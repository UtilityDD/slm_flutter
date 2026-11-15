import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
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
import 'm6_ug_dig_guard_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_ug_dig_guard_world.dart' show M6DigGeo, M6DigLayout, M6Look, kM6Dtr, kM6Pole, m6DigLayout, m6PolyDist;

// Lesson 6.5 "আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো নেটওয়ার্ক", কাজ 2
// "খোঁড়ার আগে কেবিলের পথ" (pack do_6_5_b, rung 6.5/do/1, engineType
// m6_ug_dig_guard). The verb: peg the hidden route, then flag-stop the digger.
//
// A town street is to be dug; a LIVE 11 kV UG cable runs under it from the
// riser pole (its end termination under the cross-arm — lesson point 3:
// 'মাটির নিচ থেকে ওপরে উঠে') across to the DTR on its plinth. Two or three
// identical iron covers lie on the street: one or two hide a cable joint
// (point 3: 'দুটি ইউজি কেবিলকে জোড়া'), one hides a drain.
//
//  Look (unscored): tap the pole top (the termination) or the transformer for
//    a close look; drag a cover up to lift it and see the pit, down to close.
//  Peg: tap the anchors in order — an end (the pole foot or the DTR entry),
//    the covers the cable passes, the other end — each tap lays a straight
//    chalk leg, the turns drawn gently round (ruling M6-7); 'মুছুন' clears;
//    'পথ আঁকা শেষ' judges it. Right → ◆ on the table → "পথটা এভাবে আঁকলেন
//    কেন?". Wrong (a joint missed, straight across, through the drain, or
//    not end to end) → a slip, and the true route is chalked in.
//  The guide teaches the flag once ('লাল পতাকা চেপে ধরে রাখলে মেশিন থামে').
//  Dig, three chalk circles in dealt order: the excavator drives to each and
//    lowers its bucket over 5–7 s. Over the route the player holds the red
//    flag (a 1 s ring) before it touches → ◆ → "কেন মেশিন থামালেন?"; doing
//    nothing there = DEADLY (myth 1's reality, 'মারাত্মক ভুল!'); the flag on a
//    clear circle = a slip (a needless stop, M1 sound-pole ruling, R32); a
//    clear circle left to dig is right (+5).
//  The careless coworker once a play, at a dealt circle of either kind,
//    before the descent: lesson myth 1 word for word; the bucket stays up
//    until his deck closes. Listening over the route = DEADLY (the bucket
//    strikes, ruling X2/B1); on a clear circle = a slip. Refusing him does not
//    stop the machine: the flag decides as before.
//
// No route paint or labels; covers must be lifted to tell a joint from the
// drain; the true route shows only after a wrong peg; the circles are
// identical and come only in the dig stage; the flag is never hinted.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_ug_dig_guard_world.dart), corner guide (tap: the task again),
// ReasonTable (the "কেন?" cards open at once), CoworkerMoment, gesture hands
// in the peg stage only (a sweep over the pole top, the anchors and every
// cover alike; an upward drag on a cover that was tapped; a sweep over
// 'মুছুন' and 'পথ আঁকা শেষ' once legs are laid), mistake cards with lesson
// points, the deadly freeze, three slips strike out, idle = zero frames.

// ============================================================================
// Content
// ============================================================================

/// What the reason asks about.
enum M6DigWhy { peg, flag }

/// The level's stages.
enum M6DigStage { peg, dig, done }

abstract final class M6DigLines {
  static const title = 'খোঁড়ার আগে কেবিলের পথ';

  // DRAFT wording — owner (spec flow[0]).
  static const intro = 'রাস্তা খোঁড়া হবে — নিচে লাইভ ইউজি কেবিল! আগে ওর পথ বুঝুন।';

  // The guide's task now (tap him: the same task, a different way).
  // DRAFT wording — owner.
  // Kept short: the bubble stays up and must not cover the street.
  static const askPeg = 'ঢাকনা তুলে দেখে কেবিলের পথ আঁকুন।';
  // DRAFT wording — owner (spec flow[3]).
  static const flagTeach = 'লাল পতাকা চেপে ধরে রাখলে মেশিন থামে।';
  // DRAFT wording — owner.
  static const askDig = 'কেবিলের ওপর হলে পতাকা ধরে থামান।';
  static const tasks = [askPeg, askDig];
  // Both already recorded (shared lines with clips).
  static const tapWhy = ['এর পেছনের কারণটা বলুন।', 'কারণটা কী, জানেন?'];

  // On the scene (labels a worker reads; buttons).
  static const clear = 'মুছুন';
  static const pegDone = 'পথ আঁকা শেষ';
  static const flag = 'লাল পতাকা';
  static const sceneLabel = 'রাস্তা';
  static const stepPeg = 'পথ';
  static String stepDig(int i) => enDigits('গর্ত ${i + 1}');

