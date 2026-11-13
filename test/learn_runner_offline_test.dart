// AGENTS §4: a Learn rung must never play or pass on made-up content. With no
// lesson on the phone and no network, the text deck shows the Bangla offline
// dialog; "পরে" leaves without a clear and without ◆. A quiz option is
// answered in two steps: its tap opens it big, only ✓ answers.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/choice_deck.dart' show CardAside;
import 'package:slm_flutter/features/game/learn_runner.dart';
import 'package:slm_flutter/features/home/lesson_quiz_store.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/reason_proceed.dart';

class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), ok);
  }
  ZlFx.setMuted(true);

  testWidgets('offline with nothing saved: dialog, no lesson, no pass, no ◆', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bool? result;
    late ProviderContainer container;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(_TestAuth.new),
        // Offline: the lesson list cannot be fetched and nothing is cached.
        moduleLessonsProvider.overrideWith((ref, module) async => throw Exception('offline')),
      ],
      child: Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return MaterialApp(
          theme: SlmTheme.night(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<bool>(MaterialPageRoute(
                      builder: (_) => const LearnRunnerPage(
                        rungId: '1.2/learn',
                        lessonId: '1.2',
                        ladderIndex: 3,
                        muted: true,
                      ),
                    ));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    // The lesson read never answers (a failed provider is retried): after the
    // 12 s timeout the deck must give up honestly.
    for (var i = 0; i < 140 && find.text('কুইজ আনা যায়নি').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('কুইজ আনা যায়নি'), findsOneWidget, reason: 'honest offline dialog');
    // No made-up deck behind it.
    expect(find.textContaining('Class-E Electrical Helmet'), findsNothing);

    await tester.tap(find.text('পরে'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(result, isFalse, reason: 'leaving offline is never a clear');
    final save = container.read(gameSaveProvider);
    expect(save.rungProgress['1.2/learn'], isNull);
    expect(save.points, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
    MascotTalk.reset();
  });

  test('no quiz file on the server: questions come from the lesson itself', () {
    const points = [
      LessonSectionPoint(itemName: 'রড', dailyCheck: 'রডের লেবেল মিলিয়ে নিন।'),
      LessonSectionPoint(itemName: 'চেইন', dailyCheck: 'চেইনের লিঙ্ক অক্ষত কিনা দেখুন।'),
      LessonSectionPoint(itemName: 'আর্থ পয়েন্ট', dailyCheck: 'আর্থিং পয়েন্টে মরিচা আছে কিনা দেখুন।'),
    ];
    final quiz = learnQuizFromPoints(points);
    expect(quiz, hasLength(2));
  });

  testWidgets('quiz option: a tap opens it big (no answer); ✕ sets it aside; ✓ answers and the result waits for পরের প্রশ্ন', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final old = LessonQuizStore.instance;
    // No quiz file for this lesson (404): the questions come from its points.
    LessonQuizStore.instance = LessonQuizStore(
      httpGet: (_) async => const LessonQuizHttpResponse(404, ''),
      cacheRoot: () async => throw const FileSystemException('none'),
    );
    addTearDown(() => LessonQuizStore.instance = old);
    // Wide: the test font draws every Bangla glyph a full em wide.
    tester.view.physicalSize = const Size(1400, 1700);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    const points = [
      LessonSectionPoint(itemName: 'গ্লাভস', dailyCheck: 'হাওয়া ভরে লিক চেক করুন।'),
      LessonSectionPoint(itemName: 'হেলমেট', dailyCheck: 'খোলসে ফাটল আছে কিনা দেখুন।'),
      LessonSectionPoint(itemName: 'বুট', dailyCheck: 'সোলে পেরেক গেঁথে আছে কিনা দেখুন।'),
    ];
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(_TestAuth.new),
        moduleLessonsProvider.overrideWith((ref, module) async => [
              const LessonCardItem(id: 'l9', moduleNumber: 9, chapterNumber: 9, title: 'পাঠ', points: points),
            ]),
      ],
      child: Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return MaterialApp(
          theme: SlmTheme.night(),
          home: const LearnRunnerPage(rungId: '9.9/learn', lessonId: '9.9', ladderIndex: 3, muted: true),
        );
      }),
    ));
    final quizHead = find.textContaining('কুইক ফিল্ড ডিসিশন');
    final next = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('চেক করে'));
    for (var i = 0; i < 200 && quizHead.evaluate().isEmpty; i++) {
      if (next.evaluate().isNotEmpty) await tester.tap(next.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(quizHead, findsOneWidget, reason: 'the quiz is up');
    await tester.pump(const Duration(milliseconds: 600));
    final before = container.read(gameSaveProvider).points;
    const right = 'একদম সঠিক সিদ্ধান্ত! +10 ◆ পয়েন্ট যোগ হয়েছে।';
    const wrong = 'সঠিক উত্তরটি সবুজ রঙে দেখানো হয়েছে — মনে গেঁথে নিন, মই থেকে পড়েননি।';
    final confirm = find.byKey(const ValueKey('choice-confirm'));
    final reject = find.byKey(const ValueKey('choice-reject'));

    await tester.tap(find.byKey(const ValueKey('quiz-option-0')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(confirm, findsOneWidget, reason: 'the option opens big');
    expect(find.text(right), findsNothing, reason: 'a touch is not an answer');
    expect(find.text(wrong), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(reject);
    await tester.pump(const Duration(milliseconds: 300));
    expect(confirm, findsNothing);
    expect(find.byWidgetPredicate((w) => w is CardAside && w.aside), findsOneWidget);
    expect(find.text(right), findsNothing);
    expect(find.text(wrong), findsNothing);

    // Set aside, it still opens; ✓ answers.
    await tester.tap(find.byKey(const ValueKey('quiz-option-0')), warnIfMissed: false);
    expect(await confirmChoice(tester), isTrue);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(right).evaluate().length + find.text(wrong).evaluate().length, 1, reason: 'the result shows');
    // Nothing is saved mid-quiz (the level score commits at the end), as before.
    expect(container.read(gameSaveProvider).points, before);
    // The result stays until the player moves on.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(right).evaluate().length + find.text(wrong).evaluate().length, 1, reason: 'still there');
    expect(find.text('পরের প্রশ্ন'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
    MascotTalk.reset();
  });
}
