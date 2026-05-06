import 'package:music_player/index/repository_index.dart';

class DatabaseRepository {
  static final DatabaseRepository instance = DatabaseRepository._init();
  static Database? _database;

  DatabaseRepository._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_player.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 버전 업그레이드 시 여기에 마이그레이션을 순서대로 추가합니다.
    // 예: if (oldVersion < 2) { await db.execute('ALTER TABLE songs ADD COLUMN ...'); }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. 곡 테이블
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT,
        file_path TEXT NOT NULL UNIQUE,
        album_image_path TEXT,
        duration INTEGER,
        unique_key TEXT UNIQUE
      )
    ''');

    // 2. 플레이리스트 테이블 (기획안의 '최신 업데이트순' 정렬을 위해 updated_at 추가)
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 3. 플레이리스트-곡 매핑 테이블
    await db.execute('''
            CREATE TABLE playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');
  }

  /* ==================== [기존 곡 관련 메서드] ==================== */

  Future<int> insertSong(Song song) async {
    final db = await database;
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final result = await db.query('songs', orderBy: 'id DESC');
    return result.map((map) => Song.fromMap(map)).toList();
  }

  Future<int> deleteSong(int id) async {
    final db = await database;
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSong(Song song) async {
    final db = await database;
    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  /* ==================== [🔥 추가: 플레이리스트 관련 메서드] ==================== */

  // 플레이리스트 생성 (항상 현재 시간을 밀리초로 저장하여 최신순 정렬에 활용)
  Future<int> createPlaylist(String name) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    //중복된 이름이어도 생성가능한 지 확인할 것
    return await db.insert('playlists', {'name': name, 'updated_at': now});
  }

  // 플레이리스트 목록 조회 (곡 수 포함, 최신 업데이트순 정렬)
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, COUNT(ps.song_id) as song_count
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      GROUP BY p.id
      ORDER BY p.updated_at DESC
    ''');
  }

  // 플레이리스트 이름 수정 (수정 시에도 최신순으로 맨 위로 올려야 하므로 updated_at을 갱신합니다)
  Future<int> updatePlaylistName(int id, String newName) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'playlists',
      {'name': newName, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 플레이리스트 삭제
  Future<int> deletePlaylist(int id) async {
    final db = await database;
    return await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  /* ==================== [🔥 추가: 플레이리스트 상세 관련 메서드] ==================== */

  // 1. 플레이리스트에 곡 추가 (중복 방지 포함)
  Future<int> addSongToPlaylist(int playlistId, int songId) async {
    final db = await database;

    final existing = await db.query(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
    if (existing.isNotEmpty) return 0;

    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) as max_order FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );

    final maxOrder = (result.first['max_order'] as int?) ?? -1;

    return await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'sort_order': maxOrder + 1,
    });
  }

  // 2. 플레이리스트에 담긴 곡 목록 조회 (JOIN 활용)
  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    final db = await database;

    final maps = await db.rawQuery(
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
  Future<int> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await database;
    return await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  //순서저장메서드추가
  Future<void> updatePlaylistSongOrder(int playlistId, List<Song> songs) async {
    final db = await database;
    final batch = db.batch();

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
