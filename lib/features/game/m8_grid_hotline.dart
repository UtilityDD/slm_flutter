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
import 'm8_grid_hotline_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_grid_hotline_world.dart' show M8BayDrag, M8GridGeo, M8MeterPainter, M8Phone, M8Phones, kM8Bays, kM8KnobOff, kM8KnobOn, kM8RingMs;

// Lesson 8.4 "গ্রিড কোড (Grid Code): সিস্টেম শৃঙ্খলার নিয়ম", কাজ 1
// "হটলাইন বাজছে" (pack do_8_4_a, engineType m8_grid_hotline). A 33/11 kV
// control room at dusk; two grid incidents per play, dealt fresh:
//
//  * watch: the wall meter's frequency drifts down on a dealt path (the
//    evening peak or a storm trip). Once per play, in a dealt incident, the
//    guide asks 'গ্রিডের হাল কেমন?' (a decision deck: right → ◆ → "কেন?"; wrong =
//    slip). The reading is dealt: normal (inside 49.90–50.05) asked at the
//    start, or low (well under 49.90) asked once it has drifted down.
//  * ring: the SLDC hotline rings for a dealt number of rings; on some deals
//    the black phone rings first or together. Drag the hotline's handset up
//    off its cradle. Lifting the black phone while the hotline rings = slip;
//    letting the hotline pass its dealt ring count = slip (it rings again).
//  * order: SLDC's order is a silent caption held for reading ('<n>টি ফিডার
//    এখনই OFF করুন', n = 1 or 2). The handset goes down and the frequency
//    falls toward 49.0 — the meter is the race clock (no countdown text).
//  * shed: tap the register (rows = six areas in a fixed order unrelated to
//    the panel, columns = the last three days, dark-moon marks; nothing is
//    highlighted), close it (tap or swipe down on its handle), and twist a
//    bay's pistol-grip switch along its arc to OFF; its neighbourhood goes
//    dark. A feeder shed on recent days = slip (the switch springs back).
//    All n right feeders OFF before 49.0 = in time; passing 49.0 first = slip
//    (once; the round still ends with the feeders off). Then the state-map
//    inset dims and the meter climbs.
//  * the coworker comes once a play on the first switch twist after an order
//    (the twist waits for him; the frequency is paused while he is on);
//    listening = slip (A2 'call SLDC first' also loses 3 s of the race).
//  * reason: 'কেন এই ফিডারগুলো?' / 'কেন প্রশ্ন না করে কাটলেন?' / (after a black
//    phone) 'কেন আগে হটলাইন ধরলেন?'.
//  * consumer: the black phone rings; the customer's caption; the guide asks
//    'কী বলবেন?' (a decision deck; wrong = slip).
//
// Every mistake is a slip (rulings M8-1 / M8-4: no life-safety act here;
// frequency through 49.0 is system harm with nobody exposed; X2/B1: listening
// takes the class of the act he pushes — a slip). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m8_grid_hotline_world.dart), corner guide; a right call puts ◆ on
// the table → "কেন …?". Gesture hands: a short upward drag on the hotline when
// it alone rings, a sweep over both handsets when both ring (never in the
// watch beat or while only the black phone leads); after the order a sweep
// over the six switches and the register; on a switch that was tapped twice a
// short arc on THAT switch; a swipe down on the open register's handle.

// ============================================================================
// Content
// ============================================================================

/// What made the grid sag.
enum M8Cause { peak, storm }

/// The black phone's part in an incident.
enum M8BlackMode { none, first, together }

/// What the frequency reading says (the state deck's truth).
enum M8State { normal, low, danger }

/// What a reason asks about.
enum M8Why { rotation, noQuestion, hotline, state }

/// The coworker's push (one per play).
enum M8Push { myth, ask, book }

/// Where an incident stands.
enum M8Stage { watch, state, ring, order, shed, after, callRing, callSay }

/// What lifting a handset did.
enum M8Lift { ignored, hot, blackSlip, call }

/// The race to 49.0: the frequency reaches 49.0 this long after the order
/// (ms), with one or two feeders to shed.
const int kM8RaceOneMs = 14000;
const int kM8RaceTwoMs = 17500;

/// The race's line runs on to this value (just past 49.0).
const double kM8RaceFloor = 48.94;

/// The lesson's danger line.
const double kM8Danger = 49.0;

/// After a miss, the hotline rings again this many more rings.
const int kM8Redial = 3;

/// The black phone's lead over the hotline on a 'first' deal (rings).
const int kM8BlackLead = 2;

/// The frequency after a successful shed climbs to this (ms to get there).
const double kM8Recovered = 49.93;
const int kM8RecoverMs = 4000;

/// The register's area names (the pool; each incident uses six).
const List<String> kM8AreaPool = ['বাজার', 'স্টেশন', 'নতুনপাড়া', 'কলেজ', 'বটতলা', 'রথতলা', 'হাটখোলা', 'নদীপাড়া'];

abstract final class M8GridHotlineLines {
  static const title = 'হটলাইন বাজছে';
  // DRAFT wording — owner (M6-12).
  static const intro = 'সন্ধ্যার পিক, গ্রিড টানটান! মিটারে চোখ রাখুন — হটলাইন বাজলেই সবার আগে ধরুন!';

  // The guide's task now (tap him: the same task, a different way).
  static const askWatch = 'মিটারের দিকে নজর রাখুন।';
  static const askWatchOther = 'ফ্রিকোয়েন্সির ওঠানামা দেখতে থাকুন।';
  static const askState = 'গ্রিডের হাল কেমন?';
  static const askRing = 'ফোন বাজছে!';
  static const askRingOther = 'ফোন বাজছে — দেরি করবেন না।';
  static const askOrder = 'নির্দেশটা মন দিয়ে পড়ুন।';
  static const askShed = 'নির্দেশ পেলেন — এবার কাজে নামুন।';
  static const askShedOther = 'মিটারের দিকে নজর রেখে কাজটা সারুন।';
  static const askCall = 'আবার ফোন বাজছে।';
  static const askSay = 'কী বলবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askWatch, askWatchOther, askState, askRing, askRingOther, askOrder, askShed, askShedOther, askCall, askSay];

  // Silent drawn figures (M8-10): SLDC's order and the customer, as captions.
  static const sldcTag = 'SLDC';
  static const customerTag = 'গ্রাহক';
  static String orderLine(int n) => enDigits('$nটি ফিডার এখনই OFF করুন');
  static const customerCaptions = ['আবার কারেন্ট নেই! তোমরা কী করছ?', 'এই নিয়ে কতবার কারেন্ট গেল! কী হচ্ছে?'];

  // On-screen labels (a worker's own words; not spoken).
  static const sceneLabel = 'কন্ট্রোল রুম';
  static const registerLabel = 'লোড শেডিং খাতা';
  static const registerHead = 'এলাকা';
  static String incidentName(int n) => enDigits('ঘটনা $n');
  static String date(int day) => enDigits('$day/11');

  /// The state deck: one phrasing of each state is dealt (alike in length).
  static const states = <M8State, List<String>>{
    M8State.normal: ['ফ্রিকোয়েন্সি ঠিকই আছে, স্বাভাবিক হাল', 'সব ঠিক আছে, ফ্রিকোয়েন্সি স্বাভাবিক'],
    M8State.low: ['লোড বেশি, তাই ফ্রিকোয়েন্সি কমে গেছে', 'ফ্রিকোয়েন্সি কম, লোড বেড়ে গেছে'],
    M8State.danger: ['বিপদ আসন্ন, ফ্রিকোয়েন্সি 49.0-এর নিচে', 'গ্রিড ধসার মুখে, 49.0-এর নিচে নেমেছে'],
  };

