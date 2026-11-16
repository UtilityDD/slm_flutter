// Lesson 7.6 (ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন), কাজ 2 "ক্ষতি হলে কার
// কাছে?": the rules (a damaged item to the supervisor, never to the coworker,
// the shop, the cloth or the bag; torn gloves or cut webbing bagged or worked
// in = deadly; a cracked helmet or split sole bagged = slip; a muddy whole
// glove or a dusty helmet needs no report — the cloth, or back on for the
// helmet; the diary written only after a report, its absence at the work
// decision a slip; go with a spare, stop with none, anything else a slip), the
// deal, the libraries, the drawn places, and the level in the shell: the guide
// first, full clean plays with a reason pick and the coworker refused, the
// deadly freeze, three slips, listening is a slip, the work pin waits for him,
// and the gesture hand shows how (never what).
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
import 'package:slm_flutter/features/game/m7_ppe_mishap_route.dart';
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
  rungId: '7.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7PpeMishapRoutePacks['do_7_6_b']!;
typedef L = M7PpeMishapRouteLines;
typedef Mk = M7PpeMishapRouteMistakes;
typedef K = M7PpeKind;

/// The new art is not in pubspec's bundle in tests until the director wires
/// it: tests read it from disk when the bundle does not have it.
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

Future<bool> _pumpUntil(WidgetTester t, bool Function() ok, {int maxMs = 10000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
}

bool _has(Finder f) => f.evaluate().isNotEmpty;
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
M7PpeGeo get _geo => M7PpeGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M7PpeRun get _live => M7PpeMishapRouteProbe.run!;

/// The reason deck of the step just done: pick its right card.
Future<void> _reason(WidgetTester t) async {
  expect(await _pumpUntil(t, () => _has(find.byType(ChoiceDeck))), isTrue, reason: 'the reason deck');
  final w = _live.why!;
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[w]!);
  await _pump(t, 1800);
}

Rect _zone(M7PpeDest d) => switch (d) {
      M7PpeDest.supervisor => M7PpeGeo.supervisor,
      M7PpeDest.coworker => M7PpeGeo.coworker,
      M7PpeDest.shop => M7PpeGeo.shop,
      M7PpeDest.cloth => M7PpeGeo.cloth,
      M7PpeDest.keep => _geo.bag,
    };

/// Carry the item in his hands to a place.
Future<void> _carry(WidgetTester t, M7PpeDest d) async {
  final from = _geo.hand;
  final to = _zone(d).center;
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

/// Drag the work pin onto a docket mark and hold it there.
Future<void> _pin(WidgetTester t, M7PpeWork w, {int holdMs = kM7HoldMs + 300}) async {
  final from = M7PpeGeo.pinHome;
  final to = (w == M7PpeWork.go ? M7PpeGeo.goMark : M7PpeGeo.stopMark).center;
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await _pump(t, holdMs);
  await g.up();
  await _pump(t, 400);
}

Future<void> _diary(WidgetTester t) async {
  final g = await t.startGesture(_geo.diary.center * _k);
  await _pump(t, kM7HoldMs + 300);
  await g.up();
  await _pump(t, 300);
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 600);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7PpeMishapRoutePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M7PpeDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m7PpeDeal(math.Random(s))));

/// The cutscene is over: the item is in his hands.
Future<void> _toRoute(WidgetTester t) async {
  expect(await _pumpUntil(t, () => _live.stage == M7PpeStage.route, maxMs: 5000), isTrue, reason: 'the cutscene ends');
  await _pump(t, 300);
}

Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
  await _pump(t, 600);
  await _pickRight(t, L.coworkerScript.right);
  await _pump(t, 2600);
}

