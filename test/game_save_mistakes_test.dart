// "আমার ভুলের খাতা", the near-miss and fall option C: a death turns the Do
// levels passed since the last death back to 'prove'; Learn rungs stay done.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/game_save.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(ProviderContainer, GameSaveController)> boot() async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final save = c.read(gameSaveProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    return (c, save);
  }

  test('mistakes book keeps one entry per key, counts repeats, survives a reload', () async {
    final (c, save) = await boot();
    for (var i = 0; i < 2; i++) {
      await save.addMistake(
        key: '1.5/discharge/rusty-earth',
        lessonId: '1.5',
        rungId: '1.5/do/1',
        textBn: 'মরিচা ধরা আর্থ',
        deadly: false,
        lessonPoint: 1,
      );
    }
    await save.addMistake(
      key: '1.5/discharge/line-before-earth',
      lessonId: '1.5',
      rungId: '1.5/do/1',
      textBn: 'আগে লাইন',
      deadly: true,
      lessonPoint: 1,
    );
    final book = c.read(gameSaveProvider).mistakes;
    expect(book.length, 2);
    expect(book.first.key, '1.5/discharge/rusty-earth');
    expect(book.first.count, 2);
    expect(book.last.deadly, isTrue);

    final back = GameSave.fromJson(c.read(gameSaveProvider).toJson());
    expect(back.mistakes.length, 2);
    expect(back.mistakes.first.count, 2);
    expect(back.mistakes.last.lessonPoint, 1);
  });

  test('the first deadly mistake is a near-miss, only once', () async {
    final (c, save) = await boot();
    expect(await save.useNearMiss(), isTrue);
    expect(await save.useNearMiss(), isFalse);
    expect(GameSave.fromJson(c.read(gameSaveProvider).toJson()).nearMissUsed, isTrue);
  });

  test('a death sends Do levels passed since the last death back to prove; Learn stays', () async {
    final (c, save) = await boot();
    await save.markRungCleared('1.1/learn');
    await save.markRungCleared('1.1/do/0');
    await save.markRungCleared('1.1/do/1');
    await save.markRungCleared('m1/gate');
    expect(c.read(gameSaveProvider).clearedSinceDeath, ['1.1/do/0', '1.1/do/1', 'm1/gate']);

    await save.recordLethalDeath(cause: 'আগে লাইন', lessonId: '1.5', rungId: '1.5/do/1', moduleFirstRungId: '1.1/learn');
    final s = c.read(gameSaveProvider);
    expect(s.deaths, 1);
    expect(s.rungProgress['1.1/learn'], 'cleared');
    expect(s.rungProgress['1.1/do/0'], 'prove');
    expect(s.rungProgress['1.1/do/1'], 'prove');
    expect(s.rungProgress['m1/gate'], 'prove');
    expect(s.clearedSinceDeath, isEmpty);

    // Proven again, then another death: only what was passed after the first death falls.
    await save.markRungCleared('1.1/do/0');
    await save.recordLethalDeath(cause: 'x', lessonId: '1.5', rungId: '1.5/do/1', moduleFirstRungId: '1.1/learn');
    final s2 = c.read(gameSaveProvider);
    expect(s2.rungProgress['1.1/do/0'], 'prove');
    expect(s2.rungProgress['1.1/do/1'], 'prove');
    expect(s2.deaths, 2);
  });

  test('old saves without the new fields still load', () {
    final s = GameSave.fromJson({'points': 5});
    expect(s.mistakes, isEmpty);
    expect(s.clearedSinceDeath, isEmpty);
    expect(s.nearMissUsed, isFalse);
  });

  test('only Do levels and gates can fall', () {
    expect(isFallableRung('1.5/do/1'), isTrue);
    expect(isFallableRung('m1/gate'), isTrue);
    expect(isFallableRung('1.5/learn'), isFalse);
  });
}
