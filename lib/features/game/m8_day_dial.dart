import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_day_dial_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_day_dial_world.dart'
    show M8DayAct, M8DayGeo, M8DayKind, M8DayStop, M8DayUse, M8DayZone, m8DayActs, m8DayCardOf, m8DayDark, m8DayIsMisuse, m8DayMid, m8DayRange, m8DayTruthOf, m8DayZoneOf;

// Lesson 8.7 "ট্যারিফ অর্ডার (Tariff Order): বিদ্যুতের দামের হিসাব", কাজ
// "দিনভর নজর" (pack do_8_7_b, rung 8.7/do/1, engineType m8_day_dial).
// A meter-reading round along a village-market road: four stops, the factory
// always one of them (dealt position) and three others dealt from a house, a
// house with a front-room shop, a roadside shop, a field pump house and a pump
// house where a car is washed — at least one honest and one misuse among them.
//
// The core verb: drag the sun through a day. A sky arc runs from dawn (left)
// to midnight (right) with a draggable sun that becomes the moon; the sky, the
// shadows, the lights and what runs at the premises follow it. The three stamps
// (ডোমেস্টিক · কমার্শিয়াল · কৃষি) stay locked until the sun has passed all
// four parts of the day at this stop — at every stop, so unlocking reveals
// nothing. Then drag the stamp of the use SEEN onto the book line 'চোখে দেখা
// ব্যবহার':
//  = what really runs → right (a stamp that differs from the meter's card
//    writes 'ক্যাটাগরি ভুল · Sec 126'; one that matches writes 'রিডিং নোট');
//  a stamp that differs from what runs → slip: a needless note on an honest
//    premises, or a missed misuse (the card's category stamped on a house that
//    ran a shop fridge, a farm pump that washed a car).
// The factory has no category card (not a lesson category): after the full-day
// watch a bracket 'মেশিন চলে' sits over the evening and the owner asks
// 'বিল কমাতে কী করব?'. Drag the bracket along the arc: midnight (night) is
// right; dropped in the evening it is a slip; in the morning or noon it
// slides back at no cost. If the bill shows 'PF পেনাল্টি' (about half the
// plays) a 3-card advice deck follows (a wrong card is a field slip).
//
// No deadly in lesson 8.7 (rulings M8-1, R7): everything here is billing and
// paperwork; every mistake is a slip (3 strike out). Wrong "why" cards cost
// the table ◆ only (M8-8).
//
// The coworker comes once a play at a dealt non-factory stop, on arrival,
// before the first sun drag (the drag and the stamp wait for him through
// holdForCoworker). Listening = slip (B1: nothing on this level is deadly).
//
// Gesture hands (how, never what): the sun gets a 48 dp nudge forward along
// the arc (its only control); at the stamps a sweep over the three alike, then
// a 40 dp lift from the pad's gap (never from a stamp); the bracket a 40 dp
// straight-up lift. Decks bring their own. Off during the intro, the walk
// between stops, the praise window, the coworker, cards and results.

// ============================================================================
// Content
// ============================================================================

abstract final class M8DayDialLines {
  static const title = 'দিনভর নজর';
  // DRAFT wording — owner (M6-12 / M8-14): every line below until the owner
  // gives the natural wording.
  static const intro = 'আজ রিডিং-এর রাউন্ড — শুধু রিডিং নয়, কোডটাও মিলিয়ে দেখুন!';

  // The guide's task (tap him: the next of the stage's pool, from the start).
  static const watch = 'দিনভর কী চলে, দেখুন।';
  static const watchTasks = [watch, 'সূর্যটাকে টেনে দিনটা চালান।', 'সকাল থেকে রাত, সবটা দেখে নিন।'];
  static const stampTasks = ['যা চলতে দেখলেন, তার ছাপ বসান।', 'চোখে দেখা ব্যবহারের ছাপ দিন।', 'রিডিং বইয়ের লাইনে ছাপ বসান।'];
  static const billTasks = ['মালিক বিল কমাতে চান।', 'মেশিনের সময়টা ভেবে দেখুন।', 'ব্র্যাকেটটা ঠিক জায়গায় বসান।'];
  static const adviceTasks = ['বিলে PF পেনাল্টি — মালিককে কী বলবেন?', 'মালিককে ঠিক পরামর্শটা দিন।', 'ওঁকে কী করতে বলবেন?'];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // What a worker reads on the scene and the book.
  static const cardHead = 'Type of Consumer';
  static const bookTitle = 'চোখে দেখা ব্যবহার';
  static const bookOk = 'রিডিং নোট';
  static const bookBad = 'ক্যাটাগরি ভুল · Sec 126';
  static const bracketLabel = 'মেশিন চলে';
  static const ownerAsks = 'বিল কমাতে কী করব?';
  static const billFixed = 'ফিক্সড চার্জ';
  static const billEnergy = 'এনার্জি চার্জ';
  static const billPf = 'PF পেনাল্টি';
  static const sceneLabel = 'রিডিং-এর রাউন্ড';
  static const sunLabel = 'সূর্য';

  static String useName(M8DayUse u) => switch (u) {
        M8DayUse.domestic => 'ডোমেস্টিক',
        M8DayUse.commercial => 'কমার্শিয়াল',
        M8DayUse.agri => 'কৃষি',
      };

  static String stampLabel(M8DayUse u) => '${useName(u)} ছাপ';

  static String stopName(M8DayKind k) => switch (k) {
        M8DayKind.house || M8DayKind.fridgeHouse => 'বাড়ি',
        M8DayKind.shop => 'দোকান',
        M8DayKind.pump || M8DayKind.carPump => 'পাম্প ঘর',
        M8DayKind.factory => 'কারখানা',
      };

  // The reasons (the right ones state the lesson's rule for what the player
  // just did; the wrong ones are myths and field excuses).
  static const whyStampQ = 'কেন এই ছাপ দিলেন?';
  static const whyFridgeQ = 'দোকানের ফ্রিজ বাড়ির মিটারে চললে কী হয়?';
  static const whyCarQ = 'চাষের পাম্পে গাড়ি ধোয়া কেন ধরলেন?';
  static const whyBracketQ = 'মেশিন কেন মাঝরাতে সরালেন?';
  static const whyCapQ = 'কেন ক্যাপাসিটর ব্যাংক দেখতে বললেন?';
  static const whyQs = [whyStampQ, whyFridgeQ, whyCarQ, whyBracketQ, whyCapQ];

