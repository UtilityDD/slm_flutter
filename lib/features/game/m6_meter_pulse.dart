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
import 'm6_meter_pulse_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_meter_pulse_world.dart' show M6PulseAppliance, M6PulseGeo, M6PulseLed, M6PulsePlace, kM6PulseCamMax, m6PulseLcd;

// Lesson 6.10 "এনার্জি মিটার: ক্যাশ রেজিস্টার", কাজ 1 "মিটারের নাড়ি"
// (pack do_6_10_a, engineType m6_meter_pulse). An evening of three house
// calls (lesson point 3, the three complaints), dealt fresh:
//
//  'মিটার দ্রুত চলছে' (1–2 calls, at least one with a steady LED): the
//    house is a cut-away wider than the screen, panned by a swipe; five rooms
//    (fan, tube light, TV, an old fridge behind a curtain, the yard pump),
//    3–5 of them running, one running room out of the first view. Each room
//    has its own wall switch: tap it ON/OFF. No load counter — only the real
//    cues (the fan's blur, the tube's glow, the TV's screen, the fridge's door
//    lamp, the pump's water, the switch's pilot lamp). Then 'মিটারে যাই': the
//    CAL LED is watched for the same 6 s window whatever it does (input
//    locked; never captioned), then the verdict deck:
//      a load still on → every verdict is a slip ('verdict while a load
//        runs') and the player goes back into the house;
//      'মিটারই খারাপ' before the lesson's checks = slip;
//      a wrong LED reading = slip;
//      blinking with every load off → leak ◆ → reason → 'গ্রাহককে বোঝাই'
//        (pro tip 1: explain his own appliances);
//      steady → the known-load test: drag the 100 W bulb's plug into the
//        socket (the coworker comes here once a play, before the clock), turn
//        the clock's minute hand (a circular drag, no target arc) and tap
//        'রিডিং দেখি': under a full hour = slip (the test goes on). The LCD's
//        kWh has risen; judge deck 'ঠিকমতো বেড়েছে' vs wrongs ◆ → reason.
//        (The lesson gives no rise size or a 'bad rise' action: the test
//        always ends 'ঠিক' — owner question.)
//  'মিটার চলছে না' (blank display): drag the tester onto the incoming
//    terminals — its lamp lights or not — then tap the fault place (meter,
//    service cable, pole top; two-step preview): lit → inside the meter;
//    dark → the service cable or the pole connection. A wrong place = slip;
//    a place before the test costs nothing (the guide says measure first).
//  'পাওয়ার নেই, কিন্তু মিটার ON' (the house dark, the LCD on): the deck,
//    'নিউট্রাল কেটে গেছে' vs wrongs; not the neutral = slip.
//
// No deadly act in this level (spec: "do_6_10_a has no deadly"; listening to
// the coworker = slip, ruling X2/B1, since what he pushes — ending the
// known-load test early or calling the meter bad without it — is a slip).
// Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_meter_pulse_world.dart), corner guide, a right call puts ◆
// on the table → "কেন …?" → the next call; the coworker on the first steady
// call once the bulb is plugged in (the clock and 'রিডিং দেখি' wait for him:
// holdForCoworker). Gesture hands: a swipe and a sweep over every switch on
// screen (on and off alike) in the house, never a tap on 'মিটারে যাই'; none
// during the LED window; a short generic nudge on the bulb and the tester; a
// short arc on the clock's minute hand; a sweep over the meter, the cable
// and the pole top; a tap on 'গ্রাহককে বোঝাই' (the one way on). Decks have
// their own sweep.

// ============================================================================
// Content
// ============================================================================

/// The three complaints (lesson 6.10 point 3).
enum M6PulseCallKind { fast, blank, dark }

/// Where a call stands.
enum M6PulseStage { hunt, watch, verdict, plug, clock, judge, test, place, neutral, explain }

/// The three verdicts after the LED window.
enum M6PulseVerdict { leak, steady, bad }

/// The coworker's push (one per play, on a steady call, before the clock).
enum M6PulsePush { five, skip }

/// What a call's reason asks about.
enum M6PulseWhy { loadsOff, blink, fullHour, incoming, neutral }

/// The known load runs this many game minutes (lesson: 'এক ঘণ্টা').
const double kM6PulseHour = 60;

/// The clock's hand turns at most this far (game minutes).
const double kM6PulseMaxMinutes = 240;

/// The LED window (the same for every truth).
const int kM6PulseLedMs = 6000;

abstract final class M6MeterPulseLines {
  static const title = 'মিটারের নাড়ি';
  // DRAFT wording — owner (M6-12).
  static const intro = 'গ্রাহক বলছেন মিটার দ্রুত চলছে — নিজে মেপে দেখুন!';

  // Each call opens with the customer's complaint (read by the guide).
  static const complaints = <M6PulseCallKind, List<String>>{
    M6PulseCallKind.fast: ['গ্রাহক বলছেন, মিটার খুব জোরে চলছে।', 'এ বাড়িতেও অভিযোগ — বিল নাকি বেশি আসছে।'],
    M6PulseCallKind.blank: ['গ্রাহক বলছেন, মিটার চলছে না।', 'এ বাড়ির মিটার নাকি বন্ধ হয়ে আছে।'],
    M6PulseCallKind.dark: ['গ্রাহক বলছেন, বাড়িতে কারেন্ট নেই।', 'এ বাড়িতে নাকি একটা আলোও জ্বলছে না।'],
  };

  // The guide's task now (tap him: the same task, a different way).
  static const askHunt = 'নিজে মেপে দেখুন — আগে বাড়িটা ঘুরে নিন, তারপর মিটারে।';
  static const askHuntOther = 'বাড়িটা একবার দেখে মিটারের কাছে যান।';
  static const askWatch = 'CAL LED-টা মন দিয়ে দেখুন।';
  static const askVerdict = 'বাতি কী বলছে?';
  static const steadyOk = 'ঠিক ধরেছেন।';
  static const askPlug = 'বাল্বের প্লাগটা সকেটে লাগান।';
  static const askClock = 'ঘড়ির কাঁটা ঘুরিয়ে সময় পার করুন, তারপর রিডিং দেখুন।';
  static const askJudge = 'রিডিং কেমন বেড়েছে?';
  static const askTest = 'মিটার চলছে না — দোষটা খুঁজে বের করুন।';
  static const testFirst = 'আগে মেপে দেখুন, তারপর বলুন।';
  static const askPlace = 'টেস্টার কী বলল? দোষ কোথায়, দেখান।';
  static const askNeutral = 'মিটারটা দেখুন — কী হয়েছে?';
  static const askExplain = 'এবার গ্রাহককে বুঝিয়ে বলুন।';
  static const explainLine = 'পুরোনো ফ্রিজ, জলের পাম্প — নিজের যন্ত্রের খরচ বুঝলে গ্রাহক নিজেই বোঝেন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askHunt, askHuntOther, askWatch, askVerdict, askPlug, askClock, askJudge, askTest, askPlace, askNeutral, askExplain];

