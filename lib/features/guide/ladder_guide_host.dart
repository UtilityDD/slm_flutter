import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'ai_lineman_guide.dart';
import 'guide_director.dart';

/// Ladder-only guide host: waits for the ladder to settle, then a slow
/// body pop, then an unhurried speech bubble.
class LadderGuideHost extends ConsumerStatefulWidget {
  final bool muted;

  /// Ladder pin/settle duration before the mascot may appear.
  final Duration ladderSettle;

  const LadderGuideHost({
    super.key,
    required this.muted,
    this.ladderSettle = const Duration(milliseconds: 1400),
  });

  @override
  ConsumerState<LadderGuideHost> createState() => _LadderGuideHostState();
}

class _LadderGuideHostState extends ConsumerState<LadderGuideHost> with TickerProviderStateMixin {
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
    _welcome = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _dockPop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _bubble = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _waitLadderSettled(bool reduce) async {
    // Pin animation is ~850ms; add a beat of stillness after.
    final wait = reduce ? const Duration(milliseconds: 400) : widget.ladderSettle;
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
    // Let the body land before speaking.
    await Future<void>.delayed(Duration(milliseconds: reduce ? 250 : 750));
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
    await Future<void>.delayed(dir.entranceHoldFor(line, reduce: reduce));
    if (!mounted) return;
    if (!reduce) await _bubble.reverse();
    if (!mounted) return;
    setState(() => _bubbleVisible = false);
    dir.clearEntrance();
    // Softly clear the spoken line after the bubble is gone.
    await Future<void>.delayed(Duration(milliseconds: reduce ? 100 : 350));
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

    // 1) Ladder page settles first — mascot stays hidden.
    await _waitLadderSettled(reduce);
    if (!mounted) return;

    final kind = await ref.read(guideDirectorProvider.notifier).beginLadderEntrance(muted: widget.muted);
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
        unawaited(ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.5, muted: false));
      }
      // Body visible, then speech.
      await _revealBubbleSlowly(reduce: reduce);
      if (!mounted) return;
      await _holdThenClear(reduce: reduce);
      if (!mounted) return;
      if (!reduce) await _welcome.reverse();
      if (!mounted) return;
      setState(() => _centerVisible = false);
      await Future<void>.delayed(Duration(milliseconds: reduce ? 150 : 450));
      if (!mounted) return;
      await _playDockPop(withSound: true);
      _entranceBusy = false;
      return;
    }

    // Same-day hi: body pops, pause, then bubble, hold, clear.
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
    final hold = ref.read(guideDirectorProvider.notifier).entranceHoldFor(line, reduce: reduce);
    _pokeBubbleTimer = Timer(hold, () async {
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
    if (_dockPop.value < 0.95) return;
    HapticFeedback.selectionClick();
    if (!widget.muted) {
      unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.55, muted: false));
    }
    ref.read(guideDirectorProvider.notifier).onPoke();
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
    // Idle nudge / inspire lines must show the bubble (not only poke/entrance).
    ref.listen<GuideState>(guideDirectorProvider, (prev, next) {
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
            right: 0,
            bottom: pad.bottom,
            child: AnimatedBuilder(
              animation: Listenable.merge([_dockPop, _bubble]),
              builder: (_, _) {
                final t = Curves.easeOutCubic.transform(_dockPop.value.clamp(0.0, 1.0));
                // Soft overshoot only on the last third — less “toy bounce”, more present.
                final pop = t < 0.75 ? (t / 0.75) : (1 + 0.06 * (1 - ((t - 0.75) / 0.25)));
                final bubbleT = Curves.easeOutCubic.transform(_bubble.value.clamp(0.0, 1.0));
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 64),
                    child: Transform.scale(
                      scale: 0.62 + 0.38 * pop.clamp(0.0, 1.08),
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _onPoke,
                            child: AiLinemanGuide(
                              sprite: 72,
                              bubbleWidth: 128,
                              showBubble: _bubbleVisible,
                              bubbleOpacity: _bubbleVisible ? bubbleT : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_centerVisible)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: Listenable.merge([_welcome, _bubble]),
                builder: (_, _) {
                  final t = Curves.easeOutCubic.transform(_welcome.value.clamp(0.0, 1.0));
                  final bubbleT = Curves.easeOutCubic.transform(_bubble.value.clamp(0.0, 1.0));
                  return Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.88 + 0.12 * t,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: SlmColors.navy950.withValues(alpha: 0.32 * t),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                            child: AiLinemanGuide(
                              sprite: 132,
                              bubbleWidth: 260,
                              large: true,
                              showBubble: _bubbleVisible,
                              bubbleOpacity: _bubbleVisible ? bubbleT : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
