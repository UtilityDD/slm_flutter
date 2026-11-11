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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_meter_setup_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.2 (মাল্টিমিটারের জাদু), কাজ 1: "ডায়াল আর সকেট". At an LT service
// wall with a docket of three measurements. First the meter: three lie in the
// case — read the CAT label up close, run a finger along both leads (a cut in
// the insulation, a rusty probe tip show only where the hand has been), turn
// the knob to switch it on (a low battery shows on the display); take it or
// put it back. A CAT II meter for a line-side job is deadly (the lesson's
// myth: "যন্ত্রটি বিস্ফোরিত হতে পারে"). Then the three jobs, dealt in a fresh
// order: phase–neutral voltage at the incoming terminals (AC), the fuse
// (continuity — the isolator must go OFF first, then read the result: beep
// = good, OL = blown), and the street-light battery (DC). For each, turn the
// dial and plug the leads (black → COM, red → VΩmA), then touch the probes.
// On one job the leads were left from a current measurement (red in 10A,
// dial at A) — the player must notice. The red lead in 10A across the live
// terminals is deadly (a short through the meter). Once a play the careless
// coworker (level 1's rival) peeps in: "যেকোনো সকেটে লাগাও, মিটারই বুঝে
// নেবে!" (on the AC job) or the lesson's any-meter myth (at the case).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" → next job by itself.
// Voice: the guide's lines on device TTS; the coworker's two new pushes on
// device TTS too until recorded (listed in M2MeterLines.toRecord); his exit
// line is an existing clip.

// ============================================================================
// Content
// ============================================================================

/// The meter's CAT rating (the lesson: a lineman needs CAT III or CAT IV).
enum MeterCat { cat2, cat3, cat4 }

extension MeterCatText on MeterCat {
  String get label => switch (this) {
    MeterCat.cat2 => 'CAT II 600V',
    MeterCat.cat3 => 'CAT III 600V',
    MeterCat.cat4 => 'CAT IV 600V',
  };
  String get short => switch (this) {
    MeterCat.cat2 => 'CAT II',
    MeterCat.cat3 => 'CAT III',
    MeterCat.cat4 => 'CAT IV',
  };
}

enum MeterFlaw { none, cutLead, rustyTip, lowBattery }

@immutable
class MeterItem {
  const MeterItem({required this.id, required this.cat, this.flaw = MeterFlaw.none, this.onRed = true, this.body = 0});
  final String id;
  final MeterCat cat;
  final MeterFlaw flaw;

  /// Which lead has the cut / the rusty tip.
  final bool onRed;

  /// The body colour (0 yellow, 1 orange, 2 grey) — never tells the rating.
  final int body;

  bool get fit => cat != MeterCat.cat2 && flaw == MeterFlaw.none;
}

/// The docket's three measurements.
enum MeterJob { acLt, fuse, dcBattery }

extension MeterJobText on MeterJob {
  String get docketBn => switch (this) {
    MeterJob.acLt => 'এলটি টার্মিনালে ফেজ–নিউট্রাল ভোল্টেজ',
    MeterJob.fuse => 'বোর্ডের ফিউজ পরীক্ষা',
    MeterJob.dcBattery => 'স্ট্রিটলাইটের ব্যাটারির ভোল্টেজ',
  };
  String get dot => switch (this) {
    MeterJob.acLt => 'টার্মিনাল',
    MeterJob.fuse => 'ফিউজ',
    MeterJob.dcBattery => 'ব্যাটারি',
  };
}

/// The dial's functions, in order round the knob.
enum MeterDial { off, vac, vdc, ohm, cont, amp }

/// The three input sockets, left to right as on the lesson's meter.
enum MeterSock { a10, com, vohm }

extension MeterSockText on MeterSock {
  String get label => switch (this) {
    MeterSock.a10 => '10A',
    MeterSock.com => 'COM',
    MeterSock.vohm => 'VΩmA',
  };
}

enum MeterLead { red, black }

/// What the careless coworker pushes.
enum MeterPush { socket, anyMeter }

@immutable
class MeterDeal {
  const MeterDeal({
    required this.meters,
    required this.jobs,
    required this.leftover,
    required this.fuseGood,
    required this.push,
    required this.acVolts,
    required this.dcVolts,
  });

  /// The case: one fit meter (CAT III or IV, sound), a CAT II one, a flawed one.
  final List<MeterItem> meters;

  /// The docket's jobs, in this play's order.
  final List<MeterJob> jobs;

  /// The job (index into [jobs]) where the leads were left from a current
  /// measurement: red in 10A, dial at A.
  final int leftover;
  final bool fuseGood;
  final MeterPush push;
  final String acVolts;
  final String dcVolts;

  /// The round he comes on: at the case, or on the terminal job.
  int get callRound => push == MeterPush.anyMeter ? 0 : jobs.indexOf(MeterJob.acLt) + 1;
}

abstract final class M2MeterLines {
  static const title = 'ডায়াল আর সকেট';
  static const intro = 'ডকেটে তিনটে মাপার কাজ! আগে ঠিক মিটার, তারপর ডায়াল আর সকেট মিলিয়ে মাপুন।';

  static const askMeter = 'কেসে তিনটে মিটার। কোনটা নেবেন?';
  static const inspectAsk = 'লেবেল পড়ুন, দুটো লিডে আঙুল বোলান, ডায়াল ঘুরিয়ে চালু করুন। নেবেন?';
  static String askJob(MeterJob j) => switch (j) {
    MeterJob.acLt => 'টার্মিনালের ভোল্টেজ মাপুন।',
    MeterJob.fuse => 'ফিউজটা ভালো কিনা দেখুন।',
    MeterJob.dcBattery => 'ব্যাটারির ভোল্টেজ মাপুন।',
  };
  static const judgeAsk = 'রিডিং দেখুন — ফিউজ ভালো, না কাটা?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const needLeads = 'দুটো লিডই আগে সকেটে লাগান।';
  static const needOn = 'মিটার তো বন্ধ — ডায়ালটা ঘোরান।';

  // Labels a worker reads (and screen-reader names).
  static const docket = 'ডকেট';
  static const docketHead = 'এলটি সার্ভিস পয়েন্ট';
  static const meterLabel = 'মিটার';
  static const handLabel = 'লিড হাতে';
  static const knobLabel = 'ডায়াল';
  static const redLead = 'লাল লিড';
  static const blackLead = 'কালো লিড';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const probe = 'প্রোব ছোঁয়ান';
  static const fuseOk = 'ফিউজ ভালো';
  static const fuseBlown = 'ফিউজ কাটা';
  static const rejected = 'বাতিল';
  static const on = 'ON';
  static const off = 'OFF';
  static const isolatorLabel = 'আইসোলেটর';
  static const batteryTag = '12V';

  // The reasons (lesson 2.2). Within a set, every card is about the same
  // length (test: within 1.3×).
  static const meterAsk = 'কেন এই মিটারটা নিলেন?';
  static String catMatch(MeterCat c) => 'লাইনের কাজে ${c.short} মিটার, লিডও অক্ষত';
  static const meterSound = ['CAT রেটিং ঠিক, লিড-প্রোব-ব্যাটারিও ঠিক'];
  static const meterMyths = [
    'যেকোনো মিটারেই যেকোনো লাইন মাপা যায়',
    'CAT II মিটারই লাইনের কাজে যথেষ্ট',
    'চকচকে নতুন মিটার, তাই এটাই নিলাম',
    'ব্যাটারি কম হলেও রিডিং ঠিকই আসে',
    'লিডের তার একটু কাটা হলে কিছু হয় না',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিলাম',
  ];
  static List<String> meterRight(MeterCat c) => [catMatch(c), ...meterSound];

