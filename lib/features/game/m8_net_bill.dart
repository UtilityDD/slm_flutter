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
import 'm8_net_bill_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_net_bill_world.dart' show M8Case, M8Geo, M8Page, M8Season, kM8Looks, kM8Makes, kM8Skies;

// Lesson 8.8 "নেট মিটারিং (Net Metering) রেগুলেশন: সৌরশক্তির নিয়ম", কাজ
// "নেট মিটারের হিসাব" (pack do_8_8_b, rung 8.8/do/1, engineType m8_net_bill).
// Three solar houses on the walk, three visits dealt from four cases:
//  net      a bi-directional meter, the house took more than it gave
//           ('সোলার লাগিয়েছি, তাও বিল আসছে!') → units = IMPORT − EXPORT, বিল,
//           ফিক্সড চার্জ আছে;
//  banked   the same meter, the house gave more than it took (a winter visit,
//           'বেশি দিয়েছি, বিল শূন্য হবে তো?') → units = EXPORT − IMPORT, জমা,
//           ফিক্সড চার্জ আছে (the lesson's banking fact);
//  ordinary an ordinary meter (no arrow, one kWh page) with solar on it → the
//           stamp 'নেট মিটার বাধ্যতামূলক', never units dialled;
//  apply    more solar wanted: flip the slip, slide অনুমোদন to at most the
//           sanctioned load (lesson: 100 %); an application already within the
//           limit is approved whole (cutting it is a needless refusal).
// At least one net or banked house stands second or third (the coworker's).
//
// The core verb: page the meter's registers with its one push button (the
// display shows ONE page at a time, in a dealt order; nothing copies to the
// slip), then work the same blank slip: roll the three digits of নেট ইউনিট,
// set বিল / জমা and ফিক্সড চার্জ আছে / নেই, or press the stamp; on the back
// slide অনুমোদন. Drag the slip's top bar to the consumer to hand it over. The
// slip is judged as a whole there: every wrong field is its own slip card
// and the slip comes back with the fields as they were; a right slip puts ◆
// on the table → "কেন?".
//
// No deadly (ruling M8-1 / R7: bills and paperwork, nobody near a wire).
// Every mistake is a slip; three slips strike out. A wrong 'why' card costs
// the table ◆ only (M8-8).
//
// The coworker (a net or banked house on visit 2 or 3, dealt): he is called
// the first time the player touches the slip there; the hand-over waits for
// him (holdForCoworker). Listening = slip (B1 / X2: nothing deadly here).
//
// Gesture hands (how, never what): the meter unread → a tap on the push
// button (its only control); the slip waiting → in turn a vertical nudge on
// the left digit, then a sweep over every slip control alike; the application
// strip → a horizontal nudge on the knob, alternating. The hand-over is never
// hinted. Off during the intro, pans, the praise window, the coworker, cards
// and results.

// ============================================================================
// Content
// ============================================================================

abstract final class M8NetBillLines {
  static const title = 'নেট মিটারের হিসাব';
  // DRAFT wording — owner (M6-12 / M8-14): every line below until the owner
  // gives the natural wording.
  static const intro = 'আজ তিন সোলার বাড়িতে নালিশ। মিটার পড়ে হিসাব বুঝিয়ে দিন।';

  // The guide's task (tap him: the next of the pool, from the start).
  static const askRead = 'মিটারটা পড়ে নিন।';
  static const askSlip = 'স্লিপে হিসাবটা তুলুন।';
  static const askHand = 'হিসাব ঠিক হলে স্লিপ গ্রাহকের হাতে দিন।';
  static const askApply = 'আবেদনটা দেখে নিন।';
  static const askSlide = 'অনুমোদন কতটা, ঠিক করুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const tasksMeter = [askRead, askSlip, askHand];
  static const tasksApply = [askApply, askSlide, askHand];
  static List<String> tasksFor(M8Case k) => k == M8Case.apply ? tasksApply : tasksMeter;
  static String openingTask(M8Case k) => k == M8Case.apply ? askApply : askRead;

  // The slip and the meter (a worker's own words; English digits).
  static const importWord = 'IMPORT';
  static const exportWord = 'EXPORT';
  static const kwh = 'kWh';
  static const dateWord = 'DATE';
  static const timeWord = 'TIME';
  static const netUnits = 'নেট ইউনিট';
  static const bill = 'বিল';
  static const bank = 'জমা';
  static const fixedYes = 'ফিক্সড চার্জ\nআছে';
  static const fixedNo = 'ফিক্সড চার্জ\nনেই';
  static const stampWord = 'নেট মিটার বাধ্যতামূলক';
  static const flipWord = 'উল্টান';
  static const slipWord = 'স্লিপ';
  static const sanctionWord = 'স্যাংশনড লোড';
  static const askedWord = 'চাওয়া সোলার';
  static const approveWord = 'অনুমোদন';
  static const kw = 'kW';
  static const pushLabel = 'মিটারের বোতাম';
  static const sceneLabel = 'সোলার বাড়ি';
  static const consumerLabel = 'গ্রাহক';

  static String kwText(double v) => enDigits('${v == v.roundToDouble() ? v.round() : v} $kw');

  // The consumer's line (a silent caption, M8-10; two ways each, one dealt).
  static String say(M8Case k, bool alt) => switch (k) {
        M8Case.net => alt ? 'এত সোলার, তবু বিল আসে কেন?' : 'সোলার লাগিয়েছি, তাও বিল আসছে!',
        M8Case.banked => alt ? 'এ মাসে আমার সোলার বেশিই দিয়েছে, বিল শূন্য হবে তো?' : 'এ মাসে তো আমি বেশি দিয়েছি, বিল শূন্য হবে তো?',
        M8Case.ordinary => alt ? 'সোলার তো লাগালাম, তবু বিল আরও বেড়ে গেল!' : 'সোলার লাগানোর পর বিল উল্টে বেড়ে গেল!',
        M8Case.apply => alt ? 'ছাদে আরও প্যানেল বসাতে চাই, দেখুন তো।' : 'আরও সোলার বসাতে চাই, আবেদনটা দেখুন।',
      };
  static const sayShed = 'লোড শেডিং-এ ফ্যান চলে না কেন?';
  static List<String> get allSays => [
        for (final k in M8Case.values) ...[say(k, false), say(k, true)],
        sayShed,
      ];

