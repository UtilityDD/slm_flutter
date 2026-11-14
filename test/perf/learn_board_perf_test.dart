// Learn picture boards (LearnBoardRunnerPage — 1.1, and 1.2 from ladder step 4): once the cards are dealt and
// the coach has asked, the board waits for the player. Only the decision clock
// may change (once a second) — nothing loops at 60 fps on a 3–4 GB phone — and
// with "remove animations" the board deals instantly and waits just as quietly.
// Also guards the teaching rule that a picture's name stays hidden until tapped.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_board_runner.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

/// Has read lessons 1.1 and 1.2 already, so a board opens straight on the cards.
class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1', completedLessons: ['1_1', '1.1', '1_2', '1.2']));
}

/// The boards under test: pack, ladder index, the first play's day card.
final _boards = [
  (pack: learnBoardPack11, index: 0, day: 'দিন 1'),
  (pack: learnBoardPack12, index: 3, day: 'দিন 2'),
];

var _rebuilds = 0;

/// Rebuilds outside the coach (AiLinemanGuide): the board's own, which the
/// guide's blinks cannot move.
var _boardRebuilds = 0;

void _countRebuild(Element e, bool _) {
  _rebuilds++;
  var coach = e.widget is AiLinemanGuide;
  if (!coach) {
    e.visitAncestorElements((a) {
      coach = a.widget is AiLinemanGuide;
      return !coach;
    });
  }
  if (!coach) _boardRebuilds++;
}

void _muteAudio() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), ok);
  }
}

Finder get _cards => find.byWidgetPredicate((w) => w.runtimeType.toString() == '_AnimatedChoiceCard');

Future<({double rebuildsPerSec, double boardPerSec, int framesInIdleSecond, bool dayCardFirst})> _waitAtFirstQuestion(
  WidgetTester tester, {
  required bool reduce,
  required LearnBoardPack pack,
  required int index,
  required String day,
}) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(ProviderScope(
    overrides: [authProvider.overrideWith(_TestAuth.new)],
    child: MaterialApp(
      theme: SlmTheme.night(),
      home: LearnBoardRunnerPage(
        rungId: '${pack.lessonId}/learn',
        lessonId: pack.lessonId,
        ladderIndex: index,
        pack: pack,
        muted: true,
      ),
    ),
  ));
  // First play: the day card comes before the board.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final dayCardFirst = find.text(day).evaluate().isNotEmpty;
  // Day card, intro line, deal, first ask (muted lines still hold for their reading time).
  for (var i = 0; i < 160; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  _rebuilds = 0;
  _boardRebuilds = 0;
  for (var i = 0; i < 125; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  final perSec = _rebuilds / 2.0;
  final boardPerSec = _boardRebuilds / 2.0;

  // Frames in one idle second, pumped frame by frame: a 60 fps loop shows ~60.
  var frames = 0;
  for (var i = 0; i < 60; i++) {
    if (tester.binding.hasScheduledFrame) frames++;
    await tester.pump(const Duration(milliseconds: 16));
  }
  return (rebuildsPerSec: perSec, boardPerSec: boardPerSec, framesInIdleSecond: frames, dayCardFirst: dayCardFirst);
}

Future<void> _tearDownBoard(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  // Let line timers and the lip-sync safety timer run out.
  await tester.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  tester.view.reset();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  ZlFx.setMuted(true);
  setUp(() => debugOnRebuildDirtyWidget = _countRebuild);
  tearDown(() => debugOnRebuildDirtyWidget = null);

  for (final b in _boards) {
  for (final reduce in [false, true]) {
    final tag = '${b.pack.lessonId} ${reduce ? 'reduce' : 'anim'}';
    testWidgets('board waits quietly at the first question ($tag)', (tester) async {
      final s = await _waitAtFirstQuestion(tester, reduce: reduce, pack: b.pack, index: b.index, day: b.day);
      debugPrint('PERF learn board $tag: ${s.rebuildsPerSec.toStringAsFixed(1)} rebuilds/s '
          '(${s.boardPerSec.toStringAsFixed(1)} outside the coach), ${s.framesInIdleSecond} frames in an idle second');

      expect(tester.takeException(), isNull);
      expect(s.dayCardFirst, isTrue, reason: 'a first play opens on the day card');
      expect(find.text(b.day), findsNothing, reason: 'the day card leaves on its own');
      expect(_cards, findsNWidgets(b.pack.slots.first.cards), reason: 'the first hand is dealt');
      // Only the clock (once a second, one element) and the coach's blink may draw
      // while waiting. The clock runs on fake time (package:clock), so these
      // counts no longer depend on how busy the machine is. Measured: 1/s outside
      // the coach; 5-10/s in all, 19/s when a window catches the guide's double-
      // blink burst (a setState on the whole guide per beat). Drop the total to 10
      // once the blink rebuilds only the face.
      expect(s.rebuildsPerSec, lessThan(20), reason: 'nothing may rebuild every frame while the player thinks');
      expect(s.boardPerSec, lessThan(5), reason: 'the board itself: only the clock digits, once a second');
      expect(s.framesInIdleSecond, lessThan(12), reason: 'no 60 fps loop while waiting for an answer');

      // The picture must carry the cue: no item names until a card is tapped.
      for (final o in b.pack.slots.first.options) {
        expect(find.text(o.labelBn), findsNothing, reason: '"${o.labelBn}" shown before any tap');
      }
      await _tearDownBoard(tester);
    });
  }
  }
}
