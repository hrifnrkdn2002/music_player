import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';

/// MiniPlayer 위젯 전용 VM. 미니 컨트롤(이전/재생/다음)과 진행바 표시에 필요한 상태만.
class MiniPlayerViewModel extends ChangeNotifier {
  final MusicServiceInterface _service;

  late Song? _currentSong;
  late bool _isPlaying;

  StreamSubscription<Song?>? _currentSongSub;
  StreamSubscription<bool>? _isPlayingSub;

  MiniPlayerViewModel(this._service) {
    _currentSong = _service.currentSong;
    _isPlaying = _service.isPlaying;

    _currentSongSub = _service.currentSongStream.listen((song) {
      _currentSong = song;
      notifyListeners();
    });
    _isPlayingSub = _service.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration? get duration => _service.duration;

  Stream<Duration> get positionStream => _service.positionStream;

  Future<void> togglePlayPause() =>
      _isPlaying ? _service.pause() : _service.resume();
  Future<void> playNext() => _service.playNext();
  Future<void> playPrevious() => _service.playPrevious();
  Future<void> seek(Duration position) => _service.seek(position);

  @override
  void dispose() {
    _currentSongSub?.cancel();
    _isPlayingSub?.cancel();
    super.dispose();
  }
}