  // The reasons (spec reasonQuestionsBn). Right ones fit what was done (the
  // lesson's termination and joint points; myth 1's reality); wrong ones are
  // field guesses and excuses. 38–46 letters. DRAFT wording — owner.
  static const whyQ = <M6DigWhy, String>{
    M6DigWhy.peg: 'পথটা এভাবে আঁকলেন কেন?',
    M6DigWhy.flag: 'কেন মেশিন থামালেন?',
  };
  static const whyRight = <M6DigWhy, List<String>>{
    M6DigWhy.peg: [
      'টার্মিনেশন থেকে জয়েন্ট ছুঁয়ে ট্রান্সফরমারে',
      'জয়েন্টে দুটো কেবিল জোড়া, পথ ওখান দিয়েই',
      'ঢাকনা তুলে জয়েন্ট দেখে তবেই সেদিকে দাগ',
    ],
    M6DigWhy.flag: [
      'মেশিনের ঘায়ে আর্মার ছিঁড়ে আর্ক ফ্ল্যাশ হয়',
      'লাইভ কেবিলে ঘা লাগলে বিস্ফোরণ হতে পারে',
      'আর্ক ফ্ল্যাশে অপারেটরের প্রাণ যেতে পারে',
    ],
  };
  static const whyWrong = <M6DigWhy, List<String>>{
    M6DigWhy.peg: [
      'পোল থেকে ট্রান্সফরমার সোজা দাগই কেবিলের পথ',
      'সব লোহার ঢাকনার নিচেই কেবিলের জয়েন্ট থাকে',
      'ড্রেনের পাশ দিয়েই কেবিল সবসময় টানা হয়',
      'আন্দাজে আঁকলেই চলে, খোঁড়ার সময় দেখা যাবে',
      'রাস্তার একদম মাঝখান দিয়েই কেবিল টানা হয়',
      'সবচেয়ে ছোট পথ দিয়েই কেবিল নিয়ে যাওয়া হয়',
    ],
    M6DigWhy.flag: [
      // Same sentence shape as the right ones (no tail that marks them):
      // a downplayed danger, a wrong rule, or no reason at all.
      'কেবিল কাটলে শুধু এলাকার কারেন্ট যেতে পারে',
      'কেবিলে ঘা লাগলে বড়জোর ফিউজটা কাটতে পারে',
      'বাকেট নামার আগে প্রতিবার থামানোই নিয়ম',
      'খোঁড়া মাটি রাস্তায় ছড়ালে লোকে রাগ করবে',
      'অপারেটর অনেকক্ষণ খুঁড়ছে, একটু জিরিয়ে নিক',
      'চকের দাগটা ঠিক আছে কিনা দেখে নিচ্ছিলাম',
    ],
  };

  // The careless coworker: lesson 6.5 myth 1 word for word (the same clip as
  // board 6.5's myth). His exit line is recorded already.
  static const myth1 = 'ইউজি কেবিল তো ইনসুলেটেড এবং আর্মার্ড, তাই এটা লাইভ থাকা অবস্থায় মাটি খোঁড়ার মেশিনের আঘাতে কিছু হবে না।';
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  // The cards reject or accept the myth itself — never "stop here" (he comes
  // at a clear circle too, so a card must not tell the circle's kind).
  // DRAFT wording — owner (cards and the second ask).
  static const coworker = CoworkerScript(
    line: myth1,
    exitLine: coworkerExit,
    right: ['না, মেশিনের ঘায়ে আর্মারও ছিঁড়ে যায়', 'না, লাইভ কেবিলে ঘা মানে বিস্ফোরণ', 'না, আর্মার মেশিনের শক্তি সইতে পারে না'],
    wrong: [
      'ঠিক, আর্মার তো আছে, কিছুই হবে না',
      'হ্যাঁ, ইনসুলেটেড কেবিল, ভয় নেই',
      'ঠিক, আর্মার মেশিনের ঘা সামলে নেবে',
      'ঠিক আছে, একটু ঘা লাগলে আর কী হবে',
      'হ্যাঁ, কেবিল তো শক্তপোক্ত জিনিস',
    ],
    // asks[0] and asks[2] are recorded already; asks[1] is new (DRAFT).
    asks: ['কী করবেন?', 'ও বলছে আর্মার্ড কেবিলে মেশিনের ঘায়ে কিছু হয় না। কী করবেন?', 'আপনি কী করবেন — ওর কথা শুনবেন?'],
  );
  // DRAFT wording — owner. Never says whether this circle is over the cable.
  static const callHeld = 'ঠিক! আর্মারও মেশিনের ঘা সইতে পারে না।';

  // DRAFT wording — owner.
  static const allSet = 'কেবিলের পথ চিনে, ঠিক জায়গায় মেশিন থামিয়েছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  // DRAFT wording — owner.
  static const fail = 'আরেকবার — আগে কেবিলের পথ, তারপর মেশিনে নজর।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (on the pass panel; not spoken). DRAFT wording — owner.
  static const caughtRoute = 'ঢাকনা তুলে কেবিলের আসল পথ চিনেছেন';
  static const caughtStop = 'কেবিলের ওপর মেশিন থামিয়েছেন';
  static const caughtClear = 'ফাঁকা জায়গায় অকারণে থামাননি';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken guide line of this level (for the owner's wording and
  /// the recording), DRAFT. The mistake cards' lines are spoken too (once).
  static List<String> get newGuideLines => [
        intro,
        askPeg,
        flagTeach,
        askDig,
        whyQ[M6DigWhy.peg]!,
        whyQ[M6DigWhy.flag]!,
        coworker.asks[1],
        callHeld,
        allSet,
        fail,
        for (final m in M6DigMistakes.all) m.textBn,
      ];

  /// His new line (lesson myth 1 word for word; no clip yet).
  static const newRivalLines = [myth1];
}

abstract final class M6DigMistakes {
  static const _dir = 'assets/game/art/m6_ug_dig_guard';

