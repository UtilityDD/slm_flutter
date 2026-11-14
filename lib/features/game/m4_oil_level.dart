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
import 'm4_oil_level_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_oil_level_world.dart'
    show M4OilLevelDrum, M4OilLevelGeo, M4OilLevelSpot, M4OilLevelWeather, kM4OilLevelMark, kM4OilLevelMax, kM4OilLevelMin;

// Lesson 4.5 "ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা পরীক্ষা", কাজ 1 "তেলের মাপ"
// (pack do_4_5_a, engineType m4_oil_level). Three distribution transformers
// on DP structures a play; at each the trainee does the lesson's inspection
// and acts on it. Dealt fresh: which one is fine, which leaks with the level
// still fine, which is low; the weather of each visit (a summer noon, a
// winter morning, a mild day); where the leak is; the drum order.
//
// The lesson's rules, and only those:
//   • point 1: the glass gauge on the conservator tank, marked Min, Max and
//     the normal level at a set temperature (30°C); the level should be near
//     that mark; read from below — no shutdown needed; below Min = danger
//     (the winding comes out of the oil: cooling and insulation fail);
//   • pro tip 2: oil expands in heat (the level rises) and contracts in cold
//     (it falls) — read the gauge with the weather in mind;
//   • point 3: low oil's main cause is a leak — the bushing's gasket, a
//     welding joint, the drain cock, a cooling fin; report at once to the
//     supervisor; top-up and the leak repair are arranged (film: a leak at a
//     bushing or the drain valve is reported at once, even with the level
//     still fine);
//   • pro tip 1 + film: top up only with the transformer switched off
//     ("লাইন বন্ধ করে"), with new, filtered oil of the same grade; wrong or
//     moist oil damages the transformer; myth 1: never engine oil or any
//     other oil (fire).
// From the brief's safety rules (not lesson 4.5's text — flagged in
// REGISTER.md): the shutdown is followed by a test (proved dead) and the
// earth before anyone climbs; whoever climbs wears helmet and harness.
//
// Hands on: tap the gauge to read it (a close-up), tap the tank's parts to
// look for a leak, then "ঠিক আছে" or "রিপোর্ট". The low one goes on to the
// top-up: শাটডাউন (the DO fuses drop) · টেস্টার (LIVE / DEAD) · আর্থ · উঠুন
// (helmet + harness), the drums on the ground (tap to take one), and hold to
// pour until the gauge reaches the mark.
//
// Deadly: climbing the live transformer (also by listening to the careless
// coworker, "চালু অবস্থায় একটু তেল ঢেলে দাও!"); the earth put on a live line.
// Slips: a verdict without reading the gauge, a low level passed as fine, a
// leak missed, a fine level misread (heat/cold), earth before the test,
// climbing before the test and earth, a wrong drum (engine / used / moist
// oil). Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_oil_level_world.dart), corner guide, ◆ on the table → "কেন …?" →
// the next transformer by itself. Voice: the guide by device TTS; the
// coworker's push is silent with its caption held until recorded (his exit
// line is recorded).
//
// Fair play: the step buttons are dealt in a shuffled order (never the right
// one); a looked-at part gets the same soft ring and the same tick whether it
// leaks or not (the oil streak is the evidence); the praise window takes no
// input ([ReasonTable.tableBusy]); a step tapped before the coworker came
// waits for him ([CoworkerMoment.holdForCoworker]); idle hands get a gesture
// hint (a sweep over the choices, a hold on the pour).

// ============================================================================
// Content
// ============================================================================

/// What the transformer is this visit.
enum M4OilLevelKind { fine, leak, low }

/// The round's stage: the inspection, then (low oil only) the top-up.
enum M4OilLevelPhase { inspect, topup }

/// The top-up steps (buttons).
enum M4OilLevelStep { shutdown, test, earth, climb }

@immutable
class M4OilLevelCase {
  const M4OilLevelCase({required this.id, required this.dtrNo, required this.kind, required this.weather, required this.level, this.leak});

  final String id;
  final int dtrNo;
  final M4OilLevelKind kind;
  final M4OilLevelWeather weather;

  /// The oil in the gauge glass (0 = bottom, 1 = top).
  final double level;

  /// Where it leaks ([M4OilLevelKind.leak] and [M4OilLevelKind.low]).
  final M4OilLevelSpot? leak;

  bool get low => kind == M4OilLevelKind.low;
}

