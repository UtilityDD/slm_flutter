import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'm6_ab_unjam_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_ab_unjam_world.dart' show M6UnjamStage, M6UnjamType;

// Lesson 6.4 "AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার", কাজ 2 "জ্যাম ছাড়াও,
// লাইন জোড়ো" (pack do_6_4_b, rung 6.4/do/1, engineType m6_ab_unjam). The
// patrol reported that the DP's AB switch does not work properly. The crew has
// it under শাটডাউন (docket 'শাটডাউন · PTW · আর্থ': the feeder breaker off, the
// AB open, proved dead, earthed — X1, staged, not scored); the trainee is on
// the platform in harness at the switch head:
//
//  Feel: rock the operating lever left and right (a swipe on it); the jammed
//    oil point (one blade's crank pivot, or the common rod's bearing) lags
//    with a creak. Found only by feel.
//  Oil (the core): the oil can from the pouch, a hold on an oil point drips
//    oil; then rock 3–5 times (dealt) until all three blades swing together.
//    Oiling the other points costs nothing; an unoiled jam never frees.
//  Clean: the cloth from the pouch, rubbed back and forth over a jaw (the
//    arcing marks fade: 1–3 phases dealt) and over a dirty post insulator
//    (0–2 dealt). Grime is drawn real; no ticks, no done button.
//  Down: hold the lanyard. A dirty part left = a slip (he stays up). The
//    first clean descent puts ◆ on the table → "কেন …?" (lubricate / clean
//    the contacts / the insulators — fits what he did). Then the line clear
//    (the crew takes the earths off, the PTW goes back; staged).
//  Ground: the ground handle (hold the knob, one firm swing along its arc),
//    the phone to the substation, and a swipe up for the tilt-up view of the
//    three blades. A jam left shows here as a part-seated blade (leftovers
//    are consequences): open again, back up (the crew re-isolates and earths
//    first: staged), free it, down, close. Breaker ON asked with all three
//    seated → the houses light → ◆ → reason → pass.
//
// Deadly (module 6 table R5, owner decision 4, X3; R39 by B1): an AB closed
// with the breaker already ON (asked while the AB was open, then the stroke);
// listening to 'আগে ব্রেকার দিতে বলো' at the handle. Slips (R35, M6-3): coming
// down with dirt or arcing marks left; breaker ON asked with a part-seated
// phase (his own ask, or listening to the coworker at the phone); breaker ON
// asked with all three seated but not looked at after the close (pro tips 2
// and 4: check all three phases); a stalled
// stroke (only a stall: speed is never a slip); breaker ON asked first and then
// cancelled before the stroke. Three slips strike out.
//
// The coworker, once a play, his place from the player's work: at the handle
// when the work was good (myth 2: isolator and breaker are the same → ask the
// breaker first; deadly), or at the phone when a phase sits part way ('একটু
// আলগা … লাইন দিয়ে দাও'; slip). The handle and the phone both wait for him
// (holdForCoworker).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_ab_unjam_world.dart), corner guide, ReasonTable (the "কেন?"
// cards at once), CoworkerMoment, gesture hands for every waiting state (how,
// never what), MistakeCard, FreezeFrame + DoDeathGuard, DoStrikeOut, the pass
// panel with stars. Idle = zero frames (the rock and the fades are one-shots).

// ============================================================================
// Content
// ============================================================================

/// The pouch on the platform. [cloth] and [can] are taken in hand (tap);
/// [lanyard] is a hold (down; on the ground after a reopen: back up).
enum M6UnjamTool { cloth, can, lanyard }

/// The coworker's push (one a play; which one comes from the player's work).
enum M6UnjamPush { breakerFirst, loose }

/// What a reason asks about.
enum M6UnjamWhy { oil, clean, insulators, order, partSeat }

/// What a rock of the lever felt like.
enum M6UnjamRock { none, jammed, easing, freed, together }

/// A rub place: a jaw (with the blade's contact) or a post insulator.
enum M6UnjamRub { jaw, insulator }

/// Grime below this counts as clean.
const double m6UnjamClean = 0.05;

/// The rub path (design px, back and forth inside the place) that clears one
/// dirty place.
const double m6UnjamRubPath = 160;

abstract final class M6AbUnjamLines {
  static const title = 'জ্যাম ছাড়াও, লাইন জোড়ো';

  // DRAFT wording — owner (M6-12): every guide line below is new text.
  static const intro = 'টহলে খবর এসেছে — AB সুইচটা ঠিকমতো চলছে না। শাটডাউনে সারিয়ে লাইন ফেরান।';
  static const askHead = 'সুইচটা ঠিক করুন, কাজ শেষ হলে নিচে নামুন।';
  static const askGround = 'এবার লাইন চালু করুন।';
  static const tasks = [askHead, askGround];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static String ask(M6UnjamStage s) => s == M6UnjamStage.head ? askHead : askGround;

  // On screen (a worker's own words; not spoken).
  static const docketShutdown = 'শাটডাউন · PTW · আর্থ';
  static const docketClear = 'লাইন ক্লিয়ার';
  static const docketLive = 'লাইন চালু';
  static const cutClear = 'আর্থ খোলা হলো · PTW ফেরত';
  // DRAFT (on screen) — the crew's X1 steps: PTW, isolate, the tester, earths.
  static const cutUp = 'আবার শাটডাউন · PTW · টেস্টার · আর্থ';
  static const sceneHead = 'AB সুইচের মাথা';
  static const sceneGround = 'AB-র হ্যান্ডেল আর ফোন';
  static const phoneTitle = 'সাবস্টেশন';
  static const phoneIdle = 'ফিডারের ব্রেকার বন্ধ আছে';
  static const phoneOn = 'ব্রেকার ON করা হলো';
  static const phoneOffAgain = 'ব্রেকার আবার বন্ধ করা হলো';
  static const phoneAsk = 'ব্রেকার ON করতে বলুন';
  static const phoneCancel = 'ব্রেকার বন্ধ করতে বলুন';
  static const phoneClose = 'বন্ধ';
  static const stages = ['সুইচ মেরামত', 'লাইন চালু'];

  static String tool(M6UnjamTool t) => switch (t) {
        M6UnjamTool.cloth => 'কাপড়',
        M6UnjamTool.can => 'তেলের ক্যান',
        M6UnjamTool.lanyard => 'ল্যানিয়ার্ড',
      };