  // The reasons ("কেন?"): the right ones state the lesson's rule; the wrong
  // ones are myths and field excuses.
  static const whyNet = 'গ্রাহককে বিলটা কীভাবে বোঝালেন?';
  static const whyBank = 'বেশি দিয়েছেন, তবু বিল শূন্য নয় কেন?';
  static const whyOrdinary = 'এই মিটারে সোলার কেন চলবে না?';
  static const whyCut = 'আবেদনের সোলার কেন কমালেন?';
  static const whyWhole = 'আবেদনটা পুরো মঞ্জুর করলেন কেন?';
  static const whyShed = 'লোড শেডিং-এ ফ্যান কেন চলে না?';
  static List<String> get allWhyQ => [whyNet, whyBank, whyOrdinary, whyCut, whyWhole, whyShed];

  static String whyQ(M8Reason r) => switch (r) {
        M8Reason.net => whyNet,
        M8Reason.bank => whyBank,
        M8Reason.ordinary => whyOrdinary,
        M8Reason.cut => whyCut,
        M8Reason.whole => whyWhole,
        M8Reason.shed => whyShed,
      };

  static const whyRight = <M8Reason, List<String>>{
    M8Reason.net: ['ব্যবহার আর উৎপাদনের পার্থক্যের বিল, সঙ্গে ফিক্সড চার্জ', 'নেট ইউনিটের বিল আসে, তার সঙ্গে ফিক্সড চার্জও দিতে হয়'],
    M8Reason.bank: ['বাড়তি ইউনিট জমা থাকে, কিন্তু ফিক্সড চার্জ দিতেই হয়', 'জমানো ইউনিট পরে কাজে লাগে, ফিক্সড চার্জ তবু লাগে'],
    M8Reason.ordinary: ['সাধারণ মিটার দেওয়া বিদ্যুৎকেও খরচ দেখায়, বিল বাড়ে', 'সাধারণ মিটারে সোলারের বিদ্যুৎও খরচ ধরা হয়, বিল বাড়ে'],
    M8Reason.cut: ['অনুমোদিত লোডের 100%-এর বেশি সোলার বসানো যায় না', 'স্যাংশনড লোডের 100%-এর ওপরে সোলার বসানো চলে না'],
    M8Reason.whole: ['অনুমোদিত লোডের 100%-এর মধ্যে সোলার বসানো যায়', 'স্যাংশনড লোডের সীমার ভেতরে থাকলে সোলার চলবে'],
    M8Reason.shed: ['অন-গ্রিডে গ্রিড বন্ধ হলে সেফটির জন্য সোলারও বন্ধ', 'চালাতে হলে হাইব্রিড ইনভার্টার আর ব্যাটারি লাগে'],
  };
  static const whyWrong = <M8Reason, List<String>>{
    M8Reason.net: [
      'সোলার থাকলে বিল শূন্য হয়ে যায়, কিছু লাগে না',
      'শুধু গ্রিডের ইউনিট ধরেই পুরো বিল করা হয়েছে',
      'সোলারের ইউনিট মিটার নিজেই কেটে নেয়, বিল নেই',
      'ফিক্সড চার্জ শুধু সাধারণ মিটারের গ্রাহক দেন',
      'সোলারওয়ালাদের বিলের নিয়ম আলাদা, আমরা জানি না',
    ],
    M8Reason.bank: [
      'বাড়তি ইউনিট জমা থাকে না, বিলই শূন্য হয়ে যায়',
      'বেশি দিলে ফিক্সড চার্জ নিজে থেকেই মাফ হয়ে যায়',
      'জমা ইউনিটের টাকা বিল থেকে সরাসরি কেটে নেওয়া হয়',
      'সোলার বেশি দিলে গ্রাহক আর কোনো চার্জ দেন না',
      'গ্রিডে দেওয়া ইউনিটের আলাদা বিল পাঠানো হয়ে থাকে',
    ],
    M8Reason.ordinary: [
      'সাধারণ মিটার সোলারের ইউনিট নিজেই বাদ দিয়ে দেয়',
      'সোলার থাকলে সাধারণ মিটার ধীরে চলে, তাই বিল বাড়ে',
      'সোলারের জন্য মিটারে আলাদা বোতাম টিপতে হয় বলে',
      'সাধারণ মিটার সোলারের ইউনিট গুনতেই পারে না আসলে',
      'সোলার লাগালে সাধারণ মিটারেও বিল কমে যাওয়ার কথা',
    ],
    M8Reason.cut: [
      'ট্রান্সফরমার ছোট বলে সব আবেদনই অর্ধেক করা হয়',
      'বেশি সোলার চাইলে আবেদন সবসময় বাতিল করতে হয়',
      'সোলারের লোড স্যাংশনড লোডের সঙ্গে ধরা হয় না কখনও',
      'ছাদের মাপে যতটা ধরে, ততটাই অনুমোদন দেওয়া যায়',
      'আগে আবেদন করলেই যত খুশি সোলার বসানো চলে যায়',
    ],
    M8Reason.whole: [
      'যে যত চায়, তাকে ততটাই মঞ্জুর করাই নিয়ম এখানে',
      'আবেদন দেখে মঞ্জুর করি, সীমার কথা ভাবতে হয় না',
      'গ্রাহক যা চান, তার অর্ধেকই সবসময় মঞ্জুর হয়',
      'ছাদ বড় হলে লোডের সীমা আর খাটে না কোনোদিন',
      'সোলারের আবেদনে সীমা শুধু বড় গ্রাহকদের জন্যই',
    ],
    M8Reason.shed: [
      'সোলার থাকলে লোড শেডিং-এও ফ্যান চলার কথা ছিল',
      'ইনভার্টার খারাপ হলেই এমন হয়, সোলারের দোষ নেই',
      'নেট মিটার বসালে লোড শেডিং-এও বিদ্যুৎ আসে',
      'গ্রিড বন্ধ হলে সোলারের সব ইউনিট নষ্ট হয়ে যায়',
      'ফ্যানের লোড বেশি বলে সোলার সেটা টানতে পারে না',
    ],
  };

