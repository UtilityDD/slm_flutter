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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm7_comp_casebook_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_comp_casebook_world.dart' show M7Accident, M7Outcome, M7Stage;

// Lesson 7.2 "ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট: দুর্ঘটনার পর আপনার অধিকার",
// কাজ 1 "কোন খাতে ক্ষতিপূরণ?" (pack do_7_2_a, engineType m7_comp_casebook).
// The depot's welfare room: a wooden filing cabinet with four drawers
// labelled in the Act's words (মৃত্যু · স্থায়ী সম্পূর্ণ অক্ষমতা · স্থায়ী আংশিক
// অক্ষমতা · অস্থায়ী অক্ষমতা; positions shuffled every play), a steel বাতিল
// bin, a desk with four case files (photo clip, name, tag স্থায়ী / অস্থায়ী /
// চুক্তিভিত্তিক) and the room's tear-off day calendar.
//
//   • Tap a file (any order): its story picture lifts — the accident day at
//     work. Swipe down on the calendar to tear a page: the picture moves one
//     stage (কয়েক সপ্তাহ পরে: hospital → কয়েক মাস পরে: getting well at home →
//     অনেক পরে: how life turned out). No dates or numbers. A death case opens
//     on the family at the office desk with a garlanded photo; its calendar
//     has no pages. Pages come back when the file is closed (another file
//     opened, or the same file tapped again).
//   • Drag the open file onto a drawer (or the bin). Right drawer → the
//     drawer shuts, praise, ◆ on the table → "কেন এই খাতে রাখলেন?" → next.
//     Wrong drawer → a slip (the case's head, in the lesson's words); the
//     bin → a slip (the no-fault card); the file stays on the desk.
//   • One own-fault case a play, made in play order (never the first case
//     played, never a death case; the 2nd, 3rd or 4th case): its accident
//     picture and note show the worker's own lapse — plain hurry or
//     carelessness with all his PPE on, never skipping a safety device or
//     rule (the Act's exception, s.3(1) proviso (b), would bar a claim then).
//     The careless coworker comes on the first drag of that file
//     (holdForCoworker; the drop waits for him too) with the lesson's myth 1
//     in field words. Listening = a slip (the file drops in the bin and comes
//     back); its reason asks why the file was kept although the fault was his.
//   • After the last case, once a play: "ক্ষতিপূরণের পরিমাণ কীসে ঠিক হয়?"
//     (right: by law — age and monthly pay). Pass panel or fail panel.
//
// The lesson's rules, and only those (lesson 7.2, tool/all_training_chapters_bn.json):
//   • point 1 (index 1): the four heads and their definitions — death;
//     permanent total (can never do any kind of work again); permanent partial
//     (a part of the body such as a finger, hand or eye is lost, but the
//     worker can still do other work); temporary (unable to work for a while,
//     e.g. a few weeks or months). The amount is fixed by law and depends on
//     the worker's age and monthly pay.
//   • point 0 (index 0): the no-fault rule — the employer must pay whoever's
//     fault the accident was; the Act covers permanent, temporary and
//     contract workers (the file tags).
//   • myth 1: 'my own fault, so I get nothing' — wrong when the accident was
//     in the course of and because of the work.
// The story pictures and their notes are a game device (no durations, no
// medical claims beyond the lesson's own examples).
//
// Deadly: none (ruling M7-6: no deadly in lesson 7.2). Slips: a wrong drawer,
// the বাতিল bin, listening to the coworker (X2/B1: what he pushes — binning a
// case — is a slip). Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the full
// scene (m7_comp_casebook_world.dart + the page's cabinet, calendar and desk),
// corner guide (tap: the task again, another way), ◆ on the table → "কেন …?"
// (the deck opens at once), the coworker's two beats (never in a praise
// window). Gesture hands (how, never what): a sweep over every file on the
// desk; a swipe down on the calendar pad; a sweep over all four drawers and
// the bin alike, then (the next time) a short nudge of the open file straight
// up into empty air — never toward a drawer. Voice: guide lines on the device
// voice until recorded (newGuideLines); the coworker's push needs his clip
// (newRivalLines; silent with its caption held until then); his exit line is
// his existing clip.

// ============================================================================
// Content
// ============================================================================

/// The four heads of the Act (lesson 7.2 point 2).
enum M7Head { death, ptd, ppd, td }

/// The worker's employment tag on the file (lesson point 1: the Act covers all).
enum M7Tag { permanent, temporary, contract }

/// One story the deal can draw from.
@immutable
class M7Vignette {
  const M7Vignette(this.id, this.head, this.accident, this.outcome);
  final String id;
  final M7Head head;

  /// Null for a death case (its file opens on the family).
  final M7Accident? accident;
  final M7Outcome outcome;

  bool get isDeath => head == M7Head.death;
}

abstract final class M7CasebookLines {
  static const title = 'কোন খাতে ক্ষতিপূরণ?';
  // DRAFT wording — owner (M6-12 / M7-10). The intro is the spec's line.
  static const intro = "দলের ক'জন কাজের সময় আহত হয়েছেন। কে কোন খাতে ক্ষতিপূরণ পাবেন — ফাইল সাজান।";

  // The guide's task now (tap him: the same task, a different way).
  // DRAFT wording — owner.
  static const askOpen = 'একটা ফাইল খুলে ঘটনাটা দেখুন।';
  static const askTear = 'ক্যালেন্ডারের পাতা ছিঁড়ে দেখুন, পরে কী হলো।';
  static const askFile = 'এবার ফাইলটা ঠিক খাতের ড্রয়ারে রাখুন।';
  static const openFirst = 'আগে একটা ফাইল খুলুন।';
  static const noMorePages = 'আর পাতা নেই — এবার ফাইলটা রাখুন।';
  static const tasks = [askOpen, askTear, askFile];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (not spoken).
  static const roomLabel = 'ডিপোর কল্যাণ কক্ষ';
  static const bin = 'বাতিল';
  static const calendarLabel = 'দিনের ক্যালেন্ডার';
  static String progress(int i) => enDigits('ফাইল ${i + 1}');

  /// The drawer labels, in the Act's words (lesson point 2).
  static String head(M7Head h) => switch (h) {
        M7Head.death => 'মৃত্যু',
        M7Head.ptd => 'স্থায়ী সম্পূর্ণ অক্ষমতা',
        M7Head.ppd => 'স্থায়ী আংশিক অক্ষমতা',
        M7Head.td => 'অস্থায়ী অক্ষমতা',
      };

