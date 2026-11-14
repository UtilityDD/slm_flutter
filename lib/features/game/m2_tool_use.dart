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
import 'm2_tool_use_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_tool_use_world.dart' show TuJob, TuScrew, TuTool, TuToolInfo, TuGeo, TuFit, tuFitOf;

// Lesson 2.1 "লাইনম্যানের টুলবক্স পরিচিতি", কাজ 2 "সঠিক কাজে সঠিক হাতিয়ার".
// The LT line is shut down (the docket says so); the trainee — helmet,
// gloves — stands at the pole's distribution box with his toolbox open at his
// feet. Four small jobs a play (dealt fresh): tighten the earth bolt's nut,
// tighten a terminal screw, strip the service cable's insulation, and either
// check the neutral for voltage or crimp a lug on the cable end. For each he
// takes a tool from the box and tries it on the piece in the close-up lens
// (free: the spanner's jaw sits snug, loose, or will not go on; the driver's
// tip seats in the slot or not; the VDE 1000V mark shows on the handle), then
// works with it ("এটা দিয়েই করি") or puts it back.
//
// The lesson's rules, and only those (tool/all_training_chapters_bn.json, 2.1):
//   • spanner (point 3): the wrong / loose spanner ruins the nut head and slips;
//   • screwdriver (point 2): the wrong size ruins the screw head, the hand
//     slips → short circuit / injury;
//   • wire stripper (point 1): a knife or ordinary pliers nicks the conductor
//     — a weak point, hot spot, breakage;
//   • line tester (point 4): phase only — not reliable for neutral / earth;
//     use a multimeter (and myth 2);
//   • combination pliers (point 0): grip, twist, cut, crimp; VDE 1000V only —
//     non-insulated pliers on LT = danger (myth 1: gloves + VDE tool, both);
//   • pro tip 2: right tool for the right job (pliers ≠ hammer, screwdriver ≠ chisel).
//
// No deadly move: the line is shut down and the lesson gives no death for a
// wrong hand tool, so every wrong tool is a slip (three strike the level out).
// The careless coworker comes once a play, on the nut, the strip or the crimp
// job, and pushes the shortcut (pliers on the nut, a knife on the insulation,
// plain pliers "gloves are on"); listening = the slip of that shortcut.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m2_tool_use_world.dart), corner guide, ◆ on the table → "কেন …?"
// (the reasons fit the job; each job's wrong reasons also name its tool, so
// the tool's name never gives the right card away) → the next job by itself.
// Kit (2026-11-11): no scene control works in a praise window (`tableBusy`);
// "এটা দিয়েই করি" on his job waits for the coworker (`holdForCoworker`), so a
// fast player still meets him; a gesture hint sweeps over the tools (or over
// the two buttons with a tool in hand) when the player seems stuck — never
// pointing at the right one.
// Voice: the guide's lines by device TTS; the coworker's pushes have no clip
// yet (TuLines.toRecord: silent, caption held); his exit line is recorded.

// ============================================================================
// Content
// ============================================================================

