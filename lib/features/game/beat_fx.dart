import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../shell/shell_providers.dart';
import 'game_save.dart';

/// Shared beat FX bus — score chips, death moment, later hints.
class BeatFx {
  BeatFx._();

  static Future<void> scoreDelta(
    WidgetRef ref,
    int delta, {
    String? rungId,
    GuideMood? mood,
  }) async {
    await ref.read(gameSaveProvider.notifier).addPoints(delta, rungId: rungId);
    if (mood != null) {
      ref.read(guideDirectorProvider.notifier).react(mood);
    } else if (delta > 0) {
      ref.read(guideDirectorProvider.notifier).react(GuideMood.glad);
    } else if (delta < 0) {
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
    }
  }

  /// Tip / gift / Coming Soon beat — guide reacts; visual lives on the ladder.
  static void hintAppear(WidgetRef ref, {GuideMood mood = GuideMood.inspire}) {
    ref.read(guideDirectorProvider.notifier).react(mood);
  }
}

/// Overlay that flies the latest GameSave pulse toward the top score chip.
class ScoreFlyHost extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey scoreKey;

  const ScoreFlyHost({super.key, required this.child, required this.scoreKey});

  @override
  ConsumerState<ScoreFlyHost> createState() => _ScoreFlyHostState();
}

