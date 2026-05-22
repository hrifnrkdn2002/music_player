import 'package:flutter/foundation.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/playlist.dart';

/// PlaylistPage 전용 VM. 플레이리스트 목록 CRUD + 검색어 필터.
class PlaylistViewModel extends ChangeNotifier {
  final DatabaseRepositoryInterface _db;

  List<Playlist> _playlists = [];
  String _searchQuery = '';

  PlaylistViewModel(this._db) {
    loadPlaylists();
  }

  List<Playlist> get filteredPlaylists {
    if (_searchQuery.isEmpty) return List.unmodifiable(_playlists);
    final query = _searchQuery.toLowerCase();
    return _playlists.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  String get searchQuery => _searchQuery;

  Future<void> loadPlaylists() async {
    try {
      _playlists = await _db.getPlaylists();
      notifyListeners();
    } catch (e) {
      debugPrint('loadPlaylists 오류: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    await _db.createPlaylist(name);
    await loadPlaylists();
  }

  Future<void> updatePlaylistName(int id, String newName) async {
    await _db.updatePlaylistName(id, newName);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(int id) async {
    await _db.deletePlaylist(id);
    await loadPlaylists();
  }
}