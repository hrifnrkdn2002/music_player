import 'package:flutter/material.dart';
import 'package:music_player/Provider/MusicProvider.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool _isDragging = false;
  double _dragValue = 0.0;

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

  Color _repeatColor(BuildContext context, RepeatModeState mode, bool isDark) {
    if (mode == RepeatModeState.off) {
      return isDark ? Colors.white38 : Colors.grey;
    }
    return isDark ? Colors.purpleAccent : Theme.of(context).primaryColor;
  }

  Color _shuffleColor(BuildContext context, bool isShuffle, bool isDark) {
    if (!isShuffle) {
      return isDark ? Colors.white38 : Colors.grey;
    }
    return isDark ? Colors.purpleAccent : Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;
    final player = musicProvider.player;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 💡 테마 상태 가져오기
    final isDark = musicProvider.isDarkMode;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[600];

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('재생 중'),
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
        ),
        body: Center(child: Text('재생 중인 곡이 없습니다.', style: TextStyle(color: textColor))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor, // 💡 배경색 적용
      appBar: AppBar(
        title: const Text('재생 중'),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),
              Expanded(
                child: Center(
                  child: Container(
                    width: screenWidth * 0.75,
                    height: screenWidth * 0.75,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1C) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 100,
                      color: isDark ? Colors.grey[700] : Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentSong.title,
                      style: TextStyle(
                        fontSize: (screenWidth * 0.05).clamp(14.0, 22.0),
                        fontWeight: FontWeight.bold,
                        color: textColor, // 💡 텍스트 색상
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      currentSong.artist ?? '알 수 없는 아티스트',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.035).clamp(11.0, 15.0),
                        color: subtitleColor, // 💡 서브타이틀 색상
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = player.duration ?? Duration.zero;

                  if (!_isDragging) {
                    _dragValue = position.inMilliseconds.toDouble().clamp(
                      0.0,
                      duration.inMilliseconds.toDouble(),
                    );
                  }

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: isDark ? Colors.purpleAccent : Theme.of(context).primaryColor,
                          inactiveTrackColor: isDark ? Colors.white12 : Colors.grey[300],
                          thumbColor: isDark ? Colors.purpleAccent : Theme.of(context).primaryColor,
                        ),
                        child: Slider(
                          value: _dragValue,
                          max: duration.inMilliseconds.toDouble() > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (newValue) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = newValue;
                            });
                          },
                          onChangeEnd: (newValue) async {
                            await player.seek(
                              Duration(milliseconds: newValue.toInt()),
                            );
                            setState(() {
                              _isDragging = false;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position), style: TextStyle(color: subtitleColor)),
                            Text(_formatDuration(duration), style: TextStyle(color: subtitleColor)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                musicProvider.cycleRepeatMode();
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Icon(
                                  _repeatIcon(musicProvider.repeatModeState),
                                  size: screenWidth * 0.075,
                                  color: _repeatColor(
                                    context,
                                    musicProvider.repeatModeState,
                                    isDark,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await musicProvider.playPrevious();
                              },
                              icon: Icon(
                                Icons.skip_previous,
                                size: screenWidth * 0.1,
                                color: textColor,
                              ),
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
                                musicProvider.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: screenWidth * 0.18,
                                color: isDark ? Colors.purpleAccent : Theme.of(context).primaryColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await musicProvider.playNext();
                              },
                              icon: Icon(
                                Icons.skip_next,
                                size: screenWidth * 0.1,
                                color: textColor,
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
                                  isDark,
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