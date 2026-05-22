import 'package:flutter/foundation.dart';
import 'package:music_player/interface.dart';

/// DownloadPage 전용 VM. 파일 피커로 곡 선택 → DB 삽입.
/// 중복 체크를 위해 기존 곡 목록을 service에 전달.
class DownloadViewModel extends ChangeNotifier {
  final DatabaseServiceInterface _service;
  final DatabaseRepositoryInterface _db;

  bool _isPicking = false;
  bool get isPicking => _isPicking;

  DownloadViewModel(this._service, this._db);

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
}