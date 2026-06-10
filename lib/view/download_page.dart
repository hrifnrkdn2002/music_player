import 'package:music_player/get_it.dart';
import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/view_model/download_view_model.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DownloadViewModel(
        locator<DatabaseServiceInterface>(),
        locator<DatabaseRepositoryInterface>(),
        locator<YoutubeServiceInterface>(),
      ),
      child: const _DownloadPageBody(),
    );
  }
}

class _DownloadPageBody extends StatefulWidget {
  const _DownloadPageBody();

  @override
  State<_DownloadPageBody> createState() => _DownloadPageBodyState();
}

class _DownloadPageBodyState extends State<_DownloadPageBody> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _addUrl(DownloadViewModel vm) async {
    print('유튜브 URL: ${_urlController.text}');
    await vm.addYoutubeUrl(_urlController.text);
    if (!mounted) return;
    if (vm.error == null) {
      _urlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추가되었습니다')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DownloadViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 유튜브 URL로 곡 추가
            TextField(
              controller: _urlController,
              enabled: !vm.isAdding,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: '유튜브 URL',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: vm.isAdding ? null : () => _addUrl(vm),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: vm.isAdding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('유튜브 곡 추가'),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // 로컬 파일로 곡 추가
            ElevatedButton(
              onPressed: vm.isPicking ? null : vm.pickAndInsertSongs,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: vm.isPicking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('다운로드'),
            ),
          ],
        ),
      ),
    );
  }
}
