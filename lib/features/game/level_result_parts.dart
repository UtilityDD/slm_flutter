import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_fx.dart';

/// Lowest mark (%) that clears a lesson level.
const kLessonPassMark = 60;

/// Mark for a lesson level: share of questions answered right on the first try.
class LessonMarks {
  int asked = 0;
  int clean = 0;
  var _missed = false;

  /// A wrong answer on the question on screen.
  void miss() => _missed = true;

  /// True once the question on screen has had a wrong answer.
  bool get missedCurrent => _missed;

  /// The question on screen is finished; [right] false when it ended wrong.
  void settle({bool right = true}) {
    asked++;
    if (right && !_missed) clean++;
    _missed = false;
  }

  int get percent => asked == 0 ? 0 : (clean * 100 / asked).round();
  bool get passed => percent >= kLessonPassMark;
}

String _clock(int ms) {
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// One quiet line about earlier plays of this level; nothing on a first play.
class LevelHistoryChip extends StatelessWidget {
  const LevelHistoryChip({super.key, required this.plays, this.bestMark, this.bestMs});

  final int plays;
  final int? bestMark;
  final int? bestMs;

  @override
  Widget build(BuildContext context) {
    if (plays <= 0) return const SizedBox.shrink();
    final parts = [
      if (bestMark != null) 'সেরা $bestMark%',
      if (bestMs != null && bestMs! > 0) _clock(bestMs!),
      '$plays বার খেলেছেন',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: SlmColors.navy950.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SlmColors.mist.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 14, color: SlmColors.mist.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              enDigits('আগে: ${parts.join(' · ')}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: SlmColors.mist),
            ),
          ),
        ],
      ),
    );
  }
}

/// Below the pass mark: the card drops and shakes, the meter fills short of
/// the pass line, and the same falling sting plays for every lesson level.
class LevelFailPanel extends StatefulWidget {
  const LevelFailPanel({
    super.key,
    required this.percent,
    required this.muted,
    required this.onRetry,
    required this.onLeave,
    this.onRead,
    this.history,
  });

  final int percent;
  final bool muted;
  final VoidCallback onRetry;
  final VoidCallback onLeave;
  final VoidCallback? onRead;
  final Widget? history;

  @override
  State<LevelFailPanel> createState() => _LevelFailPanelState();
}

class _LevelFailPanelState extends State<LevelFailPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      if (!widget.muted) unawaited(ZlFx.cue('sounds/learn/level_fail.wav', volume: 0.8, muted: false));
      if (MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context)) {
        _in.value = 1;
      } else {
        _in.forward();
      }
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _card();
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _in,
        child: card,
        builder: (_, card) {
          final t = _in.value;
          final drop = Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
          final shakeT = ((t - 0.3) / 0.22).clamp(0.0, 1.0);
          final shake = math.sin(shakeT * math.pi * 6) * 10 * (1 - shakeT);
          return Opacity(
            opacity: (t / 0.15).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(shake, -60 * (1 - drop)),
              child: Transform.scale(scale: 0.85 + 0.15 * drop, child: card),
            ),
          );
        },
      ),
    );
  }

  Widget _card() {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1F35), Color(0xFF0E172C)],
        ),
        border: Border.all(color: SlmColors.danger.withValues(alpha: 0.7), width: 1.6),
        boxShadow: [
          BoxShadow(color: SlmColors.danger.withValues(alpha: 0.25), blurRadius: 28, spreadRadius: 1),
          const BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SlmColors.danger.withValues(alpha: 0.18),
              border: Border.all(color: SlmColors.danger.withValues(alpha: 0.8), width: 2),
            ),
            child: const Icon(Icons.replay_rounded, size: 34, color: SlmColors.danger),
          ),
          const SizedBox(height: 12),
          Text(
            'এবার পাস হলো না',
            textAlign: TextAlign.center,
            style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: SlmColors.ivory),
          ),
          const SizedBox(height: 4),
          Text(
            enDigits('পাস করতে লাগবে $kLessonPassMark%, আপনি পেয়েছেন ${widget.percent}%'),
            textAlign: TextAlign.center,
            style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.mist),
          ),
          const SizedBox(height: 14),
          _Meter(fill: _in, percent: widget.percent),
          if (widget.history != null) ...[const SizedBox(height: 12), widget.history!],
          const SizedBox(height: 16),
          _FailButton(label: 'আবার খেলুন', icon: Icons.replay_rounded, filled: true, onTap: widget.onRetry),
          if (widget.onRead != null) ...[
            const SizedBox(height: 8),
            _FailButton(label: 'পাঠটা পড়ুন', icon: Icons.menu_book_rounded, filled: false, onTap: widget.onRead!),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: widget.onLeave,
            child: Text(
              'ফিরে যান',
              style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.mist),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mark bar with the pass line; fills during 0.3–0.9 of [fill].
class _Meter extends StatelessWidget {
  const _Meter({required this.fill, required this.percent});

  final Animation<double> fill;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (_, box) {
          final w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                height: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: SlmColors.navy700,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 8,
                height: 12,
                child: AnimatedBuilder(
                  animation: fill,
                  builder: (_, _) {
                    final p = Curves.easeOutCubic.transform(((fill.value - 0.3) / 0.6).clamp(0.0, 1.0));
                    return Container(
                      width: w * percent / 100 * p,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(colors: [SlmColors.warning, SlmColors.danger]),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: w * kLessonPassMark / 100 - 1,
                top: 2,
                width: 2,
                height: 24,
                child: const ColoredBox(color: SlmColors.emerald400),
              ),
              Positioned(
                left: w * kLessonPassMark / 100 - 30,
                width: 60,
                top: 24,
                child: Text(
                  enDigits('পাস $kLessonPassMark%'),
                  textAlign: TextAlign.center,
                  style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: SlmColors.emerald300),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FailButton extends StatelessWidget {
  const _FailButton({required this.label, required this.icon, required this.filled, required this.onTap});

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = filled ? SlmColors.navy950 : SlmColors.ivory;
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled ? SlmGradients.gold : null,
          color: filled ? null : SlmColors.navy950.withValues(alpha: 0.5),
          border: Border.all(color: filled ? SlmColors.gold700 : SlmColors.gold400.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: ink),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
