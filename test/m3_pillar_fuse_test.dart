// Lesson 3.7 (এলটি ফিডার পিলার), কাজ 1 "ফিউজ বদলাও ঠিকঠাক": the rules (full
// PPE before any work in the box, the fuse puller, only the docket's fuse,
// the cause found before the new fuse, only an HRC fuse — a copper strip or a
// thick wire is deadly — the door shut and locked before signing off), the
// deal, the reason libraries, and the level in the shell: idle perf, the
// guide first, a full clean play with the coworker refused, a slip card that
// keeps the pillar, three slips, the deadly freeze (no PPE; listening to him).
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_pillar_fuse.dart';
import 'package:slm_flutter/features/game/m3_pillar_fuse_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '3.7/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

final _pack = m3PillarFusePacks['do_3_7_a']!;
typedef _L = M3PillarFuseLines;
typedef _M = M3PillarFuseMistakes;

/// The new art is not in pubspec yet (the director adds the folder): tests
/// read it from disk when the bundle does not have it.
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

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
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

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3PillarFuseGeo get _geo => M3PillarFuseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M3PillarFusePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// PPE on, the door open, the cause spotted, the blown fuse pulled.
Future<void> _toTray(WidgetTester t, M3PillarFuseRound r) async {
  await _tool(t, _L.ppe);
  await _tapAt(t, _geo.body.center);
  await _tapAt(t, _geo.causeHits(r.cause, r.feeder).first.center);
  await _pump(t, 1800);
  await _tool(t, _L.puller);
  await _tapAt(t, _geo.fuse(r.feeder, r.phase));
}