  // Lesson 6.5 point 3 (termination, jointing); the joint under a road
  // cover is a scene choice (spec unsupported[6]). DRAFT wording — owner.
  static const pegMissed = DoMistake(
    key: '6.5/m6_ug_dig_guard/peg-missed',
    textBn: 'কেবিল পোলের টার্মিনেশন থেকে মাটিতে নেমে জয়েন্টের ঢাকনা ছুঁয়ে ট্রান্সফরমারে যায়। জয়েন্ট বাদ দিলে, উল্টো ক্রমে ছুঁলে বা সোজা দাগ টানলে পথ ভুল।',
    art: '$_dir/peg_missed.svg',
    lessonPoint: 2,
  );
  static const pegDrain = DoMistake(
    key: '6.5/m6_ug_dig_guard/peg-drain',
    textBn: 'ওই ঢাকনার নিচে ড্রেন, কেবিল নয়। ঢাকনা তুলে দেখে শুধু জয়েন্টের ঢাকনা দিয়ে পথ আঁকুন।',
    art: '$_dir/peg_drain.svg',
    lessonPoint: 2,
  );
  // Myth 1's reality (lesson 6.5 myth buster): 'মারাত্মক ভুল!'. Point 1
  // (index 0) holds the armour layer. DRAFT wording — owner.
  static const digStrike = DoMistake(
    key: '6.5/m6_ug_dig_guard/dig-strike',
    textBn: 'কেবিলের ওপর মেশিন থামাননি! এক্সক্যাভেটরের আঘাতে আর্মার ও ইনসুলেশন ছিন্ন হয়ে প্রচণ্ড বিস্ফোরণ আর আর্ক ফ্ল্যাশ হতে পারে — যাতে অপারেটরের প্রাণহানির ঝুঁকি!',
    art: '$_dir/dig_strike.svg',
    deadly: true,
    lessonPoint: 0,
  );
  // Ruling X2 (B1): listening takes the class of the act pushed — over the
  // route the bucket strikes the live cable.
  static const pushStrike = DoMistake(
    key: '6.5/m6_ug_dig_guard/push-strike',
    textBn: 'আর্মার্ড কেবিলেও মেশিনের আঘাত মারাত্মক! ওর কথায় মেশিন চালানোয় আর্মার ও ইনসুলেশন ছিঁড়ে ভয়াবহ আর্ক ফ্ল্যাশ হতে পারে। কেবিলের ওপর খোঁড়া এখনই থামান!',
    art: '$_dir/dig_strike.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const pushClear = DoMistake(
    key: '6.5/m6_ug_dig_guard/push-clear',
    textBn: '“আর্মার্ড, তাই কিছু হবে না” — এটা ভুল ধারণা। এক্সক্যাভেটর আর্মার আর ইনসুলেশন ছিঁড়ে ফেলে; এ কথা কখনো মানবেন না।',
    art: '$_dir/push_myth.svg',
    lessonPoint: 0,
  );
  // M1 sound-pole ruling (R32): a needless stop is a slip. No lesson point.
  static const needlessStop = DoMistake(
    key: '6.5/m6_ug_dig_guard/needless-stop',
    textBn: 'এখানে নিচে কেবিল নেই — অকারণে মেশিন থামালেন। চকের পথ দেখে শুধু কেবিলের ওপর থামান।',
    art: '$_dir/needless_stop.svg',
  );

  static const List<DoMistake> all = [pegMissed, pegDrain, digStrike, pushStrike, pushClear, needlessStop];
}

/// One play's deal.
@immutable
class M6DigDeal {
  const M6DigDeal({
    required this.drain,
    required this.jointRoute,
    required this.onRoute,
    required this.descentMs,
    required this.coworkerSpot,
    required this.layoutSeed,
  });

  /// The cover over the drain (index).
  final int drain;

  /// The joint covers in route order, from the pole to the DTR.
  final List<int> jointRoute;

  /// The three dig circles in dig order: over the route or clear.
  final List<bool> onRoute;

  /// Each circle's bucket descent (5–7 s).
  final List<int> descentMs;

  /// The circle the coworker comes at (before its descent).
  final int coworkerSpot;

  /// Seeds the street layout (positions follow the screen).
  final int layoutSeed;

  int get covers => jointRoute.length + 1;

  /// The right chain: the pole foot, the joints, the DTR entry.
  List<int> get trueRoute => [kM6Pole, ...jointRoute, kM6Dtr];

  M6DigLayout layoutOn(M6DigGeo geo) => m6DigLayout(seed: layoutSeed, drain: drain, jointRoute: jointRoute, onRoute: onRoute, geo: geo);
}

M6DigDeal m6DigDeal(math.Random rng) {
  final joints = 1 + rng.nextInt(2);
  final covers = joints + 1;
  final drain = rng.nextInt(covers);
  final jr = [for (var i = 0; i < covers; i++) if (i != drain) i]..shuffle(rng);
  final nOn = 1 + rng.nextInt(2);
  final onRoute = [for (var i = 0; i < 3; i++) i < nOn]..shuffle(rng);
  return M6DigDeal(
    drain: drain,
    jointRoute: jr,
    onRoute: onRoute,
    descentMs: [for (var i = 0; i < 3; i++) 5000 + 250 * rng.nextInt(9)],
    coworkerSpot: rng.nextInt(3),
    layoutSeed: rng.nextInt(1 << 30),
  );
}

/// The play state (pure logic).
class M6DigRun {
  M6DigRun(this.deal);
  final M6DigDeal deal;

