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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_fault_casebook_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 5.6 "শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই ভিন্ন শত্রু", কাজ 1
// "দুই শত্রুর খাতা" (pack do_5_6_a, engineType m5_fault_casebook). Four fault
// cases at a village edge, one after another (dealt from six kinds):
//
//   T1 short, two wires clashed         T4 open, one phase off (single-phasing)
//   T2 short through a branch / a bird  T5 a trip with no sign of a short
//   T3 open, a jumper came off          T6 a high-resistance short (dry wood)
//
// Each case slip shows only the place and the protection state ('ফিডার ট্রিপ
// করেছে' / 'ডিও ফিউজ উড়েছে' / 'ট্রিপ নেই, ফিউজ ঠিক'). The same four clue
// spots are on the scene every time; the player may spend two clues, each by
// its own gesture — tap the person, swipe up the pole, sweep the ground strip,
// hold the pump-house door — and sees each clue in a close-up lens and as a
// note in the notebook. Only when both clues are seen (or every clue is shown
// after a wrong box) can the slip be dragged into one of three boxes (fixed
// order): 'শর্ট সার্কিট' · 'ওপেন সার্কিট' · 'ট্রিপ — শর্টের প্রমাণ নেই' (ruling
// M5-10: no verdict without its evidence). Touching the locked slip points at
// the clues. Right → ◆ on the table → "কেন …?"; wrong = a slip, then every
// clue is shown and the slip is filed again.
//
// The lesson's rules, and only those (lesson 5.6):
//   • point 0: short — huge current, a big arc flash, a bang, a fuse blown or
//     the breaker tripping at once, burn marks; causes: a branch, a bird,
//     wires touching;
//   • point 1: open — the power simply stops, no big arc or bang; one phase of
//     three open = single-phasing, a motor groans or will not run;
//   • point 2: two wires touching = short; a jumper coming off = open;
//   • point 2: in a short the current rises hugely; in an open it drops to
//     zero (so an open alone trips nothing: a trip with no sign of a short is
//     the third box, and its card says so in these words);
//   • myth 1: a trip does not always mean a short — a big overload or a relay
//     maloperation trips too;
//   • pro tip 3: a short through dry wood carries little current; the fuse or
//     breaker may not operate; a big cause of fires.
// The pump's groan is lesson-backed (point 1: the motor makes an abnormal
// noise or will not run). The smoke wisp, the scorched leaves, the melted
// wire beads and the scorched feathers are illustrations (flagged to the
// owner). A no-sign trip is dealt only as a feeder trip: the lesson counts a
// blown fuse as an open-circuit example, so 'ডিও ফিউজ উড়েছে' with no sign
// would blur the boxes.
//
// Deadly: none (Module 5 table: this rung has no deadly act). Slips: a wrong
// box; listening to the coworker (R29: a myth with no immediate danger).
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_fault_casebook_world.dart), corner guide, ◆ on the table → "কেন
// …?" after each case; the careless coworker once a play, on a trip case, at
// the first clue gesture (the clue waits for him; going on with a clue
// gesture while he talks refuses him; filing that case also waits for him —
// holdForCoworker, a safety net now that filing needs both clues). Gesture
// hints: the kit's hand sweeps over all
// four spots (or nudges the slip toward the notebook spine — never toward a
// box); a wrong gesture on a spot shows only that spot's gesture glyph; after
// 6 s idle all four glyphs show together for 2 s. Voice: the guide by device
// TTS; the coworker's push needs his recorded clip (silent with its caption
// held until then); his exit line is his existing clip.

// ============================================================================
// Content
// ============================================================================

/// The three boxes of the notebook (always in this order).
enum M5Box { short, open, noProof }

/// What the case slip says about the protection.
enum M5Protection { feederTrip, doBlown, none }

/// The six case kinds (T1–T6).
enum M5CaseKind { clash, bridge, jumper, phase, noSign, hidden }

M5Box m5AnswerOf(M5CaseKind k) => switch (k) {
      M5CaseKind.clash || M5CaseKind.bridge || M5CaseKind.hidden => M5Box.short,
      M5CaseKind.jumper || M5CaseKind.phase => M5Box.open,
      M5CaseKind.noSign => M5Box.noProof,
    };

/// A trip / blown fuse on the slip (else 'ট্রিপ নেই, ফিউজ ঠিক').
bool m5Trips(M5CaseKind k) => k == M5CaseKind.clash || k == M5CaseKind.bridge || k == M5CaseKind.noSign;

/// One spot's clue in a case: its close-up and the note's wordings.
@immutable
class M5Clue {
  const M5Clue(this.look, this.notes);
  final M5Look look;
  final List<String> notes;
}

abstract final class M5CasebookLines {
  static const title = 'দুই শত্রুর খাতা';
  static const intro = 'চার জায়গায় লাইনের গোলমাল — সূত্র ধরে শত্রু চিনুন!';

  // The guide's task now (tap him: the same task, a different way).
  static const askClue = 'দুটো ক্লু দেখুন, তারপর স্লিপ খাতায় রাখুন।';
  static const askFile = 'কোন শত্রু? স্লিপটা ঠিক ঘরে রাখুন।';
  static const cluesGone = 'সূত্র শেষ — এবার স্লিপটা খাতায় রাখুন।';
  static const revealed = 'সব সূত্র খোলা — আবার ভেবে স্লিপ রাখুন।';

  /// The slip touched before both clues are seen (it does not move).
  static const clueFirst = 'আগে দুটো ক্লু দেখুন — প্রমাণ ছাড়া খাতায় লেখা নয়।';
  static const tasks = [askClue, askFile];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'গ্রামের ধারে লাইন';
  static const notebook = 'গোয়েন্দার নোটবুক';
  static const clues = 'সূত্র';
  static String caseNo(int i, int n) => enDigits('কেস ${i + 1}/$n');
  static String progress(int i) => enDigits('কেস ${i + 1}');

