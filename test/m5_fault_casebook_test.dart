// Lesson 5.6 (শর্ট সার্কিট আর ওপেন সার্কিট), কাজ 1 "দুই শত্রুর খাতা": the rules
// (two clues a case, one gesture per spot; the slip filed in one of three
// boxes; a wrong box = a slip and every clue shown; listening to "a trip
// means a short" = a slip; no deadly act), the deal (four kinds, at least one
// open; the coworker on any trip case; two spots always tell the boxes
// apart), the libraries, and the level in the shell: the guide first, a full
// clean play with the coworker refused, a wrong gesture shows only its glyph,
// the clue budget, a wrong box (card, every clue shown, no freeze), three
// slips, the coworker holding the first clue and the filing, the praise
// window, and the gesture hints (sweep over all four spots, the slip nudged
// toward the spine, never a box).
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
import 'package:slm_flutter/features/game/m5_fault_casebook.dart';
import 'package:slm_flutter/features/game/m5_fault_casebook_world.dart';
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
  rungId: '5.6/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.6',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m5FaultCasebookPacks['do_5_6_a']!;

/// The new art is not in the bundle until the director wires it: tests read
/// it from disk when the bundle does not have it.
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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M5CaseGeo get _geo => M5CaseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

/// Opens a clue with the spot's own gesture.
Future<void> _gestureOn(WidgetTester t, M5Spot s, {M5Gesture? as}) async {
  final r = _geo.hit(s);
  switch (as ?? m5GestureFor(s)) {
    case M5Gesture.tap:
      await t.tapAt(r.center * _k);
    case M5Gesture.swipeUp:
      await t.dragFrom(Offset(r.center.dx, r.bottom - 16) * _k, const Offset(0, -120));
    case M5Gesture.sweep:
      await t.dragFrom(Offset(r.left + 10, r.center.dy) * _k, const Offset(130, 0));
    case M5Gesture.hold:
      await t.longPressAt(r.center * _k);
  }
  await _pump(t, 300);
}

Finder _note(M5Spot s) => find.byKey(ValueKey('note-${s.name}'));
Finder get _glyphs => find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('glyph-'));
Finder _glyph(M5Spot s) =>
    find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('glyph-${s.name}-'));

Future<void> _fileIn(WidgetTester t, M5Box b) async {
  final slip = find.byKey(const ValueKey('case-slip'));
  final box = find.byKey(ValueKey('box-${b.name}'));
  await t.drag(slip, t.getCenter(box) - t.getCenter(slip), warnIfMissed: false);
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5FaultCasebookPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _reason(WidgetTester t, M5CaseKind k) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, M5CasebookLines.whyRight(k));
  await _pump(t, 3000);
}

/// The two spots used for case [i] (every gesture gets played in a play).
List<M5Spot> _spots(int i) => [M5Spot.values[i % 4], M5Spot.values[(i + 1) % 4]];

/// Plays case [i] right: two clues (the coworker refused on his case), the
/// right box, the right reason.
Future<void> _playCase(WidgetTester t, M5CasebookDeal d, int i) async {
  final c = d.cases[i];
  final s = _spots(i);
  await _gestureOn(t, s[0]);
  if (i == d.coworkerCase) {
    expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he comes at the first clue');
    expect(_note(s[0]), findsNothing, reason: 'the clue waits for him');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pickRight(t, M5CasebookLines.coworker.right);
    await _pump(t, 2600);
  }
  expect(_note(s[0]), findsOneWidget, reason: 'case $i: ${s[0]}');
  await _gestureOn(t, s[1]);
  expect(_note(s[1]), findsOneWidget, reason: 'case $i: ${s[1]}');
  await _fileIn(t, c.answer);
  await _pump(t, 800);
  await _reason(t, c.kind);
}

int _seedWhere(bool Function(M5CasebookDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5CasebookDeal(math.Random(s))));

