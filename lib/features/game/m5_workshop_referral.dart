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
import 'm5_workshop_referral_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_workshop_referral_world.dart' show M5WrStation, M5WrOilPart, M5WrGeo, M5WrLens;

// Lesson 5.8 "ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের রোগ নির্ণয়", কাজ 2
// "হাসপাতালের কাগজ" (pack do_5_8_b, engineType m5_workshop_referral).
// Verb: gather proof, pin it to the workshop slip.
//
// Three DP sites where the HT fuse keeps blowing (dealt fresh: two transformer
// sites + one LT site, in any order). At each the team has already isolated the
// DTR (DO barrels open with a tag, HT earth set) and clipped their
// sectionalizing log to the pole:
//
//  1. Read the log: 'LT সব আউটগোয়িং খোলা', then either the DO blew again
//     (the fault is inside the transformer) or the DO held and blew only when
//     an LT feeder went back in (the fault is on that LT line). The log gives
//     observations only.
//  2. Choose who to call: the workshop van, the LT patrol team, or the team at
//     the DO "যেমন আছে, আবার চার্জ করুক". Re-charging = DEADLY at any site
//     (rulings M5-1 / R8: re-energizing a faulted DTR; the LT site was raised
//     from slip). The wrong team = a slip. LT site → patrol → its reason.
//  3. Transformer site → the proof stations, in any order: the bushings (the
//     HT tester on its hot stick must show 0 V first — opening the bushings
//     without it = DEADLY, ruling M5-2 / R2 raised from slip; then a cloth pass
//     clears the road dust; a crack or flashover track may show), the testing
//     crew's IR card (a row near 0 or near ∞; no numbers), the oil sample (sun
//     → colour and carbon, swirl → water beads, sniff → the smell, in that
//     fixed order for every jar), the old record book. Tap a finding to pin it
//     on the slip (a small ◆); a clean item pinned = a slip (R30). 'পাঠান'
//     with every finding pinned → the crane lifts the DTR → ◆ on the table →
//     the reason. 'পাঠান' with a finding left = a slip (R31).
//
// The lesson's rules, and only those (lesson 5.8): sectionalize first to tell
// an LT fault from a transformer fault; a faulted transformer goes off the line
// to the workshop (point 0); charging a transformer with an internal fault again
// and again can make it explode (point 0); an IR near zero is sure proof of an
// internal short (pro tip 1); very black oil, a burnt smell or floating carbon
// mean arcing or overheating (pro tip 2); check the bushing surface for cracks
// or flashover marks (pro tip 3); know its history: was it bad before, is it
// often overloaded (pro tip 4); water is oil's worst enemy (myth 2). Prove dead
// before touching comes from the module rules (rulings M5-2), not 5.8's text.
//
// The careless coworker once a play (dealt): at a transformer site's decision
// beat "আর একবার চার্জ করে দেখি…" (listening = deadly, R8 / R29), or at a
// water-bead jar after the swirl, myth 2 word for word (listening = a slip,
// R32). The next decisive control waits for him (holdForCoworker).
// Three slips strike the level out. Voice: the guide by device TTS; the
// coworker's pushes are new rival lines (silent until recorded, captions held);
// his exit line is his existing clip.

// ============================================================================
// Content
// ============================================================================

/// What is really wrong at a site.
enum M5WrKind { dtr, lt }

/// Who the player calls after reading the log.
enum M5WrTeam { workshop, patrol, recharge }

/// Where a site's play is.
enum M5WrStage { log, choose, proof }

/// What a site's reason asks about.
enum M5WrWhy { workshop, lt, noCharge, ir, water }

/// The coworker's push this play.
enum M5WrPush { charge, water }

abstract final class M5WrLines {
  static const title = 'হাসপাতালের কাগজ';
  static const intro = 'তিন জায়গায় HT ফিউজ বারবার উড়ছে! কোন ট্রান্সফরমার হাসপাতালে যাবে — প্রমাণ নিয়ে ঠিক করুন।';
  static const rounds = ['সাইট 1', 'সাইট 2', 'সাইট 3'];

  // The guide's task now (tap him: the same task, a different way).
  static const askLog = 'আগে খুঁটিতে ঝোলানো লগটা পড়ুন।';
  static const askChoose = 'লগ দেখে ঠিক করুন — কাকে ডাকবেন?';
  static const askProof = 'প্রমাণ জোগাড় করে স্লিপে তুলুন, তবে পাঠান।';
  static const askLens = <M5WrStation, String>{
    M5WrStation.bushing: 'বুশিং ভালো করে দেখুন।',
    M5WrStation.ir: 'IR কার্ডটা পড়ুন।',
    M5WrStation.oil: 'তেলের নমুনাটা পরীক্ষা করুন।',
    M5WrStation.record: 'পুরনো রেকর্ড দেখুন।',
  };
  static List<String> get tasks => [askLog, askChoose, askProof, ...askLens.values];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ডিপি সাইট';
  static const logLabel = 'লগ';
  static const logTitle = 'সেকশনালাইজিং লগ';
  static const logAllOpen = 'LT সব আউটগোয়িং খোলা';
  static const logDoIn = 'DO লাগানো হলো';
  static const logBlewNow = 'সাথে সাথে উড়ে গেছে';
  static const logBlewLater = 'কিছুক্ষণ পর উড়ে গেছে';
  static const logHeld = 'DO ধরে আছে';
  static String logLtBlew(int feeder) => 'LT ফিডার $feeder লাগাতেই উড়েছে';
  // The LT site's state now: the blowing way is still in (so a re-charge
  // "as is" closes the DO onto it: R8).
  static String logLtStillIn(int feeder) => 'ফিডার $feeder এখনো লাগানো';
  static const logOk = 'ঠিক আছে';
  static const workshop = 'ওয়ার্কশপ ভ্যান';
  static const patrol = 'LT টহল দল';
  // The spec's 'যেমন আছে, আবার চার্জ করুক' (the same act at every site),
  // short enough for the 104-px button at 1.3× text ('যেমন আছে, চার্জ' is not).
  static const recharge = 'এ অবস্থায় চার্জ';
  static const tester = 'টেস্টার';
  static const testerDead = '0 V';
  static const stationName = <M5WrStation, String>{
    M5WrStation.bushing: 'বুশিং',
    M5WrStation.ir: 'IR কার্ড',
    M5WrStation.oil: 'তেলের নমুনা',
    M5WrStation.record: 'রেকর্ড বই',
  };
  static const irRows = ['HT–E', 'LT–E', 'HT–LT'];
  static const slipTitle = 'ওয়ার্কশপ স্লিপ';
  static const send = 'পাঠান';
  static const close = 'বন্ধ';

  static String teamLabel(M5WrTeam t) => switch (t) {
        M5WrTeam.workshop => workshop,
        M5WrTeam.patrol => patrol,
        M5WrTeam.recharge => recharge,
      };