  static String boxLabel(M5Box b) => switch (b) {
        M5Box.short => 'শর্ট সার্কিট',
        M5Box.open => 'ওপেন সার্কিট',
        M5Box.noProof => 'ট্রিপ — শর্টের প্রমাণ নেই',
      };

  static String protection(M5Protection p) => switch (p) {
        M5Protection.feederTrip => 'ফিডার ট্রিপ করেছে',
        M5Protection.doBlown => 'ডিও ফিউজ উড়েছে',
        M5Protection.none => 'ট্রিপ নেই, ফিউজ ঠিক',
      };

  static const places = ['পুকুরপাড়ে', 'হাটের পাশে', 'স্কুল মাঠের ধারে', 'ধানক্ষেতের ধারে', 'বাঁশবাগানের ধারে', 'মন্দিরের কাছে'];

  // The clues (symptoms only, never the fault's name). One variant per kind,
  // two for the bridged short (a branch or a bird).
  static const _pumpStopped = M5Clue(M5Look.pumpStopped, ['পাম্প বন্ধ, মোটর চুপচাপ', 'মোটর থেমে আছে, নালায় জল নেই']);
  static const _groundClean = M5Clue(M5Look.groundClean, ['মাটিতে কিছু নেই, পোড়া দাগ নেই', 'ঘাস যেমন ছিল, কোথাও দাগ নেই']);
  static const clueBook = <M5CaseKind, List<Map<M5Spot, M5Clue>>>{
    M5CaseKind.clash: [
      {
        M5Spot.person: M5Clue(M5Look.witnessBang, ['বিকট শব্দ হলো, তারপর নীল ঝলক!', 'বোমার মতো আওয়াজ, তারে আলোর ঝলক!', 'ঠাস করে শব্দ, তারে আগুনের ফুলকি!']),
        M5Spot.pole: M5Clue(M5Look.poleClash, ['দুই তার কাছাকাছি, কালো পোড়া দাগ', 'দুটো তারে ঠোকাঠুকির কালো দাগ']),
        M5Spot.ground: M5Clue(M5Look.groundMelt, ['নিচে গলা তারের পোড়া টুকরো', 'ঘাসে কালো পোড়া দাগ, গলা দানা']),
        M5Spot.pump: _pumpStopped,
      },
    ],
    M5CaseKind.bridge: [
      {
        M5Spot.person: M5Clue(M5Look.witnessBang, ['ডালটা পড়তেই ফটাস শব্দ আর ঝলক!', 'ডাল ভেঙে তারে পড়ল, বিকট আওয়াজ!']),
        M5Spot.pole: M5Clue(M5Look.poleBranch, ['দুই তারের উপর ডাল, পোড়া দাগ', 'তারে আটকে থাকা ডালে কালো দাগ']),
        M5Spot.ground: M5Clue(M5Look.groundTwigs, ['নিচে পোড়া ডাল আর ঝলসানো পাতা', 'ঘাসে কালো দাগ, পোড়া কাঠি']),
        M5Spot.pump: _pumpStopped,
      },
      {
        M5Spot.person: M5Clue(M5Look.witnessBang, ['পাখিটা বসতেই ঝলক, বিকট আওয়াজ!', 'বড় পাখি তারে বসল, ফটাস শব্দ!']),
        M5Spot.pole: M5Clue(M5Look.poleBird, ['দুই তার ছুঁয়ে পাখি, পোড়া দাগ', 'দুই তারের মাঝে কালো পোড়া দাগ']),
        M5Spot.ground: M5Clue(M5Look.groundFeathers, ['নিচে ঝলসানো পালক, কালো দাগ', 'ঘাসে পোড়া পালক ছড়ানো']),
        M5Spot.pump: _pumpStopped,
      },
    ],
    M5CaseKind.jumper: [
      {
        M5Spot.person: M5Clue(M5Look.witnessQuiet, ['হঠাৎ আলো চলে গেল, কোনো শব্দ হয়নি।', 'চুপচাপ বিদ্যুৎ চলে গেল, ঝলক দেখিনি।']),
        M5Spot.pole: M5Clue(M5Look.poleJumper, ['একটা জাম্পার খুলে ঝুলছে, দাগ নেই', 'জাম্পারের সংযোগ খোলা, পোড়া নেই']),
        M5Spot.ground: _groundClean,
        M5Spot.pump: _pumpStopped,
      },
    ],
    M5CaseKind.phase: [
      {
        M5Spot.person: M5Clue(M5Look.witnessGroan, ['পাম্পটা গোঁ গোঁ করছে, জল উঠছে না।', 'মোটরটা অদ্ভুত শব্দ করছে, ঘুরছে না।']),
        M5Spot.pole: M5Clue(M5Look.polePhase, ['তিন তারের একটা বিচ্ছিন্ন, দাগ নেই', 'এক ফেজের সংযোগ খোলা, পোড়া নেই']),
        M5Spot.ground: _groundClean,
        M5Spot.pump: M5Clue(M5Look.pumpGroan, ['মোটর গোঁ গোঁ করছে, ঘুরছে না', 'মোটরে অস্বাভাবিক শব্দ, জল নেই']),
      },
    ],
    M5CaseKind.noSign: [
      {
        M5Spot.person: M5Clue(M5Look.witnessQuiet, ['কোনো শব্দ বা ঝলক দেখিনি, শুধু বন্ধ।', 'সব শান্ত ছিল, হঠাৎ বিদ্যুৎ বন্ধ।']),
        M5Spot.pole: M5Clue(M5Look.poleClean, ['সব তার, জাম্পার ঠিক; দাগ নেই', 'তার টানটান, কোথাও পোড়া নেই']),
        M5Spot.ground: _groundClean,
        M5Spot.pump: _pumpStopped,
      },
    ],
    M5CaseKind.hidden: [
      {
        M5Spot.person: M5Clue(M5Look.witnessSmoke, ['আলো আছে, কিন্তু তারের কাছে ধোঁয়া!', 'বিদ্যুৎ আছে, তবে ডালটা থেকে ধোঁয়া উঠছে।']),
        M5Spot.pole: M5Clue(M5Look.poleDryBranch, ['শুকনো ডাল তারে ঠেকে, হালকা ধোঁয়া', 'একটা শুকনো ডাল তারে লেগে আছে']),
        M5Spot.ground: M5Clue(M5Look.groundLeaves, ['নিচে কিনারা-পোড়া শুকনো পাতা', 'ঘাসে ঝলসানো শুকনো পাতা']),
        M5Spot.pump: M5Clue(M5Look.pumpRunning, ['পাম্প চলছে, জল উঠছে', 'মোটর ঘুরছে, নালায় জল']),
      },
    ],
  };

