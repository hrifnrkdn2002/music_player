import 'package:path/path.dart';

import 'database_helper.dart';

export 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // ?은 null허용, 처음 싱글톤으로
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_player.db');
    return _database!;
  }
  // getDatabasesPath()는 앱자체의 고유 DB 경로를 반환
  // openDatabase()는 해당 경로에 DB 파일이 없으면 새로 생성 있으면 DB open.
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON'); // 외래 키 활성화
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 버전 업그레이드 시 여기에 마이그레이션을 순서대로 추가합니다.
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE songs ADD COLUMN is_youtube INTEGER NOT NULL DEFAULT 0',
      );
    }
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
        unique_key TEXT UNIQUE,
        is_youtube INTEGER NOT NULL DEFAULT 0
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
}