  // The record book: history that is proof (pro tip 4) and routine entries.
  static const recordFind = ['আগেও একবার খারাপ হয়েছিল', 'বারবার ওভারলোড হয়েছে', 'আগেও HT ফিউজ উড়েছিল'];
  static const recordRoutine = [
    'সিলিকা জেল বদলানো হয়েছে',
    'নিয়মিত পরিদর্শন — ঠিক আছে',
    'আর্থিং পরীক্ষা — ঠিক আছে',
    'তেলের লেভেল দেখা — ঠিক আছে',
    'ব্রিদার পরিষ্কার করা হয়েছে',
  ];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. 38–48 letters.
  static const whyQ = <M5WrWhy, String>{
    M5WrWhy.workshop: 'কেন এই ট্রান্সফরমারকে ওয়ার্কশপে পাঠালেন?',
    M5WrWhy.lt: 'কেন দোষ LT লাইনে খুঁজতে বললেন?',
    M5WrWhy.noCharge: 'কেন আর চার্জ করতে দিলেন না?',
    M5WrWhy.ir: 'কেন কম IR-টাই প্রমাণ?',
    M5WrWhy.water: 'কেন তেলের জলকে প্রমাণ ধরলেন?',
  };
  static const whyRight = <M5WrWhy, List<String>>{
    M5WrWhy.workshop: ['সব LT খোলা, তবু উড়ছে — দোষ ট্রান্সফরমারের ভেতরে', 'ভেতরের ফল্ট মাঠে সারে না, ওয়ার্কশপেই পাঠাতে হয়'],
    M5WrWhy.lt: ['সব LT খুলে DO ধরে ছিল, ফিডার লাগাতেই উড়েছে', 'ট্রান্সফরমার ঠিক আছে, ফল্ট ওই LT ফিডারেই আছে'],
    M5WrWhy.noCharge: ['ভেতরের ফল্টে বারবার চার্জ দিলে বিস্ফোরণ হতে পারে', 'ফল্ট না পেয়ে আবার চার্জ মানে বিস্ফোরণের ঝুঁকি'],
    M5WrWhy.ir: ['শূন্যের কাছাকাছি IR ভেতরের শর্টের নিশ্চিত প্রমাণ', 'IR প্রায় শূন্য মানে ভেতরের ইনসুলেশন শর্ট হয়েছে'],
    M5WrWhy.water: ['জল তেলের সবচেয়ে বড় শত্রু, ইনসুলেশন দুর্বল করে', 'সামান্য জলও তেলের ডাই-ইলেকট্রিক স্ট্রেন্থ কমায়'],
  };
  static const myths = [
    'আরেকবার চার্জ দিলেই ফল্টটা পুড়ে সাফ হয়ে যাবে',
    'তেল তো জলকে আলাদা রাখে, একটু জলে ক্ষতি নেই',
    'এলটি সাইডে ফিউজ নেই, তাই এলটি ফল্টে কিছু হয় না',
    'মোটা ফিউজ লাগালেই আর উড়বে না, ঝামেলা শেষ',
    'IR যত কম তত ভালো, মানে কোথাও লিকেজ নেই',
    'বাইরে থেকে ঠিকঠাক, তাই ভেতরেও কোনো দোষ নেই',
    'পুরনো রেকর্ড দেখে লাভ নেই, আজকেরটাই আসল',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  /// The careless coworker at a transformer site's decision beat (R8: listening = deadly).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const chargePush = 'আর একবার চার্জ করে দেখি, এবার হয়তো ধরে যাবে!';
  static const coworkerCharge = CoworkerScript(
    line: chargePush,
    exitLine: coworkerExit,
    right: ['না, ফল্ট না পেয়ে আর চার্জ নয়', 'না, বারবার চার্জে বিস্ফোরণ হতে পারে', 'না, আগে প্রমাণ দেখে সিদ্ধান্ত নেব'],
    wrong: [
      'ঠিক, আর একবার চার্জ দিয়ে দেখি',
      'আচ্ছা, এবার হয়তো সত্যিই ধরে যাবে',
      'হ্যাঁ, একবার চার্জে কী আর হবে',
      'ঠিক আছে, DO লাগিয়ে দেখে নিই',
      'হ্যাঁ, চার্জ দিলেই ফল্ট বোঝা যাবে',
    ],
    asks: ['কী করবেন?', 'ও আবার চার্জ করতে বলছে। কী করবেন?', 'ফল্ট না পেয়ে চার্জ দেবেন?'],
  );

  /// The careless coworker at a water-bead jar: lesson 5.8's myth 2 word for
  /// word (R32: listening = a slip).
  static const waterPush = 'ট্রান্সফরমারের ভেতরে একটু জল ঢুকলে কিছু হয় না, তেল তো জলকে আলাদা করে রাখে।';
  static const coworkerWater = CoworkerScript(
    line: waterPush,
    exitLine: coworkerExit,
    right: ['না, জল তেলের সবচেয়ে বড় শত্রু', 'না, জলের ফোঁটাও প্রমাণে তুলব', 'না, সামান্য জলও ইনসুলেশন পচায়'],
    wrong: [
      'ঠিক, একটু জলে তো কিছু হয় না',
      'আচ্ছা, তেল তো জল আলাদা রাখে',
      'হ্যাঁ, জলের ফোঁটাগুলো বাদ দিই',
      'ঠিক আছে, ওটা কোনো প্রমাণ নয়',
      'হ্যাঁ, জল তো নিচে, তেল ভালো',
    ],
    asks: ['কী করবেন?', 'ও বলছে জলে কিছু হয় না। কী করবেন?', 'ওর কথা শুনবেন, না পাঠ?'],
  );

  /// The coworker's new pushes (no recorded clip yet: the director records
  /// them with tool/rival_clip.py and lists them in the voice dump test).
  static const rivalLinesMissing = [chargePush, waterPush];

  static const heldCharge = 'ঠিক! ফল্ট না পেয়ে আর চার্জ নয়।';
  static const heldWater = 'ঠিক! জল তেলের সবচেয়ে বড় শত্রু।';
  static const allSet = 'ঠিক রোগ, ঠিক হাসপাতাল — প্রমাণসহ পাঠালেন, একবারও চার্জ নয়।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে লগ পড়ুন, তারপর প্রমাণ জুটিয়ে সিদ্ধান্ত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtTeam = 'লগ পড়ে ঠিক দল ডেকেছেন';
  static const caughtTest = 'টেস্টারে 0 V দেখে তবে বুশিং';
  static const caughtProof = 'সব প্রমাণ স্লিপে তুলে পাঠিয়েছেন';
  static const caughtCharge = 'আবার চার্জে “না” বলেছেন';
  static const caughtWater = 'জলের মিথে “না” বলেছেন';
}

abstract final class M5WrMistakes {
  // Lesson points (0-based): 0 HT fuse keeps blowing, 1 noise, 2 oil leak, 3 no LT voltage.
  static const rechargeDtr = DoMistake(
    key: '5.8/m5_workshop_referral/recharge-dtr',
    textBn: 'ভেতরের ফল্টযুক্ত ট্রান্সফরমারকে বারবার চার্জ করলে সেটি বিস্ফোরিত হতে পারে। ফল্ট না পেয়ে আর চার্জ নয় — প্রমাণ নিয়ে ওয়ার্কশপে পাঠান।',
    art: 'assets/game/art/m5_workshop_referral/recharge_dtr.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const rechargeLt = DoMistake(
    key: '5.8/m5_workshop_referral/recharge-lt',
    textBn: 'LT ফিডার লাগাতেই ফিউজ উড়েছে — ফিডার লাগানো অবস্থায় যেমন আছে আবার চার্জ নয়! আগে LT লাইনে ফল্ট খুঁজুন।',
    art: 'assets/game/art/m5_workshop_referral/recharge_lt.svg',
    deadly: true,
    lessonPoint: 0,
  );
  // The module's rule (rulings M5-2), not lesson 5.8's text: no lesson point.
  static const noTest = DoMistake(
    key: '5.8/m5_workshop_referral/no-test',
    textBn: 'টেস্টারে 0 V না দেখে বুশিং-এ ওঠা বা হাত নয়! বিচ্ছিন্ন ট্রান্সফরমারেও আগে টেস্টার দিয়ে ডেড প্রমাণ।',
    art: 'assets/game/art/m5_workshop_referral/no_test.svg',
    deadly: true,
  );
  static const workshopAtLt = DoMistake(
    key: '5.8/m5_workshop_referral/workshop-at-lt',
    textBn: 'সব LT খুলে DO ধরে ছিল, ফিডার লাগাতেই উড়েছে — দোষ ট্রান্সফরমারে নয়, ওই LT লাইনে। টহল দল পাঠান।',
    art: 'assets/game/art/m5_workshop_referral/wrong_team_lt.svg',
    lessonPoint: 0,
  );
  static const patrolAtDtr = DoMistake(
    key: '5.8/m5_workshop_referral/patrol-at-dtr',
    textBn: 'সব LT খোলা, তবু DO লাগাতেই উড়েছে — দোষ ট্রান্সফরমারের ভেতরেই। প্রমাণ নিয়ে ওয়ার্কশপে পাঠান।',
    art: 'assets/game/art/m5_workshop_referral/wrong_team_dtr.svg',
    lessonPoint: 0,
  );
  static const cleanBushing = DoMistake(
    key: '5.8/m5_workshop_referral/clean-bushing',
    textBn: 'এই বুশিং-এ ফাটল বা ফ্ল্যাশওভারের দাগ নেই — এটা প্রমাণ নয়। শুধু যা সত্যি দেখেছেন তা-ই স্লিপে তুলুন।',
    art: 'assets/game/art/m5_workshop_referral/clean_bushing.svg',
    lessonPoint: 0,
  );
  static const highIr = DoMistake(
    key: '5.8/m5_workshop_referral/high-ir',
    textBn: 'এই সারির IR উঁচু — এটা প্রমাণ নয়। শূন্যের কাছাকাছি IR-ই ভেতরের শর্ট সার্কিটের নিশ্চিত প্রমাণ।',
    art: 'assets/game/art/m5_workshop_referral/high_ir.svg',
    lessonPoint: 0,
  );
  // A false oil pin names only the part pinned (another part of the same jar
  // may be a real finding).
  static const cleanOilColour = DoMistake(
    key: '5.8/m5_workshop_referral/clean-oil-colour',
    textBn: 'এই তেলের রং খুব কালো নয়, কার্বন কণাও নেই — এটা প্রমাণ নয়। যা সত্যি দেখেছেন শুধু তা-ই স্লিপে তুলুন।',
    art: 'assets/game/art/m5_workshop_referral/clean_oil_colour.svg',
    lessonPoint: 0,
  );
  static const cleanOilWater = DoMistake(
    key: '5.8/m5_workshop_referral/clean-oil-water',
    textBn: 'তলায় জলের ফোঁটা নেই — এটা প্রমাণ নয়। যা সত্যি দেখেছেন শুধু তা-ই স্লিপে তুলুন।',
    art: 'assets/game/art/m5_workshop_referral/clean_oil_water.svg',
    lessonPoint: 2,
  );
  static const cleanOilSmell = DoMistake(
    key: '5.8/m5_workshop_referral/clean-oil-smell',
    textBn: 'পোড়া গন্ধ নেই — এটা প্রমাণ নয়। যা সত্যি দেখেছেন শুধু তা-ই স্লিপে তুলুন।',
    art: 'assets/game/art/m5_workshop_referral/clean_oil_smell.svg',
    lessonPoint: 0,
  );
  static const routineRecord = DoMistake(
    key: '5.8/m5_workshop_referral/routine-record',
    textBn: 'নিয়মিত কাজের লেখা প্রমাণ নয়। ইতিহাসে খুঁজুন: আগেও খারাপ হয়েছিল কি? বারবার ওভারলোড হয় কি?',
    art: 'assets/game/art/m5_workshop_referral/routine_record.svg',
    lessonPoint: 0,
  );
  static const missingProof = DoMistake(
    key: '5.8/m5_workshop_referral/missing-proof',
    textBn: 'একটা প্রমাণ এখনো স্লিপে ওঠেনি। বুশিং, IR কার্ড, তেল, রেকর্ড — সব দেখে তবে পাঠান।',
    art: 'assets/game/art/m5_workshop_referral/missing_proof.svg',
    lessonPoint: 0,
  );
  static const waterMyth = DoMistake(
    key: '5.8/m5_workshop_referral/water-myth',
    textBn: 'জল তেলের সবচেয়ে বড় শত্রু — ডাই-ইলেকট্রিক স্ট্রেন্থ নাটকীয়ভাবে কমায়। জলের ফোঁটাও প্রমাণ।',
    art: 'assets/game/art/m5_workshop_referral/water_myth.svg',
    lessonPoint: 2,
  );