  // The reasons: the right ones fit the case just filed; the wrong ones are
  // the lesson's myths and field excuses. 38–48 letters.
  static const whyShort = ['ঝলক, বিকট শব্দ, পোড়া দাগ — শর্টের লক্ষণ', 'কম রেজিস্ট্যান্সের পথে প্রচণ্ড কারেন্ট, তাই ঝলক'];
  static const whyOpen = ['বিদ্যুৎ বন্ধ, কিন্তু আর্ক বা বিস্ফোরণ নেই', 'পথ ভেঙেছে — কারেন্ট শূন্য, কোনো ঝলক নেই'];
  static const whyPhase = ['একটা ফেজ বিচ্ছিন্ন হলে মোটর অস্বাভাবিক শব্দ করে', 'তিন ফেজের একটা খোলা — সিঙ্গেল-ফেজিং, ঝলক নেই'];
  static const whyNoProof = ['বড় ওভারলোডেও ফিউজ বা ব্রেকার ট্রিপ করতে পারে', 'রিলের ভুলেও ট্রিপ হয় — শর্টের লক্ষণ পাইনি'];
  static const whyHidden = ['শুকনো কাঠ দিয়ে শর্টে কারেন্ট কম, ফিউজ পড়ে না', 'উচ্চ রেজিস্ট্যান্স ফল্টে ফিউজ বা ব্রেকার পড়ে না'];
  static const myths = [
    'ট্রিপ করেছে মানেই কোথাও শর্ট সার্কিট হয়েছে',
    'ওপেন সার্কিটে বিপদ নেই, বিদ্যুৎ তো বন্ধই আছে',
    'ফিউজ বা ব্রেকার না পড়লে কোনো ফল্টই হয়নি',
    'আলো নেই মানেই কোথাও শর্ট সার্কিট হয়েছে',
    'ঝলক হোক বা না হোক, সব ফল্টই আসলে একই রকম',
    'আন্দাজেই লিখলাম, পরে কেউ এসে দেখে নেবে',
    'বিকট শব্দ না হলে লাইনে কোনো সমস্যাই নেই',
  ];
  static List<String> get allWhyRight => [...whyShort, ...whyOpen, ...whyPhase, ...whyNoProof, ...whyHidden];

  static List<String> whyRight(M5CaseKind k) => switch (k) {
        M5CaseKind.clash || M5CaseKind.bridge => whyShort,
        M5CaseKind.jumper => whyOpen,
        M5CaseKind.phase => whyPhase,
        M5CaseKind.noSign => whyNoProof,
        M5CaseKind.hidden => whyHidden,
      };
  static String whyQuestion(M5CaseKind k) => switch (k) {
        M5CaseKind.clash || M5CaseKind.bridge => 'কেন শর্ট সার্কিট লিখলেন?',
        M5CaseKind.jumper || M5CaseKind.phase => 'কেন ওপেন সার্কিট লিখলেন?',
        M5CaseKind.noSign => 'কেন শর্ট লিখলেন না, ট্রিপ তো করেছে?',
        M5CaseKind.hidden => 'ফিউজ তো পড়েনি — তবু কেন শর্ট?',
      };

  /// The careless coworker: lesson 5.6's myth 1, on a trip case.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLine = 'লাইন ট্রিপ করেছে মানেই কোথাও শর্ট সার্কিট হয়েছে। শর্ট লিখে দিন, আর খোঁজার দরকার নেই!';

