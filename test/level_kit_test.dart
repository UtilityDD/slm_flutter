// Shared level kit: the death freeze swallows touches while it runs (the
// FullSceneFrame header — close — stays live); the
// careless coworker holds beat 1's caption for a reading time when muted, can
// hold a level's decisive control until he has come, never cuts into a
// praise window; a rival line with no recorded clip is silent (never the
// device voice) with its caption held.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/reason_table.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';

import 'support/reason_proceed.dart';

const _script = CoworkerScript(
  line: 'পরীক্ষার জন্য একটা লম্বা লাইন, তাড়াতাড়ি করো তো!',
  exitLine: 'পরীক্ষার বিদায়।',
  right: ['না, আগে নিয়ম মেনে কাজ', 'না, আগে পরীক্ষা করে কাজ'],
  wrong: ['ঠিক আছে, তাড়াতাড়ি করি', 'হ্যাঁ, পরে দেখে নেব', 'আচ্ছা, এবার ছেড়ে দিই'],
  asks: ['কী করবেন?'],
);

class _Probe extends ConsumerStatefulWidget {
  const _Probe();
  @override
  ConsumerState<_Probe> createState() => _ProbeState();
}

class _ProbeState extends ConsumerState<_Probe> with ReasonTable, CoworkerMoment {
  bool? can = true;
  final answers = <bool>[];

  @override
  CoworkerScript get coworkerScript => _script;
  @override
  math.Random get coworkerRng => math.Random(3);
  @override
  bool get coworkerMuted => true;
  @override
  bool? coworkerCanCome() => can;
  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) async {}
  @override
  void coworkerHush() {}
  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async => answers.add(held);

  @override
  bool get reasonMuted => true;
  @override
  bool get reasonEnded => false;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => Future<void>.delayed(const Duration(milliseconds: 500));
  @override
  void reasonHush() {}
  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) async {}
  @override
  void onReasonPaid() {}

  @override
  void dispose() {
    disposeCoworker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF223355))),
          if (coworkerChoiceUp) Positioned(key: const ValueKey('deck'), left: 0, right: 0, bottom: 0, child: coworkerDeck(quiet: true)),
          ?coworkerPeek(quiet: true, key: const ValueKey('coworker')),
        ],
      ),
    );
  }
}

Future<_ProbeState> _open(WidgetTester t) async {
  await t.pumpWidget(const ProviderScope(child: MaterialApp(home: _Probe())));
  return t.state<_ProbeState>(find.byType(_Probe));
}

