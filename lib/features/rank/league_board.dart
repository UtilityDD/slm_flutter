import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/supabase_service.dart';
import '../auth/auth_provider.dart';
import 'league_service.dart';

// Read side of the league (supabase/slm_app_10_league.sql, schema `slm_app`):
// `league_board(p_scope)` (this month), `league_board_all(p_scope)` (best
// stars ever), `my_league()` (own totals, last month, name settings),
// `my_wins()` and `set_league_show_name`. A board is reused for 15 minutes
// (also across app starts) and can be refreshed by hand at most once a
// minute. Offline the last real board seen on this phone is shown; nothing
// is invented.

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
    this.districtBn = '',
    this.deaths = 0,
    this.gapToNext = 0,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final String district;
  final String districtBn;
  final int points;

  /// Rungs cleared in this scope (month or all time).
  final int rungs;

  /// Deadly deaths counted (last tie-break).
  final int deaths;

  /// Points to reach the row above (0 at the top or when tied).
  final int gapToNext;
  final bool isMe;

  /// The district in the screen's language.
  String districtFor(bool bn) => bn && districtBn.trim().isNotEmpty ? districtBn : district;

  factory LeagueRow.fromMap(Map<String, dynamic> m) => LeagueRow(
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        name: m['display_name']?.toString() ?? m['name']?.toString() ?? 'লাইনম্যান',
        district: m['district']?.toString() ?? '',
        districtBn: m['district_bn']?.toString() ?? '',
        points: (m['points'] as num?)?.toInt() ?? 0,
        rungs: (m['rungs'] as num?)?.toInt() ?? 0,
        deaths: (m['deaths'] as num?)?.toInt() ?? 0,
        gapToNext: (m['gap_to_next'] as num?)?.toInt() ?? 0,
        isMe: m['is_me'] == true,
      );

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'display_name': name,
        'district': district,
        'district_bn': districtBn,
        'points': points,
        'rungs': rungs,
        'deaths': deaths,
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

/// The member's own league (`slm_app.my_league()`).
@immutable
class LeagueMe {
  const LeagueMe({
    this.showName = true,
    this.nameAsked = false,
    this.points = 0,
    this.rungs = 0,
    this.allPoints = 0,
    this.lastMonth,
    this.lastMonthPoints,
    this.lastMonthRankDistrict,
    this.lastMonthRankState,
  });

  final bool showName;

  /// The one-time "বোর্ডে আপনার নাম দেখাবেন?" was answered.
  final bool nameAsked;
  final int points;
  final int rungs;
  final int allPoints;

  /// First day of the month the last-month numbers belong to.
  final DateTime? lastMonth;
  final int? lastMonthPoints;
  final int? lastMonthRankDistrict;
  final int? lastMonthRankState;

  static LeagueMe? fromMap(Object? res) {
    if (res is! Map || res['success'] != true) return null;
    int? n(String k) => (res[k] as num?)?.toInt();
    return LeagueMe(
      showName: res['show_name'] != false,
      nameAsked: res['name_asked'] == true,
      points: n('points') ?? 0,
      rungs: n('rungs_cleared') ?? 0,
      allPoints: n('all_points') ?? 0,
      lastMonth: DateTime.tryParse(res['last_month']?.toString() ?? ''),
      lastMonthPoints: n('last_month_points'),
      lastMonthRankDistrict: n('last_month_rank_district'),
      lastMonthRankState: n('last_month_rank_state'),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': true,
        'show_name': showName,
        'name_asked': nameAsked,
        'points': points,
        'rungs_cleared': rungs,
        'all_points': allPoints,
        if (lastMonth != null)
          'last_month': '${lastMonth!.year}-${lastMonth!.month.toString().padLeft(2, '0')}-01',
        'last_month_points': ?lastMonthPoints,
        'last_month_rank_district': ?lastMonthRankDistrict,
        'last_month_rank_state': ?lastMonthRankState,
      };

  LeagueMe copyWith({bool? showName, bool? nameAsked}) => LeagueMe(
        showName: showName ?? this.showName,
        nameAsked: nameAsked ?? this.nameAsked,
        points: points,
        rungs: rungs,
        allPoints: allPoints,
        lastMonth: lastMonth,
        lastMonthPoints: lastMonthPoints,
        lastMonthRankDistrict: lastMonthRankDistrict,
        lastMonthRankState: lastMonthRankState,
      );
}

/// Network side of the league. Swappable in tests.
abstract class LeagueBoardSource {
  const LeagueBoardSource();

