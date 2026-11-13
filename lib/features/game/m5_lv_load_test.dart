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
import 'm5_lv_load_test_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 5.5 "'লো-ভোল্টেজ' সমস্যার সমাধান", কাজ 2 "লোড দিয়ে মাপুন" (pack
// do_5_5_b, engineType m5_lv_load_test). One house at dusk: a single
// customer's appliance does not run, the house next door is fine. Three calls
// (dealt fresh from: a loose service joint, a weak neutral, a fault inside the
// house, the customer's load grew), each played the same way:
//
//  1. মাপা: clip the tester's two leads on the meter board's terminals
//     (incoming P, incoming N, the earth terminal — drawn alike) by tap or
//     drag; the reading stays live while they are on. Switch the house's
//     appliances on and off on the switchboard and watch the needle: in a
//     service-fault call it sags under the complaint appliance, in an
//     inside-house call it holds. Optional: ask the customer (tap the door).
//  2. সিদ্ধান্ত: the verdict deck. Evidence-gated (ruling M5-10): a right
//     verdict without a P–N reading under the complaint load, or without an
//     N–E reading, is a slip. ◆ → reason.
//  3. A service fault: the method deck (right: supply off, 0 V on the tester,
//     an insulated spanner; deadly: a plain spanner / pliers on the live
//     joints, a bare hand on the neutral — R22), then tap every joint (two at
//     the pole end, P and N at the meter) and হয়ে গেছে (one left = slip).
//  4. Supply back, measure again under the load and close: fixed → done; the
//     load grew (still sags) → ask the customer → the cable-size report.
//
// The lesson's rules (5.5 point 2 "করণীয়", pro tips 1, 2 and 4, myths 1–2):
// the meter's incoming terminal first; always measure with the load on; N–E
// voltage above 5–10 V points to the neutral; check and tighten every joint of
// the service connection, at the pole and at the meter; ask the customer
// about new heavy appliances; "the company sends less" and "a little low
// voltage does no harm" are myths. From the module's safety rules (M3/M4
// rulings, not lesson 5.5): joints are tightened with the supply off, proved
// dead on the tester, with an insulated spanner. All voltages are
// illustrative and kept clear of the 5–10 V threshold.
//
// Deadly (Module 5 table R22): a plain spanner (or pliers) on live joints; a
// bare hand on the neutral. Slips: a verdict without the loaded reading,
// without N–E, a wrong verdict, "the company sends less", the transformer for
// one house, skipping the joints for "the load grew", a joint left untouched,
// cutting the meter seal, joining the neutral to earth, no loaded re-measure,
// the load-grew report without asking, a wrong close, "a little low voltage is
// fine", listening to the coworker (R29). Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_lv_load_test_world.dart), corner guide, ◆ on the table → "কেন …?"
// once a call; the careless coworker once a play on the first P–N reading of
// his dealt call (his line follows how that reading was taken); every control
// waits for him (holdForCoworker). Gesture hints: a doorway ripple and a probe
// lift by turns while measuring (the switches never singled out), a tap in the
// open sky between the LT wires while tightening (no joint pointed at). Voice:
// the guide and the customer by device TTS; the coworker in his recorded voice
// (new lines listed for recording).

// ============================================================================
// Content
// ============================================================================

/// What is wrong in a call.
enum M5LvLoadKind { loose, weakNeutral, inside, loadGrew }

/// Where a call is.
enum M5LvLoadStage { measure, method, tighten, remeasure, done }

/// The house's appliances (the first three can be the complaint).
enum M5LvLoadAppliance { pump, fridge, ac, fan, light, tv }

/// The verdict deck's cards.
enum M5LvLoadVerdict { loose, weak, inside, company, loadSkip, transformer }

/// The method deck's cards.
enum M5LvLoadMethod { right, liveSpanner, livePliers, bareNeutral, sealCut, neutralEarth }

/// The closing deck's cards.
enum M5LvLoadClose { fixed, report, company, lowOk, neutralEarth }

/// What a call's one reason asks about.
enum M5LvLoadWhy { loaded, ne, service, inside, joints }

const m5LvLoadComplaints = [M5LvLoadAppliance.pump, M5LvLoadAppliance.fridge, M5LvLoadAppliance.ac];
const m5LvLoadSmall = [M5LvLoadAppliance.fan, M5LvLoadAppliance.light, M5LvLoadAppliance.tv];

abstract final class M5LvLoadLines {
  static const title = 'লোড দিয়ে মাপুন';

  static String name(M5LvLoadAppliance a) => switch (a) {
        M5LvLoadAppliance.pump => 'পাম্প',
        M5LvLoadAppliance.fridge => 'ফ্রিজ',
        M5LvLoadAppliance.ac => 'এসি',
        M5LvLoadAppliance.fan => 'ফ্যান',
        M5LvLoadAppliance.light => 'লাইট',
        M5LvLoadAppliance.tv => 'টিভি',
      };

  /// The guide first (the first call's complaint).
  static String intro(M5LvLoadAppliance a) => 'একটা বাড়িতেই ${name(a)} চলে না, পাশের বাড়ি ঠিক। কারণ খুঁজুন!';
  static String callStart(M5LvLoadAppliance a) => 'নতুন কল: এই বাড়িতেও ${name(a)} ঠিকমতো চলে না।';

  // The guide's task now (tap him: the same task, a different way). The
  // guide never says "লোড" (no giveaway).
  static const askMeasure = 'মিটারে মেপে কারণ খুঁজুন।';
  static const askVerdict = 'সমস্যাটা কোথায়?';
  static const askMethod = 'জয়েন্টগুলো ঠিক করবেন কীভাবে?';
  static const askTighten = 'সার্ভিস কানেকশনের জয়েন্টগুলো টাইট দিন।';
  static const askRemeasure = 'আবার মেপে দেখে কাজ শেষ করুন।';
  static const askClose = 'এখন কী বলবেন?';
  static const tasks = [askMeasure, askVerdict, askMethod, askTighten, askRemeasure, askClose];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'মিটার বোর্ড';
  static const verdictBtn = 'সিদ্ধান্ত';
  static const doneBtn = 'হয়ে গেছে';
  static const on = 'ON';
  static const off = 'OFF';
  static const calls = ['কল 1', 'কল 2', 'কল 3'];

  /// The customer's replies (device TTS). The load-grew call names the
  /// complaint appliance as new; the others share one pool (no giveaway).
  static String newOne(M5LvLoadAppliance a) => 'হ্যাঁ, গত মাসে নতুন ${name(a)} লাগিয়েছি।';
  static const noneNew = ['না, নতুন কোনো যন্ত্র লাগাইনি।', 'না, আগের যন্ত্রগুলোই চলে, নতুন কিছু না।', 'নতুন কিছু লাগাইনি, কয়েক দিন ধরে এমন।'];

  // The verdict deck (lesson 5.5 points 1–2, myth 1). 28–36 letters.
  static const verdictText = <M5LvLoadVerdict, List<String>>{
    M5LvLoadVerdict.loose: ['সার্ভিস কেবিলের জয়েন্টে লুজ কানেকশন', 'পোল বা মিটারের কাছে কানেকশন ঢিলা'],
    M5LvLoadVerdict.weak: ['সার্ভিস কানেকশনের নিউট্রাল দুর্বল', 'নিউট্রাল কানেকশন দুর্বল বা কাটা'],
    M5LvLoadVerdict.inside: ['বাড়ির ভেতরের ওয়্যারিং-এ সমস্যা', 'ভেতরের মেইন সুইচ বা তারে সমস্যা'],
    M5LvLoadVerdict.company: ['কোম্পানি কম বিদ্যুৎ পাঠাচ্ছে'],
    M5LvLoadVerdict.loadSkip: ['লোড বেড়েছে, জয়েন্ট দেখার দরকার নেই'],
    M5LvLoadVerdict.transformer: ['ট্রান্সফরমারেই ভোল্টেজ কম পড়েছে'],
  };

