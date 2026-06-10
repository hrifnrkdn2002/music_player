import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';

class HomeViewModel extends ChangeNotifier {
  final MusicServiceInterface _musicService;
  final DatabaseServiceInterface _service;

  List<Song> _songs = [];
  String _searchQuery = '';
  StreamSubscription<List<Song>>? _songsSub;

  List<Song> get filteredSongs {
    if (_searchQuery.isEmpty) return _songs;
    final query = _searchQuery.toLowerCase().trim();
    return _songs
        .where((s) =>
            s.title.toLowerCase().contains(query) ||
            (s.artist ?? '').toLowerCase().contains(query))
        .toList();
  }

  HomeViewModel(this._musicService, this._service) {
    // 싱글톤 서비스의 현재 스냅샷으로 시드 후, 변경 스트림을 구독.
    // refreshSongs()가 DB를 읽어 첫 방송을 일으킨다.
    _songs = _service.songs;
    _songsSub = _service.songsStream.listen(_onSongsChanged);
    _service.refreshSongs();
  }

  void _onSongsChanged(List<Song> songs) {
    _songs = songs;
    _musicService.setPlaylist(_songs);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // 수정/삭제는 서비스를 거쳐 DB 반영 + 스트림 방송까지 일괄 처리된다.
  Future<void> updateSong(Song song) => _service.updateSong(song);

  Future<void> deleteSong(int id) => _service.deleteSong(id);

  Future<void> playSong(Song song) => _musicService.playSong(song);

  @override
  void dispose() {
    _songsSub?.cancel();
    super.dispose();
  }
}
