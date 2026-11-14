import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Aggressive “cheap kit” rival — WebP body + light SVG flaps (strap / glove / shirt).
class MythRivalPuppet extends StatelessWidget {
  const MythRivalPuppet({
    super.key,
    required this.size,
    required this.bodyAsset,
    required this.phase,
    this.speaking = false,
    this.reduce = false,
    this.defeated = false,
  });

  final double size;
  final String bodyAsset;

  /// 0..1 looping bob phase.
  final double phase;
  final bool speaking;
  final bool reduce;
  final bool defeated;

  @override
  Widget build(BuildContext context) {
    final t = reduce ? 0.0 : phase;
    final strapSwing = math.sin(t * math.pi * 2) * (speaking ? 0.28 : 0.14);
    final gloveFlap = math.sin(t * math.pi * 2 + 1.2) * (speaking ? 0.22 : 0.10);
    final shirtWave = math.sin(t * math.pi * 2 + 2.1) * 0.08;
    final breath = 1.0 + math.sin(t * math.pi * 2) * 0.012;
    final snarl = speaking ? 1.0 + 0.03 * math.sin(t * math.pi * 6) : 1.0;
    // Decode near display size (the body is 864×1152, ~4 MB at full size):
    // the box height in device pixels, with headroom for the snarl and the
    // learn board's squash-and-stretch. Never upscales past the source.
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final decodeH = (size * 1.22 * dpr * 1.1).round();

    return SizedBox(
      width: size,
      height: size * 1.22,
      child: Transform.scale(
        scale: breath * snarl * (defeated ? 0.92 : 1.0),
        alignment: Alignment.bottomCenter,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              bodyAsset,
              cacheHeight: decodeH,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_off_rounded,
                size: size * 0.55,
                color: const Color(0xFFFF8A80),
              ),
            ),
            // Chin strap hang — pivots from helmet jaw.
            Positioned(
              left: size * 0.42,
              top: size * 0.22,
              width: size * 0.16,
              height: size * 0.22,
              child: Transform.rotate(
                angle: 0.15 + strapSwing,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: defeated ? 0.35 : 0.9,
                  child: SvgPicture.asset(
                    'assets/guide/mascot/rival/chin_strap.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Torn glove flap on the gloved hand.
            Positioned(
              left: size * 0.08,
              top: size * 0.58,
              width: size * 0.20,
              height: size * 0.16,
              child: Transform.rotate(
                angle: -0.25 + gloveFlap,
                alignment: Alignment.topLeft,
                child: Opacity(
                  opacity: 0.85,
                  child: SvgPicture.asset(
                    'assets/guide/mascot/rival/glove_flap.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Loose shirt hem flutter.
            Positioned(
              left: size * 0.28,
              top: size * 0.52,
              width: size * 0.36,
              height: size * 0.16,
              child: Transform.translate(
                offset: Offset(shirtWave * 6, shirtWave.abs() * 3),
                child: Opacity(
                  opacity: 0.55,
                  child: SvgPicture.asset(
                    'assets/guide/mascot/rival/shirt_flutter.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Danger heat shimmer while speaking.
            if (speaking && !reduce && !defeated)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 0.85,
                        colors: [
                          Color.fromRGBO(255, 80, 60, 0.10 + 0.06 * math.sin(t * math.pi * 4).abs()),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
