import 'package:music_player/get_it.dart';
import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/view_model/add_song_to_playlist_view_model.dart';

class AddSongToPlaylistPage extends StatelessWidget {
  final int playlistId;
  final String playlistName;

  const AddSongToPlaylistPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddSongToPlaylistViewModel(
        playlistId: playlistId,
        db: locator<DatabaseRepositoryInterface>(),
      ),
      child: _AddSongToPlaylistBody(playlistName: playlistName),
    );
  }
}

class _AddSongToPlaylistBody extends StatelessWidget {
  final String playlistName;

  const _AddSongToPlaylistBody({required this.playlistName});

  Future<void> _addSong(BuildContext context, AddSongToPlaylistViewModel vm, Song song) async {
    final ok = await vm.addSong(song);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\'${song.title}\' 곡을 추가했습니다.'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddSongToPlaylistViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final tileColor = isDark ? const Color(0xFF1C1C1C) : Colors.grey[100]!;

    final filteredSongs = vm.filteredSongs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text('곡 추가', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              playlistName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: colorScheme.onSurfaceVariant,
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
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: '곡 제목 또는 아티스트 검색',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onChanged: vm.setSearchQuery,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.load,
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.allSongsEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                          ),
                          Center(
                            child: Text(
                              '기기에 추가된 곡이 없습니다.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
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
                              vm.searchQuery.isEmpty
                                  ? '추가할 수 있는 곡이 없습니다.'
                                  : '검색 결과가 없습니다.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
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
                                  color: colorScheme.onSurface,
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
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Icon(
                                Icons.add_circle,
                                color: colorScheme.primary,
                              ),
                              onTap: () => _addSong(context, vm, song),
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