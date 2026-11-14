import 'dart:async';
import 'dart:math' as math;

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
import 'm3_horngap_set_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_horngap_set_world.dart' show M3HorngapSetGeo, M3HorngapSetPart, M3HorngapSetWire;

// Lesson 3.4 "ডিও (DO) ফিউজ ও হর্ন গ্যাপ ফিউজ: নীরব প্রহরী", কাজ 2 "হর্ন গ্যাপ
// ঠিক করো" (pack do_3_4_b, engineType m3_horngap_set). On patrol a horn gap
// fuse at a village transformer is found blown (lesson point 1's daily check:
// an open fuse = a fault on the line). Four stations a play:
//   ক safe — before a hand goes on the sets: শাটডাউন → PTW → টেস্ট → আর্থ, in
//     that order (the module's safety rule; tokens dealt in a fresh order),
//     then climb (helmet and harness, drawn);
//   খ inspect — up the pole, the three sets R Y B: the melted fuse wire, and
//     one or two more faults dealt from: a thick wire tied in place of a fuse
//     wire (myth 1), a horn bent in so the gap no longer widens upward (point
//     3: the arc rises and goes out as the horns' distance grows), carbon on a
//     terminal (pro tip 3: dirt or carbon → sparking);
//   গ fix — clean the terminal, set the horn back, and tie new fuse wire:
//     the plate's rating (point 4's pro tip: the plate says how many amps),
//     never a thicker or thinner rating or plain wire (point 4, myth 2), tied
//     at the right tension (pro tip 4: a loose tie does not work right);
//   ঘ charge — the line comes back on: the fuse holds (village lights) or it
//     blows again (the flash, the bang, the arc climbing the horns and going
//     out — point 3, the film's "ওড়ার সময়"). Blowing again = a fault on the
//     line: keep it off and find the fault (myth 1), never a thick wire.
//
// Deadly: a hand on the sets while the line is live — climbing before the
// shutdown (also by listening to the coworker, "লাইন চালু থাকতেই ফিউজটা বদলে
// দাও"), or climbing to tie again once the line is back on. Slips: a step out
// of order, climbing before test and earth, a fault missed, a sound part
// flagged as faulty, the wrong wire, a loose tie, a thick wire after it blows,
// walking away from a fuse that blew again, stopping the line although the
// fuse held. Three slips strike out. Listening to the coworker stays deadly:
// the act he pushes (a hand on the live sets) is the ladder's deadly climb-live.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_horngap_set_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next station by itself. The coworker once a play: in ক before the
// shutdown, or (when the fuse blows again) in ঘ; the decisive control (the
// শাটডাউন token / climb in ক, any act in ঘ) waits for him (holdForCoworker).
// Gesture hints: a sweep over the controls of each waiting state. Voice: the
// guide by device TTS; the coworker's push is silent with its caption held
// until recorded (his exit line is recorded).
//
// Flagged to the owner (REGISTER.md): the lesson gives no gap size and no
// setting procedure for the horns — "a bent horn" is inferred from point 3's
// mechanism and no measurement is asked; carbon on a horn terminal applies
// pro tip 3 (written for DO contacts); the safety order and the restore
// (earth off, PTW back) are the module's rules, not lesson 3.4's text.

// ============================================================================
// Content
// ============================================================================

/// The safety steps before a hand goes on the sets, in their order.
enum M3HorngapSetStep { shutdown, ptw, test, earth }

/// What can be wrong on a set.
enum M3HorngapSetFault { blown, thick, bent, carbon }

/// The reels in the bag.
enum M3HorngapSetReel { rated, other, plain }

/// What to do once the line is back on.
enum M3HorngapSetAct { ok, stopFind, thickWire, climbNow }

M3HorngapSetPart m3HorngapSetPartOf(M3HorngapSetFault f) => switch (f) {
      M3HorngapSetFault.blown || M3HorngapSetFault.thick => M3HorngapSetPart.wire,
      M3HorngapSetFault.bent => M3HorngapSetPart.horns,
      M3HorngapSetFault.carbon => M3HorngapSetPart.terminal,
    };

/// A fault on set [phase] (0 R, 1 Y, 2 B).
@immutable
class M3HorngapSetFaultAt {
  const M3HorngapSetFaultAt(this.phase, this.fault);
  final int phase;
  final M3HorngapSetFault fault;

  M3HorngapSetPart get part => m3HorngapSetPartOf(fault);

  @override
  bool operator ==(Object other) => other is M3HorngapSetFaultAt && other.phase == phase && other.fault == fault;

  @override
  int get hashCode => Object.hash(phase, fault);

  @override
  String toString() => '${fault.name}@$phase';
}

