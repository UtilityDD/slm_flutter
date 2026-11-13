// Lesson 5.10 (প্রিভেন্টিভ মেইনটেন্যান্স), কাজ "লুকানো গরম: PM রাউন্ড": the
// rules (snap only the hotspots, end the scan with none missed; phone →
// written PTW → tester 0 V → earth → wrench, the wrench early = deadly;
// every snapped joint and the loose nut tight before নামুন; only true cards
// in the logbook), the deal and its variety, the libraries, the geometry,
// and the level in the shell: the guide first, tapping him, a full clean
// play with each coworker push refused and every reason picked, a sound joint
// snapped (slip), three slips, the wrench before the permit (freeze, then
// the card), নামুন waiting for him, listening to him, a wrong sign, and the
// gesture hands (how, never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m5_pm_thermal_round.dart';
import 'package:slm_flutter/features/game/m5_pm_thermal_round_world.dart';
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
  rungId: '5.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

final _pack = m5PmThermalRoundPacks['do_5_10_a']!;

/// Reads art from disk when the bundle does not have it yet.
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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M5PmGeo get _geo => M5PmGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

/// Drags the camera's window from [from] to [to] (design px), holds it still
/// for the snap, lets go. Returns where the window is now.
Future<Offset> _snapAt(WidgetTester t, Offset from, Offset to) async {
  const over = Offset(0, 14);
  final d = to + over - from;
  // The finger starts where both ends of the drag stay on the scene.
  final start = const Offset(200, 360) - d / 2;
  final g = await t.startGesture(start * _k);
  const steps = 8;
  for (var i = 0; i < steps; i++) {
    await g.moveBy(d * _k / steps.toDouble());
    await t.pump(const Duration(milliseconds: 16));
  }
  // The last short move lands on the joint (the hold starts there).
  await g.moveBy(-over * _k);
  await t.pump(const Duration(milliseconds: 16));
  await _pump(t, 950);
  await g.up();
  await t.pump(const Duration(milliseconds: 100));
  return to;
}

/// Turns the torque wrench round [c] (design px), a full circle.
Future<void> _turnAt(WidgetTester t, Offset c) async {
  const r = 15.0;
  final g = await t.startGesture((c + const Offset(r, 0)) * _k);
  for (var i = 1; i <= 13; i++) {
    final a = i * math.pi / 6;
    await g.moveTo((c + Offset(math.cos(a), math.sin(a)) * r) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5PmThermalRoundPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 2600);
}

M5PmDeal _dealOf(int seed) => m5PmDeal(math.Random(seed));
int _seedWhere(bool Function(M5PmDeal d) f) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => f(_dealOf(s)));

/// Round ক, right: every hotspot snapped (the first one's reason), স্ক্যান শেষ.
Future<void> _scan(WidgetTester t, M5PmDeal d) async {
  var at = _geo.finderHome;
  for (final (i, j) in d.hot.indexed) {
    at = await _snapAt(t, at, _geo.joint(j));
    if (i == 0) {
      await _reason(t, M5PmLines.hotWhy);
    } else {
      await _pump(t, 600);
    }
    expect(find.text(MistakeLines.slipHead), findsNothing, reason: '$j');
  }
  await _tool(t, M5PmLines.scanDone);
  await _pump(t, 2200);
}

/// Round খ, right: phone, permit, tester, earth, wrench; the reason.
Future<void> _shutdown(WidgetTester t) async {
  await _tool(t, M5PmLines.phone);
  await _tool(t, M5PmLines.permit);
  await _tool(t, M5PmLines.tester);
  expect(find.text(M5PmLines.testerDead), findsOneWidget);
  await _tool(t, M5PmLines.earth);
  await _tool(t, M5PmLines.wrench);
  await _pump(t, 600);
  await _reason(t, M5PmLines.ptwWhy);
}

Future<void> _refuse(WidgetTester t, CoworkerScript cw) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, cw.right);
  await _pump(t, 2600);
}

