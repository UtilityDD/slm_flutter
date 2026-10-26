import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'zero_loss_engine.dart';
import 'zero_loss_fx.dart';
import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

// ---------------------------------------------------------------------------
// Score vocabulary shared by toasts, rules and the debrief.
// ---------------------------------------------------------------------------

Color scoreKindColor(ScoreKind k) => switch (k) {
      ScoreKind.add => ZlColors.green,
      ScoreKind.deduct => ZlColors.orange,
      ScoreKind.penalty => ZlColors.red,
    };

String scoreKindBn(ScoreKind k) => switch (k) {
      ScoreKind.add => 'যোগ',
      ScoreKind.deduct => 'বিয়োগ',
      ScoreKind.penalty => 'শাস্তি',
    };

IconData scoreKindIcon(ScoreKind k) => switch (k) {
      ScoreKind.add => Icons.add_circle_rounded,
      ScoreKind.deduct => Icons.remove_circle_rounded,
      ScoreKind.penalty => Icons.gavel_rounded,
    };

IconData scoreCauseIcon(ScoreCause c) => switch (c) {
      ScoreCause.decision => Icons.check_circle_rounded,
      ScoreCause.chant => Icons.record_voice_over_rounded,
      ScoreCause.restore => Icons.lightbulb_rounded,
      ScoreCause.onTime => Icons.timer_rounded,
      ScoreCause.zeroLoss => Icons.military_tech_rounded,
      ScoreCause.dutyBonus => Icons.engineering_rounded,
      ScoreCause.wrongDecision => Icons.cancel_rounded,
      ScoreCause.chantMistake => Icons.voice_over_off_rounded,
      ScoreCause.decoy => Icons.do_not_touch_rounded,
      ScoreCause.shortcut => Icons.fast_forward_rounded,
      ScoreCause.reload => Icons.replay_rounded,
      ScoreCause.missingJob => Icons.inventory_2_rounded,
      ScoreCause.late => Icons.alarm_rounded,
      ScoreCause.accident => Icons.personal_injury_rounded,
      ScoreCause.complaint => Icons.phone_callback_rounded,
    };

String signedBn(int v) => v > 0 ? '+${n(v)}' : v < 0 ? '−${n(-v)}' : n(0);

// ---------------------------------------------------------------------------
// Score breakdown: যোগ, বিয়োগ, শাস্তি, মোট
// ---------------------------------------------------------------------------

class ScoreBreakdown extends StatelessWidget {
  final List<ScoreEntry> entries;
  final String totalLabel;

  const ScoreBreakdown({super.key, required this.entries, this.totalLabel = 'মোট পয়েন্ট'});

