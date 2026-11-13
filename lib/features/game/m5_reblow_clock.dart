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
import 'm5_reblow_clock_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 5.4 "ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী বনাম স্থায়ী ফল্ট", কাজ 2
// "লাগাতেই, না পরে?" (pack do_5_4_b, engineType m5_reblow_clock). Core verb:
// read and run the re-blow clock. Two DTRs on one 11 kV spur per play (one
// permanent fault, one transient, in a dealt order). For each:
//
//  1. Today's logbook page is dealt: blank (a fresh blow), or already written
//     by the crew before — "লাগানো · ধরে রাখল 0 সে · বিকট শব্দ, আগুনের ঝলক"
//     (instant blast) or "লাগানো · ধরে রাখল 3 ঘ 30 মি · ঝড়ো হাওয়া" (held,
//     then blew). Older pages swipe in (noise).
//  2. Hold the DO to re-fit it, or drag one of two identical stamps
//     (স্থায়ী / অস্থায়ী) onto today's entry.
//     • Blank page: the re-fit is allowed after one visual check of the DTR,
//       the DO and the span (ruling M5-8; re-fit with no check = slip). The
//       permanent fault blasts at once (0 সে written); the transient one holds
//       and the stopwatch becomes the only control: hold it to run the
//       time-lapse, a sign comes (wind, lightning, birds) and the barrel drops
//       (the held time written).
//     • A stamp on a blank page = slip (no evidence, M5-10); the wrong stamp =
//       slip.
//     • Re-fit after an instant blast with arc (written, or just seen) =
//       DEADLY (R8, M5-1). Re-fit after a delayed blow = slip (R10).
//  3. The right stamp → ◆ → "কেন স্থায়ী / অস্থায়ী ফল্ট?".
//  4. Permanent: the careless coworker pushes the lesson's myth 1 word for
//     word (fault burning); listening = DEADLY (R8). The order deck waits for
//     him: 'পেট্রোলিং দল পাঠাও' (right) / another re-fit or charge (DEADLY,
//     R8) / a thick wire or a bigger fuse (DEADLY, R26) → ◆ → "কেন আবার চার্জ
//     না করে পেট্রোলিং?".
//     Transient: a 3-picture "কোথায় দেখবেন?" deck (one span with a heavy sag
//     or a close branch; decoys: normal sag, safe or trimmed trees, a clear
//     span, a road crossing) → ◆ → "কেন এই জায়গাগুলো দেখলেন?". A wrong
//     picture = slip.
//  5. After both DTRs: the pass panel. Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md). Gesture hints (how,
// never what): reading — a swipe on the logbook, then the next time a sweep
// over the DO, both stamps and the look button alike; the line holding — a
// hold on the stopwatch (the only control); the picture deck — a sweep over
// the open cards; the text decks have their own sweep. Voice: the guide by
// device TTS; the coworker's push is a new rival line (to be recorded — until
// then silent with its caption held), his exit line is his existing clip.

// ============================================================================
// Content
// ============================================================================

enum M5ReblowKind { permanent, transient }

enum M5ReblowLog { fresh, history }

/// Where a DTR's play is.
enum M5ReblowStage {
  /// Reading the page: re-fit, look, stamp.
  read,

  /// The line holds after a re-fit on a blank page: run the clock.
  holding,

  /// Stamped: the follow-up (orders / where to look).
  follow,
}

abstract final class M5ReblowLines {
  static const title = 'লাগাতেই, না পরে?';
  static const intro = 'একই লাইনে ফিউজ বারবার উড়ছে! কী ধরনের ফল্ট — বুঝে তবে কাজ।';
  static const cases = ['প্রথম ডিটিআর', 'দ্বিতীয় ডিটিআর'];

  // The guide's task now (tap him: the same task, a different way).
  static const askRead = 'আজকের পাতা দেখে ঠিক করুন — কী করবেন।';
  static const askClock = 'ঘড়িটা চেপে ধরে দেখুন, লাইন কতক্ষণ টেকে।';
  static const askOrder = 'দলকে এখন কী নির্দেশ দেবেন?';
  static const askSpot = 'কোথায় দেখবেন?';
  static const askNext = 'এবার পরের ডিটিআর।';
  static const tasks = [askRead, askClock, askOrder, askSpot];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'স্পার লাইন, ডিটিআর আর লগবুক';
  static const doLabel = 'ডিও';

  /// Ruling M5-8 (the lesson gives no value): the fuse's tag on the DO arm.
  static const ratingTag = 'ফিউজ · সঠিক রেটিং';
  static const clockLabel = 'ঘড়ি';
  static const logLabel = 'লগবুক';
  static const lookLabel = 'চোখে দেখুন';
  static const stampPermanent = 'স্থায়ী';
  static const stampTransient = 'অস্থায়ী';
  static const today = 'আজ';
  static const blankToday = '—';
  static String stampLabel(M5ReblowKind k) => k == M5ReblowKind.permanent ? stampPermanent : stampTransient;
  static String logHead(int dtr, String village) => 'লগবুক · DTR $dtr · $village';
  static String heldLine(String held) => 'লাগানো · ধরে রাখল $held';
  static String daysAgo(int n) => '$n দিন আগে';

  // The page's facts (the logbook writes facts only).
  static const held0 = '0 সে';
  static const heldTimes = ['40 সে', '12 মি', '25 মি', '1 ঘ 15 মি', '2 ঘ 10 মি', '3 ঘ 30 মি'];
  static const blastNotes = ['বিকট শব্দ, আগুনের ঝলক', 'বড় বিস্ফোরণ আর আর্ক'];
  static String weatherNote(M5ReblowWeather w) => switch (w) {
        M5ReblowWeather.wind => 'ঝড়ো হাওয়া',
        M5ReblowWeather.lightning => 'বাজ পড়ল',
        M5ReblowWeather.bird => 'তারে পাখির ঝাঁক',
      };
  static const times = ['সকাল 8:15', 'সকাল 10:40', 'দুপুর 12:20', 'বিকেল 3:05'];
  static const timeHour = [0.08, 0.28, 0.42, 0.6];
  static const villages = ['শালবনি', 'কেশপুর', 'ডেবরা', 'পিংলা', 'গড়বেতা', 'সবং'];

  /// Older pages: routine entries (noise — today's page decides).
  static const olderNotes = [
    'রুটিন পরিদর্শন · সব ঠিক',
    'তেলের লেভেল দেখা · ঠিক আছে',
    'আর্থ রেজিস্ট্যান্স মাপা',
    'লোড মাপা · তিন ফেজ',
    'ডিও-র কন্ট্যাক্ট পরিষ্কার',
    'এলটি লাগ টাইট দেওয়া',
    'সিলিকা জেলের রং দেখা',
  ];
  static String spotPoles(int a) => 'পোল $a–${a + 1}';

