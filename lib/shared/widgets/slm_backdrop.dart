import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Cream wash used by Home and the pages that share its chrome.
class SlmBackdrop extends StatelessWidget {
  final Widget child;

  const SlmBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cream, AppColors.creamDeep, Color(0xFFF4F8FF)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -90,
            left: -70,
            child: _Glow(color: Color(0x57FF9A62), size: 240),
          ),
          const Positioned(
            top: -40,
            right: -80,
            child: _Glow(color: Color(0x3D60A5FA), size: 200),
          ),
          const Positioned(
            bottom: 40,
            left: -60,
            child: _Glow(color: Color(0x292DD4BF), size: 180),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
