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
import 'm3_gate_field_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;

// Module 3 Rank Gate (rung m3/gate, pack gate_m3): "টেকনিশিয়ানের ডকেট".
// One continuous job across feeder-7 that uses the whole of Module 3
// (lessons 3.1–3.10), in seven stations:
//   1 SLD পড়া — ring the isolation points on the diagram: AB-1 and the ring
//     tie's NO point (dealt at the far end or mid-feeder); a wrong symbol is a
//     slip, forgetting the NO point is deadly (backfeed) (3.10).
//   2 লাইন পেট্রোল — judge five parts of the span (pin insulator, clamp,
//     conductor strands, disc string, cross-arm); three are dealt faulty (3.1–3.3).
//   3 DO ও LA — one DO has dropped out: open the other two, pick the rated
//     fuse link (thick wire deadly), judge the LA (dealt healthy / cracked /
//     hanging disconnector lead) (3.4, 3.5).
//   4 DTR — judge the silica gel and the oil, LT OFF, then the off-load tap
//     change; the careless coworker pushes "the HT DOs are open, skip the LT" (3.6).
//   5 ফিডার পিলার — gloves + face shield, prove dead with the tester, a
//     same-rating HRC fuse in the blown way (copper strip deadly), tighten the
//     hot spot, lock the door (3.7, 3.10).
//   6 সার্ভিস ড্রপ — four choices on a deck, one per step: twin/four core to
//     match the connection, bearer wire, drip loop, neutral with gloves (a
//     bare hand deadly) (3.8).
//   7 ক্রেডল গার্ডিং — gloves (bare hand deadly), find the dealt fault (an
//     earth lead cut, or a broken wire), then the line goes back on (3.9).
// Every over-call (a sound part flagged, a sound fuse pulled, a sound bolt or
// guard spot worked on) is a slip; the guide never says "this one is fine"
// before the decision. The careless coworker can't be skipped: the LT switch
// and the tap wait for him (holdForCoworker). A gesture hint shows how to
// touch in every waiting state (a sweep over the choices).
// Passing awards the Technician ("টেকনিশিয়ান") rank (unlockRank(3)) and the
// "লাইন চেনার জাদুকর" badge of Module 3.

// ============================================================================
// Content
// ============================================================================

