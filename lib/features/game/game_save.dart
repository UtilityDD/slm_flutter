import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lesson_promises.dart';

/// Single local economy for the climb. Backend sync later — same shapes.
@immutable
class GameSave {
  final String seasonId;
  final int points;
  final int deaths;
  final int safeStreak;
  final int rankIndex;
  final String currentRungId;
  final Map<String, String> rungProgress;
  final Map<String, int> bestByRung;

  /// Fastest clear per rung id (ms of decision time). Informational only.
  final Map<String, int> bestTimeMsByRung;

  /// Best mark (0–100 %) and finished plays per lesson-level rung id.
  final Map<String, int> bestMarkByRung;

  /// What each Learn level currently adds to [points]: the score of its
  /// latest finished play. A replay replaces it (see [GameSaveController.commitLevelScore]).
  final Map<String, int> levelScoreByRung;
  final Map<String, int> playsByRung;
  final List<DeathLogEntry> deathLog;
  final List<String> promises;
  final List<String> ppeOwned;
  final List<String> giftsClaimed;

  /// Questions the player missed on the first try, per lesson id (stable
  /// question keys: slot ids, `myth`, quiz text). A clean answer later removes
  /// one. Recall side items and later levels bring these back first.
  final Map<String, List<String>> weakByLesson;

  /// "আমার ভুলের খাতা": the latest mistake per key (newest last, capped).
  final List<MistakeEntry> mistakes;

  /// Do rungs passed since the last death. A death turns them back to
  /// 'prove' (fall option C: prove them again); Learn rungs never fall.
  final List<String> clearedSinceDeath;

  /// The first deadly mistake in the game is a near-miss (no death, no fall).
  final bool nearMissUsed;
  final bool migratedFromDs;

  const GameSave({
    required this.seasonId,
    required this.points,
    required this.deaths,
    required this.safeStreak,
    required this.rankIndex,
    required this.currentRungId,
    required this.rungProgress,
    required this.bestByRung,
    this.bestTimeMsByRung = const {},
    this.bestMarkByRung = const {},
    this.levelScoreByRung = const {},
    this.playsByRung = const {},
    required this.deathLog,
    required this.promises,
    required this.ppeOwned,
    required this.giftsClaimed,
    this.weakByLesson = const {},
    this.mistakes = const [],
    this.clearedSinceDeath = const [],
    this.nearMissUsed = false,
    required this.migratedFromDs,
  });

  static const empty = GameSave(
    seasonId: 'season-1',
    points: 0,
    deaths: 0,
    safeStreak: 0,
    rankIndex: 0,
    currentRungId: '1.1/learn',
    rungProgress: {},
    bestByRung: {},
    deathLog: [],
    promises: [],
    ppeOwned: [],
    giftsClaimed: [],
    migratedFromDs: false,
  );

