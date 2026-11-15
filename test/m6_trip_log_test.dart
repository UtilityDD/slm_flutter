// Lesson 6.2 (সার্কিট ব্রেকার), কাজ 1 "ট্রিপের খাতা": the rules (every green
// panel marked open and no red one; the register takes the feeder whose relay
// dropped flags, its phases and its fault — else a slip; an empty cell is no
// slip; a reply that sends the crew up on the trip / green alone (R1) or with
// one end isolated / locked but not earthed (R2) = deadly), the deal, the
// libraries, the coworker's gates, and the level in the shell: the guide
// first, a full clean play (a reason pick each stage, the coworker refused),
// a slip card that keeps the stage, three slips, the deadly freeze (a deadly
// reply; listening to the radio myth), his slip push with its bang, the door
// waits for him on a fast play, the praise window takes no touch, and the
// gesture hand shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m6_trip_log.dart';
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
  rungId: '6.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m6TripLogPacks['do_6_2_a']!;
typedef L = M6TripLogLines;
typedef Mk = M6TripLogMistakes;

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
M6TripGeo get _geo => M6TripGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0));
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tapLabel(WidgetTester t, String l) async {
  await t.tap(_label(l));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6TripLogPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6TripDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6TripDeal(math.Random(s))));

/// The coworker comes (his gate reached): refuse him.
Future<void> _refuse(WidgetTester t, M6Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

/// The breaker room: in through the door, every open panel marked, 'দেখা শেষ',
/// the green reason.
Future<void> _panels(WidgetTester t, M6TripDeal d) async {
  await _tapAt(t, M6TripGeo.doorToBreakers.center);
  for (var i = 0; i < d.n; i++) {
    if (d.isOpen(i)) await _tapAt(t, _geo.panel(i, d.n).center);
  }
  await _tapLabel(t, L.lookDone);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'panels read');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the green reason');
  await _pickRight(t, L.whyRight[M6WhyTopic.green]!);
  await _pump(t, 1600);
}

/// The register filled right (no write yet).
Future<void> _fill(WidgetTester t, M6TripDeal d) async {
  await _tapAt(t, M6TripGeo.relay(d.tripped, d.n).center);
  await _tapLabel(t, d.names[d.tripped]);
  for (final p in d.flags) {
    await _tapLabel(t, L.phases[p]);
  }
  await _tapLabel(t, L.faultChip(d.fault));
}

