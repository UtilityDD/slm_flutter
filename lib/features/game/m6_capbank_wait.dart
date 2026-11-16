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
import 'm6_capbank_wait_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_capbank_wait_world.dart' show M6CapBus, M6CapFlavor, M6CapGeo, M6CapKind, m6CapLine;

// Lesson 6.7 "ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার", কাজ 1 "ঘড়ি ধরে অপেক্ষা"
// (pack do_6_7_a, engineType m6_capbank_wait). Three dealt jobs at a
// roadside 11 kV pole: a capacitor bank with the line shut down and the
// crew's earth on it, a bank isolated by its own switch, and either a small
// LT power capacitor in a ground panel or another bank. Each job: the guide
// gives the job, the bank's switch flips OFF with a clunk, and from then on
// only the watch's hands show the time (game clock: 1 minute per 2.5 s).
//
//  Bezel (optional, the core gesture): turn the watch's bezel triangle onto
//    the minute hand to count the minutes. Judging always uses the real
//    switch-off moment; the bezel is never checked.
//  Wait (all controls live): read the plate, carry the discharge rod, drag
//    its earth clamp onto the earth point (pole earth / panel earth bar).
//  Discharge (the player decides when): with the earthed rod in hand, touch
//    every terminal (one spark each, the only feedback; the earthed line
//    conductor gives no spark and discharges nothing). Then
//    'নিরাপদ — ক্রুকে দিন' → ◆ on the table → the reason deck → next job.
//
// Deadly (module 6 table, rulings M6-4, M6-6, X2): a hand on a terminal or
// can before every terminal has had the rod (R8); the rod's hook on a
// terminal before its earth clamp is on earth (R9); handing over with a
// terminal never touched by the rod (the crew's hands, R8); listening to the
// coworker (lesson myth 1 or 2, acted out as a hand on the can: R39 by B1).
// Slip (R10, M6-6): the rod on the bank before 5 game minutes from
// switch-off (it still discharges). Waiting ≥ 10 minutes on a bank job: +5 ◆
// and the guide's line (M6-6 bonus). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_capbank_wait_world.dart), corner guide, ◆ on the table →
// the reason deck at once → এগিয়ে যান → next; the careless coworker once a
// play inside the wait on his dealt job (game minute 1–3), or at once at the
// first reach for the bank (every hook, hand and hand-over control waits for
// him: holdForCoworker). Gesture hands: a short arc on the bezel (first job),
// a sweep over the watch, the plate and the rod (the same before and after
// the 5 minutes), a generic drag on the clamp, a sweep over every terminal
// (and the line) alike, then over the terminals and the hand-over button —
// never the answer, never when.

// ============================================================================
// Content
// ============================================================================

/// The game clock: one game minute per 2.5 s.
const int m6CapMsPerMinute = 2500;

/// The rule's minimum wait (M6-6) and the bonus wait.
const double m6CapMinWait = 5;
const double m6CapLongWait = 10;

abstract final class M6CapLines {
  static const title = 'ঘড়ি ধরে অপেক্ষা';

  // DRAFT wording — owner (every new spoken line; recorded later).
  static String jobLine(M6CapFlavor f) => switch (f) {
        M6CapFlavor.fuse => 'ব্যাংকের ফিউজ উড়েছে — কারণ খুঁজতে কাছে যেতে হবে।',
        M6CapFlavor.swollen => 'ব্যাংকের একটা ইউনিট ফুলে গেছে — সরাতে হবে।',
        M6CapFlavor.cold => 'ব্যাংকের একটা ইউনিট কাজ করছে না — ফিউজ দেখতে হবে।',
        M6CapFlavor.small => 'প্যানেলের ছোট ক্যাপাসিটরটা বদলাতে হবে।',
      };
  static String intro(M6CapFlavor f) => '${jobLine(f)} হাত বাঁচিয়ে কাজ।';
  static const earthedLine = 'লাইন শাটডাউন, আর্থও দেওয়া আছে।';
  static const switchOff = 'সুইচ OFF হলো। এবার আপনার পালা।';
  static const askWait = 'সুইচ OFF হয়ে গেছে — এবার কাজটা আপনার হাতে।';
  static const askReady = 'রড তৈরি। কখন, কোথায় — আপনিই ঠিক করুন।';
  static const tasks = [switchOff, askWait, askReady];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // On the scene (words a worker reads; screen-reader handles).
  static const sceneLabel = 'পোলে ক্যাপাসিটর ব্যাংক, ঘড়ি আর ডিসচার্জ রড';
  static const watch = 'হাতঘড়ি';
  static const plate = 'বিপদ প্লেট';
  static const rod = 'ডিসচার্জ রড';
  static const clamp = 'রডের আর্থ ক্ল্যাম্প';
  static String earth(M6CapKind k) => k == M6CapKind.small ? 'প্যানেলের আর্থ বার' : 'পোলের আর্থ পয়েন্ট';
  static String terminal(int i) => i == m6CapLine ? 'লাইনের তার' : 'টার্মিনাল ${i + 1}';
  static String can(M6CapKind k, int i) => k == M6CapKind.small ? 'ক্যাপাসিটর' : 'ক্যান ${i + 1}';
  static String switchState(bool off) => off ? 'সুইচ OFF' : 'সুইচ ON';
  static const handover = 'নিরাপদ — ক্রুকে দিন';
  static String jobChip(M6CapKind k) => k == M6CapKind.small ? 'ছোট ক্যাপাসিটর' : 'ক্যাপাসিটর ব্যাংক';

  /// The plate (lesson 6.7 picture: English + Bangla).
  static const plateEn = 'DANGER! STORED ENERGY. WAIT 5-10 MINUTES BEFORE TOUCHING.';
  static const plateBn = 'বিপদ! সঞ্চিত শক্তি। স্পর্শ করার আগে 5-10 মিনিট অপেক্ষা করুন।';

  // The reasons (one question per job, fitted to the job and to what he did).
  static const whyQWait = 'সুইচ OFF-এর পরও অপেক্ষা করলেন কেন?';
  static const whyWaitRight = [
    'সুইচ OFF হলেও ক্যাপাসিটর ব্যাটারির মতো চার্জ রাখে',
    'ভেতরের রেসিস্টর চার্জ নামাতে সময় নেয়, তাই অপেক্ষা',
    'কমপক্ষে 5-10 মিনিট অপেক্ষা বাধ্যতামূলক, তারপর কাজ',
  ];
  static const whyWaitWrong = [
    'সুইচ OFF মানেই ব্যাংক ডেড, অপেক্ষা শুধু অভ্যাস',
    'গরম ক্যান ঠান্ডা হোক, তাই একটু দাঁড়িয়ে থাকলাম',
    'সুইচটা আবার ON হয়ে যায় কি না, সেটাই দেখছিলাম',
    'অপেক্ষা করে নিলে পরে আর রডের দরকারই পড়ে না',
    'ক্রু তখনও এসে পৌঁছায়নি, তাই সময়টা কাটালাম',
    'বৃষ্টি থামার জন্য একটু সময় নিলাম, আর কিছু না',
  ];

