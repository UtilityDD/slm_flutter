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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm4_streetlight_fix_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_streetlight_fix_world.dart' show M4StreetlightFixGeo, M4StreetlightFixSide, M4StreetlightFixBadSpot, M4StreetlightFixGear, M4StreetlightFixInsideGeo;

// Lesson 4.9 "রাস্তার আলো (Street Light) মেরামত", কাজ 2 "আলো ফেরাও"
// (pack do_4_9_b, engineType m4_streetlight_fix). A street light on a town
// corner is out of order at dusk (the docket says what it does and that the
// supply was found fine). The trainee repairs it from a ladder — safely — and
// brings the light back. Three stations a play:
//   ক নিচে — at the feeder pillar, the MCB of THIS light off (the MCBs carry
//     the pole numbers; the pole has its plate); the ladder on firm ground,
//     clear of the overhead line, tied to the pole; the harness on; climb;
//   খ ওপরে — the tester on the fixture before any touch (0 V, or LIVE: then
//     no touch, down and isolate); the loose, corroded terminal tightened
//     before any part is changed; the right part for the gear inside (the
//     ballast's lamp type and wattage, or the LED module with its driver);
//   গ আলো — down; the old discharge lamp into the scrap crate, not the
//     dustbin; the MCBs back ON — at dusk the photocell lights it.
//
// The lesson's rules, and only those:
//   • point 0: the parts — HPSV / MH lamps run on a ballast (+ ignitor,
//     capacitor), an LED on a driver; photocell on top;
//   • point 1: the flow — supply checked, then the lamp; on-off cycling = an
//     old HPSV lamp at the end of its life; check and tighten the wiring;
//   • point 2: isolate THAT light's fuse / MCB before work and prove with a
//     tester that the fixture has no voltage; a ladder or sky lift that is
//     stable, secured and a safe distance from overhead lines; old lamps
//     (mercury) disposed of by the rules;
//   • myth 1: "only a lamp — no need to switch off" (the holder's contacts
//     are live); myth 2: any ballast with any lamp (70W HPSV, 150W MH);
//   • pro tips 1 (LED module + driver changed together), 4 (most faults are
//     loose or corroded connections — check and tighten before replacing).
// From the module's safety rules (the brief, NOT lesson 4.9's text — flagged
// in REGISTER.md): helmet + harness for anyone going up; the pole numbers on
// the MCB tags; the scrap crate's label.
//
// Deadly (lesson point 2 / myth 1): a hand on the terminals or the lamp
// holder while the light is live — untested, after a LIVE reading, or by
// listening to the coworker ("কোনো দরকার নেই MCB নামানোর!"). Slips: a
// ladder on the bad spot (by the line, or a broken slab), climbing untied or
// without the harness, a touch before proving dead (when it is dead), a part
// before tightening, the wrong part (three kinds), the old lamp in the
// dustbin. Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m4_streetlight_fix_world.dart), corner guide, ◆ on the table →
// "কেন …?" at each station's end; the careless coworker once a play, at the
// pillar before the MCB is off. Voice: the guide by device TTS; the
// coworker's new push by device TTS until recorded (his exit line is his
// existing recorded clip).

// ============================================================================
// Content
// ============================================================================

/// What the docket says the light does (and so which gear is inside).
enum M4StreetlightFixFault { hpsvCycling, mhDark, ledDark }

/// The parts on his belt (one is right for the fault).
enum M4StreetlightFixPart { hpsv70, mh150, ledSet, photocell }

enum M4StreetlightFixStation { base, top, finish }

/// What the first station's reason asks about.
enum M4StreetlightFixWhyBase { isolate, spot }

/// The hands-on tools.
enum M4StreetlightFixTool { none, ladder, driver }