abstract final class M3HorngapSetLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askSafe, askSpot, askFix, askReel, askTie, askDecide];

  static const title = 'হর্ন গ্যাপ ঠিক করো';
  static const intro = 'গ্রামের ট্রান্সফরমারে হর্ন গ্যাপ ফিউজ উড়েছে! নিরাপদে ঠিক করুন।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];

  static const askSafe = 'ফিউজে হাত দেওয়ার আগে লাইন নিরাপদ করুন — ঠিক ক্রমে।';
  static const askSpot = 'তিনটে ফিউজ ভালো করে দেখুন — কোথায় কী গোলমাল?';
  static const askFix = 'গোলমালগুলো একে একে ঠিক করুন।';
  static const askReel = 'কোন তারটা বাঁধবেন?';
  static const askTie = 'তারটা সঠিক টানে বাঁধুন।';
  static const askWatch = 'কাজ শেষ, লাইন চালু হচ্ছে — নজর রাখুন।';
  static const askDecide = 'এবার কী করবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// The fuse blew again: the lesson's picture of it.
  static const blewAgain = 'আবার উড়ল! আর্ক শিং বেয়ে উঠে নিজেই নিভে গেল।';
  static const held = 'ফিউজ টিকে আছে, গ্রামে আলো জ্বলেছে।';

  // Labels a worker reads.
  static const sceneLabel = 'হর্ন গ্যাপ ফিউজ';
  static const stepShutdown = 'শাটডাউন';
  static const stepPtw = 'PTW';
  static const stepTest = 'টেস্ট';
  static const stepEarth = 'আর্থ';
  static String step(M3HorngapSetStep s) => switch (s) {
        M3HorngapSetStep.shutdown => stepShutdown,
        M3HorngapSetStep.ptw => stepPtw,
        M3HorngapSetStep.test => stepTest,
        M3HorngapSetStep.earth => stepEarth,
      };
  static const climb = 'উঠে কাজ শুরু';
  static const spotDone = 'দেখা শেষ';
  static String fuseWire(int amps) => enDigits('ফিউজ তার ${amps}A');
  static const plainWire = 'সাধারণ জিআই তার';
  static const pull = 'টান দিন';
  static const tieDone = 'বাঁধা শেষ';
  static String plate(int amps) => enDigits('ফিউজ\n${amps}A');
  static const actOk = 'ঠিক আছে — ডকেটে লিখি';
  static const actStop = 'বন্ধ রেখে ফল্ট খুঁজি';
  static const actThick = 'মোটা তার বেঁধে দিই';
  static const actClimb = 'এখনই উঠে আবার বাঁধি';
  static String act(M3HorngapSetAct a) => switch (a) {
        M3HorngapSetAct.ok => actOk,
        M3HorngapSetAct.stopFind => actStop,
        M3HorngapSetAct.thickWire => actThick,
        M3HorngapSetAct.climbNow => actClimb,
      };

  static const stampSafe = 'নিরাপদ — ওঠা যায়';
  static const stampSeen = 'সব ধরা পড়েছে';
  static const stampFixed = 'ফিউজ বাঁধা হলো';
  static const stampHeld = 'লাইন চালু';
  static const stampStop = 'ফল্ট খোঁজা শুরু';

  // The reasons: the right ones state this station's rule (as it happened);
  // the wrong ones are field excuses and myths.
  static const whySafe = 'কেন এই ক্রমে নিরাপদ করলেন?';
  static const whySpot = 'কেন এগুলো খারাপ ধরলেন?';
  static const whyFix = 'এই তার কেন, এভাবে কেন বাঁধলেন?';
  static const whyHeld = 'কেন লাইন চালু রাখলেন?';
  static const whyBlown = 'কেন লাইন বন্ধ রেখে ফল্ট খুঁজবেন?';

  static const safeWhy = [
    'শাটডাউন, PTW, টেস্ট, আর্থ — তবেই লাইনে হাত',
    'টেস্টে মরা প্রমাণ, তারপর আর্থ — তবেই কাজ',
    'চালু লাইনে হাত নয়, আগে চারটে ধাপ শেষ করা',
  ];
  static const safeMyths = [
    'ফিউজ তো উড়েই গেছে, লাইনে কারেন্ট নেই',
    'হর্ন গ্যাপ ছোট জিনিস, এত ধাপ লাগে না',
    'গ্লাভস পরা থাকলে চালু লাইনেও কাজ চলে',
    'সাথী বলেছে লাইন বন্ধ, তাই উঠে গেলাম',
    'তাড়া আছে, আর্থ না দিলেও কিছু হয় না',
    'আগে আর্থ দিলে টেস্টের দরকার পড়ে না',
  ];

  static const blownWhy = 'গলা তার মানে ফিউজ উড়েছে — ফল্টের সংকেত';
  static const thickWhy = 'ফিউজের জায়গায় মোটা তার সুরক্ষা নষ্ট করে';
  static const bentWhy = 'শিং বাঁকা হলে ফাঁক বাড়ে না, আর্ক নেভে না';
  static const carbonWhy = 'টার্মিনালে কার্বন জমলে স্পার্কিং হয়';
  static String faultWhy(M3HorngapSetFault f) => switch (f) {
        M3HorngapSetFault.blown => blownWhy,
        M3HorngapSetFault.thick => thickWhy,
        M3HorngapSetFault.bent => bentWhy,
        M3HorngapSetFault.carbon => carbonWhy,
      };
  static const spotMyths = [
    'দূর থেকে একবার দেখলেই সব বোঝা যায়',
    'মোটা তার থাকলে ফিউজ ওড়ে না, ওটাই ভালো',
    'শিং একটু বাঁকা হলে কিছুই যায় আসে না',
    'কার্বন জমা স্বাভাবিক, ওতে কোনো ক্ষতি নেই',
    'শুধু উড়ে যাওয়া তারটা দেখলেই যথেষ্ট',
  ];

  static const fixWhy = [
    'প্লেটে লেখা রেটিং-এর ফিউজ তার, সঠিক টানে',
    'ঢিলা বাঁধন ফিউজকে ঠিকমতো কাজ করতে দেয় না',
    'পরীক্ষিত ফিউজ তারই ঠিক সময়ে গলে যায়',
  ];
  static const fixMyths = [
    'মোটা তারে বারবার ওড়ে না, তাই ওটাই ভালো',
    'যেকোনো ধাতব তার দিয়েই ফিউজ বাঁধা যায়',
    'ঢিলে বাঁধলে পরে খুলতে অনেক সহজ হয়',
    'হাতের কাছে যে তার ছিল তাই বেঁধে দিলাম',
    'রেটিং দেখার দরকার নেই, তার তো তারই',
  ];

  static const heldWhy = [
    'চালুর পরেও ফিউজ টিকে আছে, লাইন ঠিক চলছে',
    'ফিউজ ওড়েনি, গ্রামে আলো — কাজটা ঠিক হয়েছে',
  ];
  static const blownWhyAgain = [
    'বারবার উড়ছে মানে লাইনে কোথাও ফল্ট আছে',
    'ফল্ট না খুঁজে আবার তার বাঁধলে বিপদ হবে',
  ];
  static const afterMyths = [
    'মোটা তার দিলেই আর উড়বে না, ঝামেলা শেষ',
    'আওয়াজ হয়েছে মানে ফিউজটাই খারাপ ছিল',
    'ফিউজ ওড়া স্বাভাবিক, আবার বাঁধলেই হবে',
    'চালু লাইনে চটপট বেঁধে দিলেই কাজ শেষ',
    'গ্রামের লোক রাগ করবে, তাই চালু রাখি',
  ];

  static List<String> whyRight(M3HorngapSetRun run) => switch (run.index) {
        0 => safeWhy,
        1 => [for (final f in run.deal.faults) faultWhy(f.fault)],
        2 => fixWhy,
        _ => run.deal.blowsAgain ? blownWhyAgain : heldWhy,
      };
  static List<String> whyWrong(M3HorngapSetRun run) => switch (run.index) {
        0 => safeMyths,
        1 => spotMyths,
        2 => fixMyths,
        _ => afterMyths,
      };
  static String why(M3HorngapSetRun run) => switch (run.index) {
        0 => whySafe,
        1 => whySpot,
        2 => whyFix,
        _ => run.deal.blowsAgain ? whyBlown : whyHeld,
      };

  /// The careless coworker: change it live, the shutdown takes too long.
  static const coworker = CoworkerScript(
    line: 'লাইন চালু থাকতেই ফিউজটা বদলে দাও! শাটডাউনে অনেক দেরি।',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, আগে শাটডাউন, PTW, টেস্ট আর আর্থ', 'চালু লাইনে হাত নয় — আগে শাটডাউন', 'না, মরা প্রমাণ আর আর্থ ছাড়া উঠব না'],
    wrong: ['ঠিক, চটপট বেঁধে দিলেই কাজ শেষ', 'আচ্ছা, গ্লাভস আছে, চালুতেই বাঁধি', 'হ্যাঁ, শাটডাউনে দেরি, এখনই উঠি', 'ঠিক আছে, ফিউজ তো উড়েই গেছে, ভয় নেই', 'তাড়া আছে, চালু লাইনেই সেরে ফেলি'],
    asks: ['ও বলছে চালু লাইনেই বাঁধতে। কী করবেন?', 'চালু লাইনে ফিউজ বদলাবেন?', 'এখনই উঠবেন, না আগে নিরাপদ করবেন?'],
  );

  static const callHeld = 'ঠিক! চালু লাইনে হাত নয় — আগে নিরাপদ।';
  static const allSet = 'হর্ন গ্যাপ ঠিক হলো — নিরাপদে, নিয়ম মেনে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে নিরাপদ, তারপর দেখা, সঠিক তার, সঠিক টান।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtSafe = 'শাটডাউন · PTW · টেস্ট · আর্থ';
  static const caughtSeen = 'তিন ফিউজের সব গোলমাল ধরেছেন';
  static const caughtWire = 'প্লেটের রেটিং-এর তার, সঠিক টানে';
  static const caughtFault = 'আবার ওড়ায় ফল্ট খুঁজতে থেমেছেন';
  static const caughtHeld = 'চালুর পরে ফিউজ দেখে নিয়েছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M3HorngapSetMistakes {
  static const _dir = 'assets/game/art/m3_horngap_set';
  static const _k = '3.4/m3_horngap_set';

  static const liveClimb = DoMistake(
    key: '$_k/live-climb',
    textBn: 'লাইন চালু ছিল! শাটডাউন, PTW, টেস্ট আর আর্থ ছাড়া হর্ন গ্যাপে হাত দেওয়া মানেই মৃত্যু।',
    art: '$_dir/live_climb.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const liveRetie = DoMistake(
    key: '$_k/live-retie',
    textBn: 'লাইন এখন চালু! চালু হর্ন গ্যাপে হাত নয় — আবার শাটডাউন, PTW, টেস্ট আর আর্থ, তারপর।',
    art: '$_dir/live_retie.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const wrongOrder = DoMistake(
    key: '$_k/wrong-order',
    textBn: 'ধাপ উল্টো হলো। আগে শাটডাউন, তারপর PTW, তারপর টেস্ট, শেষে আর্থ।',
    art: '$_dir/wrong_order.svg',
  );
  static const notReady = DoMistake(
    key: '$_k/not-ready',
    textBn: 'চারটে ধাপ শেষ হয়নি। টেস্টে মরা প্রমাণ আর আর্থ ছাড়া ফিউজে হাত নয়।',
    art: '$_dir/not_ready.svg',
  );
  static const missedFault = DoMistake(
    key: '$_k/missed-fault',
    textBn: 'একটা গোলমাল চোখ এড়িয়ে গেল। তিনটে ফিউজেরই তার, শিং আর টার্মিনাল দেখুন।',
    art: '$_dir/missed_fault.svg',
    lessonPoint: 2,
  );
  static const thickWire = DoMistake(
    key: '$_k/thick-wire',
    textBn: 'প্লেটের চেয়ে বেশি রেটিং-এর তার! ওভারলোডে ফিউজ উড়বে না, ট্রান্সফরমার পুড়বে।',
    art: '$_dir/thick_wire.svg',
    lessonPoint: 3,
  );
  static const thinWire = DoMistake(
    key: '$_k/thin-wire',
    textBn: 'প্লেটের চেয়ে কম রেটিং-এর তার — স্বাভাবিক লোডেই বারবার উড়ে যাবে।',
    art: '$_dir/thin_wire.svg',
    lessonPoint: 3,
  );
  static const plainWire = DoMistake(
    key: '$_k/plain-wire',
    textBn: 'সাধারণ তার ফিউজ নয় — কখন গলবে তার ঠিক নেই। প্লেটের রেটিং-এর ফিউজ তার চাই।',
    art: '$_dir/plain_wire.svg',
    lessonPoint: 3,
  );

  /// Pro tip 4 (not a lesson point: "পাঠে দেখুন" opens the lesson start).
  static const loose = DoMistake(
    key: '$_k/loose-tie',
    textBn: 'তার ঢিলা রয়ে গেল। ঢিলা বা ভুলভাবে বাঁধা ফিউজ ঠিকমতো কাজ করে না — সঠিক টানে বাঁধুন।',
    art: '$_dir/loose_tie.svg',
  );
  static const thickMyth = DoMistake(
    key: '$_k/thick-myth',
    textBn: 'মোটা তার সুরক্ষাই নষ্ট করে — ওভারলোডে ফিউজ উড়বে না, ট্রান্সফরমার পুড়বে।',
    art: '$_dir/thick_myth.svg',
    lessonPoint: 3,
  );
  /// A sound part flagged in খ (a guess costs; the card comes after the call).
  static const falseFlag = DoMistake(
    key: '$_k/false-flag',
    textBn: 'ওখানে গোলমাল ছিল না। আন্দাজে নয় — তার, শিং আর টার্মিনাল ভালো করে দেখে তবেই গোলমাল ধরুন।',
    art: '$_dir/false_flag.svg',
    lessonPoint: 2,
  );
  /// The line stopped although the fuse held (a needless stop costs too).
  static const needlessStop = DoMistake(
    key: '$_k/needless-stop',
    textBn: 'ফিউজ টিকে আছে, গ্রামে আলো জ্বলেছে — লাইনে ফল্টের সংকেত নেই। ফিউজটা দেখে নিয়ে ডকেটে লিখুন।',
    art: '$_dir/needless_stop.svg',
    lessonPoint: 0,
  );
  static const ignoredBlow = DoMistake(
    key: '$_k/ignored-blow',
    textBn: 'ফিউজ আবার উড়ল, অথচ চলে যাচ্ছেন! বারবার ওড়া মানে লাইনে ফল্ট — বন্ধ রেখে খুঁজতে হবে।',
    art: '$_dir/ignored_blow.svg',
    lessonPoint: 0,
  );

  static const all = [liveClimb, liveRetie, wrongOrder, notReady, missedFault, falseFlag, thickWire, thinWire, plainWire, loose, thickMyth, needlessStop, ignoredBlow];
}

