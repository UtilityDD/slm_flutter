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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_grievance_reply_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_grievance_reply_world.dart' show M8Geo, M8Look, M8Mood, kM8Looks;

// Lesson 8.6 "গ্রাহক অভিযোগ নিষ্পত্তি", কাজ "রাগ নয়, ঠিক রাস্তা" (pack do_8_6_a,
// engineType m8_grievance_reply). A para lane at dusk beside the van. Three
// angry consumers walk up one at a time, each with an anger cloud that swells
// while he speaks (a silent caption bubble, held for a reading time).
//
// New core action (ruling M8-20: not Module 7's "build a reply from phrase
// tiles"): the van carries a complaint LADDER on its side, three planks —
// ডকেট · 1912 / CCC, CGRF, অম্বুডসম্যান. The player carries the consumer's case
// FILE from the trainee's hand and drops it on the plank that is this
// consumer's next step (nothing is judged while it sits on a plank; it can be
// lifted to another), then taps 'পাঠান'. The right plank → the consumer
// pushes back once (a caption) and a three-card reply deck opens (one honest
// line for his step, two wrong ones: a brush-off, a promise, an argument, a
// myth, or another step's line). Right → the cloud dissolves, ◆ on the table,
// "কেন …?". A wrong plank or a wrong card → a slip card, the file goes home /
// the card turns red and the consumer shouts back.
//
// Stages (dealt, 3 of 6): S1 shouting, no docket → ডকেট; S2 has a docket
// number → ডকেট (the number is checked); S3 docketed, the call centre did not
// solve it → CGRF; S4 unhappy with CGRF → অম্বুডসম্যান; S5 threatens a
// complaint against the lineman → CGRF; S6 threatens a case against the
// company after CGRF → অম্বুডসম্যান.
//
// Deadly: none (M8-1: grievance = slip). Slips: the wrong plank (a leap ahead
// or a step back), 'মুখে বললেই হবে', a false promise, arguing, 'কেস করে কিছু
// পারবেন না', 'CGRF-এর রায়ই শেষ কথা', 'দয়া করে কমপ্লেইন করবেন না', another
// step's line, and listening to the coworker (X2/B1: a slip here). Three slips
// strike out.
//
// Built on the shared level kit: guide first, the full scene, corner guide;
// the coworker once a play at one dealt consumer's 'পাঠান' (it waits for him:
// holdForCoworker). Gesture hands (how, never what): a sweep over the three
// planks, then a nudge up from the file; a tap on 'পাঠান' once the file sits
// on a plank. None while a consumer speaks, cards or decks are up.

// ============================================================================
// Content
// ============================================================================

/// The six stages a consumer can be at.
enum M8Stage { noDocket, hasDocket, unsolved, cgrfUnhappy, threatLineman, threatCase }

/// The three ladder steps (also the plank's index, 0 = lowest).
enum M8Forum { docket, cgrf, ombud }

/// The kinds of wrong reply card.
enum M8Trap { verbal, promise, argue, caseMyth, finalWord, noComplain, wrongForum }

/// What a reason asks about.
enum M8Why { docket, centre, cgrf, ombud, promise, fear }

extension M8StageInfo on M8Stage {
  /// The plank this consumer's file belongs on.
  M8Forum get forum => switch (this) {
        M8Stage.noDocket || M8Stage.hasDocket => M8Forum.docket,
        M8Stage.unsolved || M8Stage.threatLineman => M8Forum.cgrf,
        M8Stage.cgrfUnhappy || M8Stage.threatCase => M8Forum.ombud,
      };
}

abstract final class M8GrievanceReplyLines {
  static const title = 'রাগ নয়, ঠিক রাস্তা';
  // DRAFT wording — owner (M6-12).
  static const intro = 'পাড়ায় লোক রেগে আছে! তর্ক নয় — ঠিক কথা, ঠিক জায়গা।';

  // The guide's task now (tap him: the same task, a different way).
  static const askListen = 'আগে গ্রাহকের কথাটা শুনুন।';
  static const askRoute = 'ফাইলটা সিঁড়ির ঠিক ধাপে রাখুন, তারপর পাঠান।';
  static const askSend = 'ফাইল রাখা হলো — এবার পাঠান।';
  static const askReply = 'এবার কী জবাব দেবেন?';
  static const needFile = 'আগে ফাইলটা সিঁড়ির একটা ধাপে রাখুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askListen, askRoute, askSend, askReply];

  // What a worker reads on the scene.
  static const send = 'পাঠান';
  static const fileLabel = 'অভিযোগের ফাইল';
  static const sceneLabel = 'পাড়ার রাস্তা';
  static const rungNames = ['ডকেট · 1912 / CCC', 'CGRF', 'অম্বুডসম্যান'];
  static const rungShown = ['ডকেট\n1912 / CCC', 'CGRF', 'অম্বুডসম্যান'];
  static String consumer(int n) => enDigits('গ্রাহক $n');

  /// What each consumer says first (two wordings, silent caption).
  static const first = <M8Stage, List<String>>{
    M8Stage.noDocket: ['দুদিন ধরে লাইন নেই! আপনারা করছেনটা কী?', 'ভোল্টেজ এত কম, বিলও চড়া! কে দেখবে?'],
    M8Stage.hasDocket: ['ডকেট করেছি, নম্বর 4417! এখনও কিছুই হয়নি!', 'কাল ডকেট করেছি, নম্বর 2086! কেউ আসেনি!'],
    M8Stage.unsolved: ['ডকেটও আছে, কল সেন্টারে সমাধান হয়নি! এবার কী?', 'কল সেন্টারে ডকেট করেছি, কাজের কাজ হয়নি! এবার?'],
    M8Stage.cgrfUnhappy: ['CGRF-এর রায় হয়েছে, আমি খুশি নই! এবার কী?', 'CGRF-এ গেলাম, রায় পছন্দ হলো না! এবার কোথায়?'],
    M8Stage.threatLineman: ['ডকেট করেছি, কেউ শোনেনি! আপনার নামে কমপ্লেইন করব!', 'কেউ শোনে না! সব বলে দেব, আপনার নামে নালিশ করব!'],
    M8Stage.threatCase: ['CGRF-এ গেছি, রায়ও পাল্টাল না! কেস করব কোম্পানির নামে!', 'CGRF-এও হলো না কিছু! কেস করব কোম্পানির নামে!'],
  };