class _ScoreFlyHostState extends ConsumerState<ScoreFlyHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  int? _seenAt;
  int _delta = 0;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  var _flying = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _flying = false);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _hostLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  void _tryLaunch(ScorePulse? pulse) {
    if (pulse == null || pulse.atMs == _seenAt || pulse.delta == 0) return;
    _seenAt = pulse.atMs;
    final size = MediaQuery.sizeOf(context);
    final originGlobal = Offset(size.width * 0.5, size.height * 0.52);
    final scoreBox = widget.scoreKey.currentContext?.findRenderObject() as RenderBox?;
    final targetGlobal = scoreBox != null && scoreBox.hasSize
        ? scoreBox.localToGlobal(Offset(scoreBox.size.width / 2, scoreBox.size.height / 2))
        : Offset(size.width - 72, MediaQuery.paddingOf(context).top + 36);
    setState(() {
      _delta = pulse.delta;
      _from = _hostLocal(originGlobal);
      _to = _hostLocal(targetGlobal);
      _flying = true;
    });
    if (slmReduceMotion(context)) {
      _c.value = 1;
      setState(() => _flying = false);
      return;
    }
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final saveCtrl = ref.read(gameSaveProvider.notifier);
    ref.listen(gameSaveProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tryLaunch(saveCtrl.lastPulse);
      });
    });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_flying)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = Curves.easeOutCubic.transform(_c.value.clamp(0.0, 1.0));
                final pos = Offset.lerp(_from, _to, t)!;
                final opacity = (1.0 - t * 0.2).clamp(0.0, 1.0);
                final label = _delta > 0 ? '+${enDigits('$_delta')}' : enDigits('$_delta');
                final color = _delta > 0 ? SlmColors.emerald300 : SoftDanger.ink;
                return Positioned(
                  left: pos.dx - 30,
                  top: pos.dy - 16,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: 1.12 - 0.22 * t,
                      child: Text(
                        label,
                        style: bangla(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                        ).copyWith(
                          shadows: [
                            Shadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 10),
                            Shadow(color: color.withValues(alpha: 0.45), blurRadius: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Soft red that stays readable on navy without looking gory.
class SoftDanger {
  static const ink = Color(0xFFFF6B6B);
}

/// Full-screen death beat: freeze → crack → 💀 fly → kinetic cause → settle.
class DeathMomentHost extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey deathKey;
  final VoidCallback? onSettled;

  const DeathMomentHost({
    super.key,
    required this.child,
    required this.deathKey,
    this.onSettled,
  });

  @override
  ConsumerState<DeathMomentHost> createState() => _DeathMomentHostState();
}

class _DeathMomentHostState extends ConsumerState<DeathMomentHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  int? _seenAt;
  DeathPulse? _pulse;
  Offset _skullFrom = Offset.zero;
  Offset _skullTo = Offset.zero;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        final pulse = _pulse;
        setState(() => _pulse = null);
        widget.onSettled?.call();
        if (pulse != null) {
          ref.read(guideDirectorProvider.notifier).react(GuideMood.fallen);
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pulse = ref.read(gameSaveProvider.notifier).lastDeathPulse;
      if (pulse != null && DateTime.now().millisecondsSinceEpoch - pulse.atMs < 10000) {
        _tryLaunch(pulse);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _hostLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  void _tryLaunch(DeathPulse? pulse) {
    if (pulse == null || pulse.atMs == _seenAt) return;
    _seenAt = pulse.atMs;
    final size = MediaQuery.sizeOf(context);
    final originGlobal = Offset(size.width * 0.5, size.height * 0.42);
    final deathBox = widget.deathKey.currentContext?.findRenderObject() as RenderBox?;
    final targetGlobal = deathBox != null && deathBox.hasSize
        ? deathBox.localToGlobal(Offset(deathBox.size.width / 2, deathBox.size.height / 2))
        : Offset(size.width - 36, MediaQuery.paddingOf(context).top + 36);
    HapticFeedback.heavyImpact();
    setState(() {
      _pulse = pulse;
      _skullFrom = _hostLocal(originGlobal);
      _skullTo = _hostLocal(targetGlobal);
    });
    if (slmReduceMotion(context)) {
      _c.value = 1;
      return;
    }
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final saveCtrl = ref.read(gameSaveProvider.notifier);
    final bn = ref.watch(languageProvider);
    ref.listen(gameSaveProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tryLaunch(saveCtrl.lastDeathPulse);
      });
    });

    final pulse = _pulse;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (pulse != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = _c.value.clamp(0.0, 1.0);
                final freeze = (t / 0.12).clamp(0.0, 1.0);
                final crack = ((t - 0.08) / 0.18).clamp(0.0, 1.0);
                final flyT = Curves.easeInCubic.transform(((t - 0.22) / 0.38).clamp(0.0, 1.0));
                final textT = ((t - 0.35) / 0.35).clamp(0.0, 1.0);
                final fadeOut = t > 0.82 ? (1 - (t - 0.82) / 0.18).clamp(0.0, 1.0) : 1.0;
                final skullPos = Offset.lerp(_skullFrom, _skullTo, flyT)!;
                final deathN = enDigits('${pulse.deathCount}');
                final line = tr(
                  bn,
                  'বাস্তবে এটা আপনার $deathN নম্বর মৃত্যু',
                  'In real work this would be death #$deathN',
                );

                return Opacity(
                  opacity: fadeOut,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: Colors.black.withValues(alpha: 0.55 * freeze)),
                      CustomPaint(
                        painter: _CrackPainter(progress: crack),
                        size: Size.infinite,
                      ),
                      if (flyT < 1)
                        Positioned(
                          left: skullPos.dx - 22,
                          top: skullPos.dy - 22,
                          child: Opacity(
                            opacity: (1 - flyT * 0.25).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 1.6 - 0.7 * flyT,
                              child: Text(
                                '💀',
                                style: TextStyle(
                                  fontSize: 40,
                                  shadows: [Shadow(color: SoftDanger.ink.withValues(alpha: 0.7), blurRadius: 16)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (textT > 0)
                        Align(
                          alignment: const Alignment(0, 0.18),
                          child: Opacity(
                            opacity: Curves.easeOut.transform(textT),
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - textT)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      line,
                                      textAlign: TextAlign.center,
                                      style: bangla(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: SlmColors.ivory,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (pulse.cause.trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        pulse.cause,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        style: bangla(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: SoftDanger.ink,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CrackPainter extends CustomPainter {
  final double progress;

  _CrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = SoftDanger.ink.withValues(alpha: 0.55 * progress)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cx = size.width * 0.5;
    final cy = size.height * 0.4;
    final reach = progress;
    final paths = <List<Offset>>[
      [Offset(cx, cy), Offset(cx - 48 * reach, cy - 70 * reach), Offset(cx - 90 * reach, cy - 40 * reach)],
      [Offset(cx, cy), Offset(cx + 36 * reach, cy - 88 * reach), Offset(cx + 80 * reach, cy - 52 * reach)],
      [Offset(cx, cy), Offset(cx - 20 * reach, cy + 96 * reach), Offset(cx - 70 * reach, cy + 130 * reach)],
      [Offset(cx, cy), Offset(cx + 55 * reach, cy + 70 * reach), Offset(cx + 110 * reach, cy + 50 * reach)],
    ];
    for (final pts in paths) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrackPainter oldDelegate) => oldDelegate.progress != progress;
}