  /// Every right / wrong reason of every group (for the length tests).
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in whyWrong.values) ...l];

  // The careless coworker: his push (DRAFT wording; the lesson's myth 2 and its
  // reality are the refusals, 'ঠিক, সোলার থাকলে বিল লাগে না' the listening).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'সোলারওয়ালার বিল শূন্য লিখে দাও, ফিক্সড চার্জটাও কেটে দাও — গ্রাহক খুশি, ঝামেলাও শেষ।',
    exitLine: coworkerExit,
    right: [
      'না, পার্থক্যের বিল আর ফিক্সড চার্জ — দুটোই লিখব',
      'না, বিল শূন্য হয় না, ফিক্সড চার্জও দিতে হয়',
      'না, নেট ইউনিটের বিল আর ফিক্সড চার্জ লিখব',
    ],
    wrong: [
      'ঠিক বলেছ, সোলার থাকলে তো আর বিল লাগে না',
      'গ্রাহক খুশি থাকলেই হলো, তাই শূন্যই লিখি',
      'বেশ, ফিক্সড চার্জটা এবারের মতো বাদ দিই',
      'আচ্ছা, শূন্য বিলই লিখে স্লিপ দিয়ে দিই',
      'ঠিক, ঝামেলা না বাড়িয়ে ওটাই লিখে দিই',
    ],
    asks: ['ওকে কী বলবেন?', 'কী করবেন?'],
  );
  static const callHeld = 'ঠিক! সোলার থাকলেও পার্থক্যের বিল আর ফিক্সড চার্জ লাগে।';

  static const allSet = 'তিন বাড়ির হিসাব ঠিকঠাক বুঝিয়ে দিলেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মিটার পড়ে স্লিপের প্রতিটা ঘর মিলিয়ে নিন।';

  // "আজ যা ধরলেন".
  static String caughtVisit(M8Visit v, double approved) => enDigits(switch (v.kind) {
        M8Case.net => 'নেট বিল: ${v.netUnits} ইউনিট, সঙ্গে ফিক্সড চার্জ',
        M8Case.banked => 'জমা: ${v.netUnits} ইউনিট, ফিক্সড চার্জ আছে',
        M8Case.ordinary => 'সাধারণ মিটার: নেট মিটার বাধ্যতামূলক',
        M8Case.apply => 'আবেদন: ${kwText(approved)} মঞ্জুর, সীমা ${kwText(v.sanctioned)}',
      });
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (the exit, the old asks,
  /// the old why taps, the quick-pass line).
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?', quick};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askRead,
        askSlip,
        askHand,
        askApply,
        askSlide,
        ...allWhyQ,
        callHeld,
        allSet,
        fail,
        for (final m in M8NetBillMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused];
}

/// The reason groups (which "কেন?" a hand-over asks).
enum M8Reason { net, bank, ordinary, cut, whole, shed }

abstract final class M8NetBillMistakes {
  static const _dir = 'assets/game/art/m8_net_bill';

  /// Lesson 8.8 points (0-based): 0 the bi-directional meter, 3 the install limit.
  static const _meterPoint = 0;
  static const _limitPoint = 3;

  // DRAFT wording — owner (M6-12). All slips (R7, R18; M8-1).
  static const units = DoMistake(
    key: '8.8/m8_net_bill/units',
    textBn: 'নেট ইউনিট মানে IMPORT আর EXPORT-এর পার্থক্য — দুটো পড়ে মিলিয়ে নিন।',
    art: '$_dir/units.svg',
    lessonPoint: _meterPoint,
  );
  static const modeBill = DoMistake(
    key: '8.8/m8_net_bill/mode-bill',
    textBn: 'গ্রাহক গ্রিড থেকে বেশি নিয়েছেন, তাই পার্থক্যের বিল হবে।',
    art: '$_dir/bill.svg',
    lessonPoint: _meterPoint,
  );
  static const modeBank = DoMistake(
    key: '8.8/m8_net_bill/mode-bank',
    textBn: 'গ্রাহক গ্রিডে বেশি দিয়েছেন, তাই বাড়তি ইউনিট জমা থাকবে।',
    art: '$_dir/bank.svg',
  );
  static const fixedOff = DoMistake(
    key: '8.8/m8_net_bill/fixed-off',
    textBn: 'ফিক্সড চার্জ তো দিতেই হবে — সোলার থাকলেও বাদ যায় না।',
    art: '$_dir/fixed.svg',
  );
  static const dialOrdinary = DoMistake(
    key: '8.8/m8_net_bill/dial-ordinary',
    textBn: 'সাধারণ মিটার দেওয়া বিদ্যুৎকেও খরচ দেখায় — ইউনিট বসিয়ে লাভ নেই, নেট মিটার বাধ্যতামূলক।',
    art: '$_dir/ordinary.svg',
    lessonPoint: _meterPoint,
  );
  static const noStamp = DoMistake(
    key: '8.8/m8_net_bill/no-stamp',
    textBn: 'সাধারণ মিটারে সোলার চলবে না — নেট মিটার বাধ্যতামূলক, স্ট্যাম্পটা দিতে হবে।',
    art: '$_dir/ordinary.svg',
    lessonPoint: _meterPoint,
  );
  static const needlessStamp = DoMistake(
    key: '8.8/m8_net_bill/needless-stamp',
    textBn: 'এই মিটার দুই দিকেই মাপে — এখানে নেট মিটারের স্ট্যাম্প লাগে না।',
    art: '$_dir/bidir.svg',
    lessonPoint: _meterPoint,
  );
  static const overLimit = DoMistake(
    key: '8.8/m8_net_bill/over-limit',
    textBn: 'অনুমোদিত লোডের 100%-এর বেশি সোলার বসানো যায় না।',
    art: '$_dir/limit_over.svg',
    lessonPoint: _limitPoint,
  );
  static const needlessCut = DoMistake(
    key: '8.8/m8_net_bill/needless-cut',
    textBn: 'অনুমোদিত লোডের 100% পর্যন্ত সোলার বসানো যায় — এর চেয়ে কম করার কারণ নেই।',
    art: '$_dir/limit_ok.svg',
    lessonPoint: _limitPoint,
  );

  // Listening to the coworker (lesson myth 2 and its reality; X2/B1: a slip).
  static const pushListen = DoMistake(
    key: '8.8/m8_net_bill/push-listen',
    textBn: 'না — সোলার থাকলেও বিল শূন্য হয় না। যতটা ব্যবহার আর যতটা উৎপাদন, তার পার্থক্যের বিল, আর ফিক্সড চার্জ তো দিতেই হবে।',
    art: '$_dir/zero_bill.svg',
  );

  static const List<DoMistake> all = [
    units,
    modeBill,
    modeBank,
    fixedOff,
    dialOrdinary,
    noStamp,
    needlessStamp,
    overLimit,
    needlessCut,
    pushListen,
  ];
}

// ============================================================================
// Deal and rules
// ============================================================================

/// One dealt visit.
@immutable
class M8Visit {
  const M8Visit({
    required this.kind,
    required this.imp,
    required this.exp,
    required this.pages,
    required this.make,
    required this.look,
    required this.season,
    required this.lineAlt,
    required this.shed,
    required this.sanctioned,
    required this.asked,
    required this.dateText,
    required this.timeText,
  });

  final M8Case kind;

  /// The IMPORT and EXPORT registers (an ordinary meter shows [imp] as its one kWh).
  final int imp;
  final int exp;

