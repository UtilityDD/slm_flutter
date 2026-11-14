import 'dart:async';
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

  /// Best stars (1–3) earned on each rung.
  final Map<String, int> starsByRung;

  /// "ভাগ্যের টুলবক্স": keys from finished levels, pity counter, pending boosts.
  final ToolboxSave toolbox;
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
    this.starsByRung = const {},
    this.toolbox = const ToolboxSave(),
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
    Map<String, int>? starsByRung,
    ToolboxSave? toolbox,
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
      starsByRung: starsByRung ?? this.starsByRung,
      toolbox: toolbox ?? this.toolbox,
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
        'starsByRung': starsByRung,
        'toolbox': toolbox.toJson(),
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
      starsByRung: {
        if (json['starsByRung'] is Map)
          for (final e in (json['starsByRung'] as Map).entries)
            if (e.value is num) e.key.toString(): (e.value as num).toInt(),
      },
      weakByLesson: {
        if (json['weakByLesson'] is Map)
          for (final e in (json['weakByLesson'] as Map).entries)
            if (e.value is List) e.key.toString(): [for (final v in e.value as List) v.toString()],
      },
      toolbox: json['toolbox'] is Map
          ? ToolboxSave.fromJson(Map<String, dynamic>.from(json['toolbox'] as Map))
          : const ToolboxSave(),
      migratedFromDs: json['migratedFromDs'] as bool? ?? false,
    );
  }
}

/// Lucky-toolbox switches. Keys are paused (owner revising the design,
/// 2026-11-13): while [keysEnabled] is false no level earns keys and a chest
/// opens without one. Tests may flip it.
abstract final class ToolboxFlags {
  static bool keysEnabled = false;
}

/// Keys a rung's best result earns for the lucky toolbox: 1–2 stars = 1, 3 stars = 2.
int toolboxKeysForStars(int stars) => stars <= 0 ? 0 : (stars >= 3 ? 2 : 1);

/// A Learn rung has no stars: a pass = 1 key, a clean 100 % = 2 (its top result).
int toolboxKeysForLearnMark(int? mark) => (mark ?? 0) >= 100 ? 2 : 1;

/// A sudden chest ("হঠাৎ উপহার") waiting on the ladder until it is opened.
/// It drops after the first clear of [rungId] and stands beside the NEXT
/// rung; it never expires. Its one-time claim id is [claimId].
@immutable
class PendingChest {
  const PendingChest({required this.rungId, this.tier = 'wood', this.gate = false});

  /// The rung whose first clear dropped it (the chest stands one rung above).
  final String rungId;

  /// Starting tier name: `wood`, `silver` or `gold` (a gate chest starts at silver).
  final String tier;

  /// Dropped by a module gate: always holds a not-yet-won life skill.
  final bool gate;

  String get claimId => toolboxChestClaimId(rungId);

  Map<String, dynamic> toJson() => {'rungId': rungId, 'tier': tier, if (gate) 'gate': true};

  factory PendingChest.fromJson(Map<String, dynamic> j) => PendingChest(
        rungId: j['rungId'] as String? ?? '',
        tier: j['tier'] as String? ?? 'wood',
        gate: j['gate'] as bool? ?? false,
      );
}

/// The one-time id of the chest dropped by [rungId]'s first clear (kept in
/// [GameSave.giftsClaimed] once opened, beside the old `station_*` ids).
String toolboxChestClaimId(String rungId) => 'chest@$rungId';

/// At most this many ordinary chests wait at once (a gate chest always drops).
const kToolboxMaxWaiting = 3;

/// A first clear drops a chest about 1 in [kToolboxDropOneIn] times…
const kToolboxDropOneIn = 3;

/// …and at least once every [kToolboxDropEvery] first clears.
const kToolboxDropEvery = 4;