  /// The customer's deck ('কী বলবেন?').
  static const consumerRight = [
    'দাদা, এটা লোকাল ফল্ট নয়, ওপর থেকে গ্রিড বাঁচাতে লাইন OFF করেছে।',
    'দাদা, গ্রিড বাঁচাতে ওপর থেকে লাইন OFF করেছে, লোকাল ফল্ট নয়।',
  ];
  static const consumerWrong = [
    'দাদা, কোম্পানি বিদ্যুৎ তৈরি করছে না, আমরা আর কী করব বলুন?',
    'দাদা, লোকাল ফল্ট হয়েছে, মিস্ত্রি যাচ্ছে, একটু অপেক্ষা করুন।',
    'দাদা, আপনি আমার সঙ্গে তর্ক না করে একটু চুপ করুন তো এখন!',
    'ওপরের ব্যাপার আমি জানি না, গিয়ে অভিযোগ ঠুকে দিন গে যান।',
    'দাদা, কাল থেকে সব ঠিক হয়ে যাবে, এখন ফোনটা রেখে দিন।',
    'বিদ্যুৎ নেই তো আমি কী করব দাদা, এটা আমার দোষ নয়, বলুন!',
  ];
  static const consumerHeld = 'ঠিক বলেছেন — গ্রাহক বুঝলে রাগ কমে।';

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M8Why, String>{
    M8Why.rotation: 'কেন এই ফিডারগুলো বেছে নিলেন?',
    M8Why.noQuestion: 'কেন প্রশ্ন না করে সঙ্গে সঙ্গে কাটলেন?',
    M8Why.hotline: 'কেন আগে হটলাইন ধরলেন?',
    M8Why.state: 'মিটার দেখে কেন এটা বললেন?',
  };
  static const whyRight = <M8Why, List<String>>{
    M8Why.rotation: ['একই এলাকায় বারবার নয়, পালা করে কাটলে ভোগান্তি কম', 'গত কয়েক দিন যেখানে কাটা হয়নি, পালা করে সেখানেই কাটলাম'],
    M8Why.noQuestion: ['গ্রিড সেকেন্ডের মধ্যে ধসে পড়তে পারে, দেরির সময় নেই', 'অর্ডার এলে আগে লাইন কাটতে হয়, দেরি করলে গ্রিড ধসবে'],
    M8Why.hotline: ['হটলাইনের রিং এলে সবার আগে ধরতে হয়, গ্রিডের নির্দেশ আসে', 'ইমার্জেন্সি হটলাইন বাজলে আগে সেটাই ধরি, নির্দেশ আসে ওখানে'],
  };

  /// The state reason fits the dealt reading.
  static const stateWhyRight = <M8State, List<String>>{
    M8State.normal: ['ফ্রিকোয়েন্সি 49.90 থেকে 50.05-এর মধ্যে, তাই স্বাভাবিক', 'রিডিং 49.90 থেকে 50.05 হার্টজের সীমার ভেতরেই আছে'],
    M8State.low: ['ফ্রিকোয়েন্সি কমা মানে লোড বেড়েছে, সাপ্লাই কম আছে', 'রিডিং নামছে মানে চাহিদা বেশি আর সাপ্লাই কম আছে'],
  };
  static const myths = [
    'লোড শেডিং মানেই কোম্পানি বিদ্যুৎ তৈরি করছে না আসলে',
    'ছোট সাবস্টেশন বন্ধ করলে গ্রিডের কিছুই আসে যায় না',
    'হটলাইন তো রোজই বাজে, এত তাড়ার কিছু নেই আসলে ভাই',
    'SLDC তো ভুলও বলতে পারে, আগে ফোনে জেনে নিই আমি',
    'যেটা হাতের কাছে ছিল, সেটাই কেটে দিলাম আমি তাড়াতাড়ি',
    'রোজ যেগুলো কাটি, সেগুলো কাটাই সবচেয়ে সহজ হয় আমার',
    'গ্রাহক রাগ করবে, তাই আগে তাকে বুঝিয়ে নিই আমি আগে',
    'ফ্রিকোয়েন্সি কমলেও কিছু হয় না, নিজেই ঠিক হয়ে যাবে',
  ];
  static List<String> get allWhyRight => <String>{
        for (final l in whyRight.values) ...l,
        for (final l in stateWhyRight.values) ...l,
      }.toList();

  // The careless coworker (once a play, on the first switch twist after an
  // order). DRAFT wording — owner (M6-12): the spec's three pushes.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerMyth = CoworkerScript(
    line: 'আমাদের ছোট সাবস্টেশন বন্ধ করলে গ্রিডের কি বা এসে যাবে?',
    exitLine: coworkerExit,
    right: [
      'না, হাজারটা ছোট ফিডার বন্ধ হলে তবেই ফ্রিকোয়েন্সি ফেরে',
      'না, বিন্দু বিন্দু জলেই সিন্ধু হয়, আমরা ফিডার কাটব',
      'না, ছোট ফিডারও লাগে, হাজারটা মিলেই গ্রিড বাঁচে',
    ],
    wrong: [
      'ঠিক বলেছেন, আমাদের একটা বন্ধ করলে গ্রিডের কিছু হবে না',
      'হ্যাঁ, ছোট সাবস্টেশনের ফিডার না কাটলেও গ্রিড চলে যাবে',
      'আচ্ছা, আমরা এখন আর কাটছি না, দেখি ওপরে কী হয়',
      'ঠিক, ওপর থেকে অন্য কেউ কেটে দেবে ঠিকই, আমরা কেন?',
      'হ্যাঁ, আমাদেরটা বাদ দিলে কারও কিছু আসে যায় না',
    ],
    asks: ['কী করবেন?', 'ও বলছে ছোট সাবস্টেশনে কী আসে যায়। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerAsk = CoworkerScript(
    line: 'আরে আগে SLDC-কে ফোন করে জিজ্ঞেস করো, কেন কাটবে!',
    exitLine: coworkerExit,
    right: [
      'না, অর্ডার এলে প্রশ্ন নয়, আগে লাইন কাটব',
      'না, গ্রিড সেকেন্ডে ধসতে পারে, আগে ফিডার কাটব',
      'না, ফোনে জিজ্ঞেস করার সময় নেই, আগে কাটব',
    ],
    wrong: [
      'ঠিক, আগে ফোন করে কারণটা ভালো করে জেনে নিই',
      'হ্যাঁ, SLDC-কে ফেরত ফোন করে কারণ জিজ্ঞেস করি',
      'আচ্ছা, ওরা আগে কারণ বুঝিয়ে দিক, তারপর কাটব',
      'ঠিক আছে, আগে জেনে নিই কেন কাটতে হচ্ছে আমাদের',
      'হ্যাঁ, না জেনে কেটে ফেলা মোটেই ঠিক হবে না',
    ],
    asks: ['কী করবেন?', 'ও বলছে আগে SLDC-কে ফোন করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerBook = CoworkerScript(
    line: 'খাতা দেখার সময় নেই, রোজ যেটা কাটি সেটাই কাটো!',
    exitLine: coworkerExit,
    right: [
      'না, পালা করেই কাটব, খাতা দেখে মিলিয়ে',
      'না, একই এলাকায় বারবার নয়, খাতা দেখেই কাটব',
      'না, খাতা দেখে যাদের পালা, তাদেরই কাটব',
    ],
    wrong: [
      'ঠিক, রোজ যেটা কাটি সেটাই কেটে দিই এবার',
      'হ্যাঁ, খাতা দেখার সময় নেই, ওটাই চলুক',
      'আচ্ছা, যেটা হাতের কাছে সেটাই কেটে দিই',
      'ঠিক বলেছেন, খাতা দেখতে গেলে খুব দেরি হবে',
      'হ্যাঁ, রোজকার ফিডারটাই কেটে ফেলি তাহলে',
    ],
    asks: ['কী করবেন?', 'ও বলছে খাতা না দেখে রোজকার ফিডার কাটতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M8Push p) => switch (p) {
        M8Push.myth => coworkerMyth,
        M8Push.ask => coworkerAsk,
        M8Push.book => coworkerBook,
      };
  static const allCoworkers = [coworkerMyth, coworkerAsk, coworkerBook];

  static String callHeld(M8Push p) => switch (p) {
        M8Push.myth => 'ঠিক! ছোট ফিডারও গ্রিড বাঁচায়।',
        M8Push.ask => 'ঠিক! অর্ডার এলে আগে লাইন কাটতে হয়।',
        M8Push.book => 'ঠিক! খাতা দেখে ঘুরিয়ে কাটাই নিয়ম।',
      };

  static const allSet = 'গ্রিড বাঁচল — দুটো ঘটনাতেই ঠিকঠাক সামলেছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — হটলাইন আগে, নির্দেশ মাত্রই কাটুন, পালা করে।';

  // "আজ যা ধরলেন".
  static const caughtState = 'মিটার দেখে গ্রিডের হাল বোঝা';
  static const caughtHot = 'হটলাইন আগে';
  static const caughtShed = 'নির্দেশ মাত্রই OFF';
  static const caughtRotate = 'পালা করে';
  static const caughtExplain = 'গ্রাহককে বোঝানো';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until then
  /// the device voice). The silent captions (SLDC, the customer) are not here.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        consumerHeld,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks,
        for (final p in M8Push.values) callHeld(p),
        allSet,
        quick,
        fail,
        for (final m in M8GridHotlineMistakes.all) m.textBn,
      }.toList();
}

abstract final class M8GridHotlineMistakes {
  static const _dir = 'assets/game/art/m8_grid_hotline';

