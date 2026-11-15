import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'm6_trip_log_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_trip_log_world.dart' show M6Face, M6Room, M6TripGeo;

// Lesson 6.2 "সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা", কাজ 1 "ট্রিপের খাতা"
// (pack do_6_2_a, rung 6.2/do/0, engineType m6_trip_log). Night duty at a
// distribution substation; the alarm: a feeder has tripped.
//
//  1. The breaker room (tap the glass door). 'কোন কোন ব্রেকার খোলা?' — tap
//     every panel read as open to chalk-mark it (tap again to rub it off),
//     then 'দেখা শেষ' (live from the start). The lamps are the same size and
//     glow alike: red ON, green OFF (6.2 point 3). A red panel marked, or a
//     green one left unmarked, is a slip. Some plays deal a second open
//     breaker, planned OFF (in about half of those with a padlock + tag, in
//     the rest with nothing on the handle), so the relay must be read to know
//     which one tripped. ◆ → 'সবুজ বাতি দেখে কী বুঝলেন?'.
//  2. Back to the control room (coworker variant c may hold the door). Tap a
//     relay case: the lens shows its face — the drop flags (R/Y/B) and the
//     fault window; from across the room every case looks alike. The trip
//     register slides up: ফিডার stamp, ফেজ R·Y·B ticks, ফল্ট ওভারলোড ·
//     শর্ট সার্কিট, 'খাতায় লিখি' (pro tip 3). A feeder whose relay shows no
//     flag stamped as the trip, wrong phases or the wrong fault type = slip
//     (R38). ◆ → 'রিলের খবর কেন লিখে রাখলেন?', or in a two-open play (where
//     the relay told the two greens apart) at times 'কোন ব্রেকার ট্রিপ, তা
//     রিলেতে কেন দেখলেন?' (variant b holds 'খাতায় লিখি').
//  3. The radio: the crew 'ফল্টের জায়গা পেয়েছি। ব্রেকার ট্রিপ, সবুজ জ্বলছে —
//     উঠে কাজ ধরি?'; the guide 'কী বলবেন?' and three reply cards: one right
//     (both ends isolated, proved dead with the tester, earthed — live pro
//     tip 1, ruling X1) and two deadly. Every card reads as a procedure in
//     the same register, each wrong one with one deadly gap (R1: the trip /
//     green lamp as the only check; R2: one end isolated, lock + tag only, or
//     proved dead but not earthed — X1), so the rule decides, not the tone.
//     Variant a
//     speaks first; the reply waits for him. A deadly reply: the room freezes
//     grey and the back-feed hits the crew member in colour; right: the crew
//     confirms → ◆ → 'সবুজ দেখেও কেন উঠতে দিলেন না?' → the pass panel.
//
// The coworker (once a play, ruling X2/B1): (a) radio — the 6.2 myth word for
// word + 'উঠে পড়ুক!' (deadly: R1); (b) register — 'reset it and switch on'
// (slip R34, the breaker re-trips with a bang); (c) breaker-room exit — 'let's
// sit here, it's cool' (slip, pro tip 4; a bang from a neighbour panel).
// Three slips strike out. Counters, spring flags and the TRIP CKT HEALTHY
// lamp are shown, never scored.
//
// Built on the shared kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m6_trip_log_world.dart), corner guide, ◆ on the table → "কেন …?"
// (the cards at once), the two-beat coworker (the next decisive control waits
// for him: holdForCoworker), gesture hands — a tap ripple on a door (the one
// way on), sweeps over every panel / relay / register cell alike, never the
// answer. All new Bangla is DRAFT wording for the owner (M6-12).

// ============================================================================
// Content
// ============================================================================

/// Where the play is.
enum M6TripStage { toBreakers, panels, toControl, log, radio, done }

/// The relay's fault window (lesson 6.2 point 1: ওভারলোড বা শর্ট সার্কিট).
enum M6Fault { overload, short }

/// The coworker's push: (a) on the radio, (b) at the register, (c) at the
/// breaker-room door.
enum M6Push { radio, log, room }

/// What a reason asks about.
enum M6WhyTopic { green, relay, note, climb }

abstract final class M6TripLogLines {
  // DRAFT wording — owner (M6-12): every new line in this class.
  static const title = 'ট্রিপের খাতা';
  static const intro = 'রাতের ডিউটিতে অ্যালার্ম! একটা ফিডার ট্রিপ করেছে — প্যানেল পড়ে খাতা লিখুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askDoor = 'আগে ব্রেকার রুমে চলুন।';
  static const askPanels = 'কোন কোন ব্রেকার খোলা? দাগ দিয়ে দেখা শেষ করুন।';
  static const askBack = 'এবার কন্ট্রোল রুমে ফিরুন।';
  static const askRelay = 'কোন ফিডার ট্রিপ করেছে? রিলে দেখে খাতায় লিখুন।';
  static const askReply = 'কী বলবেন?';
  static const tasks = [askDoor, askPanels, askBack, askRelay, askReply];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const panelsFirst = 'আগে প্যানেলগুলো দেখে শেষ করুন।';
  static const fillAll = 'খাতার তিনটে ঘরই ভরুন — ফিডার, ফেজ, ফল্ট।';

  static String ask(M6TripStage s) => switch (s) {
        M6TripStage.toBreakers => askDoor,
        M6TripStage.panels => askPanels,
        M6TripStage.toControl => askBack,
        M6TripStage.log => askRelay,
        M6TripStage.radio || M6TripStage.done => askReply,
      };

  // On screen (labels a worker reads, the register's own words).
  static const sceneLabel = 'সাবস্টেশন';
  static const lookDone = 'দেখা শেষ';
  static const register = 'ট্রিপের খাতা';
  static const rowFeeder = 'ফিডার';
  static const rowPhase = 'ফেজ';
  static const rowFault = 'ফল্ট';
  static const write = 'খাতায় লিখি';
  static const phases = ['R', 'Y', 'B'];

  /// The fault chips (within 1.3× of each other) and the relay window.
  static String faultChip(M6Fault f) => switch (f) {
        M6Fault.overload => 'ওভারলোড ফল্ট',
        M6Fault.short => 'শর্ট সার্কিট',
      };
  static String faultWindow(M6Fault f) => switch (f) {
        M6Fault.overload => 'ওভারলোড',
        M6Fault.short => 'শর্ট সার্কিট',
      };

