import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/model/song.dart';
import 'package:music_player/view_model/music_view_model.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // MusicProvider에서 주입하는 콜백
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;
  Future<void> Function(AudioServiceRepeatMode)? onSetRepeatMode;
  Future<void> Function(AudioServiceShuffleMode)? onSetShuffleMode;

  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    // 재생 상태 변경 시 알림/잠금화면 갱신
    _player.playingStream.listen((_) => _pushPlaybackState());
    _player.processingStateStream.listen((_) => _pushPlaybackState());
    _player.positionStream.listen((_) => _pushPlaybackState());
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  // ─── BaseAudioHandler 오버라이드 ───────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async => await onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => await onSkipToPrevious?.call();

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await onSetRepeatMode?.call(repeatMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await onSetShuffleMode?.call(shuffleMode);
  }

  // ─── 공개 업데이트 메서드 ──────────────────────────────────────

  /// 현재 곡 정보를 OS 미디어 세션에 전달
  void setCurrentSong(Song? song) {
    if (song == null) {
      mediaItem.add(null);
      return;
    }
    mediaItem.add(
      MediaItem(
        id: song.filePath,
        title: song.title,
        artist: song.artist ?? '알 수 없는 아티스트',
        duration: _player.duration,
      ),
    );
  }

  /// 재생 상태(repeat/shuffle 포함)를 OS 알림/잠금화면에 반영
  void pushState({
    required RepeatModeState repeatMode,
    required bool shuffleOn,
  }) {
    _pushPlaybackState(repeatMode: repeatMode, shuffleOn: shuffleOn);
  }

  // ─── 내부 ──────────────────────────────────────────────────────

  RepeatModeState _lastRepeatMode = RepeatModeState.off;
  bool _lastShuffleOn = false;

  void _pushPlaybackState({RepeatModeState? repeatMode, bool? shuffleOn}) {
    final repeat = repeatMode ?? _lastRepeatMode;
    final shuffle = shuffleOn ?? _lastShuffleOn;
    _lastRepeatMode = repeat;
    _lastShuffleOn = shuffle;

    final playing = _player.playing;

    // 알림창 확장 뷰 5버튼: [repeat, prev, play/pause, next, shuffle]
    // 알림창 컴팩트 뷰 3버튼(인덱스 1,2,3): prev, play/pause, next
    // 잠금화면은 알림창과 동일 (Android 10+)
    final controls = [
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
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.setRepeatMode,
          MediaAction.setShuffleMode,
        },
        // 알림 컴팩트: prev(1), play/pause(2), next(3)
        androidCompactActionIndices: const [1, 2, 3],
        processingState: _toAudioProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        repeatMode: _toAudioServiceRepeatMode(repeat),
        shuffleMode: shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
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
      await _player.dispose();
      super.stop();
    }
  }
}
