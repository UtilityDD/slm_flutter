import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
import 'golden_field.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Lesson 1.7, কাজ 2: "গোল্ডেন মিনিট" (ladder step 21). The colleague is off
// the wire but does not move. On a drawn village field, by hand and in order
// (lesson 1.7 points 3–4):
//   1. tap his shoulder — the trainee calls “আপনি ঠিক আছেন?” (response);
//   2. hold by his face — look and listen for breathing;
//   3. point at someone in the crowd to call the ambulance (calling yourself
//      first is a slip: "অন্য কাউকে অবিলম্বে Ambulance/Emergency-তে কল করতে বলুন");
//   4. CPR: tap the middle of the chest in time ("বুকের মাঝখানে চাপ");
//   5. keep going until help comes (the ambulance arrives, or he comes round —
//      "Ambulance না আসা বা জ্ঞান না ফেরা পর্যন্ত CPR চালিয়ে যান").
// The lesson gives no compression rate: the beat scores for staying within
// 100–120 compressions a minute, the American Heart Association guideline
// (owner decision 2026-11-08; the cards cite "AHA নির্দেশিকা"). In rhythm adds
// 5 ◆ to the CPR step's table; off rhythm is feedback, never a slip.
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" after each right step → the
// next by itself; the careless coworker once a play with one of the crowd's
// myths (dealt): "মাটিতে পুঁতে দাও" or "পোড়ায় বরফ ঘষো" before CPR, or —
// when he comes round — "কথা বলছে, হাসপাতাল লাগবে না" (lesson 1.7 myth
// buster and pro tips).
//
// Deadly: none (owner-approved list: wrong order costs points). Slips: a step
// out of order (it stays to do); calling the ambulance yourself first;
// stopping CPR before help comes; listening to the coworker. Three slips
// strike the level out.
//
// Kit timing (audit 2026-11-11): no hand on the scene works in the praise
// window (`tableBusy`); once he is scheduled, the move that would finish the
// next step waits for him (`holdForCoworker`), so a fast play cannot skip
// him; his before-CPR myths are dropped once CPR has begun (they no longer
// fit), the "talking" myth comes only after he has come round. Gesture
// hints: a sweep over every place to touch while a step waits (never the
// next one), a tap on the chest while CPR waits for a compression.
//
// Voice: the guide's lines by device TTS; the coworker in his recorded voice.
// Art: the field is drawn in code (golden_field.dart); mistake pictures in
// assets/game/art/shock/golden_*.svg.

// ============================================================================
// Content
// ============================================================================

/// The five steps, in the lesson's order.
enum GoldenStep { response, breathing, call, cpr, keep }

/// What the hands do on the scene.
enum GoldenAct { shoulder, face, crowd, chest, phone }

/// The crowd's myths. [lowVolt] is no longer dealt (kept for the mistakes
/// book: the 2026-11-07 build could book it).
enum CrowdMyth { mud, ice, home, lowVolt }

/// The myths the coworker can push.
const dealtMyths = [CrowdMyth.mud, CrowdMyth.ice, CrowdMyth.home];

abstract final class GoldenLines {
  static const title = 'গোল্ডেন মিনিট';
  static const intro = 'সহকর্মী তারের থেকে আলাদা — কিন্তু নড়ছে না! গোল্ডেন মিনিট শুরু, এখনই!';

  /// Screen-reader names of the progress dots (on screen they are dots only).
  static const rounds = ['1', '2', '3', '4', '5'];

  // The corner guide: the next task only (never which step it is).
  static const askFirst = 'সহকর্মী নড়ছে না। প্রথমে কী করবেন?';
  static const askNext = 'এবার কী করবেন?';
  static const askCpr = 'আপনি প্রশিক্ষিত — বুকের মাঝখানে, তালে তালে চাপ দিন।';
  static const holdOn = 'একটু সময় নিয়ে দেখুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askFirst, askNext, askCpr];

  // What the trainee says and finds (scene bubbles and chips).
  static const shout = 'আপনি ঠিক আছেন?';
  static const askCall = 'আপনি — এখনই অ্যাম্বুলেন্সে কল করুন!';
  static const noResponse = 'সাড়া নেই';
  static const noBreath = 'শ্বাস নেই';
  static const silent = '…';
  static const cameRoundSays = 'আ… আমি ঠিক আছি…';
  static const ambulance = 'অ্যাম্বুলেন্স';

  // Screen-reader names of the places to touch.
  static const zoneShoulder = 'কাঁধ';
  static const zoneFace = 'মুখ';
  static const zoneChest = 'বুক';
  static const zoneCrowd = 'ভিড়ের একজন';
  static const zonePhone = 'ফোন';

  // The CPR meter (a label a worker reads on a CPR feedback meter).
  static const perMinute = 'চাপ/মিনিট';
  static const aha = 'AHA নির্দেশিকা: 100–120';
  static String average(int n) => enDigits('গড় $n/মিনিট');

  // The guide after the beat.
  static const helpCame = 'অ্যাম্বুলেন্স এসে গেছে!';
  static const cameRound = 'জ্ঞান ফিরেছে!';
  static const rhythmGood = 'দারুণ তাল — AHA নির্দেশিকা মতো, মিনিটে 100–120।';
  static const rhythmOff = 'তাল ঠিক হয়নি — AHA নির্দেশিকা: মিনিটে 100–120 বার।';
  static const dontStop = 'থামবেন না — চাপ দিন!';

  // The reasons, one deck per step (lesson 1.7 points 3–4, the CPR science).
  // No rate card: the meter and the guide already show the AHA rate. Every
  // card of a deck is about the same length and fits one line on a 360 dp
  // phone, so none stands out; "CPR" is on wrong cards too, so it is no tell.
  static const whyResponse = 'কেন আগে ডেকে সাড়া দেখলেন?';
  static const whyBreathing = 'কেন শ্বাস দেখলেন?';
  static const whyCall = 'কেন অন্যকে কল করতে বললেন?';
  static const whyCpr = 'কেন বুকের মাঝখানে চাপ দিলেন?';
  static const whyKeep = 'কেন থামেননি?';
  static String why(GoldenStep s) => switch (s) {
        GoldenStep.response => whyResponse,
        GoldenStep.breathing => whyBreathing,
        GoldenStep.call => whyCall,
        GoldenStep.cpr => whyCpr,
        GoldenStep.keep => whyKeep,
      };

