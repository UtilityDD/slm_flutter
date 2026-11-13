import 'dart:math' as math;

import '../home/lesson_quiz_page.dart' show LessonQuizQuestion;
import '../home/lesson_quiz_store.dart';
import '../life_skills/life_skills_data.dart';
import 'game_save.dart';
import 'mistake_kit.dart' show DoMistake;
import 'ten_sec_scan.dart' show ScanTopic, TenSecCheck, tenSecTopics;

// "ভাগ্যের টুলবক্স" (lucky toolbox, owner-approved 2026-11-13), stage 2
// "হঠাৎ উপহার": no side stations any more. After a rung's first clear a
// chest sometimes drops beside the next rung (game_save.dart:
// toolboxChestDrop — about 1 in 3, at least every 4th, always after a gate)
// and waits there until opened. A chest opens once: a quick task from content
// the player has met (right = the chest goes up a tier), then pick 1 of 3
// boxes. A gate chest starts at silver and always adds a not-yet-won life
// skill. Keys stay paused behind ToolboxFlags.keysEnabled. Pure rules here
// (unit-tested); the overlay is lib/features/duty_slip/lucky_toolbox_overlay.dart,
// the shield's strike hook lib/features/game/toolbox_shield.dart, the
// Supabase quiz lib/features/game/toolbox_quiz_sources.dart. No real money.

/// The chest's tier: shifts the prize odds. The gate chest starts at silver.
enum ChestTier { wood, silver, gold }

extension ChestTierUp on ChestTier {
  /// One tier up (gold stays gold).
  ChestTier get up => ChestTier.values[math.min(index + 1, ChestTier.values.length - 1)];
}

/// A saved tier name (`PendingChest.tier`) → the tier (unknown = wood).
ChestTier chestTierNamed(String name) =>
    ChestTier.values.firstWhere((t) => t.name == name, orElse: () => ChestTier.wood);

enum ToolboxRarity { common, rare, epic, legendary }

enum ToolboxPrize { coins, shield, doubleNext, badge, lifeSkill }

/// What one box holds.
class ToolboxReward {
  const ToolboxReward(this.rarity, this.prize, {this.coins = 0, this.lifeSkillId});

  final ToolboxRarity rarity;
  final ToolboxPrize prize;

  /// ◆ paid (coins prizes, or a duplicate turned into ◆).
  final int coins;

  /// The life skill won ([ToolboxPrize.lifeSkill] only).
  final String? lifeSkillId;

  bool get rareOrBetter => rarity.index >= ToolboxRarity.rare.index;

  @override
  String toString() => 'ToolboxReward($rarity, $prize, $coins${lifeSkillId == null ? '' : ', $lifeSkillId'})';
}

/// Odds in percent (common, rare, epic, legendary) per tier.
const toolboxOdds = <ChestTier, List<int>>{
  ChestTier.wood: [70, 22, 6, 2],
  ChestTier.silver: [50, 32, 13, 5],
  ChestTier.gold: [30, 38, 22, 10],
};

/// At least one Rare-or-better every this many opens.
const kToolboxPityEvery = 5;

/// ◆ for a Rare prize, a Legendary ◆ prize, and the duplicates they replace.
const kToolboxRareCoins = 50;
const kToolboxLegendCoins = 200;

/// An Epic box holds a not-yet-won life skill this often (percent).
const kToolboxLifeSkillEpicPercent = 25;

/// True when this open must give Rare-or-better (the 5th open without one).
bool toolboxPityDue(int sinceRare) => sinceRare >= kToolboxPityEvery - 1;

ToolboxRarity rollToolboxRarity(ChestTier tier, math.Random rng, {bool pity = false}) {
  final odds = toolboxOdds[tier]!;
  final from = pity ? 1 : 0;
  var total = 0;
  for (var i = from; i < odds.length; i++) {
    total += odds[i];
  }
  var r = rng.nextInt(total);
  for (var i = from; i < odds.length; i++) {
    if (r < odds[i]) return ToolboxRarity.values[i];
    r -= odds[i];
  }
  return ToolboxRarity.values.last;
}

