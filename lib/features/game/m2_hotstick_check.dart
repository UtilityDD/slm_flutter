import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'choice_deck.dart';
import 'coworker_moment.dart';
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_hotstick_check_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.5 (অপারেটিং রড / হট স্টিক), কাজ 1: "রডের স্বাস্থ্য". Just after
// the rain, at the pole with the DO fuses: read the docket (line voltage, the
// job), take an operating rod off the site's stand, and check it in hand —
// its rating label against the docket, its lab-test sticker (lesson: tested
// at a lab, usually every year), then run a hand along the whole stick
// (lesson's daily check: cracks, deep scratches, worn glaze; clean and fully
// dry). A wet stick is wiped with a soft dry cloth (lesson: নরম, শুকনো
// কাপড়) — then it is fine; a damaged or overdue rod is set aside, tagged
// বাতিল, as is the bamboo jugaad (lesson's myth). Three dockets, each with
// one good rod. Once a play the careless coworker pushes a shortcut: the wet
// rod unwiped ("একটু ভেজা, কিছু হবে না") or the
// dry bamboo (his recorded line). The wet line has no clip yet: the kit keeps it
// silent and holds his caption for a reading time. On his docket the first
// reach for a rod waits for him (holdForCoworker), so a fast player still
// meets him while both his pushes are on the stand.
//
// Deadly (MODULE2_LADDER.md row 14): a rod rated below the line; the bamboo;
// a wet stick not wiped dry (also by listening to him — the act he pushes is
// on that deadly list). Slips: taking a cracked / deeply scratched /
// glaze-worn rod, or one past its test date. The take / put-back buttons are
// dead while the cloth is still going along the stick.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" → এগিয়ে যান → next docket;
// gesture hints (how to touch, never which rod) in every waiting state.
// The rods and the site are drawn in code (m2_hotstick_check_world.dart).

// ============================================================================
// Content
// ============================================================================

/// Line / rod voltage, weakest first.
enum StickRating { kv11, kv33 }

extension StickRatingText on StickRating {
  /// The label printed on a rod.
  String get tag => switch (this) {
        StickRating.kv11 => '11 kV',
        StickRating.kv33 => '33 kV',
      };

  /// The line as the docket names it.
  String get lineBn => switch (this) {
        StickRating.kv11 => '11 কেভি',
        StickRating.kv33 => '33 কেভি',
      };
}

/// Surface flaws found by hand.
const kStickDamage = [StickMark.crack, StickMark.scratch, StickMark.glaze];

@immutable
class HotStick {
  const HotStick({required this.id, this.rating, this.flaw = StickMark.none, required this.due});
  final String id;

  /// Null: the bamboo jugaad (no rating, no test).
  final StickRating? rating;
  final StickMark flaw;

  /// The lab test sticker's "next test" month.
  final DateTime due;
  bool get bamboo => rating == null;
  DateTime get tested => DateTime(due.year - 1, due.month);
  StickBuild get build => bamboo ? StickBuild.bamboo : StickBuild.fibreglass;
}

@immutable
class StickDocket {
  const StickDocket({required this.line, required this.jobBn, required this.feederBn, required this.date});
  final StickRating line;
  final String jobBn;
  final String feederBn;
  final DateTime date;
}

@immutable
class StickRoundDeal {
  const StickRoundDeal({required this.docket, required this.rods});
  final StickDocket docket;
  final List<HotStick> rods;

  /// The one good rod (it may be wet: wiped dry, it is right).
  HotStick get good => rods.firstWhere((r) => r.rating == docket.line && (r.flaw == StickMark.none || r.flaw == StickMark.wet));
}

/// What the careless coworker pushes.
enum StickPush { wet, bamboo }

@immutable
class StickDeal {
  const StickDeal({required this.rounds, required this.callRound, required this.preferWet});
  final List<StickRoundDeal> rounds;

  /// The docket on which he peeps in (or later, if nothing is left to push).
  final int callRound;

  /// He pushes the wet rod (when it is still on the stand, not wiped);
  /// otherwise the bamboo.
  final bool preferWet;
}

String _mmyyyy(DateTime d) => enDigits('${d.month.toString().padLeft(2, '0')}/${d.year}');

abstract final class HotStickLines {
  static const tasks = [ask, inspectAsk];

  static const title = 'রডের স্বাস্থ্য';
  static const intro = 'বৃষ্টি থামল, ফিউজ খুলতে হবে! ডকেট দেখে ঠিক অপারেটিং রড বাছুন — হাতে নিয়ে যাচাই করে।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const ask = 'ডকেট দেখুন। কোন রডটা নেবেন?';
  static const inspectAsk = 'লেবেল পড়ুন, পুরো স্টিকে হাত বোলান। নেবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const lineWord = 'লাইন';
  static String line(StickDocket d) => 'লাইন: ${d.line.lineBn} · ${d.feederBn}';
  static String job(StickDocket d) => 'কাজ: ${d.jobBn}';
  static String date(StickDocket d) => enDigits('তারিখ: ${d.date.day.toString().padLeft(2, '0')}/${d.date.month.toString().padLeft(2, '0')}/${d.date.year}');
  static String tested(HotStick r) => 'ল্যাব টেস্ট ${_mmyyyy(r.tested)}';
  static String due(HotStick r) => 'পরবর্তী ${_mmyyyy(r.due)}';
  static const rodLabel = 'অপারেটিং রড';
  static const handLabel = 'রড হাতে';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const cloth = 'শুকনো কাপড়ে মুছুন';
  static const rejected = 'বাতিল';