abstract final class M4StreetlightFixLines {
  static const title = 'আলো ফেরাও';
  static const intro = 'মোড়ের আলো খারাপ — অন্ধকারে বিপদ! নিরাপদে সারিয়ে আলো ফেরান।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askBase = 'ওঠার আগে নিচের কাজ গুছিয়ে নিন।';
  static const askClimb = 'সব তৈরি? এবার ওপরে।';
  static const askProve = 'ফিক্সচারে হাত দেওয়ার আগে কী করবেন?';
  static const askLive = 'লাইভ! হাত নয় — আগে লাইনটা বিচ্ছিন্ন।';
  static const askFix = 'ভেতরটা দেখে মেরামত করুন।';
  static const askDown = 'মেরামত শেষ — এবার নিচে।';
  static const askFinish = 'আলো ফেরানোর শেষ কাজগুলো সারুন।';
  static const tasks = [askBase, askClimb, askProve, askLive, askFix, askDown, askFinish];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, parts, the docket).
  static const sceneLabel = 'রাস্তার মোড়';
  static const ladder = 'মই';
  static const rope = 'দড়ি';
  static const harness = 'হারনেস';
  static const tester = 'টেস্টার';
  static const driver = 'স্ক্রুড্রাইভার';
  static const down = 'নামুন';
  static const docket = 'ডকেট';
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const stampOn = 'আলো ফিরল';
  static String partBn(M4StreetlightFixPart p) => switch (p) {
        M4StreetlightFixPart.hpsv70 => 'HPSV 70W',
        M4StreetlightFixPart.mh150 => 'MH 150W',
        M4StreetlightFixPart.ledSet => 'LED সেট',
        M4StreetlightFixPart.photocell => 'ফটোসেল',
      };
  static String faultBn(M4StreetlightFixFault f) => switch (f) {
        M4StreetlightFixFault.hpsvCycling => 'জ্বলছে-নিভছে',
        M4StreetlightFixFault.mhDark || M4StreetlightFixFault.ledDark => 'জ্বলছে না · সাপ্লাই ঠিক',
      };
  static String docketBn(int pole, M4StreetlightFixFault f) => enDigits('SL-$pole · ${faultBn(f)}');

  // The reasons (lesson 4.9): the right ones fit what was done; the wrong
  // ones are the lesson's myths and field excuses — never a true rule marked
  // wrong. Every card 36–46 letters.
  static const whyIsolateQ = 'কেন ওঠার আগে MCB বন্ধ করলেন?';
  static const whySpotQ = 'কেন এই দিকে মই দাঁড় করালেন?';
  static const whyPartQ = 'কেন এই পার্টটাই লাগালেন?';
  static const whyDisposeQ = 'কেন পুরনো ল্যাম্প বাতিলের বাক্সে?';
  static const whyTestQ = 'কেন হাত দেওয়ার আগে টেস্টারে দেখলেন?';
  static const isolateWhy = ['হোল্ডারের ভেতরের কন্টাক্ট লাইভ থাকে, তাই বন্ধ', 'শুধু ল্যাম্প হলেও লাইন বিচ্ছিন্ন করেই কাজ'];
  static const spotLineWhy = ['ওদিকে মইয়ের মাথা ওভারহেড লাইনের খুব কাছে', 'মই রাখতে হয় ওপরের লাইন থেকে নিরাপদ দূরে'];
  static const spotSlabWhy = ['ভাঙা স্ল্যাবে মই টলবে, তাই শক্ত জায়গায়', 'মই যেন স্থির থাকে, তাই সমান শক্ত জায়গায়'];
  static const partHpsvWhy = ['ব্যালাস্টে HPSV 70W, তাই ঠিক সেই ল্যাম্পই', 'জ্বলছে-নিভছে মানে সোডিয়াম ল্যাম্পের আয়ু শেষ'];
  static const partMhWhy = ['ব্যালাস্টে MH 150W লেখা, তাই সেই ল্যাম্পই', 'সাপ্লাই ঠিক থাকলে আগে ল্যাম্প বদলে দেখা'];
  static const partLedWhy = ['এলইডি-তে মডিউল আর ড্রাইভার একসাথে বদলায়', 'ভেতরে ব্যালাস্ট নেই, আছে এলইডি ড্রাইভার'];
  static const disposeWhy = ['পুরনো ল্যাম্পে পারদ থাকতে পারে, নিয়মে ফেলা', 'বিপজ্জনক পদার্থ থাকে, তাই ডাস্টবিনে নয়'];
  static const testWhy = ['MCB নামালেও টেস্টারে নিশ্চিত হওয়া চাই', 'অনুমান নয় — ভোল্টেজ নেই দেখে তবে হাত'];
  static const myths = [
    'শুধু ল্যাম্প বদলাতে লাইন বন্ধের দরকার নেই',
    'যেকোনো ব্যালাস্টে যেকোনো ল্যাম্প চলে যায়',
    'খুব সাবধানে হাত দিলে লাইভেও কিছু হয় না',
    'মই যেখানে খুশি দাঁড় করালেই কাজ চলে যায়',
    'পুরনো ল্যাম্প যেকোনো ডাস্টবিনে ফেলা যায়',
    'যেটা হাতের কাছে ছিল, সেটাই লাগিয়ে দিলাম',
    'অন্ধকার নামছে, তাই তাড়াতাড়ি সেরে ফেললাম',
  ];
  static const allRight = [...isolateWhy, ...spotLineWhy, ...spotSlabWhy, ...partHpsvWhy, ...partMhWhy, ...partLedWhy, ...disposeWhy, ...testWhy];

  /// The careless coworker: "only a lamp — climb up, no MCB".
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'কোনো দরকার নেই MCB নামানোর! শুধু তো ল্যাম্প — মই লাগিয়ে উঠে পড়ো।',
    exitLine: coworkerExit,
    right: ['না, আগে এই লাইটের MCB বন্ধ, তবে কাজ', 'না, হোল্ডার লাইভ থাকে — আগে বিচ্ছিন্ন', 'না, বন্ধ করে টেস্টারে দেখে তবে হাত'],
    wrong: [
      'ঠিক, শুধু ল্যাম্প তো, চালুতেই বদলাই',
      'আচ্ছা, সাবধানে হাত দিলে কিছু হবে না',
      'MCB নামানোর ঝামেলা না করেই উঠি',
      'ঠিক আছে, দুই মিনিটের কাজ, চালুতেই',
      'হ্যাঁ, গ্লাভস তো আছে, লাইভেই সারি',
    ],
    asks: ['ও বলছে MCB না নামিয়েই উঠতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'লাইভ ফিক্সচারে হাত দেবেন?'],
  );

  /// When the MCB was already off before he could push: "no tester".
  static const coworkerTop = CoworkerScript(
    line: 'MCB তো নামিয়েছ — আবার টেস্টার কেন? সময় নষ্ট, হাত লাগাও!',
    exitLine: coworkerExit,
    right: ['না, টেস্টারে ভোল্টেজ নেই দেখে তবে হাত', 'না, অনুমান নয় — আগে টেস্টারে পরীক্ষা', 'না, MCB নামালেও আগে টেস্টারে দেখব'],
    wrong: [
      'ঠিক, MCB তো নামানো, এখনই হাত দিই',
      'আচ্ছা, টেস্টার ছাড়াই খুলে ফেলি',
      'হ্যাঁ, বারবার পরীক্ষা মানেই সময় নষ্ট',
      'ঠিক আছে, নামানো আছে, লাগিয়ে দিই',
      'ঠিক, একবার নামালেই তো সব নিরাপদ',
    ],
    asks: ['ও বলছে টেস্টার ছাড়াই হাত দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'না দেখেই হাত দেবেন?'],
  );

  static const callHeld = 'ঠিক! শুধু ল্যাম্প হলেও আগে লাইন বিচ্ছিন্ন।';
  static const allSet = 'মোড়ে আলো ফিরল — বিচ্ছিন্ন করে, পরীক্ষা করে, নিরাপদে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে বিচ্ছিন্ন, পরীক্ষা, তারপর মেরামত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtIsolate = 'ওঠার আগে ঠিক MCB বন্ধ';
  static const caughtSpot = 'মই শক্ত, নিরাপদ জায়গায়';
  static const caughtTied = 'মই বেঁধে, হারনেস পরে ওঠা';
  static const caughtProve = 'হাত দেওয়ার আগে টেস্টারে 0 V';
  static const caughtLive = 'টেস্টারে লাইভ ধরে হাত সরিয়েছেন';
  static const caughtTight = 'ঢিলা কানেকশন আগে টাইট';
  static const caughtPart = 'গিয়ার মিলিয়ে ঠিক পার্ট';
  static const caughtDispose = 'পুরনো ল্যাম্প বাতিলের বাক্সে';
  static const caughtCall = '“MCB লাগবে না” — না বলেছেন';
  static const caughtCallTop = '“টেস্টার লাগবে না” — না বলেছেন';
}