  static const responseRight = [
    'সাড়া দিলে বুঝি হৃৎপিণ্ড আর শ্বাস চলছে',
    'সাড়া দেখেই পরের পদক্ষেপ ঠিক হয়',
    'সাড়া না পেলে অবস্থা খুবই গুরুতর',
  ];
  static const responseWrong = [
    'ঝাঁকালে শরীরের বিদ্যুৎ বেরিয়ে যায়',
    'জোরে ঝাঁকালেই সঙ্গে সঙ্গে জ্ঞান ফেরে',
    'সাড়া না দিলেও ভয়ের তেমন কিছু নেই',
    'ঝাঁকুনিতেই CPR-এর কাজটা হয়ে যায়',
    'সাড়া দিলে আর হাসপাতালে নিতে হয় না',
    'সাড়া দেখা শুধু নিয়ম, এর কাজ নেই',
  ];
  static const breathingRight = [
    'সাড়া-শ্বাস না থাকলে তবেই CPR লাগে',
    'শ্বাস বন্ধ মানে অবস্থা খুবই গুরুতর',
    'শ্বাস দেখেই পরের ধাপ ঠিক করা যায়',
  ];
  static const breathingWrong = [
    'মুখের কাছে ফুঁ দিলেই জ্ঞান ফিরে আসে',
    'শ্বাস না থাকলে CPR-এ আর লাভ নেই',
    'শ্বাস দেখা ডাক্তারের কাজ, আমার নয়',
    'শ্বাস চললে আর অ্যাম্বুলেন্স লাগে না',
    'মুখে জল ছিটালেই শ্বাস ফিরে আসে',
    'নাকে হাত দিলে শরীরের বিদ্যুৎ নেমে যায়',
  ];
  static const callRight = [
    'আমি CPR দিই, অন্যজন কল করুক',
    'কেউ কল করুক, আমি বুকে চাপ দিই',
    'কল আর চাপ একসাথে চললে সময় বাঁচে',
  ];
  static const callWrong = [
    'কল করা আমার কাজ নয়, ও-ই করুক',
    'আমি না ডাকলেও অ্যাম্বুলেন্স আসবে',
    'ভিড় সামলাক, আমি একটু জিরিয়ে নিই',
    'আমার ফোনে টাকা নেই, তাই ও কল করুক',
    'ওকে কাজটা দিই, নিজে ঝামেলায় যাব না',
    'CPR শেষে কল করলেও ক্ষতি নেই',
    'কল হলে আর বুকে চাপ দিতে হয় না',
    'আগে ভিড় সরাই, পরে বুকে চাপ দিই',
  ];
  static const cprRight = [
    'বুকে চাপে মস্তিষ্কে অক্সিজেন পৌঁছায়',
    'শক প্রায়ই হৃৎপিণ্ড থামায়, চাপে রক্ত চলে',
    'বুকে চাপই কৃত্রিম পাম্পের কাজ করে',
  ];
  static const cprWrong = [
    'বুকে চাপে শরীরের বিদ্যুৎ বেরিয়ে যায়',
    'বুকে জোরে চাপলেই সাথে সাথে জ্ঞান ফেরে',
    'যত দ্রুত পারি চাপি, গোনার দরকার নেই',
    'মিনিটে 60 বার আস্তে চাপ দিলেই যথেষ্ট',
    'ভিড়কে দেখাতে হয় যে কিছু একটা করছি',
    'চাপে নয়, বাতাসেই মস্তিষ্কে অক্সিজেন যায়',
  ];
  static const keepRightAmbulance = [
    'থামলে মস্তিষ্কে অক্সিজেন যাওয়া বন্ধ হয়',
    '4–6 মিনিটেই মস্তিষ্কের ক্ষতি শুরু হয়',
    'অ্যাম্বুলেন্স না আসা পর্যন্ত CPR-ই ভরসা',
  ];
  static const keepRightAwake = [
    'জ্ঞান না ফেরা পর্যন্ত CPR চালাতে হয়',
    'থামলে মস্তিষ্কে অক্সিজেন যাওয়া বন্ধ হয়',
    '4–6 মিনিটেই মস্তিষ্কের ক্ষতি শুরু হয়',
  ];
  static const keepWrong = [
    'দু-এক মিনিট CPR দিলেই কাজ হয়ে যায়',
    'হাত ব্যথা করলে একটু থেমে যেতে হয়',
    'জ্ঞান না ফিরলে আর চেষ্টা করে লাভ নেই',
    'ভিড়ের সামনে থামলে খুব লজ্জা হয়',
    'অ্যাম্বুলেন্সের লোকেরা রাগ করবে, তাই',
    'থামলে মস্তিষ্ক একটু বিশ্রাম পায়',
    'মস্তিষ্কের ক্ষতি তো আগেই হয়ে গেছে',
  ];

  /// The right reasons for [s] as the player did it.
  static List<String> whyRight(GoldenStep s, {bool awake = false}) => switch (s) {
        GoldenStep.response => responseRight,
        GoldenStep.breathing => breathingRight,
        GoldenStep.call => callRight,
        GoldenStep.cpr => cprRight,
        GoldenStep.keep => awake ? keepRightAwake : keepRightAmbulance,
      };

  /// The wrong reasons for [s] (realistic excuses and the lesson's myths).
  static List<String> whyWrong(GoldenStep s) => switch (s) {
        GoldenStep.response => responseWrong,
        GoldenStep.breathing => breathingWrong,
        GoldenStep.call => callWrong,
        GoldenStep.cpr => cprWrong,
        GoldenStep.keep => keepWrong,
      };

