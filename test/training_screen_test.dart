import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';
import 'package:slm_flutter/features/training/training_screen.dart';

class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1'));
}

void main() {
  testWidgets('lesson list lays out on a small phone with long modules', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final modules = [
      for (var m = 1; m <= 4; m++)
        TrainingModuleItem(
          moduleNumber: m,
          title: 'ধাপ $m: খুঁটিতে ওঠার আগে নিরাপত্তা যাচাই ও পিপিই পরিদর্শন',
          badgeName: 'b$m',
          totalLessons: 12,
          completedLessons: m == 1 ? 5 : 0,
          status: m == 1 ? LadderStepStatus.active : LadderStepStatus.locked,
        ),
    ];
    final lessons = [
      for (var c = 1; c <= 12; c++)
        LessonCardItem(
          id: 'l$c',
          moduleNumber: 1,
          chapterNumber: c,
          title: 'পাঠ শিরোনাম অনেক লম্বা হতে পারে—সুরক্ষা কবচ ও প্রথম দিনের ইউনিফর্ম $c',
          isCompleted: c <= 5,
        ),
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authProvider.overrideWith(_TestAuth.new),
        trainingLadderProvider.overrideWith((ref) async => modules),
        moduleLessonsProvider.overrideWith((ref, module) async => module == 1 ? lessons : const []),
      ],
      child: const MaterialApp(home: TrainingScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('এখান থেকে 👉'), findsOneWidget);
    expect(find.textContaining('5/12'), findsOneWidget);
  });
}