  static String tag(M7Tag t) => switch (t) {
        M7Tag.permanent => 'স্থায়ী',
        M7Tag.temporary => 'অস্থায়ী',
        M7Tag.contract => 'চুক্তিভিত্তিক',
      };

  /// The calendar's page faces (a game device: no dates, no numbers).
  static const pages = ['দুর্ঘটনার দিন', 'কয়েক সপ্তাহ পরে', 'কয়েক মাস পরে', 'অনেক পরে'];

  static const names = ['রফিক মণ্ডল', 'অমল ঘোষ', 'বিকাশ সরকার', 'তাপস মাইতি', 'শ্যামল বাগ', 'নির্মল হালদার', 'গৌতম পাল', 'দীপক সাঁতরা'];

  /// The eleven stories (TD ×4, PPD ×3 — finger, eye, hand, PTD ×2, death ×2).
  /// Every accident kind leads to more than one head, so the first pictures
  /// never tell the head.
  static const vignettes = [
    M7Vignette('td-pole', M7Head.td, M7Accident.poleFall, M7Outcome.backOnPole),
    M7Vignette('td-flash', M7Head.td, M7Accident.dtrFlash, M7Outcome.backOnLine),
    M7Vignette('td-comealong', M7Head.td, M7Accident.comeAlong, M7Outcome.backOnPole),
    M7Vignette('td-drum', M7Head.td, M7Accident.drumRoll, M7Outcome.backOnLine),
    M7Vignette('ppd-finger', M7Head.ppd, M7Accident.comeAlong, M7Outcome.fingerCounter),
    M7Vignette('ppd-eye', M7Head.ppd, M7Accident.dtrFlash, M7Outcome.eyeDesk),
    M7Vignette('ppd-hand', M7Head.ppd, M7Accident.drumRoll, M7Outcome.handCounter),
    M7Vignette('ptd-pole', M7Head.ptd, M7Accident.poleFall, M7Outcome.homeChair),
    M7Vignette('ptd-flash', M7Head.ptd, M7Accident.dtrFlash, M7Outcome.homeBed),
    M7Vignette('death-wife', M7Head.death, null, M7Outcome.familyWife),
    M7Vignette('death-parents', M7Head.death, null, M7Outcome.familyParents),
  ];

  // The file's note under each picture (read, not spoken). DRAFT wording —
  // owner. Never a head's name.
  //
  // The own-fault lapse is plain hurry or carelessness, with every PPE item
  // on and every safety device in use: never skipping গ্লাভস, the harness, a
  // chock or any other safety rule. Under Indian law (Employees' Compensation
  // Act 1923 s.3(1) proviso (b), carried into the Code on Social Security
  // 2020 s.74(1)) wilful disregard of a safety device or rule bars
  // compensation for any injury short of death or permanent total
  // disablement, and the head stays hidden until the last page — so the
  // lapse must be one where compensation is due under every head.
  static String accidentNote(M7Accident a, {required bool ownFault}) => switch ((a, ownFault)) {
        (M7Accident.poleFall, false) => 'পোলে কাজের সময় পড়ে গেছেন।',
        (M7Accident.poleFall, true) => 'তাড়াহুড়োয় নামতে গিয়ে নিজেই পা ফসকেছেন — পড়ে গেছেন।',
        (M7Accident.dtrFlash, false) => 'DTR-এ কাজের সময় ঝলকে পুড়েছেন।',
        (M7Accident.dtrFlash, true) => 'তাড়াহুড়োয় হাত থেকে স্প্যানার ফসকে গেছে — ঝলকে পুড়েছেন।',
        (M7Accident.comeAlong, false) => 'কাম-অ্যালং টানার সময় হাতে চোট।',
        (M7Accident.comeAlong, true) => 'তাড়াহুড়োয় হাত সরাননি — কাম-অ্যালং-এ চোট।',
        (M7Accident.drumRoll, false) => 'কেবিল ড্রাম নামানোর সময় চোট।',
        (M7Accident.drumRoll, true) => 'অন্যমনস্ক ছিলেন, দড়ি হাত থেকে ফসকে গেছে — চোট।',
      };
  static const hospitalNote = 'হাসপাতালে চিকিৎসা চলছে।';
  static const recoveringNote = 'বাড়িতে বিশ্রাম, ধীরে ধীরে সেরে উঠছেন।';
  static String outcomeNote(M7Outcome o) => switch (o) {
        M7Outcome.backOnPole => 'পুরো সেরে উঠে আবার পোলে কাজ করছেন।',
        M7Outcome.backOnLine => 'সেরে উঠে আবার লাইনের কাজে ফিরেছেন।',
        M7Outcome.fingerCounter => 'একটা আঙুল নেই — এখন স্টোরের কাউন্টারে কাজ করেন।',
        M7Outcome.eyeDesk => 'একটা চোখ নষ্ট — এখন ডিপোর টেবিলে কাজ করেন।',
        M7Outcome.handCounter => 'একটা হাত নেই — এখন স্টোরে হিসাবের কাজ করেন।',
        M7Outcome.homeChair => 'হাঁটতে পারেন না — আর কোনো কাজই করতে পারেন না।',
        M7Outcome.homeBed => 'বিছানা ছাড়তে পারেন না — কোনো কাজই আর সম্ভব নয়।',
        M7Outcome.familyWife => 'কাজের সময় দুর্ঘটনায় প্রাণ গেছে — স্ত্রী অফিসে এসেছেন।',
        M7Outcome.familyParents => 'কাজের সময় দুর্ঘটনায় প্রাণ গেছে — মা-বাবা অফিসে এসেছেন।',
      };

