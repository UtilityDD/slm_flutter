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
import 'm5_culprit_case_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_culprit_case_world.dart' show M5Anchor, M5Clue, M5Culprit, M5CulpritGeo, M5Light, M5Placed, M5View;

// Lesson 5.3 "সাধারণ ফল্ট: অপরাধীদের প্যারেড", কাজ 1 "অপরাধী কে? সূত্রের সুতো"
// (pack do_5_3_a, engineType m5_culprit_case). The morning after a night trip
// on a rural 11 kV feeder; the line is off and earthed (docket "ফিডার N · ট্রিপ
// · PTW · আর্থ লাগানো"). Three fault spots, dealt fresh every play:
//
//  1. Shoot: raise the phone, drag to aim, pinch (or ±) to zoom, tap the
//     shutter. A shot from too far comes out blurry and is not pinned (the
//     guide says so only after a blurry shot). Nothing tells right from wrong
//     while shooting: each spot has 2–4 real clues (lesson 5.3's "সূত্র") and
//     2–3 decoys that look like the same kind of thing; a shot of plain
//     scenery is pinned too. At some spots a villager at the tea stall says
//     "রাতে বিস্ফোরণের মতো শব্দ হয়েছিল!" (pro tip 3) — a sound card. He comes
//     wherever a blast fits (bird, LA, kite, insulator flashover, a branch
//     across two wires), so he never names one culprit.
//  2. Case board: drag threads from the photo pins to the culprit cards (four
//     dealt, the true one among them); two threads charge a culprit. Every
//     card has a "তারপর →" knob (a chain: cracked insulator → sagged wire →
//     branch, pro tip 2, at one spot in half the plays). Slots by the picked
//     culprit, not by the truth: "ফল্টের ধরন?" (ফেজ-টু-আর্থ / ফেজ-টু-ফেজ, only
//     for a tree or an insulator) and "করণীয়?" (1 right + 2 wrong; none for LA
//     and kite — the lesson gives them no remedy).
//  3. "কেস বন্ধ": the first wrong element → its MistakeCard (one slip per
//     close); right → a stamp, ◆ on the table → "কেন …?" → the next spot.
//
// The bird spot is in every play: the careless coworker comes as its board
// opens (lesson myth 2, word for word) and the board waits for him
// (holdForCoworker). Half the bird spots carry collateral damage (a flash
// mark on an insulator) that changes the right remedy; every bird deck holds
// one "no damage" and one "replace" card either way. A remedy deck is dealt
// once per spot and pick, so re-opening the slot shows the same cards.
//
// Slips: a decoy (or plain scenery) threaded as evidence; a wrong culprit; a
// chain spot without the chain (one end only, unlinked, or reversed); a
// wrong fault type; a wrong remedy; "no damage" when the bird did damage;
// listening to the coworker.
// Deadly (module 5 table R8, ruling M5-1): a plan to charge the faulted line
// to test it ("লাইন চার্জ করে দেখি …") — on the remedy deck in half the spots.
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_culprit_case_world.dart), corner guide, ◆ on the table → "কেন …?",
// the coworker's two beats, gesture hints for every waiting state (how, never
// what), mistake cards with lesson points, the deadly freeze, idle = zero
// frames. Voice: the guide and the villager by device TTS; the coworker's push
// has no clip yet (silent, caption held) and his exit line is his clip.

// ============================================================================
// Content
// ============================================================================

/// The fault types the lesson names for a tree or an insulator.
enum M5FaultType { phaseEarth, phasePhase }

/// What a spot's reason asks about.
enum M5Why { culprit, type, remedy, chain, bird }

/// The remedy decks (by the picked culprit).
enum M5Remedy { tree, insulator, jumper, birdClean, birdHurt, chain }

abstract final class M5CulpritLines {
  static const title = 'অপরাধী কে? সূত্রের সুতো';
  static const intro = 'রাতে ফিডার ট্রিপ করেছে। লাইন বন্ধ, আর্থ লাগানো। এবার অপরাধী ধরুন!';
  static const spots = ['স্পট 1', 'স্পট 2', 'স্পট 3'];

  // The guide's task now (tap him: the same task, a different way).
  static const askShoot = 'সূত্রের ছবি তুলুন।';
  static const askAim = 'ফ্রেমে এনে শাটার টিপুন।';
  static const askBoard = 'সূত্র মিলিয়ে অপরাধী ধরুন।';
  static const askSlots = 'কেস বন্ধের আগে ঘরগুলো ভরুন।';
  static const tasks = [askShoot, askAim, askBoard, askSlots];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const blurry = 'ছবিটা ঝাপসা। কাছে এনে তুলুন।';

  /// The villager at the tea stall (device TTS; lesson 5.3 pro tip 3).
  static const villager = 'রাতে বিস্ফোরণের মতো শব্দ হয়েছিল!';

  // Labels a worker reads.
  static const sceneLabel = 'ফল্টের জায়গা';
  static const phone = 'ফোন';
  static const board = 'কেস বোর্ড';
  static const shutter = 'ছবি তুলুন';
  static const lower = 'নামান';
  static const zoomIn = 'জুম বাড়ান';
  static const zoomOut = 'জুম কমান';
  static const back = 'ফিরে যান';
  static const close = 'কেস বন্ধ';
  static const typeSlot = 'ফল্টের ধরন?';
  static const remedySlot = 'করণীয়?';
  static const knob = 'তারপর →';
  static const sound = 'শব্দ';
  static const stamp = 'সমাধান';
  static String docket(int feeder) => enDigits('ফিডার $feeder · ট্রিপ · PTW · আর্থ লাগানো');

  static String culprit(M5Culprit c) => switch (c) {
        M5Culprit.tree => 'গাছের ডাল',
        M5Culprit.insulator => 'ইনসুলেটর',
        M5Culprit.jumper => 'জাম্পার/তার',
        M5Culprit.bird => 'পাখি/জন্তু',
        M5Culprit.la => 'LA',
        M5Culprit.kite => 'ঘুড়ি',
      };

  static String faultType(M5FaultType t) => switch (t) {
        M5FaultType.phaseEarth => 'ফেজ-টু-আর্থ',
        M5FaultType.phasePhase => 'ফেজ-টু-ফেজ',
      };

  // The remedy decks (lesson 5.3 "করণীয়"; the wrong ones are field shortcuts
  // and the lesson's myths). 36–44 letters.
  static const remedyRight = <M5Remedy, List<String>>{
    M5Remedy.tree: ['আগে ডাল সরানোর পরিকল্পনা, পরে তার-পোল দেখি', 'বন দপ্তরের সাহায্যে ডাল সরিয়ে তবে মেরামত'],
    M5Remedy.insulator: ['ক্রস-আর্ম দেখে ক্ষতিগ্রস্ত ইনসুলেটর বদলে দিই', 'নিয়মমতো নতুন ইনসুলেটর বসাই, আর্মও দেখি'],
    M5Remedy.jumper: ['পোড়া কানেক্টর বদলাই, তার নরম কিনা দেখি', 'গলা ক্ল্যাম্প বদলে তারের পোড়া অংশ পরীক্ষা'],
    M5Remedy.birdClean: _birdCleanRight,
    M5Remedy.birdHurt: _birdHurtRight,
    M5Remedy.chain: ['ফাটা ইনসুলেটর বদলাই, ডাল সরাই, তার দেখি', 'শুধু ডাল নয়, ইনসুলেটর বদলে তারও পরীক্ষা'],
  };

  /// The deadly plan (module 5 R8): charge the faulted line to test it.
  static const charge = 'লাইন চার্জ করে দেখি, টিকলে সব ঠিক আছে';

  // Only the deadly plan above re-energizes the line; the slip cards below are
  // shortcuts that never charge it (one act, one class).
  static const _birdCleanRight = ['পাখি সরিয়ে ইনসুলেটর-তার দেখি, ক্ষতি নেই', 'পাখি সরাই, যন্ত্রাংশ পরীক্ষা করে অক্ষত পাই'];
  static const _birdHurtRight = ['পাখি সরিয়ে পোড়া ইনসুলেটরটা বদলে দিই', 'পাখি সরাই, ক্ষতিগ্রস্ত ইনসুলেটর বদলাই'];
  static const _remedyShared = ['রিপোর্ট লিখে রাখি, মেরামত পরের সপ্তাহে', 'যেমন আছে থাক, ট্রিপ তো একবারই হয়েছে'];
  static const _birdWrong = ['পাখিটা সরালেই হলো, আর কিছু দেখার নেই', 'পাখি থাক, কাক-চিল এমনিই ওটা সরিয়ে নেবে'];

  /// The third card of a bird deck (neither "no damage" nor "replace").
  static const birdOther = [..._birdWrong, ..._remedyShared];
  static const _treeWrong = ['ডালটা হাতে টেনে নামিয়ে কাজ শেষ করি', 'শুধু ডাল সরাই, তার-পোল দেখার দরকার নেই', 'ডাল তারেই থাক, শুকিয়ে নিজেই পড়ে যাবে'];
  static const remedyWrong = <M5Remedy, List<String>>{
    M5Remedy.tree: [..._treeWrong, ..._remedyShared],
    M5Remedy.insulator: [
      'কালো দাগটা মুছে দিলেই ইনসুলেটর আবার চলবে',
      'ফাটলে টেপ জড়িয়ে ইনসুলেটরটা রেখে দিই',
      'ইনসুলেটর বদলাই, ক্রস-আর্ম দেখার দরকার নেই',
      ..._remedyShared,
    ],
    M5Remedy.jumper: [
      'গলা ক্ল্যাম্পে টেপ জড়িয়ে রেখে দিই',
      'শুধু কানেক্টর বদলাই, তার দেখার দরকার নেই',
      'ছেঁড়া তার পাকিয়ে গিঁট দিয়ে জুড়ে দিই',
      ..._remedyShared,
    ],
    M5Remedy.birdClean: [..._birdHurtRight, ..._birdWrong, ..._remedyShared],
    M5Remedy.birdHurt: [..._birdCleanRight, ..._birdWrong, ..._remedyShared],
    M5Remedy.chain: ['শুধু ডালটা সরাই, ইনসুলেটর পরে দেখা যাবে', 'ইনসুলেটর বদলাই, ডালটা তো নিজেই সরে যাবে', 'ডালটা হাতে টেনে নামিয়ে কাজ শেষ করি', 'শুধু ডাল সরাই, তার-পোল দেখার দরকার নেই', ..._remedyShared],
  };
  static List<String> get allRemedy => {
        charge,
        for (final l in remedyRight.values) ...l,
        for (final l in remedyWrong.values) ...l,
      }.toList();