  /// Feeder names (plates, 5–6 letters each so the stamps stay alike).
  static const feederNames = ['বাজার', 'কলোনি', 'স্টেশন', 'নদীঘাট', 'হাটতলা', 'স্কুল', 'মন্দির'];

  static const rounds = ['প্যানেল', 'খাতা', 'রেডিও'];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. 45–51 letters.
  static const whyQ = <M6WhyTopic, String>{
    M6WhyTopic.green: 'সবুজ বাতি দেখে কী বুঝলেন?',
    M6WhyTopic.relay: 'কোন ব্রেকার ট্রিপ, তা রিলেতে কেন দেখলেন?',
    M6WhyTopic.note: 'রিলের খবর কেন লিখে রাখলেন?',
    M6WhyTopic.climb: 'সবুজ দেখেও কেন উঠতে দিলেন না?',
  };
  static const whyRight = <M6WhyTopic, List<String>>{
    M6WhyTopic.green: ['সবুজ জ্বলছে মানে ব্রেকারটা খোলা বা ট্রিপ অবস্থায়', 'সবুজ বাতি বলছে ব্রেকার এখন খোলা, লাল হলে চালু'],
    M6WhyTopic.relay: ['ব্রেকার নিজে ভাবে না — রিলেই ফল্ট ধরে ট্রিপ করায়', 'রিলে হলো মস্তিষ্ক, ব্রেকার শুধু তার হুকুমের পেশী'],
    M6WhyTopic.note: ['কোন ফেজে, কী ধরনের ফল্ট — জানলে ফল্ট খোঁজা সহজ', 'রিলের ফেজ আর ফল্টের ধরনই লাইনে ফল্ট খুঁজতে লাগে'],
    M6WhyTopic.climb: ['ব্যাক-ফিডিং বা ইন্ডুসড ভোল্টেজ তখনও থাকতে পারে', 'সবুজ মানে শুধু ব্রেকার খোলা — লাইন তাতে নিরাপদ নয়'],
  };
  static const myths = [
    'সবুজ বাতি মানেই লাইন পুরো ডেড, আর কোনো ভয় নেই',
    'ব্রেকার ট্রিপ করলে লাইনে আর কোনো ভোল্টেজ থাকে না',
    'যেকোনো সুইচই তো সার্কিট ব্রেকারের কাজ করতে পারে',
    'খাতা লেখা শুধু অফিসের নিয়ম, মাঠের কাজে লাগে না',
    'রিসেট করে দিলেই ফল্ট নিজে থেকেই সরে যায়, ভাবনা নেই',
    'লাল বাতি মানে ব্রেকার খোলা, আর সবুজ মানে চালু আছে',
    'ব্রেকার নিজেই সব বোঝে, রিলে দেখার কোনো দরকার নেই',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The radio reply (1 right + 2 deadly dealt; 47–55 letters). The right one
  // names the tester (live pro tip 1, ruling X1). Every wrong card is a
  // procedure in the same calm register with one deadly gap — no reckless
  // cue words — so only the rule tells them apart. Never 'earth without the
  // tester' as a decoy: under X1 that is only a slip.
  static const replyRight = [
    'দুই প্রান্ত খুলে, টেস্টারে ডেড দেখে, আর্থ দিয়ে তবে কাজ',
    'আগে দুই প্রান্তে আইসোলেটর, টেস্টারে 0 V, তারপর আর্থ',
  ];

  /// R1: the trip / green lamp (with the relay) as the only check.
  static const replyGreen = [
    'ব্রেকার ট্রিপ দেখে, সবুজ বাতি মিলিয়ে, তারপর উঠে কাজ',
    'রিলে মিলিয়ে, সবুজ বাতি দেখে, ব্রেকার খোলা জেনে তবে কাজ',
    'রিলের ফ্ল্যাগ আর সবুজ বাতি দুটোই মিলিয়ে, তবে উঠে কাজ',
  ];

  /// R2: proved dead but not earthed (X1: deadly), one end isolated, or
  /// lock + tag only.
  static const replyHalf = [
    'দুই প্রান্ত খুলে, টেস্টারে ডেড দেখে, তারপর উঠে কাজ',
    'আগে এক প্রান্তে আইসোলেটর, টেস্টারে 0 V, তারপর আর্থ',
    'ব্রেকারে লক-ট্যাগ দিয়ে, সবুজ দেখে তবে কাজ শুরু',
  ];
  static List<String> get replyWrong => [...replyGreen, ...replyHalf];

  // The crew on the radio (radio voice; two wordings dealt).
  static const crewAsk = [
    'ফল্টের জায়গা পেয়েছি। ব্রেকার ট্রিপ, সবুজ জ্বলছে — উঠে কাজ ধরি?',
    'ফল্টটা খুঁজে পেয়েছি। সাবস্টেশনে তো সবুজ জ্বলছে — পোলে উঠে পড়ি?',
  ];
  static const crewOk = 'ঠিক আছে — দুই প্রান্ত খুলে, টেস্টারে দেখে, আর্থিং দিয়ে তবে উঠছি।';

  // The careless coworker (one push a play).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';

  /// (a) The 6.2 myth word for word + his push (deadly: R1).
  static const coworkerRadio = CoworkerScript(
    line: 'সার্কিট ব্রেকার ট্রিপ করেছে মানে লাইনটি সম্পূর্ণ বন্ধ। এতে কোনো ভোল্টেজ নেই। উঠে পড়ুক!',
    exitLine: coworkerExit,
    right: ['না, আগে আইসোলেট, টেস্ট, আর্থ', 'না, সবুজ মানেই লাইন ডেড নয়', 'না, ব্যাক-ফিডিং থাকতে পারে'],
    wrong: [
      'ঠিক, ব্রেকার তো ট্রিপ করেছে',
      'হ্যাঁ, সবুজ জ্বলছে, উঠে পড়ুক',
      'আচ্ছা, লাইনে কিছু নেই, উঠুক',
      'ঠিক আছে, তাড়াতাড়ি কাজ ধরুক',
      'হ্যাঁ, ভোল্টেজ নেই, ভয় নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে লোক উঠে পড়ুক। কী করবেন?', 'সবুজ দেখেই লোক তুলবেন?'],
  );

  /// (b) At the register (slip: R34).
  static const coworkerLog = CoworkerScript(
    line: 'লিখে কী হবে? ব্রেকার তো রিসেট হয় — আবার চালু করে দাও!',
    exitLine: coworkerExit,
    right: ['না, আগে রিলের খবর খাতায় লিখব', 'না, ফল্ট না খুঁজে চালু নয়', 'না, চালু করলে আবার ট্রিপ করবে'],
    wrong: [
      'ঠিক, রিসেট করে চালু করে দিই',
      'হ্যাঁ, লেখার ঝামেলা কে করে',
      'আচ্ছা, একবার চালু করে দেখি',
      'ঠিক আছে, খাতা নাহয় পরে লিখব',
      'হ্যাঁ, ফল্ট নিজেই সরে যাবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে না লিখে চালু করতে। কী করবেন?', 'ফল্ট না খুঁজেই চালু করবেন?'],
  );

  /// (c) At the breaker-room door (slip: pro tip 4).
  static const coworkerRoom = CoworkerScript(
    line: 'ব্রেকার রুমেই একটু বসি, এখানে ঠান্ডা।',
    exitLine: coworkerExit,
    right: ['না, এখানে অকারণে থাকা নয়', 'না, বিস্ফোরণের মতো শব্দ হতে পারে', 'না, কাজ শেষ, কন্ট্রোল রুমে যাই'],
    wrong: [
      'ঠিক, একটু বসে জিরিয়ে নিই',
      'হ্যাঁ, এখানে বেশ ঠান্ডা লাগছে',
      'আচ্ছা, দু-মিনিট বসলে কী হয়',
      'ঠিক আছে, এখানেই একটু থাকি',
      'হ্যাঁ, পরে কন্ট্রোল রুমে যাব',
    ],
    asks: ['কী করবেন?', 'ও বলছে এখানেই বসতে। কী করবেন?', 'ব্রেকার রুমে বসে থাকবেন?'],
  );

  static CoworkerScript coworker(M6Push p) => switch (p) {
        M6Push.radio => coworkerRadio,
        M6Push.log => coworkerLog,
        M6Push.room => coworkerRoom,
      };
  static const allCoworkers = [coworkerRadio, coworkerLog, coworkerRoom];

  static String callHeld(M6Push p) => switch (p) {
        M6Push.radio => 'একদম ঠিক! সবুজ মানেই নিরাপদ নয়।',
        M6Push.log => 'ঠিক! আগে রিলের খবর খাতায়।',
        M6Push.room => 'ঠিক! ব্রেকার রুমে অকারণে থাকা নয়।',
      };

  static const allSet = 'বাতি দেখলেন, রিলের খবর লিখলেন, ক্রুকে নিরাপদ রাখলেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — বাতি, রিলে, খাতা, তারপর নিরাপদ নির্দেশ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtGreen = 'সবুজ বাতি মানে ব্রেকার খোলা';
  static const caughtLog = 'রিলের ফেজ আর ফল্ট খাতায়';
  static const caughtSafe = 'সবুজ দেখেও আগে আইসোলেট, টেস্ট, আর্থ';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// His lines with no clip yet (the director records them with
  /// tool/rival_clip.py). (a) is the 6.2 myth word for word + 'উঠে পড়ুক!'.
  static const newRivalLines = [
    'সার্কিট ব্রেকার ট্রিপ করেছে মানে লাইনটি সম্পূর্ণ বন্ধ। এতে কোনো ভোল্টেজ নেই। উঠে পড়ুক!',
    'লিখে কী হবে? ব্রেকার তো রিসেট হয় — আবার চালু করে দাও!',
    'ব্রেকার রুমেই একটু বসি, এখানে ঠান্ডা।',
  ];

  /// The crew's radio lines (radio voice).
  static const newRadioLines = [...crewAsk, crewOk];

  /// The guide's new lines (Subrata voice; the mistake cards' first reading
  /// is listed with the mistakes).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        panelsFirst,
        fillAll,
        ...whyQ.values,
        for (final cw in allCoworkers) ...cw.asks.where((a) => a != 'কী করবেন?'),
        for (final p in M6Push.values) callHeld(p),
        allSet,
        fail,
      ];
}

