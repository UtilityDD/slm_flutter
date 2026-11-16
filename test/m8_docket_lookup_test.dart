// Lesson 8.6 (গ্রাহক অভিযোগ নিষ্পত্তি), কাজ "ডকেট নম্বরটা দিন" (do_8_6_b,
// m8_docket_lookup): the rules (no number → 1912 / CCC; a verbal complaint
// acted on, a wrong or closed row, a false house started, no proof, a report
// before the repair, a finished docket left open, a CGRF order not pinned
// first = slips; a misread number = a free re-ask), the deal (24–30 rows, the
// targets off the first screen, decoys sharing 3 digits, 4 consumers with at
// least one false and one real, the order and his moment dealt), the lesson
// lines, the libraries, every spoken line listed, the drawn places, and the
// level in the shell: the guide first, a full clean play (rows flick-scrolled
// and tapped, a hold for the photo, a reason pick, the CGRF order pinned, the
// coworker refused), the free re-ask, slips with their cards, three slips,
// listening = a slip (no freeze), his chip waits for him, the early home key,
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
import 'package:slm_flutter/features/game/level_result_parts.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m8_docket_lookup.dart';
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
  rungId: '8.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8DocketPacks['do_8_6_b']!;
typedef L = M8DocketLines;
typedef Mk = M8DocketMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('\u09DC', '\u09A1\u09BC').replaceAll('\u09DD', '\u09A2\u09BC').replaceAll('\u09DF', '\u09AF\u09BC');

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

M8DocRun get _live => M8DocketProbe.run!;
ScrollController get _scroll => M8DocketProbe.scroll!;

Finder _key(String k) => find.byKey(ValueKey(k));
Finder _chipF(M8Chip c) => _key('chip-${c.name}');

/// Pumps until the consumer has spoken and the level waits for the player.
Future<void> _waitReady(WidgetTester t, {int maxMs = 40000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (M8DocketProbe.ready?.call() ?? false) {
      await _pump(t, 100);
      return;
    }
    await t.pump(const Duration(milliseconds: 100));
  }
  fail('the level never waited for the player');
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8DocketLookupPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8DocDeal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8DocketDeal(math.Random(s))));

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, [...L.reportScript.right, ...L.photoScript.right]);
  await _pump(t, 2600);
}


Future<void> _ensureNoPeek(WidgetTester t) async {
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t);
}

Future<void> _selectRow(WidgetTester t, int row, {bool expectSelected = true}) async {
  final n = _live.deal.rows[row].number;
  final max = _scroll.position.maxScrollExtent;
  _scroll.jumpTo((row * M8DocGeo.rowH - 2 * M8DocGeo.rowH).clamp(0.0, max));
  await _pump(t, 100);
  await t.tap(_key('row-$n'), warnIfMissed: false);
  await _pump(t, 200);
  if (expectSelected && _live.selected != row && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    // He cut in just then (the scene takes no touch while he talks): refuse, again.
    await _refuse(t);
    _scroll.jumpTo((row * M8DocGeo.rowH - 2 * M8DocGeo.rowH).clamp(0.0, max));
    await _pump(t, 100);
    await t.tap(_key('row-$n'), warnIfMissed: false);
    await _pump(t, 200);
  }
  if (expectSelected) expect(_live.selected, row);
}

Future<void> _tapChip(WidgetTester t, M8Chip c) async {
  await t.tap(_chipF(c), warnIfMissed: false);
  await _pump(t, 300);
}

Future<void> _holdPhoto(WidgetTester t) async {
  final g = await t.startGesture(t.getCenter(_chipF(M8Chip.photo)));
  await _pump(t, 1000);
  await g.up();
  await _pump(t, 300);
}

/// Does [act]; if the coworker cuts in instead (his chip waits for him),
/// refuses him and does it again.
Future<void> _doAct(WidgetTester t, Future<void> Function() act, bool Function() took) async {
  await act();
  if (!took() && find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    await _refuse(t);
    await act();
  }
  expect(took(), isTrue, reason: 'the act took');
}

Future<void> _reason(WidgetTester t, M8DocReason r) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck ($r)');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[r]!);
  await _pump(t, 1500);
}

Future<void> _pinOrder(WidgetTester t) async {
  expect(_live.orderOut, isTrue);
  _scroll.jumpTo(_scroll.position.maxScrollExtent);
  await _pump(t, 200);
  final from = t.getCenter(_key('row-order'));
  final to = t.getCenter(_key('pin-slot'));
  final g = await t.startGesture(from);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
  expect(_live.pinned, isTrue);
  await _reason(t, M8DocReason.cgrf);
}

