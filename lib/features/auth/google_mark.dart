import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../shell/shell_providers.dart';

/// Official four-color Google “G”.
class GoogleMark extends StatelessWidget {
  final double size;

  const GoogleMark({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.46;
    final stroke = size.width * 0.195;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Blue bar first (right arm of the G), then arcs.
    final barH = stroke;
    final barLeft = cx - stroke * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, cy - barH / 2, r + stroke * 0.08, barH),
        Radius.circular(barH * 0.12),
      ),
      Paint()..color = const Color(0xFF4285F4),
    );

    paint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, -math.pi * 0.95, math.pi * 0.55, false, paint);
    paint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, -math.pi * 0.38, math.pi * 0.42, false, paint);
    paint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, math.pi * 0.08, math.pi * 0.48, false, paint);
    paint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, math.pi * 0.58, math.pi * 0.42, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// White Google sign-in control — logo + label, matches brand button layout.
class GoogleSignInButton extends StatelessWidget {
  final bool bn;
  final bool loading;
  final String? error;
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    required this.bn,
    required this.loading,
    required this.error,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = tr(bn, 'Google দিয়ে লগইন', 'Sign in with Google');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlmPressable(
          onTap: onPressed,
          pressedScale: 0.985,
          semanticLabel: label,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDADCE0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF4285F4)),
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 14),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF1F3F4)),
                        ),
                        child: const GoogleMark(size: 18),
                      ),
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bangla(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3C4043),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
          ),
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          SlmText(error!, role: SlmTextRole.bodySm, color: SlmColors.danger, align: TextAlign.center, maxLines: 3),
        ],
      ],
    );
  }
}
