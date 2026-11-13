// Lesson 5.7 (রাতের বেলা ফল্ট খোঁজার কৌশল), কাজ 2 "আঁধারে চোখ-কান": the rules
// (walk with the headlamp on — off is a stumble or a hole; lights off and keep
// still: the fault's own light shows only after the wait, only on the fault
// stretch; mark the exact insulator — a glint under the torch, a sound one or
// a guess costs; leave the clue unmarked = a slip; read the plate in the
// torch light and report from the ground — climbing or a bamboo poke is
// deadly), the deal, the libraries, and the level in the shell: the guide
// first, a full clean play (the resident, the coworker refused, the dark
// wait, the mark, the plate, the report; every reason), a slip card, the
// walk waits for the coworker, listening to him is a slip, three slips, the
// deadly freeze, and the gesture hand (how, never what).
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
import 'package:slm_flutter/features/game/m5_dark_eyes.dart';
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
  rungId: '5.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5DarkEyesPacks['do_5_7_b']!;

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

/// Scene px (world x) → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
Offset _scr(M5DarkEyesProbe p, Offset world) => Offset(world.dx - p.cam, world.dy) * _k;

Future<ProviderContainer> _open(WidgetTester t, int seed, M5DarkEyesProbe p) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M5DarkEyesPage(ctx: _ctx, pack: _pack, muted: true, seed: seed, probe: p),
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

Future<void> _drag(WidgetTester t, double dx) async {
  await t.dragFrom(const Offset(150, 400), Offset(dx, 0));
  await _pump(t, 250);
}

Future<void> _refuse(WidgetTester t) async {
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pickRight(t, M5DarkEyesLines.coworker.right);
  await _pump(t, 2600);
}

/// Walks to stretch [zone] (refusing the coworker if he cuts in on the way).
Future<void> _walkTo(WidgetTester t, M5DarkEyesProbe p, int zone) async {
  for (var i = 0; i < 60 && p.run!.zone != zone; i++) {
    final dir = p.run!.walker < M5DarkEyesGeo.stretchX[zone] ? 1.0 : -1.0;
    await _drag(t, 90 * dir);
    if (find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t);
  }
  expect(p.run!.zone, zone);
}

/// From the start: walk to the first stretch, the coworker refused there.
Future<void> _firstStretch(WidgetTester t, M5DarkEyesProbe p) async {
  await _walkTo(t, p, 0);
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on the first stretch');
  await _refuse(t);
}

/// From the start to the open final deck (the resident skipped).
Future<void> _toFinal(WidgetTester t, M5DarkEyesProbe p) async {
  final d = p.run!.deal;
  await _firstStretch(t, p);
  await _walkTo(t, p, d.stretch);
  await t.tap(_label(M5DarkEyesLines.headlamp));
  await _pump(t, 5800);
  await _reason(t, M5DarkEyesLines.whyDark);
  await t.longPressAt(_scr(p, p.geo!.insulator(d.stretch, d.pole, d.phase)));
  await _pump(t, 400);
  await _reason(t, M5DarkEyesLines.whyMark[d.clue]!);
  await t.tap(_label(M5DarkEyesLines.torch));
  await _pump(t, 300);
  await t.tapAt(_scr(p, p.geo!.plate(d.stretch, d.pole)));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  expect(find.byKey(const ValueKey('final-deck')), findsOneWidget);
}

int _seedWhere(bool Function(M5DarkEyesDeal d) ok) => [for (var s = 0; s < 400; s++) s].firstWhere((s) => ok(m5DarkEyesDeal(math.Random(s))));

const _deal1 = M5DarkEyesDeal(
  stretch: 1,
  pole: 0,
  phase: 2,
  landmarks: [M5Landmark.temple, M5Landmark.bamboo, M5Landmark.pond],
  clue: M5Clue.tracking,
  sound: M5Sound.hiss,
  holes: [320, 780],
  poleBase: 40,
  residentHeard: false,
);

/// A run walked (in the headlamp's light) to world x [x].
M5DarkEyesRun _at(double x, [M5DarkEyesDeal d = _deal1]) {
  final r = M5DarkEyesRun(d);
  while ((r.walker - x).abs() > 0.5) {
    final step = (x - r.walker).clamp(-40.0, 40.0);
    expect(r.walk(step), isNull, reason: 'walk to $x');
  }
  return r;
}

