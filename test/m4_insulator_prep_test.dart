// Lesson 4.1 (পিন বা ডিস্ক ইনসুলেটর বদলানো), কাজ 1 "বদলের আগে": the rules
// (spot the faulty insulator; the right kind of new insulator, never a
// cracked spare, and its fittings; PTW → tester → earth on both sides →
// helmet + harness → climb; up a live line or with one earth = deadly), the
// deal, the reason libraries, and the level in the shell: idle perf, the
// guide first, a full clean play with the coworker refused, a slip card that
// keeps the pole, three slips, the deadly freeze (climbing a live line;
// listening to him), refusing him by putting on the second earth; he comes
// even on a fast play; the tool row never shows the safe order; the reason
// deck always holds a myth on the same topic; old mistake keys still resolve;
// the gesture hint shows after idle and after taps on nothing.
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_insulator_prep.dart';
import 'package:slm_flutter/features/game/m4_insulator_prep_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '4.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '4.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m4InsulatorPrepPacks['do_4_1_a']!;
typedef _L = M4InsulatorPrepLines;
typedef _M = M4InsulatorPrepMistakes;
typedef _I = M4InsulatorPrepItem;

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
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4InsulatorPrepGeo get _geo => M4InsulatorPrepGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

/// High on the earth spot: clear of the decks at the bottom.
Offset _earthAt(int side) => Offset(M4InsulatorPrepGeo.earthX[side], _geo.groundY - 220);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4InsulatorPrepPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// Spots the faulty insulator, packs the kit, takes the PTW and tests dead.
Future<void> _prepToDead(WidgetTester t, M4InsulatorPrepSite s) async {
  await _tapAt(t, _geo.spotCentre(s.kind, s.faulty));
  await _tool(t, _L.kit);
  for (final it in [s.rightSpare, ...s.fittings]) {
    await t.tap(find.byKey(ValueKey('shelf-${it.name}')));
    await _pump(t, 300);
  }
  await t.tap(_label(_L.shelfDone));
  await _pump(t, 400);
  await _tool(t, _L.ptw);
  await _tool(t, _L.tester);
  expect(find.text(_L.testerDead), findsOneWidget);
}