  // The careless coworker (his recorded voice) with the crowd's myths, in
  // the lesson's words (myth buster; pro tips 3 and 4).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerAsks = [
    'ও কী বলছে শুনলেন? আপনি কী করবেন?',
    'ওর কথা শুনবেন, না নিয়ম মানবেন?',
    'ওকে কী বলবেন?',
  ];
  static const coworkerMud = CoworkerScript(
    line: 'ওকে মাটিতে পুঁতে দাও, কাদা মাখাও — ভেতরের বিদ্যুৎ বেরিয়ে যাবে!',
    exitLine: coworkerExit,
    right: ['না, গুজব — অ্যাম্বুলেন্সই একমাত্র পথ', 'কাদায় সময় নষ্ট, ক্ষতে সংক্রমণ বাড়ে', 'মাটি নয় — ডাক্তার আর অ্যাম্বুলেন্স চাই'],
    wrong: [
      'ঠিক, কাদা মাখালে বিদ্যুৎ বেরিয়ে যাবে',
      'আচ্ছা, একটু মাটিতে পুঁতে দেখি কী হয়',
      'সবাই যখন বলছে, তাহলে পুঁতেই দিই',
      'গ্রামে তো এভাবেই সারায়, ঠিক আছে',
      'আগে কাদা মাখাই, তারপর অ্যাম্বুলেন্স',
      'অ্যাম্বুলেন্স না আসা পর্যন্ত কাদা দিই',
    ],
    asks: coworkerAsks,
  );
  static const coworkerIce = CoworkerScript(
    line: 'হাতের পোড়া জায়গায় বরফ ঘষো, মলম লাগাও — জ্বালা কমবে!',
    exitLine: coworkerExit,
    right: ['না, পোড়ায় হাত নয় — ডাক্তার দেখবেন', 'বরফ, জল বা মলম — কিছুই লাগানো নয়', 'পোড়া জায়গা ছোঁব না, হাসপাতালে নেব'],
    wrong: [
      'ঠিক, বরফ ঘষলে জ্বালাটা কমে যাবে',
      'আচ্ছা, একটু মলম লাগিয়ে দিই তাহলে',
      'জল ঢাললে ক্ষতি নয়, জ্বালা কমে যাবে',
      'সবাই তো পোড়ায় বরফ দেয়, আমিও দিই',
      'আগে মলম লাগাই, তারপর অ্যাম্বুলেন্স',
      'ডাক্তার না আসা পর্যন্ত বরফটা ঘষি',
      'বরফ ঘষা ক্ষতি নয়, না ঘষলে জ্বালা বাড়বে',
    ],
    asks: coworkerAsks,
  );
  static const coworkerHome = CoworkerScript(
    line: 'ওই তো কথা বলছে! হাসপাতাল লাগবে না, বাড়ি পাঠিয়ে দাও।',
    exitLine: coworkerExit,
    right: ['কথা বললেও হাসপাতালে নিতেই হবে', 'ভেতরের ক্ষতি বাইরে দেখা যায় না', 'একা ছাড়ব না — অ্যাম্বুলেন্সে তুলব'],
    wrong: [
      'ঠিক, কথা বলছে মানে সব ঠিক আছে',
      'আচ্ছা, একটু জল খাইয়ে বাড়ি পাঠাই',
      'তাহলে অ্যাম্বুলেন্সটা ফিরিয়ে দিই',
      'একটু বিশ্রাম নিলেই সেরে যাবে',
      'কাল সকালে ডাক্তার দেখালেই হবে',
      'অ্যাম্বুলেন্স লাগবে না, বাড়ি পাঠাই',
      'হাসপাতাল লাগবে না, ভালোই তো আছে',
    ],
    asks: coworkerAsks,
  );
  static const coworkers = [coworkerMud, coworkerIce, coworkerHome];
  static CoworkerScript coworker(CrowdMyth m) => switch (m) {
        CrowdMyth.ice => coworkerIce,
        CrowdMyth.home => coworkerHome,
        _ => coworkerMud,
      };

  /// The guide when he is refused.
  static String held(CrowdMyth m) => switch (m) {
        CrowdMyth.mud => 'ঠিক! কাদা-মাটি সময় নষ্ট আর ক্ষতে সংক্রমণ।',
        CrowdMyth.ice => 'ঠিক! পোড়ায় বরফ-জল-মলম নয় — ডাক্তার দেখবেন।',
        CrowdMyth.home => 'ঠিক! কথা বললেও হাসপাতাল — ভেতরের ক্ষতি দেখা যায় না।',
        CrowdMyth.lowVolt => 'ঠিক! ভোল্টেজ নয়, কারেন্ট মারে — এলটিও।',
      };

  static const allSet = 'গোল্ডেন মিনিটের হিরো — ধাপে ধাপে, গুজবে না।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — সাড়া, শ্বাস, অ্যাম্বুলেন্স, CPR।';
  static const caughtOrder = 'সাড়া → শ্বাস → কল → CPR, ঠিক ক্রমে';
  static const caughtRhythm = 'CPR তালে তালে — মিনিটে 100–120';
  static const caughtKeep = 'সাহায্য না আসা পর্যন্ত থামেননি';
  static const caughtCrowd = 'অসাবধান সহকর্মীর গুজবে “না”';
}

abstract final class GoldenMistakes {
  /// A step before the checks (response and breathing come first).
  static const order = DoMistake(
    key: '1.7/golden/order',
    textBn: 'আগে কাঁধে আলতো ঝাঁকুনি দিয়ে জোরে ডাকুন — “আপনি ঠিক আছেন?” — আর দেখুন শ্বাস চলছে কিনা। তারপর পরের পদক্ষেপ।',
    art: 'assets/game/art/shock/golden_order.svg',
    lessonPoint: 2,
  );

  /// CPR before anyone was asked to call.
  static const cprFirst = DoMistake(
    key: '1.7/golden/cpr-first',
    textBn: 'সাড়া নেই, শ্বাস নেই — আগে অন্য কাউকে অবিলম্বে অ্যাম্বুলেন্সে কল করতে বলুন, তারপর প্রশিক্ষিত হলে CPR।',
    art: 'assets/game/art/shock/golden_call.svg',
    lessonPoint: 3,
  );

  /// The trainee reached for the phone himself.
  static const callSelf = DoMistake(
    key: '1.7/golden/call-self',
    textBn: 'নিজে ফোনে ব্যস্ত হবেন না — অন্য কাউকে অবিলম্বে অ্যাম্বুলেন্সে কল করতে বলুন, আপনি থাকুন CPR-এর জন্য।',
    art: 'assets/game/art/shock/golden_call.svg',
    lessonPoint: 3,
  );

  /// CPR stopped before help came.
  static const stopped = DoMistake(
    key: '1.7/golden/stopped',
    textBn: 'থামবেন না — অ্যাম্বুলেন্স না আসা বা জ্ঞান না ফেরা পর্যন্ত CPR চালিয়ে যান।',
    art: 'assets/game/art/shock/golden_keep.svg',
    lessonPoint: 3,
  );

  static DoMistake myth(CrowdMyth m) => switch (m) {
        CrowdMyth.mud => const DoMistake(
            key: '1.7/golden/mud',
            textBn: 'মাটিতে পোঁতা বা কাদা মাখানো ভয়ঙ্কর গুজব — সময় নষ্ট করে, পোড়া ক্ষতে সংক্রমণ বাড়ায়। অবিলম্বে ডাক্তার/অ্যাম্বুলেন্সই একমাত্র উপায়।',
            art: 'assets/game/art/shock/golden_mud.svg',
            lessonPoint: 3),
        CrowdMyth.ice => const DoMistake(
            key: '1.7/golden/ice',
            textBn: 'বিদ্যুতে পোড়া জায়গায় বরফ, জল বা মলম নয় — হাত দেবেন না, ডাক্তারের কাছে নিন।',
            art: 'assets/game/art/shock/golden_burn.svg',
            lessonPoint: 3),
        CrowdMyth.home => const DoMistake(
            key: '1.7/golden/home',
            textBn: 'কথা বললেও হাসপাতালে নিন, ভিকটিমকে একা ছাড়বেন না — ভেতরের ক্ষতি বাইরে দেখা যায় না।',
            art: 'assets/game/art/shock/golden_home.svg',
            lessonPoint: 3),
        CrowdMyth.lowVolt => const DoMistake(
            key: '1.7/golden/low-volt',
            textBn: 'ভোল্টেজ নয়, কারেন্ট মারে — এলটি শকও ভেজা শরীরে হৃৎপিণ্ড থামাতে পারে। হাসপাতালে নিন।',
            art: 'assets/game/art/shock/golden_home.svg',
            lessonPoint: 3),
      };

