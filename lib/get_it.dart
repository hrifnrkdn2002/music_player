import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:music_player/index/repository_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/repository/database_repository.dart';
import 'package:music_player/service/database_service.dart';
import 'package:music_player/service/music_service.dart';
import 'package:music_player/service/playback_handler.dart';

import 'database_helper.dart';

// 1. GetIt 인스턴스 생성
final GetIt locator = GetIt.instance;

// 2. 등록을 위한 함수 정의
Future<void> setupLocator() async {
  // 여기에 등록할 클래스들을 정의합니다.
  final helper = DatabaseHelper();
  final db = await helper.database;

  //데이터베이스 영역 싱글톤으로 등록
  locator.registerSingleton<Database>(db);
  locator.registerSingleton<DatabaseRepositoryInterface>(DatabaseRepository(db));
  locator.registerSingleton<DatabaseServiceInterface>(DatabaseService(locator<DatabaseRepositoryInterface>()));

  //오디오 영역 싱글톤으로 등록
  //AudioService.init은 OS 미디어세션을 바인딩하므로 main 진입 전 1회만 실행
  //AudioPlayer 인스턴스는 PlaybackHandler 내부에서 생성되므로 별도 등록하지 않음 (캡슐화 유지)
  late PlaybackHandler handler;
  try {
    handler = await AudioService.init(
      builder: () => PlaybackHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_player.channel',
        androidNotificationChannelName: '음악 플레이어',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[AudioService] init timeout — 서비스 연결 실패');
        throw Exception('AudioService init timed out');
      },
    );
  } catch (e, stack) {
    debugPrint('[AudioService] init 오류: $e');
    debugPrint(stack.toString());
    // 초기화 실패 시에도 앱이 실행되도록 빈 핸들러 생성
    handler = PlaybackHandler();
  }
  locator.registerSingleton<PlaybackHandler>(handler);
  locator.registerSingleton<MusicServiceInterface>(
    MusicService(locator<PlaybackHandler>()),
  );
}


