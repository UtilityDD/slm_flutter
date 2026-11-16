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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_theft_evidence_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_theft_evidence_world.dart' show M8Geo, M8Kind, M8LaneGeo, M8Look, M8Verdict, m8IsTheft, m8Judge, m8Tol;

// Lesson 8.2 "সাপ্লাই কোড", কাজ "আগে প্রমাণ, পরে কাটা" (pack do_8_2_b,
// engineType m8_theft_evidence). Ruling M8-20: this level's core is NOT the
// phone viewfinder of Module 7's do_7_5_b (aim, zoom, shoot). The verb here:
// TRACE THE WIRE. Raise the phone at a premises, press REC and run a finger
// along the suspect wire on the close-up, from the conductor to the house
// (or round the meter box), then stop. Every clip is kept as a thumbnail
// whatever it holds; nothing says which clip is good. The clips are judged
// only at 'বিচ্ছিন্ন করুন' (lesson 8.2 Sec 135: "প্রথম কাজ প্রমাণ জোগাড় করা,
// তারপর লাইন বিচ্ছিন্ন করা").
//
// Lane: 3-4 premises (1-2 hooking, 0-1 bypass, exactly one shop on a domestic
// card, the rest honest), visited in any order. At each premises the same
// three tiles: ফোন · বিচ্ছিন্ন করুন (a hold, abstract: from the ground) ·
// গ্রাহককে বলুন. A valid disconnect plays a short crew cut-scene in the
// Module 7 order (OFF, tester 0 V, earth, গ্লাভস, hook off; M8-18, no new
// scoring), then the close-out tray at the van: জব্দ তালিকা (hold to sign),
// the complaint through the officer (a timing deck) and a decoy 15-day notice
// form. The shop: explain the tariff change (Sec 126: no FIR); a dealt
// follow-up asks if that is the final bill (provisional, then hearing, then
// final). A dealt access event at the bypass house: the owner blocks the gate.
//
// Slips only (ruling M8-1: regulatory/consumer acts, listening to the
// coworker by B1/X2); there is no deadly act in this level (the removal is a
// cut-scene, nobody is near a live part). A wrong 'why' card costs the ◆ only
// (M8-8). Three slips strike out.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one per play).
enum M8Push { order, shop, tray }

/// The close-out papers.
enum M8Paper { seizure, officer, notice }

/// The decks in the field.
enum M8Deck { gate1, gate2, shop1, shop2, timing }

/// What a reason asks about (fits what the player just did).
enum M8Why { video, pole, noFir, explain, seizure, gate, complaint }

abstract final class M8TheftLines {
  static const title = 'আগে প্রমাণ, পরে কাটা';

  // DRAFT wording — owner (M6-12 / M8-14): every line below until the owner
  // words it. The opening is the spec's.
  static const intro = 'এলাকায় চুরির খবর — চোখ খোলা রাখুন, নিয়ম মেনে।';
  static const askWhere = 'কোন বাড়িতে আগে যাবেন?';

  // The tasks (the corner guide; tap = said again another way).
  static const taskTiles = 'এখানে এখন কী করবেন?';
  static const taskRec = 'ফোনে প্রমাণ রেকর্ড করুন।';
  static const taskStop = 'হয়ে গেলে রেকর্ড থামান।';
  static const taskGate = 'গেটের মালিককে কী বলবেন?';
  static const taskShop = 'দোকানদারকে কী বলবেন?';
  static const taskTray = 'ভ্যানের কাগজগুলো সামলান।';
  static const taskTiming = 'অভিযোগ কখন, কীভাবে জানাবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Words on the controls and papers (not spoken).
  static const tilePhone = 'ফোন';
  static const tileCut = 'বিচ্ছিন্ন করুন';
  static const tileTalk = 'গ্রাহককে বলুন';
  static const rec = 'REC';
  static const stop = 'থামান';
  static const back = 'গলিতে ফিরুন';
  static const clipLabel = 'ক্লিপ';
  static const paperSeizure = 'জব্দ তালিকা';
  static const paperOfficer = 'অফিসারকে জানান — থানায় অভিযোগ';
  static const paperNotice = '15 দিনের নোটিশ ফর্ম';
  static const paperSign = 'সই';
  static const trayHead = 'ভ্যান';
  static const ownerBubble = 'আমার বাড়িতে ঢুকবেন না!';
  static const shopBubble = 'এটাই কি শেষ জরিমানা?';
  static const laneLabel = 'গলি';
  static const closeLabel = 'বাড়ি';
  static const crewChips = ['লাইন OFF', 'টেস্টার 0 V', 'আর্থ', 'গ্লাভস', 'হুক খোলা'];
  static const crewChipsBypass = ['পোল ফিউজ OFF', 'টেস্টার 0 V', 'আর্থ', 'গ্লাভস', 'লুপ খোলা'];

  // The reasons: the spec's seven questions (the first reworded: the clip).
  static const qVideo = 'কেন আগে ভিডিও করলেন?';
  static const qPole = 'পোল থেকে তারটা কেন ধরলেন?';
  static const qNoFir = 'দোকানে কেন FIR করলেন না?';
  static const qExplain = 'দোকানদারকে কী বোঝালেন, কেন?';
  static const qSeizure = 'কেন জব্দ তালিকা করলেন?';
  static const qGate = 'গেটে ঝগড়া না করে কেন আইনের কথা বললেন?';
  static const qComplaint = 'অভিযোগ কেন আজই অফিসারের মাধ্যমে?';
  static String whyQ(M8Why w) => switch (w) {
        M8Why.video => qVideo,
        M8Why.pole => qPole,
        M8Why.noFir => qNoFir,
        M8Why.explain => qExplain,
        M8Why.seizure => qSeizure,
        M8Why.gate => qGate,
        M8Why.complaint => qComplaint,
      };

  static const whyRight = <M8Why, List<String>>{
    M8Why.video: ['আদালতে প্রমাণই কোম্পানিকে বাঁচায়', 'চোর অস্বীকার করলে প্রমাণ লাগবেই'],
    M8Why.pole: ['পোল থেকে তার দেখা গেলে তবেই প্রমাণ', 'হুক থেকে তারটা ধরলে তবে প্রমাণ হয়'],
    M8Why.noFir: ['সেকশন 126-এ FIR হয় না, জরিমানা হয়', 'এটা অননুমোদিত ব্যবহার, চুরির মামলা নয়'],
    M8Why.explain: ['ট্যারিফ না বদলালে তার বিশাল ক্ষতি হবে', 'ঘরের কানেকশনে দোকান চললে জরিমানা হয়'],
    M8Why.seizure: ['রেইড-চেকিংয়ে জব্দ তালিকা বানাতেই হয়', 'জব্দ তালিকা ছাড়া রেইড অসম্পূর্ণ থাকে'],
    M8Why.gate: ['সাপ্লাই কোড চত্বরে ঢোকার অধিকার দেয়', 'বিনীতভাবে আইনের কথা বলাটাই নিয়ম'],
    M8Why.complaint: ['চুরিতে 24 ঘন্টার মধ্যে অভিযোগ জানাতে হয়', 'অভিযোগ যায় অফিসারের মাধ্যমে, আজই'],
  };

