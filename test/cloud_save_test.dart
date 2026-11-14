// Cloud progress backup (lib/features/rank/cloud_save.dart): the blob round
// trip, the 16 KB cap, the 3-minute throttle, the "more advanced save wins"
// rule and the restore question after sign-in. No network: a fake server.
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/rank/cloud_save.dart';

const _ladder = ['1.1/learn', '1.1/do/0', '1.1/do/1', '1.2/learn', '1.2/do/0', '1.2/do/1', 'm1/gate'];

/// Keeps one save like slm_app.save_progress: written only when the rank is
/// at least the stored one.
class _FakeServer extends CloudSaveServer {
  CloudSaveRemote? stored;
  final saves = <({String blob, int rank})>[];
  bool offline = false;

  @override
  Future<CloudSaveReply> save(String blob, {required int version, required int rank}) async {
    if (offline) throw StateError('offline');
    final s = stored;
    if (s != null && rank < s.rank) return CloudSaveReply(saved: false, serverRank: s.rank);
    saves.add((blob: blob, rank: rank));
    stored = CloudSaveRemote(blob: blob, rank: rank, version: version);
    return const CloudSaveReply(saved: true);
  }

  @override
  Future<CloudSaveRemote?> load() async {
    if (offline) throw StateError('offline');
    return stored;
  }
}

GameSave _progress({int cleared = 3, int stars = 2, int points = 120}) => GameSave.empty.copyWith(
      points: points,
      rungProgress: {for (var i = 0; i < cleared; i++) _ladder[i]: 'cleared'},
      starsByRung: {for (var i = 0; i < cleared; i++) if (_ladder[i].contains('/do/')) _ladder[i]: stars},
      toolbox: const ToolboxSave(lifeSkills: ['cpr'], opens: 2),
      currentRungId: _ladder[cleared - 1],
    );

Map<String, Object> _prefsWith(GameSave s, {String? ds}) => {
      'game_save_v1': jsonEncode(s.toJson()),
      'ds_progress_v2': ?ds,
    };

