import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
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
import 'm7_doorstep_visit_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_doorstep_visit_world.dart' show M7DvCust, M7DvGeo, M7DvRoom;

// Lesson 7.9 "গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব", কাজ 1 "দরজা থেকে মিটার
// বক্স" (pack do_7_9_a, engineType m7_doorstep_visit). A para lane in the
// morning; three dealt house fronts, one visit each (at least one goes in, at
// least one does not). The van's door carries the visit docket (the job and
// one notice line: দেওয়া হয়েছে / দেওয়া হয়নি / জরুরি; tap it for a close-up).
// The player drags the trainee to the gate; the gate shows a customer, a woman
// alone, or nobody home. A tray of three equal items (পরিচয়পত্র · ডকেট ·
// নোটিশ, shuffled) comes up: if someone answers, the ID card must be shown
// to him first. Then the answer ('আসুন' / 'এখন না') and the docket's notice
// line decide:
//
//   in   — consent AND (notice given OR জরুরি): drag through the gate. A
//          woman alone: tap the colleague to come as witness first.
//   out  — anything else: drag back to the van (a notice slip may go to the
//          customer or the letterbox).
//
// Inside (a side-cut ground floor) the customer says where the meter is; the
// player drags room to room: the meter place only for a reading or repair,
// the whole conduit run (meter box → switchboard) for an inspection or a
// test. Any other room is a slip. A ~2 s work beat, offcuts fall, the broom
// sweeps them, 'কাজ শেষ', then out the way he came.
//
// No deadly anywhere in 7.9 (ruling M7-6): every mistake is a slip. Three
// slips strike out. The careless coworker comes once a play, either at the
// gate (his own 'no ID' line, held at the first tray / gate drag) or inside
// (lesson myth 1 word for word, held at the first room drag). Listening to
// him is the slip of what he pushes (rule X2).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m7_doorstep_visit_world.dart), corner guide, ReasonTable (one
// reason a visit), CoworkerMoment, gesture hands (how, never what).

// ============================================================================
// Content
// ============================================================================

/// The jobs on the docket. A reading or repair is at the meter only; an
/// inspection or a test follows the conduit to the switchboard.
enum M7DvJob { read, repair, inspect, test }

/// Where the meter box and the switchboard are (the conduit between them).
enum M7DvCase { hall, verandaHall, storeKitchen }

/// What a visit is (the deal's building blocks).
enum M7DvKind { entryPlain, entryWoman, entryUrgent, noEntryEmpty, noEntryRefused, noEntryNoNotice }

enum M7DvNotice { given, notGiven, urgent }

enum M7DvConsent { yes, no, none }

enum M7DvItem { id, docket, notice }

enum M7DvTarget { none, customer, letterbox, door }

enum M7DvPhase { lane, door, inside, work, tidy, leave, done }

/// What a visit's reason asks about.
enum M7DvWhy { id, witness, zone, clean, refuseConsent, refuseNotice, refuseEmpty }

enum M7DvBeat { gate, inside }

abstract final class M7DoorstepVisitLines {
  static const title = 'দরজা থেকে মিটার বক্স';
  // DRAFT wording — owner (M6-12). The intro is the spec's.
  static const intro = 'আজ তিন বাড়িতে কাজ — নিয়ম মেনে ঢুকুন, নিয়ম মেনে বেরোন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askGate = 'ডকেট দেখে গেটের সামনে যান।';
  static const askDoor = 'গেটের সামনে এসেছেন — এবার কী করবেন?';
  static const askInside = 'এবার কাজের জায়গায় যান।';
  static const askTidy = 'কাজ হয়ে গেছে — এবার কী?';
  static const askLeave = 'এবার যে পথে এসেছেন, সে পথে বেরোন।';
  static const emptyDoor = 'ওখানে তো কেউ নেই।';
  static List<String> get tasks => [askGate, askDoor, askInside, askTidy, askLeave];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The scene (words a worker reads).
  static const docket = 'ডকেট';
  static const noticeWord = 'নোটিশ';
  static const idCard = 'পরিচয়পত্র';
  static const workDone = 'কাজ শেষ';
  static const sceneLabel = 'পাড়ার রাস্তা, বাড়ির গেট আর গাড়ি';
  static const insideLabel = 'বাড়ির ভেতরের ঘর, মিটার বক্স আর কনডুইট';
  static const broomLabel = 'ঝাড়ু';
  static const closeLabel = 'ডকেট বন্ধ করুন';
  static String round(int n) => enDigits('বাড়ি $n');
  static String jobOf(M7DvJob j) => switch (j) {
        M7DvJob.read => 'মিটার রিডিং',
        M7DvJob.repair => 'মিটার মেরামত',
        M7DvJob.inspect => 'ইনস্টলেশন পরিদর্শন',
        M7DvJob.test => 'মিটার পরীক্ষা',
      };
  static String jobLine(M7DvJob j) => 'কাজ: ${jobOf(j)}';
  static String noticeLine(M7DvNotice n) => switch (n) {
        M7DvNotice.given => 'নোটিশ: দেওয়া হয়েছে',
        M7DvNotice.notGiven => 'নোটিশ: দেওয়া হয়নি',
        M7DvNotice.urgent => 'জরুরি',
      };
  static String itemLabel(M7DvItem i) => switch (i) {
        M7DvItem.id => idCard,
        M7DvItem.docket => docket,
        M7DvItem.notice => noticeWord,
      };

  // What the customer says.
  static const womanAlone = 'বাড়িতে আমি একা আছি';
  static const welcome = 'আসুন';
  static const notNow = 'এখন না';
  static const silence = '...';
  static String meterSays(M7DvRoom r) => switch (r) {
        M7DvRoom.veranda => 'মিটার বক্স এই বারান্দাতেই',
        M7DvRoom.hall => 'মিটার বক্স ওই হলঘরে',
        M7DvRoom.store => 'মিটার বক্স পেছনের স্টোরে',
        _ => 'মিটার বক্স ভেতরে',
      };