  // The order deck (permanent): the right ones send the patrol; every wrong
  // one charges the faulted line again (R8) or kills the fuse (R26). 26–32
  // letters.
  static const orderRight = ['পেট্রোলিং দল পাঠাও, ফল্ট খুঁজুক', 'লাইন টহল দিয়ে আগে ফল্ট খোঁজো'];
  static const orderWrong = [
    'আরেকবার ফিউজ লাগিয়ে চার্জ দাও',
    'মোটা তার দিয়ে ফিউজ বেঁধে দাও',
    'বড় রেটিং-এর ফিউজ বসিয়ে দাও',
    'অপারেটরকে আবার চার্জ দিতে বলো',
    'দু-তিনবার চার্জ করে দেখো, পুড়ুক',
  ];
  static bool orderKillsFuse(String o) => o.contains('মোটা তার') || o.contains('রেটিং');

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. 40–52 letters.
  static const whyPermanentQ = 'কেন স্থায়ী ফল্ট?';
  static const whyTransientQ = 'কেন অস্থায়ী ফল্ট?';
  static const whyPatrolQ = 'কেন আবার চার্জ না করে পেট্রোলিং?';
  static const whySpotQ = 'কেন এই জায়গাগুলো দেখলেন?';
  static const whyPermanent = ['লাগাতেই বিস্ফোরণ আর আর্ক — ফল্টটা নিজে সারেনি', 'ধরে রাখল 0 সে, সাথে আর্ক — এটা স্থায়ী ফল্ট'];
  // True for every dealt held time, 40 সে too (the lesson: "কয়েক সেকেন্ড
  // থেকে কয়েক ঘন্টা") — never "a long time".
  static const whyTransient = ['কিছুক্ষণ ঠিক চলে তারপর উড়ল — কারণ ক্ষণস্থায়ী', 'লাগানোর পর কিছু সময় ঠিক চলেছিল — এটা অস্থায়ী ফল্ট'];
  static const whyPatrol = ['স্থায়ী ফল্টে আবার চার্জ মারাত্মক — খুঁজে সারাতে হয়', 'চার্জে যন্ত্র আরও নষ্ট হয়, আগুন লাগে — আগে টহল'];
  static const whySpot = ['বেশি ঝোলা তার বা কাছের ডালেই ক্ষণিক ছোঁয়া লাগে', 'ঝুলে থাকা তার আর কাছের ডাল — অস্থায়ী ফল্টের জায়গা'];
  static const myths = [
    'কয়েকবার চার্জ দিলে ফল্ট পুড়ে নিজেই সেরে যায়',
    'এইচটি ফিউজ উড়েছে, তাই ফল্ট এইচটি লাইনেই আছে',
    'ফিউজটাই দুর্বল ছিল, মোটা তার দিলেই ঝামেলা শেষ',
    'আবহাওয়ার সাথে ফিউজ ওড়ার কোনো সম্পর্কই নেই',
    'একবার টিকে গেলেই বোঝা যায় লাইনে আর ফল্ট নেই',
    'লগবুক দেখে লাভ নেই, লাগিয়ে দেখলেই সব বোঝা যায়',
    'তাড়াতাড়ি চার্জ দিলেই গ্রাহক খুশি, কারণ লাগে না',
  ];
  static List<String> get allWhyRight => [...whyPermanent, ...whyTransient, ...whyPatrol, ...whySpot];

  static String stampWhyQ(M5ReblowKind k) => k == M5ReblowKind.permanent ? whyPermanentQ : whyTransientQ;
  static List<String> stampWhy(M5ReblowKind k) => k == M5ReblowKind.permanent ? whyPermanent : whyTransient;
  static String followWhyQ(M5ReblowKind k) => k == M5ReblowKind.permanent ? whyPatrolQ : whySpotQ;
  static List<String> followWhy(M5ReblowKind k) => k == M5ReblowKind.permanent ? whyPatrol : whySpot;

  /// The careless coworker: the lesson's myth 1, word for word (fault
  /// burning). New rival line (record with tool/rival_clip.py).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'লাইনটা কয়েকবার চার্জ করে দেখলেই ফল্টটা জ্বলে গিয়ে নিজে থেকেই ঠিক হয়ে যাবে।',
    exitLine: coworkerExit,
    right: [
      'না — এটা ফল্ট বার্নিং, কঠোরভাবে নিষিদ্ধ। আগে পেট্রোলিং।',
      'না, আবার চার্জ নয় — আগে টহল দিয়ে ফল্টটা খুঁজে বের করব।',
      'না, স্থায়ী ফল্টে চার্জ দিলে যন্ত্র নষ্ট হয়, আগুন লাগে।',
    ],
    wrong: [
      'ঠিক, দু-তিনবার লাগিয়ে দেখি — পুড়ে গেলে তো ঝামেলা শেষ।',
      'ছোট ফল্ট, পুড়ে গেলে লাইন আবার দিব্যি চলবে, চার্জ দিই।',
      'হ্যাঁ, অপারেটরকে আরও দু-একবার চার্জ দিতে বলে দিই।',
      'ঠিক আছে, ফল্ট জ্বলে গেলে আর টহলের দরকারই পড়বে না।',
      'আচ্ছা, আরেকবার ফিউজ লাগিয়ে দেখি — এবার হয়তো টিকবে।',
    ],
    asks: ['ও বলছে বারবার চার্জ করে ফল্ট পোড়াতে। কী করবেন?', 'কী করবেন?', 'ওর কথায় আবার চার্জ দেবেন?'],
  );

  static const callHeld = 'ঠিক! ফল্ট বার্নিং নিষিদ্ধ — আগে পেট্রোলিং।';
  static const allSet = 'পাতা পড়ে ফল্ট চিনলেন — স্থায়ীতে টহল, অস্থায়ীতে ঝোলা তার আর ডাল।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে পাতা পড়ুন, ফিউজ কতক্ষণ টেকে দেখুন, তারপর সিদ্ধান্ত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtCheck = 'লাগানোর আগে চোখে দেখেছেন';
  static const caughtPermanent = 'লাগাতেই বিস্ফোরণ — স্থায়ী ফল্ট';
  static const caughtTransient = 'টিকে থেকে উড়ল — অস্থায়ী ফল্ট';
  static const caughtPatrol = 'আবার চার্জ নয় — আগে পেট্রোলিং';
  static const caughtSpot = 'ঝোলা তার আর কাছের ডাল খুঁজেছেন';
  static const caughtCall = 'ফল্ট বার্নিংয়ে “না” বলেছেন';
}

abstract final class M5ReblowMistakes {
  static const _dir = 'assets/game/art/m5_reblow_clock';
  static const _k = '5.4/m5_reblow_clock';