abstract final class TuLines {
  static const title = 'সঠিক কাজে সঠিক হাতিয়ার';
  static const intro = 'লাইন শাটডাউন, বক্সে চারটে ছোট কাজ। টুলবক্স খোলা — প্রতিটা কাজে ঠিক টুলটা বেছে নিন!';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];

  /// The job, as the guide asks it (and the docket names it).
  static String ask(TuJob j) => switch (j) {
        TuJob.nut => 'আর্থ বোল্টের নাটটা টাইট দিন। কোন টুল নেবেন?',
        TuJob.screw => 'টার্মিনালের স্ক্রুটা টাইট দিন। কোন টুল নেবেন?',
        TuJob.strip => 'সার্ভিস তারের মাথার ইনসুলেশন ছাড়ান। কোন টুল?',
        TuJob.neutral => 'নিউট্রালে ভোল্টেজ আছে কি না মাপুন। কোন টুল?',
        TuJob.crimp => 'তারের মাথায় লাগটা ক্রিম্প করুন। কোন টুল?',
      };
  static String jobBn(TuJob j) => switch (j) {
        TuJob.nut => 'আর্থ বোল্টের নাট টাইট',
        TuJob.screw => 'টার্মিনালের স্ক্রু টাইট',
        TuJob.strip => 'তারের ইনসুলেশন ছাড়ানো',
        TuJob.neutral => 'নিউট্রালে ভোল্টেজ মাপা',
        TuJob.crimp => 'তারের মাথায় লাগ ক্রিম্প',
      };
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (the docket, the slots, the buttons).
  static const docket = 'ডকেট · শাটডাউন · পারমিট (PTW)';
  static const sceneLabel = 'ডিস্ট্রিবিউশন বক্স';
  static const use = 'এটা দিয়েই করি';
  static const putBack = 'রেখে দিই';
  static const stampDone = 'হয়ে গেল';

  /// The slot label under each tool (short) and its full name (screen readers).
  static String slot(TuTool t) => switch (t) {
        TuTool.pliersVde || TuTool.pliersPlain => 'প্লায়ার্স',
        TuTool.cutter => 'কাটার',
        TuTool.stripper => 'স্ট্রিপার',
        TuTool.knife => 'ছুরি',
        TuTool.tester => 'টেস্টার',
        TuTool.meter => 'মিটার',
        TuTool.flatBig => 'ফ্ল্যাট বড়',
        TuTool.flatSmall => 'ফ্ল্যাট ছোট',
        TuTool.phillips => 'ফিলিপস',
        TuTool.sp13 || TuTool.sp17 || TuTool.sp19 => '${t.mm} mm',
      };
  static String name(TuTool t) => switch (t) {
        TuTool.pliersVde || TuTool.pliersPlain => 'প্লায়ার্স',
        TuTool.cutter => 'সাইড কাটার',
        TuTool.stripper => 'ওয়্যার স্ট্রিপার',
        TuTool.knife => 'ছুরি',
        TuTool.tester => 'লাইন টেস্টার',
        TuTool.meter => 'মাল্টিমিটার',
        TuTool.flatBig => 'ফ্ল্যাট স্ক্রুড্রাইভার বড়',
        TuTool.flatSmall => 'ফ্ল্যাট স্ক্রুড্রাইভার ছোট',
        TuTool.phillips => 'ফিলিপস স্ক্রুড্রাইভার',
        TuTool.sp13 || TuTool.sp17 || TuTool.sp19 => 'স্প্যানার ${t.mm} mm',
      };

  // The reasons (lesson 2.1): the right ones fit the job just done; the wrong
  // ones are field excuses — never a true rule marked wrong. 38–47 letters.
  static const why = 'কেন এটা নিলেন?';
  static const nutWhy = ['নাটের মাপের স্প্যানার মুখে বসে, পিছলায় না', 'ঠিক মাপের স্প্যানারে নাটের মাথা নষ্ট হয় না', 'ঢিলা স্প্যানার পিছলে নাট নষ্ট, হাতও ফসকায়'];
  static const screwWhy = ['খাঁজের মাপের ড্রাইভার বসে যায়, হাত পিছলায় না', 'ভুল মাপে স্ক্রুর মাথা নষ্ট, হাত পিছলে শর্ট হয়', 'স্ক্রুর মাথা দেখে ঠিক ড্রাইভার, হাতল ইনসুলেটেড'];
  static const stripWhy = ['স্ট্রিপারে ছাল ছাড়ে, ভেতরের তারে দাগ পড়ে না', 'ছুরিতে তারে খাঁজ পড়ে, সেখানেই হট স্পট হয়', 'তারে খাঁজ মানে দুর্বল জায়গা, পরে ছিঁড়ে যায়'];
  static const neutralWhy = ['নিউট্রালে লাইন টেস্টার ভরসার নয়, মিটার লাগে', 'টেস্টার শুধু ফেজ বলে, ভোল্টেজ মাপে মাল্টিমিটার', 'নিউট্রাল বা আর্থ চেক করতে মাল্টিমিটার লাগে'];
  static const crimpWhy = ['VDE 1000V প্লায়ার্সে ক্রিম্পার আছে, হাতল ঢাকা', 'গ্লাভস আর VDE টুল, দুই স্তরের সুরক্ষা চাই', 'সাধারণ প্লায়ার্সের হাতল খোলা ধাতু, শকের ঝুঁকি'];

  /// Wrong reasons (field excuses and the gloves myth).
  static const excuses = [
    'যেটা হাতের কাছে পেয়েছি, সেটাতেই কাজ চলে যায়',
    'এটাই সবচেয়ে সস্তা টুল, নষ্ট হলেও ক্ষতি নেই',
    'সিনিয়ররা এটা দিয়েই করেন, তাই আমিও করলাম',
    'তাড়াতাড়ি শেষ করতে হবে, বাছার সময় নেই',
    'গ্লাভস পরা আছে, টুল যেটাই হোক চলে যাবে',
    'টুলবক্সের একদম ওপরে ছিল, তাই তুলে নিলাম',
  ];

  /// Excuses that name the job's own tool and its piece (a right tool, a wrong
  /// reason), so no word of the right cards (the tool, "নাট", "তারে", "মাপ"…)
  /// is on right cards only.
  static List<String> jobExcuses(TuJob j) => switch (j) {
        TuJob.nut => const [
            'স্প্যানারটা হাতের কাছে ছিল, তাই ওটাই তুলে নিলাম',
            'নাটের মাপের কথা ভাবিনি, ভারী স্প্যানারটা নিলাম',
            'নাটটা ছোট, মাপ না মিলিয়ে যেকোনোটাতেই ঘুরে যেত',
          ],
        TuJob.screw => const [
            'ড্রাইভারটা টুলবক্সের ওপরে ছিল, তাই ওটাই নিলাম',
            'যেকোনো ড্রাইভার চেপে ধরলেই স্ক্রু ঘুরে যায় তো',
            'স্ক্রুর মাথা দেখিনি, মাপের হিসাব না করেই নিলাম',
          ],
        TuJob.strip => const [
            'স্ট্রিপারটা নতুন কেনা, তাই একবার চালিয়ে দেখলাম',
            'তারের ছাল পাতলা, যেকোনো টুলে টান দিলেই ছাড়ে',
            'তারে খাঁজ পড়ে কি না ভাবিনি, স্ট্রিপারটাই নিলাম',
          ],
        TuJob.neutral => const [
            'মিটারটা সবার ওপরে রাখা ছিল, তাই ওটাই তুলে নিলাম',
            'মাল্টিমিটার দামি টুল, দামি মানেই সব কাজে ভালো',
            'নিউট্রাল নিরাপদ, টেস্টার লাগে না, মিটারই নিলাম',
          ],
        TuJob.crimp => const [
            'VDE প্লায়ার্সের হাতলটা রঙিন, ধরতে আরাম লাগে',
            'VDE টুল সিনিয়ররা নেন, তাই আমিও তুলে নিলাম',
          ],
      };

  /// The wrong reasons dealt after job [j].
  static List<String> whyWrong(TuJob j) => [...excuses, ...jobExcuses(j)];

  static List<String> whyRight(TuJob j) => switch (j) {
        TuJob.nut => nutWhy,
        TuJob.screw => screwWhy,
        TuJob.strip => stripWhy,
        TuJob.neutral => neutralWhy,
        TuJob.crimp => crimpWhy,
      };

  /// The careless coworker: one push per job he can come on.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asks = ['ও শর্টকাট বলছে। আপনি কী করবেন?', 'ঠিক টুল নেবেন, না ওর কথা শুনবেন?', 'এই কাজে কোন পথে যাবেন?'];
  // His line fits whether or not a tool is already in hand (he may come on the
  // "এটা দিয়েই করি" tap). "না", "নেব" and the tool's name are on wrong cards too.
  static const coworkerNut = CoworkerScript(
    line: 'আরে, প্লায়ার্স দিয়েই নাটটা ঘুরিয়ে দাও! মাপ মেলাতে সময় নষ্ট কেন?',
    exitLine: coworkerExit,
    right: ['না, নাটের মাপের স্প্যানারই নেব', 'প্লায়ার্সে নাট পিছলায়, স্প্যানার নেব', 'ঠিক কাজে ঠিক টুল, মাপের স্প্যানার নেব'],
    wrong: ['ঠিক, প্লায়ার্স দিয়েই ঘুরিয়ে দিই', 'মাপের দরকার নেই, প্লায়ার্সই নেব', 'না না, প্লায়ার্সে চেপে ধরলেই নাট ঘোরে', 'হ্যাঁ, একটু জোরে ধরলেই হয়ে যাবে', 'এইটুকু নাটে আবার স্প্যানার লাগে না'],
    asks: _asks,
  );
  static const coworkerStrip = CoworkerScript(
    line: 'ছুরি দিয়ে একটানে ছাল ছাড়িয়ে নাও! স্ট্রিপার লাগে নাকি?',
    exitLine: coworkerExit,
    right: ['না, স্ট্রিপার দিয়েই ছাল ছাড়াব', 'ছুরিতে তারে খাঁজ পড়ে, স্ট্রিপার নেব', 'ঠিক কাজে ঠিক টুল, স্ট্রিপারই নেব'],
    wrong: ['আচ্ছা, ছুরিই নেব, একটানে হয়ে যাবে', 'স্ট্রিপার খোঁজার সময় নেই, ছুরিই চলবে', 'না না, ছুরিতে তো আরও তাড়াতাড়ি হয়', 'হ্যাঁ, সাবধানে টানলে দাগ পড়বে না', 'এইটুকু ছালে স্ট্রিপার লাগে না'],
    asks: _asks,
  );
  static const coworkerCrimp = CoworkerScript(
    line: 'গ্লাভস তো পরাই আছে! সাধারণ প্লায়ার্সেই চলবে, অত বাছাবাছি কেন?',
    exitLine: coworkerExit,
    right: ['না, গ্লাভস আর VDE টুল দুটোই চাই', 'একটা ফেল করলেই শক, VDE প্লায়ার্স নেব', 'গ্লাভস থাকলেও ইনসুলেটেড প্লায়ার্স নেব'],
    wrong: ['ঠিক, গ্লাভস থাকলে সবই চলে যায়', 'ঠিক আছে, সাধারণ প্লায়ার্সই নেব', 'না না, গ্লাভসই তো আসল, টুল যা খুশি', 'হ্যাঁ, এইটুকু কাজে কিছু হবে না', 'VDE খোঁজার দরকার নেই, এটাতেই হবে'],
    asks: _asks,
  );
  static CoworkerScript coworkerFor(TuJob j) => switch (j) {
        TuJob.strip => coworkerStrip,
        TuJob.crimp => coworkerCrimp,
        _ => coworkerNut,
      };

  /// The coworker's pushes with no recorded clip yet (silent, caption held).
  static List<String> get toRecord => [coworkerNut.line, coworkerStrip.line, coworkerCrimp.line];

  static const callHeld = 'ঠিক! শর্টকাট নয় — ঠিক কাজে ঠিক টুল।';
  static const allSet = 'সঠিক কাজে সঠিক হাতিয়ার — হাতও বাঁচল, কাজও নিখুঁত।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কাজ দেখে টুল, টুল দেখে মাপ।';

  // "আজ যা ধরলেন".
  static const caughtNut = 'নাটের মাপের স্প্যানার';
  static const caughtScrew = 'স্ক্রুর মাপের ড্রাইভার';
  static const caughtStrip = 'স্ট্রিপারে ইনসুলেশন ছাড়ানো';
  static const caughtNeutral = 'নিউট্রালে মাল্টিমিটার';
  static const caughtCrimp = 'VDE প্লায়ার্সে ক্রিম্প';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static String caught(TuJob j) => switch (j) {
        TuJob.nut => caughtNut,
        TuJob.screw => caughtScrew,
        TuJob.strip => caughtStrip,
        TuJob.neutral => caughtNeutral,
        TuJob.crimp => caughtCrimp,
      };
}

