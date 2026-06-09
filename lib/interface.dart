import 'package:just_audio/just_audio.dart';

import 'index/repository_index.dart';

// 반복 모드 상태 (off → one → all 순환)
enum RepeatModeState { off, one, all }

abstract class MusicServiceInterface {
  // ─── 상태 스냅샷 게터 (VM 생성 시 초기값 시드용) ─────
  // Stream은 마지막 값을 재방송하지 않으므로(뷰모델은 싱글톤객체가 방송한 이전 상태를 알 수 없음)
  // 늦게 구독한 VM이 현재 상태를 동기로 가져갈 수 있게 게터 제공.
  Song? get currentSong;
  bool get isPlaying;
  bool get isLoading;
  String? get playError;
  List<Song> get playlist;
  bool get isShuffleOn;
  RepeatModeState get repeatMode;
  Duration get position;
  Duration? get duration;

  // ─── 상태 스트림 (VM이 구독해 갱신) ────────────────
  Stream<Song?> get currentSongStream;
  Stream<bool> get isPlayingStream;
  Stream<bool> get isLoadingStream;
  Stream<String?> get playErrorStream;
  Stream<List<Song>> get playlistStream;
  Stream<bool> get isShuffleOnStream;
  Stream<RepeatModeState> get repeatModeStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  // ─── 명령: 큐 설정 ─────────────────────────────────
  Future<void> setPlaylist(List<Song> songs);
  Future<void> playPlaylist(List<Song> songs, int startIndex);

  // ─── 명령: 재생 제어 ───────────────────────────────
  Future<void> playSong(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> playNext();
  Future<void> playPrevious();

  // ─── 명령: 모드 전환 ───────────────────────────────
  Future<void> cycleRepeatMode();
  Future<void> toggleShuffle();

  // ─── 에러 클리어 (VM이 스낵바 표시 후 호출) ──────────
  void clearError();

  // ─── 정리 ──────────────────────────────────────────
  void dispose();
}

abstract class DatabaseRepositoryInterface {

  //음악정보테이블 관리
  Future<int> insertSong(Song song);
  Future<List<Song>> getAllSongs();
  Future<int> deleteSong(int id);
  Future<int> updateSong(Song song);

  //플레이리스트테이블 관리
  Future<int> createPlaylist(String name);
  Future<List<Playlist>> getPlaylists();
  Future<int> updatePlaylistName(int id, String newName);
  Future<int> deletePlaylist(int id);

  //음악-플레이리스트 조인 테이블 관리
  Future<int> addSongToPlaylist(int playlistId, int songId);
  Future<List<Song>> getSongsInPlaylist(int playlistId);
  Future<int> removeSongFromPlaylist(int playlistId, int songId);
  Future<void> updatePlaylistSongOrder(int playlistId, List<Song> songs);
}

abstract class DatabaseServiceInterface {
  Future<bool> pickAndInsertSongs(List<Song> songs);
}

abstract class YoutubeServiceInterface {
  // URL → 메타데이터(Song). 곡 추가 시점에 호출.
  Future<Song> resolveMetadata(String url);
  // URL → 재생용 오디오 소스. 큐 빌드/재생 시점에 호출.
  StreamAudioSource createSource(String url);
  void dispose();
}