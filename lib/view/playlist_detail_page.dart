import 'package:music_player/get_it.dart';
import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/view/add_song_to_playlist_page.dart';
import 'package:music_player/view/mini_player.dart';
import 'package:music_player/view/player_page.dart';
import 'package:music_player/view_model/playlist_detail_view_model.dart';

class PlaylistDetailPage extends StatelessWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlaylistDetailViewModel(
        playlistId: playlistId,
        db: locator<DatabaseRepositoryInterface>(),
        music: locator<MusicServiceInterface>(),
      ),
      child: _PlaylistDetailBody(playlistName: playlistName, playlistId: playlistId),
    );
  }
}

class _PlaylistDetailBody extends StatelessWidget {
  final String playlistName;
  final int playlistId;

  const _PlaylistDetailBody({required this.playlistName, required this.playlistId});

  Future<void> _openAddSongPage(BuildContext context, PlaylistDetailViewModel vm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSongToPlaylistPage(
          playlistId: playlistId,
          playlistName: playlistName,
        ),
      ),
    );
    await vm.loadSongs();
  }

  Future<void> _handleSongTap(BuildContext context, PlaylistDetailViewModel vm, int index) async {
    if (vm.isSelectionMode) return;
    try {
      await vm.playFromIndex(index);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerPage()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('곡 재생 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlaylistDetailViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final tileColor = isDark ? const Color(0xFF1C1C1C) : Colors.grey[100]!;
    final inactiveBorderColor = isDark ? Colors.white38 : Colors.grey[500]!;
    final deleteColor = isDark ? Colors.redAccent : Colors.red;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              playlistName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '곡 ${vm.songs.length}개',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (vm.isSelectionMode && vm.hasSelection)
            IconButton(
              onPressed: vm.deleteSelectedSongs,
              icon: Icon(Icons.delete, color: deleteColor),
              tooltip: '선택한 곡 삭제',
            ),
          IconButton(
            onPressed: vm.toggleSelectionMode,
            icon: Icon(
              vm.isSelectionMode ? Icons.close : Icons.check_box_outlined,
              color: colorScheme.onSurface,
            ),
            tooltip: vm.isSelectionMode ? '선택 취소' : '선택하기',
          ),
          IconButton(
            onPressed: vm.isSelectionMode ? null : () => _openAddSongPage(context, vm),
            icon: Icon(
              Icons.add,
              color: vm.isSelectionMode ? colorScheme.onSurfaceVariant : colorScheme.primary,
            ),
            tooltip: '곡 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.loadSongs,
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.songs.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.queue_music,
                                size: 56,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '플레이리스트에 담긴 곡이 없습니다.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '우측 상단 + 버튼으로 곡을 추가해보세요.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      buildDefaultDragHandles: false,
                      itemCount: vm.songs.length,
                      onReorder: vm.reorder,
                      itemBuilder: (context, index) {
                        final song = vm.songs[index];
                        return _SongTile(
                          key: ValueKey(song.id ?? '${song.title}_$index'),
                          song: song,
                          index: index,
                          vm: vm,
                          tileColor: tileColor,
                          textColor: colorScheme.onSurface,
                          subtitleColor: colorScheme.onSurfaceVariant,
                          activeColor: colorScheme.primary,
                          inactiveColor: inactiveBorderColor,
                          onTap: () => _handleSongTap(context, vm, index),
                        );
                      },
                    ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final PlaylistDetailViewModel vm;
  final Color tileColor;
  final Color textColor;
  final Color subtitleColor;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _SongTile({
    super.key,
    required this.song,
    required this.index,
    required this.vm,
    required this.tileColor,
    required this.textColor,
    required this.subtitleColor,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  Widget _buildCheckBox() {
    final isSelected = vm.isSelected(song);
    return GestureDetector(
      onTap: () => vm.toggleSongSelection(song),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? activeColor : inactiveColor,
            width: 1.7,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: isSelected ? Icon(Icons.check, size: 18, color: activeColor) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onTap,
        leading: vm.isSelectionMode
            ? _buildCheckBox()
            : ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle, color: subtitleColor),
              ),
        title: Text(
          song.title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            song.artist?.trim().isNotEmpty == true
                ? song.artist!
                : '알 수 없는 아티스트',
            style: TextStyle(color: subtitleColor, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}