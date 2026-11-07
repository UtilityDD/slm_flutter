import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'guide_director.dart';

/// Mouth-only SVG overlay on the coach WebP bust.
/// Brows stay on the WebP (no second SVG pair → no double eyebrows).
class MascotFaceRig extends StatelessWidget {
  final double sprite;
  final GuideMood mood;
  final double open;
  final double width;
  final double round;
  final double smile;
  final double talkBlend;
  final bool reduce;
  final bool speaking;

  /// Image fill aspect inside the square sprite (matches coach WebP).
  static const imageAspect = 597 / 888;

  const MascotFaceRig({
    super.key,
    required this.sprite,
    required this.mood,
    required this.open,
    required this.width,
    required this.round,
    required this.smile,
    required this.talkBlend,
    required this.reduce,
    required this.speaking,
  });

  bool get _warn =>
      mood == GuideMood.warn || mood == GuideMood.fright || mood == GuideMood.fallen;

  String get _mouthAsset {
    if (talkBlend < 0.04 || open < 0.08) {
      return open < 0.05 && talkBlend > 0.2
          ? 'assets/guide/mascot/mouth_mbp.svg'
          : 'assets/guide/mascot/mouth_rest.svg';
    }
    if (round > 0.55 && open > 0.35) return 'assets/guide/mascot/mouth_o.svg';
    if (width > 0.98 && open > 0.28) return 'assets/guide/mascot/mouth_ee.svg';
    if (open > 0.55) return 'assets/guide/mascot/mouth_aa.svg';
    if (open > 0.18) return 'assets/guide/mascot/mouth_ee.svg';
    return 'assets/guide/mascot/mouth_rest.svg';
  }

  @override
  Widget build(BuildContext context) {
    if (mood == GuideMood.sleep || _warn) return const SizedBox.shrink();
    if (talkBlend < 0.03) return const SizedBox.shrink();

    final imageW = sprite * imageAspect;
    final left = (sprite - imageW) / 2;
    final mouthScaleY = (0.72 + open * 0.55).clamp(0.7, 1.35);
    final mouthScaleX =
        (0.88 + (width - 0.9) * 0.45 + smile.abs() * 0.06).clamp(0.75, 1.15);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // Soft skin patch so WebP lips don't fight the SVG viseme.
        Positioned(
          left: left + imageW * 0.418,
          top: sprite * 0.422,
          width: imageW * 0.230,
          height: sprite * 0.110,
          child: IgnorePointer(
            child: Opacity(
              opacity: (talkBlend * 0.95).clamp(0.0, 0.95),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sprite * 0.04),
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFD08A57),
                      Color(0xCCD08A57),
                      Color(0x00D08A57),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: left + imageW * 0.428,
          top: sprite * 0.430,
          width: imageW * 0.210,
          height: sprite * 0.095,
          child: IgnorePointer(
            child: Opacity(
              opacity: talkBlend.clamp(0.0, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(mouthScaleX, mouthScaleY, 1),
                // Visemes swap instantly. A cross-fade (AnimatedSwitcher keyed by
                // asset) threw "Duplicate keys" when speech went ee → o → ee
                // faster than the fade, with the old ee still fading out.
                child: SvgPicture.asset(
                  _mouthAsset,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
