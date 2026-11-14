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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_cable_route_locate_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_cable_route_locate_world.dart' show M5CrlGeo, M5CrlPath, M5CrlPlan;

// Lesson 5.9 "কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা", কাজ 2 "মাটির নিচের সূত্র"
// (pack do_5_9_b, engineType m5_cable_route_locate). A town street from the
// substation gate; the faulty 11 kV cable is never seen. Two streets a play:
//
//  1. Read the route map first (walking or pinning without it = a slip). The
//     map card shows both feeder routes in one style; only their labels say
//     which is the docket's.
//  2. Walk the route: drag the trainee along the docket feeder's street. At
//     the junction the two branches look the same (the wrong branch = a slip).
//     Tap a ground mark to pin it — on the route it is a clue (once the
//     trainee has walked to it; a tap ahead of him does nothing), off the
//     route a slip at any time (one blotch art everywhere). Joint pits on the route: tap the
//     cover, drag it off, sweep the torch (a burn shows only under the beam),
//     then pin a burnt joint or close a clean one; walking past a closed pit is
//     a slip.
//  3. Nothing found by the route's end → call the specialist team (calling it
//     before the walk ends, or with a clue on the route missed, is a slip).
//     The TDR shows a distance, or a blank trace: pick what to do (a blank
//     trace needs the thumper's arc — ARM). The deck always holds a card of
//     the other case, so the trace must be read. Push the measuring wheel
//     along the route to the distance; every lift away from the last stop is a
//     stop (outside ±10 m = a slip). Then the thump sweep: the van thumps, the
//     player drags the ground microphone slowly; the headphone bar rises with
//     the thump near the fault; hold at the loudest to chalk (away from the
//     peak = a slip). The peak is always beyond the chalk radius from the TDR
//     distance, and no hold chalks before the mic has moved and two thumps
//     were heard.
//  4. Phone the owners of the other underground lines (telephone, water, gas)
//     before driving the peg (the peg first = a slip, R33 / ruling M5-7; a peg
//     with no clue and no chalk = a slip). ◆ on the table → "কেন …?" → the
//     next street.
//
// The lesson's rules, and only those (lesson 5.9): pro tip 1 (the route map is
// essential), point 3 (walk the route looking for marks, digging, wet or burnt
// spots; open joint pits for burns), point 4 (the thumper's thump heard with a
// special microphone; the TDR gives the distance in metres), advanced fact ARM
// (a high-resistance fault does not reflect the TDR's low-voltage signal: arc
// it with the thumper first), pro tip 2 (ask before digging: 'Dial before you
// dig'), myth 2 (overhead knowledge is not enough for UG cable work), pro tip
// 4 (always under the specialist team). Game data, not the lesson's (flagged):
// the ±10 m wheel tolerance, the 7 m chalk radius, the 10–16 m peak offset,
// the 1.1 s thump and 1.4 s hold, the junction pits, the trainee holding the
// microphone.
//
// No deadly act on this rung (item spec do_5_9_b: deadly []). Slips: the ten
// of the spec. Three slips strike the level out.
//
// The careless coworker once a play (dealt): B2 as the map opens ("no time
// for the map — dig here by guess"), or B1 as the team sets up (myth 2, "let us
// dig and joint it ourselves"). The next decisive control waits for him
// (holdForCoworker: closing the map / the walk / a pin; the TDR pick).
// Listening = a slip. Voice: the guide by device TTS; his lines are recorded
// by the director (rival_lines_missing).

// ============================================================================
// Content
// ============================================================================

/// What lies on the docket feeder's route this street.
enum M5CrlEvidence { none, mark, pit }

/// Where a street stands.
enum M5CrlStage { map, walk, walkDone, tdr, measure, sweep, dig }

/// A joint pit's close-up: the cover on, the torch, the call.
enum M5CrlPitStage { cover, torch, decide }

/// The kit pouch's buttons.
enum M5CrlTool { map, team, phone, peg }

/// The owners of the other underground lines.
enum M5CrlContact { telephone, water, gas }

/// The reason the street's ◆ table asks about.
enum M5CrlWhy { map, pit, arm, peg, call }

/// How the dig spot was found.
enum M5CrlSpotKind { mark, pit, chalk }

/// The coworker's push: B1 as the team sets up, B2 as the map opens.
enum M5CrlPush { team, map }

abstract final class M5CrlLines {
  static const title = 'মাটির নিচের সূত্র';
  static const intro = 'কেবিলের ফল্ট মাটির নিচে লুকিয়ে! রুট ধরে খুঁজে বের করুন।';
  static const rounds = ['রাস্তা 1', 'রাস্তা 2'];

  // The guide's task now (tap him: the same task, a different way).
  static const askStart = 'ডকেটের কেবিল কোন পথে গেছে? খুঁজে শুরু করুন।';
  static const askWalk = 'রুট ধরে হাঁটুন, মাটিতে আর পিটে সূত্র খুঁজুন।';
  static const askCover = 'পিটের ঢাকনা সরান।';
  static const askTorch = 'টর্চ ফেলে ভেতরটা দেখুন।';
  static const askPit = 'কী দেখলেন? চিহ্ন দেবেন, না ঢাকনা?';
  static const askEnd = 'রুটের শেষে পৌঁছেছেন। এবার কী করবেন?';
  static const askTdr = 'TDR কী বলছে দেখে ঠিক করুন।';
  static const askMeasure = 'চাকা ঠেলে রুট ধরে TDR-এর দূরত্বে থামুন।';
  static const askSweep = 'মাইক্রোফোন ধীরে টেনে থাম্পের শব্দ শুনুন।';
  static const askDig = 'জায়গা পাওয়া গেছে। খোঁড়ার প্রস্তুতি নিন।';
  static const askPhone = 'কার কার লাইন আছে, জেনে নিন।';
  static const askMap = 'ডকেটের ফিডার কোন পথে, ম্যাপে দেখে নিন।';
  static const tasks = [askStart, askWalk, askCover, askTorch, askPit, askEnd, askTdr, askMeasure, askSweep, askDig, askPhone, askMap];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const teamNotNeeded = 'সূত্র তো পেয়েই গেছেন — এবার খোঁড়ার প্রস্তুতি।';

  // Labels a worker reads.
  static const sceneLabel = 'শহরের রাস্তা';
  static const toolMap = 'রুট ম্যাপ';
  static const toolTeam = 'টিম ডাকুন';
  static const toolPhone = 'ফোন';
  static const toolPeg = 'গোঁজ';
  static const mapTitle = 'কেবিল রুট ম্যাপ';
  static const mapClose = 'ঠিক আছে';
  static const docket = 'ডকেট';
  static const pitPin = 'চিহ্ন দিন';
  static const pitClose = 'ঢাকনা দিন';
  static const pitTitle = 'জয়েন্ট পিট';
  static const phoneTitle = 'ফোন';
  static const phoneHang = 'রাখুন';
  static const tdr = 'TDR';
  static const tdrBlank = '— m';
  static const mic = 'মাইক্রোফোন';

  static String toolLabel(M5CrlTool t) => switch (t) {
        M5CrlTool.map => toolMap,
        M5CrlTool.team => toolTeam,
        M5CrlTool.phone => toolPhone,
        M5CrlTool.peg => toolPeg,
      };

  static String contactName(M5CrlContact c) => switch (c) {
        M5CrlContact.telephone => 'টেলিফোন অফিস',
        M5CrlContact.water => 'জল সরবরাহ',
        M5CrlContact.gas => 'গ্যাস অফিস',
      };

  /// The owners' replies (dealt: 0 = nothing here, 1 = careful, it is near).
  static String reply(M5CrlContact c, int i) => i == 0
      ? 'এই রাস্তায় আমাদের লাইন নেই।'
      : switch (c) {
          M5CrlContact.telephone => 'আমাদের কেবিল রাস্তার ওপারে — সাবধানে খুঁড়বেন।',
          M5CrlContact.water => 'জলের পাইপ ফুটপাথের ধারে — সাবধানে খুঁড়বেন।',
          M5CrlContact.gas => 'গ্যাসের পাইপ ওপারের ফুটপাথে — সাবধানে খুঁড়বেন।',
        };

  /// Feeder labels on the map and the docket (two per street, all different).
  static const feeders = ['F-2 বাজার', 'F-3 স্কুল', 'F-5 হাসপাতাল', 'F-6 কলোনি', 'F-7 স্টেশন', 'F-9 থানা'];

  // The TDR call. The same cards serve both cases: a distance card is right on
  // a distance and wrong on a blank trace, an ARM card the other way round, so
  // the player must read the trace. Every deck: one right, one card from the
  // other case (or "blank means sound"), one shortcut. 30–38.
  static const tdrRightDistance = ['দূরত্ব ধরে রুট বরাবর মেপে এগোই', 'TDR-এর মিটার রুট ধরে মেপে দাগ দিই'];
  static const tdrRightBlank = ['থাম্পারে আর্ক তুলে আবার TDR দেখি', 'আর্ক রিফ্লেকশনে (ARM) দূরত্ব মাপি'];
  static const tdrBlankIsSound = 'খালি ট্রেস মানে কেবিল ভালো, ফিরি';
  static const tdrShortcuts = [
    'আন্দাজে রাস্তার মাঝখানে খুঁড়ে দেখি',
    'ট্রেস যা-ই বলুক, গেট থেকে খুঁড়ি',
    'TDR থাক, যেখানে মন চায় খুঁড়ি',
    'যন্ত্র বাদ, পুরো রুট খুঁড়ে ফেলি',
    'দূরত্ব না মেপে পিটের পাশে খুঁড়ি',
  ];
  static List<String> tdrRight(bool blank) => blank ? tdrRightBlank : tdrRightDistance;

  /// The wrong cards that are about the trace itself (the other case's).
  static List<String> tdrDecoys(bool blank) => blank ? [...tdrRightDistance, tdrBlankIsSound] : tdrRightBlank;

  /// Every wrong card for a [blank] trace.
  static List<String> tdrWrong(bool blank) => [...tdrDecoys(blank), ...tdrShortcuts];

