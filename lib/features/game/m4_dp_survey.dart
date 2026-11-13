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
import 'm4_dp_survey_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_dp_survey_world.dart' show M4DpSurveyFault, M4DpSurveyFaultSide, M4DpSurveyGeo, M4DpSurveyLook;

// Lesson 4.7 "ডিপি (DP) স্ট্রাকচার ড্রেসিং", কাজ 1 "এলোমেলো স্ট্রাকচার" (pack
// do_4_7_a). The trainee walks a feeder and surveys three DP structures from
// the ground (no climbing: this is the survey, not the dressing). On each he
// marks what is untidy and writes the dressing list:
//   1. spot — tap the parts that need dressing. The lesson's list (point 2,
//      "ভালো ড্রেসিং-এর মূল উপাদান", and point 3, "সাধারণ ভুল"): a binding
//      wire's long tail, a tangled jumper (not a smooth U / C), a cross-arm out
//      of level, too little clearance (phase to phase, or phase to the pole's
//      body), LT cables hanging loose (not bunched and tied); and the myth's
//      case, two insulated LT wires touching. Half the plays deal one DP that
//      is tidy all over ("সব পরিপাটি" is the right list there).
//      A tidy part marked = a slip; the list written with a fault missed = a
//      slip (the guide rings what was missed).
//   2. order — a list with HT and LT work: HT first, then LT (pro tip 1).
//   3. the ◆ on the table → "কেন …?" (a reason dealt from what this DP had).
//   4. say no — the careless coworker once a play, on a DP with faults, after
//      the first mark (or at once when the list is written first: writing it
//      waits for him, [CoworkerMoment.holdForCoworker], and the press counts:
//      after him the list goes in exactly as it was pressed): the lesson's
//      myth 1 ("যা আছে চলছে তো, হাত দেওয়ার দরকার কী") or, once the touching
//      LT wires are on the list, myth 2 ("ওগুলো তো ইনসুলেটেড"). Listening = a
//      slip.
//   5. choose — the list is done: how will the dressing be done? Only after
//      shutdown, PTW, test and earth (the project's safety rule — the lesson
//      text does not say it: flagged). Dressing a live structure = deadly.
// Shared kit: guide first, full scene, corner guide, ◆ on the table, coworker
// once, mistake cards, freeze on the deadly choice, gesture hints (a sweep
// over every part while surveying, over the open cards while ordering). His
// new lines have no clip yet ([M4DpSurveyLines.recordLines]): silent with the
// caption held until the director records them.

// ============================================================================
// Content
// ============================================================================

/// What a reason card asks about: one of the faults on this DP, the order
/// (HT before LT), or why a tidy DP was called tidy.
enum M4DpSurveyTopic { tail, jumper, tilt, clearance, ltCables, touch, order, tidy }

M4DpSurveyTopic m4DpSurveyTopicOf(M4DpSurveyFault f) => M4DpSurveyTopic.values[f.index];

/// The steps of a play.
enum M4DpSurveyPhase { survey, order, why, plan, done }

@immutable
class M4DpSurveyStructure {
  const M4DpSurveyStructure({required this.look, required this.topic});
  final M4DpSurveyLook look;
  final M4DpSurveyTopic topic;

  Set<M4DpSurveyFault> get faults => look.faults;
  bool get tidy => faults.isEmpty;

  /// The list has HT and LT work: the order step.
  bool get needsOrder => faults.any((f) => f.isHt) && faults.any((f) => !f.isHt);
}

@immutable
class M4DpSurveyDeal {
  const M4DpSurveyDeal({required this.structures, required this.callAt, required this.insulated});
  final List<M4DpSurveyStructure> structures;

  /// The DP the careless coworker comes on (always one with faults).
  final int callAt;

  /// He may push the insulated-wire myth (only on a DP with LT wires
  /// touching: his line "তার একটু ছুঁয়ে আছে" must fit what is up there). He
  /// says it only once the touching wires are already on the list (his line
  /// never names a part the player has not found: [M4DpSurveyRun.aimCall]);
  /// otherwise "যা আছে চলছে তো".
  final bool insulated;
}

/// Three DPs: one to three faults each (half the plays: one DP tidy), the
/// looks, the plate numbers, the reason topics and the coworker, dealt fresh.
M4DpSurveyDeal dealM4DpSurvey(math.Random rng) {
  final tidyAt = rng.nextBool() ? rng.nextInt(3) : -1;
  final plate = 10 + rng.nextInt(80);
  final structures = <M4DpSurveyStructure>[];
  for (var i = 0; i < 3; i++) {
    final pool = [...M4DpSurveyFault.values]..shuffle(rng);
    final n = i == tidyAt ? 0 : const [1, 2, 2, 3][rng.nextInt(4)];
    final faults = pool.take(n).toSet();
    final look = M4DpSurveyLook(
      faults: faults,
      tailAt: rng.nextInt(3),
      jumperAt: rng.nextInt(3),
      bodyClear: rng.nextBool(),
      plate: plate + i,
    );
    final s0 = M4DpSurveyStructure(look: look, topic: M4DpSurveyTopic.tidy);
    final topics = faults.isEmpty
        ? const [M4DpSurveyTopic.tidy]
        : [for (final f in faults) m4DpSurveyTopicOf(f), if (s0.needsOrder) M4DpSurveyTopic.order];
    structures.add(M4DpSurveyStructure(look: look, topic: topics[rng.nextInt(topics.length)]));
  }
  final withFaults = [
    for (var i = 0; i < 3; i++)
      if (!structures[i].tidy) i,
  ];
  final callAt = withFaults[rng.nextInt(withFaults.length)];
  final f = structures[callAt].faults;
  final insulated = f.contains(M4DpSurveyFault.touch) && rng.nextBool();
  return M4DpSurveyDeal(structures: structures, callAt: callAt, insulated: insulated);
}

