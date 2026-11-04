import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/home/lesson_quiz_store.dart';

const _quiz = [
  {'questionText': 'q1', 'options': ['a', 'b', 'c'], 'correctAnswerIndex': 1},
  {'questionText': 'q2', 'options': ['a', 'b'], 'correctAnswerIndex': 0},
];

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('lesson_quiz_store_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  LessonQuizStore store(LessonQuizHttpGet get, {Duration refreshAfter = const Duration(days: 7)}) =>
      LessonQuizStore(httpGet: get, cacheRoot: () async => tmp, refreshAfter: refreshAfter);

  test('a quiz downloaded once still loads offline after a restart', () async {
    var calls = 0;
    final online = store((uri) async {
      calls++;
      expect(uri.path, '/quizzes/questions_1_2.json');
      return LessonQuizHttpResponse(200, jsonEncode(_quiz));
    });
    final first = await online.load(1, 2);
    expect(first.status, LessonQuizStatus.ready);
    expect(first.questions.length, 2);
    // Memory hit: no second request.
    await online.load(1, 2);
    expect(calls, 1);

    // New app run, no network at all.
    final offline = store((uri) async => throw const SocketException('offline'));
    final again = await offline.load(1, 2);
    expect(again.status, LessonQuizStatus.ready);
    expect(again.questions.map((q) => q.questionText), ['q1', 'q2']);
  });

  test('offline with no saved copy is "unavailable", never "no quiz"', () async {
    final offline = store((uri) async => throw const SocketException('offline'));
    final load = await offline.load(3, 4);
    expect(load.status, LessonQuizStatus.unavailable);
    expect(load.isReady, isFalse);
  });

  test('HTML reply (site fallback or Wi-Fi login page) is "unavailable"', () async {
    final s = store((uri) async => const LessonQuizHttpResponse(200, '<!doctype html><html></html>'));
    expect((await s.load(1, 1)).status, LessonQuizStatus.unavailable);
  });

  test('server errors and slow replies are "unavailable"', () async {
    final s500 = store((uri) async => const LessonQuizHttpResponse(503, ''));
    expect((await s500.load(1, 1)).status, LessonQuizStatus.unavailable);
  });

  test('only a 404 or an empty list means the lesson has no quiz', () async {
    final missing = store((uri) async => const LessonQuizHttpResponse(404, 'not found'));
    expect((await missing.load(1, 1)).status, LessonQuizStatus.noQuiz);
    final empty = store((uri) async => const LessonQuizHttpResponse(200, '[]'));
    expect((await empty.load(1, 1)).status, LessonQuizStatus.noQuiz);
  });

  test('a failed refresh keeps the saved copy', () async {
    await store((uri) async => LessonQuizHttpResponse(200, jsonEncode(_quiz))).load(2, 1);
    // Saved copy is "stale" at once; the refresh fails offline.
    final s = store((uri) async => throw const SocketException('offline'), refreshAfter: Duration.zero);
    final load = await s.load(2, 1);
    expect(load.status, LessonQuizStatus.ready);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final file = File('${tmp.path}/lesson_quiz_v1/questions_2_1.json');
    expect(file.existsSync(), isTrue);
    expect(jsonDecode(file.readAsStringSync()), hasLength(2));
  });
}