  // DRAFT wording — owner (M6-12). Lesson points of 8.4 (0-based): 0 the 50 Hz
  // target, 1 over-drawal, 2 emergency load shedding, 3 rotational shedding,
  // 4 voltage; the pro tips/myths sit with point 2 (3 for rotation).
  static const blackPhone = DoMistake(
    key: '8.4/m8_grid_hotline/black-phone',
    textBn: 'হটলাইন বাজছে — সবার আগে ওটাই ধরতে হয়। গ্রাহকের ফোন পরে, গ্রিডের নির্দেশ আগে।',
    art: '$_dir/black_phone.svg',
    lessonPoint: 2,
  );
  static const ringMissed = DoMistake(
    key: '8.4/m8_grid_hotline/ring-missed',
    textBn: 'হটলাইন বেজে গেল, কেউ ধরেনি। ইমার্জেন্সি ফোন বা হটলাইনের রিং হলে সবার আগে ধরুন।',
    art: '$_dir/ring_missed.svg',
    lessonPoint: 2,
  );
  static const raceLost = DoMistake(
    key: '8.4/m8_grid_hotline/race-lost',
    textBn: 'ফ্রিকোয়েন্সি 49.0-এর নিচে নেমে গেল। SLDC-র নির্দেশ আসা মাত্রই ফিডার OFF করতে হয়, দেরির সময় নেই।',
    art: '$_dir/race_lost.svg',
    lessonPoint: 2,
  );
  static const recentShed = DoMistake(
    key: '8.4/m8_grid_hotline/recent-shed',
    textBn: 'এই এলাকায় গত কয়েক দিনেই লোড শেডিং হয়েছে। একই এলাকায় বারবার নয়, ঘুরিয়ে ঘুরিয়ে করুন — খাতা দেখে পালা মিলিয়ে নিন।',
    art: '$_dir/recent_shed.svg',
    lessonPoint: 3,
  );
  static const stateLow = DoMistake(
    key: '8.4/m8_grid_hotline/state-low',
    textBn: 'ফ্রিকোয়েন্সি কমে যাওয়া মানে লোড বেড়ে গেছে, সাপ্লাই কম। 49.90-এর নিচে মানে নিরাপদ সীমার বাইরে — নজর রাখুন।',
    art: '$_dir/state_low.svg',
    lessonPoint: 0,
  );
  static const stateNormal = DoMistake(
    key: '8.4/m8_grid_hotline/state-normal',
    textBn: 'ফ্রিকোয়েন্সি 49.90 থেকে 50.05 হার্টজের মধ্যে থাকলে সব ঠিক। 49.0-এর নিচে নামলে তবেই বিপদ আসন্ন।',
    art: '$_dir/state_normal.svg',
    lessonPoint: 0,
  );
  static const consumerWrong = DoMistake(
    key: '8.4/m8_grid_hotline/consumer-wrong',
    textBn: 'গ্রাহককে বোঝান: এটা লোকাল ফল্ট নয়, ওপর থেকে গ্রিড বাঁচাতে লাইন OFF করা হয়েছে। তর্ক বা ভুল গল্প নয়।',
    art: '$_dir/consumer.svg',
    lessonPoint: 2,
  );
  static const pushMyth = DoMistake(
    key: '8.4/m8_grid_hotline/push-myth',
    textBn: 'ছোট সাবস্টেশনও দরকার: বিন্দু বিন্দু জলেই সিন্ধু হয়। হাজারটা ছোট ফিডার একসঙ্গে বন্ধ না হলে ফ্রিকোয়েন্সি ফেরে না।',
    art: '$_dir/push_myth.svg',
    lessonPoint: 2,
  );
  static const pushAsk = DoMistake(
    key: '8.4/m8_grid_hotline/push-ask',
    textBn: 'SLDC-র নির্দেশ এলে প্রশ্ন করবেন না, আগে লাইন কাটুন। গ্রিড সেকেন্ডের মধ্যে ধসে পড়তে পারে।',
    art: '$_dir/push_ask.svg',
    lessonPoint: 2,
  );
  static const pushBook = DoMistake(
    key: '8.4/m8_grid_hotline/push-book',
    textBn: 'একই এলাকায় বারবার নয় — খাতা দেখে ঘুরিয়ে ঘুরিয়ে লোড শেডিং করুন, তাতে গ্রাহকের ভোগান্তি কম।',
    art: '$_dir/push_book.svg',
    lessonPoint: 3,
  );

  /// Listening to his push is the act it pushes (X2/B1): a slip.
  static DoMistake push(M8Push p) => switch (p) {
        M8Push.myth => pushMyth,
        M8Push.ask => pushAsk,
        M8Push.book => pushBook,
      };

  /// The wrong reading of the frequency: what it really said.
  static DoMistake state(M8State truth) => truth == M8State.low ? stateLow : stateNormal;

  static const List<DoMistake> all = [
    blackPhone,
    ringMissed,
    raceLost,
    recentShed,
    stateLow,
    stateNormal,
    consumerWrong,
    pushMyth,
    pushAsk,
    pushBook,
  ];
}

/// One grid incident.
@immutable
class M8Incident {
  const M8Incident({
    required this.cause,
    required this.fStart,
    required this.fRing,
    required this.driftMs,
    required this.blackMode,
    required this.rings,
    required this.n,
    required this.areas,
    required this.marks,
    required this.bayArea,
    required this.day,
    required this.why,
    this.customer = 0,
  });

  final M8Cause cause;

  /// The frequency as the incident opens (inside the lesson's band) and when
  /// the hotline rings (well under it).
  final double fStart;
  final double fRing;
  final int driftMs;
  final M8BlackMode blackMode;

  /// How many rings the hotline is allowed.
  final int rings;

