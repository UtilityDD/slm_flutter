// Lesson 7.2 (ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট), কাজ 2 "দাবির পথ": the rules (a
// call before the ambulance arrives, else a slip; the report from the
// সরকারি হাসপাতাল or the কোম্পানির ডিসপেন্সারি, the ওষুধের দোকান a slip; the
// written notice into the ডাক বাক্স, the guard or going home first a slip; a
// fair letter signed at home, the commissioner then a needless claim; a bad
// letter to the commissioner, signing it a slip; papers kept by a swipe, left
// by walking on, any missing one slip in total; the union always fine), the
// deal, the libraries, the coworker (listening = a slip, never deadly: no
// deadly in 7.2, M7-6), the drawn places, and the level in the shell: the
// guide first, two full clean plays (a bad letter with a union stop and the
// desk; a fair letter signed) with every reason and the coworker refused, a
// late call, three slips, listening is a slip with no freeze, the drag waits
// for him on a fast play, the praise window takes no touch, and the gesture
// hand shows how (never what).
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
import 'package:slm_flutter/features/game/m7_claim_route.dart';
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
  rungId: '7.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7ClaimRoutePacks['do_7_2_b']!;
typedef L = M7ClaimRouteLines;
typedef Mk = M7ClaimRouteMistakes;
typedef N = M7ClaimNode;
typedef P = M7ClaimPaper;

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

Future<bool> _pumpUntil(WidgetTester t, bool Function() ok, {int maxMs = 10000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
}

bool _has(Finder f) => f.evaluate().isNotEmpty;
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
M7ClaimGeo get _geo => M7ClaimGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M7ClaimRun get _live => M7ClaimRouteProbe.run!;

/// The reason deck of the step just done: pick its right card.
Future<void> _reason(WidgetTester t) async {
  expect(await _pumpUntil(t, () => _has(find.byType(ChoiceDeck))), isTrue, reason: 'the reason deck');
  final w = _live.why!;
  await _pump(t, 400);
  await _pickRight(t, L.whyRight[w]!);
  await _pump(t, 1800);
}

/// Drag him from his crossing and drop him on [n].
Future<void> _drag(WidgetTester t, M7ClaimNode n) async {
  final map = _live.deal.map;
  final from = M7ClaimGeo.grab(_geo.at(map, _live.at));
  final to = M7ClaimGeo.grab(_geo.at(map, n));
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Future<void> _hold(WidgetTester t, Finder f) async {
  final g = await t.startGesture(t.getCenter(f));
  await _pump(t, kM7HoldMs + 300);
  await g.up();
  await _pump(t, 300);
}

/// Tap the phone and hold the call button.
Future<void> _call(WidgetTester t) async {
  await t.tapAt(_geo.phone.center * _k);
  await _pump(t, 300);
  expect(_label(L.callBtn), findsOneWidget);
  await _hold(t, _label(L.callBtn));
}

Future<void> _swipe(WidgetTester t, M7ClaimPaper p, {bool up = false}) async {
  final f = _label(L.paper(p));
  expect(f, findsWidgets, reason: L.paper(p));
  await t.drag(f.first, Offset(0, up ? -70 : 70));
  await _pump(t, 400);
}

Future<void> _pullDesk(WidgetTester t) async {
  await t.dragFrom(_geo.folder.center * _k, const Offset(0, -70));
  await _pump(t, 300);
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 600);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7ClaimRoutePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7ClaimDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7ClaimDeal(math.Random(s))));

/// The ride with the call in it; the ambulance lets him off.
Future<void> _ride(WidgetTester t) async {
  await _call(t);
  await _reason(t);
  expect(await _pumpUntil(t, () => _live.stage == M7ClaimStage.report, maxMs: 9000), isTrue);
  await _pump(t, 300);
}

