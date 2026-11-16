import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'm7_report_note_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_report_note_world.dart' show M7BodyGeo, M7Kind, M7Look, M7ReportGeo, M7Wit, M7Zone, m7BeatMid, m7ReplayEnd, m7ReplayMs;

// Lesson 7.7 "দুর্ঘটনার রিপোর্ট (Accident Reporting): আপনার দায়িত্ব", কাজ 2
// "সৎ রিপোর্ট" (pack do_7_7_b, rung 7.7/do/1, engineType m7_report_note).
//
//  1. The guide: 'মন দিয়ে দেখুন'. The accident plays ONCE (9 s, no touch, no
//     hand): T1 a shock on the pole (one hand), T2 a flash at the pillar
//     (one forearm), T3 a shock and a slip off the ladder (one ankle). The wall
//     clock of the tea stall is shown close up for a moment; the tea man and
//     the cyclist turn to watch, or do not. Then a jump of 10-25 minutes.
//  2. 'ঘটনা ঘটে গেছে — প্রথম কাজ?': hold the phone to call the supervisor. The
//     hold waits for the coworker (his myth 1, word for word): refuse him and
//     the call connects ('মুখে জানানো হলো — এবার লিখে পাঠান।'); listen to him
//     = a slip (the lesson's duty point), call again.
//  3. The report sheet slides up over the lower half, five lines in any order:
//       • তারিখ · সময় · স্থান — the clock dial starts at NOW: wind it back to
//         the accident time; tap a pole for the lens and drag its number in.
//       • নাম · বয়স · ঠিকানা — drag the injured man's ID card (the vest patch
//         in the scene shows his name); the coworker's card is the other.
//       • কীভাবে ঘটল — the coworker's pre-written draft (hiding / exaggerating
//         / honest, about 1 in 3): keep it or strike it; after a strike order
//         the three replay stills.
//       • কী আঘাত — the body outline and the kind picker; 'কোনো আঘাত নেই'
//         is always there (never right: the accident always hurt).
//       • প্রত্যক্ষদর্শী — tokens for who watched, and 'কেউ দেখেনি'.
//     A right line: praise → ◆ on the table → 'কেন …?' → এগিয়ে যান. A wrong
//     line: the MistakeCard, a strike, the line stays open.
//  4. All five filled → 'পাঠান' → 'মুখে আর লিখে — দুটোই জানানো হলো।' → pass.
//
// No deadly act here (M7-6): only slips; three strike out. The coworker comes
// once, at the call (B1: listening = a slip). Built on the shared kit: guide
// first, the full scene, corner guide, ◆ on the table → the cards at once, the
// two-beat coworker (the phone waits for him: holdForCoworker), gesture hands
// — a hold ring on the phone, sweeps over the headers / cards / zones / chips
// alike, a short drag nudge on the dial, the lens tag and a still, a tap on
// 'পাঠান' once enabled; never the answer. All new Bangla is DRAFT wording for
// the owner (M6-12).

// ============================================================================
// Content
// ============================================================================

/// Where the play is.
enum M7Stage { replay, call, sheet, sent }

/// The five report lines (any order).
enum M7Line { when, who, how, hurt, saw }

/// Keep or strike the coworker's draft.
enum M7Pick { none, keep, strike }

/// What his draft says.
enum M7Draft { hide, exaggerate, honest }

/// What a reason asks about.
enum M7Why { when, who, strike, keep, hurt, saw }

/// Minute of the day as the report reads it: 'সকাল 9:35'.
String m7TimeText(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final part = h < 12 ? 'সকাল' : (h < 16 ? 'দুপুর' : 'বিকেল');
  return '$part $h12:${m.toString().padLeft(2, '0')}';
}

abstract final class M7ReportNoteLines {
  // DRAFT wording — owner (M6-12): every new line in this class.
  static const title = 'সৎ রিপোর্ট';
  static const intro = 'মন দিয়ে দেখুন — একটু পরে খবর আর লিখিত রিপোর্ট আপনাকেই দিতে হবে।';

  // The guide's task now (tap him: the same task, a different way).
  static const askCall = 'ঘটনা ঘটে গেছে — প্রথম কাজ?';
  static const askSheet = 'রিপোর্টের পাঁচটা লাইনই ভরুন।';
  static const askSend = 'সবকটা লাইন ভরা — এবার পাঠান।';
  static const askWhen = 'কখন, কোথায় ঘটল?';
  static const askWho = 'আহত মানুষটি কে?';
  static const askHow = 'ওর লেখা খসড়াটা — রাখবেন, না কাটবেন?';
  static const askStills = 'ছবি তিনটে ঘটনার ক্রমে সাজান।';
  static const askHurt = 'কোথায় কী আঘাত লেগেছিল?';
  static const askSaw = 'কে কে ঘটনাটা দেখেছিল?';
  static const tasks = [askCall, askSheet, askSend, askWhen, askWho, askHow, askStills, askHurt, askSaw];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const fillAll = 'সবকটা ঘর ভরে তবেই লিখুন।';
  static const fillFirst = 'আগে সবকটা লাইন ভরুন।';
  static const callDone = 'মুখে জানানো হলো — এবার লিখে পাঠান।';
  static const sent = 'মুখে আর লিখে — দুটোই জানানো হলো।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — যা দেখলেন ঠিক তাই লিখবেন।';

  static String ask(M7Stage s, {M7Line? line, bool stills = false, bool allFilled = false}) => switch (s) {
        M7Stage.replay => intro,
        M7Stage.call => askCall,
        M7Stage.sent => sent,
        M7Stage.sheet => switch (line) {
            M7Line.when => askWhen,
            M7Line.who => askWho,
            M7Line.how => stills ? askStills : askHow,
            M7Line.hurt => askHurt,
            M7Line.saw => askSaw,
            null => allFilled ? askSend : askSheet,
          },
      };

  // On screen (labels a worker reads, the form's own words).
  static const sceneLabel = 'রাস্তা';
  static const phoneName = 'সুপারভাইজার';
  static const phoneTalking = 'কথা হচ্ছে…';
  static String jump(int minutes) => '$minutes মিনিট পর';
  static const sheetTitle = 'দুর্ঘটনার রিপোর্ট';
  static const headers = <M7Line, String>{
    M7Line.when: 'তারিখ · সময় · স্থান',
    M7Line.who: 'নাম · বয়স · ঠিকানা',
    M7Line.how: 'কীভাবে ঘটল',
    M7Line.hurt: 'কী আঘাত',
    M7Line.saw: 'প্রত্যক্ষদর্শী',
  };
  static const progress = ['সময়', 'আহত', 'ঘটনা', 'আঘাত', 'সাক্ষী'];
  static const write = 'লিখি';
  static const send = 'পাঠান';
  static const keep = 'রাখুন';
  static const strikeOut = 'কাটুন';
  static const draftTag = 'সহকর্মীর খসড়া';
  static const slotPole = 'পোল নং';
  static const slotWho = 'আহত';
  static const noHurt = 'কোনো আঘাত নেই';
  static const nobody = 'কেউ দেখেনি';

  static String kindChip(M7Kind k) => switch (k) {
        M7Kind.shock => 'শক লেগেছে',
        M7Kind.burn => 'পুড়ে গেছে',
        M7Kind.sprain => 'মচকে গেছে',
      };
  static String witChip(M7Wit w) => switch (w) {
        M7Wit.tea => 'চা-দোকানদার',
        M7Wit.cyclist => 'সাইকেল আরোহী',
      };

  // The dealt people (fiction): names, addresses, ages.
  static const names = ['অনিল মণ্ডল', 'সুজিত পাল', 'রবি দাস', 'তপন সরকার', 'বিশ্বনাথ রায়', 'কার্তিক বর্মন', 'নিমাই ঘোষ', 'গোপাল হালদার'];
  static const addresses = ['রথতলা, বর্ধমান', 'কালীপুর, হুগলি', 'শিবতলা, বাঁকুড়া', 'নতুনগ্রাম, নদিয়া', 'মাঝেরহাট, কলকাতা', 'বাজারপাড়া, মালদা'];
  static String ageText(int a) => 'বয়স $a';