  /// The display's pages in the order the button pages them (cycling).
  final List<M8Page> pages;
  final int make;
  final int look;
  final M8Season season;

  /// The consumer's alternative wording.
  final bool lineAlt;

  /// The consumer also asks about load shedding (a second reason follows).
  final bool shed;

  /// The application strip (kW): the sanctioned load and what is asked.
  final double sanctioned;
  final double asked;
  final String dateText;
  final String timeText;

  bool get bidirectional => kind != M8Case.ordinary;

  /// What the roller digits must show (net and banked visits).
  int get netUnits => (imp - exp).abs();

  /// The right approval (kW): what is asked, up to the sanctioned load.
  double get expectedKw => math.min(asked, sanctioned);
  bool get askedAbove => asked > sanctioned;

  /// The right "কেন?" of this visit's hand-over.
  M8Reason get reason => switch (kind) {
        M8Case.net => M8Reason.net,
        M8Case.banked => M8Reason.bank,
        M8Case.ordinary => M8Reason.ordinary,
        M8Case.apply => askedAbove ? M8Reason.cut : M8Reason.whole,
      };

  bool get isNetOrBanked => kind == M8Case.net || kind == M8Case.banked;

  String pageValue(M8Page p) => switch (p) {
        M8Page.import || M8Page.kwh => '$imp',
        M8Page.export => '$exp',
        M8Page.date => dateText,
        M8Page.time => timeText,
      };
}

/// The three visits and where the coworker comes.
@immutable
class M8Deal {
  const M8Deal({required this.visits, required this.coworkerVisit});
  final List<M8Visit> visits;

  /// The visit he comes in at (2nd or 3rd; always a net or banked one).
  final int coworkerVisit;
}

bool _round(int v) => v % 10 == 0;

M8Visit m8DealVisit(M8Case kind, math.Random rng) {
  // IMPORT / EXPORT: 100–600, never round; net: import above export by 40–380,
  // banked: export above import by as much.
  var hi = 0, lo = 0;
  while (true) {
    lo = 100 + rng.nextInt(401);
    final d = 40 + rng.nextInt(341);
    hi = lo + d;
    if (hi <= 600 && !_round(lo) && !_round(hi) && !_round(d)) break;
  }
  final swap = kind == M8Case.banked || (kind != M8Case.net && rng.nextBool());
  final imp = swap ? lo : hi;
  final exp = swap ? hi : lo;
  final pages = kind == M8Case.ordinary ? [M8Page.date, M8Page.time, M8Page.kwh] : [M8Page.date, M8Page.time, M8Page.import, M8Page.export];
  pages.shuffle(rng);
  final sanctioned = 2.0 + rng.nextInt(4);
  final asked = switch (rng.nextInt(3)) {
    0 => math.max(1.0, sanctioned - 0.5 * (1 + rng.nextInt(3))),
    1 => sanctioned,
    _ => sanctioned + 0.5 * (1 + rng.nextInt(4)),
  };
  String two(int n) => n.toString().padLeft(2, '0');
  return M8Visit(
    kind: kind,
    imp: imp,
    exp: exp,
    pages: pages,
    make: rng.nextInt(kM8Makes),
    look: rng.nextInt(kM8Looks),
    season: switch (kind) {
      M8Case.banked => M8Season.winter,
      M8Case.net => M8Season.summer,
      _ => rng.nextBool() ? M8Season.winter : M8Season.summer,
    },
    lineAlt: rng.nextBool(),
    shed: rng.nextInt(100) < 35,
    sanctioned: sanctioned,
    asked: asked,
    dateText: '${two(1 + rng.nextInt(28))}-${two(1 + rng.nextInt(12))}-2026',
    timeText: '${two(6 + rng.nextInt(14))}:${two(rng.nextInt(60))}',
  );
}

M8Deal m8NetBillDeal(math.Random rng) {
  bool nb(M8Case k) => k == M8Case.net || k == M8Case.banked;
  List<M8Case> cases;
  do {
    cases = ([...M8Case.values]..shuffle(rng)).take(3).toList();
  } while (!nb(cases[1]) && !nb(cases[2]));
  final his = [for (var i = 1; i < 3; i++) if (nb(cases[i])) i];
  return M8Deal(visits: [for (final k in cases) m8DealVisit(k, rng)], coworkerVisit: his[rng.nextInt(his.length)]);
}

/// The blank slip, the same every visit.
class M8Slip {
  /// The three roller digits (hundreds first).
  final List<int> digits = [0, 0, 0];

  /// বিল (true) / জমা (false); null = not set.
  bool? bill;

  /// ফিক্সড চার্জ আছে (true) / নেই (false); null = not set.
  bool? fixed;
  bool stamped = false;

  /// অনুমোদন on the back (kW), 0.5 steps.
  double approve = 0;

  int get units => digits[0] * 100 + digits[1] * 10 + digits[2];
}

/// The play state (pure logic).
class M8NetRun {
  M8NetRun(this.deal);
  final M8Deal deal;

  int index = 0;
  int slips = 0;
  int visitSlips = 0;

  /// The push button's presses on this visit.
  int presses = 0;
  M8Slip slip = M8Slip();
  final List<String> caught = [];

  M8Visit get visit => deal.visits[index.clamp(0, deal.visits.length - 1)];
  bool get done => index >= deal.visits.length;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  /// The display's page now (null until the button was pressed).
  M8Page? get page => presses == 0 ? null : visit.pages[(presses - 1) % visit.pages.length];

  /// A press of the push button (the next page).
  void press() => presses++;

  /// The wrong fields of the slip as it stands, in slip order (no side effects).
  List<DoMistake> judge() {
    final v = visit, s = slip;
    final m = <DoMistake>[];
    switch (v.kind) {
      case M8Case.net || M8Case.banked:
        if (s.units != v.netUnits) m.add(M8NetBillMistakes.units);
        final wantBill = v.kind == M8Case.net;
        if (s.bill != wantBill) m.add(wantBill ? M8NetBillMistakes.modeBill : M8NetBillMistakes.modeBank);
        if (s.fixed != true) m.add(M8NetBillMistakes.fixedOff);
        if (s.stamped) m.add(M8NetBillMistakes.needlessStamp);
      case M8Case.ordinary:
        if (s.units != 0) {
          m.add(M8NetBillMistakes.dialOrdinary);
        } else if (!s.stamped) {
          m.add(M8NetBillMistakes.noStamp);
        }
        if (s.fixed == false) m.add(M8NetBillMistakes.fixedOff);
      case M8Case.apply:
        if (s.approve > v.sanctioned) {
          m.add(M8NetBillMistakes.overLimit);
        } else if (s.approve < v.expectedKw) {
          m.add(M8NetBillMistakes.needlessCut);
        }
    }
    return m;
  }