@immutable
class M3HorngapSetDeal {
  const M3HorngapSetDeal({
    required this.faults,
    required this.plateAmps,
    required this.tokens,
    required this.reels,
    required this.blowsAgain,
    required this.callAt,
    this.carbonRight = false,
    this.acts = M3HorngapSetAct.values,
  });

  /// Every fault on the sets; the first is the blown wire.
  final List<M3HorngapSetFaultAt> faults;
  final int plateAmps;

  /// The safety steps as the tokens lie (shuffled).
  final List<M3HorngapSetStep> tokens;

  /// The reels as they lie in the bag (shuffled).
  final List<M3HorngapSetReel> reels;

  /// After the work the fuse blows again (a fault further on the line).
  final bool blowsAgain;

  /// The station the careless coworker comes on (0 before the shutdown, or 3).
  final int callAt;
  final bool carbonRight;

  /// The four acts in ঘ as they lie on screen (shuffled: no fixed spot for
  /// the right one).
  final List<M3HorngapSetAct> acts;

  int get blownPhase => faults.first.phase;

  /// The bag's other fuse wire: the lesson's two example ratings.
  int get otherAmps => plateAmps == 10 ? 25 : 10;

  M3HorngapSetFaultAt? at(int phase, M3HorngapSetPart part) {
    for (final f in faults) {
      if (f.phase == phase && f.part == part) return f;
    }
    return null;
  }
}

