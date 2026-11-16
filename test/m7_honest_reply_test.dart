// Lesson 7.9 (গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব), কাজ 2 "সৎ জবাব": the
// rules (a tile dropped while bubbles still come = interrupting; both tiles
// honest = he calms, any trap tile = that trap's slip and a fresh deal; the
// meter owner's job sheet: no signature on 'চলুন' = slip), the deal (the
// owner always one of the three, 1st–3rd), the six tiles, the libraries, the
// coworker's single myth-2 push (listening = a slip, never deadly here), and
// the level in the shell: the guide first, bubbles held for a reading time, a
// full clean play (tiles dragged, a reason pick each, the owner's sheet, the
// coworker refused), an interrupting slip that pauses the bubbles, a trap
// slip, three slips, 'চলুন' without the sheet, listening to him, 'বলুন'
// waits for him on a fast play, the praise window takes no touch, and the
// gesture hand shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m7_honest_reply.dart';
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
  rungId: '7.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7HonestReplyPacks['do_7_9_b']!;
typedef L = M7HonestReplyLines;
typedef Mk = M7HonestReplyMistakes;

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

M7HonestRun get _live => M7HonestReplyProbe.run!;

/// Pumps until the customer has said it all (his bubbles held one by one).
Future<void> _untilStopped(WidgetTester t, {int maxMs = 40000}) async {
  for (var ms = 0; ms < maxMs && _live.phase != M7Phase.stopped; ms += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await _pump(t, 300);
}

/// A tile dragged from the tray onto slot [slot] of the strip.
Future<void> _dragTile(WidgetTester t, M7Tile tile, int slot) async {
  final from = t.getCenter(find.byKey(ValueKey('tile-${tile.text}')));
  final to = t.getCenter(find.byKey(ValueKey('slot-$slot')));
  final g = await t.startGesture(from);
  await g.moveBy(const Offset(0, -24));
  await t.pump(const Duration(milliseconds: 30));
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from + const Offset(0, -24), to, i / 8)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 250);
}

Future<void> _fillStrip(WidgetTester t, {required bool honest}) async {
  final tiles = honest ? [for (final x in _live.tray) if (x.honest) x] : [..._live.tray.where((x) => x.honest).take(1), ..._live.tray.where((x) => !x.honest).take(1)];
  await _dragTile(t, tiles[0], 0);
  await _dragTile(t, tiles[1], 1);
}

Future<void> _tapSay(WidgetTester t) async {
  await t.tap(_label(L.say), warnIfMissed: false);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7HonestReplyPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M7HonestDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7HonestDeal(math.Random(s))));

/// The coworker comes (the strip full, 'বলুন' tapped): refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworkerMyth.right);
  await _pump(t, 2600);
}

/// One customer played right (the coworker refused if he is dealt on him).
Future<void> _playCustomer(WidgetTester t, M7HonestDeal d, int i) async {
  await _untilStopped(t);
  expect(_live.index, i);
  await _fillStrip(t, honest: true);
  expect(_live.stripFull, isTrue);
  await _tapSay(t);
  if (d.coworkerAt == i) {
    await _refuse(t);
    await _tapSay(t);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'customer $i');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck ($i)');
  await _pump(t, 500);
  await _pickRight(t, L.whyRight[d.why[i]]!);
  await _pump(t, 2500);
  if (d.customers[i].owner) {
    // His job sheet: drag it to him to sign, then 'চলুন'.
    expect(_live.phase, M7Phase.sheet);
    await _dragSheet(t);
    expect(_live.sheetSigned, isTrue);
    await t.tap(_label(L.go), warnIfMissed: false);
    await _pump(t, 300);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the sheet reason');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[M7Why.sheet]!);
    await _pump(t, 2500);
  }
}

Future<void> _dragSheet(WidgetTester t) async {
  final from = t.getCenter(_label(L.sheetLabel).first);
  final to = t.getCenter(find.byKey(ValueKey('customer-${_live.index}')));
  final g = await t.startGesture(from);
  await g.moveBy(const Offset(10, 0));
  await t.pump(const Duration(milliseconds: 30));
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from + const Offset(10, 0), to, i / 8)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 300);
}

