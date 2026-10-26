import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class HourlyOption {
  final String value;
  final String image;

  const HourlyOption({required this.value, required this.image});

  bool get hasImage => image.isNotEmpty;
}

class HourlyQuestion {
  final String id;
  final String text;
  final String image;
  final List<HourlyOption> options;
  final List<String> tags;
  final bool visual;

  const HourlyQuestion({
    required this.id,
    required this.text,
    required this.image,
    required this.options,
    required this.tags,
    required this.visual,
  });

  String get difficulty {
    final names = tags.map((tag) => tag.toLowerCase());
    if (names.contains('hard')) return 'hard';
    if (names.contains('medium')) return 'medium';
    return 'easy';
  }
}

class HourlyPack {
  final List<HourlyQuestion> questions;

  const HourlyPack(this.questions);

  static Future<HourlyPack> load() async {
    final raw = await rootBundle.loadString('assets/data/hourly_quiz_pack.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final rows = json['questions'] as List<dynamic>? ?? [];
    final questions = <HourlyQuestion>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final options = <HourlyOption>[];
      for (final option in row['options'] as List<dynamic>? ?? []) {
        if (option is! Map) continue;
        final value = option['value']?.toString() ?? '';
        if (value.isEmpty) continue;
        options.add(HourlyOption(value: value, image: option['image']?.toString() ?? ''));
      }
      final id = row['id']?.toString() ?? '';
      final text = row['text']?.toString() ?? '';
      if (id.isEmpty || text.isEmpty || options.length < 2) continue;
      questions.add(HourlyQuestion(
        id: id,
        text: text,
        image: row['image']?.toString() ?? '',
        options: options,
        tags: (row['tags'] as List<dynamic>? ?? []).map((tag) => tag.toString()).toList(),
        visual: row['visual'] == true,
      ));
    }
    return HourlyPack(questions);
  }
}

String hourlyQuizId(DateTime now) {
  final ist = now.toUtc().add(const Duration(hours: 5, minutes: 30));
  String two(int value) => value.toString().padLeft(2, '0');
  return 'hourly-challenge-${ist.year}-${two(ist.month)}-${two(ist.day)}-${two(ist.hour)}';
}

/// Five questions for this user and hour. Picture questions stay between one and two
/// when the pack has both kinds. The right answer is not in this list.
List<HourlyQuestion> pickHourlyQuestions({
  required List<HourlyQuestion> bank,
  required String seed,
  required int lifetimePoints,
}) {
  if (bank.isEmpty) return [];
  final tier = lifetimePoints < 10000
      ? 0
      : lifetimePoints < 30000
          ? 1
          : lifetimePoints < 50000
              ? 2
              : 3;
  const allowed = [
    ['easy'],
    ['easy', 'medium'],
    ['medium', 'hard'],
    ['medium', 'hard'],
  ];
  final band = bank.where((question) => allowed[tier].contains(question.difficulty)).toList();
  final pool = band.length >= 5 ? band : [...bank];
  final rng = _SeededRandom(seed);
  pool.shuffle(rng);
  final visual = pool.where((question) => question.visual).toList();
  final text = pool.where((question) => !question.visual).toList();
  final picked = <HourlyQuestion>[];
  if (visual.isNotEmpty) picked.add(visual.removeAt(0));
  while (picked.length < 5 && text.isNotEmpty) {
    picked.add(text.removeAt(0));
  }
  while (picked.length < 5 && visual.isNotEmpty && picked.where((question) => question.visual).length < 2) {
    picked.add(visual.removeAt(0));
  }
  while (picked.length < 5 && text.isNotEmpty) {
    picked.add(text.removeAt(0));
  }
  while (picked.length < 5 && visual.isNotEmpty) {
    picked.add(visual.removeAt(0));
  }
  picked.shuffle(rng);
  return [
    for (final question in picked)
      HourlyQuestion(
        id: question.id,
        text: question.text,
        image: question.image,
        options: [...question.options]..shuffle(rng),
        tags: question.tags,
        visual: question.visual,
      ),
  ];
}

class _SeededRandom implements Random {
  int _state;

  _SeededRandom(String seed) : _state = _hash(seed) & 0x7fffffff;

  static int _hash(String seed) {
    var hash = 2166136261;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  double _next() {
    _state = (1664525 * _state + 1013904223) & 0x7fffffff;
    return _state / 0x7fffffff;
  }

  @override
  bool nextBool() => _next() < 0.5;

  @override
  double nextDouble() => _next();

  @override
  int nextInt(int max) {
    if (max <= 1) return 0;
    final value = (_next() * max).floor();
    return value >= max ? max - 1 : value;
  }
}