/// A fresh play: the blown phase, one or two more faults, the plate, the
/// tokens and the reels in a fresh order, holds or blows again, his moment.
M3HorngapSetDeal m3HorngapSetDeal(math.Random rng) {
  final blown = rng.nextInt(3);
  final extras = [M3HorngapSetFault.thick, M3HorngapSetFault.bent, M3HorngapSetFault.carbon]..shuffle(rng);
  final n = rng.nextInt(3) == 0 ? 2 : 1;
  final faults = <M3HorngapSetFaultAt>[M3HorngapSetFaultAt(blown, M3HorngapSetFault.blown)];
  for (final f in extras.take(n)) {
    final phase = f == M3HorngapSetFault.thick ? ([0, 1, 2]..remove(blown))[rng.nextInt(2)] : rng.nextInt(3);
    faults.add(M3HorngapSetFaultAt(phase, f));
  }
  final again = rng.nextBool();
  return M3HorngapSetDeal(
    faults: faults,
    plateAmps: rng.nextBool() ? 10 : 25,
    tokens: [...M3HorngapSetStep.values]..shuffle(rng),
    reels: [...M3HorngapSetReel.values]..shuffle(rng),
    blowsAgain: again,
    callAt: again && rng.nextBool() ? 3 : 0,
    carbonRight: rng.nextBool(),
    acts: [...M3HorngapSetAct.values]..shuffle(rng),
  );
}

/// What a tap on a part did in the fix station.
enum M3HorngapSetFix { none, cleaned, set, reel }

/// The play state (pure logic).
class M3HorngapSetRun {
  M3HorngapSetRun(this.deal);

  final M3HorngapSetDeal deal;
  int index = 0;

  // ক
  final List<M3HorngapSetStep> steps = [];
  // খ
  final Set<M3HorngapSetFaultAt> found = {};
  int falseTaps = 0;

  /// Sound parts already flagged once (booked; a second tap does nothing).
  final Set<(int, M3HorngapSetPart)> cleared = {};
  // গ
  final Set<M3HorngapSetFaultAt> fixed = {};

  /// The set whose wire is being replaced: the reels are out.
  int? reelFor;

  /// The set the new wire is being tied on, and how far it still sags.
  int? tying;
  int slack = 0;
  final Set<int> _looseBooked = {};
  // ঘ
  var revealed = false;
  M3HorngapSetAct? acted;

  var shown = false;
  int slips = 0;
  int _stationSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  static const stations = 4;
  bool get done => index >= stations;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  /// The +5: the station went clean (no slip; in খ no false tap either).
  bool get thorough => _stationSlips == 0 && (index != 1 || falseTaps == 0);

  /// On the ground (ক, ঘ) or up the pole (খ, গ).
  bool get up => index == 1 || index == 2;
  bool get shutdown => steps.contains(M3HorngapSetStep.shutdown);
  bool get earthed => (index == 0 && steps.contains(M3HorngapSetStep.earth)) || up;
  bool get lit => index == 3 && revealed && !deal.blowsAgain;

