import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/rank/league_board.dart';
import 'package:slm_flutter/features/rank/league_service.dart';
import 'package:slm_flutter/features/rank/rank_screen.dart';

/// A board with no network: rows per query, and a log of what was asked.
class _FakeBoard extends LeagueBoardSource {
  _FakeBoard({List<LeagueRow> month = const [], List<LeagueRow> all = const [], this.showName = true})
      : monthRows = month,
        allRows = all;

  final List<LeagueRow> monthRows;
  final List<LeagueRow> allRows;

  /// What slm_app.my_league_settings answers for "show my name".
  bool showName;
  final asked = <String>[];

  @override
  Future<List<LeagueRow>> month({required int year, required int month, String? district}) async {
    asked.add('month:${district ?? '*'}');
    return monthRows;
  }

  @override
  Future<List<LeagueRow>> allTime({String? district}) async {
    asked.add('all:${district ?? '*'}');
    return allRows;
  }

  @override
  Future<List<LeagueWin>> myWins() async => const [];

  @override
  Future<bool> myShowName() async => showName;

  @override
  Future<bool> setShowName(bool value) async {
    asked.add('show:$value');
    showName = value;
    return true;
  }
}

class _OfflineBoard extends _FakeBoard {
  @override
  Future<List<LeagueRow>> month({required int year, required int month, String? district}) async =>
      throw const SocketException('offline');

  @override
  Future<List<LeagueRow>> allTime({String? district}) async => throw const SocketException('offline');
}

Future<List<LeagueRow>?> _read(LeagueBoardSource source, LeagueQuery q) async {
  final c = ProviderContainer(overrides: [leagueBoardSourceProvider.overrideWithValue(source)], retry: (_, _) => null);
  addTearDown(c.dispose);
  c.listen(leagueBoardProvider(q), (_, _) {});
  try {
    return await c.read(leagueBoardProvider(q).future);
  } catch (_) {
    return null;
  }
}

class _Auth extends AuthNotifier {
  _Auth(this.value);
  final AuthState value;

  @override
  AuthState build() => value;
}

const _verified = LinemanProfile(
  id: 'u1',
  fullName: 'Real Me',
  role: 'lineman',
  slmId: 'SLM1234',
  district: 'Howrah',
  verified: true,
);

LeagueRow _row(int rank, String name, int points, {bool me = false, int gap = 0}) =>
    LeagueRow(rank: rank, name: name, district: 'Howrah', points: points, rungs: points ~/ 30, gapToNext: gap, isMe: me);

final _top = [
  _row(1, 'Asha Das', 300),
  _row(2, 'Bimal Roy', 250, gap: 50),
  _row(3, 'Chandan Pal', 200, gap: 50),
  _row(4, 'Dipu Sen', 120, gap: 80),
];