/// One box's prize. A badge already owned, or a ×2 already waiting, turns into
/// ◆. An Epic box sometimes holds one of [lifeSkillsLeft] (not yet won).
ToolboxReward rollToolboxReward(
  ChestTier tier,
  math.Random rng, {
  bool pity = false,
  bool hasBadge = false,
  bool doublePending = false,
  List<String> lifeSkillsLeft = const [],
}) {
  final rarity = rollToolboxRarity(tier, rng, pity: pity);
  switch (rarity) {
    case ToolboxRarity.common:
      return ToolboxReward(rarity, ToolboxPrize.coins, coins: 10 + 5 * rng.nextInt(3));
    case ToolboxRarity.rare:
      return const ToolboxReward(ToolboxRarity.rare, ToolboxPrize.coins, coins: kToolboxRareCoins);
    case ToolboxRarity.epic:
      if (lifeSkillsLeft.isNotEmpty && rng.nextInt(100) < kToolboxLifeSkillEpicPercent) {
        return ToolboxReward(
          ToolboxRarity.epic,
          ToolboxPrize.lifeSkill,
          lifeSkillId: lifeSkillsLeft[rng.nextInt(lifeSkillsLeft.length)],
        );
      }
      if (rng.nextBool()) return const ToolboxReward(ToolboxRarity.epic, ToolboxPrize.shield);
      return doublePending
          ? const ToolboxReward(ToolboxRarity.epic, ToolboxPrize.coins, coins: kToolboxRareCoins)
          : const ToolboxReward(ToolboxRarity.epic, ToolboxPrize.doubleNext);
    case ToolboxRarity.legendary:
      if (rng.nextBool() && !hasBadge) return const ToolboxReward(ToolboxRarity.legendary, ToolboxPrize.badge);
      return const ToolboxReward(ToolboxRarity.legendary, ToolboxPrize.coins, coins: kToolboxLegendCoins);
  }
}

/// Life skills not won yet, in the web's order.
List<String> lifeSkillsLeft(ToolboxSave t, {List<String> all = kLifeSkillIds}) =>
    [for (final id in all) if (!t.lifeSkills.contains(id)) id];

/// The three boxes of one open. When pity is due every box is Rare-or-better,
/// so whichever the player picks keeps the promise. Two boxes never show the
/// same life skill.
List<ToolboxReward> dealToolbox(ChestTier tier, math.Random rng, ToolboxSave t, {List<String> allLifeSkills = kLifeSkillIds}) {
  final pity = toolboxPityDue(t.sinceRare);
  final left = lifeSkillsLeft(t, all: allLifeSkills);
  final out = <ToolboxReward>[];
  for (var i = 0; i < 3; i++) {
    final r = rollToolboxReward(
      tier,
      rng,
      pity: pity,
      hasBadge: t.badge,
      doublePending: t.doubleNext,
      lifeSkillsLeft: left,
    );
    if (r.lifeSkillId != null) left.remove(r.lifeSkillId);
    out.add(r);
  }
  return out;
}

/// A gate chest's guaranteed extra, given beside whichever box is picked: a
/// not-yet-won life skill (one the pick itself did not already give), or ◆
/// once all of them are won (a duplicate becomes ◆).
ToolboxReward gateLifeSkillExtra(ToolboxSave t, math.Random rng, {String? alsoWon, List<String> all = kLifeSkillIds}) {
  final left = [for (final id in lifeSkillsLeft(t, all: all)) if (id != alsoWon) id];
  if (left.isEmpty) return const ToolboxReward(ToolboxRarity.epic, ToolboxPrize.coins, coins: kToolboxRareCoins);
  return ToolboxReward(ToolboxRarity.epic, ToolboxPrize.lifeSkill, lifeSkillId: left[rng.nextInt(left.length)]);
}

// ---- the quiz -----------------------------------------------------------------

/// One quiz question for the toolbox task. [correctIndex] null = the answer
/// is not on the phone and the server checks it ([serverId]).
class ToolboxQuizQuestion {
  const ToolboxQuizQuestion({required this.text, required this.options, this.correctIndex, this.serverId});

  final String text;
  final List<String> options;
  final int? correctIndex;
  final String? serverId;

  static ToolboxQuizQuestion local(LessonQuizQuestion q) =>
      ToolboxQuizQuestion(text: q.questionText, options: q.options, correctIndex: q.correctIndex);
}

/// The result of a check: right or not, and which option was right.
class ToolboxQuizVerdict {
  const ToolboxQuizVerdict({required this.correct, required this.correctIndex});

  final bool correct;

  /// -1 when the right option is not among the shown ones.
  final int correctIndex;
}

/// The local answer (null when the question is server-checked).
ToolboxQuizVerdict? localQuizVerdict(ToolboxQuizQuestion q, int? choice) {
  final right = q.correctIndex;
  if (right == null) return null;
  return ToolboxQuizVerdict(correct: choice == right, correctIndex: right);
}