  // The reasons: one question a visit.
  static const whyQ = <M7DvWhy, String>{
    M7DvWhy.id: 'কেন আগে পরিচয়পত্র দেখালেন?',
    M7DvWhy.witness: 'কেন সাথীকে সাক্ষী হিসেবে ডাকলেন?',
    M7DvWhy.zone: 'কেন ওই ঘরে গেলেন না?',
    M7DvWhy.clean: 'কেন জায়গাটা পরিষ্কার করলেন?',
    M7DvWhy.refuseConsent: 'কেন ভেতরে ঢুকলেন না?',
    M7DvWhy.refuseNotice: 'নোটিশ ছাড়া কেন ঢুকলেন না?',
    M7DvWhy.refuseEmpty: 'ফাঁকা বাড়িতে কেন ঢুকলেন না?',
  };
  // DRAFT wording — owner (M6-12). Right reasons state the lesson's rule.
  static const whyRight = <M7DvWhy, List<String>>{
    M7DvWhy.id: ['গ্রাহক চাওয়ার আগেই পরিচয়পত্র দেখাতে হয়', 'পরিচয়পত্র দেখানো আমার দায়িত্ব, তাঁর অধিকার'],
    M7DvWhy.witness: ['মহিলা একা আছেন, সাক্ষী সাথে রাখা ভালো', 'একা মহিলার বাড়িতে সাক্ষী রাখা নিয়ম'],
    M7DvWhy.zone: ['কাজের জায়গা ছাড়া অন্য ঘরে যাওয়া যায় না', 'প্রবেশের অধিকার মিটার আর ওয়্যারিং-এর রুটে'],
    M7DvWhy.clean: ['কাজ শেষে জায়গা পরিষ্কার করে যেতে হয়', 'কাজের জায়গা পরিষ্কার রাখা আমার দায়িত্ব'],
    M7DvWhy.refuseConsent: ['গ্রাহক না বললে জোর করে ঢোকা যায় না', 'অনুমতি ছাড়া কারও বাড়িতে প্রবেশ নয়'],
    M7DvWhy.refuseNotice: ['ঢোকার আগে যুক্তিসঙ্গত নোটিশ দিতে হয়', 'নোটিশ ছাড়া প্রবেশের শর্ত পূরণ হয় না'],
    M7DvWhy.refuseEmpty: ['কেউ না থাকলে অনুমতি নেওয়ার উপায় নেই', 'ফাঁকা বাড়িতে অনুমতি ছাড়া ঢোকা যায় না'],
  };
  static const myths = [
    'ইউনিফর্ম দেখলেই সবাই বুঝে নেয়, কার্ড লাগে না',
    'কাজ জরুরি হলে অনুমতি নেওয়ার দরকারই নেই',
    'তাড়াতাড়ি কাজ সারাই আগে, বাকি পরে দেখা যাবে',
    'ঘর পরিষ্কার করা গ্রাহকের কাজ, আমার নয়',
    'কাজের সুবিধা হলে যেকোনো ঘরে যাওয়া যায়',
    'গেট খোলা পেলে ঢুকে পড়তে কোনো বাধা নেই',
    'নোটিশ দেওয়া হোক বা না হোক, একই ব্যাপার',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker. The gate beat is his own line (no recorded lesson
  // line for it); the inside beat is lesson 7.9 myth 1, word for word.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  // DRAFT wording — owner (M6-12).
  static const gateScript = CoworkerScript(
    line: 'পরিচয়পত্র-টত্র লাগবে না, ইউনিফর্ম দেখেই বুঝবে — ঢুকে পড়ো!',
    exitLine: coworkerExit,
    right: ['না, আগে পরিচয়পত্র দেখাব, তারপর অন্য কথা', 'না, গ্রাহক চাওয়ার আগেই কার্ড দেখাব', 'না, পরিচয়পত্র না দেখিয়ে কিছুই করব না'],
    wrong: [
      'ঠিক বলেছ, ইউনিফর্মই তো যথেষ্ট ভাই',
      'আচ্ছা, কার্ড বের করার সময় নেই এখন',
      'হ্যাঁ, সরাসরি ঢুকে পড়াই ভালো হবে',
      'ঠিক আছে, কার্ড-টার্ড পরে দেখানো যাবে',
      'হ্যাঁ, গ্রাহক তো আমাদের চেনেনই ভাই',
    ],
    asks: ['কী করবেন?', 'সাথী কী বলছে — শুনবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const insideScript = CoworkerScript(
    line: 'গ্রাহকের বাড়িতে কাজ করতে এসেছি, তার মানে আমি যেকোনো জায়গায় যেতে পারি এবং যেকোনো কিছু করতে পারি।',
    exitLine: coworkerExit,
    right: ['না, শুধু কাজের জায়গাতেই থাকব ভাই', 'না, মিটার আর রুটের বাইরে যাব না', 'না, অন্য ঘরে যাওয়ার অধিকার নেই'],
    wrong: [
      'ঠিক বলেছ, বাকি ঘরও দেখে নিই একটু',
      'আচ্ছা, কাজের ফাঁকে ঘুরে আসি একটু',
      'হ্যাঁ, এসেছি যখন সব ঘরই দেখে যাই',
      'ঠিক আছে, গ্রাহক কিছু মনে করবেন না',
      'হ্যাঁ, গোপনীয়তা নিয়ে ভাবার কী আছে',
    ],
    asks: ['কী করবেন?', 'সাথী কী বলছে — শুনবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript script(M7DvBeat b) => b == M7DvBeat.gate ? gateScript : insideScript;
  static const callHeldGate = 'ঠিক! আগে পরিচয়পত্র — তারপর বাকি সব।';
  static const callHeldInside = 'ঠিক! শুধু কাজের জায়গাতেই যাবেন।';

  static const allSet = 'তিন বাড়িতেই নিয়ম মেনে কাজ করলেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে পরিচয়পত্র, তারপর অনুমতি আর নোটিশ, তারপর শুধু কাজের জায়গা।';

  // "আজ যা ধরলেন".
  static const caughtId = 'আগে পরিচয়পত্র দেখিয়েছেন';
  static const caughtEntry = 'অনুমতি আর নোটিশ দেখে ঢুকেছেন';
  static const caughtNoNotice = 'নোটিশ ছাড়া ঢোকেননি';
  static const caughtNoConsent = 'গ্রাহক না বলায় ফিরেছেন';
  static const caughtEmpty = 'ফাঁকা বাড়িতে ঢোকেননি';
  static const caughtWitness = 'মহিলা একা — সাক্ষী নিয়েছেন';
  static const caughtZone = 'শুধু কাজের জায়গায় থেকেছেন';
  static const caughtClean = 'জায়গা পরিষ্কার করে এসেছেন';
  static const caughtNotice = 'নোটিশের কাগজ রেখে এসেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new lines (the inside one is the lesson's myth, word for
  /// word; record both in his voice).
  static List<String> get newRivalLines => [gateScript.line, insideScript.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askGate,
        askDoor,
        askInside,
        askTidy,
        askLeave,
        emptyDoor,
        ...tapWhy.where((l) => !_oldLines.contains(l)),
        ...whyQ.values,
        ...gateScript.asks.where((a) => !_oldLines.contains(a)),
        callHeldGate,
        callHeldInside,
        allSet,
        quick,
        fail,
        for (final m in M7DoorstepVisitMistakes.all) m.textBn,
      ];
  static const _oldLines = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};
}

abstract final class M7DoorstepVisitMistakes {
  static const _dir = 'assets/game/art/m7_doorstep_visit';

  // DRAFT wording — owner (M6-12). Every one is a slip (M7-6: no deadly in
  // 7.9). Lesson points: 0 rights, 1 entry and its limits, 2 duties.
  static const firstAct = DoMistake(
    key: '7.9/m7_doorstep_visit/first-act',
    textBn: 'আগে পরিচয়পত্র! গ্রাহক চাওয়ার আগেই আপনার কোম্পানির পরিচয়পত্র দেখাতে হয় — অন্য কিছু তার পরে।',
    art: '$_dir/first_act.svg',
    lessonPoint: 2,
  );
  static const noConsent = DoMistake(
    key: '7.9/m7_doorstep_visit/no-consent',
    textBn: 'গ্রাহক “এখন না” বলেছেন। আপনি জোর করে বা গ্রাহকের অনুমতি ছাড়া তার বাড়িতে প্রবেশ করতে পারেন না।',
    art: '$_dir/no_consent.svg',
    lessonPoint: 1,
  );
  static const noNotice = DoMistake(
    key: '7.9/m7_doorstep_visit/no-notice',
    textBn: 'নোটিশ দেওয়া হয়নি। ঢোকার আগে গ্রাহককে যুক্তিসঙ্গত নোটিশ দিতে হয় — শুধু জরুরি অবস্থায় ছাড়া।',
    art: '$_dir/no_notice.svg',
    lessonPoint: 1,
  );
  static const trespass = DoMistake(
    key: '7.9/m7_doorstep_visit/trespass',
    textBn: 'দেয়াল টপকে বা ফাঁকা বাড়িতে ঢোকা যায় না। গেট দিয়ে, গ্রাহকের অনুমতি নিয়ে তবে ভেতরে যাবেন।',
    art: '$_dir/trespass.svg',
    lessonPoint: 1,
  );
  static const needlessRefusal = DoMistake(
    key: '7.9/m7_doorstep_visit/needless-refusal',
    textBn: 'অকারণে ফিরে এলেন। গ্রাহক রাজি, নোটিশ দেওয়া বা কাজ জরুরি — আইন মেনে ঢোকার অধিকার আপনার আছে।',
    art: '$_dir/needless_refusal.svg',
    lessonPoint: 1,
  );
  // The lesson's myth 1 reality, word for word.
  static const privateRoom = DoMistake(
    key: '7.9/m7_doorstep_visit/private-room',
    textBn: 'ভুল। আপনার প্রবেশের অধিকার শুধুমাত্র আপনার কাজের সাথে সম্পর্কিত জায়গার (যেমন মিটার বক্স, ওয়্যারিং-এর রুট) মধ্যেই সীমাবদ্ধ। গ্রাহকের ব্যক্তিগত গোপনীয়তাকে সম্মান করা আপনার দায়িত্ব।',
    art: '$_dir/private_room.svg',
    lessonPoint: 1,
  );
  static const debris = DoMistake(
    key: '7.9/m7_doorstep_visit/debris',
    textBn: 'কাজের টুকরো-টাকরা পড়ে আছে। কাজ শেষে আপনার কাজের জায়গাটি পরিষ্কার করে দিন, তবে কাজ শেষ বলুন।',
    art: '$_dir/debris.svg',
    lessonPoint: 2,
  );
  static const womanAlone = DoMistake(
    key: '7.9/m7_doorstep_visit/woman-alone',
    textBn: 'বাড়িতে একজন মহিলা একা। সম্ভব হলে অন্য কোনো সহকর্মী বা স্থানীয় ব্যক্তিকে সাক্ষী হিসেবে সাথে রাখুন — সাথী কাছেই আছেন।',
    art: '$_dir/woman_alone.svg',
    lessonPoint: 2,
  );
  static const listenGate = DoMistake(
    key: '7.9/m7_doorstep_visit/listen-gate',
    textBn: 'ওর কথা শুনলে ভুল হতো। ইউনিফর্ম আছে বলে পরিচয়পত্র না দেখানো যায় না — গ্রাহক চাওয়ার আগেই আপনার কোম্পানির পরিচয়পত্র দেখান।',
    art: '$_dir/listen_gate.svg',
    lessonPoint: 2,
  );
  static const listenZone = DoMistake(
    key: '7.9/m7_doorstep_visit/listen-zone',
    textBn: 'ওর কথা শুনলে ভুল হতো। আপনার প্রবেশের অধিকার শুধুমাত্র আপনার কাজের সাথে সম্পর্কিত জায়গার (যেমন মিটার বক্স, ওয়্যারিং-এর রুট) মধ্যেই সীমাবদ্ধ।',
    art: '$_dir/listen_zone.svg',
    lessonPoint: 1,
  );

  static const List<DoMistake> all = [firstAct, noConsent, noNotice, trespass, needlessRefusal, privateRoom, debris, womanAlone, listenGate, listenZone];
  static DoMistake listen(M7DvBeat b) => b == M7DvBeat.gate ? listenGate : listenZone;
}

/// One visit, dealt.
@immutable
class M7DvVisit {
  const M7DvVisit({
    required this.house,
    required this.kind,
    required this.job,
    required this.notice,
    required this.cust,
    required this.consent,
    required this.caseOf,
    required this.trayOrder,
    required this.debris,
    required this.why,
    required this.custLook,
    required this.tone,
  });

  /// 0 village courtyard house, 1 two-storey town house, 2 shop-front.
  final int house;
  final M7DvKind kind;
  final M7DvJob job;
  final M7DvNotice notice;
  final M7DvCust cust;
  final M7DvConsent consent;
  final M7DvCase caseOf;

  /// The tray's items, shuffled (indices into [M7DvItem.values]).
  final List<M7DvItem> trayOrder;

  /// Where the offcuts fall along the floor strip (0–1).
  final List<double> debris;
  final M7DvWhy why;
  final int custLook;
  final int tone;

  bool get someone => cust != M7DvCust.none;
  bool get woman => cust == M7DvCust.woman;

  /// Going in is right: consent AND (notice given OR জরুরি).
  bool get entryRight => consent == M7DvConsent.yes && notice != M7DvNotice.notGiven;
  bool get routeJob => job == M7DvJob.inspect || job == M7DvJob.test;

  M7DvRoom get meterRoom => switch (caseOf) {
        M7DvCase.hall => M7DvRoom.hall,
        M7DvCase.verandaHall => M7DvRoom.veranda,
        M7DvCase.storeKitchen => M7DvRoom.store,
      };
  M7DvRoom get boardRoom => switch (caseOf) {
        M7DvCase.hall || M7DvCase.verandaHall => M7DvRoom.hall,
        M7DvCase.storeKitchen => M7DvRoom.kitchen,
      };
  List<M7DvRoom> get route => switch (caseOf) {
        M7DvCase.hall => [M7DvRoom.hall],
        M7DvCase.verandaHall => [M7DvRoom.veranda, M7DvRoom.hall],
        M7DvCase.storeKitchen => [M7DvRoom.store, M7DvRoom.kitchen],
      };

  /// The rooms the job may go to (everything else is private).
  Set<M7DvRoom> get workRooms => routeJob ? route.toSet() : {meterRoom};
}

@immutable
class M7DvDeal {
  const M7DvDeal({required this.visits, required this.cwVisit, required this.cwBeat});
  final List<M7DvVisit> visits;

  /// The visit he comes on, and where (at the gate / inside).
  final int cwVisit;
  final M7DvBeat cwBeat;
}

const _entryKinds = [M7DvKind.entryPlain, M7DvKind.entryWoman, M7DvKind.entryUrgent];
const _stayKinds = [M7DvKind.noEntryEmpty, M7DvKind.noEntryRefused, M7DvKind.noEntryNoNotice];

M7DvVisit m7DvVisit(M7DvKind kind, int house, math.Random rng) {
  final job = M7DvJob.values[rng.nextInt(4)];
  final routeJob = job == M7DvJob.inspect || job == M7DvJob.test;
  // A reading or repair always needs at least one room move (never the
  // veranda, where he walks in).
  final cases = routeJob ? M7DvCase.values : const [M7DvCase.hall, M7DvCase.storeKitchen];
  final woman = kind == M7DvKind.entryWoman || (kind == M7DvKind.noEntryRefused && rng.nextBool());
  final notice = switch (kind) {
    M7DvKind.entryPlain => M7DvNotice.given,
    M7DvKind.entryUrgent => M7DvNotice.urgent,
    M7DvKind.entryWoman => rng.nextBool() ? M7DvNotice.given : M7DvNotice.urgent,
    M7DvKind.noEntryNoNotice => M7DvNotice.notGiven,
    M7DvKind.noEntryEmpty || M7DvKind.noEntryRefused => M7DvNotice.values[rng.nextInt(3)],
  };
  final cust = kind == M7DvKind.noEntryEmpty ? M7DvCust.none : (woman ? M7DvCust.woman : M7DvCust.man);
  final consent = switch (kind) {
    M7DvKind.noEntryEmpty => M7DvConsent.none,
    M7DvKind.noEntryRefused => M7DvConsent.no,
    _ => M7DvConsent.yes,
  };
  final why = switch (kind) {
    M7DvKind.entryPlain || M7DvKind.entryUrgent => const [M7DvWhy.id, M7DvWhy.zone, M7DvWhy.clean][rng.nextInt(3)],
    M7DvKind.entryWoman => const [M7DvWhy.witness, M7DvWhy.witness, M7DvWhy.id, M7DvWhy.zone, M7DvWhy.clean][rng.nextInt(5)],
    M7DvKind.noEntryEmpty => M7DvWhy.refuseEmpty,
    M7DvKind.noEntryRefused => rng.nextBool() ? M7DvWhy.refuseConsent : M7DvWhy.id,
    M7DvKind.noEntryNoNotice => rng.nextBool() ? M7DvWhy.refuseNotice : M7DvWhy.id,
  };
  const spots = [0.12, 0.3, 0.5, 0.7, 0.88];
  final pick = ([...spots]..shuffle(rng)).take(2 + rng.nextInt(2)).toList()..sort();
  return M7DvVisit(
    house: house,
    kind: kind,
    job: job,
    notice: notice,
    cust: cust,
    consent: consent,
    caseOf: cases[rng.nextInt(cases.length)],
    trayOrder: [...M7DvItem.values]..shuffle(rng),
    debris: pick,
    why: why,
    custLook: rng.nextInt(3),
    tone: rng.nextInt(3),
  );
}

M7DvDeal m7DvDeal(math.Random rng) {
  final entry = _entryKinds[rng.nextInt(3)];
  final stay = _stayKinds[rng.nextInt(3)];
  final rest = [..._entryKinds, ..._stayKinds]..remove(entry)..remove(stay);
  final kinds = [entry, stay, rest[rng.nextInt(rest.length)]]..shuffle(rng);
  final houses = [0, 1, 2]..shuffle(rng);
  final visits = [for (var i = 0; i < 3; i++) m7DvVisit(kinds[i], houses[i], rng)];
  final cw = rng.nextInt(3);
  final entering = visits[cw].entryRight;
  return M7DvDeal(visits: visits, cwVisit: cw, cwBeat: entering && rng.nextBool() ? M7DvBeat.inside : M7DvBeat.gate);
}

/// The lesson point (0-based) that teaches a reason.
int m7DvLessonPoint(M7DvWhy w) => switch (w) {
      M7DvWhy.id || M7DvWhy.witness || M7DvWhy.clean => 2,
      _ => 1,
    };

/// The play state (pure logic).
class M7DvRun {
  M7DvRun(this.deal) {
    _startVisit();
  }
  final M7DvDeal deal;

  int index = 0;
  int slips = 0;
  int visitSlips = 0;
  DoMistake? lastSlip;
  final List<String> caught = [];

  var phase = M7DvPhase.lane;
  var idShown = false;
  var noticeHanded = false;
  var colleague = false;
  var room = M7DvRoom.veranda;
  final Set<M7DvRoom> visited = {};

  /// A room drag was committed (the coworker's inside beat is due before).
  var moved = false;
  List<double> debris = [];
  var visitDone = false;
  var whyAsked = false;

  /// A private room was tried this visit.
  var zoneSlip = false;

  M7DvVisit get visit => deal.visits[index.clamp(0, 2)];
  bool get done => index >= 3;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => visitSlips == 0;

  void _startVisit() {
    phase = M7DvPhase.lane;
    idShown = false;
    noticeHanded = false;
    colleague = false;
    room = M7DvRoom.veranda;
    visited.clear();
    moved = false;
    debris = [];
    visitDone = false;
    whyAsked = false;
    zoneSlip = false;
    visitSlips = 0;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    visitSlips++;
    lastSlip = m;
    return m;
  }

  /// A listening slip (the coworker).
  DoMistake pushSlip(DoMistake m) => _slip(m);

  /// Arrived at the gate: the tray comes up.
  void arrive() {
    if (phase == M7DvPhase.lane) phase = M7DvPhase.door;
  }

  /// The customer has been shown his ID.
  bool get answered => visit.someone && idShown;

  /// An item dropped on [t]: null = fine (right, or nothing happens), else
  /// the slip.
  DoMistake? giveItem(M7DvItem it, M7DvTarget t) {
    if (phase != M7DvPhase.door || t == M7DvTarget.none) return null;
    final v = visit;
    if (v.someone && !idShown) {
      if (it == M7DvItem.id && t == M7DvTarget.customer) {
        idShown = true;
        _tag(M7DoorstepVisitLines.caughtId);
        return null;
      }
      return _slip(M7DoorstepVisitMistakes.firstAct);
    }
    if (it == M7DvItem.notice && (t == M7DvTarget.customer || t == M7DvTarget.letterbox)) {
      noticeHanded = true;
      _tag(M7DoorstepVisitLines.caughtNotice);
    }
    return null;
  }

  /// Taps the colleague to come as witness (at the gate only).
  bool callColleague() {
    if (phase != M7DvPhase.door || colleague) return false;
    colleague = true;
    if (visit.woman) _tag(M7DoorstepVisitLines.caughtWitness);
    return true;
  }

  /// The trainee dropped on the wall (anywhere on it but the gate).
  DoMistake? climbWall() => phase == M7DvPhase.door ? _slip(M7DoorstepVisitMistakes.trespass) : null;

  /// The trainee dropped through the gate: null = he is in (or nothing
  /// happened off the door phase).
  DoMistake? enterGate() {
    if (phase != M7DvPhase.door) return null;
    final v = visit;
    if (v.someone && !idShown) return _slip(M7DoorstepVisitMistakes.firstAct);
    if (!v.someone) return _slip(M7DoorstepVisitMistakes.trespass);
    if (v.consent == M7DvConsent.no) return _slip(M7DoorstepVisitMistakes.noConsent);
    if (v.notice == M7DvNotice.notGiven) return _slip(M7DoorstepVisitMistakes.noNotice);
    if (v.woman && !colleague) return _slip(M7DoorstepVisitMistakes.womanAlone);
    _tag(M7DoorstepVisitLines.caughtEntry);
    room = M7DvRoom.veranda;
    visited
      ..clear()
      ..addAll(v.workRooms.intersection({M7DvRoom.veranda}));
    phase = visited.containsAll(v.workRooms) ? M7DvPhase.work : M7DvPhase.inside;
    return null;
  }

  /// The trainee dropped back at the van: null with [visitDone] = a right
  /// refusal; null without = nothing happened (someone is waiting for his ID).
  DoMistake? goHome() {
    if (phase != M7DvPhase.door) return null;
    final v = visit;
    if (v.someone && !idShown) return null;
    if (v.entryRight) return _slip(M7DoorstepVisitMistakes.needlessRefusal);
    _tag(switch (v.kind) {
      M7DvKind.noEntryEmpty => M7DoorstepVisitLines.caughtEmpty,
      M7DvKind.noEntryRefused => M7DoorstepVisitLines.caughtNoConsent,
      _ => M7DoorstepVisitLines.caughtNoNotice,
    });
    visitDone = true;
    phase = M7DvPhase.done;
    return null;
  }

  /// A room drag: null = fine (or the same room).
  DoMistake? goRoom(M7DvRoom r) {
    if (phase != M7DvPhase.inside || r == room) return null;
    moved = true;
    if (!visit.workRooms.contains(r)) {
      zoneSlip = true;
      return _slip(M7DoorstepVisitMistakes.privateRoom);
    }
    room = r;
    visited.add(r);
    if (visited.containsAll(visit.workRooms)) phase = M7DvPhase.work;
    return null;
  }

  /// The work beat is over: the offcuts have fallen.
  void workFinished() {
    if (phase != M7DvPhase.work) return;
    debris = [...visit.debris];
    phase = M7DvPhase.tidy;
  }

  /// A piece swept up.
  void sweepPiece(int i) {
    if (phase == M7DvPhase.tidy && i >= 0 && i < debris.length) debris.removeAt(i);
  }

  /// 'কাজ শেষ': null = fine.
  DoMistake? finishWork() {
    if (phase != M7DvPhase.tidy) return null;
    if (debris.isNotEmpty) return _slip(M7DoorstepVisitMistakes.debris);
    _tag(M7DoorstepVisitLines.caughtClean);
    if (!zoneSlip) _tag(M7DoorstepVisitLines.caughtZone);
    phase = M7DvPhase.leave;
    return null;
  }

  /// Out through the veranda door.
  void leaveHouse() {
    if (phase != M7DvPhase.leave) return;
    visitDone = true;
    phase = M7DvPhase.done;
  }

  void next() {
    index++;
    if (!done) _startVisit();
  }
}

/// The quick time: a builder's estimate (~85 % of a clean play: three visits
/// at about 20 s of doing each, three reasons of about 8 s, the coworker
/// about 10 s, plus the work beats and the sweep). Owner may tune after a
/// playtest.
const m7DoorstepVisitQuickMs = 120000;

@immutable
class M7DoorstepVisitPack {
  const M7DoorstepVisitPack({required this.id, required this.titleBn, this.quickMs = m7DoorstepVisitQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7DoorstepVisitPack> m7DoorstepVisitPacks = {
  'do_7_9_a': M7DoorstepVisitPack(id: 'do_7_9_a', titleBn: M7DoorstepVisitLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7DoorstepVisitProbe {
  static M7DvRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7DoorstepVisitPage extends StatefulWidget {
  const M7DoorstepVisitPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7DoorstepVisitPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7DoorstepVisitPage> createState() => _M7DoorstepVisitPageState();
}

class _M7DoorstepVisitPageState extends State<M7DoorstepVisitPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DvRunPage(
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

class _DvRunPage extends ConsumerStatefulWidget {
  const _DvRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7DoorstepVisitPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DvRunPage> createState() => _DvRunPageState();
}

enum _Drag { none, trainee, item }

class _DvRunPageState extends ConsumerState<_DvRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7DvRun _run;
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
  int _fade = 0;

  // A drag in hand.
  _Drag _drag = _Drag.none;
  M7DvItem? _dragItem;
  Offset _dragAt = Offset.zero;
  Offset _grab = Offset.zero;

  var _closeup = false;
  var _broom = false;
  var _sweeping = false;
  var _working = false;
  Timer? _workTimer;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  M7DvGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7DvRun(m7DvDeal(widget.rng));
    M7DoorstepVisitProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M7DvVisit get _v => _run.visit;

  @override
  void dispose() {
    disposeCoworker();
    _workTimer?.cancel();
    _chain++;
    if (identical(M7DoorstepVisitProbe.run, _run)) M7DoorstepVisitProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_working && !_run.visitDone;

  String get _task => switch (_run.phase) {
        M7DvPhase.lane => M7DoorstepVisitLines.askGate,
        M7DvPhase.door => M7DoorstepVisitLines.askDoor,
        M7DvPhase.inside || M7DvPhase.work => M7DoorstepVisitLines.askInside,
        M7DvPhase.tidy => M7DoorstepVisitLines.askTidy,
        M7DvPhase.leave || M7DvPhase.done => M7DoorstepVisitLines.askLeave,
      };

  Future<void> _start() async {
    _clock.start();
    _beginVisit();
  }

  void _beginVisit() {
    setState(() {
      _wake++;
      _fade++;
      _drag = _Drag.none;
      _closeup = false;
      _broom = false;
      _sweeping = false;
    });
    unawaited(_sayChain([_task]));
  }

  // --- the doing ------------------------------------------------------------
  Offset _toGlobal(Offset design) => design * (MediaQuery.sizeOf(context).width / 360);

  M7DvTarget _targetAt(Offset p, M7DvGeo g) {
    if (_v.someone && g.custZone.contains(p)) return M7DvTarget.customer;
    if (g.letterbox.inflate(10).contains(p)) return M7DvTarget.letterbox;
    if (!_v.someone && g.gate.inflate(6).contains(p)) return M7DvTarget.door;
    return M7DvTarget.none;
  }

  void _tapScene(Offset p, M7DvGeo geo) {
    if (!_canPlay) return;
    if (_closeup) {
      _tick();
      setState(() => _closeup = false);
      return;
    }
    final ph = _run.phase;
    if (ph == M7DvPhase.lane || ph == M7DvPhase.door) {
      if (geo.docket.inflate(4).contains(p)) {
        _tick();
        setState(() => _closeup = true);
        return;
      }
      final col = (_run.colleague ? geo.colleagueGate : geo.colleagueBase).inflate(6);
      if (col.contains(p)) {
        _callColleague(geo);
        return;
      }
    }
    if (ph == M7DvPhase.tidy) {
      if (geo.broom.contains(p)) {
        _tick('sounds/learn/tag_slap.ogg', 0.5);
        setState(() => _broom = !_broom);
        return;
      }
      if (geo.doneBtn.contains(p)) {
        _finishWork(p);
        return;
      }
    }
    _hints.missTap();
  }

  void _callColleague(M7DvGeo geo) {
    if (_run.phase != M7DvPhase.door) {
      // In the lane he waits by the van; he comes at the gate.
      _hints.missTap();
      return;
    }
    if (!_run.callColleague()) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() => _wake++);
    if (_v.woman && _v.why == M7DvWhy.witness) unawaited(_askWhy(M7DvWhy.witness));
  }

  void _panStart(Offset p, M7DvGeo geo) {
    _drag = _Drag.none;
    if (!_canPlay || _closeup) return;
    final ph = _run.phase;
    if (ph == M7DvPhase.door) {
      for (var i = 0; i < 3; i++) {
        if (geo.trayItem(i).contains(p)) {
          _tick('sounds/learn/card_deal_a.ogg', 0.4);
          setState(() {
            _drag = _Drag.item;
            _dragItem = _v.trayOrder[i];
            _grab = p - geo.trayItem(i).center;
            _dragAt = geo.trayItem(i).center;
          });
          return;
        }
      }
    }
    if (ph == M7DvPhase.tidy) {
      if (_broom) {
        _sweeping = true;
        _sweepAt(p, geo);
      }
      return;
    }
    if (ph == M7DvPhase.lane || ph == M7DvPhase.door || ph == M7DvPhase.inside || ph == M7DvPhase.leave) {
      final r = _traineeRect(geo);
      if (r.inflate(6).contains(p)) {
        _tick('sounds/intro/click.ogg', 0.4);
        setState(() {
          _drag = _Drag.trainee;
          _grab = p - r.center;
          _dragAt = r.center;
        });
      }
    }
  }

  void _panUpdate(Offset p, M7DvGeo geo) {
    if (_sweeping) {
      if (!_canPlay) {
        _sweeping = false;
        return;
      }
      _sweepAt(p, geo);
      return;
    }
    if (_drag == _Drag.none) return;
    if (!_canPlay) {
      setState(() => _drag = _Drag.none);
      return;
    }
    setState(() => _dragAt = p - _grab);
  }

  void _sweepAt(Offset p, M7DvGeo geo) {
    final fl = geo.floor(_run.room);
    var hit = false;
    for (var i = _run.debris.length - 1; i >= 0; i--) {
      final c = Offset(fl.left + _run.debris[i] * fl.width, fl.center.dy);
      if (Rect.fromCenter(center: c, width: 34, height: 40).contains(p)) {
        _run.sweepPiece(i);
        hit = true;
      }
    }
    if (hit) {
      _tick('sounds/learn/tick.ogg', 0.4);
      setState(() {
        if (_run.debris.isEmpty) {
          _broom = false;
          _sweeping = false;
        }
      });
    }
  }

  void _panEnd(M7DvGeo geo) {
    _sweeping = false;
    final kind = _drag;
    if (kind == _Drag.none) return;
    final at = _dragAt;
    final item = _dragItem;
    setState(() => _drag = _Drag.none);
    if (!_canPlay) {
      _hints.missTap();
      return;
    }
    if (kind == _Drag.item) {
      _dropItem(item!, at, geo);
    } else {
      _dropTrainee(at, geo);
    }
  }

  void _dropItem(M7DvItem it, Offset at, M7DvGeo geo) {
    final t = _targetAt(at, geo);
    if (t == M7DvTarget.none) {
      _hints.missTap();
      return;
    }
    if (holdForCoworker()) return;
    final wasShown = _run.idShown;
    final wasHanded = _run.noticeHanded;
    final m = _run.giveItem(it, t);
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    if (m != null) {
      unawaited(_mistake(m, _toGlobal(at)));
      return;
    }
    if (t == M7DvTarget.door) {
      unawaited(_sayChain([M7DoorstepVisitLines.emptyDoor]));
      return;
    }
    setState(() => _wake++);
    if (!wasHanded && _run.noticeHanded) _tick('sounds/intro/confirm.ogg', 0.5);
    if (!wasShown && _run.idShown) {
      _tick('sounds/intro/confirm.ogg', 0.6);
      unawaited(_sayChain([M7DoorstepVisitLines.askDoor]));
      if (_v.why == M7DvWhy.id) unawaited(_askWhy(M7DvWhy.id));
    }
  }

  void _dropTrainee(Offset at, M7DvGeo geo) {
    switch (_run.phase) {
      case M7DvPhase.lane:
        // Anywhere at the house front or on the pavement before it: he walks
        // up to the gate (nothing is done yet).
        if (geo.gateFront.inflate(10).contains(at) || geo.wall.inflate(6).contains(at) || geo.houseBody.contains(at)) {
          _arrive();
        } else {
          _hints.missTap();
        }
      case M7DvPhase.door:
        if (geo.gate.inflate(4).contains(at)) {
          if (holdForCoworker()) return;
          final m = _run.enterGate();
          if (m != null) {
            unawaited(_mistake(m, _toGlobal(at)));
            return;
          }
          _enter();
        } else if (geo.wall.contains(at)) {
          if (holdForCoworker()) return;
          final m = _run.climbWall();
          if (m != null) unawaited(_mistake(m, _toGlobal(at)));
        } else if (geo.vanZone.contains(at)) {
          if (!(_v.someone && !_run.idShown) && holdForCoworker()) return;
          final m = _run.goHome();
          if (m != null) {
            unawaited(_mistake(m, _toGlobal(at)));
            return;
          }
          if (_run.visitDone) {
            _cue('sounds/van_arrive.ogg', volume: 0.4);
            setState(() => _wake++);
            _visitFinished();
          } else {
            // Someone is waiting for his ID: he stays.
            _hints.missTap();
          }
        } else {
          _hints.missTap();
        }
      case M7DvPhase.inside:
        for (final r in M7DvRoom.values) {
          if (geo.room(r).contains(at)) {
            _goRoom(r, at);
            return;
          }
        }
        _hints.missTap();
      case M7DvPhase.leave:
        if (geo.exitDoor.inflate(8).contains(at)) {
          _run.leaveHouse();
          _cue('sounds/intro/drop.ogg', volume: 0.5);
          setState(() => _wake++);
          _visitFinished();
        } else {
          _hints.missTap();
        }
      case M7DvPhase.work || M7DvPhase.tidy || M7DvPhase.done:
        break;
    }
  }

  void _arrive() {
    _run.arrive();
    _cue('sounds/learn/knock_hollow.ogg', volume: 0.6);
    setState(() {
      _wake++;
      _fade++;
    });
    if (_run.index == _run.deal.cwVisit && _run.deal.cwBeat == M7DvBeat.gate) scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  void _enter() {
    _cue('sounds/intro/drop.ogg', volume: 0.6);
    setState(() {
      _wake++;
      _fade++;
    });
    if (_run.index == _run.deal.cwVisit && _run.deal.cwBeat == M7DvBeat.inside) scheduleCoworker();
    if (_run.phase == M7DvPhase.work) {
      _startWork();
    } else {
      unawaited(_sayChain([_task]));
    }
  }

  void _goRoom(M7DvRoom r, Offset at) {
    if (r == _run.room) return;
    if (holdForCoworker()) return;
    final m = _run.goRoom(r);
    _tick('sounds/learn/stomp.ogg', 0.35);
    if (m != null) {
      unawaited(_mistake(m, _toGlobal(at)));
      return;
    }
    setState(() => _wake++);
    final startWork = _run.phase == M7DvPhase.work;
    if (_v.why == M7DvWhy.zone && !_run.whyAsked) {
      unawaited(_askWhy(M7DvWhy.zone, then: startWork ? _startWork : null));
    } else if (startWork) {
      _startWork();
    }
  }

  void _startWork() {
    setState(() {
      _working = true;
      _wake++;
    });
    _cue('sounds/learn/ring_steel.ogg', volume: 0.35);
    _workTimer?.cancel();
    _workTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted || _ended) return;
      _run.workFinished();
      _cue('sounds/intro/glass.ogg', volume: 0.35);
      setState(() {
        _working = false;
        _wake++;
        _broom = false;
      });
      unawaited(_sayChain([_task]));
    });
  }

  void _finishWork(Offset at) {
    final m = _run.finishWork();
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    if (m != null) {
      unawaited(_mistake(m, _toGlobal(at)));
      return;
    }
    setState(() {
      _broom = false;
      _wake++;
    });
    if (_v.why == M7DvWhy.clean && !_run.whyAsked) {
      unawaited(_askWhy(M7DvWhy.clean));
    } else {
      unawaited(_sayChain([_task]));
    }
  }

  /// The visit is over (a right refusal, or out through the door). A refusal
  /// asks its reason now; otherwise the next visit follows once any reason
  /// that is still open has been paid.
  void _visitFinished() {
    if (!_run.whyAsked) {
      unawaited(_askWhy(_v.why));
    } else if (!reasonOpen && !tableBusy) {
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx && _run.visitDone && !reasonOpen && !tableBusy) _next();
    }));
  }

  Future<void> _askWhy(M7DvWhy topic, {VoidCallback? then}) async {
    _run.whyAsked = true;
    _hush();
    HapticFeedback.mediumImpact();
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    _afterWhy = then;
    unawaited(askReason(
      deal: () => dealChoices(M7DoorstepVisitLines.whyRight[topic]!, M7DoorstepVisitLines.myths, widget.rng),
      question: M7DoorstepVisitLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  VoidCallback? _afterWhy;

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _beginVisit();
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
    final then = _afterWhy;
    _afterWhy = null;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended || _run.index != idx) return;
      if (_run.visitDone) {
        _next();
        return;
      }
      setState(() => _wake++);
      if (then != null) {
        then();
      } else {
        unawaited(_sayChain([_task]));
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7DoorstepVisitLines.script(_run.deal.cwBeat);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final d = _run.deal;
    if (_ended || _run.index != d.cwVisit || _run.done) return null;
    final ph = _run.phase;
    if (d.cwBeat == M7DvBeat.gate) {
      if (ph != M7DvPhase.door) return null;
    } else {
      if (ph == M7DvPhase.door) return false;
      if (ph != M7DvPhase.inside || _run.moved) return null;
    }
    if (_intro || _card != null || tableBusy || _drag != _Drag.none) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final beat = _run.deal.cwBeat;
    if (!held) {
      final m = _run.pushSlip(M7DoorstepVisitMistakes.listen(beat));
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7DoorstepVisitLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([beat == M7DvBeat.gate ? M7DoorstepVisitLines.callHeldGate : M7DoorstepVisitLines.callHeldInside, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7DoorstepVisitLines.tapWhy[_nudgeN++ % M7DoorstepVisitLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _workTimer?.cancel();
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
      _drag = _Drag.none;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7dv/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
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
    _workTimer?.cancel();
    _clock.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height * 0.45);
    final mark = _run.percent;
    final quick = _clock.elapsedMilliseconds < widget.pack.quickMs;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M7DoorstepVisitLines.fail : (_quickBonus ? M7DoorstepVisitLines.quick : M7DoorstepVisitLines.allSet),
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
  Rect _traineeRect(M7DvGeo g) => switch (_run.phase) {
        M7DvPhase.lane => g.traineeStart,
        M7DvPhase.door => g.traineeGate,
        M7DvPhase.done => g.traineeStart,
        _ => g.traineeIn(_run.room),
      };

  LinemanMode get _mode {
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_working || _broom || _drag == _Drag.trainee) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M7DvRig get _rig => M7DvRig(
        house: _v.house,
        tone: _v.tone,
        inside: _inside,
        cust: _v.cust,
        custOut: _run.phase != M7DvPhase.lane,
        custLook: _v.custLook,
        meter: _v.meterRoom,
        board: _v.boardRoom,
        slipInBox: _run.noticeHanded,
      );

  bool get _inside => switch (_run.phase) {
        M7DvPhase.inside || M7DvPhase.work || M7DvPhase.tidy || M7DvPhase.leave => true,
        _ => false,
      };

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final g = _geoNow;
    if (g == null) return null;
    if (_closeup) return HintSpec.tap(g.closeupX.center, space: HintSpace.scene);
    switch (_run.phase) {
      case M7DvPhase.lane:
        return HintSpec.drag(g.traineeStart.center, toward: const Offset(0.8, -0.6), travel: 70, space: HintSpace.scene);
      case M7DvPhase.door:
        if (_v.someone && !_run.idShown) {
          return HintSpec.sweep([for (var i = 0; i < 3; i++) g.trayItem(i)], space: HintSpace.scene);
        }
        return HintSpec.sweep([g.gate, g.wall, g.letterbox, if (_v.someone) g.cust, g.colleagueBase], space: HintSpace.scene);
      case M7DvPhase.inside || M7DvPhase.leave:
        return HintSpec.drag(_traineeRect(g).center, toward: const Offset(-1, -1), travel: 64, space: HintSpace.scene);
      case M7DvPhase.tidy:
        if (_broom) {
          final f = g.floor(_run.room);
          return HintSpec.swipe(Offset(f.left + 6, f.center.dy), toward: const Offset(1, 0), travel: 90, space: HintSpace.scene);
        }
        return HintSpec.sweep([g.broom, g.doneBtn], space: HintSpace.scene);
      case M7DvPhase.work || M7DvPhase.done:
        return null;
    }
  }

  Rect _pieceRect(int i, M7DvGeo g) {
    final fl = g.floor(_run.room);
    return Rect.fromCenter(center: Offset(fl.left + _run.debris[i] * fl.width, fl.center.dy), width: 14, height: 9);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7DvGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final r = _run;
    final v = _v;
    final rig = _rig;
    final ph = r.phase;
    final inside = _inside;
    final trainee = _traineeRect(geo);
    final colRect = r.colleague ? geo.colleagueGate : geo.colleagueBase;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: Stack(
          children: [
            Positioned.fill(
              key: const ValueKey('land'),
              child: RepaintBoundary(
                child: CustomPaint(painter: inside ? M7DvInsidePainter(geo: geo, rig: rig) : M7DvLanePainter(geo: geo, rig: rig)),
              ),
            ),
            if (!inside) ...[
              // The colleague (unvoiced) by the van; beside the trainee when called.
              AnimatedPositioned.fromRect(
                key: const ValueKey('colleague'),
                rect: colRect,
                duration: Duration(milliseconds: quiet ? 0 : 320),
                curve: Curves.easeInOut,
                child: const RepaintBoundary(child: CustomPaint(painter: M7DvPersonPainter(look: 1, crew: true))),
              ),
              Positioned.fromRect(
                key: ValueKey('docket-${r.index}'),
                rect: geo.docket,
                child: _DocketCard(job: v.job, notice: v.notice),
              ),
              if (ph == M7DvPhase.door && v.woman)
                Positioned.fromRect(key: ValueKey('say-woman-${r.index}'), rect: geo.speechA, child: const _Say(text: M7DoorstepVisitLines.womanAlone)),
              if (ph == M7DvPhase.door && !v.someone)
                Positioned.fromRect(key: ValueKey('say-none-${r.index}'), rect: geo.speechNone, child: const _Say(text: M7DoorstepVisitLines.silence)),
              if (ph == M7DvPhase.door && r.answered)
                Positioned.fromRect(
                  key: ValueKey('say-consent-${r.index}'),
                  rect: v.woman ? geo.speechB : geo.speechA,
                  child: _Say(text: v.consent == M7DvConsent.yes ? M7DoorstepVisitLines.welcome : M7DoorstepVisitLines.notNow),
                ),
              if (ph == M7DvPhase.door)
                for (var i = 0; i < 3; i++)
                  Positioned.fromRect(
                    key: ValueKey('tray-${r.index}-$i'),
                    rect: geo.trayItem(i),
                    child: Opacity(opacity: _drag == _Drag.item && _dragItem == v.trayOrder[i] ? 0.25 : 1, child: _TrayCard(item: v.trayOrder[i])),
                  ),
            ] else ...[
              if (ph == M7DvPhase.inside || ph == M7DvPhase.work)
                Positioned.fromRect(key: ValueKey('say-meter-${r.index}'), rect: geo.meterSays, child: _Say(text: M7DoorstepVisitLines.meterSays(v.meterRoom))),
              for (var i = 0; i < r.debris.length; i++)
                Positioned.fromRect(
                  key: ValueKey('debris-${r.index}-${r.debris[i]}'),
                  rect: _pieceRect(i, geo),
                  child: const IgnorePointer(child: _Offcut()),
                ),
              if (_working)
                Positioned.fromRect(key: ValueKey('workbar-${r.index}'), rect: geo.workBar(r.room), child: _WorkBar(quiet: quiet)),
              if (ph == M7DvPhase.tidy) ...[
                Positioned.fromRect(
                  key: const ValueKey('broom'),
                  rect: geo.broom,
                  child: _BroomButton(held: _broom),
                ),
                Positioned.fromRect(key: const ValueKey('done'), rect: geo.doneBtn, child: const _DoneButton()),
              ],
            ],
            AnimatedPositioned.fromRect(
              key: const ValueKey('trainee'),
              rect: trainee,
              duration: Duration(milliseconds: quiet ? 0 : 320),
              curve: Curves.easeInOut,
              child: Opacity(
                opacity: _drag == _Drag.trainee ? 0.25 : 1,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ),
          ],
        ),
      ),
      if (_closeup)
        Positioned.fromRect(
          key: const ValueKey('closeup'),
          rect: geo.closeup,
          child: IgnorePointer(child: _DocketClose(job: v.job, notice: v.notice, x: geo.closeupX.shift(-geo.closeup.topLeft))),
        ),
      if (_drag == _Drag.item)
        Positioned.fromRect(
          key: const ValueKey('item-hand'),
          rect: Rect.fromCenter(center: _dragAt, width: 108, height: 62),
          child: IgnorePointer(child: _TrayCard(item: _dragItem!, lifted: true)),
        ),
      if (_drag == _Drag.trainee)
        Positioned.fromRect(
          key: const ValueKey('trainee-hand'),
          rect: Rect.fromCenter(center: _dragAt, width: trainee.width, height: trainee.height),
          child: IgnorePointer(child: LinemanFigure(look: LinemanLook.trainee, mode: LinemanMode.hold, wake: _wake, quiet: true)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: inside ? M7DoorstepVisitLines.insideLabel : M7DoorstepVisitLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, geo),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () {
              _sweeping = false;
              if (_drag != _Drag.none) setState(() => _drag = _Drag.none);
            },
          ),
        ),
      ),
      // A short fade at each change of place (the gate, the door, the next house).
      if (!_intro)
        Positioned.fill(
          key: ValueKey('fade-$_fade'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _fade == 0 ? 0 : 0.5, end: 0),
              duration: const Duration(milliseconds: 420),
              builder: (_, a, _) => a <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(20, 24, 34, a)),
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
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_working && !_run.visitDone && _run.phase != M7DvPhase.done;
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
              labels: [for (var i = 0; i < 3; i++) M7DoorstepVisitLines.round(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _drag == _Drag.none && !_sweeping,
            hintKey: '${_run.index}/${_run.phase.index}/$_closeup/${_run.idShown}/$_broom/${_run.visited.length}',
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 12), onLeft: coworkerFromRight),
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
                  line: M7DoorstepVisitLines.intro,
                  alarm: 'sounds/van_arrive.ogg',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: _run.lastSlip?.lessonPoint ?? 1, muted: _muted)),
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

/// The visit docket on the van's door (small; tap for the close-up).
class _DocketCard extends StatelessWidget {
  const _DocketCard({required this.job, required this.notice});
  final M7DvJob job;
  final M7DvNotice notice;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M7DoorstepVisitLines.docket,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF2),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFFB59A5A), width: 1),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 3, 3, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(M7DoorstepVisitLines.docket, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Color(0xFF1F3A68), height: 1.1)),
              Text(M7DoorstepVisitLines.jobLine(job), style: const TextStyle(fontSize: 7, color: Color(0xFF2A2A2A), height: 1.1), maxLines: 1, overflow: TextOverflow.clip),
              Text(
                M7DoorstepVisitLines.noticeLine(notice),
                style: TextStyle(fontSize: 7, fontWeight: notice == M7DvNotice.urgent ? FontWeight.w900 : FontWeight.w500, color: notice == M7DvNotice.urgent ? const Color(0xFFB02A1E) : const Color(0xFF2A2A2A), height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The docket's close-up card (tap anywhere to close).
class _DocketClose extends StatelessWidget {
  const _DocketClose({required this.job, required this.notice, required this.x});
  final M7DvJob job;
  final M7DvNotice notice;
  final Rect x;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M7DoorstepVisitLines.closeLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB59A5A), width: 3),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(M7DoorstepVisitLines.docket, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F3A68))),
                    const SizedBox(height: 10),
                    Text(M7DoorstepVisitLines.jobLine(job), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2A2A2A))),
                    const SizedBox(height: 10),
                    Text(
                      M7DoorstepVisitLines.noticeLine(notice),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: notice == M7DvNotice.urgent ? const Color(0xFFB02A1E) : const Color(0xFF2A2A2A)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fromRect(rect: x, child: const Center(child: Icon(Icons.close_rounded, size: 26, color: Color(0xFF55595F)))),
          ],
        ),
      ),
    );
  }
}

