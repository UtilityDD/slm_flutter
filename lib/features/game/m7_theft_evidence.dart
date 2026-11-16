import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
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
import 'm7_theft_evidence_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_theft_evidence_world.dart'
    show M7Cam, M7Gear, M7LaneGeo, M7LaneLook, M7LineKind, M7Light, M7Method, M7Owner, M7PoleGeo, M7Spot, M7Vantage, m7Coverage, m7ZoomMax, m7ZoomMin;

// Lesson 7.5 "বিদ্যুৎ চুরি: একটি অপরাধ এবং তার বিপদ", কাজ 2 "দূর থেকে প্রমাণ"
// (pack do_7_5_b, engineType m7_theft_evidence).
//
// Phase 1, dusk: the trainee stands by the crew van or a tea stall at one end
// of a lane. One house (dealt, unmarked) takes power through a hook (or a
// twisted wire) on the LT line (bare conductors or an AB cable, dealt) and a
// thin wire into its wall, past its meter (lesson 7.5 point 2). The phone:
// drag the viewfinder, zoom with the rail (1x–5x) or a pinch, the shutter.
// Each photo lands in the roll exactly as framed — nothing judges it there.
// Drag two photos into the two evidence slots and tap পাঠান: the two must
// show the hook on the line legibly and the wire going into that house (point
// 3: "দূর থেকে অবৈধ সংযোগের ছবি বা ভিডিও তুলুন"; pro tip 3: the report must
// be accurate). A wide or soft shot, a neighbour's legal meter, a photo with
// no proof, or the same proof twice = a slip, and that slot empties. Walking
// the trainee up to the stealing house brings its owner out shouting = a slip
// (point 3: "সরাসরি তাদের সাথে বিবাদে জড়াবেন না"); he is walked back.
//
// Phase 2, next morning, the same pole: the vigilance officer with his order
// paper, sometimes a constable (scenery), the crew phone, the PPE bag, the
// tester with its proving unit, the earth set — in a dealt order on the
// ground, no list — and the hook still on the line. Take and read the order
// (point 3: "শুধুমাত্র কর্তৃপক্ষের নির্দেশে"), call the শাটডাউন (the lane DTR's
// AB switch goes OFF with a tag; ruling M7-9: AB + HG fuses, no DO), prove
// the tester live → the line 0 V → live again, earth the span, put on the PPE
// (drag each item onto the trainee), then drag the hook off (pro tip 4: "লাইনটি
// বন্ধ করে টেস্টার দিয়ে ডেড প্রমাণ করা, আর্থ লাগানো এবং সম্পূর্ণ PPE"; ruling
// M7-8 / X1).
//
// Deadly / slip (module 7 table and rulings of 2026-11-16): a hand on the
// hook with the line live (R13), after the shutdown but before the tester's
// 0 V (N1), or after the 0 V with no earth (N2) = DEADLY; listening to push
// (ii) "হুকটা টেনে খুলে দাও" = that deadly (X2/B1). Slips: walking up to the
// thief (R15); wrong evidence (R16); listening to myth 1 (report not sent);
// the hook pulled (proven dead, earthed) before the order or with a PPE item
// missing (R14) — the গ্লাভস too, which M7-2 makes a slip once the line is
// proven dead and earthed (the rulings file's M7-2 row; the item spec's
// "always deadly" note is older; flagged to the owner); an earth before the
// 0 V (N3); the tester not proved on a live point before or after (N4).
// Three slips strike out.
//
// Built on the shared kit (GAME_LEVEL_PLAYBOOK.md): the guide first, the
// full scene (m7_theft_evidence_world.dart), the corner guide (tap: the task
// again, a different way), the ◆ table + "কেন?" deck after the report, the
// shutdown, the tester proof, the earth and the hook; the two-beat coworker
// once a play — push (i) myth 1 word for word, held on পাঠান, or push (ii)
// held on the শাটডাউন call; gesture hands (how, never what); the deadly
// freeze; idle = zero frames.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one per play).
enum M7Push { myth, hook }

/// What a photo holds (judged only when the report is sent): the hook on the
/// line or the wire's entry into the stealing house, legible; something soft
/// or too wide (unclear); a neighbour's legal meter; nothing of the theft.
enum M7ShotKind { hook, entry, unclear, neighbour, none }

/// Where the tester touches: the proving unit (a known live point) or the
/// line at the hook.
enum M7TestAt { prover, line }

/// What a reason asks about (fits what the player just did).
enum M7Why { far, evidence, shutdown, tester, earth, ppe, order }

/// The zoom a hook / an entry is readable at.
const double m7HookZoom = 3.0;
const double m7EntryZoom = 2.5;

/// What [frame] at [zoom] holds of the theft at house [thief].
M7ShotKind m7Classify(Rect frame, double zoom, M7LaneGeo g, int thief) {
  final hook = m7Coverage(g.hook(thief), frame);
  final entry = m7Coverage(g.entry(thief), frame);
  if (hook >= 0.9) return zoom + 1e-6 >= m7HookZoom ? M7ShotKind.hook : M7ShotKind.unclear;
  if (entry >= 0.8) return zoom + 1e-6 >= m7EntryZoom ? M7ShotKind.entry : M7ShotKind.unclear;
  for (var i = 0; i < M7LaneGeo.houseCx.length; i++) {
    if (i == thief) continue;
    if (m7Coverage(g.meter(i), frame) >= 0.8 && zoom >= 2) return M7ShotKind.neighbour;
  }
  return M7ShotKind.none;
}

abstract final class M7TheftLines {
  static const title = 'দূর থেকে প্রমাণ';

  // DRAFT wording — owner (M6-12 / M7-10): every line below until the owner
  // words it. The two openings are the spec's.
  static const intro = 'ওই বাড়ির হুক থেকে লাইনে চুরি! দূর থেকে পরিষ্কার ছবি তুলুন।';
  static const introMorning = 'ভিজিল্যান্স এসেছে। এবার হুকটা নিয়মে খুলুন।';

  // The tasks (the corner guide; tap = said again another way).
  static const taskAim = 'দূর থেকে জুম করে চুরির ছবি তুলুন।';
  static const taskSlots = 'দুটো ছবি প্রমাণের ঘরে টেনে দিন।';
  static const taskSend = 'এবার রিপোর্ট পাঠান।';
  static const taskRemove = 'হুকটা নিয়ম মেনে খুলুন।';
  static const taskPaper = 'নির্দেশটা পড়ে নিন।';
  static const taskPhone = 'ফোন থেকে কল করুন।';
  static const taskGear = 'PPE গায়ে পরে নিন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Words on the controls and papers (not spoken).
  static const shutter = 'ছবি তুলুন';
  static const zoom = 'জুম';
  static const send = 'পাঠান';
  static const roll = 'ছবি';
  static const slot = 'প্রমাণ';
  static const morning = 'পরদিন সকাল';
  static const paperTitle = 'নির্দেশ';
  static const paperBody = 'অবৈধ হুক সংযোগটি বিচ্ছিন্ন করুন।';
  static const paperSign = 'ভিজিল্যান্স অফিসার';
  static const paperOk = 'পড়েছি';
  static const phoneWho = 'কন্ট্রোল রুম';
  static const phoneCall = 'শাটডাউন চাই';
  static const sceneLabel = 'গলি';
  static const poleLabel = 'পোল';
  static const gearName = <M7Gear, String>{
    M7Gear.helmet: 'হেলমেট',
    M7Gear.gloves: 'গ্লাভস',
    M7Gear.boots: 'সেফটি জুতো',
    M7Gear.harness: 'ফুল-বডি হারনেস',
  };

  // The reasons: the spec's five questions and two new ones (tester, earth).
  static const qFar = 'দূর থেকেই ছবি কেন তুললেন?';
  static const qEvidence = 'এই ছবি রিপোর্টে কেন দিলেন?';
  static const qShutdown = 'হুক খোলার আগে লাইন বন্ধ কেন?';
  static const qTester = 'টেস্টার আগে আর পরে লাইভে কেন ছোঁয়ালেন?';
  static const qEarth = 'হুক খোলার আগে আর্থ কেন লাগালেন?';
  static const qPpe = 'পুরো PPE কেন পরলেন?';
  static const qOrder = 'নির্দেশ না পেয়ে খোলেননি কেন?';
  static String whyQ(M7Why w) => switch (w) {
        M7Why.far => qFar,
        M7Why.evidence => qEvidence,
        M7Why.shutdown => qShutdown,
        M7Why.tester => qTester,
        M7Why.earth => qEarth,
        M7Why.ppe => qPpe,
        M7Why.order => qOrder,
      };
  static const whyRight = <M7Why, List<String>>{
    M7Why.far: ['চোরেরা আক্রমণ করতে পারে, তাই বিবাদ নয়', 'নিজের সুরক্ষা আগে, দূর থেকে জুমই যথেষ্ট'],
    M7Why.evidence: ['হুক আর বাড়িতে ঢোকা তার, দুটোই প্রমাণ', 'নির্ভুল ছবিতেই ভিজিল্যান্স অভিযান চালায়'],
    M7Why.shutdown: ['চোরের তার কীভাবে লাগানো, জানা নেই', 'চালু লাইনে হুকে হাত মানেই শক, আগে বন্ধ'],
    M7Why.tester: ['টেস্টার ঠিক আছে কি না, আগে-পরে যাচাই', 'খারাপ টেস্টারও চালু লাইনকে ডেড দেখায়'],
    M7Why.earth: ['হঠাৎ লাইন চালু হলেও আর্থ বাঁচিয়ে দেবে', 'ডেড প্রমাণের পর আর্থ, তারপর হুকে হাত'],
    M7Why.ppe: ['চোরের তার নিম্নমানের, পুরো PPE লাগে', 'অবৈধ সংযোগ খোলা বিপজ্জনক, PPE অপরিহার্য'],
    M7Why.order: ['শুধু কর্তৃপক্ষের নির্দেশে সংযোগ কাটা যায়', 'আইন নিজের হাতে নয়, আগে নির্দেশ চাই'],
  };

