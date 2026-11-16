// Lesson 7.4 (পারমিট-টু-ওয়ার্ক: একটি আইনি চুক্তি), কাজ 2 "বৈধ PTW ছিল কি?":
// the rules (the logbook row clipped — a wrong row no slip but no clip pay and
// no thorough bonus; 'লগবুকে নেই' when the row is there a slip; the film
// strip; the pin right only on a photo of someone up the pole outside the
// permit window, a pin inside it or on nobody a slip; 'সব কাজ PTW-এর মধ্যে'
// on a breach a slip; a time verdict before the row is clipped a slip on
// every case, so on a no-row case any time verdict is one), the deal (case kinds, gaps,
// decoy rows, photos), the libraries, the coworker (myth 2 word for word;
// listening = a slip — the level has no deadly act, M7-4 / M7-6), the drawn
// desk, and the level in the shell: the guide first, a full clean play (pages
// swiped, rows clipped, the strip scrubbed, a verdict hold, a reason each
// case, the coworker refused at his hold), a wrong row that costs the clip
// pay, a time verdict before the clip and on a no-row case, three slips
// strike out, listening is a slip with no freeze, and the gesture hand shows
// how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m7_ptw_inquiry.dart';
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
  rungId: '7.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7PtwInquiryPacks['do_7_4_b']!;
typedef L = M7PtwInquiryLines;
typedef Mk = M7PtwInquiryMistakes;

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
List<String> _textsOnScreen(List<String> texts) => [
      for (final x in texts)
        if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x,
    ];

/// A reason (or the coworker's deck): the one right card, ✓, then proceed.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _textsOnScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await pickChoice(t, r.single);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M7PtwGeo get _geo => M7PtwGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M7PtwRun get _live => M7PtwInquiryProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

/// Swipes the logbook to page [p].
Future<void> _toPage(WidgetTester t, int p) async {
  for (var k = 0; k < 6 && M7PtwInquiryProbe.page != p; k++) {
    final d = M7PtwInquiryProbe.page < p ? -120.0 : 120.0;
    await t.dragFrom(Offset(180, _geo.book.center.dy) * _k, Offset(d, 0) * _k);
    await _pump(t, 250);
  }
  expect(M7PtwInquiryProbe.page, p);
}

/// The job's row clipped (swiping to its page).
Future<void> _clip(WidgetTester t) async {
  final c = _live.kase;
  await _toPage(t, c.matchPage!);
  final i = c.page(c.matchPage!).indexWhere((r) => r.id == c.matchId);
  await _tapAt(t, _geo.row(i).center);
  expect(_live.clipped, c.matchId);
  expect(_live.stage, M7PtwStage.scrub);
}

/// A hold of [ms] on [f] (one of the three hold controls).
Future<void> _hold(WidgetTester t, Finder f, {int ms = kM7PtwHoldMs + 200}) async {
  final g = await t.startGesture(t.getCenter(f));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Finder get _pin => _label(L.pin);
Finder get _noRow => _label(L.noRowStamp);
Finder get _allIn => _label(L.allInStamp);

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7PtwInquiryPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7PtwDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7PtwDeal(math.Random(s))));

/// The coworker comes at the hold: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 3000), isTrue, reason: 'he comes at the hold');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// A verdict hold; on his case the first hold brings the coworker (refused),
/// then the hold again.
Future<void> _verdict(WidgetTester t, M7PtwDeal d, int i, Finder f) async {
  if (d.coworkerCase == i && _live.caught.every((c) => c != L.caughtCall)) {
    await _hold(t, f);
    expect(_live.roundDone, isFalse, reason: 'the hold waited for him');
    await _refuse(t);
  }
  await _hold(t, f);
}

