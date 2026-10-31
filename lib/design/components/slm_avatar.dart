import 'package:flutter/material.dart';

import '../theme/slm_theme.dart';
import '../tokens/slm_colors.dart';
import 'slm_icons.dart';

/// Round profile picture with an initial fallback and an optional medal ring.
class SlmAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  final SlmMedal? medal;

  const SlmAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 40,
    this.medal,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final p = s.palette;
    final d = size * s.layout.scale;
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first);

    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SlmColors.navy600, SlmColors.navy800],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: s.type.title.copyWith(fontSize: d * 0.4, color: p.accent, height: 1),
        ),
      ),
    );

    final src = url?.trim();
    final face = ClipOval(
      child: SizedBox.square(
        dimension: d,
        child: src == null || src.isEmpty
            ? fallback
            : Image.network(
                src,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
              ),
      ),
    );

    final ring = d * 0.06;
    return Semantics(
      label: name,
      image: true,
      child: Container(
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: medal?.gradient,
          color: medal == null ? p.line : null,
          boxShadow: medal == null
              ? null
              : [BoxShadow(color: medal!.glow.withValues(alpha: 0.45), blurRadius: d * 0.3)],
        ),
        child: Container(
          padding: EdgeInsets.all(ring * 0.6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.canvas),
          child: face,
        ),
      ),
    );
  }
}
