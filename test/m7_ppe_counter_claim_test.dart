// Lesson 7.6 (ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন), কাজ "কাউন্টারে দাবি":
// the rules (a right claim brings a replacement, the stock event once a play,
// signing for a faulty item = a slip or a deadly, the wrong claim and a claim
// on a good item = slips, the docket), the deal (job, order, 2–3 faulty items,
// a good one, glove faults only on 11 kV jobs, stamps shuffled, calendar), the
// live lesson (X3: IS 4770 টাইপ ৪, IS 2925, IS 15298, the myth word for word),
// the libraries, every spoken line listed, the drawn places, and the level in
// the shell: the guide first, a full clean play (stamps dragged and held, the
// tray, a reason pick, the stock event with the coworker refused), a slip
// card, a deadly freeze, three slips strike out, listening = a slip, the
// stamps wait for him, a stamp let go early costs nothing, and the gesture
// hand shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m7_ppe_counter_claim.dart';
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
  rungId: '7.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7PpePacks['do_7_6_a']!;
typedef L = M7PpeLines;
typedef Mk = M7PpeMistakes;

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
M7PpeRun get _live => M7PpeProbe.run!;
M7PpeDeal get _deal => _live.deal;

/// Drag the stamp for [c] to [target] (design px, the pin) and hold [holdMs].
Future<void> _stampTo(WidgetTester t, int slot, Offset pin, {bool docket = false, int holdMs = 760, bool lift = true}) async {
  final from = (docket ? _geo.docketStamp(slot) : _geo.stamp(slot)).center;
  final to = lift ? pin.translate(0, M7PpeGeo.lift) : pin;
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await _pump(t, holdMs);
  await g.up();
  await _pump(t, 400);
}

Future<void> _stamp(WidgetTester t, M7Claim c, {int? line, int holdMs = 760}) async {
  final slot = _deal.stampOrder.indexOf(c);
  await _stampTo(t, slot, _geo.line(line ?? _live.index).center, holdMs: holdMs);
}

Future<void> _docketStamp(WidgetTester t, M7Docket d) async {
  final slot = _deal.docketOrder.indexOf(d);
  await _stampTo(t, slot, _geo.docket.center, docket: true);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7PpeCounterClaimPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M7PpeDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7PpeDeal(math.Random(s))));

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 3200);
}

/// Settle the line the right way: stamps held, a reason picked when due, the
/// stock event with the coworker refused, until the line moves on.
Future<void> _playLine(WidgetTester t) async {
  final idx = _live.index;
  for (var guard = 0; guard < 8 && _live.index == idx; guard++) {
    final p = _live.piece;
    if (p == null) {
      // The stock event: the stamps wait for him; he is refused; the search.
      await _refuse(t);
      await _pump(t, 2400);
      continue;
    }
    final claim = m7RightClaim(p.look);
    final why = m7WhyOf(claim);
    final due = !_live.asked.contains(why);
    await _stamp(t, claim);
    expect(find.byType(MistakeCard), findsNothing, reason: '$claim on ${p.look}');
    if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
      await _refuse(t);
      await _pump(t, 2400);
      continue;
    }
    if (due) {
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck ($why)');
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[why]!);
      await _pump(t, 1500);
    } else {
      await _pump(t, 1500);
    }
    if (_live.awaitingStock) {
      await _refuse(t);
      await _pump(t, 2800);
    }
    await _pump(t, 1800);
  }
  expect(_live.index, idx + 1, reason: 'the line moved on');
}

/// The four lines played clean (the docket is next).
Future<void> _toDocket(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await _playLine(t);
  }
  await _pump(t, 800);
  expect(_live.atDocket, isTrue);
}

M7Piece _pc(int id, M7Item i, M7Look l) => M7Piece(id: id, item: i, look: l);

/// A hand-made deal: [chains] per item (a list of looks), the stock item and
/// whether the back shelf has one.
M7PpeDeal _dealOf({
  M7Job job = M7Job.kv11,
  Map<M7Item, List<M7Look>>? chains,
  M7Item stock = M7Item.helmet,
  bool found = true,
  List<M7Item> order = M7Item.values,
}) {
  var id = 0;
  final c = chains ??
      {
        M7Item.helmet: [M7Look.cracked],
        M7Item.shoes: [M7Look.ok],
        M7Item.gloves: [M7Look.torn, M7Look.lowType, M7Look.ok],
        M7Item.harness: [M7Look.expired, M7Look.ok],
      };
  return M7PpeDeal(
    job: job,
    order: order,
    chains: {for (final e in c.entries) e.key: [for (final l in e.value) _pc(id++, e.key, l)]},
    stockItem: stock,
    found: found ? _pc(id++, stock, M7Look.ok) : null,
    stampOrder: M7Claim.values,
    docketSwap: false,
    calendar: const M7Calendar(day: 16, month: 11, year: 2026),
    light: 0,
  );
}

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.6');
}