/// One case played right.
Future<void> _playCase(WidgetTester t, M7PtwDeal d, int i) async {
  final c = d.cases[i];
  expect(_live.index, i);
  switch (c.kind) {
    case M7PtwCaseKind.noRow:
      // Every page looked through, then the stamp.
      for (var p = 1; p < c.pages; p++) {
        await _toPage(t, p);
      }
      await _verdict(t, d, i, _noRow);
    case M7PtwCaseKind.clean:
      await _clip(t);
      for (var p = 0; p < c.photos.length; p += 2) {
        await _tapAt(t, _geo.thumb(p, c.photos.length).center);
      }
      await _verdict(t, d, i, _allIn);
    case M7PtwCaseKind.before || M7PtwCaseKind.after:
      await _clip(t);
      final at = c.photos.indexWhere(c.outside);
      await _tapAt(t, _geo.thumb(at, c.photos.length).center);
      expect(_live.photo, at);
      await _verdict(t, d, i, _pin);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${c.kind}');
  expect(_live.roundDone, isTrue, reason: '${c.kind}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (${c.kind})');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[d.why[i]]!);
  await _pump(t, 3000);
}

M7PtwRow _row(int id, {int day = 14, int month = 3, int no = 4417, int feeder = 0, int issue = 600, int cancel = 760}) =>
    M7PtwRow(id: id, day: day, month: month, ptwNo: no, feeder: feeder, issue: issue, cancel: cancel);

M7PtwCase _caseOf(M7PtwCaseKind k) {
  final rows = [
    _row(1, day: 13, no: 4147),
    _row(2, feeder: 2, no: 5821),
    if (k != M7PtwCaseKind.noRow) _row(0),
    _row(3, day: 15, no: 6390),
  ];
  return M7PtwCase(
    kind: k,
    day: 14,
    month: 3,
    feeder: 0,
    ptwNo: 4417,
    fieldCopy: k != M7PtwCaseKind.noRow,
    rows: rows,
    matchId: k == M7PtwCaseKind.noRow ? null : 0,
    issue: 600,
    cancel: 760,
    photos: [
      const M7PtwPhoto(minute: 560, shot: M7PtwShot.arrive),
      if (k == M7PtwCaseKind.before) const M7PtwPhoto(minute: 585, shot: M7PtwShot.climb),
      const M7PtwPhoto(minute: 640, shot: M7PtwShot.up),
      const M7PtwPhoto(minute: 700, shot: M7PtwShot.ground),
      const M7PtwPhoto(minute: 720, shot: M7PtwShot.climb),
      if (k == M7PtwCaseKind.after) const M7PtwPhoto(minute: 775, shot: M7PtwShot.up),
      const M7PtwPhoto(minute: 800, shot: M7PtwShot.pack),
    ],
    gap: k == M7PtwCaseKind.before || k == M7PtwCaseKind.after ? 15 : 0,
  );
}

M7PtwRun _runOf(M7PtwCaseKind first) => M7PtwRun(M7PtwDeal(
      cases: [_caseOf(first), _caseOf(M7PtwCaseKind.clean), _caseOf(M7PtwCaseKind.noRow)],
      coworkerCase: 1,
      why: const [M7PtwWhy.beforeGap, M7PtwWhy.clean, M7PtwWhy.noRow],
    ));

