import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';

// The brand intro on every cold start: the native launch screen (navy + logo,
// tool/brand_assets.py) hands over to the same navy and logo here, the intro
// video (assets/brand/intro.mp4: 5.7 s, 464x832, H.264 30 fps + AAC, 330 KB)
// fades in over it and plays once, then the whole layer fades into the app.
// The app (Home) builds underneath meanwhile, so nothing waits on the video.
// Skippable after a moment; skipped with reduced motion; never blocks the app
// if the video cannot load (gives up after [IntroGate.loadTimeout]).
// Meanwhile [IntroGate.warmUp] loads what the first taps would wait for
// (lib/core/startup/startup_warmup.dart); it runs on if the intro is skipped.

/// The brand navy (the logo's own background, as the native launch screen).
const introNavy = Color(0xFF0E162B);

/// Opens a video controller for the intro; null if it cannot play.
typedef IntroVideoLoader = Future<VideoPlayerController?> Function();

Future<VideoPlayerController?> _loadIntro() async {
  final c = VideoPlayerController.asset(IntroGate.videoAsset, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
  try {
    await c.initialize();
    return c;
  } catch (_) {
    await c.dispose();
    return null;
  }
}

/// Puts the intro over [child] (the app) until it is done.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key, required this.child, this.loader = _loadIntro, this.enabled = true, this.warmUp});

  final Widget child;
  final IntroVideoLoader loader;

  /// Background loading started with the intro (given this gate's context,
  /// which lives as long as the app).
  final Future<void> Function(BuildContext context)? warmUp;

  /// False: the app straight away (tests of the app shell).
  final bool enabled;

  static const videoAsset = 'assets/brand/intro.mp4';
  static const logoAsset = 'assets/brand/splash_logo.png';
  static const loadTimeout = Duration(milliseconds: 2500);
  static const skipAfter = Duration(milliseconds: 1200);
  static const skipBn = 'এড়িয়ে যান';

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  late bool _showing = widget.enabled;

  @override
  void initState() {
    super.initState();
    final warm = widget.warmUp;
    if (widget.enabled && warm != null) {
      // After the first frame, so the native splash hands over first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(warm(context));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showing)
          IntroOverlay(
            key: const ValueKey('intro'),
            loader: widget.loader,
            onDone: () {
              if (mounted) setState(() => _showing = false);
            },
          ),
      ],
    );
  }
}

/// The intro layer itself: logo → video → fade out → [onDone].
class IntroOverlay extends StatefulWidget {
  const IntroOverlay({super.key, required this.loader, required this.onDone});
  final IntroVideoLoader loader;
  final VoidCallback onDone;

  @override
  State<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<IntroOverlay> {
  VideoPlayerController? _video;
  var _playing = false;
  var _leaving = false;
  var _canSkip = false;
  var _done = false;
  Timer? _timeout;
  Timer? _skipTimer;
  Timer? _safety;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  Future<void> _start() async {
    if (!mounted) return;
    // Reduced motion: no video, a short fade into the app.
    if (MediaQuery.disableAnimationsOf(context)) {
      _leave();
      return;
    }
    _timeout = Timer(IntroGate.loadTimeout, _leave);
    final c = await widget.loader();
    _timeout?.cancel();
    if (!mounted || _leaving) {
      await c?.dispose();
      return;
    }
    if (c == null) {
      _leave();
      return;
    }
    _video = c;
    c.addListener(_onTick);
    await c.setVolume(0.8);
    await c.play();
    if (!mounted) return;
    setState(() => _playing = true);
    _skipTimer = Timer(IntroGate.skipAfter, () {
      if (mounted) setState(() => _canSkip = true);
    });
    // Whatever happens, the app comes after the video's length (+ a margin).
    _safety = Timer(c.value.duration + const Duration(seconds: 2), _leave);
  }

  void _onTick() {
    final v = _video?.value;
    if (v == null || !v.isInitialized) return;
    if (v.hasError || (v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 60))) _leave();
  }

  /// Fade out (the video holds its last frame meanwhile), then done.
  void _leave() {
    if (_leaving || !mounted) return;
    _timeout?.cancel();
    _skipTimer?.cancel();
    _safety?.cancel();
    setState(() => _leaving = true);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _skipTimer?.cancel();
    _safety?.cancel();
    final c = _video;
    if (c != null) {
      c.removeListener(_onTick);
      unawaited(c.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _video;
    final quiet = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: introNavy),
      child: AnimatedOpacity(
        opacity: _leaving ? 0 : 1,
        duration: Duration(milliseconds: quiet ? 150 : 450),
        curve: Curves.easeOut,
        onEnd: () {
          if (_leaving) _finish();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // The layer swallows taps meanwhile (the app under it waits).
          onTap: () {},
          child: ColoredBox(
            color: introNavy,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The same logo as the native launch screen, until the video plays.
                Center(
                  child: Image.asset(IntroGate.logoAsset, width: 144, height: 144, filterQuality: FilterQuality.medium),
                ),
                if (c != null)
                  AnimatedOpacity(
                    key: const ValueKey('intro-video'),
                    opacity: _playing ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
                    ),
                  ),
                if (_canSkip && !_leaving)
                  Positioned(
                    key: const ValueKey('intro-skip'),
                    top: MediaQuery.paddingOf(context).top + 12,
                    right: 12,
                    child: _SkipChip(onTap: _leave),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipChip extends StatelessWidget {
  const _SkipChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: IntroGate.skipBn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(IntroGate.skipBn, style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