  /// The slip handed over: right, or every wrong field as a slip.
  (bool, List<DoMistake>) handOver() {
    if (done) return (false, const []);
    final m = judge();
    if (m.isEmpty) {
      caught.add(M8NetBillLines.caughtVisit(visit, slip.approve));
      return (true, const []);
    }
    slips += m.length;
    visitSlips += m.length;
    return (false, m);
  }

  /// Listened to the coworker.
  DoMistake pushSlip() {
    slips++;
    visitSlips++;
    return M8NetBillMistakes.pushListen;
  }

  void next() {
    index++;
    presses = 0;
    visitSlips = 0;
    slip = M8Slip();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per visit (net): the pan 1600, 4 pages × 1500, 3 digits × 2500, 2 fields
///     × 1500, the hand-over 2500 ≈ 20600; (ordinary) ~11500; (apply) ~8600
///   three visits ≈ 3 × 14000                                        ≈ 42000
///   + a reason for each house (~3.4 × 8200)                         ≈ 28000
///   + the coworker once                                             ≈  9600
///                                                                   ≈ 80000
/// 85 % ≈ 68000 → 70 s (a builder's estimate; owner may tune after playtest).
const m8NetBillQuickMs = 70000;

@immutable
class M8NetBillPack {
  const M8NetBillPack({required this.id, required this.titleBn, this.quickMs = m8NetBillQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8NetBillPack> m8NetBillPacks = {
  'do_8_8_b': M8NetBillPack(id: 'do_8_8_b', titleBn: M8NetBillLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8NetBillProbe {
  static M8NetRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M8NetBillPage extends StatefulWidget {
  const M8NetBillPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8NetBillPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8NetBillPage> createState() => _M8NetBillPageState();
}

class _M8NetBillPageState extends State<M8NetBillPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _NetRunPage(
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

class _NetRunPage extends ConsumerStatefulWidget {
  const _NetRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8NetBillPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_NetRunPage> createState() => _NetRunPageState();
}

class _NetRunPageState extends ConsumerState<_NetRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8NetRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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

  /// The camera walks from the house before ([_from]) to this one.
  var _panning = false;
  int? _from;

  /// The slip: the back is showing; a digit being rolled; the knob; the slip's
  /// ghost while it is carried to the consumer.
  var _flipped = false;
  int? _rolling;
  double _rollAcc = 0;
  var _knobDown = false;
  Offset? _carryAt;
  var _carrying = false;

  /// The consumer's line shows for a moment before the hand may appear.
  var _lineHold = false;

  /// The load-shedding reason of this visit was asked.
  var _shedAsked = false;
  final Set<int> _handed = {};

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M8Geo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8NetRun(m8NetBillDeal(widget.rng));
    M8NetBillProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M8NetBillProbe.run, _run)) M8NetBillProbe.run = null;
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_panning && !_run.done && !struckOut;

  bool get _atHisVisit => _run.index == _run.deal.coworkerVisit;
  bool get _isApply => _run.visit.kind == M8Case.apply;

  /// The slip's controls answer once the meter was read (an application has no meter).
  bool get _slipLive => _isApply || _run.presses > 0;

  Future<void> _start() async {
    _clock.start();
    _startVisit();
  }

  void _startVisit() {
    setState(() {
      _wake++;
      _hintN = 0;
      _flipped = false;
      _rolling = null;
      _knobDown = false;
      _carrying = false;
      _carryAt = null;
      _shedAsked = false;
      _lineHold = true;
    });
    unawaited(Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && _lineHold) setState(() => _lineHold = false);
    }));
    unawaited(_sayChain([M8NetBillLines.openingTask(_run.visit.kind)]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  /// His visit: the first touch of the slip calls him in (the hand-over waits).
  void _callHim() {
    if (_atHisVisit && !coworkerDone && !coworkerDue) scheduleCoworker();
  }

  // --- hands on -----------------------------------------------------------------
  int? _digitAt(Offset p, M8Geo geo) {
    for (var i = 0; i < 3; i++) {
      if (geo.dig(i).inflate(2).contains(p)) return i;
    }
    return null;
  }

  void _tapScene(Offset p, M8Geo geo) {
    if (!_canPlay) return;
    if (geo.flip.inflate(6).contains(p)) {
      _tick();
      setState(() => _flipped = !_flipped);
      _stepDone();
      return;
    }
    if (geo.push.inflate(2).contains(p)) {
      _tick('sounds/intro/click.ogg', 0.5);
      _run.press();
      _stepDone();
      return;
    }
    if (!_flipped && _slipLive) {
      final s = _run.slip;
      if (geo.billSeg.inflate(2).contains(p)) return _setField(() => s.bill = true);
      if (geo.bankSeg.inflate(2).contains(p)) return _setField(() => s.bill = false);
      if (geo.fixYes.inflate(2).contains(p)) return _setField(() => s.fixed = true);
      if (geo.fixNo.inflate(2).contains(p)) return _setField(() => s.fixed = false);
      if (geo.stamp.inflate(2).contains(p)) return _setField(() => s.stamped = !s.stamped);
    }
    _hints.missTap();
  }

  void _setField(VoidCallback set) {
    _tick('sounds/intro/click.ogg', 0.45);
    _callHim();
    set();
    _stepDone();
  }

  void _panStart(Offset p, M8Geo geo) {
    _rolling = null;
    _knobDown = false;
    _carrying = false;
    if (!_canPlay) return;
    if (!_flipped) {
      if (_slipLive) {
        final d = _digitAt(p, geo);
        if (d != null) {
          _rolling = d;
          _rollAcc = 0;
          _callHim();
          return;
        }
      }
      if (geo.handle.contains(p) && _slipLive) {
        _tick('sounds/intro/click.ogg', 0.4);
        _callHim();
        setState(() {
          _carrying = true;
          _carryAt = p;
        });
      }
      return;
    }
    // The back: the knob (an application only) or the slip's bar.
    if (_isApply && geo.knob(_run.slip.approve).inflate(8).contains(p)) {
      _knobDown = true;
      _callHim();
      return;
    }
    if (geo.handle.contains(p) && _slipLive) {
      _tick('sounds/intro/click.ogg', 0.4);
      _callHim();
      setState(() {
        _carrying = true;
        _carryAt = p;
      });
    }
  }

  void _panUpdate(Offset p, double dy, M8Geo geo) {
    if (!_canPlay) {
      if (_carrying || _rolling != null || _knobDown) {
        setState(() {
          _carrying = false;
          _rolling = null;
          _knobDown = false;
        });
      }
      return;
    }
    final r = _rolling;
    if (r != null) {
      // A vertical drag rolls the digit: up = higher, one per 20 px.
      _rollAcc -= dy;
      var changed = false;
      final d = _run.slip.digits;
      while (_rollAcc >= 20) {
        d[r] = (d[r] + 1) % 10;
        _rollAcc -= 20;
        changed = true;
      }
      while (_rollAcc <= -20) {
        d[r] = (d[r] + 9) % 10;
        _rollAcc += 20;
        changed = true;
      }
      if (changed) {
        _tick();
        _steps++;
        setState(() => _wake++);
      }
      return;
    }
    if (_knobDown) {
      final v = geo.kwAt(p.dx);
      if (v != _run.slip.approve) {
        _tick();
        _steps++;
        setState(() => _run.slip.approve = v);
      }
      return;
    }
    if (_carrying) setState(() => _carryAt = p);
  }

  void _panEnd(Offset local, Offset global) {
    final wasCarrying = _carrying;
    final at = _carryAt ?? local;
    final had = _rolling != null || _knobDown;
    setState(() {
      _carrying = false;
      _carryAt = null;
      _rolling = null;
      _knobDown = false;
    });
    if (had) {
      _stepDone();
      return;
    }
    if (!wasCarrying) return;
    final geo = _geoNow;
    if (geo == null || !_canPlay) return;
    if (!geo.handTarget.contains(at)) {
      // Dropped anywhere else: the slip springs back (a missed tap for the hand).
      _hints.missTap();
      return;
    }
    _handOver(global);
  }

  void _handOver(Offset global) {
    if (!_canPlay) return;
    if (_atHisVisit && !coworkerDone) {
      _callHim();
      if (holdForCoworker()) return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    final (ok, cards) = _run.handOver();
    if (!ok) {
      setState(() => _wake++);
      _steps++;
      unawaited(_levelDelta(-10 * cards.length, global, mood: GuideMood.warn));
      _cardQueue
        ..clear()
        ..addAll(cards.skip(1));
      _afterCards = null;
      unawaited(_slip(cards.first));
      return;
    }
    _cue('sounds/intro/confirm.ogg', volume: 0.6);
    _handed.add(_run.index);
    _stepDone();
    putOnTable(15);
    final idx = _run.index;
    final reason = _run.visit.reason;
    unawaited(askReason(
      deal: () => dealChoices(M8NetBillLines.whyRight[reason]!, M8NetBillLines.whyWrong[reason]!, widget.rng),
      question: M8NetBillLines.whyQ(reason),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Future<void> _goNext() async {
    if (_ended) return;
    final from = _run.index;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _ended) return;
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    if (_quiet) {
      _startVisit();
      return;
    }
    setState(() {
      _from = from;
      _panning = true;
      _wake++;
    });
  }

  void _panDone() {
    if (!mounted || !_panning) return;
    setState(() {
      _panning = false;
      _from = null;
    });
    _startVisit();
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
    // The consumer also asked about load shedding: one more reason, then on.
    if (_run.visit.shed && !_shedAsked) {
      _shedAsked = true;
      putOnTable(10);
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M8NetBillLines.whyRight[M8Reason.shed]!, M8NetBillLines.whyWrong[M8Reason.shed]!, widget.rng),
        question: M8NetBillLines.whyShed,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    unawaited(_goNext());
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8NetBillLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.done || _run.index > _run.deal.coworkerVisit || _handed.contains(_run.deal.coworkerVisit)) return null;
    if (!_atHisVisit || _intro || _card != null || tableBusy || _panning || _carrying || _rolling != null || _knobDown) return false;
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
    _run.caught.add(M8NetBillLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8NetBillLines.callHeld, M8NetBillLines.askHand], mood: GuideMood.glad));
  }

  /// Tap the guide: the next task line of the pool, from the start.
  void _tapGuide() {
    if (_intro || _ended) return;
    final tasks = M8NetBillLines.tasksFor(_run.visit.kind);
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8NetBillLines.tapWhy[_whyN++ % M8NetBillLines.tapWhy.length]
            : tasks[++_taskN % tasks.length];
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
      _carrying = false;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8net/${m.key}');
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
    // The slip is back on the clipboard, the fields as they were.
    unawaited(_sayChain([M8NetBillLines.askHand]));
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
    await _say(!_run.passed ? M8NetBillLines.fail : (_quickBonus ? M8NetBillLines.quick : M8NetBillLines.allSet),
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
    if (_panning) return LinemanMode.walk;
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_carrying || _rolling != null || _knobDown) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. The meter unread → a tap on
  /// the push button; the slip waiting → in turn a vertical nudge on the left
  /// digit and a sweep over every slip control alike; the application strip →
  /// a horizontal nudge on the knob, alternating.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final v = _run.visit;
    if (v.kind != M8Case.apply && _run.presses == 0) return HintSpec.tap(geo.push.center, space: HintSpace.scene);
    final n = _hintN++;
    if (_flipped) {
      if (!_isApply) return null;
      return HintSpec.drag(geo.knob(_run.slip.approve).center, toward: Offset(n.isEven ? 1 : -1, 0), travel: 48, space: HintSpace.scene);
    }
    return n.isEven
        ? HintSpec.drag(geo.dig(0).center, toward: const Offset(0, -1), travel: 34, space: HintSpace.scene)
        : HintSpec.sweep(geo.frontControls, space: HintSpace.scene);
  }

  Widget _visitLayer(M8Geo geo, int i, {required bool overlay}) {
    final v = _run.deal.visits[i];
    return Stack(
      children: [
        Positioned.fill(
          key: const ValueKey('house-art'),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M8HousePainter(geo: geo, season: v.season, make: v.make, look: v.look, bidirectional: v.bidirectional, showConsumer: true),
            ),
          ),
        ),
        if (overlay) ...[
          Positioned.fromRect(key: const ValueKey('display'), rect: geo.display, child: IgnorePointer(child: _MeterDisplay(page: _run.page, visit: v, presses: _run.presses))),
          Positioned.fromRect(key: ValueKey('say-$i'), rect: geo.caption, child: IgnorePointer(child: _Say(visit: v, shed: v.shed))),
        ],
      ],
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8Geo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final idx = math.min(_run.index, _run.deal.visits.length - 1);
    final from = _from;
    final v = _run.deal.visits[idx];
    final trainee = geo.trainee;
    return [
      Positioned.fill(
        key: ValueKey('back-$idx'),
        child: RepaintBoundary(child: CustomPaint(painter: M8BackPainter(geo: geo, season: v.season))),
      ),
      if (_panning && from != null)
        Positioned.fill(
          key: ValueKey('pan-$idx'),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeInOut,
            onEnd: _panDone,
            child: _visitLayer(geo, idx, overlay: false),
            builder: (_, t, child) => Stack(
              children: [
                Positioned.fill(left: -360 * t, right: 360 * t, child: _visitLayer(geo, from, overlay: false)),
                Positioned.fill(left: 360 * (1 - t), right: -360 * (1 - t), child: child!),
              ],
            ),
          ),
        )
      else
        Positioned.fill(key: ValueKey('visit-$idx'), child: _visitLayer(geo, idx, overlay: true)),
      if (trainee != null)
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: trainee,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      // The trainee's clipboard.
      Positioned.fill(
        key: const ValueKey('clipboard'),
        child: IgnorePointer(
          child: _Clipboard(
            geo: geo,
            slip: _run.slip,
            visit: v,
            flipped: _flipped,
            live: _slipLive,
            rolling: _rolling,
            wake: _wake,
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8NetBillLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) {
              _lastLocal = d.localPosition;
              _lastGlobal = d.globalPosition;
              _panStart(d.localPosition, geo);
            },
            onPanUpdate: (d) {
              _lastLocal = d.localPosition;
              _lastGlobal = d.globalPosition;
              _panUpdate(d.localPosition, d.delta.dy, geo);
            },
            onPanEnd: (_) => _panEnd(_lastLocal, _lastGlobal),
            onPanCancel: () {
              if (_carrying || _rolling != null || _knobDown) {
                setState(() {
                  _carrying = false;
                  _rolling = null;
                  _knobDown = false;
                });
              }
            },
          ),
        ),
      ),
      // The slip in hand, carried to the consumer.
      if (_carrying && _carryAt != null)
        Positioned(
          key: const ValueKey('carry-slip'),
          left: _carryAt!.dx - 38,
          top: _carryAt!.dy - 52,
          width: 76,
          child: const IgnorePointer(child: _CarrySlip()),
        ),
      // The next house: a short fade in reduced motion.
      if (quiet && !_intro)
        Positioned.fill(
          key: ValueKey('fade-$idx'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: idx == 0 ? 0 : 0.5, end: 0),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  Offset _lastLocal = Offset.zero;
  Offset _lastGlobal = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_panning && !deckUp && !coworkerOpen && _card == null && !_run.done;
    // The guide stands just above the clipboard (screen px).
    final guideBottom = M8Geo.clipH * size.width / 360 + pad.bottom * 0.6 + 2;
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
              labels: [for (var i = 0; i < 3; i++) enDigits('বাড়ি ${i + 1}')],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_lineHold && !_carrying && _rolling == null && !_knobDown,
            hintKey: '${_run.index}/$_steps/${_run.slips}/$_flipped/${_run.presses}',
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
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
                  line: M8NetBillLines.intro,
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

/// The meter's display: one page at a time (dark before the first press).
class _MeterDisplay extends StatelessWidget {
  const _MeterDisplay({required this.page, required this.visit, required this.presses});
  final M8Page? page;
  final M8Visit visit;
  final int presses;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1F2A1A);
    final p = page;
    Widget body;
    if (p == null) {
      body = Center(child: Text('— — —', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink.withValues(alpha: 0.35))));
    } else {
      final big = p == M8Page.import || p == M8Page.export || p == M8Page.kwh;
      final label = switch (p) {
        M8Page.date => M8NetBillLines.dateWord,
        M8Page.time => M8NetBillLines.timeWord,
        M8Page.import => M8NetBillLines.importWord,
        M8Page.export => M8NetBillLines.exportWord,
        M8Page.kwh => '',
      };
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 13,
              child: Row(
                children: [
                  if (p == M8Page.import) const Icon(Icons.arrow_forward, size: 12, color: ink),
                  if (p == M8Page.export) const Icon(Icons.arrow_back, size: 12, color: ink),
                  if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ink, height: 1.1)),
                ],
              ),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(enDigits(visit.pageValue(p)), style: TextStyle(fontSize: big ? 24 : 20, fontWeight: FontWeight.w900, color: ink, fontFeatures: const [FontFeature.tabularFigures()])),
                    if (big) const Padding(padding: EdgeInsets.only(left: 3, bottom: 3), child: Text(M8NetBillLines.kwh, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: ink))),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Semantics(
      label: p == null ? M8NetBillLines.pushLabel : '${M8NetBillLines.pushLabel}: ${visit.pageValue(p)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFB7C9A0),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF7E9068), width: 1),
        ),
        child: body,
      ),
    );
  }
}