void main() {
  group('rules', () {
    test('deals: three cases (never three of a kind); gaps 10–25 min with 1–2 photos; clean and no-row cases have no pole work outside; decoy rows; plays differ', () {
      final seen = <String>{};
      final kinds = <M7PtwCaseKind>{};
      final whys = <M7PtwWhy>{};
      final cw = <int>{};
      var withClean = 0, rowNoCopy = 0, page0 = 0, pageLater = 0;
      for (var s = 0; s < 300; s++) {
        final d = m7PtwDeal(math.Random(s));
        expect(d.cases, hasLength(3));
        expect(d.cases.map((c) => c.kind).toSet().length, greaterThan(1), reason: 'two of a kind may come, never three');
        expect({for (final c in d.cases) c.month * 32 + c.day}, hasLength(3), reason: 'three different days');
        if (d.cases.any((c) => c.kind == M7PtwCaseKind.clean)) withClean++;
        cw.add(d.coworkerCase);
        for (final (i, c) in d.cases.indexed) {
          kinds.add(c.kind);
          whys.add(d.why[i]);
          final fits = switch (c.kind) {
            M7PtwCaseKind.before => {M7PtwWhy.beforeGap, M7PtwWhy.law},
            M7PtwCaseKind.after => {M7PtwWhy.afterGap, M7PtwWhy.law},
            M7PtwCaseKind.noRow => {M7PtwWhy.noRow, M7PtwWhy.law},
            M7PtwCaseKind.clean => {M7PtwWhy.clean},
          };
          expect(fits, contains(d.why[i]));
          // Photos: 6–9, by time, minutes unique.
          expect(c.photos.length, inInclusiveRange(6, 9));
          final mins = [for (final p in c.photos) p.minute];
          expect(mins.toSet(), hasLength(mins.length));
          expect([...mins]..sort(), mins);
          expect(c.cancel - c.issue, greaterThanOrEqualTo(75));
          final inside = c.photos.where((p) => p.onPole && p.minute >= c.issue && p.minute <= c.cancel).length;
          expect(inside, greaterThanOrEqualTo(2), reason: 'pole work inside the window in every case');
          expect(c.photos.where((p) => !p.onPole && (p.minute < c.issue || p.minute > c.cancel)), isNotEmpty, reason: 'crew photos outside the window with nobody up');
          final out = c.photos.where(c.outside).toList();
          switch (c.kind) {
            case M7PtwCaseKind.before:
              expect(c.gap, inInclusiveRange(10, 25));
              expect(out.length, inInclusiveRange(1, 2));
              expect(out.every((p) => p.minute < c.issue && p.minute >= c.issue - c.gap), isTrue);
              expect(out.map((p) => p.minute), contains(c.issue - c.gap), reason: 'the first man up to the minute');
            case M7PtwCaseKind.after:
              expect(c.gap, inInclusiveRange(10, 25));
              expect(out.length, inInclusiveRange(1, 2));
              expect(out.every((p) => p.minute > c.cancel && p.minute <= c.cancel + c.gap), isTrue);
              expect(out.map((p) => p.minute), contains(c.cancel + c.gap));
            case M7PtwCaseKind.noRow || M7PtwCaseKind.clean:
              expect(out, isEmpty);
          }
          // The logbook: 3–4 pages; in written order; numbers unique.
          expect(c.pages, inInclusiveRange(3, 4));
          expect(c.rows.length, c.pages * kM7PtwRowsPerPage);
          expect([for (final r in c.rows) r.order], [...[for (final r in c.rows) r.order]]..sort());
          expect(c.rows.map((r) => r.ptwNo).toSet(), hasLength(c.rows.length));
          expect(c.rows.map((r) => r.id).toSet(), hasLength(c.rows.length));
          final job = c.rows.where((r) => r.day == c.day && r.month == c.month && r.feeder == c.feeder).toList();
          if (c.kind == M7PtwCaseKind.noRow) {
            expect(job, isEmpty, reason: 'no row for the job');
            expect(c.matchId, isNull);
            expect(c.fieldCopy, isFalse);
          } else {
            expect(job, hasLength(1), reason: 'one row by date and feeder, with or without the field copy');
            expect(job.single.id, c.matchId);
            expect(job.single.ptwNo, c.ptwNo);
            expect(job.single.issue, c.issue);
            expect(job.single.cancel, c.cancel);
            if (!c.fieldCopy) rowNoCopy++;
            if (c.matchPage == 0) page0++;
            if (c.matchPage! > 0) pageLater++;
          }
          // The decoys.
          expect(c.rows.any((r) => r.feeder == c.feeder && r.day != c.day), isTrue, reason: 'same feeder, other date');
          expect(c.rows.any((r) => r.day == c.day && r.feeder != c.feeder), isTrue, reason: 'same date, other feeder');
          final sw = c.ptwNo.toString().split('');
          final swapped = int.parse([sw[0], sw[2], sw[1], sw[3]].join());
          expect(swapped, isNot(c.ptwNo));
          expect(c.rows.any((r) => r.ptwNo == swapped), isTrue, reason: 'the middle digits swapped');
        }
        seen.add([for (final c in d.cases) '${c.kind.index}${c.ptwNo}${c.photos.map((p) => p.minute).join(',')}'].join('|'));
      }
      expect(seen.length, 300);
      expect(kinds, M7PtwCaseKind.values.toSet());
      expect(whys, M7PtwWhy.values.toSet());
      expect(cw, {0, 1, 2});
      expect(withClean / 300, inInclusiveRange(0.55, 0.78), reason: '~2 plays in 3 hold a clean case');
      expect(rowNoCopy, greaterThan(40), reason: 'an empty sleeve never gives the answer away');
      expect(page0, greaterThan(20));
      expect(pageLater, greaterThan(page0), reason: 'the row is often on a later page');
    });

    test('the logbook: a wrong row is no slip but costs the clip pay and the thorough bonus; the job row clips it; the strip moves the board photo', () {
      final ok = _runOf(M7PtwCaseKind.clean);
      expect(ok.clipPay, 5);
      expect(ok.clip(0), isTrue);
      expect(ok.thorough, isTrue, reason: 'straight to the row');
      final r = _runOf(M7PtwCaseKind.before);
      expect(r.stage, M7PtwStage.find);
      expect(r.clip(1), isFalse);
      expect(r.slips, 0, reason: 'a wrong row is not a slip');
      expect(r.wrongRows, 1);
      expect(r.clipPay, 0, reason: 'a wrong row loses the clip pay');
      expect(r.thorough, isFalse, reason: 'and the thorough bonus');
      expect(r.clip(2), isFalse);
      expect(r.wrongRows, 2);
      expect(r.pick(3), isTrue);
      expect(r.photo, 3);
      expect(r.pick(3), isFalse);
      expect(r.pick(99), isTrue);
      expect(r.photo, r.kase.photos.length - 1);
      expect(r.clip(0), isTrue);
      expect(r.stage, M7PtwStage.scrub);
      expect(r.clipped, 0);
      expect(r.clip(1), isFalse, reason: 'one row a case');
      expect(r.wrongRows, 2, reason: 'no cost once the row is clipped');
      expect(r.caught, contains(L.caughtRow));
      r.pick(r.kase.photos.indexWhere(r.kase.outside));
      expect(r.pin(), isNull);
      r.next();
      expect(r.wrongRows, 0, reason: 'each case counts its own');
      expect(r.clipPay, 5);
    });

    test('a time verdict before the row is clipped is a slip on every case; on a no-row case every time verdict is one', () {
      for (final k in M7PtwCaseKind.values) {
        final r = _runOf(k);
        expect(r.pin(), Mk.timeFirst, reason: '$k: a pin before the row');
        expect(r.allIn(), Mk.timeFirst, reason: '$k: "সব কাজ" before the row');
        expect(r.slips, 2);
        expect(r.roundDone, isFalse, reason: '$k: the case goes on');
        expect(r.stage, M7PtwStage.find);
      }
      // No row: nothing to clip, so a pin or "সব কাজ" is always a slip; the
      // stamp is the answer.
      final n = _runOf(M7PtwCaseKind.noRow);
      for (final r in n.kase.rows) {
        n.clip(r.id);
      }
      for (var i = 0; i < n.kase.photos.length; i++) {
        n.pick(i);
        expect(n.pin(), Mk.timeFirst);
      }
      expect(n.allIn(), Mk.timeFirst);
      expect(n.noRow(), isNull);
      expect(n.roundDone, isTrue);
    });

    test('the pin: nobody up = slip; inside the window = slip; someone up outside = right; "সব কাজ" on a breach = slip', () {
      final r = _runOf(M7PtwCaseKind.before)..clip(0);
      r.pick(0);
      expect(r.pin(), Mk.pinNobody);
      r.pick(2);
      expect(r.shown.minute, 640);
      expect(r.pin(), Mk.pinValid);
      expect(r.allIn(), Mk.allInBefore);
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.pick(1);
      expect(r.shown.minute, 585);
      expect(r.pin(), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtBefore));
      expect(r.thorough, isFalse);
      final a = _runOf(M7PtwCaseKind.after)..clip(0);
      expect(a.allIn(), Mk.allInAfter);
      a.pick(a.kase.photos.indexWhere((p) => p.minute == 775));
      expect(a.pin(), isNull);
      expect(a.caught, contains(L.caughtAfter));
    });

    test('clean: every pin a slip, "সব কাজ" right; no row: the stamp right, and wrong on a case with a row', () {
      final c = _runOf(M7PtwCaseKind.clean);
      expect(c.noRow(), Mk.rowExists, reason: 'the row is there');
      c.clip(0);
      expect(c.noRow(), Mk.rowExists);
      for (var i = 0; i < c.kase.photos.length; i++) {
        c.pick(i);
        expect(c.pin(), c.shown.onPole ? Mk.pinValid : Mk.pinNobody);
      }
      expect(c.allIn(), isNull);
      expect(c.roundDone, isTrue);
      expect(c.caught, contains(L.caughtClean));
      final n = _runOf(M7PtwCaseKind.noRow);
      for (final r in n.kase.rows) {
        expect(n.clip(r.id), isFalse, reason: 'no row is this job\'s');
      }
      expect(n.noRow(), isNull);
      expect(n.roundDone, isTrue);
      expect(n.caught, contains(L.caughtNoRow));
      expect(n.slips, 0);
      n.next();
      expect(n.index, 1);
      expect(n.stage, M7PtwStage.find);
      expect(n.clipped, isNull);
      expect(n.photo, 0);
      expect(n.thorough, isTrue, reason: 'each case counts its own slips');
    });

    test('no deadly act (M7-4 / M7-6); listening is a slip (X2/B1); three slips fail', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      final r = _runOf(M7PtwCaseKind.clean);
      r.pushSlip(Mk.listened);
      r.noRow();
      r.noRow();
      expect(r.slips, 3);
      expect(r.percent, 55);
      r.noRow();
      expect(r.percent, 40);
    });

    test('English digits; জল not পানি; term rules; nukta form; every mistake has its picture; keys unique; lesson points; M7-4 field note', () {
      final all = <String>[
        L.title,
        L.intro,
        ...L.tasks,
        L.nextCase,
        L.wrongRow,
        L.rowOk,
        ...L.tapWhy,
        L.pin,
        L.noRowStamp,
        L.allInStamp,
        L.deskLabel,
        for (var n = 1; n <= 3; n++) L.caseName(n),
        ...L.feeders,
        L.desk.caseFile,
        L.desk.date,
        L.desk.feeder,
        L.desk.fieldCopy,
        L.desk.ptwNo,
        L.desk.noFieldCopy,
        L.desk.logbook,
        ...L.desk.columns,
        L.desk.page(2, 4),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtRow,
        L.caughtBefore,
        L.caughtAfter,
        L.caughtNoRow,
        L.caughtClean,
        L.caughtCall,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: 'ডেড, never মৃত: $l');
        expect(RegExp('অফ|সুইচ অন|এলটি|এইচটি|কেভি|AB বন্ধ').hasMatch(l), isFalse, reason: 'term rules: $l');
        expect(RegExp(r'(^|[\s,(—।])অন($|[\s,)—।?!])').hasMatch(l), isFalse, reason: 'ON, never অন: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'nukta form: $l');
        expect(l.contains(' DO ') || l.startsWith('DO '), isFalse, reason: 'no DO in Module 7 (M7-9): $l');
      }
      expect(L.desk.page(2, 4), 'পাতা 2/4');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.4/m7_ptw_inquiry/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2), reason: 'lesson 7.4 has three points');
      }
      // M7-4: the breach slips and reasons say the same act in the field is deadly.
      for (final m in [Mk.allInBefore, Mk.allInAfter]) {
        expect(m.textBn, contains('মাঠে এই একই কাজ প্রাণঘাতী'));
      }
      expect(L.whyRight[M7PtwWhy.beforeGap]!.any((l) => l.contains('মাঠে')), isTrue);
      expect(L.whyRight[M7PtwWhy.afterGap]!.any((l) => l.contains('মাঠে')), isTrue);
      expect(L.whyRight[M7PtwWhy.law]!.any((l) => l.contains('মাঠে')), isTrue);
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m7_ptw_inquiry/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7PtwInquiryPacks.keys, ['do_7_4_b']);
      expect(m7PtwInquiryPacks['do_7_4_b']!.titleBn, 'বৈধ PTW ছিল কি?');
    });

    test('libraries: same length, big enough, never a rule marked wrong; the coworker\'s cards alike', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7PtwWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.whyQ.values.toSet(), containsAll(['এখানে PTW ছিল না কেন বললেন?', 'সব বৈধ বললেন কেন?', 'লগবুকে নেই — এর মানে কী?', 'এই গাফিলতিতে আইনত কী হতে পারে?']));
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
      expectSameLength('stamps', [L.pin, L.noRowStamp, L.allInStamp], ratio: 2.0);
    });

    test('spoken lines: his exit is recorded; myth 2 word for word is his new line; every guide line is listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['PTW তো শুধু সুপারভাইজারের দায়িত্ব, আমার এটা নিয়ে ভাবার দরকার নেই।']);
      // The lesson's myth 2, word for word (tool/all_training_chapters_bn.json, 7.4).
      // The lesson's single code points for য় ড় ঢ় read as base + nukta (X6).
      final lesson = File('tool/all_training_chapters_bn.json')
          .readAsStringSync()
          .replaceAll('\u09DF', '\u09AF\u09BC')
          .replaceAll('\u09DC', '\u09A1\u09BC')
          .replaceAll('\u09DD', '\u09A2\u09BC');
      expect(lesson.contains(L.coworker.line), isTrue, reason: 'myth 2 verbatim');
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            L.nextCase,
            L.wrongRow,
            L.rowOk,
            ...L.tapWhy,
            ...L.whyQ.values,
            ...L.coworker.asks,
            L.callHeld,
            L.allSet,
            L.quick,
            L.fail,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_ptw_inquiry: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the desk: below the header, above the stamps, clear of the guide and of each other; rows big enough to tap', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M7PtwGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(244, h - 122, 360, h);
        final stamps = Rect.fromLTRB(8, h - 74, 240, h - 14);
        final areas = <Rect>[g.folder, g.fieldCopy, g.photo, g.stripHit, g.book];
        for (final r in areas) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: $r below the header');
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
          expect(r.overlaps(stamps), isFalse, reason: 'h $h: $r under the stamps');
        }
        for (final (i, a) in areas.indexed) {
          for (final b in areas.skip(i + 1)) {
            expect(a.overlaps(b), isFalse, reason: 'h $h: $a / $b');
          }
        }
        expect(g.rowH, greaterThanOrEqualTo(22), reason: 'h $h: a row is a finger wide');
        for (var i = 0; i < kM7PtwRowsPerPage; i++) {
          expect(g.book.contains(g.row(i).center), isTrue);
        }
        for (final n in [6, 9]) {
          for (var i = 0; i < n; i++) {
            expect(g.stripHit.contains(g.thumb(i, n).center), isTrue);
            expect(g.photoAt(g.thumb(i, n).center.dx, n), i);
          }
          expect(g.thumb(n - 1, n).right, lessThanOrEqualTo(g.stripHit.right));
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

    testWidgets('the guide comes first: a tap does not skip him; then the desk, the pin and both stamps', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7PtwInquiryPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.deskLabel), findsOneWidget);
      expect(_pin, findsOneWidget);
      expect(_noRow, findsOneWidget);
      expect(_allIn, findsOneWidget);
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
      expect(lines.every((l) => l.contains(L.askFind)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // A breach first and a no-row case; a clean case with the coworker on it.
    final flowSeeds = [
      _seedWhere((d) => d.cases.first.breach && d.cases.any((c) => c.kind == M7PtwCaseKind.noRow) && d.coworkerCase == 0),
      _seedWhere((d) => d.cases.any((c) => c.kind == M7PtwCaseKind.clean && !c.fieldCopy) && d.cases[d.coworkerCase].kind == M7PtwCaseKind.clean),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three cases, rows clipped, the strip, a verdict hold, reasons; he is refused → pass', (t) async {
        final d = m7PtwDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playCase(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.4/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.4/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final rowFirst = _seedWhere((d) => d.cases.first.kind == M7PtwCaseKind.clean && d.coworkerCase != 0 && d.cases.first.matchPage! > 0);
    testWidgets('a wrong row: no slip, no clip pay; a time verdict before the row is a slip that keeps the case; the row clips', (t) async {
      final c = await _open(t, rowFirst);
      final k = _live.kase;
      // A row on page 0 that is not the job's.
      final wrong = k.page(0).indexWhere((r) => r.id != k.matchId);
      await _tapAt(t, _geo.row(wrong).center);
      expect(c.read(guideDirectorProvider).line, contains(L.wrongRow));
      expect(_live.clipped, isNull);
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.clipPay, 0);
      // "সব কাজ" before the row: a slip; the same case goes on.
      await _hold(t, _allIn);
      expect(find.text(Mk.timeFirst.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 1);
      expect(_live.index, 0);
      expect(_live.stage, M7PtwStage.find);
      await _clip(t);
      expect(_live.thorough, isFalse);
      // The clipped row's page stays open.
      await t.dragFrom(Offset(180, _geo.book.center.dy) * _k, const Offset(-130, 0));
      await _pump(t, 300);
      expect(M7PtwInquiryProbe.page, k.matchPage);
      // A short tap on a stamp does nothing.
      await _hold(t, _allIn, ms: 200);
      expect(_live.roundDone, isFalse);
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.timeFirst.key});
      await _close(t, c);
    });

    final noRowFirst = _seedWhere((d) => d.cases.first.kind == M7PtwCaseKind.noRow && d.coworkerCase != 0);
    testWidgets('a no-row case: a pin is a slip (no row to clip); then "লগবুকে নেই" closes it', (t) async {
      final c = await _open(t, noRowFirst);
      await _hold(t, _pin);
      expect(find.text(Mk.timeFirst.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.roundDone, isFalse);
      await _hold(t, _noRow);
      expect(_live.roundDone, isTrue);
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.timeFirst.key});
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      await _close(t, c);
    });

    testWidgets('"লগবুকে নেই" with the row there: a slip that keeps the case; three of them strike the level out', (t) async {
      final c = await _open(t, rowFirst);
      for (var i = 0; i < 3; i++) {
        await _hold(t, _noRow);
        if (i < 2) {
          expect(find.text(Mk.rowExists.textBn), findsOneWidget);
          expect(find.byType(FreezeFrame), findsNothing);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_live.index, 0, reason: 'the same case');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act in this level');
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.rowExists.key});
      await _close(t, c);
    });

    final breachCw = _seedWhere((d) => d.cases.first.kind == M7PtwCaseKind.before && d.coworkerCase == 0);
    testWidgets('his case: the first verdict hold waits for him; listening is a slip, no freeze; the case goes on', (t) async {
      final c = await _open(t, breachCw);
      await _clip(t);
      // "সব কাজ" held: he cuts in, the stamp does nothing.
      await _hold(t, _allIn);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in at the hold');
      expect(_live.roundDone, isFalse);
      expect(_live.slips, 0);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final wrong = _textsOnScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await pickChoice(t, wrong.first, proceed: false);
      await _pump(t, 800);
      expect(find.text(Mk.listened.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'listening here is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      // Now "সব কাজ" on a breach: a slip; then the pin on the early photo.
      await _hold(t, _allIn);
      expect(find.text(Mk.allInBefore.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      final k = _live.kase;
      await _tapAt(t, _geo.thumb(k.photos.indexWhere(k.outside), k.photos.length).center);
      await _hold(t, _pin);
      expect(_live.roundDone, isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.listened.key, Mk.allInBefore.key});
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      await _close(t, c);
    });

    testWidgets('gesture hand: idle at the logbook shows a hand that presses nothing; a tapped stamp gets a hold ring', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, rowFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the logbook');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a swipe or a sweep presses nothing');
      await _tapAt(t, const Offset(300, 100));
      expect(scene().showing, isFalse);
      // A short tap on a stamp: the hand comes back as a hold on that stamp.
      await _hold(t, _noRow, ms: 150);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