  static List<DoMistake> get all => [order, cprFirst, callSelf, stopped, for (final m in CrowdMyth.values) myth(m)];
}

// --- the deal ----------------------------------------------------------------

/// One play: the coworker's myth and when he comes, the crowd's looks, where
/// the phone lies.
@immutable
class GoldenDeal {
  const GoldenDeal({required this.myth, required this.mythAt, required this.crowd, required this.phoneLeft});
  final CrowdMyth myth;

  /// He comes once this step is next (breathing or call); null = after the
  /// beat (the "he is talking" myth, once he has come round).
  final GoldenStep? mythAt;
  final List<Bystander> crowd;
  final bool phoneLeft;

  /// He comes round at the end of the beat (the "talking" myth needs it);
  /// otherwise the ambulance arrives.
  bool get comesRound => myth == CrowdMyth.home;
}

GoldenDeal dealGolden(math.Random rng) {
  final myth = dealtMyths[rng.nextInt(dealtMyths.length)];
  final at = myth == CrowdMyth.home ? null : (rng.nextBool() ? GoldenStep.breathing : GoldenStep.call);
  final crowd = ([...Bystander.values]..shuffle(rng)).take(3).toList();
  return GoldenDeal(myth: myth, mythAt: at, crowd: crowd, phoneLeft: rng.nextBool());
}

// --- the rules (no widgets) --------------------------------------------------

enum GoldenMoveKind { ok, ignored, slip }

@immutable
class GoldenMove {
  const GoldenMove(this.kind, [this.mistake]);
  final GoldenMoveKind kind;
  final DoMistake? mistake;
}

/// The play's rules: the steps in order, the slips, the mark.
class GoldenRun {
  GoldenRun(this.deal);
  final GoldenDeal deal;

  /// The index of the next step to do (5 = all done).
  int next = 0;
  int slips = 0;
  int orderSlips = 0;
  var _stopBooked = false;
  final List<String> caught = [];

  GoldenStep? get pending => next < GoldenStep.values.length ? GoldenStep.values[next] : null;

  /// [a] would do the next step now (the move the coworker is held for).
  bool advances(GoldenAct a) => !done && !inCpr && a != GoldenAct.phone && _stepOf(a) == next;
  bool get done => next >= GoldenStep.values.length;

  /// CPR has started and help has not come yet.
  bool get inCpr => next == GoldenStep.keep.index;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => percent >= 55;

  static int _stepOf(GoldenAct a) => switch (a) {
        GoldenAct.shoulder => GoldenStep.response.index,
        GoldenAct.face => GoldenStep.breathing.index,
        GoldenAct.crowd => GoldenStep.call.index,
        GoldenAct.chest => GoldenStep.cpr.index,
        GoldenAct.phone => GoldenStep.call.index,
      };

  /// A move on the scene. Right: the step is done. Out of order: a slip and
  /// the step stays to do. A step already done: ignored.
  GoldenMove act(GoldenAct a) {
    if (done || inCpr) return const GoldenMove(GoldenMoveKind.ignored);
    if (a == GoldenAct.phone) {
      if (next > GoldenStep.call.index) return const GoldenMove(GoldenMoveKind.ignored);
      slips++;
      return const GoldenMove(GoldenMoveKind.slip, GoldenMistakes.callSelf);
    }
    final s = _stepOf(a);
    if (s < next) return const GoldenMove(GoldenMoveKind.ignored);
    if (s == next) {
      next++;
      return const GoldenMove(GoldenMoveKind.ok);
    }
    slips++;
    orderSlips++;
    return GoldenMove(GoldenMoveKind.slip, next <= GoldenStep.breathing.index ? GoldenMistakes.order : GoldenMistakes.cprFirst);
  }

  /// Hands off the chest before help came: a slip the first time, then only
  /// a reminder (null).
  DoMistake? stopped() {
    if (!inCpr || _stopBooked) return null;
    _stopBooked = true;
    slips++;
    return GoldenMistakes.stopped;
  }

  bool get stoppedEver => _stopBooked;

  /// Help came (the ambulance, or he came round): the last step is done.
  void helpCame() {
    if (inCpr) next = GoldenStep.values.length;
  }

  /// Listened to the coworker.
  DoMistake listened(CrowdMyth m) {
    slips++;
    return GoldenMistakes.myth(m);
  }
}

/// The compressions' rhythm. The lesson gives no rate; the AHA guideline is
/// 100–120 a minute (an interval of 500–600 ms).
class GoldenRhythm {
  static const minMs = 500;
  static const maxMs = 600;

  /// A longer gap is a pause, not a compression interval; a shorter one is
  /// a double tap.
  static const pauseMs = 1500;
  static const bounceMs = 100;

  final List<int> _taps = [];

  void add(int ms) => _taps.add(ms);
  int get count => _taps.length;

  List<int> get intervals => [
        for (var i = 1; i < _taps.length; i++)
          if (_taps[i] - _taps[i - 1] <= pauseMs && _taps[i] - _taps[i - 1] >= bounceMs) _taps[i] - _taps[i - 1],
      ];

  static int _perMinute(Iterable<int> ivs) {
    final sum = ivs.fold<int>(0, (a, b) => a + b);
    return sum <= 0 ? 0 : (60000 * ivs.length / sum).round();
  }

  /// The rate over the last few compressions (null before two).
  int? get rate {
    final iv = intervals;
    if (iv.isEmpty) return null;
    return _perMinute(iv.skip(math.max(0, iv.length - 4)));
  }

  int? get average {
    final iv = intervals;
    return iv.isEmpty ? null : _perMinute(iv);
  }

  /// The share of intervals within 100–120 a minute.
  double get share {
    final iv = intervals;
    if (iv.isEmpty) return 0;
    return iv.where((x) => x >= minMs && x <= maxMs).length / iv.length;
  }

  bool get good => intervals.length >= 6 && share >= 0.5;
}

/// The beat: help comes after this much active CPR (the ambulance is seen
/// coming for its last [kAmbulanceMs]); a gap of [kGapMs] is a stop.
const kBeatMs = 9000;
const kAmbulanceMs = 3000;
const kGapMs = 2500;

/// The metronome's beat on the chest: 110 a minute.
const kMetronomeMs = 545;