  // The coworker's drafts (about 1 in 3 honest). 55-72 letters each.
  static const draftHide = [
    'সামান্য একটু ঝাঁকুনি লেগেছিল, কেউ আহত হয়নি, কিছুই হয়নি, ঠিক আছি।',
    'ছোট একটা ব্যাপার, কিছু হয়নি, সব ঠিকই আছে, রিপোর্টের কিছু নেই।',
    'কাজের সময় একটু অসুবিধা হয়েছিল, ওটা তেমন কিছু নয়, সামলে নিয়েছি।',
  ];
  static const draftBig = [
    'পোল ভেঙে পড়ে তিনজন মারাত্মক পুড়ে গেছে, একজন প্রায় মারাই গেছে।',
    'বিরাট বিস্ফোরণ হয়ে পুরো পাড়া কাঁপিয়ে সবাই গুরুতর আহত হয়ে পড়েছে।',
    'লাইনে ভয়ংকর আগুন লেগে আমরা সবাই মরতে মরতে কোনোমতে বেঁচে ফিরেছি।',
  ];
  static const draftHonest = [
    'পোলে হাতে শক লাগে, পিলারে ফ্ল্যাশে হাত পোড়ে, মই থেকে পড়ে পা মচকায়।',
    'প্রথমে পোল ছুঁতে শক, তারপর পিলারে ফ্ল্যাশ, শেষে মই থেকে পড়ে পায়ে চোট।',
    'পোলে শক খায়, পিলারের ফ্ল্যাশে বাহু পোড়ে, মই থেকে পড়ে গোড়ালি মচকায়।',
  ];
  static List<String> draftsOf(M7Draft d) => switch (d) {
        M7Draft.hide => draftHide,
        M7Draft.exaggerate => draftBig,
        M7Draft.honest => draftHonest,
      };
  static List<String> get allDrafts => [...draftHide, ...draftBig, ...draftHonest];

  static const rounds = progress;

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M7Why, String>{
    M7Why.when: 'সময় আর পোল নম্বর কেন এত খুঁটিয়ে?',
    M7Why.who: 'কেন আহতের নাম-বয়স-ঠিকানা?',
    M7Why.strike: 'ওর লেখাটা কেন কাটলেন?',
    M7Why.keep: 'ওর লেখাটা কেন রাখলেন?',
    M7Why.hurt: 'আঘাত কেন যেমন দেখেছেন তেমনই লিখলেন?',
    M7Why.saw: 'প্রত্যক্ষদর্শীর নাম কেন লাগে?',
  };
  static const whyRight = <M7Why, List<String>>{
    M7Why.when: ['সঠিক সময় আর পোল নম্বর থাকলে তদন্তকারী ঠিক জায়গা পান', 'কোন সময়ে কোন পোলে ঘটেছে, সেটাই তদন্তের প্রথম সূত্র'],
    M7Why.who: ['কার কী হয়েছে জানতে আহতের নাম, বয়স, ঠিকানা লাগে', 'নাম-বয়স-ঠিকানা না থাকলে রিপোর্ট অসম্পূর্ণ থেকে যায়'],
    M7Why.strike: ['লুকোনো বা বাড়ানো কথা তদন্তের ভিত্তিই নষ্ট করে দেয়', 'ভুল তথ্য গেলে তদন্ত ভুল পথে যায়, তাই ওটা কাটলাম'],
    M7Why.keep: ['সৎ আর নির্ভুল তথ্যই সঠিক তদন্তের ভিত্তি, তাই রাখলাম', 'লেখাটা যা ঘটেছে ঠিক তাই বলছে, তাই কাটার কিছু নেই'],
    M7Why.hurt: ['যেমন দেখেছি ঠিক তেমন লিখলে তদন্ত সঠিক পথে চলে', 'আঘাতের ঠিক বিবরণ ডাক্তার আর তদন্ত দুই কাজেই লাগে'],
    M7Why.saw: ['প্রত্যক্ষদর্শীর কথায় তদন্তকারী ঘটনাটা মিলিয়ে দেখতে পারেন', 'যে দেখেছে তার বিবরণে ঘটনার সত্যিটা মিলিয়ে নেওয়া যায়'],
  };
  static const myths = [
    'এত খুঁটিনাটি শুধু অফিসের নিয়ম, মাঠে কাজে লাগে না',
    'কম লিখলে সুপারভাইজারের চাকরির ঝামেলা অনেক কম হবে',
    'ছোট ব্যাপার, নিজেরা সামলে নিলেই তো সব মিটে যায়',
    'রিপোর্ট বড় হলে কোম্পানি উল্টে কর্মীকেই শাস্তি দেবে',
    'যা মনে এল তাই লিখলেই চলে, ঠিক সময় বা নম্বর লাগে না',
    'আহত হলে ডাক্তার দেখবে, রিপোর্টে এত লেখার কী আছে',
    'সাক্ষী বা নাম লিখলে শুধু ঝামেলা বাড়ে, কাজ হয় না',
    'বাইরে কিছু না দেখা গেলে আঘাত নেই লিখে দিলেই হয়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play, at the call): the 7.7 myth 1 word for
  // word. B1: listening = a slip.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerCall = CoworkerScript(
    line: 'দুর্ঘটনা রিপোর্ট করলে আমার বা আমার সুপারভাইজারের চাকরি চলে যেতে পারে, তাই চুপ করে থাকাই ভালো।',
    exitLine: coworkerExit,
    right: ['না, দুর্ঘটনা লুকোনোই বড় আইনি অপরাধ', 'না, কোম্পানি দুর্ঘটনা আটকাতে চায়', 'না, সাথে সাথে সুপারভাইজারকে জানাব'],
    wrong: [
      'ঠিক, চাকরি বাঁচাতে চুপ থাকাই ভালো',
      'হ্যাঁ, ছোট ব্যাপার, নিজেরাই সামলে নেব',
      'আচ্ছা, কাউকে জানিয়ে আর কী লাভ হবে',
      'ঠিক আছে, আজ আর ফোন না করাই ভালো',
      'হ্যাঁ, রিপোর্ট করলে শুধু ঝামেলাই বাড়ে',
    ],
    asks: ['কী করবেন?', 'ও বলছে চুপ থাকতে। কী করবেন?', 'ফোনটা করবেন?'],
  );
  static const callHeld = 'একদম ঠিক! দুর্ঘটনা লুকোনো নয়, জানানোই দায়িত্ব।';

  // "আজ যা ধরলেন".
  static const caughtCall = 'ওর কথায় “না” বলে ফোন করেছেন';
  static const caughtWhen = 'দুর্ঘটনার সময় আর পোল নম্বর';
  static const caughtWho = 'আহতের নাম, বয়স, ঠিকানা';
  static const caughtHow = 'লুকোনো বা বাড়ানো নয়, সৎ বিবরণ';
  static const caughtHurt = 'যেমন দেখেছেন তেমন আঘাত';
  static const caughtSaw = 'যারা দেখেছে তাদের নাম';
  static const caughtSent = 'মুখে আর লিখে, দুভাবেই জানানো';

  /// His line with no clip yet (the director records it with
  /// tool/rival_clip.py). It is the 7.7 myth 1 word for word.
  static const newRivalLines = [
    'দুর্ঘটনা রিপোর্ট করলে আমার বা আমার সুপারভাইজারের চাকরি চলে যেতে পারে, তাই চুপ করে থাকাই ভালো।',
  ];

  /// The guide's new lines (Subrata voice): tasks, nudges, why-questions, the
  /// coworker questions, the call, the end, and every mistake card's text
  /// (read once).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        ...tapWhy,
        fillAll,
        fillFirst,
        ...whyQ.values,
        ...coworkerCall.asks.where((a) => a != 'কী করবেন?'),
        callHeld,
        callDone,
        sent,
        quick,
        fail,
        for (final m in M7ReportNoteMistakes.all) m.textBn,
      ];
}

abstract final class M7ReportNoteMistakes {
  // DRAFT wording — owner (M6-12). All slips (M7-6: no deadly here).
  static const _dir = 'assets/game/art/m7_report_note';
  static const _duty = 1; // 'রিপোর্টিং-এর দায়িত্ব কার?'
  static const _what = 2; // 'কী কী জানাতে হয়?'