  /// What he says once more after the file went to the right plank.
  static const push = <M8Stage, List<String>>{
    M8Stage.noDocket: ['ডকেট-ফকেট বুঝি না, আপনি এখনই কিছু করুন!', 'আবার ফোন? ওসব ঝামেলা কে করবে?'],
    M8Stage.hasDocket: ['নম্বর তো দিলাম, এবার কী হবে, বলুন!', 'নম্বর দিয়ে কী লাভ, কবে আসবে লোক?'],
    M8Stage.unsolved: ['তাহলে কালই কাজ হবে তো? বলুন!', 'কবে মিটবে, আজ বলুন, এখনই বলুন!'],
    M8Stage.cgrfUnhappy: ['তাহলে কি আর কোথাও যাওয়ার নেই?', 'রায় না মানলে আমার কী হবে তাহলে?'],
    M8Stage.threatLineman: ['ভয় পাচ্ছেন না তাহলে? চাকরি যাবে কিন্তু!', 'আপনার চাকরি যাবে, মনে রাখবেন, জানেন?'],
    M8Stage.threatCase: ['কোম্পানি বড়, আমার কেস টিকবে তো? বলুন!', 'কেস করে কিছু হবে, নাকি সময় নষ্ট?'],
  };

  /// The honest line for each stage (two phrasings; the guide's lesson lines).
  static const right = <M8Stage, List<String>>{
    M8Stage.noDocket: ['দাদা, ডকেট করেছেন? নম্বরটা দিন, দেখছি।', 'আগে 1912-এ জানান, ডকেট নম্বর পাবেন।'],
    M8Stage.hasDocket: ['নম্বরটা দেখে নিচ্ছি, ডকেট লেখা আছে।', 'ডকেট নম্বর থাকলে রেকর্ড আছে, দেখছি।'],
    M8Stage.unsolved: ['কল সেন্টারে না মিটলে CGRF-এ আবেদন করুন।', 'সমাধান না হলে CGRF-এ যাওয়ার অধিকার আছে।'],
    M8Stage.cgrfUnhappy: ['CGRF-এ খুশি না হলে অম্বুডসম্যানের কাছে যান', 'WBERC-এর অম্বুডসম্যানের কাছে আপিল করা যায়'],
    M8Stage.threatLineman: ['স্যার, আপনার অধিকার আছে CGRF-এ যাওয়ার।', 'স্যার, ফর্মটা এনে দিই, CGRF-এ জানান।'],
    M8Stage.threatCase: ['ঝগড়া না করে অম্বুডসম্যানের কাছে যান।', 'অম্বুডসম্যানের রায় কোম্পানিকে মানতেই হয়'],
  };

  /// The wrong reply cards by kind (the first four are for any consumer).
  static const traps = <M8Trap, List<String>>{
    M8Trap.verbal: ['ঠিক আছে দাদা, মুখে বললেই সব কাজ হবে।'],
    M8Trap.promise: ['চিন্তা করবেন না দাদা, কালই হয়ে যাবে।', 'আমি কথা দিলাম, কালই সব ঠিক হয়ে যাবে।'],
    M8Trap.argue: ['আমার সাথে চেঁচাবেন না তো, বুঝলেন দাদা!', 'মিথ্যে কথা বলছেন আপনি, থামুন এবার!'],
    M8Trap.caseMyth: ['কেস করে আমাদের কিছু করতে পারবেন না।'],
    M8Trap.finalWord: ['CGRF-এর রায়ই শেষ কথা, আর কিছু নেই।'],
    M8Trap.noComplain: ['দয়া করে কমপ্লেইন করবেন না, দাদা, ছাড়ুন!'],
  };

  static List<String> get allTrapLines => [for (final l in traps.values) ...l];
  static List<String> get allRightLines => [for (final l in right.values) ...l];

  /// The wrong cards dealt for a stage: every trap, plus the honest lines of
  /// the other steps (right for another consumer, wrong for this one).
  static List<String> wrongPool(M8Stage s) => [
        ...allTrapLines,
        for (final e in right.entries)
          if (e.key.forum != s.forum) ...e.value,
      ];

  /// Which kind of wrong card [text] is for stage [s] (null = not a wrong card).
  static M8Trap? trapOf(String text, M8Stage s) {
    for (final e in traps.entries) {
      if (e.value.contains(text)) return e.key;
    }
    for (final e in right.entries) {
      if (e.key.forum != s.forum && e.value.contains(text)) return M8Trap.wrongForum;
    }
    return null;
  }

  /// The consumer's caption when he calms / shouts back.
  static const calmReaction = ['ঠিক আছে, এবার বুঝলাম।', 'আচ্ছা, তাহলে এটাই করি।', 'ঠিক রাস্তাটা বললেন, ধন্যবাদ।'];
  static const routeReaction = 'আমাকে ঘুরিয়ে দিচ্ছেন কেন?';
  static const trapReaction = <M8Trap, String>{
    M8Trap.verbal: 'মুখের কথায় কী হবে? কেউ তো লিখে রাখছে না!',
    M8Trap.promise: 'কালই তো? কথা দিলেন কিন্তু!',
    M8Trap.argue: 'আমি মিথ্যে বলছি? ঝগড়া করছেন?',
    M8Trap.caseMyth: 'তাই নাকি? তাহলে আমি যাব কোথায়?',
    M8Trap.finalWord: 'শেষ কথা? আর কোথাও যাওয়া যাবে না?',
    M8Trap.noComplain: 'কমপ্লেইনও করতে পারব না?',
    M8Trap.wrongForum: 'এটা তো আমার ধাপই নয়!',
  };

