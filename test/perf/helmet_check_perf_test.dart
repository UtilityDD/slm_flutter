// Step 3's helmet station: the close look (torch on the shell, the inside,
// the chin strap) waits quietly — no loops while nobody touches it, with and
// without "remove animations".
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/helmet_check.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

var _rebuilds = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }
  ZlFx.setMuted(true);
  setUp(() => debugOnRebuildDirtyWidget = (_, _) => _rebuilds++);
  tearDown(() => debugOnRebuildDirtyWidget = null);

  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    testWidgets('helmet close look waits quietly ($tag)', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      final deal = dealHelmets(math.Random(4));
      final checks = <HelmetCheck>{};
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Stack(children: [
                HelmetInspect(
                  item: helmetLine,
                  stampDate: helmetStampDate(helmetLine, deal, DateTime.now()),
                  checks: checks,
                  verdict: null,
                  leaving: false,
                  quiet: reduce,
                  muted: true,
                  onCheck: checks.add,
                  onSay: (_) {},
                  onDecide: (_, _) {},
                  onTapCard: () {},
                  onTapShade: () {},
                  onGone: () {},
                ),
              ]),
            ),
          ),
        ),
      ));

      Future<(double, int)> idle() async {
        for (var i = 0; i < 30; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        _rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = _rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        return (perSec, frames);
      }

      for (final tab in HelmetCheck.values) {
        await t.tap(find.byKey(ValueKey('helmet-tab-${tab.name}')));
        final (perSec, frames) = await idle();
        debugPrint('PERF helmet ${tab.name} $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames in an idle second');
        expect(perSec, lessThan(20), reason: tab.name);
        expect(frames, lessThan(12), reason: tab.name);
      }
      expect(t.takeException(), isNull);

      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 2));
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