  // The reasons. The right ones fit what was done (lesson 6.4 points 2 and 4,
  // pro tip 2); the wrong ones are the lesson's myths and field excuses.
  // DRAFT wording — owner. 41–49 letters.
  static const whyQ = <M6UnjamWhy, String>{
    M6UnjamWhy.oil: 'কেন মেকানিজমে লুব্রিকেন্ট দিলেন?',
    M6UnjamWhy.clean: 'কেন জ আর ব্লেড পরিষ্কার করলেন?',
    M6UnjamWhy.insulators: 'কেন ইনসুলেটর মুছলেন?',
    M6UnjamWhy.order: 'কেন আগে আইসোলেটর লাগালেন, পরে ব্রেকার?',
    M6UnjamWhy.partSeat: 'কেন আলগা ফেজে লাইন দিলেন না?',
  };
  static const whyRight = <M6UnjamWhy, List<String>>{
    M6UnjamWhy.oil: ['জ্যাম মেকানিজমে তেল দিলে তিন ফেজ একসাথে চলে', 'তেল না দিলে জ্যাম ছাড়ে না, একটা ফেজ আটকে যায়'],
    M6UnjamWhy.clean: ['জ আর ব্লেড পরিষ্কার রাখাই প্রধান রক্ষণাবেক্ষণ', 'আর্কিং-এর দাগ মুছে কন্টাক্ট পরিষ্কার রাখতে হয়'],
    M6UnjamWhy.insulators: ['ইনসুলেটর পরিষ্কার রাখাও AB-র রক্ষণাবেক্ষণের কাজ', 'ময়লা ইনসুলেটর মুছে রাখা নিয়মিত রক্ষণাবেক্ষণ'],
    M6UnjamWhy.order: ['আইসোলেটর OFF-লোড যন্ত্র — লোডে লাগালে প্রচণ্ড আর্ক', 'লাইন চালুর ক্রম: আগে আইসোলেটর, তারপর ব্রেকার'],
    M6UnjamWhy.partSeat: ['আংশিকভাবে লাগা কন্টাক্ট একটি হটস্পট তৈরি করে', 'তিন ফেজই পুরো না লাগলে লাইন দেওয়া চলে না'],
  };
  static const myths = [
    'আইসোলেটর আর সার্কিট ব্রেকার আসলে একই জিনিস',
    'সামান্য লোড থাকলে আইসোলেটর খোলা যায়, কিছু হয় না',
    'একটু আলগা লাগলেও লাইন দিব্যি ঠিকঠাক চলে যায়',
    'আগে ব্রেকার দিলে সময় বাঁচে, কোনো ক্ষতি নেই',
    'আর্কিং-এর দাগ শুধু দেখতে খারাপ, আর কিছু না',
    'জোরে টানলেই জ্যাম ছেড়ে যায়, তেল লাগে না',
    'ইনসুলেটরে একটু ময়লা থাকলে কিছু যায় আসে না',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play). DRAFT wording — owner; his two
  // pushes need recording (tool/rival_clip.py).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerBreakerFirst = CoworkerScript(
    line: 'আইসোলেটর আর ব্রেকার একই জিনিস — আগে ব্রেকার দিতে বলো।',
    exitLine: coworkerExit,
    right: ['না, আগে আইসোলেটর, তারপর ব্রেকার', 'না, দুটো আলাদা যন্ত্র, ক্রম মানব', 'না, লোডে আইসোলেটর লাগানো যায় না'],
    wrong: [
      'ঠিক, আগে ব্রেকারটা দিতে বলি',
      'আচ্ছা, দুটো তো আসলে একই জিনিস',
      'হ্যাঁ, ক্রমে কিছু যায় আসে না',
      'ঠিক আছে, আগে সাবস্টেশনে ফোন করি',
      'হ্যাঁ, ব্রেকার আগে দিলে সময় বাঁচে',
    ],
    asks: ['কী করবেন?', 'ও বলছে আগে ব্রেকার দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerLoose = CoworkerScript(
    line: 'একটু আলগা লেগেছে, ও চলবে — লাইন দিয়ে দাও।',
    exitLine: coworkerExit,
    right: ['না, আগে তিন ফেজই পুরো লাগাব', 'না, আলগা ফেজে হটস্পট হবে', 'না, খুলে ঠিক করে তবে লাইন'],
    wrong: [
      'ঠিক, একটু আলগায় কিছু হয় না',
      'আচ্ছা, লাইনটা দিয়েই দিই',
      'হ্যাঁ, পরে একদিন ঠিক করা যাবে',
      'ঠিক আছে, ও চলবে নিশ্চয়ই',
      'হ্যাঁ, আবার ওঠার ঝামেলা কে করে',
    ],
    asks: ['কী করবেন?', 'ও বলছে আলগা ফেজেই লাইন দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6UnjamPush p) => switch (p) {
        M6UnjamPush.breakerFirst => coworkerBreakerFirst,
        M6UnjamPush.loose => coworkerLoose,
      };
  static const allCoworkers = [coworkerBreakerFirst, coworkerLoose];

  static String callHeld(M6UnjamPush p) => switch (p) {
        M6UnjamPush.breakerFirst => 'ঠিক! দুটো আলাদা যন্ত্র — আগে আইসোলেটর, তারপর ব্রেকার।',
        M6UnjamPush.loose => 'ঠিক! আলগা ফেজে লাইন নয় — খুলে ঠিক করুন।',
      };

  static const allSet = 'সুইচ সচল, তিন ফেজ পুরো লাগানো, ক্রমও ঠিক — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — সুইচ সারিয়ে, পরিষ্কার করে, তবে ঠিক ক্রমে লাইন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (on screen).
  static const caughtOil = 'জ্যাম মেকানিজমে তেল দিয়ে ছাড়িয়েছেন';
  static const caughtClean = 'কন্টাক্ট আর ইনসুলেটর পরিষ্কার করে নেমেছেন';
  static const caughtOrder = 'আগে আইসোলেটর, তারপর ব্রেকার';
  static const caughtSeat = 'আলগা ফেজ দেখে খুলে ঠিক করেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken guide line (DRAFT wording — owner; to be recorded).
  static const newGuideLines = [
    intro,
    askHead,
    askGround,
    'কেন মেকানিজমে লুব্রিকেন্ট দিলেন?',
    'কেন জ আর ব্লেড পরিষ্কার করলেন?',
    'কেন ইনসুলেটর মুছলেন?',
    'কেন আগে আইসোলেটর লাগালেন, পরে ব্রেকার?',
    'কেন আলগা ফেজে লাইন দিলেন না?',
    'ঠিক! দুটো আলাদা যন্ত্র — আগে আইসোলেটর, তারপর ব্রেকার।',
    'ঠিক! আলগা ফেজে লাইন নয় — খুলে ঠিক করুন।',
    allSet,
    fail,
    'ও বলছে আগে ব্রেকার দিতে। কী করবেন?',
    'ও বলছে আলগা ফেজেই লাইন দিতে। কী করবেন?',
    M6AbUnjamMistakes.uncheckedAskBn,
  ];

  /// The coworker's new pushes (DRAFT wording — owner; to be recorded in his
  /// voice). His exit line is recorded already.
  static const newRivalLines = [
    'আইসোলেটর আর ব্রেকার একই জিনিস — আগে ব্রেকার দিতে বলো।',
    'একটু আলগা লেগেছে, ও চলবে — লাইন দিয়ে দাও।',
  ];
}

abstract final class M6AbUnjamMistakes {
  static const _dir = 'assets/game/art/m6_ab_unjam';

