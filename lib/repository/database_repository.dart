import 'package:music_player/index/repository_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/playlist.dart';

class DatabaseRepository extends DatabaseRepositoryInterface{

  final Database _database;

  DatabaseRepository(this._database);


  /* ==================== [기존 곡 관련 메서드] ==================== */

  @override
  Future<int> insertSong(Song song) async {

    return await _database.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  @override
  Future<List<Song>> getAllSongs() async {
    final result = await _database.query('songs', orderBy: 'id DESC');
    return result.map((map) => Song.fromMap(map)).toList();
  }
  @override
  Future<int> deleteSong(int id) async {
    return await _database.delete('songs', where: 'id = ?', whereArgs: [id]);
  }
  @override
  Future<int> updateSong(Song song) async {
    return await _database.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  /* ==================== [ 플레이리스트 관련 메서드] ==================== */

  // 플레이리스트 생성 (항상 현재 시간을 밀리초로 저장하여 최신순 정렬에 활용)
  @override
  Future<int> createPlaylist(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    //중복된 이름이어도 생성가능한 지 확인할 것
    return await _database.insert('playlists', {'name': name, 'updated_at': now});
  }

  // 플레이리스트 목록 조회 (곡 수 포함, 최신 업데이트순 정렬)
  @override
  Future<List<Playlist>> getPlaylists() async {
    final result =  await _database.rawQuery('''
      SELECT p.*, COUNT(ps.song_id) as count  
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      GROUP BY p.id
      ORDER BY p.updated_at DESC
    ''');
    return result.map((map) => Playlist.fromMap(map)).toList();
  }

  // 플레이리스트 이름 수정 (수정 시에도 최신순으로 맨 위로 올려야 하므로 updated_at을 갱신합니다)
  @override
  Future<int> updatePlaylistName(int id, String newName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _database.update(
      'playlists',
      {'name': newName, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 플레이리스트 삭제
  @override
  Future<int> deletePlaylist(int id) async {
    return await _database.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  /* ==================== [🔥 추가: 플레이리스트 상세 관련 메서드] ==================== */

  // 1. 플레이리스트에 곡 추가 (중복 방지 포함)
  @override
  Future<int> addSongToPlaylist(int playlistId, int songId) async {
    final existing = await _database.query(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
    if (existing.isNotEmpty) return 0;

    final result = await _database.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) as max_order FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );

    final maxOrder = (result.first['max_order'] as int?) ?? -1;

    return await _database.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'sort_order': maxOrder + 1,
    });
  }

  // 2. 플레이리스트에 담긴 곡 목록 조회 (JOIN 활용)
  @override
  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    final maps = await _database.rawQuery(
      '''
    SELECT s.* FROM songs s
    INNER JOIN playlist_songs ps ON s.id = ps.song_id
    WHERE ps.playlist_id = ?
    ORDER BY ps.sort_order ASC
  ''',
      [playlistId],
    );

    return maps.map((map) => Song.fromMap(map)).toList();
  }

  // 3. 플레이리스트에서 특정 곡 제외 (원본 파일은 유지)
  @override
  Future<int> removeSongFromPlaylist(int playlistId, int songId) async {
    return await _database.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  //순서저장메서드추가
  @override
  Future<void> updatePlaylistSongOrder(int playlistId, List<Song> songs) async {
    final batch = _database.batch();

    for (int i = 0; i < songs.length; i++) {
      final songId = songs[i].id;
      if (songId == null) continue;

      batch.update(
        'playlist_songs',
        {'sort_order': i},
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId],
      );
    }

    await batch.commit(noResult: true);
  }
}