abstract final class M4DpSurveyLines {
  static const title = 'এলোমেলো স্ট্রাকচার';
  static const intro = 'ফিডারের তিনটে ডিপি নিচ থেকে দেখুন। যা এলোমেলো, ড্রেসিং লিস্টে তুলুন।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The task of each step (what the guide says and repeats when tapped).
  static const askSurvey = 'নিচ থেকে খুঁটিয়ে দেখুন — যা এলোমেলো, ছুঁয়ে দাগ দিন।';
  static const askOrder = 'লিস্টের কোন কাজ আগে, কোনটা পরে? ক্রমে ছুঁয়ে দিন।';
  static const askPlan = 'লিস্ট তৈরি। এই ড্রেসিং-এর কাজ কীভাবে হবে?';
  static const tasks = [askSurvey, askOrder, askPlan];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const tapPlan = ['কাজটা কীভাবে হবে — বেছে নিন।', 'ড্রেসিং-এর আগে কী কী লাগবে?'];
  static String ask(M4DpSurveyPhase p) => switch (p) {
    M4DpSurveyPhase.survey => askSurvey,
    M4DpSurveyPhase.order => askOrder,
    M4DpSurveyPhase.why || M4DpSurveyPhase.plan || M4DpSurveyPhase.done => askPlan,
  };

  // Labels a worker reads (buttons, his list).
  static const sceneLabel = 'ডিপি স্ট্রাকচার';
  static const submit = 'লিস্ট লিখুন';
  static const allTidy = 'সব পরিপাটি';
  static const listTitle = 'ড্রেসিং লিস্ট';
  static const listEmpty = '—';
  static const orderTitle = 'কাজের ক্রম';
  static String plateBn(M4DpSurveyLook l) => 'DP ${l.plate}';
  static String nameOf(M4DpSurveyFault f) => switch (f) {
    M4DpSurveyFault.tail => 'বাইন্ডিং তারের লম্বা লেজ',
    M4DpSurveyFault.jumper => 'জট পাকানো জাম্পার',
    M4DpSurveyFault.tilt => 'বাঁকা ক্রস-আর্ম',
    M4DpSurveyFault.clearance => 'জাম্পারে কম দূরত্ব',
    M4DpSurveyFault.ltCables => 'এলোমেলো ঝোলা এলটি কেবিল',
    M4DpSurveyFault.touch => 'ছুঁয়ে থাকা এলটি তার',
  };

  // The reasons (lesson 4.7): the right ones fit what this DP had; the wrong
  // ones are the lesson's myths and field excuses. The questions fit a part
  // the player listed and one the guide added after a miss ("উঠল", not
  // "তুললেন"), and the order after the guide put it right.
  static String why(M4DpSurveyTopic t) => switch (t) {
    M4DpSurveyTopic.tail => 'কেন বাইন্ডিং তারের লেজটা লিস্টে উঠল?',
    M4DpSurveyTopic.jumper => 'কেন জট পাকানো জাম্পারটা লিস্টে উঠল?',
    M4DpSurveyTopic.tilt => 'কেন বাঁকা ক্রস-আর্মটা লিস্টে উঠল?',
    M4DpSurveyTopic.clearance => 'কেন কাছাকাছি জাম্পারটা লিস্টে উঠল?',
    M4DpSurveyTopic.ltCables => 'কেন ঝোলা এলটি কেবিলগুলো লিস্টে উঠল?',
    M4DpSurveyTopic.touch => 'কেন ছুঁয়ে থাকা তার দুটো লিস্টে উঠল?',
    M4DpSurveyTopic.order => 'কেন ওপরের কাজগুলো আগে হবে?',
    M4DpSurveyTopic.tidy => 'কেন এই ডিপি-কে পরিপাটি বললেন?',
  };

  static const tailWhy = ['বাতাসে উড়ে বাড়তি লেজ পাশের তারে লাগে', 'বাড়তি বাইন্ডিং তার কেটে ফেলাই নিয়ম'];
  static const jumperWhy = ['জট পাকানো জাম্পার শর্ট সার্কিটের ফাঁদ', 'জাম্পার চাই মসৃণ U বা C আকৃতির বাঁক'];
  static const tiltWhy = ['ক্রস-আর্ম নিখুঁত অনুভূমিক রাখাই নিয়ম', 'সোজা, প্রতিসম স্ট্রাকচারে লোড সমান ভাগ হয়'];
  static const clearanceWhy = ['বাতাসে দুলে ছুঁয়ে গেলে শর্ট সার্কিট হয়', 'ফেজে-ফেজে, ফেজে-বডিতে নিরাপদ দূরত্ব চাই'];
  static const ltCablesWhy = ['ক্ল্যাম্প বা টাই দিয়ে বেঁধে নামানোই নিয়ম', 'গোছানো কেবিলে ফল্ট খোঁজা অনেক সহজ হয়'];
  static const touchWhy = ['ঘষা লেগে ইনসুলেশন ক্ষয়ে শর্ট সার্কিট হয়', 'ইনসুলেটেড হলেও তার ছুঁয়ে থাকা চলে না'];
  static const orderWhy = ['ড্রেসিং চলে ওপরের HT থেকে নিচের LT-তে', 'ওপর থেকে শুরু করে নিচে আসাই ভালো অভ্যাস'];
  static const tidyWhy = ['জাম্পার মসৃণ বাঁকে, দূরত্বও ঠিক আছে', 'কেবিল বাঁধা আছে, বাড়তি তারও কাটা আছে'];
  static List<String> whyRight(M4DpSurveyTopic t) => switch (t) {
    M4DpSurveyTopic.tail => tailWhy,
    M4DpSurveyTopic.jumper => jumperWhy,
    M4DpSurveyTopic.tilt => tiltWhy,
    M4DpSurveyTopic.clearance => clearanceWhy,
    M4DpSurveyTopic.ltCables => ltCablesWhy,
    M4DpSurveyTopic.touch => touchWhy,
    M4DpSurveyTopic.order => orderWhy,
    M4DpSurveyTopic.tidy => tidyWhy,
  };