@immutable
class GoldenPack {
  const GoldenPack({required this.id, required this.titleBn, this.quickMs = 75000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const goldenPack17 = GoldenPack(id: 'do_1_7_b', titleBn: GoldenLines.title);
const goldenPacks = {'do_1_7_b': goldenPack17};

// ============================================================================
// Page
// ============================================================================

class GoldenMinutePage extends StatefulWidget {
  const GoldenMinutePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final GoldenPack pack;
  final bool muted;
  final int? seed;

  @override
  State<GoldenMinutePage> createState() => _GoldenMinutePageState();
}

class _GoldenMinutePageState extends State<GoldenMinutePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GoldenRunPage(
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

class _GoldenRunPage extends ConsumerStatefulWidget {
  const _GoldenRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final GoldenPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GoldenRunPage> createState() => _GoldenRunPageState();
}

class _GoldenRunPageState extends ConsumerState<_GoldenRunPage>
    with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  // Dealt first, before any other draw from the play's random.
  late final GoldenRun _run;
  GoldenDeal get _deal => _run.deal;
  final _rhythm = GoldenRhythm();
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _nudge = TaskNudge();
  int _nudgeN = 0;
  final _hints = IdleHintController();

  /// The scene's geometry as last laid out (the gesture hint anchors on it).
  GoldenGeo? _geo;

  /// Looking and listening by his face: 0 → 1 while the finger stays.
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _breathChecked();
    });

  /// The ambulance driving in: 0 → 1.
  late final AnimationController _amb = AnimationController(vsync: this, duration: const Duration(milliseconds: kAmbulanceMs));

  /// Compressions so far (the press animation and the meter listen to it).
  final _compressions = ValueNotifier<int>(0);

  /// The metronome's beats (the pulse ring listens to it).
  final _metroBeat = ValueNotifier<int>(0);
  Timer? _metro;
  late final Ticker _beatTicker = createTicker(_onBeatTick);
  Duration _tickLast = Duration.zero;

  /// CPR time so far (ms, only while compressing), the last compression,
  /// and the rhythm clock's offset over pauses.
  int _beatNow = 0;
  int _lastTapAt = 0;
  int _rhythmBase = 0;
  var _ambComing = false;

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  VoidCallback? _afterCard;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  // The scene.
  RescuerPose _pose = RescuerPose.rest;
  int _shakes = 0;
  int? _pointAt;
  int? _caller;
  String? _said;
  int _saidTok = 0;
  String? _victimSays;
  var _noResponse = false;
  var _noBreath = false;
  var _holding = false;

  // The beat.
  var _cpr = false;
  var _paused = false;
  var _beatOver = false;
  var _awake = false;
  var _arrived = false;
  bool? _rhythmGood;
  var _wrapping = false;
  GoldenStep? _paying;

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void initState() {
    super.initState();
    _run = GoldenRun(dealGolden(widget.rng));
  }

  @override
  void dispose() {
    disposeCoworker();
    _stopTimers();
    _beatTicker.dispose();
    _hold.dispose();
    _amb.dispose();
    _compressions.dispose();
    _metroBeat.dispose();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  void _stopTimers() {
    _metro?.cancel();
    if (_beatTicker.isActive) _beatTicker.stop();
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

  String get _ask => _run.inCpr ? GoldenLines.askCpr : (_run.next == 0 ? GoldenLines.askFirst : GoldenLines.askNext);

  /// After the guide's intro: the clock runs (no glow on any place to touch;
  /// the gesture hint shows how to touch after idle or missed taps).
  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([GoldenLines.askFirst]));
  }

  bool get _canPlay =>
      !_intro &&
      !_busy &&
      !_ended &&
      _card == null &&
      !tableBusy &&
      tablePending == 0 &&
      !coworkerOpen &&
      !_holding &&
      !_wrapping &&
      !_run.done &&
      !_run.inCpr;

  // --- the hands ----------------------------------------------------------------
  void _touch(GoldenAct a, Offset origin, {int? who}) {
    if (_run.inCpr) {
      if (a == GoldenAct.chest) _compress();
      return;
    }
    if (!_canPlay) return;
    // Once he is scheduled, the move that would do the next step waits for
    // him: he comes now (a fast play cannot skip him).
    if (_run.advances(a) && holdForCoworker()) return;
    if (a == GoldenAct.face && _run.pending == GoldenStep.breathing) {
      _startHold();
      return;
    }
    final m = _run.act(a);
    switch (m.kind) {
      case GoldenMoveKind.ignored:
        HapticFeedback.selectionClick();
        if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.35, muted: false));
      case GoldenMoveKind.slip:
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(m.mistake!, then: () => unawaited(_sayChain([_ask]))));
      case GoldenMoveKind.ok:
        switch (a) {
          case GoldenAct.shoulder:
            unawaited(_checkResponse());
          case GoldenAct.crowd:
            unawaited(_askToCall(who ?? 0));
          case GoldenAct.chest:
            _startCpr();
          case GoldenAct.face:
          case GoldenAct.phone:
            break;
        }
    }
  }

  void _right() {
    HapticFeedback.lightImpact();
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: false));
    }
  }

  /// The step is done: its ◆ go on the table, then "কেন …?".
  void _table(GoldenStep s, int amount) {
    _right();
    _paying = s;
    putOnTable(amount);
    unawaited(askReason(
      deal: () => dealChoices(GoldenLines.whyRight(s, awake: _awake), GoldenLines.whyWrong(s), widget.rng),
      question: GoldenLines.why(s),
      stillValid: () => _paying == s && !_ended,
    ));
  }

  Future<void> _traineeSays(String line, int minMs) async {
    setState(() {
      _said = line;
      _saidTok++;
    });
    await Future.wait([
      MascotSpeechLibrary.speak(line, muted: _muted),
      Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : minMs)),
    ]);
  }

  Future<void> _checkResponse() async {
    _hush();
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _pose = RescuerPose.shoulder;
      _shakes++;
    });
    await _traineeSays(GoldenLines.shout, 1300);
    if (!mounted || _ended) return;
    setState(() {
      _said = null;
      _victimSays = GoldenLines.silent;
      _noResponse = true;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 700));
    if (!mounted || _ended) return;
    setState(() {
      _busy = false;
      _pose = RescuerPose.rest;
      _victimSays = null;
    });
    _table(GoldenStep.response, 5);
  }

  void _startHold() {
    _hush();
    HapticFeedback.selectionClick();
    setState(() {
      _holding = true;
      _pose = RescuerPose.face;
    });
    _hold.duration = Duration(milliseconds: _quiet ? 700 : 1800);
    unawaited(_hold.forward(from: 0));
  }

  void _releaseFace() {
    if (!_holding || _hold.isCompleted) return;
    _hold.stop();
    _hold.value = 0;
    setState(() {
      _holding = false;
      _pose = RescuerPose.rest;
    });
    unawaited(_sayChain([GoldenLines.holdOn]));
  }

  void _breathChecked() {
    if (!mounted || !_holding) return;
    final m = _run.act(GoldenAct.face);
    setState(() {
      _holding = false;
      _hold.value = 0;
      _noBreath = true;
      _pose = RescuerPose.rest;
    });
    if (m.kind == GoldenMoveKind.ok) _table(GoldenStep.breathing, 5);
  }

  Future<void> _askToCall(int who) async {
    _hush();
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _pose = RescuerPose.point;
      _pointAt = who;
    });
    await _traineeSays(GoldenLines.askCall, 1500);
    if (!mounted || _ended) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.6, muted: false));
    setState(() {
      _said = null;
      _caller = who;
      _busy = false;
      _pose = RescuerPose.rest;
      _pointAt = null;
    });
    _table(GoldenStep.call, 5);
  }

  // --- CPR: the beat --------------------------------------------------------------
  // The beat runs on frame time (a ticker, only while compressing): the
  // rhythm, the stop (no compression for kGapMs) and help coming.
  void _startCpr() {
    _hush();
    if (_run.orderSlips == 0) _run.caught.add(GoldenLines.caughtOrder);
    setState(() {
      _cpr = true;
      _pose = RescuerPose.cpr;
      _noResponse = false;
      _noBreath = false;
    });
    unawaited(_sayChain([GoldenLines.askCpr]));
    _beatNow = 0;
    _rhythmBase = 0;
    _tickLast = Duration.zero;
    unawaited(_beatTicker.start());
    _startMetronome();
    _compress();
  }

  void _compress() {
    if (!_cpr || _ended || _card != null) return;
    if (_paused) _resumeBeat();
    _lastTapAt = _beatNow;
    _rhythm.add(_rhythmBase + _beatNow);
    _compressions.value++;
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.45, muted: false));
  }

  void _onBeatTick(Duration elapsed) {
    final d = (elapsed - _tickLast).inMilliseconds;
    _tickLast = elapsed;
    if (!_cpr || _paused || _ended || _card != null) return;
    _beatNow += d;
    if (!_deal.comesRound && !_ambComing && _beatNow >= kBeatMs - kAmbulanceMs) _ambulanceComes();
    if (_beatNow >= kBeatMs) {
      _beatDone();
    } else if (_beatNow - _lastTapAt >= kGapMs) {
      _onGap();
    }
  }

  void _startMetronome() {
    _metro?.cancel();
    _metro = Timer.periodic(const Duration(milliseconds: kMetronomeMs), (_) {
      if (!mounted) return;
      _metroBeat.value++;
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tick.wav', volume: 0.3, muted: false));
    });
  }

  void _ambulanceComes() {
    _ambComing = true;
    if (!mounted || _ended) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/siren.wav', volume: 0.5, muted: false));
    if (!_quiet) unawaited(_amb.forward());
  }

  void _pauseBeat() {
    _paused = true;
    _metro?.cancel();
    _beatTicker.stop();
    _amb.stop();
  }

  void _resumeBeat() {
    _paused = false;
    // A pause is never a compression interval.
    _rhythmBase += GoldenRhythm.pauseMs + 1;
    _tickLast = Duration.zero;
    unawaited(_beatTicker.start());
    _startMetronome();
    if (_ambComing && !_quiet) unawaited(_amb.forward());
  }

  /// Hands off the chest: the first time a slip, later a reminder.
  void _onGap() {
    if (!mounted || !_cpr || _ended || _paused) return;
    _pauseBeat();
    final m = _run.stopped();
    if (m == null) {
      unawaited(_sayChain([GoldenLines.dontStop], mood: GuideMood.warn));
      return;
    }
    final size = MediaQuery.sizeOf(context);
    unawaited(_levelDelta(-10, Offset(size.width / 2, size.height * 0.5), mood: GuideMood.warn));
    unawaited(_slip(m, then: () => unawaited(_sayChain([GoldenLines.dontStop]))));
  }

  /// Help came: the ambulance pulled up, or he came round.
  void _beatDone() {
    if (!mounted || _ended || !_cpr) return;
    _stopTimers();
    _run.helpCame();
    final good = _rhythm.good;
    if (good) _run.caught.add(GoldenLines.caughtRhythm);
    if (!_run.stoppedEver) _run.caught.add(GoldenLines.caughtKeep);
    final awake = _deal.comesRound;
    if (!awake) _amb.value = 1;
    setState(() {
      _cpr = false;
      _beatOver = true;
      _rhythmGood = good;
      _awake = awake;
      _arrived = !awake;
      _pose = RescuerPose.rest;
      _victimSays = awake ? GoldenLines.cameRoundSays : null;
    });
    if (!_muted && !awake) unawaited(ZlFx.cue('sounds/van_arrive.wav', volume: 0.6, muted: false));
    unawaited(() async {
      await _sayChain([awake ? GoldenLines.cameRound : GoldenLines.helpCame, good ? GoldenLines.rhythmGood : GoldenLines.rhythmOff],
          mood: good ? GuideMood.glad : GuideMood.warn);
      if (!mounted || _ended) return;
      _table(GoldenStep.cpr, good ? 10 : 5);
    }());
  }

  /// After the last reason: the coworker (if he has not come), the
  /// ambulance (if it has not come), then the result.
  Future<void> _wrapUp() async {
    if (_ended) return;
    _wrapping = true;
    // Only the "talking" myth is left for the wrap-up (a before-CPR myth
    // no longer fits once help is here).
    if (!coworkerDone && _deal.mythAt == null) {
      setState(() {});
      scheduleCoworker();
      return; // onCoworkerAnswer comes back here.
    }
    if (!_arrived) {
      setState(() {
        _arrived = true;
        _victimSays = null;
      });
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/siren.wav', volume: 0.5, muted: false));
      if (_quiet) {
        _amb.value = 1;
      } else {
        unawaited(_amb.animateTo(1, duration: const Duration(milliseconds: 2400)));
      }
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 2600));
      if (!mounted || _ended) return;
      if (!_muted) unawaited(ZlFx.cue('sounds/van_arrive.wav', volume: 0.6, muted: false));
      await _sayChain([GoldenLines.helpCame], mood: GuideMood.glad);
    }
    if (mounted) unawaited(_finish());
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
    final s = _paying;
    _paying = null;
    switch (s) {
      case GoldenStep.cpr:
        _table(GoldenStep.keep, 15);
      case GoldenStep.keep:
        unawaited(_wrapUp());
      default:
        setState(() {});
        _armCoworker();
        unawaited(_sayChain([_ask]));
    }
  }

  /// Before CPR he comes once his step is next.
  void _armCoworker() {
    if (coworkerDue || coworkerDone) return;
    final at = _deal.mythAt;
    if (at == null || _run.next < at.index) return;
    scheduleCoworker();
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => GoldenLines.coworker(_deal.myth);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (_deal.mythAt != null) {
      // Mud / ice: before CPR only (the chest tap waits for him); once CPR
      // has begun his push no longer fits the moment.
      if (_cpr || _beatOver || _run.inCpr || _run.done) return null;
    } else if (!_awake || !_wrapping) {
      // "He is talking": only once he has come round, at the wrap-up.
      return false;
    }
    if (_intro || _busy || _holding || _card != null || tableBusy || tablePending > 0) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    void goOn() {
      if (_wrapping) {
        unawaited(_wrapUp());
      } else {
        unawaited(_sayChain([_ask]));
      }
    }

    if (!held) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(_run.listened(_deal.myth), then: goOn);
      return;
    }
    _run.caught.add(GoldenLines.caughtCrowd);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    await _sayChain([GoldenLines.held(_deal.myth)], mood: GuideMood.glad);
    if (!mounted || _ended) return;
    goOn();
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? GoldenLines.tapWhy[_nudgeN++ % GoldenLines.tapWhy.length]
            : _nudge.next(_ask);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  /// A tap on the field away from him, the crowd and the phone: a miss for
  /// the gesture hint (three quick misses show how to touch).
  void _tapField() {
    if (_canPlay || (_cpr && _card == null && !_ended)) _hints.missTap();
  }

  // --- the gesture hint (how to touch, never what) -----------------------------
  /// Every place to touch on the scene, in design pixels.
  List<Rect> _zoneRects(GoldenGeo geo) {
    final feet = geo.crowdFeet;
    return [
      Rect.fromCircle(center: geo.face, radius: 24),
      Rect.fromCircle(center: geo.shoulder, radius: 24),
      Rect.fromCircle(center: geo.chest, radius: 26),
      for (var i = 0; i < 3; i++) Rect.fromLTRB(feet[i].dx - 23, feet[i].dy - 100, feet[i].dx + 23, feet[i].dy + 6),
      if (_run.next <= GoldenStep.call.index) Rect.fromCircle(center: geo.phone(_deal.phoneLeft), radius: 24),
    ];
  }

  /// CPR waits for a compression (the chest is the one way forward).
  bool get _cprWaits => _cpr && _card == null && !_ended;

  bool get _hintWaiting => _cprWaits || (_canPlay && !coworkerOnScreen);

  /// A step waits: a sweep over every place to touch alike; CPR: tap the chest.
  HintSpec? _hintSpec() {
    final geo = _geo;
    if (geo == null) return null;
    if (_cprWaits) return HintSpec.tap(geo.chest, space: HintSpace.scene);
    return HintSpec.sweep(_zoneRects(geo), space: HintSpace.scene);
  }

  // --- mistakes ---------------------------------------------------------------
  /// The third small mistake: the level fails and the lesson card insists.
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _stopTimers();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, {VoidCallback? then}) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _afterCard = then;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('golden/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    final then = _afterCard;
    setState(() {
      _card = null;
      _afterCard = null;
    });
    then?.call();
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
    _stopTimers();
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
    await _say(!_run.passed ? GoldenLines.fail : (_quickBonus ? GoldenLines.quick : GoldenLines.allSet),
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
  Widget _zone(String key, String label, Rect r, GoldenAct a, {int? who, bool hold = false}) => Positioned.fromRect(
        key: ValueKey('zone-$key'),
        rect: r,
        child: Semantics(
          label: label,
          button: true,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _touch(a, e.position, who: who),
            onPointerUp: hold ? (_) => _releaseFace() : null,
            onPointerCancel: hold ? (_) => _releaseFace() : null,
          ),
        ),
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = GoldenGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final feet = geo.crowdFeet;
    final showZones = !_intro && _mark == null && !struckOut;
    final phoneOnGrass = _run.next <= GoldenStep.call.index;
    final rects = _zoneRects(geo);
    return [
      Positioned.fill(
        key: const ValueKey('field'),
        child: RepaintBoundary(child: CustomPaint(painter: GoldenFieldPainter(geo: geo))),
      ),
      Positioned.fill(
        key: const ValueKey('ambulance'),
        child: IgnorePointer(
          child: RepaintBoundary(child: CustomPaint(painter: AmbulancePainter(geo: geo, progress: _amb, label: GoldenLines.ambulance))),
        ),
      ),
      // The pole and its ladder stand nearer than the road: over the van.
      Positioned.fill(
        key: const ValueKey('field-near'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: GoldenFieldPainter(geo: geo, near: true)))),
      ),
      Positioned.fill(
        key: const ValueKey('crowd'),
        child: IgnorePointer(child: CustomPaint(painter: GoldenCrowdPainter(geo: geo, crowd: _deal.crowd, caller: _caller))),
      ),
      Positioned.fill(
        key: const ValueKey('patient'),
        child: IgnorePointer(
          child: ValueListenableBuilder<int>(
            valueListenable: _compressions,
            builder: (_, n, _) => TweenAnimationBuilder<double>(
              key: ValueKey('move-$n-$_shakes'),
              tween: Tween(begin: quiet || (n == 0 && _shakes == 0) ? 1.0 : 0.0, end: 1.0),
              duration: Duration(milliseconds: _pose == RescuerPose.cpr ? 300 : 900),
              builder: (_, t, _) => CustomPaint(
                painter: GoldenPatientPainter(
                  geo: geo,
                  pose: _pose,
                  press: _pose == RescuerPose.cpr ? math.sin(t * math.pi) : 0,
                  shake: _pose == RescuerPose.shoulder ? t : 1,
                  pointAt: _pointAt == null ? null : feet[_pointAt!] - const Offset(0, 70),
                  awake: _awake,
                  phoneLeft: phoneOnGrass ? _deal.phoneLeft : null,
                  burn: _deal.myth == CrowdMyth.ice,
                ),
              ),
            ),
          ),
        ),
      ),
      // A tap on the open field: a miss for the gesture hint (counted on the
      // finger's lift: the hint's own touch-down hides and re-arms first).
      if (showZones)
        Positioned.fill(
          key: const ValueKey('field-touch'),
          child: Listener(behavior: HitTestBehavior.translucent, onPointerUp: (_) => _tapField()),
        ),
      if (showZones) ...[
        _zone('face', GoldenLines.zoneFace, rects[0], GoldenAct.face, hold: true),
        _zone('shoulder', GoldenLines.zoneShoulder, rects[1], GoldenAct.shoulder),
        _zone('chest', GoldenLines.zoneChest, rects[2], GoldenAct.chest),
        for (var i = 0; i < 3; i++) _zone('crowd-$i', GoldenLines.zoneCrowd, rects[3 + i], GoldenAct.crowd, who: i),
        if (phoneOnGrass) _zone('phone', GoldenLines.zonePhone, rects[6], GoldenAct.phone),
      ],
      // Looking and listening: a ring fills round his face.
      if (_holding)
        Positioned.fromRect(
          key: const ValueKey('hold-ring'),
          rect: Rect.fromCircle(center: geo.face, radius: 30),
          child: IgnorePointer(child: CustomPaint(painter: _RingPainter(progress: _hold))),
        ),
      // The metronome on the chest during the beat.
      if (_cpr && !quiet)
        Positioned.fromRect(
          key: const ValueKey('pulse'),
          rect: Rect.fromCircle(center: geo.chest, radius: 34),
          child: IgnorePointer(
            child: ValueListenableBuilder<int>(
              valueListenable: _metroBeat,
              builder: (_, b, _) => TweenAnimationBuilder<double>(
                key: ValueKey('beat-$b'),
                tween: Tween(begin: b == 0 ? 1.0 : 0.0, end: 1.0),
                duration: const Duration(milliseconds: 420),
                builder: (_, t, _) => CustomPaint(painter: _PulsePainter(t)),
              ),
            ),
          ),
        ),
      // What the trainee says, what he found, what the colleague says.
      if (_said != null)
        Positioned(
          key: ValueKey('said-$_saidTok'),
          left: 100,
          width: 200,
          bottom: geo.height - (geo.lieY - 124),
          child: IgnorePointer(child: _Bubble(text: _said!, quiet: quiet)),
        ),
      if (_victimSays != null)
        Positioned(
          key: const ValueKey('victim-says'),
          left: 8,
          width: 150,
          bottom: geo.height - (geo.lieY - 28),
          child: IgnorePointer(child: _Bubble(text: _victimSays!, quiet: quiet, tail: false)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final meterUp = playing && (_cpr || (_beatOver && !_wrapping));
    final found = playing && !meterUp && (_noResponse || _noBreath);
    final done = _run.done ? 5 : (_run.inCpr ? 3 : _run.next);
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
              labels: GoldenLines.rounds,
              done: {for (var i = 0; i < done; i++) i},
              current: _run.done ? null : done,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hintSpec,
            hintWaiting: _hintWaiting,
            hintKey: 'golden-${_run.next}-$_cpr',
            hintController: _hints,
            overlays: [
              if (meterUp)
                Positioned(
                  key: const ValueKey('hud-meter'),
                  left: 16,
                  right: 16,
                  top: pad.top + 92,
                  child: IgnorePointer(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _compressions,
                      builder: (_, _, _) => _RateMeter(
                        rate: _cpr ? _rhythm.rate : _rhythm.average,
                        result: _cpr ? null : _rhythmGood,
                      ),
                    ),
                  ),
                ),
              // What the checks found, under the dots (never covered by a deck).
              if (found)
                Positioned(
                  key: const ValueKey('hud-found'),
                  left: 12,
                  right: 12,
                  top: pad.top + 90,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_noResponse) _FoundChip(key: const ValueKey('chip-response'), text: GoldenLines.noResponse, quiet: quiet),
                        if (_noResponse && _noBreath) const SizedBox(width: 8),
                        if (_noBreath) _FoundChip(key: const ValueKey('chip-breath'), text: GoldenLines.noBreath, quiet: quiet),
                      ],
                    ),
                  ),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + (meterUp ? 196 : (found ? 146 : 112))), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
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
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: GoldenLines.intro,
                  alarm: 'sounds/learn/heartbeat.wav',
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