Future<void> _refuse(WidgetTester t, M7ClaimPush p) async {
  expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

M7ClaimDeal _dealOf({M7ClaimLetter letter = M7ClaimLetter.refused, bool papersWhy = false}) => M7ClaimDeal(
      map: const M7ClaimMap(layout: 0),
      injury: M7ClaimInjury.temporary,
      letter: letter,
      contact: M7ClaimContact.supervisor,
      papersWhy: papersWhy,
    );

/// A run already off the ambulance (called in time, reason paid).
M7ClaimRun _runOf({M7ClaimLetter letter = M7ClaimLetter.refused, bool papersWhy = false}) {
  final r = M7ClaimRun(_dealOf(letter: letter, papersWhy: papersWhy));
  expect(r.call(), isTrue);
  r.paid();
  expect(r.rideOver(), isNull);
  return r;
}

void main() {
  group('rules', () {
    test('deals: layouts, mirror and nearer desk vary; fair about a third; no allowance only on a temporary injury; plays differ', () {
      final seen = <String>{};
      final layouts = <int>{};
      var fair = 0, mirror = 0, swap = 0, sup = 0;
      final letters = <M7ClaimLetter>{};
      for (var s = 0; s < 300; s++) {
        final d = m7ClaimDeal(math.Random(s));
        layouts.add(d.map.layout);
        if (d.fair) fair++;
        if (d.map.mirror) mirror++;
        if (d.map.swapDesks) swap++;
        if (d.contact == M7ClaimContact.supervisor) sup++;
        letters.add(d.letter);
        if (d.letter == M7ClaimLetter.noAllowance) expect(d.injury, M7ClaimInjury.temporary);
        expect(d.push, d.fair ? M7ClaimPush.bin : M7ClaimPush.accept);
        seen.add('${d.map.layout}${d.map.mirror}${d.map.swapDesks}${d.injury.index}${d.letter.index}${d.contact.index}');
      }
      expect(layouts, {0, 1, 2});
      expect(fair, inInclusiveRange(70, 130));
      for (final x in [mirror, swap, sup]) {
        expect(x, inInclusiveRange(110, 190));
      }
      expect(letters, M7ClaimLetter.values.toSet());
      expect(seen.length, greaterThan(80));
    });

    test('layouts: ten distinct crossings; the office stops side by side; every node found where it is', () {
      for (var l = 0; l < m7ClaimLayouts.length; l++) {
        for (final mirror in [false, true]) {
          for (final swap in [false, true]) {
            final m = M7ClaimMap(layout: l, mirror: mirror, swapDesks: swap);
            final slots = {for (final n in N.values) m.slotOf(n)};
            expect(slots, hasLength(N.values.length));
            final a = m.slotOf(N.mailbox), b = m.slotOf(N.guard);
            expect(a.row, b.row);
            expect((a.col - b.col).abs(), 1);
            for (final n in N.values) {
              expect(m.nodeAt(m.slotOf(n)), n);
            }
          }
        }
      }
    });

    test('the ride: a call before the ambulance arrives is right (its reason); none = the late-call slip', () {
      final r = M7ClaimRun(_dealOf());
      expect(r.canDrag, isFalse);
      expect(r.call(), isTrue);
      expect(r.call(), isFalse);
      expect(r.why, M7ClaimWhy.call);
      expect(r.caught, contains(L.caughtCall));
      r.paid();
      expect(r.rideOver(), isNull);
      expect((r.stage, r.at, r.slips), (M7ClaimStage.report, N.junction, 0));
      final late = M7ClaimRun(_dealOf());
      expect(late.rideOver(), Mk.lateCall);
      expect(late.calledLate, isTrue);
      expect(late.call(), isFalse, reason: 'he calls from bed; no reason');
      expect(late.slips, 1);
    });

    test('report: hospital or dispensary right (the report and the bill slide out after the reason); the shop, home and the commissioner slips; others cost nothing', () {
      final r = _runOf();
      expect(r.arrive(N.shop).mistake, Mk.shopReport);
      expect(r.arrive(N.home).mistake, Mk.noReport, reason: 'the report is still to come: its own card');
      expect(r.arrive(N.commissioner).mistake, Mk.earlyClaim, reason: 'no answer from the company yet');
      expect(r.at, N.junction, reason: 'a slip: he goes back');
      final back = r.arrive(N.mailbox);
      expect((back.kind, back.line), (M7ArriveKind.back, L.notNow));
      expect(r.arrive(N.junction).kind, M7ArriveKind.stay);
      expect(r.slips, 3);
      expect(r.arrive(N.dispensary).kind, M7ArriveKind.right);
      expect((r.stage, r.why), (M7ClaimStage.notice, M7ClaimWhy.report));
      expect(r.tray, isEmpty);
      expect(r.canDrag, isFalse, reason: 'the reason first');
      r.paid();
      expect(r.tray, [P.report, P.bill]);
      final h = _runOf();
      expect(h.arrive(N.hospital).kind, M7ArriveKind.right);
    });

    test('notice: the mailbox right; the guard and home slips; papers left at a stop are lost when he walks on', () {
      final r = _runOf()..arrive(N.hospital);
      r.paid();
      expect(r.file(P.report), isTrue);
      expect(r.arrive(N.guard).mistake, Mk.guardNotice);
      expect(r.tray, [P.bill], reason: 'a slip: he never left');
      expect(r.arrive(N.home).mistake, Mk.noNotice);
      expect(r.arrive(N.commissioner).mistake, Mk.earlyClaim);
      expect(r.arrive(N.mailbox).kind, M7ArriveKind.right);
      expect(r.lost, {P.bill});
      expect(r.folder, [P.report]);
      r.paid();
      expect(r.tray, [P.notice]);
      expect(r.caught, containsAll([L.caughtReport, L.caughtNotice]));
    });

    test('the union is always fine (no cost, tagged once); the commissioner before the answer a slip; the letter comes home; it must be read before he leaves', () {
      final r = _runOf()..arrive(N.hospital);
      r.paid();
      expect(r.arrive(N.union).kind, M7ArriveKind.union);
      expect(r.at, N.union);
      expect(r.lost, {P.report, P.bill});
      r.arrive(N.mailbox);
      r.paid();
      final early = r.arrive(N.commissioner);
      expect((early.kind, early.mistake), (M7ArriveKind.slip, Mk.earlyClaim), reason: 'no letter yet: a needless early claim');
      expect(r.at, N.mailbox, reason: 'a slip: he stays at the mailbox');
      expect(r.arrive(N.home).kind, M7ArriveKind.home);
      expect(r.stage, M7ClaimStage.letter);
      expect(r.canDrag, isFalse);
      expect(r.file(P.letter), isFalse, reason: 'unread');
      expect(r.read(), isTrue);
      expect(r.stage, M7ClaimStage.claim);
      expect(r.slips, 1);
      expect(r.caught.where((c) => c == L.caughtUnion), hasLength(1));
    });

    test('a bad letter: signing a slip; the commissioner right; the desk pulls papers one by one; a missing paper = one slip; the letter stays at home', () {
      final r = _runOf()..arrive(N.hospital);
      r.paid();
      r
        ..file(P.report)
        ..file(P.bill)
        ..arrive(N.mailbox);
      r.paid();
      r
        ..file(P.notice)
        ..arrive(N.home)
        ..read();
      expect(r.sign(), Mk.acceptLess);
      expect(r.signed, isFalse);
      expect(r.arrive(N.union).kind, M7ArriveKind.union);
      expect(r.letterHere, isFalse);
      expect(r.arrive(N.home).kind, M7ArriveKind.fine);
      expect(r.letterHere, isTrue, reason: 'the letter lies at home');
      // Walks off to the commissioner without a copy of the letter.
      expect(r.arrive(N.commissioner).kind, M7ArriveKind.desk);
      expect(r.stage, M7ClaimStage.desk);
      expect(r.canDrag, isFalse);
      expect(r.pull(), isFalse);
      expect(r.pull(), isFalse);
      expect(r.pull(), isTrue);
      expect(r.desk, [P.report, P.bill, P.notice]);
      expect(r.missing, [P.letter]);
      expect(r.check(), Mk.paperMissing);
      expect(r.check(), isNull, reason: 'one slip in total');
      expect(r.why, M7ClaimWhy.claim);
      r.paid();
      expect(r.done, isTrue);
      expect(r.slips, 2);
      expect(r.passed, isTrue);
      expect(r.caught, contains(L.caughtClaim));
    });

    test('a bad letter with every paper kept: the final reason by the deal; an empty folder checks at the first pull', () {
      for (final pw in [false, true]) {
        final r = _runOf(papersWhy: pw)..arrive(N.hospital);
        r.paid();
        r
          ..file(P.report)
          ..file(P.bill)
          ..arrive(N.mailbox);
        r.paid();
        r
          ..file(P.notice)
          ..arrive(N.home)
          ..read();
        expect(r.file(P.letter), isTrue);
        expect(r.file(P.letter), isFalse);
        expect(r.letterHere, isTrue, reason: 'the letter stays to be signed or not');
        r.arrive(N.commissioner);
        while (r.pull() == false) {}
        expect(r.check(), isNull);
        expect(r.why, pw ? M7ClaimWhy.papers : M7ClaimWhy.claim);
        expect(r.caught, contains(L.caughtPapers));
      }
      final e = _runOf()..arrive(N.hospital);
      e.paid();
      e.arrive(N.mailbox);
      e.paid();
      e
        ..arrive(N.home)
        ..read()
        ..arrive(N.commissioner);
      expect(e.pull(), isTrue);
      expect(e.check(), Mk.paperMissing);
    });

    test('a fair letter: the commissioner a needless claim; signing ends it; the folder checked (the letter copy too)', () {
      final r = _runOf(letter: M7ClaimLetter.fair)..arrive(N.hospital);
      r.paid();
      r
        ..file(P.report)
        ..file(P.bill)
        ..arrive(N.mailbox);
      r.paid();
      r
        ..file(P.notice)
        ..arrive(N.home)
        ..read();
      expect(r.arrive(N.commissioner).mistake, Mk.needlessClaim);
      expect(r.at, N.home);
      expect(r.file(P.letter), isTrue, reason: 'the copy before the signature');
      expect(r.sign(), isNull);
      expect(r.signed, isTrue);
      expect(r.check(), isNull);
      expect(r.why, M7ClaimWhy.papers);
      r.paid();
      expect(r.done, isTrue);
      expect(r.caught, containsAll([L.caughtFair, L.caughtPapers]));
      // Signed with no copy of the letter: that paper is missing.
      final nc = _runOf(letter: M7ClaimLetter.fair)..arrive(N.hospital);
      nc.paid();
      nc
        ..file(P.report)
        ..file(P.bill)
        ..arrive(N.mailbox);
      nc.paid();
      nc
        ..file(P.notice)
        ..arrive(N.home)
        ..read()
        ..sign();
      expect(nc.missing, [P.letter]);
      expect(nc.check(), Mk.paperMissing);
      expect(nc.why, isNull, reason: 'no papers reason after a missing paper');
      expect(nc.done, isTrue);
      expect(nc.caught, isNot(contains(L.caughtPapers)));
      // A paper left behind: one slip, no reason fits, the play ends.
      final m = _runOf(letter: M7ClaimLetter.fair)..arrive(N.hospital);
      m.paid();
      m.arrive(N.mailbox);
      m.paid();
      m
        ..arrive(N.home)
        ..read()
        ..sign();
      expect(m.check(), Mk.paperMissing);
      expect(m.done, isTrue);
    });

    test('listening is the act he pushes (X2/B1) — a slip, never deadly; a binned bill is not charged twice and never counts as kept', () {
      expect(Mk.push(M7ClaimPush.accept), Mk.acceptLess);
      expect(Mk.push(M7ClaimPush.bin), Mk.binBill);
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'no deadly in lesson 7.2 (M7-6)');
      final r = _runOf(letter: M7ClaimLetter.fair)..arrive(N.hospital);
      r.paid();
      r.file(P.bill);
      expect(r.listen(M7ClaimPush.bin), Mk.binBill);
      expect(r.folder, isNot(contains(P.bill)));
      r.file(P.report);
      r.arrive(N.mailbox);
      r.paid();
      r
        ..file(P.notice)
        ..arrive(N.home)
        ..read()
        ..file(P.letter)
        ..sign();
      expect(r.missing, isEmpty);
      expect(r.allKept, isFalse, reason: 'the bill went in the bin');
      expect(r.finalWhy, isNull, reason: 'no reason fits a binned bill (X6)');
      expect(r.check(), isNull);
      expect(r.slips, 1);
      expect(r.caught, isNot(contains(L.caughtPapers)));
      expect(r.why, isNot(M7ClaimWhy.papers));
      expect(r.done, isTrue);
    });

    test('three slips: 55; four: 40', () {
      final r = _runOf();
      for (var i = 0; i < 3; i++) {
        r.arrive(N.shop);
      }
      expect(r.percent, 55);
      r.arrive(N.shop);
      expect(r.percent, 40);
    });

    test('English digits only; jol not pani; every mistake has its picture and every picture is used; keys unique; lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        L.notNow,
        L.readFirst,
        L.unionHere,
        for (final c in M7ClaimContact.values) ...[L.contact(c), L.whyCall(c)],
        for (final p in P.values) L.paper(p),
        for (final i in M7ClaimInjury.values) L.injury(i),
        for (final l in M7ClaimLetter.values)
          for (final i in M7ClaimInjury.values) L.letterBody(l, i),
        ...L.whyQ.values,
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final p in M7ClaimPush.values) L.callHeld(p),
        for (final m in Mk.all) m.textBn,
        L.allSet,
        L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp('(?<![ঀ-৿])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'nukta as base + ় : $l');
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.2/m7_claim_route/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      const dir = 'assets/game/art/m7_claim_route/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7ClaimRoutePacks.keys, ['do_7_2_b']);
    });

    test('lesson text: myth 2 word for word; the quoted steps are in today\'s lesson 7.2', () {
      final raw = File('tool/all_training_chapters_bn.json').readAsStringSync().replaceAll('য়', 'য়').replaceAll('ড়', 'ড়');
      expect(raw.contains(L.coworkerAccept.line), isTrue);
      for (final q in ['সরকারি বা কোম্পানির ডাক্তার', 'লিখিতভাবে দুর্ঘটনার নোটিশ', 'লেবার কমিশনারের কাছে আবেদন', 'চিকিৎসার বিল', 'সুপারভাইজার বা কর্তৃপক্ষকে জানান']) {
        expect(raw.contains(q), isTrue, reason: q);
      }
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final w in M7ClaimWhy.values) {
        expectLibrary('why $w', L.whyRight[w]!, L.myths);
        expect(L.question(w, M7ClaimContact.authority), isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(L.whyRight[w]!, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his two new lines and the guide\'s new lines are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'কোম্পানি যা দেবে, সেটাই মেনে নিতে হবে। এর বিরুদ্ধে কিছু করার নেই।',
        'বিল-টিল রেখে কী হবে? ফেলে দাও, কোম্পানি তো দেবেই।',
      ]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, L.notNow, L.readFirst, L.unionHere, ...L.whyQ.values, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      for (final c in M7ClaimContact.values) {
        expect(L.newGuideLines, contains(L.whyCall(c)));
      }
      for (final p in M7ClaimPush.values) {
        expect(L.newGuideLines, contains(L.callHeld(p)));
      }
      expect(LearnVoice.resolve(L.quick), isNotNull, reason: 'the quick line is already recorded');
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_claim_route: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: crossings on the scene, under the paper tray, clear of the folder, the phone and the guide; a drop finds its own stop', () {
      for (final h in [640.0, 700.0, 780.0, 900.0]) {
        final g = M7ClaimGeo.forScene(h, 0);
        final guide = Rect.fromLTRB(244, h - 8 - 160, 360, h);
        for (var r = 0; r < 3; r++) {
          for (var c = 0; c < 4; c++) {
            final p = g.slot((col: c, row: r));
            final fig = M7ClaimGeo.figure(p);
            expect(fig.top, greaterThan(M7ClaimGeo.tray.bottom), reason: 'h $h: $p under the tray');
            expect(fig.left >= 0 && fig.right <= 360, isTrue);
            for (final box in [g.folder, g.phone, guide]) {
              final near = Offset(p.dx.clamp(box.left, box.right), p.dy.clamp(box.top, box.bottom));
              expect((near - p).distance, greaterThan(M7ClaimGeo.nodeR), reason: 'h $h: $p near $box');
            }
          }
        }
        expect(g.folder.overlaps(g.phone), isFalse);
        expect(M7ClaimGeo.letter.contains(M7ClaimGeo.sign.center), isTrue);
        for (var i = 0; i < 2; i++) {
          expect(M7ClaimGeo.tray.contains(M7ClaimGeo.paper(i, 2).center), isTrue);
        }
        expect(M7ClaimGeo.paper(0, 2).overlaps(M7ClaimGeo.paper(1, 2)), isFalse);
        // The nearest crossing to each crossing is itself.
        if (h >= 700) expect(g.rowGap, greaterThan(M7ClaimGeo.nodeR * 2));
      }
      final (mid, dir) = m7RoadPoint(Offset.zero, const Offset(10, 10), 0.25);
      expect(mid, const Offset(5, 0));
      expect(dir, const Offset(1, 0));
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

    testWidgets('the guide comes first: a tap does not skip him; then the ride, the phone glowing', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7ClaimRoutePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 300);
      expect(_label(L.phoneLabel), findsOneWidget);
      expect(_live.stage, M7ClaimStage.ride);
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
        await _pump(t, 300);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.task(M7ClaimStage.ride))), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    final badSeed = _seedWhere((d) => !d.fair && d.papersWhy);
    testWidgets('flow (bad letter, seed $badSeed): call, report, notice, letter, he is refused, a union stop, the desk → pass', (t) async {
      final c = await _open(t, badSeed);
      await _ride(t);
      await _drag(t, N.hospital);
      expect(_live.at, N.hospital);
      await _reason(t);
      expect(_live.tray, [P.report, P.bill]);
      await _swipe(t, P.report);
      await _swipe(t, P.bill);
      expect(_live.folder, [P.report, P.bill]);
      await _drag(t, N.mailbox);
      await _reason(t);
      await _swipe(t, P.notice);
      await _drag(t, N.home);
      expect(_live.stage, M7ClaimStage.letter);
      expect(await _pumpUntil(t, () => _has(_label(L.paper(P.letter))), maxMs: 3000), isTrue, reason: 'the letter after the calendar');
      await _swipe(t, P.letter, up: true);
      expect(_live.stage, M7ClaimStage.claim);
      expect(find.text(L.letterBody(_live.deal.letter, _live.deal.injury)), findsOneWidget);
      await _refuse(t, M7ClaimPush.accept);
      await _swipe(t, P.letter);
      expect(_live.folder, contains(P.letter));
      await _drag(t, N.union);
      expect(_live.at, N.union);
      await _drag(t, N.commissioner);
      expect(_live.stage, M7ClaimStage.desk);
      for (var i = 0; i < 4; i++) {
        await _pullDesk(t);
      }
      await _reason(t);
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['7.2/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['7.2/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtNo), findsOneWidget);
      expect(find.text(L.caughtUnion), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    final fairSeed = _seedWhere((d) => d.fair);
    testWidgets('flow (fair letter, seed $fairSeed): he comes at the doctor\'s stop and is refused; signed at home → pass', (t) async {
      final c = await _open(t, fairSeed);
      await _ride(t);
      await _drag(t, N.dispensary);
      await _reason(t);
      await _refuse(t, M7ClaimPush.bin);
      await _swipe(t, P.report);
      await _swipe(t, P.bill);
      await _drag(t, N.mailbox);
      await _reason(t);
      await _swipe(t, P.notice);
      await _drag(t, N.home);
      await _pumpUntil(t, () => _has(_label(L.paper(P.letter))), maxMs: 3000);
      await _swipe(t, P.letter, up: true);
      await _swipe(t, P.letter);
      expect(_live.folder, contains(P.letter));
      await _hold(t, _label(L.signLabel));
      expect(_live.signed, isTrue);
      await _reason(t);
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['7.2/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(L.caughtFair), findsOneWidget);
      expect(find.text(L.caughtPapers), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('no call before the ambulance arrives: the late-call card; then the report goes on', (t) async {
      final c = await _open(t, 7);
      await _pump(t, kM7RideMs + 500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.lateCall.textBn), findsOneWidget);
      await _gotIt(t);
      expect(_live.stage, M7ClaimStage.report);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no reason after a late call');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.lateCall.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (late call, the shop twice); a slip sends him back', (t) async {
      final c = await _open(t, 7);
      await _pump(t, kM7RideMs + 500);
      await _gotIt(t);
      await _drag(t, N.shop);
      expect(find.text(Mk.shopReport.textBn), findsOneWidget);
      await _gotIt(t);
      expect(_live.at, N.junction);
      await _drag(t, N.shop);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final badFast = _seedWhere((d) => !d.fair);
    Future<void> toLetter(WidgetTester t) async {
      await _ride(t);
      await _drag(t, N.hospital);
      await _reason(t);
      await _drag(t, N.mailbox);
      await _reason(t);
      await _drag(t, N.home);
      await _pumpUntil(t, () => _has(_label(L.paper(P.letter))), maxMs: 3000);
      await _swipe(t, P.letter, up: true);
    }

    testWidgets('listening to him (myth 2) is a slip — no freeze, no deadly (M7-6)', (t) async {
      final c = await _open(t, badFast);
      await toLetter(t);
      expect(await _pumpUntil(t, () => _has(find.byType(CoworkerPeek)), maxMs: 6000), isTrue);
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerAccept.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.acceptLess.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('a fast play: the first drag after reading waits for him; he cuts in at once', (t) async {
      final c = await _open(t, badFast);
      await toLetter(t);
      await _drag(t, N.commissioner);
      expect(_has(find.byType(CoworkerPeek)), isTrue, reason: 'he cuts in');
      expect(_live.at, N.home, reason: 'the drag did nothing');
      await _pumpUntil(t, () => _has(find.byType(ChoiceDeck)));
      await _pickRight(t, L.coworkerAccept.right);
      await _pump(t, 2600);
      await _drag(t, N.commissioner);
      expect(_live.stage, M7ClaimStage.desk, reason: 'after him the drag works');
      // Nothing was kept: the first pull checks at once.
      await _pullDesk(t);
      expect(find.text(Mk.paperMissing.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.paperMissing.key);
      await _gotIt(t);
      await _reason(t);
      await _pump(t, 2000);
      expect(find.byType(LevelPassPanel), findsOneWidget, reason: 'one slip: still a pass');
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final c = await _open(t, badFast);
      await _ride(t);
      await _drag(t, N.hospital);
      expect(_live.roundDone, isTrue);
      await _drag(t, N.shop);
      expect(_live.at, N.hospital, reason: 'he did not move');
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a hold on the call button; on the map a nudge that presses nothing', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 7);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(scene().showing, isFalse, reason: 'the ride: a timed judgement, no hand');
      await t.tapAt(_geo.phone.center * _k);
      await _pump(t, 300);
      expect(_label(L.callBtn), findsOneWidget);
      // Three short taps on the call button (a hold is wanted): the hand shows the hold.
      for (var k = 0; k < 3; k++) {
        await t.tap(_label(L.callBtn), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(_live.called, isFalse, reason: 'a tap is not a call');
      expect(_label(L.callBtn), findsOneWidget, reason: 'the phone stays open');
      expect(scene().showing, isTrue, reason: 'three misses: the hand at once');
      var ring = false;
      final callAt = t.getCenter(_label(L.callBtn));
      final box = t.renderObject<RenderBox>(find.byType(IdleHint).first);
      for (var i = 0; i < 30 && !ring; i++) {
        final f = scene().debugFrame;
        if (f != null && f.ring != null) {
          ring = true;
          expect((box.localToGlobal(f.tip) - callAt).distance, lessThan(30), reason: 'the hold sits on the call button');
        }
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(ring, isTrue, reason: 'a hold (a ring fills), not a tap');
      await _pump(t, kM7RideMs);
      // The late-call card, then the map.
      if (_has(find.text(MistakeLines.gotIt))) await _gotIt(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the map');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      expect(scene().debugOptions, isEmpty);
      await _close(t, c);
    });
  });
}
