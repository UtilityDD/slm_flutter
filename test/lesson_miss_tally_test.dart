import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';

void main() {
  setUp(() {
    LessonMissTally.resetAll();
    ReadLessonNudges.resetAll();
  });

  test('every third miss in a row offers the lesson, across replays', () {
    // Two-question text levels: a run of misses carries over to the next play.
    final offers = [for (var i = 0; i < 7; i++) LessonMissTally.miss('1.2')];
    expect(offers, [false, false, true, false, false, true, false]);
  });

  test('a right answer breaks the run', () {
    LessonMissTally.miss('1.1');
    LessonMissTally.miss('1.1');
    LessonMissTally.hit('1.1');
    expect(LessonMissTally.miss('1.1'), isFalse);
    expect(LessonMissTally.miss('1.1'), isFalse);
    expect(LessonMissTally.miss('1.1'), isTrue);
  });

  test('lessons are counted separately and reading resets the count', () {
    LessonMissTally.miss('1.1');
    LessonMissTally.miss('1.1');
    expect(LessonMissTally.miss('1.3'), isFalse);
    LessonMissTally.read('1.1');
    expect(LessonMissTally.miss('1.1'), isFalse);
    expect(LessonMissTally.miss('1.1'), isFalse);
    expect(LessonMissTally.miss('1.1'), isTrue);
  });

  test('end nudges never repeat back to back', () {
    final rng = Random(7);
    var prev = ReadLessonNudges.next('1.1', rng);
    for (var i = 0; i < 40; i++) {
      final next = ReadLessonNudges.next(i.isEven ? '1.1' : '1.2', rng);
      expect(next, isNot(prev));
      prev = next;
    }
  });
}