  static const whyQRod = 'অপেক্ষার পরও রড লাগালেন কেন?';
  static const whyRodRight = [
    'অপেক্ষার পরেও রডে ডিসচার্জ আর আর্থিং, বাড়তি সুরক্ষা',
    'ভেতরের রেসিস্টরে ভরসা নয়, রডে সরাসরি ডিসচার্জ',
    'রেসিস্টর ভোল্টেজ নামায়, রড বাকি চার্জ মাটিতে দেয়',
  ];
  static const whyRodWrong = [
    'স্যার দেখছিলেন, তাই নিয়মরক্ষায় রডটা লাগালাম',
    'রড ছোঁয়ালে ব্যাংকের পাওয়ার ফ্যাক্টর মাপা হয়ে যায়',
    'রডের হুকে ক্যান ঝুলিয়ে নিচে নামানো সহজ হয়',
    'অপেক্ষার পরে রড শুধু অভ্যাস, এমনিতেই সব ডেড',
    'রড দিয়ে ছুঁলে ভেতরের ফিউজটা দেখা যায় বাইরে থেকে',
    'রড না দিলে ব্যাংকটা আবার নিজে থেকেই ON হয়',
  ];

  static const whyQFirst = 'হাত দেওয়ার আগে রড ছোঁয়ালেন কেন?';
  static const whyFirstRight = [
    'ডিসচার্জ না করে ছুঁলে মারাত্মক শক, তাই রড আগে',
    'সুইচ OFF-এর পরও চার্জ থাকে, রড তা মাটিতে নামায়',
    'ক্যাপাসিটর শক্তি জমিয়ে রাখে, রডে নামিয়ে তবেই হাত',
  ];
  static const whyFirstWrong = [
    'রড ছোঁয়ালে বোঝা যায় ব্যাংকটা ঠিক আছে কি না',
    'হাতে গ্লাভস ছিল না বলে রডটা দিয়েই ছুঁলাম',
    'সুইচ তো OFF, রডটা শুধু ছবি তোলার জন্য লাগালাম',
    'রডে ছুঁলে টার্মিনালের ময়লা পরিষ্কার হয়ে যায়',
    'রড ছোঁয়ালে ব্যাংকের ফিউজটা আবার জুড়ে যায়',
    'রড ছাড়া উঁচুতে হাত পৌঁছায় না, তাই রড নিলাম',
  ];

  static const whyQLine = 'লাইনে আর্থ থাকা সত্ত্বেও ব্যাংকে আলাদা রড কেন?';
  static const whyLineRight = [
    'ব্যাংক লাইনের ফিউজের পরে, লাইন আর্থেও চার্জড থাকে',
    'ক্যাপাসিটরকে সবসময় আলাদা আর সরাসরি ডিসচার্জ করি',
    'লাইনের আর্থ ব্যাংকের জমা চার্জ নামিয়ে দেয় না',
  ];
  static const whyLineWrong = [
    'লাইন আর্থ মানেই নিচের সবকিছু ডেড হয়ে গেছে',
    'আর্থ যত বেশি তত ভালো, তাই আরেকটা দিলাম শুধু',
    'রডটা গাড়িতে পড়ে ছিল, তাই কাজে লাগিয়ে দিলাম',
    'আলাদা রডে ব্যাংকের পাওয়ার ফ্যাক্টর মাপা হয়',
    'লাইনের আর্থ খুলে গেলে যেন ব্যাংক ধরে রাখে',
    'ক্রু বলেছিল বলে লাগালাম, এমনিতে দরকার নেই',
  ];

  static const whyQSmall = 'ছোট ক্যাপাসিটরেও রড কেন?';
  static const whySmallRight = [
    'আকার দিয়ে বিপদ মাপা যায় না, ছোটটাও চার্জ রাখে',
    'ছোট পাওয়ার ক্যাপাসিটরও মারাত্মক শক দিতে পারে',
    'ছোট হোক বড় হোক, ক্যাপাসিটর শক্তি জমিয়ে রাখে',
  ];
  static const whySmallWrong = [
    'ছোট ক্যাপাসিটরে শক লাগলেও সামান্য ঝিঁঝি লাগে',
    'অভ্যাস রাখতে রড লাগালাম, এখানে দরকার ছিল না',
    'LT-র ছোট ক্যাপাসিটরে চার্জ জমতেই পারে না',
    'প্যানেলের দরজা খুললেই চার্জ বাইরে বেরিয়ে যায়',
    'রড না দিলে ছোট ক্যাপাসিটরটা নষ্ট হয়ে যায়',
    'ছোট জিনিসে রড দেওয়া নিয়ম নয়, শুধু দেখালাম',
  ];

  static const allWhyQs = [whyQWait, whyQRod, whyQFirst, whyQLine, whyQSmall];

