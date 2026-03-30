import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:music_player/Models/Song.dart';

class DatabaseHelper {
  // 싱글톤 객체
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // DB getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('music_player.db');
    return _database!;
  }

  // DB 초기 생성
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // 테이블 생성
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT ,
        file_path TEXT NOT NULL UNIQUE,
        album_image_path TEXT,
        duration INTEGER,
        unique_key TEXT UNIQUE
      )
    ''');
  }

  // 곡 추가
  Future<int> insertSong(Song song) async {
    final db = await database;

    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // 전체 곡 조회
  Future<List<Song>> getAllSongs() async {
    final db = await database;

    final result = await db.query(
      'songs',
      orderBy: 'id DESC',
    );

    return result.map((map) => Song.fromMap(map)).toList();
  }

  // 곡 삭제
  Future<int> deleteSong(int id) async {
    final db = await database;

    return await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 곡 수정
  Future<int> updateSong(Song song) async {
    final db = await database;

    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  // DB 닫기
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}