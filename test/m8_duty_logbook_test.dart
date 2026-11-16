// Lesson 8.10 (রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ), কাজ 1 "ডিউটির খাতা": the
// rules (a climb before the written permit = deadly, by the pole or by
// listening to coworker A; the carbon copy kept in the PTW book or greased;
// the clock stamped into the logbook, each column keeps its last stamp; the
// angry consumer's calm reply, the note flicked back, the hook coil and meter
// untouched; judged only at the sign: read passes, ±5 game-min times, a job
// missing — at most 2 slips from the sign itself), the deal, the libraries,
// the coworker's two variants, the drawn places, and the level in the shell:
// the guide first, a full clean play (stamp at the window and at the call, the
// carbon copy in the book, the time-lapse, the public moment, the page, two
// read passes, the hold on সই; a reason pick each time; the coworker refused),
// the deadly freeze, three slips, the capped sign, the refill from the copy,
// and the gesture hand.
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
import 'package:slm_flutter/features/game/m8_duty_logbook.dart';
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
  rungId: '8.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

final _pack = m8DutyLogbookPacks['do_8_10_a']!;
typedef L = M8DutyLogbookLines;
typedef Mk = M8DutyLogbookMistakes;

/// The new art is not in pubspec's bundle in tests until the director wires
/// it: tests read it from disk when the bundle does not have it.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      // Another agent's flutter run can rebuild the shared test asset folder
      // under us: an empty manifest and the repo's own files keep this test alone.
      if (key == 'AssetManifest.bin') return const StandardMessageCodec().encodeMessage(<Object?, Object?>{})!;
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

Future<bool> _until(WidgetTester t, bool Function() ok, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) => _until(t, () => f.evaluate().isNotEmpty, maxMs: maxMs);

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M8Geo get _geo => M8Geo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8Run get _live => M8DutyLogbookProbe.run!;
int get _shown => M8DutyLogbookProbe.shown!();

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

/// A drag in design px, in small steps (a finger).
Future<void> _drag(WidgetTester t, Offset from, Offset to, {int steps = 10}) async {
  final g = await t.startGesture(from * _k);
  await t.pump(const Duration(milliseconds: 40));
  for (var i = 1; i <= steps; i++) {
    await g.moveTo(Offset.lerp(from, to, i / steps)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

Future<void> _tapVan(WidgetTester t) => _tapAt(t, _geo.van.center);
Future<void> _tapPole(WidgetTester t) => _tapAt(t, _geo.pole.center);

/// The clock dragged into [col] of the logbook (the tray, or the open page).
Future<void> _stamp(WidgetTester t, M8Col col) async {
  final open = _live.phase == M8Phase.tailgate;
  final from = open ? _geo.slot(5).center : _geo.clock.center;
  final to = open ? M8PageGeo.col(col).center : _geo.trayCol(col).center;
  await _drag(t, from, to);
}

Future<void> _readPass(WidgetTester t) async {
  final p = M8PageGeo.page;
  final x = p.left + 60;
  final g = await t.startGesture(Offset(x, p.top + 3) * _k);
  for (var i = 1; i <= 30; i++) {
    await g.moveTo(Offset(x, p.top + 3 + (p.height - 6) * i / 30) * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

Future<void> _holdSign(WidgetTester t) async {
  final g = await t.startGesture(M8PageGeo.col(M8Col.sign).center * _k);
  await _pump(t, 1400);
  await g.up();
  await _pump(t, 400);
}

Finder _card(String text) => find.byKey(ValueKey('deal-$text'));

/// The one of [texts] that is a card on the deck now.
String _onDeck(List<String> texts) {
  final on = [for (final x in texts) if (_card(x).evaluate().isNotEmpty) x];
  expect(on, hasLength(1), reason: texts.first);
  return on.single;
}

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(await _until(t, () => right.any((x) => _card(x).evaluate().isNotEmpty), maxMs: 9000), isTrue, reason: right.first);
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  await pickChoice(t, _onDeck(right));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8DutyLogbookPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8Deal(math.Random(s))));

/// The coworker comes (he is held on a decisive control, or his timer): refuse.
Future<void> _refuse(WidgetTester t, M8Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  expect(await _until(t, () => L.coworker(p).right.any((x) => _card(x).evaluate().isNotEmpty), maxMs: 9000), isTrue);
  await _pump(t, 600);
  await waitChoiceDeck(t);
  await pickChoice(t, _onDeck(L.coworker(p).right), proceed: false);
  await _pump(t, 2600);
}

/// Plays the field up to the pole tap: the drive (the clock stamped at the
/// window), the permit reason, the carbon copy kept in the book and its reason.
Future<void> _fieldRight(WidgetTester t, {bool stampAtWindow = true}) async {
  final d = _live.deal;
  await _tapVan(t);
  if (stampAtWindow) {
    expect(await _until(t, () => _live.permitMin != null && _shown == _live.permitMin && _live.phase == M8Phase.window), isTrue, reason: 'at the window');
    await _stamp(t, M8Col.taken);
    expect(_live.stamps[M8Col.taken], _live.permitMin, reason: 'the clock stamped at the permit time');
  }
  expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 9000), isTrue, reason: 'the permit reason');
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[M8Why.permit]!);
  expect(await _until(t, () => _live.phase == M8Phase.copy, maxMs: 4000), isTrue);
  await _pump(t, 400);
  final slot = d.placeOrder.indexOf(M8Place.book);
  await _drag(t, _geo.copyInHand.center, _geo.place(slot).center);
  expect(_live.keptInBook, isTrue);
  expect(_live.phase, M8Phase.ready);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the copy reason');
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[M8Why.copy]!);
  await _pump(t, 2200);
}