  /// This month's board: the caller's district ([district]) or the state.
  Future<List<LeagueRow>> month({required bool district});

  /// Best stars on every rung ever.
  Future<List<LeagueRow>> allTime({required bool district});

  /// The signed-in member's own league. Throws when it cannot be read.
  Future<LeagueMe> myLeague();

  /// The signed-in member's monthly top-3 finishes.
  Future<List<LeagueWin>> myWins();

  /// Saves "show my name" (and marks the one-time question answered).
  /// True when the server took it.
  Future<bool> setShowName(bool value);
}

List<LeagueRow> _rows(Object? res) => [
      if (res is List)
        for (final m in res)
          if (m is Map) LeagueRow.fromMap(Map<String, dynamic>.from(m)),
    ];

class SupabaseLeagueBoardSource extends LeagueBoardSource {
  const SupabaseLeagueBoardSource();

  @override
  Future<List<LeagueRow>> month({required bool district}) async {
    final res = await SupabaseService.client
        .schema('slm_app')
        .rpc('league_board', params: {'p_scope': district ? 'district' : 'state'});
    return _rows(res);
  }

  @override
  Future<List<LeagueRow>> allTime({required bool district}) async {
    final res = await SupabaseService.client
        .schema('slm_app')
        .rpc('league_board_all', params: {'p_scope': district ? 'district' : 'state'});
    return _rows(res);
  }

  @override
  Future<LeagueMe> myLeague() async {
    final res = await SupabaseService.client.schema('slm_app').rpc('my_league');
    final me = LeagueMe.fromMap(res);
    if (me == null) throw StateError('league unavailable');
    return me;
  }

  @override
  Future<List<LeagueWin>> myWins() async {
    final res = await SupabaseService.client.schema('slm_app').rpc('my_wins');
    return [
      if (res is List)
        for (final m in res)
          if (m is Map) ?LeagueWin.fromMap(Map<String, dynamic>.from(m)),
    ];
  }