  /// His lines with no recorded clip yet (the director records them with
  /// tool/rival_clip.py); until then the line is silent, its caption held.
  static const toRecord = [coworkerLine];
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: ['না — ওভারলোড বা রিলের ভুলেও ট্রিপ হয়, সূত্র দেখি', 'না, ট্রিপ মানেই শর্ট নয় — আগে সূত্র দেখব', 'না, শর্টের লক্ষণ মিলিয়ে তবে খাতায় লিখব'],
    wrong: [
      'ঠিক, ট্রিপ মানেই শর্ট — লিখে দিই, খোঁজা থাক',
      'ও যখন বলছে, আর খোঁজার দরকার নেই, লিখে দিই',
      'হ্যাঁ, ট্রিপ হয়েছে, শর্টই লিখে ফেলি এখন',
      'ঠিক আছে, সূত্র দেখার সময় নেই, শর্ট লিখি',
      'আচ্ছা, শর্টই লিখে সোজা পরের কেসে চলে যাই',
    ],
    asks: ['ওর কথা শুনবেন?', 'ট্রিপ মানেই কি শর্ট?', 'সূত্র না দেখেই লিখবেন?'],
  );

  static const callHeld = 'ঠিক! ট্রিপ মানেই শর্ট নয় — সূত্রই বলবে।';
  static const allSet = 'দুই শত্রুই চিনেছেন — শর্ট আর ওপেন, সূত্র দেখে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — সূত্র দেখে তবে শত্রুর নাম লিখুন।';

  // "আজ যা ধরলেন".
  static const caughtShort = 'ঝলক আর পোড়া দাগে শর্ট সার্কিট চিনেছেন';
  static const caughtOpen = 'নিঃশব্দ পাওয়ার কাটে ওপেন সার্কিট চিনেছেন';
  static const caughtNoProof = 'ট্রিপ মানেই শর্ট নয় — প্রমাণ খুঁজেছেন';
  static const caughtHidden = 'ফিউজ না পড়লেও লুকোনো শর্ট ধরেছেন';
  static const caughtCall = '“ট্রিপ মানেই শর্ট” — এই কথায় “না” বলেছেন';

  static String caught(M5CaseKind k) => switch (k) {
        M5CaseKind.clash || M5CaseKind.bridge => caughtShort,
        M5CaseKind.jumper || M5CaseKind.phase => caughtOpen,
        M5CaseKind.noSign => caughtNoProof,
        M5CaseKind.hidden => caughtHidden,
      };

  /// Every fixed line on screen or spoken (tests: English digits, no পানি).
  static List<String> get allText => [
        intro,
        ...tasks,
        cluesGone,
        revealed,
        clueFirst,
        ...tapWhy,
        notebook,
        clues,
        for (final b in M5Box.values) boxLabel(b),
        for (final p in M5Protection.values) protection(p),
        ...places,
        for (final vs in clueBook.values)
          for (final v in vs)
            for (final c in v.values) ...c.notes,
        ...allWhyRight,
        ...myths,
        for (final k in M5CaseKind.values) whyQuestion(k),
        ...coworker.recordedLines,
        ...coworker.right,
        ...coworker.wrong,
        ...coworker.asks,
        callHeld,
        allSet,
        quick,
        fail,
        caughtShort,
        caughtOpen,
        caughtNoProof,
        caughtHidden,
        caughtCall,
      ];
}

abstract final class M5CasebookMistakes {
  static const _dir = 'assets/game/art/m5_fault_casebook';

  static const missedShort = DoMistake(
    key: '5.6/m5_fault_casebook/missed-short',
    textBn: 'বিকট শব্দ, বড় ঝলক, পোড়া দাগ — এগুলোই শর্ট সার্কিটের লক্ষণ। এমন সূত্র পেলে শর্ট লিখুন।',
    art: '$_dir/short_signs.svg',
    lessonPoint: 0,
  );
  static const missedOpen = DoMistake(
    key: '5.6/m5_fault_casebook/missed-open',
    textBn: 'বিদ্যুৎ বন্ধ, কিন্তু কোনো আর্ক বা বিস্ফোরণ নেই — পথ ভেঙেছে। খোলা জাম্পারের মতো, এটা ওপেন সার্কিট।',
    art: '$_dir/open_path.svg',
    lessonPoint: 2,
  );
  static const singlePhase = DoMistake(
    key: '5.6/m5_fault_casebook/single-phasing',
    textBn: 'তিন ফেজের একটা বিচ্ছিন্ন — মোটর অস্বাভাবিক শব্দ করে বা চলে না। এটা সিঙ্গেল-ফেজিং, এক ধরনের ওপেন সার্কিট।',
    art: '$_dir/single_phase.svg',
    lessonPoint: 1,
  );
  /// A no-sign feeder trip filed as open: the rule the third box rests on, in
  /// the lesson's words (point 2: an open circuit's current drops to zero).
  static const tripNotOpen = DoMistake(
    key: '5.6/m5_fault_casebook/trip-not-open',
    textBn: 'ওপেন সার্কিটে কারেন্ট শূন্য হয়, তাই ট্রিপ হয় না। এখানে ট্রিপ হয়েছে, অথচ ঝলক, শব্দ, পোড়া দাগ নেই: শর্টের প্রমাণ নেই।',
    art: '$_dir/no_proof.svg',
    lessonPoint: 2,
  );
  // Myth 1 and pro tip 3 are not numbered lesson points (lessonPoint null):
  // their "পাঠে দেখুন" opens the lesson at its top, with no jump.
  static const noProof = DoMistake(
    key: '5.6/m5_fault_casebook/no-proof',
    textBn: 'ট্রিপ হয়েছে, কিন্তু ঝলক, শব্দ, পোড়া দাগ — কিছুই নেই। বড় ওভারলোড বা রিলের ভুলেও ট্রিপ হয়: শর্টের প্রমাণ নেই।',
    art: '$_dir/no_proof.svg',
  );
  static const hiddenShort = DoMistake(
    key: '5.6/m5_fault_casebook/hidden-short',
    textBn: 'ফিউজ পড়েনি, তবু শুকনো ডাল তারে ঠেকে — উচ্চ রেজিস্ট্যান্স শর্ট। কারেন্ট কম বলে ফিউজ বা ব্রেকার পড়ে না।',
    art: '$_dir/hidden_short.svg',
  );
  static const listened = DoMistake(
    key: '5.6/m5_fault_casebook/trip-myth',
    textBn: 'লাইন ট্রিপ মানেই শর্ট নয় — বড় ওভারলোড বা সুরক্ষা রিলের ভুলেও ট্রিপ হয়। সূত্র দেখে তবে খাতায় লিখুন।',
    art: '$_dir/trip_myth.svg',
  );