abstract final class TuMistakes {
  static const _dir = 'assets/game/art/m2_tool_use';

  static const nutPliers = DoMistake(
    key: '2.1/tool/pliers-on-nut',
    textBn: 'নাটে প্লায়ার্স নয় — নাটের মাথা গোল হয়ে যায়, হাত পিছলে যায়। নাটের মাপের স্প্যানার নিন।',
    art: '$_dir/nut_pliers.svg',
    lessonPoint: 3,
  );
  static const spannerSize = DoMistake(
    key: '2.1/tool/wrong-spanner',
    textBn: 'ভুল বা ঢিলা স্প্যানারে নাটের মাথা নষ্ট হয়, পিছলে যায় — পোলে এটা আরও বিপজ্জনক। আগে মাপ মিলিয়ে নিন।',
    art: '$_dir/spanner_loose.svg',
    lessonPoint: 3,
  );
  static const screwSize = DoMistake(
    key: '2.1/tool/wrong-screwdriver',
    textBn: 'ভুল মাপের স্ক্রুড্রাইভারে স্ক্রুর মাথা নষ্ট হয়, হাত পিছলে শর্ট সার্কিট বা আঘাত। খাঁজ দেখে মাপের ড্রাইভার।',
    art: '$_dir/screw_size.svg',
    lessonPoint: 2,
  );
  static const stripNick = DoMistake(
    key: '2.1/tool/strip-with-knife',
    textBn: 'ছুরি বা সাধারণ প্লায়ার্সে ছাল ছাড়ালে তারে খাঁজ পড়ে — দুর্বল জায়গা, হট স্পট, ছিঁড়ে যাওয়ার ঝুঁকি। ওয়্যার স্ট্রিপার নিন।',
    art: '$_dir/strip_nick.svg',
    lessonPoint: 1,
  );
  static const testerNeutral = DoMistake(
    key: '2.1/tool/tester-on-neutral',
    textBn: 'লাইন টেস্টার শুধু ফেজ আছে কি না বলে — নিউট্রাল বা আর্থে এর ওপর ভরসা নয়। ভোল্টেজ মাপতে মাল্টিমিটার।',
    art: '$_dir/tester_neutral.svg',
    lessonPoint: 4,
  );
  static const nonInsulated = DoMistake(
    key: '2.1/tool/non-insulated-pliers',
    textBn: 'সাধারণ (নন-ইনসুলেটেড) প্লায়ার্স LT লাইনে বিপদ। গ্লাভস বা টুল — যেকোনো একটা ফেল করলেই শক। গ্লাভস আর VDE 1000V টুল, দুটোই।',
    art: '$_dir/non_insulated.svg',
    lessonPoint: 0,
  );