  // The reasons: the right ones fit what was done at this spot; the wrong ones
  // are the lesson's myths and field excuses. 37–46 letters.
  static const whyCulpritQ = 'কেন এটাকেই অপরাধী ধরলেন?';
  static const whyTypeEarthQ = 'কেন এটা ফেজ-টু-আর্থ, ফেজ-টু-ফেজ নয়?';
  static const whyTypePhaseQ = 'কেন এটা ফেজ-টু-ফেজ, ফেজ-টু-আর্থ নয়?';
  static const whyRemedyQ = 'কেন এই করণীয় বেছে নিলেন?';
  static const whyChainQ = 'কেন ডালের আগে ইনসুলেটরকে দায়ী করলেন?';
  static const whyBirdQ = 'পাখি সরানোর পর আর কী দেখলেন, কেন?';

  static const whyCulprit = <M5Culprit, List<String>>{
    M5Culprit.tree: ['তারে ডালপালা আর আঘাতের চিহ্নই গাছের সূত্র', 'ডাল আর ঝুলে পড়া তার — দুটোই গাছের দিকে'],
    M5Culprit.insulator: ['ফাটল আর কালো কার্বন ট্র্যাকই ইনসুলেটরের প্রমাণ', 'পোড়া দাগ ফ্ল্যাশওভারের পথ দেখিয়ে দিয়েছে'],
    M5Culprit.jumper: ['গলা কানেক্টর আর বিবর্ণ জোড় হটস্পটের প্রমাণ', 'পোড়া, গলা ধাতু ফল্টের উৎসের দিকে নিয়ে যায়'],
    M5Culprit.bird: ['পোড়া পাখির দেহ আর রক্তের দাগই স্পষ্ট প্রমাণ', 'তারে রক্তের দাগ, নিচে পোড়া পাখি — এটাই সূত্র'],
    M5Culprit.la: ['বজ্রপাতের পর ফাটা LA আর ঝুলন্ত আর্থ লিড', 'বিস্ফোরিত LA আর ঝোলা আর্থিং — দুটোই সূত্র'],
    M5Culprit.kite: ['ধাতব মাঞ্জা সুতো দুটো তারকে ছুঁইয়ে দিয়েছে', 'তারে আটকানো ঘুড়ির ধাতব মাঞ্জাই শর্টের সূত্র'],
  };
  static const whyTreeEarth = ['ডাল তার ছুঁয়ে মাটিতে ঠেকেছে, তাই আর্থ ফল্ট', 'মাটিতে ঠেকা ডাল ফেজ থেকে আর্থে পথ দিয়েছে'];
  static const whyTreePhase = ['ডাল একসাথে দুটো তার ছুঁয়েছে, তাই ফেজ-ফেজ', 'দুই-তিনটি তার ডালে জোড়া লাগলে ফেজ-টু-ফেজ'];
  static const whyInsulatorEarth = ['ভাঙা ইনসুলেটর পরিষ্কার আর্থ ফল্ট তৈরি করে', 'প্রহরী ইনসুলেটর ভেঙেছে, তাই ফল্ট আর্থে গেছে'];
  static const whyRemedy = <M5Culprit, List<String>>{
    M5Culprit.tree: ['ডাল সরানো ঝুঁকির কাজ, তাই আগে পরিকল্পনা চাই', 'ডাল পড়লে তার, ইনসুলেটর, পোলেও ক্ষতি থাকে'],
    M5Culprit.insulator: ['কার্বন ট্র্যাক আবার ফ্ল্যাশওভার ঘটাবে', 'দাগ মোছা যায়, কিন্তু দুর্বল পথটা থেকেই যায়'],
    M5Culprit.jumper: ['হটস্পটে অ্যালুমিনিয়াম তার নরম হয়ে যেতে পারে', 'শুধু কানেক্টর নয়, তারের ক্ষতিও দেখতে হয়'],
  };
  static const whyChain = ['ইনসুলেটর ফেটে তার ঝুলেছে, তবেই ডাল ছুঁয়েছে', 'একটি ফল্ট অন্যটির জন্ম দেয় — শুরু ইনসুলেটরে'];
  static const whyBird = ['পাখি ইনসুলেটর বা তারের ক্ষতি করেছে কিনা দেখি', 'পাখি কারণ হলেও যন্ত্রাংশের ক্ষতি দেখতে হয়'];
  static const myths = [
    'পাখি সরালেই লাইন চালু, আর কিছু দেখার নেই',
    'কালো দাগ মুছে দিলেই ইনসুলেটর আবার ভালো',
    'প্রথম যা চোখে পড়ে, সেটাই তো আসল অপরাধী',
    'চার্জ করে দেখলেই ফল্ট নিজে থেকে বেরোয়',
    'ডাল সরালেই হলো, বাকিটা দেখার দরকার নেই',
    'রাতের ট্রিপ বাতাসে হয়, কারণ খোঁজা বৃথা',
    'ছবি তোলা সময় নষ্ট, রিপোর্টে কিছু লাগে না',
  ];
  static List<String> get allWhyRight => [
        for (final l in whyCulprit.values) ...l,
        ...whyTreeEarth,
        ...whyTreePhase,
        ...whyInsulatorEarth,
        for (final l in whyRemedy.values) ...l,
        ...whyChain,
        ...whyBird,
      ];

  /// The careless coworker at the bird spot: lesson 5.3 myth 2, word for word.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'একটা পাখি মরে পড়ে আছে, ওটাকে সরিয়ে দিলেই লাইন চালু করা যাবে।',
    exitLine: coworkerExit,
    right: [
      'না, আগে দেখি ইনসুলেটর-তারের ক্ষতি হয়েছে কিনা।',
      'না, পাখি সরিয়ে আগে ইনসুলেটর আর তার দেখব।',
      'না, পাখির শর্টে কোনো ক্ষতি হয়েছে কিনা দেখি।',
    ],
    wrong: [
      'হ্যাঁ, পাখিই তো কারণ, ওটা সরালেই তো হলো।',
      'ঠিক, পাখিটা ফেলে দিয়ে এখনই কাজ শেষ করি।',
      'আচ্ছা, পাখি সরিয়ে যন্ত্রপাতি গুছিয়ে নিই।',
      'হ্যাঁ, পাখি সরালে আর কিছু দেখার দরকার নেই।',
      'ঠিক আছে, সময় বাঁচাতে পাখি সরিয়েই ফিরে যাই।',
    ],
    asks: ['ওঁর কথা মানবেন?', 'পাখি সরালেই কি সব ঠিক?', 'কী করবেন — ওঁর কথা, না নিয়ম?'],
  );

  static const callHeld = 'ঠিক! পাখি সরানোর পরও ক্ষতি পরীক্ষা করতে হয়।';
  static const allSet = 'তিনটে কেসই বন্ধ — সূত্র দেখে অপরাধী, তারপর ঠিক করণীয়।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কাছে গিয়ে পরিষ্কার ছবি, তারপর সূত্র মিলিয়ে অপরাধী।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtPhoto = 'পরিষ্কার ছবিতে সূত্র ধরেছেন';
  static const caughtCulprit = 'সূত্রের সুতোয় আসল অপরাধী';
  static const caughtChain = 'একটি ফল্ট থেকে আরেকটি — চেইন ধরেছেন';
  static const caughtType = 'ফেজ-টু-আর্থ না ফেজ-টু-ফেজ — ঠিক ধরেছেন';
  static const caughtFix = 'অপরাধী বুঝে ঠিক করণীয়';
  static const caughtCall = 'পাখি সরালেই চালু — এই কথায় “না”';
}

abstract final class M5CulpritMistakes {
  static const _dir = 'assets/game/art/m5_culprit_case';
  static const _k = '5.3/m5_culprit_case';

  /// The lesson point (0-based) that teaches each culprit.
  static int pointOf(M5Culprit c) => switch (c) {
        M5Culprit.tree => 0,
        M5Culprit.insulator => 1,
        M5Culprit.jumper => 2,
        _ => 3,
      };

  static const decoy = DoMistake(
    key: '$_k/decoy',
    textBn: 'এটা ফল্টের সূত্র নয়! পোড়া দাগ, গলিত ধাতু, কালো হয়ে যাওয়া অংশ — আসল সূত্রই ফল্টের উৎস দেখায়।',
    art: '$_dir/decoy.svg',
  );
  static const culpritTree = DoMistake(
    key: '$_k/culprit-tree',
    textBn: 'অপরাধী গাছের ডাল! লাইনের ওপর ডালপালা, অস্বাভাবিকভাবে ঝুলে পড়া তার, ক্রস-আর্মে আঘাতের চিহ্ন — এগুলোই সূত্র।',
    art: '$_dir/culprit.svg',
    lessonPoint: 0,
  );
  static const culpritInsulator = DoMistake(
    key: '$_k/culprit-insulator',
    textBn: 'অপরাধী ইনসুলেটর! ফাটা বা ভাঙা ইনসুলেটর, খসে পড়া পোর্সেলিন, ফ্ল্যাশওভারের কালো পোড়া দাগ — এগুলোই সূত্র।',
    art: '$_dir/culprit.svg',
    lessonPoint: 1,
  );
  static const culpritJumper = DoMistake(
    key: '$_k/culprit-jumper',
    textBn: 'অপরাধী কানেকশন! গলে বা পুড়ে কালো PG ক্ল্যাম্প, বিবর্ণ জয়েন্ট বা স্লিভ, ছিঁড়ে পড়া কন্ডাক্টর — এগুলোই সূত্র।',
    art: '$_dir/culprit.svg',
    lessonPoint: 2,
  );
  static const culpritBird = DoMistake(
    key: '$_k/culprit-bird',
    textBn: 'অপরাধী পাখি! পোড়া পাখির দেহ আর তারের ওপর রক্তের দাগ একটি স্পষ্ট প্রমাণ।',
    art: '$_dir/culprit.svg',
    lessonPoint: 3,
  );
  static const culpritLa = DoMistake(
    key: '$_k/culprit-la',
    textBn: 'অপরাধী LA! বজ্রপাতের পর বিস্ফোরিত বা ভাঙা LA, আর তার নিচে ঝুলে থাকা আর্থিং কানেকশন — এগুলোই সূত্র।',
    art: '$_dir/culprit.svg',
    lessonPoint: 3,
  );
  static const culpritKite = DoMistake(
    key: '$_k/culprit-kite',
    textBn: 'অপরাধী ঘুড়ি! তারে আটকে থাকা ঘুড়ির ধাতব মাঞ্জা সুতো দুটি তারকে স্পর্শ করিয়ে ফল্ট ঘটায়।',
    art: '$_dir/culprit.svg',
    lessonPoint: 3,
  );
  static const chain = DoMistake(
    key: '$_k/chain',
    textBn: 'একটি ফল্ট অন্যটির জন্ম দেয়! ইনসুলেটর ফেটে তার ঝুলে পড়েছে, তারপর ডাল ছুঁয়েছে — শুরু ইনসুলেটরে, তারপর ডাল।',
    art: '$_dir/chain.svg',
  );
  static const typeTree = DoMistake(
    key: '$_k/type-tree',
    textBn: 'ডাল মাটিতে ঠেকে থাকলে ফেজ-টু-আর্থ, দুটি বা তিনটি তার একসাথে ছুঁলে ফেজ-টু-ফেজ ফল্ট।',
    art: '$_dir/fault_type.svg',
    lessonPoint: 0,
  );
  static const typeInsulator = DoMistake(
    key: '$_k/type-insulator',
    textBn: 'ভাঙা ইনসুলেটর একটি পরিষ্কার আর্থ ফল্ট তৈরি করে — ফেজ-টু-আর্থ।',
    art: '$_dir/fault_type.svg',
    lessonPoint: 1,
  );
  static const remedyTree = DoMistake(
    key: '$_k/remedy-tree',
    textBn: 'আগে ডাল সরানোর পরিকল্পনা, দরকারে বন দপ্তর বা বিশেষ টিম; তারপর কন্ডাক্টর, ইনসুলেটর আর পোল পরীক্ষা করে মেরামত।',
    art: '$_dir/remedy.svg',
    lessonPoint: 0,
  );
  static const remedyInsulator = DoMistake(
    key: '$_k/remedy-insulator',
    textBn: 'ক্ষতিগ্রস্ত ইনসুলেটর নিয়ম অনুযায়ী বদলাতেই হবে — কালো দাগ মুছে চলবে না। বদলানোর আগে ক্রস-আর্মও পরীক্ষা করুন।',
    art: '$_dir/remedy.svg',
    lessonPoint: 1,
  );
  static const remedyJumper = DoMistake(
    key: '$_k/remedy-jumper',
    textBn: 'পোড়া কানেক্টর বদলান, ছেঁড়া তার নিয়ম অনুযায়ী জয়েন্ট করুন, আর হটস্পটে তার নরম হয়েছে কিনা পরীক্ষা করুন।',
    art: '$_dir/remedy.svg',
    lessonPoint: 2,
  );
  static const remedyBird = DoMistake(
    key: '$_k/remedy-bird',
    textBn: 'পাখি সরিয়ে ইনসুলেটর আর কন্ডাক্টর পরীক্ষা করুন — যা পেলেন, সেই অনুযায়ী করণীয়।',
    art: '$_dir/remedy.svg',
    lessonPoint: 3,
  );
  static const remedyChain = DoMistake(
    key: '$_k/remedy-chain',
    textBn: 'শুধু ডাল সরালে হবে না — ফাটা ইনসুলেটর বদলান, ঝুলে পড়া তারের ক্ষতি দেখুন, ডালও সরান। পুরো চিত্রটা সারান।',
    art: '$_dir/remedy.svg',
  );
  static const birdDamage = DoMistake(
    key: '$_k/bird-damage',
    textBn: 'ক্ষতি আছে! পাখির শর্টে ইনসুলেটরে পোড়া দাগ — পাখি সরিয়ে ক্ষতিগ্রস্ত ইনসুলেটর বদলাতে হবে।',
    art: '$_dir/bird_damage.svg',
    lessonPoint: 3,
  );
  static const listen = DoMistake(
    key: '$_k/listen',
    textBn: 'পাখিটি হয়তো ফল্টের কারণ, কিন্তু সে ইনসুলেটর, কন্ডাক্টর বা অন্য যন্ত্রাংশের ক্ষতি করেছে কিনা আগে পরীক্ষা করতে হবে।',
    art: '$_dir/bird_check.svg',
    lessonPoint: 3,
  );

