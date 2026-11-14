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
import 'level_frame.dart';
import 'level_juice.dart' show Combo, ComboPop, FreezeFrame, RescueBurst, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_gate_field_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;

// Module 2 Rank Gate (rung m2/gate, pack gate_m2): "জুনিয়রের ডকেট".
// One continuous shutdown job at a distribution transformer — replace the
// burnt lug on its LT cable — that uses the whole of Module 2 (lessons
// 2.1–2.10), in seven stations:
//   1 হাতিয়ার গোছানো — pick up and look at each tool on the van wall; pack the
//     docket's insulated tools, reject the dealt damaged twin and the bamboo stick (2.1, 2.2, 2.5, 2.10).
//   2 DO খোলা — LT switch OFF first (off-load), face shield + insulated gloves,
//     stand to the side (not under), pull the three DO fuses with the hot stick (2.5).
//   3 মৃত প্রমাণ — multimeter on V~, known live point → R, Y, B → known live
//     point again (live-dead-live); never on the 11 kV side (2.1, 2.2). The
//     readings are dealt: on some plays one phase still shows voltage — the
//     player must stop the work (the line is isolated again and re-tested);
//     a needless stop is a slip.
//   4 স্কিনিং ও ক্রিম্পিং — skin away from the body, AL 95 lug on the 95 sq mm
//     aluminium cable, the hydraulic crimper with the 95 die, pump to the click (2.3, 2.6, 2.9).
//   5 মেগার — discharge, LINE to the conductor and EARTH to the armour, 500V,
//     hold the test, discharge again, leads off, then read the dealt IR value:
//     at or above 1 MΩ the cable may go on; below it the cable stays off (the
//     team replaces the piece and the player tests again). The careless
//     coworker pushes "the multimeter showed infinity, skip the megger" (2.7).
//   6 ফেজ সিকোয়েন্স — line back on: insulated gloves, clip R-Y-B, read FWD /
//     REV (dealt); reversed → switch off and swap two phases dead (2.8).
//   7 হাতিয়ারের যত্ন — by hand, not a quiz: pick each tool up, wipe it (hold),
//     switch the meter OFF, oil the pliers' joint (not the handle), and put it
//     in its place (wall hooks, waterproof bag, toolbox — never the van floor) (2.5, 2.10).
// Passing awards the Junior ("জুনিয়র") rank (unlockRank(2)) and the
// "হাতিয়ারের ওস্তাদ" badge of Module 2.

// ============================================================================
// Content
// ============================================================================

