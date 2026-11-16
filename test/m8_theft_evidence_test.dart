// Lesson 8.2 (সাপ্লাই কোড), কাজ "আগে প্রমাণ, পরে কাটা" (ruling M8-20: a new
// core, tracing the wire with a finger on a close-up instead of Module 7's
// viewfinder): the trace judge (it must follow the stealing wire end to end
// and not much else), the run's rules (disconnect with no clip, a clip that
// misses the wire, the shop or an honest house; the shop's decks; the gate;
// the close-out tray; the coworker), the deal, the libraries, every spoken
// line, and the level in the shell: the guide first, a full clean play (a
// reason each step, the coworker refused), the slips, three slips, real
// touches (a finger trace, a hold) and the gesture hand. There is no deadly
// act in this level (ruling M8-1).
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
import 'package:slm_flutter/features/game/m8_theft_evidence.dart';
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
  rungId: '8.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '8.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m8TheftPacks['do_8_2_b']!;
typedef L = M8TheftLines;
typedef Mk = M8TheftMistakes;

/// The new art is not in the bundle in tests until the director wires it.
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

/// The lesson writes য় ড় ঢ় as single code points; the game as base + nukta.
String _nk(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

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

Future<bool> _pumpUntilTrue(WidgetTester t, bool Function() ok, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

/// The one text of [options] that is on a deck now.
String _onDeck(List<String> options) {
  final on = [for (final x in options) if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x];
  expect(on, hasLength(1), reason: options.first);
  return on.single;
}

M8TheftProbe get _probe => M8TheftProbe.current!;

Future<ProviderContainer> _open(WidgetTester t, int seed, {Size size = const Size(392, 850), double top = 0}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2.0;
  t.view.padding = FakeViewPadding(top: top * 2);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8TheftEvidencePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8TheftDeal d) ok) => [for (var s = 0; s < 800; s++) s].firstWhere((s) => ok(m8TheftDeal(math.Random(s))));

/// The path a finger runs to follow [look]'s stealing wire (block pixels).
List<Offset> _along(M8Look look) => M8Geo.target(look)!;

/// A wrong trace: along the honest service cable.
List<Offset> _service() => M8Geo.service();

Future<void> _why(WidgetTester t, M8Why w) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason $w');
  await _pump(t, 400);
  await pickChoice(t, _onDeck(L.whyRight[w]!));
  await _pump(t, 1500);
}

/// A field deck (not a reason): the right card, ✓ (no zoom card).
Future<void> _field(WidgetTester t, List<String> right) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: right.first);
  await _pump(t, 400);
  await pickChoice(t, _onDeck(right), proceed: false);
  await _pump(t, 1200);
}

/// He comes: refuse him.
Future<void> _refuse(WidgetTester t, M8Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await pickChoice(t, _onDeck(L.coworker(p).right), proceed: false);
  await _pump(t, 2600);
}

/// He comes: listen to him (a wrong card, ✓).
Future<void> _listen(WidgetTester t, M8Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  final wrong = [for (final x in L.coworker(p).wrong) if (find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty) x];
  expect(wrong, isNotEmpty);
  await t.tap(find.byKey(ValueKey('deal-${wrong.first}')), warnIfMissed: false);
  await confirmChoice(t);
  await _pump(t, 800);
}

Future<void> _visit(WidgetTester t, int i) async {
  _probe.tapPremises(i);
  await _pump(t, 1400);
  expect(_probe.inLane, isFalse, reason: 'at premises $i');
}

Future<void> _gateOpen(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the gate deck');
  await _field(t, L.gate1Right);
  if (_probe.deal.refuses) await _field(t, L.gate2Right);
  await _why(t, M8Why.gate);
}

/// One stealing premises played right: the visit (the gate, the coworker if
/// he is dealt here), the trace, the cut and its reason, the tray.
Future<void> _theft(WidgetTester t, int i, {required bool Function() pushHere}) async {
  final d = _probe.deal;
  await _visit(t, i);
  if (d.looks[i].kind == M8Kind.bypass && d.access) await _gateOpen(t);
  if (pushHere()) {
    _probe.phone();
    await _pump(t, 200);
    expect(_probe.phoneOpen, isFalse, reason: 'the phone waited for him');
    await _refuse(t, d.push);
  }
  _probe.clip(_along(d.looks[i]));
  await _pump(t, 300);
  expect(_probe.run.clips[i], hasLength(1));
  _probe.cut();
  await _pump(t, 4000);
  expect(_probe.run.disconnected, contains(i));
  await _why(t, d.whyCut);
  await _pump(t, 1200);
  expect(_probe.trayOpen, isTrue);
  if (d.push == M8Push.tray && !_probe.run.caught.contains(L.caughtCall)) {
    _probe.sign();
    await _pump(t, 200);
    expect(_probe.run.seizure, isFalse, reason: 'the list waited for him');
    await _refuse(t, M8Push.tray);
  }
  _probe.sign();
  await _pump(t, 300);
  expect(_probe.run.seizure, isTrue);
  _probe.tapPaper(M8Paper.officer);
  await _field(t, L.timingRight);
  await _why(t, d.whyClose);
  await _pump(t, 1500);
}

