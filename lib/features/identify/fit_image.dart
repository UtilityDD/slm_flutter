import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Decode-size helpers so a picture is decoded near the size it is drawn at,
/// not at its file size (some quiz jpgs are 2217x1707, about 15 MB decoded).
///
/// Pixels are rounded up to a 32 px step so small layout changes reuse the
/// same cache entry instead of decoding again.
int decodePx(BuildContext context, double logical) {
  final px = (logical * MediaQuery.devicePixelRatioOf(context)).ceil();
  return math.max(32, ((px + 31) ~/ 32) * 32);
}

/// Physical width of the screen, for pictures that are at most screen-wide.
int screenDecodeWidth(BuildContext context) => decodePx(context, MediaQuery.sizeOf(context).width);

/// An asset decoded to fit inside a [width] x [height] dp box (BoxFit.contain
/// sizing, aspect kept, never upscaled). Null sides are left free.
ImageProvider fitAsset(BuildContext context, String path, {double? width, double? height}) {
  final w = width != null && width.isFinite ? decodePx(context, width) : null;
  final h = height != null && height.isFinite ? decodePx(context, height) : null;
  final asset = AssetImage(path);
  if (w == null && h == null) return asset;
  return ResizeImage(asset, width: w, height: h, policy: ResizeImagePolicy.fit);
}

/// Image.asset that measures its box and decodes to fit it.
class FitAssetImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Alignment alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  const FitAssetImage(
    this.path, {
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final w = constraints.hasBoundedWidth ? constraints.maxWidth : size.width;
        final h = constraints.hasBoundedHeight ? constraints.maxHeight : size.height;
        return Image(
          image: fitAsset(context, path, width: w, height: h),
          width: constraints.hasBoundedWidth ? double.infinity : null,
          height: constraints.hasBoundedHeight ? double.infinity : null,
          fit: fit,
          alignment: alignment,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