  /// Pro tip 2 (right tool for the right job). The pro tips are not a lesson
  /// point: "পাঠে দেখুন" opens the lesson from its start.
  static const wrongTool = DoMistake(
    key: '2.1/tool/wrong-tool',
    textBn: 'এই কাজের টুল এটা নয়। সঠিক কাজে সঠিক টুল — প্লায়ার্স হাতুড়ি নয়, স্ক্রুড্রাইভার ছেনি নয়।',
    art: '$_dir/wrong_tool.svg',
  );

  static const all = [nutPliers, spannerSize, screwSize, stripNick, testerNeutral, nonInsulated, wrongTool];
}

@immutable
class TuCase {
  const TuCase({required this.id, required this.job, this.nutMm = 0, this.screw});
  final String id;
  final TuJob job;

  /// The earth bolt's nut (mm across the flats): 13, 17 or 19.
  final int nutMm;
  final TuScrew? screw;

  TuTool get right => switch (job) {
        TuJob.nut => switch (nutMm) {
            13 => TuTool.sp13,
            17 => TuTool.sp17,
            _ => TuTool.sp19,
          },
        TuJob.screw => switch (screw!) {
            TuScrew.flatBig => TuTool.flatBig,
            TuScrew.flatSmall => TuTool.flatSmall,
            TuScrew.phillips => TuTool.phillips,
          },
        TuJob.strip => TuTool.stripper,
        TuJob.neutral => TuTool.meter,
        TuJob.crimp => TuTool.pliersVde,
      };