/// A speech bubble on the scene (pops in once).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.quiet, this.tail = true});
  final String text;
  final bool quiet;
  final bool tail;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, alignment: Alignment.bottomCenter, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            decoration: BoxDecoration(
              color: SlmColors.ivory,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SlmColors.gold400, width: 1.4),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.3)),
          ),
          if (tail) CustomPaint(size: const Size(14, 7), painter: _TailPainter()),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(s.width, 0)
        ..lineTo(s.width / 2, s.height)
        ..close(),
      Paint()..color = SlmColors.ivory,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// What a check found ("সাড়া নেই", "শ্বাস নেই").
class _FoundChip extends StatelessWidget {
  const _FoundChip({super.key, required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.5 + 0.5 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 3, 10, 5),
        decoration: BoxDecoration(
          color: const Color(0xE6301217),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SlmColors.danger, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded, size: 14, color: Color(0xFFFF8A80)),
            const SizedBox(width: 4),
            Text(text, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          ],
        ),
      ),
    );
  }
}

/// The CPR meter: compressions a minute on a scale, the 100–120 band green;
/// after the beat the average and the guideline ([result]: in rhythm or not).
class _RateMeter extends StatelessWidget {
  const _RateMeter({required this.rate, required this.result});
  final int? rate;
  final bool? result;

