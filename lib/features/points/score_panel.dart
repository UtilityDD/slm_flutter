import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_service.dart';
import '../auth/auth_provider.dart';
import '../quizzes/hourly_pack.dart';
import '../training/training_provider.dart';

/// Breaker state in the DB box.
enum BreakerState {
  /// কারেন্ট আছে — can earn right now.
  on,

  /// চার্জ হচ্ছে — on cooldown, opens later.
  charging,

  /// এই মাসে ফুল — nothing left to take this month.
  full,

  /// Scoring for this source is not in the app yet.
  soon,
}

enum ScoreSource { hourly, lesson, lifeSkill, gift }

class SourceMeta {
  final ScoreSource id;
  final String bn;
  final String en;
  final IconData icon;
  final Color color;

  const SourceMeta(this.id, this.bn, this.en, this.icon, this.color);
}

/// Adding a scoring source = one row here + one status rule in [_buildBreakers].
const scoreSources = [
  SourceMeta(ScoreSource.hourly, 'ঘণ্টার কুইজ', 'Hourly quiz', Icons.timer_rounded, Color(0xFF0F766E)),
  SourceMeta(ScoreSource.lesson, 'পাঠ পড়া', 'Lessons', Icons.menu_book_rounded, Color(0xFF2563EB)),
  SourceMeta(ScoreSource.lifeSkill, 'লাইফ স্কিল', 'Life skill', Icons.star_rounded, Color(0xFF7C3AED)),
  SourceMeta(ScoreSource.gift, 'গিফট বক্স', 'Gift box', Icons.card_giftcard_rounded, Color(0xFFDB2777)),
];

ScoreSource? sourceOfQuizId(String quizId) {
  final q = quizId.toLowerCase();
  if (q.startsWith('hourly-challenge')) return ScoreSource.hourly;
  if (q.startsWith('lesson_bonus')) return ScoreSource.lesson;
  if (q.startsWith('life_skill_bonus')) return ScoreSource.lifeSkill;
  if (q.startsWith('identify-')) return ScoreSource.gift;
  return null;
}

class Breaker {
  final SourceMeta meta;
  final BreakerState state;
  final String statusBn;
  final String statusEn;

  const Breaker(this.meta, this.state, this.statusBn, this.statusEn);
}

class ScorePanel {
  final bool signedIn;
  final int lifetimePoints;
  final Map<ScoreSource, int> monthBySource;
  final int monthOther;
  final int activeDays;
  final int eligibleDays;
  final List<Breaker> breakers;

  const ScorePanel({
    required this.signedIn,
    required this.lifetimePoints,
    required this.monthBySource,
    required this.monthOther,
    required this.activeDays,
    required this.eligibleDays,
    required this.breakers,
  });

  int get monthTotal => monthBySource.values.fold(0, (a, b) => a + b) + monthOther;
  double get consistency => eligibleDays == 0 ? 0 : (activeDays / eligibleDays).clamp(0, 1).toDouble();
  int get grandScore => (monthTotal * (1 + consistency)).round();
  bool get anyLive => breakers.any((b) => b.state == BreakerState.on);
}

DateTime istNow() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// IST wall-clock month start, expressed as a UTC instant for queries.
DateTime _istMonthStartUtc(DateTime ist) =>
    DateTime.utc(ist.year, ist.month, 1).subtract(const Duration(hours: 5, minutes: 30));

class _Attempt {
  final String quizId;
  final int net;
  final DateTime at;
  const _Attempt(this.quizId, this.net, this.at);
}