@immutable
class M2GateFieldPack {
  const M2GateFieldPack({required this.id, required this.titleBn, this.quickMs = 240000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2GateFieldPacks = {
  'gate_m2': M2GateFieldPack(id: 'gate_m2', titleBn: M2GateLines.title),
};

enum M2GateStation { pack, doOpen, proveDead, skinCrimp, megger, phase, toolCare }

enum M2Stance { under, side }

enum M2Crimp { hyd95, hyd70, pliers }

enum M2PhaseCall { keep, swapDead, swapLive }

enum M2Care { stick, meter, pliers }

/// Where a tool can be put away at station 7.
enum M2CareSpot { hooks, bag, toolbox, floor }

const _art = 'assets/game/art/m2_gate_field';

abstract final class M2GateMistakes {
  static const bambooStick = DoMistake(
    key: 'm2/gate/bamboo-stick',
    textBn: 'বাঁশের লাঠি দিয়ে DO খোলা প্রাণঘাতী — বাঁশের ভেতরে আর্দ্রতা থাকে, হাই-ভোল্টেজে বিদ্যুৎ বয়। শুধু পরীক্ষিত ফাইবারগ্লাস হট স্টিক।',
    art: 'assets/game/art/distance/bamboo_vs_hot_stick.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const damagedTool = DoMistake(
    key: 'm2/gate/damaged-tool',
    textBn: 'ফাটা হাতল, ফাটা স্টিক বা কাটা লিডের টুল ব্যাগে নয় — ইনসুলেশনের ফাটলেই শক। বাতিল করে "ব্যবহারের অযোগ্য" লেবেল দিন।',
    art: '$_art/damaged_tool.svg',
    lessonPoint: 3,
  );
  static const goodRejected = DoMistake(
    key: 'm2/gate/good-rejected',
    textBn: 'ভালো টুল বাতিল করলে কাজের হাতিয়ার কম পড়ে — হাতে নিয়ে ফাটল, কাটা লিড, CAT রেটিং দেখে তবেই বাতিল।',
    art: '$_art/good_rejected.svg',
    lessonPoint: 3,
  );
  static const catTwo = DoMistake(
    key: 'm2/gate/cat-two',
    textBn: 'CAT II মাল্টিমিটার লাইনের কাজে নয় — লাইনম্যানের জন্য CAT III বা CAT IV রেটেড মিটার অপরিহার্য।',
    art: '$_art/mm_cat.svg',
    lessonPoint: 0,
  );
  static const doOnLoad = DoMistake(
    key: 'm2/gate/do-on-load',
    textBn: 'লোড চালু রেখে DO খোলা মারাত্মক — DO আর্ক নেভাতে পারে না। আগে LT সুইচ বন্ধ করে অফ-লোড করুন।',
    art: '$_art/do_load.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const doUnder = DoMistake(
    key: 'm2/gate/do-under',
    textBn: 'DO-র ঠিক নিচে দাঁড়িয়ে টানা মারাত্মক — আর্কের গরম গ্যাস ও গলিত ধাতু মুখে-শরীরে পড়ে। পাশে, কোণাকুণি দাঁড়ান।',
    art: '$_art/do_stance.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const doNoPpe = DoMistake(
    key: 'm2/gate/do-no-ppe',
    textBn: 'DO অপারেট করতে ফেস শিল্ড বা সেফটি গগলস আর ইনসুলেটেড গ্লাভস পরা বাধ্যতামূলক।',
    art: '$_art/do_ppe.svg',
    lessonPoint: 1,
  );
  static const mmDial = DoMistake(
    key: 'm2/gate/mm-dial',
    textBn: 'ভোল্টেজ মাপতে ডায়াল V~ (এসি) তে — রেজিস্ট্যান্স বা কন্টিনিউটি মোডে লাইভ হতে পারে এমন লাইনে প্রোব নয়।',
    art: '$_art/mm_dial.svg',
    lessonPoint: 1,
  );
  static const mmOnHt = DoMistake(
    key: 'm2/gate/mm-on-ht',
    textBn: 'হাই-ভোল্টেজ লাইনে মাল্টিমিটার ছোঁয়ানো কঠোরভাবে নিষিদ্ধ — মিটার বিস্ফোরিত হয়, আর্ক শরীরে লাগে।',
    art: '$_art/mm_ht.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const liveFirst = DoMistake(
    key: 'm2/gate/live-first',
    textBn: 'আগে জানা লাইভ পয়েন্টে মিটার যাচাই করুন — মরা মিটার "0 V" দেখালে মৃত লাইনের ধোঁকা হয়।',
    art: '$_art/live_dead_live.svg',
    lessonPoint: 4,
  );
  static const liveAfter = DoMistake(
    key: 'm2/gate/live-after',
    textBn: 'মাপার পরে আবার জানা লাইভে মিটার দেখে নিন — মাঝপথে মিটার বিগড়ালে "0 V" ভরসা নয়।',
    art: '$_art/live_dead_live.svg',
    lessonPoint: 4,
  );
  static const allPhases = DoMistake(
    key: 'm2/gate/all-phases',
    textBn: 'তিনটে ফেজই মাপুন — একটা ফেজ শূন্য দেখালেই বাকিগুলো মৃত নয়।',
    art: '$_art/live_dead_live.svg',
    lessonPoint: 1,
  );
  static const deadCallLive = DoMistake(
    key: 'm2/gate/dead-call-live',
    textBn: 'একটা ফেজে এখনো ভোল্টেজ — লাইন মৃত নয়! কাজ থামিয়ে খবর দিন; মৃত প্রমাণ না হলে কেবিলে হাত নয়।',
    art: '$_art/live_dead_live.svg',
    lessonPoint: 1,
  );
  static const needlessStop = DoMistake(
    key: 'm2/gate/needless-stop',
    textBn: 'রিডিং-এ ভোল্টেজ নেই — থামার কারণ নেই। লাইভ-মৃত-লাইভ মেপে, রিডিং দেখে তবে সিদ্ধান্ত।',
    art: '$_art/live_dead_live.svg',
    lessonPoint: 1,
  );
  static const skinToward = DoMistake(
    key: 'm2/gate/skin-toward',
    textBn: 'ছুরি নিজের দিকে টানবেন না — পেন্সিল ছোলার মতো শরীর থেকে বাইরের দিকে ঠেলে কাটুন।',
    art: '$_art/skin_away.svg',
    lessonPoint: 1,
  );
  static const lugMetal = DoMistake(
    key: 'm2/gate/lug-metal',
    textBn: 'অ্যালুমিনিয়াম তারে তামার ল্যাগ নয় — দুই ধাতু একসাথে গ্যালভানিক ক্ষয় ঘটায়।',
    art: '$_art/lug_match.svg',
    lessonPoint: 1,
  );
  static const lugSize = DoMistake(
    key: 'm2/gate/lug-size',
    textBn: 'তারের মাপের ল্যাগই নিন — ভুল মাপে ক্রিম্প হয় ঢিলা, নয়তো কন্ডাক্টর ক্ষতিগ্রস্ত।',
    art: '$_art/lug_match.svg',
    lessonPoint: 1,
  );
  static const crimpPliers = DoMistake(
    key: 'm2/gate/crimp-pliers',
    textBn: 'প্লায়ার্স দিয়ে ল্যাগ ক্রিম্প হয় না — সঠিক চাপ ও আকৃতির জন্য ঠিক ডাই-এর ক্রিম্পিং টুল চাই।',
    art: '$_art/crimp_die.svg',
    lessonPoint: 1,
  );
  static const wrongDie = DoMistake(
    key: 'm2/gate/wrong-die',
    textBn: 'কাছাকাছি সাইজের ডাই দিয়ে কাজ চলে না — ডাই সিলেকশন চার্ট মিলিয়ে ল্যাগের মাপের ডাই।',
    art: '$_art/crimp_die.svg',
    lessonPoint: 1,
  );
  static const underCrimp = DoMistake(
    key: 'm2/gate/under-crimp',
    textBn: 'অর্ধেক চাপে ক্রিম্প দুর্বল — প্রেসার রিলিজ ভাল্ভ "ক্লিক" না করা পর্যন্ত পাম্প করুন।',
    art: '$_art/crimp_full.svg',
    lessonPoint: 1,
  );
  static const megUndischarged = DoMistake(
    key: 'm2/gate/megger-undischarged',
    textBn: 'মেগারের লিড লাগানোর আগে কেবিল বিচ্ছিন্ন করে ভালোভাবে ডিসচার্জ করুন।',
    art: '$_art/megger_discharge.svg',
    lessonPoint: 1,
  );
  static const megVolt = DoMistake(
    key: 'm2/gate/megger-volt',
    textBn: 'অপারেটিং ভোল্টেজ অনুযায়ী টেস্ট ভোল্টেজ — 415V সিস্টেমের কেবিলে মেগার 500V-তে।',
    art: '$_art/megger_500.svg',
    lessonPoint: 1,
  );
  static const megAfter = DoMistake(
    key: 'm2/gate/megger-after',
    textBn: 'টেস্টের পর আবার ডিসচার্জ — মেগারের টেস্ট ভোল্টেজ কেবিলে চার্জ হয়ে জমে থাকে।',
    art: '$_art/megger_discharge.svg',
    lessonPoint: 2,
  );
  static const megSkip = DoMistake(
    key: 'm2/gate/megger-skip',
    textBn: 'মাল্টিমিটারের "ইনফিনিটি" ইনসুলেশনের আসল স্বাস্থ্য বলে না — কম ভোল্টেজ ফাটল বা আর্দ্রতা ধরে না। মেগার লাগবেই।',
    art: '$_art/megger_vs_mm.svg',
    lessonPoint: 0,
  );
  static const megLow = DoMistake(
    key: 'm2/gate/megger-low',
    textBn: 'IR 1 MΩ-এর কম মানে ইনসুলেশন দুর্বল বা আর্দ্র — এমন কেবিল চালু করা নিরাপদ নয়।',
    art: '$_art/megger_ir.svg',
    lessonPoint: 2,
  );
  static const megNeedless = DoMistake(
    key: 'm2/gate/megger-needless',
    textBn: 'IR 1 MΩ-এর অনেক বেশি — ইনসুলেশন ভালো। রিডিং পড়ে সিদ্ধান্ত; ভালো কেবিল আটকে রাখার কারণ নেই।',
    art: '$_art/megger_ir.svg',
    lessonPoint: 2,
  );
  static const phaseNoGloves = DoMistake(
    key: 'm2/gate/phase-no-gloves',
    textBn: 'ফেজ সিকোয়েন্স মাপা লাইভ টেস্ট — ইনসুলেটেড গ্লাভস ছাড়া প্রোব লাগানো সাক্ষাৎ মৃত্যু।',
    art: '$_art/phase_gloves.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const phaseLiveSwap = DoMistake(
    key: 'm2/gate/phase-live-swap',
    textBn: 'চালু লাইনে ফেজ বদলানো মারাত্মক — আগে বন্ধ করে, মৃত প্রমাণ করে তবেই দুটো ফেজ বদল।',
    art: '$_art/phase_swap.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const phaseIgnored = DoMistake(
    key: 'm2/gate/phase-ignored',
    textBn: 'মিটার উল্টো (R-B-Y) দেখালে চালু রাখা যায় না — যেকোনো দুটো ফেজ বদলে ক্রম ঠিক করুন।',
    art: '$_art/phase_rev.svg',
    lessonPoint: 2,
  );
  static const phaseNeedless = DoMistake(
    key: 'm2/gate/phase-needless',
    textBn: 'মিটার R-Y-B ঠিক দেখাচ্ছে — এখন দুটো ফেজ বদলালে ক্রমটাই উল্টে যাবে।',
    art: '$_art/phase_rev.svg',
    lessonPoint: 2,
  );
  static const careStick = DoMistake(
    key: 'm2/gate/care-stick',
    textBn: 'হট স্টিক মুছে শুকিয়ে ওয়াটারপ্রুফ ব্যাগে বা দেওয়ালে ঝুলিয়ে — মেঝেতে, ভেজা বা মালের নিচে চাপা নয়।',
    art: '$_art/care_stick.svg',
    lessonPoint: 3,
  );
  static const careMeter = DoMistake(
    key: 'm2/gate/care-meter',
    textBn: 'মাল্টিমিটার বন্ধ করে, লিড আলতো গুটিয়ে রাখুন — পেঁচানো লিড আর চালু যন্ত্রে ক্ষতি।',
    art: '$_art/care_meter.svg',
    lessonPoint: 2,
  );
  static const carePliers = DoMistake(
    key: 'm2/gate/care-pliers',
    textBn: 'ধাতব জয়েন্টে পাতলা তেল, ইনসুলেটেড হাতলে নয়; ভেজা বা নোংরা টুল বাক্সে নয়।',
    art: '$_art/care_pliers.svg',
    lessonPoint: 1,
  );

  static const careFloor = DoMistake(
    key: 'm2/gate/care-floor',
    textBn: 'প্রতিটা টুলের একটা নিজের ঘর আছে — ভ্যানের মেঝেতে ফেলে রাখলে টুল ভাঙে, হারায়।',
    art: '$_art/care_stick.svg',
    lessonPoint: 0,
  );

  static const all = [
    bambooStick,
    damagedTool,
    goodRejected,
    catTwo,
    doOnLoad,
    doUnder,
    doNoPpe,
    mmDial,
    mmOnHt,
    liveFirst,
    liveAfter,
    allPhases,
    deadCallLive,
    needlessStop,
    skinToward,
    lugMetal,
    lugSize,
    crimpPliers,
    wrongDie,
    underCrimp,
    megUndischarged,
    megVolt,
    megAfter,
    megSkip,
    megLow,
    megNeedless,
    phaseNoGloves,
    phaseLiveSwap,
    phaseIgnored,
    phaseNeedless,
    careStick,
    careMeter,
    carePliers,
    careFloor,
  ];

  /// The lesson that teaches each mistake ("পাঠে দেখুন" opens it, not 2.10).
  static const lessonOf = {
    'm2/gate/bamboo-stick': '2.5',
    'm2/gate/damaged-tool': '2.10',
    'm2/gate/good-rejected': '2.10',
    'm2/gate/cat-two': '2.2',
    'm2/gate/do-on-load': '2.5',
    'm2/gate/do-under': '2.5',
    'm2/gate/do-no-ppe': '2.5',
    'm2/gate/mm-dial': '2.2',
    'm2/gate/mm-on-ht': '2.2',
    'm2/gate/live-first': '2.1',
    'm2/gate/live-after': '2.1',
    'm2/gate/all-phases': '2.2',
    'm2/gate/dead-call-live': '2.2',
    'm2/gate/needless-stop': '2.2',
    'm2/gate/skin-toward': '2.6',
    'm2/gate/lug-metal': '2.3',
    'm2/gate/lug-size': '2.3',
    'm2/gate/crimp-pliers': '2.3',
    'm2/gate/wrong-die': '2.9',
    'm2/gate/under-crimp': '2.9',
    'm2/gate/megger-undischarged': '2.7',
    'm2/gate/megger-volt': '2.7',
    'm2/gate/megger-after': '2.7',
    'm2/gate/megger-skip': '2.7',
    'm2/gate/megger-low': '2.7',
    'm2/gate/megger-needless': '2.7',
    'm2/gate/phase-no-gloves': '2.8',
    'm2/gate/phase-live-swap': '2.8',
    'm2/gate/phase-ignored': '2.8',
    'm2/gate/phase-needless': '2.8',
    'm2/gate/care-stick': '2.5',
    'm2/gate/care-meter': '2.10',
    'm2/gate/care-pliers': '2.10',
    'm2/gate/care-floor': '2.10',
  };
}

abstract final class M2GateLines {
  static const title = 'জুনিয়রের ডকেট · র‍্যাঙ্ক গেট';
  static const intro =
      'জুনিয়রের ডকেট এলো! ট্রান্সফরমারের LT কেবিলের ল্যাগ পুড়ে গেছে। হাতিয়ার গুছিয়ে, নিরাপদে বিচ্ছিন্ন করে, নতুন ল্যাগ বসিয়ে লাইন চালু করুন — পারলেই জুনিয়র!';

  /// The task per station; a tap on the guide says the next wording.
  static const tasks = {
    M2GateStation.pack: [
      'ডকেটের হাতিয়ার ব্যাগে তুলুন। হাতে নিয়ে দেখে তবে নিন।',
      'প্রতিটা টুল পরখ করুন — কোনটা যাবে, কোনটা থাকবে।',
      'ব্যাগ গোছান। ডকেটের কাজে কী কী লাগবে?',
    ],
    M2GateStation.doOpen: [
      'ট্রান্সফরমার বিচ্ছিন্ন করুন — হট স্টিকে তিনটে DO খুলুন।',
      'তিনটে DO নামাতে হবে। নিরাপদে করুন।',
      'DO খোলার কাজ। তাড়াহুড়ো নয়।',
    ],
    M2GateStation.proveDead: [
      'এবার প্রমাণ করুন লাইন মৃত — মাল্টিমিটার নিন।',
      'মৃত প্রমাণ না করে কেবিলে হাত দেবেন না।',
      'মিটার দিয়ে মৃত প্রমাণ করুন, তারপর জানান।',
    ],
    M2GateStation.skinCrimp: [
      'পোড়া মাথা কাটা হয়েছে। কেবিল ছিলে নতুন ল্যাগ বসান।',
      'ইনসুলেশন ছিলুন, ল্যাগ বসিয়ে ক্রিম্প করুন।',
      'নিখুঁত স্কিনিং, নিখুঁত ক্রিম্প — হাত লাগান।',
    ],
    M2GateStation.megger: [
      'চালুর আগে কেবিলের ইনসুলেশন মেগারে মাপুন।',
      'কেবিলের স্বাস্থ্য পরীক্ষা — মেগার লাগান।',
      'আইআর ভ্যালু মেপে তবেই কেবিল চালু।',
    ],
    M2GateStation.phase: [
      'লাইন চালু হলো। নতুন সংযোগ — ফেজ সিকোয়েন্স মিলিয়ে নিন।',
      'ফেজের ক্রম দেখুন, তারপর সিদ্ধান্ত।',
      'মিটার লাগিয়ে ঘূর্ণনের দিক পড়ুন।',
    ],
    M2GateStation.toolCare: [
      'দিন শেষ। হাতিয়ারগুলো যত্ন করে গুছিয়ে রাখুন।',
      'প্রতিটা টুলের যত্ন — একটা একটা করে।',
      'কাল সকালে যেন সব তৈরি থাকে — গুছিয়ে নিন।',
    ],
  };

  static const stationTitles = {
    M2GateStation.pack: 'হাতিয়ার গোছানো',
    M2GateStation.doOpen: 'DO খোলা · হট স্টিক',
    M2GateStation.proveDead: 'মৃত প্রমাণ',
    M2GateStation.skinCrimp: 'স্কিনিং ও ক্রিম্পিং',
    M2GateStation.megger: 'মেগার টেস্ট',
    M2GateStation.phase: 'ফেজ সিকোয়েন্স',
    M2GateStation.toolCare: 'হাতিয়ারের যত্ন',
  };

  static const toolNames = {
    M2Tool.pliers: 'প্লায়ার্স',
    M2Tool.multimeter: 'মাল্টিমিটার',
    M2Tool.hotStick: 'হট স্টিক',
    M2Tool.skinKnife: 'স্কিনিং নাইফ',
    M2Tool.crimper: 'হাইড্রোলিক ক্রিম্পার',
    M2Tool.megger: 'মেগার',
    M2Tool.phaseMeter: 'ফেজ সিকোয়েন্স মিটার',
    M2Tool.bamboo: 'বাঁশের লাঠি',
  };

  static const pack = 'ব্যাগে নিন';
  static const closeDocket = 'বন্ধ করুন';
  static const reject = 'বাতিল করুন';
  static const packed = 'ব্যাগে';
  static const rejected = 'ব্যবহারের অযোগ্য';
  static const faceShield = 'ফেস শিল্ড';
  static const gloves = 'ইনসুলেটেড গ্লাভস';
  static const standFirst = 'হট স্টিক হাতে আগে জায়গা নিন।';
  static const knownLive = 'জানা লাইভ পয়েন্ট';
  static const provenDead = 'মৃত প্রমাণিত · কাজ চলবে';
  static const stopLive = 'ভোল্টেজ আছে · কাজ থামান';
  static const stoppedRight = 'ঠিক! কাজ থামালেন, খবর দিলেন। লাইন আবার বিচ্ছিন্ন করা হলো — এবার গোড়া থেকে আবার মাপুন।';
  static const pump = 'পাম্প করুন (চেপে ধরুন)';
  static const discharge = 'ডিসচার্জ';
  static const test = 'TEST (চেপে ধরুন)';
  static const leadsOff = 'লিড খুলুন';
  static const megOk = 'IR ঠিক আছে · চালু করা যাবে';
  static const megBad = 'IR কম · কেবিল চালু নয়';
  static const megReplaced = 'ঠিক! 1 MΩ-এর কম — এ কেবিল চালু নয়। দল কেবিলের টুকরোটা বদলে ল্যাগ বসাল — এবার নতুনটা মাপুন।';
  static const leadsFirst = 'আগে দুটো লিড লাগান।';
  static const testFirst = 'আগে পুরো এক মিনিট টেস্ট করুন।';
  static const holdLonger = 'পুরো এক মিনিট ধরে রাখুন।';
  static const phaseKeep = 'ঠিক আছে · চালু রাখুন';
  static const phaseSwapDead = 'বন্ধ করে দুটো ফেজ বদল';
  static const phaseSwapLive = 'চালু অবস্থাতেই ফেজ বদল';
  static const swappedDead = 'DO খুলে, মৃত প্রমাণ করে Y আর B বদলানো হলো। আবার চালু — মিটার দেখুন।';
  static const careNames = {M2Care.stick: 'হট স্টিক', M2Care.meter: 'মাল্টিমিটার', M2Care.pliers: 'প্লায়ার্স'};
  static const wipe = 'মুছুন (চেপে ধরুন)';
  static const oilCan = 'তেলের ক্যান';
  static const careSpots = {
    M2CareSpot.hooks: 'দেওয়ালের হুক',
    M2CareSpot.bag: 'ওয়াটারপ্রুফ ব্যাগ',
    M2CareSpot.toolbox: 'টুলবক্স',
    M2CareSpot.floor: 'ভ্যানের মেঝে',
  };

  static const praise = {
    M2GateStation.pack: 'ব্যাগ তৈরি! ক্ষতিগ্রস্ত টুল বাদ, ঠিক হাতিয়ার সঙ্গে।',
    M2GateStation.doOpen: 'তিনটে DO খোলা — নিরাপদ জায়গা থেকে, অফ-লোডে।',
    M2GateStation.proveDead: 'লাইভ-মৃত-লাইভ — লাইন মৃত প্রমাণিত!',
    M2GateStation.skinCrimp: 'নিখুঁত ষড়ভুজ ক্রিম্প! পুল টেস্টেও নড়ল না।',
    M2GateStation.megger: 'ইনসুলেশন ভালো, চার্জও নামানো — কেবিল তৈরি।',
    M2GateStation.phase: 'R-Y-B ঠিক — গ্রাহকের মোটর ঠিক দিকে ঘুরবে।',
  };

  // --- Reasons (one library per station, 2 right / 5 wrong) -----------------
  static const whyPackQ = 'কেন ক্ষতিগ্রস্ত টুলটা বাতিল করলেন?';
  static const whyPackRight = [
    'ইনসুলেশনে ফাটল মানে সুরক্ষার একটা স্তর নেই',
    'ক্ষতিগ্রস্ত টুল বাতিল করে অযোগ্য লেবেল দিই',
  ];
  static const whyPackWrong = [
    'গ্লাভস পরা থাকলে ফাটা টুলেও কিছু হয় না',
    'সামান্য ক্ষতি থাকলেও আজকের কাজটা চলে যেত',
    'টেপ জড়িয়ে নিলেই ফাটা হাতল নতুনের মতো',
    'দামি কোম্পানির টুল একটু ফাটলেও নিরাপদ',
    'শুকনো দিনে ফাটা টুলেও শক লাগার ভয় নেই',
  ];

  static const whyDoQ = 'কেন লোড বন্ধ করে, পাশে দাঁড়িয়ে DO খুললেন?';
  static const whyDoRight = [
    'DO আর্ক নেভাতে পারে না, পাশে থাকলে ফ্ল্যাশ গায়ে লাগে না',
    'অফ-লোডে বড় আর্ক হয় না, গলিত ধাতুও মুখে-শরীরে পড়ে না',
  ];
  static const whyDoWrong = [
    'ঠিক নিচে দাঁড়ালে ফিউজের রিং সবচেয়ে ভালো দেখা যায়',
    'হট স্টিক থাকলে কোথায় দাঁড়াই তাতে কিছু যায় আসে না',
    'লোড চালু রেখে খুললেও DO নিজেই আর্ক নিভিয়ে দেয়',
    'ফেস শিল্ড থাকলে ঠিক নিচে দাঁড়ালেও কোনো ভয় নেই',
    'জোরে ঝাঁকুনি দিয়ে টানলে ফিউজ তাড়াতাড়ি খুলে যায়',
  ];

  static const whyDeadQ = 'কেন মাপার আগে ও পরে জানা লাইভে মিটার ছোঁয়ালেন?';
  static const whyDeadRight = [
    'মিটার ঠিক আছে প্রমাণ না হলে শূন্য রিডিং ভরসা নয়',
    'আগে-পরে লাইভ মিললে মরা মিটারের ধোঁকা থাকে না',
  ];
  static const whyDeadWrong = [
    'শূন্য দেখালেই লাইন মৃত, মিটার যাচাই বাড়তি কাজ',
    'DO খোলা হয়ে গেছে, তাই আর মাপারই দরকার নেই',
    'লাইন টেস্টার না জ্বললে নিউট্রালও নিশ্চিত মৃত',
    'নতুন ব্যাটারি থাকলে মিটার কখনো ভুল দেখায় না',
    'একটা ফেজ মৃত হলে বাকি দুটোও মৃত ধরা যায়',
  ];

  static const whyLugQ = 'কেন এই ল্যাগ আর এই ডাই বেছে নিলেন?';
  static const whyLugRight = [
    'অ্যালুমিনিয়াম তারে অ্যালুমিনিয়াম ল্যাগ, মাপও এক',
    'তারের মাপ, ধাতু আর ডাই মিললে ঢিলা বা ক্ষয় হয় না',
  ];
  static const whyLugWrong = [
    'তামার ল্যাগ সবচেয়ে ভালো, যেকোনো তারেই চলে যায়',
    'একটু বড় ল্যাগ নিলে তারটা সহজে ভেতরে ঢুকে যায়',
    'ছোট ল্যাগে চেপে ঢোকালে সংযোগ আরও টাইট হয়',
    'ক্রিম্পের পর সোল্ডার দিলে যেকোনো ল্যাগই চলে',
    'কাছাকাছি সাইজের ডাই দিলেও ক্রিম্প ঠিকই হয়',
  ];

  static const whyMegQ = 'কেন মেগারের আগে আর পরে কেবিল ডিসচার্জ করলেন?';
  static const whyMegRight = [
    'জমা চার্জে রিডিং ভুল হয়, টেস্টের চার্জও কেবিলে থাকে',
    'মেগারের টেস্ট ভোল্টেজ কেবিলে চার্জ হয়ে জমে থাকে',
  ];
  static const whyMegWrong = [
    'মেগার ব্যাটারির যন্ত্র, কেবিলে কোনো চার্জ জমে না',
    'মাল্টিমিটারে ইনফিনিটি দেখালে মেগারই লাগে না',
    'ডিসচার্জ করলে আইআর রিডিং কমে খারাপ দেখায়',
    'পাঁচ হাজার ভোল্টে মাপলে তবেই আসল রিডিং আসে',
    'কেবিল বন্ধ থাকলে ডিসচার্জের কোনো মানে নেই',
  ];

  static const whyPhaseQ = 'কেন ফেজ সিকোয়েন্স মিলিয়ে তবেই লাইন চালু রাখলেন?';
  static const whyPhaseRight = [
    'নতুন সংযোগের পর ক্রম না মেলালে মোটর উল্টো ঘোরে',
    'R-Y-B ঠিক থাকলে গ্রাহকের পাম্প-মোটর নিরাপদ থাকে',
  ];
  static const whyPhaseWrong = [
    'তারের রং দেখেই ক্রম বোঝা যায়, মিটার বাড়তি জিনিস',
    'উল্টো ঘুরলে পরে গ্রাহক নিজেই তার বদলে নেবেন',
    'ছোট মোটর উল্টো ঘুরলে তাতে কোনো ক্ষতি হয় না',
    'চালু লাইনেই দুটো ফেজ বদলে নেওয়া সবচেয়ে দ্রুত',
    'দুটো ল্যাম্প জ্বেলে দেখাই সবচেয়ে নিরাপদ পদ্ধতি',
  ];

  // --- The careless coworker (station 5) ---------------------------------------
  static const coworker = CoworkerScript(
    line: 'আরে, মাল্টিমিটারে তো ইনফিনিটি দেখাচ্ছে! মেগার-টেগার ছাড়ো, লাগিয়ে চালু করে দাও।',
    exitLine: 'হুঁ! যত্তসব বই-পড়া নিয়ম।',
    right: [
      'না, মেগার ছাড়া কেবিল চালু করব না',
      'না, ইনফিনিটিতে ইনসুলেশন বোঝা যায় না',
      'না, আগে মেগারে আইআর মেপে তবে চালু',
    ],
    wrong: [
      'ঠিক, ইনফিনিটি মানেই ইনসুলেশন ভালো',
      'ঠিক আছে, মেগারটা আজকের মতো বাদ দিই',
      'সবাই তো মাল্টিমিটারেই কাজ সারে',
      'হ্যাঁ, তাড়াতাড়ি লাগিয়ে চালু করি',
    ],
    asks: [
      'ও বলছে মেগার লাগবে না। আপনি কী করবেন?',
      'মাল্টিমিটারের ইনফিনিটি — ভরসা করবেন?',
      'মেগার করবেন, না ওর কথা শুনবেন?',
    ],
  );
  static const coworkerHeld = 'ঠিক! মেগার ছাড়া চালু নয় — মাপ চালিয়ে যান।';

  static const allSet = 'অভিনন্দন! জুনিয়রের ডকেট নিখুঁত — আপনি এখন জুনিয়র লাইনম্যান, হাতিয়ারের ওস্তাদ!';
  static const fail = 'আরেকবার — সাতটা স্টেশনের প্রতিটা নিয়ম মেনে জুনিয়র র‍্যাঙ্ক জিতুন।';

  /// Every fixed line the guide says (for recording).
  static List<String> get recordable => [
        intro,
        for (final l in tasks.values) ...l,
        ...praise.values,
        standFirst,
        stoppedRight,
        megReplaced,
        leadsFirst,
        testFirst,
        holdLonger,
        swappedDead,
        whyPackQ,
        whyDoQ,
        whyDeadQ,
        whyLugQ,
        whyMegQ,
        whyPhaseQ,
        coworkerHeld,
        ...coworker.asks,
        allSet,
        fail,
      ];
}

// ============================================================================
// Rules (pure)
// ============================================================================

class M2GateRun {
  M2GateRun(this.seed) : _rng = math.Random(seed) {
    flaw = M2Flaw.values[_rng.nextInt(M2Flaw.values.length)];
    shelf = [...M2Tool.values]..shuffle(_rng);
    lugs = [...M2Lug.values]..shuffle(_rng);
    crimps = [...M2Crimp.values]..shuffle(_rng);
    phaseReversed = _rng.nextBool();
    // Dealt after the older draws so a seed keeps its shelf, lugs and phase.
    final live = _rng.nextInt(5) < 2;
    final livePhase = _rng.nextInt(3);
    liveLeft = live ? livePhase : null;
    liveVolts = 226 + _rng.nextInt(12);
    livePointVolts = 226 + _rng.nextInt(12);
    deadVolts = [for (var i = 0; i < 3; i++) _rng.nextInt(5) / 10];
    megLowFirst = _rng.nextInt(5) < 2;
    megLowValue = const [0.3, 0.4, 0.6, 0.8][_rng.nextInt(4)];
    megGoodValue = 120.0 + 10 * _rng.nextInt(80);
    deadCallsSwapped = _rng.nextBool();
    megCallsSwapped = _rng.nextBool();
    phaseCalls = [...M2PhaseCall.values]..shuffle(_rng);
  }

  final int seed;
  final math.Random _rng;

  late final M2Flaw flaw;
  late final List<M2Tool> shelf;
  late final List<M2Lug> lugs;
  late final List<M2Crimp> crimps;
  late final bool phaseReversed;

  /// Station 3: the phase (0 R, 1 Y, 2 B) that still shows voltage after the
  /// DO fuses are out, or null (the line is dead). Cleared once the player
  /// stops the work and the line is isolated again.
  int? liveLeft;
  late final int liveVolts;
  late final int livePointVolts;
  late final List<double> deadVolts;

  /// Station 5: the first IR reading is below 1 MΩ.
  late final bool megLowFirst;
  late final double megLowValue;
  late final double megGoodValue;

  /// The order of the two-way calls on screen (dealt, so the right one is not
  /// always in the same place).
  late final bool deadCallsSwapped;
  late final bool megCallsSwapped;
  late final List<M2PhaseCall> phaseCalls;

  static const docketTools = {
    M2Tool.pliers,
    M2Tool.multimeter,
    M2Tool.hotStick,
    M2Tool.skinKnife,
    M2Tool.crimper,
    M2Tool.megger,
    M2Tool.phaseMeter,
  };
  static const traps = {M2Tool.bamboo, M2Tool.flawed};

  M2GateStation station = M2GateStation.pack;
  final Set<M2GateStation> completed = {};
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => completed.length == M2GateStation.values.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// Listening to the careless coworker at station 5 (a slip).
  DoMistake? listenedToCoworker() => ended ? null : _slip(M2GateMistakes.megSkip);

  void advanceStation() {
    if (deadly != null) return;
    completed.add(station);
    final next = station.index + 1;
    if (next < M2GateStation.values.length) station = M2GateStation.values[next];
  }

  // 1. Pack ------------------------------------------------------------------
  final Set<M2Tool> packed = {};
  final Set<M2Tool> rejected = {};

  bool settled(M2Tool t) => packed.contains(t) || rejected.contains(t);

  /// Puts [t] in the bag. The bamboo stick is deadly; the damaged twin a slip
  /// (it stays on the shelf to be rejected).
  DoMistake? packTool(M2Tool t) {
    if (ended || settled(t)) return null;
    if (t == M2Tool.bamboo) return deadly = M2GateMistakes.bambooStick;
    if (t == M2Tool.flawed) return _slip(flaw == M2Flaw.catTwo ? M2GateMistakes.catTwo : M2GateMistakes.damagedTool);
    packed.add(t);
    return null;
  }

  /// Rejects [t]. A good docket tool is a slip (it stays on the shelf).
  DoMistake? rejectTool(M2Tool t) {
    if (ended || settled(t)) return null;
    if (!traps.contains(t)) return _slip(M2GateMistakes.goodRejected);
    rejected.add(t);
    tag(t == M2Tool.bamboo ? 'বাঁশের লাঠি বাতিল' : 'ক্ষতিগ্রস্ত টুল বাতিল');
    return null;
  }

  bool get packDone => packed.containsAll(docketTools) && rejected.containsAll(traps);

  // 2. DO --------------------------------------------------------------------
  var ltOn = true;
  var faceShield = false;
  var doGloves = false;
  M2Stance? stance;
  final List<bool> doOpen = [false, false, false];

  void switchLtOff() {
    if (ended || !ltOn) return;
    ltOn = false;
    tag('অফ-লোডে DO খোলা');
  }

  /// Pulls DO [i] with the hot stick (needs a stance).
  DoMistake? pullDo(int i) {
    if (ended || stance == null || doOpen[i]) return null;
    if (ltOn) return deadly = M2GateMistakes.doOnLoad;
    if (stance == M2Stance.under) return deadly = M2GateMistakes.doUnder;
    if (!faceShield || !doGloves) return _slip(M2GateMistakes.doNoPpe);
    doOpen[i] = true;
    if (doDone) tag('পাশে দাঁড়িয়ে হট স্টিকে DO');
    return null;
  }

  bool get doDone => doOpen.every((o) => o);

  // 3. Prove dead -------------------------------------------------------------
  M2Dial? dial;
  var liveBefore = false;
  var liveAfter = false;
  final Set<int> tested = {};
  var provenDead = false;

  /// A phase that still shows voltage has been read.
  bool get sawLive {
    final l = liveLeft;
    return l != null && tested.contains(l);
  }

  /// The known live point: before the phases it proves the meter; after all
  /// three it proves it again.
  DoMistake? probeLive() {
    if (ended) return null;
    if (dial != M2Dial.acV) return _slip(M2GateMistakes.mmDial);
    if (tested.length == 3) {
      liveAfter = true;
    } else {
      liveBefore = true;
    }
    return null;
  }

  /// Phase [i] (0 R, 1 Y, 2 B) to neutral.
  DoMistake? probePhase(int i) {
    if (ended) return null;
    if (dial != M2Dial.acV) return _slip(M2GateMistakes.mmDial);
    if (!liveBefore) return _slip(M2GateMistakes.liveFirst);
    tested.add(i);
    return null;
  }

  DoMistake? probeHt() => ended ? null : deadly = M2GateMistakes.mmOnHt;

  DoMistake? confirmDead() {
    if (ended || provenDead) return null;
    if (tested.length < 3) return _slip(M2GateMistakes.allPhases);
    if (sawLive) return _slip(M2GateMistakes.deadCallLive);
    if (!liveAfter) return _slip(M2GateMistakes.liveAfter);
    provenDead = true;
    tag('লাইভ-মৃত-লাইভ পরীক্ষা');
    return null;
  }

  /// "Voltage — stop the work": right only once a live phase has been read;
  /// the line is then isolated again and the test starts over.
  DoMistake? stopWork() {
    if (ended || provenDead) return null;
    if (!sawLive) return _slip(M2GateMistakes.needlessStop);
    liveLeft = null;
    tested.clear();
    liveBefore = false;
    liveAfter = false;
    tag('ফেজে ভোল্টেজ পেয়ে কাজ থামানো');
    return null;
  }

  /// What the display shows for a probe of the known live point / a phase.
  String readingLive() => '$livePointVolts V';
  String readingPhase(int i) => i == liveLeft ? '$liveVolts V' : '${deadVolts[i].toStringAsFixed(1)} V';
  static String readingNeutral() => '0.0 V';

  // 4. Skin and crimp ---------------------------------------------------------
  var skinned = false;
  M2Lug? lug;
  M2Crimp? crimpTool;
  var crimped = false;

  DoMistake? skin({required bool awayFromBody}) {
    if (ended || skinned) return null;
    if (!awayFromBody) return _slip(M2GateMistakes.skinToward);
    skinned = true;
    tag('শরীর থেকে বাইরে স্কিনিং');
    return null;
  }

  DoMistake? chooseLug(M2Lug l) {
    if (ended || !skinned || lug != null) return null;
    if (l == M2Lug.cu95) return _slip(M2GateMistakes.lugMetal);
    if (l != M2Lug.al95) return _slip(M2GateMistakes.lugSize);
    lug = l;
    return null;
  }

  DoMistake? chooseCrimp(M2Crimp c) {
    if (ended || lug == null || crimpTool != null) return null;
    if (c == M2Crimp.pliers) return _slip(M2GateMistakes.crimpPliers);
    if (c == M2Crimp.hyd70) return _slip(M2GateMistakes.wrongDie);
    crimpTool = c;
    return null;
  }

  DoMistake? crimp({required bool fullCycle}) {
    if (ended || crimpTool == null || crimped) return null;
    if (!fullCycle) return _slip(M2GateMistakes.underCrimp);
    crimped = true;
    tag('AL 95 ল্যাগ, পুরো চাপে ক্রিম্প');
    return null;
  }

  // 5. Megger -----------------------------------------------------------------
  var dischargedBefore = false;
  var lineLead = false;
  var earthLead = false;
  M2MegV? megV;
  var megTested = false;
  var dischargedAfter = false;
  var leadsOff = false;
  var cableReplaced = false;
  var megJudged = false;

  /// The cable under test reads below 1 MΩ.
  bool get megLow => megLowFirst && !cableReplaced;

  /// The IR value (MΩ) of the cable under test.
  double get megValue => megLow ? megLowValue : megGoodValue;

  void dischargeCable() {
    if (ended) return;
    if (megTested) {
      dischargedAfter = true;
    } else {
      dischargedBefore = true;
    }
  }

  DoMistake? clipLead({required bool line}) {
    if (ended || megTested) return null;
    if (!dischargedBefore) return _slip(M2GateMistakes.megUndischarged);
    line ? lineLead = true : earthLead = true;
    return null;
  }

  bool get leadsOn => lineLead && earthLead;

  /// The one-minute test (needs both leads).
  DoMistake? runMegger() {
    if (ended || !leadsOn || megTested) return null;
    if (megV != M2MegV.v500) return _slip(M2GateMistakes.megVolt);
    megTested = true;
    tag('500V-এ মেগার, আগে-পরে ডিসচার্জ');
    return null;
  }

  DoMistake? removeLeads() {
    if (ended || !megTested || leadsOff) return null;
    if (!dischargedAfter) return _slip(M2GateMistakes.megAfter);
    leadsOff = true;
    return null;
  }

  /// The call on the reading once the leads are off: [ok] = the cable may go
  /// on. Below 1 MΩ the cable stays off — the team replaces the piece and the
  /// test starts over.
  DoMistake? judgeMegger({required bool ok}) {
    if (ended || !leadsOff || megJudged) return null;
    if (ok && megLow) return _slip(M2GateMistakes.megLow);
    if (!ok && !megLow) return _slip(M2GateMistakes.megNeedless);
    if (!ok) {
      cableReplaced = true;
      dischargedBefore = false;
      lineLead = false;
      earthLead = false;
      megTested = false;
      dischargedAfter = false;
      leadsOff = false;
      tag('1 MΩ-এর কম — কেবিল চালু নয়');
      return null;
    }
    megJudged = true;
    return null;
  }

  /// [v] MΩ as the megger shows it.
  static String megText(double v) => v < 10 ? '${v.toStringAsFixed(1)} MΩ' : '${v.round()} MΩ';

  // 6. Phase sequence ------------------------------------------------------------
  var phaseGloves = false;
  final Set<int> clips = {};
  var swapped = false;
  var phaseDone = false;

  DoMistake? clipPhase(int i) {
    if (ended || clips.contains(i)) return null;
    if (!phaseGloves) return deadly = M2GateMistakes.phaseNoGloves;
    clips.add(i);
    return null;
  }

  /// The meter's reading once the three clips are on: true = R-Y-B.
  bool? get phaseFwd => clips.length < 3 ? null : !(phaseReversed && !swapped);

  DoMistake? decidePhase(M2PhaseCall call) {
    final fwd = phaseFwd;
    if (ended || fwd == null || phaseDone) return null;
    if (call == M2PhaseCall.swapLive) return deadly = M2GateMistakes.phaseLiveSwap;
    if (!fwd) {
      if (call == M2PhaseCall.keep) return _slip(M2GateMistakes.phaseIgnored);
      swapped = true;
      tag('উল্টো ক্রম বন্ধ করে ঠিক করা');
      return null;
    }
    if (call == M2PhaseCall.swapDead) return _slip(M2GateMistakes.phaseNeedless);
    phaseDone = true;
    tag('ফেজ সিকোয়েন্স R-Y-B যাচাই');
    return null;
  }

  // 7. Tool care (by hand) -------------------------------------------------------
  /// Put away right.
  final Set<M2Care> cared = {};

  /// The tool in the player's hand.
  M2Care? careHeld;
  final Set<M2Care> wiped = {};
  var meterOff = false;
  var pliersOiled = false;

  /// Picks [c] up off the bench (a tool already in hand goes back).
  void pickCare(M2Care c) {
    if (ended || cared.contains(c)) return;
    careHeld = c;
  }

  void wipeHeld() {
    final c = careHeld;
    if (ended || c == null) return;
    wiped.add(c);
  }

  void switchMeterOff() {
    if (ended || careHeld != M2Care.meter) return;
    meterOff = true;
  }

  /// Oil on the pliers in hand: the metal joint, or the insulated handle (a slip).
  DoMistake? oilPliers({required bool joint}) {
    if (ended || careHeld != M2Care.pliers || pliersOiled) return null;
    if (!joint) return _slip(M2GateMistakes.carePliers);
    pliersOiled = true;
    return null;
  }

  static DoMistake _careMistake(M2Care c) => switch (c) {
        M2Care.stick => M2GateMistakes.careStick,
        M2Care.meter => M2GateMistakes.careMeter,
        M2Care.pliers => M2GateMistakes.carePliers,
      };

  /// Puts the tool in hand at [spot]. A slip keeps it in hand.
  DoMistake? storeHeld(M2CareSpot spot) {
    final c = careHeld;
    if (ended || c == null) return null;
    if (spot == M2CareSpot.floor) return _slip(c == M2Care.stick ? M2GateMistakes.careStick : M2GateMistakes.careFloor);
    final ready = switch (c) {
      M2Care.stick => wiped.contains(c) && spot != M2CareSpot.toolbox,
      M2Care.meter => meterOff,
      M2Care.pliers => wiped.contains(c) && pliersOiled,
    };
    if (!ready) return _slip(_careMistake(c));
    cared.add(c);
    careHeld = null;
    if (careDone) tag('দিনের শেষে হাতিয়ারের যত্ন');
    return null;
  }

  bool get careDone => cared.length == M2Care.values.length;
}

// ============================================================================
// Page
// ============================================================================

class M2GateFieldPage extends StatefulWidget {
  const M2GateFieldPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M2GateFieldPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2GateFieldPage> createState() => _M2GateFieldPageState();
}

class _M2GateFieldPageState extends State<M2GateFieldPage> {
  var _round = 0;
  late bool _muted = widget.muted;
  late final int _base = widget.seed ?? DateTime.now().millisecondsSinceEpoch % 100000;

  @override
  Widget build(BuildContext context) => _M2GateRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        seed: _base + _round,
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _M2GateRunPage extends ConsumerStatefulWidget {
  const _M2GateRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.seed,
    required this.onRetry,
  });

  final LevelContext ctx;
  final M2GateFieldPack pack;
  final bool muted;
  final int seed;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_M2GateRunPage> createState() => _M2GateRunPageState();
}

class _M2GateRunPageState extends ConsumerState<_M2GateRunPage>
    with TickerProviderStateMixin, DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M2GateRun _run = M2GateRun(widget.seed);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _hints = IdleHintController();
  final _gk = <String, GlobalKey>{};

  int _runScore = 0;
  int _totalDelta = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _wake = 0;
  int _tapN = 0;
  var _docketOpen = false;

  final _combo = Combo();
  int _comboN = 0;
  int _comboMult = 1;

  var _freeze = false;
  Completer<void>? _frozen;
  var _bloomActive = false;
  int _bloomRound = 0;

  // Scene state.
  double _sceneH = 800;
  M2Tool? _inspect;
  Offset? _stickTo;
  Offset? _sparkAt;
  var _sparkBig = false;
  String _meterReading = '- - -';
  Offset? _probeAt;
  double _skinDrag = 0;
  double _pump = 0;
  Timer? _holdTimer;
  double _megProgress = 0;
  String _megReading = '- - -';
  double _wipe = 0;
  var _oilMode = false;
  final Map<M2Care, M2CareSpot> _stored = {};

  @override
  LevelContext get deathCtx => widget.ctx;

  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  /// A global key per control id (the gesture hint sweeps over them).
  GlobalKey _k(String id) => _gk.putIfAbsent(id, GlobalKey.new);

  @override
  void dispose() {
    _holdTimer?.cancel();
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // --- speech -----------------------------------------------------------------
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

  void _cue(String s, {double volume = 0.75}) {
    if (!_muted) unawaited(ZlFx.cue(s, volume: volume, muted: false));
  }

  Future<void> _start() async {
    // Guide first: no docket to dismiss, no start button — the play begins
    // when the intro ends (the docket opens from the station chip).
    setState(() => _intro = false);
    _clock.start();
    await _enterStation();
  }

  Future<void> _enterStation() async {
    if (!mounted) return;
    setState(() {
      _wake++;
      _tapN = 0;
      _meterReading = '- - -';
      _probeAt = null;
      _stickTo = null;
    });
    unawaited(_sayChain([M2GateLines.tasks[_run.station]!.first]));
    if (_run.station == M2GateStation.megger && !coworkerDone) scheduleCoworker();
  }

  void _tapGuide() {
    // Never over the coworker's beats or a deck's question.
    if (_intro || _ended || coworkerOpen || reasonOpen) return;
    final lines = M2GateLines.tasks[_run.station]!;
    _tapN++;
    _cue('sounds/learn/tick.ogg', volume: 0.5);
    final line = lines[_tapN % lines.length];
    ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.talk, line: line);
    unawaited(MascotSpeechLibrary.speak(line, muted: _muted));
  }

  /// The scene takes input: not in the praise window, a card, a deck, the
  /// coworker's beats, the death freeze or after the end.
  bool get _canAct =>
      !_busy &&
      !_ended &&
      !_freeze &&
      _run.deadly == null &&
      _card == null &&
      !tableBusy &&
      !reasonOpen &&
      !coworkerOpen &&
      !_intro &&
      !_docketOpen &&
      !struckOut;

  /// A deadly move: from this moment nothing else in the scene counts.
  void _lockForDeath() {
    _busy = true;
    _ended = true;
    _holdTimer?.cancel();
    _holdTimer = null;
    _oilMode = false;
    _hush();
  }

  // --- scoring ------------------------------------------------------------------
  int _scored(int base) {
    final (mult, up) = _combo.hit();
    if (up) {
      setState(() {
        _comboN++;
        _comboMult = _combo.mult;
      });
    }
    return base * mult;
  }

  Future<void> _pay(int base, Offset origin) async {
    final delta = _scored(base);
    _totalDelta += delta;
    setState(() => _runScore += delta);
    await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: GuideMood.celebrate, muted: _muted);
  }

