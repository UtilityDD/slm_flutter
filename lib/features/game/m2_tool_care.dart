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
import 'm2_tool_care_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_tool_care_world.dart' show CareKind, CareFlaw, CareZones, careLocalPoint, careToolPoint;

// Lesson 2.10, কাজ: "দিনের শেষে". End of the shift at the store's tool bench:
// the day's tools come onto the bench one by one (insulated pliers, spanner,
// and two of insulated screwdriver / multimeter / hydraulic crimper). The
// lesson's 5-minute routine, hands on: wipe each tool with a dry cloth (the
// grime and water come off under the finger — and a fault hidden under the
// dirt shows: a cracked insulated grip, a bent screwdriver tip, a widened
// spanner jaw, a hydraulic oil leak), scrub rust off with the steel brush and
// THEN a thin coat of oil (on the metal, never on the insulation, never too
// much), switch the meter OFF and coil its leads loosely, then put the tool
// in its own place on the pegboard — or hang the "ব্যবহারের অযোগ্য" tag on a
// damaged one and drop it in the বাতিল crate. Built on the shared level kit
// (GAME_LEVEL_PLAYBOOK.md): guide first, full scene, corner guide, ◆ on the
// table → "কেন …?" → the next tool by itself; the careless coworker once a
// play ("ভ্যানে ছুঁড়ে রেখে দাও, কাল দেখা যাবে!", the lesson's grease myth,
// or "একটু ফাটা তো!" on a cracked grip).
//
// Deadly (FLAGGED for the owner): putting a tool with a cracked insulated grip
// back as fit for use (lesson: "একটি ক্ষতিগ্রস্ত বা দুর্বল টুল ব্যবহার করা
// নিজের এবং সহকর্মীদের জীবন নিয়ে খেলা করার সমান"). Everything else is a slip.
//
// Kit (audit 2026-11-11): no scene control works in a praise window
// (`tableBusy`); "তার ঘরে রাখুন" and the tag wait for the coworker
// (`holdForCoworker`), so a fast play cannot skip him; he says "একটু ফাটা তো"
// only once the crack has come into view (before that he pushes the toss), and
// only a real piece of work while he talks refuses him (picking up a bench
// item or a tap on nothing does not). The bench items lie in a dealt order
// (never cloth → brush → oil), and the wipe's "clean enough to look" cue plays
// on every tool, so no sound tells a damaged tool from a sound one. Gesture
// hints: a sweep over the tool, the bench items and "তার ঘরে রাখুন"; a short
// rub nudge on the tool with the cloth or brush in hand.
//
// Voice: the guide's lines on device TTS; the coworker's new lines too (listed
// in CareLines for recording; his exit line is already recorded). Art: all
// drawn in code (m2_tool_care_world.dart); the mistake cards use
// assets/game/art/m2_tool_care/.

// ============================================================================
// Content
// ============================================================================

/// The care a sound tool needs besides the wipe.
enum CareNeed { plain, wet, rusty, meter }

@immutable
class CareTool {
  const CareTool({required this.id, required this.kind, this.flaw = CareFlaw.none, this.need = CareNeed.plain});
  final String id;
  final CareKind kind;
  final CareFlaw flaw;
  final CareNeed need;
  bool get flawed => flaw != CareFlaw.none;
}

@immutable
class CareDeal {
  const CareDeal({required this.tools, required this.callRound, this.kitOrder = const [3, 2, 0, 1]});
  final List<CareTool> tools;

  /// The tool on which the careless coworker peeps in.
  final int callRound;

  /// How the bench items (0 cloth · 1 brush · 2 oil · 3 tag) lie in the tray
  /// this play: dealt, never in the routine's order (cloth → brush → oil).
  final List<int> kitOrder;
}

/// The routine's order would show in the tray (cloth before brush before oil).
bool careKitInRoutineOrder(List<int> order) => order.indexOf(0) < order.indexOf(1) && order.indexOf(1) < order.indexOf(2);

/// What the careless coworker pushes.
enum CarePush { toss, grease, crack }

/// How far the cloth / brush must go (0..1) for the job to be done.
const double kCareClean = 0.6;
const double kCareDry = 0.9;
const double kCareRustOff = 0.75;

/// The cloth has gone far enough that a fault under the grime shows.
const double kCareFlawShows = 0.45;

/// More oil drops than this is the grease myth.
const int kCareMaxOil = 3;

abstract final class CareLines {
  static const title = 'দিনের শেষে';
  static const intro = 'দিনের শেষ! কাল সকালের আগে প্রতিটা টুলের যত্ন নিন — ভাঙা টুল বাতিল।';
  static const ask = 'এই টুলটার কী করবেন?';
  static const tasks = [ask];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads / controls.
  static const toolLabel = 'বেঞ্চের টুল';
  static const kit = ['কাপড়', 'ব্রাশ', 'তেল', 'ট্যাগ'];
  static const store = 'তার ঘরে রাখুন';
  static const tagText = 'ব্যবহারের অযোগ্য';
  static const crate = 'বাতিল';
  static String name(CareKind k) => switch (k) {
        CareKind.pliers => 'প্লায়ার্স',
        CareKind.screwdriver => 'স্ক্রুড্রাইভার',
        CareKind.spanner => 'স্প্যানার',
        CareKind.meter => 'মাল্টিমিটার',
        CareKind.crimper => 'ক্রিম্পার',
      };