abstract final class M4OilLevelLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask, topupTask];

  static const title = 'তেলের মাপ';
  static const intro = 'ট্রান্সফরমারের রক্ত তেল। তিনটের তেল মেপে দেখুন!';
  static const rounds = ['ক', 'খ', 'গ'];
  static const ask = 'এই ট্রান্সফরমারের তেল ঠিক আছে তো? দেখে বলুন।';
  static const topupAsk = 'সুপারভাইজার বললেন, টপ-আপ করুন। এবার আপনার কাজ।';
  static const topupTask = 'তেলটা টপ-আপ করুন — নিয়ম মেনে।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ট্রান্সফরমার';
  static const ok = 'ঠিক আছে — খাতায়';
  static const report = 'রিপোর্ট — সুপারভাইজার';
  static const docket = 'DTR পরিদর্শন';
  static String dtr(int n) => enDigits('DTR-$n');
  static String when(M4OilLevelWeather w) => enDigits(switch (w) {
        M4OilLevelWeather.summer => '22 মে · দুপুর 2টা',
        M4OilLevelWeather.winter => '8 জানুয়ারি · ভোর 6টা',
        M4OilLevelWeather.mild => '15 মার্চ · সকাল 10টা',
      });
  static String stepBn(M4OilLevelStep s) => switch (s) {
        M4OilLevelStep.shutdown => 'শাটডাউন',
        M4OilLevelStep.test => 'টেস্টার',
        M4OilLevelStep.earth => 'আর্থ',
        M4OilLevelStep.climb => 'উঠুন',
      };
  static const pour = 'চেপে ধরে ঢালুন';
  static const live = 'LIVE';
  static const dead = 'DEAD';

  static const stampOk = 'খাতায়: ঠিক আছে';
  static const stampReport = 'রিপোর্ট গেল';
  static const stampFilled = 'টপ-আপ হলো';

  // The reasons: the right ones fit what this transformer was; the wrong ones
  // are field excuses and myths. All within 1.3× in length.
  static const whyOk = 'কেন ঠিক আছে লিখলেন?';
  static const whyReport = 'কেন রিপোর্ট করলেন?';
  static const whyTopup = 'কেন এভাবে টপ-আপ করলেন?';
  static const fineWinter = ['শীতে তেল সংকুচিত, লেভেল তবু MIN-এর ওপরে', 'ঠান্ডায় লেভেল নামে, MIN পেরোয়নি, লিক নেই'];
  static const fineSummer = ['গরমে তেল প্রসারিত, লেভেল তবু MAX-এর নিচে', 'গরমে লেভেল একটু ওঠে, MAX ছাড়ায়নি, লিক নেই'];
  static const fineMild = ['লেভেল 30°C দাগের কাছেই, কোথাও লিক নেই', 'গেজে তেল দাগ বরাবর, বডিতে কোনো লিক নেই'];
  // The wrong ones use the right ones' words too (লেভেল, লিক, গেজ, MIN,
  // MAX, দাগ, শীতে, গরমে, তেল, 30°C, ফিল্টার, ওয়াইন্ডিং ...), so no word
  // gives the right card away.
  static const fineWrong = [
    'ট্রান্সফরমার তো চলছে, তাই লেভেলও ঠিক আছে',
    'হামিং শুনেই বুঝেছি, গেজ দেখার দরকার নেই',
    'রিপোর্ট লিখতে ঝামেলা, তাই লিক নেই লিখলাম',
    'গতবার লেভেল ঠিক ছিল, এবারও ঠিকই থাকবে',
    'লেভেল কমলেও ট্রান্সফরমার নিজেই সামলে নেয়',
    'সুপারভাইজার বকবেন, তাই লিকের কথা লিখিনি',
    'MIN-এর নিচে নামলেও চলে, তাই ঠিক লিখে দিলাম',
    'MAX ছাড়িয়ে গেলেও ক্ষতি নেই, তাই ঠিক আছে',
    'দাগ মেলানোর দরকার নেই, রং দেখেই বুঝেছি',
    'শীতে-গরমে লেভেল একই থাকে, তাই দেখিনি',
    '30°C দাগ দেখার দরকার নেই, তেল তো আছেই',
    'ঠান্ডায় তেল সংকুচিত, তাই কম থাকলেও চলে',
    'গরমে তেল প্রসারিত, তাই গেজ দেখা লাগে না',
  ];
  static const leakRight = [
    'লেভেল ঠিক হলেও লিক দেখলেই রিপোর্ট চাই',
    'লিক চলতে থাকলে তেল কমবেই, তাই রিপোর্ট',
    'দেরি করলে তেল নামবে MIN-এর নিচে, তাই রিপোর্ট',
  ];
  static const leakWrong = [
    'লিক দেখে ভাবলাম ইঞ্জিন অয়েল ঢেলে দেব',
    'রিপোর্ট দিলে ডিউটি কম পড়বে, তাই দিলাম',
    'সব ট্রান্সফরমারেই রিপোর্ট দিই, দেখি না',
    'লিক মানেই ট্রান্সফরমার এখনই ফেটে যাবে',
    'অল্প লিক, নিজেই চালু অবস্থায় তেল দেব',
    'লাইনের লোকেরা বলেছে, তাই রিপোর্ট দিলাম',
    'তেল MIN ছুঁলেই ট্যাংক ফাটবে, তাই রিপোর্ট',
    'লেভেল ঠিক আছে, তবু অভ্যাসে রিপোর্ট দিলাম',
  ];
  static const topupRight = [
    'বন্ধ, ডেড প্রমাণ, আর্থ — তারপর তেল ঢেলেছি',
    'একই গ্রেডের ফিল্টার করা নতুন তেলেই টপ-আপ',
    'MIN-এর নিচে তেল মানে ওয়াইন্ডিং পুড়তে পারে',
  ];
  static const topupWrong = [
    'তেল তো তেলই, ইঞ্জিন অয়েলেও কাজ চলত',
    'চালু অবস্থায় ঢাললেও কিছু হতো না আসলে',
    'পুরোনো তেল ছেঁকে দিলেও একই কাজ হতো',
    'বৃষ্টির জল একটু মিশলে তেলের ক্ষতি নেই',
    'সুপারভাইজার দেখছিলেন, তাই নিয়ম মানলাম',
    'ওপরে উঠে কাজ করতে ভালো লাগে, তাই উঠলাম',
    'MIN-এর নিচে নামলেও ক্ষতি নেই, তবু ঢাললাম',
    'বন্ধ করলেই হলো, ডেড প্রমাণ-আর্থ লাগে না',
    'গ্রেড যা-ই হোক, নতুন তেল হলেই টপ-আপ চলে',
    'ফিল্টার করা তেল দামি, খোলা ড্রামেরটাই চলে',
    'ওয়াইন্ডিং ডুবে না থাকলেও চলে, তবু ঢাললাম',
    'অন্য গ্রেডের তেল মেশালেও কোনো ক্ষতি নেই',
  ];

  static List<String> whyRight(M4OilLevelCase c) => switch (c.kind) {
        M4OilLevelKind.fine => switch (c.weather) {
            M4OilLevelWeather.winter => fineWinter,
            M4OilLevelWeather.summer => fineSummer,
            M4OilLevelWeather.mild => fineMild,
          },
        M4OilLevelKind.leak => leakRight,
        M4OilLevelKind.low => topupRight,
      };
  static List<String> whyWrong(M4OilLevelCase c) => switch (c.kind) {
        M4OilLevelKind.fine => fineWrong,
        M4OilLevelKind.leak => leakWrong,
        M4OilLevelKind.low => topupWrong,
      };
  static String whyAsk(M4OilLevelCase c) => switch (c.kind) {
        M4OilLevelKind.fine => whyOk,
        M4OilLevelKind.leak => whyReport,
        M4OilLevelKind.low => whyTopup,
      };

  /// The careless coworker: a little oil, live — why bother with a shutdown.
  static const coworker = CoworkerScript(
    line: 'চালু অবস্থায় একটু তেল ঢেলে দাও! শাটডাউনের ঝামেলা কেন?',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, আগে শাটডাউন-টেস্ট-আর্থ, তারপর তেল', 'না, চালু ট্রান্সফরমারে কেউ উঠবে না', 'না, বন্ধ না করে টপ-আপ একদম হবে না'],
    wrong: [
      'ঠিক, একটু তেল ঢালতে বন্ধের দরকার নেই',
      'আচ্ছা, তাড়াতাড়ি উঠে ঢেলে দিই এখনই',
      'হ্যাঁ, গ্লাভস আছে, চালুতেই ঢেলে দেব',
      'ঠিক আছে, এক মিনিটের কাজ, উঠে পড়ি',
      'হ্যাঁ, শাটডাউন নিলে লোকে রাগ করবে',
    ],
    asks: ['ও বলছে চালু অবস্থায় উঠতে। আপনি কী করবেন?', 'চালু ট্রান্সফরমারে উঠবেন?', 'শাটডাউন ছাড়া টপ-আপ করবেন?'],
  );

  static const callHeld = 'ঠিক! চালু ট্রান্সফরমারে ওঠা মানে মৃত্যু।';
  static const allSet = 'তেলের মাপ শিখে গেছেন — গেজ, তাপমাত্রা, লিক আর নিরাপদ টপ-আপ।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — গেজ পড়ুন, লিক খুঁজুন, বন্ধ করে টপ-আপ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtGauge = 'গেজে তেলের মাপ পড়েছেন';
  static const caughtTemp = 'তাপমাত্রা মিলিয়ে লেভেল বুঝেছেন';
  static const caughtLeak = 'লিক খুঁজে রিপোর্ট';
  static const caughtSafe = 'বন্ধ, টেস্ট, আর্থ — তারপর ওঠা';
  static const caughtOil = 'ঠিক তেল বেছেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M4OilLevelMistakes {
  static const _dir = 'assets/game/art/m4_oil_level';
  static const _k = '4.5/m4_oil_level';

  static const noGauge = DoMistake(
    key: '$_k/no-gauge',
    textBn: 'গেজ না দেখেই রায় দিলেন। কনজারভেটরের কাঁচের গেজে Min-Max আর দাগ দেখুন — নিচে দাঁড়িয়েই দেখা যায়, লাইন বন্ধ লাগে না।',
    art: '$_dir/no_gauge.svg',
    lessonPoint: 0,
  );
  static const missedLow = DoMistake(
    key: '$_k/missed-low',
    textBn: 'তেল MIN দাগের নিচে ছিল! ওয়াইন্ডিং তেলের বাইরে এলে কুলিং আর ইনসুলেশন দুটোই যায় — ট্রান্সফরমার পুড়তে পারে। এখনই রিপোর্ট।',
    art: '$_dir/missed_low.svg',
    lessonPoint: 0,
  );
  static const missedLeak = DoMistake(
    key: '$_k/missed-leak',
    textBn: 'তেল লিক ধরা পড়েনি। বুশিং-এর গ্যাসকেট, ওয়েল্ডিং জয়েন্ট, ড্রেন কক, কুলিং ফিন — লিক খুঁজে সঙ্গে সঙ্গে রিপোর্ট করুন।',
    art: '$_dir/missed_leak.svg',
    lessonPoint: 2,
  );
  static const misreadCold = DoMistake(
    key: '$_k/misread-cold',
    textBn: 'শীতে তেল সংকুচিত হয়, লেভেল দাগের একটু নিচে নামে। MIN-এর ওপরে আর লিক না থাকলে ওটা ঠিক আছে।',
    art: '$_dir/misread_cold.svg',
    lessonPoint: 0,
  );
  static const misreadHot = DoMistake(
    key: '$_k/misread-hot',
    textBn: 'গরমে তেল প্রসারিত হয়, লেভেল দাগের একটু ওপরে ওঠে। MAX-এর নিচে আর লিক না থাকলে ওটা ঠিক আছে।',
    art: '$_dir/misread_hot.svg',
    lessonPoint: 0,
  );
  static const falseReport = DoMistake(
    key: '$_k/false-report',
    textBn: 'তেল দাগের কাছেই, কোথাও লিক নেই — ট্রান্সফরমার ঠিক আছে। খাতায় লিখে পরের ট্রান্সফরমারে চলুন।',
    art: '$_dir/false_report.svg',
    lessonPoint: 0,
  );

  /// Pro tip 1 and the brief's safety rules (no lesson point: "পাঠে দেখুন"
  /// is not offered).
  static const climbLive = DoMistake(
    key: '$_k/climb-live',
    textBn: 'চালু ট্রান্সফরমারে উঠলেন! টপ-আপের আগে ট্রান্সফরমার বন্ধ — শাটডাউন, টেস্টে ডেড প্রমাণ, আর্থ, তারপর ওঠা।',
    art: '$_dir/climb_live.svg',
    deadly: true,
  );
  static const earthLive = DoMistake(
    key: '$_k/earth-live',
    textBn: 'লাইন চালু থাকতেই আর্থ লাগালেন! আগে শাটডাউন, টেস্টে ডেড প্রমাণ — তবেই আর্থ।',
    art: '$_dir/earth_live.svg',
    deadly: true,
  );
  static const earthUntested = DoMistake(
    key: '$_k/earth-untested',
    textBn: 'টেস্টে ডেড প্রমাণের আগেই আর্থ দিলেন। শাটডাউনের পরেও আগে টেস্টার, তারপর আর্থ।',
    art: '$_dir/earth_untested.svg',
  );
  static const climbUnproven = DoMistake(
    key: '$_k/climb-unproven',
    textBn: 'শাটডাউন হয়েছে, কিন্তু টেস্ট আর আর্থ ছাড়াই উঠলেন। ডেড প্রমাণ আর আর্থ দিয়ে তবেই ওঠা।',
    art: '$_dir/climb_unproven.svg',
  );
  static const engineOil = DoMistake(
    key: '$_k/engine-oil',
    textBn: 'ইঞ্জিন অয়েল! ট্রান্সফরমারে শুধু ট্রান্সফরমার অয়েল — বিশেষ মিনারেল অয়েল। অন্য তেলে ট্রান্সফরমার নষ্ট হয়, আগুনও লাগতে পারে।',
    art: '$_dir/engine_oil.svg',
  );
  static const usedOil = DoMistake(
    key: '$_k/used-oil',
    textBn: 'পুরোনো কালো তেল! টপ-আপে লাগে একই গ্রেডের, ফিল্টার করা নতুন তেল।',
    art: '$_dir/used_oil.svg',
  );
  static const wetOil = DoMistake(
    key: '$_k/wet-oil',
    textBn: 'ঢাকনা খোলা ড্রামে বৃষ্টির জল ঢুকেছে — আর্দ্র তেল। ভুল বা আর্দ্র তেলে ট্রান্সফরমারের ক্ষতি হয়।',
    art: '$_dir/wet_oil.svg',
  );

  static DoMistake misread(M4OilLevelWeather w) => switch (w) {
        M4OilLevelWeather.winter => misreadCold,
        M4OilLevelWeather.summer => misreadHot,
        M4OilLevelWeather.mild => falseReport,
      };

  static DoMistake? drum(M4OilLevelDrum d) => switch (d) {
        M4OilLevelDrum.fresh => null,
        M4OilLevelDrum.engine => engineOil,
        M4OilLevelDrum.used => usedOil,
        M4OilLevelDrum.wet => wetOil,
      };

  static List<DoMistake> get all => [
        noGauge,
        missedLow,
        missedLeak,
        misreadCold,
        misreadHot,
        falseReport,
        climbLive,
        earthLive,
        earthUntested,
        climbUnproven,
        engineOil,
        usedOil,
        wetOil,
      ];
}

