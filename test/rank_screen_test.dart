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
  _FakeBoard({List<LeagueRow> month = const [], List<LeagueRow> all = const [], this.showName = true, this.nameAsked = true})
      : monthRows = month,
        allRows = all;

  final List<LeagueRow> monthRows;
  final List<LeagueRow> allRows;

  /// What slm_app.my_league answers.
  bool showName;
  bool nameAsked;
  final asked = <String>[];

  @override
  Future<List<LeagueRow>> month({required bool district}) async {
    asked.add('month:${district ? 'district' : 'state'}');
    return monthRows;
  }

  @override
  Future<List<LeagueRow>> allTime({required bool district}) async {
    asked.add('all:${district ? 'district' : 'state'}');
    return allRows;
  }

  @override
  Future<LeagueMe> myLeague() async {
    asked.add('me');
    return LeagueMe(showName: showName, nameAsked: nameAsked);
  }

  @override
  Future<List<LeagueWin>> myWins() async => const [];

  @override
  Future<bool> setShowName(bool value) async {
    asked.add('show:$value');
    showName = value;
    nameAsked = true;
    return true;
  }
}

class _OfflineBoard extends _FakeBoard {
  @override
  Future<List<LeagueRow>> month({required bool district}) async => throw const SocketException('offline');

  @override
  Future<List<LeagueRow>> allTime({required bool district}) async => throw const SocketException('offline');
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

LeagueRow _row(int rank, String name, int points, {bool me = false, int gap = 0}) => LeagueRow(
      rank: rank,
      name: name,
      district: 'Howrah',
      districtBn: 'হাওড়া',
      points: points,
      rungs: points ~/ 30,
      gapToNext: gap,
      isMe: me,
    );

final _top = [
  _row(1, 'Asha Das', 300),
  _row(2, 'Bimal Roy', 250, gap: 50),
  _row(3, 'Chandan Pal', 200, gap: 50),
  _row(4, 'Dipu Sen', 120, gap: 80),
];

/// The board cache's clock (leagueClockProvider).
var _now = DateTime.utc(2026, 11, 14, 6);

Future<void> _pump(
  WidgetTester tester, {
  required AuthState auth,
  required _FakeBoard board,
  bool freshPrefs = true,
}) async {
  if (freshPrefs) SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _Auth(auth)),
      leagueBoardSourceProvider.overrideWithValue(board),
      leagueClockProvider.overrideWithValue(() => _now),
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

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byType(ListView).first, const Offset(0, 500), 1500);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUp(() {
    resetLeagueBoardMemory();
    _now = DateTime.utc(2026, 11, 14, 6);
  });

  testWidgets('verified with a district: three tabs, each asks its own board', (tester) async {
    final board = _FakeBoard(month: _top, all: [_row(1, 'Ever Best', 900)]);
    await _pump(tester, auth: const AuthState(profile: _verified, email: 'me@example.com'), board: board);

    expect(find.text('আমার জেলা'), findsOneWidget);
    expect(find.text('সারা রাজ্য'), findsOneWidget);
    expect(find.text('সর্বকালের সেরা'), findsOneWidget);
    expect(board.asked.where((a) => a != 'me'), ['month:district']);
    expect(find.text('যাচাই হলে আপনিও বোর্ডে উঠবেন'), findsNothing);

    await tester.tap(find.text('সারা রাজ্য'));
    await _settle(tester);
    expect(board.asked.last, 'month:state');

    await tester.tap(find.text('সর্বকালের সেরা'));
    await _settle(tester);
    expect(board.asked.last, 'all:state');
    expect(find.text('Ever'), findsOneWidget, reason: 'podium shows the first name');
  });

  testWidgets('monthly header: Bangla month with English digits', (tester) async {
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: _top));
    final now = leagueNow();
    final label = leagueMonthLabel(now.year, now.month);
    expect(find.text(label), findsOneWidget);
    expect(label, contains('${now.year}'));
    expect(find.textContaining(RegExp('[০-৯]')), findsNothing);
  });

  testWidgets('no district on the profile: the district tab is hidden', (tester) async {
    const noDistrict = LinemanProfile(id: 'u1', fullName: 'Real Me', role: 'lineman', verified: true);
    final board = _FakeBoard(month: _top);
    await _pump(tester, auth: const AuthState(profile: noDistrict), board: board);
    expect(find.text('আমার জেলা'), findsNothing);
    expect(find.text('সারা রাজ্য'), findsOneWidget);
    expect(board.asked.where((a) => a != 'me'), ['month:state']);
  });

  testWidgets('guest: can look, sees the join banner, has no standing card, no name question', (tester) async {
    final board = _FakeBoard(month: _top, nameAsked: false);
    await _pump(tester, auth: AuthState(profile: LinemanProfile.guest()), board: board);
    expect(find.text('যাচাই হলে আপনিও বোর্ডে উঠবেন'), findsOneWidget);
    expect(find.text('লগইন করে যাচাইয়ের জন্য আবেদন করুন।'), findsOneWidget);
    expect(find.text('আপনার অবস্থান'), findsNothing);
    expect(find.text('আমার জেলা'), findsNothing, reason: "a guest's sample district is not used");
    expect(find.text('Dipu Sen'), findsOneWidget, reason: 'the board itself is visible');
    expect(find.text('বোর্ডে আপনার নাম দেখাবেন?'), findsNothing);
    expect(board.asked, isNot(contains('me')), reason: 'guests have no my_league');
  });

  testWidgets('signed in but pending: banner with the verification status', (tester) async {
    const pending = LinemanProfile(id: 'u9', fullName: 'New One', role: 'pending', verified: false, district: 'Nadia');
    await _pump(tester, auth: const AuthState(profile: pending), board: _FakeBoard(month: _top));
    expect(find.text('যাচাই হলে আপনিও বোর্ডে উঠবেন'), findsOneWidget);
    expect(find.text('আপনার যাচাই: অপেক্ষমাণ'), findsOneWidget);
    expect(find.text('আপনার অবস্থান'), findsNothing);
  });

  testWidgets("the 'আপনি' row, the gap to the next rank and the Bangla district", (tester) async {
    final rows = [..._top, _row(5, 'Real Me', 90, me: true, gap: 30)];
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: rows));
    expect(find.text('আপনি'), findsOneWidget);
    expect(find.text('Real Me'), findsOneWidget);
    expect(find.text('আপনার অবস্থান'), findsOneWidget);
    expect(find.text('স্থান 5'), findsOneWidget);
    expect(find.text('পরের স্থানে যেতে আর 30 পয়েন্ট'), findsOneWidget);
    expect(find.text('হাওড়া · 3 লেভেল'), findsOneWidget);
  });

  testWidgets('below the top 50: own row comes after a gap', (tester) async {
    final rows = [..._top, _row(150, 'Real Me', 10, me: true, gap: 5)];
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: rows));
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    expect(find.text('স্থান 150'), findsOneWidget);
    expect(find.text('পরের স্থানে যেতে আর 5 পয়েন্ট'), findsOneWidget);
    expect(find.text('সেরা 4'), findsOneWidget, reason: 'own row below the top is not counted');
  });

  testWidgets('tie-break: equal points keep the server order, who got there first', (tester) async {
    final rows = [
      _row(1, 'Asha Das', 300),
      _row(2, 'Bimal Roy', 250, gap: 50),
      _row(3, 'Chandan Pal', 250),
      _row(4, 'Dipu Sen', 250),
      _row(5, 'Real Me', 250, me: true),
    ];
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: rows));
    expect(find.byKey(const ValueKey('league-tie-note')), findsOneWidget);
    expect(find.text('সমান পয়েন্ট হলে যিনি আগে পৌঁছেছেন তিনি আগে।'), findsOneWidget);
    expect(find.text('স্থান 5'), findsOneWidget);
    expect(find.text('সমান পয়েন্ট — উপরের জন আগে পৌঁছেছেন। আর একটা তারা নিলেই এগিয়ে যাবেন'), findsOneWidget);
    // Dipu (4) is listed above the member (5) although both have 250.
    final dipu = tester.getTopLeft(find.text('Dipu Sen')).dy;
    final me = tester.getTopLeft(find.text('Real Me')).dy;
    expect(dipu, lessThan(me));
  });

  testWidgets('name hidden: own row shows "লাইনম্যান #" + last 4 of the SLM id', (tester) async {
    // The choice comes from slm_app.my_league, not a profiles column.
    // The saved board may still carry the name from before the switch.
    final rows = [..._top, _row(5, 'Real Me', 90, me: true, gap: 30), _row(6, 'লাইনম্যান #9876', 60, gap: 30)];
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: rows, showName: false));
    expect(find.text('Real Me'), findsNothing);
    expect(find.text('লাইনম্যান #1234'), findsOneWidget);
    expect(find.text('লাইনম্যান #9876'), findsOneWidget, reason: "others' hidden names come from the server");
  });

  testWidgets('first visit asks once: "বোর্ডে আপনার নাম দেখাবেন?" and saves the answer', (tester) async {
    final board = _FakeBoard(month: _top, nameAsked: false);
    await _pump(tester, auth: const AuthState(profile: _verified), board: board);
    expect(find.text('বোর্ডে আপনার নাম দেখাবেন?'), findsOneWidget);
    expect(find.textContaining('লাইনম্যান #1234'), findsOneWidget, reason: 'the dialog shows the hidden form');

    await tester.tap(find.text('না'));
    await _settle(tester);
    expect(find.text('বোর্ডে আপনার নাম দেখাবেন?'), findsNothing);
    expect(board.asked, contains('show:false'));

    // Next visit (new screen, same phone): my_league now says it was answered.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, auth: const AuthState(profile: _verified), board: board, freshPrefs: false);
    expect(find.text('বোর্ডে আপনার নাম দেখাবেন?'), findsNothing);
    expect(board.asked.where((a) => a.startsWith('show:')), ['show:false']);
  });

  testWidgets('the question is not asked when already answered', (tester) async {
    final board = _FakeBoard(month: _top, nameAsked: true);
    await _pump(tester, auth: const AuthState(profile: _verified), board: board);
    expect(find.text('বোর্ডে আপনার নাম দেখাবেন?'), findsNothing);
  });

  testWidgets('opening the Rank screen marks this month as seen (Home chip)', (tester) async {
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard(month: _top));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(leagueSeenMonthKey), '2026-11');
  });

  testWidgets('cache: a board is reused for 15 min; pull-to-refresh at most once a minute', (tester) async {
    final board = _FakeBoard(month: _top);
    int boards() => board.asked.where((a) => a.startsWith('month:')).length;
    await _pump(tester, auth: const AuthState(profile: _verified), board: board);
    expect(boards(), 1);

    _now = _now.add(const Duration(seconds: 30));
    await _pullToRefresh(tester);
    expect(boards(), 1, reason: 'asked 30 s ago: the refresh waits');

    _now = _now.add(const Duration(minutes: 2));
    await _pullToRefresh(tester);
    expect(boards(), 2, reason: 'a minute has passed: asked again');

    // A new app start 5 minutes later uses the saved copy.
    await tester.pumpWidget(const SizedBox());
    resetLeagueBoardMemory();
    _now = _now.add(const Duration(minutes: 5));
    await _pump(tester, auth: const AuthState(profile: _verified), board: board, freshPrefs: false);
    expect(boards(), 2);
    expect(find.text('Dipu Sen'), findsOneWidget);

    // After 15 minutes it asks again.
    await tester.pumpWidget(const SizedBox());
    _now = _now.add(const Duration(minutes: 16));
    await _pump(tester, auth: const AuthState(profile: _verified), board: board, freshPrefs: false);
    expect(boards(), 3);
  });

  testWidgets('empty board: an honest empty state, no invented people', (tester) async {
    await _pump(tester, auth: const AuthState(profile: _verified), board: _FakeBoard());
    expect(find.text('এখনও কেউ নেই'), findsOneWidget);
    expect(find.text('এই মাসে 3টি লেভেল পার করলেই বোর্ডে উঠবেন।'), findsOneWidget);
    expect(find.text('এখনও বোর্ডে নেই'), findsOneWidget);
  });

  test('offline: the last real copy of the same board, never invented rows', () async {
    SharedPreferences.setMockInitialValues({});
    const state = (allTime: false, district: false);
    const all = (allTime: true, district: false);
    expect(await _read(_OfflineBoard(), state), isNull, reason: 'nothing saved yet: offline state');

    await _read(_FakeBoard(month: _top), state);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final saved = await _read(_OfflineBoard(), state);
    expect(saved!.map((r) => r.name), _top.map((r) => r.name));
    expect(await _read(_OfflineBoard(), all), isNull, reason: 'the all-time board has its own copy');
  });
}