  /// Wrong reasons for any DP (the lesson's myth 1 and field excuses). Some
  /// carry the words the right ones use ("শর্ট", "নিয়ম"), so no word is a tell.
  static const whyWrong = [
    'ড্রেসিং তো শুধু দেখতে ভালো লাগার জন্য',
    'লাইন চলছে, তাই হাত দেওয়ার দরকার নেই',
    'সুপারভাইজার দেখবে, তাই সাজিয়ে রাখি',
    'তাড়াতাড়ি সারতে হবে, মাপার সময় নেই',
    'শর্ট তো কালেভদ্রে হয়, ভয়ের কিছু নেই',
    'নিয়ম তো কাগজে থাকে, মাঠে চললেই হলো',
  ];

  /// Wrong reasons that name the same part as the question (so the right card
  /// is never the only one echoing it); one of them is dealt every time. Each
  /// is wrong as a whole (a myth or an excuse, no true rule in it), and
  /// together with [whyWrong] they carry every word the right cards use.
  static List<String> whyWrongTopic(M4DpSurveyTopic t) => switch (t) {
    M4DpSurveyTopic.tail => const ['বাতাসে উড়ে লেজ পাশের তারে লাগলেও ক্ষতি নেই', 'বাড়তি তার কেটে ফেলাই ভুল, বাঁধন ঢিলে হয়', 'বাইন্ডিং তারের লম্বা লেজ পরে কাজে লাগে'],
    M4DpSurveyTopic.jumper => const ['জট পাকানো জাম্পারে শর্ট সার্কিটের ভয় নেই', 'জাম্পার চাই টানটান, U বা C আকৃতির বাঁক বাড়তি', 'মসৃণ বাঁক বানানো সময় নষ্ট, ফাঁদ তো নেই'],
    M4DpSurveyTopic.tilt => const ['নিখুঁত অনুভূমিক রাখাই বাড়াবাড়ি, বাঁকাও চলে', 'বাঁকা স্ট্রাকচারেও লোড সমান ভাগ হয়ে যায়', 'ক্রস-আর্ম সোজা বা প্রতিসম না হলেও চলে'],
    M4DpSurveyTopic.clearance => const ['বাতাসে দুলে ছুঁয়ে গেলে শর্ট সার্কিট হয় না', 'ফেজে-ফেজে কাছাকাছি থাকলেও নিরাপদ দূরত্ব', 'ফেজে-বডিতে দূরত্ব চাই না, বডি তো আর্থ করা'],
    M4DpSurveyTopic.ltCables => const ['ক্ল্যাম্প বা টাই দিয়ে বেঁধে নামানোই ভুল', 'ঝোলা কেবিলে ফল্ট খোঁজা অনেক বেশি সহজ হয়', 'গোছানো হোক বা ঝোলা, কেবিলে কিছু যায় আসে না'],
    M4DpSurveyTopic.touch => const ['ঘষা লেগে ইনসুলেশন ক্ষয়ে না, মজবুত হয়', 'ইনসুলেটেড হলেও তার ছুঁয়ে থাকা চলে, ভয় নেই', 'ইনসুলেশন আছে, তাই শর্ট সার্কিটের ভয় নেই'],
    M4DpSurveyTopic.order => const ['নিচ থেকে শুরু করে ওপরে আসাই ভালো অভ্যাস', 'নিচের LT-তে কাজ কম, তাই ওপরের HT পরে', 'ড্রেসিং চলে যেকোনো ক্রমে, ওপর-নিচ সমান'],
    M4DpSurveyTopic.tidy => const ['জাম্পার মসৃণ বাঁকে কি না, দেখার সময় নেই', 'কেবিল বাঁধা আছে কি না, ঠিক বোঝার দরকার নেই', 'বাড়তি তারও কাটা হয়নি, দূরত্বও মাপিনি — চলবে'],
  };

  /// The general wrong reasons for [t]: for a tidy DP "no need to touch it"
  /// is not a wrong reason, so it is left out.
  static List<String> whyWrongGeneral(M4DpSurveyTopic t) => t == M4DpSurveyTopic.tidy ? [for (final w in whyWrong) if (w != whyWrong[1]) w] : whyWrong;

  /// Every wrong reason that can be dealt for [t].
  static List<String> whyWrongFor(M4DpSurveyTopic t) => [...whyWrongTopic(t), ...whyWrongGeneral(t)];

  // The plan: how the dressing on the list gets done.
  static const planRight = ['শাটডাউন, PTW, টেস্ট, আর্থ — তারপর ড্রেসিং', 'PTW নিয়ে, লাইন টেস্ট করে আর্থ দিয়ে তবেই'];
  static const planWrong = [
    'লাইন চালু রেখেই ড্রেসিংটা সেরে ফেলি',
    'রাবার গ্লাভস দিয়ে তবেই চালু লাইনে উঠি',
    'শাটডাউন লাগবে না, সাবধানে করে নিলেই হবে',
    'শাটডাউন পেলেই উঠি, টেস্ট-আর্থ লাগবে না',
    'PTW নিয়ে ভাবছি না, আগে উঠি তারপর দেখি',
  ];

