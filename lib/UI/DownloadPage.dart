import 'package:flutter/material.dart';
import 'package:music_player/Provider/ThemeProvider.dart';
import 'package:music_player/Utils/AppTheme.dart';
import 'package:provider/provider.dart';
import 'package:music_player/DB/DB_Provider.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final theme = AppTheme(isDark);

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
          child: ElevatedButton(
              onPressed: () => context.read<DB_Provider>().pickAndInsertSongs(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? theme.accent : null,
                foregroundColor: isDark ? Colors.white : null,
              ),
              child: const Text('다운로드')
          )
      ),
    );
  }
}