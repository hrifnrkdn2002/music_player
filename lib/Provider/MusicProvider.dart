import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/Models/Song.dart';

enum RepeatModeState {
  off,
  one,
  all,
}

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  Song? currentSong;
  bool isLoading = false;

  // ⏱️ 연타 방지를 위한 마지막 클릭 시간 기록 변수
  DateTime? _lastClickTime;

  List<Song> _playlist = [];
  List<Song> _originalPlaylist = [];

  bool _isShuffleOn = false;
  RepeatModeState _repeatModeState = RepeatModeState.off;

  // 🌙 [NEW] 다크 모드 상태 변수 (기본값: 라이트 모드)
  bool _isDarkMode = false;

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  List<Song> get playlist => _playlist;
  bool get isShuffleOn => _isShuffleOn;
  RepeatModeState get repeatModeState => _repeatModeState;

  // 🌙 [NEW] 다크 모드 getter
  bool get isDarkMode => _isDarkMode;

  MusicProvider() {
    _playingSubscription = _player.playingStream.listen((_) {
      notifyListeners();
    });

    _playerStateSubscription = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _handleSongComplete();
      }
    });
  }

  // 🌓 [NEW] 다크 모드 토글 함수
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // 상태 변경을 알려 UI를 새로 고침 합니다.
  }

  void setPlaylist(List<Song> songs) {
    _playlist = List.from(songs);
    _originalPlaylist = List.from(songs);
    notifyListeners();
  }

  // 🎵 곡 재생 핵심 로직
  Future<void> playSong(Song song) async {
    try {
      currentSong = song;
      isLoading = true;
      notifyListeners();

      await _player.stop();
      await _player.setFilePath(song.filePath);
      await _player.play();
    } catch (e) {
      debugPrint('playSong 오류: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ⏭️ 다음 곡 재생 (시간 기반 연타 방지 적용)
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    // 마지막 클릭 후 500ms(0.5초)가 지나지 않았으면 연타로 인식하고 무시합니다.
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!) < const Duration(milliseconds: 500)) {
      debugPrint('연타 무시됨');
      return;
    }
    _lastClickTime = now;

    try {
      final currentIndex = _playlist.indexWhere((song) => song.filePath == currentSong?.filePath);

      if (currentIndex != -1 && currentIndex < _playlist.length - 1) {
        await playSong(_playlist[currentIndex + 1]);
      } else if (_repeatModeState == RepeatModeState.all) {
        await playSong(_playlist.first);
      }
    } catch (e) {
      debugPrint('playNext 오류: $e');
    }
  }

  // ⏮️ 이전 곡 재생 (시간 기반 연타 방지 적용)
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    // 마지막 클릭 후 500ms(0.5초)가 지나지 않았으면 연타로 인식하고 무시합니다.
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!) < const Duration(milliseconds: 500)) {
      debugPrint('연타 무시됨');
      return;
    }
    _lastClickTime = now;

    try {
      final currentIndex = _playlist.indexWhere((song) => song.filePath == currentSong?.filePath);

      if (currentIndex > 0) {
        await playSong(_playlist[currentIndex - 1]);
      } else if (_repeatModeState == RepeatModeState.all) {
        await playSong(_playlist.last);
      }
    } catch (e) {
      debugPrint('playPrevious 오류: $e');
    }
  }

  void cycleRepeatMode() {
    try {
      if (_repeatModeState == RepeatModeState.off) {
        _repeatModeState = RepeatModeState.one;
      } else if (_repeatModeState == RepeatModeState.one) {
        _repeatModeState = RepeatModeState.all;
      } else {
        _repeatModeState = RepeatModeState.off;
      }
      _applyLoopMode();
      notifyListeners();
    } catch (e) {
      debugPrint('cycleRepeatMode 오류: $e');
    }
  }

  Future<void> _applyLoopMode() async {
    if (_repeatModeState == RepeatModeState.one) {
      await _player.setLoopMode(LoopMode.one);
    } else if (_repeatModeState == RepeatModeState.all) {
      await _player.setLoopMode(LoopMode.all);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  void toggleShuffle() {
    if (_playlist.isEmpty) return;

    final current = currentSong;

    if (_isShuffleOn) {
      _isShuffleOn = false;
      _playlist = List.from(_originalPlaylist);
    } else {
      _isShuffleOn = true;

      final shuffled = List<Song>.from(_playlist);
      shuffled.shuffle();

      if (current != null) {
        shuffled.removeWhere((song) => song.filePath == current.filePath);
        shuffled.insert(0, current);
      }

      _playlist = shuffled;
    }

    notifyListeners();
  }
  Future<void> playPlaylist(List<Song> songs, int startIndex) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    try {
      _playlist = List.from(songs);
      _originalPlaylist = List.from(songs);

      currentSong = _playlist[startIndex];

      isLoading = true;
      notifyListeners();

      await _player.stop();
      await _player.setFilePath(currentSong!.filePath);
      await _player.play();
    } catch (e) {
      debugPrint('playPlaylist 오류: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleSongComplete() async {
    if (currentSong == null) return;

    if (_repeatModeState == RepeatModeState.off) {
      await playNext();
    }
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}