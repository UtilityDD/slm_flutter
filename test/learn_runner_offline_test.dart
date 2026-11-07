// AGENTS §4: a Learn rung must never play or pass on made-up content. With no
// lesson on the phone and no network, the text deck shows the Bangla offline
// dialog; "পরে" leaves without a clear and without ◆.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_runner.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

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
}
