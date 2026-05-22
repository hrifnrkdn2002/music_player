import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';

/// PlayerPage 전용 VM. MusicService의 스트림을 ChangeNotifier로 어댑팅.
/// position/duration처럼 고빈도 스트림은 직접 노출 (View가 StreamBuilder로 사용).
class PlayerViewModel extends ChangeNotifier {
  final MusicServiceInterface _service;

  late Song? _currentSong;
  late bool _isPlaying;
  late bool _isShuffleOn;
  late RepeatModeState _repeatMode;
  late String? _playError;

  StreamSubscription<Song?>? _currentSongSub;
  StreamSubscription<bool>? _isPlayingSub;
  StreamSubscription<bool>? _isShuffleOnSub;
  StreamSubscription<RepeatModeState>? _repeatModeSub;
  StreamSubscription<String?>? _playErrorSub;

  PlayerViewModel(this._service) {
    _currentSong = _service.currentSong;
    _isPlaying = _service.isPlaying;
    _isShuffleOn = _service.isShuffleOn;
    _repeatMode = _service.repeatMode;
    _playError = _service.playError;

    _currentSongSub = _service.currentSongStream.listen((song) {
      _currentSong = song;
      notifyListeners();
    });
    _isPlayingSub = _service.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });
    _isShuffleOnSub = _service.isShuffleOnStream.listen((on) {
      _isShuffleOn = on;
      notifyListeners();
    });
    _repeatModeSub = _service.repeatModeStream.listen((mode) {
      _repeatMode = mode;
      notifyListeners();
    });
    _playErrorSub = _service.playErrorStream.listen((err) {
      _playError = err;
      notifyListeners();
    });
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isShuffleOn => _isShuffleOn;
  RepeatModeState get repeatMode => _repeatMode;
  String? get playError => _playError;
  Duration? get duration => _service.duration;

  Stream<Duration> get positionStream => _service.positionStream;

  Future<void> togglePlayPause() =>
      _isPlaying ? _service.pause() : _service.resume();
  Future<void> playNext() => _service.playNext();
  Future<void> playPrevious() => _service.playPrevious();
  Future<void> seek(Duration position) => _service.seek(position);
  Future<void> cycleRepeatMode() => _service.cycleRepeatMode();
  Future<void> toggleShuffle() => _service.toggleShuffle();

  void clearError() => _service.clearError();

  @override
  void dispose() {
    _currentSongSub?.cancel();
    _isPlayingSub?.cancel();
    _isShuffleOnSub?.cancel();
    _repeatModeSub?.cancel();
    _playErrorSub?.cancel();
    super.dispose();
  }
}