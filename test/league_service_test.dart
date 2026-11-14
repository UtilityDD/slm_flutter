import 'dart:io';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/rank/league_service.dart';

/// Records what would reach the server, one list per batch. [offline]
/// throws like a dead network; [refuse] answers like the RPC refusing the
/// whole batch (e.g. not verified).
class _FakeSubmitter implements LeagueSubmitter {
  bool offline = false;
  String? refuse;
  final batches = <List<LeagueResult>>[];

  List<LeagueResult> get sent => [for (final b in batches) ...b];

  @override
  Future<String?> submit(List<LeagueResult> batch) async {
    if (offline) throw const SocketException('offline');
    batches.add(List.of(batch));
    return refuse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('league rules', () {
    test('month follows India time, not UTC', () {
      // 31 Oct 19:00 UTC is 1 Nov 00:30 in Kolkata.
      expect(leagueMonthKey(DateTime.utc(2026, 10, 31, 19)), '2026-11');
      expect(leagueMonthKey(DateTime.utc(2026, 10, 31, 18, 29)), '2026-10');
    });

    test('points: stars × 10, −5 per deadly death, never below 0', () {
      expect(leaguePointsFor(3), 30);
      expect(leaguePointsFor(2), 20);
      expect(leaguePointsFor(3, deaths: 1), 25);
      expect(leaguePointsFor(1, deaths: 3), 0);
      expect(leaguePointsFor(9), 30, reason: 'stars are clamped to 3');
      expect(leaguePointsFor(-2), 0);
    });

    test('Learn mark gives stars: pass 1, 80 % 2, 100 % 3', () {
      expect(leagueStarsForLearnMark(59), 0);
      expect(leagueStarsForLearnMark(60), 1);
      expect(leagueStarsForLearnMark(79), 1);
      expect(leagueStarsForLearnMark(80), 2);
      expect(leagueStarsForLearnMark(99), 2);
      expect(leagueStarsForLearnMark(100), 3);
    });

    test('rung ids match the server pattern', () {
      for (final ok in ['1.1/learn', '10.18/do/0', '3.2/do/1', 'm1/gate', 'm10/gate']) {
        expect(isLeagueRungId(ok), isTrue, reason: ok);
      }
      for (final bad in ['', '1.1', '1.1/do/10', 'gate', 'm1/learn', "1.1/learn'; drop", 'hourly-challenge-2026-11-13-10']) {
        expect(isLeagueRungId(bad), isFalse, reason: bad);
      }
    });

    test('hidden name: last 4 of the SLM id, else of the account id', () {
      expect(leagueMaskedName(slmId: 'SLM-00 1234', id: 'x'), 'লাইনম্যান #1234');
      expect(leagueMaskedName(slmId: '  ', id: '0f8e2c1a-aaaa-bbbb-cccc-00000000beef'), 'লাইনম্যান #beef');
      expect(leagueMaskedName(id: 'ab'), 'লাইনম্যান #ab');
    });

    test('month label: Bangla month with English digits', () {
      expect(leagueMonthLabel(2026, 11), 'নভেম্বর 2026');
      expect(leagueMonthLabel(2026, 1, bn: false), 'January 2026');
      expect(RegExp('[০-৯]').hasMatch(leagueMonthLabel(2026, 12)), isFalse);
    });
  });

  group('league queue', () {
    late _FakeSubmitter server;
    late DateTime now;
    String? uid;
    final made = <LeagueService>[];

    LeagueService service() {
      final s = LeagueService(submitter: server, userId: () => uid, clock: () => now);
      made.add(s);
      return s;
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      server = _FakeSubmitter();
      now = DateTime.utc(2026, 11, 13, 6);
      uid = 'u1';
    });

    tearDown(() {
      for (final s in made) {
        s.dispose();
      }
      made.clear();
    });

    test('offline: plays wait, keeping only the best per rung', () async {
      final s = service();
      server.offline = true;
      await s.recordPlay('1.1/do/1', stars: 1, ms: 30000);
      await s.recordPlay('1.1/do/1', stars: 3, ms: 31000);
      await s.recordPlay('1.1/do/1', stars: 2, ms: 32000);
      await s.recordPlay('1.2/learn', stars: 2, ms: 20000);
      await s.flush();
      final q = await s.pending();
      expect(q.map((r) => '${r.rungId}:${r.stars}'), ['1.1/do/1:3', '1.2/learn:2']);
      expect(server.sent, isEmpty);
    });

    test('the queue survives a restart and is sent on the next flush', () async {
      server.offline = true;
      final first = service();
      await first.recordPlay('m1/gate', stars: 3, ms: 90000);
      await first.flush();
      server.offline = false;
      final fresh = service(); // a new app start reads the same saved queue
      await fresh.flush();
      expect(server.sent.map((r) => r.rungId), ['m1/gate']);
      expect(server.sent.single.stars, 3);
      expect(await fresh.pending(), isEmpty);
    });

    test('online: the first play goes at once, with its time (ms)', () async {
      final s = service();
      await s.recordPlay('2.3/do/0', stars: 2, ms: 41234);
      await s.pending(); // waits for the send
      expect(server.sent.single.rungId, '2.3/do/0');
      expect(server.sent.single.toItem(), {'rung_id': '2.3/do/0', 'stars': 2, 'deaths': 0, 'ms': 41234});
      expect(await s.pending(), isEmpty);
    });

    test('only improvements are sent: same or fewer stars this month stay home', () async {
      final s = service();
      await s.recordPlay('1.1/do/1', stars: 2, ms: 30000);
      await s.flush();
      await s.recordPlay('1.1/do/1', stars: 2, ms: 25000);
      await s.recordPlay('1.1/do/1', stars: 1, ms: 25000);
      await s.flush();
      expect(server.sent.map((r) => r.stars), [2]);
      await s.recordPlay('1.1/do/1', stars: 3, ms: 28000);
      await s.flush();
      expect(server.sent.map((r) => r.stars), [2, 3]);
    });

    test('a new month starts from zero: the same stars are sent again', () async {
      final s = service();
      await s.recordPlay('1.1/do/1', stars: 3, ms: 30000);
      await s.flush();
      now = DateTime.utc(2026, 12, 2, 6);
      await s.recordPlay('1.1/do/1', stars: 3, ms: 30000);
      await s.flush();
      expect(server.sent.map((r) => r.month), ['2026-11', '2026-12']);
    });

    test('batching: at most one automatic batch every 30 s', () async {
      final s = service();
      await s.recordPlay('1.1/do/0', stars: 3, ms: 30000);
      await s.pending();
      expect(server.batches, hasLength(1), reason: 'nothing went before: sent at once');

      now = now.add(const Duration(seconds: 5));
      await s.recordPlay('1.1/do/1', stars: 2, ms: 30000);
      await s.recordPlay('1.2/do/0', stars: 1, ms: 30000);
      await s.pending();
      expect(server.batches, hasLength(1), reason: 'inside 30 s: waits');
      expect(s.flushScheduled, isTrue);

      // The timer's turn (or the app going to the background) sends both together.
      now = now.add(const Duration(seconds: 30));
      await s.flush();
      expect(server.batches, hasLength(2));
      expect(server.batches.last.map((r) => r.rungId), ['1.1/do/1', '1.2/do/0']);
      expect(s.flushScheduled, isFalse);
    });

    test('install: the app going to the background sends the queue', () async {
      final old = LeagueService.instance;
      addTearDown(() {
        LeagueService.instance = old;
        GameSaveController.onPlayResult = null;
      });
      final s = service();
      LeagueService.instance = s;
      LeagueService.install();
      await s.recordPlay('1.1/do/0', stars: 3, ms: 30000);
      await s.pending();
      now = now.add(const Duration(seconds: 2));
      await s.recordPlay('1.1/do/1', stars: 3, ms: 30000);
      await s.pending();
      expect(server.batches, hasLength(1));
      final binding = TestWidgetsFlutterBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await s.pending();
      expect(server.batches, hasLength(2));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    test('guest play, no stars and bad rung ids are never queued', () async {
      final s = service();
      server.offline = true;
      uid = null;
      await s.recordPlay('1.1/do/1', stars: 3);
      uid = 'u1';
      await s.recordPlay('1.1/do/1', stars: 0);
      await s.recordPlay('hourly-quiz', stars: 3);
      expect(await s.pending(), isEmpty);
    });

    test('a refusal from the server (e.g. not verified) drops the plays', () async {
      final s = service();
      server.refuse = 'not_verified';
      await s.recordPlay('1.1/do/1', stars: 3, ms: 30000);
      await s.flush();
      expect(server.sent, hasLength(1));
      expect(await s.pending(), isEmpty);
    });

    test('plays of an earlier month or another account are dropped, not sent', () async {
      final s = service();
      server.offline = true;
      now = DateTime.utc(2026, 10, 20);
      await s.recordPlay('1.1/do/1', stars: 3);
      now = DateTime.utc(2026, 11, 13);
      uid = 'u2';
      await s.recordPlay('1.3/do/1', stars: 2);
      server.offline = false;
      uid = 'u1';
      await s.flush();
      expect(server.sent, isEmpty);
      expect(await s.pending(), isEmpty);
    });

    test('big queues go in batches of at most 50', () async {
      final s = service();
      server.offline = true;
      for (var m = 1; m <= 10; m++) {
        for (var l = 1; l <= 6; l++) {
          await s.recordPlay('$m.$l/do/0', stars: 1, ms: 20000);
        }
      }
      server.offline = false;
      await s.flush();
      expect(server.batches.map((b) => b.length), [50, 10]);
    });

    test('install: Do stars, Learn marks and their times reach the queue', () async {
      final old = LeagueService.instance;
      addTearDown(() {
        LeagueService.instance = old;
        GameSaveController.onPlayResult = null;
      });
      server.offline = true;
      LeagueService.instance = service();
      LeagueService.install();
      GameSaveController.onPlayResult!('1.1/do/1', stars: 2, ms: 33000);
      GameSaveController.onPlayResult!('1.1/learn', mark: 100, ms: 21000);
      GameSaveController.onPlayResult!('1.2/learn', mark: 40, ms: 9000);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final q = await LeagueService.instance.pending();
      expect(q.map((r) => '${r.rungId}:${r.stars}:${r.ms}'), unorderedEquals(['1.1/do/1:2:33000', '1.1/learn:3:21000']));
    });

    test('GameSave hands the play time from recordBestTime to recordStars', () async {
      final heard = <String>[];
      addTearDown(() => GameSaveController.onPlayResult = null);
      GameSaveController.onPlayResult = (rungId, {stars, mark, ms}) => heard.add('$rungId:$stars:$ms');
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final save = c.read(gameSaveProvider.notifier);
      await save.recordBestTime('1.1/do/0', 42000);
      await save.recordStars('1.1/do/0', 3);
      await save.recordStars('1.1/do/0', 2);
      expect(heard, ['1.1/do/0:3:42000', '1.1/do/0:2:null'], reason: 'one time per play');
    });
  });
}
