import 'package:flutter/material.dart';
import 'package:music_player/DB/DB_Provider.dart';
import 'package:music_player/Provider/ThemeProvider.dart';
import 'package:music_player/Utils/AppTheme.dart';
import 'package:music_player/UI/PlayerPage.dart';
import 'package:music_player/UI/mini_player.dart';
import 'package:provider/provider.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:music_player/Models/Song.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final dbProvider = context.read<DB_Provider>();
      dbProvider.addListener(_syncPlaylist);
      await dbProvider.loadSongs();
    });
  }

  void _syncPlaylist() {
    if (!mounted) return;
    context.read<MusicProvider>().setPlaylist(context.read<DB_Provider>().songs);
  }

  @override
  void dispose() {
    context.read<DB_Provider>().removeListener(_syncPlaylist);
    super.dispose();
  }

  void _showEditDialog(BuildContext context, Song song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist ?? '');
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
         // backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          title: Text(
              '음악 정보 수정',
              //style: TextStyle(color: isDark ? Colors.white : Colors.black)
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                //style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: '제목',
                  labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistController,
               // style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: '가수',
                  labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('취소', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
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

                await context.read<DB_Provider>().updateSong(updatedSong);

                if (!mounted) return;
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
               // backgroundColor: isDark ? Colors.purpleAccent : null,
               // foregroundColor: isDark ? Colors.white : null,
              ),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<DB_Provider>().songs;

    // 💡 테마 상태 가져오기
    // final isDark = context.watch<ThemeProvider>().isDarkMode;
    // final theme = AppTheme(isDark);

    final filteredSongs = songs.where((song) {
      final query = _searchQuery.toLowerCase().trim();

      if (query.isEmpty) return true;

      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();

      return title.contains(query) || artist.contains(query);
    }).toList();

    // 💡 Scaffold로 감싸서 배경이 어두워지도록 강제합니다.
    return Scaffold(
     // backgroundColor: theme.background,
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                   // style: TextStyle(color: theme.text),
                    decoration: InputDecoration(
                      hintText: '노래 검색',
                      //hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                      prefixIcon: Icon(Icons.search/*, color: isDark ? Colors.white54 : Colors.black45*/),
                      filled: true,
                      // 💡 다크 모드일 땐 더 짙은 회색으로 변경
                      //fillColor: isDark ? const Color(0xFF1C1C1C) : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredSongs.isEmpty
                      ? Center(
                    child: Text('검색 결과가 없습니다', /*style: TextStyle(color: theme.text)*/),
                  )
                      : ListView.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];

                      return ListTile(
                        title: Text(song.title, /*style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)*/),
                        subtitle: Text(song.artist ?? '가수없음', /*style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700])*/),
                        trailing: PopupMenuButton<String>(
                         // color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                          icon: Icon(Icons.more_vert,/*color: isDark ? Colors.white : Colors.black*/),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showEditDialog(context, song);
                            } else if (value == 'delete') {
                              final id = song.id;
                              if (id != null) {
                                await context.read<DB_Provider>().deleteSong(id);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20, /*color: isDark ? Colors.white70 : Colors.black*/),
                                  const SizedBox(width: 8),
                                  Text('수정', /*style: TextStyle(color: isDark ? Colors.white : Colors.black)*/),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          final musicProvider = context.read<MusicProvider>();
                          final dbProvider = context.read<DB_Provider>();

                          musicProvider.setPlaylist(dbProvider.songs);
                          musicProvider.playSong(song);

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlayerPage()),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}