  /// Excuses that fit any question (dealt with the topic's own myths).
  static const _excuses = [
    'তাড়াতাড়ি কাজ শেষ করাটাই আসল কথা',
    'এসব নিয়ম শুধু খাতাতেই লেখা থাকে',
    'অভিজ্ঞ লাইনম্যানের এসব কিছু লাগে না',
  ];
  static const _wrong = <M7Why, List<String>>{
    // Myth 2 of the lesson among them.
    M7Why.far: ['কাছে গিয়ে চোরকে ধমক দিলেই কাজ হয়', 'চোর ধরা পুলিশের কাজ, আমার কাজ নয়'],
    M7Why.evidence: ['যেকোনো একটা মিটারের ছবি দিলেই হয়', 'ঝাপসা হলেও চলবে, অফিস ঠিক বুঝে নেবে'],
    M7Why.shutdown: ['LT লাইনে হাত দিলে তেমন কিছু হয় না', 'হুক তো চোরের, লাইন বন্ধের দরকার নেই'],
    M7Why.tester: ['লাইন বন্ধ বলেছে মানেই ডেড, টেস্ট বাড়তি', 'টেস্টার একবার ছোঁয়ালেই সবটা বোঝা যায়'],
    M7Why.earth: ['ডেড দেখালে আর্থের আর কোনো দরকার নেই', 'আর্থ শুধু বড় HT লাইনের কাজে লাগে'],
    M7Why.ppe: ['শুধু মাথায় হেলমেট পরলেই সব ঠিক থাকে', 'হুক খুলতে এক মিনিট লাগে, PPE বাড়তি'],
    M7Why.order: ['চুরি দেখলেই নিজে খুলে দেওয়া যায়', 'নির্দেশ পরে নিলেও কোনো ক্ষতি নেই'],
  };
  static List<String> wrongFor(M7Why w) => [..._wrong[w]!, ..._excuses];
  static List<String> get myths => [..._excuses, for (final l in _wrong.values) ...l];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (M7-10): push (i) is myth 1 word for word plus his
  // ask; push (ii) the spec's shortcut line.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const myth1 = 'একটু বিদ্যুৎ চুরি করলে কোম্পানির কিছু হয় না, ওদের তো অনেক টাকা।';
  static const askMyth = 'ও বলছে রিপোর্ট না পাঠাতে। কী করবেন?';
  static const askHook = 'ও বলছে চালু লাইনেই হুক টানতে। কী করবেন?';
  static const coworkerMyth = CoworkerScript(
    line: '$myth1 রিপোর্ট পাঠিয়ো না!',
    exitLine: coworkerExit,
    right: ['না, চুরির ক্ষতি সৎ গ্রাহকের ঘাড়েই পড়ে', 'না, রিপোর্ট পাঠানো আমারই দায়িত্ব', 'না, একটু একটু চুরিতেই বড় ক্ষতি হয়'],
    wrong: [
      'ঠিক, কোম্পানির তো অনেক টাকা আছে',
      'আচ্ছা, রিপোর্টটা তাহলে আর না পাঠাই',
      'হ্যাঁ, একটু চুরিতে কী আর এমন হয়',
      'ঠিক আছে, ঝামেলায় গিয়ে কোনো লাভ নেই',
      'হ্যাঁ, পাড়ার লোক, এবারটা ছেড়ে দিই',
    ],
    asks: ['কী করবেন?', askMyth, 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerHook = CoworkerScript(
    line: 'লাইন বন্ধ করার দরকার নেই, হুকটা টেনে খুলে দাও।',
    exitLine: coworkerExit,
    right: ['না, আগে লাইন বন্ধ, পুরো PPE', 'না, চালু লাইনে হুকে হাত দেব না', 'না, বন্ধ, টেস্ট, আর্থ, তারপর হুক'],
    wrong: [
      'ঠিক, এক টানেই হুকটা খুলে দিই',
      'আচ্ছা, কল না করেই টেনে নিই',
      'হ্যাঁ, LT লাইনে কিছু হবে না',
      'ঠিক আছে, গ্লাভস আছে, টেনে দিই',
      'হ্যাঁ, শাটডাউনে অনেক দেরি হয়',
    ],
    asks: ['কী করবেন?', askHook, 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M7Push p) => p == M7Push.myth ? coworkerMyth : coworkerHook;
  static const allCoworkers = [coworkerMyth, coworkerHook];
  static String callHeld(M7Push p) => p == M7Push.myth ? 'ঠিক! চুরির দাম সৎ গ্রাহকই দেন।' : 'ঠিক! আগে লাইন বন্ধ, তারপর বাকি সব।';

  static const allSet = 'প্রমাণ দূর থেকে, হুক খোলা নিয়মে — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দূর থেকে প্রমাণ, তারপর নিয়মে খোলা।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtFar = 'দূর থেকেই প্রমাণের ছবি তুলেছেন';
  static const caughtEvidence = 'হুক আর তার, ঠিক দুটো প্রমাণ দিয়েছেন';
  static const caughtOrder = 'নির্দেশ পেয়ে তবে খুলেছেন';
  static const caughtProof = 'টেস্টারে আগে-পরে যাচাই করে ডেড প্রমাণ';
  static const caughtEarth = 'আর্থ লাগিয়ে তবে হুকে হাত দিয়েছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// New coworker lines for recording (his exit is recorded already).
  static List<String> get newRivalLines => [coworkerMyth.line, coworkerHook.line];

  /// New guide lines for recording: the openings, the tasks, the reason
  /// questions, his two new asks, the praise after refusing him, the end
  /// lines and every mistake text (read out the first time it comes).
  static List<String> get newGuideLines => [
        intro,
        introMorning,
        taskAim,
        taskSlots,
        taskSend,
        taskRemove,
        taskPaper,
        taskPhone,
        taskGear,
        for (final w in M7Why.values) whyQ(w),
        askMyth,
        askHook,
        for (final p in M7Push.values) callHeld(p),
        allSet,
        fail,
        for (final m in M7TheftMistakes.all) m.textBn,
      ];
}

abstract final class M7TheftMistakes {
  static const _dir = 'assets/game/art/m7_theft_evidence';
  static const _k = '7.5/m7_theft_evidence';

  // Lesson points (0-based): 1 the theft methods and their danger, 2 what to
  // do (stay safe, evidence from afar, report, disconnect only on the
  // authority's order). Pro tip 4 (tester, earth, full PPE) is read on point 2.
  // DRAFT wording — owner.
  static const confront = DoMistake(
    key: '$_k/confront',
    textBn: 'চোরের বাড়ির দিকে যাবেন না! ওরা আক্রমণ করতে পারে — বিবাদে জড়াবেন না, দূর থেকে জুম করে ছবি তুলুন।',
    art: '$_dir/confront.svg',
    lessonPoint: 2,
  );
  static const shotUnclear = DoMistake(
    key: '$_k/shot-unclear',
    textBn: 'ছবিটা ঝাপসা, কিছুই পড়া যায় না। জুম করে হুক আর তারটা পরিষ্কার তুলুন।',
    art: '$_dir/evidence.svg',
    lessonPoint: 2,
  );
  static const shotNeighbour = DoMistake(
    key: '$_k/shot-neighbour',
    textBn: 'এটা পাশের বাড়ির বৈধ মিটার! ভুল প্রমাণে নির্দোষ গ্রাহক বিপদে পড়েন। চুরির হুক আর তারের ছবি দিন।',
    art: '$_dir/evidence.svg',
    lessonPoint: 2,
  );
  static const shotNoProof = DoMistake(
    key: '$_k/shot-no-proof',
    textBn: 'এই ছবিতে চুরির কোনো প্রমাণ নেই। লাইনের হুক আর বাড়িতে ঢোকা তারের ছবি দিন।',
    art: '$_dir/evidence.svg',
    lessonPoint: 2,
  );
  static const shotSame = DoMistake(
    key: '$_k/shot-same',
    textBn: 'দুটো ছবিই একই জিনিসের। একটায় লাইনের হুক, অন্যটায় বাড়িতে ঢোকা তার চাই।',
    art: '$_dir/evidence.svg',
    lessonPoint: 2,
  );
  static const pushMyth = DoMistake(
    key: '$_k/push-myth',
    textBn: 'একটু একটু চুরি মিলেই বিশাল ক্ষতি, আর তার দাম সৎ গ্রাহকরাই বিলে দেন। রিপোর্ট পাঠাতেই হবে।',
    art: '$_dir/evidence.svg',
    lessonPoint: 2,
  );
  static const hookNoOrder = DoMistake(
    key: '$_k/hook-no-order',
    textBn: 'কর্তৃপক্ষের নির্দেশ ছাড়া অবৈধ সংযোগ খোলা যায় না। আগে অফিসারের নির্দেশটা নিন।',
    art: '$_dir/order.svg',
    lessonPoint: 2,
  );
  static const hookNoGloves = DoMistake(
    key: '$_k/hook-no-gloves',
    textBn: 'গ্লাভস ছাড়া হুকে হাত নয়! চোরের তার কীভাবে লাগানো, জানা নেই — আগে গ্লাভস পরুন।',
    art: '$_dir/ppe.svg',
    lessonPoint: 2,
  );
  static const hookPpe = DoMistake(
    key: '$_k/hook-ppe',
    textBn: 'পুরো PPE ছাড়া হুক খোলা নয়। হেলমেট, জুতো, হারনেস — সব পরে তবে কাজ।',
    art: '$_dir/ppe.svg',
    lessonPoint: 2,
  );
  static const earthEarly = DoMistake(
    key: '$_k/earth-early',
    textBn: 'টেস্টারে 0 V দেখার আগে আর্থ নয়। আগে লাইন ডেড প্রমাণ, তারপর আর্থ।',
    art: '$_dir/earth.svg',
    lessonPoint: 2,
  );
  static const testerUnproved = DoMistake(
    key: '$_k/tester-unproved',
    textBn: 'টেস্টার আগে জানা লাইভ পয়েন্টে যাচাই করেননি! খারাপ টেস্টারও চালু লাইনকে ডেড দেখায়।',
    art: '$_dir/tester.svg',
    lessonPoint: 2,
  );
  static const testerNotRechecked = DoMistake(
    key: '$_k/tester-not-rechecked',
    textBn: 'টেস্টের পরে টেস্টার আবার লাইভে দেখেননি। মাঝপথে বিগড়ালে 0 V-র কোনো ভরসা নেই।',
    art: '$_dir/tester.svg',
    lessonPoint: 2,
  );
  static const hookLive = DoMistake(
    key: '$_k/hook-live',
    textBn: 'চালু লাইনে হুকে হাত! চোরের তার নিম্নমানের, কীভাবে লাগানো জানা নেই — আগে লাইন বন্ধ করুন।',
    art: '$_dir/hook_live.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const pushHookLive = DoMistake(
    key: '$_k/push-hook-live',
    textBn: 'ওর কথায় চালু লাইনে হুক টানলেন! আগে শাটডাউন, টেস্টারে ডেড প্রমাণ, আর্থ — তারপর হুক।',
    art: '$_dir/hook_live.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const hookUnproven = DoMistake(
    key: '$_k/hook-unproven',
    textBn: 'শাটডাউন হয়েছে, কিন্তু টেস্টারে ডেড প্রমাণ হয়নি! 0 V না দেখে হুকে হাত দেবেন না।',
    art: '$_dir/hook_live.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const hookNoEarth = DoMistake(
    key: '$_k/hook-no-earth',
    textBn: 'ডেড প্রমাণ হলেও আর্থ ছাড়া হুকে হাত নয়! হঠাৎ লাইন চালু হলে আর্থই বাঁচায়।',
    art: '$_dir/earth.svg',
    deadly: true,
    lessonPoint: 2,
  );

  static DoMistake? forShot(M7ShotKind k) => switch (k) {
        M7ShotKind.hook || M7ShotKind.entry => null,
        M7ShotKind.unclear => shotUnclear,
        M7ShotKind.neighbour => shotNeighbour,
        M7ShotKind.none => shotNoProof,
      };

  static const List<DoMistake> all = [
    confront,
    shotUnclear,
    shotNeighbour,
    shotNoProof,
    shotSame,
    pushMyth,
    hookNoOrder,
    hookNoGloves,
    hookPpe,
    earthEarly,
    testerUnproved,
    testerNotRechecked,
    hookLive,
    pushHookLive,
    hookUnproven,
    hookNoEarth,
  ];

  /// The catalog's deadlyRules for do_7_5_b.
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

@immutable
class M7TheftDeal {
  const M7TheftDeal({
    required this.lane,
    required this.layout,
    required this.constable,
    required this.push,
    required this.reportWhy,
    required this.hookWhy,
  });

  final M7LaneLook lane;
  final List<M7Spot> layout;
  final bool constable;
  final M7Push push;

  /// The report's reason: far or evidence; the hook's: ppe or order.
  final M7Why reportWhy;
  final M7Why hookWhy;

  int get thief => lane.thief;
}

/// The houses a vantage allows (never the one beside the trainee, whose
/// zone he would start in).
List<int> m7ThievesFor(M7Vantage v) => [
      for (var i = 0; i < M7LaneGeo.houseCx.length; i++)
        if ((M7LaneGeo.houseCx[i] - M7LaneGeo.vantageX(v)).abs() > M7LaneGeo.zoneR + 5) i,
    ];

/// A fresh play: the vantage, the stealing house, the line, the method, the
/// owner, the light; phase 2's ground order and the constable; his push; the
/// two dealt reason topics.
M7TheftDeal m7TheftDeal(math.Random rng) {
  final vantage = M7Vantage.values[rng.nextInt(2)];
  final thieves = m7ThievesFor(vantage);
  final lane = M7LaneLook(
    thief: thieves[rng.nextInt(thieves.length)],
    vantage: vantage,
    line: M7LineKind.values[rng.nextInt(2)],
    method: M7Method.values[rng.nextInt(2)],
    owner: M7Owner.values[rng.nextInt(2)],
    light: M7Light.values[rng.nextInt(2)],
  );
  return M7TheftDeal(
    lane: lane,
    layout: [...M7Spot.values]..shuffle(rng),
    constable: rng.nextBool(),
    push: M7Push.values[rng.nextInt(2)],
    reportWhy: rng.nextBool() ? M7Why.far : M7Why.evidence,
    hookWhy: rng.nextBool() ? M7Why.ppe : M7Why.order,
  );
}

/// One photo in the roll, exactly as framed.
@immutable
class M7Shot {
  const M7Shot(this.id, this.frame, this.zoom, this.kind);
  final int id;
  final Rect frame;
  final double zoom;
  final M7ShotKind kind;
}

enum M7Phase { evidence, removal }

/// The play state (pure logic).
class M7TheftRun {
  M7TheftRun(this.deal);
  final M7TheftDeal deal;

  static const rollMax = 5;

  var phase = M7Phase.evidence;
  int slips = 0;

  /// Slips since the last ◆ table (a clean step earns +5 more).
  int stepSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // Phase 1.
  final List<M7Shot> roll = [];
  final List<M7Shot?> slots = [null, null];
  int _nextId = 0;
  var reportSent = false;

  // Phase 2.
  var orderTaken = false;
  var off = false;
  var liveBefore = false;
  var zero = false;
  var liveAfter = false;
  var earthed = false;
  var bagOpen = false;
  final Set<M7Gear> worn = {};
  var hookOff = false;

  bool get slotsFull => slots.every((s) => s != null);
  bool get proven => zero && liveAfter;
  bool get allWorn => worn.length == M7Gear.values.length;
  bool get readyForHook => orderTaken && off && proven && earthed && allWorn;
  bool get done => hookOff;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _evidence => !ended && phase == M7Phase.evidence && !reportSent;
  bool get _removal => !ended && phase == M7Phase.removal && !hookOff;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return m;
  }

  /// A step paid on the table: its bonus counts from here.
  void stepDone() => stepSlips = 0;

  // --- phase 1 ---------------------------------------------------------------
  /// The shutter: the photo goes into the roll as framed (the oldest one not
  /// in a slot drops out when the roll is full).
  M7Shot? shoot(Rect frame, double zoom, M7LaneGeo g) {
    if (!_evidence) return null;
    final s = M7Shot(_nextId++, frame, zoom, m7Classify(frame, zoom, g, deal.thief));
    if (roll.length >= rollMax) {
      final drop = roll.indexWhere((r) => !slots.any((x) => x?.id == r.id));
      if (drop >= 0) roll.removeAt(drop);
    }
    roll.add(s);
    return s;
  }

  /// Puts the roll's photo [id] into [slot] (moved there if it is in the
  /// other slot).
  bool place(int id, int slot) {
    if (!_evidence || slot < 0 || slot > 1) return false;
    final i = roll.indexWhere((r) => r.id == id);
    if (i < 0) return false;
    for (var k = 0; k < 2; k++) {
      if (slots[k]?.id == id) slots[k] = null;
    }
    slots[slot] = roll[i];
    return true;
  }

  void clearSlot(int slot) {
    if (_evidence && slot >= 0 && slot < 2) slots[slot] = null;
  }

  /// পাঠান: the first bad slot is a slip (every bad slot empties); the same
  /// proof twice is a slip (the second slot empties); else the report goes.
  DoMistake? send() {
    if (!_evidence || !slotsFull) return null;
    DoMistake? first;
    for (var k = 0; k < 2; k++) {
      final m = M7TheftMistakes.forShot(slots[k]!.kind);
      if (m != null) {
        first ??= m;
        slots[k] = null;
      }
    }
    if (first != null) return _slip(first);
    if (slots[0]!.kind == slots[1]!.kind) {
      slots[1] = null;
      return _slip(M7TheftMistakes.shotSame);
    }
    reportSent = true;
    _tag(M7TheftLines.caughtEvidence);
    _tag(M7TheftLines.caughtFar);
    return null;
  }

  /// The trainee walked up to the stealing house.
  DoMistake? confront() => _evidence ? _slip(M7TheftMistakes.confront) : null;

  void startRemoval() {
    if (reportSent && !ended) phase = M7Phase.removal;
  }

  // --- phase 2 ---------------------------------------------------------------
  bool takeOrder() {
    if (!_removal || orderTaken) return false;
    orderTaken = true;
    return true;
  }

  bool callShutdown() {
    if (!_removal || off) return false;
    off = true;
    return true;
  }

  /// The tester on [at]: its reading, a slip (the line read without the
  /// tester proved first; the line read again is not), and whether this
  /// touch completed live → 0 V → live.
  ({String reading, DoMistake? mistake, bool provenNow}) test(M7TestAt at) {
    if (!_removal) return (reading: '', mistake: null, provenNow: false);
    if (at == M7TestAt.prover) {
      if (zero && !liveAfter) {
        liveAfter = true;
        _tag(M7TheftLines.caughtProof);
        return (reading: 'LIVE', mistake: null, provenNow: true);
      }
      if (!zero) liveBefore = true;
      return (reading: 'LIVE', mistake: null, provenNow: false);
    }
    if (!off) return (reading: 'LIVE', mistake: null, provenNow: false);
    if (zero) return (reading: '0 V', mistake: null, provenNow: false);
    if (!liveBefore) return (reading: '0 V', mistake: _slip(M7TheftMistakes.testerUnproved), provenNow: false);
    zero = true;
    return (reading: '0 V', mistake: null, provenNow: false);
  }

  /// The earth on the span: before the 0 V (N3) or before the tester is
  /// checked live again (N4) it is a slip and comes back.
  DoMistake? placeEarth() {
    if (!_removal || earthed) return null;
    if (!zero) return _slip(M7TheftMistakes.earthEarly);
    if (!liveAfter) return _slip(M7TheftMistakes.testerNotRechecked);
    earthed = true;
    _tag(M7TheftLines.caughtEarth);
    return null;
  }

  bool openBag() {
    if (!_removal || bagOpen) return false;
    bagOpen = true;
    return true;
  }

  bool wear(M7Gear g) => _removal && bagOpen && worn.add(g);

  /// A hand on the hook: live (R13), unproven (N1) or not earthed (N2) =
  /// deadly; then the order (R14), the গ্লাভস (M7-2 after the proven
  /// isolation) and the rest of the PPE (R14) = slips. Null: he may pull.
  DoMistake? grabHook() {
    if (!_removal) return null;
    if (!off) return M7TheftMistakes.hookLive;
    if (!zero) return M7TheftMistakes.hookUnproven;
    if (!earthed) return M7TheftMistakes.hookNoEarth;
    if (!orderTaken) return _slip(M7TheftMistakes.hookNoOrder);
    if (!worn.contains(M7Gear.gloves)) return _slip(M7TheftMistakes.hookNoGloves);
    if (!allWorn) return _slip(M7TheftMistakes.hookPpe);
    return null;
  }

  /// The hook pulled off (only once [grabHook] allowed it).
  bool removeHook() {
    if (!_removal || !readyForHook) return false;
    hookOff = true;
    _tag(M7TheftLines.caughtOrder);
    return true;
  }

  DoMistake pushSlip(DoMistake m) => _slip(m);
  void failDeadly(DoMistake m) => deadly = m;
}

/// The quick bonus: the builder's estimate (~85 % of a clean play, ruling
/// M7-13; quickMs after playtest). A clean play ≈ two framed shots (~20 s) +
/// the slots and পাঠান (~8 s) + the report's reason (~8 s) + the morning card
/// (~4 s) + the order (~5 s) + the call (~4 s) and its reason (~8 s) + three
/// tester touches (~9 s) and the reason (~8 s) + the earth (~4 s) and its
/// reason (~8 s) + four PPE items (~10 s) + the hook (~4 s) and its reason
/// (~8 s) + the coworker (~10 s) ≈ 140 s.
const m7TheftQuickMs = 120000;

@immutable
class M7TheftPack {
  const M7TheftPack({required this.id, required this.titleBn, this.quickMs = m7TheftQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7TheftPack> m7TheftPacks = {
  'do_7_5_b': M7TheftPack(id: 'do_7_5_b', titleBn: M7TheftLines.title),
};

/// Test hook (tests only): the open play's camera, scenes and run, and the
/// same moves a finger makes.
class M7TheftProbe {
  M7TheftProbe._(this._s);
  final _TheftRunPageState _s;
  static M7TheftProbe? current;

  M7TheftRun get run => _s._run;
  M7TheftDeal get deal => _s._run.deal;
  M7Cam get cam => _s._cam.value;
  M7LaneGeo? get lane => _s._laneNow;
  M7PoleGeo? get pole => _s._poleNow;
  double get traineeX => _s._traineeX;

  /// Puts the frame on [centre] at [zoom] (as a drag and the rail would).
  void aimAt(Offset centre, double zoom) => _s._aimAt(centre, zoom);
  void shoot() => _s._shoot(Offset.zero);
  void place(int id, int slot) => _s._place(id, slot);
  void walkTo(double x) => _s._walkTo(x);
  void tapSpot(M7Spot s) => _s._tapSpot(s, Offset.zero);
  void readOrder() => _s._readOrder();
  void callShutdown() => _s._callShutdown();
  void test(M7TestAt at) => _s._testerOn(at, Offset.zero);
  void earth() => _s._earthOnLine(Offset.zero);
  void wear(M7Gear g) => _s._wear(g);

  /// A hand on the hook, then (if allowed) the pull off.
  void pullHook() {
    _s._grabHook(Offset.zero);
    _s._releaseHook(60);
  }
}

// ============================================================================
// Page
// ============================================================================

class M7TheftEvidencePage extends StatefulWidget {
  const M7TheftEvidencePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7TheftPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7TheftEvidencePage> createState() => _M7TheftEvidencePageState();
}

class _M7TheftEvidencePageState extends State<M7TheftEvidencePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TheftRunPage(
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

class _TheftRunPage extends ConsumerStatefulWidget {
  const _TheftRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7TheftPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TheftRunPage> createState() => _TheftRunPageState();
}

class _TheftRunPageState extends ConsumerState<_TheftRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  static const _trayH = 62.0;
  static const _shutterD = 68.0;
  static const _rowH = 72.0;
  static const _slotW = 76.0;
  static const _sendW = 72.0;
  static const _liveW = 96.0;

  final _scoreKey = GlobalKey();
  late final M7TheftRun _run;
  late final int _seed = widget.rng.nextInt(1 << 20);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  int _taskChain = -1;
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

  // Phase 1: the camera and the trainee on the road.
  final _cam = ValueNotifier<M7Cam>(const M7Cam(Offset(170, 400), 1));
  M7LaneGeo? _laneNow;
  M7LanePainter? _lane;
  var _camSet = false;
  var _moved = false;
  var _zoomed = false;
  late double _traineeX = M7LaneGeo.vantageX(_run.deal.lane.vantage);
  var _ownerOut = false;
  int _flashTok = 0;
  double _railH = _ZoomRail.maxHeight;

  // Phase 2.
  M7PoleGeo? _poleNow;
  M7PolePainter? _pole;
  var _paperOpen = false;
  var _phoneOpen = false;
  var _morning = false;
  int _morningTok = 0;
  String _reading = '';
  final _carryAt = ValueNotifier<Offset?>(null);
  Object? _carrying;
  var _holdingHook = false;
  double _hookLift = 0;

  // Pointers on the scene (design px).
  final Map<int, Offset> _ptrs = {};
  Offset _downAt = Offset.zero;
  Offset _downGlobal = Offset.zero;
  var _downMoved = false;
  double? _pinchD0;
  double _pinchZ0 = 1;
  var _walking = false;
  Object? _downOn;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // The gesture hand.
  final _hints = IdleHintController();
  final _shutterKey = GlobalKey();
  final _sendKey = GlobalKey();
  final _zoomThumbKey = GlobalKey();
  final _paperOkKey = GlobalKey();
  final _callKey = GlobalKey();
  final Map<int, GlobalKey> _thumbKeys = {};
  int _hintN = 0;

  @override
  void initState() {
    super.initState();
    _run = M7TheftRun(m7TheftDeal(widget.rng));
    M7TheftProbe.current = M7TheftProbe._(this);
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M7TheftDeal get _deal => _run.deal;
  bool get _phase1 => _run.phase == M7Phase.evidence;

  @override
  void dispose() {
    disposeCoworker();
    _cam.dispose();
    _carryAt.dispose();
    _chain++;
    if (M7TheftProbe.current?._s == this) M7TheftProbe.current = null;
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

  /// A task line said: the gesture hand waits while it is said, then the
  /// bubble clears so it never stands over the lane while the player aims.
  Future<void> _sayTask(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    if (lines.isEmpty) return;
    final chain = _chain + 1;
    _taskChain = chain;
    await _sayChain(lines, mood: mood);
    if (_muted) await Future<void>.delayed(MascotSpeechLibrary.readHold(lines.last));
    if (!mounted || chain != _chain) return;
    final guide = ref.read(guideDirectorProvider);
    if (guide.line == lines.last) ref.read(guideDirectorProvider.notifier).softClearLine();
    setState(() => _taskChain = -1);
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_morning;

  bool get _canAim => _canPlay && _phase1 && !_run.reportSent;

  String get _task {
    if (_phase1) {
      if (_run.slotsFull) return M7TheftLines.taskSend;
      if (_run.roll.isNotEmpty) return M7TheftLines.taskSlots;
      return M7TheftLines.taskAim;
    }
    if (_paperOpen) return M7TheftLines.taskPaper;
    if (_phoneOpen) return M7TheftLines.taskPhone;
    if (_run.bagOpen && !_run.allWorn) return M7TheftLines.taskGear;
    return M7TheftLines.taskRemove;
  }

  // --- the flow ----------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    final g = _laneNow;
    if (g != null && !_camSet) {
      _camSet = true;
      _cam.value = g.startCam;
    }
    setState(() => _wake++);
    unawaited(_sayTask([M7TheftLines.taskAim]));
  }

  // --- phase 1: the camera -------------------------------------------------------
  void _setCam(M7Cam c) {
    final g = _laneNow;
    final next = g == null ? c : g.clampCam(c);
    if (next != _cam.value) _cam.value = next;
  }

  void _panBy(Offset d) {
    _setCam(M7Cam(_cam.value.center + d, _cam.value.zoom));
    if (!_moved && d.distance > 0) setState(() => _moved = true);
  }

  void _setZoom(double z) {
    final z0 = _cam.value.zoom;
    _setCam(M7Cam(_cam.value.center, z));
    if (!_zoomed && (_cam.value.zoom - z0).abs() > 0.01) setState(() => _zoomed = true);
  }

  void _aimAt(Offset centre, double zoom) {
    if (!_canAim) return;
    _setCam(M7Cam(centre, zoom));
    setState(() {
      _moved = true;
      _zoomed = true;
    });
  }

  void _railDrag(double dy) {
    if (!_canAim) return;
    _setZoom(_cam.value.zoom - dy / (_railH - _ZoomRail.thumb) * (m7ZoomMax - m7ZoomMin));
  }

  void _shoot(Offset global) {
    if (!_canAim) return;
    final g = _laneNow;
    if (g == null) return;
    HapticFeedback.lightImpact();
    _cue('sounds/intro/click.ogg', volume: 0.8);
    final first = _run.roll.isEmpty;
    final cam = _cam.value;
    final s = _run.shoot(cam.frame, cam.zoom, g);
    if (s == null) return;
    setState(() {
      _flashTok++;
      _thumbKeys.putIfAbsent(s.id, GlobalKey.new);
      _thumbKeys.removeWhere((id, _) => !_run.roll.any((r) => r.id == id));
    });
    if (first) unawaited(_sayTask([M7TheftLines.taskSlots]));
  }

  void _place(int id, int slot) {
    if (!_canAim) return;
    if (!_run.place(id, slot)) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() => _wake++);
    if (_run.slotsFull) {
      if (_deal.push == M7Push.myth && !coworkerDone && !coworkerDue) scheduleCoworker();
      unawaited(_sayTask([M7TheftLines.taskSend]));
    }
  }

  void _clearSlot(int slot) {
    if (!_canAim || _run.slots[slot] == null) return;
    _tick();
    setState(() => _run.clearSlot(slot));
  }

  Future<void> _send(Offset origin) async {
    if (!_canAim || !_run.slotsFull) return;
    if (_deal.push == M7Push.myth && holdForCoworker()) return;
    _tick('sounds/intro/confirm.ogg', 0.6);
    final m = _run.send();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    putOnTable(10 + (_run.stepSlips == 0 ? 5 : 0));
    _run.stepDone();
    final w = _deal.reportWhy;
    unawaited(askReason(
      deal: () => dealChoices(M7TheftLines.whyRight[w]!, M7TheftLines.wrongFor(w), widget.rng),
      question: M7TheftLines.whyQ(w),
      stillValid: () => !_ended,
    ));
  }

  // --- phase 1: the walk -----------------------------------------------------------
  void _walkTo(double x) {
    if (!_canAim) return;
    final nx = x.clamp(12.0, 300.0);
    if (nx == _traineeX) return;
    setState(() {
      _traineeX = nx;
      _wake++;
    });
    final thiefX = M7LaneGeo.houseCx[_deal.thief];
    if ((nx - thiefX).abs() < M7LaneGeo.zoneR) unawaited(_confront());
  }

  Future<void> _confront() async {
    final m = _run.confront();
    if (m == null) return;
    _walking = false;
    _cue('sounds/learn/rush_in.ogg', volume: 0.6);
    setState(() {
      _ownerOut = true;
      _lane = null;
      _traineeX = M7LaneGeo.vantageX(_deal.lane.vantage);
    });
    final g = _laneNow;
    unawaited(_mistake(m, g == null ? Offset.zero : Offset(M7LaneGeo.houseCx[_deal.thief], g.groundY)));
  }

  // --- phase 2 -------------------------------------------------------------------------
  void _toMorning() {
    if (_ended) return;
    _run.startRemoval();
    setState(() {
      _morning = true;
      _morningTok++;
      _wake++;
    });
    _cue('sounds/intro/glass.ogg', volume: 0.45);
    final tok = _morningTok;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1700), () {
      if (!mounted || _ended || tok != _morningTok) return;
      setState(() => _morning = false);
      unawaited(_sayTask([M7TheftLines.introMorning]));
    }));
  }

  void _tapSpot(M7Spot s, Offset global) {
    if (!_canPlay || _phase1 || _paperOpen || _phoneOpen) return;
    switch (s) {
      case M7Spot.officer:
        _tick('sounds/intro/glass.ogg', 0.5);
        setState(() => _paperOpen = true);
        unawaited(_sayTask([M7TheftLines.taskPaper]));
      case M7Spot.phone:
        _tick();
        setState(() => _phoneOpen = true);
        if (_deal.push == M7Push.hook && !_run.off && !coworkerDone && !coworkerDue) scheduleCoworker();
        unawaited(_sayTask([M7TheftLines.taskPhone]));
      case M7Spot.bag:
        if (!_run.openBag()) {
          _hints.missTap();
          return;
        }
        _tick('sounds/learn/card_deal_a.ogg', 0.6);
        setState(() {
          _pole = null;
          _wake++;
        });
        unawaited(_sayTask([M7TheftLines.taskGear]));
      case M7Spot.tester:
      case M7Spot.earth:
        _hints.missTap();
    }
  }

  void _readOrder() {
    if (!_paperOpen || _ended) return;
    final first = _run.takeOrder();
    _tick('sounds/intro/confirm.ogg', 0.6);
    setState(() => _paperOpen = false);
    if (first) {
      final size = MediaQuery.sizeOf(context);
      unawaited(_levelDelta(5, Offset(size.width / 2, size.height * 0.4), mood: GuideMood.glad));
    }
  }

  void _callShutdown() {
    if (!_phoneOpen || _ended || coworkerOpen || tableBusy || _card != null) return;
    if (_deal.push == M7Push.hook && holdForCoworker()) return;
    if (!_run.callShutdown()) return;
    _hush();
    _cue('sounds/intro/click.ogg', volume: 0.8);
    HapticFeedback.mediumImpact();
    setState(() {
      _phoneOpen = false;
      _pole = null;
      _wake++;
    });
    _table(M7Why.shutdown);
  }

  /// A step done right: ◆ on the table, the reason.
  void _table(M7Why w, {int base = 10}) {
    putOnTable(base + (_run.stepSlips == 0 ? 5 : 0));
    _run.stepDone();
    unawaited(askReason(
      deal: () => dealChoices(M7TheftLines.whyRight[w]!, M7TheftLines.wrongFor(w), widget.rng),
      question: M7TheftLines.whyQ(w),
      stillValid: () => !_ended,
    ));
  }

  void _testerOn(M7TestAt at, Offset origin) {
    if (!_canPlay || _phase1) return;
    final r = _run.test(at);
    if (r.reading.isEmpty) return;
    _cue(r.reading == 'LIVE' ? 'sounds/learn/spark.ogg' : 'sounds/intro/tick.ogg', volume: r.reading == 'LIVE' ? 0.35 : 0.5);
    setState(() {
      _reading = r.reading;
      _pole = null;
      _wake++;
    });
    if (r.mistake != null) {
      unawaited(_mistake(r.mistake!, origin));
      return;
    }
    if (r.provenNow) _table(M7Why.tester);
  }

  void _earthOnLine(Offset origin) {
    if (!_canPlay || _phase1) return;
    final m = _run.placeEarth();
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    if (!_run.earthed) return;
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    setState(() {
      _pole = null;
      _wake++;
    });
    _table(M7Why.earth);
  }

  void _wear(M7Gear g) {
    if (!_canPlay || _phase1) return;
    if (!_run.wear(g)) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() {
      _pole = null;
      _wake++;
    });
    if (_run.allWorn) unawaited(_sayTask([M7TheftLines.taskRemove]));
  }

  /// A hand on the hook.
  void _grabHook(Offset origin) {
    if (!_canPlay || _phase1 || _run.hookOff || _holdingHook) return;
    final m = _run.grabHook();
    if (m != null) {
      if (m.deadly) {
        _flashAt = _poleNow?.hookAt ?? Offset.zero;
        _run.failDeadly(m);
        unawaited(_deadly(m));
      } else {
        unawaited(_mistake(m, origin));
      }
      return;
    }
    setState(() => _holdingHook = true);
  }

  void _releaseHook(double lift) {
    if (!_holdingHook) return;
    if (lift >= 36 && _run.removeHook()) {
      _hush();
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      HapticFeedback.mediumImpact();
      setState(() {
        _holdingHook = false;
        _hookLift = 0;
        _pole = null;
        _wake++;
      });
      _table(_deal.hookWhy, base: 15);
      return;
    }
    setState(() {
      _holdingHook = false;
      _hookLift = 0;
      _pole = null;
    });
  }

  // --- pointers -------------------------------------------------------------------------
  Object? _hitPole(Offset p) {
    final g = _poleNow;
    if (g == null) return null;
    if (!_run.hookOff && g.hook.inflate(8).contains(p)) return 'hook';
    if (_run.bagOpen) {
      for (final gear in M7Gear.values) {
        if (!_run.worn.contains(gear) && g.gear(gear).contains(p)) return gear;
      }
    }
    for (final (i, s) in _deal.layout.indexed) {
      final r = switch (s) {
        M7Spot.officer => g.officer(i),
        M7Spot.tester => g.tester(i).inflate(4),
        _ => g.spot(i),
      };
      if (s == M7Spot.earth && _run.earthed) continue;
      if (r.contains(p)) return s;
    }
    return null;
  }

  void _pointerDown(PointerDownEvent e) {
    _ptrs[e.pointer] = e.localPosition;
    if (_ptrs.length == 1) {
      _downAt = e.localPosition;
      _downGlobal = e.position;
      _downMoved = false;
      _walking = false;
      _downOn = null;
      if (_phase1) {
        final g = _laneNow;
        if (g != null && _canAim && g.trainee(_traineeX).inflate(6).contains(e.localPosition)) _walking = true;
      } else if (_canPlay && !_paperOpen && !_phoneOpen) {
        _downOn = _hitPole(e.localPosition);
      }
    } else if (_ptrs.length == 2) {
      final p = _ptrs.values.toList();
      _pinchD0 = (p[0] - p[1]).distance;
      _pinchZ0 = _cam.value.zoom;
      _downMoved = true;
      _walking = false;
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    final prev = _ptrs[e.pointer];
    if (prev == null) return;
    _ptrs[e.pointer] = e.localPosition;
    final wasMoved = _downMoved;
    if ((e.localPosition - _downAt).distance > 8) _downMoved = true;
    if (_phase1) {
      if (!_canAim) return;
      if (_walking) {
        _walkTo(_traineeX + (e.localPosition.dx - prev.dx));
      } else if (_ptrs.length == 1) {
        _panBy(e.localPosition - prev);
      } else if (_ptrs.length >= 2) {
        final d0 = _pinchD0;
        final p = _ptrs.values.toList();
        if (d0 != null && d0 > 4) _setZoom(_pinchZ0 * (p[0] - p[1]).distance / d0);
      }
      return;
    }
    final on = _downOn;
    if (on == null || _ptrs.length != 1) return;
    if (!wasMoved && _downMoved) {
      // The drag starts: pick it up.
      if (on == 'hook') {
        _grabHook(e.position);
      } else if (on == M7Spot.tester || on == M7Spot.earth || on is M7Gear) {
        if (!_canPlay) return;
        setState(() {
          _carrying = on;
          _pole = null;
        });
      }
    }
    if (on == 'hook' && _holdingHook) {
      setState(() => _hookLift = (e.localPosition.dy - _downAt.dy).clamp(0.0, 60.0));
    } else if (_carrying != null) {
      _carryAt.value = e.localPosition;
    }
  }

  void _pointerUp(PointerEvent e) {
    _ptrs.remove(e.pointer);
    if (_ptrs.length < 2) _pinchD0 = null;
    if (_ptrs.isNotEmpty) return;
    final up = e is PointerUpEvent;
    if (_phase1) {
      _walking = false;
      if (!_downMoved && up && _canPlay) _hints.missTap();
      return;
    }
    final on = _downOn;
    _downOn = null;
    if (on == 'hook' && _holdingHook) {
      _releaseHook(up ? _hookLift : 0);
      return;
    }
    final carried = _carrying;
    if (carried != null) {
      _carryAt.value = null;
      setState(() {
        _carrying = null;
        _pole = null;
      });
      if (up) _drop(carried, e.localPosition, e.position);
      return;
    }
    if (!_downMoved && up && _canPlay) {
      if (on is M7Spot) {
        _tapSpot(on, _downGlobal);
      } else if (!_paperOpen && !_phoneOpen) {
        _hints.missTap();
      }
    }
  }

  void _drop(Object what, Offset at, Offset global) {
    final g = _poleNow;
    if (g == null) return;
    if (what == M7Spot.tester) {
      final ti = _deal.layout.indexOf(M7Spot.tester);
      if (g.prover(ti).inflate(10).contains(at)) {
        _testerOn(M7TestAt.prover, global);
      } else if (g.lineBand.contains(at)) {
        _testerOn(M7TestAt.line, global);
      }
    } else if (what == M7Spot.earth) {
      if (g.lineBand.contains(at)) _earthOnLine(global);
    } else if (what is M7Gear) {
      if (g.trainee.inflate(18).contains(at)) _wear(what);
    }
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (!mounted || _ended) return;
      if (_phase1) {
        _toMorning();
      } else if (_run.hookOff) {
        unawaited(_finish());
      } else {
        unawaited(_sayTask([_task]));
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7TheftLines.coworker(_deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final busy = _intro || _card != null || tableBusy || _freeze || _morning;
    switch (_deal.push) {
      case M7Push.myth:
        if (!_phase1 || _run.reportSent) return null;
        return _run.slotsFull && !busy;
      case M7Push.hook:
        if (_run.off) return null;
        return !_phase1 && _phoneOpen && !busy;
    }
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _deal.push;
    if (!held) {
      if (p == M7Push.hook) {
        _flashAt = _poleNow?.hookAt ?? Offset.zero;
        _run.failDeadly(M7TheftMistakes.pushHookLive);
        setState(() => _phoneOpen = false);
        await _deadly(M7TheftMistakes.pushHookLive);
        return;
      }
      _run.pushSlip(M7TheftMistakes.pushMyth);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(M7TheftMistakes.pushMyth);
      return;
    }
    _run.caught.add(M7TheftLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayTask([M7TheftLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    _tick('sounds/intro/tick.ogg', 0.5);
    if (coworkerOpen) {
      unawaited(_sayChain([nextCoworkerAsk()]));
    } else if (reasonOpen) {
      unawaited(_sayChain([M7TheftLines.tapWhy[_nudgeN++ % M7TheftLines.tapWhy.length]]));
    } else {
      unawaited(_sayTask([_nudge.next(_task)]));
    }
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
    final speak = await SpokenOnce.first('m7theft/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on the live (or unproven, or unearthed) hook: the scene freezes
  /// grey and the arc comes off the hook in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _paperOpen = false;
      _phoneOpen = false;
      _carrying = null;
      _holdingHook = false;
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
    final speak = await SpokenOnce.first('m7theft/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M7TheftLines.deadlyWord : M7TheftLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _ownerOut = false;
          _lane = null;
          _wake++;
        });
        unawaited(_sayTask([_task]));
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
    await _say(!_run.passed ? M7TheftLines.fail : (_quickBonus ? M7TheftLines.quick : M7TheftLines.allSet),
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

  // --- the gesture hand ------------------------------------------------------------
  /// How to touch, never what. Phase 1: a fixed drag nudge from the frame's
  /// centre; once moved, a nudge up the zoom thumb; then those and a tap on
  /// the shutter in turn; with photos in the roll, a sweep over every
  /// thumbnail in turn with them; both slots full, a tap on পাঠান. The walk
  /// is never hinted. Phase 2: a sweep over the officer, the phone, the bag,
  /// the tester, the earth set and the hook alike; the paper's পড়েছি and the
  /// phone's call (the one way forward there); with the bag open, a generic
  /// upward nudge of its first item in turn; the hook's nudge only once the
  /// order, the shutdown, the proof, the earth and the full PPE are done.
  HintSpec? _hint() {
    final n = _hintN++;
    if (_phase1) {
      if (_run.slotsFull) return HintSpec.tapOn(_sendKey);
      final pan = HintSpec.drag(_cam.value.center, toward: const Offset(-0.7071, -0.7071), travel: 64, space: HintSpace.scene);
      final zoom = HintSpec.dragFrom(_zoomThumbKey, toward: const Offset(0, -1), travel: 48);
      final aim = !_moved ? pan : (!_zoomed ? zoom ?? pan : [pan, zoom, HintSpec.tapOn(_shutterKey)][n % 3] ?? pan);
      if (_run.roll.isNotEmpty && n.isOdd) {
        return HintSpec.sweepOver([for (final s in _run.roll) ?_thumbKeys[s.id]]) ?? aim;
      }
      return aim;
    }
    if (_paperOpen) return HintSpec.tapOn(_paperOkKey);
    if (_phoneOpen) return HintSpec.tapOn(_callKey);
    final g = _poleNow;
    if (g == null) return null;
    if (_run.readyForHook) return HintSpec.drag(g.hook.center, toward: const Offset(0, 1), travel: 48, space: HintSpace.scene);
    final rects = <Rect>[
      for (final (i, s) in _deal.layout.indexed)
        if (!(s == M7Spot.earth && _run.earthed))
          switch (s) {
            M7Spot.officer => g.officer(i),
            M7Spot.tester => g.tester(i),
            _ => g.spot(i),
          },
      if (!_run.hookOff) g.hook,
    ];
    final sweep = HintSpec.sweep(rects, space: HintSpace.scene);
    if (_run.bagOpen && !_run.allWorn && n.isOdd) {
      final first = M7Gear.values.firstWhere((x) => !_run.worn.contains(x));
      return HintSpec.drag(g.gear(first).center, toward: const Offset(0, -1), travel: 48, space: HintSpace.scene);
    }
    return sweep;
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_walking) return LinemanMode.walk;
    return _phase1 ? LinemanMode.hold : LinemanMode.idle;
  }

  M7LanePainter _laneFor(M7LaneGeo g) {
    final look = _deal.lane.withOwnerOut(_ownerOut);
    final w = _lane;
    if (w != null && w.geo == g && w.look == look) return w;
    return _lane = M7LanePainter(geo: g, look: look, seed: _seed);
  }

  M7PolePainter _poleFor(M7PoleGeo g) {
    final look = M7PoleLook(
      layout: _deal.layout,
      line: _deal.lane.line,
      method: _deal.lane.method,
      constable: _deal.constable,
      off: _run.off,
      earthed: _run.earthed,
      hookOff: _run.hookOff,
      bagOpen: _run.bagOpen,
      worn: {..._run.worn},
      reading: _reading,
      carrying: _carrying,
      hookLift: _hookLift,
    );
    final p = _pole;
    if (p != null && p.geo == g && p.look == look) return p;
    return _pole = M7PolePainter(geo: g, look: look);
  }

  List<Widget> _scene(SceneMetrics m) {
    final w = math.max(1.0, MediaQuery.sizeOf(context).width);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final List<Widget> world;
    if (_phase1) {
      final g = _laneNow = M7LaneGeo.forScene(m.height, m.inset, topInset: MediaQuery.paddingOf(context).top * 360 / w);
      world = [
        Positioned.fill(key: const ValueKey('lane'), child: RepaintBoundary(child: CustomPaint(painter: _laneFor(g)))),
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: g.trainee(_traineeX),
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      ];
    } else {
      final g = _poleNow = M7PoleGeo.forScene(m.height, m.inset);
      final gloves = _run.worn.contains(M7Gear.gloves);
      final look = LinemanLook(
        helmet: LinemanLook.trainee.helmet,
        shirt: LinemanLook.trainee.shirt,
        vest: LinemanLook.trainee.vest,
        pants: LinemanLook.trainee.pants,
        skin: LinemanLook.trainee.skin,
        gloves: gloves,
        gloveColor: LinemanLook.rubberGloves,
      );
      world = [
        Positioned.fill(key: const ValueKey('pole'), child: RepaintBoundary(child: CustomPaint(painter: _poleFor(g)))),
        Positioned.fromRect(
          key: const ValueKey('trainee2'),
          rect: g.trainee,
          child: LinemanFigure(look: look, mode: _mode, wake: _wake, quiet: quiet),
        ),
        Positioned(
          key: const ValueKey('worn'),
          left: g.trainee.left - 4,
          top: g.trainee.bottom + 2,
          width: 44,
          height: 12,
          child: IgnorePointer(child: CustomPaint(painter: _WornPainter(worn: {..._run.worn}))),
        ),
      ];
    }
    final aiming = !_intro && _canAimLook && !_freeze && _mark == null;
    final carried = _carrying;
    return [
      Positioned.fill(
        key: ValueKey('world-${_run.phase.name}'),
        child: ColorFiltered(colorFilter: grey, child: Stack(children: world)),
      ),
      if (aiming)
        Positioned.fill(
          key: const ValueKey('frame'),
          child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M7FramePainter(cam: _cam)))),
        ),
      if (carried != null)
        Positioned.fill(
          key: const ValueKey('carry'),
          child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M7CarryPainter(what: carried, at: _carryAt)))),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: _phase1 ? M7TheftLines.sceneLabel : M7TheftLines.poleLabel,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerUp,
          ),
        ),
      ),
      if (_flashTok > 0 && !quiet && !_freeze && _phase1)
        Positioned.fill(
          key: ValueKey('shutter-flash-$_flashTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 0),
              duration: const Duration(milliseconds: 260),
              builder: (_, v, _) => v <= 0.01 ? const SizedBox.shrink() : ColoredBox(color: Colors.white.withValues(alpha: v)),
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
              builder: (_, v, _) => CustomPaint(painter: M7FlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
    ];
  }

  bool get _canAimLook => _phase1 && !_run.reportSent;

  Widget _photo(M7Shot s, M7LanePainter world, {double? w, double? h}) => SizedBox(
        width: w,
        height: h,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5), borderRadius: BorderRadius.circular(6)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: RepaintBoundary(child: CustomPaint(painter: M7CropPainter(world: world, crop: s.frame), size: Size.infinite)),
          ),
        ),
      );

  Widget _slotBox(int k, M7LanePainter world) {
    final s = _run.slots[k];
    return DragTarget<int>(
      key: ValueKey('slot-$k'),
      onWillAcceptWithDetails: (_) => _canAim,
      onAcceptWithDetails: (d) => _place(d.data, k),
      builder: (context, cand, _) => Semantics(
        label: '${M7TheftLines.slot} ${k + 1}',
        button: s != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: s == null ? _hints.missTap : () => _clearSlot(k),
          child: Container(
            width: _slotW,
            height: _rowH,
            decoration: BoxDecoration(
              color: const Color(0xCC0B1A33),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cand.isNotEmpty ? SlmColors.gold400 : const Color(0x88FFFFFF), width: cand.isNotEmpty ? 2 : 1),
            ),
            padding: const EdgeInsets.all(3),
            child: s != null
                ? _photo(s, world)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, size: 22, color: Color(0xCCFFFFFF)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${M7TheftLines.slot} ${k + 1}', maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xCCFFFFFF))),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _roll(M7LanePainter world) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xCC0B1A33), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x55FFFFFF))),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < M7TheftRun.rollMax; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: i < _run.roll.length
                  ? LayoutBuilder(builder: (context, box) {
                      final s = _run.roll[i];
                      final thumb = _photo(s, world, w: box.maxWidth, h: box.maxHeight);
                      return Semantics(
                        key: _thumbKeys.putIfAbsent(s.id, GlobalKey.new),
                        label: '${M7TheftLines.roll} ${s.id + 1}',
                        child: Draggable<int>(
                          data: s.id,
                          maxSimultaneousDrags: _canAim ? 1 : 0,
                          feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.9, child: _photo(s, world, w: _slotW, h: _rowH * 0.75))),
                          childWhenDragging: Opacity(opacity: 0.35, child: thumb),
                          child: thumb,
                        ),
                      );
                    })
                  : DecoratedBox(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0x33FFFFFF))),
                      child: const Center(child: Icon(Icons.photo_camera_outlined, size: 16, color: Color(0x55FFFFFF))),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = math.max(1.0, size.width);
    final sceneH = (360 * size.height / w).clamp(560.0, 900.0);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_morning;
    final lane = _phase1 ? _laneFor(_laneNow ?? M7LaneGeo.forScene(sceneH, pad.bottom * 360 / w, topInset: pad.top * 360 / w)) : null;
    final aiming = handsOn && _canAimLook;
    final controlBottom = pad.bottom + 8 + _trayH + 10;
    final guideBottom = _phase1 ? pad.bottom + 8 + _trayH + 2 : pad.bottom + 8;
    final rowTop = pad.top + 62;
    final railTop = rowTop + _rowH + 10;
    _railH = (size.height - guideBottom - 116 - 8 - railTop).clamp(96.0, _ZoomRail.maxHeight);
    final waitingPhase2 = !_phase1 && !_run.hookOff;
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _taskChain != _chain && _carrying == null && !_holdingHook && (aiming || waitingPhase2),
            hintKey: '${_run.phase.name}/${_run.roll.length}/${_run.slotsFull}/$_paperOpen/$_phoneOpen/${_run.bagOpen}/${_run.readyForHook}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 170), quiet: quiet),
              if (playing && _phase1 && lane != null) ...[
                Positioned(
                  key: const ValueKey('evidence-row'),
                  left: 8,
                  top: rowTop,
                  height: _rowH,
                  child: Row(
                    children: [
                      _slotBox(0, lane),
                      const SizedBox(width: 6),
                      _slotBox(1, lane),
                      const SizedBox(width: 6),
                      if (aiming && _run.slotsFull)
                        SizedBox(width: _sendW, height: 56, child: _SendButton(key: _sendKey, onTap: (o) => unawaited(_send(o))))
                      else
                        const SizedBox(width: _sendW),
                    ],
                  ),
                ),
                if (!_run.reportSent)
                  Positioned(
                    key: const ValueKey('live-view'),
                    right: 8,
                    top: rowTop,
                    width: _liveW,
                    height: _rowH,
                    child: IgnorePointer(child: _LiveView(world: lane, cam: _cam)),
                  ),
                Positioned(
                  key: const ValueKey('roll'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  height: _trayH,
                  child: _roll(lane),
                ),
              ],
              if (aiming)
                Positioned(
                  key: const ValueKey('zoom-rail'),
                  right: 6,
                  top: railTop,
                  width: _ZoomRail.width,
                  height: _railH,
                  child: _ZoomRail(cam: _cam, height: _railH, thumbKey: _zoomThumbKey, onDrag: _railDrag),
                ),
              if (aiming)
                Positioned(
                  key: const ValueKey('shutter'),
                  left: size.width / 2 - _shutterD / 2,
                  bottom: controlBottom,
                  width: _shutterD,
                  height: _shutterD,
                  child: _Shutter(key: _shutterKey, onTap: _shoot),
                ),
              if (_morning)
                Positioned.fill(
                  key: ValueKey('morning-$_morningTok'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: Duration(milliseconds: quiet ? 1 : 500),
                      builder: (_, v, child) => Opacity(opacity: v, child: child),
                      child: ColoredBox(
                        color: const Color(0xE6050A16),
                        child: Center(child: Text(M7TheftLines.morning, style: bangla(fontSize: 30, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
                      ),
                    ),
                  ),
                ),
              if (playing && _paperOpen && !coworkerOpen)
                Positioned.fill(
                  key: const ValueKey('paper'),
                  child: _OrderPaper(okKey: _paperOkKey, onOk: _readOrder, onMiss: _hints.missTap),
                ),
              if (playing && _phoneOpen && !coworkerOpen)
                Positioned.fill(
                  key: const ValueKey('phone'),
                  child: _PhoneCard(
                    callKey: _callKey,
                    onCall: _callShutdown,
                    onClose: () => setState(() => _phoneOpen = false),
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
              if (playing && _card == null && !_morning)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : guideBottom, onLeft: coworkerFromRight),
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
                  line: M7TheftLines.intro,
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
}

// ============================================================================
// Pieces
// ============================================================================

/// The worn PPE as small icons under the trainee's feet.
class _WornPainter extends CustomPainter {
  const _WornPainter({required this.worn});
  final Set<M7Gear> worn;

  @override
  void paint(Canvas c, Size size) {
    for (final g in M7Gear.values) {
      if (!worn.contains(g)) continue;
      c.save();
      c.translate(6 + g.index * 11.0, size.height / 2);
      c.scale(0.3);
      m7PaintGear(c, g, Offset.zero);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_WornPainter old) => old.worn.length != worn.length || !old.worn.containsAll(worn);
}

/// The phone's screen: what the frame holds, at its zoom.
class _LiveView extends StatelessWidget {
  const _LiveView({required this.world, required this.cam});
  final M7LanePainter world;
  final ValueListenable<M7Cam> cam;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: M7CropPainter(world: world, cam: cam)))),
          Positioned(
            right: 4,
            bottom: 3,
            child: ValueListenableBuilder<M7Cam>(
              valueListenable: cam,
              builder: (_, c, _) => Text('${c.zoom.toStringAsFixed(1)}x',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 3)])),
            ),
          ),
        ],
      ),
    );
  }
}