  // The reasons (one question per street, fitting what was done). 34–44.
  static const whyQ = <M5CrlWhy, String>{
    M5CrlWhy.map: 'হাঁটার আগে রুট ম্যাপ কেন নিলেন?',
    M5CrlWhy.pit: 'জয়েন্ট পিট কেন খুলে দেখলেন?',
    M5CrlWhy.arm: 'TDR-এ কিছু দেখা গেল না — তবু কেন থাম্পার?',
    M5CrlWhy.peg: 'গোঁজ এখানেই কেন পুঁতলেন?',
    M5CrlWhy.call: 'খোঁড়ার আগে কেন ফোন করলেন?',
  };
  static const whyMap = ['ম্যাপ ছাড়া খোঁজা অন্ধকারে ঢিল ছোঁড়া', 'কেবিল মাটির নিচে লুকানো, ম্যাপেই তার পথ'];
  static const whyPit = ['জয়েন্টই সবচেয়ে দুর্বল, ফল্ট সেখানে হয়', 'পিট খুলে পোড়া দাগ বা ক্ষতি খুঁজতে হয়'];
  static const whyArm = ['চুলের মতো ফাটল TDR-এ ধরা পড়ে না', 'থাম্পারের আর্কে ফল্ট TDR-এ ফুটে ওঠে'];
  static const whyPegChalk = ['এখানেই থাম্পের শব্দ সবচেয়ে জোরে', 'মাইক্রোফোনে এখানেই ঠক্ সবচেয়ে জোরে'];
  static const whyPegMark = ['রুটের ঠিক ওপরে মাটিতে অস্বাভাবিক দাগ', 'কেবিল রুটের ওপরেই খোঁড়া-পোড়ার দাগ'];
  static const whyPegPit = ['এই জয়েন্ট পিটের ভেতরে পোড়া দাগ', 'জয়েন্টে পোড়া দাগ, ফল্ট এই জয়েন্টে'];
  static const whyCall = ['নিচে জল, গ্যাস বা টেলিফোনের লাইন থাকে', 'Dial before you dig — আগে জেনে নিই'];
  static const myths = [
    'ওভারহেডের অভিজ্ঞতা আছে, আন্দাজই যথেষ্ট',
    'মাটির নিচের কেবিলে ফল্ট হয় না বললেই চলে',
    'কয়েক জায়গা খুঁড়লেই ফল্ট পেয়ে যাব',
    'নিয়ম শুধু সুপারভাইজার দেখলে মানতে হয়',
    'তাড়া আছে, তাই যা মনে হলো তাই করলাম',
    'খোঁড়াখুঁড়ি তো করতেই হবে, দেরি কেন',
    'ইউজি কেবিল আবহাওয়ায় সুরক্ষিত, ভয় নেই',
  ];
  static List<String> get allWhyRight => [...whyMap, ...whyPit, ...whyArm, ...whyPegChalk, ...whyPegMark, ...whyPegPit, ...whyCall];

  static List<String> whyRight(M5CrlWhy w, M5CrlSpotKind spot) => switch (w) {
        M5CrlWhy.map => whyMap,
        M5CrlWhy.pit => whyPit,
        M5CrlWhy.arm => whyArm,
        M5CrlWhy.peg => switch (spot) {
            M5CrlSpotKind.chalk => whyPegChalk,
            M5CrlSpotKind.mark => whyPegMark,
            M5CrlSpotKind.pit => whyPegPit,
          },
        M5CrlWhy.call => whyCall,
      };

  /// The careless coworker. B1 as the team sets up (lesson 5.9 myth 2).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerTeam = CoworkerScript(
    line: 'টিমের অপেক্ষা কেন? ওভারহেড লাইনের জ্ঞান থাকলেই ইউজি কেবিলে কাজ করা যায়। চলো, নিজেরাই খুঁড়ে জুড়ে দিই!',
    exitLine: coworkerExit,
    right: ['না, ইউজি কেবিল বিশেষজ্ঞ টিমের কাজ', 'না, এ কাজে আলাদা প্রশিক্ষণ লাগে', 'না, টিমের যন্ত্রেই ঠিক জায়গা মেলে'],
    wrong: [
      'ঠিক, চলো নিজেরাই খুঁড়ে ফেলি',
      'আচ্ছা, ওভারহেডের জ্ঞানেই চলবে',
      'হ্যাঁ, টিমের জন্য বসে থাকব না',
      'ঠিক আছে, আন্দাজে খুঁড়ে দেখি',
      'হ্যাঁ, জোড়াটা আমরাই দিয়ে দিই',
    ],
    asks: ['ও বলছে নিজেরাই খুঁড়ে জুড়তে। কী করবেন?', 'টিমের অপেক্ষা, না ওর কথা?', 'কী করবেন?'],
  );

  /// B2 as the map opens.
  static const coworkerMap = CoworkerScript(
    line: 'ম্যাপ দেখার সময় নেই — আন্দাজে এখানেই খুঁড়ে ফেলো!',
    exitLine: coworkerExit,
    right: ['না, আগে ম্যাপ দেখে রুট ধরব', 'না, আন্দাজে খোঁড়া চলবে না', 'না, ম্যাপ ছাড়া কেবিল মেলে না'],
    wrong: [
      'ঠিক, তাহলে এখানেই খুঁড়ে দেখি',
      'আচ্ছা, ম্যাপ পরে দেখলেও চলে',
      'হ্যাঁ, আন্দাজেই কাজ সারি',
      'ঠিক আছে, এখানেই খুঁড়ে ফেলি',
      'হ্যাঁ, সময় নষ্ট না করে খুঁড়ি',
    ],
    asks: ['ও বলছে আন্দাজে খুঁড়তে। কী করবেন?', 'ম্যাপ, না আন্দাজ?', 'কী করবেন?'],
  );

  static CoworkerScript coworker(M5CrlPush p) => p == M5CrlPush.team ? coworkerTeam : coworkerMap;

  static const callHeld = 'ঠিক! আন্দাজে খোঁড়া নয় — নিয়ম মেনে খুঁজুন।';
  static const allSet = 'দুই রাস্তাতেই রুট ধরে ফল্ট খুঁজলেন — আর খোঁড়ার আগে জেনে নিলেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে ম্যাপ, রুট ধরে সূত্র, তারপর যন্ত্র।';

  // "আজ যা ধরলেন".
  static const caughtMap = 'আগে রুট ম্যাপ, তারপর হাঁটা';
  static const caughtRoute = 'জংশনে লেবেল মিলিয়ে ঠিক রুট';
  static const caughtPit = 'জয়েন্ট পিট খুলে টর্চে দেখা';
  static const caughtClue = 'রুটের ওপর সূত্রে চিহ্ন';
  static const caughtArm = 'খালি TDR-এ আর্ক তুলে মাপ (ARM)';
  static const caughtThump = 'থাম্পের সবচেয়ে জোরে শব্দে দাগ';
  static const caughtCall = 'খোঁড়ার আগে সবাইকে ফোন';
  static const caughtCoworker = 'আন্দাজে খোঁড়ায় “না” বলেছেন';
}

abstract final class M5CrlMistakes {
  static const _dir = 'assets/game/art/m5_cable_route_locate';
  static const _k = '5.9/m5_cable_route_locate';

  // Lesson points (0-based, lesson 5.9's section): 2 = field visual + joint
  // pits, 3 = thumper + TDR. Pro tips 1/2/4 and the myths have no point index.
  static const walkNoMap = DoMistake(
    key: '$_k/no-map',
    textBn: 'ম্যাপ ছাড়া কেবিল খোঁজা অন্ধকারে ঢিল ছোঁড়ার মতো! আগে রুট ম্যাপে ডকেটের ফিডারের পথ দেখে নিন।',
    art: '$_dir/no_map.svg',
  );
  static const wrongRoute = DoMistake(
    key: '$_k/wrong-route',
    textBn: 'এটা অন্য ফিডারের পথ! জংশনে ম্যাপের লেবেল মিলিয়ে ডকেটের ফিডারের রুট ধরুন।',
    art: '$_dir/wrong_route.svg',
  );
  static const offRoute = DoMistake(
    key: '$_k/off-route',
    textBn: 'এই দাগ কেবিলের রুটের ওপর নয়। রুট বরাবর মাটির দাগ, খোঁড়া, ভেজা বা পোড়া জায়গাই সূত্র।',
    art: '$_dir/off_route.svg',
    lessonPoint: 2,
  );
  static const teamWithMark = DoMistake(
    key: '$_k/clue-missed',
    textBn: 'রুটের ওপরে মাটির একটা দাগ চোখ এড়িয়ে গেছে! আগে রুট বরাবর ভালো করে দেখুন, তারপর টিম।',
    art: '$_dir/clue_missed.svg',
    lessonPoint: 2,
  );
  static const teamEarly = DoMistake(
    key: '$_k/team-early',
    textBn: 'আগে পুরো রুট হেঁটে মাটি আর জয়েন্ট পিট দেখুন — কিছু না পেলে তবেই বিশেষজ্ঞ টিম।',
    art: '$_dir/clue_missed.svg',
    lessonPoint: 2,
  );
  static const pitPassed = DoMistake(
    key: '$_k/pit-passed',
    textBn: 'জয়েন্ট পিট না খুলেই চলে যাচ্ছেন! জয়েন্টই সবচেয়ে দুর্বল অংশ — ঢাকনা খুলে ভেতরটা দেখুন।',
    art: '$_dir/pit_burnt.svg',
    lessonPoint: 2,
  );
  static const pinClean = DoMistake(
    key: '$_k/pin-clean',
    textBn: 'এই জয়েন্ট তো পরিষ্কার — পোড়া দাগ বা ক্ষতি নেই। ভালো জয়েন্টে চিহ্ন দিলে ভুল জায়গায় খোঁড়া হবে।',
    art: '$_dir/pit_clean.svg',
    lessonPoint: 2,
  );
  static const closeBurnt = DoMistake(
    key: '$_k/close-burnt',
    textBn: 'জয়েন্টে পোড়া দাগ! এটাই ফল্টের সূত্র — ঢাকনা দিয়ে চলে যাবেন না, চিহ্ন দিন।',
    art: '$_dir/pit_burnt.svg',
    lessonPoint: 2,
  );
  static const notArm = DoMistake(
    key: '$_k/not-arm',
    textBn: 'TDR-এ প্রতিফলন নেই মানেই কেবিল ভালো নয় — চুলের মতো ফাটল ধরা পড়ে না। থাম্পারে আর্ক তুলে আবার TDR (ARM)।',
    art: '$_dir/tdr.svg',
    lessonPoint: 3,
  );
  static const tdrIgnored = DoMistake(
    key: '$_k/tdr-ignored',
    textBn: 'TDR ফল্টের দূরত্ব মিটারে বলে দিয়েছে — আর্ক বা আন্দাজ লাগবে না, সেই দূরত্ব রুট বরাবর মেপে যান।',
    art: '$_dir/tdr.svg',
    lessonPoint: 3,
  );
  static const traceOff = DoMistake(
    key: '$_k/trace-off',
    textBn: 'দূরত্ব মেলেনি! চাকার মিটার দেখে রুট বরাবর ঠিক TDR-এর দূরত্বে থামুন।',
    art: '$_dir/wheel.svg',
    lessonPoint: 3,
  );
  static const chalkOff = DoMistake(
    key: '$_k/chalk-off',
    textBn: 'এখানে থাম্পের শব্দ সবচেয়ে জোরে নয়। ধীরে টেনে শুনুন — যেখানে ঠক্ সবচেয়ে জোরে, দাগ সেখানে।',
    art: '$_dir/thump.svg',
    lessonPoint: 3,
  );
  static const pegGuess = DoMistake(
    key: '$_k/peg-guess',
    textBn: 'আন্দাজে খোঁড়া নয়! সূত্রে বা যন্ত্রে জায়গা নিশ্চিত হলে তবেই গোঁজ — অপ্রয়োজনীয় খোঁড়াখুঁড়ি বন্ধ।',
    art: '$_dir/peg_guess.svg',
    lessonPoint: 3,
  );
  static const pegBeforeCall = DoMistake(
    key: '$_k/peg-before-call',
    textBn: 'খোঁড়ার আগে কেবিল রুট রেকর্ড দেখুন এবং অন্য ভূগর্ভস্থ লাইনের (টেলিফোন, জল, গ্যাস) মালিকদের জানান।',
    art: '$_dir/dial_dig.svg',
  );
  static const listenTeam = DoMistake(
    key: '$_k/listen-team',
    textBn: 'ওভারহেডের জ্ঞানে ইউজি কেবিলের কাজ হয় না — ফল্ট খোঁজা আর জয়েন্টিং আলাদা প্রশিক্ষণের কাজ। বিশেষজ্ঞ টিমের অধীনে কাজ করুন।',
    art: '$_dir/listen_team.svg',
  );
  static const listenMap = DoMistake(
    key: '$_k/listen-map',
    textBn: 'আন্দাজে খোঁড়া নয় — রুট ম্যাপ ছাড়া কাজ অন্ধকারে ঢিল ছোঁড়ার মতো।',
    art: '$_dir/no_map.svg',
  );