@immutable
class M4OilLevelDeal {
  const M4OilLevelDeal({required this.cases, required this.drums});
  final List<M4OilLevelCase> cases;

  /// The drums on the ground, left to right.
  final List<M4OilLevelDrum> drums;

  /// The round of the top-up (the careless coworker comes on it).
  int get callAt => cases.indexWhere((c) => c.low);
}

/// The oil in the glass for a fine level in this weather.
double _fineLevel(M4OilLevelWeather w, math.Random rng) => switch (w) {
      M4OilLevelWeather.summer => 0.60 + rng.nextDouble() * 0.10,
      M4OilLevelWeather.winter => 0.30 + rng.nextDouble() * 0.10,
      M4OilLevelWeather.mild => 0.46 + rng.nextDouble() * 0.08,
    };

/// Three transformers: fine, leaking (level still fine) and low, in a fresh
/// order, each in a different weather; two different leak spots.
M4OilLevelDeal dealM4OilLevel(math.Random rng) {
  final kinds = [...M4OilLevelKind.values]..shuffle(rng);
  final weathers = [...M4OilLevelWeather.values]..shuffle(rng);
  final spots = [...M4OilLevelSpot.values]..shuffle(rng);
  final nos = <int>{};
  while (nos.length < 3) {
    nos.add(3 + rng.nextInt(46));
  }
  final no = nos.toList();
  var s = 0;
  final cases = <M4OilLevelCase>[
    for (var i = 0; i < 3; i++)
      M4OilLevelCase(
        id: 'o$i',
        dtrNo: no[i],
        kind: kinds[i],
        weather: weathers[i],
        level: kinds[i] == M4OilLevelKind.low ? 0.07 + rng.nextDouble() * 0.07 : _fineLevel(weathers[i], rng),
        leak: kinds[i] == M4OilLevelKind.fine ? null : spots[s++],
      ),
  ];
  return M4OilLevelDeal(cases: cases, drums: [...M4OilLevelDrum.values]..shuffle(rng));
}