  @override
  Future<bool> setShowName(bool value) async {
    final res = await SupabaseService.client.schema('slm_app').rpc('set_league_show_name', params: {'p_show': value});
    return res is Map && res['success'] == true;
  }
}

final leagueBoardSourceProvider = Provider<LeagueBoardSource>((ref) => const SupabaseLeagueBoardSource());

/// The clock of the board cache. Swappable in tests.
final leagueClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Which board: this month's or all-time; the member's district or the state.
typedef LeagueQuery = ({bool allTime, bool district});

/// How long a fetched board (or my_league) is reused, also across app starts.
const leagueFreshFor = Duration(minutes: 15);

/// A pull-to-refresh asks the server again at most this often per board.
const leagueRefreshEvery = Duration(minutes: 1);

String _account(Ref ref) {
  final auth = ref.watch(authProvider.select((a) => (a.isAuthenticated, a.profile?.id, a.profile?.isGuest)));
  final (signedIn, id, guest) = auth;
  return signedIn && id != null && guest != true ? id : 'guest';
}

String _cacheKey(LeagueQuery q, String account, String monthKey) =>
    'league_board_cache_v2|$account|${q.allTime ? 'all' : monthKey}|${q.district ? 'district' : 'state'}';

/// When each board was last asked from the server in this app run.
final _askedAt = <String, DateTime>{};

/// Boards whose next build must ask the server (a manual refresh).
final _forced = <String>{};

/// One board. A copy saved less than [leagueFreshFor] ago is used without
/// asking the server; offline any saved copy of the same board is shown;
/// with none it fails at once so the screen shows its offline state.
final leagueBoardProvider =
    FutureProvider.autoDispose.family<List<LeagueRow>, LeagueQuery>(retry: (_, _) => null, (ref, q) async {
  final now = ref.read(leagueClockProvider)();
  final key = _cacheKey(q, _account(ref), leagueMonthKey(now));
  final link = ref.keepAlive();
  final expire = Timer(leagueFreshFor, link.close);
  ref.onDispose(expire.cancel);

  final saved = await _loadRows(key);
  final forced = _forced.remove(key);
  if (!forced && saved != null && now.difference(saved.at).abs() < leagueFreshFor) return saved.rows;

  final source = ref.read(leagueBoardSourceProvider);
  try {
    _askedAt[key] = now;
    final rows = q.allTime ? await source.allTime(district: q.district) : await source.month(district: q.district);
    await _saveRows(key, rows, now);
    return rows;
  } catch (_) {
    link.close();
    if (saved == null) rethrow;
    return saved.rows;
  }
});

/// Asks the server again for [q], unless it was asked less than
/// [leagueRefreshEvery] ago. Returns true when a new request was made.
Future<bool> refreshLeagueBoard(WidgetRef ref, LeagueQuery q) async {
  final now = ref.read(leagueClockProvider)();
  final auth = ref.read(authProvider);
  final p = auth.profile;
  final account = auth.isAuthenticated && p != null && !p.isGuest ? p.id : 'guest';
  final key = _cacheKey(q, account, leagueMonthKey(now));
  final last = _askedAt[key];
  if (last != null && now.difference(last).abs() < leagueRefreshEvery) return false;
  _forced.add(key);
  ref.invalidate(leagueBoardProvider(q));
  try {
    await ref.read(leagueBoardProvider(q).future);
  } catch (_) {}
  return true;
}

/// Forgets the in-memory request times (tests).
@visibleForTesting
void resetLeagueBoardMemory() {
  _askedAt.clear();
  _forced.clear();
}

Future<void> _saveRows(String key, List<LeagueRow> rows, DateTime at) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({'at': at.millisecondsSinceEpoch, 'rows': [for (final r in rows) r.toJson()]}),
    );
  } catch (_) {}
}

Future<({DateTime at, List<LeagueRow> rows})?> _loadRows(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final m = jsonDecode(raw);
    if (m is! Map) return null;
    return (
      at: DateTime.fromMillisecondsSinceEpoch((m['at'] as num?)?.toInt() ?? 0),
      rows: _rows(m['rows']),
    );
  } catch (_) {
    return null;
  }
}

const _meCacheKey = 'league_me_cache_v1';

/// The signed-in member's own league (`my_league()`), reused for
/// [leagueFreshFor]; offline the last copy for the same account. Null for
/// guests, or when it was never read.
final myLeagueProvider = FutureProvider.autoDispose<LeagueMe?>(retry: (_, _) => null, (ref) async {
  final account = _account(ref);
  if (account == 'guest') return null;
  final now = ref.read(leagueClockProvider)();
  final key = '$_meCacheKey|$account';
  final link = ref.keepAlive();
  final expire = Timer(leagueFreshFor, link.close);
  ref.onDispose(expire.cancel);
  Map? saved;
  try {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    saved = raw == null ? null : jsonDecode(raw) as Map?;
  } catch (_) {}
  final savedAt = DateTime.fromMillisecondsSinceEpoch((saved?['at'] as num?)?.toInt() ?? 0);
  if (saved != null && now.difference(savedAt).abs() < leagueFreshFor) return LeagueMe.fromMap(saved['me']);
  try {
    final me = await ref.read(leagueBoardSourceProvider).myLeague();
    await _saveMe(key, me, now);
    return me;
  } catch (_) {
    link.close();
    return saved == null ? null : LeagueMe.fromMap(saved['me']);
  }
});

Future<void> _saveMe(String key, LeagueMe me, DateTime at) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode({'at': at.millisecondsSinceEpoch, 'me': me.toJson()}));
  } catch (_) {}
}

