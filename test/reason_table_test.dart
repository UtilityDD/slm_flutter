// The shared success beat (reason_table.dart) and the frame's input shield
// (full_scene_frame.dart): from putOnTable until the deck opens the scene and
// the overlays take no touch (no double ◆, no false slip), the header's close
// stays live; the deck itself and, after proceed, the scene work again.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/reason_table.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';

import 'support/reason_proceed.dart';

const _ctx = LevelContext(rungId: 't/do/0', kind: CatalogRungKind.doKind, lessonId: '1.1', lessonTitleBn: '', ladderStep: 2, doIndex: 1, doCount: 1);

const _right = ChoiceOption('ঠিক কারণটা এখানে লেখা', true);
const _wrong1 = ChoiceOption('ভুল কারণ এক নম্বর', false);
const _wrong2 = ChoiceOption('ভুল কারণ দুই নম্বর', false);

class _Probe extends ConsumerStatefulWidget {
  const _Probe();
  @override
  ConsumerState<_Probe> createState() => _ProbeState();
}

class _ProbeState extends ConsumerState<_Probe> with ReasonTable {
  int sceneTaps = 0;
  int overlayTaps = 0;
  int closes = 0;
  int paid = 0;
  int scored = 0;
  final _score = GlobalKey();

  @override
  bool get reasonMuted => true;
  @override
  bool get reasonEnded => false;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => Future<void>.delayed(const Duration(milliseconds: 700));
  @override
  void reasonHush() {}
  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) async => scored += delta;
  @override
  void onReasonPaid() => paid++;

  /// A right move, as a level does it.
  void right() {
    putOnTable(10);
    unawaited(askReason(deal: () => const [_wrong1, _right, _wrong2], question: 'কেন?'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FullSceneFrame(
        ctx: _ctx,
        titleBn: 'পরীক্ষা',
        scoreKey: _score,
        levelScore: scored,
        muted: true,
        onClose: () => closes++,
        onToggleMute: () {},
        layers: (_, _) => [
          Positioned.fill(
            key: const ValueKey('scene-tap'),
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => sceneTaps++),
          ),
        ],
        overlays: [
          ...tableLayers(at: const Offset(180, 140), quiet: true),
          Positioned(
            key: const ValueKey('overlay-btn'),
            left: 20,
            top: 300,
            child: ElevatedButton(onPressed: () => overlayTaps++, child: const Text('A')),
          ),
          if (reasonOpen)
            Positioned(key: const ValueKey('why-deck'), left: 0, right: 0, bottom: 0, child: reasonDeck(quiet: true)),
        ],
      ),
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the table pays what waited; after a burn a right retry pays 5', () {
    expect(whyPayout(pending: 20, retried: false), 20);
    expect(whyPayout(pending: 0, retried: true), 5);
    expect(whyPayout(pending: 0, retried: false), 0);
  });

  testWidgets('praise window: the scene and overlays take no touch, the header does', (t) async {
    t.view.physicalSize = const Size(720, 1520);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(const ProviderScope(child: MaterialApp(home: _Probe())));
    await t.pump(const Duration(milliseconds: 300));
    final s = t.state<_ProbeState>(find.byType(_Probe));

    await t.tapAt(const Offset(180, 600));
    await t.tap(find.text('A'));
    expect((s.sceneTaps, s.overlayTaps), (1, 1));
    expect(s.tableBusy, isFalse);

    s.right();
    await t.pump();
    expect(s.tableHolding, isTrue);
    expect(s.tableBusy, isTrue);
    await t.tapAt(const Offset(180, 600));
    await t.tap(find.text('A'), warnIfMissed: false);
    await t.pump();
    expect((s.sceneTaps, s.overlayTaps), (1, 1), reason: 'praise window swallows the second tap');
    await t.tap(find.byIcon(Icons.close_rounded));
    expect(s.closes, 1, reason: 'the header close still works');

    // The deck opens after praise + 650 ms: it is live, the scene still waits.
    await t.pump(const Duration(milliseconds: 1400));
    await t.pump(const Duration(milliseconds: 100));
    expect(s.reasonOpen, isTrue);
    expect(s.tableHolding, isFalse);
    expect(s.tableBusy, isTrue);
    await t.tap(find.text(_right.textBn));
    expect(s.scored, 0, reason: 'a tap only opens the card');
    expect(await confirmChoice(t), isTrue);
    await t.pump(const Duration(milliseconds: 900));
    expect(s.scored, 10);
    await t.tap(find.byKey(const ValueKey('reason-proceed-btn')));
    await t.pump();
    expect(s.paid, 1);
    expect(s.tableBusy, isFalse);
    await t.tapAt(const Offset(180, 600));
    expect(s.sceneTaps, 2, reason: 'the scene is live again');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
    MascotTalk.reset();
  });

  testWidgets('wrong reason stays red on the open deck; the right one waits for এগিয়ে যান (no timer)', (t) async {
    await t.pumpWidget(const ProviderScope(child: MaterialApp(home: _Probe())));
    final s = t.state<_ProbeState>(find.byType(_Probe));
    s.right();
    await t.pump(const Duration(milliseconds: 1500));
    await t.pump(const Duration(milliseconds: 100));
    expect(s.reasonOpen, isTrue);
    await pickChoice(t, _wrong1.textBn, proceed: false);
    await t.pump(const Duration(seconds: 20));
    expect(s.reasonOpen, isTrue, reason: 'a wrong reason never closes the deck by itself');
    expect(find.byKey(ValueKey('deal-${_wrong1.textBn}')), findsOneWidget);
    expect(s.scored, 0);
    await pickChoice(t, _right.textBn, proceed: false);
    await t.pump(const Duration(seconds: 30));
    expect(s.reasonAwaitingProceed, isTrue, reason: 'the zoomed reason stays up');
    expect(find.text(_right.textBn), findsOneWidget);
    expect(s.paid, 0);
    await t.tap(find.byKey(const ValueKey('reason-proceed-btn')));
    await t.pump();
    expect(s.paid, 1);
    expect(s.scored, 5, reason: 'burnt table, right retry pays 5');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
    MascotTalk.reset();
  });

  testWidgets('a level that moved on releases the hold (stillValid false)', (t) async {
    await t.pumpWidget(const ProviderScope(child: MaterialApp(home: _Probe())));
    final s = t.state<_ProbeState>(find.byType(_Probe));
    s.putOnTable(10);
    unawaited(s.askReason(deal: () => const [_wrong1, _right, _wrong2], question: 'কেন?', stillValid: () => false));
    await t.pump();
    expect(s.tableHolding, isTrue);
    await t.pump(const Duration(milliseconds: 1500));
    expect(s.tableHolding, isFalse);
    expect(s.reasonOpen, isFalse);
    await t.tapAt(const Offset(180, 400));
    expect(s.sceneTaps, 1);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('an explicit inputBlocked wins over the table', (t) async {
    var taps = 0;
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: FullSceneFrame(
            ctx: _ctx,
            titleBn: 'পরীক্ষা',
            scoreKey: GlobalKey(),
            levelScore: 0,
            muted: true,
            onClose: () {},
            onToggleMute: () {},
            inputBlocked: true,
            layers: (_, _) => [Positioned.fill(key: const ValueKey('s'), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => taps++))],
          ),
        ),
      ),
    ));
    await t.tapAt(const Offset(200, 400));
    expect(taps, 0);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
