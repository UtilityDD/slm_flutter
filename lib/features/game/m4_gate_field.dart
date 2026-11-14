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
import 'm4_gate_field_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;

// Module 4 Rank Gate (rung m4/gate, pack gate_m4): "স্কিলডের ডকেট".
// One maintenance day on one feeder that uses the whole of Module 4
// (lessons 4.1–4.10), in nine stations:
//   1 DO খোলা — LT switch OFF (off-load), face shield + insulated gloves,
//     stand to the side, pull the three DO fuses with the hot stick (4.4).
//   2 তেল ও তাপ — read the conservator's glass gauge (MIN/MAX), take the
//     temperature with the IR thermometer from a distance (never a hand on
//     the tank); oil below MIN → report to the supervisor; never engine oil (4.5).
//   3 আর্থ টেস্ট — two spikes (fall of potential), test, too high → water
//     in the pit and the rusty clamp cleaned and tightened, test again (4.6).
//   4 ইনসুলেটর বদল — the 11 kV section under PTW: portable earths on both
//     sides, then binding off → conductor on a rope → old insulator off →
//     new one on and bound (4.1). The careless coworker pushes "skip the earths".
//   5 জাম্পার টাইট — find the hot clamp, wire-brush + paste, two wrenches (4.2).
//   6 ডিপি ড্রেসিং — top to bottom: jumper off the cross-arm, binding tail
//     cut, LT cables bunched; every nut tight (4.7).
//   7 ডাল ছাঁটা — cordon below, rope on the branch, three cuts in order,
//     never topping (4.8).
//   8 স্ট্রিট লাইট — MCB off, tester shows 0 V, new lamp, MCB on (4.9).
//   9 ফেজ ব্যালেন্স — tong tester on R, Y, B and N; under shutdown move a
//     service line from the heaviest to the lightest phase; measure again (4.10).
// Passing awards the Skilled ("স্কিলড") rank (unlockRank(4)) and the
// "কাজের কারিগর" badge of Module 4.

// ============================================================================
// Content
// ============================================================================

