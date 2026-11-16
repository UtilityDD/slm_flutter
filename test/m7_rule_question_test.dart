// Lesson 7.1 (ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন), কাজ 2 "প্রশ্ন করার
// অধিকার": the rules (an order obeyed when the lane breaks a rule = slip; a
// call on a lawful order = needless-stop slip; a wrong rulebook page = slip
// and the book stays open; the right page questions it and the fix plays
// after the reason; no deadly in 7.1, M7-6), the deal (6 orders, every kind,
// one repeated in its other version, 2–4 unlawful), the libraries, the
// lesson text (live CEA 2023 numbers, myth 1 word for word), the drawn
// places, and the level in the shell: the guide first, a full clean play (a
// close-up, both reasons, the coworker refused), the two-step 'ঠিক আছে', the
// coworker holding the first touch (listening = slip, the order still
// waits), three slips, a slip never freezes, and the gesture hand.
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
import 'package:slm_flutter/features/game/m7_rule_question.dart';
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
  rungId: '7.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '7.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m7RuleQuestionPacks['do_7_1_b']!;
typedef L = M7RuleQuestionLines;
typedef Mk = M7RuleQuestionMistakes;

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

Future<bool> _pumpUntil(WidgetTester t, bool Function() ok, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (ok()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return ok();
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
M7RqGeo get _geo => M7RqGeo.forScene(360 * 850 / 392, 0);
M7RqRun get _live => M7RuleQuestionProbe.run!;

Future<void> _deciding(WidgetTester t) async {
  expect(await _pumpUntil(t, () => _live.stage == M7RqStage.deciding && !_live.roundDone), isTrue, reason: 'the order is heard');
  await _pump(t, 200);
}

/// 'ঠিক আছে' through its preview: tap → ✓.
Future<void> _ok(WidgetTester t) async {
  await t.tap(_label(L.ok));
  await _pump(t, 200);
  expect(await confirmChoice(t), isTrue, reason: 'the preview of ঠিক আছে');
  await _pump(t, 400);
}

/// Hold 'সুপারভাইজারকে ফোন' through (1.2 s), then the book opens.
Future<void> _call(WidgetTester t) async {
  final g = await t.startGesture(t.getCenter(_label(L.call)));
  await _pump(t, 1400);
  await g.up();
  expect(await _pumpUntil(t, () => _live.stage == M7RqStage.paging), isTrue, reason: 'the rulebook opens');
  await _pump(t, 300);
}

Offset _bookCenter(WidgetTester t) => t.getCenter(_label(L.bookLabel));

/// Swipe the booklet to [page] (left = the next page).
Future<void> _pageTo(WidgetTester t, M7RqPage page) async {
  // Back to the first page, then forward.
  for (var i = 0; i < 5; i++) {
    await t.dragFrom(_bookCenter(t), const Offset(140, 0));
    await _pump(t, 200);
  }
  for (var i = 0; i < page.index; i++) {
    await t.dragFrom(_bookCenter(t), const Offset(-140, 0));
    await _pump(t, 200);
  }
  expect(find.text(L.pageTitle(page)), findsOneWidget, reason: 'the page $page is open');
}

/// Drag the open page onto the phone.
Future<void> _showPage(WidgetTester t) async {
  final from = _bookCenter(t);
  final to = t.getCenter(_label(L.phoneHead));
  await t.dragFrom(from, to - from);
  await _pump(t, 600);
}

Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7RuleQuestionPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7RqDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7RqDeal(math.Random(s))));