  DoMistake _slip(DoMistake m) {
    slips++;
    _stationSlips++;
    return m;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  // --- ক: make it safe ----------------------------------------------------------
  M3HorngapSetStep? get nextStep => steps.length < M3HorngapSetStep.values.length ? M3HorngapSetStep.values[steps.length] : null;

  /// A token: the next step in order is done; another is a slip (not done).
  DoMistake? tapStep(M3HorngapSetStep s) {
    if (!_open || index != 0 || steps.contains(s)) return null;
    if (s != nextStep) return _slip(M3HorngapSetMistakes.wrongOrder);
    steps.add(s);
    return null;
  }

  /// Climb to the sets: live = deadly; not tested and earthed = slip.
  DoMistake? climb() {
    if (!_open || index != 0) return null;
    if (!shutdown) {
      shown = true;
      return deadly = M3HorngapSetMistakes.liveClimb;
    }
    if (nextStep != null) return _slip(M3HorngapSetMistakes.notReady);
    shown = true;
    _tag(M3HorngapSetLines.caughtSafe);
    return null;
  }

  // --- খ: inspect ---------------------------------------------------------------
  /// A tap on [part] of set [phase] flags it: a fault is found (added to
  /// [found], null); a sound part is a slip ([M3HorngapSetMistakes.falseFlag],
  /// booked once a part); a part already called does nothing (null).
  DoMistake? spot(int phase, M3HorngapSetPart part) {
    if (!_open || index != 1) return null;
    final f = deal.at(phase, part);
    if (f == null) {
      if (!cleared.add((phase, part))) return null;
      falseTaps++;
      return _slip(M3HorngapSetMistakes.falseFlag);
    }
    found.add(f);
    return null;
  }

  /// "Seen it all": a missed fault is a slip (and shown).
  DoMistake? spotDone() {
    if (!_open || index != 1) return null;
    final missed = deal.faults.where((f) => !found.contains(f)).toList();
    if (missed.isNotEmpty) {
      found.addAll(missed);
      return _slip(M3HorngapSetMistakes.missedFault);
    }
    shown = true;
    if (_stationSlips == 0) _tag(M3HorngapSetLines.caughtSeen);
    return null;
  }

  // --- গ: fix -------------------------------------------------------------------
  bool get _busyWire => reelFor != null || tying != null;

  /// A tap on a part with a fault not yet fixed.
  M3HorngapSetFix tapFix(int phase, M3HorngapSetPart part) {
    if (!_open || index != 2 || _busyWire) return M3HorngapSetFix.none;
    final f = deal.at(phase, part);
    if (f == null || fixed.contains(f)) return M3HorngapSetFix.none;
    switch (f.fault) {
      case M3HorngapSetFault.carbon:
        fixed.add(f);
        _checkFixed();
        return M3HorngapSetFix.cleaned;
      case M3HorngapSetFault.bent:
        fixed.add(f);
        _checkFixed();
        return M3HorngapSetFix.set;
      case M3HorngapSetFault.blown:
      case M3HorngapSetFault.thick:
        reelFor = phase;
        return M3HorngapSetFix.reel;
    }
  }

  /// A reel from the bag: only the plate's rating is tied on.
  DoMistake? pickReel(M3HorngapSetReel r) {
    if (!_open || index != 2 || reelFor == null) return null;
    switch (r) {
      case M3HorngapSetReel.rated:
        tying = reelFor;
        reelFor = null;
        slack = 3;
        return null;
      case M3HorngapSetReel.other:
        return _slip(deal.otherAmps > deal.plateAmps ? M3HorngapSetMistakes.thickWire : M3HorngapSetMistakes.thinWire);
      case M3HorngapSetReel.plain:
        return _slip(M3HorngapSetMistakes.plainWire);
    }
  }

  /// Draw the new wire tighter (it stops at taut).
  void pull() {
    if (!_open || tying == null || slack == 0) return;
    slack--;
  }

  /// "Tied": loose = a slip (once a set; the wire stays to tighten).
  DoMistake? tieDone() {
    if (!_open || tying == null) return null;
    final p = tying!;
    if (slack > 0) {
      if (_looseBooked.add(p)) return _slip(M3HorngapSetMistakes.loose);
      return null;
    }
    for (final f in deal.faults) {
      if (f.phase == p && f.part == M3HorngapSetPart.wire) fixed.add(f);
    }
    tying = null;
    _checkFixed();
    return null;
  }

  bool get allFixed => deal.faults.every(fixed.contains);

  void _checkFixed() {
    if (!allFixed) return;
    shown = true;
    if (_stationSlips == 0) _tag(M3HorngapSetLines.caughtWire);
  }

  // --- ঘ: back on -----------------------------------------------------------------
  void reveal() {
    if (index == 3 && !ended) revealed = true;
  }

  /// What he does once the line is on. A stop when it held: a slip.
  DoMistake? act(M3HorngapSetAct a) {
    if (!_open || index != 3 || !revealed) return null;
    final again = deal.blowsAgain;
    switch (a) {
      case M3HorngapSetAct.climbNow:
        shown = true;
        acted = a;
        return deadly = M3HorngapSetMistakes.liveRetie;
      case M3HorngapSetAct.thickWire:
        return _slip(M3HorngapSetMistakes.thickMyth);
      case M3HorngapSetAct.ok:
        if (again) return _slip(M3HorngapSetMistakes.ignoredBlow);
        shown = true;
        acted = a;
        _tag(M3HorngapSetLines.caughtHeld);
        return null;
      case M3HorngapSetAct.stopFind:
        if (!again) return _slip(M3HorngapSetMistakes.needlessStop);
        shown = true;
        acted = a;
        _tag(M3HorngapSetLines.caughtFault);
        return null;
    }
  }

  /// He was listened to: a hand on the live sets.
  DoMistake? listened() {
    if (ended) return null;
    shown = true;
    return deadly = index == 3 ? M3HorngapSetMistakes.liveRetie : M3HorngapSetMistakes.liveClimb;
  }

  /// What each set looks like now.
  M3HorngapSetLook look(int phase) {
    var wire = M3HorngapSetWire.ok;
    var bent = false;
    var carbon = false;
    for (final f in deal.faults.where((f) => f.phase == phase)) {
      final isFixed = fixed.contains(f) || index > 2;
      switch (f.fault) {
        case M3HorngapSetFault.blown:
          if (!isFixed) wire = M3HorngapSetWire.blown;
        case M3HorngapSetFault.thick:
          if (!isFixed) wire = M3HorngapSetWire.thick;
        case M3HorngapSetFault.bent:
          bent = !isFixed;
        case M3HorngapSetFault.carbon:
          carbon = !isFixed;
      }
    }
    if (index == 2 && tying == phase) wire = slack > 0 ? M3HorngapSetWire.slack : M3HorngapSetWire.ok;
    if (index == 2 && reelFor == phase) wire = M3HorngapSetWire.gone;
    if (index == 3 && revealed && deal.blowsAgain && phase == deal.blownPhase) wire = M3HorngapSetWire.blown;
    return M3HorngapSetLook(wire: wire, slack: slack, bent: bent, carbon: carbon, carbonRight: deal.carbonRight);
  }

  void next() {
    index++;
    shown = false;
    _stationSlips = 0;
  }
}

/// The quick bonus: a little under a thorough play (~85 %). Safe ≈ 5 taps
/// 6000 + reason 8200; inspect ≈ 3 taps 6000 + 8200; fix ≈ 2 parts, a reel,
/// three pulls 9000 + 8200; charge ≈ 2600 watch + 2000 + 8200; the coworker
/// ~9600; the guide's lines between ≈ 18000: ≈ 94000; 85 % ≈ 80 s.
const m3HorngapSetQuickMs = 80000;

@immutable
class M3HorngapSetPack {
  const M3HorngapSetPack({required this.id, required this.titleBn, this.quickMs = m3HorngapSetQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3HorngapSetPacks = {
  'do_3_4_b': M3HorngapSetPack(id: 'do_3_4_b', titleBn: M3HorngapSetLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3HorngapSetPage extends StatefulWidget {
  const M3HorngapSetPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3HorngapSetPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3HorngapSetPage> createState() => _M3HorngapSetPageState();
}

class _M3HorngapSetPageState extends State<M3HorngapSetPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _HgRunPage(
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

class _HgRunPage extends ConsumerStatefulWidget {
  const _HgRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3HorngapSetPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HgRunPage> createState() => _HgRunPageState();
}

class _HgRunPageState extends ConsumerState<_HgRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3HorngapSetRun _run = M3HorngapSetRun(m3HorngapSetDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
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
  int _wake = 0;
  String? _stamp;
  int _arcN = 0;
  Timer? _watchTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// ঘ: the arc has gone out and the guide said it — he may come now.
  var _arcSaid = false;

  // Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _hintKeys = {};
  GlobalKey _hk(String id) => _hintKeys.putIfAbsent(id, GlobalKey.new);
  M3HorngapSetGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _watchTimer?.cancel();
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

  void _start() {
    _clock.start();
    _startRound();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && !_freeze && _card == null && !tableBusy && !coworkerOpen && !_run.shown;

  /// The task now (what the guide says and repeats).
  String get _ask => switch (_run.index) {
        0 => M3HorngapSetLines.askSafe,
        1 => M3HorngapSetLines.askSpot,
        2 => _run.reelFor != null ? M3HorngapSetLines.askReel : (_run.tying != null ? M3HorngapSetLines.askTie : M3HorngapSetLines.askFix),
        _ => _run.revealed ? M3HorngapSetLines.askDecide : M3HorngapSetLines.askWatch,
      };

  void _startRound() {
    _watchTimer?.cancel();
    setState(() {
      _stamp = null;
      _wake++;
    });
    unawaited(_sayChain([_ask]));
    if (_run.index == _run.deal.callAt && _run.index == 0) scheduleCoworker();
    if (_run.index == 3) {
      // The line comes back on; a moment later the fuse holds or blows.
      setState(() => _busy = true);
      _watchTimer = Timer(Duration(milliseconds: _quiet ? 400 : 2600), _reveal);
    }
  }

  void _reveal() {
    if (!mounted || _ended) return;
    _run.reveal();
    final again = _run.deal.blowsAgain;
    HapticFeedback.heavyImpact();
    if (again) {
      _cue('sounds/learn/spark.ogg', volume: 1);
      _cue('sounds/intro/impact_metal.ogg', volume: 0.9);
    } else {
      _cue('sounds/intro/confirm.ogg', volume: 0.6);
    }
    setState(() {
      _busy = false;
      if (again) _arcN++;
      _wake++;
    });
    unawaited(_sayChain([again ? M3HorngapSetLines.blewAgain : M3HorngapSetLines.held, M3HorngapSetLines.askDecide]));
    if (again && _run.deal.callAt == 3) {
      // He is due from now (a fast act waits for him: holdForCoworker), and
      // on his own he comes once the arc has gone out and the guide said it.
      scheduleCoworker();
      _watchTimer = Timer(Duration(milliseconds: _quiet ? 300 : 2600), () {
        if (mounted) _arcSaid = true;
      });
    }
  }

  // --- hands on -----------------------------------------------------------------------
  void _tick() {
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
  }

  void _tapScene(Offset p, M3HorngapSetGeo geo, Offset global) {
    if (!_canPlay) return;
    switch (_run.index) {
      case 0:
        if (geo.groundFuseHit.contains(p)) {
          unawaited(_climb(global));
          return;
        }
      case 1:
      case 2:
        for (var ph = 0; ph < 3; ph++) {
          for (final part in M3HorngapSetPart.values) {
            if (!geo.partHit(ph, part).contains(p)) continue;
            if (_run.index == 1) {
              unawaited(_spot(ph, part, global));
            } else if (!_fix(ph, part)) {
              _hints.missTap();
            }
            return;
          }
        }
    }
    // A tap on nothing (the gesture hint counts these).
    _hints.missTap();
  }

  Future<void> _tapStep(M3HorngapSetStep s, Offset origin) async {
    if (!_canPlay) return;
    // The shutdown ends his moment: he cuts in first (never skipped by speed).
    if (s == M3HorngapSetStep.shutdown && holdForCoworker()) return;
    final before = _run.steps.length;
    final m = _run.tapStep(s);
    if (m != null) {
      await _slipAt(m, origin);
      return;
    }
    if (_run.steps.length == before) return;
    _tick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.4);
    setState(() => _wake++);
  }

  Future<void> _climb(Offset origin) async {
    if (!_canPlay) return;
    if (holdForCoworker()) return;
    final m = _run.climb();
    if (m == null) {
      _stationRight(M3HorngapSetLines.stampSafe);
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    await _slipAt(m, origin);
  }

  /// A part flagged: a fault gets its mark; a sound part costs a slip (the
  /// card comes after the call — no free "it's fine" reply).
  Future<void> _spot(int phase, M3HorngapSetPart part, Offset origin) async {
    final before = _run.found.length;
    final m = _run.spot(phase, part);
    if (m != null) {
      await _slipAt(m, origin);
      return;
    }
    if (_run.found.length == before) {
      _hints.missTap();
      return;
    }
    _tick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    setState(() => _wake++);
  }

  Future<void> _spotDone(Offset origin) async {
    if (!_canPlay) return;
    final m = _run.spotDone();
    if (m == null) {
      _stationRight(M3HorngapSetLines.stampSeen);
      return;
    }
    await _slipAt(m, origin);
  }

  /// A part tapped in গ; false = nothing to do there.
  bool _fix(int phase, M3HorngapSetPart part) {
    final r = _run.tapFix(phase, part);
    if (r == M3HorngapSetFix.none) return false;
    _tick();
    if (r == M3HorngapSetFix.cleaned) _cue('sounds/learn/knock_solid.ogg', volume: 0.5);
    if (r == M3HorngapSetFix.set) _cue('sounds/learn/ring_steel.ogg', volume: 0.5);
    setState(() => _wake++);
    if (_run.shown) {
      _stationRight(M3HorngapSetLines.stampFixed);
      return true;
    }
    if (r == M3HorngapSetFix.reel) unawaited(_sayChain([M3HorngapSetLines.askReel]));
    return true;
  }

  Future<void> _pickReel(M3HorngapSetReel r, Offset origin) async {
    if (!_canPlay) return;
    final m = _run.pickReel(r);
    if (m != null) {
      await _slipAt(m, origin);
      return;
    }
    _tick();
    setState(() => _wake++);
    unawaited(_sayChain([M3HorngapSetLines.askTie]));
  }

  void _pull() {
    if (!_canPlay || _run.tying == null) return;
    _run.pull();
    _tick();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.35);
    setState(() => _wake++);
  }

  Future<void> _tieDone(Offset origin) async {
    if (!_canPlay) return;
    final m = _run.tieDone();
    if (m != null) {
      await _slipAt(m, origin);
      return;
    }
    _tick();
    setState(() => _wake++);
    if (_run.shown) _stationRight(M3HorngapSetLines.stampFixed);
  }

  Future<void> _act(M3HorngapSetAct a, Offset origin) async {
    if (!_canPlay || !_run.revealed) return;
    // Any act ends his moment in ঘ: he cuts in first.
    if (holdForCoworker()) return;
    final m = _run.act(a);
    if (m == null && !_run.shown) return;
    if (m == null) {
      _stationRight(a == M3HorngapSetAct.ok ? M3HorngapSetLines.stampHeld : M3HorngapSetLines.stampStop);
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    await _slipAt(m, origin);
  }

  /// A station done right: stamp, ◆ on the table, "কেন …?".
  void _stationRight(String stamp) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() {
      _stamp = stamp;
      _wake++;
    });
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M3HorngapSetLines.whyRight(_run), M3HorngapSetLines.whyWrong(_run), widget.rng),
      question: M3HorngapSetLines.why(_run),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3HorngapSetLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _freeze || _run.index != _run.deal.callAt || _run.shown) return null;
    // His push ("change it live, the shutdown takes too long") only makes
    // sense before the shutdown in ক, and in ঘ once it blew again.
    if (_run.index == 0 && _run.shutdown) return null;
    if (_run.index == 3 && (!_run.revealed || !_run.deal.blowsAgain)) return _run.revealed ? null : false;
    if (_intro || _busy || _card != null || tableBusy) return false;
    // ঘ: on his own he waits for the arc and the guide's line (a held
    // decisive control lets him in at once).
    if (_run.index == 3 && !_arcSaid) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listened();
      if (m != null) await _deadly(m);
      return;
    }
    if (!_run.caught.contains(M3HorngapSetLines.caughtCall)) _run.caught.add(M3HorngapSetLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3HorngapSetLines.callHeld]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3HorngapSetLines.tapWhy[_nudgeN++ % M3HorngapSetLines.tapWhy.length]
            : _nudge.next(_ask);
    _tick();
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _slipAt(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('horngap/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on the live sets: the scene freezes grey and the flash plays at
  /// the sets in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('horngap/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3HorngapSetLines.deadlyWord : M3HorngapSetLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        // The station stays: the task again.
        unawaited(_sayChain([_ask]));
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
    await _say(!_run.passed ? M3HorngapSetLines.fail : (_quickBonus ? M3HorngapSetLines.quick : M3HorngapSetLines.allSet),
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
    if (_stamp != null) return LinemanMode.cheer;
    if (_run.index == 3 && _run.revealed && _run.deal.blowsAgain) return LinemanMode.worried;
    if (_run.up) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M3HorngapSetGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final up = _run.up;
    final looks = [for (var i = 0; i < 3; i++) _run.look(i)];
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = up ? geo.topTrainee : geo.groundTrainee;
    final rings = <(String, Offset, bool)>[
      if (_run.index == 1)
        for (final f in _run.found) ('f-$f', geo.partAt(f.phase, f.part), true),
      if (_run.index == 2)
        for (final f in _run.found.where((f) => !_run.fixed.contains(f))) ('x-$f', geo.partAt(f.phase, f.part), false),
    ];
    final stampAt = up ? Offset(110, geo.termY - 200) : Offset(150, geo.groundTrainee.top - 20);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: ValueKey(up ? 'land-top' : 'land-ground'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: up
                        ? M3HorngapSetTopPainter(geo: geo, looks: looks)
                        : M3HorngapSetGroundPainter(geo: geo, looks: looks, earthed: _run.earthed, lit: _run.lit),
                  ),
                ),
              ),
              if (up)
                Positioned.fromRect(
                  key: const ValueKey('plate'),
                  rect: geo.plate,
                  child: _Plate(text: M3HorngapSetLines.plate(_run.deal.plateAmps)),
                ),
              Positioned.fromRect(
                key: ValueKey(up ? 'trainee-top' : 'trainee-ground'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (up)
                Positioned.fill(
                  key: const ValueKey('strap'),
                  child: IgnorePointer(child: CustomPaint(painter: M3HorngapSetStrapPainter(box: tb))),
                ),
            ],
          ),
        ),
      ),
      if (!_freeze)
        for (final (id, p, red) in rings)
          Positioned(
            key: ValueKey('ring-$id'),
            left: p.dx - 22,
            top: p.dy - 22,
            width: 44,
            height: 44,
            child: IgnorePointer(child: _Ring(red: red)),
          ),
      if (_arcN > 0 && _run.index == 3 && !_freeze)
        Positioned.fill(
          key: ValueKey('arc-$_arcN'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1600),
              builder: (_, v, _) => CustomPaint(painter: M3HorngapSetArcPainter(foot: geo.groundArcAt(_run.deal.blownPhase), scale: 0.9, v: v)),
            ),
          ),
        ),
      if (_run.index == 3 && !_freeze) ...[
        Positioned.fill(
          key: const ValueKey('zoom-lead'),
          child: IgnorePointer(child: CustomPaint(painter: _LeadPainter(from: _zoomRect.centerRight, to: geo.groundArcAt(_run.deal.blownPhase)))),
        ),
        Positioned.fromRect(
          key: const ValueKey('zoom'),
          rect: _zoomRect,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2F0E8), width: 3),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: ClipOval(
                child: LayoutBuilder(
                  builder: (_, box) {
                    final sz = box.biggest;
                    return Stack(
                      children: [
                        Positioned.fill(
                          key: const ValueKey('zoom-set'),
                          child: CustomPaint(painter: M3HorngapSetZoomPainter(look: _run.look(_run.deal.blownPhase))),
                        ),
                        if (_arcN > 0)
                          Positioned.fill(
                            key: ValueKey('zoom-arc-$_arcN'),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: quiet ? 1 : 0, end: 1),
                              duration: const Duration(milliseconds: 2200),
                              builder: (_, v, _) => CustomPaint(
                                painter: M3HorngapSetArcPainter(
                                    foot: M3HorngapSetZoomPainter.zoomFoot(sz), scale: M3HorngapSetZoomPainter.zoomScale(sz), v: v),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
      if (_stamp != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: stampAt.dx,
          top: stampAt.dy,
          child: IgnorePointer(child: _StampPop(text: _stamp!, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3HorngapSetLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3HorngapSetZapPainter(at: geo.groundArcAt(1) + const Offset(0, -10), v: v)),
            ),
          ),
        ),
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  /// The close-up bubble in ঘ (design px), left of the pole.
  static const _zoomRect = Rect.fromLTWH(14, 96, 136, 136);

  /// The controls for the station (only what the hands need now).
  List<Widget> _hud(EdgeInsets pad) {
    final b = pad.bottom;
    Widget bottomRow(String key, List<Widget> children, {double at = 12}) => Positioned(
          key: ValueKey(key),
          left: 12,
          right: 12,
          bottom: b + at,
          child: Row(children: [for (final (i, w) in children.indexed) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: w)]]),
        );
    switch (_run.index) {
      case 0:
        return [
          Positioned(
            key: const ValueKey('hud-steps'),
            left: 6,
            right: 6,
            bottom: b + 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final s in _run.deal.tokens)
                  _ToolButton(
                    key: _hk('step-${s.name}'),
                    icon: _stepIcon(s),
                    label: M3HorngapSetLines.step(s),
                    done: _run.steps.contains(s),
                    onTapUp: (d) => unawaited(_tapStep(s, d.globalPosition)),
                  ),
              ],
            ),
          ),
          bottomRow('hud-climb', [
            KeyedSubtree(
              key: _hk('climb'),
              child: DoBigButton(label: M3HorngapSetLines.climb, filled: true, onTapUp: (d) => unawaited(_climb(d.globalPosition))),
            ),
          ]),
        ];
      case 1:
        return [
          bottomRow('hud-seen', [DoBigButton(label: M3HorngapSetLines.spotDone, filled: true, onTapUp: (d) => unawaited(_spotDone(d.globalPosition)))]),
        ];
      case 2:
        if (_run.reelFor != null) {
          return [
            Positioned(
              key: const ValueKey('hud-reels'),
              left: 6,
              right: 6,
              bottom: b + 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final r in _run.deal.reels)
                    _ToolButton(
                      key: _hk('reel-${r.name}'),
                      icon: Icons.all_inclusive_rounded,
                      label: _reelLabel(r),
                      wide: true,
                      onTapUp: (d) => unawaited(_pickReel(r, d.globalPosition)),
                    ),
                ],
              ),
            ),
          ];
        }
        if (_run.tying != null) {
          return [
            bottomRow('hud-tie', [
              KeyedSubtree(key: _hk('pull'), child: DoBigButton(label: M3HorngapSetLines.pull, filled: false, onDark: true, onTapUp: (_) => _pull())),
              KeyedSubtree(
                key: _hk('tie'),
                child: DoBigButton(label: M3HorngapSetLines.tieDone, filled: true, onTapUp: (d) => unawaited(_tieDone(d.globalPosition))),
              ),
            ]),
          ];
        }
        return const [];
      default:
        if (!_run.revealed) return const [];
        // The four acts as dealt (shuffled: the right one has no fixed spot).
        final acts = _run.deal.acts;
        Widget actButton(M3HorngapSetAct a) => KeyedSubtree(
              key: _hk('act-${a.name}'),
              child: DoBigButton(label: M3HorngapSetLines.act(a), filled: false, onDark: true, onTapUp: (d) => unawaited(_act(a, d.globalPosition))),
            );
        return [
          bottomRow('hud-act-a', [for (final a in acts.take(2)) actButton(a)], at: 72),
          bottomRow('hud-act-b', [for (final a in acts.skip(2)) actButton(a)]),
        ];
    }
  }

  /// The gesture hint for the waiting state: a sweep over every control of
  /// the station (or every part of the three sets), never pressing one.
  HintSpec? _hint() {
    switch (_run.index) {
      case 0:
        return HintSpec.sweepOver([for (final s in _run.deal.tokens) _hk('step-${s.name}'), _hk('climb')]);
      case 1:
      case 2:
        if (_run.index == 2 && _run.reelFor != null) return HintSpec.sweepOver([for (final r in _run.deal.reels) _hk('reel-${r.name}')]);
        if (_run.index == 2 && _run.tying != null) return HintSpec.sweepOver([_hk('pull'), _hk('tie')]);
        final geo = _geo;
        if (geo == null) return null;
        return HintSpec.sweep([
          for (var ph = 0; ph < 3; ph++)
            for (final part in M3HorngapSetPart.values) geo.partHit(ph, part),
        ], space: HintSpace.scene);
      default:
        if (!_run.revealed) return null;
        return HintSpec.sweepOver([for (final a in _run.deal.acts) _hk('act-${a.name}')]);
    }
  }

  String _reelLabel(M3HorngapSetReel r) => switch (r) {
        M3HorngapSetReel.rated => M3HorngapSetLines.fuseWire(_run.deal.plateAmps),
        M3HorngapSetReel.other => M3HorngapSetLines.fuseWire(_run.deal.otherAmps),
        M3HorngapSetReel.plain => M3HorngapSetLines.plainWire,
      };

  static IconData _stepIcon(M3HorngapSetStep s) => switch (s) {
        M3HorngapSetStep.shutdown => Icons.power_settings_new_rounded,
        M3HorngapSetStep.ptw => Icons.assignment_rounded,
        M3HorngapSetStep.test => Icons.electric_bolt_rounded,
        M3HorngapSetStep.earth => Icons.download_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.done && !_run.shown && !deckUp && !coworkerOpen && _card == null && !_busy && !tableBusy;
    final hud = handsOn ? _hud(pad) : const <Widget>[];
    final guideAt = deckUp ? 236.0 : (_run.index == 0 ? 150.0 : (_run.index == 3 && _run.revealed ? 134.0 : (_run.reelFor != null ? 112.0 : 72.0)));
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
              labels: M3HorngapSetLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, M3HorngapSetRun.stations); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && (_run.index != 3 || _run.revealed),
            hintKey: '${_run.index}-${_run.reelFor}-${_run.tying}-${_run.revealed}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              ...hud,
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + guideAt, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  sound: FailSound.electric,
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
                  line: M3HorngapSetLines.intro,
                  alarm: 'sounds/learn/spark.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _start();
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