  // The reasons (lesson 2.10): every card 38–46 letters.
  static const storeAsk = 'কেন এভাবে রাখলেন?';
  static const retireAsk = 'কেন বাতিল করলেন?';
  static List<String> storeRight(CareNeed n) => switch (n) {
        CareNeed.plain => const ['শুকনো কাপড়ে মুছে, দেখে, তবেই তার ঘরে রাখলাম', 'ময়লা মুছে ফাটল খুঁজেছি, তারপর নিজের ঘরে'],
        CareNeed.wet => const ['ভেজা টুল বাক্সে রাখলে মরিচা ধরে, তাই শুকিয়েছি', 'জল মুছে শুকনো করে তবেই টুলটা ঘরে রাখলাম'],
        CareNeed.rusty => const ['মরিচা ব্রাশে ঘষে তুলে, তারপর পাতলা তেল দিলাম', 'মরিচা ধাতু দুর্বল করে, তাই ঘষে তুলে তেল দিলাম'],
        CareNeed.meter => const ['বন্ধ করে রাখলাম, আর লিড আলতো করে গুটিয়েছি', 'লিড পেঁচালে নষ্ট হয়, তাই আলতো গুটিয়ে রাখলাম'],
      };
  static const storeMyths = [
    'ভালো কোম্পানির টুল, যত্ন ছাড়াই সারাজীবন চলে',
    'বেশি তেল-গ্রিজ মাখালে মরিচা আর ধরেই না',
    'কাল সকালে মুছলেও একই কথা, তাড়া তো নেই',
    'স্টোরকিপার দেখছিলেন, তাই একটু গুছিয়ে রাখলাম',
    'নতুন টুল, তাই খুঁটিয়ে দেখার দরকারই নেই',
    'টুল তো টুলই, যেভাবে খুশি রাখলেই তো চলে',
  ];
  static List<String> storeWrong(CareNeed n) => storeMyths;

  static List<String> retireRight(CareFlaw f) => switch (f) {
        CareFlaw.crack => const ['হাতলে ফাটল — এমন টুলে কাজ মানে জীবন নিয়ে খেলা', 'ইনসুলেশনে ফাটল, তাই মায়া না করে বাতিল করলাম'],
        CareFlaw.bent => const ['স্ক্রুড্রাইভারের ডগা বেঁকে গেছে, তাই বাতিল', 'বাঁকা ডগার টুল আর নয় — অযোগ্য ট্যাগ দিলাম'],
        CareFlaw.widened => const ['স্প্যানারের মুখ চওড়া হয়ে গেছে, তাই বাতিল', 'চওড়া মুখের স্প্যানার আর নয় — অযোগ্য ট্যাগ'],
        _ => const ['হাইড্রোলিক টুল থেকে ক্রমাগত তেল লিক, তাই বাতিল', 'লিক করা ক্রিম্পার মায়া না করে বাতিল করলাম'],
      };
  static const retireExcuses = [
    'পুরোনো হয়ে গেছে, নতুন একটা নিতে ইচ্ছে হলো',
    'দেখতে ভালো লাগছিল না, তাই সরিয়ে রাখলাম',
    'ভালো কোম্পানির টুল, তবু আজ বাতিল করে দিলাম',
    'স্টোরকিপার বকবেন, তাই আগেভাগে বাতিল করলাম',
    'ময়লা লেগে ছিল, মোছার চেয়ে বাতিলই সহজ',
  ];

  /// The other faults (not this tool's) and the excuses.
  static List<String> retireWrong(CareFlaw f) => [
        for (final x in const [CareFlaw.crack, CareFlaw.bent, CareFlaw.widened, CareFlaw.leak])
          if (x != f) ...retireRight(x),
        ...retireExcuses,
      ];