void main() {
  group('rules', () {
    M6TripDeal deal({int n = 4, int tripped = 1, int planned = -1, Set<int> flags = const {0, 2}, M6Fault fault = M6Fault.short, M6Push push = M6Push.radio}) => M6TripDeal(
          names: L.feederNames.take(n).toList(),
          faces: [for (var i = 0; i < n; i++) M6Face.vcb],
          tripped: tripped,
          planned: planned,
          flags: flags,
          fault: fault,
          counters: [for (var i = 0; i < n; i++) 1000 + i],
          push: push,
          crewAsk: 0,
          logWhy: M6WhyTopic.note,
        );

    /// A run past the panels, back in the control room.
    M6TripRun atLog(M6TripDeal d) {
      final r = M6TripRun(d)..enterBreakers();
      for (var i = 0; i < d.n; i++) {
        if (d.isOpen(i)) r.toggleMark(i);
      }
      r
        ..finishLook()
        ..next()
        ..leaveBreakers();
      return r;
    }

    test('deals: 3–4 feeders, one tripped, sometimes a planned-OFF one; flags 1–3; every push; plays differ', () {
      final seen = <String>{};
      final pushes = <M6Push>{};
      final whys = <M6WhyTopic>{};
      var planned = 0, radio = 0, three = 0, untagged = 0;
      for (var s = 0; s < 200; s++) {
        final d = m6TripDeal(math.Random(s));
        expect(d.n, inInclusiveRange(3, 4));
        expect(d.names.toSet(), hasLength(d.n));
        expect(d.faces, hasLength(d.n));
        expect(d.counters, hasLength(d.n));
        expect(d.tripped, inInclusiveRange(0, d.n - 1));
        if (d.planned >= 0) {
          planned++;
          expect(d.planned, isNot(d.tripped));
          expect(d.planned, lessThan(d.n));
        }
        expect(d.flags, isNotEmpty);
        expect(d.flags.every((p) => p >= 0 && p <= 2), isTrue);
        expect([M6WhyTopic.relay, M6WhyTopic.note], contains(d.logWhy));
        // 'Why the relay?' only where the relay told two greens apart.
        if (d.logWhy == M6WhyTopic.relay) expect(d.planned, greaterThanOrEqualTo(0));
        if (d.planned < 0) expect(d.tagged, isTrue);
        if (d.planned >= 0 && !d.tagged) untagged++;
        // The room-push bang: a closed panel, never an open one.
        final bang = m6BangPanel(d);
        expect(d.isOpen(bang), isFalse);
        expect(bang, inInclusiveRange(0, d.n - 1));
        if (d.push == M6Push.radio) radio++;
        if (d.n == 3) three++;
        pushes.add(d.push);
        whys.add(d.logWhy);
        seen.add('${d.names.join()}|${d.faces.map((f) => f.index).join()}|${d.tripped}${d.planned}|${d.flags.toList()..sort()}${d.fault.name}|${d.push.name}${d.crewAsk}');
      }
      expect(seen.length, greaterThan(180));
      expect(pushes, M6Push.values.toSet());
      expect(whys, {M6WhyTopic.relay, M6WhyTopic.note});
      expect(planned, inInclusiveRange(60, 120), reason: 'a second open breaker in about 45 % of plays');
      expect(untagged, inInclusiveRange(planned ~/ 4, planned * 3 ~/ 4), reason: 'about half the planned-OFF breakers carry no lock + tag');
      expect(radio, inInclusiveRange(70, 130), reason: 'the radio myth in about half the plays');
      expect(three, inInclusiveRange(60, 140));
    });

    test('panels: every green marked, no red; the planned-OFF breaker is open too', () {
      final d = deal(planned: 3);
      final r = M6TripRun(d);
      expect(r.toggleMark(1), isFalse, reason: 'still in the control room');
      expect(r.enterBreakers(), isTrue);
      expect(r.room, M6Room.breakers);
      expect(r.finishLook(), Mk.missGreen, reason: 'nothing marked');
      r.toggleMark(1);
      expect(r.finishLook(), Mk.missGreen, reason: 'the planned-OFF one is green too');
      r
        ..toggleMark(3)
        ..toggleMark(0);
      expect(r.finishLook(), Mk.markRed, reason: 'a red panel marked');
      r.toggleMark(0);
      expect(r.marks, {1, 3}, reason: 'a second tap rubs the mark off');
      expect(r.leaveBreakers(), isFalse, reason: 'the door waits for the panels');
      expect(r.finishLook(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.slips, 3);
      expect(r.caught, contains(L.caughtGreen));
      expect(r.toggleMark(2), isFalse, reason: 'the praise window takes nothing');
      r.next();
      expect(r.stage, M6TripStage.toControl);
      expect(r.room, M6Room.breakers);
      expect(r.leaveBreakers(), isTrue);
      expect(r.room, M6Room.control);
    });

    test('register: only the flagged relay\'s feeder, its phases and its fault; an empty cell is no slip', () {
      final d = deal(planned: 2, flags: {0, 2}, fault: M6Fault.short);
      final r = atLog(d);
      expect(r.stage, M6TripStage.log);
      expect(r.slips, 0);
      expect(r.flagsOf(2), isEmpty, reason: 'the planned-OFF relay dropped nothing');
      expect(r.windowOf(2), isNull);
      expect(r.flagsOf(1), {0, 2});
      expect(r.windowOf(1), M6Fault.short);
      expect(r.writeLog(), isNull, reason: 'empty register: no slip');
      expect(r.slips, 0);
      r
        ..look(2)
        ..stampFeeder(2)
        ..tickPhase(0)
        ..tickPhase(2)
        ..pickFault(M6Fault.short);
      expect(r.logComplete, isTrue);
      expect(r.writeLog(), Mk.noFlag, reason: 'the planned-OFF feeder logged as the trip');
      r.stampFeeder(1);
      r.tickPhase(2);
      expect(r.writeLog(), Mk.wrongPhase);
      r.tickPhase(2);
      r.tickPhase(1);
      expect(r.writeLog(), Mk.wrongPhase, reason: 'one phase too many');
      r.tickPhase(1);
      r.pickFault(M6Fault.overload);
      expect(r.writeLog(), Mk.wrongType);
      r.pickFault(M6Fault.short);
      expect(r.writeLog(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtLog));
      expect(r.slips, 4);
    });

    test('radio: the right reply; every wrong card is a deadly act (R1 / R2)', () {
      for (final card in L.replyGreen) {
        final r = atLog(deal())..stampFeeder(1);
        r
          ..tickPhase(0)
          ..tickPhase(2)
          ..pickFault(M6Fault.short)
          ..writeLog()
          ..next();
        expect(r.stage, M6TripStage.radio);
        final m = r.reply(false, card: card);
        expect(m, Mk.greenAlone);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
        expect(r.slips, 0);
      }
      for (final card in L.replyHalf) {
        expect(Mk.reply(card), Mk.halfIsolation);
      }
      final ok = atLog(deal())
        ..stampFeeder(1)
        ..tickPhase(0)
        ..tickPhase(2)
        ..pickFault(M6Fault.short)
        ..writeLog()
        ..next();
      expect(ok.reply(true), isNull);
      expect(ok.caught, contains(L.caughtSafe));
      ok.next();
      expect(ok.done, isTrue);
      expect(ok.passed, isTrue);
      expect(ok.percent, 100);
    });

    test('the coworker comes at his gate only', () {
      final d = deal(push: M6Push.room);
      final r = M6TripRun(d);
      expect(m6PushGateReached(M6Push.room, r), isFalse);
      r
        ..enterBreakers()
        ..toggleMark(1)
        ..finishLook();
      expect(m6PushGateReached(M6Push.room, r), isFalse, reason: 'not over the praise window');
      r.next();
      expect(m6PushGateReached(M6Push.room, r), isTrue, reason: 'at the breaker-room door');
      r.leaveBreakers();
      expect(m6PushGateReached(M6Push.room, r), isFalse);
      expect(m6PushGateReached(M6Push.log, r), isFalse);
      r
        ..look(1)
        ..stampFeeder(1)
        ..tickPhase(0);
      expect(m6PushGateReached(M6Push.log, r), isFalse, reason: 'the fault cell still empty');
      r.pickFault(M6Fault.short);
      expect(m6PushGateReached(M6Push.log, r), isTrue);
      r
        ..tickPhase(2)
        ..writeLog()
        ..next();
      expect(m6PushGateReached(M6Push.radio, r), isFalse, reason: 'the crew has not asked yet');
      expect(m6PushGateReached(M6Push.radio, r, crewAsked: true), isTrue);
      expect(Mk.push(M6Push.radio), Mk.greenAlone);
      expect(Mk.push(M6Push.log), Mk.resetEarly);
      expect(Mk.push(M6Push.room), Mk.stayRoom);
      expect(Mk.push(M6Push.log).deadly || Mk.push(M6Push.room).deadly, isFalse, reason: 'B1: his slip pushes are slips');
    });

    test('three slips and the mark falls to 55; a fourth to 40', () {
      final r = M6TripRun(deal())..enterBreakers();
      for (var i = 0; i < 3; i++) {
        r.finishLook();
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.finishLook();
      expect(r.percent, 40);
    });

    test('English digits only; jol not pani; every mistake has its picture; the deadly set; keys unique; the art folder', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.panelsFirst,
        L.fillAll,
        L.lookDone,
        L.register,
        L.rowFeeder,
        L.rowPhase,
        L.rowFault,
        L.write,
        for (final f in M6Fault.values) ...[L.faultChip(f), L.faultWindow(f)],
        ...L.feederNames,
        ...L.rounds,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.replyRight,
        ...L.replyWrong,
        ...L.crewAsk,
        L.crewOk,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M6Push.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
        L.caughtGreen,
        L.caughtLog,
        L.caughtSafe,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.greenAlone, Mk.halfIsolation});
      expect(Mk.deadlyKeys, ['6.2/m6_trip_log/green-alone', '6.2/m6_trip_log/half-isolation']);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.2/m6_trip_log/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      const dir = 'assets/game/art/m6_trip_log/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m6_trip_log').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file used, no .gitkeep left');
      expect(m6TripLogPacks.keys, ['do_6_2_a']);
      // The right reply names the tester (live pro tip 1, ruling X1).
      for (final r in L.replyRight) {
        expect(r.contains('দুই'), isTrue, reason: r);
        expect(r.contains('টেস্টার'), isTrue, reason: r);
        expect(r.contains('আর্থ'), isTrue, reason: r);
      }
      // No giveaway (§4): every wrong card is a procedure in the same calm
      // register with one deadly gap — both ends, the tester or the earth
      // missing — and no reckless cue words. Never earth without the tester
      // (only a slip under X1).
      for (final w in L.replyWrong) {
        final full = w.contains('দুই') && w.contains('টেস্টার') && w.contains('আর্থ');
        expect(full, isFalse, reason: 'a deadly gap: $w');
        for (final cue in ['নির্ভয়', 'দেরি', 'এখনই', 'ছাড়াই', 'ফেলুন', 'তাড়াতাড়ি']) {
          expect(w.contains(cue), isFalse, reason: 'cue word $cue: $w');
        }
        if (w.contains('আর্থ')) expect(w.contains('টেস্টার'), isTrue, reason: 'earth without the tester is only a slip: $w');
        expect(RegExp('তবে|তারপর').hasMatch(w), isTrue, reason: 'reads as a procedure: $w');
      }
      expect(L.replyWrong.where((w) => w.contains('টেস্টার')), hasLength(greaterThanOrEqualTo(2)), reason: 'decoys that name the tester too');
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M6WhyTopic.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectLibrary('reply', L.replyRight, L.replyWrong);
      expectSameLength('reply', [...L.replyRight, ...L.replyWrong]);
      for (var k = 0; k < 20; k++) {
        final deal = dealChoices(L.replyRight, L.replyWrong, math.Random(k));
        expect(deal.where((o) => o.correct), hasLength(1));
        for (final o in deal.where((o) => !o.correct)) {
          expect(Mk.reply(o.textBn).deadly, isTrue, reason: 'both wrong replies are deadly: ${o.textBn}');
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      expectSameLength('feeder stamps', L.feederNames);
      expectSameLength('fault chips', [for (final f in M6Fault.values) L.faultChip(f)]);
    });

    test('rival lines: his exit is recorded; his three pushes and the crew\'s lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      final pushes = {for (final p in M6Push.values) L.coworker(p).line};
      expect(pushes, L.newRivalLines.toSet());
      expect(pushes, {
        'সার্কিট ব্রেকার ট্রিপ করেছে মানে লাইনটি সম্পূর্ণ বন্ধ। এতে কোনো ভোল্টেজ নেই। উঠে পড়ুক!',
        'লিখে কী হবে? ব্রেকার তো রিসেট হয় — আবার চালু করে দাও!',
        'ব্রেকার রুমেই একটু বসি, এখানে ঠান্ডা।',
      });
      // (a) starts with the 6.2 myth word for word.
      expect(L.coworkerRadio.line.startsWith('সার্কিট ব্রেকার ট্রিপ করেছে মানে লাইনটি সম্পূর্ণ বন্ধ। এতে কোনো ভোল্টেজ নেই।'), isTrue);
      expect(L.newRadioLines, [...L.crewAsk, L.crewOk]);
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...L.whyQ.values]));
      for (final l in [...L.newRivalLines, ...L.newRadioLines]) {
        debugPrint('RIVAL m6_trip_log: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, below the header and clear of the guide', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M6TripGeo.forScene(h);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        for (final n in [3, 4]) {
          final control = [for (var i = 0; i < n; i++) M6TripGeo.relay(i, n), M6TripGeo.doorToBreakers];
          final breakers = [for (var i = 0; i < n; i++) g.panel(i, n), M6TripGeo.doorToControl, g.lookDone];
          for (final room in [control, breakers]) {
            for (final r in room) {
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(360));
              expect(r.top, greaterThan(125), reason: 'below the header');
              expect(r.bottom, lessThan(g.floorY + 1), reason: 'h $h: $r above the floor');
              expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
            }
            for (var i = 0; i < room.length; i++) {
              for (var j = i + 1; j < room.length; j++) {
                expect(room[i].overlaps(room[j]), isFalse, reason: 'h $h n $n: $i/$j');
              }
            }
          }
          // The lens sits under the relays, never over a case or the door.
          for (final r in control) {
            expect(M6TripGeo.lens.overlaps(r), isFalse);
          }
        }
        expect(M6TripGeo.lens.bottom, lessThan(h - 180), reason: 'h $h: the lens above the register');
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

    testWidgets('the guide comes first: a tap does not skip him; then the control room', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6TripLogPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.sceneLabel), findsOneWidget);
      expect(_label(L.lookDone), findsNothing, reason: 'still in the control room');
      expect(_label(L.write), findsNothing, reason: 'no register before a relay is read');
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
      expect(lines.every((l) => l.contains(L.askDoor)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play per push (radio: deadly-class, refused; register and room:
    // slip-class, refused), with and without a planned-OFF breaker.
    final flowSeeds = [
      _seedWhere((d) => d.push == M6Push.radio && d.planned >= 0 && d.logWhy == M6WhyTopic.relay),
      _seedWhere((d) => d.push == M6Push.log && d.planned < 0 && d.n == 4),
      _seedWhere((d) => d.push == M6Push.room && d.logWhy == M6WhyTopic.note),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): panels, relay, register, radio, reasons; he is refused → pass', (t) async {
        final d = m6TripDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _panels(t, d);
        if (d.push == M6Push.room) await _refuse(t, M6Push.room);
        await _tapAt(t, M6TripGeo.doorToControl.center);
        expect(_label(L.lookDone), findsNothing, reason: 'back in the control room');
        await _fill(t, d);
        if (d.push == M6Push.log) await _refuse(t, M6Push.log);
        await _tapLabel(t, L.write);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'the register is right');
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
        await _pickRight(t, L.whyRight[d.logWhy]!);
        // The radio: the crew asks (the myth first, if dealt), then the reply.
        expect(await _pumpUntil(t, find.text(L.crewAsk[d.crewAsk]), maxMs: 6000), isTrue, reason: 'the crew asks');
        if (d.push == M6Push.radio) await _refuse(t, M6Push.radio);
        await _pickRight(t, L.replyRight);
        expect(await _pumpUntil(t, find.text(L.crewOk)), isTrue, reason: 'the crew confirms');
        await _pickRight(t, L.whyRight[M6WhyTopic.climb]!);
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.2/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.2/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtSafe), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (দেখা শেষ with nothing marked) shows its card; the panels go on after it', (t) async {
      const seed = 2;
      final d = m6TripDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _tapAt(t, M6TripGeo.doorToBreakers.center);
      await _tapLabel(t, L.lookDone);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.missGreen.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(L.lookDone), findsOneWidget, reason: 'the same stage');
      // A red one marked as well as the greens: the other slip.
      final red = [for (var i = 0; i < d.n; i++) if (!d.isOpen(i)) i].first;
      for (var i = 0; i < d.n; i++) {
        if (d.isOpen(i) || i == red) await _tapAt(t, _geo.panel(i, d.n).center);
      }
      await _tapLabel(t, L.lookDone);
      expect(find.text(Mk.markRed.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), containsAll([Mk.missGreen.key, Mk.markRed.key]));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, M6TripGeo.doorToBreakers.center);
      for (var i = 0; i < 3; i++) {
        await _tapLabel(t, L.lookDone);
        await _pump(t, 300);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final logAlone = _seedWhere((d) => d.push == M6Push.radio && d.planned >= 0);
    testWidgets('register: an empty cell is no slip; the planned-OFF feeder logged = the no-flag slip', (t) async {
      final d = m6TripDeal(math.Random(logAlone));
      final c = await _open(t, logAlone);
      await _panels(t, d);
      await _tapAt(t, M6TripGeo.doorToControl.center);
      await _tapAt(t, M6TripGeo.relay(d.planned, d.n).center);
      expect(_label(L.write), findsOneWidget, reason: 'the register slides up');
      await _tapLabel(t, L.write);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.fillAll));
      await _tapLabel(t, d.names[d.planned]);
      await _tapLabel(t, L.phases[0]);
      await _tapLabel(t, L.faultChip(M6Fault.overload));
      await _tapLabel(t, L.write);
      expect(find.text(Mk.noFlag.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noFlag.key);
      await _close(t, c);
    });

    final radioSeed = _seedWhere((d) => d.push != M6Push.radio && d.push != M6Push.room);
    testWidgets('a deadly reply: the room freezes first, then the card (near-miss)', (t) async {
      final d = m6TripDeal(math.Random(radioSeed));
      final c = await _open(t, radioSeed);
      await _panels(t, d);
      await _tapAt(t, M6TripGeo.doorToControl.center);
      await _fill(t, d);
      await _refuse(t, M6Push.log);
      await _tapLabel(t, L.write);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pickRight(t, L.whyRight[d.logWhy]!);
      expect(await _pumpUntil(t, find.text(L.crewAsk[d.crewAsk]), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.replyWrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      expect([Mk.greenAlone.key, Mk.halfIsolation.key], contains(s.mistakes.single.key));
      await _close(t, c);
    });

    final mythSeed = _seedWhere((d) => d.push == M6Push.radio);
    testWidgets('listening to the radio myth = deadly: freeze, then the card', (t) async {
      final d = m6TripDeal(math.Random(mythSeed));
      final c = await _open(t, mythSeed);
      await _panels(t, d);
      await _tapAt(t, M6TripGeo.doorToControl.center);
      await _fill(t, d);
      await _tapLabel(t, L.write);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pickRight(t, L.whyRight[d.logWhy]!);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue, reason: 'he speaks before the reply');
      expect(find.byKey(const ValueKey('reply-deck')), findsNothing, reason: 'the reply waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerRadio.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.greenAlone.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final resetSeed = _seedWhere((d) => d.push == M6Push.log);
    testWidgets('listening to "reset it" is a slip (the breaker re-trips with a bang); the register goes on', (t) async {
      final d = m6TripDeal(math.Random(resetSeed));
      final c = await _open(t, resetSeed);
      await _panels(t, d);
      await _tapAt(t, M6TripGeo.doorToControl.center);
      await _fill(t, d);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      await t.tap(_onScreen(L.coworkerLog.wrong).first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byKey(const ValueKey('bang-1')), findsOneWidget, reason: 'the bang');
      expect(find.text(Mk.resetEarly.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapLabel(t, L.write);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the register reason');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.resetEarly.key);
      await _close(t, c);
    });

    final roomSeed = _seedWhere((d) => d.push == M6Push.room);
    testWidgets('a fast play: the door waits for the coworker; he cuts in at once', (t) async {
      final d = m6TripDeal(math.Random(roomSeed));
      final c = await _open(t, roomSeed);
      await _panels(t, d);
      // At once, inside his 1.2–2.4 s timer: the door.
      await t.tapAt(M6TripGeo.doorToControl.center * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerRoom.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      // The tap that waited did nothing: still in the breaker room.
      await _tapAt(t, M6TripGeo.relay(d.tripped, d.n).center);
      expect(_label(L.write), findsNothing, reason: 'no relay in the breaker room');
      await _tapAt(t, M6TripGeo.doorToControl.center);
      await _tapAt(t, M6TripGeo.relay(d.tripped, d.n).center);
      expect(_label(L.write), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to "sit here, it\'s cool": a slip with a bang from a neighbour panel', (t) async {
      final d = m6TripDeal(math.Random(roomSeed));
      final c = await _open(t, roomSeed);
      await _panels(t, d);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      await t.tap(_onScreen(L.coworkerRoom.wrong).first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byKey(const ValueKey('bang-1')), findsOneWidget);
      expect(find.text(Mk.stayRoom.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.stayRoom.key);
      await _close(t, c);
    });

    final plainSeed = _seedWhere((d) => d.push == M6Push.radio);
    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final d = m6TripDeal(math.Random(plainSeed));
      final c = await _open(t, plainSeed);
      await _tapAt(t, M6TripGeo.doorToBreakers.center);
      for (var i = 0; i < d.n; i++) {
        if (d.isOpen(i)) await _tapAt(t, _geo.panel(i, d.n).center);
      }
      await _tapLabel(t, L.lookDone);
      // The ◆ wait on the table and the deck: the panels and the button take nothing.
      for (var k = 0; k < 3; k++) {
        await t.tap(_label(L.lookDone), warnIfMissed: false);
        await t.tapAt(_geo.panel(d.tripped, d.n).center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, L.whyRight[M6WhyTopic.green]!);
      await _pump(t, 2000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a tap ripple on the door; a sweep over every panel and দেখা শেষ; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m6TripDeal(math.Random(plainSeed));
      final c = await _open(t, plainSeed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the door');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the one way on, not a pick');
      await _tapAt(t, M6TripGeo.doorToBreakers.center);
      expect(scene().showing, isFalse);
      // Three taps on nothing (the wall above the panels) show the hand at once.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(200, 122) * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isTrue, reason: 'three misses');
      expect(scene().debugOptions, hasLength(d.n + 1), reason: 'every panel and দেখা শেষ alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      for (var i = 0; i < d.n; i++) {
        if (d.isOpen(i)) await _tapAt(t, _geo.panel(i, d.n).center);
      }
      await _tapLabel(t, L.lookDone);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the reason deck has its own hand');
      await _close(t, c);
    });
  });
}
