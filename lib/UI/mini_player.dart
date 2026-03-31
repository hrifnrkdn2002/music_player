import 'package:flutter/material.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:music_player/UI/PlayerPage.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _formatDuration(Duration duration) {
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final player = musicProvider.player;

    // 💡 테마 상태 가져오기
    final isDark = musicProvider.isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF1C1C1C) : Colors.grey[200];
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[600];

    return Material(
      color: backgroundColor, // 💡 배경색 동적 변경
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PlayerPage(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
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
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist ?? '재생 중인 곡 없음',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
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
                    icon: Icon(Icons.skip_previous, color: textColor),
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
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await musicProvider.playNext();
                    },
                    icon: Icon(Icons.skip_next, color: textColor),
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
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: isDark ? Colors.purpleAccent : Theme.of(context).primaryColor,
                          inactiveTrackColor: isDark ? Colors.white12 : Colors.grey[300],
                          thumbColor: isDark ? Colors.purpleAccent : Theme.of(context).primaryColor,
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
                              _formatDuration(position),
                              style: TextStyle(fontSize: 12, color: subtitleColor),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(fontSize: 12, color: subtitleColor),
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