  var stage = M6DigStage.peg;

  /// The anchors tapped, in order ([kM6Pole], [kM6Dtr], cover indices).
  final List<int> chain = [];
  var pegRight = false;

  /// The true route is chalked in (after a wrong peg).
  var revealed = false;

  /// The dig circle now, and whether its outcome is in.
  int spot = 0;
  var spotDone = false;
  final Set<int> dug = {};

  int slips = 0;
  var _clearSlip = false;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => stage == M6DigStage.done;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get onRouteNow => deal.onRoute[spot.clamp(0, 2)];

  static bool isEnd(int id) => id == kM6Pole || id == kM6Dtr;

  /// The chain runs from one end to the other.
  bool get chainClosed => chain.length >= 2 && isEnd(chain.first) && isEnd(chain.last);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  // --- peg ----------------------------------------------------------------------
  /// An anchor tapped: the chain starts at an end, takes covers, closes at
  /// the other end. True if a dot or a leg was laid.
  bool tapAnchor(int id) {
    if (ended || stage != M6DigStage.peg || chainClosed) return false;
    if (id >= deal.covers || id < kM6Dtr) return false;
    if (chain.isEmpty) {
      if (!isEnd(id)) return false;
      chain.add(id);
      return true;
    }
    if (chain.contains(id)) return false;
    chain.add(id);
    return true;
  }

  void clearChain() {
    if (!ended && stage == M6DigStage.peg) chain.clear();
  }

  /// 'পথ আঁকা শেষ' (with at least one leg laid): right only on the true
  /// route, either way round. Wrong → a slip and the true route revealed.
  DoMistake? finishPeg() {
    if (ended || stage != M6DigStage.peg || chain.length < 2 || pegRight || revealed) return null;
    final want = deal.trueRoute;
    if (chainClosed && (listEquals(chain, want) || listEquals(chain.reversed.toList(), want))) {
      pegRight = true;
      _tag(M6DigLines.caughtRoute);
      return null;
    }
    revealed = true;
    slips++;
    return chain.contains(deal.drain) ? M6DigMistakes.pegDrain : M6DigMistakes.pegMissed;
  }

  /// On to the dig (after the peg's reason, or its card).
  void toDig() {
    if (stage != M6DigStage.peg || ended) return;
    stage = M6DigStage.dig;
    spot = 0;
    spotDone = false;
  }

  // --- dig ----------------------------------------------------------------------
  /// The red flag held to the full ring while the bucket comes down: right
  /// over the route; on a clear circle a needless stop (then it is dug).
  DoMistake? flag() {
    if (ended || stage != M6DigStage.dig || spotDone) return null;
    spotDone = true;
    if (onRouteNow) {
      _tag(M6DigLines.caughtStop);
      return null;
    }
    slips++;
    _clearSlip = true;
    dug.add(spot);
    return M6DigMistakes.needlessStop;
  }

  /// The bucket reached the ground with no flag: over the live cable deadly;
  /// a clear circle is dug (right).
  DoMistake? touch() {
    if (ended || stage != M6DigStage.dig || spotDone) return null;
    spotDone = true;
    if (onRouteNow) return deadly = M6DigMistakes.digStrike;
    dug.add(spot);
    return null;
  }

  /// Listened to the coworker at this circle (B1): over the route the
  /// bucket strikes (deadly); on a clear circle a slip (and it is dug).
  DoMistake? listen() {
    if (ended || stage != M6DigStage.dig || spotDone) return null;
    spotDone = true;
    if (onRouteNow) return deadly = M6DigMistakes.pushStrike;
    slips++;
    _clearSlip = true;
    dug.add(spot);
    return M6DigMistakes.pushClear;
  }

  void refused() => _tag(M6DigLines.caughtCall);