@immutable
class M3GateFieldPack {
  const M3GateFieldPack({required this.id, required this.titleBn, this.quickMs = 300000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3GateFieldPacks = {
  'gate_m3': M3GateFieldPack(id: 'gate_m3', titleBn: M3GateLines.title),
};

enum M3GateStation { sld, patrol, fuseLa, dtr, pillar, service, guard }

/// The fuse links on offer at the DO.
enum M3Link { rated, thickWire, anyWire, overRated }

/// The HRC replacements at the feeder pillar.
enum M3Hrc { same, bigger, copperStrip }

/// What the player looks at up close.
enum M3Look { pin, clamp, strand, disc, arm, la, gel, oil }

const _art = 'assets/game/art/m3_gate_field';

abstract final class M3GateMistakes {
  static const ringBackfeed = DoMistake(
    key: '3.10/m3_gate_field/ring-no',
    textBn: 'রিং ফিডারে উল্টো দিক থেকেও বিদ্যুৎ আসে — NO পয়েন্টও আইসোলেশন পয়েন্ট। ডায়াগ্রামেই ব্যাকফিড ধরা পড়ে।',
    art: '$_art/ring_backfeed.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const sourceAb = DoMistake(
    key: '3.10/m3_gate_field/source-ab',
    textBn: 'উৎসের দিকের আইসোলেটর AB-1-ও আইসোলেশন পয়েন্ট — ডায়াগ্রামে চিহ্নিত করুন। আইসোলেটর কখনো অন-লোডে খোলা যায় না।',
    art: '$_art/ring_backfeed.svg',
    lessonPoint: 2,
  );
  static const wrongSymbol = DoMistake(
    key: '3.10/m3_gate_field/wrong-symbol',
    textBn: 'আইসোলেটর মানে সরলরেখায় কাটা লাইন। দুটি কুণ্ডলী ট্রান্সফরমার, তীর-বক্স LA, সমান্তরাল দাগ আর্থ।',
    art: '$_art/sld_symbols.svg',
    lessonPoint: 1,
  );
  static const insChip = DoMistake(
    key: '3.2/m3_gate_field/insulator-chip',
    textBn: 'কোণা ভাঙা ইনসুলেটর বদলাতেই হবে — ভাঙা খাঁজে জল-ধুলো জমে লিকেজ শুরু হয়।',
    art: '$_art/insulator_chip.svg',
    lessonPoint: 0,
  );
  static const discCrack = DoMistake(
    key: '3.2/m3_gate_field/disc-crack',
    textBn: 'ডিস্কের সরু চুলের মতো ফাটল উপেক্ষা নয় — হাই-ভোল্টেজে ওই ফাটল দিয়েই ব্লাস্ট হয়।',
    art: '$_art/disc_crack.svg',
    lessonPoint: 3,
  );
  static const armRust = DoMistake(
    key: '3.3/m3_gate_field/arm-rust',
    textBn: 'মরিচা ধরা ক্রস-আর্ম ফল্ট — মরিচা ভেতর থেকে শক্তি শেষ করে। ওতে দাঁড়াবেন না, হারনেসও আটকাবেন না।',
    art: '$_art/arm_rust.svg',
    lessonPoint: 3,
  );
  static const armBent = DoMistake(
    key: '3.3/m3_gate_field/arm-bent',
    textBn: 'বাঁকা ক্রস-আর্ম ফেজ ক্লিয়ারেন্স কমায় — ফল্ট লিখুন। বাঁকা আর্মে দাঁড়াবেন না, হারনেসও নয়।',
    art: '$_art/arm_rust.svg',
    lessonPoint: 3,
  );
  static const clampSlip = DoMistake(
    key: '3.3/m3_gate_field/clamp-slip',
    textBn: 'পোল বরাবর পিছলে নামা ক্ল্যাম্প ফল্ট — ঢিলা বা ভুল ক্ল্যাম্পে ক্রস-আর্ম হেলে পড়ে।',
    art: '$_art/clamp_slip.svg',
    lessonPoint: 3,
  );
  static const strandCut = DoMistake(
    key: '3.1/m3_gate_field/strand-cut',
    textBn: 'একটা স্ট্র্যান্ড কাটা মানেই লাইনের শক্তি কমা — ওখান থেকেই পরে তার ছেঁড়ে। ফল্ট লিখুন।',
    art: '$_art/strand_cut.svg',
    lessonPoint: 1,
  );
  static const soundFlagged = DoMistake(
    key: '3.3/m3_gate_field/sound-flagged',
    textBn: 'খুঁত চোখে না দেখে ফল্ট নয় — ফাটল, মরিচা, বাঁকা, পিছলে নামা বা কাটা স্ট্র্যান্ড খুঁজে তবেই রায়।',
    art: '$_art/arm_rust.svg',
    lessonPoint: 3,
  );
  static const allThree = DoMistake(
    key: '3.4/m3_gate_field/all-three',
    textBn: 'থ্রি-ফেজ ট্রান্সফরমারে একটা ফিউজ উড়লে বাকি দুটো ফেজের DO-ও খুলুন — তবেই ট্রান্সফরমার পুরো বিচ্ছিন্ন।',
    art: '$_art/do_all_three.svg',
    lessonPoint: 0,
  );
  static const thickWire = DoMistake(
    key: '3.4/m3_gate_field/thick-wire',
    textBn: 'ফিউজের জায়গায় মোটা তার আত্মহত্যার সামিল — ফল্টে ফিউজ না উড়ে ট্রান্সফরমার-লাইন পুড়বে।',
    art: '$_art/fuse_link.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const anyWire = DoMistake(
    key: '3.4/m3_gate_field/any-wire',
    textBn: 'যেকোনো ধাতব তারে ফিউজ লিঙ্ক হয় না — মাপা গলনাঙ্কের পরীক্ষিত লিঙ্কই একমাত্র সুরক্ষা।',
    art: '$_art/fuse_link.svg',
    lessonPoint: 3,
  );
  static const overRated = DoMistake(
    key: '3.4/m3_gate_field/over-rated',
    textBn: 'ট্রান্সফরমারের নেমপ্লেট মিলিয়ে সঠিক অ্যাম্পিয়ার রেটিংয়ের লিঙ্ক — বড় রেটিংয়ে সুরক্ষা থাকে না।',
    art: '$_art/fuse_link.svg',
    lessonPoint: 3,
  );
  static const laCrack = DoMistake(
    key: '3.5/m3_gate_field/la-crack',
    textBn: 'ফাটা বা পোড়া দাগের LA বদলাতে হবে — বড় সার্জ সয়ে ওটা নষ্ট, পরের বাজে ট্রান্সফরমার বাঁচবে না।',
    art: '$_art/la_check.svg',
    lessonPoint: 2,
  );
  static const laHanging = DoMistake(
    key: '3.5/m3_gate_field/la-hanging',
    textBn: 'ঝুলে থাকা আর্থিং তার মানে ডিসকানেক্টর খুলে গেছে — LA খারাপ, বদলাতে হবে।',
    art: '$_art/la_check.svg',
    lessonPoint: 2,
  );
  static const laSound = DoMistake(
    key: '3.5/m3_gate_field/la-sound',
    textBn: 'সুস্থ LA: আবরণে ফাটল বা পোড়া দাগ নেই, আর্থিং তার মজবুত জোড়া — তাহলে বদলানোর দরকার নেই।',
    art: '$_art/la_check.svg',
    lessonPoint: 2,
  );
  static const gelPink = DoMistake(
    key: '3.6/m3_gate_field/gel-pink',
    textBn: 'গোলাপি সিলিকা জেল মানে বাষ্প শুষে ভিজে গেছে — বদলাতে হবে। শুকনো জেল নীল।',
    art: '$_art/dtr_health.svg',
    lessonPoint: 2,
  );
  static const oilLeak = DoMistake(
    key: '3.6/m3_gate_field/oil-leak',
    textBn: 'তেল লিক উপেক্ষা নয় — লেভেল কমলে কুলিং ও ইনসুলেশন দুর্বল হয়, লিক দিয়ে জলীয় বাষ্প ঢোকে।',
    art: '$_art/dtr_health.svg',
    lessonPoint: 2,
  );
  static const gelDry = DoMistake(
    key: '3.6/m3_gate_field/gel-dry',
    textBn: 'শুকনো সিলিকা জেল নীল বা কমলা — বদলাতে হয় গোলাপি বা সাদা হলে। রং দেখে তবেই রায়।',
    art: '$_art/dtr_health.svg',
    lessonPoint: 2,
  );
  static const oilDry = DoMistake(
    key: '3.6/m3_gate_field/oil-dry',
    textBn: 'লিক মানে গ্যাসকেট, জয়েন্ট বা ড্রেন ভাল্ভে তেলের দাগ — দাগ না দেখে লিক লেখা নয়।',
    art: '$_art/dtr_health.svg',
    lessonPoint: 2,
  );
  static const tapLive = DoMistake(
    key: '3.6/m3_gate_field/tap-live',
    textBn: 'অফ-লোড ট্যাপ চেঞ্জার ঘোরানো যায় শুধু HT ও LT দুদিক বন্ধ করে — LT চালু রেখে ঘোরানো মারাত্মক।',
    art: '$_art/tap_offload.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const coworkerLt = DoMistake(
    key: '3.6/m3_gate_field/coworker-lt',
    textBn: 'শুধু HT-র DO খোলা যথেষ্ট নয় — ট্যাপ বদলের আগে LT দিকও বন্ধ, দুদিক বন্ধ করে তবেই।',
    art: '$_art/tap_offload.svg',
    lessonPoint: 1,
  );
  static const pillarPpe = DoMistake(
    key: '3.7/m3_gate_field/pillar-ppe',
    textBn: 'সম্পূর্ণ পিপিই আর ইনসুলেটেড টুল ছাড়া ফিডার পিলারে হাত নয় — ফল্ট কারেন্টে আর্ক ফ্ল্যাশ মুহূর্তে পোড়ায়।',
    art: '$_art/pillar_ppe.svg',
    lessonPoint: 2,
  );
  static const noTest = DoMistake(
    key: '3.10/m3_gate_field/no-test',
    textBn: 'বন্ধ জানলেও কাজের আগে টেস্টার দিয়ে যাচাই — ম্যাপ বা কথা নয়, পরীক্ষাই প্রমাণ।',
    art: '$_art/pillar_ppe.svg',
    lessonPoint: 0,
  );
  static const copperStrip = DoMistake(
    key: '3.7/m3_gate_field/copper-strip',
    textBn: 'ফিউজের বদলে তামার পাত ভয়ঙ্কর — ফল্টে ফিউজ না উড়ে কেবিল আর ট্রান্সফরমার পুড়ে ছাই।',
    art: '$_art/hrc_fuse.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const hrcBigger = DoMistake(
    key: '3.7/m3_gate_field/hrc-bigger',
    textBn: 'একই রেটিংয়ের HRC ফিউজ — রেটিং যাকে বাঁচাচ্ছে তার মাপে; বড় রেটিংয়ে কেবিল বাঁচে না।',
    art: '$_art/hrc_fuse.svg',
    lessonPoint: 1,
  );
  static const wrongFuse = DoMistake(
    key: '3.7/m3_gate_field/wrong-fuse',
    textBn: 'প্রতিটা আউটগোয়িং লাইনের আলাদা ফিউজ — ভালো ফিউজ টানলে চালু লাইন অকারণে বন্ধ। উড়ে যাওয়াটা চিনে হাত দিন।',
    art: '$_art/hrc_fuse.svg',
    lessonPoint: 1,
  );
  static const wrongBolt = DoMistake(
    key: '3.7/m3_gate_field/wrong-bolt',
    textBn: 'হটস্পট চেনা যায় কালো হয়ে যাওয়া কানেকশনে — সেটা খুঁজে টাইট করুন, আন্দাজে নয়।',
    art: '$_art/hotspot.svg',
    lessonPoint: 2,
  );
  static const hotspot = DoMistake(
    key: '3.7/m3_gate_field/hotspot',
    textBn: 'কালো দাগ মানে ঢিলা কানেকশনের হটস্পট — টাইট না করে দরজা বন্ধ নয়, ওখানেই স্পার্ক আর আগুন।',
    art: '$_art/hotspot.svg',
    lessonPoint: 2,
  );
  static const wrongCore = DoMistake(
    key: '3.8/m3_gate_field/wrong-core',
    textBn: 'সার্ভিস কেবিল ইনসুলেটেড — সিঙ্গেল-ফেজে টুইন-কোর, থ্রি-ফেজে ফোর-কোর। সংযোগ দেখে মিলিয়ে নিন।',
    art: '$_art/service_drop.svg',
    lessonPoint: 0,
  );
  static const noBearer = DoMistake(
    key: '3.8/m3_gate_field/no-bearer',
    textBn: 'সার্ভিস কেবিলের ওপর টান নয় — সব টান নেবে বিয়ারার (GI) তার, নইলে কেবিল ছিঁড়ে যায়।',
    art: '$_art/service_drop.svg',
    lessonPoint: 0,
  );
  static const noDrip = DoMistake(
    key: '3.8/m3_gate_field/no-drip',
    textBn: 'মিটারে ঢোকার আগে U আকৃতির ড্রিপ লুপ — নইলে বৃষ্টির জল কেবিল বেয়ে মিটারে ঢোকে।',
    art: '$_art/service_drop.svg',
    lessonPoint: 0,
  );
  static const neutralBare = DoMistake(
    key: '3.8/m3_gate_field/neutral-bare',
    textBn: 'নিউট্রাল খালি হাতে নয় — আনব্যালেন্স বা ফল্টে নিউট্রালেও ফেজের সমান প্রাণঘাতী ভোল্টেজ থাকে।',
    art: '$_art/neutral_gloves.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const guardBare = DoMistake(
    key: '3.9/m3_gate_field/guard-bare',
    textBn: 'গার্ডিং-এর তার খালি হাতে নয় — আর্থিং নষ্ট থাকলে পুরো জাল লাইভ। সবসময় লাইভ ধরে কাজ।',
    art: '$_art/guard_live.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const guardEarth = DoMistake(
    key: '3.9/m3_gate_field/guard-earth',
    textBn: 'গার্ডিং-এর আর্থিং কাটা রেখে লাইন চালু নয় — তখন জাল সুরক্ষা নয়, মারণফাঁদ। জুড়ে পাইপে ঢাকুন।',
    art: '$_art/guard_live.svg',
    lessonPoint: 3,
  );
  static const guardWire = DoMistake(
    key: '3.9/m3_gate_field/guard-wire',
    textBn: 'গার্ডিং-এর একটা তার ছিঁড়লেও পুরো কাঠামো দুর্বল — ঝুলে লাইভ তার ছুঁতে পারে। আগে মেরামত।',
    art: '$_art/guard_live.svg',
    lessonPoint: 3,
  );

  static const guardSpot = DoMistake(
    key: '3.9/m3_gate_field/guard-spot',
    textBn: 'আগে দেখে নিন ক্ষতি কোথায় — ছেঁড়া তার, না কাটা আর্থিং। আন্দাজে জালে হাত দেওয়া নয়।',
    art: '$_art/guard_live.svg',
    lessonPoint: 3,
  );

  static const all = [
    ringBackfeed,
    sourceAb,
    wrongSymbol,
    insChip,
    discCrack,
    armRust,
    armBent,
    clampSlip,
    strandCut,
    soundFlagged,
    allThree,
    thickWire,
    anyWire,
    overRated,
    laCrack,
    laHanging,
    laSound,
    gelPink,
    oilLeak,
    gelDry,
    oilDry,
    tapLive,
    coworkerLt,
    pillarPpe,
    noTest,
    copperStrip,
    hrcBigger,
    wrongFuse,
    wrongBolt,
    hotspot,
    wrongCore,
    noBearer,
    noDrip,
    neutralBare,
    guardBare,
    guardEarth,
    guardWire,
    guardSpot,
  ];

  /// The lesson that teaches a mistake (its key starts with the lesson id).
  static String lessonOf(String key) => key.split('/').first;

  static DoMistake forFault(M3Fault f) => switch (f) {
        M3Fault.chip => insChip,
        M3Fault.crack => discCrack,
        M3Fault.rust => armRust,
        M3Fault.bent => armBent,
        M3Fault.slipped => clampSlip,
        M3Fault.cut => strandCut,
      };
}

abstract final class M3GateLines {
  static const title = 'টেকনিশিয়ানের ডকেট · র‍্যাঙ্ক গেট';
  static const intro = 'টেকনিশিয়ানের ডকেট! ফিডার-7-এ DO উড়েছে, পাড়ায় কম ভোল্টেজ। ম্যাপ পড়ে, লাইন চিনে নিরাপদে সারান — পারলেই টেকনিশিয়ান!';

  /// The task per station; a tap on the guide says the next wording.
  static const tasks = {
    M3GateStation.sld: [
      'আগে ডায়াগ্রাম। কোথায় কোথায় বিচ্ছিন্ন করবেন — চিহ্নিত করুন।',
      'SLD দেখে আইসোলেশন পয়েন্টগুলো গোল করুন।',
      'বিদ্যুৎ কোন কোন দিক থেকে আসতে পারে? ম্যাপে খুঁজুন।',
    ],
    M3GateStation.patrol: [
      'এবার পেট্রোল। প্রতিটা অংশ কাছ থেকে দেখে রায় দিন।',
      'ইনসুলেটর, ক্ল্যাম্প, তার, ক্রস-আর্ম — একে একে দেখুন।',
      'কোনটা ঠিক, কোনটা ফল্ট — ভালো করে দেখে লিখুন।',
    ],
    M3GateStation.fuseLa: [
      'DTR-17-এর একটা DO ঝুলে পড়েছে। ট্রান্সফরমার সামলান।',
      'ফিউজ উড়েছে। এবার নিয়ম মেনে কী করবেন?',
      'ট্রান্সফরমারের মাথাটা ভালো করে দেখে সামলান।',
    ],
    M3GateStation.dtr: [
      'এবার ট্রান্সফরমারের স্বাস্থ্য দেখে ট্যাপ বদলান।',
      'ডাক্তারের মতো DTR দেখুন, তারপর ট্যাপ।',
      'জেল, তেল দেখুন — তারপর নিরাপদে ট্যাপ।',
    ],
    M3GateStation.pillar: [
      'ফিডার পিলারে একটা ফিউজ উড়েছে। ঠিক করুন।',
      'পিলারের ভেতর কাজ। আগে নিজের সুরক্ষা।',
      'পিলারের ভেতরটা ভালো করে দেখে সারান।',
    ],
    M3GateStation.service: [
      'নতুন সংযোগ। পোল থেকে বাড়ির মিটারে সার্ভিস কেবিল দিন।',
      'শেষ মাইল জুড়ুন — নিয়ম মেনে।',
      'কেবিল, টান, মিটারে ঢোকা — ধাপে ধাপে।',
    ],
    M3GateStation.guard: [
      'শেষ কাজ। রাস্তার ওপরের গার্ডিং দেখে লাইন চালু করুন।',
      'জালটা ঠিক আছে তো? খুঁটিয়ে দেখুন।',
      'গার্ডিং ঠিক না করে লাইন চালু নয়।',
    ],
  };

  static const stationTitles = {
    M3GateStation.sld: 'SLD পড়া',
    M3GateStation.patrol: 'লাইন পেট্রোল',
    M3GateStation.fuseLa: 'DO ও LA',
    M3GateStation.dtr: 'DTR ও ট্যাপ',
    M3GateStation.pillar: 'ফিডার পিলার',
    M3GateStation.service: 'সার্ভিস ড্রপ',
    M3GateStation.guard: 'ক্রেডল গার্ডিং',
  };

  static const lookNames = {
    M3Look.pin: 'পিন ইনসুলেটর',
    M3Look.clamp: 'ক্ল্যাম্প',
    M3Look.strand: 'কন্ডাক্টর',
    M3Look.disc: 'ডিস্ক ইনসুলেটর',
    M3Look.arm: 'ক্রস-আর্ম',
    M3Look.la: 'লাইটনিং অ্যারেস্টার',
    M3Look.gel: 'ব্রিদারের সিলিকা জেল',
    M3Look.oil: 'ট্যাঙ্কের নিচ',
  };

  static const okLabel = 'ঠিক আছে';
  static const docketOk = 'ডকেট বুঝে নিলাম';
  static const faultLabel = 'ফল্ট লিখুন';
  static const replaceLabel = 'বদলাতে হবে';
  static const leakLabel = 'লিক লিখুন';
  static const planOk = 'পরিকল্পনা পাকা';
  static const markFirst = 'আগে ডায়াগ্রামে আইসোলেশন পয়েন্ট গোল করুন।';
  static const openOthers = 'বাকি DO-গুলোর কী হবে?';
  static const linkQ = 'ফিউজ লিঙ্ক';
  static const linkNames = {
    M3Link.rated: 'নেমপ্লেট-মাফিক লিঙ্ক',
    M3Link.thickWire: 'মোটা তামার তার',
    M3Link.anyWire: 'সাধারণ GI তার',
    M3Link.overRated: 'দ্বিগুণ রেটিংয়ের লিঙ্ক',
  };
  static const healthFirst = 'আগে ট্রান্সফরমারের জেল আর তেল দেখে নিন।';
  static const gloves = 'ইনসুলেটেড গ্লাভস';
  static const faceShield = 'ফেস শিল্ড';
  static const doorFirst = 'আগে পিলারের দরজা খুলুন।';
  static const fitFirst = 'আগে উড়ে যাওয়া ফিউজটা বদলান।';
  static const lockDoor = 'দরজা লক';
  static const hrcNames = {
    M3Hrc.same: 'একই রেটিংয়ের HRC',
    M3Hrc.bigger: 'বড় রেটিংয়ের HRC',
    M3Hrc.copperStrip: 'তামার পাত',
  };

  /// Station 6: one choice per step, dealt on a [ChoiceDeck] (the guide asks
  /// [serviceAsks]; every option a real crew might do, about the same length).
  static const serviceAsks = [
    'এই সংযোগে কোন সার্ভিস কেবিল দেবেন?',
    'পোল থেকে বাড়ি পর্যন্ত কেবিল টানবেন কীভাবে?',
    'মিটারে কেবিল ঢোকাবেন কীভাবে?',
    'এবার নিউট্রাল জোড়া — কীভাবে জুড়বেন?',
  ];
  static const cableTwin = 'টুইন-কোর কেবিল, ফেজ ও নিউট্রাল';
  static const cableFour = 'ফোর-কোর কেবিল, R-Y-B ও নিউট্রাল';
  static const cableBare = 'খোলা তার, ইনসুলেশন ছাড়াই';
  static const hangRight = 'বিয়ারার তারে বেঁধে, টান ওর ওপর';
  static const hangWrong = ['কেবিল নিজেই টানটান করে বেঁধে', 'বিয়ারার ঢিলে, টান কেবিলের ওপর'];
  static const dripRight = 'নিচে U লুপ রেখে মিটারে ঢোকানো';
  // Wrong options share the right one's key words (U, নিচে, লুপ, লাইভ,
  // গ্লাভস), so no word shows up on the right option alone.
  static const dripWrong = ['U লুপ ওপরে তুলে মিটারে ঢোকানো', 'লুপ ছাড়াই নিচে সোজা মিটারে ঢোকানো'];
  static const neutralRight = 'গ্লাভস পরে, নিউট্রালও লাইভ ধরে';
  // Both wrong ones are a bare hand on the neutral (deadly), worded apart.
  static const neutralWrong = ['খালি হাতে, নিউট্রাল তো লাইভ নয়', 'গ্লাভস খুলে চটপট, নিউট্রালে ভয় নেই'];

  /// Step [step]'s right option and its wrong ones ([threePhase]: the dealt connection).
  static (String, List<String>) serviceOptions(int step, {required bool threePhase}) => switch (step) {
        0 => threePhase ? (cableFour, const [cableTwin, cableBare]) : (cableTwin, const [cableFour, cableBare]),
        1 => (hangRight, hangWrong),
        2 => (dripRight, dripWrong),
        _ => (neutralRight, neutralWrong),
      };
  static const guardOn = 'গার্ডিং ঠিক · লাইন চালু';
  static const guardFixed = {
    M3GuardFault.leftEarth: 'আর্থিং তার জুড়ে পাইপে ঢাকা হলো।',
    M3GuardFault.rightEarth: 'আর্থিং তার জুড়ে পাইপে ঢাকা হলো।',
    M3GuardFault.brokenWire: 'ছেঁড়া তার জুড়ে ঠিক টানে বাঁধা হলো।',
  };

  static const praise = {
    M3GateStation.sld: 'AB-1 আর NO — দুদিকের পথই বন্ধের পরিকল্পনা!',
    M3GateStation.patrol: 'পেট্রোল নিখুঁত — প্রতিটা খুঁত খাতায় উঠল।',
    M3GateStation.fuseLa: 'তিনটে DO খোলা, ঠিক লিঙ্ক, LA-ও দেখা হলো!',
    M3GateStation.dtr: 'দুদিক বন্ধ করে ট্যাপ বদল — ঠিক নিয়ম!',
    M3GateStation.pillar: 'পিলার ঠিক, হটস্পট টাইট, দরজা লক!',
    M3GateStation.service: 'বিয়ারারে টান, ড্রিপ লুপ — নিখুঁত সংযোগ!',
    M3GateStation.guard: 'জাল আবার সুরক্ষা — লাইন চালু!',
  };

  // --- Reasons (one library per station, 2 right / 5 wrong) -----------------
  static const whySldQ = 'কেন NO পয়েন্টটাও চিহ্নিত করলেন?';
  static const whySldRight = [
    'রিং ফিডারে উল্টো দিক থেকেও বিদ্যুৎ আসতে পারে',
    'ব্যাকফিডের পথ ডায়াগ্রামেই ধরা পড়ে, স্মৃতিতে নয়',
  ];
  static const whySldWrong = [
    'এলাকা চেনা থাকলে ডায়াগ্রাম দেখার দরকারই নেই',
    'একটা লাইন মানে একটাই তার, একদিক খুললেই হয়',
    'উপকেন্দ্রের ব্রেকার খুললেই সব দিক মৃত হয়ে যায়',
    'পুরনো ডায়াগ্রাম সবসময় মাঠের লাইনের সাথে মেলে',
    'NO সবসময় খোলা থাকে, তাই ওটা ভাবার কিছু নেই',
  ];

  static const whyPatrolQ = 'কেন ছোট খুঁতগুলোও ফল্ট লিখলেন?';
  static const whyPatrolRight = [
    'ছোট ফাটল, মরিচা বা কাটা স্ট্র্যান্ডেই বড় বিপদ হয়',
    'নিচ থেকে খুঁত ধরলে ওঠার আগেই মেরামত হয়ে যায়',
  ];
  static const whyPatrolWrong = [
    'এক কোণা ভাঙলেও মোটা চিনামাটিতে কিছু হয় না',
    'হালকা মরিচা শুধু বাইরের স্তরে, তাতে ভয় নেই',
    'একটা স্ট্র্যান্ড কাটলে বাকিরাই টান ধরে রাখে',
    'যেকোনো ক্ল্যাম্প যেকোনো পোলে লাগালেই চলে',
    'সরু চুলের মতো ফাটলে হাই-ভোল্টেজে কিছু হয় না',
  ];

  static const whyFuseQ = 'কেন তিনটে DO খুলে নেমপ্লেট-মাফিক লিঙ্ক দিলেন?';
  static const whyFuseRight = [
    'একটা উড়লে বাকি দুটো খুললেই ট্রান্সফরমার পুরো আলাদা',
    'মাপা গলনাঙ্কের ঠিক রেটিংয়ের লিঙ্কই আসল সুরক্ষা দেয়',
  ];
  static const whyFuseWrong = [
    'বারবার উড়লে মোটা তার দিলেই সমস্যা মিটে যায়',
    'একটা ফেজের DO বদলালেই বাকি দুটো চালু রাখা যায়',
    'যেকোনো ধাতব তার দিয়েই ফিউজ লিঙ্ক বানানো যায়',
    'বড় রেটিংয়ের লিঙ্ক দিলে ফিউজ আর কখনো উড়বে না',
    'LA তো বজ্রপাত আটকায়, তাই ফিউজের দরকার কম',
  ];

  static const whyDtrQ = 'কেন LT-ও বন্ধ করে তবে ট্যাপ ঘোরালেন?';
  static const whyDtrRight = [
    'অফ-লোড ট্যাপ চেঞ্জার শুধু HT-LT দুদিক বন্ধ করেই',
    'একদিক চালু থাকলে ট্রান্সফরমার মৃত নয়, তাই দুদিক',
  ];
  static const whyDtrWrong = [
    'HT-র DO খোলা থাকলেই ট্রান্সফরমার পুরো নিরাপদ',
    'ট্যাপ চেঞ্জার লোড চালু রেখেও ঘোরানো যায় সহজে',
    'হামিং শব্দ থামলেই বোঝা যায় ট্রান্সফরমার মৃত',
    'LT বন্ধ করলে গ্রাহকরা অভিযোগ করবেন, তাই নয়',
    'গোলাপি জেল আর সামান্য তেল লিকে কিছু যায় আসে না',
  ];

  static const whyPillarQ = 'কেন পিপিই, টেস্টার আর একই রেটিংয়ের HRC?';
  static const whyPillarRight = [
    'চারশো পনেরো ভোল্টেও আর্ক ফ্ল্যাশ, তাই পিপিই আর টেস্ট',
    'HRC-র কোয়ার্টজ বালু আর্ক নেভায়, পাত দিলে সব পোড়ে',
  ];
  static const whyPillarWrong = [
    'পিলারে মোটে চারশো পনেরো ভোল্ট, ভয়ের কিছু নেই',
    'তামার পাত দিলে ফিউজ বারবার ওড়ার ঝামেলা মেটে',
    'ডায়াগ্রামে বন্ধ লেখা থাকলে টেস্টারের দরকার নেই',
    'কালো দাগ পুরনো রং, ঢিলা কানেকশনের লক্ষণ নয়',
    'কাজ শেষে দরজা খোলা থাকলে হাওয়া চলাচল ভালো',
  ];

  static const whyServiceQ = 'কেন বিয়ারার তার আর ড্রিপ লুপ দিলেন?';
  static const whyServiceRight = [
    'টান নেয় বিয়ারার তার, তাই কেবিল ছেঁড়ে না',
    'U লুপে বৃষ্টির জল নিচে ঝরে, মিটারে ঢোকে না',
  ];
  static const whyServiceWrong = [
    'কেবিল নিজেই শক্ত, টানটান দিলে ঝোলে না',
    'লুপ দিলে কেবিল বেশি লাগে, তাই সোজাই ভালো',
    'নিউট্রালে কারেন্ট নেই, খালি হাতে ধরা যায়',
    'মিটার বক্সে জল ঢুকলে নিজেই শুকিয়ে যায়',
    'সব বাড়িতেই ফোর-কোর দিলে ঝামেলা থাকে না',
  ];

  static const whyGuardQ = 'কেন গ্লাভস পরে, গার্ডিং ঠিক করে তবে চালু?';
  static const whyGuardRight = [
    'আর্থিং নষ্ট থাকলে পুরো জাল লাইভ হতে পারে',
    'ভালো আর্থিং থাকলে ছেঁড়া তারে ব্রেকার ট্রিপ করে',
  ];
  static const whyGuardWrong = [
    'গার্ডের তারে কারেন্ট থাকে না, খালি হাতে চলে',
    'একটা-দুটো তার ছিঁড়লেও বাকিগুলো সামলে নেয়',
    'আর্থিং তার চুরি গেলেও জালের কাজ চলে যায়',
    'জাল একটু ঝুলে থাকলেও লাইভ তার ছোঁয় না',
    'রাস্তায় লোক কম থাকলে গার্ডিং লাগেই না',
  ];

  // --- The careless coworker (station 4) ---------------------------------------
  static const coworker = CoworkerScript(
    line: 'আরে, HT-র তিনটে DO তো খোলাই! LT বন্ধের ঝামেলা কেন, ট্যাপটা ঘুরিয়ে দাও।',
    exitLine: 'হুঁ! যত্তসব বই-পড়া নিয়ম।',
    right: [
      'না, LT-ও বন্ধ করে তবেই ট্যাপ',
      'না, দুদিক বন্ধ না হলে ট্যাপ নয়',
      'না, অফ-লোড মানে HT-LT দুদিক বন্ধ',
    ],
    wrong: [
      'ঠিক, HT খোলা মানেই সব নিরাপদ',
      'ঠিক আছে, LT চালুই থাক আপাতত',
      'হ্যাঁ, এখনই ঘুরিয়ে দিই ট্যাপ',
      'সবাই তো এভাবেই ট্যাপ বদলে নেয়',
    ],
    asks: [
      'ও বলছে LT বন্ধ লাগবে না। আপনি কী করবেন?',
      'শুধু HT খোলা রেখে ট্যাপ — রাজি?',
      'LT বন্ধ করবেন, না ওর কথা শুনবেন?',
    ],
  );
  static const coworkerHeld = 'ঠিক! দুদিক বন্ধ না করে ট্যাপ নয়।';

  static const allSet = 'অভিনন্দন! টেকনিশিয়ানের ডকেট নিখুঁত — আপনি এখন টেকনিশিয়ান, লাইন চেনার জাদুকর!';
  static const fail = 'আরেকবার — সাতটা স্টেশনের প্রতিটা নিয়ম মেনে টেকনিশিয়ান র‍্যাঙ্ক জিতুন।';

  /// Every fixed line the guide says (for recording).
  static List<String> get recordable => [
        intro,
        for (final l in tasks.values) ...l,
        ...praise.values,
        markFirst,
        openOthers,
        healthFirst,
        doorFirst,
        fitFirst,
        ...serviceAsks,
        ...guardFixed.values.toSet(),
        whySldQ,
        whyPatrolQ,
        whyFuseQ,
        whyDtrQ,
        whyPillarQ,
        whyServiceQ,
        whyGuardQ,
        coworkerHeld,
        ...coworker.asks,
        allSet,
        fail,
      ];
}

// ============================================================================
// Rules (pure)
// ============================================================================

class M3GateRun {
  M3GateRun(this.seed) : _rng = math.Random(seed) {
    noMid = _rng.nextBool();
    final parts = [...M3Part.values]..shuffle(_rng);
    final bad = parts.take(3).toSet();
    final armFault = _rng.nextBool() ? M3Fault.rust : M3Fault.bent;
    faults = {
      for (final p in M3Part.values)
        p: !bad.contains(p)
            ? null
            : switch (p) {
                M3Part.pin => M3Fault.chip,
                M3Part.clamp => M3Fault.slipped,
                M3Part.strand => M3Fault.cut,
                M3Part.disc => M3Fault.crack,
                M3Part.arm => armFault,
              },
    };
    dropped = _rng.nextInt(3);
    final la = _rng.nextInt(3);
    laFault = la == 0 ? null : M3LaFault.values[la - 1];
    links = [...M3Link.values]..shuffle(_rng);
    gelPinkDealt = _rng.nextBool();
    oilLeakDealt = _rng.nextBool();
    tapTo = _rng.nextBool() ? 2 : 4;
    blownWay = _rng.nextInt(3);
    blownPh = _rng.nextInt(3);
    hotBolt = _rng.nextInt(6);
    hrcs = [...M3Hrc.values]..shuffle(_rng);
    threePhase = _rng.nextBool();
    guardFault = M3GuardFault.values[_rng.nextInt(M3GuardFault.values.length)];
  }

  final int seed;
  final math.Random _rng;

  late final bool noMid;
  late final Map<M3Part, M3Fault?> faults;
  late final int dropped;
  late final M3LaFault? laFault;
  late final List<M3Link> links;
  late final bool gelPinkDealt;
  late final bool oilLeakDealt;
  late final int tapTo;
  late final int blownWay;
  late final int blownPh;
  late final int hotBolt;
  late final List<M3Hrc> hrcs;
  late final bool threePhase;
  late final M3GuardFault guardFault;

  static const tapFrom = 3;

  M3GateStation station = M3GateStation.sld;
  final Set<M3GateStation> completed = {};
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => completed.length == M3GateStation.values.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

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
    if (next < M3GateStation.values.length) station = M3GateStation.values[next];
  }

  // 1. SLD --------------------------------------------------------------------
  final Set<M3SldSym> marked = {};
  var planned = false;

  DoMistake? markSym(M3SldSym s) {
    if (ended || planned || marked.contains(s)) return null;
    if (s != M3SldSym.ab && s != M3SldSym.no) return slip(M3GateMistakes.wrongSymbol);
    marked.add(s);
    return null;
  }

  /// Null with [planned] still false means nothing is marked yet (no cost).
  DoMistake? confirmPlan() {
    if (ended || planned || marked.isEmpty) return null;
    if (!marked.contains(M3SldSym.no)) return deadly = M3GateMistakes.ringBackfeed;
    if (!marked.contains(M3SldSym.ab)) return slip(M3GateMistakes.sourceAb);
    planned = true;
    tag('SLD-তে রিং ফিডারের NO পয়েন্ট');
    return null;
  }

  // 2. Patrol -------------------------------------------------------------------
  final Set<M3Part> passedOk = {};
  final Set<M3Part> flagged = {};

  bool judged(M3Part p) => passedOk.contains(p) || flagged.contains(p);

  /// Calls [p] sound; a slip when it is faulty.
  DoMistake? partOk(M3Part p) {
    if (ended || judged(p)) return null;
    final f = faults[p];
    if (f != null) return slip(M3GateMistakes.forFault(f));
    passedOk.add(p);
    return null;
  }

  /// Flags [p] as a fault; an over-call on a sound part is a slip (it stays
  /// to be judged again).
  DoMistake? partFault(M3Part p) {
    if (ended || judged(p)) return null;
    if (faults[p] == null) return slip(M3GateMistakes.soundFlagged);
    flagged.add(p);
    return null;
  }

  bool get patrolDone => M3Part.values.every(judged);

  // 3. DO and LA ----------------------------------------------------------------
  final List<bool> doOpen = [false, false, false];
  M3Link? link;
  var laJudged = false;
  var laReplaced = false;

  bool isDoDown(int i) => i == dropped || doOpen[i];
  bool get allDoOpen => [0, 1, 2].every(isDoDown);

  void openDo(int i) {
    if (ended || isDoDown(i)) return;
    doOpen[i] = true;
    if (allDoOpen) tag('একটা উড়লে তিনটে DO-ই খোলা');
  }

  DoMistake? chooseLink(M3Link l) {
    if (ended || link != null) return null;
    if (l == M3Link.thickWire) return deadly = M3GateMistakes.thickWire;
    if (!allDoOpen) return slip(M3GateMistakes.allThree);
    if (l == M3Link.anyWire) return slip(M3GateMistakes.anyWire);
    if (l == M3Link.overRated) return slip(M3GateMistakes.overRated);
    link = l;
    tag('নেমপ্লেট-মাফিক ফিউজ লিঙ্ক');
    return null;
  }

  DoMistake? laOk() {
    if (ended || laJudged) return null;
    final f = laFault;
    if (f != null) return slip(f == M3LaFault.crack ? M3GateMistakes.laCrack : M3GateMistakes.laHanging);
    laJudged = true;
    return null;
  }

  /// Replaces the LA; a slip when it was healthy.
  DoMistake? laReplace() {
    if (ended || laJudged) return null;
    if (laFault == null) return slip(M3GateMistakes.laSound);
    laJudged = true;
    laReplaced = true;
    tag('খারাপ LA চেনা');
    return null;
  }

  bool get fuseLaDone => link != null && laJudged;

  // 4. DTR ----------------------------------------------------------------------
  var gelJudged = false;
  var gelNew = false;
  var oilJudged = false;
  var oilFixed = false;
  var ltOn = true;
  var tap = tapFrom;
  var tapped = false;

  DoMistake? gelOk() {
    if (ended || gelJudged) return null;
    if (gelPinkDealt) return slip(M3GateMistakes.gelPink);
    gelJudged = true;
    return null;
  }

  /// Replaces the gel; a slip when it was still dry (blue).
  DoMistake? gelReplace() {
    if (ended || gelJudged) return null;
    if (!gelPinkDealt) return slip(M3GateMistakes.gelDry);
    gelJudged = true;
    gelNew = true;
    tag('গোলাপি জেল বদল');
    return null;
  }

  DoMistake? oilOk() {
    if (ended || oilJudged) return null;
    if (oilLeakDealt) return slip(M3GateMistakes.oilLeak);
    oilJudged = true;
    return null;
  }

  /// Reports a leak; a slip when the tank is dry.
  DoMistake? oilReport() {
    if (ended || oilJudged) return null;
    if (!oilLeakDealt) return slip(M3GateMistakes.oilDry);
    oilJudged = true;
    oilFixed = true;
    tag('তেল লিক ধরা');
    return null;
  }

  bool get healthDone => gelJudged && oilJudged;

  void switchLtOff() {
    if (!ended) ltOn = false;
  }

  /// Null with [tapped] false: the health check comes first (no cost).
  DoMistake? turnTap() {
    if (ended || tapped || !healthDone) return null;
    if (ltOn) return deadly = M3GateMistakes.tapLive;
    tap = tapTo;
    tapped = true;
    tag('HT-LT দুদিক বন্ধ করে ট্যাপ বদল');
    return null;
  }

  // 5. Feeder pillar --------------------------------------------------------------
  var pGloves = false;
  var pShield = false;
  var doorOpen = false;
  var tested = false;
  var pickingFuse = false;
  var fitted = false;
  var tightened = false;
  var locked = false;

  DoMistake? _inside() {
    if (!pGloves || !pShield) return slip(M3GateMistakes.pillarPpe);
    return null;
  }

  DoMistake? testBus() {
    if (ended || tested) return null;
    final m = _inside();
    if (m != null) return m;
    tested = true;
    return null;
  }

  /// Picks up fuse ([way], [ph]); pulling a sound fuse is a slip.
  DoMistake? tapFuse(int way, int ph) {
    if (ended || fitted || pickingFuse) return null;
    final m = _inside();
    if (m != null) return m;
    if (!tested) return slip(M3GateMistakes.noTest);
    if (way != blownWay || ph != blownPh) return slip(M3GateMistakes.wrongFuse);
    pickingFuse = true;
    return null;
  }

  DoMistake? fitHrc(M3Hrc h) {
    if (ended || !pickingFuse || fitted) return null;
    if (h == M3Hrc.copperStrip) return deadly = M3GateMistakes.copperStrip;
    if (h == M3Hrc.bigger) return slip(M3GateMistakes.hrcBigger);
    fitted = true;
    pickingFuse = false;
    tag('একই রেটিংয়ের HRC ফিউজ');
    return null;
  }

  /// Tightens [bolt]; a sound bolt is a slip (the hot spot is the black one).
  DoMistake? tighten(int bolt) {
    if (ended || tightened) return null;
    final m = _inside();
    if (m != null) return m;
    if (!tested) return slip(M3GateMistakes.noTest);
    if (bolt != hotBolt) return slip(M3GateMistakes.wrongBolt);
    tightened = true;
    tag('হটস্পট টাইট');
    return null;
  }

  DoMistake? lock() {
    if (ended || locked || !fitted) return null;
    if (!tightened) return slip(M3GateMistakes.hotspot);
    locked = true;
    tag('কাজ শেষে পিলার লক');
    return null;
  }

  // 6. Service drop -----------------------------------------------------------------
  var serviceStep = 0;

  /// Step [serviceStep] answered with its right option ([right]) or the wrong one.
  DoMistake? serviceChoose({required bool right}) {
    if (ended || serviceStep >= 4) return null;
    if (!right) {
      return switch (serviceStep) {
        0 => slip(M3GateMistakes.wrongCore),
        1 => slip(M3GateMistakes.noBearer),
        2 => slip(M3GateMistakes.noDrip),
        _ => deadly = M3GateMistakes.neutralBare,
      };
    }
    serviceStep++;
    if (serviceStep == 2) tag('বিয়ারার তারে সার্ভিস কেবিল');
    if (serviceStep == 3) tag('মিটারের আগে ড্রিপ লুপ');
    if (serviceStep == 4) tag('নিউট্রালকেও লাইভ ধরা');
    return null;
  }

  /// The three options of step [i] (one right), shuffled per play.
  List<ChoiceOption> serviceDeal(int i) {
    final (right, wrong) = M3GateLines.serviceOptions(i, threePhase: threePhase);
    return dealChoices([right], wrong, math.Random(seed * 31 + i));
  }

  bool get serviceDone => serviceStep >= 4;

  // 7. Guard ------------------------------------------------------------------------
  var gGloves = false;
  var guardFixed = false;
  var guardDone = false;

  /// Works on the guard at [spot]; a spot with nothing wrong is a slip.
  DoMistake? touchGuard(M3GuardFault spot) {
    if (ended || guardFixed) return null;
    if (!gGloves) return deadly = M3GateMistakes.guardBare;
    if (spot != guardFault) return slip(M3GateMistakes.guardSpot);
    guardFixed = true;
    tag(guardFault == M3GuardFault.brokenWire ? 'গার্ডিং-এর ছেঁড়া তার মেরামত' : 'গার্ডিং-এর আর্থিং জোড়া');
    return null;
  }

  DoMistake? energise() {
    if (ended || guardDone) return null;
    if (!guardFixed) return slip(guardFault == M3GuardFault.brokenWire ? M3GateMistakes.guardWire : M3GateMistakes.guardEarth);
    guardDone = true;
    return null;
  }
}

// ============================================================================
// Page
// ============================================================================

class M3GateFieldPage extends StatefulWidget {
  const M3GateFieldPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M3GateFieldPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3GateFieldPage> createState() => _M3GateFieldPageState();
}

class _M3GateFieldPageState extends State<M3GateFieldPage> {
  var _round = 0;
  late bool _muted = widget.muted;
  late final int _base = widget.seed ?? DateTime.now().millisecondsSinceEpoch % 100000;

  @override
  Widget build(BuildContext context) => _M3GateRunPage(
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

class _M3GateRunPage extends ConsumerStatefulWidget {
  const _M3GateRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.seed,
    required this.onRetry,
  });

  final LevelContext ctx;
  final M3GateFieldPack pack;
  final bool muted;
  final int seed;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_M3GateRunPage> createState() => _M3GateRunPageState();
}

class _M3GateRunPageState extends ConsumerState<_M3GateRunPage>
    with TickerProviderStateMixin, DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3GateRun _run = M3GateRun(widget.seed);
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

  // Gesture hints (how to touch, never what): keys of every tappable thing.
  final _hints = IdleHintController();
  final _gks = <String, GlobalKey>{};
  GlobalKey _gk(String id) => _gks.putIfAbsent(id, GlobalKey.new);

  /// Station 6: options already tried and wrong on the current step.
  final Set<String> _serviceWrong = {};

  // Scene state.
  M3Look? _look;
  Offset? _sparkAt;
  var _sparkBig = false;
  Offset? _stickTo;

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

  Future<void> _start() async {
    setState(() {
      _intro = false;
      _docketOpen = true;
    });
    _clock.start();
    await _enterStation();
  }

  Future<void> _enterStation() async {
    if (!mounted) return;
    setState(() {
      _wake++;
      _tapN = 0;
      _look = null;
      _stickTo = null;
    });
    unawaited(_sayChain([
      M3GateLines.tasks[_run.station]!.first,
      if (_run.station == M3GateStation.service) M3GateLines.serviceAsks[_run.serviceStep],
    ]));
    if (_run.station == M3GateStation.dtr && !coworkerDone) scheduleCoworker();
  }

  void _tapGuide() {
    if (_intro || _ended || _freeze || _run.ended) return;
    final lines = M3GateLines.tasks[_run.station]!;
    _tapN++;
    _cue('sounds/learn/tick.ogg', volume: 0.5);
    final line = lines[_tapN % lines.length];
    ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.talk, line: line);
    unawaited(MascotSpeechLibrary.speak(line, muted: _muted));
  }

