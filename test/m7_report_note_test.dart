// Lesson 7.7 (দুর্ঘটনার রিপোর্ট), কাজ 2 "সৎ রিপোর্ট": the rules (the five report
// lines in any order — time wound back from NOW and the accident pole's plate;
// the injured man's card; his draft kept or struck, then the stills in order;
// the injuries; the witnesses — an empty cell is no slip, every wrong line is a
// slip that keeps the line open), the deal, the libraries, no deadly act, and
// the level in the shell: the guide first, a full clean play (the phone held
// for the coworker, the five lines with a reason each, 'পাঠান'), a slip card
// that keeps the line, three slips strike out, listening to him = a slip and
// the call again, the phone waits for him on a fast play, the praise window
// takes no touch, and the gesture hand shows how (never what) only while the
// level waits.
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
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_report_note.dart';
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
  rungId: '7.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7ReportNotePacks['do_7_7_b']!;
typedef L = M7ReportNoteLines;
typedef Mk = M7ReportNoteMistakes;

/// The new art is not in pubspec's bundle in tests until the director wires it:
/// tests read it from disk when the bundle does not have it.
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
Finder _key(String k) => find.byKey(ValueKey(k));
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
M7ReportGeo get _geo => M7ReportGeo.forScreen(const Size(392, 850));
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tapKey(WidgetTester t, String k, {int ms = 300}) async {
  await t.tap(_key(k), warnIfMissed: false);
  await _pump(t, ms);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7ReportNotePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M7ReportDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m7ReportDeal(math.Random(s))));

/// The accident has played, the time jumped: the phone is there.
Future<void> _toCall(WidgetTester t) async {
  expect(await _pumpUntil(t, _key('phone'), maxMs: 20000), isTrue, reason: 'the phone after the replay and the jump');
  await _pump(t, 300);
}

/// Holds the phone (he is dealt on it), refuses him; the call connects and the
/// sheet slides up.
Future<void> _callAndRefuse(WidgetTester t) async {
  final g = await t.startGesture(t.getCenter(_key('phone')));
  await _pump(t, 1300);
  await g.up();
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes at the call');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworkerCall.right);
  expect(await _pumpUntil(t, _key('hud-sheet'), maxMs: 12000), isTrue, reason: 'the call connected, the sheet is up');
  await _pump(t, 800);
}

Future<void> _openLine(WidgetTester t, M7Line l) async {
  await _tapKey(t, 'm7-line-${l.name}', ms: 600);
  expect(_key('m7-commit'), findsOneWidget, reason: 'line ${l.name} open');
}

Future<void> _commit(WidgetTester t) async => _tapKey(t, 'm7-commit', ms: 400);

Future<void> _reason(WidgetTester t, M7Why w) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck ($w)');
  await _pickRight(t, L.whyRight[w]!);
  await _pump(t, 1800);
}

Offset _dialPoint(WidgetTester t, int minutes) {
  final r = t.getRect(_key('m7-dial'));
  final a = (minutes % 60) / 60 * 2 * math.pi;
  return r.center + Offset(math.sin(a), -math.cos(a)) * 46;
}

/// Winds the dial from [from] back to [to] a slot at a time.
Future<void> _wind(WidgetTester t, int from, int to) async {
  final g = await t.startGesture(_dialPoint(t, from));
  await t.pump(const Duration(milliseconds: 60));
  var m = from;
  while (m != to) {
    m += m > to ? -5 : 5;
    await g.moveTo(_dialPoint(t, m));
    await t.pump(const Duration(milliseconds: 60));
  }
  await g.up();
  await _pump(t, 200);
}

/// Taps pole [i], drags the number in the lens into the slot.
Future<void> _lensTo(WidgetTester t, int i) async {
  await _tapAt(t, _geo.pole(i).center);
  final tag = _key('m7-lens-tag');
  expect(tag, findsOneWidget, reason: 'the lens is up');
  final from = t.getCenter(tag);
  await t.dragFrom(from, t.getCenter(_key('m7-slot-pole')) - from);
  await _pump(t, 400);
}

Future<void> _dragKeyTo(WidgetTester t, String from, String to) async {
  final a = t.getCenter(_key(from));
  await t.dragFrom(a, t.getCenter(_key(to)) - a);
  await _pump(t, 400);
}

/// Line A done right: wind, lens, 'লিখি'.
Future<void> _lineWhen(WidgetTester t, M7ReportDeal d) async {
  await _openLine(t, M7Line.when);
  await _wind(t, d.nowMin, d.accMin);
  await _lensTo(t, d.acc);
  await _commit(t);
}

