import 'package:music_player/get_it.dart';
import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/view_model/playlist_view_model.dart';

import 'playlist_detail_page.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlaylistViewModel(locator<DatabaseRepositoryInterface>()),
      child: const _PlaylistPageBody(),
    );
  }
}

class _PlaylistPageBody extends StatelessWidget {
  const _PlaylistPageBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlaylistViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final filteredPlaylists = vm.filteredPlaylists;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: '플레이리스트 검색',
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: vm.setSearchQuery,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showCreatePlaylistDialog(context, vm),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredPlaylists.isEmpty
                  ? Center(
                      child: Text(
                        vm.searchQuery.isEmpty
                            ? '생성된 플레이리스트가 없습니다.'
                            : '검색 결과가 없습니다.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredPlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = filteredPlaylists[index];

                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          title: Text(
                            playlist.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '곡 ${playlist.count}개',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                            color: colorScheme.surface,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditPlaylistDialog(context, vm, playlist.id, playlist.name);
                              } else if (value == 'delete') {
                                _showDeleteConfirmDialog(context, vm, playlist.id, playlist.name);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20, color: colorScheme.onSurface),
                                    const SizedBox(width: 8),
                                    Text('이름 수정', style: TextStyle(color: colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('삭제', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailPage(
                                  playlistId: playlist.id,
                                  playlistName: playlist.name,
                                ),
                              ),
                            ).then((_) => vm.loadPlaylists());
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistViewModel vm) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text('새 플레이리스트', style: TextStyle(color: colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: '플레이리스트 이름을 입력하세요',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                vm.createPlaylist(name);
                Navigator.pop(dialogContext);
              }
            },
            child: Text('생성', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showEditPlaylistDialog(
      BuildContext context, PlaylistViewModel vm, int id, String currentName) {
    final controller = TextEditingController(text: currentName);
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text('이름 수정', style: TextStyle(color: colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: '수정할 이름을 입력하세요',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                vm.updatePlaylistName(id, newName);
                Navigator.pop(dialogContext);
              }
            },
            child: Text('수정', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, PlaylistViewModel vm, int id, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text('플레이리스트 삭제', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          '\'$name\' 플레이리스트를 삭제하시겠습니까?\n(플레이리스트 내부의 곡만 삭제되며 원본 곡은 유지됩니다.)',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              vm.deletePlaylist(id);
              Navigator.pop(dialogContext);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}