void main() {
  group('rules', () {
    test('deals: 4 items in some order; 2–3 faulty, a good one; glove faults on 11 kV only; the stock item; stamps shuffled; plays differ', () {
      final seen = <String>{};
      final jobs = <M7Job>{};
      final looks = <M7Look>{};
      final stocks = <M7Item>{};
      final firsts = <M7Item>{};
      var foundSome = 0, foundNone = 0, second = 0, stampMoved = 0, swap = 0;
      final faultyCounts = <int>{};
      final months = <int>{};
      for (var s = 0; s < 300; s++) {
        final d = m7PpeDeal(math.Random(s));
        jobs.add(d.job);
        expect(d.order.toSet(), M7Item.values.toSet());
        firsts.add(d.order.first);
        expect(d.stampOrder.toSet(), M7Claim.values.toSet(), reason: 'all six stamps, always');
        expect(d.stampOrder, hasLength(6));
        if (d.stampOrder[0] != M7Claim.sign) stampMoved++;
        if (d.docketSwap) swap++;
        final faulty = d.faulty;
        faultyCounts.add(faulty.length);
        expect(faulty.length, inInclusiveRange(2, 3));
        expect(faulty.length, lessThan(4), reason: 'a good item every play');
        expect(d.stockItem, isNot(M7Item.gloves), reason: 'never gloves');
        expect(faulty, contains(d.stockItem));
        stocks.add(d.stockItem);
        expect(d.chains[d.stockItem]!, hasLength(1), reason: 'no replacement: out of stock');
        d.found == null ? foundNone++ : foundSome++;
        if (d.found != null) {
          expect(d.found!.look, M7Look.ok);
          expect(d.found!.item, d.stockItem);
        }
        final ids = <int>{};
        for (final i in M7Item.values) {
          final chain = d.chains[i]!;
          for (final p in chain) {
            expect(p.item, i);
            expect(m7LookFits(i, p.look, d.job), isTrue, reason: '$i ${p.look} on ${d.job}');
            expect(ids.add(p.id), isTrue, reason: 'unique ids');
            looks.add(p.look);
            if (p.look == M7Look.expired) expect(p.labelMonths, lessThan(0), reason: 'the date is before the calendar');
            if (i == M7Item.harness && p.look != M7Look.expired) expect(p.labelMonths, greaterThan(0));
          }
          if (i != d.stockItem && faulty.contains(i)) {
            expect(chain.last.look, M7Look.ok, reason: 'a replacement chain ends good');
            expect(chain.length, inInclusiveRange(2, 3));
            if (chain.length == 3) {
              second++;
              expect(chain[1].look, isNot(M7Look.ok));
              expect(chain[1].look, isNot(chain[0].look));
            }
          } else if (!faulty.contains(i)) {
            expect(chain.single.look, M7Look.ok);
          }
        }
        if (d.job == M7Job.lt) {
          expect(d.chains[M7Item.gloves]!.single.look, M7Look.ok, reason: 'glove faults only on 11 kV jobs');
        }
        months.add(d.calendar.month);
        seen.add('${d.job.index}${d.order.map((e) => e.index).join()}${d.stampOrder.map((e) => e.index).join()}${d.stockItem.index}${d.found == null}'
            '${[for (final i in M7Item.values) d.chains[i]!.map((p) => p.look.index).join(',')].join('|')}');
      }
      expect(seen.length, greaterThan(280));
      expect(jobs, M7Job.values.toSet());
      expect(looks, M7Look.values.toSet());
      expect(stocks, {M7Item.helmet, M7Item.shoes, M7Item.harness});
      expect(firsts, M7Item.values.toSet());
      expect(faultyCounts, {2, 3});
      expect(foundSome, greaterThan(80));
      expect(foundNone, greaterThan(80));
      expect(second, greaterThan(20));
      expect(stampMoved, greaterThan(200));
      expect(swap, inInclusiveRange(80, 220));
      expect(months.length, 12);
    });

    test('a claim: sign for a good item; the right claim brings a replacement; the wrong claim and a claim on a good item are slips', () {
      final r = M7PpeRun(_dealOf(order: const [M7Item.shoes, M7Item.helmet, M7Item.gloves, M7Item.harness]));
      // Line 1: good shoes.
      expect(r.item, M7Item.shoes);
      expect(r.claim(M7Claim.replace), (M7Res.slip, Mk.needlessShoes));
      expect(r.claim(M7Claim.isMark), (M7Res.slip, Mk.needlessShoes));
      expect(r.slips, 2);
      expect(r.claim(M7Claim.sign), (M7Res.signed, null));
      expect(r.lineSettled, isTrue);
      expect(r.kitHas(M7Item.shoes), isTrue);
      expect(r.marks[M7Item.shoes], [M7Claim.replace, M7Claim.isMark, M7Claim.sign]);
      r.next();
      // Line 2: the cracked helmet (the stock item).
      expect(r.piece!.look, M7Look.cracked);
      expect(r.claim(M7Claim.size), (M7Res.slip, Mk.wrongClaim));
      expect(r.claim(M7Claim.sign), (M7Res.slip, Mk.signCrackedHelmet));
      expect(r.slips, 4);
      expect(r.piece!.look, M7Look.cracked, reason: 'the item is still on the mat');
      expect(r.stockHappened, isFalse);
      // The right claim on the stock item: out of stock (once).
      expect(r.claim(M7Claim.replace), (M7Res.stockOut, null));
      expect(r.awaitingStock, isTrue);
      expect(r.piece, isNull, reason: 'nothing on the mat while he looks');
      expect(r.stockOutcome(), isTrue);
      expect(r.piece!.look, M7Look.ok);
      expect(r.claim(M7Claim.sign), (M7Res.signed, null));
      expect(r.caught, [L.caughtClaim(M7Item.shoes, M7Claim.sign), L.caughtClaim(M7Item.helmet, M7Claim.replace), L.caughtClaim(M7Item.helmet, M7Claim.sign)]);
      r.next();
      // Line 3: torn gloves → replaced (not stock: gloves) → a lower type → rating → good.
      expect(r.piece!.look, M7Look.torn);
      expect(r.claim(M7Claim.replace), (M7Res.replaced, null));
      expect(r.piece!.look, M7Look.lowType, reason: 'a second fault on the same line');
      expect(r.claim(M7Claim.replace), (M7Res.slip, Mk.wrongClaim));
      expect(r.claim(M7Claim.rating), (M7Res.replaced, null));
      expect(r.piece!.look, M7Look.ok);
      expect(r.claim(M7Claim.sign), (M7Res.signed, null));
      r.next();
      // Line 4: the expired harness.
      expect(r.claim(M7Claim.replace), (M7Res.replaced, null));
      expect(r.claim(M7Claim.sign), (M7Res.signed, null));
      r.next();
      expect(r.atDocket, isTrue);
      expect(r.percent, 100 - 15 * r.slips);
      expect(r.passed, isFalse, reason: 'not done yet');
    });

    test('signing for a faulty item: each fault its own mistake; torn / lower-type gloves and cut webbing are deadly and end the play', () {
      const cases = <(M7Item, M7Look, DoMistake)>[
        (M7Item.helmet, M7Look.cracked, Mk.signCrackedHelmet),
        (M7Item.helmet, M7Look.noIs, Mk.signNoIsHelmet),
        (M7Item.helmet, M7Look.wrongIs, Mk.signWrongIsHelmet),
        (M7Item.helmet, M7Look.wrongSize, Mk.signWrongSize),
        (M7Item.shoes, M7Look.splitSole, Mk.signSplitShoes),
        (M7Item.shoes, M7Look.noIs, Mk.signNoIsShoes),
        (M7Item.shoes, M7Look.wrongIs, Mk.signWrongIsShoes),
        (M7Item.shoes, M7Look.wrongSize, Mk.signWrongSize),
        (M7Item.gloves, M7Look.torn, Mk.signTornGloves),
        (M7Item.gloves, M7Look.lowType, Mk.signLowGloves),
        (M7Item.harness, M7Look.cutWebbing, Mk.signCutHarness),
        (M7Item.harness, M7Look.expired, Mk.signExpiredHarness),
        (M7Item.harness, M7Look.newType, Mk.signNewHarness),
        (M7Item.harness, M7Look.wrongSize, Mk.signWrongSize),
      ];
      for (final (item, look, m) in cases) {
        final r = M7PpeRun(_dealOf(
          chains: {
            for (final i in M7Item.values) i: [_look(i, i == item ? look : M7Look.ok), if (i == item) M7Look.ok],
          },
          order: [item, ...M7Item.values.where((i) => i != item)],
        ));
        final res = r.claim(M7Claim.sign);
        expect(res.$2, m, reason: '$item $look');
        expect(m.deadly, m7DeadlySign(look), reason: '$item $look');
        expect(res.$1, m.deadly ? M7Res.deadly : M7Res.slip);
        expect(r.ended, m.deadly);
        expect(r.deadly, m.deadly ? m : isNull);
        expect(r.slips, m.deadly ? 0 : 1);
        if (m.deadly) {
          expect(r.claim(M7Claim.replace), (M7Res.already, null), reason: 'frozen: nothing more counts');
          expect(r.passed, isFalse);
        }
        // The right claim on the same item always works instead.
        final ok = M7PpeRun(_dealOf(
          chains: {
            for (final i in M7Item.values) i: [_look(i, i == item ? look : M7Look.ok), if (i == item) M7Look.ok],
          },
          stock: item == M7Item.gloves ? M7Item.helmet : item,
          order: [item, ...M7Item.values.where((i) => i != item)],
        ));
        expect(ok.claim(m7RightClaim(look)).$2, isNull, reason: '$item $look right claim');
        expect(ok.slips, 0);
      }
      expect({for (final e in cases.where((c) => c.$3.deadly)) e.$3.key}, hasLength(3));
      expect(m7RightClaim(M7Look.torn), M7Claim.replace);
      expect(m7RightClaim(M7Look.lowType), M7Claim.rating);
      expect(m7RightClaim(M7Look.wrongSize), M7Claim.size);
      expect(m7RightClaim(M7Look.newType), M7Claim.training);
      expect(m7RightClaim(M7Look.noIs), M7Claim.isMark);
      expect(m7RightClaim(M7Look.wrongIs), M7Claim.isMark);
      expect(m7RightClaim(M7Look.expired), M7Claim.replace);
    });

    test('the docket: a full valid kit goes; an item missing refuses; the other stamp is a slip; 11 kV without the rated gloves is deadly', () {
      M7PpeRun at({Set<M7Item> good = const {M7Item.helmet, M7Item.shoes, M7Item.gloves, M7Item.harness}, Set<M7Item> gone = const {}, M7Job job = M7Job.kv11}) {
        final r = M7PpeRun(_dealOf(job: job));
        r.debugAtDocket(good: good, gone: gone);
        return r;
      }

      // Full kit.
      var r = at();
      expect(r.docket(M7Docket.refuse), (M7Res.slip, Mk.refuseFull));
      expect(r.docket(M7Docket.go), (M7Res.signed, null));
      r.finishDocket();
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      expect(r.slips, 1);
      expect(r.percent, 85);
      expect(r.caught, [L.caughtGo]);
      // The helmet never found.
      r = at(good: {M7Item.shoes, M7Item.gloves, M7Item.harness}, gone: {M7Item.helmet});
      expect(r.anyMissing, isTrue);
      expect(r.docket(M7Docket.go), (M7Res.slip, Mk.goMissing));
      expect(r.docket(M7Docket.refuse), (M7Res.signed, null));
      expect(r.caught, [L.caughtRefuse]);
      // The gloves missing on an 11 kV job: going is deadly (a guard in the rules).
      r = at(good: {M7Item.helmet, M7Item.shoes, M7Item.harness}, gone: {M7Item.gloves});
      expect(r.docket(M7Docket.go), (M7Res.deadly, Mk.goNoGloves));
      expect(r.ended, isTrue);
      expect(r.docket(M7Docket.refuse), (M7Res.already, null));
      // On an LT job the same gap is a slip.
      r = at(job: M7Job.lt, good: {M7Item.helmet, M7Item.shoes, M7Item.harness}, gone: {M7Item.gloves});
      expect(r.docket(M7Docket.go), (M7Res.slip, Mk.goMissing));
      // Refusing with the rated gloves missing is right.
      r = at(good: {M7Item.helmet, M7Item.shoes, M7Item.harness}, gone: {M7Item.gloves});
      expect(r.docket(M7Docket.refuse), (M7Res.signed, null));
      // Before the docket nothing counts.
      expect(M7PpeRun(_dealOf()).docket(M7Docket.go), (M7Res.already, null));
    });

    test('the stock event: not found leaves the item missing and the line settled; the reason is asked once per question; listening is a slip', () {
      final r = M7PpeRun(_dealOf(found: false, order: const [M7Item.helmet, M7Item.shoes, M7Item.gloves, M7Item.harness]));
      expect(r.claim(M7Claim.replace), (M7Res.stockOut, null));
      expect(r.stockOutcome(), isFalse);
      expect(r.piece, isNull);
      expect(r.missing, {M7Item.helmet});
      expect(r.lineSettled, isTrue);
      expect(r.kitHas(M7Item.helmet), isFalse);
      // He comes once: a second right claim on another item is just a claim.
      r.next();
      expect(r.claim(M7Claim.sign), (M7Res.signed, null));
      expect(r.stockHappened, isTrue);
      expect(r.reasonDue(M7Why.replace), isTrue);
      expect(r.reasonDue(M7Why.replace), isFalse);
      expect(r.reasonDue(M7Why.sign), isTrue);
      expect(r.pushSlip(), Mk.pushListen);
      expect(Mk.pushListen.deadly, isFalse, reason: 'a market PPE push: a slip (B1/X2)');
      expect(r.slips, 1);
      expect(r.percent, 85);
      expect(M7PpeRun(_dealOf()).percent, 100);
    });

    test('mistakes: 4 deadly keys, the rest slips; keys, pictures, lesson points; every art file is used', () {
      expect(Mk.all.where((m) => m.deadly).map((m) => m.key).toSet(), {
        Mk.signTornGloves.key,
        Mk.signLowGloves.key,
        Mk.signCutHarness.key,
        Mk.goNoGloves.key,
      });
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.6/m7_ppe_counter_claim/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2), reason: 'lesson 7.6 has three points');
      }
      expect(Mk.wrongClaim.textBn, 'এটা তো সেই সমস্যা নয়।', reason: 'the wrong claim says only this');
      expect(Mk.pushListen.lessonPoint, isNull);
      for (final i in M7Item.values) {
        expect(Mk.needless(i).deadly, isFalse);
      }
      const dir = 'assets/game/art/m7_ppe_counter_claim/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7PpePacks.keys, ['do_7_6_a']);
    });

    test('the live lesson (X3): IS 4770 টাইপ ৪, the IS codes, the duties and the myth word for word', () {
      final lesson = _lesson();
      final text = _nk(jsonEncode(lesson));
      // The 11 kV glove is the type-4 glove, never "11 kV গ্লাভস".
      expect(text, contains(_nk('IS 4770 টাইপ ৪')));
      expect(text, contains(_nk('১৭,০০০ ভোল্ট পর্যন্ত')));
      expect(m7GloveCuff(M7Look.ok, M7Job.kv11), 'IS 4770 · টাইপ 4');
      expect(m7GloveCuff(M7Look.lowType, M7Job.kv11), isNot('IS 4770 · টাইপ 4'));
      expect(m7GloveCuff(M7Look.ok, M7Job.lt), 'IS 4770');
      expect(L.kitList(M7Job.kv11)[2], contains('IS 4770 · টাইপ 4'));
      expect(L.kitList(M7Job.lt)[2], L.itemName(M7Item.gloves));
      expect(m7IsPrint(M7Item.helmet, M7Look.ok), 'IS 2925');
      expect(m7IsPrint(M7Item.shoes, M7Look.ok), 'IS 15298');
      expect(m7IsPrint(M7Item.helmet, M7Look.wrongIs), 'IS 15298');
      expect(m7IsPrint(M7Item.shoes, M7Look.wrongIs), 'IS 2925');
      expect(m7IsPrint(M7Item.helmet, M7Look.noIs), isNull);
      expect(text, contains('সেফটি হেলমেটের জন্য IS 2925 বা সেফটি জুতোর জন্য IS 15298'));
      for (final bn in [
        'ক্ষতিগ্রস্ত বা মেয়াদ উত্তীর্ণ PPE বদলে দেওয়ার ব্যবস্থা করা',
        'ভুল সাইজের PPE সুরক্ষার বদলে অসুবিধার কারণ হতে পারে',
        'সঠিক প্রশিক্ষণের দাবি জানান',
        'আপনার কাজটি করতে অস্বীকার করার সম্পূর্ণ অধিকার আছে',
        'আপনাকে নিজের টাকা দিয়ে কাজের জন্য হেলমেট বা গ্লাভস কিনতে বলাটা বেআইনি',
      ]) {
        expect(text, contains(_nk(bn)));
      }
      // Never the old spec wording.
      final all = [...L.spokenLines, ...L.kitList(M7Job.kv11), ...L.allWhyRight, ...L.allWhyWrong];
      for (final l in all) {
        expect(l.contains('11 kV গ্লাভস'), isFalse, reason: l);
        expect(l.contains('রেটেড'), isFalse, reason: l);
      }
      // The coworker's push is lesson myth 1 word for word + his ask (M7-10).
      final myths = ((lesson['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      final myth = _nk((myths[0] as Map)['myth'] as String);
      expect(_nk(L.coworker.line), startsWith(myth));
      expect(_nk(L.coworker.line), endsWith(_nk('তুইও কিনে নে।')));
      expect(_nk(Mk.pushListen.textBn), contains(_nk('সুরক্ষার মিথ্যা আশ্বাস দেয় মাত্র')));
      expect(text, contains(_nk('সুরক্ষার মিথ্যা আশ্বাস দেয় মাত্র')));
      // The stamps are the six claims; the lesson's duties back each.
      expect([for (final c in M7Claim.values) L.stampLabel(c)], ['সই করে নিলাম', 'বদলে দিন', 'IS মার্ক চাই', 'ঝুঁকি মতো রেটিং চাই', 'ঠিক সাইজ চাই', 'আগে প্রশিক্ষণ চাই']);
      expect([for (final d in M7Docket.values) L.docketStamp(d)], ['কাজে যাচ্ছি', 'PPE ছাড়া এই কাজ নয়']);
      expect(L.jobLine(M7Job.kv11), '11 kV লাইনের কাজ · পোলে ওঠা');
      expect(L.jobLine(M7Job.lt), 'LT সার্ভিস লাইন · পোলে ওঠা');
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ"; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.docketTasks,
        ...L.tapWhy,
        ...L.storekeeperLines,
        for (final w in M7Why.values) ...[L.whyQ(w), ...L.whyWrong(w), ...L.whyRight[w]!],
        for (final i in M7Item.values) L.itemName(i),
        for (final c in M7Claim.values) L.stampLabel(c),
        for (final d in M7Docket.values) L.docketStamp(d),
        ...L.kitList(M7Job.kv11),
        ...L.kitList(M7Job.lt),
        L.jobLine(M7Job.kv11),
        L.jobLine(M7Job.lt),
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.registerWord,
        L.caughtGo,
        L.caughtRefuse,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l); // the word, not কোম্পানি
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expectSameLength('why', [...L.allWhyRight, ...L.allWhyWrong]);
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.whyWrong(w));
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.whyWrong(w), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
      // The six stamps read about the same length (nothing stands out).
      expectSameLength('stamps', [for (final c in M7Claim.values) L.stampLabel(c)], ratio: 2.5);
      expectSameLength('docket stamps', [for (final d in M7Docket.values) L.docketStamp(d)], ratio: 1.6);
    });

    test('spoken lines: his exit is recorded; his push, the storekeeper\'s and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['কোম্পানি ভালো PPE দেয় না, তাই আমি বাজার থেকে সস্তার একটা কিনে ব্যবহার করি। তুইও কিনে নে।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
        L.newGuideLines,
        containsAll([
          L.intro,
          ...L.tasks,
          L.askDocket,
          ...L.storekeeperLines,
          for (final w in M7Why.values) L.whyQ(w),
          L.callHeld,
          L.allSet,
          L.fail,
          'ওর কথা শুনবেন?',
          for (final m in Mk.all) m.textBn,
        ]),
      );
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      expect(L.storeNoStock, 'এটার স্টক এখন নেই।');
      // Every line the page speaks is in one of the lists.
      final spoken = L.spokenLines.toSet();
      for (final l in [
        L.intro,
        ...L.tasks,
        ...L.docketTasks,
        ...L.tapWhy,
        ...L.storekeeperLines,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.coworker.line,
        L.coworkerExit,
        ...L.coworker.asks,
        for (final w in M7Why.values) L.whyQ(w),
        for (final m in Mk.all) m.textBn,
      ]) {
        expect(spoken, contains(l), reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_ppe_counter_claim: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: mat, trainee, docket, register, tray clear of each other, the guide and his bubble; lines and stamps found by touch', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M7PpeGeo.forScene(h, inset);
          expect(g.stand.bottom, lessThanOrEqualTo(h));
          final guide = Rect.fromLTRB(244, g.standTop - 118, 360, g.standTop);
          final parts = {'mat': g.mat, 'trainee': g.trainee, 'docket': g.docket, 'register': g.register, 'tray': g.tray};
          for (final e in parts.entries) {
            expect(e.value.left, greaterThanOrEqualTo(0), reason: '${e.key} h $h');
            expect(e.value.right, lessThanOrEqualTo(360), reason: '${e.key} h $h');
            expect(e.value.top, greaterThanOrEqualTo(e.key == 'tray' ? 124 : 140), reason: '${e.key} h $h below the header');
            expect(e.value.overlaps(g.bubble), isFalse, reason: '${e.key} h $h under his bubble');
            expect(e.value.overlaps(guide), isFalse, reason: '${e.key} h $h under the guide');
            expect(e.value.overlaps(g.stand), isFalse, reason: '${e.key} h $h');
          }
          expect(g.mat.overlaps(g.trainee), isFalse);
          expect(g.mat.overlaps(g.docket), isFalse);
          expect(g.trainee.overlaps(g.register), isFalse);
          expect(g.trainee.overlaps(g.tray), isFalse);
          expect(g.docket.overlaps(g.register), isFalse);
          expect(g.docket.overlaps(g.tray), isFalse);
          expect(g.register.overlaps(g.tray), isFalse);
          expect(g.trayArt.overlaps(g.trayClose), isFalse);
          expect(g.tray.contains(g.trayArt.topLeft) && g.tray.contains(g.trayArt.bottomRight - const Offset(1, 1)), isTrue);
          expect(g.item.size.width, greaterThan(120));
          for (var i = 0; i < 6; i++) {
            expect(g.stand.contains(g.stamp(i).topLeft) && g.stand.contains(g.stamp(i).bottomRight - const Offset(1, 1)), isTrue);
            expect(g.stamp(i).size.width, greaterThanOrEqualTo(48));
            for (var j = i + 1; j < 6; j++) {
              expect(g.stamp(i).overlaps(g.stamp(j)), isFalse);
            }
          }
          expect(g.docketStamp(0).overlaps(g.docketStamp(1)), isFalse);
          for (var k = 0; k < 4; k++) {
            expect(g.register.contains(g.line(k).topLeft) && g.register.contains(g.line(k).bottomRight - const Offset(1, 1)), isTrue);
            expect(g.lineAt(g.line(k).center.translate(5, 0)), k);
            if (k > 0) expect(g.line(k).top, g.line(k - 1).bottom);
          }
          expect(g.lineAt(const Offset(180, 300)), isNull);
          expect(g.lineAt(g.line(0).center.translate(-110, 0)), isNull, reason: 'left of the page');
          for (var i = 0; i < 6; i++) {
            expect(g.stampAt(g.stamp(i).center, docketPhase: false), i);
          }
          expect(g.stampAt(g.stamp(0).center, docketPhase: true), isNull);
          expect(g.stampAt(g.docketStamp(1).center, docketPhase: true), 1);
          if (h >= 780) expect(g.calendar.top, greaterThan(140));
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

    testWidgets('the guide comes first: a tap does not skip him; then the six stamps, the register and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M7PpeCounterClaimPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1800);
      for (final c in M7Claim.values) {
        expect(_label(L.stampLabel(c)), findsOneWidget, reason: 'all six, always');
      }
      expect(_label(L.registerWord), findsOneWidget);
      expect(_label(L.docketWord), findsOneWidget);
      expect(find.textContaining(L.jobLine(M7Job.kv11)).evaluate().length + find.textContaining(L.jobLine(M7Job.lt)).evaluate().length, 1);
      expect(find.textContaining('বাকি'), findsNothing, reason: 'no "left" counter');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the task pool in turn, never a claim or a fault', (t) async {
      final c = await _open(t, 5);
      expect(c.read(guideDirectorProvider).line, contains(L.askLook));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.askWrite, L.tapKit, L.askLook]);
      await _close(t, c);
    });

    // A stock item that is found, and one that is not; an 11 kV job and an LT one.
    final flowSeeds = [
      _seedWhere((d) => d.found != null && d.job == M7Job.kv11 && d.faulty.length == 3),
      _seedWhere((d) => d.found == null && d.job == M7Job.lt),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): four items, stamps held, the tray, reasons, he is refused, the docket → pass', (t) async {
        final c = await _open(t, seed);
        // The tray and a try-on once, for free.
        final first = _live.piece!;
        await t.tapAt(_geo.item.center * _k);
        await _pump(t, 400);
        expect(find.byKey(ValueKey('tray-${first.id}')), findsOneWidget);
        final g = await t.startGesture(_geo.trayArt.center * _k);
        for (var i = 1; i <= 8; i++) {
          await g.moveTo(Offset.lerp(_geo.trayArt.center, _geo.trainee.center, i / 8)! * _k);
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await _pump(t, 300);
        expect(find.byKey(ValueKey('tryon-${first.id}')), findsOneWidget, reason: 'the try-on on the trainee');
        expect(_live.slips, 0);
        await t.tapAt(_geo.trayClose.center * _k);
        await _pump(t, 400);
        expect(find.byKey(ValueKey('tray-${first.id}')), findsNothing);
        await _toDocket(t);
        final missing = _live.anyMissing;
        expect(missing, seed == flowSeeds.last, reason: 'the shelf had one / had none');
        await _docketStamp(t, missing ? M7Docket.refuse : M7Docket.go);
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the docket reason');
        await _pump(t, 500);
        await _pickRight(t, L.whyRight[missing ? M7Why.refuse : M7Why.go]!);
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.6/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.6/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(_live.slips, 0);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final cleanFirst = _seedWhere((d) => d.chains[d.order.first]!.first.look == M7Look.ok);
    testWidgets('a needless claim and a wrong claim are slips with their cards; the line stays; a stamp let go early or on another line costs nothing', (t) async {
      final c = await _open(t, cleanFirst);
      final it = _live.item!;
      // Let go before the ink took; and a hold on the wrong line.
      await _stamp(t, M7Claim.sign, holdMs: 200);
      expect(_live.marks[it], isEmpty, reason: 'sprang back');
      expect(find.byType(MistakeCard), findsNothing);
      await _stamp(t, M7Claim.sign, line: (_live.index + 1) % 4);
      expect(_live.marks[it], isEmpty);
      expect(_live.marks[M7Item.values.firstWhere((i) => i != it && _live.deal.order.indexOf(i) == (_live.index + 1) % 4)], isEmpty);
      expect(_live.slips, 0);
      // A claim on a good item.
      await _stamp(t, M7Claim.replace);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.needless(it).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 0, reason: 'the same line');
      // The right claim goes through (with the reason).
      await _stamp(t, M7Claim.sign);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M7Why.sign]!);
      await _pump(t, 2800);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.needless(it).key]);
      expect(find.byType(FreezeFrame), findsNothing);
      // The next item: a wrong claim shows only the one line.
      final p = _live.piece!;
      if (p.look != M7Look.ok) {
        final wrong = M7Claim.values.firstWhere((x) => x != m7RightClaim(p.look));
        await _stamp(t, wrong);
        expect(find.text(Mk.wrongClaim.textBn), findsOneWidget);
        expect(_live.piece, p, reason: 'still on the mat');
      }
      await _close(t, c);
    });

    final deadlyFirst = _seedWhere((d) => m7DeadlySign(d.chains[d.order.first]!.first.look));
    testWidgets('signing for a deadly item freezes the scene grey, then the near-miss or death card; nothing else counts', (t) async {
      final c = await _open(t, deadlyFirst);
      final p = _live.piece!;
      await _stamp(t, M7Claim.sign);
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the freeze first');
      expect(find.byType(MistakeCard), findsNothing, reason: 'the card comes after it');
      // The frozen scene takes no touch.
      await _stamp(t, M7Claim.replace, holdMs: 700);
      expect(_live.deadly, Mk.sign(p.item, p.look));
      expect(_live.slips, 0);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.sign(p.item, p.look).textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.last.key, Mk.sign(p.item, p.look).key);
      expect(s.mistakes.last.deadly, isTrue);
      expect(s.rungProgress['7.6/do/0'], isNot('cleared'));
      expect(find.byType(LevelPassPanel), findsNothing);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (needless claims)', (t) async {
      final c = await _open(t, cleanFirst);
      for (var i = 0; i < 3; i++) {
        await _stamp(t, M7Claim.replace);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'a slip, not a deadly');
      await _close(t, c);
    });

    final stockFirst = _seedWhere((d) => d.order.first == d.stockItem);
    testWidgets('the stock event: "no stock" calls him in; the stamps wait for him; listening = a slip (no freeze); then the search goes on', (t) async {
      final c = await _open(t, stockFirst);
      final it = _live.item!;
      expect(it, _deal.stockItem);
      final claim = m7RightClaim(_live.piece!.look);
      await _stamp(t, claim);
      if (find.byType(ChoiceDeck).evaluate().isNotEmpty) {
        await _pickRight(t, L.whyRight[m7WhyOf(claim)]!);
        await _pump(t, 1500);
      }
      expect(_live.awaitingStock, isTrue);
      expect(c.read(guideDirectorProvider).line, contains(L.storeNoStock));
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not at once');
      // Lift a stamp before he came: he cuts in, the stamp is not lifted.
      final marks = _live.marks[it]!.length;
      final g = await t.startGesture(_geo.stamp(0).center * _k);
      await g.moveBy(const Offset(0, -30));
      await _pump(t, 200);
      await g.up();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the stamps wait for him');
      expect(_live.marks[it]!.length, marks);
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
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 3200);
      expect(_live.awaitingStock, isFalse, reason: 'the storekeeper went to the back shelf');
      expect(find.byType(CoworkerPeek), findsNothing);
      await _close(t, c);
    });

    testWidgets('the docket: "কাজে যাচ্ছি" with an item missing and "PPE ছাড়া এই কাজ নয়" with a full kit are slips', (t) async {
      final missingSeed = _seedWhere((d) => d.found == null);
      var c = await _open(t, missingSeed);
      await _toDocket(t);
      expect(_live.anyMissing, isTrue);
      await _docketStamp(t, M7Docket.go);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.goMissing.textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.atDocket, isTrue);
      await _close(t, c);

      final fullSeed = _seedWhere((d) => d.found != null);
      c = await _open(t, fullSeed);
      await _toDocket(t);
      expect(_live.anyMissing, isFalse);
      await _docketStamp(t, M7Docket.refuse);
      expect(find.text(Mk.refuseFull.textBn), findsOneWidget);
      expect(_live.slips, 1);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the line goes on', (t) async {
      final c = await _open(t, cleanFirst);
      final it = _live.item!;
      await _stamp(t, M7Claim.sign);
      expect(_live.marks[it], [M7Claim.sign]);
      // At once: another stamp does nothing (shielded, then the deck).
      await _stampTo(t, _deal.stampOrder.indexOf(M7Claim.replace), _geo.line(0).center, holdMs: 700);
      expect(_live.marks[it], [M7Claim.sign]);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[M7Why.sign]!);
      await _pump(t, 2800);
      expect(_live.index, 1);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the tray: tap opens it, ✕ closes it; nothing is claimed; a stamp lifted closes it', (t) async {
      final c = await _open(t, 7);
      await t.tapAt(_geo.item.center * _k);
      await _pump(t, 400);
      expect(find.byKey(ValueKey('tray-${_live.piece!.id}')), findsOneWidget);
      await t.tapAt(const Offset(30, 780) * _k);
      await _pump(t, 100);
      expect(find.byKey(ValueKey('tray-${_live.piece!.id}')), findsNothing, reason: 'a tap outside closes it');
      await t.tapAt(_geo.item.center * _k);
      await _pump(t, 400);
      await t.tapAt(_geo.trayClose.center * _k);
      await _pump(t, 400);
      expect(find.byKey(ValueKey('tray-${_live.piece!.id}')), findsNothing);
      expect(_live.slips, 0);
      expect(_live.marks.values.expand((e) => e), isEmpty);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle → a tap on the item (only item), then a sweep over the stamps; with the tray open a sweep; it hides while a stamp is held', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 11);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with an item on the mat');
      await _pump(t, 6000);
      await t.tapAt(_geo.item.center * _k);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'the tray is open and waiting');
      expect(scene().debugOptions, hasLength(2), reason: 'a sweep across the item (its two halves)');
      await t.tapAt(_geo.trayClose.center * _k);
      await _pump(t, 400);
      final g = await t.startGesture(_geo.stamp(2).center * _k);
      await _pump(t, 900);
      expect(scene().showing, isFalse);
      await g.up();
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _close(t, c);
    });
  });
}

M7Look _look(M7Item i, M7Look l) => l;
