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
      ),
      child: const _DownloadPageBody(),
    );
  }
}

class _DownloadPageBody extends StatelessWidget {
  const _DownloadPageBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DownloadViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ElevatedButton(
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
      ),
    );
  }
}