  // The reasons: the right ones fit what was done; the wrong ones are field
  // excuses and the lesson's myths (all about the same length).
  static const whyQ = <M8Why, String>{
    M8Why.docket: 'কেন ডকেট নম্বর চাইলেন?',
    M8Why.centre: 'কেন 1912 বা CCC-র কথা বললেন?',
    M8Why.cgrf: 'কেন CGRF-এর কথা বললেন?',
    M8Why.ombud: 'কেন অম্বুডসম্যানের কথা বললেন?',
    M8Why.promise: 'কেন “কালই হয়ে যাবে” বললেন না?',
    M8Why.fear: 'কমপ্লেইনের কথায় ভয় পেলেন না কেন?',
  };
  static const whyRight = <M8Why, List<String>>{
    M8Why.docket: ['ডকেট নম্বর ছাড়া আইনের চোখে সমস্যাই নেই', 'ডকেট নম্বরই অভিযোগের আইনি রেকর্ড হয়ে থাকে'],
    M8Why.centre: ['1912 বা CCC-তেই অভিযোগের প্রথম ধাপ শুরু হয়', 'কল সেন্টারে জানালেই ডকেট নম্বর তৈরি হয়'],
    M8Why.cgrf: ['কল সেন্টারে না মিটলে CGRF-এ আবেদন করা যায়', 'CGRF-এ নিরপেক্ষ সদস্য আইন মেনে রায় দেন'],
    M8Why.ombud: ['CGRF-এর পরে অম্বুডসম্যানের কাছে যাওয়া যায়', 'অম্বুডসম্যানের রায় কোম্পানির MD-কেও মানতে হয়'],
    M8Why.promise: ['নিশ্চিত না হয়ে কথা দিলে অভিযোগ আরও বড় হয়', 'কথা দিয়ে না রাখলে গ্রাহকের রাগ আরও বাড়ে'],
    M8Why.fear: ['নিয়ম মেনে কাজ করলে কমপ্লেইনে ভয়ের কিছু নেই', 'তদন্ত ছাড়া কারও চাকরি যায় না, ভয় নেই'],
  };
  static const myths = [
    'গ্রাহক চুপ করলেই কাজ শেষ, কাগজ লাগে না',
    'মুখের কথাই অভিযোগ, লিখে রাখার দরকার নেই',
    'কথা দিলে গ্রাহক শান্ত হন, পরে দেখা যাবে',
    'অভিযোগ উঠলে লাইনম্যানকেই দায়ী করা হয়',
    'কোম্পানির নামে অভিযোগে গ্রাহকের কিছু হয় না',
    'তর্কে হারিয়ে দিলে গ্রাহক আর আসবেন না',
    'ওপরের ধাপগুলো ঝামেলা, এড়িয়ে চলাই ভালো',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, at one dealt consumer's 'পাঠান').
  // Line A is lesson myth 1, line B myth 2 with a shortcut (M7-10 / M8-14).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerCase = CoworkerScript(
    line: 'আমাদের কোম্পানি সরকারি (বা বড় প্রাইভেট), আমাদের নামে কেস করে গ্রাহক কিছু করতে পারবে না।',
    exitLine: coworkerExit,
    right: ['না, তারা গ্রাহক-বান্ধব, রায় মানতেই হয়', 'না, গাফিলতি হলে রায় গ্রাহকের পক্ষেই যায়', 'না, অম্বুডসম্যানের রায় কোম্পানি মানবেই'],
    wrong: [
      'ঠিক, গ্রাহক কিছুই করতে পারবে না আর',
      'হ্যাঁ, কেস করলেও কোম্পানির কিছু হয় না',
      'তাই তো, গ্রাহক অতদূর যাবেই না তো',
      'ঠিক বলেছ, ওকে ঘুরিয়ে বিদায় করে দিই',
      'আচ্ছা, তাহলে তর্ক করেই বিদায় করে দিই',
    ],
    asks: ['কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'ওর কথা রাখবেন?'],
  );
  static const coworkerJob = CoworkerScript(
    line: 'লাইনম্যানের নামে কমপ্লেইন করলেই তার চাকরি যাবে। বলে দাও কালই হয়ে যাবে।',
    exitLine: coworkerExit,
    right: ['না, SoP মেনে চললে ভয় নেই, মিথ্যা বলব না', 'না, তদন্ত ছাড়া চাকরি যায় না, কথা দেব না', 'না, নিশ্চিত না হলে “কালই” বলব না'],
    wrong: [
      'ঠিক, তাহলে বলে দিই কালই হয়ে যাবে',
      'হ্যাঁ, কথা দিয়ে এখনকার মতো সামলাই',
      'তাই বলি, কালই হয়ে যাবে, বলে দিই',
      'ঠিক, চাকরি যাবে, তাই কথা দিয়ে দিই',
      'আচ্ছা, ওকে ভয় দেখিয়ে বিদায় করি দাদা',
    ],
    asks: ['কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'ওর কথা রাখবেন?'],
  );
  static const allCoworkers = [coworkerCase, coworkerJob];
  static const callHeld = 'ঠিক! সত্যি কথা আর সঠিক ধাপ — এটাই আমাদের পথ।';

  static const allSet = 'তিন গ্রাহকই শান্ত — রাগ নয়, ঠিক রাস্তা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — তর্ক নয়, ঠিক ধাপ আর সত্যি কথা।';

  // "আজ যা ধরলেন".
  static const caughtDocket = 'ডকেট আগে';
  static const caughtRights = 'CGRF-এর অধিকার';
  static const caughtOmbud = 'অম্বুডসম্যানের ধাপ';
  static const caughtHonest = 'মিথ্যা কথা নয়';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new push (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => {
        intro,
        ...tasks,
        needFile,
        ...tapWhy,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M8GrievanceReplyMistakes.all) m.textBn,
      }.toList();
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M8GrievanceReplyMistakes {
  static const _dir = 'assets/game/art/m8_grievance_reply';

  // DRAFT wording — owner (M6-12). No deadly mistake in 8.6 (M8-1).
  static const skipAhead = DoMistake(
    key: '8.6/m8_grievance_reply/skip-ahead',
    textBn: 'এক লাফে ওপরের ধাপে নয়। আগে ডকেট, তারপর CGRF, তারপর অম্বুডসম্যান — ক্রমে যেতে হয়।',
    art: '$_dir/skip_ahead.svg',
    lessonPoint: 2,
  );
  static const stepBehind = DoMistake(
    key: '8.6/m8_grievance_reply/step-behind',
    textBn: 'যে ধাপ গ্রাহক পার হয়ে এসেছেন, সেখানে ফেরাবেন না। তাঁর পরের ধাপটা দেখান।',
    art: '$_dir/step_behind.svg',
    lessonPoint: 0,
  );
  static const verbal = DoMistake(
    key: '8.6/m8_grievance_reply/verbal',
    textBn: 'মুখে বলা অভিযোগের কোনো দাম নেই। ডকেট নম্বর তৈরি না হলে আইনের চোখে সমস্যাই নেই।',
    art: '$_dir/verbal.svg',
    lessonPoint: 0,
  );
  static const falsePromise = DoMistake(
    key: '8.6/m8_grievance_reply/false-promise',
    textBn: '“কালই হয়ে যাবে” বলবেন না, যদি নিশ্চিত না হন। কথা না রাখলে অভিযোগ আরও বড় হয়।',
    art: '$_dir/false_promise.svg',
  );
  static const arguing = DoMistake(
    key: '8.6/m8_grievance_reply/arguing',
    textBn: 'রাগী গ্রাহকের সঙ্গে তর্ক নয়। বলুন, “স্যার, আপনার অধিকার আছে CGRF-এ যাওয়ার।”',
    art: '$_dir/arguing.svg',
    lessonPoint: 2,
  );
  static const caseMyth = DoMistake(
    key: '8.6/m8_grievance_reply/case-myth',
    textBn: 'ভুল ধারণা। WBERC আর অম্বুডসম্যান গ্রাহক-বান্ধব; কোম্পানির গাফিলতি হলে গ্রাহকের পক্ষেই রায় দেয়।',
    art: '$_dir/case_myth.svg',
    lessonPoint: 3,
  );
  static const finalWord = DoMistake(
    key: '8.6/m8_grievance_reply/final-word',
    textBn: 'CGRF-এর পরেও পথ আছে। খুশি না হলে গ্রাহক WBERC-এর অম্বুডসম্যানের কাছে যান।',
    art: '$_dir/final_word.svg',
    lessonPoint: 3,
  );
  static const noComplain = DoMistake(
    key: '8.6/m8_grievance_reply/no-complain',
    textBn: 'কমপ্লেইন করা গ্রাহকের অধিকার, আটকাবেন না। নিয়ম মেনে কাজ করলে ভয় নেই।',
    art: '$_dir/no_complain.svg',
    lessonPoint: 2,
  );
  static const wrongForum = DoMistake(
    key: '8.6/m8_grievance_reply/wrong-forum',
    textBn: 'এটা গ্রাহকের ধাপ নয়। ডকেট, তারপর CGRF, তারপর অম্বুডসম্যান — ক্রম মিলিয়ে বলুন।',
    art: '$_dir/wrong_forum.svg',
    lessonPoint: 0,
  );
  // Lesson 8.6 myths 1 and 2 (his pushes) and their realities.
  static const listenCase = DoMistake(
    key: '8.6/m8_grievance_reply/listen-case',
    textBn: '“কেস করে গ্রাহক কিছু করতে পারবে না” — ভুল। WBERC আর অম্বুডসম্যানের রায় কোম্পানিকে মানতেই হয়।',
    art: '$_dir/listen_case.svg',
  );
  static const listenJob = DoMistake(
    key: '8.6/m8_grievance_reply/listen-job',
    textBn: '“কমপ্লেইন করলেই চাকরি যাবে” — না। নিয়ম মেনে কাজ করলে ভয় নেই; আর মিথ্যা কথা দেবেন না।',
    art: '$_dir/listen_job.svg',
  );

  static DoMistake forTrap(M8Trap t) => switch (t) {
        M8Trap.verbal => verbal,
        M8Trap.promise => falsePromise,
        M8Trap.argue => arguing,
        M8Trap.caseMyth => caseMyth,
        M8Trap.finalWord => finalWord,
        M8Trap.noComplain => noComplain,
        M8Trap.wrongForum => wrongForum,
      };

  static const List<DoMistake> all = [skipAhead, stepBehind, verbal, falsePromise, arguing, caseMyth, finalWord, noComplain, wrongForum, listenCase, listenJob];
}

/// One dealt consumer.
@immutable
class M8Consumer {
  const M8Consumer({required this.stage, required this.look, required this.right, required this.wording, required this.pushWording, this.promiseCoin = false});
  final M8Stage stage;

  /// Index into [kM8Looks].
  final int look;

  /// Stands further to the right in the lane (else left).
  final bool right;

  /// Which of the two wordings he opens with / pushes back with.
  final int wording;
  final int pushWording;

  /// Dealt: ask "why no promise?" where it fits.
  final bool promiseCoin;

  M8Forum get forum => stage.forum;
  String get firstLine => M8GrievanceReplyLines.first[stage]![wording];
  String get pushLine => M8GrievanceReplyLines.push[stage]![pushWording];
}

@immutable
class M8Deal {
  const M8Deal({required this.consumers, required this.coworkerAt, required this.coworker});
  final List<M8Consumer> consumers;

  /// The consumer at whose 'পাঠান' he comes in, and which push (0 case, 1 job).
  final int coworkerAt;
  final int coworker;

  CoworkerScript get script => M8GrievanceReplyLines.allCoworkers[coworker];
}

M8Deal m8Deal(math.Random rng) {
  final stages = [...M8Stage.values]..shuffle(rng);
  final looks = [for (var i = 0; i < kM8Looks.length; i++) i]..shuffle(rng);
  final consumers = [
    for (var i = 0; i < 3; i++)
      M8Consumer(stage: stages[i], look: looks[i], right: rng.nextBool(), wording: rng.nextInt(2), pushWording: rng.nextInt(2), promiseCoin: rng.nextBool()),
  ];
  return M8Deal(consumers: consumers, coworkerAt: rng.nextInt(3), coworker: rng.nextInt(2));
}

/// The three reply cards for a consumer: one honest line for his step, two
/// wrong ones (a trap, or another step's line).
List<ChoiceOption> m8DealReply(M8Stage s, math.Random rng) => dealChoices(M8GrievanceReplyLines.right[s]!, M8GrievanceReplyLines.wrongPool(s), rng);

/// What the reason after a right reply asks about (fits what was done).
M8Why m8WhyFor(M8Consumer c, String reply, {required bool promised}) {
  final lib = M8GrievanceReplyLines.right[c.stage]!;
  return switch (c.stage) {
    M8Stage.noDocket => reply == lib[0] ? M8Why.docket : M8Why.centre,
    M8Stage.hasDocket => M8Why.docket,
    M8Stage.unsolved => c.promiseCoin && !promised ? M8Why.promise : M8Why.cgrf,
    M8Stage.cgrfUnhappy => M8Why.ombud,
    M8Stage.threatLineman => M8Why.fear,
    M8Stage.threatCase => c.promiseCoin && !promised ? M8Why.promise : M8Why.ombud,
  };
}

/// Where a consumer round stands.
enum M8Phase { arriving, speaking, route, pushing, replying, said }

/// The play state (pure logic).
class M8GrievanceRun {
  M8GrievanceRun(this.deal, {math.Random? rng}) : _rng = rng ?? math.Random(1) {
    _startConsumer();
  }
  final M8Deal deal;
  final math.Random _rng;

  int index = 0;
  int slips = 0;
  int consumerSlips = 0;
  final List<String> caught = [];
  M8Phase phase = M8Phase.arriving;

  /// The plank the file sits on (null = in the trainee's hand).
  M8Forum? pinned;

  /// Wrong sends this consumer (a fresh look at the same plank).
  int attempt = 0;

  /// The reply cards (dealt when the file went to the right plank).
  List<ChoiceOption> replyOptions = const [];

  /// Kinds of wrong card taken this consumer.
  final Set<M8Trap> trapped = {};

  /// The reply that settled this consumer.
  String? replied;

  M8Consumer get consumer => deal.consumers[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => consumerSlips == 0;
  bool get roundDone => phase == M8Phase.said;

  void _startConsumer() {
    phase = M8Phase.arriving;
    pinned = null;
    attempt = 0;
    consumerSlips = 0;
    trapped.clear();
    replyOptions = const [];
    replied = null;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    consumerSlips++;
    return m;
  }

  /// He has walked up and speaks.
  void startSpeaking() {
    if (phase == M8Phase.arriving) phase = M8Phase.speaking;
  }

  /// His line was held: the file may move.
  void stopSpeaking() {
    if (phase == M8Phase.speaking) phase = M8Phase.route;
  }

  /// The file dropped on a plank (null = back in the hand). Nothing is judged.
  bool pin(M8Forum? f) {
    if (phase != M8Phase.route) return false;
    pinned = f;
    return true;
  }

  /// 'পাঠান': the right plank → he pushes back once; any other plank → a
  /// slip (a leap ahead, or a step back) and the file goes home.
  /// [ready] false: the file is not on a plank yet.
  ({bool ready, DoMistake? mistake}) sendFile() {
    final p = pinned;
    if (phase != M8Phase.route || p == null) return (ready: false, mistake: null);
    if (p == consumer.forum) {
      phase = M8Phase.pushing;
      return (ready: true, mistake: null);
    }
    pinned = null;
    attempt++;
    final m = _slip(p.index > consumer.forum.index ? M8GrievanceReplyMistakes.skipAhead : M8GrievanceReplyMistakes.stepBehind);
    return (ready: true, mistake: m);
  }

  /// His push-back was held: the reply cards open.
  void openReply() {
    if (phase != M8Phase.pushing) return;
    phase = M8Phase.replying;
    replyOptions = m8DealReply(consumer.stage, _rng);
  }

  /// A reply card: the honest line settles him; any other is its kind's slip.
  /// [ready] false: not the time, or not one of the dealt cards.
  ({bool ready, bool right, DoMistake? mistake, M8Trap? trap}) reply(String text) {
    if (phase != M8Phase.replying || !replyOptions.any((o) => o.textBn == text)) return (ready: false, right: false, mistake: null, trap: null);
    if (M8GrievanceReplyLines.right[consumer.stage]!.contains(text)) {
      phase = M8Phase.said;
      replied = text;
      switch (consumer.forum) {
        case M8Forum.docket:
          _tag(M8GrievanceReplyLines.caughtDocket);
        case M8Forum.cgrf:
          _tag(M8GrievanceReplyLines.caughtRights);
        case M8Forum.ombud:
          _tag(M8GrievanceReplyLines.caughtOmbud);
      }
      if (!trapped.contains(M8Trap.promise) && !trapped.contains(M8Trap.caseMyth)) _tag(M8GrievanceReplyLines.caughtHonest);
      return (ready: true, right: true, mistake: null, trap: null);
    }
    final t = M8GrievanceReplyLines.trapOf(text, consumer.stage)!;
    trapped.add(t);
    return (ready: true, right: false, mistake: _slip(M8GrievanceReplyMistakes.forTrap(t)), trap: t);
  }

  /// The reason that fits this consumer's settled reply.
  M8Why get why => m8WhyFor(consumer, replied ?? M8GrievanceReplyLines.right[consumer.stage]!.first, promised: trapped.contains(M8Trap.promise));

  /// Listened to the coworker (a slip here, never deadly).
  DoMistake pushSlip() => _slip(deal.coworker == 0 ? M8GrievanceReplyMistakes.listenCase : M8GrievanceReplyMistakes.listenJob);

  void next() {
    index++;
    if (!done) _startConsumer();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, captions held for their reading time (~2.5–3.5 s each):
///   a consumer: walk-up ≈ 900, his words ≈ 3500, file + পাঠান ≈ 4000,
///     his push-back ≈ 3500, a reply card ≈ 3500, a reason ≈ 8200   ≈ 23600 × 3
///   + the coworker once ≈ 9600                                      ≈ 80000
/// 85 % ≈ 68000 → 70000 (a builder's estimate; owner may tune).
const m8GrievanceReplyQuickMs = 70000;

@immutable
class M8GrievanceReplyPack {
  const M8GrievanceReplyPack({required this.id, required this.titleBn, this.quickMs = m8GrievanceReplyQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8GrievanceReplyPack> m8GrievanceReplyPacks = {
  'do_8_6_a': M8GrievanceReplyPack(id: 'do_8_6_a', titleBn: M8GrievanceReplyLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8GrievanceReplyProbe {
  static M8GrievanceRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M8GrievanceReplyPage extends StatefulWidget {
  const M8GrievanceReplyPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8GrievanceReplyPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8GrievanceReplyPage> createState() => _M8GrievanceReplyPageState();
}

class _M8GrievanceReplyPageState extends State<M8GrievanceReplyPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GrievanceRunPage(
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

class _GrievanceRunPage extends ConsumerStatefulWidget {
  const _GrievanceRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8GrievanceReplyPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GrievanceRunPage> createState() => _GrievanceRunPageState();
}

class _GrievanceRunPageState extends ConsumerState<_GrievanceRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8GrievanceRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  int _speakTok = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  /// What the consumer's bubble shows now (his words, or his reaction).
  String? _bubble;
  var _mood = M8Mood.waiting;

  /// The anger cloud: swells while he speaks, dissolves when he calms.
  double _anger = 0.25;
  var _red = false;
  var _dragging = false;

  // The reply deck (field decision: a wrong card is a slip).
  List<ChoiceOption> _replyOpts = const [];
  final Set<String> _replyWrong = {};
  String? _replyPicked;
  var _replyBusy = false;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _fileKey = GlobalKey();
  final _sendKey = GlobalKey();
  final List<GlobalKey> _rungKeys = [for (var i = 0; i < 3; i++) GlobalKey()];
  int _hintN = 0;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _run = M8GrievanceRun(m8Deal(widget.rng), rng: widget.rng);
    M8GrievanceReplyProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _speakTok++;
    if (identical(M8GrievanceReplyProbe.run, _run)) M8GrievanceReplyProbe.run = null;
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

  M8Consumer get _cons => _run.consumer;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen;

  String get _task => switch (_run.phase) {
        M8Phase.arriving || M8Phase.speaking => M8GrievanceReplyLines.askListen,
        M8Phase.route => _run.pinned == null ? M8GrievanceReplyLines.askRoute : M8GrievanceReplyLines.askSend,
        _ => M8GrievanceReplyLines.askReply,
      };

  Future<void> _start() async {
    _clock.start();
    _startConsumer();
  }

  /// A consumer walks up and speaks; the cloud swells while his caption is
  /// held for a reading time (paused while a card or the coworker is up).
  void _startConsumer() {
    setState(() {
      _wake++;
      _mood = M8Mood.waiting;
      _bubble = null;
      _anger = 0.25;
      _red = false;
      _dragging = false;
      _replyOpts = const [];
      _replyWrong.clear();
      _replyPicked = null;
      _replyBusy = false;
    });
    unawaited(_sayChain([M8GrievanceReplyLines.askListen]));
    unawaited(_speaks(++_speakTok));
  }

  bool get _blocked => _card != null || coworkerOpen || reasonOpen || tableBusy || _intro;

  Future<bool> _wait(int tok, int ms) async {
    var acc = 0;
    while (acc < ms) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || tok != _speakTok || _ended) return false;
      if (_blocked) continue;
      acc += 100;
    }
    return true;
  }

  Future<void> _speaks(int tok) async {
    if (!await _wait(tok, _quiet ? 300 : 900)) return;
    _run.startSpeaking();
    final line = _cons.firstLine;
    setState(() {
      _bubble = line;
      _anger = 1.0;
      _wake++;
    });
    if (!await _wait(tok, MascotSpeechLibrary.readHold(line).inMilliseconds + 500)) return;
    _run.stopSpeaking();
    if (!mounted) return;
    setState(() => _steps++);
    if (_run.index == _run.deal.coworkerAt && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([M8GrievanceReplyLines.askRoute]));
  }

  /// The right plank was sent: he pushes back once, then the reply deck opens.
  Future<void> _pushes(int tok) async {
    final line = _cons.pushLine;
    setState(() {
      _bubble = line;
      _mood = M8Mood.waiting;
      _wake++;
    });
    if (!await _wait(tok, MascotSpeechLibrary.readHold(line).inMilliseconds + 400)) return;
    if (!mounted) return;
    setState(() {
      _run.openReply();
      _replyOpts = _run.replyOptions;
      _replyWrong.clear();
      _replyPicked = null;
      _steps++;
      _wake++;
    });
    unawaited(_sayChain([M8GrievanceReplyLines.askReply]));
  }

  /// The coworker's consumer: 'পাঠান' waits for him once he is due.
  bool _waitForHim() => _run.index == _run.deal.coworkerAt && holdForCoworker();

  // --- hands on -----------------------------------------------------------------
  void _tapScene() {
    if (!_canPlay) return;
    _hints.missTap();
  }

  /// The file dropped on plank [f] (null = back in the hand).
  void _pin(M8Forum? f) {
    _dragging = false;
    if (!_canPlay) return;
    final before = _run.pinned;
    if (!_run.pin(f) || before == f) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _steps++);
    if (f != null) unawaited(_sayChain([M8GrievanceReplyLines.askSend]));
  }

  void _sendTap(Offset at) {
    if (!_canPlay || _run.phase != M8Phase.route) return;
    if (_run.pinned == null) {
      _tick();
      unawaited(_sayChain([M8GrievanceReplyLines.needFile]));
      return;
    }
    if (_waitForHim()) return;
    final r = _run.sendFile();
    if (!r.ready) return;
    _tick('sounds/intro/click.ogg', 0.6);
    if (r.mistake == null) {
      setState(() {
        _steps++;
        _wake++;
      });
      unawaited(_pushes(++_speakTok));
      return;
    }
    setState(() {
      _mood = M8Mood.upset;
      _anger = 1.15;
      _red = true;
      _bubble = M8GrievanceReplyLines.routeReaction;
      _steps++;
      _wake++;
    });
    unawaited(_mistake(r.mistake!, at));
  }

  Future<void> _pickReply(ChoiceOption o, Offset origin) async {
    if (!_canPlay || _run.phase != M8Phase.replying || _replyBusy || _replyWrong.contains(o.textBn) || _replyPicked != null) return;
    _hush();
    final r = _run.reply(o.textBn);
    if (!r.ready) return;
    if (!r.right) {
      setState(() {
        _replyWrong.add(o.textBn);
        _mood = M8Mood.upset;
        _anger = 1.15;
        _red = true;
        _bubble = M8GrievanceReplyLines.trapReaction[r.trap!];
        _wake++;
      });
      unawaited(_mistake(r.mistake!, origin));
      return;
    }
    _replyBusy = true;
    setState(() => _replyPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    setState(() {
      _mood = M8Mood.calm;
      _anger = 0;
      _red = false;
      _bubble = M8GrievanceReplyLines.calmReaction[widget.rng.nextInt(M8GrievanceReplyLines.calmReaction.length)];
      _replyOpts = const [];
      _replyBusy = false;
      _steps++;
      _wake++;
    });
    unawaited(_replyDone());
  }

  Future<void> _replyDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.why;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M8GrievanceReplyLines.whyRight[topic]!, M8GrievanceReplyLines.myths, widget.rng),
      question: M8GrievanceReplyLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    _speakTok++;
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startConsumer();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
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
      if (!mounted || _ended || _run.index != idx) return;
      _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _run.deal.script;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerAt || _run.phase.index >= M8Phase.pushing.index) return null;
    if (_intro || _card != null || tableBusy || _dragging || _run.phase != M8Phase.route || _run.pinned == null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8GrievanceReplyLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8GrievanceReplyLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8GrievanceReplyLines.tapWhy[_nudgeN++ % M8GrievanceReplyLines.tapWhy.length]
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8grievance/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same consumer goes on from where he was: the file goes home after a
    // wrong plank, the deck stays (its wrong card red) after a wrong card.
    _hush();
    setState(() {
      _card = null;
      _mood = M8Mood.waiting;
      _anger = 1.0;
      _red = false;
      _wake++;
    });
    unawaited(_sayChain([_task]));
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
    await _say(!_run.passed ? M8GrievanceReplyLines.fail : (_quickBonus ? M8GrievanceReplyLines.quick : M8GrievanceReplyLines.allSet),
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
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. The file waiting: a sweep
  /// over the three planks, next idle a nudge up from the file (a generic way,
  /// not at a plank); the file on a plank: a tap on 'পাঠান' (the one way on).
  /// None while he speaks, a card, the deck or the coworker is up.
  HintSpec? _hint() {
    final n = _hintN++;
    if (_run.phase != M8Phase.route) return null;
    if (_run.pinned != null) return HintSpec.tapOn(_sendKey);
    if (n.isEven) return HintSpec.sweepOver(_rungKeys);
    final r = HintSpec.globalRectOf(_fileKey);
    return r == null ? null : HintSpec.drag(r.center, toward: const Offset(0, -1), travel: 56);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M8Geo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final c = _cons;
    final box = geo.consumer(c.right);
    final routing = _run.phase == M8Phase.route && _canPlay;
    final pinned = _run.pinned;
    final fileRect = pinned == null ? geo.file : geo.fileOnRung(pinned.index);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(child: CustomPaint(painter: M8GrievanceWorldPainter(geo: geo))),
      ),
      // A tap on the lane that is nothing (a miss, for the hint).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8GrievanceReplyLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tapScene),
        ),
      ),
      // The three planks of the ladder: all alike, each takes the file.
      for (var i = 0; i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('rung-$i'),
          rect: geo.rung(i),
          child: _Rung(
            key: _rungKeys[i],
            index: i,
            canDrop: routing,
            onDrop: () => _pin(M8Forum.values[i]),
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // The consumer: he walks up from the lane's edge, then stands.
      Positioned.fromRect(
        key: ValueKey('consumer-${_run.index}'),
        rect: box,
        child: IgnorePointer(
          child: _ConsumerFigure(
            key: ValueKey('figure-${_run.index}'),
            look: kM8Looks[c.look],
            mood: _mood,
            faceLeft: !c.right,
            fromRight: c.right,
            quiet: quiet,
          ),
        ),
      ),
      Positioned.fromRect(
        key: ValueKey('cloud-${_run.index}'),
        rect: geo.cloud(c.right),
        child: IgnorePointer(child: _Cloud(anger: _anger, red: _red, quiet: quiet)),
      ),
      if (_bubble != null && !_intro)
        Positioned.fromRect(
          key: const ValueKey('bubble-box'),
          rect: geo.bubble,
          child: IgnorePointer(child: _CaptionBubble(key: ValueKey('bubble-${_run.index}-$_bubble'), text: _bubble!, quiet: quiet, tailX: (box.center.dx - geo.bubble.left).clamp(24.0, 212.0))),
        ),
      // Home of the file: dropping it here takes it off a plank.
      Positioned.fromRect(
        key: const ValueKey('file-home'),
        rect: geo.file.inflate(16),
        child: DragTarget<String>(
          onWillAcceptWithDetails: (_) => routing,
          onAcceptWithDetails: (_) => _pin(null),
          builder: (_, _, _) => const SizedBox.expand(),
        ),
      ),
      // The case file: in the trainee's hand, or on a plank.
      Positioned.fromRect(
        key: const ValueKey('file'),
        rect: fileRect,
        child: _FileProp(
          key: _fileKey,
          canDrag: routing,
          onDragStart: () => _dragging = true,
          onDragEnd: () => _dragging = false,
          onTap: _tapScene,
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
    final replyUp = _run.phase == M8Phase.replying && _replyOpts.isNotEmpty;
    final deckUp = reasonOpen || coworkerChoiceUp || (replyUp && playing);
    final handsOn = playing && _card == null && !deckUp && !coworkerOpen && !tableBusy;
    final hintOn = handsOn && _run.phase == M8Phase.route;
    final sendUp = playing && _run.phase == M8Phase.route && _run.pinned != null && !deckUp;
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
              labels: [for (var i = 0; i < 3; i++) M8GrievanceReplyLines.consumer(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintOn,
            hintKey: '${_run.index}/${_run.phase.name}/$_steps/${_run.attempt}/${_run.pinned?.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (sendUp)
                Positioned(
                  key: const ValueKey('hud-send'),
                  left: 24,
                  bottom: pad.bottom + 40,
                  child: _SendButton(key: _sendKey, onTap: _sendTap),
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
                                key: ValueKey('reply-deck-${_run.index}'),
                                options: _replyOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _replyWrong,
                                picked: _replyPicked,
                                onPick: (o, at) => unawaited(_pickReply(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : 96),
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
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
                  line: M8GrievanceReplyLines.intro,
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

/// A consumer, sliding in from the lane's edge once, then still.
class _ConsumerFigure extends StatelessWidget {
  const _ConsumerFigure({super.key, required this.look, required this.mood, required this.faceLeft, required this.fromRight, required this.quiet});
  final M8Look look;
  final M8Mood mood;
  final bool faceLeft;
  final bool fromRight;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final fig = RepaintBoundary(child: CustomPaint(painter: M8ConsumerPainter(look: look, mood: mood, faceLeft: faceLeft), size: Size.infinite));
    if (quiet) return fig;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: 1 - v * 0.8, child: Transform.translate(offset: Offset((fromRight ? 1 : -1) * v * 90, 0), child: child)),
      child: fig,
    );
  }
}

/// The anger cloud: eases to its new size (a one-shot, then still).
class _Cloud extends StatelessWidget {
  const _Cloud({required this.anger, required this.red, required this.quiet});
  final double anger;
  final bool red;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: anger),
      duration: quiet ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, v, _) => RepaintBoundary(child: CustomPaint(painter: M8CloudPainter(anger: v, red: red), size: Size.infinite)),
    );
  }
}

/// A consumer's words, as a caption bubble with a tail toward him.
class _CaptionBubble extends StatelessWidget {
  const _CaptionBubble({super.key, required this.text, required this.quiet, required this.tailX});
  final String text;
  final bool quiet;
  final double tailX;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, height: 1.3, color: const Color(0xFF2A2018))),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(padding: EdgeInsets.only(left: tailX - 8), child: const CustomPaint(size: Size(16, 10), painter: _TailPainter())),
        ),
      ],
    );
    // A long caption shrinks to fit its box rather than overflow it.
    final fitted = LayoutBuilder(
      builder: (_, box) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(width: box.maxWidth, child: body),
      ),
    );
    return Semantics(
      label: text,
      child: Align(
        alignment: Alignment.topCenter,
        child: quiet
            ? fitted
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, alignment: Alignment.bottomCenter, child: child),
                child: fitted,
              ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(0, -2)
      ..lineTo(s.width, -2)
      ..lineTo(s.width / 2, s.height)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFFFFBF0));
    final edge = Paint()
      ..color = const Color(0xFF8A6A3C)
      ..strokeWidth = 2;
    c.drawLine(const Offset(0, 0), Offset(s.width / 2, s.height), edge);
    c.drawLine(Offset(s.width, 0), Offset(s.width / 2, s.height), edge);
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// One plank of the ladder: all three alike (one wood, one size); a file
/// dropped here sits on it (the page draws the file over the plank's end).
class _Rung extends StatelessWidget {
  const _Rung({super.key, required this.index, required this.canDrop, required this.onDrop});
  final int index;
  final bool canDrop;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => canDrop,
      onAcceptWithDetails: (_) => onDrop(),
      builder: (_, cand, _) {
        final hot = cand.isNotEmpty;
        return Semantics(
          label: M8GrievanceReplyLines.rungNames[index],
          child: Container(
            padding: const EdgeInsets.only(left: 5, right: 31),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9C7448), Color(0xFF6E4E2E)]),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: hot ? SlmColors.gold300 : const Color(0xFF3C2A18), width: hot ? 2.4 : 1.6),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 2))],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(M8GrievanceReplyLines.rungShown[index], style: bangla(fontSize: 11, fontWeight: FontWeight.w900, height: 1.15, color: const Color(0xFFFFF4D8))),
            ),
          ),
        );
      },
    );
  }
}

