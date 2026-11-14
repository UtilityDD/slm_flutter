import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/supabase_service.dart';
import '../game/game_save.dart';
import '../game/level_result_parts.dart' show kLessonPassMark;

// "মাসিক লাইনম্যান লিগ" (docs/LEAGUE.md). Only level clears count. A play is
// sent only when it beats this phone's known best stars for that rung this
// month; sends are batched (at most one batch every 30 s, and when the app
// goes to the background) to `slm_app.submit_level_results`
// (supabase/slm_app_10_league.sql), which merges the stars into the player's
// one monthly row and one all-time row. Offline, plays wait in
// SharedPreferences and go with the next batch.
// Lucky-toolbox coins, the hourly quiz and guest play never count.

/// Valid rung ids (the server also checks them against `slm_app.league_rungs`).
final RegExp leagueRungPattern = RegExp(r'^[0-9]+\.[0-9]+/(learn|do/[0-9])$|^m[0-9]+/gate$');

bool isLeagueRungId(String id) => leagueRungPattern.hasMatch(id);

/// Now in India (UTC+5:30, no daylight saving), as a plain date-time.
DateTime leagueNow([DateTime? utcNow]) =>
    (utcNow ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30));

/// League month key `YYYY-MM` of [utcNow] in India time.
String leagueMonthKey([DateTime? utcNow]) {
  final t = leagueNow(utcNow);
  return '${t.year}-${t.month.toString().padLeft(2, '0')}';
}

/// League points of one rung: stars × 10, −5 per deadly death, never below 0.
int leaguePointsFor(int stars, {int deaths = 0}) {
  final p = stars.clamp(0, 3) * 10 - deaths.clamp(0, 10) * 5;
  return p < 0 ? 0 : p;
}

/// A Learn rung has no stars in the game; its mark gives them for the league:
/// below the pass mark 0, a pass 1, 80 % or more 2, a clean 100 % 3.
int leagueStarsForLearnMark(int mark) {
  if (mark < kLessonPassMark) return 0;
  if (mark >= 100) return 3;
  if (mark >= 80) return 2;
  return 1;
}

const _bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];
const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "নভেম্বর 2026" (English digits, project rule) or "November 2026".
String leagueMonthLabel(int year, int month, {bool bn = true}) =>
    '${(bn ? _bnMonths : _enMonths)[(month - 1).clamp(0, 11)]} $year';

/// The board name when the member hides it: "লাইনম্যান #" and the last 4 of
/// the SLM id (spaces removed), or of the account id. Matches the server.
String leagueMaskedName({String? slmId, required String id}) {
  final slm = (slmId ?? '').replaceAll(RegExp(r'\s'), '');
  final src = slm.isNotEmpty ? slm : id.replaceAll('-', '');
  final tail = src.length <= 4 ? src : src.substring(src.length - 4);
  return 'লাইনম্যান #$tail';
}

/// One play waiting to be sent.
@immutable
class LeagueResult {
  const LeagueResult({
    required this.userId,
    required this.month,
    required this.rungId,
    required this.stars,
    this.deaths = 0,
    this.ms = 0,
  });

  final String userId;

  /// `YYYY-MM` in India time when the play finished.
  final String month;
  final String rungId;
  final int stars;
  final int deaths;

  /// Time the play took, level start to result (the server refuses plays
  /// faster than the rung's `min_ms`).
  final int ms;

  int get points => leaguePointsFor(stars, deaths: deaths);

  /// True when this play beats [other]: the server keeps the best stars per rung.
  bool beats(LeagueResult other) => stars > other.stars;

  bool sameSlot(LeagueResult o) => o.userId == userId && o.month == month && o.rungId == rungId;

  /// One item of `submit_level_results(p_items)`.
  Map<String, dynamic> toItem() => {'rung_id': rungId, 'stars': stars, 'deaths': deaths, 'ms': ms};

  Map<String, dynamic> toJson() => {'u': userId, 'm': month, 'r': rungId, 's': stars, 'd': deaths, 't': ms};