  /// The card for filing a case of [k] in the wrong box [b].
  static DoMistake wrongBox(M5CaseKind k, M5Box b) => switch (k) {
        M5CaseKind.clash || M5CaseKind.bridge => missedShort,
        M5CaseKind.jumper => missedOpen,
        M5CaseKind.phase => singlePhase,
        M5CaseKind.noSign => b == M5Box.open ? tripNotOpen : noProof,
        M5CaseKind.hidden => hiddenShort,
      };

  static const all = [missedShort, missedOpen, singlePhase, tripNotOpen, noProof, hiddenShort, listened];
}

/// One dealt case.
@immutable
class M5Case {
  const M5Case({required this.kind, required this.protection, required this.place, required this.clues, required this.notes});

  final M5CaseKind kind;
  final M5Protection protection;
  final String place;

  /// The clue per spot (its close-up) and the note dealt for it.
  final Map<M5Spot, M5Clue> clues;
  final Map<M5Spot, String> notes;

  M5Box get answer => m5AnswerOf(kind);
}

@immutable
class M5CasebookDeal {
  const M5CasebookDeal({required this.cases, required this.coworkerCase});

  final List<M5Case> cases;

  /// The case the coworker comes on (always a trip case).
  final int coworkerCase;
}

/// Four different kinds (at least one open case), four places; the coworker
/// on one of the trip cases (any of them — never only on one kind).
M5CasebookDeal m5CasebookDeal(math.Random rng) {
  List<M5CaseKind> kinds;
  do {
    kinds = ([...M5CaseKind.values]..shuffle(rng)).take(4).toList();
  } while (!kinds.any((k) => m5AnswerOf(k) == M5Box.open));
  final places = [...M5CasebookLines.places]..shuffle(rng);
  final cases = <M5Case>[];
  for (final (i, k) in kinds.indexed) {
    final variants = M5CasebookLines.clueBook[k]!;
    final v = variants[rng.nextInt(variants.length)];
    // A no-sign trip is always a feeder trip (a blown fuse alone is an
    // open-circuit example in the lesson).
    final protection = !m5Trips(k)
        ? M5Protection.none
        : k == M5CaseKind.noSign || rng.nextBool()
            ? M5Protection.feederTrip
            : M5Protection.doBlown;
    cases.add(M5Case(
      kind: k,
      protection: protection,
      place: places[i],
      clues: v,
      notes: {for (final e in v.entries) e.key: e.value.notes[rng.nextInt(e.value.notes.length)]},
    ));
  }
  final trips = [for (final (i, c) in cases.indexed) if (c.protection != M5Protection.none) i];
  return M5CasebookDeal(cases: cases, coworkerCase: trips[rng.nextInt(trips.length)]);
}

/// What spending a clue on a spot did.
enum M5Open { opened, already, spent, closed }

/// The play state (pure logic).
class M5CasebookRun {
  M5CasebookRun(this.deal);
  final M5CasebookDeal deal;

  /// Clues a case allows.
  static const budget = 2;

  int index = 0;
  int slips = 0;
  int caseSlips = 0;
  final Set<M5Spot> opened = {};

  /// After a wrong box every clue of the case is shown.
  var revealedAll = false;

  /// The case is filed right (its reason comes next).
  var caseDone = false;
  final List<String> caught = [];

  int get count => deal.cases.length;
  M5Case get current => deal.cases[index.clamp(0, count - 1)];
  bool get done => index >= count;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get onCoworkerCase => index == deal.coworkerCase;
  int get cluesLeft => revealedAll ? 0 : math.max(0, budget - opened.length);

  /// The spots whose clue the player can read now.
  Set<M5Spot> get seen => revealedAll ? M5Spot.values.toSet() : opened;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Spends a clue on [s].
  M5Open open(M5Spot s) {
    if (done || caseDone) return M5Open.closed;
    if (seen.contains(s)) return M5Open.already;
    if (cluesLeft == 0) return M5Open.spent;
    opened.add(s);
    return M5Open.opened;
  }

  /// The slip can be filed: both clues seen, or every clue shown after a
  /// wrong box (ruling M5-10: no verdict without its evidence).
  bool get canFile => !done && !caseDone && cluesLeft == 0;

  /// Files the slip in [b]. Null = right (the case is done), or nothing
  /// happened because the slip can not be filed yet (check [canFile] first).
  DoMistake? file(M5Box b) {
    if (!canFile) return null;
    final c = current;
    if (b == c.answer) {
      caseDone = true;
      if (caseSlips == 0) _tag(M5CasebookLines.caught(c.kind));
      return null;
    }
    slips++;
    caseSlips++;
    revealedAll = true;
    return M5CasebookMistakes.wrongBox(c.kind, b);
  }

  /// Listened to the coworker's "a trip means a short": a slip.
  DoMistake listened() {
    slips++;
    caseSlips++;
    return M5CasebookMistakes.listened;
  }

  /// Refused him.
  void refused() => _tag(M5CasebookLines.caughtCall);