abstract final class M4StreetlightFixMistakes {
  static const _dir = 'assets/game/art/m4_streetlight_fix';

  static const touchLive = DoMistake(
    key: '4.9/streetlight_fix/touch-live',
    textBn: 'হোল্ডার আর টার্মিনাল লাইভ ছিল! আগে ওই লাইটের MCB বন্ধ, তারপর টেস্টারে ভোল্টেজ নেই দেখে তবে হাত।',
    art: '$_dir/live_holder.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const noProve = DoMistake(
    key: '4.9/streetlight_fix/not-proven-dead',
    textBn: 'MCB নামানোই যথেষ্ট নয় — হাত দেওয়ার আগে টেস্টারে দেখুন ফিক্সচারে ভোল্টেজ নেই। অনুমান নয়, পরীক্ষা।',
    art: '$_dir/test_first.svg',
    lessonPoint: 2,
  );
  static const spotLine = DoMistake(
    key: '4.9/streetlight_fix/ladder-by-line',
    textBn: 'এদিকে মইয়ের মাথা ওভারহেড লাইনের একদম কাছে। মই রাখুন লাইন থেকে নিরাপদ দূরত্বে।',
    art: '$_dir/ladder_line.svg',
    lessonPoint: 2,
  );
  static const spotSlab = DoMistake(
    key: '4.9/streetlight_fix/ladder-on-broken-slab',
    textBn: 'ভাঙা স্ল্যাবে মই টলবে। মই দাঁড় করান শক্ত, সমান জায়গায় — প্ল্যাটফর্ম স্থিতিশীল চাই।',
    art: '$_dir/ladder_slab.svg',
    lessonPoint: 2,
  );
  static const noTie = DoMistake(
    key: '4.9/streetlight_fix/ladder-untied',
    textBn: 'মই আগে খুঁটির সঙ্গে বেঁধে নিন — না-বাঁধা মই পিছলে যেতে পারে। প্ল্যাটফর্ম সুরক্ষিত চাই।',
    art: '$_dir/ladder_tie.svg',
    lessonPoint: 2,
  );
  // Helmet + harness for anyone going up: the module's rule (the brief), not
  // lesson 4.9's text — no lesson point.
  static const noHarness = DoMistake(
    key: '4.9/streetlight_fix/no-harness',
    textBn: 'ওপরে উঠতে হেলমেট আর সেফটি হারনেস চাই — হারনেস না পরে মইয়ে উঠবেন না।',
    art: '$_dir/harness.svg',
  );
  static const noTighten = DoMistake(
    key: '4.9/streetlight_fix/part-before-tighten',
    textBn: 'পার্ট বদলের আগে কানেকশন দেখে টাইট দিন — বেশিরভাগ সমস্যা ঢিলা বা ক্ষয়ে যাওয়া কানেকশনে।',
    art: '$_dir/loose_terminal.svg',
    lessonPoint: 1,
  );
  static const wrongLamp = DoMistake(
    key: '4.9/streetlight_fix/wrong-lamp-for-ballast',
    textBn: 'ব্যালাস্টে লেখা ধরন আর ওয়াটের ল্যাম্পই লাগান — ভুল জুটিতে ল্যাম্প জ্বলবে না বা দ্রুত নষ্ট হবে।',
    art: '$_dir/part_match.svg',
    lessonPoint: 0,
  );
  static const wrongKind = DoMistake(
    key: '4.9/streetlight_fix/wrong-kind',
    textBn: 'ভেতরের গিয়ার দেখে পার্ট বাছুন: ব্যালাস্ট থাকলে মিলিয়ে ল্যাম্প, এলইডি ড্রাইভার থাকলে মডিউল আর ড্রাইভার।',
    art: '$_dir/part_match.svg',
    lessonPoint: 0,
  );
  static const wrongPhotocell = DoMistake(
    key: '4.9/streetlight_fix/photocell-not-the-fault',
    textBn: 'ফটোসেল খারাপ হলে লাইট দিন-রাত জ্বলে। এখানে তা নয় — সাপ্লাই ঠিক, তাই ল্যাম্প বা ড্রাইভার।',
    art: '$_dir/part_match.svg',
    lessonPoint: 1,
  );
  static const dustbin = DoMistake(
    key: '4.9/streetlight_fix/lamp-in-dustbin',
    textBn: 'পুরনো ল্যাম্পে পারদ বা অন্য বিপজ্জনক পদার্থ থাকতে পারে — ডাস্টবিনে নয়, নিয়ম অনুযায়ী আলাদা জমা।',
    art: '$_dir/scrap_box.svg',
    lessonPoint: 2,
  );

  static List<DoMistake> get all => const [touchLive, noProve, spotLine, spotSlab, noTie, noHarness, noTighten, wrongLamp, wrongKind, wrongPhotocell, dustbin];
}

@immutable
class M4StreetlightFixDeal {
  const M4StreetlightFixDeal({
    required this.fault,
    required this.parts,
    required this.poleNo,
    required this.otherNo,
    required this.mineSlot,
    required this.badSide,
    required this.badKind,
    required this.loose,
    required this.whyBase,
  });

  final M4StreetlightFixFault fault;

  /// The parts on the belt, in the order shown.
  final List<M4StreetlightFixPart> parts;
  final int poleNo;

