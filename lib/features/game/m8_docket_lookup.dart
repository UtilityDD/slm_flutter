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
import 'm8_docket_lookup_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm8_docket_lookup_world.dart' show M8Chip, M8DocGeo, M8DocKind, kM8DocLooks, kM8DocSkies;

// Lesson 8.6 "গ্রাহক অভিযোগ নিষ্পত্তি (Grievance Redressal)", কাজ "ডকেট
// নম্বরটা দিন" (pack do_8_6_b, rung 8.6/do/1, engineType m8_docket_lookup).
// The van cab at dusk in a para: the dash tablet lists the section's dockets
// (24–30 rows, longer than the screen: number · para · complaint · OPEN or
// CLOSED, in the order they were registered, no search, no sort by number),
// four fixed chips below it — কাজ শুরু · ছবি/ভিডিও · অফিসে রিপোর্ট ·
// 1912 / CCC-তে জানাতে বলুন — and a 'বাড়ি চলুন' key. Four consumers walk up
// one at a time (silent captions, M8-10), each showing a phone SMS or a
// customer-care slip with a number, or none.
//
// The core verb (M8-9, a replacement of the old viewfinder level): FLICK-SCROLL
// the list and TAP the row whose number matches, then press a chip.
//  no number          → '1912 / CCC' is right; কাজ শুরু on a verbal complaint,
//                       a photo or a report with no docket = slip;
//  number, dark house → the matching row + কাজ শুরু (a short crew visit, no
//                       steps, the lights come on) → অফিসে রিপোর্ট (a phone
//                       call) → the row flips to CLOSED with the time;
//  number, lit house  → (false complaint: lit windows, the fan turning, the
//                       service line intact) hold ছবি/ভিডিও once, a thumbnail
//                       is pinned to the row; কাজ শুরু there, or a report
//                       with no proof = slip;
//  wrong row, or a closed row, acted on = slip (ভুল ডকেট);
//  a number that is on no row (a misread) → 'এই নম্বরে ডকেট নেই' and a free
//                       re-ask with the right number.
// The match is never lit, the decoys share its first three digits and some
// sit in other paras; the four chips are the same for everyone; the house's
// truth shows only in the drawn world.
//
// A CGRF order (dealt: whether, and before which consumer) arrives with a
// chime as the LAST row, in the same style as the rest: before any chip is
// pressed for that consumer it must be dragged to the pin slot at the top
// of the list (the drag is the decision; no special hint). A chip pressed
// first = slip, nothing happens.
//
// 'বাড়ি চলুন' is always live: with a finished docket unreported it is a slip
// and the play ends with that row open; otherwise it only says there are
// consumers waiting.
//
// Every mistake is a slip (M8-1: nothing here can hurt a person; R7, R18,
// R21, X2/B1: listening takes the class of the act he pushes right then,
// and neither is deadly). Three slips strike the level out; 4 consumers a
// play, then the pass panel.
//
// The coworker (once, dealt to one of two moments; that chip waits for him,
// holdForCoworker): at অফিসে রিপোর্ট after a repair, or at ছবি/ভিডিও at a
// false house. If his photo moment never occurs he comes at the next report.
//
// Gesture hands (how, never what): the list waiting → a vertical swipe on
// the list, alternating, never on one row; a row selected → a sweep over all
// four chips and 'বাড়ি চলুন'. Off during the intro, the consumer's lines, the
// crew and the call, the praise window, cards, his first beat and results.

// ============================================================================
// Content
// ============================================================================

enum M8DocReason { match, call, report, photo, cgrf }

/// Which of his two moments.
enum M8CwKind { report, photo }

abstract final class M8DocketLines {
  static const title = 'ডকেট নম্বরটা দিন';
  // DRAFT wording — owner (M6-12 / M8-14): every line below until the owner
  // gives the natural wording.
  static const intro = 'সন্ধ্যায় পাড়ায় নালিশের ভিড় — ডকেট নম্বর মিলিয়ে কাজ, কাজ শেষে রিপোর্ট।';

  /// The lesson's own line (daily check), asked at the first consumer.
  static const askFirst = 'দাদা, আপনি কি ডকেট করেছেন? নম্বরটা দিন, আমি দেখে নিচ্ছি।';
  static const askNext = 'দাদা, ডকেট নম্বরটা বলুন।';

  // The guide's task (tap him: the next of the pool, from the start).
  static const askConsumer = 'এই গ্রাহকের কথা শুনে এবার কী করবেন?';
  static const tapRead = 'গ্রাহক কী দেখাচ্ছেন, ট্যাবলেটে কী আছে — মন দিয়ে দেখুন।';
  static const tapShow = 'তালিকাটা ওপর-নিচে সরান, তারপর নিচের বোতাম বেছে নিন।';
  static const tapHome = 'সব গ্রাহকের কাজ মিটলে তবেই বাড়ি যাবেন।';
  static const tasks = [askConsumer, tapRead, tapShow, tapHome];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The screen's own words (what a worker reads).
  static const chipStart = 'কাজ শুরু';
  static const chipPhoto = 'ছবি/ভিডিও';
  static const chipReport = 'অফিসে রিপোর্ট';
  static const chipCall = '1912 / CCC-তে জানাতে বলুন';
  static const holdWord = 'ধরে রাখুন';
  static const homeKey = 'বাড়ি চলুন';
  static const colHead = 'নম্বর · পাড়া · অভিযোগ';
  static const pinWord = 'পিন';
  static const orderNumber = 'CGRF';
  static const orderPara = 'অর্ডার';
  static const orderWords = 'অর্ডারের কপি';
  static const orderPinned = 'CGRF অর্ডার';
  static const sceneLabel = 'গাড়ির ভেতর';
  static const docketWord = 'ডকেট';
  static const slipWord = 'ফোনে আসা নম্বর';
  static String chipLabel(M8Chip c) => switch (c) {
        M8Chip.start => chipStart,
        M8Chip.photo => chipPhoto,
        M8Chip.report => chipReport,
        M8Chip.call => chipCall,
      };

  // Free replies.
  static const nudgeRow = 'আগে তালিকা থেকে ডকেটটা বেছে নিন।';
  static const noDocket = 'এই নম্বরে ডকেট নেই।';
  static const reAsk = 'ও, আবার দেখে বলছি…';
  static const homeWait = 'এখনও গ্রাহক বাকি আছেন।';

  // The consumers' silent words (captions; never read aloud, M8-10).
  static const verbal = ['মুখে তো বলেছি!', 'পাশের বাড়ির দাদা বলেছেন', 'ডকেট-টকেট জানি না, লাইট নেই!', 'ফোন করার সময় নেই, আপনি দেখুন'];
  static const sms = ['এই যে, SMS-এ নম্বর এসেছে', 'এই নম্বরটা এসেছে ফোনে'];
  static const ccc = ['CCC-র স্লিপে এই নম্বর আছে', 'কাস্টমার কেয়ার এই নম্বরটা দিয়েছে'];
  static const smsTag = 'SMS';
  static const cccTag = 'CCC';

  // The rows' words.
  static const paras = ['নতুনপাড়া', 'মণ্ডলপাড়া', 'বাজারপাড়া', 'স্কুলপাড়া', 'শিবতলা', 'কালীতলা', 'পশ্চিমপাড়া', 'দক্ষিণপাড়া', 'বাগানপাড়া', 'স্টেশন রোড', 'হাটতলা', 'মাঝেরপাড়া'];
  static const complaints = ['বিদ্যুৎ নেই', 'ফিউজ অফ', 'লো ভোল্টেজ', 'মিটারে আলো নেই', 'তার ঝুলছে', 'ঘন ঘন যাচ্ছে', 'সার্ভিস লাইন ছেঁড়া', 'পোল হেলে আছে', 'বিল নিয়ে অভিযোগ', 'মিটার বদল চাই'];