  void next() {
    index++;
    caseSlips = 0;
    opened.clear();
    revealedAll = false;
    caseDone = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per case: 2 clue gestures ≈ 3500 + lens ~1000 + drag ≈ 2000 + reason ~8200
///     ≈ 14700 × 4 ≈ 58800
/// + the coworker once ≈ 9600 + case lines ≈ 6000                ≈ 74400
/// 85 % ≈ 63000 → 70 s.
const m5CasebookQuickMs = 70000;

@immutable
class M5FaultCasebookPack {
  const M5FaultCasebookPack({required this.id, required this.titleBn, this.quickMs = m5CasebookQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5FaultCasebookPack> m5FaultCasebookPacks = {
  'do_5_6_a': M5FaultCasebookPack(id: 'do_5_6_a', titleBn: M5CasebookLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M5FaultCasebookPage extends StatefulWidget {
  const M5FaultCasebookPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5FaultCasebookPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5FaultCasebookPage> createState() => _M5FaultCasebookPageState();
}

class _M5FaultCasebookPageState extends State<M5FaultCasebookPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CasebookRunPage(
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

class _CasebookRunPage extends ConsumerStatefulWidget {
  const _CasebookRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5FaultCasebookPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CasebookRunPage> createState() => _CasebookRunPageState();
}

class _CasebookRunPageState extends ConsumerState<_CasebookRunPage>
    with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5CasebookRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  /// The clue just opened: its close-up lens for a moment.
  M5Spot? _lens;
  int _lensTok = 0;
  Timer? _lensTimer;

  /// Gesture glyphs on spots (a wrong gesture: that spot; idle: all four).
  Set<M5Spot> _glyphs = const {};
  int _glyphTok = 0;
  Timer? _glyphTimer;
  Timer? _glyphIdle;
  int _glyphShows = 0;

  /// A clue gesture that waits for the coworker (revealed after him).
  M5Spot? _pending;

  /// The pan in progress on the scene (design px).
  Offset? _panFrom;
  Offset? _panTo;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _slipKey = GlobalKey();
  M5CaseGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same).
    _run = M5CasebookRun(m5CasebookDeal(widget.rng));
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _lensTimer?.cancel();
    _glyphTimer?.cancel();
    _glyphIdle?.cancel();
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.caseDone && !struckOut;

  String get _task => _run.cluesLeft > 0 ? M5CasebookLines.askClue : M5CasebookLines.askFile;

  Future<void> _start() async {
    _clock.start();
    _startCase();
  }

  void _startCase() {
    _glyphShows = 0;
    _pending = null; // a held clue never carries into the next case
    setState(() => _wake++);
    if (_run.onCoworkerCase && !coworkerDone) scheduleCoworker();
    unawaited(_sayChain([_task]));
    _armGlyphs();
  }

  // --- the glyphs (how each spot is opened) ----------------------------------
  void _showGlyphs(Set<M5Spot> spots, Duration d) {
    _glyphTimer?.cancel();
    setState(() {
      _glyphs = spots;
      _glyphTok++;
    });
    _glyphTimer = Timer(d, () {
      if (mounted) setState(() => _glyphs = const {});
    });
  }

  /// After 6 s with no touch while the scene waits for a clue, all four
  /// glyphs show together for 2 s (at most 3 times a case; gesture hints off
  /// in widget tests unless a test opts in).
  void _armGlyphs([Duration after = const Duration(seconds: 6)]) {
    _glyphIdle?.cancel();
    if (!GestureHints.enabled || _glyphShows >= 3) return;
    _glyphIdle = Timer(after, () {
      if (!mounted || !_canPlay || _run.cluesLeft == 0) return;
      _glyphShows++;
      _showGlyphs(M5Spot.values.toSet(), const Duration(seconds: 2));
      _armGlyphs(const Duration(seconds: 25));
    });
  }

  void _touched() {
    if (_glyphIdle != null) _armGlyphs();
  }

  // --- hands on -----------------------------------------------------------------
  void _gesture(M5Gesture g, Offset p, Offset global) {
    // He is talking (beat 1): going on with a clue gesture refuses him (the
    // kit's "going on working"); the clue he held opens after he goes.
    if (coworkerOpen && !coworkerChoiceUp) {
      final s = _geoNow?.spotAt(p);
      if (!_intro && !_ended && _card == null && s != null && m5GestureFor(s) == g) {
        unawaited(answerCoworker(true, global, direct: true));
      }
      return;
    }
    if (!_canPlay) return;
    final geo = _geoNow;
    final spot = geo?.spotAt(p);
    if (spot == null) {
      _hints.missTap();
      return;
    }
    if (m5GestureFor(spot) != g) {
      // Not how this spot opens: show only its glyph.
      _tick('sounds/intro/tick.ogg', 0.35);
      _showGlyphs({spot}, const Duration(milliseconds: 1600));
      return;
    }
    switch (_run.seen.contains(spot) ? M5Open.already : (_run.cluesLeft == 0 ? M5Open.spent : M5Open.opened)) {
      case M5Open.already:
        _tick('sounds/intro/tick.ogg', 0.35);
        _showLens(spot);
        return;
      case M5Open.spent:
        _tick('sounds/intro/impact_metal.ogg', 0.3);
        unawaited(_sayChain([M5CasebookLines.cluesGone]));
        return;
      default:
        break;
    }
    // His case: the first clue waits for him.
    if (_run.onCoworkerCase && holdForCoworker()) {
      _pending = spot;
      return;
    }
    _open(spot);
  }

  void _open(M5Spot spot, {bool say = true}) {
    if (_run.open(spot) != M5Open.opened) return;
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    _showLens(spot);
    if (say && _run.cluesLeft == 0) unawaited(_sayChain([M5CasebookLines.askFile]));
    _armGlyphs();
  }

  void _showLens(M5Spot spot) {
    _lensTimer?.cancel();
    setState(() {
      _lens = spot;
      _lensTok++;
      _wake++;
    });
    _lensTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _lens = null);
    });
  }

  void _panDown(DragDownDetails d) {
    _panFrom = d.localPosition;
    _panTo = d.localPosition;
  }

  void _panEnd(Offset global) {
    final from = _panFrom;
    final to = _panTo;
    _panFrom = null;
    _panTo = null;
    if (from == null || to == null) return;
    final d = to - from;
    if (d.dy < -32 && d.dy.abs() > d.dx.abs()) {
      _gesture(M5Gesture.swipeUp, from, global);
    } else if (d.dx.abs() >= 50 && d.dx.abs() > d.dy.abs()) {
      _gesture(M5Gesture.sweep, from, global);
    } else {
      // A short or downward drag: not a gesture any spot takes.
      final s = _geoNow?.spotAt(from);
      if (s != null && _canPlay) {
        _showGlyphs({s}, const Duration(milliseconds: 1600));
      } else {
        _hints.missTap();
      }
    }
  }

  /// The slip dropped in [b].
  void _file(M5Box b, Offset origin) {
    // No verdict without both clues (the slip does not drag before; this
    // guards a drop anyway).
    if (!_canPlay || !_run.canFile) return;
    // His case: filing waits for him too (a safety net: he comes at the
    // first clue, and filing needs both).
    if (_run.onCoworkerCase && holdForCoworker()) return;
    final c = _run.current;
    final m = _run.file(b);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      unawaited(_slip(m));
      return;
    }
    _hush();
    _glyphIdle?.cancel();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(_run.caseSlips == 0 ? 20 : 15);
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5CasebookLines.whyRight(c.kind), M5CasebookLines.myths, widget.rng),
      question: M5CasebookLines.whyQuestion(c.kind),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  /// The slip touched while it is locked (clues still to see): it stays put;
  /// the guide and the four gesture glyphs point at the clues.
  void _slipLocked() {
    if (!_canPlay || _run.canFile) return;
    _tick('sounds/intro/tick.ogg', 0.35);
    _showGlyphs({
      for (final s in M5Spot.values)
        if (!_run.seen.contains(s)) s,
    }, const Duration(milliseconds: 1600));
    unawaited(_sayChain([M5CasebookLines.clueFirst]));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCase();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5CasebookLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  /// He comes only on his trip case, at its first clue gesture (or when that
  /// case's slip is filed first): until then "not yet"; once a clue of the
  /// case is open (or it is filed) his moment has passed.
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.onCoworkerCase || _run.caseDone || _run.opened.isNotEmpty || _run.revealedAll) return null;
    return false;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened: a slip; the clue he held opens after the card.
      final m = _run.listened();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.refused();
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    // Speak and open only while the case still waits for clues (play is on in
    // this window: no stale task over a card, the reason deck or the table).
    if (!mounted || _ended || _run.caseDone || reasonOpen || tableBusy || _card != null) return;
    _openPending();
    unawaited(_sayChain([M5CasebookLines.callHeld, _task], mood: GuideMood.glad));
  }

  void _openPending() {
    final s = _pending;
    _pending = null;
    if (s != null) _open(s, say: false);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5CasebookLines.tapWhy[_nudgeN++ % M5CasebookLines.tapWhy.length]
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
    _glyphIdle?.cancel();
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
    _glyphIdle?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('casebook/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same case goes on: every clue is open after a wrong box; a clue
    // held for the coworker opens now.
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    if (_pending != null) {
      _openPending();
      unawaited(_sayChain([_task]));
    } else {
      unawaited(_sayChain([_run.revealedAll ? M5CasebookLines.revealed : _task]));
    }
    _armGlyphs();
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
    _glyphIdle?.cancel();
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
    await _say(!_run.passed ? M5CasebookLines.fail : (_quickBonus ? M5CasebookLines.quick : M5CasebookLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    return LinemanMode.idle;
  }

  /// The gesture hand: while clues are left, a sweep over all four spots
  /// (left to right, the same in every case); with none left, the slip
  /// nudged toward the notebook's spine — never toward a box.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_run.cluesLeft > 0) {
      final spots = [...M5Spot.values]..sort((a, b) => geo.hit(a).center.dx.compareTo(geo.hit(b).center.dx));
      return HintSpec.sweep([for (final s in spots) geo.hit(s)], space: HintSpace.scene);
    }
    return HintSpec.dragFrom(_slipKey, toward: const Offset(1, 0), travel: 72);
  }

  static const _glyphIcons = {
    M5Gesture.tap: Icons.touch_app,
    M5Gesture.swipeUp: Icons.swipe_up,
    M5Gesture.sweep: Icons.swipe,
    M5Gesture.hold: Icons.pan_tool,
  };

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5CaseGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final lens = _lens;
    final c = _run.current;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(
          child: CustomPaint(painter: M5CasebookPainter(geo: geo, light: _run.index, opened: Set.of(_run.seen))),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5CasebookLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _gesture(M5Gesture.tap, d.localPosition, d.globalPosition),
            onLongPressStart: (d) => _gesture(M5Gesture.hold, d.localPosition, d.globalPosition),
            onPanDown: _panDown,
            onPanUpdate: (d) => _panTo = d.localPosition,
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: () {
              _panFrom = null;
              _panTo = null;
            },
          ),
        ),
      ),
      // The close-up of the clue just opened (or looked at again).
      if (lens != null)
        Positioned.fromRect(
          key: ValueKey('lens-$_lensTok'),
          rect: geo.lens(lens),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * v, child: child)),
              child: RepaintBoundary(child: CustomPaint(painter: M5LensPainter(look: c.clues[lens]!.look))),
            ),
          ),
        ),
      // How a spot opens (its gesture glyph).
      for (final s in _glyphs)
        Positioned.fromRect(
          key: ValueKey('glyph-${s.name}-$_glyphTok'),
          rect: Rect.fromCenter(center: geo.hit(s).center, width: 46, height: 46),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 220),
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xE60B1324),
                  border: Border.all(color: SlmColors.gold300, width: 2),
                ),
                child: Icon(_glyphIcons[m5GestureFor(s)], size: 26, color: SlmColors.gold300),
              ),
            ),
          ),
        ),
      // The next case: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('case-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.6, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  Widget _notebook(EdgeInsets pad, bool canFile) {
    final c = _run.current;
    final notes = [
      for (final s in M5Spot.values)
        if (_run.seen.contains(s)) (s, c.notes[s]!),
    ];
    final slip = _SlipCard(
      caseLine: M5CasebookLines.caseNo(_run.index, _run.count),
      place: c.place,
      protection: M5CasebookLines.protection(c.protection),
      cluesLeft: _run.cluesLeft,
    );
    // Hands on, but clues still to see: the slip stays, the boxes wait.
    final locked = canFile && !_run.canFile;
    return Positioned(
      key: ValueKey('notebook-${_run.index}'),
      left: 8,
      right: 8,
      bottom: pad.bottom + 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6EED9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8A6A2E), width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Locked until both clues are seen: a touch then points at
                  // the clues (no recognizer at all once it can be dragged).
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: locked ? _slipLocked : null,
                    onPanStart: locked ? (_) => _slipLocked() : null,
                    child: Draggable<int>(
                      key: const ValueKey('case-slip'),
                      data: _run.index,
                      maxSimultaneousDrags: canFile && _run.canFile ? 1 : 0,
                      onDragStarted: () => _tick('sounds/learn/card_deal_a.ogg', 0.4),
                      feedback: Material(color: Colors.transparent, child: Transform.rotate(angle: -0.05, child: slip)),
                      childWhenDragging: Opacity(opacity: 0.3, child: slip),
                      child: KeyedSubtree(key: _slipKey, child: slip),
                    ),
                  ),
                  // The spine.
                  Container(width: 3, margin: const EdgeInsets.symmetric(horizontal: 7), color: const Color(0xFFB89A5E)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(M5CasebookLines.notebook,
                            style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF6B4E1E))),
                        const SizedBox(height: 3),
                        for (final (s, n) in notes)
                          Padding(
                            key: ValueKey('note-${s.name}'),
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_spotIcon(s), size: 14, color: const Color(0xFF6B4E1E)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(n,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: bangla(
                                          fontSize: notes.length > 2 ? 10.5 : 11.5,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                          color: const Color(0xFF2B2111))),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final b in M5Box.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: DragTarget<int>(
                        onWillAcceptWithDetails: (d) => d.data == _run.index && _canPlay,
                        onAcceptWithDetails: (d) => _file(b, d.offset + const Offset(60, 40)),
                        builder: (context, cand, _) =>
                            _BoxTile(key: ValueKey('box-${b.name}'), label: M5CasebookLines.boxLabel(b), hot: cand.isNotEmpty, dim: locked),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static IconData _spotIcon(M5Spot s) => switch (s) {
        M5Spot.person => Icons.record_voice_over_rounded,
        M5Spot.pole => Icons.electrical_services_rounded,
        M5Spot.ground => Icons.grass_rounded,
        M5Spot.pump => Icons.water_drop_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.caseDone && !deckUp && !coworkerOpen && _card == null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _touched(),
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
                labels: [for (var i = 0; i < _run.count; i++) M5CasebookLines.progress(i)],
                done: {for (var i = 0; i < math.min(_run.index, _run.count); i++) i},
                current: _run.done ? null : _run.index,
                quiet: quiet,
              ),
              layers: (context, m) => _scene(m),
              hint: _hint,
              hintWaiting: handsOn && !tableBusy,
              hintKey: '${_run.index}/${_run.cluesLeft}',
              hintController: _hints,
              overlays: [
                ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
                if (playing && !deckUp && !_run.done) _notebook(pad, handsOn),
                if (deckUp)
                  Positioned(
                    key: const ValueKey('hud-deck'),
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: pad.bottom),
                      child: reasonOpen
                          ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                          : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                    ),
                  ),
                if (playing && _card == null)
                  cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 200), onLeft: coworkerFromRight),
                ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
                if (_card != null)
                  MistakeCard(
                    key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
                    mistake: _card!,
                    tone: MistakeTone.slip,
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
                if (_intro)
                  GuideIntro(
                    key: const ValueKey('intro'),
                    line: M5CasebookLines.intro,
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
      ),
    );
  }
}