  /// The neighbouring light's number (the other MCB).
  final int otherNo;

  /// Which MCB in the pillar is this light's (0 left, 1 right).
  final int mineSlot;
  final M4StreetlightFixSide badSide;
  final M4StreetlightFixBadSpot badKind;

  /// The loose, corroded terminal (0 L, 1 N, 2 E).
  final int loose;
  final M4StreetlightFixWhyBase whyBase;

  M4StreetlightFixSide get goodSide => badSide == M4StreetlightFixSide.left ? M4StreetlightFixSide.right : M4StreetlightFixSide.left;

  M4StreetlightFixGear get gear => switch (fault) {
        M4StreetlightFixFault.hpsvCycling => M4StreetlightFixGear.hpsv70,
        M4StreetlightFixFault.mhDark => M4StreetlightFixGear.mh150,
        M4StreetlightFixFault.ledDark => M4StreetlightFixGear.led,
      };

  M4StreetlightFixPart get rightPart => switch (fault) {
        M4StreetlightFixFault.hpsvCycling => M4StreetlightFixPart.hpsv70,
        M4StreetlightFixFault.mhDark => M4StreetlightFixPart.mh150,
        M4StreetlightFixFault.ledDark => M4StreetlightFixPart.ledSet,
      };

  /// The old part is a discharge lamp (mercury): it goes to the scrap crate.
  bool get oldLamp => fault != M4StreetlightFixFault.ledDark;
}

const _m4StreetlightFixPoles = [7, 12, 18, 23, 31, 36, 44];

/// One street light a play: the fault, the parts' order, the pole numbers
/// and which MCB is this light's, the bad ladder spot (by the LT line — on
/// the left — or a broken slab on either side), the loose terminal.
M4StreetlightFixDeal m4StreetlightFixDeal(math.Random rng) {
  final fault = M4StreetlightFixFault.values[rng.nextInt(3)];
  final parts = [...M4StreetlightFixPart.values]..shuffle(rng);
  final pole = _m4StreetlightFixPoles[rng.nextInt(_m4StreetlightFixPoles.length)];
  final other = rng.nextBool() ? pole + 1 : pole - 1;
  final spot = rng.nextInt(3);
  return M4StreetlightFixDeal(
    fault: fault,
    parts: parts,
    poleNo: pole,
    otherNo: other,
    mineSlot: rng.nextInt(2),
    badSide: spot == 2 ? M4StreetlightFixSide.right : M4StreetlightFixSide.left,
    badKind: spot == 0 ? M4StreetlightFixBadSpot.line : M4StreetlightFixBadSpot.slab,
    loose: rng.nextInt(3),
    whyBase: rng.nextBool() ? M4StreetlightFixWhyBase.isolate : M4StreetlightFixWhyBase.spot,
  );
}

/// The play state (pure logic).
class M4StreetlightFixRun {
  M4StreetlightFixRun(this.deal);
  final M4StreetlightFixDeal deal;

  M4StreetlightFixStation station = M4StreetlightFixStation.base;
  int slips = 0;
  int stationSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// Each MCB in the pillar (slot 0, slot 1): ON at the start.
  final List<bool> mcbOn = [true, true];
  M4StreetlightFixTool tool = M4StreetlightFixTool.none;
  M4StreetlightFixSide? ladder;
  var tied = false;
  var harness = false;
  var up = false;
  var climbed = false;

  /// MCB of this light was off at the first climb (the isolate reason fits).
  var isolatedAtClimb = false;
  var proved = false;
  var liveSeen = false;
  var tightened = false;
  M4StreetlightFixPart? fitted;
  var oldInHand = false;
  var inCrate = false;
  var inBin = false;
  var done = false;

  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get clean => stationSlips == 0;
  int get stationIndex => station.index;

  /// This light's MCB is ON (the fixture is live).
  bool get live => mcbOn[deal.mineSlot];
  bool get otherOn => mcbOn[1 - deal.mineSlot];

  /// The light burns: fixed and switched on (dusk: the photocell has it on).
  bool get lightOn => fitted != null && live && !up;

  /// The last station's work is all done.
  bool get finishReady => station == M4StreetlightFixStation.finish && lightOn && otherOn && (!deal.oldLamp || inCrate);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  bool get _open => !ended;

  /// The MCB in [slot]: only from the footpath. False = it did not move.
  bool toggleMcb(int slot) {
    if (!_open || up) return false;
    mcbOn[slot] = !mcbOn[slot];
    proved = false;
    return true;
  }

  /// Picks up [t] (or puts it down, if held).
  void hold(M4StreetlightFixTool t) {
    if (!_open) return;
    if (t == M4StreetlightFixTool.ladder && (ladder != null || up)) return;
    if (t == M4StreetlightFixTool.driver && !up) return;
    tool = tool == t ? M4StreetlightFixTool.none : t;
  }

  /// Stands the ladder against the pole on [side].
  DoMistake? placeLadder(M4StreetlightFixSide side) {
    if (!_open || tool != M4StreetlightFixTool.ladder || ladder != null) return null;
    if (side == deal.badSide) {
      return _slip(deal.badKind == M4StreetlightFixBadSpot.line ? M4StreetlightFixMistakes.spotLine : M4StreetlightFixMistakes.spotSlab);
    }
    ladder = side;
    tool = M4StreetlightFixTool.none;
    _tag(M4StreetlightFixLines.caughtSpot);
    return null;
  }

  /// The rope round the ladder and the pole. False = not now (no ladder).
  bool tie() {
    if (!_open || ladder == null || tied || up) return false;
    tied = true;
    return true;
  }

  void wearHarness() {
    if (_open) harness = true;
  }

