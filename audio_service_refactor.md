# AudioService 책임 분리 — 방향 결정과 근거

## 결론

**분리하는 게 맞습니다.** 이유는 명확합니다.

---

## 지금 구조의 문제점

현재 `MusicViewModel`은 **MVVM의 책임 경계를 넘어선 비대한 ViewModel**입니다.

```
MusicViewModel ─┬─ 화면 상태 (currentSong, isLoading)
                ├─ 재생 제어 (player.stop/setFilePath/play)  ← 인프라 직접 호출
                ├─ 플레이리스트 도메인 로직 (next/prev/shuffle)
                ├─ OS 미디어세션 동기화 (_syncHandlerState)
                └─ 스트림 구독 관리
```

특히 `_handler.player.setFilePath(...)`처럼 **just_audio API를 ViewModel이 직접 호출**하는 부분 — 이게 가장 큰 신호입니다. ViewModel이 특정 오디오 패키지에 종속되어 있다는 뜻이거든요.

추가로 `AudioPlayerHandler`와 `MusicViewModel`이 **콜백으로 양방향 결합**되어 있습니다 (`_handler.onSkipToNext = playNext`). 이건 "누가 주인인가"가 모호하다는 신호입니다.

---

## 분리 후 권장 구조

```
View (PlayerPage, MiniPlayer, HomePage, ...)
   │ watches (ChangeNotifier)
   ▼
ViewModel (per-screen, thin)
   │ - 화면 상태만 보유
   │ - 액션은 service에 위임
   │ uses (interface)
   ▼
AudioService  ◄─── 도메인의 단일 진실 공급원(SSOT)
   │ - currentSong, playlist, repeat, shuffle 보유
   │ - 스트림으로 상태 노출
   │ - next/prev/shuffle 등 재생 도메인 로직
   │ uses
   ▼
AudioPlayerHandler (어댑터)
   │ - BaseAudioHandler 구현만 담당
   │ - OS ↔ AudioPlayer 양방향 변환
   │ - 비즈니스 로직 0
   ▼
just_audio.AudioPlayer
```

---

## 왜 분리해야 하는가 (실무 근거 4가지)

### 1. 여러 ViewModel이 같은 재생 상태를 봐야 함

지금 만드신 `PlayerViewModel`, `MiniPlayerViewModel`, `HomeViewModel`은 전부 "지금 뭐 재생 중인지"를 알아야 합니다. 재생 상태를 한 VM이 들고 있으면 나머지 VM들이 그 VM을 또 참조해야 해요. 결국 어떤 ViewModel은 "다른 ViewModel을 의존하는 서비스" 역할을 하게 되고, 이건 MVVM이 가장 피하려는 구조입니다.

> **Spotify, YouTube Music 같은 앱은 예외 없이 PlaybackService를 싱글톤으로 두고 각 화면 VM이 거기서 상태를 끌어옵니다.**

### 2. ViewModel 수명 < 재생 수명

화면 전환되면 ViewModel은 dispose됩니다. 하지만 음악은 계속 재생되어야 하죠. 재생 상태를 ViewModel이 들고 있으면 "화면 진입 시 복원" 로직이 필요해집니다. Service(DI 싱글톤)에 두면 자연스럽게 해결됩니다.

> **Android의 공식 가이드(Media3/ExoPlayer + MediaSessionService)도 동일한 이유로 Service 분리를 강제합니다.**

### 3. 테스트 가능성

지금 `MusicViewModel`을 단위 테스트하려면 `AudioPlayer`(just_audio)를 모킹해야 하는데, 이건 사실상 불가능합니다(final 클래스, native 의존). 인터페이스로 한 번 감싸면 `MockAudioService`로 끝납니다.

> **이게 `interface.dart`에 `AudioServiceInterface`를 이미 선언해두신 이유일 것입니다. 끝까지 가야 합니다.**

### 4. just_audio 교체 가능성

just_audio가 maintainership 이슈로 멈춘 적이 있습니다(2024). 만약 audioplayers나 media_kit으로 갈아타야 한다면, 지금 구조에선 ViewModel과 Handler 둘 다 고쳐야 합니다. 분리하면 Handler 한 곳만 고치면 됩니다.

> **"외부 의존성은 단 한 곳에서만 만나라" — 헥사고날 아키텍처의 핵심 원칙입니다.**

---

## 책임 재배치 가이드

| 현재 위치 | 옮겨갈 위치 | 이유 |
|---|---|---|
| `playSong`, `playNext`, `playPrevious` | **AudioService** | 도메인 동작, 화면 무관 |
| `_playlist`, `_repeatModeState`, `_isShuffleOn` | **AudioService** | 화면 간 공유되는 상태 |
| `currentSong`, `isPlaying` (getter) | **AudioService**가 스트림으로 노출 | SSOT |
| `isLoading`, `playError` | **ViewModel** | 화면별 UI 상태 |
| `_lastClickTime` (연타 방지) | **AudioService** | 도메인 규칙 (어느 화면에서 눌러도 동일) |
| `_syncHandlerState` | **AudioService**가 Handler 구독 | Handler는 service 상태만 반영 |
| `_handler.onSkipToNext = ...` 콜백 결합 | **Handler가 Service를 호출** | 단방향 |

---

## 순환 의존 주의 (실무에서 가장 많이 막히는 지점)

Service가 Handler를 쓰고, Handler(OS 버튼 이벤트)가 Service를 호출해야 하므로 양방향 참조가 됩니다. 해결 패턴 3가지:

1. **2단계 초기화** (가장 단순): `setupLocator`에서 둘을 만든 뒤 `service.bindHandler(handler)` 같은 메서드로 묶기
2. **Handler가 Service interface만 받기**: 생성자에 `AudioServiceInterface` 주입, get_it의 `registerLazySingleton` 활용
3. **EventBus/Stream**: Handler는 이벤트만 발행, Service가 구독. 유연하지만 추적이 어려움 → 권장 안 함

**(1)번 추천.** 코드가 가장 솔직합니다.

---

## 하지 말아야 할 것

- **Service에 `BuildContext`나 `ChangeNotifier`를 넣지 말 것.** Service는 Flutter에 무지해야 합니다(pure Dart). 알림은 `Stream`으로만.
- **ViewModel에 비즈니스 로직 잔존 금지.** 분리하기로 했으면 "VM은 service 호출과 화면 상태만"을 엄격히 지킬 것. 어중간하면 분리 안 한 것보다 더 혼란스럽습니다.
- **`music_service.dart`가 빈 파일인데**, 같은 고민으로 비워두신 것 같습니다. `audio_service.dart`로 이름을 바꾸는 것을 추천 (audio_service 패키지와 헷갈리지 않게).

---

## 한 줄 요약

> **ViewModel은 "지금 화면이 무엇을 보여줄지"만 알면 되고, "지금 무엇이 재생 중인지"는 Service가 알아야 합니다.** 이 경계를 지금 명확히 그어두지 않으면 화면이 늘어날수록 기하급수적으로 꼬입니다.