  static const _excuses = [
    'তাড়াতাড়ি কাজ শেষ করাটাই আসল কথা',
    'এসব নিয়ম শুধু খাতাতেই লেখা থাকে',
    'অভিজ্ঞ লাইনম্যানের এসব নিয়ম লাগে না',
  ];
  static const _wrong = <M8Why, List<String>>{
    M8Why.video: ['প্রমাণ ছাড়াই লাইন কাটলে চলে যায়', 'ভিডিও তো শুধু ফোনের জায়গা খায়'],
    M8Why.pole: ['যেকোনো তার দেখালেই প্রমাণ হয়ে যায়', 'বাড়ির ছবি থাকলেই প্রমাণ যথেষ্ট'],
    M8Why.noFir: ['দোকানদার চোর, তাই FIR করাই উচিত', 'FIR করলে জরিমানা আরও বেড়ে যায়'],
    M8Why.explain: ['চুপ করে থাকলেই ঝামেলা অনেক কম থাকে', 'জরিমানার কথা অফিস নিজেই পরে জানাবে'],
    M8Why.seizure: ['তালিকা বানালে সময় নষ্ট হয় শুধু', 'জব্দ তালিকা বানানো শুধু পুলিশের কাজ'],
    M8Why.gate: ['গলা চড়ালেই লোকে ভয় পেয়ে সরে যায়', 'আইনের কথা বললে মালিক আরও রেগে যায়'],
    M8Why.complaint: ['থানায় একবার গেলেই যথেষ্ট, দেরি চলে', 'সপ্তাহের শেষে জানালেও কোনো ক্ষতি নেই'],
  };
  static List<String> wrongFor(M8Why w) => [..._wrong[w]!, ..._excuses];
  static List<String> get myths => [..._excuses, for (final l in _wrong.values) ...l];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The field decks (right phrasings; wrong ones map to a slip).
  static const gate1Right = ['বিনীতভাবে সাপ্লাই কোডের অধিকার বলি', 'আইন অনুযায়ী মিটার দেখার অধিকার বলি'];
  static const gate2Right = ['অফিসারকে বলি পুলিশ ডেকে দিতে', 'নিয়ম মেনে পুলিশ ডাকার ব্যবস্থা করি'];
  static const shop1Right = ['ট্যারিফ না বদলালে বিশাল জরিমানা হবে', 'ঘরের মিটারে দোকান চালালে জরিমানা হবে'];
  static const shop2Right = ['আগে প্রভিশনাল, আপত্তি-শুনানির পর ফাইনাল', 'প্রভিশনাল এখন, শুনানির পরেই ফাইনাল হবে'];
  static const timingRight = ['আজই অফিসারের মাধ্যমে, 24 ঘন্টার মধ্যে', 'আজকেই অফিসারকে দিয়ে জানাই, 24 ঘন্টায়'];

  static const gateWrong = [
    'জোর করে গেট ঠেলে ভেতরে ঢুকে পড়ি',
    'ধমক দিয়ে বলি এখনই গেট খুলুন',
    'গলা চড়িয়ে ঝগড়া করেই বোঝাই ওকে',
    'গেট ধরে টানাটানি করে ঢুকে যাই',
    'হুমকি দিই যে মামলা করে ছাড়ব ওকে',
    'আরও জোরে চেঁচিয়ে তর্ক করে যাই',
    'দরজা ভেঙে জোর করে ভেতরে ঢুকে যাই',
    'গেটের তালা ভেঙে ভেতরে ঢুকে পড়ি',
  ];
  static const shopFirWrong = ['থানায় FIR করার ব্যবস্থা করে ফেলি', 'এখনই পুলিশ ডেকে FIR করিয়ে দিই'];
  static const shopSilentWrong = ['কিছু না বলে চুপচাপ ফিরে চলে যাই', 'কথা না বলে শুধু ছবি তুলে ফিরি', 'ওর সঙ্গে কোনো কথাই বলব না আর'];
  static const shopFinalWrong = [
    'হ্যাঁ, এটাই ফাইনাল, আর কিছু নেই',
    'কিছু করার নেই, এটাই শেষ কথা বলি',
    'আপত্তি করে লাভ নেই, এটাই শেষ বলি',
    'এই টাকাটাই শেষ, নতুন বিল হবে না',
    'হ্যাঁ, বিল একবারই দেওয়া হয়, শেষ',
  ];
  static const timingWrong = [
    'সপ্তাহের রিপোর্টে সবার সঙ্গে জানাব',
    'নিজেই থানায় গিয়ে অভিযোগ করে আসব',
    'সুযোগ হলে পরের সপ্তাহে একবার জানাব',
    'দু-তিন দিন পরে জানালেও চলে যাবে',
    'আমি নিজেই থানায় গিয়ে ডায়েরি করব',
  ];