  // The reasons: the right ones fit the head just filed; the wrong ones are
  // the lesson's myths and field excuses. DRAFT wording — owner.
  static const whyFiled = 'কেন এই খাতে রাখলেন?';
  static const whyOwnFault = 'দোষ ওর নিজের হলেও কেন ফাইলটা রাখলেন?';
  static const whyAmount = 'ক্ষতিপূরণের পরিমাণ কীসে ঠিক হয়?';
  static const whyRight = <M7Head, List<String>>{
    M7Head.death: ['কাজের সময় দুর্ঘটনায় মৃত্যু — তাই মৃত্যুর খাতে', 'কাজের কারণে প্রাণ গেছে, তাই ক্ষতিপূরণ মৃত্যুর খাতে'],
    M7Head.ptd: ['আর কোনো কাজই করতে পারবেন না — তাই সম্পূর্ণ অক্ষমতা', 'ভবিষ্যতে কোনো কাজের ক্ষমতাই নেই — স্থায়ী সম্পূর্ণ'],
    M7Head.ppd: ['অঙ্গ নষ্ট, তবু অন্য কাজ করতে পারেন — তাই আংশিক অক্ষমতা', 'আঙুল, হাত বা চোখ গেছে, তবু অন্য কাজ করতে পারেন'],
    M7Head.td: ['কিছুদিন কাজ করতে পারেননি, পরে ফিরেছেন — তাই অস্থায়ী', 'কয়েক সপ্তাহ বা মাস অক্ষম, তারপর আবার কাজে ফিরেছেন'],
  };
  static const noFaultRight = ['দোষ যারই হোক, কাজের সময় কাজের কারণে — ক্ষতিপূরণ পাবেন', 'No-Fault নীতি: নিজের ভুলেও ক্ষতিপূরণের অধিকার থাকে'];
  static const myths = [
    'নিজের ভুলে দুর্ঘটনা হলে কোনো ক্ষতিপূরণই পাওয়া যায় না',
    'চুক্তিভিত্তিক কর্মী হলে এই আইনে কিছুই পাওয়া যায় না',
    'কোম্পানি যা দেবে, সেটাই মেনে নিতে হবে — কিছু করার নেই',
    'অফিসার যে খাতে বলবেন, সেই খাতেই ফাইল রাখতে হয়',
    'ক্ষতিপূরণ তো কোম্পানির দয়া — যত খুশি দিতে পারে',
    'যার চোট বেশি, তাকে যেকোনো খাতে রাখলেই চলে যায়',
    'হাসপাতাল থেকে ছুটি পেলেই সব কেস একই খাতে যায়',
  ];
  static const amountRight = ['আইন অনুযায়ী — কর্মীর বয়স আর মাসিক বেতনের ওপর', 'আইনে ঠিক করা — বয়স আর মাসিক বেতন দেখে গণনা'];
  static const amountWrong = [
    'কোম্পানি নিজের খুশিমতো যা ঠিক করে, শুধু সেটাই',
    'চোট কত বড়, অফিসার দেখে মুখে মুখে বলে দেন',
    'সবাই একই টাকা পান — বয়স বা বেতন দেখা হয় না',
    'ইউনিয়ন যত টাকা চাইবে, ঠিক তত টাকাই পাবেন',
    'যে আগে ফাইল জমা দেবে, সে-ই বেশি টাকা পাবে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l, ...noFaultRight];

  /// The careless coworker: lesson 7.2's myth 1 in field words (spec
  /// coworkerPushBn). DRAFT wording — owner (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLine = 'ওর নিজের ভুলেই তো হয়েছে! ও কিছুই পাবে না — ফাইলটা বাতিলে ফেলো।';
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: [
      'দোষ যারই হোক, কাজের কারণে হলে ক্ষতিপূরণ পাবেন',
      'No-Fault নীতি — ফাইলটা বাতিলে নয়, খাতেই যাবে',
      'না, নিজের ভুলেও ক্ষতিপূরণের অধিকার আছে, খাতে রাখি',
    ],
    wrong: [
      'ঠিক, নিজের দোষে কিছু পাওয়া যায় না — বাতিলে ফেলি',
      'ঠিক বলেছ, ফাইলটা বাতিলেই ফেলে দিই, ঝামেলা কম',
      'হ্যাঁ, নিজের ভুল হলে কোম্পানি কিছুই দেবে না',
      'আচ্ছা, ওর দোষ যখন, ফাইলটা আর খাতে রাখব না',
      'ঠিক আছে, নিজের ভুলের কেস বাতিলেই যাক এখন',
    ],
    asks: ['কী করবেন?', 'ও বলছে ফাইলটা বাতিলে ফেলতে। কী করবেন?', 'ওর কথা শুনবেন, না আইন?'],
  );

  static const callHeld = 'ঠিক! দোষ যারই হোক — কাজের সময়, কাজের কারণে হলে ক্ষতিপূরণ।';
  static const allSet = 'সব ফাইল ঠিক খাতে — ক্ষতিপূরণ দয়া নয়, অধিকার।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — শেষ পাতা পর্যন্ত দেখে তবে খাতে রাখুন।';

  // "আজ যা ধরলেন" (not spoken).
  static String caught(M7Head h) => switch (h) {
        M7Head.death => 'মৃত্যুর খাত চিনেছেন',
        M7Head.ptd => 'আর কোনো কাজ করতে পারবেন না — স্থায়ী সম্পূর্ণ',
        M7Head.ppd => 'অঙ্গ গেছে, অন্য কাজ করতে পারেন — স্থায়ী আংশিক',
        M7Head.td => 'কিছুদিন পরে কাজে ফিরেছেন — অস্থায়ী অক্ষমতা',
      };
  static const caughtNoFault = 'নিজের ভুলেও ক্ষতিপূরণ — No-Fault নীতি';
  static const caughtCall = '“বাতিলে ফেলো” — এই কথায় “না” বলেছেন';
  static const caughtAmount = 'পরিমাণ আইনে ঠিক — বয়স আর মাসিক বেতন';

  /// The coworker's new push (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworkerLine];

  /// Every spoken guide line (DRAFT — owner wording, then recorded; until
  /// then the device voice). The kit's own praise and 'wrong' bags are left
  /// out.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        openFirst,
        noMorePages,
        ...tapWhy,
        whyFiled,
        whyOwnFault,
        whyAmount,
        ...coworker.asks,
        callHeld,
        allSet,
        quick,
        fail,
        for (final m in M7CasebookMistakes.all) m.textBn,
      }.toList();

  /// Every fixed line on screen or spoken (tests: English digits, no পানি).
  static List<String> get allText => [
        ...newGuideLines,
        bin,
        roomLabel,
        calendarLabel,
        for (final h in M7Head.values) head(h),
        for (final t in M7Tag.values) tag(t),
        ...pages,
        ...names,
        for (final a in M7Accident.values) ...[accidentNote(a, ownFault: false), accidentNote(a, ownFault: true)],
        hospitalNote,
        recoveringNote,
        for (final o in M7Outcome.values) outcomeNote(o),
        ...allWhyRight,
        ...myths,
        ...amountRight,
        ...amountWrong,
        ...coworker.recordedLines,
        ...coworker.right,
        ...coworker.wrong,
        for (final h in M7Head.values) caught(h),
        caughtNoFault,
        caughtCall,
        caughtAmount,
      ];
}

abstract final class M7CasebookMistakes {
  static const _dir = 'assets/game/art/m7_comp_casebook';

