// Lesson 5.8 (ট্রান্সফরমারের সাধারণ সমস্যা), কাজ 2 "হাসপাতালের কাগজ": the rules
// (read the log → call the right team; re-charging = deadly at any site; the
// bushings before the tester's 0 V = deadly; pin findings, never clean items;
// 'পাঠান' only with every finding pinned), the deal, the libraries, the
// coworker's lines (the water push is lesson 5.8's myth word for word), and the
// level in the shell: the guide first, tapping him restates the task, full
// clean plays with each coworker push refused, a slip card that keeps the
// site, three slips, the deadly freezes (re-charge; bushings untested;
// listening to the charge push), the water myth slip, the coworker cutting in
// on a fast play, and the gesture hand (how, never what) only while waiting.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/theme/app_theme.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_workshop_referral.dart';
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
  rungId: '5.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5WorkshopReferralPacks['do_5_8_b']!;

/// The new art is not in the bundle until the director wires it: tests read
/// it from disk when the bundle does not have it.
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
M5WrGeo get _geo => M5WrGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _lensTap(WidgetTester t, String key) async {
  await t.tapAt(t.getCenter(find.byKey(ValueKey(key))));
  await _pump(t, 400);
}

/// A slow horizontal drag inside the close-up (the cloth pass, the swirl).
Future<void> _lensDrag(WidgetTester t, String key) async {
  final r = t.getRect(find.byKey(ValueKey(key)));
  final g = await t.startGesture(r.centerLeft + const Offset(6, 0));
  for (var i = 0; i < 8; i++) {
    await g.moveBy(const Offset(28, 0));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 700);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5WorkshopReferralPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

/// Reads the site's log (tap it on the pole, then ঠিক আছে).
Future<void> _readLog(WidgetTester t) async {
  await _tapAt(t, _geo.logHit.center);
  expect(find.text(M5WrLines.logTitle), findsOneWidget);
  await t.tap(_label(M5WrLines.logOk));
  await _pump(t, 500);
}

/// A team button: its tap only opens it big; ✓ (key `choice-confirm`) decides.
Future<void> _team(WidgetTester t, M5WrTeam team) async {
  await t.tap(_label(M5WrLines.teamLabel(team)));
  await confirmChoice(t);
  await _pump(t, 400);
}

Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, s.right);
  await _pump(t, 2600);
}

/// The tester held to the bushings: 0 V.
Future<void> _test(WidgetTester t) async {
  await t.longPressAt(_geo.testerHit.center * _k);
  await _pump(t, 400);
  expect(find.text(M5WrLines.testerDead), findsOneWidget);
}

Future<void> _openStation(WidgetTester t, M5WrStation s) async {
  await _tapAt(t, _geo.stationHit(s).center);
  await _pump(t, 200);
  expect(find.byKey(ValueKey('lens-${s.name}')), findsOneWidget, reason: '$s open');
}

/// Looks at a station and pins its findings; [onSwirl] runs right after the
/// oil swirl (the water coworker).
Future<void> _station(WidgetTester t, M5WrSite site, M5WrStation s, {Future<void> Function()? onSwirl}) async {
  await _openStation(t, s);
  final mine = [for (final p in site.findings) if (p.station == s) p.index];
  switch (s) {
    case M5WrStation.bushing:
      await _lensDrag(t, 'lens-bushing-0');
      for (final i in mine) {
        await _lensTap(t, 'lens-bushing-$i');
      }
    case M5WrStation.ir:
      for (final i in mine) {
        await _lensTap(t, 'lens-ir-$i');
      }
    case M5WrStation.oil:
      await t.longPressAt(t.getCenter(find.byKey(const ValueKey('lens-jar'))));
      await _pump(t, 400);
      await _lensDrag(t, 'lens-jar');
      if (onSwirl != null) await onSwirl();
      await _lensTap(t, 'lens-mouth');
      for (final i in mine) {
        await _lensTap(t, 'lens-oil-${M5WrOilPart.values[i].name}');
      }
    case M5WrStation.record:
      for (final i in mine) {
        await _lensTap(t, 'lens-entry-$i');
      }
  }
  expect(find.byType(MistakeCard), findsNothing, reason: '$s');
  await t.tap(_label(M5WrLines.close));
  await _pump(t, 400);
  expect(find.byKey(ValueKey('lens-${s.name}')), findsNothing);
}