/// The time-lapse to the public moment, played right, then on to the call
/// (the clock stamped there) and the tailgate; the coworker (B) refused there.
Future<void> _lapseRight(WidgetTester t, {bool stampAtCall = true}) async {
  await _tapPole(t);
  expect(await _until(t, () => _live.phase == M8Phase.moment, maxMs: 16000), isTrue, reason: 'the public moment');
  await _pump(t, 500);
  if (_live.deal.moment == M8Moment.angry) {
    await waitChoiceDeck(t);
    await pickChoice(t, _onDeck(L.replyRight), proceed: false);
  } else {
    await _drag(t, _geo.note.center, _geo.note.center + const Offset(70, 0));
    expect(_live.momentDone, isTrue, reason: 'the note flicked back');
  }
  await _pickRight(t, L.whyRight[_live.momentWhy]!);
  if (stampAtCall) {
    expect(await _until(t, () => _live.callMin != null && _shown == _live.callMin, maxMs: 20000), isTrue, reason: 'the line-clear call');
    await _stamp(t, M8Col.released);
    expect(_live.stamps[M8Col.released], _live.callMin);
  }
  expect(await _until(t, () => _live.phase == M8Phase.tailgate, maxMs: 16000), isTrue, reason: 'the tailgate');
  await _pump(t, 300);
}

/// Everything on the page right: the jobs, two read passes (the coworker B
/// refused when he comes), the hold on সই, the reason.
Future<void> _pageRight(WidgetTester t) async {
  final r = _live;
  if (!r.deal.done.every(r.onPage.contains)) {
    for (var i = 0; i < M8Job.values.length; i++) {
      if (r.deal.done.contains(M8Job.values[i]) && !r.onPage.contains(M8Job.values[i])) {
        await _drag(t, _geo.slot(i).center, M8PageGeo.col(M8Col.work).center);
      }
    }
  }
  expect(r.deal.done.every(r.onPage.contains), isTrue, reason: 'every job on the page');
  await _readPass(t);
  await _readPass(t);
  expect(r.passes, 2);
  await _holdSign(t);
  expect(r.signed, isTrue);
}

M8Deal _dealOf({
  List<M8Job> docket = const [M8Job.fuse],
  M8Job? extra,
  M8Moment moment = M8Moment.angry,
  M8NoteKind kind = M8NoteKind.coil,
}) =>
    M8Deal(
      startMin: 9 * 60 + 30,
      phoneDelay: 4,
      goMin: 10,
      backMin: 10,
      workMin: 90,
      gapMin: 10,
      tailMin: 10,
      docket: docket,
      extra: extra,
      moment: moment,
      noteKind: kind,
      house: 1,
      placeOrder: const [M8Place.toolbox, M8Place.book, M8Place.dash, M8Place.doorPocket],
      earlier: const [('11/11', 600, 800, M8Job.fuse), ('12/11', 610, 820, M8Job.jumper)],
      phoneMs: 8000,
    );

/// A run walked to the tailgate with the story's own clock.
M8Run _atTailgate(M8Deal d, {bool copyInBook = true}) {
  final r = M8Run(d)
    ..toStation()
    ..backFromStation()
    ..toCopy()
    ..placeCopy(copyInBook ? M8Place.book : M8Place.toolbox)
    ..beginLapse()
    ..startMoment();
  if (d.moment == M8Moment.angry) {
    r.reply(true);
  } else {
    r.noteFlick();
  }
  r
    ..resumeLapse()
    ..workDone()
    ..callClear()
    ..packed()
    ..toTailgate();
  return r;
}