  // The reasons (lesson 2.5): the right ones fit this docket and this rod.
  static const packAsk = 'কেন এই রডটা নিলেন?';
  static String packMatch(StickRating r) => 'ডকেটে ${r.lineBn}, রডের লেবেলেও ${r.lineBn}';
  static const packSound = [
    'ফাটল-আঁচড় নেই, স্টিক পরিষ্কার আর শুকনো',
    'লেবেল মিলেছে, ল্যাব টেস্টের মেয়াদও আছে',
  ];
  static const packWiped = 'ভেজা ছিল, শুকনো কাপড়ে মুছে তবে নিয়েছি';
  static const packMyths = [
    'শুকনো বাঁশও তো ইনসুলেটর, একই কাজ দেয়',
    'সামান্য আঁচড়ে স্টিকের কিছুই হয় না',
    'একটু ভেজা থাকলেও রডের কিছু হয় না',
    'যেকোনো রেটিংয়ের রডেই ফিউজ খোলা যায়',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিলাম',
    'নতুন দেখতে, তাই খুঁটিয়ে দেখার দরকার নেই',
  ];

  /// Why this rod: its label matched, it was sound — and, only if it was wet
  /// and the player wiped it, that.
  static List<String> packRight(StickRating line, {required bool wiped}) => [packMatch(line), ...packSound, if (wiped) packWiped];

  static List<String> packWrong(StickRating line, {required bool wiped}) => [
        for (final r in StickRating.values)
          if (r != line) packMatch(r),
        if (!wiped) packWiped,
        ...packMyths,
      ];

