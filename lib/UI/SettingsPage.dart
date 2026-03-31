import 'package:flutter/material.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Provider를 통해 테마 상태를 실시간으로 감시합니다.
    final musicProvider = context.watch<MusicProvider>();

    // 🎨 현재 테마 상태에 따라 색상을 수동으로 정의합니다.
    final isDark = musicProvider.isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      // 💡 1. 배경색을 현재 테마 상태에 맞춰 강제로 칠합니다.
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: Text(
            '설정',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        // 💡 2. 앱바 배경색도 강제 주입
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // 🌓 1. 다크 모드 ON/OFF 스위치 타일
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.purpleAccent : Colors.orange,
            ),
            title: Text(
              '다크 모드',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor, // 💡 3. 타이틀 글자색 강제 주입
              ),
            ),
            subtitle: Text(
              isDark ? '어두운 테마 사용 중' : '밝은 테마 사용 중',
              style: TextStyle(color: subtitleColor), // 💡 4. 서브타이틀 글자색 강제 주입
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                // 🔥 스위치를 누르면 MusicProvider의 토글 함수가 실행되며 앱 전체 테마가 바뀝니다.
                musicProvider.toggleTheme();
              },
              activeColor: Colors.purpleAccent,
            ),
          ),

          Divider(color: isDark ? Colors.white10 : Colors.grey[300]), // 구분선 색상도 대응

          // ℹ️ 앱 정보 (예시)
          ListTile(
            leading: Icon(Icons.info_outline, color: isDark ? Colors.white70 : Colors.black54),
            title: Text(
              '앱 버전',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              'v1.0.0',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}