  /// The next circle (after the last, the play is done).
  void nextSpot() {
    if (ended || stage != M6DigStage.dig || !spotDone) return;
    spot++;
    spotDone = false;
    if (spot >= deal.onRoute.length) {
      stage = M6DigStage.done;
      if (!_clearSlip && deal.onRoute.contains(false)) _tag(M6DigLines.caughtClear);
    }
  }
}

/// The quick bonus: a little under a thorough play. ms, ~1500 per action:
///   look + lift 2–3 covers ≈ 6000, 4–5 anchor taps + done ≈ 7500, reason
///   ~8200; the flag line ~3000; three circles (drive ~900 + descent ~6000 +
///   ~800) ≈ 23100, one or two flag reasons ~8200–16400; the coworker ~9600
///                                                     ≈ 65600–73800
/// The descents are the machine's time (only a right flag cuts one short).
/// 70 s (an owner decision: say so in the report).
const m6DigQuickMs = 70000;

/// The flag's ring (hold this long to stop the machine).
const m6FlagHoldMs = 1000;

@immutable
class M6DigPack {
  const M6DigPack({required this.id, required this.titleBn, this.quickMs = m6DigQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6DigPack> m6UgDigGuardPacks = {
  'do_6_5_b': M6DigPack(id: 'do_6_5_b', titleBn: M6DigLines.title),
};

/// Test hook (tests only): the run on screen and whether a bucket is coming
/// down now.
@visibleForTesting
abstract final class M6DigProbe {
  static M6DigRun? run;
  static bool descending = false;
}

// ============================================================================
// Page
// ============================================================================

class M6UgDigGuardPage extends StatefulWidget {
  const M6UgDigGuardPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6DigPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6UgDigGuardPage> createState() => _M6UgDigGuardPageState();
}

class _M6UgDigGuardPageState extends State<M6UgDigGuardPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DigRunPage(
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

class _DigRunPage extends ConsumerStatefulWidget {
  const _DigRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6DigPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DigRunPage> createState() => _DigRunPageState();
}

/// Where the dig stands at the current circle.
enum _Dig { idle, moving, waiting, descending, stopped, over }

class _DigRunPageState extends ConsumerState<_DigRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6DigRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  VoidCallback? _afterCard;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  M6DigWhy _why = M6DigWhy.peg;

  // Peg stage: lifted covers, the close look, the last cover tapped alone.
  final Set<int> _open = {};
  M6Look? _look;
  int _lookTok = 0;
  int? _tappedCover;

  // Dig stage.
  var _dig = _Dig.idle;
  late final AnimationController _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
  late final AnimationController _travel = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  Offset _from = Offset.zero;

  /// The app went to the background mid-descent: the bucket waits there
  /// (a ticker would jump to the end on return and strike unseen).
  AppLifecycleListener? _life;
  double? _pausedAt;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what) — peg stage only.
  final _hints = IdleHintController();
  final _clearKey = GlobalKey();
  final _doneKey = GlobalKey();
  int _hintN = 0;
  M6DigGeo? _geoNow;
  M6DigLayout? _lay;

  // A drag on a cover.
  int? _dragCover;
  Offset _dragFrom = Offset.zero;
  Offset _dragNow = Offset.zero;

  @override
  void initState() {
    super.initState();
    _run = M6DigRun(m6DigDeal(widget.rng));
    M6DigProbe.run = _run;
    M6DigProbe.descending = false;
    _life = AppLifecycleListener(onHide: _pauseDrop, onShow: _resumeDrop);
  }

  void _pauseDrop() {
    if (_dig != _Dig.descending || !_drop.isAnimating) return;
    _pausedAt = _drop.value;
    _drop.stop();
  }

  void _resumeDrop() {
    final at = _pausedAt;
    _pausedAt = null;
    if (at == null || !mounted || _ended || _dig != _Dig.descending || _run.spotDone) return;
    unawaited(_descend(from: at));
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _life?.dispose();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    _drop.dispose();
    _travel.dispose();
    if (identical(M6DigProbe.run, _run)) {
      M6DigProbe.run = null;
      M6DigProbe.descending = false;
    }
    super.dispose();
  }

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

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  M6DigLayout get _layout => _lay!;

  bool get _canPeg =>
      !_intro &&
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_freeze &&
      _run.stage == M6DigStage.peg &&
      !_run.pegRight &&
      !_run.revealed &&
      _lay != null;

  bool get _flagLive => !_ended && !_freeze && _card == null && !tableBusy && !coworkerOpen && _run.stage == M6DigStage.dig && _dig == _Dig.descending;

  String get _task => _run.stage == M6DigStage.dig ? M6DigLines.askDig : M6DigLines.askPeg;

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([M6DigLines.askPeg]));
  }

  // --- peg ------------------------------------------------------------------------
  Offset _anchorAt(int id) => switch (id) {
        kM6Pole => _geoNow!.poleFoot,
        kM6Dtr => _geoNow!.dtrEntry,
        _ => _layout.covers[id],
      };

  int? _coverAt(Offset p) {
    final geo = _geoNow;
    final lay = _lay;
    if (geo == null || lay == null) return null;
    for (final (i, c) in lay.covers.indexed) {
      if (geo.coverHit(c).contains(p)) return i;
    }
    return null;
  }

  void _tapScene(Offset p) {
    if (!_canPeg) return;
    final geo = _geoNow!;
    if (geo.riserHit.contains(p)) {
      _showLook(M6Look.termination);
      return;
    }
    if (geo.dtrBox.inflate(4).contains(p)) {
      _showLook(M6Look.dtrEntry);
      return;
    }
    int? id;
    if (geo.poleFootHit.contains(p)) {
      id = kM6Pole;
    } else if (geo.dtrEntryHit.contains(p)) {
      id = kM6Dtr;
    } else {
      id = _coverAt(p);
    }
    if (id == null) {
      _hints.missTap();
      return;
    }
    if (_run.chain.isEmpty && id >= 0) {
      // A cover before the chain has begun: it does not lift at a tap (the
      // hand shows the upward drag on it).
      setState(() => _tappedCover = id);
      _hints.missTap();
      return;
    }
    if (_run.tapAnchor(id)) {
      _tick('sounds/learn/tag_slap.ogg', 0.4);
      HapticFeedback.lightImpact();
      setState(() {
        _tappedCover = null;
        _wake++;
      });
    } else {
      _hints.missTap();
    }
  }