  void _triggerBloom() {
    if (_bloomActive || !mounted) return;
    setState(() {
      _bloomActive = true;
      _bloomRound++;
    });
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _bloomActive = false);
    });
  }

  /// A station's last right move: ◆ wait on the table (paid only by the
  /// reason), praise, the reason deck.
  Future<void> _stationWon(Offset origin, String question, List<String> right, List<String> wrong, int salt) async {
    _busy = true;
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.7);
    putOnTable(_scored(20));
    final praise = M2GateLines.praise[_run.station];
    if (praise != null) await _say(praise, mood: GuideMood.celebrate);
    if (!mounted || _ended) return;
    _busy = false;
    await askReason(
      deal: () => dealChoices(right, wrong, math.Random(widget.seed + salt)),
      question: question,
      stillValid: () => mounted && !_ended,
    );
  }

  Future<void> _handleMistake(DoMistake m) async {
    if (!mounted) return;
    // Nothing but the death itself counts once a deadly move is made.
    if (!m.deadly && (_run.deadly != null || _freeze)) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    _combo.miss();
    _holdTimer?.cancel();
    _holdTimer = null;
    if (m.deadly) {
      _lockForDeath();
      final frozen = _frozen = Completer<void>();
      setState(() {
        _freeze = true;
        _inspect = null;
      });
      final outcome = await bookDeadly(m, runScore: _runScore);
      await frozen.future;
      if (!mounted) return;
      setState(() {
        _freeze = false;
        _card = m;
        _cardTone = outcome == DeadlyOutcome.nearMiss ? MistakeTone.nearMiss : MistakeTone.deadly;
      });
    } else {
      final out = strike(m);
      unawaited(bookMistake(ref, widget.ctx, m));
      setState(() {
        _card = m;
        _cardTone = MistakeTone.slip;
        _busy = false;
        _oilMode = false;
      });
      if (out) unawaited(recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore));
    }
  }

  /// Plays the spark of a deadly move (the scene is locked first).
  Future<void> _deathSpark(Offset at, {bool accident = true}) async {
    _lockForDeath();
    _cue('sounds/learn/spark.ogg', volume: 0.95);
    if (accident) _cue('sounds/accident.ogg', volume: 0.7);
    setState(() {
      _sparkAt = at;
      _sparkBig = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) setState(() => _sparkAt = null);
  }

  // --- ReasonTable hooks ----------------------------------------------------------
  @override
  bool get reasonMuted => _muted;

  @override
  bool get reasonEnded => _ended;

  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);

  @override
  void reasonHush() => _hush();

  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) async {
    _totalDelta += delta;
    setState(() => _runScore += delta);
    await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: mood, muted: _muted);
  }

  @override
  void onReasonPaid() {
    _run.advanceStation();
    _triggerBloom();
    unawaited(_enterStation());
  }

  // --- CoworkerMoment hooks -------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => M2GateLines.coworker;

  @override
  late final math.Random coworkerRng = math.Random(widget.seed * 7 + 3);

  @override
  bool get coworkerMuted => _muted;

  /// He pushes "skip the megger": only at station 5, before the test has run.
  @override
  bool? coworkerCanCome() {
    // A strike-out ends his moment too (slips never end the run itself).
    if (_ended || _run.ended || struckOut || _run.station != M2GateStation.megger || _run.megTested || _run.megJudged) return null;
    if (tableBusy || _busy || _freeze || _card != null || _holdTimer != null || _docketOpen || _inspect != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);

  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (held) {
      _run.tag('সহকর্মীর চাপে "না" বলা');
      _cue('sounds/quiz_right.ogg', volume: 0.7);
      setState(() => _wake++);
      unawaited(coworkerSnarl());
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await _say(M2GateLines.coworkerHeld, mood: GuideMood.glad);
    } else {
      // Listening is the slip (playbook beat 8); the megger is still to do.
      final m = _run.listenedToCoworker();
      if (m != null) await _handleMistake(m);
    }
  }

  // --- station 1: pack ------------------------------------------------------------
  void _onShelfTap(M2Tool t) {
    if (!_canAct || _run.settled(t)) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/card_deal_b.ogg', volume: 0.6);
    setState(() => _inspect = t);
  }

  Future<void> _onPack(bool pack, Offset origin) async {
    final t = _inspect;
    if (t == null || !_canAct) return;
    _hush();
    setState(() => _inspect = null);
    final m = pack ? _run.packTool(t) : _run.rejectTool(t);
    if (m != null) {
      if (m.deadly) await _deathSpark(const Offset(180, 220), accident: false);
      await _handleMistake(m);
      return;
    }
    _cue(pack ? 'sounds/intro/drop.ogg' : 'sounds/learn/tag_slap.ogg', volume: pack ? 0.7 : 0.8);
    setState(() => _wake++);
    if (_run.packDone) {
      await _stationWon(origin, M2GateLines.whyPackQ, M2GateLines.whyPackRight, M2GateLines.whyPackWrong, 11);
    }
  }

  // --- station 2: DO ----------------------------------------------------------------
  void _onLtSwitch() {
    if (!_canAct || !_run.ltOn) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.9);
    setState(() {
      _run.switchLtOff();
      _wake++;
    });
  }

  void _onWear({required bool shield}) {
    if (!_canAct) return;
    HapticFeedback.selectionClick();
    _cue('sounds/dress_right.ogg', volume: 0.6);
    setState(() {
      if (_run.station == M2GateStation.phase) {
        _run.phaseGloves = true;
      } else if (shield) {
        _run.faceShield = true;
      } else {
        _run.doGloves = true;
      }
      _wake++;
    });
  }

  void _onStand(M2Stance s) {
    if (!_canAct) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/stomp.ogg', volume: 0.4);
    setState(() {
      _run.stance = s;
      _wake++;
    });
  }

  Future<void> _onDo(int i, M2YardGeo geo, Offset origin) async {
    if (!_canAct || _run.doOpen[i]) return;
    if (_run.stance == null) {
      unawaited(_say(M2GateLines.standFirst));
      return;
    }
    _busy = true;
    _hush();
    setState(() {
      _stickTo = geo.doRing(i).translate(4, -32);
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 60 : 520));
    if (!mounted) return;
    final m = _run.pullDo(i);
    if (m != null) {
      if (m.deadly) await _deathSpark(geo.doRing(i).translate(0, -18));
      if (!mounted) return;
      setState(() => _stickTo = null);
      await _handleMistake(m);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/spark.ogg', volume: 0.5);
    setState(() {
      _sparkAt = geo.doRing(i).translate(0, -30);
      _sparkBig = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() {
      _sparkAt = null;
      _stickTo = null;
      _busy = false;
    });
    if (_run.doDone) {
      await _stationWon(origin, M2GateLines.whyDoQ, M2GateLines.whyDoRight, M2GateLines.whyDoWrong, 22);
    }
  }

  // --- station 3: prove dead ----------------------------------------------------------
  static String _dialFace(M2Dial d) => switch (d) {
        M2Dial.acV => '0.0 V',
        M2Dial.dcV => '0.0 V⎓',
        M2Dial.ohm => 'OL Ω',
        M2Dial.beep => 'OL',
      };

  void _onDial(M2Dial d) {
    if (!_canAct) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.8);
    setState(() {
      _run.dial = d;
      _meterReading = _dialFace(d);
    });
  }

  Future<void> _onProbe(Offset at, DoMistake? Function() act, String Function() reading) async {
    if (!_canAct) return;
    if (_run.dial == null) {
      unawaited(_say(M2GateLines.tasks[M2GateStation.proveDead]!.first));
      return;
    }
    _hush();
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    final m = act();
    if (m != null) {
      if (m.deadly) {
        setState(() => _probeAt = at);
        await _deathSpark(at);
      }
      await _handleMistake(m);
      return;
    }
    setState(() {
      _probeAt = at;
      _meterReading = reading();
    });
  }

  Future<void> _onDeadCall({required bool dead, required Offset origin}) async {
    if (!_canAct || _run.provenDead) return;
    _hush();
    final m = dead ? _run.confirmDead() : _run.stopWork();
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    if (dead) {
      await _stationWon(origin, M2GateLines.whyDeadQ, M2GateLines.whyDeadRight, M2GateLines.whyDeadWrong, 33);
      return;
    }
    // Stopped on a live reading: the line is isolated again; test it again.
    _busy = true;
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() {
      _probeAt = null;
      _meterReading = _run.dial == null ? '- - -' : _dialFace(_run.dial!);
      _wake++;
    });
    await _say(M2GateLines.stoppedRight, mood: GuideMood.glad);
    if (mounted) setState(() => _busy = false);
  }

  // --- station 4: skin & crimp --------------------------------------------------------
  Future<void> _onSkinEnd(Offset origin) async {
    final dx = _skinDrag;
    _skinDrag = 0;
    if (!_canAct || _run.skinned || dx.abs() < 24) return;
    _hush();
    final m = _run.skin(awayFromBody: dx > 0);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.7);
    setState(() => _wake++);
    await _pay(5, origin);
  }

  Future<void> _onLug(M2Lug l, Offset origin) async {
    if (!_canAct) return;
    _hush();
    final m = _run.chooseLug(l);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() => _wake++);
  }

  Future<void> _onCrimpTool(M2Crimp c, Offset origin) async {
    if (!_canAct) return;
    _hush();
    final m = _run.chooseCrimp(c);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() => _wake++);
  }

  void _holdStart(void Function() tick) {
    if (!_canAct || _holdTimer != null) return;
    _hush();
    _hints.hide();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) return;
      tick();
    });
  }

  void _pumpTick() {
    setState(() => _pump = math.min(1, _pump + 0.045));
    if ((_pump * 100).round() % 18 == 0) _cue('sounds/learn/tock.ogg', volume: 0.4);
    if (_pump >= 1) {
      _holdTimer?.cancel();
      _holdTimer = null;
      unawaited(_crimpDone(true));
    }
  }

  Future<void> _pumpRelease() async {
    final t = _holdTimer;
    if (t == null) return;
    t.cancel();
    _holdTimer = null;
    if (_pump < 1) {
      final early = _pump > 0.12;
      setState(() => _pump = 0);
      if (early) await _crimpDone(false);
    }
  }

  Future<void> _crimpDone(bool full) async {
    final m = _run.crimp(fullCycle: full);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    if (!full || !mounted) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/click.ogg', volume: 1);
    final size = MediaQuery.sizeOf(context);
    await _stationWon(Offset(size.width / 2, size.height * 0.55), M2GateLines.whyLugQ, M2GateLines.whyLugRight, M2GateLines.whyLugWrong, 44);
  }

  // --- station 5: megger -------------------------------------------------------------
  Future<void> _onDischarge(Offset origin, M2CableGeo geo) async {
    if (!_canAct) return;
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 0.6);
    setState(() {
      _run.dischargeCable();
      _sparkAt = Offset(geo.endX, geo.y);
      _sparkBig = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _sparkAt = null);
  }

  Future<void> _onLead({required bool line}) async {
    if (!_canAct) return;
    _hush();
    final m = _run.clipLead(line: line);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  void _onMegV(M2MegV v) {
    if (!_canAct || _run.megTested) return;
    _cue('sounds/intro/tick.ogg', volume: 0.8);
    setState(() => _run.megV = v);
  }

  void _testStart() {
    if (!_canAct || _run.megTested) return;
    // The coworker's push is about this test: he comes before it can run.
    if (holdForCoworker()) return;
    if (!_run.leadsOn) {
      unawaited(_say(M2GateLines.leadsFirst));
      return;
    }
    if (_run.megV != M2MegV.v500) {
      // Pressing TEST on the wrong voltage is the slip.
      _hush();
      final m = _run.runMegger();
      if (m != null) unawaited(_handleMistake(m));
      return;
    }
    final target = _run.megValue;
    _holdStart(() {
      setState(() {
        _megProgress = math.min(1, _megProgress + 0.03);
        _megReading = M2GateRun.megText(target * (0.2 + 0.8 * _megProgress));
      });
      if (_megProgress >= 1) {
        _holdTimer?.cancel();
        _holdTimer = null;
        _run.runMegger();
        // A neutral tick: the reading, not the sound, tells good from bad.
        _cue('sounds/learn/tock.ogg', volume: 0.6);
        setState(() => _megReading = M2GateRun.megText(target));
      }
    });
  }

  void _testRelease() {
    final t = _holdTimer;
    if (t == null) return;
    t.cancel();
    _holdTimer = null;
    if (!_run.megTested) {
      setState(() {
        _megProgress = 0;
        _megReading = '- - -';
      });
      unawaited(_say(M2GateLines.holdLonger));
    }
  }

  Future<void> _onLeadsOff(Offset origin) async {
    if (!_canAct || _run.leadsOff) return;
    if (!_run.megTested) {
      unawaited(_say(M2GateLines.testFirst));
      return;
    }
    _hush();
    final m = _run.removeLeads();
    if (m != null) {
      _cue('sounds/learn/spark.ogg', volume: 0.7);
      await _handleMistake(m);
      return;
    }
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  Future<void> _onMegCall({required bool ok, required Offset origin}) async {
    if (!_canAct || !_run.leadsOff || _run.megJudged) return;
    _hush();
    final m = _run.judgeMegger(ok: ok);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    if (ok) {
      await _stationWon(origin, M2GateLines.whyMegQ, M2GateLines.whyMegRight, M2GateLines.whyMegWrong, 55);
      return;
    }
    // Below 1 MΩ: the cable stays off; the team replaces it; test again.
    _busy = true;
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() {
      _megProgress = 0;
      _megReading = '- - -';
      _wake++;
    });
    await _say(M2GateLines.megReplaced, mood: GuideMood.glad);
    if (mounted) setState(() => _busy = false);
  }

  // --- station 6: phase ---------------------------------------------------------------
  Future<void> _onClip(int i, Offset at) async {
    if (!_canAct || _run.phaseDone) return;
    _hush();
    final m = _run.clipPhase(i);
    if (m != null) {
      if (m.deadly) await _deathSpark(at);
      await _handleMistake(m);
      return;
    }
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  Future<void> _onPhaseCall(M2PhaseCall c, Offset origin) async {
    if (!_canAct) return;
    _hush();
    final wasFwd = _run.phaseFwd;
    final m = _run.decidePhase(c);
    if (m != null) {
      if (m.deadly) await _deathSpark(M2TermGeo(_sceneH).term(1));
      await _handleMistake(m);
      return;
    }
    if (wasFwd == false) {
      _busy = true;
      _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
      setState(() => _wake++);
      await _say(M2GateLines.swappedDead);
      if (mounted) setState(() => _busy = false);
      return;
    }
    await _stationWon(origin, M2GateLines.whyPhaseQ, M2GateLines.whyPhaseRight, M2GateLines.whyPhaseWrong, 66);
  }

  // --- station 7: tool care (by hand) ---------------------------------------------------
  void _onCareTool(M2Care c) {
    if (!_canAct || _run.cared.contains(c) || _holdTimer != null) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    setState(() {
      _run.pickCare(c);
      _oilMode = false;
      _wipe = 0;
      _wake++;
    });
  }

  void _wipeTick() {
    setState(() => _wipe = math.min(1, _wipe + 0.06));
    if (_wipe >= 1) {
      _holdTimer?.cancel();
      _holdTimer = null;
      _cue('sounds/learn/card_deal_b.ogg', volume: 0.6);
      setState(() {
        _run.wipeHeld();
        _wipe = 0;
        _wake++;
      });
    }
  }

  void _wipeRelease() {
    final t = _holdTimer;
    if (t == null) return;
    t.cancel();
    _holdTimer = null;
    if (_wipe < 1) setState(() => _wipe = 0);
  }

  void _onMeterSwitch() {
    if (!_canAct || _run.careHeld != M2Care.meter || _run.meterOff) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.8);
    setState(() {
      _run.switchMeterOff();
      _wake++;
    });
  }

  void _onOilCan() {
    if (!_canAct || _run.careHeld != M2Care.pliers || _run.pliersOiled) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tock.ogg', volume: 0.5);
    setState(() => _oilMode = !_oilMode);
  }

  Future<void> _onOilAt({required bool joint}) async {
    if (!_canAct || !_oilMode) return;
    _hush();
    setState(() => _oilMode = false);
    final m = _run.oilPliers(joint: joint);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _cue('sounds/learn/tock.ogg', volume: 0.6);
    setState(() => _wake++);
  }

  Future<void> _onStore(M2CareSpot spot, Offset origin) async {
    final c = _run.careHeld;
    if (!_canAct || c == null || _holdTimer != null) return;
    _hush();
    final m = _run.storeHeld(spot);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _busy = true;
    _cue('sounds/intro/drop.ogg', volume: 0.7);
    setState(() {
      _stored[c] = spot;
      _oilMode = false;
      _wake++;
    });
    await _pay(10, origin);
    if (!mounted) return;
    setState(() => _busy = false);
    if (_run.careDone) {
      _run.advanceStation();
      _triggerBloom();
      await _finish();
    }
  }

  // --- end ---------------------------------------------------------------------
  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    final ms = _clock.elapsedMilliseconds;
    final mark = _run.percent;
    final passed = _run.passed;
    final quick = passed && ms <= widget.pack.quickMs && _run.slips == 0;
    final stars = starsFor(passed: passed, strikes: _run.slips, quick: quick);

    if (quick) {
      // The "ঝটপট ও নির্ভুল" bonus the pass panel shows is paid before saving.
      final size = MediaQuery.sizeOf(context);
      _totalDelta += 10;
      setState(() => _runScore += 10);
      await BeatFx.levelDelta(ref, 10, originGlobal: Offset(size.width / 2, size.height * 0.45), mood: GuideMood.celebrate, muted: _muted);
      if (!mounted) return;
    }
    final save = ref.read(gameSaveProvider.notifier);
    await save.recordLevelResult(widget.ctx.rungId, mark);
    final delta = await save.commitLevelScore(widget.ctx.rungId, _runScore);
    if (passed) {
      await save.markRungCleared(widget.ctx.rungId);
      await save.unlockRank(2); // Promotes to Junior (জুনিয়র, rank 2).
      await save.recordBestTime(widget.ctx.rungId, ms);
    }
    if (stars > 0) await save.recordStars(widget.ctx.rungId, stars);
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _stars = stars;
      _quickBonus = quick;
      if (delta > 0) _totalDelta = delta;
    });
    if (passed) {
      _cue('sounds/level_done.ogg', volume: 0.85);
      await _say(M2GateLines.allSet, mood: GuideMood.celebrate);
    } else {
      _cue('sounds/learn/level_fail.ogg', volume: 0.7);
      await _say(M2GateLines.fail, mood: GuideMood.warn);
    }
  }

  void _dismissCard() {
    if (_card == null) return;
    final tone = _cardTone;
    setState(() => _card = null);
    if (tone == MistakeTone.deadly) {
      unawaited(dieAndLeave());
    } else if (tone == MistakeTone.nearMiss) {
      widget.onRetry(_muted);
    }
  }

  Future<void> _leave() async {
    _hush();
    if (deathPending) {
      await dieAndLeave();
      return;
    }
    if (_runScore > 0 && !_ended) {
      final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
      if (leave != true || !mounted) return;
    }
    _popOnce(false);
  }

  void _popOnce(bool passed) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(passed);
  }

  // ============================================================================
  // Gesture hint (how to touch, never what)
  // ============================================================================

  /// The control ids open now: a sweep passes over all of them alike; a hold
  /// or tap hint only where there is one way forward.
  HintSpec? _hint() {
    if (!_canAct || _holdTimer != null) return null;
    final ids = <String>[];
    switch (_run.station) {
      case M2GateStation.pack:
        if (_inspect != null) {
          ids.addAll(['reject', 'pack']);
        } else {
          ids.addAll([for (final t in _run.shelf) if (!_run.settled(t)) 'shelf-${t.name}']);
        }
      case M2GateStation.doOpen:
        ids.addAll([
          if (_run.ltOn) 'lt-switch',
          if (!_run.faceShield) 'wear-shield',
          if (!_run.doGloves) 'wear-gloves',
          for (final s in M2Stance.values) 'stand-${s.name}',
          for (var i = 0; i < 3; i++) if (!_run.doOpen[i]) 'do-$i',
        ]);
      case M2GateStation.proveDead:
        if (_run.dial == null) {
          ids.addAll([for (final d in M2Dial.values) 'dial-${d.name}']);
        } else {
          ids.addAll(['live-point', 'ht', for (var i = 0; i < 4; i++) 'term-$i', 'call-dead', 'call-stop']);
        }
      case M2GateStation.skinCrimp:
        if (!_run.skinned) {
          // A short generic nudge: the knife can be dragged (never which way).
          return HintSpec.dragFrom(_k('skin-hit'), toward: const Offset(0, -1), travel: 40);
        }
        if (_run.lug == null) {
          ids.addAll([for (final l in _run.lugs) 'lug-${l.name}']);
        } else if (_run.crimpTool == null) {
          ids.addAll([for (final c in _run.crimps) 'crimp-${c.name}']);
        } else {
          return HintSpec.holdOn(_k('pump'));
        }
      case M2GateStation.megger:
        if (_run.leadsOff) {
          ids.addAll(['meg-ok', 'meg-bad']);
        } else {
          ids.addAll(['discharge', 'leads-off', 'test', 'lead-line', 'lead-earth', for (final v in M2MegV.values) 'megv-${v.name}']);
        }
      case M2GateStation.phase:
        if (_run.phaseFwd == null) {
          ids.addAll([if (!_run.phaseGloves) 'wear-gloves', for (var i = 0; i < 3; i++) if (!_run.clips.contains(i)) 'clip-$i']);
        } else {
          ids.addAll([for (final c in _run.phaseCalls) 'call-${c.name}']);
        }
      case M2GateStation.toolCare:
        final held = _run.careHeld;
        if (held == null) {
          ids.addAll([for (final c in M2Care.values) if (!_run.cared.contains(c)) 'care-${c.name}']);
        } else if (_oilMode) {
          ids.addAll(['oil-joint', 'oil-handle']);
        } else {
          ids.addAll([
            'wipe',
            if (held == M2Care.meter && !_run.meterOff) 'meter-switch',
            if (held == M2Care.pliers && !_run.pliersOiled) 'oil-can',
            for (final s in M2CareSpot.values) 'spot-${s.name}',
          ]);
        }
    }
    final keys = [for (final id in ids) _k(id)];
    if (keys.isEmpty) return null;
    return keys.length == 1 ? HintSpec.tapOn(keys.single) : HintSpec.sweepOver(keys);
  }

  String get _hintKey => [
        _run.station.index,
        _inspect?.name,
        _run.packed.length + _run.rejected.length,
        _run.dial?.name,
        _run.tested.length,
        _run.skinned,
        _run.lug?.name,
        _run.crimpTool?.name,
        _run.leadsOff,
        _run.cableReplaced,
        _run.phaseFwd,
        _run.careHeld?.name,
        _oilMode,
        _run.cared.length,
        _run.slips,
        coworkerDone,
      ].join('|');

  // ============================================================================
  // Scene layers (design pixels, 360 × m.height)
  // ============================================================================

  List<Widget> _layers(BuildContext context, SceneMetrics m) {
    final quiet = _quiet;
    final h = m.height;
    final out = switch (_run.station) {
      M2GateStation.pack => _packLayers(h, quiet),
      M2GateStation.doOpen => _doLayers(h, quiet),
      M2GateStation.proveDead => _deadLayers(h, quiet),
      M2GateStation.skinCrimp => _cableLayers(h, quiet, megger: false),
      M2GateStation.megger => _cableLayers(h, quiet, megger: true),
      M2GateStation.phase => _phaseLayers(h, quiet),
      M2GateStation.toolCare => _careLayers(h, quiet),
    };
    final spark = _sparkAt;
    return [
      ...out,
      if (spark != null)
        Positioned.fill(
          key: const ValueKey('spark'),
          child: IgnorePointer(child: CustomPaint(painter: M2SparkPainter(at: spark, big: _sparkBig))),
        ),
    ];
  }

  Widget _figure(Rect r, LinemanMode mode, {Key? key}) => Positioned.fromRect(
        key: key ?? const ValueKey('worker'),
        rect: r,
        child: IgnorePointer(child: LinemanFigure(look: LinemanLook.trainee, mode: mode, wake: _wake, quiet: _quiet)),
      );

  Widget _hit(String id, Rect r, VoidCallback onTap, {Widget? child}) => Positioned.fromRect(
        key: ValueKey(id),
        rect: r,
        child: GestureDetector(key: _k(id), behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
      );

  Widget _hitAt(String id, Rect r, void Function(Offset global) onTap, {Widget? child}) => Positioned.fromRect(
        key: ValueKey(id),
        rect: r,
        child: GestureDetector(key: _k(id), behavior: HitTestBehavior.opaque, onTapUp: (d) => onTap(d.globalPosition), child: child),
      );

  List<Widget> _packLayers(double h, bool quiet) {
    final benchY = h - 210;
    return [
      Positioned.fill(
        key: const ValueKey('bench'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M2BenchPainter(benchY: benchY)))),
      ),
      for (var i = 0; i < _run.shelf.length; i++)
        _hit(
          'shelf-${_run.shelf[i].name}',
          Rect.fromLTWH(12.0 + (i % 3) * 114, 124.0 + (i ~/ 3) * 96, 108, 88),
          () => _onShelfTap(_run.shelf[i]),
          child: _ShelfCard(
            // On the shelf the damaged twin looks like its good twin; the
            // flaw shows only when it is picked up and looked at.
            tool: _run.shelf[i] == M2Tool.flawed ? _run.flaw.twin : _run.shelf[i],
            flaw: null,
            packed: _run.packed.contains(_run.shelf[i]),
            rejected: _run.rejected.contains(_run.shelf[i]),
          ),
        ),
      _figure(Rect.fromLTWH(14, benchY - 64, 62, 124), _run.packed.isEmpty ? LinemanMode.idle : LinemanMode.hold),
    ];
  }

  List<Widget> _doLayers(double h, bool quiet) {
    final g = M2YardGeo(h);
    final foot = switch (_run.stance) {
      M2Stance.under => g.underSpot,
      M2Stance.side => g.sideSpot,
      null => Offset(g.sideSpot.dx - 40, g.groundY),
    };
    final stickTo = _stickTo ?? (_run.stance == null ? null : g.handsAt(foot).translate(26, -120));
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M2YardPainter(geo: g, doOpen: [..._run.doOpen], ltOn: _run.ltOn)))),
      ),
      for (final s in M2Stance.values)
        _hit(
          'stand-${s.name}',
          Rect.fromCenter(center: (s == M2Stance.under ? g.underSpot : g.sideSpot).translate(0, 10), width: 64, height: 34),
          () => _onStand(s),
          child: const _SpotMark(),
        ),
      if (stickTo != null)
        Positioned.fill(
          key: const ValueKey('stick'),
          child: IgnorePointer(child: CustomPaint(painter: M2StickPainter(from: g.handsAt(foot), to: stickTo))),
        ),
      _figure(g.figureAt(foot), _run.stance == null ? LinemanMode.idle : LinemanMode.hold),
      if (_run.faceShield || _run.doGloves)
        Positioned(
          key: const ValueKey('ppe-badge'),
          left: g.figureAt(foot).left - 4,
          top: g.figureAt(foot).top - 22,
          child: _PpeBadge(shield: _run.faceShield, gloves: _run.doGloves),
        ),
      _hit('lt-switch', g.ltBox.inflate(10), _onLtSwitch),
      for (var i = 0; i < 3; i++)
        _hitAt('do-$i', Rect.fromLTWH(g.doX(i) - 17, g.doTopY - 12, 34, g.doLen + 28), (p) => unawaited(_onDo(i, g, p))),
    ];
  }

  List<Widget> _deadLayers(double h, bool quiet) {
    final g = M2TermGeo(h);
    final meter = Rect.fromLTWH(14, g.box.bottom + 12, 96, 136);
    final probe = _probeAt;
    return [
      Positioned.fill(
        key: const ValueKey('terminals'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M2TerminalPainter(geo: g)))),
      ),
      Positioned(
        key: const ValueKey('live-tag'),
        left: g.liveHit.left - 6,
        top: g.liveHit.bottom + 4,
        width: g.liveHit.width + 12,
        child: IgnorePointer(
          child: Text(M2GateLines.knownLive, textAlign: TextAlign.center, style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
        ),
      ),
      if (probe != null)
        Positioned.fill(
          key: const ValueKey('probe-leads'),
          child: IgnorePointer(child: CustomPaint(painter: _LeadsPainter(from: meter.topCenter, to: probe))),
        ),
      Positioned.fromRect(
        key: const ValueKey('meter'),
        rect: meter,
        child: IgnorePointer(child: CustomPaint(painter: M2MultimeterPainter(dial: _run.dial, reading: _meterReading))),
      ),
      for (var i = 0; i < M2Dial.values.length; i++)
        _hit(
          'dial-${M2Dial.values[i].name}',
          Rect.fromCenter(
            center: meter.topLeft + Offset(M2MultimeterPainter.markAt(i).dx * meter.width / 120, M2MultimeterPainter.markAt(i).dy * meter.height / 170),
            width: 30,
            height: 26,
          ),
          () => _onDial(M2Dial.values[i]),
        ),
      _hit('live-point', g.liveHit, () => unawaited(_onProbe(g.liveHit.center, _run.probeLive, _run.readingLive))),
      _hit('ht', g.htHit, () => unawaited(_onProbe(g.htHit.center, _run.probeHt, () => ''))),
      for (var i = 0; i < 3; i++)
        _hit('term-$i', g.termHit(i), () => unawaited(_onProbe(g.term(i), () => _run.probePhase(i), () => _run.readingPhase(i)))),
      _hit('term-3', g.termHit(3), () => unawaited(_onProbe(g.term(3), () => null, M2GateRun.readingNeutral))),
    ];
  }

  List<Widget> _cableLayers(double h, bool quiet, {required bool megger}) {
    _sceneH = h;
    final benchY = h - 400;
    final g = M2CableGeo(benchY);
    final megRect = Rect.fromLTWH(196, benchY - 150, 150, 120);
    return [
      Positioned.fill(
        key: const ValueKey('bench'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M2BenchPainter(benchY: benchY)))),
      ),
      Positioned.fill(
        key: const ValueKey('cable'),
        child: IgnorePointer(
          child: CustomPaint(
            painter: M2CablePainter(
              geo: g,
              skin: _run.skinned ? 1 : 0,
              lug: _run.lug,
              crimped: _run.crimped,
              line: megger && _run.lineLead && !_run.leadsOff,
              earth: megger && _run.earthLead && !_run.leadsOff,
            ),
          ),
        ),
      ),
      _figure(Rect.fromLTWH(4, benchY - 70, 64, 128), LinemanMode.hold),
      if (!megger && !_run.skinned)
        Positioned.fromRect(
          key: const ValueKey('skin-hit'),
          rect: g.insulationHit,
          child: GestureDetector(
            key: _k('skin-hit'),
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _skinDrag = 0,
            onPanUpdate: (d) => _skinDrag += d.delta.dx,
            onPanEnd: (_) => unawaited(_onSkinEnd(Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height / 2))),
            child: const _KnifeMark(),
          ),
        ),
      if (megger) ...[
        Positioned.fromRect(
          key: const ValueKey('megger'),
          rect: megRect,
          child: IgnorePointer(child: CustomPaint(painter: M2MeggerPainter(volt: _run.megV, reading: _megReading, progress: _megProgress))),
        ),
        for (var i = 0; i < M2MegV.values.length; i++)
          _hit(
            'megv-${M2MegV.values[i].name}',
            Rect.fromCenter(center: megRect.topLeft + M2MeggerPainter.markAt(i), width: 34, height: 26),
            () => _onMegV(M2MegV.values[i]),
          ),
        _hit('lead-line', g.conductorHit, () => unawaited(_onLead(line: true))),
        _hit('lead-earth', g.armourHit, () => unawaited(_onLead(line: false))),
      ],
    ];
  }

  List<Widget> _phaseLayers(double h, bool quiet) {
    _sceneH = h;
    final g = M2TermGeo(h);
    final meter = Rect.fromLTWH(14, g.box.bottom + 14, 110, 100);
    return [
      Positioned.fill(
        key: const ValueKey('terminals'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M2TerminalPainter(geo: g, clips: {..._run.clips}, live: true)))),
      ),
      if (_run.clips.isNotEmpty)
        Positioned.fill(
          key: const ValueKey('phase-leads'),
          child: IgnorePointer(
            child: CustomPaint(painter: _LeadsPainter(from: meter.topCenter, to: g.term(_run.clips.last), many: [for (final c in _run.clips) g.term(c)])),
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('phase-meter'),
        rect: meter,
        child: IgnorePointer(child: CustomPaint(painter: M2PhaseMeterPainter(fwd: _run.phaseFwd))),
      ),
      if (_run.phaseGloves)
        Positioned(
          key: const ValueKey('ppe-badge'),
          left: meter.right + 8,
          top: meter.top + 8,
          child: const _PpeBadge(shield: false, gloves: true),
        ),
      for (var i = 0; i < 3; i++) _hitAt('clip-$i', g.termHit(i), (_) => unawaited(_onClip(i, g.term(i)))),
    ];
  }

  static const _careTools = {M2Care.stick: M2Tool.hotStick, M2Care.meter: M2Tool.multimeter, M2Care.pliers: M2Tool.pliers};

  List<Widget> _careLayers(double h, bool quiet) {
    final g = M2CareGeo(h);
    final held = _run.careHeld;
    final spots = {M2CareSpot.hooks: g.hooks, M2CareSpot.bag: g.bag, M2CareSpot.toolbox: g.toolbox, M2CareSpot.floor: g.floor};
    final byCount = <M2CareSpot, int>{};
    final hand = g.hand;
    // The pliers in hand, as M2ToolPainter fits them (100 × 60 units).
    final s = math.min((hand.width - 16) / 100, (hand.height - 16) / 60);
    final p0 = Offset(hand.left + 8 + (hand.width - 16 - 100 * s) / 2, hand.top + 8 + (hand.height - 16 - 60 * s) / 2);
    Rect unit(double l, double t, double r, double b) => Rect.fromLTRB(p0.dx + l * s, p0.dy + t * s, p0.dx + r * s, p0.dy + b * s);
    return [
      Positioned.fill(
        key: const ValueKey('care-bay'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M2CareBayPainter(geo: g)))),
      ),
      for (final e in spots.entries)
        _hitAt('spot-${e.key.name}', e.value, (p) => unawaited(_onStore(e.key, p)),
            child: Semantics(label: M2GateLines.careSpots[e.key], excludeSemantics: true, child: const SizedBox.expand())),
      for (final e in _stored.entries)
        Positioned.fromRect(
          key: ValueKey('stored-${e.key.name}'),
          rect: g.storedAt(spots[e.value]!, byCount[e.value] = (byCount[e.value] ?? -1) + 1),
          child: IgnorePointer(child: CustomPaint(painter: M2ToolPainter(_careTools[e.key]!))),
        ),
      for (final c in M2Care.values)
        if (!_run.cared.contains(c) && held != c)
          _hit(
            'care-${c.name}',
            g.slot(c.index),
            () => _onCareTool(c),
            child: _ShelfCard(
              tool: _careTools[c]!,
              flaw: null,
              packed: false,
              rejected: false,
              dirty: !_run.wiped.contains(c),
              name: M2GateLines.careNames[c],
            ),
          ),
      if (held != null) ...[
        Positioned.fromRect(
          key: const ValueKey('care-hand'),
          rect: hand,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xCC0F1A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6), width: 1.4),
              ),
              child: CustomPaint(size: Size.infinite, painter: M2ToolPainter(_careTools[held]!, dirty: !_run.wiped.contains(held))),
            ),
          ),
        ),
        if (held == M2Care.meter)
          _hit(
            'meter-switch',
            Rect.fromLTWH(hand.right - 72, hand.top + 10, 60, 36),
            _onMeterSwitch,
            child: _PowerSwitch(on: !_run.meterOff),
          ),
        if (held == M2Care.pliers && _oilMode) ...[
          // Two plain zones over the picture: the metal (jaws and joint) and
          // the insulated handles. Nothing marks either.
          _hitAt('oil-joint', unit(4, 10, 50, 50), (_) => unawaited(_onOilAt(joint: true))),
          _hitAt('oil-handle', unit(50, 10, 98, 50), (_) => unawaited(_onOilAt(joint: false))),
        ],
      ],
      _figure(Rect.fromLTWH(4, g.floor.top - 56, 56, 112), _run.careDone ? LinemanMode.cheer : (held == null ? LinemanMode.idle : LinemanMode.hold)),
    ];
  }

  // ============================================================================
  // Controls (screen pixels, page overlays)
  // ============================================================================

  Widget _kid(String id, Widget child) => KeyedSubtree(key: _k(id), child: child);

  List<Widget> _controls(EdgeInsets pad) {
    final b = pad.bottom + 12;
    Widget row(String key, List<Widget> kids) => Positioned(
          key: ValueKey(key),
          left: 12,
          right: 12,
          bottom: b,
          child: Row(children: [for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: kids[i])]]),
        );
    Widget stack(String key, List<Widget> kids) => Positioned(
          key: ValueKey(key),
          left: 130,
          right: 12,
          bottom: b,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(height: 6), kids[i]]],
          ),
        );
    switch (_run.station) {
      case M2GateStation.pack:
        return const [];
      case M2GateStation.doOpen:
        return [
          Positioned(
            key: const ValueKey('ppe-row'),
            left: 12,
            bottom: b,
            child: Row(
              children: [
                _kid('wear-shield', _ToolButton(icon: Icons.face_retouching_natural, label: M2GateLines.faceShield, on: _run.faceShield, onTap: () => _onWear(shield: true))),
                const SizedBox(width: 8),
                _kid('wear-gloves', _ToolButton(icon: Icons.back_hand_rounded, label: M2GateLines.gloves, on: _run.doGloves, onTap: () => _onWear(shield: false))),
              ],
            ),
          ),
        ];
      case M2GateStation.proveDead:
        final dead = _kid('call-dead', _ActionButton(key: const ValueKey('dead-call'), label: M2GateLines.provenDead, onTapUp: (p) => unawaited(_onDeadCall(dead: true, origin: p))));
        final stop = _kid('call-stop', _ActionButton(key: const ValueKey('stop-call'), label: M2GateLines.stopLive, onTapUp: (p) => unawaited(_onDeadCall(dead: false, origin: p))));
        return [stack('dead-row', _run.deadCallsSwapped ? [stop, dead] : [dead, stop])];
      case M2GateStation.skinCrimp:
        if (!_run.skinned) return const [];
        if (_run.lug == null) {
          return [
            row('lug-row', [
              for (final l in _run.lugs) _kid('lug-${l.name}', _ActionButton(label: l.stamp, mono: true, onTapUp: (p) => unawaited(_onLug(l, p)))),
            ]),
          ];
        }
        if (_run.crimpTool == null) {
          return [
            row('crimp-row', [
              for (final c in _run.crimps)
                _kid(
                  'crimp-${c.name}',
                  _ActionButton(
                    label: switch (c) {
                      M2Crimp.hyd95 => 'হাইড্রোলিক · ডাই 95',
                      M2Crimp.hyd70 => 'হাইড্রোলিক · ডাই 70',
                      M2Crimp.pliers => 'প্লায়ার্সে চাপ',
                    },
                    onTapUp: (p) => unawaited(_onCrimpTool(c, p)),
                  ),
                ),
            ]),
          ];
        }
        return [
          Positioned(
            key: const ValueKey('pump-row'),
            left: 12,
            right: 130,
            bottom: b,
            child: Row(
              children: [
                SizedBox(width: 56, height: 56, child: CustomPaint(painter: M2GaugePainter(p: _pump))),
                const SizedBox(width: 8),
                Expanded(
                  child: _kid(
                    'pump',
                    _HoldButton(
                      key: const ValueKey('pump'),
                      label: M2GateLines.pump,
                      onDown: () => _holdStart(_pumpTick),
                      onUp: () => unawaited(_pumpRelease()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      case M2GateStation.megger:
        if (_run.leadsOff) {
          final ok = _kid('meg-ok', _ActionButton(key: const ValueKey('meg-ok-btn'), label: M2GateLines.megOk, onTapUp: (p) => unawaited(_onMegCall(ok: true, origin: p))));
          final bad = _kid('meg-bad', _ActionButton(key: const ValueKey('meg-bad-btn'), label: M2GateLines.megBad, onTapUp: (p) => unawaited(_onMegCall(ok: false, origin: p))));
          return [stack('meg-call-row', _run.megCallsSwapped ? [bad, ok] : [ok, bad])];
        }
        final g = M2CableGeo(_sceneH - 400);
        return [
          Positioned(
            key: const ValueKey('meg-row'),
            left: 12,
            right: 130,
            bottom: b,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _kid('discharge', _ActionButton(label: M2GateLines.discharge, onTapUp: (p) => unawaited(_onDischarge(p, g))))),
                    const SizedBox(width: 8),
                    Expanded(child: _kid('leads-off', _ActionButton(label: M2GateLines.leadsOff, onTapUp: (p) => unawaited(_onLeadsOff(p))))),
                  ],
                ),
                const SizedBox(height: 8),
                _kid('test', _HoldButton(key: const ValueKey('test'), label: M2GateLines.test, onDown: _testStart, onUp: _testRelease)),
              ],
            ),
          ),
        ];
      case M2GateStation.phase:
        final fwd = _run.phaseFwd;
        return [
          if (fwd == null)
            Positioned(
              key: const ValueKey('gloves-row'),
              left: 12,
              bottom: b,
              child: _kid('wear-gloves', _ToolButton(icon: Icons.back_hand_rounded, label: M2GateLines.gloves, on: _run.phaseGloves, onTap: () => _onWear(shield: false))),
            )
          else
            Positioned(
              key: const ValueKey('phase-row'),
              left: 12,
              right: 130,
              bottom: b,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in _run.phaseCalls) ...[
                    _kid(
                      'call-${c.name}',
                      _ActionButton(
                        key: ValueKey('call-${c.name}'),
                        label: switch (c) {
                          M2PhaseCall.keep => M2GateLines.phaseKeep,
                          M2PhaseCall.swapDead => M2GateLines.phaseSwapDead,
                          M2PhaseCall.swapLive => M2GateLines.phaseSwapLive,
                        },
                        onTapUp: (p) => unawaited(_onPhaseCall(c, p)),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
        ];
      case M2GateStation.toolCare:
        final held = _run.careHeld;
        if (held == null) return const [];
        return [
          Positioned(
            key: const ValueKey('care-row'),
            left: 12,
            right: 130,
            bottom: b,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (held == M2Care.pliers) ...[
                  _kid(
                    'oil-can',
                    _ToolButton(key: const ValueKey('oil-can-btn'), icon: Icons.opacity_rounded, label: M2GateLines.oilCan, on: _run.pliersOiled, lit: _oilMode, onTap: _onOilCan),
                  ),
                  const SizedBox(width: 8),
                ],
                SizedBox(width: 48, height: 48, child: CustomPaint(painter: M2GaugePainter(p: _wipe))),
                const SizedBox(width: 8),
                Expanded(
                  child: _kid('wipe', _HoldButton(key: const ValueKey('wipe'), label: M2GateLines.wipe, onDown: () => _holdStart(_wipeTick), onUp: _wipeRelease)),
                ),
              ],
            ),
          ),
        ];
    }
  }

  double _guideBottom(EdgeInsets pad, bool deckUp) {
    if (deckUp) return pad.bottom + 236;
    return pad.bottom + switch (_run.station) {
          M2GateStation.proveDead => 130,
          M2GateStation.megger => 128,
          M2GateStation.phase => _run.phaseFwd == null ? 72 : 180,
          M2GateStation.toolCare => _run.careHeld == null ? 72 : 100,
          _ => 72,
        };
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut && _card == null;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !_docketOpen;
    final inspect = _inspect;

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
              labels: [for (final s in M2GateStation.values) M2GateLines.stationTitles[s]!],
              done: {for (final s in _run.completed) s.index},
              current: _run.done ? null : _run.station.index,
              quiet: quiet,
            ),
            hint: _hint,
            hintWaiting: handsOn && _canAct && _holdTimer == null && !coworkerOnScreen,
            hintKey: _hintKey,
            hintController: _hints,
            layers: (c, m) => [
              Positioned.fill(
                key: const ValueKey('scene'),
                child: ColorFiltered(
                  colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                  child: GestureDetector(
                    // A tap that lands on nothing counts towards the hint.
                    behavior: HitTestBehavior.translucent,
                    onTap: _hints.missTap,
                    child: Stack(children: _layers(c, m)),
                  ),
                ),
              ),
            ],
            overlays: [
              if (_freeze)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2200,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_bloomActive)
                Positioned.fill(
                  key: const ValueKey('bloom'),
                  child: IgnorePointer(child: RescueBurst(key: ValueKey('bloom-$_bloomRound'), muted: _muted, cloud: false)),
                ),
              if (_comboN > 0)
                Positioned(
                  key: const ValueKey('combo'),
                  top: pad.top + 92,
                  left: 0,
                  right: 0,
                  child: Center(child: ComboPop(key: ValueKey('combo-$_comboN'), mult: _comboMult)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 130), quiet: quiet),
              if (playing)
                Positioned(
                  key: const ValueKey('station-chip'),
                  top: pad.top + 86,
                  right: 12,
                  child: _StationChip(
                    num: 'স্টেশন ${_run.station.index + 1}/7',
                    title: M2GateLines.stationTitles[_run.station]!,
                    onDocket: () {
                      if (!_canAct) return;
                      _cue('sounds/learn/card_deal_a.ogg', volume: 0.8);
                      setState(() => _docketOpen = true);
                    },
                  ),
                ),
              if (handsOn) ..._controls(pad),
              if (handsOn && inspect != null)
                Positioned.fill(
                  key: const ValueKey('inspect'),
                  child: _InspectSheet(
                    tool: inspect,
                    flaw: _run.flaw,
                    rejectKey: _k('reject'),
                    packKey: _k('pack'),
                    onPack: (p) => unawaited(_onPack(true, p)),
                    onReject: (p) => unawaited(_onPack(false, p)),
                    onClose: () {
                      if (_canAct) setState(() => _inspect = null);
                    },
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
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing) cornerGuide(onTap: _tapGuide, bottom: _guideBottom(pad, deckUp), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () => unawaited(
                            openLessonPoint(
                              context,
                              ref,
                              lessonId: M2GateMistakes.lessonOf[_card!.key] ?? widget.ctx.lessonId,
                              point: _card!.lessonPoint,
                              muted: _muted,
                            ),
                          ),
                  onGo: _dismissCard,
                ),
              if (struckOut && _card == null)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy ?? M2GateMistakes.damagedTool,
                  lessonId: M2GateMistakes.lessonOf[strikeOutBy?.key] ?? widget.ctx.lessonId,
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xE6050A16),
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _run.passed
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _RankStamp(),
                                    const SizedBox(height: 14),
                                    LevelPassPanel(
                                      mark: _mark!,
                                      levelScore: _runScore,
                                      totalDelta: _totalDelta,
                                      ms: _clock.elapsedMilliseconds,
                                      caughtBn: _run.caught,
                                      quickBonus: _quickBonus,
                                      stars: _stars,
                                      onNext: () => _popOnce(true),
                                      onRetry: () => widget.onRetry(_muted),
                                    ),
                                  ],
                                )
                              : LevelFailPanel(
                                  percent: _mark!,
                                  muted: _muted,
                                  onRetry: () => widget.onRetry(_muted),
                                  onLeave: () => _popOnce(false),
                                  onRead: () => unawaited(
                                    openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M2GateLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
                  muted: _muted,
                  onDone: () => unawaited(_start()),
                ),
              if (_docketOpen && !_intro)
                Positioned.fill(
                  key: const ValueKey('docket-modal'),
                  child: _DocketSheet(
                    onClose: () {
                      _cue('sounds/learn/card_deal_a.ogg', volume: 0.8);
                      setState(() => _docketOpen = false);
                    },
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
// Small widgets
// ============================================================================

/// Probe / clip leads from the meter to the point(s) touched.
class _LeadsPainter extends CustomPainter {
  const _LeadsPainter({required this.from, required this.to, this.many = const []});
  final Offset from;
  final Offset to;
  final List<Offset> many;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = [Color(0xFFD7312B), Color(0xFFF2C40F), Color(0xFF2A62C9)];
    final targets = many.isEmpty ? [to] : many;
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      canvas.drawPath(
        Path()
          ..moveTo(from.dx + i * 6, from.dy)
          ..quadraticBezierTo((from.dx + t.dx) / 2, math.max(from.dy, t.dy) + 40, t.dx, t.dy),
        Paint()
          ..color = many.isEmpty ? cols[0] : cols[i % 3]
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(t, 4, Paint()..color = many.isEmpty ? cols[0] : cols[i % 3]);
    }
  }

  @override
  bool shouldRepaint(_LeadsPainter old) => old.to != to || old.from != from || old.many.length != many.length;
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({
    required this.tool,
    required this.flaw,
    required this.packed,
    required this.rejected,
    this.dirty = false,
    this.name,
  });

  final M2Tool tool;
  final M2Flaw? flaw;
  final bool packed;
  final bool rejected;
  final bool dirty;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final label = name ?? M2GateLines.toolNames[tool == M2Tool.flawed ? flaw!.twin : tool]!;
    return Opacity(
      opacity: packed ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xCC0F1A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: packed ? const Color(0xFF41C463) : (rejected ? SlmColors.danger : SlmColors.gold400.withValues(alpha: 0.5)),
            width: 1.4,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: CustomPaint(size: Size.infinite, painter: M2ToolPainter(tool, flaw: flaw, dirty: dirty))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ),
              ],
            ),
            if (packed) const Positioned(right: 0, top: 0, child: Icon(Icons.check_circle_rounded, color: Color(0xFF41C463), size: 20)),
            if (rejected)
              Positioned(
                left: 0,
                right: 0,
                top: 22,
                child: Transform.rotate(
                  angle: -0.18,
                  child: Container(
                    color: SlmColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(M2GateLines.rejected, textAlign: TextAlign.center, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tool picked up off the shelf, large enough to see its state.
class _InspectSheet extends StatelessWidget {
  const _InspectSheet({
    required this.tool,
    required this.flaw,
    required this.rejectKey,
    required this.packKey,
    required this.onPack,
    required this.onReject,
    required this.onClose,
  });

  final M2Tool tool;
  final M2Flaw flaw;
  final GlobalKey rejectKey;
  final GlobalKey packKey;
  final ValueChanged<Offset> onPack;
  final ValueChanged<Offset> onReject;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final label = M2GateLines.toolNames[tool == M2Tool.flawed ? flaw.twin : tool]!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        color: const Color(0xB3050A16),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2638),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.7), width: 1.6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                  const SizedBox(height: 8),
                  SizedBox(height: 170, width: double.infinity, child: CustomPaint(painter: M2ToolPainter(tool, flaw: flaw))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: KeyedSubtree(key: rejectKey, child: _ActionButton(key: const ValueKey('reject'), label: M2GateLines.reject, onTapUp: onReject)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: KeyedSubtree(key: packKey, child: _ActionButton(key: const ValueKey('pack'), label: M2GateLines.pack, onTapUp: onPack)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotMark extends StatelessWidget {
  const _SpotMark();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 52,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0x33FFFFFF),
            border: Border.all(color: const Color(0x99FFFFFF), width: 1.4),
          ),
        ),
      );
}

class _KnifeMark extends StatelessWidget {
  const _KnifeMark();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment(0.1, -0.9),
        child: SizedBox(width: 44, height: 22, child: CustomPaint(painter: M2ToolPainter(M2Tool.skinKnife))),
      );
}

class _PpeBadge extends StatelessWidget {
  const _PpeBadge({required this.shield, required this.gloves});
  final bool shield;
  final bool gloves;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xE60A1324), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shield) const Icon(Icons.face_retouching_natural, size: 14, color: SlmColors.gold300),
              if (shield && gloves) const SizedBox(width: 4),
              if (gloves) const Icon(Icons.back_hand_rounded, size: 14, color: Color(0xFFFF8A65)),
            ],
          ),
        ),
      );
}

