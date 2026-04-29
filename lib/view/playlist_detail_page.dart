import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/index/view_model_index.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/view/add_song_to_playlist_page.dart';
import 'package:music_player/view/mini_player.dart';
import 'package:music_player/view/player_page.dart';

class PlaylistDetailPage extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  List<Song> _songs = [];
  bool _isLoading = true;

  bool _isSelectionMode = false;
  final Set<int> _selectedSongIds = {};

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();
  }

  Future<void> _loadPlaylistSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbProvider = context.read<DatabaseViewModel>();
      final loadedSongs = await dbProvider.getSongsInPlaylist(
        widget.playlistId,
      );

      if (!mounted) return;
      setState(() {
        _songs = loadedSongs;
      });
    } catch (e) {
      debugPrint('PlaylistDetailPage load 오류: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSongIds.clear();
      }
    });
  }

  void _toggleSongSelection(Song song) {
    final songId = song.id;
    if (songId == null) return;

    setState(() {
      if (_selectedSongIds.contains(songId)) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });
  }

  Future<void> _deleteSelectedSongs() async {
    if (_selectedSongIds.isEmpty) return;

    final dbProvider = context.read<DatabaseViewModel>();

    for (final songId in _selectedSongIds) {
      await dbProvider.removeSongFromPlaylist(widget.playlistId, songId);
    }

    if (!mounted) return;

    setState(() {
      _selectedSongIds.clear();
      _isSelectionMode = false;
    });

    await _loadPlaylistSongs();
  }

  Future<void> _handleSongTap(int index) async {
    if (_isSelectionMode) return;
    if (index < 0 || index >= _songs.length) return;

    final musicProvider = context.read<MusicViewModel>();

    try {
      await musicProvider.playPlaylist(_songs, index);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerPage()),
      );
    } catch (e) {
      debugPrint('플레이리스트 곡 재생 오류: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('곡 재생 중 오류가 발생했습니다.')));
    }
  }

  Future<void> _openAddSongPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSongToPlaylistPage(
          playlistId: widget.playlistId,
          playlistName: widget.playlistName,
        ),
      ),
    );

    await _loadPlaylistSongs();
  }

  Widget _buildCheckBox({
    required Song song,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final songId = song.id;
    final isSelected = songId != null && _selectedSongIds.contains(songId);

    return GestureDetector(
      onTap: () => _toggleSongSelection(song),
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
        child: isSelected
            ? Icon(Icons.check, size: 18, color: activeColor)
            : null,
      ),
    );
  }

  Widget _buildSongTile({
    required Song song,
    required int index,
    required Color tileColor,
    required Color textColor,
    required Color subtitleColor,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Container(
      key: ValueKey(song.id ?? '${song.title}_$index'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () => _handleSongTap(index),
        leading: _isSelectionMode
            ? _buildCheckBox(
                song: song,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              )
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

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_isSelectionMode) return;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, item);
    });

    try {
      await context.read<DatabaseViewModel>().updatePlaylistSongOrder(
        widget.playlistId,
        _songs,
      );
    } catch (e) {
      debugPrint('순서 저장 메서드가 아직 없습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeViewModel>().isDarkMode;

    final theme = AppTheme(isDark);
    final tileColor = isDark ? const Color(0xFF1C1C1C) : Colors.grey[100]!;
    final inactiveBorderColor = isDark ? Colors.white38 : Colors.grey[500]!;
    final deleteColor = isDark ? Colors.redAccent : Colors.red;
    final textColor = theme.text;
    final subtitleColor = theme.subtitle;
    final activeColor = theme.accent;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.text,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.playlistName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '곡 ${_songs.length}개',
              style: TextStyle(fontSize: 12, color: theme.subtitle),
            ),
          ],
        ),
        actions: [
          if (_isSelectionMode && _selectedSongIds.isNotEmpty)
            IconButton(
              onPressed: _deleteSelectedSongs,
              icon: Icon(Icons.delete, color: deleteColor),
              tooltip: '선택한 곡 삭제',
            ),
          IconButton(
            onPressed: _toggleSelectionMode,
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.check_box_outlined,
              color: theme.text,
            ),
            tooltip: _isSelectionMode ? '선택 취소' : '선택하기',
          ),
          IconButton(
            onPressed: _isSelectionMode ? null : _openAddSongPage,
            icon: Icon(
              Icons.add,
              color: _isSelectionMode ? theme.subtitle : theme.accent,
            ),
            tooltip: '곡 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPlaylistSongs,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _songs.isEmpty
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
                                color: theme.subtitle,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '플레이리스트에 담긴 곡이 없습니다.',
                                style: TextStyle(
                                  color: theme.subtitle,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '우측 상단 + 버튼으로 곡을 추가해보세요.',
                                style: TextStyle(
                                  color: theme.subtitle,
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
                      itemCount: _songs.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return _buildSongTile(
                          song: song,
                          index: index,
                          tileColor: tileColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          activeColor: activeColor,
                          inactiveColor: inactiveBorderColor,
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