  static const whyRight = <M8DayWhy, List<String>>{
    M8DayWhy.stamp: ['সারাদিন যা চলল, কার্ডের ক্যাটাগরির সঙ্গে মিলে গেল', 'ব্যবহার আর Type of Consumer কোড মিলল, নোট লাগবে না'],
    M8DayWhy.fridge: ['বাড়ির রেট কম, দোকান চালালে সেকশন 126-এ জরিমানা', 'ভুল ক্যাটাগরিতে ব্যবহার আইনত আলাদা, জরিমানা হয়'],
    M8DayWhy.car: ['চাষের পাম্পে গ্যারেজ চালানো বড় অপরাধ, তাই ধরলাম', 'কৃষির সস্তা রেটে ব্যবসা চালানো বড় অপরাধ আইনত'],
    M8DayWhy.bracket: ['মাঝরাতে অফ-পিকে দাম কম, সন্ধেতে পিকে বেশি থাকে', 'অফ-পিক রাতে মেশিন চালালে প্রতি ইউনিটে খরচ কম'],
    M8DayWhy.capbank: ['PF কম হলে বিলে পেনাল্টি লাগে, তাই ব্যাংক দেখা দরকার', 'কম PF-এর পেনাল্টি এড়াতে ক্যাপাসিটর ব্যাংক চেক করাই'],
  };
  static const _wrongBy = <M8DayWhy, List<String>>{
    M8DayWhy.stamp: [
      'কার্ডের ছাপটাই ধরলেই হয়, আলাদা করে দেখতে হয় না',
      'সন্দেহ হলে সব মিটারেই ভুলের নোট দিয়ে দিন',
      'ছাপ যা-ই দিই, বিলে তো আর কিছুই বদলায় না',
      'ক্যাটাগরি মেলানো রিডারের কাজের মধ্যে পড়ে না',
      'দিনভর বসে দেখা সময় নষ্ট, রিডিংই আসল কাজ',
      'ছোট মিটারে ক্যাটাগরির নিয়ম আর খাটে না, ছাড়ুন',
    ],
    M8DayWhy.fridge: [
      'কিছুই হয় না, ফ্রিজ তো সব ঘরেই থাকে, চিন্তা নেই',
      'একই মিটার, তাই বিলে কোনো ফারাক পড়ে না আসলে',
      'ছোট দোকান হলে ক্যাটাগরির নিয়ম আর খাটে না',
      'বাড়ির লোকের ব্যাপার, কোম্পানির দেখার কিছু নেই',
      'শুধু বিল একটু বেশি আসবে, এর বেশি কিছু নয়',
    ],
    M8DayWhy.car: [
      'জল তো একই পাম্পের, কিছু যায় আসে না তাতে',
      'গাড়ি ধোয়াও তো এক ধরনের কাজ, দোষ নেই কোনো',
      'এক-আধ ঘণ্টার ব্যাপার, কেউ ধরবে না এসব নিয়ে',
      'পাম্প যার, জলও তার, যা খুশি চালাতে পারে সে',
      'রাতে চললে অন্য কেউ দেখবে না, ঠিক আছে তাই',
    ],
    M8DayWhy.bracket: [
      'রাতে মিটার ধীরে ঘোরে, তাই কম মাপে ওটা বেশ',
      'রাতে মিটার রিডার দেখে না, ধরা পড়বে না তাই',
      'মাঝরাতে চালালে ফিক্সড চার্জ লাগে না কোনোটাই',
      'সকালের দাম সবচেয়ে বেশি, তাই সরানো হলো তো',
      'রাতে মেশিন ঠান্ডা থাকে, কম বিদ্যুৎ টানে তাই',
    ],
    M8DayWhy.capbank: [
      'ক্যাপাসিটর ব্যাংক ঠিক থাকলে মিটার ধীরে ঘোরে আর',
      'পেনাল্টি মিটার রিডারের হাতে, ব্যাংকের কী দোষ তাতে',
      'ব্যাংক বদলালে ফিক্সড চার্জ মকুব হয়ে যায় বিলে',
      'পেনাল্টি শুধু বড় কোম্পানির বিলেই বসে থাকে',
      'ক্যাপাসিটর ব্যাংক ঠিক থাকলে MVCA আর লাগে না',
    ],
  };