/// What the customer says (a small speech bubble).
class _Say extends StatelessWidget {
  const _Say({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Semantics(
        label: text,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF55595F), width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2833), height: 1.15), textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tray item: three equal cards (same size, colour and weight).
class _TrayCard extends StatelessWidget {
  const _TrayCard({required this.item, this.lifted = false});
  final M7DvItem item;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item) {
      M7DvItem.id => Icons.badge_outlined,
      M7DvItem.docket => Icons.description_outlined,
      M7DvItem.notice => Icons.mail_outline_rounded,
    };
    return Semantics(
      label: M7DoorstepVisitLines.itemLabel(item),
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBF3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1F3A68), width: 2),
          boxShadow: [BoxShadow(color: const Color(0x55000000), blurRadius: lifted ? 10 : 3, offset: Offset(0, lifted ? 5 : 1))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: const Color(0xFF1F3A68)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(M7DoorstepVisitLines.itemLabel(item), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1F3A68)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// A piece of cable or conduit offcut on the floor.
class _Offcut extends StatelessWidget {
  const _Offcut();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'টুকরো',
        child: CustomPaint(painter: _OffcutPainter()),
      );
}

class _OffcutPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & Size(s.width, s.height * 0.5), const Radius.circular(2)), Paint()..color = const Color(0xFF55595F));
    c.drawRect(Rect.fromLTWH(s.width * 0.1, s.height * 0.5, s.width * 0.5, s.height * 0.3), Paint()..color = const Color(0xFFC63A2F));
    c.drawCircle(Offset(s.width * 0.8, s.height * 0.7), 2, Paint()..color = const Color(0xFFD9DDE2));
  }

  @override
  bool shouldRepaint(_OffcutPainter old) => false;
}

