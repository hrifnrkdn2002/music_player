import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/Provider/MusicProvider.dart'; // 💡 추가

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 테마 상태 가져오기
    final isDark = context.watch<MusicProvider>().isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
          child: Text(
              "플레이리스트",
              style: TextStyle(color: textColor, fontSize: 18)
          )
      ),
    );
  }
}