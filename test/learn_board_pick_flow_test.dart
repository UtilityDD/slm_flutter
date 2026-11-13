// Learn boards (LearnBoardRunnerPage), the owner's UI brief of 2026-11-12:
// a tap on a card only opens it large (✓ বেছে নিন / ✕ বাদ দিন, the same for
// every card); ✕ sets it aside (not wrong) and it can be opened again; only ✓
// runs the pick, once; the feedback stays under the card until "এগিয়ে যান";
// the top bar shows L<n> (no name, no sound button) and fits every phone.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/board_pick.dart';

const _pack = learnBoardPack13;

/// Has read lesson 1.3 already, so the board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['1_3', '1.3']));
}

void _muteAudio() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), ok);
  }
}

/// A dealt card (`pick-…` or `why-…`) whose id is one of [ids].
Finder _dealt(String kind, Set<String> ids) => find.byWidgetPredicate((w) {
      final k = w.key;
      return w.runtimeType.toString() == '_AnimatedChoiceCard' &&
          k is ValueKey<String> &&
          k.value.startsWith('$kind-') &&
          ids.contains(k.value.split('-').skip(2).join('-'));
    });

LearnBoardSlot get _first => _pack.slots.first;
Set<String> get _safe => {for (final o in _first.options) if (o.correct) o.id};
Set<String> get _traps => {for (final o in _first.options) if (!o.correct) o.id};
Set<String> get _allWhy => {for (final w in _first.whyChips) w.id};

String _idOf(Finder card) => (card.evaluate().first.widget.key! as ValueKey<String>).value.split('-').skip(2).join('-');

Future<void> _pumpMs(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Opens the board at [size] (logical) and waits at the first question.
Future<void> _open(WidgetTester t, {Size size = const Size(360, 800), bool reduce = false}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2.0;
  t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  SharedPreferences.setMockInitialValues({});
  await t.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: const LearnBoardRunnerPage(rungId: '1.3/learn', lessonId: '1.3', ladderIndex: 6, pack: _pack, muted: true),
    ),
  ));
  for (var i = 0; i < 165 && _dealt('pick', _safe).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await _pumpMs(t, 1500);
}

Future<void> _close(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  t.platformDispatcher.clearAccessibilityFeaturesTestValue();
  t.view.reset();
}

