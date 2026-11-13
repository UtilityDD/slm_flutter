// The toolbox sheet (Home, intro and fear pages): exactly four rows, in order
// র‍্যাঙ্ক, আমার পাঠ, জরুরি নম্বর, সেটিংস. No language toggle, no পরিচিতি.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/home/home_toolbox.dart';
import 'package:slm_flutter/features/training/training_screen.dart';

class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(profile: LinemanProfile.guest());
}

Future<void> _openSheet(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(_TestAuth.new),
      passedLessonKeysProvider.overrideWithValue(const <String>{}),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(builder: (c) => HomeToolboxButton(onTap: () => openHomeToolbox(c))),
        ),
      ),
    ),
  ));
  await tester.tap(find.byType(HomeToolboxButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('sheet shows exactly the four rows, in order', (tester) async {
    await _openSheet(tester);

    final rows = find.descendant(of: find.byType(BottomSheet), matching: find.byType(SlmPressable));
    expect(rows, findsNWidgets(4));

    const labels = ['র‍্যাঙ্ক', 'আমার পাঠ', 'জরুরি নম্বর', 'সেটিংস'];
    final ys = [for (final l in labels) tester.getTopLeft(find.text(l)).dy];
    for (var i = 1; i < ys.length; i++) {
      expect(ys[i], greaterThan(ys[i - 1]), reason: '${labels[i]} comes after ${labels[i - 1]}');
    }

    for (final gone in ['পরিচিতি', 'প্রশিক্ষণ জোন · পাঠ', 'বাংলা', 'English', 'কুইজ']) {
      expect(find.text(gone), findsNothing, reason: '$gone left the sheet');
    }
  });

  testWidgets('আমার পাঠ opens the lessons screen (empty state with no passes)', (tester) async {
    await _openSheet(tester);

    await tester.tap(find.text('আমার পাঠ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(TrainingScreen), findsOneWidget);
    expect(find.text('এখনও কোনো পাঠ খোলেনি'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
