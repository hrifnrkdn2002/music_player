import 'package:music_player/index/view_essential_index.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final darkModeViewModel = context.watch<DarkModeViewModel>();
    final isDark = darkModeViewModel.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          '설정',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.purpleAccent : Colors.orange,
            ),
            title: Text(
              '다크 모드',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              isDark ? '어두운 테마 사용 중' : '밝은 테마 사용 중',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => darkModeViewModel.toggleTheme(),
              activeColor: Colors.purpleAccent,
            ),
          ),
          Divider(color: isDark ? Colors.white10 : Colors.grey[300]),
          ListTile(
            leading: Icon(
              Icons.info_outline,


              color: colorScheme.onSurfaceVariant,
            ),
            title: Text(
              '앱 버전',
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              'v1.0.0',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