  // On-screen buttons (a worker's own words; not spoken).
  static const goMeter = 'মিটারে যাই';
  static const goHome = 'ঘরে ফিরি';
  static const readNow = 'রিডিং দেখি';
  static const explain = 'গ্রাহককে বোঝাই';
  static const houseLabel = 'গ্রাহকের বাড়ি';
  static const verandaLabel = 'বারান্দার মিটার';
  static String callName(int n) => enDigits('কল $n');
  static String switchName(M6PulseAppliance a) => switch (a) {
        M6PulseAppliance.fan => 'পাখার সুইচ',
        M6PulseAppliance.tube => 'টিউবলাইটের সুইচ',
        M6PulseAppliance.tv => 'টিভির সুইচ',
        M6PulseAppliance.fridge => 'ফ্রিজের সুইচ',
        M6PulseAppliance.pump => 'পাম্পের সুইচ',
      };

  /// The fault places (a two-step pick; alike in length).
  static String place(M6PulsePlace p) => switch (p) {
        M6PulsePlace.meter => 'মিটারের ভেতরের দোষ',
        M6PulsePlace.cable => 'সার্ভিস কেবিলের দোষ',
        M6PulsePlace.pole => 'পোলের কানেকশনের দোষ',
      };

  /// The verdict deck: one phrasing of each verdict is dealt.
  static const verdicts = <M6PulseVerdict, List<String>>{
    M6PulseVerdict.leak: ['লোড বন্ধেও বাতি চলছে — লিকেজ বা বন্ধ যন্ত্রও টানছে', 'সব বন্ধ, তবু বাতি জ্বলছে-নিভছে — কোথাও লিকেজ'],
    M6PulseVerdict.steady: ['বাতি স্থির — জানা লোডে এক ঘণ্টা পরীক্ষা করি', 'বাতি নড়ছে না — এবার জানা লোডে এক ঘণ্টা মাপি'],
    M6PulseVerdict.bad: ['মিটারই খারাপ — বদলানোর জন্য রিপোর্ট লিখে দিই', 'মিটারটাই গোলমেলে — বদলের রিপোর্ট করে দিই'],
  };

  /// The known-load judgement (after the hour).
  static const judgeRight = ['ঠিকমতো বেড়েছে — মিটার ঠিক, গ্রাহককে বোঝাই', 'রিডিং যতটা বাড়ার বেড়েছে — মিটার ঠিক আছে'];
  static const judgeWrong = [
    'বাড়েনি বলে লিখি — মিটার খারাপের রিপোর্ট',
    'আরও একদিন বাল্ব জ্বালিয়ে রেখে তবে দেখি',
    'মিটার বদলে দিলেই গ্রাহক খুশি হয়ে যাবেন',
    'রিডিং দেখার দরকার নেই, বাল্ব তো জ্বলছে',
    'গ্রাহকের কথাই ঠিক — মিটার সত্যিই জোরে চলছে',
  ];