  void _showLook(M6Look l) {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _look = l;
      _lookTok++;
    });
  }

  void _dragStart(Offset p) {
    _dragCover = _canPeg ? _coverAt(p) : null;
    _dragFrom = p;
    _dragNow = p;
  }

  void _dragUpdate(Offset p) => _dragNow = p;

  void _dragEnd() {
    final i = _dragCover;
    _dragCover = null;
    if (!_canPeg) return;
    final dy = _dragNow.dy - _dragFrom.dy;
    if (i == null || dy.abs() < 24) {
      _hints.missTap();
      return;
    }
    final lift = dy < 0;
    if (lift == _open.contains(i)) {
      _hints.missTap();
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.45);
    HapticFeedback.mediumImpact();
    setState(() {
      if (lift) {
        _open.add(i);
      } else {
        _open.remove(i);
      }
      _tappedCover = null;
      _wake++;
    });
  }

  void _clear() {
    if (!_canPeg) return;
    if (_run.chain.isEmpty) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _run.clearChain();
      _wake++;
    });
  }

  void _finishPeg(Offset global) {
    if (!_canPeg) return;
    if (_run.chain.length < 2) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.finishPeg();
    if (m != null) {
      setState(() {
        _look = null;
        _wake++;
      });
      unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
      unawaited(_slip(m, after: _toDig));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() => _look = null);
    _why = M6DigWhy.peg;
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(M6DigLines.whyRight[M6DigWhy.peg]!, M6DigLines.whyWrong[M6DigWhy.peg]!, widget.rng),
      question: M6DigLines.whyQ[M6DigWhy.peg]!,
      stillValid: () => !_ended && _run.stage == M6DigStage.peg,
    ));
  }

  // --- dig ------------------------------------------------------------------------
  Future<void> _toDig() async {
    if (_ended) return;
    _run.toDig();
    setState(() {
      _open.clear();
      _look = null;
      _tappedCover = null;
      _dig = _Dig.idle;
      _wake++;
    });
    _hush();
    await _say(M6DigLines.flagTeach);
    if (!mounted || _ended) return;
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700));
    if (!mounted || _ended) return;
    unawaited(_startSpot());
  }

  Offset get _parking => Offset(400, (_geoNow?.roadBottom ?? 500) - 30);

  Future<void> _startSpot() async {
    if (_ended || _lay == null) return;
    final i = _run.spot;
    _from = i == 0 ? _parking : _layout.spots[i - 1];
    _drop.value = 0;
    _travel.duration = Duration(milliseconds: _quiet ? 1 : 900);
    setState(() {
      _dig = _Dig.moving;
      _wake++;
    });
    if (!_muted) _cue('sounds/intro/impact_metal.ogg', volume: 0.25);
    try {
      await _travel.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || _ended || _run.spot != i) return;
    if (i == _run.deal.coworkerSpot && !coworkerDone) {
      // He comes now; the bucket stays up until his deck closes.
      setState(() => _dig = _Dig.waiting);
      scheduleCoworker();
      return;
    }
    unawaited(_descend());
  }

  Future<void> _descend({double from = 0}) async {
    if (_ended || _run.spotDone) return;
    final i = _run.spot;
    _drop.duration = Duration(milliseconds: _run.deal.descentMs[i]);
    setState(() => _dig = _Dig.descending);
    M6DigProbe.descending = true;
    try {
      await _drop.forward(from: from).orCancel;
    } on TickerCanceled {
      return;
    } finally {
      M6DigProbe.descending = false;
    }
    if (!mounted || _ended || _run.spot != i || _dig != _Dig.descending) return;
    _touch();
  }

  /// The red flag's ring is full.
  void _flagDone(Offset global) {
    if (!_flagLive) return;
    if (holdForCoworker()) return;
    _drop.stop();
    M6DigProbe.descending = false;
    setState(() {
      _dig = _Dig.stopped;
      _wake++;
    });
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.7);
    final m = _run.flag();
    if (m != null) {
      unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
      unawaited(_slip(m, after: _spotOverSoon));
      return;
    }
    _hush();
    _why = M6DigWhy.flag;
    putOnTable(15);
    final i = _run.spot;
    unawaited(askReason(
      deal: () => dealChoices(M6DigLines.whyRight[M6DigWhy.flag]!, M6DigLines.whyWrong[M6DigWhy.flag]!, widget.rng),
      question: M6DigLines.whyQ[M6DigWhy.flag]!,
      stillValid: () => !_ended && _run.spot == i,
    ));
  }

  /// The bucket reached the ground with no flag.
  void _touch() {
    final at = _layout.spots[_run.spot];
    final m = _run.touch();
    if (m != null) {
      _flashAt = at;
      unawaited(_deadly(m));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    setState(() {
      _dig = _Dig.over;
      _wake++;
    });
    final size = MediaQuery.sizeOf(context);
    unawaited(_levelDelta(5, Offset(size.width / 2, size.height * 0.45), mood: GuideMood.glad));
    _spotOverSoon();
  }

  void _spotOverSoon() {
    final i = _run.spot;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 800), () {
      if (mounted && !_ended && _run.spot == i) _spotOver();
    }));
  }

  void _spotOver() {
    setState(() {
      _run.nextSpot();
      _dig = _Dig.idle;
      _wake++;
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    unawaited(_startSpot());
  }

  Future<void> _mistake(DoMistake m, Offset origin, {VoidCallback? after}) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m, after: after);
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
  void onReasonPaid() {
    if (_ended) return;
    if (_why == M6DigWhy.peg) {
      unawaited(_toDig());
    } else {
      _spotOverSoon();
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6DigLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final at = _run.deal.coworkerSpot;
    if (_ended || _run.stage == M6DigStage.done || (_run.stage == M6DigStage.dig && (_run.spot > at || (_run.spot == at && _run.spotDone)))) return null;
    if (_run.stage != M6DigStage.dig || _run.spot != at || _dig != _Dig.waiting) return false;
    if (_card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (_ended) return;
    if (!held) {
      final m = _run.listen();
      if (m == null) return;
      if (m.deadly) {
        _flashAt = _layout.spots[_run.spot];
        _drop.value = 1;
        await _deadly(m);
        return;
      }
      setState(() => _dig = _Dig.over);
      await _mistake(m, origin, after: _spotOverSoon);
      return;
    }
    _run.refused();
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6DigLines.callHeld], mood: GuideMood.glad));
    // Refusing him does not stop the machine: the bucket comes down now.
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 600));
    if (!mounted || _ended || _dig != _Dig.waiting) return;
    unawaited(_descend());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6DigLines.tapWhy[_nudgeN++ % M6DigLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _drop.stop();
    _travel.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, {VoidCallback? after}) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _afterCard = after;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6dig/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The bucket through the live cable: the scene freezes grey, the arc flash
  /// bursts off it in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _drop.stop();
    _travel.stop();
    M6DigProbe.descending = false;
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _drop.value = 1;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m6dig/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6DigLines.deadlyWord : M6DigLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final after = _afterCard;
        setState(() {
          _card = null;
          _afterCard = null;
          _wake++;
        });
        if (after != null) {
          // The card's long line must not stay in the bubble over the street.
          final guide = ref.read(guideDirectorProvider.notifier);
          guide.softClearLine();
          guide.react(GuideMood.idle);
          after();
        } else {
          unawaited(_sayChain([_task]));
        }
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

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
    await _say(!_run.passed ? M6DigLines.fail : (_quickBonus ? M6DigLines.quick : M6DigLines.allSet),
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

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_dig == _Dig.descending) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6DigRig get _rig => M6DigRig(
        layout: _layout,
        drain: _run.deal.drain,
        seed: _run.deal.layoutSeed,
        open: {..._open},
        chalk: [for (final id in _run.chain) _anchorAt(id)],
        showTrue: _run.revealed,
        spotsUp: _run.stage != M6DigStage.peg,
        dug: {..._run.dug},
      );

  /// The gesture hand, peg stage only (the dig stage and the flag never get
  /// one): an upward drag on a cover that was tapped; once legs are laid,
  /// in turn a sweep over 'মুছুন' and 'পথ আঁকা শেষ'; else a sweep over the
  /// pole top, the two ends and every cover alike.
  HintSpec? _hint() {
    final geo = _geoNow;
    final lay = _lay;
    if (geo == null || lay == null || _run.stage != M6DigStage.peg) return null;
    final n = _hintN++;
    final tc = _tappedCover;
    if (tc != null) return HintSpec.drag(lay.covers[tc], toward: const Offset(0, -1), travel: 46, space: HintSpace.scene);
    if (_run.chain.length >= 2 && n.isOdd) return HintSpec.sweepOver([_clearKey, _doneKey]);
    final rects = <Rect>[
      geo.riserHit,
      geo.poleFootHit,
      for (final c in lay.covers) geo.coverHit(c),
      geo.dtrEntryHit,
    ]..sort((a, b) => a.center.dx.compareTo(b.center.dx));
    return HintSpec.sweep(rects, space: HintSpace.scene);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M6DigGeo.forScene(m.height, m.inset);
    if (_lay == null || _geoNow != geo) _lay = _run.deal.layoutOn(geo);
    _geoNow = geo;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final dig = _run.stage != M6DigStage.peg && _dig != _Dig.idle && _run.spot < 3;
    final look = _look;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('street'),
                child: RepaintBoundary(child: CustomPaint(painter: M6DigPainter(geo: geo, rig: _rig))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (dig)
                Positioned.fill(
                  key: const ValueKey('digger'),
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: M6DiggerPainter(spot: _layout.spots[_run.spot], from: _from, drop: _drop, travel: _travel, stepped: quiet),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6DigLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A cover is judged where the finger went down, not where the
            // drag passed the slop.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition),
            onVerticalDragStart: (d) => _dragStart(d.localPosition),
            onVerticalDragUpdate: (d) => _dragUpdate(d.localPosition),
            onVerticalDragEnd: (_) => _dragEnd(),
          ),
        ),
      ),
      if (look != null && !_freeze && _run.stage == M6DigStage.peg)
        Positioned.fromRect(
          key: ValueKey('look-$_lookTok'),
          rect: M6DigGeo.card,
          child: IgnorePointer(child: CustomPaint(painter: M6LookPainter(look: look))),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6DigFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final pegHands = playing && _run.stage == M6DigStage.peg && !_run.pegRight && !_run.revealed && !deckUp && !coworkerOpen && _card == null;
    final flagUp = playing && _run.stage == M6DigStage.dig && !deckUp && _card == null;
    final stepNow = _run.stage == M6DigStage.peg ? 0 : (_run.done ? null : _run.spot + 1);
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
              labels: [M6DigLines.stepPeg, for (var i = 0; i < 3; i++) M6DigLines.stepDig(i)],
              done: {
                if (_run.stage != M6DigStage.peg) 0,
                for (var i = 0; i < math.min(_run.spot, 3); i++)
                  if (_run.stage != M6DigStage.peg) i + 1,
              },
              current: stepNow,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: pegHands && !tableBusy,
            hintKey: 'peg/${_run.chain.length}/${_open.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (pegHands)
                Positioned(
                  key: const ValueKey('hud-peg'),
                  left: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ChalkButton(key: _clearKey, label: M6DigLines.clear, icon: Icons.backspace_outlined, onTap: (_) => _clear()),
                      const SizedBox(width: 10),
                      _ChalkButton(key: _doneKey, label: M6DigLines.pegDone, icon: Icons.check_rounded, strong: true, onTap: _finishPeg),
                    ],
                  ),
                ),
              if (flagUp)
                Positioned(
                  key: const ValueKey('hud-flag'),
                  left: 16,
                  bottom: pad.bottom + 10,
                  width: 92,
                  height: 92,
                  child: _FlagPad(
                    key: ValueKey('flag-${_run.spot}'),
                    label: M6DigLines.flag,
                    ms: m6FlagHoldMs,
                    enabled: _flagLive,
                    onDone: _flagDone,
                  ),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.spot}-$strikes'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: () {
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
                  sound: FailSound.thud,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2400,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M6DigLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
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