/// Stable 32-bit FNV-1a hash (String.hashCode is not stable across runs).
int toolboxSeed(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Does the first clear of [rungId] drop a chest? Seeded by the rung id and
/// the save's first-clear counter [clearNo], so the same save always gives
/// the same answer. A gate always drops (silver); otherwise about 1 in 3,
/// guaranteed when [sinceDrop] first clears in a row gave none (every 4th),
/// and never while [waiting] ordinary chests already fill the ladder.
PendingChest? toolboxChestDrop({
  required String rungId,
  required int clearNo,
  required int sinceDrop,
  required int waiting,
}) {
  if (rungId.endsWith('/gate')) return PendingChest(rungId: rungId, tier: 'silver', gate: true);
  if (waiting >= kToolboxMaxWaiting) return null;
  final due = sinceDrop >= kToolboxDropEvery - 1;
  if (due || toolboxSeed('$rungId#$clearNo') % kToolboxDropOneIn == 0) return PendingChest(rungId: rungId);
  return null;
}

/// "ভাগ্যের টুলবক্স" state (lucky toolbox on the ladder). Old saves load with zeros.
@immutable
class ToolboxSave {
  const ToolboxSave({
    this.keys = 0,
    this.keysByRung = const {},
    this.opens = 0,
    this.sinceRare = 0,
    this.shields = 0,
    this.doubleNext = false,
    this.badge = false,
    this.chests = const [],
    this.firstClears = 0,
    this.sinceDrop = 0,
    this.lifeSkills = const [],
  });

  /// Keys in hand (one opens one chest).
  final int keys;

  /// Keys already earned per rung id (best result only; a better replay pays the difference).
  final Map<String, int> keysByRung;

  /// Chests opened so far.
  final int opens;

  /// Opens since the last Rare-or-better prize (pity counter).
  final int sinceRare;

  /// Pending shields: each forgives one small slip in a Do level.
  final int shields;

  /// ×2 ◆ waits for the next completed level.
  final bool doubleNext;

  /// The rare toolbox badge is owned.
  final bool badge;

  /// Sudden chests waiting on the ladder (oldest first).
  final List<PendingChest> chests;

  /// First clears so far (seeds the drop roll).
  final int firstClears;

  /// First clears since the last drop (the every-4th guarantee).
  final int sinceDrop;

  /// Life skills won (ids from life_skills_data.dart), in the order won.
  final List<String> lifeSkills;

  ToolboxSave copyWith({
    int? keys,
    Map<String, int>? keysByRung,
    int? opens,
    int? sinceRare,
    int? shields,
    bool? doubleNext,
    bool? badge,
    List<PendingChest>? chests,
    int? firstClears,
    int? sinceDrop,
    List<String>? lifeSkills,
  }) =>
      ToolboxSave(
        keys: keys ?? this.keys,
        keysByRung: keysByRung ?? this.keysByRung,
        opens: opens ?? this.opens,
        sinceRare: sinceRare ?? this.sinceRare,
        shields: shields ?? this.shields,
        doubleNext: doubleNext ?? this.doubleNext,
        badge: badge ?? this.badge,
        chests: chests ?? this.chests,
        firstClears: firstClears ?? this.firstClears,
        sinceDrop: sinceDrop ?? this.sinceDrop,
        lifeSkills: lifeSkills ?? this.lifeSkills,
      );

  Map<String, dynamic> toJson() => {
        'keys': keys,
        'keysByRung': keysByRung,
        'opens': opens,
        'sinceRare': sinceRare,
        'shields': shields,
        'doubleNext': doubleNext,
        'badge': badge,
        'chests': [for (final c in chests) c.toJson()],
        'firstClears': firstClears,
        'sinceDrop': sinceDrop,
        'lifeSkills': lifeSkills,
      };

  factory ToolboxSave.fromJson(Map<String, dynamic> j) => ToolboxSave(
        keys: (j['keys'] as num?)?.toInt() ?? 0,
        keysByRung: {
          if (j['keysByRung'] is Map)
            for (final e in (j['keysByRung'] as Map).entries)
              if (e.value is num) e.key.toString(): (e.value as num).toInt(),
        },
        opens: (j['opens'] as num?)?.toInt() ?? 0,
        sinceRare: (j['sinceRare'] as num?)?.toInt() ?? 0,
        shields: (j['shields'] as num?)?.toInt() ?? 0,
        doubleNext: j['doubleNext'] as bool? ?? false,
        badge: j['badge'] as bool? ?? false,
        chests: [
          for (final raw in (j['chests'] as List? ?? const []))
            if (raw is Map && raw['rungId'] is String) PendingChest.fromJson(Map<String, dynamic>.from(raw)),
        ],
        firstClears: (j['firstClears'] as num?)?.toInt() ?? 0,
        sinceDrop: (j['sinceDrop'] as num?)?.toInt() ?? 0,
        lifeSkills: [for (final v in (j['lifeSkills'] as List? ?? const [])) v.toString()],
      );
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
    var s = score < 0 ? 0 : score;
    // Lucky toolbox ×2: doubles one cleared level's committed score, once.
    if (s > 0 && state.toolbox.doubleNext && state.rungProgress[rungId] == 'cleared') {
      s *= 2;
      state = state.copyWith(toolbox: state.toolbox.copyWith(doubleNext: false));
    }
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
    // This play's time, for the league (recordStars sends it with the stars).
    if (ms > 0) _playMs[rungId] = ms;
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

  /// The sudden chest dropped by the latest first clear, for the ladder's
  /// one-shot drop. The ladder takes it (sets it back to null) when it plays it.
  PendingChest? lastChestDrop;

  Future<void> markRungCleared(String rungId, {int? score}) async {
    // Only a rung's very first clear can drop a chest ('prove' = passed before a fall).
    final firstClear = rungId.isNotEmpty && state.rungProgress[rungId] == null;
    final progress = Map<String, String>.from(state.rungProgress)..[rungId] = 'cleared';
    final since = isFallableRung(rungId) && !state.clearedSinceDeath.contains(rungId)
        ? [...state.clearedSinceDeath, rungId]
        : state.clearedSinceDeath;
    final best = Map<String, int>.from(state.bestByRung);
    if (score != null) {
      final prev = best[rungId] ?? 0;
      if (score > prev) best[rungId] = score;
    }
    state = _withToolboxKeys(
      state.copyWith(
        rungProgress: progress,
        bestByRung: best,
        safeStreak: state.safeStreak + 1,
        currentRungId: rungId,
        clearedSinceDeath: since,
      ),
      rungId,
      // A Do/gate clear is worth at least 1 key; its stars may lift it to 2.
      isFallableRung(rungId) ? 1 : toolboxKeysForLearnMark(state.bestMarkByRung[rungId]),
    );
    if (firstClear) state = _withChestDrop(state, rungId);
    await _persist();
  }

  /// Rolls the sudden chest for [rungId]'s first clear ([toolboxChestDrop]).
  GameSave _withChestDrop(GameSave s, String rungId) {
    final t = s.toolbox;
    if (s.giftsClaimed.contains(toolboxChestClaimId(rungId)) || t.chests.any((c) => c.rungId == rungId)) return s;
    final drop = toolboxChestDrop(
      rungId: rungId,
      clearNo: t.firstClears,
      sinceDrop: t.sinceDrop,
      waiting: t.chests.where((c) => !c.gate).length,
    );
    if (drop != null) lastChestDrop = drop;
    return s.copyWith(
      toolbox: t.copyWith(
        firstClears: t.firstClears + 1,
        sinceDrop: drop == null ? t.sinceDrop + 1 : 0,
        chests: drop == null ? null : [...t.chests, drop],
      ),
    );
  }

  /// Gives the keys [rungId]'s best result is worth ([target]) minus what it
  /// already earned, so each rung pays once for its best result.
  GameSave _withToolboxKeys(GameSave s, String rungId, int target) {
    if (!ToolboxFlags.keysEnabled || rungId.isEmpty) return s;
    final had = s.toolbox.keysByRung[rungId] ?? 0;
    if (target <= had) return s;
    return s.copyWith(
      toolbox: s.toolbox.copyWith(
        keys: s.toolbox.keys + (target - had),
        keysByRung: {...s.toolbox.keysByRung, rungId: target},
      ),
    );
  }

  /// Uses one pending lucky-toolbox shield (a small slip is forgiven).
  /// Synchronous so a strike can ask it; saves in the background.
  bool useToolboxShield() {
    final t = state.toolbox;
    if (t.shields <= 0) return false;
    state = state.copyWith(toolbox: t.copyWith(shields: t.shields - 1));
    unawaited(_persist());
    return true;
  }

  /// Opens the lucky toolbox [claimId]: marks it opened (never twice), takes
  /// its waiting chest off the ladder, moves the pity counter and grants the
  /// prize and any [lifeSkills]; [coins] go through [addPoints].
  /// With keys on ([ToolboxFlags.keysEnabled]) it also spends one key and
  /// refuses without one. Returns false and changes nothing when it cannot
  /// open. The check and the mark happen before any await.
  Future<bool> openToolbox(
    String claimId, {
    required bool rareOrBetter,
    int coins = 0,
    bool shield = false,
    bool doubleNext = false,
    bool badge = false,
    List<String> lifeSkills = const [],
    Offset? originGlobal,
  }) async {
    final t = state.toolbox;
    final keys = ToolboxFlags.keysEnabled;
    if ((keys && t.keys <= 0) || state.giftsClaimed.contains(claimId)) return false;
    state = state.copyWith(
      giftsClaimed: [...state.giftsClaimed, claimId],
      toolbox: t.copyWith(
        chests: [for (final c in t.chests) if (c.claimId != claimId) c],
        lifeSkills: [...t.lifeSkills, for (final id in lifeSkills) if (!t.lifeSkills.contains(id)) id],
        keys: keys ? t.keys - 1 : t.keys,
        opens: t.opens + 1,
        sinceRare: rareOrBetter ? 0 : t.sinceRare + 1,
        shields: shield ? t.shields + 1 : t.shields,
        doubleNext: t.doubleNext || doubleNext,
        badge: t.badge || badge,
      ),
    );
    if (coins > 0) {
      await addPoints(coins, originGlobal: originGlobal);
    } else {
      await _persist();
    }
    return true;
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

  /// Hears every finished play: a Do/gate play's stars (below) and a Learn
  /// play's mark (from the Learn runners), with the play's time in [ms] from
  /// level start to result when known. Set by the monthly league
  /// (`rank/league_service.dart`); null in tests.
  static void Function(String rungId, {int? stars, int? mark, int? ms})? onPlayResult;

  /// Time of the latest play per rung, from [recordBestTime] (the runners call
  /// it just before [recordStars]). Memory only.
  final _playMs = <String, int>{};

  /// Keeps the best stars (1–3) of a rung; returns true when this is a new best.
  Future<bool> recordStars(String rungId, int stars) async {
    final s = stars.clamp(0, 3);
    onPlayResult?.call(rungId, stars: s, ms: _playMs.remove(rungId));
    if (s <= (state.starsByRung[rungId] ?? 0)) return false;
    state = _withToolboxKeys(
      state.copyWith(starsByRung: {...state.starsByRung, rungId: s}),
      rungId,
      toolboxKeysForStars(s),
    );
    await _persist();
    return true;
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