  static M5LvLoadVerdict rightVerdict(M5LvLoadKind k) => switch (k) {
        M5LvLoadKind.loose || M5LvLoadKind.loadGrew => M5LvLoadVerdict.loose,
        M5LvLoadKind.weakNeutral => M5LvLoadVerdict.weak,
        M5LvLoadKind.inside => M5LvLoadVerdict.inside,
      };
  static List<String> verdictRight(M5LvLoadKind k) => verdictText[rightVerdict(k)]!;
  static List<String> verdictWrong(M5LvLoadKind k) => [
        for (final e in verdictText.entries)
          if (e.key != rightVerdict(k)) ...e.value,
      ];
  static List<String> get allVerdicts => [for (final l in verdictText.values) ...l];
  static M5LvLoadVerdict verdictOf(String text) => verdictText.entries.firstWhere((e) => e.value.contains(text)).key;

  // The method deck (M3/M4 rulings; R22). 45–53 letters.
  static const methodText = <M5LvLoadMethod, List<String>>{
    M5LvLoadMethod.right: ['সাপ্লাই বন্ধ, টেস্টারে 0 V, ইনসুলেটেড স্প্যানারে টাইট', 'আগে সাপ্লাই বন্ধ, 0 V দেখে ইনসুলেটেড স্প্যানারে টাইট'],
    M5LvLoadMethod.liveSpanner: ['চালু লাইনেই সাধারণ স্প্যানারে জয়েন্টগুলো টাইট দিই'],
    M5LvLoadMethod.livePliers: ['চালু লাইনে সাধারণ প্লাস দিয়ে জয়েন্টগুলো চেপে দিই'],
    M5LvLoadMethod.bareNeutral: ['খালি হাতে নিউট্রাল তারটা জয়েন্টে চেপে বসিয়ে দিই'],
    M5LvLoadMethod.sealCut: ['মিটারের সিল কেটে ভেতরের তারগুলো টাইট দিয়ে দিই'],
    M5LvLoadMethod.neutralEarth: ['নিউট্রাল তারটা আর্থের সাথে জুড়ে টাইট করে দিই'],
  };
  static const methodDeadly = [M5LvLoadMethod.liveSpanner, M5LvLoadMethod.livePliers, M5LvLoadMethod.bareNeutral];
  static const methodSlip = [M5LvLoadMethod.sealCut, M5LvLoadMethod.neutralEarth];
  static List<String> get methodRight => methodText[M5LvLoadMethod.right]!;
  static List<String> get methodWrong => [
        for (final e in methodText.entries)
          if (e.key != M5LvLoadMethod.right) ...e.value,
      ];
  static M5LvLoadMethod methodOf(String text) => methodText.entries.firstWhere((e) => e.value.contains(text)).key;

  // The closing deck (after the loaded re-measure). 37–43 letters.
  static const closeText = <M5LvLoadClose, List<String>>{
    M5LvLoadClose.fixed: ['লোড চালিয়েও ভোল্টেজ ঠিক আছে, কাজ শেষ', 'জয়েন্ট টাইটে ভোল্টেজ ফিরেছে, কাজ শেষ'],
    M5LvLoadClose.report: ['লোড বেড়েছে: কেবিলের সাইজ যাচাইয়ের রিপোর্ট', 'লোড বেড়েছে, সার্ভিস কেবিলের সাইজ যাচাই চাই'],
    M5LvLoadClose.company: ['কোম্পানি কম পাঠাচ্ছে, আমাদের কিছু করার নেই'],
    M5LvLoadClose.lowOk: ['একটু লো-ভোল্টেজে কিছু হয় না, চলুন যাই'],
    M5LvLoadClose.neutralEarth: ['নিউট্রাল আর্থে জুড়ে দিয়ে ভোল্টেজ তুলে দিই'],
  };
  static M5LvLoadClose rightClose(M5LvLoadKind k) => k == M5LvLoadKind.loadGrew ? M5LvLoadClose.report : M5LvLoadClose.fixed;
  static List<String> closeRight(M5LvLoadKind k) => closeText[rightClose(k)]!;
  static List<String> closeWrong(M5LvLoadKind k) => [
        for (final e in closeText.entries)
          if (e.key != rightClose(k)) ...e.value,
      ];
  static List<String> get allClose => [for (final l in closeText.values) ...l];
  static M5LvLoadClose closeOf(String text) => closeText.entries.firstWhere((e) => e.value.contains(text)).key;

