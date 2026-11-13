// The level top bar (owner's brief, Nov 2026): close · "L12" · ◆ · 💀 ·
// (clock / book icon). No level name drawn (screen readers still hear it), no
// speaker button, the read pill is the book icon only. One 54 dp row on a
// 320, 360 and 411 dp phone and in landscape: no overflow, no wrap, touch
// targets ≥ 40 dp (the book ≥ 44 dp), everything inside the screen.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/beat_fx.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';

const _title = 'খুঁটিতে ওঠার আগে পিপিই পরিদর্শন';

const _sizes = <Size>[Size(320, 640), Size(360, 740), Size(411, 860), Size(800, 360)];

const _ctx = LevelContext(
  rungId: '1.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.5',
  lessonTitleBn: _title,
  ladderStep: 12,
  doIndex: 1,
  doCount: 2,
);

Future<void> _pumpAt(WidgetTester t, Size size, Widget bar) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SafeArea(child: Column(children: [bar, const Expanded(child: SizedBox())])),
      ),
    ),
  ));
  await t.pump(); // the save hydrates (a big total and a 💀 count)
  await t.pump(const Duration(milliseconds: 600)); // the bump settles
}

void _expectCleanBar(WidgetTester t, Size size) {
  expect(t.takeException(), isNull, reason: 'no overflow at ${size.width}×${size.height}');
  expect(t.getSize(find.byType(UnifiedGameTopHud)).height, UnifiedGameTopHud.height, reason: 'no extra height');
  expect(find.text('L12'), findsOneWidget);
  final badge = t.renderObject<RenderParagraph>(find.text('L12'));
  expect(badge.didExceedMaxLines, isFalse, reason: 'the level number is never cut');
  expect(find.textContaining('ধাপ'), findsNothing);
  expect(find.text(_title), findsNothing, reason: 'the level name is not drawn');
  expect(find.textContaining('পাঠ'), findsNothing);
  expect(find.byIcon(Icons.volume_up_rounded), findsNothing, reason: 'no speaker button');
  expect(find.byIcon(Icons.volume_off_rounded), findsNothing, reason: 'no speaker button');
  expect(find.text('💀'), findsOneWidget);
  expect(find.text('◆'), findsOneWidget);
  for (final e in find.byType(IconButton).evaluate()) {
    final box = e.renderObject! as RenderBox;
    expect(box.size.width, greaterThanOrEqualTo(40));
    expect(box.size.height, greaterThanOrEqualTo(40));
  }
  for (final e in find.descendant(of: find.byType(UnifiedGameTopHud), matching: find.byType(Text)).evaluate()) {
    final box = e.renderObject! as RenderBox;
    final r = box.localToGlobal(Offset.zero) & box.size;
    expect(r.right, lessThanOrEqualTo(size.width + 0.01), reason: 'text inside the screen');
    expect(box.size.height, lessThan(30), reason: 'one line, no wrap');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'game_save_v1': '{"points": 98765, "deaths": 7}',
    });
  });

  for (final size in _sizes) {
    final tag = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('LevelShellBar $tag: L12, ◆, 💀, a clock — no title, no speaker', (t) async {
      final scoreKey = GlobalKey();
      final handle = t.ensureSemantics();
      var closes = 0;
      await _pumpAt(
        t,
        size,
        LevelShellBar(
          context_: _ctx,
          titleBn: _title,
          scoreKey: scoreKey,
          levelScore: 240,
          muted: false,
          onClose: () => closes++,
          onToggleMute: () {},
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const Text('0:42'),
          ),
        ),
      );
      _expectCleanBar(t, size);
      expect(find.text('240'), findsOneWidget);
      expect(scoreKey.currentContext, isNotNull, reason: 'score fly-in target');
      expect(find.bySemanticsLabel(RegExp(RegExp.escape(_title))), findsOneWidget, reason: 'title for screen readers');
      await t.tap(find.byIcon(Icons.close_rounded));
      expect(closes, 1);
      handle.dispose();
    });

    testWidgets('LevelShellBar bare $tag fits', (t) async {
      await _pumpAt(
        t,
        size,
        LevelShellBar(
          bare: true,
          context_: _ctx,
          titleBn: _title,
          scoreKey: GlobalKey(),
          levelScore: 120,
          muted: true,
          onClose: () {},
          onToggleMute: () {},
        ),
      );
      _expectCleanBar(t, size);
    });

    testWidgets('Learn bar $tag: listen + book icon only, total ticker', (t) async {
      var reads = 0;
      await _pumpAt(
        t,
        size,
        UnifiedGameTopHud(
          scoreKey: GlobalKey(),
          deathKey: GlobalKey(),
          levelScore: 240,
          badgeText: 'L12',
          titleText: _title,
          stepOnly: true,
          closeIcon: Icons.close_rounded,
          onClose: () {},
          onToggleMute: () {},
          trailingExtra: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                icon: const Icon(Icons.headphones_rounded, size: 20),
              ),
              ReadLessonPill(hot: true, onTap: () => reads++),
            ],
          ),
        ),
      );
      _expectCleanBar(t, size);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      final pill = t.getRect(find.byType(ReadLessonPill));
      expect(pill.width, greaterThanOrEqualTo(44));
      expect(pill.height, greaterThanOrEqualTo(44));
      expect(pill.right, lessThanOrEqualTo(size.width + 0.01));
      await t.tap(find.byType(ReadLessonPill));
      expect(reads, 1);
    });

    testWidgets('bar with the running total $tag fits', (t) async {
      await _pumpAt(
        t,
        size,
        UnifiedGameTopHud(
          scoreKey: GlobalKey(),
          levelScore: 999,
          badgeText: 'L12',
          titleText: _title,
          onClose: () {},
          trailingExtra: ReadLessonPill(hot: false, onTap: () {}),
        ),
      );
      expect(find.byType(ScoreTotalTicker), findsOneWidget);
      _expectCleanBar(t, size);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      expect(t.getRect(find.byType(ReadLessonPill)).right, lessThanOrEqualTo(size.width + 0.01));
    });
  }

  testWidgets('a huge score and 💀 count on a 320 dp phone: the badge gives way, nothing overflows', (t) async {
    SharedPreferences.setMockInitialValues({'game_save_v1': '{"points": 98765, "deaths": 999}'});
    await _pumpAt(
      t,
      const Size(320, 640),
      UnifiedGameTopHud(
        scoreKey: GlobalKey(),
        levelScore: 99999,
        badgeText: 'L120',
        titleText: _title,
        stepOnly: true,
        onClose: () {},
        trailingExtra: ReadLessonPill(hot: false, onTap: () {}),
      ),
    );
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byType(UnifiedGameTopHud)).height, UnifiedGameTopHud.height);
    expect(t.getRect(find.byType(ReadLessonPill)).right, lessThanOrEqualTo(320.01));
  });

  testWidgets('ReadLessonPill is the book icon only, read as "পাঠ পড়ুন"', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: ReadLessonPill(hot: false, onTap: () {})))));
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.bySemanticsLabel('পাঠ পড়ুন'), findsOneWidget);
    expect(t.getSize(find.byType(ReadLessonPill)), const Size(44, 44));
    handle.dispose();
  });
}
