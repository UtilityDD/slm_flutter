import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
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
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'rod_van.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 1.5, কাজ 1: "সঠিক রড". Behind the van before the job: read the
// docket's line voltage on the door, take a rod from the rack (its rating
// label is readable only up close), run a hand along the stick and along the
// earth lead to the clamp (cracks, a cut cable, a rusty clamp show only where
// you looked), then take it or put it back (a broken rod or the PVC jugaad
// goes aside, tagged বাতিল). Three dockets, easy to hard; on the last one no
// rod on the rack is right — hold the job (lesson: মিল না থাকলে কাজ শুরু নয়).
// Once a play the careless coworker (level 1's rival, his recorded voice)
// peeps in with the lesson's shortcut: the PVC jugaad, or the 11 kV rod for a
// 33 kV line. He is dealt a docket; on it the decisive controls (lifting a rod
// off the rack, holding the job) wait for him (holdForCoworker), so a fast
// play never skips him. Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md):
// guide first, full scene, corner guide, ◆ on the table → "কেন …?" → next
// docket by itself; the scene takes no input in the praise window (tableBusy).
// Gesture hints (how, never what): a sweep over the docket, every rod on the
// rack and the hold button; in the close look a short slide nudge along the
// rod, then a sweep over put back / take; a tap on the zoomed docket.
//
// Deadly (owner-approved list, MODULE1_LADDER.md step 14): a rod rated below
// the line; the jugaad — so listening to him (he pushes exactly one of those)
// is deadly too. Slips: taking a damaged rod; holding the job when the right
// rod was there (a needless stop costs a slip; the reply stays neutral).
//
// Voice: the guide's lines on device TTS (owner's decision 2026-11-06); the
// coworker in his recorded voice. Art: the van is drawn in code
// (rod_van.dart), the rods too, so rating, build and flaw vary each play;
// the mistake cards use assets/game/art/rod/.

// ============================================================================
// Content
// ============================================================================

/// Line / rod voltage, weakest first.
enum RodRating { lt, kv11, kv33 }

extension RodRatingText on RodRating {
  /// The label printed on a rod.
  String get tag => switch (this) {
        RodRating.lt => 'LT 440V',
        RodRating.kv11 => '11 kV',
        RodRating.kv33 => '33 kV',
      };

  /// The line as the docket names it.
  String get lineBn => switch (this) {
        RodRating.lt => 'এলটি 440 ভি',
        RodRating.kv11 => '11 কেভি',
        RodRating.kv33 => '33 কেভি',
      };
}

enum RodFlaw { none, crack, cable, clamp }

@immutable
class RodItem {
  const RodItem({required this.id, this.rating, this.flaw = RodFlaw.none});
  final String id;

  /// Null: the PVC jugaad (no rating at all).
  final RodRating? rating;
  final RodFlaw flaw;
  bool get jugaad => rating == null;
}

@immutable
class RodDocket {
  const RodDocket({required this.line, required this.feederBn, required this.timeBn});
  final RodRating line;
  final String feederBn;
  final String timeBn;
}

@immutable
class RodRoundDeal {
  const RodRoundDeal({required this.docket, required this.rods});
  final RodDocket docket;
  final List<RodItem> rods;

  /// No rod on the rack is right: the job must be held.
  bool get noneFits => !rods.any((r) => r.rating == docket.line && r.flaw == RodFlaw.none);
}

/// What the careless coworker pushes.
enum RodPush { jugaad, rating }

@immutable
class RodDeal {
  const RodDeal({required this.rounds, required this.callRound, required this.callRating});
  final List<RodRoundDeal> rounds;

  /// The docket on which the careless coworker peeps in (its decisive controls
  /// wait for him; only if he had nothing left to push would he try the next).
  final int callRound;

  /// He pushes the 11 kV rod for a 33 kV line (when that docket is 33 kV);
  /// otherwise the PVC jugaad. If that rod is no longer on the rack (set
  /// aside), he pushes the other one, or waits for the next docket.
  final bool callRating;
}