  /// The dark-house diagnosis.
  static const neutralRight = ['নিউট্রাল তার কেটে গেছে', 'নিউট্রাল তারটা কাটা পড়েছে'];
  static const neutralWrong = [
    'মিটারের ভেতরের ফিউজ গেছে',
    'পোলের ফিউজটা উড়ে গেছে',
    'মিটারটাই খারাপ হয়ে গেছে',
    'সব বাল্ব একসাথে কেটে গেছে',
    'ডিসপ্লে জ্বলছে, লাইন ঠিক',
  ];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M6PulseWhy, String>{
    M6PulseWhy.loadsOff: 'কেন আগে বাড়ির সব লোড বন্ধ করলেন?',
    M6PulseWhy.blink: 'লোড বন্ধেও বাতি জ্বলছে-নিভছে — এর মানে কী?',
    M6PulseWhy.fullHour: 'কেন জানা লোড পুরো এক ঘণ্টা চালালেন?',
    M6PulseWhy.incoming: 'ডিসপ্লে ফাঁকা — কেন আগে ইনকামিংয়ে ভোল্টেজ দেখলেন?',
    M6PulseWhy.neutral: 'মিটার ON, অথচ আলো নেই — কেন নিউট্রাল?',
  };
  static const whyRight = <M6PulseWhy, List<String>>{
    M6PulseWhy.loadsOff: ['লোড চললে বাতি এমনিই ব্লিঙ্ক করে, তাই আগে সব বন্ধ', 'সব বন্ধ থাকলে তবেই বোঝা যায় খরচ কোথা থেকে আসছে'],
    M6PulseWhy.blink: ['আর্থ লিকেজ, বা কোনো যন্ত্র বন্ধেও বিদ্যুৎ টানছে', 'বাড়িতে কোথাও লিকেজ, নয়তো বন্ধ যন্ত্রও টানছে'],
    M6PulseWhy.fullHour: ['জানা লোডে এক ঘণ্টায় রিডিং ঠিক বাড়ছে কি না দেখা যায়', 'পুরো এক ঘণ্টা চালালে তবেই রিডিং মিলিয়ে দেখা যায়'],
    M6PulseWhy.incoming: ['ভোল্টেজ না থাকলে দোষ কেবিল বা পোলের কানেকশনে', 'ভোল্টেজ আছে কি না দেখেই বোঝা যায় দোষ মিটারে কি না'],
    M6PulseWhy.neutral: ['পাওয়ার নেই অথচ মিটার ON — নিউট্রাল কাটার লক্ষণ', 'মিটার চলছে, বাড়িতে আলো নেই — নিউট্রাল কেটে গেছে'],
  };
  static const myths = [
    'মিটারের ওপর চুম্বক রাখলেই মিটার স্লো হয়ে যায়',
    'বৃষ্টি বা ঠান্ডা আবহাওয়ায় মিটার এমনিই স্লো চলে',
    'গ্রাহক অভিযোগ করলে মিটার খারাপ ধরে নেওয়াই ভালো',
    'বাতি ব্লিঙ্ক করা মানেই মিটার নিজেই খারাপ হয়েছে',
    'ডিসপ্লে জ্বললেই বাড়ির সব লাইন পুরো ঠিক আছে',
    'পাঁচ মিনিট দেখলেই মিটারের পুরো হিসাব বোঝা যায়',
    'নতুন মিটার লাগালেই গ্রাহকের সব অভিযোগ মিটে যায়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play, after the bulb is plugged in, before
  // the clock). DRAFT wording — owner (M6-12): the spec's two pushes.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerFive = CoworkerScript(
    line: 'এক ঘণ্টা কে বসে থাকবে? পাঁচ মিনিট দেখেই লিখে দাও মিটার খারাপ!',
    exitLine: coworkerExit,
    right: ['না, পুরো এক ঘণ্টা চালিয়ে রিডিং দেখব', 'না, না মেপে মিটার খারাপ লিখব না', 'না, ঘড়ি পুরো এক পাক ঘুরিয়ে দেখব'],
    wrong: [
      'ঠিক, পাঁচ মিনিট দেখেই লিখে দিই',
      'হ্যাঁ, এক ঘণ্টা বসে থাকার সময় নেই',
      'আচ্ছা, মিটার খারাপ লিখে চলে যাই',
      'ঠিক আছে, পাঁচ মিনিটেই যথেষ্ট',
      'হ্যাঁ, গ্রাহক তো বলছেনই খারাপ',
    ],
    asks: ['কী করবেন?', 'ও বলছে পাঁচ মিনিট দেখেই লিখে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerSkip = CoworkerScript(
    line: 'ঘড়ি ঘোরানোর দরকার নেই, বাল্ব জ্বলছে মানেই মিটার ঠিক — চলো!',
    exitLine: coworkerExit,
    right: ['না, পুরো এক ঘণ্টা চালিয়ে রিডিং দেখব', 'না, রিডিং না দেখে কিছুই বলব না', 'না, ঘড়ি পুরো এক পাক ঘুরিয়ে দেখব'],
    wrong: [
      'ঠিক, বাল্ব জ্বলছে, তাতেই চলবে',
      'আচ্ছা, ঘড়ি ঘোরানোর দরকার নেই',
      'হ্যাঁ, রিডিং না দেখেই সেরে ফেলি',
      'ঠিক আছে, মিটার তো ঠিক, চলো যাই',
      'হ্যাঁ, এক ঘণ্টা কে বসে থাকবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে ঘড়ি না ঘুরিয়েই চলে যেতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6PulsePush p) => switch (p) {
        M6PulsePush.five => coworkerFive,
        M6PulsePush.skip => coworkerSkip,
      };
  static const allCoworkers = [coworkerFive, coworkerSkip];

  static String callHeld(M6PulsePush p) => switch (p) {
        M6PulsePush.five => 'ঠিক! না মেপে মিটার খারাপ বলা চলে না।',
        M6PulsePush.skip => 'ঠিক! বাল্ব জ্বলা আর রিডিং মেলা এক কথা নয়।',
      };

  static const allSet = 'তিন বাড়ির অভিযোগই মেপে দেখেছেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে সব লোড বন্ধ, তারপর বাতি, তারপর পরীক্ষা।';

  // "আজ যা ধরলেন".
  static const caughtLoads = 'সব লোড বন্ধ করে তবে বাতি দেখা';
  static const caughtLeak = 'লোড বন্ধেও বাতি — লিকেজ ধরা';
  static const caughtHour = 'জানা লোডে পুরো এক ঘণ্টা';
  static const caughtIncoming = 'আগে ইনকামিংয়ে ভোল্টেজ';
  static const caughtNeutral = 'মিটার ON, আলো নেই — নিউট্রাল';
  static const caughtExplain = 'গ্রাহককে বুঝিয়ে বলা';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until
  /// then the device voice). Lines the kit already shares are listed too, so
  /// the voice pass finds every line this level speaks; only the kit's own
  /// praise and 'wrong' bags are left out.
  static List<String> get newGuideLines => <String>{
        intro,
        for (final l in complaints.values) ...l,
        ...tasks,
        ...tapWhy,
        steadyOk,
        testFirst,
        explainLine,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks,
        for (final p in M6PulsePush.values) callHeld(p),
        allSet,
        quick,
        fail,
        for (final m in M6MeterPulseMistakes.all) m.textBn,
      }.toList();
}

abstract final class M6MeterPulseMistakes {
  static const _dir = 'assets/game/art/m6_meter_pulse';

  // DRAFT wording — owner (M6-12). Lesson point 3 (index 2) unless noted.
  static const loadOn = DoMistake(
    key: '6.10/m6_meter_pulse/load-on',
    textBn: 'বাড়িতে এখনও যন্ত্র চলছে — তাই বাতি ব্লিঙ্ক করছে। আগে গ্রাহকের বাড়ির সমস্ত লোড বন্ধ করুন, তারপর CAL LED দেখুন।',
    art: '$_dir/load_on.svg',
    lessonPoint: 2,
  );
  static const meterBadEarly = DoMistake(
    key: '6.10/m6_meter_pulse/meter-bad-early',
    textBn: 'পরীক্ষা না করেই মিটার খারাপ বলা চলে না। সব লোড বন্ধে বাতি দেখুন; বাতি স্থির থাকলে জানা লোডে এক ঘণ্টা পরীক্ষা।',
    art: '$_dir/meter_bad.svg',
    lessonPoint: 2,
  );
  static const ledMissedBlink = DoMistake(
    key: '6.10/m6_meter_pulse/led-missed-blink',
    textBn: 'সব লোড বন্ধ, তবু CAL LED খুব দ্রুত ব্লিঙ্ক করছিল — মানে বাড়িতে আর্থ লিকেজ, বা কোনো যন্ত্র বন্ধ অবস্থায়ও বিদ্যুৎ টানছে।',
    art: '$_dir/led.svg',
    lessonPoint: 2,
  );
  static const ledFalseBlink = DoMistake(
    key: '6.10/m6_meter_pulse/led-false-blink',
    textBn: 'CAL LED স্থির ছিল — সব লোড বন্ধে কোনো খরচ নেই, লিকেজও নেই। এবার জানা লোড (100 ওয়াটের বাল্ব) এক ঘণ্টা চালিয়ে দেখুন।',
    art: '$_dir/led.svg',
    lessonPoint: 2,
  );
  static const shortHour = DoMistake(
    key: '6.10/m6_meter_pulse/short-hour',
    textBn: 'এক ঘণ্টা এখনও পুরো হয়নি। জানা লোড (100 ওয়াটের বাল্ব) পুরো এক ঘণ্টা চালিয়ে তবে রিডিং দেখুন।',
    art: '$_dir/hour.svg',
    lessonPoint: 2,
  );
  static const knownWrong = DoMistake(
    key: '6.10/m6_meter_pulse/known-wrong',
    textBn: 'জানা লোডে এক ঘণ্টায় রিডিং ঠিকমতো বেড়েছে — মিটার ঠিক আছে। গ্রাহককে তাঁর নিজের যন্ত্রের খরচ বুঝিয়ে বলুন।',
    art: '$_dir/known.svg',
    lessonPoint: 2,
  );
  static const pushFive = DoMistake(
    key: '6.10/m6_meter_pulse/push-five',
    textBn: 'পাঁচ মিনিট দেখে মিটার খারাপ লেখা চলে না। জানা লোড পুরো এক ঘণ্টা চালিয়ে দেখুন রিডিং ঠিকমতো বাড়ছে কি না।',
    art: '$_dir/hour.svg',
    lessonPoint: 2,
  );
  static const pushSkip = DoMistake(
    key: '6.10/m6_meter_pulse/push-skip',
    textBn: 'বাল্ব জ্বলছে মানেই মিটার ঠিক নয়। জানা লোড পুরো এক ঘণ্টা চালিয়ে দেখুন রিডিং ঠিকমতো বাড়ছে কি না।',
    art: '$_dir/hour.svg',
    lessonPoint: 2,
  );
  static const blankLit = DoMistake(
    key: '6.10/m6_meter_pulse/blank-lit',
    textBn: 'ইনকামিং টার্মিনালে ভোল্টেজ আছে — তাহলে দোষ মিটারের ভেতরের ফিউজ বা সার্কিটে, কেবিল বা পোলে নয়।',
    art: '$_dir/blank_lit.svg',
    lessonPoint: 2,
  );
  static const blankDead = DoMistake(
    key: '6.10/m6_meter_pulse/blank-dead',
    textBn: 'ইনকামিং টার্মিনালে ভোল্টেজ নেই — তাহলে দোষ সার্ভিস কেবিল বা পোলের কানেকশনে, মিটারে নয়।',
    art: '$_dir/blank_dead.svg',
    lessonPoint: 2,
  );
  static const darkNotNeutral = DoMistake(
    key: '6.10/m6_meter_pulse/dark-not-neutral',
    textBn: 'পাওয়ার নেই, কিন্তু মিটার ON — এটা সাধারণত নিউট্রাল কেটে যাওয়ার লক্ষণ।',
    art: '$_dir/neutral.svg',
    lessonPoint: 2,
  );

  /// Listening to his push is the act it pushes (X2/B1): a slip.
  static DoMistake push(M6PulsePush p) => switch (p) {
        M6PulsePush.five => pushFive,
        M6PulsePush.skip => pushSkip,
      };

  static const List<DoMistake> all = [
    loadOn,
    meterBadEarly,
    ledMissedBlink,
    ledFalseBlink,
    shortHour,
    knownWrong,
    pushFive,
    pushSkip,
    blankLit,
    blankDead,
    darkNotNeutral,
  ];
}

/// One house call.
@immutable
class M6PulseCall {
  const M6PulseCall({
    required this.kind,
    required this.rooms,
    required this.switches,
    required this.startHund,
    required this.startMinute,
    this.leak = false,
    this.voltage = false,
    this.complaint = 0,
  });

  final M6PulseCallKind kind;

  /// The appliance in each of the five rooms (the pump always in the yard).
  final List<M6PulseAppliance> rooms;

  /// Each room's switch as found (a fast call: the running loads).
  final List<bool> switches;

  /// The meter's kWh as found, in hundredths (the LCD shows tenths).
  final int startHund;

  /// The wall clock's minute as found (the hour is 7 in the evening).
  final int startMinute;

  /// A fast call: something draws power with every load off (the LED blinks).
  final bool leak;

  /// A blank call: the tester lights on the incoming terminals.
  final bool voltage;

  /// Which wording of the complaint.
  final int complaint;

  int get runningAtStart => switches.where((s) => s).length;
}

@immutable
class M6PulseDeal {
  const M6PulseDeal({required this.calls, required this.coworkerCall, required this.push, required this.why});

  final List<M6PulseCall> calls;

  /// The call the coworker comes in on (the first steady fast call), and his push.
  final int coworkerCall;
  final M6PulsePush push;

  /// What each call's reason asks about (fits what was done).
  final List<M6PulseWhy> why;
}

M6PulseDeal m6PulseDeal(math.Random rng) {
  // 1–2 fast calls (the first call is always one: the intro's complaint),
  // at least one with a steady LED; then a blank or a dark-house call (with
  // one fast call: both).
  final twoFast = rng.nextBool();
  final rest = twoFast ? [M6PulseCallKind.fast, rng.nextBool() ? M6PulseCallKind.blank : M6PulseCallKind.dark] : [M6PulseCallKind.blank, M6PulseCallKind.dark];
  rest.shuffle(rng);
  final kinds = [M6PulseCallKind.fast, ...rest];
  // Which fast call leaks (never all of them: one steady LED always). With
  // two fast calls a leak comes 4 times in 5, so most such plays teach both
  // LED outcomes.
  final fastIdx = [for (final (i, k) in kinds.indexed) if (k == M6PulseCallKind.fast) i];
  final leakAt = fastIdx.length == 2 && rng.nextInt(5) < 4 ? fastIdx[rng.nextInt(2)] : -1;
  final calls = <M6PulseCall>[];
  final why = <M6PulseWhy>[];
  for (final (i, k) in kinds.indexed) {
    final house = [M6PulseAppliance.fan, M6PulseAppliance.tube, M6PulseAppliance.tv, M6PulseAppliance.fridge]..shuffle(rng);
    final rooms = [...house, M6PulseAppliance.pump];
    final switches = List<bool>.filled(5, false);
    if (k == M6PulseCallKind.fast) {
      // 3–5 running; one of them out of the first view (room 3 or the yard).
      final far = 3 + rng.nextInt(2);
      switches[far] = true;
      final others = [for (var r = 0; r < 5; r++) if (r != far) r]..shuffle(rng);
      final n = 3 + rng.nextInt(3);
      for (final r in others.take(n - 1)) {
        switches[r] = true;
      }
    } else {
      // No supply in the house: the switches stand as the family left them.
      for (var r = 0; r < 5; r++) {
        switches[r] = rng.nextInt(3) > 0;
      }
    }
    final leak = i == leakAt;
    calls.add(M6PulseCall(
      kind: k,
      rooms: rooms,
      switches: switches,
      // The last digit stays 3–7, so the 0.1 kWh tick always lands mid-hour
      // and never marks the hour's end.
      startHund: (10000 + rng.nextInt(80000)) * 10 + 3 + rng.nextInt(5),
      startMinute: rng.nextInt(60),
      leak: leak,
      voltage: k == M6PulseCallKind.blank && rng.nextBool(),
      complaint: rng.nextInt(2),
    ));
    why.add(switch (k) {
      M6PulseCallKind.fast => leak ? (rng.nextBool() ? M6PulseWhy.blink : M6PulseWhy.loadsOff) : (rng.nextBool() ? M6PulseWhy.fullHour : M6PulseWhy.loadsOff),
      M6PulseCallKind.blank => M6PulseWhy.incoming,
      M6PulseCallKind.dark => M6PulseWhy.neutral,
    });
  }
  final coworkerCall = [for (final (i, c) in calls.indexed) if (c.kind == M6PulseCallKind.fast && !c.leak) i].first;
  return M6PulseDeal(calls: calls, coworkerCall: coworkerCall, push: M6PulsePush.values[rng.nextInt(2)], why: why);
}

/// The play state (pure logic).
class M6PulseRun {
  M6PulseRun(this.deal) {
    _startCall();
  }
  final M6PulseDeal deal;

  int index = 0;
  int slips = 0;
  int callSlips = 0;
  final List<String> caught = [];

  /// The call's right answer is in (its reason comes next).
  var roundDone = false;
  var stage = M6PulseStage.hunt;

  /// Each room's switch now.
  List<bool> switches = const [];

  /// Game minutes the known load has run.
  double minutes = 0;
  var plugged = false;
  var tested = false;

  /// A verdict was given with a load on this call (the 'loads off' reason
  /// would not fit).
  var loadSlipped = false;
  var explained = false;

  int get count => deal.calls.length;
  M6PulseCall get call => deal.calls[index.clamp(0, count - 1)];
  bool get done => index >= count;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => callSlips == 0;
  bool get _open => !done && !roundDone;

  /// The house has supply (only the fast calls).
  bool get powered => call.kind == M6PulseCallKind.fast;

  /// The loads drawing power now.
  int get loadsOn => powered ? switches.where((s) => s).length : 0;

  /// What the CAL LED does now: blinking from a load left on (faster with
  /// more loads) or, with everything off, a fast blink from a leak (lesson
  /// 6.10 point 2: 'লোড বন্ধ থাকা সত্ত্বেও যদি CAL LED খুব দ্রুত ব্লিঙ্ক
  /// করে'); else steady. A verdict with a load on is a slip anyway, so the
  /// blink rate need not tell a leak from a running load.
  M6PulseLed get led {
    // A blank meter has no supply: its impulse LED cannot light or blink.
    if (call.kind == M6PulseCallKind.blank) return M6PulseLed.off;
    final n = loadsOn;
    if (n >= 2) return M6PulseLed.faster;
    if (n == 1) return call.leak ? M6PulseLed.faster : M6PulseLed.fast;
    return call.leak ? M6PulseLed.leak : M6PulseLed.steady;
  }

  /// The LCD's kWh in tenths (the known load adds 0.1 kWh an hour).
  int get readingTenths => (call.startHund + (plugged ? minutes / kM6PulseHour * 10 : 0)).floor() ~/ 10;

  /// The clock's minute (0–60) and hour.
  double get clockMinute => (call.startMinute + minutes) % 60;
  int get clockHour => 7 + (call.startMinute + minutes) ~/ 60;

  void _startCall() {
    switches = [...call.switches];
    stage = M6PulseStage.hunt;
    roundDone = false;
    callSlips = 0;
    minutes = 0;
    plugged = false;
    tested = false;
    loadSlipped = false;
    explained = false;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    callSlips++;
    return m;
  }

  /// A room's switch flips (in the house).
  bool toggle(int room) {
    if (!_open || stage != M6PulseStage.hunt) return false;
    switches[room] = !switches[room];
    return true;
  }

  /// 'মিটারে যাই'.
  bool goMeter() {
    if (!_open || stage != M6PulseStage.hunt) return false;
    stage = switch (call.kind) {
      M6PulseCallKind.fast => M6PulseStage.watch,
      M6PulseCallKind.blank => M6PulseStage.test,
      M6PulseCallKind.dark => M6PulseStage.neutral,
    };
    return true;
  }

  /// The LED window is over: the verdict.
  void watchDone() {
    if (_open && stage == M6PulseStage.watch) stage = M6PulseStage.verdict;
  }

  /// 'ঘরে ফিরি' from the verdict.
  bool goHome() {
    if (!_open || stage != M6PulseStage.verdict) return false;
    stage = M6PulseStage.hunt;
    return true;
  }

  /// A verdict on the LED.
  DoMistake? verdict(M6PulseVerdict v) {
    if (!_open || stage != M6PulseStage.verdict) return null;
    if (loadsOn > 0) {
      loadSlipped = true;
      stage = M6PulseStage.hunt;
      return _slip(M6MeterPulseMistakes.loadOn);
    }
    if (v == M6PulseVerdict.bad) return _slip(M6MeterPulseMistakes.meterBadEarly);
    if (call.leak) {
      if (v != M6PulseVerdict.leak) return _slip(M6MeterPulseMistakes.ledMissedBlink);
      _tag(M6MeterPulseLines.caughtLoads);
      _tag(M6MeterPulseLines.caughtLeak);
      roundDone = true;
      return null;
    }
    if (v != M6PulseVerdict.steady) return _slip(M6MeterPulseMistakes.ledFalseBlink);
    _tag(M6MeterPulseLines.caughtLoads);
    stage = M6PulseStage.plug;
    return null;
  }

  /// The bulb's plug into the socket.
  bool plug() {
    if (!_open || stage != M6PulseStage.plug) return false;
    plugged = true;
    stage = M6PulseStage.clock;
    return true;
  }

  /// The clock's minute hand turned by [d] game minutes (back as well as
  /// forward); returns the turn made.
  double turnClock(double d) {
    if (!_open || stage != M6PulseStage.clock) return 0;
    final n = (minutes + d).clamp(0.0, kM6PulseMaxMinutes);
    final moved = n - minutes;
    minutes = n;
    return moved;
  }

  /// 'রিডিং দেখি': under a full hour = slip (the test goes on).
  DoMistake? readNow() {
    if (!_open || stage != M6PulseStage.clock) return null;
    if (minutes < kM6PulseHour - 0.5) return _slip(M6MeterPulseMistakes.shortHour);
    stage = M6PulseStage.judge;
    return null;
  }

  /// The known-load judgement.
  DoMistake? judge({required bool right}) {
    if (!_open || stage != M6PulseStage.judge) return null;
    if (!right) return _slip(M6MeterPulseMistakes.knownWrong);
    _tag(M6MeterPulseLines.caughtHour);
    roundDone = true;
    return null;
  }

  /// The tester on the incoming terminals (its lamp: [M6PulseCall.voltage]).
  bool test() {
    if (!_open || stage != M6PulseStage.test) return false;
    tested = true;
    stage = M6PulseStage.place;
    return true;
  }

  /// A fault place before the test: nothing happens (the guide: measure).
  bool placeEarly() => _open && stage == M6PulseStage.test;

  /// The fault place on a blank call.
  DoMistake? place(M6PulsePlace p) {
    if (!_open || stage != M6PulseStage.place) return null;
    final lit = call.voltage;
    if (lit ? p != M6PulsePlace.meter : p == M6PulsePlace.meter) {
      return _slip(lit ? M6MeterPulseMistakes.blankLit : M6MeterPulseMistakes.blankDead);
    }
    _tag(M6MeterPulseLines.caughtIncoming);
    roundDone = true;
    return null;
  }

  /// The dark-house diagnosis.
  DoMistake? neutral({required bool right}) {
    if (!_open || stage != M6PulseStage.neutral) return null;
    if (!right) return _slip(M6MeterPulseMistakes.darkNotNeutral);
    _tag(M6MeterPulseLines.caughtNeutral);
    roundDone = true;
    return null;
  }

  /// After a leak's reason: explain the customer's appliances (pro tip 1).
  bool toExplain() {
    if (done || !roundDone || !call.leak || stage != M6PulseStage.verdict) return false;
    stage = M6PulseStage.explain;
    return true;
  }

  bool explain() {
    if (stage != M6PulseStage.explain || explained) return false;
    explained = true;
    _tag(M6MeterPulseLines.caughtExplain);
    return true;
  }

  /// Listened to the coworker (a slip).
  DoMistake pushSlip(DoMistake m) => _slip(m);

  void next() {
    index++;
    if (!done) _startCall();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a steady fast call: a swipe, 3–5 switches, 'মিটারে যাই' ≈ 8000, the
///     LED window 6000, the verdict ≈ 3000, the plug ≈ 2000, the clock (one
///     turn ≈ 2 drags) + 'রিডিং দেখি' ≈ 4500, the judgement ≈ 3000,
///     the coworker ≈ 9600                                        ≈ 36000
///   a leak call: hunt 8000, LED 6000, verdict 3000, 'বোঝাই' 2000 ≈ 19000
///   a blank call: go 1500, tester 2000, place + ✓ 3000           ≈ 6500
///   a dark call: go 1500, the deck 3000                           ≈ 4500
///   + a reason each (~8200 × 3)                                   ≈ 24600
///   three calls ≈ 72000–86000; 85 % ≈ 66000 → 70 s (a builder's
///   estimate; owner may tune).
const m6MeterPulseQuickMs = 70000;

@immutable
class M6MeterPulsePack {
  const M6MeterPulsePack({required this.id, required this.titleBn, this.quickMs = m6MeterPulseQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6MeterPulsePack> m6MeterPulsePacks = {
  'do_6_10_a': M6MeterPulsePack(id: 'do_6_10_a', titleBn: M6MeterPulseLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6MeterPulseProbe {
  static M6PulseRun? run;
  static double camX = 0;
}

// ============================================================================
// Page
// ============================================================================

class M6MeterPulsePage extends StatefulWidget {
  const M6MeterPulsePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6MeterPulsePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6MeterPulsePage> createState() => _M6MeterPulsePageState();
}

class _M6MeterPulsePageState extends State<M6MeterPulsePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PulseRunPage(
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

class _PulseRunPage extends ConsumerStatefulWidget {
  const _PulseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6MeterPulsePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PulseRunPage> createState() => _PulseRunPageState();
}

class _PulseRunPageState extends ConsumerState<_PulseRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6PulseRun _run;
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
  int _wake = 0;

  /// The house camera.
  double _camX = 0;
  double? _panX;

  /// Things in hand: the bulb's plug, the tester, the clock's hand.
  Offset? _plugAt;
  Offset? _testerAt;
  double? _clockAngle;
  double _clockTick = 0;

  /// The LED window's clock (forward once, then still).
  late final AnimationController _led = AnimationController(vsync: this, duration: const Duration(milliseconds: kM6PulseLedMs), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_ledStatus);

  /// The deck on screen (verdict / judgement / dark house): its options, the
  /// wrong ones tried, the right one picked.
  List<ChoiceOption> _deck = const [];
  final Map<String, M6PulseVerdict> _deckVerdict = {};
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  int _deckN = 0;

  /// The fault-place preview (two-step pick) and the places set aside.
  M6PulsePlace? _preview;
  Offset _previewAt = Offset.zero;
  final Set<M6PulsePlace> _aside = {};

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _explainKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6PulseGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6PulseRun(m6PulseDeal(widget.rng));
    M6MeterPulseProbe.run = _run;
    M6MeterPulseProbe.camX = 0;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _led.dispose();
    _chain++;
    if (identical(M6MeterPulseProbe.run, _run)) M6MeterPulseProbe.run = null;
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

  M6PulseCall get _call => _run.call;
  M6PulseStage get _stage => _run.stage;
  bool get _atMeter => _stage != M6PulseStage.hunt;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone;

  String get _task => switch (_stage) {
        M6PulseStage.hunt => _call.kind == M6PulseCallKind.fast ? M6MeterPulseLines.askHunt : M6MeterPulseLines.askHuntOther,
        M6PulseStage.watch => M6MeterPulseLines.askWatch,
        M6PulseStage.verdict => M6MeterPulseLines.askVerdict,
        M6PulseStage.plug => M6MeterPulseLines.askPlug,
        M6PulseStage.clock => M6MeterPulseLines.askClock,
        M6PulseStage.judge => M6MeterPulseLines.askJudge,
        M6PulseStage.test => M6MeterPulseLines.askTest,
        M6PulseStage.place => M6MeterPulseLines.askPlace,
        M6PulseStage.neutral => M6MeterPulseLines.askNeutral,
        M6PulseStage.explain => M6MeterPulseLines.askExplain,
      };

  Future<void> _start() async {
    _clock.start();
    _startCall();
  }

  void _startCall() {
    setState(() {
      _wake++;
      _camX = 0;
      M6MeterPulseProbe.camX = 0;
      _resetHands();
      _closeDeck();
    });
    final c = _call;
    unawaited(_sayChain([M6MeterPulseLines.complaints[c.kind]![c.complaint], _task]));
  }

  void _resetHands() {
    _plugAt = null;
    _testerAt = null;
    _clockAngle = null;
    _panX = null;
    _preview = null;
    _aside.clear();
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  /// The coworker's call: once he is due, the clock waits for him.
  bool _waitForHim() => _run.index == _run.deal.coworkerCall && holdForCoworker();

  // --- the decks ---------------------------------------------------------------
  void _closeDeck() {
    _deck = const [];
    _deckVerdict.clear();
    _deckWrong.clear();
    _deckPicked = null;
  }

  void _openDeck() {
    _closeDeck();
    _deckN++;
    final rng = widget.rng;
    switch (_stage) {
      case M6PulseStage.verdict:
        final truth = _call.leak ? M6PulseVerdict.leak : M6PulseVerdict.steady;
        final opts = <ChoiceOption>[];
        for (final v in M6PulseVerdict.values) {
          final l = M6MeterPulseLines.verdicts[v]!;
          final t = l[rng.nextInt(l.length)];
          _deckVerdict[t] = v;
          opts.add(ChoiceOption(t, v == truth));
        }
        _deck = opts..shuffle(rng);
      case M6PulseStage.judge:
        _deck = dealChoices(M6MeterPulseLines.judgeRight, M6MeterPulseLines.judgeWrong, rng);
      case M6PulseStage.neutral:
        _deck = dealChoices(M6MeterPulseLines.neutralRight, M6MeterPulseLines.neutralWrong, rng);
      default:
        break;
    }
  }

  bool get _ownDeckUp =>
      _deck.isNotEmpty && !_run.roundDone && _card == null && (_stage == M6PulseStage.verdict || _stage == M6PulseStage.judge || _stage == M6PulseStage.neutral);

  void _pickDeck(ChoiceOption o, Offset at) {
    if (!_canPlay || !_ownDeckUp) return;
    final stage = _stage;
    final DoMistake? m = switch (stage) {
      M6PulseStage.verdict => _run.verdict(_deckVerdict[o.textBn]!),
      M6PulseStage.judge => _run.judge(right: o.correct),
      M6PulseStage.neutral => _run.neutral(right: o.correct),
      _ => null,
    };
    if (m != null) {
      setState(() {
        if (_stage == M6PulseStage.hunt) {
          // A load was still on: back into the house.
          _closeDeck();
        } else {
          _deckWrong.add(o.textBn);
        }
        _wake++;
      });
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    if (_run.roundDone) {
      setState(() => _deckPicked = o.textBn);
      _stepDone();
      unawaited(_callDone());
      return;
    }
    if (_stage == M6PulseStage.plug) {
      // Steady with every load off: on to the known load.
      setState(_closeDeck);
      _stepDone();
      unawaited(_levelDelta(5, at, mood: GuideMood.glad));
      unawaited(_sayChain([M6MeterPulseLines.steadyOk, _task], mood: GuideMood.glad));
    }
  }

  // --- hands on -----------------------------------------------------------------
  void _goMeter() {
    if (!_canPlay || !_run.goMeter()) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() {
      _resetHands();
      _wake++;
    });
    _steps++;
    if (_stage == M6PulseStage.watch) {
      _hush();
      unawaited(_sayChain([_task]));
      _led.forward(from: 0);
      return;
    }
    if (_stage == M6PulseStage.neutral) setState(_openDeck);
    unawaited(_sayChain([_task]));
  }

  void _ledStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted || _stage != M6PulseStage.watch) return;
    _run.watchDone();
    setState(() {
      _openDeck();
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  void _goHome() {
    if (!_canPlay || !_run.goHome()) return;
    _tick();
    setState(() {
      _closeDeck();
      _wake++;
    });
    _steps++;
    unawaited(_sayChain([_task]));
  }

  void _tapScene(Offset p, M6PulseGeo geo, Offset global) {
    if (!_canPlay) return;
    if (!_atMeter) {
      for (var i = 0; i < 5; i++) {
        if (geo.switchOnScreen(i, _camX).contains(p)) {
          _run.toggle(i);
          _tick('sounds/intro/click.ogg', 0.55);
          _stepDone();
          return;
        }
      }
      _hints.missTap();
      return;
    }
    if (_stage == M6PulseStage.test || _stage == M6PulseStage.place) {
      final at = <M6PulsePlace, Rect>{M6PulsePlace.meter: geo.meterHit, M6PulsePlace.cable: geo.cableHit, M6PulsePlace.pole: geo.poleHit};
      for (final e in at.entries) {
        if (!e.value.contains(p)) continue;
        if (_run.placeEarly()) {
          _tick();
          unawaited(_sayChain([M6MeterPulseLines.testFirst]));
          return;
        }
        if (_preview != null) return;
        setState(() {
          _preview = e.key;
          _previewAt = global;
        });
        return;
      }
    }
    _hints.missTap();
  }

  void _confirmPlace() {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _preview = null;
      _aside.clear();
    });
    if (!_canPlay) return;
    final m = _run.place(p);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, _previewAt));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    _stepDone();
    unawaited(_callDone());
  }

  void _rejectPlace() {
    final p = _preview;
    if (p == null) return;
    setState(() {
      _preview = null;
      _aside.add(p);
    });
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

  void _panStart(Offset p, M6PulseGeo geo) {
    _panX = null;
    _plugAt = null;
    _testerAt = null;
    _clockAngle = null;
    if (!_canPlay) return;
    if (!_atMeter) {
      _panX = p.dx;
      return;
    }
    if (!_run.plugged && geo.bulbTray.contains(p)) {
      if (_stage != M6PulseStage.plug) {
        _hints.missTap();
        return;
      }
      setState(() => _plugAt = p);
      return;
    }
    if (!_run.tested && geo.testerTray.contains(p)) {
      if (_stage != M6PulseStage.test) {
        _hints.missTap();
        return;
      }
      setState(() => _testerAt = p);
      return;
    }
    if (geo.inClock(p) && _stage == M6PulseStage.clock) {
      if (_waitForHim()) return;
      final d = p - geo.clock;
      _clockAngle = math.atan2(d.dy, d.dx);
      setState(() => _wake++);
    }
  }

  void _panUpdate(Offset p, M6PulseGeo geo) {
    final px = _panX;
    if (px != null) {
      if (!_canPlay) {
        _panX = null;
        return;
      }
      final n = (_camX - (p.dx - px)).clamp(0.0, kM6PulseCamMax);
      _panX = p.dx;
      if (n != _camX) {
        setState(() => _camX = n);
        M6MeterPulseProbe.camX = n;
      }
      return;
    }
    if (_plugAt != null) {
      setState(() => _plugAt = p);
      return;
    }
    if (_testerAt != null) {
      setState(() => _testerAt = p);
      return;
    }
    final last = _clockAngle;
    if (last != null) {
      if (!_canPlay) {
        _clockAngle = null;
        return;
      }
      final d = p - geo.clock;
      if (d.distance < 4) return;
      final a = math.atan2(d.dy, d.dx);
      final da = _wrap(a - last);
      _clockAngle = a;
      // Clockwise on screen (the angle grows) moves time on.
      final moved = _run.turnClock(da / (2 * math.pi) * 60);
      if (moved != 0) {
        _clockTick += moved.abs();
        if (_clockTick >= 5) {
          _clockTick = 0;
          _cue('sounds/intro/tick.ogg', volume: 0.25);
        }
        setState(() {});
      }
    }
  }

  void _panEnd(M6PulseGeo geo) {
    if (_panX != null) {
      _panX = null;
      _stepDone();
      return;
    }
    final plug = _plugAt;
    if (plug != null) {
      setState(() => _plugAt = null);
      if (_canPlay && geo.socketHit.contains(plug) && _run.plug()) {
        _tick('sounds/intro/click.ogg', 0.6);
        if (_run.index == _run.deal.coworkerCall && !coworkerDone && !coworkerDue) scheduleCoworker();
        _stepDone();
        unawaited(_sayChain([_task]));
        return;
      }
      _hints.missTap();
      return;
    }
    final tester = _testerAt;
    if (tester != null) {
      setState(() => _testerAt = null);
      if (_canPlay && geo.incomingHit.contains(tester) && _run.test()) {
        _tick('sounds/intro/click.ogg', 0.6);
        _stepDone();
        unawaited(_sayChain([_task]));
        return;
      }
      _hints.missTap();
      return;
    }
    if (_clockAngle != null) {
      _clockAngle = null;
      _stepDone();
    }
  }

  void _readNow(Offset at) {
    if (!_canPlay || _stage != M6PulseStage.clock) return;
    if (_waitForHim()) return;
    final m = _run.readNow();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    setState(_openDeck);
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  void _explain() {
    if (_intro || _ended || _card != null || tableBusy || !_run.explain()) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    _stepDone();
    final idx = _run.index;
    unawaited(_sayChain([M6MeterPulseLines.explainLine], mood: GuideMood.glad));
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 1600), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  Future<void> _callDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final dealt = _run.deal.why[_run.index];
    // "Why switch every load off first?" would not fit a play that judged
    // the LED with a load still on.
    final topic = dealt == M6PulseWhy.loadsOff && _run.loadSlipped ? (_call.leak ? M6PulseWhy.blink : M6PulseWhy.fullHour) : dealt;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6MeterPulseLines.whyRight[topic]!, M6MeterPulseLines.myths, widget.rng),
      question: M6MeterPulseLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCall();
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
    if (_run.toExplain()) {
      setState(() {
        _closeDeck();
        _wake++;
      });
      unawaited(_sayChain([_task]));
      return;
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6MeterPulseLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerCall || _run.roundDone) return null;
    if (_run.plugged && _stage != M6PulseStage.clock) return null;
    if (_intro || _card != null || tableBusy || _preview != null || !_run.plugged) return false;
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
      final m = M6MeterPulseMistakes.push(p);
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6MeterPulseLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6MeterPulseLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6MeterPulseLines.tapWhy[_nudgeN++ % M6MeterPulseLines.tapWhy.length]
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
    _led.stop();
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
      _preview = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6pulse/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same call goes on from where it was.
    _hush();
    setState(() {
      _card = null;
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
    await _say(!_run.passed ? M6MeterPulseLines.fail : (_quickBonus ? M6MeterPulseLines.quick : M6MeterPulseLines.allSet),
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

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_plugAt != null || _testerAt != null || _clockAngle != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  List<M6PulseRoom> get _rooms => [
        for (var i = 0; i < 5; i++) M6PulseRoom(appliance: _call.rooms[i], switchOn: _run.switches[i], running: _run.powered && _run.switches[i]),
      ];

  M6PulseRig get _rig => M6PulseRig(
        lcdOn: _call.kind != M6PulseCallKind.blank,
        reading: _run.readingTenths,
        minute: _run.clockMinute,
        hour: _run.clockHour,
        plugged: _run.plugged,
        plugAt: _plugAt,
        testerAt: _testerAt,
        testerOnIncoming: _run.tested,
        testerLit: _call.voltage,
      );

  /// The gesture hand: how to touch, never what (see the header comment).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    switch (_stage) {
      case M6PulseStage.hunt:
        if (n.isEven) return HintSpec.swipe(Offset(220, geo.y(0.40)), toward: Offset(_camX < kM6PulseCamMax / 2 ? -1 : 1, 0), travel: 90, space: HintSpace.scene);
        final rects = [
          for (var i = 0; i < 5; i++)
            if (geo.switchOnScreen(i, _camX).center.dx > 8 && geo.switchOnScreen(i, _camX).center.dx < 352) geo.switchOnScreen(i, _camX),
        ];
        return rects.length < 2 ? null : HintSpec.sweep(rects, space: HintSpace.scene);
      case M6PulseStage.plug:
        return HintSpec.drag(geo.bulbTray.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M6PulseStage.clock:
        final th = -math.pi / 2 + _run.clockMinute / 60 * 2 * math.pi;
        return HintSpec.drag(geo.minuteTip(_run.clockMinute), toward: Offset(-math.sin(th), math.cos(th)), travel: 26, space: HintSpace.scene);
      case M6PulseStage.test:
        return HintSpec.drag(geo.testerTray.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M6PulseStage.place:
        return HintSpec.sweep([geo.meterHit, geo.cableHit, geo.poleHit], space: HintSpace.scene);
      // The explain beat is one plain button: no hand (the spec lists none).
      case M6PulseStage.explain || M6PulseStage.watch || M6PulseStage.verdict || M6PulseStage.judge || M6PulseStage.neutral:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6PulseGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final atMeter = _atMeter;
    return [
      if (!atMeter)
        Positioned.fill(
          key: const ValueKey('house'),
          child: RepaintBoundary(child: CustomPaint(painter: M6PulseHousePainter(geo: geo, camX: _camX, rooms: _rooms, powered: _run.powered))),
        )
      else ...[
        Positioned.fill(
          key: const ValueKey('veranda'),
          child: RepaintBoundary(child: CustomPaint(painter: M6PulseVerandaPainter(geo: geo, rig: _rig))),
        ),
        Positioned.fill(
          key: const ValueKey('led'),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M6PulseLedPainter(geo: geo, pattern: _run.led, windowMs: kM6PulseLedMs, t: _stage == M6PulseStage.watch ? _led : null),
            ),
          ),
        ),
      ],
      // The trainee at the meter (in the house the scene is his own look round).
      if (atMeter)
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: geo.trainee,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: atMeter ? M6MeterPulseLines.verandaLabel : M6MeterPulseLines.houseLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () {
              setState(_resetHands);
            },
          ),
        ),
      ),
      // The next call: a short fade.
      if (!_intro)
        Positioned.fill(
          key: ValueKey('round-${_run.index}-$atMeter'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || (_run.index == 0 && !atMeter) ? 0 : 0.5, end: 0),
              duration: const Duration(milliseconds: 420),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final ownDeck = _ownDeckUp;
    final deckUp = reasonOpen || coworkerChoiceUp || ownDeck;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && (_stage == M6PulseStage.explain || !_run.roundDone);
    const waits = {M6PulseStage.hunt, M6PulseStage.plug, M6PulseStage.clock, M6PulseStage.test, M6PulseStage.place, M6PulseStage.explain};
    final String? button = !handsOn || tableBusy
        ? null
        : switch (_stage) {
            M6PulseStage.hunt => M6MeterPulseLines.goMeter,
            M6PulseStage.clock => M6MeterPulseLines.readNow,
            M6PulseStage.explain => _run.explained ? null : M6MeterPulseLines.explain,
            _ => null,
          };
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
              labels: [for (var i = 0; i < _run.count; i++) M6MeterPulseLines.callName(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, _run.count); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _preview == null && waits.contains(_stage),
            hintKey: '${_run.index}/$_steps/${_stage.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (button != null)
                Positioned(
                  key: ValueKey('hud-btn-${_stage.name}-${_run.index}'),
                  left: 16,
                  bottom: pad.bottom + 14,
                  child: _PillButton(
                    key: _stage == M6PulseStage.explain ? _explainKey : null,
                    label: button,
                    onTap: (g) => switch (_stage) {
                      M6PulseStage.hunt => _goMeter(),
                      M6PulseStage.clock => _readNow(g),
                      M6PulseStage.explain => _explain(),
                      _ => null,
                    },
                  ),
                ),
              if (ownDeck && _stage == M6PulseStage.verdict && !reasonOpen && !coworkerOpen)
                Positioned(
                  key: ValueKey('hud-home-${_run.index}'),
                  left: 16,
                  top: pad.top + 104,
                  child: _PillButton(label: M6MeterPulseLines.goHome, small: true, onTap: (_) => _goHome()),
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
                                key: ValueKey('call-deck-$_deckN'),
                                options: _deck,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: _pickDeck,
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _preview != null)
                Positioned.fill(
                  key: ValueKey('place-preview-${_preview!.name}'),
                  child: CardPreviewOverlay(
                    textBn: M6MeterPulseLines.place(_preview!),
                    icon: _placeIcons[_preview!],
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmPlace,
                    onReject: _rejectPlace,
                  ),
                ),
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
                  line: M6MeterPulseLines.intro,
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

  static const _placeIcons = {
    M6PulsePlace.meter: Icons.speed_rounded,
    M6PulsePlace.cable: Icons.cable_rounded,
    M6PulsePlace.pole: Icons.electrical_services_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// A worker's button on the scene ('মিটারে যাই', 'রিডিং দেখি', …).
class _PillButton extends StatelessWidget {
  const _PillButton({super.key, required this.label, required this.onTap, this.small = false});
  final String label;
  final ValueChanged<Offset> onTap;
  final bool small;

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
          constraints: BoxConstraints(minHeight: small ? 48 : 54, minWidth: small ? 96 : 150),
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(label, style: bangla(fontSize: small ? 13.5 : 16, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}