  // The careless coworker (M8-14, M8-18): three pushes, one per play.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerOrder = CoworkerScript(
    line: 'আগে লাইনটা কেটে দাও, ভিডিও-টিডিও পরে হবে।',
    exitLine: coworkerExit,
    right: ['না, আগে প্রমাণ, তারপর লাইন কাটা', 'না, ক্লিপ ছাড়া লাইন কাটব না', 'না, প্রমাণ জোগাড়ই প্রথম কাজ'],
    wrong: [
      'ঠিক, আগে লাইনটা কেটেই দিই',
      'আচ্ছা, প্রমাণ পরে দেখা যাবে',
      'হ্যাঁ, চোর তো হাতেনাতে ধরা',
      'ঠিক আছে, ক্লিপের আর কী দরকার',
      'হ্যাঁ, আগে কাটি, পরে ভাবব',
    ],
    asks: ['কী করবেন?', 'ও বলছে আগেই কাটতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerShop = CoworkerScript(
    line: 'দোকানদার তো চোর — থানায় FIR করে দাও।',
    exitLine: coworkerExit,
    right: ['না, এখানে FIR নয়, জরিমানার কেস', 'না, সেকশন 126-এ FIR হয় না', 'না, আগে ওকে ট্যারিফ বুঝিয়ে দেব'],
    wrong: [
      'ঠিক, চোরকে থানাতেই তুলে দেব',
      'আচ্ছা, FIR-এর ব্যবস্থাই করে ফেলি',
      'হ্যাঁ, দোকানদার তো আসলে চোরই',
      'ঠিক আছে, এখনই পুলিশ ডেকে দিই',
      'হ্যাঁ, ওকে বোঝানো তো বৃথাই, দেখো',
    ],
    asks: ['কী করবেন?', 'ও বলছে FIR করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerTray = CoworkerScript(
    line: 'ঝামেলা কোরো না, নোটিশ ধরিয়ে চলে চলো।',
    exitLine: coworkerExit,
    right: ['না, চুরিতে কোনো নোটিশ লাগে না', 'না, আগে জব্দ তালিকা আর অভিযোগ', 'না, নোটিশ নয়, জব্দ তালিকা আগে'],
    wrong: [
      'ঠিক, নোটিশ দিলেই সব মিটে যায়',
      'আচ্ছা, নোটিশ দিয়ে ফিরে চলে যাই',
      'হ্যাঁ, ঝামেলা না করাই বরং ভালো',
      'ঠিক আছে, তালিকা পরে করে নেব',
      'হ্যাঁ, অভিযোগ করে আর কী হবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে নোটিশ দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M8Push p) => switch (p) {
        M8Push.order => coworkerOrder,
        M8Push.shop => coworkerShop,
        M8Push.tray => coworkerTray,
      };
  static const allCoworkers = [coworkerOrder, coworkerShop, coworkerTray];
  static String callHeld(M8Push p) => switch (p) {
        M8Push.order => 'ঠিক! আগে প্রমাণ, তারপর লাইন বিচ্ছিন্ন।',
        M8Push.shop => 'ঠিক! দোকানে FIR নয়, জরিমানা।',
        M8Push.tray => 'ঠিক! চুরিতে নোটিশ নয়।',
      };

  static const allSet = 'আগে প্রমাণ, পরে কাটা — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে প্রমাণ, তারপর লাইন কাটা।';

  // "আজ যা ধরলেন".
  static const caughtClip = 'আগে প্রমাণ, তারপর লাইন কেটেছেন';
  static const caughtSeizure = 'জব্দ তালিকা করতে ভোলেননি';
  static const caughtComplaint = '24 ঘন্টার মধ্যে অফিসারের মাধ্যমে অভিযোগ';
  static const caughtShop = 'দোকানে FIR নয়, জরিমানার কথা বুঝিয়েছেন';
  static const caughtGate = 'ঝগড়া না করে আইনের কথা বলেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// New coworker lines for recording (his exit is recorded already).
  static List<String> get newRivalLines => [for (final s in allCoworkers) s.line];

  /// New guide lines for recording: the opening, the tasks, the reason
  /// questions, his asks, the praise after refusing him, the end lines and
  /// every mistake text (read out the first time it comes).
  static List<String> get newGuideLines => [
        intro,
        askWhere,
        taskTiles,
        taskRec,
        taskStop,
        taskGate,
        taskShop,
        taskTray,
        taskTiming,
        for (final w in M8Why.values) whyQ(w),
        for (final s in allCoworkers) s.asks[1],
        for (final p in M8Push.values) callHeld(p),
        allSet,
        quick,
        fail,
        for (final m in M8TheftMistakes.all) m.textBn,
      ];
}

abstract final class M8TheftMistakes {
  static const _dir = 'assets/game/art/m8_theft_evidence';
  static const _k = '8.2/m8_theft_evidence';

  // Lesson points (0-based): 0 Sec 135 theft, 1 evidence first + 24 h through
  // the officer, 2 seizure list, 3 video before the hook, 4 Sec 126 (no FIR,
  // assessment), 5 provisional/final, 6 right of access, 7 no notice for
  // theft. DRAFT wording — owner.
  static const noEvidence = DoMistake(
    key: '$_k/no-evidence',
    textBn: 'আগে প্রমাণ, তারপর লাইন কাটা! ফোনে পোল থেকে তারটা রেকর্ড না করে বিচ্ছিন্ন করবেন না।',
    art: '$_dir/evidence.svg',
    lessonPoint: 3,
  );
  static const badClip = DoMistake(
    key: '$_k/bad-clip',
    textBn: 'ক্লিপে তারটা পোল থেকে পুরোটা ধরা নেই। প্রমাণ হতে হবে হুক থেকে বাড়ি পর্যন্ত, বাইপাসে মিটার ঘিরে লুপ।',
    art: '$_dir/evidence.svg',
    lessonPoint: 3,
  );
  static const innocentHouse = DoMistake(
    key: '$_k/innocent-house',
    textBn: 'এখানে চুরির কোনো প্রমাণ নেই! বিনা প্রমাণে সংযোগ কাটা চলবে না।',
    art: '$_dir/innocent.svg',
    lessonPoint: 1,
  );
  static const innocentShop = DoMistake(
    key: '$_k/innocent-shop',
    textBn: 'দোকানে ঘরোয়া কানেকশন চালানো সেকশন 126, চুরি নয়। লাইন কাটা নয়, গ্রাহককে বোঝান।',
    art: '$_dir/shop.svg',
    lessonPoint: 4,
  );
  static const shopFir = DoMistake(
    key: '$_k/shop-fir',
    textBn: 'এখানে এফআইআর হয় না, কড়া জরিমানা (Assessment) হয়। গ্রাহককে বোঝান।',
    art: '$_dir/shop.svg',
    lessonPoint: 4,
  );
  static const shopSilent = DoMistake(
    key: '$_k/shop-silent',
    textBn: 'চুপ করে থাকলে চলবে না। বোঝান: ট্যারিফ পরিবর্তন না করলে তার বিশাল ক্ষতি হবে।',
    art: '$_dir/shop.svg',
    lessonPoint: 4,
  );
  static const shopFinal = DoMistake(
    key: '$_k/shop-final',
    textBn: 'প্রথমে প্রভিশনাল বিল দেওয়া হয়। গ্রাহক আপত্তি জানালে শুনানির পর ফাইনাল অর্ডার হয়।',
    art: '$_dir/shop.svg',
    lessonPoint: 5,
  );
  static const gateFight = DoMistake(
    key: '$_k/gate-fight',
    textBn: 'ঝগড়া নয়! সাপ্লাই কোড চত্বরে ঢোকার অধিকার দিয়েছে। বিনীতভাবে আইনের কথা বলুন, দরকারে পুলিশ ডাকুন।',
    art: '$_dir/gate.svg',
    lessonPoint: 6,
  );
  static const noSeizure = DoMistake(
    key: '$_k/no-seizure',
    textBn: 'রেইড বা চেকিং-এর সময় জব্দ তালিকা (Seizure List) তৈরি করতে ভুলবেন না।',
    art: '$_dir/seizure.svg',
    lessonPoint: 2,
  );
  static const noticeTheft = DoMistake(
    key: '$_k/notice-theft',
    textBn: 'চুরির ক্ষেত্রে (Sec 135) কোনো নোটিশ লাগে না। কাজ হলো জব্দ তালিকা আর অভিযোগ।',
    art: '$_dir/seizure.svg',
    lessonPoint: 7,
  );
  static const complaintLate = DoMistake(
    key: '$_k/complaint-late',
    textBn: '24 ঘন্টার মধ্যে, অফিসারের মাধ্যমে থানায় অভিযোগ জানাতে হবে। দেরি নয়, নিজে গিয়েও নয়।',
    art: '$_dir/complaint.svg',
    lessonPoint: 1,
  );
  static const needlessTalk = DoMistake(
    key: '$_k/needless-talk',
    textBn: 'এখানে এখন গ্রাহককে বলার কিছু নেই। আগে দেখুন কোথায় কী দরকার।',
    art: '$_dir/innocent.svg',
    lessonPoint: 4,
  );
  static const pushOrder = DoMistake(
    key: '$_k/push-order',
    textBn: 'প্রমাণ ছাড়া আগে লাইন কাটা নয়! আগে ক্লিপ, তারপর লাইন বিচ্ছিন্ন।',
    art: '$_dir/evidence.svg',
    lessonPoint: 3,
  );
  static const pushShop = DoMistake(
    key: '$_k/push-shop',
    textBn: 'দোকানে ঘরোয়া কানেকশন সেকশন 126-এর কেস। FIR নয়, জরিমানা।',
    art: '$_dir/shop.svg',
    lessonPoint: 4,
  );
  static const pushTray = DoMistake(
    key: '$_k/push-tray',
    textBn: 'চুরিতে নোটিশ লাগে না, কিন্তু জব্দ তালিকা আর অভিযোগ বাদ যায় না।',
    art: '$_dir/seizure.svg',
    lessonPoint: 7,
  );

  static const List<DoMistake> all = [
    noEvidence,
    badClip,
    innocentHouse,
    innocentShop,
    shopFir,
    shopSilent,
    shopFinal,
    gateFight,
    noSeizure,
    noticeTheft,
    complaintLate,
    needlessTalk,
    pushOrder,
    pushShop,
    pushTray,
  ];

  static DoMistake push(M8Push p) => switch (p) {
        M8Push.order => pushOrder,
        M8Push.shop => pushShop,
        M8Push.tray => pushTray,
      };

  /// The slip a wrong card of [deck] costs.
  static DoMistake forCard(M8Deck deck, String card) {
    switch (deck) {
      case M8Deck.gate1:
      case M8Deck.gate2:
        return gateFight;
      case M8Deck.shop1:
        return M8TheftLines.shopFirWrong.contains(card) ? shopFir : shopSilent;
      case M8Deck.shop2:
        return shopFinal;
      case M8Deck.timing:
        return complaintLate;
    }
  }

  /// The catalog's deadlyRules for do_8_2_b: none (ruling M8-1, row R7).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

@immutable
class M8TheftDeal {
  const M8TheftDeal({
    required this.looks,
    required this.access,
    required this.refuses,
    required this.followUp,
    required this.push,
    required this.whyCut,
    required this.whyShop,
    required this.whyClose,
    required this.trayOrder,
  });

  /// One look per premises, left to right.
  final List<M8Look> looks;

  /// The owner of the bypass house blocks the gate (dealt), and whether he
  /// still refuses after the law is stated (dealt).
  final bool access;
  final bool refuses;

  /// The shopkeeper's follow-up question (dealt).
  final bool followUp;
  final M8Push push;
  final M8Why whyCut;
  final M8Why whyShop;
  final M8Why whyClose;
  final List<M8Paper> trayOrder;

  int get n => looks.length;
  int get shop => looks.indexWhere((l) => l.kind == M8Kind.shop);
  int get bypass => looks.indexWhere((l) => l.kind == M8Kind.bypass);
  List<int> get theft => [for (var i = 0; i < n; i++) if (m8IsTheft(looks[i].kind)) i];
  int get firstHooking => looks.indexWhere((l) => l.kind == M8Kind.hooking);
}

/// A fresh play: 3-4 premises (1-2 hooking, 0-1 bypass, exactly 1 shop, the
/// rest honest), each hook's conductor, spot, route and the trees; the access
/// event, the shop follow-up, the coworker's push, the reason topics and the
/// close-out papers' order.
M8TheftDeal m8TheftDeal(math.Random rng) {
  final n = 3 + rng.nextInt(2);
  var hooking = 1 + rng.nextInt(2);
  var bypass = rng.nextInt(2);
  while (hooking + bypass + 1 > n) {
    if (bypass == 1) {
      bypass = 0;
    } else {
      hooking--;
    }
  }
  final kinds = <M8Kind>[
    for (var i = 0; i < hooking; i++) M8Kind.hooking,
    if (bypass == 1) M8Kind.bypass,
    M8Kind.shop,
  ];
  while (kinds.length < n) {
    kinds.add(M8Kind.normal);
  }
  kinds.shuffle(rng);
  final dusk = rng.nextBool();
  final looks = [
    for (final k in kinds)
      M8Look(
        kind: k,
        hookRow: rng.nextInt(4),
        hookCol: rng.nextInt(4),
        entry: rng.nextInt(2),
        sag: rng.nextInt(3),
        tree: rng.nextBool(),
        dusk: dusk,
      ),
  ];
  return M8TheftDeal(
    looks: looks,
    access: bypass == 1 && rng.nextBool(),
    refuses: rng.nextBool(),
    followUp: rng.nextBool(),
    push: M8Push.values[rng.nextInt(3)],
    whyCut: rng.nextBool() ? M8Why.video : M8Why.pole,
    whyShop: rng.nextBool() ? M8Why.noFir : M8Why.explain,
    whyClose: rng.nextBool() ? M8Why.seizure : M8Why.complaint,
    trayOrder: [...M8Paper.values]..shuffle(rng),
  );
}

/// One clip: a trace over a premises (kept whatever it holds).
@immutable
class M8Clip {
  const M8Clip(this.id, this.at, this.trace, this.verdict);
  final int id;
  final int at;
  final List<Offset> trace;

  /// Hidden from the player until the disconnect.
  final M8Verdict verdict;
  bool get valid => verdict.valid;
}

/// The play state (pure logic).
class M8TheftRun {
  M8TheftRun(this.deal) : clips = List.generate(deal.n, (_) => <M8Clip>[]);
  final M8TheftDeal deal;

  static const clipMax = 3;

  int slips = 0;
  final List<String> caught = [];
  final List<List<M8Clip>> clips;
  final Set<int> visited = {};
  final Set<int> disconnected = {};
  final Set<int> closed = {};
  final Set<int> gateDone = {};
  int _nextId = 0;

  var shopDone = false;
  var seizure = false;
  var complaint = false;

  /// Slips since the last ◆ table (a clean step earns +5 more).
  int stepSlips = 0;

  bool get done => deal.theft.every(closed.contains) && shopDone;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return m;
  }

  void stepDone() => stepSlips = 0;
  DoMistake pushSlip(DoMistake m) => _slip(m);
  DoMistake wrongCard(M8Deck d, String card) => _slip(M8TheftMistakes.forCard(d, card));

  /// A recording stopped at premises [at] (the oldest clip drops out past
  /// [clipMax]). Every clip is kept; none is judged out loud.
  M8Clip? saveClip(int at, List<Offset> trace) {
    if (trace.length < 2 || disconnected.contains(at)) return null;
    final c = M8Clip(_nextId++, at, List.of(trace), m8Judge(trace, deal.looks[at]));
    final list = clips[at];
    if (list.length >= clipMax) list.removeAt(0);
    list.add(c);
    return c;
  }

  /// 'বিচ্ছিন্ন করুন' at [i]: a slip on an honest premises, with no clip or a
  /// clip that does not follow the stealing wire; else it is cut.
  DoMistake? disconnect(int i) {
    if (disconnected.contains(i)) return null;
    final k = deal.looks[i].kind;
    if (!m8IsTheft(k)) return _slip(k == M8Kind.shop ? M8TheftMistakes.innocentShop : M8TheftMistakes.innocentHouse);
    final list = clips[i];
    if (list.isEmpty) return _slip(M8TheftMistakes.noEvidence);
    if (!list.any((c) => c.valid)) return _slip(M8TheftMistakes.badClip);
    disconnected.add(i);
    seizure = false;
    complaint = false;
    _tag(M8TheftLines.caughtClip);
    return null;
  }

  /// 'গ্রাহককে বলুন' off the shop: a needless act.
  DoMistake? needlessTalk(int i) => deal.looks[i].kind == M8Kind.shop || shopDone ? null : _slip(M8TheftMistakes.needlessTalk);

  void shopHandled() {
    shopDone = true;
    _tag(M8TheftLines.caughtShop);
  }

  void gateResolved(int i) {
    gateDone.add(i);
    _tag(M8TheftLines.caughtGate);
  }

  /// A paper on the van's tray: the seizure list signed; the complaint
  /// before it (leaving without the list) or the notice form = a slip.
  DoMistake? paper(M8Paper p) {
    switch (p) {
      case M8Paper.seizure:
        if (!seizure) {
          seizure = true;
          _tag(M8TheftLines.caughtSeizure);
        }
        return null;
      case M8Paper.officer:
        return seizure ? null : _slip(M8TheftMistakes.noSeizure);
      case M8Paper.notice:
        return _slip(M8TheftMistakes.noticeTheft);
    }
  }

  /// The timing deck's right card: the complaint goes through the officer.
  void complaintSent() {
    complaint = true;
    _tag(M8TheftLines.caughtComplaint);
  }

  bool get trayDone => seizure && complaint;

  void closeOut(int i) {
    closed.add(i);
    seizure = false;
    complaint = false;
  }
}

/// The quick bonus: the builder's estimate (~85 % of a clean play, ruling
/// M8-15; quickMs after playtest). A clean play with 3-4 premises ≈ walks
/// (~12 s) + two traces (~20 s) + two disconnects with cut-scenes (~12 s) +
/// two close-outs (~24 s) + the shop's decks (~14 s) + five reasons (~40 s) +
/// the coworker (~10 s) ≈ 130 s.
const m8TheftQuickMs = 110000;

@immutable
class M8TheftPack {
  const M8TheftPack({required this.id, required this.titleBn, this.quickMs = m8TheftQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8TheftPack> m8TheftPacks = {
  'do_8_2_b': M8TheftPack(id: 'do_8_2_b', titleBn: M8TheftLines.title),
};

/// Test hook (tests only): the open play's run and the same moves a finger
/// makes.
class M8TheftProbe {
  M8TheftProbe._(this._s);
  final _TheftRunPageState _s;
  static M8TheftProbe? current;

  M8TheftRun get run => _s._run;
  M8TheftDeal get deal => _s._run.deal;
  M8LaneGeo? get lane => _s._laneNow;
  bool get inLane => !_s._close;
  int get at => _s._at;
  bool get phoneOpen => _s._phone;
  bool get recording => _s._recording;
  bool get trayOpen => _s._tray;
  M8Deck? get deck => _s._deckKind;
  double get oy => _s._oy;
  List<Offset> get trace => _s._trace;

  void tapPremises(int i) => _s._tapPremises(i);
  void back() => _s._backToLane();
  void phone() => _s._openPhone();
  void startRec() => _s._startRec();

  /// A finger run along [path] (block pixels) while recording.
  void drag(List<Offset> path) => _s._dragPath(path);
  void stopRec() => _s._stopRec();
  void cut() => unawaited(_s._cutHeld());
  void talk() => _s._talk();
  void sign() => _s._signHeld();
  void tapPaper(M8Paper p) => _s._tapPaper(p);

  /// Records [path] at the open premises and stops (no touch needed).
  void clip(List<Offset> path) {
    _s._openPhone();
    _s._startRec();
    _s._dragPath(path);
    _s._stopRec();
  }
}

// ============================================================================
// Page
// ============================================================================

class M8TheftEvidencePage extends StatefulWidget {
  const M8TheftEvidencePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8TheftPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8TheftEvidencePage> createState() => _M8TheftEvidencePageState();
}

class _M8TheftEvidencePageState extends State<M8TheftEvidencePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TheftRunPage(
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

class _TheftRunPage extends ConsumerStatefulWidget {
  const _TheftRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8TheftPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TheftRunPage> createState() => _TheftRunPageState();
}

/// What follows a paid reason.
enum _After { tray, lane, tiles }

class _TheftRunPageState extends ConsumerState<_TheftRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  static const _tilesH = 78.0;
  static const _thumbH = 64.0;

  final _scoreKey = GlobalKey();
  late final M8TheftRun _run;
  late final int _seed = widget.rng.nextInt(1 << 20);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  int _taskChain = -1;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  // Where the trainee is: the lane or a premises' close-up.
  var _close = false;
  int _at = 0;
  M8LaneGeo? _laneNow;
  M8LanePainter? _lanePainter;
  M8CloseUpPainter? _closePainter;
  double _oy = 70;
  late final AnimationController _walkC = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  double _walkFrom = 0, _walkTo = 0;
  var _walking = false;
  int _traineeStart = 0;
  double _traineeX = 60;

  // The phone and the trace.
  var _phone = false;
  var _recording = false;
  var _trace = <Offset>[];
  final _traceTick = ValueNotifier<int>(0);
  var _panHinted = false;
  int _flagClip = -1;
  var _holdHint = false;

  // The field decks and the tray.
  M8Deck? _deckKind;
  List<ChoiceOption> _deckOpts = const [];
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  var _deckBusy = false;
  var _tray = false;
  var _trayPushed = false;
  var _signed = false;
  var _bubble = '';
  int _cutStep = -1;
  var _afterReason = _After.lane;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  Offset _downAt = Offset.zero;
  var _downMoved = false;

  // The gesture hand.
  final _hints = IdleHintController();
  final _recKey = GlobalKey();
  final _stopKey = GlobalKey();
  final _tileKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final Map<M8Paper, GlobalKey> _paperKeys = {for (final p in M8Paper.values) p: GlobalKey()};
  int _hintN = 0;

  @override
  void initState() {
    super.initState();
    _run = M8TheftRun(m8TheftDeal(widget.rng));
    M8TheftProbe.current = M8TheftProbe._(this);
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M8TheftDeal get _deal => _run.deal;
  final Set<int> _cutShown = {};
  M8Look _look(int i) => _deal.looks[i].withCut(_cutShown.contains(i));

  @override
  void dispose() {
    disposeCoworker();
    _walkC.dispose();
    _traceTick.dispose();
    _chain++;
    if (M8TheftProbe.current?._s == this) M8TheftProbe.current = null;
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

  /// A task line said: the gesture hand waits while it is said, then the
  /// bubble clears so it never stands over the scene while the player works.
  Future<void> _sayTask(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    if (lines.isEmpty) return;
    final chain = _chain + 1;
    _taskChain = chain;
    await _sayChain(lines, mood: mood);
    if (_muted) await Future<void>.delayed(MascotSpeechLibrary.readHold(lines.last));
    if (!mounted || chain != _chain) return;
    final guide = ref.read(guideDirectorProvider);
    if (guide.line == lines.last) ref.read(guideDirectorProvider.notifier).softClearLine();
    setState(() => _taskChain = -1);
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

  bool get _deckUp => _deckKind != null;
  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && _cutStep < 0 && !_walking;
  bool get _tiles => _close && !_phone && !_deckUp && !_tray;

  String get _task {
    if (!_close) return M8TheftLines.askWhere;
    if (_tray) return _deckKind == M8Deck.timing ? M8TheftLines.taskTiming : M8TheftLines.taskTray;
    switch (_deckKind) {
      case M8Deck.gate1:
      case M8Deck.gate2:
        return M8TheftLines.taskGate;
      case M8Deck.shop1:
      case M8Deck.shop2:
        return M8TheftLines.taskShop;
      case M8Deck.timing:
        return M8TheftLines.taskTiming;
      case null:
        break;
    }
    if (_phone) return _recording ? M8TheftLines.taskStop : M8TheftLines.taskRec;
    return M8TheftLines.taskTiles;
  }

  // --- the flow ----------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayTask([M8TheftLines.askWhere]));
  }

  // --- the lane ----------------------------------------------------------------
  void _tapPremises(int i) {
    if (!_canPlay || _close || i < 0 || i >= _deal.n) return;
    final g = _laneNow;
    if (g == null) return;
    _hush();
    _tick();
    _walkFrom = _traineeX;
    _walkTo = g.standX(i);
    _at = i;
    if (_quiet || (_walkTo - _walkFrom).abs() < 2) {
      _traineeX = _walkTo;
      _arrive(i);
      return;
    }
    setState(() => _walking = true);
    _walkC.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _traineeX = _walkTo;
      setState(() => _walking = false);
      _arrive(i);
    });
  }

  void _arrive(int i) {
    if (!mounted || _ended) return;
    _run.visited.add(i);
    final k = _deal.looks[i].kind;
    final p = _deal.push;
    if (!coworkerDone && !coworkerDue) {
      if ((p == M8Push.order && k == M8Kind.hooking) || (p == M8Push.shop && k == M8Kind.shop)) scheduleCoworker();
    }
    setState(() {
      _close = true;
      _closePainter = null;
      _phone = false;
      _recording = false;
      _trace = [];
      _holdHint = false;
      _bubble = '';
      _wake++;
    });
    if (k == M8Kind.bypass && _deal.access && !_run.gateDone.contains(i)) {
      unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_ended && _close && _at == i) _openGate();
      }));
      return;
    }
    unawaited(_sayTask([M8TheftLines.taskTiles]));
  }

  void _backToLane() {
    if (!_canPlay || !_close || _phone || _deckUp || _tray) return;
    _tick();
    setState(() {
      _close = false;
      _lanePainter = null;
      _bubble = '';
      _flagClip = -1;
      _wake++;
    });
    unawaited(_sayTask([M8TheftLines.askWhere]));
  }

  // --- the phone and the trace ---------------------------------------------------
  void _openPhone() {
    if (!_canPlay || !_tiles) return;
    if (holdForCoworker()) return;
    _tick();
    setState(() {
      _phone = true;
      _recording = false;
      _flagClip = -1;
      _wake++;
    });
    unawaited(_sayTask([M8TheftLines.taskRec]));
  }

  void _closePhone() {
    if (!_phone || _recording || !_canPlay) return;
    _tick();
    setState(() => _phone = false);
    unawaited(_sayTask([M8TheftLines.taskTiles]));
  }

  void _startRec() {
    if (!_canPlay || !_phone || _recording) return;
    _tick('sounds/intro/click.ogg', 0.8);
    HapticFeedback.lightImpact();
    setState(() {
      _recording = true;
      _trace = [];
      _panHinted = false;
      _wake++;
    });
    _traceTick.value++;
    unawaited(_sayTask([M8TheftLines.taskStop]));
  }

  void _addPoint(Offset block) {
    if (!_recording) return;
    if (_trace.isNotEmpty && (_trace.last - block).distance < 3) return;
    _trace.add(block);
    _traceTick.value++;
  }

  void _dragPath(List<Offset> path) {
    if (!_recording) return;
    for (final p in path) {
      _addPoint(p);
    }
  }

  void _stopRec() {
    if (!_canPlay || !_recording) return;
    _tick('sounds/intro/confirm.ogg', 0.6);
    _run.saveClip(_at, _trace);
    setState(() {
      _recording = false;
      _phone = false;
      _trace = [];
      _wake++;
    });
    _traceTick.value++;
    unawaited(_sayTask([M8TheftLines.taskTiles]));
  }

  // --- the three tiles -------------------------------------------------------------
  void _talk() {
    if (!_canPlay || !_tiles) return;
    if (holdForCoworker()) return;
    final i = _at;
    if (_deal.looks[i].kind == M8Kind.shop && !_run.shopDone) {
      _tick();
      _openDeck(M8Deck.shop1);
      return;
    }
    final m = _run.needlessTalk(i);
    if (m != null) unawaited(_mistake(m, _centre));
  }

  /// A short press on the cut tile: it needs a hold (the hint shows how).
  void _cutShort() {
    if (!_canPlay || !_tiles) return;
    _tick();
    setState(() => _holdHint = true);
    _hints.missTap();
  }

  Future<void> _cutHeld() async {
    if (!_canPlay || !_tiles) return;
    if (holdForCoworker()) return;
    final i = _at;
    if (_run.disconnected.contains(i)) return;
    final m = _run.disconnect(i);
    if (m != null) {
      final list = _run.clips[i];
      setState(() {
        _holdHint = false;
        _flagClip = list.isEmpty ? -1 : list.last.id;
      });
      unawaited(_mistake(m, _centre));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() {
      _holdHint = false;
      _flagClip = -1;
      _cutStep = 0;
      _closePainter = null;
      _lanePainter = null;
    });
    final bypass = _deal.looks[i].kind == M8Kind.bypass;
    final chips = bypass ? M8TheftLines.crewChipsBypass : M8TheftLines.crewChips;
    for (var s = 1; s <= chips.length; s++) {
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 40 : 520));
      if (!mounted || _ended) return;
      setState(() => _cutStep = s);
    }
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 40 : 600));
    if (!mounted || _ended) return;
    setState(() {
      _cutStep = -1;
      _cutShown.add(i);
      _closePainter = null;
      _lanePainter = null;
    });
    _afterReason = _After.tray;
    _table(_deal.whyCut, base: 15);
  }

  // --- the field decks -----------------------------------------------------------------
  void _openGate() {
    if (!_canPlay) return;
    setState(() => _bubble = M8TheftLines.ownerBubble);
    _openDeck(M8Deck.gate1);
  }

  void _openDeck(M8Deck d) {
    final (right, wrong) = switch (d) {
      M8Deck.gate1 => (M8TheftLines.gate1Right, M8TheftLines.gateWrong),
      M8Deck.gate2 => (M8TheftLines.gate2Right, M8TheftLines.gateWrong),
      M8Deck.shop1 => (M8TheftLines.shop1Right, [...M8TheftLines.shopFirWrong, ...M8TheftLines.shopSilentWrong]),
      M8Deck.shop2 => (M8TheftLines.shop2Right, M8TheftLines.shopFinalWrong),
      M8Deck.timing => (M8TheftLines.timingRight, M8TheftLines.timingWrong),
    };
    setState(() {
      _deckKind = d;
      _deckOpts = dealChoices(right, wrong, widget.rng);
      _deckWrong.clear();
      _deckPicked = null;
      _deckBusy = false;
      if (d == M8Deck.shop2) _bubble = M8TheftLines.shopBubble;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayTask([_task], mood: GuideMood.think));
  }

  Future<void> _pickDeck(ChoiceOption o, Offset origin) async {
    final d = _deckKind;
    if (d == null || _ended || _card != null || _deckBusy || _deckWrong.contains(o.textBn) || _deckPicked != null || coworkerOpen) return;
    _hush();
    if (!o.correct) {
      setState(() => _deckWrong.add(o.textBn));
      final m = _run.wrongCard(d, o.textBn);
      unawaited(_mistake(m, origin));
      return;
    }
    _deckBusy = true;
    setState(() => _deckPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    setState(() {
      _deckKind = null;
      _deckOpts = const [];
      _deckBusy = false;
      _wake++;
    });
    switch (d) {
      case M8Deck.gate1:
        if (_deal.refuses) {
          _openDeck(M8Deck.gate2);
        } else {
          _gateResolved();
        }
      case M8Deck.gate2:
        _gateResolved();
      case M8Deck.shop1:
        if (_deal.followUp) {
          _openDeck(M8Deck.shop2);
        } else {
          _shopResolved();
        }
      case M8Deck.shop2:
        _shopResolved();
      case M8Deck.timing:
        _run.complaintSent();
        _trayStep();
    }
  }

  void _gateResolved() {
    _run.gateResolved(_at);
    setState(() => _bubble = '');
    _afterReason = _After.tiles;
    _table(M8Why.gate);
  }

  void _shopResolved() {
    _run.shopHandled();
    setState(() => _bubble = '');
    _afterReason = _After.lane;
    _table(_deal.whyShop);
  }

  // --- the close-out tray ---------------------------------------------------------------
  void _openTray() {
    if (!mounted || _ended) return;
    setState(() {
      _tray = true;
      _signed = false;
      _phone = false;
      _wake++;
    });
    if (_deal.push == M8Push.tray && !coworkerDone && !coworkerDue) {
      _trayPushed = true;
      scheduleCoworker();
    }
    unawaited(_sayTask([M8TheftLines.taskTray]));
  }

  void _signHeld() {
    if (!_canPlay || !_tray || _deckUp) return;
    if (holdForCoworker()) return;
    if (_signed) return;
    _run.paper(M8Paper.seizure);
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    setState(() {
      _signed = true;
      _holdHint = false;
    });
    unawaited(_levelDelta(5, _centre, mood: GuideMood.glad));
    _trayStep();
  }

  void _tapPaper(M8Paper p) {
    if (!_canPlay || !_tray || _deckUp) return;
    if (holdForCoworker()) return;
    switch (p) {
      case M8Paper.seizure:
        // A short press: it needs a hold.
        _tick();
        setState(() => _holdHint = true);
        _hints.missTap();
      case M8Paper.officer:
        final m = _run.paper(p);
        if (m != null) {
          unawaited(_mistake(m, _centre));
          return;
        }
        if (_run.complaint) return;
        _tick();
        _openDeck(M8Deck.timing);
      case M8Paper.notice:
        final m = _run.paper(p);
        if (m != null) unawaited(_mistake(m, _centre));
    }
  }

  /// A tray step done: when both papers are, the premises is closed out.
  void _trayStep() {
    if (!_run.trayDone) {
      unawaited(_sayTask([_task]));
      return;
    }
    _run.closeOut(_at);
    setState(() {
      _tray = false;
      _signed = false;
      _wake++;
    });
    _afterReason = _After.lane;
    _table(_deal.whyClose, base: 15);
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  /// A step done right: ◆ on the table, then the reason.
  void _table(M8Why w, {int base = 10}) {
    putOnTable(base + (_run.stepSlips == 0 ? 5 : 0));
    _run.stepDone();
    unawaited(askReason(
      deal: () => dealChoices(M8TheftLines.whyRight[w]!, M8TheftLines.wrongFor(w), widget.rng),
      question: M8TheftLines.whyQ(w),
      stillValid: () => !_ended,
    ));
  }

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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (!mounted || _ended) return;
      if (_run.done) {
        unawaited(_finish());
        return;
      }
      switch (_afterReason) {
        case _After.tray:
          _openTray();
        case _After.lane:
          setState(() {
            _close = false;
            _lanePainter = null;
            _bubble = '';
            _wake++;
          });
          unawaited(_sayTask([M8TheftLines.askWhere]));
        case _After.tiles:
          unawaited(_sayTask([M8TheftLines.taskTiles]));
      }
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8TheftLines.coworker(_deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final busy = _intro || _card != null || tableBusy || _cutStep >= 0 || _walking || _deckUp;
    switch (_deal.push) {
      case M8Push.order:
        if (_run.disconnected.isNotEmpty) return null;
        return _close && _deal.looks[_at].kind == M8Kind.hooking && !_phone && !busy;
      case M8Push.shop:
        if (_run.shopDone) return null;
        return _close && _deal.looks[_at].kind == M8Kind.shop && !_phone && !busy;
      case M8Push.tray:
        if (_trayPushed && !_tray) return null;
        return _tray && !busy;
    }
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _deal.push;
    if (!held) {
      final m = _run.pushSlip(M8TheftMistakes.push(p));
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8TheftLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayTask([M8TheftLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    _tick('sounds/intro/tick.ogg', 0.5);
    if (coworkerOpen) {
      unawaited(_sayChain([nextCoworkerAsk()]));
    } else if (reasonOpen) {
      unawaited(_sayChain([M8TheftLines.tapWhy[_nudgeN++ % M8TheftLines.tapWhy.length]]));
    } else {
      unawaited(_sayTask([_nudge.next(_task)]));
    }
  }

  // --- mistakes ---------------------------------------------------------------
  Offset get _centre {
    final s = MediaQuery.sizeOf(context);
    return Offset(s.width / 2, s.height * 0.4);
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

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
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8theft/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _flagClip = -1;
      _wake++;
    });
    unawaited(_sayTask([_task]));
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
    await _say(!_run.passed ? M8TheftLines.fail : (_quickBonus ? M8TheftLines.quick : M8TheftLines.allSet),
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

  // --- pointers (design px of the scene) -------------------------------------------
  void _pointerDown(PointerDownEvent e) {
    _downAt = e.localPosition;
    _downMoved = false;
    if (_close && _recording && _canPlay) {
      _addPoint(e.localPosition - Offset(0, _oy));
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    if ((e.localPosition - _downAt).distance > 8) _downMoved = true;
    if (_close && _recording && _canPlay) _addPoint(e.localPosition - Offset(0, _oy));
  }

  void _pointerUp(PointerEvent e) {
    final up = e is PointerUpEvent;
    if (!up || !_canPlay || _downMoved) return;
    if (!_close) {
      final g = _laneNow;
      if (g == null) return;
      for (var i = 0; i < _deal.n; i++) {
        if (g.premises(i).contains(e.localPosition)) {
          _tapPremises(i);
          return;
        }
      }
      _hints.missTap();
      return;
    }
    if (!_recording) _hints.missTap();
  }

  // --- the gesture hand ------------------------------------------------------------
  /// How to touch, never what. Lane: a sweep over every premises alike.
  /// Tiles: a sweep over all three (after a short press on the cut tile, a
  /// hold on it). The phone before REC: a tap on REC (the one way forward);
  /// recording: a short back-and-forth nudge from the frame's centre (the
  /// same every deal), then a tap on থামান once it has played. Tray: a sweep
  /// over all the papers (after a short press on the list, a hold on it).
  /// The decks have their own.
  HintSpec? _hint() {
    final n = _hintN++;
    if (!_close) {
      final g = _laneNow;
      if (g == null) return null;
      return HintSpec.sweep([for (var i = 0; i < _deal.n; i++) g.premises(i)], space: HintSpace.scene);
    }
    if (_tray) {
      if (_holdHint) return HintSpec.holdOn(_paperKeys[M8Paper.seizure]!);
      return HintSpec.sweepOver([for (final p in _deal.trayOrder) _paperKeys[p]!]);
    }
    if (_phone) {
      if (!_recording) return HintSpec.tapOn(_recKey);
      if (_panHinted && n.isOdd) return HintSpec.tapOn(_stopKey);
      _panHinted = true;
      return HintSpec.drag(Offset(180, _oy + 200), toward: const Offset(1, 0), travel: 80, space: HintSpace.scene);
    }
    if (_holdHint) return HintSpec.holdOn(_tileKeys[1]);
    return HintSpec.sweepOver(_tileKeys);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_walking) return LinemanMode.walk;
    return _phone ? LinemanMode.hold : LinemanMode.idle;
  }

  LinemanLook get _look0 => LinemanLook(
        helmet: LinemanLook.trainee.helmet,
        shirt: LinemanLook.trainee.shirt,
        vest: LinemanLook.trainee.vest,
        pants: LinemanLook.trainee.pants,
        skin: LinemanLook.trainee.skin,
        gloves: true,
        gloveColor: LinemanLook.rubberGloves,
      );

  M8LanePainter _laneFor(M8LaneGeo g) {
    final looks = [for (var i = 0; i < _deal.n; i++) _look(i)];
    final p = _lanePainter;
    if (p != null && p.geo == g && M8LanePainter.sameLooks(p.looks, looks)) return p;
    return _lanePainter = M8LanePainter(geo: g, looks: looks);
  }

  M8CloseUpPainter _closeFor() {
    final look = _look(_at);
    final p = _closePainter;
    if (p != null && p.look == look && p.oy == _oy) return p;
    return _closePainter = M8CloseUpPainter(look: look, oy: _oy, seed: _seed);
  }

  List<Widget> _scene(SceneMetrics m) {
    final quiet = _quiet;
    final w = math.max(1.0, MediaQuery.sizeOf(context).width);
    final top = MediaQuery.paddingOf(context).top * 360 / w;
    final g = _laneNow = M8LaneGeo(_deal.n, m.height);
    _oy = M8Geo.oyFor(m.height, topInset: top);
    if (_traineeStart == 0) {
      _traineeStart = 1;
      _traineeX = g.standX(0) - g.step;
    }
    final List<Widget> world;
    if (!_close) {
      world = [
        Positioned.fill(key: const ValueKey('lane'), child: RepaintBoundary(child: CustomPaint(painter: _laneFor(g)))),
        AnimatedBuilder(
          key: const ValueKey('trainee'),
          animation: _walkC,
          builder: (context, _) {
            final x = _walking ? _walkFrom + (_walkTo - _walkFrom) * Curves.easeInOut.transform(_walkC.value) : _traineeX;
            return Positioned.fromRect(
              rect: g.trainee(x),
              child: LinemanFigure(look: _look0, mode: _mode, wake: _wake, quiet: quiet),
            );
          },
        ),
      ];
    } else {
      world = [
        Positioned.fill(key: ValueKey('close-$_at'), child: RepaintBoundary(child: CustomPaint(painter: _closeFor()))),
        Positioned.fromRect(
          key: const ValueKey('trainee2'),
          rect: Rect.fromLTWH(96, _oy + 296, 62, 92),
          child: LinemanFigure(look: _look0, mode: _mode, wake: _wake, quiet: quiet),
        ),
        if (_bubble.isNotEmpty)
          Positioned(
            key: const ValueKey('bubble'),
            left: 196,
            top: _oy + 232,
            width: 150,
            child: IgnorePointer(child: _Bubble(text: _bubble)),
          ),
        if (_bubble.isNotEmpty)
          Positioned(
            key: const ValueKey('owner'),
            left: 322,
            top: _oy + 282,
            width: 34,
            height: 50,
            child: const IgnorePointer(child: Icon(Icons.person_rounded, size: 46, color: Color(0xFF263238))),
          ),
        if (_phone || _recording)
          Positioned.fill(
            key: const ValueKey('trace'),
            child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M8TracePainter(trace: _trace, oy: _oy, tick: _traceTick)))),
          ),
      ];
    }
    return [
      Positioned.fill(key: ValueKey('world-$_close'), child: Stack(children: world)),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: _close ? M8TheftLines.closeLabel : M8TheftLines.laneLabel,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerUp,
          ),
        ),
      ),
    ];
  }

  Widget _thumbs(double bottom) {
    final list = _run.clips[_at];
    return Positioned(
      key: const ValueKey('clips'),
      left: 10,
      bottom: bottom,
      height: _thumbH,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in list)
            Container(
              key: ValueKey('clip-${c.id}'),
              width: 58,
              height: _thumbH,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.id == _flagClip ? const Color(0xFFE53935) : Colors.white, width: c.id == _flagClip ? 3 : 1.5),
              ),
              child: Semantics(
                label: M8TheftLines.clipLabel,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: RepaintBoundary(child: CustomPaint(painter: M8ThumbPainter(look: _deal.looks[c.at], trace: c.trace), size: const Size(58, _thumbH))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp || _deckUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && _cutStep < 0 && !_walking;
    final tilesBottom = pad.bottom + 10;
    final thumbBottom = tilesBottom + (_tiles ? _tilesH + 8 : 8);
    final guideBottom = _close ? thumbBottom + _thumbH + 4 : pad.bottom + 8;
    final chips = _close && _deal.looks[_at].kind == M8Kind.bypass ? M8TheftLines.crewChipsBypass : M8TheftLines.crewChips;
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _taskChain != _chain && !(_close && _bubble.isNotEmpty),
            hintKey: '$_close/$_at/$_phone/$_recording/$_tray/$_holdHint/${_run.clips[_at.clamp(0, _deal.n - 1)].length}/${_run.disconnected.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 170), quiet: quiet),
              if (playing && _close && !_tray && _cutStep < 0 && !_phone && _canBack)
                Positioned(
                  key: const ValueKey('back-lane'),
                  left: 10,
                  top: pad.top + 60,
                  child: _SmallButton(icon: Icons.arrow_back_rounded, label: M8TheftLines.back, onTap: _backToLane),
                ),
              if (playing && _close && !_tray && _cutStep < 0 && (_run.clips[_at].isNotEmpty) && !deckUp) _thumbs(thumbBottom),
              if (playing && _close && _tiles && _cutStep < 0 && !coworkerOpen && _card == null)
                Positioned(
                  key: const ValueKey('tiles'),
                  left: 10,
                  right: 10,
                  bottom: tilesBottom,
                  height: _tilesH,
                  child: Row(
                    children: [
                      Expanded(child: _Tile(key: _tileKeys[0], icon: Icons.smartphone_rounded, label: M8TheftLines.tilePhone, onTap: _openPhone)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HoldBox(
                          key: _tileKeys[1],
                          ms: 800,
                          onDone: () => unawaited(_cutHeld()),
                          onShort: _cutShort,
                          child: _TileFace(icon: Icons.power_off_rounded, label: M8TheftLines.tileCut),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _Tile(key: _tileKeys[2], icon: Icons.record_voice_over_rounded, label: M8TheftLines.tileTalk, onTap: _talk)),
                    ],
                  ),
                ),
              if (playing && _close && _phone && _cutStep < 0 && _card == null && !coworkerOpen)
                Positioned(
                  key: const ValueKey('rec-bar'),
                  left: 0,
                  right: 0,
                  bottom: tilesBottom,
                  height: _tilesH,
                  child: Center(
                    child: !_recording
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SmallButton(icon: Icons.close_rounded, label: M8TheftLines.back, onTap: _closePhone),
                              const SizedBox(width: 18),
                              _RoundButton(key: _recKey, label: M8TheftLines.rec, color: const Color(0xFFE53935), onTap: _startRec),
                            ],
                          )
                        : _RoundButton(key: _stopKey, label: M8TheftLines.stop, color: Colors.white, dark: true, onTap: _stopRec),
                  ),
                ),
              if (_cutStep >= 0)
                Positioned(
                  key: const ValueKey('crew'),
                  left: 12,
                  right: 12,
                  top: pad.top + 64,
                  child: IgnorePointer(child: _CrewChips(chips: chips, shown: _cutStep)),
                ),
              if (playing && _tray && !coworkerOpen && _card == null)
                Positioned(
                  key: const ValueKey('tray'),
                  left: 0,
                  right: 0,
                  top: pad.top + 64,
                  child: _TrayPanel(
                    order: _deal.trayOrder,
                    keys: _paperKeys,
                    signed: _signed,
                    complaint: _run.complaint,
                    onSign: _signHeld,
                    onTap: _tapPaper,
                    onMiss: _hints.missTap,
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('field-deck-${_deckKind?.name}'),
                                options: _deckOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: (o, at) => unawaited(_pickDeck(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : guideBottom, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M8TheftLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

  bool get _canBack => !_phone && !_deckUp && _bubble.isEmpty;
}

// ============================================================================
// Pieces
// ============================================================================

/// A silent caption bubble (the owner, the shopkeeper).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Text(text, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, height: 1.25, color: const Color(0xFF14202B))),
      );
}

class _TileFace extends StatelessWidget {
  const _TileFace({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xF20B1A33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x88FFFFFF)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: SlmColors.gold400),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, height: 1.1, color: Colors.white)),
          ],
        ),
      );
}