/// The play state (pure logic).
class M4OilLevelRun {
  M4OilLevelRun(this.deal) {
    _startRound();
  }

  final M4OilLevelDeal deal;
  int index = 0;
  var phase = M4OilLevelPhase.inspect;
  var gaugeRead = false;
  final Set<M4OilLevelSpot> looked = {};
  var leakFound = false;

  // The top-up.
  var isolated = false;
  var tested = false;
  var earthed = false;
  var climbed = false;
  M4OilLevelDrum? oil;
  final Set<M4OilLevelDrum> rejected = {};
  var filled = false;

  var shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  M4OilLevelCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;
  bool get _inspect => _open && phase == M4OilLevelPhase.inspect;
  bool get _topup => _open && phase == M4OilLevelPhase.topup;
  bool get canPour => _topup && climbed && oil != null && !filled;

  /// The +5: every part of the tank looked at.
  bool get thorough => looked.length == M4OilLevelSpot.values.length;

  void _startRound() {
    phase = M4OilLevelPhase.inspect;
    gaugeRead = false;
    looked.clear();
    leakFound = false;
    isolated = false;
    tested = false;
    earthed = false;
    climbed = false;
    oil = null;
    rejected.clear();
    filled = false;
    shown = false;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Look at the gauge (from below).
  bool readGauge() {
    if (!_inspect) return false;
    gaugeRead = true;
    return true;
  }

  /// Look at a part of the tank: true = it leaks; null = not now.
  bool? look(M4OilLevelSpot s) {
    if (!_inspect) return null;
    looked.add(s);
    final hit = current.leak == s;
    if (hit) leakFound = true;
    return hit;
  }

  /// The verdict. A report on low oil goes on to the top-up ([phase]);
  /// everything else ends the inspection ([shown]).
  DoMistake? decide({required bool report}) {
    if (!_inspect) return null;
    final c = current;
    if (!gaugeRead) {
      shown = true;
      slips++;
      return M4OilLevelMistakes.noGauge;
    }
    if (!report) {
      shown = true;
      if (c.low) {
        slips++;
        return M4OilLevelMistakes.missedLow;
      }
      if (c.kind == M4OilLevelKind.leak) {
        slips++;
        return M4OilLevelMistakes.missedLeak;
      }
      _tag(M4OilLevelLines.caughtGauge);
      if (c.weather != M4OilLevelWeather.mild) _tag(M4OilLevelLines.caughtTemp);
      return null;
    }
    switch (c.kind) {
      case M4OilLevelKind.fine:
        shown = true;
        slips++;
        return M4OilLevelMistakes.misread(c.weather);
      case M4OilLevelKind.leak:
        shown = true;
        if (!leakFound) {
          slips++;
          return M4OilLevelMistakes.missedLeak;
        }
        _tag(M4OilLevelLines.caughtLeak);
        return null;
      case M4OilLevelKind.low:
        phase = M4OilLevelPhase.topup;
        _tag(M4OilLevelLines.caughtGauge);
        if (!leakFound) {
          slips++;
          return M4OilLevelMistakes.missedLeak;
        }
        _tag(M4OilLevelLines.caughtLeak);
        return null;
    }
  }

  /// A top-up step. For [M4OilLevelStep.test] the result is in [lastTestLive].
  DoMistake? step(M4OilLevelStep s) {
    if (!_topup) return null;
    switch (s) {
      case M4OilLevelStep.shutdown:
        isolated = true;
        return null;
      case M4OilLevelStep.test:
        lastTestLive = !isolated;
        if (isolated) tested = true;
        return null;
      case M4OilLevelStep.earth:
        if (!isolated) return deadly = M4OilLevelMistakes.earthLive;
        if (!tested) {
          slips++;
          return M4OilLevelMistakes.earthUntested;
        }
        earthed = true;
        return null;
      case M4OilLevelStep.climb:
        if (!isolated) return deadly = M4OilLevelMistakes.climbLive;
        if (!tested || !earthed) {
          slips++;
          return M4OilLevelMistakes.climbUnproven;
        }
        climbed = true;
        _tag(M4OilLevelLines.caughtSafe);
        return null;
    }
  }

  /// The tester's last reading (true = LIVE).
  bool? lastTestLive;

  bool stepDone(M4OilLevelStep s) => switch (s) {
        M4OilLevelStep.shutdown => isolated,
        M4OilLevelStep.test => tested,
        M4OilLevelStep.earth => earthed,
        M4OilLevelStep.climb => climbed,
      };

  /// Take a drum for the top-up.
  DoMistake? pick(M4OilLevelDrum d) {
    if (!_topup || rejected.contains(d) || oil != null) return null;
    final m = M4OilLevelMistakes.drum(d);
    if (m == null) {
      oil = d;
      _tag(M4OilLevelLines.caughtOil);
      return null;
    }
    rejected.add(d);
    slips++;
    return m;
  }

  /// Poured up to the mark: the round is done.
  bool fill() {
    if (!canPour) return false;
    filled = true;
    shown = true;
    return true;
  }

  void next() {
    index++;
    lastTestLive = null;
    if (!done) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A thorough fine
/// round (ms): the gauge 1500 + read 2500, four parts 4 × 1500, the verdict
/// 1500, the reason ~8200 ≈ 19700; the leak round the same; the low round
/// ≈ 19700 − 8200 + the coworker ~9600 + four steps 6000 + a drum 2000 + the
/// pour 2600 + the reason 8200 ≈ 39900. ≈ 79300; 85 % ≈ 68 s.
const kM4OilLevelQuickMs = 68000;

@immutable
class M4OilLevelPack {
  const M4OilLevelPack({required this.id, required this.titleBn, this.quickMs = kM4OilLevelQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m4OilLevelPacks = {
  'do_4_5_a': M4OilLevelPack(id: 'do_4_5_a', titleBn: M4OilLevelLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4OilLevelPage extends StatefulWidget {
  const M4OilLevelPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4OilLevelPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4OilLevelPage> createState() => _M4OilLevelPageState();
}

class _M4OilLevelPageState extends State<M4OilLevelPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _OilRunPage(
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

class _OilRunPage extends ConsumerStatefulWidget {
  const _OilRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4OilLevelPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_OilRunPage> createState() => _OilRunPageState();
}

class _OilRunPageState extends ConsumerState<_OilRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4OilLevelRun _run = M4OilLevelRun(dealM4OilLevel(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  late final AnimationController _pour = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) unawaited(_filled());
    });

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
  String? _stamp;
  var _topupStarted = false;
  var _pouring = false;

  /// The step buttons, left to right: dealt fresh on the top-up, never in the
  /// right order (the row must not give the order away).
  List<M4OilLevelStep> _stepOrder = M4OilLevelStep.values;

  // Gesture hints: the scene's touch layer (design → screen), the buttons.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _okKey = GlobalKey();
  final _reportKey = GlobalKey();
  final _pourKey = GlobalKey();
  final Map<M4OilLevelStep, GlobalKey> _stepKeys = {for (final s in M4OilLevelStep.values) s: GlobalKey()};

  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _zapAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The scene's geometry as last laid out (where the flash goes).
  M4OilLevelGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _pour.dispose();
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

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.shown;
  bool get _topup => _run.phase == M4OilLevelPhase.topup;

  void _startRound() {
    _pour
      ..stop()
      ..value = 0;
    setState(() {
      _stamp = null;
      _topupStarted = false;
      _pouring = false;
      _wake++;
    });
    unawaited(_sayChain([M4OilLevelLines.ask]));
  }

  void _startTopup() {
    if (_topupStarted || _ended) return;
    final order = [...M4OilLevelStep.values];
    do {
      order.shuffle(widget.rng);
    } while (_inRightOrder(order));
    setState(() {
      _stepOrder = order;
      _topupStarted = true;
      _stamp = M4OilLevelLines.stampReport;
      _wake++;
    });
    unawaited(_sayChain([M4OilLevelLines.topupAsk]));
    if (!coworkerDone) scheduleCoworker();
    // The report stamp stays a moment, then the top-up has the scene.
    final idx = _run.index;
    unawaited(Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _run.index == idx && _stamp == M4OilLevelLines.stampReport) setState(() => _stamp = null);
    }));
  }

  static bool _inRightOrder(List<M4OilLevelStep> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != M4OilLevelStep.values[i]) return false;
    }
    return true;
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p, M4OilLevelGeo geo) {
    if (!_canPlay) return;
    if (_topup) {
      if (_run.climbed && _run.oil != null) return;
      for (var i = 0; i < _run.deal.drums.length; i++) {
        if (geo.drumHit(i).contains(p)) {
          _pick(_run.deal.drums[i], p);
          return;
        }
      }
      _hints.missTap();
      return;
    }
    if (geo.gaugeHit.contains(p)) {
      if (_run.readGauge()) {
        HapticFeedback.selectionClick();
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        setState(() => _wake++);
      }
      return;
    }
    M4OilLevelSpot? best;
    var bestD = double.infinity;
    for (final s in M4OilLevelSpot.values) {
      if (!geo.spotHit(s).contains(p)) continue;
      final d = (geo.spot(s) - p).distance;
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    if (best == null) {
      _hints.missTap();
      return;
    }
    // The same tick for a leaking part and a sound one: the oil streak is
    // the evidence, not the sound.
    if (_run.look(best) == null) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    setState(() => _wake++);
  }

  void _pick(M4OilLevelDrum d, Offset at) {
    if (_run.oil != null || _run.rejected.contains(d)) return;
    final m = _run.pick(d);
    if (m == null) {
      HapticFeedback.selectionClick();
      _cue('sounds/intro/click.ogg', volume: 0.5);
      setState(() => _wake++);
      return;
    }
    unawaited(_levelDelta(-10, at, mood: GuideMood.warn));
    unawaited(_slip(m));
  }

  Future<void> _step(M4OilLevelStep s, Offset origin, {bool force = false}) async {
    if (!force && (!_canPlay || !_topup || _run.stepDone(s))) return;
    // Any step before he came (the shutdown ends his moment; a climb or an
    // earth on the live line would skip him): he cuts in now.
    if (!force && holdForCoworker()) return;
    final m = _run.step(s);
    if (m == null) {
      HapticFeedback.selectionClick();
      switch (s) {
        case M4OilLevelStep.test:
          final live = _run.lastTestLive ?? false;
          _cue(live ? 'sounds/learn/spark.ogg' : 'sounds/intro/click.ogg', volume: 0.5);
          if (live) HapticFeedback.mediumImpact();
        case M4OilLevelStep.shutdown:
          _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
        case M4OilLevelStep.earth || M4OilLevelStep.climb:
          _cue('sounds/intro/click.ogg', volume: 0.5);
      }
      setState(() => _wake++);
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _pourDown() {
    if (!_canPlay || !_run.canPour) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() => _pouring = true);
    _pour.duration = Duration(milliseconds: _quiet ? 400 : 2600);
    unawaited(_pour.forward());
  }

  void _pourUp() {
    if (!_pouring) return;
    _pour.stop();
    if (mounted) setState(() => _pouring = false);
  }

  Future<void> _filled() async {
    if (!mounted || !_run.fill()) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() {
      _pouring = false;
      _stamp = M4OilLevelLines.stampFilled;
      _wake++;
    });
    _askWhy();
  }

  void _askWhy() {
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final c = _run.current;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M4OilLevelLines.whyRight(c), M4OilLevelLines.whyWrong(c), widget.rng),
      question: M4OilLevelLines.whyAsk(c),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  // --- the verdict ----------------------------------------------------------------
  Future<void> _decide(bool report, Offset origin) async {
    if (!_canPlay || _topup) return;
    _hush();
    final m = _run.decide(report: report);
    if (m == null && _topup) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
      _startTopup();
      return;
    }
    if (m == null) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
      _cue('sounds/quiz_right.ogg', volume: 0.6);
      setState(() {
        _stamp = report ? M4OilLevelLines.stampReport : M4OilLevelLines.stampOk;
        _wake++;
      });
      _askWhy();
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
  CoworkerScript get coworkerScript => M4OilLevelLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("live, no shutdown") makes sense only before the shutdown.
    if (_ended || !_topup || _run.isolated || _run.shown) return null;
    if (tableBusy || _intro || _busy || _card != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up the live transformer with a can of oil. Deadly,
      // not the playbook's slip: climbing the live transformer is this
      // level's own deadly move (MODULE4_LADDER step 14) — owner to confirm.
      await _step(M4OilLevelStep.climb, origin, force: true);
      return;
    }
    if (!_run.caught.contains(M4OilLevelLines.caughtCall)) _run.caught.add(M4OilLevelLines.caughtCall);
    if (mounted) setState(() {});
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4OilLevelLines.callHeld]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4OilLevelLines.tapWhy[_nudgeN++ % M4OilLevelLines.tapWhy.length]
            : _nudge.next(_topup ? M4OilLevelLines.topupTask : M4OilLevelLines.ask);
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
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('oil/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up the live transformer (or the earth on a live line): the site freezes
  /// grey and the flash shows in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    final geo = _geo ?? M4OilLevelGeo.forScene(560, 0);
    setState(() {
      _freeze = true;
      _zapAt = m == M4OilLevelMistakes.earthLive
          ? Offset(geo.doX(1), geo.doTopY + geo.doLen + 22)
          : Offset(geo.bushX(0) - 4, geo.bushTop + 4);
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
    final speak = await SpokenOnce.first('oil/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4OilLevelLines.deadlyWord : M4OilLevelLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        if (_run.shown) {
          _next();
        } else if (_topup) {
          _startTopup();
        }
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        if (_popped) return;
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
    await _say(!_run.passed ? M4OilLevelLines.fail : (_quickBonus ? M4OilLevelLines.quick : M4OilLevelLines.allSet),
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
    if (_stamp != null && _run.shown) return LinemanMode.cheer;
    if (_run.climbed || _freeze) return LinemanMode.hold;
    return _topup ? LinemanMode.idle : LinemanMode.point;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M4OilLevelGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final up = _run.climbed || (_freeze && _zapAt != null && _run.deadly == M4OilLevelMistakes.climbLive);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M4OilLevelWorldPainter(
                      geo: geo,
                      weather: c.weather,
                      leak: c.leak,
                      looked: {..._run.looked},
                      gaugeLit: _run.gaugeRead && !_topup,
                      doOpen: _run.isolated,
                      earthed: _run.earthed,
                      climbed: up,
                      drums: _topup ? _run.deal.drums : null,
                      rejected: {..._run.rejected},
                      picked: _run.oil,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: up ? geo.traineeUp : geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (_stamp != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}-$_stamp'),
          left: 18,
          width: 170,
          top: geo.platformY - 40,
          child: IgnorePointer(child: _StampPop(text: _stamp!, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4OilLevelLines.sceneLabel,
          child: GestureDetector(key: _touchKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze && _zapAt != null)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4OilLevelZapPainter(at: _zapAt!, v: v)),
            ),
          ),
        ),
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
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

  // --- gesture hints -----------------------------------------------------------
  /// A scene rect (design px) on the screen, through the touch layer.
  Rect? _sceneRect(Rect r) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// How to interact now, never what is right: the inspection sweeps over the
  /// gauge, the tank's parts and both verdicts; the top-up over the steps
  /// left and the drums; the pour (the one way on) is a hold.
  HintSpec? _hint() {
    final geo = _geo;
    if (geo == null) return null;
    final List<Rect> options;
    if (!_topup) {
      options = [
        ?_sceneRect(geo.gaugeHit),
        for (final s in M4OilLevelSpot.values) ?_sceneRect(geo.spotHit(s)),
        ?HintSpec.globalRectOf(_okKey),
        ?HintSpec.globalRectOf(_reportKey),
      ];
    } else if (_run.canPour) {
      return HintSpec.holdOn(_pourKey);
    } else {
      options = [
        for (final s in _stepOrder)
          if (!_run.stepDone(s)) ?HintSpec.globalRectOf(_stepKeys[s]!),
        if (_run.oil == null)
          for (var i = 0; i < _run.deal.drums.length; i++)
            if (!_run.rejected.contains(_run.deal.drums[i])) ?_sceneRect(geo.drum(i)),
      ];
    }
    return options.isEmpty ? null : HintSpec.sweep(options);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && !tableBusy;
    final topup = _topup && _topupStarted;
    final c = _run.current;
    final cardBottom = pad.bottom + (topup ? 96 : 76);
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
              labels: M4OilLevelLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !_pouring && (!_topup || topup),
            hintKey: '${_run.index}-${_run.phase.name}-${_run.canPour}-${_run.oil != null}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(dtr: c.dtrNo, weather: c.weather)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !_run.done && !deckUp && _run.gaugeRead)
                Positioned(
                  key: const ValueKey('hud-gauge'),
                  left: 10,
                  bottom: cardBottom,
                  child: IgnorePointer(child: _GaugeCard(from: c.level, to: c.low ? kM4OilLevelMark : c.level, pour: _pour, quiet: quiet)),
                ),
              if (playing && topup && !deckUp && _run.lastTestLive != null)
                Positioned(
                  key: const ValueKey('hud-tester'),
                  left: 136,
                  bottom: cardBottom,
                  child: IgnorePointer(child: _TesterChip(live: _run.lastTestLive!)),
                ),
              if (handsOn && !_topup)
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(child: DoBigButton(key: _okKey, label: M4OilLevelLines.ok, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(key: _reportKey, label: M4OilLevelLines.report, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                    ],
                  ),
                ),
              if (handsOn && topup && !_run.canPour)
                Positioned(
                  key: const ValueKey('hud-steps'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final s in _stepOrder)
                        _ToolButton(
                          key: ValueKey('step-${s.name}'),
                          hintKey: _stepKeys[s]!,
                          icon: switch (s) {
                            M4OilLevelStep.shutdown => Icons.power_settings_new_rounded,
                            M4OilLevelStep.test => Icons.bolt_rounded,
                            M4OilLevelStep.earth => Icons.vertical_align_bottom_rounded,
                            M4OilLevelStep.climb => Icons.stairs_rounded,
                          },
                          label: M4OilLevelLines.stepBn(s),
                          done: _run.stepDone(s),
                          enabled: _canPlay && !_run.stepDone(s),
                          onTapUp: (d) => unawaited(_step(s, d.globalPosition)),
                        ),
                    ],
                  ),
                ),
              if ((handsOn || _pouring) && topup && _run.canPour)
                Positioned(
                  key: const ValueKey('hud-pour'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: KeyedSubtree(key: _pourKey, child: _HoldButton(label: M4OilLevelLines.pour, progress: _pour, onDown: _pourDown, onUp: _pourUp)),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (topup ? 92 : 72)), onLeft: coworkerFromRight),
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
                  sound: FailSound.electric,
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
                  line: M4OilLevelLines.intro,
                  alarm: 'sounds/learn/tag_slap.ogg',
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

/// The inspection slip: the transformer, the date and the hour.
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.dtr, required this.weather});
  final int dtr;
  final M4OilLevelWeather weather;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('${M4OilLevelLines.docket} · ${M4OilLevelLines.dtr(dtr)}', style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4OilLevelLines.when(weather), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// The gauge, close up (what he reads from below).
class _GaugeCard extends StatelessWidget {
  const _GaugeCard({required this.from, required this.to, required this.pour, required this.quiet});
  final double from;
  final double to;
  final Animation<double> pour;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 40 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 5))],
        ),
        child: SizedBox(
          key: const ValueKey('gauge-card'),
          width: 118,
          height: 156,
          child: RepaintBoundary(child: CustomPaint(painter: M4OilLevelGaugePainter(from: from, to: to, pour: pour))),
        ),
      ),
    );
  }
}

