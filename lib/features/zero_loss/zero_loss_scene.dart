import 'dart:async';
import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'zero_loss_models.dart';
import 'zero_loss_ui.dart';

/// Logical size of the 3:4 stage every [ScenePlan] is authored against.
const _stageW = 300.0;
const _stageH = 400.0;

IconData spotIcon(String key) => switch (key) {
      'bolt' => Icons.bolt_rounded,
      'broken' => Icons.heart_broken_rounded,
      'water' => Icons.water_drop_rounded,
      'phone' => Icons.phone_in_talk_rounded,
      'permit' => Icons.assignment_late_rounded,
      'lock' => Icons.lock_open_rounded,
      'generator' => Icons.electric_bolt_rounded,
      'earth' => Icons.electrical_services_rounded,
      'person' => Icons.accessibility_new_rounded,
      'wire' => Icons.cable_rounded,
      'crowd' => Icons.groups_rounded,
      'bamboo' => Icons.dangerous_rounded,
      'slippers' => Icons.do_not_step_rounded,
      'helmet' => Icons.engineering_rounded,
      'gloves' => Icons.back_hand_rounded,
      'fence' => Icons.fence_rounded,
      _ => Icons.warning_rounded,
    };

/// A composed site scene: background plate, crew and props, tappable hazards,
/// and the visible result of the player's choice.
class ZlScene extends StatefulWidget {
  final ScenePlan plan;
  final HazardOption? picked;
  final Set<int> found;

  /// Spots react to taps only while hunting.
  final bool hunting;
  final ValueChanged<int> onFound;

  /// Crew shown on name tags for `lead` / `junior` layers.
  final Map<String, SmartLineman?> roles;

  const ZlScene({
    super.key,
    required this.plan,
    required this.picked,
    required this.found,
    required this.hunting,
    required this.onFound,
    this.roles = const {},
  });

  @override
  State<ZlScene> createState() => _ZlSceneState();
}

class _ZlSceneState extends State<ZlScene> {
  Offset? _miss;
  int _missCount = 0;
  int? _hint;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _armHint();
  }

  @override
  void didUpdateWidget(ZlScene old) {
    super.didUpdateWidget(old);
    if (old.found.length != widget.found.length || old.hunting != widget.hunting) _armHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _armHint() {
    _hintTimer?.cancel();
    if (_hint != null) setState(() => _hint = null);
    if (!widget.hunting) return;
    _hintTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      final next = List.generate(widget.plan.spots.length, (i) => i).where((i) => !widget.found.contains(i));
      if (next.isNotEmpty) setState(() => _hint = next.first);
    });
  }

  void _tap(Offset p) {
    if (!widget.hunting) return;
    final spots = widget.plan.spots;
    int? hit;
    var best = double.infinity;
    for (var i = 0; i < spots.length; i++) {
      final s = spots[i];
      final d = (Offset(s.x * _stageW, s.y * _stageH) - p).distance;
      final reach = s.r * _stageW + 10;
      if (d <= reach && d < best && !widget.found.contains(i)) {
        best = d;
        hit = i;
      }
    }
    if (hit != null) {
      HapticFeedback.mediumImpact();
      widget.onFound(hit);
    } else {
      HapticFeedback.selectionClick();
      setState(() {
        _miss = p;
        _missCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final picked = widget.picked;
    final wrong = picked != null && !picked.best;
    final tint = plan.indoor ? const Color(0xFFEDE3D4) : const Color(0xFFB4BFDC);

    final stage = SizedBox(
      width: _stageW,
      height: _stageH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _tap(d.localPosition),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: Image.asset(plan.background, fit: BoxFit.cover)),
            if (plan.storm) const Positioned.fill(child: StormOverlay(drops: 55, lightning: true)),
            for (var i = 0; i < plan.layers.length; i++)
              if (plan.layers[i].visibleFor(picked)) ..._layer(i, plan.layers[i], tint),
            for (var i = 0; i < plan.spots.length; i++)
              if (widget.found.contains(i))
                _SpotMarker(key: ValueKey('spot$i'), spot: plan.spots[i], dim: !widget.hunting)
              else if (_hint == i)
                _HintPulse(spot: plan.spots[i]),
            if (_miss != null) _MissRipple(key: ValueKey('miss$_missCount'), at: _miss!),
            if (wrong) ...[
              Positioned(
                left: plan.failX * _stageW - 60,
                top: plan.failY * _stageH - 60,
                width: 120,
                height: 120,
                child: const IgnorePointer(child: _SparkBurst()),
              ),
              const Positioned.fill(child: IgnorePointer(child: _Flash(color: ZlColors.red))),
            ],
            if (picked?.best ?? false) ...[
              const Positioned.fill(child: IgnorePointer(child: _Flash(color: ZlColors.green))),
              const Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: IgnorePointer(child: Center(child: PopIn(child: _Stamp()))),
              ),
            ],
          ],
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Image.asset(plan.background, fit: BoxFit.cover),
          ),
          const ColoredBox(color: Color(0x66000000)),
          Shake(
            trigger: wrong ? 1 : 0,
            child: Center(child: FittedBox(fit: BoxFit.contain, child: stage)),
          ),
        ],
      ),
    );
  }

  List<Widget> _layer(int i, SceneLayer l, Color tint) {
    final h = l.h * _stageH;
    final top = l.y * _stageH - h;
    final animate = l.when.isNotEmpty && widget.picked != null && !l.when.contains('before');
    Widget img = Image.asset(
      l.image,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    if (l.flip) img = Transform.flip(flipX: true, child: img);
    img = ColorFiltered(colorFilter: ColorFilter.mode(tint, BlendMode.modulate), child: img);
    if (animate) img = _DropIn(key: ValueKey('drop$i-${widget.picked?.id}'), child: img);

    final man = widget.roles[l.role];
    return [
      Positioned(left: l.x * _stageW - h * 1.5, top: top, width: h * 3, height: h, child: IgnorePointer(child: img)),
      if (man != null)
        Positioned(
          left: l.x * _stageW - 50,
          width: 100,
          top: max(2, top - 16),
          child: IgnorePointer(child: Center(child: _NameTag(man: man))),
        ),
    ];
  }
}

