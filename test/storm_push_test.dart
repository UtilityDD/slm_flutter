// Lesson 1.9 কাজ 2 (সুপারভাইজারের চাপ): the rules of the storm calls (routine
// work stops in drizzle; only an emergency fault goes on, with waterproof
// gloves; a gale or lightning = no climbing, deadly), the deal, reason
// libraries that fit the situation, the supervisor's recorded lines, and the
// level in the shell: idle perf, the guide first, a full clean play (the
// supervisor refused, gloves, the ladder, the reasons, the shelter), slips
// (one card, three strike out) and the deadly freeze.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/game/storm_push.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _rung = '1.9/do/1';
final _pack = stormPushPacks['do_1_9_b']!;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.doKind,
      lessonId: '1.9',
      lessonTitleBn: '',
      ladderStep: 27,
      doIndex: 2,
      doCount: 2,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

/// The first seed from [from] whose deal passes [ok].
int _seed(bool Function(StormDeal d) ok, {int from = 0}) {
  var s = from;
  while (!ok(dealStorm(math.Random(s)))) {
    s++;
  }
  return s;
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => StormPushPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1900);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _up(WidgetTester t) => t.drag(_label(StormLines.ladderLabel), const Offset(0, -220), warnIfMissed: false);
Future<void> _down(WidgetTester t) => t.drag(_label(StormLines.ladderLabel), const Offset(0, 220), warnIfMissed: false);

const _routine = StormCase(cue: StormCue.drizzle, job: StormJob.routine);
const _emergency = StormCase(cue: StormCue.drizzle, job: StormJob.emergency);
const _gale = StormCase(cue: StormCue.wind, job: StormJob.emergency);
const _storm = StormCase(cue: StormCue.thunder, job: StormJob.routine);

StormRun _runOf(StormCase c) => StormRun(StormDeal(cases: [c], callRound: 0));