final scorePanelProvider = FutureProvider<ScorePanel>((ref) async {
  final auth = ref.watch(authProvider);
  final profile = auth.profile;
  final userId = auth.isAuthenticated && !auth.isGuest ? profile?.id : null;
  final now = istNow();

  final ladder = await ref.watch(trainingLadderProvider.future).catchError((_) => const <dynamic>[]);
  final lessonsLeft = ladder.any((m) => m.isActive && !m.isCompleted);

  final attempts = <_Attempt>[];
  var activeDays = 0;
  var eligibleDays = now.day;

  if (userId != null) {
    final client = SupabaseService.client;
    final since = DateTime.now().toUtc().subtract(const Duration(days: 35));
    try {
      final rows = await client
          .from('quiz_attempts')
          .select('quiz_id, score, penalty, created_at')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .limit(3000);
      for (final r in rows) {
        final score = (r['score'] as num?)?.toInt() ?? 0;
        final penalty = (r['penalty'] as num?)?.toInt() ?? 0;
        final at = DateTime.tryParse('${r['created_at']}')?.toUtc();
        if (at == null) continue;
        attempts.add(_Attempt('${r['quiz_id'] ?? ''}', score - penalty, at));
      }
    } catch (_) {}
    try {
      final days = await client
          .from('daily_user_activity')
          .select('activity_date')
          .eq('user_id', userId)
          .gte('activity_date', _ymd(DateTime(now.year, now.month, 1)));
      activeDays = days.length;
    } catch (_) {}
    try {
      final row = await client.from('profiles').select('created_at').eq('id', userId).maybeSingle();
      final joined = DateTime.tryParse('${row?['created_at']}')?.toUtc().add(const Duration(hours: 5, minutes: 30));
      if (joined != null && joined.year == now.year && joined.month == now.month) {
        eligibleDays = (now.day - joined.day + 1).clamp(1, now.day);
      }
    } catch (_) {}
  }

  final monthStart = _istMonthStartUtc(now);
  final bySource = {for (final s in ScoreSource.values) s: 0};
  var other = 0;
  for (final a in attempts) {
    if (a.at.isBefore(monthStart)) continue;
    final s = sourceOfQuizId(a.quizId);
    if (s == null) {
      other += a.net;
    } else {
      bySource[s] = bySource[s]! + a.net;
    }
  }

  return ScorePanel(
    signedIn: userId != null,
    lifetimePoints: profile?.points ?? 0,
    monthBySource: bySource,
    monthOther: other,
    activeDays: activeDays,
    eligibleDays: eligibleDays,
    breakers: _buildBreakers(
      now: now,
      userId: userId,
      attempts: attempts,
      lessonsLeft: lessonsLeft,
    ),
  );
});

List<Breaker> _buildBreakers({
  required DateTime now,
  required String? userId,
  required List<_Attempt> attempts,
  required bool lessonsLeft,
}) {
  SourceMeta meta(ScoreSource s) => scoreSources.firstWhere((m) => m.id == s);
  final minsLeft = 60 - now.minute;
  final today = _ymd(now);

  final hourId = hourlyQuizId(DateTime.now());
  final hourDone = attempts.any((a) => a.quizId == hourId);
  final hourly = userId == null
      ? Breaker(meta(ScoreSource.hourly), BreakerState.charging, 'লগইন করলে পয়েন্ট', 'Log in to earn')
      : hourDone
          ? Breaker(meta(ScoreSource.hourly), BreakerState.charging, 'পরের ঘণ্টা $minsLeft মিনিটে', 'Next in $minsLeft min')
          : Breaker(meta(ScoreSource.hourly), BreakerState.on, 'খোলা · $minsLeft মিনিট বাকি', 'Open · $minsLeft min left');

  final lesson = lessonsLeft
      ? Breaker(meta(ScoreSource.lesson), BreakerState.on, 'নতুন পাঠ বাকি · +20', 'New lesson · +20')
      : Breaker(meta(ScoreSource.lesson), BreakerState.full, 'সব পাঠ শেষ', 'All lessons done');

  final lastLife = attempts
      .where((a) => sourceOfQuizId(a.quizId) == ScoreSource.lifeSkill && a.net > 0)
      .map((a) => a.at)
      .fold<DateTime?>(null, (p, d) => p == null || d.isAfter(p) ? d : p);
  final lifeSkill = Breaker(
    meta(ScoreSource.lifeSkill),
    BreakerState.soon,
    lastLife == null ? 'অ্যাপে শীঘ্রই' : 'শেষ স্কোর ${DateTime.now().toUtc().difference(lastLife).inDays} দিন আগে',
    lastLife == null ? 'Coming to app' : 'Last scored ${DateTime.now().toUtc().difference(lastLife).inDays}d ago',
  );

  final giftToday = attempts.any((a) => a.quizId == 'identify-$today');
  final window = userId == null ? null : identifyGiftWindow(userId, now);
  final gift = giftToday
      ? Breaker(meta(ScoreSource.gift), BreakerState.full, 'আজকের উপহার নেওয়া হয়েছে', 'Today\'s gift taken')
      : Breaker(
          meta(ScoreSource.gift),
          BreakerState.soon,
          window == null ? 'অ্যাপে শীঘ্রই' : 'আজ ${window.$1}–${window.$2} · অ্যাপে শীঘ্রই',
          window == null ? 'Coming to app' : 'Today ${window.$1}–${window.$2} · coming to app',
        );

  return [hourly, lesson, lifeSkill, gift];
}

/// Same personal 3-hour window as the web gift (FNV-1a of userId + IST date, 06:00–20:00 start).
(String, String) identifyGiftWindow(String userId, DateTime ist) {
  final seed = '$userId|identify-gift|${_ymd(ist)}';
  var h = 2166136261;
  for (final c in seed.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  final t = (h % 1000000) / 1000000;
  const earliest = 6 * 60;
  const latest = 20 * 60;
  final start = earliest + (t * (latest - earliest + 1)).floor();
  final end = start + 180;
  String fmt(int m) => '${(m ~/ 60 % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  return (fmt(start), fmt(end));
}