abstract final class M6TripLogMistakes {
  // DRAFT wording — owner (M6-12).
  static const _dir = 'assets/game/art/m6_trip_log';

  /// A red (ON) panel marked open (6.2 point 3).
  static const markRed = DoMistake(
    key: '6.2/m6_trip_log/mark-red',
    textBn: 'লাল বাতি মানে ব্রেকার চালু (ON)। খোলা ব্রেকার চেনা যায় সবুজ বাতিতে — লাল প্যানেলে দাগ নয়।',
    art: '$_dir/lamps.svg',
    lessonPoint: 2,
  );

  /// A green (OFF) panel left unmarked (6.2 point 3).
  static const missGreen = DoMistake(
    key: '6.2/m6_trip_log/miss-green',
    textBn: 'সবুজ বাতি জ্বলা মানে ব্রেকার খোলা বা ট্রিপ। প্রতিটা সবুজ প্যানেলেই দাগ দিন — লক-ট্যাগ দেওয়াটাও খোলা।',
    art: '$_dir/lamps.svg',
    lessonPoint: 2,
  );

  /// A feeder whose relay shows no flag logged as the trip (6.2 point 1: the
  /// relay is the brain; R38).
  static const noFlag = DoMistake(
    key: '6.2/m6_trip_log/no-flag',
    textBn: 'যে রিলেতে কোনো ফ্ল্যাগ পড়েনি, সেই ফিডার ট্রিপ করেনি। ব্রেকার নিজে ভাবে না — কোনটা ট্রিপ, তা রিলের ফ্ল্যাগ বলে।',
    art: '$_dir/relay_flags.svg',
    lessonPoint: 0,
  );

  /// Wrong phases logged (pro tip 3; R38): no lesson point (a pro tip).
  static const wrongPhase = DoMistake(
    key: '6.2/m6_trip_log/wrong-phase',
    textBn: 'রিলের যে যে ফেজে ফ্ল্যাগ পড়েছে, ঠিক সেই ফেজগুলোই খাতায় লিখুন — ফল্ট খুঁজতে এটাই লাগে।',
    art: '$_dir/log.svg',
  );

  /// The wrong fault type logged (pro tip 3; R38).
  static const wrongType = DoMistake(
    key: '6.2/m6_trip_log/wrong-type',
    textBn: 'রিলের জানালা যে ফল্ট দেখাচ্ছে — ওভারলোড না শর্ট সার্কিট — খাতায় ঠিক সেটাই লিখুন।',
    art: '$_dir/log.svg',
  );

