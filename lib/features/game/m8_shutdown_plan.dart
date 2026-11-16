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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_shutdown_plan_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm8_shutdown_plan_world.dart' show M8PlanGeo, kM8Days, kM8DayNames, kM8PxH, kM8StripL, kM8StripR, m8Clock;

// Lesson 8.3 "স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য", কাজ 2
// "শাটডাউনের ছক" (pack do_8_3_b, engineType m8_shutdown_plan). The section
// office wall, a dealt day (rulings M8-1, M8-8, M8-12):
//
//  Three jobs, order dealt — two maintenance jobs (one of 2–4 h, one LONG of
//  7–9 h) and one emergency (an LT wire down, town or village, registered in
//  the evening). Each has its own planner of five dated 00–24 strips (hour
//  numbers only: no night shading, no colour band) with a red 'এখন' magnet at
//  the dealt time, a docket clip and the job's block in a tray. DRAG the block
//  onto a strip (it snaps to whole hours; while held a readout shows only its
//  times, never a verdict) and tap 'বোর্ডে লাগান' — the notice goes out NOW.
//    maintenance: the block wholly inside 06:00–17:00, else a slip (lesson
//      point 5: 'সন্ধ্যা ৫টা থেকে সকাল ৬টার মধ্যে … নিষেধ');
//    maintenance over 6 h: also at least 72 h after 'এখন' (live lesson: 'ছয়
//      ঘন্টার বেশি … অন্তত ৩ দিন আগে নোটিশ'); a short job needs no 3 days;
//    emergency (LT wire break): the block ends within the live limit of its
//      zone from the registration (town 4 h, village 10 h), night allowed;
//      later = a slip.
//  Then ONE dealt maintenance job's notice sheet: the miking script card has
//  three wheels (দিন · শুরু · শেষ, dealt at random values); SWIPE each to
//  match the board, HOLD the mic to announce; wheels that do not match = a
//  slip (the sheet stays), the auto drives off when they match.
//  Then that job's shutdown morning: the clock stands 30 min before the start,
//  three porches in a lane. A tap on a porch asks 'শাটডাউনের খবর জানেন?' (5
//  game min each): all three know (about 40 % of plays) or one para says
//  'কই, মাইকিং তো শুনিনি!'. Two equal controls: HOLD the lever, or 'আগে
//  জানাই' (the crew tells the para that did not hear). The lever (or 'আগে
//  জানাই') before every porch is asked, or the lever while a para has not
//  heard = slips; 'আগে জানাই' when all three know = a needless hold = a slip.
//
// No deadly act in this level (ruling M8-1: all SoP-timing and notice mistakes
// are slips; nobody is exposed). Listening to the coworker is a slip (B1/X2).
// Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m8_shutdown_plan_world.dart), corner guide; a right job puts ◆ on the
// table and "কেন …?" opens at once; the coworker once a play, two variants —
// PLANNER (on the long job, once its block is on the board; 'বোর্ডে লাগান' waits
// for him) or MORNING (before the lever; the lever and 'আগে জানাই' wait for
// him). Gesture hands: a short straight-up nudge on the block in the tray; a
// sweep over the placed block and 'বোর্ডে লাগান'; a vertical swipe on the wheel
// row (never stopping on a value) and a hold ring on the mic; a sweep over the
// porches and both controls (never a hold ring on the lever). Off during the
// intro, a held lever, the coworker, cards and results; decks have their own
// sweep.

// ============================================================================
// Content
// ============================================================================

enum M8PlanKind { maint, emergency }

enum M8PlanZone { town, village }

enum M8PlanStage { plan, notice, morning }

/// The coworker's push (one per play): PLANNER on the long job's confirm, or
/// MORNING before the lever.
enum M8PlanPush { notice, miking }

/// What a step's reason asks about.
enum M8PlanWhy { window, early, night, heard, allKnow }

/// A job over this many hours is LONG (live lesson 8.3: 'ছয় ঘন্টার বেশি').
const int kM8LongOver = 6;

/// A long job needs at least this many hours' notice (3 days).
const int kM8NoticeH = 72;

/// Maintenance blocks sit wholly inside these hours (06:00 and 17:00 allowed).
const int kM8WindowFrom = 6;
const int kM8WindowTo = 17;

/// The live limit for an LT wire break (lesson 8.3: town 4 h, village 10 h).
int m8Limit(M8PlanZone z) => z == M8PlanZone.town ? 4 : 10;

const int kM8MicMs = 1100;
const int kM8LeverMs = 900;

/// Game minutes a porch's question takes.
const int kM8AskMin = 5;

abstract final class M8ShutdownPlanLines {
  static const title = 'শাটডাউনের ছক';
  // DRAFT wording — owner (M6-12).
  static const intro = 'মেইনটেন্যান্সের জন্য লাইন বন্ধ করতে হবে — দিন-সময় ঠিক করুন, এলাকাকে জানান।';

  static const startMaint = ['মেইনটেন্যান্সের ডকেট এসেছে।', 'আরেকটা মেইনটেন্যান্সের ডকেট এসেছে।'];
  static const startEmergency = 'লাইন ছিঁড়ে গেছে — ডকেট নথিভুক্ত হয়েছে!';
  static const startNotice = 'ছক তো হল — এবার এলাকাকে জানাতে হবে।';
  static const startMorning = 'শাটডাউনের সকাল — আধ ঘন্টা বাকি।';

  // The guide's task now (tap him: the same task, a different way).
  static const askPlan = 'ব্লকটা ছকে বসিয়ে বোর্ডে লাগান।';
  static const askEmergency = 'ছিঁড়ে যাওয়া লাইনের কাজটা ছকে বসান।';
  static const askNotice = 'চাকা ঘুরিয়ে মিলিয়ে নিন, তারপর মাইক ধরে রাখুন।';
  static const askMorning = 'এলাকার অবস্থা দেখে নিয়ে সিদ্ধান্ত নিন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askPlan, askEmergency, askNotice, askMorning];

  static const noticeOk = 'মাইকিং শুরু — গাড়ি বেরিয়ে গেল।';
  static const informedLine = 'ক্রু পাড়াকে জানিয়ে দিল।';

