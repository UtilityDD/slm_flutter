// Gate-field Do level (Step 30, Module 1 Rank Gate):
// While the player examines the station and decides, nothing loops —
// with and without "remove animations" — and the idle screen draws zero frames.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/gate_field.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';

var _rebuilds = 0;

const _ctx = LevelContext(
  rungId: 'm1/gate',
  kind: CatalogRungKind.gate,
  lessonId: '1.10',
  lessonTitleBn: 'প্রথম ডকেট · র‍্যাঙ্ক গেট',
  ladderStep: 30,
  doIndex: 0,
  doCount: 0,
);

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
    testWidgets('gate-field waits quietly for decision ($tag)', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      SharedPreferences.setMockInitialValues({});

      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: GateFieldPage(
              ctx: _ctx,
              pack: gateFieldPacks['gate_m1']!,
              muted: true,
              seed: 42,
            ),
          ),
        ),
      );

      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      for (var i = 0; i < 100; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      _rebuilds = 0;
      for (var i = 0; i < 125; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      final perSec = _rebuilds / 2.0;
      expect(
        perSec,
        lessThan(20.0),
        reason: 'idle screen must not rebuild continuously ($tag), had $perSec/s',
      );
    });
  }
}