  /// Module 5 R8 (ruling M5-1): re-energizing a faulted line to test it.
  static const chargeTest = DoMistake(
    key: '$_k/charge-test',
    textBn: 'ফল্ট না সারিয়ে লাইন চার্জ করা কঠোরভাবে নিষিদ্ধ! আগে মেরামত, সবাই সরে, পারমিট ফেরত — তবেই চার্জ।',
    art: '$_dir/charge.svg',
    deadly: true,
  );

  static DoMistake culprit(M5Culprit c) => switch (c) {
        M5Culprit.tree => culpritTree,
        M5Culprit.insulator => culpritInsulator,
        M5Culprit.jumper => culpritJumper,
        M5Culprit.bird => culpritBird,
        M5Culprit.la => culpritLa,
        M5Culprit.kite => culpritKite,
      };

  static DoMistake remedy(M5Remedy r) => switch (r) {
        M5Remedy.tree => remedyTree,
        M5Remedy.insulator => remedyInsulator,
        M5Remedy.jumper => remedyJumper,
        M5Remedy.birdClean || M5Remedy.birdHurt => remedyBird,
        M5Remedy.chain => remedyChain,
      };

  static List<DoMistake> get all => [
        decoy,
        for (final c in M5Culprit.values) culprit(c),
        chain,
        typeTree,
        typeInsulator,
        remedyTree,
        remedyInsulator,
        remedyJumper,
        remedyBird,
        remedyChain,
        birdDamage,
        listen,
        chargeTest,
      ];
}

// ============================================================================
// The deal
// ============================================================================

/// The real clues of each culprit (lesson 5.3, "সূত্র").
const m5RealClues = <M5Culprit, List<M5Clue>>{
  M5Culprit.tree: [M5Clue.branch, M5Clue.sag, M5Clue.armScar],
  M5Culprit.insulator: [M5Clue.pinCrack, M5Clue.carbon, M5Clue.chips],
  M5Culprit.jumper: [M5Clue.pgMelt, M5Clue.sleeveHot, M5Clue.wireDown],
  M5Culprit.bird: [M5Clue.birdBody, M5Clue.blood],
  M5Culprit.la: [M5Clue.laBlown, M5Clue.laLead],
  M5Culprit.kite: [M5Clue.kiteWire, M5Clue.manja],
};

/// Decoys that look like each culprit's clues (no lesson fact: scenery).
const m5Decoys = <M5Culprit, List<M5Clue>>{
  M5Culprit.tree: [M5Clue.prunedPile, M5Clue.dryLeaves],
  M5Culprit.insulator: [M5Clue.dewInsulator, M5Clue.spareCrate],
  M5Culprit.jumper: [M5Clue.newClamp, M5Clue.wireCoil],
  M5Culprit.bird: [M5Clue.liveCrow, M5Clue.catRoof],
  M5Culprit.la: [M5Clue.earthPit, M5Clue.tapePole],
  M5Culprit.kite: [M5Clue.kiteTree, M5Clue.flagStall],
};

/// Where each clue can sit.
const m5AnchorsOf = <M5Clue, List<M5Anchor>>{
  M5Clue.branch: [M5Anchor.wireA],
  M5Clue.sag: [M5Anchor.wireB],
  M5Clue.armScar: [M5Anchor.armL, M5Anchor.armR],
  M5Clue.pinCrack: [M5Anchor.ins0, M5Anchor.ins1, M5Anchor.ins2],
  M5Clue.carbon: [M5Anchor.ins0, M5Anchor.ins1, M5Anchor.ins2],
  M5Clue.chips: [M5Anchor.g0, M5Anchor.g1],
  M5Clue.pgMelt: [M5Anchor.wireC, M5Anchor.wireD],
  M5Clue.sleeveHot: [M5Anchor.wireA, M5Anchor.wireB, M5Anchor.wireC, M5Anchor.wireD],
  M5Clue.wireDown: [M5Anchor.g0, M5Anchor.g1, M5Anchor.g3],
  M5Clue.birdBody: [M5Anchor.g0, M5Anchor.g1],
  M5Clue.blood: [M5Anchor.wireB, M5Anchor.wireC],
  M5Clue.birdFlash: [M5Anchor.ins0, M5Anchor.ins1, M5Anchor.ins2],
  M5Clue.laBlown: [M5Anchor.la],
  M5Clue.laLead: [M5Anchor.laLead],
  M5Clue.kiteWire: [M5Anchor.wireA, M5Anchor.wireC, M5Anchor.wireD],
  M5Clue.manja: [M5Anchor.wireB, M5Anchor.wireC],
  M5Clue.prunedPile: [M5Anchor.g2, M5Anchor.g3, M5Anchor.g0],
  M5Clue.dryLeaves: [M5Anchor.g0, M5Anchor.g1, M5Anchor.g3],
  M5Clue.dewInsulator: [M5Anchor.ins0, M5Anchor.ins1, M5Anchor.ins2],
  M5Clue.spareCrate: [M5Anchor.g2, M5Anchor.g3],
  M5Clue.newClamp: [M5Anchor.wireA, M5Anchor.wireB, M5Anchor.wireC, M5Anchor.wireD],
  M5Clue.wireCoil: [M5Anchor.g2, M5Anchor.g3, M5Anchor.g0],
  M5Clue.liveCrow: [M5Anchor.wireA, M5Anchor.wireC, M5Anchor.wireD, M5Anchor.armR, M5Anchor.armL],
  M5Clue.catRoof: [M5Anchor.stall],
  M5Clue.earthPit: [M5Anchor.g1, M5Anchor.g0],
  M5Clue.tapePole: [M5Anchor.poleMid, M5Anchor.poleLow],
  M5Clue.kiteTree: [M5Anchor.crown],
  M5Clue.flagStall: [M5Anchor.stall],
};

/// One fault spot of the play.
@immutable
class M5Spot {
  const M5Spot({
    required this.culprit,
    required this.chain,
    required this.view,
    required this.real,
    required this.cards,
    required this.why,
    this.collateral = false,
    this.chargeBait = false,
  });

  /// The culprit (for a chain spot: the branch it ends in is [M5Culprit.tree],
  /// the insulator it starts at — see [truth]).
  final M5Culprit culprit;

  /// A chain spot: cracked insulator → sagged wire → branch.
  final bool chain;

  /// What the spot shows (items, light, the villager).
  final M5View view;

  /// Per item: a real clue of this spot (else a decoy).
  final List<bool> real;

  /// The four culprit cards on the board.
  final List<M5Culprit> cards;

  /// What the reason asks about.
  final M5Why why;

  /// Bird spot: the bird damaged an insulator (the remedy changes).
  final bool collateral;

  /// The remedy deck carries the deadly "charge it and see" plan.
  final bool chargeBait;

  List<M5Placed> get items => view.items;
  bool get villager => view.villager;

  /// The culprits the board must charge.
  Set<M5Culprit> get truth => chain ? {M5Culprit.insulator, M5Culprit.tree} : {culprit};

  /// The fault type (only for a tree or an insulator).
  M5FaultType? get faultType => chain
      ? null
      : switch (culprit) {
          M5Culprit.tree => view.treeToGround ? M5FaultType.phaseEarth : M5FaultType.phasePhase,
          M5Culprit.insulator => M5FaultType.phaseEarth,
          _ => null,
        };

  /// Where the fault is (the deadly flash).
  M5Anchor get faultAt => items[real.indexOf(true)].at;
}

@immutable
class M5CulpritDeal {
  const M5CulpritDeal({required this.spots, required this.feeder});
  final List<M5Spot> spots;

  /// The feeder number on the docket.
  final int feeder;

  /// The bird spot (the coworker comes there).
  int get birdIndex => spots.indexWhere((s) => s.culprit == M5Culprit.bird && !s.chain);
}

