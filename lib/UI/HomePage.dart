import 'package:flutter/material.dart';
import 'package:music_player/DB/DB_Provider.dart';
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

    Future.microtask(() {
      context.read<DB_Provider>().loadSongs();
    });
  }

  void _showEditDialog(BuildContext context, Song song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist ?? '');

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
                decoration: const InputDecoration(labelText: '제목'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: '가수'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
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
    context.read<MusicProvider>().setPlaylist(songs);

    final filteredSongs = songs.where((song) {
      final query = _searchQuery.toLowerCase().trim();

      if (query.isEmpty) return true;

      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();

      return title.contains(query) || artist.contains(query);
    }).toList();

    return Scaffold(
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
                    decoration: InputDecoration(
                      hintText: '노래 검색',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
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
                      ? const Center(
                    child: Text('검색 결과가 없습니다'),
                  )
                      : ListView.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];

                      return ListTile(
                        title: Text(song.title),
                        subtitle: Text(song.artist ?? '가수없음'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showEditDialog(context, song);
                            } else if (value == 'delete') {
                              if (song.id != null) {
                                await context.read<DB_Provider>().deleteSong(song.id!);
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
                          context.read<MusicProvider>().playSong(song);

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
          const MiniPlayer(),
        ],
      ),
    );
  }
}