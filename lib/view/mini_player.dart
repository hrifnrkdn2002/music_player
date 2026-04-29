import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/utils/duration_formatter.dart';
import 'package:music_player/view/player_page.dart';
import 'package:music_player/view_model/music_view_model.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicViewModel>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final player = musicProvider.player;

    final isDark = context.watch<DarkModeViewModel>().isDarkMode;
    final theme = AppTheme(isDark);

    return Material(
      color: theme.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey[300]!,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    color: isDark ? Colors.grey[800] : Colors.grey[400],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist ?? '재생 중인 곡 없음',
                          style: TextStyle(color: theme.subtitle, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await musicProvider.playPrevious();
                    },
                    icon: Icon(Icons.skip_previous, color: theme.text),
                  ),
                  IconButton(
                    onPressed: () {
                      if (musicProvider.isPlaying) {
                        player.pause();
                      } else {
                        player.play();
                      }
                    },
                    icon: Icon(
                      musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: theme.text,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await musicProvider.playNext();
                    },
                    icon: Icon(Icons.skip_next, color: theme.text),
                  ),
                ],
              ),
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = player.duration ?? Duration.zero;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 4,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                          activeTrackColor: isDark
                              ? Colors.purpleAccent
                              : Theme.of(context).primaryColor,
                          inactiveTrackColor: isDark
                              ? Colors.white12
                              : Colors.grey[300],
                          thumbColor: isDark
                              ? Colors.purpleAccent
                              : Theme.of(context).primaryColor,
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble().clamp(
                            0.0,
                            duration.inMilliseconds.toDouble(),
                          ),
                          max: duration.inMilliseconds.toDouble() > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (newValue) {
                            player.seek(
                              Duration(milliseconds: newValue.toInt()),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DurationFormatter.format(position),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.subtitle,
                              ),
                            ),
                            Text(
                              DurationFormatter.format(duration),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