/// The line from the close-up bubble to the set it shows.
class _LeadPainter extends CustomPainter {
  const _LeadPainter({required this.from, required this.to});
  final Offset from;
  final Offset to;

  @override
  void paint(Canvas c, Size size) {
    c.drawLine(from, to, Paint()
      ..color = const Color(0xCCF2F0E8)
      ..strokeWidth = 2);
    c.drawCircle(to, 9, Paint()
      ..color = const Color(0xCCF2F0E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_LeadPainter old) => old.from != from || old.to != to;
}

/// The rating plate on the pole (what the worker reads).
class _Plate extends StatelessWidget {
  const _Plate({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F1E6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2B2F36), width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, height: 1.1, color: const Color(0xFF1C2230))),
          ),
        ),
      );
}

/// A ring on a part: red = a fault he found; amber = still to fix.
class _Ring extends StatelessWidget {
  const _Ring({required this.red});
  final bool red;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: red ? const Color(0xFFE5483B) : const Color(0xFFF2B21B), width: 3),
        ),
      );
}

/// A hands-on token: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.onTapUp, this.done = false, this.wide = false});
  final IconData icon;
  final String label;
  final bool done;
  final bool wide;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = done ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: done ? null : onTapUp,
        child: SizedBox(
          width: wide ? 104 : 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: done ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(done ? Icons.check_rounded : icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