  static const lo = 60.0;
  static const hi = 160.0;

  @override
  Widget build(BuildContext context) {
    final r = rate;
    final inBand = r != null && r >= 100 && r <= 120;
    final res = result;
    final accent = res == null ? (inBand ? SlmColors.emerald400 : SlmColors.gold300) : (res ? SlmColors.emerald400 : SlmColors.danger);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: SlmColors.navy950.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.8), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(res == null ? GoldenLines.perMinute : (r == null ? GoldenLines.perMinute : GoldenLines.average(r)),
                  style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
              const Spacer(),
              if (res == null)
                Text(r == null ? '–' : enDigits('$r'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accent))
              else
                Icon(res ? Icons.check_circle_rounded : Icons.error_rounded, size: 20, color: accent),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(height: 14, child: CustomPaint(size: Size.infinite, painter: _ScalePainter(rate: r))),
          const SizedBox(height: 4),
          Text(GoldenLines.aha, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w700, color: SlmColors.gold200)),
        ],
      ),
    );
  }
}

class _ScalePainter extends CustomPainter {
  const _ScalePainter({required this.rate});
  final int? rate;

  @override
  void paint(Canvas c, Size s) {
    double x(double v) => ((v - _RateMeter.lo) / (_RateMeter.hi - _RateMeter.lo)).clamp(0.0, 1.0) * s.width;
    final bar = RRect.fromRectAndRadius(Rect.fromLTWH(0, 3, s.width, s.height - 6), const Radius.circular(4));
    c.drawRRect(bar, Paint()..color = const Color(0xFF2A3550));
    c.drawRect(Rect.fromLTRB(x(100), 3, x(120), s.height - 3), Paint()..color = const Color(0xFF2E9E5B));
    final r = rate;
    if (r != null) {
      final nx = x(r.toDouble());
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(nx, s.height / 2), width: 5, height: s.height), const Radius.circular(2)), Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_ScalePainter old) => old.rate != rate;
}

/// The hold ring round his face.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress}) : super(repaint: progress);
  final Animation<double> progress;

  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    c.drawCircle(rect.center, s.width / 2 - 3, Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
    c.drawArc(rect.deflate(3), -math.pi / 2, math.pi * 2 * progress.value, false, Paint()
      ..color = const Color(0xFF7FE0A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// The metronome's beat: a ring swells from the middle of the chest.
class _PulsePainter extends CustomPainter {
  const _PulsePainter(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final centre = s.center(Offset.zero);
    c.drawCircle(centre, 10 + (s.width / 2 - 12) * t, Paint()
      ..color = Color.fromRGBO(255, 120, 120, 0.7 * (1 - t))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.drawCircle(centre, 5, Paint()..color = const Color(0x99FF6B6B));
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t;
}
