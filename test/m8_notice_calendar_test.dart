// Lesson 8.2 (সাপ্লাই কোড), কাজ "দিন গুনুন, তারপর কাটুন": the rules (the
// notice needs 15 clear days in writing; no notice or fewer days = hold;
// dues + reconnection charge = reconnect; 180 days unpaid = dismantle; every
// mistake a slip, ruling M8-1), the deal (3 of 6 houses, an act and a hold,
// dates inside the calendars, never a count at 13-17 or 175-185 days), the
// live lesson lines (X3), the libraries, every spoken line listed, the drawn
// places, and the level in the shell: the guide first, full clean plays (the
// ribbon dragged, a tile opened big and confirmed, the receipt, the notebook,
// the hold, the crate, a reason pick, the coworker refused), a wrong tile that
// resolves after its card, the notebook and crate slips, three slips, no
// freeze (nothing here is deadly), the tiles wait for the coworker, and the
// gesture hand showing how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m8_notice_calendar.dart';
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
  rungId: '8.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8NoticeCalendarPacks['do_8_2_a']!;
typedef L = M8NoticeLines;
typedef Mk = M8NoticeMistakes;

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

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M8Geo get _geo => M8Geo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M8NoticeRun get _live => M8NoticeProbe.run!;
M8House get _house => _live.house;

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8NoticeCalendarPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8Deal d) ok) => [for (var s = 0; s < 6000; s++) s].firstWhere((s) => ok(m8DealPlay(math.Random(s))));

// --- driving the scene ------------------------------------------------------------
Future<void> _tapDesign(WidgetTester t, Offset p, {int settle = 400}) async {
  await t.tapAt(p * _k);
  await _pump(t, settle);
}

Future<void> _openDocket(WidgetTester t) async {
  await _tapDesign(t, _geo.closedDocket.center, settle: 500);
  expect(M8NoticeProbe.stage, 'measure');
}

/// The date a clean player counts from at [h].
DateTime _startOf(M8House h) => switch (h.kind) {
      M8Kind.shortNotice || M8Kind.longNotice => h.notice!,
      M8Kind.noNotice => h.bill,
      _ => h.cut!,
    };

/// Drag the ribbon from [from]'s cell to 'আজ'.
Future<void> _ribbon(WidgetTester t, DateTime from, {Offset? endAt, bool settle = true}) async {
  final a = _geo.dateRect(_house, from)!.center;
  final b = endAt ?? _geo.todayRect(_house).center;
  final g = await t.startGesture(a * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(a, b, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, settle ? 300 : 60);
}

Finder _tile(M8Tile tile) => _label(L.tile(tile));

Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworkerFor(_house.kind).right);
  await _pump(t, 2600);
}

/// Tap a tile → its preview → ✓ (his house: he is refused first).
Future<void> _choose(WidgetTester t, M8Tile tile) async {
  await t.tap(_tile(tile), warnIfMissed: false);
  await _pump(t, 500);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    await _refuse(t);
    await t.tap(_tile(tile), warnIfMissed: false);
    await _pump(t, 500);
  }
  expect(await confirmChoice(t), isTrue, reason: 'the tile opened big');
  await _pump(t, 500);
}

Future<void> _setWheels(WidgetTester t, List<int> digits) async {
  for (var i = 0; i < 5; i++) {
    final r = _geo.wheel(i);
    for (var n = 0; n < digits[i]; n++) {
      await t.tapAt(Offset(r.center.dx, r.bottom - 8) * _k);
      await t.pump(const Duration(milliseconds: 30));
    }
  }
  await _pump(t, 200);
}

Future<void> _chip(WidgetTester t, bool intact) async {
  await _tapDesign(t, (intact ? _geo.chipOk : _geo.chipBroken).center, settle: 200);
}

Future<void> _holdDisc(WidgetTester t, {int ms = 1500}) async {
  final g = await t.startGesture(_geo.discBtn.center * _k);
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

Future<void> _drag(WidgetTester t, Offset from, Offset to) async {
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

int get _crateSide => _live.deal.crateLeft[_live.index] ? 0 : 1;

/// A house done the clean way (the coworker refused if he cuts in; the reason
/// picked if due). [reasons] = the reason decks already asked.
Future<void> _playHouse(WidgetTester t) async {
  final i = _live.index;
  final h = _house;
  final why = _live.why;
  final asked = _live.asked.contains(why);
  await _openDocket(t);
  await _ribbon(t, _startOf(h));
  expect(M8NoticeProbe.measured, isTrue);
  expect(M8NoticeProbe.count, h.today.difference(_startOf(h)).inDays);
  final tile = h.answer;
  if (tile == M8Tile.reconnect && h.hasReceipt) {
    await t.tap(_tile(tile), warnIfMissed: false);
    await _pump(t, 500);
    if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
      await _refuse(t);
      await t.tap(_tile(tile), warnIfMissed: false);
      await _pump(t, 500);
    }
    expect(find.byKey(const ValueKey('receipt-card')), findsOneWidget, reason: 'the receipt opens first');
    await _tapDesign(t, const Offset(180, 220));
    expect(find.byKey(const ValueKey('receipt-card')), findsNothing);
  }
  await t.tap(_tile(tile), warnIfMissed: false);
  await _pump(t, 500);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_live.index, i);
    expect(find.byType(CardPreviewOverlay), findsNothing, reason: 'the tiles wait for him');
    await _refuse(t);
    await t.tap(_tile(tile), warnIfMissed: false);
    await _pump(t, 500);
  }
  expect(await confirmChoice(t), isTrue);
  await _pump(t, 500);
  if (tile == M8Tile.cut) {
    expect(M8NoticeProbe.stage, 'note');
    await _setWheels(t, h.meter);
    await _chip(t, h.sealIntact);
    await _tapDesign(t, _geo.noteBtn.center);
    expect(M8NoticeProbe.noted, isTrue);
    expect(find.byType(MistakeCard), findsNothing);
    await _holdDisc(t);
    await _pump(t, 1000);
  } else if (tile == M8Tile.dismantle) {
    expect(M8NoticeProbe.stage, 'crate');
    final crate = _geo.pad(_crateSide).center;
    await _drag(t, _geo.meterItem.center, crate);
    await _drag(t, _geo.coilItem.center, crate);
    await _pump(t, 600);
  }
  if (asked) {
    await _pump(t, 2800);
  } else {
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck ($why)');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[why]!);
    await _pump(t, 2800);
  }
  if (!_live.done) expect(_live.index, i + 1);
}

