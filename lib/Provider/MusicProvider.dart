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

  List<Song> _playlist = [];
  List<Song> _originalPlaylist = [];

  bool _isShuffleOn = false;
  RepeatModeState _repeatModeState = RepeatModeState.off;

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  List<Song> get playlist => _playlist;
  bool get isShuffleOn => _isShuffleOn;
  RepeatModeState get repeatModeState => _repeatModeState;

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

  void setPlaylist(List<Song> songs) {
    final sameLength = _playlist.length == songs.length;
    final sameItems = sameLength &&
        _playlist.every((song) => songs.any((s) => s.filePath == song.filePath));

    if (sameItems) return;

    _playlist = List.from(songs);
    _originalPlaylist = List.from(songs);
    notifyListeners();
  }

  int get currentIndex {
    if (currentSong == null) return -1;
    return _playlist.indexWhere(
          (song) => song.filePath == currentSong!.filePath,
    );
  }

  bool get canPlayPrevious {
    if (_playlist.isEmpty || currentIndex == -1) return false;

    if (_repeatModeState == RepeatModeState.all) return true;

    return currentIndex > 0;
  }

  bool get canPlayNext {
    if (_playlist.isEmpty || currentIndex == -1) return false;

    if (_repeatModeState == RepeatModeState.all) return true;

    return currentIndex < _playlist.length - 1;
  }

  Future<void> playSong(Song song) async {
    final isSameSong = currentSong?.filePath == song.filePath;

    if (isSameSong) {
      if (!_player.playing) {
        await _player.play();
      }
      notifyListeners();
      return;
    }

    currentSong = song;
    isLoading = true;
    notifyListeners();

    try {
      await _player.stop();
      await _player.setFilePath(song.filePath);
      await _applyLoopMode();
      await _player.play();
    } catch (e, stackTrace) {
      debugPrint('playSong 오류: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (currentSong == null) return;

      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.audioSource == null) {
          await _player.setFilePath(currentSong!.filePath);
          await _applyLoopMode();
        }
        await _player.play();
      }
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('togglePlayPause 오류: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> pauseSong() async {
    try {
      await _player.pause();
      notifyListeners();
    } catch (e) {
      debugPrint('pauseSong 오류: $e');
    }
  }

  Future<void> resumeSong() async {
    try {
      if (currentSong == null) return;

      if (_player.audioSource == null) {
        await _player.setFilePath(currentSong!.filePath);
        await _applyLoopMode();
      }

      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('resumeSong 오류: $e');
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    final index = currentIndex;
    if (index == -1) return;

    if (index > 0) {
      await playSong(_playlist[index - 1]);
      return;
    }

    if (_repeatModeState == RepeatModeState.all && _playlist.isNotEmpty) {
      await playSong(_playlist.last);
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    final index = currentIndex;
    if (index == -1) return;

    if (index < _playlist.length - 1) {
      await playSong(_playlist[index + 1]);
      return;
    }

    if (_repeatModeState == RepeatModeState.all && _playlist.isNotEmpty) {
      await playSong(_playlist.first);
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('seekTo 오류: $e');
    }
  }

  Future<void> cycleRepeatMode() async {
    try {
      if (_repeatModeState == RepeatModeState.off) {
        _repeatModeState = RepeatModeState.one;
      } else if (_repeatModeState == RepeatModeState.one) {
        _repeatModeState = RepeatModeState.all;
      } else {
        _repeatModeState = RepeatModeState.off;
      }

      await _applyLoopMode();
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

  Future<void> _handleSongComplete() async {
    if (currentSong == null) return;

    // repeat one / repeat all 은 LoopMode가 처리
    if (_repeatModeState == RepeatModeState.off) {
      final index = currentIndex;
      if (index >= 0 && index < _playlist.length - 1) {
        await playSong(_playlist[index + 1]);
      }
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