  /// Listened to myth 1 at the call.
  static const listen = DoMistake(
    key: '7.7/m7_report_note/listen-myth',
    textBn: 'দুর্ঘটনা লুকিয়ে রাখা বড় আইনি অপরাধ। সাথে সাথে সুপারভাইজারকে জানানোই আপনার দায়িত্ব — কোম্পানি দুর্ঘটনা আটকাতে চায়, শাস্তি দিতে নয়।',
    art: '$_dir/phone.svg',
    lessonPoint: _duty,
  );

  /// The time left at NOW.
  static const timeNow = DoMistake(
    key: '7.7/m7_report_note/time-now',
    textBn: 'দুর্ঘটনার সময়টাই লিখতে হয়, এখনকার সময় নয়। ঘড়ি পিছিয়ে দুর্ঘটনার সময়ে আনুন।',
    art: '$_dir/clock.svg',
    lessonPoint: _what,
  );

  /// The wrong time.
  static const timeWrong = DoMistake(
    key: '7.7/m7_report_note/time-wrong',
    textBn: 'সময়টা মেলেনি। দুর্ঘটনা যখন ঘটল, ঘড়িতে তখন যা দেখেছেন, ঠিক সেই সময় লিখুন।',
    art: '$_dir/clock.svg',
    lessonPoint: _what,
  );

  /// The wrong pole number.
  static const poleWrong = DoMistake(
    key: '7.7/m7_report_note/pole-wrong',
    textBn: 'পোলের নম্বর মেলেনি। যে পোলে দুর্ঘটনা ঘটেছে, লেন্সে তার নম্বর পড়ে ঠিক নম্বরটাই লিখুন।',
    art: '$_dir/plate.svg',
    lessonPoint: _what,
  );

  /// The coworker's card instead of the injured man's.
  static const cardWrong = DoMistake(
    key: '7.7/m7_report_note/card-wrong',
    textBn: 'এটা সহকর্মীর কার্ড। আহত মানুষটির নাম, বয়স, ঠিকানা লিখতে হয় — যার আঘাত লেগেছে তার কার্ড দিন।',
    art: '$_dir/cards.svg',
    lessonPoint: _what,
  );

  /// Kept a hiding draft (pro tip 2).
  static const keepHide = DoMistake(
    key: '7.7/m7_report_note/keep-hide',
    textBn: 'দুর্ঘটনার বিবরণে তথ্য লুকোবেন না। যা ঘটেছে ঠিক তাই লিখতে হয় — লুকোনো লেখা কেটে দিন।',
    art: '$_dir/draft.svg',
    lessonPoint: _what,
  );

  /// Kept an exaggerating draft (pro tip 2).
  static const keepBig = DoMistake(
    key: '7.7/m7_report_note/keep-big',
    textBn: 'বিবরণ বাড়িয়ে বলবেন না। যা ঘটেছে ঠিক ততটুকুই লিখুন — বাড়ানো কথা তদন্তকে ভুল পথে নেয়।',
    art: '$_dir/draft.svg',
    lessonPoint: _what,
  );

  /// Struck an honest draft.
  static const strikeHonest = DoMistake(
    key: '7.7/m7_report_note/strike-honest',
    textBn: 'ওর লেখাটা সৎ আর ঠিক ছিল — ওটা কাটার দরকার ছিল না। লুকোনো বা বাড়ানো লেখাই শুধু কাটতে হয়।',
    art: '$_dir/draft.svg',
    lessonPoint: _what,
  );

  /// The stills in the wrong order.
  static const stillOrder = DoMistake(
    key: '7.7/m7_report_note/still-order',
    textBn: 'কীভাবে ঘটল, তা ঘটনার ক্রমে লিখতে হয়। ছবি তিনটে যে ক্রমে ঘটেছিল, সেই ক্রমে সাজান।',
    art: '$_dir/stills.svg',
    lessonPoint: _what,
  );

  /// The injury marked wrong.
  static const injuryWrong = DoMistake(
    key: '7.7/m7_report_note/injury-wrong',
    textBn: 'আঘাত যেমন দেখেছেন ঠিক তেমন লিখুন — কোন অঙ্গে, কী ধরনের। শকের ক্ষতি বাইরে না দেখা গেলেও ভেতরে থাকতে পারে।',
    art: '$_dir/body.svg',
    lessonPoint: _what,
  );

  /// The witness list wrong.
  static const witnessWrong = DoMistake(
    key: '7.7/m7_report_note/witness-wrong',
    textBn: 'যারা ঘটনাটা দেখেছে, শুধু তাদেরই নাম লিখতে হয় — কম বা বেশি নয়। কেউ না দেখলে তবেই “কেউ দেখেনি”।',
    art: '$_dir/witness.svg',
    lessonPoint: _what,
  );

  static const List<DoMistake> all = [listen, timeNow, timeWrong, poleWrong, cardWrong, keepHide, keepBig, strikeHonest, stillOrder, injuryWrong, witnessWrong];

  /// The level's deadly keys (the catalog's deadlyRules): none (M7-6).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

@immutable
class M7Person {
  const M7Person({required this.name, required this.age, required this.addr});
  final String name;
  final int age;
  final String addr;
}

@immutable
class M7ReportDeal {
  const M7ReportDeal({
    required this.poleNos,
    required this.acc,
    required this.accMin,
    required this.offset,
    required this.handR,
    required this.foreR,
    required this.ankleR,
    required this.people,
    required this.hurt,
    required this.draft,
    required this.draftIdx,
    required this.tea,
    required this.cyclist,
    required this.stillOrder,
  });

  /// The three plates, left to right (one digit apart), and the accident pole.
  final List<int> poleNos;
  final int acc;

  /// The accident's minute of the day (5-minute slots, 08:00-16:00) and how
  /// long after it the clock reads now (10-25 minutes).
  final int accMin;
  final int offset;

  /// The hurt side of the hand (T1), the forearm (T2), the ankle (T3).
  final bool handR;
  final bool foreR;
  final bool ankleR;

  /// The two ID cards in dealt order, and which one is the injured man's.
  final List<M7Person> people;
  final int hurt;

  /// His draft: what it says and which wording.
  final M7Draft draft;
  final int draftIdx;

  /// Who turned to watch.
  final bool tea;
  final bool cyclist;

  /// The stills' tray order (a permutation of 0..2, never the right order).
  final List<int> stillOrder;

  int get nowMin => accMin + offset;
  int get accNo => poleNos[acc];
  M7Person get injured => people[hurt];
  String get draftText => M7ReportNoteLines.draftsOf(draft)[draftIdx];
  bool get honest => draft == M7Draft.honest;

  /// The injuries the report must show.
  Map<M7Zone, M7Kind> get injuries => {
        handR ? M7Zone.handR : M7Zone.handL: M7Kind.shock,
        foreR ? M7Zone.forearmR : M7Zone.forearmL: M7Kind.burn,
        ankleR ? M7Zone.ankleR : M7Zone.ankleL: M7Kind.sprain,
      };

  Set<M7Wit> get witnesses => {if (tea) M7Wit.tea, if (cyclist) M7Wit.cyclist};