/// Round গ: every snapped joint, push A refused (if dealt), every nut (the
/// loose one's reason), নামুন; the line clear.
Future<void> _tighten(WidgetTester t, M5PmDeal d) async {
  for (final j in d.hot) {
    await _turnAt(t, _geo.joint(j));
  }
  if (!d.pushB) await _refuse(t, M5PmLines.coworkerA);
  for (final n in d.nuts) {
    await _turnAt(t, _geo.nut(n));
    if (n == d.loose) await _reason(t, M5PmLines.nutWhy);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing);
  await _tool(t, M5PmLines.down);
  await _pump(t, 4500);
}

Set<String> _truth(M5PmDeal d, {bool looseFixed = true}) => {
      for (final j in d.hot) M5PmLines.hotCard(j),
      M5PmLines.workCard,
      if (d.loose != null && looseFixed) M5PmLines.nutCard,
      if (d.oilChanged) M5PmLines.oilCard,
    };

/// Round ঘ: push B refused (if dealt), the true cards on the page (the first
/// one dragged), sign; the reason.
Future<void> _logbook(WidgetTester t, M5PmDeal d) async {
  expect(_label(M5PmLines.sign), findsOneWidget);
  if (d.pushB) await _refuse(t, M5PmLines.coworkerB);
  // The whole logbook fits: সই and every card within reach.
  expect(find.byKey(const ValueKey('m5pm-sign')).hitTestable(), findsOneWidget);
  for (final c in M5PmRun(d).logPool(math.Random(0))) {
    expect(_label(c).hitTestable(), findsOneWidget, reason: c);
  }
  final cards = _truth(d).toList();
  final page = find.byType(DragTarget<String>);
  final first = find.byKey(ValueKey('log-pool-${cards.first}'));
  await t.drag(first, t.getCenter(page) - t.getCenter(first));
  await _pump(t, 300);
  expect(find.byKey(ValueKey('log-on-${cards.first}')), findsOneWidget, reason: 'dragged onto the page');
  for (final c in cards.skip(1)) {
    await t.tap(_label(c));
    await _pump(t, 250);
  }
  await _tool(t, M5PmLines.sign);
  await _pump(t, 600);
  await _reason(t, d.oilChanged ? M5PmLines.oilWhy : M5PmLines.logWhy);
}