  // Lesson 5.4 points (0-based): 0 where (HT/DTR/LT), 1 transient, 2
  // permanent, 3 sectionalizing.
  static const refitBlast = DoMistake(
    key: '$_k/refit-blast',
    textBn: 'লাগাতেই বিস্ফোরণ আর আর্ক — এটা স্থায়ী ফল্ট। আবার চার্জ করা মারাত্মক ভুল; পেট্রোলিং করে ফল্ট খুঁজে সারান।',
    art: '$_dir/refit_blast.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const faultBurning = DoMistake(
    key: '$_k/fault-burning',
    textBn: 'বারবার চার্জ করে ফল্ট পোড়ানো — ফল্ট বার্নিং — কঠোরভাবে নিষিদ্ধ। স্থায়ী ফল্টে যন্ত্র আরও নষ্ট হয়, আগুন লাগে।',
    art: '$_dir/fault_burning.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const orderRecharge = DoMistake(
    key: '$_k/order-recharge',
    textBn: 'স্থায়ী ফল্টে আবার লাগানো বা চার্জ দেওয়া মারাত্মক ভুল। দলকে পেট্রোলিংয়ে পাঠান — আগে ফল্ট খুঁজে বের করুন।',
    art: '$_dir/refit_blast.svg',
    deadly: true,
    lessonPoint: 2,
  );
  // Pro tip 1 (no section point).
  static const thickWire = DoMistake(
    key: '$_k/thick-wire',
    textBn: 'মোটা তার বা ভুল রেটিং-এর ফিউজ কখনো নয় — এতে সুরক্ষাই নষ্ট হয়, আর ফল্টের উপর আবার চার্জ চলে যায়।',
    art: '$_dir/thick_wire.svg',
    deadly: true,
  );
  // Module 5 ruling M5-8 (not lesson 5.4's text).
  static const noCheck = DoMistake(
    key: '$_k/no-check',
    textBn: 'প্রথমবার লাগানোর আগেও একবার চোখে দেখে নিন — ডিটিআর, ডিও আর স্প্যান। তারপর অপারেটিং রডে, পাশে দাঁড়িয়ে।',
    art: '$_dir/look_first.svg',
  );
  static const refitDelayed = DoMistake(
    key: '$_k/refit-delayed',
    textBn: 'কিছুক্ষণ টিকে আবার উড়েছে — অস্থায়ী ফল্ট। আবার লাগানোর আগে বেশি ঝোলা তার আর কাছের গাছের ডাল দেখে নিন।',
    art: '$_dir/sag_branch.svg',
    lessonPoint: 1,
  );
  // Module 5 ruling M5-10 (evidence first).
  static const noEvidence = DoMistake(
    key: '$_k/no-evidence',
    textBn: 'খালি পাতায় রায় নয়! আগে জানুন লাগানোর পর ফিউজ কতক্ষণ টেকে — তারপর সিল।',
    art: '$_dir/log_empty.svg',
  );
  static const stampWasPermanent = DoMistake(
    key: '$_k/stamp-permanent',
    textBn: 'লাগানোর সাথে সাথেই বিস্ফোরণ আর আর্ক সহ ফিউজ উড়লে — সেটা স্থায়ী ফল্ট, নিজে সারে না।',
    art: '$_dir/blast_page.svg',
    lessonPoint: 2,
  );
  static const stampWasTransient = DoMistake(
    key: '$_k/stamp-transient',
    textBn: 'লাগানোর পর কিছুক্ষণ ঠিক চলে তারপর উড়লে — সেটা অস্থায়ী ফল্ট; কারণটা ক্ষণস্থায়ী।',
    art: '$_dir/held_page.svg',
    lessonPoint: 1,
  );
  static const wrongSpot = DoMistake(
    key: '$_k/wrong-spot',
    textBn: 'অস্থায়ী ফল্টে দেখুন যেখানে তার খুব বেশি ঝুলে আছে বা গাছের ডাল খুব কাছে — স্বাভাবিক ঝোল বা দূরের গাছ নয়।',
    art: '$_dir/sag_branch.svg',
    lessonPoint: 1,
  );

  /// The wrong stamp on a page of [actual] kind.
  static DoMistake wrongStamp(M5ReblowKind actual) => actual == M5ReblowKind.permanent ? stampWasPermanent : stampWasTransient;

  static DoMistake order(String option) => M5ReblowLines.orderKillsFuse(option) ? thickWire : orderRecharge;

  static const all = [
    refitBlast,
    faultBurning,
    orderRecharge,
    thickWire,
    noCheck,
    refitDelayed,
    noEvidence,
    stampWasPermanent,
    stampWasTransient,
    wrongSpot,
  ];
}

/// An older logbook page (noise).
@immutable
class M5ReblowOldPage {
  const M5ReblowOldPage(this.daysAgo, this.notes);
  final int daysAgo;
  final List<String> notes;
}

/// One DTR of the play.
@immutable
class M5ReblowCase {
  const M5ReblowCase({
    required this.kind,
    required this.page,
    required this.held,
    required this.weather,
    required this.note,
    required this.phase,
    required this.dtr,
    required this.village,
    required this.time,
    required this.spots,
    required this.spotPoles,
    required this.older,
  });

  final M5ReblowKind kind;

  /// Blank (a fresh blow) or written before the player came.
  final M5ReblowLog page;

  /// How long the re-fit held ('0 সে' for the permanent fault).
  final String held;

  /// The sign that comes as the barrel drops (transient).
  final M5ReblowWeather weather;

  /// The entry's note: the blast, or the weather sign.
  final String note;

  /// The phase whose barrel dropped (0..2).
  final int phase;
  final int dtr;
  final String village;

  /// Index into [M5ReblowLines.times].
  final int time;

  /// The "কোথায় দেখবেন?" pictures (one right), in their dealt order.
  final List<M5ReblowSpot> spots;

  /// The span each picture is (pole numbers), same order.
  final List<int> spotPoles;
  final List<M5ReblowOldPage> older;

  M5ReblowSpot get rightSpot => spots.firstWhere(m5ReblowSpotRight.contains);
}

@immutable
class M5ReblowDeal {
  const M5ReblowDeal({required this.cases, required this.stampsSwapped});
  final List<M5ReblowCase> cases;

  /// The two stamps' places on the pad (false: স্থায়ী left).
  final bool stampsSwapped;

  bool get hasHistory => cases.any((c) => c.page == M5ReblowLog.history);
}