  /// The scene takes a move now: not during the praise window or the reason
  /// deck (tableBusy), a death freeze, a card, the coworker, intro or docket.
  bool get _canAct =>
      !_busy &&
      !_ended &&
      !_freeze &&
      !_run.ended &&
      _card == null &&
      !tableBusy &&
      !coworkerOpen &&
      !_intro &&
      !_docketOpen &&
      !struckOut;

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

  Offset get _mid {
    final s = MediaQuery.sizeOf(context);
    return Offset(s.width / 2, s.height * 0.5);
  }

  /// A station's last right move: ◆ on the table, praise, the reason deck.
  Future<void> _stationWon(Offset origin) async {
    final (q, right, wrong) = switch (_run.station) {
      M3GateStation.sld => (M3GateLines.whySldQ, M3GateLines.whySldRight, M3GateLines.whySldWrong),
      M3GateStation.patrol => (M3GateLines.whyPatrolQ, M3GateLines.whyPatrolRight, M3GateLines.whyPatrolWrong),
      M3GateStation.fuseLa => (M3GateLines.whyFuseQ, M3GateLines.whyFuseRight, M3GateLines.whyFuseWrong),
      M3GateStation.dtr => (M3GateLines.whyDtrQ, M3GateLines.whyDtrRight, M3GateLines.whyDtrWrong),
      M3GateStation.pillar => (M3GateLines.whyPillarQ, M3GateLines.whyPillarRight, M3GateLines.whyPillarWrong),
      M3GateStation.service => (M3GateLines.whyServiceQ, M3GateLines.whyServiceRight, M3GateLines.whyServiceWrong),
      M3GateStation.guard => (M3GateLines.whyGuardQ, M3GateLines.whyGuardRight, M3GateLines.whyGuardWrong),
    };
    _busy = true;
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.7);
    // The station's ◆ wait on the table; the right reason pays them (once).
    putOnTable(_scored(20));
    final praise = M3GateLines.praise[_run.station];
    if (praise != null) await _say(praise, mood: GuideMood.celebrate);
    if (!mounted) return;
    _busy = false;
    await askReason(
      deal: () => dealChoices(right, wrong, math.Random(widget.seed + 11 * (_run.station.index + 1))),
      question: q,
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
    await Future<void>.delayed(Duration(milliseconds: big ? 450 : 260));
    if (mounted) setState(() => _sparkAt = null);
  }

