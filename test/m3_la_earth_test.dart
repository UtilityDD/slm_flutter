// Lesson 3.5 কাজ 2 (কবচের মাটি): the rules (the hanging lead marks the bad
// LA; tag both earth-path faults; listening to "a little cut is fine" is a
// slip; the repair: docket → test → earth → work, harness before work up the
// pole), the deadly move (hands on the LA before the shutdown), the deal, the
// option libraries, and the level in the shell: idle perf, the guide first,
// tap-the-guide, a full clean play to the pass, a slip card, the deadly
// freeze and the coworker.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_la_earth.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _rung = '3.5/do/2';
final _pack = m3LaEarthPacks['do_3_5_b']!;
typedef L = M3LaEarthLines;
typedef M = M3LaEarthMistakes;
typedef I = M3LaEarthIds;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_la_earth/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(b.buffer);
    }
    return rootBundle.load(key);
  }
}

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.doKind,
      lessonId: '3.5',
      lessonTitleBn: '',
      ladderStep: 1,
      doIndex: 2,
      doCount: 2,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

Future<void> _tap(WidgetTester t, String label, {int ms = 900}) async {
  await t.tap(_label(label), warnIfMissed: false);
  await _pump(t, ms);
}

M3LaEarthDeal _deal(int seed) => m3LaEarthDealFor(math.Random(seed));

/// A run past the LA and the earth path.
M3LaEarthRun _atRepair(M3LaEarthDeal d) {
  final r = M3LaEarthRun(d)..pickLa(d.badLa);
  for (final s in d.faults.keys) {
    r.look(s);
  }
  return r;
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M3LaEarthPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// The bad LA, its reason; then the coworker is due on the earth path.
Future<void> _laDone(WidgetTester t, int seed) async {
  await _tap(t, L.laLabel(_deal(seed).badLa), ms: 2200);
  expect(find.text(L.laAsk), findsWidgets);
  await _pickRight(t, L.laRight);
  await _pump(t, 2600);
}

/// Refuse him, tag both faults, the reason.
Future<void> _pathDone(WidgetTester t, int seed) async {
  await _pump(t, 2000);
  expect(find.byType(CoworkerPeek), findsOneWidget);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2500);
  final d = _deal(seed);
  await _tap(t, L.spotLabel(d.loose));
  await _tap(t, L.spotLabel(d.cut), ms: 2200);
  expect(find.text(L.pathAsk), findsWidgets);
  await _pickRight(t, L.pathRight);
  await _pump(t, 3000);
}