  M7Look get look => M7Look(acc: acc, handR: handR, foreR: foreR, ankleR: ankleR, tea: tea, cyclist: cyclist, patch: injured.name, poleNos: poleNos);
}

M7ReportDeal m7ReportDeal(math.Random rng) {
  final base = 4100 + rng.nextInt(800);
  final nos = [base, base + 1, base + 2]..shuffle(rng);
  final names = [...M7ReportNoteLines.names]..shuffle(rng);
  final addrs = [...M7ReportNoteLines.addresses]..shuffle(rng);
  final people = [
    for (var i = 0; i < 2; i++) M7Person(name: names[i], age: 22 + rng.nextInt(33), addr: addrs[i]),
  ];
  final r = rng.nextInt(3);
  final draft = switch (r) {
    0 => M7Draft.hide,
    1 => M7Draft.exaggerate,
    _ => M7Draft.honest,
  };
  final w = rng.nextInt(3);
  final order = [0, 1, 2];
  do {
    order.shuffle(rng);
  } while (order[0] == 0 && order[1] == 1);
  return M7ReportDeal(
    poleNos: nos,
    acc: rng.nextInt(3),
    accMin: 480 + 5 * rng.nextInt(97),
    offset: 10 + 5 * rng.nextInt(4),
    handR: rng.nextBool(),
    foreR: rng.nextBool(),
    ankleR: rng.nextBool(),
    people: people,
    hurt: rng.nextInt(2),
    draft: draft,
    draftIdx: rng.nextInt(3),
    tea: w != 1,
    cyclist: w != 0,
    stillOrder: order,
  );
}

/// The play state (pure logic).
class M7ReportRun {
  M7ReportRun(this.deal) : timeMin = deal.nowMin;
  final M7ReportDeal deal;

  var stage = M7Stage.replay;
  int slips = 0;
  final Map<M7Line, int> lineSlips = {};
  final List<String> caught = [];

  /// The lines written (their reasons paid), the line open on the sheet, and
  /// the line just done right whose reason is still to come.
  final Set<M7Line> filled = {};
  M7Line? open;
  M7Line? pending;

  // Line A: the dial (starts at NOW) and the plate number dropped.
  int timeMin;
  int? tag;

  // Line B: the card dropped (its place in the dealt order).
  int? card;

  // Line C: keep or strike, then the stills (slot -> beat).
  M7Pick pick = M7Pick.none;
  var stillsStage = false;
  final List<int?> slots = [null, null, null];

  // Line D: the marks, the zone selected, 'কোনো আঘাত নেই'.
  final Map<M7Zone, M7Kind> marks = {};
  M7Zone? zone;
  var noHurt = false;

  // Line E.
  final Set<M7Wit> saw = {};
  var nobody = false;

  bool get sent => stage == M7Stage.sent;
  bool get ended => sent;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => sent && percent >= 55;
  bool get allFilled => filled.length == M7Line.values.length;
  int slipsOn(M7Line l) => lineSlips[l] ?? 0;
  bool get canAct => stage == M7Stage.sheet && pending == null;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m, [M7Line? line]) {
    slips++;
    if (line != null) lineSlips[line] = slipsOn(line) + 1;
    return m;
  }

  /// The replay and the time jump are over.
  void toCall() {
    if (stage == M7Stage.replay) stage = M7Stage.call;
  }

  /// Listened to myth 1 at the call.
  DoMistake? listenSlip() => stage == M7Stage.call ? _slip(M7ReportNoteMistakes.listen) : null;

  /// The call connected (he was refused, or he was not dealt).
  void connect({bool refused = false}) {
    if (stage != M7Stage.call) return;
    if (refused) _tag(M7ReportNoteLines.caughtCall);
    stage = M7Stage.sheet;
  }

  bool openLine(M7Line l) {
    if (!canAct || filled.contains(l)) return false;
    open = l;
    return true;
  }

  void closeLine() {
    if (canAct) open = null;
  }

  // --- A -----------------------------------------------------------------------
  bool setTime(int minutes) {
    if (!canAct || open != M7Line.when) return false;
    timeMin = minutes.clamp(480, 990);
    return true;
  }

  bool dropTag(int number) {
    if (!canAct || open != M7Line.when) return false;
    tag = number;
    return true;
  }

  void clearTag() {
    if (canAct && open == M7Line.when) tag = null;
  }

  // --- B -----------------------------------------------------------------------
  bool dropCard(int i) {
    if (!canAct || open != M7Line.who || i < 0 || i > 1) return false;
    card = i;
    return true;
  }

  void clearCard() {
    if (canAct && open == M7Line.who) card = null;
  }

  // --- C -----------------------------------------------------------------------
  bool setPick(M7Pick p) {
    if (!canAct || open != M7Line.how || stillsStage) return false;
    pick = p;
    return true;
  }

  /// Beat [beat] into [slot] (a beat already in another slot moves).
  bool placeStill(int slot, int beat) {
    if (!canAct || open != M7Line.how || !stillsStage || slot < 0 || slot > 2 || beat < 0 || beat > 2) return false;
    for (var i = 0; i < 3; i++) {
      if (slots[i] == beat) slots[i] = null;
    }
    slots[slot] = beat;
    return true;
  }

  void clearSlot(int slot) {
    if (canAct && open == M7Line.how && stillsStage) slots[slot] = null;
  }

  /// The beats still in the tray, in the dealt order.
  List<int> get tray => [for (final b in deal.stillOrder) if (!slots.contains(b)) b];

  // --- D -----------------------------------------------------------------------
  bool tapZone(M7Zone z) {
    if (!canAct || open != M7Line.hurt) return false;
    noHurt = false;
    if (zone == z && marks.containsKey(z)) {
      marks.remove(z);
      zone = null;
    } else {
      zone = z;
    }
    return true;
  }

  bool setKind(M7Kind k) {
    final z = zone;
    if (!canAct || open != M7Line.hurt || z == null) return false;
    noHurt = false;
    marks[z] = k;
    return true;
  }

  bool pressNoHurt() {
    if (!canAct || open != M7Line.hurt) return false;
    marks.clear();
    zone = null;
    noHurt = true;
    return true;
  }

  // --- E -----------------------------------------------------------------------
  bool toggleWit(M7Wit w) {
    if (!canAct || open != M7Line.saw) return false;
    nobody = false;
    if (!saw.remove(w)) saw.add(w);
    return true;
  }

  bool pressNobody() {
    if (!canAct || open != M7Line.saw) return false;
    saw.clear();
    nobody = true;
    return true;
  }

  // --- the commit ---------------------------------------------------------------
  /// Everything the line needs is in (an empty cell is no slip: the guide asks).
  bool canCommit(M7Line l) => switch (l) {
        M7Line.when => tag != null,
        M7Line.who => card != null,
        M7Line.how => stillsStage ? !slots.contains(null) : pick != M7Pick.none,
        M7Line.hurt => marks.isNotEmpty || noHurt,
        M7Line.saw => saw.isNotEmpty || nobody,
      };

  /// 'লিখি' on the open line. Null with [pending] set = right (its reason
  /// comes); null with [stillsStage] newly set = the draft struck right, the
  /// stills come; a mistake = a slip, the line stays open.
  DoMistake? commit(M7Line l) {
    if (!canAct || open != l || !canCommit(l)) return null;
    switch (l) {
      case M7Line.when:
        if (timeMin == deal.nowMin) return _slip(M7ReportNoteMistakes.timeNow, l);
        if (timeMin != deal.accMin) return _slip(M7ReportNoteMistakes.timeWrong, l);
        if (tag != deal.accNo) return _slip(M7ReportNoteMistakes.poleWrong, l);
        _tag(M7ReportNoteLines.caughtWhen);
      case M7Line.who:
        if (card != deal.hurt) return _slip(M7ReportNoteMistakes.cardWrong, l);
        _tag(M7ReportNoteLines.caughtWho);
      case M7Line.how:
        if (!stillsStage) {
          final p = pick;
          pick = M7Pick.none;
          if (p == M7Pick.keep) {
            if (!deal.honest) return _slip(deal.draft == M7Draft.hide ? M7ReportNoteMistakes.keepHide : M7ReportNoteMistakes.keepBig, l);
            _tag(M7ReportNoteLines.caughtHow);
          } else {
            if (deal.honest) return _slip(M7ReportNoteMistakes.strikeHonest, l);
            stillsStage = true;
            pick = M7Pick.strike;
            return null;
          }
        } else {
          if (!(slots[0] == 0 && slots[1] == 1 && slots[2] == 2)) {
            for (var i = 0; i < 3; i++) {
              slots[i] = null;
            }
            return _slip(M7ReportNoteMistakes.stillOrder, l);
          }
          _tag(M7ReportNoteLines.caughtHow);
        }
      case M7Line.hurt:
        if (noHurt || !mapEquals(marks, deal.injuries)) return _slip(M7ReportNoteMistakes.injuryWrong, l);
        _tag(M7ReportNoteLines.caughtHurt);
      case M7Line.saw:
        if (nobody || !setEquals(saw, deal.witnesses)) return _slip(M7ReportNoteMistakes.witnessWrong, l);
        _tag(M7ReportNoteLines.caughtSaw);
    }
    pending = l;
    return null;
  }