abstract final class RodLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask, inspectAsk];

  static const title = 'সঠিক রড';
  static const intro = 'শাটডাউনের সময় হয়ে এল! ডকেট দেখে ঠিক রড বাছুন — হাতে নিয়ে যাচাই করে।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const ask = 'ডকেট দেখুন। কোন রডটা?';
  static const inspectAsk = 'হাত বুলিয়ে স্টিক, কেবিল আর ক্ল্যাম্প দেখুন। নেবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const lineWord = 'লাইন';
  static String line(RodDocket d) => 'লাইন: ${d.line.lineBn} · ${d.feederBn}';
  static String shutdown(RodDocket d) => 'শাটডাউন ${d.timeBn}';
  static const rodLabel = 'রড';
  static const handLabel = 'রড হাতে';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const hold = 'কোনোটাই ঠিক নয় — কাজ স্থগিত';
  static const rejected = 'বাতিল';

  // The reasons (lesson 1.5): the right ones fit what this docket and this
  // rack had. Every card is 33–43 letters, so none stands out by its length.
  static const packAsk = 'কেন এই রডটা নিলেন?';
  static const holdAsk = 'কেন কাজ স্থগিত করলেন?';
  static String packMatch(RodRating r) => 'ডকেটে ${r.lineBn}, রডের লেবেলেও ${r.lineBn}';
  static const packSound = [
    'স্টিক শুকনো, ফাটলহীন; কেবিল-ক্ল্যাম্প মজবুত',
    'লেবেল মিলেছে, স্টিক-কেবিল-ক্ল্যাম্পও ঠিক',
  ];
  static const packMyths = [
    'যেকোনো রেটিংয়ের রডেই কাজ চলে যায়',
    'লাইন তো বন্ধ, রড শুধু নিয়মরক্ষার জন্য',
    'প্লাস্টিকের হাতল হলেই রড নিরাপদ হয়',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিলাম',
    'নতুন দেখতে, তাই খুঁটিয়ে দেখার দরকার নেই',
  ];

  /// Why this rod, on a [line] docket: its label matched, and it was sound.
  static List<String> packRight(RodRating line) => [packMatch(line), ...packSound];

  /// The other dockets' matches (true elsewhere, not here) and the myths.
  static List<String> packWrong(RodRating line) => [
        for (final r in RodRating.values)
          if (r != line) packMatch(r),
        ...packMyths,
      ];

  static String flawWhy(RodRating line, RodFlaw f) => switch (f) {
        RodFlaw.crack => 'একমাত্র ${line.lineBn} রডের স্টিকেই ফাটল',
        RodFlaw.cable => 'একমাত্র ${line.lineBn} রডের কেবিলটা কাটা',
        _ => 'একমাত্র ${line.lineBn} রডের ক্ল্যাম্পে মরিচা',
      };
  static const holdSound = [
    'ঠিক রেটিংয়ের ভালো রড নেই, তাই কাজ নয়',
    'মিল না থাকলে কাজ শুরু নয়, আগে জানাই',
  ];
  static const holdExcuses = [
    'শাটডাউনের সময় কম, তাই কাজটা বাদ দিলাম',
    'রড বয়ে নিতে ভারী লাগছিল, তাই নিলাম না',
    'স্টোরকিপার বকবে, তাই কোনো রড নিইনি',
    'সুপারভাইজার না এলে কাজ শুরুই হয় না',
    'রোদ বেশি, দুপুরে কাজ না করাই ভালো',
  ];

  static RodFlaw _heldFlaw(RodRoundDeal r) =>
      r.rods.firstWhere((x) => x.rating == r.docket.line, orElse: () => const RodItem(id: '-')).flaw;

  /// Why the job was held: the rule, and — only when the player has seen it
  /// ([flawKnown]: found by hand, or shown on a card) — what the right-rated
  /// rod had.
  static List<String> holdRight(RodRoundDeal r, {required bool flawKnown}) {
    final f = _heldFlaw(r);
    return [if (flawKnown && f != RodFlaw.none) flawWhy(r.docket.line, f), ...holdSound];
  }

  /// The excuses, and (when the fault is known) the faults it did not have —
  /// a fault the player never looked for is never put to him as a card.
  static List<String> holdWrong(RodRoundDeal r, {required bool flawKnown}) {
    final f = _heldFlaw(r);
    return [
      if (flawKnown && f != RodFlaw.none)
        for (final x in const [RodFlaw.crack, RodFlaw.cable, RodFlaw.clamp])
          if (x != f) flawWhy(r.docket.line, x),
      ...holdExcuses,
    ];
  }

  /// The careless coworker (his recorded voice): the lesson's shortcuts.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerJugaad = CoworkerScript(
    line: 'পিভিসি পাইপ তো প্লাস্টিক — এটা দিয়েই রডের কাজ চলবে!',
    exitLine: coworkerExit,
    right: ['না — স্টোরের স্ট্যান্ডার্ড রড নেব', 'প্লাস্টিক দেখে নিরাপদ ভাবব না', 'জুগাড় নয়, রেটিং মেলানো রড চাই'],
    wrong: [
      'ঠিক বলেছ, পিভিসি তো প্লাস্টিকই',
      'জুগাড়টাই তাহলে তুলে নিয়ে যাই',
      'রডটা হালকা, জুগাড়টাই নিয়ে যাই',
      'একবার জুগাড় দিয়েই চালিয়ে নিই',
      'সবাই তো জুগাড় দিয়েই কাজ সারে',
    ],
    asks: ['ও বলছে জুগাড়েই চলবে। আপনি কী করবেন?', 'জুগাড় নেবেন, না স্ট্যান্ডার্ড রড?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerRating = CoworkerScript(
    line: 'রড তো রডই! 11 কেভিরটাই নিয়ে চলো, 33 কেভিতেও চলবে।',
    exitLine: coworkerExit,
    right: ['না — 33 কেভি লাইনে 33 কেভি রড', 'নিচু রেটিংয়ের রড কখনো নেব না', 'লেবেল না মিললে রড নেব না'],
    wrong: [
      'ঠিক, 11 কেভিরটাই নিয়ে যাই',
      'রড তো রডই, যেটা হোক নিই',
      'লাইন তো বন্ধ, যেকোনোটা চলে',
      'একবার 11 কেভিতেই চালিয়ে নিই',
      'সবাই তো যেটা পায় সেটাই নেয়',
    ],
    asks: ['ও বলছে 11 কেভিরটাই চলবে। আপনি কী করবেন?', 'নিচু রেটিং নেবেন, না লেবেল মিলিয়ে?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(RodPush p) => p == RodPush.jugaad ? coworkerJugaad : coworkerRating;

  static const callHeld = 'ঠিক! রেটিং আর অবস্থা মিলিয়েই রড।';
  static const asideFlaw = 'ঠিক — ভাঙা রড বাতিল।';
  static const asideJugaad = 'ঠিক — জুগাড় বাতিল।';
  static const allSet = 'রড বাছাইয়ে পাকা হাত! লেবেল আর অবস্থা — দুটোই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — লেবেল আর অবস্থা দুটোই দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtRating = 'ডকেটের সঙ্গে রেটিং মিলিয়েছেন';
  static const caughtHold = 'ঠিক রড না পেয়ে কাজ স্থগিত';
  static const caughtFlaw = 'ভাঙা রড বাতিল';
  static const caughtJugaad = 'জুগাড় রড বাতিল';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
  static const times = ['10:00–14:00', '09:30–13:00', '11:00–15:30', '08:00–12:00'];
}

abstract final class RodMistakes {
  static const wrongRating = DoMistake(
    key: '1.5/rod/wrong-rating',
    textBn: 'রডের রেটিং লাইনের চেয়ে কম — ইনসুলেশন ভেঙে যাওয়ার ঝুঁকি, এমন রড জীবন নিতে পারে। ডকেটের ভোল্টেজ আর রডের লেবেল মিলিয়ে নিন।',
    art: 'assets/game/art/rod/rating_match.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const jugaad = DoMistake(
    key: '1.5/rod/jugaad',
    textBn: 'পিভিসি পাইপের জুগাড় রড নয় — ফাটতে পারে, ভেজা-ময়লায় লিক হতে পারে। স্টোরের স্ট্যান্ডার্ড রড ছাড়া কাজ নয়।',
    art: 'assets/game/art/rod/jugaad_vs_standard.svg',
    deadly: true,
    lessonPoint: 4,
  );
  static const crack = DoMistake(
    key: '1.5/rod/cracked-stick',
    textBn: 'স্টিকে ফাটল — ভাঙা রড নিজেই বিদ্যুৎ পরিবাহী হয়ে উঠতে পারে। স্টিক পরিষ্কার, শুকনো, ফাটলমুক্ত চাই। ফাটা রড বাতিল।',
    art: 'assets/game/art/rod/rod_flaws.svg',
    lessonPoint: 2,
  );
  static const cable = DoMistake(
    key: '1.5/rod/cut-cable',
    textBn: 'কপার কেবিলের ইনসুলেশন কাটা — কেবিল অক্ষত আর দুই প্রান্তের কানেকশন মজবুত চাই। এমন রড বাতিল।',
    art: 'assets/game/art/rod/rod_flaws.svg',
    lessonPoint: 2,
  );
  static const clamp = DoMistake(
    key: '1.5/rod/rusty-clamp',
    textBn: 'ক্ল্যাম্পে মরিচা — ক্ল্যাম্প পরিষ্কার আর তার গ্রিপ মজবুত চাই। এমন রড বাতিল।',
    art: 'assets/game/art/rod/rod_flaws.svg',
    lessonPoint: 2,
  );
  static const heldWhenRight = DoMistake(
    key: '1.5/rod/held-when-right',
    textBn: 'সঠিক রডটা র‍্যাকেই ছিল — লেবেল আর অবস্থা ভালো করে দেখুন।',
    art: 'assets/game/art/rod/rating_match.svg',
    lessonPoint: 3,
  );
  static const all = [wrongRating, jugaad, crack, cable, clamp, heldWhenRight];
}

RodFlaw _anyFlaw(math.Random rng) => const [RodFlaw.crack, RodFlaw.cable, RodFlaw.clamp][rng.nextInt(3)];

RodRating _below(RodRating r) => r == RodRating.kv33 ? RodRating.kv11 : RodRating.lt;

/// A fresh rack each play: dockets, decoys, flaws, rack order and the
/// coworker's moment vary.
RodDeal dealRods(math.Random rng) {
  var n = 0;
  RodItem rod(RodRating? r, [RodFlaw f = RodFlaw.none]) => RodItem(id: 'rod${n++}', rating: r, flaw: f);
  RodDocket docket(RodRating line) => RodDocket(
        line: line,
        feederBn: RodLines.feeders[rng.nextInt(RodLines.feeders.length)],
        timeBn: RodLines.times[rng.nextInt(RodLines.times.length)],
      );

  // 1: easy — one right rod, the jugaad and one plain decoy.
  final first = rng.nextBool() ? RodRating.kv11 : RodRating.lt;
  final r1 = [
    rod(first),
    rod(null),
    first == RodRating.kv11 ? rod(RodRating.lt) : rod(RodRating.lt, _anyFlaw(rng)),
  ]..shuffle(rng);
  // 2: 33 kV — the right rod, a damaged twin, a lower rating and the jugaad.
  final r2 = [rod(RodRating.kv33), rod(RodRating.kv33, _anyFlaw(rng)), rod(RodRating.kv11), rod(null)]..shuffle(rng);
  // 3: nothing fits — damaged right rating, a lower rating, the jugaad.
  final last = rng.nextBool() ? RodRating.kv11 : RodRating.kv33;
  final r3 = [rod(last, _anyFlaw(rng)), rod(_below(last)), rod(null)]..shuffle(rng);
  final rounds = [
    RodRoundDeal(docket: docket(first), rods: r1),
    RodRoundDeal(docket: docket(RodRating.kv33), rods: r2),
    RodRoundDeal(docket: docket(last), rods: r3),
  ];
  final call = rng.nextInt(rounds.length);
  return RodDeal(rounds: rounds, callRound: call, callRating: rounds[call].docket.line == RodRating.kv33 && rng.nextBool());
}

/// What the careless coworker can push on docket [r] now: only a rod still on
/// the rack (never the jugaad once it hangs on the door tagged বাতিল); the
/// 11 kV rod only on a 33 kV docket. The dealt push first ([preferRating]),
/// else the other; null when neither is there.
RodPush? rodPushFor(RodRoundDeal r, Set<String> rejected, {required bool preferRating}) {
  final rating = r.docket.line == RodRating.kv33 && r.rods.any((x) => x.rating == RodRating.kv11 && !rejected.contains(x.id));
  final jugaad = r.rods.any((x) => x.jugaad && !rejected.contains(x.id));
  if (preferRating && rating) return RodPush.rating;
  if (jugaad) return RodPush.jugaad;
  return rating ? RodPush.rating : null;
}

enum RodVerdict { right, slip, deadly }

@immutable
class RodOutcome {
  const RodOutcome(this.verdict, {this.mistake});
  final RodVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class RodRun {
  RodRun(this.deal);
  final RodDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;

  /// This docket is decided (the right rod taken, or the job held): the
  /// reason comes, then [next].
  bool shown = false;

  /// Rods set aside on this docket (broken ones taken by mistake, or put aside).
  final Set<String> rejected = {};

  /// Rods on this docket whose flaw the player has seen: found by hand in the
  /// close look ([spot]), or shown on the card after taking it.
  final Set<String> spotted = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  RodRoundDeal get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Takes [rod] for the job.
  RodOutcome take(RodItem rod) {
    if (ended || shown || rejected.contains(rod.id)) return const RodOutcome(RodVerdict.slip);
    final line = current.docket.line;
    if (rod.jugaad) return _deadly(RodMistakes.jugaad);
    if (rod.rating!.index < line.index) return _deadly(RodMistakes.wrongRating);
    if (rod.flaw != RodFlaw.none) {
      slips++;
      rejected.add(rod.id);
      spotted.add(rod.id);
      return RodOutcome(RodVerdict.slip, mistake: switch (rod.flaw) {
        RodFlaw.crack => RodMistakes.crack,
        RodFlaw.cable => RodMistakes.cable,
        _ => RodMistakes.clamp,
      });
    }
    _tag(RodLines.caughtRating);
    shown = true;
    return const RodOutcome(RodVerdict.right);
  }

  /// The player's hand found [rod]'s flaw in the close look.
  void spot(RodItem rod) {
    if (ended || shown) return;
    if (rod.flaw != RodFlaw.none) spotted.add(rod.id);
  }

  /// The right-rated rod of this docket is damaged, and the player has seen how.
  bool get flawKnown =>
      current.rods.any((x) => x.rating == current.docket.line && x.flaw != RodFlaw.none && spotted.contains(x.id));

  /// Puts [rod] back: the jugaad (it is PVC to the eye), or a broken rod whose
  /// flaw the player found, goes aside (true); anything else goes back on the
  /// rack (false) — putting back never tells which rods are broken. Never
  /// costs anything.
  bool putBack(RodItem rod) {
    if (ended || shown || rejected.contains(rod.id)) return false;
    if (!rod.jugaad && !spotted.contains(rod.id)) return false;
    rejected.add(rod.id);
    _tag(rod.jugaad ? RodLines.caughtJugaad : RodLines.caughtFlaw);
    return true;
  }

  /// "কোনোটাই ঠিক নয় — কাজ স্থগিত".
  RodOutcome holdJob() {
    if (ended || shown) return const RodOutcome(RodVerdict.slip);
    if (!current.noneFits) {
      slips++;
      return const RodOutcome(RodVerdict.slip, mistake: RodMistakes.heldWhenRight);
    }
    _tag(RodLines.caughtHold);
    shown = true;
    return const RodOutcome(RodVerdict.right);
  }

  /// The next docket (after the reason).
  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    shown = false;
  }

  RodOutcome _deadly(DoMistake m) {
    deadly = m;
    return RodOutcome(RodVerdict.deadly, mistake: m);
  }
}

@immutable
class RodPickPack {
  const RodPickPack({required this.id, required this.titleBn, this.quickMs = 70000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const rodPickPack15 = RodPickPack(id: 'do_1_5_a', titleBn: RodLines.title);
const rodPickPacks = {'do_1_5_a': rodPickPack15};

// ============================================================================
// Page
// ============================================================================

class RodPickPage extends StatefulWidget {
  const RodPickPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final RodPickPack pack;
  final bool muted;
  final int? seed;

  @override
  State<RodPickPage> createState() => _RodPickPageState();
}

class _RodPickPageState extends State<RodPickPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RodRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _RodRunPage extends ConsumerStatefulWidget {
  const _RodRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final RodPickPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RodRunPage> createState() => _RodRunPageState();
}

class _RodRunPageState extends ConsumerState<_RodRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final RodRun _run = RodRun(dealRods(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;

  /// The rod in the trainee's hands (the close look), and the one packed.
  RodItem? _held;
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
  RodPush _push = RodPush.jugaad;

  /// The trainee's pose (moves a few seconds after each change).
  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;

  /// A deadly move: the van freezes grey, the consequence plays in colour.
  var _freeze = false;
  var _flashJugaad = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hint (how to touch, never what): taps on nothing count.
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _sceneKeys = {};
  GlobalKey _sceneKey(String id) => _sceneKeys.putIfAbsent(id, GlobalKey.new);
  final _holdKey = GlobalKey();
  final _zoomKey = GlobalKey();
  final _closeUpKey = GlobalKey();
  final _takeKey = GlobalKey();
  final _backKey = GlobalKey();

  /// The hand has run along the stick / the lead of the rod in the close look.
  var _slidStick = false;
  var _slidLead = false;

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

  // ---- voice (never holds the player) -------------------------------------------

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

  String get _task => _held != null ? RodLines.inspectAsk : RodLines.ask;

  // ---- flow -----------------------------------------------------------------------

  /// After the guide's intro: the clock runs and he gives the first task.
  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([RodLines.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || tableBusy || _run.shown || _freeze;

  /// The decisive controls of his docket wait for him (when he has a rod on
  /// the rack to push; else his moment moves on).
  bool _waitForHim() => rodPushFor(_run.current, _run.rejected, preferRating: _run.deal.callRating) != null && holdForCoworker();

  /// A tap that hit nothing to work with (gesture hint after a few).
  void _missTap() {
    if (!_blocked && !coworkerOnScreen) _hints.missTap();
  }

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// A rod comes off the rack into the trainee's hands.
  void _pick(RodItem r, Offset origin) {
    // Taking another rod while he is still talking refuses him too.
    if (coworkerOpen && !coworkerChoiceUp && !_isPushed(r)) unawaited(answerCoworker(true, origin, direct: true));
    if (_blocked || coworkerOpen || _held != null || _docketOpen || _run.rejected.contains(r.id) || _packed == r.id) return;
    // His docket: the rod stays on the rack until he has spoken.
    if (_waitForHim()) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.45, muted: false));
    _hush();
    setState(() {
      _held = r;
      _slidStick = false;
      _slidLead = false;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([RodLines.inspectAsk]));
  }

  bool _isPushed(RodItem r) => _push == RodPush.jugaad ? r.jugaad : r.rating == RodRating.kv11;

  /// A flaw came into view under the hand.
  void _found() {
    final r = _held;
    if (r != null) _run.spot(r);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.6, muted: false));
  }

  void _putBack() {
    final r = _held;
    if (r == null || _blocked) return;
    final aside = _run.putBack(r);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([r.jugaad ? RodLines.asideJugaad : RodLines.asideFlaw, RodLines.ask], mood: GuideMood.glad));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
      unawaited(_sayChain([RodLines.ask]));
    }
  }

  void _take(Offset origin) {
    final r = _held;
    if (r == null || _blocked) return;
    setState(() => _held = null);
    final o = _run.take(r);
    switch (o.verdict) {
      case RodVerdict.right:
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
        _ask(15, () => dealChoices(RodLines.packRight(line), RodLines.packWrong(line), widget.rng), RodLines.packAsk);
      case RodVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, origin));
      case RodVerdict.deadly:
        // The rod stays in his hands (off the rack) while the scene freezes.
        setState(() => _packed = r.id);
        unawaited(_deadly(o.mistake!));
    }
  }

  void _holdJob(Offset origin) {
    if (_blocked || coworkerOpen || _held != null || _docketOpen) return;
    if (_waitForHim()) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == RodVerdict.right) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      final r = _run.current;
      final known = _run.flawKnown;
      _ask(
        20,
        () => dealChoices(RodLines.holdRight(r, flawKnown: known), RodLines.holdWrong(r, flawKnown: known), widget.rng),
        RodLines.holdAsk,
      );
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  /// A right move: the ◆ wait on the table, then "কেন …?".
  void _ask(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  /// The next docket (or the result) — by itself, after the reason.
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
    unawaited(_sayChain([RodLines.ask]));
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
  CoworkerScript get coworkerScript => RodLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    // He pushes only a rod still on the rack (never the jugaad once it hangs
    // on the door tagged বাতিল, the 11 kV rod only on a 33 kV docket). With
    // nothing left to push he tries the next docket; after the last, never.
    final push = rodPushFor(_run.current, _run.rejected, preferRating: _run.deal.callRating);
    if (push == null) return _run.round >= _run.deal.rounds.length - 1 ? null : false;
    // Never in the praise window (tableBusy is in _blocked), nor once this
    // docket is decided, nor over a rod in hand or the docket held up close.
    if (_blocked || _held != null || _docketOpen) return false;
    _push = push;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Took what he pushed: the jugaad, or the 11 kV rod for a 33 kV line.
      final m = _push == RodPush.jugaad ? RodMistakes.jugaad : RodMistakes.wrongRating;
      _run.deadly = m;
      await _deadly(m);
      return;
    }
    _run.caught.add(RodLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([RodLines.callHeld, RodLines.ask], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? RodLines.tapWhy[_nudgeN++ % RodLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes ---------------------------------------------------------------------

  /// The third small mistake: the level fails and the lesson card insists.
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
    final speak = await SpokenOnce.first('rod/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the van freezes grey, the rod flashes over in colour,
  /// then the card.
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
      _flashJugaad = m == RodMistakes.jugaad;
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
    final speak = await SpokenOnce.first('rod/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? RodLines.deadlyWord : RodLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(LinemanMode.idle);
        });
        unawaited(_sayChain([RodLines.ask]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  // ---- score and result ---------------------------------------------------------------

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
    await _say(!_run.passed ? RodLines.fail : (_quickBonus ? RodLines.quick : RodLines.allSet),
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

  // ---- gesture hint (how to touch, never what) -------------------------------------

  /// The level waits for the player's hands now (no intro, card, deck, his
  /// beat, praise window, freeze or result).
  bool get _hintWaiting =>
      !_intro && _mark == null && !struckOut && !_freeze && !_busy && !_ended && _card == null && !tableBusy && !_run.shown && !coworkerOnScreen;

  Object get _hintKey => '${_run.round}·${_held?.id}·$_docketOpen·${_run.rejected.length}';

  HintSpec? _hintNow() {
    if (_docketOpen) return HintSpec.tapOn(_zoomKey);
    if (_held != null) {
      // Not felt along yet: a short slide nudge from the hook end (a generic
      // direction along the rod; it never travels to a fault).
      if (!_slidStick || !_slidLead) {
        final r = HintSpec.globalRectOf(_closeUpKey);
        if (r == null) return null;
        final y = r.top + r.height * (!_slidStick ? 0.36 : 0.8);
        return HintSpec.drag(Offset(r.left + r.width * 0.14, y), toward: const Offset(1, 0), travel: 72);
      }
      return HintSpec.sweepOver([_backKey, _takeKey]);
    }
    // At the van: every choice the same way — the docket, each rod still on
    // the rack (in its rack order), the hold button.
    final r = _run.current;
    return HintSpec.sweepOver([
      _sceneKey('docket-${_run.round}'),
      for (final x in r.rods)
        if (!_run.rejected.contains(x.id) && _packed != x.id) _sceneKey(x.id),
      _holdKey,
    ]);
  }

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = RodVanGeo(m.height);
    final r = _run.current;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final aside = [for (final x in r.rods) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_docketOpen;
    return [
      Positioned.fill(
        key: const ValueKey('van'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _missTap,
          child: ColorFiltered(colorFilter: grey, child: RepaintBoundary(child: CustomPaint(painter: RodVanPainter(geo)))),
        ),
      ),
      // The docket on the left door (tap to read it close).
      Positioned.fromRect(
        key: ValueKey('docket-${_run.round}'),
        rect: geo.docket,
        child: ColorFiltered(
          key: _sceneKey('docket-${_run.round}'),
          colorFilter: grey,
          child: _DocketSheet(docket: r.docket, quiet: quiet, onTap: _openDocket),
        ),
      ),
      // The rack: one slot per rod (the rod's slot stays, empty, once it is gone).
      for (var i = 0; i < r.rods.length; i++)
        Positioned.fromRect(
          key: ValueKey('slot-${_run.round}-$i'),
          rect: geo.slot(i, r.rods.length),
          child: ColorFiltered(
            key: _sceneKey(r.rods[i].id),
            colorFilter: grey,
            child: DoDealIn(
              index: i,
              quiet: quiet,
              muted: true,
              child: _RackRod(
                rod: r.rods[i],
                gone: _run.rejected.contains(r.rods[i].id) || _packed == r.rods[i].id || _held?.id == r.rods[i].id,
                enabled: canPick,
                onTake: (at) => _pick(r.rods[i], at),
              ),
            ),
          ),
        ),
      // Rods set aside lean on the right door, tagged বাতিল.
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
    final holdUp = playing && _held == null && !_docketOpen && _card == null && !deckUp && !_run.shown && !coworkerOpen;
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
              labels: RodLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hintNow,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (holdUp)
                Positioned(
                  key: const ValueKey('hud-hold'),
                  left: 12,
                  right: 128,
                  bottom: pad.bottom + 18,
                  child: _HoldButton(key: _holdKey, onTapUp: (d) => _holdJob(d.globalPosition)),
                ),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  rod: held,
                  docket: _run.current.docket,
                  quiet: quiet,
                  onFound: _found,
                  onTake: _take,
                  onPutBack: _putBack,
                  onSlid: (stick) => stick ? _slidStick = true : _slidLead = true,
                  onMiss: _missTap,
                  closeUpKey: _closeUpKey,
                  takeKey: _takeKey,
                  backKey: _backKey,
                ),
              if (_docketOpen && playing)
                _DocketZoom(
                  key: const ValueKey('docket-zoom'),
                  cardKey: _zoomKey,
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
              if (playing && _card == null && !_docketOpen)
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
                  consequence: _RodFlash(jugaad: _flashJugaad, quiet: quiet),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: RodLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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

/// Behind the rod in the close look (and the wash over what is not looked at yet).
const _bench = Color(0xFF26303B);

/// The docket sheet on the clipboard (design px): the line's voltage big,
/// the rest small — tap it to read it close.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.docket, required this.quiet, required this.onTap});
  final RodDocket docket;
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(RodLines.docket, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
                    Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
                    Text(RodLines.lineWord, style: bangla(fontSize: 7, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.1)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(docket.line.lineBn, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: _ink, height: 1.15)),
                    ),
                    const SizedBox(height: 2),
                    Text(docket.feederBn, maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.2)),
                    Text(RodLines.shutdown(docket), maxLines: 2, style: bangla(fontSize: 6, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.2)),
                    const Spacer(),
                    for (var i = 0; i < 3; i++) Container(height: 0.8, color: const Color(0x33000000), margin: const EdgeInsets.only(top: 3, right: 10)),
                  ],
                ),
              ),
            ),
            // The clip.
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 28,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD9DEE2), Color(0xFF8D969E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The docket held up close (tap anywhere to put it back on the door).
class _DocketZoom extends StatelessWidget {
  const _DocketZoom({super.key, required this.cardKey, required this.docket, required this.quiet, required this.onClose});
  final GlobalKey cardKey;
  final RodDocket docket;
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
                width: 280,
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
                        Text(RodLines.docket, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text(RodLines.line(docket), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(RodLines.shutdown(docket), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
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

/// A rod standing in the rack, hook up (design px). At this distance its
/// label is a white tag too small to read and its flaws do not show. Tap it,
/// or pull it down out of the rack, to take it in hand.
class _RackRod extends StatefulWidget {
  const _RackRod({required this.rod, required this.gone, required this.enabled, required this.onTake});
  final RodItem rod;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  State<_RackRod> createState() => _RackRodState();
}

class _RackRodState extends State<_RackRod> {
  double _pull = 0;
  Offset _at = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final rod = widget.rod;
    if (widget.gone) return Semantics(label: RodLines.rodLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: RodLines.rodLabel,
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
                  child: RotatedBox(quarterTurns: 1, child: CustomPaint(painter: RodPainter(rod, seenStick: const {}, seenLead: const {}))),
                ),
                if (rod.rating != null)
                  Positioned(
                    top: box.maxHeight * 0.3,
                    left: box.maxWidth * 0.64 - 7,
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

/// The rating label seen from a step away: a white tag, its print too small to read.
class _BlankTag extends StatelessWidget {
  const _BlankTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5), border: Border.all(color: const Color(0xFF31363C), width: 0.6)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (var i = 0; i < 3; i++) Container(height: 1.2, color: const Color(0x99555B63))],
      ),
    );
  }
}

/// A rod set aside on the right door, tagged বাতিল.
class _AsideRod extends StatelessWidget {
  const _AsideRod({required this.rod, required this.quiet});
  final RodItem rod;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(-60 * (1 - t), 0), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Transform.rotate(
        angle: -0.1,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(child: RotatedBox(quarterTurns: 1, child: CustomPaint(painter: RodPainter(rod)))),
            Positioned(
              top: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
                child: Text(RodLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "কোনোটাই ঠিক নয় — কাজ স্থগিত", readable on the road.
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1A33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.85), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pan_tool_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(RodLines.hold,
                    textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The close look, hands on: the rod held up big, its label readable; run a
/// finger along the stick, and along the earth lead to the clamp — a crack, a
/// cut or rust shows only where the hand has been. Then take it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.rod,
    required this.docket,
    required this.quiet,
    required this.onFound,
    required this.onTake,
    required this.onPutBack,
    required this.onSlid,
    required this.onMiss,
    required this.closeUpKey,
    required this.takeKey,
    required this.backKey,
  });
  final RodItem rod;
  final RodDocket docket;
  final bool quiet;
  final VoidCallback onFound;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  /// The hand ran along the stick (true) or the lead (false).
  final ValueChanged<bool> onSlid;

  /// A tap on the dim backdrop (nothing to work with there).
  final VoidCallback onMiss;
  final GlobalKey closeUpKey;
  final GlobalKey takeKey;
  final GlobalKey backKey;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _stick = {};
  final Set<int> _lead = {};
  Offset? _hand;
  var _found = false;

  void _touch(Offset p, Size s) {
    final stick = p.dy < s.height * 0.52;
    final u = stick ? RodPainter.stickU(s, p.dx) : RodPainter.leadU(s, p.dx);
    final b = rodBin(u);
    final set = stick ? _stick : _lead;
    final before = set.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kRodBins) set.add(x);
    }
    final grew = set.length != before;
    if (grew && set.length >= 6) widget.onSlid(stick);
    if (!_found && RodPainter.flawSeen(widget.rod, _stick, _lead)) {
      _found = true;
      widget.onFound();
    }
    if (grew || _hand != p) setState(() => _hand = p);
  }

  Widget _closeUp(RodItem rod) => LayoutBuilder(
      builder: (context, box) {
        final s = Size(box.maxWidth, box.maxHeight);
        return Semantics(
          key: widget.closeUpKey,
          label: RodLines.handLabel,
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
                  child: CustomPaint(painter: RodPainter(rod, seenStick: _stick, seenLead: _lead, veil: _bench)),
                ),
                if (rod.rating != null)
                  Positioned(
                    left: s.width * 0.3,
                    top: s.height * 0.36 - s.height * 0.13 * 0.5 - 30,
                    child: _Tag(text: rod.rating!.tag),
                  ),
                // Where to run the hand: along the stick, along the lead.
                if (_stick.isEmpty) _Puck(at: Offset(s.width * 0.86, s.height * 0.36)),
                if (_lead.isEmpty) _Puck(at: RodPainter.leadAt(s, 0.25)),
                if (_hand != null) _Puck(at: _hand!, live: true),
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onMiss,
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
                    // The docket, clipped beside the rod.
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
                              child: Text('${RodLines.docket} · ${RodLines.line(widget.docket)}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AspectRatio(
                      aspectRatio: 2.1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF3A4654), _bench],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 18, 16, 2),
                          child: _closeUp(rod),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: DoBigButton(key: widget.backKey, label: RodLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                        const SizedBox(width: 12),
                        Expanded(child: DoBigButton(key: widget.takeKey, label: RodLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
                      ],
                    ),
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

/// A gloved hand's mark: where to slide (still), or under the finger.
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF31363C), width: 1.4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
    );
  }
}

/// How many stretches the stick and the lead are looked at in.
const kRodBins = 20;
int rodBin(double u) => (u * kRodBins).floor().clamp(0, kRodBins - 1);

/// A discharge rod drawn lengthwise (hook at the left): fibreglass stick with
/// telescopic joints, a red guard band and a black grip, copper cable to the
/// earth clamp — or the jugaad (white PVC, tape, thin wire, crocodile clip).
/// Flaws: a crack in the stick, a cut in the cable, rust on the clamp; each
/// shows only once its stretch has been looked at ([seenStick] / [seenLead]:
/// stretches of [kRodBins]; null = all seen). Unseen stretches are washed
/// with [veil] when it is set.
class RodPainter extends CustomPainter {
  RodPainter(this.rod, {this.seenStick, this.seenLead, this.veil});
  final RodItem rod;
  final Set<int>? seenStick;
  final Set<int>? seenLead;
  final Color? veil;

  static const _crackU = 0.62;
  static const _cutA = 0.5;
  static const _cutB = 0.56;
  static const _clampFrom = 0.9;

  static double _x0(Size s) => s.width * 0.1;
  static double _x1(Size s) => s.width * 0.9;
  static double _t(Size s) => math.max(3.0, s.height * 0.13);

  static (Offset, Offset, Offset) _curve(Size s) {
    final t = _t(s);
    return (Offset(_x0(s) + t * 0.4, s.height * 0.36 + t * 0.4), Offset(s.width * 0.5, s.height * 1.05), Offset(s.width * 0.93, s.height * 0.8));
  }

  /// A point on the earth lead, [u] from the hook end (0) to the clamp (1).
  static Offset leadAt(Size s, double u) {
    final (from, ctrl, to) = _curve(s);
    final a = Offset.lerp(from, ctrl, u)!;
    final b = Offset.lerp(ctrl, to, u)!;
    return Offset.lerp(a, b, u)!;
  }

  /// How far along the stick (0 hook end … 1 grip end) [x] is.
  static double stickU(Size s, double x) => ((x - _x0(s)) / (_x1(s) - _x0(s))).clamp(0.0, 1.0);

  /// How far along the lead (0 … 1 clamp) the point under [x] is.
  static double leadU(Size s, double x) {
    var best = 0.0;
    var gap = double.infinity;
    for (var i = 0; i <= 60; i++) {
      final u = i / 60;
      final d = (leadAt(s, u).dx - x).abs();
      if (d < gap) {
        gap = d;
        best = u;
      }
    }
    return best;
  }

  static bool _any(Set<int>? seen, double a, double b) {
    if (seen == null) return true;
    for (var i = rodBin(a); i <= rodBin(b); i++) {
      if (seen.contains(i)) return true;
    }
    return false;
  }

  /// The rod's flaw is in view (false for a sound rod).
  static bool flawSeen(RodItem rod, Set<int>? stick, Set<int>? lead) => switch (rod.flaw) {
        RodFlaw.none => false,
        RodFlaw.crack => _any(stick, _crackU - 0.03, _crackU + 0.03),
        RodFlaw.cable => _any(lead, _cutA, _cutB),
        RodFlaw.clamp => _any(lead, _clampFrom, 1),
      };

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final cy = h * 0.36;
    final t = _t(s);
    final x0 = _x0(s);
    final x1 = _x1(s);
    final jug = rod.jugaad;
    final flawShows = flawSeen(rod, seenStick, seenLead);
    final (_, _, clampAt) = _curve(s);

    final cablePaint = Paint()
      ..color = jug ? const Color(0xFF7A7F85) : const Color(0xFF8A5A1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = jug ? math.max(1.0, t * 0.18) : math.max(1.6, t * 0.42)
      ..strokeCap = StrokeCap.round;
    final cut = rod.flaw == RodFlaw.cable && flawShows;
    Path cablePath(double a, double b) {
      final p = Path()..moveTo(leadAt(s, a).dx, leadAt(s, a).dy);
      for (var i = 1; i <= 24; i++) {
        final q = leadAt(s, a + (b - a) * i / 24);
        p.lineTo(q.dx, q.dy);
      }
      return p;
    }

    // Cable first (it hangs behind the stick).
    if (cut) {
      canvas.drawPath(cablePath(0, _cutA), cablePaint);
      canvas.drawPath(cablePath(_cutB, 1), cablePaint);
      final strand = Paint()
        ..color = const Color(0xFFF0A040)
        ..strokeWidth = math.max(0.8, t * 0.1)
        ..strokeCap = StrokeCap.round;
      final a = leadAt(s, _cutA);
      final b = leadAt(s, _cutB);
      for (var i = -1; i <= 1; i++) {
        canvas.drawLine(a, Offset.lerp(a, b, 0.7)!.translate(0, i * t * 0.25), strand);
        canvas.drawLine(b, Offset.lerp(b, a, 0.6)!.translate(0, i * t * 0.22), strand);
      }
    } else {
      canvas.drawPath(cablePath(0, 1), cablePaint);
      if (!jug) {
        canvas.drawPath(
          cablePath(0, 1),
          Paint()
            ..color = const Color(0xFFD9954A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.6, t * 0.12),
        );
      }
    }

    // Clamp (or crocodile clip).
    if (jug) {
      final jaw = Paint()..color = const Color(0xFF8D949B);
      final p = Path()
        ..moveTo(clampAt.dx - t * 0.9, clampAt.dy - t * 0.3)
        ..lineTo(clampAt.dx + t * 0.9, clampAt.dy - t * 0.6)
        ..lineTo(clampAt.dx + t * 0.9, clampAt.dy + t * 0.1)
        ..lineTo(clampAt.dx - t * 0.9, clampAt.dy + t * 0.3)
        ..close();
      canvas.drawPath(p, jaw);
    } else {
      final rusty = rod.flaw == RodFlaw.clamp && flawShows;
      final r = Rect.fromCenter(center: clampAt, width: t * 2.4, height: t * 1.7);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(t * 0.4)), Paint()..color = rusty ? const Color(0xFF9A5A2C) : const Color(0xFFD9A441));
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(t * 0.4)),
        Paint()
          ..color = rusty ? const Color(0xFF4F2A12) : const Color(0xFF7A5A1C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, t * 0.14),
      );
      canvas.drawCircle(clampAt, t * 0.32, Paint()..color = rusty ? const Color(0xFF4F2A12) : const Color(0xFF7A5A1C));
      if (rusty) {
        final spot = Paint()..color = const Color(0xFFC9783A);
        for (final o in const [Offset(-0.7, -0.4), Offset(0.6, 0.35), Offset(0.75, -0.45), Offset(-0.4, 0.5)]) {
          canvas.drawCircle(clampAt + Offset(o.dx * t, o.dy * t), t * 0.2, spot);
        }
      }
    }

    // Hook.
    final hook = Path()
      ..moveTo(x0, cy)
      ..lineTo(x0 - w * 0.03, cy)
      ..quadraticBezierTo(x0 - w * 0.08, cy, x0 - w * 0.08, cy - t * 1.6)
      ..quadraticBezierTo(x0 - w * 0.08, cy - t * 3, x0 - w * 0.04, cy - t * 3)
      ..quadraticBezierTo(x0 - w * 0.01, cy - t * 3, x0 - w * 0.01, cy - t * 2.1);
    canvas.drawPath(
      hook,
      Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, t * 0.5)
        ..strokeCap = StrokeCap.round,
    );

    // Stick.
    final stick = RRect.fromRectAndRadius(Rect.fromLTRB(x0, cy - t / 2, x1, cy + t / 2), Radius.circular(t / 2));
    canvas.drawRRect(stick, Paint()..color = jug ? const Color(0xFFF4F4F0) : const Color(0xFFE9B949));
    canvas.drawRRect(
      stick,
      Paint()
        ..color = jug ? const Color(0xFFA9A9A2) : const Color(0xFF9C7420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, t * 0.1),
    );
    if (jug) {
      final tape = Paint()..color = const Color(0xFF222222);
      for (final u in const [0.36, 0.62]) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x0 + (x1 - x0) * u, cy), width: t * 0.9, height: t * 1.15), tape);
      }
    } else {
      final joint = Paint()..color = const Color(0xFFB88A2A);
      for (final u in const [0.33, 0.55]) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x0 + (x1 - x0) * u, cy), width: t * 0.35, height: t * 1.08), joint);
      }
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x0 + (x1 - x0) * 0.7, cy), width: t * 0.7, height: t * 1.15),
        Paint()..color = const Color(0xFFC0392B),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x0 + (x1 - x0) * 0.8, cy - t * 0.6, x1, cy + t * 0.6), Radius.circular(t * 0.4)),
        Paint()..color = const Color(0xFF3B3F45),
      );
    }
    if (rod.flaw == RodFlaw.crack && flawShows) {
      final cx = x0 + (x1 - x0) * _crackU;
      final crack = Path()
        ..moveTo(cx - t * 1.2, cy - t * 0.45)
        ..lineTo(cx - t * 0.4, cy + t * 0.1)
        ..lineTo(cx + t * 0.2, cy - t * 0.25)
        ..lineTo(cx + t * 1.0, cy + t * 0.42);
      canvas.drawPath(
        crack,
        Paint()
          ..color = const Color(0xFF3B2A12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, t * 0.16),
      );
      final stress = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = math.max(0.5, t * 0.08);
      canvas.drawLine(Offset(cx - t * 0.5, cy - t * 0.45), Offset(cx - t * 0.2, cy - t * 0.1), stress);
      canvas.drawLine(Offset(cx + t * 0.6, cy + t * 0.45), Offset(cx + t * 0.4, cy + t * 0.12), stress);
    }

    // What has not been looked at yet is washed out.
    final v = veil;
    if (v != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.6);
      final stickSeen = seenStick;
      if (stickSeen != null) {
        final bw = (x1 - x0) / kRodBins;
        for (var i = 0; i < kRodBins; i++) {
          if (!stickSeen.contains(i)) canvas.drawRect(Rect.fromLTWH(x0 + bw * i - 0.5, cy - t * 0.75, bw + 1, t * 1.5), wash);
        }
      }
      final leadSeen = seenLead;
      if (leadSeen != null) {
        final band = Paint()
          ..color = v.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(4.0, t * 1.1)
          ..strokeCap = StrokeCap.butt;
        // Along the lead up to the clamp (the clamp has its own wash).
        for (var i = 0; (i + 1) / kRodBins <= _clampFrom + 1e-9; i++) {
          if (!leadSeen.contains(i)) canvas.drawPath(cablePath(i / kRodBins, (i + 1) / kRodBins), band);
        }
        if (!_any(leadSeen, _clampFrom, 1)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: clampAt, width: t * 2.4 + 4, height: t * 1.7 + 4), Radius.circular(t * 0.4 + 2)),
            wash,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(RodPainter old) =>
      old.rod != rod || old.veil != veil || !_same(old.seenStick, seenStick) || !_same(old.seenLead, seenLead);

  static bool _same(Set<int>? a, Set<int>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}

