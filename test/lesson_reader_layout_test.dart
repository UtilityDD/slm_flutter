// Lesson reader redesign (owner-approved, 2026-11-14): the whole screen is
// the page, a slim header ('পাঠ n', text size, page colour, listen), one
// section at a time with swipe, the big quiz button only on the last page,
// in-text read-aloud highlight, and the saved reading place.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/home/lesson_quiz_store.dart';
import 'package:slm_flutter/features/home/lesson_reader_page.dart';
import 'package:slm_flutter/features/home/lesson_seal_page.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';

class _GuestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

/// The server has no quiz for this lesson: the claim goes straight to the seal.
class _NoQuizStore extends LessonQuizStore {
  @override
  Future<LessonQuizLoad> load(int module, int chapter) async => LessonQuizLoad.noQuiz;
}

const _title = 'সুরক্ষা কবচ ও প্রথম দিনের ইউনিফর্ম';
const _brief = 'লাইনে ওঠার আগে সব সরঞ্জাম চেক করুন। একটি ভুলই জীবনের শেষ হতে পারে।';
const _tip = 'কাজের আগে সব সরঞ্জাম একবার মিলিয়ে নিন।';
const _myth = 'শুকনো কাঠ দিয়ে লাইন ছোঁয়া নিরাপদ।';
const _truth = 'শুকনো কাঠও বিদ্যুৎ বহন করতে পারে।';

const _lesson = LessonCardItem(
  id: 'l1',
  moduleNumber: 1,
  chapterNumber: 2,
  title: _title,
  missionBriefing: '$_brief\nদ্বিতীয় অনুচ্ছেদ: ডকেট ছাড়া কাজ নয়।',
  points: [
    LessonSectionPoint(
      itemName: 'হেলমেট',
      specifications: 'হেলমেট মাথায় ঠিকমতো বসাতে হবে। চিবুকের ফিতে আটকান।',
      importance: 'মাথার আঘাত থেকে বাঁচায়।',
      dailyCheck: 'ফাটল আছে কিনা দেখুন।',
    ),
    LessonSectionPoint(itemName: 'গ্লাভস', specifications: 'গ্লাভস ফুলিয়ে ছিদ্র দেখুন।'),
    LessonSectionPoint(itemName: 'জুতো', specifications: 'রাবার সোলের জুতো পরুন।'),
  ],
  proTips: [_tip],
  myths: [LessonMythItem(myth: _myth, reality: _truth)],
);

// hero, 3 points, tip, myth, done
const _sections = 7;

/// Long text everywhere, for the overflow checks.
final _long = LessonCardItem(
  id: 'l9',
  moduleNumber: 1,
  chapterNumber: 10,
  title: '$_title — অনেক লম্বা শিরোনাম, যাতে দুই তিন লাইনে ভেঙে যায়',
  missionBriefing: List.filled(8, _brief).join('\n'),
  points: [
    for (var i = 0; i < 2; i++)
      LessonSectionPoint(
        itemName: 'অনেক লম্বা বিষয়ের নাম যা ছোট ফোনে দুই লাইনে যাবে $i',
        specifications: List.filled(6, _brief).join(' '),
        importance: List.filled(3, _brief).join(' '),
        dailyCheck: '• ফাটল আছে কিনা দেখুন।\n• ফিতে আটকান।',
      ),
  ],
  proTips: [List.filled(4, _tip).join(' '), _tip],
  myths: const [LessonMythItem(myth: _myth, reality: _truth), LessonMythItem(myth: _myth, reality: _truth)],
);