/// The consumer's line (a silent caption bubble).
class _Say extends StatelessWidget {
  const _Say({required this.visit, required this.shed});
  final M8Visit visit;
  final bool shed;

  @override
  Widget build(BuildContext context) {
    final lines = [M8NetBillLines.say(visit.kind, visit.lineAlt), if (shed) M8NetBillLines.sayShed];
    return Semantics(
      label: M8NetBillLines.consumerLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB9B2A2), width: 1),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, l) in lines.indexed)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 3),
                      child: Text(l, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF26303D), height: 1.25)),
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

/// The slip in hand while it is carried.
class _CarrySlip extends StatelessWidget {
  const _CarrySlip();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1DE),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF8A6A3C), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Text(M8NetBillLines.slipWord, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
      ),
    );
  }
}

/// The trainee's clipboard: the same blank slip every visit (front: the
/// roller digits, বিল / জমা, ফিক্সড চার্জ, the stamp; back: the application
/// strip). It draws and takes no touch itself (the scene's detector does).
class _Clipboard extends StatelessWidget {
  const _Clipboard({required this.geo, required this.slip, required this.visit, required this.flipped, required this.live, required this.rolling, required this.wake});
  final M8Geo geo;
  final M8Slip slip;
  final M8Visit visit;
  final bool flipped;
  final bool live;
  final int? rolling;
  final int wake;