void main() {
  group('rules', () {
    test('deals: 3-4 premises, 1-2 hooking, 0-1 bypass, exactly 1 shop; the access event only at a bypass house; every push and topic comes; plays differ', () {
      final seen = <String>{};
      final pushes = <M8Push>{}, whyCuts = <M8Why>{}, whyShops = <M8Why>{}, whyCloses = <M8Why>{};
      final ns = <int>{}, hooks = <int>{}, bypasses = <int>{};
      var access = 0, refuses = 0, follow = 0, trees = 0, normals = 0;
      final firsts = <M8Paper>{};
      for (var s = 0; s < 400; s++) {
        final d = m8TheftDeal(math.Random(s));
        final kinds = [for (final l in d.looks) l.kind];
        expect(d.n, inInclusiveRange(3, 4));
        final h = kinds.where((k) => k == M8Kind.hooking).length;
        final b = kinds.where((k) => k == M8Kind.bypass).length;
        expect(h, inInclusiveRange(1, 2));
        expect(b, inInclusiveRange(0, 1));
        expect(kinds.where((k) => k == M8Kind.shop), hasLength(1));
        expect(d.shop, isNonNegative);
        expect(d.theft, hasLength(h + b));
        if (d.access) expect(b, 1, reason: 'the gate is at the bypass house');
        expect({M8Why.video, M8Why.pole}, contains(d.whyCut));
        expect({M8Why.noFir, M8Why.explain}, contains(d.whyShop));
        expect({M8Why.seizure, M8Why.complaint}, contains(d.whyClose));
        expect(d.trayOrder.toSet(), M8Paper.values.toSet());
        for (final l in d.looks) {
          expect(l.hookRow, inInclusiveRange(0, 3));
          expect(l.hookCol, inInclusiveRange(0, 3));
          if (l.tree) trees++;
          if (l.kind == M8Kind.normal) normals++;
        }
        pushes.add(d.push);
        whyCuts.add(d.whyCut);
        whyShops.add(d.whyShop);
        whyCloses.add(d.whyClose);
        ns.add(d.n);
        hooks.add(h);
        bypasses.add(b);
        firsts.add(d.trayOrder.first);
        if (d.access) access++;
        if (d.refuses) refuses++;
        if (d.followUp) follow++;
        seen.add('${kinds.map((k) => k.index).join()}|${d.looks.map((l) => '${l.hookRow}${l.hookCol}${l.entry}${l.sag}${l.tree ? 1 : 0}').join()}|${d.push.name}|${d.trayOrder.map((p) => p.index).join()}');
      }
      expect(seen.length, greaterThan(380));
      expect(pushes, M8Push.values.toSet());
      expect({M8Why.video, M8Why.pole}, whyCuts);
      expect({M8Why.noFir, M8Why.explain}, whyShops);
      expect({M8Why.seizure, M8Why.complaint}, whyCloses);
      expect(ns, {3, 4});
      expect(hooks, {1, 2});
      expect(bypasses, {0, 1});
      expect(firsts, M8Paper.values.toSet(), reason: 'the tray order is dealt');
      expect(access, inInclusiveRange(40, 140), reason: 'the access event comes in about half the plays that have a bypass house');
      expect(refuses, inInclusiveRange(120, 280));
      expect(follow, inInclusiveRange(120, 280));
      expect(trees, greaterThan(300));
      expect(normals, greaterThan(40));
    });

    test('the trace judge: it must follow the stealing wire end to end and not much else (honest premises have nothing to follow)', () {
      for (final col in [0, 3]) {
        final look = M8Look(kind: M8Kind.hooking, hookRow: col, hookCol: col, entry: col % 2, sag: col % 3);
        final wire = M8Geo.hookWire(look);
        expect(m8Judge(wire, look).valid, isTrue, reason: 'the exact path');
        expect(m8Judge(wire.reversed.toList(), look).valid, isTrue, reason: 'from the house to the hook');
        // A wobbly finger, a few px off.
        final wobbly = [for (final (i, p) in wire.indexed) p + Offset(i.isEven ? 9 : -9, i % 3 == 0 ? 7 : -5)];
        expect(m8Judge(wobbly, look).valid, isTrue, reason: 'a finger, not a ruler');
        expect(m8Judge(wire.sublist(0, wire.length ~/ 2), look).valid, isFalse, reason: 'half of it: the house end is missing');
        expect(m8Judge(wire.sublist(wire.length ~/ 3), look).valid, isFalse, reason: 'no hook point in it');
        expect(m8Judge(_service(), look).valid, isFalse, reason: 'the honest service cable');
        // The whole picture scribbled over is not a clip of one wire.
        final scribble = <Offset>[];
        for (var y = 70.0; y < 330; y += 14) {
          scribble.addAll(y ~/ 14 % 2 == 0 ? [Offset(0, y), Offset(360, y)] : [Offset(360, y), Offset(0, y)]);
        }
        expect(m8Judge(scribble, look).valid, isFalse, reason: 'scribbling everywhere');
        expect(m8Judge(const [Offset(5, 5)], look).valid, isFalse);
      }
      const bypass = M8Look(kind: M8Kind.bypass);
      expect(m8Judge(M8Geo.loop(), bypass).valid, isTrue);
      expect(m8Judge(M8Geo.service(), bypass).valid, isFalse);
      expect(m8Judge(M8Geo.loop().sublist(0, 8), bypass).valid, isFalse);
      for (final k in [M8Kind.shop, M8Kind.normal]) {
        final l = M8Look(kind: k);
        expect(M8Geo.target(l), isNull);
        expect(m8Judge(M8Geo.service(), l).valid, isFalse);
        expect(m8Judge(M8Geo.hookWire(const M8Look(kind: M8Kind.hooking)), l).valid, isFalse);
      }
      // The hook wire and the service cable differ by a clear margin at the
      // pole end, so a finger can tell them apart.
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          expect((M8Geo.hookPoint(M8Look(kind: M8Kind.hooking, hookRow: r, hookCol: c)) - M8Geo.clamp).distance, greaterThan(m8Tol * 2));
        }
      }
    });

    M8TheftDeal deal({M8Push push = M8Push.order, bool followUp = false}) => M8TheftDeal(
          looks: const [
            M8Look(kind: M8Kind.hooking),
            M8Look(kind: M8Kind.bypass, hookCol: 2),
            M8Look(kind: M8Kind.shop),
            M8Look(kind: M8Kind.normal),
          ],
          access: false,
          refuses: false,
          followUp: followUp,
          push: push,
          whyCut: M8Why.video,
          whyShop: M8Why.noFir,
          whyClose: M8Why.seizure,
          trayOrder: M8Paper.values,
        );

    test('disconnect: no clip, a clip that misses the wire (slips, the clip stays), the shop and a house (slips), a valid clip cuts it; every clip is kept', () {
      final r = M8TheftRun(deal());
      final hook = r.deal.looks[0];
      expect(r.disconnect(0), Mk.noEvidence);
      expect(r.slips, 1);
      expect(r.saveClip(0, const [Offset(10, 10)]), isNull, reason: 'a single point is no clip');
      final bad = r.saveClip(0, _service())!;
      expect(bad.valid, isFalse);
      expect(r.clips[0], hasLength(1), reason: 'every clip is kept as a thumbnail');
      expect(r.disconnect(0), Mk.badClip);
      expect(r.disconnected, isEmpty);
      expect(r.clips[0], hasLength(1), reason: 'a failed disconnect keeps the clip');
      final good = r.saveClip(0, _along(hook))!;
      expect(good.valid, isTrue);
      expect(r.clips[0], hasLength(2));
      expect(r.disconnect(0), isNull);
      expect(r.disconnected, {0});
      expect(r.caught, contains(L.caughtClip));
      expect(r.disconnect(0), isNull, reason: 'already cut');
      expect(r.saveClip(0, _along(hook)), isNull, reason: 'no clip after the cut');
      // The shop and an honest house.
      expect(r.disconnect(2), Mk.innocentShop);
      expect(r.disconnect(3), Mk.innocentHouse);
      expect(r.slips, 4);
      // The bypass house: a loop clip.
      r.saveClip(1, M8Geo.loop());
      expect(r.disconnect(1), isNull);
      // Past three clips the oldest drops out.
      final q = M8TheftRun(deal());
      final ids = [for (var k = 0; k < 5; k++) q.saveClip(3, _service())!.id];
      expect([for (final c in q.clips[3]) c.id], ids.sublist(2));
    });

    test('talk, the shop, the gate and the tray: Sec 126 handled once; a needless talk is a slip; the complaint before the list and the notice form are slips; the premises closes when both papers are done', () {
      final r = M8TheftRun(deal());
      expect(r.needlessTalk(0), Mk.needlessTalk);
      expect(r.needlessTalk(3), Mk.needlessTalk);
      expect(r.needlessTalk(2), isNull, reason: 'the shop is where to talk');
      expect(r.slips, 2);
      expect(r.done, isFalse);
      r.shopHandled();
      expect(r.shopDone, isTrue);
      expect(r.caught, contains(L.caughtShop));
      expect(r.needlessTalk(2), isNull);
      r.gateResolved(1);
      expect(r.caught, contains(L.caughtGate));
      // The tray.
      expect(r.paper(M8Paper.officer), Mk.noSeizure);
      expect(r.paper(M8Paper.notice), Mk.noticeTheft);
      expect(r.slips, 4);
      expect(r.paper(M8Paper.seizure), isNull);
      expect(r.seizure, isTrue);
      expect(r.paper(M8Paper.officer), isNull);
      expect(r.trayDone, isFalse);
      r.complaintSent();
      expect(r.trayDone, isTrue);
      expect(r.caught, containsAll([L.caughtSeizure, L.caughtComplaint]));
      r.closeOut(0);
      expect(r.closed, {0});
      expect(r.trayDone, isFalse, reason: 'the next premises starts a fresh tray');
      expect(r.done, isFalse, reason: 'the bypass house is still open');
      r.closeOut(1);
      expect(r.done, isTrue);
      expect(r.percent, 100 - 15 * 4);
      expect(r.passed, isFalse, reason: 'four slips = 40 %, under the pass mark');
      expect(M8TheftRun(deal()).passed, isFalse);
      final one = M8TheftRun(deal())..pushSlip(Mk.pushOrder);
      for (final i in [0, 1]) {
        one.closeOut(i);
      }
      one.shopHandled();
      expect(one.passed, isTrue, reason: 'one slip = 85 %');
      // Every wrong card of a deck maps to a slip.
      expect(Mk.forCard(M8Deck.gate1, L.gateWrong.first), Mk.gateFight);
      expect(Mk.forCard(M8Deck.gate2, L.gateWrong.last), Mk.gateFight);
      expect(Mk.forCard(M8Deck.shop1, L.shopFirWrong.first), Mk.shopFir);
      expect(Mk.forCard(M8Deck.shop1, L.shopSilentWrong.first), Mk.shopSilent);
      expect(Mk.forCard(M8Deck.shop2, L.shopFinalWrong.first), Mk.shopFinal);
      expect(Mk.forCard(M8Deck.timing, L.timingWrong.first), Mk.complaintLate);
    });

    test('the coworker: every push is a slip (X2/B1: no deadly act here); four slips fail the pass mark? (55 %: four slips = 40 %)', () {
      for (final p in M8Push.values) {
        expect(Mk.push(p).deadly, isFalse);
        final r = M8TheftRun(deal(push: p));
        expect(r.pushSlip(Mk.push(p)), Mk.push(p));
        expect(r.slips, 1);
      }
      final r = M8TheftRun(deal());
      for (var i = 0; i < 4; i++) {
        r.pushSlip(Mk.pushOrder);
      }
      for (final i in [0, 1]) {
        r.closeOut(i);
      }
      r.shopHandled();
      expect(r.done, isTrue);
      expect(r.percent, 40);
      expect(r.passed, isFalse);
    });

    test('mistakes: none deadly (= the catalog\'s empty deadlyRules), keys, pictures, lesson points, the art folder all used', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.deadlyKeys, isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.2/m8_theft_evidence/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 7), reason: m.key);
      }
      const dir = 'assets/game/art/m8_theft_evidence/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory('assets/game/art/m8_theft_evidence').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8TheftPacks.keys, ['do_8_2_b']);
      expect(m8TheftQuickMs, 110000);
      // Every slip of the spec is a mistake (the spec's 11 rows).
      expect(Mk.all, hasLength(15));
    });

    test('Bangla: English digits, জল never পানি, base + nukta, owner terms (ডেড, ON/OFF, no «AB বন্ধ»), গ্লাভস', () {
      final all = <String>[
        L.intro,
        L.askWhere,
        L.taskTiles,
        L.taskRec,
        L.taskStop,
        L.taskGate,
        L.taskShop,
        L.taskTray,
        L.taskTiming,
        ...L.tapWhy,
        L.tilePhone,
        L.tileCut,
        L.tileTalk,
        L.rec,
        L.stop,
        L.back,
        L.clipLabel,
        L.paperSeizure,
        L.paperOfficer,
        L.paperNotice,
        L.paperSign,
        L.trayHead,
        L.ownerBubble,
        L.shopBubble,
        L.laneLabel,
        L.closeLabel,
        ...L.crewChips,
        ...L.crewChipsBypass,
        for (final w in M8Why.values) L.whyQ(w),
        ...L.allWhyRight,
        ...L.myths,
        ...L.gate1Right,
        ...L.gate2Right,
        ...L.shop1Right,
        ...L.shop2Right,
        ...L.timingRight,
        ...L.gateWrong,
        ...L.shopFirWrong,
        ...L.shopSilentWrong,
        ...L.shopFinalWrong,
        ...L.timingWrong,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M8Push.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.quick,
        L.fail,
        L.caughtClip,
        L.caughtSeizure,
        L.caughtComplaint,
        L.caughtShop,
        L.caughtGate,
        L.caughtCall,
      ];
      final pani = RegExp(r'(^|[\s,।!?—])পানি');
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(pani.hasMatch(l), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$|।)').hasMatch(l), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(l.contains('গ্লোভস'), isFalse, reason: l);
        expect(RegExp('(এলটি|এইচটি|কেভি)').hasMatch(l), isFalse, reason: l);
      }
    });

    test('libraries: same length, big enough; the coworker\'s cards alike; the decks\' wrong cards each map to a slip', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M8Why.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.wrongFor(w));
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.wrongFor(w), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final decks = {
        'gate1': (L.gate1Right, L.gateWrong),
        'gate2': (L.gate2Right, L.gateWrong),
        'shop1': (L.shop1Right, [...L.shopFirWrong, ...L.shopSilentWrong]),
        'shop2': (L.shop2Right, L.shopFinalWrong),
        'timing': (L.timingRight, L.timingWrong),
      };
      for (final e in decks.entries) {
        expectSameLength('deck ${e.key}', [...e.value.$1, ...e.value.$2]);
        expectLibrary('deck ${e.key}', e.value.$1, e.value.$2);
      }
      // The three shop cards always include the two wrong kinds across plays.
      final kinds = <DoMistake>{};
      for (var k = 0; k < 60; k++) {
        for (final o in dealChoices(L.shop1Right, [...L.shopFirWrong, ...L.shopSilentWrong], math.Random(k))) {
          if (!o.correct) kinds.add(Mk.forCard(M8Deck.shop1, o.textBn));
        }
      }
      expect(kinds, {Mk.shopFir, Mk.shopSilent});
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: the three pushes (M8-18 reworded the first); every spoken line listed for recording; lesson 8.2 backs the content', () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l82 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['module_number'] == 8 && l['chapter_number'] == 2);
      final text = _nk(jsonEncode(l82));
      expect(text, contains('প্রমাণ জোগাড় করা'));
      expect(text, contains('২৪ ঘন্টার মধ্যে থানায় বা পুলিশে অভিযোগ জানানো (অফিসারের মাধ্যমে)'));
      expect(text, contains('জব্দ তালিকা (Seizure List)'));
      expect(text, contains('পোল থেকে হুকিং তারটা'));
      expect(text, contains('এফআইআর (FIR) হয় না'));
      expect(text, contains('প্রভিশনাল'));
      expect(text, contains('বিনীতভাবে এই আইনের কথা বলুন'));
      expect(text, contains('চুরির ক্ষেত্রে (Sec 135) কোনো নোটিশ লাগে না'));
      expect(L.coworkerOrder.line, 'আগে লাইনটা কেটে দাও, ভিডিও-টিডিও পরে হবে।');
      expect(L.coworkerShop.line, 'দোকানদার তো চোর — থানায় FIR করে দাও।');
      expect(L.coworkerTray.line, 'ঝামেলা কোরো না, নোটিশ ধরিয়ে চলে চলো।');
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [for (final s in L.allCoworkers) s.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length));
      expect(L.newGuideLines, containsAll([for (final m in Mk.all) m.textBn]));
      expect(L.newGuideLines, containsAll([for (final w in M8Why.values) L.whyQ(w)]));
      expect(L.newGuideLines, containsAll([L.intro, L.askWhere, L.taskTiles, L.taskRec, L.taskStop, L.taskGate, L.taskShop, L.taskTray, L.taskTiming]));
      const shared = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};
      for (final cw in L.allCoworkers) {
        for (final a in cw.asks) {
          expect(L.newGuideLines.contains(a) || shared.contains(a), isTrue, reason: a);
        }
      }
      for (final p in M8Push.values) {
        expect(L.newGuideLines, contains(L.callHeld(p)));
      }
      expect(L.newGuideLines, containsAll([L.allSet, L.quick, L.fail]));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_theft_evidence: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the lane, the three tiles at a premises, the clips', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8TheftEvidencePage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_probe.inLane, isTrue);
      expect(find.byKey(const ValueKey('tiles')), findsNothing);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await _visit(t, 0);
      expect(find.byKey(const ValueKey('tiles')), findsOneWidget);
      for (final x in [L.tilePhone, L.tileCut, L.tileTalk]) {
        expect(_label(x), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('clips')), findsNothing, reason: 'no clip yet');
      expect(find.textContaining('হুকিং'), findsNothing, reason: 'no caption names it');
      expect(find.textContaining('বাইপাস'), findsNothing);
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
      expect(lines.every((l) => l.contains(L.askWhere)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // Plays whose push falls at each place; the access event and the follow-up on/off.
    final flowSeeds = [
      _seedWhere((d) => d.push == M8Push.order && d.whyCut == M8Why.video && d.whyClose == M8Why.seizure && !d.access && !d.followUp && d.n == 4),
      _seedWhere((d) => d.push == M8Push.shop && d.access && d.refuses && d.followUp && d.whyShop == M8Why.explain),
      _seedWhere((d) => d.push == M8Push.tray && d.whyCut == M8Why.pole && d.whyClose == M8Why.complaint && d.theft.length == 2),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): every stealing premises traced, cut, closed out; the shop; a reason each step; he is refused → pass', (t) async {
        final d = m8TheftDeal(math.Random(seed));
        final c = await _open(t, seed);
        var firstHooking = true;
        for (final i in d.theft) {
          await _theft(t, i, pushHere: () {
            final here = d.looks[i].kind == M8Kind.hooking && firstHooking && d.push == M8Push.order;
            if (d.looks[i].kind == M8Kind.hooking) firstHooking = false;
            return here;
          });
          if (_probe.run.done) break;
        }
        if (!_probe.run.done) {
          // The shop (the normal houses need nothing).
          await _visit(t, d.shop);
          _probe.talk();
          if (d.push == M8Push.shop) {
            await _pump(t, 200);
            expect(_probe.deck, isNull, reason: 'the talk waited for him');
            await _refuse(t, M8Push.shop);
            _probe.talk();
          }
          await _field(t, L.shop1Right);
          if (d.followUp) {
            expect(find.text(L.shopBubble), findsOneWidget);
            await _field(t, L.shop2Right);
          }
          await _why(t, d.whyShop);
        }
        await _pump(t, 3500);
        expect(_probe.run.done, isTrue);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.2/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.2/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtClip), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final hookSeed = _seedWhere((d) => d.push == M8Push.order && !d.access && d.looks.any((l) => l.kind == M8Kind.normal));

    testWidgets('disconnect with no clip, then with a clip on the honest cable: slip cards, the clip stays and is marked; every clip shows as a thumbnail, none says it is good', (t) async {
      final d = m8TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      final i = d.firstHooking;
      await _visit(t, i);
      // The coworker is dealt here: his hold first (the tiles wait for him).
      _probe.cut();
      await _pump(t, 200);
      expect(_probe.run.slips, 0, reason: 'the cut waited for him');
      await _refuse(t, M8Push.order);
      _probe.cut();
      await _pump(t, 500);
      expect(find.text(Mk.noEvidence.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      _probe.clip(_service());
      await _pump(t, 300);
      _probe.clip(_along(d.looks[i]).sublist(0, 6));
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('clips')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == L.clipLabel), findsNWidgets(2), reason: 'both clips are kept');
      _probe.cut();
      await _pump(t, 500);
      expect(find.text(Mk.badClip.textBn), findsOneWidget);
      expect(_probe.run.disconnected, isEmpty);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.noEvidence.key, Mk.badClip.key]);
      // A cut at an honest house and at the shop: slips as well.
      await _close(t, c);
    });

    testWidgets('the shop and an honest house cut as theft are slips; a talk at an honest house is a needless slip; three slips strike out', (t) async {
      final d = m8TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      final normal = d.looks.indexWhere((l) => l.kind == M8Kind.normal);
      await _visit(t, d.shop);
      _probe.cut();
      await _pump(t, 500);
      expect(find.text(Mk.innocentShop.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      _probe.back();
      await _pump(t, 600);
      await _visit(t, normal);
      _probe.cut();
      await _pump(t, 500);
      expect(find.text(Mk.innocentHouse.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      _probe.talk();
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.innocentShop.key, Mk.innocentHouse.key, Mk.needlessTalk.key]);
      await _close(t, c);
    });

    final shopSeed = _seedWhere((d) => d.push == M8Push.order && d.followUp);

    testWidgets('the shop: FIR and silence are slips, the follow-up "final" is a slip; the right cards go on', (t) async {
      final d = m8TheftDeal(math.Random(shopSeed));
      final c = await _open(t, shopSeed);
      await _visit(t, d.shop);
      _probe.talk();
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      expect(_probe.deck, M8Deck.shop1);
      final wrongs = [...L.shopFirWrong, ...L.shopSilentWrong].where((x) => find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty).toList();
      expect(wrongs, hasLength(2));
      await t.tap(find.byKey(ValueKey('deal-${wrongs.first}')), warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 600);
      expect(find.text(Mk.forCard(M8Deck.shop1, wrongs.first).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      await pickChoice(t, _onDeck(L.shop1Right), proceed: false);
      await _pump(t, 1200);
      expect(_probe.deck, M8Deck.shop2);
      await waitChoiceDeck(t);
      final fin = L.shopFinalWrong.firstWhere((x) => find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty);
      await t.tap(find.byKey(ValueKey('deal-$fin')), warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 600);
      expect(find.text(Mk.shopFinal.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      await pickChoice(t, _onDeck(L.shop2Right), proceed: false);
      await _pump(t, 1200);
      await _why(t, d.whyShop);
      expect(_probe.run.shopDone, isTrue);
      expect(_probe.inLane, isTrue, reason: 'back in the lane after the shop');
      await _close(t, c);
    });

    final gateSeed = _seedWhere((d) => d.access && d.refuses && d.push != M8Push.order);

    testWidgets('the gate: the owner\'s caption, fighting is a slip, the law then (if he still refuses) the police; then the reason', (t) async {
      final d = m8TheftDeal(math.Random(gateSeed));
      final c = await _open(t, gateSeed);
      await _visit(t, d.bypass);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      expect(find.text(L.ownerBubble), findsOneWidget);
      expect(find.byKey(const ValueKey('tiles')), findsNothing, reason: 'no tiles while the gate is shut');
      await waitChoiceDeck(t);
      final wrong = L.gateWrong.firstWhere((x) => find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty);
      await t.tap(find.byKey(ValueKey('deal-$wrong')), warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 600);
      expect(find.text(Mk.gateFight.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      await pickChoice(t, _onDeck(L.gate1Right), proceed: false);
      await _pump(t, 1200);
      expect(_probe.deck, M8Deck.gate2);
      await _field(t, L.gate2Right);
      await _why(t, M8Why.gate);
      expect(find.byKey(const ValueKey('tiles')), findsOneWidget);
      expect(find.text(L.ownerBubble), findsNothing);
      expect(_probe.run.gateDone, {d.bypass});
      await _close(t, c);
    });

    testWidgets('the tray: the complaint before the list and the notice form are slips; a late complaint card is the third slip and strikes out', (t) async {
      final seed = _seedWhere((d) => d.push == M8Push.order && !d.access && d.whyClose == M8Why.complaint);
      final d = m8TheftDeal(math.Random(seed));
      final c = await _open(t, seed);
      final i = d.firstHooking;
      await _visit(t, i);
      _probe.phone();
      await _pump(t, 200);
      await _refuse(t, M8Push.order);
      _probe.clip(_along(d.looks[i]));
      await _pump(t, 300);
      _probe.cut();
      await _pump(t, 4000);
      await _why(t, d.whyCut);
      await _pump(t, 1200);
      expect(_probe.trayOpen, isTrue);
      for (final p in M8Paper.values) {
        expect(find.byKey(ValueKey(p)), findsNothing);
      }
      expect(_label(L.paperSeizure), findsOneWidget);
      expect(_label(L.paperOfficer), findsOneWidget);
      expect(_label(L.paperNotice), findsOneWidget);
      _probe.tapPaper(M8Paper.officer);
      await _pump(t, 500);
      expect(find.text(Mk.noSeizure.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      _probe.tapPaper(M8Paper.notice);
      await _pump(t, 500);
      expect(find.text(Mk.noticeTheft.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      _probe.sign();
      await _pump(t, 300);
      _probe.tapPaper(M8Paper.officer);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      final late = L.timingWrong.firstWhere((x) => find.byKey(ValueKey('deal-$x')).evaluate().isNotEmpty);
      await t.tap(find.byKey(ValueKey('deal-$late')), warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 600);
      // The third slip strikes out (the late complaint's card is its mistake).
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((x) => x.key), [Mk.noSeizure.key, Mk.noticeTheft.key, Mk.complaintLate.key]);
      await _close(t, c);
    });

    testWidgets('listening to the coworker is a slip (his push at the first stealing premises); then the cut works', (t) async {
      final d = m8TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      await _visit(t, d.firstHooking);
      _probe.phone();
      await _pump(t, 200);
      await _listen(t, M8Push.order);
      expect(find.text(Mk.pushOrder.textBn), findsOneWidget);
      expect(_probe.phoneOpen, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      _probe.phone();
      await _pump(t, 300);
      expect(_probe.phoneOpen, isTrue);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.pushOrder.key);
      await _close(t, c);
    });

    testWidgets('real touches: a finger trace on the close-up is recorded in block pixels; REC then থামান saves a clip; a hold on বিচ্ছিন্ন করুন cuts, a short press does not', (t) async {
      final d = m8TheftDeal(math.Random(hookSeed));
      final c = await _open(t, hookSeed);
      final i = d.firstHooking;
      await _visit(t, i);
      // He is dealt here: the phone tile waits for him.
      await t.tap(_label(L.tilePhone));
      await _pump(t, 200);
      await _refuse(t, M8Push.order);
      await t.tap(_label(L.tilePhone));
      await _pump(t, 300);
      expect(_probe.phoneOpen, isTrue);
      expect(_label(L.rec), findsOneWidget);
      // A drag with no REC leaves no trace.
      const k = 392 / 360;
      final oy = _probe.oy;
      final wire = M8Geo.hookWire(d.looks[i]);
      Offset screen(Offset p) => Offset(p.dx * k, (p.dy + oy) * k);
      await t.dragFrom(screen(wire.first), const Offset(40, 40));
      expect(_probe.trace, isEmpty);
      await t.tap(_label(L.rec));
      await _pump(t, 200);
      expect(_probe.recording, isTrue);
      expect(_label(L.stop), findsOneWidget);
      final g = await t.startGesture(screen(wire.first));
      for (final p in wire.skip(1)) {
        await g.moveTo(screen(p));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _pump(t, 100);
      expect(_probe.trace.length, greaterThan(10));
      expect((_probe.trace.first - wire.first).distance, lessThan(10));
      await t.tap(_label(L.stop));
      await _pump(t, 400);
      expect(_probe.recording, isFalse);
      expect(_probe.phoneOpen, isFalse);
      expect(_probe.run.clips[i], hasLength(1));
      expect(_probe.run.clips[i].single.valid, isTrue, reason: 'a real finger run along the wire');
      expect(find.byType(MistakeCard), findsNothing, reason: 'nothing is judged when recording stops');
      // A short press on the cut tile: no slip, no cut (a hold hint is set).
      await t.tap(_label(L.tileCut));
      await _pump(t, 300);
      expect(_probe.run.disconnected, isEmpty);
      expect(_probe.run.slips, 0);
      // A real hold cuts it.
      final hold = await t.startGesture(t.getCenter(_label(L.tileCut)));
      await _pump(t, 1100);
      await hold.up();
      await _pump(t, 4000);
      expect(_probe.run.disconnected, contains(i));
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over every premises, a sweep over the three tiles, a tap on REC, then a short drag; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.push == M8Push.shop);
      final d = m8TheftDeal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(await _pumpUntilTrue(t, () => scene().showing, maxMs: 20000), isTrue, reason: 'idle in the lane');
      expect(scene().debugOptions, hasLength(d.n), reason: 'a sweep over all premises alike');
      await _visit(t, d.firstHooking);
      expect(await _pumpUntilTrue(t, () => scene().showing, maxMs: 20000), isTrue, reason: 'idle at the tiles');
      expect(scene().debugOptions, hasLength(3), reason: 'all three tiles, none pressed');
      _probe.phone();
      await _pump(t, 300);
      expect(await _pumpUntilTrue(t, () => scene().showing, maxMs: 20000), isTrue, reason: 'idle with the phone up');
      expect(scene().debugOptions, isEmpty);
      _probe.startRec();
      await _pump(t, 300);
      expect(await _pumpUntilTrue(t, () => scene().showing, maxMs: 20000), isTrue, reason: 'idle while recording');
      expect(scene().debugOptions, isEmpty, reason: 'a nudge, never a target');
      await _close(t, c);
    });

    testWidgets('fits a narrow 360 dp screen with a notch; every beat lays out without overflow', (t) async {
      final seed = _seedWhere((d) => d.push == M8Push.order && d.access);
      final d = m8TheftDeal(math.Random(seed));
      final c = await _open(t, seed, size: const Size(360, 640), top: 28);
      await _visit(t, d.bypass);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await waitChoiceDeck(t);
      await _field(t, L.gate1Right);
      if (d.refuses) await _field(t, L.gate2Right);
      await _why(t, M8Why.gate);
      _probe.clip(M8Geo.service());
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('clips')), findsOneWidget);
      _probe.phone();
      await _pump(t, 300);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
