import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../duty_slip/duty_slip_page.dart';
import '../shell/shell_providers.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'home_toolbox.dart';

/// Beat 3: red fear, emerald-standard skull, three lines, then the ladder.
class PathFearPage extends ConsumerStatefulWidget {
  const PathFearPage({super.key});

  @override
  ConsumerState<PathFearPage> createState() => _PathFearPageState();
}

class _PathFearPageState extends ConsumerState<PathFearPage> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _breath;
  late final AnimationController _gaze;
  late final AnimationController _script;
  late final AnimationController _sweep;
  late final AnimationController _resolveSweep;
  var _arrowOn = false;
  var _skipped = false;
  var _resolveLooping = false;

  static const _lines = <(String, Color)>[
    ('বিদ্যুতে ছোট ভুল বলে কিছু নেই।', Color(0xFFC3CCDD)),
    ('একটি ভুলেই জীবন শেষ।', Color(0xFFFFE8E6)),
    ('সব নিয়ম মেনে নিরাপদে বাড়ি ফিরব।', const Color(0xFF6EE7B7)),
  ];

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _gaze = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));
    _script = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));
    _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _resolveSweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _script.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _arrowOn = true);
        _startResolveLoop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _enter.value = 1;
      _script.value = 1;
      _breath.stop();
      _gaze.stop();
      _resolveSweep.stop();
      _arrowOn = true;
      return;
    }
    if (!_breath.isAnimating) _breath.repeat(reverse: true);
    if (!_gaze.isAnimating) _gaze.repeat(reverse: true);
    if (_script.status == AnimationStatus.dismissed) {
      _script.forward();
      _armSounds();
      _runSweeps();
    } else if (_script.isCompleted) {
      _startResolveLoop();
    }
  }

  void _startResolveLoop() {
    if (_resolveLooping || _skipped) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _resolveLooping = true;
    _resolveSweep.repeat();
  }

  void _armSounds() {
    _at(40, 'sounds/intro/impact_metal.ogg', 0.58);
    _at(520, 'sounds/intro/glass.ogg', 0.48);
    _at(1500, 'sounds/intro/tick.ogg', 0.3);
    _at(2900, 'sounds/intro/tick.ogg', 0.28);
    _at(4300, 'sounds/intro/confirm.ogg', 0.36);
  }

  void _runSweeps() {
    Future<void>.delayed(const Duration(milliseconds: 1280), () {
      if (!mounted || _skipped) return;
      _sweep.forward(from: 0);
    });
    Future<void>.delayed(const Duration(milliseconds: 2680), () {
      if (!mounted || _skipped) return;
      _sweep.forward(from: 0);
    });
    Future<void>.delayed(const Duration(milliseconds: 4080), () {
      if (!mounted || _skipped) return;
      _sweep.forward(from: 0);
    });
  }

  void _at(int ms, String file, double volume) {
    Future<void>.delayed(Duration(milliseconds: ms), () {
      if (!mounted || _skipped) return;
      unawaited(ZlFx.cue(file, volume: volume));
    });
  }

  @override
  void dispose() {
    _skipped = true;
    _enter.dispose();
    _breath.dispose();
    _gaze.dispose();
    _script.dispose();
    _sweep.dispose();
    _resolveSweep.dispose();
    super.dispose();
  }

  void _enterLadder() {
    _skipped = true;
    _resolveSweep.stop();
    _gaze.stop();
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.5));
    Navigator.of(context).pushReplacement(
      SlmPageRoute<void>(
        builder: (_) => const DutySlipPage(startOnRoad: true),
        style: SlmTransition.fadeThrough,
      ),
    );
  }

  double _lineProgress(int index) {
    // Three windows across the script controller.
    final start = 0.18 + index * 0.24;
    final end = start + 0.18;
    final v = _script.value;
    if (v <= start) return 0;
    if (v >= end) return 1;
    return Curves.easeOutCubic.transform((v - start) / (end - start));
  }

  double _lineSweep(int index, bool reduce) {
    if (reduce || _skipped) return 0;
    final progress = _lineProgress(index);
    // Last resolve line: green light keeps moving until the arrow is tapped.
    if (index == 2 && progress >= 1) return _resolveSweep.value;
    if (progress > 0.55 && progress < 1) return _sweep.value;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final skull = MediaQuery.sizeOf(context).shortestSide * 0.42;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0506),
        body: AnimatedBuilder(
          animation: Listenable.merge([_enter, _breath, _gaze, _script, _sweep, _resolveSweep]),
          builder: (context, _) {
            final fear = Curves.easeOutCubic.transform(_enter.value);
            final pulse = reduce ? 1.0 : 0.72 + 0.28 * _breath.value;
            final gaze = reduce ? 0.5 : _gaze.value;
            if (!reduce && _lineProgress(2) >= 1) _startResolveLoop();
            return Stack(
              fit: StackFit.expand,
              children: [
                // Blood wash in from black.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.12),
                      radius: 1.15,
                      colors: [
                        Color.lerp(const Color(0xFF050208), const Color(0xFF8B1218), fear)!,
                        Color.lerp(const Color(0xFF020104), const Color(0xFF3A070B), fear)!,
                        const Color(0xFF050208),
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
                // Soft vignette.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, 0.1),
                      radius: 1.05,
                      colors: [Color(0x00000000), Color(0x99000000)],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                // Red flare under the skull.
                Align(
                  alignment: const Alignment(0, -0.28),
                  child: Opacity(
                    opacity: fear * pulse,
                    child: Container(
                      width: skull * 1.55,
                      height: skull * 1.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            SlmColors.danger.withValues(alpha: 0.55 * pulse),
                            const Color(0xFFB71C1C).withValues(alpha: 0.22 * pulse),
                            const Color(0x00B71C1C),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: tr(bn, 'ফিরে যান', 'Back'),
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded, color: SlmColors.gold200),
                            ),
                            const Spacer(),
                            HomeToolboxButton(onTap: () => openHomeToolbox(context)),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                      Opacity(
                        opacity: fear,
                        child: Transform.scale(
                          scale: 0.82 + 0.18 * fear,
                          child: _EmeraldSkull(size: skull, breath: pulse, gaze: gaze),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            for (var i = 0; i < _lines.length; i++) ...[
                              if (i > 0) const SizedBox(height: 14),
                              _FearLine(
                                text: _lines[i].$1,
                                color: _lines[i].$2,
                                progress: reduce ? 1 : _lineProgress(i),
                                sweep: _lineSweep(i, reduce),
                                weight: i == 1 ? FontWeight.w800 : FontWeight.w700,
                                size: i == 1 ? 22.0 : 17.0,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      AnimatedOpacity(
                        opacity: _arrowOn || reduce ? 1 : 0,
                        duration: const Duration(milliseconds: 420),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: _GoldArrow(onTap: _arrowOn || reduce ? _enterLadder : null),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FearLine extends StatelessWidget {
  final String text;
  final Color color;
  final double progress;
  final double sweep;
  final FontWeight weight;
  final double size;

  const _FearLine({
    required this.text,
    required this.color,
    required this.progress,
    required this.sweep,
    required this.weight,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final shown = (progress * words.length).ceil().clamp(0, words.length);
    final style = TextStyle(
      fontFamily: banglaFont,
      fontSize: size,
      fontWeight: weight,
      height: 1.35,
      letterSpacing: 0,
      color: color,
      shadows: [
        Shadow(color: color.withValues(alpha: 0.35 * progress), blurRadius: 16),
        const Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 2)),
      ],
    );

    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - progress)),
        child: ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final t = sweep.clamp(0.0, 1.0);
            return LinearGradient(
              begin: Alignment(-1.2 + 2.4 * t, 0),
              end: Alignment(-0.4 + 2.4 * t, 0),
              colors: [
                color,
                Colors.white,
                color,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          child: Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < words.length; i++)
                  TextSpan(
                    text: '${words[i]}${i == words.length - 1 ? '' : ' '}',
                    style: style.copyWith(
                      color: i < shown ? color : color.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _GoldArrow extends StatelessWidget {
  final VoidCallback? onTap;

  const _GoldArrow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'অভিযান',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SlmColors.gold200, SlmColors.gold400, SlmColors.gold600],
            ),
            boxShadow: [
              BoxShadow(
                color: SlmColors.gold400.withValues(alpha: 0.45),
                blurRadius: 18,
              ),
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
            border: Border.all(color: SlmColors.gold100.withValues(alpha: 0.55)),
          ),
          child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A0506), size: 28),
        ),
      ),
    );
  }
}

/// Emerald-standard skull: ivory bone, emerald sockets, thin gold rim.
class _EmeraldSkull extends StatelessWidget {
  final double size;
  final double breath;
  final double gaze;

  const _EmeraldSkull({required this.size, required this.breath, required this.gaze});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmeraldSkullPainter(breath: breath, gaze: gaze),
      ),
    );
  }
}

class _EmeraldSkullPainter extends CustomPainter {
  final double breath;
  final double gaze;

  _EmeraldSkullPainter({required this.breath, required this.gaze});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.42;

    // Outer gold rim.
    final rim = Paint()
      ..shader = ui.Gradient.sweep(
        c,
        [
          SlmColors.gold700,
          SlmColors.gold200,
          SlmColors.gold500,
          SlmColors.gold100,
          SlmColors.gold700,
        ],
        const [0.0, 0.22, 0.5, 0.78, 1.0],
        TileMode.clamp,
        -math.pi / 2,
        math.pi * 1.5,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07;
    canvas.drawCircle(c, r * 1.02, rim);

    // Soft emerald halo inside the rim.
    final halo = Paint()
      ..shader = ui.Gradient.radial(
        c,
        r * 1.08,
        [
          SlmColors.emerald400.withValues(alpha: 0.22 * breath),
          SlmColors.emerald800.withValues(alpha: 0.05),
          const Color(0x00000000),
        ],
        const [0.55, 0.82, 1.0],
      );
    canvas.drawCircle(c, r * 1.08, halo);

    // Cranium.
    final bone = Path()
      ..addOval(Rect.fromCenter(center: c.translate(0, -r * 0.08), width: r * 1.55, height: r * 1.48));
    final jaw = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, r * 0.42), width: r * 0.95, height: r * 0.55),
          Radius.circular(r * 0.18),
        ),
      );
    final skull = Path.combine(PathOperation.union, bone, jaw);

    final boneFill = Paint()
      ..shader = ui.Gradient.linear(
        c.translate(-r, -r),
        c.translate(r, r),
        [
          const Color(0xFFF8F3E7),
          const Color(0xFFE8D9B8),
          const Color(0xFFC9B68A),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawPath(skull, boneFill);

    // Emerald glass sheen over the bone.
    final sheen = Paint()
      ..shader = ui.Gradient.linear(
        c.translate(-r * 0.2, -r),
        c.translate(r * 0.4, r * 0.2),
        [
          SlmColors.emerald200.withValues(alpha: 0.35 * breath),
          const Color(0x00A7F3D0),
          SlmColors.emerald400.withValues(alpha: 0.12),
        ],
        const [0.0, 0.45, 1.0],
      )
      ..blendMode = BlendMode.softLight;
    canvas.drawPath(skull, sheen);

    // Slow gaze: shade and glint drift across both sockets together.
    final lookX = (Curves.easeInOutSine.transform(gaze) - 0.5) * 2;
    final lookY = math.sin(gaze * math.pi) * 0.55;
    final look = Offset(lookX * r * 0.14, lookY * r * 0.09);

    void eye(Offset at) {
      final socketRect = Rect.fromCenter(center: at, width: r * 0.46, height: r * 0.52);
      canvas.save();
      canvas.clipPath(Path()..addOval(socketRect));

      // Dark socket well.
      canvas.drawOval(
        socketRect,
        Paint()
          ..shader = ui.Gradient.radial(
            at,
            r * 0.32,
            const [Color(0xFF02140F), Color(0xFF053D2F), Color(0xFF02140F)],
            const [0.0, 0.55, 1.0],
          ),
      );

      // Moving emerald eyeball shade.
      final shadeCenter = at + look;
      canvas.drawCircle(
        shadeCenter,
        r * 0.20,
        Paint()
          ..shader = ui.Gradient.radial(
            shadeCenter.translate(-r * 0.04, -r * 0.05),
            r * 0.22,
            [
              SlmColors.emerald200.withValues(alpha: 0.95),
              SlmColors.emerald400.withValues(alpha: 0.9 * breath),
              SlmColors.emerald800.withValues(alpha: 0.35),
              const Color(0x0002140F),
            ],
            const [0.0, 0.35, 0.7, 1.0],
          ),
      );

      // Bright glint that rides with the shade.
      final glint = shadeCenter.translate(-r * 0.06, -r * 0.07);
      canvas.drawCircle(
        glint,
        r * 0.055,
        Paint()..color = Colors.white.withValues(alpha: 0.75),
      );
      canvas.drawCircle(
        glint.translate(r * 0.04, r * 0.05),
        r * 0.025,
        Paint()..color = SlmColors.emerald200.withValues(alpha: 0.55 * breath),
      );
      canvas.restore();

      // Soft rim on the socket.
      canvas.drawOval(
        socketRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = SlmColors.gold400.withValues(alpha: 0.35),
      );
    }

    eye(c.translate(-r * 0.32, -r * 0.12));
    eye(c.translate(r * 0.32, -r * 0.12));

    // Nasal cavity.
    final nose = Path()
      ..moveTo(c.dx, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.12, c.dy + r * 0.28)
      ..lineTo(c.dx + r * 0.12, c.dy + r * 0.28)
      ..close();
    canvas.drawPath(
      nose,
      Paint()
        ..shader = ui.Gradient.linear(
          c,
          c.translate(0, r * 0.3),
          [SlmColors.emerald800, const Color(0xFF02140F)],
        ),
    );

    // Teeth marks.
    final tooth = Paint()
      ..color = const Color(0xFF5C4A2E).withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = -2; i <= 2; i++) {
      final x = c.dx + i * r * 0.14;
      canvas.drawLine(Offset(x, c.dy + r * 0.38), Offset(x, c.dy + r * 0.55), tooth);
    }

    // Thin gold edge on the cranium.
    canvas.drawPath(
      skull,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = SlmColors.gold400.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _EmeraldSkullPainter old) => old.breath != breath || old.gaze != gaze;
}