/// The deadly move, in colour over the frozen van, staged as its own picture:
/// the trainee under a pole top holds the rod up, its hook on a conductor and
/// its earth lead down to a spike — the 11 kV rod on a 33 kV line, or the PVC
/// jugaad. The charge breaks down the insulation (the jugaad splits) and
/// creeps down the stick to his hands. (An illustration of the lesson's
/// "ইনসুলেশন ভেঙে যাওয়ার ঝুঁকি" / "পিভিসি ফাটতে পারে, লিক হতে পারে".)
class _RodFlash extends StatelessWidget {
  const _RodFlash({required this.jugaad, required this.quiet});
  final bool jugaad;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth - 40, 340.0);
        final h = math.min(w * 1.12, box.maxHeight * 0.7);
        final g = _FlashGeo(Size(w, h));
        final still = Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PoleTopPainter(g))),
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
                          Positioned.fill(child: CustomPaint(painter: _FlashPainter(g: g, t: t, jugaad: jugaad))),
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

/// Where things are in the consequence picture ([s]: the panel).
@immutable
class _FlashGeo {
  const _FlashGeo(this.s);
  final Size s;

  double get ground => s.height * 0.9;
  double get poleX => s.width * 0.86;
  double get armY => s.height * 0.2;

  /// The insulator top the near conductor is tied to.
  Offset get tie => Offset(s.width * 0.72, armY - 14);

