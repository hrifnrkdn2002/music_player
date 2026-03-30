import 'package:flutter/material.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:provider/provider.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  String _formatDuration(Duration duration) {
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  IconData _repeatIcon(RepeatModeState mode) {
    switch (mode) {
      case RepeatModeState.one:
        return Icons.repeat_one;
      case RepeatModeState.all:
        return Icons.repeat_on;
      case RepeatModeState.off:
        return Icons.repeat;
    }
  }

  Color _repeatColor(BuildContext context, RepeatModeState mode) {
    if (mode == RepeatModeState.off) {
      return Colors.grey;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _shuffleColor(BuildContext context, bool isShuffleOn) {
    return isShuffleOn
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final song = musicProvider.currentSong;
    final player = musicProvider.player;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final albumSize = screenWidth * 0.72;
    final horizontalPadding = screenWidth * 0.06;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.keyboard_arrow_down),
                  iconSize: screenWidth * 0.08,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight * 0.82,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          width: albumSize,
                          height: albumSize,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.music_note,
                            size: albumSize * 0.35,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        Text(
                          song?.title ?? '제목없음',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          song?.artist ?? '가수없음',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.035),
                        StreamBuilder<Duration>(
                          stream: player.positionStream,
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

                                return Column(
                                  children: [
                                    Slider(
                                      value: value,
                                      min: 0.0,
                                      max: max,
                                      onChanged: (newValue) async {
                                        await musicProvider.seekTo(
                                          Duration(milliseconds: newValue.toInt()),
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_formatDuration(position)),
                                          Text(_formatDuration(duration)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: () async {
                                await musicProvider.cycleRepeatMode();
                              },
                              icon: Icon(
                                _repeatIcon(musicProvider.repeatModeState),
                                size: screenWidth * 0.075,
                                color: _repeatColor(
                                  context,
                                  musicProvider.repeatModeState,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: musicProvider.currentIndex > 0
                                  ? () async {
                                await musicProvider.playPrevious();
                              }
                                  : null,
                              icon: Icon(
                                Icons.skip_previous,
                                size: screenWidth * 0.1,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await musicProvider.togglePlayPause();
                              },
                              icon: Icon(
                                musicProvider.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                size: screenWidth * 0.16,
                              ),
                            ),
                            IconButton(
                              onPressed: (musicProvider.currentIndex >= 0 &&
                                  musicProvider.currentIndex <
                                      musicProvider.playlist.length - 1) ||
                                  musicProvider.repeatModeState ==
                                      RepeatModeState.all
                                  ? () async {
                                await musicProvider.playNext();
                              }
                                  : null,
                              icon: Icon(
                                Icons.skip_next,
                                size: screenWidth * 0.1,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                musicProvider.toggleShuffle();
                              },
                              icon: Icon(
                                Icons.shuffle,
                                size: screenWidth * 0.075,
                                color: _shuffleColor(
                                  context,
                                  musicProvider.isShuffleOn,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}