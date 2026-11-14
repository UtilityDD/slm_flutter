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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_trip_call_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm5_trip_call_world.dart' show M5TripArea, M5TripSuspect, M5TripSky, M5TripGeo;

// Lesson 5.1 "'লাইন ট্রিপ করেছে'—প্রথম কাজ কী?", কাজ 1 "কন্ট্রোল রুমের ফোন"
// (pack do_5_1_a, engineType m5_trip_call). The section office's duty desk at
// a trip: two calls from the control room per play (two of the lesson's three
// examples, in random order), a time card between them, then the team
// briefing at the van.
//
// Each call:
//  1. The phone rings — drag the handset up. The operator: "11 কেভি ফিডার
//     নম্বর N ট্রিপ করেছে, লাইন বন্ধ আছে।"
//  2. Seven question tiles (shuffled); the notepad copies every answer word
//     for word. Two dealt topics answer vaguely first; a second tap on the
//     same tile probes ("ওভারকারেন্ট না আর্থ ফল্ট?") — nothing on the tile or
//     the note marks a vague answer. Tapping a tile again after its clear
//     answer is needless ("আগেই তো বললাম — …"): the step loses its thorough
//     bonus and the play its quick bonus, so "tap everything twice" never
//     stands in for spotting the vague answers.
//  3. Drag the handset down. Any of the lesson's four questions (point 1:
//     the trip's nature — instant or not, overcurrent or earth fault; the
//     recloser; the weather; customers' reports) or the logbook (pro tip 1)
//     unasked or still vague = a slip, the call goes on ("হ্যালো? আর কিছু জানতে চান?"). Complete → ◆ →
//     "ফোন রাখার আগে এত প্রশ্ন কেন করলেন?" (the first call; the second pays
//     straight away).
//  4. Drag the red pin onto a suspect card (point 3's examples: storm + earth
//     fault → a branch; clear day + overcurrent → a bird or animal; repeated
//     recloses then the final trip → wires clashing) → ◆ → "কোন সূত্রে এই
//     সন্দেহ?".
//  5. Drag the van magnet onto the start section (storm + earth fault → the
//     trees; otherwise the section the customers or the logbook name — the
//     two never conflict) → ◆ → "পেট্রোলিং এখান থেকে কেন শুরু?".
// Then the team briefing deck (point 2: the information and the plan — and
// the PTW, isolation and earthing before anyone touches or climbs the line;
// ruling M5-3: never a PTW as a must for ground patrol), then the pass panel.
//
// The careless coworker once a play, in his pre-dealt call, on the first
// hang-up drag (the hang-up is mandatory, so he can not be outrun): lesson
// myth 2 word for word. The operator's "ফল্ট কোথায় বুঝতে পারছি না।" stands
// in the bubble by the phone as he cuts in. Refuse him (input waits until the
// interrupted hang-up resumes) and the hang-up goes on into the check; listen ("একবার
// চার্জ করে দেখুন") and the locked-out feeder is charged onto its fault =
// deadly (module rule R8 / ruling M5-1, raised from the designer's slip): the
// scene freezes grey, then the flash and fire at the fault's section on the
// map in colour.
// Slips: hanging up with a lesson question unasked or vague (one per try), a
// wrong suspect, a wrong start section, a wrong briefing card. Three slips
// strike the level out.
//
// Built on the shared kit (GAME_LEVEL_PLAYBOOK.md): guide first, full scene
// (m5_trip_call_world.dart), corner guide, ◆ on the table → "কেন …?", the
// two-beat coworker, gesture hints (a drag nudge on the handset / pin / van in
// a generic direction, a sweep over every tile — never the answer). Voice: the
// guide and the operator by device TTS (the operator's words also stand in a
// bubble by the phone and in the notepad); the coworker's push in his
// recorded voice (silent with his caption held until it is recorded).

// ============================================================================
// Content
// ============================================================================

/// The lesson's three examples (point 3).
enum M5TripCase { storm, clear, recloses }

/// The question tiles.
enum M5TripTopic { how, relay, recloser, weather, customer, logbook, opinion }

/// Where a call is.
enum M5TripStage { ring, talk, pin, van, brief, done }

/// Where the location clue comes from (never conflicting).
enum M5TripClue { none, customer, logbook, both }

/// The answer the operator gives to a tile tap.
enum M5TripReply { first, vague, probe, again }

/// What must be on the notepad before the hang-up: the lesson's four
/// questions (point 1; the first one asks two things — instant or not, and
/// overcurrent or earth fault) and pro tip 1, the logbook ('লগবুক দেখুন').
/// The same set every deal, so being required never hints where the clue is.
const m5TripRequired = {M5TripTopic.how, M5TripTopic.relay, M5TripTopic.recloser, M5TripTopic.weather, M5TripTopic.customer, M5TripTopic.logbook};

abstract final class M5TripLines {
  static const title = 'কন্ট্রোল রুমের ফোন';
  static const intro = 'ফিডার ট্রিপ করেছে, চারদিক অন্ধকার! মাঠে নামার আগে কন্ট্রোল রুম থেকে খবর নিন।';
  static const rounds = ['প্রথম কল', 'দ্বিতীয় কল', 'ব্রিফিং'];

  // The guide's task now (tap him: the same task, a different way).
  static const askPhone = 'ফোন বাজছে — রিসিভার তুলুন।';
  static const askAsk = 'অপারেটরের কাছ থেকে সব খবর নিন।';
  static const askPin = 'সন্দেহের ছবিতে লাল পিন গাঁথুন।';
  static const askVan = 'পেট্রোলিং কোথা থেকে শুরু? গাড়িটা সেখানে রাখুন।';
  static const askBrief = 'বেরোনোর আগে টিমকে কী বলবেন?';
  static const tasks = [askPhone, askAsk, askPin, askVan, askBrief];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ডিউটি ডেস্ক';
  static const handset = 'রিসিভার';
  static const pin = 'লাল পিন';
  static const van = 'গাড়ি';
  static const nextCall = 'পরের কল';

  /// The tiles (the trainee's questions) and their probes.
  static const tile = <M5TripTopic, String>{
    M5TripTopic.how: 'ট্রিপ কীভাবে হলো?',
    M5TripTopic.relay: 'রিলে কী দেখাল?',
    M5TripTopic.recloser: 'রিক্লোজার?',
    M5TripTopic.weather: 'আবহাওয়া?',
    M5TripTopic.customer: 'গ্রাহকের খবর?',
    M5TripTopic.logbook: 'লগবুক?',
    M5TripTopic.opinion: 'আপনার কী মনে হয়?',
  };
  static const probe = <M5TripTopic, String>{
    M5TripTopic.how: 'তৎক্ষণাৎ, নাকি কিছু সময় পর?',
    M5TripTopic.relay: 'ওভারকারেন্ট না আর্থ ফল্ট?',
    M5TripTopic.recloser: 'কতবার চেষ্টা করেছিল?',
    M5TripTopic.weather: 'ঝড়, বৃষ্টি বা বাজ ছিল কি?',
    M5TripTopic.customer: 'কোন এলাকা থেকে? কী শুনেছে বা দেখেছে?',
    M5TripTopic.logbook: 'কোন সেকশনে আগে বারবার ফল্ট হয়েছে?',
  };

  /// The notepad's labels.
  static const note = <M5TripTopic, String>{
    M5TripTopic.how: 'ট্রিপ',
    M5TripTopic.relay: 'রিলে',
    M5TripTopic.recloser: 'রিক্লোজার',
    M5TripTopic.weather: 'আবহাওয়া',
    M5TripTopic.customer: 'গ্রাহক',
    M5TripTopic.logbook: 'লগবুক',
    M5TripTopic.opinion: 'অপারেটর',
  };

