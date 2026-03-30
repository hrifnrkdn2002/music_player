import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:music_player/DB/database_helper.dart';
import 'package:music_player/Models/Song.dart';

class DB_Provider extends ChangeNotifier {
  final List<Song> _songs = [];
  bool _isLoading = false;

  List<Song> get songs => List.unmodifiable(_songs);
  bool get isLoading => _isLoading;

  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedSongs = await DatabaseHelper.instance.getAllSongs();

      _songs
        ..clear()
        ..addAll(loadedSongs);
    } catch (e) {
      debugPrint('loadSongs 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndInsertSongs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
        final filePath = file.path;
        if (filePath == null) continue;

        // 🔥 중복 체크
        final uniqueKey = '${file.name}_${file.size}';

        final exists = _songs.any((song) => song.uniqueKey == uniqueKey);
        if (exists) continue;


        final song = Song(
          title: p.basenameWithoutExtension(file.name),
          artist: null,
          filePath: filePath,
          duration: null,
          albumImagePath: null,
          uniqueKey: uniqueKey
        );

        await DatabaseHelper.instance.insertSong(song);
      }

      await loadSongs();
    } catch (e) {
      debugPrint('오류: $e');
    }
  }

  Future<void> insertSong(Song song) async {
    try {
      await DatabaseHelper.instance.insertSong(song);
      await loadSongs();
    } catch (e) {
      debugPrint('insertSong 오류: $e');
    }
  }

  Future<void> deleteSong(int id) async {
    try {
      await DatabaseHelper.instance.deleteSong(id);
      _songs.removeWhere((song) => song.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteSong 오류: $e');
    }
  }

  Future<void> updateSong(Song song) async {
    try {
      await DatabaseHelper.instance.updateSong(song);
      await loadSongs();
    } catch (e) {
      debugPrint('updateSong 오류: $e');
    }
  }

  Future<void> refreshSongs() async {
    await loadSongs();
  }

  Future<void> clearProviderOnly() async {
    _songs.clear();
    notifyListeners();
  }
}