  static const jobAsk = 'কেন এভাবে সেট করলেন?';
  static const acRight = ['লাইনে AC, তাই ডায়াল V~-এ রেখেছি', 'কালো COM-এ, লাল VΩmA-তে, ডায়াল V~'];
  static const acWrong = [
    'লাল লিড 10A-তে দিলে রিডিং জোরালো হয়',
    'লাইনে DC থাকে, তাই DC ভোল্টেই মাপলাম',
    'যেকোনো সকেটে দিলে মিটারই বুঝে নেয়',
    'ভোল্ট মাপতে কন্টিনিউটি মোডই যথেষ্ট',
    'ডায়াল যেখানেই থাক, প্রোব ছোঁয়ালেই হয়',
  ];
  static const dcRight = ['ব্যাটারিতে DC, তাই ডায়াল DC ভোল্টে', 'কালো COM-এ, লাল VΩmA-তে, ডায়াল DC'];
  static const dcWrong = [
    'ব্যাটারিতেও লাইনের মতো AC থাকে',
    'লাল লিড 10A-তে দিলে রিডিং জোরালো হয়',
    'যেকোনো সকেটে দিলে মিটারই বুঝে নেয়',
    'ব্যাটারি মাপতে ওহম মোডই সবচেয়ে ভালো',
    'ডায়াল যেখানেই থাক, প্রোব ছোঁয়ালেই হয়',
  ];
  static const fuseAsk = 'কেন ফিউজটা এভাবে যাচাই করলেন?';
  static String fuseResult(bool good) => good ? 'সংযোগ পাওয়া গেল — ফিউজটা ভালো' : 'সংযোগ নেই — ফিউজটা উড়ে গেছে';
  static const fuseSound = ['পাওয়ার বন্ধ করে তবেই কন্টিনিউটি', 'আগে সুইচ বন্ধ, তারপর ফিউজে প্রোব'];
  static const fuseMyths = [
    'চালু লাইনেই কন্টিনিউটি মাপা চলে',
    'ফিউজ মাপতে ডায়াল V~-এ রাখলেই হয়',
    'ফিউজ দেখতে লাল লিড 10A-তেই ঠিক',
    'সুইচ বন্ধের দরকার নেই, ফিউজ তো ছোট',
    'বিপ না হলেও ফিউজটা ভালোই থাকে',
  ];
  static List<String> fuseRight(bool good) => [fuseResult(good), ...fuseSound];
  static List<String> fuseWrong(bool good) => [fuseResult(!good), ...fuseMyths];