M5Spot _dealSpot(math.Random rng, M5Culprit culprit, {required bool chain, required bool villager}) {
  final used = <M5Anchor>{};
  final items = <M5Placed>[];
  final real = <bool>[];
  bool place(M5Clue c, bool isReal, {M5Anchor? at}) {
    if (items.any((p) => p.clue == c)) return false;
    final free = at != null ? [if (!used.contains(at)) at] : [...m5AnchorsOf[c]!.where((a) => !used.contains(a))];
    if (free.isEmpty) return false;
    final a = free[rng.nextInt(free.length)];
    used.add(a);
    items.add(M5Placed(c, a));
    real.add(isReal);
    return true;
  }

  final collateral = !chain && culprit == M5Culprit.bird && rng.nextBool();
  final treeToGround = !chain && culprit == M5Culprit.tree && rng.nextBool();
  if (chain) {
    // Cracked insulator on the left arm (its conductor sags onto the tree).
    place(M5Clue.pinCrack, true, at: M5Anchor.ins0);
    place(rng.nextBool() ? M5Clue.carbon : M5Clue.chips, true);
    place(M5Clue.sag, true);
    place(M5Clue.branch, true);
  } else {
    final pool = [...m5RealClues[culprit]!];
    if (culprit == M5Culprit.tree) {
      place(M5Clue.branch, true);
      final rest = [M5Clue.sag, M5Clue.armScar]..shuffle(rng);
      for (final c in rest.take(1 + rng.nextInt(2))) {
        place(c, true);
      }
    } else {
      pool.shuffle(rng);
      final n = pool.length == 2 ? 2 : 2 + rng.nextInt(2);
      for (final c in pool.take(n)) {
        place(c, true);
      }
      if (collateral) place(M5Clue.birdFlash, true);
    }
  }

  // The cards: the truth and others, four in all.
  final truth = chain ? {M5Culprit.insulator, M5Culprit.tree} : {culprit};
  final others = [...M5Culprit.values.where((c) => !truth.contains(c))]..shuffle(rng);
  final cards = [...truth, ...others.take(4 - truth.length)]..shuffle(rng);

  // Decoys: 2–3 that look like the clues of the cards on the board.
  final decoyPool = [for (final c in cards) ...m5Decoys[c]!]..shuffle(rng);
  final want = 2 + rng.nextInt(2);
  var n = 0;
  for (final d in decoyPool) {
    if (n >= want) break;
    if (place(d, false)) n++;
  }

  final M5Why why;
  if (chain) {
    why = M5Why.chain;
  } else {
    final options = switch (culprit) {
      M5Culprit.bird => [M5Why.bird],
      M5Culprit.tree || M5Culprit.insulator => [M5Why.culprit, M5Why.type, M5Why.remedy],
      M5Culprit.jumper => [M5Why.culprit, M5Why.remedy],
      _ => [M5Why.culprit],
    };
    why = options[rng.nextInt(options.length)];
  }
  return M5Spot(
    culprit: chain ? M5Culprit.tree : culprit,
    chain: chain,
    view: M5View(items: items, treeToGround: treeToGround, light: rng.nextBool() ? M5Light.sun : M5Light.haze, villager: villager),
    real: real,
    cards: cards,
    why: why,
    collateral: collateral,
    chargeBait: rng.nextBool(),
  );
}

/// A fresh play: the bird spot and two of tree / insulator / jumper / LA /
/// kite (one of them a chain spot in half the plays), in a dealt order.
M5CulpritDeal m5CulpritDeal(math.Random rng) {
  final chain = rng.nextBool();
  final List<(M5Culprit, bool)> kinds;
  if (chain) {
    final other = [M5Culprit.jumper, M5Culprit.la, M5Culprit.kite];
    kinds = [(M5Culprit.bird, false), (M5Culprit.tree, true), (other[rng.nextInt(other.length)], false)];
  } else {
    final pool = [M5Culprit.tree, M5Culprit.insulator, M5Culprit.jumper, M5Culprit.la, M5Culprit.kite]..shuffle(rng);
    kinds = [(M5Culprit.bird, false), (pool[0], false), (pool[1], false)];
  }
  kinds.shuffle(rng);
  final spots = [for (var i = 0; i < 3; i++) _dealSpot(rng, kinds[i].$1, chain: kinds[i].$2, villager: false)];
  // The villager heard a blast (lesson 5.3 pro tip 3: a burst LA, or a short —
  // the bird, the kite, an insulator flashover, a branch across two wires).
  final loud = [for (var i = 0; i < 3; i++) if (m5Loud(spots[i])) i];
  if (rng.nextBool()) {
    final at = loud[rng.nextInt(loud.length)];
    spots[at] = _withVillager(spots[at]);
  }
  return M5CulpritDeal(spots: spots, feeder: 1 + rng.nextInt(9));
}

/// A spot where a blast in the night fits the culprit (the villager may be there).
bool m5Loud(M5Spot s) =>
    !s.chain &&
    switch (s.culprit) {
      M5Culprit.bird || M5Culprit.la || M5Culprit.kite || M5Culprit.insulator => true,
      M5Culprit.tree => !s.view.treeToGround,
      M5Culprit.jumper => false,
    };

M5Spot _withVillager(M5Spot s) => M5Spot(
      culprit: s.culprit,
      chain: s.chain,
      view: M5View(items: s.view.items, treeToGround: s.view.treeToGround, light: s.view.light, villager: true),
      real: s.real,
      cards: s.cards,
      why: s.why,
      collateral: s.collateral,
      chargeBait: s.chargeBait,
    );

// ============================================================================
// The rules (pure)
// ============================================================================

/// A photo (or the villager's sound card) on the case board.
@immutable
class M5Pin {
  const M5Pin({required this.id, required this.at, this.item, this.sound = false});
  final String id;

  /// The design point the photo was taken at.
  final Offset at;

  /// The spot item in the photo (null: plain scenery, or the sound card).
  final int? item;
  final bool sound;
}

/// What the shutter did.
enum M5Shot { blurry, pinned, again, full }

/// The sharp zoom (closer than this is blurry) and the reticle's reach.
const double m5SharpZoom = 2.0;
const double m5MaxZoom = 3.0;
double m5ShotReach(double zoom) => 46 / zoom;

/// The photo pins a spot can hold (the sound card is extra).
const int m5MaxPhotos = 7;

/// The picked culprit(s) on the board: one, or a chain from → to.
@immutable
class M5Pick {
  const M5Pick.single(M5Culprit c)
      : first = c,
        then = null;
  const M5Pick.chain(this.first, M5Culprit this.then);
  final M5Culprit first;
  final M5Culprit? then;
  bool get chain => then != null;

  @override
  bool operator ==(Object other) => other is M5Pick && other.first == first && other.then == then;

  @override
  int get hashCode => Object.hash(first, then);
}

/// The play state (pure logic).
class M5CulpritRun {
  M5CulpritRun(this.deal);
  final M5CulpritDeal deal;

  int index = 0;
  int slips = 0;
  int spotSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The spot's case is closed (its reason comes next).
  var spotDone = false;

  // The board of the spot now.
  final List<M5Pin> pins = [];
  final Map<String, M5Culprit> threads = {};
  M5Culprit? linkFrom;
  M5Culprit? linkTo;
  M5FaultType? typeAnswer;
  ChoiceOption? remedyAnswer;
  int _photoN = 0;

  /// The remedy decks dealt at this spot, one per deck kind: a re-opened slot
  /// shows the same cards (re-dealing would let the steady right card stand out).
  final Map<M5Remedy, List<ChoiceOption>> _remedyDeals = {};
  var _blurry = false;