/// A chalk-board button under the scene ('মুছুন', 'পথ আঁকা শেষ').
class _ChalkButton extends StatelessWidget {
  const _ChalkButton({super.key, required this.label, required this.icon, required this.onTap, this.strong = false});
  final String label;
  final IconData icon;
  final ValueChanged<Offset> onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: strong ? const Color(0xFF1C2E4A) : const Color(0xCC0B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: strong ? 0.95 : 0.6), width: strong ? 1.8 : 1.4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The red flag: press and hold — a ring fills over [ms]; [onDone] when full.
/// Let go early and the ring empties (nothing happens). Pressed while not yet
/// [enabled], the hold is kept and its ring starts once enabled. Draws nothing while
/// not held (idle = no frames). Never hinted.
class _FlagPad extends StatefulWidget {
  const _FlagPad({super.key, required this.label, required this.ms, required this.enabled, required this.onDone});
  final String label;
  final int ms;
  final bool enabled;
  final ValueChanged<Offset> onDone;

  @override
  State<_FlagPad> createState() => _FlagPadState();
}

class _FlagPadState extends State<_FlagPad> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && _down) {
        _fired = true;
        widget.onDone(_at);
      }
    });
  var _fired = false;
  var _down = false;
  Offset _at = Offset.zero;

  @override
  void didUpdateWidget(_FlagPad old) {
    super.didUpdateWidget(old);
    if (!widget.enabled && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
    // A flag already held when the bucket starts down (pressed during the
    // drive, or right after refusing him) starts its ring now: a steady,
    // early hold is the right instinct and must count.
    if (widget.enabled && !old.enabled && _down && !_fired) unawaited(_c.forward(from: 0));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _press(PointerDownEvent e) {
    _down = true;
    _fired = false;
    _at = e.position;
    HapticFeedback.selectionClick();
    if (!widget.enabled) return;
    unawaited(_c.forward(from: 0));
  }

  void _release() {
    if (!_down || !mounted) return;
    _down = false;
    if (!_fired) _c.stop();
    _c.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _press,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: CustomPaint(
          foregroundPainter: _RingPainter(_c),
          child: Center(
            child: Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: on ? const [Color(0xFFE5483C), Color(0xFF9E2219)] : const [Color(0xFF8A5A55), Color(0xFF4E2E2B)]),
                border: Border.all(color: const Color(0xFF2A0E0B), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: CustomPaint(size: const Size(34, 34), painter: _FlagIconPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagIconPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    c.drawLine(Offset(size.width * 0.28, size.height * 0.08), Offset(size.width * 0.28, size.height * 0.95), Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF2EEE4));
    c.drawPath(
        Path()
          ..moveTo(size.width * 0.3, size.height * 0.1)
          ..quadraticBezierTo(size.width * 0.6, size.height * 0.02, size.width * 0.9, size.height * 0.16)
          ..lineTo(size.width * 0.9, size.height * 0.5)
          ..quadraticBezierTo(size.width * 0.6, size.height * 0.38, size.width * 0.3, size.height * 0.48)
          ..close(),
        Paint()..color = const Color(0xFFFFE9E4));
  }

  @override
  bool shouldRepaint(_FlagIconPainter old) => false;
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v) : super(repaint: v);
  final Animation<double> v;

  @override
  void paint(Canvas canvas, Size size) {
    final t = v.value;
    if (t <= 0) return;
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 3;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0x55FFFFFF));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * t, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = SlmColors.gold300);
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}