/// One of the three equal tiles.
class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: true,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: _TileFace(icon: icon, label: label)),
      );
}

/// A press that must be held for [ms] (abstract: a bar fills under the
/// finger); a shorter press is [onShort].
class _HoldBox extends StatefulWidget {
  const _HoldBox({super.key, required this.ms, required this.onDone, required this.onShort, required this.child, this.semantic});
  final int ms;
  final VoidCallback onDone;
  final VoidCallback onShort;
  final Widget child;
  final String? semantic;

  @override
  State<_HoldBox> createState() => _HoldBoxState();
}

class _HoldBoxState extends State<_HoldBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms));
  var _held = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && _held) {
        _held = false;
        widget.onDone();
        _c.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    _held = true;
    _c.forward(from: 0);
  }

  void _up() {
    if (!_held) return;
    _held = false;
    final short = _c.value < 1;
    _c.value = 0;
    if (short) widget.onShort();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.semantic ?? (widget.child is _TileFace ? (widget.child as _TileFace).label : null),
        button: true,
        onLongPress: widget.onDone,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _down(),
          onPointerUp: (_) => _up(),
          onPointerCancel: (_) {
            _held = false;
            _c.value = 0;
          },
          child: Stack(
            children: [
              widget.child,
              Positioned(
                left: 8,
                right: 8,
                bottom: 6,
                height: 5,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, _) => _c.value == 0
                        ? const SizedBox.shrink()
                        : FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _c.value,
                            child: DecoratedBox(decoration: BoxDecoration(color: SlmColors.emerald500, borderRadius: BorderRadius.circular(3))),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xE60B1A33), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x88FFFFFF))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(width: 6),
                Text(label, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.label, required this.color, required this.onTap, this.dark = false});
  final String label;
  final Color color;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: dark ? SlmColors.navy950 : Colors.white)),
          ),
        ),
      );
}

