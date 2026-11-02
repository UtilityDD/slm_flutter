import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Four depths, each a short run of different plates. A plate overlaps the
/// next through mist, and higher on the path the air gets cooler and paler.
/// The ladder above this stays locked to the checkpoints.
class AdventureWorld extends StatelessWidget {
  final ScrollController scroll;
  final Animation<double> drift;
  final bool motion;

  const AdventureWorld({super.key, required this.scroll, required this.drift, required this.motion});

  static const _bands = <_DepthBand>[
    _DepthBand(
      assets: [
        'assets/duty_slip/world3d/depth_sky_a.webp',
        'assets/duty_slip/world3d/depth_sky_b.webp',
      ],
      factor: 0.10,
      aspect: 16 / 9,
      overlap: 0.42,
      cacheWidth: 720,
    ),
    _DepthBand(
      assets: [
        'assets/duty_slip/world3d/depth_ridge_a.webp',
        'assets/duty_slip/world3d/depth_ridge_b.webp',
        'assets/duty_slip/world3d/depth_ridge_c.webp',
      ],
      factor: 0.22,
      aspect: 4 / 3,
      overlap: 0.40,
      cacheWidth: 780,
    ),
    _DepthBand(
      assets: [
        'assets/duty_slip/world3d/depth_mid_river.webp',
        'assets/duty_slip/world3d/depth_mid_falls.webp',
        'assets/duty_slip/world3d/depth_mid_forest.webp',
      ],
      factor: 0.40,
      aspect: 16 / 9,
      overlap: 0.36,
      cacheWidth: 900,
    ),
    _DepthBand(
      assets: [
        'assets/duty_slip/world3d/depth_near_a.webp',
        'assets/duty_slip/world3d/depth_near_b.webp',
      ],
      factor: 0.65,
      aspect: 16 / 9,
      overlap: 0.28,
      cacheWidth: 800,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scroll, drift]),
      builder: (context, _) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        final phase = motion ? drift.value : 0.35;
        final climb = (offset / (200 * 108)).clamp(0.0, 1.0);
        return LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            if (w <= 0 || h <= 0) return const SizedBox.expand();
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                const ColoredBox(color: Color(0xFFC5D4E4)),
                for (final band in _bands) _DepthStrip(band: band, width: w, height: h, offset: offset),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0x00D5E4F0),
                          Color.fromRGBO(214, 228, 238, 0.08 + 0.34 * climb),
                        ],
                      ),
                    ),
                  ),
                ),
                if (motion) _Motes(phase: phase),
              ],
            );
          },
        );
      },
    );
  }
}

class _DepthBand {
  final List<String> assets;
  final double factor;
  final double aspect;
  final double overlap;
  final int cacheWidth;

  const _DepthBand({
    required this.assets,
    required this.factor,
    required this.aspect,
    required this.overlap,
    required this.cacheWidth,
  });
}

class _DepthStrip extends StatelessWidget {
  final _DepthBand band;
  final double width;
  final double height;
  final double offset;

  const _DepthStrip({required this.band, required this.width, required this.height, required this.offset});

  @override
  Widget build(BuildContext context) {
    final tileH = math.max(height * 0.92, width * band.aspect);
    final step = tileH * (1 - band.overlap);
    if (step <= 0) return const SizedBox.shrink();
    final travel = offset * band.factor;
    final first = (travel / step).floor() - 1;
    final count = (height / step).ceil() + 3;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var n = 0; n < count; n++)
          Positioned(
            left: 0,
            right: 0,
            bottom: (first + n) * step - travel,
            height: tileH,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                stops: [0.0, 0.16, 0.84, 1.0],
              ).createShader(rect),
              child: Image.asset(
                band.assets[_slot(first + n, band.assets.length)],
                fit: BoxFit.cover,
                alignment: Alignment.center,
                cacheWidth: band.cacheWidth,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
          ),
      ],
    );
  }

  static int _slot(int world, int length) {
    final m = world % length;
    return m < 0 ? m + length : m;
  }
}

