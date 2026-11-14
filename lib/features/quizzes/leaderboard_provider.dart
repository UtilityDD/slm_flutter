import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/supabase_service.dart';

class LeaderboardEntry {
  final int rank;
  final String id;
  final String name;
  final String district;
  final int points;
  final int level;
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    required this.district,
    required this.points,
    required this.level,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardEntry(
      rank: rank,
      id: map['id']?.toString() ?? '',
      name: map['display_name']?.toString() ?? 'লাইনম্যান',
      district: map['district']?.toString() ?? 'পশ্চিমবঙ্গ',
      points: (map['points'] as num?)?.toInt() ?? 0,
      level: (map['training_level'] as num?)?.toInt() ?? 1,
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}

List<LeaderboardEntry> _ranked(List<LeaderboardEntry> rows) {
  return [
    for (var i = 0; i < rows.length; i++)
      LeaderboardEntry(
        rank: i + 1,
        id: rows[i].id,
        name: rows[i].name,
        district: rows[i].district,
        points: rows[i].points,
        level: rows[i].level,
        avatarUrl: rows[i].avatarUrl,
      ),
  ];
}

const _boardSize = 25;

/// Network side of the board. Swappable in tests.
///
/// Reads this month's state-wide league board, `slm_app.league_board`
/// (supabase/slm_app_10_league.sql, SECURITY DEFINER): approved names or
/// "লাইনম্যান #1234", district and points of verified, unblocked, unhidden
/// people only. Nothing is read from `profiles` directly, so it does not
/// depend on the web app's profiles policies. The board has no ids or photos:
/// the member's own row (`is_me`) gets their account id, others a rank key.
class LeaderboardSource {
  const LeaderboardSource();

  Future<List<LeaderboardEntry>> fetch() async {
    final res = await SupabaseService.client
        .schema('slm_app')
        .rpc('league_board', params: {'p_scope': 'state'});
    String? me;
    try {
      me = SupabaseService.client.auth.currentUser?.id;
    } catch (_) {}
    final rows = [
      if (res is List)
        for (final raw in res)
          if (raw is Map)
            LeaderboardEntry(
              rank: 0,
              id: raw['is_me'] == true && me != null ? me : 'rank_${raw['rank']}',
              name: raw['display_name']?.toString() ?? 'লাইনম্যান',
              district: raw['district']?.toString() ?? 'পশ্চিমবঙ্গ',
              points: (raw['points'] as num?)?.toInt() ?? 0,
              level: 1,
            ),
    ];
    return _ranked(rows.take(_boardSize).toList());
  }
}

final leaderboardSourceProvider = Provider<LeaderboardSource>((ref) => const LeaderboardSource());

const _boardCacheKey = 'leaderboard_cache_v1';

Map<String, dynamic> _entryToJson(LeaderboardEntry e) => {
      'id': e.id,
      'name': e.name,
      'district': e.district,
      'points': e.points,
      'level': e.level,
      if (e.avatarUrl != null) 'avatar_url': e.avatarUrl,
    };

LeaderboardEntry _entryFromJson(Map<String, dynamic> m) => LeaderboardEntry(
      rank: 0,
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? 'লাইনম্যান',
      district: m['district']?.toString() ?? 'পশ্চিমবঙ্গ',
      points: (m['points'] as num?)?.toInt() ?? 0,
      level: (m['level'] as num?)?.toInt() ?? 1,
      avatarUrl: m['avatar_url']?.toString(),
    );

/// Last real board seen on this phone, with when it was fetched.
class LeaderboardCache {
  static Future<void> save(List<LeaderboardEntry> rows, DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _boardCacheKey,
        jsonEncode({'at': at.toIso8601String(), 'rows': [for (final e in rows) _entryToJson(e)]}),
      );
    } catch (_) {}
  }

  static Future<({List<LeaderboardEntry> rows, DateTime at})?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_boardCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(decoded['at']?.toString() ?? '');
      final list = decoded['rows'];
      if (at == null || list is! List) return null;
      return (
        rows: _ranked([for (final m in list) if (m is Map) _entryFromJson(Map<String, dynamic>.from(m))]),
        at: at,
      );
    } catch (_) {
      return null;
    }
  }
}

/// How long a fetched board is reused while the app runs. Opening Rank again
/// inside this window costs no network; a finished hourly quiz invalidates it.
const leaderboardFreshFor = Duration(minutes: 5);

/// The old hourly-quiz points board (design preview only). The Rank screen
/// shows the level-clear league instead (`rank/league_board.dart`).
/// Offline it shows the last real board saved on this
/// phone; with no saved board it fails at once (no automatic retry, which
/// would keep a skeleton up for ~40 s), so the screen shows its offline state.
/// A live board is kept for [leaderboardFreshFor] after the last visit, so
/// tab hopping does not refetch; the cached offline fallback is not kept, so
/// the next visit tries the network again. Never makes up people or points.
final liveLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>(retry: (_, _) => null, (ref) async {
  try {
    final rows = await ref.read(leaderboardSourceProvider).fetch();
    unawaited(LeaderboardCache.save(rows, DateTime.now()));
    final link = ref.keepAlive();
    final expire = Timer(leaderboardFreshFor, link.close);
    ref.onDispose(expire.cancel);
    return rows;
  } catch (_) {
    final saved = await LeaderboardCache.load();
    if (saved == null || saved.rows.isEmpty) rethrow;
    return saved.rows;
  }
});