  // The reasons (the right ones state the lesson's rule; the wrong ones are
  // myths and field excuses).
  static String whyQ(M8DocReason r) => switch (r) {
        M8DocReason.match => 'কেন ডকেট নম্বর মিলিয়ে তবেই কাজ ধরলেন?',
        M8DocReason.call => 'কেন 1912 বা CCC-তে জানাতে বললেন?',
        M8DocReason.report => 'কেন অফিসে রিপোর্ট করলেন?',
        M8DocReason.photo => 'কেন ছবি বা ভিডিও তুললেন?',
        M8DocReason.cgrf => 'CGRF-এর অর্ডার কেন সবার আগে?',
      };
  static const whyRight = <M8DocReason, List<String>>{
    M8DocReason.match: ['ডকেট নম্বরই আইনি রেকর্ড, মুখের কথার দাম নেই', 'ডকেট না হলে আইনের চোখে সমস্যাই নেই'],
    M8DocReason.call: ['1912 বা CCC-তে জানালে তবেই ডকেট তৈরি হয়', 'টোল ফ্রি 1912-এ জানালে আইনি রেকর্ড হয়'],
    M8DocReason.report: ['কাজ শেষে রিপোর্ট না দিলে ডকেট ক্লোজ হয় না', 'ডকেট খোলা থাকলে SoP-এর জরিমানা বাড়ে'],
    M8DocReason.photo: ['মিথ্যে নালিশে ছবি-ভিডিওই শুনানির প্রমাণ', 'নালিশ মিথ্যে হলে ছবি তুলে প্রমাণ রাখি'],
    M8DocReason.cgrf: ['CGRF-এর অর্ডারে সর্বোচ্চ গুরুত্ব দিতে হয়', 'ফোরামের অর্ডারের কপি এলে আগে সেটাই'],
  };
  static const myths = [
    'আইনকানুন কাগজের, মাঠে কাজ চললেই হলো',
    'নালিশ হলেই চাকরি যায়, চুপ থাকাই ভালো',
    'ঝামেলা এড়াতে মুখেই সব মিটিয়ে নেওয়া ভালো',
    'ডকেট-ফকেট অফিসবাবুদের মাথাব্যথা, আমাদের নয়',
  ];
  static const _wrongBy = <M8DocReason, List<String>>{
    M8DocReason.match: ['গ্রাহক চেঁচালে নম্বর ছাড়াই কাজ ধরা যায়', 'পাশের বাড়ির কথাতেও নম্বর ধরে নেওয়া চলে'],
    M8DocReason.call: ['মুখে বললেও অফিস নিজেই ডকেট করে নেয়', 'গ্রাহককে ফেরানোর জন্যই 1912 বলা হয়'],
    M8DocReason.report: ['রিপোর্ট শুধু ফাইলের শোভা, কাজে লাগে না', 'কাজ হলে ডকেট নিজে থেকেই বন্ধ হয়ে যায়'],
    M8DocReason.photo: ['ছবি তুললে গ্রাহক আরও রেগে যায়, তাই তুলি', 'ছবি তোলা ছাড়া মিথ্যে নালিশ ধরা যায় না'],
    M8DocReason.cgrf: ['অর্ডার তো অফিসের ব্যাপার, মাঠে দেখার নয়', 'সামনের গ্রাহক আগে এসেছেন, তাই তাঁর কাজ আগে'],
  };

  /// The wrong reasons for a question (its own excuses + the myths).
  static List<String> whyWrong(M8DocReason r) => [..._wrongBy[r]!, ...myths];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in _wrongBy.values) ...l, ...myths];

  // The careless coworker (two moments; the photo one is lesson myth 1).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asks = ['ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  // DRAFT wording — owner.
  static const reportScript = CoworkerScript(
    line: 'অফিসে রিপোর্ট কাল দিলেই হবে, চলো বাড়ি।',
    exitLine: coworkerExit,
    right: [
      'না, রিপোর্ট না দিলে ডকেট খোলা থাকবে',
      'না, কাজ শেষে রিপোর্ট দিয়েই ডকেট ক্লোজ',
      'না, ডকেট খোলা থাকলে জরিমানা বাড়তে থাকে',
    ],
    wrong: [
      'ঠিক, কাল রিপোর্ট দিলেও চলবে, চলো',
      'আজ ক্লান্ত, রিপোর্ট কাল সকালেই দেব',
      'ডকেট নিজে থেকেই বন্ধ হয়ে যাবে, চলো',
      'রিপোর্টে কিছু আসে যায় না, বাড়ি চলো',
      'ঠিক বলেছ, রিপোর্ট পরে দিলেও চলে',
    ],
    asks: _asks,
  );
  static const photoScript = CoworkerScript(
    line: 'ছবি-টবি তুলে কী হবে? কোম্পানির নামে কেউ কিছু করতে পারবে না।',
    exitLine: coworkerExit,
    right: [
      'না, ছবিই শুনানিতে আমাদের প্রমাণ হবে',
      'না, মিথ্যে নালিশে ছবি-ভিডিও রাখতে হয়',
      'না, নিয়ম মানলে ছবি আমাদেরই বাঁচাবে',
    ],
    wrong: [
      'ঠিক বলেছ, ছবি লাগবে না, চটপট চলো',
      'মুখে বলে দিলেই হবে, ছবি-টবি কীসের',
      'ঠিক, নালিশ করে কেউ কিছু পারবে না',
      'ছবি তুলে গ্রাহককে চটিয়ে লাভ নেই',
      'হ্যাঁ, কোম্পানি বড়, কেউ কিছু করবে না',
    ],
    asks: _asks,
  );
  /// Both scripts (the voice dump test lists them).
  static const allCoworkers = [reportScript, photoScript];
  static CoworkerScript script(M8CwKind k) => k == M8CwKind.report ? reportScript : photoScript;
  static const callHeldReport = 'ঠিক! রিপোর্ট না দিলে ডকেট খোলাই থাকে।';
  static const callHeldPhoto = 'ঠিক! ছবি-ভিডিওই শুনানিতে প্রমাণ।';
  static String callHeld(M8CwKind k) => k == M8CwKind.report ? callHeldReport : callHeldPhoto;

  static const allSet = 'সব গ্রাহকের কাজ মিটল — ডকেট মিলিয়ে, রিপোর্ট দিয়ে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ডকেট নম্বর মিলিয়ে, কাজ শেষে রিপোর্ট।';

  // "আজ যা ধরলেন".
  static const caughtDocket = 'ডকেট নম্বর = রেকর্ড';
  static const caughtVerbal = 'মুখের নালিশে নয়, 1912 / CCC-তে';
  static const caughtClosed = 'রিপোর্টে ক্লোজ';
  static const caughtProof = 'মিথ্যে নালিশে ছবি';
  static const caughtCgrf = 'CGRF অর্ডার আগে';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (his exit, the old asks, the
  /// old why-taps, the quick-pass line).
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', quick, 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [reportScript.line, photoScript.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askFirst,
        askNext,
        ...tasks,
        nudgeRow,
        noDocket,
        homeWait,
        for (final r in M8DocReason.values) whyQ(r),
        callHeldReport,
        callHeldPhoto,
        allSet,
        fail,
        for (final m in M8DocketMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused];
}

abstract final class M8DocketMistakes {
  static const _dir = 'assets/game/art/m8_docket_lookup';