  /// The careless coworker. His pushes are new lines (device TTS until
  /// recorded in his voice); the exit line is an existing clip.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerSocket = CoworkerScript(
    line: 'যেকোনো সকেটে লাগাও, মিটারই বুঝে নেবে!',
    exitLine: coworkerExit,
    right: ['না — লাল লিড VΩmA-তেই থাকবে', 'ভোল্টে 10A সকেট কখনো নয়', 'সকেট দেখে লাগাব, আন্দাজে নয়'],
    wrong: ['ঠিক, মিটার নিজেই বুঝে নেবে', 'যেটা কাছে, সেটাতেই লাগাই', 'লাল লিড 10A-তেই গুঁজে দিই', 'একবার 10A দিয়েই মেপে নিই', 'সবাই তো যেকোনো সকেটে দেয়'],
    asks: ['ও বলছে যেকোনো সকেটেই চলবে। আপনি কী করবেন?', 'আন্দাজে সকেট, না দেখে শুনে?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerAnyMeter = CoworkerScript(
    line: 'যেকোনো মাল্টিমিটার দিয়েই যেকোনো লাইনের ভোল্টেজ মাপা যায়! চকচকেটাই নাও।',
    exitLine: coworkerExit,
    right: ['না — লাইনে CAT III/IV মিটার', 'রেটিং না দেখে মিটার নেব না', 'CAT II মিটার লাইনে কখনো নয়'],
    wrong: [
      'ঠিক বলেছ, মিটার তো মিটারই',
      'চকচকেটাই তাহলে নিয়ে যাই',
      'একবার CAT II দিয়েই মেপে নিই',
      'রেটিং দেখার সময় নেই, চলো',
      'সবাই তো যেটা পায় সেটাই নেয়',
    ],
    asks: ['ও বলছে যেকোনো মিটারেই চলবে। আপনি কী করবেন?', 'রেটিং দেখবেন, না চকচকে দেখে?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(MeterPush p) => p == MeterPush.socket ? coworkerSocket : coworkerAnyMeter;

  /// New lines to record (his voice: the two pushes; the guide: everything here).
  static List<String> get toRecord => [coworkerSocket.line, coworkerAnyMeter.line];

  static const callHeld = 'ঠিক! সকেট আর রেটিং — দেখে শুনে।';
  static const asideFlaw = 'ঠিক — খারাপ মিটার বাতিল।';
  static const asideCat = 'ঠিক — CAT II লাইনের কাজে নয়।';
  static const switchedOff = 'সুইচ বন্ধ।';
  static const allSet = 'মিটারে পাকা হাত! রেটিং, ডায়াল আর সকেট — সব মিলিয়েছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ডায়াল আর সকেট দুটোই মিলিয়ে দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtCat = 'CAT রেটিং দেখে মিটার নিয়েছেন';
  static const caughtFlaw = 'খারাপ লিড/ব্যাটারির মিটার বাতিল';
  static const caughtCatAside = 'CAT II মিটার সরিয়ে রেখেছেন';
  static const caughtAc = 'AC ভোল্টেজ: V~, COM আর VΩmA';
  static const caughtDc = 'DC ভোল্টেজ: ডায়াল DC-তে';
  static const caughtFuse = 'সুইচ বন্ধ করে ফিউজের কন্টিনিউটি';
  static const caughtLeftover = '10A-তে রয়ে যাওয়া লিড ধরেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
}

abstract final class M2MeterMistakes {
  static const _art = 'assets/game/art/m2_meter_setup';
  static const catTwo = DoMistake(
    key: '2.2/meter/cat-ii',
    textBn: 'সাধারণ ইলেকট্রিশিয়ানের CAT II মিটার দিয়ে লাইনে মাপা মারাত্মক বিপজ্জনক — যন্ত্রটি বিস্ফোরিত হতে পারে। লাইনম্যানের চাই CAT III বা CAT IV।',
    art: '$_art/cat_rating.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const tenALive = DoMistake(
    key: '2.2/meter/10a-live',
    textBn: 'লাল লিড 10A সকেটে রেখে লাইভ টার্মিনালে প্রোব — মিটারের ভেতর দিয়ে সোজা শর্ট, ঝলক উঠতে পারে। ভোল্ট মাপতে কালো COM-এ, লাল VΩmA-তে।',
    art: '$_art/sockets.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const tenAOther = DoMistake(
    key: '2.2/meter/10a-wrong-port',
    textBn: '10A সকেট শুধু বড় কারেন্ট মাপার জন্য। ভোল্ট বা কন্টিনিউটিতে লাল লিড VΩmA-তে — ভুল পোর্টে ফিউজ উড়ে মিটার নষ্ট হতে পারে।',
    art: '$_art/sockets.svg',
    lessonPoint: 0,
  );
  static const swapped = DoMistake(
    key: '2.2/meter/leads-swapped',
    textBn: 'লিড উল্টো সকেটে। কালো প্রোব COM-এ, লাল প্রোব VΩmA পোর্টে।',
    art: '$_art/sockets.svg',
    lessonPoint: 0,
  );
  static const liveContinuity = DoMistake(
    key: '2.2/meter/live-continuity',
    textBn: 'চালু সার্কিটে কন্টিনিউটি টেস্ট নয়! আগে সুইচ বন্ধ করে পাওয়ার পুরো বন্ধ, তারপর ফিউজের দুই প্রান্তে প্রোব।',
    art: '$_art/power_off.svg',
    lessonPoint: 2,
  );
  static const acNeedsVac = DoMistake(
    key: '2.2/meter/ac-dial',
    textBn: 'লাইনে AC ভোল্টেজ — ডায়াল V~-এ রাখুন। ভুল সেটিং-এ মিটার ভুল রিডিং দেবে।',
    art: '$_art/dial_mode.svg',
    lessonPoint: 1,
  );
  static const dcNeedsVdc = DoMistake(
    key: '2.2/meter/dc-dial',
    textBn: 'ব্যাটারিতে DC ভোল্টেজ — ডায়াল DC ভোল্টে রাখুন। ভুল সেটিং-এ মিটার ভুল রিডিং দেবে।',
    art: '$_art/dial_mode.svg',
    lessonPoint: 1,
  );
  static const ohmOnLive = DoMistake(
    key: '2.2/meter/ohm-on-live',
    textBn: 'চালু জিনিসে ওহম বা কন্টিনিউটি মোড নয় — এ দুটো শুধু পাওয়ার বন্ধ করে। ভোল্টেজ মাপতে ডায়াল ভোল্টে।',
    art: '$_art/dial_mode.svg',
    lessonPoint: 3,
  );
  static const ampOnLive = DoMistake(
    key: '2.2/meter/amp-dial',
    textBn: 'ডায়াল কারেন্টে (A) রেখে ভোল্টেজে প্রোব দিলে ফিউজ উড়ে মিটার নষ্ট হতে পারে। ভোল্টেজ মাপতে ডায়াল ভোল্টে।',
    art: '$_art/dial_mode.svg',
    lessonPoint: 0,
  );
  static const fuseMode = DoMistake(
    key: '2.2/meter/fuse-mode',
    textBn: 'ভোল্টেজ দেখে ফিউজ ভালো কিনা বোঝা যায় না। পাওয়ার বন্ধ করে ডায়াল কন্টিনিউটি (•))) মোডে — বিপ হলে সংযোগ ঠিক।',
    art: '$_art/dial_mode.svg',
    lessonPoint: 2,
  );
  static const fuseJudge = DoMistake(
    key: '2.2/meter/fuse-judge',
    textBn: 'রিডিং আবার দেখুন — বিপ হলে বা প্রায় শূন্য ওহম হলে সংযোগ ঠিক; বিপ নেই, OL মানে ফিউজের ভেতরটা কাটা।',
    art: '$_art/power_off.svg',
    lessonPoint: 2,
  );
  static const cutLead = DoMistake(
    key: '2.2/meter/cut-lead',
    textBn: 'লিডের তারে কাটা — ভেতরের তামা বেরিয়ে আছে। ব্যবহারের আগে প্রোবের তার দেখে নিন; কাটা লিডের মিটার বাতিল।',
    art: '$_art/lead_check.svg',
    lessonPoint: 0,
  );
  static const rustyTip = DoMistake(
    key: '2.2/meter/rusty-tip',
    textBn: 'প্রোবের ডগায় মরিচা — মরিচা ধরা বা ভোঁতা প্রোব সঠিক রিডিং দেয় না। এমন মিটার বাতিল।',
    art: '$_art/lead_check.svg',
    lessonPoint: 0,
  );
  static const lowBattery = DoMistake(
    key: '2.2/meter/low-battery',
    textBn: 'মিটারের ব্যাটারি কম — ব্যবহারের আগে ব্যাটারি লেভেল দেখে নিন। এমন মিটার বাতিল।',
    art: '$_art/lead_check.svg',
    lessonPoint: 0,
  );
  static const all = [
    catTwo,
    tenALive,
    tenAOther,
    swapped,
    liveContinuity,
    acNeedsVac,
    dcNeedsVdc,
    ohmOnLive,
    ampOnLive,
    fuseMode,
    fuseJudge,
    cutLead,
    rustyTip,
    lowBattery,
  ];
}

/// A fresh play: the case (ratings, flaw, colours, order), the jobs' order,
/// where the leads were left, the fuse, the readings and the coworker vary.
MeterDeal dealMeter(math.Random rng) {
  final colours = [0, 1, 2]..shuffle(rng);
  final flaw = const [MeterFlaw.cutLead, MeterFlaw.rustyTip, MeterFlaw.lowBattery][rng.nextInt(3)];
  final meters = [
    MeterItem(id: 'm0', cat: rng.nextBool() ? MeterCat.cat3 : MeterCat.cat4, body: colours[0]),
    MeterItem(id: 'm1', cat: MeterCat.cat2, body: colours[1]),
    MeterItem(id: 'm2', cat: rng.nextBool() ? MeterCat.cat3 : MeterCat.cat4, flaw: flaw, onRed: rng.nextBool(), body: colours[2]),
  ]..shuffle(rng);
  final jobs = [...MeterJob.values]..shuffle(rng);
  final ac = 224 + rng.nextInt(14);
  final dc = 12.2 + rng.nextInt(7) / 10;
  return MeterDeal(
    meters: meters,
    jobs: jobs,
    leftover: rng.nextInt(3),
    fuseGood: rng.nextBool(),
    push: rng.nextBool() ? MeterPush.socket : MeterPush.anyMeter,
    acVolts: '$ac.${rng.nextInt(10)}',
    dcVolts: dc.toStringAsFixed(2),
  );
}

enum MeterVerdict { right, slip, deadly, nudge }

@immutable
class MeterOutcome {
  const MeterOutcome(this.verdict, {this.mistake, this.nudge});
  final MeterVerdict verdict;
  final DoMistake? mistake;
  final String? nudge;
}

/// The play state (pure logic). Round 0 = the meter; rounds 1–3 = the jobs.
class MeterRun {
  MeterRun(this.deal) {
    _setUpJob();
  }
  final MeterDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;
  MeterItem? meter;

  /// This round is decided: the reason comes, then [next].
  bool shown = false;

  /// Meters set aside, and meters whose flaw the player has seen.
  final Set<String> rejected = {};
  final Set<String> spotted = {};
  final List<String> caught = [];

  // The meter in hand on a job.
  MeterDial dial = MeterDial.off;
  MeterSock? red;
  MeterSock? black;
  var isolatorOn = true;

  /// The display after the probes touched (null: not yet this job).
  String? reading;

  /// The fuse was read; now the player says good or blown.
  var judging = false;

  bool get done => round > deal.jobs.length;
  bool get ended => done || deadly != null;
  MeterJob? get job => round >= 1 && round <= deal.jobs.length ? deal.jobs[round - 1] : null;
  bool get leftHere => round >= 1 && deal.leftover == round - 1;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  void _setUpJob() {
    reading = null;
    judging = false;
    if (leftHere) {
      dial = MeterDial.amp;
      red = MeterSock.a10;
      black = MeterSock.com;
    } else {
      dial = MeterDial.off;
      red = null;
      black = null;
    }
  }

  // ---- round 0: the case ----------------------------------------------------

  MeterOutcome take(MeterItem m) {
    if (ended || shown || job != null || rejected.contains(m.id)) return const MeterOutcome(MeterVerdict.nudge);
    if (m.cat == MeterCat.cat2) return _deadly(M2MeterMistakes.catTwo);
    if (m.flaw != MeterFlaw.none) {
      slips++;
      rejected.add(m.id);
      spotted.add(m.id);
      return MeterOutcome(
        MeterVerdict.slip,
        mistake: switch (m.flaw) {
          MeterFlaw.cutLead => M2MeterMistakes.cutLead,
          MeterFlaw.rustyTip => M2MeterMistakes.rustyTip,
          _ => M2MeterMistakes.lowBattery,
        },
      );
    }
    meter = m;
    _tag(M2MeterLines.caughtCat);
    shown = true;
    return const MeterOutcome(MeterVerdict.right);
  }

  /// The player's hand (or the switched-on display) found [m]'s flaw.
  void spot(MeterItem m) {
    if (m.flaw != MeterFlaw.none) spotted.add(m.id);
  }

  /// Puts [m] back: the CAT II meter (its label is read up close) or a meter
  /// whose flaw was found goes aside (true); anything else back in the case.
  bool putBack(MeterItem m) {
    if (ended || shown || job != null || rejected.contains(m.id)) return false;
    if (m.cat != MeterCat.cat2 && !spotted.contains(m.id)) return false;
    rejected.add(m.id);
    _tag(m.cat == MeterCat.cat2 ? M2MeterLines.caughtCatAside : M2MeterLines.caughtFlaw);
    return true;
  }

  // ---- rounds 1–3: the jobs -------------------------------------------------

  void setDial(MeterDial d) {
    if (job == null || shown || ended) return;
    dial = d;
    reading = null;
  }

  /// Plugs [lead] into [s]; a lead already there comes out.
  void plug(MeterLead lead, MeterSock s) {
    if (job == null || shown || ended) return;
    if (lead == MeterLead.red) {
      if (black == s) black = null;
      red = s;
    } else {
      if (red == s) red = null;
      black = s;
    }
    reading = null;
  }

  void unplug(MeterLead lead) {
    if (job == null || shown || ended) return;
    if (lead == MeterLead.red) {
      red = null;
    } else {
      black = null;
    }
    reading = null;
  }

  void setIsolator(bool on) {
    if (ended) return;
    isolatorOn = on;
    if (job == MeterJob.fuse) reading = null;
  }

  /// The source under the probes is live.
  bool get _live => job != MeterJob.fuse || isolatorOn;

  /// Touch the probes on the job.
  MeterOutcome probe() {
    final j = job;
    if (j == null || ended || shown || judging) return const MeterOutcome(MeterVerdict.nudge);
    if (red == null || black == null) return const MeterOutcome(MeterVerdict.nudge, nudge: M2MeterLines.needLeads);
    if (dial == MeterDial.off) return const MeterOutcome(MeterVerdict.nudge, nudge: M2MeterLines.needOn);
    if (red == MeterSock.a10 || black == MeterSock.a10) {
      if (j == MeterJob.acLt) return _deadly(M2MeterMistakes.tenALive);
      return _slip(M2MeterMistakes.tenAOther);
    }
    if (black != MeterSock.com || red != MeterSock.vohm) return _slip(M2MeterMistakes.swapped);
    switch (j) {
      case MeterJob.acLt:
        switch (dial) {
          case MeterDial.vac:
            reading = deal.acVolts;
            _tag(M2MeterLines.caughtAc);
            if (leftHere) _tag(M2MeterLines.caughtLeftover);
            shown = true;
            return const MeterOutcome(MeterVerdict.right);
          case MeterDial.vdc:
            return _slip(M2MeterMistakes.acNeedsVac);
          case MeterDial.ohm || MeterDial.cont:
            return _slip(M2MeterMistakes.ohmOnLive);
          default:
            return _slip(M2MeterMistakes.ampOnLive);
        }
      case MeterJob.dcBattery:
        switch (dial) {
          case MeterDial.vdc:
            reading = deal.dcVolts;
            _tag(M2MeterLines.caughtDc);
            if (leftHere) _tag(M2MeterLines.caughtLeftover);
            shown = true;
            return const MeterOutcome(MeterVerdict.right);
          case MeterDial.vac:
            return _slip(M2MeterMistakes.dcNeedsVdc);
          case MeterDial.ohm || MeterDial.cont:
            return _slip(M2MeterMistakes.ohmOnLive);
          default:
            return _slip(M2MeterMistakes.ampOnLive);
        }
      case MeterJob.fuse:
        if (_live) return _slip(M2MeterMistakes.liveContinuity);
        if (dial == MeterDial.amp) return _slip(M2MeterMistakes.ampOnLive);
        if (dial != MeterDial.cont && dial != MeterDial.ohm) return _slip(M2MeterMistakes.fuseMode);
        reading = deal.fuseGood ? (dial == MeterDial.cont ? '000' : '0.2') : 'OL';
        judging = true;
        return const MeterOutcome(MeterVerdict.right);
    }
  }

  /// The beep sounds on this reading (continuity mode, fuse good).
  bool get beeps => job == MeterJob.fuse && reading != null && dial == MeterDial.cont && deal.fuseGood;

  /// Good or blown, after the fuse was read.
  MeterOutcome judge(bool good) {
    if (!judging || ended || shown) return const MeterOutcome(MeterVerdict.nudge);
    if (good != deal.fuseGood) return _slip(M2MeterMistakes.fuseJudge, keepReading: true);
    judging = false;
    shown = true;
    _tag(M2MeterLines.caughtFuse);
    if (leftHere) _tag(M2MeterLines.caughtLeftover);
    return const MeterOutcome(MeterVerdict.right);
  }

  /// The next round (after the reason).
  void next() {
    round++;
    shown = false;
    _setUpJob();
  }

  MeterOutcome _slip(DoMistake m, {bool keepReading = false}) {
    slips++;
    if (!keepReading) reading = null;
    return MeterOutcome(MeterVerdict.slip, mistake: m);
  }

  MeterOutcome _deadly(DoMistake m) {
    deadly = m;
    return MeterOutcome(MeterVerdict.deadly, mistake: m);
  }
}

/// May the coworker come now? Only with something to push: the CAT II meter
/// still in the case (round 0), or the terminal job not yet done.
bool meterPushOpen(MeterRun r) => switch (r.deal.push) {
  MeterPush.anyMeter => r.round == 0 && !r.shown && r.deal.meters.any((m) => m.cat == MeterCat.cat2 && !r.rejected.contains(m.id)),
  MeterPush.socket => r.job == MeterJob.acLt && !r.shown,
};

@immutable
class M2MeterPack {
  const M2MeterPack({required this.id, required this.titleBn, this.quickMs = 110000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2MeterPack22a = M2MeterPack(id: 'do_2_2_a', titleBn: M2MeterLines.title);
const m2MeterSetupPacks = {'do_2_2_a': m2MeterPack22a};

// ============================================================================
// Page
// ============================================================================

class M2MeterSetupPage extends StatefulWidget {
  const M2MeterSetupPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M2MeterPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2MeterSetupPage> createState() => _M2MeterSetupPageState();
}

class _M2MeterSetupPageState extends State<M2MeterSetupPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _MeterRunPage(
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

class _MeterRunPage extends ConsumerStatefulWidget {
  const _MeterRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2MeterPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_MeterRunPage> createState() => _MeterRunPageState();
}

class _MeterRunPageState extends ConsumerState<_MeterRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final MeterRun _run = MeterRun(dealMeter(widget.rng));
  late final String _feeder = M2MeterLines.feeders[widget.rng.nextInt(M2MeterLines.feeders.length)];
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The meter in the trainee's hands at the case (the close look).
  MeterItem? _held;

  /// The lead lifted out, waiting for a socket.
  MeterLead? _lifted;
  var _docketOpen = false;
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

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;

  var _freeze = false;
  var _flashTenA = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice ------------------------------------------------------------------

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

  void _cue(String file, {double volume = 0.55}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  String get _task {
    final j = _run.job;
    if (j == null) return _held != null ? M2MeterLines.inspectAsk : M2MeterLines.askMeter;
    return _run.judging ? M2MeterLines.judgeAsk : M2MeterLines.askJob(j);
  }

  // ---- flow ---------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([_task]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || _run.shown || _freeze;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// Any hands-on move while he is still talking (not the one he pushes)
  /// refuses him.
  void _refuseByWork(Offset at) {
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, at, direct: true));
  }

  // Round 0: the case.

  void _pick(MeterItem m, Offset at) {
    if (coworkerOpen && !coworkerChoiceUp && m.cat != MeterCat.cat2) _refuseByWork(at);
    if (_blocked || coworkerOpen || _held != null || _docketOpen || _run.rejected.contains(m.id)) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.4);
    _hush();
    setState(() {
      _held = m;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([M2MeterLines.inspectAsk]));
  }

  void _found() {
    final m = _held;
    if (m != null) _run.spot(m);
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tock.wav', volume: 0.6);
  }

  void _putBack() {
    final m = _held;
    if (m == null || _blocked) return;
    final aside = _run.putBack(m);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.6);
      unawaited(_sayChain([m.cat == MeterCat.cat2 ? M2MeterLines.asideCat : M2MeterLines.asideFlaw, M2MeterLines.askMeter], mood: GuideMood.glad));
    } else {
      _cue('sounds/intro/drop.ogg', volume: 0.4);
      unawaited(_sayChain([M2MeterLines.askMeter]));
    }
  }

  void _take(Offset at) {
    final m = _held;
    if (m == null || _blocked) return;
    setState(() => _held = null);
    final o = _run.take(m);
    switch (o.verdict) {
      case MeterVerdict.right:
        HapticFeedback.lightImpact();
        _cue('sounds/quiz_right.wav', volume: 0.6);
        setState(() => _setMode(LinemanMode.cheer));
        _ask(15, () => dealChoices(M2MeterLines.meterRight(m.cat), M2MeterLines.meterMyths, widget.rng), M2MeterLines.meterAsk);
      case MeterVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        unawaited(_slip(o.mistake!, at));
      case MeterVerdict.deadly:
        unawaited(_deadly(o.mistake!));
      case MeterVerdict.nudge:
        break;
    }
  }

  // Rounds 1–3: the meter in hand.

  bool get _jobLive => !_blocked && !coworkerOpen && _run.job != null && !_run.judging && !_docketOpen;

  void _turnDial(MeterDial d, Offset at) {
    _refuseByWork(at);
    if (!_jobLive || _run.dial == d) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    setState(() => _run.setDial(d));
  }

  void _liftLead(MeterLead lead, Offset at) {
    _refuseByWork(at);
    if (!_jobLive) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() {
      if ((lead == MeterLead.red ? _run.red : _run.black) != null) _run.unplug(lead);
      _lifted = _lifted == lead ? null : lead;
    });
  }

  void _tapSocket(MeterSock s, Offset at) {
    final lifted = _lifted;
    // Plugging into 10A while he talks is what he pushes — not a refusal.
    if (!(lifted == MeterLead.red && s == MeterSock.a10)) _refuseByWork(at);
    if (!_jobLive) return;
    if (lifted == null) {
      // Tap a plugged socket: pull its lead out into the hand.
      final there = _run.red == s ? MeterLead.red : (_run.black == s ? MeterLead.black : null);
      if (there == null) return;
      HapticFeedback.selectionClick();
      _cue('sounds/intro/click.ogg', volume: 0.4);
      setState(() {
        _run.unplug(there);
        _lifted = there;
      });
      return;
    }
    _dropLead(lifted, s);
  }

  void _dropLead(MeterLead lead, MeterSock s) {
    if (!_jobLive) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.35);
    setState(() {
      _run.plug(lead, s);
      _lifted = null;
    });
  }