  /// Up the ladder. Null and [up] = he is at the top.
  DoMistake? climb() {
    if (!_open || ladder == null || up || station == M4StreetlightFixStation.finish) return null;
    if (!tied) return _slip(M4StreetlightFixMistakes.noTie);
    if (!harness) return _slip(M4StreetlightFixMistakes.noHarness);
    up = true;
    tool = M4StreetlightFixTool.none;
    _tag(M4StreetlightFixLines.caughtTied);
    if (!climbed) {
      climbed = true;
      isolatedAtClimb = !live;
    }
    return null;
  }

  /// First climb done: the base station is over.
  void toTop() {
    station = M4StreetlightFixStation.top;
    stationSlips = 0;
  }

  /// Down the ladder (any time). After the repair: the last station.
  void descend() {
    if (!_open || !up) return;
    up = false;
    tool = M4StreetlightFixTool.none;
    if (fitted != null) {
      station = M4StreetlightFixStation.finish;
      stationSlips = 0;
    }
  }

  /// The tester on the fixture: true = live.
  bool test() {
    if (!_open || !up) return false;
    if (live) {
      liveSeen = true;
      return true;
    }
    proved = true;
    _tag(M4StreetlightFixLines.caughtProve);
    if (liveSeen) _tag(M4StreetlightFixLines.caughtLive);
    return false;
  }

  /// Any hand inside the fixture: live = deadly; untested = a slip.
  DoMistake? _touch() {
    if (live) return deadly = M4StreetlightFixMistakes.touchLive;
    if (!proved) return _slip(M4StreetlightFixMistakes.noProve);
    return null;
  }

  /// The screwdriver on terminal [i].
  DoMistake? tighten(int i) {
    if (!_open || !up || tool != M4StreetlightFixTool.driver || fitted != null) return null;
    final m = _touch();
    if (m != null) return m;
    if (i == deal.loose && !tightened) {
      tightened = true;
      tool = M4StreetlightFixTool.none;
      _tag(M4StreetlightFixLines.caughtTight);
    }
    return null;
  }

  /// Fits [p] in place of the old part. Null and [fitted] = done.
  DoMistake? fit(M4StreetlightFixPart p) {
    if (!_open || !up || fitted != null) return null;
    final m = _touch();
    if (m != null) return m;
    if (!tightened) return _slip(M4StreetlightFixMistakes.noTighten);
    if (p != deal.rightPart) {
      if (p == M4StreetlightFixPart.photocell) return _slip(M4StreetlightFixMistakes.wrongPhotocell);
      final lampGear = deal.fault != M4StreetlightFixFault.ledDark;
      final lampPart = p != M4StreetlightFixPart.ledSet;
      return _slip(lampGear && lampPart ? M4StreetlightFixMistakes.wrongLamp : M4StreetlightFixMistakes.wrongKind);
    }
    fitted = p;
    tool = M4StreetlightFixTool.none;
    oldInHand = deal.oldLamp;
    _tag(M4StreetlightFixLines.caughtPart);
    return null;
  }

  /// The old lamp into the scrap crate.
  bool toCrate() {
    if (!_open || up || !oldInHand) return false;
    oldInHand = false;
    inCrate = true;
    _tag(M4StreetlightFixLines.caughtDispose);
    return true;
  }

  /// The old lamp into the dustbin: a slip (it stays in hand).
  DoMistake? toBin() {
    if (!_open || up || !oldInHand) return null;
    return _slip(M4StreetlightFixMistakes.dustbin);
  }

  void finish() => done = true;

  /// Fails the play (listening to the coworker): he climbs and touches it live.
  void failDeadly(DoMistake m) {
    ladder ??= deal.goodSide;
    up = true;
    deadly = m;
  }

  /// Listened to "no tester" at the top: a hand inside, untested.
  DoMistake listenTop() {
    if (live) return deadly = M4StreetlightFixMistakes.touchLive;
    return _slip(M4StreetlightFixMistakes.noProve);
  }

  /// The reason for the first station fits what he did.
  M4StreetlightFixWhyBase get whyBase => deal.whyBase == M4StreetlightFixWhyBase.isolate && isolatedAtClimb ? M4StreetlightFixWhyBase.isolate : M4StreetlightFixWhyBase.spot;

  List<String> whyRight(M4StreetlightFixStation s) => switch (s) {
        M4StreetlightFixStation.base => whyBase == M4StreetlightFixWhyBase.isolate
            ? M4StreetlightFixLines.isolateWhy
            : (deal.badKind == M4StreetlightFixBadSpot.line ? M4StreetlightFixLines.spotLineWhy : M4StreetlightFixLines.spotSlabWhy),
        M4StreetlightFixStation.top => switch (deal.fault) {
            M4StreetlightFixFault.hpsvCycling => M4StreetlightFixLines.partHpsvWhy,
            M4StreetlightFixFault.mhDark => M4StreetlightFixLines.partMhWhy,
            M4StreetlightFixFault.ledDark => M4StreetlightFixLines.partLedWhy,
          },
        M4StreetlightFixStation.finish => deal.oldLamp ? M4StreetlightFixLines.disposeWhy : M4StreetlightFixLines.testWhy,
      };