  // Lesson 6.4 points (0-based): 0 the AB and the daily check (contacts seated,
  // arcing marks), 1 the off-load golden rule and the restore order, 2 the
  // types, 3 operation (one firm stroke) and maintenance.
  // DRAFT wording — owner (every text below is read aloud the first time).
  static const closeOnLoad = DoMistake(
    key: '6.4/m6_ab_unjam/close-on-load',
    textBn: 'ব্রেকার ON থাকা অবস্থায় AB লাগালেন — লোডে প্রচণ্ড আর্ক! লাইন চালুর সময় প্রথমে আইসোলেটর লাগান, তারপর সার্কিট ব্রেকার ON করুন।',
    art: '$_dir/close_on_load.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const listenBreakerFirst = DoMistake(
    key: '6.4/m6_ab_unjam/listen-breaker-first',
    textBn: 'আইসোলেটর আর সার্কিট ব্রেকার এক নয় — দুটি সম্পূর্ণ ভিন্ন যন্ত্র! আগে ব্রেকার ON করলে AB লাগাতে হবে লোডে — যাতে মারাত্মক আর্ক হবে।',
    art: '$_dir/close_on_load.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const dirtLeft = DoMistake(
    key: '6.4/m6_ab_unjam/dirt-left',
    textBn: 'কাজ শেষ না করে নামবেন না: জ আর ব্লেডের আর্কিং-এর দাগ আর ইনসুলেটরের ময়লা পরিষ্কার করে তবে নামুন।',
    art: '$_dir/dirt_left.svg',
    lessonPoint: 3,
  );
  static const partSeatedOn = DoMistake(
    key: '6.4/m6_ab_unjam/part-seated-on',
    textBn: 'একটা ফেজ পুরো লাগেনি! আংশিকভাবে লাগা কন্টাক্ট একটি হটস্পট তৈরি করবে। খুলে, জ্যাম সারিয়ে, তিন ফেজ পুরো লাগিয়ে তবে লাইন।',
    art: '$_dir/part_seated.svg',
    lessonPoint: 0,
  );
  static const pushLoose = DoMistake(
    key: '6.4/m6_ab_unjam/push-loose',
    textBn: '“একটু আলগা” মানেই হটস্পট — আংশিকভাবে লাগা কন্টাক্টে লাইন দেওয়া নয়। খুলে ঠিক করে তবে লাইন।',
    art: '$_dir/part_seated.svg',
    lessonPoint: 0,
  );
  static const stall = DoMistake(
    key: '6.4/m6_ab_unjam/stall',
    textBn: 'হ্যান্ডেল দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত ঘোরান — মাঝপথে থামবেন না।',
    art: '$_dir/stall.svg',
    lessonPoint: 3,
  );
  static const askCancel = DoMistake(
    key: '6.4/m6_ab_unjam/ask-cancel',
    textBn: 'AB খোলা রেখে ব্রেকার ON চাওয়া উল্টো ক্রম। আগে আইসোলেটর লাগান, তারপর ব্রেকার ON করতে বলুন।',
    art: '$_dir/ask_cancel.svg',
    lessonPoint: 1,
  );

  /// Breaker ON asked with all three seated but never looked at after the
  /// close (lesson 6.4 pro tips 2 and 4: check all three phases after the
  /// operation). A slip; the substation puts it off again.
  // DRAFT wording — owner
  static const uncheckedAskBn = 'AB লাগানোর পর আগে তাকিয়ে দেখুন তিনটি ফেজের কন্টাক্টই পুরো লেগেছে কি না — না দেখে ব্রেকার ON চাওয়া নয়।';
  static const uncheckedAsk = DoMistake(
    key: '6.4/m6_ab_unjam/unchecked-ask',
    textBn: uncheckedAskBn,
    art: '$_dir/part_seated.svg',
    lessonPoint: 0,
  );

  static DoMistake push(M6UnjamPush p) => switch (p) {
        M6UnjamPush.breakerFirst => listenBreakerFirst,
        M6UnjamPush.loose => pushLoose,
      };

  static const List<DoMistake> all = [closeOnLoad, listenBreakerFirst, dirtLeft, partSeatedOn, pushLoose, stall, askCancel, uncheckedAsk];
}

/// One play's deal.
@immutable
class M6UnjamDeal {
  const M6UnjamDeal({
    required this.type,
    required this.jam,
    required this.stuck,
    required this.rocks,
    required this.arcs,
    required this.dirtyIns,
    required this.pouch,
    required this.whyRoll,
  });

  final M6UnjamType type;

  /// The jammed oil point: 0–2 a blade's crank pivot (R, Y, B), 3 the
  /// common rod's bearing.
  final int jam;

  /// The phase that lags and, if the jam is left, sits part way at the close
  /// (the pivot's own phase; for the bearing, dealt).
  final int stuck;

  /// Rocks after the oil until the jam frees (3–5).
  final int rocks;

  /// The phases with arcing marks (1–3) and the dirty insulators (0–2).
  final Set<int> arcs;
  final Set<int> dirtyIns;

  /// The pouch's order (never the working order).
  final List<M6UnjamTool> pouch;

  /// Picks the reason topic among those that fit.
  final int whyRoll;
}

M6UnjamDeal m6UnjamDeal(math.Random rng) {
  final type = M6UnjamType.values[rng.nextInt(2)];
  final jam = rng.nextInt(4);
  final stuck = jam < 3 ? jam : rng.nextInt(3);
  final rocks = 3 + rng.nextInt(3);
  final phases = [0, 1, 2]..shuffle(rng);
  final arcs = phases.take(1 + rng.nextInt(3)).toSet();
  final ins = [0, 1, 2]..shuffle(rng);
  final dirtyIns = ins.take(rng.nextInt(3)).toSet();
  final pouch = [...M6UnjamTool.values]..shuffle(rng);
  return M6UnjamDeal(type: type, jam: jam, stuck: stuck, rocks: rocks, arcs: arcs, dirtyIns: dirtyIns, pouch: pouch, whyRoll: rng.nextInt(1000));
}

/// The descent's reason topic: one that fits what was done (the oil only if
/// the jam is free; the insulators only if some were dirty).
M6UnjamWhy m6UnjamMaintWhy(M6UnjamDeal d, {required bool freed}) {
  final fits = [M6UnjamWhy.clean, if (freed) M6UnjamWhy.oil, if (d.dirtyIns.isNotEmpty) M6UnjamWhy.insulators];
  return fits[d.whyRoll % fits.length];
}

/// The restore's reason topic: the order, or the part-seated phase when he
/// caught one this play and never put the line on it ([refusedPartSeat]: he
/// reopened a part-seated AB with no part-seated-on or push-loose slip). A
/// player who did ask for the line on a loose phase is never asked why he
/// did not.
M6UnjamWhy m6UnjamFinalWhy(M6UnjamDeal d, {required bool refusedPartSeat}) => refusedPartSeat && d.whyRoll.isEven ? M6UnjamWhy.partSeat : M6UnjamWhy.order;

/// The coworker's moment: at the handle while the AB is still open after a
/// good repair; at the phone while a phase sits part way.
bool m6UnjamPushFits(M6UnjamPush p, M6UnjamRun r) => switch (p) {
      M6UnjamPush.breakerFirst => r.stage == M6UnjamStage.ground && !r.earths && !r.abClosed && !r.breakerOn && r.freed,
      M6UnjamPush.loose => r.stage == M6UnjamStage.ground && !r.earths && r.partSeated && !r.breakerOn,
    };

/// The gesture hand with the can in hand (how, never what): on even turns a
/// sweep over all four oil points alike; on odd turns a press-and-hold on
/// one of them, a different one each time in a fixed round (R, Y, B pivots,
/// then the bearing) that never looks at the deal, so it never points at the
/// jam. Oiling a free point costs nothing.
HintSpec m6UnjamCanHint(M6UnjamGeo geo, int n) => n.isEven
    ? HintSpec.sweep([for (var i = 0; i < 4; i++) geo.pivotHit(i)], space: HintSpace.scene)
    : HintSpec.hold(geo.pivot((n ~/ 2) % 4), space: HintSpace.scene);

/// The play state (pure logic).
class M6UnjamRun {
  M6UnjamRun(this.deal)
      : jawDirt = [for (var i = 0; i < 3; i++) deal.arcs.contains(i) ? 1.0 : 0.0],
        insDirt = [for (var i = 0; i < 3; i++) deal.dirtyIns.contains(i) ? 1.0 : 0.0];

