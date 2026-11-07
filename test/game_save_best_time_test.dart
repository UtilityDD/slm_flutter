import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/game_save.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('best time: first clear saved, slower kept out, faster replaces', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final save = c.read(gameSaveProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    final first = await save.recordBestTime('1.1/learn', 42000);
    expect(first.record, isTrue);
    expect(first.previous, isNull);

    final slower = await save.recordBestTime('1.1/learn', 50000);
    expect(slower.record, isFalse);
    expect(c.read(gameSaveProvider).bestTimeMsByRung['1.1/learn'], 42000);

    final faster = await save.recordBestTime('1.1/learn', 38000);
    expect(faster.record, isTrue);
    expect(faster.previous, 42000);

    final json = c.read(gameSaveProvider).toJson();
    expect(GameSave.fromJson(json).bestTimeMsByRung['1.1/learn'], 38000);
  });

  test('old saves without best times still load', () {
    final s = GameSave.fromJson({'points': 10});
    expect(s.points, 10);
    expect(s.bestTimeMsByRung, isEmpty);
  });
}