  /// The careless coworker (new lines: device TTS until recorded in his voice).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerToss = CoworkerScript(
    line: 'ভ্যানে ছুঁড়ে রেখে দাও, কাল দেখা যাবে!',
    exitLine: coworkerExit,
    right: ['না — আগে মুছে, দেখে, তবে তার ঘরে', 'পাঁচ মিনিটের যত্ন আজই সেরে নেব', 'ছুঁড়ে নয়, টুল যাবে নিজের ঘরে'],
    wrong: [
      'ঠিক বলেছ, কাল সকালে দেখে নেব',
      'ভ্যানেই ফেলে রাখি, কাল দেখা যাবে',
      'আজ ক্লান্ত, যত্নটা কাল করব',
      'একদিন না মুছলে কিছুই হয় না',
      'সবাই তো ভ্যানেই ফেলে রাখে',
    ],
    asks: ['ও বলছে ভ্যানে ফেলে দিতে। আপনি কী করবেন?', 'যত্ন আজ, না কাল?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerGrease = CoworkerScript(
    line: 'বেশি করে গ্রিজ মাখিয়ে দাও, মরিচা আর ধরবে না!',
    exitLine: coworkerExit,
    right: ['না — পাতলা তেল দেব, বেশি নয়', 'বেশি গ্রিজে ধুলো জমে, হাত পিছলায়', 'মরিচা তুলে শুধু হালকা তেল দেব'],
    wrong: [
      'ঠিক বলেছ, মোটা করে গ্রিজ মাখাই',
      'যত বেশি গ্রিজ, তত কম মরিচা',
      'পুরো টুলটাই গ্রিজে মাখিয়ে রাখি',
      'গ্রিজ বেশি থাকলে ক্ষতি নেই',
      'সবাই তো গ্রিজ মাখিয়েই রাখে',
    ],
    asks: ['ও বলছে মোটা করে গ্রিজ দিতে। আপনি কী করবেন?', 'বেশি গ্রিজ, না পাতলা তেল?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerCrack = CoworkerScript(
    line: 'একটু ফাটা তো! ব্যাগে রেখে দাও, কাল চালিয়ে নেব।',
    exitLine: coworkerExit,
    right: ['না — ফাটা হাতলের টুল মানেই বাতিল', 'ফাটা টুলে কাজ মানে জীবন নিয়ে খেলা', 'অযোগ্য ট্যাগ লাগিয়ে আলাদা রাখব'],
    wrong: [
      'ঠিক, একটু ফাটায় কিছু হয় না',
      'ব্যাগেই রেখে দিই, কাল দেখা যাবে',
      'টেপ জড়িয়ে কাল চালিয়ে নেব',
      'নতুন না আসা পর্যন্ত এটাই চলুক',
      'সবাই তো ফাটা টুলেই কাজ সারে',
    ],
    asks: ['ও বলছে ফাটা টুল ব্যাগে রাখতে। আপনি কী করবেন?', 'ব্যাগে রাখবেন, না বাতিল?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(CarePush p) => switch (p) {
        CarePush.toss => coworkerToss,
        CarePush.grease => coworkerGrease,
        CarePush.crack => coworkerCrack,
      };

  static const callHeld = 'ঠিক! যত্ন আজই — কাল নয়।';
  static const allSet = 'হাতিয়ারের ওস্তাদ! মুছেছেন, দেখেছেন, ঘরে রেখেছেন — ভাঙাটা বাতিল।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মুছুন, দেখুন, তারপর ঘরে বা বাতিল।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtClean = 'মুছে, দেখে, তার ঘরে রেখেছেন';
  static const caughtDry = 'ভেজা টুল শুকিয়ে রেখেছেন';
  static const caughtRust = 'মরিচা তুলে, তারপর তেল';
  static const caughtMeter = 'মিটার বন্ধ, লিড আলতো গুটানো';
  static const caughtRetire = 'ভাঙা টুলে অযোগ্য ট্যাগ';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// Every fixed line of the guide and the coworker (for recording).
  static List<String> get recordLines => [
        intro,
        ask,
        ...tapWhy,
        storeAsk,
        retireAsk,
        callHeld,
        allSet,
        quick,
        fail,
        deadlyWord,
        nearMissWord,
        for (final p in CarePush.values) ...coworker(p).recordedLines,
      ];
}

abstract final class CareMistakes {
  static const _retire = 'assets/game/art/m2_tool_care/retire_tag.svg';
  static const _clean = 'assets/game/art/m2_tool_care/clean_dry.svg';
  static const _rust = 'assets/game/art/m2_tool_care/rust_oil.svg';
  static const _meter = 'assets/game/art/m2_tool_care/meter_care.svg';

  static const crackKept = DoMistake(
    key: '2.10/care/crack-kept',
    textBn: 'হাতলের ইনসুলেশনে ফাটল নিয়েই টুল তুলে রাখলেন — কাল লাইনে এই ফাটলই প্রাণ নিতে পারে। মায়া না করে ‘ব্যবহারের অযোগ্য’ ট্যাগ লাগিয়ে বাতিল করুন।',
    art: _retire,
    deadly: true,
    lessonPoint: 3,
  );
  static const bentKept = DoMistake(
    key: '2.10/care/bent-kept',
    textBn: 'স্ক্রুড্রাইভারের ডগা বাঁকা — এমন টুল বাতিল। ‘ব্যবহারের অযোগ্য’ ট্যাগ লাগিয়ে আলাদা রাখুন।',
    art: _retire,
    lessonPoint: 3,
  );
  static const widenedKept = DoMistake(
    key: '2.10/care/widened-kept',
    textBn: 'স্প্যানারের মুখ চওড়া হয়ে গেছে — এমন স্প্যানার বাতিল। ট্যাগ লাগিয়ে আলাদা রাখুন।',
    art: _retire,
    lessonPoint: 3,
  );
  static const leakKept = DoMistake(
    key: '2.10/care/leak-kept',
    textBn: 'হাইড্রোলিক টুল থেকে ক্রমাগত তেল লিক করছে — এমন টুল বাতিল। ট্যাগ লাগিয়ে আলাদা রাখুন।',
    art: _retire,
    lessonPoint: 3,
  );
  static const goodRetired = DoMistake(
    key: '2.10/care/good-retired',
    textBn: 'ভালো টুল বাতিল নয় — হাতলে ফাটল, বাঁকা ডগা, চওড়া মুখ বা তেল লিক থাকলে তবেই বাতিল। আগে মুছে ভালো করে দেখুন।',
    art: _retire,
    lessonPoint: 3,
  );
  static const dirty = DoMistake(
    key: '2.10/care/dirty',
    textBn: 'ময়লা নিয়েই টুল তুলে রাখলেন — আগে শুকনো কাপড়ে ধুলো, ময়লা, তেল মুছুন; হাতে নিয়ে দেখুন, তারপর তার ঘরে।',
    art: _clean,
    lessonPoint: 0,
  );
  static const wet = DoMistake(
    key: '2.10/care/wet',
    textBn: 'ভেজা বা স্যাঁতস্যাঁতে টুল কখনো টুলবক্সে নয় — শুকনো কাপড়ে মুছে শুকিয়ে তবেই রাখুন।',
    art: _clean,
    lessonPoint: 0,
  );
  static const skipCare = DoMistake(
    key: '2.10/care/skip-care',
    textBn: 'ভ্যানে ছুঁড়ে রাখা নয় — কাজের শেষে 5 মিনিট: মুছুন, দেখুন, প্রতিটা টুল তার নির্দিষ্ট জায়গায়।',
    art: _clean,
    lessonPoint: 0,
  );
  static const rustLeft = DoMistake(
    key: '2.10/care/rust-left',
    textBn: 'মরিচা নিয়েই তুলে রাখলেন — স্টিল ব্রাশ বা শিরিষ কাগজে ঘষে মরিচা তুলুন, তারপর তেল দিন।',
    art: _rust,
    lessonPoint: 1,
  );
  static const oilOnRust = DoMistake(
    key: '2.10/care/oil-on-rust',
    textBn: 'মরিচার ওপরেই তেল দিলেন — আগে স্টিল ব্রাশে মরিচা ঘষে তুলুন, তারপর তেল।',
    art: _rust,
    lessonPoint: 1,
  );
  static const noOil = DoMistake(
    key: '2.10/care/no-oil',
    textBn: 'মরিচা তোলার পর তেল দেননি — ধাতুর ওপর হালকা তেলের পাতলা একটা স্তর দিন।',
    art: _rust,
    lessonPoint: 1,
  );
  static const oilInsulation = DoMistake(
    key: '2.10/care/oil-insulation',
    textBn: 'তেল পড়ল ইনসুলেটেড হাতলে — তেল শুধু ধাতব অংশে; খেয়াল রাখুন যেন ইনসুলেশনে না লাগে।',
    art: _rust,
    lessonPoint: 1,
  );
  static const overOil = DoMistake(
    key: '2.10/care/over-oil',
    textBn: 'অতিরিক্ত তেল-গ্রিজ ধুলো টানে, জয়েন্টের ক্ষতি করে, হাতের গ্রিপ কমায় — পাতলা একটা স্তরই যথেষ্ট।',
    art: _rust,
    lessonPoint: 1,
  );
  static const oilMeter = DoMistake(
    key: '2.10/care/oil-meter',
    textBn: 'তেল ধাতব টুলের জন্য — মাল্টিমিটারের যত্ন আলাদা: বন্ধ করুন, লিড আলতো করে গুটিয়ে রাখুন।',
    art: _meter,
    lessonPoint: 2,
  );
  static const meterOn = DoMistake(
    key: '2.10/care/meter-on',
    textBn: 'মিটার চালু রেখেই তুলে রাখলেন — ব্যবহার না করলে যন্ত্রটি বন্ধ করুন।',
    art: _meter,
    lessonPoint: 2,
  );
  static const leadsTwisted = DoMistake(
    key: '2.10/care/leads-twisted',
    textBn: 'প্রোবের তার পেঁচিয়ে বা ভাঁজ করে রাখবেন না — আলতো করে গুটিয়ে রাখুন।',
    art: _meter,
    lessonPoint: 2,
  );
  static const all = [
    crackKept, bentKept, widenedKept, leakKept, goodRetired, dirty, wet, skipCare, //
    rustLeft, oilOnRust, noOil, oilInsulation, overOil, oilMeter, meterOn, leadsTwisted,
  ];

  static DoMistake kept(CareFlaw f) => switch (f) {
        CareFlaw.crack => crackKept,
        CareFlaw.bent => bentKept,
        CareFlaw.widened => widenedKept,
        _ => leakKept,
      };
}

CareFlaw _flawFor(CareKind k, math.Random rng) => switch (k) {
      CareKind.pliers => CareFlaw.crack,
      CareKind.screwdriver => rng.nextBool() ? CareFlaw.crack : CareFlaw.bent,
      CareKind.spanner => CareFlaw.widened,
      CareKind.crimper => CareFlaw.leak,
      CareKind.meter => CareFlaw.none,
    };

/// A fresh pile each play: which tools, their order, which is damaged (one,
/// sometimes two), which is wet, and the coworker's moment.
CareDeal dealCare(math.Random rng) {
  final extra = [CareKind.screwdriver, CareKind.meter, CareKind.crimper]..shuffle(rng);
  final kinds = [CareKind.pliers, CareKind.spanner, extra[0], extra[1]]..shuffle(rng);
  final flawable = [for (final k in kinds) if (k != CareKind.meter) k]..shuffle(rng);
  final flaws = <CareKind, CareFlaw>{flawable[0]: _flawFor(flawable[0], rng)};
  if (rng.nextDouble() < 0.4) flaws[flawable[1]] = _flawFor(flawable[1], rng);
  var tools = <CareTool>[];
  for (var i = 0; i < kinds.length; i++) {
    final k = kinds[i];
    final f = flaws[k] ?? CareFlaw.none;
    // Rust and water are drawn from the first frame, so they are dealt with
    // no regard to the fault: a rusty or wet tool may be sound or damaged,
    // and only the wipe tells.
    final need = k == CareKind.meter
        ? CareNeed.meter
        : k == CareKind.spanner
            ? (rng.nextDouble() < 0.75 ? CareNeed.rusty : CareNeed.plain)
            : (rng.nextDouble() < 0.45 ? CareNeed.wet : CareNeed.plain);
    tools.add(CareTool(id: 't$i', kind: k, flaw: f, need: need));
  }
  // Always one tool that needs more than the wipe: if nothing came wet or
  // rusty, the spanner (always on the bench) gets the rust, fault or not.
  if (!tools.any((t) => t.need == CareNeed.wet || t.need == CareNeed.rusty)) {
    final j = tools.indexWhere((t) => t.kind == CareKind.spanner);
    tools[j] = CareTool(id: tools[j].id, kind: tools[j].kind, flaw: tools[j].flaw, need: CareNeed.rusty);
  }
  tools = List.unmodifiable(tools);
  final callRound = rng.nextInt(tools.length);
  final kit = [0, 1, 2, 3];
  do {
    kit.shuffle(rng);
  } while (careKitInRoutineOrder(kit));
  return CareDeal(tools: tools, callRound: callRound, kitOrder: List.unmodifiable(kit));
}

enum CareVerdict { none, ok, right, slip, deadly }

@immutable
class CareOutcome {
  const CareOutcome(this.verdict, {this.mistake});
  final CareVerdict verdict;
  final DoMistake? mistake;
  static const none = CareOutcome(CareVerdict.none);
  static const ok = CareOutcome(CareVerdict.ok);
}

/// The play state (pure logic).
class CareRun {
  CareRun(this.deal);
  final CareDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;

  /// This tool is decided (in its place, or in the crate): the reason, then [next].
  bool shown = false;
  bool retiredNow = false;

  // The tool on the bench.
  double wiped = 0;
  double brushed = 0;
  final List<Offset> oil = [];
  bool meterOn = true;
  bool coiled = false;
  bool flawSeen = false;

  final Set<String> stored = {};
  final Set<String> retired = {};
  final List<String> caught = [];

  bool get done => round >= deal.tools.length;
  bool get ended => done || deadly != null;
  CareTool get current => deal.tools[round.clamp(0, deal.tools.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  // What shows on the bench.
  double get dirt => (1 - wiped / kCareClean).clamp(0.0, 1.0);
  double get wet => current.need == CareNeed.wet ? (1 - wiped / kCareDry).clamp(0.0, 1.0) : 0;
  double get rust => current.need == CareNeed.rusty ? (1 - brushed / kCareRustOff).clamp(0.0, 1.0) : 0;
  bool get flawShows => flawSeen || wiped >= kCareFlawShows;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  bool get _locked => ended || shown;

  /// The cloth goes over the tool; true when the tool has just come clean
  /// enough to look at (on every tool, damaged or sound — the cue gives
  /// nothing away; a fault under the grime shows from then on).
  bool wipe(double amount) {
    if (_locked) return false;
    final before = wiped >= kCareFlawShows;
    wiped = math.min(1, wiped + amount);
    if (before || wiped < kCareFlawShows) return false;
    if (current.flawed) flawSeen = true;
    return true;
  }

  /// The steel brush scrubs (only rust comes off).
  void brush(double amount) {
    if (_locked) return;
    brushed = math.min(1, brushed + amount);
  }

  CareOutcome _slip(DoMistake m) {
    slips++;
    return CareOutcome(CareVerdict.slip, mistake: m);
  }

  /// A drop of oil at [p] (the tool's 300 × 120 space).
  CareOutcome oilAt(Offset p) {
    if (_locked) return CareOutcome.none;
    final t = current;
    if (t.kind == CareKind.meter) return _slip(CareMistakes.oilMeter);
    if (CareZones.onInsulation(t.kind, p)) return _slip(CareMistakes.oilInsulation);
    if (rust > 0.05) return _slip(CareMistakes.oilOnRust);
    oil.add(p);
    if (oil.length > kCareMaxOil) {
      // The excess wiped off for him; the myth costs a slip.
      oil.removeRange(kCareMaxOil, oil.length);
      return _slip(CareMistakes.overOil);
    }
    return CareOutcome.ok;
  }

  /// The meter's dial to OFF.
  CareOutcome dialOff() {
    if (_locked || current.kind != CareKind.meter || !meterOn) return CareOutcome.none;
    meterOn = false;
    return CareOutcome.ok;
  }

  /// The meter's leads coiled loosely.
  CareOutcome coilLeads() {
    if (_locked || current.kind != CareKind.meter || coiled) return CareOutcome.none;
    coiled = true;
    return CareOutcome.ok;
  }

  /// "তার ঘরে রাখুন": the tool goes to its place on the pegboard — if it is
  /// fit and cared for.
  CareOutcome store() {
    if (_locked) return CareOutcome.none;
    final t = current;
    if (t.flawed) {
      flawSeen = true;
      if (t.flaw == CareFlaw.crack) {
        deadly = CareMistakes.crackKept;
        return const CareOutcome(CareVerdict.deadly, mistake: CareMistakes.crackKept);
      }
      return _slip(CareMistakes.kept(t.flaw));
    }
    if (t.need == CareNeed.wet && wiped < kCareDry) return _slip(CareMistakes.wet);
    if (wiped < kCareClean) return _slip(CareMistakes.dirty);
    if (t.need == CareNeed.rusty && brushed < kCareRustOff) return _slip(CareMistakes.rustLeft);
    if (t.need == CareNeed.rusty && oil.isEmpty) return _slip(CareMistakes.noOil);
    if (t.need == CareNeed.meter && meterOn) return _slip(CareMistakes.meterOn);
    if (t.need == CareNeed.meter && !coiled) return _slip(CareMistakes.leadsTwisted);
    _tag(switch (t.need) {
      CareNeed.plain => CareLines.caughtClean,
      CareNeed.wet => CareLines.caughtDry,
      CareNeed.rusty => CareLines.caughtRust,
      CareNeed.meter => CareLines.caughtMeter,
    });
    stored.add(t.id);
    shown = true;
    return const CareOutcome(CareVerdict.right);
  }

  /// The "ব্যবহারের অযোগ্য" tag on the tool: into the বাতিল crate.
  CareOutcome retire() {
    if (_locked) return CareOutcome.none;
    final t = current;
    if (!t.flawed) return _slip(CareMistakes.goodRetired);
    flawSeen = true;
    _tag(CareLines.caughtRetire);
    retired.add(t.id);
    retiredNow = true;
    shown = true;
    return const CareOutcome(CareVerdict.right);
  }

  /// What the coworker pushes on this tool now. "একটু ফাটা তো" only once the
  /// crack shows (before that it would name the fault for the player).
  CarePush get push {
    final t = current;
    if (t.flaw == CareFlaw.crack && flawShows) return CarePush.crack;
    if (t.need == CareNeed.rusty && rust > 0.3) return CarePush.grease;
    return CarePush.toss;
  }

  /// The player listened to him. Listening is a slip; on the cracked grip
  /// (the module table's deadly act: a cracked insulated grip kept as fit) it
  /// is deadly — FLAGGED for the owner.
  CareOutcome listen(CarePush p) {
    if (ended) return CareOutcome.none;
    if (p == CarePush.crack) {
      deadly = CareMistakes.crackKept;
      return const CareOutcome(CareVerdict.deadly, mistake: CareMistakes.crackKept);
    }
    return _slip(p == CarePush.grease ? CareMistakes.overOil : CareMistakes.skipCare);
  }

  /// The next tool (after the reason).
  void next() {
    if (deadly != null || done) return;
    round++;
    shown = false;
    retiredNow = false;
    wiped = 0;
    brushed = 0;
    oil.clear();
    meterOn = true;
    coiled = false;
    flawSeen = false;
  }
}

@immutable
class M2ToolCarePack {
  const M2ToolCarePack({required this.id, required this.titleBn, this.quickMs = 150000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2ToolCarePack210 = M2ToolCarePack(id: 'do_2_10_a', titleBn: CareLines.title);
const m2ToolCarePacks = {'do_2_10_a': m2ToolCarePack210};

// ============================================================================
// Page
// ============================================================================

class M2ToolCarePage extends StatefulWidget {
  const M2ToolCarePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2ToolCarePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2ToolCarePage> createState() => _M2ToolCarePageState();
}

class _M2ToolCarePageState extends State<M2ToolCarePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CareRunPage(
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

class _CareRunPage extends ConsumerStatefulWidget {
  const _CareRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2ToolCarePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CareRunPage> createState() => _CareRunPageState();
}

class _CareRunPageState extends ConsumerState<_CareRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final CareRun _run = CareRun(dealCare(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The bench item in hand: 0 cloth · 1 brush · 2 oil · 3 tag.
  int? _hand;

  /// Where the cloth / brush is on the tool (its box's design px), while dragging.
  Offset? _rubAt;
  double _rubSound = 0;

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
  CarePush _push = CarePush.toss;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The cloth / brush moved a moment ago (the coworker waits for a pause:
  /// he never cuts in between two strokes).
  Timer? _rubQuiet;

  /// Gesture hints (how to touch, never what): the bench's waiting states.
  final _hints = IdleHintController();
  final _toolKey = GlobalKey();
  final _storeKey = GlobalKey();
  final _kitKeys = [for (var i = 0; i < 4; i++) GlobalKey()];

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _rubQuiet?.cancel();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice ------------------------------------------------------------------------

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

  void _cue(String s, double v) {
    if (!_muted) unawaited(ZlFx.cue(s, volume: v, muted: false));
  }

  // ---- flow -------------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([CareLines.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  /// The scene takes no move now (also the praise window: `tableBusy`).
  bool get _blocked => _intro || _busy || _ended || _card != null || tableBusy || _run.shown || _freeze;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// Going on working while he is still talking refuses him (call it only
  /// for a move that does something to the tool).
  bool _refusedByWork(Offset at) {
    if (coworkerOpen && !coworkerChoiceUp) {
      unawaited(answerCoworker(true, at, direct: true));
      return true;
    }
    return coworkerOpen;
  }

  /// Picking up a bench item is no work on the tool: it never refuses him.
  void _pickHand(int i) {
    if (_blocked || coworkerChoiceUp) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', 0.4);
    setState(() {
      _hand = _hand == i ? null : i;
      _setMode(_hand == null ? LinemanMode.idle : LinemanMode.hold);
    });
  }

  /// The finger on the tool (its 300 × 120 space), a tap.
  void _toolTap(Offset p, Offset global) {
    if (_blocked) return;
    final meter = _run.current.kind == CareKind.meter;
    final acts = switch (_hand) {
      2 || 3 => true,
      _ => meter && ((CareZones.onDial(p) && _run.meterOn) || (CareZones.onLeads(p) && !_run.coiled)),
    };
    if (!acts) {
      // A tap that does nothing: no work (he is not refused), a miss for the hint.
      if (!coworkerOpen) _hints.missTap();
      return;
    }
    if (_refusedByWork(global)) return;
    final CareOutcome o;
    switch (_hand) {
      case 2:
        o = _run.oilAt(p);
        if (o.verdict == CareVerdict.ok) _cue('sounds/intro/click.ogg', 0.5);
      case 3:
        _retire(global);
        return;
      default:
        if (_run.current.kind != CareKind.meter) return;
        if (CareZones.onDial(p)) {
          o = _run.dialOff();
          if (o.verdict == CareVerdict.ok) _cue('sounds/intro/click.ogg', 0.6);
        } else if (CareZones.onLeads(p)) {
          o = _run.coilLeads();
          if (o.verdict == CareVerdict.ok) _cue('sounds/quiz_flip.wav', 0.5);
        } else {
          return;
        }
    }
    HapticFeedback.selectionClick();
    setState(() {});
    if (o.verdict == CareVerdict.slip) {
      setState(() => _setMode(LinemanMode.worried));
      unawaited(_slip(o.mistake!, global));
    }
  }

  /// The cloth or the brush dragged over the tool.
  void _toolRub(Offset local, double distance, Offset global) {
    if (_hand != 0 && _hand != 1) return;
    if (_blocked || _refusedByWork(global)) return;
    _rubQuiet?.cancel();
    _rubQuiet = Timer(const Duration(milliseconds: 700), () => _rubQuiet = null);
    var found = false;
    if (_hand == 0) {
      found = _run.wipe(distance / 700);
    } else {
      _run.brush(distance / 600);
    }
    _rubSound += distance;
    if (_rubSound > 110) {
      _rubSound = 0;
      _cue('sounds/quiz_shuffle.wav', 0.25);
    }
    if (found) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tock.wav', 0.6);
    }
    setState(() => _rubAt = local);
  }

  void _rubEnd() {
    if (_rubAt != null) setState(() => _rubAt = null);
  }

  void _store(Offset at) {
    if (_blocked || _refusedByWork(at)) return;
    if (holdForCoworker()) return;
    _hush();
    final o = _run.store();
    switch (o.verdict) {
      case CareVerdict.right:
        HapticFeedback.lightImpact();
        _cue('sounds/quiz_right.wav', 0.6);
        _cue('sounds/intro/impact_metal.ogg', 0.45);
        setState(() {
          _hand = null;
          _setMode(LinemanMode.cheer);
        });
        final need = _run.current.need;
        _ask(15, () => dealChoices(CareLines.storeRight(need), CareLines.storeWrong(need), widget.rng), CareLines.storeAsk);
      case CareVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        unawaited(_slip(o.mistake!, at));
      case CareVerdict.deadly:
        unawaited(_deadly(o.mistake!));
      default:
    }
  }

  void _retire(Offset at) {
    if (holdForCoworker()) return;
    final o = _run.retire();
    if (o.verdict == CareVerdict.right) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tag_slap.wav', 0.6);
      _cue('sounds/quiz_right.wav', 0.5);
      setState(() {
        _hand = null;
        _setMode(LinemanMode.cheer);
      });
      final f = _run.current.flaw;
      _ask(15, () => dealChoices(CareLines.retireRight(f), CareLines.retireWrong(f), widget.rng), CareLines.retireAsk);
      return;
    }
    if (o.verdict == CareVerdict.slip) {
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
      _hand = null;
      _setMode(LinemanMode.idle);
    });
    _cue('sounds/quiz_flip.wav', 0.5);
    _armCoworker();
    unawaited(_sayChain([CareLines.ask]));
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

  // --- CoworkerMoment ---------------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => CareLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    // Asked only before he arrives; refreshed on every ask so a held arrival
    // (holdForCoworker on a fast play) still pushes what fits the moment.
    _push = _run.push;
    if (_blocked || tableBusy || _rubAt != null || _rubQuiet != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final o = _run.listen(_push);
      if (o.verdict == CareVerdict.none) return;
      if (o.verdict == CareVerdict.deadly) {
        await _deadly(o.mistake!);
      } else {
        setState(() => _setMode(LinemanMode.worried));
        await _slip(o.mistake!, origin);
      }
      return;
    }
    _run.caught.add(CareLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([CareLines.callHeld, CareLines.ask], mood: GuideMood.glad);
    }());
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? CareLines.tapWhy[_nudgeN++ % CareLines.tapWhy.length]
            : _nudge.next(CareLines.ask);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // ---- gesture hints ------------------------------------------------------------------

  /// The bench waits for a move (no card, deck, coworker, praise window).
  bool get _hintWaiting =>
      !_blocked && _mark == null && !struckOut && !_run.done && !coworkerOnScreen && !_deckUp;

  bool get _deckUp => reasonOpen || coworkerChoiceUp;

  /// How to touch, never what: with the cloth or the brush in hand a short
  /// rub nudge on the tool (it is the only thing to rub); otherwise a sweep
  /// over the tool, every bench item and "তার ঘরে রাখুন", pressing none.
  HintSpec? _hint() {
    if (_hand == 0 || _hand == 1) {
      final r = HintSpec.globalRectOf(_toolKey);
      return r == null ? null : HintSpec.drag(Offset(r.left + r.width * 0.2, r.top + r.height * 0.55), toward: const Offset(1, 0), travel: 80);
    }
    return HintSpec.sweepOver([_toolKey, for (final i in _run.deal.kitOrder) _kitKeys[i], _storeKey]);
  }

  Object get _hintKey => '${_run.round}/$_hand/${_run.slips}/${_run.meterOn}/${_run.coiled}';

  // ---- mistakes ----------------------------------------------------------------------

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
    _cue('sounds/quiz_wrong.wav', 0.7);
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _rubAt = null;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('care/${m.key}');
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
    _cue('sounds/learn/spark.wav', 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _hand = null;
      _rubAt = null;
      _setMode(LinemanMode.worried);
      _freeze = true;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('care/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? CareLines.deadlyWord : CareLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(LinemanMode.idle);
        });
        unawaited(_sayChain([CareLines.ask]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  // ---- score and result ---------------------------------------------------------------

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
    await _say(!_run.passed ? CareLines.fail : (_quickBonus ? CareLines.quick : CareLines.allSet),
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

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = CareGeo(m.height);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final kinds = [for (final t in _run.deal.tools) t.kind];
    final t = _run.done ? null : _run.current;
    final toolRect = t == null
        ? geo.tool
        : !_run.shown
            ? geo.tool
            : _run.retiredNow
                ? geo.crate.deflate(6)
                : geo.slot(t.kind);
    return [
      Positioned.fill(
        key: const ValueKey('room'),
        child: ColorFiltered(colorFilter: grey, child: RepaintBoundary(child: CustomPaint(painter: CareRoomPainter(geo, kinds: kinds)))),
      ),
      // Tools already in their places on the pegboard.
      for (final x in _run.deal.tools)
        if (_run.stored.contains(x.id) && x.id != t?.id)
          Positioned.fromRect(
            key: ValueKey('peg-${x.id}'),
            rect: geo.slot(x.kind),
            child: ColorFiltered(colorFilter: grey, child: CustomPaint(painter: CareToolPainter(kind: x.kind, coiled: true))),
          ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: ColorFiltered(colorFilter: grey, child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
      ),
      Positioned.fill(
        key: const ValueKey('bench'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(child: CustomPaint(painter: CareBenchPainter(geo, tagged: _run.retired.length - (_run.retiredNow ? 1 : 0)))),
        ),
      ),
      Positioned(
        key: const ValueKey('crate-label'),
        left: geo.crate.left,
        width: geo.crate.width,
        top: geo.crate.bottom - 16,
        child: IgnorePointer(
          child: Text(CareLines.crate, textAlign: TextAlign.center, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFF7F1E1))),
        ),
      ),
      if (t != null)
        AnimatedPositioned.fromRect(
          key: ValueKey('tool-${t.id}'),
          rect: toolRect,
          duration: Duration(milliseconds: quiet ? 1 : 520),
          curve: Curves.easeInOutCubic,
          child: ColorFiltered(
            colorFilter: grey,
            child: DoDealIn(
              index: 0,
              quiet: quiet,
              muted: true,
              child: _BenchTool(
                key: _toolKey,
                tool: t,
                run: _run,
                hand: _hand,
                rubAt: _rubAt,
                enabled: !_blocked && !_run.shown,
                onTap: _toolTap,
                onRub: _toolRub,
                onRubEnd: _rubEnd,
              ),
            ),
          ),
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
    final trayUp = playing && _card == null && !deckUp && !_run.shown && !_run.done;
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
              labels: [for (final t in _run.deal.tools) CareLines.name(t.kind)],
              done: {for (var i = 0; i < math.min(_run.round, _run.deal.tools.length); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            hintAutoMiss: true,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (trayUp)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  left: 8,
                  right: 124,
                  bottom: pad.bottom + 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // The bench items in this play's dealt order.
                          for (final (n, i) in _run.deal.kitOrder.indexed) ...[
                            if (n > 0) const SizedBox(width: 6),
                            Expanded(
                              child: KeyedSubtree(
                                key: _kitKeys[i],
                                child: _KitChip(item: i, selected: _hand == i, onTapUp: (_) => _pickHand(i)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      KeyedSubtree(
                        key: _storeKey,
                        child: DoBigButton(label: CareLines.store, filled: true, onTapUp: (d) => _store(d.globalPosition)),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
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
                  consequence: _ShockFlash(quiet: quiet),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: CareLines.intro,
                  alarm: 'sounds/intro/impact_metal.ogg',
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

/// The tool lying on the bench: wipe or scrub it by dragging, tap it to oil,
/// tag, or turn the meter's dial / coil its leads.
class _BenchTool extends StatelessWidget {
  const _BenchTool({
    super.key,
    required this.tool,
    required this.run,
    required this.hand,
    required this.rubAt,
    required this.enabled,
    required this.onTap,
    required this.onRub,
    required this.onRubEnd,
  });

  final CareTool tool;
  final CareRun run;
  final int? hand;
  final Offset? rubAt;
  final bool enabled;
  final void Function(Offset toolPoint, Offset global) onTap;
  final void Function(Offset local, double distance, Offset global) onRub;
  final VoidCallback onRubEnd;

  @override
  Widget build(BuildContext context) {
    final rub = rubAt;
    return Semantics(
      label: CareLines.toolLabel,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: enabled ? (d) => onTap(careToolPoint(size, d.localPosition), d.globalPosition) : null,
            onPanUpdate: enabled ? (d) => onRub(d.localPosition, d.delta.distance, d.globalPosition) : null,
            onPanEnd: enabled ? (_) => onRubEnd() : null,
            onPanCancel: enabled ? onRubEnd : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: CareToolPainter(
                      kind: tool.kind,
                      flaw: tool.flaw,
                      dirt: run.dirt,
                      wet: run.wet,
                      rust: run.rust,
                      oil: List.of(run.oil),
                      meterOn: run.meterOn,
                      coiled: run.coiled,
                      flawShown: run.flawShows,
                    ),
                  ),
                ),
                if (run.retiredNow && run.current.id == tool.id)
                  Positioned(
                    key: const ValueKey('tag'),
                    left: size.width * 0.36,
                    top: size.height * 0.02,
                    width: size.width * 0.44,
                    height: size.height * 0.26,
                    // Scales with the tool, so it rides into the crate with it.
                    child: const FittedBox(fit: BoxFit.contain, alignment: Alignment.topLeft, child: _RetireTag()),
                  ),
                if (rub != null && (hand == 0 || hand == 1))
                  Positioned(
                    key: const ValueKey('rub'),
                    left: rub.dx - 22,
                    top: rub.dy - 18,
                    width: 44,
                    height: 34,
                    child: IgnorePointer(child: CustomPaint(painter: CareHandPainter(brush: hand == 1))),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The red "ব্যবহারের অযোগ্য" tag on a retired tool.
class _RetireTag extends StatelessWidget {
  const _RetireTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFF7F1E1), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 2))],
      ),
      child: Text(CareLines.tagText, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
    );
  }
}

/// A bench item in the tray: cloth, brush, oil can, tag.
class _KitChip extends StatelessWidget {
  const _KitChip({required this.item, required this.selected, required this.onTapUp});
  final int item;
  final bool selected;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: CareLines.kit[item],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 62,
          padding: const EdgeInsets.fromLTRB(2, 5, 2, 3),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B2F12) : const Color(0xE60B1A33),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? SlmColors.gold300 : const Color(0x55FFFFFF), width: selected ? 2.4 : 1.2),
          ),
          child: Column(
            children: [
              Expanded(child: CustomPaint(painter: CareKitIconPainter(item), child: const SizedBox.expand())),
              const SizedBox(height: 2),
              ExcludeSemantics(
                child: Text(CareLines.kit[item], style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The deadly moment: tomorrow on the line, the current through the crack.
class _ShockFlash extends StatelessWidget {
  const _ShockFlash({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1800),
      builder: (_, t, _) => Opacity(
        opacity: (t * 5).clamp(0.0, 1.0),
        child: CustomPaint(painter: CareShockPainter(t), child: const SizedBox.expand()),
      ),
    );
  }
}
