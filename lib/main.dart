import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:music_player/UI/HomePage.dart';
import 'package:music_player/UI/PlaylistPage.dart';
import 'package:music_player/UI/SettingsPage.dart';
import 'package:music_player/UI/DownloadPage.dart';
import 'package:music_player/DB/DB_Provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MusicProvider()),
      ChangeNotifierProvider(create: (_) => DB_Provider()),
    ],
    child: MaterialApp(
      home: MainPage(),
    ),
  )
  );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    PlaylistPage(),
    DownloadPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('음악'), centerTitle: true),
      body: _pages[_currentIndex], // ⭐ 여기 핵심

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: '플레이리스트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: '다운로드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}