  /// Feeders SLDC orders OFF (1 or 2).
  final int n;

  /// The six area names in the register's fixed order.
  final List<String> areas;

  /// marks[row][col]: the area (register row) was shed on that day (columns:
  /// the last three days, oldest first).
  final List<List<bool>> marks;

  /// Which register row each panel bay feeds.
  final List<int> bayArea;

  /// The register's last day (its columns are day-3 … day-1).
  final int day;

  /// What this incident's reason asks about.
  final M8Why why;

  /// Which wording of the customer's caption.
  final int customer;

  String bayName(int bay) => areas[bayArea[bay]];

  /// The area behind [bay] was shed on a recent day.
  bool recent(int bay) => marks[bayArea[bay]].any((m) => m);

  /// The bays that are right to shed (no recent shedding).
  List<int> get rightBays => [for (var b = 0; b < kM8Bays; b++) if (!recent(b)) b];

  int get raceMs => n == 1 ? kM8RaceOneMs : kM8RaceTwoMs;

  /// The race's full length: its line runs from [fRing] to [kM8RaceFloor] and
  /// crosses 49.0 at [raceMs].
  double get raceTotalMs => raceMs * (fRing - kM8RaceFloor) / (fRing - kM8Danger);

  /// The frequency [ms] into the race.
  double raceFreq(double ms) => fRing + (kM8RaceFloor - fRing) * (ms / raceTotalMs).clamp(0.0, 1.0);

  /// The black phone's lead over the hotline (ms).
  int get leadMs => blackMode == M8BlackMode.first ? kM8BlackLead * kM8RingMs : 0;

  /// The hotline's allowed rings end this far into the ring timeline.
  int get missAtMs => leadMs + rings * kM8RingMs;

  /// The whole ring timeline: the allowed rings, then the redial.
  int get ringTotalMs => missAtMs + kM8Redial * kM8RingMs;
}

@immutable
class M8Deal {
  const M8Deal({required this.incidents, required this.askIncident, required this.readState, required this.coworkerIncident, required this.push});

  final List<M8Incident> incidents;

  /// The incident that hosts the guide's 'গ্রিডের হাল' question, and its truth.
  final int askIncident;
  final M8State readState;

  /// The incident the coworker comes in on, and his push.
  final int coworkerIncident;
  final M8Push push;
}

M8Deal m8GridDeal(math.Random rng) {
  final readState = rng.nextBool() ? M8State.normal : M8State.low;
  final askIncident = rng.nextInt(2);
  final coworkerIncident = rng.nextInt(2);
  final push = M8Push.values[rng.nextInt(M8Push.values.length)];
  final incidents = <M8Incident>[];
  final used = <M8Why>{};
  final day0 = 5 + rng.nextInt(18);
  for (var i = 0; i < 2; i++) {
    final n = 1 + rng.nextInt(2);
    final pool = [for (var k = 0; k < kM8AreaPool.length; k++) k]..shuffle(rng);
    final six = pool.take(kM8Bays).toList()..sort();
    final areas = [for (final k in six) kM8AreaPool[k]];
    // Exactly n areas with no mark in the last three days; every other area
    // was shed at least once.
    final rows = [for (var r = 0; r < kM8Bays; r++) r]..shuffle(rng);
    final unshed = rows.take(n).toSet();
    final marks = <List<bool>>[];
    for (var r = 0; r < kM8Bays; r++) {
      if (unshed.contains(r)) {
        marks.add([false, false, false]);
      } else {
        final mask = 1 + rng.nextInt(7);
        marks.add([(mask & 1) != 0, (mask & 2) != 0, (mask & 4) != 0]);
      }
    }
    final blackMode = M8BlackMode.values[rng.nextInt(3)];
    final whyPool = [M8Why.rotation, M8Why.noQuestion, if (blackMode != M8BlackMode.none) M8Why.hotline].where((w) => !used.contains(w)).toList();
    final why = whyPool[rng.nextInt(whyPool.length)];
    used.add(why);
    incidents.add(M8Incident(
      cause: rng.nextBool() ? M8Cause.peak : M8Cause.storm,
      fStart: 49.93 + rng.nextInt(11) / 100,
      fRing: 49.60 + rng.nextInt(23) / 100,
      driftMs: 3500 + rng.nextInt(2001),
      blackMode: blackMode,
      rings: 3 + rng.nextInt(2),
      n: n,
      areas: areas,
      marks: marks,
      bayArea: [for (var r = 0; r < kM8Bays; r++) r]..shuffle(rng),
      day: day0 + i,
      why: why,
      customer: rng.nextInt(M8GridHotlineLines.customerCaptions.length),
    ));
  }
  return M8Deal(incidents: incidents, askIncident: askIncident, readState: readState, coworkerIncident: coworkerIncident, push: push);
}

/// The play state (pure logic; the page owns time).
class M8GridRun {
  M8GridRun(this.deal) {
    _start();
  }
  final M8Deal deal;

  int index = 0;
  int slips = 0;
  int callSlips = 0;
  final List<String> caught = [];

  var stage = M8Stage.watch;

  /// The hotline / black phone are ringing now (ring beat).
  var hotOn = false;
  var blackOn = false;

  /// This incident's slips that decide which reason fits.
  var ringMissed = false;
  var blackSlipped = false;
  var raceLost = false;
  var recentSlips = 0;

  /// The state question was answered right (once per play).
  var stateDone = false;
  var stateAnswered = false;

  /// The consumer beat is answered right.
  var consumerDone = false;

  /// Each bay's switch is at OFF.
  List<bool> off = List.filled(kM8Bays, false);

  int get count => deal.incidents.length;
  M8Incident get inc => deal.incidents[index.clamp(0, count - 1)];
  bool get done => index >= count;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => callSlips == 0;

  /// This incident hosts the state question and it is still to come.
  bool get askHere => !stateDone && index == deal.askIncident;

  void _start() {
    stage = askHere && deal.readState == M8State.normal ? M8Stage.state : M8Stage.watch;
    hotOn = false;
    blackOn = false;
    ringMissed = false;
    blackSlipped = false;
    raceLost = false;
    recentSlips = 0;
    stateAnswered = false;
    consumerDone = false;
    callSlips = 0;
    off = List.filled(kM8Bays, false);
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    callSlips++;
    return m;
  }

  /// The frequency's drift is over: the state question (a low reading, asked
  /// once it has fallen) or the ring.
  void driftDone() {
    if (stage != M8Stage.watch) return;
    if (askHere && deal.readState == M8State.low) {
      stage = M8Stage.state;
      return;
    }
    startRing();
  }

  /// The guide's state question: a wrong card is a slip (a decision deck).
  DoMistake? answerState(M8State s) {
    if (stage != M8Stage.state || stateAnswered) return null;
    if (s != deal.readState) return _slip(M8GridHotlineMistakes.state(deal.readState));
    stateAnswered = true;
    stateDone = true;
    _tag(M8GridHotlineLines.caughtState);
    return null;
  }

  /// After the state reason: a normal reading goes on to the drift, a low one
  /// to the ring.
  void afterState() {
    if (stage != M8Stage.state || !stateAnswered) return;
    if (deal.readState == M8State.normal) {
      stage = M8Stage.watch;
    } else {
      startRing();
    }
  }

  void startRing() {
    stage = M8Stage.ring;
    hotOn = inc.blackMode != M8BlackMode.first;
    blackOn = inc.blackMode != M8BlackMode.none;
  }

  /// The black phone's lead is over: the hotline starts.
  void hotStarts() {
    if (stage == M8Stage.ring) hotOn = true;
  }