  void _toggleIsolator(Offset at) {
    _refuseByWork(at);
    if (!_jobLive) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    final on = !_run.isolatorOn;
    setState(() => _run.setIsolator(on));
    if (!on) unawaited(_sayChain([M2MeterLines.switchedOff, _task]));
  }

  void _probe(Offset at) {
    _refuseByWork(at);
    if (!_jobLive) return;
    _hush();
    final o = _run.probe();
    switch (o.verdict) {
      case MeterVerdict.nudge:
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        final n = o.nudge;
        if (n != null) unawaited(_sayChain([n]));
        setState(() {});
      case MeterVerdict.right:
        HapticFeedback.lightImpact();
        setState(() {
          _lifted = null;
          _setMode(LinemanMode.cheer);
        });
        if (_run.beeps) _cue('sounds/learn/dmm_beep.wav', volume: 0.7);
        if (_run.judging) {
          unawaited(_sayChain([M2MeterLines.judgeAsk]));
          return;
        }
        _cue('sounds/quiz_right.wav', volume: 0.6);
        final j = _run.job!;
        _ask(
          15,
          () => j == MeterJob.acLt
              ? dealChoices(M2MeterLines.acRight, M2MeterLines.acWrong, widget.rng)
              : dealChoices(M2MeterLines.dcRight, M2MeterLines.dcWrong, widget.rng),
          M2MeterLines.jobAsk,
        );
      case MeterVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        unawaited(_slip(o.mistake!, at));
      case MeterVerdict.deadly:
        unawaited(_deadly(o.mistake!));
    }
  }