  // On-screen words a worker reads (not spoken).
  static const confirm = 'বোর্ডে লাগান';
  static const leverLabel = 'শাটডাউন';
  static const informLabel = 'আগে জানাই';
  static const askBubble = 'শাটডাউনের খবর জানেন?';
  static const replyKnow = ['হ্যাঁ, মাইকিং শুনেছি', 'জানি, গাড়ি এসেছিল'];
  static const replyNo = 'কই, মাইকিং তো শুনিনি!';
  static const replyTold = 'ও, এবার জানলাম';
  static const wheelDay = 'দিন';
  static const wheelStart = 'শুরু';
  static const wheelEnd = 'শেষ';
  static const boardLabel = 'দিন-সময়ের বোর্ড';
  static const noticeLabel = 'মাইকিংয়ের ছক';
  static const laneLabel = 'গ্রামের গলি';
  static const micLabel = 'মাইক';
  static const paras = ['বাগানপাড়া', 'মাঝেরপাড়া', 'স্টেশনপাড়া', 'কুমোরপাড়া', 'দত্তপাড়া', 'ঘোষপাড়া', 'নতুনপাড়া', 'মণ্ডলপাড়া'];
  static String stepName(int i) => i < 3 ? enDigits('কাজ ${i + 1}') : (i == 3 ? 'মাইকিং' : 'শাটডাউন');
  static String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
  static String zone(M8PlanZone z) => z == M8PlanZone.town ? 'শহর' : 'গ্রাম';

  /// The docket's lines (the same shape for every maintenance job; the
  /// emergency card never says night is allowed).
  static List<String> docket(M8PlanJob j) => j.kind == M8PlanKind.maint
      ? [enDigits('মেইনটেন্যান্স · ${j.para} · ${j.len} ঘন্টা')]
      : ['লাইন ছিঁড়ে গেছে · LT তার · ${zone(j.zone)}', enDigits('নথিভুক্ত ${m8Clock(j.nowMin)} · কাজ ${j.len} ঘন্টা')];

  /// The held block's readout: its times only.
  static String readout(String day, int hour, int len) => '$day ${hh(hour)}–${hh(hour + len)}';

