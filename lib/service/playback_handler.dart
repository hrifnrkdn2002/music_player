import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/model/song.dart';

class PlaybackHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // OS → Service: repeat/shuffle 변경 요청 스트림
  final _repeatRequestController =
      StreamController<AudioServiceRepeatMode>.broadcast();
  final _shuffleRequestController =
      StreamController<AudioServiceShuffleMode>.broadcast();

  Stream<AudioServiceRepeatMode> get repeatModeRequestStream =>
      _repeatRequestController.stream;
  Stream<AudioServiceShuffleMode> get shuffleModeRequestStream =>
      _shuffleRequestController.stream;

  // 엔진 스트림 패스스루 (Service가 직접 구독)
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // 동기 스냅샷
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  PlaybackHandler() {
    _player.playingStream.listen((_) => _pushPlaybackState());
    _player.processingStateStream.listen((_) => _pushPlaybackState());
    _player.positionStream.listen((_) => _pushPlaybackState());
    _player.durationStream.listen((d) {
      final current = mediaItem.value;
      if (current != null && d != null) {
        mediaItem.add(current.copyWith(duration: d));
      }
    });
  }

  // ─── Service → 엔진 명령 ──────────────────────────────────

  Future<void> setQueue(List<Song> songs, {int initialIndex = 0}) {
    final source = ConcatenatingAudioSource(
      children: songs.map((s) => AudioSource.file(s.filePath)).toList(),
    );
    return _player.setAudioSource(source, initialIndex: initialIndex);
  }

  Future<void> playFile(String filePath) async {
    await _player.setFilePath(filePath);
    await _player.play();
  }

  // ConcatenatingAudioSource 내 특정 인덱스로 이동
  Future<void> jumpTo(int index) =>
      _player.seek(Duration.zero, index: index);

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  void setCurrentSong(Song? song) {
    if (song == null) {
      mediaItem.add(null);
      return;
    }
    mediaItem.add(MediaItem(
      id: song.filePath,
      title: song.title,
      artist: song.artist ?? '알 수 없는 아티스트',
      duration: _player.duration,
    ));
  }

  void pushState({required RepeatModeState repeatMode, required bool shuffleOn}) {
    _pushPlaybackState(repeatMode: repeatMode, shuffleOn: shuffleOn);
  }

  // ─── BaseAudioHandler 오버라이드 (OS → 엔진/Service) ───────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  // repeat/shuffle은 상태가 Service에 있으므로 스트림으로만 전달
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async =>
      _repeatRequestController.add(repeatMode);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async =>
      _shuffleRequestController.add(shuffleMode);

  // ─── 내부 ──────────────────────────────────────────────────

  RepeatModeState _lastRepeatMode = RepeatModeState.off;
  bool _lastShuffleOn = false;

  void _pushPlaybackState({RepeatModeState? repeatMode, bool? shuffleOn}) {
    final repeat = repeatMode ?? _lastRepeatMode;
    final shuffle = shuffleOn ?? _lastShuffleOn;
    _lastRepeatMode = repeat;
    _lastShuffleOn = shuffle;

    final playing = _player.playing;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl(
          androidIcon: repeat == RepeatModeState.one
              ? 'drawable/ic_repeat_one'
              : 'drawable/ic_repeat',
          label: 'Repeat',
          action: MediaAction.setRepeatMode,
        ),
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl(
          androidIcon: 'drawable/ic_shuffle',
          label: 'Shuffle',
          action: MediaAction.setShuffleMode,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.setRepeatMode,
        MediaAction.setShuffleMode,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: _toAudioProcessingState(_player.processingState),
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      repeatMode: _toAudioServiceRepeatMode(repeat),
      shuffleMode:
          shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    ));
  }

  AudioProcessingState _toAudioProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  AudioServiceRepeatMode _toAudioServiceRepeatMode(RepeatModeState mode) {
    switch (mode) {
      case RepeatModeState.off:
        return AudioServiceRepeatMode.none;
      case RepeatModeState.one:
        return AudioServiceRepeatMode.one;
      case RepeatModeState.all:
        return AudioServiceRepeatMode.all;
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      _repeatRequestController.close();
      _shuffleRequestController.close();
      await _player.dispose();
      super.stop();
    }
  }
}