  void _judge(bool good, Offset at) {
    if (_blocked || coworkerOpen || !_run.judging) return;
    _hush();
    final o = _run.judge(good);
    if (o.verdict == MeterVerdict.right) {
      HapticFeedback.lightImpact();
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() => _setMode(LinemanMode.cheer));
      final g = _run.deal.fuseGood;
      _ask(20, () => dealChoices(M2MeterLines.fuseRight(g), M2MeterLines.fuseWrong(g), widget.rng), M2MeterLines.fuseAsk);
      return;
    }
    if (o.verdict == MeterVerdict.slip) {
      setState(() => _setMode(LinemanMode.worried));
      unawaited(_slip(o.mistake!, at));
    }
  }

  void _ask(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _lifted = null;
      _setMode(LinemanMode.idle);
    });
    _cue('sounds/quiz_flip.wav', volume: 0.5);
    _armCoworker();
    unawaited(_sayChain([_task]));
  }

  void _openDocket() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_flip.wav', volume: 0.4);
    setState(() => _docketOpen = true);
  }

  // --- ReasonTable ----------------------------------------------------------------
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
  void onReasonPaid() => _nextRound();

  // --- CoworkerMoment -------------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => M2MeterLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round > _run.deal.callRound) return null;
    if (_run.round < _run.deal.callRound) return false;
    if (_blocked || _held != null || _docketOpen || _lifted != null) return false;
    if (!meterPushOpen(_run)) return _run.round == _run.deal.callRound && !_run.shown ? false : null;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Took what he pushed: the CAT II meter, or the red lead into 10A on the live terminals.
      final m = _run.deal.push == MeterPush.anyMeter ? M2MeterMistakes.catTwo : M2MeterMistakes.tenALive;
      if (m == M2MeterMistakes.tenALive) {
        _run.red = MeterSock.a10;
      }
      _run.deadly = m;
      await _deadly(m);
      return;
    }
    _run.caught.add(M2MeterLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([M2MeterLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
        ? M2MeterLines.tapWhy[_nudgeN++ % M2MeterLines.tapWhy.length]
        : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // ---- mistakes -------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav', volume: 0.7);
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('meter/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _held = null;
      _docketOpen = false;
      _lifted = null;
      _flashTenA = m == M2MeterMistakes.tenALive;
      _setMode(LinemanMode.worried);
      _freeze = true;
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
    final speak = await SpokenOnce.first('meter/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M2MeterLines.deadlyWord : M2MeterLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(LinemanMode.idle);
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

  // ---- score and result -------------------------------------------------------------

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
      !_run.passed ? M2MeterLines.fail : (_quickBonus ? M2MeterLines.quick : M2MeterLines.allSet),
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

  // ---- build --------------------------------------------------------------------------

  Rect? _targetRect(MeterSceneGeo geo) => switch (_run.job) {
    MeterJob.acLt => geo.terminals.inflate(4),
    MeterJob.fuse => geo.fuse.inflate(4),
    MeterJob.dcBattery => geo.battery.inflate(4),
    null => null,
  };

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = MeterSceneGeo(m.height);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final atCase = _run.job == null;
    final meters = _run.deal.meters;
    final aside = [
      for (final x in meters)
        if (_run.rejected.contains(x.id)) x,
    ];
    final canPick = atCase && !_blocked && _held == null && !_docketOpen;
    final target = _targetRect(geo);
    Widget g(Widget child) => ColorFiltered(colorFilter: grey, child: child);
    return [
      Positioned.fill(
        key: const ValueKey('scene'),
        child: g(RepaintBoundary(child: CustomPaint(painter: MeterScenePainter(geo)))),
      ),
      Positioned.fromRect(
        key: const ValueKey('isolator'),
        rect: geo.isolator,
        child: g(_IsolatorSwitch(on: _run.isolatorOn, onTapUp: (d) => _toggleIsolator(d.globalPosition))),
      ),
      Positioned(
        key: const ValueKey('battery-tag'),
        left: geo.battery.left + 22,
        top: geo.battery.top + 30,
        child: g(
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: const Color(0xFFF2C230),
              child: const Text(
                M2MeterLines.batteryTag,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E2228), height: 1.1),
              ),
            ),
          ),
        ),
      ),
      if (target != null && !_run.shown) Positioned.fromRect(key: ValueKey('target-${_run.round}'), rect: target, child: g(const MeterTargetRing())),
      if (target != null && _run.reading != null)
        Positioned.fromRect(key: ValueKey('tips-${_run.round}'), rect: target.deflate(6), child: g(const ProbeTips())),
      Positioned.fromRect(
        key: const ValueKey('docket'),
        rect: geo.docket,
        child: g(_DocketSheet(jobs: _run.deal.jobs, done: _run.round - 1, quiet: quiet, onTap: _openDocket)),
      ),
      if (atCase)
        for (var i = 0; i < meters.length; i++)
          Positioned.fromRect(
            key: ValueKey('slot-$i'),
            rect: geo.slot(i, meters.length),
            child: g(
              DoDealIn(
                index: i,
                quiet: quiet,
                muted: true,
                child: _CaseMeter(
                  meter: meters[i],
                  gone: _run.rejected.contains(meters[i].id) || _held?.id == meters[i].id || _run.meter?.id == meters[i].id,
                  enabled: canPick,
                  onTake: (at) => _pick(meters[i], at),
                ),
              ),
            ),
          ),
      for (var i = 0; i < aside.length && i < 2; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: g(_AsideMeter(meter: aside[i], quiet: quiet)),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: g(LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final held = _held;
    final job = _run.job;
    final panelUp = playing && job != null && _run.meter != null && !deckUp;
    final panelW = math.min(size.width - 16, 380.0);
    const panelH = 300.0;
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
              labels: [M2MeterLines.meterLabel, for (final j in _run.deal.jobs) j.dot],
              done: {for (var i = 0; i < math.min(_run.round, 4); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (panelUp)
                Positioned(
                  key: const ValueKey('panel'),
                  left: (size.width - panelW) / 2,
                  width: panelW,
                  bottom: pad.bottom + 8,
                  height: panelH,
                  child: _MeterPanel(
                    meter: _run.meter!,
                    run: _run,
                    lifted: _lifted,
                    docketLine: job.docketBn,
                    quiet: quiet,
                    onDial: _turnDial,
                    onLead: _liftLead,
                    onSocket: _tapSocket,
                    onDropLead: _dropLead,
                    onProbe: _probe,
                    onJudge: _judge,
                  ),
                ),
              if (held != null && playing)
                _Inspect(key: ValueKey('inspect-${held.id}'), meter: held, quiet: quiet, onFound: _found, onTake: _take, onPutBack: _putBack),
              if (_docketOpen && playing)
                _DocketZoom(
                  key: const ValueKey('docket-zoom'),
                  feeder: _feeder,
                  jobs: _run.deal.jobs,
                  quiet: quiet,
                  onClose: () => setState(() => _docketOpen = false),
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
              if (playing && _card == null && !_docketOpen && held == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : (panelUp ? panelH + 14 : 8)),
                  onLeft: coworkerFromRight || (panelUp && !coworkerOnScreen),
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: _cardTone,
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: quiet ? 300 : 2200,
                  consequence: MeterFlash(tenA: _flashTenA, quiet: quiet),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M2MeterLines.intro,
                  alarm: 'sounds/van_arrive.wav',
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _brown = Color(0xFF8C6A2A);
const _bench = Color(0xFF26303B);
const _red = Color(0xFFC0392B);
const _black = Color(0xFF15171A);

const _bodies = [Color(0xFFF2B705), Color(0xFFE8792B), Color(0xFF8FA3B5)];
const _bodyEdge = [Color(0xFF8A6500), Color(0xFF8C3F10), Color(0xFF4A5966)];

/// The isolator on the board: a handle up at ON, down at OFF (tap to throw).
class _IsolatorSwitch extends StatelessWidget {
  const _IsolatorSwitch({required this.on, required this.onTapUp});
  final bool on;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M2MeterLines.isolatorLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD7DADD),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF5A6066), width: 1.4),
          ),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: 22,
                  decoration: BoxDecoration(color: const Color(0xFF2B2F35), borderRadius: BorderRadius.circular(4)),
                  alignment: on ? Alignment.topCenter : Alignment.bottomCenter,
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(color: on ? const Color(0xFFC0392B) : const Color(0xFF2E8B45), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                on ? M2MeterLines.on : M2MeterLines.off,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: on ? const Color(0xFFB0281C) : const Color(0xFF1F6E35), height: 1.1),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// The docket clipped on the wall: three jobs, those done struck off.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.jobs, required this.done, required this.quiet, required this.onTap});
  final List<MeterJob> jobs;
  final int done;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 12, 4, 4),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    M2MeterLines.docket,
                    style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1),
                  ),
                  Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
                  for (var i = 0; i < jobs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${i + 1}. ${jobs[i].dot}',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: bangla(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: i < done ? const Color(0xFF8A8F96) : _ink,
                          height: 1.2,
                        ).copyWith(decoration: i < done ? TextDecoration.lineThrough : null),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 28,
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFD9DEE2), Color(0xFF8D969E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocketZoom extends StatelessWidget {
  const _DocketZoom({super.key, required this.feeder, required this.jobs, required this.quiet, required this.onClose});
  final String feeder;
  final List<MeterJob> jobs;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(
                scale: 0.6 + 0.4 * t,
                child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
              ),
              child: Container(
                width: 300,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: _brown, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          M2MeterLines.docket,
                          style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text(
                      '${M2MeterLines.docketHead} · $feeder',
                      style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478)),
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < jobs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${i + 1}. ${jobs[i].docketBn}',
                          style: bangla(fontSize: 15.5, fontWeight: FontWeight.w800, color: _ink, height: 1.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A meter lying in the case: from a step away its label is a blank strip.
class _CaseMeter extends StatelessWidget {
  const _CaseMeter({required this.meter, required this.gone, required this.enabled, required this.onTake});
  final MeterItem meter;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  Widget build(BuildContext context) {
    if (gone) return Semantics(label: M2MeterLines.meterLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: M2MeterLines.meterLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTake(d.globalPosition) : null,
        child: _MiniMeter(body: meter.body),
      ),
    );
  }
}

class _MiniMeter extends StatelessWidget {
  const _MiniMeter({required this.body});
  final int body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth, box.maxHeight * 0.62);
        return Center(
          child: Container(
            width: w,
            height: w * 1.55,
            padding: EdgeInsets.all(w * 0.1),
            decoration: BoxDecoration(
              color: _bodies[body],
              borderRadius: BorderRadius.circular(w * 0.16),
              border: Border.all(color: _bodyEdge[body], width: 1.4),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                Container(
                  height: w * 0.32,
                  decoration: BoxDecoration(color: const Color(0xFF9FB39A), borderRadius: BorderRadius.circular(2)),
                ),
                SizedBox(height: w * 0.06),
                Container(height: w * 0.08, color: const Color(0xEEFFFFFF)),
                const Spacer(),
                Container(
                  width: w * 0.42,
                  height: w * 0.42,
                  decoration: const BoxDecoration(color: Color(0xFF2B2F35), shape: BoxShape.circle),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: w * 0.13,
                        height: w * 0.13,
                        decoration: const BoxDecoration(color: _black, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AsideMeter extends StatelessWidget {
  const _AsideMeter({required this.meter, required this.quiet});
  final MeterItem meter;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(
        offset: Offset(40 * (1 - t), 0),
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Transform.rotate(
        angle: -0.2,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(child: _MiniMeter(body: meter.body)),
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
                child: Text(
                  M2MeterLines.rejected,
                  style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dial's positions round the knob (degrees from straight up, clockwise).
const _dialAngle = {MeterDial.off: -135.0, MeterDial.vac: -81.0, MeterDial.vdc: -27.0, MeterDial.ohm: 27.0, MeterDial.cont: 81.0, MeterDial.amp: 135.0};

/// A dial position's printed mark.
Widget _dialMark(MeterDial d, double size, Color c) {
  final s = TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: c, height: 1);
  return switch (d) {
    MeterDial.off => Text('OFF', style: s.copyWith(fontSize: size * 0.72)),
    MeterDial.vac => Text('V~', style: s),
    MeterDial.vdc => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('V', style: s),
        const SizedBox(width: 1),
        DcMark(color: c, width: size * 0.8),
      ],
    ),
    MeterDial.ohm => Text('Ω', style: s),
    MeterDial.cont => Text('•)))', style: s.copyWith(fontSize: size * 0.8)),
    MeterDial.amp => Text('A', style: s),
  };
}

/// The meter's face, drawn at width [w]: the display, the CAT strip, the dial
/// and the three sockets. Interactive parts call back when given.
class _MeterFace extends StatelessWidget {
  const _MeterFace({
    required this.meter,
    required this.w,
    required this.dial,
    required this.display,
    this.red,
    this.black,
    this.lifted,
    this.onDial,
    this.onSocket,
    this.onDropLead,
    this.onKnob,
    this.lowBattery = false,
    this.beep = false,
  });
  final MeterItem meter;
  final double w;
  final MeterDial dial;
  final String? display;
  final MeterSock? red;
  final MeterSock? black;
  final MeterLead? lifted;
  final void Function(MeterDial, Offset)? onDial;
  final void Function(MeterSock, Offset)? onSocket;
  final void Function(MeterLead, MeterSock)? onDropLead;
  final VoidCallback? onKnob;
  final bool lowBattery;
  final bool beep;

  @override
  Widget build(BuildContext context) {
    final dialBox = w * 0.86;
    final r = dialBox * 0.34;
    final knob = dialBox * 0.2;
    final hit = math.max(40.0, dialBox * 0.25);
    final on = dial != MeterDial.off;
    Widget lcd() {
      final ann = switch (dial) {
        MeterDial.vac => 'AC',
        MeterDial.vdc => 'DC',
        _ => '',
      };
      final unit = switch (dial) {
        MeterDial.vac || MeterDial.vdc => 'V',
        MeterDial.ohm || MeterDial.cont => 'Ω',
        MeterDial.amp => 'A',
        MeterDial.off => '',
      };
      return Container(
        height: w * 0.27,
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFC9DCC0) : const Color(0xFF8E9C89),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF3B4A36), width: 1.4),
        ),
        child: !on
            ? null
            : Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ann,
                        style: TextStyle(fontSize: w * 0.06, fontWeight: FontWeight.w900, color: _ink),
                      ),
                      if (lowBattery) Icon(Icons.battery_alert_rounded, size: w * 0.09, color: _ink),
                      if (beep)
                        Text(
                          '•)))',
                          style: TextStyle(fontSize: w * 0.055, fontWeight: FontWeight.w900, color: _ink),
                        ),
                    ],
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        display ?? (dial == MeterDial.ohm || dial == MeterDial.cont ? 'OL' : '0.00'),
                        style: TextStyle(fontSize: w * 0.15, fontWeight: FontWeight.w800, color: _ink, fontFamily: 'monospace', height: 1),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  Text(
                    unit,
                    style: TextStyle(fontSize: w * 0.07, fontWeight: FontWeight.w900, color: _ink),
                  ),
                ],
              ),
      );
    }

    Widget socket(MeterSock s) {
      final who = red == s ? MeterLead.red : (black == s ? MeterLead.black : null);
      final ring = s == MeterSock.com ? const Color(0xFF5A6066) : _red;
      final d = w * 0.18;
      final body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              color: _black,
              shape: BoxShape.circle,
              border: Border.all(color: lifted != null && who == null ? const Color(0xFF1E88E5) : ring, width: lifted != null && who == null ? 3.4 : 2.4),
            ),
            alignment: Alignment.center,
            child: who == null
                ? Container(
                    width: d * 0.3,
                    height: d * 0.3,
                    decoration: const BoxDecoration(color: Color(0xFF55595E), shape: BoxShape.circle),
                  )
                : Container(
                    width: d * 0.78,
                    height: d * 0.78,
                    decoration: BoxDecoration(
                      color: who == MeterLead.red ? _red : const Color(0xFF2B2F35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                    ),
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            style: TextStyle(fontSize: w * 0.065, fontWeight: FontWeight.w900, color: _ink, height: 1.1),
          ),
        ],
      );
      final tap = onSocket;
      final drop = onDropLead;
      if (tap == null) return body;
      return Semantics(
        button: true,
        label: s.label,
        child: DragTarget<MeterLead>(
          onAcceptWithDetails: (det) => drop?.call(det.data, s),
          builder: (context, _, _) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (det) => tap(s, det.globalPosition),
            child: SizedBox(
              width: math.max(48.0, w * 0.28),
              height: math.max(48.0, d + w * 0.1),
              child: Center(child: body),
            ),
          ),
        ),
      );
    }

    final face = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        lcd(),
        SizedBox(height: w * 0.025),
        Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 1),
          color: Colors.white,
          child: Text(
            meter.cat.label,
            style: TextStyle(fontSize: w * 0.07, fontWeight: FontWeight.w900, color: _ink, height: 1.15),
          ),
        ),
        SizedBox(
          width: dialBox,
          height: dialBox * 0.86,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The knob, its pointer at the chosen function.
              Positioned(
                left: dialBox / 2 - knob,
                top: dialBox * 0.43 - knob,
                width: knob * 2,
                height: knob * 2,
                child: Semantics(
                  button: onKnob != null,
                  label: M2MeterLines.knobLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onKnob,
                    child: Transform.rotate(
                      angle: _dialAngle[dial]! * math.pi / 180,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Color(0xFF4A5056), Color(0xFF1E2226)]),
                          boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: knob * 0.22,
                          height: knob * 0.9,
                          margin: EdgeInsets.only(top: knob * 0.08),
                          decoration: BoxDecoration(color: const Color(0xFFE6E8EA), borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (final d in MeterDial.values)
                Positioned(
                  left: dialBox / 2 + r * math.sin(_dialAngle[d]! * math.pi / 180) - hit / 2,
                  top: dialBox * 0.43 - r * math.cos(_dialAngle[d]! * math.pi / 180) - hit / 2,
                  width: hit,
                  height: hit,
                  child: onDial == null
                      ? Center(child: _dialMark(d, w * 0.075, dial == d ? _red : _ink))
                      : Semantics(
                          button: true,
                          label: 'dial-${d.name}',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (det) => onDial!(d, det.globalPosition),
                            child: Center(child: _dialMark(d, w * 0.085, dial == d ? _red : _ink)),
                          ),
                        ),
                ),
            ],
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final s in MeterSock.values) socket(s)]),
      ],
    );
    return Container(
      width: w,
      padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.06, w * 0.06, w * 0.03),
      decoration: BoxDecoration(
        color: _bodies[meter.body],
        borderRadius: BorderRadius.circular(w * 0.1),
        border: Border.all(color: _bodyEdge[meter.body], width: 2),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: face,
    );
  }
}

