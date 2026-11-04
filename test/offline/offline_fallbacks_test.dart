import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/quizzes/leaderboard_provider.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';

class _OfflineBoard extends LeaderboardSource {
  @override
  Future<List<LeaderboardEntry>> fetch() async => throw const SocketException('offline');
}

class _OnlineBoard extends LeaderboardSource {
  @override
  Future<List<LeaderboardEntry>> fetch() async => const [
        LeaderboardEntry(rank: 1, id: 'a', name: 'Real One', district: 'Howrah', points: 90, level: 2),
        LeaderboardEntry(rank: 2, id: 'b', name: 'Real Two', district: 'Nadia', points: 40, level: 1),
      ];
}

Future<AsyncValue<List<LeaderboardEntry>>> _board(LeaderboardSource source) async {
  // No automatic retry here, so a failure surfaces at once.
  final container = ProviderContainer(
    overrides: [leaderboardSourceProvider.overrideWithValue(source)],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  // Keep the auto-dispose board alive while it loads.
  container.listen(liveLeaderboardProvider, (_, _) {});
  try {
    return AsyncData(await container.read(liveLeaderboardProvider.future));
  } catch (e, st) {
    return AsyncError(e, st);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('leaderboard offline', () {
    test('no saved board: an error (offline state), never invented people', () async {
      SharedPreferences.setMockInitialValues({});
      final board = await _board(_OfflineBoard());
      expect(board.hasError, isTrue);
      expect(board.value, isNull);
    });

    test('offline after one good load: the last real board', () async {
      SharedPreferences.setMockInitialValues({});
      final live = await _board(_OnlineBoard());
      expect(live.value!.map((e) => e.name), ['Real One', 'Real Two']);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final offline = await _board(_OfflineBoard());
      expect(offline.value!.map((e) => e.name), ['Real One', 'Real Two']);
      expect(offline.value!.map((e) => e.rank), [1, 2]);
      expect(offline.value!.first.points, 90);
    });
  });

  group('training ladder offline', () {
    test('built from the bundled catalog and real completions only', () async {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      final catalog = ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final rows = chapterIndexFromCatalog(catalog);
      expect(rows.length, catalog.lessons.length);

      final fresh = buildTrainingLadder(rows, completedLessons: {}, devOpen: false, userLevel: 1);
      expect(fresh.every((m) => m.completedLessons == 0), isTrue);
      expect(fresh.first.status, LadderStepStatus.active);
      expect(fresh[1].status, LadderStepStatus.locked);
      expect(fresh.map((m) => m.totalLessons).reduce((a, b) => a + b), catalog.lessons.length);

      final some = buildTrainingLadder(rows, completedLessons: {'1.1', '1_2'}, devOpen: false, userLevel: 1);
      expect(some.first.completedLessons, 2);
      expect(some.first.status, LadderStepStatus.active);
    });
  });

  group('bundled data', () {
    test('safety library: every image path exists and is not empty', () {
      final items = jsonDecode(File('assets/data/safety_library.json').readAsStringSync()) as List;
      for (final item in items) {
        for (final img in (item['images'] as List? ?? const [])) {
          final f = File(img.toString());
          expect(f.existsSync() && f.lengthSync() > 0, isTrue, reason: '${item['id']}: $img');
        }
      }
    });

    test('hourly pack: no web links as options, every image exists', () {
      final pack = jsonDecode(File('assets/data/hourly_quiz_pack.json').readAsStringSync()) as Map;
      for (final q in pack['questions'] as List) {
        final image = q['image']?.toString() ?? '';
        if (image.isNotEmpty) {
          final f = File(image);
          expect(f.existsSync() && f.lengthSync() > 0, isTrue, reason: '${q['id']}: $image');
        }
        for (final o in q['options'] as List) {
          expect(o['value'].toString().contains('http'), isFalse, reason: '${q['id']}');
          final oi = o['image']?.toString() ?? '';
          if (oi.isNotEmpty) expect(File(oi).existsSync(), isTrue, reason: '${q['id']}: $oi');
        }
      }
    });

    test('emergency directory: only real districts', () {
      final rows = jsonDecode(File('assets/data/districtEmergencyServices.json').readAsStringSync()) as List;
      final districts = (jsonDecode(File('assets/data/wb_locations.json').readAsStringSync()) as Map).keys.toSet();
      final used = {for (final r in rows) r['district'].toString()};
      expect(used.difference(districts), isEmpty);
    });
  });
}
