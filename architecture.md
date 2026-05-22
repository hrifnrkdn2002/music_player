# Music Player 아키텍처 명세

## 레이어 구조

```
┌─────────────────────────────────────┐
│              View                   │  Flutter Widgets
│   (StatelessWidget / StatefulWidget) │
└────────────────┬────────────────────┘
                 │ context.watch / context.read
┌────────────────▼────────────────────┐
│            ViewModel                │  ChangeNotifier + Provider
│   (페이지별 VM, DarkModeViewModel)    │
└────────────────┬────────────────────┘
                 │ 메서드 호출
┌────────────────▼────────────────────┐
│             Service                 │  비즈니스 로직 / 상태 관리
│   (MusicService, DatabaseService)   │
└────────────────┬────────────────────┘
                 │ 메서드 호출
┌────────────────▼────────────────────┐
│           Repository                │  데이터 접근 추상화
│       (DatabaseRepository)          │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Infrastructure             │  외부 시스템
│   SQLite │ AudioPlayer │ OS Media   │
└─────────────────────────────────────┘
```

## 의존성 주입 (DI)

- **get_it** — Service / Repository 레이어 (싱글톤, 앱 수명과 동일)
- **Provider** — ViewModel 레이어 (페이지 생명주기에 따라 생성/소멸)

```
main() → setupLocator() → runApp()
                            └─ MultiProvider
                                ├─ DatabaseViewModel  (전역, 리팩토링 전 잔재)
                                └─ DarkModeViewModel  (전역, 테마 제어)

각 페이지 build()
  └─ ChangeNotifierProvider(create: (_) => PageViewModel(...))
```

---

## 핵심 클래스 명세

### PlaybackHandler (`lib/service/playback_handler.dart`)

**역할**: OS(잠금화면/알림창)와 앱 사이의 브릿지. `AudioPlayer`를 소유하고 캡슐화.

**상속**: `BaseAudioHandler with SeekHandler` (audio_service 패키지)

#### OS → Service 스트림 (상향 이벤트)

| 스트림 | 타입 | 설명 |
|--------|------|------|
| `repeatModeRequestStream` | `Stream<AudioServiceRepeatMode>` | OS에서 repeat 버튼 눌림 |
| `shuffleModeRequestStream` | `Stream<AudioServiceShuffleMode>` | OS에서 shuffle 버튼 눌림 |

> repeat/shuffle은 상태가 Service에 있으므로 Handler는 스트림만 emit. 엔진 적용은 Service가 담당.

#### 엔진 스트림 패스스루 (Service가 구독)

| 스트림 | 타입 | 설명 |
|--------|------|------|
| `currentIndexStream` | `Stream<int?>` | 현재 재생 인덱스 변경 |
| `isPlayingStream` | `Stream<bool>` | 재생/정지 상태 변경 |
| `positionStream` | `Stream<Duration>` | 재생 위치 변경 |
| `durationStream` | `Stream<Duration?>` | 곡 길이 변경 |
| `playerStateStream` | `Stream<PlayerState>` | 엔진 상태 변경 |

#### Service → 엔진 명령 API

| 메서드 | 설명 |
|--------|------|
| `setQueue(songs, {initialIndex})` | ConcatenatingAudioSource 구성 후 큐 설정 |
| `playFile(filePath)` | 단일 파일 로드 후 재생 |
| `jumpTo(index)` | 큐 내 특정 인덱스로 이동 |
| `setLoopMode(LoopMode)` | 반복 모드 엔진 적용 |
| `setShuffleModeEnabled(bool)` | 셔플 모드 엔진 적용 |
| `setCurrentSong(Song?)` | OS 미디어 세션에 곡 정보 전달 |
| `pushState({repeatMode, shuffleOn})` | OS 알림창/잠금화면 상태 갱신 |
| `play() / pause() / stop() / seek()` | BaseAudioHandler 오버라이드 |
| `skipToNext() / skipToPrevious()` | 엔진의 seekToNext/Previous 호출 |

---

### MusicService (`lib/service/music_service.dart`)

**역할**: 오디오 재생 상태의 SSOT(Single Source of Truth). PlaybackHandler를 통해 엔진을 제어하고, Stream으로 상태를 ViewModel에 노출.

**구현**: `MusicServiceInterface` (DI를 위한 인터페이스 분리)

#### 상태 스트림 (ViewModel이 구독)