  /// What the line's reason asks about.
  M7Why whyFor(M7Line l) => switch (l) {
        M7Line.when => M7Why.when,
        M7Line.who => M7Why.who,
        M7Line.how => stillsStage ? M7Why.strike : M7Why.keep,
        M7Line.hurt => M7Why.hurt,
        M7Line.saw => M7Why.saw,
      };

  /// The reason is paid: the line is written.
  void next() {
    final p = pending;
    if (p != null) filled.add(p);
    pending = null;
    open = null;
  }

  /// 'পাঠান' with all five lines written.
  bool send() {
    if (stage != M7Stage.sheet || !allFilled || pending != null) return false;
    stage = M7Stage.sent;
    _tag(M7ReportNoteLines.caughtSent);
    return true;
  }

  /// The round dot of the open line.
  int? get openIndex => open?.index;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action: the replay 9000 + the jump 2400 + the guide's ask
/// ~3000 + the phone hold ~2500 + the coworker once ~9600 + the connect ~3000;
/// each of the five lines ≈ open 1500 + its work (dial/lens 8000, card 4500,
/// keep/strike ~4500 or + stills 7000, body 8000, witnesses 4500) + commit 1500
/// + the reason ~8200; send ~2500 → ≈ 113000. 85 % ≈ 96000 → 100 s. (A new
/// level's value: the owner may change it.)
const m7ReportNoteQuickMs = 100000;

@immutable
class M7ReportNotePack {
  const M7ReportNotePack({required this.id, required this.titleBn, this.quickMs = m7ReportNoteQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7ReportNotePack> m7ReportNotePacks = {
  'do_7_7_b': M7ReportNotePack(id: 'do_7_7_b', titleBn: M7ReportNoteLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M7ReportNotePage extends StatefulWidget {
  const M7ReportNotePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7ReportNotePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7ReportNotePage> createState() => _M7ReportNotePageState();
}

class _M7ReportNotePageState extends State<M7ReportNotePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ReportRunPage(
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

class _ReportRunPage extends ConsumerStatefulWidget {
  const _ReportRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7ReportNotePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ReportRunPage> createState() => _ReportRunPageState();
}

class _ReportRunPageState extends ConsumerState<_ReportRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7ReportRun _run;
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

  /// The replay: one controller 0..1 (in reduced motion, three stills).
  late final AnimationController _replay = AnimationController(vsync: this, duration: const Duration(milliseconds: m7ReplayMs));
  final List<Timer> _replayTimers = [];
  var _jump = false;

  /// The phone hold.
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  var _holding = false;
  var _connecting = false;
  final _phoneKey = GlobalKey();

  /// The lens on a pole's plate (line A).
  int? _lensAt;
  final _lensTagKey = GlobalKey();
  final _dialKey = GlobalKey();

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M7ReportGeo? _geoNow;
  final Map<M7Line, GlobalKey> _headerKeys = {for (final l in M7Line.values) l: GlobalKey()};
  final _sendKey = GlobalKey();
  final List<GlobalKey> _cardKeys = [GlobalKey(), GlobalKey()];
  final _keepKey = GlobalKey();
  final _strikeKey = GlobalKey();
  final List<GlobalKey> _stillKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final Map<M7Zone, GlobalKey> _zoneKeys = {for (final z in M7Zone.values) z: GlobalKey()};
  final Map<M7Kind, GlobalKey> _kindKeys = {for (final k in M7Kind.values) k: GlobalKey()};
  final _noHurtKey = GlobalKey();
  final Map<M7Wit, GlobalKey> _witKeys = {for (final w in M7Wit.values) w: GlobalKey()};
  final _nobodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _run = M7ReportRun(m7ReportDeal(widget.rng));
    _hold.addStatusListener((s) {
      if (s == AnimationStatus.completed) _phoneDone();
    });
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M7ReportDeal get _deal => _run.deal;

  @override
  void dispose() {
    disposeCoworker();
    for (final t in _replayTimers) {
      t.cancel();
    }
    _replay.dispose();
    _hold.dispose();
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro &&
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      _run.pending == null &&
      !_connecting &&
      !_jump &&
      _run.stage != M7Stage.replay;

  String get _task => M7ReportNoteLines.ask(_run.stage, line: _run.open, stills: _run.stillsStage, allFilled: _run.allFilled);

  // --- the replay -------------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    ref.read(guideDirectorProvider.notifier).softClearLine();
    if (_quiet) {
      // Reduced motion: three still frames, one per beat.
      for (final e in [(0, m7BeatMid[0]), (3000, m7BeatMid[1]), (6000, m7BeatMid[2]), (9000, m7ReplayEnd)]) {
        _replayTimers.add(Timer(Duration(milliseconds: e.$1), () {
          if (!mounted) return;
          _replay.value = e.$2;
          if (e.$2 >= m7ReplayEnd) _replayDone();
        }));
      }
      return;
    }
    unawaited(_replay.forward().whenComplete(() {
      if (mounted && _replay.value >= m7ReplayEnd) _replayDone();
    }));
  }

  Future<void> _replayDone() async {
    if (_run.stage != M7Stage.replay || !mounted) return;
    setState(() => _jump = true);
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 1200 : 2400));
    if (!mounted) return;
    setState(() {
      _jump = false;
      _run.toCall();
      _wake++;
    });
    scheduleCoworker();
    unawaited(_sayChain([_task]));
  }

  // --- the call ---------------------------------------------------------------------
  void _holdDown() {
    if (!_canPlay || _run.stage != M7Stage.call) return;
    _holding = true;
    _hold.forward(from: 0);
  }

  void _holdUp() {
    if (!_holding) return;
    _holding = false;
    if (_hold.status != AnimationStatus.completed) {
      final short = _hold.value < 0.25;
      unawaited(_hold.animateBack(0, duration: const Duration(milliseconds: 160)));
      if (short) _hints.missTap();
    }
  }

  void _phoneDone() {
    _holding = false;
    if (!mounted) return;
    if (!_canPlay || _run.stage != M7Stage.call) {
      _hold.value = 0;
      return;
    }
    if (holdForCoworker()) {
      _hold.value = 0;
      return;
    }
    _hold.value = 0;
    unawaited(_connect());
  }

  Future<void> _connect({bool refused = false}) async {
    if (_connecting || !mounted) return;
    setState(() => _connecting = true);
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    ref.read(guideDirectorProvider.notifier).softClearLine();
    _hush();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _ended) return;
    setState(() {
      _connecting = false;
      _run.connect(refused: refused);
      _steps++;
      _wake++;
    });
    unawaited(_sayChain([M7ReportNoteLines.callDone, _task], mood: GuideMood.glad));
  }

  // --- the sheet ----------------------------------------------------------------------
  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  void _openLine(M7Line l) {
    if (!_canPlay || _run.stage != M7Stage.sheet) return;
    _tick();
    setState(() {
      _run.openLine(l);
      _lensAt = null;
      _wake++;
    });
    _steps++;
    unawaited(_sayChain([_task]));
  }

  void _closeLine() {
    if (!_canPlay || _run.open == null) return;
    _tick();
    setState(() {
      _run.closeLine();
      _lensAt = null;
      _wake++;
    });
    _steps++;
    unawaited(_sayChain([_task]));
  }

  void _tapScene(Offset p, M7ReportGeo geo) {
    if (!_canPlay) return;
    if (_run.stage == M7Stage.sheet && _run.open == M7Line.when) {
      for (var i = 0; i < 3; i++) {
        if (geo.pole(i).contains(p)) {
          _tick('sounds/intro/click.ogg', 0.5);
          setState(() => _lensAt = i);
          ref.read(guideDirectorProvider.notifier).softClearLine();
          _stepDone();
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _setTime(int m) {
    if (!_canPlay) return;
    if (_run.setTime(m)) {
      _tick('sounds/intro/tick.ogg', 0.3);
      _stepDone();
    }
  }

  void _dropTag(int no) {
    if (!_canPlay) return;
    if (_run.dropTag(no)) {
      _tick('sounds/learn/tag_slap.ogg', 0.5);
      setState(() => _lensAt = null);
      _stepDone();
    }
  }

  void _act(bool Function() f, {String sound = 'sounds/learn/tag_slap.ogg'}) {
    if (!_canPlay) return;
    var ok = false;
    setState(() => ok = f());
    if (ok) {
      _tick(sound, 0.45);
      _stepDone();
    }
  }

  void _commit(Offset global) {
    final l = _run.open;
    if (!_canPlay || l == null) return;
    if (!_run.canCommit(l)) {
      // Not a slip: a cell is still empty.
      _tick();
      unawaited(_sayChain([M7ReportNoteLines.fillAll]));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    final wasStills = _run.stillsStage;
    final m = _run.commit(l);
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.pending == l) {
      unawaited(_lineDone(l));
      return;
    }
    // The draft struck right: now the stills.
    if (!wasStills && _run.stillsStage) {
      setState(() => _wake++);
      _steps++;
      unawaited(_sayChain([M7ReportNoteLines.askStills], mood: GuideMood.glad));
    }
  }

  Future<void> _lineDone(M7Line l) async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    final why = _run.whyFor(l);
    putOnTable(15 + (_run.slipsOn(l) == 0 ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(M7ReportNoteLines.whyRight[why]!, M7ReportNoteLines.myths, widget.rng),
      question: M7ReportNoteLines.whyQ[why]!,
      stillValid: () => _run.pending == l && !_ended,
    ));
  }

  void _next() {
    setState(() {
      _run.next();
      _lensAt = null;
      _wake++;
    });
    _steps++;
    unawaited(_sayChain([_task]));
  }

  Future<void> _send(Offset global) async {
    if (!_canPlay || _run.stage != M7Stage.sheet || _run.open != null) return;
    if (!_run.allFilled) {
      _tick();
      unawaited(_sayChain([M7ReportNoteLines.fillFirst]));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    if (!_run.send()) return;
    setState(() => _wake++);
    await _finish();
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
    final p = _run.pending;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1000), () {
      if (mounted && !_ended && _run.pending == p) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7ReportNoteLines.coworkerCall;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (_run.stage != M7Stage.call) return null;
    if (_intro || _card != null || tableBusy || _connecting) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listenSlip();
      if (m == null) return;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7ReportNoteLines.callHeld], mood: GuideMood.glad));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _connect(refused: true);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7ReportNoteLines.tapWhy[_nudgeN++ % M7ReportNoteLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('m7report/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same stage goes on from where it was.
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
    await _say(!_run.passed ? M7ReportNoteLines.fail : M7ReportNoteLines.sent, mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
    if (_quickBonus) await _say(M7ReportNoteLines.quick, mood: GuideMood.celebrate);
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

  // --- the gesture hand ----------------------------------------------------------
  /// How to touch, never what. The phone (the one way on): a hold ring. The
  /// sheet with no line open: a sweep over the five headers (all alike); once
  /// all are written, a tap on 'পাঠান'. Line A: a short drag nudge on the
  /// minute hand (a fixed clockwise way, never toward the answer), then the
  /// lens tag nudged up, or a sweep over the three poles. B: a sweep over the
  /// cards. C: one sweep over keep and strike; with the stills, an upward
  /// nudge on a still. D: a sweep over the body zones, or the picker when a
  /// zone waits for its kind. E: a sweep over the chips.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final k = _hintN++;
    switch (_run.stage) {
      case M7Stage.replay:
      case M7Stage.sent:
        return null;
      case M7Stage.call:
        return HintSpec.holdOn(_phoneKey);
      case M7Stage.sheet:
        if (_run.pending != null) return null;
        switch (_run.open) {
          case null:
            if (_run.allFilled) return HintSpec.tapOn(_sendKey);
            return HintSpec.sweepOver(_headerKeys.values);
          case M7Line.when:
            final dial = HintSpec.globalRectOf(_dialKey);
            if (k.isEven && dial != null) {
              final a = (_run.timeMin % 60) / 60 * 2 * math.pi;
              final tip = dial.center + Offset(math.sin(a), -math.cos(a)) * (dial.width / 2 * 0.62);
              return HintSpec.drag(tip, toward: Offset(math.cos(a), math.sin(a)), travel: 40);
            }
            if (_lensAt != null) return HintSpec.dragFrom(_lensTagKey, travel: 64);
            return HintSpec.sweep([for (var i = 0; i < 3; i++) geo.pole(i)], space: HintSpace.scene);
          case M7Line.who:
            return HintSpec.sweepOver(_cardKeys);
          case M7Line.how:
            if (!_run.stillsStage) return HintSpec.sweepOver([_keepKey, _strikeKey]);
            final tray = _run.tray;
            if (tray.isEmpty) return null;
            return HintSpec.dragFrom(_stillKeys[tray[k % tray.length]], travel: 64);
          case M7Line.hurt:
            final z = _run.zone;
            if (z != null && !_run.marks.containsKey(z)) return HintSpec.sweepOver([..._kindKeys.values, _noHurtKey]);
            return HintSpec.sweepOver(_zoneKeys.values);
          case M7Line.saw:
            return HintSpec.sweepOver([..._witKeys.values, _nobodyKey]);
        }
    }
  }

  // --- the scene ---------------------------------------------------------------
  M7StreetRig get _rig => M7StreetRig(clockMin: _run.stage == M7Stage.replay ? _deal.accMin : _deal.nowMin);

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7ReportGeo.forScreen(MediaQuery.sizeOf(context), bottomInset: MediaQuery.paddingOf(context).bottom);
    return [
      Positioned.fill(
        key: const ValueKey('street'),
        child: RepaintBoundary(child: CustomPaint(painter: M7StreetPainter(geo: geo, rig: _rig))),
      ),
      Positioned.fill(
        key: const ValueKey('action'),
        child: IgnorePointer(
          child: RepaintBoundary(child: CustomPaint(painter: M7ActionPainter(geo: geo, look: _deal.look, t: _replay))),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7ReportNoteLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
          ),
        ),
      ),
    ];
  }

  // --- the phone ------------------------------------------------------------------
  Widget _phone(EdgeInsets pad) {
    final talking = _connecting;
    return Positioned(
      key: const ValueKey('phone'),
      left: 18,
      bottom: pad.bottom + 78,
      child: Semantics(
        key: _phoneKey,
        button: true,
        label: M7ReportNoteLines.phoneName,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _holdDown(),
          onTapUp: (_) => _holdUp(),
          onTapCancel: _holdUp,
          child: SizedBox(
            width: 112,
            height: 134,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: talking ? const Color(0xFF2E9E5B) : const Color(0xFF1C2E4A),
                          border: Border.all(color: SlmColors.gold300, width: 2.4),
                          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Icon(talking ? Icons.phone_in_talk_rounded : Icons.phone_rounded, size: 34, color: SlmColors.ivory),
                      ),
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _hold,
                          builder: (_, _) => SizedBox(
                            width: 84,
                            height: 84,
                            child: CircularProgressIndicator(value: _hold.value, strokeWidth: 5, color: SlmColors.gold300, backgroundColor: Colors.transparent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                DecoratedBox(
                  decoration: BoxDecoration(color: const Color(0xCC0B1426), borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text(talking ? M7ReportNoteLines.phoneTalking : M7ReportNoteLines.phoneName, style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- the lens ---------------------------------------------------------------------
  Widget _lens(EdgeInsets pad) {
    final i = _lensAt!;
    final no = _deal.poleNos[i];
    return Positioned(
      key: ValueKey('lens-$i'),
      top: pad.top + 114,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xF2101A2B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SlmColors.gold300, width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 88, height: 88, child: CustomPaint(painter: M7LensPainter(number: no))),
            const SizedBox(width: 8),
            Draggable<int>(
              data: no,
              feedback: Material(color: Colors.transparent, child: _NumTag(no: no, lifted: true)),
              childWhenDragging: Opacity(opacity: 0.3, child: _NumTag(no: no)),
              child: KeyedSubtree(key: _lensTagKey, child: _NumTag(key: const ValueKey('m7-lens-tag'), no: no)),
            ),
          ],
        ),
      ),
    );
  }

  // --- the sheet ----------------------------------------------------------------------
  Widget _sheet(EdgeInsets pad) {
    final open = _run.open;
    final body = Container(
      height: M7ReportGeo.sheetDp + pad.bottom,
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + pad.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHead(open),
          const SizedBox(height: 4),
          Expanded(child: open == null ? _lineList() : _linePanel(open)),
          if (open != null) _commitBar(),
        ],
      ),
    );
    return Positioned(
      key: const ValueKey('hud-sheet'),
      left: 0,
      right: 0,
      bottom: 0,
      child: _quiet
          ? body
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Transform.translate(offset: Offset(0, v * 320), child: child),
              child: body,
            ),
    );
  }

  Widget _sheetHead(M7Line? open) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          if (open != null)
            Semantics(
              button: true,
              label: 'ফিরুন',
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('m7-back'),
                behavior: HitTestBehavior.opaque,
                onTap: _closeLine,
                child: const SizedBox(width: 40, height: 30, child: Icon(Icons.chevron_left_rounded, size: 28, color: Color(0xFF3A2A16))),
              ),
            )
          else
            const Padding(padding: EdgeInsets.only(left: 4, right: 6), child: Icon(Icons.edit_note_rounded, size: 22, color: Color(0xFF7A1F1F))),
          Expanded(
            child: Text(
              open == null ? M7ReportNoteLines.sheetTitle : M7ReportNoteLines.headers[open]!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final l in M7Line.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Semantics(
              key: _headerKeys[l],
              button: true,
              label: M7ReportNoteLines.headers[l],
              excludeSemantics: true,
              child: GestureDetector(
                key: ValueKey('m7-line-${l.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _openLine(l),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _run.filled.contains(l) ? const Color(0xFFDDEFD8) : const Color(0xFFFFFCF2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _run.filled.contains(l) ? const Color(0xFF2E8B57) : const Color(0xFFB59A6C), width: 1.4),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(M7ReportNoteLines.headers[l]!, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018)))),
                      Icon(_run.filled.contains(l) ? Icons.check_circle_rounded : Icons.chevron_right_rounded, size: 20, color: _run.filled.contains(l) ? const Color(0xFF2E8B57) : const Color(0xFF8A6A3C)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 2),
        Semantics(
          key: _sendKey,
          button: true,
          label: M7ReportNoteLines.send,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('m7-send'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => unawaited(_send(d.globalPosition)),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _run.allFilled ? const Color(0xFF1C2E4A) : const Color(0xFF6B7686),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SlmColors.gold300, width: 1.6),
              ),
              child: Text(M7ReportNoteLines.send, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _commitBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        button: true,
        label: M7ReportNoteLines.write,
        excludeSemantics: true,
        child: GestureDetector(
          key: const ValueKey('m7-commit'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _commit(d.globalPosition),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2E4A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SlmColors.gold300, width: 1.6),
            ),
            child: Text(M7ReportNoteLines.write, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          ),
        ),
      ),
    );
  }

  Widget _linePanel(M7Line l) => switch (l) {
        M7Line.when => _panelWhen(),
        M7Line.who => _panelWho(),
        M7Line.how => _run.stillsStage ? _panelStills() : _panelDraft(),
        M7Line.hurt => _panelHurt(),
        M7Line.saw => _panelSaw(),
      };

  // A — the dial and the plate slot.
  Widget _panelWhen() {
    final tag = _run.tag;
    return Row(
      children: [
        _Dial(key: _dialKey, minutes: _run.timeMin, onChange: _setTime),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                key: const ValueKey('m7-time'),
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFFFFCF2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFB59A6C), width: 1.2)),
                child: Text(m7TimeText(_run.timeMin), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1F3F8F))),
              ),
              const SizedBox(height: 10),
              DragTarget<int>(
                onWillAcceptWithDetails: (_) => _canPlay,
                onAcceptWithDetails: (d) => _dropTag(d.data),
                builder: (_, cand, _) => GestureDetector(
                  key: const ValueKey('m7-slot-pole'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _act(() {
                    if (_run.tag == null) return false;
                    _run.clearTag();
                    return true;
                  }),
                  child: _Slot(label: M7ReportNoteLines.slotPole, hot: cand.isNotEmpty, height: 62, child: tag == null ? null : _NumTag(no: tag)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // B — the ID cards and the slot.
  Widget _panelWho() {
    final dropped = _run.card;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (dropped == i)
              _Slot(label: '', hot: false, height: 118, width: 102, child: null)
            else
              Draggable<int>(
                data: i,
                feedback: Material(color: Colors.transparent, child: _IdCard(person: _deal.people[i], lifted: true)),
                childWhenDragging: Opacity(opacity: 0.3, child: _IdCard(person: _deal.people[i])),
                child: KeyedSubtree(key: _cardKeys[i], child: _IdCard(key: ValueKey('m7-card-$i'), person: _deal.people[i])),
              ),
            const SizedBox(width: 8),
          ],
          DragTarget<int>(
            onWillAcceptWithDetails: (_) => _canPlay,
            onAcceptWithDetails: (d) => _act(() => _run.dropCard(d.data)),
            builder: (_, cand, _) => GestureDetector(
              key: const ValueKey('m7-slot-who'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _act(() {
                if (_run.card == null) return false;
                _run.clearCard();
                return true;
              }),
              child: _Slot(label: M7ReportNoteLines.slotWho, hot: cand.isNotEmpty, height: 118, width: 102, child: dropped == null ? null : _IdCard(person: _deal.people[dropped])),
            ),
          ),
        ],
      ),
    );
  }

  // C — his draft: keep or strike.
  Widget _panelDraft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFB59A6C), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(M7ReportNoteLines.draftTag, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F))),
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _deal.draftText,
                      key: const ValueKey('m7-draft'),
                      style: bangla(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: const Color(0xFF2A2018),
                      ).copyWith(decoration: _run.pick == M7Pick.strike ? TextDecoration.lineThrough : null, decorationThickness: 2.4, decorationColor: const Color(0xFFB02A1E)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _Chip(key: const ValueKey('m7-keep'), holder: _keepKey, text: M7ReportNoteLines.keep, on: _run.pick == M7Pick.keep, onTap: () => _act(() => _run.setPick(M7Pick.keep)))),
            const SizedBox(width: 8),
            Expanded(child: _Chip(key: const ValueKey('m7-strike'), holder: _strikeKey, text: M7ReportNoteLines.strikeOut, on: _run.pick == M7Pick.strike, onTap: () => _act(() => _run.setPick(M7Pick.strike)))),
          ],
        ),
      ],
    );
  }

  // C — the three replay stills.
  Widget _panelStills() {
    Widget still(int b, {Key? key, bool lifted = false}) => Container(
          key: key,
          width: 98,
          height: 68,
          decoration: BoxDecoration(boxShadow: lifted ? const [BoxShadow(color: Color(0x88000000), blurRadius: 8)] : null),
          child: CustomPaint(painter: M7StillPainter(beat: b, look: _deal.look)),
        );
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var k = 0; k < 3; k++) ...[
              if (k > 0) const SizedBox(width: 8),
              DragTarget<int>(
                onWillAcceptWithDetails: (_) => _canPlay,
                onAcceptWithDetails: (d) => _act(() => _run.placeStill(k, d.data)),
                builder: (_, cand, _) {
                  final b = _run.slots[k];
                  return GestureDetector(
                    key: ValueKey('m7-slot-$k'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _act(() {
                      if (_run.slots[k] == null) return false;
                      _run.clearSlot(k);
                      return true;
                    }),
                    child: _Slot(label: '${k + 1}', hot: cand.isNotEmpty, height: 68, width: 98, child: b == null ? null : still(b)),
                  );
                },
              ),
            ],
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              if (_run.tray.contains(_deal.stillOrder[i]))
                Draggable<int>(
                  data: _deal.stillOrder[i],
                  feedback: Material(color: Colors.transparent, child: still(_deal.stillOrder[i], lifted: true)),
                  childWhenDragging: Opacity(opacity: 0.3, child: still(_deal.stillOrder[i])),
                  child: KeyedSubtree(key: _stillKeys[_deal.stillOrder[i]], child: still(_deal.stillOrder[i], key: ValueKey('m7-still-${_deal.stillOrder[i]}'))),
                )
              else
                const SizedBox(width: 98, height: 68),
            ],
          ],
        ),
      ],
    );
  }

  // D — the body outline and the kind picker.
  Widget _panelHurt() {
    const s = 0.9;
    return Row(
      children: [
        SizedBox(
          width: M7BodyGeo.size.width * s,
          height: M7BodyGeo.size.height * s,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: M7BodyPainter(marks: {..._run.marks}, selected: _run.zone))),
              for (final z in M7Zone.values)
                Positioned.fromRect(
                  key: ValueKey('m7-zone-${z.name}'),
                  rect: Rect.fromLTWH(M7BodyGeo.zones[z]!.left * s, M7BodyGeo.zones[z]!.top * s, M7BodyGeo.zones[z]!.width * s, M7BodyGeo.zones[z]!.height * s),
                  child: Semantics(
                    key: _zoneKeys[z],
                    button: true,
                    label: z.name,
                    excludeSemantics: true,
                    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _act(() => _run.tapZone(z), sound: 'sounds/intro/click.ogg')),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final k in M7Kind.values) ...[
                _Chip(
                  key: ValueKey('m7-kind-${k.name}'),
                  holder: _kindKeys[k]!,
                  text: M7ReportNoteLines.kindChip(k),
                  on: _run.zone != null && _run.marks[_run.zone] == k,
                  onTap: () => _act(() => _run.setKind(k)),
                ),
                const SizedBox(height: 6),
              ],
              _Chip(key: const ValueKey('m7-none'), holder: _noHurtKey, text: M7ReportNoteLines.noHurt, on: _run.noHurt, onTap: () => _act(_run.pressNoHurt)),
            ],
          ),
        ),
      ],
    );
  }

  // E — who watched.
  Widget _panelSaw() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in M7Wit.values) ...[
          _Chip(key: ValueKey('m7-wit-${w.name}'), holder: _witKeys[w]!, text: M7ReportNoteLines.witChip(w), on: _run.saw.contains(w), onTap: () => _act(() => _run.toggleWit(w)), height: 44),
          const SizedBox(height: 8),
        ],
        _Chip(key: const ValueKey('m7-wit-nobody'), holder: _nobodyKey, text: M7ReportNoteLines.nobody, on: _run.nobody, onTap: () => _act(_run.pressNobody), height: 44),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final stage = _run.stage;
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final sheetUp = playing && stage == M7Stage.sheet;
    final handsOn = playing && (stage == M7Stage.call || stage == M7Stage.sheet) && _run.pending == null && !deckUp && !coworkerOpen && _card == null && !_connecting && !_jump;
    final lensUp = sheetUp && _lensAt != null && _run.open == M7Line.when && !deckUp;
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
              labels: M7ReportNoteLines.progress,
              done: {for (final l in _run.filled) l.index},
              current: _run.openIndex,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${stage.name}/${_run.open?.name}/$_steps',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              // The wall clock close up, while the accident plays.
              if (playing && stage == M7Stage.replay && !_jump)
                Positioned(
                  key: const ValueKey('clock-inset'),
                  top: pad.top + 112,
                  right: 10,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _replay,
                      builder: (_, _) {
                        final v = _replay.value;
                        if (v < 0.04 || v > 0.32) return const SizedBox.shrink();
                        return SizedBox(width: 74, height: 74, child: CustomPaint(painter: M7ClockPainter(minutes: _deal.accMin)));
                      },
                    ),
                  ),
                ),
              if (_jump)
                Positioned.fill(
                  key: const ValueKey('jump'),
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: const Color(0x99050A16),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          decoration: BoxDecoration(color: const Color(0xEE101A2B), borderRadius: BorderRadius.circular(16), border: Border.all(color: SlmColors.gold300, width: 2)),
                          child: Text(M7ReportNoteLines.jump(_deal.offset), style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
                        ),
                      ),
                    ),
                  ),
                ),
              if (playing && stage == M7Stage.call && !_jump) _phone(pad),
              if (sheetUp) _sheet(pad),
              if (lensUp) _lens(pad),
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
              if (playing && _card == null && stage != M7Stage.replay && !_jump)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (sheetUp ? M7ReportGeo.sheetDp + 6 : 84)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${stage.name}-$strikes'),
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
                  line: M7ReportNoteLines.intro,
                  alarm: null,
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