  /// Stayed in the breaker room on his word (pro tip 4).
  static const stayRoom = DoMistake(
    key: '6.2/m6_trip_log/stay-room',
    textBn: 'ব্রেকার রুমে অকারণে থাকা নয় — বড় ফল্ট কাটার সময় ব্রেকারে বিস্ফোরণের মতো প্রচণ্ড শব্দ হতে পারে।',
    art: '$_dir/breaker_room.svg',
  );

  /// Reset before the fault is found, on his word (mission briefing:
  /// 'সমস্যা সমাধান হওয়ার পর'; R34, slip by M6-5).
  static const resetEarly = DoMistake(
    key: '6.2/m6_trip_log/reset-early',
    textBn: 'ফল্ট না খুঁজে ব্রেকার আবার চালু নয় — ফল্ট থাকলে আবার ট্রিপ করবে। আগে রিলের খবর লিখে ফল্ট খুঁজুন।',
    art: '$_dir/reset.svg',
  );

  /// R1 (deadly): the crew told to work on the trip / green lamp alone, or
  /// the 6.2 myth listened to (pro tip 1 + myth reality).
  static const greenAlone = DoMistake(
    key: '6.2/m6_trip_log/green-alone',
    textBn: 'ব্রেকার ট্রিপ বা সবুজ বাতি মানেই লাইন ডেড নয় — ব্যাক-ফিডিং বা ইন্ডুসড ভোল্টেজ থাকতে পারে। দুই প্রান্তে আইসোলেটর খুলে, টেস্টারে ডেড প্রমাণ করে, আর্থিং দিয়ে তবে কাজ!',
    art: '$_dir/backfeed.svg',
    deadly: true,
    lessonPoint: 2,
  );

  /// R2 (deadly): one end isolated, lock + tag only, or proved dead but not
  /// earthed (pro tip 1; ruling X1: work after the 0 V without the earth).
  static const halfIsolation = DoMistake(
    key: '6.2/m6_trip_log/half-isolation',
    textBn: 'এক প্রান্ত খোলা, শুধু লক-ট্যাগ, বা আর্থ ছাড়া কাজ — কোনোটাই যথেষ্ট নয়। দুই প্রান্তে আইসোলেটর খুলে, টেস্টারে ডেড প্রমাণ করে, আর্থিং দিয়ে তবেই কাজ!',
    art: '$_dir/one_end.svg',
    deadly: true,
  );

  /// A wrong reply card is the deadly act it orders.
  static DoMistake reply(String card) => M6TripLogLines.replyHalf.contains(card) ? halfIsolation : greenAlone;

  static DoMistake push(M6Push p) => switch (p) {
        M6Push.radio => greenAlone,
        M6Push.log => resetEarly,
        M6Push.room => stayRoom,
      };

  static const List<DoMistake> all = [markRed, missGreen, noFlag, wrongPhase, wrongType, stayRoom, resetEarly, greenAlone, halfIsolation];

  /// The level's deadly keys (the catalog's deadlyRules).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

@immutable
class M6TripDeal {
  const M6TripDeal({
    required this.names,
    required this.faces,
    required this.tripped,
    required this.planned,
    required this.flags,
    required this.fault,
    required this.counters,
    required this.push,
    required this.crewAsk,
    required this.logWhy,
    this.tagged = true,
  });

  /// Feeder plates left to right (3–4).
  final List<String> names;
  final List<M6Face> faces;

  /// The feeder that tripped, and a second breaker planned OFF (−1 none).
  final int tripped;
  final int planned;

  /// The planned-OFF breaker shows its padlock + red tag. Off in about half
  /// of the two-open plays (nothing on the handle), so the handle does not
  /// always name the feeder that did not trip and the relay must be read.
  final bool tagged;

  /// The tripped relay's dropped flags (0 R, 1 Y, 2 B) and its fault window.
  final Set<int> flags;
  final M6Fault fault;

  /// Operation counters (shown, not scored).
  final List<int> counters;
  final M6Push push;

  /// Which crew wording asks on the radio.
  final int crewAsk;

  /// The register's reason ([M6WhyTopic.relay] or [M6WhyTopic.note]).
  final M6WhyTopic logWhy;

  int get n => names.length;
  bool isOpen(int i) => i == tripped || i == planned;
}

M6TripDeal m6TripDeal(math.Random rng) {
  final n = 3 + rng.nextInt(2);
  final names = ([...M6TripLogLines.feederNames]..shuffle(rng)).take(n).toList();
  final faces = [for (var i = 0; i < n; i++) rng.nextBool() ? M6Face.vcb : M6Face.ocb];
  final tripped = rng.nextInt(n);
  var planned = -1;
  var tagged = true;
  if (rng.nextDouble() < 0.45) {
    planned = (tripped + 1 + rng.nextInt(n - 1)) % n;
    tagged = rng.nextBool();
  }
  final count = 1 + rng.nextInt(3);
  final flags = ([0, 1, 2]..shuffle(rng)).take(count).toSet();
  final fault = rng.nextBool() ? M6Fault.overload : M6Fault.short;
  final counters = [for (var i = 0; i < n; i++) 120 + rng.nextInt(2880)];
  final r = rng.nextDouble();
  final push = r < 0.5 ? M6Push.radio : (r < 0.75 ? M6Push.log : M6Push.room);
  return M6TripDeal(
    names: names,
    faces: faces,
    tripped: tripped,
    planned: planned,
    tagged: tagged,
    flags: flags,
    fault: fault,
    counters: counters,
    push: push,
    crewAsk: rng.nextInt(M6TripLogLines.crewAsk.length),
    // 'Why the relay?' fits only where the relay told two greens apart.
    logWhy: planned >= 0 && rng.nextBool() ? M6WhyTopic.relay : M6WhyTopic.note,
  );
}

/// The panel the room-push bang comes from: the closed (red, in service)
/// panel nearest the tripped one — a breaker that can still cut a fault,
/// never the open (tripped or planned-OFF) ones. With 3–4 panels and at most
/// two open there is always one.
int m6BangPanel(M6TripDeal d) {
  for (var k = 1; k < d.n; k++) {
    for (final i in [d.tripped + k, d.tripped - k]) {
      if (i >= 0 && i < d.n && !d.isOpen(i)) return i;
    }
  }
  return (d.tripped + 1) % d.n;
}

/// The play state (pure logic).
class M6TripRun {
  M6TripRun(this.deal);
  final M6TripDeal deal;

  var stage = M6TripStage.toBreakers;
  int slips = 0;
  int stageSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The stage's right move is in (its reason comes next).
  var roundDone = false;