  /// What working with [t] is (null = right).
  DoMistake? mistakeFor(TuTool t) {
    if (t == right) return null;
    return switch (job) {
      TuJob.nut when t.spanner => TuMistakes.spannerSize,
      TuJob.nut when t.pliers => TuMistakes.nutPliers,
      TuJob.screw when t.driver => TuMistakes.screwSize,
      TuJob.strip when t.pliers || t == TuTool.knife || t == TuTool.cutter => TuMistakes.stripNick,
      TuJob.neutral when t == TuTool.tester => TuMistakes.testerNeutral,
      TuJob.crimp when t == TuTool.pliersPlain => TuMistakes.nonInsulated,
      _ => TuMistakes.wrongTool,
    };
  }

  /// The coworker's shortcut on this job (null: he does not come on it).
  TuTool? get pushTool => switch (job) {
        TuJob.nut => TuTool.pliersVde,
        TuJob.strip => TuTool.knife,
        TuJob.crimp => TuTool.pliersPlain,
        _ => null,
      };
}

@immutable
class TuDeal {
  const TuDeal({required this.cases, required this.callAt, required this.tray});
  final List<TuCase> cases;

  /// The job the careless coworker comes on (nut, strip or crimp).
  final int callAt;

  /// The tools in the open box, slot by slot (row 1: 7, row 2: 6).
  final List<TuTool> tray;
}