/// A number plate tag (the number read in the lens).
class _NumTag extends StatelessWidget {
  const _NumTag({super.key, required this.no, this.lifted = false});
  final int no;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A74),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF4F4F4), width: 2),
        boxShadow: lifted ? const [BoxShadow(color: Color(0x88000000), blurRadius: 8)] : null,
      ),
      child: Text('$no', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFF7F7F7))),
    );
  }
}

/// A crew ID card: name, age, address.
class _IdCard extends StatelessWidget {
  const _IdCard({super.key, required this.person, this.lifted = false});
  final M7Person person;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      height: 118,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F3F8F), width: 2),
        boxShadow: lifted ? const [BoxShadow(color: Color(0x88000000), blurRadius: 8)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 30, height: 24, decoration: BoxDecoration(color: const Color(0xFFE6B891), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(person.name, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018)))),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(M7ReportNoteLines.ageText(person.age), style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2A2018)))),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(person.addr, style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF55483A)))),
        ],
      ),
    );
  }
}

/// A dashed slot a thing is dropped into.
class _Slot extends StatelessWidget {
  const _Slot({required this.label, required this.hot, required this.height, this.width, this.child});
  final String label;
  final bool hot;
  final double height;
  final double? width;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hot ? const Color(0xFFDDE6FA) : const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hot ? const Color(0xFF1F3F8F) : const Color(0xFFB59A6C), width: hot ? 2.4 : 1.4),
      ),
      child: child ?? Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF8A7656))),
    );
  }
}