/// Where the "কুইজ প্রশ্ন" task gets its question. Implementations never
/// throw: [next] returns null when there is nothing to ask (the type is then
/// skipped), [check] null when it could not check.
abstract interface class ToolboxQuizSource {
  Future<ToolboxQuizQuestion?> next(GameSave save, math.Random rng);

  /// Grades [choice] (null = time ran out).
  Future<ToolboxQuizVerdict?> check(ToolboxQuizQuestion q, int? choice);
}

/// One text-only question from [pool] (pictures may need the network).
ToolboxQuizQuestion? pickQuizQuestion(List<LessonQuizQuestion> pool, math.Random rng) {
  final usable = [
    for (final q in pool)
      if (q.questionText.trim().isNotEmpty && (q.image == null || q.image!.isEmpty) && !q.hasImageOptions && q.options.length >= 2) q,
  ];
  if (usable.isEmpty) return null;
  return ToolboxQuizQuestion.local(usable[rng.nextInt(usable.length)]);
}

/// Questions of lessons whose Learn rung is cleared (passed), from this
/// phone's quiz cache only (never the network): the toolbox never opens or
/// previews a lesson the player has not passed. Empty offline with nothing saved.
class CachedLessonQuizSource implements ToolboxQuizSource {
  const CachedLessonQuizSource({this.store});

  /// Null = [LessonQuizStore.instance].
  final LessonQuizStore? store;

  Future<List<LessonQuizQuestion>> questionsFor(GameSave save) async {
    final quiz = store ?? LessonQuizStore.instance;
    final out = <LessonQuizQuestion>[];
    final lessons = clearedLessons(save)..shuffle();
    for (final id in lessons.take(8)) {
      final parts = id.split('.');
      if (parts.length != 2) continue;
      final m = int.tryParse(parts[0]);
      final c = int.tryParse(parts[1]);
      if (m == null || c == null) continue;
      try {
        final q = await quiz.cachedOnly(m, c);
        if (q != null) out.addAll(q);
      } catch (_) {}
      if (out.length >= 12) break;
    }
    return out;
  }

  @override
  Future<ToolboxQuizQuestion?> next(GameSave save, math.Random rng) async => pickQuizQuestion(await questionsFor(save), rng);

  @override
  Future<ToolboxQuizVerdict?> check(ToolboxQuizQuestion q, int? choice) async => localQuizVerdict(q, choice);
}

/// Questions of the life skills the player has won (their answers ship in
/// assets/life_skills/questions/: works offline).
class LifeSkillQuizSource implements ToolboxQuizSource {
  const LifeSkillQuizSource({this.repo});

  /// Null = [LifeSkillsRepo.instance].
  final LifeSkillsRepo? repo;

  Future<List<LessonQuizQuestion>> questionsFor(GameSave save) async {
    final r = repo ?? LifeSkillsRepo.instance;
    final out = <LessonQuizQuestion>[];
    for (final id in save.toolbox.lifeSkills) {
      try {
        out.addAll(await r.questions(id));
      } catch (_) {}
    }
    return out;
  }

  @override
  Future<ToolboxQuizQuestion?> next(GameSave save, math.Random rng) async {
    if (save.toolbox.lifeSkills.isEmpty) return null;
    return pickQuizQuestion(await questionsFor(save), rng);
  }

  @override
  Future<ToolboxQuizVerdict?> check(ToolboxQuizQuestion q, int? choice) async => localQuizVerdict(q, choice);
}

/// Tries [sources] in order and takes the first question (a source that
/// fails or has nothing is skipped). [sometimesFirst] (the won life skills)
/// is asked first one time in [sometimesOneIn], so won skills come back even
/// online. The source that gave a question also checks it.
class ToolboxQuizChain implements ToolboxQuizSource {
  ToolboxQuizChain(this.sources, {this.sometimesFirst, this.sometimesOneIn = 3});

  final List<ToolboxQuizSource> sources;
  final ToolboxQuizSource? sometimesFirst;
  final int sometimesOneIn;
  final _from = Expando<ToolboxQuizSource>();

  @override
  Future<ToolboxQuizQuestion?> next(GameSave save, math.Random rng) async {
    final first = sometimesFirst;
    final order = [
      if (first != null && rng.nextInt(sometimesOneIn) == 0) first,
      ...sources,
      ?first,
    ];
    for (final s in order) {
      ToolboxQuizQuestion? q;
      try {
        q = await s.next(save, rng);
      } catch (_) {
        q = null;
      }
      if (q != null && q.options.length >= 2) {
        _from[q] = s;
        return q;
      }
    }
    return null;
  }

