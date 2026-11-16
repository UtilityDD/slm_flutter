// Lesson 8.8 (নেট মিটারিং রেগুলেশন), কাজ "নেট মিটারের হিসাব": the rules (a net
// or banked slip = IMPORT − EXPORT units + বিল / জমা + ফিক্সড চার্জ আছে; an
// ordinary meter = the stamp, never dialled units; an application = at most the
// sanctioned load and not less than asked; every wrong field is its own slip;
// nothing is deadly, ruling M8-1), the deal (3 visits of 4 cases, a net or banked
// house on visit 2 or 3 for the coworker, seasons, never-round registers,
// shuffled pages), the libraries, every spoken line listed, the drawn places,
// and the level in the shell: the guide first, a full clean round (meter paged,
// digits rolled, fields set, the slip handed over, a reason pick, the coworker
// refused), a wrong slip with its cards that comes back unchanged, three
// slips, listening = a slip (no freeze), the hand-over waits for him, the
// praise window takes no touch, and the gesture hand shows how (never what).
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
import 'package:slm_flutter/features/game/m8_net_bill.dart';
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
  rungId: '8.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8NetBillPacks['do_8_8_b']!;
typedef L = M8NetBillLines;
typedef Mk = M8NetBillMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('\u09dc', '\u09a1\u09bc').replaceAll('\u09dd', '\u09a2\u09bc').replaceAll('\u09df', '\u09af\u09bc');

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
M8Geo get _geo => M8Geo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8NetRun get _live => M8NetBillProbe.run!;

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 150);
}

/// Press the meter's button [n] times (the pages, one at a time).
Future<void> _press(WidgetTester t, [int n = 1]) async {
  for (var i = 0; i < n; i++) {
    await _tapAt(t, _geo.push.center);
    await _clear(t);
  }
}

