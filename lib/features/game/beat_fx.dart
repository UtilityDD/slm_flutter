import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../shell/shell_providers.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'game_save.dart';
import 'lesson_promises.dart';

/// Shared beat FX bus — score chips, sound cues, death moment, and unified HUD.
class BeatFx {
  BeatFx._();

  /// Points inside a level: the chip flies into the level score and the
  /// player hears and feels it, but the main ◆ only changes when the level
  /// ends ([GameSaveController.commitLevelScore]).
  static Future<void> levelDelta(
    WidgetRef ref,
    int delta, {
    GuideMood? mood,
    Offset? originGlobal,
    bool playSound = true,
    bool muted = false,
  }) async {
    if (delta == 0) return;
    if (delta > 0) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    if (playSound && !muted) {
      if (delta >= 20) {
        unawaited(ZlFx.cue('sounds/quiz_complete.ogg', volume: 0.75, muted: false));
      } else if (delta > 0) {
        unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.72, muted: false));
      } else {
        unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.72, muted: false));
      }
    }
    ref.read(gameSaveProvider.notifier).pulseDelta(delta, originGlobal: originGlobal);
    if (mood != null) {
      ref.read(guideDirectorProvider.notifier).react(mood);
    }
  }

  static Future<void> scoreDelta(
    WidgetRef ref,
    int delta, {
    String? rungId,
    GuideMood? mood,
    Offset? originGlobal,
    bool playSound = true,
    bool muted = false,
  }) async {
    if (delta == 0) return;
    if (delta > 0) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    if (playSound && !muted) {
      if (delta >= 20) {
        unawaited(ZlFx.cue('sounds/quiz_complete.ogg', volume: 0.75, muted: false));
      } else if (delta > 0) {
        unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.72, muted: false));
      } else {
        unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.72, muted: false));
      }
    }
    await ref.read(gameSaveProvider.notifier).addPoints(
          delta,
          rungId: rungId,
          originGlobal: originGlobal,
        );
    if (mood != null) {
      ref.read(guideDirectorProvider.notifier).react(mood);
    } else if (delta >= 20) {
      ref.read(guideDirectorProvider.notifier).react(GuideMood.celebrate);
    } else if (delta > 0) {
      ref.read(guideDirectorProvider.notifier).react(GuideMood.glad);
    } else if (delta < 0) {
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
    }
  }
}

/// Unified top HUD bar shared by LearnRunnerPage and Do Rungs (DutySlipPage)
/// so the player always sees the exact same live ◆ Score and 💀 Death counters.
/// The main ◆ total, small, beside a level score. When the level ends and
/// its score lands in the total, the number counts to the new value once
/// (one-shot tween, nothing runs while idle).
class ScoreTotalTicker extends StatelessWidget {
  const ScoreTotalTicker({super.key, required this.total, this.scale = 1.0});

  final int total;

  /// Shrinks with the top bar on narrow phones.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: total.toDouble()),
      duration: quiet ? Duration.zero : const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('মোট', style: bangla(fontSize: 9.5 * scale, fontWeight: FontWeight.w700, color: SlmColors.mist, height: 1)),
          Text(
            enDigits('◆ ${v.round()}'),
            style: bangla(fontSize: 11.5 * scale, fontWeight: FontWeight.w800, color: SlmColors.gold200, height: 1.15),
          ),
        ],
      ),
    );
  }
}

/// `L<n>`: the one place a level's number shows (lesson numbers are internal).
/// Short so the top bar fits a 320 dp phone; screen readers hear "ধাপ N" and
/// the level's [title] (never drawn). [scale] shrinks it with the bar.
class LadderStepBadge extends StatelessWidget {
  const LadderStepBadge({super.key, required this.step, this.title = '', this.scale = 1.0});
  final int step;
  final String title;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final f = scale;
    return Semantics(
      label: enDigits(title.trim().isEmpty ? 'ধাপ $step' : 'ধাপ $step · ${title.trim()}'),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * f, vertical: 4 * f),
        decoration: BoxDecoration(
          color: SlmColors.gold400.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5)),
        ),
        child: Text(
          enDigits('L$step'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: bangla(fontSize: 16 * f, fontWeight: FontWeight.w900, color: SlmColors.gold200, height: 1.1),
        ),
      ),
    );
  }
}