  static DoMistake listen(M5CrlPush p) => p == M5CrlPush.team ? listenTeam : listenMap;

  static const all = [
    walkNoMap,
    wrongRoute,
    offRoute,
    teamWithMark,
    teamEarly,
    pitPassed,
    pinClean,
    closeBurnt,
    notArm,
    tdrIgnored,
    traceOff,
    chalkOff,
    pegGuess,
    pegBeforeCall,
    listenTeam,
    listenMap,
  ];
}

/// Game data (not in lesson 5.9; flagged): the wheel's tolerance, the chalk
/// radius, how far past a closed pit counts as passing it, how near a pit or
/// an on-route mark the trainee must be to open or pin it, and how far the
/// thump peak lies from the TDR distance (always beyond the chalk radius, so a
/// chalk at the wheel's stop without listening misses).
const double m5CrlWheelTolM = 10;
const double m5CrlChalkM = 7;
const double m5CrlPitMargin = 0.03;
const double m5CrlReach = 0.06;
const int m5CrlPeakMinM = 10;
const int m5CrlPeakMaxM = 16;

/// The sweep: before a hold can chalk, the microphone has moved this far
/// (design px) and this many thumps were heard; a hold lasts longer than one
/// thump interval, so a thump is always heard at the hold spot.
const double m5CrlSweepTravel = 40;
const int m5CrlSweepThumps = 2;
const int m5CrlThumpMs = 1100;
const int m5CrlHoldMs = 1400;

/// The TDR deck: one right card, one card about the trace from the other case,
/// one shortcut (shuffled).
List<ChoiceOption> m5CrlTdrDeal(bool blank, math.Random rng) {
  final right = M5CrlLines.tdrRight(blank);
  final decoys = M5CrlLines.tdrDecoys(blank);
  final cuts = M5CrlLines.tdrShortcuts;
  return [
    ChoiceOption(right[rng.nextInt(right.length)], true),
    ChoiceOption(decoys[rng.nextInt(decoys.length)], false),
    ChoiceOption(cuts[rng.nextInt(cuts.length)], false),
  ]..shuffle(rng);
}

/// A ground mark: on the docket's route (a clue) or off it (a decoy).
@immutable
class M5CrlMark {
  const M5CrlMark(this.path, this.t);
  final M5CrlPath path;
  final double t;
  bool get onRoute => path == M5CrlPath.own;
}

/// A joint pit: on the docket's route (open it) or on the other branch.
@immutable
class M5CrlPit {
  const M5CrlPit(this.path, this.t, {this.burnt = false});
  final M5CrlPath path;
  final double t;
  final bool burnt;
  bool get onRoute => path == M5CrlPath.own;
}

/// One street round.
@immutable
class M5CrlStreet {
  const M5CrlStreet({
    required this.plan,
    required this.ownFeeder,
    required this.otherFeeder,
    required this.routeMetres,
    required this.evidence,
    required this.marks,
    required this.pits,
    required this.faultT,
    required this.tdrBlank,
    required this.peakOffsetM,
    required this.contacts,
    required this.replies,
    required this.why,
  });

  final M5CrlPlan plan;
  final String ownFeeder;
  final String otherFeeder;

  /// The docket route's length (gate → far end), metres.
  final int routeMetres;
  final M5CrlEvidence evidence;

  /// Ground marks, in no telling order.
  final List<M5CrlMark> marks;

  /// Joint pits: those on the route, in route order, then the other branch's.
  final List<M5CrlPit> pits;

  /// The fault along the docket's route (0..1): the clue's place, or hidden.
  final double faultT;

  /// The TDR shows a blank trace (a high-resistance fault): ARM needed.
  final bool tdrBlank;

  /// The thump peak lies this far from the TDR distance (cable slack), metres.
  final int peakOffsetM;

  /// The phone's contact order, and each owner's reply.
  final List<M5CrlContact> contacts;
  final Map<M5CrlContact, int> replies;

  /// The question the street's reason deck asks (if it fits the play).
  final M5CrlWhy why;

  /// The TDR's distance (metres along the route).
  int get tdrMetres => (faultT * routeMetres).round();

  /// The thump peak along the route (0..1).
  double get peakT => (faultT + peakOffsetM / routeMetres).clamp(0.03, 0.99);

  List<int> get ownPits => [for (var i = 0; i < pits.length; i++) if (pits[i].onRoute) i];

  /// The clue on the route (a mark), if any.
  int? get clueMark {
    for (var i = 0; i < marks.length; i++) {
      if (marks[i].onRoute) return i;
    }
    return null;
  }
}

@immutable
class M5CrlDeal {
  const M5CrlDeal({required this.streets, required this.push, required this.pushStreet});
  final List<M5CrlStreet> streets;

  /// The coworker's push this play, and on which street (B1 only where the
  /// team is called: a street with nothing on the route).
  final M5CrlPush push;
  final int pushStreet;
}

double _between(math.Random r, double a, double b) => a + r.nextDouble() * (b - a);

M5CrlStreet _street(math.Random rng, {required int layout, required M5CrlEvidence evidence, required List<String> labels, M5CrlWhy? notWhy}) {
  final plan = M5CrlPlan(layout: layout, mirror: rng.nextBool(), ownA: rng.nextBool());
  // The smallest scene (things are closest there): every pit and mark at
  // least a finger apart, and clear of the junction.
  final scenes = [for (final h in const [560.0, 640.0, 720.0, 780.0, 850.0, 900.0]) M5CrlGeo.forScene(h, 0, plan)];
  final small = scenes.first;
  final j = small.junctionT;
  final placed = <(M5CrlPath, bool, double)>[];
  Offset at(M5CrlGeo g, (M5CrlPath, bool, double) x) => x.$2 ? g.pitAt(x.$1, x.$3) : g.markAt(x.$1, x.$3);
  double gapOf((M5CrlPath, bool, double) x) {
    var gap = double.infinity;
    for (final g in scenes) {
      final p = at(g, x);
      if (g.guideZone.inflate(16).contains(p)) return 0;
      gap = math.min(gap, (p - g.junction).distance + 22);
      for (final q in placed) {
        gap = math.min(gap, (at(g, q) - p).distance);
      }
    }
    return gap;
  }

  /// A place at [from]..[to] of [path] a finger clear of everything placed
  /// (the most clear one tried if none is fully clear).
  double pick(M5CrlPath path, {required bool pit, required double from, required double to}) {
    var best = from;
    var bestGap = -1.0;
    for (var k = 0; k < 400; k++) {
      final t = _between(rng, from, to);
      final gap = gapOf((path, pit, t));
      if (gap >= 56) {
        best = t;
        break;
      }
      if (gap > bestGap) {
        bestGap = gap;
        best = t;
      }
    }
    placed.add((path, pit, best));
    return best;
  }

  final routeMetres = 240 + 10 * rng.nextInt(15);
  // Joint pits on the docket's branch (1 or 2, in route order), one on the
  // other branch.
  final nOwn = 1 + rng.nextInt(2);
  final from = j + 0.08;
  final ownPitT = <double>[pick(M5CrlPath.own, pit: true, from: from, to: 0.9)];
  if (nOwn == 2) {
    final b = pick(M5CrlPath.own, pit: true, from: from, to: 0.92);
    // No room for a second pit on a short branch: one is enough.
    if (gapOf(placed.removeLast()) >= 56) {
      ownPitT.add(b);
      placed.add((M5CrlPath.own, true, b));
    }
  }
  ownPitT.sort();
  final burntAt = evidence == M5CrlEvidence.pit ? rng.nextInt(ownPitT.length) : -1;
  final otherPitT = pick(M5CrlPath.other, pit: true, from: 0.2, to: 0.75);
  final pits = [
    for (final (i, t) in ownPitT.indexed) M5CrlPit(M5CrlPath.own, t, burnt: i == burntAt),
    M5CrlPit(M5CrlPath.other, otherPitT),
  ];
  // The fault: the clue's place, or hidden along the route.
  final faultT = switch (evidence) {
    M5CrlEvidence.pit => ownPitT[burntAt],
    M5CrlEvidence.mark => pick(M5CrlPath.own, pit: false, from: 0.12, to: 0.92),
    M5CrlEvidence.none => _between(rng, 0.28, 0.9),
  };
  // Marks: the clue (if dealt) and one or two decoys off the route.
  final decoys = 1 + rng.nextInt(2);
  final lane = decoys == 2 || rng.nextBool();
  final marks = <M5CrlMark>[if (evidence == M5CrlEvidence.mark) M5CrlMark(M5CrlPath.own, faultT)];
  // Decoys: on the lane and / or the other branch, wherever a finger's room
  // is left (never under the guide).
  final where = [if (lane) M5CrlPath.lane, M5CrlPath.other, M5CrlPath.other, if (!lane) M5CrlPath.lane];
  for (final path in where) {
    if (marks.where((m) => !m.onRoute).length >= decoys) break;
    final t = path == M5CrlPath.lane ? pick(path, pit: false, from: 0.4, to: 0.9) : pick(path, pit: false, from: 0.2, to: 0.92);
    final spot = placed.removeLast();
    if (gapOf(spot) >= 56) {
      placed.add(spot);
      marks.add(M5CrlMark(path, t));
    }
  }
  if (marks.every((m) => m.onRoute)) {
    marks.add(M5CrlMark(M5CrlPath.other, pick(M5CrlPath.other, pit: false, from: 0.2, to: 0.92)));
  }
  marks.shuffle(rng);
  final peak = (m5CrlPeakMinM + rng.nextInt(m5CrlPeakMaxM - m5CrlPeakMinM + 1)) * (rng.nextBool() ? 1 : -1);
  final contacts = [...M5CrlContact.values]..shuffle(rng);
  final tdrBlank = evidence == M5CrlEvidence.none && rng.nextBool();
  final whys = [
    M5CrlWhy.map,
    M5CrlWhy.pit,
    M5CrlWhy.peg,
    M5CrlWhy.call,
    if (tdrBlank) ...[M5CrlWhy.arm, M5CrlWhy.arm, M5CrlWhy.arm],
  ]..removeWhere((w) => w == notWhy);
  return M5CrlStreet(
    plan: plan,
    ownFeeder: labels[0],
    otherFeeder: labels[1],
    routeMetres: routeMetres,
    evidence: evidence,
    marks: marks,
    pits: pits,
    faultT: faultT,
    tdrBlank: tdrBlank,
    peakOffsetM: peak,
    contacts: contacts,
    replies: {for (final c in M5CrlContact.values) c: rng.nextInt(2)},
    why: whys[rng.nextInt(whys.length)],
  );
}

