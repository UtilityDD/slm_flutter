import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../shell/shell_providers.dart';

/// Official Google “G” mark — four brand colors.
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
    final r = size.width * 0.42;
    final stroke = size.width * 0.18;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.1, 1.5, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -0.55, 1.15, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.65, 1.2, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 1.9, 1.55, false, paint);

    final blue = Paint()..color = const Color(0xFF4285F4);
    final barTop = cy - stroke / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - stroke * 0.15, barTop, r + stroke * 0.35, stroke),
        Radius.circular(stroke * 0.15),
      ),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlmPressable(
          onTap: onPressed,
          semanticLabel: tr(bn, 'গুগল দিয়ে লগইন', 'Sign in with Google'),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDADCE0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF4285F4)),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleMark(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        tr(bn, 'গুগল দিয়ে লগইন', 'Sign in with Google'),
                        style: bangla(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3C4043),
                        ),
                      ),
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