  M5Spot get spot => deal.spots[index.clamp(0, deal.spots.length - 1)];
  bool get done => index >= deal.spots.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => spotSlips == 0;
  bool get _open => !ended && !spotDone;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    spotSlips++;
    return m;
  }

  int get photoCount => pins.where((p) => !p.sound).length;
  bool get soundPinned => pins.any((p) => p.sound);

  /// A real clue of this spot is on [pin] (the sound card is one too).
  bool isReal(M5Pin pin) => pin.sound || (pin.item != null && spot.real[pin.item!]);

  M5Pin? pinById(String id) => pins.where((p) => p.id == id).firstOrNull;

  /// The item nearest [aim] within the reticle's reach, or null.
  int? itemAt(Offset aim, double zoom, M5CulpritGeo geo) {
    final sagged = spot.view.has(M5Clue.sag);
    int? best;
    var bestD = m5ShotReach(zoom);
    for (final (i, p) in spot.items.indexed) {
      final d = (geo.anchor(p.at, sagged: sagged) - aim).distance;
      if (d <= bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// The shutter at [aim], [zoom]× (no feedback on right or wrong).
  M5Shot shoot(Offset aim, double zoom, M5CulpritGeo geo) {
    if (!_open) return M5Shot.again;
    if (zoom < m5SharpZoom) {
      _blurry = true;
      return M5Shot.blurry;
    }
    final item = itemAt(aim, zoom, geo);
    if (item != null && pins.any((p) => p.item == item)) return M5Shot.again;
    if (item == null && pins.any((p) => !p.sound && p.item == null && (p.at - aim).distance < 30)) return M5Shot.again;
    if (photoCount >= m5MaxPhotos) return M5Shot.full;
    pins.add(M5Pin(id: 'p${_photoN++}', at: item == null ? aim : geo.anchor(spot.items[item].at, sagged: spot.view.has(M5Clue.sag)), item: item));
    return M5Shot.pinned;
  }

  /// The villager's sound card (once, where he is).
  bool addSound() {
    if (!_open || !spot.villager || soundPinned) return false;
    pins.add(const M5Pin(id: 'snd', at: Offset.zero, sound: true));
    return true;
  }

  int threadsOn(M5Culprit c) => threads.values.where((x) => x == c).length;

  /// The cards with two threads or more.
  Set<M5Culprit> get charged => {for (final c in spot.cards) if (threadsOn(c) >= 2) c};

  /// The pick the slots follow (null: none, or not one clear pick).
  M5Pick? get pick {
    final ch = charged;
    if (ch.length == 1) return M5Pick.single(ch.single);
    final f = linkFrom;
    final t = linkTo;
    if (ch.length == 2 && f != null && t != null && ch.contains(f) && ch.contains(t)) return M5Pick.chain(f, t);
    return null;
  }

  /// The remedy deck the pick opens (null: no remedy slot).
  M5Remedy? remedyFor(M5Pick? p) {
    if (p == null) return null;
    if (p.chain) return M5Remedy.chain;
    return switch (p.first) {
      M5Culprit.tree => M5Remedy.tree,
      M5Culprit.insulator => M5Remedy.insulator,
      M5Culprit.jumper => M5Remedy.jumper,
      M5Culprit.bird => spot.culprit == M5Culprit.bird && !spot.chain && spot.collateral ? M5Remedy.birdHurt : M5Remedy.birdClean,
      _ => null,
    };
  }

  bool get needsType {
    final p = pick;
    return p != null && !p.chain && (p.first == M5Culprit.tree || p.first == M5Culprit.insulator);
  }

  bool get needsRemedy => remedyFor(pick) != null;

  bool get canClose => _open && charged.isNotEmpty && (!needsType || typeAnswer != null) && (!needsRemedy || remedyAnswer != null);

  void _keepPick(M5Pick? before) {
    if (pick != before) {
      typeAnswer = null;
      remedyAnswer = null;
    }
  }

  /// A thread from [pin] to [card] (null: the thread comes off).
  void thread(String pin, M5Culprit? card) {
    if (!_open || pinById(pin) == null) return;
    final before = pick;
    if (card == null) {
      threads.remove(pin);
    } else if (spot.cards.contains(card)) {
      threads[pin] = card;
    }
    _keepPick(before);
  }

  /// "তারপর →" from [from] to [to] (one link; the same again removes it).
  void link(M5Culprit from, M5Culprit to) {
    if (!_open || from == to) return;
    final before = pick;
    if (linkFrom == from && linkTo == to) {
      linkFrom = null;
      linkTo = null;
    } else {
      linkFrom = from;
      linkTo = to;
    }
    _keepPick(before);
  }

  void unlink() {
    final before = pick;
    linkFrom = null;
    linkTo = null;
    _keepPick(before);
  }

  /// The fault type options for the slot (by the pick's culprit).
  List<ChoiceOption> typeOptions(math.Random rng) {
    final truth = spot.faultType;
    return [for (final t in M5FaultType.values) ChoiceOption(M5CulpritLines.faultType(t), t == truth)]..shuffle(rng);
  }

  /// The remedy options for the slot: 1 right + 2 wrong for the pick (the
  /// deadly "charge it" plan is one of the two at a bait spot). Dealt once per
  /// spot and deck kind. A bird deck always holds one "no damage" card, one
  /// "replace the insulator" card and one other (or the charge plan), whatever
  /// the truth, so the deck never tells whether the bird did damage.
  List<ChoiceOption> remedyOptions(math.Random rng) {
    final r = remedyFor(pick);
    if (r == null) return const [];
    return _remedyDeals[r] ??= _dealRemedy(r, rng);
  }

  List<ChoiceOption> _dealRemedy(M5Remedy r, math.Random rng) {
    if (r == M5Remedy.birdClean || r == M5Remedy.birdHurt) {
      final clean = M5CulpritLines.remedyRight[M5Remedy.birdClean]!;
      final hurt = M5CulpritLines.remedyRight[M5Remedy.birdHurt]!;
      const other = M5CulpritLines.birdOther;
      return [
        ChoiceOption(clean[rng.nextInt(clean.length)], r == M5Remedy.birdClean),
        ChoiceOption(hurt[rng.nextInt(hurt.length)], r == M5Remedy.birdHurt),
        spot.chargeBait ? const ChoiceOption(M5CulpritLines.charge, false) : ChoiceOption(other[rng.nextInt(other.length)], false),
      ]..shuffle(rng);
    }
    final right = M5CulpritLines.remedyRight[r]!;
    final wrong = [...M5CulpritLines.remedyWrong[r]!]..shuffle(rng);
    return [
      ChoiceOption(right[rng.nextInt(right.length)], true),
      if (spot.chargeBait) const ChoiceOption(M5CulpritLines.charge, false),
      for (final w in wrong.take(spot.chargeBait ? 1 : 2)) ChoiceOption(w, false),
    ]..shuffle(rng);
  }

  void answerType(String text) {
    if (!_open) return;
    typeAnswer = M5FaultType.values.firstWhere((t) => M5CulpritLines.faultType(t) == text);
  }

  void answerRemedy(ChoiceOption o) {
    if (!_open) return;
    remedyAnswer = o;
  }

  /// "কেস বন্ধ": the first wrong element (one slip), or null — the case is closed.
  DoMistake? close() {
    if (!canClose) return null;
    final s = spot;
    final rem = remedyAnswer;
    if (needsRemedy && rem != null && rem.textBn == M5CulpritLines.charge) return deadly = M5CulpritMistakes.chargeTest;
    for (final e in threads.entries) {
      final pin = pinById(e.key);
      if (pin != null && !isReal(pin)) return _slip(M5CulpritMistakes.decoy);
    }
    final ch = charged;
    if (s.chain) {
      final ok = ch.length == 2 && ch.containsAll(s.truth) && linkFrom == M5Culprit.insulator && linkTo == M5Culprit.tree;
      // Half the chain (either end), or both unlinked / reversed: the chain card.
      // Neither end charged: the insulator (where the chain starts) was missed.
      if (!ok) {
        final half = ch.contains(M5Culprit.tree) || ch.contains(M5Culprit.insulator);
        return _slip(half ? M5CulpritMistakes.chain : M5CulpritMistakes.culpritInsulator);
      }
    } else if (ch.length != 1 || ch.single != s.culprit) {
      return _slip(M5CulpritMistakes.culprit(s.culprit));
    }
    if (needsType && typeAnswer != s.faultType) {
      return _slip(s.culprit == M5Culprit.tree ? M5CulpritMistakes.typeTree : M5CulpritMistakes.typeInsulator);
    }
    if (needsRemedy && rem != null && !rem.correct) {
      final r = remedyFor(pick)!;
      if (r == M5Remedy.birdHurt && M5CulpritLines.remedyRight[M5Remedy.birdClean]!.contains(rem.textBn)) {
        return _slip(M5CulpritMistakes.birdDamage);
      }
      return _slip(M5CulpritMistakes.remedy(r));
    }
    spotDone = true;
    if (!_blurry && thorough) _tag(M5CulpritLines.caughtPhoto);
    _tag(s.chain ? M5CulpritLines.caughtChain : M5CulpritLines.caughtCulprit);
    if (needsType && thorough) _tag(M5CulpritLines.caughtType);
    if (needsRemedy && thorough) _tag(M5CulpritLines.caughtFix);
    return null;
  }

  /// Listening to the coworker (a slip).
  DoMistake listened() => _slip(M5CulpritMistakes.listen);

  /// The right reasons for this spot's question.
  List<String> whyRight() {
    final s = spot;
    return switch (s.why) {
      M5Why.chain => M5CulpritLines.whyChain,
      M5Why.bird => M5CulpritLines.whyBird,
      M5Why.type => s.culprit == M5Culprit.insulator
          ? M5CulpritLines.whyInsulatorEarth
          : (s.view.treeToGround ? M5CulpritLines.whyTreeEarth : M5CulpritLines.whyTreePhase),
      M5Why.remedy => M5CulpritLines.whyRemedy[s.culprit]!,
      M5Why.culprit => M5CulpritLines.whyCulprit[s.culprit]!,
    };
  }

  String whyQuestion() {
    final s = spot;
    return switch (s.why) {
      M5Why.chain => M5CulpritLines.whyChainQ,
      M5Why.bird => M5CulpritLines.whyBirdQ,
      M5Why.type => s.faultType == M5FaultType.phasePhase ? M5CulpritLines.whyTypePhaseQ : M5CulpritLines.whyTypeEarthQ,
      M5Why.remedy => M5CulpritLines.whyRemedyQ,
      M5Why.culprit => M5CulpritLines.whyCulpritQ,
    };
  }

  void next() {
    index++;
    spotSlips = 0;
    spotDone = false;
    pins.clear();
    threads.clear();
    linkFrom = null;
    linkTo = null;
    typeAnswer = null;
    remedyAnswer = null;
    _remedyDeals.clear();
    _blurry = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per spot: phone, 3 shots × (zoom, aim, shutter) ≈ 15000; board: 3 threads,
///   1–2 slots, close ≈ 10500; reason ≈ 8200                      ≈ 33700
/// × 3 spots + the coworker ≈ 9600                                ≈ 110700
/// 85 % ≈ 94000 → 100 s.
const m5CulpritQuickMs = 100000;

@immutable
class M5CulpritPack {
  const M5CulpritPack({required this.id, required this.titleBn, this.quickMs = m5CulpritQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5CulpritPack> m5CulpritPacks = {
  'do_5_3_a': M5CulpritPack(id: 'do_5_3_a', titleBn: M5CulpritLines.title),
};

/// The case board's layout (screen px inside the page): the photo pins on
/// top, the four culprit cards, the slots, the buttons.
@immutable
class M5BoardLayout {
  const M5BoardLayout._(this.size, this.pins, this.cards, this.knobs, this.slots, this.backBtn, this.closeBtn, this.titleTop);

  factory M5BoardLayout.of(Size size, EdgeInsets pad) {
    final w = size.width;
    const m = 14.0;
    final top = pad.top + 104;
    final pw = (w - 2 * m - 3 * 8) / 4;
    final ph = pw * 0.82;
    final pinsTop = top + 24;
    final pins = [for (var i = 0; i < 8; i++) Rect.fromLTWH(m + (i % 4) * (pw + 8), pinsTop + (i ~/ 4) * (ph + 8), pw, ph)];
    final cardsTop = pinsTop + 2 * (ph + 8) + 34;
    final cw = (w - 2 * m - 12) / 2;
    const ch = 64.0;
    final cards = [for (var i = 0; i < 4; i++) Rect.fromLTWH(m + (i % 2) * (cw + 12), cardsTop + (i ~/ 2) * (ch + 10), cw, ch)];
    final knobs = [for (final c in cards) Rect.fromLTWH(c.right - 86, c.bottom - 48, 86, 48)];
    final slotsTop = cardsTop + 2 * (ch + 10) + 2;
    final slots = [for (var i = 0; i < 2; i++) Rect.fromLTWH(m + i * (cw + 12), slotsTop, cw, 50)];
    // The buttons stand in a column on the right (the corner guide is bottom left).
    final closeBtn = Rect.fromLTWH(w - m - 132, size.height - pad.bottom - 60, 132, 50);
    final backBtn = Rect.fromLTWH(w - m - 132, closeBtn.top - 58, 132, 50);
    return M5BoardLayout._(size, pins, cards, knobs, slots, backBtn, closeBtn, top);
  }

  final Size size;
  final List<Rect> pins;
  final List<Rect> cards;
  final List<Rect> knobs;
  final List<Rect> slots;
  final Rect backBtn;
  final Rect closeBtn;
  final double titleTop;

  /// The board's drag hint for [pinCount] pins: from the first pin of the
  /// bottom pin row (so the hand never ends on another pin) straight down into
  /// the gap above the cards.
  (Offset, double) pinDragHint(int pinCount) {
    final from = pins[pinCount > 4 ? 4 : 0].center;
    final gapY = cards.first.top - 16;
    return (from, (gapY - from.dy).clamp(24.0, HintSpec.maxDragTravel));
  }
}

/// Test hook: what the level is doing now and where things are on screen.
/// Never used by the app.
class M5CulpritProbe {
  _CaseRunPageState? _s;
  M5CulpritRun? get run => _s?._run;
  M5CulpritDeal? get deal => _s?._run.deal;

  /// intro, scene, aim, board, slot, card, freeze, done.
  String get phase {
    final s = _s;
    if (s == null) return 'none';
    if (s._intro) return 'intro';
    if (s._mark != null || s.struckOut) return 'done';
    if (s._freeze) return 'freeze';
    if (s._card != null) return 'card';
    if (s._slotOpen != null) return 'slot';
    return s._phase.name;
  }

  double get zoom => _s?._zoom ?? 1;
  Offset get aim => _s?._aim ?? Offset.zero;

  /// The design point of item [i] of the spot now.
  Offset? itemDesign(int i) {
    final s = _s;
    final geo = s?._geoNow;
    if (s == null || geo == null) return null;
    return geo.anchor(s._run.spot.items[i].at, sagged: s._run.spot.view.has(M5Clue.sag));
  }

  /// Screen points on the board.
  Offset? pinGlobal(String id) => _s?._boardPoint(pin: id);
  Offset? cardGlobal(M5Culprit c) => _s?._boardPoint(card: c);
  Offset? knobGlobal(M5Culprit c) => _s?._boardPoint(knob: c);

  /// A design point of the scene on screen.
  Offset? sceneGlobal(Offset design) => _s?._sceneGlobal(design);

  /// The options on the slot deck now.
  List<ChoiceOption> get slotOptions => _s?._slotOpts ?? const [];
}

// ============================================================================
// Page
// ============================================================================

class M5CulpritCasePage extends StatefulWidget {
  const M5CulpritCasePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5CulpritPack pack;
  final bool muted;
  final int? seed;
  final M5CulpritProbe? probe;

  @override
  State<M5CulpritCasePage> createState() => _M5CulpritCasePageState();
}

class _M5CulpritCasePageState extends State<M5CulpritCasePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CaseRunPage(
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

enum _Phase { scene, aim, board }

class _CaseRunPage extends ConsumerStatefulWidget {
  const _CaseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5CulpritPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5CulpritProbe? probe;

  @override
  ConsumerState<_CaseRunPage> createState() => _CaseRunPageState();
}

class _CaseRunPageState extends ConsumerState<_CaseRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5CulpritRun _run;
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

  var _phase = _Phase.scene;

  // The phone.
  double _zoom = 1;
  Offset _aim = Offset.zero;
  final Map<int, Offset> _fingers = {};
  double? _pinchFrom;
  double _pinchZoom = 1;
  int _shotTok = 0;
  M5Pin? _lastPhoto;
  var _lastBlurry = false;
  Offset _lastAt = Offset.zero;

  // The villager's line, in a bubble for a moment.
  var _villagerTalk = false;
  Timer? _villagerTimer;

  // The board.
  final _boardKey = GlobalKey();
  String? _dragPin;
  Offset? _dragAt;
  M5Culprit? _knobArmed;
  String? _slotOpen;
  List<ChoiceOption> _slotOpts = const [];
  int _stampTok = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _boardBtnKey = GlobalKey();
  final _zoomInKey = GlobalKey();
  final _shutterKey = GlobalKey();
  M5CulpritGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M5CulpritRun(m5CulpritDeal(widget.rng));
    widget.probe?._s = this;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    if (widget.probe?._s == this) widget.probe?._s = null;
    disposeCoworker();
    _villagerTimer?.cancel();
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.spotDone && !_freeze;

  bool get _canBoard => _canPlay && _phase == _Phase.board && _slotOpen == null;

  String get _task => switch (_phase) {
        _Phase.scene => M5CulpritLines.askShoot,
        _Phase.aim => M5CulpritLines.askAim,
        _Phase.board => _run.charged.isNotEmpty && !_run.canClose ? M5CulpritLines.askSlots : M5CulpritLines.askBoard,
      };

  Future<void> _start() async {
    _clock.start();
    _startSpot();
  }

  void _startSpot() {
    setState(() {
      _phase = _Phase.scene;
      _zoom = 1;
      _aim = _geoNow?.viewCentre() ?? Offset.zero;
      _knobArmed = null;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  // --- the phone --------------------------------------------------------------
  Offset _clampAim(Offset a) {
    final g = _geoNow;
    if (g == null) return a;
    return Offset(a.dx.clamp(0.0, 360.0), a.dy.clamp(g.topY - 60, g.groundY + 60));
  }

  void _raisePhone() {
    if (!_canPlay || _phase != _Phase.scene) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _phase = _Phase.aim;
      _zoom = 1;
      _aim = _geoNow?.viewCentre() ?? _aim;
      _wake++;
    });
    unawaited(_sayChain([M5CulpritLines.askAim]));
  }

  void _lowerPhone() {
    if (!_canPlay || _phase != _Phase.aim) return;
    _tick();
    setState(() {
      _phase = _Phase.scene;
      _zoom = 1;
      _aim = _geoNow?.viewCentre() ?? _aim;
    });
  }

  void _zoomBy(double d) {
    if (!_canPlay || _phase != _Phase.aim) return;
    _tick();
    setState(() => _setZoom(_zoom + d));
  }

  void _setZoom(double z) {
    _zoom = z.clamp(1.0, m5MaxZoom);
    if (_zoom <= 1.0001) {
      _aim = _geoNow?.viewCentre() ?? _aim;
    } else {
      _aim = _clampAim(_aim);
    }
  }

  void _fingerDown(PointerDownEvent e) {
    if (!_canPlay || _phase != _Phase.aim) return;
    _fingers[e.pointer] = e.localPosition;
    if (_fingers.length == 2) {
      final p = _fingers.values.toList();
      _pinchFrom = (p[0] - p[1]).distance;
      _pinchZoom = _zoom;
    }
  }

  void _fingerMove(PointerMoveEvent e) {
    if (!_fingers.containsKey(e.pointer)) return;
    if (!_canPlay || _phase != _Phase.aim) return;
    _fingers[e.pointer] = e.localPosition;
    if (_fingers.length >= 2 && _pinchFrom != null && _pinchFrom! > 4) {
      final p = _fingers.values.toList();
      setState(() => _setZoom(_pinchZoom * (p[0] - p[1]).distance / _pinchFrom!));
      return;
    }
    if (_fingers.length == 1 && _zoom > 1.0001) {
      // The scene's layer is in design px: drag the view (the world follows the finger).
      setState(() => _aim = _clampAim(_aim - e.localDelta / _zoom));
    }
  }

  void _fingerUp(PointerEvent e) {
    _fingers.remove(e.pointer);
    if (_fingers.length < 2) _pinchFrom = null;
  }

  void _shoot() {
    final geo = _geoNow;
    if (!_canPlay || _phase != _Phase.aim || geo == null) return;
    _cue('sounds/intro/click.ogg', volume: 0.8);
    HapticFeedback.lightImpact();
    final r = _run.shoot(_aim, _zoom, geo);
    setState(() {
      _shotTok++;
      _lastBlurry = r == M5Shot.blurry;
      _lastAt = _aim;
      _lastPhoto = r == M5Shot.pinned ? _run.pins.last : null;
      _wake++;
    });
    _hush();
    if (r == M5Shot.blurry) unawaited(_sayChain([M5CulpritLines.blurry]));
  }

  // --- the scene ----------------------------------------------------------------
  void _tapScene(Offset p, M5CulpritGeo geo) {
    if (!_canPlay || _phase != _Phase.scene) return;
    if (_run.spot.villager && geo.villager.contains(p)) {
      _tick();
      _villagerTimer?.cancel();
      final added = _run.addSound();
      setState(() {
        _villagerTalk = true;
        _wake++;
      });
      _hush();
      unawaited(MascotSpeechLibrary.speak(M5CulpritLines.villager, muted: _muted));
      _villagerTimer = Timer(Duration(milliseconds: _muted ? 2600 : 3400), () {
        if (mounted) setState(() => _villagerTalk = false);
      });
      if (added) _cue('sounds/learn/tag_slap.ogg', volume: 0.4);
      return;
    }
    _hints.missTap();
  }

  void _openBoard() {
    if (!_canPlay || _phase != _Phase.scene || _run.pins.isEmpty) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.6);
    setState(() {
      _phase = _Phase.board;
      _knobArmed = null;
      _wake++;
    });
    if (_run.index == _run.deal.birdIndex && !coworkerDone) {
      // The bird spot: he comes as the board opens; the board waits for him.
      scheduleCoworker();
      _hush();
      return;
    }
    unawaited(_sayChain([_task]));
  }

  void _boardBack() {
    if (!_canBoard) return;
    if (holdForCoworker()) return;
    _tick();
    setState(() {
      _phase = _Phase.scene;
      _knobArmed = null;
      _dragPin = null;
    });
    unawaited(_sayChain([_task]));
  }

  // --- the board ----------------------------------------------------------------
  Offset? _boardLocal(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.globalToLocal(global);
  }

  M5BoardLayout? _layout() {
    final box = _boardKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return M5BoardLayout.of(box.size, MediaQuery.paddingOf(context));
  }

  Offset? _boardPoint({String? pin, M5Culprit? card, M5Culprit? knob}) {
    final box = _boardKey.currentContext?.findRenderObject();
    final l = _layout();
    if (box is! RenderBox || l == null || _phase != _Phase.board) return null;
    Offset? at;
    if (pin != null) {
      final i = _run.pins.indexWhere((p) => p.id == pin);
      if (i >= 0) at = l.pins[i].center;
    } else if (card != null) {
      // The card's name area (clear of its knob).
      final i = _run.spot.cards.indexOf(card);
      if (i >= 0) at = Offset(l.cards[i].left + l.cards[i].width * 0.3, l.cards[i].top + l.cards[i].height * 0.35);
    } else if (knob != null) {
      final i = _run.spot.cards.indexOf(knob);
      if (i >= 0) at = l.knobs[i].center;
    }
    return at == null ? null : box.localToGlobal(at);
  }

  Offset? _sceneGlobal(Offset design) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(design);
  }

  void _pinDragStart(String id, DragStartDetails d) {
    if (!_canBoard) return;
    if (holdForCoworker()) return;
    setState(() {
      _dragPin = id;
      _dragAt = _boardLocal(d.globalPosition);
      _knobArmed = null;
    });
  }

  void _pinDragMove(DragUpdateDetails d) {
    if (_dragPin == null) return;
    setState(() => _dragAt = _boardLocal(d.globalPosition));
  }

  void _pinDragEnd() {
    final id = _dragPin;
    final at = _dragAt;
    final l = _layout();
    setState(() {
      _dragPin = null;
      _dragAt = null;
    });
    if (id == null || l == null || !_canBoard) return;
    M5Culprit? target;
    for (final (i, c) in _run.spot.cards.indexed) {
      if (at != null && l.cards[i].inflate(6).contains(at)) target = c;
    }
    final had = _run.threads[id];
    _run.thread(id, target);
    if (target != null) {
      _tick('sounds/learn/tag_slap.ogg', 0.45);
    } else if (had != null) {
      _tick();
    }
    setState(() => _wake++);
  }

  void _tapKnob(M5Culprit c) {
    if (!_canBoard) return;
    if (holdForCoworker()) return;
    _tick();
    setState(() {
      if (_run.linkFrom == c) {
        _run.unlink();
        _knobArmed = null;
      } else {
        _knobArmed = _knobArmed == c ? null : c;
      }
    });
  }

  void _tapCard(M5Culprit c) {
    if (!_canBoard) return;
    final from = _knobArmed;
    if (from == null || from == c) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    _tick('sounds/learn/tag_slap.ogg', 0.45);
    setState(() {
      _run.link(from, c);
      _knobArmed = null;
    });
  }

  void _openSlot(String which) {
    if (!_canBoard) return;
    if (holdForCoworker()) return;
    final opts = which == 'type' ? _run.typeOptions(widget.rng) : _run.remedyOptions(widget.rng);
    if (opts.isEmpty) return;
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    setState(() {
      _slotOpen = which;
      _slotOpts = opts;
      _knobArmed = null;
    });
    unawaited(_sayChain([which == 'type' ? M5CulpritLines.typeSlot : M5CulpritLines.remedySlot], mood: GuideMood.think));
  }

  /// A slot's card: put in the slot, no right or wrong shown until the close.
  void _pickSlot(ChoiceOption o) {
    final which = _slotOpen;
    if (which == null || !_canPlay) return;
    _hush();
    _tick('sounds/learn/tag_slap.ogg', 0.45);
    setState(() {
      if (which == 'type') {
        _run.answerType(o.textBn);
      } else {
        _run.answerRemedy(o);
      }
      _slotOpen = null;
      _slotOpts = const [];
      _wake++;
    });
  }

  void _closeCase(Offset global) {
    if (!_canBoard || !_run.canClose) return;
    if (holdForCoworker()) return;
    _hush();
    final m = _run.close();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    unawaited(_spotDone());
  }

  Future<void> _spotDone() async {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.8);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() => _stampTok++);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(_run.whyRight(), M5CulpritLines.myths, widget.rng),
      question: _run.whyQuestion(),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startSpot();
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
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5CulpritLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.birdIndex || _run.spotDone) return null;
    if (_intro || _card != null || tableBusy || _freeze || _phase != _Phase.board || _slotOpen != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(_run.listened());
      return;
    }
    _run.caught.add(M5CulpritLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5CulpritLines.callHeld, M5CulpritLines.askBoard], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5CulpritLines.tapWhy[_nudgeN++ % M5CulpritLines.tapWhy.length]
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
      _slotOpen = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('culprit/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Charging a faulted line: the scene freezes grey and the flash comes off
  /// the fault in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _phase = _Phase.scene;
      _zoom = 1;
      _aim = _geoNow?.viewCentre() ?? _aim;
      _slotOpen = null;
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
    final speak = await SpokenOnce.first('culprit/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5CulpritLines.deadlyWord : M5CulpritLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same spot goes on from where it was.
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
    await _say(!_run.passed ? M5CulpritLines.fail : (_quickBonus ? M5CulpritLines.quick : M5CulpritLines.allSet),
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

  // --- the hints ------------------------------------------------------------------
  /// The gesture hand — how to touch, never what:
  /// • the scene: a tap on the phone (the one way to start), or a sweep over
  ///   the phone and the board buttons once photos are pinned;
  /// • the phone: a tap on zoom-in while too far; then a drag on the sky (the
  ///   same path every deal, never toward a clue);
  /// • the board: a short drag from the first pin of the bottom pin row into
  ///   the gap above the cards (never ending on another pin)
  ///   (springing back); with a culprit charged, a sweep over the open slots
  ///   (or the close and back buttons). The "তারপর →" knob is never hinted.
  HintSpec? _hint() {
    switch (_phase) {
      case _Phase.scene:
        if (_run.pins.isEmpty) return HintSpec.tapOn(_phoneKey);
        return HintSpec.sweepOver([_phoneKey, _boardBtnKey]);
      case _Phase.aim:
        if (_zoom < m5SharpZoom) return HintSpec.tapOn(_zoomInKey);
        final g = _geoNow;
        if (g == null) return null;
        return HintSpec.drag(Offset(120, g.topY - 40), toward: const Offset(1, 0), travel: 80, space: HintSpace.scene);
      case _Phase.board:
        final box = _boardKey.currentContext?.findRenderObject();
        final l = _layout();
        if (box is! RenderBox || l == null) return null;
        Rect g(Rect r) => Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
        if (_run.charged.isEmpty) {
          final (from, travel) = l.pinDragHint(_run.pins.length);
          return HintSpec.drag(box.localToGlobal(from), toward: const Offset(0, 1), travel: travel);
        }
        final slots = [
          if (_run.needsType && _run.typeAnswer == null) g(l.slots[0]),
          if (_run.needsRemedy && _run.remedyAnswer == null) g(l.slots[_run.needsType ? 1 : 0]),
        ];
        if (slots.length == 1) return HintSpec.tap(slots.single.center);
        if (slots.length > 1) return HintSpec.sweep(slots);
        return HintSpec.sweep([g(l.backBtn), g(l.closeBtn)]);
    }
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_phase == _Phase.aim) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  Matrix4 _view(M5CulpritGeo geo) {
    if (_phase != _Phase.aim || _zoom <= 1.0001) return Matrix4.identity();
    final c = geo.viewCentre();
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(_zoom, _zoom, 1, 1)
      ..translateByDouble(-_aim.dx, -_aim.dy, 0, 1);
  }

  M5CulpritPainter _world(M5CulpritGeo geo) => M5CulpritPainter(geo: geo, view: _run.spot.view, seed: _run.index * 5 + _run.deal.feeder);

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5CulpritGeo.forScene(m.height, m.inset);
    if (_aim == Offset.zero) _aim = geo.viewCentre();
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final aiming = _phase == _Phase.aim && !_freeze;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Transform(
            transform: _view(geo),
            child: Stack(
              children: [
                Positioned.fill(
                  key: const ValueKey('spot'),
                  child: RepaintBoundary(child: CustomPaint(painter: _world(geo))),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: geo.trainee,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ],
            ),
          ),
        ),
      ),
      // The scene's touch layer: the villager (tap) and the phone's drag/pinch.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5CulpritLines.sceneLabel,
          child: Listener(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            onPointerDown: _fingerDown,
            onPointerMove: _fingerMove,
            onPointerUp: _fingerUp,
            onPointerCancel: _fingerUp,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _phase == _Phase.scene ? (d) => _tapScene(d.localPosition, geo) : null,
            ),
          ),
        ),
      ),
      if (aiming)
        Positioned.fill(
          key: const ValueKey('viewfinder'),
          child: IgnorePointer(child: CustomPaint(painter: M5ViewfinderPainter(centre: geo.viewCentre(), sharp: _zoom >= m5SharpZoom))),
        ),
      // The shutter's flash.
      if (_shotTok > 0 && !_freeze && _phase == _Phase.aim)
        Positioned.fill(
          key: ValueKey('flash-$_shotTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 0.75, end: 0),
              duration: const Duration(milliseconds: 320),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(255, 255, 255, v)),
            ),
          ),
        ),
      if (_villagerTalk && _run.spot.villager && _phase == _Phase.scene && !_freeze)
        Positioned(
          key: const ValueKey('villager-say'),
          right: 8,
          top: geo.villager.top - 62,
          child: const IgnorePointer(child: _Bubble(text: M5CulpritLines.villager)),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(
                painter: M5CulpritFlashPainter(at: geo.anchor(_run.spot.faultAt, sagged: _run.spot.view.has(M5Clue.sag)), v: v),
              ),
            ),
          ),
        ),
      // The next spot: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('spot-${_run.index}'),
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

  // --- the board widget ------------------------------------------------------
  Widget _board(bool quiet, M5CulpritGeo geo) {
    final pad = MediaQuery.paddingOf(context);
    final world = _world(geo);
    return Positioned.fill(
      key: ValueKey('board-${_run.index}'),
      child: LayoutBuilder(builder: (context, box) {
        final l = M5BoardLayout.of(Size(box.maxWidth, box.maxHeight), pad);
        final cards = _run.spot.cards;
        final charged = _run.charged;
        final live = _canBoard;
        return Stack(
          key: _boardKey,
          children: [
            // The van's rear door: a cork case board.
            Positioned.fill(
              key: const ValueKey('cork'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xF2B3875A), Color(0xF29A6F45)]),
                  border: Border.all(color: const Color(0xFF5A6470), width: 6),
                ),
              ),
            ),
            Positioned(
              key: const ValueKey('board-title'),
              left: 16,
              top: l.titleTop,
              child: Text(M5CulpritLines.board, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF3A2614))),
            ),
            // The threads (and the live one while dragging).
            Positioned.fill(
              key: const ValueKey('threads'),
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ThreadPainter(
                    lines: [
                      for (final e in _run.threads.entries)
                        if (_run.pins.indexWhere((p) => p.id == e.key) case final i when i >= 0)
                          (l.pins[i].bottomCenter.translate(0, -4), l.cards[cards.indexOf(e.value)].topCenter.translate(0, 6)),
                      if (_dragPin != null && _dragAt != null)
                        if (_run.pins.indexWhere((p) => p.id == _dragPin) case final i when i >= 0) (l.pins[i].center, _dragAt!),
                    ],
                  ),
                ),
              ),
            ),
            for (final (i, p) in _run.pins.indexed)
              Positioned.fromRect(
                key: ValueKey('pin-${p.id}'),
                rect: l.pins[i],
                child: Semantics(
                  label: p.sound ? M5CulpritLines.sound : 'ছবি ${enDigits('${i + 1}')}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: live ? (d) => _pinDragStart(p.id, d) : null,
                    onPanUpdate: live ? _pinDragMove : null,
                    onPanEnd: live ? (_) => _pinDragEnd() : null,
                    onPanCancel: live ? _pinDragEnd : null,
                    child: _PinCard(pin: p, world: world, height: geo.height, threaded: _run.threads.containsKey(p.id)),
                  ),
                ),
              ),
            for (final (i, c) in cards.indexed) ...[
              Positioned.fromRect(
                key: ValueKey('card-${c.name}'),
                rect: l.cards[i],
                child: Semantics(
                  label: M5CulpritLines.culprit(c),
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: live ? () => _tapCard(c) : null,
                    child: _CulpritCard(culprit: c, threads: _run.threadsOn(c), charged: charged.contains(c), armed: _knobArmed == c),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: ValueKey('knob-${c.name}'),
                rect: l.knobs[i],
                child: Semantics(
                  label: '${M5CulpritLines.culprit(c)} ${M5CulpritLines.knob}',
                  button: true,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: live ? () => _tapKnob(c) : null,
                    child: Center(child: _Knob(on: _knobArmed == c || _run.linkFrom == c)),
                  ),
                ),
              ),
            ],
            // The chain arrow, over the cards (edge to edge).
            if (_run.linkFrom != null && _run.linkTo != null)
              Positioned.fill(
                key: const ValueKey('chain-arrow'),
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ThreadPainter(
                      lines: const [],
                      link: _edgeToEdge(l.cards[cards.indexOf(_run.linkFrom!)], l.cards[cards.indexOf(_run.linkTo!)]),
                    ),
                  ),
                ),
              ),
            // The slots (by the pick).
            if (_run.needsType)
              Positioned.fromRect(
                key: const ValueKey('slot-type'),
                rect: l.slots[0],
                child: _SlotChip(
                  label: M5CulpritLines.typeSlot,
                  value: _run.typeAnswer == null ? null : M5CulpritLines.faultType(_run.typeAnswer!),
                  onTap: live ? () => _openSlot('type') : null,
                ),
              ),
            if (_run.needsRemedy)
              Positioned.fromRect(
                key: const ValueKey('slot-remedy'),
                rect: l.slots[_run.needsType ? 1 : 0],
                child: _SlotChip(
                  label: M5CulpritLines.remedySlot,
                  value: _run.remedyAnswer?.textBn,
                  onTap: live ? () => _openSlot('remedy') : null,
                ),
              ),
            Positioned.fromRect(
              key: const ValueKey('board-back'),
              rect: l.backBtn,
              child: _BoardButton(label: M5CulpritLines.back, icon: Icons.photo_camera_rounded, on: false, onTap: live ? (_) => _boardBack() : null),
            ),
            Positioned.fromRect(
              key: const ValueKey('board-close'),
              rect: l.closeBtn,
              child: _BoardButton(
                label: M5CulpritLines.close,
                icon: Icons.gavel_rounded,
                on: _run.canClose,
                onTap: live && _run.canClose ? _closeCase : null,
              ),
            ),
            if (_stampTok > 0 && _run.spotDone)
              Positioned(
                key: ValueKey('stamp-$_stampTok'),
                left: 0,
                right: 0,
                top: l.cards.first.top - 8,
                child: IgnorePointer(
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) => Transform.scale(scale: 1.8 - 0.8 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                      child: Transform.rotate(angle: -0.18, child: const _Stamp()),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final slotUp = _slotOpen != null && _slotOpts.isNotEmpty && playing;
    final deckUp = reasonOpen || coworkerChoiceUp || slotUp;
    final handsOn = playing && !_run.spotDone && !deckUp && !coworkerOpen && _card == null && !coworkerDue;
    final geo = _geoNow;
    final boardUp = _phase == _Phase.board && !_freeze && geo != null;
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
              labels: M5CulpritLines.spots,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.index}/${_phase.name}/${_run.pins.length}/${_run.charged.length}/${_zoom >= m5SharpZoom}',
            hintController: _hints,
            overlays: [
              if (boardUp) _board(quiet, geo),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && _phase == _Phase.scene && !coworkerOnScreen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 98,
                  child: IgnorePointer(child: _DocketChip(text: M5CulpritLines.docket(_run.deal.feeder))),
                ),
              if (playing && _card == null && _phase == _Phase.scene && !_run.spotDone)
                Positioned(
                  key: ValueKey('hud-scene-${_run.index}'),
                  left: 120,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(key: _phoneKey, icon: Icons.photo_camera_rounded, label: M5CulpritLines.phone, on: false, onTap: (_) => _raisePhone()),
                      _ToolButton(
                        key: _boardBtnKey,
                        icon: Icons.push_pin_rounded,
                        label: M5CulpritLines.board,
                        on: _run.pins.isNotEmpty,
                        count: _run.pins.length,
                        onTap: (_) => _openBoard(),
                      ),
                    ],
                  ),
                ),
              if (playing && _card == null && _phase == _Phase.aim)
                Positioned(
                  key: ValueKey('hud-phone-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(icon: Icons.south_rounded, label: M5CulpritLines.lower, on: false, onTap: (_) => _lowerPhone()),
                      _ToolButton(icon: Icons.zoom_out_rounded, label: M5CulpritLines.zoomOut, on: false, onTap: (_) => _zoomBy(-0.5)),
                      _ToolButton(key: _shutterKey, icon: Icons.camera_rounded, label: M5CulpritLines.shutter, on: true, big: true, onTap: (_) => _shoot()),
                      _ToolButton(key: _zoomInKey, icon: Icons.zoom_in_rounded, label: M5CulpritLines.zoomIn, on: false, onTap: (_) => _zoomBy(0.5)),
                    ],
                  ),
                ),
              // The last shot, for a moment (sharp or blurry), top right.
              if (_shotTok > 0 && _phase == _Phase.aim && geo != null && playing)
                Positioned(
                  key: ValueKey('last-shot-$_shotTok'),
                  right: 12,
                  top: pad.top + 100,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: 0),
                      duration: Duration(milliseconds: quiet ? 1 : 1400),
                      builder: (_, v, child) => v <= 0.001 ? const SizedBox.shrink() : Opacity(opacity: math.min(1, v * 3), child: child),
                      child: SizedBox(
                        width: 72,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)]),
                          child: CustomPaint(
                            painter: M5PhotoPainter(world: _world(geo), height: geo.height, centre: _lastPhoto?.at ?? _lastAt, blurry: _lastBlurry),
                          ),
                        ),
                      ),
                    ),
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
                                key: ValueKey('slot-deck-$_slotOpen-${_run.index}'),
                                options: _slotOpts,
                                quiet: quiet,
                                muted: _muted,
                                onPick: (o, _) => _pickSlot(o),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : (_phase == _Phase.board ? 6 : 84)),
                  onLeft: !coworkerOnScreen || coworkerFromRight,
                ),
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
                  line: M5CulpritLines.intro,
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