void main() {
  group('rules', () {
    test('deal: 3 situations, always a thunderstorm, never all go-on; he pushes in an unsafe one; fresh every play', () {
      final seen = <String>{};
      var emergencyPlays = 0;
      final hisCues = <StormCue>{};
      final jobsInStorm = <StormJob>{};
      for (var s = 0; s < 80; s++) {
        final d = dealStorm(math.Random(s));
        expect(d.cases, hasLength(3));
        expect(d.cases.where((c) => c.cue == StormCue.thunder), hasLength(1));
        expect(d.cases.where((c) => c.mayGoOn).length, lessThanOrEqualTo(1));
        expect(d.cases.where((c) => !c.mayGoOn).length, greaterThanOrEqualTo(2));
        expect(d.cases.toSet(), hasLength(3), reason: 'three different situations');
        expect(d.cases.where((c) => c.cue == StormCue.wind).length, lessThanOrEqualTo(1));
        expect(d.cases[d.callRound].mayGoOn, isFalse, reason: 'he never pushes where the lesson allows it');
        if (d.cases.any((c) => c.mayGoOn)) emergencyPlays++;
        hisCues.add(d.cases[d.callRound].cue);
        for (final c in d.cases.where((c) => c.stormy)) {
          jobsInStorm.add(c.job);
        }
        seen.add('${d.cases.map((c) => '${c.cue.name}${c.job.name}').join('|')}@${d.callRound}');
      }
      expect(seen.length, greaterThan(15), reason: 'every play is dealt fresh');
      expect(emergencyPlays, inInclusiveRange(15, 65), reason: 'the go-on situation in some plays, not all');
      expect(hisCues, containsAll(StormCue.values), reason: 'he pushes in drizzle, gale or thunder');
      expect(jobsInStorm, containsAll(StormJob.values), reason: 'an emergency docket does not make a storm safe');
    });

    test('climbing: in a gale or lightning deadly; routine in drizzle a slip; the emergency needs the gloves first', () {
      final storm = _runOf(_storm);
      expect(storm.climb(), StormMistakes.lightningClimb);
      expect(storm.deadly!.deadly, isTrue);
      expect(storm.ended, isTrue);
      final gale = _runOf(_gale)..takeGloves();
      expect(gale.climb(), StormMistakes.galeClimb, reason: 'even an emergency, even gloved');
      expect(gale.ended, isTrue);
      final routine = _runOf(_routine)..takeGloves();
      expect(routine.climb(), StormMistakes.routineInRain);
      expect(routine.slips, 1);
      expect(routine.deadly, isNull);
      expect(routine.phase, StormPhase.shown, reason: 'the play moves on');
      final bare = _runOf(_emergency);
      expect(bare.climb(), StormMistakes.noGloves);
      expect(bare.slips, 1);
      expect(bare.phase, StormPhase.judge, reason: 'still to do');
      bare.takeGloves();
      expect(bare.climb(), isNull);
      expect(bare.phase, StormPhase.shown);
      expect(bare.caught, contains(StormLines.caughtEmergency));
    });

    test('saying no: right in drizzle-routine, gale and thunder (then the shelter); "না" to the emergency costs nothing', () {
      for (final c in [_routine, _gale, _storm]) {
        final r = _runOf(c);
        expect(r.stop(), StormStop.right, reason: '$c');
        expect(r.slips, 0);
        expect(r.phase, c.needsShelter ? StormPhase.shelter : StormPhase.shown);
      }
      final e = _runOf(_emergency);
      expect(e.stop(), StormStop.mayGoOn, reason: 'the lesson allows it: it stays');
      expect(e.phase, StormPhase.judge);
      expect(e.stop(), StormStop.declined, reason: 'a second "না" is his right');
      expect(e.phase, StormPhase.shown);
      expect(e.slips, 0);
      expect(e.percent, 100);
      expect(e.caught, isEmpty, reason: 'no ◆ tag for it');
    });

    test('shelter: the van is right; the lone tree or the pole\'s foot a slip, choose again', () {
      final r = _runOf(_storm)..stop();
      expect(r.shelter(StormPlace.tree), StormMistakes.shelterTree);
      expect(r.shelter(StormPlace.pole), StormMistakes.shelterPole);
      expect(r.slips, 2);
      expect(r.phase, StormPhase.shelter);
      expect(r.shelter(StormPlace.van), isNull);
      expect(r.phase, StormPhase.shown);
      expect(r.caught, containsAll([StormLines.caughtThunder, StormLines.caughtShelter]));
    });

    test('mistakes: pictures, lesson points (1.9: rain 0, lightning 1, wind 2), only the storm climbs deadly', () {
      for (final m in StormMistakes.all) {
        expect(m.art, startsWith('assets/game/art/storm_board/push_'));
        expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(StormMistakes.all.where((m) => m.deadly), unorderedEquals([StormMistakes.galeClimb, StormMistakes.lightningClimb]));
      expect(StormMistakes.lightningClimb.lessonPoint, 1);
      expect(StormMistakes.galeClimb.lessonPoint, 2);
      expect(StormMistakes.routineInRain.lessonPoint, 0);
      expect(StormMistakes.all.map((m) => m.key), isNot(contains('1.9/push/needless-stop')));
    });

    test('reasons fit the situation: same length, big enough, one right per deal', () {
      for (final c in [_routine, _emergency, _gale, _storm]) {
        final right = StormLines.whyRight(c);
        final wrong = StormLines.whyWrong(c);
        expectSameLength('why $c', [...right, ...wrong]);
        expectLibrary('why $c', right, wrong);
        for (var s = 0; s < 12; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(StormLines.whyRight(_gale), StormLines.windRight, reason: 'an emergency docket in a gale is still a stop');
      expect(StormLines.whyRight(_emergency), StormLines.goRight);
      expectSameLength('shelter', [...StormLines.shelterRight, ...StormLines.shelterWrong]);
      expectLibrary('shelter', StormLines.shelterRight, StormLines.shelterWrong);
      // A myth is never a right reason.
      for (final c in [_routine, _gale, _storm]) {
        expect(StormLines.whyRight(c).where((l) => l.contains('রাবার')), isEmpty);
      }
      // No wording tell: no ending, care word or van shared by one side only.
      bool tai(String l) => l.contains('তাই');
      for (final c in [_routine, _gale, _storm]) {
        expect(StormLines.whyRight(c).any(tai) && StormLines.whyWrong(c).any(tai), isTrue, reason: '$c');
        expect(StormLines.whyWrong(c).where(tai).length, lessThan(StormLines.whyWrong(c).length ~/ 2));
      }
      bool care(String l) => l.contains('সাবধান') || l.contains('সতর্ক');
      expect(StormLines.goRight.any(care) && StormLines.goWrong.any(care), isTrue);
      expect(StormLines.goRight.every(care), isFalse);
      bool van(String l) => l.contains('গাড়ি');
      expect(StormLines.shelterRight.any(van) && StormLines.shelterWrong.any(van), isTrue);
      expect(StormLines.shelterWrong.where(tai), isEmpty);
    });

    test('the supervisor: his push is the lesson\'s myth, recorded in the rival\'s voice; the deck refuses or listens', () {
      for (final cue in StormCue.values) {
        final s = StormLines.coworker(cue);
        expect(s.line, startsWith('হালকা বৃষ্টি'));
        expect(s.tag, StormLines.supervisorTag);
        expectSameLength('choice $cue', [...s.right, ...s.wrong]);
        expectLibrary('choice $cue', s.right, s.wrong);
        for (final l in s.recordedLines) {
          expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
        }
        // "না" opens cards on both sides: no tell.
        expect(s.right.every((r) => r.startsWith('না')), isFalse, reason: '$cue');
        expect(s.wrong.any((r) => r.startsWith('না')), isTrue);
      }
      expect(StormLines.pushLines, hasLength(3));
    });

    test('English digits only on screen; the words of the house', () {
      final all = <String>[
        StormLines.intro,
        ...StormLines.tasks,
        ...StormLines.drizzleRight,
        ...StormLines.windRight,
        ...StormLines.thunderRight,
        ...StormLines.stopWrong,
        ...StormLines.goRight,
        ...StormLines.goWrong,
        ...StormLines.shelterRight,
        ...StormLines.shelterWrong,
        ...StormLines.pushLines,
        ...StormLines.refuseAny,
        ...StormLines.listen,
        ...StormLines.asks,
        StormLines.mayGoOn,
        StormLines.mayGoOnStill,
        StormLines.declined,
        for (final m in StormMistakes.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l, isNot(contains('পানি')), reason: l);
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
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        // A thunderstorm first (flashes, driving rain), and he is not due yet.
        final seed = _seed((d) => d.cases.first.cue == StormCue.thunder && d.callRound != 0);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: StormPushPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF storm_push ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the ladder is in his hands', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: StormPushPage(ctx: _ctx(), pack: _pack, muted: true, seed: 3)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(StormLines.ladderLabel), findsNothing);
      await waitIntro(t);
      await _pump(t, 1900);
      expect(_label(StormLines.ladderLabel), findsOneWidget);
      expect(find.text(StormLines.docket), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, _seed((d) => d.callRound != 0));
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(StormLines.askJudge)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: refuse the supervisor, gloves for the emergency, the ladder down in the storms, reasons, the van → pass', (t) async {
      // A play with the go-on situation, and him in a later round.
      final seed = _seed((d) => d.cases.any((c) => c.mayGoOn) && d.callRound > 0);
      final deal = dealStorm(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        final k = deal.cases[i];
        if (i == deal.callRound) {
          await _pump(t, 3000);
          expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'round $i');
          expect(find.text(StormLines.supervisorTag), findsOneWidget);
          await _pickRight(t, StormLines.coworker(k.cue).right);
          await _pump(t, 2500);
        }
        if (k.mayGoOn) {
          await t.tap(_label(StormLines.glovesLabel));
          await _pump(t, 400);
          await _up(t);
        } else {
          await _down(t);
        }
        await _pump(t, 2500);
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i');
        expect(find.text(StormLines.whyAsk(k)), findsWidgets);
        await _pickRight(t, StormLines.whyRight(k));
        await _pump(t, 3000);
        if (k.needsShelter) {
          expect(_label(StormLines.placeLabel(StormPlace.van)), findsOneWidget);
          await t.tap(_label(StormLines.placeLabel(StormPlace.van)));
          await _pump(t, 2800);
          expect(find.text(StormLines.whyShelter), findsWidgets);
          await _pickRight(t, StormLines.shelterRight);
          await _pump(t, 3000);
        }
        await _pump(t, i == 2 ? 4000 : 1900);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(StormLines.caughtCall), findsOneWidget);
      expect(find.text(StormLines.caughtShelter), findsOneWidget);
      expect(find.text(StormLines.caughtEmergency), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a routine job in drizzle: up the ladder is a slip with its card, no freeze; the next situation comes', (t) async {
      final seed = _seed((d) => d.cases.first == _routine && d.callRound != 0);
      final c = await _open(t, seed);
      await _up(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, StormMistakes.routineInRain.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2200);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(StormLines.ladderLabel), findsOneWidget, reason: 'on to the next situation');
      await _close(t, c);
    });

    testWidgets('"না" to the emergency in plain drizzle: no card, no cost; the guide says it may go on; a second "না" moves on', (t) async {
      final seed = _seed((d) => d.cases.first.mayGoOn);
      final c = await _open(t, seed);
      int score() => t.widget<FullSceneFrame>(find.byType(FullSceneFrame)).levelScore;
      final before = score();
      await _down(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no ◆, no why');
      expect(c.read(guideDirectorProvider).line, anyOf(StormLines.mayGoOn, StormLines.mayGoOnStill));
      expect(_label(StormLines.ladderLabel), findsOneWidget, reason: 'the same situation');
      expect(find.text(StormLines.job(StormJob.emergency)), findsOneWidget);
      await _down(t);
      await _pump(t, 2600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(StruckOutCard), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, isEmpty);
      expect(score(), before, reason: 'no −10');
      expect(find.text(StormLines.job(dealStorm(math.Random(seed)).cases[1].job)), findsOneWidget, reason: 'on to the next situation');
      await _close(t, c);
    });

    testWidgets('a lone tree in the thunderstorm: a slip with its card; then the van', (t) async {
      final seed = _seed((d) => d.cases.first.cue == StormCue.thunder && d.callRound != 0);
      final c = await _open(t, seed);
      await _down(t);
      await _pump(t, 2500);
      await _pickRight(t, StormLines.thunderRight);
      await _pump(t, 3000);
      await t.tap(_label(StormLines.placeLabel(StormPlace.tree)));
      await _pump(t, 1800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, StormMistakes.shelterTree.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 900);
      await t.tap(_label(StormLines.placeLabel(StormPlace.van)));
      await _pump(t, 2800);
      expect(find.text(StormLines.whyShelter), findsWidgets);
      await _close(t, c);
    });

    testWidgets('up the ladder in a gale or a thunderstorm: the scene freezes first, then the card', (t) async {
      final seed = _seed((d) => d.cases.first.stormy && d.callRound != 0);
      final c = await _open(t, seed);
      await _up(t);
      await _pump(t, 600);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('doom')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to the supervisor in a storm: up the ladder, frozen, deadly', (t) async {
      final seed = _seed((d) => d.callRound == 0 && d.cases.first.stormy);
      final c = await _open(t, seed);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      // The ladder waits for him: before he came, nothing could be done.
      final wrong = _onScreen(StormLines.listen);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