void main() {
  group('rules', () {
    test('round 1: the LA with the hanging lead; a healthy one is a slip (look again)', () {
      final d = _deal(3);
      final r = M3LaEarthRun(d);
      expect(r.stage, 0);
      expect(r.look(d.cut), isNull, reason: 'not the time');
      expect(r.tap(I.docket).kind, OrderTapKind.ignored);
      final other = (d.badLa + 1) % 3;
      expect(r.pickLa(other), M.wrongLa);
      expect(r.slips, 1);
      expect(r.stage, 0);
      expect(r.pickLa(d.badLa), isNull);
      expect(r.stage, 1);
    });

    test('round 2: both faults tagged; a healthy spot costs nothing; listening is a slip', () {
      final d = _deal(5);
      final r = M3LaEarthRun(d)..pickLa(d.badLa);
      final healthy = d.spots.where((s) => !d.faults.containsKey(s)).toList();
      expect(healthy, hasLength(3));
      expect(d.spots, isNot(contains(m3LaEarthJoint(d.badLa))));
      for (final s in healthy) {
        expect(r.look(s), isNull);
      }
      expect(r.slips, 0);
      expect(r.look(d.cut), M3LaEarthFault.cut);
      expect(r.look(d.cut), isNull, reason: 'already tagged');
      expect(r.stage, 1);
      expect(r.listened(), M.smallCut);
      expect(r.slips, 1);
      expect(r.ended, isFalse, reason: 'equipment damage, not deadly');
      expect(r.look(d.loose), M3LaEarthFault.loose);
      expect(r.stage, 2);
    });

    test('round 3: a clean repair — docket → test → earth → harness → LA and mends in any order', () {
      final d = _deal(8);
      final r = _atRepair(d);
      for (final id in [I.docket, I.test, I.earth]) {
        expect(r.tap(id).kind, OrderTapKind.ok, reason: id);
      }
      r.wearHarness();
      final work = [for (final s in d.faults.keys) I.mend(s), I.replace];
      for (final id in work.take(work.length - 1)) {
        expect(r.tap(id).kind, OrderTapKind.ok, reason: id);
      }
      final last = r.tap(work.last);
      expect(last.allDone, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.stage, 3);
    });

    test('deadly: hands on the LA before the shutdown (with or without the harness)', () {
      for (final harness in [false, true]) {
        final d = _deal(2);
        final r = _atRepair(d);
        if (harness) r.wearHarness();
        expect(r.tap(I.replace).mistake, M.liveLa);
        expect(r.ended, isTrue);
      }
      expect(M.all.where((m) => m.deadly), [M.liveLa]);
    });

    test('slips: test or earth before the docket, earth before the test, work before the earth, no harness up the pole', () {
      final d = _deal(11);
      final r = _atRepair(d);
      expect(r.tap(I.test).mistake, M.noShutdown);
      expect(r.tap(I.earth).mistake, M.noShutdown);
      expect(r.tap(I.mend(d.cut)).mistake, M.noShutdown, reason: 'a mend early is a slip, not deadly');
      r.tap(I.docket);
      expect(r.tap(I.earth).mistake, M.noTest);
      expect(r.tap(I.replace).mistake, M.noTest, reason: 'after the shutdown: a slip');
      r.tap(I.test);
      expect(r.tap(I.replace).mistake, M.noEarth);
      r.tap(I.earth);
      expect(r.tap(I.replace).mistake, M.noHarness);
      expect(r.tap(I.mend(d.cut)).mistake, M.noHarness);
      expect(r.deadly, isNull);
      expect(r.slips, 8);
      expect(r.passed, isFalse);
      // The rod clamp is mended at the ground: no harness needed.
      final g = M3LaEarthRun(const M3LaEarthDeal(badLa: 0, loose: M3LaEarthSpot.rodClamp, cut: M3LaEarthSpot.leadLower))
        ..pickLa(0)
        ..look(M3LaEarthSpot.rodClamp)
        ..look(M3LaEarthSpot.leadLower);
      for (final id in [I.docket, I.test, I.earth]) {
        g.tap(id);
      }
      expect(g.tap(I.mend(M3LaEarthSpot.rodClamp)).kind, OrderTapKind.ok);
    });

    test('mistakes: pictures exist, keys unique and under the lesson, lesson points', () {
      for (final m in M.all) {
        expect(m.art, startsWith('assets/game/art/m3_la_earth/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('3.5/m3_la_earth/'));
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(M.wrongLa.lessonPoint, 2);
      expect(M.all.map((m) => m.key).toSet(), hasLength(M.all.length));
    });

    test('deal: any LA, one loose joint and one cut piece, never on the bad LA; fresh across plays', () {
      final bads = <int>{};
      final looses = <M3LaEarthSpot>{};
      final cuts = <M3LaEarthSpot>{};
      for (var s = 0; s < 60; s++) {
        final d = _deal(s);
        bads.add(d.badLa);
        looses.add(d.loose);
        cuts.add(d.cut);
        expect(d.loose, isNot(m3LaEarthJoint(d.badLa)));
        expect(d.spots, containsAll(d.faults.keys));
        expect(d.spots, hasLength(5));
      }
      expect(bads, hasLength(3));
      expect(looses, hasLength(4));
      expect(cuts, hasLength(2));
    });

    test('reasons and the coworker\'s deck: same length, big enough, one right per deal', () {
      final libs = {
        'la': (L.laRight, L.laWrong),
        'path': (L.pathRight, L.pathWrong),
        'fix': (L.fixRight, L.fixWrong),
        'coworker': (L.coworker.right, L.coworker.wrong),
      };
      for (final MapEntry(key: name, value: (right, wrong)) in libs.entries) {
        expectSameLength(name, [...right, ...wrong]);
        expectLibrary(name, right, wrong);
        for (var s = 0; s < 12; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.coworker.line, L.coworkerLine);
      expect(L.coworker.recordedLines, contains('হুঁ! যা খুশি করুন।'));
    });

    test('English digits only; the words of the house', () {
      final all = <String>[
        ...L.guideLines,
        ...L.laRight, ...L.laWrong, ...L.pathRight, ...L.pathWrong, ...L.fixRight, ...L.fixWrong, //
        L.coworker.line, ...L.coworker.right, ...L.coworker.wrong, ...L.coworker.asks,
        for (final m in M.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l, isNot(contains('পানি')), reason: l);
      }
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
          child: MaterialApp(home: M3LaEarthPage(ctx: _ctx(), pack: _pack, muted: true, seed: 4)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
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
        debugPrint('PERF m3_la_earth ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the three LAs are in reach', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: M3LaEarthPage(ctx: _ctx(), pack: _pack, muted: true, seed: 3)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      for (var i = 0; i < 3; i++) {
        expect(_label(L.laLabel(i)), findsOneWidget);
      }
      expect(_label(L.testerLabel), findsNothing, reason: 'the kit waits for the repair');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askLa)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: the bad LA, refuse him, tag both faults, docket → test → earth → harness → work → pass', (t) async {
      const seed = 11;
      final d = _deal(seed);
      final c = await _open(t, seed);
      await _laDone(t, seed);
      await _pathDone(t, seed);
      await _tap(t, L.docketLabel);
      await _tap(t, L.testerLabel);
      await _tap(t, L.earthSetLabel);
      await _tap(t, L.harnessLabel);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _tap(t, L.spotLabel(d.loose));
      await _tap(t, L.spotLabel(d.cut));
      await _tap(t, L.laLabel(d.badLa), ms: 2200);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.text(L.fixAsk), findsWidgets);
      await _pickRight(t, L.fixRight);
      await _pump(t, 5000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtCall), findsOneWidget);
      expect(find.text(L.caughtSafe), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a healthy LA: a slip with its card, no freeze; then the bad one', (t) async {
      const seed = 7;
      final c = await _open(t, seed);
      final bad = _deal(seed).badLa;
      await _tap(t, L.laLabel((bad + 1) % 3), ms: 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M.wrongLa.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsNothing);
      await _tap(t, L.laLabel(bad), ms: 2200);
      expect(find.text(L.laAsk), findsWidgets);
      await _close(t, c);
    });

    testWidgets('hands on the LA before the shutdown: frozen first, then the deadly card', (t) async {
      const seed = 2;
      final c = await _open(t, seed);
      await _laDone(t, seed);
      await _pathDone(t, seed);
      await _tap(t, L.laLabel(_deal(seed).badLa), ms: 600);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('zap')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M.liveLa.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the coworker: once, on the earth path; the last fault waits for him; listening is a slip', (t) async {
      const seed = 9;
      final d = _deal(seed);
      final c = await _open(t, seed);
      await _laDone(t, seed);
      // Both faults tapped at once: the last one waits for him.
      await _tap(t, L.spotLabel(d.loose), ms: 300);
      await _tap(t, L.spotLabel(d.cut), ms: 300);
      expect(find.text(L.pathAsk), findsNothing);
      await _pump(t, 2000);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(L.coworkerLine), findsOneWidget);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M.smallCut.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 900);
      await _tap(t, L.spotLabel(d.cut), ms: 2200);
      expect(find.text(L.pathAsk), findsWidgets);
      await _close(t, c);
    });
  });
}
