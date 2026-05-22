import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/service/playback_handler.dart';

class MusicService implements MusicServiceInterface {
  final PlaybackHandler _handler;

  // ─── 내부 상태 (게터 노출용 SSOT) ───────────────────
  Song? _currentSong;
  List<Song> _songs = [];
  bool _isShuffleOn = false;
  RepeatModeState _repeatMode = RepeatModeState.off;
  bool _isLoading = false;
  String? _playError;

  final _currentSongCtrl = StreamController<Song?>.broadcast();
  final _isLoadingCtrl = StreamController<bool>.broadcast();
  final _playErrorCtrl = StreamController<String?>.broadcast();
  final _playlistCtrl = StreamController<List<Song>>.broadcast();
  final _isShuffleOnCtrl = StreamController<bool>.broadcast();
  final _repeatModeCtrl = StreamController<RepeatModeState>.broadcast();

  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<AudioServiceRepeatMode>? _repeatRequestSub;
  StreamSubscription<AudioServiceShuffleMode>? _shuffleRequestSub;

  DateTime? _lastSkipTime;

  MusicService(this._handler) {
    _currentIndexSub = _handler.currentIndexStream.listen((index) {
      if (index != null && index < _songs.length) {
        _currentSong = _songs[index];
        _currentSongCtrl.add(_currentSong);
        _handler.setCurrentSong(_currentSong);
      }
    });

    _repeatRequestSub = _handler.repeatModeRequestStream.listen((mode) {
      _repeatMode = _fromAudioServiceRepeatMode(mode);
      _repeatModeCtrl.add(_repeatMode);
      _handler.setLoopMode(_toLoopMode(_repeatMode));
      _handler.pushState(repeatMode: _repeatMode, shuffleOn: _isShuffleOn);
    });

    _shuffleRequestSub = _handler.shuffleModeRequestStream.listen((mode) {
      _isShuffleOn = mode != AudioServiceShuffleMode.none;
      _isShuffleOnCtrl.add(_isShuffleOn);
      _handler.setShuffleModeEnabled(_isShuffleOn);
      _handler.pushState(repeatMode: _repeatMode, shuffleOn: _isShuffleOn);
    });
  }

  // ─── 스냅샷 게터 ───────────────────────────────────
  @override
  Song? get currentSong => _currentSong;
  @override
  bool get isPlaying => _handler.isPlaying;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get playError => _playError;
  @override
  List<Song> get playlist => List.unmodifiable(_songs);
  @override
  bool get isShuffleOn => _isShuffleOn;
  @override
  RepeatModeState get repeatMode => _repeatMode;
  @override
  Duration get position => _handler.position;
  @override
  Duration? get duration => _handler.duration;

  // ─── 스트림 ────────────────────────────────────────
  @override
  Stream<Song?> get currentSongStream => _currentSongCtrl.stream;
  @override
  Stream<bool> get isLoadingStream => _isLoadingCtrl.stream;
  @override
  Stream<String?> get playErrorStream => _playErrorCtrl.stream;
  @override
  Stream<List<Song>> get playlistStream => _playlistCtrl.stream;
  @override
  Stream<bool> get isShuffleOnStream => _isShuffleOnCtrl.stream;
  @override
  Stream<RepeatModeState> get repeatModeStream => _repeatModeCtrl.stream;

  @override
  Stream<bool> get isPlayingStream => _handler.isPlayingStream;
  @override
  Stream<Duration> get positionStream => _handler.positionStream;
  @override
  Stream<Duration?> get durationStream => _handler.durationStream;

  @override
  Future<void> setPlaylist(List<Song> songs) async {
    _songs = List.from(songs);
    _playlistCtrl.add(_songs);
    await _handler.setQueue(_songs);
  }

  @override
  Future<void> playPlaylist(List<Song> songs, int startIndex) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;
    _setLoading(true);
    try {
      _songs = List.from(songs);
      _playlistCtrl.add(_songs);
      _currentSong = _songs[startIndex];
      _currentSongCtrl.add(_currentSong);
      _handler.setCurrentSong(_currentSong);
      await _handler.setQueue(_songs, initialIndex: startIndex);
      await _handler.play();
    } catch (e) {
      _setError('재생 중 오류가 발생했습니다');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Future<void> playSong(Song song) async {
    if (!File(song.filePath).existsSync()) {
      _setError('파일을 찾을 수 없습니다: ${song.title}');
      return;
    }
    clearError();
    _setLoading(true);
    try {
      final index = _songs.indexWhere((s) => s.id == song.id);
      _currentSong = song;
      _currentSongCtrl.add(song);
      _handler.setCurrentSong(song);
      if (index != -1) {
        await _handler.jumpTo(index);
        await _handler.play();
      } else {
        _songs = [song];
        _playlistCtrl.add(_songs);
        await _handler.playFile(song.filePath);
      }
    } catch (e) {
      _setError('재생 중 오류가 발생했습니다: ${song.title}');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> stop() => _handler.stop();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> playNext() async {
    if (!_debounce()) return;
    await _handler.skipToNext();
  }

  @override
  Future<void> playPrevious() async {
    if (!_debounce()) return;
    await _handler.skipToPrevious();
  }

  @override
  Future<void> cycleRepeatMode() async {
    _repeatMode = switch (_repeatMode) {
      RepeatModeState.off => RepeatModeState.one,
      RepeatModeState.one => RepeatModeState.all,
      RepeatModeState.all => RepeatModeState.off,
    };
    _repeatModeCtrl.add(_repeatMode);
    await _handler.setLoopMode(_toLoopMode(_repeatMode));
    _handler.pushState(repeatMode: _repeatMode, shuffleOn: _isShuffleOn);
  }

  @override
  Future<void> toggleShuffle() async {
    if (_songs.isEmpty) return;
    _isShuffleOn = !_isShuffleOn;
    _isShuffleOnCtrl.add(_isShuffleOn);
    await _handler.setShuffleModeEnabled(_isShuffleOn);
    _handler.pushState(repeatMode: _repeatMode, shuffleOn: _isShuffleOn);
  }

  @override
  void clearError() {
    if (_playError == null) return;
    _playError = null;
    _playErrorCtrl.add(null);
  }

  @override
  void dispose() {
    _currentIndexSub?.cancel();
    _repeatRequestSub?.cancel();
    _shuffleRequestSub?.cancel();
    _currentSongCtrl.close();
    _isLoadingCtrl.close();
    _playErrorCtrl.close();
    _playlistCtrl.close();
    _isShuffleOnCtrl.close();
    _repeatModeCtrl.close();
  }

  bool _debounce() {
    final now = DateTime.now();
    if (_lastSkipTime != null &&
        now.difference(_lastSkipTime!) < const Duration(milliseconds: 500)) {
      return false;
    }
    _lastSkipTime = now;
    return true;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _isLoadingCtrl.add(value);
  }

  void _setError(String message) {
    _playError = message;
    _playErrorCtrl.add(message);
  }

  LoopMode _toLoopMode(RepeatModeState state) => switch (state) {
        RepeatModeState.off => LoopMode.off,
        RepeatModeState.one => LoopMode.one,
        RepeatModeState.all => LoopMode.all,
      };

  RepeatModeState _fromAudioServiceRepeatMode(AudioServiceRepeatMode mode) =>
      switch (mode) {
        AudioServiceRepeatMode.none => RepeatModeState.off,
        AudioServiceRepeatMode.one => RepeatModeState.one,
        AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => RepeatModeState.all,
      };
}