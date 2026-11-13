// Lesson 1.9 কাজ 2 (সুপারভাইজারের চাপ): the rules of the storm calls (routine
// work stops in drizzle; only an emergency fault goes on, with waterproof
// gloves; a gale or lightning = no climbing, deadly), the deal, reason
// libraries that fit the situation, the supervisor's recorded lines, and the
// level in the shell: idle perf, the guide first, a full clean play (the
// supervisor refused, gloves, the ladder, the reasons, the shelter), slips
// (one card, three strike out), the deadly freeze, the supervisor on a fast
// play (the ladder waits for him), a needless stop (no ◆, neutral reply, no
// third star) and the gesture hints (how, never what).
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
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
import 'support/reason_proceed.dart';

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
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  // A right reason zooms and waits for এগিয়ে যান; a coworker deck just closes.
  await tapReasonProceed(t);
}

/// Words (Bangla runs) found in every right option and in no wrong one: a
/// tell that picks the answer without reading it.
Set<String> _rightOnlyWords(List<String> right, List<String> wrong) {
  Set<String> words(String l) => RegExp('[\u0980-\u09FF]+').allMatches(l).map((m) => m.group(0)!).toSet();
  final common = right.map(words).reduce((a, b) => a.intersection(b));
  final inWrong = wrong.map(words).fold(<String>{}, (a, b) => a..addAll(b));
  return common.difference(inWrong);
}

/// Pieces of words (Bangla runs, 3+ letters, found inside other words too)
/// on every wrong option but missing from some right one: when that right
/// card is dealt it is the only one without them (e.g. "বাতাস" on every gale
/// excuse but not on one gale reason).
Set<String> _wrongEverywhereWords(List<String> right, List<String> wrong) => {
      for (final w in [...right, ...wrong].expand((l) => RegExp('[ঀ-৿]+').allMatches(l).map((m) => m.group(0)!)))
        if (w.length >= 3 && wrong.every((l) => l.contains(w)) && right.any((l) => !l.contains(w))) w,
    };