  /// The panels chalk-marked open.
  final Set<int> marks = {};

  /// The relays looked at in the lens, and the one in it now.
  final Set<int> looked = {};
  int? lensAt;

  /// The register: the feeder stamped, the phases ticked, the fault ticked.
  int? stamp;
  final Set<int> phases = {};
  M6Fault? fault;

  bool get done => stage == M6TripStage.done;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => stageSlips == 0;
  bool _at(M6TripStage s) => !ended && !roundDone && stage == s;

  M6Room get room => switch (stage) {
        M6TripStage.panels || M6TripStage.toControl => M6Room.breakers,
        _ => M6Room.control,
      };

  bool get logComplete => stamp != null && phases.isNotEmpty && fault != null;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  /// The glass door into the breaker room.
  bool enterBreakers() {
    if (!_at(M6TripStage.toBreakers)) return false;
    stage = M6TripStage.panels;
    return true;
  }

  /// A panel chalk-marked open, or the mark rubbed off.
  bool toggleMark(int i) {
    if (!_at(M6TripStage.panels) || i < 0 || i >= deal.n) return false;
    if (!marks.remove(i)) marks.add(i);
    return true;
  }

  /// 'দেখা শেষ': every green panel marked and no red one.
  DoMistake? finishLook() {
    if (!_at(M6TripStage.panels)) return null;
    for (var i = 0; i < deal.n; i++) {
      if (marks.contains(i) && !deal.isOpen(i)) return _slip(M6TripLogMistakes.markRed);
    }
    for (var i = 0; i < deal.n; i++) {
      if (deal.isOpen(i) && !marks.contains(i)) return _slip(M6TripLogMistakes.missGreen);
    }
    roundDone = true;
    _tag(M6TripLogLines.caughtGreen);
    return null;
  }

  /// The glass door back to the control room (after the panels' reason).
  bool leaveBreakers() {
    if (!_at(M6TripStage.toControl)) return false;
    stage = M6TripStage.log;
    return true;
  }

  /// A relay case into the lens.
  bool look(int i) {
    if (!_at(M6TripStage.log) || i < 0 || i >= deal.n) return false;
    looked.add(i);
    lensAt = i;
    return true;
  }

  /// What relay [i] shows in the lens: its dropped flags and its window.
  Set<int> flagsOf(int i) => i == deal.tripped ? deal.flags : const <int>{};
  M6Fault? windowOf(int i) => i == deal.tripped ? deal.fault : null;

  bool stampFeeder(int i) {
    if (!_at(M6TripStage.log) || i < 0 || i >= deal.n) return false;
    stamp = i;
    return true;
  }

  bool tickPhase(int p) {
    if (!_at(M6TripStage.log) || p < 0 || p > 2) return false;
    if (!phases.remove(p)) phases.add(p);
    return true;
  }

  bool pickFault(M6Fault f) {
    if (!_at(M6TripStage.log)) return false;
    fault = f;
    return true;
  }

  /// 'খাতায় লিখি': the feeder whose relay dropped flags, its phases, its
  /// fault. Null with nothing done when a cell is still empty (the guide asks).
  DoMistake? writeLog() {
    if (!_at(M6TripStage.log) || !logComplete) return null;
    if (stamp != deal.tripped) return _slip(M6TripLogMistakes.noFlag);
    if (!setEquals(phases, deal.flags)) return _slip(M6TripLogMistakes.wrongPhase);
    if (fault != deal.fault) return _slip(M6TripLogMistakes.wrongType);
    roundDone = true;
    _tag(M6TripLogLines.caughtLog);
    return null;
  }

  /// The radio reply ([card]: its words): a wrong card is the deadly act it
  /// orders (R1 / R2).
  DoMistake? reply(bool right, {String card = ''}) {
    if (!_at(M6TripStage.radio)) return null;
    if (!right) return deadly = M6TripLogMistakes.reply(card);
    roundDone = true;
    _tag(M6TripLogLines.caughtSafe);
    return null;
  }

  /// Listened to a slip-line coworker.
  DoMistake pushSlip(DoMistake m) => _slip(m);

  /// Fails the play (listening to a deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  /// The stage's reason is paid: on to the next stage.
  void next() {
    stage = switch (stage) {
      M6TripStage.toBreakers => M6TripStage.panels,
      M6TripStage.panels => M6TripStage.toControl,
      M6TripStage.toControl => M6TripStage.log,
      M6TripStage.log => M6TripStage.radio,
      M6TripStage.radio || M6TripStage.done => M6TripStage.done,
    };
    roundDone = false;
    stageSlips = 0;
  }