class _StationChip extends StatelessWidget {
  const _StationChip({required this.num, required this.title, required this.onDocket});
  final String num;
  final String title;
  final VoidCallback onDocket;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE60A1324),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.65), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(enDigits(num), style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: Colors.white24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDocket,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_rounded, size: 14, color: SlmColors.gold300),
                  const SizedBox(width: 4),
                  Text('ডকেট', style: bangla(fontSize: 11, fontWeight: FontWeight.bold, color: SlmColors.gold300)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.lit = false});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  /// In use right now (the oil can raised).
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on ? null : onTap,
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? const Color(0xFF1E5A33) : (lit ? const Color(0xFF6B5310) : const Color(0xFF14233A)),
                  border: Border.all(color: on ? const Color(0xFF41C463) : SlmColors.gold300, width: 1.8),
                ),
                child: Icon(on ? Icons.check_rounded : icon, size: 26, color: on ? const Color(0xFF9BE7B0) : SlmColors.gold300),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({super.key, required this.label, required this.onTapUp, this.mono = false});
  final String label;
  final ValueChanged<Offset> onTapUp;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTapUp(d.globalPosition),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.gold400, width: 1.6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: mono
                ? const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory, letterSpacing: 0.5)
                : bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory),
          ),
        ),
      ),
    );
  }
}

