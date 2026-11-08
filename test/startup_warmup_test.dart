// The intro's warm-up: every step runs, is timed, and never throws — even
// with no network/Supabase (the lessons step gives up quietly).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/startup/startup_trace.dart';
import 'package:slm_flutter/core/startup/startup_warmup.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }

  testWidgets('loads the catalog, voice and map art; times every step', (t) async {
    SharedPreferences.setMockInitialValues({});
    StartupTrace.reset();
    late BuildContext ctx;
    final container = ProviderContainer();
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })),
    ));
    await t.runAsync(() => warmUpDuringIntro(ctx, sounds: false));
    final names = StartupTrace.background.map((s) => s.name).toSet();
    expect(names, containsAll(['warm:catalog', 'warm:voice', 'warm:art']));
    expect(container.read(contentCatalogProvider).hasValue, isTrue, reason: 'the ladder catalog is ready');
    for (final a in warmCoins) {
      final key = ResizeImage(AssetImage(a), width: 180);
      final status = PaintingBinding.instance.imageCache.statusForKey(await key.obtainKey(ImageConfiguration.empty));
      expect(status.keepAlive || status.live, isTrue, reason: '$a is in the image cache');
    }
    await t.pumpWidget(const SizedBox());
    container.dispose();
  });
}