Future<void> _lineWho(WidgetTester t, M7ReportDeal d) async {
  await _openLine(t, M7Line.who);
  await _dragKeyTo(t, 'm7-card-${d.hurt}', 'm7-slot-who');
  await _commit(t);
}

/// Line C done right (strike a lying draft and order the stills; keep an honest one).
Future<void> _lineHow(WidgetTester t, M7ReportDeal d) async {
  await _openLine(t, M7Line.how);
  if (d.honest) {
    await _tapKey(t, 'm7-keep');
    await _commit(t);
    return;
  }
  await _tapKey(t, 'm7-strike');
  await _commit(t);
  expect(_key('m7-slot-0'), findsOneWidget, reason: 'the stills come after a right strike');
  for (var b = 0; b < 3; b++) {
    await _dragKeyTo(t, 'm7-still-$b', 'm7-slot-$b');
  }
  await _commit(t);
}

Future<void> _lineHurt(WidgetTester t, M7ReportDeal d) async {
  await _openLine(t, M7Line.hurt);
  for (final e in d.injuries.entries) {
    await _tapKey(t, 'm7-zone-${e.key.name}');
    await _tapKey(t, 'm7-kind-${e.value.name}');
  }
  await _commit(t);
}

Future<void> _lineSaw(WidgetTester t, M7ReportDeal d) async {
  await _openLine(t, M7Line.saw);
  for (final w in d.witnesses) {
    await _tapKey(t, 'm7-wit-${w.name}');
  }
  await _commit(t);
}