  // DRAFT wording — owner (M6-12). Lesson point 2 (index 1) for the heads;
  // the no-fault rule is point 1 (index 0).
  static const headDeath = DoMistake(
    key: '7.2/m7_comp_casebook/head-death',
    textBn: 'কাজের সময় দুর্ঘটনায় কর্মীর মৃত্যু হলে — ক্ষতিপূরণ মৃত্যুর খাতে।',
    art: '$_dir/head_death.svg',
    lessonPoint: 1,
  );
  static const headPtd = DoMistake(
    key: '7.2/m7_comp_casebook/head-ptd',
    textBn: 'দুর্ঘটনার পর ভবিষ্যতে কোনো ধরনের কাজের ক্ষমতাই না থাকলে — স্থায়ী সম্পূর্ণ অক্ষমতা।',
    art: '$_dir/head_ptd.svg',
    lessonPoint: 1,
  );
  static const headPpd = DoMistake(
    key: '7.2/m7_comp_casebook/head-ppd',
    textBn: 'আঙুল, হাত বা চোখের মতো অঙ্গ নষ্ট, কিন্তু অন্য কাজ করতে পারেন — স্থায়ী আংশিক অক্ষমতা।',
    art: '$_dir/head_ppd.svg',
    lessonPoint: 1,
  );
  static const headTd = DoMistake(
    key: '7.2/m7_comp_casebook/head-td',
    textBn: 'কয়েক সপ্তাহ বা মাস কাজ করতে পারেননি, তারপর কাজে ফিরেছেন — অস্থায়ী অক্ষমতা।',
    art: '$_dir/head_td.svg',
    lessonPoint: 1,
  );
  static const binned = DoMistake(
    key: '7.2/m7_comp_casebook/binned',
    textBn: 'কাজের সময়, কাজের কারণে দুর্ঘটনা হলে দোষ যারই হোক, ক্ষতিপূরণ পাওয়া যায় (No-Fault নীতি)। কোনো কেসই বাতিল নয়।',
    art: '$_dir/no_fault.svg',
    lessonPoint: 0,
  );
  static const listened = DoMistake(
    key: '7.2/m7_comp_casebook/own-fault-myth',
    textBn: 'নিজের ভুলে দুর্ঘটনা হলেও, কাজের সময় কাজের কারণে হলে ক্ষতিপূরণ পাওয়া যায় — এটাই No-Fault নীতি।',
    art: '$_dir/no_fault.svg',
    lessonPoint: 0,
  );

  /// The card for a case of head [h] put in the wrong drawer: [h]'s own
  /// definition (what THIS case had).
  static DoMistake wrongHead(M7Head h) => switch (h) {
        M7Head.death => headDeath,
        M7Head.ptd => headPtd,
        M7Head.ppd => headPpd,
        M7Head.td => headTd,
      };

  static const all = [headDeath, headPtd, headPpd, headTd, binned, listened];
}

/// One dealt case file.
@immutable
class M7Case {
  const M7Case({required this.story, required this.name, required this.tag, required this.ownFault, required this.photo});

  final M7Vignette story;
  final String name;
  final M7Tag tag;

  /// The worker's own lapse caused it (the coworker's case).
  final bool ownFault;

  /// The photo clip's look.
  final int photo;

  /// The same file as the own-fault case.
  M7Case asOwnFault() => M7Case(story: story, name: name, tag: tag, ownFault: true, photo: photo);

  M7Head get head => story.head;
  bool get isDeath => story.isDeath;

  /// Pages the calendar can tear for this file.
  int get pages => isDeath ? 0 : 3;

  M7Stage stageAt(int torn) => isDeath ? M7Stage.later : M7Stage.values[torn.clamp(0, 3)];

  /// The file's note under the picture at [torn] pages.
  String noteAt(int torn) {
    final a = story.accident;
    if (a == null) return M7CasebookLines.outcomeNote(story.outcome);
    return switch (stageAt(torn)) {
      M7Stage.accident => M7CasebookLines.accidentNote(a, ownFault: ownFault),
      M7Stage.hospital => M7CasebookLines.hospitalNote,
      M7Stage.recovering => M7CasebookLines.recoveringNote,
      M7Stage.later => M7CasebookLines.outcomeNote(story.outcome),
    };
  }
}

@immutable
class M7CasebookDeal {
  const M7CasebookDeal({required this.cases, required this.drawers, required this.ownFaultAfter});

  /// The four files in desk order (left to right). None is the own-fault
  /// case yet: the run makes one so in play order ([M7CasebookRun.openFile]).
  final List<M7Case> cases;

  /// The drawers' heads in cabinet order (top-left, top-right, bottom-left,
  /// bottom-right).
  final List<M7Head> drawers;

  /// The own-fault case is the first non-death file opened once this many
  /// cases are filed (1–3: the 2nd, 3rd or 4th case played).
  final int ownFaultAfter;
}

/// Four files from the eleven stories: a death case in about half the plays
/// (at most one), the rest any mix (never forced one per head); desk order,
/// drawer order, names, tags and photos shuffled; the own-fault case due as
/// the 2nd, 3rd or 4th case played (never a death case; spec: never first).
M7CasebookDeal m7CasebookDeal(math.Random rng) {
  final deaths = [for (final v in M7CasebookLines.vignettes) if (v.isDeath) v];
  final others = [for (final v in M7CasebookLines.vignettes) if (!v.isDeath) v]..shuffle(rng);
  final picks = <M7Vignette>[if (rng.nextBool()) deaths[rng.nextInt(deaths.length)]];
  picks.addAll(others.take(4 - picks.length));
  picks.shuffle(rng);
  final names = [...M7CasebookLines.names]..shuffle(rng);
  final photos = [for (var i = 0; i < 12; i++) i]..shuffle(rng);
  return M7CasebookDeal(
    cases: [
      for (final (i, v) in picks.indexed)
        M7Case(story: v, name: names[i], tag: M7Tag.values[rng.nextInt(M7Tag.values.length)], ownFault: false, photo: photos[i]),
    ],
    drawers: [...M7Head.values]..shuffle(rng),
    ownFaultAfter: 1 + rng.nextInt(3),
  );
}