  // Lesson 8.6 points (0-based): 0 লিখিত অভিযোগের গুরুত্ব, 1 আপনার সুরক্ষা,
  // 2 CGRF. The pro tip (photo) and the myths are not numbered points.

  // DRAFT wording — owner (M6-12). R7: a verbal complaint acted on.
  static const startVerbal = DoMistake(
    key: '8.6/m8_docket_lookup/start-verbal',
    textBn: 'মুখে বলা নালিশে কাজ ধরলেন — ডকেট নম্বর না হওয়া পর্যন্ত আইনের চোখে সমস্যাই নেই। 1912 বা CCC-তে জানাতে বলুন।',
    art: '$_dir/call_1912.svg',
    lessonPoint: 0,
  );
  static const noNumberPhoto = DoMistake(
    key: '8.6/m8_docket_lookup/no-number-photo',
    textBn: 'ডকেটই নেই, ছবি কীসের? আগে 1912 বা CCC-তে জানিয়ে ডকেট করাতে বলুন।',
    art: '$_dir/call_1912.svg',
    lessonPoint: 0,
  );
  static const noNumberReport = DoMistake(
    key: '8.6/m8_docket_lookup/no-number-report',
    textBn: 'ডকেট ছাড়া অফিসে কীসের রিপোর্ট? আগে 1912 বা CCC-তে নালিশ নথিভুক্ত হোক।',
    art: '$_dir/call_1912.svg',
    lessonPoint: 0,
  );
  static const wrongRow = DoMistake(
    key: '8.6/m8_docket_lookup/wrong-row',
    textBn: 'ভুল ডকেট! নম্বরটা পুরো মিলিয়ে নিন — ডকেট নম্বরই আইনি রেকর্ড।',
    art: '$_dir/list_match.svg',
    lessonPoint: 0,
  );
  // R18: a needless act.
  static const needless1912 = DoMistake(
    key: '8.6/m8_docket_lookup/needless-1912',
    textBn: 'নম্বর আছে, ডকেটও খোলা — এখন 1912-তে জানাতে বলার কিছু নেই। ডকেট ধরে এগোন।',
    art: '$_dir/list_match.svg',
    lessonPoint: 0,
  );
  static const needlessPhoto = DoMistake(
    key: '8.6/m8_docket_lookup/needless-photo',
    textBn: 'এই ঘরে সত্যিই সমস্যা — ছবি নয়, আগে কাজ ধরুন। ছবি লাগে মিথ্যে নালিশে।',
    art: '$_dir/house_dark.svg',
    lessonPoint: 0,
  );
  // The false complaint (R7).
  static const falseStart = DoMistake(
    key: '8.6/m8_docket_lookup/false-start',
    textBn: 'ঘরে আলো জ্বলছে, ফ্যান ঘুরছে, লাইন ঠিক — মিথ্যে নালিশ। কাজ না ধরে ছবি বা ভিডিও তুলে রাখুন।',
    art: '$_dir/house_lit.svg',
  );
  static const noProof = DoMistake(
    key: '8.6/m8_docket_lookup/no-proof',
    textBn: 'প্রমাণ ছাড়া মিথ্যে নালিশ ছেড়ে এলে শুনানিতে বলার কিছু থাকে না — ছবি বা ভিডিও তুলে রাখুন।',
    art: '$_dir/house_lit.svg',
  );
  // R21: the docket left open, or reported before the repair.
  static const reportEarly = DoMistake(
    key: '8.6/m8_docket_lookup/report-early',
    textBn: 'কাজ শুরুর আগেই রিপোর্ট! কাজ শেষ করে অফিসে রিপোর্ট দিলে তবেই ডকেট ক্লোজ হয়।',
    art: '$_dir/phone_report.svg',
    lessonPoint: 1,
  );
  static const leftOpen = DoMistake(
    key: '8.6/m8_docket_lookup/left-open',
    textBn: 'কাজ শেষ করে অফিসে রিপোর্ট না দেওয়া পর্যন্ত ডকেট ক্লোজ হয় না — SoP-এর জরিমানা বাড়তেই থাকে।',
    art: '$_dir/phone_report.svg',
    lessonPoint: 1,
  );
  static const homeUnreported = DoMistake(
    key: '8.6/m8_docket_lookup/home-unreported',
    textBn: 'রিপোর্ট না দিয়ে বাড়ি ফিরলেন — ডকেট খোলা রইল, SoP-এর জরিমানা বাড়তে থাকবে।',
    art: '$_dir/phone_report.svg',
    lessonPoint: 1,
  );
  // The CGRF order (lesson 8.6 point 3).
  static const cgrfFirst = DoMistake(
    key: '8.6/m8_docket_lookup/cgrf-first',
    textBn: 'CGRF-এর অর্ডারের কপি এলে সেটাকে সর্বোচ্চ গুরুত্ব দিয়ে আগে ধরতে হয়।',
    art: '$_dir/cgrf_order.svg',
    lessonPoint: 2,
  );
  // Listening to him (X2/B1: slip; neither push is on a deadly list).
  static const pushListenReport = DoMistake(
    key: '8.6/m8_docket_lookup/push-listen-report',
    textBn: 'না। কাল রিপোর্ট দিলে ডকেট রাতভর খোলা থাকে, জরিমানা বাড়ে — কাজ শেষে রিপোর্ট করেই ডকেট ক্লোজ।',
    art: '$_dir/phone_report.svg',
    lessonPoint: 1,
  );
  static const pushListenPhoto = DoMistake(
    key: '8.6/m8_docket_lookup/push-listen-photo',
    textBn: 'না। মিথ্যে নালিশে ছবি বা ভিডিওই শুনানিতে প্রমাণ — আর কোম্পানির গাফিলতি থাকলে WBERC গ্রাহকের পক্ষেই রায় দেয়।',
    art: '$_dir/house_lit.svg',
  );

  static DoMistake pushListen(M8CwKind k) => k == M8CwKind.report ? pushListenReport : pushListenPhoto;

  static const List<DoMistake> all = [
    startVerbal,
    noNumberPhoto,
    noNumberReport,
    wrongRow,
    needless1912,
    needlessPhoto,
    falseStart,
    noProof,
    reportEarly,
    leftOpen,
    homeUnreported,
    cgrfFirst,
    pushListenReport,
    pushListenPhoto,
  ];
}

// ============================================================================
// Deal and rules
// ============================================================================

/// One docket row (the list is dealt in registration order).
@immutable
class M8DocRow {
  const M8DocRow({required this.number, required this.para, required this.complaint, required this.open, this.closedAt});
  final String number;
  final String para;
  final String complaint;
  final bool open;

  /// 'HH:MM' for a row that was closed before the play.
  final String? closedAt;
}

/// One consumer: his docket (a row index; -1 if none), what the phone shows,
/// the house, his looks and his words.
@immutable
class M8DocConsumer {
  const M8DocConsumer({
    required this.kind,
    required this.row,
    required this.shown,
    required this.lit,
    required this.look,
    required this.line,
    required this.sms,
    required this.mirror,
  });

  final M8DocKind kind;

  /// The consumer's docket row in the list; -1 when he has no number.
  final int row;

  /// The number his phone shows first (null: none). A misread number is on no row.
  final String? shown;

  /// The house is lit (fan turning, line intact): nothing to repair.
  final bool lit;
  final int look;
  final String line;

  /// The slip is a phone SMS (else a customer-care slip).
  final bool sms;
  final bool mirror;
}

@immutable
class M8DocDeal {
  const M8DocDeal({required this.rows, required this.consumers, required this.orderAfter, required this.cw, required this.light, required this.clock0});

  final List<M8DocRow> rows;
  final List<M8DocConsumer> consumers;