Future<void> _close(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 6));
  MascotTalk.reset();
  RivalTalk.reset();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CoworkerTiming.debugReadHoldInTests = true;
    MascotSpeechLibrary.debugSilentHoldInTests = true;
  });
  tearDown(() {
    CoworkerTiming.debugReadHoldInTests = false;
    MascotSpeechLibrary.debugSilentHoldInTests = false;
  });

  group('FreezeFrame', () {
    testWidgets('swallows touches while it runs, lets them through after', (t) async {
      var taps = 0;
      var done = false;
      Widget app(bool freeze) => MaterialApp(
            home: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(key: const ValueKey('scene'), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => taps++)),
                  if (freeze) FreezeFrame(key: const ValueKey('freeze'), muted: true, ms: 1000, onDone: () => done = true),
                ],
              ),
            ),
          );
      await t.pumpWidget(app(true));
      await t.pump(const Duration(milliseconds: 100));
      await t.tapAt(const Offset(200, 300));
      expect(taps, 0, reason: 'the scene must not play on during a death');
      await t.pump(const Duration(milliseconds: 1000));
      expect(done, isTrue);
      await t.pump();
      await t.tapAt(const Offset(200, 300));
      expect(taps, 1, reason: 'after the freeze, touches pass again');
    });

    testWidgets('a card above the freeze stays live; fine inside a Positioned.fill', (t) async {
      var cardTaps = 0;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: FreezeFrame(muted: true, ms: 2000, onDone: () {})),
              Center(child: ElevatedButton(onPressed: () => cardTaps++, child: const Text('C'))),
            ],
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.text('C'));
      expect(cardTaps, 1);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('inside FullSceneFrame the header (close) stays live during the freeze', (t) async {
      t.view.physicalSize = const Size(720, 1520);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      var scene = 0, closes = 0, mutes = 0;
      var done = false;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FullSceneFrame(
              ctx: const LevelContext(rungId: 't/do/0', kind: CatalogRungKind.doKind, lessonId: '1.1', lessonTitleBn: '', ladderStep: 2, doIndex: 1, doCount: 1),
              titleBn: 'পরীক্ষা',
              scoreKey: GlobalKey(),
              levelScore: 0,
              muted: true,
              onClose: () => closes++,
              onToggleMute: () => mutes++,
              layers: (_, _) => [Positioned.fill(key: const ValueKey('s'), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => scene++))],
              overlays: [FreezeFrame(key: const ValueKey('freeze'), muted: true, ms: 2000, onDone: () => done = true)],
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await t.tapAt(const Offset(180, 500));
      expect(scene, 0, reason: 'the scene is frozen');
      await t.tap(find.byIcon(Icons.close_rounded));
      expect(closes, 1, reason: 'close works during the freeze');
      // The bar has no speaker button any more (owner's brief, Nov 2026).
      expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      expect(mutes, 0);
      await t.pump(const Duration(milliseconds: 2000));
      expect(done, isTrue);
      await t.pump();
      await t.tapAt(const Offset(180, 500));
      expect(scene, 1, reason: 'after the freeze the scene is live');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 2));
    });
  });

  group('CoworkerMoment', () {
    testWidgets('muted: beat 1 caption stays up for a reading time before the deck', (t) async {
      final s = await _open(t);
      s.scheduleCoworker();
      expect(s.coworkerDue, isTrue);
      for (var i = 0; i < 60 && !s.coworkerOpen; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(s.coworkerOpen, isTrue);
      final read = MascotSpeechLibrary.readHold(_script.line);
      await t.pump(read - const Duration(milliseconds: 300));
      expect(s.coworkerChoiceUp, isFalse, reason: 'the caption is not collapsed at once when muted');
      await t.pump(const Duration(milliseconds: 400));
      await t.pump();
      expect(s.coworkerChoiceUp, isTrue);
      expect(s.coworkerDue, isFalse);
      await _close(t);
    });

    testWidgets('holdForCoworker: the decisive control waits, he comes now', (t) async {
      final s = await _open(t);
      expect(s.holdForCoworker(), isFalse, reason: 'not scheduled: the control works');
      s.scheduleCoworker();
      s.can = false; // the level would say "not yet" …
      expect(s.holdForCoworker(), isTrue, reason: '… but a held control lets him in now');
      await t.pump();
      expect(s.coworkerOpen, isTrue);
      expect(s.coworkerHeld, isTrue);
      await s.answerCoworker(true, Offset.zero);
      await t.pump();
      expect(s.coworkerHeld, isFalse);
      expect(s.coworkerDue, isFalse);
      expect(s.holdForCoworker(), isFalse, reason: 'after him the control works again');
      expect(s.answers, [true]);
      await _close(t);
    });

    testWidgets('holdForCoworker: a moment that passed does not block', (t) async {
      final s = await _open(t);
      s.scheduleCoworker();
      s.can = null;
      expect(s.holdForCoworker(), isFalse);
      expect(s.coworkerDue, isFalse);
      await t.pump(const Duration(seconds: 3));
      expect(s.coworkerOpen, isFalse);
      await _close(t);
    });

    testWidgets('refuse/listen deck: a tap only opens the card; ✓ answers him once', (t) async {
      final s = await _open(t);
      s.scheduleCoworker();
      for (var i = 0; i < 200 && !s.coworkerChoiceUp; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(s.coworkerChoiceUp, isTrue);
      await waitChoiceDeck(t);
      final listen = _script.wrong.firstWhere((w) => find.byKey(ValueKey('deal-$w')).evaluate().isNotEmpty);
      await t.tap(find.byKey(ValueKey('deal-$listen')));
      await t.pump(const Duration(seconds: 3));
      expect(s.answers, isEmpty, reason: 'the preview answers nothing');
      expect(s.coworkerChoiceUp, isTrue);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await t.pump();
      expect(s.answers, isEmpty, reason: '✕ answers nothing');
      await pickChoice(t, listen, proceed: false);
      expect(s.answers, isEmpty, reason: 'the red shake shows first');
      await t.pump(const Duration(milliseconds: 550));
      expect(s.answers, [false]);
      expect(s.coworkerChoiceUp, isFalse);
      await _close(t);
    });

    testWidgets('he never cuts into a praise window', (t) async {
      final s = await _open(t);
      s.putOnTable(10);
      unawaited(s.askReason(deal: () => const [ChoiceOption('ক', true), ChoiceOption('খ', false), ChoiceOption('গ', false)], question: 'কেন?', stillValid: () => false));
      s.scheduleCoworker();
      await t.pump(const Duration(milliseconds: 1000));
      expect(s.tableHolding, isTrue);
      expect(s.coworkerOpen, isFalse);
      await t.pump(const Duration(milliseconds: 3000));
      expect(s.tableHolding, isFalse);
      expect(s.coworkerOpen, isTrue, reason: 'he comes once the window is over');
      await _close(t);
    });
  });

  group('rival voice', () {
    testWidgets('a rival line with no clip is silent, lips still, caption held', (t) async {
      const line = 'এই লাইনের কোনো রেকর্ড করা ক্লিপ নেই, পরীক্ষা মাত্র।';
      var done = false;
      final talked = <bool>[];
      void listen() => talked.add(RivalTalk.active.value || MascotTalk.active.value);
      RivalTalk.active.addListener(listen);
      MascotTalk.active.addListener(listen);
      addTearDown(() {
        RivalTalk.active.removeListener(listen);
        MascotTalk.active.removeListener(listen);
      });
      unawaited(MascotSpeechLibrary.speak(line, rival: true).then((_) => done = true));
      final read = MascotSpeechLibrary.readHold(line);
      await t.pump(read - const Duration(milliseconds: 200));
      expect(done, isFalse, reason: 'held for a reading time');
      expect(talked.where((v) => v), isEmpty, reason: 'no mouth moves');
      await t.pump(const Duration(milliseconds: 400));
      expect(done, isTrue);

      done = false;
      unawaited(MascotSpeechLibrary.speak(line, rival: true).then((_) => done = true));
      await t.pump(const Duration(milliseconds: 300));
      await MascotSpeechLibrary.stop();
      await t.pump();
      expect(done, isTrue, reason: 'stop ends the hold at once');
    });
  });
}