  /// The suspect cards' labels (a worker's words; the cards show photos).
  static const suspect = <M5TripSuspect, String>{
    M5TripSuspect.branch: 'গাছের ডাল',
    M5TripSuspect.bird: 'পাখি / জন্তু',
    M5TripSuspect.clash: 'তারে টক্কর',
  };

  /// Section names on a feeder map (dealt per call).
  static const areaNames = <M5TripArea, List<String>>{
    M5TripArea.trees: ['বাঁশবাগান', 'আমবাগান', 'শালবন'],
    M5TripArea.river: ['নদীঘাট', 'খালপাড়', 'চরপাড়া'],
    M5TripArea.market: ['হাটতলা', 'বাজারপাড়া', 'নতুন বাজার'],
    M5TripArea.fields: ['মাঠপাড়া', 'ধানখেত', 'বিলপাড়'],
  };

  // --- the operator (device TTS; written for the scene, the topics are the lesson's) ---
  static String opening(int feeder) => '11 কেভি ফিডার নম্বর $feeder ট্রিপ করেছে, লাইন বন্ধ আছে।';
  static const lost = 'ফল্ট কোথায় বুঝতে পারছি না।';
  static const hello = 'হ্যালো? আর কিছু জানতে চান?';

  /// A tile tapped again after its clear answer: the operator repeats it,
  /// a little put out (the notes already have it word for word).
  static String again(String answer) => 'আগেই তো বললাম — $answer';

  static const vague = <M5TripTopic, List<String>>{
    M5TripTopic.how: ['ব্রেকার পড়ে গেছে, ট্রিপ করেছে।', 'হ্যাঁ, ট্রিপ করেছে, লাইন বন্ধ।'],
    M5TripTopic.relay: ['রিলে পড়েছে।', 'রিলের ফ্ল্যাগ উঠেছে।'],
    M5TripTopic.recloser: ['রিক্লোজার চলেছিল।', 'রিক্লোজার চেষ্টা করেছিল।'],
    M5TripTopic.weather: ['বাইরেটা ঠিক খেয়াল করিনি।', 'আবহাওয়া? তখন অত দেখিনি।'],
    M5TripTopic.customer: ['কয়েকজন ফোন করেছে।', 'গ্রাহকের ফোন আসছে।'],
    M5TripTopic.logbook: ['লগবুকে পুরনো রেকর্ড আছে।', 'হ্যাঁ, লগবুক তো আছেই।'],
  };
  static const howInstant = ['তৎক্ষণাৎ ট্রিপ করেছে।', 'সঙ্গে সঙ্গে — তৎক্ষণাৎ ট্রিপ।'];
  static const howDelayed = ['তৎক্ষণাৎ নয়, কিছু সময় পর ট্রিপ।', 'কিছু সময় চলার পর ট্রিপ করেছে।'];
  static const relayEarth = ['আর্থ ফল্ট দেখাচ্ছে।', 'রিলেতে আর্থ ফল্ট।'];
  static const relayOver = ['ওভারকারেন্ট দেখাচ্ছে।', 'রিলেতে ওভারকারেন্ট।'];
  static const recloseOnce = ['একবার চেষ্টা করেই লক-আউট।', 'একবার চালু করে টেকেনি, লক-আউট।'];
  static List<String> recloseMany(int n) => ['$n বার চালু হয়ে আবার ট্রিপ, শেষে লক-আউট।', 'বারবার — $n বার চেষ্টা, তারপর লক-আউট।'];
  static const weatherStorm = ['প্রবল বাতাস আর বৃষ্টি, ঝড় চলছিল।', 'ঝড়-বৃষ্টি চলছিল, জোর বাতাস।'];
  static const weatherClear = ['পরিষ্কার দিন, রোদ ঝলমলে।', 'আকাশ পরিষ্কার, ঝড়-বৃষ্টি নেই।'];
  static const weatherWindy = ['জোর বাতাস ছিল, বৃষ্টি নেই।', 'বৃষ্টি নেই, তবে খুব বাতাস।'];
  static const heardWhat = ['বিস্ফোরণের শব্দ শুনেছেন', 'আলোর ঝলকানি দেখেছেন', 'শব্দ শুনেছেন, ঝলকানিও দেখেছেন'];
  static List<String> customerFrom(String name, String what) => ['$name থেকে ফোন: $what।', '$name এলাকার গ্রাহকেরা $what।'];
  static const customerNone = ['শব্দ বা ঝলকানির কোনো খবর আসেনি।', 'গ্রাহকেরা শুধু বলছেন আলো নেই।'];
  static List<String> logbookFrom(String name) => ['লগবুকে আছে: $name সেকশনে বারবার ফল্ট।', 'আগেও $name সেকশনে বারবার ফল্ট হয়েছে।'];
  static const logbookNone = ['লগবুকে বারবার ফল্টের কোনো সেকশন নেই।', 'এই ফিডারে আগে তেমন কিছু নেই।'];
  static const opinion = ['লক-আউট হয়ে আছে, ফল্ট মনে হয় স্থায়ী।', 'লাইন আর ওঠেনি — স্থায়ী ফল্টই মনে হচ্ছে।'];

  // --- the reasons (the right ones fit what was done; the wrong ones are
  // field excuses and the lesson's myths). 39–50 letters. ---
  static const askWhyQ = 'ফোন রাখার আগে এত প্রশ্ন কেন করলেন?';
  static const pinWhyQ = 'কোন সূত্রে এই সন্দেহ?';
  static const vanWhyQ = 'পেট্রোলিং এখান থেকে কেন শুরু?';
  static const askWhy = [
    'ফিল্ডে যাওয়ার আগে যত বেশি তথ্য, তত ভালো অনুমান',
    'প্রতিটি তথ্যই সূত্র, তাতে খোঁজার এলাকা ছোট হয়',
    'অস্পষ্ট উত্তরে অনুমান ভুল হয়, তাই স্পষ্ট করে নিই',
  ];
  static const pinWhy = <M5TripCase, List<String>>{
    M5TripCase.storm: ['ঝড়-বৃষ্টি আর আর্থ ফল্ট, এ তো ডাল পড়ার লক্ষণ', 'প্রবল বাতাস, বৃষ্টি, আর্থ ফল্ট: সম্ভবত গাছের ডাল'],
    M5TripCase.clear: ['পরিষ্কার দিনে ওভারকারেন্ট: পাখি বা জন্তুর শর্ট', 'আকাশ পরিষ্কার, তবু ওভারকারেন্ট: সম্ভবত পাখির কাজ'],
    M5TripCase.recloses: ['বারবার রিক্লোজ, শেষে লক-আউট: বাতাসে তারে টক্কর', 'অস্থায়ী ফল্ট বারবার ফিরে স্থায়ী হলো: তারে টক্কর'],
  };
  static const vanTrees = ['ঝড়ে তৎক্ষণাৎ ট্রিপ, তাই আগে গাছপালার এলাকা দেখি', 'ঝড় আর আর্থ ফল্টে খোঁজা শুরু গাছপালার এলাকায়'];
  static const vanCustomer = ['এই এলাকা থেকেই শব্দ বা ঝলকানির খবর এসেছে', 'গ্রাহক যেখানে শব্দ বা ঝলকানি পেয়েছেন, শুরু সেখানে'];
  static const vanLogbook = ['লগবুক বলছে, এই সেকশনেই বারবার ফল্ট হয়েছে', 'যে সেকশনে বারবার ফল্ট, সমস্যা সম্ভবত সেখানেই'];
  static const myths = [
    'ফোনে কথা বাড়ালে অপারেটর খুশি থাকেন, তাই',
    'লাইন তো ট্রিপ করেই আছে, মানে ওটা এখন ডেড',
    'একবার চার্জ করে দেখলেই ফল্ট ধরা পড়ে যায়',
    'পুরো লাইন হেঁটে দেখলেই হবে, অনুমান লাগে না',
    'রিপোর্টে লিখতে হয়, তাই প্রশ্ন করে রাখলাম',
    'যেটা অফিসের সবচেয়ে কাছে, সেখান থেকে খোঁজা সহজ',
    'আন্দাজেই চলি, কারও কাছে তথ্য নেওয়া লাগে না',
  ];
  static List<String> get allWhyRight => [...askWhy, for (final l in pinWhy.values) ...l, ...vanTrees, ...vanCustomer, ...vanLogbook];