  static DoMistake falsePin(M5WrProof p) => switch (p.station) {
        M5WrStation.bushing => cleanBushing,
        M5WrStation.ir => highIr,
        M5WrStation.oil => switch (M5WrOilPart.values[p.index]) {
            M5WrOilPart.colour => cleanOilColour,
            M5WrOilPart.water => cleanOilWater,
            M5WrOilPart.smell => cleanOilSmell,
          },
        M5WrStation.record => routineRecord,
      };

  static const List<DoMistake> all = [
    rechargeDtr,
    rechargeLt,
    noTest,
    workshopAtLt,
    patrolAtDtr,
    cleanBushing,
    highIr,
    cleanOilColour,
    cleanOilWater,
    cleanOilSmell,
    routineRecord,
    missingProof,
    waterMyth,
  ];
}

/// One thing a player may pin: a station and the item in it (bushing 0–2,
/// IR row 0–2, oil part index, record entry 0–3).
@immutable
class M5WrProof {
  const M5WrProof(this.station, this.index);
  final M5WrStation station;
  final int index;

  static M5WrProof oil(M5WrOilPart p) => M5WrProof(M5WrStation.oil, p.index);

  @override
  bool operator ==(Object other) => other is M5WrProof && other.station == station && other.index == index;

  @override
  int get hashCode => Object.hash(station, index);

  @override
  String toString() => '${station.name}#$index';
}

/// One dealt site.
@immutable
class M5WrSite {
  const M5WrSite({
    required this.kind,
    this.late = false,
    this.feeder = 1,
    this.bushingMarks = const [0, 0, 0],
    this.irLow,
    this.oilDark = false,
    this.oilWater = false,
    this.oilBurnt = false,
    this.record = const [],
    this.recordFind = const {},
    this.why = M5WrWhy.workshop,
  });

  final M5WrKind kind;