  String whyQuestion(M4StreetlightFixStation s) => switch (s) {
        M4StreetlightFixStation.base => whyBase == M4StreetlightFixWhyBase.isolate ? M4StreetlightFixLines.whyIsolateQ : M4StreetlightFixLines.whySpotQ,
        M4StreetlightFixStation.top => M4StreetlightFixLines.whyPartQ,
        M4StreetlightFixStation.finish => deal.oldLamp ? M4StreetlightFixLines.whyDisposeQ : M4StreetlightFixLines.whyTestQ,
      };
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
/// ms, ~1500 per human action:
///   ক: MCB, ladder + spot, rope, harness, climb ≈ 9000, the coworker
///     ≈ 9600, reason ≈ 8200                                        ≈ 26800
///   খ: tester ~2500, driver, terminal, part ≈ 7000, reason ≈ 8200   ≈ 15200
///   গ: down, crate, MCB, the light ≈ 6000, reason ≈ 8200            ≈ 14200
/// ≈ 56200; 85 % ≈ 47800 → 50 s.
const kM4StreetlightFixQuickMs = 50000;

@immutable
class M4StreetlightFixPack {
  const M4StreetlightFixPack({required this.id, required this.titleBn, this.quickMs = kM4StreetlightFixQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4StreetlightFixPack> m4StreetlightFixPacks = {
  'do_4_9_b': M4StreetlightFixPack(id: 'do_4_9_b', titleBn: M4StreetlightFixLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4StreetlightFixPage extends StatefulWidget {
  const M4StreetlightFixPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4StreetlightFixPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4StreetlightFixPage> createState() => _M4StreetlightFixPageState();
}

class _M4StreetlightFixPageState extends State<M4StreetlightFixPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FixRunPage(
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

class _FixRunPage extends ConsumerStatefulWidget {
  const _FixRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4StreetlightFixPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FixRunPage> createState() => _FixRunPageState();
}

class _FixRunPageState extends ConsumerState<_FixRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4StreetlightFixRun _run = M4StreetlightFixRun(m4StreetlightFixDeal(widget.rng));
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

  /// The station whose reason is on the table (null = none).
  M4StreetlightFixStation? _asking;

  /// The tester's lamp, a moment after it touches the fixture.
  bool? _tester;
  Timer? _testerTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _testerTimer?.cancel();
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

  Future<void> _start() async {
    _clock.start();
    _lastTask = _task;
    unawaited(_sayChain([_task]));
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_freeze;

  String get _task {
    final r = _run;
    switch (r.station) {
      case M4StreetlightFixStation.base:
        return r.ladder != null && r.tied && r.harness ? M4StreetlightFixLines.askClimb : M4StreetlightFixLines.askBase;
      case M4StreetlightFixStation.top:
        if (!r.up) return r.liveSeen && r.live ? M4StreetlightFixLines.askLive : M4StreetlightFixLines.askClimb;
        if (r.fitted != null) return M4StreetlightFixLines.askDown;
        if (r.liveSeen && r.live) return M4StreetlightFixLines.askLive;
        if (!r.proved) return M4StreetlightFixLines.askProve;
        return M4StreetlightFixLines.askFix;
      case M4StreetlightFixStation.finish:
        return M4StreetlightFixLines.askFinish;
    }
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  /// He comes once a play: at the footpath while this light is still ON
  /// (as the work starts), or else at the top before the tester.
  var _coworkerAtTop = false;
  void _armCoworker() {
    if (coworkerDone || _coworkerArmed || _run.station != M4StreetlightFixStation.base || !_run.live) return;
    _coworkerArmed = true;
    _coworkerAtTop = false;
    scheduleCoworker();
  }

  var _coworkerArmed = false;

  void _hold(M4StreetlightFixTool t) {
    if (!_canPlay) return;
    _armCoworker();
    _tick('sounds/quiz_select.wav');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _tie() {
    if (!_canPlay) return;
    _armCoworker();
    if (_run.tie()) {
      _tick('sounds/learn/tag_slap.wav', 0.5);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
    setState(() => _wake++);
    _maybeNextTask();
  }

  void _harness() {
    if (!_canPlay || _run.harness) return;
    _armCoworker();
    _tick('sounds/learn/tag_slap.wav', 0.4);
    setState(() {
      _run.wearHarness();
      _wake++;
    });
    _maybeNextTask();
  }

  /// When everything below is ready, the guide says so once.
  String? _lastTask;
  void _maybeNextTask() {
    final t = _task;
    if (t != _lastTask) {
      _lastTask = t;
      unawaited(_sayChain([t]));
    }
  }

  void _useTester() {
    if (!_canPlay || !_run.up) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final live = _run.test();
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
    _maybeNextTask();
  }

  void _climbOrDown() {
    if (!_canPlay) return;
    if (_run.up) {
      _tick('sounds/intro/click.ogg', 0.5);
      setState(() {
        _run.descend();
        _wake++;
      });
      _maybeNextTask();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    final m = _run.climb();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, _centre));
      return;
    }
    if (_run.up && _run.station == M4StreetlightFixStation.base) {
      _run.toTop();
      _stationDone(M4StreetlightFixStation.base, clean: _cleanBase);
      return;
    }
    if (_run.up) _maybeNextTask();
  }

  var _cleanBase = true;

  Offset get _centre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  void _tapScene(Offset p, M4StreetlightFixGeo geo, Offset global) {
    if (_intro || _ended || _card != null || reasonOpen || _freeze) return;
    final r = _run;
    final mine = r.deal.mineSlot;
    // While he talks, the answer is on the deck.
    if (coworkerOpen) return;
    if (r.up) {
      final l = r.ladder;
      if (l != null && geo.ladderHit(l).contains(p)) _climbOrDown();
      return;
    }
    // The old lamp in hand: the crate or the bin.
    if (r.oldInHand) {
      if (geo.crateHit.contains(p)) {
        _tick('sounds/learn/tag_slap.wav', 0.5);
        setState(() {
          r.toCrate();
          _wake++;
        });
        _checkFinish();
        return;
      }
      if (geo.dustbinHit.contains(p)) {
        final m = r.toBin();
        setState(() => _wake++);
        if (m != null) unawaited(_mistake(m, global));
        return;
      }
    }
    if (r.tool == M4StreetlightFixTool.ladder) {
      for (final s in M4StreetlightFixSide.values) {
        if (geo.spotHit(s).contains(p)) {
          _tick('sounds/intro/impact_metal.ogg', 0.4);
          final m = r.placeLadder(s);
          setState(() => _wake++);
          if (m != null) {
            unawaited(_mistake(m, global));
          } else {
            _maybeNextTask();
          }
          return;
        }
      }
    }
    for (var s = 0; s < 2; s++) {
      if (geo.mcbHit(s).contains(p)) {
        if (s != mine) _armCoworker();
        if (r.toggleMcb(s)) {
          _tick('sounds/intro/impact_metal.ogg', 0.5);
        } else {
          _tick('sounds/intro/click.ogg', 0.3);
        }
        setState(() => _wake++);
        if (r.lightOn && r.station == M4StreetlightFixStation.finish) _cue('sounds/learn/card_deal_a.wav', volume: 0.5);
        _checkFinish();
        return;
      }
    }
    final l = r.ladder;
    if (l != null && geo.ladderHit(l).contains(p)) {
      if (r.station != M4StreetlightFixStation.finish) _climbOrDown();
      return;
    }
  }

  void _tapTerminal(int i, Offset global) {
    if (!_canPlay || !_run.up) return;
    _tick();
    final was = _run.tightened;
    final m = _run.tighten(i);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    if (!was && _run.tightened) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.5);
      HapticFeedback.lightImpact();
    }
  }

  void _fit(M4StreetlightFixPart p, Offset global) {
    if (!_canPlay || !_run.up || _run.fitted != null) return;
    _tick('sounds/quiz_select.wav');
    final m = _run.fit(p);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    _stationDone(M4StreetlightFixStation.top, clean: _run.clean);
  }

  void _checkFinish() {
    if (!_run.finishReady || _asking != null) return;
    _stationDone(M4StreetlightFixStation.finish, clean: _run.clean);
  }

  void _stationDone(M4StreetlightFixStation s, {required bool clean}) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    _asking = s;
    putOnTable(15 + (clean ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(_run.whyRight(s), M4StreetlightFixLines.myths, widget.rng),
      question: _run.whyQuestion(s),
      stillValid: () => _asking == s && !_ended,
    ));
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    if (_run.station == M4StreetlightFixStation.base) _cleanBase = false;
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
    final s = _asking;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended || _asking != s) return;
      _asking = null;
      if (s == M4StreetlightFixStation.finish) {
        setState(_run.finish);
        unawaited(_finish());
        return;
      }
      setState(() => _wake++);
      _lastTask = _task;
      unawaited(_sayChain([_task]));
      if (s == M4StreetlightFixStation.base && !coworkerDone) {
        _coworkerAtTop = true;
        scheduleCoworker();
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _coworkerAtTop ? M4StreetlightFixLines.coworkerTop : M4StreetlightFixLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final r = _run;
    if (_ended) return null;
    if (_coworkerAtTop) {
      if (!r.up || r.station != M4StreetlightFixStation.top || r.proved || r.liveSeen || r.fitted != null) return null;
    } else if (r.station != M4StreetlightFixStation.base || r.up || !r.live) {
      return null;
    }
    if (_intro || _card != null || reasonOpen || _freeze || _tester != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      if (_coworkerAtTop) {
        // Listened: a hand inside, untested (live = deadly; dead = a slip).
        final m = _run.listenTop();
        setState(() => _wake++);
        await _mistake(m, origin);
        return;
      }
      // Listened to him: up the ladder, a hand on the live lamp holder.
      _run.failDeadly(M4StreetlightFixMistakes.touchLive);
      await _deadly(M4StreetlightFixMistakes.touchLive);
      return;
    }
    _run.caught.add(_coworkerAtTop ? M4StreetlightFixLines.caughtCallTop : M4StreetlightFixLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    _lastTask = _task;
    unawaited(_sayChain([M4StreetlightFixLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4StreetlightFixLines.tapWhy[_nudgeN++ % M4StreetlightFixLines.tapWhy.length]
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('streetlight_fix/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on the live holder: the street freezes grey and the flash comes
  /// off the luminaire in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _testerTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _tester = null;
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
    final speak = await SpokenOnce.first('streetlight_fix/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4StreetlightFixLines.deadlyWord : M4StreetlightFixLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same job goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        _lastTask = _task;
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
    final centre = _centre;
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
    await _say(!_run.passed ? M4StreetlightFixLines.fail : (_quickBonus ? M4StreetlightFixLines.quick : M4StreetlightFixLines.allSet),
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
    if (_run.lightOn && _run.station == M4StreetlightFixStation.finish) return LinemanMode.cheer;
    if (_run.up || _run.tool != M4StreetlightFixTool.none || _run.oldInHand) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M4StreetlightFixView get _view => M4StreetlightFixView(
        badSide: _run.deal.badSide,
        badKind: _run.deal.badKind,
        poleNo: _run.deal.poleNo,
        mcbNos: [
          for (var s = 0; s < 2; s++) s == _run.deal.mineSlot ? _run.deal.poleNo : _run.deal.otherNo,
        ],
        mcbOn: [..._run.mcbOn],
        ladder: _run.ladder,
        tied: _run.tied,
        lightOn: _run.lightOn,
        farOn: _run.otherOn,
        oldInHand: _run.oldInHand,
        inCrate: _run.inCrate,
        inBin: false,
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = M4StreetlightFixGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final l = _run.ladder;
    final up = _run.up && l != null;
    final tb = up ? geo.traineeUp(l) : geo.traineeDown;
    final flip = up && l == M4StreetlightFixSide.right;
    final spotting = _run.tool == M4StreetlightFixTool.ladder && _run.ladder == null && !_freeze && _card == null && !reasonOpen;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('street'),
                child: RepaintBoundary(child: CustomPaint(painter: M4StreetlightFixStreetPainter(geo: geo, view: _view, seed: _run.deal.poleNo))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: Transform.flip(
                  flipX: flip,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ),
              Positioned.fill(
                key: const ValueKey('harness'),
                child: IgnorePointer(
                  child: CustomPaint(painter: M4StreetlightFixHarnessPainter(box: tb, up: up, harness: _run.harness, oldLamp: _run.oldInHand)),
                ),
              ),
            ],
          ),
        ),
      ),
      // Where the ladder could stand: two plain rings, the same for each.
      if (spotting)
        for (final s in M4StreetlightFixSide.values)
          Positioned.fromRect(
            key: ValueKey('spot-${s.name}'),
            rect: geo.spotRing(s),
            child: IgnorePointer(child: _Ring(quiet: quiet)),
          ),
      if (_run.lightOn && _run.station == M4StreetlightFixStation.finish && !_freeze)
        Positioned(
          key: const ValueKey('stamp'),
          left: 214,
          width: 130,
          top: geo.poleTop + 60,
          child: IgnorePointer(child: _StampPop(text: M4StreetlightFixLines.stampOn, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4StreetlightFixLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4StreetlightFixFlashPainter(geo: geo, v: v)),
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
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null;
    final r = _run;
    final cardUp = playing && r.up && _card == null;
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
              labels: M4StreetlightFixLines.rounds,
              done: {for (var i = 0; i < r.stationIndex; i++) i, if (r.done) 2},
              current: r.done ? null : r.stationIndex,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !r.up && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(text: M4StreetlightFixLines.docketBn(r.deal.poleNo, r.deal.fault))),
                ),
              if (cardUp)
                Positioned(
                  key: const ValueKey('fixture'),
                  left: 10,
                  right: 10,
                  top: pad.top + 100,
                  child: _FixtureCard(
                    docket: M4StreetlightFixLines.docketBn(r.deal.poleNo, r.deal.fault),
                    inside: M4StreetlightFixInside(gear: r.deal.gear, loose: r.deal.loose, tightened: r.tightened, fitted: r.fitted != null, driverHeld: r.tool == M4StreetlightFixTool.driver),
                    parts: r.deal.parts,
                    fitted: r.fitted,
                    enabled: handsOn,
                    quiet: quiet,
                    onTerminal: _tapTerminal,
                    onPart: _fit,
                  ),
                ),
              if (_tester != null && !_freeze && r.up)
                Positioned(
                  key: const ValueKey('tester'),
                  right: 22,
                  top: pad.top + 110,
                  child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && !r.up && r.station != M4StreetlightFixStation.finish)
                Positioned(
                  key: const ValueKey('hud-base'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(icon: Icons.stairs_rounded, label: M4StreetlightFixLines.ladder, on: r.tool == M4StreetlightFixTool.ladder || r.ladder != null, onTap: () => _hold(M4StreetlightFixTool.ladder)),
                      _ToolButton(icon: Icons.link_rounded, label: M4StreetlightFixLines.rope, on: r.tied, onTap: _tie),
                      _ToolButton(icon: Icons.accessibility_new_rounded, label: M4StreetlightFixLines.harness, on: r.harness, onTap: _harness),
                    ],
                  ),
                ),
              if (handsOn && r.up)
                Positioned(
                  key: const ValueKey('hud-top'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(icon: Icons.flash_on_rounded, label: M4StreetlightFixLines.tester, on: _tester != null, onTap: _useTester),
                      _ToolButton(icon: Icons.construction_rounded, label: M4StreetlightFixLines.driver, on: r.tool == M4StreetlightFixTool.driver, onTap: () => _hold(M4StreetlightFixTool.driver)),
                      _ToolButton(icon: Icons.south_rounded, label: M4StreetlightFixLines.down, on: false, onTap: _climbOrDown),
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              // Raised over the street on the footpath (the ladder's feet, the crate, the bin are under his
              // usual corner); low again at the top of the ladder, where only the card is worked.
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (r.up ? 84 : 84 + 130 * size.width / 360)), onLeft: !coworkerOnScreen || coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M4StreetlightFixLines.intro,
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M4StreetlightFixLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(text, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// The open luminaire close up (at the top of the ladder): the docket line,
/// the inside (tap a terminal with the screwdriver), and the parts on his belt.
class _FixtureCard extends StatelessWidget {
  const _FixtureCard({
    required this.docket,
    required this.inside,
    required this.parts,
    required this.fitted,
    required this.enabled,
    required this.quiet,
    required this.onTerminal,
    required this.onPart,
  });
  final String docket;
  final M4StreetlightFixInside inside;
  final List<M4StreetlightFixPart> parts;
  final M4StreetlightFixPart? fitted;
  final bool enabled;
  final bool quiet;
  final void Function(int i, Offset global) onTerminal;
  final void Function(M4StreetlightFixPart p, Offset global) onPart;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, -30 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xEE0F1A2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${M4StreetlightFixLines.docket}: $docket', style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
            ),
            const SizedBox(height: 4),
            AspectRatio(
              aspectRatio: 2.0,
              child: LayoutBuilder(
                builder: (context, box) {
                  final s = Size(box.maxWidth, box.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      if (!enabled) return;
                      for (var i = 0; i < 3; i++) {
                        if (M4StreetlightFixInsideGeo.terminalHit(i, s).contains(d.localPosition)) {
                          onTerminal(i, d.globalPosition);
                          return;
                        }
                      }
                    },
                    child: RepaintBoundary(child: CustomPaint(size: s, painter: M4StreetlightFixInsidePainter(inside: inside))),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final (i, p) in parts.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _PartChip(label: M4StreetlightFixLines.partBn(p), on: fitted == p, onTapUp: (d) => enabled ? onPart(p, d.globalPosition) : null)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartChip extends StatelessWidget {
  const _PartChip({required this.label, required this.on, required this.onTapUp});
  final String label;
  final bool on;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF263B5C), Color(0xFF111C30)],
            ),
            border: Border.all(color: (on ? SlmColors.success : SlmColors.gold300).withValues(alpha: 0.85), width: 1.4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label, maxLines: 1, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live, required this.quiet});
  final bool live;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE101A2B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: live ? SlmColors.danger : const Color(0xFF6E7C90), width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: live ? const Color(0xFFFF5A3D) : const Color(0xFF3A3F45),
                boxShadow: live ? const [BoxShadow(color: Color(0xAAFF5A3D), blurRadius: 8, spreadRadius: 1)] : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(live ? M4StreetlightFixLines.testerLive : M4StreetlightFixLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
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
                child: Icon(icon, size: 24, color: ring),
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

class _Ring extends StatelessWidget {
  const _Ring({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * v, child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.elliptical(23, 11)),
          border: Border.all(color: const Color(0xFFFFE08A), width: 2.2),
          color: const Color(0x22FFE08A),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
