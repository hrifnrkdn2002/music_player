import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/index/view_model_index.dart';
import 'package:music_player/model/song.dart';

class AddSongToPlaylistPage extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const AddSongToPlaylistPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<AddSongToPlaylistPage> createState() => _AddSongToPlaylistPageState();
}

class _AddSongToPlaylistPageState extends State<AddSongToPlaylistPage> {
  bool _isLoading = true;
  String _searchQuery = '';

  List<Song> _allSongs = [];
  Set<int> _existingSongIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbProvider = context.read<DatabaseViewModel>();

      if (dbProvider.songs.isEmpty) {
        await dbProvider.loadSongs();
      }

      final playlistSongs = await dbProvider.getSongsInPlaylist(
        widget.playlistId,
      );

      final existingIds = playlistSongs
          .map((song) => song.id)
          .whereType<int>()
          .toSet();

      if (!mounted) return;

      setState(() {
        _allSongs = List<Song>.from(dbProvider.songs);
        _existingSongIds = existingIds;
      });
    } catch (e) {
      debugPrint('AddSongToPlaylistPage load 오류: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSong(Song song) async {
    final songId = song.id;
    if (songId == null) return;

    try {
      await context.read<DatabaseViewModel>().addSongToPlaylist(
        widget.playlistId,
        songId,
      );

      if (!mounted) return;

      setState(() {
        _existingSongIds.add(songId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\'${song.title}\' 곡을 추가했습니다.'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('곡 추가 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicViewModel>();
    final isDark = context.watch<DarkModeViewModel>().isDarkMode;
    final theme = AppTheme(isDark);
    final tileColor = isDark ? const Color(0xFF1C1C1C) : Colors.grey[100]!;

    final filteredSongs = _allSongs.where((song) {
      final songId = song.id;

      // 이미 플레이리스트에 있는 곡은 아예 목록에서 제외
      if (songId != null && _existingSongIds.contains(songId)) {
        return false;
      }

      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return title.contains(query) || artist.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.text,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text('곡 추가', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              widget.playlistName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: theme.subtitle,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1C) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  style: TextStyle(color: theme.text),
                  decoration: InputDecoration(
                    hintText: '곡 제목 또는 아티스트 검색',
                    hintStyle: TextStyle(color: theme.subtitle),
                    prefixIcon: Icon(Icons.search, color: theme.subtitle),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allSongs.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                          ),
                          Center(
                            child: Text(
                              '기기에 추가된 곡이 없습니다.',
                              style: TextStyle(
                                color: theme.subtitle,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : filteredSongs.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                          ),
                          Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? '추가할 수 있는 곡이 없습니다.'
                                  : '검색 결과가 없습니다.',
                              style: TextStyle(
                                color: theme.subtitle,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 20),
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                ),
                              ),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                  color: theme.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  song.artist?.trim().isNotEmpty == true
                                      ? song.artist!
                                      : '알 수 없는 아티스트',
                                  style: TextStyle(
                                    color: theme.subtitle,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Icon(
                                Icons.add_circle,
                                color: theme.accent,
                              ),
                              onTap: () => _addSong(song),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