Future<void> _pump(WidgetTester tester, {required AuthState auth, required _FakeBoard board}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _Auth(auth)),
      leagueBoardSourceProvider.overrideWithValue(board),
    ],
    child: const MaterialApp(home: Material(child: RankScreen())),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('verified with a district: three tabs, each asks its own board', (tester) async {
    final board = _FakeBoard(month: _top, all: [_row(1, 'Ever Best', 900)]);
    await _pump(tester, auth: const AuthState(profile: _verified, email: 'me@example.com'), board: board);

    expect(find.text('আমার জেলা'), findsOneWidget);
    expect(find.text('সারা রাজ্য'), findsOneWidget);
    expect(find.text('সর্বকালের সেরা'), findsOneWidget);
    expect(board.asked, ['month:Howrah']);
    expect(find.text('যাচাই হলে আপনিও বোর্ডে উঠবেন'), findsNothing);

    await tester.tap(find.text('সারা রাজ্য'));
    await _settle(tester);
    expect(board.asked.last, 'month:*');

    await tester.tap(find.text('সর্বকালের সেরা'));
    await _settle(tester);
    expect(board.asked.last, 'all:*');
    expect(find.text('Ever'), findsOneWidget, reason: 'podium shows the first name');
  });

  testWidgets('monthly header: Bangla month with English digits', (tester) async {
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: _top));
    final now = leagueNow();
    final label = leagueMonthLabel(now.year, now.month);
    expect(find.text(label), findsOneWidget);
    expect(label, contains('${now.year}'));
  });

  testWidgets('no district on the profile: the district tab is hidden', (tester) async {
    const noDistrict = LinemanProfile(id: 'u1', fullName: 'Real Me', role: 'lineman', verified: true);
    final board = _FakeBoard(month: _top);
    await _pump(tester, auth: const AuthState(profile: noDistrict), board: board);
    expect(find.text('আমার জেলা'), findsNothing);
    expect(find.text('সারা রাজ্য'), findsOneWidget);
    expect(board.asked, ['month:*']);
  });

  testWidgets('guest: can look, sees the join banner, has no standing card', (tester) async {
    await _pump(tester, auth: AuthState(profile: LinemanProfile.guest()), board: _FakeBoard(month: _top));
    expect(find.text('যাচাই হলে আপনিও বোর্ডে উঠবেন'), findsOneWidget);
    expect(find.text('লগইন করে যাচাইয়ের জন্য আবেদন করুন।'), findsOneWidget);
    expect(find.text('আপনার অবস্থান'), findsNothing);
    expect(find.text('আমার জেলা'), findsNothing, reason: "a guest's sample district is not used");
    expect(find.text('Dipu Sen'), findsOneWidget, reason: 'the board itself is visible');
  });

  testWidgets('signed in but pending: banner with the verification status', (tester) async {
    const pending = LinemanProfile(id: 'u9', fullName: 'New One', role: 'pending', verified: false, district: 'Nadia');
    await _pump(tester, auth: const AuthState(profile: pending), board: _FakeBoard(month: _top));
    expect(find.text('যাচাই হলে আপনিও বোর্ডে উঠবেন'), findsOneWidget);
    expect(find.text('আপনার যাচাই: অপেক্ষমাণ'), findsOneWidget);
    expect(find.text('আপনার অবস্থান'), findsNothing);
  });

  testWidgets("the 'আপনি' row and the gap to the next rank", (tester) async {
    final rows = [..._top, _row(5, 'Real Me', 90, me: true, gap: 30)];
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: rows));
    expect(find.text('আপনি'), findsOneWidget);
    expect(find.text('Real Me'), findsOneWidget);
    expect(find.text('আপনার অবস্থান'), findsOneWidget);
    expect(find.text('স্থান 5'), findsOneWidget);
    expect(find.text('পরের স্থানে যেতে আর 30 পয়েন্ট'), findsOneWidget);
  });

  testWidgets('below the top 100: own row comes after a gap', (tester) async {
    final rows = [..._top, _row(150, 'Real Me', 10, me: true, gap: 5)];
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: rows));
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    expect(find.text('স্থান 150'), findsOneWidget);
    expect(find.text('পরের স্থানে যেতে আর 5 পয়েন্ট'), findsOneWidget);
  });

  testWidgets('name hidden: own row shows "লাইনম্যান #" + last 4 of the SLM id', (tester) async {
    // The choice comes from slm_app.my_league_settings, not a profiles column.
    // The saved board may still carry the name from before the switch.
    final rows = [..._top, _row(5, 'Real Me', 90, me: true, gap: 30), _row(6, 'লাইনম্যান #9876', 60, gap: 30)];
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: rows, showName: false));
    expect(find.text('Real Me'), findsNothing);
    expect(find.text('লাইনম্যান #1234'), findsOneWidget);
    expect(find.text('লাইনম্যান #9876'), findsOneWidget, reason: "others' hidden names come from the server");
  });

  testWidgets('empty board: an honest empty state, no invented people', (tester) async {
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard());
    expect(find.text('এখনও কেউ নেই'), findsOneWidget);
    expect(find.text('এখনও বোর্ডে নেই'), findsOneWidget);
  });

  test('offline: the last real copy of the same board, never invented rows', () async {
    SharedPreferences.setMockInitialValues({});
    const state = (allTime: false, district: null);
    const all = (allTime: true, district: null);
    expect(await _read(_OfflineBoard(), state), isNull, reason: 'nothing saved yet: offline state');

    await _read(_FakeBoard(month: _top), state);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final saved = await _read(_OfflineBoard(), state);
    expect(saved!.map((r) => r.name), _top.map((r) => r.name));
    expect(await _read(_OfflineBoard(), all), isNull, reason: 'the all-time board has its own copy');
  });
}