  /// The CGRF order arrives as the consumer with this index walks up (1–3),
  /// or never (null).
  final int? orderAfter;
  final M8CwKind cw;
  final int light;

  /// The game clock at the start, in minutes after midnight.
  final int clock0;
}

String m8DocClock(int minutes) => '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// 24–30 rows; per number consumer 2–3 decoys sharing the first 3 digits (at
/// least one of them OPEN, some in other paras); fillers; the targets never
/// among the first 6 rows nor the last 2 (so the list must be scrolled).
M8DocDeal m8DocketDeal(math.Random rng) {
  final n = 24 + rng.nextInt(7);
  final clock0 = 17 * 60 + 40 + rng.nextInt(60);
  final kinds = <M8DocKind>[M8DocKind.real, M8DocKind.falseHouse, M8DocKind.values[rng.nextInt(4)], M8DocKind.values[rng.nextInt(4)]]..shuffle(rng);
  final paras = [...M8DocketLines.paras]..shuffle(rng);
  final here = paras.first;
  final used = <String>{};
  final prefixes = <String>{};
  String fresh(String prefix) {
    for (;;) {
      final s = '$prefix${rng.nextInt(10)}${rng.nextInt(10)}';
      if (used.add(s)) return s;
    }
  }

  String freshAny() {
    for (;;) {
      final s = '${1 + rng.nextInt(9)}${rng.nextInt(10)}${rng.nextInt(10)}${rng.nextInt(10)}${rng.nextInt(10)}';
      // A filler never shares the first 3 digits of a consumer's number.
      if (!prefixes.contains(s.substring(0, 3)) && used.add(s)) return s;
    }
  }

  String closed() => m8DocClock(clock0 - 25 - rng.nextInt(150));
  String words() => M8DocketLines.complaints[rng.nextInt(M8DocketLines.complaints.length)];

  final targets = <M8DocRow>[];
  final fillers = <M8DocRow>[];
  final targetOf = <int, M8DocRow>{};
  final shown = <int, String?>{};
  for (var i = 0; i < kinds.length; i++) {
    final k = kinds[i];
    if (k == M8DocKind.noNumber) {
      shown[i] = null;
      continue;
    }
    var prefix = '${1 + rng.nextInt(9)}${rng.nextInt(10)}${rng.nextInt(10)}';
    while (!prefixes.add(prefix)) {
      prefix = '${1 + rng.nextInt(9)}${rng.nextInt(10)}${rng.nextInt(10)}';
    }
    final number = fresh(prefix);
    final row = M8DocRow(number: number, para: here, complaint: words(), open: true);
    targetOf[i] = row;
    targets.add(row);
    final decoys = 2 + rng.nextInt(2);
    for (var d = 0; d < decoys; d++) {
      final open = d == 0 || rng.nextBool();
      fillers.add(M8DocRow(
        number: fresh(prefix),
        para: d == 1 ? paras[1 + rng.nextInt(paras.length - 1)] : (rng.nextBool() ? here : paras[1 + rng.nextInt(paras.length - 1)]),
        complaint: words(),
        open: open,
        closedAt: open ? null : closed(),
      ));
    }
    if (k == M8DocKind.misread) {
      // The phone shows a number on no row: the last two digits changed.
      // (fresh() records it as used, so no row ever takes it)
      shown[i] = fresh(prefix);
    } else {
      shown[i] = number;
    }
  }
  while (targets.length + fillers.length < n) {
    final open = rng.nextInt(10) < 4;
    fillers.add(M8DocRow(number: freshAny(), para: paras[rng.nextInt(paras.length)], complaint: words(), open: open, closedAt: open ? null : closed()));
  }
  fillers.shuffle(rng);
  // Place the targets at distinct slots in [6, n-3], the rest in order.
  final slots = <int>{};
  while (slots.length < targets.length) {
    slots.add(6 + rng.nextInt(n - 8));
  }
  final rows = <M8DocRow>[];
  var f = 0;
  final tgtList = [...targets]..shuffle(rng);
  final slotList = slots.toList()..sort();
  var t = 0;
  for (var i = 0; i < n; i++) {
    if (t < slotList.length && slotList[t] == i) {
      rows.add(tgtList[t++]);
    } else {
      rows.add(fillers[f++]);
    }
  }
  final consumers = <M8DocConsumer>[];
  final looks = [for (var i = 0; i < kM8DocLooks.length; i++) i]..shuffle(rng);
  for (var i = 0; i < kinds.length; i++) {
    final k = kinds[i];
    final target = targetOf[i];
    final sms = rng.nextBool();
    final line = switch (k) {
      M8DocKind.noNumber => M8DocketLines.verbal[rng.nextInt(M8DocketLines.verbal.length)],
      _ => (sms ? M8DocketLines.sms : M8DocketLines.ccc)[rng.nextInt(2)],
    };
    consumers.add(M8DocConsumer(
      kind: k,
      row: target == null ? -1 : rows.indexOf(target),
      shown: shown[i],
      lit: switch (k) {
        M8DocKind.real => false,
        M8DocKind.falseHouse => true,
        _ => rng.nextBool(),
      },
      look: looks[i],
      line: line,
      sms: sms,
      mirror: rng.nextBool(),
    ));
  }
  return M8DocDeal(
    rows: rows,
    consumers: consumers,
    orderAfter: rng.nextInt(10) < 7 ? 1 + rng.nextInt(3) : null,
    cw: rng.nextBool() ? M8CwKind.report : M8CwKind.photo,
    light: rng.nextInt(kM8DocSkies.length),
    clock0: clock0,
  );
}

/// The CGRF order row (never a consumer's docket).
const M8DocRow kM8OrderRow = M8DocRow(number: M8DocketLines.orderNumber, para: M8DocketLines.orderPara, complaint: M8DocketLines.orderWords, open: true);

/// The selected row when it is the CGRF order.
const int kM8OrderSel = -2;

/// What a chip (or the home key) did.
enum M8DocResult { slipped, nudge, noDocket, started, proof, closed, called, none }

enum M8DocPhase { lookup, work }

/// The play state (pure logic).
class M8DocRun {
  M8DocRun(this.deal) : clock = deal.clock0;
  final M8DocDeal deal;

  int index = 0;
  int slips = 0;
  M8DocPhase phase = M8DocPhase.lookup;

  /// The selected row index (a base row, or [kM8OrderSel]); null = none.
  int? selected;
  bool orderOut = false;
  bool pinned = false;

  /// The misread number was re-asked (the right number is on the phone now).
  bool reasked = false;

  /// The play ended early ('বাড়ি চলুন' with a docket unreported).
  bool ended = false;
  int clock;

  /// The rows closed this play (row index → time) and rows with proof pinned.
  final Map<int, String> closedAt = {};
  final Set<int> proof = {};
  final Set<M8DocReason> asked = {};
  final List<String> caught = [];

  M8DocConsumer get consumer => deal.consumers[index.clamp(0, deal.consumers.length - 1)];
  bool get done => index >= deal.consumers.length;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && !ended && percent >= 55;

  /// The number the phone shows now (the right one after the re-ask).
  String? get shownNumber {
    final c = consumer;
    if (c.kind == M8DocKind.misread && reasked) return deal.rows[c.row].number;
    return c.shown;
  }

  /// This consumer's house is a false complaint (lit, a number given).
  bool get isFalse => !done && consumer.lit && consumer.kind != M8DocKind.noNumber;

  /// A false consumer (lit, with a number) stands at or after index [from].
  bool falseFrom(int from) {
    for (var i = from; i < deal.consumers.length; i++) {
      final c = deal.consumers[i];
      if (c.lit && c.kind != M8DocKind.noNumber) return true;
    }
    return false;
  }