/// The 💀 count, the same chip on every level. [scale] shrinks it with the
/// top bar on narrow phones (see [UnifiedGameTopHud.scaleFor]).
class DeathCountChip extends StatelessWidget {
  const DeathCountChip({super.key, required this.deaths, this.chipKey, this.scale = 1.0});
  final int deaths;
  final Key? chipKey;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      key: chipKey,
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1524),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: deaths > 0 ? SoftDanger.ink.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💀', style: TextStyle(fontSize: 11.5 * s)),
          SizedBox(width: 4 * s),
          Text(
            enDigits('$deaths'),
            maxLines: 1,
            softWrap: false,
            style: bangla(
              fontSize: 13 * s,
              fontWeight: FontWeight.w800,
              color: deaths > 0 ? SoftDanger.ink : SlmColors.mist,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one top bar of every level (owner's brief, Nov 2026): close · "L12"
/// (the ladder step only — the level's name is read to screen readers, never
/// drawn) · ◆ score (chips fly into [scoreKey]) · 💀 · [trailingExtra].
///
/// One row of fixed height ([height]) on every phone: icons, fonts, padding
/// and gaps scale with the bar's width ([scaleFor]); touch targets stay
/// ≥ 40 dp; the level badge is the only part that gives way.
class UnifiedGameTopHud extends ConsumerStatefulWidget {
  final GlobalKey scoreKey;
  final GlobalKey? deathKey;

  /// The level badge, e.g. "L12" (`'L${ctx.ladderStep}'`).
  final String badgeText;

  /// The level's name: Semantics only, never drawn in the bar.
  final String titleText;
  final VoidCallback onClose;
  final IconData closeIcon;

  /// The speaker/mute button was removed from the bar (owner's brief, Nov
  /// 2026). [muted] and [onToggleMute] stay so callers compile, but the bar
  /// draws nothing for them; muting elsewhere is unchanged.
  final bool muted;

  /// Not drawn — see [muted].
  final VoidCallback? onToggleMute;
  final Widget? trailingExtra;

  /// This level's running score. When set, the pill shows it (chips fly into
  /// it) and the main ◆ total sits small beside it (unless [stepOnly]).
  final int? levelScore;

  /// The clean level header: only the badge, the score pill and the 💀 count
  /// — no running total.
  final bool stepOnly;

  /// No bar behind the chips: they float on a full-screen scene (as level 1).
  final bool bare;

  /// Bar height on every phone (scenes place captions under it).
  static const double height = 54;

  /// Size factor for a bar [width] dp wide: 1.0 from 400 dp up, down to 0.82
  /// on the narrowest phones.
  static double scaleFor(double width) => (width / 400).clamp(0.82, 1.0).toDouble();

  const UnifiedGameTopHud({
    super.key,
    required this.scoreKey,
    this.deathKey,
    required this.badgeText,
    required this.titleText,
    required this.onClose,
    this.closeIcon = Icons.arrow_back_rounded,
    this.muted = false,
    this.onToggleMute,
    this.trailingExtra,
    this.levelScore,
    this.stepOnly = false,
    this.bare = false,
  });

  @override
  ConsumerState<UnifiedGameTopHud> createState() => _UnifiedGameTopHudState();
}

class _UnifiedGameTopHudState extends ConsumerState<UnifiedGameTopHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump;
  int? _lastPoints;

  @override
  void initState() {
    super.initState();
    _bump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameSaveProvider);
    final shown = widget.levelScore ?? save.points;
    if (_lastPoints != null && _lastPoints != shown) {
      _bump.forward(from: 0);
    }
    _lastPoints = shown;

    // A fixed-height HUD: system text scaling past 1.0 would push it over
    // the edge on a 320 dp phone, so the bar keeps its own sizes.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : MediaQuery.sizeOf(context).width;
          final s = UnifiedGameTopHud.scaleFor(w);
          final gap = 6 * s;
          final tap = math.max(40.0, 44 * s);
          final title = enDigits(widget.titleText);
          return Container(
            height: UnifiedGameTopHud.height,
            padding: EdgeInsets.symmetric(horizontal: 10 * s),
            decoration: widget.bare
                ? null
                : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SlmColors.navy950.withValues(alpha: 0.94),
                        SlmColors.navy900.withValues(alpha: 0.82),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.22)),
                    ),
                  ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(widget.closeIcon, color: SlmColors.ivory, size: 22 * s),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(width: tap, height: tap),
                ),
                SizedBox(width: gap),
                // The level badge takes the free space and shrinks (never
                // cut) when it runs out, so a big score never pushes the bar
                // over the edge.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      label: title.isEmpty ? null : title,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                        decoration: BoxDecoration(
                          color: SlmColors.gold400.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10 * s),
                          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          enDigits(widget.badgeText),
                          maxLines: 1,
                          softWrap: false,
                          style: bangla(fontSize: 15 * s, fontWeight: FontWeight.w900, color: SlmColors.gold200, height: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: gap),
                // Unified Live ◆ Score Chip
                AnimatedBuilder(
                  animation: _bump,
                  builder: (_, child) {
                    final k = 1.0 + 0.18 * math.sin(_bump.value * math.pi);
                    return Transform.scale(scale: k, child: child);
                  },
                  child: Container(
                    key: widget.scoreKey,
                    padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2B45), Color(0xFF111A2E)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.65), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: SlmColors.gold400.withValues(alpha: 0.18),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '◆',
                          style: TextStyle(
                            color: SlmColors.gold300,
                            fontSize: 13 * s,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 5 * s),
                        Text(
                          enDigits('$shown'),
                          maxLines: 1,
                          softWrap: false,
                          style: bangla(
                            fontSize: 14 * s,
                            fontWeight: FontWeight.w900,
                            color: SlmColors.ivory,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.levelScore != null && !widget.stepOnly) ...[
                  SizedBox(width: gap),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: ScoreTotalTicker(total: save.points, scale: s),
                    ),
                  ),
                ],
                SizedBox(width: gap),
                // Unified 💀 Death Counter Chip
                DeathCountChip(deaths: save.deaths, chipKey: widget.deathKey, scale: s),
                if (widget.trailingExtra != null) ...[
                  SizedBox(width: 2 * s),
                  widget.trailingExtra!,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Overlay that flies the latest GameSave pulse toward the top score chip
/// along an energetic curved trajectory with spark particles.
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
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 980));
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
    final rawOrigin = pulse.originGlobal;
    final originGlobal = (rawOrigin != null && rawOrigin != Offset.zero)
        ? rawOrigin
        : Offset(size.width * 0.5, size.height * 0.52);
    final scoreBox = widget.scoreKey.currentContext?.findRenderObject() as RenderBox?;
    final targetGlobal = scoreBox != null && scoreBox.hasSize
        ? scoreBox.localToGlobal(Offset(scoreBox.size.width / 2, scoreBox.size.height / 2))
        : Offset(size.width - 78, MediaQuery.paddingOf(context).top + 28);
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
                final rawT = _c.value.clamp(0.0, 1.0);
                final t = Curves.easeOutCubic.transform(rawT);
                final linearPos = Offset.lerp(_from, _to, t)!;
                final arcLift = -72.0 * math.sin(rawT * math.pi);
                final pos = Offset(linearPos.dx, linearPos.dy + arcLift);
                final opacity = (rawT < 0.82 ? 1.0 : (1.0 - (rawT - 0.82) / 0.18)).clamp(0.0, 1.0);
                final positive = _delta > 0;
                final label = positive ? '+${enDigits('$_delta')} ◆' : '${enDigits('$_delta')} ◆';
                final color = positive ? SlmColors.emerald300 : SoftDanger.ink;
                final borderColor = positive ? SlmColors.gold300 : SoftDanger.ink;
                final popScale = rawT < 0.14
                    ? (0.55 + 0.85 * (rawT / 0.14))
                    : (1.4 - 0.55 * ((rawT - 0.14) / 0.86));

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Builder(
                        builder: (_) {
                          final trailT = (rawT - i * 0.045).clamp(0.0, 1.0);
                          final trailEase = Curves.easeOutCubic.transform(trailT);
                          final trailLinear = Offset.lerp(_from, _to, trailEase)!;
                          final trailLift = -72.0 * math.sin(trailT * math.pi);
                          final trailPos = Offset(trailLinear.dx, trailLinear.dy + trailLift);
                          final trailAlpha = (0.42 - i * 0.06) * opacity;
                          return Positioned(
                            left: trailPos.dx - 5,
                            top: trailPos.dy - 5,
                            child: Opacity(
                              opacity: trailAlpha.clamp(0.0, 1.0),
                              child: Container(
                                width: 10 - i * 0.8,
                                height: 10 - i * 0.8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (positive ? SlmColors.gold300 : SoftDanger.ink)
                                      .withValues(alpha: 0.9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (positive ? SlmColors.gold300 : SoftDanger.ink)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    Positioned(
                      left: pos.dx - 48,
                      top: pos.dy - 22,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: popScale.clamp(0.5, 1.6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: positive
                                    ? const [Color(0xF2143D2C), Color(0xF2081F18)]
                                    : const [Color(0xF23B1219), Color(0xF2240A0E)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: borderColor, width: 1.7),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.7),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                                const BoxShadow(
                                  color: Color(0x99000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              label,
                              style: bangla(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: positive ? SlmColors.gold200 : SoftDanger.ink,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
    // A broken promise is one more line to read.
    _c.duration = Duration(milliseconds: pulse.promiseBn != null ? 3400 : 2200);
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
                  'বাস্তবে এটা কিন্তু আপনার $deathN নম্বর মারাত্মক ভুল!',
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
                                    if (pulse.promiseBn != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        '${PromiseLines.broken} — “${pulse.promiseBn}”',
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        style: bangla(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: SlmColors.gold200,
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
