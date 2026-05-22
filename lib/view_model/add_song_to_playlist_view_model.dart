import 'package:flutter/foundation.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';

/// 곡 추가 페이지 VM. 전체 곡 - 이미 담긴 곡 - 검색 필터.
/// '곡 추가 완료' 같은 일회성 메시지는 콜백으로 View에 전달 (SnackBar는 BuildContext가 필요).
class AddSongToPlaylistViewModel extends ChangeNotifier {
  final int playlistId;
  final DatabaseRepositoryInterface _db;

  List<Song> _allSongs = [];
  Set<int> _existingSongIds = {};
  String _searchQuery = '';
  bool _isLoading = true;

  AddSongToPlaylistViewModel({
    required this.playlistId,
    required DatabaseRepositoryInterface db,
  }) : _db = db {
    load();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get allSongsEmpty => _allSongs.isEmpty;

  List<Song> get filteredSongs {
    final query = _searchQuery.toLowerCase();
    return _allSongs.where((song) {
      final id = song.id;
      if (id != null && _existingSongIds.contains(id)) return false;
      final title = song.title.toLowerCase();
      final artist = (song.artist ?? '').toLowerCase();
      return title.contains(query) || artist.contains(query);
    }).toList();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final all = await _db.getAllSongs();
      final existing = await _db.getSongsInPlaylist(playlistId);
      _allSongs = all;
      _existingSongIds = existing.map((s) => s.id).whereType<int>().toSet();
    } catch (e) {
      debugPrint('AddSongToPlaylist load 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addSong(Song song) async {
    final id = song.id;
    if (id == null) return false;
    try {
      await _db.addSongToPlaylist(playlistId, id);
      _existingSongIds.add(id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('addSong 오류: $e');
      return false;
    }
  }
}