/// One whole mishap, played cleanly: the right hands, the record on a report,
/// the decision the lesson wants, every reason picked, him refused.
Future<void> _playClean(WidgetTester t) async {
  await _toRoute(t);
  final r = _live;
  final idx = r.index;
  final k = r.kind;
  final hisTurn = idx == r.deal.coworkerAt;
  if (k.damaged) {
    await _carry(t, M7PpeDest.supervisor);
    await _reason(t);
    expect(_live.stage, M7PpeStage.decide);
    if (hisTurn) await _refuse(t);
    await _diary(t);
    if (_live.why != null) await _reason(t);
    expect(_live.recorded, isTrue);
    await _pin(t, r.incident.spare ? M7PpeWork.go : M7PpeWork.stop);
    await _reason(t);
  } else {
    await _carry(t, k == K.glovesMuddy ? M7PpeDest.cloth : M7PpeDest.keep);
    await _reason(t);
    if (hisTurn) await _refuse(t);
    await _pin(t, M7PpeWork.go);
    await _pump(t, 1600);
  }
  expect(_live.index, idx + 1 > 3 ? 3 : idx + 1);
}

M7PpeDeal _dealOf(List<M7PpeIncident> inc, {int coworkerAt = 0}) => M7PpeDeal(
      incidents: inc,
      coworkerAt: coworkerAt,
      supervisorName: 'রাজেশ',
      coworkerName: 'বিকাশ',
      badgeRight: false,
      date: '15/11',
    );

M7PpeRun _runOf(M7PpeIncident first) {
  final r = M7PpeRun(_dealOf([first, const M7PpeIncident(K.helmetDusty), const M7PpeIncident(K.glovesMuddy)]));
  r.cutDone();
  return r;
}

/// A run of one damaged item already reported (its reason paid), at the work decision.
M7PpeRun _reported(K kind, {bool spare = true}) {
  final r = _runOf(M7PpeIncident(kind, spare: spare));
  expect(r.route(M7PpeDest.supervisor).kind, M7PpeStepKind.right);
  r.paid();
  return r;
}

