import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<DeathLogEntry> deathLog;
  final List<String> promises;
  final List<String> ppeOwned;
  final List<String> giftsClaimed;
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
    required this.deathLog,
    required this.promises,
    required this.ppeOwned,
    required this.giftsClaimed,
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
    List<DeathLogEntry>? deathLog,
    List<String>? promises,
    List<String>? ppeOwned,
    List<String>? giftsClaimed,
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
      deathLog: deathLog ?? this.deathLog,
      promises: promises ?? this.promises,
      ppeOwned: ppeOwned ?? this.ppeOwned,
      giftsClaimed: giftsClaimed ?? this.giftsClaimed,
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
        'deathLog': [for (final e in deathLog) e.toJson()],
        'promises': promises,
        'ppeOwned': ppeOwned,
        'giftsClaimed': giftsClaimed,
        'migratedFromDs': migratedFromDs,
      };

  factory GameSave.fromJson(Map<String, dynamic> json) {
    final progressRaw = json['rungProgress'];
    final bestRaw = json['bestByRung'];
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
      migratedFromDs: json['migratedFromDs'] as bool? ?? false,
    );
  }
}

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

  const DeathPulse({
    required this.deathCount,
    required this.cause,
    required this.moduleFirstRungId,
    required this.atMs,
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
    lastDeathPulse = DeathPulse(
      deathCount: nextDeaths,
      cause: cause,
      moduleFirstRungId: moduleFirstRungId,
      atMs: atMs,
    );
    state = state.copyWith(
      deaths: nextDeaths,
      safeStreak: 0,
      deathLog: log,
      currentRungId: moduleFirstRungId,
    );
    await _persist();
  }

  Future<void> markRungCleared(String rungId, {int? score}) async {
    final progress = Map<String, String>.from(state.rungProgress)..[rungId] = 'cleared';
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

  Future<void> addPromise(String id) async {
    if (state.promises.contains(id)) return;
    state = state.copyWith(promises: [...state.promises, id]);
    await _persist();
  }
}

final gameSaveProvider = NotifierProvider<GameSaveController, GameSave>(GameSaveController.new);