  /// The right reasons for the start section of [c].
  static List<String> vanWhy(M5TripCall c) => c.kase == M5TripCase.storm
      ? vanTrees
      : [
          if (c.clue == M5TripClue.customer || c.clue == M5TripClue.both) ...vanCustomer,
          if (c.clue == M5TripClue.logbook || c.clue == M5TripClue.both) ...vanLogbook,
        ];

  // --- the team briefing at the van (point 2) ---
  static const briefRight = [
    'খবর, সন্দেহ, শুরু; হাত দেওয়ার আগে পারমিট, আইসোলেট, আর্থিং',
    'যা জানলাম, কোথা থেকে শুরু; হাত দেওয়ার আগে পারমিট ও আর্থিং',
  ];
  static const briefWrong = [
    'লাইন তো ট্রিপ করেই আছে, পারমিট ছাড়াই দ্রুত কাজ সারি',
    'যে যার মতো খুঁজুক, পরিকল্পনা লাগবে না, চলো বেরোই',
    'আগে একবার লাইন চার্জ করিয়ে দেখি, তারপর খোঁজা শুরু',
    'ট্রিপ মানে ডেড, আর্থিং ছাড়াই উঠে দেখে নেব একবার',
    'পুরো লাইন অন্ধের মতো খুঁজি, যা পাই সেটাই ফল্ট',
  ];

  /// The careless coworker: lesson 5.1 myth 2, word for word.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'কন্ট্রোল রুম বলছে ফল্ট খুঁজে পাওয়া যাচ্ছে না, লাইনটা একবার চার্জ করে দেখাই যাক কী হয়।',
    exitLine: coworkerExit,
    right: [
      'না, স্থায়ী ফল্টে চার্জ দিলে আগুন লাগতে পারে',
      'চার্জ করে নয়, আগে পেট্রোলিং করে ফল্ট খুঁজি',
      'না, বারবার চালু করলে যন্ত্রপাতি আরও নষ্ট হবে',
    ],
    wrong: [
      'ঠিক আছে, একবার চার্জ করে দেখুন কী হয়',
      'একবার চালু করুন, টিকে গেলে খোঁজা লাগবে না',
      'চার্জ দিন, ফল্ট থাকলে আবার ট্রিপ করবে',
      'হ্যাঁ, লাইনটা একবার চালিয়ে দেখি কী হয়',
      'একবার চার্জ দিন, ফল্টের জায়গা শব্দে বুঝব',
    ],
    asks: ['অপারেটরকে কী বলবেন?', 'ও বলছে লাইন চার্জ করাতে। কী বলবেন?', 'চার্জ করে ফল্ট খুঁজবেন?'],
  );

  static const callHeld = 'ঠিক! ফল্ট খুঁজতে লাইন চার্জ নয়।';
  static const askPaid = 'ঠিক! ফোন রাখার আগে সব খবর।';
  static const briefPaid = 'চমৎকার! খবর, পরিকল্পনা — আর হাত দেওয়ার আগে পারমিট (PTW)।';
  static const allSet = 'খবর নিয়ে, অনুমান করে, ঠিক জায়গা থেকে — নিরাপদে পেট্রোলিং।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ফোন রাখার আগে সব খবর, তারপর অনুমান।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtAsk = 'ফোন রাখার আগে সব খবর নিয়েছেন';
  static const caughtProbe = 'অস্পষ্ট উত্তরে আবার জিজ্ঞেস করেছেন';
  static const caughtSuspect = 'সূত্র মিলিয়ে ঠিক সন্দেহ';
  static const caughtStart = 'ঠিক জায়গা থেকে পেট্রোলিং শুরু';
  static const caughtCall = 'চার্জ করে ফল্ট খোঁজায় “না” বলেছেন';
  static const caughtBrief = 'বেরোনোর আগে টিম ব্রিফিং; হাত দেওয়ার আগে পারমিট (PTW)';

  /// The operator's clear answer to [t] in [c].
  static String clearAnswer(M5TripCall c, M5TripTopic t) {
    String pick(List<String> l) => l[(c.phrase + t.index) % l.length];
    final name = c.names[c.clueArea]!;
    return switch (t) {
      M5TripTopic.how => pick(c.instant ? howInstant : howDelayed),
      M5TripTopic.relay => pick(c.kase == M5TripCase.storm ? relayEarth : relayOver),
      M5TripTopic.recloser => pick(c.shots > 1 ? recloseMany(c.shots) : recloseOnce),
      M5TripTopic.weather => pick(switch (c.kase) {
          M5TripCase.storm => weatherStorm,
          M5TripCase.clear => weatherClear,
          M5TripCase.recloses => weatherWindy,
        }),
      M5TripTopic.customer =>
        pick(c.clue == M5TripClue.customer || c.clue == M5TripClue.both ? customerFrom(name, heardWhat[c.heard]) : customerNone),
      M5TripTopic.logbook => pick(c.clue == M5TripClue.logbook || c.clue == M5TripClue.both ? logbookFrom(name) : logbookNone),
      M5TripTopic.opinion => pick(opinion),
    };
  }

  /// The operator's vague first answer to [t] (only the dealt topics).
  static String vagueAnswer(M5TripCall c, M5TripTopic t) => vague[t]![(c.phrase + t.index) % vague[t]!.length];
}

abstract final class M5TripMistakes {
  static const _dir = 'assets/game/art/m5_trip_call';