  final M6UnjamDeal deal;

  M6UnjamStage stage = M6UnjamStage.head;

  // The head.
  final Set<int> oiled = {};
  int rocksAfterOil = 0;
  var freed = false;
  final List<double> jawDirt;
  final List<double> insDirt;
  var _dirtSlip = false;

  /// The crew's earths are on (under the PTW).
  var earths = true;
  int descents = 0;

  // The ground.
  var abClosed = false;
  int strokes = 0;
  var looked = false;
  var breakerOn = false;
  var askedOpen = false;
  var restored = false;

  /// He opened the AB again while a phase sat part way (caught it).
  var reopenedAfterSeat = false;

  /// He put (or let) the line on a part-seated phase: his own ask, or
  /// listening to the coworker at the phone.
  var seatSlip = false;
  var cancelled = false;

  /// The coworker's push this play (set when he is scheduled).
  M6UnjamPush? push;

  int slips = 0;
  int stageSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get ended => restored || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => restored && deadly == null && percent >= 55;
  bool get _open => deadly == null && !restored;
  bool get partSeated => abClosed && !freed;
  /// He caught the part-seated phase and never put the line on it: the
  /// part-seat reason and the "আজ যা ধরলেন" line fit only then.
  bool get refusedPartSeat => reopenedAfterSeat && !seatSlip;
  bool get dirtLeft => jawDirt.any((d) => d > m6UnjamClean) || insDirt.any((d) => d > m6UnjamClean);

  /// How much the jam still holds (the drawing's lag).
  double get lag => freed ? 0 : (oiled.contains(deal.jam) ? 1 - 0.7 * rocksAfterOil / deal.rocks : 1);

  /// The lanyard on the ground: back up after a reopen.
  bool get canClimb => _open && stage == M6UnjamStage.ground && !earths && !abClosed && !breakerOn && strokes > 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  // --- the head --------------------------------------------------------------
  /// A rock of the lever: the jam frees only after its point had oil and
  /// enough rocks.
  M6UnjamRock rock() {
    if (!_open || stage != M6UnjamStage.head) return M6UnjamRock.none;
    if (freed) return M6UnjamRock.together;
    if (!oiled.contains(deal.jam)) return M6UnjamRock.jammed;
    rocksAfterOil++;
    if (rocksAfterOil >= deal.rocks) {
      freed = true;
      _tag(M6AbUnjamLines.caughtOil);
      return M6UnjamRock.freed;
    }
    return M6UnjamRock.easing;
  }

  /// Oil on point [i] (the can in hand); true if it is new.
  bool oil(int i) {
    if (!_open || stage != M6UnjamStage.head || i < 0 || i > 3) return false;
    return oiled.add(i);
  }

  /// The cloth over a place by [path] design px; true if it is clean now (and
  /// was not before).
  bool rub(M6UnjamRub kind, int i, double path) {
    if (!_open || stage != M6UnjamStage.head) return false;
    final l = kind == M6UnjamRub.jaw ? jawDirt : insDirt;
    if (l[i] <= m6UnjamClean) return false;
    l[i] = math.max(0.0, l[i] - path / m6UnjamRubPath);
    if (l[i] <= m6UnjamClean) {
      l[i] = 0;
      return true;
    }
    return false;
  }

  /// Hold the lanyard: down, unless a dirty part is left (a slip; he stays
  /// up). A jam left is no slip here: it shows at the close.
  DoMistake? comeDown() {
    if (!_open || stage != M6UnjamStage.head) return null;
    if (dirtLeft) {
      _dirtSlip = true;
      return _slip(M6AbUnjamMistakes.dirtLeft);
    }
    stage = M6UnjamStage.ground;
    descents++;
    looked = false;
    if (descents == 1 && !_dirtSlip) _tag(M6AbUnjamLines.caughtClean);
    return null;
  }

  /// The crew takes the earths off and returns the PTW (the line clear).
  void lineClear() {
    if (stage == M6UnjamStage.ground) earths = false;
  }

  /// Back up after a reopen (the crew re-isolates and earths first). True if
  /// it happened.
  bool climbUp() {
    if (!canClimb) return false;
    stage = M6UnjamStage.head;
    earths = true;
    return true;
  }

  // --- the ground ------------------------------------------------------------
  /// One stroke of the ground handle (it closes an open AB, opens a closed
  /// one). With the breaker already ON: closing on load (deadly), even when
  /// the stroke stalls mid-arc — a stroke begun toward live jaws is the AB
  /// operated on load (X3). Otherwise [stalled]: stopped mid-arc (a slip;
  /// nothing moves).
  DoMistake? stroke({bool stalled = false}) {
    if (!_open || stage != M6UnjamStage.ground || earths) return null;
    if (breakerOn) return deadly = M6AbUnjamMistakes.closeOnLoad;
    if (stalled) return _slip(M6AbUnjamMistakes.stall);
    if (partSeated) reopenedAfterSeat = true;
    abClosed = !abClosed;
    strokes++;
    looked = false;
    return null;
  }

  /// The swipe up: the three blades seen.
  void look() {
    if (!_open || stage != M6UnjamStage.ground) return;
    looked = true;
  }

  /// Breaker ON asked by phone. The AB open: it goes on (no slip yet: the
  /// stroke after it is deadly, a cancel a slip). Closed with a phase part
  /// way: a slip (the substation puts it off again). Closed and seated but
  /// the three blades not looked at since the close: a slip too (pro tips 2
  /// and 4; put off again). Closed, seated and looked at: the line is
  /// restored.
  DoMistake? askBreaker() {
    if (!_open || stage != M6UnjamStage.ground || earths || breakerOn) return null;
    if (!abClosed) {
      breakerOn = true;
      askedOpen = true;
      return null;
    }
    if (!freed) {
      seatSlip = true;
      return _slip(M6AbUnjamMistakes.partSeatedOn);
    }
    if (!looked) return _slip(M6AbUnjamMistakes.uncheckedAsk);
    breakerOn = true;
    restored = true;
    if (!cancelled) _tag(M6AbUnjamLines.caughtOrder);
    if (refusedPartSeat) _tag(M6AbUnjamLines.caughtSeat);
    return null;
  }

  /// Breaker OFF asked again before the stroke (ask-then-cancel): a slip.
  DoMistake? cancelBreaker() {
    if (!_open || !askedOpen || !breakerOn || abClosed) return null;
    breakerOn = false;
    askedOpen = false;
    cancelled = true;
    return _slip(M6AbUnjamMistakes.askCancel);
  }

  /// Listened to the coworker: his push's class (B1).
  DoMistake listen(M6UnjamPush p) {
    switch (p) {
      case M6UnjamPush.breakerFirst:
        return deadly = M6AbUnjamMistakes.listenBreakerFirst;
      case M6UnjamPush.loose:
        seatSlip = true;
        return _slip(M6AbUnjamMistakes.pushLoose);
    }
  }