  GameSave copyWith({
    String? seasonId,
    int? points,
    int? deaths,
    int? safeStreak,
    int? rankIndex,
    String? currentRungId,
    Map<String, String>? rungProgress,
    Map<String, int>? bestByRung,
    Map<String, int>? bestTimeMsByRung,
    Map<String, int>? bestMarkByRung,
    Map<String, int>? levelScoreByRung,
    Map<String, int>? playsByRung,
    List<DeathLogEntry>? deathLog,
    List<String>? promises,
    List<String>? ppeOwned,
    List<String>? giftsClaimed,
    Map<String, List<String>>? weakByLesson,
    List<MistakeEntry>? mistakes,
    List<String>? clearedSinceDeath,
    bool? nearMissUsed,
    bool? migratedFromDs,
  }) {
    return GameSave(
      seasonId: seasonId ?? this.seasonId,
      points: points ?? this.points,
      deaths: deaths ?? this.deaths,
      safeStreak: safeStreak ?? this.safeStreak,
      rankIndex: rankIndex ?? this.rankIndex,
      currentRungId: currentRungId ?? this.currentRungId,
      rungProgress: rungProgress ?? this.rungProgress,
      bestByRung: bestByRung ?? this.bestByRung,
      bestTimeMsByRung: bestTimeMsByRung ?? this.bestTimeMsByRung,
      bestMarkByRung: bestMarkByRung ?? this.bestMarkByRung,
      levelScoreByRung: levelScoreByRung ?? this.levelScoreByRung,
      playsByRung: playsByRung ?? this.playsByRung,
      deathLog: deathLog ?? this.deathLog,
      promises: promises ?? this.promises,
      ppeOwned: ppeOwned ?? this.ppeOwned,
      giftsClaimed: giftsClaimed ?? this.giftsClaimed,
      weakByLesson: weakByLesson ?? this.weakByLesson,
      mistakes: mistakes ?? this.mistakes,
      clearedSinceDeath: clearedSinceDeath ?? this.clearedSinceDeath,
      nearMissUsed: nearMissUsed ?? this.nearMissUsed,
      migratedFromDs: migratedFromDs ?? this.migratedFromDs,
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonId': seasonId,
        'points': points,
        'deaths': deaths,
        'safeStreak': safeStreak,
        'rankIndex': rankIndex,
        'currentRungId': currentRungId,
        'rungProgress': rungProgress,
        'bestByRung': bestByRung,
        'bestTimeMsByRung': bestTimeMsByRung,
        'bestMarkByRung': bestMarkByRung,
        'levelScoreByRung': levelScoreByRung,
        'playsByRung': playsByRung,
        'deathLog': [for (final e in deathLog) e.toJson()],
        'promises': promises,
        'ppeOwned': ppeOwned,
        'giftsClaimed': giftsClaimed,
        'weakByLesson': weakByLesson,
        'mistakes': [for (final m in mistakes) m.toJson()],
        'clearedSinceDeath': clearedSinceDeath,
        'nearMissUsed': nearMissUsed,
        'migratedFromDs': migratedFromDs,
      };

  factory GameSave.fromJson(Map<String, dynamic> json) {
    final progressRaw = json['rungProgress'];
    final bestRaw = json['bestByRung'];
    final timeRaw = json['bestTimeMsByRung'];
    Map<String, int> ints(Object? raw) => {
          if (raw is Map)
            for (final e in raw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
        };
    return GameSave(
      seasonId: json['seasonId'] as String? ?? 'season-1',
      points: (json['points'] as num?)?.toInt() ?? 0,
      deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      safeStreak: (json['safeStreak'] as num?)?.toInt() ?? 0,
      rankIndex: (json['rankIndex'] as num?)?.toInt() ?? 0,
      currentRungId: json['currentRungId'] as String? ?? '1.1/learn',
      rungProgress: {
        if (progressRaw is Map)
          for (final e in progressRaw.entries) e.key.toString(): e.value.toString(),
      },
      bestByRung: {
        if (bestRaw is Map)
          for (final e in bestRaw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
      },
      bestTimeMsByRung: {
        if (timeRaw is Map)
          for (final e in timeRaw.entries) e.key.toString(): (e.value as num?)?.toInt() ?? 0,
      },
      bestMarkByRung: ints(json['bestMarkByRung']),
      levelScoreByRung: ints(json['levelScoreByRung']),
      playsByRung: ints(json['playsByRung']),
      deathLog: [
        for (final raw in (json['deathLog'] as List? ?? const []))
          DeathLogEntry.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      promises: [
        for (final v in (json['promises'] as List? ?? const [])) v.toString(),
      ],
      ppeOwned: [
        for (final v in (json['ppeOwned'] as List? ?? const [])) v.toString(),
      ],
      giftsClaimed: [
        for (final v in (json['giftsClaimed'] as List? ?? const [])) v.toString(),
      ],
      mistakes: [
        for (final raw in (json['mistakes'] as List? ?? const []))
          if (raw is Map) MistakeEntry.fromJson(Map<String, dynamic>.from(raw)),
      ],
      clearedSinceDeath: [
        for (final v in (json['clearedSinceDeath'] as List? ?? const [])) v.toString(),
      ],
      nearMissUsed: json['nearMissUsed'] as bool? ?? false,
      weakByLesson: {
        if (json['weakByLesson'] is Map)
          for (final e in (json['weakByLesson'] as Map).entries)
            if (e.value is List) e.key.toString(): [for (final v in e.value as List) v.toString()],
      },
      migratedFromDs: json['migratedFromDs'] as bool? ?? false,
    );
  }
}

/// One entry in "আমার ভুলের খাতা".
@immutable
class MistakeEntry {
  const MistakeEntry({
    required this.key,
    required this.lessonId,
    required this.rungId,
    required this.textBn,
    required this.deadly,
    required this.atMs,
    this.lessonPoint,
    this.count = 1,
  });

  /// Stable id of the mistake, e.g. `1.5/discharge/line-before-earth`.
  final String key;
  final String lessonId;
  final String rungId;
  final String textBn;
  final bool deadly;
  final int atMs;

  /// Lesson point (0-based) that teaches it, for "পাঠে দেখুন".
  final int? lessonPoint;
  final int count;

  Map<String, dynamic> toJson() => {
        'key': key,
        'lessonId': lessonId,
        'rungId': rungId,
        'textBn': textBn,
        'deadly': deadly,
        'atMs': atMs,
        if (lessonPoint != null) 'lessonPoint': lessonPoint,
        'count': count,
      };

  factory MistakeEntry.fromJson(Map<String, dynamic> j) => MistakeEntry(
        key: j['key'] as String? ?? '',
        lessonId: j['lessonId'] as String? ?? '',
        rungId: j['rungId'] as String? ?? '',
        textBn: j['textBn'] as String? ?? '',
        deadly: j['deadly'] as bool? ?? false,
        atMs: (j['atMs'] as num?)?.toInt() ?? 0,
        lessonPoint: (j['lessonPoint'] as num?)?.toInt(),
        count: (j['count'] as num?)?.toInt() ?? 1,
      );
}

/// Do levels and gates (their passes fall on a death); Learn rungs do not.
bool isFallableRung(String rungId) => rungId.contains('/do/') || rungId.endsWith('/gate');

@immutable
class DeathLogEntry {
  final String cause;
  final String lessonId;
  final String rungId;
  final int atMs;

  const DeathLogEntry({
    required this.cause,
    required this.lessonId,
    required this.rungId,
    required this.atMs,
  });

  Map<String, dynamic> toJson() => {
        'cause': cause,
        'lessonId': lessonId,
        'rungId': rungId,
        'atMs': atMs,
      };

  factory DeathLogEntry.fromJson(Map<String, dynamic> json) => DeathLogEntry(
        cause: json['cause'] as String? ?? '',
        lessonId: json['lessonId'] as String? ?? '',
        rungId: json['rungId'] as String? ?? '',
        atMs: (json['atMs'] as num?)?.toInt() ?? 0,
      );
}

/// Latest score delta for HUD FX consumers (E4). Cleared after read optional.
@immutable
class ScorePulse {
  final int delta;
  final int atMs;
  final Offset? originGlobal;
  const ScorePulse(this.delta, this.atMs, {this.originGlobal});
}

/// Latest lethal death for death-moment FX (E5).
@immutable
class DeathPulse {
  final int deathCount;
  final String cause;
  final String moduleFirstRungId;
  final int atMs;

  /// The promise the player made for the lesson they just died in, if any.
  final String? promiseBn;

  const DeathPulse({
    required this.deathCount,
    required this.cause,
    required this.moduleFirstRungId,
    required this.atMs,
    this.promiseBn,
  });
}

class GameSaveController extends Notifier<GameSave> {
  static const _prefsKey = 'game_save_v1';

  ScorePulse? lastPulse;
  DeathPulse? lastDeathPulse;

  @override
  GameSave build() {
    // Load async; keep empty until hydrated.
    Future.microtask(_hydrate);
    return GameSave.empty;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = GameSave.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return;
      } catch (_) {}
    }
    await migrateFromDutySlipIfNeeded(prefs);
  }

  Future<void> migrateFromDutySlipIfNeeded(SharedPreferences prefs) async {
    if (state.migratedFromDs) return;
    final score = prefs.getInt('ds_career_score') ?? 0;
    // Legacy skull was mistake-sum; do NOT copy into lethal deaths.
    // Keep deaths at 0 until real lethal events; preserve score so home isn't wiped.
    state = state.copyWith(
      points: score > state.points ? score : state.points,
      migratedFromDs: true,
    );
    await _persist();
  }

  /// Re-read prefs after legacy Duty Slip mirrors career score into disk.
  Future<void> reloadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        state = GameSave.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      final legacy = prefs.getInt('ds_career_score') ?? 0;
      if (legacy > state.points) {
        state = state.copyWith(points: legacy, migratedFromDs: true);
        await _persist();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
      // Mirror career score for any leftover readers during transition.
      await prefs.setInt('ds_career_score', state.points);
    } catch (_) {}
  }

  Future<void> addPoints(int delta, {String? rungId, Offset? originGlobal}) async {
    if (delta == 0) return;
    final nextPoints = (state.points + delta).clamp(0, 1 << 30);
    var best = Map<String, int>.from(state.bestByRung);
    if (rungId != null && delta > 0) {
      final prev = best[rungId] ?? 0;
      if (delta > prev) best[rungId] = delta;
    }
    lastPulse = ScorePulse(
      delta,
      DateTime.now().millisecondsSinceEpoch,
      originGlobal: originGlobal,
    );
    state = state.copyWith(points: nextPoints, bestByRung: best);
    await _persist();
  }

  /// A Learn level finished with [score]: it replaces that level's previous
  /// score in [GameSave.points] (the latest play counts, not the sum of plays).
  /// Returns the change to the main ◆, which may be negative.
  Future<int> commitLevelScore(String rungId, int score, {Offset? originGlobal}) async {
    final s = score < 0 ? 0 : score;
    final prev = state.levelScoreByRung[rungId] ?? 0;
    state = state.copyWith(levelScoreByRung: {...state.levelScoreByRung, rungId: s});
    final delta = s - prev;
    if (delta == 0) {
      await _persist();
    } else {
      await addPoints(delta, rungId: rungId, originGlobal: originGlobal);
    }
    return delta;
  }

  /// Saves [ms] as the rung's best time when it beats the old one (or there is
  /// none). Returns the previous best (null = first clear) and whether it improved.
  Future<({int? previous, bool record})> recordBestTime(String rungId, int ms) async {
    final prev = state.bestTimeMsByRung[rungId];
    if (ms <= 0 || (prev != null && prev > 0 && ms >= prev)) {
      return (previous: prev, record: false);
    }
    final next = Map<String, int>.from(state.bestTimeMsByRung)..[rungId] = ms;
    state = state.copyWith(bestTimeMsByRung: next);
    await _persist();
    return (previous: prev, record: true);
  }

  /// Counts a finished play of a lesson level (passed or not) and keeps its
  /// best mark. Returns the best mark before this play (null = first play).
  Future<int?> recordLevelResult(String rungId, int percent) async {
    final prev = state.bestMarkByRung[rungId];
    final marks = Map<String, int>.from(state.bestMarkByRung);
    if (prev == null || percent > prev) marks[rungId] = percent.clamp(0, 100);
    final plays = Map<String, int>.from(state.playsByRung)
      ..[rungId] = (state.playsByRung[rungId] ?? 0) + 1;
    state = state.copyWith(bestMarkByRung: marks, playsByRung: plays);
    await _persist();
    return prev;
  }

  /// Visual-only score chip (legacy Duty Slip still owns career math during bridge).
  void pulseDelta(int delta, {Offset? originGlobal}) {
    if (delta == 0) return;
    lastPulse = ScorePulse(
      delta,
      DateTime.now().millisecondsSinceEpoch,
      originGlobal: originGlobal,
    );
    // Touch state so listeners rebuild / ScoreFlyHost can launch.
    state = state.copyWith(points: state.points);
  }

  Future<void> recordLethalDeath({
    required String cause,
    required String lessonId,
    required String rungId,
    required String moduleFirstRungId,
  }) async {
    final atMs = DateTime.now().millisecondsSinceEpoch;
    final nextDeaths = state.deaths + 1;
    final log = [
      ...state.deathLog,
      DeathLogEntry(
        cause: cause,
        lessonId: lessonId,
        rungId: rungId,
        atMs: atMs,
      ),
    ];
    final promise = lessonPromiseFor(lessonId);
    lastDeathPulse = DeathPulse(
      deathCount: nextDeaths,
      cause: cause,
      moduleFirstRungId: moduleFirstRungId,
      atMs: atMs,
      promiseBn: promise != null && state.promises.contains(promise.id) ? promise.textBn : null,
    );
    // Fall option C: every Do level passed since the last death must be
    // proven again; Learn rungs stay done.
    final progress = Map<String, String>.from(state.rungProgress);
    for (final id in state.clearedSinceDeath) {
      if (progress[id] == 'cleared') progress[id] = 'prove';
    }
    state = state.copyWith(
      deaths: nextDeaths,
      safeStreak: 0,
      deathLog: log,
      currentRungId: moduleFirstRungId,
      rungProgress: progress,
      clearedSinceDeath: const [],
    );
    await _persist();
  }

  Future<void> markRungCleared(String rungId, {int? score}) async {
    final progress = Map<String, String>.from(state.rungProgress)..[rungId] = 'cleared';
    final since = isFallableRung(rungId) && !state.clearedSinceDeath.contains(rungId)
        ? [...state.clearedSinceDeath, rungId]
        : state.clearedSinceDeath;
    final best = Map<String, int>.from(state.bestByRung);
    if (score != null) {
      final prev = best[rungId] ?? 0;
      if (score > prev) best[rungId] = score;
    }
    state = state.copyWith(
      rungProgress: progress,
      bestByRung: best,
      safeStreak: state.safeStreak + 1,
      currentRungId: rungId,
      clearedSinceDeath: since,
    );
    await _persist();
  }

  Future<void> setCurrentRung(String rungId) async {
    state = state.copyWith(currentRungId: rungId);
    await _persist();
  }

  Future<void> unlockRank(int index) async {
    if (index <= state.rankIndex) return;
    state = state.copyWith(rankIndex: index);
    await _persist();
  }

  Future<void> ownPpe(String id) async {
    if (state.ppeOwned.contains(id)) return;
    state = state.copyWith(ppeOwned: [...state.ppeOwned, id]);
    await _persist();
  }

  Future<void> claimGift(String id) async {
    if (state.giftsClaimed.contains(id)) return;
    state = state.copyWith(giftsClaimed: [...state.giftsClaimed, id]);
    await _persist();
  }

  /// Marks the one-time reward [id] as paid. Returns false when it was paid
  /// before, so the caller skips the points. Safe against double taps: the
  /// check and the mark happen before the first await.
  Future<bool> claimOnce(String id) async {
    if (state.giftsClaimed.contains(id)) return false;
    await claimGift(id);
    return true;
  }

  /// Writes a mistake into "আমার ভুলের খাতা" (one entry per key, newest last,
  /// at most 200 kept).
  Future<void> addMistake({
    required String key,
    required String lessonId,
    required String rungId,
    required String textBn,
    required bool deadly,
    int? lessonPoint,
  }) async {
    final old = state.mistakes.where((m) => m.key == key).toList();
    final entry = MistakeEntry(
      key: key,
      lessonId: lessonId,
      rungId: rungId,
      textBn: textBn,
      deadly: deadly,
      atMs: DateTime.now().millisecondsSinceEpoch,
      lessonPoint: lessonPoint,
      count: old.isEmpty ? 1 : old.first.count + 1,
    );
    final list = [for (final m in state.mistakes) if (m.key != key) m, entry];
    state = state.copyWith(mistakes: list.length > 200 ? list.sublist(list.length - 200) : list);
    await _persist();
  }

  /// True the first time only: the game's first deadly mistake is a near-miss.
  Future<bool> useNearMiss() async {
    if (state.nearMissUsed) return false;
    state = state.copyWith(nearMissUsed: true);
    await _persist();
    return true;
  }

  /// Remembers [key] as a weak spot of [lessonId] (missed on the first try),
  /// or forgets it after a clean answer. Saves only when something changed.
  Future<void> markWeak(String lessonId, String key, {required bool weak}) async {
    if (lessonId.isEmpty || key.isEmpty) return;
    final now = state.weakByLesson[lessonId] ?? const <String>[];
    if (weak == now.contains(key)) return;
    final next = Map<String, List<String>>.from(state.weakByLesson);
    final list = weak ? [...now, key] : [for (final k in now) if (k != key) k];
    if (list.isEmpty) {
      next.remove(lessonId);
    } else {
      next[lessonId] = list;
    }
    state = state.copyWith(weakByLesson: next);
    await _persist();
  }

  Future<void> addPromise(String id) async {
    if (state.promises.contains(id)) return;
    state = state.copyWith(promises: [...state.promises, id]);
    await _persist();
  }
}

final gameSaveProvider = NotifierProvider<GameSaveController, GameSave>(GameSaveController.new);
