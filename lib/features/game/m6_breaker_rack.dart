import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'm6_breaker_rack_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_breaker_rack_world.dart' show M6RackFace, M6RackGeo, M6RackPos, m6RackControlOn, m6RackPosAt;

// Lesson 6.2 "সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা", কাজ 2 "তিন অবস্থান"
// (pack do_6_2_b, engineType m6_breaker_rack). A breaker room; three jobs,
// each on its own feeder panel, in dealt order; every breaker is OFF (the
// docket says so; interlocks are not scored — the lesson is silent):
//
//  রক্ষণাবেক্ষণ (point 4): crank the truck to ISOLATED (power and control
//    both out) and 'খুলে কাজ ধরি'. Hands-on in SERVICE = deadly (R6); in
//    TEST = slip (R7: the control circuit is still connected).
//  অন-অফ পরীক্ষা (points 3–4): crank to TEST and 'পরীক্ষা করি' (in SERVICE
//    or ISOLATED = slip, R36); then ON and OFF on the panel. Some plays the
//    spring flag reads DISCHARGED (it did not charge by itself, pro tip 2):
//    fit the manual handle, stroke it down until the flag reads CHARGED.
//    ON with the flag at DISCHARGED = slip (R36).
//  সার্ভিসে ফেরত (point 3): look at the TRIP CIRCUIT HEALTHY lamp (it lights
//    only with the control plug in: TEST or SERVICE). Lit → crank to SERVICE
//    and 'সার্ভিসে দিই'; dark → 'রিপোর্ট করি' (the spec's proposal, owner).
//    A dark breaker put into service = slip (R36); 'সার্ভিসে দিই' out of
//    SERVICE = slip; a lit breaker reported = slip (R32); a report before
//    the lamp could be seen costs nothing: the guide says to look first.
//
// The core verb is the crank: a circular drag turns it (one turn = one
// position step), the window rolls SERVICE · TEST · ISOLATED past one pointer
// with no detent, colour or click, it stops anywhere and turns freely both
// ways; the truck rolls behind the glass. The four actions are the same four
// buttons on every job (two-step: preview, then ✓). Any action that does not
// fit the docket = slip (wrong job); a report on a sound breaker = R32.
//
// Deadly (module 6 table R6, ruling X2/B1): hands-on with the truck in
// SERVICE — by the player's own 'খুলে কাজ ধরি' or by listening to the
// coworker's (a) 'সবুজ জ্বলছে, এখানেই খুলে কাজ সারো' (dealt only on a
// maintenance panel that starts in SERVICE). His (b) 'টেস্ট পর্যন্ত টানলেই
// হবে' = slip (R7), also only where the truck still stands in SERVICE; his
// (c), lesson myth 2 (feed the line through the isolator while the breaker
// is in repair) = slip, dealt on a maintenance panel or on a return job whose
// HEALTHY lamp already shows dark (truck in TEST) — never on a sound breaker.
// Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_breaker_rack_world.dart), corner guide, a right job puts ◆
// on the table → "কেন …?" → the next panel; the coworker once a play at the
// start of a dealt job (after its docket is read; the crank, the actions and
// the panel buttons wait for him: holdForCoworker). Gesture hands: a tap on
// the docket (the one way on), a short rocking nudge on the crank grip (both
// ways in turn, never a full turn), a sweep over the crank and the four
// actions, a sweep over ON, OFF and the socket, a downward swipe on the
// fitted handle — never the answer.

// ============================================================================
// Content
// ============================================================================

/// The three jobs (one per panel).
enum M6RackJobKind { maintain, onOff, toService }

/// The four actions (always the same four, alike).
enum M6RackAction { work, test, service, report }

/// The coworker's push (one per play, at the start of a fitting job).
enum M6RackPush { greenHere, testEnough, isolator }

/// What a job's reason asks about.
enum M6RackWhy { rackOut, testPos, spring, healthy, report }

/// The lesson point (0-based) that teaches a job.
int m6RackLessonPoint(M6RackJobKind k) => switch (k) {
      M6RackJobKind.maintain => 3,
      M6RackJobKind.onOff => 3,
      M6RackJobKind.toService => 2,
    };