/// The HT tester's lamp: LIVE (red) or DEAD (green).
class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) {
    final col = live ? const Color(0xFFE23B2E) : SlmColors.success;
    return Container(
      key: const ValueKey('tester'),
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2126),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF2C230), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle, color: col, boxShadow: [BoxShadow(color: col.withValues(alpha: 0.7), blurRadius: 8)]),
          ),
          const SizedBox(width: 6),
          Text(live ? M4OilLevelLines.live : M4OilLevelLines.dead, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: col)),
        ],
      ),
    );
  }
}

/// A hands-on step: a round icon with its name under it; a tick once done.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.hintKey, required this.icon, required this.label, required this.enabled, required this.done, required this.onTapUp});

  /// Where the gesture hint finds the button's round.
  final GlobalKey hintKey;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool done;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = done ? SlmColors.success : (enabled ? SlmColors.gold300 : const Color(0xFF6B7380));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? onTapUp : null,
        child: SizedBox(
          key: hintKey,
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.8),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(done ? Icons.check_rounded : icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 1, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hold to pour: the bar fills as the oil goes in.
class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.label, required this.progress, required this.onDown, required this.onUp});
  final String label;
  final Animation<double> progress;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: SlmColors.gold700),
                AnimatedBuilder(
                  animation: progress,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.value.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0x55FFFFFF)),
                  ),
                ),
                Center(child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
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
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
