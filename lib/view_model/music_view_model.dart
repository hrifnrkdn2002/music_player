import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/service/audio_player_handler.dart';

// 현재 반복버튼 터치시 한 곡 반복->전체 반복-> 반복 안함 순임.
enum RepeatModeState { off, one, all }

// 옵저버패턴을 적용시키기위해 ChangeNofier를 상속받음.
class MusicViewModel extends ChangeNotifier {
  final AudioPlayerHandler _handler;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  Song? currentSong;
  bool isLoading = false;
  String? playError;

  DateTime? _lastClickTime;

  List<Song> _playlist = [];
  List<Song> _originalPlaylist = [];

  bool _isShuffleOn = false;
  RepeatModeState _repeatModeState = RepeatModeState.off;

  AudioPlayer get player => _handler.player;

  bool get isPlaying => _handler.player.playing;

  List<Song> get playlist => _playlist;

  bool get isShuffleOn => _isShuffleOn;

  RepeatModeState get repeatModeState => _repeatModeState;

  MusicViewModel(this._handler) {
    // 잠금화면/알림창에서 오는 명령 콜백 등록
    _handler.onSkipToNext = playNext;
    _handler.onSkipToPrevious = playPrevious;
    _handler.onSetRepeatMode = _handleRepeatModeFromOS;
    _handler.onSetShuffleMode = _handleShuffleModeFromOS;

    _playingSubscription = _handler.player.playingStream.listen((_) {
      //플레이어엔진의 데이터와 뷰모델의 데이터를 동기화하는 함수
      _syncHandlerState();
      //동기화하고 알림
      notifyListeners();
    });

    //PlayerState 객체를 반환하는 스트림을 구독
    //PlayerState는 playing과 processingState를 포함하고 있음
    //TODO: StreamSubscription은 view_model이 파괴될 때 반드시 cancel해줘야함
    _playerStateSubscription = _handler.player.playerStateStream.listen((
      state,
    ) async {
      //만약 진행상태가 완료라면 곡완료함수를 실행
      if (state.processingState == ProcessingState.completed) {
        await _handleSongComplete();
      }
    });
  }

  void setPlaylist(List<Song> songs) {
    _playlist = List.from(songs);
    _originalPlaylist = List.from(songs);
    notifyListeners();
  }

  // 🎵 곡 재생 핵심 로직
  Future<void> playSong(Song song) async {
    try {
      if (!File(song.filePath).existsSync()) {
        playError = '파일을 찾을 수 없습니다: ${song.title}';
        notifyListeners();
        return;
      }

      playError = null;
      currentSong = song;
      isLoading = true;
      notifyListeners();
      //현재 상태로는 재생 중인 곡 선택 시 다시 재생할 가능성 매우 높음
      await _handler.player.stop();
      await _handler.player.setFilePath(song.filePath);
      await _handler.player.play();

      // 잠금화면/알림창에 곡 정보 전달
      _handler.setCurrentSong(song);
      _syncHandlerState();
    } catch (e) {
      playError = '재생 중 오류가 발생했습니다: ${song.title}';
      debugPrint('playSong 오류: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ⏭️ 다음 곡 재생
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!) < const Duration(milliseconds: 500)) {
      debugPrint('연타 무시됨');
      return;
    }
    _lastClickTime = now;

    try {
      final currentIndex = _playlist.indexWhere(
        (song) => song.id != null && song.id == currentSong?.id,
      );

      if (currentIndex != -1 && currentIndex < _playlist.length - 1) {
        await playSong(_playlist[currentIndex + 1]);
      } else if (_repeatModeState == RepeatModeState.all) {
        await playSong(_playlist.first);
      }
    } catch (e) {
      debugPrint('playNext 오류: $e');
    }
  }

  // ⏮️ 이전 곡 재생
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;

    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!) < const Duration(milliseconds: 500)) {
      debugPrint('연타 무시됨');
      return;
    }
    _lastClickTime = now;

    try {
      final currentIndex = _playlist.indexWhere(
        (song) => song.id != null && song.id == currentSong?.id,
      );

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
      _syncHandlerState();
      notifyListeners();
    } catch (e) {
      debugPrint('cycleRepeatMode 오류: $e');
    }
  }

  //repeatModeState를 오디오엔진이 알게 하기 위함
  //TODO: 현재 상태는 반복모드 코드가 중복된 상황임 수동으로 직접 구현할 지 엔진자체 기능을 사용할 지 정할 것
  Future<void> _applyLoopMode() async {
    if (_repeatModeState == RepeatModeState.one) {
      await _handler.player.setLoopMode(LoopMode.one);
    } else if (_repeatModeState == RepeatModeState.all) {
      await _handler.player.setLoopMode(LoopMode.all);
    } else {
      await _handler.player.setLoopMode(LoopMode.off);
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
        shuffled.removeWhere(
          (song) => song.id != null && song.id == current.id,
        );
        shuffled.insert(0, current);
      }
      _playlist = shuffled;
    }

    _syncHandlerState();
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

      await _handler.player.stop();
      await _handler.player.setFilePath(currentSong!.filePath);
      await _handler.player.play();

      _handler.setCurrentSong(currentSong);
      _syncHandlerState();
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

  // OS(잠금화면/알림창)에서 repeat 버튼 눌렸을 때
  Future<void> _handleRepeatModeFromOS(AudioServiceRepeatMode mode) async {
    switch (mode) {
      case AudioServiceRepeatMode.none:
        _repeatModeState = RepeatModeState.off;
        break;
      case AudioServiceRepeatMode.one:
        _repeatModeState = RepeatModeState.one;
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        _repeatModeState = RepeatModeState.all;
        break;
    }
    await _applyLoopMode();
    _syncHandlerState();
    notifyListeners();
  }

  // OS(잠금화면/알림창)에서 shuffle 버튼 눌렸을 때
  Future<void> _handleShuffleModeFromOS(AudioServiceShuffleMode mode) async {
    final shouldShuffle = mode != AudioServiceShuffleMode.none;
    if (shouldShuffle != _isShuffleOn) {
      toggleShuffle();
    }
  }

  /// 핸들러(알림/잠금화면)의 재생 상태를 현재 앱 상태와 동기화
  void _syncHandlerState() {
    _handler.pushState(repeatMode: _repeatModeState, shuffleOn: _isShuffleOn);
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }
}
