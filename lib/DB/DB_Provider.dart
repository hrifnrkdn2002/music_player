import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:music_player/DB/DatabaseHelper.dart';
import 'package:music_player/Models/Song.dart';

class DB_Provider extends ChangeNotifier {
  final List<Song> _songs = [];
  bool _isLoading = false;

  List<Song> get songs => List.unmodifiable(_songs);
  bool get isLoading => _isLoading;

  // 💡 [기획안 반영] 플레이리스트 목록을 담아둘 리스트
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> get playlists => List.unmodifiable(_playlists);

  /* =======================================================================
   * [1] 기존 곡 관련 메서드들 (그대로 유지)
   * ======================================================================= */

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
          uniqueKey: uniqueKey,
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

  /* =======================================================================
   * [2] 🔥 [기획안 반영] 플레이리스트 관련 메서드 (신규 추가)
   * ======================================================================= */

  // 💡 1. 플레이리스트 목록 조회 (최신 업데이트순 정렬)
  Future<void> loadPlaylists() async {
    try {
      final loadedPlaylists = await DatabaseHelper.instance.getPlaylists();
      _playlists = List.from(loadedPlaylists);
      notifyListeners(); // UI에 데이터가 변경되었음을 알림
    } catch (e) {
      debugPrint('loadPlaylists 오류: $e');
    }
  }

  // 💡 2. 플레이리스트 생성
  Future<void> createPlaylist(String name) async {
    try {
      await DatabaseHelper.instance.createPlaylist(name);
      await loadPlaylists(); // 생성 후 목록을 새로고침하여 최신순 정렬 반영
    } catch (e) {
      debugPrint('createPlaylist 오류: $e');
    }
  }

  // 💡 3. 플레이리스트 이름 수정
  Future<void> updatePlaylistName(int id, String newName) async {
    try {
      await DatabaseHelper.instance.updatePlaylistName(id, newName);
      await loadPlaylists(); // 수정 후 목록을 새로고침하여 최신순 정렬 반영
    } catch (e) {
      debugPrint('updatePlaylistName 오류: $e');
    }
  }

  // 💡 4. 플레이리스트 삭제
  Future<void> deletePlaylist(int id) async {
    try {
      await DatabaseHelper.instance.deletePlaylist(id);
      await loadPlaylists(); // 삭제 후 목록 갱신
    } catch (e) {
      debugPrint('deletePlaylist 오류: $e');
    }
  }
  /* =======================================================================
   * [3] 🔥 [기획안 반영] 플레이리스트 상세 관련 메서드 (신규 추가)
   * ======================================================================= */

  // 1. 플레이리스트에 곡 추가
  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    try {
      await DatabaseHelper.instance.addSongToPlaylist(playlistId, songId);
      notifyListeners();
    } catch (e) {
      debugPrint('addSongToPlaylist 오류: $e');
    }
  }

  // 2. 플레이리스트 곡 조회
  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    try {
      return await DatabaseHelper.instance.getSongsInPlaylist(playlistId);
    } catch (e) {
      debugPrint('getSongsInPlaylist 오류: $e');
      return [];
    }
  }

  // 3. 플레이리스트에서 곡 삭제
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      await DatabaseHelper.instance.removeSongFromPlaylist(playlistId, songId);
      notifyListeners();
    } catch (e) {
      debugPrint('removeSongFromPlaylist 오류: $e');
    }
  }
  //순서저장메서드
  Future<void> updatePlaylistSongOrder(int playlistId, List<Song> songs) async {
    try {
      await DatabaseHelper.instance.updatePlaylistSongOrder(playlistId, songs);
      notifyListeners();
    } catch (e) {
      debugPrint('updatePlaylistSongOrder 오류: $e');
    }
  }
}