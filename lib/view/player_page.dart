import 'package:music_player/get_it.dart';
import 'package:music_player/index/view_essential_index.dart';
import 'package:music_player/interface.dart';
import 'package:music_player/utils/duration_formatter.dart';
import 'package:music_player/view_model/player_view_model.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerViewModel(locator<MusicServiceInterface>()),
      child: const _PlayerPageBody(),
    );
  }
}

class _PlayerPageBody extends StatefulWidget {
  const _PlayerPageBody();

  @override
  State<_PlayerPageBody> createState() => _PlayerPageBodyState();
}

class _PlayerPageBodyState extends State<_PlayerPageBody> {
  bool _isDragging = false;
  double _dragValue = 0.0;

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
    final vm = context.watch<PlayerViewModel>();
    final currentSong = vm.currentSong;

    final error = vm.playError;
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        vm.clearError();
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text('재생 중'),
          backgroundColor: background,
          foregroundColor: colorScheme.onSurface,
        ),
        body: Center(
          child: Text('재생 중인 곡이 없습니다.', style: TextStyle(color: colorScheme.onSurface)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('재생 중'),
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
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
                      color: isDark
                          ? const Color(0xFF1C1C1C)
                          : Colors.grey[300],
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
                        color: colorScheme.onSurface,
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
                        color: colorScheme.onSurfaceVariant,
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
                stream: vm.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = vm.duration ?? Duration.zero;

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
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: isDark ? Colors.white12 : Colors.grey[300],
                          thumbColor: colorScheme.primary,
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
                            await vm.seek(
                              Duration(milliseconds: newValue.toInt()),
                            );
                            setState(() {
                              _isDragging = false;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DurationFormatter.format(position),
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              DurationFormatter.format(duration),
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: vm.cycleRepeatMode,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(
                                _repeatIcon(vm.repeatMode),
                                size: screenWidth * 0.075,
                                color: _repeatColor(
                                  context,
                                  vm.repeatMode,
                                  isDark,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: vm.playPrevious,
                            icon: Icon(
                              Icons.skip_previous,
                              size: screenWidth * 0.1,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            onPressed: vm.togglePlayPause,
                            icon: Icon(
                              vm.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: screenWidth * 0.18,
                              color: colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            onPressed: vm.playNext,
                            icon: Icon(
                              Icons.skip_next,
                              size: screenWidth * 0.1,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            onPressed: vm.toggleShuffle,
                            icon: Icon(
                              Icons.shuffle,
                              size: screenWidth * 0.075,
                              color: _shuffleColor(
                                context,
                                vm.isShuffleOn,
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
            ],
          ),
        ),
      ),
    );
  }
}