  @override
  Future<ToolboxQuizVerdict?> check(ToolboxQuizQuestion q, int? choice) async {
    final local = localQuizVerdict(q, choice);
    if (local != null) return local;
    try {
      return await _from[q]?.check(q, choice);
    } catch (_) {
      return null;
    }
  }
}

enum ToolboxTaskKind { ownMistake, quiz, eye }

/// One quick question before the pick (~10 s).
class ToolboxTask {
  const ToolboxTask({
    required this.kind,
    required this.promptBn,
    required this.options,
    required this.correctIndex,
    this.art,
    this.mistakeKey,
    this.quiz,
  });

  final ToolboxTaskKind kind;
  final String promptBn;
  final List<String> options;

  /// -1 = the server checks the answer ([quiz] has no local answer).
  final int correctIndex;

  /// Picture (SVG or WebP asset), if any.
  final String? art;

  /// The player's own mistake key (ownMistake only).
  final String? mistakeKey;

  /// The quiz question (quiz only), for the check.
  final ToolboxQuizQuestion? quiz;

  bool get serverChecked => correctIndex < 0;

  String get titleBn => ToolboxLines.taskTitle(kind);
}

/// The ten-sec checks' question → the lesson that teaches it (a check counts
/// as met once that lesson's Learn rung is cleared; the rest belong to 1.10).
String _lessonOfTopic(ScanTopic t) => switch (t) {
      ScanTopic.ppe => '1.1',
      ScanTopic.rekha => '1.2',
      ScanTopic.pole => '1.3',
      ScanTopic.harness => '1.4',
      ScanTopic.permit => '1.6',
      ScanTopic.weather => '1.9',
      _ => '1.10',
    };

bool _learnCleared(GameSave save, String lessonId) => save.rungProgress['$lessonId/learn'] == 'cleared';

/// Lessons whose Learn rung the player has cleared (`M.C`), newest unknown.
List<String> clearedLessons(GameSave save) => [
      for (final e in save.rungProgress.entries)
        if (e.value == 'cleared' && e.key.endsWith('/learn')) e.key.substring(0, e.key.length - '/learn'.length),
    ];

/// Builds the "নিজের ভুল চিনুন" task from one of the player's own mistakes.
ToolboxTask? ownMistakeTask(GameSave save, Map<String, DoMistake> known, math.Random rng) {
  final mine = [
    for (final e in save.mistakes)
      if (known[e.key] != null && e.textBn.isNotEmpty) e,
  ];
  if (mine.isEmpty) return null;
  final pick = mine[rng.nextInt(mine.length)];
  final art = known[pick.key]!.art;
  final decoys = [
    for (final m in known.values)
      if (m.key != pick.key && m.textBn != pick.textBn && m.textBn.isNotEmpty) m.textBn,
  ];
  if (decoys.isEmpty) return null;
  final decoy = decoys[rng.nextInt(decoys.length)];
  final rightFirst = rng.nextBool();
  return ToolboxTask(
    kind: ToolboxTaskKind.ownMistake,
    promptBn: ToolboxLines.whichMistake,
    options: rightFirst ? [pick.textBn, decoy] : [decoy, pick.textBn],
    correctIndex: rightFirst ? 0 : 1,
    art: art,
    mistakeKey: pick.key,
  );
}

/// The "কুইজ প্রশ্ন" task for [q].
ToolboxTask quizTask(ToolboxQuizQuestion q) => ToolboxTask(
      kind: ToolboxTaskKind.quiz,
      promptBn: q.text,
      options: q.options,
      correctIndex: q.correctIndex ?? -1,
      quiz: q,
    );

/// One "10 সেকেন্ডের চোখ" card from a lesson the player has met.
ToolboxTask? eyeTask(GameSave save, List<TenSecCheck> checks, math.Random rng) {
  final met = [
    for (final c in checks)
      if (_learnCleared(save, _lessonOfTopic(c.topic))) c,
  ];
  if (met.isEmpty) return null;
  final c = met[rng.nextInt(met.length)];
  return ToolboxTask(
    kind: ToolboxTaskKind.eye,
    promptBn: tenSecTopics[c.topic]?.askBn ?? ToolboxLines.eyeAsk,
    options: const [ToolboxLines.eyeOk, ToolboxLines.eyeFault],
    correctIndex: c.isSafe ? 0 : 1,
    art: c.art,
  );
}