  /// A handset lifted. The mistake of a black-phone lift comes from
  /// [blackSlip].
  M8Lift lift(M8Phone p) {
    if (p == M8Phone.hot) {
      if (stage != M8Stage.ring || !hotOn) return M8Lift.ignored;
      stage = M8Stage.order;
      hotOn = false;
      blackOn = false;
      if (!ringMissed && !blackSlipped) _tag(M8GridHotlineLines.caughtHot);
      return M8Lift.hot;
    }
    if (stage == M8Stage.ring && hotOn) return M8Lift.blackSlip;
    if (stage == M8Stage.callRing) {
      stage = M8Stage.callSay;
      return M8Lift.call;
    }
    return M8Lift.ignored;
  }

  /// The black phone lifted while the hotline rings.
  DoMistake blackSlip() {
    blackSlipped = true;
    return _slip(M8GridHotlineMistakes.blackPhone);
  }

  /// The hotline passed its dealt rings (once an incident).
  DoMistake? ringExpired() {
    if (stage != M8Stage.ring || !hotOn || ringMissed) return null;
    ringMissed = true;
    return _slip(M8GridHotlineMistakes.ringMissed);
  }

  /// SLDC's caption has been read: the race begins.
  void orderRead() {
    if (stage == M8Stage.order) stage = M8Stage.shed;
  }

  /// A bay's switch twisted to OFF. A recently shed area is a slip and the
  /// switch springs back; all the right bays OFF ends the shed beat.
  DoMistake? shed(int bay) {
    if (stage != M8Stage.shed || off[bay]) return null;
    if (inc.recent(bay)) {
      recentSlips++;
      return _slip(M8GridHotlineMistakes.recentShed);
    }
    off[bay] = true;
    if (inc.rightBays.every((b) => off[b])) {
      stage = M8Stage.after;
      if (!raceLost) _tag(M8GridHotlineLines.caughtShed);
      if (recentSlips == 0) _tag(M8GridHotlineLines.caughtRotate);
    }
    return null;
  }

  /// The frequency passed 49.0 before the ordered feeders were off (once an
  /// incident; the round still ends with the feeders off).
  DoMistake? raceLose() {
    if (stage != M8Stage.shed || raceLost) return null;
    raceLost = true;
    return _slip(M8GridHotlineMistakes.raceLost);
  }

  /// Listened to the coworker (a slip).
  DoMistake pushSlip(DoMistake m) => _slip(m);

  /// The shed reason is paid: the customer rings.
  void afterReason() {
    if (stage == M8Stage.after) stage = M8Stage.callRing;
  }

  /// The customer deck: a wrong card is a slip; the right one closes the incident.
  DoMistake? consumerSay({required bool right}) {
    if (stage != M8Stage.callSay || consumerDone) return null;
    if (!right) return _slip(M8GridHotlineMistakes.consumerWrong);
    consumerDone = true;
    _tag(M8GridHotlineLines.caughtExplain);
    return null;
  }

  /// The reason that fits this incident's play.
  M8Why get whyNow {
    final w = inc.why;
    if (w == M8Why.hotline && (ringMissed || blackSlipped)) return M8Why.noQuestion;
    return w;
  }

