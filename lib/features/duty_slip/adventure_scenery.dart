import 'package:flutter/material.dart';

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
          colors: [Color(0xFF10243A), Color(0xFF2E5870), Color(0xFF6E9460)],
          stops: [0.0, 0.42, 1.0],
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
