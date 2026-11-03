import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Four depths, each a short run of different plates. A plate overlaps the
/// next through mist, and higher on the path the air gets cooler and paler.
/// The ladder above this stays locked to the checkpoints.
class AdventureWorld extends StatefulWidget {
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
  State<AdventureWorld> createState() => _AdventureWorldState();
}

class _AdventureWorldState extends State<AdventureWorld> {
  /// Decoded plates, keyed by asset path. Same providers (and so the same
  /// image-cache entries) as `Image.asset(cacheWidth: …)` used before.
  final _images = <String, ui.Image>{};
  final _streams = <String, (ImageStream, ImageStreamListener)>{};
  final _version = ValueNotifier<int>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_streams.isNotEmpty) return;
    final config = createLocalImageConfiguration(context);
    for (final band in AdventureWorld._bands) {
      for (final asset in band.assets) {
        final provider = ResizeImage.resizeIfNeeded(band.cacheWidth, null, AssetImage(asset));
        final stream = provider.resolve(config);
        final listener = ImageStreamListener((info, _) {
          if (!mounted) {
            info.dispose();
            return;
          }
          _images.remove(asset)?.dispose();
          _images[asset] = info.image.clone();
          info.dispose();
          _version.value++;
        });
        stream.addListener(listener);
        _streams[asset] = (stream, listener);
      }
    }
  }

  @override
  void dispose() {
    for (final (stream, listener) in _streams.values) {
      stream.removeListener(listener);
    }
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _version.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Plates, mist fade and the cool "climb" wash only change when the ladder
    // scrolls: one painter, its own layer, repainted by the scroll alone.
    // The 7 motes are the only thing on the drift clock.
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _DepthPainter(
                bands: AdventureWorld._bands,
                images: _images,
                scroll: widget.scroll,
                repaint: Listenable.merge([widget.scroll, _version]),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          if (widget.motion)
            RepaintBoundary(
              child: CustomPaint(
                painter: _MotePainter(widget.drift),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
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

/// Paints the four depth strips exactly as the old `ShaderMask(dstIn)` tiles
/// did, but only the two faded edges (top and bottom 16 %) of each plate use
/// an offscreen layer; the opaque middle 68 % is a plain image draw.
class _DepthPainter extends CustomPainter {
  final List<_DepthBand> bands;
  final Map<String, ui.Image> images;
  final ScrollController scroll;

  _DepthPainter({required this.bands, required this.images, required this.scroll, required Listenable repaint})
      : super(repaint: repaint);

  static const _fadeTop = 0.16;
  static const _fadeBottom = 0.84;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    final climb = (offset / (200 * 108)).clamp(0.0, 1.0);
    final screen = Offset.zero & size;
    canvas.save();
    canvas.clipRect(screen);
    canvas.drawRect(screen, Paint()..color = const Color(0xFFC5D4E4));
    for (final band in bands) {
      _strip(canvas, band, w, h, offset);
    }
    canvas.drawRect(
      screen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0x00D5E4F0),
            Color.fromRGBO(214, 228, 238, 0.08 + 0.34 * climb),
          ],
        ).createShader(screen),
    );
    canvas.restore();
  }

  void _strip(Canvas canvas, _DepthBand band, double w, double h, double offset) {
    final tileH = math.max(h * 0.92, w * band.aspect);
    final step = tileH * (1 - band.overlap);
    if (step <= 0) return;
    final travel = offset * band.factor;
    final first = (travel / step).floor() - 1;
    final count = (h / step).ceil() + 3;
    for (var n = 0; n < count; n++) {
      final bottom = (first + n) * step - travel;
      final tile = Rect.fromLTWH(0, h - bottom - tileH, w, tileH);
      if (tile.bottom <= 0 || tile.top >= h) continue;
      final image = images[band.assets[_slot(first + n, band.assets.length)]];
      if (image == null) continue;
      _tile(canvas, image, tile);
    }
  }

  void _tile(Canvas canvas, ui.Image image, Rect tile) {
    final topEdge = tile.top + tile.height * _fadeTop;
    final bottomEdge = tile.top + tile.height * _fadeBottom;
    // Opaque middle: straight draw, hard (non-AA) clip so the seams with the
    // faded edges meet on whole pixels.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(tile.left, topEdge, tile.right, bottomEdge), doAntiAlias: false);
    _image(canvas, image, tile);
    canvas.restore();
    // Faded edges: same dstIn mask the ShaderMask applied, over a strip only.
    final mask = Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        stops: [0.0, _fadeTop, _fadeBottom, 1.0],
      ).createShader(tile);
    for (final edge in [
      Rect.fromLTRB(tile.left, tile.top, tile.right, topEdge),
      Rect.fromLTRB(tile.left, bottomEdge, tile.right, tile.bottom),
    ]) {
      canvas.save();
      canvas.clipRect(edge, doAntiAlias: false);
      canvas.saveLayer(edge, Paint());
      _image(canvas, image, tile);
      canvas.drawRect(edge, mask);
      canvas.restore();
      canvas.restore();
    }
  }

  void _image(Canvas canvas, ui.Image image, Rect tile) {
    paintImage(
      canvas: canvas,
      rect: tile,
      image: image,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
    );
  }

  static int _slot(int world, int length) {
    final m = world % length;
    return m < 0 ? m + length : m;
  }

  @override
  bool shouldRepaint(covariant _DepthPainter old) =>
      old.images != images || old.scroll != scroll || old.bands != bands;
}

class _MotePainter extends CustomPainter {
  final Animation<double> drift;

  _MotePainter(this.drift) : super(repaint: drift);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = drift.value;
    final paint = Paint()..color = const Color(0x66FFF6D8);
    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.12 + 0.76 * ((i * 0.17) % 1));
      final y = size.height * ((0.15 * i + phase * 0.35) % 1);
      canvas.drawCircle(Offset(x, y), 1.3 + (i % 3) * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter old) => old.drift != drift;
}