/// Plays the whole deal right; refuses the coworker.
Future<void> _playAll(WidgetTester t, M5WrDeal d) async {
  for (final (i, site) in d.sites.indexed) {
    await _readLog(t);
    final his = i == d.pushSite;
    if (his && d.push == M5WrPush.charge) await _refuse(t, M5WrLines.coworkerCharge);
    if (site.kind == M5WrKind.lt) {
      await _team(t, M5WrTeam.patrol);
      await _pump(t, 800);
      await _reason(t, M5WrLines.whyRight[M5WrWhy.lt]!);
      continue;
    }
    await _team(t, M5WrTeam.workshop);
    expect(_label(M5WrLines.send), findsOneWidget, reason: 'the slip is up');
    await _test(t);
    for (final s in M5WrStation.values) {
      if (!site.present.contains(s)) continue;
      await _station(t, site, s,
          onSwirl: his && d.push == M5WrPush.water && s == M5WrStation.oil ? () => _refuse(t, M5WrLines.coworkerWater) : null);
    }
    await t.tap(_label(M5WrLines.send));
    await _pump(t, 2200);
    await _reason(t, M5WrLines.whyRight[site.why]!);
  }
}

int _seedWhere(bool Function(M5WrDeal d) f) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => f(m5WrDeal(math.Random(s))));

const _dtrSite = M5WrSite(
  kind: M5WrKind.dtr,
  bushingMarks: [0, 2, 0],
  irLow: 1,
  oilWater: true,
  record: ['সিলিকা জেল বদলানো হয়েছে', 'আগেও একবার খারাপ হয়েছিল', 'নিয়মিত পরিদর্শন — ঠিক আছে', 'আর্থিং পরীক্ষা — ঠিক আছে'],
  recordFind: {1},
);
const _ltSite = M5WrSite(kind: M5WrKind.lt, feeder: 2, why: M5WrWhy.lt);
const _deal1 = M5WrDeal(sites: [_dtrSite, _ltSite, _dtrSite], push: M5WrPush.water, pushSite: 0);