  /// The table was paid: the next stage's slips count afresh.
  void tablePaid() => stageSlips = 0;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   head: rock, can, oil × 2 holds, rock × 4, cloth, rub 3 places × 2.5 s,
///     lanyard hold                                            ≈ 22000
///   the descent's reason ~8200, fade + line clear ~3000
///   ground: stroke, swipe up, phone + ask ≈ 5500, houses 1200, reason ~8200
///   the coworker once ≈ 9600                                  ≈ 57700
/// 85 % ≈ 49000 → 50 s.
const m6AbUnjamQuickMs = 50000;

/// Test hook: the play state of the page now on screen (tests only).
abstract final class M6AbUnjamProbe {
  @visibleForTesting
  static M6UnjamRun? run;
}

@immutable
class M6AbUnjamPack {
  const M6AbUnjamPack({required this.id, required this.titleBn, this.quickMs = m6AbUnjamQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6AbUnjamPack> m6AbUnjamPacks = {
  'do_6_4_b': M6AbUnjamPack(id: 'do_6_4_b', titleBn: M6AbUnjamLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M6AbUnjamPage extends StatefulWidget {
  const M6AbUnjamPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6AbUnjamPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6AbUnjamPage> createState() => _M6AbUnjamPageState();
}

class _M6AbUnjamPageState extends State<M6AbUnjamPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _UnjamRunPage(
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

class _UnjamRunPage extends ConsumerStatefulWidget {
  const _UnjamRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6AbUnjamPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_UnjamRunPage> createState() => _UnjamRunPageState();
}

/// What a pan on the scene is doing.
enum _Pan { none, lever, rub, stroke, swipe }

class _UnjamRunPageState extends ConsumerState<_UnjamRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6UnjamRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  late final AnimationController _rock = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  Timer? _rockTimer;

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  /// The tool in hand on the head (the cloth or the can).
  M6UnjamTool? _held;

  /// A cutscene running ('clear', 'up'); the scene takes no touch.
  String? _cut;
  Timer? _cutTimer;

  // The ground.
  var _phoneOpen = false;
  String _phoneNote = M6AbUnjamLines.phoneIdle;
  double _handle = 0;
  var _stroking = false;
  Timer? _stallTimer;
  var _looking = false;
  var _hot = false;
  double _lit = 0;
  var _handleTouched = false;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M6UnjamTool, GlobalKey> _toolKeys = {for (final t in M6UnjamTool.values) t: GlobalKey()};
  final _handleKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _phoneButtonKey = GlobalKey();
  final _phoneCloseKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6UnjamGeo? _geoNow;

  // A pan on the scene.
  _Pan _pan = _Pan.none;
  Offset _panFrom = Offset.zero;
  Offset _panNow = Offset.zero;
  M6UnjamRub _rubKind = M6UnjamRub.jaw;
  int _rubAt = 0;

  @override
  void initState() {
    super.initState();
    _run = M6UnjamRun(m6UnjamDeal(widget.rng));
    M6AbUnjamProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _rockTimer?.cancel();
    _cutTimer?.cancel();
    _stallTimer?.cancel();
    _rock.dispose();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
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

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && _cut == null && !_run.ended;

  String get _task => M6AbUnjamLines.ask(_run.stage);

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  // --- the head ----------------------------------------------------------------
  void _tapTool(M6UnjamTool t) {
    if (!_canPlay) return;
    if (t == M6UnjamTool.lanyard) {
      // A hold control: a plain tap does nothing (the hand shows the pouch).
      _hints.missTap();
      return;
    }
    if (_run.stage != M6UnjamStage.head) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _held = _held == t ? null : t;
      _wake++;
    });
  }

  void _holdLanyard() {
    if (!_canPlay) return;
    if (_run.stage == M6UnjamStage.head) {
      unawaited(_comeDown());
    } else {
      _climbUp();
    }
  }

  void _rockOnce() {
    final r = _run.rock();
    if (r == M6UnjamRock.none) return;
    if (_quiet) {
      _rockTimer?.cancel();
      _rock.value = 0.5;
      _rockTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) _rock.value = 0;
      });
    } else {
      unawaited(_rock.forward(from: 0));
    }
    switch (r) {
      case M6UnjamRock.jammed:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/dull_steel.ogg', volume: 0.75);
      case M6UnjamRock.easing:
        HapticFeedback.lightImpact();
        _cue('sounds/learn/dull_steel.ogg', volume: 0.45);
      case M6UnjamRock.freed:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/ring_steel.ogg', volume: 0.7);
        final g = _geoNow;
        unawaited(_levelDelta(5, g == null ? Offset.zero : _sceneToGlobal(g.leverGrip), mood: GuideMood.glad));
      case M6UnjamRock.together:
        HapticFeedback.selectionClick();
        _cue('sounds/learn/ring_steel.ogg', volume: 0.45);
      case M6UnjamRock.none:
        break;
    }
    _stepDone();
  }

  /// A rough global position of a design point (for the flying ◆ only).
  Offset _sceneToGlobal(Offset p) {
    final size = MediaQuery.sizeOf(context);
    final k = size.width / 360;
    return Offset(p.dx * k, p.dy * k);
  }

  void _oilAt(Offset p, M6UnjamGeo geo) {
    if (!_canPlay || _run.stage != M6UnjamStage.head) return;
    if (_held != M6UnjamTool.can) {
      _hints.missTap();
      return;
    }
    for (var i = 0; i < 4; i++) {
      if (geo.pivotHit(i).contains(p)) {
        HapticFeedback.lightImpact();
        _cue('sounds/intro/drop.ogg', volume: 0.6);
        _run.oil(i);
        _stepDone();
        return;
      }
    }
    _hints.missTap();
  }

  Future<void> _comeDown() async {
    final m = _run.comeDown();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _sceneToGlobal(const Offset(180, 300))));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/stomp.ogg', volume: 0.6);
    setState(() {
      _held = null;
      _looking = false;
      _phoneOpen = false;
      _wake++;
    });
    if (_run.descents == 1) {
      // The first clean descent: ◆ on the table, then the reason (it fits
      // what he did), then the line clear.
      putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
      final topic = m6UnjamMaintWhy(_run.deal, freed: _run.freed);
      unawaited(askReason(
        deal: () => dealChoices(M6AbUnjamLines.whyRight[topic]!, M6AbUnjamLines.myths, widget.rng),
        question: M6AbUnjamLines.whyQ[topic]!,
        stillValid: () => !_ended && _run.stage == M6UnjamStage.ground,
      ));
      return;
    }
    _lineClear();
  }

  void _lineClear() {
    _cutscene('clear', () {
      _run.lineClear();
      unawaited(_sayChain([_task]));
      _groundReady();
    });
  }

  void _climbUp() {
    if (!_run.canClimb) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    _run.climbUp();
    _hush();
    _cue('sounds/learn/stomp.ogg', volume: 0.5);
    setState(() {
      _phoneOpen = false;
      _looking = false;
      _wake++;
    });
    _cutscene('up', () => unawaited(_sayChain([_task])));
  }

  void _cutscene(String id, VoidCallback then) {
    _cutTimer?.cancel();
    setState(() {
      _cut = id;
      _wake++;
    });
    _cutTimer = Timer(Duration(milliseconds: _quiet ? 900 : 2400), () {
      if (!mounted || _ended) return;
      setState(() {
        _cut = null;
        _wake++;
      });
      then();
    });
  }