/// A fresh play: two streets (different shapes and feeders); one has nothing
/// on its route (the team's instruments find the fault), the other a clue on
/// the route (a mark or a burnt joint) or nothing either.
M5CrlDeal m5CrlDeal(math.Random rng) {
  final layouts = [for (var i = 0; i < m5CrlLayouts; i++) i]..shuffle(rng);
  final labels = [...M5CrlLines.feeders]..shuffle(rng);
  final roll = rng.nextDouble();
  final second = roll < 0.5 ? M5CrlEvidence.mark : (roll < 0.85 ? M5CrlEvidence.pit : M5CrlEvidence.none);
  final kinds = [M5CrlEvidence.none, second]..shuffle(rng);
  final a = _street(rng, layout: layouts[0], evidence: kinds[0], labels: labels.sublist(0, 2));
  final b = _street(rng, layout: layouts[1], evidence: kinds[1], labels: labels.sublist(2, 4), notWhy: a.why);
  final streets = [a, b];
  final push = rng.nextBool() ? M5CrlPush.team : M5CrlPush.map;
  final teamStreets = [for (var i = 0; i < 2; i++) if (streets[i].evidence == M5CrlEvidence.none) i];
  final at = push == M5CrlPush.team ? teamStreets[rng.nextInt(teamStreets.length)] : rng.nextInt(2);
  return M5CrlDeal(streets: streets, push: push, pushStreet: at);
}

/// The play state (pure logic).
class M5CrlRun {
  M5CrlRun(this.deal);
  final M5CrlDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  final List<String> caught = [];
  var _routeSlip = false;
  var _mapSlip = false;

  /// The street's work is done (its reason comes next).
  var roundDone = false;

  M5CrlStage stage = M5CrlStage.map;
  var mapRead = false;

  /// How far the trainee has walked along the docket's route (0..1).
  double walked = 0;
  final Set<int> pinnedMarks = {};
  final Set<int> resolvedPits = {};
  int? pitOpen;
  M5CrlPitStage pitStage = M5CrlPitStage.cover;
  var pitOpened = false;
  var armDone = false;
  double? wheelM;
  M5CrlSpotKind? spotKind;
  double? spotT;
  final Set<M5CrlContact> called = {};
  var heldCoworker = false;

  M5CrlStreet get street => deal.streets[index.clamp(0, 1)];
  bool get done => index >= 2;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get spotKnown => spotKind != null;
  bool get callsDone => called.length == M5CrlContact.values.length;
  bool get _open => !ended && !roundDone;

  /// The team's path is on (TDR, wheel, thump).
  bool get teamOn => stage.index >= M5CrlStage.tdr.index;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  /// The route map is read (any time; the walk opens).
  void openMap() {
    if (!_open) return;
    mapRead = true;
    if (stage == M5CrlStage.map) stage = M5CrlStage.walk;
  }

  /// A walk begins (a drag of the trainee): without the map it is a slip.
  DoMistake? startWalk() {
    if (!_open) return null;
    if (!mapRead) {
      _mapSlip = true;
      return _slip(M5CrlMistakes.walkNoMap);
    }
    return null;
  }

  /// The trainee drags along the docket's route to [t] (0..1).
  DoMistake? traceTo(double t) {
    if (!_open || stage != M5CrlStage.walk || pitOpen != null) return null;
    // Once the spot is known, a pit further on is no longer a clue to check.
    for (final i in spotKnown ? const <int>[] : street.ownPits) {
      final p = street.pits[i];
      if (!resolvedPits.contains(i) && t > p.t + m5CrlPitMargin) {
        walked = math.max(walked, p.t);
        return _slip(M5CrlMistakes.pitPassed);
      }
    }
    walked = math.max(walked, t.clamp(0.0, 1.0));
    if (walked >= 0.985) {
      walked = 1;
      stage = M5CrlStage.walkDone;
    }
    return null;
  }

  /// The drag went up the other feeder's branch.
  DoMistake? traceOther() {
    if (!_open) return null;
    _routeSlip = true;
    return _slip(M5CrlMistakes.wrongRoute);
  }

  /// A tap on mark [i] counts now: always before the map (a slip) and for a
  /// decoy (a wrong pin costs at any time); a mark on the route only once the
  /// trainee has walked to it (the walk along the route is the looking).
  bool markInReach(int i) {
    final m = street.marks[i];
    return !mapRead || !m.onRoute || walked >= m.t - m5CrlReach;
  }

  /// A ground mark tapped: pinned on the route, a slip off it; an on-route
  /// mark ahead of the trainee is not reached yet (nothing happens).
  DoMistake? tapMark(int i) {
    if (!_open || pinnedMarks.contains(i) || teamOn || !markInReach(i)) return null;
    if (!mapRead) {
      _mapSlip = true;
      return _slip(M5CrlMistakes.walkNoMap);
    }
    final m = street.marks[i];
    if (!m.onRoute) return _slip(M5CrlMistakes.offRoute);
    pinnedMarks.add(i);
    spotKind = M5CrlSpotKind.mark;
    spotT = m.t;
    _tag(M5CrlLines.caughtClue);
    return null;
  }

  /// A pit on the route can be opened once the trainee has come to it.
  bool canOpenPit(int i) =>
      _open &&
      stage == M5CrlStage.walk &&
      pitOpen == null &&
      street.pits[i].onRoute &&
      !resolvedPits.contains(i) &&
      walked >= street.pits[i].t - m5CrlReach;

  void openPit(int i) {
    if (!canOpenPit(i)) return;
    pitOpen = i;
    pitStage = M5CrlPitStage.cover;
    pitOpened = true;
  }

  void liftCover() {
    if (pitOpen != null && pitStage == M5CrlPitStage.cover) pitStage = M5CrlPitStage.torch;
  }

  void torchDone() {
    if (pitOpen != null && pitStage == M5CrlPitStage.torch) pitStage = M5CrlPitStage.decide;
  }

  /// Pin ([pin]) or close the open pit. A wrong call is a slip; the pit stays.
  DoMistake? decidePit(bool pin) {
    final i = pitOpen;
    if (!_open || i == null || pitStage != M5CrlPitStage.decide) return null;
    final burnt = street.pits[i].burnt;
    if (pin && !burnt) return _slip(M5CrlMistakes.pinClean);
    if (!pin && burnt) return _slip(M5CrlMistakes.closeBurnt);
    resolvedPits.add(i);
    pitOpen = null;
    _tag(M5CrlLines.caughtPit);
    if (pin) {
      spotKind = M5CrlSpotKind.pit;
      spotT = street.pits[i].t;
      _tag(M5CrlLines.caughtClue);
    }
    return null;
  }

  /// A kit button. The phone just opens its sheet (see [call]).
  DoMistake? use(M5CrlTool t) {
    if (!_open) return null;
    switch (t) {
      case M5CrlTool.map:
        openMap();
      case M5CrlTool.team:
        if (spotKnown || teamOn) return null;
        if (stage != M5CrlStage.walkDone) return _slip(M5CrlMistakes.teamEarly);
        final clue = street.clueMark;
        if (clue != null && !pinnedMarks.contains(clue)) return _slip(M5CrlMistakes.teamWithMark);
        stage = M5CrlStage.tdr;
      case M5CrlTool.phone:
        break;
      case M5CrlTool.peg:
        if (!spotKnown) return _slip(M5CrlMistakes.pegGuess);
        if (!callsDone) return _slip(M5CrlMistakes.pegBeforeCall);
        roundDone = true;
        _tag(M5CrlLines.caughtCall);
    }
    return null;
  }

  /// One owner phoned.
  void call(M5CrlContact c) {
    if (_open) called.add(c);
  }