/// He comes on the first decision touch: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty, maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// One order played right (a close-up on the first; the coworker refused if
/// he is dealt on it).
Future<void> _play(WidgetTester t, M7RqDeal d, int i, {required bool firstOk}) async {
  final o = d.orders[i];
  await _deciding(t);
  expect(_live.index, i);
  if (i == 0) {
    await _tapAt(t, _geo.hit(o.kind).center);
    expect(find.byKey(const ValueKey('closeup-close')), findsOneWidget, reason: 'a close-up of ${o.kind}');
    await t.tap(find.byKey(const ValueKey('closeup-close')));
    await _pump(t, 300);
  }
  if (d.coworkerAt == i) {
    // The first touch waits for him.
    if (o.lawful) {
      await t.tap(_label(L.ok));
    } else {
      await t.tapAt(t.getCenter(_label(L.call)));
    }
    await _pump(t, 200);
    expect(find.byType(CardPreviewOverlay), findsNothing);
    await _refuse(t);
  }
  if (o.lawful) {
    await _ok(t);
    if (firstOk) {
      expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'কেন মেনে নিলেন?');
      await _pump(t, 400);
      await _pickRight(t, L.whyOkRight[o.kind]!);
    }
    await _pump(t, 2000);
  } else {
    await _call(t);
    await _pageTo(t, m7RqPageFor(o.kind));
    await _showPage(t);
    expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${o.kind}');
    expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'কেন প্রশ্ন করলেন?');
    await _pump(t, 400);
    await _pickRight(t, L.whyAskRight[o.kind]!);
    await _pump(t, 2400);
  }
}

M7RqDeal _dealOf(List<M7RqOrder> orders, {int coworkerAt = 5}) => M7RqDeal(orders: orders, coworkerAt: coworkerAt);

const _allLawful = [
  M7RqOrder(kind: M7RqKind.helper, lawful: true),
  M7RqOrder(kind: M7RqKind.pillar, lawful: true),
  M7RqOrder(kind: M7RqKind.earth, lawful: true),
  M7RqOrder(kind: M7RqKind.balcony, lawful: true),
  M7RqOrder(kind: M7RqKind.kit, lawful: true),
  M7RqOrder(kind: M7RqKind.helper, lawful: false, person: 1),
];

String _nukta(String s) => s.replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');

Map<String, dynamic> _lesson71() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List;
  return (all.firstWhere((c) => c['id'] == '7.1') as Map).cast<String, dynamic>();
}