M7Customer _cust(M7Situation s) => M7Customer(situation: s, look: 0, right: false, wording: 0);

/// A run over the three given situations; the first is at the table.
M7HonestRun _runOf(M7Situation first, {M7Situation? second}) => M7HonestRun(
      M7HonestDeal(
        customers: [_cust(first), _cust(second ?? M7Situation.meter), _cust(M7Situation.outage)],
        coworkerAt: 0,
        why: const [M7Why.reply, M7Why.reply, M7Why.reply],
      ),
      rng: math.Random(5),
    );

/// A run whose first customer has said it all (bubbles over).
M7HonestRun _stoppedRun(M7Situation s) {
  final r = _runOf(s)
    ..startListening()
    ..showBubble(0)
    ..stopListening();
  return r;
}

void _place(M7HonestRun r, {required bool honest}) {
  final tiles = honest ? [for (final x in r.tray) if (x.honest) x] : [r.tray.firstWhere((x) => x.honest), r.tray.firstWhere((x) => !x.honest)];
  r.drop(tiles[0], 0);
  r.drop(tiles[1], 1);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('rules', () {
    test('the six tiles: two honest (a fact and a next step), four traps one of each kind, equal weight', () {
      for (final s in M7Situation.values) {
        for (var a = 0; a < 3; a++) {
          final tiles = m7DealTiles(s, a, math.Random(a * 7 + s.index));
          expect(tiles, hasLength(6), reason: '$s');
          expect(tiles.where((t) => t.honest).map((t) => t.role).toSet(), {0, 1}, reason: '$s');
          expect(tiles.where((t) => !t.honest).map((t) => t.trap).toSet(), M7Trap.values.toSet(), reason: '$s');
          expect(tiles.map((t) => t.text).toSet(), hasLength(6));
        }
      }
    });

    test('a re-deal swaps the phrasings and the order varies between plays', () {
      for (final s in M7Situation.values) {
        final a = m7DealTiles(s, 0, math.Random(3));
        final b = m7DealTiles(s, 1, math.Random(3));
        expect({for (final t in a) t.text}.intersection({for (final t in b) t.text}), isEmpty, reason: '$s: no tile repeats its wording');
      }
      final orders = {for (var k = 0; k < 40; k++) m7DealTiles(M7Situation.bill, 0, math.Random(k)).map((t) => t.honest ? 'h' : 't').join()};
      expect(orders.length, greaterThan(4), reason: 'the honest tiles sit in varying places');
    });

    test('the deal: the owner always one of the three (1st–3rd), distinct situations, looks, sides, coworker customer vary', () {
      final ownerAt = <int>{};
      final cw = <int>{};
      final sides = <bool>{};
      final sets = <String>{};
      for (var s = 0; s < 300; s++) {
        final d = m7HonestDeal(math.Random(s));
        expect(d.customers, hasLength(3));
        expect(d.customers.where((c) => c.owner), hasLength(1), reason: 'seed $s');
        expect(d.customers.map((c) => c.situation).toSet(), hasLength(3));
        expect(d.customers.map((c) => c.look).toSet(), hasLength(3));
        ownerAt.add(d.customers.indexWhere((c) => c.owner));
        cw.add(d.coworkerAt);
        for (final c in d.customers) {
          sides.add(c.right);
          expect(c.bubbles.length, inInclusiveRange(2, 3));
        }
        sets.add(d.customers.map((c) => c.situation.index).join());
        for (final (i, w) in d.why.indexed) {
          if (d.customers[i].owner) expect(w, M7Why.reply);
          if (w == M7Why.promise) expect(m7PromiseFits(d.customers[i].situation), isTrue);
        }
      }
      expect(ownerAt, {0, 1, 2});
      expect(cw, {0, 1, 2});
      expect(sides, {true, false});
      expect(sets.length, greaterThan(12));
    });

    test('no tile before he has walked up; a tile while bubbles still come is interrupting (R26), kept in the tray', () {
      final r = _runOf(M7Situation.bill);
      final t0 = r.tray.first;
      expect(r.drop(t0, 0).placed, isFalse);
      expect(r.slips, 0, reason: 'he is still walking up: nothing');
      r.startListening();
      expect(r.bubblesComing, isTrue);
      final d = r.drop(t0, 0);
      expect(d.placed, isFalse);
      expect(d.mistake, Mk.interrupt);
      expect(r.slips, 1);
      expect(r.slots, [null, null]);
      expect(r.interruptedHere, isTrue);
      r.showBubble(1);
      r.stopListening();
      expect(r.bubblesComing, isFalse);
      expect(r.drop(t0, 0).placed, isTrue);
    });

    test('the strip: two slots, a tile once, taken back by a tap; no বলুন until both are filled', () {
      final r = _stoppedRun(M7Situation.transformer);
      expect(r.sayIt().ready, isFalse);
      final a = r.tray[0], b = r.tray[1];
      expect(r.drop(a, 0).placed, isTrue);
      expect(r.drop(b, 0).placed, isFalse, reason: 'the slot is taken');
      expect(r.drop(a, 1).placed, isFalse, reason: 'the same tile twice');
      expect(r.sayIt().ready, isFalse);
      expect(r.drop(b, 1).placed, isTrue);
      expect(r.stripFull, isTrue);
      expect(r.remove(0), isTrue);
      expect(r.stripFull, isFalse);
      expect(r.remove(0), isFalse);
    });

    test('both honest: he calms (the reply is done, nothing else), a reason follows', () {
      final r = _stoppedRun(M7Situation.outage);
      _place(r, honest: true);
      final s = r.sayIt();
      expect(s.ready, isTrue);
      expect(s.mistake, isNull);
      expect(r.phase, M7Phase.said);
      expect(r.roundDone, isTrue);
      expect(r.slips, 0);
      expect(r.thorough, isTrue);
      expect(r.caught, containsAll([L.caughtHonest, L.caughtListen]));
      expect(r.caught, isNot(contains(L.caughtExplain)), reason: 'only the meter owner explains the job');
    });

    test('each trap tile is its own slip; the strip is cleared and the tiles are dealt again; the same customer stays', () {
      for (final t in M7Trap.values) {
        final r = _stoppedRun(M7Situation.complaint);
        final before = [...r.tray];
        final honest = r.tray.firstWhere((x) => x.honest);
        final trap = r.tray.firstWhere((x) => x.trap == t);
        r.drop(honest, 0);
        r.drop(trap, 1);
        final s = r.sayIt();
        expect(s.mistake, Mk.forTrap(t));
        expect(s.trap, t);
        expect(r.slips, 1);
        expect(r.index, 0);
        expect(r.phase, M7Phase.stopped);
        expect(r.slots, [null, null]);
        expect(r.attempt, 1);
        expect({for (final x in r.tray) x.text}.intersection({for (final x in before) x.text}), isEmpty);
        expect(r.thorough, isFalse);
        expect(r.trapped, {t});
      }
      expect(Mk.forTrap(M7Trap.promise), Mk.falsePromise);
      expect(Mk.forTrap(M7Trap.brushOff), Mk.brushOff);
      expect(Mk.forTrap(M7Trap.argue), Mk.arguing);
      expect(Mk.forTrap(M7Trap.denied), Mk.deniedRight);
    });

    test('two traps: the first in the strip is the slip (one slip, not two)', () {
      final r = _stoppedRun(M7Situation.bill);
      final traps = r.tray.where((x) => !x.honest).take(2).toList();
      r.drop(traps[1], 0);
      r.drop(traps[0], 1);
      expect(r.sayIt().mistake, Mk.forTrap(traps[1].trap!));
      expect(r.slips, 1);
    });

    test('the meter owner: a what-and-why pair, then the sheet; চলুন with no signature is a slip, with it the customer is done', () {
      final d = M7HonestDeal(customers: [_cust(M7Situation.meter), _cust(M7Situation.bill), _cust(M7Situation.outage)], coworkerAt: 1, why: const [M7Why.reply, M7Why.reply, M7Why.reply]);
      final r = M7HonestRun(d, rng: math.Random(2))
        ..startListening()
        ..showBubble(0)
        ..stopListening();
      expect(r.tray.where((t) => t.honest).map((t) => t.role).toSet(), {0, 1});
      expect(r.leave(), isNull, reason: 'no sheet yet: nothing');
      expect(r.giveSheet(), isFalse, reason: 'not his turn');
      _place(r, honest: true);
      expect(r.sayIt().mistake, isNull);
      expect(r.caught, contains(L.caughtExplain));
      expect(r.leave(), isNull, reason: 'the reason comes first');
      r.toSheet();
      expect(r.phase, M7Phase.sheet);
      expect(r.leave(), Mk.noSignature);
      expect(r.slips, 1);
      expect(r.phase, M7Phase.sheet, reason: 'the same customer: sign, then go');
      expect(r.giveSheet(), isTrue);
      expect(r.giveSheet(), isFalse, reason: 'signed once');
      expect(r.leave(), isNull);
      expect(r.phase, M7Phase.done);
      expect(r.caught, contains(L.caughtSheet));
      r.next();
      expect(r.index, 1);
      expect(r.phase, M7Phase.arriving);
      expect(r.sheetSigned, isFalse);
    });

    test('listening to him is a slip here, never deadly (M7-6, X2/B1); the mark falls 15 a slip; three slips fail the play', () {
      expect(Mk.listenMyth.deadly, isFalse);
      final r = _stoppedRun(M7Situation.bill);
      expect(r.pushSlip(), Mk.listenMyth);
      expect(r.slips, 1);
      expect(r.percent, 85);
      r.pushSlip();
      r.pushSlip();
      expect(r.percent, 55);
      expect(r.passed, isFalse, reason: 'not finished');
    });

    test('a play of three customers all right passes with 100', () {
      final r = _runOf(M7Situation.transformer, second: M7Situation.bill);
      for (var i = 0; i < 3; i++) {
        r
          ..startListening()
          ..showBubble(0)
          ..stopListening();
        _place(r, honest: true);
        expect(r.sayIt().mistake, isNull);
        if (r.customer.owner) {
          r
            ..toSheet()
            ..giveSheet();
          expect(r.leave(), isNull);
        }
        r.next();
      }
      expect(r.done, isTrue);
      expect(r.percent, 100);
      expect(r.passed, isTrue);
    });
  });

  group('content', () {
    test('libraries: every tile in one length band (1.3x), two phrasings per slot, no duplicates', () {
      final all = <String>[];
      for (final s in M7Situation.values) {
        final honest = L.honest[s]!;
        expect(honest, hasLength(2));
        for (final h in honest) {
          expect(h, hasLength(2), reason: '$s honest phrasings');
          all.addAll(h);
        }
        for (final t in M7Trap.values) {
          expect(L.traps[s]![t], hasLength(2), reason: '$s $t');
          all.addAll(L.traps[s]![t]!);
        }
        expect(L.bubbles[s], hasLength(2));
        for (final w in L.bubbles[s]!) {
          expect(w.length, inInclusiveRange(2, 3));
        }
      }
      expect(all.toSet(), hasLength(all.length), reason: 'no tile line twice');
      expectSameLength('tiles', all);
      for (final s in M7Situation.values) {
        for (var k = 0; k < 6; k++) {
          expectSameLength('deal $s', [for (final x in m7DealTiles(s, k, math.Random(k))) x.text]);
        }
      }
    });

    test('libraries: the reasons — same length, big enough, never a rule marked wrong; four questions', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expect(L.whyQ.keys.toSet(), M7Why.values.toSet());
      for (final w in M7Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(L.whyQ.values, ['কেন এই জবাব দিলেন?', 'কেন আগে পুরো কথা শুনলেন?', 'কেন কথা দিলেন না?', 'কেন জব শিটে সই নিলেন?']);
      final cw = L.coworkerMyth;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong, minRight: 3);
    });

    test('English digits only; jol not pani; base + nukta; every mistake has its picture; no deadly; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.needTwo,
        ...L.tapWhy,
        L.say,
        L.go,
        L.sheetLabel,
        for (var n = 1; n <= 3; n++) L.customer(n),
        for (final s in M7Situation.values) ...[
          for (final w in L.bubbles[s]!) ...w,
          for (final h in L.honest[s]!) ...h,
          for (final m in L.traps[s]!.values) ...m,
        ],
        ...L.calmReaction,
        ...L.trapReaction.values,
        L.interruptReaction,
        L.signedReaction,
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworkerMyth.recordedLines,
        ...L.coworkerMyth.right,
        ...L.coworkerMyth.wrong,
        ...L.coworkerMyth.asks,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.split(RegExp(r'[\s,।?!—-]+')).any((w) => w.startsWith('পানি')), isFalse, reason: l);
        expect(l.runes.any((r) => r == 0x9dc || r == 0x9dd || r == 0x9df), isFalse, reason: 'base + nukta: $l');
        expect(l.runes.any((r) => (r >= 0x400 && r <= 0x4ff) || (r >= 0x600 && r <= 0x6ff) || (r >= 0x900 && r <= 0x963) || (r >= 0x965 && r <= 0x97f) || (r >= 0xb80 && r <= 0xbff)), isFalse, reason: l);
        expect(RegExp('(^| )(অন|অফ)( |\$)').hasMatch(l), isFalse, reason: 'ON/OFF in English letters: $l');
        expect(l.contains('মৃত'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'M7-6: no deadly in 7.9');
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.9/m7_honest_reply/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m7_honest_reply/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).where((n) => n != '.gitkeep').toSet();
      expect(files, used);
      expect(m7HonestReplyPacks.keys, ['do_7_9_b']);
    });

    test('the seven slips are exactly the spec\'s; the coworker\'s line is the lesson\'s myth 2 word for word', () {
      expect(Mk.all.map((m) => m.key.split('/').last).toSet(), {'interrupt', 'false-promise', 'brush-off', 'arguing', 'denied-right', 'no-signature', 'listen-myth'});
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync(encoding: utf8)) as List<dynamic>;
      final l79 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.9');
      final myths = ((l79['content'] as Map)['myth_buster'] as Map)['myths'] as List<dynamic>;
      // The lesson file keeps য় ড় ঢ় as single code points; the game text is base + nukta.
      final lesson = ((myths[1] as Map)['myth'] as String).replaceAll(String.fromCharCode(0x9df), 'য়').replaceAll(String.fromCharCode(0x9dc), 'ড়').replaceAll(String.fromCharCode(0x9dd), 'ঢ়');
      expect(lesson, L.coworkerMyth.line);
    });

    test('rival lines: his exit is recorded; his myth push and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['গ্রাহক তো কিছুই বোঝেন না, তাকে যা-খুশি বুঝিয়ে দিলেই হলো।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, L.needTwo, ...L.whyQ.values, 'সাথীর কথা শুনবেন?', L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_honest_reply: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('the world: the tray, the strip and the figures leave the lane clear on every screen height', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M7HonestGeo.forScene(h, 0);
        expect(g.bubble.top, greaterThan(115));
        expect(g.bubble.bottom, lessThan(g.floorY - 100), reason: 'h $h: the bubble above the customer\'s head');
        for (final right in [false, true]) {
          final c = g.customer(right);
          expect(c.right, lessThanOrEqualTo(253), reason: 'h $h: clear of the corner guide');
          expect(c.overlaps(g.trainee), isFalse);
          expect(c.overlaps(g.sheet), isFalse);
          expect(c.bottom, g.floorY);
        }
        expect(g.sheet.overlaps(g.trainee), isFalse);
        expect(g.floorY, lessThan(h - 180), reason: 'h $h: the strip and the tray stand below the lane');
      }
    });
  });

  group('page', () {
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: a tap does not skip him; then the bubbles, the strip and the six tiles', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7HonestReplyPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 3000);
      expect(find.byKey(const ValueKey('slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot-1')), findsOneWidget);
      expect(_label(L.say), findsOneWidget);
      final d = m7HonestDeal(math.Random(3));
      expect(find.text(d.customers.first.bubbles.first), findsOneWidget, reason: 'his first bubble');
      for (final tile in _live.tray) {
        expect(_label(tile.text), findsOneWidget);
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('the bubbles come one at a time, each held; only then he has said it all; tapping the guide repeats the task, a different way', (t) async {
      final c = await _open(t, 5);
      final d = m7HonestDeal(math.Random(5));
      final lines = d.customers.first.bubbles;
      await _pump(t, 1500);
      expect(find.text(lines[0]), findsOneWidget);
      expect(find.text(lines[1]), findsNothing, reason: 'one at a time');
      expect(_live.phase, M7Phase.listening);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final said = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        said.add(c.read(guideDirectorProvider).line);
      }
      expect(said.every((l) => l.contains(L.askListen)), isTrue, reason: '$said');
      expect(said.first, isNot(said.last));
      await _untilStopped(t);
      expect(find.text(lines.last), findsOneWidget, reason: 'his last words stay');
      expect(c.read(guideDirectorProvider).line, contains(L.askAnswer));
      await _close(t, c);
    });

    // A play with the coworker on the owner and one with him elsewhere.
    final flowSeeds = [
      _seedWhere((d) => d.customers[d.coworkerAt].owner && d.customers.first.owner == false),
      _seedWhere((d) => !d.customers[d.coworkerAt].owner && d.customers.first.owner),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three customers listened to, honest replies, a reason each, the owner\'s sheet, the coworker refused → pass', (t) async {
        final d = m7HonestDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playCustomer(t, d, i);
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.9/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.9/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtListen), findsOneWidget);
        expect(find.text(L.caughtSheet), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final plain = _seedWhere((d) => d.coworkerAt != 0 && !d.customers.first.owner);
    testWidgets('a tile dropped while bubbles still come: interrupting — a card; the bubbles wait for the card, then go on', (t) async {
      final c = await _open(t, plain);
      await _pump(t, 1500);
      expect(_live.phase, M7Phase.listening);
      final tile = _live.tray.first;
      await _dragTile(t, tile, 0);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.interrupt.textBn), findsOneWidget);
      expect(_live.slots, [null, null], reason: 'the tile stayed in the tray');
      expect(find.text(L.interruptReaction), findsOneWidget);
      final shown = _live.bubblesShown;
      await _pump(t, 9000);
      expect(_live.bubblesShown, shown, reason: 'the bubbles wait while the card is up');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _untilStopped(t);
      expect(_live.phase, M7Phase.stopped);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.interrupt.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('a trap tile: only on বলুন does he react; the card; the tiles come again in other words; the same customer', (t) async {
      final c = await _open(t, plain);
      await _untilStopped(t);
      final before = [for (final x in _live.tray) x.text];
      await _fillStrip(t, honest: false);
      expect(find.byType(MistakeCard), findsNothing, reason: 'nothing before বলুন');
      expect(find.text(L.trapReaction[_live.slots[1]!.trap!]!), findsNothing);
      final trap = _live.slots[1]!.trap!;
      await _tapSay(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.forTrap(trap).textBn), findsOneWidget);
      expect(find.text(L.trapReaction[trap]!), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.index, 0);
      expect(_live.slots, [null, null]);
      expect({for (final x in _live.tray) x.text}.intersection(before.toSet()), isEmpty);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.forTrap(trap).key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('বলুন with the strip not full does nothing (the guide says to build the reply); a placed tile goes back on a tap', (t) async {
      final c = await _open(t, plain);
      await _untilStopped(t);
      await _tapSay(t);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, contains(L.needTwo));
      await _dragTile(t, _live.tray.first, 0);
      expect(_live.slots[0], isNotNull);
      await t.tap(find.byKey(const ValueKey('slot-0')));
      await _pump(t, 300);
      expect(_live.slots[0], isNull, reason: 'back to the tray');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, plain);
      await _untilStopped(t);
      for (var i = 0; i < 3; i++) {
        await _fillStrip(t, honest: false);
        await _tapSay(t);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final ownerFirst = _seedWhere((d) => d.customers.first.owner && d.coworkerAt != 0);
    testWidgets('the owner: চলুন with no signature is a slip and the same sheet step goes on; then drag and go', (t) async {
      final d = m7HonestDeal(math.Random(ownerFirst));
      final c = await _open(t, ownerFirst);
      await _untilStopped(t);
      await _fillStrip(t, honest: true);
      await _tapSay(t);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[d.why[0]]!);
      await _pump(t, 2500);
      expect(_live.phase, M7Phase.sheet);
      expect(_label(L.say), findsNothing, reason: 'the strip is gone');
      await t.tap(_label(L.go), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.noSignature.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 0);
      expect(_live.phase, M7Phase.sheet);
      await _dragSheet(t);
      expect(_live.sheetSigned, isTrue);
      expect(find.text(L.signedReaction), findsOneWidget);
      await t.tap(_label(L.go), warnIfMissed: false);
      await _pump(t, 300);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.noSignature.key);
      await _close(t, c);
    });

    testWidgets('the job sheet is dragged only when its turn comes; before it, a drag moves nothing', (t) async {
      final c = await _open(t, ownerFirst);
      await _untilStopped(t);
      await _dragSheet(t);
      expect(_live.sheetSigned, isFalse);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    final cwFirst = _seedWhere((d) => d.coworkerAt == 0);
    testWidgets('listening to him is a slip (his myth), never a freeze; the play goes on', (t) async {
      final c = await _open(t, cwFirst);
      await _untilStopped(t);
      await _fillStrip(t, honest: true);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerMyth.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(Mk.listenMyth.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.listenMyth.key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _tapSay(t);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reply still counts');
      await _close(t, c);
    });

    testWidgets('a fast play: বলুন waits for the coworker; he cuts in at once; after him it works', (t) async {
      final c = await _open(t, cwFirst);
      await _untilStopped(t);
      await _fillStrip(t, honest: true);
      // At once, well inside his 1.2–2.4 s timer.
      await _tapSay(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(_live.phase, M7Phase.stopped, reason: 'the reply was not said');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerMyth.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _tapSay(t);
      expect(_live.phase, M7Phase.said, reason: 'after him বলুন works');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch: no tile, no বলুন, no slip', (t) async {
      final d = m7HonestDeal(math.Random(plain));
      final c = await _open(t, plain);
      await _untilStopped(t);
      await _fillStrip(t, honest: true);
      await _tapSay(t);
      expect(_live.phase, M7Phase.said);
      // The ◆ on the table, the deck open at once: the strip and the tray are gone.
      expect(_label(L.say), findsNothing);
      expect(find.byKey(const ValueKey('slot-0')), findsNothing);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(200, 300));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[d.why[0]]!);
      await _pump(t, 3000);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: none while bubbles come; tiles waiting a sweep over all six (no tap); the strip full a tap on বলুন', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, plain);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 1500);
      expect(_live.phase, M7Phase.listening);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(const Offset(30, 400));
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(scene().showing, isFalse, reason: 'while bubbles come: no hand');
      await _untilStopped(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the tiles waiting');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep or a nudge presses nothing');
      expect(scene().debugOptions.length, 6, reason: 'a sweep over every tile alike');
      expect(find.byType(MistakeCard), findsNothing);
      await _fillStrip(t, honest: true);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with the strip full');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the one way on');
      await t.tapAt(const Offset(30, 400));
      await t.pump(const Duration(milliseconds: 200));
      expect(scene().showing, isFalse, reason: 'any touch hides it');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}