  static String whyQ(M8DayWhy w) => switch (w) {
        M8DayWhy.stamp => whyStampQ,
        M8DayWhy.fridge => whyFridgeQ,
        M8DayWhy.car => whyCarQ,
        M8DayWhy.bracket => whyBracketQ,
        M8DayWhy.capbank => whyCapQ,
      };
  static List<String> whyWrong(M8DayWhy w) => _wrongBy[w]!;
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in _wrongBy.values) ...l];

  // The PF advice deck (a field decision: a wrong card is a slip).
  static const adviceRight = ['আগে ক্যাপাসিটর ব্যাংক চেক করান', 'ক্যাপাসিটর ব্যাংকটা চেক করান ভালো করে'];
  static const adviceWrong = [
    'পেনাল্টি সবার বিলেই আসে, ধরবেন না',
    'মিটারটা পাল্টে নতুন লাগিয়ে নিন',
    'কারখানার লোড আরও কিছুটা বাড়িয়ে দিন',
    'অফিসে বলুন বিলটা আবার ছাপিয়ে দিতে',
    'রিডারকে বলুন বিলটা কমিয়ে দিতে',
    'নতুন ট্রান্সফরমার লাগিয়ে নিন',
  ];

  // The careless coworker (DRAFT wording — owner; M8-14).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'কোড-টোড দেখার দরকার নেই, রিডিংটা লিখে চলো।',
    exitLine: coworkerExit,
    right: [
      'না, Type of Consumer কোড মিলিয়ে দেখতেই হবে',
      'না, কোড ঠিক আছে কি না দেখাও আমাদের কাজ',
      'রিডিং তো লিখবই, কোডটাও মিলিয়ে নেব সঙ্গে',
    ],
    wrong: [
      'হ্যাঁ, কোড মেলানো আমাদের কাজ নয়, রিডিংই যথেষ্ট',
      'হ্যাঁ, রিডিং লিখলেই কাজ শেষ, কোড বড় সাহেবদের',
      'ঠিক, কোড দেখতে গেলে রাউন্ড শেষ হতে দেরি হবে',
      'তাই করি, এত ঘুরে ঘুরে দেখার সময় কোথায়',
      'ঠিক বলেছ, কোড নিয়ে মাথা ঘামানোর কেউ নেই',
    ],
    asks: ['ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! মিটার দেখার সময় কোড মিলিয়ে দেখা আমাদেরই কাজ।';

  static const allSet = 'রাউন্ড শেষ — দিনভর নজর রেখে ঠিক হিসাব এনেছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দিনভর নজর রাখুন, কোডটাও মিলিয়ে দেখুন।';

  // "আজ যা ধরলেন".
  static String caughtStop(M8DayStop s) => switch (s.kind) {
        M8DayKind.fridgeHouse => 'বাড়ির মিটারে দোকানের ফ্রিজ — $bookBad',
        M8DayKind.carPump => 'চাষের পাম্পে গাড়ি ধোয়া — $bookBad',
        M8DayKind.house => 'বাড়ির ব্যবহার ঠিক — ডোমেস্টিক ছাপ',
        M8DayKind.shop => 'দোকানের ব্যবহার ঠিক — কমার্শিয়াল ছাপ',
        M8DayKind.pump => 'পাম্পের ব্যবহার ঠিক — কৃষি ছাপ',
        M8DayKind.factory => 'কারখানার মেশিন মাঝরাতে, অফ-পিকে',
      };
  static const caughtPf = 'PF পেনাল্টি — ক্যাপাসিটর ব্যাংক চেক';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (the exit, the old asks, the
  /// old why taps, the quick-pass line).
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', quick};
  static const _oldWhyTaps = {'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...watchTasks,
        ...stampTasks,
        ...billTasks,
        ...adviceTasks,
        ...tapWhy.where((l) => !_oldWhyTaps.contains(l)),
        ...whyQs,
        ...coworker.asks.where((a) => !reused.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M8DayDialMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused, ...tapWhy];
}

/// The "why" questions.
enum M8DayWhy { stamp, fridge, car, bracket, capbank }

abstract final class M8DayDialMistakes {
  static const _dir = 'assets/game/art/m8_day_dial';

  // Lesson 8.7 points (0-based, across both sections): 0 ফিক্সড চার্জ,
  // 1 এনার্জি চার্জ, 2 ডোমেস্টিক বনাম কমার্শিয়াল, 3 চাষের সংযোগ.
  static const _catPoint = 2;
  static const _farmPoint = 3;

  // DRAFT wording — owner (M6-12). A needless note on an honest premises.
  static const needlessHouse = DoMistake(
    key: '8.7/m8_day_dial/needless-house',
    textBn: 'এই বাড়িতে সারাদিন ঘরের কাজেই বিদ্যুৎ চলেছে — ক্যাটাগরি ঠিক আছে, ভুল ক্যাটাগরির নোট দরকার ছিল না।',
    art: '$_dir/needless_house.svg',
    lessonPoint: _catPoint,
  );
  static const needlessShop = DoMistake(
    key: '8.7/m8_day_dial/needless-shop',
    textBn: 'দোকানে সারাদিন দোকানের কাজেই বিদ্যুৎ চলেছে — ক্যাটাগরি ঠিক আছে, ভুল ক্যাটাগরির নোট দরকার ছিল না।',
    art: '$_dir/needless_shop.svg',
    lessonPoint: _catPoint,
  );
  static const needlessPump = DoMistake(
    key: '8.7/m8_day_dial/needless-pump',
    textBn: 'পাম্পে সারাদিন চাষের কাজেই বিদ্যুৎ চলেছে — ক্যাটাগরি ঠিক আছে, ভুল ক্যাটাগরির নোট দরকার ছিল না।',
    art: '$_dir/needless_pump.svg',
    lessonPoint: _farmPoint,
  );

  // The card's category stamped on a premises that ran another use.
  static const missedFridge = DoMistake(
    key: '8.7/m8_day_dial/missed-fridge',
    textBn: 'বাড়ির মিটারে দোকানের ফ্রিজ চলছিল — আইনত আলাদা, ভুল ক্যাটাগরিতে বিদ্যুৎ ব্যবহারে সেকশন 126 অনুযায়ী জরিমানা হয়।',
    art: '$_dir/missed_fridge.svg',
    lessonPoint: _catPoint,
  );
  static const missedCar = DoMistake(
    key: '8.7/m8_day_dial/missed-car',
    textBn: 'চাষের জল পাম্প দিয়ে গাড়ি ধোয়ার গ্যারেজ চলছিল — এটা বড় অপরাধ।',
    art: '$_dir/missed_car.svg',
    lessonPoint: _farmPoint,
  );

  // The factory.
  static const bracketEvening = DoMistake(
    key: '8.7/m8_day_dial/bracket-evening',
    textBn: 'পিক আওয়ারে (সন্ধেবেলা) দাম বেশি, অফ-পিক আওয়ারে (মাঝরাতে) কম — মেশিন সন্ধেতেই থেকে গেল।',
    art: '$_dir/bracket_evening.svg',
  );
  static const pfWrong = DoMistake(
    key: '8.7/m8_day_dial/pf-wrong-advice',
    textBn: 'কারখানার পাওয়ার ফ্যাক্টর (PF) কম হলে বিলে পেনাল্টি লাগে — মালিককে ক্যাপাসিটর ব্যাংক চেক করতে বলুন।',
    art: '$_dir/pf_wrong.svg',
  );

  // Listening to the coworker (the lesson's daily check and Sec 126; B1).
  static const pushListen = DoMistake(
    key: '8.7/m8_day_dial/push-listen',
    textBn: 'একেবারেই নয়। মিটার দেখার সময় Type of Consumer কোড ঠিক আছে কি না মিলিয়ে দেখতে হয় — ভুল ক্যাটাগরিতে ব্যবহারে সেকশন 126 অনুযায়ী জরিমানা হয়।',
    art: '$_dir/push_listen.svg',
    lessonPoint: _catPoint,
  );

  static DoMistake needless(M8DayKind k) => switch (k) {
        M8DayKind.shop => needlessShop,
        M8DayKind.pump => needlessPump,
        _ => needlessHouse,
      };

  static DoMistake missed(M8DayKind k) => k == M8DayKind.carPump ? missedCar : missedFridge;

  static const List<DoMistake> all = [needlessHouse, needlessShop, needlessPump, missedFridge, missedCar, bracketEvening, pfWrong, pushListen];
}

// ============================================================================
// Deal and rules
// ============================================================================

@immutable
class M8DayDeal {
  const M8DayDeal({required this.stops, required this.coworkerStop});

  /// The four stops in round order (the factory once).
  final List<M8DayStop> stops;

  /// The stop the coworker comes in at (never the factory).
  final int coworkerStop;
}

const _honestKinds = [M8DayKind.house, M8DayKind.shop, M8DayKind.pump];
const _misuseKinds = [M8DayKind.fridgeHouse, M8DayKind.carPump];

M8DayStop m8DayDealStop(M8DayKind k, math.Random rng) {
  final misuse = m8DayIsMisuse(k);
  return M8DayStop(
    kind: k,
    variant: rng.nextInt(3),
    misuseZone: misuse ? const [M8DayZone.morning, M8DayZone.noon, M8DayZone.evening][rng.nextInt(3)] : null,
    pf: k == M8DayKind.factory && rng.nextBool(),
    mirror: rng.nextBool(),
  );
}

M8DayDeal m8DayDeal(math.Random rng) {
  // Three premises (≥ 1 honest and ≥ 1 misuse) and the factory in a dealt place.
  final misuse = _misuseKinds[rng.nextInt(2)];
  final honest = _honestKinds[rng.nextInt(3)];
  final rest = [..._honestKinds, ..._misuseKinds]..removeWhere((k) => k == misuse || k == honest);
  final third = rest[rng.nextInt(rest.length)];
  final three = [misuse, honest, third]..shuffle(rng);
  final kinds = [...three]..insert(rng.nextInt(4), M8DayKind.factory);
  final stops = [for (final k in kinds) m8DayDealStop(k, rng)];
  final cw = [for (var i = 0; i < stops.length; i++) if (!stops[i].factory) i];
  return M8DayDeal(stops: stops, coworkerStop: cw[rng.nextInt(cw.length)]);
}

/// Where a play's stop stands.
enum M8DayStage { watch, stamp, bracket, advice, finished }

/// What a stamp did.
enum M8DayStamp { locked, right, slip }

/// What a dropped bracket did.
enum M8DayBracket { notNow, notMoved, bounced, right, slip }

/// The play state (pure logic).
class M8DayRun {
  M8DayRun(this.deal);
  final M8DayDeal deal;

  int index = 0;
  int slips = 0;
  M8DayStage stage = M8DayStage.watch;

  /// The parts of the day the sun has passed at this stop.
  final Set<M8DayZone> visited = {};

  /// The stamp put on the line (right ones only).
  M8DayUse? stamped;

  /// Where the factory's machine runs now.
  M8DayZone machine = M8DayZone.evening;

  final List<String> caught = [];

  M8DayStop get stop => deal.stops[index.clamp(0, deal.stops.length - 1)];
  bool get done => index >= deal.stops.length;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get unlocked => visited.length == M8DayZone.values.length;

  /// The remark the book writes for the right stamp.
  String get remark => stamped != null && stamped != stop.card ? M8DayDialLines.bookBad : M8DayDialLines.bookOk;

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// The sun moved from [a] to [b]: every part of the day in between counts as
  /// passed. True when this move completed the day (the stop unlocks).
  bool pass(double a, double b) {
    if (done || stage != M8DayStage.watch) return false;
    final lo = math.min(a, b), hi = math.max(a, b);
    for (final z in M8DayZone.values) {
      final (zl, zh) = m8DayRange(z);
      if (hi >= zl && lo < zh) visited.add(z);
    }
    if (!unlocked) return false;
    stage = stop.factory ? M8DayStage.bracket : M8DayStage.stamp;
    return true;
  }

  /// A stamp dropped on the line: right (what runs), or a slip.
  (M8DayStamp, DoMistake?) stamp(M8DayUse u) {
    if (done || stage != M8DayStage.stamp || stop.factory) return (M8DayStamp.locked, null);
    if (u == stop.truth) {
      stamped = u;
      stage = M8DayStage.finished;
      caught.add(M8DayDialLines.caughtStop(stop));
      return (M8DayStamp.right, null);
    }
    // Honest premises: the stamp differs from the card (and from what runs) →
    // a needless note. A misuse premises: the stamp misses what ran.
    return (M8DayStamp.slip, _slip(stop.misuse ? M8DayDialMistakes.missed(stop.kind) : M8DayDialMistakes.needless(stop.kind)));
  }

  /// The factory's bracket let go in [z] ([moved]: it was dragged a real way).
  (M8DayBracket, DoMistake?) dropBracket(M8DayZone z, {required bool moved}) {
    if (done || stage != M8DayStage.bracket) return (M8DayBracket.notNow, null);
    if (!moved) return (M8DayBracket.notMoved, null);
    switch (z) {
      case M8DayZone.night:
        machine = M8DayZone.night;
        stage = stop.pf ? M8DayStage.advice : M8DayStage.finished;
        caught.add(M8DayDialLines.caughtStop(stop));
        return (M8DayBracket.right, null);
      case M8DayZone.evening:
        return (M8DayBracket.slip, _slip(M8DayDialMistakes.bracketEvening));
      case M8DayZone.morning || M8DayZone.noon:
        return (M8DayBracket.bounced, null);
    }
  }

  /// A card of the PF advice deck.
  DoMistake? advice({required bool right}) {
    if (done || stage != M8DayStage.advice) return null;
    if (!right) return _slip(M8DayDialMistakes.pfWrong);
    stage = M8DayStage.finished;
    caught.add(M8DayDialLines.caughtPf);
    return null;
  }

  /// Listened to the coworker.
  DoMistake pushSlip() => _slip(M8DayDialMistakes.pushListen);

  void next() {
    index++;
    stage = M8DayStage.watch;
    visited.clear();
    stamped = null;
    machine = M8DayZone.evening;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per premises (3): arrival 1500, the sun dragged through the day ~5000,
///     a stamp ~3000, the reason ~8200                         ≈ 17700 × 3 = 53100
///   + the factory: the day ~5000, the bracket ~3500, its reason ~8200,
///     the PF deck + reason on half the plays (~5700)         ≈ 22400
///   + the coworker once                                       ≈  9600
///                                                              ≈ 85100
/// 85 % ≈ 72300 → 70 s (a builder's estimate; owner may tune after playtest).
const m8DayDialQuickMs = 70000;

@immutable
class M8DayDialPack {
  const M8DayDialPack({required this.id, required this.titleBn, this.quickMs = m8DayDialQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8DayDialPack> m8DayDialPacks = {
  'do_8_7_b': M8DayDialPack(id: 'do_8_7_b', titleBn: M8DayDialLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8DayDialProbe {
  static M8DayRun? run;
  static ValueNotifier<double>? sun;
  static ValueNotifier<double>? bracket;
}

// ============================================================================
// Page
// ============================================================================

class M8DayDialPage extends StatefulWidget {
  const M8DayDialPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8DayDialPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8DayDialPage> createState() => _M8DayDialPageState();
}

class _M8DayDialPageState extends State<M8DayDialPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DayRunPage(
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

class _DayRunPage extends ConsumerStatefulWidget {
  const _DayRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8DayDialPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DayRunPage> createState() => _DayRunPageState();
}

class _DayRunPageState extends ConsumerState<_DayRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8DayRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// Sun-time, the bracket's centre, where the factory's machine runs: moved
  /// without rebuilding the page (only their painters repaint).
  final _t = ValueNotifier<double>(0);
  final _bracketT = ValueNotifier<double>(m8DayMid(M8DayZone.evening));
  final _machine = ValueNotifier<M8DayZone>(M8DayZone.evening);

  /// The veil between stops, and the glide of the sun to a new hour.
  late final AnimationController _veil = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _glide = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  VoidCallback? _glideListener;

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  final List<DoMistake> _cardQueue = [];
  VoidCallback? _afterCards;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  int _taskN = 0;
  int _whyN = 0;
  int _steps = 0;
  int _stopHintN = 0;

  /// Between two stops (the veil is down or coming up).
  var _moving = false;

  /// Hands: the sun, a stamp in hand (its pin, design px), the bracket.
  var _sunDrag = false;
  int? _stampDrag;
  Offset _dragAt = Offset.zero;
  var _bracketDrag = false;
  double _bracketFrom = 0;
  double _bracketGrab = 0;
  double _prevT = 0;
  M8DayZone _zoneNow = M8DayZone.morning;

  /// The PF advice deck (a field decision).
  List<ChoiceOption> _deck = const [];
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  int _deckN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  M8DayGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8DayRun(m8DayDeal(widget.rng));
    M8DayDialProbe.run = _run;
    M8DayDialProbe.sun = _t;
    M8DayDialProbe.bracket = _bracketT;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M8DayDialProbe.run, _run)) {
      M8DayDialProbe.run = null;
      M8DayDialProbe.sun = null;
      M8DayDialProbe.bracket = null;
    }
    _veil.dispose();
    _glide.dispose();
    _t.dispose();
    _bracketT.dispose();
    _machine.dispose();
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_moving && !_run.done && !struckOut;

  bool get _atHisStop => _run.index == _run.deal.coworkerStop;

  /// The sun stands in the sky (at the stamps and while watching; the factory's
  /// bracket and the advice take the arc over).
  bool get _sunShown => _run.stage == M8DayStage.watch || _run.stage == M8DayStage.stamp;

  List<String> get _tasks => switch (_run.stage) {
        M8DayStage.watch => M8DayDialLines.watchTasks,
        M8DayStage.stamp => M8DayDialLines.stampTasks,
        M8DayStage.bracket => M8DayDialLines.billTasks,
        _ => M8DayDialLines.adviceTasks,
      };

  Future<void> _start() async {
    _clock.start();
    _startStop();
  }

  void _startStop() {
    _prevT = _t.value;
    _zoneNow = m8DayZoneOf(_t.value);
    setState(() {
      _wake++;
      _stopHintN = 0;
      _sunDrag = false;
      _stampDrag = null;
      _bracketDrag = false;
    });
    unawaited(_sayChain([M8DayDialLines.watch]));
    // His stop: he comes on arrival, before the first sun drag.
    if (_atHisStop && !coworkerDone) scheduleCoworker();
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- the sun and the hour ------------------------------------------------------
  void _glideTo(double to, {VoidCallback? done}) {
    final l = _glideListener;
    if (l != null) _glide.removeListener(l);
    _glideListener = null;
    _glide.stop();
    final from = _t.value;
    if (_quiet || (from - to).abs() < 0.001) {
      _t.value = to;
      done?.call();
      return;
    }
    void tick() => _t.value = from + (to - from) * Curves.easeInOut.transform(_glide.value);
    _glideListener = tick;
    _glide
      ..addListener(tick)
      ..forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _glide.removeListener(tick);
        if (identical(_glideListener, tick)) _glideListener = null;
        _t.value = to;
        done?.call();
      });
  }

  void _sunMoved(double nt) {
    final unlockedNow = _run.pass(_prevT, nt);
    _prevT = nt;
    _t.value = nt;
    final z = m8DayZoneOf(nt);
    if (z != _zoneNow) {
      _zoneNow = z;
      _tick('sounds/intro/tick.ogg', 0.3);
    }
    if (unlockedNow) _dayDone();
  }

  /// The sun has passed all four parts of the day at this stop.
  void _dayDone() {
    // The factory's sun leaves the sky for the bracket; elsewhere the finger
    // keeps the sun.
    if (_run.stage == M8DayStage.bracket) _sunDrag = false;
    _stopHintN = 0;
    _stepDone();
    _tick('sounds/intro/click.ogg', 0.6);
    if (_run.stage == M8DayStage.bracket) {
      // The factory: the sky settles on the evening, the bracket over it.
      _bracketT.value = m8DayMid(M8DayZone.evening);
      _glideTo(m8DayMid(M8DayZone.evening));
      unawaited(_sayChain([M8DayDialLines.billTasks.first]));
    } else {
      unawaited(_sayChain([M8DayDialLines.stampTasks.first]));
    }
  }

  // --- hands on -----------------------------------------------------------------
  int? _stampAt(Offset p, M8DayGeo geo) {
    if (_run.stop.factory) return null;
    for (var i = 0; i < 3; i++) {
      if (geo.stamp(i).contains(p)) return i;
    }
    return null;
  }

  void _tapScene(Offset p, M8DayGeo geo) {
    if (!_canPlay) return;
    // The sun, the stamps and the bracket only answer a drag; a tap is a miss.
    _hints.missTap();
  }

  void _panStart(Offset p, M8DayGeo geo) {
    _sunDrag = false;
    _stampDrag = null;
    _bracketDrag = false;
    if (!_canPlay) return;
    final st = _run.stage;
    if (_sunShown && (geo.sunAt(_t.value) - p).distance <= M8DayGeo.sunHit) {
      // His stop: the first drag of the day waits for him.
      if (_atHisStop && holdForCoworker()) return;
      _tick('sounds/intro/click.ogg', 0.4);
      _sunDrag = true;
      setState(() => _wake++);
      return;
    }
    if (st == M8DayStage.bracket && (geo.bracketAt(_bracketT.value) - p).distance <= 40) {
      if (_atHisStop && holdForCoworker()) return;
      _tick('sounds/intro/click.ogg', 0.4);
      _bracketFrom = _bracketT.value;
      _bracketGrab = _bracketT.value - geo.tAtX(p.dx);
      setState(() => _bracketDrag = true);
      return;
    }
    final i = _stampAt(p, geo);
    if (i != null) {
      if (st != M8DayStage.stamp) {
        // Locked until the whole day has been watched (at every stop).
        _hints.missTap();
        return;
      }
      if (_atHisStop && holdForCoworker()) return;
      _tick('sounds/intro/click.ogg', 0.4);
      setState(() {
        _stampDrag = i;
        _dragAt = p.translate(0, -M8DayGeo.lift);
      });
      return;
    }
  }

  void _panUpdate(Offset p, M8DayGeo geo) {
    if (_sunDrag) {
      if (!_canPlay) {
        _sunDrag = false;
        return;
      }
      _sunMoved(geo.tAtX(p.dx));
      return;
    }
    if (_bracketDrag) {
      if (!_canPlay) {
        setState(() => _bracketDrag = false);
        return;
      }
      _bracketT.value = (geo.tAtX(p.dx) + _bracketGrab).clamp(0.115, 0.885);
      return;
    }
    if (_stampDrag != null) {
      if (!_canPlay) {
        setState(() => _stampDrag = null);
        return;
      }
      setState(() => _dragAt = p.translate(0, -M8DayGeo.lift));
    }
  }

  void _panEnd(Offset global) {
    if (_sunDrag) {
      _sunDrag = false;
      setState(() => _wake++);
      return;
    }
    if (_bracketDrag) {
      final bt = _bracketT.value;
      setState(() => _bracketDrag = false);
      _dropBracket(bt, global);
      return;
    }
    final i = _stampDrag;
    if (i != null) {
      final pin = _dragAt;
      setState(() => _stampDrag = null);
      _dropStamp(M8DayUse.values[i], pin, global);
    }
  }

  void _panCancel() {
    _sunDrag = false;
    if (_bracketDrag) {
      _bracketT.value = _bracketFrom;
      setState(() => _bracketDrag = false);
    }
    if (_stampDrag != null) setState(() => _stampDrag = null);
  }

  // --- a stamp -------------------------------------------------------------------
  void _dropStamp(M8DayUse use, Offset pin, Offset global) {
    if (!_canPlay) return;
    final geo = _geoNow;
    if (geo == null) return;
    if (!geo.onSlot(pin)) {
      // Off the line: the stamp springs back (a missed tap for the hand).
      _hints.missTap();
      return;
    }
    if (_atHisStop && holdForCoworker()) return;
    final (res, m) = _run.stamp(use);
    switch (res) {
      case M8DayStamp.locked:
        _tick();
      case M8DayStamp.slip:
        setState(() => _wake++);
        unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M8DayStamp.right:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _stepDone();
        final why = switch (_run.stop.kind) {
          M8DayKind.fridgeHouse => M8DayWhy.fridge,
          M8DayKind.carPump => M8DayWhy.car,
          _ => M8DayWhy.stamp,
        };
        _reasonFor(why, 15);
    }
  }

  /// A right move: its ◆ on the table, the reason deck at once.
  void _reasonFor(M8DayWhy why, int amount) {
    _hush();
    putOnTable(amount);
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M8DayDialLines.whyRight[why]!, M8DayDialLines.whyWrong(why), widget.rng),
      question: M8DayDialLines.whyQ(why),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  // --- the bracket ---------------------------------------------------------------
  void _dropBracket(double bt, Offset global) {
    if (!_canPlay) {
      _bracketT.value = _bracketFrom;
      return;
    }
    final z = m8DayZoneOf(bt);
    final moved = (bt - _bracketFrom).abs() >= 0.05;
    if (_atHisStop && holdForCoworker()) {
      _bracketT.value = _bracketFrom;
      return;
    }
    final (res, m) = _run.dropBracket(z, moved: moved);
    switch (res) {
      case M8DayBracket.notNow:
        _bracketT.value = _bracketFrom;
      case M8DayBracket.notMoved:
        _bracketT.value = _bracketFrom;
        _hints.missTap();
      case M8DayBracket.bounced:
        // Morning or noon: no cost, it slides back.
        _bracketT.value = _bracketFrom;
        _tick();
      case M8DayBracket.slip:
        _bracketT.value = _bracketFrom;
        setState(() => _wake++);
        unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M8DayBracket.right:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _machine.value = M8DayZone.night;
        _stepDone();
        // The day turns over to the night, the machine running there; the
        // reason deck is dealt once the sky has settled.
        putOnTable(15);
        _hush();
        _glideTo(m8DayMid(M8DayZone.night), done: () {
          if (!mounted || _ended) return;
          final idx = _run.index;
          unawaited(askReason(
            deal: () => dealChoices(M8DayDialLines.whyRight[M8DayWhy.bracket]!, M8DayDialLines.whyWrong(M8DayWhy.bracket), widget.rng),
            question: M8DayDialLines.whyBracketQ,
            stillValid: () => _run.index == idx && !_ended,
          ));
        });
    }
  }

  // --- the PF advice deck ----------------------------------------------------------
  bool get _adviceUp => _run.stage == M8DayStage.advice && _deck.isNotEmpty && !_run.done && _card == null && !reasonOpen && !tableBusy && !coworkerOpen;

  void _openAdvice() {
    _deckN++;
    _deckWrong.clear();
    _deckPicked = null;
    _deck = dealChoices(M8DayDialLines.adviceRight, M8DayDialLines.adviceWrong, widget.rng);
    setState(() => _wake++);
    unawaited(_sayChain([M8DayDialLines.adviceTasks.first]));
  }

  void _pickAdvice(ChoiceOption o, Offset at) {
    if (!_canPlay || !_adviceUp) return;
    final m = _run.advice(right: o.correct);
    if (m != null) {
      setState(() {
        _deckWrong.add(o.textBn);
        _wake++;
      });
      unawaited(_levelDelta(-10, at, mood: GuideMood.warn));
      unawaited(_slip(m));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    setState(() => _deckPicked = o.textBn);
    _stepDone();
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted || _ended) return;
      setState(() {
        _deck = const [];
        _deckPicked = null;
      });
      _reasonFor(M8DayWhy.capbank, 10);
    }());
  }

  // --- moving on -------------------------------------------------------------------
  Future<void> _goNext() async {
    if (_ended) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _ended) return;
    if (_quiet) {
      _swapStop();
      return;
    }
    setState(() {
      _moving = true;
      _wake++;
    });
    await _veil.forward();
    if (!mounted || _ended) return;
    _swapStop();
    await _veil.reverse();
    if (!mounted) return;
    setState(() => _moving = false);
  }

  void _swapStop() {
    setState(_run.next);
    _t.value = 0;
    _bracketT.value = m8DayMid(M8DayZone.evening);
    _machine.value = M8DayZone.evening;
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startStop();
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
    if (!mounted) return;
    setState(() => _wake++);
    switch (_run.stage) {
      case M8DayStage.finished:
        unawaited(_goNext());
      case M8DayStage.advice:
        _openAdvice();
      default:
        break;
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8DayDialLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.done || _run.index > _run.deal.coworkerStop) return null;
    if (!_atHisStop || _intro || _card != null || tableBusy || _moving || _sunDrag || _stampDrag != null || _bracketDrag) return false;
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
    _run.caught.add(M8DayDialLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8DayDialLines.callHeld, _tasks.first], mood: GuideMood.glad));
  }

  /// Tap the guide: the next task line of the stage's pool, from the start.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8DayDialLines.tapWhy[_whyN++ % M8DayDialLines.tapWhy.length]
            : _tasks[++_taskN % _tasks.length];
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _cardQueue.clear();
    _afterCards = null;
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
      _stampDrag = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8day/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    if (_cardQueue.isNotEmpty) {
      unawaited(_slip(_cardQueue.removeAt(0)));
      return;
    }
    final after = _afterCards;
    _afterCards = null;
    if (after != null) {
      after();
      return;
    }
    if (_run.stage == M8DayStage.advice && _deck.isNotEmpty) return;
    unawaited(_sayChain([_tasks.first]));
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
      _moving = false;
    });
    await _say(!_run.passed ? M8DayDialLines.fail : (_quickBonus ? M8DayDialLines.quick : M8DayDialLines.allSet),
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
    if (_moving) return LinemanMode.walk;
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_sunDrag || _stampDrag != null || _bracketDrag) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. The sun is nudged forward
  /// along the arc; at the stamps a sweep over the three alike, then a lift
  /// from the pad's gap; the bracket a straight-up lift.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _stopHintN++;
    switch (_run.stage) {
      case M8DayStage.watch:
        final t = _t.value;
        final dir = geo.tangentAt(t);
        return HintSpec.drag(geo.sunAt(t), toward: t > 0.9 ? -dir : dir, travel: 48, space: HintSpace.scene);
      case M8DayStage.stamp:
        return n.isEven
            ? HintSpec.sweep([for (var i = 0; i < 3; i++) geo.stamp(i)], space: HintSpace.scene)
            : HintSpec.drag(geo.padGap, toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      case M8DayStage.bracket:
        return HintSpec.drag(geo.bracketAt(_bracketT.value), toward: const Offset(0, -1), travel: 40, space: HintSpace.scene);
      default:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8DayGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final stop = _run.stop;
    final factory = stop.factory;
    final st = _run.stage;
    final card = stop.card;
    return [
      Positioned.fill(
        key: const ValueKey('back'),
        child: RepaintBoundary(child: CustomPaint(painter: M8DayBackPainter(geo: geo, t: _t))),
      ),
      Positioned.fill(
        key: ValueKey('premises-${_run.index}'),
        child: RepaintBoundary(child: CustomPaint(painter: M8DayPremisesPainter(geo: geo, stop: stop, t: _t, factoryRun: _machine))),
      ),
      if (card != null)
        Positioned.fromRect(
          key: ValueKey('meter-card-${_run.index}'),
          rect: geo.card(mirror: stop.mirror),
          child: IgnorePointer(child: _MeterCard(use: card)),
        ),
      if (factory) ...[
        Positioned.fromRect(
          key: ValueKey('bill-${_run.index}'),
          rect: geo.billClip(mirror: stop.mirror),
          child: IgnorePointer(child: _BillClip(pf: stop.pf)),
        ),
        if (st == M8DayStage.bracket)
          Positioned.fromRect(
            key: const ValueKey('owner-ask'),
            rect: geo.vRect(96, -2, 250, 34, mirror: stop.mirror),
            child: const IgnorePointer(child: _OwnerBubble()),
          ),
      ],
      // The trainee on the road.
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // The arc, the sun that becomes the moon, and the factory's bracket.
      Positioned.fill(
        key: const ValueKey('arc'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M8DayArcPainter(geo: geo, t: _t, bracketT: _bracketT, sunShown: _sunShown, bracketShown: st == M8DayStage.bracket),
            ),
          ),
        ),
      ),
      if (st == M8DayStage.bracket)
        ValueListenableBuilder<double>(
          key: const ValueKey('bracket-tag'),
          valueListenable: _bracketT,
          builder: (_, bt, _) {
            final o = geo.bracketAt(bt);
            return Positioned(
              left: o.dx - 36,
              top: o.dy - 40,
              width: 72,
              child: IgnorePointer(child: Semantics(label: M8DayDialLines.bracketLabel, child: const _BracketTag())),
            );
          },
        ),
      // The reading book with the stamp pad.
      Positioned.fromRect(
        key: const ValueKey('book'),
        rect: geo.book,
        child: _ReadingBook(geo: geo, run: _run, lifted: _stampDrag, unlocked: st != M8DayStage.watch),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8DayDialLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: _panCancel,
          ),
        ),
      ),
      // The stamp in hand, its pin at the finger's tip.
      if (_stampDrag != null)
        Positioned(
          key: const ValueKey('drag-stamp'),
          left: _dragAt.dx - 52,
          top: _dragAt.dy - 21,
          width: 104,
          height: 42,
          child: IgnorePointer(child: _StampChip(use: M8DayUse.values[_stampDrag!], lifted: true)),
        ),
      // Between stops: a short veil (nothing at all in reduced motion).
      if (!quiet)
        Positioned.fill(
          key: const ValueKey('veil'),
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _veil,
              builder: (_, _) => _veil.value <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, _veil.value)),
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
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp || _adviceUp;
    final handsOn = playing && !_moving && !deckUp && !coworkerOpen && _card == null && !_run.done;
    // The guide stands just above the reading book (screen px).
    final guideBottom = M8DayGeo.bookH * size.width / 360 + pad.bottom * 0.6 + 2;
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
              labels: [for (final s in _run.deal.stops) M8DayDialLines.stopName(s.kind)],
              done: {for (var i = 0; i < math.min(_run.index, _run.deal.stops.length); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_sunDrag && _stampDrag == null && !_bracketDrag && _run.stage != M8DayStage.finished && _run.stage != M8DayStage.advice,
            hintKey: '${_run.index}/${_run.stage.name}/$_steps/${_run.slips}',
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
                                key: ValueKey('advice-deck-$_deckN'),
                                options: _deck,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: _pickAdvice,
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : guideBottom, onLeft: coworkerFromRight),
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
                  line: M8DayDialLines.intro,
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

/// The meter box's card: 'Type of Consumer: …'.
class _MeterCard extends StatelessWidget {
  const _MeterCard({required this.use});
  final M8DayUse use;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${M8DayDialLines.cardHead}: ${M8DayDialLines.useName(use)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1DE),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF6A5232), width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(M8DayDialLines.cardHead, maxLines: 1, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF6A5232), height: 1.1)),
                Text(M8DayDialLines.useName(use), maxLines: 1, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018), height: 1.15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The factory's bill clip: fixed and energy lines (and the PF penalty line