  static const unasked = DoMistake(
    key: '5.1/m5_trip_call/unasked',
    textBn: 'ফোন রাখার আগে সব খবর চাই: ট্রিপের প্রকৃতি (তৎক্ষণাৎ কি না, ওভারকারেন্ট না আর্থ ফল্ট), রিক্লোজার কতবার, আবহাওয়া, গ্রাহকের খবর, আর লগবুক।',
    art: '$_dir/notes.svg',
    lessonPoint: 0,
  );
  static const vagueKept = DoMistake(
    key: '5.1/m5_trip_call/vague',
    textBn: 'অস্পষ্ট উত্তর খাতায় রেখে ফোন রাখবেন না — আবার জিজ্ঞেস করে স্পষ্ট করে নিন। প্রতিটি তথ্যই সূত্র।',
    art: '$_dir/vague.svg',
    lessonPoint: 0,
  );
  static const suspectStorm = DoMistake(
    key: '5.1/m5_trip_call/suspect-storm',
    textBn: 'প্রবল বাতাস আর বৃষ্টি + আর্থ ফল্ট = সম্ভবত গাছের ডাল ভেঙে পড়েছে বা ইনসুলেটর পাংচার।',
    art: '$_dir/branch.svg',
    lessonPoint: 2,
  );
  static const suspectClear = DoMistake(
    key: '5.1/m5_trip_call/suspect-clear',
    textBn: 'পরিষ্কার দিন + ওভারকারেন্ট = সম্ভবত পাখি বা জন্তুর শর্ট সার্কিট, অথবা জাম্পার বা কানেক্টর গলে গেছে।',
    art: '$_dir/bird.svg',
    lessonPoint: 2,
  );
  static const suspectRecloses = DoMistake(
    key: '5.1/m5_trip_call/suspect-recloses',
    textBn: 'বারবার অটো-রিক্লোজ হয়ে ফাইনাল ট্রিপ = সম্ভবত অস্থায়ী ফল্ট (বাতাসে দুটি তারে টক্কর), যা পরে স্থায়ী হয়েছে।',
    art: '$_dir/clash.svg',
    lessonPoint: 2,
  );
  static const startTrees = DoMistake(
    key: '5.1/m5_trip_call/start-trees',
    textBn: 'ঝড়ের সময় তৎক্ষণাৎ ট্রিপ আর আর্থ ফল্ট = সম্ভবত গাছ বা ডালপালা। পেট্রোলিং শুরু হোক গাছপালার এলাকা থেকে।',
    art: '$_dir/start_trees.svg',
    lessonPoint: 2,
  );
  static const startReport = DoMistake(
    key: '5.1/m5_trip_call/start-report',
    textBn: 'যে এলাকা থেকে শব্দ বা ঝলকানির খবর, বা লগবুকে যে সেকশনে বারবার ফল্ট — খোঁজা শুরু সেখান থেকে।',
    art: '$_dir/start_report.svg',
    lessonPoint: 0,
  );
  static const brief = DoMistake(
    key: '5.1/m5_trip_call/brief',
    textBn: 'টিমকে জানান কী খবর পেলেন আর কোথা থেকে শুরু। ট্রিপ মানে ডেড নয় — লাইনে হাত দেওয়া বা ওঠার আগে পারমিট (PTW), আইসোলেট আর আর্থিং।',
    art: '$_dir/brief.svg',
    lessonPoint: 1,
  );

  /// Ruling M5-1 (R8, from lesson 5.1 myth 2 and 5.4's 'মারাত্মক ভুল'):
  /// a myth, so no lesson point to open.
  static const recharge = DoMistake(
    key: '5.1/m5_trip_call/recharge',
    textBn: 'ফল্ট খুঁজতে লাইন চার্জ নয়! স্থায়ী ফল্টে বারবার চালু করলে যন্ত্রপাতি আরও নষ্ট হয়, আগুন লাগতে পারে। ব্রেকার না টিকলে লাইন ব্রেকডাউন — ফল্ট না পেয়ে আর চার্জ নয়।',
    art: '$_dir/recharge.svg',
    deadly: true,
  );

  static DoMistake suspectFor(M5TripCase c) => switch (c) {
        M5TripCase.storm => suspectStorm,
        M5TripCase.clear => suspectClear,
        M5TripCase.recloses => suspectRecloses,
      };

  static List<DoMistake> get all => [unasked, vagueKept, suspectStorm, suspectClear, suspectRecloses, startTrees, startReport, brief, recharge];
}

/// One call from the control room (dealt).
@immutable
class M5TripCall {
  const M5TripCall({
    required this.kase,
    required this.feeder,
    required this.instant,
    required this.shots,
    required this.clue,
    required this.clueArea,
    required this.heard,
    required this.vague,
    required this.tiles,
    required this.map,
    required this.names,
    required this.cards,
    required this.day,
    required this.hour,
    required this.minute,
    required this.phrase,
  });

  final M5TripCase kase;
  final int feeder;

  /// The breaker tripped at once (always in a storm).
  final bool instant;

  /// The recloser's tries before the lock-out (2–3 on repeated recloses).
  final int shots;
  final M5TripClue clue;

  /// The section the customers / the logbook name (the trees in a storm).
  final M5TripArea clueArea;

  /// What the customers heard or saw (index into [M5TripLines.heardWhat]).
  final int heard;

  /// The topics that answer vaguely first.
  final Set<M5TripTopic> vague;

  /// The tile order on screen.
  final List<M5TripTopic> tiles;

  /// The four sections, map place 0..3, and their names.
  final List<M5TripArea> map;
  final Map<M5TripArea, String> names;

  /// The suspect cards, row place 0..2.
  final List<M5TripSuspect> cards;

  /// The shift (the wall clock and the window).
  final bool day;
  final int hour;
  final int minute;

  /// Picks the operator's phrasings.
  final int phrase;

  M5TripSuspect get suspect => switch (kase) {
        M5TripCase.storm => M5TripSuspect.branch,
        M5TripCase.clear => M5TripSuspect.bird,
        M5TripCase.recloses => M5TripSuspect.clash,
      };

  M5TripArea get start => kase == M5TripCase.storm ? M5TripArea.trees : clueArea;

  M5TripSky get sky => switch (kase) {
        M5TripCase.storm => M5TripSky.storm,
        M5TripCase.clear => M5TripSky.clear,
        M5TripCase.recloses => M5TripSky.windy,
      };

  M5TripRoom get room => M5TripRoom(sky: sky, day: day, map: map, cards: cards);

  String get clockText => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

@immutable
class M5TripDeal {
  const M5TripDeal({required this.calls, required this.coworkerCall});
  final List<M5TripCall> calls;

  /// The call the coworker comes in (0 or 1).
  final int coworkerCall;
}

M5TripCall _dealCall(M5TripCase kase, int feeder, math.Random rng) {
  final map = [...M5TripArea.values]..shuffle(rng);
  final names = {for (final a in M5TripArea.values) a: M5TripLines.areaNames[a]![rng.nextInt(M5TripLines.areaNames[a]!.length)]};
  final cards = [...M5TripSuspect.values]..shuffle(rng);
  final storm = kase == M5TripCase.storm;
  final clue = storm
      ? const [M5TripClue.none, M5TripClue.customer, M5TripClue.logbook][rng.nextInt(3)]
      : const [M5TripClue.customer, M5TripClue.logbook, M5TripClue.both][rng.nextInt(3)];
  final clueArea = storm ? M5TripArea.trees : const [M5TripArea.river, M5TripArea.market, M5TripArea.fields][rng.nextInt(3)];
  final vague = ([...m5TripRequired]..shuffle(rng)).take(2).toSet();
  final tiles = [...M5TripTopic.values]..shuffle(rng);
  // The lesson's second example is a clear day; the others by day or night.
  final day = kase == M5TripCase.clear || rng.nextBool();
  final hour = day ? 9 + rng.nextInt(8) : (20 + rng.nextInt(8)) % 24;
  return M5TripCall(
    kase: kase,
    feeder: feeder,
    instant: storm || rng.nextBool(),
    shots: kase == M5TripCase.recloses ? 2 + rng.nextInt(2) : 1,
    clue: clue,
    clueArea: clueArea,
    heard: rng.nextInt(M5TripLines.heardWhat.length),
    vague: vague,
    tiles: tiles,
    map: map,
    names: names,
    cards: cards,
    day: day,
    hour: hour,
    minute: rng.nextInt(12) * 5,
    phrase: rng.nextInt(2),
  );
}

/// A play's deal: two of the lesson's three examples in random order, two
/// feeders, and the call the coworker comes in.
M5TripDeal m5TripDeal(math.Random rng) {
  final cases = [...M5TripCase.values]..shuffle(rng);
  final feeders = [for (var i = 1; i <= 9; i++) i]..shuffle(rng);
  final calls = [for (var i = 0; i < 2; i++) _dealCall(cases[i], feeders[i], rng)];
  return M5TripDeal(calls: calls, coworkerCall: rng.nextInt(2));
}

/// The play state (pure logic).
class M5TripRun {
  M5TripRun(this.deal);
  final M5TripDeal deal;

  /// 0, 1 = the calls; 2 = the briefing.
  int call = 0;
  M5TripStage stage = M5TripStage.ring;

