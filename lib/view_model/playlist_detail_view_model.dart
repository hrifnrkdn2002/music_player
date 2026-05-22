import 'package:flutter/foundation.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';

/// PlaylistDetailPage 전용 VM.
/// View에서 빼낸 화면 상태(_isSelectionMode, _selectedSongIds, _isLoading, _songs)와
/// reorder, 선택 삭제, 재생 트리거를 모두 보유.
class PlaylistDetailViewModel extends ChangeNotifier {
  final int playlistId;
  final DatabaseRepositoryInterface _db;
  final MusicServiceInterface _music;

  List<Song> _songs = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedSongIds = {};

  PlaylistDetailViewModel({
    required this.playlistId,
    required DatabaseRepositoryInterface db,
    required MusicServiceInterface music,
  })  : _db = db,
        _music = music {
    loadSongs();
  }

  List<Song> get songs => List.unmodifiable(_songs);
  bool get isLoading => _isLoading;
  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedSongIds => Set.unmodifiable(_selectedSongIds);
  bool get hasSelection => _selectedSongIds.isNotEmpty;

  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _songs = await _db.getSongsInPlaylist(playlistId);
    } catch (e) {
      debugPrint('loadSongs(playlist) 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) _selectedSongIds.clear();
    notifyListeners();
  }

  void toggleSongSelection(Song song) {
    final id = song.id;
    if (id == null) return;
    if (_selectedSongIds.contains(id)) {
      _selectedSongIds.remove(id);
    } else {
      _selectedSongIds.add(id);
    }
    notifyListeners();
  }

  bool isSelected(Song song) =>
      song.id != null && _selectedSongIds.contains(song.id);

  Future<void> deleteSelectedSongs() async {
    if (_selectedSongIds.isEmpty) return;
    for (final id in _selectedSongIds) {
      await _db.removeSongFromPlaylist(playlistId, id);
    }
    _selectedSongIds.clear();
    _isSelectionMode = false;
    await loadSongs();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (_isSelectionMode) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _songs.removeAt(oldIndex);
    _songs.insert(newIndex, item);
    notifyListeners();
    try {
      await _db.updatePlaylistSongOrder(playlistId, _songs);
    } catch (e) {
      debugPrint('순서 저장 오류: $e');
    }
  }

  Future<void> playFromIndex(int index) async {
    if (_isSelectionMode) return;
    if (index < 0 || index >= _songs.length) return;
    await _music.playPlaylist(_songs, index);
  }
}