  /// The reasons: the right ones fit what was done; the wrong ones are field
  /// excuses and the lesson's myths (all about the same length).
  static const whyQ = <M8PlanWhy, String>{
    M8PlanWhy.window: 'শাটডাউন এই সময়ে কেন রাখলেন?',
    M8PlanWhy.early: 'নোটিশ এত আগে কেন দিলেন?',
    M8PlanWhy.night: 'ছিঁড়ে যাওয়া লাইনের শাটডাউন রাতেই কেন?',
    M8PlanWhy.heard: 'পাড়ায় মাইকিং হয়নি শুনে কেন থামলেন?',
    M8PlanWhy.allKnow: 'সবাই জানে নিশ্চিত হয়ে কেন বন্ধ করলেন?',
  };
  static const whyRight = <M8PlanWhy, List<String>>{
    M8PlanWhy.window: ['সন্ধ্যা 5টা থেকে সকাল 6টায় শাটডাউন নেওয়া নিষেধ', 'দিনের আলোর মধ্যেই মেইনটেন্যান্স শাটডাউন রাখা নিয়ম'],
    M8PlanWhy.early: ['6 ঘন্টার বেশি বন্ধ রাখতে অন্তত 3 দিন আগে নোটিশ লাগে', 'লম্বা শাটডাউনে গ্রাহককে 3 দিন আগে জানাতেই হয়'],
    M8PlanWhy.night: ['লাইন ছিঁড়লে জরুরী অবস্থা, নিষেধের সময়েও কাজ চলে', 'ছেঁড়া লাইনে ঘন্টার সীমার মধ্যে সারাতেই হয়, রাত হোক'],
    M8PlanWhy.heard: ['মাইকিং না হলে গ্রাহক জানে না, আগে তাঁকে জানাতে হয়', 'এলাকা না জানলে শাটডাউন চলে না, আগে খবর দিই'],
    M8PlanWhy.allKnow: ['এলাকা জেনে গেছে বুঝে তবেই লাইন বন্ধ করা নিয়ম', 'সবাই জানে নিশ্চিত হয়েই শাটডাউন নিতে হয়, তাই'],
  };
  static const myths = [
    'রাতে লোড কম থাকে, তাই রাতেই শাটডাউন সুবিধার',
    'নোটিশ দিলেই ঝামেলা হয়, দেরিতে জানানোই ভালো',
    'মাইকিং করা না করা দপ্তরের নিজের ইচ্ছার ব্যাপার',
    'গ্রাহক নিজেই টের পেয়ে যায়, বলার দরকার নেই',
    'ওপরঅলা বললে সময়ের নিয়ম মানার দরকার হয় না',
    'শাটডাউন ছোট হলে এলাকাকে জানানোর দরকার নেই',
    'ছুটির দিন হলে নোটিশ ছাড়াই লাইন বন্ধ চলে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play). DRAFT wording — owner (M6-12): the
  // spec's two pushes (the live lesson changed the refusal: 3 days, over 6 h).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerNotice = CoworkerScript(
    line: 'কাল সকালেই বন্ধ করে দাও, নোটিশ-টোটিশ লাগে না!',
    exitLine: coworkerExit,
    right: ['না, 6 ঘন্টার বেশি বন্ধ রাখলে 3 দিন আগে নোটিশ দিতেই হবে', 'না, এত লম্বা শাটডাউনে আগে 3 দিনের নোটিশ লাগেই', 'না, নোটিশ ছাড়া এত ঘন্টা লাইন বন্ধ রাখা চলে না'],
    wrong: [
      'ঠিক আছে, কাল সকালেই সেরে ফেলি, নোটিশ লাগে না',
      'হ্যাঁ, নোটিশ-টোটিশ ছাড়াই কাল সকালে বন্ধ করে দিই',
      'আচ্ছা, কাল সকালেই বন্ধ করে দিই, নোটিশ পরে হবে',
      'ঠিক আছে, নোটিশ ছাড়াই কাল সকালে চালিয়ে দিই',
      'হ্যাঁ, গ্রাহক সামলে নেবে, কাল সকালেই সেরে ফেলি',
    ],
    asks: ['কী করবেন?', 'ও বলছে নোটিশ ছাড়াই কাল সকালে বন্ধ করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerMiking = CoworkerScript(
    line: 'মাইকিং-এ কী আসে যায়? এখনই লাইন বন্ধ করো!',
    exitLine: coworkerExit,
    right: ['না, আগে নিশ্চিত হই সবাই খবর পেয়েছে', 'না, সবাই জেনেছে কি না, তা আগে দেখে নিই', 'না, এলাকা জানে কি না না দেখে বন্ধ করব না'],
    wrong: [
      'ঠিক, লোকে আপনিই বুঝে নেবে, এখনই বন্ধ করি',
      'হ্যাঁ, মাইকিং-এ কী আসে যায়, এখনই বন্ধ করি',
      'আচ্ছা, কে জানল না জানল ভাবার সময় নেই',
      'ঠিক আছে, গ্রাহক নিজেই টের পাবে, বন্ধ করি',
      'হ্যাঁ, দেরি করার দরকার নেই, লাইন বন্ধ করে দিই',
    ],
    asks: ['কী করবেন?', 'ও বলছে মাইকিং না দেখেই লাইন বন্ধ করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M8PlanPush p) => p == M8PlanPush.notice ? coworkerNotice : coworkerMiking;
  static const allCoworkers = [coworkerNotice, coworkerMiking];

  static String callHeld(M8PlanPush p) => p == M8PlanPush.notice ? 'ঠিক! লম্বা শাটডাউনে নোটিশ ছাড়া চলে না।' : 'ঠিক! না জেনে লাইন বন্ধ করা চলে না।';

  static const allSet = 'সব ছক ঠিক — এলাকাও জানত, দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে দিন-সময়, তারপর নোটিশ, তারপর এলাকার খবর।';

  // "আজ যা ধরলেন".
  static const caughtNotice = 'মাইকিংয়ে ঠিক দিন আর সময় বলা';
  static const caughtLane = 'শাটডাউনের আগে পাড়ার খবর নেওয়া';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// A job's line on the pass panel: the block, its notice gap and time of day.
  static String caughtJob(M8PlanJob j, List<M8DayLabel> days, int day, int hour) {
    final gap = ((day * 1440 + hour * 60 - j.nowMin) / 60).round();
    final what = j.kind == M8PlanKind.maint ? 'নোটিশের' : 'নথিভুক্তির';
    return enDigits('${days[day].name} ${days[day].date} · ${hh(hour)}–${hh(hour + j.len)} · $what $gap ঘন্টা পরে');
  }

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until then
  /// the device voice). The porches' bubbles are silent captions (M8-10).
  static List<String> get newGuideLines => <String>{
        intro,
        ...startMaint,
        startEmergency,
        startNotice,
        startMorning,
        ...tasks,
        ...tapWhy,
        noticeOk,
        informedLine,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks,
        for (final p in M8PlanPush.values) callHeld(p),
        allSet,
        quick,
        fail,
        for (final m in M8ShutdownPlanMistakes.all) m.textBn,
      }.toList();
}

abstract final class M8ShutdownPlanMistakes {
  static const _dir = 'assets/game/art/m8_shutdown_plan';

  // DRAFT wording — owner (M6-12). Lesson points (flat, 0-based): 1 breakdown,
  // 4 scheduled shutdown.
  static const night = DoMistake(
    key: '8.3/m8_shutdown_plan/night',
    textBn: 'সন্ধ্যা 5টা থেকে সকাল 6টার মধ্যে সাধারণত মেইনটেন্যান্স শাটডাউন নেওয়া নিষেধ — শুধু জরুরী অবস্থায় চলে।',
    art: '$_dir/night.svg',
    lessonPoint: 4,
  );
  static const notice = DoMistake(
    key: '8.3/m8_shutdown_plan/notice',
    textBn: '6 ঘন্টার বেশি লাইন বন্ধ রাখতে হলে অন্তত 3 দিন আগে গ্রাহকদের নোটিশ দিতে হবে।',
    art: '$_dir/notice.svg',
    lessonPoint: 4,
  );
  static const late = DoMistake(
    key: '8.3/m8_shutdown_plan/late',
    textBn: 'লাইন ছিঁড়লে সময় ফল্টের ধরন অনুযায়ী — LT তার ছিঁড়লে শহরে 4 ঘন্টা, গ্রামে 10 ঘন্টা। তার মধ্যেই সারতে হবে।',
    art: '$_dir/late.svg',
    lessonPoint: 1,
  );
  static const wheels = DoMistake(
    key: '8.3/m8_shutdown_plan/wheels',
    textBn: 'মাইকিংয়ে যা বলবেন তা বোর্ডের সঙ্গে হুবহু মিলতে হবে — দিন, শুরু আর শেষের সময়।',
    art: '$_dir/wheels.svg',
    lessonPoint: 4,
  );
  static const unchecked = DoMistake(
    key: '8.3/m8_shutdown_plan/unchecked',
    textBn: 'শাটডাউন নেওয়ার আগে নিশ্চিত হন যে এলাকায় মাইকিং হয়েছে বা গ্রাহকরা জানে — আগে সব পাড়ায় জিজ্ঞেস করুন।',
    art: '$_dir/lane.svg',
    lessonPoint: 4,
  );
  static const unheard = DoMistake(
    key: '8.3/m8_shutdown_plan/unheard',
    textBn: 'একটা পাড়া এখনও জানে না — আগে তাদের জানান, তারপর শাটডাউন। নিশ্চিত হন যে এলাকা জানে।',
    art: '$_dir/lane.svg',
    lessonPoint: 4,
  );
  static const needless = DoMistake(
    key: '8.3/m8_shutdown_plan/needless',
    textBn: 'তিন পাড়াই মাইকিং শুনেছে — আবার জানিয়ে দেরি করার দরকার নেই। এলাকা জানলে সময়মতো শাটডাউন।',
    art: '$_dir/wait.svg',
    lessonPoint: 4,
  );
  static const pushNotice = DoMistake(
    key: '8.3/m8_shutdown_plan/push-notice',
    textBn: 'নোটিশ ছাড়া কাল সকালেই বন্ধ করা চলে না — 6 ঘন্টার বেশি লাইন বন্ধ রাখলে অন্তত 3 দিন আগে নোটিশ দিতে হবে।',
    art: '$_dir/notice.svg',
    lessonPoint: 4,
  );
  static const pushMiking = DoMistake(
    key: '8.3/m8_shutdown_plan/push-miking',
    textBn: 'মাইকিং না দেখে লাইন বন্ধ করা চলে না — শাটডাউন নেওয়ার আগে নিশ্চিত হন যে এলাকা জানে।',
    art: '$_dir/lane.svg',
    lessonPoint: 4,
  );

  /// Listening to his push is the act it pushes (X2/B1): a slip here.
  static DoMistake push(M8PlanPush p) => p == M8PlanPush.notice ? pushNotice : pushMiking;

  static const List<DoMistake> all = [night, notice, late, wheels, unchecked, unheard, needless, pushNotice, pushMiking];
}

/// One job on the day's list.
@immutable
class M8PlanJob {
  const M8PlanJob({required this.kind, required this.para, required this.len, required this.nowMin, this.zone = M8PlanZone.town});

  final M8PlanKind kind;
  final String para;

  /// The block's length, whole hours.
  final int len;

  /// 'এখন' (the registration time on an emergency): minutes from the first
  /// day's midnight.
  final int nowMin;
  final M8PlanZone zone;

  bool get isLong => kind == M8PlanKind.maint && len > kM8LongOver;

  /// The earliest start hour on [day] (never before 'এখন'), and the latest.
  int minStart(int day) => day == 0 ? (nowMin / 60).ceil() : 0;
  int get maxStart => 24 - len;

  /// A block that stands wholly inside the maintenance window.
  bool windowOk(int hour) => hour >= kM8WindowFrom && hour + len <= kM8WindowTo;

  /// The block's start in minutes from the first day's midnight.
  static int absMin(int day, int hour) => day * 1440 + hour * 60;

  /// The rule for one placement (null = right): the mistake it makes.
  DoMistake? judge(int day, int hour) {
    if (kind == M8PlanKind.emergency) {
      return absMin(day, hour) + len * 60 > nowMin + m8Limit(zone) * 60 ? M8ShutdownPlanMistakes.late : null;
    }
    if (!windowOk(hour)) return M8ShutdownPlanMistakes.night;
    if (isLong && absMin(day, hour) < nowMin + kM8NoticeH * 60) return M8ShutdownPlanMistakes.notice;
    return null;
  }

  /// Every placement that is right (tests; the deal always has one).
  List<(int, int)> get validPlacements => [
        for (var d = 0; d < kM8Days; d++)
          for (var h = minStart(d); h <= maxStart; h++)
            if (judge(d, h) == null) (d, h),
      ];
}

@immutable
class M8PlanDeal {
  const M8PlanDeal({
    required this.weekday,
    required this.date0,
    required this.jobs,
    required this.noticeJob,
    required this.paras,
    required this.unheard,
    required this.push,
    required this.why,
    required this.wheels,
  });

  /// The first day's weekday (0 = Monday) and date.
  final int weekday;
  final int date0;
  final List<M8PlanJob> jobs;

  /// The maintenance job that gets the notice sheet and the shutdown morning.
  final int noticeJob;

  /// The three paras of the lane and the one that did not hear (-1: all know).
  final List<String> paras;
  final int unheard;
  final M8PlanPush push;

  /// What each step's reason asks about: the three jobs, then the morning.
  final List<M8PlanWhy> why;

  /// The notice wheels' dealt values: day (0–4), start hour, end hour (1–24).
  final List<int> wheels;

  List<M8DayLabel> get days => [for (var d = 0; d < kM8Days; d++) M8DayLabel(kM8DayNames[(weekday + d) % 7], enDigits('${date0 + d}'))];

  int get longJob => jobs.indexWhere((j) => j.isLong);
}

M8PlanDeal m8PlanDeal(math.Random rng) {
  final names = [...M8ShutdownPlanLines.paras]..shuffle(rng);
  int nowAt(int from, int to) => (from + rng.nextInt(to - from + 1)) * 60 + (rng.nextBool() ? 30 : 0);
  final jobs = <M8PlanJob>[
    M8PlanJob(kind: M8PlanKind.maint, para: names[0], len: 2 + rng.nextInt(3), nowMin: nowAt(9, 16)),
    M8PlanJob(kind: M8PlanKind.maint, para: names[1], len: 7 + rng.nextInt(3), nowMin: nowAt(9, 16)),
    M8PlanJob(kind: M8PlanKind.emergency, para: names[2], len: 2 + rng.nextInt(2), nowMin: nowAt(18, 20), zone: rng.nextBool() ? M8PlanZone.town : M8PlanZone.village),
  ]..shuffle(rng);
  final maint = [for (final (i, j) in jobs.indexed) if (j.kind == M8PlanKind.maint) i];
  final noticeJob = maint[rng.nextInt(2)];
  final lane = [...names]..shuffle(rng);
  // About 40 % of plays: every para heard the miking.
  final unheard = rng.nextInt(10) < 4 ? -1 : rng.nextInt(3);
  final why = <M8PlanWhy>[
    for (final j in jobs)
      switch (j.kind) {
        M8PlanKind.emergency => M8PlanWhy.night,
        M8PlanKind.maint => j.isLong && rng.nextBool() ? M8PlanWhy.early : M8PlanWhy.window,
      },
    unheard < 0 ? M8PlanWhy.allKnow : M8PlanWhy.heard,
  ];
  return M8PlanDeal(
    weekday: rng.nextInt(7),
    date0: 10 + rng.nextInt(12),
    jobs: jobs,
    noticeJob: noticeJob,
    paras: lane.take(3).toList(),
    unheard: unheard,
    push: M8PlanPush.values[rng.nextInt(2)],
    why: why,
    wheels: [rng.nextInt(kM8Days), rng.nextInt(24), 1 + rng.nextInt(24)],
  );
}

/// The play state (pure logic).
class M8PlanRun {
  M8PlanRun(this.deal) {
    _startStep();
  }
  final M8PlanDeal deal;

  /// 0–2 the three jobs, 3 the notice sheet, 4 the shutdown morning.
  int index = 0;
  int slips = 0;
  int stepSlips = 0;
  final List<String> caught = [];

  /// The step's right answer is in (its reason, if any, comes next).
  var roundDone = false;

  // planner
  /// The block on the board: (day, hour), or null while it is in the tray.
  (int, int)? placed;

  /// Each job's accepted block.
  final List<(int, int)?> accepted = [null, null, null];

  // notice sheet: day index, start hour (0–23), end hour (1–24)
  List<int> wheels = [0, 0, 1];
  var announced = false;

  // morning
  final List<bool> asked = [false, false, false];
  var informed = false;
  double morningMin = 0;

  int get count => 5;
  bool get done => index >= count;
  M8PlanStage get stage => index < 3 ? M8PlanStage.plan : (index == 3 ? M8PlanStage.notice : M8PlanStage.morning);
  M8PlanJob get job => deal.jobs[index.clamp(0, 2)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => stepSlips == 0;
  bool get _open => !done && !roundDone;

  /// The notice job and its accepted block.
  M8PlanJob get noticeJob => deal.jobs[deal.noticeJob];
  (int, int) get noticeBlock => accepted[deal.noticeJob]!;

  bool get hasBlock => placed != null;
  bool get allAsked => asked.every((a) => a);

  /// The coworker's step: the long job's confirm, or the morning.
  bool get coworkerStep => deal.push == M8PlanPush.notice ? index == deal.longJob : index == 4;

  void _startStep() {
    placed = null;
    roundDone = false;
    stepSlips = 0;
    announced = false;
    informed = false;
    for (var i = 0; i < 3; i++) {
      asked[i] = false;
    }
    if (index == 3) {
      wheels = [...deal.wheels];
      final b = noticeBlock;
      // The wheels never start on the answer.
      if (wheels[0] == b.$1 && wheels[1] == b.$2 && wheels[2] == b.$2 + noticeJob.len) wheels[1] = (wheels[1] + 1) % 24;
    }
    if (index == 4) {
      final b = noticeBlock;
      morningMin = (b.$2 * 60 - 30).toDouble();
    }
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return m;
  }

  // --- the planner -------------------------------------------------------------
  /// The nearest placement to a block of the job's length whose left edge is
  /// at [hour] on [day]: the hour clamped to what the strip allows (never
  /// before 'এখন', never past midnight); null when the strip has no room.
  (int, int)? clampPlace(int day, double hour) {
    if (stage != M8PlanStage.plan || day < 0 || day >= kM8Days) return null;
    final lo = job.minStart(day);
    final hi = job.maxStart;
    if (lo > hi) return null;
    return (day, hour.round().clamp(lo, hi));
  }

  bool place(int day, int hour) {
    if (!_open || stage != M8PlanStage.plan) return false;
    final p = clampPlace(day, hour.toDouble());
    if (p == null) return false;
    placed = p;
    return true;
  }

  /// Picks the block off the board (back in the tray).
  void lift() {
    if (_open && stage == M8PlanStage.plan) placed = null;
  }

  /// 'বোর্ডে লাগান': null = right (the notice goes out), else the slip.
  DoMistake? confirm() {
    if (!_open || stage != M8PlanStage.plan || placed == null) return null;
    final (d, h) = placed!;
    final m = job.judge(d, h);
    if (m != null) return _slip(m);
    accepted[index] = placed;
    _tag(M8ShutdownPlanLines.caughtJob(job, deal.days, d, h));
    roundDone = true;
    return null;
  }

  // --- the notice sheet --------------------------------------------------------
  /// Wheel [i] (0 day, 1 start, 2 end) turned [delta] steps (both ways, round).
  void turn(int i, int delta) {
    if (!_open || stage != M8PlanStage.notice) return;
    switch (i) {
      case 0:
        wheels[0] = ((wheels[0] + delta) % kM8Days + kM8Days) % kM8Days;
      case 1:
        wheels[1] = ((wheels[1] + delta) % 24 + 24) % 24;
      case 2:
        wheels[2] = ((wheels[2] - 1 + delta) % 24 + 24) % 24 + 1;
    }
  }

  bool get wheelsMatch {
    final b = noticeBlock;
    return wheels[0] == b.$1 && wheels[1] == b.$2 && wheels[2] == b.$2 + noticeJob.len;
  }

  /// The mic held to the end: null = the auto drives off.
  DoMistake? announce() {
    if (!_open || stage != M8PlanStage.notice) return null;
    if (!wheelsMatch) return _slip(M8ShutdownPlanMistakes.wheels);
    announced = true;
    roundDone = true;
    _tag(M8ShutdownPlanLines.caughtNotice);
    return null;
  }

  // --- the shutdown morning ----------------------------------------------------
  bool ask(int porch) {
    if (!_open || stage != M8PlanStage.morning || asked[porch]) return false;
    asked[porch] = true;
    morningMin += kM8AskMin;
    return true;
  }

  /// Porch [i] knows now (it heard, or the crew told it).
  bool knows(int i) => deal.unheard != i || informed;

  /// 'আগে জানাই'.
  DoMistake? inform() {
    if (!_open || stage != M8PlanStage.morning) return null;
    if (!allAsked) return _slip(M8ShutdownPlanMistakes.unchecked);
    if (deal.unheard < 0 || informed) return _slip(M8ShutdownPlanMistakes.needless);
    informed = true;
    return null;
  }

  /// The lever held to the end.
  DoMistake? lever() {
    if (!_open || stage != M8PlanStage.morning) return null;
    if (!allAsked) return _slip(M8ShutdownPlanMistakes.unchecked);
    if (!knows(deal.unheard < 0 ? 0 : deal.unheard)) return _slip(M8ShutdownPlanMistakes.unheard);
    _tag(M8ShutdownPlanLines.caughtLane);
    roundDone = true;
    return null;
  }

  /// Listened to the coworker (a slip).
  DoMistake pushSlip(DoMistake m) => _slip(m);

  void next() {
    index++;
    if (!done) _startStep();
  }
}

/// The quick bonus: a little under a clean play (~85 %, rounded). ms, ~1500
/// per human action:
///   a job: the drag ≈ 4000, 'বোর্ডে লাগান' ≈ 1500, the reason ≈ 8200   ≈ 14000 × 3
///   the notice sheet: three swipes ≈ 5000, the mic hold ≈ 2000, the auto 1600 ≈ 8500
///   the morning: three porches ≈ 5500, the lever hold ≈ 2500, the reason ≈ 8200 ≈ 16000
///   the coworker ≈ 9600
///   total ≈ 76000; 85 % ≈ 64000 (a builder's estimate; owner may tune).
const m8ShutdownPlanQuickMs = 64000;

@immutable
class M8ShutdownPlanPack {
  const M8ShutdownPlanPack({required this.id, required this.titleBn, this.quickMs = m8ShutdownPlanQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8ShutdownPlanPack> m8ShutdownPlanPacks = {
  'do_8_3_b': M8ShutdownPlanPack(id: 'do_8_3_b', titleBn: M8ShutdownPlanLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8ShutdownPlanProbe {
  static M8PlanRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M8ShutdownPlanPage extends StatefulWidget {
  const M8ShutdownPlanPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8ShutdownPlanPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8ShutdownPlanPage> createState() => _M8ShutdownPlanPageState();
}

class _M8ShutdownPlanPageState extends State<M8ShutdownPlanPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PlanRunPage(
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

class _PlanRunPage extends ConsumerStatefulWidget {
  const _PlanRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8ShutdownPlanPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PlanRunPage> createState() => _PlanRunPageState();
}

class _PlanRunPageState extends ConsumerState<_PlanRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8PlanRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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
  int _steps = 0;

  /// The block in hand: the finger, and the placement under it.
  var _dragging = false;
  Offset? _dragAt;
  (int, int)? _cand;

  /// The notice wheels: the one being swiped, and the swipe's last y.
  int? _wheel;
  double _lastY = 0;
  double _wheelAcc = 0;

  /// The mic's hold ring and the auto's drive (each runs only when used).
  late final AnimationController _mic = AnimationController(vsync: this, duration: const Duration(milliseconds: kM8MicMs), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_micStatus);
  late final AnimationController _drive = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600), animationBehavior: AnimationBehavior.preserve);
  late final AnimationController _lever = AnimationController(vsync: this, duration: const Duration(milliseconds: kM8LeverMs), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_leverStatus);

  /// The morning lane: each porch's bubble, and the questions in flight.
  final List<String?> _bubbles = [null, null, null];
  final Set<int> _told = {};
  int _asking = 0;
  var _off = false;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  M8PlanGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8PlanRun(m8PlanDeal(widget.rng));
    M8ShutdownPlanProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M8PlanDeal get _deal => _run.deal;
  M8PlanStage get _stage => _run.stage;

  @override
  void dispose() {
    disposeCoworker();
    _mic.dispose();
    _drive.dispose();
    _lever.dispose();
    _chain++;
    if (identical(M8ShutdownPlanProbe.run, _run)) M8ShutdownPlanProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone;

  String get _task => switch (_stage) {
        M8PlanStage.plan => _run.job.kind == M8PlanKind.emergency ? M8ShutdownPlanLines.askEmergency : M8ShutdownPlanLines.askPlan,
        M8PlanStage.notice => M8ShutdownPlanLines.askNotice,
        M8PlanStage.morning => M8ShutdownPlanLines.askMorning,
      };

  String get _stepStart => switch (_stage) {
        M8PlanStage.plan => _run.job.kind == M8PlanKind.emergency ? M8ShutdownPlanLines.startEmergency : M8ShutdownPlanLines.startMaint[_run.index == 0 ? 0 : 1],
        M8PlanStage.notice => M8ShutdownPlanLines.startNotice,
        M8PlanStage.morning => M8ShutdownPlanLines.startMorning,
      };

  Future<void> _start() async {
    _clock.start();
    _startStep();
  }

  void _startStep() {
    setState(() {
      _resetHands();
      _off = false;
      _told.clear();
      for (var i = 0; i < 3; i++) {
        _bubbles[i] = null;
      }
      _drive.value = 0;
    });
    if (_stage == M8PlanStage.morning && _deal.push == M8PlanPush.miking && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([_stepStart, _task]));
  }

  void _resetHands() {
    _dragging = false;
    _dragAt = null;
    _cand = null;
    _wheel = null;
    _wheelAcc = 0;
    _mic.value = 0;
    _lever.value = 0;
  }

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  /// The coworker's moment: once he is due, the decisive control waits for him.
  bool _waitForHim() => _run.coworkerStep && holdForCoworker();

  // --- the planner -----------------------------------------------------------------
  Rect _grab(Rect r) => Rect.fromCenter(center: r.center, width: math.max(r.width, 56), height: math.max(r.height, 48));

  (int, int)? _candidateAt(Offset p, M8PlanGeo geo) {
    final row = geo.rowAt(p.dy);
    if (row == null) return null;
    final len = _run.job.len;
    return _run.clampPlace(row, (p.dx - kM8StripL) / kM8PxH - len / 2);
  }

  void _planStart(Offset p, M8PlanGeo geo) {
    final len = _run.job.len;
    final placed = _run.placed;
    if (placed != null && _grab(geo.blockRect(placed.$1, placed.$2, len)).contains(p)) {
      _run.lift();
      setState(() {
        _dragging = true;
        _dragAt = p;
        _cand = placed;
      });
      return;
    }
    if (placed == null && geo.trayGrab(len).contains(p)) {
      setState(() {
        _dragging = true;
        _dragAt = p;
        _cand = null;
      });
      return;
    }
    _hints.missTap();
  }

  void _planMove(Offset p, M8PlanGeo geo) {
    if (!_dragging) return;
    setState(() {
      _dragAt = p;
      _cand = _candidateAt(p, geo);
    });
  }

  void _planEnd() {
    if (!_dragging) return;
    final c = _cand;
    setState(() {
      _dragging = false;
      _dragAt = null;
      _cand = null;
    });
    if (c != null && _run.place(c.$1, c.$2)) {
      _tick('sounds/intro/click.ogg', 0.5);
      // The long job's block is on the board: the coworker comes now.
      if (_deal.push == M8PlanPush.notice && _run.index == _deal.longJob && !coworkerDone && !coworkerDue) scheduleCoworker();
    }
    _stepDone();
  }

  void _confirm(Offset at) {
    if (!_canPlay || _stage != M8PlanStage.plan || _dragging) return;
    if (!_run.hasBlock) {
      _hints.missTap();
      return;
    }
    if (_waitForHim()) return;
    final m = _run.confirm();
    if (m != null) {
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    _stepDone();
    unawaited(_stepRight());
  }

  /// A right step with a reason: ◆ on the table, then "কেন …?".
  Future<void> _stepRight() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    final topic = _deal.why[idx == 4 ? 3 : idx];
    unawaited(askReason(
      deal: () => dealChoices(M8ShutdownPlanLines.whyRight[topic]!, M8ShutdownPlanLines.myths, widget.rng),
      question: M8ShutdownPlanLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  // --- the notice sheet ---------------------------------------------------------------
  void _wheelStart(Offset p, M8PlanGeo geo) {
    for (var i = 0; i < 3; i++) {
      if (geo.wheel(i).inflate(4).contains(p)) {
        _wheel = i;
        _lastY = p.dy;
        _wheelAcc = 0;
        return;
      }
    }
    _hints.missTap();
  }

  void _wheelMove(Offset p) {
    final w = _wheel;
    if (w == null) return;
    _wheelAcc += p.dy - _lastY;
    _lastY = p.dy;
    var moved = false;
    // Swiping up brings the next value; down the one before.
    while (_wheelAcc <= -30) {
      _run.turn(w, 1);
      _wheelAcc += 30;
      moved = true;
    }
    while (_wheelAcc >= 30) {
      _run.turn(w, -1);
      _wheelAcc -= 30;
      moved = true;
    }
    if (moved) {
      _cue('sounds/intro/tick.ogg', volume: 0.3);
      setState(() {});
    }
  }

  void _micDown() {
    if (!_canPlay || _stage != M8PlanStage.notice || _mic.isAnimating) return;
    _mic.forward(from: 0);
  }

  void _micUp() {
    if (_mic.status == AnimationStatus.completed) return;
    _mic.value = 0;
  }

  void _micStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    _mic.value = 0;
    if (!_canPlay || _stage != M8PlanStage.notice) return;
    final m = _run.announce();
    if (m != null) {
      unawaited(_mistake(m, const Offset(180, 600)));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    _stepDone();
    unawaited(_levelDelta(10, const Offset(180, 600), mood: GuideMood.glad));
    unawaited(_sayChain([M8ShutdownPlanLines.noticeOk], mood: GuideMood.glad));
    if (_quiet) {
      _drive.value = 1;
    } else {
      _drive.forward(from: 0);
    }
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 2000), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shutdown morning -----------------------------------------------------------
  void _askPorch(int i) {
    if (!_canPlay || _stage != M8PlanStage.morning || _lever.isAnimating) return;
    if (!_run.ask(i)) return;
    _tick('sounds/intro/click.ogg', 0.55);
    final idx = _run.index;
    setState(() => _bubbles[i] = M8ShutdownPlanLines.askBubble);
    _stepDone();
    _asking++;
    final know = _deal.unheard != i;
    final reply = know ? M8ShutdownPlanLines.replyKnow[widget.rng.nextInt(2)] : M8ShutdownPlanLines.replyNo;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 700), () {
      _asking--;
      if (!mounted || _run.index != idx) return;
      setState(() => _bubbles[i] = reply);
    }));
  }

  void _inform(Offset at) {
    if (!_canPlay || _stage != M8PlanStage.morning || _lever.isAnimating) return;
    if (_waitForHim()) return;
    final m = _run.inform();
    if (m != null) {
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    final p = _deal.unheard;
    setState(() {
      _told.add(p);
      _bubbles[p] = M8ShutdownPlanLines.replyTold;
    });
    _stepDone();
    unawaited(_sayChain([M8ShutdownPlanLines.informedLine, _task], mood: GuideMood.glad));
  }

  void _leverDown() {
    if (!_canPlay || _stage != M8PlanStage.morning || _lever.isAnimating) return;
    if (_waitForHim()) return;
    _lever.forward(from: 0);
    setState(() {});
  }

  void _leverUp() {
    if (_lever.status == AnimationStatus.completed) return;
    if (_lever.value != 0) {
      _lever.value = 0;
      setState(() {});
    }
  }

  void _leverStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    _lever.value = 0;
    if (!_canPlay || _stage != M8PlanStage.morning) {
      setState(() {});
      return;
    }
    final m = _run.lever();
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, const Offset(70, 700)));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.7);
    setState(() => _off = true);
    _stepDone();
    unawaited(_stepRight());
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startStep();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  // --- the shared success beat (ReasonTable) --------------------------------------------
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

  // --- the shared pressure moment (CoworkerMoment) ----------------------------------------
  @override
  CoworkerScript get coworkerScript => M8ShutdownPlanLines.coworker(_deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.coworkerStep || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy) return false;
    if (_deal.push == M8PlanPush.notice) return !_dragging && _run.hasBlock;
    return !_lever.isAnimating && _asking == 0;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _deal.push;
    if (!held) {
      final m = M8ShutdownPlanMistakes.push(p);
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8ShutdownPlanLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8ShutdownPlanLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8ShutdownPlanLines.tapWhy[_nudgeN++ % M8ShutdownPlanLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -------------------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _mic.stop();
    _lever.stop();
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
      _dragging = false;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8plan/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same step goes on from where it was.
    _hush();
    setState(() => _card = null);
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
    await _say(!_run.passed ? M8ShutdownPlanLines.fail : (_quickBonus ? M8ShutdownPlanLines.quick : M8ShutdownPlanLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the scene ---------------------------------------------------------------------
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    switch (_stage) {
      case M8PlanStage.plan:
        final len = _run.job.len;
        final placed = _run.placed;
        if (placed == null) return HintSpec.drag(geo.trayBlock(len).center, toward: const Offset(0, -1), travel: 90, space: HintSpace.scene);
        return HintSpec.sweep([geo.blockRect(placed.$1, placed.$2, len), geo.confirmBtn], space: HintSpace.scene);
      case M8PlanStage.notice:
        if (n.isEven) return HintSpec.swipe(geo.wheel(1).center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
        return HintSpec.hold(geo.mic, space: HintSpace.scene);
      case M8PlanStage.morning:
        final rects = [if (!_run.allAsked) for (var i = 0; i < 3; i++) geo.porch(i), geo.lever, geo.inform];
        return HintSpec.sweep(rects, space: HintSpace.scene);
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8PlanGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final days = _deal.days;
    final Widget art;
    final String label;
    switch (_stage) {
      case M8PlanStage.plan:
        final len = _run.job.len;
        final shown = _dragging ? _cand : _run.placed;
        label = M8ShutdownPlanLines.boardLabel;
        art = CustomPaint(
          painter: M8PlanBoardPainter(
            geo: geo,
            days: days,
            nowMin: _run.job.nowMin.toDouble(),
            len: len,
            docket: M8ShutdownPlanLines.docket(_run.job),
            block: shown,
            drag: _dragging ? _dragAt : null,
            readout: _dragging && _cand != null ? M8ShutdownPlanLines.readout(days[_cand!.$1].name, _cand!.$2, len) : null,
          ),
        );
      case M8PlanStage.notice:
        final b = _run.noticeBlock;
        final w = _run.wheels;
        String dayAt(int d) => '${days[d % kM8Days].name} ${days[d % kM8Days].date}';
        int hourWrap(int h) => ((h % 24) + 24) % 24;
        int endWrap(int h) => ((h - 1) % 24 + 24) % 24 + 1;
        label = M8ShutdownPlanLines.noticeLabel;
        art = CustomPaint(
          painter: M8NoticePainter(
            geo: geo,
            day: days[b.$1],
            dayIndex: b.$1,
            startHour: b.$2,
            len: _run.noticeJob.len,
            wheels: [
              M8WheelFace(M8ShutdownPlanLines.wheelDay, dayAt(w[0] - 1 + kM8Days), dayAt(w[0]), dayAt(w[0] + 1)),
              M8WheelFace(M8ShutdownPlanLines.wheelStart, M8ShutdownPlanLines.hh(hourWrap(w[1] - 1)), M8ShutdownPlanLines.hh(w[1]), M8ShutdownPlanLines.hh(hourWrap(w[1] + 1))),
              M8WheelFace(M8ShutdownPlanLines.wheelEnd, M8ShutdownPlanLines.hh(endWrap(w[2] - 1)), M8ShutdownPlanLines.hh(w[2]), M8ShutdownPlanLines.hh(endWrap(w[2] + 1))),
            ],
            drive: quiet ? const AlwaysStoppedAnimation(0) : _drive,
            hold: _mic,
          ),
        );
      case M8PlanStage.morning:
        label = M8ShutdownPlanLines.laneLabel;
        art = CustomPaint(
          painter: M8LanePainter(
            geo: geo,
            porches: [for (var i = 0; i < 3; i++) M8PorchView(name: _deal.paras[i], caption: _bubbles[i])],
            clock: m8Clock(_run.morningMin),
            off: _off,
            informed: _told,
          ),
        );
    }
    return [
      Positioned.fill(key: ValueKey('art-${_stage.name}'), child: RepaintBoundary(child: art)),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      if (_stage == M8PlanStage.notice)
        Positioned.fromRect(
          key: const ValueKey('mic'),
          rect: geo.micHit,
          child: Semantics(
            button: true,
            label: M8ShutdownPlanLines.micLabel,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _micDown(),
              onPointerUp: (_) => _micUp(),
              onPointerCancel: (_) => _micUp(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      // The next step: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.5, end: 0),
              duration: const Duration(milliseconds: 420),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  void _tapScene(Offset p, M8PlanGeo geo) {
    if (!_canPlay) return;
    if (_stage == M8PlanStage.morning) {
      for (var i = 0; i < 3; i++) {
        if (geo.porch(i).contains(p)) {
          _askPorch(i);
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _panStart(Offset p, M8PlanGeo geo) {
    _dragging = false;
    _wheel = null;
    if (!_canPlay) return;
    switch (_stage) {
      case M8PlanStage.plan:
        _planStart(p, geo);
      case M8PlanStage.notice:
        _wheelStart(p, geo);
      case M8PlanStage.morning:
        break;
    }
  }

  void _panUpdate(Offset p, M8PlanGeo geo) {
    if (_dragging) {
      if (!_canPlay) {
        _panEnd();
        return;
      }
      _planMove(p, geo);
    } else if (_wheel != null) {
      if (!_canPlay) {
        _wheel = null;
        return;
      }
      _wheelMove(p);
    }
  }

  void _panEnd() {
    if (_dragging) {
      _planEnd();
      return;
    }
    if (_wheel != null) {
      _wheel = null;
      _stepDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.roundDone;
    final waiting = handsOn && !tableBusy && !_dragging && _wheel == null && !_lever.isAnimating && _asking == 0 && !_mic.isAnimating;
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
              labels: [for (var i = 0; i < _run.count; i++) M8ShutdownPlanLines.stepName(i)],
              done: {for (var i = 0; i < math.min(_run.index, _run.count); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.index}/$_steps/${_stage.name}/${_run.hasBlock}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && !tableBusy && _stage == M8PlanStage.plan)
                Positioned(
                  key: ValueKey('hud-confirm-${_run.index}'),
                  left: 16,
                  bottom: pad.bottom + 14,
                  child: _PillButton(label: M8ShutdownPlanLines.confirm, onTap: _confirm),
                ),
              if (handsOn && !tableBusy && _stage == M8PlanStage.morning) ...[
                Positioned(
                  key: const ValueKey('hud-lever'),
                  left: 10,
                  bottom: pad.bottom + 14,
                  child: _LeverButton(progress: _lever, onDown: _leverDown, onUp: _leverUp),
                ),
                Positioned(
                  key: const ValueKey('hud-inform'),
                  left: 134,
                  bottom: pad.bottom + 14,
                  child: _PillButton(label: M8ShutdownPlanLines.informLabel, onTap: _inform, width: 116),
                ),
              ],
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  line: M8ShutdownPlanLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 4, muted: _muted)),
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

const _ctlDeco = BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
  boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
);

/// A worker's button on the scene ('বোর্ডে লাগান', 'আগে জানাই').
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap, this.width});
  final String label;
  final ValueChanged<Offset> onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 56, minWidth: 116),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: _ctlDeco.copyWith(border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7)),
          child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// The breaker-style 'শাটডাউন' lever: hold to pull (the fill is the pull).
/// The same size as 'আগে জানাই'.
class _LeverButton extends StatelessWidget {
  const _LeverButton({required this.progress, required this.onDown, required this.onUp});
  final Animation<double> progress;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8ShutdownPlanLines.leverLabel,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Container(
          width: 116,
          height: 56,
          decoration: _ctlDeco.copyWith(border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (_, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(widthFactor: progress.value, heightFactor: 1, child: const ColoredBox(color: Color(0x6643C464))),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.power_settings_new_rounded, size: 20, color: Color(0xFFFF8A80)),
                      const SizedBox(width: 6),
                      Text(M8ShutdownPlanLines.leverLabel, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                    ],
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
