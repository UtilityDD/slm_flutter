import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/rank/league_service.dart';

/// Records what would reach the server. [offline] throws like a dead network;
/// [refuse] answers like the RPC refusing (e.g. not verified).
class _FakeSubmitter implements LeagueSubmitter {
  bool offline = false;
  String? refuse;
  final sent = <LeagueResult>[];

  @override
  Future<String?> submit(LeagueResult r) async {
    if (offline) throw const SocketException('offline');
    sent.add(r);
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

    LeagueService service() => LeagueService(submitter: server, userId: () => uid, clock: () => now);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      server = _FakeSubmitter();
      now = DateTime.utc(2026, 11, 13, 6);
      uid = 'u1';
    });

    test('offline: plays wait, keeping only the best per rung', () async {
      final s = service();
      server.offline = true;
      await s.recordPlay('1.1/do/1', stars: 1);
      await s.recordPlay('1.1/do/1', stars: 3);
      await s.recordPlay('1.1/do/1', stars: 2);
      await s.recordPlay('1.2/learn', stars: 2);
      final q = await s.pending();
      expect(q.map((r) => '${r.rungId}:${r.stars}'), ['1.1/do/1:3', '1.2/learn:2']);
      expect(server.sent, isEmpty);
    });

    test('the queue survives a restart and is sent on the next flush', () async {
      server.offline = true;
      await service().recordPlay('m1/gate', stars: 3);
      server.offline = false;
      final fresh = service(); // a new app start reads the same saved queue
      await fresh.flush();
      expect(server.sent.map((r) => r.rungId), ['m1/gate']);
      expect(server.sent.single.stars, 3);
      expect(await fresh.pending(), isEmpty);
    });

    test('online: a play is sent at once and nothing stays queued', () async {
      final s = service();
      await s.recordPlay('2.3/do/0', stars: 2);
      expect(server.sent.single.rungId, '2.3/do/0');
      expect(server.sent.single.points, 20);
      expect(await s.pending(), isEmpty);
    });

    test('the next play also flushes what waited', () async {
      final s = service();
      server.offline = true;
      await s.recordPlay('1.1/do/1', stars: 2);
      server.offline = false;
      await s.recordPlay('1.2/do/1', stars: 1);
      expect(server.sent.map((r) => r.rungId), unorderedEquals(['1.1/do/1', '1.2/do/1']));
      expect(await s.pending(), isEmpty);
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

    test('a refusal from the server (e.g. not verified) drops the play', () async {
      final s = service();
      server.refuse = 'not_verified';
      await s.recordPlay('1.1/do/1', stars: 3);
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

    test('install: Do stars and Learn marks from the game reach the queue', () async {
      final old = LeagueService.instance;
      addTearDown(() {
        LeagueService.instance = old;
        GameSaveController.onPlayResult = null;
      });
      server.offline = true;
      LeagueService.instance = service();
      LeagueService.install();
      GameSaveController.onPlayResult!('1.1/do/1', stars: 2);
      GameSaveController.onPlayResult!('1.1/learn', mark: 100);
      GameSaveController.onPlayResult!('1.2/learn', mark: 40);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final q = await LeagueService.instance.pending();
      expect(q.map((r) => '${r.rungId}:${r.stars}'), unorderedEquals(['1.1/do/1:2', '1.1/learn:3']));
    });
  });
}