abstract final class M6BreakerRackLines {
  static const title = 'তিন অবস্থান';
  // DRAFT wording — owner (M6-12).
  static const intro = 'ব্রেকারের তিনটে কাজ — প্রতিটার জন্য ট্রলি ঠিক জায়গায় আনুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askDocket = 'ডকেটটা দেখুন — কী কাজ, লেখা আছে।';
  static const askTest = 'এবার ON-OFF করে পরীক্ষা করুন।';
  static const docketFirst = 'আগে ডকেটটা দেখুন।';
  static const midway = 'ট্রলি মাঝপথে — কোনো অবস্থানে বসেনি।';
  static const lookFirst = 'আগে টেস্ট পজিশনে এনে হেলদি বাতি দেখুন।';
  static String askJob(M6RackJobKind k) => switch (k) {
        M6RackJobKind.maintain => 'ডকেট: রক্ষণাবেক্ষণ। ট্রলি ঠিক জায়গায় এনে কাজটা করুন।',
        M6RackJobKind.onOff => 'ডকেট: ON-OFF পরীক্ষা। ট্রলি ঠিক জায়গায় এনে কাজটা করুন।',
        M6RackJobKind.toService => 'ডকেট: সার্ভিসে ফেরত। ট্রলি ঠিক জায়গায় এনে কাজটা করুন।',
      };
  static List<String> get tasks => [askDocket, askTest, for (final k in M6RackJobKind.values) askJob(k)];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The docket and the panel (a worker's own words).
  static const docket = 'ডকেট';
  static const docketOff = 'ব্রেকার: OFF';
  static String feeder(int n) => enDigits('ফিডার $n');
  static String job(M6RackJobKind k) => switch (k) {
        M6RackJobKind.maintain => 'রক্ষণাবেক্ষণ',
        M6RackJobKind.onOff => 'ON-OFF পরীক্ষা',
        M6RackJobKind.toService => 'সার্ভিসে ফেরত',
      };
  static const sceneLabel = 'ব্রেকার প্যানেল';
  static const crankLabel = 'র‍্যাকিং ক্র্যাঙ্ক';

  /// The four actions: about the same length, the same for every job.
  static String action(M6RackAction a) => switch (a) {
        M6RackAction.work => 'খুলে কাজ ধরি',
        M6RackAction.test => 'পরীক্ষা করি',
        M6RackAction.service => 'সার্ভিসে দিই',
        M6RackAction.report => 'রিপোর্ট করি',
      };

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M6RackWhy, String>{
    M6RackWhy.rackOut: 'কেন র‍্যাক-আউট করে তবেই হাত দিলেন?',
    M6RackWhy.testPos: 'ON-OFF পরীক্ষা কেন টেস্ট পজিশনে?',
    M6RackWhy.spring: 'ON টেপার আগে কেন স্প্রিং চার্জ করলেন?',
    M6RackWhy.healthy: 'সার্ভিসে দেওয়ার আগে কেন হেলদি বাতি দেখলেন?',
    M6RackWhy.report: 'কেন রিপোর্ট করলেন, সার্ভিসে দিলেন না?',
  };
  static const whyRight = <M6RackWhy, List<String>>{
    M6RackWhy.rackOut: ['আইসোলেটেডে পাওয়ার আর কন্ট্রোল দুটোই বিচ্ছিন্ন', 'র‍্যাক-আউটে ব্রেকার পুরো বিচ্ছিন্ন, কাজ নিরাপদ'],
    M6RackWhy.testPos: ['টেস্টে মূল পাওয়ার কাটা, কন্ট্রোল তখনও যুক্ত', 'টেস্ট পজিশনে বাইরে থেকেই ON-OFF করা যায়'],
    M6RackWhy.spring: ['স্প্রিং-এর জমানো শক্তিতেই ব্রেকার অপারেট করে', 'ফ্ল্যাগ বলছিল স্প্রিং পরের অপারেশনে তৈরি নয়'],
    M6RackWhy.healthy: ['হেলদি বাতি বলে ট্রিপ করানোর সার্কিট ঠিক আছে', 'ট্রিপ সার্কিট ঠিক কি না, হেলদি বাতিই দেখায়'],
    M6RackWhy.report: ['হেলদি বাতি নেভা — ট্রিপ করানোর সার্কিট ঠিক নেই', 'ট্রিপ সার্কিট ঠিক নেই, এমন ব্রেকার সার্ভিসে নয়'],
  };
  static const myths = [
    'সবুজ বাতি জ্বললেই হাত দেওয়া পুরো নিরাপদ',
    'ব্রেকার OFF থাকলে অবস্থান দেখার দরকার নেই',
    'যেকোনো সুইচই তো সার্কিট ব্রেকারের কাজ করে',
    'ট্রিপ করেছে মানেই লাইনে কোনো ভোল্টেজ নেই',
    'হেলদি বাতি শুধু সাজানোর, কাজের কিছু নয়',
    'তাড়াতাড়ি সারতে যেখানে আছে সেখানেই ভালো',
    'স্প্রিং যেমনই থাকুক, ON টিপলেই চলে যায়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, at the start of a fitting job).
  // DRAFT wording — owner (M6-12): his three pushes are the spec's.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerGreen = CoworkerScript(
    line: 'ঝামেলা কোরো না, ব্রেকার তো OFF — সবুজ জ্বলছে, এখানেই খুলে কাজ সারো!',
    exitLine: coworkerExit,
    right: ['না, আগে র‍্যাক-আউট করে তবেই হাত', 'না, সবুজ মানেই কাজের জন্য নিরাপদ নয়', 'না, সার্ভিসে থাকা ব্রেকারে হাত নয়'],
    wrong: [
      'ঠিক, সবুজ জ্বলছে, এখানেই খুলি',
      'আচ্ছা, OFF তো, এখানেই কাজ সারি',
      'হ্যাঁ, র‍্যাক-আউটের ঝামেলা কে করে',
      'ঠিক আছে, তাড়াতাড়ি এখানেই ধরি',
      'হ্যাঁ, ব্রেকার OFF মানেই নিরাপদ',
    ],
    asks: ['কী করবেন?', 'ও বলছে এখানেই খুলে কাজ করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerTest = CoworkerScript(
    line: 'টেস্ট পর্যন্ত টানলেই হবে, পাওয়ার তো কাটা — কাজ ধরো।',
    exitLine: coworkerExit,
    right: ['না, পুরো র‍্যাক-আউট করে তবেই কাজ', 'না, টেস্টে কন্ট্রোল তখনও যুক্ত', 'না, আইসোলেটেড না করে হাত নয়'],
    wrong: [
      'ঠিক, টেস্টেই কাজ ধরে ফেলি',
      'আচ্ছা, পাওয়ার কাটা, ভয় নেই',
      'হ্যাঁ, পুরো টানার দরকার নেই',
      'ঠিক আছে, টেস্ট পর্যন্তই টানি',
      'হ্যাঁ, এতেই যথেষ্ট নিরাপদ',
    ],
    asks: ['কী করবেন?', 'ও বলছে টেস্টেই কাজ ধরতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerIsolator = CoworkerScript(
    line: 'ব্রেকার মেরামতে থাক, আইসোলেটর দিয়েই ফিডার চালিয়ে দাও — যেকোনো সুইচই তো সার্কিট ব্রেকার।',
    exitLine: coworkerExit,
    right: ['না, ফল্ট কাটতে পারে শুধু ব্রেকার', 'না, আইসোলেটর শুধু OFF-লোডে চলে', 'না, ব্রেকার ছাড়া ফিডার চালাব না'],
    wrong: [
      'ঠিক, আইসোলেটর দিয়েই চালাই',
      'আচ্ছা, সব সুইচই তো এক কাজ করে',
      'হ্যাঁ, ব্রেকার পরে দেখা যাবে',
      'ঠিক আছে, আইসোলেটরই যথেষ্ট',
      'হ্যাঁ, ফিডার চালু হলেই হলো',
    ],
    asks: ['কী করবেন?', 'ও বলছে আইসোলেটরেই ফিডার চালাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6RackPush p) => switch (p) {
        M6RackPush.greenHere => coworkerGreen,
        M6RackPush.testEnough => coworkerTest,
        M6RackPush.isolator => coworkerIsolator,
      };
  static const allCoworkers = [coworkerGreen, coworkerTest, coworkerIsolator];

  static String callHeld(M6RackPush p) => switch (p) {
        M6RackPush.greenHere => 'ঠিক! সবুজ মানেই নিরাপদ নয় — আগে র‍্যাক-আউট।',
        M6RackPush.testEnough => 'ঠিক! টেস্টে কন্ট্রোল যুক্ত — পুরো র‍্যাক-আউট চাই।',
        M6RackPush.isolator => 'ঠিক! ফল্ট কারেন্ট কাটতে পারে শুধু সার্কিট ব্রেকার।',
      };

  static const allSet = 'তিন ব্রেকারেই ট্রলি ঠিক জায়গায় — নিরাপদ কাজ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে ডকেট, তারপর ট্রলির অবস্থান, তারপর কাজ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtRackOut = 'র‍্যাক-আউট করে তবেই হাত';
  static const caughtTest = 'ON-OFF পরীক্ষা টেস্ট পজিশনে';
  static const caughtSpring = 'স্প্রিং চার্জ দেখে তবে ON';
  static const caughtHealthy = 'হেলদি বাতি দেখে সার্ভিসে';
  static const caughtReport = 'হেলদি বাতি নেভা — রিপোর্ট';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askDocket,
        askTest,
        docketFirst,
        midway,
        lookFirst,
        for (final k in M6RackJobKind.values) askJob(k),
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        for (final p in M6RackPush.values) callHeld(p),
        allSet,
        fail,
        for (final m in M6BreakerRackMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M6BreakerRackMistakes {
  static const _dir = 'assets/game/art/m6_breaker_rack';

  // DRAFT wording — owner (M6-12).
  static const handsService = DoMistake(
    key: '6.2/m6_breaker_rack/hands-service',
    textBn: 'সার্ভিস পজিশনে ব্রেকার সার্কিটের সাথে পুরো যুক্ত — সবুজ বাতি মানেই নিরাপদ নয়! র‍্যাক-আউট করে আইসোলেটেড অবস্থানে এনে তবেই হাত।',
    art: '$_dir/hands_service.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const handsTest = DoMistake(
    key: '6.2/m6_breaker_rack/hands-test',
    textBn: 'টেস্ট পজিশনে মূল পাওয়ার কাটা, কিন্তু কন্ট্রোল সার্কিট তখনও যুক্ত। রক্ষণাবেক্ষণের কাজ শুধু আইসোলেটেড (র‍্যাক-আউট) অবস্থানে।',
    art: '$_dir/hands_test.svg',
    lessonPoint: 3,
  );
  static const testService = DoMistake(
    key: '6.2/m6_breaker_rack/test-service',
    textBn: 'সার্ভিস পজিশনে ব্রেকার সার্কিটের সাথে পুরো যুক্ত। বাইরে থেকে ON-OFF পরীক্ষা টেস্ট পজিশনে — মূল পাওয়ার কাটা, কন্ট্রোল যুক্ত।',
    art: '$_dir/test_pos.svg',
    lessonPoint: 3,
  );
  static const testIsolated = DoMistake(
    key: '6.2/m6_breaker_rack/test-isolated',
    textBn: 'আইসোলেটেড অবস্থানে কন্ট্রোল সার্কিটও বিচ্ছিন্ন — ON-OFF হবে না। পরীক্ষার জন্য ট্রলি টেস্ট পজিশনে আনুন।',
    art: '$_dir/test_pos.svg',
    lessonPoint: 3,
  );
  static const springFlat = DoMistake(
    key: '6.2/m6_breaker_rack/spring-flat',
    textBn: 'স্প্রিং ডিসচার্জড দেখাচ্ছে — অপারেট করার শক্তি জমা নেই। আগে হ্যান্ডেল দিয়ে স্প্রিং চার্জ করুন, তারপর ON।',
    art: '$_dir/spring_flat.svg',
    lessonPoint: 2,
  );
  static const darkIn = DoMistake(
    key: '6.2/m6_breaker_rack/dark-in',
    textBn: 'ট্রিপ সার্কিট হেলদি বাতি জ্বলছে না — ট্রিপ করানোর সার্কিট ঠিক নেই। এমন ব্রেকার সার্ভিসে নয়, রিপোর্ট করুন।',
    art: '$_dir/healthy.svg',
    lessonPoint: 2,
  );
  static const litReport = DoMistake(
    key: '6.2/m6_breaker_rack/lit-report',
    textBn: 'হেলদি বাতি জ্বলছে — ট্রিপ সার্কিট ঠিক আছে। অকারণে রিপোর্ট নয়; সার্ভিস পজিশনে এনে সার্ভিসে দিন।',
    art: '$_dir/healthy.svg',
    lessonPoint: 2,
  );
  static const needlessReport = DoMistake(
    key: '6.2/m6_breaker_rack/needless-report',
    textBn: 'ব্রেকারে কোনো গোলমাল পাননি — অকারণে রিপোর্ট করে কাজ থামাবেন না। ডকেটের কাজটাই করুন।',
    art: '$_dir/report.svg',
    lessonPoint: 2,
  );
  static const notInService = DoMistake(
    key: '6.2/m6_breaker_rack/not-in-service',
    textBn: 'ট্রলি সার্ভিস পজিশনে নেই — ব্রেকার এখনও সার্কিটের সাথে যুক্ত হয়নি। সার্ভিস পজিশনে এনে তবে সার্ভিসে দিন।',
    art: '$_dir/not_in_service.svg',
    lessonPoint: 3,
  );
  static const wrongJob = DoMistake(
    key: '6.2/m6_breaker_rack/wrong-job',
    textBn: 'ডকেটের কাজ মিলিয়ে নিন: রক্ষণাবেক্ষণে র‍্যাক-আউট, ON-OFF পরীক্ষা টেস্ট পজিশনে, ফেরত দিতে সার্ভিস পজিশন।',
    art: '$_dir/wrong_job.svg',
    lessonPoint: 3,
  );
  // Lesson 6.2 myth 2 and its reality (not a numbered point).
  static const pushIsolator = DoMistake(
    key: '6.2/m6_breaker_rack/push-isolator',
    textBn: 'আইসোলেটর শুধু লোড ছাড়া (OFF-লোড) খোলা-বন্ধের জন্য — ফল্ট কারেন্ট বাধা দিতে পারে শুধু সার্কিট ব্রেকার। ব্রেকার ছাড়া ফিডার চালু নয়।',
    art: '$_dir/isolator.svg',
    // Owner, 2026-11-15: charging the feeder on the isolator = closing it on
    // load with no fault protection, the class of AB-on-load: deadly.
    deadly: true,
  );

  /// Listening to his push is the act it pushes (X2/B1).
  static DoMistake push(M6RackPush p) => switch (p) {
        M6RackPush.greenHere => handsService,
        M6RackPush.testEnough => handsTest,
        M6RackPush.isolator => pushIsolator,
      };

  static const List<DoMistake> all = [
    handsService,
    handsTest,
    testService,
    testIsolated,
    springFlat,
    darkIn,
    litReport,
    needlessReport,
    notInService,
    wrongJob,
    pushIsolator,
  ];
}

/// One panel and its job.
@immutable
class M6RackJob {
  const M6RackJob({
    required this.kind,
    required this.face,
    required this.feeder,
    required this.start,
    required this.counter,
    this.selfCharge = true,
    this.healthy = true,
  });

  final M6RackJobKind kind;
  final M6RackFace face;
  final int feeder;

  /// Where the truck stands when the job starts (never the job's own place).
  final M6RackPos start;

  /// The operation counter as found.
  final int counter;

  /// অন-অফ পরীক্ষা: the spring charged itself (else the flag reads DISCHARGED).
  final bool selfCharge;

  /// সার্ভিসে ফেরত: the trip circuit is healthy (its lamp lights).
  final bool healthy;

  /// Where the job is done (null: reported, not racked in).
  M6RackPos? get target => switch (kind) {
        M6RackJobKind.maintain => M6RackPos.isolated,
        M6RackJobKind.onOff => M6RackPos.test,
        M6RackJobKind.toService => healthy ? M6RackPos.service : null,
      };
}

@immutable
class M6RackDeal {
  const M6RackDeal({required this.jobs, required this.coworkerJob, required this.push, required this.why});

  /// The three jobs in order (one of each kind).
  final List<M6RackJob> jobs;

  /// The job the coworker comes in at (its start), and his push.
  final int coworkerJob;
  final M6RackPush push;

  /// What each job's reason asks about (fits what was done).
  final List<M6RackWhy> why;
}

/// The starting places a job may be dealt (never its own place).
List<M6RackPos> m6RackStarts(M6RackJobKind k) => switch (k) {
      M6RackJobKind.maintain => const [M6RackPos.service, M6RackPos.test],
      M6RackJobKind.onOff => const [M6RackPos.service, M6RackPos.isolated],
      M6RackJobKind.toService => const [M6RackPos.test, M6RackPos.isolated],
    };

/// The pushes that fit a job's start (his line must fit the moment): "work
/// here, it's green" and "pulling to TEST is enough" only on a maintenance
/// panel still in SERVICE (where the green lamp shows and the truck has yet
/// to be pulled); myth 2 ("leave the breaker in repair, feed through the
/// isolator") on any maintenance panel — the breaker really is going into
/// repair — and on a return job whose HEALTHY lamp shows dark from the start
/// (truck in TEST: the breaker is plainly bound for repair, not service).
/// No push fits the ON/OFF test, a sound return job, or one whose lamp
/// cannot be seen yet (ISOLATED).
List<M6RackPush> m6RackPushesFor(M6RackJob j) => switch (j.kind) {
      M6RackJobKind.maintain => [
          if (j.start == M6RackPos.service) ...[M6RackPush.greenHere, M6RackPush.testEnough],
          M6RackPush.isolator,
        ],
      M6RackJobKind.onOff => const [],
      M6RackJobKind.toService => [if (!j.healthy && j.start == M6RackPos.test) M6RackPush.isolator],
    };

M6RackDeal m6RackDeal(math.Random rng) {
  final kinds = [...M6RackJobKind.values]..shuffle(rng);
  final feeders = [for (var i = 1; i <= 8; i++) i]..shuffle(rng);
  // His push first (each a third of the plays), then the panels; then one
  // panel his push fits (the maintenance panel always does: for (a) and (b)
  // its truck is dealt in SERVICE).
  final push = M6RackPush.values[rng.nextInt(3)];
  final maint = kinds.indexOf(M6RackJobKind.maintain);
  final jobs = <M6RackJob>[];
  final why = <M6RackWhy>[];
  for (final (i, k) in kinds.indexed) {
    final starts = m6RackStarts(k);
    var start = starts[rng.nextInt(starts.length)];
    if (i == maint && push != M6RackPush.isolator) start = M6RackPos.service;
    final selfCharge = k != M6RackJobKind.onOff || rng.nextBool();
    final healthy = k != M6RackJobKind.toService || rng.nextBool();
    jobs.add(M6RackJob(
      kind: k,
      face: M6RackFace.values[rng.nextInt(2)],
      feeder: feeders[i],
      start: start,
      counter: 180 + rng.nextInt(9600),
      selfCharge: selfCharge,
      healthy: healthy,
    ));
    why.add(switch (k) {
      M6RackJobKind.maintain => M6RackWhy.rackOut,
      M6RackJobKind.onOff => !selfCharge && rng.nextBool() ? M6RackWhy.spring : M6RackWhy.testPos,
      M6RackJobKind.toService => healthy ? M6RackWhy.healthy : M6RackWhy.report,
    });
  }
  final fitting = [for (final (i, j) in jobs.indexed) if (m6RackPushesFor(j).contains(push)) i];
  final at = fitting[rng.nextInt(fitting.length)];
  return M6RackDeal(jobs: jobs, coworkerJob: at, push: push, why: why);
}

/// Strokes of the manual handle that charge the spring.
const kM6RackStrokes = 4;

/// The play state (pure logic).
class M6RackRun {
  M6RackRun(this.deal) {
    _startJob();
  }
  final M6RackDeal deal;

  int index = 0;
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The job's right action is in (its reason comes next).
  var roundDone = false;

  /// The job's docket has been read.
  var docketRead = false;

  /// The truck's travel: 0 SERVICE … 1 TEST … 2 ISOLATED.
  double t = 0;

  /// The TRIP CIRCUIT HEALTHY lamp could be seen this job (control plug in).
  var sawHealthy = false;

  /// অন-অফ পরীক্ষা: begun in TEST; the breaker ON now; the spring.
  var testArmed = false;
  var breakerOn = false;
  var springCharged = true;
  var handleFitted = false;
  int strokes = 0;
  var handCharged = false;

  /// ON was pressed at DISCHARGED this job (the spring reason would not fit).
  var springSlipped = false;
  int counter = 0;

  M6RackJob get job => deal.jobs[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => jobSlips == 0;
  bool get _open => !ended && !roundDone;

  /// The position the truck sits in, or null between positions.
  M6RackPos? get pos => m6RackPosAt(t);
  bool get controlOn => m6RackControlOn(t);

  /// The crank turns: the docket read, no test under way, the breaker OFF
  /// (a closed breaker cannot be racked: the interlock, unscored).
  bool get canCrank => _open && docketRead && !testArmed && !breakerOn;

  void _startJob() {
    final j = job;
    t = j.start.index.toDouble();
    sawHealthy = controlOn;
    docketRead = false;
    roundDone = false;
    jobSlips = 0;
    testArmed = false;
    breakerOn = false;
    springCharged = j.selfCharge;
    handleFitted = false;
    strokes = 0;
    handCharged = false;
    springSlipped = false;
    counter = j.counter;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  void readDocket() {
    if (_open) docketRead = true;
  }

  /// Turn the crank by [steps] (one turn = one step; + racks out, which the
  /// page maps to an anticlockwise turn: clockwise racks in). Returns
  /// the travel made (0 at a stop or while it cannot turn).
  double crank(double steps) {
    if (!canCrank) return 0;
    final n = (t + steps).clamp(0.0, kM6RackMax);
    final moved = n - t;
    t = n;
    if (controlOn) sawHealthy = true;
    return moved;
  }

  /// A report on a return job before the HEALTHY lamp could be seen: nothing
  /// happens (the page asks to look first; no cost).
  bool reportUnseen(M6RackAction a) => a == M6RackAction.report && job.kind == M6RackJobKind.toService && !sawHealthy;

  /// One of the four actions, judged where the truck sits. Between positions,
  /// before the docket or before the lamp could be seen (a report) nothing
  /// happens (the page says why).
  DoMistake? act(M6RackAction a) {
    if (!_open || !docketRead || testArmed) return null;
    final p = pos;
    if (p == null) return null;
    final k = job.kind;
    switch (a) {
      case M6RackAction.work:
        if (p == M6RackPos.service) return deadly = M6BreakerRackMistakes.handsService;
        if (p == M6RackPos.test) return _slip(M6BreakerRackMistakes.handsTest);
        if (k != M6RackJobKind.maintain) return _slip(M6BreakerRackMistakes.wrongJob);
        _done();
        return null;
      case M6RackAction.test:
        if (k != M6RackJobKind.onOff) return _slip(M6BreakerRackMistakes.wrongJob);
        if (p == M6RackPos.service) return _slip(M6BreakerRackMistakes.testService);
        if (p == M6RackPos.isolated) return _slip(M6BreakerRackMistakes.testIsolated);
        testArmed = true;
        return null;
      case M6RackAction.service:
        if (k != M6RackJobKind.toService) return _slip(M6BreakerRackMistakes.wrongJob);
        if (p != M6RackPos.service) return _slip(M6BreakerRackMistakes.notInService);
        if (!job.healthy) return _slip(M6BreakerRackMistakes.darkIn);
        _done();
        return null;
      case M6RackAction.report:
        if (k != M6RackJobKind.toService) return _slip(M6BreakerRackMistakes.needlessReport);
        if (!sawHealthy) return null;
        if (job.healthy) return _slip(M6BreakerRackMistakes.litReport);
        _done();
        return null;
    }
  }

  /// ON on the panel (the test under way): with the flag at DISCHARGED a
  /// slip and nothing closes; else the breaker closes (the counter counts;
  /// a spring that charges itself is ready again at once).
  DoMistake? pressOn() {
    if (!_open || !testArmed || breakerOn) return null;
    if (!springCharged) {
      springSlipped = true;
      return _slip(M6BreakerRackMistakes.springFlat);
    }
    breakerOn = true;
    counter++;
    if (!job.selfCharge) springCharged = false;
    return null;
  }

  /// OFF on the panel: the closed breaker opens — the test is done.
  bool pressOff() {
    if (!_open || !testArmed || !breakerOn) return false;
    breakerOn = false;
    _done();
    return true;
  }

  /// The manual handle into its socket (the test job, the spring flat).
  bool fitHandle() {
    if (!_open || job.kind != M6RackJobKind.onOff || springCharged || handleFitted || breakerOn) return false;
    handleFitted = true;
    return true;
  }

  /// One downward stroke of the fitted handle; true when it charged.
  bool stroke() {
    if (!_open || !handleFitted || springCharged) return false;
    strokes++;
    if (strokes >= kM6RackStrokes) {
      springCharged = true;
      handleFitted = false;
      handCharged = true;
      return true;
    }
    return false;
  }

  void _done() {
    roundDone = true;
    switch (job.kind) {
      case M6RackJobKind.maintain:
        _tag(M6BreakerRackLines.caughtRackOut);
      case M6RackJobKind.onOff:
        _tag(M6BreakerRackLines.caughtTest);
        if (handCharged) _tag(M6BreakerRackLines.caughtSpring);
      case M6RackJobKind.toService:
        _tag(job.healthy ? M6BreakerRackLines.caughtHealthy : M6BreakerRackLines.caughtReport);
    }
  }

  /// Listened to a slip-line coworker.
  DoMistake pushSlip(DoMistake m) => _slip(m);

  /// Fails the play (listening to a deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    if (!done) _startJob();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   রক্ষণাবেক্ষণ: docket, crank (1–2 turns ≈ 3000), action + ✓ ≈ 6000
///   অন-অফ: docket, crank, action + ✓, ON, OFF (+ a flat spring: socket and
///     4 strokes ≈ 7500 on half the plays) ≈ 9000–16500
///   সার্ভিসে ফেরত: docket, crank, action + ✓ ≈ 6000
///   + a reason each (~8200 × 3) + the coworker once ≈ 9600       ≈ 59000–66000
/// 85 % ≈ 53000 → 60 s (a builder's estimate; owner may tune).
const m6BreakerRackQuickMs = 60000;

@immutable
class M6BreakerRackPack {
  const M6BreakerRackPack({required this.id, required this.titleBn, this.quickMs = m6BreakerRackQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6BreakerRackPack> m6BreakerRackPacks = {
  'do_6_2_b': M6BreakerRackPack(id: 'do_6_2_b', titleBn: M6BreakerRackLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6BreakerRackProbe {
  static M6RackRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M6BreakerRackPage extends StatefulWidget {
  const M6BreakerRackPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6BreakerRackPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6BreakerRackPage> createState() => _M6BreakerRackPageState();
}

class _M6BreakerRackPageState extends State<M6BreakerRackPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RackRunPage(
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

class _RackRunPage extends ConsumerStatefulWidget {
  const _RackRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6BreakerRackPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RackRunPage> createState() => _RackRunPageState();
}

class _RackRunPageState extends ConsumerState<_RackRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6RackRun _run;
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

  /// The action preview (two-step pick) and the actions set aside.
  M6RackAction? _preview;
  Offset _previewAt = Offset.zero;
  final Set<M6RackAction> _aside = {};

  /// The crank in hand (its last angle) and the ratchet's travel since a tick.
  double? _crankAngle;
  double _ratchet = 0;

  /// A stroke of the fitted handle.
  Offset? _strokeFrom;
  Offset _strokeNow = Offset.zero;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M6RackAction, GlobalKey> _actionKeys = {for (final a in M6RackAction.values) a: GlobalKey()};
  final _crankKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6RackGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6RackRun(m6RackDeal(widget.rng));
    M6BreakerRackProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M6BreakerRackProbe.run, _run)) M6BreakerRackProbe.run = null;
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

  M6RackJob get _job => _run.job;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task => !_run.docketRead
      ? M6BreakerRackLines.askDocket
      : _run.testArmed
          ? M6BreakerRackLines.askTest
          : M6BreakerRackLines.askJob(_job.kind);

  Future<void> _start() async {
    _clock.start();
    _startJob();
  }

  void _startJob() {
    setState(() {
      _wake++;
      _preview = null;
      _aside.clear();
      _crankAngle = null;
      _strokeFrom = null;
    });
    unawaited(_sayChain([_task]));
  }

  /// The coworker's job: once he is due, every control waits for him.
  bool _waitForHim() => _run.index == _run.deal.coworkerJob && holdForCoworker();

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- hands on -----------------------------------------------------------------
  void _readDocket() {
    if (_run.docketRead) {
      _tick();
      unawaited(_sayChain([_task]));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    _run.readDocket();
    if (_run.index == _run.deal.coworkerJob && !coworkerDone && !coworkerDue) scheduleCoworker();
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _needDocket() {
    _tick();
    unawaited(_sayChain([M6BreakerRackLines.docketFirst]));
  }

  void _tapScene(Offset p, M6RackGeo geo, Offset global) {
    if (!_canPlay) return;
    if (M6RackGeo.docket.contains(p)) {
      _readDocket();
      return;
    }
    if (geo.onHit.contains(p)) {
      if (!_run.testArmed) {
        _hints.missTap();
        return;
      }
      if (_waitForHim()) return;
      final m = _run.pressOn();
      if (m != null) {
        setState(() => _wake++);
        unawaited(_mistake(m, global));
        return;
      }
      if (!_run.breakerOn) {
        _hints.missTap();
        return;
      }
      HapticFeedback.mediumImpact();
      _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
      _stepDone();
      return;
    }
    if (geo.offHit.contains(p)) {
      if (_run.testArmed && _waitForHim()) return;
      if (!_run.pressOff()) {
        _hints.missTap();
        return;
      }
      HapticFeedback.mediumImpact();
      _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
      _stepDone();
      unawaited(_jobDone());
      return;
    }
    if (geo.socketHit.contains(p)) {
      if (_job.kind == M6RackJobKind.onOff && _waitForHim()) return;
      if (_run.fitHandle()) {
        _tick('sounds/intro/click.ogg', 0.55);
        _stepDone();
        return;
      }
    }
    _hints.missTap();
  }

  static double _wrap(double a) {
    var x = a;
    while (x > math.pi) {
      x -= 2 * math.pi;
    }
    while (x < -math.pi) {
      x += 2 * math.pi;
    }
    return x;
  }

  void _panStart(Offset p, M6RackGeo geo) {
    _crankAngle = null;
    _strokeFrom = null;
    if (!_canPlay) return;
    if (geo.inCrank(p)) {
      if (!_run.docketRead) {
        _needDocket();
        return;
      }
      if (_waitForHim()) return;
      if (!_run.canCrank) {
        // A closed breaker or a test under way: the crank will not turn.
        HapticFeedback.heavyImpact();
        _hints.missTap();
        return;
      }
      final d = p - geo.crank;
      _crankAngle = math.atan2(d.dy, d.dx);
      setState(() => _wake++);
      return;
    }
    if (_run.handleFitted && geo.strokeHit.contains(p)) {
      if (_waitForHim()) return;
      _strokeFrom = p;
      _strokeNow = p;
    }
  }

  void _panUpdate(Offset p, M6RackGeo geo) {
    final last = _crankAngle;
    if (last != null) {
      if (!_canPlay) {
        _crankAngle = null;
        return;
      }
      final d = p - geo.crank;
      if (d.distance < 4) return;
      final a = math.atan2(d.dy, d.dx);
      final da = _wrap(a - last);
      _crankAngle = a;
      // Clockwise (screen angle up) racks in: toward SERVICE.
      final moved = _run.crank(-da / (2 * math.pi));
      if (moved != 0) {
        _ratchet += moved.abs();
        if (_ratchet >= 0.25) {
          _ratchet = 0;
          _cue('sounds/intro/tick.ogg', volume: 0.3);
        }
        setState(() {});
      }
      return;
    }
    if (_strokeFrom != null) _strokeNow = p;
  }

  void _panEnd() {
    if (_crankAngle != null) {
      _crankAngle = null;
      _stepDone();
      return;
    }
    final from = _strokeFrom;
    _strokeFrom = null;
    if (from == null || !_canPlay) return;
    if (_strokeNow.dy - from.dy < 36) {
      _hints.missTap();
      return;
    }
    final charged = _run.stroke();
    _tick(charged ? 'sounds/learn/tag_slap.ogg' : 'sounds/intro/click.ogg', 0.55);
    _stepDone();
  }

  /// A tap on an action opens it big; nothing is decided yet.
  void _openAction(M6RackAction a, Offset global) {
    if (!_canPlay || _preview != null) return;
    if (!_run.docketRead) {
      _needDocket();
      return;
    }
    setState(() {
      _preview = a;
      _previewAt = global;
    });
  }

  /// ✓ on the preview: the decision.
  void _confirmAction() {
    final a = _preview;
    if (a == null) return;
    setState(() {
      _preview = null;
      _aside.clear();
    });
    _act(a, _previewAt);
  }

  /// ✕: the action is set aside (dimmed), nothing is decided.
  void _rejectAction() {
    final a = _preview;
    if (a == null) return;
    setState(() {
      _preview = null;
      _aside.add(a);
    });
  }

  void _act(M6RackAction a, Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    if (_run.pos == null) {
      _tick();
      unawaited(_sayChain([M6BreakerRackLines.midway]));
      return;
    }
    if (_run.reportUnseen(a)) {
      _tick();
      unawaited(_sayChain([M6BreakerRackLines.lookFirst]));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.act(a);
    if (m != null) {
      if (m.deadly) {
        final geo = _geoNow;
        if (geo != null) _flashAt = geo.flashAt;
      }
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.roundDone) {
      _stepDone();
      unawaited(_jobDone());
      return;
    }
    if (_run.testArmed) {
      _stepDone();
      unawaited(_sayChain([M6BreakerRackLines.askTest]));
    }
  }

  Future<void> _jobDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final dealt = _run.deal.why[_run.index];
    // "Why charge it before ON?" would not fit a play that pressed ON first.
    final topic = dealt == M6RackWhy.spring && _run.springSlipped ? M6RackWhy.testPos : dealt;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6BreakerRackLines.whyRight[topic]!, M6BreakerRackLines.myths, widget.rng),
      question: M6BreakerRackLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
  CoworkerScript get coworkerScript => M6BreakerRackLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerJob || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _freeze || _preview != null || !_run.docketRead) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.deal.push;
    if (!held) {
      final m = M6BreakerRackMistakes.push(p);
      if (m.deadly) {
        final geo = _geoNow;
        if (geo != null) _flashAt = geo.flashAt;
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6BreakerRackLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6BreakerRackLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6BreakerRackLines.tapWhy[_nudgeN++ % M6BreakerRackLines.tapWhy.length]
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
      _preview = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6rack/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Hands on a live breaker: the scene freezes grey and the arc flash comes
  /// off the contacts in colour; then near-miss or death.
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
      _preview = null;
      _crankAngle = null;
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
    final speak = await SpokenOnce.first('m6rack/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6BreakerRackLines.deadlyWord : M6BreakerRackLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? M6BreakerRackLines.fail : (_quickBonus ? M6BreakerRackLines.quick : M6BreakerRackLines.allSet),
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
    if (_passed) return LinemanMode.cheer;
    if (_crankAngle != null || _run.handleFitted) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6RackRig get _rig {
    final j = _job;
    return M6RackRig(
      face: j.face,
      feeder: j.feeder,
      counter: _run.counter,
      controlOn: _run.controlOn,
      breakerOn: _run.breakerOn,
      healthy: j.healthy,
      springCharged: _run.springCharged,
      handleFitted: _run.handleFitted,
      strokes: _run.strokes,
    );
  }

  /// The gesture hand: how to touch, never what. Before the docket is read,
  /// a tap on it (the one way on); in the test, a sweep over ON, OFF and the
  /// socket alike, or a downward swipe on the fitted handle; otherwise, in
  /// turn, a short nudge on the crank's grip (one way, then the other —
  /// never a full turn) and a sweep over the crank and the four actions.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (!_run.docketRead) return HintSpec.tap(M6RackGeo.docket.center, space: HintSpace.scene);
    if (_run.testArmed) {
      if (_run.handleFitted) return HintSpec.swipe(geo.grip, toward: const Offset(0, 1), travel: 50, space: HintSpace.scene);
      return HintSpec.sweep([geo.onHit, geo.offHit, geo.socketHit], space: HintSpace.scene);
    }
    if (n.isEven) {
      final grip = geo.crankGrip(_run.t);
      final tangent = grip - geo.crank;
      final dir = Offset(-tangent.dy, tangent.dx) / tangent.distance * ((n ~/ 2).isEven ? 1.0 : -1.0);
      return HintSpec.drag(grip, toward: dir, travel: 36, space: HintSpace.scene);
    }
    return HintSpec.sweepOver([_crankKey, for (final a in M6RackAction.values) _actionKeys[a]!]);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6RackGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final j = _job;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('panel'),
                child: RepaintBoundary(child: CustomPaint(painter: M6RackPanelPainter(geo: geo, rig: _rig))),
              ),
              Positioned.fill(
                key: const ValueKey('trolley'),
                child: RepaintBoundary(child: CustomPaint(painter: M6RackTrolleyPainter(geo: geo, t: _run.t, face: j.face))),
              ),
              Positioned.fromRect(
                key: ValueKey('docket-${_run.index}'),
                rect: M6RackGeo.docket,
                child: _Docket(
                  feeder: j.feeder,
                  job: j.kind,
                  read: _run.docketRead,
                  quiet: quiet,
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // The crank's place, for the sweep over the controls (no paint).
      Positioned.fromRect(
        key: const ValueKey('crank-box'),
        rect: geo.crankHit,
        child: IgnorePointer(child: SizedBox.expand(key: _crankKey)),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6BreakerRackLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The crank counts from the touch-down (no arc lost to the slop).
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: () {
              _crankAngle = null;
              _strokeFrom = null;
            },
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
              builder: (_, v, _) => CustomPaint(painter: M6RackFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // The next panel: a short fade.
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final btnW = math.min(92.0, (size.width - 8) / 4);
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
              labels: [for (final j in _run.deal.jobs) M6BreakerRackLines.feeder(j.feeder)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _preview == null,
            hintKey: '${_run.index}/$_steps/${_run.docketRead}/${_run.testArmed}/${_run.handleFitted}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && !_run.testArmed)
                Positioned(
                  key: ValueKey('hud-actions-${_run.index}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final a in M6RackAction.values)
                        CardAside(
                          aside: _aside.contains(a),
                          child: _ActionButton(
                            key: _actionKeys[a],
                            icon: _icons[a]!,
                            label: M6BreakerRackLines.action(a),
                            width: btnW,
                            onTap: (g) => _openAction(a, g),
                          ),
                        ),
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _preview != null)
                Positioned.fill(
                  key: ValueKey('action-preview-${_preview!.name}'),
                  child: CardPreviewOverlay(
                    textBn: M6BreakerRackLines.action(_preview!),
                    icon: _icons[_preview!],
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmAction,
                    onReject: _rejectAction,
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
                  line: M6BreakerRackLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: m6RackLessonPoint(_run.job.kind), muted: _muted)),
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

  static const _icons = {
    M6RackAction.work: Icons.handyman_rounded,
    M6RackAction.test: Icons.toggle_on_rounded,
    M6RackAction.service: Icons.input_rounded,
    M6RackAction.report: Icons.assignment_late_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// The docket clipped to the neighbour panel: folded until read, then the
/// feeder, the job (never the position) and "ব্রেকার: অফ".
class _Docket extends StatelessWidget {
  const _Docket({required this.feeder, required this.job, required this.read, required this.quiet});
  final int feeder;
  final M6RackJobKind job;
  final bool read;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018));
    final paper = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(M6BreakerRackLines.docket, textAlign: TextAlign.center, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
            Text(M6BreakerRackLines.feeder(feeder), textAlign: TextAlign.center, style: ink),
            const Divider(height: 6, thickness: 1, color: Color(0x668A6A3C)),
            if (read) ...[
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M6BreakerRackLines.job(job), style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF8A2A16))),
                  ),
                ),
              ),
              FittedBox(fit: BoxFit.scaleDown, child: Text(M6BreakerRackLines.docketOff, style: ink)),
            ] else
              Expanded(child: CustomPaint(painter: _ScribblePainter())),
          ],
        ),
      ),
    );
    return Semantics(
      label: M6BreakerRackLines.docket,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: quiet
                ? paper
                : TweenAnimationBuilder<double>(
                    key: ValueKey(read),
                    tween: Tween(begin: 0.92, end: 1),
                    duration: const Duration(milliseconds: 260),
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: paper,
                  ),
          ),
          // The clip.
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(child: Container(width: 30, height: 10, decoration: BoxDecoration(color: const Color(0xFF9AA2A8), borderRadius: BorderRadius.circular(3)))),
          ),
        ],
      ),
    );
  }
}

/// Unread lines on the folded docket.
class _ScribblePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0x553A2A16)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.25 + i * 0.25);
      c.drawLine(Offset(4, y), Offset(size.width - (i.isOdd ? 18 : 6), y), p);
    }
  }

  @override
  bool shouldRepaint(_ScribblePainter old) => false;
}

/// One of the four actions: a round icon with its name under it (all alike).
class _ActionButton extends StatelessWidget {
  const _ActionButton({super.key, required this.icon, required this.label, required this.onTap, this.width = 90});
  final IconData icon;
  final String label;
  final double width;
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
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: SlmColors.gold300),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