/// Updates the saved my_league copy after the member changed a setting.
Future<void> _patchSavedMe(String account, LeagueMe Function(LeagueMe) change) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_meCacheKey|$account';
    final raw = prefs.getString(key);
    if (raw == null) return;
    final saved = jsonDecode(raw) as Map;
    final me = LeagueMe.fromMap(saved['me']);
    if (me == null) return;
    await prefs.setString(key, jsonEncode({'at': saved['at'], 'me': change(me).toJson()}));
  } catch (_) {}
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

const _showNameCacheKey = 'league_show_name_v1';

/// The signed-in member's "বোর্ডে আমার নাম দেখান" choice, from
/// `slm_app.my_league` (not a profiles column). True for guests and while
/// unknown; offline the last value saved for the same account.
class LeagueShowNameNotifier extends AsyncNotifier<bool> {
  String? _account() {
    final auth = ref.read(authProvider);
    final p = auth.profile;
    if (!auth.isAuthenticated || p == null || p.isGuest) return null;
    return p.id;
  }

  @override
  Future<bool> build() async {
    ref.watch(authProvider.select((a) => (a.isAuthenticated, a.profile?.id)));
    final id = _account();
    if (id == null) return true;
    final key = '$_showNameCacheKey|$id';
    final me = await ref.watch(myLeagueProvider.future).catchError((_) => null);
    if (me != null) {
      unawaited(_saveShowName(key, me.showName));
      return me.showName;
    }
    return await _loadShowName(key) ?? true;
  }

  /// Saves [value] on the server first; the switch changes only if it took it.
  /// The server also marks the one-time name question as answered.
  Future<bool> set(bool value) async {
    final id = _account();
    if (id == null) return false;
    try {
      if (!await ref.read(leagueBoardSourceProvider).setShowName(value)) return false;
    } catch (_) {
      return false;
    }
    state = AsyncData(value);
    await _saveShowName('$_showNameCacheKey|$id', value);
    await _patchSavedMe(id, (me) => me.copyWith(showName: value, nameAsked: true));
    return true;
  }
}

final leagueShowNameProvider =
    AsyncNotifierProvider<LeagueShowNameNotifier, bool>(LeagueShowNameNotifier.new, retry: (_, _) => null);

Future<void> _saveShowName(String key, bool value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  } catch (_) {}
}

Future<bool?> _loadShowName(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  } catch (_) {
    return null;
  }
}

/// `YYYY-MM` of the month in which the member last opened the Rank screen.
const leagueSeenMonthKey = 'league_seen_month_v1';

/// The month the Rank screen was last opened (null: never). The Home "new
/// month" chip shows until it is opened in the new month.
class LeagueSeenMonthNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    try {
      return (await SharedPreferences.getInstance()).getString(leagueSeenMonthKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> markSeen(String monthKey) async {
    if (state.value == monthKey) return;
    state = AsyncData(monthKey);
    try {
      await (await SharedPreferences.getInstance()).setString(leagueSeenMonthKey, monthKey);
    } catch (_) {}
  }
}

final leagueSeenMonthProvider =
    AsyncNotifierProvider<LeagueSeenMonthNotifier, String?>(LeagueSeenMonthNotifier.new, retry: (_, _) => null);

/// The Home chip "নতুন মাস, নতুন লিগ · গত মাসে জেলায় #k": in the first 7
/// days of a month, until the Rank screen is opened that month, for a member
/// who scored last month. [show] says whether the chip shows; [rank] is last
/// month's district rank (null: not ranked).
({bool show, int? rank}) leagueNewMonthChip({required LeagueMe? me, required String? seenMonth, required DateTime now}) {
  const hidden = (show: false, rank: null);
  if (me == null) return hidden;
  final india = leagueNow(now);
  if (india.day > 7) return hidden;
  final monthKey = leagueMonthKey(now);
  if (seenMonth == monthKey) return hidden;
  final last = me.lastMonth;
  final prev = DateTime(india.year, india.month - 1);
  if (last == null || last.year != prev.year || last.month != prev.month) return hidden;
  if ((me.lastMonthPoints ?? 0) <= 0) return hidden;
  return (show: true, rank: me.lastMonthRankDistrict);
}