  /// The near conductor, from the panel's left edge to [tie] (a slight sag).
  Offset wire(double u) {
    final a = Offset(0, armY - 4);
    final c = Offset(s.width * 0.36, armY + 6);
    return Offset.lerp(Offset.lerp(a, c, u)!, Offset.lerp(c, tie, u)!, u)!;
  }

  Offset get hook => wire(0.72);

  Rect get figure {
    final fh = s.height * 0.5;
    return Rect.fromLTWH(s.width * 0.03, ground - fh * 0.985, fh * 0.5, fh);
  }

  /// The trainee's gloved hands on the grip.
  Offset get hand => figure.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, figure.size);

  Offset get dir => (hook - hand) / (hook - hand).distance;
  Offset get nrm => Offset(-dir.dy, dir.dx);
  double get len => (hook - hand).distance;

  /// A point on the rod: 0 at the hands, 1 at the hook.
  Offset along(double u) => hand + dir * (len * u);

  /// The earth spike the lead is clamped to.
  Offset get spike => Offset(s.width * 0.52, ground + 2);
}

/// The still picture behind the flash: sky, a far line, the pole top with its
/// cross-arm, insulators and conductors, the ground and the earth spike.
class _PoleTopPainter extends CustomPainter {
  const _PoleTopPainter(this.g);
  final _FlashGeo g;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final sky = Rect.fromLTWH(0, 0, w, g.ground);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E5E8E), Color(0xFF7FA9C9), Color(0xFFD7E3E8)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    // A far line of poles, hazy.
    final far = Paint()..color = const Color(0xFF9DB1C0);
    for (final x in [w * 0.12, w * 0.4]) {
      c.drawRect(Rect.fromLTWH(x, g.ground - h * 0.3, 3, h * 0.3), far);
      c.drawRect(Rect.fromLTWH(x - 10, g.ground - h * 0.3, 23, 2.5), far);
    }
    c.drawLine(
      Offset(0, g.ground - h * 0.29),
      Offset(w * 0.5, g.ground - h * 0.28),
      Paint()
        ..color = const Color(0xFF9DB1C0)
        ..strokeWidth = 1,
    );
    // Ground.
    final field = Rect.fromLTWH(0, g.ground, w, h - g.ground);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7D8B4E), Color(0xFF5C6838)],
        ).createShader(field),
    );
    // The pole (concrete) and its cross-arm.
    final pole = Rect.fromLTRB(g.poleX - 9, h * 0.08, g.poleX + 9, g.ground + 4);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B8B1), Color(0xFF8C8B85)]).createShader(pole));
    c.drawRect(Rect.fromLTRB(w * 0.64, g.armY, w + 4, g.armY + 7), Paint()..color = const Color(0xFF4F565D));
    // Insulators and the conductors on them.
    final porcelain = Paint()..color = const Color(0xFFEDE7DA);
    final rim = Paint()..color = const Color(0xFF8E5A3C);
    for (final x in [g.tie.dx, w * 0.97]) {
      for (var i = 0; i < 3; i++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, g.armY - 3 - i * 4.0), width: 14 - i * 2.0, height: 5), i.isEven ? porcelain : rim);
      }
    }
    final wire = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    final near = Path()..moveTo(g.wire(0).dx, g.wire(0).dy);
    for (var i = 1; i <= 24; i++) {
      final p = g.wire(i / 24);
      near.lineTo(p.dx, p.dy);
    }
    c.drawPath(near, wire);
    c.drawLine(Offset(w * 0.97, g.armY - 14), Offset(w + 4, g.armY - 13), wire);
    c.drawLine(Offset(0, h * 0.09), Offset(w, h * 0.07), wire..strokeWidth = 2.4);
    // The earth spike.
    c.drawRect(Rect.fromCenter(center: g.spike.translate(0, -5), width: 5, height: 14), Paint()..color = const Color(0xFF6F777E));
  }

  @override
  bool shouldRepaint(_PoleTopPainter old) => old.g.s != g.s;
}

