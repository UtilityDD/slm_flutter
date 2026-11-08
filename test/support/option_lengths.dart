// Option libraries (GAME_LEVEL_PLAYBOOK.md §4): every option in a set about
// the same length, so the right one cannot be spotted by its length.
import 'package:flutter_test/flutter_test.dart';

/// All of [options] within [ratio]× of each other in length.
void expectSameLength(String name, List<String> options, {double ratio = 1.3}) {
  expect(options, isNotEmpty, reason: name);
  final lens = options.map((t) => t.length).toList()..sort();
  expect(lens.last / lens.first, lessThanOrEqualTo(ratio), reason: '$name: lengths ${lens.first}..${lens.last}');
}

/// A library big enough not to repeat: at least [minRight] right and
/// [minWrong] wrong, no duplicates.
void expectLibrary(String name, List<String> right, List<String> wrong, {int minRight = 2, int minWrong = 5}) {
  expect(right.length, greaterThanOrEqualTo(minRight), reason: '$name: right options');
  expect(wrong.length, greaterThanOrEqualTo(minWrong), reason: '$name: wrong options');
  final all = [...right, ...wrong];
  expect(all.toSet().length, all.length, reason: '$name: duplicates');
}
