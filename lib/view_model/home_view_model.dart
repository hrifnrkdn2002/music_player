import 'package:flutter/material.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';

class HomeViewModel extends ChangeNotifier {
  final MusicServiceInterface _musicService;
  final DatabaseRepositoryInterface _db;

  List<Song> _songs = [];
  String _searchQuery = '';

  List<Song> get filteredSongs {
    if (_searchQuery.isEmpty) return _songs;
    final query = _searchQuery.toLowerCase().trim();
    return _songs
        .where((s) =>
            s.title.toLowerCase().contains(query) ||
            (s.artist ?? '').toLowerCase().contains(query))
        .toList();
  }

  HomeViewModel(this._musicService, this._db) {
    loadSongs();
  }

  Future<void> loadSongs() async {
    _songs = await _db.getAllSongs();
    await _musicService.setPlaylist(_songs);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> updateSong(Song song) async {
    await _db.updateSong(song);
    await loadSongs();
  }

  Future<void> deleteSong(int id) async {
    await _db.deleteSong(id);
    await loadSongs();
  }

  Future<void> playSong(Song song) => _musicService.playSong(song);
}
