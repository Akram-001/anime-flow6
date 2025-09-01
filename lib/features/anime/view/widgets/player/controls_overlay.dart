// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/features/anime/view_model/episodeDataProvider.dart';
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';

// Main Controls Widget
class CloudstreamControls extends ConsumerStatefulWidget {
  final VoidCallback? onEpisodesPressed;

  const CloudstreamControls({
    super.key,
    this.onEpisodesPressed,
  });

  @override
  ConsumerState<CloudstreamControls> createState() =>
      _CloudstreamControlsState();
}

class _CloudstreamControlsState extends ConsumerState<CloudstreamControls> {
  bool _areControlsVisible = true;
  bool _isLocked = false;
  Timer? _hideControlsTimer;
  double? _draggedSliderValue;

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_isLocked) return;
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _areControlsVisible = false);
    });
  }

  void _hideControls() {
    if (mounted && _areControlsVisible) {
      setState(() => _areControlsVisible = false);
      _hideControlsTimer?.cancel();
    }
  }

  void _toggleControlsVisibility() {
    if (mounted) {
      setState(() {
        _areControlsVisible = !_areControlsVisible;
        if (_areControlsVisible)
          _startHideControlsTimer();
        else
          _hideControlsTimer?.cancel();
      });
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _areControlsVisible = true; // Show lock icon immediately
        _hideControlsTimer?.cancel();
      } else {
        _startHideControlsTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gesture detector for seeking, scrubbing, and toggling controls
        if (!_isLocked)
          _PlayerGestureDetector(
            onGesture: _hideControls,
            onSingleTap: _toggleControlsVisibility,
            child: Container(color: Colors.transparent),
          ),

        // Animated switcher for locked vs unlocked UI
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLocked
              ? _LockMode(
                  key: const ValueKey('lock_mode'),
                  isVisible: _areControlsVisible,
                  onUnlock: _toggleLock,
                )
              : GestureDetector(
                  key: const ValueKey('controls_mode'),
                  onTap: _toggleControlsVisibility,
                  child: AnimatedOpacity(
                    opacity: _areControlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AbsorbPointer(
                      absorbing: !_areControlsVisible,
                      child: _buildFullControls(),
                    ),
                  ),
                ),
        ),

        // Subtitle overlay
        Positioned(
          bottom: _areControlsVisible ? 150 : 20,
          left: 0,
          right: 0,
          child: const _SubtitleOverlay(),
        ),
      ],
    );
  }

  Widget _buildFullControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Controls
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(0, _areControlsVisible ? 0 : -80, 0),
          child: _TopControls(
            onEpisodesPressed: widget.onEpisodesPressed,
            onSettingsPressed: _showSettingsSheet,
            onQualityPressed: _showQualitySheet,
          ),
        ),

        // Center Controls
        const _CenterControls(),

        // Bottom Controls
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(0, _areControlsVisible ? 0 : 150, 0),
          child: _BottomControls(
            sliderValue: _draggedSliderValue,
            onSliderChanged: (val) => setState(() => _draggedSliderValue = val),
            onSliderChangeStart: (val) {
              setState(() {
                _draggedSliderValue = val;
              });
              _hideControlsTimer?.cancel();
            },
            onSliderChangeEnd: (val) {
              ref
                  .read(playerStateProvider.notifier)
                  .seek(Duration(milliseconds: val.round()));
              setState(() {
                _draggedSliderValue = null;
              });
              _startHideControlsTimer();
            },
            onLockPressed: _toggleLock,
            onSourcePressed: _showSourceSheet,
            onSubtitlePressed: _showSubtitleSheet,
          ),
        ),
      ],
    );
  }

  // Helper to show modal sheets while managing the hide-controls timer
  Future<void> _showPlayerModalSheet({required WidgetBuilder builder}) async {
    _hideControlsTimer?.cancel();
    await showModalBottomSheet(context: context, builder: builder);
    if (mounted) _startHideControlsTimer();
  }

  void _showSettingsSheet() => _showPlayerModalSheet(
        builder: (context) => _SettingsSheetContent(
          onDismiss: () => Navigator.pop(context),
        ),
      );

  void _showQualitySheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => _GenericSelectionSheet<Map<String, dynamic>>(
        title: 'Quality',
        items: episodeData.qualityOptions,
        selectedIndex: episodeData.selectedQualityIdx ?? -1,
        displayBuilder: (item) => item['quality'] ?? 'Unknown',
        onItemSelected: (index) {
          episodeNotifier.changeQuality(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSourceSheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => _GenericSelectionSheet<Source>(
        title: 'Source',
        items: episodeData.sources,
        selectedIndex: episodeData.selectedSourceIdx ?? -1,
        displayBuilder: (item) => item.quality ?? 'Default Source',
        onItemSelected: (index) {
          episodeNotifier.changeSource(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSubtitleSheet() {
    final episodeData = ref.read(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);
    _showPlayerModalSheet(
      builder: (context) => _GenericSelectionSheet<Subtitle>(
        title: 'Subtitle',
        items: episodeData.subtitles,
        selectedIndex: episodeData.selectedSubtitleIdx ?? -1,
        displayBuilder: (item) => item.lang ?? 'Unknown Subtitle',
        onItemSelected: (index) {
          episodeNotifier.changeSubtitle(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// --- Reusable Generic Sheet ---
class _GenericSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final int selectedIndex;
  final String Function(T item) displayBuilder;
  final void Function(int index) onItemSelected;

  const _GenericSelectionSheet({
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.displayBuilder,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            if (items.isEmpty)
              const Center(child: Text("No options available"))
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedIndex == index;
                    return ListTile(
                      title: Text(displayBuilder(item)),
                      selected: isSelected,
                      trailing:
                          isSelected ? const Icon(Iconsax.tick_circle) : null,
                      onTap: () => onItemSelected(index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Player Control Components (Refactored) ---

class _PlayerGestureDetector extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onGesture;
  final VoidCallback onSingleTap;
  const _PlayerGestureDetector(
      {required this.child,
      required this.onGesture,
      required this.onSingleTap});

  @override
  ConsumerState<_PlayerGestureDetector> createState() =>
      _PlayerGestureDetectorState();
}

class _PlayerGestureDetectorState extends ConsumerState<_PlayerGestureDetector>
    with TickerProviderStateMixin {
  late AnimationController _seekController;
  late AnimationController _scrubController;

  bool _isSeeking = false;
  bool _isSeekForward = false;
  bool _isScrubbing = false;
  double _scrubSpeed = 2.0;
  double _originalSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _seekController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scrubController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _seekController.dispose();
    _scrubController.dispose();
    super.dispose();
  }

  void _showSeekAnimation(bool isForward) {
    widget.onGesture();
    setState(() {
      _isSeeking = true;
      _isSeekForward = isForward;
    });
    _seekController.forward(from: 0.0).whenComplete(() {
      if (mounted) setState(() => _isSeeking = false);
    });
  }

  void _toggleScrubMode() {
    final playerNotifier = ref.read(playerStateProvider.notifier);
    final isEntering = !_isScrubbing;

    widget.onGesture();
    setState(() => _isScrubbing = isEntering);

    if (isEntering) {
      _originalSpeed = ref.read(playerStateProvider).playbackSpeed;
      _scrubSpeed = 2.0;
      playerNotifier.setSpeed(_scrubSpeed);
      _scrubController.forward();
    } else {
      playerNotifier.setSpeed(_originalSpeed);
      _scrubController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerNotifier = ref.read(playerStateProvider.notifier);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isScrubbing)
          _toggleScrubMode();
        else
          widget.onSingleTap();
      },
      onDoubleTapDown: (details) {
        if (_isScrubbing) return;
        final isForward = details.localPosition.dx > size.width / 2;
        final seekDuration = Duration(seconds: isForward ? 10 : -10);
        playerNotifier
            .seek(ref.read(playerStateProvider).position + seekDuration);
        _showSeekAnimation(isForward);
      },
      onLongPress: _toggleScrubMode,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_isSeeking)
            Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0)
                    .animate(_seekController),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(99)),
                  child: Icon(
                      _isSeekForward
                          ? Iconsax.forward_10_seconds
                          : Iconsax.backward_10_seconds,
                      color: Colors.white,
                      size: 40),
                ),
              ),
            ),
          if (_isScrubbing)
            Positioned(
              top: 80,
              bottom: 80,
              right: 10,
              width: 60,
              child: FadeTransition(
                opacity: _scrubController,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${_scrubSpeed.toStringAsFixed(1)}x",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: _scrubSpeed,
                            min: 2.0,
                            max: 4.0,
                            divisions: 20,
                            onChanged: (newSpeed) {
                              setState(() => _scrubSpeed = newSpeed);
                              playerNotifier.setSpeed(newSpeed);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LockMode extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onUnlock;
  const _LockMode({super.key, required this.isVisible, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IconButton(
          style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(16)),
          onPressed: onUnlock,
          icon: const Icon(Icons.lock_open, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}

class _TopControls extends ConsumerWidget {
  final VoidCallback? onEpisodesPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onQualityPressed;

  const _TopControls({
    this.onEpisodesPressed,
    this.onSettingsPressed,
    this.onQualityPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodeData = ref.watch(episodeDataProvider);
    final source = ref.watch(selectedAnimeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final episodeTitle = !episodeData.episodesLoading &&
            episodeData.selectedEpisodeIdx != null
        ? 'Ep ${episodeData.episodes[episodeData.selectedEpisodeIdx!].number} - ${episodeData.episodes[episodeData.selectedEpisodeIdx!].title}'
        : 'Loading...';

    return Material(
      color: colorScheme.surface.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                tooltip: "Back"),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(source?.providerName.toUpperCase() ?? "SOURCE",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    episodeTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (episodeData.qualityOptions.length > 1)
              IconButton(
                  onPressed: onQualityPressed,
                  icon: const Icon(Iconsax.video_horizontal),
                  tooltip: "Quality"),
            if (onEpisodesPressed != null)
              IconButton(
                  onPressed: onEpisodesPressed,
                  icon: const Icon(Icons.playlist_play),
                  tooltip: "Episodes"),
            IconButton(
                onPressed: onSettingsPressed,
                icon: const Icon(Iconsax.setting_2),
                tooltip: "Settings"),
          ],
        ),
      ),
    );
  }
}

class _CenterControls extends ConsumerWidget {
  const _CenterControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final playerNotifier = ref.read(playerStateProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        playerState.isBuffering
            ? const SizedBox(
                width: 80, height: 80, child: CircularProgressIndicator())
            : IconButton(
                onPressed: playerNotifier.togglePlay,
                icon: Icon(
                    playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 80),
              ),
      ],
    );
  }
}

class _BottomControls extends ConsumerWidget {
  final double? sliderValue;
  final Function(double) onSliderChanged;
  final Function(double) onSliderChangeStart;
  final Function(double) onSliderChangeEnd;
  final VoidCallback onLockPressed;
  final VoidCallback onSourcePressed;
  final VoidCallback onSubtitlePressed;

  const _BottomControls({
    this.sliderValue,
    required this.onSliderChanged,
    required this.onSliderChangeStart,
    required this.onSliderChangeEnd,
    required this.onLockPressed,
    required this.onSourcePressed,
    required this.onSubtitlePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final episodeData = ref.watch(episodeDataProvider);
    final episodeNotifier = ref.read(episodeDataProvider.notifier);

    final positionMs = playerState.position.inMilliseconds.toDouble();
    final durationMs = playerState.duration.inMilliseconds.toDouble();

    final double displayedValue =
        (sliderValue ?? positionMs).clamp(0.0, durationMs);

    return Material(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(_formatDuration(
                      Duration(milliseconds: displayedValue.round())))),
              Expanded(
                child: Slider(
                  value: displayedValue,
                  max: durationMs.clamp(1.0, double.infinity),
                  onChanged: onSliderChanged,
                  onChangeStart: onSliderChangeStart,
                  onChangeEnd: onSliderChangeEnd,
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(_formatDuration(playerState.duration))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                  onPressed: onLockPressed,
                  label: const Text('Lock'),
                  icon: const Icon(Iconsax.lock)),
              if (episodeData.dubSubSupport)
                TextButton.icon(
                  onPressed: () => episodeNotifier.toggleDubSub(),
                  label: Text(episodeData.selectedCategory == 'sub'
                      ? 'Subbed'
                      : 'Dubbed'),
                  icon: const Icon(Iconsax.text_block),
                ),
              TextButton.icon(
                onPressed:
                    episodeData.sources.length > 1 ? onSourcePressed : null,
                label: const Text('Source'),
                icon: const Icon(Iconsax.hierarchy_2),
              ),
              TextButton.icon(
                onPressed:
                    episodeData.subtitles.isNotEmpty ? onSubtitlePressed : null,
                label: const Text('Subtitle'),
                icon: const Icon(Iconsax.subtitle),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _SubtitleOverlay extends ConsumerWidget {
  const _SubtitleOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleText =
        ref.watch(playerStateProvider.select((s) => s.subtitle.firstOrNull));
    return AnimatedOpacity(
      opacity: subtitleText != null && subtitleText.isNotEmpty ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subtitleText ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SettingsSheetContent extends ConsumerWidget {
  final VoidCallback onDismiss;
  const _SettingsSheetContent({required this.onDismiss});

  void _showDialog(BuildContext context,
      {required Widget Function(BuildContext) builder}) {
    showDialog(context: context, builder: builder).then((_) {
      // Pop the sheet after the dialog is closed.
      if (Navigator.of(context).canPop()) onDismiss();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Iconsax.speedometer),
              title: const Text("Playback Speed"),
              trailing: Text("${playerState.playbackSpeed}x"),
              onTap: () =>
                  _showDialog(context, builder: (ctx) => _SpeedDialog()),
            ),
            ListTile(
              leading: const Icon(Iconsax.crop),
              title: const Text("Video Fit"),
              trailing: Text(_fitModeToString(playerState.fit)),
              onTap: () => _showDialog(context, builder: (ctx) => _FitDialog()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends ConsumerState<_SpeedDialog> {
  late double _selectedSpeed;

  @override
  void initState() {
    super.initState();
    _selectedSpeed = ref.read(playerStateProvider).playbackSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Playback Speed"),
      content: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
            .map((speed) => ChoiceChip(
                  label: Text("${speed}x"),
                  selected: _selectedSpeed == speed,
                  onSelected: (isSelected) {
                    if (isSelected) setState(() => _selectedSpeed = speed);
                  },
                ))
            .toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        TextButton(
          onPressed: () {
            ref.read(playerStateProvider.notifier).setSpeed(_selectedSpeed);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

class _FitDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FitDialog> createState() => _FitDialogState();
}

class _FitDialogState extends ConsumerState<_FitDialog> {
  late BoxFit _selectedFit;
  static const fitModes = [BoxFit.contain, BoxFit.cover, BoxFit.fill];

  @override
  void initState() {
    super.initState();
    _selectedFit = ref.read(playerStateProvider).fit;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Video Fit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: fitModes
            .map((fit) => RadioListTile<BoxFit>(
                  title: Text(_fitModeToString(fit)),
                  value: fit,
                  groupValue: _selectedFit,
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedFit = value);
                  },
                ))
            .toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        TextButton(
          onPressed: () {
            ref.read(playerStateProvider.notifier).setFit(_selectedFit);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

// --- Helper Functions ---

String _formatDuration(Duration duration) {
  if (duration.isNegative) return '00:00';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String _fitModeToString(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'Contain';
    case BoxFit.cover:
      return 'Cover';
    case BoxFit.fill:
      return 'Fill';
    default:
      return 'Fit';
  }
}