  /// On the ground after the line clear: the handle coworker when the work
  /// was good (his moment needs the AB still open and the jam free).
  void _groundReady() {
    if (coworkerDone || _run.push != null) return;
    if (m6UnjamPushFits(M6UnjamPush.breakerFirst, _run)) {
      _run.push = M6UnjamPush.breakerFirst;
      scheduleCoworker();
    }
  }

  // --- the ground ----------------------------------------------------------------
  void _tapGround(Offset p, M6UnjamGeo geo) {
    if (!_canPlay) return;
    if (geo.phoneHit.contains(p)) {
      if (holdForCoworker()) return;
      _tick('sounds/learn/dmm_beep.ogg', 0.5);
      setState(() {
        _phoneOpen = !_phoneOpen;
        _looking = false;
        _wake++;
      });
      return;
    }
    if (geo.knobHit(_handle).contains(p)) {
      // A drag control: a tap only tells the hand to show the swing.
      setState(() => _handleTouched = true);
    }
    _hints.missTap();
  }

  void _phoneAsk(Offset global) {
    if (!_canPlay || !_phoneOpen) return;
    if (holdForCoworker()) {
      setState(() => _phoneOpen = false);
      return;
    }
    _tick('sounds/learn/dmm_beep.ogg', 0.55);
    final m = _run.askBreaker();
    if (m != null) {
      setState(() {
        _phoneOpen = false;
        _hot = true;
        _wake++;
      });
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.restored) {
      unawaited(_restored());
      return;
    }
    setState(() {
      _phoneNote = M6AbUnjamLines.phoneOn;
      _wake++;
    });
    _stepDone();
  }

  void _phoneCancel(Offset global) {
    if (!_canPlay || !_phoneOpen) return;
    _tick('sounds/learn/dmm_beep.ogg', 0.55);
    final m = _run.cancelBreaker();
    if (m == null) return;
    setState(() {
      _phoneNote = M6AbUnjamLines.phoneIdle;
      _phoneOpen = false;
      _wake++;
    });
    unawaited(_mistake(m, global));
  }

