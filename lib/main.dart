import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:music_player/UI/HomePage.dart';
import 'package:music_player/UI/PlaylistPage.dart';
import 'package:music_player/UI/SettingsPage.dart';
import 'package:music_player/UI/DownloadPage.dart';
import 'package:music_player/DB/DB_Provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => DB_Provider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();

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

      themeMode: musicProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 🔥 여기에 watch를 추가해야 스위치를 누를 때 상단바와 하단바가 즉시 변합니다!
    final musicProvider = context.watch<MusicProvider>();
    final isDark = musicProvider.isDarkMode;

    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('음악', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        // 💡 다크 모드일 때 하단바 색상 수동 지정
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        selectedItemColor: isDark ? Colors.purpleAccent : Colors.purple,
        unselectedItemColor: isDark ? Colors.white38 : Colors.grey,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: '플레이리스트'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: '다운로드'), // 아이콘 겹침 수정
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}