/// A lead's plug out of its socket, in the hand (tap, then tap a socket; or drag).
class _LeadPlug extends StatelessWidget {
  const _LeadPlug({super.key, required this.lead, required this.up, required this.onTapUp});
  final MeterLead lead;
  final bool up;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final col = lead == MeterLead.red ? _red : const Color(0xFF2B2F35);
    final label = lead == MeterLead.red ? M2MeterLines.redLead : M2MeterLines.blackLead;
    Widget chip({bool lifted = false}) => Container(
      width: 64,
      height: 50,
      decoration: BoxDecoration(
        color: lifted ? const Color(0xFFFFE6B0) : const Color(0xFFF1ECE0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lifted ? const Color(0xFFFFB020) : const Color(0xFFB9AF9A), width: lifted ? 2.6 : 1.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 6, height: 14, color: const Color(0xFFC9CED3)),
          Container(
            width: 18,
            height: 22,
            decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(4)),
          ),
          Container(width: 22, height: 7, color: col),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: label,
      child: Draggable<MeterLead>(
        data: lead,
        feedback: Material(color: Colors.transparent, child: chip(lifted: true)),
        childWhenDragging: Opacity(opacity: 0.3, child: chip()),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTapUp,
          child: chip(lifted: up),
        ),
      ),
    );
  }
}