/// The 'why this drawer' deck of a case of head [h]: one of [h]'s own
/// definitions, another head's definition (so the pick tests the definition,
/// not the card's form) and one of the lesson's myths.
List<ChoiceOption> m7WhyFiledDeal(M7Head h, math.Random rng) {
  final mine = M7CasebookLines.whyRight[h]!;
  final others = [for (final o in M7Head.values) if (o != h) o];
  final other = M7CasebookLines.whyRight[others[rng.nextInt(others.length)]]!;
  return [
    ChoiceOption(mine[rng.nextInt(mine.length)], true),
    ChoiceOption(other[rng.nextInt(other.length)], false),
    ChoiceOption(M7CasebookLines.myths[rng.nextInt(M7CasebookLines.myths.length)], false),
  ]..shuffle(rng);
}

/// The play state (pure logic).
class M7CasebookRun {
  M7CasebookRun(this.deal);
  final M7CasebookDeal deal;

  /// The file whose story is up (desk slot), and the pages torn on it.
  int? open;
  int torn = 0;
  final Set<int> filed = {};

  /// Files opened at least once (their first picture has been seen).
  final Set<int> seen = {};
  int? _own;
  int slips = 0;
  final Map<int, int> _caseSlips = {};
  final List<String> caught = [];

  int get count => deal.cases.length;
  bool get done => filed.length >= count;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  M7Case caseAt(int i) => i == _own ? deal.cases[i].asOwnFault() : deal.cases[i];
  M7Case? get openCase => open == null ? null : caseAt(open!);

  /// The desk slot of the own-fault file: null until it is opened in play
  /// (never the first case played, never a death case).
  int? get ownFaultCase => _own;
  bool get ownFaultFiled => _own != null && filed.contains(_own);
  int caseSlips(int i) => _caseSlips[i] ?? 0;