void main() {
  group('rules', () {
    test('deals: fault stretch/pole/phase, landmark order, clue, sound, holes in the gaps, plates, the resident; plays differ', () {
      final seen = <String>{};
      final stretches = <int>{}, clues = <M5Clue>{}, sounds = <M5Sound>{}, firsts = <M5Landmark>{};
      for (var s = 0; s < 120; s++) {
        final d = m5DarkEyesDeal(math.Random(s));
        expect(d.stretch, inInclusiveRange(0, 2));
        expect(d.pole, inInclusiveRange(0, 1));
        expect(d.phase, inInclusiveRange(0, 2));
        expect(d.landmarks.toSet(), M5Landmark.values.toSet());
        expect(d.holes.length, inInclusiveRange(1, 2));
        for (final h in d.holes) {
          expect(M5DarkEyesGeo.holeGaps.any((g) => h >= g.$1 && h <= g.$2), isTrue, reason: '$h');
          expect(M5DarkEyesGeo.zoneAt(h), isNull, reason: 'never in a stretch');
        }
        expect(d.poleBase, inInclusiveRange(11, 80));
        if (d.residentHeard) expect(d.sound, isNot(M5Sound.none));
        expect(M5DarkEyesLines.allResidentLines, contains(d.residentLine));
        stretches.add(d.stretch);
        clues.add(d.clue);
        sounds.add(d.sound);
        firsts.add(d.landmarks.first);
        seen.add('${d.stretch}${d.pole}${d.phase}|${d.landmarks}|${d.clue}|${d.sound}|${d.holes.length}');
      }
      expect(stretches, {0, 1, 2});
      expect(clues, M5Clue.values.toSet());
      expect(sounds, M5Sound.values.toSet());
      expect(firsts, M5Landmark.values.toSet());
      expect(seen.length, greaterThan(80));
    });

    test('the resident names the fault stretch by its landmark, never by a pole', () {
      expect(_deal1.residentLine, 'বাঁশঝাড়ের ওদিকে নীলচে আলো দেখেছি।');
      const heard = M5DarkEyesDeal(
        stretch: 2,
        pole: 1,
        phase: 0,
        landmarks: [M5Landmark.temple, M5Landmark.bamboo, M5Landmark.pond],
        clue: M5Clue.flash,
        sound: M5Sound.rattle,
        holes: [320],
        poleBase: 40,
        residentHeard: true,
      );
      expect(heard.residentLine, 'পুকুরপাড়ের ওদিকে খটখট শব্দ শুনেছি।');
      for (final l in M5DarkEyesLines.allResidentLines) {
        expect(RegExp('[0-9০-৯]').hasMatch(l), isFalse, reason: l);
      }
    });

    test('walking: with the headlamp he steps round holes; without it a stumble, or the hole close ahead', () {
      final r = M5DarkEyesRun(_deal1);
      expect(r.walk(100), isNull);
      expect(r.walker, 280);
      expect(r.walk(60), isNull, reason: 'over the hole at 320 in the light');
      expect(r.passedHoles, {0});
      expect(r.slips, 0);
      final dark = _at(700)..toggleHeadlamp();
      expect(dark.walk(20), M5DarkEyesMistakes.hole, reason: 'the hole at 780 is 80 ahead');
      expect(dark.walker, 700, reason: 'he does not move in the dark');
      expect(dark.walk(20), M5DarkEyesMistakes.walkDark, reason: 'that hole is known now');
      expect(dark.walk(-20), M5DarkEyesMistakes.walkDark);
      expect(dark.slips, 3);
      expect(dark.passed, isFalse);
    });

    test('the dark wait: lights off and still — the clue shows only on the fault stretch; a light resets it', () {
      final r = _at(560);
      expect(r.zone, 0);
      expect(r.adaptDone(), isFalse, reason: 'the headlamp is on');
      r.toggleHeadlamp();
      expect(r.adaptDone(), isFalse, reason: 'a sound stretch: nothing to see');
      expect(r.adapted, isTrue);
      expect(r.clueVisible, isFalse);
      r.toggleHeadlamp();
      expect(r.adapted, isFalse, reason: 'light resets the eyes');
      expect(r.walk(440), isNull);
      expect(r.zone, 1);
      r.toggleHeadlamp();
      expect(r.adaptDone(), isTrue);
      expect(r.clueSeen, isTrue);
      expect(r.clueVisible, isTrue);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(M5DarkEyesLines.caughtDark));
      r.toggleTorch();
      expect(r.clueVisible, isFalse, reason: 'the torch drowns it');
    });

    test('marking: a glint under the torch, a sound insulator, a guess before the clue are slips; the right one after it', () {
      final r = _at(1000);
      expect(r.mark(1, 0, 2), M5DarkEyesMistakes.markGuess, reason: 'right, but no clue seen');
      r.toggleTorch();
      expect(r.mark(1, 1, 2), M5DarkEyesMistakes.markGlint);
      r
        ..toggleTorch()
        ..toggleHeadlamp();
      expect(r.mark(1, 0, 1), M5DarkEyesMistakes.markSound);
      expect(r.slips, 3);
      expect(r.adaptDone(), isTrue);
      r.next();
      expect(r.round, M5DarkRound.mark);
      expect(r.mark(1, 0, 2), isNull);
      expect(r.marked, isTrue);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(M5DarkEyesLines.caughtMark), reason: 'this round was clean');
    });

    test('leaving the fault stretch after the clue without marking is a slip (once); walking past every stretch is a slip', () {
      final r = _at(1000)..toggleHeadlamp();
      r
        ..adaptDone()
        ..next()
        ..toggleHeadlamp();
      expect(r.walk(80), isNull);
      expect(r.walk(80), M5DarkEyesMistakes.leftClue);
      expect(r.walk(-80), isNull);
      expect(r.walk(80), isNull, reason: 'once a round');
      final past = _at(1600);
      expect(past.walk(200), M5DarkEyesMistakes.walkedPast);
      expect(past.walker, M5DarkEyesGeo.endX);
      expect(past.walk(10), isNull, reason: 'once');
    });

    test('the report: the plate needs the torch and the right pole; climbing or a poke is deadly; waiting is a slip', () {
      M5DarkEyesRun marked() {
        final r = _at(1000)..toggleHeadlamp();
        r
          ..adaptDone()
          ..next()
          ..mark(1, 0, 2)
          ..next();
        return r;
      }

      final r = marked();
      expect(r.round, M5DarkRound.report);
      expect(r.readPlate(1, 0), isNull);
      expect(r.plateRead, isFalse, reason: 'dark: nothing to read');
      r.toggleTorch();
      expect(r.readPlate(1, 1), M5DarkEyesMistakes.wrongPlate);
      expect(r.readPlate(1, 0), isNull);
      expect(r.plateRead, isTrue);
      expect(r.report(M5DarkFinal.morning), M5DarkEyesMistakes.morning);
      expect(r.report(M5DarkFinal.walkOn), M5DarkEyesMistakes.walkOn);
      expect(r.ended, isFalse);
      expect(r.report(M5DarkFinal.report), isNull);
      expect(r.reported, isTrue);
      r.next();
      expect(r.done, isTrue);
      expect(r.percent, 55);
      expect(r.passed, isTrue);
      for (final k in [M5DarkFinal.climb, M5DarkFinal.poke]) {
        final x = marked()..toggleTorch();
        x.readPlate(1, 0);
        final m = x.report(k);
        expect(m!.deadly, isTrue, reason: '$k');
        expect(x.ended, isTrue);
        expect(x.deadly, m);
      }
    });

    test('the resident pays once, during the search; listening to the coworker is a slip; a clean play tags the headlamp', () {
      final r = M5DarkEyesRun(_deal1);
      expect(r.askResident(), isTrue);
      expect(r.askResident(), isFalse);
      expect(r.listen(), M5DarkEyesMistakes.listened);
      expect(r.slips, 1);
      final clean = _at(1000)..toggleHeadlamp();
      clean
        ..held()
        ..adaptDone()
        ..next()
        ..mark(1, 0, 2)
        ..next()
        ..toggleTorch()
        ..readPlate(1, 0)
        ..report(M5DarkFinal.report)
        ..next();
      expect(clean.passed, isTrue);
      expect(clean.percent, 100);
      expect(clean.caught, containsAll([M5DarkEyesLines.caughtCall, M5DarkEyesLines.caughtLamp, M5DarkEyesLines.caughtReport]));
    });

    test('English digits only; every mistake has its picture and a lesson point in range; two deadly; keys unique', () {
      final all = <String>[
        M5DarkEyesLines.intro,
        ...M5DarkEyesLines.tasks,
        ...M5DarkEyesLines.allWhyRight,
        ...M5DarkEyesLines.whyQ.values,
        ...M5DarkEyesLines.myths,
        ...M5DarkEyesLines.finalRight,
        ...M5DarkEyesLines.finalWrong.keys,
        ...M5DarkEyesLines.allResidentLines,
        ...M5DarkEyesLines.coworker.recordedLines,
        ...M5DarkEyesLines.coworker.right,
        ...M5DarkEyesLines.coworker.wrong,
        ...M5DarkEyesLines.coworker.asks,
        for (final m in M5DarkEyesMistakes.all) m.textBn,
        M5DarkEyesLines.allSet,
        M5DarkEyesLines.fail,
        M5DarkEyesLines.callHeld,
        M5DarkEyesLines.plate(27),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5DarkEyesLines.plate(27), contains('27'));
      expect(M5DarkEyesMistakes.all.where((m) => m.deadly).toSet(), {M5DarkEyesMistakes.climb, M5DarkEyesMistakes.poke});
      expect(M5DarkEyesMistakes.all.map((m) => m.key).toSet(), hasLength(M5DarkEyesMistakes.all.length));
      final arts = <String>{};
      for (final m in M5DarkEyesMistakes.all) {
        expect(m.key, startsWith('5.7/m5_dark_eyes/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        arts.add(m.art.split('/').last);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // Every picture in the folder is used (no stray assets).
      final files = Directory('assets/game/art/m5_dark_eyes').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, arts);
      expect(m5DarkEyesPacks.keys, ['do_5_7_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; the final deck is right + deadly + slip', () {
      expectSameLength('why', [...M5DarkEyesLines.allWhyRight, ...M5DarkEyesLines.myths]);
      expect(M5DarkEyesLines.myths.toSet().intersection(M5DarkEyesLines.allWhyRight.toSet()), isEmpty);
      for (final w in M5DarkWhy.values) {
        for (final c in M5Clue.values) {
          final right = M5DarkEyesLines.whyRight(w, c);
          expectLibrary('$w $c', right, M5DarkEyesLines.myths);
          expect(M5DarkEyesLines.whyQ[w], isNotEmpty);
          for (var k = 0; k < 10; k++) {
            final deal = dealChoices(right, M5DarkEyesLines.myths, math.Random(k));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
      }
      expectSameLength('final', [...M5DarkEyesLines.finalRight, ...M5DarkEyesLines.finalWrong.keys]);
      expectLibrary('final', M5DarkEyesLines.finalRight, M5DarkEyesLines.finalWrong.keys.toList());
      final seen = <String>{};
      for (var k = 0; k < 40; k++) {
        final deal = M5DarkEyesLines.dealFinal(math.Random(k));
        expect(deal, hasLength(3));
        expect(deal.where((o) => o.correct), hasLength(1));
        final kinds = [for (final o in deal.where((o) => !o.correct)) M5DarkEyesLines.finalKind(o.textBn)];
        expect(kinds.where((x) => x == M5DarkFinal.climb || x == M5DarkFinal.poke), hasLength(1), reason: '$kinds');
        expect(kinds.where((x) => x == M5DarkFinal.morning || x == M5DarkFinal.walkOn), hasLength(1), reason: '$kinds');
        seen.add(deal.map((o) => o.textBn).join('|'));
      }
      expect(seen.length, greaterThan(10));
      final cw = M5DarkEyesLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
    });

    test('rival lines: his push is the lesson myth word for word and listed for recording; his exit is recorded', () {
      final cw = M5DarkEyesLines.coworker;
      expect(cw.line, 'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।');
      expect(cw.recordedLines, [cw.line, cw.exitLine]);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      for (final l in cw.recordedLines) {
        if (LearnVoice.resolve(l, rival: true) == null) expect(M5DarkEyesLines.rivalLinesToRecord, contains(l), reason: l);
      }
    });

    test('geometry: insulator, plate and door areas never overlap, stay on screen, under the header and over the switch row', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M5DarkEyesGeo.forScene(h, 0);
        for (var s = 0; s < 3; s++) {
          final cam = M5DarkEyesGeo.camFor(M5DarkEyesGeo.stretchX[s]);
          final rects = [
            for (var p = 0; p < 2; p++) ...[
              for (var ph = 0; ph < 3; ph++) g.insulatorHit(s, p, ph),
              g.plateHit(s, p),
            ],
          ].map((r) => r.shift(Offset(-cam, 0))).toList();
          for (final r in rects) {
            expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h s $s');
            expect(r.right, lessThanOrEqualTo(360), reason: 'h $h s $s');
            expect(r.top, greaterThan(110), reason: 'below the header');
            expect(r.bottom, lessThan(g.groundY), reason: 'above the path and the switches');
          }
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              final x = rects[i].intersect(rects[j]);
              expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h s $s: $i/$j');
            }
          }
        }
        final door = g.doorHit.shift(Offset(-M5DarkEyesGeo.camFor(M5DarkEyesGeo.startX), 0));
        expect(door.left, greaterThanOrEqualTo(0));
        expect(door.bottom, lessThan(g.groundY + 20));
      }
      // The camera follows smoothly and settles on a stretch at its centre.
      var last = M5DarkEyesGeo.camFor(M5DarkEyesGeo.startX);
      for (var x = M5DarkEyesGeo.startX; x <= M5DarkEyesGeo.endX; x += 5) {
        final c = M5DarkEyesGeo.camFor(x);
        expect((c - last).abs(), lessThan(12), reason: 'x $x');
        last = c;
      }
      for (final c in M5DarkEyesGeo.stretchX) {
        expect(M5DarkEyesGeo.camFor(c), closeTo(c - 180, 0.01));
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

    testWidgets('the guide comes first: a tap does not skip him; then the scene and the switches', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M5DarkEyesPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M5DarkEyesLines.torch), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M5DarkEyesLines.torch), findsOneWidget);
      expect(_label(M5DarkEyesLines.headlamp), findsOneWidget);
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5, M5DarkEyesProbe());
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5DarkEyesLines.askWalk)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final want in [0, 2]) {
      testWidgets('flow (fault on stretch $want): the resident, the coworker refused, the dark wait, the mark, the plate, the report → pass', (t) async {
        final seed = _seedWhere((d) => d.stretch == want);
        final p = M5DarkEyesProbe();
        final c = await _open(t, seed, p);
        final d = p.run!.deal;
        expect(d.stretch, want);
        // The lit door: the resident names the landmark.
        await t.tapAt(_scr(p, p.geo!.doorHit.center));
        await _pump(t, 300);
        expect(find.text(d.residentLine), findsOneWidget);
        await _reason(t, M5DarkEyesLines.whyResident);
        await _firstStretch(t, p);
        await _walkTo(t, p, d.stretch);
        // Lights off, keep still: the clue comes after the wait.
        expect(p.run!.torch, isFalse);
        await t.tap(_label(M5DarkEyesLines.headlamp));
        await _pump(t, 2500);
        expect(p.run!.clueSeen, isFalse, reason: 'not before the wait');
        expect(find.byType(ChoiceDeck), findsNothing);
        await _pump(t, 3300);
        expect(p.run!.clueSeen, isTrue);
        expect(find.byKey(const ValueKey('clue')), findsOneWidget);
        await _reason(t, M5DarkEyesLines.whyDark);
        await t.longPressAt(_scr(p, p.geo!.insulator(d.stretch, d.pole, d.phase)));
        await _pump(t, 400);
        await _reason(t, M5DarkEyesLines.whyMark[d.clue]!);
        await t.tap(_label(M5DarkEyesLines.torch));
        await _pump(t, 300);
        await t.tapAt(_scr(p, p.geo!.plate(d.stretch, d.pole)));
        await _pump(t, 600);
        expect(find.byKey(const ValueKey('plate-chip')), findsOneWidget);
        await waitChoiceDeck(t);
        final right = _onScreen(M5DarkEyesLines.finalRight);
        expect(right, hasLength(1));
        await t.tap(right.single, warnIfMissed: false);
        await confirmChoice(t);
        await _pump(t, 1200);
        await _reason(t, M5DarkEyesLines.whyReport);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.7/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.7/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        for (final tag in [
          M5DarkEyesLines.caughtResident,
          M5DarkEyesLines.caughtCall,
          M5DarkEyesLines.caughtDark,
          M5DarkEyesLines.caughtMark,
          M5DarkEyesLines.caughtReport,
          M5DarkEyesLines.caughtLamp,
        ]) {
          expect(find.text(tag), findsOneWidget, reason: tag);
        }
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('walking with the headlamp off is a slip card; the same round goes on; he stays put', (t) async {
      final p = M5DarkEyesProbe();
      final c = await _open(t, 2, p);
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 300);
      final x = p.run!.walker;
      await _drag(t, 90);
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsOneWidget);
      final key = c.read(gameSaveProvider).mistakes.single.key;
      expect([M5DarkEyesMistakes.walkDark.key, M5DarkEyesMistakes.hole.key], contains(key));
      expect(p.run!.walker, x);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 300);
      await _drag(t, 90);
      expect(p.run!.walker, greaterThan(x), reason: 'in the light he walks on');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2, M5DarkEyesProbe());
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 300);
      for (var i = 0; i < 3; i++) {
        await _drag(t, 90);
        await _pump(t, 600);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('the walk waits for the coworker on the first stretch; listening to his myth is a slip (no freeze)', (t) async {
      final p = M5DarkEyesProbe();
      final c = await _open(t, _seedWhere((d) => d.stretch != 0), p);
      await _walkTo(t, p, 0);
      final x = p.run!.walker;
      // At once on: well inside his 1.2–2.4 s timer.
      await t.dragFrom(const Offset(150, 400), const Offset(90, 0));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      expect(p.run!.walker, x, reason: 'the walk waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5DarkEyesLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(M5DarkEyesMistakes.listened.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5DarkEyesMistakes.listened.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _drag(t, 90);
      expect(p.run!.walker, greaterThan(x), reason: 'the play goes on');
      await _close(t, c);
    });

    testWidgets('under the torch every insulator glints: marking a sound one is a slip', (t) async {
      final p = M5DarkEyesProbe();
      final c = await _open(t, _seedWhere((d) => d.stretch == 0), p);
      await _firstStretch(t, p);
      final d = p.run!.deal;
      await t.tap(_label(M5DarkEyesLines.torch));
      await _pump(t, 300);
      final other = (d.pole, (d.phase + 1) % 3);
      await t.longPressAt(_scr(p, p.geo!.insulator(0, other.$1, other.$2)));
      await _pump(t, 600);
      expect(find.text(M5DarkEyesMistakes.markGlint.textBn), findsOneWidget);
      expect(p.run!.marked, isFalse);
      await _close(t, c);
    });

    testWidgets('climbing (or a poke) at the final deck: the scene freezes first, then the card (near-miss)', (t) async {
      final p = M5DarkEyesProbe();
      final c = await _open(t, _seedWhere((d) => d.stretch == 1), p);
      await _toFinal(t, p);
      final deadly = _onScreen([
        for (final e in M5DarkEyesLines.finalWrong.entries)
          if (e.value == M5DarkFinal.climb || e.value == M5DarkFinal.poke) e.key,
      ]);
      expect(deadly, hasLength(1));
      await t.tap(deadly.single, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      expect([M5DarkEyesMistakes.climb.key, M5DarkEyesMistakes.poke.key], contains(s.mistakes.single.key));
      await _close(t, c);
    });

    testWidgets('gesture hand: door + path head alike, then a forward drag; none at a stretch while searching or in the dark wait; a forward drag after a fruitless wait', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M5DarkEyesProbe();
      final c = await _open(t, _seedWhere((d) => d.stretch != 0), p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle by the house');
      expect(scene().debugOptions, hasLength(2), reason: 'the door and the path head');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // Ask, then walk off into the gap: a forward drag nudge.
      await t.tapAt(_scr(p, p.geo!.doorHit.center));
      await _pump(t, 300);
      await _reason(t, M5DarkEyesLines.whyResident);
      await _drag(t, 120);
      await _pump(t, 600);
      expect(p.run!.zone, isNull);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle between stretches');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a choice');
      // The first stretch (the coworker refused): marking is not this round's
      // move and the switches are not hinted before the find — no hand.
      await _firstStretch(t, p);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'none at a stretch while searching');
      // Lights off: the dark wait shows no hand.
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 3000);
      expect(scene().showing, isFalse, reason: 'none during the wait');
      expect(p.adapting, isTrue);
      // The wait shows nothing here (not the fault stretch); still no hand
      // in the dark (walking unlit is a slip).
      await _pump(t, 3000);
      expect(p.run!.adapted, isTrue);
      expect(p.run!.clueSeen, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'never a walk nudge with the headlamp off');
      // Headlamp back on: a forward drag nudge.
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle after a fruitless wait');
      expect(scene().debugOptions, isEmpty, reason: 'a drag, not a choice');
      await _close(t, c);
    });

    testWidgets('gesture hand in the mark round: a look-around sweep over all six insulators', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final p = M5DarkEyesProbe();
      final c = await _open(t, _seedWhere((d) => d.stretch == 0), p);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _firstStretch(t, p);
      await t.tap(_label(M5DarkEyesLines.headlamp));
      await _pump(t, 5800);
      await _reason(t, M5DarkEyesLines.whyDark);
      expect(p.run!.round, M5DarkRound.mark);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle in the mark round');
      expect(scene().debugOptions, hasLength(6));
      await _close(t, c);
    });
  });
}