  /// 1 = a vague answer heard, 2 = a clear answer.
  final Map<M5TripTopic, int> heard = {};

  /// The topics in the order they were first asked (the notepad).
  final List<M5TripTopic> asked = [];

  int slips = 0;
  int stepSlips = 0;

  /// Needless re-asks (a tile tapped again after its clear answer): in this
  /// step, and in the whole play. Asking twice "just in case" is not
  /// spotting a vague answer: the step is no longer thorough (no +5, no
  /// "আজ যা ধরলেন" tag) and the play loses the quick bonus.
  int stepWaste = 0;
  int wasted = 0;

  /// A vague answer was probed this call.
  var _probed = false;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The step's work is done (its praise / reason comes next).
  var stepDone = false;

  M5TripCall get now => deal.calls[math.min(call, 1)];
  bool get done => stage == M5TripStage.done;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => stepSlips == 0 && stepWaste == 0;
  bool get isCoworkerCall => call == deal.coworkerCall;
  bool get _open => !ended && !stepDone;

  /// Every lesson question asked and answered clearly.
  bool get notesComplete => m5TripRequired.every((t) => heard[t] == 2);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return m;
  }

  /// The handset up.
  bool pickUp() {
    if (!_open || stage != M5TripStage.ring) return false;
    stage = M5TripStage.talk;
    return true;
  }

  /// A tile tapped: how the operator answers (null = not now).
  M5TripReply? ask(M5TripTopic t) {
    if (!_open || stage != M5TripStage.talk) return null;
    switch (heard[t]) {
      case null:
        asked.add(t);
        if (now.vague.contains(t)) {
          heard[t] = 1;
          return M5TripReply.vague;
        }
        heard[t] = 2;
        return M5TripReply.first;
      case 1:
        heard[t] = 2;
        _probed = true;
        return M5TripReply.probe;
      default:
        stepWaste++;
        wasted++;
        return M5TripReply.again;
    }
  }

  /// The handset down: a question unasked or vague = a slip (the call goes on).
  DoMistake? hangUp() {
    if (!_open || stage != M5TripStage.talk) return null;
    if (m5TripRequired.any((t) => heard[t] == null)) return _slip(M5TripMistakes.unasked);
    if (!notesComplete) return _slip(M5TripMistakes.vagueKept);
    stepDone = true;
    if (thorough) _tag(M5TripLines.caughtAsk);
    if (_probed && stepWaste == 0) _tag(M5TripLines.caughtProbe);
    return null;
  }

  /// The red pin on the card [s].
  DoMistake? pin(M5TripSuspect s) {
    if (!_open || stage != M5TripStage.pin) return null;
    if (s != now.suspect) return _slip(M5TripMistakes.suspectFor(now.kase));
    stepDone = true;
    if (thorough) _tag(M5TripLines.caughtSuspect);
    return null;
  }

  /// The van on the section [a].
  DoMistake? van(M5TripArea a) {
    if (!_open || stage != M5TripStage.van) return null;
    if (a != now.start) return _slip(now.kase == M5TripCase.storm ? M5TripMistakes.startTrees : M5TripMistakes.startReport);
    stepDone = true;
    if (thorough) _tag(M5TripLines.caughtStart);
    return null;
  }