  void _caught(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  (M8DocResult, DoMistake?) _slipped(DoMistake m) => (M8DocResult.slipped, _slip(m));

  /// The CGRF order arrives (as the last row).
  void orderArrive() => orderOut = true;

  /// The order was dragged to the pin slot.
  void pin() {
    orderOut = false;
    pinned = true;
    if (selected == kM8OrderSel) selected = null;
    _caught(M8DocketLines.caughtCgrf);
  }

  /// A row tapped: selects (taps it again to let go). A docket in work is locked.
  bool select(int row) {
    if (done || phase == M8DocPhase.work) return false;
    selected = selected == row ? null : row;
    return true;
  }

  /// A chip pressed.
  (M8DocResult, DoMistake?) act(M8Chip chip) {
    if (done || ended) return (M8DocResult.none, null);
    // A CGRF order still unpinned: nothing is served before it.
    if (orderOut) return _slipped(M8DocketMistakes.cgrfFirst);
    final c = consumer;
    if (c.kind == M8DocKind.noNumber) {
      switch (chip) {
        case M8Chip.call:
          _caught(M8DocketLines.caughtVerbal);
          return (M8DocResult.called, null);
        case M8Chip.start:
          return _slipped(M8DocketMistakes.startVerbal);
        case M8Chip.photo:
          return _slipped(M8DocketMistakes.noNumberPhoto);
        case M8Chip.report:
          return _slipped(M8DocketMistakes.noNumberReport);
      }
    }
    // A number on no row (a misread): 'no such docket', a free re-ask.
    if (c.kind == M8DocKind.misread && !reasked) {
      reasked = true;
      selected = null;
      return (M8DocResult.noDocket, null);
    }
    if (phase == M8DocPhase.work) {
      if (chip == M8Chip.report) {
        clock += 4;
        closedAt[c.row] = m8DocClock(clock);
        _caught(M8DocketLines.caughtClosed);
        return (M8DocResult.closed, null);
      }
      return _slipped(M8DocketMistakes.leftOpen);
    }
    if (chip == M8Chip.call) return _slipped(M8DocketMistakes.needless1912);
    if (selected == null) return (M8DocResult.nudge, null);
    if (selected != c.row) return _slipped(M8DocketMistakes.wrongRow);
    if (!c.lit) {
      switch (chip) {
        case M8Chip.start:
          clock += 12;
          phase = M8DocPhase.work;
          _caught(M8DocketLines.caughtDocket);
          return (M8DocResult.started, null);
        case M8Chip.photo:
          return _slipped(M8DocketMistakes.needlessPhoto);
        case M8Chip.report:
          return _slipped(M8DocketMistakes.reportEarly);
        case M8Chip.call:
          break;
      }
    } else {
      switch (chip) {
        case M8Chip.photo:
          clock += 2;
          proof.add(c.row);
          _caught(M8DocketLines.caughtDocket);
          _caught(M8DocketLines.caughtProof);
          return (M8DocResult.proof, null);
        case M8Chip.start:
          return _slipped(M8DocketMistakes.falseStart);
        case M8Chip.report:
          return _slipped(M8DocketMistakes.noProof);
        case M8Chip.call:
          break;
      }
    }
    return (M8DocResult.none, null);
  }

  /// 'বাড়ি চলুন': with a finished docket unreported it is a slip and the play
  /// ends with that row open; otherwise only a word.
  (M8DocResult, DoMistake?) home() {
    if (done || ended) return (M8DocResult.none, null);
    if (phase == M8DocPhase.work) {
      ended = true;
      return _slipped(M8DocketMistakes.homeUnreported);
    }
    return (M8DocResult.nudge, null);
  }

  /// Listened to the coworker (his moment's own card).
  DoMistake pushSlip(M8CwKind k) => _slip(M8DocketMistakes.pushListen(k));

  /// A reason is due the first time of each kind in a play.
  bool reasonDue(M8DocReason r) => asked.add(r);

  /// The next consumer.
  void next() {
    index++;
    selected = null;
    phase = M8DocPhase.lookup;
    reasked = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per consumer: walk-up and ask ~4600 + scroll to the row 4000 + select 1500
///     + a chip 1500 ≈ 11600 × 4                                   ≈ 46400
///   + the repair visit and report (~2 dark houses × 5000)          ≈ 10000
///   + a reason for each kind met (~3.5 × 8200)                     ≈ 28700
///   + the order drag (70 %) and the coworker once                  ≈ 18000
///                                                                  ≈ 103000
/// 85 % ≈ 88000 → 90 s (a builder's estimate; owner may tune after playtest).
const m8DocketQuickMs = 90000;

@immutable
class M8DocketPack {
  const M8DocketPack({required this.id, required this.titleBn, this.quickMs = m8DocketQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8DocketPack> m8DocketPacks = {
  'do_8_6_b': M8DocketPack(id: 'do_8_6_b', titleBn: M8DocketLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8DocketProbe {
  static M8DocRun? run;
  static ScrollController? scroll;
  static bool Function()? ready;
}

// ============================================================================
// Page
// ============================================================================

class M8DocketLookupPage extends StatefulWidget {
  const M8DocketLookupPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8DocketPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8DocketLookupPage> createState() => _M8DocketLookupPageState();
}

class _M8DocketLookupPageState extends State<M8DocketLookupPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DocketRunPage(
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

class _DocketRunPage extends ConsumerStatefulWidget {
  const _DocketRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8DocketPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DocketRunPage> createState() => _DocketRunPageState();
}

class _DocketRunPageState extends ConsumerState<_DocketRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8DocRun _run;
  final _clock = Stopwatch();
  final _scroll = ScrollController();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  int _seq = 0;
  DoMistake? _card;
  final List<DoMistake> _cardQueue = [];
  VoidCallback? _afterCards;
  VoidCallback? _afterReward;
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
  int _hintN = 0;

  /// The consumer on the lane, his words, the slip, the house, the cut-scenes.
  var _shown = false;
  var _ready = false;
  String? _caption;
  var _slipUp = false;
  var _fixed = false;
  var _crew = false;
  var _calling = false;
  String? _note;
  Timer? _noteTimer;
  Timer? _crewTimer;
  Timer? _callTimer;

  /// The chip being held (photo) and the order row being dragged.
  M8Chip? _holding;
  Timer? _holdTimer;
  int _holdTok = 0;
  var _dragging = false;
  M8CwKind _cwNow = M8CwKind.report;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  M8DocGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8DocRun(m8DocketDeal(widget.rng));
    _cwNow = _run.deal.cw;
    M8DocketProbe.run = _run;
    M8DocketProbe.scroll = _scroll;
    M8DocketProbe.ready = () => _ready && !_busy;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  bool get _busy => _crew || _calling;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _seq++;
    _noteTimer?.cancel();
    _crewTimer?.cancel();
    _callTimer?.cancel();
    _holdTimer?.cancel();
    _scroll.dispose();
    if (identical(M8DocketProbe.run, _run)) {
      M8DocketProbe.run = null;
      M8DocketProbe.scroll = null;
      M8DocketProbe.ready = null;
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

  bool get _canPlay =>
      !_intro && !_ended && _ready && !_busy && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.done && !struckOut;

  // --- the consumers -----------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    await _startConsumer(0);
  }

  Future<void> _startConsumer(int i) async {
    final tok = ++_seq;
    final c = _run.deal.consumers[i];
    setState(() {
      _ready = false;
      _shown = true;
      _caption = null;
      _slipUp = false;
      _fixed = false;
      _crew = false;
      _calling = false;
      _note = null;
      _wake++;
    });
    if (_run.deal.orderAfter == i) {
      // The order arrives with a chime, as the last row.
      _cue('sounds/brand_chime.ogg', volume: 0.7);
      HapticFeedback.mediumImpact();
      setState(_run.orderArrive);
    }
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 150 : 950));
    if (!mounted || tok != _seq || _ended) return;
    await _say(i == 0 ? M8DocketLines.askFirst : M8DocketLines.askNext);
    if (!mounted || tok != _seq || _ended) return;
    setState(() {
      _caption = c.line;
      _slipUp = c.kind != M8DocKind.noNumber;
    });
    await Future<void>.delayed(MascotSpeechLibrary.readHold(c.line));
    if (!mounted || tok != _seq || _ended) return;
    setState(() {
      _ready = true;
      _wake++;
    });
    if (i == 0) unawaited(_sayChain([M8DocketLines.askConsumer]));
    // His photo moment: he turns up at the false house (the chip waits for him).
    if (_cwNow == M8CwKind.photo && _run.isFalse && !coworkerDone && !coworkerDue) scheduleCoworker();
  }

  void _enterWork() {
    setState(() => _wake++);
    // His report moment (or the photo one that fell back to the next report).
    if (coworkerDone || coworkerDue) return;
    if (_run.deal.cw == M8CwKind.report) {
      _cwNow = M8CwKind.report;
      scheduleCoworker();
    } else if (!_run.falseFrom(_run.index + 1)) {
      _cwNow = M8CwKind.report;
      scheduleCoworker();
    }
  }

  Future<void> _goNext() async {
    if (_ended) return;
    final tok = ++_seq;
    setState(() {
      _ready = false;
      _caption = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || tok != _seq || _ended) return;
    setState(() {
      _shown = false;
      _slipUp = false;
      _run.next();
      _wake++;
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _ended) return;
    unawaited(_startConsumer(_run.index));
  }

  // --- hands on -----------------------------------------------------------------
  void _tapBackground() {
    if (!_canPlay) return;
    _hints.missTap();
  }

  void _selectRow(int row) {
    if (!_canPlay) return;
    if (!_run.select(row)) return;
    _tick('sounds/intro/click.ogg', 0.4);
    setState(() => _wake++);
  }

  bool _hisChip(M8Chip chip) {
    if (coworkerDone || !coworkerDue) return false;
    return switch (_cwNow) {
      M8CwKind.report => chip == M8Chip.report && _run.phase == M8DocPhase.work,
      M8CwKind.photo => chip == M8Chip.photo && _run.isFalse && _run.phase == M8DocPhase.lookup,
    };
  }

  void _chipTap(M8Chip chip) {
    if (!_canPlay) return;
    // The photo needs a hold; a tap on it is a missed touch.
    if (chip == M8Chip.photo) {
      _hints.missTap();
      return;
    }
    _commit(chip);
  }

  void _holdStart(M8Chip chip) {
    if (!_canPlay) return;
    _holdTimer?.cancel();
    final tok = ++_holdTok;
    setState(() => _holding = chip);
    _holdTimer = Timer(Duration(milliseconds: _quiet ? 250 : 650), () {
      if (!mounted || tok != _holdTok) return;
      setState(() => _holding = null);
      _commit(chip);
    });
  }

  void _holdEnd() {
    if (_holding == null) return;
    _holdTimer?.cancel();
    _holdTok++;
    setState(() => _holding = null);
    _hints.missTap();
  }

  void _commit(M8Chip chip) {
    if (!_canPlay) return;
    if (_hisChip(chip) && holdForCoworker()) return;
    final origin = _centreOf(chip);
    final (res, m) = _run.act(chip);
    switch (res) {
      case M8DocResult.none:
        break;
      case M8DocResult.slipped:
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M8DocResult.nudge:
        _hints.missTap();
        unawaited(_sayChain([M8DocketLines.nudgeRow]));
      case M8DocResult.noDocket:
        _noDocket();
      case M8DocResult.started:
        _crewVisit(origin);
      case M8DocResult.proof:
        _cue('sounds/intro/glass.ogg', volume: 0.6);
        HapticFeedback.mediumImpact();
        _steps++;
        setState(() => _wake++);
        _reward(M8DocReason.photo, origin, _goNext);
      case M8DocResult.closed:
        _phoneCall(origin);
      case M8DocResult.called:
        _cue('sounds/learn/tick.ogg', volume: 0.6);
        _steps++;
        setState(() {
          _caption = null;
          _wake++;
        });
        _reward(M8DocReason.call, origin, _goNext);
    }
  }

  Offset _centreOf(M8Chip chip) {
    final g = _geoNow;
    final size = MediaQuery.sizeOf(context);
    if (g == null) return Offset(size.width / 2, size.height * 0.7);
    final k = size.width / 360;
    return g.chip(chip).center * k;
  }

  void _showNote(String? note) {
    _noteTimer?.cancel();
    setState(() => _note = note);
    if (note != null) {
      _noteTimer = Timer(const Duration(milliseconds: 2800), () {
        if (mounted) setState(() => _note = null);
      });
    }
  }

  void _noDocket() {
    _showNote(M8DocketLines.noDocket);
    _hush();
    _ready = false;
    setState(() => _wake++);
    unawaited(() async {
      final tok = _seq;
      await _say(M8DocketLines.noDocket, mood: GuideMood.warn);
      if (!mounted || tok != _seq || _ended) return;
      setState(() => _caption = M8DocketLines.reAsk);
      await Future<void>.delayed(MascotSpeechLibrary.readHold(M8DocketLines.reAsk));
      if (!mounted || tok != _seq || _ended) return;
      // The right number now on the phone; the free re-ask.
      setState(() {
        _caption = _run.consumer.line;
        _ready = true;
        _wake++;
      });
    }());
  }

  /// The crew's short visit (no steps): the lights come on, then the report.
  void _crewVisit(Offset origin) {
    _cue('sounds/intro/drop.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    setState(() {
      _crew = true;
      _caption = null;
      _wake++;
    });
    final quiet = _quiet;
    _crewTimer?.cancel();
    _crewTimer = Timer(Duration(milliseconds: quiet ? 200 : 1100), () {
      if (!mounted) return;
      setState(() => _fixed = true);
      _crewTimer = Timer(Duration(milliseconds: quiet ? 100 : 700), () {
        if (!mounted) return;
        setState(() => _crew = false);
        _steps++;
        _reward(M8DocReason.match, origin, _enterWork);
      });
    });
  }

  /// The report by phone: the row flips to CLOSED with the time.
  void _phoneCall(Offset origin) {
    _cue('sounds/learn/tick.ogg', volume: 0.6);
    setState(() {
      _calling = true;
      _wake++;
    });
    _callTimer?.cancel();
    _callTimer = Timer(Duration(milliseconds: _quiet ? 150 : 1100), () {
      if (!mounted) return;
      _cue('sounds/intro/confirm.ogg', volume: 0.6);
      HapticFeedback.mediumImpact();
      _steps++;
      setState(() {
        _calling = false;
        _caption = null;
        _wake++;
      });
      _reward(M8DocReason.report, origin, _goNext);
    });
  }

  /// A right act: its ◆ on the table with the question the first time of each
  /// kind; later the same kind pays at once.
  void _reward(M8DocReason r, Offset origin, VoidCallback after) {
    if (_run.reasonDue(r)) {
      _hush();
      _afterReward = after;
      putOnTable(15);
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M8DocketLines.whyRight[r]!, M8DocketLines.whyWrong(r), widget.rng),
        question: M8DocketLines.whyQ(r),
        stillValid: () => _run.index == idx && !_ended,
      ));
    } else {
      unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_ended) after();
      });
    }
  }

  // --- the CGRF order ---------------------------------------------------------
  void _pinOrder() {
    if (!_canPlay || !_run.orderOut) return;
    setState(() => _dragging = false);
    _run.pin();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    HapticFeedback.mediumImpact();
    _steps++;
    _reward(M8DocReason.cgrf, Offset(MediaQuery.sizeOf(context).width / 2, 200), () {
      if (mounted) setState(() => _wake++);
    });
  }

  void _homeTap() {
    if (!_canPlay) return;
    final (res, m) = _run.home();
    switch (res) {
      case M8DocResult.slipped:
        _afterCards = () => unawaited(_finish());
        unawaited(_levelDelta(-10, Offset(MediaQuery.sizeOf(context).width / 2, 600), mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M8DocResult.nudge:
        _hints.missTap();
        unawaited(_sayChain([M8DocketLines.homeWait]));
      default:
        break;
    }
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
    final after = _afterReward;
    _afterReward = null;
    if (!mounted) return;
    if (after != null) {
      after();
    } else {
      setState(() => _wake++);
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8DocketLines.script(_cwNow);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.done || _run.ended) return null;
    final here = switch (_cwNow) {
      M8CwKind.report => _run.phase == M8DocPhase.work,
      M8CwKind.photo => _run.isFalse && _run.phase == M8DocPhase.lookup,
    };
    if (!here || _intro || !_ready || _busy || _card != null || tableBusy || _holding != null || _dragging) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.pushSlip(_cwNow);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    if (!_run.caught.contains(M8DocketLines.caughtCall)) _run.caught.add(M8DocketLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8DocketLines.callHeld(_cwNow), M8DocketLines.askConsumer], mood: GuideMood.glad));
  }

  /// Tap the guide: the next task line of the pool, from the start.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8DocketLines.tapWhy[_whyN++ % M8DocketLines.tapWhy.length]
            : M8DocketLines.tasks[++_taskN % M8DocketLines.tasks.length];
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8docket/${m.key}');
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
    unawaited(_sayChain([M8DocketLines.askConsumer]));
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
    _seq++;
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
    await _say(!_run.passed ? M8DocketLines.fail : (_quickBonus ? M8DocketLines.quick : M8DocketLines.allSet),
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
  /// The gesture hand: how to touch, never what. The list waiting → a swipe
  /// up or down on the list in turn (never on one row); a row selected → a
  /// sweep over all four chips and 'বাড়ি চলুন'.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (_run.selected != null) {
      return HintSpec.sweep([for (final c in M8Chip.values) geo.chip(c), geo.home], space: HintSpace.scene);
    }
    return HintSpec.swipe(geo.listCentre, toward: Offset(0, n.isEven ? -1 : 1), travel: 90, space: HintSpace.scene);
  }