| 스트림 | 원천 | 설명 |
|--------|------|------|
| `currentSongStream` | StreamController | 현재 곡 (인덱스 변경 시 자동 업데이트) |
| `isLoadingStream` | StreamController | 로딩 상태 |
| `playErrorStream` | StreamController | 에러 메시지 |
| `playlistStream` | StreamController | 현재 큐 목록 |
| `isShuffleOnStream` | StreamController | 셔플 상태 |
| `repeatModeStream` | StreamController | 반복 모드 상태 |
| `isPlayingStream` | 엔진 패스스루 | 재생/정지 |
| `positionStream` | 엔진 패스스루 | 재생 위치 |
| `durationStream` | 엔진 패스스루 | 곡 길이 |

> **앱 관리 상태**: StreamController로 직접 emit  
> **엔진 상태**: Handler의 AudioPlayer 스트림을 그대로 노출

#### 명령 API (`MusicServiceInterface` 구현)

| 메서드 | 설명 |
|--------|------|
| `setPlaylist(songs)` | 큐만 설정, 재생 시작 안 함 |
| `playPlaylist(songs, startIndex)` | 큐 설정 후 startIndex부터 재생 |
| `playSong(song)` | 큐에 있으면 해당 인덱스로 이동, 없으면 단독 재생 |
| `pause() / resume() / stop()` | Handler에 위임 |
| `seek(position)` | Handler에 위임 |
| `playNext() / playPrevious()` | 디바운스(500ms) 적용 후 Handler에 위임 |
| `cycleRepeatMode()` | off→one→all 순환, 엔진 + OS 상태 동기화 |
| `toggleShuffle()` | 셔플 토글, 엔진 + OS 상태 동기화 |
| `dispose()` | 구독 cancel, StreamController close |

#### OS 이벤트 처리

- Handler의 `repeatModeRequestStream` 구독 → `_repeatMode` 업데이트 → `setLoopMode` 호출
- Handler의 `shuffleModeRequestStream` 구독 → `_isShuffleOn` 업데이트 → `setShuffleModeEnabled` 호출

---

### DatabaseRepository (`lib/repository/database_repository.dart`)

**역할**: SQLite CRUD 추상화.  
**구현**: `DatabaseRepositoryInterface`

| 메서드 그룹 | 메서드 |
|-------------|--------|
| 곡 | `insertSong / getAllSongs / deleteSong / updateSong` |
| 플레이리스트 | `createPlaylist / getPlaylists / updatePlaylistName / deletePlaylist` |
| 곡-플레이리스트 조인 | `addSongToPlaylist / getSongsInPlaylist / removeSongFromPlaylist / updatePlaylistSongOrder` |

---

### DatabaseService (`lib/service/database_service.dart`)

**역할**: 파일 피커로 곡을 선택해 DB에 삽입.  
**구현**: `DatabaseServiceInterface`

| 메서드 | 설명 |
|--------|------|
| `pickAndInsertSongs(songs)` | 파일 피커 실행 → 중복 확인 → DB 삽입 |

---

### HomeViewModel (`lib/view_model/home_view_model.dart`)

**역할**: 홈 페이지 상태 관리. 곡 목록 로드, 검색 필터링, 재생 트리거.

**의존성**: `MusicServiceInterface`, `DatabaseRepositoryInterface`

| 항목 | 설명 |
|------|------|
| `filteredSongs` | 검색 쿼리 적용된 곡 목록 |
| `loadSongs()` | DB에서 로드 후 MusicService 큐 설정 |
| `setSearchQuery(query)` | 검색어 갱신 |
| `updateSong(song)` | DB 수정 후 재로드 |
| `deleteSong(id)` | DB 삭제 후 재로드 |
| `playSong(song)` | MusicService에 위임 |

---

### DarkModeViewModel (`lib/view_model/dark_mode_view_model.dart`)

**역할**: 앱 테마 상태 관리. SharedPreferences로 설정 영속화.

**등록**: 전역 Provider (MyApp이 watch하여 ThemeMode 결정)

| 항목 | 설명 |
|------|------|
| `isDarkMode` | 현재 테마 상태 |
| `toggleTheme()` | 토글 후 SharedPreferences 저장 |
| 생성자 | SharedPreferences에서 초기값 비동기 로드 |

---

## 미완성 / 진행 중

| 항목 | 상태 |
|------|------|
| `DatabaseViewModel` | 리팩토링 전 잔재. PlaylistVM / PlaylistDetailVM 등으로 분리 예정 |
| `PlayerViewModel` | 미구현 (player_page.dart가 삭제된 MusicViewModel 참조 중) |
| `MiniPlayerViewModel` | 미구현 |
| `PlaylistViewModel` | 미구현 |
| `PlaylistDetailViewModel` | 미구현 |
| `DownloadViewModel` | 미구현 |
| `AddSongToPlaylistViewModel` | 미구현 |
| `DatabaseRepositoryInterface` ISP 분리 | 미구현 |
| `PlaybackHandler` 콜백 → Stream 완전 전환 | 완료 |