/// The crew's cut-scene, as chips lighting in turn (nothing to do, nothing
/// scored: the Module 7 order).
class _CrewChips extends StatelessWidget {
  const _CrewChips({required this.chips, required this.shown});
  final List<String> chips;
  final int shown;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < chips.length; i++)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: i < shown ? 1 : 0.25,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: i < shown ? SlmColors.emerald500 : const Color(0xE60B1A33),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(chips[i], style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: i < shown ? SlmColors.navy950 : Colors.white)),
              ),
            ),
        ],
      );
}

/// The close-out papers on the van's tray, in the dealt order.
class _TrayPanel extends StatelessWidget {
  const _TrayPanel({required this.order, required this.keys, required this.signed, required this.complaint, required this.onSign, required this.onTap, required this.onMiss});
  final List<M8Paper> order;
  final Map<M8Paper, GlobalKey> keys;
  final bool signed;
  final bool complaint;
  final VoidCallback onSign;
  final ValueChanged<M8Paper> onTap;
  final VoidCallback onMiss;

  String _label(M8Paper p) => switch (p) {
        M8Paper.seizure => M8TheftLines.paperSeizure,
        M8Paper.officer => M8TheftLines.paperOfficer,
        M8Paper.notice => M8TheftLines.paperNotice,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMiss,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(color: const Color(0xE60B1A33), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x66FFFFFF))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping_rounded, size: 18, color: Colors.white70),
                const SizedBox(width: 6),
                Text(M8TheftLines.trayHead, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, p) in order.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: p == M8Paper.seizure
                        ? _HoldBox(
                            key: keys[p],
                            ms: 900,
                            semantic: _label(p),
                            onDone: onSign,
                            onShort: () => onTap(p),
                            child: _paper(p, done: signed, sign: true),
                          )
                        : GestureDetector(
                            key: keys[p],
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(p),
                            child: Semantics(label: _label(p), button: true, child: _paper(p, done: p == M8Paper.officer && complaint)),
                          ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paper(M8Paper p, {required bool done, bool sign = false}) => Container(
        height: 116,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFDDF2E1) : const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(_label(p), style: bangla(fontSize: 13, fontWeight: FontWeight.w800, height: 1.25, color: const Color(0xFF14202B)))),
            if (sign)
              Row(
                children: [
                  Text(M8TheftLines.paperSign, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF455A64))),
                  const SizedBox(width: 6),
                  Expanded(child: Divider(height: 1, color: done ? SlmColors.emerald500 : const Color(0xFF90A4AE), thickness: done ? 3 : 1)),
                ],
              ),
          ],
        ),
      );
}