void main() {
  group('rules', () {
    test('deals: two transformer sites + one LT site; 1–4 findings in 2–3 stations; his push fits his site; plays differ', () {
      final seen = <String>{};
      final pushes = <M5WrPush>{};
      for (var s = 0; s < 120; s++) {
        final d = m5WrDeal(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.where((x) => x.kind == M5WrKind.lt), hasLength(1));
        expect(d.sites[d.pushSite].kind, M5WrKind.dtr);
        pushes.add(d.push);
        if (d.push == M5WrPush.water) expect(d.sites[d.pushSite].oilWater, isTrue, reason: 'seed $s: a water-bead jar for him');
        for (final (i, site) in d.sites.indexed) {
          expect(site.record, hasLength(4));
          if (site.kind == M5WrKind.lt) {
            expect(site.findings, isEmpty);
            expect(site.feeder, inInclusiveRange(1, 4));
            expect(site.why, M5WrWhy.lt);
            expect(site.record.where(M5WrLines.recordFind.contains), isEmpty);
            continue;
          }
          expect(site.findings.length, inInclusiveRange(1, 4), reason: 'seed $s site $i');
          expect(site.present.length, inInclusiveRange(2, 3), reason: 'seed $s site $i');
          expect(site.bushingMarks.where((m) => m != 0).length, lessThanOrEqualTo(1));
          for (final f in site.recordFind) {
            expect(M5WrLines.recordFind, contains(site.record[f]));
          }
          for (final (j, e) in site.record.indexed) {
            if (!site.recordFind.contains(j)) expect(M5WrLines.recordRoutine, contains(e));
          }
          switch (site.why) {
            case M5WrWhy.ir:
              expect(site.irLow, isNotNull);
            case M5WrWhy.water:
              expect(site.oilWater, isTrue);
            case M5WrWhy.noCharge:
              expect(d.push == M5WrPush.charge && d.pushSite == i, isTrue, reason: 'only where he pushed a charge');
            case M5WrWhy.lt:
              fail('an LT reason at a transformer site');
            case M5WrWhy.workshop:
              break;
          }
        }
        seen.add('${d.sites.map((x) => '${x.kind.name}${x.findings.toList()..sort((a, b) => a.toString().compareTo(b.toString()))}${x.feeder}').join('|')}|${d.push.name}${d.pushSite}');
      }
      expect(pushes, {M5WrPush.charge, M5WrPush.water});
      expect(seen.length, greaterThan(60));
    });

    test('the team: re-charging is deadly at a transformer site and at the LT site; the wrong team is a slip', () {
      for (final kind in M5WrKind.values) {
        final r = M5WrRun(M5WrDeal(sites: [kind == M5WrKind.dtr ? _dtrSite : _ltSite, _ltSite, _dtrSite], push: M5WrPush.charge, pushSite: 2));
        expect(r.choose(M5WrTeam.workshop), isNull, reason: 'not before the log');
        expect(r.stage, M5WrStage.log);
        r.readLog();
        expect(r.stage, M5WrStage.choose);
        final m = r.choose(M5WrTeam.recharge);
        expect(m, kind == M5WrKind.dtr ? M5WrMistakes.rechargeDtr : M5WrMistakes.rechargeLt);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
      }
      final a = M5WrRun(_deal1)..readLog();
      expect(a.choose(M5WrTeam.patrol), M5WrMistakes.patrolAtDtr);
      expect(a.stage, M5WrStage.choose);
      expect(a.choose(M5WrTeam.workshop), isNull);
      expect(a.stage, M5WrStage.proof);
      expect(a.caught, isNot(contains(M5WrLines.caughtTeam)), reason: 'not first time');
      final b = M5WrRun(M5WrDeal(sites: const [_ltSite, _dtrSite, _dtrSite], push: M5WrPush.water, pushSite: 1))..readLog();
      expect(b.choose(M5WrTeam.workshop), M5WrMistakes.workshopAtLt);
      expect(b.choose(M5WrTeam.patrol), isNull);
      expect(b.roundDone, isTrue);
      expect(b.slips, 1);
    });

    test('the proof: bushings before 0 V are deadly; the cloth first; a clean item pinned is a slip; oil gestures in order; পাঠান waits for every finding', () {
      final dead = M5WrRun(_deal1)
        ..readLog()
        ..choose(M5WrTeam.workshop);
      final m = dead.openStation(M5WrStation.bushing);
      expect(m, M5WrMistakes.noTest);
      expect(m!.deadly, isTrue);

      final r = M5WrRun(_deal1)
        ..readLog()
        ..choose(M5WrTeam.workshop);
      expect(r.caught, contains(M5WrLines.caughtTeam));
      expect(r.send(), M5WrMistakes.missingProof, reason: 'nothing pinned');
      r.test();
      expect(r.openStation(M5WrStation.bushing), isNull);
      expect(r.caught, contains(M5WrLines.caughtTest));
      expect(r.openStation(M5WrStation.ir), isNull, reason: 'one at a time');
      expect(r.open, M5WrStation.bushing);
      expect(r.canPin(const M5WrProof(M5WrStation.bushing, 1)), isFalse, reason: 'dusty');
      expect(r.pin(const M5WrProof(M5WrStation.bushing, 1)), isNull);
      expect(r.pinned, isEmpty);
      expect(r.rub(), isTrue);
      expect(r.pin(const M5WrProof(M5WrStation.bushing, 0)), M5WrMistakes.cleanBushing);
      expect(r.pin(const M5WrProof(M5WrStation.bushing, 1)), isNull);
      expect(r.pinned, {const M5WrProof(M5WrStation.bushing, 1)});
      expect(r.send(), isNull, reason: 'a close-up is open');
      r.closeStation();

      r.openStation(M5WrStation.ir);
      expect(r.pin(const M5WrProof(M5WrStation.ir, 0)), M5WrMistakes.highIr);
      expect(r.pin(const M5WrProof(M5WrStation.ir, 1)), isNull);
      r.closeStation();

      r.openStation(M5WrStation.oil);
      expect(r.oil(1), isFalse, reason: 'the sun first');
      expect(r.oil(2), isFalse);
      expect(r.pin(M5WrProof.oil(M5WrOilPart.water)), isNull);
      expect(r.pinned.length, 2);
      expect(r.oil(0), isTrue);
      expect(r.oil(0), isFalse);
      expect(r.oil(1), isTrue);
      expect(r.canPin(M5WrProof.oil(M5WrOilPart.water)), isFalse, reason: 'every jar takes all three');
      expect(r.oil(2), isTrue);
      expect(r.oilStep, 3);
      expect(r.pin(M5WrProof.oil(M5WrOilPart.smell)), M5WrMistakes.cleanOilSmell, reason: 'the card names only the smell');
      expect(r.pin(M5WrProof.oil(M5WrOilPart.water)), isNull);
      r.closeStation();

      expect(r.send(), M5WrMistakes.missingProof, reason: 'the record entry is left');
      r.openStation(M5WrStation.record);
      expect(r.pin(const M5WrProof(M5WrStation.record, 0)), M5WrMistakes.routineRecord);
      expect(r.pin(const M5WrProof(M5WrStation.record, 1)), isNull);
      r.closeStation();
      expect(r.missing, isEmpty);
      expect(r.send(), isNull);
      expect(r.sent, isTrue);
      expect(r.roundDone, isTrue);
      expect(r.caught, isNot(contains(M5WrLines.caughtProof)), reason: 'clean items were pinned');
      expect(r.slips, 6);
      expect(r.percent, 10);
      r.next();
      expect(r.index, 1);
      expect(r.stage, M5WrStage.log);
      expect(r.tested, isFalse);
      expect(r.pinned, isEmpty);
    });

    test('a clean transformer site: every finding pinned → sent, ◆ thorough, "all proof" caught; listening to the water myth is a slip', () {
      final r = M5WrRun(_deal1)
        ..readLog()
        ..choose(M5WrTeam.workshop)
        ..test();
      for (final p in _dtrSite.findings) {
        r.openStation(p.station);
        if (p.station == M5WrStation.bushing) r.rub();
        if (p.station == M5WrStation.oil) {
          r
            ..oil(0)
            ..oil(1)
            ..oil(2);
        }
        expect(r.pin(p), isNull, reason: '$p');
        r.closeStation();
      }
      expect(r.send(), isNull);
      expect(r.thorough, isTrue);
      expect(r.caught, containsAll([M5WrLines.caughtTeam, M5WrLines.caughtTest, M5WrLines.caughtProof]));
      expect(r.listenWater(), M5WrMistakes.waterMyth);
      expect(r.slips, 1);
      expect(M5WrMistakes.waterMyth.deadly, isFalse);
    });

    test('a false oil pin names only the part pinned (never denies what another part of the jar shows)', () {
      final cards = {for (final p in M5WrOilPart.values) p: M5WrMistakes.falsePin(M5WrProof.oil(p))};
      expect(cards.values.toSet(), hasLength(3));
      // The words each part is about; a card may name only its own.
      const words = {
        M5WrOilPart.colour: ['কালো', 'কার্বন'],
        M5WrOilPart.water: ['জল'],
        M5WrOilPart.smell: ['গন্ধ'],
      };
      for (final p in M5WrOilPart.values) {
        final text = cards[p]!.textBn;
        expect(words[p]!.any(text.contains), isTrue, reason: '$p: $text');
        for (final other in M5WrOilPart.values.where((o) => o != p)) {
          for (final w in words[other]!) {
            expect(text.contains(w), isFalse, reason: '$p card says "$w": $text');
          }
        }
        expect(M5WrMistakes.all, contains(cards[p]));
        expect(cards[p]!.deadly, isFalse);
      }
      expect(M5WrMistakes.falsePin(const M5WrProof(M5WrStation.bushing, 0)), M5WrMistakes.cleanBushing);
      expect(M5WrMistakes.falsePin(const M5WrProof(M5WrStation.ir, 2)), M5WrMistakes.highIr);
      expect(M5WrMistakes.falsePin(const M5WrProof(M5WrStation.record, 3)), M5WrMistakes.routineRecord);
    });

    test('the re-charge is the same act at both kinds of site: "as is", and the LT log ends on the blowing feeder still in', () {
      expect(M5WrLines.recharge, contains('এ অবস্থায়'), reason: 'as is: the same act at both kinds of site');
      expect(M5WrLines.logLtStillIn(3), contains('3'));
      expect(M5WrLines.logLtStillIn(3), contains('এখনো লাগানো'));
      expect(M5WrMistakes.rechargeLt.textBn, contains('ফিডার লাগানো অবস্থায়'));
      expect(M5WrMistakes.rechargeLt.deadly, isTrue);
      expect(M5WrMistakes.rechargeDtr.deadly, isTrue);
    });

    test('team rows: every team, in a dealt order; rows differ', () {
      final rows = <String>{};
      for (var s = 0; s < 40; s++) {
        final row = m5WrTeamRow(math.Random(s));
        expect(row.toSet(), M5WrTeam.values.toSet());
        rows.add(row.map((x) => x.name).join(','));
      }
      expect(rows.length, 6, reason: 'every order shows up');
    });

    test('English digits only; no পানি; every mistake has its picture; three deadly; keys unique', () {
      final all = <String>[
        M5WrLines.intro,
        ...M5WrLines.rounds,
        ...M5WrLines.tasks,
        ...M5WrLines.allWhyRight,
        ...M5WrLines.whyQ.values,
        ...M5WrLines.myths,
        ...M5WrLines.recordFind,
        ...M5WrLines.recordRoutine,
        for (final s in [M5WrLines.coworkerCharge, M5WrLines.coworkerWater]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in M5WrMistakes.all) m.textBn,
        for (var f = 1; f <= 4; f++) M5WrLines.logLtBlew(f),
        for (var f = 1; f <= 4; f++) M5WrLines.logLtStillIn(f),
        M5WrLines.logAllOpen,
        M5WrLines.allSet,
        M5WrLines.fail,
        M5WrLines.heldCharge,
        M5WrLines.heldWater,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5WrMistakes.all.where((m) => m.deadly).toSet(), {M5WrMistakes.rechargeDtr, M5WrMistakes.rechargeLt, M5WrMistakes.noTest});
      expect(M5WrMistakes.all.map((m) => m.key).toSet(), hasLength(M5WrMistakes.all.length));
      for (final m in M5WrMistakes.all) {
        expect(m.key, startsWith('5.8/m5_workshop_referral/'));
        expect(m.art, startsWith('assets/game/art/m5_workshop_referral/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // Every picture in the folder is used.
      final used = M5WrMistakes.all.map((m) => m.art.split('/').last).toSet();
      final files = Directory('assets/game/art/m5_workshop_referral').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m5WorkshopReferralPacks.keys, ['do_5_8_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...M5WrLines.allWhyRight, ...M5WrLines.myths]);
      expect(M5WrLines.myths.toSet().intersection(M5WrLines.allWhyRight.toSet()), isEmpty);
      for (final w in M5WrWhy.values) {
        final right = M5WrLines.whyRight[w]!;
        expectLibrary('why $w', right, M5WrLines.myths);
        expect(M5WrLines.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, M5WrLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final s in [M5WrLines.coworkerCharge, M5WrLines.coworkerWater]) {
        expectSameLength('choice ${s.line}', [...s.right, ...s.wrong]);
        expectLibrary('choice ${s.line}', s.right, s.wrong, minRight: 3);
        expect(s.asks, contains('কী করবেন?'));
      }
    });

    test('the coworker: his exit is recorded; the new pushes are listed for recording; the water push is lesson 5.8 myth 2 word for word', () {
      expect(LearnVoice.resolve(M5WrLines.coworkerExit, rival: true), isNotNull);
      for (final s in [M5WrLines.coworkerCharge, M5WrLines.coworkerWater]) {
        for (final l in s.recordedLines) {
          expect(LearnVoice.resolve(l, rival: true) != null || M5WrLines.rivalLinesMissing.contains(l), isTrue, reason: l);
        }
      }
      expect(M5WrLines.rivalLinesMissing, [M5WrLines.chargePush, M5WrLines.waterPush]);
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l58 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '5.8');
      final myths = ((l58['content'] as Map<String, dynamic>)['myth_buster'] as Map<String, dynamic>)['myths'] as List<dynamic>;
      expect(myths.map((m) => (m as Map<String, dynamic>)['myth']), contains(M5WrLines.waterPush));
    });

    test('tap areas: apart, on the 360-wide scene, under the header, above the controls, clear of the guide', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M5WrGeo.forScene(h, 0);
        final rects = [g.logHit, g.testerHit, for (final s in M5WrStation.values) g.stationHit(s)];
        for (final (i, r) in rects.indexed) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h #$i');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h #$i');
          expect(r.top, greaterThan(120), reason: 'h $h #$i below the header');
          expect(r.bottom, lessThan(g.groundY), reason: 'h $h #$i above the controls');
          // The corner guide's touch square (bottom-right 116 dp of its 232-wide box).
          expect(r.right > 100 && r.left < 236 && r.bottom > g.groundY - 90, isFalse, reason: 'h $h #$i under the guide');
          expect(r.height, greaterThanOrEqualTo(40), reason: 'h $h #$i a finger fits');
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final x = rects[i].intersect(rects[j]);
            expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
          }
        }
      }
      // The close-ups' regions: inside the box, apart within a station.
      final box = Offset.zero & M5WrLens.size;
      final groups = [
        [for (var i = 0; i < 3; i++) M5WrLens.bushing(i)],
        [for (var i = 0; i < 3; i++) M5WrLens.irRow(i)],
        [for (final p in M5WrOilPart.values) M5WrLens.oilPart(p)],
        [for (var i = 0; i < 4; i++) M5WrLens.entry(i)],
      ];
      for (final g in groups) {
        for (final r in g) {
          expect(box.contains(r.topLeft) && box.contains(r.bottomRight - const Offset(0.01, 0.01)), isTrue, reason: '$r');
        }
        for (var i = 0; i < g.length; i++) {
          for (var j = i + 1; j < g.length; j++) {
            final x = g[i].intersect(g[j]);
            expect(x.width <= 0 || x.height <= 0, isTrue, reason: '${g[i]} / ${g[j]}');
          }
        }
      }
    });
  });

  group('team labels', () {
    // The real Bangla font (the test font draws every code point a full em wide).
    setUpAll(() async {
      final loader = FontLoader('Noto Sans Bengali');
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    });

    test('every team label fits its 104-px button at 1.3× text', () {
      for (final team in M5WrTeam.values) {
        final tp = TextPainter(
          text: TextSpan(text: M5WrLines.teamLabel(team), style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15, color: Colors.white)),
          textDirection: TextDirection.ltr,
          textScaler: const TextScaler.linear(1.3),
          maxLines: 1,
        )..layout();
        expect(tp.width, lessThanOrEqualTo(104 - 10), reason: '${M5WrLines.teamLabel(team)}: ${tp.width}');
        tp.dispose();
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

    testWidgets('the guide comes first: a tap does not skip him; then the log (no team before it)', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(home: M5WorkshopReferralPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)),
        ),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5WrLines.workshop), findsNothing, reason: 'the log first');
      await _readLog(t);
      expect(_label(M5WrLines.workshop), findsOneWidget);
      expect(_label(M5WrLines.patrol), findsOneWidget);
      expect(_label(M5WrLines.recharge), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M5WrLines.askLog)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final push in M5WrPush.values) {
      testWidgets('flow (${push.name} push): logs, teams, tester, proof pinned, sent; he is refused; right reasons → pass', (t) async {
        final seed = _seedWhere((d) => d.push == push);
        final deal = m5WrDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _playAll(t, deal);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.8/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.8/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(push == M5WrPush.charge ? M5WrLines.caughtCharge : M5WrLines.caughtWater), findsOneWidget);
        expect(find.text(M5WrLines.caughtProof), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (the wrong team) shows its card; the same site goes on after it', (t) async {
      final seed = _seedWhere((d) => !(d.push == M5WrPush.charge && d.pushSite == 0));
      final deal = m5WrDeal(math.Random(seed));
      final wrong = deal.sites[0].kind == M5WrKind.dtr ? M5WrTeam.patrol : M5WrTeam.workshop;
      final card = deal.sites[0].kind == M5WrKind.dtr ? M5WrMistakes.patrolAtDtr : M5WrMistakes.workshopAtLt;
      final c = await _open(t, seed);
      await _readLog(t);
      await _team(t, wrong);
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(card.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M5WrLines.teamLabel(wrong)), findsOneWidget, reason: 'the same site');
      expect(c.read(gameSaveProvider).mistakes.single.key, card.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => !(d.push == M5WrPush.charge && d.pushSite == 0));
      final deal = m5WrDeal(math.Random(seed));
      final wrong = deal.sites[0].kind == M5WrKind.dtr ? M5WrTeam.patrol : M5WrTeam.workshop;
      final c = await _open(t, seed);
      await _readLog(t);
      for (var i = 0; i < 3; i++) {
        await _team(t, wrong);
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

    testWidgets('a team button opens big first: no decision on touch; ✕ sets it aside, ✓ decides', (t) async {
      final seed = _seedWhere((d) => !(d.push == M5WrPush.charge && d.pushSite == 0));
      final c = await _open(t, seed);
      await _readLog(t);
      await t.tap(_label(M5WrLines.teamLabel(M5WrTeam.recharge)));
      await _pump(t, 100);
      expect(find.byKey(const ValueKey('choice-confirm')), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a touch is not a decision');
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('choice-confirm')), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byWidgetPredicate((w) => w is CardAside && w.aside), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _team(t, M5WrTeam.recharge);
      await _pump(t, 200);
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'set aside, it still opens; ✓ decides');
      await _close(t, c);
    });

    testWidgets('re-charging: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => !(d.push == M5WrPush.charge && d.pushSite == 0));
      final deal = m5WrDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _readLog(t);
      await _team(t, M5WrTeam.recharge);
      await _pump(t, 200);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, (deal.sites[0].kind == M5WrKind.dtr ? M5WrMistakes.rechargeDtr : M5WrMistakes.rechargeLt).key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the bushings before the tester: freeze, then the card', (t) async {
      final seed = _seedWhere((d) => d.sites[0].kind == M5WrKind.dtr && !(d.push == M5WrPush.charge && d.pushSite == 0));
      final c = await _open(t, seed);
      await _readLog(t);
      await _team(t, M5WrTeam.workshop);
      await _tapAt(t, _geo.stationHit(M5WrStation.bushing).center);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('lens-bushing')), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5WrMistakes.noTest.key);
      await _close(t, c);
    });

    testWidgets('a tap on the tester does not test: it must be held', (t) async {
      final seed = _seedWhere((d) => d.sites[0].kind == M5WrKind.dtr && !(d.push == M5WrPush.charge && d.pushSite == 0));
      final c = await _open(t, seed);
      await _readLog(t);
      await _team(t, M5WrTeam.workshop);
      await _tapAt(t, _geo.testerHit.center);
      expect(find.text(M5WrLines.testerDead), findsNothing);
      await _test(t);
      await _openStation(t, M5WrStation.bushing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to the charge push = deadly: freeze, then the card', (t) async {
      final seed = _seedWhere((d) => d.push == M5WrPush.charge && d.pushSite == 0);
      final c = await _open(t, seed);
      await _readLog(t);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M5WrLines.coworkerCharge.wrong);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5WrMistakes.rechargeDtr.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fast play: the team waits for the coworker; he cuts in before the proof opens', (t) async {
      final seed = _seedWhere((d) => d.push == M5WrPush.charge && d.pushSite == 0);
      final c = await _open(t, seed);
      await _readLog(t);
      // At once: well inside his 1.2–2.4 s timer. The tap only opens the
      // team's card; its ✓ is the decision that waits for him.
      await t.tap(_label(M5WrLines.workshop));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'the preview is not the decision');
      expect(await confirmChoice(t), isTrue);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_label(M5WrLines.send), findsNothing, reason: 'the decision waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, M5WrLines.coworkerCharge.right);
      await _pump(t, 2600);
      await _team(t, M5WrTeam.workshop);
      expect(_label(M5WrLines.send), findsOneWidget);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to the water myth after the swirl = a slip; the beads still go on the slip', (t) async {
      final seed = _seedWhere((d) => d.push == M5WrPush.water && d.pushSite == 0);
      final c = await _open(t, seed);
      await _readLog(t);
      await _team(t, M5WrTeam.workshop);
      await _test(t);
      await _openStation(t, M5WrStation.oil);
      await t.longPressAt(t.getCenter(find.byKey(const ValueKey('lens-jar'))));
      await _pump(t, 400);
      await _lensDrag(t, 'lens-jar');
      // Straight on to the sniff: it waits for him.
      await t.tapAt(t.getCenter(find.byKey(const ValueKey('lens-mouth'))));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickWrong(t, M5WrLines.coworkerWater.wrong);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(M5WrMistakes.waterMyth.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _lensTap(t, 'lens-mouth');
      await _lensTap(t, 'lens-oil-water');
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5WrMistakes.waterMyth.key);
      await _close(t, c);
    });

    testWidgets('a clean item pinned is a slip; পাঠান with a finding left is a slip', (t) async {
      final seed = _seedWhere((d) =>
          d.sites[0].kind == M5WrKind.dtr && d.pushSite != 0 && d.sites[0].irLow != null);
      final deal = m5WrDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _readLog(t);
      await _team(t, M5WrTeam.workshop);
      await _test(t);
      await _openStation(t, M5WrStation.ir);
      final clean = [0, 1, 2].firstWhere((i) => i != deal.sites[0].irLow);
      await _lensTap(t, 'lens-ir-$clean');
      expect(find.text(M5WrMistakes.highIr.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tap(_label(M5WrLines.close));
      await _pump(t, 400);
      await t.tap(_label(M5WrLines.send));
      await _pump(t, 600);
      expect(find.text(M5WrMistakes.missingProof.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [M5WrMistakes.highIr.key, M5WrMistakes.missingProof.key]);
      await _close(t, c);
    });

    testWidgets('the praise window takes no touch: a scene tap after the LT patrol is no slip', (t) async {
      final seed = _seedWhere((d) => d.sites[0].kind == M5WrKind.lt);
      final c = await _open(t, seed);
      await _readLog(t);
      await _team(t, M5WrTeam.patrol);
      for (var k = 0; k < 6; k++) {
        await t.tapAt(_geo.logHit.center * _k);
        await t.pump(const Duration(milliseconds: 250));
      }
      expect(find.text(M5WrLines.logTitle), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M5WrLines.whyRight[M5WrWhy.lt]!);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a tap on the log, ঠিক আছে; a sweep over the three teams, over the tester and stations; the hold after a tester tap', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.sites[0].kind == M5WrKind.dtr && d.pushSite != 0);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the log');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the one way forward');
      await _tapAt(t, _geo.logHit.center);
      expect(scene().showing, isFalse, reason: 'a touch hides it');
      await t.tap(_label(M5WrLines.logOk));
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the choice');
      expect(scene().debugOptions, hasLength(3), reason: 'every team');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _team(t, M5WrTeam.workshop);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the proof');
      expect(scene().debugOptions, hasLength(5), reason: 'the tester and the four stations alike');
      expect(scene().debugFrame?.ripple, isNull);
      await _tapAt(t, _geo.testerHit.center);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'the hold after a tap');
      expect(scene().debugOptions, isEmpty);
      await _test(t);
      await _openStation(t, M5WrStation.ir);
      await _pump(t, 9000);
      expect(scene().debugOptions, hasLength(3), reason: 'every row, near 0 or not');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