/// Plays pole [i] right (the coworker refused on his pole).
Future<void> _playRight(WidgetTester t, M4InsulatorPrepDeal deal, int i) async {
  final s = deal.sites[i];
  await _prepToDead(t, s);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue, reason: 'he comes on pole $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, _L.coworker.right);
    await _pump(t, 2600);
  }
  await _tool(t, _L.earth);
  await _tapAt(t, _earthAt(0));
  await _tapAt(t, _earthAt(1));
  await _tool(t, _L.harness);
  await _tapAt(t, _geo.poleHit.center);
  await _pump(t, 2200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pole $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(s));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals: three poles, both kinds, both faults, a reason each, the full shelf; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m4InsulatorPrepDeal(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.map((x) => x.kind).toSet(), hasLength(2));
        expect(d.sites.map((x) => x.fault).toSet(), hasLength(2));
        expect(d.sites.map((x) => x.why).toSet(), hasLength(3));
        expect(d.callAt, inInclusiveRange(0, 2));
        for (final x in d.sites) {
          expect(x.faulty, inInclusiveRange(0, x.kind == M4InsulatorPrepKind.pin ? 2 : 5));
          expect(x.shelf.toSet(), _I.values.toSet());
          expect(x.tools.toSet(), M4InsulatorPrepButton.values.toSet());
          expect(x.tools, hasLength(M4InsulatorPrepButton.values.length));
          expect(m4InsulatorPrepRowInOrder(x.tools), isFalse, reason: 'the tool row gives the order away: ${x.tools}');
        }
        seen.add(d.sites.map((x) => '${x.kind.name}${x.fault.name}${x.faulty}${x.why.name}${x.shelf.first.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(60));
    });

    test('tool row: the safe order is spotted; the default row and every dealt row avoid it', () {
      const b = M4InsulatorPrepButton.values;
      expect(m4InsulatorPrepRowInOrder([b[0], b[1], b[2], b[3], b[4]]), isTrue);
      expect(m4InsulatorPrepRowInOrder([b[1], b[2], b[0], b[3], b[4]]), isTrue, reason: 'the kit anywhere');
      expect(m4InsulatorPrepRowInOrder([b[2], b[1], b[3], b[4], b[0]]), isFalse);
      final def = M4InsulatorPrepSite(id: 'x', kind: M4InsulatorPrepKind.pin, fault: M4InsulatorPrepFault.crack, faulty: 0, why: M4InsulatorPrepWhy.ptw, shelf: _I.values, poleNo: 1);
      expect(m4InsulatorPrepRowInOrder(def.tools), isFalse);
      final firsts = <M4InsulatorPrepButton>{};
      for (var k = 0; k < 200; k++) {
        final row = m4InsulatorPrepDealRow(math.Random(k));
        expect(m4InsulatorPrepRowInOrder(row), isFalse);
        firsts.add(row.first);
      }
      expect(firsts, hasLength(M4InsulatorPrepButton.values.length), reason: 'rows differ');
    });

    M4InsulatorPrepRun run1(M4InsulatorPrepKind k) => M4InsulatorPrepRun(M4InsulatorPrepDeal(sites: [
          M4InsulatorPrepSite(id: 'x', kind: k, fault: M4InsulatorPrepFault.crack, faulty: 1, why: M4InsulatorPrepWhy.earth, shelf: _I.values, poleNo: 12),
        ], callAt: 0));

    test('spot: a good insulator is a slip; the faulty one opens the prep', () {
      final r = run1(M4InsulatorPrepKind.pin);
      expect(r.pick(_I.pinNew), isNull);
      expect(r.bag, isEmpty, reason: 'nothing before the spot');
      expect(r.tapInsulator(0), _M.misSpot);
      expect(r.spotted, isFalse);
      expect(r.tapInsulator(1), isNull);
      expect(r.spotted, isTrue);
      expect(r.slips, 1);
      expect(r.caught, contains(_L.caughtSpot));
    });

    test('the shelf: the other kind and a cracked spare are slips; the kit is ready with its fittings', () {
      for (final k in M4InsulatorPrepKind.values) {
        final r = run1(k)..tapInsulator(1);
        final pin = k == M4InsulatorPrepKind.pin;
        expect(r.pick(pin ? _I.discNew : _I.pinNew), _M.wrongKind);
        expect(r.pick(pin ? _I.pinBad : _I.discBad), _M.crackedSpare);
        expect(r.bag, isEmpty);
        expect(r.pick(r.site.rightSpare), isNull);
        expect(r.kitReady, isFalse);
        for (final f in r.site.fittings) {
          r.pick(f);
        }
        expect(r.kitReady, isTrue);
        expect(r.pick(r.site.fittings.first), isNull, reason: 'puts it back');
        expect(r.kitReady, isFalse);
        expect(r.slips, 2);
      }
    });

    test('over-packing: a fitting for the other kind of insulator is a slip and stays on the shelf', () {
      for (final k in M4InsulatorPrepKind.values) {
        final r = run1(k)..tapInsulator(1);
        final other = [for (final i in [_I.binding, _I.rope, _I.comeAlong, _I.turnbuckle]) if (!r.site.fittings.contains(i)) i];
        expect(other, hasLength(2));
        for (final (n, i) in other.indexed) {
          expect(r.pick(i), _M.wrongFitting, reason: '$k ${i.name}');
          expect(r.bag.contains(i), isFalse);
          expect(r.slips, n + 1);
        }
        for (final i in r.site.fittings) {
          expect(r.pick(i), isNull);
        }
        expect(r.slips, 2, reason: 'the right fittings cost nothing');
      }
      expect(_M.wrongFitting.deadly, isFalse);
    });

    test('earth: not on a live line, not before the tester; then both sides', () {
      final r = run1(M4InsulatorPrepKind.disc)
        ..tapInsulator(1)
        ..holdEarth();
      expect(r.tapEarth(0), _M.earthLive);
      expect(r.test(), isTrue, reason: 'live before the PTW');
      expect(r.tested, isFalse);
      r.takePtw();
      expect(r.tapEarth(0), _M.earthUntested);
      expect(r.test(), isFalse);
      expect(r.tapEarth(0), isNull);
      expect(r.tapEarth(1), isNull);
      expect(r.earths, {0, 1});
      expect(r.tool, M4InsulatorPrepTool.none);
      expect(r.caught, containsAll([_L.caughtPtw, _L.caughtDead, _L.caughtEarth]));
    });

    test('climb: no PTW = deadly; one earth = deadly', () {
      final a = run1(M4InsulatorPrepKind.pin)..tapInsulator(1);
      expect(a.climb(), _M.climbLive);
      expect(_M.climbLive.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = run1(M4InsulatorPrepKind.pin)
        ..tapInsulator(1)
        ..takePtw()
        ..test()
        ..holdEarth()
        ..tapEarth(0);
      expect(b.climb(), _M.earthBoth);
      expect(b.ended, isTrue);
      final c = run1(M4InsulatorPrepKind.pin)
        ..tapInsulator(1)
        ..takePtw()
        ..test();
      expect(c.climb(), _M.earthBoth, reason: 'no earth at all');
    });

    test('climb: helmet + harness and the full kit first; then up', () {
      final r = run1(M4InsulatorPrepKind.disc)
        ..tapInsulator(1)
        ..takePtw()
        ..test()
        ..holdEarth()
        ..tapEarth(0)
        ..tapEarth(1);
      expect(r.climb(), _M.noHarness);
      r.putHarness();
      expect(r.climb(), _M.noKit);
      for (final it in [r.site.rightSpare, ...r.site.fittings]) {
        r.pick(it);
      }
      expect(r.climb(), isNull);
      expect(r.climbed, isTrue);
      expect(r.slips, 2);
      expect(r.caught, contains(_L.caughtHarness));
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
    });

    test('a good insulator called faulty: a slip with a neutral reply (never "it is fine")', () {
      expect(_M.misSpot.deadly, isFalse);
      for (final w in ['ভালো আছে', 'ঠিক আছে', 'এটা তো']) {
        expect(_M.misSpot.textBn.contains(w), isFalse, reason: w);
      }
    });

    test('old mistake keys (4.1/insulator_prep/…) still resolve to the renamed cards', () {
      expect(_M.legacy, hasLength(_M.all.length));
      for (final (i, m) in _M.all.indexed) {
        final old = _M.legacy[i];
        expect(old.key, startsWith(_M.legacyPrefix));
        expect(old.key.substring(_M.legacyPrefix.length), m.key.substring(_M.prefix.length));
        expect(old.textBn, m.textBn);
        expect(old.art, m.art);
        expect(old.deadly, m.deadly);
        expect(_M.byKey(old.key), same(m));
        expect(_M.byKey(m.key), same(m));
      }
      expect(_M.byKey('4.1/insulator_prep/climb-live'), same(_M.climbLive));
      expect(_M.byKey('nope'), isNull);
    });

    test('English digits only; every mistake has its picture; two deadly', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allRight,
        ..._L.myths,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final m in _M.all) m.textBn,
        for (final i in _I.values) _L.itemBn(i),
        _L.allSet,
        _L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.climbLive, _M.earthBoth]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.1/m4_insulator_prep/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m4InsulatorPrepPacks.keys, ['do_4_1_a']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      for (final w in M4InsulatorPrepWhy.values) {
        final s = M4InsulatorPrepSite(id: 'x', kind: M4InsulatorPrepKind.pin, fault: M4InsulatorPrepFault.burn, faulty: 0, why: w, shelf: _I.values, poleNo: 3);
        final right = _L.whyRight(s);
        expectLibrary('$w', right, _L.myths);
        expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
        final near = _L.nearMyths(w);
        expect(near, hasLength(greaterThanOrEqualTo(2)));
        expect(_L.myths.toSet().containsAll(near), isTrue);
        final rights = <String>{};
        for (var k = 0; k < 40; k++) {
          final deal = _L.dealWhy(s, math.Random(k));
          expect(deal, hasLength(3));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(right, contains(deal.firstWhere((o) => o.correct).textBn));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          expect(deal.where((o) => near.contains(o.textBn)), isNotEmpty, reason: 'a myth on the same topic');
          rights.add(deal.firstWhere((o) => o.correct).textBn);
        }
        expect(rights, hasLength(right.length));
      }
    });

    test('reasons: no word of the question shows only on the right card', () {
      for (final w in M4InsulatorPrepWhy.values) {
        final s = M4InsulatorPrepSite(id: 'x', kind: M4InsulatorPrepKind.disc, fault: M4InsulatorPrepFault.crack, faulty: 0, why: w, shelf: _I.values, poleNo: 5);
        final q = _L.cardWords(_L.whyQuestion(s));
        final seen = <String>{};
        for (var k = 0; k < 200; k++) {
          final deal = _L.dealWhy(s, math.Random(k));
          final right = deal.firstWhere((o) => o.correct).textBn;
          final wrong = {for (final o in deal.where((o) => !o.correct)) ..._L.cardWords(o.textBn)};
          for (final word in q.intersection(_L.cardWords(right))) {
            expect(wrong, contains(word), reason: '$w: "$word" only on "$right"');
          }
          seen.add(right);
        }
        expect(seen, hasLength(_L.whyRight(s).length), reason: 'every right card can come');
      }
      final cw = _L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4InsulatorPrepPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_insulator_prep ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket; the tools after the spot', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(3));
      final c = ProviderContainer();
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: M4InsulatorPrepPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.text(_L.docketJob), findsOneWidget);
      expect(_label(_L.ptw), findsNothing, reason: 'first, the spot');
      final s = deal.sites[0];
      await _tapAt(t, _geo.spotCentre(s.kind, s.faulty));
      expect(_label(_L.ptw), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
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
      expect(lines.every((l) => l.contains(_L.askSpot)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: spot, kit, PTW, dead, two earths, harness, climb; refuse him; right reasons → pass', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.1/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.1/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtEarth), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (a cracked spare) shows its card; the same pole goes on after it', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(2));
      final s = deal.sites[0];
      final c = await _open(t, 2);
      await _tapAt(t, _geo.spotCentre(s.kind, s.faulty));
      await _tool(t, _L.kit);
      await t.tap(find.byKey(ValueKey('shelf-${(s.kind == M4InsulatorPrepKind.pin ? _I.pinBad : _I.discBad).name}')));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.crackedSpare.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.shelfDone), findsOneWidget, reason: 'the same shelf, the same pole');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.crackedSpare.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(2));
      final s = deal.sites[0];
      final good = [for (var i = 0; i < _geo.spots(s.kind); i++) if (i != s.faulty) i];
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.spotCentre(s.kind, good[i % good.length]));
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

    testWidgets('climbing a live line: the scene freezes first, then the card (near-miss)', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(2));
      final s = deal.sites[0];
      final c = await _open(t, 2);
      await _tapAt(t, _geo.spotCentre(s.kind, s.faulty));
      await _tapAt(t, _geo.poleHit.center);
      await _pump(t, 200);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final save = c.read(gameSaveProvider);
      expect(save.mistakes.single.key, _M.climbLive.key);
      expect(save.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _prepToDead(t, deal.sites[deal.callAt]);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.earthBoth.key);
      await _close(t, c);
    });

    testWidgets('the second earth on while he talks refuses him', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _prepToDead(t, deal.sites[deal.callAt]);
      await _tool(t, _L.earth);
      await _tapAt(t, _earthAt(0));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 300);
      await _tapAt(t, _earthAt(1));
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: the second earth waits for him', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      final s = deal.sites[deal.callAt];
      await _prepToDead(t, s);
      // Earth, both sides, at once — well before his 1.2 s timer.
      await t.tap(_label(_L.earth));
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(_earthAt(0) * _k);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(_earthAt(1) * _k);
      await t.pump(const Duration(milliseconds: 60));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the second earth brought him in');
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      // The earth is still in hand: the other side now, then up.
      await _tapAt(t, _earthAt(1));
      await _tool(t, _L.harness);
      await _tapAt(t, _geo.poleHit.center);
      await _pump(t, 2200);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'both earths were on');
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'up the pole: the reason deck');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('he comes even on a fast climb: the pole waits for him', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _prepToDead(t, deal.sites[deal.callAt]);
      await t.tapAt(_geo.poleHit.center * _k);
      await t.pump(const Duration(milliseconds: 60));
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'the climb tap only called him in');
      await _close(t, c);
    });

    testWidgets('the tool row follows the dealt order (never the safe order)', (t) async {
      final deal = m4InsulatorPrepDeal(math.Random(7));
      final c = await _open(t, 7);
      final s = deal.sites[0];
      await _tapAt(t, _geo.spotCentre(s.kind, s.faulty));
      String name(M4InsulatorPrepButton b) => switch (b) {
            M4InsulatorPrepButton.kit => _L.kit,
            M4InsulatorPrepButton.ptw => _L.ptw,
            M4InsulatorPrepButton.tester => _L.tester,
            M4InsulatorPrepButton.earth => _L.earth,
            M4InsulatorPrepButton.harness => _L.harness,
          };
      final xs = [for (final b in s.tools) t.getCenter(_label(name(b))).dx];
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]), reason: '${s.tools}');
      }
      expect(m4InsulatorPrepRowInOrder(s.tools), isFalse);
      await _close(t, c);
    });

    group('gesture hints', () {
      setUp(() => GestureHints.debugEnableInTests = true);
      tearDown(() => GestureHints.debugEnableInTests = false);

      IdleHintState frameHint(WidgetTester t) => t.state<IdleHintState>(find.byType(IdleHint).first);

      testWidgets('the hand shows after idle while the level waits; a touch hides it', (t) async {
        final c = await _open(t, 5);
        expect(find.byType(IdleHint), findsOneWidget);
        expect(frameHint(t).showing, isFalse);
        await _pump(t, 9000);
        expect(frameHint(t).showing, isTrue);
        await t.tapAt(const Offset(250, 140) * _k);
        await t.pump(const Duration(milliseconds: 50));
        expect(frameHint(t).showing, isFalse);
        await _close(t, c);
      });

      testWidgets('three taps on nothing show the hand at once', (t) async {
        final c = await _open(t, 5);
        for (var i = 0; i < 3; i++) {
          await t.tapAt(const Offset(250, 140) * _k);
          await t.pump(const Duration(milliseconds: 200));
        }
        expect(frameHint(t).showing, isTrue);
        expect(c.read(gameSaveProvider).mistakes, isEmpty, reason: 'a tap on the sky costs nothing');
        await _close(t, c);
      });
    });
  });
}