  /// The call on the TDR screen ([right] = the card fits the trace).
  DoMistake? tdrPick(bool right) {
    if (!_open || stage != M5CrlStage.tdr) return null;
    if (!right) return _slip(street.tdrBlank && !armDone ? M5CrlMistakes.notArm : M5CrlMistakes.tdrIgnored);
    if (street.tdrBlank) {
      armDone = true;
      _tag(M5CrlLines.caughtArm);
    }
    stage = M5CrlStage.measure;
    return null;
  }

  /// The wheel stopped at [metres] along the route.
  DoMistake? measure(double metres) {
    if (!_open || stage != M5CrlStage.measure) return null;
    if ((metres - street.tdrMetres).abs() > m5CrlWheelTolM) return _slip(M5CrlMistakes.traceOff);
    wheelM = metres;
    stage = M5CrlStage.sweep;
    return null;
  }

  /// A chalk mark held [metresFromPeak] from the thump's peak.
  DoMistake? chalk(double metresFromPeak) {
    if (!_open || stage != M5CrlStage.sweep) return null;
    if (metresFromPeak > m5CrlChalkM) return _slip(M5CrlMistakes.chalkOff);
    spotKind = M5CrlSpotKind.chalk;
    spotT = street.peakT;
    stage = M5CrlStage.dig;
    _tag(M5CrlLines.caughtThump);
    return null;
  }

  /// Listened to the coworker.
  DoMistake listened(M5CrlPush p) => _slip(M5CrlMistakes.listen(p));

  /// The question street 1 asked (street 2 never asks it again).
  M5CrlWhy? _firstWhy;

  /// The question this street's reason asks: the dealt one if it fits the
  /// play (a pit opened, ARM done), else the next that fits; never the
  /// question the first street asked.
  M5CrlWhy get why {
    bool fits(M5CrlWhy w) => switch (w) {
          M5CrlWhy.pit => pitOpened,
          M5CrlWhy.arm => armDone,
          _ => true,
        };
    final asked = index == 1 ? _firstWhy : null;
    for (final w in [street.why, M5CrlWhy.peg, M5CrlWhy.call, M5CrlWhy.map]) {
      if (fits(w) && w != asked) return w;
    }
    return M5CrlWhy.map;
  }