/// A selectable chip (a free selection committed by 'লিখি').
class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.holder, required this.text, required this.on, required this.onTap, this.height = 40});
  final GlobalKey holder;
  final String text;
  final bool on;
  final VoidCallback onTap;
  final double height;

  static const _ink = Color(0xFF1F3F8F);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: holder,
      button: true,
      selected: on,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFDDE6FA) : const Color(0xFFFFFCF2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: on ? _ink : const Color(0xFFB59A6C), width: on ? 2.4 : 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (on) const Padding(padding: EdgeInsets.only(right: 3), child: Icon(Icons.check_rounded, size: 15, color: _ink)),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(text, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: on ? _ink : const Color(0xFF2A2018))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The clock dial: wind the minute hand (5-minute slots); the hour follows.
class _Dial extends StatelessWidget {
  const _Dial({super.key, required this.minutes, required this.onChange});
  final int minutes;
  final ValueChanged<int> onChange;

  static const double size = 128;

  void _pan(Offset p) {
    final v = p - const Offset(size / 2, size / 2);
    if (v.distance < 8) return;
    var a = math.atan2(v.dx, -v.dy);
    if (a < 0) a += 2 * math.pi;
    final m = ((a / (2 * math.pi) * 12).round() * 5) % 60;
    final curM = minutes % 60;
    var h = minutes ~/ 60;
    if (curM >= 45 && m <= 15) h++;
    if (curM <= 15 && m >= 45) h--;
    final next = (h * 60 + m).clamp(480, 990);
    if (next != minutes) onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ঘড়ি',
      child: GestureDetector(
        key: const ValueKey('m7-dial'),
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _pan(d.localPosition),
        onPanUpdate: (d) => _pan(d.localPosition),
        child: SizedBox(width: size, height: size, child: CustomPaint(painter: M7ClockPainter(minutes: minutes))),
      ),
    );
  }
}