void main() {
  group('rules', () {
    test('deal: four different kinds (≥1 open), four places, the slip states the protection, he comes on a trip case; plays differ', () {
      final seen = <String>{};
      final coworkerKinds = <M5CaseKind>{};
      final coworkerAt = <int>{};
      final kinds = <M5CaseKind>{};
      for (var s = 0; s < 120; s++) {
        final d = m5CasebookDeal(math.Random(s));
        expect(d.cases, hasLength(4));
        expect(d.cases.map((c) => c.kind).toSet(), hasLength(4));
        expect(d.cases.map((c) => c.place).toSet(), hasLength(4));
        expect(d.cases.any((c) => c.answer == M5Box.open), isTrue);
        for (final c in d.cases) {
          kinds.add(c.kind);
          expect(c.protection == M5Protection.none, !m5Trips(c.kind), reason: '${c.kind}');
          if (c.kind == M5CaseKind.noSign) expect(c.protection, M5Protection.feederTrip, reason: 'a blown fuse alone is an open example');
          expect(c.clues.keys.toSet(), M5Spot.values.toSet());
          for (final sp in M5Spot.values) {
            expect(c.clues[sp]!.notes, contains(c.notes[sp]));
          }
        }
        final cw = d.cases[d.coworkerCase];
        expect(cw.protection, isNot(M5Protection.none), reason: 'a trip case');
        coworkerKinds.add(cw.kind);
        coworkerAt.add(d.coworkerCase);
        seen.add('${d.cases.map((c) => '${c.kind.name}:${c.protection.name}:${c.place}').join(',')}|${d.coworkerCase}');
      }
      expect(seen.length, greaterThan(100));
      expect(kinds, M5CaseKind.values.toSet(), reason: 'every kind is dealt');
      expect(coworkerKinds, {M5CaseKind.clash, M5CaseKind.bridge, M5CaseKind.noSign}, reason: 'his case gives no answer away');
      expect(coworkerAt.length, greaterThanOrEqualTo(3));
    });

    test('any two spots tell apart two cases with the same slip but different boxes; notes never name a box', () {
      for (final a in M5CaseKind.values) {
        for (final b in M5CaseKind.values) {
          if (m5Trips(a) != m5Trips(b) || m5AnswerOf(a) == m5AnswerOf(b)) continue;
          for (final va in M5CasebookLines.clueBook[a]!) {
            for (final vb in M5CasebookLines.clueBook[b]!) {
              for (var i = 0; i < 4; i++) {
                for (var j = i + 1; j < 4; j++) {
                  final s1 = M5Spot.values[i];
                  final s2 = M5Spot.values[j];
                  expect(va[s1]!.look != vb[s1]!.look || va[s2]!.look != vb[s2]!.look, isTrue, reason: '$a vs $b on $s1+$s2');
                }
              }
            }
          }
        }
      }
      for (final vs in M5CasebookLines.clueBook.values) {
        for (final v in vs) {
          for (final c in v.values) {
            for (final n in c.notes) {
              expect(n.contains('শর্ট') || n.contains('ওপেন') || n.contains('সার্কিট'), isFalse, reason: n);
            }
          }
        }
      }
      // Each spot opens by its own gesture.
      expect(M5Spot.values.map(m5GestureFor).toSet(), hasLength(4));
    });

    test('clues: two a case; an open spot or an empty budget spends nothing', () {
      final d = m5CasebookDeal(math.Random(3));
      final r = M5CasebookRun(d);
      expect(r.cluesLeft, 2);
      expect(r.open(M5Spot.person), M5Open.opened);
      expect(r.open(M5Spot.person), M5Open.already);
      expect(r.cluesLeft, 1);
      expect(r.open(M5Spot.pump), M5Open.opened);
      expect(r.cluesLeft, 0);
      expect(r.open(M5Spot.pole), M5Open.spent);
      expect(r.seen, {M5Spot.person, M5Spot.pump});
      expect(r.slips, 0);
    });

    test('filing: locked until both clues; the right box ends the case; a wrong box is a slip, its card, every clue shown; then a right box', () {
      final d = m5CasebookDeal(math.Random(5));
      final r = M5CasebookRun(d);
      final c = d.cases[0];
      final wrong = M5Box.values.firstWhere((b) => b != c.answer);
      // No verdict without its evidence (M5-10): nothing happens, no slip.
      expect(r.canFile, isFalse);
      expect(r.file(c.answer), isNull);
      expect(r.file(wrong), isNull);
      expect(r.caseDone, isFalse);
      expect(r.slips, 0);
      r.open(M5Spot.person);
      expect(r.canFile, isFalse, reason: 'one clue is not enough');
      expect(r.file(wrong), isNull);
      expect(r.slips, 0);
      r.open(M5Spot.pole);
      expect(r.canFile, isTrue);
      expect(r.file(wrong), M5CasebookMistakes.wrongBox(c.kind, wrong));
      expect(r.slips, 1);
      expect(r.revealedAll, isTrue);
      expect(r.seen, M5Spot.values.toSet());
      expect(r.cluesLeft, 0);
      expect(r.caseDone, isFalse);
      expect(r.file(c.answer), isNull);
      expect(r.caseDone, isTrue);
      expect(r.caught, isEmpty, reason: 'not a clean case');
      expect(r.file(wrong), isNull, reason: 'filed already');
      r.next();
      expect(r.index, 1);
      expect(r.seen, isEmpty);
      expect(r.revealedAll, isFalse);
      expect(r.cluesLeft, 2);
      final c1 = d.cases[1];
      r
        ..open(M5Spot.ground)
        ..open(M5Spot.pump);
      expect(r.file(c1.answer), isNull);
      expect(r.caught, [M5CasebookLines.caught(c1.kind)]);
    });

    test('every kind: its box and its card; listening is a slip; four cases with two slips still pass (three strike out in the page)', () {
      expect(m5AnswerOf(M5CaseKind.clash), M5Box.short);
      expect(m5AnswerOf(M5CaseKind.bridge), M5Box.short);
      expect(m5AnswerOf(M5CaseKind.hidden), M5Box.short);
      expect(m5AnswerOf(M5CaseKind.jumper), M5Box.open);
      expect(m5AnswerOf(M5CaseKind.phase), M5Box.open);
      expect(m5AnswerOf(M5CaseKind.noSign), M5Box.noProof);
      expect(M5CasebookMistakes.wrongBox(M5CaseKind.phase, M5Box.short), M5CasebookMistakes.singlePhase);
      expect(M5CasebookMistakes.wrongBox(M5CaseKind.hidden, M5Box.open), M5CasebookMistakes.hiddenShort);
      // A no-sign trip: filed as short -> "a trip is not always a short";
      // filed as open -> "an open drops the current to zero, it trips nothing".
      expect(M5CasebookMistakes.wrongBox(M5CaseKind.noSign, M5Box.short), M5CasebookMistakes.noProof);
      expect(M5CasebookMistakes.wrongBox(M5CaseKind.noSign, M5Box.open), M5CasebookMistakes.tripNotOpen);
      expect(M5CasebookMistakes.tripNotOpen.textBn, contains('কারেন্ট শূন্য'));
      expect(M5CasebookMistakes.tripNotOpen.lessonPoint, 2);
      final d = m5CasebookDeal(math.Random(8));
      final r = M5CasebookRun(d);
      expect(r.listened(), M5CasebookMistakes.listened);
      r.refused();
      expect(r.caught, [M5CasebookLines.caughtCall]);
      for (var i = 0; i < 4; i++) {
        r
          ..open(M5Spot.person)
          ..open(M5Spot.pole);
        if (i == 1) r.file(M5Box.values.firstWhere((b) => b != r.current.answer));
        r.file(r.current.answer);
        r.next();
      }
      expect(r.done, isTrue);
      expect(r.slips, 2);
      expect(r.percent, 70);
      expect(r.passed, isTrue);
      r.slips = 4;
      expect(r.passed, isFalse, reason: '40 %');
    });

    test('a blind play cannot pass: no clue, no filing; "trip -> short, none -> open" without clues files nothing', () {
      for (var seed = 0; seed < 40; seed++) {
        final r = M5CasebookRun(m5CasebookDeal(math.Random(seed)));
        for (var i = 0; i < 4; i++) {
          final blind = r.current.protection == M5Protection.none ? M5Box.open : M5Box.short;
          expect(r.canFile, isFalse);
          expect(r.file(blind), isNull);
          expect(r.caseDone, isFalse, reason: 'seed $seed: filed with no clue');
          expect(r.slips, 0);
        }
        expect(r.index, 0);
        expect(r.done, isFalse);
        expect(r.passed, isFalse);
      }
    });

    test('mistakes: no deadly act on this rung; keys unique; pictures exist; lesson points in range', () {
      expect(M5CasebookMistakes.all.where((m) => m.deadly), isEmpty);
      expect(M5CasebookMistakes.all.map((m) => m.key).toSet(), hasLength(M5CasebookMistakes.all.length));
      for (final m in M5CasebookMistakes.all) {
        expect(m.key, startsWith('5.6/m5_fault_casebook/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(M5CasebookMistakes.tripNotOpen.art, M5CasebookMistakes.noProof.art, reason: 'the two no-proof cards share a picture');
      final art = Directory('assets/game/art/m5_fault_casebook').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(art, M5CasebookMistakes.all.map((m) => m.art.split('/').last).toSet(), reason: 'no unused art');
      expect(m5FaultCasebookPacks.keys, ['do_5_6_a']);
    });

    test('English digits only; জল not পানি; the case labels', () {
      final all = [...M5CasebookLines.allText, for (final m in M5CasebookMistakes.all) m.textBn];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5CasebookLines.caseNo(1, 4), 'কেস 2/4');
      expect(M5CasebookLines.progress(0), 'কেস 1');
    });

    test('libraries: reasons and his deck the same length, big enough, never a rule marked wrong; deals 1 right of 3', () {
      expectSameLength('why', [...M5CasebookLines.allWhyRight, ...M5CasebookLines.myths]);
      expect(M5CasebookLines.myths.toSet().intersection(M5CasebookLines.allWhyRight.toSet()), isEmpty);
      for (final k in M5CaseKind.values) {
        final right = M5CasebookLines.whyRight(k);
        expectLibrary('$k', right, M5CasebookLines.myths);
        expect(M5CasebookLines.whyQuestion(k), isNotEmpty);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, M5CasebookLines.myths, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = M5CasebookLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.asks, hasLength(greaterThanOrEqualTo(2)));
    });

    test('rival lines: each recorded line has its clip or is listed to record', () {
      final cw = M5CasebookLines.coworker;
      expect(cw.recordedLines, [M5CasebookLines.coworkerLine, M5CasebookLines.coworkerExit]);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull, reason: 'his exit line is recorded');
      for (final l in cw.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true) != null || M5CasebookLines.toRecord.contains(l), isTrue, reason: l);
      }
    });

    test('spots never overlap, stay on the 360-wide scene under the header and above the notebook; lenses on the scene', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M5CaseGeo.forScene(h, 0);
        final rects = [for (final s in M5Spot.values) g.hit(s)];
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(120), reason: 'h $h: below the header');
          expect(r.bottom, lessThanOrEqualTo(g.groundY), reason: 'h $h: above the notebook');
          expect(r.width, greaterThanOrEqualTo(48));
          expect(r.height, greaterThanOrEqualTo(48));
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final x = rects[i].intersect(rects[j]);
            expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: $i/$j');
          }
        }
        for (final s in M5Spot.values) {
          final l = g.lens(s);
          expect(l.left, greaterThanOrEqualTo(0));
          expect(l.right, lessThanOrEqualTo(360));
          expect(l.top, greaterThanOrEqualTo(120));
          expect(g.spotAt(g.hit(s).center), s);
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

    testWidgets('the guide comes first: a tap does not skip him; then the notebook', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5FaultCasebookPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.byKey(const ValueKey('case-slip')), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m5CasebookDeal(math.Random(3));
      expect(find.byKey(const ValueKey('case-slip')), findsOneWidget);
      expect(find.text(d.cases[0].place), findsOneWidget);
      expect(find.text(M5CasebookLines.protection(d.cases[0].protection)), findsOneWidget);
      // The boxes, always in the same order.
      final xs = [for (final b in M5Box.values) t.getCenter(find.byKey(ValueKey('box-${b.name}'))).dx];
      expect(xs, [...xs]..sort());
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
      expect(lines.every((l) => l.contains(M5CasebookLines.askClue)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in [7, 12]) {
      testWidgets('flow (seed $seed): two clues a case by gesture, the coworker refused, the right boxes and reasons → pass', (t) async {
        final d = m5CasebookDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 4; i++) {
          await _playCase(t, d, i);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.6/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.6/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5CasebookLines.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a wrong gesture shows only that spot\'s glyph and spends nothing; a third clue is not opened', (t) async {
      final seed = _seedWhere((d) => d.coworkerCase != 0);
      final c = await _open(t, seed);
      await _gestureOn(t, M5Spot.pole, as: M5Gesture.tap);
      expect(_glyphs, findsOneWidget);
      expect(_glyph(M5Spot.pole), findsOneWidget);
      expect(_note(M5Spot.pole), findsNothing);
      await _pump(t, 2000);
      expect(_glyphs, findsNothing, reason: 'it goes by itself');
      await _gestureOn(t, M5Spot.pump, as: M5Gesture.tap);
      expect(_glyph(M5Spot.pump), findsOneWidget);
      expect(_note(M5Spot.pump), findsNothing);
      await _gestureOn(t, M5Spot.pole);
      await _gestureOn(t, M5Spot.pump);
      expect(_note(M5Spot.pole), findsOneWidget);
      expect(_note(M5Spot.pump), findsOneWidget);
      await _gestureOn(t, M5Spot.person);
      expect(_note(M5Spot.person), findsNothing, reason: 'two clues a case');
      expect(c.read(guideDirectorProvider).line, M5CasebookLines.cluesGone);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a wrong box: its card (no freeze), every clue shown, the case filed again; the praise window takes no touch', (t) async {
      final seed = _seedWhere((d) => d.coworkerCase != 0);
      final d = m5CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      final first = d.cases[0];
      await _gestureOn(t, M5Spot.person);
      await _gestureOn(t, M5Spot.pole);
      final wrong = M5Box.values.firstWhere((b) => b != first.answer);
      await _fileIn(t, wrong);
      await _pump(t, 400);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act here');
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5CasebookMistakes.wrongBox(first.kind, wrong).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      for (final s in M5Spot.values) {
        expect(_note(s), findsOneWidget, reason: 'every clue after a wrong box: $s');
      }
      expect(c.read(guideDirectorProvider).line, M5CasebookLines.revealed);
      await _fileIn(t, first.answer);
      // The praise window: taps on the scene do nothing (no glyph, no card).
      for (var k = 0; k < 4; k++) {
        await t.tapAt(_geo.hit(M5Spot.pole).center * _k);
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(_glyphs, findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, first.kind);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CasebookMistakes.wrongBox(first.kind, wrong).key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => d.coworkerCase >= 2);
      final d = m5CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      final wrong0 = M5Box.values.where((b) => b != d.cases[0].answer).toList();
      await _gestureOn(t, M5Spot.person);
      await _gestureOn(t, M5Spot.pump);
      for (final b in wrong0) {
        await _fileIn(t, b);
        await _pump(t, 400);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 600);
      }
      await _fileIn(t, d.cases[0].answer);
      await _pump(t, 800);
      await _reason(t, d.cases[0].kind);
      await _gestureOn(t, M5Spot.pole);
      await _gestureOn(t, M5Spot.ground);
      await _fileIn(t, M5Box.values.firstWhere((b) => b != d.cases[1].answer));
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('his case: the first clue waits for him; listening is a slip; the clue opens after the card', (t) async {
      final seed = _seedWhere((d) => d.coworkerCase == 0);
      final c = await _open(t, seed);
      await _gestureOn(t, M5Spot.ground);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(_note(M5Spot.ground), findsNothing);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 400);
      await _pickWrong(t, M5CasebookLines.coworker.wrong);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(M5CasebookMistakes.listened.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_note(M5Spot.ground), findsOneWidget, reason: 'the held clue opens');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5CasebookMistakes.listened.key);
      // He comes once a play.
      await _gestureOn(t, M5Spot.person);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_note(M5Spot.person), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the slip is locked until both clues: a drag does nothing, a touch points at the clues; no slip, no coworker', (t) async {
      final seed = _seedWhere((d) => d.coworkerCase != 0);
      final d = m5CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      final slip = find.byKey(const ValueKey('case-slip'));
      // A blind drag into the right box: nothing is filed.
      await _fileIn(t, d.cases[0].answer);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'not filed');
      expect(find.byType(MistakeCard), findsNothing);
      expect(slip, findsOneWidget);
      expect(c.read(guideDirectorProvider).line, M5CasebookLines.clueFirst);
      expect(_glyphs, findsNWidgets(4), reason: 'the glyphs point at the clues');
      await _pump(t, 2000);
      // One clue: still locked; a tap on the slip says so again.
      await _gestureOn(t, M5Spot.person);
      await _fileIn(t, d.cases[0].answer);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(_glyphs, findsNWidgets(3), reason: 'only the clues not seen');
      await _pump(t, 2000);
      await t.tap(slip, warnIfMissed: false);
      await _pump(t, 300);
      expect(c.read(guideDirectorProvider).line, M5CasebookLines.clueFirst);
      // Two clues: it files.
      await _pump(t, 2000);
      await _gestureOn(t, M5Spot.pole);
      await _fileIn(t, d.cases[0].answer);
      await _pump(t, 800);
      await _reason(t, d.cases[0].kind);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('his case: going on with a clue gesture while he talks refuses him; the held clue opens', (t) async {
      CoworkerTiming.debugReadHoldInTests = true; // beat 1 holds his caption, as on a phone
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final seed = _seedWhere((d) => d.coworkerCase == 0);
      final d = m5CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _gestureOn(t, M5Spot.ground);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'beat 1: he is still talking');
      await _gestureOn(t, M5Spot.person);
      await _pump(t, 2000);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'he is gone, no deck');
      expect(find.byType(MistakeCard), findsNothing);
      expect(_note(M5Spot.ground), findsOneWidget, reason: 'the held clue opens');
      await _gestureOn(t, M5Spot.pole);
      expect(_note(M5Spot.pole), findsOneWidget);
      await _fileIn(t, d.cases[0].answer);
      await _pump(t, 800);
      await _reason(t, d.cases[0].kind);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hints: four glyphs after idle, a sweep over all four spots; with no clue left the slip nudged toward the spine', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.coworkerCase != 0);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 5600);
      expect(_glyphs, findsNWidgets(4), reason: 'all four glyphs after 6 s idle');
      await _pump(t, 2400);
      expect(_glyphs, findsNothing, reason: 'shown for 2 s');
      await _pump(t, 1600);
      expect(scene().showing, isTrue, reason: 'the kit hand after idle');
      expect(scene().debugOptions, hasLength(4), reason: 'every spot, the same each case');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _gestureOn(t, M5Spot.person);
      await _gestureOn(t, M5Spot.pump);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'no clue left: the slip');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a sweep');
      final f = scene().debugFrame!;
      final slip = t.getRect(find.byKey(const ValueKey('case-slip')));
      final boxTop = t.getRect(find.byKey(const ValueKey('box-short'))).top;
      expect(f.trailFrom, isNotNull);
      expect(slip.contains(f.trailFrom!), isTrue, reason: 'it starts on the slip');
      expect(f.tip.dy, lessThan(boxTop), reason: 'never down into a box');
      await _close(t, c);
    });
  });
}