M5ReblowDeal m5ReblowDeal(math.Random rng) {
  final permanentFirst = rng.nextBool();
  // Page states: 3 of the 4 patterns have a written page (≥ 50 % of plays).
  const patterns = [
    [M5ReblowLog.fresh, M5ReblowLog.fresh],
    [M5ReblowLog.history, M5ReblowLog.fresh],
    [M5ReblowLog.fresh, M5ReblowLog.history],
    [M5ReblowLog.history, M5ReblowLog.history],
  ];
  final pages = patterns[rng.nextInt(patterns.length)];
  final villages = [...M5ReblowLines.villages]..shuffle(rng);
  final dtr0 = 11 + rng.nextInt(40);
  final cases = <M5ReblowCase>[];
  for (var i = 0; i < 2; i++) {
    final kind = (i == 0) == permanentFirst ? M5ReblowKind.permanent : M5ReblowKind.transient;
    final weather = M5ReblowWeather.values[rng.nextInt(M5ReblowWeather.values.length)];
    final right = m5ReblowSpotRight.elementAt(rng.nextInt(2));
    final decoys = [...M5ReblowSpot.values.where((s) => !m5ReblowSpotRight.contains(s))]..shuffle(rng);
    final spots = [right, ...decoys.take(2)]..shuffle(rng);
    final starts = <int>{};
    while (starts.length < 3) {
      starts.add(2 + rng.nextInt(20));
    }
    final notes = [...M5ReblowLines.olderNotes]..shuffle(rng);
    final d1 = 3 + rng.nextInt(20);
    cases.add(M5ReblowCase(
      kind: kind,
      page: pages[i],
      held: kind == M5ReblowKind.permanent ? M5ReblowLines.held0 : M5ReblowLines.heldTimes[rng.nextInt(M5ReblowLines.heldTimes.length)],
      weather: weather,
      note: kind == M5ReblowKind.permanent
          ? M5ReblowLines.blastNotes[rng.nextInt(M5ReblowLines.blastNotes.length)]
          : M5ReblowLines.weatherNote(weather),
      phase: rng.nextInt(3),
      dtr: dtr0 + i * (3 + rng.nextInt(9)),
      village: villages[i],
      time: rng.nextInt(M5ReblowLines.times.length),
      spots: spots,
      spotPoles: starts.toList(),
      older: [
        M5ReblowOldPage(d1, notes.sublist(0, 2)),
        M5ReblowOldPage(d1 + 7 + rng.nextInt(30), notes.sublist(2, 4)),
      ],
    ));
  }
  return M5ReblowDeal(cases: cases, stampsSwapped: rng.nextBool());
}

/// The play state (pure logic).
class M5ReblowRun {
  M5ReblowRun(this.deal);
  final M5ReblowDeal deal;

  int index = 0;
  int slips = 0;
  int caseSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  var stage = M5ReblowStage.read;

  /// The look-first check was done on this DTR.
  var checked = false;

  /// The player's own re-fit result is in (blast seen, or the clock run).
  var seen = false;
  var refitted = false;
  var _noCheckSlip = false;
  M5ReblowKind? stamped;
  var followDone = false;