  static const _paper = Color(0xFFF7F1DE);
  static const _ink = Color(0xFF3A2A16);
  static const _brown = Color(0xFF8A6A3C);

  @override
  Widget build(BuildContext context) {
    final c = geo.clip;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: c,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _brown,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(0, -2))],
            ),
          ),
        ),
        Positioned.fromRect(
          rect: Rect.fromLTRB(c.left + 5, c.top + 28, c.right - 5, c.bottom - 5),
          child: DecoratedBox(decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(4))),
        ),
        // The bar the slip is carried by, and the clip.
        Positioned.fromRect(
          rect: geo.handle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(M8NetBillLines.slipWord, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFF7E7B8))),
                  const SizedBox(width: 8),
                  for (var i = 0; i < 3; i++) Container(width: 4, height: 4, margin: const EdgeInsets.only(right: 3), decoration: const BoxDecoration(color: Color(0x88F7E7B8), shape: BoxShape.circle)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: c.center.dx - 16,
          top: c.top - 5,
          width: 32,
          height: 11,
          child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xFF9AA2A8), borderRadius: BorderRadius.circular(3))),
        ),
        // Flip.
        Positioned.fromRect(
          rect: geo.flip,
          child: Semantics(
            label: M8NetBillLines.flipWord,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFF7E7B8), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF5E4426), width: 1.2)),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(M8NetBillLines.flipWord, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: _ink)),
                ),
              ),
            ),
          ),
        ),
        if (flipped) ..._back(context) else ..._front(context),
      ],
    );
  }

  List<Widget> _front(BuildContext context) {
    Widget line(Rect r, String word) => Positioned.fromRect(
          rect: r,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(word, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _ink)),
              const SizedBox(width: 4),
              Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 3), child: Container(height: 1.2, color: const Color(0x883A2A16)))),
              const Padding(padding: EdgeInsets.only(bottom: 1), child: Text(M8NetBillLines.kwh, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _brown))),
            ],
          ),
        );
    return [
      Positioned(
        left: 126,
        top: geo.clipTop + 35,
        child: Text(M8NetBillLines.netUnits, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: _ink)),
      ),
      line(geo.importLine, M8NetBillLines.importWord),
      line(geo.exportLine, M8NetBillLines.exportWord),
      for (var i = 0; i < 3; i++) Positioned.fromRect(rect: geo.dig(i), child: _Roller(digit: slip.digits[i], active: rolling == i, live: live)),
      Positioned.fromRect(rect: geo.billSeg, child: _Seg(label: M8NetBillLines.bill, on: slip.bill == true, live: live)),
      Positioned.fromRect(rect: geo.bankSeg, child: _Seg(label: M8NetBillLines.bank, on: slip.bill == false, live: live)),
      Positioned.fromRect(rect: geo.fixYes, child: _Seg(label: M8NetBillLines.fixedYes, on: slip.fixed == true, live: live)),
      Positioned.fromRect(rect: geo.fixNo, child: _Seg(label: M8NetBillLines.fixedNo, on: slip.fixed == false, live: live)),
      Positioned.fromRect(rect: geo.stamp, child: _StampBtn(on: slip.stamped, live: live)),
    ];
  }

  List<Widget> _back(BuildContext context) {
    final apply = visit.kind == M8Case.apply;
    Widget box(Rect r, String word, String value) => Positioned.fromRect(
          rect: r,
          child: DecoratedBox(
            decoration: BoxDecoration(color: const Color(0xFFFFFBEF), borderRadius: BorderRadius.circular(6), border: Border.all(color: _brown, width: 1.2)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(word, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: _brown))),
                FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: _ink))),
              ],
            ),
          ),
        );
    final knob = geo.knob(slip.approve);
    return [
      box(geo.sanctionBox, M8NetBillLines.sanctionWord, apply ? M8NetBillLines.kwText(visit.sanctioned) : '—'),
      box(geo.askedBox, M8NetBillLines.askedWord, apply ? M8NetBillLines.kwText(visit.asked) : '—'),
      Positioned.fromRect(
        rect: geo.readout,
        child: Center(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '${M8NetBillLines.approveWord}  ', style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: _brown)),
              TextSpan(text: apply ? M8NetBillLines.kwText(slip.approve) : '—', style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
            ]),
          ),
        ),
      ),
      // The track: unmarked (no ticks, no scale).
      Positioned.fromRect(
        rect: geo.track,
        child: DecoratedBox(decoration: BoxDecoration(color: apply ? const Color(0xFFCDBF98) : const Color(0xFFDDD6C0), borderRadius: BorderRadius.circular(4))),
      ),
      Positioned.fromRect(
        rect: Rect.fromLTRB(geo.track.left, geo.track.top, knob.center.dx, geo.track.bottom),
        child: DecoratedBox(decoration: BoxDecoration(color: apply ? const Color(0xFF2E9E4F) : Colors.transparent, borderRadius: BorderRadius.circular(4))),
      ),
      Positioned.fromRect(
        rect: Rect.fromCenter(center: knob.center, width: 28, height: 28),
        child: Semantics(
          label: M8NetBillLines.approveWord,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: apply ? const Color(0xFFF2C94C) : const Color(0xFFBDB6A2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5E4426), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    ];
  }
}