class _NameTag extends StatelessWidget {
  final SmartLineman man;

  const _NameTag({required this.man});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 2, 6, 2),
      decoration: BoxDecoration(color: const Color(0xCC0B1220), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CrewFace(man: man, size: 12),
          const SizedBox(width: 3),
          Text(man.name, style: zlText(7.5, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SpotMarker extends StatelessWidget {
  final SceneSpot spot;
  final bool dim;

  const _SpotMarker({super.key, required this.spot, required this.dim});

  @override
  Widget build(BuildContext context) {
    final r = spot.r * _stageW;
    final cx = spot.x * _stageW;
    final cy = spot.y * _stageH;
    final below = spot.y < 0.8;
    return Positioned(
      left: cx - 70,
      top: below ? cy - r : cy - r - 22,
      width: 140,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: dim ? 0.55 : 1,
          duration: const Duration(milliseconds: 300),
          child: PopIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!below) _label(),
                Container(
                  width: r * 2,
                  height: r * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ZlColors.amber, width: 2),
                    color: ZlColors.amber.withValues(alpha: 0.12),
                    boxShadow: [BoxShadow(color: ZlColors.amber.withValues(alpha: 0.6), blurRadius: 8)],
                  ),
                ),
                if (below) _label(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label() => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(color: ZlColors.red, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spotIcon(spot.icon), size: 9, color: Colors.white),
            const SizedBox(width: 2),
            Text(spot.labelBn, style: zlText(8, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      );
}

class _HintPulse extends StatefulWidget {
  final SceneSpot spot;

  const _HintPulse({required this.spot});

  @override
  State<_HintPulse> createState() => _HintPulseState();
}

class _HintPulseState extends State<_HintPulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.spot.r * _stageW;
    return Positioned(
      left: widget.spot.x * _stageW - r * 1.6,
      top: widget.spot.y * _stageH - r * 1.6,
      width: r * 3.2,
      height: r * 3.2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Center(
            child: Container(
              width: r * (1 + _c.value * 2),
              height: r * (1 + _c.value * 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.7 * (1 - _c.value)), width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissRipple extends StatelessWidget {
  final Offset at;

  const _MissRipple({super.key, required this.at});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - 20,
      top: at.dy - 20,
      width: 40,
      height: 40,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          builder: (_, v, _) => v >= 1
              ? const SizedBox.shrink()
              : Center(
                  child: Container(
                    width: 8 + v * 30,
                    height: 8 + v * 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8 * (1 - v)), width: 1.5),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DropIn extends StatelessWidget {
  final Widget child;

  const _DropIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - v) * -36), child: c),
      ),
      child: child,
    );
  }
}

class _Flash extends StatelessWidget {
  final Color color;

  const _Flash({required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 900),
      builder: (_, v, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.35 * v),
          border: Border.all(color: color.withValues(alpha: 0.4 + 0.6 * v), width: 3),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ZlColors.green,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: ZlColors.green.withValues(alpha: 0.6), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text('নিরাপদ', style: zlText(11, weight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Crackling electric arc at the point of failure.
class _SparkBurst extends StatefulWidget {
  const _SparkBurst();

  @override
  State<_SparkBurst> createState() => _SparkBurstState();
}

class _SparkBurstState extends State<_SparkBurst> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _SparkPainter(seed: DateTime.now().millisecondsSinceEpoch ~/ 90, t: _c.value),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final int seed;
  final double t;

  _SparkPainter({required this.seed, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = Random(seed);
    canvas.drawCircle(
      c,
      14 + 6 * sin(t * pi),
      Paint()
        ..color = const Color(0xAAE0F2FE)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final glow = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final core = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 7; i++) {
      final a = r.nextDouble() * pi * 2;
      final len = size.width * (0.22 + r.nextDouble() * 0.26);
      final path = Path()..moveTo(c.dx, c.dy);
      var p = c;
      for (var k = 1; k <= 4; k++) {
        final d = len * k / 4;
        p = c + Offset(cos(a) * d, sin(a) * d) + Offset(r.nextDouble() * 8 - 4, r.nextDouble() * 8 - 4);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, core);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.seed != seed || old.t != t;
}