/// on about half the plays). No figures: the lesson gives no rupee rate.
class _BillClip extends StatelessWidget {
  const _BillClip({required this.pf});
  final bool pf;

  @override
  Widget build(BuildContext context) {
    Widget row(String t, {Color color = const Color(0xFF2A2018), bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(t, maxLines: 1, style: bangla(fontSize: 10, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: color, height: 1.1)))),
              Container(width: 14, height: 3, color: color.withValues(alpha: 0.4)),
            ],
          ),
        );
    return Semantics(
      label: [M8DayDialLines.billFixed, M8DayDialLines.billEnergy, if (pf) M8DayDialLines.billPf].join(', '),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF8A6A3C),
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ),
          Positioned.fill(
            left: 4,
            right: 4,
            top: 9,
            bottom: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFF7F1DE), borderRadius: BorderRadius.circular(2)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 4, 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    row(M8DayDialLines.billFixed),
                    row(M8DayDialLines.billEnergy),
                    if (pf) row(M8DayDialLines.billPf, color: const Color(0xFFC62828), bold: true),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -3,
            left: 0,
            right: 0,
            child: Center(child: Container(width: 24, height: 9, decoration: BoxDecoration(color: const Color(0xFF9AA2A8), borderRadius: BorderRadius.circular(3)))),
          ),
        ],
      ),
    );
  }
}