  M5ReblowCase get now => deal.cases[index.clamp(0, deal.cases.length - 1)];
  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Today's entry is on the page (written before, or by the player's re-fit).
  bool get evidence => now.page == M5ReblowLog.history || seen;
  bool get _open => !ended;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    caseSlips++;
    return m;
  }

  /// The look-first check (any time while reading; costs nothing).
  void check() {
    if (_open && stage == M5ReblowStage.read) checked = true;
  }

  /// Hold the DO to re-fit the dropped barrel.
  DoMistake? refit() {
    if (!_open || stage != M5ReblowStage.read || stamped != null) return null;
    if (evidence) {
      if (now.kind == M5ReblowKind.permanent) return deadly = M5ReblowMistakes.refitBlast;
      return _slip(M5ReblowMistakes.refitDelayed);
    }
    if (!checked) {
      _noCheckSlip = true;
      return _slip(M5ReblowMistakes.noCheck);
    }
    refitted = true;
    if (!_noCheckSlip) _tag(M5ReblowLines.caughtCheck);
    if (now.kind == M5ReblowKind.permanent) {
      seen = true;
    } else {
      stage = M5ReblowStage.holding;
    }
    return null;
  }

  /// Hold the clock: the time-lapse runs until the barrel drops.
  void runClock() {
    if (!_open || stage != M5ReblowStage.holding) return;
    seen = true;
    stage = M5ReblowStage.read;
  }

  /// A stamp dropped on today's entry.
  DoMistake? stamp(M5ReblowKind k) {
    if (!_open || stage != M5ReblowStage.read || stamped != null) return null;
    if (!evidence) return _slip(M5ReblowMistakes.noEvidence);
    if (k != now.kind) return _slip(M5ReblowMistakes.wrongStamp(now.kind));
    stamped = k;
    stage = M5ReblowStage.follow;
    _tag(k == M5ReblowKind.permanent ? M5ReblowLines.caughtPermanent : M5ReblowLines.caughtTransient);
    return null;
  }

  /// The order card picked (permanent).
  DoMistake? order(String option) {
    if (!_open || stage != M5ReblowStage.follow || now.kind != M5ReblowKind.permanent || followDone) return null;
    if (M5ReblowLines.orderRight.contains(option)) {
      followDone = true;
      _tag(M5ReblowLines.caughtPatrol);
      return null;
    }
    return deadly = M5ReblowMistakes.order(option);
  }

  /// The "কোথায় দেখবেন?" picture picked (transient).
  DoMistake? spot(M5ReblowSpot s) {
    if (!_open || stage != M5ReblowStage.follow || now.kind != M5ReblowKind.transient || followDone) return null;
    if (!m5ReblowSpotRight.contains(s)) return _slip(M5ReblowMistakes.wrongSpot);
    followDone = true;
    _tag(M5ReblowLines.caughtSpot);
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    caseSlips = 0;
    stage = M5ReblowStage.read;
    checked = false;
    seen = false;
    refitted = false;
    _noCheckSlip = false;
    stamped = null;
    followDone = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per DTR: read + look + re-fit hold ≈ 4500, clock hold / blast ≈ 2500,
///     stamp drag ≈ 2000, reason ≈ 8200, follow deck ≈ 3000, reason ≈ 8200
///     ≈ 28400 × 2                                              ≈ 56800
/// + the coworker once ≈ 9600                                  ≈ 66400
/// 85 % ≈ 56400 → 60 s.
const m5ReblowQuickMs = 60000;

/// How long the DO and the clock must be held.
const m5ReblowHoldMs = 1000;

@immutable
class M5ReblowPack {
  const M5ReblowPack({required this.id, required this.titleBn, this.quickMs = m5ReblowQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5ReblowPack> m5ReblowPacks = {
  'do_5_4_b': M5ReblowPack(id: 'do_5_4_b', titleBn: M5ReblowLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M5ReblowPage extends StatefulWidget {
  const M5ReblowPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5ReblowPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5ReblowPage> createState() => _M5ReblowPageState();
}

class _M5ReblowPageState extends State<M5ReblowPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ReblowRunPage(
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

class _ReblowRunPage extends ConsumerStatefulWidget {
  const _ReblowRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5ReblowPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ReblowRunPage> createState() => _ReblowRunPageState();
}

class _ReblowRunPageState extends ConsumerState<_ReblowRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5ReblowRun _run;
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

  /// An animation of the scene is playing (the re-fit, the blast, the drop,
  /// the look): no input meanwhile.
  var _busy = false;

  // Scene state.
  var _barrelUp = false;
  var _rod = false;
  var _written = false;
  M5ReblowKind? _imprint;
  int _page = 0;
  double _swipe = 0;
  int _blastTok = 0;
  int _weatherTok = 0;
  int _checkTok = 0;

  // The dragged stamp (design px), and which.
  M5ReblowKind? _dragging;
  Offset? _dragAt;

  // The follow-up (after the stamp's reason).
  var _followOpen = false;
  List<ChoiceOption> _orderOpts = const [];
  final Set<String> _orderWrong = {};
  String? _orderPicked;
  final Set<M5ReblowSpot> _spotWrong = {};
  M5ReblowSpot? _spotPicked;
  var _followBusy = false;

  /// The DO and the clock are held to act.
  late final AnimationController _doHold = AnimationController(vsync: this, duration: const Duration(milliseconds: m5ReblowHoldMs))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _refitHeld();
    });
  late final AnimationController _clockHold = AnimationController(vsync: this, duration: const Duration(milliseconds: m5ReblowHoldMs))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _clockHeld();
    });

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  final Map<M5ReblowSpot, GlobalKey> _spotKeys = {for (final s in M5ReblowSpot.values) s: GlobalKey()};
  int _hintN = 0;
  M5ReblowGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M5ReblowRun(m5ReblowDeal(widget.rng));
    _written = _run.now.page == M5ReblowLog.history;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M5ReblowCase get _case => _run.now;

  @override
  void dispose() {
    disposeCoworker();
    _doHold.dispose();
    _clockHold.dispose();
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_busy && !_followBusy;

  bool get _ordersUp =>
      _followOpen && _case.kind == M5ReblowKind.permanent && !_run.followDone && (coworkerDone || (!coworkerDue && !coworkerOpen));
  bool get _spotsUp => _followOpen && _case.kind == M5ReblowKind.transient && !_run.followDone;

  /// Reading or holding: the hands-on controls are live.
  bool get _handsOn => !_followOpen && (_run.stage == M5ReblowStage.read || _run.stage == M5ReblowStage.holding);

  String get _task {
    if (_spotsUp) return M5ReblowLines.askSpot;
    if (_ordersUp) return M5ReblowLines.askOrder;
    return _run.stage == M5ReblowStage.holding ? M5ReblowLines.askClock : M5ReblowLines.askRead;
  }

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  /// Global → design px of the scene.
  Offset? _toScene(Offset global) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.globalToLocal(global);
  }

  /// A design-px rect on screen (null before layout).
  Rect? _sceneRect(Rect r) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  Offset _globalOf(Rect design) => _sceneRect(design)?.center ?? Offset.zero;

  // --- hands on -----------------------------------------------------------------
  void _holdDown(AnimationController c, bool live) {
    if (!_canPlay || !live) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.4);
    if (identical(c, _clockHold)) _cue('sounds/clock_tick.wav', volume: 0.5);
    unawaited(c.forward(from: 0));
  }

  void _holdUp(AnimationController c) {
    if (c.isAnimating) {
      c.stop();
      c.value = 0;
    }
  }

  bool get _doLive => _run.stage == M5ReblowStage.read && !_followOpen && _run.stamped == null;
  bool get _clockLive => _run.stage == M5ReblowStage.holding;

  /// The DO was held long enough: re-fit.
  Future<void> _refitHeld() async {
    _doHold.value = 0;
    if (!_canPlay || !_doLive) return;
    final geo = _geoNow;
    final at = geo == null ? Offset.zero : _globalOf(geo.doHit(_case.phase));
    final m = _run.refit();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, at));
      return;
    }
    _hush();
    _busy = true;
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    setState(() {
      _rod = true;
      _barrelUp = true;
      _wake++;
    });
    final idx = _run.index;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || _ended || _run.index != idx) return;
    if (_case.kind == M5ReblowKind.permanent) {
      // The instant blast with arc.
      HapticFeedback.heavyImpact();
      _cue('sounds/learn/spark.wav', volume: 0.9);
      _cue('sounds/learn/thunder_near.wav', volume: 0.7);
      setState(() {
        _blastTok++;
        _barrelUp = false;
        _rod = false;
        _written = true;
        _wake++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted || _ended || _run.index != idx) return;
      setState(() => _busy = false);
      unawaited(_sayChain([M5ReblowLines.askRead]));
    } else {
      setState(() {
        _rod = false;
        _busy = false;
        _wake++;
      });
      unawaited(_sayChain([M5ReblowLines.askClock]));
    }
  }

  /// The clock was held: the time-lapse ran; the sign comes and the barrel drops.
  Future<void> _clockHeld() async {
    if (!_canPlay || !_clockLive) {
      _clockHold.value = 0;
      return;
    }
    _hush();
    _run.runClock();
    _busy = true;
    final idx = _run.index;
    _cue(switch (_case.weather) {
      M5ReblowWeather.wind => 'sounds/learn/wind_gust.wav',
      M5ReblowWeather.lightning => 'sounds/learn/thunder_clap.wav',
      M5ReblowWeather.bird => 'sounds/learn/rush_out.wav',
    }, volume: 0.7);
    setState(() {
      _weatherTok++;
      _wake++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || _ended || _run.index != idx) return;
    _cue('sounds/intro/drop.ogg', volume: 0.8);
    setState(() {
      _barrelUp = false;
      _written = true;
      _wake++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _ended || _run.index != idx) return;
    setState(() => _busy = false);
    unawaited(_sayChain([M5ReblowLines.askRead]));
  }

  void _look() {
    if (!_canPlay || !_handsOn || _run.stage != M5ReblowStage.read) return;
    _tick('sounds/intro/click.ogg', 0.5);
    _run.check();
    _busy = true;
    setState(() {
      _checkTok++;
      _wake++;
    });
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 1300), () {
      if (mounted && _run.index == idx) setState(() => _busy = false);
    }));
  }

  void _flip(double v) {
    if (!_canPlay) return;
    final older = v > 0 || (v == 0 && _swipe > 0);
    final next = (_page + (older ? 1 : -1)).clamp(0, _case.older.length);
    if (next == _page) return;
    _cue('sounds/quiz_flip.wav', volume: 0.5);
    setState(() => _page = next);
  }

  void _dragStart(M5ReblowKind k, Offset global) {
    if (!_canPlay || !_handsOn || _run.stage != M5ReblowStage.read) return;
    _tick();
    setState(() {
      _dragging = k;
      _dragAt = _toScene(global);
    });
  }

  void _dragMove(Offset global) {
    if (_dragging == null) return;
    setState(() => _dragAt = _toScene(global));
  }

  void _dragEnd() {
    final k = _dragging;
    final at = _dragAt;
    final geo = _geoNow;
    setState(() {
      _dragging = null;
      _dragAt = null;
    });
    if (k == null || at == null || geo == null || !_canPlay) return;
    if (_page != 0 || !geo.today.inflate(12).contains(at)) {
      _hints.missTap();
      return;
    }
    final origin = _globalOf(geo.today);
    final m = _run.stamp(k);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.8);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    setState(() {
      _imprint = k;
      _wake++;
    });
    putOnTable(15 + (_run.caseSlips == 0 ? 5 : 0));
    final idx = _run.index;
    final kind = _case.kind;
    unawaited(askReason(
      deal: () => dealChoices(M5ReblowLines.stampWhy(kind), M5ReblowLines.myths, widget.rng),
      question: M5ReblowLines.stampWhyQ(kind),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  /// After the stamp's reason: the follow-up opens.
  void _openFollow() {
    if (_case.kind == M5ReblowKind.permanent) {
      // He comes first; the order deck waits for him.
      scheduleCoworker();
      setState(() {
        _followOpen = true;
        _orderOpts = dealChoices(M5ReblowLines.orderRight, M5ReblowLines.orderWrong, widget.rng);
        _orderWrong.clear();
        _orderPicked = null;
      });
    } else {
      _cue('sounds/learn/card_deal_a.wav', volume: 0.6);
      setState(() {
        _followOpen = true;
        _spotWrong.clear();
        _spotPicked = null;
      });
      unawaited(_sayChain([M5ReblowLines.askSpot], mood: GuideMood.think));
    }
  }

  Future<void> _pickOrder(ChoiceOption o, Offset origin) async {
    if (holdForCoworker()) return;
    if (!_canPlay || !_ordersUp || _orderWrong.contains(o.textBn) || _orderPicked != null) return;
    _hush();
    if (!o.correct) {
      setState(() => _orderWrong.add(o.textBn));
      final m = _run.order(o.textBn);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _followBusy = true;
    setState(() => _orderPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _run.order(o.textBn);
    _followBusy = false;
    _followDone();
  }

  Future<void> _pickSpot(M5ReblowSpot s, Offset origin) async {
    if (!_canPlay || !_spotsUp || _spotWrong.contains(s) || _spotPicked != null) return;
    _hush();
    if (!m5ReblowSpotRight.contains(s)) {
      HapticFeedback.mediumImpact();
      setState(() => _spotWrong.add(s));
      final m = _run.spot(s);
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _followBusy = true;
    setState(() => _spotPicked = s);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted || _ended) return;
    _run.spot(s);
    _followBusy = false;
    _followDone();
  }

  void _followDone() {
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    putOnTable(10);
    final idx = _run.index;
    final kind = _case.kind;
    unawaited(askReason(
      deal: () => dealChoices(M5ReblowLines.followWhy(kind), M5ReblowLines.myths, widget.rng),
      question: M5ReblowLines.followWhyQ(kind),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(() {
      _run.next();
      _page = 0;
      _followOpen = false;
      _imprint = null;
      _barrelUp = false;
      _rod = false;
      _written = !_run.done && _run.now.page == M5ReblowLog.history;
      _blastTok = 0;
      _weatherTok = 0;
      _checkTok = 0;
      _orderOpts = const [];
      _orderWrong.clear();
      _orderPicked = null;
      _spotWrong.clear();
      _spotPicked = null;
      _wake++;
    });
    _clockHold.value = 0;
    _doHold.value = 0;
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    unawaited(_sayChain([M5ReblowLines.askNext, M5ReblowLines.askRead]));
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
    if (!_run.followDone) {
      if (_run.stage == M5ReblowStage.follow && !_followOpen) _openFollow();
      return;
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5ReblowLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended) return null;
    if (_run.stage != M5ReblowStage.follow || _case.kind != M5ReblowKind.permanent || _run.followDone) return null;
    if (_intro || _card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the faulted line is charged again (fault burning).
      _run.failDeadly(M5ReblowMistakes.faultBurning);
      await _deadly(M5ReblowMistakes.faultBurning);
      return;
    }
    _run.caught.add(M5ReblowLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    _cue('sounds/learn/card_deal_a.wav', volume: 0.5);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5ReblowLines.callHeld, M5ReblowLines.askOrder], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5ReblowLines.tapWhy[_nudgeN++ % M5ReblowLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('reblow/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The faulted line charged again: the scene freezes grey and the blast
  /// comes off the DO in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _doHold.stop();
    _clockHold.stop();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _rod = true;
      _barrelUp = true;
      _dragging = null;
      _dragAt = null;
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
    final speak = await SpokenOnce.first('reblow/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5ReblowLines.deadlyWord : M5ReblowLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
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
    await _say(!_run.passed ? M5ReblowLines.fail : (_quickBonus ? M5ReblowLines.quick : M5ReblowLines.allSet),
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
    if (_rod) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_spotsUp) {
      final rects = [
        for (final s in _case.spots)
          if (!_spotWrong.contains(s)) ?HintSpec.globalRectOf(_spotKeys[s]!),
      ];
      return rects.length < 2 ? null : HintSpec.sweep(rects);
    }
    if (_run.stage == M5ReblowStage.holding) {
      // The clock is the only control: hold it.
      final r = _sceneRect(geo.dial);
      return r == null ? null : HintSpec.hold(r.center);
    }
    // Reading: a page-flip swipe, then (next time) an equal lap over the DO,
    // both stamps and the look button.
    if (_hintN++ % 2 == 0) {
      final r = _sceneRect(geo.log);
      return r == null ? null : HintSpec.swipe(r.center.translate(-40, 10), toward: const Offset(1, 0), travel: 90);
    }
    final rects = [
      ?_sceneRect(geo.doHit(_case.phase)),
      ?_sceneRect(geo.stamp(0)),
      ?_sceneRect(geo.stamp(1)),
      ?_sceneRect(geo.check),
    ];
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  int _stampSlot(M5ReblowKind k) => (k == M5ReblowKind.permanent) != _run.deal.stampsSwapped ? 0 : 1;

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5ReblowGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final c = _case;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final seed = c.dtr * 7 + c.phase;
    final controls = _handsOn && !_freeze && !_ended;
    final holding = _run.stage == M5ReblowStage.holding;
    return [
      Positioned.fill(key: const ValueKey('scene-box'), child: IgnorePointer(child: SizedBox(key: _sceneKey))),
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('sky'),
                child: RepaintBoundary(
                  child: CustomPaint(painter: M5ReblowSkyPainter(geo: geo, lapse: _clockHold, hour: M5ReblowLines.timeHour[c.time], seed: seed)),
                ),
              ),
              if (_weatherTok > 0 && c.kind == M5ReblowKind.transient)
                Positioned.fill(
                  key: ValueKey('weather-${_run.index}-$_weatherTok'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 1400),
                      builder: (_, v, _) => CustomPaint(painter: M5ReblowWeatherPainter(geo: geo, weather: c.weather, v: v)),
                    ),
                  ),
                ),
              Positioned.fill(
                key: const ValueKey('dtr'),
                child: RepaintBoundary(
                  child: CustomPaint(painter: M5ReblowWorldPainter(geo: geo, rig: M5ReblowRig(phase: c.phase, barrelUp: _barrelUp, rod: _rod, seed: seed))),
                ),
              ),
              Positioned(
                key: const ValueKey('plate'),
                left: geo.tank.right + 6,
                top: geo.tank.top + 18,
                child: _Plate(text: 'DTR ${c.dtr}'),
              ),
              // Ruling M5-8: the fuse that goes back in is the correct rating.
              Positioned.fromRect(
                key: const ValueKey('rating-tag'),
                rect: geo.ratingTag,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(fit: BoxFit.scaleDown, child: _Plate(text: M5ReblowLines.ratingTag)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              Positioned.fill(
                key: const ValueKey('bonnet'),
                child: RepaintBoundary(child: CustomPaint(painter: M5ReblowBonnetPainter(geo: geo))),
              ),
            ],
          ),
        ),
      ),
      // The blast on a fresh page (the permanent fault shows itself).
      if (_blastTok > 0 && !_freeze)
        Positioned.fill(
          key: ValueKey('blast-${_run.index}-$_blastTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder: (_, v, _) => v >= 0.999 ? const SizedBox.shrink() : CustomPaint(painter: M5ReblowBlastPainter(geo: geo, phase: c.phase, v: v)),
            ),
          ),
        ),
      // The look-first check: the DTR, the DO and the span in turn.
      if (_checkTok > 0 && !_freeze)
        Positioned.fill(
          key: ValueKey('check-${_run.index}-$_checkTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              builder: (_, v, _) => v >= 0.999 ? const SizedBox.shrink() : CustomPaint(painter: _LookPainter(m5ReblowCheckSpots(geo, c.phase), v)),
            ),
          ),
        ),
      // Taps on nothing (the hint counts them).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5ReblowLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (_) => _hints.missTap()),
        ),
      ),
      // The logbook.
      Positioned.fromRect(
        key: const ValueKey('log'),
        rect: geo.log,
        child: GestureDetector(
          key: const ValueKey('reblow-log'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _swipe = 0,
          onHorizontalDragUpdate: (d) => _swipe += d.primaryDelta ?? 0,
          onHorizontalDragEnd: (d) => _flip(_swipe.abs() > 24 ? _swipe : (d.primaryVelocity ?? 0)),
          child: Semantics(
            label: M5ReblowLines.logLabel,
            child: _LogBook(
              head: M5ReblowLines.logHead(c.dtr, c.village),
              page: _page,
              pages: c.older.length + 1,
              older: _page == 0 ? null : c.older[_page - 1],
              time: M5ReblowLines.times[c.time],
              entry: _written ? (M5ReblowLines.heldLine(c.held), c.note) : null,
              imprint: _imprint == null ? null : M5ReblowLines.stampLabel(_imprint!),
              todayRect: geo.today.shift(-geo.log.topLeft),
            ),
          ),
        ),
      ),
      // The stopwatch dial in the logbook's corner (held when it is the only control).
      Positioned.fromRect(
        key: const ValueKey('dial'),
        rect: geo.dial,
        child: Semantics(
          label: M5ReblowLines.clockLabel,
          button: holding,
          child: Listener(
            key: const ValueKey('reblow-clock'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _holdDown(_clockHold, _clockLive),
            onPointerUp: (_) => _holdUp(_clockHold),
            onPointerCancel: (_) => _holdUp(_clockHold),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: M5ReblowDialPainter(run: _clockHold, live: holding),
                foregroundPainter: holding ? M5ReblowHoldRingPainter(fill: _clockHold, armed: !_freeze) : null,
              ),
            ),
          ),
        ),
      ),
      // The DO: hold to re-fit.
      if (controls && !holding)
        Positioned.fromRect(
          key: ValueKey('do-${_run.index}'),
          rect: geo.doHit(c.phase),
          child: Semantics(
            label: M5ReblowLines.doLabel,
            button: true,
            child: Listener(
              key: const ValueKey('reblow-do'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _holdDown(_doHold, _doLive),
              onPointerUp: (_) => _holdUp(_doHold),
              onPointerCancel: (_) => _holdUp(_doHold),
              child: RepaintBoundary(child: CustomPaint(painter: M5ReblowHoldRingPainter(fill: _doHold, armed: true))),
            ),
          ),
        ),
      // The stamps on the ink pad.
      if (controls && !holding)
        for (final k in M5ReblowKind.values)
          Positioned.fromRect(
            key: ValueKey('stamp-${k.name}'),
            rect: geo.stamp(_stampSlot(k)),
            child: Semantics(
              label: M5ReblowLines.stampLabel(k),
              button: true,
              child: GestureDetector(
                key: ValueKey('reblow-stamp-${k.name}'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => _dragStart(k, d.globalPosition),
                onPanUpdate: (d) => _dragMove(d.globalPosition),
                onPanEnd: (_) => _dragEnd(),
                onPanCancel: () => setState(() {
                  _dragging = null;
                  _dragAt = null;
                }),
                child: Opacity(opacity: _dragging == k ? 0.35 : 1, child: _Stamp(label: M5ReblowLines.stampLabel(k))),
              ),
            ),
          ),
      if (controls && !holding)
        Positioned.fromRect(
          key: const ValueKey('look'),
          rect: geo.check,
          child: _LookButton(
            key: const ValueKey('reblow-check'),
            label: M5ReblowLines.lookLabel,
            on: _run.checked,
            onTap: _look,
          ),
        ),
      if (_dragging != null && _dragAt != null)
        Positioned(
          key: const ValueKey('stamp-ghost'),
          left: _dragAt!.dx - 26,
          top: _dragAt!.dy - 39,
          width: 52,
          height: 78,
          child: IgnorePointer(child: _Stamp(label: M5ReblowLines.stampLabel(_dragging!), lifted: true)),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('freeze-blast'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M5ReblowBlastPainter(geo: geo, phase: c.phase, v: 0.25 + 0.5 * v)),
            ),
          ),
        ),
      // The next DTR: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('case-${_run.index}'),
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
    final ordersUp = _ordersUp && playing;
    final spotsUp = _spotsUp && playing;
    final deckUp = reasonOpen || coworkerChoiceUp || ordersUp || spotsUp;
    final waitingHim = _followOpen && _case.kind == M5ReblowKind.permanent && !coworkerDone;
    final waiting = playing && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_busy && !_followBusy && !ordersUp && !waitingHim;
    final scale = size.width / 360;
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
              labels: M5ReblowLines.cases,
              done: {for (var i = 0; i < math.min(_run.index, 2); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting && (_handsOn || spotsUp),
            hintKey: '${_run.index}/${_run.stage.name}/$_followOpen/${_spotWrong.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
                            : ordersUp
                                ? ChoiceDeck(
                                    key: ValueKey('order-deck-${_run.index}'),
                                    options: _orderOpts,
                                    quiet: quiet,
                                    muted: _muted,
                                    wrong: _orderWrong,
                                    picked: _orderPicked,
                                    onPick: (o, at) => unawaited(_pickOrder(o, at)),
                                  )
                                : _SpotDeck(
                                    key: ValueKey('spot-deck-${_run.index}'),
                                    spots: _case.spots,
                                    poles: _case.spotPoles,
                                    keys: _spotKeys,
                                    wrong: _spotWrong,
                                    picked: _spotPicked,
                                    quiet: quiet,
                                    onPick: (s, at) => unawaited(_pickSpot(s, at)),
                                  ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : M5ReblowGeo.bonnetH * scale + 4),
                  // On the right (the trainee stands on the left), unless he peeps from the right.
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
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
                  line: M5ReblowLines.intro,
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

/// The DTR's number plate (a label a worker reads).
class _Plate extends StatelessWidget {
  const _Plate({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFF3C93C), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFF3A3020))),
        child: Text(text, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A2210), height: 1.1)),
      );
}