void main() {
  group('rules', () {
    test('deals: 6 orders, every kind, one repeated (its second version dealt on its own, never twice in a row), 2–4 unlawful; plays differ', () {
      final seen = <String>{};
      final at = <int>{};
      final unlawful = <int>{};
      final repeats = <M7RqKind>{};
      var plateRight = 0, neutralLeft = 0, firstLawful = 0, sameVersion = 0;
      final variants = <String>{};
      for (var s = 0; s < 300; s++) {
        final d = m7RqDeal(math.Random(s));
        expect(d.orders, hasLength(kM7RqOrders));
        expect(d.orders.map((o) => o.kind).toSet(), M7RqKind.values.toSet());
        final counts = <M7RqKind, int>{};
        for (final o in d.orders) {
          counts[o.kind] = (counts[o.kind] ?? 0) + 1;
        }
        final rep = counts.entries.where((e) => e.value == 2).map((e) => e.key).toList();
        expect(rep, hasLength(1));
        final two = d.orders.where((o) => o.kind == rep.single).toList();
        if (two.first.lawful) firstLawful++;
        if (two.first.lawful == two.last.lawful) sameVersion++;
        for (var i = 1; i < kM7RqOrders; i++) {
          expect(d.orders[i].kind == d.orders[i - 1].kind, isFalse, reason: 'never the same kind twice in a row');
        }
        if (rep.single == M7RqKind.helper) {
          expect(two.map((o) => o.person).toList(), [0, 1], reason: 'the repeat is a second helper');
        }
        expect(d.unlawful, inInclusiveRange(2, 4));
        expect(d.coworkerAt, inInclusiveRange(0, kM7RqOrders - 1));
        at.add(d.coworkerAt);
        unlawful.add(d.unlawful);
        repeats.add(rep.single);
        if (d.plateRight) plateRight++;
        if (d.neutralLeft) neutralLeft++;
        for (final o in d.orders.where((o) => !o.lawful)) {
          variants.add('${o.kind.name}${o.variant}${o.kind == M7RqKind.earth ? o.alt : ''}');
        }
        seen.add('${d.orders.map((o) => '${o.kind.index}${o.lawful}${o.variant}').join('|')}|${d.coworkerAt}');
      }
      expect(seen.length, greaterThan(280));
      expect(at, {0, 1, 2, 3, 4, 5});
      expect(unlawful, {2, 3, 4});
      expect(repeats, M7RqKind.values.toSet());
      for (final x in [plateRight, neutralLeft, firstLawful]) {
        expect(x, inInclusiveRange(100, 200));
      }
      // The repeat's second version is dealt on its own: the first never
      // tells it (§4 no giveaways).
      expect(sameVersion, inInclusiveRange(100, 200), reason: 'same version as the first: $sameVersion of 300');
      expect(variants, containsAll(['helper0', 'helper1', 'pillar0', 'pillar1', 'earth0true', 'earth0false', 'earth1true', 'earth1false', 'balcony0', 'kit0']));
    });

    test('every object shows its first order from the start; a repeated kind changes when its second order comes', () {
      final r = M7RqRun(_dealOf(_allLawful));
      expect(r.look.helperPerson, 0);
      expect(r.card, (name: L.names[0], training: true, signed: true));
      for (var i = 0; i < 5; i++) {
        r.read();
        expect(r.obey(), isNull);
        r.next();
      }
      expect(r.look.helperPerson, 1, reason: 'the second helper');
      expect(r.look.helperUp, isFalse);
      final c = r.card;
      expect(c.name, L.names[1]);
      expect(c.training && c.signed, isFalse, reason: 'his card is not complete');
      final bad = M7RqRun(_dealOf(const [
        M7RqOrder(kind: M7RqKind.pillar, lawful: false, variant: 1),
        M7RqOrder(kind: M7RqKind.earth, lawful: false, variant: 0, alt: true),
        M7RqOrder(kind: M7RqKind.balcony, lawful: false),
        M7RqOrder(kind: M7RqKind.kit, lawful: false),
        M7RqOrder(kind: M7RqKind.helper, lawful: true),
        M7RqOrder(kind: M7RqKind.pillar, lawful: true),
      ]));
      expect(bad.look.plate, M7RqPlate.ground);
      expect((bad.look.lead, bad.look.badLeadIsBody), (M7RqLead.cut, true));
      expect(bad.look.line, M7RqLine.resting);
      expect(bad.look.helmetIn, isFalse);
    });

    test('obey: lawful goes ahead (the first asks why); unlawful = slip (R28), the act plays; nothing before the order is heard', () {
      final r = M7RqRun(_dealOf(const [
        M7RqOrder(kind: M7RqKind.pillar, lawful: true),
        M7RqOrder(kind: M7RqKind.earth, lawful: true),
        M7RqOrder(kind: M7RqKind.balcony, lawful: false),
        M7RqOrder(kind: M7RqKind.kit, lawful: true),
        M7RqOrder(kind: M7RqKind.helper, lawful: false),
        M7RqOrder(kind: M7RqKind.pillar, lawful: false),
      ]));
      expect(r.obey(), isNull);
      expect(r.roundDone, isFalse, reason: 'the order is not heard yet');
      r.read();
      expect(r.obey(), isNull);
      expect(r.okReason, isTrue, reason: 'the first right ঠিক আছে asks why');
      expect(r.look.pillarOn, isTrue);
      r.next();
      r.read();
      expect(r.obey(), isNull);
      expect(r.okReason, isFalse, reason: 'only the first');
      r.next();
      r.read();
      expect(r.obey(), Mk.obeyBalcony);
      expect(r.look.lineLive, isTrue, reason: 'the act plays');
      expect(r.slips, 1);
      expect(r.roundDone, isTrue);
      expect(r.caught, isEmpty);
      expect(r.call(), isFalse, reason: 'the order is over');
    });

    test('call: lawful = needless (R29) and the order goes ahead; wrong page = slip, book stays open; right page questions it; the fix after', () {
      final r = M7RqRun(_dealOf(const [
        M7RqOrder(kind: M7RqKind.kit, lawful: true),
        M7RqOrder(kind: M7RqKind.earth, lawful: false, variant: 1),
        M7RqOrder(kind: M7RqKind.helper, lawful: false),
        M7RqOrder(kind: M7RqKind.pillar, lawful: false),
        M7RqOrder(kind: M7RqKind.balcony, lawful: false),
        M7RqOrder(kind: M7RqKind.kit, lawful: false),
      ]));
      r.read();
      expect(r.show(M7RqPage.rights), isNull, reason: 'no book before the call');
      expect(r.call(), isTrue);
      expect(r.stage, M7RqStage.asking);
      expect(r.show(M7RqPage.rights), isNull, reason: 'the book opens after he asks');
      r.openBook();
      expect(r.show(M7RqPage.rights), Mk.needless, reason: 'any page: nothing was wrong');
      expect(r.roundDone, isTrue);
      expect(r.look.crewWorking, isTrue, reason: 'the order goes ahead');
      r.next();
      r.read();
      expect(r.look.lead, M7RqLead.hanging);
      r
        ..call()
        ..openBook();
      expect(r.show(M7RqPage.reg3), Mk.pageEarth);
      expect(r.show(M7RqPage.reg20), Mk.pageEarth);
      expect(r.stage, M7RqStage.paging, reason: 'the book stays open');
      expect(r.slips, 3);
      expect(r.orderSlips, 2);
      expect(r.show(M7RqPage.reg43), isNull);
      expect(r.questioned, isTrue);
      expect(r.caught, [L.caughtQuestion(M7RqKind.earth)]);
      expect(r.look.lead, M7RqLead.hanging, reason: 'the fix plays after the reason');
      r.applyFix();
      expect(r.look.lead, M7RqLead.ok);
      expect(r.look.dtrReady, isFalse, reason: 'questioned, not readied');
    });

    test('nothing charged in 7.1: obeying the DTR only readies it (AB open, M7-6 / M6-1)', () {
      final r = M7RqRun(_dealOf(const [
        M7RqOrder(kind: M7RqKind.earth, lawful: false, variant: 0),
        M7RqOrder(kind: M7RqKind.helper, lawful: true),
        M7RqOrder(kind: M7RqKind.pillar, lawful: true),
        M7RqOrder(kind: M7RqKind.balcony, lawful: true),
        M7RqOrder(kind: M7RqKind.kit, lawful: true),
        M7RqOrder(kind: M7RqKind.earth, lawful: true),
      ]));
      r.read();
      expect(r.obey(), Mk.obeyEarth);
      expect(r.look.dtrReady, isTrue, reason: 'the tag comes off');
      expect(Mk.obeyEarth.deadly, isFalse, reason: 'a slip in 7.1 (M7-6)');
      r.next();
      expect(r.look.dtrReady, isFalse, reason: 'the next order: back to the shutdown lane');
    });

    test('no charge ever with a man up, and no man climbs a charged lane (M5-1 / X7): every deal, obeyed or questioned', () {
      bool unsafe(M7RqLook l) => l.helperUp && (l.pillarOn || l.lineLive || l.dtrReady);
      for (var s = 0; s < 400; s++) {
        final d = m7RqDeal(math.Random(s));
        for (final question in [false, true]) {
          final r = M7RqRun(d);
          for (var i = 0; i < kM7RqOrders; i++) {
            expect(r.look.helperUp, isFalse, reason: 'seed $s order $i: he is down when the order comes');
            r.read();
            if (question && !r.order.lawful) {
              r
                ..call()
                ..openBook()
                ..show(m7RqPageFor(r.order.kind))
                ..applyFix();
            } else {
              r.obey();
            }
            expect(unsafe(r.look), isFalse, reason: 'seed $s order $i (${r.order.kind}): ${r.look.helperUp}');
            r.next();
            if (!r.done) expect(unsafe(r.look), isFalse, reason: 'seed $s order $i: the next order');
          }
        }
      }
    });

    test('every kind: its page, its fix; the fit man after a questioned helper', () {
      for (final k in M7RqKind.values) {
        final r = M7RqRun(_dealOf([
          M7RqOrder(kind: k, lawful: false),
          for (final o in M7RqKind.values.where((x) => x != k)) M7RqOrder(kind: o, lawful: true),
          M7RqOrder(kind: k, lawful: true, person: 1),
        ]));
        r
          ..read()
          ..call()
          ..openBook();
        for (final p in M7RqPage.values.where((p) => p != m7RqPageFor(k))) {
          expect(r.show(p), Mk.wrongPage(k), reason: '$k on $p');
        }
        expect(r.show(m7RqPageFor(k)), isNull);
        r.applyFix();
        switch (k) {
          case M7RqKind.helper:
            expect(r.card, (name: L.names[2], training: true, signed: true));
            expect(r.look.helperPerson, 2);
          case M7RqKind.pillar:
            expect(r.look.plate, M7RqPlate.fixed);
          case M7RqKind.earth:
            expect(r.look.lead, M7RqLead.ok);
          case M7RqKind.balcony:
            expect((r.look.line, r.look.lineLive), (M7RqLine.clear, false));
          case M7RqKind.kit:
            expect(r.look.helmetIn, isTrue);
        }
      }
      expect({for (final k in M7RqKind.values) m7RqPageFor(k)}, M7RqPage.values.toSet(), reason: 'one page per kind');
    });

    test('listening to him is a slip (X2/B1) and the order still waits; three slips fail; no deadly anywhere (M7-6)', () {
      final r = M7RqRun(_dealOf(_allLawful, coworkerAt: 0))..read();
      expect(r.pushSlip(), Mk.listen);
      expect(r.deciding, isTrue, reason: 'the order still waits');
      r.pushSlip();
      r.pushSlip();
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(r.thorough, isFalse);
      expect(Mk.all.where((m) => m.deadly), isEmpty, reason: 'no deadly in lesson 7.1');
      expect(r.ended, isFalse, reason: 'only the end of the orders ends a play');
    });

    test('lesson text: live CEA 2023 numbers, no old ones; English digits; term rules; jol not pani; keys, art, lesson points', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        for (final p in M7RqPage.values) ...[L.pageTitle(p), L.pageBody(p), L.pageShort(p)],
        for (var i = 0; i < 5; i++) L.pageCount(i),
        ...L.supervisorLines,
        for (final k in M7RqKind.values) ...[L.closeTitle(k), L.caughtQuestion(k)],
        L.whyAsk,
        L.whyOk,
        ...L.allWhyRight,
        ...L.myths,
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        // The word only: 'কোম্পানি' holds the letters too.
        expect(RegExp(r"(^|[\s,।'(])পানি").hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp(r'রেগুলেশন (15|18|32)\b').hasMatch(l), isFalse, reason: 'old numbers (X3): $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
        expect(RegExp(r'(^|\s)(অন|অফ)(\s|$|।|,)').hasMatch(l), isFalse, reason: 'ON/OFF in English: $l');
      }
      expect([for (final p in M7RqPage.values) L.pageShort(p)], ['রেগুলেশন 3', 'রেগুলেশন 20', 'রেগুলেশন 43 ও 50', 'রেগুলেশন 60 থেকে 63 ও 71', 'নিজের অধিকার']);
      // Each page's words are the lesson's (7.1 section 3 and pro tips 2, 4).
      final content = _lesson71()['content'] as Map;
      final lesson = _nukta([
        for (final sec in content['sections'] as List)
          for (final pt in (sec as Map)['points'] as List) '${(pt as Map)['specifications']} ${pt['importance']}',
        ...((content['pro_tip'] as Map)['content'] as List).cast<String>(),
      ].join(' '));
      for (final p in M7RqPage.values) {
        for (final sentence in L.pageBody(p).split('।').where((s) => s.trim().isNotEmpty)) {
          expect(lesson.contains(sentence.trim()), isTrue, reason: 'lesson words: $sentence');
        }
      }
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.1/m7_rule_question/'));
        expect(m.deadly, isFalse);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      const dir = 'assets/game/art/m7_rule_question/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used, reason: 'every file in the art folder is used');
      expect(m7RuleQuestionPacks.keys, ['do_7_1_b']);
    });

    test('libraries: same length, big enough, no rule marked wrong; each deal one right of three', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final k in M7RqKind.values) {
        for (final lib in [L.whyAskRight[k]!, L.whyOkRight[k]!]) {
          expectLibrary('why $k', lib, L.myths);
          for (var s = 0; s < 10; s++) {
            final deal = dealChoices(lib, L.myths, math.Random(s));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
      }
      expectSameLength('coworker', [...L.coworker.right, ...L.coworker.wrong]);
      expectLibrary('coworker', L.coworker.right, L.coworker.wrong, minRight: 3);
      expect(L.coworker.asks, contains('কী করবেন?'));
    });

    test('voice: his line is lesson 7.1 myth 1 word for word; his exit is recorded; every spoken line is listed', () {
      final myth = (((_lesson71()['content'] as Map)['myth_buster'] as Map)['myths'] as List).first as Map;
      expect(_nukta(L.coworker.line), _nukta(myth['myth'] as String));
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['এসব আইনকানুন তো শুধু কাগজের জন্য, মাঠে কেউ মানে না।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll([
            L.intro,
            L.askListen,
            L.askLook,
            L.askPage,
            L.askClose,
            L.whyAsk,
            L.whyOk,
            L.callHeld,
            L.allSet,
            L.quick,
            L.fail,
            ...L.tapWhy,
            ...L.coworker.asks,
            for (final m in Mk.all) m.textBn,
          ]));
      // The supervisor in the rival's voice (kit_check's caller), apart from
      // the guide's lines.
      expect(L.newSupervisorLines, L.supervisorLines);
      expect(L.newGuideLines.toSet().intersection(L.supervisorLines.toSet()), isEmpty);
      expect(L.supervisorLines, containsAll([L.askWhich, L.agree, L.notThere, L.allFine, L.order(M7RqKind.helper), L.order(M7RqKind.helper, person: 1)]));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_rule_question: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('tap areas: no overlap, on the lane, under the header, above the floor (the phone, the controls and the guide)', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        final g = M7RqGeo.forScene(h, 0);
        final rects = [for (final k in M7RqKind.values) g.hit(k)];
        for (final (i, r) in rects.indexed) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThanOrEqualTo(M7RqGeo.top - 0.01), reason: 'h $h: $r under the header');
          expect(r.bottom, lessThanOrEqualTo(h - M7RqGeo.floorUp + 0.01), reason: 'h $h: $r above the floor');
          for (final o in rects.skip(i + 1)) {
            expect(r.overlaps(o), isFalse, reason: 'h $h: $r / $o');
          }
          expect(r.width, greaterThanOrEqualTo(30 * g.k), reason: 'a finger-sized target');
        }
        for (final k in M7RqKind.values) {
          expect(g.kindAt(g.hit(k).center), k);
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

    testWidgets('the guide comes first: a tap does not skip him; then the phone and the two controls', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
          child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M7RuleQuestionPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m7RqDeal(math.Random(3));
      expect(find.text(d.orders.first.textBn), findsOneWidget, reason: 'the order on the phone');
      expect(_label(L.ok), findsOneWidget);
      expect(_label(L.call), findsOneWidget);
      expect(find.text(L.holdHint), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      await _deciding(t);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askLook)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with the coworker on an unlawful order, one on a lawful one;
    // both with a repeated helper or a later lawful order.
    final flowSeeds = [
      _seedWhere((d) => !d.orders[d.coworkerAt].lawful && d.coworkerAt > 0 && d.unlawful >= 3),
      _seedWhere((d) => d.orders[d.coworkerAt].lawful && d.coworkerAt > 0 && d.orders.any((o) => o.kind == M7RqKind.helper && o.person == 1)),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): six orders — look, obey or question with the right page, reasons; he is refused → pass', (t) async {
        final d = m7RqDeal(math.Random(seed));
        final c = await _open(t, seed);
        var firstOk = true;
        for (var i = 0; i < kM7RqOrders; i++) {
          await _play(t, d, i, firstOk: firstOk && d.orders[i].lawful);
          if (d.orders[i].lawful) firstOk = false;
        }
        await _pump(t, 2500);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.1/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.1/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        for (final o in d.orders.where((o) => !o.lawful)) {
          expect(find.text(L.caughtQuestion(o.kind)), findsOneWidget);
        }
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final lawfulFirstAlone = _seedWhere((d) => d.orders.first.lawful && d.coworkerAt != 0);
    testWidgets('ঠিক আছে is two steps: a tap opens it and answers nothing, ✕ sets it aside, ✓ carries it out', (t) async {
      final c = await _open(t, lawfulFirstAlone);
      await _deciding(t);
      await t.tap(_label(L.ok));
      await _pump(t, 300);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(_live.roundDone, isFalse);
      await _pump(t, 400);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      final aside = t.widget<CardAside>(find.ancestor(of: _label(L.ok), matching: find.byType(CardAside)));
      expect(aside.aside, isTrue, reason: 'set aside, dimmed');
      expect(_live.roundDone, isFalse);
      await _ok(t);
      expect(_live.roundDone, isTrue);
      expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue, reason: 'কেন মেনে নিলেন?');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    final unlawfulFirstAlone = _seedWhere((d) => !d.orders.first.lawful && d.coworkerAt != 0);
    testWidgets('a slip (ঠিক আছে on a breach) shows its card, never a freeze (M7-6); the next order follows', (t) async {
      final d = m7RqDeal(math.Random(unlawfulFirstAlone));
      final c = await _open(t, unlawfulFirstAlone);
      await _deciding(t);
      await _ok(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(Mk.obey(d.orders.first.kind).textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.obey(d.orders.first.kind).key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 1, reason: 'the order was carried out; the next one');
      await _close(t, c);
    });

    testWidgets('three wrong pages strike the level out (the book stays open between)', (t) async {
      final d = m7RqDeal(math.Random(unlawfulFirstAlone));
      final c = await _open(t, unlawfulFirstAlone);
      await _deciding(t);
      await _call(t);
      final wrong = M7RqPage.values.firstWhere((p) => p != m7RqPageFor(d.orders.first.kind));
      for (var i = 0; i < 3; i++) {
        await _pageTo(t, wrong);
        await _showPage(t);
        await _pump(t, 600);
        if (i < 2) {
          expect(find.text(Mk.wrongPage(d.orders.first.kind).textBn), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
          expect(_label(L.bookLabel), findsOneWidget, reason: 'the book stays open');
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a call on a lawful order: the needless-stop card; the order then goes ahead', (t) async {
      final c = await _open(t, lawfulFirstAlone);
      await _deciding(t);
      await _call(t);
      await _showPage(t);
      await _pump(t, 600);
      expect(find.text(Mk.needless.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.needless.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 1);
      await _close(t, c);
    });

    final himFirst = _seedWhere((d) => d.coworkerAt == 0 && !d.orders.first.lawful);
    testWidgets('his order: the first touch waits for him (myth 1); listening = slip; the order still waits for the player', (t) async {
      final c = await _open(t, himFirst);
      await _deciding(t);
      // Press the call: it does not start; he cuts in.
      final g = await t.startGesture(t.getCenter(_label(L.call)));
      await _pump(t, 1400);
      await g.up();
      expect(_live.stage, M7RqStage.deciding, reason: 'the hold did not run');
      expect(await _pumpUntil(t, () => find.byType(CoworkerPeek).evaluate().isNotEmpty), isTrue);
      expect(find.text(L.coworker.line), findsWidgets);
      await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.listen.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listen.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect((_live.index, _live.stage, _live.roundDone), (0, M7RqStage.deciding, false), reason: 'the order still waits');
      // Now the call works.
      await _call(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _close(t, c);
    });

    testWidgets('the praise window takes no touch: the lane and the controls wait for the reason', (t) async {
      final c = await _open(t, lawfulFirstAlone);
      await _deciding(t);
      await _ok(t);
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_geo.hit(M7RqKind.pillar).center * _k);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(find.byKey(const ValueKey('closeup-close')), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, () => find.byType(ChoiceDeck).evaluate().isNotEmpty), isTrue);
      await _pump(t, 400);
      await _pickRight(t, L.whyOkRight[m7RqDeal(math.Random(lawfulFirstAlone)).orders.first.kind]!);
      await _pump(t, 2400);
      expect(_live.index, 1);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: a sweep over the five objects and both controls (presses none); a tap on a close-up\'s close; nothing while the phone talks', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, lawfulFirstAlone);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _deciding(t);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while deciding');
      expect(scene().debugOptions, hasLength(7), reason: 'five objects and two controls alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _tapAt(t, _geo.hit(M7RqKind.kit).center);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on a close-up');
      expect(scene().debugOptions, isEmpty, reason: 'a tap on the close button, the one way on');
      await t.tap(find.byKey(const ValueKey('closeup-close')));
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
