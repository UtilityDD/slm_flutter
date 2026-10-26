import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

String resolveTrainingMediaSrc(String mediaRef) {
  final s = mediaRef.trim();
  if (s.isEmpty) return '';
  if (RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(s)) {
    if (s.contains('drive.google.com')) {
      final match = RegExp(r'/d/(.+?)/|id=(.+?)(&|$)').firstMatch(s);
      final id = match?.group(1) ?? match?.group(2) ?? '';
      if (id.isNotEmpty) {
        final day = DateTime.now().toIso8601String().split('T').first;
        return 'https://lh3.googleusercontent.com/u/0/d/$id?v=$day';
      }
    }
    return s;
  }
  if (s.startsWith('/')) return '${AppConfig.websiteUrl}$s';
  if (s.startsWith('images/')) return '${AppConfig.websiteUrl}/$s';
  return '${AppConfig.websiteUrl}/quizzes/${s.replaceFirst(RegExp(r'^/'), '')}';
}

bool trainingMediaLooksLikeImage(String mediaRef) {
  final path = mediaRef.trim().split(RegExp(r'[?#]')).first;
  if (RegExp(r'\.(jpg|jpeg|png|webp|gif|svg)$', caseSensitive: false).hasMatch(path)) return true;
  if (mediaRef.contains('drive.google.com')) return true;
  if (mediaRef.contains('googleusercontent.com') || mediaRef.contains('ggpht.com')) return true;
  return false;
}

/// Full-visible textbook plate — no crop; letterboxes on warm paper.
class LessonFigurePlate extends StatelessWidget {
  final String imageUrl;
  final Color paperColor;
  final VoidCallback? onTap;
  final double maxHeightFraction;

  const LessonFigurePlate({
    super.key,
    required this.imageUrl,
    this.paperColor = const Color(0xFFF5E6D8),
    this.onTap,
    this.maxHeightFraction = 0.42,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * maxHeightFraction;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: paperColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              alignment: Alignment.center,
              placeholder: (_, __) => SizedBox(
                height: maxH * 0.45,
                width: double.infinity,
                child: ColoredBox(color: paperColor),
              ),
              errorWidget: (_, __, ___) => SizedBox(
                height: 120,
                width: double.infinity,
                child: ColoredBox(
                  color: paperColor,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders lesson text with web `((ref|label))` chips and `[[image|caption]]` figures.
class LessonRichText extends StatelessWidget {
  final String text;
  final bool bn;
  final TextStyle? style;
  final void Function(String url, String caption)? onOpenImage;
  final void Function(String body)? onOpenNote;

  const LessonRichText({
    super.key,
    required this.text,
    required this.bn,
    this.style,
    this.onOpenImage,
    this.onOpenNote,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ??
        const TextStyle(fontSize: 17, height: 1.55, fontWeight: FontWeight.w500, color: AppColors.ink);
    final parts = text.split(RegExp(r'(\(\(.*?\)\)|\[\[.*?\]\])'));
    final children = <InlineSpan>[];
    final below = <Widget>[];

    for (final part in parts) {
      if (part.startsWith('((') && part.endsWith('))')) {
        final raw = part.substring(2, part.length - 2);
        final pipe = raw.indexOf('|');
        final mediaPart = (pipe >= 0 ? raw.substring(0, pipe) : raw).trim();
        final authorLabel = pipe >= 0 ? raw.substring(pipe + 1).trim() : '';
        final resolved = resolveTrainingMediaSrc(mediaPart);
        final isImage = trainingMediaLooksLikeImage(mediaPart);
        final label = authorLabel.isNotEmpty
            ? authorLabel
            : (isImage ? (bn ? 'ছবি' : 'Photo') : (bn ? 'আরও' : 'More'));
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Material(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(99),
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () {
                    if (isImage && resolved.isNotEmpty) {
                      onOpenImage?.call(resolved, label);
                    } else {
                      onOpenNote?.call(raw);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isImage ? Icons.image_outlined : Icons.info_outline_rounded, size: 15, color: const Color(0xFFC2410C)),
                        const SizedBox(width: 5),
                        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9A3412))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (part.startsWith('[[') && part.endsWith(']]')) {
        final inner = part.substring(2, part.length - 2).trim();
        final segments = inner.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (segments.isEmpty) continue;
        final imgPath = segments.first;
        final captionParts = segments.skip(1).where((s) => s.toLowerCase() != 'inline').toList();
        final caption = captionParts.join(' | ');
        final src = resolveTrainingMediaSrc(imgPath);
        below.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: LessonFigurePlate(
              imageUrl: src,
              paperColor: const Color(0xFFF5E6D8),
              onTap: () => onOpenImage?.call(src, caption),
            ),
          ),
        );
        if (caption.isNotEmpty) {
          below.add(Text(caption, style: const TextStyle(fontSize: 13, color: AppColors.muted)));
        }
      } else if (part.isNotEmpty) {
        children.add(TextSpan(text: part, style: base));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: children), style: base),
        ...below,
      ],
    );
  }
}