@immutable
class M4GateFieldPack {
  const M4GateFieldPack({required this.id, required this.titleBn, this.quickMs = 300000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m4GateFieldPacks = {
  'gate_m4': M4GateFieldPack(id: 'gate_m4', titleBn: M4GateLines.title),
};

enum M4GateStation { doOpen, oilTemp, earth, insulator, jumper, dpDress, tree, streetLight, balance }

enum M4GateStance { under, side }

enum M4OilCall { normal, report, engineOil }

enum M4InsStep { unbind, rope, removeOld, fitNew }

enum M4JumperAct { brush, twoWrench, oneWrench }

enum M4Cut { under, top, finish, topping }

enum M4BalCall { shiftDead, wrongWay, shiftLive, liveBack }

const _art = 'assets/game/art/m4_gate_field';
const _m2Art = 'assets/game/art/m2_gate_field';

abstract final class M4GateMistakes {
  static const doOnLoad = DoMistake(
    key: '4.4/m4_gate_field/do-on-load',
    textBn: 'লোড চালু রেখে DO খোলা মারাত্মক — বড় আর্ক, আর্ক ফ্ল্যাশে অন্ধত্ব বা মৃত্যু। আগে LT সুইচ বন্ধ করে অফ-লোড করুন।',
    art: '$_m2Art/do_load.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const doUnder = DoMistake(
    key: '4.4/m4_gate_field/do-under',
    textBn: 'ফিউজের ঠিক নিচে বা সামনে দাঁড়িয়ে টানবেন না — ফিউজ যেন পাশে বা কোণাকুণি থাকে, মুখ একপাশে সরিয়ে দ্রুত টান দিন।',
    art: '$_m2Art/do_stance.svg',
    lessonPoint: 2,
  );
  static const doNoPpe = DoMistake(
    key: '4.4/m4_gate_field/do-no-ppe',
    textBn: 'DO চালাতে ফেস শিল্ড আর ইনসুলেটেড গ্লাভস বাধ্যতামূলক — ফেস শিল্ডই আর্কের ফ্ল্যাশ থেকে চোখ-মুখ বাঁচায়।',
    art: '$_m2Art/do_ppe.svg',
    lessonPoint: 0,
  );
  static const touchTank = DoMistake(
    key: '4.5/m4_gate_field/touch-tank',
    textBn: 'তাপ মাপতে ট্যাঙ্কে হাত দেবেন না — দূর থেকে ইনফ্রারেড থার্মোমিটারে মাপুন।',
    art: '$_art/ir_not_hand.svg',
    lessonPoint: 1,
  );
  static const engineOil = DoMistake(
    key: '4.5/m4_gate_field/engine-oil',
    textBn: 'ট্রান্সফরমারে গাড়ির ইঞ্জিন অয়েল নয় — শুধু ফিল্টার করা খাঁটি মিনারেল অয়েল, লাইন বন্ধ করে, নিয়ম মেনে।',
    art: '$_art/oil_mineral.svg',
    lessonPoint: 2,
  );
  static const oilIgnored = DoMistake(
    key: '4.5/m4_gate_field/oil-ignored',
    textBn: 'গেজে তেল MIN-এর নিচে — এটা বিপদ সংকেত। সঙ্গে সঙ্গে সুপারভাইজারকে রিপোর্ট করুন, লিক আর টপ-আপের ব্যবস্থা চাই।',
    art: '$_art/oil_gauge.svg',
    lessonPoint: 2,
  );
  static const oilNeedless = DoMistake(
    key: '4.5/m4_gate_field/oil-needless',
    textBn: 'গেজে তেল MIN আর MAX-এর মাঝে, স্বাভাবিক দাগের কাছে — গেজ ঠিকমতো পড়ুন, রিডিং লিখে রাখুন।',
    art: '$_art/oil_gauge.svg',
    lessonPoint: 0,
  );
  static const oilUnread = DoMistake(
    key: '4.5/m4_gate_field/oil-unread',
    textBn: 'না দেখে সিদ্ধান্ত নয় — আগে কনজারভেটরের গেজে তেলের লেভেল পড়ুন, দূর থেকে IR-এ তাপ মাপুন, তারপর ঠিক করুন।',
    art: '$_art/oil_gauge.svg',
    lessonPoint: 0,
  );
  static const earthSpikes = DoMistake(
    key: '4.6/m4_gate_field/earth-spikes',
    textBn: 'আর্থ টেস্টারে মাপার আগে দুটো স্পাইক মাটিতে পুঁতে লিড লাগান — ফল অব পটেনশিয়াল পদ্ধতি।',
    art: '$_art/earth_spikes.svg',
    lessonPoint: 2,
  );
  static const earthHigh = DoMistake(
    key: '4.6/m4_gate_field/earth-high',
    textBn: 'লাইনের আর্থ 5-8 ওহমের কম চাই। রেজিস্ট্যান্স বেশি মানে আর্থিং অকেজো, ফিউজ-ব্রেকার ঠিকমতো কাজ করে না — ঠিক করে আবার মাপুন।',
    art: '$_art/earth_ohm.svg',
    lessonPoint: 2,
  );
  static const earthUntested = DoMistake(
    key: '4.6/m4_gate_field/earth-untested',
    textBn: 'চোখে দেখে আর্থিং ঠিক বলা যায় না — আর্থ টেস্টারে মেপে রেজিস্ট্যান্স সীমার নিচে, তা প্রমাণ করে তবে লিখুন।',
    art: '$_art/earth_ohm.svg',
    lessonPoint: 2,
  );
  static const noEarth = DoMistake(
    key: '4.1/m4_gate_field/no-earth',
    textBn: 'দুই দিকে আর্থ ছাড়া লাইনে কাজ মারাত্মক — বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ বা ভুল চালু থাকতে পারে।',
    art: '$_art/earth_both_sides.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const earthSkip = DoMistake(
    key: '4.1/m4_gate_field/earth-skip',
    textBn: 'শাটডাউন থাকলেও লাইনের দুই প্রান্তে আর্থিং বাধ্যতামূলক — বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ থাকে।',
    art: '$_art/earth_both_sides.svg',
    lessonPoint: 0,
  );
  static const insNoRope = DoMistake(
    key: '4.1/m4_gate_field/ins-no-rope',
    textBn: 'কন্ডাক্টর দড়িতে না ধরে ইনসুলেটর খোলা নয় — তার পড়ে যায় বা পাশের ফেজের কাছে চলে যায়।',
    art: '$_art/ins_rope.svg',
    lessonPoint: 1,
  );
  static const insOrder = DoMistake(
    key: '4.1/m4_gate_field/ins-order',
    textBn: 'ধাপ মেনে চলুন: বাইন্ডিং খোলা → দড়িতে কন্ডাক্টর → পুরনো ইনসুলেটর খোলা → নতুনটা বসিয়ে বাঁধা।',
    art: '$_art/ins_rope.svg',
    lessonPoint: 1,
  );
  static const jumperWrongClamp = DoMistake(
    key: '4.2/m4_gate_field/jumper-wrong-clamp',
    textBn: 'ভুল ক্ল্যাম্প ধরলেন। ঢিলা কানেকশনই হটস্পট — রাতে লাল হয়ে জ্বলে, স্পার্ক বা হিসহিস শব্দ আসে। লক্ষণ দেখে তবে হাত দিন।',
    art: '$_art/jumper_hotspot.svg',
    lessonPoint: 2,
  );
  static const jumperDirty = DoMistake(
    key: '4.2/m4_gate_field/jumper-dirty',
    textBn: 'আগে স্টিল ব্রাশে তার ঘষে ময়লা তুলে অ্যান্টি-অক্সিডেন্ট পেস্ট — ময়লা সংযোগে রেজিস্ট্যান্স বাড়ে, আবার গরম হয়।',
    art: '$_art/jumper_brush.svg',
    lessonPoint: 1,
  );
  static const jumperOneWrench = DoMistake(
    key: '4.2/m4_gate_field/jumper-one-wrench',
    textBn: 'দুটি রেঞ্চ: একটায় বল্টুর মাথা চেপে ধরুন, অন্যটায় নাট ঘোরান — এক রেঞ্চে বল্টু ঘোরে, টাইট হয় না।',
    art: '$_art/jumper_wrench.svg',
    lessonPoint: 1,
  );
  static const dpOrder = DoMistake(
    key: '4.7/m4_gate_field/dp-order',
    textBn: 'ড্রেসিং উপর থেকে নিচে — আগে HT সাইড, তারপর LT সাইড। এলোমেলো করলে কাজ বাদ পড়ে।',
    art: '$_art/dp_top_down.svg',
    lessonPoint: 1,
  );
  static const dpUnfinished = DoMistake(
    key: '4.7/m4_gate_field/dp-unfinished',
    textBn: 'ড্রেসিং বাকি: ক্রস-আর্মে ঠেকা জাম্পার, বাইন্ডিং তারের লেজ বা ঝোলা LT কেবিল — এগুলোই শর্ট সার্কিটের ফাঁদ।',
    art: '$_art/dp_top_down.svg',
    lessonPoint: 2,
  );
  static const dpLoose = DoMistake(
    key: '4.7/m4_gate_field/dp-loose',
    textBn: 'ড্রেসিং সুন্দর করতে গিয়ে নাট-বল্টু ঢিলা রাখবেন না — প্রতিটি কানেকশন সঠিক টর্কে টাইট দিন।',
    art: '$_art/dp_nuts.svg',
    lessonPoint: 2,
  );
  static const treeTopping = DoMistake(
    key: '4.8/m4_gate_field/tree-topping',
    textBn: 'গাছের মাথা গোল করে কাটা (টপিং) নিষিদ্ধ — শুধু লাইনের দিকে ঝোঁকা ডাল ছাঁটুন।',
    art: '$_art/tree_topping.svg',
    lessonPoint: 0,
  );
  static const treeCordon = DoMistake(
    key: '4.8/m4_gate_field/tree-cordon',
    textBn: 'কাটার আগে নিচে দড়ি বা টেপে এলাকা ঘিরে দিন — কাটা ডাল পথচারী বা গাড়ির ওপর পড়তে পারে।',
    art: '$_art/tree_cordon.svg',
    lessonPoint: 1,
  );
  static const treeRope = DoMistake(
    key: '4.8/m4_gate_field/tree-rope',
    textBn: 'ভারী ডাল দড়িতে বেঁধে তবে কাটুন — দড়িই পতনের দিক নিয়ন্ত্রণ করে, তারের ওপর পড়তে দেয় না।',
    art: '$_art/tree_rope.svg',
    lessonPoint: 2,
  );
  static const treeCutOrder = DoMistake(
    key: '4.8/m4_gate_field/tree-cut-order',
    textBn: 'থ্রি-কাট: আগে নিচে ছোট কাট, তারপর ওপর থেকে কেটে নামানো, শেষে কলারের বাইরে ফিনিশ কাট।',
    art: '$_art/tree_three_cut.svg',
    lessonPoint: 2,
  );
  static const lampLive = DoMistake(
    key: '4.9/m4_gate_field/lamp-live',
    textBn: 'MCB চালু রেখে ল্যাম্প বদলানো মারাত্মক — হোল্ডারের ভেতরের পিন লাইভ থাকে। আগে MCB বা ফিউজ নামান।',
    art: '$_art/lamp_mcb.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const lampUntested = DoMistake(
    key: '4.9/m4_gate_field/lamp-untested',
    textBn: 'MCB নামানোর পরেও টেস্টার বা মাল্টিমিটারে ফিক্সচারে ভোল্টেজ নেই — নিশ্চিত করে তবে হাত দিন।',
    art: '$_art/lamp_test.svg',
    lessonPoint: 2,
  );
  static const balLive = DoMistake(
    key: '4.10/m4_gate_field/bal-live',
    textBn: 'চালু লাইনে সার্ভিস লাইনের ফেজ বদলানো মারাত্মক — শাটডাউন আর PTW নিয়ে তবেই কাজ।',
    art: '$_art/bal_shutdown.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const balWrongWay = DoMistake(
    key: '4.10/m4_gate_field/bal-wrong-way',
    textBn: 'বেশি কারেন্টের ফেজ থেকে কম লোডের ফেজে সার্ভিস লাইন সরান — উল্টো সরালে আনব্যালেন্স আরও বাড়ে।',
    art: '$_art/bal_shift.svg',
    lessonPoint: 2,
  );
  static const balNoRecheck = DoMistake(
    key: '4.10/m4_gate_field/bal-no-recheck',
    textBn: 'কাজের পর আবার ক্ল্যাম্প মিটারে প্রতিটি ফেজ আর নিউট্রাল মাপুন — না মাপলে ব্যালেন্স প্রমাণ হয় না।',
    art: '$_art/bal_shift.svg',
    lessonPoint: 2,
  );

  static List<DoMistake> get all => const [
        doOnLoad,
        doUnder,
        doNoPpe,
        touchTank,
        engineOil,
        oilIgnored,
        oilNeedless,
        oilUnread,
        earthSpikes,
        earthHigh,
        earthUntested,
        noEarth,
        earthSkip,
        insNoRope,
        insOrder,
        jumperWrongClamp,
        jumperDirty,
        jumperOneWrench,
        dpOrder,
        dpUnfinished,
        dpLoose,
        treeTopping,
        treeCordon,
        treeRope,
        treeCutOrder,
        lampLive,
        lampUntested,
        balLive,
        balWrongWay,
        balNoRecheck,
      ];

  /// The lesson that teaches [m] ("পাঠে দেখুন" opens it): its key's prefix.
  static String lessonOf(DoMistake m) => m.key.split('/').first;
}

abstract final class M4GateLines {
  static const title = 'স্কিলডের ডকেট · র‍্যাঙ্ক গেট';
  static const intro = 'স্কিলডের ডকেট! এক ফিডারে সারাদিনের নয়টা কাজ — নিয়ম মেনে সারুন, পারলেই স্কিলড!';

  /// The task per station; a tap on the guide says the next wording.
  static const tasks = {
    M4GateStation.doOpen: [
      'ট্রান্সফরমারের কাজ। আগে হট স্টিকে তিনটে DO খুলুন।',
      'তিনটে DO নামাতে হবে — নিরাপদে।',
      'DO খোলার কাজ। তাড়াহুড়ো নয়।',
    ],
    M4GateStation.oilTemp: [
      'এবার ট্রান্সফরমারের তেল আর তাপ দেখুন।',
      'রক্তচাপ আর জ্বর — গেজ আর তাপমাত্রা।',
      'তেলের লেভেল আর তাপ মেপে সিদ্ধান্ত নিন।',
    ],
    M4GateStation.earth: [
      'ট্রান্সফরমারের আর্থিং মাপুন — দরকার হলে ঠিক করুন।',
      'আর্থের রেজিস্ট্যান্স কত? মেপে দেখুন।',
      'আর্থিং সুস্থ কিনা প্রমাণ করুন।',
    ],
    M4GateStation.insulator: [
      'এগারো কেভি সেকশনে PTW এসেছে। ভাঙা ইনসুলেটরটা বদলান।',
      'ভাঙা ইনসুলেটর বদলের কাজ — নিয়ম মেনে।',
      'পোলের কাজ শুরু। নিরাপদে বদলান।',
    ],
    M4GateStation.jumper: [
      'রাতে এই পোলের জাম্পারে লাল আভা দেখা গেছিল। খুঁজে ঠিক করুন।',
      'কোন জাম্পার ক্ল্যাম্পটা গরম হয়েছিল? ঠিক করুন।',
      'গরম জাম্পার সারান।',
    ],
    M4GateStation.dpDress: [
      'ডিপি স্ট্রাকচারটা গুছিয়ে দিন।',
      'ড্রেসিং — অগোছালো যা আছে ঠিক করুন।',
      'স্ট্রাকচার পরিপাটি করুন।',
    ],
    M4GateStation.tree: [
      'লাইনের দিকে ঝুঁকে পড়া ডালটা ছাঁটুন।',
      'ডালটা নিরাপদে নামান।',
      'গাছের ডাল ছাঁটার কাজ — ধাপে ধাপে।',
    ],
    M4GateStation.streetLight: [
      'মোড়ের স্ট্রিট লাইট জ্বলছে না, ল্যাম্প কেটেছে। বদলে দিন।',
      'ল্যাম্প বদলের কাজ — নিরাপদে।',
      'রাস্তার আলো ফেরান।',
    ],
    M4GateStation.balance: [
      'শেষ কাজ: ফিডার পিলারে LT ফেজ ব্যালেন্স করুন।',
      'চারটে তারের কারেন্ট মেপে লোড সমান করুন।',
      'ফেজের লোড মিলিয়ে দিন।',
    ],
  };

  static const stationTitles = {
    M4GateStation.doOpen: 'DO খোলা',
    M4GateStation.oilTemp: 'তেল ও তাপ',
    M4GateStation.earth: 'আর্থ টেস্ট',
    M4GateStation.insulator: 'ইনসুলেটর বদল',
    M4GateStation.jumper: 'জাম্পার টাইট',
    M4GateStation.dpDress: 'ডিপি ড্রেসিং',
    M4GateStation.tree: 'ডাল ছাঁটা',
    M4GateStation.streetLight: 'স্ট্রিট লাইট',
    M4GateStation.balance: 'ফেজ ব্যালেন্স',
  };

  // Controls.
  static const faceShield = 'ফেস শিল্ড';
  static const gloves = 'ইনসুলেটেড গ্লাভস';
  static const standFirst = 'হট স্টিক হাতে আগে জায়গা নিন।';
  static const irGun = 'IR থার্মোমিটার';
  static const handOnTank = 'ট্যাঙ্কে হাত';
  static const oilCalls = {
    M4OilCall.normal: 'স্বাভাবিক · লিখে রাখি',
    M4OilCall.report: 'সুপারভাইজারকে রিপোর্ট',
    M4OilCall.engineOil: 'ইঞ্জিন অয়েল ঢালি',
  };
  static const test = 'TEST';
  static const earthOk = 'আর্থিং ঠিক';
  static const steps = {
    M4InsStep.unbind: 'বাইন্ডিং খোলা',
    M4InsStep.rope: 'দড়িতে কন্ডাক্টর ধরা',
    M4InsStep.removeOld: 'পুরনো ইনসুলেটর খোলা',
    M4InsStep.fitNew: 'নতুনটা বসিয়ে বাঁধা',
  };
  static const jumperActs = {
    M4JumperAct.brush: 'ব্রাশে ঘষে পেস্ট',
    M4JumperAct.twoWrench: 'দুই রেঞ্চে টাইট',
    M4JumperAct.oneWrench: 'এক রেঞ্চে টাইট',
  };
  static const nuts = 'নাট-বল্টু টাইট';
  static const dpDone = 'ড্রেসিং শেষ';
  static const cordon = 'এলাকা ঘেরা';
  static const rope = 'ডালে দড়ি বাঁধা';
  static const cuts = {
    M4Cut.under: 'নিচ থেকে ছোট কাট',
    M4Cut.top: 'ওপর থেকে পুরো কাট',
    M4Cut.finish: 'কলারের বাইরে ফিনিশ',
    M4Cut.topping: 'মাথা গোল করে টপিং',
  };
  static const tester = 'টেস্টার ছোঁয়ান';
  static const newLamp = 'ল্যাম্প বদলান';
  static const measureAll = 'আগে চারটে তারই মাপুন।';
  static const balanced = 'ব্যালেন্স হয়েছে';
  /// Four calls: shutdown or live × heavy→light or light→heavy, so no option
  /// shares a part with every other one (no "odd one in" giveaway).
  static String balCall(M4BalCall c, String heavy, String light) => switch (c) {
        M4BalCall.shiftDead => 'শাটডাউন নিয়ে $heavy → $light',
        M4BalCall.wrongWay => 'শাটডাউন নিয়ে $light → $heavy',
        M4BalCall.shiftLive => 'চালু লাইনেই $heavy → $light',
        M4BalCall.liveBack => 'চালু লাইনেই $light → $heavy',
      };
  static const docketClose = 'ডকেট বন্ধ করুন';
  static const shifted = 'শাটডাউন নিয়ে কয়েকটা সার্ভিস লাইন সরানো হলো, গ্রাহককে জানানো হয়েছিল। লাইন চালু — আবার মাপুন।';

  static const praise = {
    M4GateStation.doOpen: 'তিনটে DO খোলা — অফ-লোডে, পাশ থেকে, পুরো PPE-তে।',
    M4GateStation.oilTemp: 'গেজ পড়া হলো, তাপ মাপা হলো দূর থেকে — ঠিক সিদ্ধান্ত!',
    M4GateStation.earth: 'আর্থ রেজিস্ট্যান্স এখন সীমার নিচে — অদৃশ্য রক্ষক সচল!',
    M4GateStation.insulator: 'নতুন ইনসুলেটর শক্ত করে বাঁধা — সার্জনের হাত!',
    M4GateStation.jumper: 'পরিষ্কার, টাইট জাম্পার — আর হটস্পট হবে না।',
    M4GateStation.dpDress: 'পরিপাটি ডিপি — উপর থেকে নিচে, সব টাইট।',
    M4GateStation.tree: 'ডাল নামল দড়িতে, ছাল ছেঁড়েনি — নিখুঁত থ্রি-কাট!',
    M4GateStation.streetLight: 'মোড় আবার আলোয় — নিরাপদে বদলানো!',
    M4GateStation.balance: 'নিউট্রাল কারেন্ট প্রায় শূন্যের কাছে — ফেজ ব্যালেন্সড!',
  };

  // --- Reasons (one library per station, 2 right / 5 wrong) -----------------
  static const whyDoQ = 'কেন লোড বন্ধ করে, পাশে দাঁড়িয়ে DO খুললেন?';
  static const whyDoRight = [
    'অফ-লোডে আর্ক ছোট, পাশে থাকলে ফ্ল্যাশ মুখে লাগে না',
    'ফিউজ মাথার ওপরে নয়, পাশে রাখলে ফ্ল্যাশ থেকে বাঁচি',
  ];
  static const whyDoWrong = [
    'হট স্টিক থাকলে পাশে না নিচে, তাতে কিছু যায় না',
    'ঠিক নিচে দাঁড়ালে ফিউজের রিং ভালো দেখা যায়',
    'লোড চালু রাখলেও DO নিজেই আর্ক নিভিয়ে নেয়',
    'ফেস শিল্ড থাকলে ঠিক নিচেও ফ্ল্যাশ লাগে না',
    'ধীরে ধীরে আলতো করে টানলে আর্ক সবচেয়ে কম হয়',
  ];

  static const whyOilQ = 'কেন গেজ পড়ে, দূর থেকে তাপ মাপলেন?';
  static const whyOilRight = [
    'গেজের MIN-MAX দাগই তেলের আসল অবস্থা বলে',
    'গরম ট্যাঙ্কে হাত নয়, IR-এ দূর থেকে মাপা নিরাপদ',
  ];
  static const whyOilWrong = [
    'ট্যাঙ্ক ছুঁয়ে দেখলেই তাপ সবচেয়ে ঠিক বোঝা যায়',
    'তেল কমলে যেকোনো ইঞ্জিন অয়েল ঢাললেই চলে',
    'গেজ দেখার দরকার নেই, হামিং শুনলেই সব বোঝা যায়',
    'শীতে-গরমে কনজারভেটরে তেলের লেভেল বদলায় না',
    'তেল লিক হলে পরে সময়মতো দেখে নেওয়া যায়',
  ];

  static const whyEarthQ = 'কেন পিট ঠিক করে আবার মাপলেন?';
  static const whyEarthRight = [
    'লাইনের আর্থ 5-8 ওহমের কম না হলে সুরক্ষা কাজ করে না',
    'জল আর টাইট সংযোগে রেজিস্ট্যান্স কমে, মেপে প্রমাণ চাই',
  ];
  static const whyEarthWrong = [
    'আর্থ তার চোখে ঠিক দেখালেই মাপার দরকার নেই',
    'মাটিতে একটা লোহার রড পুঁতলেই আর্থিং হয়ে যায়',
    'আর্থিং কাটা থাকলেও লাইন তো দিব্যি চলে যায়',
    'রেজিস্ট্যান্স বেশি হলে সুরক্ষা আরও ভালো হয়',
    'একবার মেপেছি, ঠিক করার পরে আবার মাপা বৃথা',
  ];

  static const whyInsQ = 'কেন দুদিকে আর্থ দিয়ে, দড়িতে তার ধরে কাজ করলেন?';
  static const whyInsRight = [
    'বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ থাকে, দড়ি তার ধরে রাখে',
    'দুদিকের আর্থ আমায় বাঁচায়, দড়ি তারকে দূরে রাখে',
  ];
  static const whyInsWrong = [
    'শাটডাউন থাকলে দুদিকে আর্থ লাগানো শুধুই সময় নষ্ট',
    'দড়ি লাগে না, কন্ডাক্টর খালি হাতে ধরে রাখাই সহজ',
    'একদিকে আর্থ দিলেই পুরো লাইনকে নিরাপদ রাখে',
    'পুরনো ইনসুলেটর আগে খুললে কাজ অনেক দ্রুত হয়',
    'নতুন ইনসুলেটর একটু ঢিলা থাকলেও তার ঠিক থাকে',
  ];

  static const whyJumperQ = 'কেন আগে ঘষে, তারপর দুই রেঞ্চে টাইট দিলেন?';
  static const whyJumperRight = [
    'ময়লা আর ঢিলা সংযোগেই ক্ল্যাম্প গরম হয়ে ওঠে',
    'এক রেঞ্চে বল্টু ধরে অন্যটায় নাট ঘোরালে ঠিক টাইট হয়',
  ];
  static const whyJumperWrong = [
    'জাম্পারে যান্ত্রিক টান নেই, তাই ঢিলা থাকলেও বিপদ নেই',
    'যেকোনো সরু তার দিয়েও জাম্পার দিব্যি চলে যায়',
    'গরম ক্ল্যাম্পে জল ঢাললেই সমস্যাটা মিটে যায়',
    'এক রেঞ্চে যত জোরে পারি টাইট দিলেই কাজ হয়ে যায়',
    'তারের ওপর অক্সাইডের স্তর থাকলে সংযোগ ভালো হয়',
  ];

  static const whyDpQ = 'কেন উপর থেকে নিচে গুছিয়ে, নাটও টাইট দিলেন?';
  static const whyDpRight = [
    'HT থেকে LT, উপর থেকে নিচে গোছালে কিছু বাদ পড়ে না',
    'বাড়তি লেজ আর ঝোলা কেবিলে শর্ট হয়, ঢিলা নাটে তাপ',
  ];
  static const whyDpWrong = [
    'ড্রেসিং শুধু দেখানোর জন্য, কাজের কিছু নয়',
    'ইনসুলেটেড তার ছুঁয়ে থাকলে কোনো ক্ষতি নেই',
    'বাইন্ডিং তারের লেজ থাকলে বাঁধন মজবুত হয়',
    'সুন্দর দেখালেই সব কানেকশন আপনা থেকে টাইট হয়',
    'LT কেবিল এলোমেলো ঝুললে বাতাসে ভালো ঠান্ডা হয়',
  ];

  static const whyTreeQ = 'কেন দড়ি বেঁধে, তিন কাটে ডালটা নামালেন?';
  static const whyTreeRight = [
    'দড়িতে পতনের দিক ঠিক থাকে, নিচের কাটে ছাল ছেঁড়ে না',
    'তিন কাটে ভারী ডাল নিয়ন্ত্রণে নামে, তারে পড়ে না',
  ];
  static const whyTreeWrong = [
    'গাছের মাথা গোল করে কেটে দিলেই সব ঝামেলা শেষ',
    'এক কাটে ডাল নামালেই কাজ সবচেয়ে দ্রুত হয়',
    'ডাল যেদিকে খুশি পড়ুক, নিচে তো কেউ থাকে না',
    'লাইনের একদম কাছে ডাল কাটতেও শাটডাউন লাগে না',
    'ইচ্ছে হলেই অনুমতি ছাড়া গোটা গাছ কেটে ফেলা যায়',
  ];

  static const whyLampQ = 'কেন MCB নামিয়ে, টেস্টারে দেখে ল্যাম্প বদলালেন?';
  static const whyLampRight = [
    'হোল্ডারের ভেতরের পিন লাইভ থাকে, বন্ধ করে প্রমাণ চাই',
    'MCB নামালেও টেস্টারে শূন্য না দেখলে ভরসা নেই',
  ];
  static const whyLampWrong = [
    'বাল্ব বদলাতে পাওয়ার অফ করার কোনো দরকারই নেই',
    'যেকোনো ওয়াটের ল্যাম্প যেকোনো ব্যালাস্টে চলে',
    'গ্লাভস পরা থাকলে চালু হোল্ডারেও কোনো ভয় নেই',
    'MCB নামানোর পরে আর টেস্ট করার কোনো মানে নেই',
    'দিনের বেলা লাইট নেভা, তাই হোল্ডার নিরাপদ',
  ];

  static const whyBalQ = 'কেন মেপে, শাটডাউনে ভারী ফেজ থেকে হালকায় সরালেন?';
  static const whyBalRight = [
    'ভারী ফেজের লোড হালকায় গেলে নিউট্রাল কারেন্ট নামে',
    'চালু লাইনে বদল নয়, আবার মাপাই ব্যালেন্সের প্রমাণ',
  ];
  static const whyBalWrong = [
    'নিউট্রালে তো কোনো কারেন্ট থাকেই না, মাপা বৃথা',
    'হালকা ফেজ থেকে ভারীতে সরালেই ব্যালেন্স হয়',
    'চালু লাইনেই সার্ভিস তার বদলানো সবচেয়ে দ্রুত',
    'লোড ব্যালেন্স শুধু সময় নষ্ট, কোনো লাভ নেই',
    'কোন গ্রাহক কোন ফেজে, লিখে রাখার দরকার নেই',
  ];

  // --- The careless coworker (station 4) ---------------------------------------
  static const coworker = CoworkerScript(
    line: 'আরে, শাটডাউন তো নেওয়াই আছে! দুদিকে আর্থ লাগাতে সময় নষ্ট — সোজা উঠে পড়ো।',
    exitLine: 'হুঁ! আর্থ আর্থ করেই দিন কাবার।',
    right: [
      'না, দুদিকে আর্থ না দিয়ে পোলে উঠব না',
      'বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ — আগে আর্থ',
      'না, আগে দুই প্রান্তে আর্থিং, তারপর কাজ',
    ],
    wrong: [
      'ঠিক, শাটডাউন থাকলেই লাইন পুরো নিরাপদ',
      'ঠিক আছে, আর্থটা আজ বাদ দিয়ে উঠি',
      'একদিকে একটা আর্থ দিলেই যথেষ্ট হবে',
      'হ্যাঁ, তাড়াতাড়ি উঠে কাজ সেরে নামি',
    ],
    asks: [
      'ও বলছে আর্থ লাগবে না। আপনি কী করবেন?',
      'শাটডাউন আছে — আর্থ ছাড়া উঠবেন?',
      'আর্থ দেবেন, না ওর কথা শুনবেন?',
    ],
  );
  static const coworkerHeld = 'ঠিক! আর্থ ছাড়া পোলে নয় — দুদিকে আর্থ দিন।';

  static const allSet = 'অভিনন্দন! স্কিলডের ডকেট নিখুঁত — আপনি এখন স্কিলড লাইনম্যান, কাজের কারিগর!';
  static const fail = 'আরেকবার — নয়টা কাজের প্রতিটা নিয়ম মেনে স্কিলড র‍্যাঙ্ক জিতুন।';
  static const rankStamp = 'নতুন র‍্যাঙ্ক: স্কিলড · কাজের কারিগর';

  /// Every fixed line the guide says (for recording).
  static List<String> get recordable => [
        intro,
        for (final l in tasks.values) ...l,
        ...praise.values,
        standFirst,
        measureAll,
        shifted,
        whyDoQ,
        whyOilQ,
        whyEarthQ,
        whyInsQ,
        whyJumperQ,
        whyDpQ,
        whyTreeQ,
        whyLampQ,
        whyBalQ,
        coworkerHeld,
        ...coworker.asks,
        allSet,
        fail,
      ];
}

// ============================================================================
// Rules (pure)
// ============================================================================

class M4GateRun {
  M4GateRun(this.seed) : _rng = math.Random(seed) {
    oilLow = _rng.nextBool();
    tempC = 44 + _rng.nextInt(14);
    earthHighOhm = 11 + _rng.nextInt(80) / 10;
    earthGoodOhm = 2.6 + _rng.nextInt(20) / 10;
    broken = _rng.nextInt(3);
    insOrder = [...M4InsStep.values]..shuffle(_rng);
    hotSide = _rng.nextInt(2);
    jumperOpts = [...M4JumperAct.values]..shuffle(_rng);
    cutOpts = [...M4Cut.values]..shuffle(_rng);
    final phases = [0, 1, 2]..shuffle(_rng);
    heavy = phases[0];
    mid = phases[1];
    light = phases[2];
    balOpts = [...M4BalCall.values]..shuffle(_rng);
    rowFlips = _rng.nextInt(16);
  }

  final int seed;
  final math.Random _rng;

  late final bool oilLow;
  late final int tempC;
  late final double earthHighOhm;
  late final double earthGoodOhm;
  late final int broken;
  late final List<M4InsStep> insOrder;
  late final int hotSide;
  late final List<M4JumperAct> jumperOpts;
  late final List<M4Cut> cutOpts;
  late final int heavy;
  late final int mid;
  late final int light;
  late final List<M4BalCall> balOpts;

  /// Dealt left/right order of the two-button rows (bit per row), so the
  /// right move is never always on the same side.
  late final int rowFlips;

  /// The heat row (IR gun / hand on the tank) is dealt swapped.
  bool get flipTemp => rowFlips & 1 != 0;

  /// The earth row (TEST / earthing OK) is dealt swapped.
  bool get flipEarth => rowFlips & 2 != 0;

  /// The DP row (nuts / dressing done) is dealt swapped.
  bool get flipDp => rowFlips & 4 != 0;

  /// The lamp row (tester / new lamp) is dealt swapped.
  bool get flipLamp => rowFlips & 8 != 0;

  M4GateStation station = M4GateStation.doOpen;
  final Set<M4GateStation> completed = {};
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => completed.length == M4GateStation.values.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  /// Three slips strike the play out (kit [kStrikesToFail]), so a pass has fewer.
  bool get passed => done && deadly == null && slips < kStrikesToFail && percent >= 55;

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake slip(DoMistake m) {
    slips++;
    return m;
  }

  void advanceStation() {
    completed.add(station);
    final next = station.index + 1;
    if (next < M4GateStation.values.length) station = M4GateStation.values[next];
  }

  // 1. DO ---------------------------------------------------------------------
  var ltOn = true;
  var faceShield = false;
  var doGloves = false;
  M4GateStance? stance;
  final List<bool> doOpen = [false, false, false];

  void switchLtOff() {
    if (!ltOn) return;
    ltOn = false;
    tag('অফ-লোডে DO খোলা');
  }

  DoMistake? pullDo(int i) {
    if (ended || stance == null || doOpen[i]) return null;
    if (ltOn) return deadly = M4GateMistakes.doOnLoad;
    // A slip here as in m4_do_open (4.4a): the same act, one class.
    if (stance == M4GateStance.under) return slip(M4GateMistakes.doUnder);
    if (!faceShield || !doGloves) return slip(M4GateMistakes.doNoPpe);
    doOpen[i] = true;
    if (doDone) tag('পাশে দাঁড়িয়ে হট স্টিকে DO');
    return null;
  }

  bool get doDone => doOpen.every((o) => o);

  // 2. Oil and temperature --------------------------------------------------------
  var gaugeRead = false;
  var tempRead = false;
  var oilDone = false;

  void readGauge() => gaugeRead = true;

  DoMistake? measureTemp({required bool ir}) {
    if (ended || tempRead) return null;
    if (!ir) return slip(M4GateMistakes.touchTank);
    tempRead = true;
    tag('দূর থেকে IR-এ তাপ মাপা');
    return null;
  }

  bool get oilReady => gaugeRead && tempRead;

  DoMistake? callOil(M4OilCall c) {
    if (ended || oilDone) return null;
    if (c == M4OilCall.engineOil) return slip(M4GateMistakes.engineOil);
    // A call before the gauge is read and the heat measured is an over-call.
    if (!oilReady) return slip(M4GateMistakes.oilUnread);
    if (oilLow && c != M4OilCall.report) return slip(M4GateMistakes.oilIgnored);
    if (!oilLow && c != M4OilCall.normal) return slip(M4GateMistakes.oilNeedless);
    oilDone = true;
    tag(oilLow ? 'কম তেলের রিপোর্ট' : 'গেজ পড়ে লেভেল লেখা');
    return null;
  }

  // 3. Earth --------------------------------------------------------------------
  final Set<int> spikes = {};
  var pitWet = false;
  var clampTight = false;
  var earthTested = false;
  var earthGood = false;
  var earthDone = false;

  void placeSpike(int i) => spikes.add(i);
  void waterPit() => pitWet = true;
  void tightenClamp() => clampTight = true;

  /// One test: the reading the tester shows (null = a slip, see [slips]).
  DoMistake? runEarthTest() {
    if (ended || earthDone) return null;
    if (spikes.length < 2) return slip(M4GateMistakes.earthSpikes);
    earthTested = true;
    earthGood = pitWet && clampTight;
    return null;
  }

  double get earthOhm => earthGood ? earthGoodOhm : earthHighOhm;

  DoMistake? confirmEarth() {
    if (ended || earthDone) return null;
    // "Earthing OK" with no reading is an over-call, never a free reminder.
    if (!earthTested) return slip(M4GateMistakes.earthUntested);
    if (!earthGood) return slip(M4GateMistakes.earthHigh);
    earthDone = true;
    tag('আর্থ মেপে, পিট সারিয়ে আবার মাপা');
    return null;
  }

  // 4. Insulator ------------------------------------------------------------------
  final Set<int> earths = {};
  final List<M4InsStep> insDone = [];

  bool get earthsBoth => earths.length == 2;

  void placeEarth(int side) {
    earths.add(side);
    if (earthsBoth) tag('দুই দিকে আর্থ দিয়ে পোলে ওঠা');
  }

  DoMistake? insStep(M4InsStep s) {
    if (ended || insDone.contains(s) || insDoneAll) return null;
    if (!earthsBoth) return deadly = M4GateMistakes.noEarth;
    final expected = M4InsStep.values[insDone.length];
    if (s != expected) {
      if (s == M4InsStep.removeOld && !insDone.contains(M4InsStep.rope)) return slip(M4GateMistakes.insNoRope);
      return slip(M4GateMistakes.insOrder);
    }
    insDone.add(s);
    if (insDoneAll) tag('দড়িতে কন্ডাক্টর ধরে ইনসুলেটর বদল');
    return null;
  }

  bool get insDoneAll => insDone.length == M4InsStep.values.length;

  // 5. Jumper -----------------------------------------------------------------------
  var hotFound = false;
  var jumperClean = false;
  var jumperTight = false;

  /// Tapping a clamp: null when it is the one that ran hot; the cool one is a
  /// wrong flag and costs a slip (never a free "this one is fine").
  DoMistake? spotClamp(int side) {
    if (ended || hotFound) return null;
    if (side != hotSide) return slip(M4GateMistakes.jumperWrongClamp);
    hotFound = true;
    return null;
  }

  DoMistake? jumperAct(M4JumperAct a) {
    if (ended || !hotFound || jumperTight) return null;
    if (a == M4JumperAct.brush) {
      jumperClean = true;
      return null;
    }
    if (a == M4JumperAct.oneWrench) return slip(M4GateMistakes.jumperOneWrench);
    if (!jumperClean) return slip(M4GateMistakes.jumperDirty);
    jumperTight = true;
    tag('ব্রাশ, পেস্ট আর দুই রেঞ্চে জাম্পার');
    return null;
  }

  // 6. DP dressing ----------------------------------------------------------------
  final Set<M4DpFault> dpFixed = {};
  var nutsTight = false;
  var dpDone = false;

  DoMistake? fixDp(M4DpFault f) {
    if (ended || dpDone || dpFixed.contains(f)) return null;
    if (f.index != dpFixed.length) return slip(M4GateMistakes.dpOrder);
    dpFixed.add(f);
    return null;
  }

  void tightenNuts() => nutsTight = true;

  DoMistake? finishDp() {
    if (ended || dpDone) return null;
    if (dpFixed.length < M4DpFault.values.length) return slip(M4GateMistakes.dpUnfinished);
    if (!nutsTight) return slip(M4GateMistakes.dpLoose);
    dpDone = true;
    tag('উপর থেকে নিচে ড্রেসিং, নাট টাইট');
    return null;
  }

  // 7. Tree -------------------------------------------------------------------------
  var cordoned = false;
  var roped = false;
  final List<M4Cut> cutsDone = [];

  DoMistake? cut(M4Cut c) {
    if (ended || treeDone) return null;
    if (c == M4Cut.topping) return slip(M4GateMistakes.treeTopping);
    if (!cordoned) return slip(M4GateMistakes.treeCordon);
    if (!roped) return slip(M4GateMistakes.treeRope);
    if (c.index != cutsDone.length) return slip(M4GateMistakes.treeCutOrder);
    cutsDone.add(c);
    if (treeDone) tag('দড়ি বেঁধে থ্রি-কাট');
    return null;
  }

  bool get treeDone => cutsDone.length == 3;

  // 8. Street light ----------------------------------------------------------------
  var mcbOn = true;
  var fixtureTested = false;
  var lampNew = false;

  bool get lit => mcbOn && lampNew;

  void toggleMcb() {
    if (ended || lit) return;
    mcbOn = !mcbOn;
    if (mcbOn) fixtureTested = false;
    if (lit) tag('MCB নামিয়ে, টেস্ট করে ল্যাম্প বদল');
  }

  /// The tester on the fixture: what it reads.
  String testFixture() {
    fixtureTested = !mcbOn;
    return mcbOn ? '230 V' : '0 V';
  }

  DoMistake? replaceLamp() {
    if (ended || lampNew) return null;
    if (mcbOn) return deadly = M4GateMistakes.lampLive;
    if (!fixtureTested) return slip(M4GateMistakes.lampUntested);
    lampNew = true;
    return null;
  }

  // 9. Phase balance ------------------------------------------------------------------
  final Set<int> measured = {};
  var balShifted = false;
  var balDone = false;

  static const phaseNames = ['R', 'Y', 'B', 'N'];

  /// The tong tester's reading on wire [i] (0 R, 1 Y, 2 B, 3 N), in A.
  int amps(int i) {
    if (!balShifted) {
      if (i == 3) return 50;
      return i == heavy ? 120 : (i == mid ? 70 : 50);
    }
    if (i == 3) return 6;
    return i == heavy ? 84 : (i == mid ? 70 : 86);
  }

  void measure(int i) => measured.add(i);

  bool get allMeasured => measured.length == 4;

  DoMistake? callBalance(M4BalCall c) {
    if (ended || !allMeasured || balShifted) return null;
    if (c == M4BalCall.shiftLive || c == M4BalCall.liveBack) return deadly = M4GateMistakes.balLive;
    if (c == M4BalCall.wrongWay) return slip(M4GateMistakes.balWrongWay);
    balShifted = true;
    measured.clear();
    return null;
  }

  DoMistake? confirmBalance() {
    if (ended || !balShifted || balDone) return null;
    if (!allMeasured) return slip(M4GateMistakes.balNoRecheck);
    balDone = true;
    tag('টং টেস্টারে মেপে ফেজ ব্যালেন্স');
    return null;
  }
}

// ============================================================================
// Page
// ============================================================================

class M4GateFieldPage extends StatefulWidget {
  const M4GateFieldPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M4GateFieldPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4GateFieldPage> createState() => _M4GateFieldPageState();
}

class _M4GateFieldPageState extends State<M4GateFieldPage> {
  var _round = 0;
  late bool _muted = widget.muted;
  late final int _base = widget.seed ?? DateTime.now().millisecondsSinceEpoch % 100000;

  @override
  Widget build(BuildContext context) => _M4GateRunPage(
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

class _M4GateRunPage extends ConsumerStatefulWidget {
  const _M4GateRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.seed,
    required this.onRetry,
  });

  final LevelContext ctx;
  final M4GateFieldPack pack;
  final bool muted;
  final int seed;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_M4GateRunPage> createState() => _M4GateRunPageState();
}

class _M4GateRunPageState extends ConsumerState<_M4GateRunPage>
    with TickerProviderStateMixin, DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4GateRun _run = M4GateRun(widget.seed);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;

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

  /// The station whose win is being paid (a second tap never pays again).
  M4GateStation? _won;

  // Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  final _docketBtnKey = GlobalKey();
  final Map<String, GlobalKey> _boxKeys = {};
  GlobalKey _bk(String id) => _boxKeys.putIfAbsent(id, GlobalKey.new);

  // Scene state.
  Offset? _stickTo;
  Offset? _sparkAt;
  var _sparkBig = false;
  String _reading = '- - -';
  int? _clampOn;

  @override
  LevelContext get deathCtx => widget.ctx;

  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
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

  // Guide first: no docket modal with a start button; the docket stays one tap
  // away on the station chip.
  Future<void> _start() async {
    setState(() => _intro = false);
    _clock.start();
    await _enterStation();
  }

  Future<void> _enterStation() async {
    if (!mounted) return;
    setState(() {
      _wake++;
      _tapN = 0;
      _reading = '- - -';
      _stickTo = null;
      _clampOn = null;
    });
    unawaited(_sayChain([M4GateLines.tasks[_run.station]!.first]));
    if (_run.station == M4GateStation.insulator && !coworkerDone) scheduleCoworker();
  }

  void _tapGuide() {
    // The reason deck or the coworker's question stays in the bubble.
    if (_intro || _ended || tableBusy || coworkerOpen) return;
    final lines = M4GateLines.tasks[_run.station]!;
    _tapN++;
    _cue('sounds/learn/tick.ogg', volume: 0.5);
    final line = lines[_tapN % lines.length];
    ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.talk, line: line);
    unawaited(MascotSpeechLibrary.speak(line, muted: _muted));
  }

  /// The scene takes input, the coworker aside (his beat 1 is refused by
  /// placing an earth, see [_onEarthSet]).
  bool get _canActBase =>
      !_busy && !_ended && !_freeze && !_run.ended && _card == null && !tableBusy && !_intro && !_docketOpen && !struckOut;

  bool get _canAct => _canActBase && !coworkerOpen;

  /// The level waits for the player's touch now (the gesture hint may show).
  bool get _hintWaiting => (_canAct && _mark == null) || (_docketOpen && !_intro && !_ended && _card == null);

  void _onMissTap() {
    if (_hintWaiting) _hints.missTap();
  }

  /// A scene rect (design pixels) on the screen, or null before layout.
  Rect? _sceneRect(Rect r) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// The gesture hint: the docket's one close button (tap), otherwise a sweep
  /// over every live control of the station — in screen order, never the
  /// order of the work — and a tap only when a single control is left.
  HintSpec? _hint() {
    if (_docketOpen) return HintSpec.tapOn(_docketBtnKey);
    final out = <Rect>[];
    void scene(Rect r) {
      final g = _sceneRect(r);
      if (g != null) out.add(g);
    }

    void btn(String id) {
      final g = HintSpec.globalRectOf(_bk(id));
      if (g != null) out.add(g);
    }

    final h = _sceneH;
    switch (_run.station) {
      case M4GateStation.doOpen:
        final g = M4DtrGeo(h);
        if (_run.ltOn) scene(g.ltBox.inflate(10));
        if (!_run.faceShield) btn('ppe-shield');
        if (!_run.doGloves) btn('ppe-gloves');
        for (final s in M4GateStance.values) {
          if (_run.stance != s) scene(Rect.fromCenter(center: (s == M4GateStance.under ? g.underSpot : g.sideSpot).translate(0, 10), width: 64, height: 34));
        }
        for (var i = 0; i < 3; i++) {
          if (!_run.doOpen[i]) scene(Rect.fromLTWH(g.doX(i) - 17, g.doTopY - 12, 34, g.doLen + 28));
        }
      case M4GateStation.oilTemp:
        final g = M4DtrGeo(h);
        if (!_run.gaugeRead) scene(g.gauge.inflate(18));
        if (!_run.tempRead) {
          btn('temp-ir');
          btn('temp-hand');
        }
        for (final c in M4OilCall.values) {
          btn('oil-${c.name}');
        }
      case M4GateStation.earth:
        final g = M4DtrGeo(h);
        for (var i = 0; i < 2; i++) {
          if (!_run.spikes.contains(i)) scene(g.spikeHit(i));
        }
        if (!_run.pitWet) scene(g.pitHit);
        if (!_run.clampTight) scene(g.clampHit);
        btn('earth-test');
        btn('earth-ok');
      case M4GateStation.insulator:
        final g = M4PoleGeo(h);
        for (var s = 0; s < 2; s++) {
          if (!_run.earths.contains(s)) scene(g.earthHit(s));
        }
        for (final s in M4InsStep.values) {
          if (!_run.insDone.contains(s)) btn('ins-${s.name}');
        }
      case M4GateStation.jumper:
        final g = M4PoleGeo(h);
        if (!_run.hotFound) {
          for (var s = 0; s < 2; s++) {
            scene(g.clampHit(s));
          }
        } else {
          for (final a in M4JumperAct.values) {
            btn('jumper-${a.name}');
          }
        }
      case M4GateStation.dpDress:
        final g = M4DpGeo(h);
        for (final f in M4DpFault.values) {
          if (!_run.dpFixed.contains(f)) scene(g.faultHit(f));
        }
        if (!_run.nutsTight) btn('dp-nuts');
        btn('dp-done');
      case M4GateStation.tree:
        if (!_run.cordoned) btn('tree-cordon');
        if (!_run.roped) btn('tree-rope');
        for (final c in M4Cut.values) {
          if (!_run.cutsDone.contains(c)) btn('cut-${c.name}');
        }
      case M4GateStation.streetLight:
        scene(M4StreetGeo(h).mcbHit);
        btn('lamp-test');
        if (!_run.lampNew) btn('lamp-new');
      case M4GateStation.balance:
        final g = M4PillarGeo(h);
        for (var i = 0; i < 4; i++) {
          scene(g.cableHit(i));
        }
        if (_run.balShifted) {
          btn('bal-ok');
        } else if (_run.allMeasured) {
          for (final c in M4BalCall.values) {
            btn('bal-${c.name}');
          }
        }
    }
    if (out.isEmpty) return null;
    if (out.length == 1) return HintSpec.tap(out.single.center);
    out.sort((a, b) {
      final dx = a.center.dx.compareTo(b.center.dx);
      return dx != 0 ? dx : a.center.dy.compareTo(b.center.dy);
    });
    return HintSpec.sweep(out);
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

  Offset get _mid {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.5);
  }

  /// A station's last right move: ◆ on the table, praise, the reason deck.
  /// The ◆ wait on the table and are paid only by the right reason
  /// ([reasonScore]); a second tap on the station's last control is ignored.
  Future<void> _stationWon(Offset origin, String question, List<String> right, List<String> wrong, int salt) async {
    final st = _run.station;
    if (_won == st || _run.completed.contains(st) || _ended) return;
    _won = st;
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.7);
    putOnTable(_scored(20));
    final praise = M4GateLines.praise[st];
    if (praise != null) await _say(praise, mood: GuideMood.celebrate);
    if (!mounted) return;
    await askReason(
      deal: () => dealChoices(right, wrong, math.Random(widget.seed + salt)),
      question: question,
      stillValid: () => mounted && !_ended,
    );
  }