void main() {
  group('rules', () {
    test('deals: the stated ranges, jobs, places; plays differ', () {
      final seen = <String>{};
      final moments = <M8Moment>{};
      final kinds = <M8NoteKind>{};
      final extras = <M8Job?>{};
      final docketSizes = <int>{};
      var bookFirst = 0;
      for (var s = 0; s < 200; s++) {
        final d = m8Deal(math.Random(s));
        expect(d.startMin, inInclusiveRange(9 * 60, 11 * 60));
        expect(d.phoneDelay, inInclusiveRange(2, 6));
        expect(d.roundTrip, inInclusiveRange(15, 30));
        expect(d.goMin, greaterThan(5));
        expect(d.backMin, greaterThan(kM8Tolerance), reason: 'the way back is more than the tolerance');
        expect(d.workMin, inInclusiveRange(60, 150));
        expect(d.gapMin, inInclusiveRange(6, 15), reason: 'a gap beyond the tolerance (6-15)');
        expect(d.tailMin, greaterThan(kM8Tolerance), reason: 'the tailgate time is outside the tolerance');
        expect(d.docket, isNotEmpty);
        expect(d.docket.length, lessThanOrEqualTo(2));
        expect(d.docket.toSet(), hasLength(d.docket.length));
        expect(d.extra == null || !d.docket.contains(d.extra), isTrue, reason: 'a job beyond the docket');
        expect(d.done.toSet(), hasLength(d.done.length));
        expect(d.done.length, inInclusiveRange(1, 3));
        expect(d.placeOrder.toSet(), M8Place.values.toSet());
        expect(d.earlier, hasLength(2));
        expect(d.phoneMs, inInclusiveRange(7000, 9999));
        if (d.placeOrder.first == M8Place.book) bookFirst++;
        moments.add(d.moment);
        kinds.add(d.noteKind);
        extras.add(d.extra);
        docketSizes.add(d.docket.length);
        seen.add('${d.startMin}${d.phoneDelay}${d.goMin}${d.workMin}${d.gapMin}${d.docket}${d.extra}${d.moment}${d.placeOrder}${d.house}');
      }
      expect(seen.length, greaterThan(190));
      expect(moments, M8Moment.values.toSet());
      expect(kinds, M8NoteKind.values.toSet());
      expect(extras.length, greaterThan(2), reason: 'whether a second job beyond the docket was done');
      expect(docketSizes, {1, 2});
      expect(bookFirst, inInclusiveRange(25, 80), reason: 'the book is shuffled among the four');
    });

    test('the clock reads HH:MM with English digits', () {
      expect(m8Clock(9 * 60 + 5), '09:05');
      expect(m8Clock(13 * 60 + 40), '13:40');
      expect(m8Clock(24 * 60 + 10), '00:10');
    });

    test('a climb before the written permit is deadly (R1); the drive gives the permit and its time', () {
      final r = M8Run(_dealOf());
      expect(r.climb(), Mk.climbNoPermit);
      expect(Mk.climbNoPermit.deadly, isTrue);
      expect(r.ended, isTrue);
      final r2 = M8Run(_dealOf());
      r2.lightPhone();
      expect(r2.phoneLit, isTrue);
      expect(r2.now, 9 * 60 + 34, reason: 'the clock stands at the phone\'s time');
      expect(r2.climb(), Mk.climbNoPermit, reason: 'the phone\'s word is no permit');
      final r3 = M8Run(_dealOf());
      r3.toStation();
      expect(r3.hasPermit, isTrue);
      expect(r3.permitMin, 9 * 60 + 40, reason: 'the permit time is the window\'s time');
      expect(r3.climb(), isNull, reason: 'no climb is scored once the permit is in hand');
      r3.backFromStation();
      expect(r3.now, 9 * 60 + 50);
      expect(r3.phase, M8Phase.returned);
      expect(r3.caught, contains(L.caughtPermit));
    });

    test('the carbon copy: the PTW book keeps it; anywhere else is a slip and it is greased', () {
      for (final p in M8Place.values) {
        final r = M8Run(_dealOf())
          ..toStation()
          ..backFromStation()
          ..toCopy();
        expect(r.phase, M8Phase.copy);
        final m = r.placeCopy(p);
        expect(r.phase, M8Phase.ready);
        if (p == M8Place.book) {
          expect(m, isNull);
          expect(r.copyUsable, isTrue);
          expect(r.caught, contains(L.caughtCopy));
          expect(r.slips, 0);
        } else {
          expect(m, Mk.copyMisplaced);
          expect(m!.deadly, isFalse);
          expect(r.copyUsable, isFalse);
          expect(r.greased, isTrue);
          expect(r.slips, 1);
        }
        expect(r.placeCopy(p), isNull, reason: 'placed once');
      }
    });

    test('stamps: each column keeps only the last; only the two time columns; the page clears a time', () {
      final r = M8Run(_dealOf());
      expect(r.stamp(M8Col.taken, 580), isTrue);
      expect(r.stamp(M8Col.taken, 600), isTrue);
      expect(r.stamps[M8Col.taken], 600, reason: 'the last stamp stays');
      expect(r.stamp(M8Col.work, 600), isFalse);
      expect(r.stamp(M8Col.sign, 600), isFalse);
      expect(r.clearStamp(M8Col.taken), isFalse, reason: 'a time is cleared only on the open page');
      final t = _atTailgate(_dealOf());
      t.stamp(M8Col.released, 777);
      expect(t.clearStamp(M8Col.released), isTrue);
      expect(t.stamps[M8Col.released], isNull);
      expect(t.clearStamp(M8Col.released), isFalse);
    });

    test('the public moment: a calm reply, the note flicked back; every other act a slip', () {
      var r = M8Run(_dealOf());
      r
        ..toStation()
        ..backFromStation()
        ..toCopy()
        ..placeCopy(M8Place.book)
        ..beginLapse()
        ..startMoment();
      expect(r.reply(false), Mk.rudeReply);
      expect(r.slips, 1);
      expect(r.momentDone, isFalse, reason: 'the deck stays up after a slip');
      expect(r.notePocket(), isNull, reason: 'no note in an angry moment');
      expect(r.touchHook(), isNull);
      expect(r.reply(true), isNull);
      expect(r.momentDone, isTrue);
      expect(r.caught, contains(L.caughtCalm));
      r.resumeLapse();
      expect(r.phase, M8Phase.lapse);

      for (final kind in M8NoteKind.values) {
        r = M8Run(_dealOf(moment: M8Moment.note, kind: kind));
        r
          ..toStation()
          ..backFromStation()
          ..toCopy()
          ..placeCopy(M8Place.book)
          ..beginLapse()
          ..startMoment();
        expect(r.reply(false), isNull, reason: 'no reply deck in a note moment');
        expect(r.notePocket(), Mk.tookNote);
        expect(r.touchHook(), Mk.touchedHook);
        expect(Mk.tookNote.deadly || Mk.touchedHook.deadly, isFalse, reason: 'cash and hooking are slips (M8-6)');
        expect(r.slips, 2);
        r.noteFlick();
        expect(r.momentDone, isTrue);
        expect(r.caught, contains(L.caughtNote));
      }
    });

    test('the time-lapse timeline: the clock moves with the story; the call and the tailgate are outside the tolerance of each other', () {
      final d = _dealOf();
      final r = _atTailgate(d);
      expect(r.permitMin, 9 * 60 + 40);
      expect(r.callMin, r.workEndMin + 10);
      expect(r.now, r.callMin! + d.tailMin);
      expect(M8Run.near(r.now, r.callMin), isFalse, reason: 'stamping the tailgate time is late');
      expect(M8Run.near(r.now, r.permitMin), isFalse);
      expect(r.midMin, lessThan(r.workEndMin));
      expect(M8Run.near(100, 105), isTrue);
      expect(M8Run.near(100, 106), isFalse);
      expect(M8Run.near(100, 95), isTrue);
      expect(M8Run.near(null, 95), isFalse);
    });

    test('the sign: all right = no slip; judged order: passes, taken, released, jobs; at most 2 slips from the sign (M8-13)', () {
      final d = _dealOf(docket: [M8Job.fuse, M8Job.jumper], extra: M8Job.insulator);
      var r = _atTailgate(d);
      r
        ..stamp(M8Col.taken, r.permitMin! + 4)
        ..stamp(M8Col.released, r.callMin! - 5)
        ..readPass()
        ..readPass();
      for (final j in d.done) {
        r.addJob(j);
      }
      expect(r.sign(), isEmpty);
      expect(r.signed, isTrue);
      expect(r.passed, isTrue);
      expect(r.percent, 100);
      expect(r.caught, contains(L.caughtLog));
      expect(r.sign(), isEmpty, reason: 'signed once');

      // Nothing right: four faults, two cards.
      r = _atTailgate(d);
      final cut = r.sign();
      expect(cut, [Mk.signedFast, Mk.takenWrong], reason: 'the cap keeps the first two');
      expect(r.signSlips, 2);
      expect(r.percent, 70);
      expect(r.passed, isTrue, reason: 'a careless sign alone cannot fail the level');

      // Single faults.
      r = _atTailgate(d)
        ..stamp(M8Col.taken, 1)
        ..readPass()
        ..readPass();
      expect(r.sign().first, Mk.takenWrong);
      r = _atTailgate(d)
        ..stamp(M8Col.taken, 0)
        ..readPass();
      expect(r.sign(), [Mk.signedFast, Mk.takenWrong], reason: 'one pass is not two');

      r = _atTailgate(d);
      r
        ..readPass()
        ..readPass()
        ..stamp(M8Col.taken, r.permitMin!)
        ..stamp(M8Col.released, r.callMin! + 6)
        ..addDocket();
      expect(r.onPage, {M8Job.fuse, M8Job.jumper});
      expect(r.sign(), [Mk.releaseWrong, Mk.jobMissing], reason: '+6 is outside the tolerance; the extra job is missing');

      r = _atTailgate(d);
      r
        ..readPass()
        ..readPass()
        ..stamp(M8Col.taken, r.permitMin!)
        ..stamp(M8Col.released, r.callMin!);
      expect(r.sign(), [Mk.jobMissing]);
    });

    test('the copy kept in the book refills শাটডাউন নেওয়া; a greased copy cannot; a blank or late time is a slip', () {
      var r = _atTailgate(_dealOf());
      r.stamp(M8Col.taken, r.now);
      expect(r.refillTaken(), isTrue);
      expect(r.stamps[M8Col.taken], r.permitMin);
      r = _atTailgate(_dealOf(), copyInBook: false);
      expect(r.copyUsable, isFalse);
      expect(r.refillTaken(), isFalse);
      expect(r.stamps[M8Col.taken], isNull);
      r.readPass();
      r.readPass();
      r.stamp(M8Col.released, r.callMin!);
      r.addJob(M8Job.fuse);
      expect(r.sign(), [Mk.takenWrong], reason: 'blank');
      expect(r.refillTaken(), isFalse, reason: 'signed');
    });

    test('the page only takes jobs once the tailgate is reached; the docket card adds its jobs', () {
      final d = _dealOf(docket: [M8Job.fuse, M8Job.insulator]);
      final r = M8Run(d);
      expect(r.addJob(M8Job.fuse), isFalse);
      expect(r.addDocket(), isFalse);
      final t = _atTailgate(d);
      expect(t.addDocket(), isTrue);
      expect(t.onPage, {M8Job.fuse, M8Job.insulator});
      expect(t.addDocket(), isFalse);
      expect(t.addJob(M8Job.fuse), isFalse, reason: 'already written');
      expect(t.addJob(M8Job.jumper), isTrue);
    });

    test('three slips fail the play; listening to B is a slip, listening to A is the deadly climb (B1)', () {
      final r = M8Run(_dealOf());
      expect(r.pushSlip(), Mk.listenedSign);
      expect(Mk.listenedSign.deadly, isFalse);
      expect(r.slips, 1);
      expect(r.pushDeadly(), Mk.listenedClimb);
      expect(Mk.listenedClimb.deadly, isTrue);
      expect(r.ended, isTrue);
      final r2 = M8Run(_dealOf());
      for (var i = 0; i < 3; i++) {
        r2.pushSlip();
      }
      expect(r2.percent, 55);
      r2.pushSlip();
      expect(r2.percent, 40);
    });

    test('English digits only; jol not pani; term rules; every mistake has its picture; the deadly set; keys; lesson points', () {
      final all = <String>[
        L.title,
        L.intro,
        ...L.tasks,
        ...L.bubbles,
        L.phoneOff,
        L.phoneClear,
        L.clockLabel,
        L.colTaken,
        L.colReleased,
        L.colWork,
        L.colSign,
        L.carbonCopy,
        L.docket,
        for (final p in M8Place.values) L.place(p),
        for (final j in M8Job.values) ...[L.job(j), L.part(j)],
        ...L.permits,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.allReply,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        L.callHeldPhone,
        L.callHeldRead,
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtPermit,
        L.caughtCopy,
        L.caughtCalm,
        L.caughtNote,
        L.caughtLog,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s—,।])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('মরা'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$)').hasMatch(l), isFalse, reason: l);
        expect(l.contains('কেভি'), isFalse, reason: 'kV in English letters: $l');
        expect(l.contains('এলটি') || l.contains('এইচটি'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(l.contains('গ্লাভ্স'), isFalse, reason: l);
        // য় / ড় / ঢ় as base + nukta.
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.climbNoPermit, Mk.listenedClimb});
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.10/m8_duty_logbook/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: 'lesson 8.10 has four points');
      }
      const dir = 'assets/game/art/m8_duty_logbook/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used (no .gitkeep left)');
      expect(m8DutyLogbookPacks.keys, ['do_8_10_a']);
      expect(_pack.titleBn, L.title);
    });

    test('the lesson\'s own words stand behind the cards (live 8.10 text)', () {
      final lesson = File('tool/all_training_chapters_bn.json').readAsStringSync();
      String norm(String s) => s.replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');
      final text = norm(lesson);
      for (final w in [
        'লিখিত পারমিট হাতে না পাওয়া এবং নিজের হাতে আর্থিং না করা পর্যন্ত পোল-এ উঠবেন না',
        'সাইন করার আগে দুবার পড়ে দেখুন সব ঠিক আছে কি না',
        'লেখা নেই = প্রমাণ নেই',
        'ধরা পড়লে আইন আপনাকে ছাড়বে না',
        'নিজের পায়ে কুড়ুল মারা',
        'ইউনিফর্ম = কোম্পানির প্রতিনিধি',
        'মাথা গরম হলেও',
        'কার্বন কপি যত্ন করে রাখা',
        'আইন-কানুন সব বইয়ের পাতায়',
        'সব দায় অফিসারের',
        'পুঙ্খানুপুঙ্খভাবে',
        'আপনি কাজটা করেননি বা নিয়ম মানেননি',
      ]) {
        expect(text.contains(norm(w)), isTrue, reason: w);
      }
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      for (final w in M8Why.values) {
        expectSameLength('why $w', [...L.whyRight[w]!, ...L.myths]);
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expectSameLength('reply', L.allReply);
      expectLibrary('reply', L.replyRight, L.replyWrong, minRight: 2, minWrong: 5);
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
      expect(L.whyQ.values.toSet(), hasLength(5), reason: 'the spec\'s five questions');
      for (final r in L.replyRight) {
        expect(r, isNot(contains('ধমক')));
      }
    });

    test('rival lines: his exit is recorded; his two pushes and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'অফিস ফোনে বলল লাইন OFF আছে — উঠে পড়! দায় তো অফিসারের, আমাদের নয়।',
        'আইন-কানুন সব বইয়ের পাতায়, মাঠে জুগাড়েই কাজ চলে — না পড়েই সইটা করে দাও।',
      ]);
      expect({for (final p in M8Push.values) L.coworker(p).line}, L.newRivalLines.toSet());
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...L.whyQ.values, L.callHeldPhone, L.callHeldRead, L.allSet, L.quick, L.fail, for (final m in Mk.all) m.textBn]));
      for (final cw in L.allCoworkers) {
        for (final a in cw.asks) {
          expect(L.newGuideLines.contains(a) || a == 'কী করবেন?' || a == 'ওর কথা শুনবেন, না নিয়ম?', isTrue, reason: a);
        }
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_duty_logbook: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas stay on the scene, under the header, clear of the guide, its bubble and each other', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M8Geo.forScene(h, 0);
        final guide = Rect.fromLTRB(253, h - 77 - 107, 360, h);
        final rects = <Rect>[g.pole, g.van, g.phone, g.clock, g.tray, M8PageGeo.page, for (var i = 0; i < 6; i++) g.slot(i), for (var i = 0; i < 4; i++) g.place(i), g.copyInHand];
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.bottom, lessThan(h - 20), reason: 'h $h: $r');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81)), isFalse, reason: 'h $h: $r under the bubble');
        }
        final noteRects = <Rect>[g.note, g.coil, g.meterBox, g.pocket];
        for (final r in noteRects) {
          expect(r.top, greaterThan(125), reason: 'h $h: $r');
          if (h >= 700) expect(r.overlaps(Rect.fromLTRB(147, h - 112 - 129, 360, h - 112 - 81)), isFalse, reason: 'h $h: $r under the bubble');
        }
        // The lane's taps never overlap each other; the strip and the places neither.
        final lane = [g.pole, g.van, g.phone, g.clock];
        for (final (i, a) in lane.indexed) {
          for (final b in lane.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        for (final (i, a) in [for (var i = 0; i < 6; i++) g.slot(i)].indexed) {
          for (final b in [for (var i = 0; i < 6; i++) g.slot(i)].skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: slots $a / $b');
          }
        }
        for (var i = 0; i < 4; i++) {
          for (var j = i + 1; j < 4; j++) {
            expect(g.place(i).overlaps(g.place(j)), isFalse);
          }
          expect(g.place(i).overlaps(g.copyInHand), isFalse);
        }
        expect(g.slot(0).height * _k, greaterThanOrEqualTo(48), reason: 'a finger-sized chip');
        expect(g.place(0).height * _k, greaterThanOrEqualTo(48));
        // The compact tray's columns tile the tray; the page's columns tile the page.
        var w = 0.0;
        for (final c in M8Col.values) {
          w += g.trayCol(c).width;
          expect(g.tray.contains(g.trayCol(c).center), isTrue);
        }
        expect(w, g.tray.width);
        expect(M8PageGeo.colW.reduce((a, b) => a + b), M8PageGeo.width);
        expect(M8PageGeo.zone(kM8ReadZones - 1).bottom, M8PageGeo.page.bottom);
        expect(M8PageGeo.zoneAt(M8PageGeo.page.top + 1), 0);
        expect(M8PageGeo.zoneAt(M8PageGeo.page.bottom - 1), kM8ReadZones - 1);
        expect(M8PageGeo.zoneAt(M8PageGeo.page.bottom + 1), isNull);
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

    testWidgets('the guide comes first: a tap does not skip him; then the lane, the clock and the dark phone', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M8DutyLogbookPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_live.phase, M8Phase.field);
      expect(_live.phoneLit, isFalse, reason: 'the phone is dark at first');
      expect(find.text(m8Clock(_live.deal.startMin)), findsOneWidget);
      expect(find.text(L.phoneOff), findsNothing, reason: 'the phone says nothing until it lights');
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
      expect(lines.every((l) => l.contains(L.askField)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('the phone lights after its delay: the clock steps to its time; the lane stays quiet', (t) async {
      final c = await _open(t, 5);
      expect(_live.phoneLit, isFalse);
      expect(await _until(t, () => _live.phoneLit, maxMs: 11000), isTrue);
      await _pump(t, 800);
      expect(find.text(L.phoneOff), findsOneWidget);
      expect(_shown, _live.phoneAt, reason: 'the dash clock reads the phone\'s time');
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he comes on the first touch, not on a timer');
      await _close(t, c);
    });

    testWidgets('tapping the pole before the permit: the lane freezes first, then the card (deadly)', (t) async {
      final c = await _open(t, 5);
      await _tapPole(t);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.climbNoPermit.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('variant A: on the phone\'s word the first touch of the van lets him in; refused, the drive goes on', (t) async {
      final c = await _open(t, 7);
      expect(await _until(t, () => _live.phoneLit, maxMs: 11000), isTrue);
      await _pump(t, 800);
      await _tapVan(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in on the touch');
      expect(_live.phase, M8Phase.field, reason: 'the van waited for him');
      await _refuse(t, M8Push.phone);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(_live.caught, contains(L.caughtCall));
      await _tapVan(t);
      expect(_live.hasPermit, isTrue, reason: 'after him the van goes');
      await _close(t, c);
    });

    testWidgets('variant A: listening to him is the deadly climb: freeze, then the card', (t) async {
      final c = await _open(t, 7);
      expect(await _until(t, () => _live.phoneLit, maxMs: 11000), isTrue);
      await _tapPole(t);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = L.coworkerPhone.wrong.firstWhere((x) => _card(x).evaluate().isNotEmpty);
      await pickChoice(t, wrong, proceed: false);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listenedClimb.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final angrySeed = _seedWhere((d) => d.moment == M8Moment.angry);
    final noteSeed = _seedWhere((d) => d.moment == M8Moment.note && d.extra != null && d.docket.length == 2);
    for (final seed in [angrySeed, noteSeed, _seedWhere((d) => d.moment == M8Moment.note && d.extra == null && d.noteKind == M8NoteKind.meter)]) {
      testWidgets('flow (seed $seed): the drive, the copy, the time-lapse, the moment, the page, two passes, the sign; reasons; he is refused → pass', (t) async {
        final c = await _open(t, seed);
        await _fieldRight(t);
        await _lapseRight(t);
        // The coworker (variant B) comes at the page.
        await _refuse(t, M8Push.noRead);
        await _pageRight(t);
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the sign reason');
        await _pump(t, 400);
        await _pickRight(t, L.whyRight[M8Why.sign]!);
        await _pump(t, 4000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.10/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.10/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(_live.slips, 0);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('the carbon copy dropped in another place: a slip card; the copy is greased; the play goes on', (t) async {
      final c = await _open(t, angrySeed);
      final d = _live.deal;
      await _tapVan(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 9000), isTrue);
      await _pump(t, 400);
      await _pickRight(t, L.whyRight[M8Why.permit]!);
      expect(await _until(t, () => _live.phase == M8Phase.copy, maxMs: 4000), isTrue);
      await _pump(t, 400);
      final slot = d.placeOrder.indexOf(M8Place.toolbox);
      await _drag(t, _geo.copyInHand.center, _geo.place(slot).center);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.copyMisplaced.textBn), findsOneWidget);
      expect(_live.greased, isTrue);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.phase, M8Phase.ready);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.copyMisplaced.key);
      await _close(t, c);
    });

    testWidgets('a wrong reply is a slip and the deck stays; three slips strike the level out', (t) async {
      final c = await _open(t, angrySeed);
      final d = _live.deal;
      await _tapVan(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 9000), isTrue);
      await _pump(t, 400);
      await _pickRight(t, L.whyRight[M8Why.permit]!);
      expect(await _until(t, () => _live.phase == M8Phase.copy, maxMs: 4000), isTrue);
      await _pump(t, 400);
      await _drag(t, _geo.copyInHand.center, _geo.place(d.placeOrder.indexOf(M8Place.dash)).center);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapPole(t);
      expect(await _until(t, () => _live.phase == M8Phase.moment, maxMs: 16000), isTrue);
      await _pump(t, 500);
      expect(_live.deal.moment, M8Moment.angry);
      final used = <String>{};
      for (var i = 0; i < 2; i++) {
        await waitChoiceDeck(t);
        final wrong = L.replyWrong.firstWhere((x) => _card(x).evaluate().isNotEmpty && !used.contains(x));
        used.add(wrong);
        await pickChoice(t, wrong, proceed: false);
        await _pump(t, 900);
        if (i == 0) {
          expect(find.text(Mk.rudeReply.textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_live.momentDone, isFalse);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the note: into the pocket and a touch of the coil or meter are slips; flicked back is right', (t) async {
      final seed = _seedWhere((d) => d.moment == M8Moment.note && d.noteKind == M8NoteKind.coil);
      final c = await _open(t, seed);
      await _fieldRight(t, stampAtWindow: false);
      await _tapPole(t);
      expect(await _until(t, () => _live.phase == M8Phase.moment, maxMs: 16000), isTrue);
      await _pump(t, 500);
      // The note dragged to his own pocket.
      await _drag(t, _geo.note.center, _geo.pocket.center);
      expect(find.text(Mk.tookNote.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.momentDone, isFalse);
      // The hook coil touched.
      await _tapAt(t, _geo.coil.center);
      expect(find.text(Mk.touchedHook.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // A short drag goes nowhere; a flick toward him is right.
      await _drag(t, _geo.note.center, _geo.note.center + const Offset(12, 0));
      expect(_live.momentDone, isFalse);
      await _drag(t, _geo.note.center, _geo.note.center + const Offset(70, 0));
      expect(_live.momentDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.tookNote.key, Mk.touchedHook.key]);
      await _close(t, c);
    });

    testWidgets('the sign blind: no passes, no stamps — at most 2 cards, each in turn, then a pass with 2 slips', (t) async {
      final c = await _open(t, angrySeed);
      await _fieldRight(t, stampAtWindow: false);
      await _lapseRight(t, stampAtCall: false);
      await _refuse(t, M8Push.noRead);
      expect(_live.stamps[M8Col.taken], isNull);
      final d = _live.deal;
      for (var i = 0; i < M8Job.values.length; i++) {
        if (d.done.contains(M8Job.values[i])) await _drag(t, _geo.slot(i).center, M8PageGeo.col(M8Col.work).center);
      }
      await _holdSign(t);
      expect(_live.signed, isTrue);
      expect(find.text(Mk.signedFast.textBn), findsOneWidget, reason: 'the first card');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 700);
      expect(find.text(Mk.takenWrong.textBn), findsOneWidget, reason: 'the second card in turn');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.text(Mk.releaseWrong.textBn), findsNothing, reason: 'the cap: no third card from the sign');
      expect(find.byType(LevelPassPanel), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['8.10/do/0'], 'cleared');
      expect(s.mistakes.map((m) => m.key), [Mk.signedFast.key, Mk.takenWrong.key]);
      await _close(t, c);
    });

    testWidgets('the correction: a wrong time cleared by a tap, refilled from the carbon copy kept in the book', (t) async {
      final c = await _open(t, noteSeed);
      await _fieldRight(t, stampAtWindow: false);
      await _lapseRight(t);
      await _refuse(t, M8Push.noRead);
      expect(_live.stamps[M8Col.taken], isNull);
      // Stamp a wrong time (the tailgate clock), then clear it by a tap.
      await _stamp(t, M8Col.taken);
      expect(_live.stamps[M8Col.taken], _shown);
      expect(M8Run.near(_live.stamps[M8Col.taken], _live.permitMin), isFalse);
      await _tapAt(t, M8PageGeo.col(M8Col.taken).center);
      expect(_live.stamps[M8Col.taken], isNull, reason: 'a tap on a time clears it');
      // Drag the time off the carbon copy.
      await _drag(t, _geo.slot(4).center, M8PageGeo.col(M8Col.taken).center);
      expect(_live.stamps[M8Col.taken], _live.permitMin, reason: 'refilled from the copy');
      await _pageRight(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 400);
      await _pickRight(t, L.whyRight[M8Why.sign]!);
      await _pump(t, 4000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('variant B holds the সই box: a fast play is cut in; listening is a slip; refusing frees it', (t) async {
      final c = await _open(t, angrySeed);
      await _fieldRight(t);
      await _lapseRight(t);
      // At once, inside his timer: the hold on সই (he cuts in, or is already in).
      await _holdSign(t);
      expect(_live.signed, isFalse, reason: 'the সই hold waited for him');
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = L.coworkerRead.wrong.firstWhere((x) => _card(x).evaluate().isNotEmpty);
      await pickChoice(t, wrong, proceed: false);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.listenedSign.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listenedSign.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.signed, isFalse, reason: 'listening signs nothing; the player still signs');
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch on the lane', (t) async {
      final c = await _open(t, angrySeed);
      await _tapVan(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 9000), isTrue);
      await _pump(t, 400);
      // The reason deck is up: the pole and the van take nothing.
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.pole.center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.ended, isFalse);
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, L.whyRight[M8Why.permit]!);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the lane first; a hint presses nothing and gives nothing away', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 5);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      // The phone lights on the way (a new state); then 9 s of rest.
      expect(await _until(t, () => _live.phoneLit, maxMs: 11000), isTrue);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'idle in the field');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(_live.phase, M8Phase.field);
      expect(find.byType(MistakeCard), findsNothing);
      // Any touch hides it.
      await t.tapAt(const Offset(30, 300));
      await t.pump(const Duration(milliseconds: 200));
      expect(scene().showing, isFalse);
      await _close(t, c);
    });
  });
}