/// Four jobs: the nut, the screw and the strip always, plus the neutral or
/// the crimp; in a fresh order, the nut's size and the screw head dealt; the
/// tray's rows shuffled (the two pliers never in the same place).
TuDeal dealToolUse(math.Random rng) {
  final jobs = [TuJob.nut, TuJob.screw, TuJob.strip, rng.nextBool() ? TuJob.neutral : TuJob.crimp]..shuffle(rng);
  final cases = <TuCase>[
    for (final (i, j) in jobs.indexed)
      TuCase(
        id: 't$i',
        job: j,
        nutMm: j == TuJob.nut ? const [13, 17, 19][rng.nextInt(3)] : 0,
        screw: j == TuJob.screw ? TuScrew.values[rng.nextInt(3)] : null,
      ),
  ];
  final can = [
    for (final (i, c) in cases.indexed)
      if (c.pushTool != null) i,
  ];
  final row1 = [TuTool.pliersVde, TuTool.pliersPlain, TuTool.cutter, TuTool.stripper, TuTool.knife, TuTool.tester, TuTool.meter]..shuffle(rng);
  final drivers = [TuTool.flatBig, TuTool.flatSmall, TuTool.phillips]..shuffle(rng);
  final spanners = [TuTool.sp13, TuTool.sp17, TuTool.sp19];
  final row2 = rng.nextBool() ? [...drivers, ...spanners] : [...spanners, ...drivers];
  return TuDeal(cases: cases, callAt: can[rng.nextInt(can.length)], tray: [...row1, ...row2]);
}

/// The play state (pure logic).
class ToolUseRun {
  ToolUseRun(this.deal);
  final TuDeal deal;
  int index = 0;

  /// The tool in his hand (being tried on the piece).
  TuTool? held;

  /// The tools tried on this job.
  final Set<TuTool> tried = {};
  bool shown = false;
  int slips = 0;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done;
  TuCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  /// Takes [t] from the box and tries it on the piece (free).
  void tryTool(TuTool t) {
    if (ended || shown) return;
    held = t;
    tried.add(t);
  }

