// Lesson 8.1 (WBERC পরিচিতি), কাজ "তর্ক নয়, তথ্য দিন": the rules (hold to
// listen; a release before his real end = a slip; 'শুনছেন?' after ~2 s with no
// hold = no slip; the right zone of the table answers his question, a wrong
// zone = a slip; listening to the coworker = a slip; no deadly anywhere,
// ruling M8-1), the deal (3 of 4 complaints, places, bursts and false pauses,
// row order, looks, his round), the live lesson lines, the libraries, every
// spoken line listed, the geometry, and the level in the shell: the guide
// first, full clean plays (hold, release, flip or pan, a zone, a reason, the
// coworker refused), an interruption, a wrong zone, three slips, listening =
// a slip, the flip and the pan wait for him, the praise window takes no touch,
// and the gesture hand shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m8_bill_listen.dart';
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
  rungId: '8.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8BillListenPacks['do_8_1_a']!;
typedef L = M8BillListenLines;
typedef Mk = M8BillListenMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

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

Future<bool> _until(WidgetTester t, bool Function() ok, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 50) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 50));
  }
  return ok();
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
M8BillGeo get _geo => M8BillGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8BillRun get _live => M8BillListenProbe.run!;
String get _phase => M8BillListenProbe.phase;
M8BillRound get _round => _live.round;

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8BillListenPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M8BillDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8BillDeal(math.Random(s))));

/// Press the listen pad (the gesture stays down until [TestGesture.up]).
Future<TestGesture> _press(WidgetTester t) => t.startGesture(_geo.padCentre * _k);

/// Hold the pad to his real end; the gesture is still down.
Future<TestGesture> _holdToEnd(WidgetTester t) async {
  await _until(t, () => _phase == 'rant', maxMs: 4000);
  final g = await _press(t);
  expect(await _until(t, () => _phase == 'endHeld', maxMs: 30000), isTrue, reason: 'his real end');
  return g;
}

/// Hold and release after the real end: the evidence step opens.
Future<void> _listen(WidgetTester t) async {
  final g = await _holdToEnd(t);
  await g.up();
  await _pump(t, 200);
  expect(_phase, 'evidence');
}

/// The flip (swipe the bill up) or the pan (drag sideways).
Future<void> _evidence(WidgetTester t) async {
  if (_round.flips) {
    final from = _geo.billHand.center;
    await t.dragFrom(from * _k, const Offset(0, -90) * _k);
  } else {
    await t.dragFrom(_geo.sceneCentre * _k, const Offset(-100, 0) * _k);
  }
  await _pump(t, 200);
}

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

Offset _zoneAt(M8BillZone z) => _geo.zone(z, unitFirst: _round.unitFirst).center;

Future<void> _tapZone(WidgetTester t, M8BillZone z) async {
  await t.tapAt(_zoneAt(z) * _k);
  await _pump(t, 200);
}

/// Open the table: flip or pan (the coworker refused if he cuts in).
Future<void> _toTable(WidgetTester t) async {
  await _evidence(t);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_phase, 'evidence', reason: 'the flip/pan waited for him');
    await _refuse(t);
    await _evidence(t);
  }
  expect(await _until(t, () => _phase == 'table', maxMs: 4000), isTrue, reason: 'the table opens');
  await _pump(t, 1200);
}

/// One round played clean.
Future<void> _playRound(WidgetTester t) async {
  final i = _live.index;
  final zone = _round.zone;
  await _listen(t);
  await _toTable(t);
  await _tapZone(t, zone);
  expect(find.byType(MistakeCard), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[zone]!);
  await _pump(t, 2500);
  if (i < 2) {
    expect(_live.index, i + 1);
  } else {
    expect(_live.done, isTrue);
  }
}

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.1');
}

M8BillRound _roundOf(M8BillComplaint c, {M8BillPlace place = M8BillPlace.door, int bursts = 3, Set<int> pauses = const {0}}) => M8BillRound(
      complaint: c,
      place: place,
      bursts: [...L.fillers.take(bursts - 1), L.complaint(c)],
      pauseAfter: pauses,
      unitFirst: true,
      look: 0,
    );

M8BillRun _runOf(M8BillRound first) => M8BillRun(M8BillDeal(
      rounds: [first, _roundOf(M8BillComplaint.company), _roundOf(M8BillComplaint.fixed)],
      coworkerRound: 1,
      light: 0,
    ));