/// A roller digit: the one in the window, its neighbours faded above and below.
class _Roller extends StatelessWidget {
  const _Roller({required this.digit, required this.active, required this.live});
  final int digit;
  final bool active;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final up = (digit + 1) % 10, down = (digit + 9) % 10;
    const faded = TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0x663A2A16), height: 1);
    return Semantics(
      label: '${M8NetBillLines.netUnits} $digit',
      child: Opacity(
        opacity: live ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFF6DA) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? const Color(0xFFC9951A) : const Color(0xFF8A6A3C), width: active ? 2.2 : 1.4),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('$up', style: faded),
              Text('$digit', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF2A2018), height: 1)),
              Text('$down', style: faded),
            ],
          ),
        ),
      ),
    );
  }
}

/// One half of a two-way field (বিল / জমা, ফিক্সড চার্জ আছে / নেই).
class _Seg extends StatelessWidget {
  const _Seg({required this.label, required this.on, required this.live});
  final String label;
  final bool on;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label.replaceAll('\n', ' '),
      selected: on,
      child: Opacity(
        opacity: live ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: on ? const Color(0xFFF2C94C) : const Color(0xFFFFFBEF),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: on ? const Color(0xFF7A5A10) : const Color(0xFF8A6A3C), width: on ? 2 : 1.2),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, textAlign: TextAlign.center, style: bangla(fontSize: label.contains('\n') ? 10.5 : 14, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018), height: 1.15)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The stamp: 'নেট মিটার বাধ্যতামূলক' (inked when pressed).
class _StampBtn extends StatelessWidget {
  const _StampBtn({required this.on, required this.live});
  final bool on;
  final bool live;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFB3261E);
    return Semantics(
      label: M8NetBillLines.stampWord,
      selected: on,
      child: Opacity(
        opacity: live ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: on ? const Color(0x22B3261E) : const Color(0xFFFFFBEF),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: on ? red : const Color(0xFF8A6A3C), width: on ? 2.4 : 1.2),
          ),
          child: Center(
            child: Transform.rotate(
              angle: on ? -0.03 : 0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(M8NetBillLines.stampWord, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: on ? red : const Color(0xFF6A5232))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