  void putBack() {
    if (!shown) held = null;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Works with the tool in hand (or the coworker's [pushed] one). Returns
  /// the mistake, if any; null and [shown] = the job done right.
  DoMistake? use({TuTool? pushed}) {
    final t = pushed ?? held;
    if (t == null || ended || shown) return null;
    held = t;
    shown = true;
    final m = current.mistakeFor(t);
    if (m != null) {
      slips++;
      return m;
    }
    _tag(TuLines.caught(current.job));
    return null;
  }

  void next() {
    index++;
    held = null;
    tried.clear();
    shown = false;
  }
}

/// The quick bonus: a little under a clean play (~85 %, rounded to 5 s). The
/// clock runs from the end of the guide's intro to the last paid reason.
/// A clean job (ms; ~1500 human reaction per action):
///   the guide asks                                         2500
///   take a tool 1500 + look at the fit 1000, once more     5000
///   use it 1500 + the job turning 1100                     2600
///   reason: praise ~1500 + 650 gap + deck 910 + read 2000
///     + pick 1500 + "এই তো আসল কথা" ~1200 + 450           8210
///   = 18310 × 4                                           73240
/// + the coworker once: his line ~3500 + deck 910 + read and pick 3500 + 420
///                                                          8330
/// ≈ 81570 ms; 85 % ≈ 69300 → 70 s.
const kTuQuickMs = 70000;

@immutable
class M2ToolUsePack {
  const M2ToolUsePack({required this.id, required this.titleBn, this.quickMs = kTuQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2ToolUsePacks = {
  'do_2_1_b': M2ToolUsePack(id: 'do_2_1_b', titleBn: TuLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M2ToolUsePage extends StatefulWidget {
  const M2ToolUsePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2ToolUsePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2ToolUsePage> createState() => _M2ToolUsePageState();
}

class _M2ToolUsePageState extends State<M2ToolUsePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TuRunPage(
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

class _TuRunPage extends ConsumerStatefulWidget {
  const _TuRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2ToolUsePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TuRunPage> createState() => _TuRunPageState();
}

class _TuRunPageState extends ConsumerState<_TuRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final ToolUseRun _run = ToolUseRun(dealToolUse(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The job turning in the lens (the nut turns, the insulation comes off …).
  late final AnimationController _work = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

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
  var _doneStamp = false;

  /// A wrong tool used: the lens shakes red once.
  int _shake = 0;

  /// The service cable end has been stripped this play.
  var _stripped = false;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hint (how to play, never which tool): a sweep over every
  /// tool in the box, or over the two buttons with a tool in hand.
  final _hints = IdleHintController();
  final _useKey = GlobalKey();
  final _backKey = GlobalKey();

  /// The scene's geometry from the last layout (the hint's tool rects).
  TuGeo? _geo;

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _work.dispose();
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

  /// The scene takes a move now: never in a right move's praise window
  /// (`tableBusy`), with a card or a deck up, or while he talks.
  bool get _canPlay => !_intro && !_ended && !struckOut && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && !tableBusy;

  /// The level waits for the player (the gesture hint may show).
  bool get _hintWaiting => _canPlay && !coworkerOnScreen && _mark == null;

  HintSpec? _hint() {
    if (!_hintWaiting) return null;
    if (_run.held != null) return HintSpec.sweepOver([_useKey, _backKey]);
    final geo = _geo;
    if (geo == null) return null;
    return HintSpec.sweep(geo.slots(_run.deal.tray).values.toList(), space: HintSpace.scene);
  }

  /// A tap on the scene that hit no tool or button.
  void _missTap() {
    if (_hintWaiting) _hints.missTap();
  }

  // --- a job ----------------------------------------------------------------------
  void _startJob() {
    setState(() {
      _doneStamp = false;
      _wake++;
    });
    _work.value = 0;
    if (_run.index == _run.deal.callAt) scheduleCoworker();
    unawaited(_sayChain([TuLines.ask(_run.current.job)]));
  }

  void _tapTool(TuTool t) {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    if (_run.held == t) {
      _cue('sounds/intro/click.ogg', volume: 0.4);
      setState(() {
        _run.putBack();
        _wake++;
      });
      return;
    }
    _cue('sounds/learn/tag_slap.ogg', volume: 0.35);
    setState(() {
      _run.tryTool(t);
      _wake++;
    });
  }

  void _putBack() {
    if (!_canPlay || _run.held == null) return;
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() {
      _run.putBack();
      _wake++;
    });
  }

  Future<void> _use(Offset origin, {TuTool? pushed}) async {
    if (_ended || _run.shown) return;
    if (pushed == null) {
      if (!_canPlay || _run.held == null) return;
      // His job: the coworker comes first, however fast the player is.
      if (holdForCoworker()) return;
    }
    _hush();
    final m = _run.use(pushed: pushed);
    HapticFeedback.mediumImpact();
    if (m == null) {
      if (!_run.shown) return;
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      _cue('sounds/quiz_right.ogg', volume: 0.6);
      final job = _run.current.job;
      setState(() {
        if (job == TuJob.strip) _stripped = true;
        _wake++;
      });
      if (_quiet) {
        _work.value = 1;
      } else {
        await _work.forward(from: 0);
      }
      if (!mounted) return;
      setState(() => _doneStamp = true);
      putOnTable(15);
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(TuLines.whyRight(job), TuLines.whyWrong(job), widget.rng),
        question: TuLines.why,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    setState(() => _shake++);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => TuLines.coworkerFor(_run.deal.cases[_run.deal.callAt].job);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_intro || _card != null || reasonOpen || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: does it his way (the slip of that shortcut).
      await _use(origin, pushed: _run.current.pushTool);
      return;
    }
    _run.caught.add(TuLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([TuLines.callHeld, TuLines.ask(_run.current.job)], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    // Beat 1 is his alone: the guide stays quiet until his deck is up.
    if (coworkerOpen && !coworkerChoiceUp) return;
    // The work and its praise are running: don't cut the praise or re-ask a
    // finished job.
    if ((_run.shown || tableHolding) && !reasonOpen) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? TuLines.tapWhy[_nudgeN++ % TuLines.tapWhy.length]
            : _nudge.next(TuLines.ask(_run.current.job));
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
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
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('tool/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() => _card = null);
    _next();
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
    await _say(!_run.passed ? TuLines.fail : (_quickBonus ? TuLines.quick : TuLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
  LinemanMode get _mode {
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_doneStamp) return LinemanMode.cheer;
    if (_run.held != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = TuGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final playing = !_intro && _mark == null && !struckOut;
    final slots = geo.slots(_run.deal.tray);
    final held = _run.held;
    final tryUp = playing && held != null && !_run.shown && _card == null && !reasonOpen;
    final lensR = geo.lensR;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(
          child: CustomPaint(painter: TuWorldPainter(geo: geo, job: playing && !_run.done ? c.job : null, stripped: _stripped)),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('tray'),
        child: RepaintBoundary(child: CustomPaint(painter: TuTrayPainter(geo: geo, slots: slots))),
      ),
      // Taps that hit no tool or button (the gesture hint's miss count): over
      // the painted tray, under the tools.
      Positioned.fill(
        key: const ValueKey('scene-tap'),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (_) => _missTap()),
      ),
      for (final MapEntry(key: t, value: r) in slots.entries)
        Positioned.fromRect(
          key: ValueKey('tool-${t.name}'),
          rect: r,
          child: Semantics(
            button: true,
            label: TuLines.name(t),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _tapTool(t),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 3, 4, 0),
                      // The tool in his hand leaves its slot empty.
                      child: held == t ? const SizedBox.expand() : CustomPaint(painter: TuToolPainter(t), child: const SizedBox.expand()),
                    ),
                  ),
                  SizedBox(
                    height: 18,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(TuLines.slot(t), style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: held == t ? SlmColors.gold300 : const Color(0xFFE7EAEE))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      // The close-up lens on the job's piece.
      if (playing && !_run.done)
        Positioned(
          key: ValueKey('lens-${_run.index}'),
          left: geo.lens.dx - lensR,
          top: geo.lens.dy - lensR,
          width: lensR * 2,
          height: lensR * 2,
          child: IgnorePointer(
            child: Semantics(
              label: TuLines.sceneLabel,
              child: _Shake(
                key: ValueKey('shake-$_shake'),
                on: _shake > 0 && !quiet,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _work,
                    builder: (_, _) => CustomPaint(
                      painter: TuLensPainter(job: c.job, tool: held, nutMm: c.nutMm, screw: c.screw, done: Curves.easeInOut.transform(_work.value)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (_doneStamp && playing)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: geo.lens.dx - 60,
          width: 120,
          top: geo.lens.dy + lensR - 18,
          child: IgnorePointer(child: _StampPop(text: TuLines.stampDone, quiet: quiet)),
        ),
      // Try it on, then work with it or put it back (beside the lens).
      if (tryUp)
        Positioned(
          key: const ValueKey('hud-try'),
          left: geo.lens.dx + lensR + 10,
          width: 150,
          top: geo.lens.dy - 52,
          child: Column(
            children: [
              DoBigButton(key: _useKey, label: TuLines.use, filled: true, onTapUp: (d) => unawaited(_use(d.globalPosition))),
              const SizedBox(height: 8),
              _PutBackButton(key: _backKey, onTap: _putBack),
            ],
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
    final deckUp = reasonOpen || coworkerChoiceUp;
    final k = size.width / 360;
    final trayTop = (196 + 16) * k + pad.bottom;
    final c = _run.current;
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
              labels: TuLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: playing && !deckUp && _hintWaiting,
            hintKey: '${_run.index}/${_run.held?.name}/$strikes',
            hintController: _hints,
            overlays: [
              // The docket (hidden while his speech bubble is up, which covers it).
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  right: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(job: c.job)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : trayTop, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  line: TuLines.intro,
                  alarm: 'sounds/learn/tag_slap.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _clock.start();
                    _startJob();
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.job});
  final TuJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
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
          Text(TuLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(TuLines.jobBn(job), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

class _PutBackButton extends StatelessWidget {
  const _PutBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1324),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.6),
          ),
          child: Text(TuLines.putBack, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// A one-shot side shake (a wrong tool on the piece).
class _Shake extends StatelessWidget {
  const _Shake({super.key, required this.on, required this.child});
  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, v, child) => Transform.translate(offset: Offset(math.sin(v * math.pi * 6) * 7 * (1 - v), 0), child: child),
      child: child,
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
      builder: (_, v, child) => Transform.rotate(angle: -0.1, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
