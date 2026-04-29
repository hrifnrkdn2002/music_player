import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/view_model/database_view_model.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeViewModel>().isDarkMode;
    final theme = AppTheme(isDark);

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              context.read<DatabaseViewModel>().pickAndInsertSongs(),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? theme.accent : null,
            foregroundColor: isDark ? Colors.white : null,
          ),
          child: const Text('다운로드'),
        ),
      ),
    );
  }
}