/// A press-and-hold control (crimper pump, megger TEST).
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.label, required this.onDown, required this.onUp});
  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFC62828), Color(0xFF8E1B1B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SlmColors.gold300, width: 1.6),
          ),
          child: Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }
}

/// The multimeter's power switch in the tool-care close-up.
class _PowerSwitch extends StatelessWidget {
  const _PowerSwitch({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: on ? 'ON' : 'OFF',
        excludeSemantics: true,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2F36),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SlmColors.gold300, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? const Color(0xFFFFC928) : const Color(0xFF4A4F57))),
              const SizedBox(width: 6),
              Text(on ? 'ON' : 'OFF', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      );
}

class _RankStamp extends StatelessWidget {
  const _RankStamp();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SlmColors.gold300, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_rounded, color: SlmColors.gold300),
            const SizedBox(width: 8),
            Flexible(
              child: Text('নতুন র‍্যাঙ্ক: জুনিয়র · হাতিয়ারের ওস্তাদ', style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ),
          ],
        ),
      );
}

class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.onClose});
  final VoidCallback onClose;

  static const _rows = [
    (Icons.place_rounded, 'সাইট', 'ট্রান্সফরমার DTR-17 · বটতলা হাট', Color(0xFF1565C0)),
    (Icons.warning_rounded, 'ফল্ট', 'LT কেবিলের ল্যাগ পুড়ে গেছে (95 বর্গমিমি অ্যালুমিনিয়াম)', Color(0xFFC62828)),
    (Icons.power_off_rounded, 'শাটডাউন', 'সেকশনের লিখিত অনুমতি · হট স্টিকে তিনটে DO খুলে বিচ্ছিন্ন', Color(0xFFE65100)),
    (Icons.handyman_rounded, 'হাতিয়ার', 'VDE প্লায়ার্স, মাল্টিমিটার, হট স্টিক, স্কিনিং নাইফ, হাইড্রোলিক ক্রিম্পার, মেগার, ফেজ সিকোয়েন্স মিটার', Color(0xFF2E7D32)),
    (Icons.verified_user_rounded, 'সুরক্ষা', 'মৃত প্রমাণ না করে কেবিলে হাত নয় · চালুর আগে মেগার ও ফেজ সিকোয়েন্স', Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC4BBA5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(color: Color(0xFF1B3A57), borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: SlmColors.gold300, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('জুনিয়রের ডকেট', style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text('ডকেট নং: DKT-LT-2210 · শাটডাউন কাজ', style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: SlmColors.gold300)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final r in _rows)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(r.$1, size: 16, color: r.$4),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: '${r.$2}: ', style: const TextStyle(fontWeight: FontWeight.w900)),
                                      TextSpan(text: r.$3),
                                    ],
                                  ),
                                  style: bangla(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50), height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          label: Text(M2GateLines.closeDocket, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A57),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