  /// A briefing card picked.
  DoMistake? brief(bool right) {
    if (!_open || stage != M5TripStage.brief) return null;
    if (!right) return _slip(M5TripMistakes.brief);
    stepDone = true;
    _tag(M5TripLines.caughtBrief);
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  /// On to the next step (after the praise / reason).
  void next() {
    stepSlips = 0;
    stepWaste = 0;
    stepDone = false;
    switch (stage) {
      case M5TripStage.ring:
      case M5TripStage.talk:
        stage = stage == M5TripStage.ring ? M5TripStage.talk : M5TripStage.pin;
      case M5TripStage.pin:
        stage = M5TripStage.van;
      case M5TripStage.van:
        call++;
        heard.clear();
        asked.clear();
        _probed = false;
        stage = call < 2 ? M5TripStage.ring : M5TripStage.brief;
      case M5TripStage.brief:
        stage = M5TripStage.done;
      case M5TripStage.done:
        break;
    }
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per call: pick up, ~8 tile taps (6 required + 2 probes), hang up, pin,
///     van ≈ 12 × 1500 + reading the notes ~8000 ≈ 26000; reasons 3 × 8200
///     (the second call 2) → call 1 ≈ 50600, call 2 ≈ 42400
///   the time card 1700, the briefing ~6000, the coworker once ≈ 9600 ≈ 110300
/// 85 % ≈ 93800 → 100 s (rounded up; the operator's answers take time).
const m5TripQuickMs = 100000;

@immutable
class M5TripCallPack {
  const M5TripCallPack({required this.id, required this.titleBn, this.quickMs = m5TripQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5TripCallPack> m5TripCallPacks = {
  'do_5_1_a': M5TripCallPack(id: 'do_5_1_a', titleBn: M5TripLines.title),
};

/// What is being dragged.
enum _Grab { none, handset, pin, van }

// ============================================================================
// Page
// ============================================================================

class M5TripCallPage extends StatefulWidget {
  const M5TripCallPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5TripCallPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5TripCallPage> createState() => _M5TripCallPageState();
}

class _M5TripCallPageState extends State<M5TripCallPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TripRunPage(
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

class _TripRunPage extends ConsumerStatefulWidget {
  const _TripRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5TripCallPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TripRunPage> createState() => _TripRunPageState();
}

class _TripRunPageState extends ConsumerState<_TripRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5TripRun _run;
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

  /// The operator's last words (the bubble by the phone) and the trainee's
  /// probe before them.
  String? _opLine;
  String? _probeLine;
  var _opTalking = false;
  int _opTok = 0;

  /// The phone rang (a short shake), the time card between the calls.
  int _ringTok = 0;
  var _timeCard = false;
  Timer? _timeTimer;

  /// Where the pin and the van were put this call (null = at home).
  M5TripSuspect? _pinOn;
  M5TripArea? _vanOn;

  /// The drag in progress (design px).
  _Grab _grab = _Grab.none;
  Offset _dragFrom = Offset.zero;
  final _dragAt = ValueNotifier<Offset?>(null);

  // The briefing deck.
  List<ChoiceOption> _briefOpts = const [];
  final Set<String> _briefWrong = {};
  String? _briefPicked;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M5TripTopic, GlobalKey> _tileKeys = {for (final t in M5TripTopic.values) t: GlobalKey()};
  M5TripGeo? _geoNow;

  /// Play-clock ms of the last thing done on the call (a tile, the pick-up):
  /// the hand shows the tile sweep first and the hang-up nudge only after a
  /// long wait (a pure read in [_hint], never a counter it bumps).
  int _talkAt = 0;

  /// After the coworker is refused, his interrupted hang-up resumes on its
  /// own: input waits for it (a tile tapped meanwhile would not cut it short).
  var _resuming = false;

  @override
  void initState() {
    super.initState();
    _run = M5TripRun(m5TripDeal(widget.rng));
    MascotTalk.active.addListener(_operatorLips);
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    MascotTalk.active.removeListener(_operatorLips);
    disposeCoworker();
    _timeTimer?.cancel();
    _dragAt.dispose();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  /// The operator speaks by the device voice, which would move the guide's
  /// mouth: keep the guide's lips still while the operator talks.
  void _operatorLips() {
    if (_opTalking && MascotTalk.active.value) scheduleMicrotask(MascotTalk.reset);
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
    _opTalking = false;
    unawaited(MascotSpeechLibrary.stop());
  }

  /// The operator on the line: his words in the bubble (and the device voice,
  /// a little lower); the guide's bubble clears meanwhile.
  Future<void> _operatorSay(String line, {String? probe}) async {
    _hush();
    final tok = ++_opTok;
    final guide = ref.read(guideDirectorProvider.notifier);
    guide.softClearLine();
    guide.react(GuideMood.idle);
    setState(() {
      _opLine = line;
      _probeLine = probe;
    });
    _opTalking = true;
    await MascotSpeechLibrary.speak(line, muted: _muted, pitch: 0.82);
    if (mounted && tok == _opTok) _opTalking = false;
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro &&
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_run.stepDone &&
      !_freeze &&
      !_timeCard &&
      !_resuming;

  String get _task => switch (_run.stage) {
        M5TripStage.ring => M5TripLines.askPhone,
        M5TripStage.talk => M5TripLines.askAsk,
        M5TripStage.pin => M5TripLines.askPin,
        M5TripStage.van => M5TripLines.askVan,
        M5TripStage.brief || M5TripStage.done => M5TripLines.askBrief,
      };

  Future<void> _start() async {
    _clock.start();
    _startStage();
  }

  void _startStage() {
    setState(() {
      if (_run.stage == M5TripStage.ring) {
        _ringTok++;
        _opLine = null;
        _probeLine = null;
        _pinOn = null;
        _vanOn = null;
      }
      if (_run.stage == M5TripStage.brief) {
        _briefOpts = dealChoices(M5TripLines.briefRight, M5TripLines.briefWrong, widget.rng);
        _briefWrong.clear();
        _briefPicked = null;
        _opLine = null;
        _probeLine = null;
      }
    });
    if (_run.stage == M5TripStage.ring) {
      HapticFeedback.heavyImpact();
      _cue('sounds/complaint.ogg', volume: 0.8);
    }
    if (_run.stage == M5TripStage.brief) _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([_task]));
  }

  // --- hands on -----------------------------------------------------------------
  void _pickUp() {
    if (!_canPlay || !_run.pickUp()) return;
    _tick('sounds/intro/click.ogg', 0.6);
    _talkAt = _clock.elapsedMilliseconds;
    setState(() {});
    unawaited(_operatorSay(M5TripLines.opening(_run.now.feeder)));
  }

  void _askTopic(M5TripTopic t) {
    if (!_canPlay) return;
    final r = _run.ask(t);
    if (r == null) return;
    _tick('sounds/quiz_select.ogg', 0.45);
    _talkAt = _clock.elapsedMilliseconds;
    final c = _run.now;
    final line = switch (r) {
      M5TripReply.vague => M5TripLines.vagueAnswer(c, t),
      M5TripReply.again => M5TripLines.again(M5TripLines.clearAnswer(c, t)),
      M5TripReply.first || M5TripReply.probe => M5TripLines.clearAnswer(c, t),
    };
    unawaited(_operatorSay(line, probe: r == M5TripReply.probe ? M5TripLines.probe[t] : null));
  }

  void _hangUp() {
    if (!_canPlay || _run.stage != M5TripStage.talk) return;
    // His call: the hang-up waits for him (he comes before the check).
    if (_run.isCoworkerCall && !coworkerDone) {
      scheduleCoworker();
      if (holdForCoworker()) {
        // The operator's cue stands by the phone as he cuts in (in the
        // bubble only: his recorded push follows at once).
        setState(() {
          _opTok++;
          _opLine = M5TripLines.lost;
          _probeLine = null;
        });
        return;
      }
    }
    _hush();
    final m = _run.hangUp();
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, _phoneGlobal()));
      return;
    }
    _cue('sounds/intro/drop.ogg', volume: 0.5);
    setState(() {
      _opLine = null;
      _probeLine = null;
    });
    if (_run.call == 0) {
      _stepDone(M5TripLines.askWhyQ, M5TripLines.askWhy);
    } else {
      // The second call's hang-up pays at once (its reason was asked in the first).
      unawaited(_levelDelta(15 + (_run.thorough ? 5 : 0), _phoneGlobal(), mood: GuideMood.glad));
      unawaited(_sayChain([M5TripLines.askPaid], mood: GuideMood.glad));
      final idx = (_run.call, _run.stage);
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 1400), () {
        if (mounted && !_ended && (_run.call, _run.stage) == idx) _next();
      }));
    }
  }

  void _dropPin(Offset p) {
    if (!_canPlay || _run.stage != M5TripStage.pin) return;
    final geo = _geoNow!;
    final at = [for (var i = 0; i < 3; i++) i].where((i) => geo.card(i).inflate(6).contains(p)).firstOrNull;
    if (at == null) return;
    final s = _run.now.cards[at];
    _tick('sounds/learn/tag_slap.ogg', 0.55);
    final m = _run.pin(s);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, _sceneGlobal(p)));
      return;
    }
    setState(() => _pinOn = s);
    _stepDone(M5TripLines.pinWhyQ, M5TripLines.pinWhy[_run.now.kase]!);
  }

  void _dropVan(Offset p) {
    if (!_canPlay || _run.stage != M5TripStage.van) return;
    final geo = _geoNow!;
    final at = [for (var i = 0; i < 4; i++) i].where((i) => geo.section(i).inflate(4).contains(p)).firstOrNull;
    if (at == null) return;
    final a = _run.now.map[at];
    _tick('sounds/intro/impact_metal.ogg', 0.5);
    final m = _run.van(a);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, _sceneGlobal(p)));
      return;
    }
    setState(() => _vanOn = a);
    _stepDone(M5TripLines.vanWhyQ, M5TripLines.vanWhy(_run.now));
  }

  Future<void> _pickBrief(ChoiceOption o, Offset origin) async {
    if (!_canPlay || _run.stage != M5TripStage.brief || _briefWrong.contains(o.textBn) || _briefPicked != null) return;
    _hush();
    if (!o.correct) {
      setState(() => _briefWrong.add(o.textBn));
      final m = _run.brief(false);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    setState(() => _briefPicked = o.textBn);
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    _run.brief(true);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await _sayChain([M5TripLines.briefPaid], mood: GuideMood.glad);
    if (!mounted || _ended) return;
    _next();
  }

  /// A right step: the ◆ on the table, then its reason.
  void _stepDone(String question, List<String> right) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = (_run.call, _run.stage);
    unawaited(askReason(
      deal: () => dealChoices(right, M5TripLines.myths, widget.rng),
      question: question,
      stillValid: () => (_run.call, _run.stage) == idx && !_ended,
    ));
  }

  void _next() {
    final newCall = _run.stage == M5TripStage.van && _run.call == 0;
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    if (newCall) {
      // The time card between the calls, then the phone rings again.
      setState(() => _timeCard = true);
      _timeTimer?.cancel();
      _timeTimer = Timer(Duration(milliseconds: _quiet ? 700 : 1700), () {
        if (!mounted || _ended) return;
        setState(() => _timeCard = false);
        _startStage();
      });
      return;
    }
    _startStage();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Offset _sceneGlobal(Offset design) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return Offset.zero;
    final s = box.size;
    final k = math.max(s.width / 360, s.height / (_geoNow?.height ?? 780));
    return Offset(design.dx * k, design.dy * k);
  }

  Offset _phoneGlobal() => _sceneGlobal(_geoNow?.handsetRest.center ?? const Offset(290, 420));

  // --- the drags (handset, pin, van) -------------------------------------------
  Rect get _handsetRect {
    final g = _geoNow!;
    return _run.stage == M5TripStage.talk ? g.handsetUp : g.handsetRest;
  }

  void _panStart(Offset p) {
    _grab = _Grab.none;
    if (!_canPlay || _geoNow == null) return;
    final g = _geoNow!;
    switch (_run.stage) {
      case M5TripStage.ring:
      case M5TripStage.talk:
        if (_handsetRect.inflate(16).contains(p)) _grab = _Grab.handset;
      case M5TripStage.pin:
        if (g.pinHit.contains(p)) _grab = _Grab.pin;
      case M5TripStage.van:
        if (g.vanHit.contains(p)) _grab = _Grab.van;
      default:
        break;
    }
    if (_grab != _Grab.none) {
      _dragFrom = p;
      _dragAt.value = p;
    }
  }

  void _panUpdate(Offset p) {
    if (_grab == _Grab.none) return;
    _dragAt.value = p;
  }

  void _panEnd() {
    final grab = _grab;
    final at = _dragAt.value;
    _grab = _Grab.none;
    _dragAt.value = null;
    if (grab == _Grab.none || at == null) return;
    final dy = at.dy - _dragFrom.dy;
    switch (grab) {
      case _Grab.handset:
        if (_run.stage == M5TripStage.ring && dy < -22) {
          _pickUp();
        } else if (_run.stage == M5TripStage.talk && dy > 22) {
          _hangUp();
        } else {
          _hints.missTap();
        }
      case _Grab.pin:
        _dropPin(at);
      case _Grab.van:
        _dropVan(at);
      case _Grab.none:
        break;
    }
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
    final idx = (_run.call, _run.stage);
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && (_run.call, _run.stage) == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5TripLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  /// He comes only through the held hang-up of his call (never on a timer).
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.isCoworkerCall || _run.stage != M5TripStage.talk || _run.stepDone) return null;
    return false;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the locked-out feeder is charged onto its fault.
      _run.failDeadly(M5TripMistakes.recharge);
      await _deadly(M5TripMistakes.recharge);
      return;
    }
    _run.caught.add(M5TripLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    setState(() => _resuming = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    await _sayChain([M5TripLines.callHeld], mood: GuideMood.glad);
    if (!mounted || _ended) return;
    // The hang-up he interrupted goes on into the check.
    setState(() => _resuming = false);
    _hangUp();
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5TripLines.tapWhy[_nudgeN++ % M5TripLines.tapWhy.length]
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
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('tripcall/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The feeder charged onto its fault: the scene freezes grey, the flash and
  /// fire at the fault's section in colour; then near-miss or death.
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
      _opLine = null;
      _probeLine = null;
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
    final speak = await SpokenOnce.first('tripcall/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5TripLines.deadlyWord : M5TripLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same step goes on; a call goes on with the operator.
        _hush();
        setState(() => _card = null);
        if (_run.stage == M5TripStage.talk) {
          _talkAt = _clock.elapsedMilliseconds;
          unawaited(_operatorSay(M5TripLines.hello));
        } else {
          unawaited(_sayChain([_task]));
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
      if (mark == 100 && _quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M5TripLines.fail : (_quickBonus ? M5TripLines.quick : M5TripLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  /// Quick = in time and without needless re-asks (tapping every tile twice
  /// is not quick work).
  bool get _quick => _clock.elapsedMilliseconds < widget.pack.quickMs && _run.wasted == 0;

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
  /// The gesture hand: a drag nudge on the thing to move, in a generic
  /// direction and too short to reach any card or section; a sweep over all
  /// seven tiles (after a long wait with something asked, the hang-up nudge
  /// instead). Never what to pick. Pure: reads the clock, changes nothing.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.stage) {
      case M5TripStage.ring:
        return HintSpec.drag(geo.handsetRest.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M5TripStage.talk:
        final tiles = [for (final t in _run.now.tiles) ?HintSpec.globalRectOf(_tileKeys[t]!)];
        if (_run.asked.isNotEmpty && _clock.elapsedMilliseconds - _talkAt > _hangUpHintMs) {
          return HintSpec.drag(geo.handsetUp.center, toward: const Offset(0, 1), travel: 40, space: HintSpace.scene);
        }
        return tiles.length < 2 ? null : HintSpec.sweep(tiles);
      case M5TripStage.pin:
        return HintSpec.drag(geo.pinHome, toward: const Offset(-1, -0.2), travel: 22, space: HintSpace.scene);
      case M5TripStage.van:
        return HintSpec.drag(geo.vanHome, toward: const Offset(0, -1), travel: 26, space: HintSpace.scene);
      case M5TripStage.brief:
      case M5TripStage.done:
        return null;
    }
  }

  /// The first hand (idle 8 s) sweeps the tiles; one after the re-arm wait
  /// (25 s more) nudges the hang-up.
  static const _hangUpHintMs = 20000;

  /// The tile band's gap above the bottom inset.
  static const _tileGap = 8.0;

  /// The scene's design height for this screen (as FullSceneFrame sizes it).
  double get _sceneH {
    final size = MediaQuery.sizeOf(context);
    return size.width <= 0 ? 780 : (360 * size.height / size.width).clamp(560.0, 900.0);
  }

  /// The top of the tile band in design px for a grid [gridH] screen px tall.
  double _tilesTopDesign(double sceneH, double gridH) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    if (size.width <= 0 || size.height <= 0) return sceneH;
    final scale = math.max(size.width / 360, size.height / sceneH);
    final dy = (size.height - sceneH * scale) / 2;
    return (size.height - pad.bottom - _tileGap - gridH - dy) / scale;
  }

  /// A short screen: the tiles go 4 to a row (2 rows) so the notepad keeps
  /// room for every answer at a readable size.
  bool get _compactTiles {
    final h = _sceneH;
    final geo = M5TripGeo.forScene(h);
    return _tilesTopDesign(h, _TileGrid.heightFor(compact: false)) - (geo.notepad.top + 14) < 170;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5TripGeo.forScene(m.height);
    final quiet = _quiet;
    final call = _run.now;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final lifted = _run.stage == M5TripStage.talk;
    final opLine = _opLine;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('room'),
                child: RepaintBoundary(child: CustomPaint(painter: M5TripPainter(geo: geo, room: call.room))),
              ),
              // Section names (map) and the cards' labels — words a worker reads.
              for (var i = 0; i < 4; i++)
                Positioned.fromRect(
                  key: ValueKey('area-$i'),
                  rect: Rect.fromLTWH(geo.section(i).left, geo.section(i).bottom - 18, geo.section(i).width, 17),
                  child: _Label(call.names[call.map[i]]!, size: 9.5),
                ),
              for (var i = 0; i < 3; i++)
                Positioned.fromRect(
                  key: ValueKey('card-$i'),
                  rect: Rect.fromLTWH(geo.card(i).left, geo.card(i).bottom - 20, geo.card(i).width, 18),
                  child: _Label(M5TripLines.suspect[call.cards[i]]!, size: 10.5),
                ),
              Positioned.fromRect(
                key: const ValueKey('clock'),
                rect: geo.clock,
                child: Center(
                  child: Text(enDigits(call.clockText),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF6CFF8E), fontFeatures: [FontFeature.tabularFigures()])),
                ),
              ),
              Positioned.fromRect(
                key: ValueKey('notes-${_run.call}'),
                rect: Rect.fromLTRB(
                  geo.notepad.left + 22,
                  geo.notepad.top + 14,
                  geo.notepad.right - 6,
                  math.max(
                    geo.notepad.top + 60,
                    _run.stage == M5TripStage.talk
                        ? math.min(geo.notepad.bottom - 4, _tilesTopDesign(m.height, _TileGrid.heightFor(compact: _compactTiles)) - 4)
                        : geo.notepad.bottom - 4,
                  ),
                ),
                child: _Notes(call: call, run: _run),
              ),
              // The pin and the van: at home, put down, or under the finger.
              ValueListenableBuilder<Offset?>(
                key: const ValueKey('tokens'),
                valueListenable: _dragAt,
                builder: (_, drag, _) {
                  final pinAt = _grab == _Grab.pin && drag != null
                      ? drag
                      : _pinOn != null
                          ? geo.card(call.cards.indexOf(_pinOn!)).topCenter + const Offset(0, 10)
                          : geo.pinHome;
                  final vanAt = _grab == _Grab.van && drag != null
                      ? drag
                      : _vanOn != null
                          ? geo.section(call.map.indexOf(_vanOn!)).center
                          : geo.vanHome;
                  final dy = _grab == _Grab.handset && drag != null ? (drag.dy - _dragFrom.dy).clamp(-34.0, 34.0) : 0.0;
                  final hs = (lifted ? geo.handsetUp : geo.handsetRest).translate(0, dy);
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        key: const ValueKey('handset'),
                        rect: hs,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('ring-$_ringTok'),
                          tween: Tween(begin: quiet || _ringTok == 0 ? 1 : 0, end: 1),
                          duration: const Duration(milliseconds: 1300),
                          builder: (_, v, child) => Transform.rotate(angle: v >= 1 ? 0 : math.sin(v * math.pi * 14) * 0.08 * (1 - v), child: child),
                          child: Semantics(
                            label: M5TripLines.handset,
                            child: CustomPaint(painter: M5TripHandsetPainter(lifted: lifted)),
                          ),
                        ),
                      ),
                      Positioned.fromRect(
                        key: const ValueKey('pin'),
                        rect: Rect.fromCenter(center: pinAt, width: 26, height: 34),
                        child: Semantics(label: M5TripLines.pin, child: const CustomPaint(painter: M5TripPinPainter())),
                      ),
                      Positioned.fromRect(
                        key: const ValueKey('van'),
                        rect: Rect.fromCenter(center: vanAt, width: 46, height: 28),
                        child: Semantics(label: M5TripLines.van, child: const CustomPaint(painter: M5TripVanPainter())),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // The operator's words by the phone (and the trainee's probe above them).
      if (opLine != null && !_freeze)
        Positioned.fromRect(
          key: ValueKey('op-$_opTok'),
          rect: geo.bubble,
          child: IgnorePointer(child: _OperatorBubble(line: opLine, probe: _probeLine)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5TripLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (_) {
              if (_canPlay) _hints.missTap();
            },
            onPanStart: (d) => _panStart(d.localPosition),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () {
              _grab = _Grab.none;
              _dragAt.value = null;
            },
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('fire'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1600),
              builder: (_, v, _) => CustomPaint(painter: M5TripFirePainter(at: geo.section(call.map.indexOf(call.start)), v: v)),
            ),
          ),
        ),
      // The next call: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('call-${_run.call}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.call == 0 ? 0 : 0.6, end: 0),
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
    final briefUp = _run.stage == M5TripStage.brief && playing && _card == null && !_run.stepDone;
    final deckUp = reasonOpen || coworkerChoiceUp || briefUp;
    final handsOn = playing && !_run.stepDone && !deckUp && !coworkerOpen && _card == null && !_timeCard;
    final tilesUp = handsOn && _run.stage == M5TripStage.talk;
    final compact = _compactTiles;
    final tilesH = _TileGrid.heightFor(compact: compact);
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
              labels: M5TripLines.rounds,
              done: {for (var i = 0; i < math.min(_run.call, 3); i++) i},
              current: _run.done ? null : math.min(_run.call, 2),
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _run.stage != M5TripStage.brief,
            hintKey: '${_run.call}/${_run.stage.name}/${_run.asked.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (tilesUp)
                Positioned(
                  key: ValueKey('hud-tiles-${_run.call}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + _tileGap,
                  child: _TileGrid(
                    compact: compact,
                    tiles: _run.now.tiles,
                    keys: _tileKeys,
                    onTap: _askTopic,
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
                                key: const ValueKey('brief-deck'),
                                options: _briefOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _briefWrong,
                                picked: _briefPicked,
                                onPick: (o, at) => unawaited(_pickBrief(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : (tilesUp ? _tileGap + tilesH + 14 : 8)),
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_timeCard)
                Positioned.fill(
                  key: const ValueKey('time-card'),
                  child: IgnorePointer(child: _TimeCard(clock: _run.now.clockText, quiet: quiet)),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.call}-$strikes'),
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
                  line: M5TripLines.intro,
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

/// A short label on the board (a section's name, a card's caption).
class _Label extends StatelessWidget {
  const _Label(this.text, {required this.size});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1, style: bangla(fontSize: size, fontWeight: FontWeight.w800, color: const Color(0xFF2A2116))),
        ),
      );
}

/// The notepad: the feeder, then every answer word for word, in the order
/// asked (a vague answer stands as it was said until it is probed).
class _Notes extends StatelessWidget {
  const _Notes({required this.call, required this.run});
  final M5TripCall call;
  final M5TripRun run;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A6B), height: 1.3);
    final head = bangla(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF1E3A6B), height: 1.3);
    final picked = run.stage != M5TripStage.ring;
    final notes = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (picked) Text(enDigits('ফিডার ${call.feeder} · ${call.clockText}'), style: head),
        for (final t in run.asked)
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '${M5TripLines.note[t]}: ', style: head),
              TextSpan(
                text: enDigits(run.heard[t] == 1 ? M5TripLines.vagueAnswer(call, t) : M5TripLines.clearAnswer(call, t)),
                style: ink,
              ),
            ]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    // Many entries on a short notepad: the page shrinks to fit (never hidden
    // under the tiles, never overflowing).
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => ClipRect(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(width: box.maxWidth, child: notes),
          ),
        ),
      ),
    );
  }
}