/// The live ◆ in the top bar (the level score).
String _score(WidgetTester t) {
  final pill = find.ancestor(of: find.text('◆'), matching: find.byType(Row)).first;
  final texts = [for (final e in find.descendant(of: pill, matching: find.byType(Text)).evaluate()) (e.widget as Text).data];
  return texts.whereType<String>().firstWhere((s) => s != '◆');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(LearnDealer.resetMemory);

  // The app's Bangla font, so text wraps as on a phone.
  setUpAll(() async {
    final loader = FontLoader('Noto Sans Bengali');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/NotoSansBengali-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  });

  testWidgets('a tap opens the card large: nothing is judged or scored, names stay hidden', (t) async {
    await _open(t);
    // Let the guide finish asking (his lip-sync draws while he talks).
    await _pumpMs(t, 6000);
    final trap = _dealt('pick', _traps);
    await openBoardCard(t, trap);
    expect(boardPreview, findsOneWidget);
    expect(boardConfirm, findsOneWidget);
    expect(boardReject, findsOneWidget);
    expect(find.text('বেছে নিন'), findsOneWidget);
    expect(find.text('বাদ দিন'), findsOneWidget);
    expect(boardFeedback, findsNothing, reason: 'no verdict before ✓');
    expect(boardContinue, findsNothing);
    expect(_score(t), '0');
    expect(find.textContaining('নষ্ট'), findsNothing);
    for (final o in _first.options) {
      expect(find.text(o.labelBn), findsNothing, reason: 'the picture carries the cue, even when opened');
    }
    // Buttons: 48 dp or more, the same size for every card.
    expect(t.getSize(boardConfirm).height, greaterThanOrEqualTo(48));
    expect(t.getSize(boardReject).height, greaterThanOrEqualTo(48));
    expect(t.getSize(boardConfirm), t.getSize(boardReject));
    // Waiting on the open card draws nothing (the opening pop is one-shot).
    await _pumpMs(t, 1000);
    var frames = 0;
    for (var i = 0; i < 60; i++) {
      if (t.binding.hasScheduledFrame) frames++;
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(frames, lessThan(12), reason: 'the open card must not animate forever');
    expect(t.takeException(), isNull);
    await _close(t);
  });

  testWidgets('the opening pop ignores taps; ✕ sets the card aside (not wrong) and it opens again', (t) async {
    await _open(t);
    final trap = _dealt('pick', _traps);
    final id = _idOf(trap);
    await t.tap(trap.first, warnIfMissed: false);
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    // Still opening: ✓ does nothing yet.
    await t.tap(boardConfirm, warnIfMissed: false);
    await t.pump();
    expect(boardFeedback, findsNothing, reason: 'a tap during the opening animation is ignored');
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(boardReject);
    await t.pump();
    expect(boardPreview, findsNothing, reason: '✕ closes the card');
    expect(find.byKey(const ValueKey('board-card-aside')), findsOneWidget, reason: 'the card is marked set aside');
    expect(_dealt('pick', {id}), findsOneWidget, reason: 'it stays on the board (no redeal)');
    expect(find.textContaining('নষ্ট'), findsNothing);
    expect(_score(t), '0', reason: 'setting aside costs nothing');
    // Reopen it.
    await openBoardCard(t, _dealt('pick', {id}));
    expect(boardPreview, findsOneWidget, reason: 'a set-aside card can be opened again');
    expect(t.takeException(), isNull);
    await _close(t);
  });

  testWidgets('✓ on a wrong card: its reason stays under the card until Continue; then the hand is dealt again', (t) async {
    await _open(t);
    final trap = _dealt('pick', _traps);
    final id = _idOf(trap);
    final option = _first.options.firstWhere((o) => o.id == id);
    await tapBoardCard(t, trap);
    // A second ✓ (double tap) changes nothing: the buttons are gone.
    expect(boardConfirm, findsNothing);
    expect(boardFeedback, findsOneWidget);
    expect(find.descendant(of: boardFeedback, matching: find.text(option.rejectBn)), findsOneWidget);
    expect(find.descendant(of: boardFeedback, matching: find.text(option.labelBn)), findsOneWidget);
    // No timer takes it away.
    await _pumpMs(t, 30000);
    expect(boardFeedback, findsOneWidget, reason: 'the feedback waits for the player');
    expect(boardContinue, findsOneWidget);
    expect(find.text('এগিয়ে যান'), findsOneWidget);
    for (final w in _first.whyChips) {
      expect(find.text(w.textBn), findsNothing, reason: 'a wrong card never opens the reason deck');
    }
    await continueBoard(t);
    expect(boardPreview, findsNothing);
    expect(_dealt('pick', _safe), findsOneWidget, reason: 'a fresh hand with the safe card');
    expect(t.takeException(), isNull);
    await _close(t);
  });

  testWidgets('✓ on the right card scores once: pending ◆, Continue, the right reason banks it', (t) async {
    await _open(t);
    final pending = _first.pendingPoints;
    await tapBoardCard(t, _dealt('pick', _safe));
    expect(boardFeedback, findsOneWidget);
    await t.tap(boardContinue, warnIfMissed: false); // too soon after ✓: ignored
    await t.pump();
    expect(boardFeedback, findsOneWidget, reason: 'a double tap on ✓ cannot skip the feedback');
    await _pumpMs(t, 3000);
    expect(_dealt('why', _allWhy), findsNothing, reason: 'the reason deck waits for Continue');
    if (pending > 0) expect(find.text('+$pending ◆'), findsOneWidget, reason: 'the ◆ on the table');
    await continueBoard(t);
    final right = {for (final w in _first.whyChips) if (w.correct) w.id};
    for (var i = 0; i < 100 && _dealt('why', right).evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await _pumpMs(t, 1500);
    // A reason chip opens large too, with its whole text.
    final chip = _dealt('why', right);
    final text = _first.whyChips.firstWhere((w) => w.id == _idOf(chip)).textBn;
    await openBoardCard(t, chip);
    expect(find.descendant(of: boardPreview, matching: find.text(text)), findsOneWidget);
    await t.tap(boardConfirm);
    await t.pump();
    await continueBoard(t);
    await _pumpMs(t, 4000);
    expect(_score(t), '$pending', reason: 'the round paid its ◆ once');
    expect(t.takeException(), isNull);
    await _close(t);
  });

  group('top bar', () {
    for (final size in const [Size(320, 640), Size(360, 640), Size(411, 820), Size(800, 360)]) {
      testWidgets('L7, no name, no sound button, nothing overflows (${size.width.toInt()}x${size.height.toInt()})', (t) async {
        await _open(t, size: size);
        expect(t.takeException(), isNull, reason: 'no overflow');
        expect(find.text('L7'), findsOneWidget);
        expect(find.text('ধাপ 7'), findsNothing);
        expect(find.text(_pack.titleBn), findsNothing, reason: 'the level name is for screen readers only');
        expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
        expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
        expect(find.byType(ReadLessonPill), findsOneWidget);
        expect(find.text('💀'), findsOneWidget);
        // Touch targets.
        expect(t.getSize(find.byType(ReadLessonPill)).height, greaterThanOrEqualTo(40));
        final close = find.widgetWithIcon(IconButton, Icons.close_rounded).first;
        expect(t.getSize(close).width, greaterThanOrEqualTo(40));
        // Everything inside the screen.
        for (final f in [find.text('L7'), find.byType(ReadLessonPill), find.text('💀'), close]) {
          final r = t.getRect(f);
          expect(r.left >= 0 && r.right <= size.width, isTrue, reason: '$f at $r');
        }
        await _close(t);
      });
    }
  });

  group('the feedback stays on a small phone', () {
    for (final size in const [Size(320, 640), Size(360, 640), Size(800, 360)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (t) async {
        await _open(t, size: size);
        final trap = _dealt('pick', _traps);
        await tapBoardCard(t, trap);
        await _pumpMs(t, 1000);
        expect(t.takeException(), isNull, reason: 'no overflow in the open card');
        final screen = Offset.zero & size;
        final next = t.getRect(boardContinue);
        expect(screen.contains(next.topLeft) && screen.contains(next.bottomRight - const Offset(1, 1)), isTrue,
            reason: 'Continue on screen: $next');
        final fb = t.getRect(boardFeedback);
        expect(fb.top, lessThan(size.height - 60), reason: 'the feedback starts on screen: $fb');
        expect(fb.top, greaterThanOrEqualTo(0));
        await continueBoard(t);
        expect(boardPreview, findsNothing);
        await _close(t);
      });
    }
  });
}