/// The factory owner's question (a silent drawn figure's caption; nothing is
/// read aloud for him).
class _OwnerBubble extends StatelessWidget {
  const _OwnerBubble();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M8DayDialLines.ownerAsks,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3A4660), width: 1.4),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(M8DayDialLines.ownerAsks, maxLines: 1, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1A2438))),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 'মেশিন চলে' tag on the bracket.
class _BracketTag extends StatelessWidget {
  const _BracketTag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2B431),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1A2438), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(M8DayDialLines.bracketLabel, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF1A2438), height: 1.1)),
        ),
      ),
    );
  }
}

/// One stamp of the pad (or in hand while dragged).
class _StampChip extends StatelessWidget {
  const _StampChip({required this.use, this.lifted = false, this.locked = false, this.dim = false});
  final M8DayUse use;
  final bool lifted;
  final bool locked;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = switch (use) {
      M8DayUse.domestic => const Color(0xFF2E6F9A),
      M8DayUse.commercial => const Color(0xFFB5523A),
      M8DayUse.agri => const Color(0xFF3F8A4C),
    };
    return Opacity(
      opacity: dim ? 0.35 : (locked ? 0.55 : 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1DE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c, width: 2),
          boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 9 : 3, offset: Offset(0, lifted ? 5 : 1))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 8, height: 26, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(M8DayDialLines.useName(use), maxLines: 1, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
              ),
            ),
            if (locked) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_rounded, size: 13, color: Color(0xFF6A5232))),
          ],
        ),
      ),
    );
  }
}