  /// Every page of the open file is torn (or it has none).
  bool get atLastPage {
    final c = openCase;
    return c != null && torn >= c.pages;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Opens desk file [i] (its pages back to the accident day). False when
  /// it is filed or already open. This is where the own-fault case is made
  /// (see [_maybeOwnFault]).
  bool openFile(int i) {
    if (done || filed.contains(i) || open == i) return false;
    _maybeOwnFault(i);
    seen.add(i);
    open = i;
    torn = 0;
    return true;
  }

  /// Makes file [i] the own-fault case, in play order: only once a case is
  /// filed (so never the first case played), never a death case, and only a
  /// file whose plain first picture has not been seen yet — when filed
  /// reaches [M7CasebookDeal.ownFaultAfter], or earlier when no other unseen
  /// non-death file is left. The last non-death file always takes it if
  /// nothing has (a player who opened every file before filing any).
  void _maybeOwnFault(int i) {
    final c = deal.cases[i];
    if (_own != null || c.isDeath || filed.isEmpty) return;
    final freshOthers = [
      for (var j = 0; j < count; j++)
        if (j != i && !filed.contains(j) && !deal.cases[j].isDeath && !seen.contains(j)) j,
    ];
    final fresh = !seen.contains(i);
    final lastChance = freshOthers.isEmpty;
    if ((fresh || lastChance) && (filed.length >= deal.ownFaultAfter || lastChance)) _own = i;
  }

  /// Closes the open file (its pages come back).
  void closeFile() {
    open = null;
    torn = 0;
  }

  /// Tears a calendar page of the open file. False: no file, no page left.
  bool tear() {
    final c = openCase;
    if (c == null || torn >= c.pages) return false;
    torn++;
    return true;
  }

  /// File [i] can be dropped now (it is the open one, not filed).
  bool canFile(int i) => !done && open == i && !filed.contains(i);

  /// Drops file [i] in the drawer of [into] (null = the বাতিল bin). Null =
  /// right (the file is put away), or nothing happened because the file can
  /// not be filed now (check [canFile] first).
  DoMistake? file(int i, M7Head? into) {
    if (!canFile(i)) return null;
    final c = caseAt(i);
    if (into == c.head) {
      filed.add(i);
      closeFile();
      if (caseSlips(i) == 0) _tag(c.ownFault ? M7CasebookLines.caughtNoFault : M7CasebookLines.caught(c.head));
      return null;
    }
    slips++;
    _caseSlips[i] = caseSlips(i) + 1;
    return into == null ? M7CasebookMistakes.binned : M7CasebookMistakes.wrongHead(c.head);
  }

  /// Listened to "it was his own fault — bin it": a slip.
  DoMistake listened() {
    slips++;
    final own = _own;
    if (own != null) _caseSlips[own] = caseSlips(own) + 1;
    return M7CasebookMistakes.listened;
  }

  /// Refused him.
  void refused() => _tag(M7CasebookLines.caughtCall);

  /// The closing reason (the amount) was answered.
  void amountKnown() => _tag(M7CasebookLines.caughtAmount);
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   per case: open 1500 + three tears ≈ 3600 + drag ≈ 2000 + reason ~8200
///     ≈ 15300 × 4 ≈ 61200 (a death case has no tears: −3600 half the plays)
/// + the coworker once ≈ 9600 + the closing reason ≈ 8200 + lines ≈ 9000
///                                                               ≈ 86200
/// 85 % ≈ 73300 → 75 s.
const m7CasebookQuickMs = 75000;

@immutable
class M7CompCasebookPack {
  const M7CompCasebookPack({required this.id, required this.titleBn, this.quickMs = m7CasebookQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7CompCasebookPack> m7CompCasebookPacks = {
  'do_7_2_a': M7CompCasebookPack(id: 'do_7_2_a', titleBn: M7CasebookLines.title),
};

/// Test hook: the live run (tests only).
abstract final class M7CompCasebookProbe {
  static M7CasebookRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7CompCasebookPage extends StatefulWidget {
  const M7CompCasebookPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7CompCasebookPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7CompCasebookPage> createState() => _M7CompCasebookPageState();
}

class _M7CompCasebookPageState extends State<M7CompCasebookPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CasebookRunPage(
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

class _CasebookRunPage extends ConsumerStatefulWidget {
  const _CasebookRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7CompCasebookPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CasebookRunPage> createState() => _CasebookRunPageState();
}

/// Where the page's pieces stand on screen (logical px).
@immutable
class _Layout {
  const _Layout({required this.story, required this.cabinet, required this.desk});
  final Rect story;
  final Rect cabinet;
  final Rect desk;

  factory _Layout.of(Size size, EdgeInsets pad) {
    final w = size.width;
    final top = pad.top + 112;
    final bottom = pad.bottom + 8;
    final avail = size.height - top - bottom;
    // The gap between the cabinet and the desk holds the trainee (left) and
    // the corner guide with his bubble (right, ~116 + ~80), so the bubble
    // stays off the drawer labels on a 360 × 760 phone and taller.
    final desk = (avail * 0.19).clamp(100.0, 128.0);
    final story = (avail * 0.26).clamp(146.0, 230.0);
    final cab = (avail * 0.21).clamp(120.0, 170.0);
    return _Layout(
      story: Rect.fromLTWH(10, top, w - 20, story),
      cabinet: Rect.fromLTWH(10, top + story + 8, w - 20, cab),
      desk: Rect.fromLTWH(0, size.height - bottom - desk, w, desk + bottom),
    );
  }
}

class _CasebookRunPageState extends ConsumerState<_CasebookRunPage>
    with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7CasebookRun _run;
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

  /// The reason now on the table: a case's (its desk slot) or the closing one.
  int? _reasonFor;
  var _closingAsked = false;

  /// Little animations (each a one-shot keyed by its token).
  int _tearTok = 0;
  M7Head? _shut;
  int _shutTok = 0;
  int _binTok = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintFlip = 0;
  final _fileKeys = List.generate(4, (_) => GlobalKey());
  final _drawerKeys = {for (final h in M7Head.values) h: GlobalKey()};
  final _binKey = GlobalKey();
  final _calendarKey = GlobalKey();

  /// A vertical drag on the calendar in progress.
  double _calDrag = 0;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same).
    _run = M7CasebookRun(m7CasebookDeal(widget.rng));
    M7CompCasebookProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M7CompCasebookProbe.run, _run)) M7CompCasebookProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !struckOut && !_run.done;

  /// He is talking (beat 1: no deck yet).
  bool get _coworkerTalking => coworkerOpen && !coworkerChoiceUp;

  String get _task {
    final c = _run.openCase;
    if (c == null) return M7CasebookLines.askOpen;
    return _run.atLastPage ? M7CasebookLines.askFile : M7CasebookLines.askTear;
  }

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([M7CasebookLines.askOpen]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tapFile(int i) {
    if (!_canPlay || _run.filed.contains(i)) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.45);
    if (_run.open == i) {
      setState(() {
        _run.closeFile();
        _wake++;
      });
      unawaited(_sayChain([_task]));
      return;
    }
    setState(() {
      _run.openFile(i);
      _wake++;
    });
    // The own-fault file (made in play order on opening): he is due from now
    // and comes on its first drag.
    if (i == _run.ownFaultCase && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  /// A drag began on a file that does not move now: the held own-fault file
  /// (he comes now), or him talking (going on working refuses him).
  void _fileHeld(int i, Offset global) {
    if (_coworkerTalking) {
      if (i == _run.ownFaultCase && !_intro && !_ended && _card == null) {
        unawaited(answerCoworker(true, global, direct: true));
      }
      return;
    }
    if (!_canPlay) return;
    if (_run.open != i) {
      _tapFile(i);
      return;
    }
    if (i == _run.ownFaultCase) holdForCoworker();
  }

  void _tear() {
    if (!_canPlay) return;
    final c = _run.openCase;
    if (c == null) {
      _tick('sounds/intro/tick.ogg', 0.35);
      unawaited(_sayChain([M7CasebookLines.openFirst]));
      return;
    }
    if (!_run.tear()) {
      _tick('sounds/intro/impact_metal.ogg', 0.3);
      unawaited(_sayChain([M7CasebookLines.noMorePages]));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    setState(() {
      _tearTok++;
      _wake++;
    });
    if (_run.atLastPage) unawaited(_sayChain([M7CasebookLines.askFile]));
  }

  /// File [i] dropped on the drawer of [into] (null = the bin).
  void _file(int i, M7Head? into, Offset origin) {
    if (!_canPlay || !_run.canFile(i)) return;
    // His file: the drop waits for him too (a safety net: he comes on the
    // first drag).
    if (i == _run.ownFaultCase && holdForCoworker()) return;
    final c = _run.caseAt(i);
    final m = _run.file(i, into);
    setState(() => _wake++);
    if (m != null) {
      if (into == null) setState(() => _binTok++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      unawaited(_slip(m));
      return;
    }
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() {
      _shut = into;
      _shutTok++;
      _reasonFor = i;
    });
    putOnTable(_run.caseSlips(i) == 0 ? 20 : 15);
    unawaited(askReason(
      deal: () => c.ownFault
          ? dealChoices(M7CasebookLines.noFaultRight, M7CasebookLines.myths, widget.rng)
          : m7WhyFiledDeal(c.head, widget.rng),
      question: c.ownFault ? M7CasebookLines.whyOwnFault : M7CasebookLines.whyFiled,
      stillValid: () => !_ended && _reasonFor == i,
    ));
  }

  void _askClosing() {
    if (_ended || _closingAsked) return;
    _closingAsked = true;
    setState(() => _reasonFor = null);
    putOnTable(10);
    unawaited(askReason(
      deal: () => dealChoices(M7CasebookLines.amountRight, M7CasebookLines.amountWrong, widget.rng),
      question: M7CasebookLines.whyAmount,
      stillValid: () => !_ended,
    ));
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
    final closing = _closingAsked;
    final filed = _run.filed.length;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended) return;
      if (closing) {
        _run.amountKnown();
        unawaited(_finish());
        return;
      }
      if (_run.filed.length != filed) return;
      if (_run.done) {
        _askClosing();
        return;
      }
      setState(() {
        _reasonFor = null;
        _wake++;
      });
      unawaited(_sayChain([_task]));
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7CasebookLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;

  /// He comes only on the first drag of the own-fault file (the drag holds
  /// for him): "not yet" until then; once that file is filed (or the play
  /// ended) his moment has passed.
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ownFaultFiled || _run.done) return null;
    return false;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened: a slip; the file drops in the bin and comes back.
      final m = _run.listened();
      setState(() => _binTok++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.refused();
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    // Speak only while play is on (no stale task over a card or a deck).
    if (!mounted || _ended || reasonOpen || tableBusy || _card != null) return;
    unawaited(_sayChain([M7CasebookLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7CasebookLines.tapWhy[_nudgeN++ % M7CasebookLines.tapWhy.length]
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
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7casebook/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same file stays open on the desk.
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
    await _say(!_run.passed ? M7CasebookLines.fail : (_quickBonus ? M7CasebookLines.quick : M7CasebookLines.allSet),
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

  // --- the gesture hand ---------------------------------------------------------
  /// Desk waiting: a sweep over every file left. A file open with its
  /// calendar untouched: a swipe down on the pad. After a tear (or a file
  /// with no pages): a sweep over all four drawers and the bin alike, and the
  /// next time a short nudge of the file straight up into the air — never
  /// toward a drawer.
  HintSpec? _hint() {
    final c = _run.openCase;
    if (c == null) {
      return HintSpec.sweepOver([
        for (var i = 0; i < _run.count; i++)
          if (!_run.filed.contains(i)) _fileKeys[i],
      ]);
    }
    if (_run.torn == 0 && c.pages > 0) {
      final r = HintSpec.globalRectOf(_calendarKey);
      if (r == null) return null;
      return HintSpec.swipe(Offset(r.center.dx, r.top + r.height * 0.3), toward: const Offset(0, 1), travel: math.min(80, r.height * 0.5));
    }
    final flip = _hintFlip++;
    if (flip.isEven) {
      return HintSpec.sweepOver([for (final h in _run.deal.drawers) _drawerKeys[h]!, _binKey]);
    }
    return HintSpec.dragFrom(_fileKeys[_run.open!], toward: const Offset(0, -1), travel: 56);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) => [
        const Positioned.fill(
          key: ValueKey('world'),
          child: RepaintBoundary(child: CustomPaint(painter: M7RoomPainter())),
        ),
      ];

  Widget _story(Rect r, bool quiet) {
    final c = _run.openCase;
    final stage = c?.stageAt(_run.torn);
    final picture = c == null
        ? const SizedBox.expand(key: ValueKey('story-none'))
        : KeyedSubtree(
            key: ValueKey('story-${_run.open}-${stage!.name}'),
            child: Column(
              children: [
                Expanded(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: M7StoryPainter(accident: c.story.accident, stage: stage, outcome: c.story.outcome, ownFault: c.ownFault),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFFFBF0),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
                  child: Text(
                    c.noteAt(_run.torn),
                    key: const ValueKey('story-note'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.2, color: const Color(0xFF2B2111)),
                  ),
                ),
              ],
            ),
          );
    return Positioned.fromRect(
      key: const ValueKey('story-row'),
      rect: r,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              key: const ValueKey('story'),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF7A5A36),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ColoredBox(
                  color: const Color(0xFFEDE4CF),
                  child: AnimatedSwitcher(
                    duration: quiet ? Duration.zero : const Duration(milliseconds: 320),
                    child: picture,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 92, child: _calendar(quiet)),
        ],
      ),
    );
  }

  Widget _calendar(bool quiet) {
    final c = _run.openCase;
    final pages = c == null ? 3 : c.pages - _run.torn;
    final face = c == null ? null : (c.isDeath ? null : M7CasebookLines.pages[_run.torn.clamp(0, 3)]);
    final showPage = c == null || !c.isDeath;
    return Semantics(
      label: M7CasebookLines.calendarLabel,
      child: GestureDetector(
        key: const ValueKey('calendar'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _calDrag = 0,
        onVerticalDragUpdate: (d) => _calDrag += d.delta.dy,
        onVerticalDragEnd: (_) {
          final down = _calDrag;
          _calDrag = 0;
          if (down > 28) {
            _tear();
          } else {
            _hints.missTap();
          }
        },
        onTap: () {
          if (_canPlay) _hints.missTap();
        },
        child: KeyedSubtree(
          key: _calendarKey,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5E34),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Column(
              children: [
                // The binding rings.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 8, height: 12, decoration: BoxDecoration(color: const Color(0xFFCFD3D8), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // The pages still under the top one.
                      for (var k = math.min(pages, 3); k > 0; k--)
                        Positioned(
                          key: ValueKey('under-$k'),
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: -k * 2.5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color.lerp(const Color(0xFFF6F1E4), const Color(0xFFD8CFBA), k / 3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      if (showPage)
                        Positioned.fill(
                          key: const ValueKey('top-page'),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF6),
                              borderRadius: BorderRadius.circular(3),
                              border: Border(top: BorderSide(color: SlmColors.danger.withValues(alpha: 0.85), width: 7)),
                            ),
                            child: face == null
                                ? null
                                : Text(
                                    face,
                                    key: const ValueKey('calendar-face'),
                                    textAlign: TextAlign.center,
                                    style: bangla(fontSize: 14, fontWeight: FontWeight.w900, height: 1.2, color: const Color(0xFF2B2111)),
                                  ),
                          ),
                        ),
                      // The page just torn, falling away.
                      if (_tearTok > 0)
                        Positioned.fill(
                          key: ValueKey('fall-$_tearTok'),
                          child: IgnorePointer(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: quiet ? 1 : 0, end: 1),
                              duration: const Duration(milliseconds: 460),
                              curve: Curves.easeIn,
                              builder: (_, v, _) => v >= 1
                                  ? const SizedBox.shrink()
                                  : Opacity(
                                      opacity: 1 - v,
                                      child: Transform.translate(
                                        offset: Offset(10 * v, 70 * v),
                                        child: Transform.rotate(
                                          angle: 0.5 * v,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(color: const Color(0xFFFFFDF6), borderRadius: BorderRadius.circular(3)),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabinet(Rect r, bool quiet) {
    Widget drawer(M7Head h) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (d) => _canPlay && _run.canFile(d.data),
              onAcceptWithDetails: (d) => _file(d.data, h, d.offset + const Offset(40, 40)),
              builder: (context, cand, _) => KeyedSubtree(
                key: _drawerKeys[h],
                child: _Drawer(
                  key: ValueKey('drawer-${h.name}'),
                  label: M7CasebookLines.head(h),
                  hot: cand.isNotEmpty,
                  shutTok: _shut == h ? _shutTok : 0,
                  quiet: quiet,
                ),
              ),
            ),
          ),
        );
    final d = _run.deal.drawers;
    return Positioned.fromRect(
      key: const ValueKey('cabinet'),
      rect: r,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 74,
            child: Padding(
              padding: EdgeInsets.only(top: r.height * 0.28),
              child: DragTarget<int>(
                onWillAcceptWithDetails: (dd) => _canPlay && _run.canFile(dd.data),
                onAcceptWithDetails: (dd) => _file(dd.data, null, dd.offset + const Offset(40, 40)),
                builder: (context, cand, _) => KeyedSubtree(
                  key: _binKey,
                  child: _Bin(key: const ValueKey('bin'), hot: cand.isNotEmpty, tok: _binTok, quiet: quiet),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9A6A3A), Color(0xFF6E4622)]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [drawer(d[0]), drawer(d[1])])),
                  Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [drawer(d[2]), drawer(d[3])])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desk(Rect r, bool handsOn) {
    Widget slot(int i) {
      if (_run.filed.contains(i)) return const Expanded(child: SizedBox());
      final c = _run.caseAt(i);
      final open = _run.open == i;
      final held = open && i == _run.ownFaultCase && coworkerDue;
      final canDrag = handsOn && open && !held;
      final card = _FileCard(name: c.name, tag: M7CasebookLines.tag(c.tag), photo: c.photo, open: open);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _tapFile(i),
            // A file that does not move now: a closed one opens, the held
            // own-fault file calls him in, his talk is refused.
            onPanStart: canDrag ? null : (d) => _fileHeld(i, d.globalPosition),
            child: Draggable<int>(
              key: ValueKey('file-$i'),
              data: i,
              maxSimultaneousDrags: canDrag ? 1 : 0,
              onDragStarted: () => _tick('sounds/learn/card_deal_a.ogg', 0.4),
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(width: (r.width - 24) / 4, height: r.height - 26, child: Transform.rotate(angle: -0.05, child: card)),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: card),
              child: KeyedSubtree(key: _fileKeys[i], child: card),
            ),
          ),
        ),
      );
    }

    return Positioned.fromRect(
      key: const ValueKey('desk'),
      rect: r,
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 10, 8, 8 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9773F), Color(0xFF7C522A)]),
          border: Border(top: BorderSide(color: Color(0xFFC89A5E), width: 4)),
          boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < _run.count; i++) slot(i)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final lay = _Layout.of(size, pad);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.done && !deckUp && !coworkerOpen && _card == null;
    final gap = lay.desk.top - lay.cabinet.bottom;
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
              labels: [for (var i = 0; i < _run.count; i++) M7CasebookLines.progress(i)],
              done: {..._run.filed},
              current: _run.open,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.filed.length}/${_run.open}/${_run.torn > 0}',
            hintController: _hints,
            overlays: [
              // Taps on the bare room (never over the header's close / mute).
              Positioned(
                key: const ValueKey('room-touch'),
                left: 0,
                right: 0,
                bottom: 0,
                top: pad.top + FullSceneFrame.headerBand,
                child: Semantics(
                  label: M7CasebookLines.roomLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_canPlay) _hints.missTap();
                    },
                  ),
                ),
              ),
              _story(lay.story, quiet),
              _cabinet(lay.cabinet, quiet),
              if (gap >= 70)
                Positioned(
                  key: const ValueKey('trainee'),
                  left: 6,
                  bottom: size.height - lay.desk.top - 4,
                  width: 64,
                  height: math.min(gap, 124),
                  child: IgnorePointer(child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
                ),
              _desk(lay.desk, handsOn),
              ...tableLayers(at: Offset(size.width / 2, lay.story.center.dy), quiet: quiet),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-${_reasonFor ?? 'amount'}'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : size.height - lay.desk.top + 2, onLeft: coworkerFromRight),
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
                  line: M7CasebookLines.intro,
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
}

// ============================================================================
// Pieces
// ============================================================================

/// A case file on the desk: a manila folder, a photo clip, the name and the
/// employment tag. [open]: lifted, its story up.
class _FileCard extends StatelessWidget {
  const _FileCard({required this.name, required this.tag, required this.photo, required this.open});
  final String name;
  final String tag;
  final int photo;
  final bool open;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2B2111);
    return Semantics(
      label: name,
      container: true,
      child: Transform.translate(
        offset: Offset(0, open ? -8 : 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
          decoration: BoxDecoration(
            color: open ? const Color(0xFFF3D99A) : const Color(0xFFE8C987),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(10), bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
            border: Border.all(color: open ? SlmColors.gold300 : const Color(0xFFB08A4A), width: open ? 2.4 : 1.2),
            boxShadow: [BoxShadow(color: const Color(0x55000000), blurRadius: open ? 10 : 3, offset: Offset(0, open ? 5 : 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.82,
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2)]),
                      child: CustomPaint(painter: M7PortraitPainter(photo)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, height: 1.1, color: ink)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(6)),
                child: Text(tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, height: 1.1, color: const Color(0xFF6B4E1E))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A drawer of the cabinet (a drop target): a wooden face, a brass label
/// holder with the head's name, a handle. [hot] while a file is over it;
/// [shutTok] bumps when a file was put away in it (a short shut).
class _Drawer extends StatelessWidget {
  const _Drawer({super.key, required this.label, required this.hot, required this.shutTok, required this.quiet});
  final String label;
  final bool hot;
  final int shutTok;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final face = Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: hot ? const [Color(0xFFD9A867), Color(0xFFB27A3E)] : const [Color(0xFFB98549), Color(0xFF8E5F2E)],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: hot ? SlmColors.gold300 : const Color(0xFF5E3D1C), width: hot ? 2.2 : 1.2),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF4E3B5),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFC9A44E), width: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: bangla(fontSize: 12, fontWeight: FontWeight.w900, height: 1.12, color: const Color(0xFF2B2111))),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(width: 30, height: 6, decoration: BoxDecoration(color: const Color(0xFFD8B55A), borderRadius: BorderRadius.circular(3))),
        ],
      ),
    );
    return Semantics(
      label: label,
      container: true,
      child: shutTok == 0
          ? face
          : TweenAnimationBuilder<double>(
              key: ValueKey('shut-$shutTok'),
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 360),
              builder: (_, v, child) => Transform.scale(scale: 1 - 0.06 * math.sin(v * math.pi), child: child),
              child: face,
            ),
    );
  }
}

/// The steel বাতিল bin (a drop target). [tok] bumps when a file drops in.
class _Bin extends StatelessWidget {
  const _Bin({super.key, required this.hot, required this.tok, required this.quiet});
  final bool hot;
  final int tok;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Container(
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: hot ? const Color(0xFFB8C4CE) : const Color(0xFF8E9AA4), borderRadius: BorderRadius.circular(3)),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF9AA6B0), Color(0xFFD0D8DE), Color(0xFF8A96A0)]),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border.all(color: hot ? SlmColors.gold300 : const Color(0xFF5E6870), width: hot ? 2.2 : 1),
            ),
            child: Text(M7CasebookLines.bin, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2F33))),
          ),
        ),
      ],
    );
    return Semantics(
      label: M7CasebookLines.bin,
      container: true,
      child: tok == 0
          ? body
          : TweenAnimationBuilder<double>(
              key: ValueKey('bin-$tok'),
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 420),
              builder: (_, v, child) => Transform.rotate(angle: 0.08 * math.sin(v * math.pi * 3) * (1 - v), child: child),
              child: body,
            ),
    );
  }
}