  static LeagueResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final u = raw['u']?.toString() ?? '';
    final m = raw['m']?.toString() ?? '';
    final r = raw['r']?.toString() ?? '';
    if (u.isEmpty || m.isEmpty || !isLeagueRungId(r)) return null;
    return LeagueResult(
      userId: u,
      month: m,
      rungId: r,
      stars: ((raw['s'] as num?)?.toInt() ?? 0).clamp(0, 3),
      deaths: ((raw['d'] as num?)?.toInt() ?? 0).clamp(0, 10),
      ms: ((raw['t'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
    );
  }
}

/// Sends one batch to the server.
abstract class LeagueSubmitter {
  /// Null when the server took the batch (single items it refused, e.g. too
  /// fast, are dropped too); the server's reason when it refused the whole
  /// batch (not verified, blocked, …: the plays are dropped). Throws when the
  /// network failed, so the plays stay queued.
  Future<String?> submit(List<LeagueResult> batch);
}

class SupabaseLeagueSubmitter implements LeagueSubmitter {
  const SupabaseLeagueSubmitter();

  @override
  Future<String?> submit(List<LeagueResult> batch) async {
    final res = await SupabaseService.client.schema('slm_app').rpc(
      'submit_level_results',
      params: {'p_items': [for (final r in batch) r.toItem()]},
    );
    if (res is Map && res['success'] == true) return null;
    if (res is Map) return res['reason']?.toString() ?? 'refused';
    return 'refused';
  }
}

String? _supabaseUserId() {
  try {
    if (!SupabaseService.hasClient) return null;
    return SupabaseService.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

const leagueQueueKey = 'league_queue_v1';

/// Best stars per rung this phone already queued or sent, for one account and
/// one month: `{"u": id, "m": "YYYY-MM", "b": {rungId: stars}}`.
const leagueKnownKey = 'league_known_v1';

/// The server takes at most 50 items per call.
const leagueBatchMax = 50;

/// Queues improving plays and sends them in batches, fire-and-forget.
class LeagueService {
  LeagueService({
    this.submitter = const SupabaseLeagueSubmitter(),
    this.userId = _supabaseUserId,
    this.clock = DateTime.now,
    this.flushEvery = const Duration(seconds: 30),
  });

  final LeagueSubmitter submitter;

  /// The signed-in account, or null for a guest.
  final String? Function() userId;
  final DateTime Function() clock;

  /// At most one automatic batch per this long.
  final Duration flushEvery;

  static LeagueService instance = LeagueService();
  static AppLifecycleListener? _lifecycle;

  /// Wires the league to finished plays, sends what waited offline once the
  /// saved sign-in is restored, and sends the queue when the app goes to the
  /// background. Called once from `main.dart`.
  static void install() {
    GameSaveController.onPlayResult = (rungId, {stars, mark, ms}) => instance.recordPlay(
          rungId,
          stars: stars ?? (mark == null ? 0 : leagueStarsForLearnMark(mark)),
          ms: ms ?? 0,
        );
    _lifecycle ??= AppLifecycleListener(onHide: () => unawaited(instance.flush()));
    unawaited(SupabaseService.ready.then((ok) {
      if (ok) unawaited(instance.flush());
    }));
  }

  Future<void> _lock = Future.value();
  DateTime? _lastFlush;
  Timer? _timer;

  /// Runs [job] after every earlier queue job (no lost writes).
  Future<T> _serial<T>(Future<T> Function() job) {
    final next = _lock.then((_) => job());
    _lock = next.then((_) {}, onError: (_) {});
    return next;
  }

  /// True while a throttled batch is waiting for its turn (tests).
  bool get flushScheduled => _timer != null;

  /// Cancels a waiting batch timer (tests).
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// A play finished. Queued only when it beats this phone's best stars for
  /// the rung this month; guests and plays with no stars are ignored. The
  /// batch goes at once if none went in the last [flushEvery], else when that
  /// time is up. Never throws.
  Future<void> recordPlay(String rungId, {required int stars, int deaths = 0, int ms = 0}) async {
    try {
      final uid = userId();
      if (uid == null || uid.isEmpty || !isLeagueRungId(rungId) || stars <= 0) return;
      final play = LeagueResult(
        userId: uid,
        month: leagueMonthKey(clock()),
        rungId: rungId,
        stars: stars.clamp(0, 3),
        deaths: deaths.clamp(0, 10),
        ms: ms < 0 ? 0 : ms,
      );
      final queued = await _serial(() async {
        final known = await _loadKnown(uid, play.month);
        if (play.stars <= (known[rungId] ?? 0)) return false;
        final q = await _load();
        final i = q.indexWhere(play.sameSlot);
        if (i < 0) {
          q.add(play);
        } else {
          q[i] = play;
        }
        await _save(q);
        known[rungId] = play.stars;
        await _saveKnown(uid, play.month, known);
        return true;
      });
      if (queued) _scheduleFlush();
    } catch (_) {}
  }

  void _scheduleFlush() {
    if (_timer != null) return;
    final last = _lastFlush;
    final wait = last == null ? Duration.zero : flushEvery - clock().difference(last);
    if (wait <= Duration.zero) {
      unawaited(flush());
      return;
    }
    _timer = Timer(wait, () {
      _timer = null;
      unawaited(flush());
    });
  }

  /// Sends everything queued for the signed-in member this month, in batches
  /// of at most [leagueBatchMax]. Plays of an earlier month or another
  /// account are dropped (the server would count them in the wrong month or
  /// for the wrong person). Stops at the first network failure and keeps the
  /// rest. Never throws.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    try {
      await _serial(() async {
        final q = await _load();
        if (q.isEmpty) return;
        final uid = userId();
        if (uid == null || uid.isEmpty) return;
        final month = leagueMonthKey(clock());
        final pending = [for (final r in q) if (r.userId == uid && r.month == month) r];
        final left = <LeagueResult>[];
        if (pending.isNotEmpty) _lastFlush = clock();
        for (var i = 0; i < pending.length; i += leagueBatchMax) {
          final end = i + leagueBatchMax < pending.length ? i + leagueBatchMax : pending.length;
          final batch = pending.sublist(i, end);
          try {
            await submitter.submit(batch);
          } catch (_) {
            left.addAll(pending.sublist(i));
            break;
          }
        }
        await _save(left);
      });
    } catch (_) {}
  }

  /// What is waiting to be sent (tests, debugging).
  Future<List<LeagueResult>> pending() => _serial(_load);

  Future<List<LeagueResult>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(leagueQueueKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(LeagueResult.fromJson).whereType<LeagueResult>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<LeagueResult> q) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (q.isEmpty) {
        await prefs.remove(leagueQueueKey);
      } else {
        await prefs.setString(leagueQueueKey, jsonEncode([for (final r in q) r.toJson()]));
      }
    } catch (_) {}
  }

  /// Best stars per rung known for [uid] in [month] (empty for another
  /// account or month: a new month starts from zero on the server too).
  Future<Map<String, int>> _loadKnown(String uid, String month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(leagueKnownKey);
      if (raw == null || raw.isEmpty) return {};
      final m = jsonDecode(raw);
      if (m is! Map || m['u'] != uid || m['m'] != month || m['b'] is! Map) return {};
      return {
        for (final e in (m['b'] as Map).entries)
          if (e.value is num) e.key.toString(): (e.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveKnown(String uid, String month, Map<String, int> best) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(leagueKnownKey, jsonEncode({'u': uid, 'm': month, 'b': best}));
    } catch (_) {}
  }
}