/// Picks the quick task: the player's own mistakes are weighted 3 : 1 : 1
/// against a quiz question ([quiz], null = none could be fetched) and a
/// ten-sec card. A type with nothing to show is left out. Null = no task:
/// the flow goes straight to the pick.
ToolboxTask? pickToolboxTask({
  required GameSave save,
  required Map<String, DoMistake> known,
  required List<TenSecCheck> eyeChecks,
  required ToolboxQuizQuestion? quiz,
  required math.Random rng,
}) {
  final pool = <ToolboxTask>[];
  final mine = ownMistakeTask(save, known, rng);
  if (mine != null) pool.addAll([mine, mine, mine]);
  if (quiz != null && quiz.text.trim().isNotEmpty && quiz.options.length >= 2) pool.add(quizTask(quiz));
  final eye = eyeTask(save, eyeChecks, rng);
  if (eye != null) pool.add(eye);
  if (pool.isEmpty) return null;
  return pool[rng.nextInt(pool.length)];
}

/// The chest tier after the task: a right answer goes up one; wrong or skipped stays.
ChestTier tierAfterTask(ChestTier start, {required bool? right}) => right == true ? start.up : start;

/// Every fixed line of the toolbox (device TTS for now; recorded later).
abstract final class ToolboxLines {
  static const name = 'ভাগ্যের টুলবক্স';
  static const noKeyTitle = 'চাবি নেই';
  static const noKeyBody = 'একটা লেভেল শেষ করুন — চাবি পাবেন।';
  static const intro = 'ঝটপট একটা প্রশ্ন! ঠিক হলে বাক্স আরও দামি।';
  static const whichMistake = 'কোন ভুলটা ছবিতে?';
  static const eyeAsk = 'সব ঠিক আছে?';
  static const eyeOk = 'ঠিক আছে';
  static const eyeFault = 'সমস্যা';
  static const skip = 'এড়িয়ে যান';
  static const right = 'ঠিক! বাক্স এক ধাপ উপরে।';
  static const wrong = 'এটাই ঠিক উত্তর — মনে রাখুন।';
  static const unchecked = 'উত্তর যাচাই করা গেল না — বাক্স যেমন ছিল তেমনই।';
  static const pick = 'একটা বাক্স বেছে নিন';
  static const missed = 'বাকি দুটোয় ছিল';
  static const back = 'মইয়ে ফিরুন';
  static const gateExtra = 'গেট পার করার উপহার';
  static const dropped = 'হঠাৎ উপহার! পাশের ধাপে একটা টুলবক্স এসেছে।';

  static String taskTitle(ToolboxTaskKind k) => switch (k) {
        ToolboxTaskKind.ownMistake => 'নিজের ভুল চিনুন',
        ToolboxTaskKind.quiz => 'কুইজ প্রশ্ন',
        ToolboxTaskKind.eye => '10 সেকেন্ডের চোখ',
      };

  static String tierName(ChestTier t) => switch (t) {
        ChestTier.wood => 'কাঠের বাক্স',
        ChestTier.silver => 'রুপোর বাক্স',
        ChestTier.gold => 'সোনার বাক্স',
      };

  static String rarityName(ToolboxRarity r) => switch (r) {
        ToolboxRarity.common => 'সাধারণ',
        ToolboxRarity.rare => 'দুর্লভ',
        ToolboxRarity.epic => 'অসাধারণ',
        ToolboxRarity.legendary => 'কিংবদন্তি',
      };

  /// The prize's short label under its box.
  static String prizeLabel(ToolboxReward r) => switch (r.prize) {
        ToolboxPrize.coins => '+${r.coins} ◆',
        ToolboxPrize.shield => 'শিল্ড',
        ToolboxPrize.doubleNext => '×2 ◆',
        ToolboxPrize.badge => 'বিরল ব্যাজ',
        ToolboxPrize.lifeSkill => LifeSkillLines.prize,
      };

  /// What the guide says when the picked box opens.
  static String won(ToolboxReward r) => switch (r.prize) {
        ToolboxPrize.coins => '+${r.coins} ◆ আপনার!',
        ToolboxPrize.shield => 'শিল্ড পেলেন! পরের কাজে একটা ছোট ভুল মাফ।',
        ToolboxPrize.doubleNext => '×2! পরের লেভেলের ◆ দ্বিগুণ।',
        ToolboxPrize.badge => 'বিরল ব্যাজ পেলেন! টুলবক্সের সেরা পুরস্কার।',
        ToolboxPrize.lifeSkill => '${LifeSkillLines.won} টুলবক্সের মেনুতে "${LifeSkillLines.menu}"-এ পাবেন।',
      };
}
