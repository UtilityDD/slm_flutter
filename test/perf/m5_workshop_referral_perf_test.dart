// Lesson 5.8 কাজ 2 "হাসপাতালের কাগজ" (m5_workshop_referral): an idle screen
// draws zero frames — at a site waiting for the log to be read, and in a
// close-up waiting for a pin (the bushings after the cloth pass), with and
// without reduced motion.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_workshop_referral.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

const _ctx = LevelContext(rungId: '5.8/do/1', kind: CatalogRungKind.doKind, lessonId: '5.8', lessonTitleBn: '', ladderStep: 0, doIndex: 2, doCount: 2);

class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }
  ZlFx.setMuted(true);
  var rebuilds = 0;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpokenOnce.resetForTest();
    debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
  });
  tearDown(() => debugOnRebuildDirtyWidget = null);

  // A play whose first site is a transformer site without the coworker.
  final seed = [for (var s = 0; s < 400; s++) s].firstWhere((s) {
    final d = m5WrDeal(math.Random(s));
    return d.sites[0].kind == M5WrKind.dtr && d.pushSite != 0;
  });
  const k = 392 / 360;
  final geo = M5WrGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

  for (final lens in [false, true]) {
    for (final reduce in [false, true]) {
      testWidgets('do_5_8_b waits quietly ${lens ? 'in the bushing close-up' : 'at the log'} (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(784, 1700);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: DefaultAssetBundle(
            bundle: _DiskBundle(),
            child: MaterialApp(home: M5WorkshopReferralPage(ctx: _ctx, pack: m5WorkshopReferralPacks['do_5_8_b']!, muted: true, seed: seed)),
          ),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        await _pump(t, 1200);
        if (lens) {
          await t.tapAt(geo.logHit.center * k);
          await _pump(t, 300);
          await t.tap(_label(M5WrLines.logOk));
          await _pump(t, 400);
          await t.tap(_label(M5WrLines.workshop));
          await _pump(t, 400);
          await t.longPressAt(geo.testerHit.center * k);
          await _pump(t, 300);
          await t.tapAt(geo.stationHit(M5WrStation.bushing).center * k);
          await _pump(t, 400);
          final r = t.getRect(find.byKey(const ValueKey('lens-bushing-0')));
          final g = await t.startGesture(r.centerLeft + const Offset(6, 0));
          for (var i = 0; i < 8; i++) {
            await g.moveBy(const Offset(28, 0));
            await t.pump(const Duration(milliseconds: 16));
          }
          await g.up();
          expect(find.byKey(const ValueKey('lens-bushing')), findsOneWidget);
        }
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF m5_workshop_referral ${lens ? 'lens' : 'log'} ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }
  }
}