Future<void> _pump(
  WidgetTester tester, {
  LessonCardItem lesson = _lesson,
  Size size = const Size(360, 740),
  Map<String, Object> prefs = const {},
  Brightness platform = Brightness.light,
  double textScale = 1.0,
  int? startPoint,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  LessonQuizStore.instance = _NoQuizStore();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = platform;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(_GuestAuth.new),
      moduleLessonsProvider.overrideWith((ref, m) async => [
            lesson,
            const LessonCardItem(id: 'l-next', moduleNumber: 1, chapterNumber: 11, title: 'পরের পাঠ'),
          ]),
    ],
    child: MaterialApp(home: LessonReaderPage(lesson: lesson, bn: true, startPoint: startPoint)),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('reader-next')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _toLast(WidgetTester tester) async {
  while (find.byKey(const ValueKey('reader-next')).evaluate().isNotEmpty) {
    await _next(tester);
  }
}

TextStyle _styleOf(WidgetTester tester, String text) {
  final w = tester.widget<Text>(find.text(text));
  return (w.textSpan! as TextSpan).style!;
}

Color _pageColor(WidgetTester tester) =>
    tester.widget<Scaffold>(find.descendant(of: find.byType(LessonReaderPage), matching: find.byType(Scaffold))).backgroundColor!;

String _position(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('reader-position'))).data!;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  tearDown(() => LessonReaderPage.debugSpeak = null);

  testWidgets('edge to edge: no paper card, border or shadow inside the page', (tester) async {
    await _pump(tester);
    expect(_pageColor(tester), const Color(0xFFFBF7EF));
    final reader = find.byType(LessonReaderPage);
    for (final box in tester.widgetList<DecoratedBox>(find.descendant(of: reader, matching: find.byType(DecoratedBox)))) {
      final d = box.decoration;
      if (d is! BoxDecoration) continue;
      expect(d.boxShadow ?? const [], isEmpty, reason: 'no card shadow');
      expect(d.gradient, isNull, reason: 'no paper gradient card');
    }
    for (final c in tester.widgetList<Container>(find.descendant(of: reader, matching: find.byType(Container)))) {
      final d = c.decoration;
      if (d is BoxDecoration) expect(d.boxShadow ?? const [], isEmpty);
    }
    // The text runs to the screen edge minus the 20 dp gutter.
    final left = tester.getTopLeft(find.text(_title)).dx;
    expect(left, 20);
  });

  testWidgets('slim header: "পাঠ n", no title; the title sits once at the top of the first page', (tester) async {
    await _pump(tester);
    expect(find.text('পাঠ 2'), findsOneWidget);
    expect(find.text(_title), findsOneWidget);
    expect(find.descendant(of: find.byType(SingleChildScrollView), matching: find.text(_title)), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-listen')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-bigger')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-smaller')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-theme')), findsOneWidget);
    // Progress is a thin line at the top edge.
    expect(tester.getSize(find.byKey(const ValueKey('reader-progress'))).height, 3);
    expect(tester.getTopLeft(find.byKey(const ValueKey('reader-progress'))).dy, 0);
    // Title is shown large; after the first page it is gone.
    expect(_styleOf(tester, _title).fontSize, greaterThanOrEqualTo(24));
    await _next(tester);
    expect(find.text(_title), findsNothing);
    expect(find.text('পাঠ 2'), findsOneWidget);
  });

  testWidgets('body type: 18 sp, w400, 1.7 line height; A+ and A− change it', (tester) async {
    await _pump(tester);
    var body = _styleOf(tester, _brief);
    expect(body.fontSize, 18);
    expect(body.fontWeight, FontWeight.w400);
    expect(body.height, 1.7);

    await tester.tap(find.byKey(const ValueKey('reader-bigger')));
    await tester.pump();
    expect(_styleOf(tester, _brief).fontSize, closeTo(20.7, 0.01));

    await tester.tap(find.byKey(const ValueKey('reader-smaller')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reader-smaller')));
    await tester.pump();
    body = _styleOf(tester, _brief);
    expect(body.fontSize, closeTo(16.2, 0.01));
    // Smallest step reached: A− is disabled, A+ still works.
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('reader-smaller'))).onPressed, isNull);
  });

  testWidgets('system text scale counts too, clamped at 1.3', (tester) async {
    await _pump(tester, textScale: 2.0);
    expect(_styleOf(tester, _brief).fontSize, closeTo(18 * 1.3, 0.01));
    await tester.tap(find.byKey(const ValueKey('reader-bigger')));
    await tester.pump();
    expect(_styleOf(tester, _brief).fontSize, closeTo(18 * 1.3, 0.01));
  });

  testWidgets('day paper vs night charcoal, following the phone and the toggle', (tester) async {
    await _pump(tester, platform: Brightness.dark);
    expect(_pageColor(tester), const Color(0xFF121417));
    expect(_styleOf(tester, _brief).color, const Color(0xFFE8E2D6));

    // system → day
    await tester.tap(find.byKey(const ValueKey('reader-theme')));
    await tester.pump();
    expect(_pageColor(tester), const Color(0xFFFBF7EF));
    expect(_styleOf(tester, _brief).color, const Color(0xFF2B2118));

    // day → night
    await tester.tap(find.byKey(const ValueKey('reader-theme')));
    await tester.pump();
    expect(_pageColor(tester), const Color(0xFF121417));

    expect(_contrast(const Color(0xFF2B2118), const Color(0xFFFBF7EF)), greaterThanOrEqualTo(7));
    expect(_contrast(const Color(0xFFE8E2D6), const Color(0xFF121417)), greaterThanOrEqualTo(7));
  });

  testWidgets('swipe left moves on, swipe right goes back; double tap moves once', (tester) async {
    await _pump(tester);
    expect(_position(tester), 'ধাপ 1/$_sections');

    await tester.fling(find.text(_brief), const Offset(-300, 0), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_position(tester), 'ধাপ 2/$_sections');
    expect(find.text('হেলমেট'), findsOneWidget);

    await tester.fling(find.text('হেলমেট'), const Offset(300, 0), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_position(tester), 'ধাপ 1/$_sections');

    // Two quick taps on "পরের ধাপ" move one step.
    await tester.tap(find.byKey(const ValueKey('reader-next')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byKey(const ValueKey('reader-next')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_position(tester), 'ধাপ 2/$_sections');
  });

  testWidgets('the big quiz button shows only on the last page', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('reader-cta')), findsNothing);
    expect(find.text('পরের ধাপ'), findsOneWidget);
    final bar = tester.getRect(find.byKey(const ValueKey('reader-next')));
    expect(bar.height, greaterThanOrEqualTo(48));

    for (var i = 1; i < _sections - 1; i++) {
      await _next(tester);
      expect(find.byKey(const ValueKey('reader-cta')), findsNothing, reason: 'page ${i + 1}');
    }
    await _next(tester);
    expect(find.byKey(const ValueKey('reader-cta')), findsOneWidget);
    expect(find.text('পুরোটা পড়েছি · কুইজ দিন'), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-next')), findsNothing);
    expect(find.text('পাঠ শেষ'), findsOneWidget);
    // No swipe past the end.
    await tester.fling(find.text('পাঠ শেষ'), const Offset(-300, 0), 1200);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('reader-cta')), findsOneWidget);
  });

  testWidgets('pro tip and myth are light blocks with a 3 dp coloured edge', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 4; i++) {
      await _next(tester);
    }
    expect(find.text('কাজের সহজ টিপ'), findsOneWidget);
    BoxDecoration blockOf(String text) => tester
        .widgetList<DecoratedBox>(find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)))
        .map((b) => b.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border is Border && (d.border! as Border).left.width == 3);
    final tip = blockOf(_tip);
    expect((tip.border! as Border).left.color, const Color(0xFFD19A2A));

    await _next(tester);
    expect(find.text('ভুল'), findsOneWidget);
    expect(find.text('সত্য'), findsOneWidget);
    expect((blockOf(_myth).border! as Border).left.color, const Color(0xFFC8443A));
    expect((blockOf(_truth).border! as Border).left.color, const Color(0xFF3F9A5C));
    // "ভুল" comes before "সত্য".
    expect(tester.getTopLeft(find.text('ভুল')).dy, lessThan(tester.getTopLeft(find.text('সত্য')).dy));
  });

  testWidgets('read-aloud highlights the sentence in the text and stops on page change', (tester) async {
    final said = <String>[];
    LessonReaderPage.debugSpeak = (s) async {
      said.add(s);
      await Future<void>.delayed(const Duration(seconds: 1));
      return true;
    };
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('reader-listen')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(said, [_title]);
    // Title is sentence 0: it gets the soft background.
    final spans = (tester.widget<Text>(find.text(_title)).textSpan! as TextSpan).children!;
    expect(spans.whereType<TextSpan>().any((s) => s.style?.backgroundColor != null), isTrue);

    await _next(tester);
    final count = said.length;
    await tester.pump(const Duration(seconds: 3));
    expect(said.length, count, reason: 'leaving the page stops the voice');
    expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
  });

  testWidgets('resume: opens at the saved place with a toast, saves on page turn, clears on finish', (tester) async {
    // Wide view: the seal page that follows lays out Bangla labels in the
    // wide test font, which does not fit its 360 dp buttons.
    await _pump(tester, size: const Size(600, 900), prefs: {
      'reader.resume.l1': jsonEncode({'phase': 1, 'point': 1, 'scroll': 0.0}),
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(_position(tester), 'ধাপ 3/$_sections');
    expect(find.text('গ্লাভস'), findsOneWidget);
    expect(find.text('আগের জায়গা থেকে'), findsOneWidget);

    await _next(tester);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('reader.resume.l1')!), {'phase': 1, 'point': 2, 'scroll': 0.0});

    await _toLast(tester);
    await tester.tap(find.byKey(const ValueKey('reader-cta')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(LessonSealPage), findsOneWidget);
    expect(prefs.getString('reader.resume.l1'), isNull);
    expect(prefs.getStringList('local_completed_lessons'), contains('l1'));
  });

  testWidgets('resume keeps how far down the page was read; leaving saves it', (tester) async {
    await _pump(tester, lesson: _long, prefs: {
      'reader.resume.l9': jsonEncode({'phase': 0, 'point': 0, 'scroll': 0.5}),
    });
    await tester.pump(const Duration(milliseconds: 300));
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!;
    final half = scroll.position.maxScrollExtent * 0.5;
    expect(scroll.offset, closeTo(half, 1));
    expect(find.text('আগের জায়গা থেকে'), findsOneWidget);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('reader.resume.l9')!), {'phase': 0, 'point': 0, 'scroll': 1.0});
  });

  testWidgets('a finished lesson opens at the start, not the saved place', (tester) async {
    const done = LessonCardItem(id: 'l1', moduleNumber: 1, chapterNumber: 2, title: _title, isCompleted: true, points: [
      LessonSectionPoint(itemName: 'হেলমেট'),
      LessonSectionPoint(itemName: 'গ্লাভস'),
    ]);
    await _pump(tester, lesson: done, prefs: {
      'reader.resume.l1': jsonEncode({'phase': 1, 'point': 1, 'scroll': 0.0}),
    });
    expect(_position(tester), 'ধাপ 1/4');
    expect(find.text('আগের জায়গা থেকে'), findsNothing);
  });

  for (final size in const [Size(320, 640), Size(360, 740), Size(411, 860), Size(800, 360)]) {
    testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}, every page, large text', (tester) async {
      await _pump(tester, lesson: _long, size: size, textScale: 1.3);
      await tester.tap(find.byKey(const ValueKey('reader-bigger')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      var pages = 1;
      while (find.byKey(const ValueKey('reader-next')).evaluate().isNotEmpty) {
        await _next(tester);
        expect(tester.takeException(), isNull, reason: 'page ${++pages}');
      }
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('reader-cta')), findsOneWidget);
      // Header and bar buttons stay at least 48 dp.
      for (final key in ['reader-close', 'reader-smaller', 'reader-bigger', 'reader-theme', 'reader-listen', 'reader-back']) {
        final s = tester.getSize(find.byKey(ValueKey(key)));
        expect(s.width, greaterThanOrEqualTo(48), reason: key);
        expect(s.height, greaterThanOrEqualTo(48), reason: key);
      }
      // Text column never wider than ~640 dp.
      if (size.width > 700) {
        expect(tester.getSize(find.text('পাঠ শেষ')).width, lessThanOrEqualTo(640));
      }
    });
  }

  testWidgets('idle reader draws zero frames (first page and last page)', (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'idle first page');

    await _toLast(tester);
    var frames = 0;
    while (tester.binding.hasScheduledFrame && frames < 400) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    await tester.pump(const Duration(seconds: 2));
    expect(frames, lessThan(240), reason: 'the end-page burst must stop');
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'idle last page');
  });

  testWidgets('reduce motion: page turns are instant', (tester) async {
    await _pump(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reader-next')));
    await tester.pump();
    await tester.pump();
    expect(find.text(_title), findsNothing, reason: 'no crossfade under reduce motion');
    expect(find.text('হেলমেট'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('startPoint opens straight at that point', (tester) async {
    await _pump(tester, startPoint: 2);
    expect(_position(tester), 'ধাপ 4/$_sections');
    expect(find.text('জুতো'), findsOneWidget);
  });
}