  Future<void> _restored() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.7);
    setState(() {
      _phoneOpen = false;
      _phoneNote = M6AbUnjamLines.phoneOn;
      _lit = 1;
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 1200));
    if (!mounted || _ended) return;
    putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
    final topic = m6UnjamFinalWhy(_run.deal, refusedPartSeat: _run.refusedPartSeat);
    unawaited(askReason(
      deal: () => dealChoices(M6AbUnjamLines.whyRight[topic]!, M6AbUnjamLines.myths, widget.rng),
      question: M6AbUnjamLines.whyQ[topic]!,
      stillValid: () => !_ended,
    ));
  }

  void _strokeStart() {
    if (holdForCoworker()) {
      _pan = _Pan.none;
      return;
    }
    _pan = _Pan.stroke;
    setState(() {
      _stroking = true;
      _phoneOpen = false;
      _looking = false;
      _handleTouched = true;
      _wake++;
    });
  }

  /// The knob follows the finger round the pivot; at the far end the stroke
  /// is done. Still for 650 ms mid-arc: a stall.
  void _strokeMove(Offset p, M6UnjamGeo geo) {
    final was = _handle;
    final now = geo.progressAt(p);
    if ((now - was).abs() > 0.01) {
      setState(() => _handle = now);
      _stallTimer?.cancel();
      if (_midArc) _stallTimer = Timer(const Duration(milliseconds: 650), _stall);
    }
    final closing = !_run.abClosed;
    if ((closing && now >= 0.92) || (!closing && now <= 0.08)) _strokeDone();
  }

  bool get _midArc {
    final p = _run.abClosed ? 1 - _handle : _handle;
    return p > 0.08 && p < 0.92;
  }

  void _strokeEnd() {
    if (!_stroking) return;
    if (_midArc) {
      _stall();
      return;
    }
    _stallTimer?.cancel();
    setState(() {
      _stroking = false;
      _handle = _run.abClosed ? 1 : 0;
    });
    _hints.missTap();
  }

  void _stall() {
    _stallTimer?.cancel();
    if (!_stroking || !mounted) return;
    _pan = _Pan.none;
    // With the breaker ON this is no stall: the blades already went toward
    // live jaws (deadly, the flash at the AB).
    final m = _run.stroke(stalled: true);
    final g = _geoNow;
    if (m != null && m.deadly && g != null) _flashAt = g.abCentre;
    setState(() {
      _stroking = false;
      _handle = _run.abClosed ? 1 : 0;
      _wake++;
    });
    if (m != null) unawaited(_mistake(m, _sceneToGlobal(m.deadly ? _flashAt : (g?.handlePivot ?? Offset.zero))));
  }

  void _strokeDone() {
    _stallTimer?.cancel();
    _pan = _Pan.none;
    final m = _run.stroke();
    if (m != null) {
      final g = _geoNow;
      if (g != null) _flashAt = g.abCentre;
      setState(() {
        _stroking = false;
        _handle = 1;
      });
      unawaited(_mistake(m, _sceneToGlobal(_flashAt)));
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    setState(() {
      _stroking = false;
      _handle = _run.abClosed ? 1 : 0;
    });
    // A phase part way: the phone coworker (if none came yet).
    if (!coworkerDone && _run.push == null && m6UnjamPushFits(M6UnjamPush.loose, _run)) {
      _run.push = M6UnjamPush.loose;
      scheduleCoworker();
    }
    _stepDone();
  }

  void _look() {
    _tick('sounds/intro/click.ogg', 0.5);
    _run.look();
    setState(() {
      _looking = true;
      _phoneOpen = false;
    });
    _stepDone();
  }

  // --- the scene's pans ----------------------------------------------------------
  /// A still press that the long press won: the oil (the can in hand, on an
  /// oil point), else the pan it was going to be.
  void _holdStart(Offset p, M6UnjamGeo geo) {
    if (_canPlay && _run.stage == M6UnjamStage.head && _held == M6UnjamTool.can) {
      for (var i = 0; i < 4; i++) {
        if (geo.pivotHit(i).contains(p)) {
          _pan = _Pan.none;
          _oilAt(p, geo);
          return;
        }
      }
    }
    _panStart(p, geo);
  }

  void _panStart(Offset p, M6UnjamGeo geo) {
    _pan = _Pan.none;
    if (!_canPlay) return;
    _panFrom = p;
    _panNow = p;
    if (_run.stage == M6UnjamStage.ground) {
      if (geo.knobHit(_handle).contains(p)) {
        _strokeStart();
        return;
      }
      _pan = _Pan.swipe;
      return;
    }
    if (geo.leverHit.inflate(6).contains(p)) {
      _pan = _Pan.lever;
      return;
    }
    if (_held == M6UnjamTool.cloth) {
      for (var i = 0; i < 3; i++) {
        if (geo.jawHit(i).contains(p) || geo.insHit(i).contains(p)) {
          _pan = _Pan.rub;
          _rubKind = geo.jawHit(i).contains(p) ? M6UnjamRub.jaw : M6UnjamRub.insulator;
          _rubAt = i;
          return;
        }
      }
    }
    _pan = _Pan.swipe;
  }

  void _panUpdate(Offset p, M6UnjamGeo geo) {
    final last = _panNow;
    _panNow = p;
    switch (_pan) {
      case _Pan.stroke:
        if (_stroking) _strokeMove(p, geo);
      case _Pan.rub:
        if (!_canPlay) return;
        final area = (_rubKind == M6UnjamRub.jaw ? geo.jawHit(_rubAt) : geo.insHit(_rubAt)).inflate(8);
        if (!area.contains(p)) return;
        final list = _rubKind == M6UnjamRub.jaw ? _run.jawDirt : _run.insDirt;
        final before = list[_rubAt];
        final cleared = _run.rub(_rubKind, _rubAt, (p - last).distance);
        if (cleared) {
          HapticFeedback.lightImpact();
          _cue('sounds/intro/glass.ogg', volume: 0.45);
          _steps++;
        }
        if (list[_rubAt] != before) setState(() => _wake++);
      case _Pan.lever:
      case _Pan.swipe:
      case _Pan.none:
        break;
    }
  }

  void _panEnd() {
    final kind = _pan;
    _pan = _Pan.none;
    final d = _panNow - _panFrom;
    switch (kind) {
      case _Pan.stroke:
        _strokeEnd();
      case _Pan.lever:
        if (!_canPlay) return;
        if (d.dx.abs() >= 30) {
          _rockOnce();
        } else {
          _hints.missTap();
        }
      case _Pan.rub:
        if (_canPlay) _stepDone();
      case _Pan.swipe:
        if (!_canPlay) return;
        if (_run.stage == M6UnjamStage.ground && -d.dy >= 50) {
          _look();
        } else {
          _hints.missTap();
        }
      case _Pan.none:
        break;
    }
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
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
    _run.tablePaid();
    if (_run.restored) {
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended) unawaited(_finish());
      }));
      return;
    }
    _lineClear();
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6AbUnjamLines.coworker(_run.push ?? M6UnjamPush.breakerFirst);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final p = _run.push;
    if (_ended || _run.ended || p == null || !m6UnjamPushFits(p, _run)) return null;
    if (_intro || _card != null || tableBusy || _freeze || _cut != null || _stroking) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() {
    _hush();
    if (_phoneOpen && mounted) setState(() => _phoneOpen = false);
  }

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.push ?? M6UnjamPush.breakerFirst;
    if (!held) {
      final m = _run.listen(p);
      if (m.deadly) {
        final g = _geoNow;
        if (g != null) _flashAt = g.abCentre;
        await _deadly(m);
        return;
      }
      setState(() => _hot = true);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6AbUnjamLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6AbUnjamLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6AbUnjamLines.tapWhy[_nudgeN++ % M6AbUnjamLines.tapWhy.length]
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
    _stallTimer?.cancel();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6abunjam/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// An AB closed on load: the scene freezes grey and the arc comes off it in
  /// colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _stallTimer?.cancel();
    _cutTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _held = null;
      _phoneOpen = false;
      _stroking = false;
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
    final speak = await SpokenOnce.first('m6abunjam/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6AbUnjamLines.deadlyWord : M6AbUnjamLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The play goes on from where it was; a part-seated ask was put off
        // again by the substation.
        _hush();
        setState(() {
          if (_hot) _phoneNote = M6AbUnjamLines.phoneOffAgain;
          _hot = false;
          _card = null;
          _wake++;
        });
        unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? M6AbUnjamLines.fail : (_quickBonus ? M6AbUnjamLines.quick : M6AbUnjamLines.allSet),
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
    if (_held != null || _stroking) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6UnjamHeadRig get _headRig => M6UnjamHeadRig(
        type: _run.deal.type,
        jam: _run.deal.jam,
        stuck: _run.deal.stuck,
        lag: _run.lag,
        jawDirt: [..._run.jawDirt],
        insDirt: [..._run.insDirt],
        oiled: {..._run.oiled},
        earths: _run.earths,
      );

  M6UnjamGroundRig _groundRig(double lit) => M6UnjamGroundRig(
        type: _run.deal.type,
        handle: _handle,
        closed: _run.abClosed,
        stuck: _run.deal.stuck,
        seated: _run.freed,
        earths: _run.earths,
        lit: lit,
        hot: _hot,
      );

  /// The gesture hand: how to touch, never what. On the head: a left-right
  /// swipe on the lever and a sweep over the pouch; the can in hand, a sweep
  /// over every oil point alike and a hold on each in turn
  /// ([m6UnjamCanHint]); the cloth in hand,
  /// a back-and-forth on the cloth itself and a sweep over every jaw and
  /// insulator alike. On the ground: a sweep over the handle and the phone
  /// (and the lanyard when it is out), a swipe up the structure, and once the
  /// handle was touched, the swing along its arc. The phone panel open: a
  /// sweep over its request button and its close button together.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (_phoneOpen) return HintSpec.sweepOver([_phoneButtonKey, _phoneCloseKey]);
    if (_run.stage == M6UnjamStage.head) {
      switch (_held) {
        case M6UnjamTool.can:
          return m6UnjamCanHint(geo, n);
        case M6UnjamTool.cloth:
          if (n.isEven) {
            final r = HintSpec.globalRectOf(_toolKeys[M6UnjamTool.cloth]!);
            if (r != null) return HintSpec.swipe(r.center.translate(-16, 0), toward: const Offset(1, 0), travel: 32);
          }
          return HintSpec.sweep([for (var i = 0; i < 3; i++) ...[geo.jawHit(i), geo.insHit(i)]], space: HintSpace.scene);
        case M6UnjamTool.lanyard:
        case null:
          if (n.isEven) return HintSpec.swipe(geo.leverGrip.translate(-22, 0), toward: const Offset(1, 0), travel: 44, space: HintSpace.scene);
          return HintSpec.sweepOver([for (final t in _run.deal.pouch) _toolKeys[t]!]);
      }
    }
    final ways = <HintSpec? Function()>[
      () => HintSpec.sweepOver([_handleKey, _phoneKey, if (_run.canClimb) _toolKeys[M6UnjamTool.lanyard]!]),
      () => HintSpec.swipe(geo.swipeFrom, toward: const Offset(0, -1), travel: 80, space: HintSpace.scene),
      if (_handleTouched) () => HintSpec.drag(geo.knob(_handle), toward: Offset(0, _run.abClosed ? 1 : -1), travel: 50, space: HintSpace.scene),
    ];
    return ways[n % ways.length]();
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6UnjamGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final head = _run.stage == M6UnjamStage.head;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              if (head)
                Positioned.fill(
                  key: const ValueKey('head'),
                  child: RepaintBoundary(child: CustomPaint(painter: M6UnjamHeadPainter(geo: geo, rig: _headRig, rock: _rock))),
                )
              else
                Positioned.fill(
                  key: const ValueKey('ground'),
                  child: RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: _lit, end: _lit),
                      duration: Duration(milliseconds: quiet ? 1 : 900),
                      builder: (_, v, _) => CustomPaint(painter: M6UnjamGroundPainter(geo: geo, rig: _groundRig(v))),
                    ),
                  ),
                ),
              Positioned.fromRect(
                key: ValueKey('trainee-${_run.stage.name}'),
                rect: head ? geo.traineeUp : geo.traineeDown,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // Where the hand's ground sweep passes (the handle's arc, the phone).
      if (!head) ...[
        Positioned.fromRect(key: const ValueKey('hint-handle'), rect: geo.handleArea, child: IgnorePointer(child: SizedBox.expand(key: _handleKey))),
        Positioned.fromRect(key: const ValueKey('hint-phone'), rect: geo.phoneHit, child: IgnorePointer(child: SizedBox.expand(key: _phoneKey))),
      ],
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: head ? M6AbUnjamLines.sceneHead : M6AbUnjamLines.sceneGround,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A pan is judged by where the finger went down (the lever, a
            // rub place, the knob), not where it passed the slop.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => head ? _hints.missTap() : _tapGround(d.localPosition, geo),
            // A finger that rests ~0.5 s before it moves goes to the long
            // press, not the pan: with the can on an oil point that is the
            // oil; anything else carries on as the same pan (hold the knob,
            // then swing; press the lever or a rub place, then move).
            onLongPressStart: (d) => _holdStart(d.localPosition, geo),
            onLongPressMoveUpdate: (d) => _panUpdate(d.localPosition, geo),
            onLongPressEnd: (_) => _panEnd(),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      // The tilt-up view of the three blades.
      if (!head && _looking && !_freeze)
        Positioned.fromRect(
          key: ValueKey('phases-${_run.strokes}-$_hot'),
          rect: M6UnjamGeo.phaseCard,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 360),
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: CustomPaint(painter: M6UnjamPhasePainter(closed: _run.abClosed, seated: _run.freed, stuck: _run.deal.stuck, hot: _hot)),
            ),
          ),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6UnjamFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // A place change: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('place-${_run.stage.name}-${_run.descents}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || (_run.descents == 0 && head) ? 0 : 0.7, end: 0),
              duration: const Duration(milliseconds: 560),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
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
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && _cut == null && !_run.ended;
    final head = _run.stage == M6UnjamStage.head;
    final pouch = head ? _run.deal.pouch : [if (_run.canClimb) M6UnjamTool.lanyard];
    final toolW = math.min(96.0, (size.width - 8) / 3);
    final docket = _run.earths ? M6AbUnjamLines.docketShutdown : (_run.restored ? M6AbUnjamLines.docketLive : M6AbUnjamLines.docketClear);
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
              labels: M6AbUnjamLines.stages,
              done: {if (_run.descents > 0) 0, if (_run.restored) 1},
              current: _run.restored ? null : (head ? 0 : 1),
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_stroking,
            hintKey: '${_run.stage.name}/$_steps/${_held?.name}/$_handleTouched/${_run.canClimb}/$_phoneOpen/${_run.breakerOn}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing)
                Positioned(
                  key: const ValueKey('docket'),
                  top: pad.top + 92,
                  left: 10,
                  child: IgnorePointer(child: _DocketChip(text: docket, shutdown: _run.earths)),
                ),
              if (handsOn && pouch.isNotEmpty)
                Positioned(
                  key: ValueKey('hud-pouch-${_run.stage.name}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in pouch)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M6AbUnjamLines.tool(t),
                          width: toolW,
                          on: _held == t,
                          onTap: () => _tapTool(t),
                          onHold: t == M6UnjamTool.lanyard ? _holdLanyard : null,
                        ),
                    ],
                  ),
                ),
              if (handsOn && _phoneOpen)
                Positioned(
                  key: const ValueKey('phone-panel'),
                  left: 16,
                  right: 16,
                  top: pad.top + 122,
                  child: _PhonePanel(
                    buttonKey: _phoneButtonKey,
                    closeKey: _phoneCloseKey,
                    note: _run.breakerOn ? M6AbUnjamLines.phoneOn : _phoneNote,
                    asked: _run.breakerOn,
                    onAsk: _phoneAsk,
                    onCancel: _phoneCancel,
                    onClose: () => setState(() => _phoneOpen = false),
                  ),
                ),
              if (_cut != null)
                Positioned.fill(
                  key: ValueKey('cut-$_cut'),
                  child: _Cutscene(text: _cut == 'clear' ? M6AbUnjamLines.cutClear : M6AbUnjamLines.cutUp, earthsOn: _cut == 'up', quiet: quiet),
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
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M6AbUnjamLines.intro,
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

  static const _icons = {
    M6UnjamTool.cloth: Icons.cleaning_services_rounded,
    M6UnjamTool.can: Icons.water_drop_rounded,
    M6UnjamTool.lanyard: Icons.link_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// The docket on the job (a worker reads it).
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text, required this.shutdown});
  final String text;
  final bool shutdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6F7F1DE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: shutdown ? const Color(0xFFB03A2E) : const Color(0xFF2E7D4F), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(shutdown ? Icons.lock_rounded : Icons.check_circle_rounded, size: 13, color: shutdown ? const Color(0xFFB03A2E) : const Color(0xFF2E7D4F)),
          const SizedBox(width: 5),
          Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
        ],
      ),
    );
  }
}

