import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../shell/shell_providers.dart';
import '../training/training_models.dart';
import '../zero_loss/zero_loss_fx.dart';

/// Lesson cleared: a gold seal stamps down, joins the module's seal row, and
/// the next lesson unlocks. No points — the seal and the open door are the win.
/// Every animation is one-shot; the settled page draws no frames.
class LessonSealPage extends StatefulWidget {
  const LessonSealPage({
    super.key,
    required this.lesson,
    required this.seals,
    required this.mine,
    required this.revision,
    required this.bn,
    this.muted = false,
    this.next,
    this.onOpenNext,
  });

  final LessonCardItem lesson;

  /// One entry per lesson of this module in order: has its seal (this one included).
  final List<bool> seals;

  /// Index of this lesson in [seals].
  final int mine;
  final bool revision;
  final bool bn;

  /// The level that opened the lesson was muted: stamp without sound.
  final bool muted;
  final LessonCardItem? next;
  final VoidCallback? onOpenNext;

  @override
  State<LessonSealPage> createState() => _LessonSealPageState();
}

class _LessonSealPageState extends State<LessonSealPage> with TickerProviderStateMixin {
  static const _stampAt = 0.42;

  late final AnimationController _run =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  Timer? _thud;
  var _stamped = false;

  @override
  void initState() {
    super.initState();
    _thud = Timer(_run.duration! * _stampAt, _onStamp);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_run.isAnimating || _run.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context)) {
      _run.value = 1;
      _thud?.cancel();
      _onStamp();
    } else {
      _run.forward();
    }
  }

  void _onStamp() {
    if (!mounted || _stamped) return;
    setState(() => _stamped = true);
    HapticFeedback.heavyImpact();
    unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.85, muted: widget.muted));
    Timer(const Duration(milliseconds: 260), () {
      if (mounted) unawaited(ZlFx.cue('sounds/quiz_complete.wav', volume: 0.7, muted: widget.muted));
    });
  }

  @override
  void dispose() {
    _thud?.cancel();
    _run.dispose();
    super.dispose();
  }

  double _span(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_run.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final bn = widget.bn;
    final l = widget.lesson;
    final code = enDigits('${l.moduleNumber}.${l.chapterNumber}');
    final next = widget.next;

    return Theme(
      data: SlmTheme.night(),
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.35),
              radius: 1.1,
              colors: [Color(0xFF1C2C4C), SlmColors.navy950],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - 40)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _run,
                            builder: (_, _) => _stampStack(code),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _fadeUp(
                        0.5,
                        Text(
                          widget.revision
                              ? tr(bn, 'রিভিশন সম্পন্ন!', 'Revision done!')
                              : tr(bn, 'পাঠ সম্পন্ন!', 'Lesson complete!'),
                          style: bangla(fontSize: 30, fontWeight: FontWeight.w900, color: SlmColors.gold200),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _fadeUp(
                        0.56,
                        Text(
                          l.title,
                          textAlign: TextAlign.center,
                          style: bangla(fontSize: 16, fontWeight: FontWeight.w700, color: SlmColors.ivory),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _fadeUp(
                        0.6,
                        Text(
                          widget.revision
                              ? tr(bn, 'জ্ঞান আরও পাকা হলো।', 'Your knowledge just got stronger.')
                              : tr(bn, 'এই পাঠের সিল এখন আপনার।', 'This lesson\'s seal is yours.'),
                          style: bangla(fontSize: 14, fontWeight: FontWeight.w600, color: SlmColors.mist),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _fadeUp(0.64, _sealRow()),
                      const SizedBox(height: 22),
                      if (next != null) _fadeUp(0.74, _nextCard(next)),
                      const SizedBox(height: 22),
                      _fadeUp(
                        0.8,
                        Row(
                          children: [
                            Expanded(
                              child: _SealButton(
                                label: tr(bn, 'ফিরে যান', 'Back'),
                                filled: next == null,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ),
                            if (next != null && widget.onOpenNext != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SealButton(
                                  label: tr(bn, 'পরের পাঠ', 'Next lesson'),
                                  filled: true,
                                  icon: Icons.arrow_forward_rounded,
                                  onTap: widget.onOpenNext!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Seal drops from above, oversized and tilted, lands with a squash and an
  /// ink ring; sparks fly once on impact.
  Widget _stampStack(String code) {
    final drop = _span(0, _stampAt, Curves.easeInCubic);
    final land = _span(_stampAt, _stampAt + 0.16, Curves.easeOut);
    final ring = _span(_stampAt, _stampAt + 0.3);
    final settle = math.sin(land * math.pi) * 0.08;
    final scale = _stamped ? 1 + settle : 2.4 - 1.4 * drop;
    final angle = _stamped ? -0.08 * (1 - land) : -0.5 * (1 - drop) - 0.08;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_stamped && ring < 1)
          Container(
            width: 150 + 110 * ring,
            height: 150 + 110 * ring,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: SlmColors.gold300.withValues(alpha: 0.7 * (1 - ring)),
                width: 6 * (1 - ring) + 1,
              ),
            ),
          ),
        if (_stamped) const SlmSparkBurst(playOnMount: true, radius: 118, count: 24),
        Opacity(
          opacity: (drop * 3).clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: _Seal(code: code, size: 150),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fadeUp(double at, Widget child) {
    return AnimatedBuilder(
      animation: _run,
      child: child,
      builder: (_, c) {
        final t = _span(at, at + 0.16);
        if (t >= 1) return c!;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: c),
        );
      },
    );
  }

  /// The module's seals: earned ones gold, the new one pops in last.
  Widget _sealRow() {
    final seals = widget.seals.isEmpty ? const [true] : widget.seals;
    final total = seals.length;
    final done = seals.where((s) => s).length;
    final mine = widget.seals.isEmpty ? 0 : widget.mine;
    return Column(
      children: [
        Text(
          enDigits(tr(widget.bn, 'এই ধাপের সিল  $done/$total', 'Seals in this step  $done/$total')),
          style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold300),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedBuilder(
                animation: _run,
                builder: (_, _) {
                  final isMine = i == mine && !widget.revision;
                  final pop = isMine ? _span(0.7, 0.84, Curves.elasticOut) : 1.0;
                  final earned = isMine ? pop > 0.05 : seals[i];
                  return Transform.scale(
                    scale: isMine ? 0.4 + 0.6 * pop : 1,
                    child: _MiniSeal(earned: earned, label: enDigits('${i + 1}')),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _nextCard(LessonCardItem next) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: SlmColors.navy900.withValues(alpha: 0.85),
        border: Border.all(color: SlmColors.emerald400.withValues(alpha: 0.6), width: 1.3),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SlmColors.emerald400.withValues(alpha: 0.18),
            ),
            child: const Icon(Icons.lock_open_rounded, color: SlmColors.emerald300, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(widget.bn, 'পরের পাঠ খুলে গেছে', 'Next lesson unlocked'),
                  style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.emerald300),
                ),
                const SizedBox(height: 2),
                Text(
                  enDigits('${next.moduleNumber}.${next.chapterNumber}  ${next.title}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.ivory),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold wax-style seal with the lesson code.
class _Seal extends StatelessWidget {
  const _Seal({required this.code, required this.size});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.35),
          colors: [Color(0xFFFFE9A8), Color(0xFFE2A93B), Color(0xFF9A6514)],
          stops: [0, 0.6, 1],
        ),
        boxShadow: [
          BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.55), blurRadius: 30, spreadRadius: 2),
          const BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7A4D0C).withValues(alpha: 0.7), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, size: size * 0.24, color: const Color(0xFF5C3A08)),
              Text(
                code,
                style: bangla(fontSize: size * 0.2, fontWeight: FontWeight.w900, color: const Color(0xFF3E2705)),
              ),
              Text(
                'সম্পন্ন',
                style: bangla(fontSize: size * 0.1, fontWeight: FontWeight.w900, color: const Color(0xFF5C3A08)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSeal extends StatelessWidget {
  const _MiniSeal({required this.earned, required this.label});

  final bool earned;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned ? SlmGradients.gold : null,
        color: earned ? null : SlmColors.navy900,
        border: Border.all(
          color: earned ? SlmColors.gold700 : SlmColors.gold400.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: earned
          ? const Icon(Icons.verified_rounded, size: 18, color: SlmColors.navy950)
          : Text(label, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.mist)),
    );
  }
}

class _SealButton extends StatelessWidget {
  const _SealButton({required this.label, required this.filled, required this.onTap, this.icon});

  final String label;
  final bool filled;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = filled ? SlmColors.navy950 : SlmColors.ivory;
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: filled ? SlmGradients.gold : null,
          color: filled ? null : SlmColors.navy900,
          border: Border.all(color: filled ? SlmColors.gold700 : SlmColors.gold400.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
            if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: 20, color: ink)],
          ],
        ),
      ),
    );
  }
}