void main() {
  group('rules', () {
    test('deals: 3 of 6 houses, an act and a hold, dates inside the calendars, no count at 13–17 or 175–185 days, the bill date earlier, plays differ', () {
      final seen = <String>{};
      final kinds = <M8Kind>{};
      final his = <M8Kind>{};
      final receipts = <M8Receipt>{};
      final lights = <int>{};
      var crateLeft = 0, billOvershoot = 0, noticeFirst = 0;
      for (var s = 0; s < 400; s++) {
        final d = m8DealPlay(math.Random(s));
        expect(d.houses, hasLength(3));
        expect(d.houses.map((h) => h.kind).toSet(), hasLength(3), reason: 'three different houses');
        expect(d.houses.any((h) => m8IsAct(h.kind)), isTrue, reason: 'an act');
        expect(d.houses.any((h) => !m8IsAct(h.kind)), isTrue, reason: 'a hold');
        expect(d.houses.where((h) => h.live).length + d.houses.where((h) => !h.live).length, 3);
        expect(d.hisHouse, inInclusiveRange(0, 2));
        final hk = d.houses[d.hisHouse].kind;
        expect([M8Kind.shortNotice, M8Kind.noNotice, M8Kind.recentCut, M8Kind.paidCut], contains(hk));
        his.add(hk);
        lights.add(d.light);
        for (var i = 0; i < 3; i++) {
          final h = d.houses[i];
          kinds.add(h.kind);
          receipts.add(h.receipt);
          if (d.crateLeft[i]) crateLeft++;
          expect(d.tileOrder[i].toSet(), h.tiles.toSet());
          expect(d.tileOrder[i], hasLength(h.tiles.length));
          expect(h.tiles.length, h.live ? 2 : 3);
          expect(h.meter, hasLength(5));
          expect(h.meter.every((x) => x >= 0 && x <= 9), isTrue);
          // Every docket date sits inside the calendar the house uses.
          final geo = M8Geo.forScene(780, 0);
          for (final dt in [...h.docketDates, h.today]) {
            expect(geo.dateRect(h, dt), isNotNull, reason: '${h.kind} ${m8DateText(dt)} inside the ${h.planner ? 'planner' : 'grid'}');
            expect(dt.isAfter(h.today), isFalse);
          }
          expect(h.docketDates.toSet(), hasLength(h.docketDates.length), reason: 'dates differ');
          // The counts a player can make avoid the unclear days.
          for (final dt in h.docketDates) {
            final n = h.daysAgo(dt);
            expect(n >= 13 && n <= 17, isFalse, reason: '${h.kind}: $n days');
            expect(n >= 175 && n <= 185, isFalse, reason: '${h.kind}: $n days');
          }
          expect(h.bill.isBefore(h.notice ?? h.today), isTrue, reason: 'the bill date is earlier than the notice');
          expect(h.order.toSet(), hasLength(h.order.length));
          expect(h.order, hasLength(h.live ? 3 : 4));
          switch (h.kind) {
            case M8Kind.shortNotice:
              expect(h.daysAgo(h.notice!), inInclusiveRange(3, 10));
              expect(h.daysAgo(h.bill), greaterThanOrEqualTo(18), reason: 'a count from the bill date overshoots');
              billOvershoot++;
            case M8Kind.longNotice:
              expect(h.daysAgo(h.notice!), inInclusiveRange(20, 40));
            case M8Kind.noNotice:
              expect(h.notice, isNull);
              expect(h.order, contains(M8Label.spoken));
              expect(h.daysAgo(h.bill), greaterThan(15), reason: 'a count from the bill date looks like enough');
            case M8Kind.recentCut:
              expect(h.daysAgo(h.cut!), inInclusiveRange(40, 120));
              expect(h.receipt, isNot(M8Receipt.full));
            case M8Kind.oldCut:
              expect(h.daysAgo(h.cut!), inInclusiveRange(200, 290));
              expect(h.receipt, M8Receipt.none);
            case M8Kind.paidCut:
              expect(h.daysAgo(h.cut!), lessThan(175));
              expect(h.receipt, M8Receipt.full);
              expect(h.paid, h.due);
          }
          if (h.receipt == M8Receipt.part) expect(h.paid, lessThan(h.due));
          if (h.receipt == M8Receipt.none) expect(h.paid, 0);
          if (h.order.first == M8Label.notice || h.order.first == M8Label.spoken) noticeFirst++;
        }
        seen.add('${d.today}${d.hisHouse}${d.light}|${d.houses.map((h) => '${h.kind.index}${h.docketDates.map((x) => x.millisecondsSinceEpoch).join(',')}${h.meter.join()}${h.sealIntact}').join('|')}');
      }
      expect(seen.length, greaterThan(390));
      expect(kinds, M8Kind.values.toSet());
      expect(his, {M8Kind.shortNotice, M8Kind.noNotice, M8Kind.recentCut, M8Kind.paidCut});
      expect(receipts, M8Receipt.values.toSet());
      expect(lights, hasLength(kM8Skies.length));
      expect(crateLeft, inInclusiveRange(400, 800), reason: 'the crate stands on either side');
      expect(billOvershoot, greaterThan(20));
      expect(noticeFirst, greaterThan(100), reason: 'the dates come in a dealt order');
    });

    test('the right answer: written notice 15+ days → cut; no notice or short → hold; paid in full → reconnect; 180+ days unpaid → dismantle; other cut lines hold', () {
      final rng = math.Random(7);
      final today = DateTime.utc(2026, 7, 20);
      for (var n = 0; n < 60; n++) {
        for (final k in M8Kind.values) {
          final h = m8DealHouse(k, today, rng);
          final want = switch (k) {
            M8Kind.longNotice => M8Tile.cut,
            M8Kind.oldCut => M8Tile.dismantle,
            M8Kind.paidCut => M8Tile.reconnect,
            _ => M8Tile.hold,
          };
          expect(h.answer, want, reason: '$k');
          expect(m8IsAct(k), want != M8Tile.hold);
          // The same rule from the dates and the receipt.
          if (h.live) {
            final cut = h.notice != null && h.daysAgo(h.notice!) >= 15;
            expect(h.answer, cut ? M8Tile.cut : M8Tile.hold);
          } else if (h.receipt == M8Receipt.full) {
            expect(h.answer, M8Tile.reconnect);
          } else {
            expect(h.answer, h.daysAgo(h.cut!) >= 180 ? M8Tile.dismantle : M8Tile.hold);
          }
        }
      }
    });

    test('a decision: right goes on; every wrong tile is a slip with its own card', () {
      DoMistake? slipOf(M8Kind k, M8Tile t, {M8Receipt? receipt}) {
        final base = m8DealHouse(k, DateTime.utc(2026, 7, 20), math.Random(k.index + 3));
        final h = receipt == null
            ? base
            : M8House(
                kind: base.kind,
                today: base.today,
                bill: base.bill,
                reading: base.reading,
                order: base.order,
                meter: base.meter,
                sealIntact: base.sealIntact,
                notice: base.notice,
                cut: base.cut,
                receipt: receipt,
                due: base.due,
                paid: base.paid,
              );
        final run = M8NoticeRun(M8Deal(today: h.today, houses: [h, h, h], hisHouse: 0, crateLeft: const [true, true, true], tileOrder: [h.tiles, h.tiles, h.tiles], noteWhy: const [false, false, false], light: 0));
        final (ok, m) = run.decide(t);
        expect(ok, t == h.answer);
        expect(run.slips, ok ? 0 : 1);
        expect(m == null, ok);
        return m;
      }

      expect(slipOf(M8Kind.longNotice, M8Tile.cut), isNull);
      expect(slipOf(M8Kind.longNotice, M8Tile.hold), Mk.holdCut, reason: 'a needless hold on a valid cut');
      expect(slipOf(M8Kind.noNotice, M8Tile.cut), Mk.cutNoNotice);
      expect(slipOf(M8Kind.shortNotice, M8Tile.cut), Mk.cutShort);
      expect(slipOf(M8Kind.noNotice, M8Tile.hold), isNull);
      expect(slipOf(M8Kind.shortNotice, M8Tile.hold), isNull);
      expect(slipOf(M8Kind.paidCut, M8Tile.reconnect), isNull);
      expect(slipOf(M8Kind.paidCut, M8Tile.hold), Mk.holdReconnect);
      expect(slipOf(M8Kind.paidCut, M8Tile.dismantle), Mk.dismantlePaid);
      expect(slipOf(M8Kind.recentCut, M8Tile.hold), isNull);
      expect(slipOf(M8Kind.recentCut, M8Tile.reconnect, receipt: M8Receipt.part), Mk.reconnectPart);
      expect(slipOf(M8Kind.recentCut, M8Tile.reconnect, receipt: M8Receipt.chargeBlank), Mk.reconnectNoCharge);
      expect(slipOf(M8Kind.recentCut, M8Tile.reconnect, receipt: M8Receipt.none), Mk.reconnectNoPay);
      expect(slipOf(M8Kind.recentCut, M8Tile.dismantle), Mk.dismantleEarly);
      expect(slipOf(M8Kind.oldCut, M8Tile.dismantle), isNull);
      expect(slipOf(M8Kind.oldCut, M8Tile.hold), Mk.holdDismantle);
      expect(slipOf(M8Kind.oldCut, M8Tile.reconnect), Mk.reconnectNoPay);
    });

    test('the notebook: wrong digits and a wrong seal are a slip each; the right entries none; the hold with no note has its card', () {
      final h = m8DealHouse(M8Kind.longNotice, DateTime.utc(2026, 7, 20), math.Random(5));
      final run = M8NoticeRun(M8Deal(today: h.today, houses: [h, h, h], hisHouse: 0, crateLeft: const [true, true, true], tileOrder: [h.tiles, h.tiles, h.tiles], noteWhy: const [false, true, false], light: 0));
      expect(run.checkNote(h.meter, h.sealIntact), isEmpty);
      expect(run.slips, 0);
      final bad = [...h.meter]..[2] = (h.meter[2] + 1) % 10;
      expect(run.checkNote(bad, h.sealIntact), [Mk.noteReading]);
      expect(run.checkNote(h.meter, !h.sealIntact), [Mk.noteSeal]);
      expect(run.checkNote(bad, !h.sealIntact), [Mk.noteReading, Mk.noteSeal]);
      expect(run.slips, 4);
      expect(run.noNoteSlip(), Mk.noNote);
      expect(run.crateSlip(), Mk.crateWrong);
      expect(run.pushSlip(), Mk.pushMeter, reason: 'the long-notice house is not his; the script falls to the meter myth');
      expect(run.percent, 100 - 15 * 7 < 0 ? 0 : 100 - 15 * 7);
      // The cut house asks the cut or the note, dealt.
      expect(run.why, M8Why.cut);
      run.next();
      expect(run.why, M8Why.note);
      expect(run.reasonDue(M8Why.note), isTrue);
      expect(run.reasonDue(M8Why.note), isFalse, reason: 'a repeat pays at once');
      run.finishHouse();
      expect(run.caught.single, L.caught(M8Kind.longNotice));
    });

    test('every kind asks a reason that fits what was done', () {
      final today = DateTime.utc(2026, 7, 20);
      final rng = math.Random(11);
      for (var n = 0; n < 40; n++) {
        for (final k in M8Kind.values) {
          final h = m8DealHouse(k, today, rng);
          final w = m8WhyFor(h, noteWhy: n.isEven);
          expect(L.whyQ[w], isNotNull);
          expect(L.whyRight[w], hasLength(2));
          switch (k) {
            case M8Kind.shortNotice:
              expect(w, M8Why.holdShort);
            case M8Kind.noNotice:
              expect(w, M8Why.holdNoNotice);
            case M8Kind.longNotice:
              expect(w, n.isEven ? M8Why.note : M8Why.cut);
            case M8Kind.recentCut:
              expect(w, h.receipt == M8Receipt.none ? M8Why.notDismantle : M8Why.notReconnect);
            case M8Kind.oldCut:
              expect(w, M8Why.crate);
            case M8Kind.paidCut:
              expect(w, M8Why.reconnect);
          }
        }
      }
      // The right cards state the lesson's rule.
      expect(L.whyRight[M8Why.holdShort]!.first, contains('15'));
      expect(L.whyRight[M8Why.notDismantle]!.first, contains('180'));
      expect(L.whyRight[M8Why.reconnect]!.first, contains('রিকানেকশন চার্জ'));
    });

    test('no deadly in 8.2 (M8-1): every mistake a slip; keys, pictures, lesson points; listening = a slip', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      expect(Mk.all.map((m) => m.textBn).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.2/m8_notice_calendar/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m == Mk.pushMeter) {
          expect(m.lessonPoint, isNull, reason: 'a myth, not a numbered point');
        } else {
          expect(m.lessonPoint, anyOf(2, 3), reason: 'lesson 8.2 points 3 and 4: the notice rule and the 180 days');
        }
      }
      for (final m in [Mk.dismantleEarly, Mk.holdDismantle, Mk.crateWrong]) {
        expect(m.lessonPoint, 3, reason: 'the dismantling point');
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m8_notice_calendar/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8NoticeCalendarPacks.keys, ['do_8_2_a']);
      // The push slips take the myth he pushed.
      expect(Mk.push(M8Kind.noNotice), Mk.pushNoNotice);
      expect(Mk.push(M8Kind.shortNotice), Mk.pushNoNotice);
      expect(Mk.push(M8Kind.recentCut), Mk.pushPity);
      expect(Mk.push(M8Kind.paidCut), Mk.pushMeter);
    });

    Map<String, dynamic> lesson() {
      final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.2');
    }

    test('the live lesson (X3): the 15 clear days, Sec 56, reading and seal, dues + charge, 180 days, the myths word for word', () {
      final text = _nk(jsonEncode(lesson()));
      for (final line in [
        '১৫ দিনের ক্লিয়ার নোটিশ পিরিয়ড ছাড়া সাধারণ বকেয়ার জন্য লাইন কাটা যায় না',
        'ইলেকট্রিসিটি অ্যাক্ট ২০০৩-এর সেকশন ৫৬ অনুযায়ী, ১৫ দিনের লিখিত নোটিশ বাধ্যতামূলক',
        'লাইন কাটার আগে মিটারের বর্তমান রিডিং এবং সীল-এর অবস্থা নোট করে নিন',
        'গ্রাহককে পুরো টাকা এবং রিকানেকশন চার্জ জমা দিতে হবে। দয়া করে লাইন জুড়ে দিলে আপনিই বিপদে পড়বেন',
        'লাইন কাটার পর ১৮০ দিন (৬ মাস) কেটে গেলে এবং গ্রাহক টাকা না দিলে',
        'সার্ভিস তার, মিটার সব খুলে স্টোরে জমা দিতে হয়',
        'মিটার শিফটিং-এর জন্য নির্দিষ্ট ফি জমা দিতে হয় এবং নতুন জায়গার টেকনিক্যাল ফিজিবিলিটি চেক করতে হয়',
        'বিনা অর্ডারে মিটার সরালে চুরির দায় আপনার ওপর আসতে পারে',
        'তবে চুরির ক্ষেত্রে (Sec 135) কোনো নোটিশ লাগে না',
      ]) {
        expect(text, contains(_nk(line)), reason: line);
      }
      // The coworker's pushes are lesson myths word for word (M8-14).
      final myths = ((lesson()['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      expect(_nk(L.coworkerMeter.line), _nk((myths[0] as Map)['myth'] as String));
      expect(_nk(L.coworkerNoNotice.line), _nk((myths[1] as Map)['myth'] as String));
      expect(L.coworkerPity.line, isNot(anyOf(L.coworkerMeter.line, L.coworkerNoNotice.line)), reason: 'the pity line is a draft of ours');
      // The cards quote the lesson's realities.
      expect(_nk(Mk.pushNoNotice.textBn), contains(_nk('সেকশন 56 অনুযায়ী 15 দিনের লিখিত নোটিশ বাধ্যতামূলক')));
      expect(Mk.pushPity.textBn, contains('দয়া করে লাইন জুড়ে দিলে আপনিই বিপদে পড়বেন'));
      expect(Mk.dismantleEarly.textBn, contains('180 দিন (6 মাস)'));
      // The tiles are the item's words.
      expect([for (final t in M8Tile.values) L.tile(t)], ['লাইন কাটুন', 'এখন নয়', 'জুড়ে দিন', 'খুলে স্টোরে']);
      // The receipt prints amounts, never a verdict word.
      final h = m8DealHouse(M8Kind.paidCut, DateTime.utc(2026, 7, 20), math.Random(1));
      for (final l in [L.duesLine(h), L.chargeLine(h)]) {
        expect(l, isNot(contains('পুরো')));
        expect(l, isNot(contains('আংশিক')));
      }
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ"; option groups within 1.3×', () {
      final h = m8DealHouse(M8Kind.recentCut, DateTime.utc(2026, 7, 20), math.Random(2));
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.allWhyWrong,
        for (final s in L.scripts) ...[s.line, ...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        L.callHeld,
        L.noteDone,
        L.allSet,
        L.fail,
        for (final t in M8Tile.values) L.tile(t),
        for (final l in M8Label.values) L.label(l),
        L.spokenNotice,
        L.duesLine(h),
        L.chargeLine(h),
        for (final k in M8Kind.values) L.caught(k),
        for (final m in Mk.all) m.textBn,
        ...kM8Months,
        ...kM8MonthsShort,
        ...kM8Dow,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[\u09DC\u09DD\u09DF]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        for (final bad in ['এলটি', 'এইচটি', 'কেভি', 'অন', 'অফ']) {
          expect(RegExp('(^|[\\s,।—“])$bad(\$|[\\s,।—”])').hasMatch(l), isFalse, reason: '$bad in $l');
        }
      }
      expect(L.count(26), '26 দিন');
      expectSameLength('why', [...L.allWhyRight, ...L.allWhyWrong]);
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M8Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.whyWrong(w));
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.whyWrong(w), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final s in L.scripts) {
        expectSameLength('coworker ${s.line}', [...s.right, ...s.wrong]);
        expectLibrary('coworker ${s.line}', s.right, s.wrong, minRight: 3);
        expect(s.asks, contains('কী করবেন?'));
        expect(s.exitLine, L.coworkerExit);
      }
      expect({for (final s in L.scripts) s.line}, hasLength(3));
    });

    test('spoken lines: his exit is recorded; his three pushes and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'বিল বাকি থাকলে নোটিশ ছাড়াই লাইন কাটা যায়।',
        'বেচারা কাঁদছে, বাকি টাকা পরে দেবে — জুড়ে দাও।',
        'লাইনম্যান চাইলেই যেকোনো সময় গ্রাহকের মিটার শিফট বা সরাতে পারে।',
      ]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, ...{...L.whyQ.values}, L.callHeld, L.noteDone, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      expect(L.reused, contains('ওকে কী বলবেন?'), reason: 'it already has a clip');
      expect(L.newGuideLines, isNot(contains('ওকে কী বলবেন?')));
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      final spoken = L.spokenLines.toSet();
      for (final l in [
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.callHeld,
        L.noteDone,
        L.allSet,
        L.quick,
        L.fail,
        for (final s in L.scripts) ...[s.line, ...s.asks],
        L.coworkerExit,
        ...L.whyQ.values,
        for (final m in Mk.all) m.textBn,
      ]) {
        expect(spoken, contains(l), reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_notice_calendar: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: panels stay on the scene under the header, clear of the guide, its bubble and the tiles; every date finds its cell', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M8Geo.forScene(h, inset);
          final scene = Rect.fromLTWH(0, 0, 360, h);
          final panels = <String, Rect>{
            'cal': g.cal,
            'docket': g.docket,
            'receiptIcon': g.receiptIcon,
            'countChip': g.countChip,
            'closed': g.closedDocket,
            'receiptCard': g.receiptCard,
            'notebook': g.notebook,
            'meterBox': g.meterBox,
            'discBtn': g.discBtn,
            'meterItem': g.meterItem,
            'coilItem': g.coilItem,
            'pad0': g.pad(0),
            'pad1': g.pad(1),
            for (var i = 0; i < 3; i++) 'tile$i': g.tile(i, 3),
          };
          for (final e in panels.entries) {
            expect(scene.contains(e.value.topLeft) && scene.contains(e.value.bottomRight - const Offset(1, 1)), isTrue, reason: '${e.key} h $h: ${e.value}');
            if (e.key.startsWith('tile')) continue;
            expect(e.value.top, greaterThan(100), reason: '${e.key} h $h under the header (a 560-high scene is the tightest)');
            expect(e.value.overlaps(g.bubble), isFalse, reason: '${e.key} h $h under the bubble');
            expect(e.value.overlaps(g.guide), isFalse, reason: '${e.key} h $h under the guide');
          }
          for (var i = 0; i < 3; i++) {
            expect(g.tile(i, 3).overlaps(g.guide), isFalse);
            expect(g.tile(i, 3).overlaps(g.bubble), isFalse);
            expect(g.tile(i, 3).width, greaterThanOrEqualTo(72));
            expect(g.tile(i, 3).height * _k, greaterThanOrEqualTo(48));
          }
          for (var i = 0; i < 2; i++) {
            expect(g.tile(i, 2).overlaps(g.guide), isFalse);
          }
          // The docket card, the chip and the calendar do not overlap.
          expect(g.docket.overlaps(g.cal), isFalse);
          expect(g.docket.overlaps(g.receiptIcon), isFalse);
          expect(g.countChip.overlaps(g.receiptIcon), isFalse);
          expect(g.countChip.overlaps(g.cal), isFalse);
          // Notebook stage.
          expect(g.meterBox.overlaps(g.notebook), isFalse);
          expect(g.meterBox.overlaps(g.discBtn), isFalse);
          expect(g.discBtn.overlaps(g.notebook), isFalse);
          for (var i = 0; i < 5; i++) {
            expect(g.notebook.contains(g.wheel(i).topLeft) && g.notebook.contains(g.wheel(i).bottomRight - const Offset(1, 1)), isTrue);
            expect(g.wheel(i).overlaps(g.chipOk), isFalse);
            if (i > 0) expect(g.wheel(i).overlaps(g.wheel(i - 1)), isFalse);
          }
          expect(g.chipOk.overlaps(g.chipBroken), isFalse);
          expect(g.noteBtn.overlaps(g.wheel(0)), isFalse);
          // Dismantle stage: equal pads, the items clear of them.
          expect(g.pad(0).size, g.pad(1).size);
          expect(g.pad(0).overlaps(g.pad(1)), isFalse);
          expect(g.meterItem.overlaps(g.pad(0)), isFalse);
          expect(g.coilItem.overlaps(g.pad(1)), isFalse);
          expect(g.meterItem.overlaps(g.coilItem), isFalse);
        }
      }
      // Every date finds its cell in both calendars; today's row is the last.
      final g = M8Geo.forScene(780, 0);
      final today = DateTime.utc(2026, 9, 17);
      for (final kind in [M8Kind.longNotice, M8Kind.oldCut]) {
        final h = m8DealHouse(kind, today, math.Random(3));
        final end = h.planner ? 334 : 63;
        for (var d = 0; d <= end; d++) {
          final dt = today.subtract(Duration(days: d));
          final r = g.dateRect(h, dt);
          expect(r, isNotNull, reason: '${h.planner} $d');
          expect(g.cal.contains(r!.center), isTrue);
          expect(g.dateAt(h, r.center), dt, reason: '${h.planner} $d');
        }
        expect(g.dateRect(h, today.subtract(Duration(days: end + 400))), isNull);
        expect(g.dateAt(h, g.cal.topLeft + const Offset(2, 2)), isNull, reason: 'the header row');
        // The hand's start cell is a date, never a docket date, never today's row.
        for (var s = 0; s < 40; s++) {
          final hh = m8DealHouse(kind, today, math.Random(s));
          final p = g.hintCell(hh);
          final d = g.dateAt(hh, p);
          expect(d, isNotNull);
          expect(hh.docketDates, isNot(contains(d)));
          expect((p.dy - g.todayRect(hh).center.dy).abs(), greaterThan(30), reason: 'not today\'s row');
        }
      }
      // The grid's last row holds today; the planner's last row today's month.
      final gridHouse = m8DealHouse(M8Kind.longNotice, today, math.Random(1));
      expect(m8GridStart(today).weekday, DateTime.sunday);
      expect(g.todayRect(gridHouse).bottom, closeTo(g.cal.bottom, 0.5));
      final planHouse = m8DealHouse(M8Kind.oldCut, today, math.Random(1));
      expect(g.todayRect(planHouse).bottom, closeTo(g.cal.bottom, 0.5));
      expect(m8PlannerStart(today), DateTime.utc(2025, 10, 1));
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

    testWidgets('the guide comes first: a tap does not skip him; then the pinned paper, no calendar yet', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8NoticeCalendarPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.docketWord), findsOneWidget);
      expect(_label(L.calendarWord), findsNothing, reason: 'the paper is not open yet');
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(_tile(M8Tile.hold), findsNothing, reason: 'no tiles before a count');
      expect(M8NoticeProbe.stage, 'docket');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the stage\'s pool in turn, never a tile, a date or a verdict', (t) async {
      final c = await _open(t, 5);
      expect(c.read(guideDirectorProvider).line, anyOf(contains(L.askDocketFirst), contains(L.askDocket)));
      final guide = find.byKey(const ValueKey('hud-guide'));
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await _pump(t, 400);
      expect(c.read(guideDirectorProvider).line, L.tapDocket);
      await _openDocket(t);
      expect(c.read(guideDirectorProvider).line, L.askCount);
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await _pump(t, 400);
      expect(c.read(guideDirectorProvider).line, L.tapCount);
      for (final l in [L.askDocketFirst, L.askDocket, L.tapDocket, L.askCount, L.tapCount, L.askDecide, L.tapDecide, L.askNote, L.tapNote, L.askCrate, L.tapCrate]) {
        expect(RegExp('[0-9]').hasMatch(l), isFalse, reason: 'no number or date named: $l');
        for (final tile in M8Tile.values) {
          expect(l.contains(L.tile(tile)), isFalse, reason: 'no tile named: $l');
        }
      }
      await _close(t, c);
    });

    testWidgets('the docket prints plain dates (none marked), the calendar \'আজ\' only on today, a short drag measures nothing', (t) async {
      final c = await _open(t, 9);
      await _openDocket(t);
      final h = _house;
      for (final l in h.order) {
        expect(_label(L.entryText(h, l)), findsOneWidget, reason: L.entryText(h, l));
      }
      expect(_label(L.calendarWord), findsOneWidget);
      expect(find.text(L.count(1)), findsNothing);
      // A short drag, a drag that ends off 'আজ', and a drag from a date after today: nothing measured.
      final a = _geo.dateRect(h, _startOf(h))!.center;
      await _ribbon(t, _startOf(h), endAt: a + const Offset(10, 0));
      expect(M8NoticeProbe.measured, isFalse);
      expect(M8NoticeProbe.count, isNull);
      await _ribbon(t, _startOf(h), endAt: _geo.cal.topLeft + const Offset(20, 40));
      expect(M8NoticeProbe.measured, isFalse);
      expect(_tile(M8Tile.hold), findsNothing);
      expect(_live.slips, 0);
      // The full drag: the count, the tiles rise.
      await _ribbon(t, _startOf(h));
      expect(M8NoticeProbe.measured, isTrue);
      expect(find.text(L.count(h.daysAgo(_startOf(h)))), findsOneWidget);
      for (final tile in h.tiles) {
        expect(_tile(tile), findsOneWidget);
      }
      for (final tile in M8Tile.values.where((x) => !h.tiles.contains(x))) {
        expect(_tile(tile), findsNothing, reason: 'tiles depend only on a live or a cut line');
      }
      // Re-measuring is free: from another date the count changes.
      final other = h.docketDates.firstWhere((d) => d != _startOf(h));
      await _ribbon(t, other);
      expect(find.text(L.count(h.daysAgo(other))), findsOneWidget);
      expect(_live.slips, 0);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    // His houses: a hold (no notice / short notice), a cut-line hold, a paid cut; and a play without him
    // on an act first (cut / dismantle) so the notebook and the crate are walked.
    final flowSeeds = <int>{
      _seedWhere((d) => d.houses.map((h) => h.kind).toSet().containsAll({M8Kind.longNotice, M8Kind.oldCut})),
      _seedWhere((d) => d.houses[d.hisHouse].kind == M8Kind.paidCut && d.houses.any((h) => h.kind == M8Kind.longNotice)),
      _seedWhere((d) => d.houses[d.hisHouse].kind == M8Kind.recentCut && d.houses.any((h) => h.kind == M8Kind.oldCut)),
      _seedWhere((d) => d.houses[d.hisHouse].kind == M8Kind.noNotice && d.houses.any((h) => h.kind == M8Kind.paidCut)),
    };
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three houses, the ribbon, tiles opened big, receipt, notebook, hold, crate, reasons, he is refused → pass', (t) async {
        final c = await _open(t, seed);
        final kinds = [for (final h in _live.deal.houses) h.kind];
        for (var i = 0; i < 3; i++) {
          await _playHouse(t);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.2/do/0'], 'cleared', reason: '$kinds');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.2/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        for (final k in kinds) {
          expect(find.text(L.caught(k)), findsOneWidget);
        }
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final cutFirst = _seedWhere((d) => d.houses.first.kind == M8Kind.longNotice && d.hisHouse != 0);
    testWidgets('a tap on a tile opens it big and answers nothing; ✕ sets it aside; ✓ then scores', (t) async {
      final c = await _open(t, cutFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await t.tap(_tile(M8Tile.hold), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.text(L.tileHold), findsWidgets);
      expect(_live.slips, 0, reason: 'a touch is never an answer');
      expect(M8NoticeProbe.stage, 'measure');
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await t.tap(_tile(M8Tile.cut), warnIfMissed: false);
      await _pump(t, 500);
      expect(await confirmChoice(t), isTrue);
      await _pump(t, 600);
      expect(M8NoticeProbe.stage, 'note', reason: 'the right tile opens the notebook');
      expect(_live.slips, 0);
      await _close(t, c);
    });

    testWidgets('the notebook: wrong digits and a wrong seal are a slip each (a card each, then the true entries); the clean hold then cuts', (t) async {
      final c = await _open(t, cutFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await _choose(t, M8Tile.cut);
      final h = _house;
      final bad = [...h.meter]..[0] = (h.meter[0] + 1) % 10;
      await _setWheels(t, bad);
      await _chip(t, !h.sealIntact);
      await _tapDesign(t, _geo.noteBtn.center);
      expect(find.text(Mk.noteReading.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(Mk.noteSeal.textBn), findsOneWidget, reason: 'one card each');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 700);
      expect(_live.slips, 2);
      expect(M8NoticeProbe.noted, isTrue, reason: 'the notebook shows the true entries now');
      expect(find.byType(StruckOutCard), findsNothing);
      await _holdDisc(t);
      await _pump(t, 3500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.index, 1, reason: 'the cut went through; the house slipped, so no reason deck');
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.noteReading.key, Mk.noteSeal.key]);
      await _close(t, c);
    });

    testWidgets('a short hold does not cut; a hold with the notebook empty is the no-note slip', (t) async {
      final c = await _open(t, cutFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await _choose(t, M8Tile.cut);
      await _holdDisc(t, ms: 400);
      expect(find.byType(MistakeCard), findsNothing, reason: 'let go early: nothing');
      expect(_live.slips, 0);
      await _holdDisc(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.noNote.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 1);
      expect(M8NoticeProbe.stage, 'note', reason: 'still at the meter');
      await _close(t, c);
    });

    final oldFirst = _seedWhere((d) => d.houses.first.kind == M8Kind.oldCut && d.hisHouse != 0);
    testWidgets('the crate: the verandah is a slip each time and the item springs back; empty ground costs nothing; the crate takes it', (t) async {
      final c = await _open(t, oldFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await _choose(t, M8Tile.dismantle);
      expect(M8NoticeProbe.stage, 'crate');
      final veranda = _geo.pad(1 - _crateSide).center;
      final crate = _geo.pad(_crateSide).center;
      // Empty ground: nothing.
      await _drag(t, _geo.meterItem.center, const Offset(180, 160));
      expect(_live.slips, 0);
      expect(find.byType(MistakeCard), findsNothing);
      await _drag(t, _geo.meterItem.center, veranda);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.crateWrong.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 1);
      await _drag(t, _geo.meterItem.center, crate);
      await _drag(t, _geo.coilItem.center, veranda);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 2);
      expect(M8NoticeProbe.stage, 'crate', reason: 'one item still to carry');
      await _drag(t, _geo.coilItem.center, crate);
      await _pump(t, 800);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'the house slipped: no reason, no ◆ for it');
      await _pump(t, 2500);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet(), {Mk.crateWrong.key});
      await _close(t, c);
    });

    testWidgets('a wrong tile is a slip with its card; after it the house resolves to the right state (no reason for it)', (t) async {
      final c = await _open(t, cutFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await _choose(t, M8Tile.hold);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.holdCut.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 700);
      expect(_live.slips, 1);
      expect(M8NoticeProbe.stage, 'note', reason: 'the cut house goes on to the notebook');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.holdCut.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    final shortFirst = _seedWhere((d) => d.houses.first.kind == M8Kind.shortNotice && d.hisHouse == 0);
    testWidgets('three slips strike the level out (a needless hold, the hold with no note, wrong digits); nothing freezes', (t) async {
      final c = await _open(t, cutFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await _choose(t, M8Tile.hold);
      expect(find.text(Mk.holdCut.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 700);
      expect(M8NoticeProbe.stage, 'note');
      await _holdDisc(t);
      expect(find.text(Mk.noNote.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.slips, 2);
      final bad = [..._house.meter]..[1] = (_house.meter[1] + 1) % 10;
      await _setWheels(t, bad);
      await _chip(t, _house.sealIntact);
      await _tapDesign(t, _geo.noteBtn.center);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 8.2');
      expect(c.read(gameSaveProvider).mistakes.every((m) => !m.deadly), isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = a slip (no freeze); the tiles waited for him; he came once', (t) async {
      final c = await _open(t, shortFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      final script = L.coworkerFor(_house.kind);
      await t.tap(_tile(M8Tile.hold), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the tiles wait for him');
      expect(find.byType(CardPreviewOverlay), findsNothing);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(script.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushNoNotice.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.pushNoNotice.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He came once: now the right tile opens at once.
      await t.tap(_tile(M8Tile.hold), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      await _close(t, c);
    });

    final paidSeed = _seedWhere((d) => d.houses.first.kind == M8Kind.paidCut && d.houses.first.receipt == M8Receipt.full && d.hisHouse != 0);
    testWidgets('a paid cut line: the receipt opens first (two printed lines, amounts only); then the tile works', (t) async {
      final c = await _open(t, paidSeed);
      await _openDocket(t);
      final h = _house;
      await _ribbon(t, _startOf(h));
      expect(_label(L.receiptWord), findsOneWidget, reason: 'the consumer\'s paper');
      // 'জুড়ে দিন' before the receipt: the receipt opens, nothing is answered.
      await t.tap(_tile(M8Tile.reconnect), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.byKey(const ValueKey('receipt-card')), findsOneWidget);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(find.text(L.duesLine(h)), findsOneWidget);
      expect(find.text(L.chargeLine(h)), findsOneWidget);
      expect(_live.slips, 0);
      await _tapDesign(t, const Offset(180, 220));
      expect(find.byKey(const ValueKey('receipt-card')), findsNothing);
      await t.tap(_tile(M8Tile.reconnect), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the reason deck opens at once; the reason pays and the next house opens', (t) async {
      final c = await _open(t, shortFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await _choose(t, M8Tile.hold);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(M8NoticeProbe.stage, 'measure');
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[_live.why]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(M8NoticeProbe.stage, 'docket');
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: docket → a tap; calendar → a drag from no docket date; tiles → a sweep over all; never one tile', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, cutFirst);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the pinned paper');
      expect(scene().debugOptions, isEmpty, reason: 'a tap hint, not a sweep');
      await _openDocket(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle at the calendar');
      expect(scene().debugOptions, isEmpty, reason: 'a drag nudge');
      await _ribbon(t, _startOf(_house));
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the tiles up');
      final h = _house;
      expect(scene().debugOptions, hasLength(h.tiles.length), reason: 'a sweep over every tile alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // A tile open: the hand is off (the preview sweeps its own two buttons).
      await t.tap(_tile(M8Tile.cut), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _close(t, c);
    });

    testWidgets('gesture hand at the notebook: a swipe on the first wheel, a sweep over both chips, a tap on the button only when it is the last control, then a hold', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, cutFirst);
      await _openDocket(t);
      await _ribbon(t, _startOf(_house));
      await _choose(t, M8Tile.cut);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      final h = _house;
      await _setWheels(t, h.meter);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'wheels done, no seal chosen: a sweep over both chips');
      expect(scene().debugOptions, hasLength(2));
      await _chip(t, h.sealIntact);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'only the button is left: a tap');
      expect(scene().debugOptions, isEmpty);
      await _tapDesign(t, _geo.noteBtn.center);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'noted: the hold on the disconnect control');
      expect(scene().debugOptions, isEmpty);
      expect(_live.slips, 0);
      await _close(t, c);
    });
  });
}
