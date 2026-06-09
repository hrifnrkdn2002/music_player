import 'package:music_player/get_it.dart';
import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/view/player_page.dart';
import 'package:music_player/view_model/home_view_model.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        locator<MusicServiceInterface>(),
        locator<DatabaseRepositoryInterface>(),
      ),
      child: const _HomePageBody(),
    );
  }
}

class _HomePageBody extends StatelessWidget {
  const _HomePageBody();

  void _showEditDialog(BuildContext context, Song song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist ?? '');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('음악 정보 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '제목',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistController,
                decoration: InputDecoration(
                  labelText: '가수',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                '취소',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedSong = Song(
                  id: song.id,
                  title: titleController.text.trim().isEmpty
                      ? song.title
                      : titleController.text.trim(),
                  artist: artistController.text.trim().isEmpty
                      ? null
                      : artistController.text.trim(),
                  filePath: song.filePath,
                  duration: song.duration,
                  albumImagePath: song.albumImagePath,
                  uniqueKey: song.uniqueKey,
                );
                await context.read<HomeViewModel>().updateSong(updatedSong);
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: vm.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: '노래 검색',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: vm.filteredSongs.isEmpty
                      ? const Center(child: Text('검색 결과가 없습니다'))
                      : ListView.builder(
                          itemCount: vm.filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = vm.filteredSongs[index];
                            return ListTile(
                              title: Text(song.title),
                              subtitle: Text(song.artist ?? '가수없음'),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _showEditDialog(context, song);
                                  } else if (value == 'delete') {
                                    final id = song.id;
                                    if (id != null) {
                                      await context
                                          .read<HomeViewModel>()
                                          .deleteSong(id);
                                    }
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('수정'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('삭제',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                print("노래 클릭");
                                context.read<HomeViewModel>().playSong(song);
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PlayerPage(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
