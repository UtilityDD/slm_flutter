import 'mascot_speech_library.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'ai_lineman_guide.dart';
import 'guide_director.dart';

/// Ladder guide host: waits for the ladder to settle, then a smooth
/// spring body pop, then an expressive speech bubble with live 60fps lip-sync.
class LadderGuideHost extends ConsumerStatefulWidget {
  final bool muted;

  /// Ladder pin/settle duration before the mascot may appear.
  final Duration ladderSettle;

  const LadderGuideHost({
    super.key,
    required this.muted,
    this.ladderSettle = const Duration(milliseconds: 950),
  });

  @override
  ConsumerState<LadderGuideHost> createState() => _LadderGuideHostState();
}

class _LadderGuideHostState extends ConsumerState<LadderGuideHost>
    with TickerProviderStateMixin {
  late final AnimationController _welcome;
  late final AnimationController _dockPop;
  late final AnimationController _bubble;
  var _dockVisible = false;
  var _centerVisible = false;
  var _bubbleVisible = false;
  var _started = false;
  var _entranceBusy = false;
  Timer? _pokeBubbleTimer;

  @override
  void initState() {
    super.initState();
    _welcome = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _dockPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _bubble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _waitLadderSettled(bool reduce) async {
    final wait = reduce ? const Duration(milliseconds: 280) : widget.ladderSettle;
    await Future<void>.delayed(wait);
  }

  Future<void> _playDockPop({required bool withSound}) async {
    final reduce = slmReduceMotion(context);
    setState(() {
      _dockVisible = true;
      _bubbleVisible = false;
    });
    _bubble.value = 0;
    if (withSound && !widget.muted) {
      unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.7, muted: false));
    }
    if (reduce) {
      _dockPop.value = 1;
      return;
    }
    await _dockPop.forward(from: 0);
  }

  Future<void> _revealBubbleSlowly({required bool reduce}) async {
    await Future<void>.delayed(Duration(milliseconds: reduce ? 160 : 420));
    if (!mounted) return;
    ref.read(guideDirectorProvider.notifier).revealEntranceLine();
    setState(() => _bubbleVisible = true);
    if (reduce) {
      _bubble.value = 1;
    } else {
      await _bubble.forward(from: 0);
    }
  }

  Future<void> _holdThenClear({required bool reduce}) async {
    final dir = ref.read(guideDirectorProvider.notifier);
    final line = dir.entranceLine;
    // Keep bubble at least long enough to read, then until voice finishes.
    await Future<void>.delayed(dir.entranceHoldFor(line, reduce: reduce));
    if (!mounted) return;
    await MascotSpeechLibrary.waitUntilQuiet();
    if (!mounted) return;
    await Future<void>.delayed(Duration(milliseconds: reduce ? 180 : 420));
    if (!mounted) return;
    if (!reduce) await _bubble.reverse();
    if (!mounted) return;
    setState(() => _bubbleVisible = false);
    dir.clearEntrance();
    await Future<void>.delayed(Duration(milliseconds: reduce ? 80 : 240));
    if (!mounted) return;
    if (ref.read(guideDirectorProvider).line.isNotEmpty) {
      dir.clearLine();
    }
  }

  Future<void> _boot() async {
    if (!mounted || _started) return;
    _started = true;
    _entranceBusy = true;
    final reduce = slmReduceMotion(context);

    await _waitLadderSettled(reduce);
    if (!mounted) return;

    final kind = await ref
        .read(guideDirectorProvider.notifier)
        .beginLadderEntrance(muted: widget.muted);
    if (!mounted) return;

    if (kind == GuideEntranceKind.dailyWelcome) {
      setState(() {
        _centerVisible = true;
        _dockVisible = false;
        _bubbleVisible = false;
      });
      if (reduce) {
        _welcome.value = 1;
      } else {
        await _welcome.forward(from: 0);
      }
      if (!widget.muted) {
        unawaited(
          ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.5, muted: false),
        );
      }
      await _revealBubbleSlowly(reduce: reduce);
      if (!mounted) return;
      await _holdThenClear(reduce: reduce);
      if (!mounted) return;
      if (!reduce) await _welcome.reverse();
      if (!mounted) return;
      setState(() => _centerVisible = false);
      await Future<void>.delayed(Duration(milliseconds: reduce ? 120 : 320));
      if (!mounted) return;
      await _playDockPop(withSound: true);
      _entranceBusy = false;
      return;
    }

    await _playDockPop(withSound: true);
    if (!mounted) return;
    await _revealBubbleSlowly(reduce: reduce);
    if (!mounted) return;
    await _holdThenClear(reduce: reduce);
    _entranceBusy = false;
  }

  void _presentDockBubble(String line) {
    if (!_dockVisible || _centerVisible || _entranceBusy) return;
    if (line.trim().isEmpty) return;
    _pokeBubbleTimer?.cancel();
    setState(() => _bubbleVisible = true);
    final reduce = slmReduceMotion(context);
    if (reduce) {
      _bubble.value = 1;
    } else {
      unawaited(_bubble.forward(from: 0));
    }
    final minHold = ref
        .read(guideDirectorProvider.notifier)
        .entranceHoldFor(line, reduce: reduce);
    _pokeBubbleTimer = Timer(minHold, () async {
      // Do not cut the voice — wait for speech to finish, then clear the bubble.
      await MascotSpeechLibrary.waitUntilQuiet();
      if (!mounted) return;
      await Future<void>.delayed(Duration(milliseconds: reduce ? 160 : 380));
      if (!mounted) return;
      if (!reduce) await _bubble.reverse();
      if (!mounted) return;
      setState(() => _bubbleVisible = false);
      final g = ref.read(guideDirectorProvider);
      if (g.entrance == null && g.line.isNotEmpty) {
        ref.read(guideDirectorProvider.notifier).clearLine();
      }
    });
  }

  void _onPoke() {
    if (!_dockVisible || _centerVisible || _entranceBusy) return;
    if (_dockPop.value < 0.85) return;
    HapticFeedback.selectionClick();
    if (!widget.muted) {
      unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.55, muted: false));
    }
    ref.read(guideDirectorProvider.notifier).onPoke(muted: widget.muted);
    _presentDockBubble(ref.read(guideDirectorProvider).line);
  }

  @override
  void dispose() {
    _pokeBubbleTimer?.cancel();
    _welcome.dispose();
    _dockPop.dispose();
    _bubble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GuideState>(guideDirectorProvider, (prev, next) {
      // Learn/Do owns the coach — do not steal bubbles under the level route.
      if (ref.read(guideDirectorProvider.notifier).levelFocus) return;
      if (_entranceBusy || _centerVisible || !_dockVisible) return;
      if (next.entrance != null) return;
      if (next.line.isEmpty) return;
      if (prev != null && prev.token == next.token) return;
      _presentDockBubble(next.line);
    });
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        if (_dockVisible)
          Positioned(
            right: 8,
            bottom: pad.bottom + 8,
            // Own layer: the guide's per-frame motion never repaints the ladder.
            child: RepaintBoundary(
              child: AnimatedBuilder(
              animation: Listenable.merge([_dockPop, _bubble]),
              builder: (_, _) {
                final raw = _dockPop.value.clamp(0.0, 1.0);
                final spring = Curves.easeOutBack.transform(raw);
                final bubbleT = Curves.easeOutBack
                    .transform(_bubble.value.clamp(0.0, 1.0))
                    .clamp(0.0, 1.0);
                return Opacity(
                  opacity: raw,
                  child: Transform.translate(
                    offset: Offset(0, (1 - spring) * 56),
                    child: Transform.scale(
                      scale: (0.68 + 0.32 * spring).clamp(0.5, 1.12),
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
                        child: AiLinemanGuide(
                          sprite: 122,
                          bubbleWidth: 228,
                          centered: false,
                          showBubble: _bubbleVisible,
                          bubbleOpacity: _bubbleVisible ? bubbleT : 0,
                          onTap: _onPoke,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            ),
          ),
        if (_centerVisible)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_welcome, _bubble]),
                builder: (_, _) {
                  final raw = _welcome.value.clamp(0.0, 1.0);
                  final t = Curves.easeOutBack.transform(raw);
                  final bubbleT = Curves.easeOutCubic
                      .transform(_bubble.value.clamp(0.0, 1.0));
                  return Opacity(
                    opacity: raw,
                    child: Transform.scale(
                      scale: (0.86 + 0.14 * t).clamp(0.7, 1.1),
                      // He stands on the scene itself: no card or dark box
                      // behind him (owner, 2026-11-14).
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                          child: AiLinemanGuide(
                            sprite: 176,
                            bubbleWidth: 300,
                            large: true,
                            centered: true,
                            showBubble: _bubbleVisible,
                            bubbleOpacity: _bubbleVisible ? bubbleT : 0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
          ),
      ],
    );
  }
}