/// The zoom rail: drag the thumb up to zoom in (1x at the bottom, 5x at the
/// top).
class _ZoomRail extends StatelessWidget {
  const _ZoomRail({required this.cam, required this.height, required this.thumbKey, required this.onDrag});
  final ValueListenable<M7Cam> cam;
  final double height;
  final GlobalKey thumbKey;
  final ValueChanged<double> onDrag;

  static const width = 44.0;
  static const maxHeight = 196.0;
  static const thumb = 36.0;

  @override
  Widget build(BuildContext context) {
    const tick = TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 3)]);
    return Semantics(
      label: M7TheftLines.zoom,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerMove: (e) => onDrag(e.delta.dy),
        child: Stack(
          children: [
            Positioned(
              left: width / 2 - 3,
              top: thumb / 2,
              bottom: thumb / 2,
              width: 6,
              child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xAA0B1A33), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0x88FFFFFF)))),
            ),
            const Positioned(top: 0, left: 0, right: 0, child: Text('5x', textAlign: TextAlign.center, style: tick)),
            const Positioned(bottom: 0, left: 0, right: 0, child: Text('1x', textAlign: TextAlign.center, style: tick)),
            ValueListenableBuilder<M7Cam>(
              valueListenable: cam,
              builder: (_, c, _) {
                final f = ((c.zoom - m7ZoomMin) / (m7ZoomMax - m7ZoomMin)).clamp(0.0, 1.0);
                return Positioned(
                  left: (width - thumb) / 2,
                  top: (1 - f) * (height - thumb),
                  width: thumb,
                  height: thumb,
                  child: Container(
                    key: thumbKey,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF1F5F8F), width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
                    ),
                    child: Text(c.zoom.toStringAsFixed(1), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF14202B))),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({super.key, required this.onTap});
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M7TheftLines.shutter,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF1F5F8F), width: 4),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: const Center(child: Icon(Icons.photo_camera_rounded, size: 30, color: Color(0xFF14202B))),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({super.key, required this.onTap});
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M7TheftLines.send,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SlmColors.emerald500,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.send_rounded, size: 20, color: SlmColors.navy950),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(M7TheftLines.send, maxLines: 1, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.navy950)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The officer's order paper (one way forward: পড়েছি).
class _OrderPaper extends StatelessWidget {
  const _OrderPaper({required this.okKey, required this.onOk, required this.onMiss});
  final GlobalKey okKey;
  final VoidCallback onOk;
  final VoidCallback onMiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMiss,
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(M7TheftLines.paperTitle, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF14202B))),
                const Divider(height: 14, color: Color(0xFF90A4AE)),
                Text(M7TheftLines.paperBody, style: bangla(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35, color: const Color(0xFF14202B))),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(M7TheftLines.paperSign, style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF455A64))),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Semantics(
                    label: M7TheftLines.paperOk,
                    button: true,
                    child: GestureDetector(
                      key: okKey,
                      behavior: HitTestBehavior.opaque,
                      onTap: onOk,
                      child: Container(
                        width: 140,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF1F5F8F), borderRadius: BorderRadius.circular(14)),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(M7TheftLines.paperOk, maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                    ),
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

/// The crew phone: the control room's number and the শাটডাউন call.
class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.callKey, required this.onCall, required this.onClose});
  final GlobalKey callKey;
  final VoidCallback onCall;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 220,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF14202B),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFF37474F), width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle_rounded, size: 48, color: Color(0xFF90A4AE)),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M7TheftLines.phoneWho, maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: M7TheftLines.phoneCall,
                    button: true,
                    child: GestureDetector(
                      key: callKey,
                      behavior: HitTestBehavior.opaque,
                      onTap: onCall,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: SlmColors.emerald500, borderRadius: BorderRadius.circular(26)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.call_rounded, size: 22, color: SlmColors.navy950),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(M7TheftLines.phoneCall, maxLines: 1, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.navy950)),
                              ),
                            ),
                          ],
                        ),
                      ),
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
