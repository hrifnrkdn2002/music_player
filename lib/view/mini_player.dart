import 'package:music_player/get_it.dart';
import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/utils/duration_formatter.dart';
import 'package:music_player/view/player_page.dart';
import 'package:music_player/view_model/mini_player_view_model.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    // 자체적으로 VM을 Provider로 감싸 어디서든 사용 가능.
    return ChangeNotifierProvider(
      create: (_) => MiniPlayerViewModel(locator<MusicServiceInterface>()),
      child: const _MiniPlayerBody(),
    );
  }
}

class _MiniPlayerBody extends StatelessWidget {
  const _MiniPlayerBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MiniPlayerViewModel>();
    final currentSong = vm.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
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
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist ?? '재생 중인 곡 없음',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: vm.playPrevious,
                    icon: Icon(Icons.skip_previous, color: colorScheme.onSurface),
                  ),
                  IconButton(
                    onPressed: vm.togglePlayPause,
                    icon: Icon(
                      vm.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: vm.playNext,
                    icon: Icon(Icons.skip_next, color: colorScheme.onSurface),
                  ),
                ],
              ),
              StreamBuilder<Duration>(
                stream: vm.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = vm.duration ?? Duration.zero;

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
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: isDark ? Colors.white12 : Colors.grey[300],
                          thumbColor: colorScheme.primary,
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
                            vm.seek(Duration(milliseconds: newValue.toInt()));
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
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              DurationFormatter.format(duration),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
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