  // The reasons (one a call). The right ones fit what was done; the wrong
  // ones are the lesson's myths and field excuses. 40–50 letters.
  static const whyQ = <M5LvLoadWhy, String>{
    M5LvLoadWhy.loaded: 'কেন যন্ত্রটা চালিয়ে তবেই মাপলেন?',
    M5LvLoadWhy.ne: 'কেন নিউট্রাল আর আর্থের মধ্যেও মাপলেন?',
    M5LvLoadWhy.service: 'কেন সমস্যাটা সার্ভিস কানেকশনে বললেন?',
    M5LvLoadWhy.inside: 'কেন সমস্যাটা বাড়ির ভেতরে বললেন?',
    M5LvLoadWhy.joints: 'কেন পোলে ও মিটারে প্রতিটি জয়েন্ট টাইট দিলেন?',
  };
  static const whyRight = <M5LvLoadWhy, List<String>>{
    M5LvLoadWhy.loaded: ['লোড ছাড়া মাপলে ভোল্টেজ ঠিকই দেখাতে পারে', 'যন্ত্র চলা অবস্থায় মাপলে তবেই ড্রপ ধরা পড়ে'],
    M5LvLoadWhy.ne: ['নিউট্রাল-আর্থে বেশি ভোল্ট মানে নিউট্রালে সমস্যা', 'নিউট্রাল দুর্বল কি না, এই মাপেই বোঝা যায়'],
    M5LvLoadWhy.service: ['মিটারের ইনকামিংয়েই ভোল্টেজ কম, তাই সার্ভিসে', 'একজনেরই সমস্যা, মিটারেও কম — তাই সার্ভিস লাইন'],
    M5LvLoadWhy.inside: ['মিটারের ইনকামিংয়ে লোডেও ভোল্টেজ ঠিক আছে', 'মিটারে ভোল্টেজ ঠিক, তাই গোলমাল বাড়ির ভেতরে'],
    M5LvLoadWhy.joints: ['লুজ কানেকশনই একক গ্রাহকের সবচেয়ে সাধারণ কারণ', 'পোলে আর মিটারে, সার্ভিসের প্রতিটি জয়েন্ট দেখা চাই'],
  };
  static const myths = [
    'কোম্পানি কম বিদ্যুৎ পাঠাচ্ছে, তাই ভোল্টেজ কম',
    'একটু লো-ভোল্টেজে কিছু হয় না, যন্ত্র তো চলছে',
    'মিটারে একবার মাপলেই হলো, যন্ত্র চালাতে হয় না',
    'নিউট্রাল আর্থে জুড়ে দিলেই ভোল্টেজ ঠিক হবে',
    'একটা জয়েন্ট টাইট দিলেই বাকিগুলো ঠিক থাকে',
    'সন্ধ্যা হলেই ভোল্টেজ কমে, কিছুই করার নেই',
    'গ্রাহকের কথা শুনে লাভ নেই, মিটারই সব বলে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  /// The careless coworker (recorded voice), on the first P–N reading of his
  /// call: taken without the complaint load (one line per appliance) …
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _noLoadRight = [
    'না, লোড চালিয়েই মাপব; লোড ছাড়া ঠিক দেখাতে পারে',
    'না, যন্ত্র চালিয়ে মাপব; খালি মিটার ভুল বোঝায়',
    'না, লোডে ভোল্টেজ কত নামে, তা দেখে তবে যাব',
  ];
  static const _noLoadWrong = [
    'ঠিক, মিটারে তো ঠিকই দেখাচ্ছে, চলো পরের কলে',
    'আচ্ছা, যন্ত্র চালিয়ে মাপার কোনো দরকার নেই',
    'হ্যাঁ, এই রিডিং দিয়েই কাজটা সেরে ফেলি',
    'ঠিক আছে, লোড ছাড়া মাপাই যথেষ্ট, চলো যাই',
    'হ্যাঁ, মিটার যখন ঠিক, ভেতরেই সমস্যা হবে',
  ];
  static const _noLoadAsks = ['ও বলছে যন্ত্র না চালিয়েই চলে যেতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'এই এক রিডিংয়েই কি কাজ শেষ?'];
  static const coworkerNoLoad = <M5LvLoadAppliance, CoworkerScript>{
    M5LvLoadAppliance.pump: CoworkerScript(
      line: 'মিটারে তো ঠিকই দেখাচ্ছে! পাম্প চালিয়ে মাপার দরকার নেই, চলো।',
      exitLine: coworkerExit,
      right: _noLoadRight,
      wrong: _noLoadWrong,
      asks: _noLoadAsks,
    ),
    M5LvLoadAppliance.fridge: CoworkerScript(
      line: 'মিটারে তো ঠিকই দেখাচ্ছে! ফ্রিজ চালিয়ে মাপার দরকার নেই, চলো।',
      exitLine: coworkerExit,
      right: _noLoadRight,
      wrong: _noLoadWrong,
      asks: _noLoadAsks,
    ),
    M5LvLoadAppliance.ac: CoworkerScript(
      line: 'মিটারে তো ঠিকই দেখাচ্ছে! এসি চালিয়ে মাপার দরকার নেই, চলো।',
      exitLine: coworkerExit,
      right: _noLoadRight,
      wrong: _noLoadWrong,
      asks: _noLoadAsks,
    ),
  };

  /// … or with it, low (the lesson's myth 2).
  static const coworkerLowOk = CoworkerScript(
    line: 'একটু লো-ভোল্টেজ হলে কিছু হয় না, যন্ত্রপাতি তো চলছেই। চলো, পরের কলে যাই।',
    exitLine: coworkerExit,
    right: [
      'না, লো-ভোল্টেজে মোটর গরম হয়ে আয়ু কমে; কারণ খুঁজি',
      'না, কম ভোল্টে মোটর বেশি কারেন্ট টানে; কারণ খুঁজি',
      'না, যন্ত্রের ক্ষতি হবে; কারণ না খুঁজে যাব না',
    ],
    wrong: [
      'ঠিক, যন্ত্র তো চলছেই, চলো এবার পরের কলে যাই',
      'আচ্ছা, একটু লো-ভোল্টেজে কিছু হয় না, চলো',
      'হ্যাঁ, এটুকু কম ভোল্টেজে যন্ত্র চলেই যায়',
      'ঠিক আছে, মোটর তো ঘুরছেই, কোনো সমস্যা নেই',
      'হ্যাঁ, কারণ খোঁজার সময় নেই, পরের কলে চলো',
    ],
    asks: ['ও বলছে লো-ভোল্টেজে কিছু হয় না। কী করবেন?', 'ওর কথা শুনবেন, না কারণ খুঁজবেন?', 'কম ভোল্টেজ রেখেই চলে যাবেন?'],
  );

  /// Every coworker script (the voice dump test lists their lines).
  static List<CoworkerScript> get coworkerScripts => [...coworkerNoLoad.values, coworkerLowOk];

  static const heldNoLoad = 'ঠিক! যন্ত্র চালিয়ে মেপেই কারণ খুঁজি।';
  static const heldLowOk = 'ঠিক! কম ভোল্টে মোটর গরম হয় — কারণ খুঁজি।';
  static const allSet = 'চালিয়ে মাপা, নিউট্রাল-আর্থ দেখা, প্রতিটি জয়েন্ট টাইট — দক্ষ ডাক্তারের মতো!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — যন্ত্র চালিয়ে মাপুন, নিউট্রাল-আর্থও দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtLoad = 'যন্ত্র চালিয়ে, লোডে মেপেছেন';
  static const caughtNe = 'নিউট্রাল-আর্থও মেপেছেন';
  static const caughtSafe = 'সাপ্লাই বন্ধ, 0 V, ইনসুলেটেড স্প্যানার';
  static const caughtJoints = 'পোলে ও মিটারে প্রতিটি জয়েন্ট টাইট';
  static const caughtReport = 'লোড বাড়লে কেবিলের সাইজের রিপোর্ট';
  static const caughtCall = 'সহকর্মীকে “না” বলেছেন';

  /// Every fixed guide / customer line (device TTS now; recorded later).
  static List<String> get spoken => [
        for (final a in m5LvLoadComplaints) ...[intro(a), callStart(a), newOne(a)],
        ...noneNew,
        ...tasks,
        ...tapWhy,
        ...whyQ.values,
        for (final s in coworkerScripts) ...s.asks,
        heldNoLoad,
        heldLowOk,
        allSet,
        quick,
        fail,
        deadlyWord,
        nearMissWord,
      ];
}

abstract final class M5LvLoadMistakes {
  static const _dir = 'assets/game/art/m5_lv_load_test';
  static const _k = '5.5/m5_lv_load_test';

  // R22 (Module 5 table; M3/M4 rulings — not lesson 5.5's text).
  static const liveSpanner = DoMistake(
    key: '$_k/live-spanner',
    textBn: 'চালু জয়েন্টে সাধারণ স্প্যানার বা প্লাস নয়! আগে সাপ্লাই বন্ধ, টেস্টারে 0 V, তারপর ইনসুলেটেড স্প্যানারে টাইট।',
    art: '$_dir/live_spanner.svg',
    deadly: true,
  );
  static const bareNeutral = DoMistake(
    key: '$_k/bare-neutral',
    textBn: 'খালি হাতে নিউট্রাল নয় — নিউট্রালেও ভোল্টেজ থাকতে পারে। সাপ্লাই বন্ধ, 0 V দেখে, ইনসুলেটেড যন্ত্রে কাজ।',
    art: '$_dir/bare_neutral.svg',
    deadly: true,
  );

  // Lesson 5.5 (point 2 "করণীয়", pro tips 1–2–4, myths).
  static const noLoad = DoMistake(
    key: '$_k/no-load',
    textBn: 'লোড ছাড়া মাপলে ভোল্টেজ ঠিকই দেখাতে পারে। অভিযোগের যন্ত্রটা চালিয়ে তবেই মিটারে মাপুন।',
    art: '$_dir/no_load.svg',
    lessonPoint: 1,
  );
  static const noNe = DoMistake(
    key: '$_k/no-ne',
    textBn: 'নিউট্রাল আর আর্থের মধ্যেও মাপুন — 5-10 ভোল্টের বেশি মানে নিউট্রাল লাইনে সমস্যা।',
    art: '$_dir/ne_check.svg',
    lessonPoint: 1,
  );
  static const wrongVerdict = DoMistake(
    key: '$_k/wrong-verdict',
    textBn: 'রিডিং মিলিয়ে দেখুন: লোডে মিটারেও ভোল্টেজ কম হলে সার্ভিস কানেকশন, ঠিক থাকলে বাড়ির ভেতর; নিউট্রাল-আর্থে বেশি ভোল্ট মানে নিউট্রাল।',
    art: '$_dir/verdict.svg',
    lessonPoint: 1,
  );
  static const companyMyth = DoMistake(
    key: '$_k/company-myth',
    textBn: 'কোম্পানি একটা নির্দিষ্ট ভোল্টেজ বজায় রাখে। লো-ভোল্টেজের কারণ বেশিরভাগ সময় স্থানীয় নেটওয়ার্ক বা সার্ভিস কানেকশন।',
    art: '$_dir/company_myth.svg',
  );
  static const oneHouse = DoMistake(
    key: '$_k/one-house',
    textBn: 'সমস্যা শুধু একটা বাড়িতে, পাশের বাড়ি ঠিক — কারণ সার্ভিস কানেকশন বা বাড়ির ভেতরে, ট্রান্সফরমারে নয়।',
    art: '$_dir/verdict.svg',
    lessonPoint: 0,
  );
  static const skipJoints = DoMistake(
    key: '$_k/skip-joints',
    textBn: 'লোড বেড়েছে বলে জয়েন্ট বাদ নয় — মিটারেও ভোল্টেজ কম হলে আগে পোলে ও মিটারে প্রতিটি জয়েন্ট টাইট দিন।',
    art: '$_dir/joints.svg',
    lessonPoint: 1,
  );
  static const jointLeft = DoMistake(
    key: '$_k/joint-left',
    textBn: 'একটা জয়েন্ট বাকি! সার্ভিস কানেকশনের প্রতিটি জয়েন্ট — পোলে এবং মিটারে — টাইট দিন।',
    art: '$_dir/joints.svg',
    lessonPoint: 1,
  );
  static const sealCut = DoMistake(
    key: '$_k/seal-cut',
    textBn: 'মিটারের সিল কাটবেন না। কাজ সার্ভিস কানেকশনের জয়েন্টে — পোলে আর মিটারের ইনকামিং টার্মিনালে।',
    art: '$_dir/seal.svg',
    lessonPoint: 1,
  );
  static const neutralEarth = DoMistake(
    key: '$_k/neutral-earth',
    textBn: 'নিউট্রাল আর্থে জোড়া নয় — দুর্বল নিউট্রালের জয়েন্ট খুঁজে টাইট দিন।',
    art: '$_dir/neutral_earth.svg',
    lessonPoint: 1,
  );
  static const noRemeasure = DoMistake(
    key: '$_k/no-remeasure',
    textBn: 'কাজ শেষ বলার আগে যন্ত্র চালিয়ে আবার মাপুন — লোডে ভোল্টেজ ঠিক কি না দেখুন।',
    art: '$_dir/no_load.svg',
    lessonPoint: 1,
  );
  static const askFirst = DoMistake(
    key: '$_k/ask-first',
    textBn: 'লোড বেড়েছে কি না গ্রাহকের কাছে জেনে নিন — নতুন কোনো ভারী যন্ত্র লাগিয়েছেন কি না।',
    art: '$_dir/ask.svg',
  );
  static const wrongClose = DoMistake(
    key: '$_k/wrong-close',
    textBn: 'আবার মাপা রিডিং দেখুন: লোডে ভোল্টেজ ঠিক হলে কাজ শেষ; তখনও কম থাকলে লোড বেড়েছে কি না দেখে রিপোর্ট।',
    art: '$_dir/verdict.svg',
    lessonPoint: 1,
  );
  static const lowOk = DoMistake(
    key: '$_k/low-ok',
    textBn: 'একটু লো-ভোল্টেজও ক্ষতি করে: মোটর বা কম্প্রেসর বেশি কারেন্ট টেনে গরম হয়, আয়ু মারাত্মকভাবে কমে।',
    art: '$_dir/motor_hot.svg',
  );
  static const listenNoLoad = DoMistake(
    key: '$_k/listen-no-load',
    textBn: 'ওর কথায় যন্ত্র না চালিয়ে চলে যাওয়া নয় — লোড ছাড়া মাপলে ভোল্টেজ ঠিকই দেখাতে পারে।',
    art: '$_dir/no_load.svg',
    lessonPoint: 1,
  );
  static const listenLowOk = DoMistake(
    key: '$_k/listen-low-ok',
    textBn: 'ওর কথায় কম ভোল্টেজ রেখে যাওয়া নয় — লো-ভোল্টেজে মোটর গরম হয়ে আয়ু কমে যায়।',
    art: '$_dir/motor_hot.svg',
  );

  static DoMistake? method(M5LvLoadMethod m) => switch (m) {
        M5LvLoadMethod.right => null,
        M5LvLoadMethod.liveSpanner || M5LvLoadMethod.livePliers => liveSpanner,
        M5LvLoadMethod.bareNeutral => bareNeutral,
        M5LvLoadMethod.sealCut => sealCut,
        M5LvLoadMethod.neutralEarth => neutralEarth,
      };

  static List<DoMistake> get all => [
        liveSpanner,
        bareNeutral,
        noLoad,
        noNe,
        wrongVerdict,
        companyMyth,
        oneHouse,
        skipJoints,
        jointLeft,
        sealCut,
        neutralEarth,
        noRemeasure,
        askFirst,
        wrongClose,
        lowOk,
        listenNoLoad,
        listenLowOk,
      ];
}

/// One dealt call.
@immutable
class M5LvLoadCall {
  const M5LvLoadCall({
    required this.kind,
    required this.complaint,
    required this.switches,
    required this.smallOn,
    required this.nominal,
    required this.depth,
    required this.neFault,
    required this.neOk,
    required this.reply,
    required this.why,
    required this.wall,
  });

  final M5LvLoadKind kind;

  /// The appliance that does not run (a heavy load).
  final M5LvLoadAppliance complaint;

  /// The switchboard, left to right (the complaint among small loads).
  final List<M5LvLoadAppliance> switches;

  /// A small load already on when the call starts (null = none).
  final M5LvLoadAppliance? smallOn;

  /// No-load P–N volts (226–236).
  final int nominal;

  /// How far the complaint load pulls P–N down before the fix.
  final int depth;

  /// N–E volts with a weak neutral (15–22) and normally (1–3).
  final int neFault;
  final int neOk;

  /// Which "nothing new" reply the customer gives (not the load-grew call).
  final int reply;

  /// What the call's one reason asks about.
  final M5LvLoadWhy why;

  /// The house's wall tone.
  final int wall;

  bool get service => kind != M5LvLoadKind.inside;
}

@immutable
class M5LvLoadDeal {
  const M5LvLoadDeal({required this.calls, required this.cwCall});
  final List<M5LvLoadCall> calls;

  /// The call the coworker comes on (a service-fault call).
  final int cwCall;
}

M5LvLoadDeal m5LvLoadDeal(math.Random rng) {
  final kinds = [...M5LvLoadKind.values]..shuffle(rng);
  final calls = <M5LvLoadCall>[];
  for (final k in kinds.take(3)) {
    final complaint = m5LvLoadComplaints[rng.nextInt(m5LvLoadComplaints.length)];
    final small = [...m5LvLoadSmall]..shuffle(rng);
    final switches = [complaint, ...small]..shuffle(rng);
    final depth = switch (k) {
      M5LvLoadKind.loose => 44 + rng.nextInt(15),
      M5LvLoadKind.weakNeutral => 34 + rng.nextInt(13),
      M5LvLoadKind.inside => 2 + rng.nextInt(3),
      M5LvLoadKind.loadGrew => 40 + rng.nextInt(13),
    };
    final whys = switch (k) {
      M5LvLoadKind.inside => [M5LvLoadWhy.loaded, M5LvLoadWhy.ne, M5LvLoadWhy.inside],
      _ => [M5LvLoadWhy.loaded, M5LvLoadWhy.ne, M5LvLoadWhy.service, M5LvLoadWhy.joints],
    };
    calls.add(M5LvLoadCall(
      kind: k,
      complaint: complaint,
      switches: switches,
      smallOn: rng.nextBool() ? small[rng.nextInt(small.length)] : null,
      nominal: 226 + rng.nextInt(11),
      depth: depth,
      neFault: 15 + rng.nextInt(8),
      neOk: 1 + rng.nextInt(3),
      reply: rng.nextInt(M5LvLoadLines.noneNew.length),
      why: whys[rng.nextInt(whys.length)],
      wall: rng.nextInt(4),
    ));
  }
  final service = [for (var i = 0; i < calls.length; i++) if (calls[i].service) i];
  return M5LvLoadDeal(calls: calls, cwCall: service[rng.nextInt(service.length)]);
}

/// A verdict / close pick: the slip (if any) and whether the answer stands.
typedef M5LvLoadPick = ({DoMistake? mistake, bool accepted});

/// The play state (pure logic).
class M5LvLoadRun {
  M5LvLoadRun(this.deal) {
    _startCall();
  }
  final M5LvLoadDeal deal;

  int index = 0;
  int slips = 0;
  int callSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  var stage = M5LvLoadStage.measure;
  late int cwCall = deal.cwCall;

  // The tester's leads (null = resting).
  M5LvLoadTerm? red;
  M5LvLoadTerm? black;
  /// Both leads on: the red one went on first (it moves on the next tap).
  var _redOlder = true;
  final Set<M5LvLoadAppliance> on = {};
  var supplyOn = true;

  // Evidence this call.
  var loaded = false;
  var neSeen = false;
  var reLoaded = false;
  var asked = false;

  /// The first P–N reading of the call (for the coworker): taken, and was the
  /// complaint load on?
  var pnSeen = false;
  var pnFirstLoaded = false;
  final Set<M5LvLoadJoint> tight = {};

  M5LvLoadCall get call => deal.calls[index.clamp(0, deal.calls.length - 1)];
  bool get done => index >= deal.calls.length;
  bool get ended => done || deadly != null;
  bool get callDone => stage == M5LvLoadStage.done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => callSlips == 0;
  bool get _measuring => stage == M5LvLoadStage.measure || stage == M5LvLoadStage.remeasure;
  bool get _open => !ended && !callDone;

  void _startCall() {
    stage = M5LvLoadStage.measure;
    red = black = null;
    on
      ..clear()
      ..addAll([?call.smallOn]);
    supplyOn = true;
    loaded = neSeen = reLoaded = asked = pnSeen = pnFirstLoaded = false;
    tight.clear();
    callSlips = 0;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    callSlips++;
    return m;
  }

  /// The pair of terminals the leads are on (null unless both are on).
  Set<M5LvLoadTerm>? get pair => red != null && black != null && red != black ? {red!, black!} : null;

  /// The volts the tester shows now (null: the leads are not both on).
  int? get reading {
    final p = pair;
    if (p == null) return null;
    if (!supplyOn) return 0;
    final pn = pnVolts;
    final ne = neVolts;
    if (p.containsAll({M5LvLoadTerm.p, M5LvLoadTerm.n})) return pn;
    if (p.containsAll({M5LvLoadTerm.n, M5LvLoadTerm.e})) return ne;
    return pn + ne;
  }

  bool get _fixed => stage == M5LvLoadStage.remeasure || stage == M5LvLoadStage.done;

  /// How far the complaint load pulls P–N down now.
  int get _depthNow => switch (call.kind) {
        M5LvLoadKind.loose || M5LvLoadKind.weakNeutral => _fixed ? 2 + call.depth % 3 : call.depth,
        M5LvLoadKind.inside || M5LvLoadKind.loadGrew => call.depth,
      };

  int get pnVolts {
    final d = _depthNow;
    final sag = d > 10;
    var v = call.nominal;
    if (on.contains(call.complaint)) v -= d;
    for (final a in on) {
      if (a == call.complaint) continue;
      v -= switch (a) {
        M5LvLoadAppliance.light => sag ? 2 : 0,
        _ => sag ? 4 : 1,
      };
    }
    return v;
  }

  int get neVolts => call.kind == M5LvLoadKind.weakNeutral && !_fixed ? call.neFault : call.neOk;

  /// Notes what the tester shows (evidence). Returns true when this is the
  /// call's first P–N reading.
  bool _observe() {
    final p = pair;
    if (p == null || !supplyOn) return false;
    final load = on.contains(call.complaint);
    var first = false;
    if (p.containsAll({M5LvLoadTerm.p, M5LvLoadTerm.n})) {
      if (stage == M5LvLoadStage.measure) {
        if (!pnSeen) {
          pnSeen = true;
          pnFirstLoaded = load;
          first = true;
        }
        if (load) loaded = true;
      } else if (stage == M5LvLoadStage.remeasure && load) {
        reLoaded = true;
      }
    } else if (p.containsAll({M5LvLoadTerm.n, M5LvLoadTerm.e}) && stage == M5LvLoadStage.measure) {
      neSeen = true;
    }
    return first;
  }

  /// A terminal tapped: while measuring a lead goes on (the free one, else
  /// the one put on first moves) or comes off; while tightening the meter's
  /// P / N joint is tightened. Returns true on the first P–N reading.
  bool tapTerm(M5LvLoadTerm t) {
    if (!_open) return false;
    if (stage == M5LvLoadStage.tighten) {
      if (t == M5LvLoadTerm.p) tighten(M5LvLoadJoint.meterP);
      if (t == M5LvLoadTerm.n) tighten(M5LvLoadJoint.meterN);
      return false;
    }
    if (!_measuring) return false;
    if (red == t) {
      red = null;
      return false;
    }
    if (black == t) {
      black = null;
      return false;
    }
    if (red == null) {
      return placeLead(true, t);
    } else if (black == null) {
      return placeLead(false, t);
    }
    return placeLead(_redOlder, t);
  }

  /// A lead put on [t] (by drag or tap). The other lead's terminal is refused.
  bool placeLead(bool isRed, M5LvLoadTerm t) {
    if (!_open || !_measuring) return false;
    if ((isRed ? black : red) == t) return false;
    if (isRed) {
      red = t;
    } else {
      black = t;
    }
    _redOlder = !isRed;
    return _observe();
  }

  void liftLead(bool isRed) {
    if (isRed) {
      red = null;
    } else {
      black = null;
    }
  }

  /// A switch on the switchboard. Returns true on the first P–N reading.
  bool toggle(M5LvLoadAppliance a) {
    if (!_open || stage == M5LvLoadStage.method) return false;
    if (!on.remove(a)) on.add(a);
    return _observe();
  }

  /// The customer asked (tap the door): his reply.
  String ask() {
    asked = true;
    final c = call;
    return c.kind == M5LvLoadKind.loadGrew ? M5LvLoadLines.newOne(c.complaint) : M5LvLoadLines.noneNew[c.reply];
  }

  /// The verdict deck's pick.
  M5LvLoadPick pickVerdict(M5LvLoadVerdict v) {
    if (!_open || stage != M5LvLoadStage.measure) return (mistake: null, accepted: false);
    final c = call;
    if (v != M5LvLoadLines.rightVerdict(c.kind)) {
      final m = switch (v) {
        M5LvLoadVerdict.company => M5LvLoadMistakes.companyMyth,
        M5LvLoadVerdict.transformer => M5LvLoadMistakes.oneHouse,
        M5LvLoadVerdict.loadSkip when c.kind == M5LvLoadKind.loadGrew => M5LvLoadMistakes.skipJoints,
        _ => M5LvLoadMistakes.wrongVerdict,
      };
      return (mistake: _slip(m), accepted: false);
    }
    DoMistake? m;
    if (!loaded) {
      m = _slip(M5LvLoadMistakes.noLoad);
    } else if (!neSeen) {
      m = _slip(M5LvLoadMistakes.noNe);
    } else {
      _tag(M5LvLoadLines.caughtLoad);
      _tag(M5LvLoadLines.caughtNe);
    }
    red = black = null;
    stage = c.service ? M5LvLoadStage.method : M5LvLoadStage.done;
    return (mistake: m, accepted: true);
  }

  /// The method deck's pick: right → the supply off, tightening starts.
  DoMistake? pickMethod(M5LvLoadMethod m) {
    if (!_open || stage != M5LvLoadStage.method) return null;
    final mistake = M5LvLoadMistakes.method(m);
    if (mistake != null) {
      if (mistake.deadly) return deadly = mistake;
      return _slip(mistake);
    }
    supplyOn = false;
    red = black = null;
    stage = M5LvLoadStage.tighten;
    if (thorough) _tag(M5LvLoadLines.caughtSafe);
    return null;
  }

  void tighten(M5LvLoadJoint j) {
    if (!_open || stage != M5LvLoadStage.tighten) return;
    tight.add(j);
  }

  /// হয়ে গেছে while tightening: every joint, or a slip.
  DoMistake? doneTightening() {
    if (!_open || stage != M5LvLoadStage.tighten) return null;
    if (tight.length < M5LvLoadJoint.values.length) return _slip(M5LvLoadMistakes.jointLeft);
    supplyOn = true;
    stage = M5LvLoadStage.remeasure;
    _tag(M5LvLoadLines.caughtJoints);
    return null;
  }

  /// The closing deck's pick (after the re-measure).
  M5LvLoadPick pickClose(M5LvLoadClose v) {
    if (!_open || stage != M5LvLoadStage.remeasure) return (mistake: null, accepted: false);
    final c = call;
    if (v != M5LvLoadLines.rightClose(c.kind)) {
      final m = switch (v) {
        M5LvLoadClose.company => M5LvLoadMistakes.companyMyth,
        M5LvLoadClose.lowOk => M5LvLoadMistakes.lowOk,
        M5LvLoadClose.neutralEarth => M5LvLoadMistakes.neutralEarth,
        _ => M5LvLoadMistakes.wrongClose,
      };
      return (mistake: _slip(m), accepted: false);
    }
    DoMistake? m;
    if (!reLoaded) {
      m = _slip(M5LvLoadMistakes.noRemeasure);
    } else if (c.kind == M5LvLoadKind.loadGrew && !asked) {
      m = _slip(M5LvLoadMistakes.askFirst);
    } else if (c.kind == M5LvLoadKind.loadGrew) {
      _tag(M5LvLoadLines.caughtReport);
    }
    red = black = null;
    stage = M5LvLoadStage.done;
    return (mistake: m, accepted: true);
  }

  /// A slip from outside the rules (listening to the coworker).
  DoMistake slip(DoMistake m) => _slip(m);

  /// The coworker's call passed without a P–N reading: he waits for the next
  /// service-fault call (or not at all).
  void passCoworker() {
    final later = [for (var i = index + 1; i < deal.calls.length; i++) if (deal.calls[i].service) i];
    cwCall = later.isEmpty ? -1 : later.first;
  }

  void next() {
    index++;
    if (!done) _startCall();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a service call: 2 leads, the switch, move a lead to N–E, the verdict
///     (deck ~3000), the method (~3000), 4 joints + হয়ে গেছে, 2 leads,
///     the switch, the close (~3000) ≈ 31500; an inside call ≈ 12000
///   3 calls (2 service + 1 inside on average) ≈ 75000
///   + one reason a call 3 × 8200 + the coworker ≈ 9600       ≈ 109000
/// 85 % ≈ 93000 → 90 s.
const m5LvLoadQuickMs = 90000;

@immutable
class M5LvLoadPack {
  const M5LvLoadPack({required this.id, required this.titleBn, this.quickMs = m5LvLoadQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5LvLoadPack> m5LvLoadTestPacks = {
  'do_5_5_b': M5LvLoadPack(id: 'do_5_5_b', titleBn: M5LvLoadLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M5LvLoadTestPage extends StatefulWidget {
  const M5LvLoadTestPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5LvLoadPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5LvLoadTestPage> createState() => _M5LvLoadTestPageState();
}

class _M5LvLoadTestPageState extends State<M5LvLoadTestPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _LoadRunPage(
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

enum _Deck { none, verdict, method, close }

class _LoadRunPage extends ConsumerStatefulWidget {
  const _LoadRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5LvLoadPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_LoadRunPage> createState() => _LoadRunPageState();
}

class _LoadRunPageState extends ConsumerState<_LoadRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5LvLoadRun _run;
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

  // The deck up now (verdict / method / close).
  var _deck = _Deck.none;
  int _deckGen = 0;
  List<ChoiceOption> _deckOpts = const [];
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  var _deckBusy = false;

  /// The coworker's script this play (set on his call's first P–N reading).
  CoworkerScript _cwScript = M5LvLoadLines.coworkerLowOk;
  var _cwArmed = false;

  /// The customer's reply bubble, and the joint being tightened (the spanner).
  String? _reply;
  int _replyTok = 0;
  M5LvLoadJoint? _twist;
  int _twistTok = 0;

  /// A probe being dragged (true = red) and where.
  bool? _drag;
  Offset _dragAt = Offset.zero;

  var _freeze = false;
  Offset _flashAt = Offset.zero;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand: a doorway ripple and a probe lift by turns.
  final _hints = IdleHintController();
  var _hintDoor = false;
  M5LvLoadGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M5LvLoadRun(m5LvLoadDeal(widget.rng));
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
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

  bool get _deckUp => _deck != _Deck.none && _deckOpts.isNotEmpty;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.callDone && !_freeze;

  bool get _handsFree => _canPlay && !_deckUp;

  String get _task => switch (_run.stage) {
        M5LvLoadStage.measure => M5LvLoadLines.askMeasure,
        M5LvLoadStage.method => M5LvLoadLines.askMethod,
        M5LvLoadStage.tighten => M5LvLoadLines.askTighten,
        M5LvLoadStage.remeasure => M5LvLoadLines.askRemeasure,
        M5LvLoadStage.done => M5LvLoadLines.askMeasure,
      };

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- measuring ----------------------------------------------------------------
  /// After a lead / switch change: the coworker on his call's first P–N reading.
  void _afterReading(bool firstPn) {
    setState(() => _wake++);
    if (!firstPn || _cwArmed || coworkerDone || _run.index != _run.cwCall) return;
    _cwArmed = true;
    _cwScript = _run.pnFirstLoaded ? M5LvLoadLines.coworkerLowOk : M5LvLoadLines.coworkerNoLoad[_run.call.complaint]!;
    scheduleCoworker();
  }

  void _toggle(M5LvLoadAppliance a) {
    if (!_handsFree) return;
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.5);
    _afterReading(_run.toggle(a));
  }

  void _askCustomer() {
    if (holdForCoworker()) return;
    _tick();
    final reply = _run.ask();
    _hush();
    ref.read(guideDirectorProvider.notifier).softClearLine();
    setState(() {
      _reply = reply;
      _replyTok++;
      _wake++;
    });
    final tok = _replyTok;
    // The customer speaks (device TTS, a little higher); the bubble stays a
    // reading time.
    unawaited(MascotSpeechLibrary.speak(reply, muted: _muted, pitch: 1.2));
    unawaited(Future<void>.delayed(MascotSpeechLibrary.readHold(reply) + const Duration(milliseconds: 1200), () {
      if (mounted && _replyTok == tok) setState(() => _reply = null);
    }));
  }

  void _tapScene(Offset p, M5LvLoadGeo geo) {
    if (!_handsFree) return;
    final stage = _run.stage;
    if (stage == M5LvLoadStage.tighten) {
      for (final j in M5LvLoadJoint.values) {
        if (geo.jointHit(j).contains(p)) {
          if (_run.tight.contains(j)) return;
          _tick('sounds/intro/impact_metal.ogg', 0.5);
          if (j == M5LvLoadJoint.meterP || j == M5LvLoadJoint.meterN) {
            _run.tapTerm(j == M5LvLoadJoint.meterP ? M5LvLoadTerm.p : M5LvLoadTerm.n);
          } else {
            _run.tighten(j);
          }
          setState(() {
            _twist = j;
            _twistTok++;
            _wake++;
          });
          return;
        }
      }
      _hints.missTap();
      return;
    }
    if (stage != M5LvLoadStage.measure && stage != M5LvLoadStage.remeasure) return;
    for (final t in M5LvLoadTerm.values) {
      if (geo.termHit(t).contains(p)) {
        if (holdForCoworker()) return;
        _tick('sounds/intro/click.ogg', 0.5);
        _afterReading(_run.tapTerm(t));
        return;
      }
    }
    if (geo.doorHit.contains(p)) {
      _askCustomer();
      return;
    }
    _hints.missTap();
  }

  // Drag a probe from its rest (or off a terminal) onto a terminal.
  void _panStart(Offset p, M5LvLoadGeo geo) {
    if (!_handsFree) return;
    final stage = _run.stage;
    if (stage != M5LvLoadStage.measure && stage != M5LvLoadStage.remeasure) return;
    bool? which;
    for (final isRed in [true, false]) {
      final on = isRed ? _run.red : _run.black;
      final hit = on == null ? geo.restHit(isRed) : geo.termHit(on);
      if (hit.contains(p)) {
        which = isRed;
        break;
      }
    }
    if (which == null) return;
    if (holdForCoworker()) return;
    _run.liftLead(which);
    setState(() {
      _drag = which;
      _dragAt = p;
    });
  }

  void _panUpdate(Offset p) {
    if (_drag == null) return;
    setState(() => _dragAt = p);
  }

  void _panEnd(M5LvLoadGeo geo) {
    final which = _drag;
    if (which == null) return;
    var first = false;
    if (_handsFree) {
      for (final t in M5LvLoadTerm.values) {
        if (geo.termHit(t).inflate(6).contains(_dragAt)) {
          _tick('sounds/intro/click.ogg', 0.5);
          first = _run.placeLead(which, t);
          break;
        }
      }
    }
    _drag = null;
    _afterReading(first);
  }

  // --- the decks ------------------------------------------------------------------
  void _openDeck(_Deck d) {
    final k = _run.call.kind;
    final List<ChoiceOption> opts;
    switch (d) {
      case _Deck.verdict:
        opts = dealChoices(M5LvLoadLines.verdictRight(k), M5LvLoadLines.verdictWrong(k), widget.rng);
      case _Deck.method:
        // One right, one deadly-class and one slip-class wrong.
        final deadly = M5LvLoadLines.methodDeadly[widget.rng.nextInt(M5LvLoadLines.methodDeadly.length)];
        final slip = M5LvLoadLines.methodSlip[widget.rng.nextInt(M5LvLoadLines.methodSlip.length)];
        opts = dealChoices(M5LvLoadLines.methodRight, [...M5LvLoadLines.methodText[deadly]!, ...M5LvLoadLines.methodText[slip]!], widget.rng);
      case _Deck.close:
        opts = dealChoices(M5LvLoadLines.closeRight(k), M5LvLoadLines.closeWrong(k), widget.rng);
      case _Deck.none:
        opts = const [];
    }
    setState(() {
      _deck = d;
      _deckGen++;
      _deckOpts = opts;
      _deckWrong.clear();
      _deckPicked = null;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.wav', volume: 0.6);
    final ask = switch (d) {
      _Deck.verdict => M5LvLoadLines.askVerdict,
      _Deck.method => M5LvLoadLines.askMethod,
      _Deck.close => M5LvLoadLines.askClose,
      _Deck.none => '',
    };
    unawaited(_sayChain([ask], mood: GuideMood.think));
  }

  void _closeDeck() {
    _deck = _Deck.none;
    _deckOpts = const [];
    _deckWrong.clear();
    _deckPicked = null;
  }

  /// The action button: সিদ্ধান্ত while measuring, হয়ে গেছে while tightening.
  void _action(Offset origin) {
    if (!_handsFree) return;
    if (holdForCoworker()) return;
    _tick('sounds/learn/tag_slap.wav', 0.5);
    switch (_run.stage) {
      case M5LvLoadStage.measure:
        if (_run.index == _run.cwCall && !_cwArmed && !coworkerDone) _run.passCoworker();
        _openDeck(_Deck.verdict);
      case M5LvLoadStage.remeasure:
        _openDeck(_Deck.close);
      case M5LvLoadStage.tighten:
        final m = _run.doneTightening();
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, origin));
          return;
        }
        _cue('sounds/quiz_right.wav', volume: 0.6);
        _success(origin, joints: true);
      default:
        break;
    }
  }

  Future<void> _pick(ChoiceOption o, Offset origin) async {
    if (!_canPlay || !_deckUp || _deckBusy || _deckWrong.contains(o.textBn) || _deckPicked != null) return;
    _hush();
    final d = _deck;
    if (!o.correct) {
      setState(() => _deckWrong.add(o.textBn));
      DoMistake? m;
      switch (d) {
        case _Deck.verdict:
          m = _run.pickVerdict(M5LvLoadLines.verdictOf(o.textBn)).mistake;
        case _Deck.close:
          m = _run.pickClose(M5LvLoadLines.closeOf(o.textBn)).mistake;
        case _Deck.method:
          m = _run.pickMethod(M5LvLoadLines.methodOf(o.textBn));
        case _Deck.none:
          break;
      }
      if (d != _Deck.method && m != null && !m.deadly) {
        // Back to the readings (the deck closes behind the card). The deck
        // stays locked meanwhile, so a fast second tap books nothing.
        _deckBusy = true;
        await Future<void>.delayed(const Duration(milliseconds: 420));
        _deckBusy = false;
        if (!mounted || _ended) return;
        setState(_closeDeck);
      }
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _deckBusy = true;
    setState(() => _deckPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    _deckBusy = false;
    if (!mounted || _ended) return;
    final M5LvLoadPick res = switch (d) {
      _Deck.verdict => _run.pickVerdict(M5LvLoadLines.verdictOf(o.textBn)),
      _Deck.close => _run.pickClose(M5LvLoadLines.closeOf(o.textBn)),
      _Deck.method => (mistake: _run.pickMethod(M5LvLoadMethod.right), accepted: true),
      _Deck.none => (mistake: null, accepted: false),
    };
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    setState(() {
      _closeDeck();
      _wake++;
    });
    if (res.mistake != null) {
      // A right answer without its readings (ruling M5-10): a slip, then on.
      unawaited(_mistake(res.mistake!, origin));
      return;
    }
    switch (d) {
      case _Deck.verdict:
        _success(origin);
      case _Deck.method:
        unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
        unawaited(_sayChain([LearnFeedbackLines.right.first.shownBn, M5LvLoadLines.askTighten], mood: GuideMood.glad));
      case _Deck.close:
        unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
        _afterStage();
      case _Deck.none:
        break;
    }
  }

  /// A clean verdict / all joints tightened: the call's one reason when it
  /// asks about this, else plain points; then on.
  void _success(Offset origin, {bool joints = false}) {
    final why = _run.call.why;
    final reasonHere = joints ? why == M5LvLoadWhy.joints : why != M5LvLoadWhy.joints;
    if (!reasonHere) {
      unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
      _afterStage();
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5LvLoadLines.whyRight[why]!, M5LvLoadLines.myths, widget.rng),
      question: M5LvLoadLines.whyQ[why]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  /// Brings the screen in line with the run: the next deck, the next task or
  /// the next call.
  void _afterStage() {
    if (!mounted || _ended || _run.ended) return;
    if (_run.callDone) {
      final idx = _run.index;
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
        if (mounted && !_ended && _run.index == idx) _nextCall();
      }));
      return;
    }
    if (_run.stage == M5LvLoadStage.method) {
      if (_deck != _Deck.method) _openDeck(_Deck.method);
      return;
    }
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  void _nextCall() {
    setState(() {
      _run.next();
      _cwArmed = _cwArmed && coworkerDone;
      _reply = null;
      _twist = null;
      _wake++;
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    unawaited(_sayChain([M5LvLoadLines.callStart(_run.call.complaint), M5LvLoadLines.askMeasure]));
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
      if (mounted && !_ended && _run.index == idx) _afterStage();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _cwScript;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.cwCall || _run.stage != M5LvLoadStage.measure) return null;
    if (_intro || _card != null || tableBusy || _deckUp || _freeze || _drag != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final lowOk = identical(_cwScript, M5LvLoadLines.coworkerLowOk);
    if (!held) {
      // Listened to him (R29: a myth with no danger on the spot = a slip);
      // the call goes on.
      final m = _run.slip(lowOk ? M5LvLoadMistakes.listenLowOk : M5LvLoadMistakes.listenNoLoad);
      unawaited(_mistake(m, origin));
      return;
    }
    _run.caught.add(M5LvLoadLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([lowOk ? M5LvLoadLines.heldLowOk : M5LvLoadLines.heldNoLoad, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5LvLoadLines.tapWhy[_nudgeN++ % M5LvLoadLines.tapWhy.length]
            : _nudge.next(switch (_deck) {
                _Deck.verdict => M5LvLoadLines.askVerdict,
                _Deck.close => M5LvLoadLines.askClose,
                _ => _task,
              });
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('lvload/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A live joint touched: the scene freezes grey and the flash comes off the
  /// terminal in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final geo = _geoNow;
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _closeDeck();
      if (geo != null) _flashAt = geo.termAt(m == M5LvLoadMistakes.bareNeutral ? M5LvLoadTerm.n : M5LvLoadTerm.p);
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('lvload/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5LvLoadLines.deadlyWord : M5LvLoadLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        _afterStage();
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
    await _say(!_run.passed ? M5LvLoadLines.fail : (_quickBonus ? M5LvLoadLines.quick : M5LvLoadLines.allSet),
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
    if (_run.red != null || _run.black != null || _run.stage == M5LvLoadStage.tighten) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand (how, never what): while measuring a ripple on the
  /// doorway and a probe lifted toward the board by turns (the switches are
  /// never singled out); while tightening a tap in the open sky (geo.tightenHint).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.stage) {
      case M5LvLoadStage.measure || M5LvLoadStage.remeasure:
        _hintDoor = !_hintDoor;
        if (_hintDoor) return HintSpec.tap(geo.door.center, space: HintSpace.scene);
        final free = _run.red == null ? geo.restRed : (_run.black == null ? geo.restBlack : null);
        if (free == null) return HintSpec.tap(geo.door.center, space: HintSpace.scene);
        // A short lift toward the board, ending under the terminal row (none touched).
        return HintSpec.drag(free, toward: const Offset(-0.9, -0.15), travel: 56, space: HintSpace.scene);
      case M5LvLoadStage.tighten:
        return HintSpec.tap(geo.tightenHint, space: HintSpace.scene);
      default:
        return null;
    }
  }

  Offset _tip(bool isRed, M5LvLoadGeo geo) {
    if (_drag == isRed) return _dragAt;
    final t = isRed ? _run.red : _run.black;
    if (t != null) return geo.termAt(t);
    return isRed ? geo.restRed : geo.restBlack;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5LvLoadGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final reading = _run.reading;
    final twist = _twist;
    final rig = M5LvLoadRig(
      supplyOn: _run.supplyOn,
      tight: {..._run.tight},
      wall: _run.call.wall,
      lit: _run.on.length,
    );
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('house'),
                child: RepaintBoundary(child: CustomPaint(painter: M5LvLoadWorldPainter(geo: geo, rig: rig))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              Positioned.fromRect(
                key: const ValueKey('tester'),
                rect: geo.tester,
                child: _TesterView(volts: reading, quiet: quiet),
              ),
              Positioned.fill(
                key: const ValueKey('leads'),
                child: IgnorePointer(
                  child: CustomPaint(painter: M5LvLoadLeadsPainter(geo: geo, red: _tip(true, geo), black: _tip(false, geo))),
                ),
              ),
            ],
          ),
        ),
      ),
      // The spanner turning on the joint just tightened.
      if (twist != null && !_freeze)
        Positioned.fromRect(
          key: ValueKey('twist-$_twistTok'),
          rect: Rect.fromCenter(center: geo.jointAt(twist), width: 40, height: 40),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 700),
              builder: (_, v, _) => v >= 0.999
                  ? const SizedBox.shrink()
                  : Transform.rotate(angle: v * math.pi * 0.9, child: const Icon(Icons.build_rounded, size: 26, color: Color(0xFFE9C46A))),
            ),
          ),
        ),
      if (_reply != null && !_freeze)
        Positioned(
          key: ValueKey('reply-$_replyTok'),
          right: 360 - geo.bubbleAt.dx,
          bottom: m.height - geo.bubbleAt.dy,
          child: IgnorePointer(child: _ReplyBubble(text: _reply!)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5LvLoadLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () => _panEnd(geo),
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
              builder: (_, v, _) => CustomPaint(painter: M5LvLoadFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // The next call: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('call-${_run.index}'),
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
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp || (_deckUp && playing);
    final handsOn = playing && !_run.callDone && !deckUp && !coworkerOpen && _card == null && !_run.done;
    final stage = _run.stage;
    final measuring = stage == M5LvLoadStage.measure || stage == M5LvLoadStage.remeasure;
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
              labels: M5LvLoadLines.calls,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_deckBusy && _drag == null && (measuring || stage == M5LvLoadStage.tighten),
            hintKey: '${_run.index}/${stage.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && stage != M5LvLoadStage.method)
                Positioned(
                  key: ValueKey('hud-switches-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SwitchBoard(
                          switches: _run.call.switches,
                          on: _run.on,
                          enabled: measuring,
                          onTap: _toggle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ActionButton(
                        label: stage == M5LvLoadStage.tighten ? M5LvLoadLines.doneBtn : M5LvLoadLines.verdictBtn,
                        icon: stage == M5LvLoadStage.tighten ? Icons.check_rounded : Icons.fact_check_rounded,
                        onTap: _action,
                      ),
                    ],
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
                                key: ValueKey('deck-${_deck.name}-$_deckGen'),
                                options: _deckOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: (o, at) => unawaited(_pick(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: !coworkerOnScreen || coworkerFromRight),
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
                  line: M5LvLoadLines.intro(_run.deal.calls.first.complaint),
                  alarm: 'sounds/learn/rush_in.wav',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

/// The analogue tester: a dial (0–300 V, no coloured zone) and its readout.
class _TesterView extends StatelessWidget {
  const _TesterView({required this.volts, required this.quiet});
  final int? volts;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final v = (volts ?? 0).toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2B53A), Color(0xFFC98A1C)]),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 18),
        child: Column(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: v),
                duration: Duration(milliseconds: quiet ? 0 : 650),
                curve: Curves.easeOutBack,
                builder: (_, x, _) => CustomPaint(size: Size.infinite, painter: M5LvLoadDialPainter(v: x)),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF1E2A22), borderRadius: BorderRadius.circular(4)),
              child: Text(
                volts == null ? '--- V' : '$volts V',
                key: const ValueKey('tester-readout'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF9BE59A), fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The customer's reply, over the doorway.
class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFDF5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text(text, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.3, color: SlmColors.ink)),
    );
  }
}

/// The house's switchboard: a plate of switches, each with its appliance's
/// name and ON / OFF (labels a worker reads). None is singled out.
class _SwitchBoard extends StatelessWidget {
  const _SwitchBoard({required this.switches, required this.on, required this.enabled, required this.onTap});
  final List<M5LvLoadAppliance> switches;
  final Set<M5LvLoadAppliance> on;
  final bool enabled;
  final ValueChanged<M5LvLoadAppliance> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xF2EFE8D8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9AE95), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          for (final a in switches)
            Expanded(
              child: Semantics(
                button: true,
                label: M5LvLoadLines.name(a),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? () => onTap(a) : null,
                  child: Opacity(
                    opacity: enabled ? 1 : 0.55,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF8F1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFF9C927C)),
                          ),
                          child: Column(
                            mainAxisAlignment: on.contains(a) ? MainAxisAlignment.start : MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.all(3),
                                height: 16,
                                decoration: BoxDecoration(color: const Color(0xFF6F6655), borderRadius: BorderRadius.circular(3)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(M5LvLoadLines.name(a), maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.1, color: SlmColors.ink)),
                        Text(on.contains(a) ? M5LvLoadLines.on : M5LvLoadLines.off,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, height: 1.1, color: Color(0xFF5A5246))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// সিদ্ধান্ত / হয়ে গেছে.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap});
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