void main() {
  group('rules', () {
    test('deals: 3 of 4 complaints, no repeat; a flip and a pan every play; 2–4 bursts, 1–2 false pauses; row order, looks, his round and light vary', () {
      final seen = <String>{};
      final complaints = <M8BillComplaint>{};
      final places = <M8BillPlace>{};
      final looks = <int>{};
      final bursts = <int>{};
      final pauses = <int>{};
      final him = <int>{};
      final lights = <int>{};
      var unitFirst = 0, fixedFirst = 0, bothHeaders = 0;
      for (var s = 0; s < 300; s++) {
        final d = m8BillDeal(math.Random(s));
        expect(d.rounds, hasLength(3));
        expect(d.rounds.map((r) => r.complaint).toSet(), hasLength(3), reason: 'no repeat');
        expect(d.rounds.any((r) => r.place == M8BillPlace.office), isTrue, reason: 'a notice-board round');
        expect(d.rounds.any((r) => r.flips), isTrue, reason: 'a bill-flip round');
        expect(d.coworkerRound, inInclusiveRange(0, 2));
        him.add(d.coworkerRound);
        lights.add(d.light);
        if (d.rounds.where((r) => r.zone == M8BillZone.header).length == 2) bothHeaders++;
        for (final r in d.rounds) {
          complaints.add(r.complaint);
          places.add(r.place);
          looks.add(r.look);
          expect(r.bursts.length, inInclusiveRange(2, 4));
          expect(r.bursts.last, L.complaint(r.complaint), reason: 'his question ends it');
          expect(r.bursts.toSet(), hasLength(r.bursts.length));
          for (final b in r.bursts.take(r.bursts.length - 1)) {
            expect(L.fillers, contains(b));
          }
          expect(r.pauseAfter.length, inInclusiveRange(1, 2));
          expect(r.pauseAfter.length, lessThanOrEqualTo(r.bursts.length - 1));
          for (final p in r.pauseAfter) {
            expect(p, inInclusiveRange(0, r.bursts.length - 2), reason: 'a gap between bursts');
          }
          bursts.add(r.bursts.length);
          pauses.add(r.pauseAfter.length);
          r.unitFirst ? unitFirst++ : fixedFirst++;
        }
        seen.add('${d.coworkerRound}${d.light}|${d.rounds.map((r) => '${r.complaint.index}${r.place.index}${r.look}${r.unitFirst}${r.bursts.join()}${r.pauseAfter}').join('|')}');
      }
      expect(seen.length, greaterThan(280));
      expect(complaints, M8BillComplaint.values.toSet());
      expect(places, M8BillPlace.values.toSet());
      expect(looks, {0, 1, 2, 3});
      expect(bursts, {2, 3, 4});
      expect(pauses, {1, 2});
      expect(him, {0, 1, 2});
      expect(lights, hasLength(kM8BillSkies.length));
      expect(unitFirst, greaterThan(300));
      expect(fixedFirst, greaterThan(300));
      expect(bothHeaders, greaterThan(50), reason: 'both header complaints can come in one play');
    });

    test('the zone that answers each complaint', () {
      expect(m8BillZoneOf(M8BillComplaint.company), M8BillZone.header);
      expect(m8BillZoneOf(M8BillComplaint.lineman), M8BillZone.header);
      expect(m8BillZoneOf(M8BillComplaint.unit), M8BillZone.unit);
      expect(m8BillZoneOf(M8BillComplaint.fixed), M8BillZone.fixed);
    });

    test('his rant: held to the end it closes; a false pause stays open; 2 s unheld he waits; resume and replay go from his burst', () {
      final r = _roundOf(M8BillComplaint.unit, bursts: 3, pauses: {0});
      final rant = M8Rant(r);
      var sawPause = false;
      var sawBurst = 0;
      var ticks = 0;
      while (!rant.ended && ticks < 400) {
        final ev = rant.tick(padDown: true);
        if (rant.inPause) {
          sawPause = true;
          expect(rant.shown, endsWith('…'));
          expect(rant.burst, 0, reason: 'the pause is after burst 0');
        }
        if (ev == M8RantEvent.burst) sawBurst++;
        expect(ev, isNot(M8RantEvent.waiting), reason: 'held: he never waits');
        ticks++;
      }
      expect(rant.ended, isTrue);
      expect(sawPause, isTrue);
      expect(sawBurst, 2);
      expect(rant.burst, 2);
      expect(rant.shown, L.complaint(M8BillComplaint.unit));
      expect(rant.tick(padDown: true), M8RantEvent.none, reason: 'done');
      // Never held: he starts, then stops after ~2 s.
      final idle = M8Rant(r);
      var waits = 0;
      for (var i = 0; i < 40; i++) {
        if (idle.tick(padDown: false) == M8RantEvent.waiting) waits++;
      }
      expect(waits, 1);
      expect(idle.waiting, isTrue);
      expect(idle.unheld, greaterThanOrEqualTo(M8Rant.graceMs));
      expect(idle.tick(padDown: true), M8RantEvent.none, reason: 'he waits until the pad is pressed');
      idle.resume();
      expect(idle.waiting, isFalse);
      expect(idle.word, 0, reason: 'from his burst\'s start');
      expect(idle.tick(padDown: true), isNot(M8RantEvent.waiting));
      // The real end only closes on a held pad: let go in the closing lag.
      final late = M8Rant(_roundOf(M8BillComplaint.fixed, bursts: 2, pauses: {0}));
      var gotEnd = false;
      for (var i = 0; i < 400 && !late.closing; i++) {
        late.tick(padDown: true);
      }
      expect(late.closing, isTrue);
      expect(late.burst, 1);
      late.unheld = 1500; // listened, then looked away
      for (var i = 0; i < 20 && !late.waiting; i++) {
        if (late.tick(padDown: false) == M8RantEvent.ended) gotEnd = true;
      }
      expect(gotEnd, isFalse);
      expect(late.waiting, isTrue);
      expect(late.ended, isFalse);
      // Replay: his last burst again, louder.
      late.replay();
      expect(late.louder, isTrue);
      expect(late.waiting, isFalse);
      expect(late.burst, 1);
      expect(late.word, 0);
      // Every burst is words split by spaces (never a code point).
      for (final b in [...L.fillers, for (final c in M8BillComplaint.values) L.complaint(c)]) {
        expect(b.split(' ').join(' '), b);
      }
    });

    test('a tap: the right zone answers; another zone is a slip with this complaint\'s card; the pad released early is a slip', () {
      final r = _runOf(_roundOf(M8BillComplaint.company));
      expect(r.tap(M8BillZone.unit), (M8BillTap.wrong, Mk.wrongCompany));
      expect(r.tap(M8BillZone.fixed), (M8BillTap.wrong, Mk.wrongCompany));
      expect(r.slips, 2);
      expect(r.tap(M8BillZone.header), (M8BillTap.right, null));
      expect(r.caught.single, L.caughtZone(M8BillZone.header));
      expect(r.interrupt(), Mk.interrupt);
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.next();
      final u = r;
      expect(u.round.complaint, M8BillComplaint.company);
      expect(u.tap(M8BillZone.header).$1, M8BillTap.right);
      u.next();
      expect(u.tap(M8BillZone.header), (M8BillTap.wrong, Mk.wrongFixed));
      expect(u.tap(M8BillZone.fixed).$1, M8BillTap.right);
      u.next();
      expect(u.done, isTrue);
      expect(u.slips, 4);
      expect(u.passed, isFalse, reason: '40 is below the pass mark of 55');
      expect(u.tap(M8BillZone.header), (M8BillTap.wrong, null));
      // Both header complaints answer with the header.
      final l = _runOf(_roundOf(M8BillComplaint.lineman));
      expect(l.tap(M8BillZone.unit), (M8BillTap.wrong, Mk.wrongLineman));
      expect(l.tap(M8BillZone.header).$1, M8BillTap.right);
      final un = _runOf(_roundOf(M8BillComplaint.unit));
      expect(un.tap(M8BillZone.fixed), (M8BillTap.wrong, Mk.wrongUnit));
      expect(un.pushSlip(), Mk.pushListen);
      expect(un.slips, 2);
      expect(un.percent, 70);
    });

    test('no deadly in 8.1 (M8-1): every mistake a slip; keys, pictures, the tariff point; listening = a slip', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      expect(Mk.all.map((m) => m.textBn).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.1/m8_bill_listen/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(Mk.all.where((x) => x.key == m.key), hasLength(1));
      }
      for (final c in M8BillComplaint.values) {
        expect(Mk.wrongZone(c).lessonPoint, 2, reason: 'lesson 8.1 point 3 is the tariff');
        expect(Mk.wrongZone(c).deadly, isFalse);
      }
      expect(Mk.interrupt.lessonPoint, isNull, reason: 'pro tip 1, not a numbered point');
      expect(Mk.pushListen.lessonPoint, isNull, reason: 'a myth, not a numbered point');
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_bill_listen/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8BillListenPacks.keys, ['do_8_1_a']);
    });

    test('the live lesson: tariff line, pro tip 1, the myth and its reality word for word; the table shows only what the lesson names', () {
      final lesson = _lesson();
      final text = _nk(jsonEncode(lesson));
      expect(text, contains(_nk('স্যার, এই রেট আমাদের কোম্পানি ঠিক করে না, এটা কমিশনের অর্ডার।')));
      expect(_nk(L.reply), _nk('স্যার, এই রেট আমাদের কোম্পানি ঠিক করে না, এটা কমিশনের অর্ডার।'));
      expect(text, contains(_nk('গ্রাহক বিল নিয়ে রেগে গেলে তর্কে জড়াবেন না')));
      expect(text, contains(_nk('বিলের পেছনের অংশে বা নোটিশ বোর্ডে ট্যারিফ চার্ট দেখে নিন')));
      expect(text, contains(_nk('ইউনিট প্রতি বিদ্যুতের দাম কত হবে, ফিক্সড চার্জ কত হবে')));
      // The myth the coworker pushes (a shortcut) and the reality on the card.
      final myths = ((lesson['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      expect(_nk((myths[0] as Map)['myth'] as String), contains(_nk('ইচ্ছামতো বাড়ায়')));
      expect(text, contains(_nk('কোম্পানি শুধু প্রস্তাব দেয় যে তাদের খরচ বেড়েছে')));
      expect(text, contains(_nk('জনশুনানি করে, সব দিক বিচার করে তারপর নতুন রেট ঘোষণা করে')));
      expect(_nk(Mk.pushListen.textBn), contains(_nk('কোম্পানি শুধু প্রস্তাব দেয় যে তাদের খরচ বেড়েছে')));
      expect(_nk(Mk.pushListen.textBn), contains(_nk('জনশুনানি করে, সব দিক বিচার করে তারপর নতুন রেট ঘোষণা করে')));
      expect(_nk(Mk.interrupt.textBn), contains(_nk('তর্কে জড়াবেন না')));
      expect(L.tableHead, 'WBERC ট্যারিফ অর্ডার');
      expect(L.rowUnit, 'ইউনিট প্রতি দাম');
      expect(L.rowFixed, 'ফিক্সড চার্জ');
      // No on-screen line says 'সরকারি' (spec unsupported) and no rate figure appears.
      final screen = [L.tableHead, L.rowUnit, L.rowFixed, L.reply, ...L.fillers, for (final c in M8BillComplaint.values) L.complaint(c), L.storm, L.areYouListening];
      for (final s in screen) {
        expect(s.contains('সরকারি'), isFalse, reason: s);
        expect(RegExp('[0-9]').hasMatch(s.replaceAll('WBERC', '')), isFalse, reason: s);
      }
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ"; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.areYouListening,
        L.storm,
        L.reply,
        L.tableHead,
        L.rowUnit,
        L.rowFixed,
        ...L.fillers,
        for (final c in M8BillComplaint.values) L.complaint(c),
        for (final z in M8BillZone.values) ...[L.whyQ(z), ...L.whyWrong(z), L.caughtZone(z)],
        ...L.allWhyRight,
        for (final p in M8BillPlace.values) L.placeName(p),
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expectSameLength('why', [...L.allWhyRight, ...L.allWhyWrong]);
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final z in M8BillZone.values) {
        expectLibrary('why $z', L.whyRight[z]!, L.whyWrong(z));
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(L.whyRight[z]!, L.whyWrong(z), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong);
      expect(cw.asks, contains('কী করবেন?'));
    });

    test('spoken lines: his exit is recorded; his push and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['বলে দাও কোম্পানি নিজের ইচ্ছেমতো রেট বাড়িয়েছে — ঝামেলা মিটে যাবে।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, for (final z in M8BillZone.values) L.whyQ(z), 'ওর কথা মানবেন?', L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      expect(L.reused, contains('ওকে কী বলবেন?'), reason: 'it already has a clip');
      expect(L.newGuideLines, isNot(contains('ওকে কী বলবেন?')));
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      // Every line the page speaks is in one of the lists; the consumer's
      // words and the reply are silent captions (never spoken).
      final spoken = L.spokenLines.toSet();
      for (final l in [L.intro, ...L.tasks, ...L.tapWhy, L.callHeld, L.allSet, L.quick, L.fail, L.coworker.line, L.coworkerExit, ...L.coworker.asks, for (final z in M8BillZone.values) L.whyQ(z), for (final m in Mk.all) m.textBn]) {
        expect(spoken, contains(l), reason: l);
      }
      for (final l in [L.reply, L.storm, L.areYouListening, ...L.fillers, for (final c in M8BillComplaint.values) L.complaint(c)]) {
        expect(spoken, isNot(contains(l)), reason: 'silent caption: $l');
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_bill_listen: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: the zones are equal, stacked, header on top, rows in dealt order; pad, bill and bubble stay clear', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M8BillGeo.forScene(h, inset);
          for (final first in [true, false]) {
            final zs = [for (final z in M8BillZone.values) g.zone(z, unitFirst: first)];
            expect(zs[0].top, g.table.top, reason: 'the header is always on top');
            expect(zs[0].height, closeTo(zs[1].height, 0.001));
            expect(zs[1].height, closeTo(zs[2].height, 0.001));
            expect(zs[0].width, zs[1].width);
            for (final (i, a) in zs.indexed) {
              expect(g.table.contains(a.topLeft) && g.table.contains(a.bottomRight - const Offset(1, 1)), isTrue);
              for (final b in zs.skip(i + 1)) {
                expect(a.overlaps(b), isFalse);
              }
            }
            expect(g.zone(M8BillZone.unit, unitFirst: first).top < g.zone(M8BillZone.fixed, unitFirst: first).top, first);
          }
          expect(g.panel.contains(g.table.topLeft) && g.panel.contains(g.table.bottomRight), isTrue);
          expect(g.pad.bottom, lessThanOrEqualTo(h));
          expect(g.pad.left, greaterThan(100));
          expect(g.pad.right, lessThan(244), reason: 'clear of the guide in the corner');
          expect(g.bubble.top, greaterThan(140), reason: 'under the header');
          expect(g.bubble.overlaps(g.trainee), isFalse);
          expect(g.bubble.overlaps(g.consumer), isFalse);
          expect(g.billTouch.left, greaterThan(g.trainee.right));
          expect(g.billHand.overlaps(g.pad), isFalse);
          expect(g.consumer.right, lessThanOrEqualTo(360));
          expect(g.trainee.overlaps(g.consumer), isFalse);
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

    testWidgets('the guide comes first: a tap does not skip him; then the listen pad is the control', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8BillListenPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 800);
      expect(_label(L.padWord), findsOneWidget);
      expect(find.text(L.tableHead), findsNothing, reason: 'no chart before the rant ends');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the task pool in turn, never a zone', (t) async {
      final c = await _open(t, 5);
      expect(c.read(guideDirectorProvider).line, contains(L.askListen));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.tapQuestion, L.tapPaper, L.tapFacts]);
      for (final l in lines) {
        expect(l.contains('হেডার') || l.contains('ইউনিট') || l.contains('ফিক্সড'), isFalse, reason: l);
      }
      await _close(t, c);
    });

    // His round 0, 1 and 2; each play has a bill-flip and a notice-board round.
    final flowSeeds = [for (var r = 0; r < 3; r++) _seedWhere((d) => d.coworkerRound == r)];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three rounds, hold, release, flip or pan, a zone, reasons, he is refused → pass', (t) async {
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRound(t);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.1/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.1/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('releasing the pad before his real end = a slip with its card; his last burst replays louder; the round goes on', (t) async {
      final c = await _open(t, 7);
      await _until(t, () => _phase == 'rant', maxMs: 4000);
      final g = await _press(t);
      await _pump(t, 700);
      expect(_phase, 'rant');
      await g.up();
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.interrupt.textBn), findsOneWidget);
      expect(_live.slips, 1);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      expect(M8BillListenProbe.rant!.louder, isTrue);
      expect(M8BillListenProbe.rant!.word, lessThan(4), reason: 'his burst starts again');
      // Hold again to the real end: no second slip.
      await _listen(t);
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.interrupt.key]);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('not held ~2 s after he starts: "শুনছেন?" and he waits (no slip); pressing the pad goes on', (t) async {
      final c = await _open(t, 9);
      await _until(t, () => _phase == 'rant', maxMs: 4000);
      expect(await _until(t, () => M8BillListenProbe.rant!.waiting, maxMs: 6000), isTrue);
      await _pump(t, 300);
      expect(find.text(L.areYouListening), findsOneWidget);
      await _pump(t, 4000);
      expect(find.text(L.areYouListening), findsOneWidget, reason: 'he waits as long as it takes');
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      // The press made him go on: letting go again is interrupting.
      final g0 = await _press(t);
      await g0.up();
      await _pump(t, 200);
      expect(_live.slips, 1, reason: 'he started again at the press: letting go is interrupting');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      await _listen(t);
      await _close(t, c);
    });

    final wrongSeed = _seedWhere((d) => d.rounds.first.zone == M8BillZone.unit || d.rounds.first.zone == M8BillZone.fixed);
    testWidgets('a wrong zone is a slip with its card; the table stays; the right zone then answers', (t) async {
      final c = await _open(t, wrongSeed);
      final r = _round;
      await _listen(t);
      await _toTable(t);
      final wrong = M8BillZone.header;
      await _tapZone(t, wrong);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.wrongZone(r.complaint).textBn), findsOneWidget);
      expect(_live.slips, 1);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_phase, 'table');
      expect(_live.index, 0);
      await _tapZone(t, r.zone);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[r.zone]!);
      await _pump(t, 2000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.wrongZone(r.complaint).key]);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (wrong zones); no freeze, no deadly', (t) async {
      final c = await _open(t, wrongSeed);
      await _listen(t);
      await _toTable(t);
      for (var i = 0; i < 3; i++) {
        await _tapZone(t, M8BillZone.header);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 8.1');
      expect(c.read(gameSaveProvider).mistakes.where((m) => m.deadly), isEmpty);
      await _close(t, c);
    });

    final hisFirst = _seedWhere((d) => d.coworkerRound == 0);
    testWidgets('listening to him = a slip (no freeze); the consumer storms off, the round resumes at the evidence step; the flip/pan waited for him', (t) async {
      final c = await _open(t, hisFirst);
      await _listen(t);
      await _evidence(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the flip/pan waits for him');
      expect(_phase, 'evidence');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushListen.textBn), findsOneWidget);
      expect(find.text(L.storm), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.pushListen.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(L.storm), findsNothing);
      expect(_phase, 'evidence', reason: 'resumes at the evidence step');
      // He came once: the next flip/pan goes through.
      await _toTable(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_live.slips, 1);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the next round starts', (t) async {
      final seed = _seedWhere((d) => d.coworkerRound != 0);
      final c = await _open(t, seed);
      final r = _round;
      await _listen(t);
      await _toTable(t);
      await _tapZone(t, r.zone);
      expect(_live.caught, hasLength(1));
      // At once: more taps on the table do nothing (shielded, then the deck).
      await t.tapAt(_zoneAt(M8BillZone.header) * _k);
      await t.tapAt(_zoneAt(r.zone == M8BillZone.unit ? M8BillZone.fixed : M8BillZone.unit) * _k);
      await _pump(t, 100);
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(L.reply), findsOneWidget, reason: 'the trainee\'s reply is a caption');
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[r.zone]!);
      await _pump(t, 2500);
      expect(_live.index, 1);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a swipe that is not up on the bill, or a tap on nothing, costs nothing and opens nothing', (t) async {
      final seed = _seedWhere((d) => d.rounds.first.flips && d.coworkerRound != 0);
      final c = await _open(t, seed);
      await _listen(t);
      await t.dragFrom(const Offset(120, 300) * _k, const Offset(0, -90) * _k);
      await _pump(t, 300);
      await t.tapAt(const Offset(180, 330) * _k);
      await _pump(t, 300);
      expect(_phase, 'evidence');
      expect(_live.slips, 0);
      expect(find.text(L.tableHead), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hand: hold on the pad while he waits; a swipe on the bill or a sideways drag; a sweep over the 3 zones (presses none)', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.rounds.first.flips && d.coworkerRound != 0);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      // He talks, the pad is not held: the hold hand once he waits.
      await _until(t, () => M8BillListenProbe.rant?.waiting ?? false, maxMs: 6000);
      expect(scene().showing, isFalse, reason: 'not at once');
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'he waits, the pad is not held');
      // Holding the pad hides it at once.
      final g = await _press(t);
      await _pump(t, 600);
      expect(scene().showing, isFalse);
      expect(await _until(t, () => _phase == 'endHeld', maxMs: 30000), isTrue);
      expect(scene().showing, isFalse, reason: 'never while held');
      await g.up();
      await _pump(t, 300);
      expect(_phase, 'evidence');
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'the bill held out: a swipe hand');
      await _toTable(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'the table is open');
      expect(scene().debugOptions, hasLength(3), reason: 'every zone alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _close(t, c);
    });
  });
}
