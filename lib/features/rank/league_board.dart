import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/supabase_service.dart';
import '../auth/auth_provider.dart';
import 'league_service.dart';

// Read side of the league (supabase/league.sql): `league_board` (one month),
// `league_board_all` (all-time best) and the `league_my_wins` view. Offline
// the last real board seen on this phone is shown; nothing is invented.

/// One line of the board. [name] is what the server shows publicly (the
/// approved name, or "লাইনম্যান #1234" when the member hides it).
@immutable
class LeagueRow {
  const LeagueRow({
    required this.rank,
    required this.name,
    required this.district,
    required this.points,
    required this.rungs,
    this.gapToNext = 0,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final String district;
  final int points;

  /// Rungs cleared in this scope (month or all time).
  final int rungs;

  /// Points to reach the row above (0 at the top or when tied).
  final int gapToNext;
  final bool isMe;

  factory LeagueRow.fromMap(Map<String, dynamic> m) => LeagueRow(
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        name: m['display_name']?.toString() ?? m['name']?.toString() ?? 'লাইনম্যান',
        district: m['district']?.toString() ?? '',
        points: (m['points'] as num?)?.toInt() ?? 0,
        rungs: (m['rungs'] as num?)?.toInt() ?? 0,
        gapToNext: (m['gap_to_next'] as num?)?.toInt() ?? 0,
        isMe: m['is_me'] == true,
      );

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'display_name': name,
        'district': district,
        'points': points,
        'rungs': rungs,
        'gap_to_next': gapToNext,
        'is_me': isMe,
      };
}

/// A finished month in which the member was in the top 3.
@immutable
class LeagueWin {
  const LeagueWin({required this.year, required this.month, required this.state, required this.place, this.district});

  final int year;
  final int month;

  /// True: state-wide top 3; false: district top 3.
  final bool state;
  final int place;
  final String? district;

  static LeagueWin? fromMap(Map<String, dynamic> m) {
    final at = DateTime.tryParse(m['month']?.toString() ?? '');
    final place = (m['place'] as num?)?.toInt() ?? 0;
    if (at == null || place < 1) return null;
    return LeagueWin(
      year: at.year,
      month: at.month,
      state: m['scope']?.toString() == 'state',
      place: place,
      district: m['district']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'month': '$year-${month.toString().padLeft(2, '0')}-01',
        'scope': state ? 'state' : 'district',
        'place': place,
        'district': ?district,
      };
}

/// Network side of the league. Swappable in tests.
abstract class LeagueBoardSource {
  const LeagueBoardSource();

  /// The board of the month starting [year]-[month] (India time).
  Future<List<LeagueRow>> month({required int year, required int month, String? district});

  /// Best stars on every rung ever.
  Future<List<LeagueRow>> allTime({String? district});

  /// The signed-in member's monthly top-3 finishes.
  Future<List<LeagueWin>> myWins();
}

List<LeagueRow> _rows(Object? res) => [
      if (res is List)
        for (final m in res)
          if (m is Map) LeagueRow.fromMap(Map<String, dynamic>.from(m)),
    ];

class SupabaseLeagueBoardSource extends LeagueBoardSource {
  const SupabaseLeagueBoardSource();

  @override
  Future<List<LeagueRow>> month({required int year, required int month, String? district}) async {
    final res = await SupabaseService.client.rpc('league_board', params: {
      'p_month': '$year-${month.toString().padLeft(2, '0')}-01',
      'p_district': district,
    });
    return _rows(res);
  }

  @override
  Future<List<LeagueRow>> allTime({String? district}) async {
    final res = await SupabaseService.client.rpc('league_board_all', params: {'p_district': district});
    return _rows(res);
  }

  @override
  Future<List<LeagueWin>> myWins() async {
    final res = await SupabaseService.client
        .from('league_my_wins')
        .select('month, scope, district, place')
        .order('month', ascending: false)
        .limit(24);
    return [
      for (final m in res) ?LeagueWin.fromMap(m),
    ];
  }
}

final leagueBoardSourceProvider = Provider<LeagueBoardSource>((ref) => const SupabaseLeagueBoardSource());

/// Which board: this month's (in [district], or state-wide when null) or all-time.
typedef LeagueQuery = ({bool allTime, String? district});

String _cacheKey(LeagueQuery q, String monthKey) =>
    'league_board_cache_v1|${q.allTime ? 'all' : monthKey}|${q.district ?? '*'}';

/// How long a fetched board is reused while the app runs.
const leagueFreshFor = Duration(minutes: 5);

/// One board. Offline it shows the last real copy of the same board saved on
/// this phone; with none it fails at once so the screen shows its offline state.
final leagueBoardProvider =
    FutureProvider.autoDispose.family<List<LeagueRow>, LeagueQuery>(retry: (_, _) => null, (ref, q) async {
  final now = leagueNow();
  final key = _cacheKey(q, leagueMonthKey());
  final source = ref.read(leagueBoardSourceProvider);
  try {
    final rows = q.allTime
        ? await source.allTime(district: q.district)
        : await source.month(year: now.year, month: now.month, district: q.district);
    unawaited(_saveRows(key, rows));
    final link = ref.keepAlive();
    final expire = Timer(leagueFreshFor, link.close);
    ref.onDispose(expire.cancel);
    return rows;
  } catch (_) {
    final saved = await _loadRows(key);
    if (saved == null) rethrow;
    return saved;
  }
});

Future<void> _saveRows(String key, List<LeagueRow> rows) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode([for (final r in rows) r.toJson()]));
  } catch (_) {}
}

Future<List<LeagueRow>?> _loadRows(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return _rows(jsonDecode(raw));
  } catch (_) {
    return null;
  }
}

const _winsCacheKey = 'league_wins_cache_v1';

/// The signed-in member's "মাসের সেরা লাইনম্যান" badges (newest first).
/// Empty for guests; offline the last real list for the same account.
final myLeagueWinsProvider = FutureProvider.autoDispose<List<LeagueWin>>(retry: (_, _) => null, (ref) async {
  final auth = ref.watch(authProvider);
  final id = auth.profile?.id;
  if (!auth.isAuthenticated || id == null) return const [];
  final key = '$_winsCacheKey|$id';
  try {
    final wins = await ref.read(leagueBoardSourceProvider).myWins();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode([for (final w in wins) w.toJson()]));
    } catch (_) {}
    return wins;
  } catch (_) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      final list = raw == null ? null : jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final m in list)
          if (m is Map) ?LeagueWin.fromMap(Map<String, dynamic>.from(m)),
      ];
    } catch (_) {
      return const [];
    }
  }
});