/// Roll digit [i] to [target] (vertical drags, 20 px a step).
Future<void> _dial(WidgetTester t, int i, int target) async {
  for (var attempt = 0; attempt < 6; attempt++) {
    final cur = _live.slip.digits[i];
    if (cur == target) return;
    final n = (target - cur) % 10;
    final from = _geo.dig(i).center;
    final to = from - Offset(0, n * 20.0 + 5);
    final g = await t.startGesture(from * _k);
    for (var s = 1; s <= 8; s++) {
      await g.moveTo(Offset.lerp(from, to, s / 8)! * _k);
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await _pump(t, 100);
    await _clear(t);
  }
  expect(_live.slip.digits[i], target, reason: 'digit $i rolled');
}

Future<void> _dialUnits(WidgetTester t, int units) async {
  await _dial(t, 0, units ~/ 100);
  await _dial(t, 1, (units ~/ 10) % 10);
  await _dial(t, 2, units % 10);
}

Future<void> _slide(WidgetTester t, double kw) async {
  final g0 = _geo;
  final from = g0.knob(_live.slip.approve).center;
  final to = Offset(g0.track.left + g0.track.width * kw / M8Geo.maxKw, from.dy);
  final g = await t.startGesture(from * _k);
  for (var s = 1; s <= 10; s++) {
    await g.moveTo(Offset.lerp(from, to, s / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 150);
  await _clear(t);
  expect(_live.slip.approve, kw, reason: 'knob at $kw kW');
}

Future<void> _handOver(WidgetTester t, {Offset? to}) async {
  final g0 = _geo;
  final from = g0.handle.center;
  final end = to ?? g0.handTarget.center;
  final g = await t.startGesture(from * _k);
  for (var s = 1; s <= 10; s++) {
    await g.moveTo(Offset.lerp(from, end, s / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// If he cut in meanwhile, refuse him.
Future<void> _clear(WidgetTester t) async {
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t);
}

/// Fill the slip of the visit on screen the right way (the meter read first).
Future<void> _fill(WidgetTester t) async {
  final v = _live.visit;
  switch (v.kind) {
    case M8Case.net || M8Case.banked:
      await _press(t, v.pages.length);
      await _dialUnits(t, v.netUnits);
      await _tapAt(t, v.kind == M8Case.net ? _geo.billSeg.center : _geo.bankSeg.center);
      await _tapAt(t, _geo.fixYes.center);
    case M8Case.ordinary:
      await _press(t, v.pages.length);
      await _tapAt(t, _geo.stamp.center);
      await _tapAt(t, _geo.fixYes.center);
    case M8Case.apply:
      await _tapAt(t, _geo.flip.center);
      await _slide(t, v.expectedKw);
  }
  await _clear(t);
}

/// The reasons after a right hand-over (and the load-shedding one if asked).
Future<void> _reasons(WidgetTester t, M8Visit v) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck (${v.reason})');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[v.reason]!);
  await _pump(t, 1500);
  if (v.shed) {
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the load-shedding reason');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[M8Reason.shed]!);
    await _pump(t, 1500);
  }
}

/// One visit played clean: meter read, slip filled, handed over (the
/// coworker refused if he cuts in), the reasons.
Future<void> _playVisit(WidgetTester t) async {
  final i = _live.index;
  final v = _live.visit;
  await _fill(t);
  await _handOver(t);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_live.caught.where((c) => c != L.caughtCall).length, i, reason: 'the hand-over waited for him');
    await _refuse(t);
    await _handOver(t);
  }
  expect(_live.slips, 0);
  await _reasons(t, v);
  await _pump(t, 2400);
  expect(_live.index, i + 1);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8NetBillPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8NetBillDeal(math.Random(s))));

M8Visit _visit(M8Case kind, {int imp = 482, int exp = 268, double sanctioned = 3, double asked = 3}) => M8Visit(
      kind: kind,
      imp: imp,
      exp: exp,
      pages: kind == M8Case.ordinary ? const [M8Page.date, M8Page.time, M8Page.kwh] : const [M8Page.date, M8Page.import, M8Page.time, M8Page.export],
      make: 0,
      look: 0,
      season: M8Season.summer,
      lineAlt: false,
      shed: false,
      sanctioned: sanctioned,
      asked: asked,
      dateText: '14-11-2026',
      timeText: '10:42',
    );

M8NetRun _runOf(M8Visit first) {
  final rng = math.Random(1);
  return M8NetRun(M8Deal(visits: [first, m8DealVisit(M8Case.net, rng), m8DealVisit(M8Case.banked, rng)], coworkerVisit: 1));
}

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.8');
}

void main() {
  group('rules', () {
    test('deals: 3 distinct visits of 4 cases, a net or banked house on 2 or 3 for him; seasons, registers, pages, strip values and looks vary', () {
      final seen = <String>{};
      final cases = <M8Case>{};
      final seasonsOf = <M8Case, Set<M8Season>>{};
      final his = <int>{};
      final makes = <int>{}, looks = <int>{}, firstPages = <M8Page>{};
      var sheds = 0, above = 0, equal = 0, within = 0, lineAlts = 0;
      final sanctions = <double>{};
      for (var s = 0; s < 400; s++) {
        final d = m8NetBillDeal(math.Random(s));
        expect(d.visits, hasLength(3));
        expect(d.visits.map((v) => v.kind).toSet(), hasLength(3), reason: 'three different cases');
        expect(d.coworkerVisit, inInclusiveRange(1, 2));
        expect(d.visits[d.coworkerVisit].isNetOrBanked, isTrue, reason: 'he comes at a net or banked house');
        expect(d.visits.skip(1).any((v) => v.isNetOrBanked), isTrue);
        his.add(d.coworkerVisit);
        for (final v in d.visits) {
          cases.add(v.kind);
          (seasonsOf[v.kind] ??= {}).add(v.season);
          expect(v.imp, inInclusiveRange(100, 600));
          expect(v.exp, inInclusiveRange(100, 600));
          expect(v.imp % 10, isNot(0), reason: 'IMPORT never round');
          expect(v.exp % 10, isNot(0), reason: 'EXPORT never round');
          expect(v.netUnits % 10, isNot(0));
          expect(v.netUnits, greaterThanOrEqualTo(40));
          if (v.kind == M8Case.net) expect(v.imp, greaterThan(v.exp));
          if (v.kind == M8Case.banked) expect(v.exp, greaterThan(v.imp));
          expect(v.pages.toSet(), hasLength(v.pages.length));
          expect(v.pages, v.kind == M8Case.ordinary ? containsAll([M8Page.date, M8Page.time, M8Page.kwh]) : containsAll([M8Page.date, M8Page.time, M8Page.import, M8Page.export]));
          expect(v.pages.length, v.kind == M8Case.ordinary ? 3 : 4);
          expect(v.pages, isNot(contains(v.kind == M8Case.ordinary ? M8Page.import : M8Page.kwh)));
          firstPages.add(v.pages.first);
          makes.add(v.make);
          looks.add(v.look);
          if (v.shed) sheds++;
          if (v.lineAlt) lineAlts++;
          expect(v.sanctioned, inInclusiveRange(2, 5));
          sanctions.add(v.sanctioned);
          expect(v.asked, greaterThanOrEqualTo(1));
          expect(v.asked % 0.5, 0, reason: '0.5 kW steps');
          expect(v.expectedKw, math.min(v.asked, v.sanctioned));
          if (v.asked > v.sanctioned) {
            above++;
          } else if (v.asked == v.sanctioned) {
            equal++;
          } else {
            within++;
          }
          expect(v.dateText, matches(RegExp(r'^\d\d-\d\d-2026$')));
          expect(v.timeText, matches(RegExp(r'^\d\d:\d\d$')));
        }
        seen.add('${d.coworkerVisit}|${d.visits.map((v) => '${v.kind.index}${v.imp}${v.exp}${v.pages.map((p) => p.index).join()}${v.look}${v.make}${v.shed}${v.sanctioned}${v.asked}').join('|')}');
      }
      expect(seen.length, greaterThan(395), reason: 'plays differ');
      expect(cases, M8Case.values.toSet());
      expect(seasonsOf[M8Case.banked], {M8Season.winter}, reason: 'a banked visit is a winter one');
      expect(seasonsOf[M8Case.net], {M8Season.summer}, reason: 'a net-bill visit is a summer one');
      expect(seasonsOf[M8Case.ordinary], M8Season.values.toSet());
      expect(seasonsOf[M8Case.apply], M8Season.values.toSet());
      expect(his, {1, 2});
      expect(makes, {0, 1, 2});
      expect(looks, {0, 1, 2, 3});
      expect(firstPages.length, greaterThanOrEqualTo(4), reason: 'the page order is shuffled');
      expect(sheds, inInclusiveRange(200, 600));
      expect(lineAlts, inInclusiveRange(300, 900));
      expect(above, greaterThan(200));
      expect(equal, greaterThan(200));
      expect(within, greaterThan(200));
      expect(sanctions, {2.0, 3.0, 4.0, 5.0});
    });

    test('the meter pages one register at a time; nothing is shown before the first press; the pages cycle', () {
      final r = _runOf(_visit(M8Case.net));
      expect(r.page, isNull);
      final seen = <M8Page>[];
      for (var i = 0; i < 8; i++) {
        r.press();
        seen.add(r.page!);
      }
      expect(seen.sublist(0, 4), r.visit.pages);
      expect(seen.sublist(4), r.visit.pages, reason: 'it goes round');
      expect(r.visit.pageValue(M8Page.import), '482');
      expect(r.visit.pageValue(M8Page.export), '268');
      expect(r.visit.pageValue(M8Page.date), '14-11-2026');
    });

    test('a net or banked slip: units = the difference, বিল / জমা by who gave more, ফিক্সড চার্জ আছে; the stamp is needless', () {
      final net = _runOf(_visit(M8Case.net));
      expect(net.visit.netUnits, 214);
      expect(net.judge(), [Mk.units, Mk.modeBill, Mk.fixedOff], reason: 'a blank slip: every field wrong');
      net.slip.digits.setAll(0, [2, 1, 4]);
      net.slip.bill = true;
      net.slip.fixed = true;
      expect(net.judge(), isEmpty);
      // The wrong way round and the neighbours.
      net.slip.digits.setAll(0, [2, 1, 5]);
      expect(net.judge(), [Mk.units]);
      net.slip.digits.setAll(0, [2, 1, 4]);
      net.slip.bill = false;
      expect(net.judge(), [Mk.modeBill]);
      net.slip.bill = true;
      net.slip.fixed = false;
      expect(net.judge(), [Mk.fixedOff], reason: 'নেই is a slip');
      net.slip.fixed = true;
      net.slip.stamped = true;
      expect(net.judge(), [Mk.needlessStamp], reason: 'a bi-directional meter needs no stamp');
      // Banked: export above import → the same number, জমা.
      final bank = _runOf(_visit(M8Case.banked, imp: 268, exp: 482));
      bank.slip.digits.setAll(0, [2, 1, 4]);
      bank.slip.fixed = true;
      bank.slip.bill = true;
      expect(bank.judge(), [Mk.modeBank], reason: 'gave more → জমা, not বিল');
      bank.slip.bill = false;
      expect(bank.judge(), isEmpty);
      bank.slip.digits.setAll(0, [0, 0, 0]);
      expect(bank.judge(), [Mk.units]);
      // Units with leading zeros.
      final small = _runOf(_visit(M8Case.net, imp: 187, exp: 143));
      small.slip.digits.setAll(0, [0, 4, 4]);
      small.slip.bill = true;
      small.slip.fixed = true;
      expect(small.judge(), isEmpty);
    });

    test('an ordinary meter: the stamp, never dialled units; ফিক্সড চার্জ নেই is still a slip; বিল / জমা is not judged', () {
      final r = _runOf(_visit(M8Case.ordinary));
      expect(r.judge(), [Mk.noStamp]);
      r.slip.stamped = true;
      expect(r.judge(), isEmpty);
      r.slip.bill = false;
      expect(r.judge(), isEmpty, reason: 'বিল / জমা means nothing on an ordinary meter');
      r.slip.fixed = true;
      expect(r.judge(), isEmpty);
      r.slip.fixed = false;
      expect(r.judge(), [Mk.fixedOff]);
      r.slip.fixed = null;
      r.slip.digits.setAll(0, [3, 2, 1]);
      expect(r.judge(), [Mk.dialOrdinary], reason: 'units dialled instead of stamping, stamp or not');
      r.slip.stamped = false;
      expect(r.judge(), [Mk.dialOrdinary]);
    });

    test('an application: at most the sanctioned load, never less than asked (a cut within the limit is needless)', () {
      // Asked within the limit: approve what is asked.
      final within = _runOf(_visit(M8Case.apply, sanctioned: 4, asked: 2.5));
      expect(within.visit.expectedKw, 2.5);
      expect(within.visit.reason, M8Reason.whole);
      expect(within.judge(), [Mk.needlessCut], reason: 'the knob starts at 0');
      within.slip.approve = 2.0;
      expect(within.judge(), [Mk.needlessCut]);
      within.slip.approve = 2.5;
      expect(within.judge(), isEmpty);
      within.slip.approve = 3.0;
      expect(within.judge(), isEmpty, reason: 'above asked but within the limit: not judged more');
      within.slip.approve = 4.5;
      expect(within.judge(), [Mk.overLimit]);
      // Asked equal to the limit.
      final equal = _runOf(_visit(M8Case.apply, sanctioned: 3, asked: 3));
      equal.slip.approve = 3;
      expect(equal.judge(), isEmpty);
      expect(equal.visit.reason, M8Reason.whole);
      // Asked above: approve the limit, no more and no less.
      final above = _runOf(_visit(M8Case.apply, sanctioned: 3, asked: 4.5));
      expect(above.visit.askedAbove, isTrue);
      expect(above.visit.expectedKw, 3);
      expect(above.visit.reason, M8Reason.cut);
      above.slip.approve = 4.5;
      expect(above.judge(), [Mk.overLimit], reason: 'approving what is asked is over 100 %');
      above.slip.approve = 3.5;
      expect(above.judge(), [Mk.overLimit]);
      above.slip.approve = 2.5;
      expect(above.judge(), [Mk.needlessCut]);
      above.slip.approve = 3;
      expect(above.judge(), isEmpty);
    });

    test('handing over: a right slip costs nothing; each wrong field is one slip; the fields stay; listening is one slip', () {
      final r = _runOf(_visit(M8Case.net));
      expect(r.handOver().$2, [Mk.units, Mk.modeBill, Mk.fixedOff]);
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.passed, isFalse, reason: 'not done');
      r.slip.digits.setAll(0, [2, 1, 4]);
      r.slip.bill = true;
      r.slip.fixed = true;
      expect(r.handOver(), (true, const <DoMistake>[]));
      expect(r.slips, 3);
      expect(r.caught.single, L.caughtVisit(r.visit, 0));
      expect(r.caught.single, contains('214'));
      r.next();
      expect(r.index, 1);
      expect(r.presses, 0);
      expect(r.slip.units, 0);
      expect(r.slip.bill, isNull);
      expect(r.slip.fixed, isNull);
      expect(r.slip.stamped, isFalse);
      expect(r.visitSlips, 0);
      expect(r.pushSlip(), Mk.pushListen);
      expect(r.slips, 4);
      expect(r.percent, 40);
      r.next();
      r.next();
      expect(r.done, isTrue);
      expect(r.handOver(), (false, const <DoMistake>[]));
      // The mark: 100 − 15 per slip, pass at 55.
      expect(M8NetRun(m8NetBillDeal(math.Random(2))).percent, 100);
    });

    test('no deadly in 8.8 (M8-1): every mistake a slip; keys, pictures, lesson points; the art folder is all used', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      expect(Mk.all.map((m) => m.textBn).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.8/m8_net_bill/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(Mk.units.lessonPoint, 0);
      expect(Mk.dialOrdinary.lessonPoint, 0);
      expect(Mk.needlessStamp.lessonPoint, 0);
      expect(Mk.overLimit.lessonPoint, 3);
      expect(Mk.needlessCut.lessonPoint, 3);
      expect(Mk.pushListen.lessonPoint, isNull, reason: 'a myth, not a numbered point');
      const dir = 'assets/game/art/m8_net_bill/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8NetBillPacks.keys, ['do_8_8_b']);
      expect(_pack.quickMs, 70000);
    });

    test('the live lesson 8.8: both directions, the ordinary-meter fact, the fixed charge, banking, 100 %, anti-islanding', () {
      final lesson = _lesson();
      final text = _nk(jsonEncode(lesson));
      expect(text, contains(_nk('এটি দুই দিকেই মাপে')));
      expect(text, contains(_nk('Import')));
      expect(text, contains(_nk('Export')));
      expect(text, contains(_nk('সাধারণ মিটারে সোলার লাগালে, আপনি বিদ্যুৎ দিলেও সেটা খরচ হিসেবে দেখাবে এবং বিল বেড়ে যাবে')));
      expect(text, contains(_nk('নেট-মিটার লাগানো বাধ্যতামূলক')));
      expect(text, contains(_nk('তার পার্থক্যের বিল হবে')));
      expect(text, contains(_nk("'ফিক্সড চার্জ' তো দিতেই হবে")));
      expect(text, contains(_nk('গ্রিডে জমা (Bank) রাখতে পারে')));
      expect(text, contains(_nk('অনুমোদিত লোডের ১০০% (বা নির্দিষ্ট শতাংশ)-এর বেশি সোলার বসানো যায় না')));
      expect(text, contains(_nk('অন-গ্রিড')));
      expect(text, contains(_nk('হাইব্রিড ইনভার্টার ও ব্যাটারি লাগে')));
      expect(text, contains(_nk('সেফটির (Anti-islanding) কারণে')));
      // The consumers' complaints and the reason cards use the lesson's words.
      final myths = ((lesson['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      expect(_nk((myths[1] as Map)['myth'] as String), contains(_nk('বিল শূন্য হয়ে যাবে')));
      expect(_nk(Mk.pushListen.textBn), contains(_nk('বিল শূন্য হয় না')));
      expect(_nk(Mk.pushListen.textBn), contains(_nk('ফিক্সড চার্জ তো দিতেই হবে')));
      expect(_nk(Mk.fixedOff.textBn), contains(_nk('ফিক্সড চার্জ')));
      expect(_nk(L.whyRight[M8Reason.net]!.first), contains(_nk('পার্থক্যের বিল')));
      expect(_nk(L.whyRight[M8Reason.cut]!.first), contains('100%'));
      expect(_nk(L.whyRight[M8Reason.shed]!.first), contains(_nk('সেফটির জন্য সোলারও বন্ধ')));
      expect(_nk(L.whyRight[M8Reason.shed]![1]), contains(_nk('হাইব্রিড ইনভার্টার আর ব্যাটারি লাগে')));
      expect(L.sayShed, contains('লোড শেডিং'));
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ"; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        L.title,
        ...L.tasksMeter,
        ...L.tasksApply,
        ...L.tapWhy,
        ...L.allWhyQ,
        ...L.allWhyRight,
        ...L.allWhyWrong,
        ...L.allSays,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.netUnits,
        L.stampWord,
        L.sanctionWord,
        L.askedWord,
        L.fixedYes,
        L.fixedNo,
        for (final m in Mk.all) m.textBn,
        L.caughtVisit(_visit(M8Case.apply, sanctioned: 3, asked: 4.5), 3),
        L.caughtVisit(_visit(M8Case.net), 0),
        L.kwText(3.5),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[\u09dc\u09dd\u09df]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(RegExp('(এলটি|এইচটি|কেভি|কেভিএ)').hasMatch(l), isFalse, reason: 'LT / HT / kV in English letters: $l');
      }
      expect(L.kwText(3.5), '3.5 kW');
      expect(L.kwText(4), '4 kW');
      for (final r in M8Reason.values) {
        final right = L.whyRight[r]!, wrong = L.whyWrong[r]!;
        expectSameLength('why $r', [...right, ...wrong]);
        expectLibrary('why $r', right, wrong);
        expect(L.whyQ(r), isNotEmpty);
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(right, wrong, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.allWhyRight.toSet().intersection(L.allWhyWrong.toSet()), isEmpty);
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
    });

    test('spoken lines: his exit is recorded; his push and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['সোলারওয়ালার বিল শূন্য লিখে দাও, ফিক্সড চার্জটাও কেটে দাও — গ্রাহক খুশি, ঝামেলাও শেষ।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
        L.newGuideLines,
        containsAll([L.intro, L.askRead, L.askSlip, L.askHand, L.askApply, L.askSlide, ...L.allWhyQ, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]),
      );
      expect(L.reused, contains('ওকে কী বলবেন?'), reason: 'it already has a clip');
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      final spoken = L.spokenLines.toSet();
      for (final l in [
        L.intro,
        ...L.tasksMeter,
        ...L.tasksApply,
        ...L.tapWhy,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.coworker.line,
        L.coworkerExit,
        ...L.coworker.asks,
        ...L.allWhyQ,
        for (final m in Mk.all) m.textBn,
      ]) {
        expect(spoken, contains(l), reason: l);
      }
      expect(L.whyQ(M8Reason.net), 'গ্রাহককে বিলটা কীভাবে বোঝালেন?');
      expect(L.whyQ(M8Reason.cut), 'আবেদনের সোলার কেন কমালেন?');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_net_bill: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
      // The guide's task pool never names a number or an answer.
      for (final l in [...L.tasksMeter, ...L.tasksApply]) {
        expect(RegExp('[0-9]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('100'), isFalse);
      }
    });

    test('places: every control inside the clipboard, none over another, the meter strip clear of the guide\'s bubble, the consumer above it', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        for (final inset in h == 640.0 ? [0.0] : [0.0, 30.0]) {
          final g = M8Geo.forScene(h, inset);
          expect(g.clip.bottom, lessThanOrEqualTo(h));
          expect(g.clip.left, greaterThanOrEqualTo(0));
          expect(g.clip.right, lessThanOrEqualTo(360));
          final bubble = Rect.fromLTRB(128, g.clipTop - 166, 360, g.clipTop - 112);
          final controls = g.frontControls;
          for (final (i, a) in controls.indexed) {
            expect(g.clip.contains(a.topLeft) && g.clip.contains(a.bottomRight - const Offset(1, 1)), isTrue, reason: 'h $h: $a');
            expect(a.height, greaterThanOrEqualTo(29));
            for (final b in controls.skip(i + 1)) {
              expect(a.inflate(1).overlaps(b.inflate(1)), isFalse, reason: 'h $h: $a / $b');
            }
          }
          for (final r in [g.billSeg, g.bankSeg, g.fixYes, g.fixNo, g.stamp]) {
            expect(r.height + 4, greaterThanOrEqualTo(44), reason: 'touch height with its slop');
          }
          for (final a in controls) {
            expect(a.overlaps(g.handle), isFalse, reason: 'the hand-over is never in the hand\'s sweep');
          }
          expect(g.handle.overlaps(g.flip), isFalse);
          // The meter strip: display and button inside the box, clear of the bubble.
          expect(g.meterBox.contains(g.display.topLeft) && g.meterBox.contains(g.display.bottomRight), isTrue);
          expect(g.meterBox.contains(g.push.topLeft) && g.meterBox.contains(g.push.bottomRight), isTrue);
          expect(g.display.overlaps(g.push), isFalse);
          expect(g.meterBox.right, lessThan(128));
          expect(g.push.height, greaterThanOrEqualTo(48));
          expect(g.meterBox.bottom, lessThan(g.clipTop));
          final inv = g.inverter;
          if (inv != null) {
            expect(inv.overlaps(g.meterBox), isFalse);
            expect(inv.bottom, lessThanOrEqualTo(g.clipTop));
            expect(inv.right, lessThan(128));
          }
          // The right column: caption and consumer above the bubble, apart.
          expect(g.caption.overlaps(bubble), isFalse, reason: 'h $h: caption over the bubble');
          expect(g.consumer.overlaps(bubble), isFalse, reason: 'h $h: consumer over the bubble');
          expect(g.caption.overlaps(g.consumer), isFalse);
          expect(g.caption.top, greaterThan(140));
          expect(g.consumer.right, lessThanOrEqualTo(360));
          expect(g.caption.left, greaterThan(g.meterBox.right));
          expect(g.handTarget.contains(g.consumer.center), isTrue);
          expect(g.handTarget.overlaps(g.handle), isFalse);
          final tr = g.trainee;
          if (tr != null) {
            expect(tr.overlaps(g.caption), isFalse);
            expect(tr.overlaps(bubble), isFalse);
            expect(tr.overlaps(g.meterBox), isFalse);
          }
          // The strip: knob on the track, the steps of 0.5 kW.
          expect(g.kwAt(g.track.left - 40), 0);
          expect(g.kwAt(g.track.right + 40), M8Geo.maxKw);
          expect(g.kwAt(g.knob(3.5).center.dx), 3.5);
          for (final kw in [0.0, 2.5, 8.0]) {
            expect(g.track.inflate(2).contains(g.knob(kw).center), isTrue);
          }
          expect(g.readout.overlaps(g.sanctionBox), isFalse);
          expect(g.sanctionBox.overlaps(g.askedBox), isFalse);
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

    testWidgets('the guide comes first: a tap does not skip him; then the meter, the slip and the clipboard', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8NetBillPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.flipWord), findsOneWidget);
      expect(_label(L.stampWord), findsOneWidget);
      expect(find.text(L.netUnits), findsOneWidget);
      expect(find.text(L.say(M8NetBillProbe.run!.visit.kind, M8NetBillProbe.run!.visit.lineAlt)), findsOneWidget, reason: 'the consumer\'s line, as a caption');
      expect(find.textContaining('নেট মিটার স্লিপ'), findsNothing, reason: 'no description text on the scene');
      expect(M8NetBillProbe.run!.page, isNull, reason: 'nothing is read for him');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the task pool in turn, never a value or an answer', (t) async {
      final seed = _seedWhere((d) => d.visits.first.kind != M8Case.apply);
      final c = await _open(t, seed);
      expect(c.read(guideDirectorProvider).line, contains(L.askRead));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.askSlip, L.askHand, L.askRead]);
      for (final l in lines) {
        expect(RegExp('[0-9]').hasMatch(l), isFalse, reason: l);
      }
      await _close(t, c);
    });

    testWidgets('the meter first: the slip waits until the button was pressed; a press shows one page; the pages go round', (t) async {
      final seed = _seedWhere((d) => d.visits.first.isNetOrBanked);
      final c = await _open(t, seed);
      final v = _live.visit;
      // The slip's controls do nothing yet (a tap is a miss, a drag moves nothing).
      await _tapAt(t, _geo.billSeg.center);
      await _tapAt(t, _geo.stamp.center);
      expect(_live.slip.bill, isNull);
      expect(_live.slip.stamped, isFalse);
      final g = await t.startGesture(_geo.dig(0).center * _k);
      await g.moveBy(const Offset(0, -60));
      await g.up();
      await _pump(t, 200);
      expect(_live.slip.units, 0);
      // Press: the first page, in the dealt order; one page on the glass.
      for (var i = 0; i < v.pages.length * 2; i++) {
        await _tapAt(t, _geo.push.center);
        final p = v.pages[i % v.pages.length];
        expect(_live.page, p);
        expect(find.text(v.pageValue(p)), findsOneWidget, reason: 'page $i');
        for (final other in v.pages.where((x) => x != p && x != M8Page.date && x != M8Page.time)) {
          expect(find.text(v.pageValue(other)), findsNothing, reason: 'only one register at a time');
        }
        expect(_live.slip.units, 0, reason: 'nothing copies to the slip');
      }
      // Now the slip answers.
      await _tapAt(t, _geo.fixYes.center);
      expect(_live.slip.fixed, isTrue);
      await _tapAt(t, _geo.fixNo.center);
      expect(_live.slip.fixed, isFalse);
      await _tapAt(t, _geo.billSeg.center);
      expect(_live.slip.bill, isTrue);
      await _tapAt(t, _geo.bankSeg.center);
      expect(_live.slip.bill, isFalse);
      await _tapAt(t, _geo.stamp.center);
      expect(_live.slip.stamped, isTrue);
      await _tapAt(t, _geo.stamp.center);
      expect(_live.slip.stamped, isFalse, reason: 'the stamp lifts');
      await _dial(t, 1, 7);
      await _dial(t, 1, 3);
      expect(_live.slip.digits, [0, 3, 0]);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _close(t, c);
    });

    testWidgets('flip: the back is the application strip; blank dashes and a dead knob unless it is an application; the slider moves in 0.5 kW steps', (t) async {
      final seed = _seedWhere((d) => d.visits.first.kind == M8Case.apply);
      final c = await _open(t, seed);
      final v = _live.visit;
      expect(c.read(guideDirectorProvider).line, contains(L.askApply));
      await _tapAt(t, _geo.flip.center);
      expect(find.text(L.kwText(v.sanctioned)), findsWidgets);
      expect(find.text(L.kwText(v.asked)), findsWidgets);
      expect(find.text(L.sanctionWord), findsOneWidget);
      await _slide(t, 1.5);
      expect(find.textContaining(L.kwText(1.5)), findsWidgets);
      await _slide(t, v.sanctioned);
      expect(_live.slip.approve, v.sanctioned);
      // Flip back and forth: the value stays.
      await _tapAt(t, _geo.flip.center);
      expect(find.text(L.netUnits), findsOneWidget);
      await _tapAt(t, _geo.flip.center);
      expect(_live.slip.approve, v.sanctioned);
      await _close(t, c);

      final seed2 = _seedWhere((d) => d.visits.first.isNetOrBanked);
      final c2 = await _open(t, seed2);
      await _tapAt(t, _geo.flip.center);
      expect(find.text('—'), findsWidgets, reason: 'no application on this visit');
      // Dragging the dead knob moves nothing.
      final g = await t.startGesture(_geo.knob(0).center * _k);
      await g.moveBy(const Offset(120, 0));
      await g.up();
      await _pump(t, 200);
      expect(_live.slip.approve, 0);
      await _close(t, c2);
    });

    // His visit 2 (with an ordinary meter and an application also dealt), his visit 3
    // (with a load-shedding question somewhere) and a play with both a net and a banked house.
    final flowSeeds = [
      _seedWhere((d) => d.coworkerVisit == 1 && d.visits.any((v) => v.kind == M8Case.ordinary) && d.visits.any((v) => v.kind == M8Case.apply)),
      _seedWhere((d) => d.coworkerVisit == 2 && d.visits.any((v) => v.shed) && d.visits.any((v) => v.kind == M8Case.apply)),
      _seedWhere((d) => d.visits.any((v) => v.kind == M8Case.net) && d.visits.any((v) => v.kind == M8Case.banked) && d.visits.any((v) => v.shed)),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three houses, the meter paged, the slip filled and handed over, reasons, he is refused → pass', (t) async {
        final c = await _open(t, seed);
        final kinds = _live.deal.visits.map((v) => v.kind).toList();
        for (var i = 0; i < 3; i++) {
          await _playVisit(t);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.8/do/1'], 'cleared', reason: '$kinds');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.8/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final netFirst = _seedWhere((d) => d.visits.first.isNetOrBanked && d.coworkerVisit == 2);
    testWidgets('a wrong slip: one card per wrong field, the slip comes back as it was, fix it and hand it over', (t) async {
      final c = await _open(t, netFirst);
      final v = _live.visit;
      await _press(t, v.pages.length);
      await _dialUnits(t, v.netUnits);
      await _tapAt(t, v.kind == M8Case.net ? _geo.billSeg.center : _geo.bankSeg.center);
      await _tapAt(t, _geo.fixNo.center);
      await _tapAt(t, _geo.stamp.center);
      await _handOver(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.fixedOff.textBn), findsOneWidget);
      expect(_live.slips, 2, reason: 'two wrong fields, two slips');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(Mk.needlessStamp.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0, reason: 'the same house');
      expect(_live.slip.units, v.netUnits, reason: 'the slip came back with the fields as they were');
      expect(_live.slip.fixed, isFalse);
      expect(_live.slip.stamped, isTrue);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.fixedOff.key, Mk.needlessStamp.key]);
      expect(c.read(gameSaveProvider).mistakes.every((m) => !m.deadly), isTrue);
      expect(find.byType(FreezeFrame), findsNothing);
      await _tapAt(t, _geo.fixYes.center);
      await _tapAt(t, _geo.stamp.center);
      expect(_live.judge(), isEmpty);
      await _handOver(t);
      expect(find.byType(MistakeCard), findsNothing);
      await _reasons(t, v);
      await _pump(t, 2400);
      expect(_live.index, 1);
      expect(_live.slips, 2);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (a blank slip handed over); nothing freezes', (t) async {
      final c = await _open(t, netFirst);
      await _press(t);
      await _handOver(t);
      expect(find.text(Mk.units.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(StruckOutCard), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 8.8');
      expect(c.read(gameSaveProvider).mistakes, hasLength(3));
      await _close(t, c);
    });

    testWidgets('an ordinary meter with dialled units: its own card; the slip is fixed by rolling back to nothing', (t) async {
      final seed = _seedWhere((d) => d.visits.first.kind == M8Case.ordinary && d.visits.any((v) => v.kind == M8Case.apply));
      final c = await _open(t, seed);
      await _press(t, _live.visit.pages.length);
      await _dial(t, 2, 4);
      await _tapAt(t, _geo.stamp.center);
      await _handOver(t);
      expect(find.text(Mk.dialOrdinary.textBn), findsOneWidget);
      expect(_live.slips, 1);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _dial(t, 2, 0);
      expect(_live.judge(), isEmpty);
      await _close(t, c);
    });

    final hisSecond = _seedWhere((d) => d.coworkerVisit == 1);
    testWidgets('listening to him = a slip (no freeze); the hand-over waited for him', (t) async {
      final c = await _open(t, hisSecond);
      await _playVisit(t);
      expect(_live.index, 1);
      // His house: the first touch of the slip calls him; the hand-over, soon after, waits for him.
      await _press(t);
      await _tapAt(t, _geo.fixYes.center);
      await _handOver(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the hand-over waits for him');
      expect(_live.caught, hasLength(1));
      expect(find.byType(MistakeCard), findsNothing);
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
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.pushListen.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      expect(_live.slips, 1);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He came once: the slip can be finished and handed over.
      await _fill(t);
      await _handOver(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      await _reasons(t, _live.visit);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the next house comes', (t) async {
      final c = await _open(t, netFirst);
      final v = _live.visit;
      await _fill(t);
      await _handOver(t);
      expect(find.byType(MistakeCard), findsNothing);
      // At once: drags and taps on the scene do nothing (shielded, then the deck).
      final presses = _live.presses;
      await _tapAt(t, _geo.push.center);
      expect(_live.presses, presses);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[v.reason]!);
      if (v.shed) {
        await _pump(t, 800);
        await _pickRight(t, L.whyRight[M8Reason.shed]!);
      }
      await _pump(t, 2800);
      expect(_live.index, 1);
      expect(_live.slip.units, 0, reason: 'a fresh blank slip');
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the slip dropped anywhere but on the consumer springs back for free', (t) async {
      final c = await _open(t, netFirst);
      await _fill(t);
      await _handOver(t, to: const Offset(200, 176));
      expect(_live.caught, isEmpty);
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(_live.slip.units, _live.visit.netUnits);
      await _close(t, c);
    });

    testWidgets('gesture hand: the meter unread → a tap on the button; the slip waiting → a nudge or a sweep over every control; it hides on touch', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.visits.first.isNetOrBanked);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the meter unread');
      expect(scene().debugOptions, isEmpty, reason: 'one control: a tap hint, not a sweep');
      final g = await t.startGesture(_geo.dig(0).center * _k);
      await _pump(t, 600);
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      await g.up();
      await _pump(t, 300);
      expect(_live.slip.units, 0, reason: 'the meter is unread: the slip is not live');
      // Read the meter: now the slip waits; the hand nudges or sweeps, never at one answer.
      await _press(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the slip waiting');
      final opts = scene().debugOptions;
      expect(opts.isEmpty || opts.length == _geo.frontControls.length, isTrue, reason: 'a nudge (no options) or a sweep over all');
      if (opts.isNotEmpty) expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hand on the application strip: a sideways nudge on the knob, no option named', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.visits.first.kind == M8Case.apply);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _tapAt(t, _geo.flip.center);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, isEmpty);
      expect(_live.slip.approve, 0, reason: 'it moved nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