// ============================================================================
// Pieces
// ============================================================================

/// The case slip: the case, the place, the protection state, the clue pips.
class _SlipCard extends StatelessWidget {
  const _SlipCard({required this.caseLine, required this.place, required this.protection, required this.cluesLeft});
  final String caseLine;
  final String place;
  final String protection;
  final int cluesLeft;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2B2111);
    return Container(
      width: 126,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB89A5E), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caseLine, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF8A6A2E))),
          Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 3),
          Text(protection, maxLines: 2, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15, color: ink)),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(M5CasebookLines.clues, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF8A6A2E))),
              const SizedBox(width: 5),
              for (var i = 0; i < M5CasebookRun.budget; i++)
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < cluesLeft ? const Color(0xFFC48A2E) : Colors.transparent,
                    border: Border.all(color: const Color(0xFFC48A2E), width: 1.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A box of the notebook (a drop target). [hot] while the slip is over it;
/// [dim] while the slip is locked (clues still to see).
class _BoxTile extends StatelessWidget {
  const _BoxTile({super.key, required this.label, required this.hot, this.dim = false});
  final String label;
  final bool hot;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: AnimatedOpacity(
        opacity: dim ? 0.55 : 1,
        duration: const Duration(milliseconds: 240),
        child: Container(
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: hot ? const Color(0xFFFFF1C9) : const Color(0xFFEFE3C4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hot ? const Color(0xFFC48A2E) : const Color(0xFF9C8256), width: hot ? 2.4 : 1.4),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, height: 1.15, color: const Color(0xFF2B2111))),
        ),
      ),
    );
  }
}
