import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game/content_catalog.dart';
import '../../features/guide/mascot_speech_library.dart';
import '../../features/training/training_provider.dart';
import '../../features/zero_loss/zero_loss_fx.dart';
import 'startup_trace.dart';

/// The work the player would otherwise wait for on the first taps, started
/// with the brand splash (≤ 1.5 s on a cold start; `IntroGate`) and running
/// on under Home when it needs longer.
/// Nothing here holds the app: each step has a time limit and swallows its
/// errors, steps run on after the splash if they must, and every
/// step is timed in [StartupTrace.background] as `warm:<name>`.
/// Local work goes first, with a frame's pause between steps so the splash
/// keeps its frames.
///
/// - `catalog`: the ladder's content catalog (170 KB JSON) — the map opens
///   at once.
/// - `lessons`: Module 1's lessons (network, kept on disk for offline) —
///   the lesson reader and the levels' "পাঠে দেখুন" open at once. It waits
///   for Supabase's own start (begun in `bootstrap`).
/// - `voice`: the device TTS engine (language, rate) — the guide's first
///   line is not late.
/// - `sounds`: players for the most used cues — no delay on the first tap.
/// - `art`: the ladder map's coins at the size the map decodes them.
/// [sounds]: false skips the native players (widget tests have none).
Future<void> warmUpDuringIntro(BuildContext context, {bool sounds = true}) async {
  final c = ProviderScope.containerOf(context, listen: false);
  // Precaching needs a live context; take what it needs before any await.
  final images = ImageConfigurationScope(context);

  await _step('catalog', () => c.read(contentCatalogProvider.future));
  await _frame();
  unawaited(_step('lessons', () => c.read(moduleLessonsProvider(1).future), limit: const Duration(seconds: 20)));
  await _step('voice', MascotSpeechLibrary.warmUp);
  await _frame();
  if (sounds) {
    await _step('sounds', () async => SlmSfx.warm(warmCues));
    await _frame();
  }
  await _step('art', images.precacheCoins);
}

/// The cues played most across the app (quiz, cards, levels).
const warmCues = [
  'sounds/quiz_right.ogg',
  'sounds/quiz_wrong.ogg',
  'sounds/quiz_flip.ogg',
  'sounds/quiz_select.ogg',
  'sounds/intro/tick.ogg',
  'sounds/learn/card_deal_a.ogg',
];

/// The ladder map's coins, decoded as the map does (`cacheWidth: 180`).
const warmCoins = [
  'assets/duty_slip/world3d/coin_current_3d.webp',
  'assets/duty_slip/world3d/coin_cleared_3d.webp',
  'assets/duty_slip/world3d/medallion_bronze_3d.webp',
];

Future<void> _step(String name, Future<Object?> Function() work, {Duration limit = const Duration(seconds: 6)}) =>
    StartupTrace.backgroundStep('warm:$name', () async {
      try {
        await work().timeout(limit);
      } catch (_) {
        // Warm-up only: the screen that needs it loads it as before.
      }
    });

Future<void> _frame() => Future<void>.delayed(const Duration(milliseconds: 16));

/// What precaching needs from the context, captured before the awaits.
class ImageConfigurationScope {
  ImageConfigurationScope(BuildContext context) : _context = context;
  final BuildContext _context;

  Future<void> precacheCoins() async {
    if (!_context.mounted) return;
    await Future.wait([
      for (final a in warmCoins) precacheImage(ResizeImage(AssetImage(a), width: 180), _context),
    ]);
  }
}
