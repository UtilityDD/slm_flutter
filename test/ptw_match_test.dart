// Lesson 1.6, কাজ 1 (কাগজ মেলাও): permit rules, the phone call, deal variety,
// and the level in the shell (idle perf; a full clean flow).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/ptw_match.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '1.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.6',
  lessonTitleBn: '',
  ladderStep: 17,
  doIndex: 1,
  doCount: 2,
);

final _today = DateTime(2026, 11, 7);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

void main() {
  group('rules', () {
    test('deals: one phone call (never first), one valid form, two with one fault each', () {
      for (var s = 0; s < 60; s++) {
        final r = dealPermits(math.Random(s), _today);
        expect(r.length, 4);
        expect(r.first.phone, isFalse);
        expect(r.where((x) => x.phone).length, 1);
        final forms = [for (final x in r) if (!x.phone) x.form!];
        expect(forms.where((f) => f.fault == PtwFault.none).length, 1);
        expect(forms.where((f) => f.fault != PtwFault.none).map((f) => f.fault).toSet().length, 2);
        for (final x in r.where((x) => !x.phone)) {
          final f = x.form!;
          expect(f.feederBn == x.site.feederBn, f.fault != PtwFault.feeder);
          expect(f.nameBn == x.site.nameBn, f.fault != PtwFault.name);
          expect(f.signed, f.fault != PtwFault.unsigned);
        }
      }
    });

    test('starting: valid is right; wrong feeder / unsigned / expired are deadly; pole or name a slip', () {
      PtwRun runFor(PtwFault f) {
        for (var s = 0; s < 400; s++) {
          final r = dealPermits(math.Random(s), _today);
          final i = r.indexWhere((x) => x.form?.fault == f);
          if (i >= 0) return PtwRun(r)..index = i;
        }
        throw StateError('no $f');
      }

      expect(runFor(PtwFault.none).decide(start: true), isNull);
      for (final f in [PtwFault.feeder, PtwFault.unsigned, PtwFault.expiredDate, PtwFault.expiredTime]) {
        expect(runFor(f).decide(start: true)!.deadly, isTrue, reason: '$f');
      }
      for (final f in [PtwFault.place, PtwFault.name]) {
        final run = runFor(f);
        expect(run.decide(start: true)!.deadly, isFalse);
        expect(run.slips, 1);
      }
    });

    test('stopping: needs the right field; stopping a valid permit is a slip; the phone needs paper', () {
      final r = dealPermits(math.Random(3), _today);
      final bad = r.indexWhere((x) => x.form != null && x.form!.fault != PtwFault.none);
      final a = PtwRun(r)..index = bad;
      expect(a.decide(start: false, flagged: r[bad].form!.fault.field), isNull);
      final b = PtwRun(r)..index = bad;
      final wrong = PtwField.values.firstWhere((f) => f != r[bad].form!.fault.field);
      expect(b.decide(start: false, flagged: wrong), PtwMistakes.wrongField);
      final ok = r.indexWhere((x) => x.form?.fault == PtwFault.none);
      expect((PtwRun(r)..index = ok).decide(start: false, flagged: PtwField.job), PtwMistakes.falseStop);
      final phone = r.indexWhere((x) => x.phone);
      expect((PtwRun(r)..index = phone).answerPhone(held: false), PtwMistakes.verbal);
      expect((PtwRun(r)..index = phone).answerPhone(held: true), isNull);
    });
  });

  group('page', () {
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: PtwMatchPage(ctx: _ctx, pack: ptwPack16, muted: true, seed: 2, today: _today)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
        await _pump(t, 6000);
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
        debugPrint('PERF ptw ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('flow: flag each mismatch, start the valid one, refuse the phone → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 5;
      final rounds = dealPermits(math.Random(seed), _today);
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => PtwMatchPage(ctx: _ctx, pack: ptwPack16, muted: true, seed: seed, today: _today),
      )));
      await _pump(t, 2000);
      await _skipIntro(t);

      for (var i = 0; i < 4; i++) {
        final r = rounds[i];
        if (r.phone) {
          await t.tap(find.text(PtwLines.holdOut));
        } else if (r.form!.fault == PtwFault.none) {
          await t.tap(find.text(PtwLines.start));
        } else {
          final label = PtwLines.labels[r.form!.fault.field]!;
          final row = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);
          await t.ensureVisible(row);
          await t.tap(row, warnIfMissed: false);
          await _pump(t, 200);
          await t.tap(find.text(PtwLines.stop));
        }
        await _pump(t, 900);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i');
        await t.tap(find.text(i == 3 ? PtwLines.finish : PtwLines.next));
        await _pump(t, i == 3 ? 3000 : 700);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.6/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(PtwLines.caughtPhone), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