String _noise(Random r, int n) => String.fromCharCodes([for (var i = 0; i < n; i++) 0x0980 + r.nextInt(0x7f)]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('blob', () {
    test('round trip: game save, toolbox, life skills and duty-slip progress', () {
      final save = _progress();
      final blob = encodeCloudSave(save, dutySlip: '{"levels":{"3":"darun"}}')!;
      expect(() => base64Decode(blob), returnsNormally);
      final back = decodeCloudSave(blob)!;
      expect(back.game, save.toJson());
      expect(GameSave.fromJson(back.game).toolbox.lifeSkills, ['cpr']);
      expect(back.dutySlip, '{"levels":{"3":"darun"}}');
    });

    test('damaged or future-version blobs are refused', () {
      expect(decodeCloudSave('not base64!'), isNull);
      final future = base64Encode(gzipBytes(jsonEncode({'v': 99, 'game': GameSave.empty.toJson()})));
      expect(decodeCloudSave(future), isNull);
    });

    test('16 KB cap: old mistakes and deaths are trimmed, progress stays; too big is refused', () {
      final r = Random(7);
      final big = _progress().copyWith(
        mistakes: [
          for (var i = 0; i < 200; i++)
            MistakeEntry(key: 'k$i', lessonId: '1.1', rungId: '1.1/do/0', textBn: _noise(r, 120), deadly: false, atMs: i),
        ],
      );
      final blob = encodeCloudSave(big)!;
      expect(blob.length, lessThanOrEqualTo(cloudSaveMaxBytes));
      final back = GameSave.fromJson(decodeCloudSave(blob)!.game);
      expect(back.rungProgress, big.rungProgress);
      expect(back.starsByRung, big.starsByRung);
      expect(back.mistakes.length, lessThan(200));

      final huge = GameSave.empty.copyWith(rungProgress: {for (var i = 0; i < 3000; i++) _noise(r, 12): 'cleared'});
      expect(encodeCloudSave(huge), isNull);
    });

    test('progress rank: ladder position x 10000 + stars; further beats more stars', () {
      expect(cloudProgressRank(GameSave.empty, _ladder), 0);
      final a = _progress(cleared: 3, stars: 3); // position 3, stars 3+3
      expect(cloudProgressRank(a, _ladder), 3 * 10000 + 6);
      final b = _progress(cleared: 5, stars: 1); // position 5, stars 1+1+1
      expect(cloudProgressRank(b, _ladder), 5 * 10000 + 3);
      expect(cloudProgressRank(b, _ladder), greaterThan(cloudProgressRank(a, _ladder)));
      final proven = GameSave.empty.copyWith(rungProgress: {'1.2/do/0': 'prove'});
      expect(cloudProgressRank(proven, _ladder), 5 * 10000, reason: "'prove' (passed before a fall) counts");
    });
  });

  group('service', () {
    late _FakeServer server;
    late DateTime now;
    late CloudSaveService service;

    setUp(() {
      server = _FakeServer();
      now = DateTime.utc(2026, 11, 14, 6);
      service = CloudSaveService(server: server, clock: () => now, ladderIds: () async => _ladder)..account = 'u1';
    });

    tearDown(() => service.dispose());

    test('guests never save', () async {
      SharedPreferences.setMockInitialValues(_prefsWith(_progress()));
      service.account = null;
      expect(await service.saveNow(), isFalse);
      service.afterLevelResult();
      expect(service.saveScheduled, isFalse);
      expect(server.saves, isEmpty);
    });

    test('saves the game and duty-slip progress with its rank; an unchanged save is not sent again', () async {
      SharedPreferences.setMockInitialValues(_prefsWith(_progress(), ds: '{"x":1}'));
      expect(await service.saveNow(), isTrue);
      expect(server.saves.single.rank, 3 * 10000 + 4);
      expect(decodeCloudSave(server.saves.single.blob)!.dutySlip, '{"x":1}');
      expect(await service.saveNow(), isFalse);
      expect(server.saves, hasLength(1));
    });

    test('more advanced wins: an older phone cannot overwrite a further save', () async {
      server.stored = CloudSaveRemote(blob: encodeCloudSave(_progress(cleared: 6))!, rank: 6 * 10000);
      SharedPreferences.setMockInitialValues(_prefsWith(_progress(cleared: 2)));
      expect(await service.saveNow(), isFalse);
      expect(service.lastServerRank, 6 * 10000, reason: 'the app learns the stored rank');
      expect(server.stored!.rank, 6 * 10000);
    });

    test('offline: nothing breaks, the next save tries again', () async {
      SharedPreferences.setMockInitialValues(_prefsWith(_progress()));
      server.offline = true;
      expect(await service.saveNow(), isFalse);
      server.offline = false;
      now = now.add(const Duration(minutes: 4));
      expect(await service.saveNow(), isTrue);
    });

    test('restore offer only when the server is further ahead', () async {
      SharedPreferences.setMockInitialValues(_prefsWith(_progress(cleared: 3)));
      expect(await service.offerAfterSignIn(), isNull, reason: 'nothing saved');

      server.stored = CloudSaveRemote(blob: encodeCloudSave(_progress(cleared: 2))!, rank: 2 * 10000);
      expect(await service.offerAfterSignIn(), isNull, reason: 'server behind');

      server.stored = CloudSaveRemote(blob: encodeCloudSave(_progress(cleared: 3, stars: 2))!, rank: 3 * 10000 + 4);
      expect(await service.offerAfterSignIn(), isNull, reason: 'equal: the phone keeps its own');

      server.stored = CloudSaveRemote(blob: encodeCloudSave(_progress(cleared: 6))!, rank: 6 * 10000 + 6);
      expect((await service.offerAfterSignIn())?.rank, 6 * 10000 + 6);

      server.offline = true;
      expect(await service.offerAfterSignIn(), isNull, reason: 'offline: no question');
    });

    test('restore writes the game save, the duty-slip key and the ◆ mirror', () async {
      SharedPreferences.setMockInitialValues(_prefsWith(_progress(cleared: 1, points: 10)));
      final remote = CloudSaveRemote(blob: encodeCloudSave(_progress(cleared: 6, points: 900), dutySlip: '{"d":2}')!, rank: 60006);
      expect(await service.restore(remote), isTrue);
      final prefs = await SharedPreferences.getInstance();
      final game = GameSave.fromJson(jsonDecode(prefs.getString('game_save_v1')!) as Map<String, dynamic>);
      expect(game.points, 900);
      expect(game.rungProgress.length, 6);
      expect(prefs.getString(DutySlipEngine.progressKey), '{"d":2}');
      expect(prefs.getInt('ds_career_score'), 900);
    });
  });

  testWidgets('throttle: after a level result at most one save per 3 minutes', (tester) async {
    final server = _FakeServer();
    var now = DateTime.utc(2026, 11, 14, 6);
    final service = CloudSaveService(server: server, clock: () => now, ladderIds: () async => _ladder)..account = 'u1';
    addTearDown(service.dispose);
    SharedPreferences.setMockInitialValues(_prefsWith(_progress(cleared: 1)));

    // First result: saved after the short settle wait.
    service.afterLevelResult();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(server.saves, hasLength(1));

    // Next result 30 s later: waits until 3 minutes after the last save.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game_save_v1', jsonEncode(_progress(cleared: 2).toJson()));
    now = now.add(const Duration(seconds: 30));
    service.afterLevelResult();
    service.afterLevelResult(); // a second result does not add a second save
    expect(service.saveScheduled, isTrue);
    await tester.pump(const Duration(minutes: 2));
    expect(server.saves, hasLength(1), reason: 'inside 3 minutes');
    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 40));
    await tester.pump();
    expect(server.saves, hasLength(2));
    expect(server.saves.last.rank, 2 * 10000 + 2);
    expect(service.saveScheduled, isFalse);
  });

  group('restore question after sign-in', () {
    Future<(CloudSaveService, _FakeServer)> pumpHost(WidgetTester tester, {required int serverCleared}) async {
      final server = _FakeServer()
        ..stored = CloudSaveRemote(
          blob: encodeCloudSave(_progress(cleared: serverCleared, points: 777))!,
          rank: cloudProgressRank(_progress(cleared: serverCleared), _ladder),
        );
      final service = CloudSaveService(server: server, ladderIds: () async => _ladder);
      addTearDown(service.dispose);
      SharedPreferences.setMockInitialValues(_prefsWith(_progress(cleared: 2, points: 50)));
      await tester.pumpWidget(ProviderScope(
        overrides: [authProvider.overrideWith(() => _Auth())],
        child: MaterialApp(home: CloudSaveHost(service: service, child: const Scaffold(body: Text('home')))),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return (service, server);
    }

    testWidgets('server ahead: yes restores it and reloads the game', (tester) async {
      final (service, _) = await pumpHost(tester, serverCleared: 6);
      expect(service.account, 'u1');
      expect(find.text('আগের অগ্রগতি ফিরিয়ে আনবেন?'), findsOneWidget);
      await tester.tap(find.text('হ্যাঁ'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('আগের অগ্রগতি ফিরিয়ে আনবেন?'), findsNothing);
      final container = ProviderScope.containerOf(tester.element(find.text('home')));
      expect(container.read(gameSaveProvider).points, 777);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('game_save_v1'), contains('"points":777'));
    });

    testWidgets('"এখন না" keeps the phone\'s progress', (tester) async {
      await pumpHost(tester, serverCleared: 6);
      await tester.tap(find.text('এখন না'));
      await tester.pump(const Duration(milliseconds: 300));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('game_save_v1'), contains('"points":50'));
    });

    testWidgets('server not ahead: no question', (tester) async {
      await pumpHost(tester, serverCleared: 1);
      expect(find.text('আগের অগ্রগতি ফিরিয়ে আনবেন?'), findsNothing);
    });
  });
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        profile: LinemanProfile(id: 'u1', fullName: 'Real Me', role: 'lineman', verified: true),
      );
}

List<int> gzipBytes(String s) => gzip.encode(utf8.encode(s));
