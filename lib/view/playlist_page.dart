import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/index/view_model_index.dart';

import 'playlist_detail_page.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  String _searchQuery = ''; // 플레이리스트 검색어 저장 변수

  @override
  void initState() {
    super.initState();
    // 💡 화면이 열릴 때 플레이리스트 목록을 DB에서 새로고침합니다.
    Future.microtask(() {
      context.read<DatabaseViewModel>().loadPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 💡 테마 및 view_model 데이터 가져오기
    final musicProvider = context.watch<MusicViewModel>();
    final dbProvider = context.watch<DatabaseViewModel>();

    final isDark = context.watch<DarkModeViewModel>().isDarkMode;
    final theme = AppTheme(isDark);

    // 💡 [검색 및 정렬] 검색어에 맞는 플레이리스트만 필터링 (DB에서 이미 최신순 정렬되어 옴)
    final filteredPlaylists = dbProvider.playlists.where((playlist) {
      final name = playlist['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            /* =======================================================================
             * [1] 상단 검색바 & 추가 버튼 (HomePage 스타일 참고)
             * ======================================================================= */
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1C)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        style: TextStyle(color: theme.text),
                        decoration: InputDecoration(
                          hintText: '플레이리스트 검색',
                          hintStyle: TextStyle(color: theme.subtitle),
                          prefixIcon: Icon(Icons.search, color: theme.subtitle),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value; // 검색어 실시간 갱신
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 💡 플레이리스트 추가 버튼
                  GestureDetector(
                    onTap: () => _showCreatePlaylistDialog(context, isDark),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.purpleAccent : Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            /* =======================================================================
             * [2] 플레이리스트 목록 (기획안 반영)
             * ======================================================================= */
            Expanded(
              child: filteredPlaylists.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? '생성된 플레이리스트가 없습니다.'
                            : '검색 결과가 없습니다.',
                        style: TextStyle(color: theme.subtitle, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredPlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = filteredPlaylists[index];
                        final playlistId = playlist['id'] as int;
                        final playlistName = playlist['name'] as String;

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
                            playlistName,
                            style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '곡 ${playlist['song_count'] ?? 0}개',
                            style: TextStyle(
                              color: theme.subtitle,
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: theme.subtitle),
                            color: isDark
                                ? const Color(0xFF1C1C1C)
                                : Colors.white,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditPlaylistDialog(
                                  context,
                                  playlistId,
                                  playlistName,
                                  isDark,
                                );
                              } else if (value == 'delete') {
                                _showDeleteConfirmDialog(
                                  context,
                                  playlistId,
                                  playlistName,
                                  isDark,
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: theme.text,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '이름 수정',
                                      style: TextStyle(color: theme.text),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '삭제',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // 💡 PlaylistPage.dart의 ListTile 내부 onTap 부분 수정
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailPage(
                                  playlistId: playlistId,
                                  playlistName: playlistName,
                                ),
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
    );
  }

  /* =======================================================================
   * [3] 다이얼로그 모음 (생성 / 수정 / 삭제)
   * ======================================================================= */

  // 💡 1. 플레이리스트 생성 다이얼로그
  void _showCreatePlaylistDialog(BuildContext context, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        title: Text(
          '새 플레이리스트',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: '플레이리스트 이름을 입력하세요',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<DatabaseViewModel>().createPlaylist(name);
                Navigator.pop(context);
              }
            },
            child: Text(
              '생성',
              style: TextStyle(
                color: isDark ? Colors.purpleAccent : Colors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 2. 플레이리스트 이름 수정 다이얼로그
  void _showEditPlaylistDialog(
    BuildContext context,
    int id,
    String currentName,
    bool isDark,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        title: Text(
          '이름 수정',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: '수정할 이름을 입력하세요',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                context.read<DatabaseViewModel>().updatePlaylistName(
                  id,
                  newName,
                );
                Navigator.pop(context);
              }
            },
            child: Text(
              '수정',
              style: TextStyle(
                color: isDark ? Colors.purpleAccent : Colors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 3. 플레이리스트 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(
    BuildContext context,
    int id,
    String name,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        title: Text(
          '플레이리스트 삭제',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          '\'$name\' 플레이리스트를 삭제하시겠습니까?\n(플레이리스트 내부의 곡만 삭제되며 원본 곡은 유지됩니다.)',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<DatabaseViewModel>().deletePlaylist(id);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