  /// The careless coworker.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerWet = CoworkerScript(
    line: 'একটু ভেজা, কিছু হবে না! মোছামুছি পরে, আগে ফিউজটা খোলো।',
    exitLine: coworkerExit,
    right: ['আগে শুকনো কাপড়ে মুছে তবে নেব', 'ভেজা রডে লাইভ ফিউজে হাত দেব না', 'স্টিক পুরো শুকনো হলে তবেই কাজ'],
    wrong: [
      'ঠিক, একটু জলে কিছু হবে না',
      'মোছামুছি পরে, আগে ফিউজটা খুলি',
      'ভেজাটাই তুলে নিয়ে চলে যাই',
      'রড তো ফাইবারের, জলে কী হবে',
      'সবাই তো ভেজা রডেই কাজ সারে',
      'কাজ করতে করতেই শুকনো হবে',
    ],
    asks: ['ও বলছে ভেজাতেই চলবে। আপনি কী করবেন?', 'ভেজা রড নেবেন, না মুছে শুকনো করে?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerBamboo = CoworkerScript(
    line: 'শুকনো বাঁশ তো, চলবে! হট স্টিক আনতে গাড়ি পর্যন্ত কে যাবে?',
    exitLine: coworkerExit,
    right: ['রেটেড ফাইবারগ্লাস রডই তুলে নেব', 'বাঁশের ভেতরে আর্দ্রতা, ওটা চলবে না', 'জুগাড় নয়, পরীক্ষিত হট স্টিক চাই'],
    wrong: [
      'ঠিক, শুকনো বাঁশই তো ইনসুলেটর',
      'বাঁশটাই তুলে নিয়ে কাজ সারি',
      'গাড়ি দূরে, হট স্টিক জরুরি নয়',
      'একবার বাঁশ দিয়েই খুলে ফেলি',
      'সবাই তো বাঁশ দিয়েই কাজ সারে',
      'শুকনো বাঁশ রেটেড রডের মতোই চলে',
    ],
    asks: ['ও বলছে বাঁশেই চলবে। আপনি কী করবেন?', 'বাঁশ নেবেন, না রেটেড হট স্টিক?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(StickPush p) => p == StickPush.wet ? coworkerWet : coworkerBamboo;

  /// His lines that have no recording yet (silent, caption held, until then).
  static const toRecord = [
    'একটু ভেজা, কিছু হবে না! মোছামুছি পরে, আগে ফিউজটা খোলো।',
  ];

  static const callHeld = 'ঠিক! রেটিং, তারিখ আর স্টিকের অবস্থা — তবেই রড।';
  static const asideFlaw = 'ঠিক — খারাপ রড বাতিল।';
  static const asideBamboo = 'ঠিক — বাঁশ বাতিল।';
  static const asideOverdue = 'ঠিক — মেয়াদ পেরোনো রড বাতিল।';
  static const wipedDry = 'ভালো — এবার স্টিক শুকনো।';
  static const allSet = 'রডের স্বাস্থ্য দেখায় পাকা হাত! লেবেল, তারিখ, স্টিক — সব দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — লেবেল, তারিখ আর পুরো স্টিক দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtRating = 'ডকেটের সঙ্গে রেটিং মিলিয়েছেন';
  static const caughtWet = 'ভেজা স্টিক মুছে শুকনো করেছেন';
  static const caughtFlaw = 'ক্ষতিগ্রস্ত রড বাতিল';
  static const caughtOverdue = 'মেয়াদ পেরোনো রড বাতিল';
  static const caughtBamboo = 'বাঁশের জুগাড় বাতিল';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
  static const jobs = ['ডিও ফিউজ খোলা', 'AB সুইচ খোলা'];
}

abstract final class HotStickMistakes {
  static const lowRating = DoMistake(
    key: '2.5/hotstick/low-rating',
    textBn: 'রডের রেটিং লাইনের চেয়ে কম — এই রড ওই ভোল্টেজ আটকানোর জন্য নয়। ডকেটের ভোল্টেজ আর রডের লেবেল মিলিয়ে নিন।',
    art: 'assets/game/art/rod_board/pick_33_low.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const bamboo = DoMistake(
    key: '2.5/hotstick/bamboo',
    textBn: 'বাঁশের ভেতরে আর্দ্রতা থাকে — হাই-ভোল্টেজে বিদ্যুৎ পরিবহন করতে পারে। শুধু পরীক্ষিত, রেটেড ফাইবারগ্লাস হট স্টিক।',
    art: 'assets/game/art/distance/bamboo_vs_hot_stick.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const wet = DoMistake(
    key: '2.5/hotstick/wet',
    textBn: 'ভেজা স্টিকের ইনসুলেটিং ক্ষমতা মারাত্মকভাবে কমে যায়। নরম শুকনো কাপড়ে মুছে, পুরো শুকনো করে তবেই কাজ।',
    art: 'assets/game/art/rod_board/dead_rain.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const crack = DoMistake(
    key: '2.5/hotstick/crack',
    textBn: 'স্টিকে ফাটল — ভেতরের ফোমে আর্দ্রতা ঢোকার পথ, ইনসুলেশন ভেতর থেকে নষ্ট হয়। ফাটা রড বাতিল।',
    art: 'assets/game/art/rod_board/check_crack.svg',
    lessonPoint: 0,
  );
  static const scratch = DoMistake(
    key: '2.5/hotstick/deep-scratch',
    textBn: 'গভীর আঁচড় — "সামান্য" নয়: ভেতরে আর্দ্রতা ঢোকে, বাইরে থেকে বোঝা যায় না। এমন রড বাতিল।',
    art: 'assets/game/art/rod_board/check_crack.svg',
    lessonPoint: 0,
  );
  static const glaze = DoMistake(
    key: '2.5/hotstick/glaze',
    textBn: 'বাইরের গ্লেজ নষ্ট, ফাইবার বেরিয়ে আছে — ইনসুলেশন দুর্বল। এমন রড বাতিল।',
    art: 'assets/game/art/rod_board/check_crack.svg',
    lessonPoint: 0,
  );
  static const overdue = DoMistake(
    key: '2.5/hotstick/test-overdue',
    textBn: 'ল্যাবের হাই-ভোল্টেজ পরীক্ষার তারিখ পেরিয়ে গেছে — সাধারণত প্রতি বছর পরীক্ষা হয়। মেয়াদ পেরোনো রড বাতিল।',
    art: 'assets/game/art/rod/rating_match.svg',
    lessonPoint: 3,
  );
  static const all = [lowRating, bamboo, wet, crack, scratch, glaze, overdue];

  static DoMistake forFlaw(StickMark f) => switch (f) {
        StickMark.crack => crack,
        StickMark.scratch => scratch,
        StickMark.glaze => glaze,
        _ => overdue,
      };
}

/// A fresh site each play: dockets, decoys, flaws, the wet rod, stand order,
/// dates and the coworker's moment vary. [today] is the docket's date.
StickDeal dealSticks(math.Random rng, DateTime today) {
  var n = 0;
  final day = DateTime(today.year, today.month, today.day);
  HotStick rod(StickRating? r, [StickMark f = StickMark.none]) => HotStick(
        id: 'stick${n++}',
        rating: r,
        flaw: f,
        due: f == StickMark.overdue ? DateTime(day.year, day.month - 1 - rng.nextInt(4)) : DateTime(day.year, day.month + 2 + rng.nextInt(8)),
      );
  StickDocket docket(StickRating line) => StickDocket(
        line: line,
        jobBn: HotStickLines.jobs[rng.nextInt(HotStickLines.jobs.length)],
        feederBn: HotStickLines.feeders[rng.nextInt(HotStickLines.feeders.length)],
        date: day,
      );
  StickMark damage() => kStickDamage[rng.nextInt(kStickDamage.length)];
  final wetRound = rng.nextBool() ? 0 : 2;

  // 1: 11 kV — the good rod, the bamboo and a bad twin.
  final f1 = rng.nextInt(4) == 0 ? StickMark.overdue : damage();
  final r1 = [
    rod(StickRating.kv11, wetRound == 0 ? StickMark.wet : StickMark.none),
    rod(null),
    rod(StickRating.kv11, f1),
  ]..shuffle(rng);
  // 2: 33 kV — the good rod, a damaged twin, an 11 kV rod and the bamboo.
  final r2 = [rod(StickRating.kv33), rod(StickRating.kv33, damage()), rod(StickRating.kv11), rod(null)]..shuffle(rng);
  // 3: 11 or 33 kV — the good rod, a damaged twin, an overdue twin, and the
  // bamboo (11 kV) or an 11 kV rod (33 kV).
  final last = rng.nextBool() ? StickRating.kv11 : StickRating.kv33;
  final r3 = [
    rod(last, wetRound == 2 ? StickMark.wet : StickMark.none),
    rod(last, damage()),
    rod(last, StickMark.overdue),
    last == StickRating.kv33 ? rod(StickRating.kv11) : rod(null),
  ]..shuffle(rng);
  final rounds = [
    StickRoundDeal(docket: docket(StickRating.kv11), rods: r1),
    StickRoundDeal(docket: docket(StickRating.kv33), rods: r2),
    StickRoundDeal(docket: docket(last), rods: r3),
  ];
  // He comes on a docket where he has something to push.
  final can = [
    for (var i = 0; i < rounds.length; i++)
      if (stickPushFor(rounds[i], const {}, const {}, preferWet: false) != null) i,
  ];
  final call = can[rng.nextInt(can.length)];
  final hasWet = rounds[call].rods.any((r) => r.flaw == StickMark.wet);
  return StickDeal(rounds: rounds, callRound: call, preferWet: hasWet && (rng.nextInt(3) > 0));
}

/// What he can push on docket [r] now: only a rod still on the stand (the
/// wet one only while it is not wiped dry). The dealt push first, else the
/// other; null when neither is there.
StickPush? stickPushFor(StickRoundDeal r, Set<String> rejected, Set<String> wiped, {required bool preferWet}) {
  final wet = r.rods.any((x) => x.flaw == StickMark.wet && !wiped.contains(x.id) && !rejected.contains(x.id));
  final bamboo = r.rods.any((x) => x.bamboo && !rejected.contains(x.id));
  if (preferWet && wet) return StickPush.wet;
  if (bamboo) return StickPush.bamboo;
  return wet ? StickPush.wet : null;
}

enum StickVerdict { right, slip, deadly }

@immutable
class StickOutcome {
  const StickOutcome(this.verdict, {this.mistake});
  final StickVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class HotStickRun {
  HotStickRun(this.deal);
  final StickDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;

  /// This docket is decided (the good rod taken): the reason, then [next].
  bool shown = false;

  /// The good rod was wet and wiped before it was taken (for the reason).
  bool tookWiped = false;

  /// Rods set aside on this docket (tagged বাতিল).
  final Set<String> rejected = {};

  /// Rods whose surface flaw the hand has found (or a card has shown).
  final Set<String> spotted = {};

  /// Rods wiped dry with the cloth on this docket.
  final Set<String> wiped = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  StickRoundDeal get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Is [rod] wet right now (not wiped)?
  bool isWet(HotStick rod) => rod.flaw == StickMark.wet && !wiped.contains(rod.id);

  /// Takes [rod] to the job.
  StickOutcome take(HotStick rod) {
    if (ended || shown || rejected.contains(rod.id)) return const StickOutcome(StickVerdict.slip);
    if (rod.bamboo) return _deadly(HotStickMistakes.bamboo);
    if (rod.rating!.index < current.docket.line.index) return _deadly(HotStickMistakes.lowRating);
    if (isWet(rod)) return _deadly(HotStickMistakes.wet);
    if (kStickDamage.contains(rod.flaw) || rod.flaw == StickMark.overdue) {
      slips++;
      rejected.add(rod.id);
      spotted.add(rod.id);
      return StickOutcome(StickVerdict.slip, mistake: HotStickMistakes.forFlaw(rod.flaw));
    }
    tookWiped = rod.flaw == StickMark.wet;
    _tag(HotStickLines.caughtRating);
    if (tookWiped) _tag(HotStickLines.caughtWet);
    shown = true;
    return const StickOutcome(StickVerdict.right);
  }

  /// The hand found [rod]'s surface flaw.
  void spot(HotStick rod) {
    if (kStickDamage.contains(rod.flaw) || rod.flaw == StickMark.wet) spotted.add(rod.id);
  }

  /// The dry cloth along [rod]: a wet stick is dry after it (true). Wiping a
  /// dry or damaged stick changes nothing (and never costs).
  bool wipe(HotStick rod) {
    if (ended || shown || !isWet(rod)) return false;
    wiped.add(rod.id);
    return true;
  }

  /// Puts [rod] back: the bamboo, an overdue rod (its sticker is in plain
  /// sight in hand) or a damaged rod whose flaw the hand found go aside
  /// (true); anything else back on the stand (false). Never costs anything.
  /// A hidden flaw is never told: a damaged rod goes aside only once the hand
  /// has found it. The overdue rod's date is on screen whenever it is in hand,
  /// so going aside confirms what the sticker already shows (an explicit
  /// "বাতিল" with a slip for tagging a good rod is an open owner question).
  bool putBack(HotStick rod) {
    if (ended || shown || rejected.contains(rod.id)) return false;
    final String tag;
    if (rod.bamboo) {
      tag = HotStickLines.caughtBamboo;
    } else if (rod.flaw == StickMark.overdue) {
      tag = HotStickLines.caughtOverdue;
    } else if (kStickDamage.contains(rod.flaw) && spotted.contains(rod.id)) {
      tag = HotStickLines.caughtFlaw;
    } else {
      return false;
    }
    rejected.add(rod.id);
    _tag(tag);
    return true;
  }

  /// The next docket (after the reason).
  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    wiped.clear();
    tookWiped = false;
    shown = false;
  }

  StickOutcome _deadly(DoMistake m) {
    deadly = m;
    return StickOutcome(StickVerdict.deadly, mistake: m);
  }
}

@immutable
class M2HotstickPack {
  const M2HotstickPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2HotstickPack25 = M2HotstickPack(id: 'do_2_5_a', titleBn: HotStickLines.title);
const m2HotstickPacks = {'do_2_5_a': m2HotstickPack25};

// ============================================================================
// Page
// ============================================================================

class M2HotstickPage extends StatefulWidget {
  const M2HotstickPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.today});

  final LevelContext ctx;
  final M2HotstickPack pack;
  final bool muted;
  final int? seed;

  /// The docket's date (default: today).
  final DateTime? today;

  @override
  State<M2HotstickPage> createState() => _M2HotstickPageState();
}

class _M2HotstickPageState extends State<M2HotstickPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _StickRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        today: widget.today ?? DateTime.now(),
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _StickRunPage extends ConsumerStatefulWidget {
  const _StickRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.today, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2HotstickPack pack;
  final bool muted;
  final DateTime today;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_StickRunPage> createState() => _StickRunPageState();
}

class _StickRunPageState extends ConsumerState<_StickRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final HotStickRun _run = HotStickRun(dealSticks(widget.rng, widget.today));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  HotStick? _held;
  String? _packed;
  var _docketOpen = false;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  StickPush _push = StickPush.bamboo;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;

