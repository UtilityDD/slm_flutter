import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/supabase_service.dart';
import '../game/game_save.dart';
import '../game/level_result_parts.dart' show kLessonPassMark;

// "মাসিক লাইনম্যান লিগ" (docs/LEAGUE.md). Only level clears count: every
// finished play is sent to `submit_level_result` (supabase/league.sql), which
// keeps the best per rung per month (India time) and the best ever. Offline,
// plays wait in SharedPreferences and go on the next app start or next play.
// Lucky-toolbox coins, the hourly quiz and guest play never count.

/// Valid rung ids (same pattern as the server).
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

/// League points of one play: stars × 10, −5 per deadly death, never below 0.
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
  });

  final String userId;

  /// `YYYY-MM` in India time when the play finished.
  final String month;
  final String rungId;
  final int stars;
  final int deaths;

  int get points => leaguePointsFor(stars, deaths: deaths);

  /// True when this play beats [other] (more points, or as many with more stars).
  bool beats(LeagueResult other) =>
      points > other.points || (points == other.points && stars > other.stars);

  bool sameSlot(LeagueResult o) => o.userId == userId && o.month == month && o.rungId == rungId;

  Map<String, dynamic> toJson() => {'u': userId, 'm': month, 'r': rungId, 's': stars, 'd': deaths};

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
    );
  }
}

/// Sends one result to the server.
abstract class LeagueSubmitter {
  /// Null when the server took it; the server's reason when it refused it
  /// (not verified, blocked, …: the play is dropped). Throws when the network
  /// failed, so the play stays queued.
  Future<String?> submit(LeagueResult r);
}

class SupabaseLeagueSubmitter implements LeagueSubmitter {
  const SupabaseLeagueSubmitter();

  @override
  Future<String?> submit(LeagueResult r) async {
    final res = await SupabaseService.client.rpc(
      'submit_level_result',
      params: {'p_rung_id': r.rungId, 'p_stars': r.stars, 'p_deaths': r.deaths},
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

/// Queues finished plays and sends them, best per rung, fire-and-forget.
class LeagueService {
  LeagueService({
    this.submitter = const SupabaseLeagueSubmitter(),
    this.userId = _supabaseUserId,
    this.clock = DateTime.now,
  });

  final LeagueSubmitter submitter;

  /// The signed-in account, or null for a guest.
  final String? Function() userId;
  final DateTime Function() clock;

  static LeagueService instance = LeagueService();

  /// Wires the league to finished plays and sends what waited offline once
  /// the saved sign-in is restored. Called once from `main.dart`.
  static void install() {
    GameSaveController.onPlayResult = (rungId, {stars, mark}) =>
        instance.recordPlay(rungId, stars: stars ?? (mark == null ? 0 : leagueStarsForLearnMark(mark)));
    unawaited(SupabaseService.ready.then((ok) {
      if (ok) unawaited(instance.flush());
    }));
  }

  Future<void> _lock = Future.value();

  /// Runs [job] after every earlier queue job (no lost writes).
  Future<T> _serial<T>(Future<T> Function() job) {
    final next = _lock.then((_) => job());
    _lock = next.then((_) {}, onError: (_) {});
    return next;
  }

  /// A play finished. Guests and plays with no stars are ignored. Never throws.
  Future<void> recordPlay(String rungId, {required int stars, int deaths = 0}) async {
    try {
      final uid = userId();
      if (uid == null || uid.isEmpty || !isLeagueRungId(rungId) || stars <= 0) return;
      final play = LeagueResult(
        userId: uid,
        month: leagueMonthKey(clock()),
        rungId: rungId,
        stars: stars.clamp(0, 3),
        deaths: deaths.clamp(0, 10),
      );
      await _serial(() async {
        final q = await _load();
        final i = q.indexWhere(play.sameSlot);
        if (i < 0) {
          q.add(play);
        } else if (play.beats(q[i])) {
          q[i] = play;
        } else {
          return;
        }
        await _save(q);
      });
      await flush();
    } catch (_) {}
  }

  /// Sends everything queued for the signed-in member this month. Plays of an
  /// earlier month or another account are dropped (the server would count
  /// them in the wrong month or for the wrong person). Stops at the first
  /// network failure and keeps the rest. Never throws.
  Future<void> flush() async {
    try {
      await _serial(() async {
        final q = await _load();
        if (q.isEmpty) return;
        final uid = userId();
        if (uid == null || uid.isEmpty) return;
        final month = leagueMonthKey(clock());
        final pending = [for (final r in q) if (r.userId == uid && r.month == month) r];
        final left = <LeagueResult>[];
        var offline = false;
        for (final r in pending) {
          if (offline) {
            left.add(r);
            continue;
          }
          try {
            await submitter.submit(r);
          } catch (_) {
            offline = true;
            left.add(r);
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
}