/// The reading book: its title, the line the stamp lands on, and the pad of
/// three stamps (locked until the day was watched; none at the factory).
class _ReadingBook extends StatelessWidget {
  const _ReadingBook({required this.geo, required this.run, required this.lifted, required this.unlocked});
  final M8DayGeo geo;
  final M8DayRun run;
  final int? lifted;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final b = geo.book;
    final stamped = run.stamped;
    final slot = geo.slot;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF233A5E), Color(0xFF142540)]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(0, -2))],
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 4,
          right: 14,
          height: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(M8DayDialLines.bookTitle, maxLines: 1, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
          ),
        ),
        // The line the stamp lands on.
        Positioned(
          left: slot.left - b.left,
          top: slot.top - b.top,
          width: slot.width,
          height: slot.height,
          child: Semantics(
            label: M8DayDialLines.bookTitle,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFF7F1DE), borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xFF8A6A3C), width: 1.2)),
              child: stamped == null
                  ? CustomPaint(painter: _RulePainter())
                  : Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC62828), width: 2), borderRadius: BorderRadius.circular(4)),
                          child: Text(M8DayDialLines.useName(stamped), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFC62828))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(run.remark, maxLines: 1, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF3A2A16))),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (!run.stop.factory)
          for (var i = 0; i < 3; i++)
            Positioned(
              left: geo.stamp(i).left - b.left,
              top: geo.stamp(i).top - b.top,
              width: geo.stamp(i).width,
              height: geo.stamp(i).height,
              child: Semantics(
                label: M8DayDialLines.stampLabel(M8DayUse.values[i]),
                child: _StampChip(use: M8DayUse.values[i], locked: !unlocked, dim: lifted == i),
              ),
            ),
      ],
    );
  }
}

class _RulePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0x553A2A16)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(10, size.height * 0.7), Offset(size.width - 10, size.height * 0.7), p);
  }

  @override
  bool shouldRepaint(_RulePainter old) => false;
}