  Future<void> _spark(Offset at, {bool big = true}) async {
    _cue('sounds/learn/spark.ogg', volume: big ? 0.95 : 0.5);
    if (big) _cue('sounds/accident.ogg', volume: 0.7);
    setState(() {
      _sparkAt = at;
      _sparkBig = big;
    });
    await Future<void>.delayed(Duration(milliseconds: big ? 480 : 260));
    if (mounted) setState(() => _sparkAt = null);
  }

  Future<void> _handleMistake(DoMistake m) async {
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    _combo.miss();
    if (m.deadly) {
      _busy = true;
      _ended = true;
      final frozen = _frozen = Completer<void>();
      setState(() => _freeze = true);
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
      });
      if (out) unawaited(recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore));
    }
  }

  /// Runs a rule: a mistake goes to [_handleMistake] (true); otherwise false.
  Future<bool> _check(DoMistake? m, {Offset? sparkAt}) async {
    if (m == null) return false;
    _hush();
    if (m.deadly && sparkAt != null) await _spark(sparkAt);
    await _handleMistake(m);
    return true;
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
    if (_run.done) {
      unawaited(_finish());
    } else {
      unawaited(_enterStation());
    }
  }

  // --- CoworkerMoment hooks -------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => M4GateLines.coworker;

  @override
  late final math.Random coworkerRng = math.Random(widget.seed * 7 + 3);

  @override
  bool get coworkerMuted => _muted;

  @override
  bool? coworkerCanCome() {
    // His push ("skip the earths, climb") fits only before any earth is on and
    // before the work on the pole has begun.
    if (_ended || _run.ended || _run.station != M4GateStation.insulator || _run.earths.isNotEmpty || _run.insDone.isNotEmpty) return null;
    if (_busy || _freeze || _card != null || tableBusy || _docketOpen || struckOut) return false;
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
      await _say(M4GateLines.coworkerHeld, mood: GuideMood.glad);
    } else {
      await _handleMistake(_run.slip(M4GateMistakes.earthSkip));
    }
  }

  // --- 1 DO ------------------------------------------------------------------------
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
      if (shield) {
        _run.faceShield = true;
      } else {
        _run.doGloves = true;
      }
      _wake++;
    });
  }

  void _onStand(M4GateStance s) {
    if (!_canAct) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/stomp.ogg', volume: 0.4);
    setState(() {
      _run.stance = s;
      _wake++;
    });
  }

  Future<void> _onDo(int i, M4DtrGeo geo, Offset origin) async {
    if (!_canAct || _run.doOpen[i]) return;
    if (_run.stance == null) {
      unawaited(_say(M4GateLines.standFirst));
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
      setState(() => _stickTo = null);
      _busy = false;
      await _check(m, sparkAt: geo.doRing(i).translate(0, -18));
      return;
    }
    HapticFeedback.mediumImpact();
    await _spark(geo.doRing(i).translate(0, -30), big: false);
    if (!mounted) return;
    setState(() => _stickTo = null);
    _busy = false;
    if (_run.doDone) {
      await _stationWon(origin, M4GateLines.whyDoQ, M4GateLines.whyDoRight, M4GateLines.whyDoWrong, 11);
    }
  }

  // --- 2 oil and temperature ----------------------------------------------------------
  void _onGauge() {
    if (!_canAct || _run.gaugeRead) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/card_deal_b.ogg', volume: 0.6);
    setState(() {
      _run.readGauge();
      _wake++;
    });
  }

  Future<void> _onTemp({required bool ir}) async {
    if (!_canAct || _run.tempRead) return;
    if (await _check(_run.measureTemp(ir: ir))) return;
    _cue('sounds/intro/tick.ogg', volume: 0.8);
    setState(() {
      _reading = '${_run.tempC}.${widget.seed % 10} °C';
      _wake++;
    });
  }

  Future<void> _onOilCall(M4OilCall c, Offset origin) async {
    if (!_canAct || _run.oilDone) return;
    if (await _check(_run.callOil(c))) return;
    await _stationWon(origin, M4GateLines.whyOilQ, M4GateLines.whyOilRight, M4GateLines.whyOilWrong, 22);
  }

  // --- 3 earth --------------------------------------------------------------------------
  void _onSpike(int i) {
    if (!_canAct || _run.spikes.contains(i)) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() {
      _run.placeSpike(i);
      _wake++;
    });
  }

  void _onPit() {
    if (!_canAct || _run.pitWet) return;
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    setState(() {
      _run.waterPit();
      _wake++;
    });
  }

  void _onClamp() {
    if (!_canAct || _run.clampTight) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    setState(() {
      _run.tightenClamp();
      _wake++;
    });
  }

  Future<void> _onEarthTest() async {
    if (!_canAct || _run.earthDone) return;
    if (await _check(_run.runEarthTest())) return;
    _cue('sounds/intro/tick.ogg', volume: 0.8);
    setState(() => _reading = '${_run.earthOhm.toStringAsFixed(1)} Ω');
  }

  Future<void> _onEarthOk(Offset origin) async {
    if (!_canAct || _run.earthDone) return;
    if (await _check(_run.confirmEarth())) return;
    await _stationWon(origin, M4GateLines.whyEarthQ, M4GateLines.whyEarthRight, M4GateLines.whyEarthWrong, 33);
  }

  // --- 4 insulator -------------------------------------------------------------------------
  void _onEarthSet(int side, Offset origin) {
    // While he is still talking (beat 1), placing an earth refuses him.
    final beat1 = coworkerOpen && !coworkerChoiceUp;
    if (!(beat1 ? _canActBase : _canAct) || _run.earths.contains(side)) return;
    if (holdForCoworker()) return;
    if (beat1) unawaited(answerCoworker(true, origin, direct: true));
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    setState(() {
      _run.placeEarth(side);
      _wake++;
    });
  }

  Future<void> _onInsStep(M4InsStep s, Offset origin) async {
    if (!_canAct || _run.insDoneAll) return;
    if (holdForCoworker()) return;
    final g = M4PoleGeo(_sceneH);
    if (await _check(_run.insStep(s), sparkAt: g.ins(_run.broken).translate(0, -24))) return;
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _wake++);
    if (_run.insDoneAll) {
      await _stationWon(origin, M4GateLines.whyInsQ, M4GateLines.whyInsRight, M4GateLines.whyInsWrong, 44);
    }
  }

  // --- 5 jumper ---------------------------------------------------------------------------
  Future<void> _onClampSpot(int side) async {
    if (!_canAct || _run.hotFound) return;
    HapticFeedback.selectionClick();
    // The cool clamp is a wrong flag: a slip, and the card stays neutral.
    if (await _check(_run.spotClamp(side))) return;
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  Future<void> _onJumper(M4JumperAct a, Offset origin) async {
    if (!_canAct || _run.jumperTight) return;
    if (await _check(_run.jumperAct(a))) return;
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    setState(() => _wake++);
    if (_run.jumperTight) {
      await _stationWon(origin, M4GateLines.whyJumperQ, M4GateLines.whyJumperRight, M4GateLines.whyJumperWrong, 55);
    }
  }

  // --- 6 DP dressing -----------------------------------------------------------------------
  Future<void> _onDpFault(M4DpFault f) async {
    if (!_canAct || _run.dpDone) return;
    if (await _check(_run.fixDp(f))) return;
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  void _onNuts() {
    if (!_canAct || _run.nutsTight) return;
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    setState(() {
      _run.tightenNuts();
      _wake++;
    });
  }

  Future<void> _onDpDone(Offset origin) async {
    if (!_canAct || _run.dpDone) return;
    if (await _check(_run.finishDp())) return;
    await _stationWon(origin, M4GateLines.whyDpQ, M4GateLines.whyDpRight, M4GateLines.whyDpWrong, 66);
  }

  // --- 7 tree ---------------------------------------------------------------------------
  void _onCordon() {
    if (!_canAct || _run.cordoned) return;
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    setState(() {
      _run.cordoned = true;
      _wake++;
    });
  }

  void _onRope() {
    if (!_canAct || _run.roped) return;
    _cue('sounds/learn/card_deal_b.ogg', volume: 0.6);
    setState(() {
      _run.roped = true;
      _wake++;
    });
  }

  Future<void> _onCut(M4Cut c, Offset origin) async {
    if (!_canAct || _run.treeDone) return;
    if (await _check(_run.cut(c))) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.8);
    setState(() => _wake++);
    if (_run.treeDone) {
      await _stationWon(origin, M4GateLines.whyTreeQ, M4GateLines.whyTreeRight, M4GateLines.whyTreeWrong, 77);
    }
  }

  // --- 8 street light ---------------------------------------------------------------------
  Future<void> _onMcb() async {
    // Once the lamp is lit the station is won: a second tap never switches it off.
    if (!_canAct || _run.lit) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.9);
    setState(() {
      _run.toggleMcb();
      _reading = '- - -';
      _wake++;
    });
    if (_run.lit) {
      await _stationWon(_mid, M4GateLines.whyLampQ, M4GateLines.whyLampRight, M4GateLines.whyLampWrong, 88);
    }
  }

  void _onTester() {
    if (!_canAct || _run.lit) return;
    _cue('sounds/intro/tick.ogg', volume: 0.8);
    setState(() => _reading = _run.testFixture());
  }

  Future<void> _onLamp() async {
    if (!_canAct || _run.lampNew) return;
    final g = M4StreetGeo(_sceneH);
    if (await _check(_run.replaceLamp(), sparkAt: g.head)) return;
    _cue('sounds/intro/drop.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  // --- 9 balance ------------------------------------------------------------------------
  void _onMeasure(int i) {
    if (!_canAct) return;
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() {
      _run.measure(i);
      _clampOn = i;
      _reading = '${M4GateRun.phaseNames[i]} ${_run.amps(i)} A';
      _wake++;
    });
  }

  Future<void> _onBalCall(M4BalCall c) async {
    if (!_canAct || _run.balShifted) return;
    if (!_run.allMeasured) {
      unawaited(_say(M4GateLines.measureAll));
      return;
    }
    if (await _check(_run.callBalance(c), sparkAt: M4PillarGeo(_sceneH).clampAt(_run.heavy))) return;
    _busy = true;
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() {
      _clampOn = null;
      _reading = '- - -';
      _wake++;
    });
    await _say(M4GateLines.shifted);
    _busy = false;
  }

  Future<void> _onBalanced(Offset origin) async {
    if (!_canAct || _run.balDone) return;
    if (await _check(_run.confirmBalance())) return;
    await _stationWon(origin, M4GateLines.whyBalQ, M4GateLines.whyBalRight, M4GateLines.whyBalWrong, 99);
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
      await save.unlockRank(4); // Promotes to Skilled (স্কিলড, rank 4).
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
      await _say(M4GateLines.allSet, mood: GuideMood.celebrate);
    } else {
      _cue('sounds/learn/level_fail.ogg', volume: 0.7);
      await _say(M4GateLines.fail, mood: GuideMood.warn);
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
  // Scene layers (design pixels, 360 × m.height)
  // ============================================================================

  double _sceneH = 800;

  List<Widget> _layers(BuildContext context, SceneMetrics m) {
    final h = _sceneH = m.height;
    final out = switch (_run.station) {
      M4GateStation.doOpen || M4GateStation.oilTemp || M4GateStation.earth => _dtrLayers(h),
      M4GateStation.insulator || M4GateStation.jumper => _poleLayers(h),
      M4GateStation.dpDress => _dpLayers(h),
      M4GateStation.tree => _treeLayers(h),
      M4GateStation.streetLight => _streetLayers(h),
      M4GateStation.balance => _pillarLayers(h),
    };
    final spark = _sparkAt;
    return [
      // A tap on nothing (the sky, the road) counts toward the gesture hint.
      Positioned.fill(
        key: const ValueKey('scene-miss'),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onMissTap),
      ),
      ...out,
      if (spark != null)
        Positioned.fill(
          key: const ValueKey('spark'),
          child: IgnorePointer(child: CustomPaint(painter: M4GateSparkPainter(at: spark, big: _sparkBig))),
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
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
      );

  Widget _hitAt(String id, Rect r, void Function(Offset global) onTap) => Positioned.fromRect(
        key: ValueKey(id),
        rect: r,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => onTap(d.globalPosition)),
      );

  Widget _meter(Rect r, M4GateMeterKind kind) => Positioned.fromRect(
        key: ValueKey('meter-${kind.name}'),
        rect: r,
        child: IgnorePointer(child: CustomPaint(painter: M4GateMeterPainter(kind: kind, reading: _reading))),
      );

  List<Widget> _dtrLayers(double h) {
    final g = M4DtrGeo(h);
    final st = _run.station;
    final foot = switch (st) {
      M4GateStation.doOpen => switch (_run.stance) {
          M4GateStance.under => g.underSpot,
          M4GateStance.side => g.sideSpot,
          null => Offset(g.sideSpot.dx - 40, g.groundY),
        },
      M4GateStation.oilTemp => Offset(140, g.groundY),
      _ => Offset(132, g.groundY),
    };
    final stickTo = st != M4GateStation.doOpen ? null : (_stickTo ?? (_run.stance == null ? null : g.handsAt(foot).translate(26, -120)));
    final meterRect = Rect.fromLTWH(12, g.groundY - 170, 84, 104);
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M4DtrPainter(
                geo: g,
                doOpen: [..._run.doOpen],
                ltOn: _run.ltOn,
                oilLow: _run.oilLow,
                spikes: {..._run.spikes},
                wet: _run.pitWet,
                tight: _run.clampTight,
                tester: st == M4GateStation.earth,
              ),
            ),
          ),
        ),
      ),
      if (st == M4GateStation.doOpen) ...[
        for (final s in M4GateStance.values)
          _hit(
            'stand-${s.name}',
            Rect.fromCenter(center: (s == M4GateStance.under ? g.underSpot : g.sideSpot).translate(0, 10), width: 64, height: 34),
            () => _onStand(s),
            child: const _SpotMark(),
          ),
        if (stickTo != null)
          Positioned.fill(
            key: const ValueKey('stick'),
            child: IgnorePointer(child: CustomPaint(painter: M4GateStickPainter(from: g.handsAt(foot), to: stickTo))),
          ),
      ],
      _figure(g.figureAt(foot), st == M4GateStation.doOpen && _run.stance != null ? LinemanMode.hold : LinemanMode.idle),
      if (st == M4GateStation.doOpen) ...[
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
      ],
      if (st == M4GateStation.oilTemp) ...[
        _meter(meterRect, M4GateMeterKind.irGun),
        _hit('gauge', g.gauge.inflate(18), _onGauge),
        if (_run.gaugeRead)
          Positioned(
            key: const ValueKey('gauge-lens'),
            left: 108,
            top: g.groundY - 170,
            width: 56,
            height: 104,
            child: IgnorePointer(child: CustomPaint(painter: _GaugeLensPainter(low: _run.oilLow))),
          ),
      ],
      if (st == M4GateStation.earth) ...[
        _meter(meterRect, M4GateMeterKind.earthTester),
        for (var i = 0; i < 2; i++) _hit('spike-$i', g.spikeHit(i), () => _onSpike(i)),
        _hit('pit', g.pitHit, _onPit),
        _hit('clamp', g.clampHit, _onClamp),
      ],
    ];
  }

  List<Widget> _poleLayers(double h) {
    final g = M4PoleGeo(h);
    final ins = _run.station == M4GateStation.insulator;
    final up = ins ? _run.insDone.isNotEmpty : true;
    return [
      Positioned.fill(
        key: const ValueKey('pole'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M4PolePainter(
                geo: g,
                broken: ins ? _run.broken : null,
                replaced: _run.insDone.contains(M4InsStep.fitNew),
                earths: ins ? {..._run.earths} : const {0, 1},
                jumper: !ins,
                hotSide: _run.hotSide,
                clean: _run.jumperClean,
                tight: _run.jumperTight,
                roped: _run.insDone.contains(M4InsStep.rope) && !_run.insDone.contains(M4InsStep.fitNew),
              ),
            ),
          ),
        ),
      ),
      _figure(
        !ins ? Rect.fromLTWH(M4PoleGeo.poleX - 30, g.armY + 66, 59, 118) : (up ? g.poleFigure() : g.groundFigure()),
        up ? LinemanMode.hold : LinemanMode.idle,
      ),
      if (ins)
        for (var s = 0; s < 2; s++) _hitAt('earth-$s', g.earthHit(s), (p) => _onEarthSet(s, p))
      else
        for (var s = 0; s < 2; s++) _hit('jclamp-$s', g.clampHit(s), () => unawaited(_onClampSpot(s))),
      if (!ins && _run.hotFound)
        Positioned(
          key: const ValueKey('hot-mark'),
          left: g.clamp(_run.hotSide).dx - 18,
          top: g.clamp(_run.hotSide).dy - 18,
          width: 36,
          height: 36,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SlmColors.gold300, width: 2.4)),
            ),
          ),
        ),
    ];
  }

  List<Widget> _dpLayers(double h) {
    final g = M4DpGeo(h);
    return [
      Positioned.fill(
        key: const ValueKey('dp'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M4DpPainter(geo: g, fixed: {..._run.dpFixed}, nutsTight: _run.nutsTight)))),
      ),
      _figure(Rect.fromLTWH(M4DpGeo.poleR + 6, g.armY + 70, 59, 118), LinemanMode.hold),
      for (final f in M4DpFault.values)
        if (!_run.dpFixed.contains(f)) _hit('fault-${f.name}', g.faultHit(f), () => unawaited(_onDpFault(f))),
    ];
  }

  List<Widget> _treeLayers(double h) {
    final g = M4TreeGeo(h);
    return [
      Positioned.fill(
        key: const ValueKey('tree'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: M4TreePainter(geo: g, cordon: _run.cordoned, rope: _run.roped, cuts: _run.cutsDone.length)),
          ),
        ),
      ),
      _figure(Rect.fromLTWH(120, g.groundY - 100, 59, 118), _run.roped ? LinemanMode.hold : LinemanMode.idle),
    ];
  }

  List<Widget> _streetLayers(double h) {
    final g = M4StreetGeo(h);
    return [
      Positioned.fill(
        key: const ValueKey('street'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M4StreetPainter(geo: g, mcbOn: _run.mcbOn, lit: _run.lit, newLamp: _run.lampNew)))),
      ),
      _meter(Rect.fromLTWH(12, g.groundY - 170, 84, 104), M4GateMeterKind.tester),
      _figure(Rect.fromLTWH(M4StreetGeo.postX - 100, g.groundY - 112, 59, 118), _run.lampNew ? LinemanMode.hold : LinemanMode.idle),
      _hit('mcb', g.mcbHit, () => unawaited(_onMcb())),
    ];
  }

  List<Widget> _pillarLayers(double h) {
    final g = M4PillarGeo(h);
    final log = [
      for (var i = 0; i < 4; i++)
        if (_run.measured.contains(i)) '${M4GateRun.phaseNames[i]} ${_run.amps(i)}A',
    ];
    return [
      Positioned.fill(
        key: const ValueKey('pillar'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M4PillarPainter(geo: g, clampOn: _clampOn)))),
      ),
      _meter(Rect.fromLTWH(12, g.box.bottom + 18, 84, 100), M4GateMeterKind.tong),
      if (log.isNotEmpty)
        Positioned(
          key: const ValueKey('amp-log'),
          left: g.box.left + 14,
          top: g.box.bottom - 46,
          child: IgnorePointer(child: _AmpLog(lines: log)),
        ),
      for (var i = 0; i < 4; i++) _hit('wire-$i', g.cableHit(i), () => _onMeasure(i)),
    ];
  }

  // ============================================================================
  // Controls (screen pixels, page overlays)
  // ============================================================================

  Widget _row(String key, List<Widget> kids, double b, {double right = 12}) => Positioned(
        key: ValueKey(key),
        left: 12,
        right: right,
        bottom: b,
        child: Row(children: [for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: kids[i])]]),
      );

  /// The two buttons of a row in their dealt order, with [gap] between.
  List<Widget> _deal(bool flip, List<Widget> kids, {Widget? gap}) {
    final o = flip ? kids.reversed.toList() : kids;
    return [for (var i = 0; i < o.length; i++) ...[if (i > 0 && gap != null) gap, o[i]]];
  }

  List<Widget> _controls(EdgeInsets pad) {
    final b = pad.bottom + 12;
    switch (_run.station) {
      case M4GateStation.doOpen:
        return [
          Positioned(
            key: const ValueKey('ppe-row'),
            left: 12,
            bottom: b,
            child: Row(
              children: [
                _ToolButton(boxKey: _bk('ppe-shield'), icon: Icons.face_retouching_natural, label: M4GateLines.faceShield, on: _run.faceShield, onTap: () => _onWear(shield: true)),
                const SizedBox(width: 8),
                _ToolButton(boxKey: _bk('ppe-gloves'), icon: Icons.back_hand_rounded, label: M4GateLines.gloves, on: _run.doGloves, onTap: () => _onWear(shield: false)),
              ],
            ),
          ),
        ];
      case M4GateStation.oilTemp:
        return [
          Positioned(
            key: const ValueKey('temp-row'),
            left: 12,
            bottom: b + 160,
            child: Row(
              children: _deal(_run.flipTemp, [
                _ToolButton(boxKey: _bk('temp-ir'), icon: Icons.thermostat_rounded, label: M4GateLines.irGun, on: _run.tempRead, onTap: () => unawaited(_onTemp(ir: true))),
                _ToolButton(boxKey: _bk('temp-hand'), icon: Icons.back_hand_rounded, label: M4GateLines.handOnTank, on: false, onTap: () => unawaited(_onTemp(ir: false))),
              ], gap: const SizedBox(width: 8)),
            ),
          ),
          Positioned(
            key: const ValueKey('oil-row'),
            left: 12,
            right: 130,
            bottom: b,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in M4OilCall.values) ...[
                  _ActionButton(key: ValueKey('oil-${c.name}'), boxKey: _bk('oil-${c.name}'), label: M4GateLines.oilCalls[c]!, compact: true, onTapUp: (p) => unawaited(_onOilCall(c, p))),
                  if (c != M4OilCall.values.last) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ];
      case M4GateStation.earth:
        return [
          _row('earth-row', _deal(_run.flipEarth, [
            _ActionButton(key: const ValueKey('earth-test'), boxKey: _bk('earth-test'), label: M4GateLines.test, mono: true, onTapUp: (_) => unawaited(_onEarthTest())),
            _ActionButton(key: const ValueKey('earth-ok'), boxKey: _bk('earth-ok'), label: M4GateLines.earthOk, onTapUp: (p) => unawaited(_onEarthOk(p))),
          ]), b, right: 130),
        ];
      case M4GateStation.insulator:
        final o = _run.insOrder;
        return [
          Positioned(
            key: const ValueKey('ins-grid'),
            left: 12,
            right: 130,
            bottom: b,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < 2; r++) ...[
                  if (r > 0) const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var k = 0; k < 2; k++) ...[
                        if (k > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _ActionButton(
                            key: ValueKey('ins-${o[r * 2 + k].name}'), boxKey: _bk('ins-${o[r * 2 + k].name}'),
                            label: M4GateLines.steps[o[r * 2 + k]]!,
                            done: _run.insDone.contains(o[r * 2 + k]),
                            compact: true,
                            onTapUp: (p) => unawaited(_onInsStep(o[r * 2 + k], p)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ];
      case M4GateStation.jumper:
        if (!_run.hotFound) return const [];
        return [
          Positioned(
            key: const ValueKey('jumper-col'),
            left: 12,
            right: 130,
            bottom: b,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in _run.jumperOpts) ...[
                  _ActionButton(
                    key: ValueKey('jumper-${a.name}'), boxKey: _bk('jumper-${a.name}'),
                    label: M4GateLines.jumperActs[a]!,
                    done: a == M4JumperAct.brush && _run.jumperClean,
                    compact: true,
                    onTapUp: (p) => unawaited(_onJumper(a, p)),
                  ),
                  if (a != _run.jumperOpts.last) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ];
      case M4GateStation.dpDress:
        return [
          _row('dp-row', _deal(_run.flipDp, [
            _ActionButton(key: const ValueKey('dp-nuts'), boxKey: _bk('dp-nuts'), label: M4GateLines.nuts, done: _run.nutsTight, onTapUp: (_) => _onNuts()),
            _ActionButton(key: const ValueKey('dp-done'), boxKey: _bk('dp-done'), label: M4GateLines.dpDone, onTapUp: (p) => unawaited(_onDpDone(p))),
          ]), b, right: 130),
        ];
      case M4GateStation.tree:
        final o = _run.cutOpts;
        return [
          Positioned(
            key: const ValueKey('tree-grid'),
            left: 12,
            right: 130,
            bottom: b,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _ActionButton(key: const ValueKey('tree-cordon'), boxKey: _bk('tree-cordon'), label: M4GateLines.cordon, done: _run.cordoned, compact: true, onTapUp: (_) => _onCordon())),
                    const SizedBox(width: 6),
                    Expanded(child: _ActionButton(key: const ValueKey('tree-rope'), boxKey: _bk('tree-rope'), label: M4GateLines.rope, done: _run.roped, compact: true, onTapUp: (_) => _onRope())),
                  ],
                ),
                for (var r = 0; r < 2; r++) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var k = 0; k < 2; k++) ...[
                        if (k > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _ActionButton(
                            key: ValueKey('cut-${o[r * 2 + k].name}'), boxKey: _bk('cut-${o[r * 2 + k].name}'),
                            label: M4GateLines.cuts[o[r * 2 + k]]!,
                            done: _run.cutsDone.contains(o[r * 2 + k]),
                            compact: true,
                            onTapUp: (p) => unawaited(_onCut(o[r * 2 + k], p)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ];
      case M4GateStation.streetLight:
        return [
          _row('lamp-row', _deal(_run.flipLamp, [
            _ActionButton(key: const ValueKey('lamp-test'), boxKey: _bk('lamp-test'), label: M4GateLines.tester, onTapUp: (_) => _onTester()),
            _ActionButton(key: const ValueKey('lamp-new'), boxKey: _bk('lamp-new'), label: M4GateLines.newLamp, done: _run.lampNew, onTapUp: (_) => unawaited(_onLamp())),
          ]), b, right: 130),
        ];
      case M4GateStation.balance:
        final heavy = M4GateRun.phaseNames[_run.heavy];
        final light = M4GateRun.phaseNames[_run.light];
        if (_run.balShifted) {
          return [
            _row('bal-done-row', [
              _ActionButton(key: const ValueKey('bal-ok'), boxKey: _bk('bal-ok'), label: M4GateLines.balanced, onTapUp: (p) => unawaited(_onBalanced(p))),
            ], b, right: 130),
          ];
        }
        if (!_run.allMeasured) return const [];
        final o = _run.balOpts;
        return [
          Positioned(
            key: const ValueKey('bal-grid'),
            left: 12,
            right: 130,
            bottom: b,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < 2; r++) ...[
                  if (r > 0) const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var k = 0; k < 2; k++) ...[
                        if (k > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _ActionButton(
                            key: ValueKey('bal-${o[r * 2 + k].name}'),
                            boxKey: _bk('bal-${o[r * 2 + k].name}'),
                            label: M4GateLines.balCall(o[r * 2 + k], heavy, light),
                            compact: true,
                            onTapUp: (_) => unawaited(_onBalCall(o[r * 2 + k])),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ];
    }
  }

  double _guideBottom(EdgeInsets pad, bool deckUp) {
    if (deckUp) return pad.bottom + 236;
    return pad.bottom +
        switch (_run.station) {
          M4GateStation.oilTemp => 150,
          M4GateStation.insulator => 112,
          M4GateStation.jumper => _run.hotFound ? 150 : 72,
          M4GateStation.tree => 166,
          M4GateStation.balance => _run.allMeasured && !_run.balShifted ? 112 : 72,
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
    // The death freeze takes in every touch: no controls, no docket chip.
    final handsOn = playing && !deckUp && !_docketOpen && !_freeze && !_ended;

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
              labels: [for (final s in M4GateStation.values) M4GateLines.stationTitles[s]!],
              done: {for (final s in _run.completed) s.index},
              current: _run.done ? null : _run.station.index,
              quiet: quiet,
            ),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: '${_run.station.index}:$_wake:$_docketOpen',
            hintController: _hints,
            layers: (c, m) => [
              Positioned.fill(
                key: const ValueKey('scene'),
                child: ColorFiltered(
                  colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                  child: Stack(key: _sceneKey, children: _layers(c, m)),
                ),
              ),
            ],
            overlays: [
              if (_freeze && _card == null)
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
              if (playing && !_freeze && !_ended)
                Positioned(
                  key: const ValueKey('station-chip'),
                  top: pad.top + 86,
                  right: 12,
                  child: _StationChip(
                    num: 'কাজ ${_run.station.index + 1}/${M4GateStation.values.length}',
                    title: M4GateLines.stationTitles[_run.station]!,
                    onDocket: () {
                      // Not while praise, the reason deck or the coworker is up.
                      if (!_canAct) return;
                      _cue('sounds/learn/card_deal_a.ogg', volume: 0.8);
                      setState(() => _docketOpen = true);
                    },
                  ),
                ),
              if (handsOn) ..._controls(pad),
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
                              lessonId: M4GateMistakes.lessonOf(_card!),
                              point: _card!.lessonPoint,
                              muted: _muted,
                            ),
                          ),
                  onGo: _dismissCard,
                ),
              if (struckOut && _card == null)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy ?? M4GateMistakes.earthHigh,
                  lessonId: M4GateMistakes.lessonOf(strikeOutBy ?? M4GateMistakes.earthHigh),
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
                  line: M4GateLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
                  muted: _muted,
                  onDone: () => unawaited(_start()),
                ),
              if (_docketOpen && !_intro)
                Positioned.fill(
                  key: const ValueKey('docket-modal'),
                  child: _DocketSheet(
                    buttonKey: _docketBtnKey,
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

/// The conservator's glass gauge, close up: MAX, MIN and the oil level.
class _GaugeLensPainter extends CustomPainter {
  const _GaugeLensPainter({required this.low});
  final bool low;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    canvas.drawRRect(r, Paint()..color = const Color(0xE60A1324));
    canvas.drawRRect(
      r,
      Paint()
        ..color = SlmColors.gold400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final tube = Rect.fromLTWH(size.width * 0.5, 10, 14, size.height - 20);
    canvas.drawRRect(RRect.fromRectAndRadius(tube, const Radius.circular(4)), Paint()..color = const Color(0xFFE8F1F4));
    final level = low ? tube.bottom - tube.height * 0.1 : tube.top + tube.height * 0.48;
    canvas.drawRect(Rect.fromLTRB(tube.left, level, tube.right, tube.bottom), Paint()..color = const Color(0xFFC9962B));
    final maxY = tube.top + tube.height * 0.18;
    final minY = tube.bottom - tube.height * 0.25;
    final mark = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 1.6;
    for (final (y, t) in [(maxY, 'MAX'), (minY, 'MIN')]) {
      canvas.drawLine(Offset(tube.left - 4, y), Offset(tube.right + 4, y), mark);
      final tp = TextPainter(
        text: TextSpan(text: t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(tube.left - tp.width - 5, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GaugeLensPainter old) => old.low != low;
}

/// The tong-tester readings written down at the pillar.
class _AmpLog extends StatelessWidget {
  const _AmpLog({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFF9F7F0), borderRadius: BorderRadius.circular(6)),
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          children: [
            for (final l in lines) Text(l, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
          ],
        ),
      );
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
  const _ToolButton({required this.icon, required this.label, required this.on, required this.onTap, this.boxKey});
  final GlobalKey? boxKey;
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: boxKey,
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
                  color: on ? const Color(0xFF1E5A33) : const Color(0xFF14233A),
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
  const _ActionButton({super.key, required this.label, required this.onTapUp, this.mono = false, this.done = false, this.compact = false, this.boxKey});
  final GlobalKey? boxKey;
  final String label;
  final ValueChanged<Offset> onTapUp;
  final bool mono;
  final bool done;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: boxKey,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTapUp(d.globalPosition),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 4 : 6),
          decoration: BoxDecoration(
            color: done ? const Color(0xE61E5A33) : const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: done ? const Color(0xFF41C463) : SlmColors.gold400, width: 1.6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: mono
                ? const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory, letterSpacing: 0.5)
                : bangla(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w900, color: SlmColors.ivory),
          ),
        ),
      ),
    );
  }
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
            const Icon(Icons.settings_rounded, color: SlmColors.gold300),
            const SizedBox(width: 8),
            Flexible(
              child: Text(M4GateLines.rankStamp, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ),
          ],
        ),
      );
}

class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.onClose, this.buttonKey});
  final VoidCallback onClose;
  final GlobalKey? buttonKey;

  static const _rows = [
    (Icons.place_rounded, 'ফিডার', '11 kV বটতলা ফিডার · DTR-23 আর তার সেকশন', Color(0xFF1565C0)),
    (Icons.build_circle_rounded, 'কাজ', 'DTR-এর DO খোলা, তেল-তাপ ও আর্থ টেস্ট · ভাঙা ইনসুলেটর · গরম জাম্পার · ডিপি ড্রেসিং · লাইনের ধারে ডাল · মোড়ের স্ট্রিট লাইট · LT ফেজ ব্যালেন্স', Color(0xFFC62828)),
    (Icons.power_off_rounded, 'শাটডাউন', 'DTR: হট স্টিকে তিনটে DO খুলে · 11 kV সেকশন: লিখিত PTW, দুই দিকে আর্থ · LT: শাটডাউন নিয়ে', Color(0xFFE65100)),
    (Icons.handyman_rounded, 'হাতিয়ার', 'হট স্টিক, IR থার্মোমিটার, আর্থ টেস্টার ও স্পাইক, আর্থিং সেট, দড়ি, স্টিল ব্রাশ ও পেস্ট, দুটো রেঞ্চ, করাত, টেস্টার, টং টেস্টার', Color(0xFF2E7D32)),
    (Icons.verified_user_rounded, 'সুরক্ষা', 'হেলমেট, হার্নেস, ইনসুলেটেড গ্লাভস, ফেস শিল্ড · মৃত প্রমাণ ও আর্থ ছাড়া লাইনে হাত নয়', Color(0xFF6A1B9A)),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
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
                            Text('স্কিলডের ডকেট', style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text('ডকেট নং: DKT-MNT-4410 · রক্ষণাবেক্ষণের দিন', style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: SlmColors.gold300)),
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
                        key: buttonKey,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const ValueKey('docket-close'),
                          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                          label: Text(M4GateLines.docketClose, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
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
    );
  }
}