/// Plays pillar [i] right (the coworker refused on his pillar).
Future<void> _playRight(WidgetTester t, M3PillarFuseDeal deal, int i) async {
  final r = deal.rounds[i];
  await _toTray(t, r);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on pillar $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, _L.coworker.right);
    await _pump(t, 2600);
  }
  expect(await _pumpUntil(t, _label(_L.itemBn(M3PillarFuseItem.hrc)), maxMs: 3000), isTrue, reason: 'the tray on pillar $i');
  await _tool(t, _L.itemBn(M3PillarFuseItem.hrc));
  await _pump(t, 600);
  await _tapAt(t, _geo.openDoorHit.center); // shut
  await _tool(t, _L.lock);
  await _tool(t, _L.signOff);
  await _pump(t, 1200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pillar $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(r));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals: three pillars, three causes, three reasons; he comes once; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m3PillarFuseDeal(math.Random(s));
        expect(d.rounds, hasLength(3));
        expect(d.rounds.map((r) => r.cause).toSet(), hasLength(3));
        expect(d.rounds.map((r) => r.why).toSet(), hasLength(3));
        expect(d.callAt, inInclusiveRange(0, 2));
        for (final r in d.rounds) {
          expect(r.feeder, inInclusiveRange(0, 2));
          expect(r.phase, inInclusiveRange(0, 2));
          expect(r.tray.toSet(), M3PillarFuseItem.values.toSet());
        }
        seen.add(d.rounds.map((r) => '${r.feeder}${r.phase}${r.cause.name}${r.why.name}${r.tray.first.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(60));
    });

    M3PillarFuseRun run1({int feeder = 1, int phase = 2}) => M3PillarFuseRun(M3PillarFuseDeal(rounds: [
          M3PillarFuseRound(id: 'x', feeder: feeder, phase: phase, cause: M3PillarFuseCause.water, why: M3PillarFuseWhy.hrc, tray: M3PillarFuseItem.values),
        ], callAt: 0));

    test('no PPE in the box is deadly (bare hand or puller); the door shut, nothing happens', () {
      final shut = run1();
      expect(shut.tapFuse(1, 2), isNull);
      final bare = run1()..toggleDoor();
      final m = bare.tapFuse(1, 2);
      expect(m, _M.noPpe);
      expect(m!.deadly, isTrue);
      expect(bare.ended, isTrue);
      final tool = run1()
        ..toggleDoor()
        ..holdPuller();
      expect(tool.tapFuse(0, 0), _M.noPpe);
    });

    test('with PPE: a hand is a slip; a healthy fuse is a slip; the docket\'s fuse comes out', () {
      final r = run1()
        ..putPpe()
        ..toggleDoor();
      expect(r.tapFuse(1, 2), _M.noPuller);
      r.holdPuller();
      expect(r.tapFuse(1, 1), _M.wrongFuse);
      expect(r.tapFuse(0, 2), _M.wrongFuse);
      expect(r.slotEmpty, isFalse);
      expect(r.tapFuse(1, 2), isNull);
      expect(r.slotEmpty, isTrue);
      expect(r.trayUp, isTrue);
      expect(r.slips, 3);
      expect(r.caught, containsAll([_L.caughtPpe, _L.caughtFuse]));
    });

    test('the tray: a strip or a wire is deadly; HRC before the cause is a slip; after it, in', () {
      M3PillarFuseRun pulled() => run1()
        ..putPpe()
        ..toggleDoor()
        ..holdPuller()
        ..tapFuse(1, 2);
      final s = pulled();
      expect(s.fit(M3PillarFuseItem.strip), _M.bodgeStrip);
      expect(s.ended, isTrue);
      expect(pulled().fit(M3PillarFuseItem.wire), _M.bodgeWire);
      final h = pulled();
      expect(h.fit(M3PillarFuseItem.hrc), _M.noCause);
      expect(h.fitted, isFalse);
      expect(h.spot(false), isFalse);
      expect(h.spot(true), isTrue);
      expect(h.spot(true), isFalse, reason: 'once');
      expect(h.fit(M3PillarFuseItem.hrc), isNull);
      expect(h.fitted, isTrue);
      expect(h.trayUp, isFalse);
      expect(h.caught, containsAll([_L.caughtCause, _L.caughtHrc]));
    });

    test('sign off: not before the fuse is in; door open and unlocked are slips; locked = done', () {
      final r = run1();
      expect(r.signOff(), isNull);
      expect(r.signedOff, isFalse);
      r
        ..putPpe()
        ..toggleDoor()
        ..spot(true)
        ..holdPuller()
        ..tapFuse(1, 2)
        ..fit(M3PillarFuseItem.hrc);
      expect(r.toggleLock(), isFalse, reason: 'no lock on an open door');
      expect(r.signOff(), _M.doorOpen);
      expect(r.toggleDoor(), isTrue);
      expect(r.signOff(), _M.noLock);
      expect(r.toggleLock(), isTrue);
      expect(r.toggleDoor(), isFalse, reason: 'locked');
      expect(r.signOff(), isNull);
      expect(r.signedOff, isTrue);
      expect(r.caught, contains(_L.caughtLock));
      expect(r.slips, 2);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
    });

    test('English digits only; every mistake has its picture; the deadly ones', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allRight,
        ..._L.myths,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final c in M3PillarFuseCause.values) _L.causeSeen(c),
        for (final m in _M.all) m.textBn,
        _L.allSet,
        _L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly).toSet(), {_M.noPpe, _M.bodgeStrip, _M.bodgeWire});
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('3.7/m3_pillar_fuse/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m3PillarFusePacks.keys, ['do_3_7_a']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      for (final w in M3PillarFuseWhy.values) {
        final r = M3PillarFuseRound(id: 'x', feeder: 0, phase: 0, cause: M3PillarFuseCause.hotspot, why: w, tray: M3PillarFuseItem.values);
        final right = _L.whyRight(r);
        expectLibrary('$w', right, _L.myths);
        expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, _L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = _L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('the scene: no tap zone overlaps another', () {
      final g = _geo;
      final fuses = [
        for (var f = 0; f < 3; f++)
          for (var p = 0; p < 3; p++) g.fuseHit(f, p),
      ];
      for (var i = 0; i < fuses.length; i++) {
        for (var j = i + 1; j < fuses.length; j++) {
          expect(fuses[i].overlaps(fuses[j]), isFalse, reason: '$i/$j');
        }
        expect(fuses[i].overlaps(g.openDoorHit), isFalse);
      }
      for (final c in M3PillarFuseCause.values) {
        for (var f = 0; f < 3; f++) {
          for (final h in g.causeHits(c, f)) {
            expect(g.body.contains(h.center), isTrue);
            expect(fuses.any((x) => x.contains(h.center)), isFalse, reason: '$c F$f');
          }
        }
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3PillarFusePage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m3_pillar_fuse ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3PillarFusePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.puller), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.puller), findsOneWidget);
      expect(find.text(_L.docketBn(m3PillarFuseDeal(math.Random(3)).rounds[0])), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askOpen)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: PPE, cause, the docket\'s fuse, HRC, shut and lock; refuse him; right reasons → pass', (t) async {
      final deal = m3PillarFuseDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.7/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.7/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtCause), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (a hand on the fuse) shows its card; the same pillar goes on after it', (t) async {
      final deal = m3PillarFuseDeal(math.Random(2));
      final r = deal.rounds[0];
      final c = await _open(t, 2);
      await _tool(t, _L.ppe);
      await _tapAt(t, _geo.body.center);
      await _tapAt(t, _geo.fuse(r.feeder, r.phase));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.noPuller.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.puller), findsOneWidget, reason: 'the same pillar');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.noPuller.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final r = m3PillarFuseDeal(math.Random(2)).rounds[0];
      final c = await _open(t, 2);
      await _tool(t, _L.ppe);
      await _tapAt(t, _geo.body.center);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.fuse(r.feeder, r.phase));
        await _pump(t, 600);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('no PPE in the box: the street freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.body.center);
      await _tool(t, _L.puller);
      await _tapAt(t, _geo.fuse(0, 0));
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.noPpe.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = the copper strip: freeze, then the card', (t) async {
      final deal = m3PillarFuseDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _toTray(t, deal.rounds[deal.callAt]);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.bodgeStrip.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