  Widget _tablet(M8DocGeo geo) {
    final rows = _run.deal.rows;
    final total = rows.length + (_run.orderOut ? 1 : 0);
    return Positioned.fromRect(
      key: const ValueKey('tablet'),
      rect: geo.tablet,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF16233F), Color(0xFF0E182D)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A4E78), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: geo.colHead.left - geo.tablet.left,
              top: geo.colHead.top - geo.tablet.top,
              width: geo.colHead.width,
              height: geo.colHead.height,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(M8DocketLines.colHead, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF8EA3C9))),
              ),
            ),
            Positioned(
              left: geo.pinSlot.left - geo.tablet.left,
              top: geo.pinSlot.top - geo.tablet.top,
              width: geo.pinSlot.width,
              height: geo.pinSlot.height,
              child: _PinSlot(pinned: _run.pinned, onAccept: _pinOrder),
            ),
            Positioned(
              left: geo.list.left - geo.tablet.left,
              top: geo.list.top - geo.tablet.top,
              width: geo.list.width,
              height: geo.list.height,
              child: Semantics(
                label: M8DocketLines.docketWord,
                child: ClipRect(
                  child: ListView.builder(
                    key: const ValueKey('docket-list'),
                    controller: _scroll,
                    physics: const ClampingScrollPhysics(),
                    itemExtent: M8DocGeo.rowH,
                    itemCount: total,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) {
                      if (i >= rows.length) {
                        // The CGRF order: the last row, the same style, draggable.
                        final row = _OrderRow(selected: _run.selected == kM8OrderSel, onTap: () => _selectRow(kM8OrderSel));
                        return Draggable<int>(
                          key: const ValueKey('row-order'),
                          data: 1,
                          affinity: Axis.vertical,
                          maxSimultaneousDrags: _canPlay ? 1 : 0,
                          onDragStarted: () => setState(() => _dragging = true),
                          onDragEnd: (_) {
                            if (mounted) setState(() => _dragging = false);
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(width: geo.list.width, height: M8DocGeo.rowH, child: const _OrderRow(selected: true)),
                          ),
                          childWhenDragging: const Opacity(opacity: 0.3, child: _OrderRow(selected: false)),
                          child: row,
                        );
                      }
                      final r = rows[i];
                      final closedNow = _run.closedAt[i];
                      return _DocRow(
                        key: ValueKey('row-${r.number}'),
                        row: r,
                        closedAt: closedNow ?? r.closedAt,
                        open: closedNow == null && r.open,
                        selected: _run.selected == i,
                        proof: _run.proof.contains(i),
                        onTap: () => _selectRow(i),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_note != null)
              Positioned(
                key: const ValueKey('tablet-note'),
                left: 40,
                right: 40,
                top: geo.pinSlot.top - geo.tablet.top + 2,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: const Color(0xF2B3261E), borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Text(_note!, textAlign: TextAlign.center, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8DocGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final idx = math.min(_run.index, _run.deal.consumers.length - 1);
    final c = _run.deal.consumers[idx];
    final lit = c.lit || _fixed;
    final number = _run.shownNumber;
    return [
      Positioned.fill(
        key: const ValueKey('back'),
        child: RepaintBoundary(child: CustomPaint(painter: M8DocBackPainter(geo: geo, light: _run.deal.light))),
      ),
      // A tap on nothing is a missed touch for the hand.
      Positioned.fill(
        key: const ValueKey('miss'),
        child: Semantics(
          label: M8DocketLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (_) => _tapBackground()),
        ),
      ),
      if (_shown) ...[
        Positioned.fill(
          key: ValueKey('house-$idx'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: c.lit ? 1 : 0, end: lit ? 1 : 0),
              duration: Duration(milliseconds: quiet ? 1 : 700),
              builder: (_, v, _) => RepaintBoundary(child: CustomPaint(painter: M8DocHousePainter(geo: geo, litT: v, mirror: false))),
            ),
          ),
        ),
        Positioned.fill(
          key: ValueKey('consumer-$idx'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 900),
              curve: Curves.easeOut,
              builder: (_, v, child) => Transform.translate(offset: Offset(-(1 - v) * 220, 0), child: child),
              child: RepaintBoundary(child: CustomPaint(painter: M8DocConsumerPainter(look: kM8DocLooks[c.look], rect: geo.consumer, phone: c.kind != M8DocKind.noNumber))),
            ),
          ),
        ),
        if (_crew)
          Positioned.fill(
            key: ValueKey('crew-$idx'),
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: quiet ? 1 : 1800),
                builder: (_, v, _) => CustomPaint(painter: M8DocCrewPainter(geo: geo, t: v)),
              ),
            ),
          ),
        if (_slipUp && number != null)
          Positioned.fromRect(
            key: ValueKey('slip-$idx-$number'),
            rect: geo.slip,
            child: IgnorePointer(child: _SlipCard(number: number, sms: c.sms)),
          ),
        if (_calling)
          Positioned.fromRect(
            key: ValueKey('call-$idx'),
            rect: geo.slip.translate(0, -52),
            child: const IgnorePointer(child: _CallBadge()),
          ),
        if (_caption != null)
          Positioned.fromRect(
            key: ValueKey('caption-$idx-${_caption.hashCode}'),
            rect: geo.caption,
            child: IgnorePointer(child: _Caption(text: _caption!)),
          ),
      ],
      _tablet(geo),
      for (final chip in M8Chip.values)
        Positioned.fromRect(
          key: ValueKey('chip-${chip.name}'),
          rect: geo.chip(chip),
          child: _ChipBtn(
            label: M8DocketLines.chipLabel(chip),
            sub: chip == M8Chip.photo ? M8DocketLines.holdWord : null,
            holding: _holding == chip,
            quiet: quiet,
            onTap: chip == M8Chip.photo ? null : () => _chipTap(chip),
            onHoldStart: chip == M8Chip.photo ? () => _holdStart(chip) : null,
            onHoldEnd: chip == M8Chip.photo ? _holdEnd : null,
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('home-key'),
        rect: geo.home,
        child: _HomeKey(onTap: _homeTap),
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
    final handsOn = playing && _ready && !_busy && !deckUp && !coworkerOpen && _card == null && !_run.done;
    final sceneH = (360 * size.height / math.max(1.0, size.width)).clamp(560.0, 900.0);
    final geoH = _geoNow?.height ?? sceneH;
    final tabTop = M8DocGeo.forScene(geoH, 0).tabTop;
    // The guide stands bottom-right of the windscreen (screen px).
    final guideBottom = (geoH - tabTop) * size.width / 360 + 2;
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
              labels: [for (var i = 0; i < _run.deal.consumers.length; i++) enDigits('${i + 1}')],
              done: {for (var i = 0; i < math.min(_run.index, _run.deal.consumers.length); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _holding == null && !_dragging,
            hintKey: '${_run.index}/$_steps/${_run.slips}/${_run.selected != null}/${_run.orderOut}/${_run.reasked}',
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
                  line: M8DocketLines.intro,
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

/// One docket row: number · para · complaint · OPEN / CLOSED (and a pinned
/// proof thumbnail). Every row is drawn the same; only selection tints it.
class _DocRow extends StatelessWidget {
  const _DocRow({super.key, required this.row, required this.open, required this.selected, required this.proof, required this.onTap, this.closedAt});

  final M8DocRow row;
  final bool open;
  final String? closedAt;
  final bool selected;
  final bool proof;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${M8DocketLines.docketWord} ${row.number}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2A3E68) : const Color(0xFF1A2742),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: selected ? SlmColors.gold300 : const Color(0xFF2B3B5E), width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                SizedBox(
                  width: 52,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(row.number, maxLines: 1, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 66,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(row.para, maxLines: 1, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFFB7C6E4))),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(row.complaint, maxLines: 1, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFFDDE6F7))),
                  ),
                ),
                if (proof)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.photo_camera, size: 15, color: Color(0xFF9FD3FF)),
                  ),
                _StatusPill(open: open, closedAt: closedAt),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.open, this.closedAt});
  final bool open;
  final String? closedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: open ? const Color(0xFF1F6B3A) : const Color(0xFF3A4152),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(open ? 'OPEN' : 'CLOSED', maxLines: 1, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
          if (!open && closedAt != null) Text(closedAt!, maxLines: 1, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFFC9D2E6), height: 1.1)),
        ],
      ),
    );
  }
}