  Future<void> _handleMistake(DoMistake m, {Offset? at}) async {
    _busy = true;
    _hints.hide();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    _combo.miss();
    if (m.deadly) {
      if (at != null) await _spark(at);
      if (!mounted) return;
      final frozen = _frozen = Completer<void>();
      setState(() => _freeze = true);
      final outcome = await bookDeadly(m, runScore: _runScore);
      await frozen.future;
      if (!mounted) return;
      setState(() {
        _freeze = false;
        _card = m;
        _cardTone = outcome == DeadlyOutcome.nearMiss ? MistakeTone.nearMiss : MistakeTone.deadly;
        _busy = false;
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
  CoworkerScript get coworkerScript => M3GateLines.coworker;

  @override
  late final math.Random coworkerRng = math.Random(widget.seed * 7 + 3);

  @override
  bool get coworkerMuted => _muted;

  @override
  bool? coworkerCanCome() {
    // His push is "the HT DOs are open, skip the LT, turn the tap": too late
    // once the LT is off or the tap turned.
    if (_ended || _run.ended || struckOut || _run.station != M3GateStation.dtr || _run.tapped || !_run.ltOn) return null;
    if (_busy || _freeze || _card != null || tableBusy || _docketOpen || _look != null) return false;
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
      await _say(M3GateLines.coworkerHeld, mood: GuideMood.glad);
    } else {
      await _handleMistake(_run.slip(M3GateMistakes.coworkerLt));
    }
  }

  // --- station 1: SLD -------------------------------------------------------------
  Future<void> _onSym(M3SldSym s, Offset at) async {
    if (!_canAct) return;
    _hush();
    final m = _run.markSym(s);
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  Future<void> _onPlan(Offset origin) async {
    if (!_canAct || _run.planned) return;
    _hush();
    if (_run.marked.isEmpty) {
      unawaited(_say(M3GateLines.markFirst));
      return;
    }
    final m = _run.confirmPlan();
    if (m != null) {
      await _handleMistake(m, at: m.deadly ? _mid : null);
      return;
    }
    await _stationWon(origin);
  }

  // --- judge sheet (patrol, LA, DTR health) ----------------------------------------
  void _onLook(M3Look l) {
    if (!_canAct) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/card_deal_b.ogg', volume: 0.6);
    setState(() => _look = l);
  }

  static M3Part? _partOf(M3Look l) => switch (l) {
        M3Look.pin => M3Part.pin,
        M3Look.clamp => M3Part.clamp,
        M3Look.strand => M3Part.strand,
        M3Look.disc => M3Part.disc,
        M3Look.arm => M3Part.arm,
        _ => null,
      };

  Future<void> _onJudge(bool fault, Offset origin) async {
    final l = _look;
    if (l == null || !_canAct) return;
    _hush();
    setState(() => _look = null);
    final part = _partOf(l);
    // A wrong verdict either way is a slip; its card teaches after the call.
    final m = part != null
        ? (fault ? _run.partFault(part) : _run.partOk(part))
        : switch (l) {
            M3Look.la => fault ? _run.laReplace() : _run.laOk(),
            M3Look.gel => fault ? _run.gelReplace() : _run.gelOk(),
            _ => fault ? _run.oilReport() : _run.oilOk(),
          };
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _cue(fault ? 'sounds/learn/tag_slap.ogg' : 'sounds/intro/confirm.ogg', volume: 0.7);
    setState(() => _wake++);
    if (part != null && _run.patrolDone) {
      await _stationWon(origin);
    } else if (l == M3Look.la && _run.fuseLaDone) {
      await _stationWon(origin);
    }
  }

  // --- station 3: DO and LA ------------------------------------------------------------
  Future<void> _onDo(int i, M3DtrGeo g) async {
    if (!_canAct || _run.isDoDown(i)) return;
    _busy = true;
    _hush();
    setState(() {
      _stickTo = Offset(g.doX(i) + 4, g.doTop + 6);
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 60 : 520));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _run.openDo(i);
    await _spark(Offset(g.doX(i), g.doTop + M3DtrGeo.doLen), big: false);
    if (!mounted) return;
    setState(() => _stickTo = null);
    _busy = false;
  }

  Future<void> _onLink(M3Link l, Offset origin) async {
    if (!_canAct) return;
    _hush();
    final m = _run.chooseLink(l);
    if (m != null) {
      await _handleMistake(m, at: m.deadly ? _mid : null);
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() => _wake++);
    if (_run.fuseLaDone) await _stationWon(origin);
  }

  // --- station 4: DTR -------------------------------------------------------------------
  void _onLt() {
    if (!_canAct || !_run.ltOn) return;
    // He pushes "skip the LT": switching it off before he came would skip him.
    if (holdForCoworker()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.9);
    setState(() {
      _run.switchLtOff();
      _run.tag('LT সুইচ বন্ধ');
      _wake++;
    });
  }

  Future<void> _onTap(Offset at) async {
    if (!_canAct || _run.tapped) return;
    if (holdForCoworker()) return;
    _hush();
    if (!_run.healthDone) {
      unawaited(_say(M3GateLines.healthFirst));
      return;
    }
    final m = _run.turnTap();
    if (m != null) {
      await _handleMistake(m, at: at);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.8);
    setState(() => _wake++);
    await _stationWon(at);
  }

  // --- station 5: feeder pillar ---------------------------------------------------------
  void _onWear({required bool shield}) {
    if (!_canAct) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() {
      if (_run.station == M3GateStation.guard) {
        _run.gGloves = true;
      } else if (shield) {
        _run.pShield = true;
      } else {
        _run.pGloves = true;
      }
      _wake++;
    });
  }

  void _onDoor() {
    if (!_canAct || _run.doorOpen) return;
    _cue('sounds/intro/click.ogg', volume: 0.8);
    setState(() {
      _run.doorOpen = true;
      _wake++;
    });
  }

  Future<void> _onPillarAct(DoMistake? Function() act) async {
    if (!_canAct) return;
    _hush();
    if (!_run.doorOpen) {
      unawaited(_say(M3GateLines.doorFirst));
      return;
    }
    final m = act();
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  Future<void> _onHrc(M3Hrc h, Offset origin) async {
    if (!_canAct) return;
    _hush();
    final m = _run.fitHrc(h);
    if (m != null) {
      await _handleMistake(m, at: m.deadly ? M3PillarGeo(_sceneH).fuse(_run.blownWay, _run.blownPh) : null);
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    setState(() => _wake++);
    await _pay(5, origin);
  }

  Future<void> _onLock(Offset origin) async {
    if (!_canAct || _run.locked) return;
    _hush();
    if (!_run.fitted) {
      unawaited(_say(M3GateLines.fitFirst));
      return;
    }
    final m = _run.lock();
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    _cue('sounds/intro/click.ogg', volume: 1);
    setState(() {
      _run.doorOpen = false;
      _wake++;
    });
    await _stationWon(origin);
  }

  // --- station 6: service drop ----------------------------------------------------------
  Future<void> _onService(ChoiceOption o, Offset origin) async {
    if (!_canAct || _run.serviceDone || _serviceWrong.contains(o.textBn)) return;
    _hush();
    final m = _run.serviceChoose(right: o.correct);
    if (m != null) {
      setState(() => _serviceWrong.add(o.textBn));
      await _handleMistake(m, at: m.deadly ? M3ServiceGeo(_sceneH).meter.center : null);
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    setState(() {
      _serviceWrong.clear();
      _wake++;
    });
    if (_run.serviceDone) {
      await _stationWon(origin);
    } else {
      unawaited(_sayChain([M3GateLines.serviceAsks[_run.serviceStep]]));
      await _pay(5, origin);
    }
  }

  // --- station 7: guard ------------------------------------------------------------------
  Future<void> _onGuard(M3GuardFault spot, Offset at) async {
    if (!_canAct || _run.guardFixed) return;
    _hush();
    final m = _run.touchGuard(spot);
    if (m != null) {
      await _handleMistake(m, at: m.deadly ? at : null);
      return;
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    setState(() => _wake++);
    unawaited(_say(M3GateLines.guardFixed[_run.guardFault]!));
    await _pay(5, at);
  }

  Future<void> _onEnergise(Offset origin) async {
    if (!_canAct || _run.guardDone) return;
    _hush();
    final m = _run.energise();
    if (m != null) {
      await _handleMistake(m);
      return;
    }
    await _stationWon(origin);
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
      await save.unlockRank(3); // Promotes to Technician (টেকনিশিয়ান, rank 3).
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
      _cue('sounds/quiz_complete.ogg', volume: 0.85);
      await _say(M3GateLines.allSet, mood: GuideMood.celebrate);
    } else {
      _cue('sounds/learn/level_fail.ogg', volume: 0.7);
      await _say(M3GateLines.fail, mood: GuideMood.warn);
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
      M3GateStation.sld => _sldLayers(h),
      M3GateStation.patrol => _patrolLayers(h),
      M3GateStation.fuseLa || M3GateStation.dtr => _dtrLayers(h),
      M3GateStation.pillar => _pillarLayers(h),
      M3GateStation.service => _serviceLayers(h),
      M3GateStation.guard => _guardLayers(h),
    };
    final spark = _sparkAt;
    return [
      ...out,
      if (spark != null)
        Positioned.fill(
          key: const ValueKey('spark'),
          child: IgnorePointer(child: CustomPaint(painter: M3SparkPainter(at: spark, big: _sparkBig))),
        ),
    ];
  }

  Widget _figure(Rect r, LinemanMode mode) => Positioned.fromRect(
        key: const ValueKey('worker'),
        rect: r,
        child: IgnorePointer(child: LinemanFigure(look: LinemanLook.trainee, mode: mode, wake: _wake, quiet: _quiet)),
      );

  Widget _hitAt(String id, Rect r, void Function(Offset global) onTap) => Positioned.fromRect(
        key: ValueKey(id),
        rect: r,
        child: GestureDetector(key: _gk(id), behavior: HitTestBehavior.opaque, onTapUp: (d) => onTap(d.globalPosition)),
      );

  /// A control wrapped so the gesture hint can find it.
  Widget _keyed(String id, Widget child) => KeyedSubtree(key: _gk(id), child: child);

  Rect _standing(double x, double groundY) => Rect.fromLTWH(x - 30, groundY - 112, 59, 118);

  List<Widget> _sldLayers(double h) {
    final g = M3SldGeo(h, noMid: _run.noMid);
    return [
      Positioned.fill(
        key: const ValueKey('sld'),
        child: RepaintBoundary(child: CustomPaint(painter: M3SldPainter(geo: g, marked: {..._run.marked}))),
      ),
      for (final s in M3SldSym.values) _hitAt('sym-${s.name}', g.hit(s), (p) => unawaited(_onSym(s, p))),
    ];
  }

  List<Widget> _patrolLayers(double h) {
    final g = M3PatrolGeo(h);
    return [
      Positioned.fill(
        key: const ValueKey('span'),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: M3PatrolPainter(geo: g, faults: _run.faults, ok: {..._run.passedOk}, flagged: {..._run.flagged}),
          ),
        ),
      ),
      _figure(_standing(176, g.groundY + 20), LinemanMode.point),
      for (final p in M3Part.values)
        if (!_run.judged(p)) _hitAt('part-${p.name}', g.hit(p), (_) => _onLook(M3Look.values[p.index])),
    ];
  }

  List<Widget> _dtrLayers(double h) {
    final g = M3DtrGeo(h);
    final dtr = _run.station == M3GateStation.dtr;
    final foot = Offset(dtr ? 112 : 134, g.groundY + 14);
    final hands = foot + const Offset(14, -74);
    final stick = _stickTo;
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: M3DtrPainter(
              geo: g,
              doOpen: [..._run.doOpen],
              dropped: _run.dropped,
              laFault: _run.laFault,
              laReplaced: _run.laReplaced,
              gelPink: _run.gelPinkDealt,
              gelNew: _run.gelNew,
              oilLeak: _run.oilLeakDealt,
              oilFixed: _run.oilFixed,
              ltOn: _run.ltOn,
              tap: _run.tap,
            ),
          ),
        ),
      ),
      if (stick != null)
        Positioned.fill(
          key: const ValueKey('stick'),
          child: IgnorePointer(child: CustomPaint(painter: _StickPainter(from: hands, to: stick))),
        ),
      _figure(_standing(foot.dx, foot.dy), stick != null ? LinemanMode.hold : LinemanMode.idle),
      if (!dtr) ...[
        for (var i = 0; i < 3; i++)
          if (!_run.isDoDown(i)) _hitAt('do-$i', g.doHit(i), (_) => unawaited(_onDo(i, g))),
        if (!_run.laJudged) _hitAt('la', g.laHit, (_) => _onLook(M3Look.la)),
      ] else ...[
        if (!_run.gelJudged) _hitAt('gel', g.breatherHit, (_) => _onLook(M3Look.gel)),
        if (!_run.oilJudged) _hitAt('oil', g.oilHit, (_) => _onLook(M3Look.oil)),
        _hitAt('lt-switch', g.ltHit, (_) => _onLt()),
        _hitAt('tap', g.tapHit, (p) => unawaited(_onTap(p))),
      ],
    ];
  }