  @override
  Widget build(BuildContext context) {
    final total = entries.fold(0, (a, e) => a + e.points);
    var row = 0;
    final sections = <Widget>[];
    for (final kind in ScoreKind.values) {
      final ofKind = entries.where((e) => e.kind == kind).toList();
      if (ofKind.isEmpty) continue;
      final grouped = <ScoreCause, (int, int)>{};
      for (final e in ofKind) {
        final g = grouped[e.cause] ?? (0, 0);
        grouped[e.cause] = (g.$1 + e.points, g.$2 + 1);
      }
      final c = scoreKindColor(kind);
      final sub = ofKind.fold(0, (a, e) => a + e.points);
      sections.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Row(
          children: [
            Icon(scoreKindIcon(kind), size: 16, color: c),
            const SizedBox(width: 6),
            Text(scoreKindBn(kind), style: zlText(13, weight: FontWeight.w900, color: c)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: c.withValues(alpha: 0.3))),
            const SizedBox(width: 8),
            Text(signedBn(sub), style: zlText(13, weight: FontWeight.w900, color: c)),
          ],
        ),
      ));
      for (final g in grouped.entries) {
        sections.add(PopIn(
          delay: Duration(milliseconds: 60 * row++),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Icon(scoreCauseIcon(g.key), size: 18, color: c.withValues(alpha: 0.85)),
                const SizedBox(width: 8),
                Expanded(child: Text(g.key.labelBn, style: zlText(13.5, weight: FontWeight.w700))),
                if (g.value.$2 > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text('×${n(g.value.$2)}', style: zlText(12, weight: FontWeight.w700, color: ZlColors.soft)),
                  ),
                SizedBox(
                  width: 58,
                  child: Text(signedBn(g.value.$1), textAlign: TextAlign.right, style: zlText(15, weight: FontWeight.w900, color: c)),
                ),
              ],
            ),
          ),
        ));
      }
    }
    final tc = total >= 0 ? ZlColors.amber : ZlColors.red;
    return ZlPanel(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...sections,
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tc),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: tc, size: 22),
                const SizedBox(width: 6),
                Expanded(child: Text(totalLabel, style: zlText(15, weight: FontWeight.w900))),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: total.toDouble()),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Text(n(v.round()), style: zlText(24, weight: FontWeight.w900, color: tc, height: 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating score toasts
// ---------------------------------------------------------------------------

/// Pops a chip for every new ledger entry ("+২০ সঠিক সিদ্ধান্ত", "−১৫ শর্টকাট").
/// Same-cause entries from one action merge into one chip.
class ScoreToastLayer extends ConsumerStatefulWidget {
  const ScoreToastLayer({super.key});

  @override
  ConsumerState<ScoreToastLayer> createState() => _ScoreToastLayerState();
}

class _ToastData {
  final int id;
  final ScoreCause cause;
  final int points;
  final int count;

  const _ToastData(this.id, this.cause, this.points, this.count);
}

class _ScoreToastLayerState extends ConsumerState<ScoreToastLayer> {
  final _toasts = <_ToastData>[];
  var _nextId = 0;

  void _onLedger(int? prev, int next) {
    final s = ref.read(zeroLossProvider);
    if (s == null) return;
    final from = prev ?? 0;
    if (next <= from) {
      if (next < from) setState(_toasts.clear);
      return;
    }
    final fresh = s.ledger.sublist(from, next).where((e) => !s.duty || e.cause.liveInDuty).toList();
    if (fresh.isEmpty) return;
    final grouped = <ScoreCause, (int, int)>{};
    for (final e in fresh) {
      final g = grouped[e.cause] ?? (0, 0);
      grouped[e.cause] = (g.$1 + e.points, g.$2 + 1);
    }
    final kinds = fresh.map((e) => e.kind).toSet();
    if (kinds.contains(ScoreKind.penalty)) {
      HapticFeedback.heavyImpact();
    } else if (kinds.contains(ScoreKind.deduct)) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() {
      for (final e in grouped.entries) {
        _toasts.add(_ToastData(_nextId++, e.key, e.value.$1, e.value.$2));
      }
      while (_toasts.length > 4) {
        _toasts.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(zeroLossProvider.select((s) => s?.ledger.length ?? 0), _onLedger);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in _toasts)
                _ScoreToast(
                  key: ValueKey(t.id),
                  data: t,
                  onDone: () {
                    if (mounted) setState(() => _toasts.removeWhere((x) => x.id == t.id));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreToast extends StatefulWidget {
  final _ToastData data;
  final VoidCallback onDone;

  const _ScoreToast({super.key, required this.data, required this.onDone});

  @override
  State<_ScoreToast> createState() => _ScoreToastState();
}

class _ScoreToastState extends State<_ScoreToast> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final kind = d.cause.kind;
    final c = scoreKindColor(kind);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        final pop = Curves.easeOutBack.transform((t / 0.14).clamp(0.0, 1.0));
        final out = ((t - 0.8) / 0.2).clamp(0.0, 1.0);
        final shake = kind == ScoreKind.add ? 0.0 : sin(t * 70) * 5 * (1 - (t / 0.25).clamp(0.0, 1.0));
        return Opacity(
          opacity: (1 - out) * pop.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(shake, -14 * out),
            child: Transform.scale(scale: 0.6 + 0.4 * pop, child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
        decoration: BoxDecoration(
          color: Color.alphaBlend(c.withValues(alpha: 0.22), ZlColors.bg),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c, width: 1.6),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 16)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 14, backgroundColor: c, child: Icon(scoreCauseIcon(d.cause), size: 17, color: ZlColors.bg)),
            const SizedBox(width: 8),
            Text(signedBn(d.points), style: zlText(19, weight: FontWeight.w900, color: c, height: 1)),
            const SizedBox(width: 8),
            Text(
              d.count > 1 ? '${d.cause.labelBn} ×${n(d.count)}' : d.cause.labelBn,
              style: zlText(13.5, weight: FontWeight.w800, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stress clock
// ---------------------------------------------------------------------------

/// Projected finish minute against the deadline. The hand sweeps when minutes
/// are added, a "+N′" floats up, and past the deadline the dial pulses red and shakes.
class StressClock extends StatefulWidget {
  final int minute;
  final int limit;
  final double size;

  const StressClock({super.key, required this.minute, required this.limit, this.size = 46});

  @override
  State<StressClock> createState() => _StressClockState();
}

class _StressClockState extends State<StressClock> with TickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final _jolt = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  int _delta = 0;

  bool get _late => widget.minute > widget.limit;

  @override
  void initState() {
    super.initState();
    if (_late) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StressClock old) {
    super.didUpdateWidget(old);
    if (widget.minute > old.minute) {
      _delta = widget.minute - old.minute;
      _jolt.forward(from: 0);
      if (_late) HapticFeedback.heavyImpact();
    }
    if (_late && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_late && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _jolt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final scale = max(widget.limit * 1.25, widget.minute.toDouble());
    final c = _late ? ZlColors.red : (widget.minute > widget.limit * 0.85 ? ZlColors.amber : ZlColors.green);
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _jolt]),
        builder: (_, _) {
          final j = _jolt.value;
          final shakeAmp = _late ? 4.0 : 1.5;
          final shake = _jolt.isAnimating ? sin(j * 60) * shakeAmp * (1 - (j / 0.4).clamp(0.0, 1.0)) : 0.0;
          final floatT = _jolt.isAnimating ? j : 1.0;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(shake, 0),
                child: Transform.scale(
                  scale: 1 + 0.08 * _pulse.value,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (_late) BoxShadow(color: ZlColors.red.withValues(alpha: 0.35 + 0.4 * _pulse.value), blurRadius: 14, spreadRadius: 1),
                      ],
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.minute.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      builder: (_, m, _) => CustomPaint(
                        painter: _ClockPainter(
                          hand: (m / scale).clamp(0.0, 1.0),
                          limit: widget.limit / scale,
                          color: c,
                          flash: _late ? _pulse.value : 0,
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: size * 0.42),
                            child: Text(
                              '${n(m.round())}′',
                              style: zlText(size * 0.22, weight: FontWeight.w900, color: c, height: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_jolt.isAnimating && _delta > 0)
                Positioned(
                  top: -6 - 26 * Curves.easeOut.transform(floatT),
                  child: Opacity(
                    opacity: (1 - floatT).clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                      child: Text('+${n(_delta)}′', style: zlText(12, weight: FontWeight.w900, color: ZlColors.bg, height: 1.1)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final double hand;
  final double limit;
  final Color color;
  final double flash;

  const _ClockPainter({required this.hand, required this.limit, required this.color, required this.flash});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = Color.lerp(ZlColors.panelHi, const Color(0xFF4C1010), flash)!);
    final ring = Rect.fromCircle(center: c, radius: r - 3);
    const start = -pi / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(ring, start, 2 * pi * limit, false, stroke..color = ZlColors.green.withValues(alpha: 0.35));
    canvas.drawArc(ring, start + 2 * pi * limit, 2 * pi * (1 - limit), false, stroke..color = ZlColors.red.withValues(alpha: 0.45));
    canvas.drawArc(ring, start, 2 * pi * hand, false, stroke..color = color);

    final tick = Paint()
      ..color = ZlColors.soft.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 12; i++) {
      final a = start + i * pi / 6;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * (r - 9), c + Offset(cos(a), sin(a)) * (r - 6.5), tick);
    }
    final la = start + 2 * pi * limit;
    canvas.drawLine(
      c + Offset(cos(la), sin(la)) * (r - 11),
      c + Offset(cos(la), sin(la)) * (r + 1),
      Paint()
        ..color = ZlColors.red
        ..strokeWidth = 2.4,
    );

    final a = start + 2 * pi * hand;
    canvas.drawLine(
      c,
      c + Offset(cos(a), sin(a)) * (r - 10),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.hand != hand || old.limit != limit || old.color != color || old.flash != flash;
}

// ---------------------------------------------------------------------------
// Customer pop-ups
// ---------------------------------------------------------------------------

/// Angry or worried locals slide in from the screen edge while the crew works.
/// Faster and angrier when the active job is running late; a late call costs points.
class CustomerPopLayer extends ConsumerStatefulWidget {
  final bool active;

  const CustomerPopLayer({super.key, required this.active});

  @override
  ConsumerState<CustomerPopLayer> createState() => _CustomerPopLayerState();
}

class _CustomerPop {
  final Customer customer;
  final String line;
  final bool fromLeft;
  final bool angry;
  final double y;
  final int id;

  const _CustomerPop(this.id, this.customer, this.line, this.fromLeft, this.angry, this.y);
}

class _CustomerPopLayerState extends ConsumerState<CustomerPopLayer> {
  final _rng = Random();
  Timer? _next;
  Timer? _hide;
  _CustomerPop? _pop;
  var _id = 0;
  var _lastIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.active) _schedule(first: true);
  }

  @override
  void didUpdateWidget(CustomerPopLayer old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _schedule(first: true);
    if (!widget.active && old.active) {
      _next?.cancel();
      _hide?.cancel();
      setState(() => _pop = null);
    }
  }

  @override
  void dispose() {
    _next?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  /// The job the public is waiting on right now.
  String? _focus(ZeroLossState s) {
    final active = s.activeFaultId;
    if (active != null) return active;
    for (final f in s.scenario.faults) {
      if (s.mission(f.id).stage != MissionStage.done) return f.id;
    }
    return null;
  }

  bool _isLate(ZeroLossState s) {
    final id = _focus(s);
    return id != null && s.isLate(id);
  }

  void _schedule({bool first = false}) {
    _next?.cancel();
    final s = ref.read(zeroLossProvider);
    final late = s != null && _isLate(s);
    final secs = first ? 6 + _rng.nextInt(5) : (late ? 7 + _rng.nextInt(4) : 14 + _rng.nextInt(7));
    _next = Timer(Duration(seconds: secs), _show);
  }

  void _show() {
    if (!mounted || !widget.active) return;
    final s = ref.read(zeroLossProvider);
    final people = s?.scenario.customers ?? const <Customer>[];
    if (s == null || people.isEmpty) return;
    var i = _rng.nextInt(people.length);
    if (people.length > 1 && i == _lastIndex) i = (i + 1) % people.length;
    _lastIndex = i;
    final who = people[i];
    final faultId = _focus(s);
    final late = _isLate(s);
    final pool = late && who.lateLinesBn.isNotEmpty ? who.lateLinesBn : who.linesBn;
    if (pool.isEmpty) return;
    final place = faultId == null ? s.setting.placeA : s.mission(faultId).location;
    final line = s.setting.fill(pool[_rng.nextInt(pool.length)]).replaceAll('{place}', place);

    if (late && faultId != null) {
      ref.read(zeroLossProvider.notifier).customerComplaint(faultId);
      ZlFx.cue('sounds/complaint.wav', volume: 0.72);
      HapticFeedback.heavyImpact();
    } else {
      ZlFx.cue('sounds/customer.wav', volume: 0.46);
      HapticFeedback.lightImpact();
    }

    setState(() => _pop = _CustomerPop(_id++, who, line, _rng.nextBool(), late, 0.18 + _rng.nextDouble() * 0.32));
    _hide?.cancel();
    _hide = Timer(Duration(milliseconds: late ? 3400 : 3000), _dismiss);
  }

  void _dismiss() {
    _hide?.cancel();
    if (!mounted) return;
    setState(() => _pop = null);
    if (widget.active) _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final p = _pop;
    return LayoutBuilder(
      builder: (_, box) => Stack(
        children: [
          if (p != null)
            Positioned(
              key: ValueKey(p.id),
              top: box.maxHeight * p.y,
              left: p.fromLeft ? 0 : null,
              right: p.fromLeft ? null : 0,
              child: GestureDetector(
                onTap: _dismiss,
                child: _CustomerCard(pop: p, maxWidth: box.maxWidth * 0.82),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatefulWidget {
  final _CustomerPop pop;
  final double maxWidth;

  const _CustomerCard({required this.pop, required this.maxWidth});

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> with TickerProviderStateMixin {
  late final _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))..forward();
  late final _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _slide.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pop;
    final left = p.fromLeft;
    final accent = p.angry ? ZlColors.red : ZlColors.amber;
    const face = 96.0;

    final portrait = SizedBox(
      width: face,
      height: face * 1.1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(left ? 1 : -1, 1, 1),
              child: Image.asset(p.customer.image, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
            ),
          ),
          Positioned(
            top: 0,
            right: left ? 0 : null,
            left: left ? null : 0,
            child: AnimatedBuilder(
              animation: _ring,
              builder: (_, child) => Transform.rotate(angle: sin(_ring.value * pi * 8) * 0.35, child: child),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: accent,
                child: Icon(p.angry ? Icons.priority_high_rounded : Icons.phone_in_talk_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );

    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
        decoration: BoxDecoration(
          color: p.angry ? const Color(0xFFFEE2E2) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(left ? 4 : 16),
            bottomRight: Radius.circular(left ? 16 : 4),
          ),
          border: Border.all(color: accent, width: p.angry ? 2 : 1),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.customer.nameBn, style: zlText(11, weight: FontWeight.w800, color: const Color(0xFF9A3412))),
            Text(p.line, style: zlText(15, weight: FontWeight.w900, color: const Color(0xFF1C1917), height: 1.25)),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_slide, _ring]),
      builder: (_, child) {
        final t = Curves.easeOutBack.transform(_slide.value);
        final shake = p.angry && _slide.isCompleted ? sin(_ring.value * pi * 6) * 1.5 : 0.0;
        return FractionalTranslation(
          translation: Offset((left ? -1 : 1) * (1 - t), 0),
          child: Transform.translate(offset: Offset(shake, 0), child: child),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: left ? [portrait, const SizedBox(width: 2), bubble] : [bubble, const SizedBox(width: 2), portrait],
        ),
      ),
    );
  }
}
