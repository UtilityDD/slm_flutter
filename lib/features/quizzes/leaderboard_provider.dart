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
      name: map['full_name']?.toString() ?? map['slm_id']?.toString() ?? 'লাইনম্যান',
      district: map['district']?.toString() ?? 'পশ্চিমবঙ্গ',
      points: (map['points'] as num?)?.toInt() ?? 0,
      level: (map['training_level'] as num?)?.toInt() ?? 1,
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}

/// Which of [ids] are blocked. Asks only about the rows on the board, not
/// every blocked account.
Future<Set<String>> _blockedAmong(List<String> ids) async {
  if (ids.isEmpty) return {};
  final rows = await SupabaseService.client.from('profiles').select('id').inFilter('id', ids).eq('blocked', true);
  return {
    for (final raw in rows)
      if ((raw['id']?.toString() ?? '').isNotEmpty) raw['id'].toString(),
  };
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
class LeaderboardSource {
  const LeaderboardSource();

  Future<List<LeaderboardEntry>> fetch() async {
    final now = DateTime.now();
    try {
      // The view has no blocked flag, so read a few spare rows and drop
      // blocked ones before cutting to the board size.
      final monthlyData = await SupabaseService.client
          .from('monthly_leaderboard_view')
          .select('user_id, full_name, district, points, avatar_url')
          .eq('year_num', now.year)
          .eq('month_num', now.month)
          .order('points', ascending: false)
          .limit(_boardSize * 2);

      if (monthlyData.isNotEmpty) {
        final hidden = await _blockedAmong([
          for (final row in monthlyData)
            if ((row['user_id']?.toString() ?? '').isNotEmpty) row['user_id'].toString(),
        ]);
        final rows = [
          for (final row in monthlyData)
            if (!hidden.contains(row['user_id']?.toString() ?? ''))
              LeaderboardEntry(
                rank: 0,
                id: row['user_id']?.toString() ?? '',
                name: row['full_name']?.toString() ?? 'লাইনম্যান',
                district: row['district']?.toString() ?? 'পশ্চিমবঙ্গ',
                points: (row['points'] as num?)?.toInt() ?? 0,
                level: 1,
                avatarUrl: row['avatar_url']?.toString(),
              ),
        ];
        if (rows.isNotEmpty) return _ranked(rows.take(_boardSize).toList());
      }
    } catch (_) {
      // Fall back to the profiles table if the view is missing or different.
    }

    // Blocked accounts are filtered on the server, before the limit.
    final profileData = await SupabaseService.client
        .from('profiles')
        .select('id, full_name, slm_id, district, points, training_level, avatar_url')
        .eq('blocked', false)
        .order('points', ascending: false)
        .limit(_boardSize);

    return _ranked([for (final row in profileData) LeaderboardEntry.fromMap(row, 0)]);
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

/// The monthly board. Offline it shows the last real board saved on this
/// phone; with no saved board it fails at once (no automatic retry, which
/// would keep a skeleton up for ~40 s), so the screen shows its offline state.
/// Auto-dispose: the next visit to Rank fetches again. Never makes up people
/// or points.
final liveLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>(retry: (_, _) => null, (ref) async {
  try {
    final rows = await ref.read(leaderboardSourceProvider).fetch();
    unawaited(LeaderboardCache.save(rows, DateTime.now()));
    return rows;
  } catch (_) {
    final saved = await LeaderboardCache.load();
    if (saved == null || saved.rows.isEmpty) rethrow;
    return saved.rows;
  }
});