/// The first seed from [from] whose deal passes [ok].
int _seed(bool Function(StormDeal d) ok, {int from = 0}) {
  var s = from;
  while (!ok(dealStorm(math.Random(s)))) {
    s++;
  }
  return s;
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {int settleMs = 1900}) async {
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
  await _pump(t, settleMs);
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

    test('saying no: right in drizzle-routine, gale and thunder (then the shelter); "না" to the emergency is a needless stop', () {
      for (final c in [_routine, _gale, _storm]) {
        final r = _runOf(c);
        expect(r.stop(), StormStop.right, reason: '$c');
        expect(r.slips, 0);
        expect(r.needless, 0);
        expect(r.phase, c.needsShelter ? StormPhase.shelter : StormPhase.shown);
      }
      // One "না" ends it: no second try that would show it may go on.
      final e = _runOf(_emergency);
      expect(e.stop(), StormStop.declined, reason: 'his right, but needless');
      expect(e.phase, StormPhase.shown);
      expect(e.needless, 1, reason: 'it costs the clean play');
      expect(e.slips, 0, reason: 'never a slip: Stop Work is his right');
      expect(e.percent, 100);
      expect(e.caught, isEmpty, reason: 'no ◆ tag for it');
      expect(e.climb(), isNull, reason: 'the situation is over');
    });

    test('after a deadly the rules take nothing more', () {
      final r = StormRun(const StormDeal(cases: [_storm, _routine, _emergency], callRound: 1));
      expect(r.climb(), StormMistakes.lightningClimb);
      r.next();
      expect(r.round, 0, reason: 'no next situation after a death');
      expect(r.stop(), StormStop.ignored);
      expect(r.shelter(StormPlace.van), isNull);
      expect(r.slips, 0);
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
      // No giveaway word: nothing found on every right card and no wrong one
      // (e.g. "জরুরি" only on the go-on reasons, "বজ্র" only on the storm's).
      for (final c in [_routine, _emergency, _gale, _storm]) {
        expect(_rightOnlyWords(StormLines.whyRight(c), StormLines.whyWrong(c)), isEmpty, reason: '$c');
      }
      expect(StormLines.whyWrong(_storm).every((l) => l.contains('বজ্র')), isTrue, reason: 'every storm card names the sky');
      expect(StormLines.whyWrong(_gale).every((l) => l.contains('বাতাস')), isTrue);
      expect(StormLines.whyRight(_gale).every((l) => l.contains('বাতাস')), isTrue, reason: 'the right ones name it too');
      // And the reverse: nothing on every wrong card that a right one lacks.
      for (final c in [_routine, _emergency, _gale, _storm]) {
        expect(_wrongEverywhereWords(StormLines.whyRight(c), StormLines.whyWrong(c)), isEmpty, reason: '$c');
      }
      expect(_wrongEverywhereWords(StormLines.shelterRight, StormLines.shelterWrong), isEmpty);
      expect(_rightOnlyWords(StormLines.shelterRight, StormLines.shelterWrong), isEmpty);
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
        expect(_rightOnlyWords(s.right, s.wrong), isEmpty, reason: '$cue');
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
        ...StormLines.windWrong,
        ...StormLines.thunderWrong,
        ...StormLines.goRight,
        ...StormLines.goWrong,
        ...StormLines.shelterRight,
        ...StormLines.shelterWrong,
        ...StormLines.pushLines,
        ...StormLines.refuseAny,
        ...StormLines.listen,
        ...StormLines.asks,
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
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
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

    /// Plays a whole deal clean; [needless] lays the ladder down on the
    /// go-on situation instead of climbing it gloved.
    Future<void> playAll(WidgetTester t, StormDeal deal, {bool needless = false}) async {
      for (var i = 0; i < 3; i++) {
        final k = deal.cases[i];
        if (i == deal.callRound) {
          await _pump(t, 3000);
          expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'round $i');
          expect(find.text(StormLines.supervisorTag), findsOneWidget);
          await _pickRight(t, StormLines.coworker(k.cue).right);
          await _pump(t, 2500);
        }
        if (k.mayGoOn && needless) {
          await _down(t);
          await _pump(t, i == 2 ? 6000 : 3500);
          continue;
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
    }

    testWidgets('flow: refuse the supervisor, gloves for the emergency, the ladder down in the storms, reasons, the van → pass', (t) async {
      // A play with the go-on situation, and him in a later round.
      final seed = _seed((d) => d.cases.any((c) => c.mayGoOn) && d.callRound > 0);
      final deal = dealStorm(math.Random(seed));
      final c = await _open(t, seed);
      await playAll(t, deal);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], 3, reason: 'clean and quick');
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(StormLines.caughtCall), findsOneWidget);
      expect(find.text(StormLines.caughtShelter), findsOneWidget);
      expect(find.text(StormLines.caughtEmergency), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a needless stop costs the clean play: a pass, but no third star and no quick bonus', (t) async {
      final seed = _seed((d) => d.cases.any((c) => c.mayGoOn) && d.callRound > 0);
      final deal = dealStorm(math.Random(seed));
      final c = await _open(t, seed);
      await playAll(t, deal, needless: true);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.mistakes, isEmpty, reason: 'never a slip');
      expect(s.starsByRung[_rung], 2);
      final panel = t.widget<LevelPassPanel>(find.byType(LevelPassPanel));
      expect(panel.quickBonus, isFalse);
      expect(panel.caughtBn, isNot(contains(StormLines.caughtEmergency)));
      await _close(t, c);
    });

    testWidgets('the supervisor comes even on a fast play: the ladder waits for him', (t) async {
      // His situation first, and the hands are quicker than his timer (1.2–2.4 s
      // from the docket): step through seeds until one where the ladder is
      // ready (1.5 s) and he has not come yet.
      late int seed;
      late ProviderContainer c;
      var from = 0;
      for (var tries = 0;; tries++) {
        expect(tries, lessThan(40), reason: 'a seed where he is still on his way');
        seed = _seed((d) => d.callRound == 0 && !d.cases.first.mayGoOn, from: from);
        c = await _open(t, seed, settleMs: 1550);
        if (find.byType(CoworkerPeek).evaluate().isEmpty) break;
        await _close(t, c);
        from = seed + 1;
      }
      final k = dealStorm(math.Random(seed)).cases.first;
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not come yet');
      await _down(t);
      await t.pump();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the drag brings him in now');
      await _pump(t, 600);
      expect(find.text(StormLines.whyAsk(k)), findsNothing, reason: 'the ladder did not act');
      await _pickRight(t, StormLines.coworker(k.cue).right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _down(t);
      await _pump(t, 2500);
      expect(find.text(StormLines.whyAsk(k)), findsWidgets, reason: 'after him the ladder works');
      await _close(t, c);
    });

    testWidgets('three slips strike out: the lone tree, the pole, the tree again', (t) async {
      final seed = _seed((d) => d.cases.first.cue == StormCue.thunder && d.callRound != 0);
      final c = await _open(t, seed);
      await _down(t);
      await _pump(t, 2500);
      await _pickRight(t, StormLines.thunderRight);
      await _pump(t, 3000);
      for (final p in [StormPlace.tree, StormPlace.pole]) {
        await t.tap(_label(StormLines.placeLabel(p)));
        await _pump(t, 1800);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: '$p');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 900);
      }
      expect(find.byType(StruckOutCard), findsNothing);
      await t.tap(_label(StormLines.placeLabel(StormPlace.tree)));
      await _pump(t, 1800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], isNot('cleared'));
      expect(s.mistakes.map((m) => m.key), containsAll([StormMistakes.shelterTree.key, StormMistakes.shelterPole.key]));
      expect(_label(StormLines.placeLabel(StormPlace.van)), findsNothing, reason: 'the play is over');
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

    testWidgets('"না" to the emergency in plain drizzle: no card, no ◆, a neutral reply (never "it may go on"); it moves on', (t) async {
      final seed = _seed((d) => d.cases.first.mayGoOn);
      final c = await _open(t, seed);
      int score() => t.widget<FullSceneFrame>(find.byType(FullSceneFrame)).levelScore;
      final before = score();
      await _down(t);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no ◆, no why');
      final line = c.read(guideDirectorProvider).line;
      expect(line, StormLines.declined);
      for (final tell in ['সারা যায়', 'জরুরি', 'গ্লাভস', 'পাঠ বলে']) {
        expect(line, isNot(contains(tell)), reason: 'the reply never tells it could go on');
      }
      await _pump(t, 2600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(StruckOutCard), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, isEmpty);
      expect(score(), before, reason: 'no −10, no ◆');
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

    group('gesture hints', () {
      setUp(() => GestureHints.debugEnableInTests = true);
      tearDown(() => GestureHints.debugEnableInTests = false);

      // The scene's own hand (the frame's, with the level's controller), never
      // a deck's.
      IdleHintState hand(WidgetTester t) =>
          t.state<IdleHintState>(find.byWidgetPredicate((w) => w is IdleHint && w.controller != null).first);

      /// The vertical way of the ladder nudge now showing: −1 up, +1 down.
      Future<double> nudgeWay(WidgetTester t) async {
        for (var i = 0; i < 200; i++) {
          final f = hand(t).debugFrame;
          if (f != null && f.trailFrom != null && (f.tip - f.trailFrom!).distance > 6) {
            return (f.tip.dy - f.trailFrom!.dy).sign;
          }
          await t.pump(const Duration(milliseconds: 50));
        }
        fail('no ladder nudge moved');
      }

      testWidgets('judge: a short nudge on the ladder after idle, up and down by turns; the shelter: a sweep over all three places', (t) async {
        final seed = _seed((d) => d.cases.first.cue == StormCue.thunder && d.callRound != 0);
        final c = await _open(t, seed);
        expect(hand(t).showing, isFalse);
        await _pump(t, 8600);
        expect(hand(t).showing, isTrue, reason: 'idle while the ladder waits');
        final f = hand(t).debugFrame!;
        expect(f.trailFrom, isNotNull, reason: 'a drag');
        expect((f.tip - f.trailFrom!).distance, lessThanOrEqualTo(HintSpec.maxDragTravel * 1.2), reason: 'a short nudge, never to a target');
        final first = await nudgeWay(t);
        expect(first, isNot(0));
        // Any touch hides it.
        await t.tapAt(const Offset(40, 300));
        await t.pump();
        expect(hand(t).showing, isFalse);
        // The next show goes the other way (both are moves).
        await _pump(t, 8600);
        expect(hand(t).showing, isTrue, reason: 'idle again');
        expect(await nudgeWay(t), -first, reason: 'up and down by turns');
        await t.tapAt(const Offset(40, 300));
        await t.pump();
        // The ladder down, the reason, then the shelter: a sweep.
        await _down(t);
        await _pump(t, 2500);
        await _pickRight(t, StormLines.thunderRight);
        await _pump(t, 3000);
        expect(_label(StormLines.placeLabel(StormPlace.van)), findsOneWidget);
        await _pump(t, 8600);
        expect(hand(t).showing, isTrue);
        expect(hand(t).debugOptions, hasLength(StormPlace.values.length), reason: 'every place, the same way');
        await _close(t, c);
      });

      testWidgets('no hand over a mistake card; taps on the ladder count as misses', (t) async {
        final seed = _seed((d) => d.cases.first == _routine && d.callRound != 0);
        final c = await _open(t, seed);
        // Three taps on the ladder (it must be dragged): the hand at once.
        for (var i = 0; i < 3; i++) {
          await t.tap(_label(StormLines.ladderLabel), warnIfMissed: false);
          await t.pump(const Duration(milliseconds: 120));
        }
        expect(hand(t).showing, isTrue);
        await _up(t);
        await _pump(t, 1200);
        expect(find.text(MistakeLines.slipHead), findsOneWidget);
        await _pump(t, 9000);
        expect(hand(t).showing, isFalse, reason: 'never over a mistake card');
        await _close(t, c);
      });

      testWidgets('no scene hand while the supervisor is on screen, however long he waits', (t) async {
        final seed = _seed((d) => d.callRound == 0 && !d.cases.first.mayGoOn);
        final c = await _open(t, seed, settleMs: 3000);
        expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he has come');
        // Longer than the idle wait: the ladder's nudge never shows over him.
        for (var i = 0; i < 200; i++) {
          await t.pump(const Duration(milliseconds: 50));
          expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he waits for an answer');
          expect(hand(t).showing, isFalse, reason: 'tick $i');
        }
        await _close(t, c);
      });
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
      await confirmChoice(t);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