/// The case file: a manila folder, dragged from the trainee's hand (or from a
/// plank) to a plank.
class _FileProp extends StatelessWidget {
  const _FileProp({super.key, required this.canDrag, required this.onDragStart, required this.onDragEnd, required this.onTap});
  final bool canDrag;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;

  Widget _folder({bool lifted = false, bool ghost = false}) => Opacity(
        opacity: ghost ? 0.3 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE9C77E),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 1.6),
            boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 9 : 3, offset: Offset(0, lifted ? 6 : 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 5), child: Container(height: 2, color: const Color(0x663A2A16))),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M8GrievanceReplyLines.fileLabel,
      button: true,
      child: Draggable<String>(
        data: 'file',
        maxSimultaneousDrags: canDrag ? 1 : 0,
        onDragStarted: onDragStart,
        onDragEnd: (_) => onDragEnd(),
        onDraggableCanceled: (_, _) => onDragEnd(),
        feedback: Material(color: Colors.transparent, child: SizedBox(width: 34, height: 42, child: _folder(lifted: true))),
        childWhenDragging: _folder(ghost: true),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: _folder()),
      ),
    );
  }
}

/// 'পাঠান'.
class _SendButton extends StatelessWidget {
  const _SendButton({super.key, required this.onTap});
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8GrievanceReplyLines.send,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          width: 120,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7D774), Color(0xFFD9A441)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 1.8),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(M8GrievanceReplyLines.send, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
        ),
      ),
    );
  }
}