  List<Widget> _pillarLayers(double h) {
    final g = M3PillarGeo(h);
    return [
      Positioned.fill(
        key: const ValueKey('pillar'),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: M3PillarPainter(
              geo: g,
              doorOpen: _run.doorOpen,
              blownWay: _run.blownWay,
              blownPh: _run.blownPh,
              fitted: _run.fitted,
              hotBolt: _run.hotBolt,
              tightened: _run.tightened,
              tested: _run.tested,
            ),
          ),
        ),
      ),
      if (!_run.doorOpen) _hitAt('door', g.box, (_) => _onDoor()),
      if (_run.doorOpen && !_run.locked) ...[
        _hitAt('bus', g.busHit, (_) => unawaited(_onPillarAct(_run.testBus))),
        for (var i = 0; i < 6; i++)
          _hitAt(
            'bolt-$i',
            g.boltHit(i),
            (_) => unawaited(_onPillarAct(() => _run.tighten(i))),
          ),
        for (var w = 0; w < 3; w++)
          for (var ph = 0; ph < 3; ph++)
            _hitAt(
              'fuse-$w-$ph',
              g.fuseHit(w, ph),
              (_) => unawaited(_onPillarAct(() => _run.tapFuse(w, ph))),
            ),
      ],
      _figure(Rect.fromLTWH(2, g.box.bottom - 100, 56, 112), _run.doorOpen ? LinemanMode.hold : LinemanMode.idle),
    ];
  }

  List<Widget> _serviceLayers(double h) {
    final g = M3ServiceGeo(h);
    final s = _run.serviceStep;
    return [
      Positioned.fill(
        key: const ValueKey('service'),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: M3ServicePainter(
              geo: g,
              threePhase: _run.threePhase,
              cableOn: s >= 1,
              bearer: s >= 2,
              drip: s >= 3,
              neutralDone: s >= 4,
            ),
          ),
        ),
      ),
      _figure(_standing(176, g.groundY + 14), s >= 4 ? LinemanMode.cheer : LinemanMode.hold),
    ];
  }

  List<Widget> _guardLayers(double h) {
    final g = M3GuardGeo(h);
    return [
      Positioned.fill(
        key: const ValueKey('guard'),
        child: RepaintBoundary(child: CustomPaint(painter: M3GuardPainter(geo: g, fault: _run.guardFault, fixed: _run.guardFixed))),
      ),
      _figure(_standing(92, g.groundY + 14), _run.guardDone ? LinemanMode.cheer : LinemanMode.idle),
      if (!_run.guardFixed)
        for (final f in M3GuardFault.values) _hitAt('guard-${f.name}', g.hit(f), (_) => unawaited(_onGuard(f, g.spot(f)))),
    ];
  }

  // ============================================================================
  // Controls (screen pixels, page overlays)
  // ============================================================================

  List<Widget> _controls(EdgeInsets pad) {
    final b = pad.bottom + 12;
    Widget row(String key, List<Widget> kids, {double right = 12}) => Positioned(
          key: ValueKey(key),
          left: 12,
          right: right,
          bottom: b,
          child: Row(children: [for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: kids[i])]]),
        );
    switch (_run.station) {
      case M3GateStation.sld:
        return [
          row('plan-row', [_keyed('plan', _ActionButton(label: M3GateLines.planOk, filled: true, onTapUp: (p) => unawaited(_onPlan(p))))], right: 130),
        ];
      case M3GateStation.patrol:
        return const [];
      case M3GateStation.fuseLa:
        if (_run.link != null) return const [];
        return [
          Positioned(
            key: const ValueKey('link-tray'),
            left: 12,
            right: 120,
            bottom: b,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < 2; r++) ...[
                  if (r > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var c = 0; c < 2; c++) ...[
                        if (c > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _keyed(
                            'link-${_run.links[r * 2 + c].name}',
                            _ActionButton(
                              key: ValueKey('link-${_run.links[r * 2 + c].name}'),
                              label: M3GateLines.linkNames[_run.links[r * 2 + c]]!,
                              onTapUp: (p) => unawaited(_onLink(_run.links[r * 2 + c], p)),
                            ),
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
      case M3GateStation.dtr:
        return const [];
      case M3GateStation.pillar:
        return [
          Positioned(
            key: const ValueKey('ppe-row'),
            left: 12,
            bottom: b,
            child: Row(
              children: [
                _keyed('ppe-gloves', _ToolButton(icon: Icons.back_hand_rounded, label: M3GateLines.gloves, on: _run.pGloves, onTap: () => _onWear(shield: false))),
                const SizedBox(width: 8),
                _keyed('ppe-shield', _ToolButton(icon: Icons.face_retouching_natural, label: M3GateLines.faceShield, on: _run.pShield, onTap: () => _onWear(shield: true))),
              ],
            ),
          ),
          if (_run.pickingFuse)
            Positioned(
              key: const ValueKey('hrc-row'),
              left: 12,
              right: 12,
              bottom: b + 92,
              child: Row(
                children: [
                  for (var i = 0; i < _run.hrcs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _keyed(
                        'hrc-${_run.hrcs[i].name}',
                        _ActionButton(
                          key: ValueKey('hrc-${_run.hrcs[i].name}'),
                          label: M3GateLines.hrcNames[_run.hrcs[i]]!,
                          onTapUp: (p) => unawaited(_onHrc(_run.hrcs[i], p)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (_run.doorOpen)
            Positioned(
              key: const ValueKey('lock-row'),
              left: 212,
              bottom: b + 8,
              width: 100,
              child: _keyed('lock', _ActionButton(label: M3GateLines.lockDoor, filled: true, onTapUp: (p) => unawaited(_onLock(p)))),
            ),
        ];
      case M3GateStation.service:
        final s = _run.serviceStep;
        if (s >= 4) return const [];
        // One choice per step on a deck (its own sweep hint); the options are
        // shuffled per play, all of them things a crew might really do.
        return [
          Positioned(
            key: const ValueKey('service-deck'),
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.only(bottom: pad.bottom),
              child: ChoiceDeck(
                key: ValueKey('service-deck-$s'),
                options: _run.serviceDeal(s),
                quiet: _quiet,
                muted: _muted,
                wrong: {..._serviceWrong},
                onPick: (o, at) => unawaited(_onService(o, at)),
              ),
            ),
          ),
        ];
      case M3GateStation.guard:
        return [
          Positioned(
            key: const ValueKey('guard-row'),
            left: 12,
            right: 120,
            bottom: b,
            child: Row(
              children: [
                _keyed('guard-gloves', _ToolButton(icon: Icons.back_hand_rounded, label: M3GateLines.gloves, on: _run.gGloves, onTap: () => _onWear(shield: false))),
                const SizedBox(width: 8),
                Expanded(child: _keyed('energise', _ActionButton(label: M3GateLines.guardOn, filled: true, onTapUp: (p) => unawaited(_onEnergise(p))))),
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
          M3GateStation.fuseLa => _run.link == null ? 128 : 72,
          M3GateStation.pillar => _run.pickingFuse ? 168 : 96,
          M3GateStation.guard => 96,
          M3GateStation.service => _run.serviceDone ? 72 : 236,
          _ => 72,
        };
  }

  // --- gesture hints ----------------------------------------------------------

  /// The level waits for a touch on the scene or its controls now (not during
  /// the intro, a card, a freeze, the praise window, a deck or the coworker).
  bool get _hintWaiting =>
      !_intro &&
      _mark == null &&
      !struckOut &&
      _card == null &&
      !_freeze &&
      !_busy &&
      !_ended &&
      !_run.ended &&
      !tableBusy &&
      !coworkerOnScreen &&
      // Station 6's deck carries its own sweep hint.
      (_docketOpen || _look != null || _run.station != M3GateStation.service || _run.serviceDone);

  Object get _hintKey => '${_run.station.name}|${_look?.name}|$_docketOpen|${_run.doorOpen}|${_run.pickingFuse}';

  Rect? _rectOf(String id) {
    final k = _gks[id];
    return k == null ? null : HintSpec.globalRectOf(k);
  }

  /// One rect around several things (a bank of fuses, a row of bolts).
  Rect? _bankOf(Iterable<String> ids) {
    Rect? out;
    for (final id in ids) {
      final r = _rectOf(id);
      if (r != null) out = out == null ? r : out.expandToInclude(r);
    }
    return out;
  }

  /// The ids of what can be touched now (every option, never just the right one).
  List<String> _hintIds() => switch (_run.station) {
        M3GateStation.sld => [for (final s in M3SldSym.values) 'sym-${s.name}', 'plan'],
        M3GateStation.patrol => [
            for (final p in M3Part.values)
              if (!_run.judged(p)) 'part-${p.name}',
          ],
        M3GateStation.fuseLa => [
            for (var i = 0; i < 3; i++)
              if (!_run.isDoDown(i)) 'do-$i',
            if (!_run.laJudged) 'la',
            if (_run.link == null)
              for (final l in _run.links) 'link-${l.name}',
          ],
        M3GateStation.dtr => [
            if (!_run.gelJudged) 'gel',
            if (!_run.oilJudged) 'oil',
            if (_run.ltOn) 'lt-switch',
            'tap',
          ],
        M3GateStation.pillar => _run.pickingFuse
            ? [for (final h in _run.hrcs) 'hrc-${h.name}']
            : [
                if (!_run.pGloves) 'ppe-gloves',
                if (!_run.pShield) 'ppe-shield',
                if (!_run.doorOpen) 'door' else ...['bus', 'lock'],
              ],
        M3GateStation.service => const [],
        M3GateStation.guard => [
            if (!_run.gGloves) 'guard-gloves',
            if (!_run.guardFixed)
              for (final f in M3GuardFault.values) 'guard-${f.name}',
            'energise',
          ],
      };

  /// How to touch now: a tap on the one way forward, else a sweep over every
  /// choice (it presses none and passes over the right one like the rest).
  HintSpec? _hint() {
    if (_docketOpen) return HintSpec.tapOn(_gk('docket-ok'));
    if (_look != null) return HintSpec.sweepOver([_gk('judge-ok'), _gk('judge-bad')]);
    final rects = [for (final id in _hintIds()) ?_rectOf(id)];
    if (_run.station == M3GateStation.pillar && _run.doorOpen && !_run.pickingFuse) {
      rects.addAll([
        ?_bankOf([for (var w = 0; w < 3; w++) for (var ph = 0; ph < 3; ph++) 'fuse-$w-$ph']),
        ?_bankOf([for (var i = 0; i < 6; i++) 'bolt-$i']),
      ]);
    }
    if (rects.isEmpty) return null;
    if (rects.length == 1) return HintSpec.tap(rects.single.center);
    // The hand enters at the first rect and glides on in order, so the list
    // must not follow the enum (AB-1 then NO, gel→oil→LT→tap is the answer).
    // A fixed per-play shuffle: steady while idle, unrelated to the steps.
    rects.shuffle(math.Random(widget.seed * 31 + 7 * _run.station.index + rects.length));
    return HintSpec.sweep(rects);
  }

  CustomPainter _lookPainter(M3Look l) {
    final part = _partOf(l);
    if (part != null) return M3PartPainter(part, _run.faults[part]);
    return switch (l) {
      M3Look.la => M3LaPainter(_run.laFault),
      M3Look.gel => _GelPainter(pink: _run.gelPinkDealt),
      _ => _OilPainter(leak: _run.oilLeakDealt),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut && _card == null;
    final deckUp = reasonOpen || coworkerChoiceUp;
    // During a death freeze nothing but the header takes a touch.
    final handsOn = playing && !deckUp && !_docketOpen && !_freeze;
    final look = _look;
    // A leak is reported, not replaced: only the LA and the gel are swapped.
    final badLabel = switch (look) {
      M3Look.la || M3Look.gel => M3GateLines.replaceLabel,
      M3Look.oil => M3GateLines.leakLabel,
      _ => M3GateLines.faultLabel,
    };

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
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            hintAutoMiss: true,
            progress: DoProgress(
              labels: [for (final s in M3GateStation.values) M3GateLines.stationTitles[s]!],
              done: {for (final s in _run.completed) s.index},
              current: _run.done ? null : _run.station.index,
              quiet: quiet,
            ),
            layers: (c, m) => [
              Positioned.fill(
                key: const ValueKey('scene'),
                child: ColorFiltered(
                  colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                  child: Stack(children: _layers(c, m)),
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
              if (playing && !_freeze)
                Positioned(
                  key: const ValueKey('station-chip'),
                  top: pad.top + 86,
                  right: 12,
                  child: _StationChip(
                    num: 'স্টেশন ${_run.station.index + 1}/7',
                    title: M3GateLines.stationTitles[_run.station]!,
                    onDocket: () {
                      if (!_canAct) return;
                      _cue('sounds/learn/card_deal_a.ogg', volume: 0.8);
                      setState(() => _docketOpen = true);
                    },
                  ),
                ),
              if (handsOn) ..._controls(pad),
              if (handsOn && look != null)
                Positioned.fill(
                  key: const ValueKey('look'),
                  child: _JudgeSheet(
                    title: M3GateLines.lookNames[look]!,
                    painter: _lookPainter(look),
                    badLabel: badLabel,
                    okKey: _gk('judge-ok'),
                    badKey: _gk('judge-bad'),
                    onOk: (p) => unawaited(_onJudge(false, p)),
                    onBad: (p) => unawaited(_onJudge(true, p)),
                    onClose: () => setState(() => _look = null),
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
                              lessonId: M3GateMistakes.lessonOf(_card!.key),
                              point: _card!.lessonPoint,
                              muted: _muted,
                            ),
                          ),
                  onGo: _dismissCard,
                ),
              if (struckOut && _card == null)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy ?? M3GateMistakes.wrongSymbol,
                  lessonId: strikeOutBy == null ? widget.ctx.lessonId : M3GateMistakes.lessonOf(strikeOutBy!.key),
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
                  line: M3GateLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
                  muted: _muted,
                  onDone: () => unawaited(_start()),
                ),
              if (_docketOpen && !_intro)
                Positioned.fill(
                  key: const ValueKey('docket-modal'),
                  child: _DocketSheet(
                    okKey: _gk('docket-ok'),
                    tapTo: _run.tapTo,
                    threePhase: _run.threePhase,
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

class _StickPainter extends CustomPainter {
  const _StickPainter({required this.from, required this.to});
  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFFF1C232)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StickPainter old) => old.from != from || old.to != to;
}

/// The breather close up: dry gel is blue, wet gel pink.
class _GelPainter extends CustomPainter {
  const _GelPainter({required this.pink});
  final bool pink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), Paint()..color = const Color(0xFFCFE6F5));
    final glass = Rect.fromCenter(center: size.center(Offset.zero), width: 70, height: size.height - 30);
    canvas.drawRect(Rect.fromLTWH(glass.center.dx - 5, 0, 10, glass.top), Paint()..color = const Color(0xFF55634F));
    canvas.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(10)), Paint()..color = const Color(0xFFF2F6F8));
    final dot = Paint()..color = pink ? const Color(0xFFF4A3C0) : const Color(0xFF2F6FD6);
    for (var y = glass.top + 10; y < glass.bottom - 6; y += 9) {
      for (var x = glass.left + 8; x < glass.right - 4; x += 9) {
        canvas.drawCircle(Offset(x, y), 3.6, dot);
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(glass, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFF55634F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_GelPainter old) => old.pink != pink;
}

/// The bottom of the tank close up: dry, or an oil drip and a dark puddle.
class _OilPainter extends CustomPainter {
  const _OilPainter({required this.leak});
  final bool leak;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), Paint()..color = const Color(0xFFCFE6F5));
    final tank = Rect.fromLTWH(20, 10, size.width - 40, size.height * 0.62);
    canvas.drawRect(tank, Paint()..color = const Color(0xFF7E8E77));
    canvas.drawRect(Rect.fromLTWH(0, tank.bottom, size.width, size.height - tank.bottom), Paint()..color = const Color(0xFFA9A397));
    for (var x = tank.left + 30; x < tank.right - 6; x += 12) {
      canvas.drawLine(Offset(x, tank.top + 8), Offset(x, tank.bottom - 6), Paint()
        ..color = const Color(0xFF55634F)
        ..strokeWidth = 3);
    }
    canvas.drawRect(Rect.fromLTWH(tank.left + 6, tank.bottom - 16, 22, 10), Paint()..color = const Color(0xFF4A5058));
    if (leak) {
      final oil = Paint()..color = const Color(0xFF3A2A12);
      canvas.drawPath(
        Path()
          ..moveTo(tank.left + 14, tank.bottom - 6)
          ..quadraticBezierTo(tank.left + 8, tank.bottom + 14, tank.left + 14, tank.bottom + 20)
          ..quadraticBezierTo(tank.left + 20, tank.bottom + 14, tank.left + 14, tank.bottom - 6),
        oil,
      );
      canvas.drawOval(Rect.fromCenter(center: Offset(tank.left + 30, tank.bottom + 26), width: 90, height: 16), Paint()..color = const Color(0xCC2A1E0C));
      canvas.drawLine(Offset(tank.left + 2, tank.top + 30), Offset(tank.left + 12, tank.bottom - 10), Paint()
        ..color = const Color(0x993A2A12)
        ..strokeWidth = 5);
    }
  }

  @override
  bool shouldRepaint(_OilPainter old) => old.leak != leak;
}

/// A part looked at up close, with the verdict buttons.
class _JudgeSheet extends StatelessWidget {
  const _JudgeSheet({
    required this.title,
    required this.painter,
    required this.badLabel,
    required this.onOk,
    required this.onBad,
    required this.onClose,
    this.okKey,
    this.badKey,
  });

  final String title;
  final CustomPainter painter;
  final GlobalKey? okKey;
  final GlobalKey? badKey;
  final String badLabel;
  final ValueChanged<Offset> onOk;
  final ValueChanged<Offset> onBad;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
                  Text(title, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                  const SizedBox(height: 8),
                  SizedBox(height: 170, width: double.infinity, child: CustomPaint(painter: painter)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: KeyedSubtree(key: okKey, child: _ActionButton(key: const ValueKey('judge-ok'), label: M3GateLines.okLabel, onTapUp: onOk)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: KeyedSubtree(key: badKey, child: _ActionButton(key: const ValueKey('judge-bad'), label: badLabel, filled: true, onTapUp: onBad)),
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
  const _ToolButton({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

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
  const _ActionButton({super.key, required this.label, required this.onTapUp, this.filled = false});
  final String label;
  final ValueChanged<Offset> onTapUp;
  final bool filled;

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
            color: filled ? SlmColors.gold400 : const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.gold400, width: 1.6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: filled ? SlmColors.navy950 : SlmColors.ivory),
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
            const Icon(Icons.bolt_rounded, color: SlmColors.gold300),
            const SizedBox(width: 8),
            Flexible(
              child: Text(M3GateRankText.stamp, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ),
          ],
        ),
      );
}

abstract final class M3GateRankText {
  static const stamp = 'নতুন র‍্যাঙ্ক: টেকনিশিয়ান · লাইন চেনার জাদুকর';
}

class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.tapTo, required this.threePhase, required this.onClose, this.okKey});
  final GlobalKey? okKey;
  final int tapTo;
  final bool threePhase;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.place_rounded, 'সাইট', 'ফিডার-7 · DTR-17 (100 kVA) · বটতলা মোড়', const Color(0xFF1565C0)),
      (Icons.warning_rounded, 'অভিযোগ', 'DTR-17-এর একটা DO ঝুলে পড়েছে · পাড়ায় কম ভোল্টেজ · পিলারের OUT লাইনে ফিউজ উড়েছে', const Color(0xFFC62828)),
      (Icons.power_off_rounded, 'শাটডাউন', 'SLD দেখে আইসোলেশন পয়েন্ট চিহ্নিত করে, লিখিত অনুমতি (PTW) নিয়ে', const Color(0xFFE65100)),
      (
        Icons.handyman_rounded,
        'কাজ',
        'পেট্রোল · DO ও LA · DTR স্বাস্থ্য, ট্যাপ ${M3GateRun.tapFrom} → $tapTo · ফিডার পিলার · নতুন ${threePhase ? '3-ফেজ' : '1-ফেজ'} সার্ভিস সংযোগ · রাস্তার গার্ডিং',
        const Color(0xFF2E7D32),
      ),
      (Icons.verified_user_rounded, 'সুরক্ষা', 'পুরো পিপিই আর ইনসুলেটেড টুল সঙ্গে · নিয়ম মেনে ধাপে ধাপে', const Color(0xFF6A1B9A)),
    ];
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
                            Text('টেকনিশিয়ানের ডকেট', style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text('ডকেট নং: DKT-F7-3110 · শাটডাউন কাজ', style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: SlmColors.gold300)),
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
                      for (final r in rows)
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
                        key: okKey,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                          label: Text(M3GateLines.docketOk, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
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