/// The segment between two cards' edges along the line joining their centres.
(Offset, Offset) _edgeToEdge(Rect a, Rect b) {
  Offset exit(Rect r, Offset from, Offset to) {
    final d = to - from;
    final tx = d.dx.abs() < 1e-6 ? double.infinity : (r.width / 2) / d.dx.abs();
    final ty = d.dy.abs() < 1e-6 ? double.infinity : (r.height / 2) / d.dy.abs();
    return from + d * math.min(1, math.min(tx, ty));
  }

  return (exit(a, a.center, b.center), exit(b, b.center, a.center));
}

/// The threads from pins to cards, and the chain arrow between two cards.
class _ThreadPainter extends CustomPainter {
  const _ThreadPainter({required this.lines, this.link});
  final List<(Offset, Offset)> lines;
  final (Offset, Offset)? link;

  @override
  void paint(Canvas canvas, Size size) {
    final yarn = Paint()
      ..color = const Color(0xFFC0261E)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in lines) {
      canvas.drawLine(a, b, yarn);
      canvas.drawCircle(a, 3.5, Paint()..color = const Color(0xFF8E1A14));
    }
    final k = link;
    if (k != null) {
      final (a, b) = k;
      final arrow = Paint()
        ..color = const Color(0xFF1F3A68)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, arrow);
      final d = b - a;
      final u = d / math.max(1, d.distance);
      final tip = b - u * 12;
      final n = Offset(-u.dy, u.dx);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx + u.dx * 12, tip.dy + u.dy * 12)
          ..lineTo(tip.dx + n.dx * 8, tip.dy + n.dy * 8)
          ..lineTo(tip.dx - n.dx * 8, tip.dy - n.dy * 8)
          ..close(),
        Paint()..color = const Color(0xFF1F3A68),
      );
    }
  }

  @override
  bool shouldRepaint(_ThreadPainter old) => true;
}