class _OperatorBubble extends StatelessWidget {
  const _OperatorBubble({required this.line, required this.probe});
  final String line;
  final String? probe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xF0F4F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (probe != null)
            Text('— ${probe!}', maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF5A6675))),
          Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFF2E6B3A)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(enDigits(line),
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF14202E), height: 1.25)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The seven question tiles, three to a row (four on a short screen), all
/// alike.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.keys, required this.onTap, this.compact = false});
  final List<M5TripTopic> tiles;
  final Map<M5TripTopic, GlobalKey> keys;
  final ValueChanged<M5TripTopic> onTap;
  final bool compact;

  static const _gap = 6.0;
  static int _cols(bool compact) => compact ? 4 : 3;
  static double _tileH(bool compact) => compact ? 40 : 44;

  /// The grid's height on screen.
  static double heightFor({required bool compact}) {
    final rows = (M5TripTopic.values.length / _cols(compact)).ceil();
    return rows * _tileH(compact) + (rows - 1) * _gap;
  }

  @override
  Widget build(BuildContext context) {
    final cols = _cols(compact);
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - (cols - 1) * _gap) / cols;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          alignment: WrapAlignment.center,
          children: [
            for (final t in tiles)
              Semantics(
                key: keys[t],
                button: true,
                label: M5TripLines.tile[t],
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(t),
                  child: Container(
                    width: w,
                    height: _tileH(compact),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.4),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 3))],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: compact
                          // Narrow tiles: two lines, then shrink only if needed.
                          ? SizedBox(
                              width: w - 8,
                              child: Text(M5TripLines.tile[t]!,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.15)),
                            )
                          : Text(M5TripLines.tile[t]!, maxLines: 1, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Between the calls: the next call's time, for a moment.
class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.clock, required this.quiet});
  final String clock;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 380),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: ColoredBox(
        color: const Color(0xCC050A16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(M5TripLines.nextCall, style: bangla(fontSize: 18, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
              const SizedBox(height: 6),
              Text(enDigits(clock), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