  void next() {
    if (index == 0) _firstWhy = why;
    if (index == 1) {
      if (!_mapSlip) _tag(M5CrlLines.caughtMap);
      if (!_routeSlip) _tag(M5CrlLines.caughtRoute);
    }
    index++;
    roundSlips = 0;
    roundDone = false;
    stage = M5CrlStage.map;
    mapRead = false;
    walked = 0;
    pinnedMarks.clear();
    resolvedPits.clear();
    pitOpen = null;
    pitStage = M5CrlPitStage.cover;
    pitOpened = false;
    armDone = false;
    wheelM = null;
    spotKind = null;
    spotT = null;
    called.clear();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a clue street: map + read ~4000, walk ~5000, 1–2 pits × ~6000, phone ×3
///     + hang up ~5000, peg, reason ~8200                            ≈ 32000
///   a team street: map + read ~4000, walk ~5000, pits ~9000, team + TDR deck
///     ~5000, wheel ~4000, thump sweep ~8000, phone ~5000, peg, reason ~8200
///                                                                  ≈ 50000
/// + the coworker once ≈ 9600                                       ≈ 92000
/// 85 % ≈ 78000 → 80 s.
const m5CrlQuickMs = 80000;

/// The kit row, shuffled so that it never reads left to right in a working
/// order (map → team → phone → peg; no answer in the layout).
List<M5CrlTool> m5CrlToolRow(math.Random rng) {
  final tools = [...M5CrlTool.values];
  do {
    tools.shuffle(rng);
  } while (m5CrlInWorkOrder(tools));
  return tools;
}

/// True if tapping [row] left to right would follow the work's order.
bool m5CrlInWorkOrder(List<M5CrlTool> row) {
  int at(M5CrlTool t) => row.indexOf(t);
  return at(M5CrlTool.map) < at(M5CrlTool.phone) && at(M5CrlTool.phone) < at(M5CrlTool.peg);
}

/// The thump's loudness at [metres] from the peak (0..1).
double m5CrlLoudness(double metres) => (1 - metres / 30).clamp(0.0, 1.0);

@immutable
class M5CrlPack {
  const M5CrlPack({required this.id, required this.titleBn, this.quickMs = m5CrlQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5CrlPack> m5CrlPacks = {
  'do_5_9_b': M5CrlPack(id: 'do_5_9_b', titleBn: M5CrlLines.title),
};

/// Test hook: the live play (tests only).
class M5CrlProbe {
  _CrlRunPageState? _s;
  M5CrlRun? get run => _s?._run;
  M5CrlGeo? get geo => _s?._geoNow;

  /// The scene's design px → this screen (null before layout).
  Offset? toScreen(Offset design) {
    final box = _s?._touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(design);
  }

  /// The pit close-up's box on screen (null when closed).
  Rect? get pitRect => HintSpec.globalRectOf(_s!._pitKey);

  /// The sweep: the thump peak (design px).
  Offset? get peak {
    final s = _s;
    final g = s?._geoNow;
    if (s == null || g == null) return null;
    return g.ownAt(s._run.street.peakT);
  }

  double get level => _s?._level ?? 0;
}

// ============================================================================
// Page
// ============================================================================

class M5CableRouteLocatePage extends StatefulWidget {
  const M5CableRouteLocatePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5CrlPack pack;
  final bool muted;
  final int? seed;
  final M5CrlProbe? probe;

  @override
  State<M5CableRouteLocatePage> createState() => _M5CableRouteLocatePageState();
}

class _M5CableRouteLocatePageState extends State<M5CableRouteLocatePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CrlRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _CrlRunPage extends ConsumerStatefulWidget {
  const _CrlRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5CrlPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5CrlProbe? probe;

  @override
  ConsumerState<_CrlRunPage> createState() => _CrlRunPageState();
}

enum _Drag { none, walk, wheel, mic }

class _CrlRunPageState extends ConsumerState<_CrlRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5CrlRun _run;
  late final List<M5CrlTool> _tools;
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

  // Overlays.
  var _mapOpen = false;
  var _phoneOpen = false;

  // The TDR deck.
  List<ChoiceOption> _tdrOpts = const [];
  final Set<String> _tdrWrong = {};
  String? _tdrPicked;
  var _tdrBusy = false;
  var _tdrReady = false;
  Timer? _tdrTimer;

  // The pit close-up.
  double _lift = 0;
  double _liftDrag = 0;
  Offset? _beam;
  final Set<int> _beamBins = {};
  final _pitKey = GlobalKey();

  // Drags on the street.
  _Drag _drag = _Drag.none;
  var _dragDead = false;
  Offset _dragFrom = Offset.zero;
  double _wheelT = 0;

  /// Where the wheel was last stopped (metres): a lift anywhere else is a stop.
  double _wheelLastM = 0;

  /// The sweep so far: the microphone's travel (design px), thumps heard.
  double _sweepTravel = 0;
  int _sweepThumps = 0;
  Offset? _mic;
  Offset _holdAnchor = Offset.zero;
  Timer? _holdTimer;
  Timer? _thumpTimer;
  int _thumps = 0;
  double _level = 0;
  Offset? _chalkAt;
  Offset? _pegAt;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final Map<M5CrlTool, GlobalKey> _toolKeys = {for (final t in M5CrlTool.values) t: GlobalKey()};
  final _mapCloseKey = GlobalKey();
  final _pinKey = GlobalKey();
  final _closeKey = GlobalKey();
  final Map<M5CrlContact, GlobalKey> _contactKeys = {for (final c in M5CrlContact.values) c: GlobalKey()};
  final _hangKey = GlobalKey();
  M5CrlGeo? _geoNow;
  int _hintShows = 0;
  Object? _hintKeyNow;

  @override
  void initState() {
    super.initState();
    _run = M5CrlRun(m5CrlDeal(widget.rng));
    _tools = m5CrlToolRow(widget.rng);
    widget.probe?._s = this;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M5CrlStreet get _street => _run.street;

  @override
  void dispose() {
    disposeCoworker();
    _tdrTimer?.cancel();
    _holdTimer?.cancel();
    _thumpTimer?.cancel();
    _chain++;
    if (widget.probe?._s == this) widget.probe?._s = null;
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

  bool get _tdrUp => _run.stage == M5CrlStage.tdr && _tdrReady && _tdrOpts.isNotEmpty;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone;

  String get _task {
    if (_phoneOpen) return M5CrlLines.askPhone;
    if (_mapOpen) return M5CrlLines.askMap;
    if (_run.pitOpen != null) {
      return switch (_run.pitStage) {
        M5CrlPitStage.cover => M5CrlLines.askCover,
        M5CrlPitStage.torch => M5CrlLines.askTorch,
        M5CrlPitStage.decide => M5CrlLines.askPit,
      };
    }
    if (_run.spotKnown) return M5CrlLines.askDig;
    return switch (_run.stage) {
      M5CrlStage.map => M5CrlLines.askStart,
      M5CrlStage.walk => M5CrlLines.askWalk,
      M5CrlStage.walkDone => M5CrlLines.askEnd,
      M5CrlStage.tdr => M5CrlLines.askTdr,
      M5CrlStage.measure => M5CrlLines.askMeasure,
      M5CrlStage.sweep => M5CrlLines.askSweep,
      M5CrlStage.dig => M5CrlLines.askDig,
    };
  }

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _wake++;
      _mapOpen = false;
      _phoneOpen = false;
      _tdrOpts = const [];
      _tdrReady = false;
      _chalkAt = null;
      _pegAt = null;
      _mic = null;
      _level = 0;
      _wheelT = 0;
      _wheelLastM = 0;
    });
    unawaited(_sayChain([_task]));
  }

  // --- the kit ------------------------------------------------------------------
  void _useTool(M5CrlTool t, Offset global) {
    if (!_canPlay || _mapOpen || _phoneOpen || _run.pitOpen != null) return;
    _tick(t == M5CrlTool.peg ? 'sounds/intro/impact_metal.ogg' : 'sounds/intro/click.ogg', 0.5);
    switch (t) {
      case M5CrlTool.map:
        _run.use(t);
        setState(() {
          _mapOpen = true;
          _wake++;
        });
        _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
        if (!coworkerDone && _run.index == _run.deal.pushStreet && _run.deal.push == M5CrlPush.map) scheduleCoworker();
        unawaited(_sayChain([M5CrlLines.askMap]));
        return;
      case M5CrlTool.phone:
        setState(() {
          _phoneOpen = true;
          _wake++;
        });
        unawaited(_sayChain([M5CrlLines.askPhone]));
        return;
      case M5CrlTool.team:
        if (_run.spotKnown && !_run.teamOn) {
          unawaited(_sayChain([M5CrlLines.teamNotNeeded]));
          return;
        }
      case M5CrlTool.peg:
        break;
    }
    final before = _run.stage;
    final m = _run.use(t);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    if (t == M5CrlTool.team && before != M5CrlStage.tdr && _run.stage == M5CrlStage.tdr) _teamArrives();
    if (t == M5CrlTool.peg && _run.roundDone) {
      setState(() => _pegAt = _spotPoint());
      unawaited(_roundDone());
    }
  }

  /// The specialist van at the gate; the TDR screen, then its deck.
  void _teamArrives() {
    _cue('sounds/learn/rush_in.ogg', volume: 0.5);
    setState(() {
      _wheelT = 0;
      _wheelLastM = 0;
      _tdrReady = false;
      _tdrOpts = const [];
    });
    if (!coworkerDone && _run.index == _run.deal.pushStreet && _run.deal.push == M5CrlPush.team) scheduleCoworker();
    _tdrTimer?.cancel();
    _tdrTimer = Timer(Duration(milliseconds: _quiet ? 400 : 1200), () {
      if (!mounted || _run.stage != M5CrlStage.tdr) return;
      setState(() {
        _tdrReady = true;
        _tdrOpts = m5CrlTdrDeal(_street.tdrBlank, widget.rng);
        _tdrWrong.clear();
        _tdrPicked = null;
      });
      _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
      unawaited(_sayChain([M5CrlLines.askTdr], mood: GuideMood.think));
    });
  }

  Future<void> _pickTdr(ChoiceOption o, Offset origin) async {
    if (!_canPlay || !_tdrUp || _tdrBusy || _tdrWrong.contains(o.textBn) || _tdrPicked != null) return;
    if (holdForCoworker()) return;
    _hush();
    if (!o.correct) {
      setState(() => _tdrWrong.add(o.textBn));
      final m = _run.tdrPick(false);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _tdrBusy = true;
    setState(() => _tdrPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    if (_street.tdrBlank) _cue('sounds/learn/spark.ogg', volume: 0.5);
    _run.tdrPick(true);
    _tdrBusy = false;
    setState(() {
      _tdrOpts = const [];
      _wheelT = 0;
      _wheelLastM = 0;
      _wake++;
    });
    unawaited(_sayChain([M5CrlLines.askMeasure]));
  }

  void _closeMap() {
    if (!_mapOpen || !_canPlay) return;
    if (holdForCoworker()) return;
    _tick();
    setState(() {
      _mapOpen = false;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  void _call(M5CrlContact c) {
    if (!_canPlay || !_phoneOpen || _run.called.contains(c)) return;
    _tick('sounds/learn/dmm_beep.ogg', 0.5);
    setState(() {
      _run.call(c);
      _wake++;
    });
  }

  void _hangUp() {
    if (!_phoneOpen) return;
    _tick();
    setState(() {
      _phoneOpen = false;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  Offset? _spotPoint() {
    final g = _geoNow;
    if (g == null) return null;
    final kind = _run.spotKind;
    if (kind == M5CrlSpotKind.chalk) return _chalkAt;
    if (kind == M5CrlSpotKind.mark) {
      final i = _run.pinnedMarks.isEmpty ? null : _run.pinnedMarks.first;
      if (i != null) {
        final m = _street.marks[i];
        return g.markAt(m.path, m.t);
      }
    }
    final t = _run.spotT;
    if (t == null) return null;
    return kind == M5CrlSpotKind.pit ? g.pitAt(M5CrlPath.own, t).translate(0, -14) : g.ownAt(t);
  }

  // --- the street: taps and drags ----------------------------------------------
  bool get _streetLive => _canPlay && !_mapOpen && !_phoneOpen && _run.pitOpen == null && !_tdrUp;

  void _tapScene(Offset p, M5CrlGeo geo, Offset global) {
    if (!_streetLive) return;
    final st = _street;
    if (!_run.teamOn) {
      for (final (i, m) in st.marks.indexed) {
        if (geo.markHit(geo.markAt(m.path, m.t)).contains(p)) {
          if (_run.pinnedMarks.contains(i)) return;
          if (!_run.markInReach(i)) {
            // Ahead of the trainee: walk to it first (no cost).
            _hints.missTap();
            return;
          }
          if (holdForCoworker()) return;
          _tick('sounds/learn/tag_slap.ogg', 0.5);
          final mk = _run.tapMark(i);
          setState(() => _wake++);
          if (mk != null) {
            unawaited(_mistake(mk, global));
          } else {
            unawaited(_levelDelta(5, global, mood: GuideMood.glad));
            unawaited(_sayChain([_task]));
          }
          return;
        }
      }
      for (final (i, pit) in st.pits.indexed) {
        if (geo.pitHit(geo.pitAt(pit.path, pit.t)).contains(p)) {
          if (_run.canOpenPit(i)) {
            _tick('sounds/intro/impact_metal.ogg', 0.4);
            setState(() {
              _run.openPit(i);
              _lift = 0;
              _liftDrag = 0;
              _beam = null;
              _beamBins.clear();
              _wake++;
            });
            unawaited(_sayChain([M5CrlLines.askCover]));
          } else {
            _hints.missTap();
          }
          return;
        }
      }
    }
    _hints.missTap();
  }

  Offset _walkerFeet(M5CrlGeo g) => switch (_run.stage) {
        M5CrlStage.measure || M5CrlStage.sweep || M5CrlStage.dig => g.ownAt(_wheelT),
        M5CrlStage.tdr => g.gate,
        _ => g.ownAt(_run.walked),
      };

  void _down(PointerDownEvent e) {
    final g = _geoNow;
    if (g == null || !_streetLive) return;
    _drag = _Drag.none;
    _dragDead = false;
    _dragFrom = e.localPosition;
    switch (_run.stage) {
      case M5CrlStage.map || M5CrlStage.walk:
        if ((e.localPosition - g.ownAt(_run.walked)).distance > 40) return;
        _drag = _Drag.walk;
      case M5CrlStage.measure:
        if ((e.localPosition - g.ownAt(_wheelT)).distance > 40) return;
        _drag = _Drag.wheel;
      case M5CrlStage.sweep:
        _drag = _Drag.mic;
        _micAt(e.localPosition);
        _holdAnchor = e.localPosition;
        _armHold();
        _thumpTimer?.cancel();
        _thumpTimer = Timer.periodic(const Duration(milliseconds: m5CrlThumpMs), (_) => _thump());
        _thump();
      default:
        break;
    }
  }

  void _move(PointerMoveEvent e) {
    final g = _geoNow;
    if (g == null || _drag == _Drag.none || _dragDead) return;
    if (!_streetLive) {
      _endDrag();
      return;
    }
    final p = e.localPosition;
    switch (_drag) {
      case _Drag.walk:
        if ((p - _dragFrom).distance < 8) return;
        if (holdForCoworker()) {
          _dragDead = true;
          return;
        }
        if (!_run.mapRead) {
          _dragDead = true;
          final m = _run.startWalk();
          setState(() => _wake++);
          if (m != null) unawaited(_mistake(m, e.position));
          return;
        }
        final own = g.nearOwn(p);
        final other = g.nearOther(p);
        if (other.d < own.d && other.d < 26 && other.s > 22) {
          _dragDead = true;
          final m = _run.traceOther();
          setState(() => _wake++);
          if (m != null) unawaited(_mistake(m, e.position));
          return;
        }
        if (own.d > 32 || own.s > _run.walked * g.ownLength + 56) return;
        final was = _run.stage;
        final m = _run.traceTo(own.s / g.ownLength);
        setState(() => _wake++);
        if (m != null) {
          _dragDead = true;
          unawaited(_mistake(m, e.position));
          return;
        }
        if (was == M5CrlStage.walk && _run.stage == M5CrlStage.walkDone) {
          _dragDead = true;
          _tick('sounds/intro/confirm.ogg', 0.5);
          unawaited(_sayChain([_task]));
        }
      case _Drag.wheel:
        final own = g.nearOwn(p);
        final other = g.nearOther(p);
        if (other.d < own.d && other.d < 26 && other.s > 22) {
          _dragDead = true;
          final m = _run.traceOther();
          setState(() => _wake++);
          if (m != null) unawaited(_mistake(m, e.position));
          return;
        }
        if (own.d > 32 || (own.s - _wheelT * g.ownLength).abs() > 56) return;
        setState(() => _wheelT = own.s / g.ownLength);
      case _Drag.mic:
        final was = _mic;
        if (was != null) _sweepTravel += (p - was).distance;
        _micAt(p);
        if ((p - _holdAnchor).distance > 6) {
          _holdAnchor = p;
          _armHold();
        }
      case _Drag.none:
        break;
    }
  }

  void _up(PointerEvent e) {
    final drag = _drag;
    final dead = _dragDead;
    _endDrag();
    if (dead || !_streetLive) return;
    if (drag == _Drag.wheel) {
      final m = (_wheelT * _street.routeMetres).roundToDouble();
      // A touch with no push (the wheel where it last stopped) is no stop.
      if ((m - _wheelLastM).abs() < 2) return;
      _wheelLastM = m;
      _tick('sounds/intro/click.ogg', 0.5);
      final mk = _run.measure(m);
      setState(() => _wake++);
      if (mk != null) {
        unawaited(_mistake(mk, e.position));
        return;
      }
      _sweepTravel = 0;
      _sweepThumps = 0;
      unawaited(_sayChain([M5CrlLines.askSweep]));
    }
  }

  void _endDrag() {
    _drag = _Drag.none;
    _holdTimer?.cancel();
    _thumpTimer?.cancel();
    _holdTimer = null;
    _thumpTimer = null;
  }

  void _micAt(Offset p) {
    setState(() => _mic = p);
  }

  void _armHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: m5CrlHoldMs), _chalk);
  }

  /// The microphone's distance from the thump peak, metres: along the route
  /// and across it (so a bend never brings a far spot near).
  double _metresFromPeak(Offset p) {
    final g = _geoNow!;
    final n = g.nearOwn(p);
    final along = (n.s - _street.peakT * g.ownLength).abs();
    return math.sqrt(along * along + n.d * n.d) / g.ownLength * _street.routeMetres;
  }

  /// One thump of the van: heard at the microphone now.
  void _thump() {
    final mic = _mic;
    if (!mounted || mic == null || _geoNow == null || _run.stage != M5CrlStage.sweep) return;
    final loud = m5CrlLoudness(_metresFromPeak(mic));
    setState(() {
      _level = loud;
      _thumps++;
      _sweepThumps++;
    });
    _cue('sounds/learn/knock_solid.ogg', volume: 0.08 + 0.8 * loud);
  }

  void _chalk() {
    final mic = _mic;
    if (!mounted || mic == null || !_streetLive || _run.stage != M5CrlStage.sweep) return;
    // No chalk before the player has listened: the mic moved, thumps heard.
    if (_sweepTravel < m5CrlSweepTravel || _sweepThumps < m5CrlSweepThumps) {
      _armHold();
      return;
    }
    final far = _metresFromPeak(mic);
    _endDrag();
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    final m = _run.chalk(far);
    setState(() => _wake++);
    final box = _touchKey.currentContext?.findRenderObject();
    final global = box is RenderBox && box.attached ? box.localToGlobal(mic) : Offset.zero;
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    setState(() {
      _chalkAt = mic;
      _mic = null;
    });
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    unawaited(_sayChain([M5CrlLines.askDig]));
  }

  // --- the pit close-up -----------------------------------------------------------
  void _pitDown(PointerDownEvent e, Size size) {
    if (!_canPlay || _run.pitOpen == null) return;
    _liftDrag = 0;
    if (_run.pitStage != M5CrlPitStage.cover) _torch(e.localPosition, size);
  }

  void _pitMove(PointerMoveEvent e, Size size) {
    if (!_canPlay || _run.pitOpen == null) return;
    if (_run.pitStage == M5CrlPitStage.cover) {
      _liftDrag += e.delta.dy;
      setState(() => _lift = (-_liftDrag / (size.height * 0.7)).clamp(0.0, 1.0));
      return;
    }
    _torch(e.localPosition, size);
  }

  void _pitUp(Size size) {
    if (!_canPlay || _run.pitOpen == null || _run.pitStage != M5CrlPitStage.cover) return;
    if (_lift >= 0.45) {
      _tick('sounds/learn/dull_steel.ogg', 0.5);
      setState(() {
        _lift = 1;
        _run.liftCover();
        _wake++;
      });
      unawaited(_sayChain([M5CrlLines.askTorch]));
    } else {
      setState(() => _lift = 0);
    }
  }

  void _torch(Offset p, Size size) {
    final hole = (Offset.zero & size).deflate(14);
    final c = Offset(p.dx.clamp(hole.left, hole.right), p.dy.clamp(hole.top, hole.bottom));
    final bin = ((c.dx - hole.left) / hole.width * 10).floor().clamp(0, 9);
    setState(() {
      _beam = c;
      _beamBins.add(bin);
    });
    if (_run.pitStage == M5CrlPitStage.torch && _beamBins.length >= 7) {
      setState(() => _run.torchDone());
      unawaited(_sayChain([M5CrlLines.askPit], mood: GuideMood.think));
    }
  }

  void _decidePit(bool pin, Offset global) {
    if (!_canPlay || _run.pitOpen == null || _run.pitStage != M5CrlPitStage.decide) return;
    _tick(pin ? 'sounds/learn/tag_slap.ogg' : 'sounds/learn/dull_steel.ogg', 0.5);
    final m = _run.decidePit(pin);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    if (pin) unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    unawaited(_sayChain([_task]));
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final why = _run.why;
    final spot = _run.spotKind ?? M5CrlSpotKind.chalk;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5CrlLines.whyRight(why, spot), M5CrlLines.myths, widget.rng),
      question: M5CrlLines.whyQ[why]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
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
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5CrlLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.roundDone || _run.index != _run.deal.pushStreet) return null;
    switch (_run.deal.push) {
      case M5CrlPush.map:
        if (!_run.mapRead) return false;
        if (_run.stage != M5CrlStage.walk) return null;
      case M5CrlPush.team:
        if (_run.stage.index < M5CrlStage.tdr.index) return false;
        if (_run.stage != M5CrlStage.tdr) return null;
    }
    if (_intro || _card != null || tableBusy || _run.pitOpen != null || _phoneOpen || _tdrBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      unawaited(_mistake(_run.listened(_run.deal.push), origin));
      return;
    }
    _run.heldCoworker = true;
    _run.caught.add(M5CrlLines.caughtCoworker);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5CrlLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5CrlLines.tapWhy[_nudgeN++ % M5CrlLines.tapWhy.length]
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
    _endDrag();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    _endDrag();
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('crl/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same street goes on from where it was.
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? M5CrlLines.fail : (_quickBonus ? M5CrlLines.quick : M5CrlLines.allSet),
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

  // --- the gesture hand --------------------------------------------------------
  Object get _hintKey => '${_run.index}/${_run.stage.name}/${_run.pitOpen}/${_run.pitStage.name}/$_mapOpen/$_phoneOpen/${_run.spotKnown}';

  bool get _hintWaiting {
    final playing = !_intro && _mark == null && !struckOut;
    if (!playing || !_canPlay || _tdrUp || _tdrBusy || _drag != _Drag.none) return false;
    if (_run.stage == M5CrlStage.tdr && !_tdrUp) return false;
    return true;
  }

  /// How to touch now (never what): a sweep over the whole kit row (the phone
  /// and the peg alike, no timing), a generic drag of the walker / the wheel,
  /// a drag up on a pit cover, a torch arc, a sweep over the pit's two calls,
  /// a slow drag then a hold for the microphone; on the map card, its one
  /// button; on the phone, every row and the hang-up alike.
  HintSpec? _hint() {
    final key = _hintKey;
    if (key != _hintKeyNow) {
      _hintKeyNow = key;
      _hintShows = 0;
    }
    final geo = _geoNow;
    if (geo == null) return null;
    if (_mapOpen) return HintSpec.tapOn(_mapCloseKey);
    if (_phoneOpen) return HintSpec.sweepOver([for (final c in _street.contacts) _contactKeys[c]!, _hangKey]);
    if (_run.pitOpen != null) {
      final r = HintSpec.globalRectOf(_pitKey);
      if (r == null) return null;
      return switch (_run.pitStage) {
        M5CrlPitStage.cover => HintSpec.drag(r.center, toward: const Offset(0, -1), travel: 70),
        M5CrlPitStage.torch => HintSpec.swipe(Offset(r.left + 40, r.center.dy), toward: const Offset(1, 0), travel: math.min(110, r.width - 80)),
        M5CrlPitStage.decide => HintSpec.sweepOver([_pinKey, _closeKey]),
      };
    }
    final row = HintSpec.sweepOver([for (final t in _tools) _toolKeys[t]!]);
    if (_run.spotKnown) return row;
    switch (_run.stage) {
      case M5CrlStage.walk:
        return HintSpec.drag(geo.ownAt(_run.walked).translate(0, -20), toward: const Offset(0.2, -1), travel: 60, space: HintSpace.scene);
      case M5CrlStage.measure:
        return HintSpec.drag(geo.ownAt(_wheelT).translate(0, -20), toward: const Offset(0.2, -1), travel: 60, space: HintSpace.scene);
      case M5CrlStage.sweep:
        final at = Offset(180, (geo.top + geo.gateY) / 2);
        return _hintShows++ < 2 ? HintSpec.drag(at, toward: const Offset(1, 0), travel: 80, space: HintSpace.scene) : HintSpec.hold(at, space: HintSpace.scene);
      default:
        return row;
    }
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_drag == _Drag.walk || _drag == _Drag.wheel) return LinemanMode.walk;
    if (_run.stage == M5CrlStage.sweep) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M5CrlRig _rig(M5CrlGeo g) {
    final st = _street;
    final wheelM = _run.wheelM;
    return M5CrlRig(
      marks: [for (final (i, m) in st.marks.indexed) M5CrlSpot(g.markAt(m.path, m.t), pinned: _run.pinnedMarks.contains(i))],
      pits: [
        for (final (i, p) in st.pits.indexed)
          M5CrlSpot(g.pitAt(p.path, p.t),
              pinned: _run.resolvedPits.contains(i) && p.burnt, open: _run.pitOpen == i || (_run.resolvedPits.contains(i) && p.burnt)),
      ],
      walkedT: _run.walked,
      van: _run.teamOn,
      wheelChalk: wheelM == null ? null : g.ownAt(wheelM / st.routeMetres),
      chalk: _chalkAt,
      peg: _pegAt,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5CrlGeo.forScene(m.height, m.inset, _street.plan);
    final quiet = _quiet;
    final feet = _walkerFeet(geo);
    final mic = _mic;
    final wheel = _run.stage == M5CrlStage.measure;
    return [
      Positioned.fill(
        key: ValueKey('street-${_run.index}'),
        child: RepaintBoundary(child: CustomPaint(painter: M5CrlStreetPainter(geo: geo, rig: _rig(geo), seed: 11 + _run.index * 7 + _street.plan.layout))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.walkerBox(feet),
        child: IgnorePointer(child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
      ),
      if (wheel)
        Positioned(
          key: const ValueKey('wheel-count'),
          left: (feet.dx + 16).clamp(4.0, 290.0),
          top: feet.dy - 52,
          child: IgnorePointer(child: _Chip(text: '${(_wheelT * _street.routeMetres).round()} m', icon: Icons.straighten_rounded)),
        ),
      if (mic != null)
        Positioned(
          key: const ValueKey('mic'),
          left: mic.dx - 18,
          top: mic.dy - 18,
          width: 36,
          height: 36,
          child: IgnorePointer(child: _MicDisc(pulse: _thumps, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5CrlLines.sceneLabel,
          child: Listener(
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: _up,
            child: GestureDetector(
              key: _touchKey,
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            ),
          ),
        ),
      ),
      // The next street: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp || (_tdrUp && playing && !coworkerOpen);
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final st = _street;
    final pit = _run.pitOpen;
    final showTdr = playing && _run.teamOn && _run.stage.index <= M5CrlStage.tdr.index && !coworkerOpen;
    final tdrKnown = !st.tdrBlank || _run.armDone;
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
              labels: M5CrlLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 2); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !_run.done)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 10,
                  top: pad.top + 66,
                  child: IgnorePointer(child: _Chip(text: '${M5CrlLines.docket} · ${st.ownFeeder}', icon: Icons.assignment_rounded)),
                ),
              if (playing && _run.stage.index >= M5CrlStage.measure.index && !_run.done)
                Positioned(
                  key: const ValueKey('tdr-chip'),
                  right: 10,
                  top: pad.top + 66,
                  child: IgnorePointer(child: _Chip(text: '${M5CrlLines.tdr} ${st.tdrMetres} m', icon: Icons.show_chart_rounded)),
                ),
              if (playing && _run.stage == M5CrlStage.sweep)
                Positioned(
                  key: const ValueKey('level-bar'),
                  right: 10,
                  top: pad.top + 104,
                  child: IgnorePointer(child: _LevelBar(level: _level)),
                ),
              if (showTdr)
                Positioned(
                  key: const ValueKey('tdr-screen'),
                  left: 0,
                  right: 0,
                  top: pad.top + 104,
                  child: IgnorePointer(
                    child: Center(
                      child: _TdrScreen(
                        at: tdrKnown ? (st.tdrMetres / 500).clamp(0.05, 0.95) : null,
                        arc: _run.armDone,
                        readout: tdrKnown && _tdrReady ? '${st.tdrMetres} m' : M5CrlLines.tdrBlank,
                      ),
                    ),
                  ),
                ),
              if (handsOn && !_mapOpen && !_phoneOpen && pit == null)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in _tools)
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _icons[t]!,
                          label: M5CrlLines.toolLabel(t),
                          onTap: (g) => _useTool(t, g),
                        ),
                    ],
                  ),
                ),
              if (handsOn && pit != null)
                Positioned(
                  key: ValueKey('pit-$pit'),
                  left: 16,
                  right: 16,
                  top: pad.top + 120,
                  child: _PitView(
                    boxKey: _pitKey,
                    pinKey: _pinKey,
                    closeKey: _closeKey,
                    burnt: st.pits[pit].burnt,
                    lift: _lift,
                    beam: _beam,
                    deciding: _run.pitStage == M5CrlPitStage.decide,
                    onDown: _pitDown,
                    onMove: _pitMove,
                    onUp: _pitUp,
                    onDecide: _decidePit,
                  ),
                ),
              if (_mapOpen && playing && !coworkerOpen && _card == null && _geoNow != null)
                Positioned(
                  key: ValueKey('map-${_run.index}'),
                  left: 14,
                  right: 14,
                  top: pad.top + 96,
                  child: _MapCard(
                    geo: _geoNow!,
                    docket: st.ownFeeder,
                    ownLabel: st.ownFeeder,
                    otherLabel: st.otherFeeder,
                    height: math.min(420, size.height * 0.52),
                    closeKey: _mapCloseKey,
                    onClose: _closeMap,
                  ),
                ),
              if (_phoneOpen && playing && _card == null)
                Positioned(
                  key: const ValueKey('phone-sheet'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: _PhoneSheet(
                    contacts: st.contacts,
                    called: _run.called,
                    replies: st.replies,
                    keys: _contactKeys,
                    hangKey: _hangKey,
                    onCall: _call,
                    onHang: _hangUp,
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('tdr-deck-${_run.index}'),
                                options: _tdrOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _tdrWrong,
                                picked: _tdrPicked,
                                onPick: (o, at) => unawaited(_pickTdr(o, at)),
                              ),
                  ),
                ),
              // The guide stands on the far side from the gate (the trunk runs up
              // from it); away from the coworker while he peeps. Off while the
              // map card or the phone is up (the phone grows with each reply and
              // would slide under him).
              if (playing && _card == null && !_mapOpen && !_phoneOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerOnScreen ? coworkerFromRight : st.plan.mirror),
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
                  line: M5CrlLines.intro,
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

  static const _icons = {
    M5CrlTool.map: Icons.map_rounded,
    M5CrlTool.team: Icons.groups_rounded,
    M5CrlTool.phone: Icons.phone_in_talk_rounded,
    M5CrlTool.peg: Icons.push_pin_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: SlmColors.gold300),
          const SizedBox(width: 5),
          Text(text, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}

/// The ground microphone at the finger; a soft ring on each thump.
class _MicDisc extends StatelessWidget {
  const _MicDisc({required this.pulse, required this.quiet});
  final int pulse;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!quiet && pulse > 0)
          TweenAnimationBuilder<double>(
            key: ValueKey('thump-$pulse'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            builder: (_, v, _) => v >= 0.999
                ? const SizedBox.shrink()
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color.fromRGBO(255, 236, 170, 1 - v), width: 2 + 4 * (1 - v)),
                    ),
                  ),
          ),
        Center(
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1C2E4A),
              border: Border.all(color: SlmColors.gold300, width: 2),
            ),
            child: const Icon(Icons.mic_rounded, size: 16, color: SlmColors.gold300),
          ),
        ),
      ],
    );
  }
}