/// A photo pinned to the cork (or the sound card).
class _PinCard extends StatelessWidget {
  const _PinCard({required this.pin, required this.world, required this.height, required this.threaded});
  final M5Pin pin;
  final M5CulpritPainter world;
  final double height;
  final bool threaded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(1, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (pin.sound)
              Container(
                color: const Color(0xFFF2EAD3),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up_rounded, size: 22, color: Color(0xFF3A2614)),
                    Text(M5CulpritLines.sound, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF3A2614))),
                  ],
                ),
              )
            else
              ClipRect(child: CustomPaint(painter: M5PhotoPainter(world: world, height: height, centre: pin.at))),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 0),
                decoration: BoxDecoration(shape: BoxShape.circle, color: threaded ? const Color(0xFFC0261E) : const Color(0xFF2F64B0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A culprit card: its name, its thread count; charged at two threads.
class _CulpritCard extends StatelessWidget {
  const _CulpritCard({required this.culprit, required this.threads, required this.charged, required this.armed});
  final M5Culprit culprit;
  final int threads;
  final bool charged;
  final bool armed;

  static const _icons = {
    M5Culprit.tree: Icons.park_rounded,
    M5Culprit.insulator: Icons.settings_input_component_rounded,
    M5Culprit.jumper: Icons.cable_rounded,
    M5Culprit.bird: Icons.flutter_dash_rounded,
    M5Culprit.la: Icons.bolt_rounded,
    M5Culprit.kite: Icons.change_history_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: armed ? const Color(0xFF1F3A68) : (charged ? const Color(0xFFC0261E) : const Color(0xFF8A7458)), width: armed || charged ? 2.6 : 1.4),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(1, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icons[culprit], size: 18, color: const Color(0xFF3A2614)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(M5CulpritLines.culprit(culprit),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A1A0E))),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < math.min(threads, 4); i++)
                Container(width: 9, height: 9, margin: const EdgeInsets.only(right: 3), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFC0261E))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: on ? const Color(0xFF1F3A68) : const Color(0xFFE4DAC2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F3A68), width: 1.2),
      ),
      child: Text(M5CulpritLines.knob, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: on ? Colors.white : const Color(0xFF1F3A68))),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label, required this.value, required this.onTap});
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: value == null ? const Color(0xCCFFFFFF) : const Color(0xFFFFF4D2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5A4630), width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF5A4630))),
              Text(value ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF2A1A0E))),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardButton extends StatelessWidget {
  const _BoardButton({required this.label, required this.icon, required this.on, required this.onTap});
  final String label;
  final IconData icon;
  final bool on;
  final ValueChanged<Offset>? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTap == null ? null : (d) => onTap!(d.globalPosition),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: on ? const [Color(0xFF2E5C3A), Color(0xFF173A22)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (on ? SlmColors.success : SlmColors.gold300).withValues(alpha: 0.9), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: on ? SlmColors.success : SlmColors.gold300),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xDDB0201A), width: 3.4), borderRadius: BorderRadius.circular(8)),
      child: Text(M5CulpritLines.stamp, style: bangla(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xDDB0201A))),
    );
  }
}

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xEEF6F0E0), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8A7458))),
      child: Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A1A0E))),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
      ),
      child: Text(text, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A))),
    );
  }
}

/// A hands-on button: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.big = false, this.count});
  final IconData icon;
  final String label;
  final bool on;
  final bool big;
  final int? count;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    final d = big ? 60.0 : 48.0;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (e) => onTap(e.globalPosition),
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: d,
                    height: d,
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
                    child: Icon(icon, size: big ? 30 : 24, color: ring),
                  ),
                  if ((count ?? 0) > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFC0261E), borderRadius: BorderRadius.circular(9)),
                        child: Text(enDigits('$count'), style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ),
                ],
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