/// The CGRF order copy: the last row, in the same style as the rest.
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.selected, this.onTap});
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _DocRow(
      row: kM8OrderRow,
      open: true,
      selected: selected,
      proof: false,
      onTap: onTap ?? () {},
    );
  }
}

/// The pin slot at the top of the list: a plain strip; the order dropped on
/// it is pinned for good.
class _PinSlot extends StatelessWidget {
  const _PinSlot({required this.pinned, required this.onAccept});
  final bool pinned;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (_) => onAccept(),
      builder: (context, candidates, _) {
        final over = candidates.isNotEmpty;
        return Semantics(
          label: M8DocketLines.pinWord,
          child: DecoratedBox(
            key: const ValueKey('pin-slot'),
            decoration: BoxDecoration(
              color: pinned ? const Color(0xFF2A3E68) : (over ? const Color(0xFF22345A) : const Color(0xFF111B31)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: pinned ? SlmColors.gold300 : const Color(0xFF3A4E78), width: pinned ? 1.6 : 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.push_pin, size: 14, color: pinned ? SlmColors.gold300 : const Color(0xFF6E83AD)),
                  const SizedBox(width: 6),
                  Text(pinned ? M8DocketLines.orderPinned : M8DocketLines.pinWord,
                      style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: pinned ? SlmColors.ivory : const Color(0xFF6E83AD))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The phone slip in the consumer's hand: an SMS or a customer-care slip with
/// its number.
class _SlipCard extends StatelessWidget {
  const _SlipCard({required this.number, required this.sms});
  final String number;
  final bool sms;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${M8DocketLines.slipWord} $number',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: sms ? const Color(0xFFEFF6FF) : const Color(0xFFFFF4DD),
          borderRadius: BorderRadius.circular(sms ? 12 : 4),
          border: Border.all(color: sms ? const Color(0xFF3F7CAC) : const Color(0xFF8A6A3C), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(sms ? M8DocketLines.smsTag : M8DocketLines.cccTag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: sms ? const Color(0xFF3F7CAC) : const Color(0xFF8A6A3C), height: 1.1)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(number, maxLines: 1, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF14213D), letterSpacing: 1.5, height: 1.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The consumer's silent words.
class _Caption extends StatelessWidget {
  const _Caption({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(text, maxLines: 2, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1B2540), height: 1.25)),
        ),
      ),
    );
  }
}

class _CallBadge extends StatelessWidget {
  const _CallBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFF1F6B3A), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.phone_in_talk, color: Colors.white, size: 24)),
      ),
    );
  }
}