  void next() {
    index++;
    if (!done) _start();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   an incident: the drift ≈ 4500, the ring wait + lift ≈ 4500, SLDC's
///     caption ≈ 2600, the register (open, read, close) ≈ 7000, one or two
///     twists ≈ 3500, the shed reason ≈ 8200, the customer ring + lift +
///     deck ≈ 6500                                                  ≈ 37000
///   two incidents                                                   ≈ 74000
///   + the state question and its reason (once) ≈ 12000
///   + the coworker (once) ≈ 9600                                    ≈ 96000
///   85 % ≈ 82000 → 80 s (a builder's estimate; owner may tune).
const m8GridHotlineQuickMs = 80000;

@immutable
class M8GridHotlinePack {
  const M8GridHotlinePack({required this.id, required this.titleBn, this.quickMs = m8GridHotlineQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8GridHotlinePack> m8GridHotlinePacks = {
  'do_8_4_a': M8GridHotlinePack(id: 'do_8_4_a', titleBn: M8GridHotlineLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8GridHotlineProbe {
  static M8GridRun? run;

  /// The frequency now (the page owns the clock).
  static double Function()? freq;
  static M8Phones Function()? phones;
  static bool regOpen = false;
}

// ============================================================================
// Page
// ============================================================================

class M8GridHotlinePage extends StatefulWidget {
  const M8GridHotlinePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8GridHotlinePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8GridHotlinePage> createState() => _M8GridHotlinePageState();
}

class _M8GridHotlinePageState extends State<M8GridHotlinePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GridRunPage(
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

class _GridRunPage extends ConsumerStatefulWidget {
  const _GridRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8GridHotlinePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GridRunPage> createState() => _GridRunPageState();
}

/// What the meter's clock is doing.
enum _Phase { idle, drift, race, recover }

/// What a reason is about.
enum _ReasonKind { state, shed }

class _GridRunPageState extends ConsumerState<_GridRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8GridRun _run;
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

  // --- the meter's clock ---------------------------------------------------------
  late final AnimationController _fq = AnimationController(vsync: this, duration: const Duration(seconds: 1), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_fqStatus)
    ..addListener(_onFq);
  var _phase = _Phase.idle;
  double _fFrom = 50;
  double _fTo = 50;
  var _lostFired = false;
  final List<double> _hist = [];
  double _lastHist = 0;

  // --- the phones ----------------------------------------------------------------
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(seconds: 1), animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener(_ringStatus)
    ..addListener(_onRing);
  final _phones = ValueNotifier<M8Phones>(const M8Phones());
  double _ringTotal = 1000;
  var _ringIsCall = false;
  var _ringHotStarted = false;
  var _ringMissFired = false;
  int _lastCycle = -1;
  M8Phone? _grab;
  double _grabY = 0;
  var _orderRunning = false;

  // --- the panel -----------------------------------------------------------------
  final _drag = ValueNotifier<M8BayDrag?>(null);
  int? _bayI;
  double? _bayLast;
  double _bayProg = 0;
  final List<int> _bayTaps = List.filled(kM8Bays, 0);
  int? _touchedBay;
  var _regOpen = false;
  double _regDrag = 0;

  // --- decks ---------------------------------------------------------------------
  List<ChoiceOption> _deck = const [];
  final Map<String, M8State> _deckState = {};
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  int _deckN = 0;
  var _reasonKind = _ReasonKind.shed;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _steps = 0;
  M8GridGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8GridRun(m8GridDeal(widget.rng));
    M8GridHotlineProbe.run = _run;
    M8GridHotlineProbe.freq = _freqNow;
    M8GridHotlineProbe.phones = () => _phones.value;
    M8GridHotlineProbe.regOpen = false;
    _fFrom = _fTo = _run.inc.fStart;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _fq.dispose();
    _ring.dispose();
    _phones.dispose();
    _drag.dispose();
    _chain++;
    if (identical(M8GridHotlineProbe.run, _run)) {
      M8GridHotlineProbe.run = null;
      M8GridHotlineProbe.freq = null;
      M8GridHotlineProbe.phones = null;
      M8GridHotlineProbe.regOpen = false;
    }
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

  M8Incident get _inc => _run.inc;
  M8Stage get _stage => _run.stage;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen;

  String get _task => switch (_stage) {
        M8Stage.watch => M8GridHotlineLines.askWatch,
        M8Stage.state => M8GridHotlineLines.askState,
        M8Stage.ring => M8GridHotlineLines.askRing,
        M8Stage.order => M8GridHotlineLines.askOrder,
        M8Stage.shed => M8GridHotlineLines.askShed,
        M8Stage.after => M8GridHotlineLines.askShed,
        M8Stage.callRing => M8GridHotlineLines.askCall,
        M8Stage.callSay => M8GridHotlineLines.askSay,
      };

  /// The task, in its other wording for a repeat.
  String get _taskOther => switch (_stage) {
        M8Stage.watch => M8GridHotlineLines.askWatchOther,
        M8Stage.ring => M8GridHotlineLines.askRingOther,
        M8Stage.shed => M8GridHotlineLines.askShedOther,
        _ => _task,
      };

  // --- the meter's clock ---------------------------------------------------------
  double _freqNow() => _fFrom + (_fTo - _fFrom) * _fq.value;

  double _dimNow() => _phase == _Phase.recover ? _fq.value : 0;

  void _startPhase(_Phase p, double from, double to, int ms) {
    _phase = p;
    _fFrom = from;
    _fTo = to;
    _fq.duration = Duration(milliseconds: math.max(1, ms));
    _fq.value = 0;
  }

  /// Run or hold the clocks to match the play: a card, the coworker, a deck or
  /// the intro hold them still (idle = zero frames).
  void _syncClock() {
    if (!mounted) return;
    final base = _ended || _intro || _card != null;
    final bool fq = switch (_phase) {
      _Phase.idle => false,
      _Phase.drift => !base && !coworkerOpen && !reasonOpen && !tableBusy && _stage == M8Stage.watch,
      _Phase.race => !base && !coworkerOpen && _stage == M8Stage.shed,
      _Phase.recover => !_ended && _card == null,
    };
    if (fq && !_fq.isAnimating && _fq.value < 1) {
      unawaited(_fq.forward());
    } else if (!fq && _fq.isAnimating) {
      _fq.stop(canceled: false);
    }
    final ring = _ringActive && !base && !coworkerOpen && _ring.value < 1;
    if (ring && !_ring.isAnimating) {
      unawaited(_ring.forward());
    } else if (!ring && _ring.isAnimating) {
      _ring.stop(canceled: false);
    }
  }

  bool get _ringActive => _stage == M8Stage.ring || _stage == M8Stage.callRing;

  void _onFq() {
    final f = _freqNow();
    if ((f - _lastHist).abs() >= 0.012 || _hist.isEmpty) {
      _lastHist = f;
      _hist.add(f);
      if (_hist.length > 40) _hist.removeAt(0);
    }
    if (_phase == _Phase.race && !_lostFired && f <= kM8Danger) {
      _lostFired = true;
      scheduleMicrotask(() {
        if (mounted) unawaited(_raceLost());
      });
    }
  }

  void _fqStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;
    if (_phase == _Phase.drift && _stage == M8Stage.watch) {
      scheduleMicrotask(() {
        if (mounted) _driftDone();
      });
    }
  }

  // --- an incident -----------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    _startIncident();
  }

  void _startIncident() {
    setState(() {
      _wake++;
      _phase = _Phase.idle;
      _fFrom = _fTo = _inc.fStart;
      _fq.value = 0;
      _hist.clear();
      _lastHist = _inc.fStart;
      _ring.value = 0;
      _phones.value = const M8Phones();
      _regOpen = false;
      M8GridHotlineProbe.regOpen = false;
      _touchedBay = null;
      for (var i = 0; i < kM8Bays; i++) {
        _bayTaps[i] = 0;
      }
      _drag.value = null;
      _bayI = null;
      _grab = null;
      _orderRunning = false;
      _closeDeck();
    });
    if (_stage == M8Stage.state) {
      setState(_openDeck);
      unawaited(_sayChain([_task]));
      return;
    }
    unawaited(_sayChain([_task]));
    _runDrift();
  }

  void _runDrift() {
    final f = _freqNow();
    final span = _inc.fStart - _inc.fRing;
    final frac = span <= 0 ? 0.0 : ((f - _inc.fRing) / span).clamp(0.0, 1.0);
    setState(() => _startPhase(_Phase.drift, f, _inc.fRing, math.max(300, (_inc.driftMs * frac).round())));
  }

  void _driftDone() {
    if (_ended || _stage != M8Stage.watch) return;
    _run.driftDone();
    if (_stage == M8Stage.state) {
      setState(() {
        _phase = _Phase.idle;
        _openDeck();
        _wake++;
      });
      unawaited(_sayChain([_task]));
      return;
    }
    _beginRing();
  }

  // --- the phones ----------------------------------------------------------------
  void _beginRing() {
    _phase = _Phase.idle;
    _ringIsCall = false;
    _ringHotStarted = _inc.leadMs == 0;
    _ringMissFired = false;
    _lastCycle = -1;
    _ringTotal = _inc.ringTotalMs.toDouble();
    _ring.duration = Duration(milliseconds: _inc.ringTotalMs);
    _ring.value = 0;
    setState(() {
      _wake++;
      _phones.value = M8Phones(hotRinging: _run.hotOn, blackRinging: _run.blackOn);
    });
    _steps++;
    unawaited(_sayChain([_task]));
  }

  void _beginConsumerRing() {
    _ringIsCall = true;
    _ringHotStarted = true;
    _ringMissFired = true;
    _lastCycle = -1;
    _ringTotal = (4 * kM8RingMs).toDouble();
    _ring.duration = Duration(milliseconds: 4 * kM8RingMs);
    _ring.value = 0;
    setState(() {
      _wake++;
      _phones.value = const M8Phones(blackRinging: true);
    });
    _steps++;
    unawaited(_sayChain([_task]));
  }

  void _onRing() {
    if (!_ringActive) return;
    final ms = _ring.value * _ringTotal;
    if (!_ringIsCall && !_ringHotStarted && ms >= _inc.leadMs) {
      _ringHotStarted = true;
      _run.hotStarts();
      _phones.value = _phones.value.copyWith(hotRinging: true);
    }
    if (!_ringIsCall && !_ringMissFired && ms >= _inc.missAtMs) {
      _ringMissFired = true;
      scheduleMicrotask(() {
        if (mounted) unawaited(_ringMiss());
      });
    }
    final cyc = ms ~/ kM8RingMs;
    if (cyc != _lastCycle) {
      _lastCycle = cyc;
      final p = _phones.value;
      if (p.hotRinging) _cue('sounds/learn/dmm_beep.ogg', volume: 0.6);
      if (p.blackRinging) _cue('sounds/learn/ring_steel.ogg', volume: 0.35);
    }
  }

  void _ringStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted || !_ringActive) return;
    // Nobody lifted it: the lamp stays lit, the desk is still.
    _phones.value = _phones.value.copyWith(
      hotRinging: false,
      blackRinging: false,
      hotLit: !_ringIsCall,
      blackLit: _ringIsCall || _inc.blackMode != M8BlackMode.none,
    );
  }

  Future<void> _ringMiss() async {
    final m = _run.ringExpired();
    if (m == null) return;
    unawaited(_levelDelta(-10, Offset(MediaQuery.sizeOf(context).width / 2, 300), mood: GuideMood.warn));
    await _slip(m);
  }

  void _setLift(M8Phone p, double v) {
    _phones.value = p == M8Phone.hot ? _phones.value.copyWith(hotLift: v) : _phones.value.copyWith(blackLift: v);
  }

  void _commitLift(M8Phone p, Offset at) {
    final res = _run.lift(p);
    final DoMistake? m = res == M8Lift.blackSlip ? _run.blackSlip() : null;
    switch (res) {
      case M8Lift.ignored:
        _setLift(p, 0);
      case M8Lift.blackSlip:
        _setLift(p, 0);
        unawaited(_mistake(m!, at));
      case M8Lift.hot:
        _tick('sounds/intro/click.ogg', 0.6);
        _ring.stop(canceled: false);
        _phones.value = M8Phones(hotLift: 34, blackLit: false);
        _steps++;
        setState(() => _wake++);
        unawaited(_runOrder());
      case M8Lift.call:
        _tick('sounds/intro/click.ogg', 0.6);
        _ring.stop(canceled: false);
        _phones.value = const M8Phones(blackLift: 34);
        _steps++;
        setState(() {
          _wake++;
          _openDeck();
        });
        unawaited(_sayChain([_task]));
    }
  }

  // --- the order and the race ----------------------------------------------------
  Future<void> _runOrder() async {
    if (_orderRunning) return;
    _orderRunning = true;
    final idx = _run.index;
    unawaited(_sayChain([_task]));
    final line = M8GridHotlineLines.orderLine(_inc.n);
    await Future<void>.delayed(MascotSpeechLibrary.readHold(line));
    if (!mounted || _ended || _run.index != idx) return;
    _run.orderRead();
    _orderRunning = false;
    _phones.value = const M8Phones();
    _lostFired = false;
    _steps++;
    setState(() {
      _wake++;
      _startPhase(_Phase.race, _inc.fRing, kM8RaceFloor, _inc.raceTotalMs.round());
    });
    if (idx == _run.deal.coworkerIncident && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  Future<void> _raceLost() async {
    final m = _run.raceLose();
    if (m == null) return;
    setState(() => _wake++);
    unawaited(_levelDelta(-10, Offset(MediaQuery.sizeOf(context).width / 2, 300), mood: GuideMood.warn));
    await _slip(m);
  }

  // --- the decks ---------------------------------------------------------------
  void _closeDeck() {
    _deck = const [];
    _deckState.clear();
    _deckWrong.clear();
    _deckPicked = null;
  }

  void _openDeck() {
    _closeDeck();
    _deckN++;
    final rng = widget.rng;
    switch (_stage) {
      case M8Stage.state:
        final opts = <ChoiceOption>[];
        for (final s in M8State.values) {
          final l = M8GridHotlineLines.states[s]!;
          final t = l[rng.nextInt(l.length)];
          _deckState[t] = s;
          opts.add(ChoiceOption(t, s == _run.deal.readState));
        }
        _deck = opts..shuffle(rng);
      case M8Stage.callSay:
        _deck = dealChoices(M8GridHotlineLines.consumerRight, M8GridHotlineLines.consumerWrong, rng);
      default:
        break;
    }
  }

  bool get _ownDeckUp =>
      _deck.isNotEmpty && _card == null && ((_stage == M8Stage.state && !_run.stateAnswered) || (_stage == M8Stage.callSay && !_run.consumerDone));

  void _pickDeck(ChoiceOption o, Offset at) {
    if (!_canPlay || !_ownDeckUp) return;
    if (_stage == M8Stage.state) {
      final m = _run.answerState(_deckState[o.textBn]!);
      if (m != null) {
        setState(() {
          _deckWrong.add(o.textBn);
          _wake++;
        });
        unawaited(_mistake(m, at));
        return;
      }
      _tick('sounds/intro/click.ogg', 0.6);
      setState(() => _deckPicked = o.textBn);
      _stepDone();
      unawaited(_stateDone());
      return;
    }
    final m = _run.consumerSay(right: o.correct);
    if (m != null) {
      setState(() {
        _deckWrong.add(o.textBn);
        _wake++;
      });
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    setState(() => _deckPicked = o.textBn);
    _stepDone();
    final idx = _run.index;
    unawaited(_levelDelta(10, at, mood: GuideMood.glad));
    unawaited(_sayChain([M8GridHotlineLines.consumerHeld], mood: GuideMood.glad));
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 1700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the register and the switches ---------------------------------------------
  void _openRegister() {
    if (!_canPlay || _stage != M8Stage.shed || _regOpen) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() {
      _regOpen = true;
      M8GridHotlineProbe.regOpen = true;
      _regDrag = 0;
    });
    _steps++;
  }

  void _closeRegister() {
    if (!_regOpen) return;
    _tick();
    setState(() {
      _regOpen = false;
      M8GridHotlineProbe.regOpen = false;
    });
    _steps++;
  }

  void _tapScene(Offset p, M8GridGeo geo) {
    if (!_canPlay || _regOpen) return;
    if (_stage == M8Stage.shed) {
      if (geo.register.contains(p)) {
        _openRegister();
        return;
      }
      for (var i = 0; i < kM8Bays; i++) {
        if (geo.switchHit(i).contains(p)) {
          _bayTaps[i]++;
          _touchedBay = i;
          _tick('sounds/intro/click.ogg', 0.3);
          _hints.missTap();
          return;
        }
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

  void _panStart(Offset p, M8GridGeo geo) {
    _grab = null;
    _bayI = null;
    _bayLast = null;
    if (!_canPlay || _regOpen) return;
    if (_stage == M8Stage.ring || _stage == M8Stage.callRing) {
      if (geo.hotline.contains(p)) {
        _grab = M8Phone.hot;
      } else if (geo.blackPhone.contains(p)) {
        _grab = M8Phone.black;
      } else {
        _hints.missTap();
        return;
      }
      _grabY = p.dy;
      return;
    }
    if (_stage == M8Stage.shed) {
      for (var i = 0; i < kM8Bays; i++) {
        if (!geo.switchHit(i).contains(p)) continue;
        if (_run.off[i]) {
          _hints.missTap();
          return;
        }
        // The decisive control: the coworker comes before the first twist.
        if (holdForCoworker()) return;
        _bayI = i;
        _bayProg = 0;
        _touchedBay = i;
        final d = p - geo.knob(i);
        _bayLast = d.distance < 6 ? null : math.atan2(d.dy, d.dx);
        _drag.value = M8BayDrag(i, 0);
        return;
      }
      _hints.missTap();
    }
  }

  void _panUpdate(Offset p, Offset global, M8GridGeo geo) {
    final g = _grab;
    if (g != null) {
      if (!_canPlay) {
        _setLift(g, 0);
        _grab = null;
        return;
      }
      final lift = (_grabY - p.dy).clamp(0.0, 60.0);
      _setLift(g, lift);
      if (lift >= 34) {
        _grab = null;
        _commitLift(g, global);
      }
      return;
    }
    final i = _bayI;
    if (i == null) return;
    if (!_canPlay) {
      _bayI = null;
      _drag.value = null;
      return;
    }
    final d = p - geo.knob(i);
    if (d.distance < 6) return;
    final a = math.atan2(d.dy, d.dx);
    final last = _bayLast;
    _bayLast = a;
    if (last == null) return;
    // Clockwise on screen (the angle grows) twists toward OFF; a quarter turn.
    _bayProg = (_bayProg + _wrap(a - last) / (math.pi / 2)).clamp(0.0, 1.0);
    _drag.value = M8BayDrag(i, _bayProg);
    if (_bayProg >= 0.85) {
      _bayI = null;
      _commitShed(i, global);
    }
  }

  void _panEnd() {
    final g = _grab;
    if (g != null) {
      _setLift(g, 0);
      _grab = null;
    }
    if (_bayI != null) {
      // Let go before the stop: the switch springs back.
      _bayI = null;
      _drag.value = null;
      _stepDone();
    }
  }

  void _commitShed(int bay, Offset at) {
    final m = _run.shed(bay);
    _drag.value = null;
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/intro/impact_metal.ogg', 0.5);
    _steps++;
    setState(() => _wake++);
    if (_run.stage == M8Stage.after) unawaited(_shedDone());
  }

  Future<void> _shedDone() async {
    _hush();
    setState(() {
      _regOpen = false;
      M8GridHotlineProbe.regOpen = false;
      _startPhase(_Phase.recover, _freqNow(), kM8Recovered, kM8RecoverMs);
    });
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    _reasonKind = _ReasonKind.shed;
    final topic = _run.whyNow;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M8GridHotlineLines.whyRight[topic]!, M8GridHotlineLines.myths, widget.rng),
      question: M8GridHotlineLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Future<void> _stateDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(10);
    _reasonKind = _ReasonKind.state;
    final truth = _run.deal.readState;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M8GridHotlineLines.stateWhyRight[truth]!, M8GridHotlineLines.myths, widget.rng),
      question: M8GridHotlineLines.whyQ[M8Why.state]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startIncident();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  // --- the shared success beat (ReasonTable) ---------------------------------------
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
    if (_reasonKind == _ReasonKind.state) {
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
        if (!mounted || _ended || _run.index != idx) return;
        setState(() {
          _closeDeck();
          _run.afterState();
          _wake++;
        });
        if (_stage == M8Stage.watch) {
          _runDrift();
        } else {
          _beginRing();
        }
      }));
      return;
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended || _run.index != idx) return;
      _run.afterReason();
      setState(() {
        _closeDeck();
        _wake++;
      });
      _beginConsumerRing();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------------
  @override
  CoworkerScript get coworkerScript => M8GridHotlineLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerIncident) return null;
    if (_stage.index > M8Stage.shed.index) return null;
    if (_stage != M8Stage.shed) return false;
    if (_intro || _card != null || tableBusy || _regOpen) return false;
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
      final m = M8GridHotlineMistakes.push(p);
      _run.pushSlip(m);
      // 'Call SLDC first': the race loses 3 s while he talks the player round.
      if (p == M8Push.ask && _phase == _Phase.race) {
        final extra = 3000 / _inc.raceTotalMs;
        _fq.value = math.min(1.0, _fq.value + extra);
      }
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8GridHotlineLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8GridHotlineLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8GridHotlineLines.tapWhy[_nudgeN++ % M8GridHotlineLines.tapWhy.length]
            : _nudge.next(_nudgeN++ % 2 == 0 ? _task : _taskOther);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _fq.stop(canceled: false);
    _ring.stop(canceled: false);
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
    final speak = await SpokenOnce.first('m8grid/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same incident goes on from where it was.
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
    await _say(!_run.passed ? M8GridHotlineLines.fail : (_quickBonus ? M8GridHotlineLines.quick : M8GridHotlineLines.allSet),
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
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_grab != null || _bayI != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what (see the header comment).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_stage) {
      case M8Stage.ring:
        if (!_run.hotOn) return null;
        if (_run.blackOn) return HintSpec.sweep([geo.hotline, geo.blackPhone], space: HintSpace.scene);
        return HintSpec.drag(geo.hotline.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M8Stage.callRing:
        return HintSpec.drag(geo.blackPhone.center, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M8Stage.shed:
        if (_regOpen) return HintSpec.swipe(geo.registerHandle.center, toward: const Offset(0, 1), travel: 60, space: HintSpace.scene);
        final t = _touchedBay;
        if (t != null && _bayTaps[t] >= 2) {
          // Touched twice but not twisted: the arc, on THAT switch.
          final th = kM8KnobOn;
          return HintSpec.drag(geo.knob(t) + Offset(math.cos(th), math.sin(th)) * 14, toward: Offset(-math.sin(th), math.cos(th)), travel: 24, space: HintSpace.scene);
        }
        // Over every switch and the register, the same way; none pressed.
        return HintSpec.sweep([for (var i = 0; i < kM8Bays; i++) geo.switchHit(i), geo.register], space: HintSpace.scene);
      case M8Stage.watch || M8Stage.state || M8Stage.order || M8Stage.after || M8Stage.callSay:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8GridGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final inc = _inc;
    final names = [for (var b = 0; b < kM8Bays; b++) inc.bayName(b)];
    final captionOn = _stage == M8Stage.order || _stage == M8Stage.callSay;
    return [
      Positioned.fill(
        key: const ValueKey('room'),
        child: RepaintBoundary(child: CustomPaint(painter: M8RoomPainter(geo: geo, lit: [for (var i = 0; i < kM8Bays; i++) !_run.off[i]], storm: inc.cause == M8Cause.storm))),
      ),
      Positioned.fill(
        key: const ValueKey('meter'),
        child: RepaintBoundary(child: CustomPaint(painter: M8MeterPainter(geo: geo, freq: _freqNow, hist: _hist, dim: _dimNow, repaint: _fq))),
      ),
      Positioned.fill(
        key: const ValueKey('bays'),
        child: RepaintBoundary(child: CustomPaint(painter: M8BayPainter(geo: geo, names: names, off: [..._run.off], drag: _drag))),
      ),
      Positioned.fill(
        key: const ValueKey('desk'),
        child: RepaintBoundary(child: CustomPaint(painter: M8DeskPainter(geo: geo, phones: _phones, ring: _ring, ringMs: () => _ringTotal))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8GridHotlineLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, d.globalPosition, geo),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      if (captionOn)
        Positioned.fromRect(
          key: ValueKey('caption-${_stage.name}-${_run.index}'),
          rect: geo.caption,
          child: IgnorePointer(
            child: _CaptionBubble(
              tag: _stage == M8Stage.order ? M8GridHotlineLines.sldcTag : M8GridHotlineLines.customerTag,
              text: _stage == M8Stage.order ? M8GridHotlineLines.orderLine(inc.n) : M8GridHotlineLines.customerCaptions[inc.customer],
            ),
          ),
        ),
      if (_regOpen) ..._registerLayers(geo, inc),
      // The next incident: a short fade.
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

  List<Widget> _registerLayers(M8GridGeo geo, M8Incident inc) => [
        Positioned.fill(
          key: const ValueKey('register'),
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: M8RegisterPainter(
                  geo: geo,
                  areas: inc.areas,
                  dates: [for (var q = 0; q < 3; q++) M8GridHotlineLines.date(inc.day - 3 + q)],
                  marks: inc.marks,
                ),
              ),
            ),
          ),
        ),
        // The page takes touches (nothing under it is reachable).
        Positioned.fromRect(
          key: const ValueKey('register-body'),
          rect: geo.registerPanel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
        ),
        Positioned.fromRect(
          key: const ValueKey('register-handle'),
          rect: geo.registerHandle,
          child: Semantics(
            button: true,
            label: M8GridHotlineLines.registerLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeRegister,
              onVerticalDragStart: (_) => _regDrag = 0,
              onVerticalDragUpdate: (d) {
                _regDrag += d.delta.dy;
                if (_regDrag > 24) _closeRegister();
              },
            ),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    // Run or hold the meter's and the phones' clocks to match what is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncClock());
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final ownDeck = _ownDeckUp;
    final deckUp = reasonOpen || coworkerChoiceUp || ownDeck;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null;
    final waiting = handsOn && !tableBusy && switch (_stage) {
      M8Stage.ring => _run.hotOn,
      M8Stage.callRing || M8Stage.shed => true,
      _ => false,
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
              labels: [for (var i = 0; i < _run.count; i++) M8GridHotlineLines.incidentName(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, _run.count); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.index}/$_steps/${_stage.name}/$_regOpen/${_touchedBay ?? -1}',
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
                  line: M8GridHotlineLines.intro,
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
}

// ============================================================================
// Pieces
// ============================================================================

/// A silent caption bubble (SLDC's order, the customer's words).
class _CaptionBubble extends StatelessWidget {
  const _CaptionBubble({required this.tag, required this.text});
  final String tag;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xEE0B1324),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.6),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(8)),
            child: Text(tag, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: SlmColors.ivory))),
        ],
      ),
    );
  }
}