/// The headphone level: ten bars, lit up to the thump's loudness.
class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.level});
  final double level;

  @override
  Widget build(BuildContext context) {
    final lit = (level * 10).round();
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: const Color(0xEE101A2B), borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.headphones_rounded, size: 18, color: SlmColors.gold300),
          const SizedBox(height: 4),
          for (var i = 9; i >= 0; i--)
            Container(
              width: 18,
              height: 6,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < lit ? Color.lerp(const Color(0xFF59E39A), const Color(0xFFF2C14E), i / 9) : const Color(0x33FFFFFF),
              ),
            ),
        ],
      ),
    );
  }
}

class _TdrScreen extends StatelessWidget {
  const _TdrScreen({required this.at, required this.arc, required this.readout});
  final double? at;
  final bool arc;
  final String readout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xF0101A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(M5CrlLines.tdr, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
              const Spacer(),
              Text(readout, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(height: 70, width: double.infinity, child: CustomPaint(painter: M5CrlTdrPainter(at: at, arc: arc))),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.geo,
    required this.docket,
    required this.ownLabel,
    required this.otherLabel,
    required this.height,
    required this.closeKey,
    required this.onClose,
  });

  final M5CrlGeo geo;
  final String docket;
  final String ownLabel;
  final String otherLabel;
  final double height;
  final GlobalKey closeKey;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xF2101A2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, size: 18, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Flexible(
                child: Text(M5CrlLines.mapTitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${M5CrlLines.docket} · $docket',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height - 110,
            width: double.infinity,
            child: CustomPaint(
              painter: M5CrlMapPainter(
                geo: geo,
                ownLabel: ownLabel,
                otherLabel: otherLabel,
                labelStyle: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF3A1C12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: M5CrlLines.mapClose,
            excludeSemantics: true,
            child: GestureDetector(
              key: closeKey,
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: SlmColors.gold300, borderRadius: BorderRadius.circular(24)),
                child: Text(M5CrlLines.mapClose, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.navy950)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitView extends StatelessWidget {
  const _PitView({
    required this.boxKey,
    required this.pinKey,
    required this.closeKey,
    required this.burnt,
    required this.lift,
    required this.beam,
    required this.deciding,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onDecide,
  });

  final GlobalKey boxKey;
  final GlobalKey pinKey;
  final GlobalKey closeKey;
  final bool burnt;
  final double lift;
  final Offset? beam;
  final bool deciding;
  final void Function(PointerDownEvent, Size) onDown;
  final void Function(PointerMoveEvent, Size) onMove;
  final void Function(Size) onUp;
  final void Function(bool pin, Offset global) onDecide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xF2101A2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.6), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M5CrlLines.pitTitle, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, 190);
              return Semantics(
                label: M5CrlLines.pitTitle,
                child: Listener(
                  key: boxKey,
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => onDown(e, size),
                  onPointerMove: (e) => onMove(e, size),
                  onPointerUp: (_) => onUp(size),
                  onPointerCancel: (_) => onUp(size),
                  child: SizedBox.fromSize(
                    size: size,
                    child: CustomPaint(painter: M5CrlPitPainter(burnt: burnt, lift: lift, beam: beam, beamR: 34)),
                  ),
                ),
              );
            },
          ),
          if (deciding) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                _PillButton(key: pinKey, label: M5CrlLines.pitPin, icon: Icons.flag_rounded, onTap: (g) => onDecide(true, g)),
                _PillButton(key: closeKey, label: M5CrlLines.pitClose, icon: Icons.check_box_outline_blank_rounded, onTap: (g) => onDecide(false, g)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PhoneSheet extends StatelessWidget {
  const _PhoneSheet({
    required this.contacts,
    required this.called,
    required this.replies,
    required this.keys,
    required this.hangKey,
    required this.onCall,
    required this.onHang,
  });

  final List<M5CrlContact> contacts;
  final Set<M5CrlContact> called;
  final Map<M5CrlContact, int> replies;
  final Map<M5CrlContact, GlobalKey> keys;
  final GlobalKey hangKey;
  final ValueChanged<M5CrlContact> onCall;
  final VoidCallback onHang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xF2101A2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.6), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, size: 18, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Text(M5CrlLines.phoneTitle, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          for (final c in contacts)
            Semantics(
              button: true,
              label: M5CrlLines.contactName(c),
              excludeSemantics: true,
              child: GestureDetector(
                key: keys[c],
                behavior: HitTestBehavior.opaque,
                onTap: () => onCall(c),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1C2E4A), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(called.contains(c) ? Icons.check_circle_rounded : Icons.call_rounded,
                          size: 20, color: called.contains(c) ? SlmColors.success : SlmColors.gold300),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(M5CrlLines.contactName(c), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                            if (called.contains(c))
                              Text(M5CrlLines.reply(c, replies[c] ?? 0), style: bangla(fontSize: 12, fontWeight: FontWeight.w600, color: SlmColors.ivory)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Center(child: _PillButton(key: hangKey, label: M5CrlLines.phoneHang, icon: Icons.call_end_rounded, onTap: (_) => onHang())),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final ValueChanged<Offset> onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2E4A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: SlmColors.gold300),
              const SizedBox(width: 6),
              Text(label, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A kit button: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: SlmColors.gold300),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
