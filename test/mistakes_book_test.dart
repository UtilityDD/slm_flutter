// "আমার ভুলের খাতা": empty note, newest first, counts and day labels, the
// deadly filter, and a picture for every known mistake.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/discharge_order.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/mistakes_book.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(720, 1600);
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: MistakesBookPage(now: DateTime.now())),
    ));
    await t.pump();
    return c;
  }

  Future<void> book(ProviderContainer c, DoMistake m) => c.read(gameSaveProvider.notifier).addMistake(
        key: m.key,
        lessonId: '1.5',
        rungId: '1.5/do/1',
        textBn: m.textBn,
        deadly: m.deadly,
        lessonPoint: m.lessonPoint,
      );

  testWidgets('empty book says so', (t) async {
    await pump(t);
    expect(find.text(MistakesBookLines.empty), findsOneWidget);
  });

  testWidgets('entries show newest first with count; the deadly filter hides slips', (t) async {
    final c = await pump(t);
    await book(c, DischargeMistakes.rustyEarth);
    await book(c, DischargeMistakes.rustyEarth);
    await book(c, DischargeMistakes.lineBeforeEarth);
    await t.pump();

    final slip = find.text(DischargeMistakes.rustyEarth.textBn);
    final deadly = find.text(DischargeMistakes.lineBeforeEarth.textBn);
    expect(slip, findsOneWidget);
    expect(deadly, findsOneWidget);
    expect(t.getTopLeft(deadly).dy, lessThan(t.getTopLeft(slip).dy), reason: 'newest first');
    expect(find.text('${MistakesBookLines.today} · ${MistakesBookLines.times(2)}'), findsOneWidget);
    expect(find.text(MistakesBookLines.lesson('1.5')), findsNWidgets(2));
    expect(find.text(MistakeLines.readLesson), findsNWidgets(2));

    await t.tap(find.text(MistakesBookLines.deadly));
    await t.pump();
    expect(find.text(DischargeMistakes.rustyEarth.textBn), findsNothing);
    expect(find.text(DischargeMistakes.lineBeforeEarth.textBn), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('the 💀 page: deadly mistakes only, most repeated first, plain header, no filters', (t) async {
    t.view.physicalSize = const Size(720, 1600);
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: MistakesBookPage(now: DateTime.now(), deathsOnly: true)),
    ));
    await t.pump();
    expect(find.text(MistakesBookLines.deathTitle), findsOneWidget);
    expect(find.text(MistakesBookLines.deathEmpty), findsOneWidget);

    final deadlyOnes = knownMistakes.values.where((m) => m.deadly).take(2).toList();
    expect(deadlyOnes, hasLength(2));
    await book(c, DischargeMistakes.rustyEarth); // a slip: never on this page
    await book(c, deadlyOnes[0]);
    await book(c, deadlyOnes[1]);
    await book(c, deadlyOnes[1]); // repeated: goes first
    await t.pump();

    expect(find.text(MistakesBookLines.deathLine), findsOneWidget);
    expect(find.text(MistakesBookLines.deathSub), findsOneWidget);
    expect(find.text(DischargeMistakes.rustyEarth.textBn), findsNothing);
    expect(find.text(MistakesBookLines.all), findsNothing, reason: 'no filter chips');
    expect(find.text(MistakesBookLines.deadly), findsNothing);
    final twice = find.text(deadlyOnes[1].textBn);
    final once = find.text(deadlyOnes[0].textBn);
    expect(twice, findsOneWidget);
    expect(once, findsOneWidget);
    expect(t.getTopLeft(twice).dy, lessThan(t.getTopLeft(once).dy), reason: 'most repeated first');
    expect(t.takeException(), isNull);
  });

  test('every known mistake has its picture on disk', () {
    expect(knownMistakes, isNotEmpty);
    for (final m in knownMistakes.values) {
      expect(File(m.art).existsSync(), isTrue, reason: m.art);
    }
  });
}