  var _freeze = false;
  StickFlashKind _flash = StickFlashKind.rating;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The cloth is still going along the held stick (take / put back wait).
  var _wiping = false;

  /// The hand has slid along the held stick at least once (for the hint).
  var _slid = false;

  // Gesture hints: how to touch, never which rod.
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _rodKeys = {};
  final _stickKey = GlobalKey();
  final _clothKey = GlobalKey();
  final _backKey = GlobalKey();
  final _takeKey = GlobalKey();
  final _docketCardKey = GlobalKey();
  GlobalKey _rodKey(String id) => _rodKeys.putIfAbsent(id, GlobalKey.new);

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice ----------------------------------------------------------------

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk}) async {
    if (line.trim().isEmpty || !mounted) return;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted);
  }

  Future<void> _sayChain(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    for (final l in lines) {
      if (!mounted || chain != _chain) return;
      await _say(l, mood: mood);
    }
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  String get _task => _held != null ? HotStickLines.inspectAsk : HotStickLines.ask;

  // ---- flow -----------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([HotStickLines.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || tableBusy || _run.shown || _freeze;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  void _pick(HotStick r, Offset origin) {
    // While he is on screen the stand waits: his deck is the only answer.
    if (_blocked || coworkerOpen || _held != null || _docketOpen || _run.rejected.contains(r.id) || _packed == r.id) return;
    // On his docket the first reach for a rod waits for him (a fast player
    // still meets him, with both his pushes still on the stand).
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.45, muted: false));
    _hush();
    setState(() {
      _held = r;
      _slid = false;
      _wiping = false;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([HotStickLines.inspectAsk]));
  }

  void _found() {
    final r = _held;
    if (r != null) _run.spot(r);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.6, muted: false));
  }

  void _slidOnce() {
    if (_slid || !mounted) return;
    setState(() => _slid = true);
  }

  void _wipeStarted() {
    if (!mounted) return;
    setState(() => _wiping = true);
  }

  void _wiped() {
    final r = _held;
    _wiping = false;
    if (r == null || _blocked) {
      if (mounted) setState(() {});
      return;
    }
    final dried = _run.wipe(r);
    setState(() {});
    if (dried) {
      HapticFeedback.lightImpact();
      unawaited(_sayChain([HotStickLines.wipedDry], mood: GuideMood.glad));
    }
  }

  void _putBack() {
    final r = _held;
    if (r == null || _blocked || _wiping) return;
    final aside = _run.putBack(r);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      final line = r.bamboo ? HotStickLines.asideBamboo : (r.flaw == StickMark.overdue ? HotStickLines.asideOverdue : HotStickLines.asideFlaw);
      unawaited(_sayChain([line, HotStickLines.ask], mood: GuideMood.glad));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
      unawaited(_sayChain([HotStickLines.ask]));
    }
  }

  void _take(Offset origin) {
    final r = _held;
    // Not while the cloth is still going along the stick: it is not dry yet.
    if (r == null || _blocked || _wiping) return;
    setState(() => _held = null);
    final o = _run.take(r);
    switch (o.verdict) {
      case StickVerdict.right:
        HapticFeedback.lightImpact();
        if (!_muted) {
          unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
          unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.5, muted: false));
        }
        setState(() {
          _packed = r.id;
          _setMode(LinemanMode.cheer);
        });
        final line = _run.current.docket.line;
        final wiped = _run.tookWiped;
        _ask(
          wiped ? 20 : 15,
          () => dealChoices(HotStickLines.packRight(line, wiped: wiped), HotStickLines.packWrong(line, wiped: wiped), widget.rng),
          HotStickLines.packAsk,
        );
      case StickVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, origin));
      case StickVerdict.deadly:
        setState(() => _packed = r.id);
        unawaited(_deadly(o.mistake!));
    }
  }

  void _ask(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _packed = null;
      _setMode(LinemanMode.idle);
    });
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([HotStickLines.ask]));
  }

  void _openDocket() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: false));
    setState(() => _docketOpen = true);
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  @override
  bool get reasonMuted => _muted;
  @override
  bool get reasonEnded => _ended;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void reasonHush() => _hush();
  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) => _levelDelta(delta, origin, mood: mood);
  @override
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => HotStickLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    final push = stickPushFor(_run.current, _run.rejected, _run.wiped, preferWet: _run.deal.preferWet);
    // Nothing of his left on this stand (the bamboo aside, the wet rod wiped):
    // his push would no longer fit. His moment passes on this docket; the
    // next docket arms him again ([_armCoworker]).
    if (push == null) return null;
    _push = push;
    if (_blocked || _held != null || _docketOpen || _wiping) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _push == StickPush.wet ? HotStickMistakes.wet : HotStickMistakes.bamboo;
      _run.deadly = m;
      await _deadly(m);
      return;
    }
    _run.caught.add(HotStickLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([HotStickLines.callHeld, HotStickLines.ask], mood: GuideMood.glad);
    }());
  }

  // --- gesture hints (how to touch, never which rod) -------------------------

  /// Waiting for the player's touch at the stand, in hand or on the docket.
  bool get _hintWaiting => !_blocked && !_wiping && !coworkerOnScreen && !struckOut && _mark == null;

  Object get _hintKey => '${_run.round}|${_held?.id}|$_docketOpen|$_slid';

  HintSpec? _hintNow() {
    // The docket up close: a tap anywhere puts it back (one way forward).
    if (_docketOpen) return HintSpec.tapOn(_docketCardKey);
    if (_held != null) {
      if (!_slid) {
        // Run a hand along the stick: a short nudge along it, from its end.
        final r = HintSpec.globalRectOf(_stickKey);
        return r == null ? null : HintSpec.drag(r.centerLeft + Offset(r.width * 0.12, 0), toward: const Offset(1, 0), travel: HintSpec.maxDragTravel);
      }
      // Then one of the three: cloth, put back, take — a sweep over all.
      return HintSpec.sweepOver([_clothKey, _backKey, _takeKey]);
    }
    // At the stand: a sweep over every rod still hanging (none for one).
    final keys = [
      for (final x in _run.current.rods)
        if (!_run.rejected.contains(x.id) && _packed != x.id) _rodKey(x.id),
    ];
    return keys.length < 2 ? null : HintSpec.sweepOver(keys);
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? HotStickLines.tapWhy[_nudgeN++ % HotStickLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes -------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('hotstick/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _held = null;
      _docketOpen = false;
      _flash = m == HotStickMistakes.bamboo ? StickFlashKind.bamboo : (m == HotStickMistakes.wet ? StickFlashKind.wet : StickFlashKind.rating);
      _setMode(LinemanMode.worried);
      _freeze = true;
    });
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('hotstick/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? HotStickLines.deadlyWord : HotStickLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(LinemanMode.idle);
        });
        unawaited(_sayChain([HotStickLines.ask]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  // ---- score and result -----------------------------------------------------

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height * 0.45);
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? HotStickLines.fail : (_quickBonus ? HotStickLines.quick : HotStickLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (deathPending) {
      if (_popped) return;
      _popped = true;
      await dieAndLeave();
      return;
    }
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // ---- build ----------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = StickSiteGeo(m.height);
    final r = _run.current;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final aside = [for (final x in r.rods) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_docketOpen && !coworkerOpen;
    return [
      Positioned.fill(
        key: const ValueKey('site'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hints.missTap,
          child: ColorFiltered(colorFilter: grey, child: RepaintBoundary(child: CustomPaint(painter: StickSitePainter(geo)))),
        ),
      ),
      Positioned.fromRect(
        key: ValueKey('docket-${_run.round}'),
        rect: geo.docket,
        child: ColorFiltered(colorFilter: grey, child: _DocketSheet(docket: r.docket, quiet: quiet, onTap: _openDocket)),
      ),
      for (var i = 0; i < r.rods.length; i++)
        Positioned.fromRect(
          key: ValueKey('slot-${_run.round}-$i'),
          rect: geo.slot(i, r.rods.length),
          child: ColorFiltered(
            colorFilter: grey,
            child: DoDealIn(
              index: i,
              quiet: quiet,
              muted: true,
              child: _StandRod(
                key: _rodKey(r.rods[i].id),
                rod: r.rods[i],
                gone: _run.rejected.contains(r.rods[i].id) || _packed == r.rods[i].id || _held?.id == r.rods[i].id,
                enabled: canPick,
                onTake: (at) => _pick(r.rods[i], at),
              ),
            ),
          ),
        ),
      for (var i = 0; i < aside.length && i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: ColorFiltered(colorFilter: grey, child: _AsideRod(rod: aside[i], quiet: quiet)),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: ColorFiltered(
          colorFilter: grey,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final held = _held;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: FullSceneFrame(
            ctx: widget.ctx,
            titleBn: widget.pack.titleBn,
            scoreKey: _scoreKey,
            levelScore: _runScore,
            muted: _muted,
            onClose: () => unawaited(_leave()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            progress: DoProgress(
              labels: HotStickLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            hint: _hintNow,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            layers: (context, m) => _layers(context, m, quiet),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  rod: held,
                  docket: _run.current.docket,
                  wiped: _run.wiped.contains(held.id),
                  quiet: quiet,
                  onFound: _found,
                  onSlid: _slidOnce,
                  onWipeStart: _wipeStarted,
                  onWiped: _wiped,
                  muted: _muted,
                  onTake: _take,
                  onPutBack: _putBack,
                  stickKey: _stickKey,
                  clothKey: _clothKey,
                  backKey: _backKey,
                  takeKey: _takeKey,
                ),
              if (_docketOpen && playing)
                _DocketZoom(
                  key: const ValueKey('docket-zoom'),
                  cardKey: _docketCardKey,
                  docket: _run.current.docket,
                  quiet: quiet,
                  onClose: () => setState(() => _docketOpen = false),
                ),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null && !_docketOpen && held == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
                          _hush();
                          unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: quiet ? 300 : 2200,
                  consequence: _StickFlash(kind: _flash, quiet: quiet),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: HotStickLines.intro,
                  alarm: 'sounds/van_arrive.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _run.passed
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: _run.caught,
                                quickBonus: _quickBonus,
                                stars: _stars,
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Pieces
// ============================================================================

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _brown = Color(0xFF8C6A2A);
const _grey = Color(0xFF5A6478);
const _bench = Color(0xFF26303B);

/// The docket on the post (design px): line voltage big — tap to read close.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.docket, required this.quiet, required this.onTap});
  final StickDocket docket;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.translate(offset: Offset(0, -30 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(2),
            border: Border(top: BorderSide(color: Colors.grey.shade500, width: 4)),
            boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(HotStickLines.docket, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
              Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
              Text(HotStickLines.lineWord, style: bangla(fontSize: 7, fontWeight: FontWeight.w700, color: _grey, height: 1.1)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(docket.line.lineBn, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: _ink, height: 1.15)),
              ),
              const SizedBox(height: 2),
              Text(docket.jobBn, maxLines: 2, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w700, color: _grey, height: 1.2)),
              Text(docket.feederBn, maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 6, fontWeight: FontWeight.w700, color: _grey, height: 1.2)),
              const Spacer(),
              for (var i = 0; i < 2; i++) Container(height: 0.8, color: const Color(0x33000000), margin: const EdgeInsets.only(top: 3, right: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The docket held up close (tap anywhere to put it back).
class _DocketZoom extends StatelessWidget {
  const _DocketZoom({super.key, required this.cardKey, required this.docket, required this.quiet, required this.onClose});
  final GlobalKey cardKey;
  final StickDocket docket;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                key: cardKey,
                width: 290,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: _brown, size: 22),
                        const SizedBox(width: 8),
                        Text(HotStickLines.docket, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text(HotStickLines.line(docket), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(HotStickLines.job(docket), style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 2),
                    Text(HotStickLines.date(docket), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: _grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rod hanging on the stand, hook up (design px). From here its label is a
/// white tag too small to read and its surface does not show. Tap it, or pull
/// it down off the hook, to take it in hand.
class _StandRod extends StatefulWidget {
  const _StandRod({super.key, required this.rod, required this.gone, required this.enabled, required this.onTake});
  final HotStick rod;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  State<_StandRod> createState() => _StandRodState();
}

class _StandRodState extends State<_StandRod> {
  double _pull = 0;
  Offset _at = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final rod = widget.rod;
    if (widget.gone) return Semantics(label: HotStickLines.rodLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: HotStickLines.rodLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.enabled ? (d) => widget.onTake(d.globalPosition) : null,
        onVerticalDragStart: widget.enabled ? (d) => _at = d.globalPosition : null,
        onVerticalDragUpdate: widget.enabled
            ? (d) {
                _at = d.globalPosition;
                setState(() => _pull = (_pull + d.delta.dy).clamp(0.0, 70.0));
              }
            : null,
        onVerticalDragEnd: widget.enabled
            ? (_) {
                final out = _pull > 26;
                setState(() => _pull = 0);
                if (out) widget.onTake(_at);
              }
            : null,
        child: Transform.translate(
          offset: Offset(0, _pull),
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RotatedBox(quarterTurns: 1, child: CustomPaint(painter: HotStickPainter(build: rod.build, mark: rod.flaw, seen: const {}))),
                ),
                if (!rod.bamboo)
                  Positioned(
                    top: box.maxHeight * 0.52,
                    left: box.maxWidth * 0.5 + 3,
                    child: const _BlankTag(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlankTag extends StatelessWidget {
  const _BlankTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5), border: Border.all(color: const Color(0xFF31363C), width: 0.6)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (var i = 0; i < 3; i++) Container(height: 1.2, color: const Color(0x99555B63))],
      ),
    );
  }
}

/// A rod set aside against the pole, tagged বাতিল.
class _AsideRod extends StatelessWidget {
  const _AsideRod({required this.rod, required this.quiet});
  final HotStick rod;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(-60 * (1 - t), 0), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Transform.rotate(
        angle: 0.08,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(child: RotatedBox(quarterTurns: 1, child: CustomPaint(painter: HotStickPainter(build: rod.build, mark: rod.flaw)))),
            Positioned(
              top: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
                child: Text(HotStickLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The close look, hands on: the rod held up big, its rating label and its
/// lab-test sticker readable; run a hand along the whole stick — a crack, a
/// deep scratch, worn glaze or water shows only where the hand has been. The
/// dry cloth wipes it along its length. Then take it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.rod,
    required this.docket,
    required this.wiped,
    required this.quiet,
    required this.muted,
    required this.onFound,
    required this.onSlid,
    required this.onWipeStart,
    required this.onWiped,
    required this.onTake,
    required this.onPutBack,
    required this.stickKey,
    required this.clothKey,
    required this.backKey,
    required this.takeKey,
  });
  final HotStick rod;
  final StickDocket docket;
  final bool wiped;
  final bool quiet;
  final bool muted;
  final VoidCallback onFound;

  /// The hand has touched the stick (first time).
  final VoidCallback onSlid;

  /// The cloth starts along the stick (take / put back wait for [onWiped]).
  final VoidCallback onWipeStart;
  final VoidCallback onWiped;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  // For the gesture hint (the page reads their rects).
  final GlobalKey stickKey;
  final GlobalKey clothKey;
  final GlobalKey backKey;
  final GlobalKey takeKey;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _seen = {};
  Offset? _hand;
  var _found = false;

  /// The cloth is going along the stick (a one-shot sweep).
  var _wiping = false;
  int _wipes = 0;

  void _touch(Offset p, Size s) {
    if (_wiping) return;
    final b = stickBin(HotStickPainter.stickU(s, p.dx));
    final before = _seen.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kStickBins) _seen.add(x);
    }
    final grew = _seen.length != before;
    if (before == 0 && grew) widget.onSlid();
    final mark = widget.rod.flaw == StickMark.wet && widget.wiped ? StickMark.none : widget.rod.flaw;
    if (!_found && HotStickPainter.markFelt(mark, _seen)) {
      _found = true;
      widget.onFound();
    }
    if (grew || _hand != p) setState(() => _hand = p);
  }

  void _wipe() {
    if (_wiping) return;
    HapticFeedback.selectionClick();
    if (!widget.muted) unawaited(ZlFx.cue('sounds/learn/rush_out.wav', volume: 0.35, muted: false));
    if (widget.quiet) {
      setState(() => _wipes++);
      widget.onWiped();
      return;
    }
    setState(() {
      _wiping = true;
      _wipes++;
    });
    widget.onWipeStart();
  }

  Widget _closeUp(HotStick rod) => LayoutBuilder(
        builder: (context, box) {
          final s = Size(box.maxWidth, box.maxHeight);
          final t = HotStickPainter.thick(s);
          final cy = HotStickPainter.cy(s);
          final x0 = HotStickPainter.x0(s);
          final x1 = HotStickPainter.x1(s);
          return Semantics(
            key: widget.stickKey,
            label: HotStickLines.handLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _touch(d.localPosition, s),
              onPanUpdate: (d) => _touch(d.localPosition, s),
              onPanEnd: (_) => setState(() => _hand = null),
              onPanCancel: () => setState(() => _hand = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: HotStickPainter(build: rod.build, mark: rod.flaw, seen: _seen, wiped: widget.wiped, veil: _bench)),
                  ),
                  if (!rod.bamboo) ...[
                    Positioned(left: x0 + (x1 - x0) * 0.08, top: cy - t / 2 - 30, child: _Tag(text: rod.rating!.tag)),
                    Positioned(left: x0 + (x1 - x0) * 0.44, top: cy + t / 2 + 4, child: _TestSticker(rod: rod)),
                  ],
                  if (_seen.isEmpty && !_wiping) _Puck(at: Offset(x0 + (x1 - x0) * 0.9, cy)),
                  if (_hand != null) _Puck(at: _hand!, live: true),
                  if (_wiping)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('wipe-$_wipes'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 750),
                      curve: Curves.easeInOut,
                      onEnd: () {
                        if (!mounted) return;
                        setState(() => _wiping = false);
                        widget.onWiped();
                      },
                      builder: (_, u, _) => Positioned(
                        left: x0 + (x1 - x0) * u - 22,
                        top: cy - 18,
                        child: const _Cloth(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final rod = widget.rod;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.translate(
              offset: Offset(0, 80 * (1 - t)),
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFB59B62)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: _brown, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(HotStickLines.line(widget.docket),
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                                Text(HotStickLines.date(widget.docket), maxLines: 1, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: _grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AspectRatio(
                    aspectRatio: 2.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4654), _bench]),
                      ),
                      child: Padding(padding: const EdgeInsets.fromLTRB(6, 10, 10, 6), child: _closeUp(rod)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    key: widget.clothKey,
                    width: double.infinity,
                    child: _ClothButton(onTap: _wipe),
                  ),
                  const SizedBox(height: 8),
                  // Dead (and dimmed) while the cloth is still going along.
                  IgnorePointer(
                    ignoring: _wiping,
                    child: Opacity(
                      opacity: _wiping ? 0.45 : 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: KeyedSubtree(
                              key: widget.backKey,
                              child: DoBigButton(
                                label: HotStickLines.putBack,
                                filled: false,
                                onTapUp: (_) {
                                  if (!_wiping) widget.onPutBack();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KeyedSubtree(
                              key: widget.takeKey,
                              child: DoBigButton(
                                label: HotStickLines.take,
                                filled: true,
                                onTapUp: (d) {
                                  if (!_wiping) widget.onTake(d.globalPosition);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The soft dry cloth.
class _ClothButton extends StatelessWidget {
  const _ClothButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE6EEF2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF8FA4B6), width: 1.4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Cloth(size: 26),
              const SizedBox(width: 8),
              Text(HotStickLines.cloth, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A folded cloth (drawn).
class _Cloth extends StatelessWidget {
  const _Cloth({this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: -0.15,
        child: Container(
          width: size,
          height: size * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F0E8),
            borderRadius: BorderRadius.circular(size * 0.18),
            border: Border.all(color: const Color(0xFFB8B3A3), width: 1.2),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (var i = 0; i < 2; i++) Container(height: 1, margin: EdgeInsets.symmetric(horizontal: size * 0.12), color: const Color(0x55A39E8E))],
          ),
        ),
      ),
    );
  }
}

class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 22.0 : 17.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFF31363C), width: 1.4)),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
    );
  }
}

/// The lab's test sticker on the stick: when it was tested, when it is next due.
class _TestSticker extends StatelessWidget {
  const _TestSticker({required this.rod});
  final HotStick rod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFF2E7D32), width: 1.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(HotStickLines.tested(rod), style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: _ink, height: 1.2)),
          Text(HotStickLines.due(rod), style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: _ink, height: 1.2)),
        ],
      ),
    );
  }
}

/// The deadly move in colour over the frozen site: the trainee at the pole
/// puts the rod's hook into the DO fuse's ring; the charge tracks down the
/// stick (over the water, through the bamboo, through a rod rated too low)
/// to his hands. (The lesson: a wet or damaged stick loses its insulating
/// power; bamboo can conduct at high voltage; ratings must match.)
class _StickFlash extends StatelessWidget {
  const _StickFlash({required this.kind, required this.quiet});
  final StickFlashKind kind;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth - 40, 340.0);
        final h = math.min(w * 1.12, box.maxHeight * 0.7);
        final g = StickFlashGeo(Size(w, h));
        final still = Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: StickPoleTopPainter(g))),
            Positioned.fromRect(
              rect: g.figure,
              child: const LinemanFigure(look: LinemanLook.trainee, mode: LinemanMode.hold, mood: LinemanMode.worried, quiet: true),
            ),
          ],
        );
        return Align(
          alignment: const Alignment(0, -0.25),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1700),
            child: still,
            builder: (_, t, child) {
              final pop = (t * 6).clamp(0.0, 1.0);
              return Opacity(
                opacity: pop,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * pop,
                  child: Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SlmColors.danger, width: 2.5),
                      boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          Positioned.fill(child: child!),
                          Positioned.fill(child: CustomPaint(painter: StickFlashPainter(g: g, t: t, kind: kind))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