/// One consumer played clean.
Future<void> _serveOne(WidgetTester t) async {
  final i = _live.index;
  await _waitReady(t);
  await _ensureNoPeek(t);
  if (_live.orderOut) {
    await _pinOrder(t);
    await _ensureNoPeek(t);
  }
  final c = _live.consumer;
  Future<void> reasonIfDue(M8DocReason r, bool due) async {
    if (due) await _reason(t, r);
  }

  if (c.kind == M8DocKind.noNumber) {
    final due = !_live.asked.contains(M8DocReason.call);
    await _doAct(t, () => _tapChip(t, M8Chip.call), () => _live.caught.contains(L.caughtVerbal));
    // The reward puts the reason on the table at once.
    await reasonIfDue(M8DocReason.call, due);
  } else {
    if (c.kind == M8DocKind.misread && !_live.reasked) {
      await _tapChip(t, M8Chip.start);
      expect(_live.reasked, isTrue);
      await _waitReady(t);
      await _ensureNoPeek(t);
    }
    await _selectRow(t, c.row);
    await _ensureNoPeek(t);
    if (c.lit) {
      final due = !_live.asked.contains(M8DocReason.photo);
      await _doAct(t, () => _holdPhoto(t), () => _live.proof.contains(c.row));
      await reasonIfDue(M8DocReason.photo, due);
    } else {
      final dueMatch = !_live.asked.contains(M8DocReason.match);
      await _doAct(t, () => _tapChip(t, M8Chip.start), () => _live.phase == M8DocPhase.work);
      await _pump(t, 2800);
      await reasonIfDue(M8DocReason.match, dueMatch);
      await _waitReady(t);
      await _ensureNoPeek(t);
      final dueReport = !_live.asked.contains(M8DocReason.report);
      await _doAct(t, () => _tapChip(t, M8Chip.report), () => _live.closedAt.containsKey(c.row));
      await reasonIfDue(M8DocReason.report, dueReport);
    }
  }
  for (var k = 0; k < 40 && !_live.done && _live.index == i; k++) {
    await _pump(t, 200);
  }
}

M8DocRow _row(String n, {bool open = true, String para = 'নতুনপাড়া'}) => M8DocRow(number: n, para: para, complaint: 'বিদ্যুৎ নেই', open: open, closedAt: open ? null : '17:20');

M8DocConsumer _cons(M8DocKind k, {int row = -1, String? shown, bool lit = false}) =>
    M8DocConsumer(kind: k, row: row, shown: shown, lit: lit, look: 0, line: 'x', sms: true, mirror: false);

M8DocRun _runOf(List<M8DocConsumer> cs, {int? orderAfter, M8CwKind cw = M8CwKind.report}) => M8DocRun(M8DocDeal(
      rows: [_row('48213'), _row('48217'), _row('48291', open: false), _row('52614'), _row('31872', open: false)],
      consumers: cs,
      orderAfter: orderAfter,
      cw: cw,
      light: 0,
      clock0: 18 * 60,
    ));

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.6');
}