  /// The round dot (0 panels, 1 register, 2 radio; null when done).
  int? get roundIndex => switch (stage) {
        M6TripStage.toBreakers || M6TripStage.panels => 0,
        M6TripStage.toControl || M6TripStage.log => 1,
        M6TripStage.radio => 2,
        M6TripStage.done => null,
      };
}

/// The coworker comes once his gate is reached: (c) after the panels'
/// reason, in the breaker room; (b) once the register's three cells are
/// filled; (a) after the crew has asked on the radio.
bool m6PushGateReached(M6Push p, M6TripRun r, {bool crewAsked = false}) => switch (p) {
      M6Push.room => r.stage == M6TripStage.toControl,
      M6Push.log => r.stage == M6TripStage.log && !r.roundDone && r.logComplete,
      M6Push.radio => r.stage == M6TripStage.radio && !r.roundDone && crewAsked,
    };

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action: door 1500; panels 4 × 1500 + দেখা শেষ ≈ 7500
/// + reason ~8200; door 1500; relays 3 × 1500 ≈ 4500; register 5 × 1500 ≈
/// 7500 + reason ~8200; the crew's ask ~5000 + reply ~4000 + the crew's yes
/// ~3500 + reason ~8200; the coworker once ≈ 9600 → ≈ 79000. 85 % ≈ 67000
/// → 70 s. (A new level's value: the owner may change it.)
const m6TripLogQuickMs = 70000;

@immutable
class M6TripLogPack {
  const M6TripLogPack({required this.id, required this.titleBn, this.quickMs = m6TripLogQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6TripLogPack> m6TripLogPacks = {
  'do_6_2_a': M6TripLogPack(id: 'do_6_2_a', titleBn: M6TripLogLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M6TripLogPage extends StatefulWidget {
  const M6TripLogPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6TripLogPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6TripLogPage> createState() => _M6TripLogPageState();
}

class _M6TripLogPageState extends State<M6TripLogPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TripRunPage(
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

class _TripRunPage extends ConsumerStatefulWidget {
  const _TripRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6TripLogPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TripRunPage> createState() => _TripRunPageState();
}

class _TripRunPageState extends ConsumerState<_TripRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6TripRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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

  /// The radio: the crew's words in the bubble; the reply cards.
  String? _crewLine;
  var _crewTalking = false;
  int _crewTok = 0;
  var _crewAsked = false;
  var _replyUp = false;
  List<ChoiceOption> _replyOpts = const [];
  final Set<String> _replyWrong = {};
  String? _replyPicked;
  var _replyBusy = false;

  /// A bang (a breaker opening on a fault) at a design point.
  Offset? _bangAt;
  int _bangTok = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M6TripGeo? _geoNow;
  final List<GlobalKey> _feederKeys = [for (var i = 0; i < 4; i++) GlobalKey()];
  final List<GlobalKey> _phaseKeys = [for (var i = 0; i < 3; i++) GlobalKey()];
  final Map<M6Fault, GlobalKey> _faultKeys = {for (final f in M6Fault.values) f: GlobalKey()};
  final _writeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _run = M6TripRun(m6TripDeal(widget.rng));
    MascotTalk.active.addListener(_crewLips);
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M6TripDeal get _deal => _run.deal;

  @override
  void dispose() {
    MascotTalk.active.removeListener(_crewLips);
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  /// The crew speaks in another voice: keep the guide's lips still meanwhile.
  void _crewLips() {
    if (_crewTalking && MascotTalk.active.value) scheduleMicrotask(MascotTalk.reset);
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
    _crewTalking = false;
    unawaited(MascotSpeechLibrary.stop());
  }

  /// The crew on the radio: the words in the bubble and the radio voice; the
  /// guide's bubble clears meanwhile.
  Future<void> _crewSay(String line) async {
    _hush();
    final tok = ++_crewTok;
    final guide = ref.read(guideDirectorProvider.notifier);
    guide.softClearLine();
    guide.react(GuideMood.idle);
    setState(() => _crewLine = line);
    _cue('sounds/intro/click.ogg', volume: 0.5);
    _crewTalking = true;
    await MascotSpeechLibrary.speak(line, muted: _muted, pitch: 0.86);
    if (mounted && tok == _crewTok) _crewTalking = false;
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_replyBusy;

  String get _task => M6TripLogLines.ask(_run.stage);

  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  void _stepDone() {
    _steps++;
    _maybeSchedule();
    setState(() => _wake++);
  }

  void _maybeSchedule() {
    if (coworkerDone || coworkerDue) return;
    if (m6PushGateReached(_deal.push, _run, crewAsked: _crewAsked)) scheduleCoworker();
  }

  // --- hands on -----------------------------------------------------------------
  void _tapScene(Offset p, M6TripGeo geo) {
    if (!_canPlay) return;
    final n = _deal.n;
    switch (_run.stage) {
      case M6TripStage.toBreakers:
        if (M6TripGeo.doorToBreakers.contains(p)) {
          _tick('sounds/intro/glass.ogg', 0.5);
          setState(() => _run.enterBreakers());
          _stepDone();
          unawaited(_sayChain([_task]));
          return;
        }
      case M6TripStage.panels:
        for (var i = 0; i < n; i++) {
          if (geo.panel(i, n).contains(p)) {
            _tick('sounds/learn/tag_slap.ogg', 0.5);
            setState(() => _run.toggleMark(i));
            _stepDone();
            return;
          }
        }
        if (M6TripGeo.doorToControl.contains(p)) {
          // Not a slip: the panels first.
          _tick();
          unawaited(_sayChain([M6TripLogLines.panelsFirst]));
          return;
        }
      case M6TripStage.toControl:
        if (M6TripGeo.doorToControl.contains(p)) {
          if (holdForCoworker()) return;
          _tick('sounds/intro/glass.ogg', 0.5);
          setState(() => _run.leaveBreakers());
          _stepDone();
          unawaited(_sayChain([_task]));
          return;
        }
      case M6TripStage.log:
        for (var i = 0; i < n; i++) {
          if (M6TripGeo.relay(i, n).contains(p)) {
            _tick('sounds/intro/click.ogg', 0.5);
            setState(() => _run.look(i));
            // The register slides up: the guide's bubble clears so it never
            // hides the lens (tap him for the task again).
            ref.read(guideDirectorProvider.notifier).softClearLine();
            _stepDone();
            return;
          }
        }
      case M6TripStage.radio:
      case M6TripStage.done:
        break;
    }
    _hints.missTap();
  }

  void _lookDone(Offset global) {
    if (!_canPlay || _run.stage != M6TripStage.panels) return;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.finishLook();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    unawaited(_stageDone());
  }

  void _register(VoidCallback act) {
    if (!_canPlay || _run.stage != M6TripStage.log) return;
    _tick('sounds/learn/tag_slap.ogg', 0.45);
    setState(act);
    _stepDone();
  }

  void _write(Offset global) {
    if (!_canPlay || _run.stage != M6TripStage.log) return;
    if (holdForCoworker()) return;
    if (!_run.logComplete) {
      // Not a slip: a cell is still empty.
      _tick();
      unawaited(_sayChain([M6TripLogLines.fillAll]));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.writeLog();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    unawaited(_stageDone());
  }

  // --- the radio ------------------------------------------------------------------
  Future<void> _startRadio() async {
    _cue('sounds/learn/tock.ogg', volume: 0.5);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _ended) return;
    await _crewSay(M6TripLogLines.crewAsk[_deal.crewAsk]);
    if (!mounted || _ended) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || _ended) return;
    setState(() => _crewAsked = true);
    if (_deal.push == M6Push.radio && !coworkerDone) {
      // He speaks first; the reply waits for him (see onCoworkerAnswer).
      _maybeSchedule();
      return;
    }
    _openReply();
  }

  void _openReply({String? before}) {
    if (!mounted || _ended || _replyUp) return;
    setState(() {
      _replyOpts = dealChoices(M6TripLogLines.replyRight, M6TripLogLines.replyWrong, widget.rng);
      _replyWrong.clear();
      _replyPicked = null;
      _replyUp = true;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([?before, M6TripLogLines.askReply], mood: GuideMood.think));
  }

  Future<void> _pickReply(ChoiceOption o, Offset origin) async {
    if (_ended || _card != null || !_replyUp || _replyBusy || _replyWrong.contains(o.textBn) || _replyPicked != null) return;
    _hush();
    if (!o.correct) {
      setState(() => _replyWrong.add(o.textBn));
      final m = _run.reply(false, card: o.textBn);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _replyBusy = true;
    setState(() => _replyPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _run.reply(true);
    setState(() {
      _replyUp = false;
      _replyOpts = const [];
      _replyBusy = false;
      _wake++;
    });
    unawaited(_stageDone(crewYes: true));
  }

  // --- the success beat -----------------------------------------------------------
  M6WhyTopic get _whyNow => switch (_run.stage) {
        M6TripStage.panels => M6WhyTopic.green,
        M6TripStage.log => _deal.logWhy,
        _ => M6WhyTopic.climb,
      };

  Future<void> _stageDone({bool crewYes = false}) async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    final stage = _run.stage;
    final topic = _whyNow;
    putOnTable(15 + (_run.thorough ? 5 : 0));
    if (crewYes) {
      await _crewSay(M6TripLogLines.crewOk);
      if (!mounted || _ended) return;
    }
    unawaited(askReason(
      deal: () => dealChoices(M6TripLogLines.whyRight[topic]!, M6TripLogLines.myths, widget.rng),
      question: M6TripLogLines.whyQ[topic]!,
      stillValid: () => _run.stage == stage && !_ended,
    ));
  }

  void _next() {
    setState(() {
      _run.next();
      _wake++;
    });
    switch (_run.stage) {
      case M6TripStage.toControl:
        _maybeSchedule();
        unawaited(_sayChain([_task]));
      case M6TripStage.radio:
        unawaited(_startRadio());
      case M6TripStage.done:
        unawaited(_finish());
      case M6TripStage.toBreakers:
      case M6TripStage.panels:
      case M6TripStage.log:
        unawaited(_sayChain([_task]));
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
    final stage = _run.stage;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1000), () {
      if (mounted && !_ended && _run.stage == stage) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6TripLogLines.coworker(_deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final s = _run.stage;
    switch (_deal.push) {
      case M6Push.room:
        if (s != M6TripStage.toControl) return null;
      case M6Push.log:
        if (s != M6TripStage.log || _run.roundDone) return null;
      case M6Push.radio:
        if (s != M6TripStage.radio || _run.roundDone || _replyUp) return null;
    }
    if (_intro || _card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _deal.push;
    if (!held) {
      final m = M6TripLogMistakes.push(p);
      if (m.deadly) {
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      // The breaker opens on the fault again with a bang (b: the one reset
      // through the glass; c: a neighbour panel).
      final geo = _geoNow;
      if (geo != null) {
        final n = _deal.n;
        setState(() {
          _bangAt = p == M6Push.room ? geo.panel(m6BangPanel(_deal), n).topCenter.translate(0, 52) : M6TripGeo.doorToBreakers.center;
          _bangTok++;
        });
      }
      HapticFeedback.heavyImpact();
      _cue('sounds/learn/spark.ogg', volume: 0.9);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6TripLogLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    if (p == M6Push.radio) {
      _openReply(before: M6TripLogLines.callHeld(p));
      return;
    }
    unawaited(_sayChain([M6TripLogLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6TripLogLines.tapWhy[_nudgeN++ % M6TripLogLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('m6trip/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The crew sent up on a line still live: the room freezes grey, the
  /// back-feed plays in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _replyUp = false;
      _replyOpts = const [];
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
    final speak = await SpokenOnce.first('m6trip/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6TripLogLines.deadlyWord : M6TripLogLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same stage goes on from where it was.
        _hush();
        setState(() {
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
    final quick = _clock.elapsedMilliseconds < widget.pack.quickMs;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
      _crewLine = null;
    });
    await _say(!_run.passed ? M6TripLogLines.fail : (_quickBonus ? M6TripLogLines.quick : M6TripLogLines.allSet),
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
    return LinemanMode.idle;
  }

  M6TripRig get _rig => M6TripRig(
        room: _run.room,
        names: _deal.names,
        faces: _deal.faces,
        open: [for (var i = 0; i < _deal.n; i++) _deal.isOpen(i)],
        planned: _deal.tagged ? _deal.planned : -1,
        counters: _deal.counters,
        marks: {..._run.marks},
      );

  bool get _registerShown => _run.stage == M6TripStage.log && _run.looked.isNotEmpty;

  /// The gesture hand: how to touch, never what. A door (the one way on): a
  /// tap ripple on it. The panels: a sweep over every panel and 'দেখা শেষ'
  /// alike. The relays: a sweep over every case; once the register is up, in
  /// turn a sweep over its every cell and 'খাতায় লিখি' (no press).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _deal.n;
    final k = _hintN++;
    switch (_run.stage) {
      case M6TripStage.toBreakers:
        return HintSpec.tap(M6TripGeo.doorToBreakers.center, space: HintSpace.scene);
      case M6TripStage.panels:
        return HintSpec.sweep([for (var i = 0; i < n; i++) geo.panel(i, n), geo.lookDone], space: HintSpace.scene);
      case M6TripStage.toControl:
        return HintSpec.tap(M6TripGeo.doorToControl.center, space: HintSpace.scene);
      case M6TripStage.log:
        if (!_registerShown || k.isEven) return HintSpec.sweep([for (var i = 0; i < n; i++) M6TripGeo.relay(i, n)], space: HintSpace.scene);
        return HintSpec.sweepOver([..._feederKeys.take(n), ..._phaseKeys, ..._faultKeys.values, _writeKey]);
      case M6TripStage.radio:
      case M6TripStage.done:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6TripGeo.forScene(m.height);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final room = _run.room;
    final lensAt = _run.lensAt;
    final bang = _bangAt;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('rooms'),
                child: RepaintBoundary(child: CustomPaint(painter: M6TripPainter(geo: geo, rig: _rig))),
              ),
              Positioned.fromRect(
                key: ValueKey('trainee-${room.name}'),
                rect: geo.trainee(room),
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (lensAt != null && _run.stage == M6TripStage.log)
                Positioned.fromRect(
                  key: ValueKey('lens-$lensAt'),
                  rect: M6TripGeo.lens,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0.86, end: 1),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: CustomPaint(
                        painter: M6LensPainter(
                          name: _deal.names[lensAt],
                          flags: _run.flagsOf(lensAt),
                          window: switch (_run.windowOf(lensAt)) {
                            final M6Fault f => M6TripLogLines.faultWindow(f),
                            null => '',
                          },
                        ),
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
          label: M6TripLogLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
          ),
        ),
      ),
      if (_run.stage == M6TripStage.panels)
        Positioned.fromRect(
          key: const ValueKey('look-done'),
          rect: geo.lookDone,
          child: ColorFiltered(
            colorFilter: grey,
            child: Semantics(
              button: true,
              label: M6TripLogLines.lookDone,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _lookDone(d.globalPosition),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2E4A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SlmColors.gold300, width: 1.6),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: Center(child: Text(M6TripLogLines.lookDone, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
                ),
              ),
            ),
          ),
        ),
      if (bang != null && !_freeze)
        Positioned.fill(
          key: ValueKey('bang-$_bangTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, _) => v >= 1 ? const SizedBox.shrink() : CustomPaint(painter: M6BangPainter(at: bang, v: v)),
            ),
          ),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('backfeed'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1600),
              builder: (_, v, _) => CustomPaint(painter: M6BackfeedPainter(v: v, height: m.height)),
            ),
          ),
        ),
      // Walking through a door: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('room-${room.name}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.stage == M6TripStage.toBreakers ? 0 : 0.6, end: 0),
              duration: const Duration(milliseconds: 420),
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
    final replyUp = _replyUp && playing && _replyOpts.isNotEmpty;
    final deckUp = reasonOpen || coworkerChoiceUp || replyUp;
    final registerUp = playing && _registerShown && !deckUp;
    final stageOpen = _run.stage != M6TripStage.radio && _run.stage != M6TripStage.done;
    final handsOn = playing && stageOpen && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final crew = _crewLine;
    final idx = _run.roundIndex;
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
              labels: M6TripLogLines.rounds,
              done: {for (var i = 0; i < (idx ?? 3); i++) i},
              current: idx,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.stage.name}/$_steps',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (registerUp)
                Positioned(
                  key: const ValueKey('hud-register'),
                  left: 6,
                  right: 6,
                  bottom: pad.bottom + 6,
                  child: _Register(
                    names: _deal.names,
                    stamp: _run.stamp,
                    phases: _run.phases,
                    fault: _run.fault,
                    feederKeys: _feederKeys,
                    phaseKeys: _phaseKeys,
                    faultKeys: _faultKeys,
                    writeKey: _writeKey,
                    onStamp: (i) => _register(() => _run.stampFeeder(i)),
                    onPhase: (p) => _register(() => _run.tickPhase(p)),
                    onFault: (f) => _register(() => _run.pickFault(f)),
                    onWrite: _write,
                  ),
                ),
              if (crew != null && playing && _run.stage == M6TripStage.radio && !coworkerOnScreen)
                Positioned(
                  key: ValueKey('crew-$_crewTok'),
                  left: 12,
                  right: 12,
                  top: pad.top + 112,
                  child: IgnorePointer(child: _CrewBubble(line: crew)),
                ),
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
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: const ValueKey('reply-deck'),
                                options: _replyOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _replyWrong,
                                picked: _replyPicked,
                                onPick: (o, at) => unawaited(_pickReply(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (registerUp ? _Register.height + 10 : 84)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.stage.name}-$strikes'),
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
                  line: M6TripLogLines.intro,
                  alarm: 'sounds/learn/siren.ogg',
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

/// The trip register: the feeder stamps, the phase ticks, the fault ticks
/// (always in this order), and 'খাতায় লিখি'. A free selection committed by
/// its own button (playbook §1.4).
class _Register extends StatelessWidget {
  const _Register({
    required this.names,
    required this.stamp,
    required this.phases,
    required this.fault,
    required this.feederKeys,
    required this.phaseKeys,
    required this.faultKeys,
    required this.writeKey,
    required this.onStamp,
    required this.onPhase,
    required this.onFault,
    required this.onWrite,
  });

  final List<String> names;
  final int? stamp;
  final Set<int> phases;
  final M6Fault? fault;
  final List<GlobalKey> feederKeys;
  final List<GlobalKey> phaseKeys;
  final Map<M6Fault, GlobalKey> faultKeys;
  final GlobalKey writeKey;
  final ValueChanged<int> onStamp;
  final ValueChanged<int> onPhase;
  final ValueChanged<M6Fault> onFault;
  final ValueChanged<Offset> onWrite;

  static const double height = 230;
  static const _ink = Color(0xFF1F3F8F);

  Widget _row(String label, List<Widget> cells) => SizedBox(
        height: 46,
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(label, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
            ),
            for (final c in cells) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: c)),
          ],
        ),
      );

  Widget _cell({required Key key, required String text, required bool on, required VoidCallback onTap}) => Semantics(
        key: key,
        button: true,
        selected: on,
        label: text,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? const Color(0xFFDDE6FA) : const Color(0xFFFFFCF2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? _ink : const Color(0xFFB59A6C), width: on ? 2.4 : 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (on) const Padding(padding: EdgeInsets.only(right: 3), child: Icon(Icons.check_rounded, size: 15, color: _ink)),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(text, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: on ? _ink : const Color(0xFF2A2018))),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 20,
            child: Center(child: Text(M6TripLogLines.register, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F)))),
          ),
          _row(M6TripLogLines.rowFeeder, [
            for (var i = 0; i < names.length; i++) _cell(key: feederKeys[i], text: names[i], on: stamp == i, onTap: () => onStamp(i)),
          ]),
          _row(M6TripLogLines.rowPhase, [
            for (var p = 0; p < 3; p++) _cell(key: phaseKeys[p], text: M6TripLogLines.phases[p], on: phases.contains(p), onTap: () => onPhase(p)),
          ]),
          _row(M6TripLogLines.rowFault, [
            for (final f in M6Fault.values) _cell(key: faultKeys[f]!, text: M6TripLogLines.faultChip(f), on: fault == f, onTap: () => onFault(f)),
          ]),
          const SizedBox(height: 4),
          Semantics(
            key: writeKey,
            button: true,
            label: M6TripLogLines.write,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => onWrite(d.globalPosition),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2E4A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SlmColors.gold300, width: 1.6),
                ),
                child: Text(M6TripLogLines.write, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The crew's words on the radio.
class _CrewBubble extends StatelessWidget {
  const _CrewBubble({required this.line});
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6BE08A), width: 1.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 2, right: 8), child: Icon(Icons.settings_input_antenna_rounded, size: 20, color: Color(0xFF6BE08A))),
          Expanded(child: Text(line, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, height: 1.3, color: SlmColors.ivory))),
        ],
      ),
    );
  }
}