class _FlashPainter extends CustomPainter {
  _FlashPainter({required this.g, required this.t, required this.jugaad});
  final _FlashGeo g;
  final double t;
  final bool jugaad;

  @override
  void paint(Canvas c, Size s) {
    final nrm = g.nrm;
    Offset along(double u) => g.along(u);
    final hook = g.hook;
    final hand = g.hand;

    // The earth lead: from the rod's head down to the clamp on the spike.
    final head = along(0.9);
    final lead = Path()
      ..moveTo(head.dx, head.dy)
      ..quadraticBezierTo(g.s.width * 0.62, g.s.height * 0.62, g.spike.dx, g.spike.dy - 12);
    c.drawPath(
      lead,
      Paint()
        ..color = jugaad ? const Color(0xFF7A7F85) : const Color(0xFF8A5A1E)
        ..strokeWidth = jugaad ? 1.2 : 2.6
        ..style = PaintingStyle.stroke,
    );
    c.drawRect(
      Rect.fromCenter(center: g.spike.translate(0, -12), width: 10, height: 7),
      Paint()..color = jugaad ? const Color(0xFF8D949B) : const Color(0xFFD9A441),
    );

    // The stick, from just behind the hands up to the head.
    final stickW = math.max(7.0, g.s.width * 0.03);
    Offset edge(double u, double side) => along(u) + nrm * (side * stickW / 2);
    final stick = Path()
      ..moveTo(edge(-0.1, 1).dx, edge(-0.1, 1).dy)
      ..lineTo(edge(0.92, 1).dx, edge(0.92, 1).dy)
      ..lineTo(edge(0.92, -1).dx, edge(0.92, -1).dy)
      ..lineTo(edge(-0.1, -1).dx, edge(-0.1, -1).dy)
      ..close();
    c.drawPath(stick, Paint()..color = jugaad ? const Color(0xFFF4F4F0) : const Color(0xFFE9B949));
    c.drawPath(
      stick,
      Paint()
        ..color = jugaad ? const Color(0xFF8F8F88) : const Color(0xFF8A6418)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    if (jugaad) {
      final tape = Paint()
        ..color = const Color(0xFF222222)
        ..strokeWidth = stickW * 0.8;
      for (final u in const [0.35, 0.62]) {
        c.drawLine(along(u) + nrm * stickW * 0.6, along(u) - nrm * stickW * 0.6, tape);
      }
      // The split opens along the pipe.
      final split = Path()..moveTo(along(0.4).dx, along(0.4).dy);
      for (var i = 1; i <= 8; i++) {
        final p = along(0.4 + 0.025 * i) + nrm * ((i.isEven ? 1 : -1) * stickW * 0.35 * t);
        split.lineTo(p.dx, p.dy);
      }
      c.drawPath(
        split,
        Paint()
          ..color = const Color(0xFF3B2A12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + 2 * t,
      );
    } else {
      // The grip and the red guard band.
      c.drawLine(along(-0.1), along(0.08), Paint()
        ..color = const Color(0xFF3B3F45)
        ..strokeWidth = stickW * 1.15);
      c.drawLine(along(0.13), along(0.16), Paint()
        ..color = const Color(0xFFC0392B)
        ..strokeWidth = stickW * 1.2);
    }
    // The metal hook over the conductor.
    final hk = Path()
      ..moveTo(along(0.92).dx, along(0.92).dy)
      ..lineTo(hook.dx, hook.dy + 6)
      ..quadraticBezierTo(hook.dx - 9, hook.dy - 2, hook.dx - 2, hook.dy - 8)
      ..quadraticBezierTo(hook.dx + 6, hook.dy - 10, hook.dx + 7, hook.dy - 3);
    c.drawPath(
      hk,
      Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );

    // The breakdown: a jagged arc creeps from the hook down the stick to the hands.
    final reach = (t / 0.55).clamp(0.0, 1.0);
    if (reach > 0) {
      final rng = math.Random(7 + (t * 14).floor());
      final arc = Path()..moveTo(hook.dx, hook.dy);
      const n = 16;
      for (var i = 1; i <= n; i++) {
        final u = 0.92 * (1 - (i / n) * reach);
        final p = along(u) + nrm * ((rng.nextDouble() - 0.5) * stickW * 2.4);
        arc.lineTo(p.dx, p.dy);
      }
      c.drawPath(
        arc,
        Paint()
          ..color = const Color(0x8066B7FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      c.drawPath(
        arc,
        Paint()
          ..color = const Color(0xFFE8F6FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );
      c.drawCircle(
        hook,
        10 + 10 * reach,
        Paint()
          ..color = const Color(0x99FFF3B0)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    // The flash at the hands.
    if (t > 0.55) {
      final f = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
      final r = 24 + 56 * f;
      c.drawCircle(
        hand,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * (1 - f * 0.3)), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: hand, radius: r)),
      );
      // Sparks off the gloves.
      final spark = Paint()
        ..color = Color.fromRGBO(255, 236, 160, 1 - f * 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + 0.3;
        final d = Offset(math.cos(a), math.sin(a));
        c.drawLine(hand + d * (14 + 10 * f), hand + d * (26 + 26 * f), spark);
      }
    }
  }

  @override
  bool shouldRepaint(_FlashPainter old) => old.t != t || old.jugaad != jugaad || old.g.s != g.s;
}
