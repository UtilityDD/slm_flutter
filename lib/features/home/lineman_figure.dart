import 'package:flutter/material.dart';

/// Progressive illustrated looks. Same navy/orange field kit; gear builds by level.
const double _viewW = 3;
const double _viewH = 4;

const _looks = <String>[
  'assets/lineman/lineman_00_start.webp',
  'assets/lineman/lineman_01_trainee.webp',
  'assets/lineman/lineman_02_junior.webp',
  'assets/lineman/lineman_03_tech.webp',
  'assets/lineman/lineman_04_skilled.webp',
  'assets/lineman/lineman_05_advanced.webp',
  'assets/lineman/lineman_06_senior.webp',
  'assets/lineman/lineman_07_supervisor.webp',
  'assets/lineman/lineman_08_specialist.webp',
  'assets/lineman/lineman_09_expert.webp',
  'assets/lineman/lineman_10_pro.webp',
];

String linemanAssetForStep(int step) => _looks[step.clamp(0, _looks.length - 1)];

class LinemanFigure extends StatefulWidget {
  final int step;
  final double glance;
  final bool quiet;
  final bool enableHero;

  const LinemanFigure({
    super.key,
    required this.step,
    this.glance = 0,
    this.quiet = false,
    this.enableHero = true,
  });

  static String heroTagFor(int step) => 'lineman-look-$step';

  @override
  State<LinemanFigure> createState() => _LinemanFigureState();
}

class _LinemanFigureState extends State<LinemanFigure> with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step.clamp(0, 10);
    final lift = step == 0 ? 0.004 : 0.006;
    final asset = linemanAssetForStep(step);
    final glance = widget.glance.clamp(-1.0, 1.0);

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        return Opacity(
          opacity: widget.quiet ? 0.52 : 1,
          child: Transform.translate(
            offset: Offset(glance * 6, 0),
            child: Transform.scale(
              scale: 1 + (lift * _breath.value),
              child: AspectRatio(
                aspectRatio: _viewW / _viewH,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    Widget portrait = Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.person_outline_rounded, size: 64, color: Color(0xFFD6D3D1)),
                      ),
                    );
                    if (widget.enableHero) {
                      portrait = Hero(
                        tag: LinemanFigure.heroTagFor(step),
                        child: Material(type: MaterialType.transparency, child: portrait),
                      );
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: w * 0.22,
                          right: w * 0.22,
                          bottom: h * 0.04,
                          height: h * 0.04,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF000000).withValues(alpha: widget.quiet ? 0.04 : 0.10),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        portrait,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
