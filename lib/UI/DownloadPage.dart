import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/DB/DB_Provider.dart';
import 'package:music_player/Provider/MusicProvider.dart'; // 💡 추가

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 테마 상태를 가져옵니다.
    final isDark = context.watch<MusicProvider>().isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor, // 💡 배경색 적용
      body: Center(
          child: ElevatedButton(
              onPressed: () => DB_Provider().pickAndInsertSongs(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.purpleAccent : null,
                foregroundColor: isDark ? Colors.white : null,
              ),
              child: const Text('다운로드')
          )
      ),
    );
  }
}