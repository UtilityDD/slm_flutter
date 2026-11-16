// Lesson 6.11 (আর্থিং সিস্টেম), কাজ "মাটির ভেতরে রক্ষক" (ruling M6-9: inspect
// and test the new DTR's two earth pits): the rules (a broken earth path —
// OL — signed = deadly; a wrong electrode, an iron nut, no lid, both earths
// in one pit, a high reading signed, gravel as a remedy = slips, each once a
// pit; the lid, the joints and the spanner, the tester, remedies that fit
// the soil; needless work costs only the bonus), the deal, the libraries,
// the coworker's pushes (lesson myths word for word; listening = the act he
// pushes), the drawn places, and the level in the shell: the guide first, a
// full clean play (lids, joints with the spanner's circle, a test, a remedy,
// a second pit, reasons, the coworker refused), the two-step pick, a slip
// card that keeps the pit, three slips, the deadly freeze (own act;
// listening to his deadly push), his pit's controls wait for him, the praise
// window takes no touch, and the gesture hand shows how (never what).
import 'dart:async';
import 'dart:convert';
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
import 'package:slm_flutter/features/game/m6_earth_pit_test.dart';
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
  rungId: '6.11/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.11',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

final _pack = m6EarthPitPacks['do_6_11_a']!;
typedef L = M6EarthPitLines;
typedef Mk = M6EarthPitMistakes;

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
M6PitGeo get _geo => M6PitGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M6PitRun get _live => M6EarthPitProbe.run!;
int get _pit => _live.index;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _drag(WidgetTester t, Offset from, Offset by) async {
  final g = await t.startGesture(from * _k);
  for (var k = 1; k <= 8; k++) {
    await g.moveTo((from + by * (k / 8)) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

Future<void> _lift(WidgetTester t) => _drag(t, _geo.lidOn(_pit).center, const Offset(0, -60));
Future<void> _closeLid(WidgetTester t) => _drag(t, _geo.lidOff(_pit).center, const Offset(0, 50));
Future<void> _spare(WidgetTester t) => _drag(t, _geo.spare.center, _geo.chamber(_pit).center - _geo.spare.center);
Future<void> _test(WidgetTester t) => _tapAt(t, _geo.testBtn);

/// A choice under the scene (an action, a packet, a remedy) through its
/// preview: tap → ✓.
Future<void> _pick(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 200);
  expect(await confirmChoice(t), isTrue, reason: 'the preview of $label');
  await _pump(t, 400);
}

Future<void> _act(WidgetTester t, M6PitAction a) => _pick(t, L.action(a));

/// The spanner circled clockwise round joint [j] until it is snug.
Future<void> _tighten(WidgetTester t, int j) async {
  final c = j == 0 ? _geo.joint1(_pit) : _geo.joint2(_pit);
  Offset at(double a) => (c + Offset(math.cos(a), math.sin(a)) * 30) * _k;
  const total = 2.9 * math.pi;
  const n = 60;
  final g = await t.startGesture(at(0));
  for (var k = 1; k <= n; k++) {
    await g.moveTo(at(total * k / n));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

/// A joint put right: tap it, a brass packet, then the spanner.
Future<void> _fixJoint(WidgetTester t, int j) async {
  await _tapAt(t, j == 0 ? _geo.joint1(_pit) : _geo.joint2(_pit));
  await _pick(t, L.nut(M6Nut.brass));
  expect(_live.pendingTight, j);
  await _tighten(t, j);
  expect(_live.tight[j], isTrue, reason: 'the spanner made joint $j snug');
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6EarthPitPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6PitDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m6PitDeal(math.Random(s))));

/// The coworker comes (his pit's chamber open): refuse him.
Future<void> _refuse(WidgetTester t, M6PitPush p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// One pit played right (the coworker refused if he is dealt on it: myth 2
/// once the chamber is open, myth 1 when the tester reads OL).
Future<void> _playPit(WidgetTester t, M6PitDeal d, int i, {bool reason = true, int after = 3000}) async {
  final s = d.pits[i];
  final dig = d.shared && i == 1;
  if (dig) {
    expect(_live.pitExists, isFalse);
    await _act(t, M6PitAction.dig);
    expect(_live.pitExists, isTrue);
    await _lift(t);
  } else if (!s.lidMissing) {
    await _lift(t);
  }
  expect(_live.chamberOpen, isTrue, reason: 'pit $i open');
  if (d.coworkerPit == i && d.push == M6PitPush.anyRod) await _refuse(t, d.push);
  if (d.coworkerPit == i && d.push == M6PitPush.looseOk) {
    await _test(t);
    expect(_live.reading, double.infinity, reason: 'his pit reads OL');
    await _refuse(t, d.push);
  }
  if (!m6ElectrodeGood(_live.electrode)) {
    await _act(t, M6PitAction.replace);
    expect(m6ElectrodeGood(_live.electrode), isTrue);
  }
  for (var j = 0; j < 2; j++) {
    if (_live.nuts[j] == M6Nut.iron || _live.nuts[j] == M6Nut.none) await _fixJoint(t, j);
  }
  await _test(t);
  expect(_live.reading, isNotNull);
  expect(_live.reading!.isFinite, isTrue);
  if (_live.reading! > kM6PitLimit) {
    await _act(t, M6PitAction.remedy);
    await _pick(t, L.remedy(m6PitFits(d.soil).first));
    await _test(t);
    expect(_live.reading!, lessThanOrEqualTo(kM6PitLimit));
  }
  if (_live.lid == M6Lid.missing) {
    await _spare(t);
  } else {
    await _closeLid(t);
  }
  expect(_live.lid, M6Lid.on);
  final topic = _live.whyTopic;
  await _act(t, M6PitAction.sign);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pit $i');
  expect(_live.roundDone, isTrue, reason: 'pit $i signed');
  if (!reason) return;
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (pit $i)');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[_live.whyTopic]!);
  expect(topic, isNotNull);
  await _pump(t, after);
}

M6PitSpec _spec({
  bool lidMissing = false,
  M6Electrode electrode = M6Electrode.gi27,
  M6Nut j1 = M6Nut.brass,
  M6Nut j2 = M6Nut.steel,
}) =>
    M6PitSpec(lidMissing: lidMissing, electrode: electrode, joint1: j1, joint2: j2, good: 2.6, high: 18.4, fixed: 3.3);

M6PitRun _runOf(M6PitSpec first, {M6Soil soil = M6Soil.loamWet, bool shared = false, M6PitSpec? second}) => M6PitRun(M6PitDeal(
      soil: soil,
      pits: [first, second ?? _spec()],
      shared: shared,
      coworkerPit: 0,
      push: M6PitPush.anyRod,
      nuts: const [M6Nut.brass, M6Nut.steel, M6Nut.iron],
      remedies: M6Remedy.values,
    ));

/// The lesson's text, with the app's nukta form (U+09AF U+09BC …).
String _nukta(String s) => s
    .replaceAll(String.fromCharCode(0x09DF), String.fromCharCodes([0x09AF, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DC), String.fromCharCodes([0x09A1, 0x09BC]))
    .replaceAll(String.fromCharCode(0x09DD), String.fromCharCodes([0x09A2, 0x09BC]));

/// The precomposed ড় ঢ় য় (the app writes base + nukta).
final _precomposed = RegExp('[${String.fromCharCodes([0x09DC, 0x09DD, 0x09DF])}]');

void main() {
  group('rules', () {
    test('deals: soil about half needs a remedy; a shared pit on ~30 %; his push fits his pit; one lid spare; at least two faults; readings never 5–8', () {
      final seen = <String>{};
      var high = 0, shared = 0, rod = 0;
      final soils = <M6Soil>{};
      final cps = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m6PitDeal(math.Random(s));
        soils.add(d.soil);
        if (m6SoilHigh(d.soil)) high++;
        if (d.shared) shared++;
        if (d.push == M6PitPush.anyRod) rod++;
        cps.add(d.coworkerPit);
        expect(m6PitPushesFor(d.pits[d.coworkerPit]), contains(d.push), reason: 'seed $s');
        if (d.shared) {
          expect(d.coworkerPit, 0, reason: 'the crew\'s pit is clean: he never comes there');
          final p = d.pits[1];
          expect((p.faults, p.lidMissing), (0, false));
        }
        expect(d.pits.where((p) => p.lidMissing), hasLength(lessThanOrEqualTo(1)), reason: 'one spare chamber set');
        final faults = d.pits.take(d.shared ? 1 : 2).fold(0, (a, p) => a + p.faults) + (d.shared ? 1 : 0);
        expect(faults, greaterThanOrEqualTo(2), reason: 'seed $s');
        for (final p in d.pits) {
          expect(p.joints.where((n) => n == M6Nut.none).length, lessThanOrEqualTo(1));
          expect(p.good, inInclusiveRange(1.8, 3.9));
          expect(p.fixed, inInclusiveRange(2.4, 4.6));
          expect(p.high, inInclusiveRange(12, 28));
        }
        expect(d.nuts.toSet(), {M6Nut.brass, M6Nut.steel, M6Nut.iron});
        expect(d.remedies.toSet(), M6Remedy.values.toSet(), reason: 'the full tray on every deal');
        seen.add('${d.soil.index}${d.shared}${d.coworkerPit}${d.push.index}|${d.pits.map((p) => '${p.lidMissing}${p.electrode.index}${p.joint1.index}${p.joint2.index}').join('|')}|${d.nuts}|${d.remedies}');
      }
      expect(seen.length, greaterThan(280));
      expect(soils, M6Soil.values.toSet());
      expect(high, inInclusiveRange(110, 190), reason: '~half the plays need a remedy');
      expect(shared, inInclusiveRange(60, 130));
      expect(rod, inInclusiveRange(110, 190), reason: 'coworker A or B, half each');
      expect(cps, {0, 1});
    });

    test('the lid: up to look, down before signing; the tester and the bottom joint need it open; the spare only on a pit with none', () {
      final r = _runOf(_spec());
      expect(r.chamberOpen, isFalse);
      expect(r.test(), M6PitGuard.lidFirst);
      expect(r.jointGuard(0), M6PitGuard.lidFirst);
      expect(r.jointGuard(1), isNull, reason: 'the top joint is on the plinth');
      expect(r.fitSpare(), isFalse, reason: 'this pit has its lid');
      expect(r.closeLid(), isFalse);
      expect(r.liftLid(), isTrue);
      expect(r.opened, isTrue);
      expect(r.test(), isNull);
      expect(r.reading, 2.6);
      expect(r.sign(), M6Sign.slip);
      expect(r.lastMistake, Mk.noLid);
      expect(r.sign(), M6Sign.again, reason: 'once a pit');
      expect(r.slips, 1);
      expect(r.closeLid(), isTrue);
      expect(r.sign(), M6Sign.done);
      expect(r.whyTopic, M6PitWhy.signed);
      final m = _runOf(_spec(lidMissing: true));
      expect(m.chamberOpen, isTrue);
      expect(m.opened, isTrue, reason: 'no chamber: open from the start (his cue)');
      expect(m.liftLid(), isFalse);
      m.test();
      expect(m.fitSpare(), isTrue);
      expect(m.lid, M6Lid.on);
      expect(m.spareUsed, isTrue);
      expect(m.sign(), M6Sign.done);
      expect(m.whyTopic, M6PitWhy.lid);
      expect(m.caught, contains(L.caughtLid));
    });

    test('a joint off its bolt: the tester reads OL, and signing it is deadly (N7)', () {
      final r = _runOf(_spec(j2: M6Nut.none));
      r.liftLid();
      expect(r.broken, isTrue);
      r.test();
      expect(r.reading, double.infinity);
      r.closeLid();
      expect(r.sign(), M6Sign.deadly);
      expect(r.deadly, Mk.brokenSigned);
      expect(Mk.brokenSigned.deadly, isTrue);
      expect(r.ended, isTrue);
      expect(r.slips, 0);
    });

    test('joints: iron = slip (once a pit), nothing fitted; brass goes on loose (still OL) until the spanner turns it snug, clockwise only', () {
      final r = _runOf(_spec(j1: M6Nut.none, j2: M6Nut.iron));
      r.liftLid();
      expect(r.fitNut(0, M6Nut.iron), Mk.ironNut);
      expect(r.nuts[0], M6Nut.none);
      expect(r.fitNut(1, M6Nut.iron), isNull, reason: 'once a pit');
      expect(r.slips, 1);
      expect(r.fitNut(0, M6Nut.steel), isNull);
      expect((r.nuts[0], r.tight[0]), (M6Nut.steel, false));
      expect(r.pendingTight, 0);
      r.test();
      expect(r.reading, double.infinity, reason: 'a loose nut is no joint yet');
      expect(r.turn(0, -10), isFalse, reason: 'anticlockwise does nothing');
      expect(r.turned(0), 0);
      expect(r.turn(0, math.pi), isFalse);
      expect(r.reading, double.infinity, reason: 'unchanged until snug');
      expect(r.turn(0, 2 * math.pi), isTrue);
      expect(r.tight[0], isTrue);
      expect(r.reading, isNull, reason: 'test again after a change');
      expect(r.pendingTight, isNull);
      r.test();
      expect(r.reading, 2.6);
      r.closeLid();
      expect(r.sign(), M6Sign.again, reason: 'the iron nut on the top joint, already scored');
      expect(r.slips, 1);
      expect(r.fitNut(1, M6Nut.brass), isNull);
      r.turn(1, 3 * math.pi);
      r.liftLid();
      r.test();
      r.closeLid();
      expect(r.sign(), M6Sign.done);
      expect(r.whyTopic, M6PitWhy.joint);
      expect(r.caught, containsAll([L.caughtJoint, L.caughtIron]));
    });

    test('a wrong electrode reads high whatever is added; signed = slip; the crew drives a right one (a new clamp)', () {
      for (final e in [M6Electrode.rod, M6Electrode.short, M6Electrode.bar]) {
        expect(m6ElectrodeGood(e), isFalse);
        final r = _runOf(_spec(electrode: e, j1: M6Nut.iron));
        r.liftLid();
        r.test();
        expect(r.reading, 18.4, reason: 'good soil, but a wrong electrode');
        r.remedy(M6Remedy.water);
        r.test();
        expect(r.reading!, greaterThan(kM6PitLimit));
        expect(r.reading!, greaterThanOrEqualTo(9), reason: 'never 5–8');
        r.closeLid();
        expect(r.sign(), M6Sign.slip);
        expect(r.lastMistake, Mk.electrode);
        r.liftLid();
        expect(r.replace(), isNull);
        expect(r.electrode, M6Electrode.gi27);
        expect((r.nuts[0], r.tight[0]), (M6Nut.iron, true), reason: 'the clamp moves as it was: the iron nut is still his job');
        expect(r.replaced, isTrue);
        expect(r.wasted, isTrue, reason: 'the water poured on a wrong electrode');
        r.test();
        expect(r.reading, 2.6);
        r.closeLid();
        expect(r.sign(), M6Sign.slip, reason: 'the iron nut');
        r.liftLid();
        r.fitNut(0, M6Nut.brass);
        r.turn(0, 3 * math.pi);
        r.test();
        r.closeLid();
        expect(r.sign(), M6Sign.done);
        expect(r.whyTopic, isNot(M6PitWhy.electrode), reason: 'he slipped on the electrode first');
      }
      for (final e in [M6Electrode.gi25, M6Electrode.gi27, M6Electrode.gi30]) {
        expect(m6ElectrodeGood(e), isTrue);
      }
      final ok = _runOf(_spec(electrode: M6Electrode.rod))..liftLid();
      ok.replace();
      ok.test();
      ok.closeLid();
      expect(ok.sign(), M6Sign.done);
      expect(ok.whyTopic, M6PitWhy.electrode);
      // A replacement never puts a joint right by itself (an open bottom
      // joint still reads OL, signing it still deadly; no joint credit).
      final open = _runOf(_spec(electrode: M6Electrode.bar, j1: M6Nut.none))..liftLid();
      open.replace();
      expect(open.nuts[0], M6Nut.none);
      open.test();
      expect(open.reading, double.infinity);
      final needless = _runOf(_spec(j1: M6Nut.none))..liftLid();
      expect(needless.replace(), isNull);
      expect(needless.wasted, isTrue);
      expect((needless.electrode, needless.nuts[0], needless.tight[0]), (M6Electrode.gi27, M6Nut.none, false), reason: 'needless: nothing changes');
      expect(needless.slips, 0);
      expect(needless.thorough, isFalse);
      expect(_runOf(_spec()).replace(), M6PitGuard.lidFirst);
    });

    test('high soil: signed high = slip; gravel = slip; a remedy that does not fit stays over 5; one that fits brings it under', () {
      for (final soil in [M6Soil.loamDry, M6Soil.rocky, M6Soil.sandy]) {
        final fits = m6PitFits(soil);
        expect(fits, isNotEmpty);
        expect(fits, isNot(contains(M6Remedy.gravel)));
        final miss = M6Remedy.values.firstWhere((r) => r != M6Remedy.gravel && !fits.contains(r));
        final r = _runOf(_spec(), soil: soil);
        r.liftLid();
        r.test();
        expect(r.reading, 18.4);
        r.closeLid();
        expect(r.sign(), M6Sign.slip);
        expect(r.lastMistake, Mk.highSigned);
        r.liftLid();
        expect(r.remedy(M6Remedy.gravel), Mk.gravel);
        expect(r.reading, 18.4, reason: 'gravel did nothing');
        expect(r.wasted, isFalse);
        expect(r.remedy(miss), isNull);
        r.test();
        expect(r.reading!, inInclusiveRange(9, 18.4));
        expect(r.wasted, isTrue, reason: 'a remedy that does not fit the soil costs the bonus');
        expect(r.remedy(fits.first), isNull);
        r.test();
        expect(r.reading, 3.3);
        r.closeLid();
        expect(r.sign(), M6Sign.done);
        expect(r.slips, 2);
        expect(r.whyTopic, M6PitWhy.signed, reason: 'he signed high first: the remedy reason would not fit');
      }
      for (final (soil, rem, why) in [
        (M6Soil.loamDry, M6Remedy.water, M6PitWhy.water),
        (M6Soil.rocky, M6Remedy.bentonite, M6PitWhy.bentonite),
        (M6Soil.sandy, M6Remedy.extra, M6PitWhy.extra),
      ]) {
        final r = _runOf(_spec(), soil: soil)..liftLid();
        r.test();
        r.remedy(rem);
        r.test();
        r.closeLid();
        expect(r.sign(), M6Sign.done);
        expect(r.whyTopic, why);
        expect(r.caught, contains(L.caughtRemedy));
      }
      expect(m6PitFits(M6Soil.loamWet), isEmpty);
      final wet = _runOf(_spec())..liftLid();
      wet.test();
      expect(wet.remedy(M6Remedy.water), isNull);
      expect(wet.wasted, isTrue, reason: 'a needless remedy: the bonus only');
      expect(wet.slips, 0);
      final rod = _runOf(_spec(electrode: M6Electrode.rod), soil: M6Soil.loamDry)..liftLid();
      rod.test();
      rod.remedy(M6Remedy.water);
      expect(rod.wasted, isTrue, reason: 'a remedy on a wrong electrode costs the bonus');
      expect(rod.thorough, isFalse);
    });

    test('both earths in one pit: signing = slip (once); the crew digs a separate pit at the peg; a needless dig costs the bonus only', () {
      final r = _runOf(_spec(), shared: true, second: _spec(j1: M6Nut.steel));
      r.liftLid();
      r.test();
      r.closeLid();
      expect(r.digTooEarly, isTrue);
      expect(r.dig(), isFalse, reason: 'its turn comes with lead 2');
      expect(r.wasted, isFalse, reason: 'the right call early: no cost');
      expect(r.sign(), M6Sign.done);
      r.next();
      expect(r.pitExists, isFalse);
      expect(r.test(), M6PitGuard.noPit);
      expect(r.jointGuard(1), M6PitGuard.noPit);
      expect(r.liftLid(), isFalse);
      expect(r.sign(), M6Sign.slip);
      expect(r.lastMistake, Mk.samePit);
      expect(r.sign(), M6Sign.again);
      expect(r.slips, 1);
      expect(r.lookOf(1).exists, isFalse);
      expect(r.dig(), isTrue);
      expect(r.pitExists, isTrue);
      expect(r.lookOf(1).exists, isTrue);
      expect(r.lid, M6Lid.on);
      r.liftLid();
      r.test();
      r.closeLid();
      expect(r.sign(), M6Sign.done);
      expect(r.whyTopic, M6PitWhy.signed, reason: 'slipped on the shared pit first');
      expect(r.caught, contains(L.caughtSecond));
      expect(r.done, isFalse);
      r.next();
      expect(r.done, isTrue);
      expect(r.percent, 85);
      expect(r.passed, isTrue);
      final lone = _runOf(_spec())..liftLid();
      expect(lone.digTooEarly, isFalse);
      expect(lone.dig(), isFalse);
      expect(lone.wasted, isTrue, reason: 'a needless dig costs the bonus only');
      expect(lone.slips, 0);
    });

    test('three slips and the play fails; a thorough round pays its bonus; each round counts its own', () {
      final r = _runOf(_spec(j2: M6Nut.iron), soil: M6Soil.rocky);
      r.liftLid();
      r.test();
      r.remedy(M6Remedy.gravel);
      r.fitNut(1, M6Nut.iron);
      expect(r.sign(), M6Sign.slip);
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      final c = _runOf(_spec());
      c
        ..liftLid()
        ..test()
        ..closeLid();
      expect(c.sign(), M6Sign.done);
      expect(c.thorough, isTrue);
      c.next();
      expect(c.thorough, isTrue);
      expect(c.lid, M6Lid.on, reason: 'a new pit');
      expect(c.lookOf(0).lid, M6Lid.on, reason: 'pit 0 drawn as signed');
    });

    test('listening to him is the act he pushes (X2/B1): myth 2 (any rod) a slip, myth 1 (a bit cut or loose) deadly', () {
      expect(Mk.push(M6PitPush.anyRod), Mk.electrode);
      expect(Mk.push(M6PitPush.anyRod).deadly, isFalse);
      expect(Mk.push(M6PitPush.looseOk), Mk.brokenSigned);
      expect(Mk.push(M6PitPush.looseOk).deadly, isTrue);
      expect(m6PitPushesFor(_spec(electrode: M6Electrode.rod)), [M6PitPush.anyRod]);
      expect(m6PitPushesFor(_spec(j1: M6Nut.none)), [M6PitPush.looseOk]);
      expect(m6PitPushesFor(_spec()), isEmpty);
      final r = _runOf(_spec(electrode: M6Electrode.rod))..liftLid();
      r.pushSlip(Mk.electrode);
      expect(r.slips, 1);
      r.test();
      r.closeLid();
      expect(r.sign(), M6Sign.again, reason: 'the electrode was scored when he was heard');
    });

    test('English digits; জল not পানি; the owner\'s terms; nukta form; every mistake has its picture; the deadly set; keys; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.lidFirst,
        L.testFirst,
        L.noPit,
        L.needless,
        L.retest,
        L.replaced,
        L.dug,
        L.digLater,
        L.ironAgain,
        ...L.allAgain,
        for (var n = 1; n <= 2; n++) L.lead(n),
        for (final e in M6Electrode.values) L.tagOf(e),
        for (final a in M6PitAction.values) L.action(a),
        for (final n in [M6Nut.brass, M6Nut.steel, M6Nut.iron]) L.nut(n),
        for (final r in M6Remedy.values) L.remedy(r),
        L.trayClose,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6PitPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        ...L.caughtAll,
        kEarthTesterBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(RegExp('মৃত|এলটি|এইচটি|কেভি|অন |অফ ').hasMatch(l), isFalse, reason: 'owner term rules: $l');
        expect(_precomposed.hasMatch(l), isFalse, reason: 'nukta as base + U+09BC: $l');
      }
      expect(kEarthTesterBn, 'আর্থ টেস্টার');
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.brokenSigned});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.11/m6_earth_pit_test/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m6_earth_pit_test/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6EarthPitPacks.keys, ['do_6_11_a']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; the actions and trays alike', () {
      expectSameLength('actions', [for (final a in M6PitAction.values) L.action(a)]);
      expectSameLength('nuts', [for (final n in [M6Nut.brass, M6Nut.steel, M6Nut.iron]) L.nut(n)]);
      expectSameLength('remedies', [for (final r in M6Remedy.values) L.remedy(r)]);
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6PitWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his two pushes are lesson 6.11\'s myths word for word; every spoken line is listed', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      final lesson = _nukta(File('tool/all_training_chapters_bn.json').readAsStringSync());
      final myths = <String>[];
      void walk(Object? o) {
        if (o is Map) {
          if (o['myth'] is String) myths.add(o['myth'] as String);
          o.values.forEach(walk);
        } else if (o is List) {
          o.forEach(walk);
        }
      }

      walk(jsonDecode(lesson));
      expect(L.newRivalLines, hasLength(2));
      for (final l in L.newRivalLines) {
        expect(myths, contains(l), reason: 'word for word: $l');
      }
      expect({for (final p in M6PitPush.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            L.lidFirst,
            L.testFirst,
            L.noPit,
            L.needless,
            L.retest,
            L.replaced,
            L.dug,
            L.digLater,
            L.ironAgain,
            ...L.allAgain,
            ...L.whyQ.values,
            for (final p in M6PitPush.values) L.callHeld(p),
            L.allSet,
            L.fail,
            for (final m in Mk.all) m.textBn,
            ...L.tapWhy,
            for (final cw in L.allCoworkers) ...cw.asks,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_earth_pit_test: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, clear of the header, the guide and the action row', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6PitGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (var i = 0; i < 2; i++) {
          final taps = <Rect>[g.jointHit(g.joint1(i)), g.jointHit(g.joint2(i)), g.testHit];
          final drags = <Rect>[g.lidOnHit(i), g.lidOffHit(i), g.spare];
          for (final r in [...taps, ...drags]) {
            expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
            expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
            expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
            expect(r.bottom, lessThan(h - 95), reason: 'h $h: $r above the action row');
            expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
            if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81)), isFalse, reason: 'h $h: $r under the bubble');
          }
          final all = [...taps, ...drags];
          for (final (k, a) in all.indexed) {
            for (final b in all.skip(k + 1)) {
              if ((a == g.lidOnHit(i) && b == g.lidOffHit(i))) continue; // never both at once
              expect(a.overlaps(b), isFalse, reason: 'h $h pit $i: $a / $b');
            }
          }
          // A spanner's reach round one joint never starts a lid or spare drag.
          for (final c in [g.joint1(i), g.joint2(i)]) {
            for (final r in drags) {
              final near = Offset(c.dx.clamp(r.left, r.right), c.dy.clamp(r.top, r.bottom));
              expect((near - c).distance, greaterThan(M6PitGeo.spannerReach - 22), reason: 'h $h pit $i: $c / $r');
            }
          }
          expect(g.chamber(i).bottom, lessThan(g.floorY));
        }
        // The two top joints stay apart.
        expect(g.jointHit(g.joint2(0)).overlaps(g.jointHit(g.joint2(1))), isFalse);
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

    testWidgets('the guide comes first: a tap does not skip him; then the tester and the four actions', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6EarthPitPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.text(kEarthTesterBn), findsOneWidget);
      expect(_label(L.reading(null)), findsOneWidget, reason: 'no reading before a test');
      for (final a in M6PitAction.values) {
        expect(_label(L.action(a)), findsOneWidget);
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    final quietLid = _seedWhere((d) => d.coworkerPit != 0 && !d.pits[0].lidMissing && !d.pits[0].hasOpen && !d.pits[0].hasIron && !d.shared);
    testWidgets('tapping the guide repeats the task, a different way each time; the lid lifted, the task moves on', (t) async {
      final c = await _open(t, quietLid);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askPit)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _lift(t);
      expect(_live.lid, M6Lid.off);
      expect(c.read(guideDirectorProvider).line, contains(L.askCheck));
      expect(_label(L.tagOf(_live.electrode)), findsOneWidget, reason: 'the record tag shows once the chamber is open');
      await _close(t, c);
    });

    // One play: separate pits, high soil, myth 1 refused, a joint off; one:
    // a shared pit, myth 2 refused, a pit with no chamber.
    final flowSeeds = [
      _seedWhere((d) => !d.shared && d.push == M6PitPush.looseOk && m6SoilHigh(d.soil) && d.pits.any((p) => p.hasIron || !m6ElectrodeGood(p.electrode))),
      _seedWhere((d) => d.shared && d.push == M6PitPush.anyRod && d.pits[0].lidMissing),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): two pits — lids, joints, a test, a remedy or a second pit, reasons; he is refused → pass', (t) async {
        final d = m6PitDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 2; i++) {
          await _playPit(t, d, i, after: i == 1 ? 0 : 3000);
        }
        expect(await _pumpUntil(t, find.byKey(const ValueKey('fault-replay')), maxMs: 4000), isTrue, reason: '"ফল্ট হলে": the replay first');
        expect(find.byType(LevelPassPanel), findsNothing);
        expect(await _pumpUntil(t, find.byType(LevelPassPanel), maxMs: 6000), isTrue);
        await _pump(t, 1000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.11/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.11/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('an action is two steps: a tap opens it and answers nothing, ✕ sets it aside, ✓ judges it', (t) async {
      final c = await _open(t, quietLid);
      await t.tap(_label(L.action(M6PitAction.sign)));
      await _pump(t, 300);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      final aside = t.widget<CardAside>(find.ancestor(of: _label(L.action(M6PitAction.sign)), matching: find.byType(CardAside)));
      expect(aside.aside, isTrue, reason: 'set aside, dimmed');
      // ✓ before a test: nothing is signed, nothing costs; the guide says why.
      await _act(t, M6PitAction.sign);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.testFirst));
      // The remedy tray opens on its action and closes again.
      await _lift(t);
      await _test(t);
      await _act(t, M6PitAction.remedy);
      for (final r in M6Remedy.values) {
        expect(_label(L.remedy(r)), findsOneWidget, reason: 'the full tray');
      }
      await t.tap(_label(L.trayClose));
      await _pump(t, 300);
      expect(_label(L.action(M6PitAction.sign)), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a slip (signed with the lid off) shows its card; the same pit goes on; signing again with it is refused, no second slip', (t) async {
      final c = await _open(t, quietLid);
      await _lift(t);
      await _test(t);
      await _act(t, M6PitAction.sign);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.noLid.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0, reason: 'the same pit');
      await _act(t, M6PitAction.sign);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.again(Mk.noLid)));
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noLid.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (gravel, an iron nut, no lid)', (t) async {
      final c = await _open(t, quietLid);
      await _lift(t);
      await _test(t);
      await _act(t, M6PitAction.remedy);
      await _pick(t, L.remedy(M6Remedy.gravel));
      expect(find.text(Mk.gravel.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapAt(t, _geo.joint2(0));
      await _pick(t, L.nut(M6Nut.iron));
      expect(find.text(Mk.ironNut.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _act(t, M6PitAction.sign);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final openAlone = _seedWhere((d) => d.coworkerPit != 0 && d.pits[0].hasOpen && !d.pits[0].lidMissing);
    testWidgets('a broken earth (OL) signed: the scene freezes first, then the card (near-miss, deadly)', (t) async {
      final c = await _open(t, openAlone);
      await _lift(t);
      await _test(t);
      expect(_label('OL'), findsOneWidget);
      await _act(t, M6PitAction.sign);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.brokenSigned.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final looseFirst = _seedWhere((d) => d.coworkerPit == 0 && d.push == M6PitPush.looseOk && !d.pits[0].lidMissing);
    testWidgets('listening to myth 1 ("a bit cut or loose") = deadly: he comes on the OL reading; freeze, then the card', (t) async {
      final c = await _open(t, looseFirst);
      await _lift(t);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not on the lid: on the broken reading');
      await _test(t);
      expect(_label('OL'), findsOneWidget);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerLoose.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.brokenSigned.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final looseTop = _seedWhere((d) => d.coworkerPit == 0 && d.push == M6PitPush.looseOk && !d.pits[0].lidMissing && d.pits[0].joint2 == M6Nut.none);
    testWidgets('myth 1 never comes once the loose joint is put right (fixed on the plinth before the lid)', (t) async {
      final c = await _open(t, looseTop);
      await _fixJoint(t, 1);
      await _lift(t);
      await _test(t);
      expect(_live.reading!.isFinite, isTrue);
      await _pump(t, 4000);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'his line would not fit');
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final rodFirst = _seedWhere((d) => d.coworkerPit == 0 && d.push == M6PitPush.anyRod && !d.pits[0].lidMissing);
    testWidgets('a fast play: his pit\'s controls wait for him; he cuts in at once', (t) async {
      final c = await _open(t, rodFirst);
      await _lift(t);
      // At once, inside his 1.2–2.4 s timer: TEST.
      await _test(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.reading, isNull, reason: 'the tester did not run');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerRod.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _test(t);
      expect(_live.reading, isNotNull, reason: 'after him the tester runs');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final d = m6PitDeal(math.Random(quietLid));
      final c = await _open(t, quietLid);
      await _playPit(t, d, 0, reason: false);
      // The ◆ on the table, the deck open at once: the scene takes nothing
      // (the lid, the tester) and the action row is gone.
      expect(_label(L.action(M6PitAction.sign)), findsNothing);
      final reading = _live.reading;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.testBtn * _k);
        await t.pump(const Duration(milliseconds: 150));
        await t.dragFrom(_geo.lidOn(0).center * _k, const Offset(0, -60));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.lid, M6Lid.on, reason: 'the lid did not move');
      expect(_live.reading, reading);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[_live.whyTopic]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a nudge on the lid first (no pick); then three taps on nothing show a hand that presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, quietLid);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the lid still on');
      expect(scene().debugOptions, isEmpty, reason: 'a drag nudge, not a pick');
      expect(scene().debugFrame?.ripple, isNull);
      await _lift(t);
      expect(scene().showing, isFalse);
      final empty = const Offset(120, 180) * _k;
      for (var k = 0; k < 3; k++) {
        await t.tapAt(empty);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge or a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