/// The logbook page: today (the entry, if any, and the stamp's imprint) or an
/// older page (routine notes). Facts only.
class _LogBook extends StatelessWidget {
  const _LogBook({
    required this.head,
    required this.page,
    required this.pages,
    required this.older,
    required this.time,
    required this.entry,
    required this.imprint,
    required this.todayRect,
  });

  final String head;
  final int page;
  final int pages;
  final M5ReblowOldPage? older;
  final String time;
  final (String, String)? entry;
  final String? imprint;
  final Rect todayRect;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF1F2A44), height: 1.25);
    final dim = bangla(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF6A6F7A), height: 1.2);
    final old = older;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8E8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB9A57A), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            right: 56,
            top: 8,
            child: Text(head, maxLines: 2, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF3A2E14), height: 1.2)),
          ),
          for (var i = 0; i < 6; i++)
            Positioned(
              left: 8,
              right: 8,
              top: 56.0 + i * 22,
              child: Container(height: 1, color: const Color(0x33405A90)),
            ),
          if (old != null) ...[
            Positioned(left: 10, right: 10, top: 62, child: Text(M5ReblowLines.daysAgo(old.daysAgo), style: dim)),
            for (final (i, n) in old.notes.indexed)
              Positioned(left: 10, right: 10, top: 84.0 + i * 24, child: Text(n, maxLines: 1, overflow: TextOverflow.ellipsis, style: ink)),
          ] else ...[
            Positioned(left: 10, right: 10, top: 62, child: Text('${M5ReblowLines.today} · $time', style: dim)),
            Positioned.fromRect(
              rect: todayRect,
              child: Container(
                key: const ValueKey('reblow-today'),
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                decoration: BoxDecoration(
                  color: const Color(0x0F1F2A44),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0x55405A90)),
                ),
                child: Stack(
                  children: [
                    if (entry == null)
                      Align(alignment: Alignment.centerLeft, child: Text(M5ReblowLines.blankToday, style: dim))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry!.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: ink),
                          Text(entry!.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: ink),
                        ],
                      ),
                    if (imprint != null)
                      Align(
                        key: const ValueKey('reblow-imprint'),
                        alignment: Alignment.centerRight,
                        child: Transform.rotate(
                          angle: -0.18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xCC5A3C8C), width: 2), borderRadius: BorderRadius.circular(6)),
                            child: Text(imprint!, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xCC5A3C8C))),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          // Page dots (older pages to the right: swipe).
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages; i++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: i == page ? const Color(0xFF3A2E14) : const Color(0x553A2E14)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One rubber stamp; the two are identical but for the word on the handle.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, this.lifted = false});
  final String label;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFF8A5A33), Color(0xFF4E2F17)]),
            boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 10 : 3, offset: Offset(0, lifted ? 6 : 2))],
          ),
        ),
        Container(width: 10, height: 12, color: const Color(0xFF5E3A1E)),
        Container(
          width: 52,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2F3540),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF5A3C8C), width: 2),
          ),
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(label, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

/// The look-first button.
class _LookButton extends StatelessWidget {
  const _LookButton({super.key, required this.label, required this.on, required this.onTap});
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
            ),
            border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.2 : 1.6),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_rounded, size: 22, color: ring),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three outlines in turn (the DTR, the DO, the span): what the look covers.