void main() {
  group('rules', () {
    test('deals: three different items, two or three real damages, a clean one only gloves or helmet, spare and coworker vary; plays differ', () {
      final seen = <String>{};
      var three = 0, spares = 0, damagedN = 0;
      final at = <int>{}, names = <String>{}, cnames = <String>{};
      final items = <M7PpeItem>{};
      for (var s = 0; s < 400; s++) {
        final d = m7PpeDeal(math.Random(s));
        expect(d.incidents, hasLength(3));
        expect(d.incidents.map((i) => i.kind.item).toSet(), hasLength(3), reason: 'different items');
        expect(d.damages, inInclusiveRange(2, 3));
        if (d.damages == 3) three++;
        for (final i in d.incidents) {
          items.add(i.kind.item);
          if (i.kind.damaged) {
            damagedN++;
            if (i.spare) spares++;
          } else {
            expect(i.spare, isFalse);
            expect(i.kind.item == M7PpeItem.gloves || i.kind.item == M7PpeItem.helmet, isTrue);
          }
        }
        at.add(d.coworkerAt);
        names.add(d.supervisorName);
        cnames.add(d.coworkerName);
        expect(RegExp(r'^\d{1,2}/\d{1,2}$').hasMatch(d.date), isTrue, reason: d.date);
        seen.add(d.incidents.map((i) => '${i.kind.index}${i.spare ? 's' : ''}').join(',') + d.coworkerAt.toString());
      }
      expect(three, inInclusiveRange(60, 140), reason: 'about a quarter have no clean mishap');
      expect(spares / damagedN, inInclusiveRange(0.45, 0.65));
      expect(at, {0, 1, 2});
      expect(names, hasLength(L.supervisorNames.length));
      expect(cnames, hasLength(L.coworkerNames.length));
      expect(items, M7PpeItem.values.toSet());
      expect(seen.length, greaterThan(60));
    });

    test('a damaged item: to the supervisor is right (the report, its reason); coworker and cloth, the shop, the bag are slips and it stays', () {
      for (final k in [K.helmetCracked, K.bootSplit]) {
        final r = _runOf(M7PpeIncident(k));
        expect(r.route(M7PpeDest.coworker).mistake, Mk.wrongHands);
        expect(r.route(M7PpeDest.cloth).mistake, Mk.wrongHands);
        expect(r.route(M7PpeDest.shop).mistake, Mk.shopBuy);
        expect(r.route(M7PpeDest.keep).mistake, Mk.bagDamaged);
        expect(r.slips, 4);
        expect((r.stage, r.reported, r.roundDone), (M7PpeStage.route, false, false), reason: 'a slip: the item stays in his hands');
        final s = r.route(M7PpeDest.supervisor);
        expect(s.kind, M7PpeStepKind.right);
        expect((r.reported, r.why, r.roundDone), (true, M7PpeWhy.report, true));
        expect(r.route(M7PpeDest.supervisor).kind, M7PpeStepKind.stay, reason: 'the reason first');
      }
    });

    test('torn gloves or cut webbing in the bag = deadly (R10, R11); the play ends', () {
      final g = _runOf(const M7PpeIncident(K.glovesTorn));
      final s = g.route(M7PpeDest.keep);
      expect((s.kind, s.mistake), (M7PpeStepKind.deadly, Mk.tornGlovesKept));
      expect(g.ended, isTrue);
      expect(g.passed, isFalse);
      final h = _runOf(const M7PpeIncident(K.harnessNicked));
      expect(h.route(M7PpeDest.keep).mistake, Mk.cutHarnessKept);
      expect(h.deadly, isNotNull);
      expect(Mk.deadlyKeys, [Mk.tornGlovesKept.key, Mk.cutHarnessKept.key]);
      // Other wrong hands for them are slips, never deadly.
      final w = _runOf(const M7PpeIncident(K.glovesTorn));
      expect(w.route(M7PpeDest.shop).mistake, Mk.shopBuy);
      expect(w.deadly, isNull);
    });

    test('dirty but whole: the cloth is right for gloves and helmet; back on is right only for the dusty helmet; a report or a hand-over is a needless-report slip', () {
      final mud = _runOf(const M7PpeIncident(K.glovesMuddy));
      expect(mud.route(M7PpeDest.keep).mistake, Mk.muddyGloves);
      expect(mud.route(M7PpeDest.supervisor).mistake, Mk.needlessReport);
      expect(mud.route(M7PpeDest.coworker).mistake, Mk.needlessReport);
      expect(mud.route(M7PpeDest.shop).mistake, Mk.needlessReport);
      expect(mud.route(M7PpeDest.cloth).kind, M7PpeStepKind.right);
      expect((mud.cleaned, mud.why, mud.reported), (true, M7PpeWhy.clean, false));
      final dust = _runOf(const M7PpeIncident(K.helmetDusty));
      expect(dust.route(M7PpeDest.keep).kind, M7PpeStepKind.right);
      expect(dust.why, M7PpeWhy.backOn);
      expect(dust.caught, [L.caughtBackOn]);
      final wipe = _runOf(const M7PpeIncident(K.helmetDusty));
      expect(wipe.route(M7PpeDest.cloth).kind, M7PpeStepKind.right);
      expect(wipe.why, M7PpeWhy.clean);
      final rep = _runOf(const M7PpeIncident(K.helmetDusty));
      expect(rep.route(M7PpeDest.supervisor).mistake, Mk.needlessReport);
      expect(rep.slips, 1);
    });

    test('the diary: nothing before a report; once after it; the first record asks its reason, later ones do not', () {
      final none = _runOf(const M7PpeIncident(K.helmetDusty));
      none.route(M7PpeDest.keep);
      none.paid();
      expect(none.record(), isNull, reason: 'no report: nothing to write');
      expect(none.recorded, isFalse);
      final r = _reported(K.bootSplit);
      expect(r.record()!.kind, M7PpeStepKind.right);
      expect((r.recorded, r.why), (true, M7PpeWhy.diary));
      expect(r.paid(), M7PpePaid.stayDecide);
      expect(r.record(), isNull, reason: 'once');
      expect(r.caught, contains(L.caughtDiary));
      // The next mishap's record (a later report) has no reason.
      final both = M7PpeRun(_dealOf([const M7PpeIncident(K.bootSplit), const M7PpeIncident(K.helmetCracked, spare: true), const M7PpeIncident(K.glovesMuddy)]));
      both.cutDone();
      both.route(M7PpeDest.supervisor);
      both.paid();
      both.record();
      both.paid();
      both.decide(M7PpeWork.stop);
      both.paid();
      expect(both.index, 1);
      both.cutDone();
      both.route(M7PpeDest.supervisor);
      both.paid();
      expect(both.record()!.kind, M7PpeStepKind.rightDone);
      expect(both.roundDone, isFalse);
    });

    test('the work decision, with a spare: go is right (after the record), stop is a needless stop; with none: stop is right, go is deadly (gloves, harness) or a slip (helmet, sole)', () {
      final a = _reported(K.helmetCracked);
      expect(a.replyLine, L.replySpare);
      expect(a.spareInHand, isTrue);
      expect(a.decide(M7PpeWork.stop).mistake, Mk.needlessStop);
      expect(a.decide(M7PpeWork.go).mistake, Mk.noRecord, reason: 'a report with no record');
      expect(a.decide(M7PpeWork.go).kind, M7PpeStepKind.right, reason: 'the record slip is charged once');
      expect((a.why, a.slips), (M7PpeWhy.goNew, 2));
      expect(a.paid(), M7PpePaid.nextIncident);
      final b = _reported(K.bootSplit, spare: false);
      expect(b.replyLine, L.replyNone);
      expect(b.decide(M7PpeWork.go).mistake, Mk.workNoSpare);
      b.record();
      b.paid();
      expect(b.decide(M7PpeWork.stop).kind, M7PpeStepKind.right);
      expect(b.why, M7PpeWhy.stop);
      expect(b.caught, containsAll([L.caughtReport, L.caughtDiary, L.caughtStop]));
      for (final (k, m) in [(K.glovesTorn, Mk.tornGlovesKept), (K.harnessNicked, Mk.cutHarnessKept)]) {
        final d = _reported(k, spare: false);
        final s = d.decide(M7PpeWork.go);
        expect((s.kind, s.mistake), (M7PpeStepKind.deadly, m));
        expect(d.ended, isTrue);
      }
      // With a spare the same items are fine to work in.
      final ok = _reported(K.glovesTorn);
      ok.record();
      ok.paid();
      expect(ok.decide(M7PpeWork.go).kind, M7PpeStepKind.right);
    });

    test('a clean mishap: go is right with no reason (the next one at once); stop is a needless stop', () {
      final r = _runOf(const M7PpeIncident(K.glovesMuddy));
      r.route(M7PpeDest.cloth);
      r.paid();
      expect(r.decide(M7PpeWork.stop).mistake, Mk.needlessStop);
      expect(r.decide(M7PpeWork.go).kind, M7PpeStepKind.rightDone);
      expect((r.index, r.stage, r.roundDone), (1, M7PpeStage.cut, false));
      expect(r.afterAdvance(), M7PpePaid.nextIncident);
      expect(r.caught, containsAll([L.caughtClean, L.caughtGo]));
    });

    test('three mishaps end the play: pass 100, 85 per slip, struck out at 3; listening is a slip, never deadly (X2/B1)', () {
      final r = M7PpeRun(_dealOf([const M7PpeIncident(K.glovesMuddy), const M7PpeIncident(K.helmetDusty), const M7PpeIncident(K.bootSplit)]));
      for (var i = 0; i < 2; i++) {
        r.cutDone();
        r.route(i == 0 ? M7PpeDest.cloth : M7PpeDest.keep);
        r.paid();
        expect(r.decide(M7PpeWork.go).kind, M7PpeStepKind.rightDone);
      }
      r.cutDone();
      r.route(M7PpeDest.supervisor);
      r.paid();
      r.record();
      r.paid();
      r.decide(M7PpeWork.stop);
      expect(r.paid(), M7PpePaid.done);
      expect((r.done, r.passed, r.percent), (true, true, 100));
      final s = _runOf(const M7PpeIncident(K.glovesMuddy));
      expect(s.listen(), Mk.listen);
      expect(Mk.listen.deadly, isFalse);
      s.listen();
      s.listen();
      expect(s.percent, 55);
      s.listen();
      expect(s.percent, 40);
    });

    test('English digits only; jol not pani; no mrito; nukta as base + ়; mistake pictures all exist and all used; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        ...L.crewLines,
        for (final i in M7PpeItem.values) L.itemName(i),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworkerScript.recordedLines,
        ...L.coworkerScript.right,
        ...L.coworkerScript.wrong,
        ...L.coworkerScript.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.deadlyWord,
        L.nearMissWord,
        for (final m in Mk.all) m.textBn,
        M7PpeSigns.glove,
        M7PpeSigns.helmetIs,
        M7PpeSigns.bootIs,
        M7PpeSigns.go,
        M7PpeSigns.stop,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp('(?<![ঀ-৿])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'nukta as base + ় : $l');
      }
      expect(M7PpeSigns.glove, 'IS 4770 · টাইপ 4');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.6/m7_ppe_mishap_route/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m7_ppe_mishap_route/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => n != '.gitkeep').toSet();
      expect(files, used);
      expect(Mk.all.where((m) => m.deadly).map((m) => m.key), hasLength(2));
      expect(m7PpeMishapRoutePacks.keys, ['do_7_6_b']);
      expect(L.quick, 'নিখুঁত আর ঝটপট!');
    });

    test('lesson text: his line is myth 2 word for word; the quoted duties and the glove label are in today\'s lesson 7.6', () {
      final raw = File('tool/all_training_chapters_bn.json')
          .readAsStringSync()
          .replaceAll('য়', 'য়')
          .replaceAll('ড়', 'ড়')
          .replaceAll('ঢ়', 'ঢ়');
      expect(raw.contains('আমি অভিজ্ঞ, আমার PPE লাগে না। এটা শুধু নতুনদের জন্য।'), isTrue);
      expect(L.coworkerLine.startsWith('আমি অভিজ্ঞ, আমার PPE লাগে না। এটা শুধু নতুনদের জন্য।'), isTrue);
      for (final q in [
        'PPE-তে কোনো ক্ষতি বা ত্রুটি দেখা গেলে অবিলম্বে সুপারভাইজারকে রিপোর্ট করা',
        'PPE-এর সঠিক যত্ন নেওয়া এবং সেটিকে পরিষ্কার রাখা',
        'রেকর্ড রাখুন',
        'কাকে বলেছেন',
        'কাজটি করতে অস্বীকার করার সম্পূর্ণ অধিকার',
        'IS 4770 টাইপ ৪ গ্লাভস',
        'সেফটি হেলমেটের জন্য IS 2925',
        'সেফটি জুতোর জন্য IS 15298',
        'ক্ষতিগ্রস্ত বা মেয়াদ উত্তীর্ণ PPE বদলে দেওয়ার',
      ]) {
        expect(raw.contains(q), isTrue, reason: q);
      }
    });

    test('libraries: same length, big enough, never a rule marked wrong; a right card per deal', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7PpeWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworkerScript;
      expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
      expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
    });

    test('rival lines: his exit is recorded; his new line and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['আমি অভিজ্ঞ, আমার PPE লাগে না। এটা শুধু নতুনদের জন্য। তুইও খুলে রাখ।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...L.whyQ.values, L.callHeld, L.allSet, L.fail, L.deadlyWord, L.nearMissWord, for (final m in Mk.all) m.textBn]));
      expect(L.newGuideLines, isNot(contains(L.quick)), reason: 'already recorded');
      expect(LearnVoice.resolve(L.quick), isNotNull, reason: 'the quick line is already recorded');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_ppe_mishap_route: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: every drop zone and control apart, on the scene, under the header, clear of the guide in either corner', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M7PpeGeo.forScene(h, 0);
        final zones = <String, Rect>{
          'supervisor': M7PpeGeo.supervisor,
          'coworker': M7PpeGeo.coworker,
          'shop': M7PpeGeo.shop,
          'cloth': M7PpeGeo.cloth,
          'bag': g.bag,
          'trainee': g.traineeBody,
          'docket': M7PpeGeo.docket,
          'hand': g.itemGrab,
          'diary': g.diary,
        };
        final names = zones.keys.toList();
        for (var i = 0; i < names.length; i++) {
          final a = zones[names[i]]!;
          expect(a.left >= 0 && a.right <= 360 && a.top >= 104 && a.bottom <= h, isTrue, reason: 'h $h ${names[i]} $a on the scene');
          for (var j = i + 1; j < names.length; j++) {
            if ({names[i], names[j]}.containsAll(['trainee', 'diary'])) continue; // the diary is in his shirt pocket
            expect(a.overlaps(zones[names[j]]!), isFalse, reason: 'h $h ${names[i]} / ${names[j]}');
          }
        }
        // The marks sit inside the docket and apart; the pin's pocket is on it.
        expect(M7PpeGeo.docket.contains(M7PpeGeo.goMark.center) && M7PpeGeo.docket.contains(M7PpeGeo.stopMark.center), isTrue);
        expect(M7PpeGeo.goMark.overlaps(M7PpeGeo.stopMark), isFalse);
        expect(M7PpeGeo.docket.contains(M7PpeGeo.pinHome), isTrue);
        for (final m in [M7PpeGeo.goMark, M7PpeGeo.stopMark, g.diary]) {
          expect(m.width >= 48 && m.height >= 48, isTrue, reason: 'touch target $m');
        }
        // The guide's corner squares, either side.
        for (final guide in [Rect.fromLTRB(244, h - 8 - 160, 360, h), Rect.fromLTRB(0, h - 8 - 160, 116, h)]) {
          for (final n in ['hand', 'diary', 'bag', 'trainee']) {
            expect(zones[n]!.overlaps(guide), isFalse, reason: 'h $h $n vs guide $guide');
          }
        }
        // A drop finds its own place; the middle of nowhere finds none.
        expect(g.keepAt(g.bag.center), isTrue);
        expect(g.keepAt(g.traineeBody.center), isTrue);
        expect(g.keepAt(M7PpeGeo.shop.center), isFalse);
        expect(g.keepAt(g.hand), isFalse, reason: 'where the item rests is not a place');
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

    testWidgets('the guide comes first: a tap does not skip him; then the cutscene, then the item is in his hands', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7PpeMishapRoutePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 300);
      expect(_live.stage, M7PpeStage.cut, reason: 'the mishap plays first, wordless');
      await _toRoute(t);
      expect(_label(L.itemLabel), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      await _toRoute(t);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 300);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.taskRoute)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('a tap on the item shows it close; a tap closes it; nothing is scored', (t) async {
      final c = await _open(t, 5);
      await _toRoute(t);
      await t.tapAt(_geo.hand * _k);
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('closeup')), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await t.tapAt(const Offset(40, 400));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('closeup')), findsNothing);
      expect(_live.stage, M7PpeStage.route);
      await _close(t, c);
    });

    // A play with a damaged item with a spare, one with none, and a clean mishap.
    final mixSeed = _seedWhere((d) =>
        d.damages == 2 &&
        d.incidents.any((i) => i.kind.damaged && i.spare) &&
        d.incidents.any((i) => i.kind.damaged && !i.spare));
    testWidgets('flow (seed $mixSeed): the right hands, the record, the decision, every reason picked, him refused → pass', (t) async {
      final c = await _open(t, mixSeed);
      for (var i = 0; i < 3; i++) {
        await _playClean(t);
      }
      await _pumpUntil(t, () => _has(find.byType(LevelPassPanel)), maxMs: 6000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['7.6/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['7.6/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtNo), findsOneWidget);
      expect(find.text(L.caughtReport), findsOneWidget);
      expect(find.text(L.caughtDiary), findsOneWidget);
      expect(_live.percent, 100);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final threeSeed = _seedWhere((d) => d.damages == 3 && d.coworkerAt == 2);
    testWidgets('flow (seed $threeSeed): three damaged items, him at the last one → pass', (t) async {
      final c = await _open(t, threeSeed);
      for (var i = 0; i < 3; i++) {
        await _playClean(t);
      }
      await _pumpUntil(t, () => _has(find.byType(LevelPassPanel)), maxMs: 6000);
      expect(c.read(gameSaveProvider).rungProgress['7.6/do/1'], 'cleared');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final glovesSeed = _seedWhere((d) => d.incidents.first.kind == K.glovesTorn);
    testWidgets('torn gloves into the bag = deadly: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, glovesSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.keep);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the freeze comes first');
      expect(await _pumpUntil(t, () => _has(find.byType(MistakeCard)), maxMs: 6000), isTrue);
      expect(find.text(Mk.tornGlovesKept.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.tornGlovesKept.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(s.rungProgress['7.6/do/1'], isNot('cleared'));
      await _close(t, c);
    });

    final noSpareSeed = _seedWhere((d) => d.incidents.first.kind == K.harnessNicked && !d.incidents.first.spare);
    testWidgets('a cut harness reported, no spare, then "কাজ চালাই" = deadly after the freeze', (t) async {
      final c = await _open(t, noSpareSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.supervisor);
      await _reason(t);
      expect(_label(L.replyNone), findsOneWidget, reason: 'the supervisor answers: no spare');
      if (_live.index == _live.deal.coworkerAt) await _refuse(t);
      await _diary(t);
      await _reason(t);
      await _pin(t, M7PpeWork.go);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(await _pumpUntil(t, () => _has(find.byType(MistakeCard)), maxMs: 6000), isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.cutHarnessKept.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final helmetSeed = _seedWhere((d) => d.incidents.first.kind == K.helmetCracked);
    testWidgets('three slips strike the level out (shop, coworker, shop); a slip leaves the item in his hands', (t) async {
      final c = await _open(t, helmetSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.shop);
      expect(find.text(Mk.shopBuy.textBn), findsOneWidget);
      await _gotIt(t);
      expect(_live.stage, M7PpeStage.route);
      expect(_label(L.itemLabel), findsOneWidget);
      await _carry(t, M7PpeDest.coworker);
      expect(find.text(Mk.wrongHands.textBn), findsOneWidget);
      await _gotIt(t);
      await _carry(t, M7PpeDest.shop);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'slips never freeze');
      expect(c.read(gameSaveProvider).mistakes.where((x) => x.deadly), isEmpty);
      await _close(t, c);
    });

    testWidgets('a cracked helmet into the bag is a slip: the card, no freeze, the play goes on', (t) async {
      final c = await _open(t, helmetSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.keep);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.bagDamaged.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.bagDamaged.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await _gotIt(t);
      expect(_live.stage, M7PpeStage.route);
      await _close(t, c);
    });

    final spareSeed = _seedWhere((d) => d.incidents.first.kind.damaged && d.incidents.first.spare && d.coworkerAt != 0);
    testWidgets('no record before the work decision after a report: the slip, then the decision stands once the pin is held again', (t) async {
      final c = await _open(t, spareSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.supervisor);
      await _reason(t);
      expect(_label(L.replySpare), findsOneWidget);
      await _pin(t, M7PpeWork.go);
      expect(find.text(Mk.noRecord.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noRecord.key);
      await _gotIt(t);
      expect(_live.stage, M7PpeStage.decide);
      await _pin(t, M7PpeWork.go);
      expect(_live.why, M7PpeWhy.goNew);
      await _reason(t);
      expect(_live.index, 1);
      await _close(t, c);
    });

    final cleanSeed = _seedWhere((d) => !d.incidents.first.kind.damaged && d.coworkerAt != 0);
    testWidgets('a clean mishap: the diary does nothing; "এই কাজ আজ নয়" is a needless stop; the cloth, then go', (t) async {
      final c = await _open(t, cleanSeed);
      await _toRoute(t);
      final muddy = _live.kind == K.glovesMuddy;
      await _carry(t, muddy ? M7PpeDest.cloth : M7PpeDest.keep);
      await _reason(t);
      await _diary(t);
      expect(_live.recorded, isFalse);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the diary does nothing without a report');
      await _pin(t, M7PpeWork.stop);
      expect(find.text(Mk.needlessStop.textBn), findsOneWidget);
      await _gotIt(t);
      await _pin(t, M7PpeWork.go);
      await _pump(t, 1600);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.needlessStop.key);
      await _close(t, c);
    });

    testWidgets('a muddy glove into the bag is a slip; a whole item reported is a needless report', (t) async {
      final seed = _seedWhere((d) => d.incidents.first.kind == K.glovesMuddy);
      final c = await _open(t, seed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.keep);
      expect(find.text(Mk.muddyGloves.textBn), findsOneWidget);
      await _gotIt(t);
      await _carry(t, M7PpeDest.supervisor);
      expect(find.text(Mk.needlessReport.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key).toSet(), {Mk.muddyGloves.key, Mk.needlessReport.key});
      await _close(t, c);
    });

    final hisSeed = _seedWhere((d) => d.coworkerAt == 0 && d.incidents.first.kind.damaged && d.incidents.first.spare);
    testWidgets('listening to him (take your PPE off) is a slip — no freeze, no deadly', (t) async {
      final c = await _open(t, hisSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.supervisor);
      await _reason(t);
      expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 6000), isTrue);
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerScript.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listen.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('a fast play: the work pin waits for him; he cuts in at once; after him it works', (t) async {
      final c = await _open(t, hisSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.supervisor);
      expect(await _pumpUntil(t, () => _has(find.byType(ChoiceDeck))), isTrue);
      await _pump(t, 400);
      await _pickRight(t, L.whyRight[M7PpeWhy.report]!);
      await _pump(t, 1000);
      await _pin(t, M7PpeWork.stop, holdMs: 800);
      expect(_has(find.byType(CoworkerPeek)), isTrue, reason: 'he cuts in');
      expect(_live.stage, M7PpeStage.decide);
      expect(_live.roundDone, isFalse, reason: 'the pin did nothing');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pickRight(t, L.coworkerScript.right);
      await _pump(t, 2600);
      await _diary(t);
      await _reason(t);
      await _pin(t, M7PpeWork.go);
      expect(_live.why, M7PpeWhy.goNew, reason: 'after him the pin works');
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final c = await _open(t, helmetSeed);
      await _toRoute(t);
      await _carry(t, M7PpeDest.supervisor);
      expect(_live.roundDone, isTrue);
      await _carry(t, M7PpeDest.shop);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the item did not move');
      await _reason(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a nudge up from the item (presses nothing); at the decision a sweep over both marks and the diary', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, helmetSeed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(scene().showing, isFalse, reason: 'the cutscene: no hand');
      await _toRoute(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the item in hand');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      expect(scene().debugOptions, isEmpty, reason: 'it points at no person and no place');
      await t.tapAt(const Offset(30, 600));
      await _pump(t, 200);
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      await _carry(t, M7PpeDest.supervisor);
      await _reason(t);
      if (_live.index == _live.deal.coworkerAt) await _refuse(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the work decision');
      expect(scene().debugOptions, hasLength(3), reason: 'both docket marks and the diary alike');
      expect(scene().debugFrame?.ripple, isNull);
      await _close(t, c);
    });
  });
}