void main() {
  group('rules', () {
    test('deals: 1–2 hotspots on different places (> 15 °C over the other phases); nuts, the loose one, the oil, the push all vary', () {
      final seen = <String>{};
      var loose = 0;
      var oil = 0;
      var pushB = 0;
      var two = 0;
      for (var s = 0; s < 300; s++) {
        final d = _dealOf(s);
        expect(d.hot.length, inInclusiveRange(1, 2));
        expect(d.hot.map((j) => j.place).toSet(), hasLength(d.hot.length));
        if (d.hot.length == 2) {
          two++;
          expect(
              [
                {M5PmPlace.doTop, M5PmPlace.doBottom},
                {M5PmPlace.doBottom, M5PmPlace.htBushing},
                {M5PmPlace.htBushing, M5PmPlace.ltLug},
              ].any((p) => p.containsAll(d.hot.map((j) => j.place))),
              isFalse,
              reason: '${d.hot}');
        }
        expect(d.temps, hasLength(18));
        for (final p in M5PmPlace.values) {
          final hot = d.hot.where((j) => j.place == p).toList();
          final row = [for (var i = 0; i < 3; i++) d.temps[(place: p, phase: i)]!];
          if (hot.isEmpty) {
            expect(row.reduce(math.max) - row.reduce(math.min), lessThanOrEqualTo(3), reason: 'sound phases alike: $row');
          } else {
            final h = d.temps[hot.single]!;
            for (var i = 0; i < 3; i++) {
              if (i != hot.single.phase) expect(h - row[i], greaterThan(15), reason: 'M5-15: $row');
            }
          }
        }
        expect(d.nuts.length, inInclusiveRange(3, 4));
        expect(d.nuts.toSet(), hasLength(d.nuts.length));
        if (d.loose != null) {
          loose++;
          expect(d.nuts, contains(d.loose));
        }
        if (d.oilChanged) oil++;
        if (d.pushB) pushB++;
        expect(d.hot, isNot(contains(d.decoy)));
        expect(d.untrueWork.length, inInclusiveRange(1, 2));
        expect(M5PmLines.untrueWork, containsAll(d.untrueWork));
        expect(d.light, inInclusiveRange(0, 2));
        seen.add('${d.hot}|${d.nuts}|${d.loose}|${d.oilChanged}|${d.pushB}');
      }
      expect(seen.length, greaterThan(100));
      expect(loose / 300, inInclusiveRange(0.55, 0.78), reason: 'a loose nut 2 plays in 3');
      expect(oil / 300, inInclusiveRange(0.4, 0.6));
      expect(pushB / 300, inInclusiveRange(0.4, 0.6));
      expect(two / 300, inInclusiveRange(0.4, 0.6));
    });

    test('deals: no cut-off reading gives a hotspot away; only a comparison across phases does (M5-15)', () {
      var hottestSound = 0;
      var coolestHot = 1000;
      var sameDeal = 0;
      for (var s = 0; s < 300; s++) {
        final d = _dealOf(s);
        final sound = [for (final j in m5PmAllJoints) if (!d.hot.contains(j)) d.temps[j]!];
        final hot = [for (final j in d.hot) d.temps[j]!];
        final maxSound = sound.reduce(math.max);
        final minHot = hot.reduce(math.min);
        hottestSound = math.max(hottestSound, maxSound);
        coolestHot = math.min(coolestHot, minHot);
        if (maxSound > minHot) sameDeal++;
      }
      expect(hottestSound, greaterThan(coolestHot + 5), reason: 'absolute readings overlap across deals');
      expect(sameDeal / 300, greaterThan(0.25), reason: 'often a sound joint reads hotter than a hotspot in the same deal');
    });

    test('deals: today\'s oil colour alone never tells; only the গত PM photo beside it does', () {
      final byToday = <int, Set<bool>>{};
      for (var s = 0; s < 300; s++) {
        final d = _dealOf(s);
        expect(d.oilLast, inInclusiveRange(0, 2));
        expect(d.oilToday, inInclusiveRange(0, 2));
        if (d.oilChanged) expect(d.oilToday, greaterThan(d.oilLast), reason: 'changed oil only darkens');
        byToday.putIfAbsent(d.oilToday, () => {}).add(d.oilChanged);
      }
      for (final today in [1, 2]) {
        expect(byToday[today], {true, false}, reason: 'today $today seen both changed and unchanged');
      }
    });

    test('স্ক্যান: the same sound joint photographed again costs no second slip', () {
      final d = _dealOf(0);
      final r = M5PmRun(d);
      final sound = m5PmAllJoints.firstWhere((j) => !d.hot.contains(j));
      expect(r.snap(sound), M5PmMistakes.soundSnap);
      expect(r.snap(sound), isNull);
      expect(r.snap(sound), isNull);
      expect(r.slips, 1);
      expect(r.wrongSnapped, {sound});
      expect(r.snapped, isEmpty);
    });

    test('স্ক্যান: a sound joint snapped is a slip (not pinned); স্ক্যান শেষ with a hotspot missed is a slip; all found ends the round', () {
      final d = _dealOf(_seedWhere((d) => d.hot.length == 2));
      final r = M5PmRun(d);
      expect(r.stage, M5PmStage.scan);
      final sound = m5PmAllJoints.firstWhere((j) => !d.hot.contains(j));
      expect(r.snap(sound), M5PmMistakes.soundSnap);
      expect(r.snapped, isEmpty);
      expect(r.snap(d.hot.first), isNull);
      expect(r.snap(d.hot.first), isNull, reason: 'again: nothing');
      expect(r.endScan(), M5PmMistakes.missedHot);
      expect(r.roundDone, isFalse);
      expect(r.snap(d.hot.last), isNull);
      expect(r.endScan(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.slips, 2);
      expect(r.caught, isNot(contains(M5PmLines.caughtScan)));
      final clean = M5PmRun(d);
      for (final j in d.hot) {
        clean.snap(j);
      }
      expect(clean.endScan(), isNull);
      expect(clean.caught, contains(M5PmLines.caughtScan));
    });

    test('শাটডাউন: the wrench before the written PTW, before 0 V or before the earth is deadly', () {
      final d = _dealOf(1);
      M5PmRun at() => M5PmRun(d)..next();
      final a = at();
      expect(a.use(M5PmTool.wrench), M5PmMistakes.noPermit);
      expect(a.ended, isTrue);
      final b = at()..use(M5PmTool.phone);
      expect(b.use(M5PmTool.wrench), M5PmMistakes.noPermit, reason: 'a phone "line off" is no permit');
      final c = at()
        ..use(M5PmTool.phone)
        ..use(M5PmTool.permit);
      expect(c.use(M5PmTool.wrench), M5PmMistakes.noTest);
      final e = at()
        ..use(M5PmTool.phone)
        ..use(M5PmTool.permit)
        ..use(M5PmTool.tester);
      expect(e.use(M5PmTool.wrench), M5PmMistakes.noEarth);
      for (final m in [M5PmMistakes.noPermit, M5PmMistakes.noTest, M5PmMistakes.noEarth]) {
        expect(m.deadly, isTrue);
      }
    });

    test('শাটডাউন: steps out of order are slips (earth before the test = R3 slip); the right order ends the round', () {
      final r = M5PmRun(_dealOf(1))..next();
      expect(r.stage, M5PmStage.shutdown);
      expect(r.use(M5PmTool.permit), M5PmMistakes.phoneFirst);
      expect(r.use(M5PmTool.tester), M5PmMistakes.permitFirst);
      expect(r.use(M5PmTool.earth), M5PmMistakes.permitFirst);
      r
        ..use(M5PmTool.phone)
        ..use(M5PmTool.permit);
      expect(r.use(M5PmTool.earth), M5PmMistakes.testFirst);
      expect(r.earthed, isFalse);
      expect(r.use(M5PmTool.tester), isNull);
      expect(r.use(M5PmTool.earth), isNull);
      expect(r.use(M5PmTool.wrench), isNull);
      expect(r.roundDone, isTrue);
      expect(r.slips, 4);
      expect(r.caught, isNot(contains(M5PmLines.caughtPtw)));
      expect(M5PmMistakes.testFirst.textBn, contains('আগে টেস্টার দিয়ে ডেড প্রমাণ, তারপর আর্থ'));
    });

    test('টাইট: tight nuts click at once, the loose one needs a full turn; নামুন with a joint or the loose nut left is a slip', () {
      final d = _dealOf(_seedWhere((d) => d.loose != null));
      final r = M5PmRun(d)
        ..next()
        ..next();
      expect(r.stage, M5PmStage.tighten);
      expect(r.aloft, isTrue);
      for (final n in d.nuts) {
        expect(r.turnForNut(n), n == d.loose ? m5PmFullTurn : m5PmTightTurn);
      }
      expect(r.climbDown(), M5PmMistakes.nutLeft);
      for (final j in d.hot) {
        r.wrenchJoint(j);
      }
      expect(r.hotDone, isTrue);
      expect(r.climbDown(), M5PmMistakes.nutLeft, reason: 'the loose nut');
      for (final n in d.nuts.where((n) => n != d.loose)) {
        expect(r.wrenchNut(n), isFalse);
      }
      expect(r.wrenchNut(d.loose!), isTrue);
      expect(r.turnForNut(d.loose!), m5PmTightTurn, reason: 'now tight');
      expect(r.climbDown(), isNull);
      expect(r.aloft, isFalse);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(M5PmLines.caughtNut));
      // The cooled joints read like the other two phases again.
      for (final j in d.hot) {
        final others = [for (var i = 0; i < 3; i++) if (i != j.phase) d.temps[(place: j.place, phase: i)]!];
        expect((r.cooled[j]! - others.reduce(math.max)).abs(), lessThanOrEqualTo(4));
      }
    });

    test('the coworker: listening is a slip; push A brings him down at once, leaving the loose nut (its card turns untrue)', () {
      final d = _dealOf(_seedWhere((d) => !d.pushB && d.loose != null));
      final r = M5PmRun(d)
        ..next()
        ..next();
      for (final j in d.hot) {
        r.wrenchJoint(j);
      }
      expect(r.listen(), M5PmMistakes.pushA);
      expect(r.roundDone, isTrue);
      expect(r.aloft, isFalse);
      r.next();
      expect(r.logTrue, isNot(contains(M5PmLines.nutCard)));
      final b = M5PmRun(_dealOf(_seedWhere((d) => d.pushB)))
        ..next()
        ..next()
        ..next();
      expect(b.listen(), M5PmMistakes.pushB);
      expect(b.roundDone, isFalse, reason: 'the logbook stays open');
    });

    test('লগবুক: only the true cards sign right; a wrong sign is a slip and the untrue cards come off; the oil card is true only when the photos differ', () {
      for (var s = 0; s < 40; s++) {
        final d = _dealOf(s);
        final r = M5PmRun(d)
          ..next()
          ..next();
        for (final j in d.hot) {
          r.wrenchJoint(j);
        }
        if (d.loose != null) r.wrenchNut(d.loose!);
        r.climbDown();
        r.next();
        expect(r.stage, M5PmStage.logbook);
        expect(r.logTrue, _truth(d));
        final pool = r.logPool(math.Random(s));
        expect(pool.toSet(), hasLength(pool.length));
        expect(pool, containsAll(r.logTrue));
        expect(pool, containsAll([M5PmLines.nutCard, M5PmLines.oilCard, M5PmLines.hotCard(d.decoy)]), reason: 'offered every play');
        expect(d.oilChanged, d.oilLast != d.oilToday);
        // A page with an untrue card.
        for (final c in r.logTrue) {
          r.place(c);
        }
        final untrue = pool.firstWhere((c) => !r.logTrue.contains(c));
        r.place(untrue);
        expect(r.sign(), M5PmMistakes.wrongSign);
        expect(r.page, isNot(contains(untrue)));
        expect(r.page, r.logTrue, reason: 'the true cards stay');
        // A page with one missing.
        r.unplace(M5PmLines.workCard);
        expect(r.sign(), M5PmMistakes.wrongSign);
        r.place(M5PmLines.workCard);
        expect(r.sign(), isNull);
        expect(r.roundDone, isTrue);
        r.next();
        expect(r.done, isTrue);
        expect(r.slips, 2);
      }
    });

    test('a clean play passes with every caught line', () {
      final d = _dealOf(_seedWhere((d) => d.loose != null));
      final r = M5PmRun(d);
      for (final j in d.hot) {
        r.snap(j);
      }
      r
        ..endScan()
        ..next()
        ..use(M5PmTool.phone)
        ..use(M5PmTool.permit)
        ..use(M5PmTool.tester)
        ..use(M5PmTool.earth)
        ..use(M5PmTool.wrench)
        ..next();
      for (final j in d.hot) {
        r.wrenchJoint(j);
      }
      for (final n in d.nuts) {
        r.wrenchNut(n);
      }
      r
        ..climbDown()
        ..next();
      for (final c in r.logTrue) {
        r.place(c);
      }
      r
        ..sign()
        ..next();
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, containsAll([M5PmLines.caughtScan, M5PmLines.caughtPtw, M5PmLines.caughtNut, M5PmLines.caughtLog]));
    });

    test('tool rows: every tool, never laid out left to right in a working order; rows differ', () {
      expect(m5PmInWorkOrder(const [M5PmTool.phone, M5PmTool.permit, M5PmTool.tester, M5PmTool.earth, M5PmTool.wrench]), isTrue);
      expect(m5PmInWorkOrder(const [M5PmTool.wrench, M5PmTool.phone, M5PmTool.permit, M5PmTool.tester, M5PmTool.earth]), isTrue);
      final rows = <String>{};
      for (var s = 0; s < 60; s++) {
        final row = m5PmToolRow(math.Random(s));
        expect(row.toSet(), M5PmTool.values.toSet());
        expect(m5PmInWorkOrder(row), isFalse, reason: '$row');
        rows.add(row.map((t) => t.name).join(','));
      }
      expect(rows.length, greaterThan(15));
    });

    test('English digits only; জল not পানি; every mistake has its picture; the three deadly; keys unique', () {
      final all = <String>[
        M5PmLines.intro,
        ...M5PmLines.tasks,
        ...M5PmLines.allWhyRight,
        ...M5PmLines.myths,
        M5PmLines.hotWhyQ,
        M5PmLines.ptwWhyQ,
        M5PmLines.nutWhyQ,
        M5PmLines.logWhyQ,
        M5PmLines.oilWhyQ,
        for (final cw in [M5PmLines.coworkerA, M5PmLines.coworkerB]) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final j in m5PmAllJoints) M5PmLines.hotCard(j),
        M5PmLines.workCard,
        M5PmLines.nutCard,
        M5PmLines.oilCard,
        ...M5PmLines.untrueWork,
        for (final m in M5PmMistakes.all) m.textBn,
        M5PmLines.allSet,
        M5PmLines.fail,
        M5PmLines.lineClear,
        M5PmLines.reglance,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5PmMistakes.all.where((m) => m.deadly).toSet(), {M5PmMistakes.noPermit, M5PmMistakes.noTest, M5PmMistakes.noEarth});
      expect(M5PmMistakes.all.map((m) => m.key).toSet(), hasLength(M5PmMistakes.all.length));
      for (final m in M5PmMistakes.all) {
        expect(m.key, startsWith('5.10/m5_pm_thermal_round/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      // Every picture in the folder is used.
      final used = {for (final m in M5PmMistakes.all) m.art.split('/').last};
      final files = Directory('assets/game/art/m5_pm_thermal_round').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m5PmThermalRoundPacks.keys, ['do_5_10_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; both pushes listed for recording; his exit is recorded', () {
      expectSameLength('why', [...M5PmLines.allWhyRight, ...M5PmLines.myths]);
      expect(M5PmLines.myths.toSet().intersection(M5PmLines.allWhyRight.toSet()), isEmpty);
      for (final right in [M5PmLines.hotWhy, M5PmLines.ptwWhy, M5PmLines.nutWhy, M5PmLines.logWhy, M5PmLines.oilWhy]) {
        expectLibrary(right.first, right, M5PmLines.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, M5PmLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in [M5PmLines.coworkerA, M5PmLines.coworkerB]) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks.length, greaterThanOrEqualTo(3));
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: 'the exit line is recorded');
      }
      expect(M5PmLines.rivalLines, [M5PmLines.coworkerA.line, M5PmLines.coworkerB.line]);
      expect(M5PmLines.coworkerA.line, isNot(M5PmLines.coworkerB.line));
    });

    test('geometry: joints apart and on the scene below the header; wrench targets never crowd', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M5PmGeo.forScene(h, 0);
        final pts = [for (final j in m5PmAllJoints) g.joint(j)];
        for (final p in pts) {
          expect(p.dx, inInclusiveRange(10, 350));
          expect(p.dy, greaterThan(120), reason: 'below the header');
          expect(p.dy, lessThan(g.groundY));
        }
        for (var i = 0; i < pts.length; i++) {
          for (var j = i + 1; j < pts.length; j++) {
            expect((pts[i] - pts[j]).distance, greaterThanOrEqualTo(2 * M5PmGeo.jointHit), reason: 'h $h: ${m5PmAllJoints[i]} / ${m5PmAllJoints[j]}');
          }
        }
        expect(g.jointAt(g.finderHome), isNull, reason: 'the camera starts on the empty sky');
        for (var s = 0; s < 200; s++) {
          final d = _dealOf(s);
          final t = [for (final j in d.hot) g.joint(j), for (final n in d.nuts) g.nut(n)];
          for (var i = 0; i < t.length; i++) {
            for (var j = i + 1; j < t.length; j++) {
              expect((t[i] - t[j]).distance, greaterThanOrEqualTo(2 * M5PmGeo.targetHit - 2), reason: 'h $h seed $s: $i/$j');
            }
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
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: a tap does not skip him; then the camera and স্ক্যান শেষ', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5PmThermalRoundPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5PmLines.scanDone), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5PmLines.scanDone), findsOneWidget);
      expect(_label(M5PmLines.wrench), findsNothing, reason: 'no tools while scanning');
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
      expect(lines.every((l) => l.contains(M5PmLines.askScan)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final flows = {
      'push A, a loose nut, two hotspots': (M5PmDeal d) => !d.pushB && d.loose != null && d.hot.length == 2,
      'push B, the oil changed, no loose nut': (M5PmDeal d) => d.pushB && d.oilChanged && d.loose == null,
    };
    for (final MapEntry(key: name, value: pick) in flows.entries) {
      testWidgets('flow ($name): scan, shutdown, tighten, logbook; he is refused; right reasons → pass', (t) async {
        final seed = _seedWhere(pick);
        final d = _dealOf(seed);
        final c = await _open(t, seed);
        await _scan(t, d);
        expect(_label(M5PmLines.phone), findsOneWidget, reason: 'the shutdown round');
        await _shutdown(t);
        expect(_label(M5PmLines.down), findsOneWidget, reason: 'up the pole');
        await _tighten(t, d);
        await _logbook(t, d);
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.10/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.10/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5PmLines.caughtScan), findsOneWidget);
        expect(find.text(M5PmLines.caughtLog), findsOneWidget);
        expect(find.text(d.pushB ? M5PmLines.caughtCallB : M5PmLines.caughtCallA), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a sound joint held in the camera is a slip: its card, and the scan goes on', (t) async {
      const seed = 2;
      final d = _dealOf(seed);
      final c = await _open(t, seed);
      final sound = m5PmAllJoints.firstWhere((j) => !d.hot.contains(j));
      await _snapAt(t, _geo.finderHome, _geo.joint(sound));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5PmMistakes.soundSnap.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_label(M5PmLines.scanDone), findsOneWidget, reason: 'the same round');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5PmMistakes.soundSnap.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (স্ক্যান শেষ with nothing found)', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _tool(t, M5PmLines.scanDone);
        await _pump(t, 600);
        if (i < 2) {
          expect(find.text(M5PmMistakes.missedHot.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the wrench before the permit: the scene freezes first, then the card (near-miss)', (t) async {
      final d = _dealOf(4);
      final c = await _open(t, 4);
      await _scan(t, d);
      await _tool(t, M5PmLines.phone);
      await _tool(t, M5PmLines.wrench);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5PmMistakes.noPermit.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('push A: নামুন waits for him on a fast play; listening is a slip, he takes the trainee down; a wrong sign is a slip', (t) async {
      final seed = _seedWhere((d) => !d.pushB && d.loose != null);
      final d = _dealOf(seed);
      final c = await _open(t, seed);
      await _scan(t, d);
      await _shutdown(t);
      for (final j in d.hot) {
        await _turnAt(t, _geo.joint(j));
      }
      // At once: well inside his 1.2–2.4 s timer.
      await t.tap(_label(M5PmLines.down));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(find.byType(MistakeCard), findsNothing, reason: 'নামুন did nothing');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M5PmLines.coworkerA.wrong);
      await _pump(t, 800);
      expect(find.text(M5PmMistakes.pushA.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 4500);
      // The line clear ran; the logbook is open; the nut card is untrue now.
      expect(_label(M5PmLines.sign), findsOneWidget);
      await t.tap(_label(M5PmLines.nutCard));
      for (final card in _truth(d, looseFixed: false)) {
        await t.tap(_label(card));
        await _pump(t, 200);
      }
      await _tool(t, M5PmLines.sign);
      await _pump(t, 600);
      expect(find.text(M5PmMistakes.wrongSign.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byKey(ValueKey('log-on-${M5PmLines.nutCard}')), findsNothing, reason: 'the untrue card came off');
      await _tool(t, M5PmLines.sign);
      await _pump(t, 600);
      await _reason(t, d.oilChanged ? M5PmLines.oilWhy : M5PmLines.logWhy);
      await _pump(t, 2500);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [M5PmMistakes.pushA.key, M5PmMistakes.wrongSign.key]);
      expect(find.byType(LevelPassPanel), findsOneWidget, reason: '2 slips = 70 %');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hand: the camera drag (never a sweep over the joints), the tool row, every wrench target; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => !d.pushB);
      final d = _dealOf(seed);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the scan');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a sweep over joints');
      expect(scene().debugFrame?.ripple, isNull);
      await _scan(t, d);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the shutdown');
      expect(scene().debugOptions, hasLength(M5PmTool.values.length), reason: 'every button alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _shutdown(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle aloft');
      expect(scene().debugOptions, hasLength(d.hot.length + d.nuts.length), reason: 'every target alike');
      // The reason deck has its own sweep; the scene's hand stays away.
      for (final j in d.hot) {
        await _turnAt(t, _geo.joint(j));
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'his deck is up');
      await _close(t, c);
    });
  });
}