/// An action chip: the same four for every consumer. The photo chip needs a
/// hold (a ring fills); a quick tap on it is only a missed touch.
class _ChipBtn extends StatelessWidget {
  const _ChipBtn({
    required this.label,
    required this.holding,
    required this.quiet,
    this.sub,
    this.onTap,
    this.onHoldStart,
    this.onHoldEnd,
  });

  final String label;
  final String? sub;
  final bool holding;
  final bool quiet;
  final VoidCallback? onTap;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2C4A7E), Color(0xFF1C3358)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: holding ? SlmColors.gold300 : const Color(0xFF5F7CB0), width: holding ? 2.4 : 1.4),
      ),
      child: Stack(
        children: [
          if (holding)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: quiet ? 250 : 650),
                builder: (_, v, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: DecoratedBox(decoration: BoxDecoration(color: SlmColors.gold300.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(9))),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1, textAlign: TextAlign.center, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                  ),
                  if (sub != null) Text(sub!, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF9FB4DA), height: 1.1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: label,
      child: onHoldStart != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => onHoldStart!(),
              onTapUp: (_) {
                onHoldEnd!();
              },
              onTapCancel: () => onHoldEnd!(),
              child: body,
            )
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: body),
    );
  }
}

/// 'বাড়ি চলুন': always live.
class _HomeKey extends StatelessWidget {
  const _HomeKey({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8DocketLines.homeKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF3A2A2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8A5A4A), width: 1.4),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, size: 18, color: Color(0xFFF0C9B8)),
                  const SizedBox(width: 6),
                  Text(M8DocketLines.homeKey, maxLines: 1, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFFF0C9B8))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