  // The careless coworker (one push a play, inside the wait on his job).
  // His pushes are the lesson's myths word for word (not new text, but they
  // need his clip; myth 1 is shared with the 6.7 board).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const mythLine = 'লাইন তো বন্ধ এবং আর্থ করা আছে, তাই ক্যাপাসিটর ব্যাংকে কাজ করতে কোনো ভয় নেই।';
  static const mythSmall = 'একটি ছোট ক্যাপাসিটর তেমন বিপজ্জনক নয়।';
  static const askLine = 'ও বলছে লাইন আর্থ আছে, ভয় নেই। কী করবেন?';
  static const askSmall = 'ও বলছে ছোট ক্যাপাসিটরে ভয় নেই। কী করবেন?';
  static const coworkerBank = CoworkerScript(
    line: mythLine,
    exitLine: coworkerExit,
    right: [
      'না, আগে অপেক্ষা — তারপর রডে সরাসরি ডিসচার্জ',
      'না, ব্যাংক আলাদা করে ডিসচার্জ না করে নয়',
      'না, লাইনের আর্থে ব্যাংকের চার্জ নামে না',
    ],
    wrong: [
      'ঠিক, লাইন আর্থ আছে, হাত দিয়েই দেখি',
      'হ্যাঁ, আর্থ দেওয়া লাইনে আর ভয় কীসের',
      'আচ্ছা, রড ছাড়াই ক্যানটা হাতে ধরে ফেলি',
      'ঠিক বলেছ, অপেক্ষার কোনো দরকারই নেই',
      'হ্যাঁ, লাইন বন্ধ মানে ব্যাংকও তো বন্ধ',
    ],
    asks: ['কী করবেন?', askLine, 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerSmall = CoworkerScript(
    line: mythSmall,
    exitLine: coworkerExit,
    right: [
      'না, ছোট হলেও আগে অপেক্ষা, তারপর রড',
      'না, আকার দেখে বিপদ মাপা যায় না',
      'না, ছোট ক্যাপাসিটরেও রডে ডিসচার্জ',
    ],
    wrong: [
      'ঠিক, এটুকু ক্যাপাসিটরে আর কী হবে',
      'হ্যাঁ, ছোটটা হাত দিয়েই খুলে ফেলি',
      'আচ্ছা, ছোট জিনিসে রডের কী দরকার',
      'ঠিক বলেছ, এতে শক লাগে না তেমন',
      'হ্যাঁ, অপেক্ষা না করেই ধরে ফেলি',
    ],
    asks: ['কী করবেন?', askSmall, 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6CapKind k) => k == M6CapKind.small ? coworkerSmall : coworkerBank;
  static const allCoworkers = [coworkerBank, coworkerSmall];

  static String callHeld(M6CapKind k) => k == M6CapKind.small
      ? 'ঠিক! ছোট ক্যাপাসিটরও শক দেয় — আগে অপেক্ষা, তারপর রড।'
      : 'ঠিক! লাইনের আর্থ ব্যাংকের চার্জ নামায় না — রডে সরাসরি।';

  static const bonus = 'বড় 11 kV ব্যাংকে 10 মিনিট অপেক্ষা আরও নিরাপদ।';
  /// A pass with no early rod (spoken only then: never praises a cut wait).
  static const allSet = 'তিনটে কাজেই অপেক্ষা, তারপর প্রতিটি টার্মিনালে রড — শাবাশ!';

  /// A pass with one or two early rods (DRAFT — owner wording).
  static const passSlipped = 'পাস! পরের বার সুইচ OFF-এর পর পুরো 5 মিনিট অপেক্ষা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — সুইচ OFF-এর পর অপেক্ষা, তারপর প্রতিটি টার্মিনালে রড।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtWait = 'সুইচ OFF-এর পর ঘড়ি ধরে অপেক্ষা';
  static const caughtAll = 'প্রতিটি টার্মিনালে রড, তবেই ক্রুকে';
  static const caughtLine = 'লাইনে আর্থ থাকলেও ব্যাংকে আলাদা রড';
  static const caughtSmall = 'ছোট ক্যাপাসিটরেও রড';
  static const caughtLong = '10 মিনিট অপেক্ষা — আরও নিরাপদ';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken line of the guide (DRAFT — owner wording, then a clip):
  /// intros, job lines, tasks, the spoken why-questions, the coworker asks,
  /// the held lines, the bonus, the pass/fail lines and every mistake text.
  static List<String> get newGuideLines => [
        for (final f in M6CapFlavor.values) intro(f),
        for (final f in M6CapFlavor.values) jobLine(f),
        earthedLine,
        switchOff,
        askWait,
        askReady,
        ...allWhyQs,
        askLine,
        askSmall,
        for (final k in [M6CapKind.bankEarthed, M6CapKind.small]) callHeld(k),
        bonus,
        allSet,
        passSlipped,
        fail,
        for (final m in M6CapMistakes.all) m.textBn,
      ];

  /// The coworker's pushes (the lesson's myths word for word; his clips).
  static List<String> get newRivalLines => [mythLine, mythSmall];
}

abstract final class M6CapMistakes {
  static const _dir = 'assets/game/art/m6_capbank_wait';

  // Lesson 6.7 point 3 (index 2): 'মারাত্মক বা প্রাণঘাতী শক' — R8, deadly.
  static const handBeforeRod = DoMistake(
    key: '6.7/m6_capbank_wait/hand-before-rod',
    textBn: 'ডিসচার্জ না করে ক্যাপাসিটর ছুঁলেন! সুইচ OFF-এর পরেও এটা চার্জ করা ব্যাটারির মতো ভোল্টেজ ধরে রাখে — মারাত্মক বা প্রাণঘাতী শক। প্রতিটি টার্মিনালে আগে রড।',
    art: '$_dir/hand_touch.svg',
    deadly: true,
    lessonPoint: 2,
  );
  // Lesson 1.5's earth-first rule carried into 6.7 (R9, M6-4), deadly.
  static const hookBeforeClamp = DoMistake(
    key: '6.7/m6_capbank_wait/hook-before-clamp',
    textBn: 'আগে টার্মিনালে হুক, পরে আর্থ — জমা চার্জ আপনার শরীর দিয়ে মাটিতে নামে। সবসময় আগে ক্ল্যাম্প আর্থে, তারপর হুক।',
    art: '$_dir/hook_first.svg',
    deadly: true,
    lessonPoint: 2,
  );
  // R8 at the hand-over: the crew's hands on a terminal the rod never touched.
  static const handoverCharged = DoMistake(
    key: '6.7/m6_capbank_wait/handover-charged',
    textBn: 'একটা টার্মিনালে রড ছোঁয়ানো হয়নি — ক্রু হাত দিলেই সঞ্চিত চার্জের শক। প্রতিটি টার্মিনাল ডিসচার্জ করে তবেই “নিরাপদ”।',
    art: '$_dir/handover.svg',
    deadly: true,
    lessonPoint: 2,
  );
  // Lesson 6.7 point 3 safety protocol: 'কমপক্ষে ৫-১০ মিনিট' — R10, slip.
  static const earlyRod = DoMistake(
    key: '6.7/m6_capbank_wait/early-rod',
    textBn: 'সুইচ OFF-এর 5 মিনিট পেরোনোর আগেই রড! ভেতরের ডিসচার্জ রেসিস্টরকে সময় দিন — কমপক্ষে 5-10 মিনিট অপেক্ষা বাধ্যতামূলক, তারপর রড।',
    art: '$_dir/early_rod.svg',
    lessonPoint: 2,
  );
  // Listening to myth 1 (acted out as a hand on the can): its reality, word
  // for word — deadly (R39 by B1: the act he pushes is R8).
  static const pushLine = DoMistake(
    key: '6.7/m6_capbank_wait/push-line-earthed',
    textBn: 'ভুল। যদি ক্যাপাসিটর ব্যাংকটি লাইনের ফিউজের পরে লাগানো থাকে, তবে লাইন আর্থ করা সত্ত্বেও ক্যাপাসিটরটি চার্জড থাকতে পারে। ক্যাপাসিটরকে সবসময় আলাদাভাবে এবং সরাসরি ডিসচার্জ করা অপরিহার্য।',
    art: '$_dir/hand_touch.svg',
    deadly: true,
    lessonPoint: 2,
  );
  // Listening to myth 2: its reality, word for word — deadly (B1, R8).
  static const pushSmall = DoMistake(
    key: '6.7/m6_capbank_wait/push-small',
    textBn: 'আকার দিয়ে বিপদ মাপা যায় না। এমনকি একটি ছোট পাওয়ার ক্যাপাসিটরও একজন মানুষকে মারাত্মক শক দেওয়ার মতো যথেষ্ট শক্তি ধরে রাখতে পারে।',
    art: '$_dir/hand_touch.svg',
    deadly: true,
    lessonPoint: 2,
  );

  /// Listening to his push is the act it pushes (B1).
  static DoMistake push(M6CapKind k) => k == M6CapKind.small ? pushSmall : pushLine;

  static const List<DoMistake> all = [handBeforeRod, hookBeforeClamp, handoverCharged, earlyRod, pushLine, pushSmall];
}

/// One job.
@immutable
class M6CapJob {
  const M6CapJob({
    required this.kind,
    required this.flavor,
    required this.cans,
    required this.bus,
    required this.badCan,
    required this.startMinute,
    required this.hour,
  });

  final M6CapKind kind;
  final M6CapFlavor flavor;

  /// 3 or 6 cans on a bank (a small capacitor has 3 terminals).
  final int cans;
  final M6CapBus bus;
  final int badCan;

  /// The watch at switch-off.
  final int startMinute;
  final int hour;

  int get terminals => kind == M6CapKind.small ? 3 : cans;
  bool get bank => kind != M6CapKind.small;
}

@immutable
class M6CapDeal {
  const M6CapDeal({required this.jobs, required this.coworkerJob, required this.coworkerMinute});

  final List<M6CapJob> jobs;

  /// The job he comes on (an earthed bank or the small capacitor: his myth
  /// must fit the scene) and the game minute he is scheduled at (1–3).
  final int coworkerJob;
  final int coworkerMinute;
}

M6CapDeal m6CapDeal(math.Random rng) {
  final third = rng.nextBool() ? M6CapKind.small : (rng.nextBool() ? M6CapKind.bankEarthed : M6CapKind.bankAlone);
  final kinds = [M6CapKind.bankEarthed, M6CapKind.bankAlone, third]..shuffle(rng);
  final flavors = [M6CapFlavor.fuse, M6CapFlavor.swollen, M6CapFlavor.cold]..shuffle(rng);
  var f = 0;
  final jobs = <M6CapJob>[];
  for (final k in kinds) {
    final small = k == M6CapKind.small;
    final cans = small ? 3 : (rng.nextBool() ? 3 : 6);
    jobs.add(M6CapJob(
      kind: k,
      flavor: small ? M6CapFlavor.small : flavors[f++ % 3],
      cans: cans,
      bus: rng.nextBool() ? M6CapBus.star : M6CapBus.delta,
      badCan: rng.nextInt(cans),
      startMinute: rng.nextInt(60),
      hour: 9 + rng.nextInt(7),
    ));
  }
  final eligible = [
    for (var i = 0; i < 3; i++)
      if (jobs[i].kind != M6CapKind.bankAlone) i,
  ];
  return M6CapDeal(jobs: jobs, coworkerJob: eligible[rng.nextInt(eligible.length)], coworkerMinute: 1 + rng.nextInt(3));
}

/// The play state (pure logic).
class M6CapRun {
  M6CapRun(this.deal);
  final M6CapDeal deal;

  int index = 0;
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  var _earlyEver = false;

  /// This job's switch has flipped OFF (the clock runs from then).
  var switchedOff = false;
  var rodHeld = false;
  var clampOn = false;

  /// The terminals the earthed rod has touched (sparked).
  final Set<int> discharged = {};

  /// The game minute of the first rod touch on a terminal.
  double? firstHookMin;
  var early = false;
  var roundDone = false;

  /// Waited ≥ 10 minutes on this bank job (the M6-6 bonus).
  var longWait = false;
  int longWaits = 0;

  /// Real ms of optional waiting past 5 minutes on the long-wait jobs.
  int longWaitMs = 0;

  /// The bezel's minute (never judged).
  int? bezel;
  var bezelEver = false;

  M6CapJob get job => deal.jobs[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => jobSlips == 0;
  bool get ready => rodHeld && clampOn;
  bool get allDischarged => discharged.length >= job.terminals;
  bool get _open => !ended && !roundDone && switchedOff;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  void switchOff() => switchedOff = true;

  bool carry() {
    if (!_open || rodHeld) return false;
    rodHeld = true;
    return true;
  }

  bool clamp() {
    if (!_open || clampOn) return false;
    clampOn = true;
    return true;
  }

  void setBezel(int m) {
    bezel = ((m % 60) + 60) % 60;
    bezelEver = true;
  }

  /// The rod's hook on terminal [t] ([m6CapLine]: the line conductor) at game
  /// minute [min]. Null: no rod in hand. Clamp not on earth = deadly (R9)
  /// on a bank terminal; the earthed line is always a harmless no-op.
  /// The first terminal before 5 minutes = slip (R10), and it still
  /// discharges. A spark only the first time a terminal is touched; the
  /// earthed line conductor never sparks and discharges nothing.
  ({bool spark, DoMistake? mistake})? hook(int t, double min) {
    if (!_open || !rodHeld) return null;
    // The earthed line conductor is not a bank terminal: touching it does
    // nothing, clamp on or not (R9 is about the bank's terminals).
    if (t == m6CapLine) return (spark: false, mistake: null);
    if (!clampOn) {
      deadly = M6CapMistakes.hookBeforeClamp;
      return (spark: false, mistake: deadly);
    }
    if (t < 0 || t >= job.terminals) return null;
    DoMistake? m;
    if (firstHookMin == null) {
      firstHookMin = min;
      if (min < m6CapMinWait) {
        early = true;
        _earlyEver = true;
        slips++;
        jobSlips++;
        m = M6CapMistakes.earlyRod;
      } else if (min >= m6CapLongWait && job.bank) {
        longWait = true;
      }
    }
    return (spark: discharged.add(t), mistake: m);
  }

  /// A hand on a terminal or can: deadly unless every terminal has had the
  /// rod (R8); after that, harmless.
  DoMistake? touch() {
    if (!_open) return null;
    if (allDischarged) return null;
    return deadly = M6CapMistakes.handBeforeRod;
  }

  /// 'নিরাপদ — ক্রুকে দিন': a terminal never rod-touched = deadly; all done
  /// → the job is done.
  DoMistake? handOver() {
    if (!_open) return null;
    if (!allDischarged) return deadly = M6CapMistakes.handoverCharged;
    roundDone = true;
    // 'Waited on the watch' only while no job of this play had an early rod.
    if (_earlyEver) {
      caught.remove(M6CapLines.caughtWait);
    } else {
      _tag(M6CapLines.caughtWait);
    }
    _tag(M6CapLines.caughtAll);
    if (job.kind == M6CapKind.bankEarthed) _tag(M6CapLines.caughtLine);
    if (job.kind == M6CapKind.small) _tag(M6CapLines.caughtSmall);
    if (longWait) {
      longWaits++;
      // The optional extra wait past 5 minutes (capped at the 10-minute
      // bonus) does not count against the quick bonus.
      final extra = ((firstHookMin ?? m6CapMinWait) - m6CapMinWait).clamp(0.0, m6CapLongWait - m6CapMinWait + 0.5);
      longWaitMs += (extra * m6CapMsPerMinute).round();
      _tag(M6CapLines.caughtLong);
    }
    return null;
  }

  /// The first terminal of the play not yet discharged (where a deadly
  /// hand-over plays out), or 0.
  int get firstCharged => [for (var i = 0; i < job.terminals; i++) if (!discharged.contains(i)) i].firstOrNull ?? 0;

  bool get earlyEver => _earlyEver;

  /// Fails the play (listening to his push).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    jobSlips = 0;
    switchedOff = false;
    rodHeld = false;
    clampOn = false;
    discharged.clear();
    firstHookMin = null;
    early = false;
    roundDone = false;
    longWait = false;
    bezel = null;
  }
}

/// The reason for a finished job: the question and its libraries, fitted to
/// the job and to what he did (an early rod: the rod-first question).
({String q, List<String> right, List<String> wrong}) m6CapWhy(M6CapJob j, {required bool early, required bool waitQ}) => switch (j.kind) {
      M6CapKind.bankEarthed => (q: M6CapLines.whyQLine, right: M6CapLines.whyLineRight, wrong: M6CapLines.whyLineWrong),
      M6CapKind.small => (q: M6CapLines.whyQSmall, right: M6CapLines.whySmallRight, wrong: M6CapLines.whySmallWrong),
      M6CapKind.bankAlone => early
          ? (q: M6CapLines.whyQFirst, right: M6CapLines.whyFirstRight, wrong: M6CapLines.whyFirstWrong)
          : waitQ
              ? (q: M6CapLines.whyQWait, right: M6CapLines.whyWaitRight, wrong: M6CapLines.whyWaitWrong)
              : (q: M6CapLines.whyQRod, right: M6CapLines.whyRodRight, wrong: M6CapLines.whyRodWrong),
    };

/// The guide's closing line: never praises the wait when a job had an early
/// rod.
String m6CapEndLine(M6CapRun r, {required bool quick}) {
  if (!r.passed) return M6CapLines.fail;
  if (r.slips > 0) return M6CapLines.passSlipped;
  return quick ? M6CapLines.quick : M6CapLines.allSet;
}

/// The quick bonus: a little under a clean play (~85 %, rounded).
/// ms per job: job line + switch ~2500, the 5-minute wait 12500 (the rod and
/// the clamp are fitted inside it), 3–6 hooks ~6000, hand-over 1500, the
/// reason ~8000 ≈ 30500; three jobs ≈ 91500 + the coworker ≈ 9600 = 101100.
/// 85 % ≈ 86000 → 85 s. (A new level's quickMs: owner to confirm.)
const m6CapQuickMs = 85000;

@immutable
class M6CapPack {
  const M6CapPack({required this.id, required this.titleBn, this.quickMs = m6CapQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6CapPack> m6CapbankWaitPacks = {
  'do_6_7_a': M6CapPack(id: 'do_6_7_a', titleBn: M6CapLines.title),
};

/// Test-only view of the running level (game clock and job state).
abstract final class M6CapProbe {
  static double minutes = 0;
  static M6CapRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M6CapbankWaitPage extends StatefulWidget {
  const M6CapbankWaitPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6CapPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6CapbankWaitPage> createState() => _M6CapbankWaitPageState();
}

class _M6CapbankWaitPageState extends State<M6CapbankWaitPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CapRunPage(
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

class _CapRunPage extends ConsumerStatefulWidget {
  const _CapRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6CapPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CapRunPage> createState() => _CapRunPageState();
}

enum _Drag { none, bezel, clamp, rod, hook }

class _CapRunPageState extends ConsumerState<_CapRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6CapRun _run;
  late final int _seed = _run.deal.coworkerJob * 7 + _run.deal.coworkerMinute;
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

  /// The game clock: tenths of a game minute since this job's switch-off
  /// (a 250 ms timer — fake time in tests; never a frame by itself).
  int _tenths = 0;
  Timer? _gameTimer;
  late final ValueNotifier<int> _watchMinute = ValueNotifier(_run.job.startMinute);
  final ValueNotifier<int?> _bezel = ValueNotifier(null);

  /// The rod's hook rests here (drawn), the clamp is lifted for a tap-place.
  int? _hookAt;
  var _clampPicked = false;
  var _bonusSaid = false;
  var _bonusPending = false;
  var _waitQ = false;

  /// The plate's close-up, the last spark.
  var _plateUp = false;
  int _plateTok = 0;
  Timer? _plateTimer;
  ({Offset at, int tok})? _spark;
  int _sparkTok = 0;
  Timer? _sparkTimer;

  var _freeze = false;
  Offset _shockAt = Offset.zero;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M6CapGeo? _geoNow;

  // A drag on the scene.
  _Drag _drag = _Drag.none;
  Offset? _dragFrom;
  Offset _dragNow = Offset.zero;
  Offset _dragGlobal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _run = M6CapRun(m6CapDeal(widget.rng));
    M6CapProbe.run = _run;
    M6CapProbe.minutes = 0;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _gameTimer?.cancel();
    _plateTimer?.cancel();
    _sparkTimer?.cancel();
    _watchMinute.dispose();
    _bezel.dispose();
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

  M6CapJob get _job => _run.job;
  double get _minutes => _tenths / 10;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && _run.switchedOff;

  String get _task => !_run.switchedOff ? M6CapLines.jobLine(_job.flavor) : (_run.ready ? M6CapLines.askReady : M6CapLines.askWait);

  // --- the job and its clock ---------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    await _startJob(first: true);
  }

  Future<void> _startJob({bool first = false}) async {
    final idx = _run.index;
    final job = _job;
    _gameTimer?.cancel();
    _tenths = 0;
    M6CapProbe.minutes = 0;
    _watchMinute.value = job.startMinute;
    _bezel.value = null;
    setState(() {
      _wake++;
      _hookAt = null;
      _clampPicked = false;
      _plateUp = false;
      _spark = null;
    });
    await _sayChain([
      if (!first) M6CapLines.jobLine(job.flavor),
      if (job.kind == M6CapKind.bankEarthed) M6CapLines.earthedLine,
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || _ended || _run.index != idx || _run.switchedOff) return;
    _flipOff();
  }

  /// The bank's switch flips OFF with a clunk; the clock starts now.
  void _flipOff() {
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.8);
    _run.switchOff();
    _gameTimer = Timer.periodic(Duration(milliseconds: m6CapMsPerMinute ~/ 10), _tick);
    setState(() => _wake++);
    unawaited(_sayChain([M6CapLines.switchOff]));
  }

  void _tick(Timer t) {
    if (!mounted || _ended || _run.roundDone) {
      t.cancel();
      return;
    }
    // His moment stops the game clock: his exit is never a "time is up" cue.
    if (coworkerOnScreen) return;
    _tenths++;
    M6CapProbe.minutes = _minutes;
    final shown = _job.startMinute + _tenths ~/ 10;
    if (_watchMinute.value != shown) _watchMinute.value = shown;
    // After an hour of game time nothing more can change: stop ticking.
    if (_tenths >= 600) t.cancel();
    _maybeSchedule();
  }

  /// He is scheduled inside the wait on his job (game minute 1–3).
  void _maybeSchedule() {
    if (coworkerDone || coworkerDue || _run.index != _run.deal.coworkerJob || !_run.switchedOff) return;
    if (_minutes >= _run.deal.coworkerMinute) scheduleCoworker();
  }

  /// On his job, every reach for the bank (hook, hand, hand-over) waits for
  /// him: he cuts in now.
  bool _waitForHim() => _run.index == _run.deal.coworkerJob && !coworkerDone && (coworkerDue || _armNow()) && holdForCoworker();

  /// A reach for the bank before his minute: arm him so the hold calls him in.
  bool _armNow() {
    scheduleCoworker();
    return coworkerDue;
  }

  void _tickSound([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- hands on -----------------------------------------------------------------
  void _carry() {
    if (!_run.carry()) return;
    _tickSound('sounds/intro/click.ogg', 0.5);
    _stepDone();
    if (_run.ready) unawaited(_sayChain([M6CapLines.askReady]));
  }

  void _clampOn() {
    if (!_run.clamp()) return;
    _clampPicked = false;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/ring_steel.ogg', volume: 0.5);
    _stepDone();
    if (_run.ready) unawaited(_sayChain([M6CapLines.askReady]));
  }

  void _showPlate() {
    _plateTimer?.cancel();
    _tickSound('sounds/intro/click.ogg', 0.4);
    setState(() {
      _plateUp = true;
      _plateTok++;
    });
    _plateTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted) setState(() => _plateUp = false);
    });
    _steps++;
  }

  void _hook(int t, Offset global, M6CapGeo geo) {
    if (_waitForHim()) return;
    final res = _run.hook(t, _minutes);
    if (res == null) return;
    final at = geo.terminal(_job.kind, _job.cans, t);
    setState(() {
      _hookAt = t;
      _wake++;
    });
    final m = res.mistake;
    if (m != null && m.deadly) {
      unawaited(_deadly(m, at));
      return;
    }
    if (res.spark) {
      HapticFeedback.heavyImpact();
      _cue('sounds/learn/spark.ogg', volume: 0.6);
      _sparkTimer?.cancel();
      setState(() => _spark = (at: at, tok: ++_sparkTok));
      _sparkTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _spark = null);
      });
    } else {
      // A dull touch: the earthed line, or a terminal already done.
      HapticFeedback.selectionClick();
      _cue('sounds/intro/tick.ogg', volume: 0.35);
    }
    _stepDone();
    if (m != null) unawaited(_slip(m, global));
  }

  void _touch(Offset at) {
    if (_waitForHim()) return;
    final m = _run.touch();
    if (m != null) {
      unawaited(_deadly(m, at));
      return;
    }
    if (_run.allDischarged) _tickSound();
  }

  void _handOver() {
    if (!_canPlay || !_run.ready) return;
    if (_waitForHim()) return;
    final geo = _geoNow;
    final m = _run.handOver();
    if (m != null) {
      final at = geo == null ? Offset.zero : geo.terminal(_job.kind, _job.cans, _run.firstCharged);
      unawaited(_deadly(m, at));
      return;
    }
    if (_run.roundDone) unawaited(_jobDone());
  }

  int? _terminalAt(Offset p, M6CapGeo geo) {
    final j = _job;
    for (var i = 0; i < j.terminals; i++) {
      if (geo.terminalHit(j.kind, j.cans, i).contains(p)) return i;
    }
    if (j.kind == M6CapKind.bankEarthed && geo.lineHit.contains(p)) return m6CapLine;
    return null;
  }

  bool _onCan(Offset p, M6CapGeo geo) => geo.canHits(_job.kind, _job.cans).any((r) => r.contains(p));

  bool _onBezel(Offset p) {
    final d = (p - M6CapGeo.watchC).distance;
    return d >= M6CapGeo.watchR * 0.45 && d <= M6CapGeo.watchR + 14;
  }

  void _tapScene(Offset p, M6CapGeo geo, Offset global) {
    if (!_canPlay) return;
    final j = _job;
    final t = _terminalAt(p, geo);
    if (t != null) {
      if (_run.rodHeld) {
        _hook(t, global, geo);
      } else if (t != m6CapLine) {
        _touch(geo.terminal(j.kind, j.cans, t));
      } else {
        _hints.missTap();
      }
      return;
    }
    if (_onCan(p, geo)) {
      if (_run.rodHeld) {
        // The rod against a can's body: no terminal, nothing happens.
        _tickSound('sounds/intro/tick.ogg', 0.3);
      } else {
        _touch(p);
      }
      return;
    }
    if (geo.plateHit(j.kind).contains(p)) {
      _showPlate();
      return;
    }
    if (geo.watchHit.contains(p)) {
      // Reading the watch: nothing to press.
      return;
    }
    if (!_run.rodHeld && geo.rodHit.contains(p)) {
      _carry();
      return;
    }
    if (!_run.clampOn && geo.clampHit.contains(p)) {
      _tickSound();
      setState(() => _clampPicked = !_clampPicked);
      return;
    }
    if (_clampPicked && geo.earthHit(j.kind).inflate(6).contains(p)) {
      _clampOn();
      return;
    }
    _hints.missTap();
  }

  void _panStart(Offset p, M6CapGeo geo) {
    if (!_canPlay) return;
    _dragFrom = p;
    _dragNow = p;
    if (_onBezel(p)) {
      _drag = _Drag.bezel;
    } else if (!_run.clampOn && geo.clampHit.inflate(4).contains(p)) {
      _drag = _Drag.clamp;
    } else if (!_run.rodHeld && geo.rodHit.contains(p)) {
      _drag = _Drag.rod;
      _carry();
    } else if (_run.rodHeld) {
      _drag = _Drag.hook;
    } else {
      _drag = _Drag.none;
    }
  }

  void _panUpdate(Offset p, Offset global) {
    _dragNow = p;
    _dragGlobal = global;
    if (_drag == _Drag.bezel) {
      final d = p - M6CapGeo.watchC;
      if (d.distance < 6) return;
      final a = math.atan2(d.dx, -d.dy);
      final m = ((a / (math.pi / 30)).round() + 60) % 60;
      if (_bezel.value != m) {
        _run.setBezel(m);
        _bezel.value = m;
        HapticFeedback.selectionClick();
      }
      return;
    }
    if (_drag == _Drag.clamp || _drag == _Drag.hook) setState(() {});
  }

  void _panEnd(M6CapGeo geo) {
    final drag = _drag;
    final from = _dragFrom;
    final global = _dragGlobal;
    _drag = _Drag.none;
    _dragFrom = null;
    if (from == null || !_canPlay) {
      if (mounted) setState(() {});
      return;
    }
    final to = _dragNow;
    switch (drag) {
      case _Drag.bezel:
        _tickSound('sounds/intro/tick.ogg', 0.3);
        _stepDone();
      case _Drag.clamp:
        setState(() {});
        if (geo.earthHit(_job.kind).inflate(8).contains(to)) {
          _clampOn();
        }
      case _Drag.rod:
        setState(() {});
      case _Drag.hook:
        setState(() {});
        final t = _terminalAt(to, geo);
        if (t != null) {
          _hook(t, global, geo);
        } else if ((to - from).distance > 30) {
          _hints.missTap();
        }
      case _Drag.none:
        _hints.missTap();
    }
  }

  // --- the job's end and its reason --------------------------------------------
  Future<void> _jobDone() async {
    _hush();
    _gameTimer?.cancel();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() {
      _hookAt = null;
      _plateUp = false;
      _wake++;
    });
    if (_run.longWait && !_bonusSaid) {
      _bonusSaid = true;
      _bonusPending = true;
    }
    putOnTable(15 + (_run.thorough ? 5 : 0) + (_run.longWait ? 5 : 0));
    final job = _job;
    final idx = _run.index;
    _waitQ = widget.rng.nextBool();
    final why = m6CapWhy(job, early: _run.early, waitQ: _waitQ);
    unawaited(askReason(
      deal: () => dealChoices(why.right, why.wrong, widget.rng),
      question: why.q,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    unawaited(_startJob());
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
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
    final speak = await SpokenOnce.first('m6cap/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
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
    unawaited(() async {
      if (_bonusPending) {
        _bonusPending = false;
        await _sayChain([M6CapLines.bonus], mood: GuideMood.glad);
      }
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100));
      if (mounted && !_ended && _run.index == idx) _next();
    }());
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  M6CapKind get _hisKind => _run.deal.jobs[_run.deal.coworkerJob].kind;

  @override
  CoworkerScript get coworkerScript => M6CapLines.coworker(_hisKind);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index > _run.deal.coworkerJob || _run.roundDone && _run.index == _run.deal.coworkerJob) return null;
    if (_run.index != _run.deal.coworkerJob || !_run.switchedOff) return false;
    if (_intro || _card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final k = _hisKind;
    if (!held) {
      // Listening: his hand-on-the-can, acted out (B1: the act is R8).
      final m = M6CapMistakes.push(k);
      _run.failDeadly(m);
      final geo = _geoNow;
      final at = geo == null ? Offset.zero : geo.canHits(_job.kind, _job.cans)[k == M6CapKind.small ? 0 : _job.badCan].center;
      await _deadly(m, at);
      return;
    }
    _run.caught.add(M6CapLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6CapLines.callHeld(k)], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6CapLines.tapWhy[_nudgeN++ % M6CapLines.tapWhy.length]
            : _nudge.next(_task);
    _tickSound('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _gameTimer?.cancel();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  /// A deadly touch: the scene freezes grey and the stored charge flashes
  /// over at [at] in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m, Offset at) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _gameTimer?.cancel();
    _hush();
    _plateTimer?.cancel();
    _sparkTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _shockAt = at;
      _plateUp = false;
      _spark = null;
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
    final speak = await SpokenOnce.first('m6cap/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6CapLines.deadlyWord : M6CapLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same job goes on (the clock kept running).
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

  /// The play time the quick bonus judges: the optional 10-minute waits
  /// (the +5 ◆ bonus) never cost the star.
  int get _quickMs => _clock.elapsedMilliseconds - _run.longWaitMs;

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _gameTimer?.cancel();
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
      if (mark == 100 && _quickMs < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _quickMs < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(m6CapEndLine(_run, quick: _quickBonus),
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
    if (_run.rodHeld) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6CapRig get _rig => M6CapRig(
        kind: _job.kind,
        cans: _job.cans,
        bus: _job.bus,
        flavor: _job.flavor,
        badCan: _job.badCan,
        switchOff: _run.switchedOff,
        rodHeld: _run.rodHeld,
        clampOn: _run.clampOn,
        hookAt: _run.rodHeld ? _hookAt : null,
      );

  List<Rect> _terminalRects(M6CapGeo geo) {
    final j = _job;
    return [
      for (var i = 0; i < j.terminals; i++) geo.terminalHit(j.kind, j.cans, i),
      if (j.kind == M6CapKind.bankEarthed) geo.lineHit,
    ];
  }

  /// The gesture hand: how to touch, never what — and never when. First job,
  /// bezel never turned: a short arc along the bezel, starting opposite the
  /// minute hand (never ending on it). Before the rod is ready: a sweep over
  /// the watch, the plate, the rod and the clamp, or a generic drag nudge on
  /// the clamp. Ready, nothing touched yet: the same sweep, or a sweep over
  /// every terminal alike (and the line) — the same cadence before and after
  /// the five minutes. Discharging: a sweep over every terminal and the
  /// hand-over button.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final j = _job;
    final wait = [geo.watchHit, geo.plateHit(j.kind), if (!_run.rodHeld) geo.rodHit, if (!_run.clampOn) geo.clampHit];
    if (_run.index == 0 && !_run.bezelEver && n % 3 == 0) {
      final m = (_watchMinute.value + 30) % 60;
      final from = M6CapGeo.bezelAt(m, r: M6CapGeo.watchR - 4);
      final a = -math.pi / 2 + m * math.pi / 30;
      return HintSpec.drag(from, toward: Offset(-math.sin(a), math.cos(a)), travel: 30, space: HintSpace.scene);
    }
    if (!_run.ready) {
      // A short lift straight up: how to pick the clamp, never where it goes.
      if (!_run.clampOn && n.isOdd) return HintSpec.drag(geo.clampSpot, toward: const Offset(0, -1), travel: 28, space: HintSpace.scene);
      return HintSpec.sweep(wait, space: HintSpace.scene);
    }
    if (_run.discharged.isEmpty) {
      return n.isEven ? HintSpec.sweep(wait, space: HintSpace.scene) : HintSpec.sweep(_terminalRects(geo), space: HintSpace.scene);
    }
    return HintSpec.sweep([..._terminalRects(geo), geo.handover], space: HintSpace.scene);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6CapGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final j = _job;
    final spark = _spark;
    final playing = !_intro && !_ended && !_freeze;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('pole'),
                child: RepaintBoundary(child: CustomPaint(painter: M6CapPainter(geo: geo, rig: _rig, seed: _seed + _run.index))),
              ),
              Positioned.fill(
                key: const ValueKey('watch'),
                child: RepaintBoundary(child: CustomPaint(painter: M6WatchPainter(minute: _watchMinute, bezel: _bezel, hour: j.hour))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: _gloved, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (_drag == _Drag.clamp && _dragFrom != null && !_freeze)
        Positioned.fill(
          key: const ValueKey('drag-clamp'),
          child: IgnorePointer(child: CustomPaint(painter: _DragLinePainter(from: geo.rodFoot, to: _dragNow, color: const Color(0xFFC77B3A)))),
        ),
      if (_drag == _Drag.hook && _dragFrom != null && !_freeze)
        Positioned.fill(
          key: const ValueKey('drag-hook'),
          child: IgnorePointer(child: CustomPaint(painter: _DragLinePainter(from: geo.hands, to: _dragNow, color: const Color(0xFFF2C230)))),
        ),
      if (_clampPicked && !_run.clampOn && !_freeze)
        Positioned.fromRect(
          key: const ValueKey('clamp-lifted'),
          rect: geo.clampHit.inflate(2),
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xCCFFFFFF), width: 2),
              ),
            ),
          ),
        ),
      if (spark != null && !_freeze)
        Positioned.fill(
          key: ValueKey('spark-${spark.tok}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0.35 : 0, end: quiet ? 0.35 : 1),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, _) => CustomPaint(painter: M6SparkPainter(at: spark.at, v: v)),
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6CapLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, d.globalPosition),
            onPanEnd: (_) => _panEnd(geo),
          ),
        ),
      ),
      // Screen-reader handles on the scene's targets (invisible; never a mark).
      _sem('watch', geo.watchHit, M6CapLines.watch),
      _sem('plate', geo.plateHit(j.kind), M6CapLines.plate),
      _sem('switch', j.kind == M6CapKind.small ? geo.panel.topLeft & const Size(40, 20) : Rect.fromCenter(center: Offset(M6CapGeo.poleX, geo.switchY), width: 54, height: 14),
          M6CapLines.switchState(_run.switchedOff)),
      if (!_run.rodHeld) _sem('rod', geo.rodHit, M6CapLines.rod),
      if (!_run.clampOn) _sem('clamp', geo.clampHit, M6CapLines.clamp),
      _sem('earth', geo.earthHit(j.kind), M6CapLines.earth(j.kind)),
      for (var i = 0; i < j.terminals; i++) _sem('term-$i', geo.terminalHit(j.kind, j.cans, i), M6CapLines.terminal(i)),
      if (j.kind == M6CapKind.bankEarthed) _sem('line', geo.lineHit, M6CapLines.terminal(m6CapLine)),
      for (final (i, r) in geo.canHits(j.kind, j.cans).indexed) _sem('can-$i', r, M6CapLines.can(j.kind, i)),
      if (playing && _run.switchedOff && _run.ready && !_run.roundDone)
        Positioned.fromRect(
          key: ValueKey('handover-${_run.index}'),
          rect: geo.handover,
          child: _HandoverButton(onTap: _handOver),
        ),
      if (_plateUp && !_freeze)
        Positioned(
          key: ValueKey('plate-$_plateTok'),
          left: 128,
          right: 6,
          top: 132,
          child: IgnorePointer(child: _PlateCard(job: j)),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('shock'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1400),
              builder: (_, v, _) => CustomPaint(painter: M6CapShockPainter(at: _shockAt, v: v)),
            ),
          ),
        ),
      // The next job: a short fade.
      if (!_intro && !_freeze)
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

  /// An invisible label over a painted target (screen readers, tests); the
  /// touch goes through to the scene's own detector.
  Widget _sem(String key, Rect r, String label) => Positioned.fromRect(
        key: ValueKey('sem-$key'),
        rect: r,
        child: IgnorePointer(child: Semantics(label: label, excludeSemantics: true, child: const SizedBox.expand())),
      );

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && _run.switchedOff && !_run.roundDone && !deckUp && !coworkerOpen && _card == null && _drag == _Drag.none;
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
              labels: [for (final j in _run.deal.jobs) M6CapLines.jobChip(j.kind)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.index}/$_steps/${_run.rodHeld}/${_run.clampOn}/${_run.discharged.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
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
                  line: M6CapLines.intro(_run.deal.jobs.first.flavor),
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

  /// The trainee in insulated gloves.
  static const _gloved = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
    gloves: true,
    gloveColor: LinemanLook.rubberGloves,
  );
}

// ============================================================================
// Pieces
// ============================================================================

/// 'নিরাপদ — ক্রুকে দিন' (the one way to end a job).
class _HandoverButton extends StatelessWidget {
  const _HandoverButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M6CapLines.handover,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF1E6B3A),
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          key: const ValueKey('handover-btn'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(M6CapLines.handover, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The plate up close (English + Bangla, as on the lesson's picture).
class _PlateCard extends StatelessWidget {
  const _PlateCard({required this.job});
  final M6CapJob job;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5C518),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1B1B1B), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(M6CapLines.plateEn, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C), height: 1.15)),
            const SizedBox(height: 3),
            Text(M6CapLines.plateBn, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1B1B1B))),
          ],
        ),
      ),
    );
  }
}

class _DragLinePainter extends CustomPainter {
  const _DragLinePainter({required this.from, required this.to, required this.color});
  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas c, Size size) {
    c.drawLine(from, to, Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    c.drawCircle(to, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DragLinePainter old) => old.from != from || old.to != to || old.color != color;
}