  /// Transformer site: the DO blew a while after going in (not at once).
  final bool late;

  /// LT site: the feeder that blew the DO.
  final int feeder;

  /// Per bushing: 0 clean, 1 crack, 2 flashover track.
  final List<int> bushingMarks;

  /// The IR row near zero, if any.
  final int? irLow;
  final bool oilDark;
  final bool oilWater;
  final bool oilBurnt;

  /// The record book's four entries, top to bottom, and which are proof.
  final List<String> record;
  final Set<int> recordFind;

  /// What the site's reason asks about.
  final M5WrWhy why;

  Set<M5WrProof> get findings => {
        for (final (i, m) in bushingMarks.indexed)
          if (m != 0) M5WrProof(M5WrStation.bushing, i),
        if (irLow != null) M5WrProof(M5WrStation.ir, irLow!),
        if (oilDark) M5WrProof.oil(M5WrOilPart.colour),
        if (oilWater) M5WrProof.oil(M5WrOilPart.water),
        if (oilBurnt) M5WrProof.oil(M5WrOilPart.smell),
        for (final i in recordFind) M5WrProof(M5WrStation.record, i),
      };

  /// The stations holding at least one finding.
  Set<M5WrStation> get present => {for (final p in findings) p.station};
}

@immutable
class M5WrDeal {
  const M5WrDeal({required this.sites, required this.push, required this.pushSite});

  /// The three sites in play order (two transformer sites, one LT site).
  final List<M5WrSite> sites;

  /// The coworker's push and the (transformer) site he comes at.
  final M5WrPush push;
  final int pushSite;
}

M5WrSite _dealDtr(math.Random rng, {required bool forceWater, required bool pushCharge}) {
  final stations = [...M5WrStation.values]..shuffle(rng);
  final n = 2 + rng.nextInt(2);
  final present = stations.take(n).toSet();
  if (forceWater && !present.contains(M5WrStation.oil)) {
    present
      ..remove(present.first)
      ..add(M5WrStation.oil);
  }
  // Three stations: one finding each; two: oil and record may hold two.
  final rich = present.length == 2;
  var marks = const [0, 0, 0];
  if (present.contains(M5WrStation.bushing)) {
    final m = [0, 0, 0];
    m[rng.nextInt(3)] = 1 + rng.nextInt(2);
    marks = m;
  }
  final irLow = present.contains(M5WrStation.ir) ? rng.nextInt(3) : null;
  var dark = false, water = false, burnt = false;
  if (present.contains(M5WrStation.oil)) {
    final parts = [...M5WrOilPart.values]..shuffle(rng);
    final take = {...parts.take(rich && rng.nextBool() ? 2 : 1)};
    if (forceWater && !take.contains(M5WrOilPart.water)) {
      take
        ..remove(take.first)
        ..add(M5WrOilPart.water);
    }
    dark = take.contains(M5WrOilPart.colour);
    water = take.contains(M5WrOilPart.water);
    burnt = take.contains(M5WrOilPart.smell);
  }
  final record = <String>[];
  final find = <int>{};
  {
    final finds = [...M5WrLines.recordFind]..shuffle(rng);
    final routine = [...M5WrLines.recordRoutine]..shuffle(rng);
    final nFind = present.contains(M5WrStation.record) ? (rich && rng.nextBool() ? 2 : 1) : 0;
    final entries = <(String, bool)>[for (final f in finds.take(nFind)) (f, true), for (final r in routine.take(4 - nFind)) (r, false)]..shuffle(rng);
    for (final (i, e) in entries.indexed) {
      record.add(e.$1);
      if (e.$2) find.add(i);
    }
  }
  final whys = [
    M5WrWhy.workshop,
    if (irLow != null) M5WrWhy.ir,
    if (water) M5WrWhy.water,
    if (pushCharge) M5WrWhy.noCharge,
  ];
  return M5WrSite(
    kind: M5WrKind.dtr,
    late: rng.nextBool(),
    bushingMarks: marks,
    irLow: irLow,
    oilDark: dark,
    oilWater: water,
    oilBurnt: burnt,
    record: record,
    recordFind: find,
    why: whys[rng.nextInt(whys.length)],
  );
}

M5WrSite _dealLt(math.Random rng) {
  final routine = [...M5WrLines.recordRoutine]..shuffle(rng);
  return M5WrSite(kind: M5WrKind.lt, feeder: 1 + rng.nextInt(4), record: routine.take(4).toList(), why: M5WrWhy.lt);
}

/// A fresh play.
M5WrDeal m5WrDeal(math.Random rng) {
  final ltAt = rng.nextInt(3);
  final dtrAt = [for (var i = 0; i < 3; i++) if (i != ltAt) i];
  final push = rng.nextBool() ? M5WrPush.charge : M5WrPush.water;
  final pushSite = dtrAt[rng.nextInt(2)];
  final sites = [
    for (var i = 0; i < 3; i++)
      i == ltAt
          ? _dealLt(rng)
          : _dealDtr(rng, forceWater: push == M5WrPush.water && i == pushSite, pushCharge: push == M5WrPush.charge && i == pushSite),
  ];
  return M5WrDeal(sites: sites, push: push, pushSite: pushSite);
}

/// The play state (pure logic).
class M5WrRun {
  M5WrRun(this.deal);
  final M5WrDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The site's work is done (its reason comes next).
  var roundDone = false;

  // The site now.
  var stage = M5WrStage.log;
  var logRead = false;
  var tested = false;
  M5WrStation? open;
  var rubbed = false;

  /// Oil gestures done, in order: 1 sun, 2 swirl, 3 sniff.
  int oilStep = 0;
  final Set<M5WrProof> pinned = {};
  var sent = false;
  var _teamSlip = false;
  var _pinSlip = false;