/// The crew's staged step (the line clear, or the re-isolation).
class _Cutscene extends StatelessWidget {
  const _Cutscene({required this.text, required this.earthsOn, required this.quiet});
  final String text;
  final bool earthsOn;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xF20B1324),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SlmColors.gold300, width: 1.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(earthsOn ? Icons.lock_rounded : Icons.assignment_turned_in_rounded, size: 26, color: SlmColors.gold300),
                // The re-isolation: the crew's tester proves it dead first.
                if (earthsOn) ...[
                  const SizedBox(width: 6),
                  const SizedBox(key: ValueKey('cut-tester'), width: 26, height: 30, child: CustomPaint(painter: M6UnjamTesterPainter())),
                ],
                const SizedBox(width: 10),
                Flexible(child: Text(text, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The phone to the substation: the state, one request button, close.
class _PhonePanel extends StatelessWidget {
  const _PhonePanel({
    required this.buttonKey,
    required this.closeKey,
    required this.note,
    required this.asked,
    required this.onAsk,
    required this.onCancel,
    required this.onClose,
  });

  /// Where the gesture hand's sweep passes (the request button, ✕).
  final GlobalKey buttonKey;
  final GlobalKey closeKey;
  final String note;
  final bool asked;
  final ValueChanged<Offset> onAsk;
  final ValueChanged<Offset> onCancel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final label = asked ? M6AbUnjamLines.phoneCancel : M6AbUnjamLines.phoneAsk;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xF2101A2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, size: 18, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Expanded(child: Text(M6AbUnjamLines.phoneTitle, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: SlmColors.gold300))),
              Semantics(
                button: true,
                label: M6AbUnjamLines.phoneClose,
                excludeSemantics: true,
                child: KeyedSubtree(
                  key: closeKey,
                  child: InkWell(
                    key: const ValueKey('phone-close'),
                    onTap: onClose,
                    child: const SizedBox(width: 44, height: 36, child: Icon(Icons.close_rounded, color: SlmColors.ivory)),
                  ),
                ),
              ),
            ],
          ),
          Text(note, key: const ValueKey('phone-note'), style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: SlmColors.ivory)),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: KeyedSubtree(
              key: buttonKey,
              child: GestureDetector(
                key: ValueKey(asked ? 'phone-cancel' : 'phone-ask'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => asked ? onCancel(d.globalPosition) : onAsk(d.globalPosition),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2E4A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SlmColors.gold300, width: 1.4),
                  ),
                  child: Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pouch item: a round icon with its name under it; lit while in hand.
/// [onHold]: a hold control (the lanyard) — a plain tap does nothing.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.onHold, this.width = 80});
  final IconData icon;
  final String label;
  final double width;
  final bool on;
  final VoidCallback onTap;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onHold,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, softWrap: false, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
