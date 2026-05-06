import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player/service/audio_player_handler.dart';
import 'package:music_player/view/setting_page.dart';
import 'package:music_player/view/download_page.dart';
import 'package:music_player/view/home_page.dart';
import 'package:music_player/view/playlist_page.dart';
import 'package:music_player/view_model/dark_mode_view_model.dart';
import 'package:music_player/view_model/database_view_model.dart';
import 'package:music_player/view_model/music_view_model.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late AudioPlayerHandler audioHandler;

  try {
    audioHandler =
        //BaseAudioHandler를 상송받은 AudioPlayerHandler의 인스턴스 audioHandler를 OS에 등록하기 위해
        //AudioService.init 함수를 사용함
        await AudioService.init(
          builder: () => AudioPlayerHandler(),
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
    audioHandler = AudioPlayerHandler();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicViewModel(audioHandler)),
        ChangeNotifierProvider(create: (_) => DatabaseViewModel()),
        ChangeNotifierProvider(create: (_) => DarkModeViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<DarkModeViewModel>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '음악 플레이어',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.purple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.purpleAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C1C),
          selectedItemColor: Colors.purpleAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),

      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const PlaylistPage(),
    const DownloadPage(),
    const SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음악', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: '플레이리스트',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: '다운로드'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