  M5WrSite get site => deal.sites[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;
  Set<M5WrProof> get missing => site.findings.difference(pinned);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  /// The log has been read (closed): the team choice opens.
  void readLog() {
    if (!_open) return;
    logRead = true;
    if (stage == M5WrStage.log) stage = M5WrStage.choose;
  }

  /// The team the player calls.
  DoMistake? choose(M5WrTeam t) {
    if (!_open || stage != M5WrStage.choose) return null;
    final dtr = site.kind == M5WrKind.dtr;
    switch (t) {
      case M5WrTeam.recharge:
        return deadly = dtr ? M5WrMistakes.rechargeDtr : M5WrMistakes.rechargeLt;
      case M5WrTeam.patrol:
        if (dtr) {
          _teamSlip = true;
          return _slip(M5WrMistakes.patrolAtDtr);
        }
        roundDone = true;
      case M5WrTeam.workshop:
        if (!dtr) {
          _teamSlip = true;
          return _slip(M5WrMistakes.workshopAtLt);
        }
        stage = M5WrStage.proof;
    }
    if (!_teamSlip) _tag(M5WrLines.caughtTeam);
    return null;
  }

  /// The HT tester on its hot stick, held to the bushings: 0 V.
  void test() {
    if (!_open || stage != M5WrStage.proof || open != null) return;
    tested = true;
  }

  /// A station's close-up. The bushings before the tester's 0 V = deadly.
  DoMistake? openStation(M5WrStation s) {
    if (!_open || stage != M5WrStage.proof || open != null) return null;
    if (s == M5WrStation.bushing) {
      if (!tested) return deadly = M5WrMistakes.noTest;
      _tag(M5WrLines.caughtTest);
    }
    open = s;
    return null;
  }

  void closeStation() => open = null;

  /// The cloth pass over the bushings (the dust comes off). True if it did.
  bool rub() {
    if (!_open || open != M5WrStation.bushing || rubbed) return false;
    rubbed = true;
    return true;
  }

  /// An oil gesture ([step] 0 sun, 1 swirl, 2 sniff): only the next one in
  /// the fixed order counts. True if it did.
  bool oil(int step) {
    if (!_open || open != M5WrStation.oil || step != oilStep || oilStep >= 3) return false;
    oilStep++;
    return true;
  }

  /// Can [p] be pinned now (its station open and looked at, not pinned yet)?
  bool canPin(M5WrProof p) =>
      _open &&
      open == p.station &&
      (p.station != M5WrStation.bushing || rubbed) &&
      (p.station != M5WrStation.oil || oilStep >= 3) &&
      !pinned.contains(p);

  /// Pins [p] on the slip: a finding, or a slip (a clean item).
  DoMistake? pin(M5WrProof p) {
    if (!canPin(p)) return null;
    if (site.findings.contains(p)) {
      pinned.add(p);
      return null;
    }
    _pinSlip = true;
    return _slip(M5WrMistakes.falsePin(p));
  }

  /// 'পাঠান': every finding on the slip → off to the workshop.
  DoMistake? send() {
    if (!_open || stage != M5WrStage.proof || open != null) return null;
    if (missing.isNotEmpty) {
      _pinSlip = true;
      return _slip(M5WrMistakes.missingProof);
    }
    sent = true;
    roundDone = true;
    if (!_pinSlip) _tag(M5WrLines.caughtProof);
    return null;
  }

  /// Listening to the water myth: a slip.
  DoMistake listenWater() => _slip(M5WrMistakes.waterMyth);

  /// Fails the play (listening to the charge push).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    roundSlips = 0;
    roundDone = false;
    stage = M5WrStage.log;
    logRead = false;
    tested = false;
    open = null;
    rubbed = false;
    oilStep = 0;
    pinned.clear();
    sent = false;
    _teamSlip = false;
    _pinSlip = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   LT site: log tap + close + team ≈ 4500 + reason ~8200          ≈ 12700
///   transformer site: log + team ≈ 4500, tester hold 1500, four stations
///     (open, look, 1–2 pins, close ≈ 6000 each; oil +3000) ≈ 27000,
///     send + crane 2500, reason ~8200                       ≈ 43700 × 2
/// + the coworker once ≈ 9600                                     ≈ 109700
/// 85 % ≈ 93000 → 90 s.
const m5WrQuickMs = 90000;

/// A site's team row, shuffled (no fixed place for any team).
List<M5WrTeam> m5WrTeamRow(math.Random rng) => [...M5WrTeam.values]..shuffle(rng);

@immutable
class M5WrPack {
  const M5WrPack({required this.id, required this.titleBn, this.quickMs = m5WrQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5WrPack> m5WorkshopReferralPacks = {
  'do_5_8_b': M5WrPack(id: 'do_5_8_b', titleBn: M5WrLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M5WorkshopReferralPage extends StatefulWidget {
  const M5WorkshopReferralPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5WrPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5WorkshopReferralPage> createState() => _M5WorkshopReferralPageState();
}

class _M5WorkshopReferralPageState extends State<M5WorkshopReferralPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ReferralRunPage(
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

class _ReferralRunPage extends ConsumerStatefulWidget {
  const _ReferralRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5WrPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ReferralRunPage> createState() => _ReferralRunPageState();
}

/// Where a deadly flash goes.
enum _Flash { bushing, tank, fuse }

class _ReferralRunPageState extends ConsumerState<_ReferralRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5WrRun _run;
  late final List<List<M5WrTeam>> _teams;
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

  /// The log card is up.
  var _logOpen = false;

  /// The tester was tapped (not held): its hint now shows the hold.
  var _testerTapped = false;

  /// The cloth pass in the bushing close-up (accumulated drag).
  double _rub = 0;

  /// The oil close-up's swirl drag, and its ripple token.
  double _swirlDrag = 0;
  int _swirlTok = 0;

  /// The crane lifting the transformer.
  var _lifting = false;
  int _liftTok = 0;

  var _freeze = false;
  _Flash _flash = _Flash.tank;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _lensKey = GlobalKey();
  final _logOkKey = GlobalKey();
  final Map<M5WrTeam, GlobalKey> _teamKeys = {for (final t in M5WrTeam.values) t: GlobalKey()};
  M5WrGeo? _geoNow;

  /// The team button open big (two steps: its preview, then ✓), where it was
  /// tapped, and the teams set aside with ✕ at this site.
  M5WrTeam? _teamPreview;
  Offset _teamAt = Offset.zero;
  final Set<M5WrTeam> _teamAside = {};

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same), then the team rows.
    _run = M5WrRun(m5WrDeal(widget.rng));
    _teams = [for (var i = 0; i < 3; i++) m5WrTeamRow(widget.rng)];
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

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_lifting;

  String get _task => switch (_run.stage) {
        M5WrStage.log => M5WrLines.askLog,
        M5WrStage.choose => M5WrLines.askChoose,
        M5WrStage.proof => _run.open == null ? M5WrLines.askProof : M5WrLines.askLens[_run.open]!,
      };

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- hands on ----------------------------------------------------------------
  void _openLog() {
    if (!_canPlay || _logOpen || _run.open != null) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() {
      _logOpen = true;
      _wake++;
    });
  }

  void _closeLog() {
    if (!_logOpen) return;
    _tick();
    final first = _run.stage == M5WrStage.log;
    setState(() {
      _logOpen = false;
      _run.readLog();
      _wake++;
    });
    if (!first) return;
    if (_run.deal.push == M5WrPush.charge && _run.index == _run.deal.pushSite) scheduleCoworker();
    unawaited(_sayChain([M5WrLines.askChoose], mood: GuideMood.think));
  }

  /// A tap on a team button opens it big; nothing is decided yet.
  void _openTeam(M5WrTeam t, Offset global) {
    if (!_canPlay || _logOpen || _teamPreview != null || _run.stage != M5WrStage.choose) return;
    setState(() {
      _teamPreview = t;
      _teamAt = global;
    });
  }

  /// ✓ on the team's preview: the decision (as one tap was before).
  void _confirmTeam() {
    final t = _teamPreview;
    if (t == null) return;
    setState(() {
      _teamPreview = null;
      _teamAside.clear();
    });
    _choose(t, _teamAt);
  }

  /// ✕: that team is set aside (dimmed), nothing is decided.
  void _rejectTeam() {
    final t = _teamPreview;
    if (t == null) return;
    setState(() {
      _teamPreview = null;
      _teamAside.add(t);
    });
  }

  void _choose(M5WrTeam t, Offset global) {
    if (!_canPlay || _logOpen) return;
    // The decision waits for the coworker once he is due at this site.
    if (holdForCoworker()) return;
    _tick(t == M5WrTeam.recharge ? 'sounds/intro/impact_metal.ogg' : 'sounds/intro/click.ogg', 0.5);
    final m = _run.choose(t);
    setState(() => _wake++);
    if (m != null) {
      if (m.deadly) _flash = _run.site.kind == M5WrKind.dtr ? _Flash.tank : _Flash.fuse;
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.roundDone) {
      unawaited(_roundDone());
      return;
    }
    // The workshop van at a transformer site: the proof round.
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.5);
    unawaited(_sayChain([M5WrLines.askProof]));
  }

  void _tapScene(Offset p, M5WrGeo geo, Offset global) {
    if (!_canPlay || _logOpen || _run.open != null) return;
    if (geo.logHit.contains(p)) {
      _openLog();
      return;
    }
    if (_run.stage == M5WrStage.proof) {
      if (!_run.tested && geo.testerHit.contains(p)) {
        // A tap is not enough: the tester is held to the bushings.
        _tick();
        setState(() => _testerTapped = true);
        _hints.missTap();
        return;
      }
      for (final s in M5WrStation.values) {
        if (geo.stationHit(s).contains(p)) {
          _openStation(s, global);
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _holdScene(Offset p, M5WrGeo geo) {
    if (!_canPlay || _logOpen || _run.open != null) return;
    if (_run.stage != M5WrStage.proof || _run.tested || !geo.testerHit.contains(p)) {
      _hints.missTap();
      return;
    }
    _run.test();
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.8);
    setState(() => _wake++);
  }

  void _openStation(M5WrStation s, Offset global) {
    _tick('sounds/intro/click.ogg', 0.5);
    final m = _run.openStation(s);
    if (m != null) {
      _flash = _Flash.bushing;
      unawaited(_mistake(m, global));
      return;
    }
    setState(() {
      _rub = 0;
      _swirlDrag = 0;
      _wake++;
    });
    unawaited(_sayChain([M5WrLines.askLens[s]!]));
  }

  bool get _lensLive => _canPlay && _run.open != null;

  void _closeStation() {
    if (!_lensLive) return;
    if (_run.open == M5WrStation.oil && holdForCoworker()) return;
    _tick();
    setState(() {
      _run.closeStation();
      _wake++;
    });
    unawaited(_sayChain([M5WrLines.askProof]));
  }

  /// A tap inside the close-up (lens-local [p]).
  void _tapLens(Offset p, Offset global) {
    if (!_lensLive) return;
    final open = _run.open!;
    M5WrProof? hit;
    switch (open) {
      case M5WrStation.bushing:
        for (var i = 0; i < 3; i++) {
          if (M5WrLens.bushing(i).contains(p)) hit = M5WrProof(M5WrStation.bushing, i);
        }
      case M5WrStation.ir:
        for (var i = 0; i < 3; i++) {
          if (M5WrLens.irRow(i).contains(p)) hit = M5WrProof(M5WrStation.ir, i);
        }
      case M5WrStation.record:
        for (var i = 0; i < 4; i++) {
          if (M5WrLens.entry(i).contains(p)) hit = M5WrProof(M5WrStation.record, i);
        }
      case M5WrStation.oil:
        if (holdForCoworker()) return;
        if (_run.oilStep == 2 && M5WrLens.mouth.contains(p)) {
          _oilStep(2);
          return;
        }
        for (final part in M5WrOilPart.values) {
          if (M5WrLens.oilPart(part).contains(p)) hit = M5WrProof.oil(part);
        }
    }
    if (hit == null || !_run.canPin(hit)) {
      _hints.missTap();
      return;
    }
    _pin(hit, global);
  }

  void _pin(M5WrProof p, Offset global) {
    _tick('sounds/learn/tag_slap.ogg', 0.55);
    final m = _run.pin(p);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.5);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
  }

  void _rubLens(double dx) {
    if (!_lensLive || _run.open != M5WrStation.bushing || _run.rubbed) return;
    _rub += dx.abs();
    if (_rub < 120) return;
    if (_run.rub()) {
      _cue('sounds/learn/card_deal_a.ogg', volume: 0.5);
      setState(() => _wake++);
    }
  }

  void _oilStep(int step) {
    if (!_lensLive || _run.open != M5WrStation.oil) return;
    if (step > 0 && holdForCoworker()) return;
    if (!_run.oil(step)) {
      _hints.missTap();
      return;
    }
    _tick(step == 1 ? 'sounds/learn/card_deal_a.ogg' : 'sounds/intro/click.ogg', 0.5);
    setState(() {
      if (step == 1) _swirlTok++;
      _wake++;
    });
    // The water-bead jar: he comes after the swirl, before any pin.
    if (step == 1 && _run.deal.push == M5WrPush.water && _run.index == _run.deal.pushSite) scheduleCoworker();
  }

  Future<void> _send(Offset global) async {
    if (!_canPlay || _run.open != null || _run.stage != M5WrStage.proof) return;
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    final m = _run.send();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    setState(() {
      _lifting = true;
      _liftTok++;
      _wake++;
    });
    final idx = _run.index;
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 1400));
    if (!mounted || _ended || _run.index != idx) return;
    setState(() => _lifting = false);
    unawaited(_roundDone());
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final why = _run.site.why;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5WrLines.whyRight[why]!, M5WrLines.myths, widget.rng),
      question: M5WrLines.whyQ[why]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(() {
      _run.next();
      _logOpen = false;
      _testerTapped = false;
      _rub = 0;
      _swirlDrag = 0;
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
  CoworkerScript get coworkerScript => _run.deal.push == M5WrPush.charge ? M5WrLines.coworkerCharge : M5WrLines.coworkerWater;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final d = _run.deal;
    if (_ended || _run.index > d.pushSite) return null;
    if (_run.index < d.pushSite) return false;
    if (d.push == M5WrPush.charge) {
      if (_run.stage == M5WrStage.proof || _run.roundDone) return null;
      if (_run.stage != M5WrStage.choose) return false;
    } else {
      if (_run.roundDone || _run.pinned.contains(M5WrProof.oil(M5WrOilPart.water))) return null;
      if (_run.open != M5WrStation.oil || _run.oilStep < 2) return false;
    }
    if (_intro || _card != null || tableBusy || _freeze || _logOpen || _lifting || _teamPreview != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final charge = _run.deal.push == M5WrPush.charge;
    if (!held) {
      if (charge) {
        // Listened: the DO goes back in on a transformer with an inner fault.
        _run.failDeadly(M5WrMistakes.rechargeDtr);
        _flash = _Flash.tank;
        await _deadly(M5WrMistakes.rechargeDtr);
        return;
      }
      await _mistake(_run.listenWater(), origin);
      return;
    }
    _run.caught.add(charge ? M5WrLines.caughtCharge : M5WrLines.caughtWater);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([charge ? M5WrLines.heldCharge : M5WrLines.heldWater, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5WrLines.tapWhy[_nudgeN++ % M5WrLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('wkref/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the scene freezes grey, the arc or blast plays in colour;
  /// then near-miss or death.
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
      _logOpen = false;
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
    final speak = await SpokenOnce.first('wkref/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5WrLines.deadlyWord : M5WrLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same site goes on from where it was.
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
    await _say(!_run.passed ? M5WrLines.fail : (_quickBonus ? M5WrLines.quick : M5WrLines.allSet),
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

  // --- the gesture hand ---------------------------------------------------------
  /// A lens-local rect on screen (null before layout).
  Rect? _lensRect(Rect local) {
    final box = _lensKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return local.shift(box.localToGlobal(Offset.zero));
  }

  /// How to touch now, never what: a tap only on the one way forward (the log,
  /// its ঠিক আছে), a sweep over every choice of the moment (the three teams;
  /// the tester and the four stations; every bushing, row, part or entry), the
  /// cloth drag along the whole bushing row, and the oil gestures in their
  /// fixed order (the same for every jar). 'পাঠান' is never hinted.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_logOpen) return HintSpec.tapOn(_logOkKey);
    switch (_run.stage) {
      case M5WrStage.log:
        return HintSpec.tap(geo.logHit.center, space: HintSpace.scene);
      case M5WrStage.choose:
        return HintSpec.sweepOver([for (final t in _teams[_run.index]) _teamKeys[t]!]);
      case M5WrStage.proof:
        final open = _run.open;
        if (open == null) {
          if (_testerTapped && !_run.tested) return HintSpec.hold(geo.testerHit.center, space: HintSpace.scene);
          final rects = [
            if (!_run.tested) geo.testerHit,
            for (final s in M5WrStation.values) geo.stationHit(s),
          ]..sort((a, b) => a.center.dx.compareTo(b.center.dx));
          return HintSpec.sweep(rects, space: HintSpace.scene);
        }
        List<Rect> sweep(Iterable<Rect> local) => [for (final r in local) ?_lensRect(r)];
        switch (open) {
          case M5WrStation.bushing:
            if (!_run.rubbed) {
              final r = _lensRect(M5WrLens.bushing(0));
              return r == null ? null : HintSpec.drag(r.center, toward: const Offset(1, 0), travel: 96);
            }
            return HintSpec.sweep(sweep([for (var i = 0; i < 3; i++) M5WrLens.bushing(i)]));
          case M5WrStation.ir:
            return HintSpec.sweep(sweep([for (var i = 0; i < 3; i++) M5WrLens.irRow(i)]));
          case M5WrStation.record:
            return HintSpec.sweep(sweep([for (var i = 0; i < 4; i++) M5WrLens.entry(i)]));
          case M5WrStation.oil:
            final jar = _lensRect(M5WrLens.jar);
            final mouth = _lensRect(M5WrLens.mouth);
            if (jar == null || mouth == null) return null;
            return switch (_run.oilStep) {
              0 => HintSpec.hold(jar.center),
              1 => HintSpec.swipe(jar.centerLeft.translate(10, 0), toward: const Offset(1, 0), travel: 90),
              2 => HintSpec.tap(mouth.center),
              _ => HintSpec.sweep(sweep([for (final p in M5WrOilPart.values) M5WrLens.oilPart(p)])),
            };
        }
    }
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_run.open != null || _logOpen) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  Offset _flashAt(M5WrGeo geo) => switch (_flash) {
        _Flash.bushing => geo.flashBushing,
        _Flash.tank => geo.flashTank,
        _Flash.fuse => Offset(M5WrGeo.phaseX[1], geo.doArmY + 12),
      };

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5WrGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final seed = _run.index * 31 + 7;
    Widget site(double lift) => CustomPaint(
          painter: M5WrPainter(geo: geo, rig: M5WrRig(tested: _run.tested, sent: _run.sent && !_lifting, lift: lift), seed: seed),
        );
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: ValueKey(_lifting ? 'site-lift-$_liftTok' : 'site'),
                child: RepaintBoundary(
                  child: _lifting
                      ? TweenAnimationBuilder<double>(
                          tween: Tween(begin: quiet ? 1 : 0, end: 1),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeIn,
                          builder: (_, v, _) => site(v),
                        )
                      : site(0),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.ground,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (_run.tested && !_run.sent && !_freeze)
        Positioned(
          key: ValueKey('tester-${_run.index}'),
          left: geo.htBushings[0].dx - 46,
          top: geo.htBushings[0].dy - 48,
          child: const IgnorePointer(child: _TesterChip()),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5WrLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onLongPressStart: (d) => _holdScene(d.localPosition, geo),
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
              builder: (_, v, _) => CustomPaint(painter: M5WrFlashPainter(at: _flashAt(geo), v: v, blast: _flash == _Flash.tank)),
            ),
          ),
        ),
      // The next site: a short fade.
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

  static const _teamIcons = {
    M5WrTeam.workshop: Icons.local_shipping_rounded,
    M5WrTeam.patrol: Icons.directions_walk_rounded,
    M5WrTeam.recharge: Icons.bolt_rounded,
  };

  // --- the close-ups -----------------------------------------------------------
  Widget _lensBody(M5WrStation s, bool quiet) {
    final site = _run.site;
    final pinned = {for (final p in _run.pinned) if (p.station == s) p.index};
    final List<Widget> layers;
    switch (s) {
      case M5WrStation.bushing:
        layers = [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _run.rubbed ? 0 : 1),
              duration: Duration(milliseconds: quiet ? 1 : 520),
              builder: (_, v, _) => CustomPaint(painter: M5WrBushingPainter(mark: site.bushingMarks, dust: v, pinned: pinned)),
            ),
          ),
          for (var i = 0; i < 3; i++) _marker('lens-bushing-$i', M5WrLens.bushing(i)),
        ];
      case M5WrStation.ir:
        layers = [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xFFF7F3E6), borderRadius: BorderRadius.circular(10))),
          ),
          for (var i = 0; i < 3; i++)
            Positioned.fromRect(
              key: ValueKey('lens-ir-$i'),
              rect: M5WrLens.irRow(i),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x665C6B80)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(M5WrLines.irRows[i],
                          textAlign: TextAlign.center, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF1B2436))),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(child: CustomPaint(painter: M5WrIrScalePainter(low: site.irLow == i, pinned: pinned.contains(i)))),
                          Positioned(left: 8, bottom: 2, child: Text('0', style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF3A4660)))),
                          Positioned(right: 8, bottom: 2, child: Text('∞', style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF3A4660)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ];
      case M5WrStation.oil:
        layers = [
          Positioned.fill(
            child: _swirlTok > 0
                ? TweenAnimationBuilder<double>(
                    key: ValueKey('swirl-$_swirlTok'),
                    tween: Tween(begin: quiet ? 0 : 1, end: 0),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, _) => _oilPaint(site, v),
                  )
                : _oilPaint(site, 0),
          ),
          _marker('lens-jar', M5WrLens.jar),
          _marker('lens-mouth', M5WrLens.mouth),
          for (final p in M5WrOilPart.values) _marker('lens-oil-${p.name}', M5WrLens.oilPart(p)),
        ];
      case M5WrStation.record:
        layers = [
          Positioned.fill(child: CustomPaint(painter: M5WrPagePainter(pinned: pinned))),
          for (var i = 0; i < 4; i++)
            Positioned.fromRect(
              key: ValueKey('lens-entry-$i'),
              rect: M5WrLens.entry(i),
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(site.record[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF1B2436))),
                ),
              ),
            ),
        ];
    }
    return SizedBox(
      key: _lensKey,
      width: M5WrLens.size.width,
      height: M5WrLens.size.height,
      child: Stack(
        children: [
          ...layers,
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _tapLens(d.localPosition, d.globalPosition),
              onLongPressStart: s == M5WrStation.oil
                  ? (d) {
                      if (M5WrLens.jar.contains(d.localPosition)) {
                        _oilStep(0);
                      } else {
                        _hints.missTap();
                      }
                    }
                  : null,
              onHorizontalDragStart: s == M5WrStation.ir || s == M5WrStation.record
                  ? null
                  : (_) => _swirlDrag = 0,
              onHorizontalDragUpdate: s == M5WrStation.ir || s == M5WrStation.record
                  ? null
                  : (d) {
                      if (s == M5WrStation.bushing) {
                        _rubLens(d.delta.dx);
                      } else {
                        _swirlDrag += d.delta.dx.abs();
                      }
                    },
              onHorizontalDragEnd: s == M5WrStation.oil
                  ? (_) {
                      if (_swirlDrag >= 50) _oilStep(1);
                      _swirlDrag = 0;
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _oilPaint(M5WrSite site, double swirl) => CustomPaint(
        painter: M5WrOilPainter(
          step: _run.oilStep,
          dark: site.oilDark,
          water: site.oilWater,
          burnt: site.oilBurnt,
          pinned: {for (final p in _run.pinned) if (p.station == M5WrStation.oil) M5WrOilPart.values[p.index]},
          swirl: swirl,
        ),
      );

  /// An invisible marker over a lens region (tests find the regions by key).
  Widget _marker(String key, Rect r) => Positioned.fromRect(key: ValueKey(key), rect: r, child: const IgnorePointer(child: SizedBox.expand()));

  Widget _lens(M5WrStation s, bool quiet) {
    return Container(
      key: ValueKey('lens-card-${s.name}-${_run.index}'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xF20B1324),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M5WrLines.stationName[s]!, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: _lensBody(s, quiet)),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: M5WrLines.close,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('lens-close'),
              behavior: HitTestBehavior.opaque,
              onTap: _closeStation,
              child: Container(
                height: 44,
                width: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2E4A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.4),
                ),
                child: Text(M5WrLines.close, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard() {
    final site = _run.site;
    final lines = site.kind == M5WrKind.dtr
        ? [M5WrLines.logAllOpen, M5WrLines.logDoIn, site.late ? M5WrLines.logBlewLater : M5WrLines.logBlewNow]
        : [M5WrLines.logAllOpen, M5WrLines.logHeld, M5WrLines.logLtBlew(site.feeder), M5WrLines.logLtStillIn(site.feeder)];
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8A5A2E), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(M5WrLines.logTitle, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1B2436))),
          const SizedBox(height: 8),
          for (final (i, l) in lines.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${i + 1}. $l', style: bangla(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3, color: const Color(0xFF2A3346))),
            ),
          const SizedBox(height: 6),
          Center(
            child: Semantics(
              button: true,
              label: M5WrLines.logOk,
              excludeSemantics: true,
              child: GestureDetector(
                key: _logOkKey,
                behavior: HitTestBehavior.opaque,
                onTap: _closeLog,
                child: Container(
                  height: 44,
                  width: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF1C2E4A), borderRadius: BorderRadius.circular(22)),
                  child: Text(M5WrLines.logOk, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slipStrip(EdgeInsets pad) {
    final pins = _run.pinned.toList();
    final sendLive = _canPlay && _run.open == null;
    return Positioned(
      key: ValueKey('hud-slip-${_run.index}'),
      left: 8,
      right: 8,
      bottom: pad.bottom + 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xF2F7F3E6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2E6FB0), width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(M5WrLines.slipTitle, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: const Color(0xFF1B2436))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          key: ValueKey('slot-$i-${i < pins.length}'),
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: i < pins.length ? const Color(0xFFFFE9E6) : const Color(0x11000000),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: i < pins.length ? const Color(0xFFD23A2E) : const Color(0x665C6B80), width: 1.4),
                          ),
                          child: i < pins.length ? Icon(_stationIcon(pins[i].station), size: 20, color: const Color(0xFFB0302A)) : null,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: M5WrLines.send,
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('wr-send'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => unawaited(_send(d.globalPosition)),
                child: Opacity(
                  opacity: sendLive ? 1 : 0.5,
                  child: Container(
                    width: 92,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFF2E6FB0), borderRadius: BorderRadius.circular(14)),
                    child: Text(M5WrLines.send, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _stationIcon(M5WrStation s) => switch (s) {
        M5WrStation.bushing => Icons.electrical_services_rounded,
        M5WrStation.ir => Icons.speed_rounded,
        M5WrStation.oil => Icons.opacity_rounded,
        M5WrStation.record => Icons.menu_book_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null && !_lifting;
    final open = _run.open;
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
              labels: M5WrLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _teamPreview == null,
            hintKey: '${_run.index}/${_run.stage.name}/${open?.name}/${_run.oilStep}/${_run.rubbed}/${_run.tested}/$_testerTapped/'
                '${_run.pinned.length}/$_logOpen',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && _run.stage == M5WrStage.choose && !_logOpen)
                Positioned(
                  key: ValueKey('hud-teams-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in _teams[_run.index.clamp(0, 2)])
                        CardAside(
                          aside: _teamAside.contains(t),
                          child: _TeamButton(
                            key: _teamKeys[t],
                            icon: _teamIcons[t]!,
                            label: M5WrLines.teamLabel(t),
                            onTap: (g) => _openTeam(t, g),
                          ),
                        ),
                    ],
                  ),
                ),
              if (playing && _run.stage == M5WrStage.proof && !_run.done) _slipStrip(pad),
              if (playing && open != null)
                Positioned.fill(
                  key: const ValueKey('lens-shade'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _hints.missTap,
                    child: const ColoredBox(color: Color(0x88050A16)),
                  ),
                ),
              if (playing && open != null)
                Positioned(
                  key: ValueKey('lens-${open.name}'),
                  top: pad.top + 104,
                  left: 0,
                  right: 0,
                  child: Center(child: _lens(open, quiet)),
                ),
              if (playing && _logOpen)
                Positioned.fill(
                  key: const ValueKey('log-shade'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _hints.missTap,
                    child: ColoredBox(color: const Color(0x88050A16), child: Center(child: _logCard())),
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: !coworkerOnScreen || coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _run.stage == M5WrStage.choose && !_logOpen && _teamPreview != null)
                Positioned.fill(
                  key: ValueKey('team-preview-${_teamPreview!.name}'),
                  child: CardPreviewOverlay(
                    textBn: M5WrLines.teamLabel(_teamPreview!),
                    icon: _teamIcons[_teamPreview!],
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmTeam,
                    onReject: _rejectTeam,
                  ),
                ),
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
                  line: M5WrLines.intro,
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

class _TesterChip extends StatelessWidget {
  const _TesterChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3A3F45))),
          const SizedBox(width: 6),
          Text(M5WrLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// A team to call: a round icon with its name under it.
class _TeamButton extends StatelessWidget {
  const _TeamButton({super.key, required this.icon, required this.label, required this.onTap});
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
          width: 104,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 26, color: SlmColors.gold300),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