void main() {
  group('rules', () {
    test('deals: 24–30 rows, targets off the first screen, decoys share 3 digits, 4 consumers (a false and a real at least); plays differ', () {
      final seen = <String>{};
      final kinds = <M8DocKind>{};
      final order = <int?>{};
      final cws = <M8CwKind>{};
      final lights = <int>{};
      final sizes = <int>{};
      var misreads = 0, noNumbers = 0, lateTargets = 0, closedRows = 0;
      for (var s = 0; s < 300; s++) {
        final d = m8DocketDeal(math.Random(s));
        final n = d.rows.length;
        sizes.add(n);
        expect(n, inInclusiveRange(24, 30));
        expect(d.consumers, hasLength(4));
        expect(d.rows.map((r) => r.number).toSet(), hasLength(n), reason: 'every number once');
        for (final r in d.rows) {
          expect(RegExp(r'^[1-9][0-9]{4}$').hasMatch(r.number), isTrue, reason: r.number);
          expect(r.open, r.closedAt == null, reason: 'a closed row has its time');
          if (!r.open) closedRows++;
        }
        expect(d.consumers.where((c) => c.kind == M8DocKind.real), isNotEmpty);
        expect(d.consumers.where((c) => c.kind == M8DocKind.falseHouse), isNotEmpty);
        expect(d.consumers.map((c) => c.look).toSet(), hasLength(4), reason: 'four looks');
        for (final c in d.consumers) {
          kinds.add(c.kind);
          if (c.kind == M8DocKind.noNumber) {
            noNumbers++;
            expect(c.row, -1);
            expect(c.shown, isNull);
            expect(M8DocketLines.verbal, contains(c.line));
            continue;
          }
          expect(c.row, inInclusiveRange(6, n - 3), reason: 'the list must be scrolled');
          if (c.row >= 9) lateTargets++;
          final target = d.rows[c.row];
          expect(target.open, isTrue, reason: 'his docket is OPEN');
          expect(c.shown, isNotNull);
          expect((c.sms ? M8DocketLines.sms : M8DocketLines.ccc), contains(c.line));
          final prefix = target.number.substring(0, 3);
          final decoys = d.rows.where((r) => r != target && r.number.startsWith(prefix)).toList();
          expect(decoys.length, inInclusiveRange(2, 3), reason: 'decoys share the first 3 digits');
          expect(decoys.any((r) => r.open), isTrue, reason: 'another OPEN docket to act on by mistake');
          if (c.kind == M8DocKind.misread) {
            misreads++;
            expect(d.rows.any((r) => r.number == c.shown), isFalse, reason: 'the misread number is on no row');
            expect(c.shown!.substring(0, 3), prefix);
          } else {
            expect(c.shown, target.number);
          }
          if (c.kind == M8DocKind.real) expect(c.lit, isFalse);
          if (c.kind == M8DocKind.falseHouse) expect(c.lit, isTrue);
        }
        // Targets are distinct rows.
        expect(d.consumers.where((c) => c.row >= 0).map((c) => c.row).toSet().length, d.consumers.where((c) => c.row >= 0).length);
        expect(d.orderAfter == null || d.orderAfter! >= 1 && d.orderAfter! <= 3, isTrue);
        order.add(d.orderAfter);
        cws.add(d.cw);
        lights.add(d.light);
        seen.add('${d.rows.map((r) => r.number).join(',')}|${d.consumers.map((c) => '${c.kind.index}${c.lit}${c.look}').join()}|${d.orderAfter}${d.cw.index}');
      }
      expect(seen.length, 300);
      expect(kinds, M8DocKind.values.toSet());
      expect(order, {null, 1, 2, 3});
      expect(cws, M8CwKind.values.toSet());
      expect(lights, hasLength(kM8DocSkies.length));
      expect(sizes.length, greaterThan(5));
      expect(misreads, greaterThan(100));
      expect(noNumbers, greaterThan(100));
      expect(lateTargets, greaterThan(300), reason: 'targets deep in the list');
      expect(closedRows, greaterThan(1000));
    });

    test('no number: 1912 / CCC is right; start, photo and report with no docket are slips', () {
      for (final chip in [M8Chip.start, M8Chip.photo, M8Chip.report]) {
        final r = _runOf([_cons(M8DocKind.noNumber)]);
        final (res, m) = r.act(chip);
        expect(res, M8DocResult.slipped);
        expect(m, switch (chip) { M8Chip.start => Mk.startVerbal, M8Chip.photo => Mk.noNumberPhoto, _ => Mk.noNumberReport });
        expect(r.slips, 1);
      }
      final r = _runOf([_cons(M8DocKind.noNumber)]);
      r.selected = 2; // a row selected changes nothing for a no-number consumer
      expect(r.act(M8Chip.call), (M8DocResult.called, null));
      expect(r.slips, 0);
      expect(r.caught, [L.caughtVerbal]);
    });

    test('a real fault (dark house): select + start, then report; each wrong act its own slip', () {
      M8DocRun fresh() => _runOf([_cons(M8DocKind.real, row: 0, shown: '48213')]);
      var r = fresh();
      expect(r.act(M8Chip.start), (M8DocResult.nudge, null), reason: 'nothing selected: a free word');
      expect(r.act(M8Chip.photo), (M8DocResult.nudge, null));
      expect(r.slips, 0);
      expect(r.act(M8Chip.call), (M8DocResult.slipped, Mk.needless1912), reason: 'a docket exists');
      r = fresh()..selected = 1;
      expect(r.act(M8Chip.start), (M8DocResult.slipped, Mk.wrongRow), reason: 'another OPEN docket');
      r = fresh()..selected = 2;
      expect(r.act(M8Chip.start), (M8DocResult.slipped, Mk.wrongRow), reason: 'a CLOSED row');
      r = fresh()..selected = kM8OrderSel;
      expect(r.act(M8Chip.report), (M8DocResult.slipped, Mk.wrongRow));
      r = fresh()..selected = 0;
      expect(r.act(M8Chip.photo), (M8DocResult.slipped, Mk.needlessPhoto));
      expect(r.act(M8Chip.report), (M8DocResult.slipped, Mk.reportEarly), reason: 'reported before the repair');
      expect(r.slips, 2);
      expect(r.phase, M8DocPhase.lookup);
      expect(r.act(M8Chip.start), (M8DocResult.started, null));
      expect(r.phase, M8DocPhase.work);
      // Locked on its row while the work is done.
      expect(r.select(1), isFalse);
      expect(r.selected, 0);
      expect(r.act(M8Chip.start), (M8DocResult.slipped, Mk.leftOpen));
      expect(r.act(M8Chip.photo), (M8DocResult.slipped, Mk.leftOpen));
      expect(r.act(M8Chip.call), (M8DocResult.slipped, Mk.leftOpen));
      final (res, m) = r.act(M8Chip.report);
      expect((res, m), (M8DocResult.closed, null));
      expect(r.closedAt[0], matches(RegExp(r'^\d\d:\d\d$')));
      expect(r.caught, [L.caughtDocket, L.caughtClosed]);
      r.next();
      expect(r.done, isTrue);
      expect(r.slips, 5);
      expect(r.passed, isFalse);
    });

    test('a false complaint (lit house): the photo is right; start and a report with no proof are slips', () {
      M8DocRun fresh() => _runOf([_cons(M8DocKind.falseHouse, row: 3, shown: '52614', lit: true)])..selected = 3;
      var r = fresh();
      expect(r.act(M8Chip.start), (M8DocResult.slipped, Mk.falseStart));
      expect(r.act(M8Chip.report), (M8DocResult.slipped, Mk.noProof));
      expect(r.act(M8Chip.call), (M8DocResult.slipped, Mk.needless1912));
      expect(r.act(M8Chip.photo), (M8DocResult.proof, null));
      expect(r.proof, {3});
      expect(r.caught, [L.caughtDocket, L.caughtProof]);
      expect(r.slips, 3);
      r = fresh()..selected = 0;
      expect(r.act(M8Chip.photo), (M8DocResult.slipped, Mk.wrongRow));
      expect(r.proof, isEmpty);
    });

    test('a misread number: any chip says "no such docket" once, free, and the right number comes; then it plays on', () {
      final r = _runOf([_cons(M8DocKind.misread, row: 0, shown: '48231')]);
      expect(r.shownNumber, '48231');
      r.selected = 1;
      expect(r.act(M8Chip.start), (M8DocResult.noDocket, null));
      expect(r.slips, 0);
      expect(r.reasked, isTrue);
      expect(r.selected, isNull);
      expect(r.shownNumber, '48213', reason: 'the right number now');
      r.select(0);
      expect(r.act(M8Chip.start), (M8DocResult.started, null));
    });

    test('the CGRF order: unpinned it blocks every chip (a slip, nothing happens); pinned it is done; a row tap can select it', () {
      final r = _runOf([_cons(M8DocKind.real, row: 0, shown: '48213'), _cons(M8DocKind.noNumber)], orderAfter: 1);
      r.select(0);
      r.orderArrive();
      expect(r.orderOut, isTrue);
      expect(r.act(M8Chip.start), (M8DocResult.slipped, Mk.cgrfFirst));
      expect(r.phase, M8DocPhase.lookup, reason: 'the start did not happen');
      expect(r.act(M8Chip.call), (M8DocResult.slipped, Mk.cgrfFirst));
      expect(r.slips, 2);
      expect(r.select(kM8OrderSel), isTrue);
      expect(r.selected, kM8OrderSel);
      r.pin();
      expect(r.orderOut, isFalse);
      expect(r.pinned, isTrue);
      expect(r.selected, isNull);
      expect(r.caught, [L.caughtCgrf]);
      r.select(0);
      expect(r.act(M8Chip.start), (M8DocResult.started, null));
    });

    test('the home key: free while nothing is unreported; a slip and the end with a docket unreported', () {
      var r = _runOf([_cons(M8DocKind.real, row: 0, shown: '48213'), _cons(M8DocKind.noNumber)]);
      expect(r.home(), (M8DocResult.nudge, null));
      expect(r.slips, 0);
      r.select(0);
      r.act(M8Chip.start);
      expect(r.home(), (M8DocResult.slipped, Mk.homeUnreported));
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
      expect(r.act(M8Chip.report), (M8DocResult.none, null));
      // A clean play passes; marks 100 − 15 × slips, pass at 55.
      r = _runOf([_cons(M8DocKind.noNumber)]);
      r.act(M8Chip.call);
      r.next();
      expect((r.done, r.percent, r.passed), (true, 100, true));
      r = _runOf([_cons(M8DocKind.noNumber)]);
      for (var i = 0; i < 3; i++) {
        r.act(M8Chip.start);
      }
      r.act(M8Chip.call);
      r.next();
      expect((r.percent, r.passed), (55, true));
      r.slips = 4;
      expect(r.passed, isFalse);
    });

    test('reasons: the first time of each kind in a play asks, later pays at once; listening takes its own moment\'s card', () {
      final r = _runOf([_cons(M8DocKind.noNumber)]);
      for (final k in M8DocReason.values) {
        expect(r.reasonDue(k), isTrue);
        expect(r.reasonDue(k), isFalse);
      }
      expect(r.pushSlip(M8CwKind.report), Mk.pushListenReport);
      expect(r.pushSlip(M8CwKind.photo), Mk.pushListenPhoto);
      expect(r.slips, 2);
      expect(r.falseFrom(0), isFalse);
      final f = _runOf([_cons(M8DocKind.real, row: 0), _cons(M8DocKind.misread, row: 3, lit: true), _cons(M8DocKind.noNumber, lit: true)]);
      expect(f.falseFrom(0), isTrue);
      expect(f.falseFrom(2), isFalse, reason: 'a no-number house is not a false complaint');
      expect(f.isFalse, isFalse);
      f.next();
      expect(f.isFalse, isTrue);
    });

    test('no deadly in 8.6 (M8-1): every mistake a slip; keys, pictures, lesson points; the art folder is all used', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      expect(Mk.all.map((m) => m.textBn).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.6/m8_docket_lookup/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, anyOf(isNull, 0, 1, 2));
      }
      // The three slips of lesson point 2 (CGRF) and point 1 (the report) are named.
      expect(Mk.cgrfFirst.lessonPoint, 2);
      for (final m in [Mk.leftOpen, Mk.reportEarly, Mk.homeUnreported]) {
        expect(m.lessonPoint, 1);
      }
      expect(Mk.pushListen(M8CwKind.report), Mk.pushListenReport);
      expect(Mk.pushListen(M8CwKind.photo), Mk.pushListenPhoto);
      const dir = 'assets/game/art/m8_docket_lookup/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8DocketPacks.keys, ['do_8_6_b']);
    });

    test('the live lesson: the lines, the numbers and the myth the coworker leans on; no rupee amount anywhere', () {
      final lesson = _lesson();
      final text = _nk(jsonEncode(lesson));
      for (final s in [
        'দাদা, আপনি কি ডকেট করেছেন? নম্বরটা দিন, আমি দেখে নিচ্ছি।',
        'মুখে বলা অভিযোগের কোনো দাম নেই',
        'কাজ শেষ করে অফিসে রিপোর্ট না করা পর্যন্ত ডকেট ক্লোজ হয় না',
        'ডকেট ওপেন থাকলে SoP-এর জরিমানা বাড়তে থাকে',
        'CGRF-এর অর্ডারের কপি এলে সেটাকে সর্বোচ্চ গুরুত্ব দিয়ে কাজ করতে হয়',
        'তার ভিডিও বা ছবি তুলে রাখুন। শুনানির সময় এটাই প্রমাণ হবে',
        '১৯১২ (টোল ফ্রি) বা কাস্টমার কেয়ার সেন্টারে (CCC)',
        'গ্রাহকের পক্ষেই রায় দেয়',
        'আমাদের নামে কেস করে গ্রাহক কিছু করতে পারবে না',
      ]) {
        expect(text, contains(_nk(s)), reason: s);
      }
      // Lesson text the card quotes.
      expect(_nk(Mk.cgrfFirst.textBn), contains(_nk('CGRF-এর অর্ডারের কপি এলে সেটাকে সর্বোচ্চ গুরুত্ব দিয়ে')));
      expect(_nk(Mk.leftOpen.textBn), contains(_nk('কাজ শেষ করে অফিসে রিপোর্ট না দেওয়া পর্যন্ত ডকেট ক্লোজ হয় না')));
      expect(_nk(Mk.startVerbal.textBn), contains(_nk('ডকেট নম্বর না হওয়া পর্যন্ত আইনের চোখে সমস্যাই নেই')));
      // His lines (DRAFT) and the two the lesson gives.
      expect(L.photoScript.line, contains('কোম্পানির নামে কেউ কিছু করতে পারবে না'));
      expect(L.reportScript.line, contains('অফিসে রিপোর্ট কাল দিলেই হবে'));
      // 8.6 compensation: no amount on any line (M8-L10).
      final all = [...L.spokenLines, ...L.allWhyRight, ...L.allWhyWrong, for (final r in L.whyRight.values) ...r];
      for (final l in all) {
        expect(RegExp('[₹]|লক্ষ|লাখ|lakh', caseSensitive: false).hasMatch(l), isFalse, reason: l);
      }
      // The chips are the lesson's four; the order is 'CGRF'.
      expect([for (final c in M8Chip.values) L.chipLabel(c)], ['কাজ শুরু', 'ছবি/ভিডিও', 'অফিসে রিপোর্ট', '1912 / CCC-তে জানাতে বলুন']);
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ"; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        L.askFirst,
        L.askNext,
        ...L.tasks,
        ...L.tapWhy,
        L.nudgeRow,
        L.noDocket,
        L.reAsk,
        L.homeWait,
        for (final c in M8Chip.values) L.chipLabel(c),
        L.holdWord,
        L.homeKey,
        L.colHead,
        L.orderPinned,
        ...L.verbal,
        ...L.sms,
        ...L.ccc,
        ...L.paras,
        ...L.complaints,
        for (final r in M8DocReason.values) ...[L.whyQ(r), ...L.whyWrong(r)],
        ...L.allWhyRight,
        for (final s in [L.reportScript, L.photoScript]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        L.callHeldReport,
        L.callHeldPhoto,
        L.allSet,
        L.fail,
        L.caughtDocket,
        L.caughtVerbal,
        L.caughtClosed,
        L.caughtProof,
        L.caughtCgrf,
        L.caughtCall,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l); // the word, not কোম্পানি
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('মরা'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[\u09DC\u09DD\u09DF]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(RegExp('এলটি|এইচটি|কেভি').hasMatch(l), isFalse, reason: 'LT / HT / kV in English letters: $l');
        expect(RegExp(r'\bঅন\b|অফ-|\bঅফ\b').hasMatch(l.replaceAll('ফিউজ অফ', '')), isFalse, reason: 'ON / OFF: $l');
      }
      expectSameLength('why-all', [...L.allWhyRight, ...L.allWhyWrong], ratio: 1.5);
      for (final r in M8DocReason.values) {
        expectSameLength('why $r', [...L.whyRight[r]!, ...L.whyWrong(r)]);
        expectLibrary('why $r', L.whyRight[r]!, L.whyWrong(r));
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(L.whyRight[r]!, L.whyWrong(r), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final cw in [L.reportScript, L.photoScript]) {
        expectSameLength('coworker ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
        expect(cw.exitLine, L.coworkerExit);
      }
      expect(L.script(M8CwKind.report), L.reportScript);
      expect(L.script(M8CwKind.photo), L.photoScript);
      // The right reason fits the act: it names the lesson's rule for it.
      expect(L.whyRight[M8DocReason.report]!.join(), allOf(contains('ডকেট ক্লোজ'), contains('জরিমানা')));
      expect(L.whyRight[M8DocReason.photo]!.join(), contains('ছবি'));
      expect(L.whyRight[M8DocReason.cgrf]!.join(), contains('CGRF'));
    });

    test('spoken lines: his two pushes and every new guide line are listed for recording; his exit is recorded', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['অফিসে রিপোর্ট কাল দিলেই হবে, চলো বাড়ি।', 'ছবি-টবি তুলে কী হবে? কোম্পানির নামে কেউ কিছু করতে পারবে না।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
        L.newGuideLines,
        containsAll([L.intro, L.askFirst, L.askNext, ...L.tasks, for (final r in M8DocReason.values) L.whyQ(r), L.callHeldReport, L.callHeldPhoto, L.allSet, L.fail, for (final m in Mk.all) m.textBn]),
      );
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      expect(L.reused, containsAll(['ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', L.quick, L.coworkerExit]));
      // Every line the page speaks is in one of the lists.
      final spoken = L.spokenLines.toSet();
      for (final l in [
        L.intro,
        L.askFirst,
        L.askNext,
        ...L.tasks,
        ...L.tapWhy,
        L.nudgeRow,
        L.noDocket,
        L.homeWait,
        L.callHeldReport,
        L.callHeldPhoto,
        L.allSet,
        L.quick,
        L.fail,
        L.reportScript.line,
        L.photoScript.line,
        L.coworkerExit,
        ...L.reportScript.asks,
        ...L.photoScript.asks,
        for (final r in M8DocReason.values) L.whyQ(r),
        for (final m in Mk.all) m.textBn,
      ]) {
        expect(spoken, contains(l), reason: l);
      }
      // The consumers' words are silent captions (M8-10): never in a spoken list.
      for (final l in [...L.verbal, ...L.sms, ...L.ccc, L.reAsk]) {
        expect(spoken, isNot(contains(l)), reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_docket_lookup: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: the controls stay on the scene and apart; the house, the consumer, the slip and the caption clear of the guide and his bubble', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M8DocGeo.forScene(h, inset);
          final chips = [for (final c in M8Chip.values) g.chip(c)];
          for (final (i, a) in chips.indexed) {
            expect(a.left, greaterThanOrEqualTo(0));
            expect(a.right, lessThanOrEqualTo(360));
            expect(a.height, greaterThanOrEqualTo(44), reason: 'a touch target');
            expect(a.overlaps(g.tablet), isFalse, reason: 'h $h chip $i');
            expect(a.overlaps(g.home), isFalse);
            for (final b in chips.skip(i + 1)) {
              expect(a.overlaps(b), isFalse);
            }
          }
          expect(g.home.bottom, lessThanOrEqualTo(h - inset * 0.6));
          expect(g.home.height, greaterThanOrEqualTo(36));
          expect(g.tablet.bottom, lessThanOrEqualTo(g.chip(M8Chip.start).top));
          expect(g.list.top, greaterThan(g.pinSlot.bottom));
          expect(g.pinSlot.top, greaterThan(g.colHead.bottom - 1));
          expect(g.list.bottom, lessThanOrEqualTo(g.tablet.bottom));
          expect(g.list.height / M8DocGeo.rowH, greaterThanOrEqualTo(h >= 740 ? 5.5 : (h >= 640 ? 3.5 : 1.5)), reason: 'h $h rows in view');
          expect(g.house.top, greaterThan(118), reason: 'under the header');
          for (final r in [g.house, g.consumer, g.slip]) {
            expect(r.overlaps(g.bubble), isFalse, reason: 'h $h $r under his bubble');
            expect(r.overlaps(g.guide), isFalse, reason: 'h $h $r under the guide');
            expect(r.bottom, lessThanOrEqualTo(g.tabTop));
          }
          if (h >= 740) expect(g.caption.overlaps(g.bubble), isFalse);
          expect(g.listCentre.dy, closeTo(g.list.center.dy, 0.01));
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

    // His report moment on one play, his photo moment on another.
    final reportSeed = _seedWhere((d) =>
        d.cw == M8CwKind.report &&
        d.orderAfter == 2 &&
        d.consumers.any((c) => c.kind == M8DocKind.real) &&
        d.consumers.any((c) => c.kind == M8DocKind.falseHouse) &&
        d.consumers.any((c) => c.kind == M8DocKind.noNumber));
    final photoSeed = _seedWhere((d) =>
        d.cw == M8CwKind.photo &&
        d.orderAfter == null &&
        d.consumers.any((c) => c.kind == M8DocKind.misread) &&
        d.consumers.any((c) => c.kind == M8DocKind.real));
    final photoFirstSeed = _seedWhere((d) => d.cw == M8CwKind.photo && d.consumers.first.kind == M8DocKind.falseHouse && d.orderAfter != null);

    testWidgets('the guide comes first: a tap does not skip him; then the tablet, the four chips and the home key', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8DocketLookupPage(ctx: _ctx, pack: _pack, muted: true, seed: reportSeed)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _waitReady(t);
      for (final c in M8Chip.values) {
        expect(_label(L.chipLabel(c)), findsOneWidget);
      }
      expect(_label(L.homeKey), findsOneWidget);
      expect(_key('tablet'), findsOneWidget);
      expect(_key('pin-slot'), findsOneWidget);
      // The first rows are on screen, the list is longer than the screen.
      expect(find.byKey(ValueKey('row-${_live.deal.rows.first.number}')), findsOneWidget);
      expect(_scroll.position.maxScrollExtent, greaterThan(M8DocGeo.rowH * 10));
      // The consumer's number is on his slip; the match is not marked.
      expect(_label('${L.slipWord} ${_live.shownNumber}'), findsOneWidget);
      expect(_live.selected, isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the task pool in turn, never a row or a chip', (t) async {
      final c = await _open(t, reportSeed);
      await _waitReady(t);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.tapRead, L.tapShow, L.tapHome]);
      for (final l in lines) {
        expect(RegExp('[0-9]').hasMatch(l), isFalse, reason: 'no number named: $l');
        expect(l.contains('1912'), isFalse);
      }
      await _close(t, c);
    });

    testWidgets('flick-scrolling the list moves it and selects nothing; a row tap selects, a second tap lets go; any row can be chosen', (t) async {
      final c = await _open(t, reportSeed);
      await _waitReady(t);
      expect(_scroll.offset, 0);
      await t.fling(_key('docket-list'), const Offset(0, -300), 1500);
      await _pump(t, 1500);
      expect(_scroll.offset, greaterThan(M8DocGeo.rowH * 3), reason: 'inertia carried it');
      expect(_live.selected, isNull);
      await _selectRow(t, 9);
      await t.tap(_key('row-${_live.deal.rows[9].number}'), warnIfMissed: false);
      await _pump(t, 200);
      expect(_live.selected, isNull, reason: 'a second tap lets go');
      await _selectRow(t, 12);
      await _selectRow(t, 7);
      expect(_live.slips, 0);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    for (final (name, seed) in [('report moment', reportSeed), ('photo moment', photoSeed)]) {
      testWidgets('flow ($name, seed $seed): four consumers, rows scrolled and tapped, a hold, reasons, the order pinned, he is refused → pass', (t) async {
        final c = await _open(t, seed);
        for (var i = 0; i < 4 && !_live.done; i++) {
          await _serveOne(t);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.6/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.6/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget, reason: 'he was refused once');
        expect(find.text(L.caughtDocket), findsWidgets);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(_live.slips, 0);
        expect(_live.passed, isTrue);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a verbal complaint acted on, then the right chip; the card names the lesson; nothing starts', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.noNumber);
      final c = await _open(t, seed);
      await _waitReady(t);
      await _tapChip(t, M8Chip.start);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.startVerbal.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not deadly');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 0);
      expect(_live.phase, M8DocPhase.lookup);
      await _holdPhoto(t);
      expect(find.text(Mk.noNumberPhoto.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.startVerbal.key, Mk.noNumberPhoto.key]);
      expect(_live.slips, 2);
      await _close(t, c);
    });

    testWidgets('the wrong row is a slip with its card; the right row then goes on; selecting alone costs nothing', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.real);
      final c = await _open(t, seed);
      await _waitReady(t);
      final cons = _live.consumer;
      // A decoy sharing his first three digits.
      final decoy = _live.deal.rows.indexWhere((r) => r != _live.deal.rows[cons.row] && r.number.startsWith(_live.deal.rows[cons.row].number.substring(0, 3)));
      await _selectRow(t, decoy);
      expect(_live.slips, 0);
      await _tapChip(t, M8Chip.start);
      expect(find.text(Mk.wrongRow.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.phase, M8DocPhase.lookup);
      expect(_live.closedAt, isEmpty);
      await _selectRow(t, cons.row);
      await _doAct(t, () => _tapChip(t, M8Chip.start), () => _live.phase == M8DocPhase.work);
      await _pump(t, 2800);
      expect(_live.slips, 1);
      await _close(t, c);
    });

    testWidgets('no row selected: a chip is a free word from the guide, never a slip', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.real);
      final c = await _open(t, seed);
      await _waitReady(t);
      await _tapChip(t, M8Chip.start);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, L.nudgeRow);
      expect(_live.slips, 0);
      await _close(t, c);
    });

    testWidgets('a misread number: "no such docket", free; the right number comes on the slip and the play goes on', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.misread);
      final c = await _open(t, seed);
      await _waitReady(t);
      final before = _live.shownNumber;
      expect(_label('${L.slipWord} $before'), findsOneWidget);
      await _selectRow(t, 8);
      await _tapChip(t, M8Chip.start);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(L.noDocket), findsWidgets, reason: 'the tablet says so');
      expect(_live.slips, 0);
      expect(_live.reasked, isTrue);
      await _waitReady(t);
      final after = _live.shownNumber;
      expect(after, isNot(before));
      expect(after, _live.deal.rows[_live.consumer.row].number);
      expect(_label('${L.slipWord} $after'), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('a lit house: কাজ শুরু is a slip; a quick tap on the photo chip is nothing; the hold pins the proof', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.falseHouse && d.cw == M8CwKind.report);
      final c = await _open(t, seed);
      await _waitReady(t);
      final cons = _live.consumer;
      await _selectRow(t, cons.row);
      await _tapChip(t, M8Chip.start);
      expect(find.text(Mk.falseStart.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapChip(t, M8Chip.report);
      expect(find.text(Mk.noProof.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // A tap on the photo chip: no hold, no proof, no cost.
      await t.tap(_chipF(M8Chip.photo), warnIfMissed: false);
      await _pump(t, 1200);
      expect(_live.proof, isEmpty);
      expect(_live.slips, 2);
      expect(find.byType(MistakeCard), findsNothing);
      // The hold: the proof is pinned to its row (a camera on the row).
      await _holdPhoto(t);
      expect(_live.proof, {cons.row});
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.falseStart.key, Mk.noProof.key]);
      await _close(t, c);
    });

    testWidgets('the CGRF order: a chime, the last row; a chip first is a slip and does nothing; the drag pins it, then the play goes on', (t) async {
      final seed = _seedWhere((d) => d.orderAfter == 1 && d.cw == M8CwKind.report && d.consumers[0].kind != M8DocKind.falseHouse);
      final c = await _open(t, seed);
      await _serveOne(t);
      await _waitReady(t);
      expect(_live.index, 1);
      expect(_live.orderOut, isTrue, reason: 'it came with the second consumer');
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      await _pump(t, 200);
      debugPrint('DBG max ${_scroll.position.maxScrollExtent} off ${_scroll.offset} rows ${_live.deal.rows.length} drag ${find.byType(Draggable<int>).evaluate().length} rowkeys ${find.byWidgetPredicate((w) => w.key is ValueKey && (w.key as ValueKey).value.toString().startsWith('row-')).evaluate().map((e) => (e.widget.key as ValueKey).value).join(',')}');
      expect(_key('row-order'), findsOneWidget);
      expect(find.text(L.orderWords), findsOneWidget);
      expect(find.text(L.orderNumber), findsOneWidget);
      // Serving first: a slip, nothing happens.
      await _ensureNoPeek(t);
      await _tapChip(t, M8Chip.call);
      expect(find.text(Mk.cgrfFirst.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 1);
      expect(_live.slips, 1);
      // A tap on the order row only selects it.
      await t.tap(_key('row-order'), warnIfMissed: false);
      await _pump(t, 200);
      expect(_live.selected, kM8OrderSel);
      expect(_live.orderOut, isTrue);
      // The drag to the pin slot.
      await _pinOrder(t);
      expect(_live.orderOut, isFalse);
      expect(find.text(L.orderPinned), findsOneWidget);
      expect(_key('row-order'), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.cgrfFirst.key]);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (verbal starts); no freeze, nothing deadly', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.noNumber);
      final c = await _open(t, seed);
      await _waitReady(t);
      for (var i = 0; i < 3; i++) {
        await _tapChip(t, M8Chip.start);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 8.6');
      expect(c.read(gameSaveProvider).mistakes.every((m) => !m.deadly), isTrue);
      await _close(t, c);
    });

    testWidgets('বাড়ি চলুন with a finished docket unreported: a slip, and the play ends with that row open (fail panel)', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.real && d.cw == M8CwKind.photo);
      final c = await _open(t, seed);
      await _waitReady(t);
      final cons = _live.consumer;
      // Free while nothing is unreported.
      await t.tap(_key('home-key'), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, L.homeWait);
      await _selectRow(t, cons.row);
      await _doAct(t, () => _tapChip(t, M8Chip.start), () => _live.phase == M8DocPhase.work);
      await _pump(t, 2800);
      await _reason(t, M8DocReason.match);
      await _waitReady(t);
      await t.tap(_key('home-key'), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.text(Mk.homeUnreported.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2500);
      expect(_live.ended, isTrue);
      expect(_live.closedAt, isEmpty, reason: 'the row stays open');
      expect(find.byType(LevelFailPanel), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['8.6/do/1'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('his report moment: the report chip waits for him; listening = a slip with its card (no freeze); then it closes the docket', (t) async {
      final seed = _seedWhere((d) => d.cw == M8CwKind.report && d.consumers.first.kind == M8DocKind.real && d.orderAfter != 1);
      final c = await _open(t, seed);
      await _waitReady(t);
      final cons = _live.consumer;
      await _selectRow(t, cons.row);
      await _doAct(t, () => _tapChip(t, M8Chip.start), () => _live.phase == M8DocPhase.work);
      await _pump(t, 2800);
      await _reason(t, M8DocReason.match);
      // Straight at the report chip: he is due, so it does nothing yet.
      await _tapChip(t, M8Chip.report);
      if (find.byType(CoworkerPeek).evaluate().isEmpty) {
        await _pump(t, 600);
        expect(_live.closedAt, isNotEmpty, reason: 'he may only be there already');
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000) || coworkerSeen(t), isTrue);
      expect(_live.closedAt, isEmpty, reason: 'the report waited for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.reportScript.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushListenReport.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.pushListenReport.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He came once: the report now closes the docket.
      await _tapChip(t, M8Chip.report);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_live.closedAt, contains(cons.row));
      await _close(t, c);
    });

    testWidgets('his photo moment at a false house: he comes there; listening = the photo card; refusing him and holding pins the proof', (t) async {
      final c = await _open(t, photoFirstSeed);
      await _waitReady(t);
      final cons = _live.consumer;
      expect(_live.deal.cw, M8CwKind.photo);
      // He turns up on his own at the false house (nothing to do with a row).
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.photoScript.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.text(Mk.pushListenPhoto.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      if (_live.orderOut) await _pinOrder(t);
      await _selectRow(t, cons.row);
      await _holdPhoto(t);
      expect(_live.proof, {cons.row});
      expect(find.byType(CoworkerPeek), findsNothing);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the next consumer comes', (t) async {
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.noNumber && d.cw == M8CwKind.report);
      final c = await _open(t, seed);
      await _waitReady(t);
      await _tapChip(t, M8Chip.call);
      expect(_live.caught, contains(L.caughtVerbal));
      // At once: touches on the scene do nothing (shielded, then the deck).
      await t.tap(_chipF(M8Chip.start), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M8DocReason.call]!);
      await _pump(t, 4000);
      expect(_live.index, 1, reason: 'the next consumer');
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: the list waiting → a vertical swipe on the list; a row selected → a sweep over the four chips and the home key; it hides on touch', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.consumers.first.kind == M8DocKind.real);
      final c = await _open(t, seed);
      await _waitReady(t);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the list waiting');
      expect(scene().debugFrame, isNotNull);
      expect(scene().debugOptions, isEmpty);
      // It never presses a row: the list is unchanged.
      expect(_live.selected, isNull);
      await t.tap(_key('row-${_live.deal.rows[0].number}'), warnIfMissed: false);
      await _pump(t, 300);
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      expect(_live.selected, 0);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with a row selected');
      expect(scene().debugOptions, hasLength(5), reason: 'all four chips and the home key alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _close(t, c);
    });
  });
}

/// A coworker already on screen (or already gone after answering).
bool coworkerSeen(WidgetTester t) => find.byType(CoworkerPeek).evaluate().isNotEmpty || find.byType(ChoiceDeck).evaluate().isNotEmpty;