void main() {
  group('rules', () {
    M7ReportDeal deal({M7Draft draft = M7Draft.hide, bool tea = true, bool cyc = false, List<int> order = const [2, 0, 1], int acc = 1}) => M7ReportDeal(
          poleNos: const [4217, 4218, 4219],
          acc: acc,
          accMin: 11 * 60 + 35,
          offset: 15,
          handR: true,
          foreR: false,
          ankleR: true,
          people: const [M7Person(name: 'অনিল মণ্ডল', age: 34, addr: 'রথতলা'), M7Person(name: 'সুজিত পাল', age: 41, addr: 'কালীপুর')],
          hurt: 1,
          draft: draft,
          draftIdx: 0,
          tea: tea,
          cyclist: cyc,
          stillOrder: order,
        );

    M7ReportRun atSheet(M7ReportDeal d) => M7ReportRun(d)
      ..toCall()
      ..connect();

    test('deals: poles one digit apart, 5-minute slots 08:00-16:00 and 10-25 min later, a lying draft in about 2 of 3 plays, plays differ', () {
      final seen = <String>{};
      var honest = 0, hide = 0, both = 0, tea = 0, cyc = 0;
      final accs = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m7ReportDeal(math.Random(s));
        final no = [...d.poleNos]..sort();
        expect(no[1] - no[0], 1);
        expect(no[2] - no[1], 1);
        expect(d.poleNos.toSet(), hasLength(3));
        expect(d.acc, inInclusiveRange(0, 2));
        expect(d.accMin % 5, 0);
        expect(d.accMin, inInclusiveRange(480, 960));
        expect(d.offset, anyOf(10, 15, 20, 25));
        expect(d.nowMin, lessThanOrEqualTo(990));
        expect(d.people, hasLength(2));
        expect(d.people[0].name, isNot(d.people[1].name));
        expect(d.people[0].addr, isNot(d.people[1].addr));
        expect(d.injured.name, d.people[d.hurt].name);
        expect(d.stillOrder.toSet(), {0, 1, 2});
        expect(d.stillOrder, isNot([0, 1, 2]), reason: 'the tray never comes in the right order');
        expect(d.stillOrder.sublist(0, 2), isNot([0, 1]), reason: 'nor the first two');
        expect(d.witnesses, isNotEmpty);
        expect(d.injuries, hasLength(3));
        expect(d.injuries.values.toSet(), M7Kind.values.toSet());
        expect(d.draftText, isNotEmpty);
        if (d.honest) honest++;
        if (d.draft == M7Draft.hide) hide++;
        if (d.tea && d.cyclist) both++;
        if (d.tea) tea++;
        if (d.cyclist) cyc++;
        accs.add(d.acc);
        seen.add('${d.poleNos}|${d.acc}|${d.accMin}|${d.offset}|${d.handR}${d.foreR}${d.ankleR}|${d.hurt}|${d.draft.name}${d.draftIdx}|${d.tea}${d.cyclist}');
        expect(d.look.patch, d.injured.name);
      }
      expect(seen.length, greaterThan(290));
      expect(accs, {0, 1, 2});
      expect(honest, inInclusiveRange(70, 130), reason: 'about 1 play in 3 has the honest draft');
      expect(hide, inInclusiveRange(70, 130));
      expect(both, inInclusiveRange(60, 140));
      expect(tea, greaterThan(150));
      expect(cyc, greaterThan(150));
    });

    test('the call: listening to myth 1 is a slip and he is still there; the call opens the sheet', () {
      final r = M7ReportRun(deal());
      expect(r.listenSlip(), isNull, reason: 'the replay is not the call');
      r.toCall();
      expect(r.openLine(M7Line.when), isFalse, reason: 'not before the call');
      expect(r.listenSlip(), Mk.listen);
      expect(r.slips, 1);
      expect(r.stage, M7Stage.call);
      r.connect(refused: true);
      expect(r.stage, M7Stage.sheet);
      expect(r.caught, contains(L.caughtCall));
      expect(r.listenSlip(), isNull);
    });

    test('line A: left at NOW, a wrong time, a wrong pole = slips; an empty slot is no slip; the line stays open', () {
      final d = deal();
      final r = atSheet(d);
      expect(r.timeMin, d.nowMin, reason: 'the dial starts at NOW');
      expect(r.setTime(d.accMin), isFalse, reason: 'no line open');
      expect(r.openLine(M7Line.when), isTrue);
      expect(r.canCommit(M7Line.when), isFalse);
      expect(r.commit(M7Line.when), isNull, reason: 'empty slot: no slip');
      expect(r.slips, 0);
      r.dropTag(d.accNo);
      expect(r.commit(M7Line.when), Mk.timeNow, reason: 'the dial was never wound back');
      r.setTime(d.accMin - 10);
      expect(r.commit(M7Line.when), Mk.timeWrong);
      r
        ..setTime(d.accMin)
        ..dropTag(d.poleNos[0]);
      expect(r.commit(M7Line.when), Mk.poleWrong);
      expect(r.slips, 3);
      expect(r.lineSlips[M7Line.when], 3);
      expect(r.open, M7Line.when, reason: 'the line reopens');
      r.dropTag(d.accNo);
      expect(r.commit(M7Line.when), isNull);
      expect(r.pending, M7Line.when);
      expect(r.caught, contains(L.caughtWhen));
      expect(r.whyFor(M7Line.when), M7Why.when);
      expect(r.openLine(M7Line.who), isFalse, reason: 'the praise window: nothing opens');
      r.next();
      expect(r.filled, {M7Line.when});
      expect(r.open, isNull);
      expect(r.openLine(M7Line.when), isFalse, reason: 'a written line stays written');
    });

    test('line A: the time is clamped to the shift and a time one slot off is wrong', () {
      final d = deal();
      final r = atSheet(d)..openLine(M7Line.when);
      r.setTime(100);
      expect(r.timeMin, 480);
      r.setTime(5000);
      expect(r.timeMin, 990);
      r
        ..setTime(d.accMin + 5)
        ..dropTag(d.accNo);
      expect(r.commit(M7Line.when), Mk.timeWrong);
    });

    test('line B: the coworker\'s card is a slip, the injured man\'s card is right', () {
      final d = deal();
      final r = atSheet(d)..openLine(M7Line.who);
      expect(r.commit(M7Line.who), isNull, reason: 'empty: no slip');
      expect(r.dropCard(0), isTrue);
      expect(r.commit(M7Line.who), Mk.cardWrong);
      expect(r.dropCard(1), isTrue);
      expect(r.commit(M7Line.who), isNull);
      expect(r.pending, M7Line.who);
      expect(r.slips, 1);
    });

    test('line C: a hiding or exaggerating draft kept = slip; a struck one needs the stills in order; an honest draft struck = slip', () {
      for (final dr in [M7Draft.hide, M7Draft.exaggerate]) {
        final d = deal(draft: dr);
        final r = atSheet(d)..openLine(M7Line.how);
        expect(r.commit(M7Line.how), isNull, reason: 'nothing picked: no slip');
        r.setPick(M7Pick.keep);
        expect(r.commit(M7Line.how), dr == M7Draft.hide ? Mk.keepHide : Mk.keepBig);
        expect(r.pick, M7Pick.none, reason: 'the choice reopens');
        r.setPick(M7Pick.strike);
        expect(r.commit(M7Line.how), isNull, reason: 'right: on to the stills, no ◆ yet');
        expect(r.stillsStage, isTrue);
        expect(r.pending, isNull);
        expect(r.setPick(M7Pick.keep), isFalse, reason: 'the choice is made');
        expect(r.tray, d.stillOrder);
        expect(r.canCommit(M7Line.how), isFalse);
        r
          ..placeStill(0, 1)
          ..placeStill(1, 0)
          ..placeStill(2, 2);
        expect(r.tray, isEmpty);
        expect(r.commit(M7Line.how), Mk.stillOrder);
        expect(r.slots, [null, null, null], reason: 'the slots clear');
        expect(r.tray, d.stillOrder);
        r
          ..placeStill(0, 0)
          ..placeStill(1, 1)
          ..placeStill(2, 2);
        expect(r.commit(M7Line.how), isNull);
        expect(r.pending, M7Line.how);
        expect(r.whyFor(M7Line.how), M7Why.strike);
        expect(r.slips, 2);
      }
      final h = deal(draft: M7Draft.honest);
      final r = atSheet(h)..openLine(M7Line.how);
      r.setPick(M7Pick.strike);
      expect(r.commit(M7Line.how), Mk.strikeHonest);
      expect(r.stillsStage, isFalse);
      r.setPick(M7Pick.keep);
      expect(r.commit(M7Line.how), isNull);
      expect(r.pending, M7Line.how);
      expect(r.whyFor(M7Line.how), M7Why.keep, reason: 'kept: the "why keep" question');
    });

    test('stills: a beat moves between slots; a slot can be cleared', () {
      final r = atSheet(deal(draft: M7Draft.exaggerate))..openLine(M7Line.how);
      r
        ..setPick(M7Pick.strike)
        ..commit(M7Line.how);
      r.placeStill(0, 2);
      r.placeStill(1, 2);
      expect(r.slots, [null, 2, null], reason: 'a beat is in one slot only');
      r.clearSlot(1);
      expect(r.slots, [null, null, null]);
      expect(r.placeStill(3, 0), isFalse);
    });

    test('line D: the three injuries by zone and kind; none, a missing zone, a wrong kind or an extra mark = slip', () {
      final d = deal();
      final r = atSheet(d)..openLine(M7Line.hurt);
      expect(r.canCommit(M7Line.hurt), isFalse);
      expect(r.setKind(M7Kind.shock), isFalse, reason: 'no zone selected');
      expect(d.injuries, {M7Zone.handR: M7Kind.shock, M7Zone.forearmL: M7Kind.burn, M7Zone.ankleR: M7Kind.sprain});
      r.pressNoHurt();
      expect(r.commit(M7Line.hurt), Mk.injuryWrong, reason: '"কোনো আঘাত নেই" is never right');
      r
        ..tapZone(M7Zone.handR)
        ..setKind(M7Kind.shock)
        ..tapZone(M7Zone.forearmL)
        ..setKind(M7Kind.burn);
      expect(r.noHurt, isFalse);
      expect(r.commit(M7Line.hurt), Mk.injuryWrong, reason: 'the ankle is missing');
      r
        ..tapZone(M7Zone.ankleR)
        ..setKind(M7Kind.burn);
      expect(r.commit(M7Line.hurt), Mk.injuryWrong, reason: 'a wrong kind');
      r.setKind(M7Kind.sprain);
      r
        ..tapZone(M7Zone.chest)
        ..setKind(M7Kind.shock);
      expect(r.commit(M7Line.hurt), Mk.injuryWrong, reason: 'an extra mark');
      r.tapZone(M7Zone.chest);
      expect(r.marks.containsKey(M7Zone.chest), isFalse, reason: 'a second tap on a marked zone rubs it off');
      expect(r.commit(M7Line.hurt), isNull);
      expect(r.pending, M7Line.hurt);
      expect(r.slips, 4);
    });

    test('line E: the witnesses who turned to watch, no more, no fewer; "কেউ দেখেনি" is wrong when someone did', () {
      for (final (tea, cyc) in [(true, false), (false, true), (true, true)]) {
        final d = deal(tea: tea, cyc: cyc);
        final r = atSheet(d)..openLine(M7Line.saw);
        expect(r.commit(M7Line.saw), isNull, reason: 'empty: no slip');
        r.pressNobody();
        expect(r.commit(M7Line.saw), Mk.witnessWrong);
        r.toggleWit(M7Wit.tea);
        r.toggleWit(M7Wit.cyclist);
        if (!(tea && cyc)) {
          expect(r.commit(M7Line.saw), Mk.witnessWrong, reason: 'both ticked, one watched');
        }
        r.saw
          ..clear()
          ..addAll(d.witnesses);
        expect(r.commit(M7Line.saw), isNull);
        expect(r.pending, M7Line.saw);
      }
    });

    test('lines in any order; the send needs all five; percent and pass; three slips = 55', () {
      final d = deal(draft: M7Draft.honest, tea: true, cyc: true);
      final r = atSheet(d);
      expect(r.send(), isFalse);
      void write(M7Line l, void Function() act) {
        r.openLine(l);
        act();
        expect(r.commit(l), isNull, reason: '$l');
        r.next();
      }

      write(M7Line.saw, () => r.saw.addAll(d.witnesses));
      write(M7Line.hurt, () => r.marks.addAll(d.injuries));
      expect(r.send(), isFalse, reason: 'two of five');
      write(M7Line.how, () => r.setPick(M7Pick.keep));
      write(M7Line.who, () => r.dropCard(d.hurt));
      expect(r.allFilled, isFalse);
      write(M7Line.when, () {
        r
          ..setTime(d.accMin)
          ..dropTag(d.accNo);
      });
      expect(r.allFilled, isTrue);
      expect(r.send(), isTrue);
      expect(r.sent, isTrue);
      expect(r.percent, 100);
      expect(r.passed, isTrue);
      expect(r.caught, containsAll([L.caughtWhen, L.caughtWho, L.caughtHow, L.caughtHurt, L.caughtSaw, L.caughtSent]));

      final s = atSheet(d)..openLine(M7Line.who);
      for (var i = 0; i < 3; i++) {
        s
          ..dropCard(1 - d.hurt)
          ..commit(M7Line.who);
      }
      expect(s.slips, 3);
      expect(s.percent, 55);
      s.commit(M7Line.who);
      expect(s.percent, 40);
    });

    test('the time text reads like the clock: সকাল, দুপুর, বিকেল, English digits', () {
      expect(m7TimeText(8 * 60), 'সকাল 8:00');
      expect(m7TimeText(11 * 60 + 35), 'সকাল 11:35');
      expect(m7TimeText(12 * 60 + 5), 'দুপুর 12:05');
      expect(m7TimeText(13 * 60 + 45), 'দুপুর 1:45');
      expect(m7TimeText(16 * 60), 'বিকেল 4:00');
    });

    test('no deadly act (M7-6); English digits only; jol not pani; nukta as base + nukta; every mistake has its picture; keys unique; the art folder', () {
      expect(Mk.deadlyKeys, isEmpty);
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'do_7_7_b has slips only');
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.fillAll,
        L.fillFirst,
        L.callDone,
        L.sent,
        L.quick,
        L.fail,
        L.sceneLabel,
        L.phoneName,
        L.phoneTalking,
        L.jump(25),
        L.sheetTitle,
        ...L.headers.values,
        ...L.progress,
        L.write,
        L.send,
        L.keep,
        L.strikeOut,
        L.draftTag,
        L.slotPole,
        L.slotWho,
        L.noHurt,
        L.nobody,
        for (final k in M7Kind.values) L.kindChip(k),
        for (final w in M7Wit.values) L.witChip(w),
        ...L.names,
        ...L.addresses,
        ...L.allDrafts,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworkerCall.recordedLines,
        ...L.coworkerCall.right,
        ...L.coworkerCall.wrong,
        ...L.coworkerCall.asks,
        L.callHeld,
        for (final m in Mk.all) m.textBn,
        L.caughtCall,
        L.caughtWhen,
        L.caughtWho,
        L.caughtHow,
        L.caughtHurt,
        L.caughtSaw,
        L.caughtSent,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp('(?<!ম্)পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('ডেড') || !l.contains('মৃত'), isTrue, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'য় ড় ঢ় as base + nukta: $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.7/m7_report_note/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      const dir = 'assets/game/art/m7_report_note/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m7_report_note').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file used, no .gitkeep left');
      expect(m7ReportNotePacks.keys, ['do_7_7_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expectSameLength('coworker choices', [...L.coworkerCall.right, ...L.coworkerCall.wrong]);
      expectLibrary('coworker', L.coworkerCall.right, L.coworkerCall.wrong, minRight: 3);
      expect(L.coworkerCall.asks, contains('কী করবেন?'));
      expectSameLength('drafts: no length gives the answer away', L.allDrafts);
      for (final d in M7Draft.values) {
        expect(L.draftsOf(d), hasLength(3));
      }
      expectSameLength('kind chips', [for (final k in M7Kind.values) L.kindChip(k)]);
      expectSameLength('witness chips', [for (final w in M7Wit.values) L.witChip(w), L.nobody]);
      expectSameLength('keep / strike', [L.keep, L.strikeOut]);
      // His push is the 7.7 myth 1 word for word.
      expect(L.coworkerCall.line, 'দুর্ঘটনা রিপোর্ট করলে আমার বা আমার সুপারভাইজারের চাকরি চলে যেতে পারে, তাই চুপ করে থাকাই ভালো।');
      // The honest draft says all three beats; the lying ones say none of them in order.
      for (final h in L.draftHonest) {
        expect(h.contains('শক'), isTrue, reason: h);
        expect(h.contains('মই'), isTrue, reason: h);
      }
      // The right reasons never name a side or a number the deal could change.
      for (final r in L.allWhyRight) {
        expect(RegExp('[0-9]').hasMatch(r), isFalse, reason: r);
      }
    });

    test('rival lines: his exit is recorded; his push is listed for recording; the guide\'s new lines are all listed', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect({L.coworkerCall.line}, L.newRivalLines.toSet());
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...L.whyQ.values, L.callDone, L.sent, L.callHeld, L.fillAll]));
      expect(L.newGuideLines, containsAll([for (final m in Mk.all) m.textBn]), reason: 'every mistake text is a spoken line');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_report_note: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas do not overlap, stay on the scene, below the header and clear of the guide and the sheet', () {
      for (final s in [const Size(360, 640), const Size(360, 760), const Size(392, 850), const Size(412, 915), const Size(411, 731)]) {
        final g = M7ReportGeo.forScreen(s);
        final guide = Rect.fromLTRB(244, g.sheetTop - 116, 360, g.sheetTop);
        final poles = [for (var i = 0; i < 3; i++) g.pole(i)];
        for (final p in poles) {
          expect(p.left, greaterThanOrEqualTo(0));
          expect(p.right, lessThanOrEqualTo(360));
          expect(p.top, greaterThan(125), reason: '$s: below the header');
          expect(p.bottom, lessThanOrEqualTo(g.sheetTop), reason: '$s: above the sheet');
          expect(p.overlaps(guide), isFalse, reason: '$s: $p under the guide');
          expect(p.overlaps(g.stall), isFalse);
        }
        for (var i = 0; i < 3; i++) {
          for (var j = i + 1; j < 3; j++) {
            expect(poles[i].overlaps(poles[j]), isFalse);
          }
        }
        for (var acc = 0; acc < 3; acc++) {
          final px = M7ReportGeo.pillarX(acc);
          expect(px, inInclusiveRange(20, 250));
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

    testWidgets('the guide comes first: a tap does not skip him; then the accident plays with no phone and no sheet', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7ReportNotePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 2000);
      expect(_label(L.sceneLabel), findsOneWidget);
      expect(_key('phone'), findsNothing, reason: 'the accident is still playing');
      expect(_key('hud-sheet'), findsNothing);
      expect(_key('hud-guide'), findsNothing, reason: 'no guide over the replay');
      expect(_key('clock-inset'), findsOneWidget, reason: 'the wall clock close up');
      await _pump(t, 8000);
      expect(_key('jump'), findsOneWidget, reason: 'the time jump');
      expect(find.text(L.jump(m7ReportDeal(math.Random(3)).offset)), findsOneWidget);
      await _toCall(t);
      expect(_key('hud-sheet'), findsNothing, reason: 'the call first');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      await _toCall(t);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askCall)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // Every draft kind and every witness mix, lines in a different order each time.
    final flowSeeds = [
      _seedWhere((d) => d.draft == M7Draft.hide && d.tea && d.cyclist),
      _seedWhere((d) => d.draft == M7Draft.exaggerate && d.tea && !d.cyclist),
      _seedWhere((d) => d.draft == M7Draft.honest && !d.tea && d.cyclist),
    ];
    final orders = [
      [M7Line.when, M7Line.who, M7Line.how, M7Line.hurt, M7Line.saw],
      [M7Line.saw, M7Line.hurt, M7Line.how, M7Line.who, M7Line.when],
      [M7Line.hurt, M7Line.when, M7Line.saw, M7Line.how, M7Line.who],
    ];
    for (var n = 0; n < flowSeeds.length; n++) {
      final seed = flowSeeds[n];
      testWidgets('flow (seed $seed): replay, the call (he is refused), five lines with a reason each, পাঠান → pass', (t) async {
        final d = m7ReportDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _toCall(t);
        await _callAndRefuse(t);
        for (final l in orders[n]) {
          switch (l) {
            case M7Line.when:
              await _lineWhen(t, d);
              await _reason(t, M7Why.when);
            case M7Line.who:
              await _lineWho(t, d);
              await _reason(t, M7Why.who);
            case M7Line.how:
              await _lineHow(t, d);
              await _reason(t, d.honest ? M7Why.keep : M7Why.strike);
            case M7Line.hurt:
              await _lineHurt(t, d);
              await _reason(t, M7Why.hurt);
            case M7Line.saw:
              await _lineSaw(t, d);
              await _reason(t, M7Why.saw);
          }
          expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'line ${l.name} is right');
          expect(find.byType(MistakeCard), findsNothing);
        }
        await _pump(t, 600);
        await t.tap(_key('m7-send'), warnIfMissed: false);
        await _pump(t, 4000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.7/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.7/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtSent), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final slipSeed = _seedWhere((d) => d.draft != M7Draft.honest);
    testWidgets('a slip shows its card and the same line goes on; the sheet shows only what was saved', (t) async {
      final d = m7ReportDeal(math.Random(slipSeed));
      final c = await _open(t, slipSeed);
      await _toCall(t);
      await _callAndRefuse(t);
      await _openLine(t, M7Line.when);
      // The pole is right, the dial was never wound back: the time left at NOW.
      await _lensTo(t, d.acc);
      await _commit(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.timeNow.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_key('m7-commit'), findsOneWidget, reason: 'the same line');
      expect(find.text(m7TimeText(d.nowMin)), findsOneWidget, reason: 'the dial kept its setting');
      await _wind(t, d.nowMin, d.accMin);
      await _commit(t);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M7Why.when);
      // The coworker's card instead of the injured man's.
      await _openLine(t, M7Line.who);
      await _dragKeyTo(t, 'm7-card-${1 - d.hurt}', 'm7-slot-who');
      await _commit(t);
      expect(find.text(Mk.cardWrong.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), containsAll([Mk.timeNow.key, Mk.cardWrong.key]));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong pole, then keeping a lying draft: each its own slip card; the choice reopens', (t) async {
      final d = m7ReportDeal(math.Random(slipSeed));
      final c = await _open(t, slipSeed);
      await _toCall(t);
      await _callAndRefuse(t);
      await _openLine(t, M7Line.when);
      await _wind(t, d.nowMin, d.accMin);
      await _lensTo(t, (d.acc + 1) % 3);
      await _commit(t);
      expect(find.text(Mk.poleWrong.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapKey(t, 'm7-back');
      await _openLine(t, M7Line.how);
      await _tapKey(t, 'm7-keep');
      await _commit(t);
      expect(find.text((d.draft == M7Draft.hide ? Mk.keepHide : Mk.keepBig).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_key('m7-strike'), findsOneWidget, reason: 'the choice reopened');
      expect(c.read(gameSaveProvider).mistakes, hasLength(2));
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, slipSeed);
      final d = m7ReportDeal(math.Random(slipSeed));
      await _toCall(t);
      await _callAndRefuse(t);
      await _openLine(t, M7Line.who);
      await _dragKeyTo(t, 'm7-card-${1 - d.hurt}', 'm7-slot-who');
      for (var i = 0; i < 3; i++) {
        await _commit(t);
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

    testWidgets('an empty cell is no slip: the guide asks and the line stays', (t) async {
      final d = m7ReportDeal(math.Random(slipSeed));
      final c = await _open(t, slipSeed);
      await _toCall(t);
      await _callAndRefuse(t);
      await _openLine(t, M7Line.hurt);
      await _commit(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.fillAll));
      // 'কোনো আঘাত নেই' is always there, and wrong: the accident hurt him.
      await _tapKey(t, 'm7-none');
      await _commit(t);
      expect(find.text(Mk.injuryWrong.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.injuryWrong.key);
      expect(d.injuries, hasLength(3));
      await _close(t, c);
    });

    testWidgets('listening to him at the call is a slip; he is gone and the call goes through next time', (t) async {
      final c = await _open(t, 4);
      await _toCall(t);
      final g = await t.startGesture(t.getCenter(_key('phone')));
      await _pump(t, 1300);
      await g.up();
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerCall.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.text(Mk.listen.textBn), findsOneWidget);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(_key('hud-sheet'), findsNothing, reason: 'the call did not go through');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listen.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsNothing);
      // Call again: nobody waits now.
      final g2 = await t.startGesture(t.getCenter(_key('phone')));
      await _pump(t, 1300);
      await g2.up();
      expect(await _pumpUntil(t, _key('hud-sheet'), maxMs: 6000), isTrue, reason: 'the call connects');
      expect(c.read(guideDirectorProvider).line, anyOf(contains(L.callDone), contains(L.askSheet)));
      await _close(t, c);
    });

    testWidgets('a fast play: the phone waits for the coworker; he cuts in at once; a short tap only misses', (t) async {
      final c = await _open(t, 6);
      await _toCall(t);
      // A tap that is not a hold does nothing.
      await t.tap(_key('phone'), warnIfMissed: false);
      await _pump(t, 300);
      expect(_key('hud-sheet'), findsNothing);
      // At once, inside his 1.2–2.4 s timer: hold the phone.
      final g = await t.startGesture(t.getCenter(_key('phone')));
      await _pump(t, 1200);
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_key('hud-sheet'), findsNothing, reason: 'the hold did not call');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerCall.right);
      expect(await _pumpUntil(t, _key('hud-sheet'), maxMs: 12000), isTrue);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final d = m7ReportDeal(math.Random(slipSeed));
      final c = await _open(t, slipSeed);
      await _toCall(t);
      await _callAndRefuse(t);
      await _openLine(t, M7Line.saw);
      for (final w in d.witnesses) {
        await _tapKey(t, 'm7-wit-${w.name}');
      }
      await _commit(t);
      // The ◆ on the table and the deck: the scene takes nothing.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.pole(d.acc).center * _k);
        await t.tapAt(_geo.pole(0).center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_key('m7-lens-tag'), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      await _pickRight(t, L.whyRight[M7Why.saw]!);
      await _pump(t, 2000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(find.byKey(const ValueKey('m7-line-saw')), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a pole is looked at under the lens only with line A open; the dial winds back across the hour', (t) async {
      final seed = _seedWhere((d) => d.nowMin ~/ 60 != d.accMin ~/ 60);
      final d = m7ReportDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _toCall(t);
      await _callAndRefuse(t);
      await _tapAt(t, _geo.pole(0).center);
      expect(_key('m7-lens-tag'), findsNothing, reason: 'no line open: no lens');
      await _openLine(t, M7Line.when);
      await _tapAt(t, _geo.pole(1).center);
      expect(_key('m7-lens-tag'), findsOneWidget);
      expect(find.text('${d.poleNos[1]}'), findsWidgets, reason: 'the lens reads its number');
      await _tapAt(t, _geo.pole(2).center);
      expect(find.text('${d.poleNos[2]}'), findsWidgets);
      await _wind(t, d.nowMin, d.accMin);
      expect(find.text(m7TimeText(d.accMin)), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('gesture hand: a hold ring on the phone; a sweep over the five headers; a drag nudge on the dial; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final d = m7ReportDeal(math.Random(slipSeed));
      final c = await _open(t, slipSeed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 1500);
      expect(scene().showing, isFalse, reason: 'not over the replay');
      await _toCall(t);
      await _pump(t, 9500);
      if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
        await _pumpUntil(t, find.byType(ChoiceDeck));
        await _pump(t, 600);
        await _pickRight(t, L.coworkerCall.right);
        expect(await _pumpUntil(t, _key('hud-sheet'), maxMs: 12000), isTrue);
      } else {
        expect(scene().showing, isTrue, reason: 'idle at the phone');
        expect(scene().debugOptions, isEmpty, reason: 'a hold on the one way on, not a pick');
        await _callAndRefuse(t);
      }
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the sheet');
      expect(scene().debugOptions, hasLength(5), reason: 'all five headers alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _tapKey(t, 'm7-line-when', ms: 700);
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'idle at the dial');
      // A short drag nudge on the minute hand, or a sweep over the three poles alike: never one pole.
      expect(scene().debugOptions.length, anyOf(0, 3), reason: 'a nudge or a sweep over all, not a pick');
      await _wind(t, d.nowMin, d.accMin);
      await _lensTo(t, d.acc);
      await _commit(t);
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the reason deck has its own hand');
      await _close(t, c);
    });
  });
}
