import 'package:flutter/material.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:music_player/UI/PlayerPage.dart';
import 'package:provider/provider.dart';

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

    return Material(
      color: Colors.grey[200],
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
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentSong.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              StreamBuilder<Duration>(
                stream: player.createPositionStream(
                  minPeriod: const Duration(milliseconds: 16),
                  maxPeriod: const Duration(milliseconds: 100),
                ),
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;

                  return StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;

                      final max = duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0;

                      final value = position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, max);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: musicProvider.canPlayPrevious
                                ? () async {
                              await musicProvider.playPrevious();
                            }
                                : null,
                            icon: const Icon(Icons.skip_previous),
                          ),
                          IconButton(
                            onPressed: () async {
                              await musicProvider.togglePlayPause();
                            },
                            icon: Icon(
                              musicProvider.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 36,
                            ),
                          ),
                          IconButton(
                            onPressed:  musicProvider.canPlayNext
                                ? () async {
                              await musicProvider.playNext();
                            }
                                : null,
                            icon: const Icon(Icons.skip_next),
                          ),

                          /// 슬라이더 + 시간 표시를 하나의 세로 묶음으로
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Slider(
                                  min: 0.0,
                                  max: max,
                                  value: value,
                                  onChanged: (newValue) async {
                                    await musicProvider.seekTo(
                                      Duration(
                                        milliseconds: newValue.toInt(),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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