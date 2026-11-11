// Lesson 4.9 (রাস্তার আলো মেরামত), কাজ 2 "আলো ফেরাও": the rules (THIS
// light's MCB off, the ladder on the safe spot and tied, the harness on;
// the tester before any touch; the loose terminal tightened before a part;
// the part that matches the gear; the old lamp to the scrap crate; a hand
// inside a live fixture = deadly), the deal, the reason libraries, and the
// level in the shell: idle perf, the guide first, a full clean play with the
// coworker refused, a slip card that keeps the job, the deadly freeze (a
// hand inside untested and live; listening to him), "no tester" at the top.
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
import 'package:slm_flutter/features/game/m4_streetlight_fix.dart';
import 'package:slm_flutter/features/game/m4_streetlight_fix_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

typedef _L = M4StreetlightFixLines;
typedef _M = M4StreetlightFixMistakes;

const _ctx = LevelContext(
  rungId: '4.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '4.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m4StreetlightFixPacks['do_4_9_b']!;

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
M4StreetlightFixGeo get _geo => M4StreetlightFixGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

/// A terminal in the open luminaire (the close-up card).
Future<void> _terminal(WidgetTester t, int i) async {
  final f = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is M4StreetlightFixInsidePainter);
  expect(f, findsOneWidget);
  final size = t.getSize(f);
  await t.tapAt(t.getTopLeft(f) + M4StreetlightFixInsideGeo.terminal(i, size));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4StreetlightFixPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

M4StreetlightFixDeal _deal(int seed) => m4StreetlightFixDeal(math.Random(seed));

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

/// The footpath: harness (he comes: refuse him), MCB off, ladder on the good
/// spot, rope; climb; the reason.
Future<void> _base(WidgetTester t, M4StreetlightFixDeal d) async {
  await _tool(t, _L.harness);
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes as the work starts');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, _L.coworker.right);
  await _pump(t, 2600);
  await _tapAt(t, _geo.mcb(d.mineSlot).center);
  await _tool(t, _L.ladder);
  await _tapAt(t, _geo.spotHit(d.goodSide).center);
  await _tool(t, _L.rope);
  await _tapAt(t, _geo.ladderHit(d.goodSide).center);
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await _reason(t, d.whyBase == M4StreetlightFixWhyBase.isolate ? _L.isolateWhy : (d.badKind == M4StreetlightFixBadSpot.line ? _L.spotLineWhy : _L.spotSlabWhy));
}

List<String> _partWhy(M4StreetlightFixDeal d) => switch (d.fault) {
      M4StreetlightFixFault.hpsvCycling => _L.partHpsvWhy,
      M4StreetlightFixFault.mhDark => _L.partMhWhy,
      M4StreetlightFixFault.ledDark => _L.partLedWhy,
    };

/// The top: tester 0 V, tighten the loose terminal, the right part; reason.
Future<void> _top(WidgetTester t, M4StreetlightFixDeal d) async {
  await _tool(t, _L.tester);
  expect(find.text(_L.testerDead), findsOneWidget);
  await _tool(t, _L.driver);
  await _terminal(t, d.loose);
  await _tool(t, _L.partBn(d.rightPart));
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await _reason(t, _partWhy(d));
}

/// Down: the old lamp to the crate, the MCB on; the light; reason.
Future<void> _down(WidgetTester t, M4StreetlightFixDeal d) async {
  await _tool(t, _L.down);
  if (d.oldLamp) await _tapAt(t, _geo.crate.center);
  await _tapAt(t, _geo.mcb(d.mineSlot).center);
  expect(find.text(_L.stampOn), findsOneWidget);
  await _reason(t, d.oldLamp ? _L.disposeWhy : _L.testWhy);
}

void main() {
  group('rules', () {
    test('deals: one light, the right part fits the gear, the bad spot varies, plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 120; s++) {
        final d = _deal(s);
        expect(d.parts.toSet(), hasLength(4));
        expect(d.mineSlot, inInclusiveRange(0, 1));
        expect((d.poleNo - d.otherNo).abs(), 1);
        if (d.badKind == M4StreetlightFixBadSpot.line) expect(d.badSide, M4StreetlightFixSide.left, reason: 'the LT line is on the left');
        expect(d.oldLamp, d.fault != M4StreetlightFixFault.ledDark);
        seen.add('${d.fault.name}${d.parts.map((p) => p.index).join()}${d.poleNo}${d.mineSlot}${d.badSide.name}${d.badKind.name}${d.loose}${d.whyBase.name}');
      }
      expect(seen.length, greaterThan(100));
      expect({for (var s = 0; s < 120; s++) _deal(s).fault}, hasLength(3));
      expect({for (var s = 0; s < 120; s++) '${_deal(s).badSide}${_deal(s).badKind}'}, hasLength(3));
    });

    M4StreetlightFixDeal fixed({M4StreetlightFixFault fault = M4StreetlightFixFault.hpsvCycling, M4StreetlightFixBadSpot kind = M4StreetlightFixBadSpot.line}) =>
        M4StreetlightFixDeal(
          fault: fault,
          parts: M4StreetlightFixPart.values,
          poleNo: 12,
          otherNo: 13,
          mineSlot: 0,
          badSide: M4StreetlightFixSide.left,
          badKind: kind,
          loose: 1,
          whyBase: M4StreetlightFixWhyBase.isolate,
        );

    M4StreetlightFixRun atTop({M4StreetlightFixFault fault = M4StreetlightFixFault.hpsvCycling, bool isolate = true}) {
      final r = M4StreetlightFixRun(fixed(fault: fault));
      if (isolate) r.toggleMcb(0);
      r
        ..hold(M4StreetlightFixTool.ladder)
        ..placeLadder(M4StreetlightFixSide.right)
        ..tie()
        ..wearHarness();
      expect(r.climb(), isNull);
      r.toTop();
      return r;
    }

    test('the ladder: the bad spot is a slip (by the line / a broken slab); untied or no harness: no climbing', () {
      final a = M4StreetlightFixRun(fixed())..hold(M4StreetlightFixTool.ladder);
      expect(a.placeLadder(M4StreetlightFixSide.left), _M.spotLine);
      expect(a.ladder, isNull);
      final b = M4StreetlightFixRun(fixed(kind: M4StreetlightFixBadSpot.slab))..hold(M4StreetlightFixTool.ladder);
      expect(b.placeLadder(M4StreetlightFixSide.left), _M.spotSlab);
      expect(b.placeLadder(M4StreetlightFixSide.right), isNull);
      expect(b.climb(), _M.noTie);
      expect(b.tie(), isTrue);
      expect(b.climb(), _M.noHarness);
      b.wearHarness();
      expect(b.climb(), isNull);
      expect(b.up, isTrue);
      expect(b.isolatedAtClimb, isFalse);
      expect(b.whyBase, M4StreetlightFixWhyBase.spot, reason: 'the isolate reason only if he isolated');
      expect(b.toggleMcb(0), isFalse, reason: 'the pillar is out of reach from the ladder');
      expect(b.slips, 3);
    });

    test('a hand inside a live fixture is deadly — untested, or after a LIVE reading', () {
      final a = atTop(isolate: false)..hold(M4StreetlightFixTool.driver);
      final m = a.tighten(1);
      expect(m, _M.touchLive);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = atTop(isolate: false);
      expect(b.test(), isTrue);
      expect(b.fit(M4StreetlightFixPart.hpsv70), _M.touchLive);
    });

    test('the wrong MCB: the tester shows LIVE; down, the right one off, up, 0 V', () {
      final r = M4StreetlightFixRun(fixed())..toggleMcb(1);
      expect(r.otherOn, isFalse);
      r
        ..hold(M4StreetlightFixTool.ladder)
        ..placeLadder(M4StreetlightFixSide.right)
        ..tie()
        ..wearHarness()
        ..climb()
        ..toTop();
      expect(r.test(), isTrue);
      r.descend();
      expect(r.station, M4StreetlightFixStation.top);
      expect(r.toggleMcb(0), isTrue);
      expect(r.climb(), isNull);
      expect(r.test(), isFalse);
      expect(r.proved, isTrue);
      expect(r.caught, containsAll([_L.caughtProve, _L.caughtLive]));
      expect(r.slips, 0);
    });

    test('dead but untested is a slip; a part before tightening is a slip; the wrong parts', () {
      final r = atTop()..hold(M4StreetlightFixTool.driver);
      expect(r.tighten(1), _M.noProve);
      expect(r.test(), isFalse);
      expect(r.fit(M4StreetlightFixPart.hpsv70), _M.noTighten);
      expect(r.tool, M4StreetlightFixTool.driver);
      expect(r.tighten(0), isNull);
      expect(r.tightened, isFalse, reason: 'that one was tight');
      expect(r.tighten(1), isNull);
      expect(r.tightened, isTrue);
      expect(r.fit(M4StreetlightFixPart.mh150), _M.wrongLamp);
      expect(r.fit(M4StreetlightFixPart.ledSet), _M.wrongKind);
      expect(r.fit(M4StreetlightFixPart.photocell), _M.wrongPhotocell);
      expect(r.fitted, isNull);
      expect(r.fit(M4StreetlightFixPart.hpsv70), isNull);
      expect(r.fitted, M4StreetlightFixPart.hpsv70);
      expect(r.oldInHand, isTrue);
      expect(r.slips, 5);
      final led = atTop(fault: M4StreetlightFixFault.ledDark)
        ..test()
        ..hold(M4StreetlightFixTool.driver)
        ..tighten(1);
      expect(led.fit(M4StreetlightFixPart.hpsv70), _M.wrongKind);
      expect(led.fit(M4StreetlightFixPart.ledSet), isNull);
      expect(led.oldInHand, isFalse, reason: 'no discharge lamp to scrap');
    });

    test('the finish: the old lamp to the crate (the bin is a slip), both MCBs ON, the light burns', () {
      final r = atTop()
        ..test()
        ..hold(M4StreetlightFixTool.driver)
        ..tighten(1)
        ..fit(M4StreetlightFixPart.hpsv70)
        ..descend();
      expect(r.station, M4StreetlightFixStation.finish);
      expect(r.lightOn, isFalse);
      expect(r.toBin(), _M.dustbin);
      expect(r.oldInHand, isTrue);
      r.toggleMcb(0);
      expect(r.lightOn, isTrue);
      expect(r.finishReady, isFalse, reason: 'the old lamp is still in hand');
      expect(r.toCrate(), isTrue);
      expect(r.finishReady, isTrue);
      expect(r.caught, contains(_L.caughtDispose));
      expect(r.climb(), isNull, reason: 'no climbing back at the finish');
      expect(r.up, isFalse);
    });

    test('listening to "no tester" at the top: dead = a slip, live = deadly', () {
      expect(atTop().listenTop(), _M.noProve);
      final live = atTop(isolate: false);
      expect(live.listenTop(), _M.touchLive);
      expect(live.ended, isTrue);
    });

    test('English digits only; every mistake has its picture; one deadly', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allRight,
        ..._L.myths,
        for (final cw in [_L.coworker, _L.coworkerTop]) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final m in _M.all) m.textBn,
        for (final f in M4StreetlightFixFault.values) _L.docketBn(12, f),
        for (final p in M4StreetlightFixPart.values) _L.partBn(p),
        _L.allSet,
        _L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.touchLive]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.9/streetlight_fix/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m4StreetlightFixPacks.keys, ['do_4_9_b']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
      for (final right in [_L.isolateWhy, _L.spotLineWhy, _L.spotSlabWhy, _L.partHpsvWhy, _L.partMhWhy, _L.partLedWhy, _L.disposeWhy, _L.testWhy]) {
        expectLibrary(right.first, right, _L.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, _L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in [_L.coworker, _L.coworkerTop]) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4StreetlightFixPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_streetlight_fix ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4StreetlightFixPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.ladder), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.ladder), findsOneWidget);
      final d = _deal(3);
      expect(find.text(_L.docketBn(d.poleNo, d.fault)), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askBase)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in [7, 8]) {
      testWidgets('flow (seed $seed): isolate, ladder, climb, prove, tighten, the right part, scrap, light; refuse him → pass', (t) async {
        final d = _deal(seed);
        final c = await _open(t, seed);
        await _base(t, d);
        await _top(t, d);
        await _down(t, d);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.9/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.9/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(_L.caughtCall), findsOneWidget);
        expect(find.text(_L.caughtTight), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (the ladder on the bad spot) shows its card; the job goes on after it', (t) async {
      final d = _deal(2);
      final c = await _open(t, 2);
      await _tapAt(t, _geo.mcb(d.mineSlot).center);
      await _tool(t, _L.ladder);
      await _tapAt(t, _geo.spotHit(d.badSide).center);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      final want = d.badKind == M4StreetlightFixBadSpot.line ? _M.spotLine : _M.spotSlab;
      expect(find.text(want.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.ladder), findsOneWidget, reason: 'the same street');
      expect(c.read(gameSaveProvider).mistakes.single.key, want.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final d = _deal(2);
      final c = await _open(t, 2);
      await _tapAt(t, _geo.mcb(d.mineSlot).center);
      await _tool(t, _L.ladder);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.spotHit(d.badSide).center);
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

    testWidgets('a hand inside the live fixture: the street freezes first, then the card (near-miss)', (t) async {
      final d = _deal(2);
      final c = await _open(t, 2);
      await _tool(t, _L.harness);
      // He comes: refuse him by the deck (but leave the MCB ON).
      expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 8000), isTrue);
      await _pump(t, 600);
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      await _tool(t, _L.ladder);
      await _tapAt(t, _geo.spotHit(d.goodSide).center);
      await _tool(t, _L.rope);
      await _tapAt(t, _geo.ladderHit(d.goodSide).center);
      // The MCB is still ON: only the spot reason can be asked.
      await _reason(t, d.badKind == M4StreetlightFixBadSpot.line ? _L.spotLineWhy : _L.spotSlabWhy);
      await _tool(t, _L.driver);
      await _terminal(t, 0);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.touchLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final c = await _open(t, 11);
      await _tool(t, _L.harness);
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
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('MCB off first: he comes at the top ("no tester"); listening on a dead fixture is a slip', (t) async {
      final d = _deal(9);
      final c = await _open(t, 9);
      await _tapAt(t, _geo.mcb(d.mineSlot).center);
      await _tool(t, _L.harness);
      await _tool(t, _L.ladder);
      await _tapAt(t, _geo.spotHit(d.goodSide).center);
      await _tool(t, _L.rope);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not on the footpath: the MCB is off');
      await _tapAt(t, _geo.ladderHit(d.goodSide).center);
      await _reason(t, d.whyBase == M4StreetlightFixWhyBase.isolate ? _L.isolateWhy : (d.badKind == M4StreetlightFixBadSpot.line ? _L.spotLineWhy : _L.spotSlabWhy));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(_L.coworkerTop.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(_M.noProve.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.noProve.key);
      await _close(t, c);
    });
  });
}