class _WorkBar extends StatelessWidget {
  const _WorkBar({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 2000),
        builder: (_, v, _) => DecoratedBox(
          decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(4)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v.clamp(0.02, 1.0),
              child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xFFFFC043), borderRadius: BorderRadius.circular(4))),
            ),
          ),
        ),
      ),
    );
  }
}

class _BroomButton extends StatelessWidget {
  const _BroomButton({required this.held});
  final bool held;

  @override
  Widget build(BuildContext context) => Semantics(
        label: M7DoorstepVisitLines.broomLabel,
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: held ? const Color(0xFFFFC043) : const Color(0xFF1F3A68), width: 2.5),
          ),
          child: CustomPaint(painter: _BroomPainter()),
        ),
      );
}

class _BroomPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final stick = Paint()
      ..color = const Color(0xFF8A5E3C)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(s.width * 0.72, s.height * 0.14), Offset(s.width * 0.42, s.height * 0.62), stick);
    final head = Path()
      ..moveTo(s.width * 0.3, s.height * 0.6)
      ..lineTo(s.width * 0.58, s.height * 0.5)
      ..lineTo(s.width * 0.7, s.height * 0.84)
      ..lineTo(s.width * 0.22, s.height * 0.86)
      ..close();
    c.drawPath(head, Paint()..color = const Color(0xFFD7B24A));
    for (var i = 0; i < 5; i++) {
      c.drawLine(Offset(s.width * (0.28 + i * 0.1), s.height * 0.7), Offset(s.width * (0.26 + i * 0.1), s.height * 0.85), Paint()
        ..color = const Color(0xFF9C7A22)
        ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(_BroomPainter old) => false;
}

class _DoneButton extends StatelessWidget {
  const _DoneButton();

  @override
  Widget build(BuildContext context) => Semantics(
        label: M7DoorstepVisitLines.workDone,
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1F3A68),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFC043), width: 2),
          ),
          child: const Center(
            child: Text(M7DoorstepVisitLines.workDone, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
          ),
        ),
      );
}