/// The meter in hand on a job: the docket line, the meter (dial and
/// sockets live), the leads not yet plugged, and the probe button (or, after
/// the fuse is read, good / blown).
class _MeterPanel extends StatelessWidget {
  const _MeterPanel({
    required this.meter,
    required this.run,
    required this.lifted,
    required this.docketLine,
    required this.quiet,
    required this.onDial,
    required this.onLead,
    required this.onSocket,
    required this.onDropLead,
    required this.onProbe,
    required this.onJudge,
  });
  final MeterItem meter;
  final MeterRun run;
  final MeterLead? lifted;
  final String docketLine;
  final bool quiet;
  final void Function(MeterDial, Offset) onDial;
  final void Function(MeterLead, Offset) onLead;
  final void Function(MeterSock, Offset) onSocket;
  final void Function(MeterLead, MeterSock) onDropLead;
  final void Function(Offset) onProbe;
  final void Function(bool, Offset) onJudge;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final meterW = math.min(box.maxWidth * 0.56, 196.0);
        final loose = [if (run.red == null) MeterLead.red, if (run.black == null) MeterLead.black];
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xF2131C2B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Color(0xFFE6C98A), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${M2MeterLines.docket} · $docketLine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: meterW,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: _MeterFace(
                          meter: meter,
                          w: meterW,
                          dial: run.dial,
                          display: run.reading,
                          red: run.red,
                          black: run.black,
                          lifted: lifted,
                          beep: run.beeps,
                          onDial: onDial,
                          onSocket: onSocket,
                          onDropLead: onDropLead,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final l in loose)
                                _LeadPlug(key: ValueKey('plug-${l.name}'), lead: l, up: lifted == l, onTapUp: (d) => onLead(l, d.globalPosition)),
                            ],
                          ),
                          const Spacer(),
                          if (run.judging) ...[
                            DoBigButton(label: M2MeterLines.fuseOk, filled: true, onTapUp: (d) => onJudge(true, d.globalPosition)),
                            const SizedBox(height: 8),
                            DoBigButton(label: M2MeterLines.fuseBlown, filled: false, onDark: true, onTapUp: (d) => onJudge(false, d.globalPosition)),
                          ] else
                            DoBigButton(label: M2MeterLines.probe, filled: true, onTapUp: (d) => onProbe(d.globalPosition)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The close look at the case: the meter held up, its CAT label readable;
/// turn the knob to switch it on (a low battery shows); run a finger along
/// both leads to the probe tips (a cut or rust shows only where the hand has
/// been). Then take it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({super.key, required this.meter, required this.quiet, required this.onFound, required this.onTake, required this.onPutBack});
  final MeterItem meter;
  final bool quiet;
  final VoidCallback onFound;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _red = {};
  final Set<int> _black = {};
  Offset? _hand;
  var _on = false;
  var _found = false;

  bool? get _cutOn => widget.meter.flaw == MeterFlaw.cutLead ? widget.meter.onRed : null;
  bool? get _rustOn => widget.meter.flaw == MeterFlaw.rustyTip ? widget.meter.onRed : null;

  void _check() {
    if (_found) return;
    final m = widget.meter;
    final seen = LeadsPainter.flawSeen(cutOn: _cutOn, rustOn: _rustOn, red: _red, black: _black) || (_on && m.flaw == MeterFlaw.lowBattery);
    if (seen) {
      _found = true;
      widget.onFound();
    }
  }

  void _touch(Offset p, Size s) {
    final red = p.dy < s.height * 0.51;
    final b = leadBin(LeadsPainter.uOf(s, p.dx));
    final set = red ? _red : _black;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kLeadBins) set.add(x);
    }
    _check();
    setState(() => _hand = p);
  }

  void _knob() {
    HapticFeedback.selectionClick();
    setState(() => _on = !_on);
    _check();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meter;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.translate(
              offset: Offset(0, 80 * (1 - t)),
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MeterFace(
                    meter: m,
                    w: 168,
                    dial: _on ? MeterDial.vac : MeterDial.off,
                    display: null,
                    lowBattery: _on && m.flaw == MeterFlaw.lowBattery,
                    onKnob: _knob,
                  ),
                  const SizedBox(height: 10),
                  AspectRatio(
                    aspectRatio: 3.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4654), _bench]),
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final s = Size(box.maxWidth, box.maxHeight);
                          return Semantics(
                            label: M2MeterLines.handLabel,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanDown: (d) => _touch(d.localPosition, s),
                              onPanUpdate: (d) => _touch(d.localPosition, s),
                              onPanEnd: (_) => setState(() => _hand = null),
                              onPanCancel: () => setState(() => _hand = null),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: LeadsPainter(cutOn: _cutOn, rustOn: _rustOn, seenRed: _red, seenBlack: _black, veil: _bench),
                                    ),
                                  ),
                                  if (_red.isEmpty) _Puck(at: LeadsPainter.at(s, true, 0.12)),
                                  if (_black.isEmpty) _Puck(at: LeadsPainter.at(s, false, 0.12)),
                                  if (_hand != null) _Puck(at: _hand!, live: true),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DoBigButton(label: M2MeterLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DoBigButton(label: M2MeterLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition)),
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

class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 20.0 : 15.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}