class _Motes extends StatelessWidget {
  final double phase;

  const _Motes({required this.phase});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MotePainter(phase),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MotePainter extends CustomPainter {
  final double phase;

  const _MotePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x66FFF6D8);
    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.12 + 0.76 * ((i * 0.17) % 1));
      final y = size.height * ((0.15 * i + phase * 0.35) % 1);
      canvas.drawCircle(Offset(x, y), 1.3 + (i % 3) * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter oldDelegate) => oldDelegate.phase != phase;
}

/// Distant sky and ridge silhouettes. The ground itself is painted per band.
class ValleyBackdrop extends StatelessWidget {
  final double scroll;

  const ValleyBackdrop({super.key, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final shift = (scroll * 0.02).clamp(0.0, 36.0);
    return CustomPaint(
      painter: _SkyRidgePainter(shift: shift),
      child: const SizedBox.expand(),
    );
  }
}

class _SkyRidgePainter extends CustomPainter {
  final double shift;

  const _SkyRidgePainter({required this.shift});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07111E), Color(0xFF10243A), Color(0xFF16382C)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0x88202818),
            const Color(0x00000000),
            const Color(0x00000000),
            const Color(0x88202818),
          ],
          stops: const [0.0, 0.22, 0.78, 1.0],
        ).createShader(rect),
    );
    // shift is kept so a scroll still eases the sky, without drawing a wide ridge.
    if (shift > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, shift),
        Paint()..color = const Color(0x2210243A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyRidgePainter oldDelegate) => oldDelegate.shift != shift;
}

/// 3D Wooden Safety Training Pavilion with workbench, PPE, and cones.
class TrainingShed extends StatelessWidget {
  const TrainingShed({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/world3d/training_shed_3d.webp',
      width: 132,
      height: 104,
      cacheWidth: 260,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

/// 3D Double-pole H-frame 11/0.4 kV Distribution Transformer station.
class DtrStation extends StatelessWidget {
  const DtrStation({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/world3d/dtr_station_3d.webp',
      width: 118,
      height: 110,
      cacheWidth: 240,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

/// 3D 33/11 kV outdoor substation yard with gantry, transformer, and breakers.
class SubstationYard extends StatelessWidget {
  const SubstationYard({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/world3d/substation_33kv_3d.webp',
      width: 134,
      height: 106,
      cacheWidth: 260,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

/// 3D 11 kV PCC/Steel distribution pole with crossarm & porcelain insulators.
class Pole3D extends StatelessWidget {
  const Pole3D({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/world3d/pole_11kv_3d.webp',
      width: 72,
      height: 96,
      cacheWidth: 160,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

/// 3D Stylized tree cluster with boulders and ambient occlusion shadow.
class TreeCluster3D extends StatelessWidget {
  final double size;

  const TreeCluster3D({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/world3d/tree_cluster_3d.webp',
      width: size,
      height: size,
      cacheWidth: 190,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

/// 3D Timber-and-stone arched bridge over the stream.
class BridgeArch3D extends StatelessWidget {
  const BridgeArch3D({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/world3d/bridge_arch_3d.webp',
      width: 96,
      height: 68,
      cacheWidth: 210,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}

/// 3D Zero-Death Monument Crest at the top of the visible journey.
class ZeroDeathCrest extends StatelessWidget {
  const ZeroDeathCrest({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/duty_slip/world3d/zero_death_crest_3d.webp',
      width: 82,
      height: 82,
      cacheWidth: 180,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Lineman in the lower-right foreground, watching the valley.
class CornerLineman extends StatelessWidget {
  const CornerLineman({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 126,
        height: 176,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 4,
              child: Container(
                width: 78,
                height: 16,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(78, 16)),
                  color: Color(0xAA061008),
                  boxShadow: [BoxShadow(color: Color(0x88061008), blurRadius: 8, offset: Offset(3, 2))],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 8,
              child: Image(
                image: AssetImage('assets/duty_slip/dress/kit_ready.webp'),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
