// m7_report_note (lesson 7.7 কাজ 2 "সৎ রিপোর্ট") at rest: once the accident has
// played and the guide has said the task, the street draws nothing while the
// player thinks — with animations and with reduced motion — at the phone (or
// his deck), at the report sheet, with line A's dial and lens up, with the body
// outline and a zone waiting for its kind, and with the reason deck open.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_report_note.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import '../support/intro_wait.dart';
import '../support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '7.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

typedef L = M7ReportNoteLines;

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  final r = [for (final x in right) if (_label(x).evaluate().isNotEmpty) _label(x)];
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

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

  Future<void> idle(WidgetTester t, String tag) async {
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
    debugPrint('PERF m7_report_note $tag: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
    expect(t.takeException(), isNull);
    expect(perSec, lessThan(20));
    expect(frames, lessThan(12));
  }

  const seed = 7;
  final d = m7ReportDeal(math.Random(seed));
  final geo = M7ReportGeo.forScreen(const Size(392, 850));
  const k = 392 / 360;

  for (final reduce in [false, true]) {
    testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7ReportNotePage(ctx: _ctx, pack: m7ReportNotePacks['do_7_7_b']!, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      final tag = reduce ? 'reduce' : 'anim';
      // The accident, the jump, the call: the phone (and in time his deck).
      expect(await _pumpUntil(t, _key('phone'), maxMs: 20000), isTrue, reason: 'the phone');
      await idle(t, '$tag call');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      // Hold the phone, refuse him, the sheet slides up.
      if (find.byType(CoworkerPeek).evaluate().isEmpty) {
        final g = await t.startGesture(t.getCenter(_key('phone')));
        await _pump(t, 1300);
        await g.up();
        expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      }
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, L.coworkerCall.right);
      expect(await _pumpUntil(t, _key('hud-sheet'), maxMs: 12000), isTrue);
      await idle(t, '$tag sheet');
      // Line A: the dial and the lens up.
      await t.tap(_key('m7-line-when'));
      await _pump(t, 700);
      await t.tapAt(geo.pole(d.acc).center * k);
      await _pump(t, 400);
      expect(_key('m7-lens-tag'), findsOneWidget);
      await idle(t, '$tag dial + lens');
      // Line D: the body outline, a zone waiting for its kind.
      await t.tap(_key('m7-back'));
      await _pump(t, 500);
      await t.tap(_key('m7-line-hurt'));
      await _pump(t, 700);
      await t.tap(_key('m7-zone-handR'), warnIfMissed: false);
      await _pump(t, 300);
      await idle(t, '$tag body');
      // A right line: the reason deck open.
      for (final e in d.injuries.entries) {
        await t.tap(_key('m7-zone-${e.key.name}'), warnIfMissed: false);
        await _pump(t, 200);
        await t.tap(_key('m7-kind-${e.value.name}'), warnIfMissed: false);
        await _pump(t, 200);
      }
      await t.tap(_key('m7-commit'));
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      await idle(t, '$tag reason deck');
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the deck waits for the player');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      t.view.reset();
    });
  }
}