  /// The careless coworker (lesson 4.7, myth 1).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerAsIs = CoworkerScript(
    line: 'যা আছে চলছে তো, হাত দেওয়ার দরকার কী!',
    exitLine: coworkerExit,
    right: ['না, এলোমেলো ড্রেসিং মানেই শর্টের ঝুঁকি', 'না, লিস্ট শেষ করব — এটা সুরক্ষার কাজ', 'চললেই হলো না, এগুলো ফল্টের ফাঁদ'],
    wrong: [
      'ঠিক, চলছে যখন, থাক যেমন আছে তেমন',
      'আচ্ছা, লিস্ট-টিস্ট বাদ দিয়ে দিই',
      'ঠিক আছে, ড্রেসিং তো শুধু দেখানো',
      'হ্যাঁ, বাকিটা আর দেখার দরকার নেই',
      'ঠিক বলেছ, লাইন চললেই সব ঠিক আছে',
    ],
    asks: ['ও বলছে হাত দেওয়ার দরকার নেই। আপনি?', 'লিস্ট থামাবেন, না শেষ করবেন?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// The careless coworker (lesson 4.7, myth 2), on a DP with wires touching
  /// or too close.
  static const coworkerInsulated = CoworkerScript(
    line: 'তার একটু ছুঁয়ে আছে তো কী, ওগুলো তো ইনসুলেটেড!',
    exitLine: coworkerExit,
    right: ['না, ঘষায় ইনসুলেশন ক্ষয়ে শর্ট হবে', 'না, ছুঁয়ে থাকা তার লিস্টে উঠবেই', 'ইনসুলেটেড হলেও দূরত্ব রাখতেই হবে'],
    wrong: [
      'ঠিক, ইনসুলেটেড তারে কিছু হয় না',
      'আচ্ছা, ছোঁয়াছুঁয়ি লিস্টে তুলব না',
      'হ্যাঁ, একটু ঘষায় কিছু যায় আসে না',
      'ঠিক আছে, এসব নিয়ে মাথা ঘামাব না',
      'ঠিক, তার তো মোড়া আছে, ভয় কীসের',
    ],
    asks: ['ও বলছে ইনসুলেটেড, তাই চলবে। আপনি?', 'ছুঁয়ে থাকা তার — ওর কথায়, না নিয়মে?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// New lines for him with no recorded clip yet (silent, caption held, until
  /// the director records them in his voice).
  static List<String> get recordLines => [coworkerAsIs.line, coworkerInsulated.line];

  static const callHeld = 'ঠিক! পরিপাটি ড্রেসিং সুরক্ষার কাজ — লিস্ট শেষ করুন।';
  /// He came as the list was being written: refused, the list goes in as it
  /// was pressed (neutral: never hints whether it was complete).
  static const callHeldList = 'ঠিক! চাপে নিয়ম ছাড়লেন না। এবার লিস্টটা দেখা যাক।';
  /// After a slip card (neutral: never "ঠিক আছে" about a part).
  static const putRight = 'চলুন, বাকিটা খুঁটিয়ে দেখুন।';
  static const allSet = 'তিনটে ডিপি, পুরো লিস্ট — একজন পাকা লাইনম্যানের চোখ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ওপর থেকে নিচে, প্রতিটা অংশ খুঁটিয়ে দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtTidy = 'পরিপাটি ডিপি চিনলেন';
  static const caughtOrder = 'ওপরের HT আগে, তারপর LT';
  static const caughtPlan = 'শাটডাউন, PTW, টেস্ট, আর্থ — তারপর ড্রেসিং';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

/// The reason cards for [t]: one right, one wrong that names the same part,
/// one general wrong — shuffled.
List<ChoiceOption> dealM4DpSurveyWhy(M4DpSurveyTopic t, math.Random rng) {
  final right = M4DpSurveyLines.whyRight(t);
  final topic = M4DpSurveyLines.whyWrongTopic(t);
  final general = M4DpSurveyLines.whyWrongGeneral(t);
  return [
    ChoiceOption(right[rng.nextInt(right.length)], true),
    ChoiceOption(topic[rng.nextInt(topic.length)], false),
    ChoiceOption(general[rng.nextInt(general.length)], false),
  ]..shuffle(rng);
}

abstract final class M4DpSurveyMistakes {
  static const _dir = 'assets/game/art/m4_dp_survey';

  static const missedTail = DoMistake(
    key: '4.7/m4_dp_survey/missed-binding-tail',
    textBn: 'বাইন্ডিং তারের বাড়তি লেজ চোখ এড়াল। বাতাসে উড়ে পাশের তারে লাগলেই শর্ট — বাড়তি অংশ কেটে ফেলতে হয়।',
    art: '$_dir/dp_tail.svg',
    lessonPoint: 1,
  );
  static const missedJumper = DoMistake(
    key: '4.7/m4_dp_survey/missed-tangled-jumper',
    textBn: 'জট পাকানো জাম্পার চোখ এড়াল। জাম্পার চাই মসৃণ, সুষম U বা C আকৃতির বাঁক — জট মানেই বিপদের লক্ষণ।',
    art: '$_dir/dp_jumper.svg',
    lessonPoint: 2,
  );
  static const missedTilt = DoMistake(
    key: '4.7/m4_dp_survey/missed-tilted-arm',
    textBn: 'বাঁকা ক্রস-আর্ম চোখ এড়াল। ক্রস-আর্ম আর ইনসুলেটর লাগাতে হয় নিখুঁত অনুভূমিক আর উল্লম্বভাবে।',
    art: '$_dir/dp_tilt.svg',
    lessonPoint: 1,
  );
  static const missedClearance = DoMistake(
    key: '4.7/m4_dp_survey/missed-clearance',
    textBn: 'জাম্পারের কম দূরত্ব চোখ এড়াল। ফেজে-ফেজে আর লাইভ অংশ থেকে পোলের কাঠামোয় নিরাপদ দূরত্ব চাই — নইলে বাতাসে দুলে শর্ট সার্কিট।',
    art: '$_dir/dp_clearance.svg',
    lessonPoint: 2,
  );
  static const missedLtCables = DoMistake(
    key: '4.7/m4_dp_survey/missed-lt-cables',
    textBn: 'এলোমেলো ঝোলা এলটি কেবিল চোখ এড়াল। কেবিল টাই বা ক্ল্যাম্প দিয়ে গুছিয়ে, বেঁধে নিচে নামাতে হয়।',
    art: '$_dir/dp_ltcables.svg',
    lessonPoint: 2,
  );
  static const missedTouch = DoMistake(
    key: '4.7/m4_dp_survey/missed-wires-touching',
    textBn: 'ছুঁয়ে থাকা এলটি তার চোখ এড়াল। ইনসুলেটেড হলেও ঘষায় ইনসুলেশন ক্ষয়ে শর্ট সার্কিট হয় — দূরত্ব রাখা বাধ্যতামূলক।',
    art: '$_dir/dp_touch.svg',
    lessonPoint: 0,
  );
  static DoMistake missed(M4DpSurveyFault f) => switch (f) {
    M4DpSurveyFault.tail => missedTail,
    M4DpSurveyFault.jumper => missedJumper,
    M4DpSurveyFault.tilt => missedTilt,
    M4DpSurveyFault.clearance => missedClearance,
    M4DpSurveyFault.ltCables => missedLtCables,
    M4DpSurveyFault.touch => missedTouch,
  };

  static const falseMark = DoMistake(
    key: '4.7/m4_dp_survey/tidy-part-marked',
    textBn: 'যা পরিপাটি, তা লিস্টে তোলার কিছু নেই — মসৃণ বাঁকের জাম্পার, সোজা ক্রস-আর্ম, বাঁধা কেবিল। দাগ দেওয়ার আগে খুঁটিয়ে মিলিয়ে নিন।',
    art: '$_dir/dp_tidy.svg',
    lessonPoint: 1,
  );

  /// Pro tip 1 (not a lesson point: "পাঠে দেখুন" opens the lesson from its start).
  static const bottomUp = DoMistake(
    key: '4.7/m4_dp_survey/lt-before-ht',
    textBn: 'নিচের এলটি কাজ আগে ধরলেন। ড্রেসিং শুরু হয় ওপরের HT অংশ থেকে, তারপর নিচের LT-তে।',
    art: '$_dir/dp_order.svg',
  );
  static const asIsMyth = DoMistake(
    key: '4.7/m4_dp_survey/myth-runs-anyway',
    textBn: 'ওর কথায় লিস্ট থামালেন। ড্রেসিং শুধু দেখানোর জন্য নয় — খারাপ ড্রেসিং থেকেই শর্ট সার্কিট আর ফল্ট হয়।',
    art: '$_dir/dp_jumper.svg',
    lessonPoint: 0,
  );
  static const insulatedMyth = DoMistake(
    key: '4.7/m4_dp_survey/myth-insulated',
    textBn: 'ওর কথা মেনে নিলেন। ইনসুলেটেড তার ছুঁয়ে থাকলেও ঘষায় আর আবহাওয়ায় ইনসুলেশন নষ্ট হয়ে শর্ট সার্কিট হয়।',
    art: '$_dir/dp_touch.svg',
    lessonPoint: 0,
  );

  /// The project's safety rule (shutdown, PTW, test, earth) — not in the
  /// lesson text: no lesson point.
  static const liveDressing = DoMistake(
    key: '4.7/m4_dp_survey/dressing-live',
    textBn: 'চালু লাইনে ড্রেসিং-এ হাত দিলেন। জাম্পার আর তার লাইভ — শাটডাউন, PTW, টেস্ট আর আর্থ ছাড়া স্ট্রাকচারে কাজ নয়।',
    art: '$_dir/dp_live.svg',
    deadly: true,
  );

  static List<DoMistake> get all => [
    missedTail,
    missedJumper,
    missedTilt,
    missedClearance,
    missedLtCables,
    missedTouch,
    falseMark,
    bottomUp,
    asIsMyth,
    insulatedMyth,
    liveDressing,
  ];
}

/// The play state (pure logic).
class M4DpSurveyRun {
  M4DpSurveyRun(this.deal);
  final M4DpSurveyDeal deal;
  int index = 0;
  M4DpSurveyPhase phase = M4DpSurveyPhase.survey;

  /// The parts on this DP's list, in the order they were marked (the missed
  /// ones are added after the list is written).
  final List<M4DpSurveyFault> marked = [];

  /// What the guide had to ring after the list was written.
  final Set<M4DpSurveyFault> missed = {};

  /// The dressing order picked so far.
  final List<M4DpSurveyFault> order = [];
  int slips = 0;
  int dpSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  int get count => deal.structures.length;
  bool get done => phase == M4DpSurveyPhase.done;
  bool get ended => done || deadly != null;
  M4DpSurveyStructure get structure => deal.structures[index.clamp(0, count - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get clean => dpSlips == 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    dpSlips++;
    return m;
  }

  /// A tap on part [f]: listed (true) if it is untidy; a tidy part marked is
  /// a slip. Already listed, or not surveying: nothing.
  (bool, DoMistake?) mark(M4DpSurveyFault f) {
    if (ended || phase != M4DpSurveyPhase.survey || marked.contains(f)) return (false, null);
    if (structure.faults.contains(f)) {
      marked.add(f);
      return (true, null);
    }
    return (false, _slip(M4DpSurveyMistakes.falseMark));
  }

  /// The list is written. A fault left off = one slip (the first missed, top
  /// down); the guide rings all the missed ones and the play goes on.
  DoMistake? submit() {
    if (ended || phase != M4DpSurveyPhase.survey) return null;
    final s = structure;
    final left = [
      for (final f in M4DpSurveyFault.values)
        if (s.faults.contains(f) && !marked.contains(f)) f,
    ];
    missed.addAll(left);
    marked.addAll(left);
    phase = s.needsOrder ? M4DpSurveyPhase.order : M4DpSurveyPhase.why;
    if (left.isNotEmpty) return _slip(M4DpSurveyMistakes.missed(left.first));
    if (s.tidy) {
      _tag(M4DpSurveyLines.caughtTidy);
    } else {
      for (final f in M4DpSurveyFault.values) {
        if (s.faults.contains(f)) _tag(M4DpSurveyLines.nameOf(f));
      }
    }
    return null;
  }

  /// The next item in the dressing order. An LT item while HT work is still
  /// unordered = a slip; the guide puts the order right (HT first).
  DoMistake? pick(M4DpSurveyFault f) {
    if (ended || phase != M4DpSurveyPhase.order || order.contains(f) || !structure.faults.contains(f)) return null;
    final faults = structure.faults;
    if (!f.isHt && faults.any((x) => x.isHt && !order.contains(x))) {
      order
        ..clear()
        ..addAll([
          for (final x in M4DpSurveyFault.values)
            if (faults.contains(x)) x,
        ]);
      phase = M4DpSurveyPhase.why;
      return _slip(M4DpSurveyMistakes.bottomUp);
    }
    order.add(f);
    if (order.length == faults.length) {
      phase = M4DpSurveyPhase.why;
      _tag(M4DpSurveyLines.caughtOrder);
    }
    return null;
  }

  /// Which myth he pushes: the insulated one only on an insulated deal, on
  /// his DP, with the touching wires already on the list (his line must not
  /// tell the player a fault he has not found). Set by [aimCall].
  bool callInsulated = false;

  /// Aim his myth at what is on the list now. The page calls it each time it
  /// checks whether he may come; nothing can be marked while he is on, so the
  /// last aim before he comes is the one he and [listen] use.
  void aimCall() {
    callInsulated = deal.insulated && index == deal.callAt && marked.contains(M4DpSurveyFault.touch);
  }

  /// Listened to the careless coworker (on this DP): a slip.
  DoMistake? listen() {
    if (ended) return null;
    return _slip(callInsulated ? M4DpSurveyMistakes.insulatedMyth : M4DpSurveyMistakes.asIsMyth);
  }

  /// How the dressing will be done: only the safe way is right; the rest =
  /// dressing a live structure (deadly).
  DoMistake? plan({required bool safe}) {
    if (ended || phase != M4DpSurveyPhase.plan) return null;
    if (!safe) return deadly = M4DpSurveyMistakes.liveDressing;
    _tag(M4DpSurveyLines.caughtPlan);
    phase = M4DpSurveyPhase.done;
    return null;
  }

  /// On to the next DP (after the reason), or to the plan after the last.
  void next() {
    if (ended || phase != M4DpSurveyPhase.why) return;
    marked.clear();
    missed.clear();
    order.clear();
    dpSlips = 0;
    if (index + 1 >= count) {
      phase = M4DpSurveyPhase.plan;
      return;
    }
    index++;
    phase = M4DpSurveyPhase.survey;
  }
}

/// The quick bonus (~85 % of a thorough play, rounded to 10 s). A DP: look
/// 4000 + two marks 2 × 2000 + the list 1500 + order (half the DPs) 1500 +
/// reason 8200 ≈ 19200 × 3 = 57600, + the coworker ≈ 9000 + the plan ≈ 6000
/// → 72600; 85 % ≈ 61700 → 60 s.
const kM4DpSurveyQuickMs = 60000;

@immutable
class M4DpSurveyPack {
  const M4DpSurveyPack({required this.id, required this.titleBn, this.quickMs = kM4DpSurveyQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4DpSurveyPack> m4DpSurveyPacks = {'do_4_7_a': M4DpSurveyPack(id: 'do_4_7_a', titleBn: M4DpSurveyLines.title)};

// ============================================================================
// Page
// ============================================================================

class M4DpSurveyPage extends StatefulWidget {
  const M4DpSurveyPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4DpSurveyPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4DpSurveyPage> createState() => _M4DpSurveyPageState();
}

class _M4DpSurveyPageState extends State<M4DpSurveyPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DpRunPage(
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

class _DpRunPage extends ConsumerStatefulWidget {
  const _DpRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4DpSurveyPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DpRunPage> createState() => _DpRunPageState();
}

class _DpRunPageState extends ConsumerState<_DpRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4DpSurveyRun _run = M4DpSurveyRun(dealM4DpSurvey(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  /// The list button was pressed while he was due: he came first; the press
  /// stands and the list goes in after him exactly as it was ([_writeList]).
  var _listHeld = false;
  Offset _listOrigin = Offset.zero;

  /// The order card's items (shuffled once per DP).
  List<M4DpSurveyFault> _orderItems = const [];

  // The plan deck.
  var _planOpen = false;
  List<ChoiceOption> _planOpts = const [];
  final Set<String> _planWrong = {};
  String? _planPicked;
  int _planAskN = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// Gesture hints (how to touch, never what): misses come from [_tapScene].
  final _hints = IdleHintController();
  final _orderKeys = <M4DpSurveyFault, GlobalKey>{};
  M4DpSurveyGeo _geoNow = M4DpSurveyGeo.forScene(780, 0);

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

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_planOpen;

  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    return design * (size.width / 360);
  }

  void _start() {
    _clock.start();
    _startDp();
  }

  void _startDp() {
    _listHeld = false;
    setState(() => _wake++);
    if (_run.index == _run.deal.callAt) scheduleCoworker();
    unawaited(_sayChain([M4DpSurveyLines.askSurvey]));
  }

  // --- 1. spot ---------------------------------------------------------------------
  Future<void> _tapScene(Offset p) async {
    if (!_canPlay) return;
    final zone = _run.phase == M4DpSurveyPhase.survey ? _geoNow.zoneAt(p) : null;
    if (zone == null) {
      // A tap on sky or ground (or on the scene while the order card waits).
      if (_run.phase == M4DpSurveyPhase.survey || _run.phase == M4DpSurveyPhase.order) _hints.missTap();
      return;
    }
    final (hit, m) = _run.mark(zone);
    if (m != null) {
      unawaited(_levelDelta(-10, _toGlobal(p), mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    if (!hit) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.wav', volume: 0.55);
    setState(() => _wake++);
  }

  // --- the list ----------------------------------------------------------------------
  Future<void> _submit(Offset origin) async {
    if (!_canPlay || _run.phase != M4DpSurveyPhase.survey) return;
    // Writing the list finishes his DP: a fast player still meets him first.
    // The press is a commitment: after him the list goes in as pressed (so
    // "সব পরিপাটি" cannot be used to see whether he comes).
    if (holdForCoworker()) {
      _listHeld = true;
      _listOrigin = origin;
      return;
    }
    await _writeList(origin);
  }

  /// The list goes in as it stands (the button, or the held press after him).
  Future<void> _writeList(Offset origin) async {
    _listHeld = false;
    if (_ended || _run.phase != M4DpSurveyPhase.survey) return;
    _hush();
    final m = _run.submit();
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/confirm.ogg', volume: 0.5);
    setState(() {
      _orderItems = [..._run.structure.faults]..shuffle(widget.rng);
      _wake++;
    });
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _goOn();
  }

  /// After a step (or a slip card): the order, or the reason.
  void _goOn() {
    switch (_run.phase) {
      case M4DpSurveyPhase.survey:
        unawaited(_sayChain([M4DpSurveyLines.askSurvey]));
      case M4DpSurveyPhase.order:
        unawaited(_sayChain([M4DpSurveyLines.askOrder]));
      case M4DpSurveyPhase.why:
        _dpDone();
      case M4DpSurveyPhase.plan || M4DpSurveyPhase.done:
        break;
    }
  }

  // --- 2. order ------------------------------------------------------------------------
  Future<void> _pick(M4DpSurveyFault f, Offset origin) async {
    if (!_canPlay || _run.phase != M4DpSurveyPhase.order) return;
    final m = _run.pick(f);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    if (_run.phase == M4DpSurveyPhase.why) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) _goOn();
    }
  }

  /// The DP's list is done: its ◆ on the table, then "কেন …?".
  void _dpDone() {
    final s = _run.structure;
    final idx = _run.index;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(
      askReason(
        deal: () => dealM4DpSurveyWhy(s.topic, widget.rng),
        question: M4DpSurveyLines.why(s.topic),
        stillValid: () => _run.index == idx && _run.phase == M4DpSurveyPhase.why && !_ended,
      ),
    );
  }

  void _next() {
    _run.next();
    if (_run.phase == M4DpSurveyPhase.plan) {
      _askPlan();
      return;
    }
    _startDp();
  }

  // --- 5. the plan -----------------------------------------------------------------------
  void _askPlan() {
    setState(() {
      _planOpts = dealChoices(M4DpSurveyLines.planRight, M4DpSurveyLines.planWrong, widget.rng);
      _planWrong.clear();
      _planPicked = null;
      _planOpen = true;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.wav', volume: 0.6);
    unawaited(_sayChain([M4DpSurveyLines.askPlan]));
  }

  Future<void> _pickPlan(ChoiceOption o, Offset origin) async {
    if (!_planOpen || _planPicked != null || _planWrong.isNotEmpty || _ended) return;
    _hush();
    setState(() {
      if (o.correct) {
        _planPicked = o.textBn;
      } else {
        _planWrong.add(o.textBn);
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final m = _run.plan(safe: o.correct);
    setState(() => _planOpen = false);
    if (m != null) {
      await _deadly(m, at: _geoNow.zoneOf(M4DpSurveyFault.jumper).center);
      return;
    }
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    await _levelDelta(10, origin, mood: GuideMood.glad);
    unawaited(_finish());
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
    unawaited(
      Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended && _run.index == idx && _run.phase == M4DpSurveyPhase.why) _next();
      }),
    );
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _run.callInsulated ? M4DpSurveyLines.coworkerInsulated : M4DpSurveyLines.coworkerAsIs;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.phase != M4DpSurveyPhase.survey) return null;
    // His myth fits what is on the list right now (the kit asks this just
    // before he comes; nothing is marked while he is on).
    _run.aimCall();
    // Never into the praise window; the held list (writing it waits for him)
    // lets him in even before the first mark.
    if (_intro || _busy || _card != null || tableBusy) return false;
    return _run.marked.isNotEmpty || coworkerHeld;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listen();
      if (m == null) return;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M4DpSurveyLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    if (_listHeld) {
      // The list was pressed as he came: it goes in as it was pressed (no
      // marks can be added in between), with a neutral word first.
      setState(() => _busy = true);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted || _ended) return;
      await _sayChain([M4DpSurveyLines.callHeldList]);
      if (!mounted || _ended) return;
      setState(() => _busy = false);
      await _writeList(_listOrigin);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    unawaited(_sayChain([M4DpSurveyLines.callHeld, M4DpSurveyLines.ask(_run.phase)]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
        ? M4DpSurveyLines.tapWhy[_nudgeN++ % M4DpSurveyLines.tapWhy.length]
        : _planOpen
        ? M4DpSurveyLines.tapPlan[_planAskN++ % M4DpSurveyLines.tapPlan.length]
        : _nudge.next(M4DpSurveyLines.ask(_run.phase));
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('dpsurvey/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The structure freezes grey; the arc flashes at [at] in colour; then
  /// near-miss or death.
  Offset? _deathAt;
  Future<void> _deadly(DoMistake m, {required Offset at}) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/accident.wav', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _deathAt = at;
    });
    await frozen.future;
    if (!mounted) return;
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('dpsurvey/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4DpSurveyLines.deadlyWord : M4DpSurveyLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        // The guide put it right; the DP goes on.
        if (_run.phase == M4DpSurveyPhase.survey && _listHeld) {
          // Listened to him after pressing the list: the press stands.
          unawaited(_writeList(_listOrigin));
        } else if (_run.phase == M4DpSurveyPhase.survey) {
          unawaited(_sayChain([M4DpSurveyLines.putRight, M4DpSurveyLines.askSurvey]));
        } else {
          _goOn();
        }
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
    await _say(
      !_run.passed ? M4DpSurveyLines.fail : (_quickBonus ? M4DpSurveyLines.quick : M4DpSurveyLines.allSet),
      mood: _run.passed ? GuideMood.celebrate : GuideMood.warn,
    );
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

  // --- gesture hints ---------------------------------------------------------
  /// Surveying: the hand glides over every part of the structure (tidy and
  /// untidy alike, top to bottom — never one part). Ordering: over the cards
  /// not yet picked (the last one is the only way forward: a tap).
  HintSpec? _hint() {
    switch (_run.phase) {
      case M4DpSurveyPhase.survey:
        final g = _geoNow;
        final zones = [for (final f in M4DpSurveyFault.values) g.zoneOf(f)]..sort((a, b) => a.top.compareTo(b.top));
        return HintSpec.sweep(zones, space: HintSpace.scene);
      case M4DpSurveyPhase.order:
        final open = [
          for (final f in _orderItems)
            if (!_run.order.contains(f)) _orderKeys.putIfAbsent(f, GlobalKey.new),
        ];
        if (open.isEmpty) return null;
        return open.length == 1 ? HintSpec.tapOn(open.single) : HintSpec.sweepOver(open);
      case M4DpSurveyPhase.why || M4DpSurveyPhase.plan || M4DpSurveyPhase.done:
        return null;
    }
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_mark != null && _run.passed) return LinemanMode.cheer;
    if (_run.phase == M4DpSurveyPhase.survey) return LinemanMode.point;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M4DpSurveyGeo.forScene(m.height, m.inset);
    final s = _run.structure;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = geo.trainee;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('yard'),
                child: RepaintBoundary(
                  child: CustomPaint(painter: M4DpSurveyWorldPainter(geo: geo, look: s.look)),
                ),
              ),
              Positioned.fill(
                key: const ValueKey('marks'),
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: M4DpSurveyMarksPainter(geo: geo, marked: List.of(_run.marked), missed: Set.of(_run.missed)),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('trainee'),
                left: tb.left,
                top: tb.top,
                width: tb.width,
                height: tb.height,
                child: IgnorePointer(
                  child: Transform.flip(
                    flipX: false,
                    child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Tap a part of the structure.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4DpSurveyLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => unawaited(_tapScene(d.localPosition)),
          ),
        ),
      ),
      // The arc, in colour over the grey structure.
      if (_freeze && _deathAt != null)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(
                painter: M4DpSurveyArcPainter(at: _deathAt!, v: 0.25 + 0.6 * v),
              ),
            ),
          ),
        ),
      // The walk to the next DP: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('dp-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
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
    final deckUp = reasonOpen || coworkerChoiceUp || _planOpen;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null;
    final phase = _run.phase;
    final hintWaiting = handsOn && !_busy && !tableBusy && (phase == M4DpSurveyPhase.survey || phase == M4DpSurveyPhase.order);
    final s = _run.structure;
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
              labels: M4DpSurveyLines.rounds,
              done: {
                for (var i = 0; i < _run.count; i++)
                  if (i < _run.index || phase == M4DpSurveyPhase.plan || phase == M4DpSurveyPhase.done) i,
              },
              current: phase == M4DpSurveyPhase.plan || phase == M4DpSurveyPhase.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintWaiting,
            hintKey: '${_run.index}-${phase.name}',
            hintController: _hints,
            overlays: [
              if (handsOn && phase == M4DpSurveyPhase.survey)
                Positioned(
                  key: ValueKey('list-${_run.index}'),
                  left: 56,
                  bottom: pad.bottom + 80,
                  child: IgnorePointer(
                    child: _ListChip(title: '${M4DpSurveyLines.listTitle} · ${M4DpSurveyLines.plateBn(s.look)}', items: _run.marked),
                  ),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && phase == M4DpSurveyPhase.survey)
                Positioned(
                  key: const ValueKey('hud-submit'),
                  left: 48,
                  right: 120,
                  bottom: pad.bottom + 14,
                  child: DoBigButton(
                    label: _run.marked.isEmpty ? M4DpSurveyLines.allTidy : M4DpSurveyLines.submit,
                    filled: true,
                    onTapUp: (d) => unawaited(_submit(d.globalPosition)),
                  ),
                ),
              if (handsOn && phase == M4DpSurveyPhase.order)
                _OrderCard(
                  key: ValueKey('order-${_run.index}'),
                  items: _orderItems,
                  itemKeys: {for (final f in _orderItems) f: _orderKeys.putIfAbsent(f, GlobalKey.new)},
                  picked: _run.order,
                  quiet: quiet,
                  onPick: (f, o) => unawaited(_pick(f, o)),
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
                        : _planOpen
                        ? ChoiceDeck(
                            key: const ValueKey('plan-deck'),
                            options: _planOpts,
                            onPick: (o, origin) => unawaited(_pickPlan(o, origin)),
                            quiet: quiet,
                            muted: _muted,
                            wrong: _planWrong,
                            picked: _planPicked,
                          )
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  line: M4DpSurveyLines.intro,
                  alarm: null,
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _start();
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

/// His dressing list for this DP: what he has marked, numbered.
class _ListChip extends StatelessWidget {
  const _ListChip({required this.title, required this.items});
  final String title;
  final List<M4DpSurveyFault> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xF2F7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A)),
          ),
          if (items.isEmpty)
            Text(
              M4DpSurveyLines.listEmpty,
              style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF2B2416)),
            ),
          for (final (i, f) in items.indexed)
            Text(
              '${i + 1}. ${M4DpSurveyLines.nameOf(f)}',
              style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.3, color: const Color(0xFF2B2416)),
            ),
        ],
      ),
    );
  }
}

/// The order: the list's items as cards; tap them in the dressing order.
class _OrderCard extends StatelessWidget {
  const _OrderCard({super.key, required this.items, required this.itemKeys, required this.picked, required this.quiet, required this.onPick});
  final List<M4DpSurveyFault> items;

  /// Where each card is on screen (the sweep hint).
  final Map<M4DpSurveyFault, GlobalKey> itemKeys;
  final List<M4DpSurveyFault> picked;
  final bool quiet;
  final void Function(M4DpSurveyFault f, Offset origin) onPick;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Positioned(
      left: 20,
      right: 20,
      bottom: pad.bottom + 236,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(
          scale: 0.9 + 0.1 * v,
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xF0F7F1E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8A7A55), width: 1.6),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                M4DpSurveyLines.orderTitle,
                textAlign: TextAlign.center,
                style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF6B5B3A)),
              ),
              const SizedBox(height: 6),
              for (final f in items)
                Padding(
                  key: itemKeys[f],
                  padding: const EdgeInsets.only(top: 6),
                  child: _OrderItem(
                    key: ValueKey('order-${f.name}'),
                    label: M4DpSurveyLines.nameOf(f),
                    n: picked.contains(f) ? picked.indexOf(f) + 1 : null,
                    onTapUp: (d) => onPick(f, d.globalPosition),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({super.key, required this.label, required this.n, required this.onTapUp});
  final String label;
  final int? n;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final on = n != null;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: on ? null : onTapUp,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF1F4A33) : const Color(0xFF1C2E4A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (on ? SlmColors.success : SlmColors.gold300).withValues(alpha: 0.9), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: on ? SlmColors.success : const Color(0x33FFFFFF)),
                child: Text(
                  on ? '$n' : '',
                  style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
