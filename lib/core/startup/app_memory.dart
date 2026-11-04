import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Decoded-image cache limits ([ImageCache] keeps finished images that no
/// widget shows any more, so going back is instant).
typedef ImageCacheBudget = ({int bytes, int entries});

const _mb = 1024 * 1024;

/// The heaviest screen (a Duty Slip dress-up level) holds about 13 MB of
/// decoded art; its perf budget is 18 MB (test/perf/duty_games_perf_test.dart).
/// No budget below may go under that, or a screen would re-decode its own art.
const imageCacheFloorBytes = 24 * _mb;

/// Flutter's default: 100 MB / 1000 images, sized for flagship phones.
const ImageCacheBudget flutterDefaultImageCache = (bytes: 100 * _mb, entries: 1000);

/// Budget for a phone with [memTotalKb] of RAM (`MemTotal` in /proc/meminfo).
/// A "4 GB" phone reports about 3.6–3.8 GB, a "3 GB" one about 2.7–2.9 GB.
ImageCacheBudget imageCacheBudgetFor(int? memTotalKb) {
  if (memTotalKb == null || memTotalKb <= 0) return (bytes: 64 * _mb, entries: 400);
  final gb = memTotalKb / (1024 * 1024);
  if (gb < 2.5) return (bytes: 32 * _mb, entries: 200); // 2 GB phones
  if (gb < 4.5) return (bytes: 48 * _mb, entries: 300); // 3–4 GB phones (our users)
  if (gb < 6.5) return (bytes: 72 * _mb, entries: 500);
  return flutterDefaultImageCache;
}

/// Parses `MemTotal:  3809268 kB` out of /proc/meminfo text.
int? parseMemTotalKb(String meminfo) {
  final m = RegExp(r'^MemTotal:\s+(\d+)\s*kB', multiLine: true).firstMatch(meminfo);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// Sizes the image cache for this phone and trims it when the OS reports
/// memory pressure. Install once, right after the binding exists.
class AppMemory with WidgetsBindingObserver {
  AppMemory._();

  static AppMemory? _instance;

  /// Sets a safe Android budget at once, then refines it from /proc/meminfo
  /// off the UI thread. Never awaited, so it adds nothing to the first frame.
  static void install() {
    if (_instance != null) return;
    final memory = _instance = AppMemory._();
    WidgetsBinding.instance.addObserver(memory);
    if (kIsWeb || !Platform.isAndroid) return;
    applyImageCacheBudget(imageCacheBudgetFor(null));
    unawaited(_readMemTotalKb().then((kb) {
      if (!memory._trimmed) applyImageCacheBudget(imageCacheBudgetFor(kb));
    }));
  }

  static Future<int?> _readMemTotalKb() async {
    try {
      return parseMemTotalKb(await File('/proc/meminfo').readAsString());
    } catch (_) {
      return null;
    }
  }

  bool _trimmed = false;

  /// The framework already empties the cache on pressure
  /// (PaintingBinding.handleMemoryPressure); this also halves the budget,
  /// down to [imageCacheFloorBytes], so it does not refill to the old size.
  @override
  void didHaveMemoryPressure() {
    _trimmed = true;
    final cache = PaintingBinding.instance.imageCache;
    int half(int now, int floor) => now <= floor ? now : math.max(floor, now ~/ 2);
    applyImageCacheBudget((
      bytes: half(cache.maximumSizeBytes, imageCacheFloorBytes),
      entries: half(cache.maximumSize, 100),
    ));
    cache.clear();
  }
}

void applyImageCacheBudget(ImageCacheBudget budget) {
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = budget.bytes
    ..maximumSize = budget.entries;
}