class _LookPainter extends CustomPainter {
  const _LookPainter(this.rects, this.v);
  final List<Rect> rects;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    for (final (i, r) in rects.indexed) {
      final t = ((v * rects.length) - i).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final a = math.sin(t * math.pi);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.8 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
    }
  }

  @override
  bool shouldRepaint(_LookPainter old) => old.v != v || old.rects != rects;
}

/// The "কোথায় দেখবেন?" deck: three span pictures (no captions naming the
/// hazard — only the poles a worker would read).
class _SpotDeck extends StatelessWidget {
  const _SpotDeck({
    super.key,
    required this.spots,
    required this.poles,
    required this.keys,
    required this.wrong,
    required this.picked,
    required this.quiet,
    required this.onPick,
  });

  final List<M5ReblowSpot> spots;
  final List<int> poles;
  final Map<M5ReblowSpot, GlobalKey> keys;
  final Set<M5ReblowSpot> wrong;
  final M5ReblowSpot? picked;
  final bool quiet;
  final void Function(M5ReblowSpot spot, Offset origin) onPick;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 0 : 1, end: 0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 180 * v), child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
        decoration: const BoxDecoration(
          color: Color(0xF20B1324),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: Color(0x66F2C94C), width: 1.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(M5ReblowLines.askSpot, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final (i, s) in spots.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _SpotCard(
                        key: keys[s],
                        spot: s,
                        n: i + 1,
                        label: M5ReblowLines.spotPoles(poles[i]),
                        state: picked == s ? 1 : (wrong.contains(s) ? -1 : 0),
                        onTap: (at) => onPick(s, at),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({super.key, required this.spot, required this.n, required this.label, required this.state, required this.onTap});
  final M5ReblowSpot spot;
  final int n;
  final String label;

  /// 1 = picked right, −1 = tried and wrong, 0 = open.
  final int state;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final edge = switch (state) {
      1 => SlmColors.success,
      -1 => const Color(0xFFE5484D),
      _ => const Color(0x99F2C94C),
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('reblow-spot-${spot.name}'),
        behavior: HitTestBehavior.opaque,
        onTapUp: state == 0 ? (d) => onTap(d.globalPosition) : null,
        child: Opacity(
          opacity: state == -1 ? 0.5 : 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: edge, width: state == 0 ? 1.6 : 3),
              color: const Color(0xFF15233B),
            ),
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(aspectRatio: 1.1, child: CustomPaint(painter: M5ReblowSpotPainter(spot))),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$n', style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
                    const SizedBox(width: 5),
                    Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
