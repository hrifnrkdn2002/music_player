import 'package:flutter/foundation.dart';
import 'package:music_player/interface.dart';

/// DownloadPage 전용 VM. 파일 피커로 곡 선택 → DB 삽입,
/// 또는 유튜브 URL 입력 → 메타데이터 해석 후 DB 삽입.
/// 중복 체크를 위해 기존 곡 목록을 service에 전달.
class DownloadViewModel extends ChangeNotifier {
  final DatabaseServiceInterface _service;
  final DatabaseRepositoryInterface _db;
  final YoutubeServiceInterface _youtube;

  bool _isPicking = false;
  bool get isPicking => _isPicking;

  bool _isAdding = false;
  bool get isAdding => _isAdding;

  String? _error;
  String? get error => _error;

  DownloadViewModel(this._service, this._db, this._youtube);

  Future<void> pickAndInsertSongs() async {
    if (_isPicking) return;
    _isPicking = true;
    notifyListeners();
    try {
      final existing = await _db.getAllSongs();
      await _service.pickAndInsertSongs(existing);
    } catch (e) {
      debugPrint('pickAndInsertSongs 오류: $e');
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }

  // 유튜브 URL → 메타데이터 해석 → 중복 체크 후 DB 삽입
  Future<void> addYoutubeUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || _isAdding) return;
    _isAdding = true;
    _error = null;
    notifyListeners();
    try {
      final existing = await _db.getAllSongs();
      final song = await _youtube.resolveMetadata(trimmed);
      if (existing.any((s) => s.uniqueKey == song.uniqueKey)) {
        _error = '이미 추가된 곡입니다';
      } else {
        await _db.insertSong(song);
      }
    } catch (e) {
      _error = '추가 실패: URL을 확인해주세요';
      debugPrint('addYoutubeUrl 오류: $e');
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }
}
