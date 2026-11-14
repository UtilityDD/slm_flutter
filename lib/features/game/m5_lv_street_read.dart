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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_lv_street_read_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 5.5 "'লো-ভোল্টেজ' সমস্যার সমাধান", কাজ 1 "ড্রপ কোথায়?" (pack
// do_5_5_a, engineType m5_lv_street_read). Verb: ask the street, read the
// voltage pattern. An evening street; three low-voltage complaints a play,
// easy to hard, dealt from five kinds:
//
//   one house · the transformer low (DTR) · gradual drop to the line's end ·
//   one phase low (load unbalance) · a sudden drop between two poles.
//
// Each complaint:
//  1. Ask: tap houses to ask the neighbours (device-voice replies), then the
//     scope chip 'শুধু এই বাড়ি' / 'অনেক বাড়ি'. A chip before any neighbour is
//     asked = slip; the wrong scope = slip.
//  2. Route deck: one house → the service-connection docket (◆ → reason);
//     many → measure at the transformer's LT side first.
//  3. LTDB: tap R / Y / B (the black lead stays on N); readings go into the
//     notebook as plain numbers; 'সিদ্ধান্ত' → the decision deck. 'Transformer
//     fine' needs all three phases (evidence gate); 'চালু অবস্থাতেই ট্যাপ এক
//     ঘর ঘুরাই' = deadly (R21, do_3_6_b); the company myth = slip.
//  4. Line: tap a house's meter board to walk there and probe its incoming;
//     'সিদ্ধান্ত' → the verdict deck (gradual / one phase / sudden /
//     company). A right verdict without its readings = slip (M5-10).
//  5. Docket deck (sudden: three dealt span cards) → ◆ → reason.
//
// The careless coworker: once a play, on a dealt 1st or 2nd probe of one area
// complaint (the probes and the 'সিদ্ধান্ত' button wait for him —
// holdForCoworker): the lesson's myth 1 in his mouth. Listening = slip (R29).
//
// Content: lesson 5.5 points 1–3 and myth 1 only; the voltage numbers are
// illustrative (bands far apart), the LTDB stands in for the LT bushing (no
// climbing a live DTR), and the remedies for a long line / thin wire / one
// heavy phase are reports only (not in 5.5) — all flagged to the owner.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_lv_street_read_world.dart), corner guide, ◆ on the table →
// "কেন …?" after each complaint, mistakes with lesson sources, the deadly
// freeze, 3 slips strike out, gesture hints for every waiting state (a tap
// ripple on the empty road while asking; a sweep over R/Y/B at the LTDB and
// over all ten houses on the line — never one of them), idle = zero frames.

// ============================================================================
// Content
// ============================================================================

/// The kinds of complaint (easy → hard).
enum M5LvKind { oneHouse, dtrLow, gradual, onePhase, sudden }

/// Where a complaint is.
enum M5LvStage { ask, route, ltdb, line, docket }

/// The cards of the LTDB decision deck.
enum M5LvDecide { okLine, lowDocket, liveTap, company }

/// The cards of the verdict deck.
enum M5LvVerdict { gradual, onePhase, sudden, company }

/// The reason question a complaint ends with.
enum M5LvWhy { ask, service, ltSide, unbalance, many }

/// Which choice deck is up.
enum M5LvDeck { none, route, decide, verdict, docket }

const _phaseNames = ['R', 'Y', 'B'];

abstract final class M5LvLines {
  static const title = 'ড্রপ কোথায়?';
  static const intro = 'সন্ধ্যায় পাড়া থেকে লো-ভোল্টেজের ফোন! কার সমস্যা, খুঁজে বের করুন।';
  static const rounds = ['ফোন 1', 'ফোন 2', 'ফোন 3'];

  // The guide's task now (tap him: the same task, a different way).
  static const askAsk = 'বাড়িগুলোতে জিজ্ঞেস করুন — কার কার কম?';
  static const askRoute = 'এবার কী করবেন?';
  static const askLtdb = 'ট্রান্সফরমারের দিকে ভোল্টেজ মাপুন।';
  static const askDecide = 'রিডিং দেখে কী বুঝলেন?';
  static const askLine = 'লাইনের বিভিন্ন বাড়িতে মেপে দেখুন।';
  static const askVerdict = 'রিডিংয়ে কী দেখছেন?';
  static const askDocket = 'কোন ডকেট লিখবেন?';
  static const tasks = [askAsk, askRoute, askLtdb, askDecide, askLine, askVerdict, askDocket];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const newCall = 'আরেকটা ফোন এল!';

  // Labels a worker reads.
  static const sceneLabel = 'সন্ধ্যার পাড়া';
  static const scopeOne = 'শুধু এই বাড়ি';
  static const scopeMany = 'অনেক বাড়ি';
  static const decide = 'সিদ্ধান্ত';
  static const notebook = 'খাতা';
  static const ltdbLabel = 'LTDB';
  static String terminalLabel(int ph) => 'LTDB ${_phaseNames[ph]}';
  static String houseLabel(int h) => 'বাড়ি ${h + 1}';

  // The neighbours (device voice).
  static const callerReply = 'হ্যাঁ, আমরাই ফোন করেছিলাম — আলো টিমটিম!';
  static const lowReplies = ['আমাদেরও আলো টিমটিম করছে', 'আমাদের ফ্যানও খুব আস্তে ঘুরছে', 'হ্যাঁ, আমাদের পাম্পও চলছে না'];
  static const okReplies = ['আমাদের তো সব ঠিক চলছে', 'না, আমাদের আলো একদম ঠিক', 'ফ্যান-টিভি সব ঠিকঠাক চলছে'];

  // The route deck (lesson 5.5 points 1–3). 33–41 letters.
  static const routeOneRight = ['মিটারের ইনকামিং মেপে সার্ভিস জয়েন্ট দেখি', 'সার্ভিস কানেকশন পরীক্ষার ডকেট লিখি'];
  static const routeOneWrong = [
    'আগে ট্রান্সফরমারের এলটি দিকে মাপতে যাই',
    'পুরো এলটি লাইনের সব পোলে মেপে বেড়াই',
    'ট্রান্সফরমারের ট্যাপ বদলের ডকেট লিখি',
    'পাশের ফেজ থেকে আলাদা লাইন টেনে দিই',
    'কোম্পানিকে বলি বেশি ভোল্টেজ পাঠাতে',
  ];
  static const routeAreaRight = ['আগে ট্রান্সফরমারের এলটি দিকে মাপি', 'এলটিডিবি-তে তিন ফেজের ভোল্টেজ মাপি'];
  static const routeAreaWrong = [
    'ফোনের বাড়ির জয়েন্ট টাইট দিয়ে ফিরি',
    'ফোনের বাড়ির মিটারটাই বদলে দিয়ে আসি',
    'ট্রান্সফরমারের ট্যাপ বদলের ডকেট লিখি',
    'শেষ বাড়ি পর্যন্ত নতুন কেবিল টেনে দিই',
    'কোম্পানিকে বলি বেশি ভোল্টেজ পাঠাতে',
  ];

  // The LTDB decision deck. 31–40 letters.
  static const decideText = <M5LvDecide, List<String>>{
    M5LvDecide.okLine: ['তিন ফেজই ঠিক — এবার লাইনে মেপে দেখি', 'ট্রান্সফরমার ঠিক, লাইনের পয়েন্টে মাপি'],
    M5LvDecide.lowDocket: ['ট্রান্সফরমারেই কম — ওভারলোড-ট্যাপের ডকেট', 'এলটিডিবি-তেই কম, ওভারলোড ও ট্যাপের ডকেট'],
    M5LvDecide.liveTap: ['চালু অবস্থাতেই ট্যাপ এক ঘর ঘুরাই', 'লাইন চালু রেখেই ট্যাপ এক ঘর ঘুরিয়ে দিই'],
    M5LvDecide.company: ['কোম্পানিই কম পাঠাচ্ছে, ফিরে যাই', 'ওপর থেকেই কম আসছে, কিছু করার নেই'],
  };

  // The verdict deck (the voltage pattern). 21–26 letters.
  static const verdictText = <M5LvVerdict, List<String>>{
    M5LvVerdict.gradual: ['শেষের দিকে ক্রমশ কমছে', 'পোল যত দূরে, ভোল্টেজ তত কম'],
    M5LvVerdict.onePhase: ['একটা ফেজেই ভোল্টেজ কম', 'শুধু এক ফেজের বাড়িতে কম'],
    M5LvVerdict.sudden: ['দুই পোলের মাঝে হঠাৎ ড্রপ', 'এক স্প্যানের পরে হঠাৎ কম'],
    M5LvVerdict.company: ['কোম্পানিই কম পাঠাচ্ছে', 'ওপর থেকেই কম ভোল্টেজ আসছে'],
  };

  // The docket deck (reports only: the remedies are not in lesson 5.5).
  static const docketRight = <M5LvKind, List<String>>{
    M5LvKind.gradual: ['লম্বা লাইন, সরু তার — রিপোর্ট ডকেট লিখি', 'লাইনের দৈর্ঘ্য ও তারের সাইজের রিপোর্ট দিই'],
    M5LvKind.onePhase: ['এক ফেজে বেশি লোড — ব্যালেন্সের রিপোর্ট দিই', 'ফেজের লোড ব্যালেন্স করার রিপোর্ট লিখি'],
  };
  static const docketWrong = [
    'ট্রান্সফরমারের ট্যাপ বদলের ডকেট লিখি',
    'ফোনের বাড়ির সার্ভিস জয়েন্ট টাইট দিই',
    'কোম্পানিকে বেশি ভোল্টেজ পাঠাতে লিখি',
    'পাড়ার সব বাড়ির মিটার বদলের ডকেট লিখি',
    'কিছু লিখি না, কাল সকালে আবার দেখব',
  ];

  /// A span card of the sudden-drop docket (between pole [a] and a + 1).
  static String spanCard(int a) => 'P$a–P${a + 1} স্প্যানের জয়েন্ট শাটডাউনে টাইট';

  // The reasons (41–51 letters): the right ones fit what was done; the wrong
  // ones are the lesson's myths and field excuses.
  static const whyQ = <M5LvWhy, String>{
    M5LvWhy.ask: 'কেন আগে প্রতিবেশীকে জিজ্ঞেস করলেন?',
    M5LvWhy.service: 'কেন একজনের সমস্যায় সার্ভিস কানেকশনের ডকেট?',
    M5LvWhy.ltSide: 'কেন আগে ট্রান্সফরমারের এলটি দিকে মাপলেন?',
    M5LvWhy.unbalance: 'কেন এটাকে লোড আনব্যালেন্স বললেন?',
    M5LvWhy.many: 'কেন লাইনের অনেক জায়গায় মাপলেন?',
  };
  static const whyRight = <M5LvWhy, List<String>>{
    M5LvWhy.ask: ['একজনের না অনেকের — এতেই খোঁজার এলাকা ছোট হয়', 'কার সমস্যা জানলে বোঝা যায় কোথায় খুঁজতে হবে'],
    M5LvWhy.service: ['একজনেরই কম হলে কারণ সাধারণত তার সার্ভিস কানেকশনে', 'একজনের সমস্যা মানে সার্ভিস বা বাড়ির ওয়্যারিং'],
    M5LvWhy.ltSide: ['অনেকের সমস্যায় আগে দেখি ট্রান্সফরমারেই কম কি না', 'ট্রান্সফরমারেই কম হলে ওভারলোড বা ট্যাপ দেখতে হয়'],
    M5LvWhy.unbalance: ['এক ফেজে বেশি লোড হলে সেই ফেজের গ্রাহকরাই কম পান', 'শুধু এক ফেজের বাড়িগুলোতেই ভোল্টেজ কম পেলাম'],
    M5LvWhy.many: ['ট্রান্সফরমার ঠিক হলে লাইনে মেপে ড্রপের জায়গা খুঁজি', 'কয়েক পয়েন্টে মাপলে বোঝা যায় কোথায় ড্রপ হচ্ছে'],
  };
  static const myths = [
    'ভোল্টেজ কম মানে কোম্পানিই কম বিদ্যুৎ পাঠাচ্ছে',
    'একটু লো-ভোল্টেজে কিছু হয় না, যন্ত্র তো চলছেই',
    'সন্ধ্যায় সবারই কম থাকে, মাপার কোনো দরকার নেই',
    'যেখানে খুশি একবার মাপলেই পুরোটা জানা যায়',
    'গ্রাহকের কথা শুনে লাভ নেই, নিজেই আন্দাজ করি',
    'তাড়াতাড়ি ফিরতে হবে, তাই আন্দাজেই বলে দিলাম',
    'ট্যাপ ঘুরিয়ে দিলেই সব লো-ভোল্টেজ সেরে যায়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  /// The reason questions a kind may end with (one is dealt).
  static const whyFor = <M5LvKind, List<M5LvWhy>>{
    M5LvKind.oneHouse: [M5LvWhy.ask, M5LvWhy.service],
    M5LvKind.dtrLow: [M5LvWhy.ltSide, M5LvWhy.ask],
    M5LvKind.gradual: [M5LvWhy.many, M5LvWhy.ltSide],
    M5LvKind.onePhase: [M5LvWhy.unbalance, M5LvWhy.many],
    M5LvKind.sudden: [M5LvWhy.many, M5LvWhy.ltSide],
  };

  /// The careless coworker: lesson 5.5's myth 1 in his mouth.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'ভোল্টেজ কম মানে কোম্পানিই কম বিদ্যুৎ পাঠাচ্ছে! মাপামাপি করে লাভ নেই, চলো ফিরি।',
    exitLine: coworkerExit,
    right: ['না, কোম্পানি ভোল্টেজ ঠিক রাখে; মেপে খুঁজি', 'না, কারণ স্থানীয় লাইনেই — মেপে বের করব', 'না, না মেপে ফিরব না; ড্রপটা লাইনেই খুঁজি'],
    wrong: [
      'ঠিকই, ওপর থেকেই কম আসছে, ফিরে যাই',
      'সন্ধ্যায় সবারই কম, কাল সকালে দেখব',
      'হ্যাঁ, কোম্পানির দোষ, আমাদের কিছু করার নেই',
      'ঠিক, মাপামাপি করে সময় নষ্ট, চলো ফিরি',
      'আচ্ছা, অফিসে বলে দিই ওপর থেকেই কম',
    ],
    asks: ['কী করবেন?', 'ওর কথায় ফিরে যাবেন, না মাপবেন?', 'কোম্পানির দোষ — মেনে নেবেন?'],
  );

  static const callHeld = 'ঠিক! কোম্পানি ভোল্টেজ ঠিক রাখে — কারণ লাইনেই।';
  static const allSet = 'তিনটে ফোন, তিনটে ঠিক উত্তর — জিজ্ঞেস করে, মেপে, তবে রায়।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে জিজ্ঞেস, তারপর মেপে, তবে সিদ্ধান্ত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtAsk = 'আগে প্রতিবেশীকে জিজ্ঞেস করেছেন';
  static const caughtService = 'একজনের সমস্যায় সার্ভিস কানেকশন';
  static const caughtLt = 'আগে ট্রান্সফরমারের দিকে তিন ফেজ মেপেছেন';
  static const caughtRead = 'রিডিং দেখে ঠিক রায়';
  static const caughtCall = 'কোম্পানির মিথে “না” বলেছেন';
}

abstract final class M5LvMistakes {
  static const _ask = 'assets/game/art/m5_lv_street_read/ask_first.svg';
  static const _scope = 'assets/game/art/m5_lv_street_read/scope.svg';
  static const _route = 'assets/game/art/m5_lv_street_read/route.svg';
  static const _three = 'assets/game/art/m5_lv_street_read/three_phase.svg';
  static const _tap = 'assets/game/art/m5_lv_street_read/live_tap.svg';
  static const _myth = 'assets/game/art/m5_lv_street_read/myth.svg';
  static const _read = 'assets/game/art/m5_lv_street_read/readings.svg';
  static const _docket = 'assets/game/art/m5_lv_street_read/docket.svg';

  static const askFirst = DoMistake(
    key: '5.5/m5_lv_street_read/ask-first',
    textBn: 'আগে প্রতিবেশীদের জিজ্ঞেস করুন — একজনের সমস্যা, না অনেকের? এই প্রশ্নই খোঁজার এলাকা ছোট করে।',
    art: _ask,
    lessonPoint: 0,
  );
  static const scopeOne = DoMistake(
    key: '5.5/m5_lv_street_read/scope-one',
    textBn: 'প্রতিবেশীদের তো ঠিক আছে — শুধু এই বাড়িতেই কম। একজনের সমস্যা মানে তার সার্ভিস কানেকশন বা বাড়ির ওয়্যারিং।',
    art: _scope,
    lessonPoint: 0,
  );
  static const scopeMany = DoMistake(
    key: '5.5/m5_lv_street_read/scope-many',
    textBn: 'পাড়ার অনেকেরই কম — তাহলে কারণ ট্রান্সফরমার বা এলটি নেটওয়ার্কে, একটা বাড়িতে নয়।',
    art: _scope,
    lessonPoint: 0,
  );
  static const routeOne = DoMistake(
    key: '5.5/m5_lv_street_read/route-one',
    textBn: 'একজনের সমস্যায় আগে তার মিটারের ইনকামিং-এ মাপুন; কম হলে সার্ভিস কানেকশনের প্রতিটি জয়েন্ট পরীক্ষা করে টাইট দিন।',
    art: _route,
    lessonPoint: 1,
  );
  static const routeArea = DoMistake(
    key: '5.5/m5_lv_street_read/route-area',
    textBn: 'অনেকের সমস্যায় আগে ট্রান্সফরমারের এলটি দিকে ভোল্টেজ মাপুন — সেখানেই কম, না লাইনে?',
    art: _route,
    lessonPoint: 2,
  );
  static const threePhase = DoMistake(
    key: '5.5/m5_lv_street_read/three-phase',
    textBn: 'তিন ফেজই মাপুন। একটা-দুটো ফেজ দেখে ট্রান্সফরমার ঠিক বলা যায় না।',
    art: _three,
    lessonPoint: 2,
  );
  static const wrongDtr = DoMistake(
    key: '5.5/m5_lv_street_read/wrong-dtr',
    textBn: 'রিডিং মিলিয়ে দেখুন: ট্রান্সফরমারেই কম হলে ওভারলোড আর ট্যাপ সেটিং পরীক্ষা; ঠিক থাকলে এলটি লাইনের বিভিন্ন পয়েন্টে মাপুন।',
    art: _three,
    lessonPoint: 2,
  );
  static const liveTap = DoMistake(
    key: '5.5/m5_lv_street_read/live-tap',
    textBn: 'অফ-লোড ট্যাপ চেঞ্জার চালু অবস্থায় কখনো নয়! আগে ডকেট, শাটডাউন, HT-LT দুদিক বন্ধ, মৃত প্রমাণ, আর্থিং — তবে ট্যাপ।',
    art: _tap,
    deadly: true,
    lessonPoint: 2,
  );
  static const company = DoMistake(
    key: '5.5/m5_lv_street_read/company-myth',
    textBn: 'ভুল ধারণা! কোম্পানি নির্দিষ্ট ভোল্টেজ রাখে — লো-ভোল্টেজের কারণ সাধারণত ওভারলোড, লম্বা লাইন বা সার্ভিস কানেকশন।',
    art: _myth,
  );
  static const evidence = DoMistake(
    key: '5.5/m5_lv_street_read/no-evidence',
    textBn: 'রিডিং ছাড়া রায় নয়! লাইনের বিভিন্ন পয়েন্টে মেপে দেখুন কোথায় ড্রপ হচ্ছে, তারপর বলুন।',
    art: _read,
    lessonPoint: 2,
  );
  static const wrongVerdict = DoMistake(
    key: '5.5/m5_lv_street_read/wrong-verdict',
    textBn: 'রিডিংগুলো আবার মিলিয়ে দেখুন — শেষের দিকে ক্রমশ কম, একটা ফেজেই কম, না দুই পোলের মাঝে হঠাৎ ড্রপ?',
    art: _read,
    lessonPoint: 2,
  );
  static const wrongDocket = DoMistake(
    key: '5.5/m5_lv_street_read/wrong-docket',
    textBn: 'এই ডকেট রিডিংয়ের সাথে মেলে না। যেখানে আর যে কারণে ড্রপ, সেই কাজের ডকেট লিখুন।',
    art: _docket,
    lessonPoint: 2,
  );
  static const listened = DoMistake(
    key: '5.5/m5_lv_street_read/listened',
    textBn: 'মিথ! কোম্পানি ভোল্টেজ ঠিক রাখে। কারণ স্থানীয় লাইনেই — না মেপে ফেরা নয়।',
    art: _myth,
  );

  static List<DoMistake> get all =>
      [askFirst, scopeOne, scopeMany, routeOne, routeArea, threePhase, wrongDtr, liveTap, company, evidence, wrongVerdict, wrongDocket, listened];
}

/// One complaint of the play (all its numbers are dealt).
@immutable
class M5LvComplaint {
  const M5LvComplaint({
    required this.kind,
    required this.caller,
    required this.phases,
    required this.lowPhase,
    required this.dropAt,
    required this.jitter,
    required this.ltdbJitter,
    required this.replies,
    required this.why,
    required this.scopeFlip,
  });

  final M5LvKind kind;

  /// The house that phoned.
  final int caller;

  /// Each house's phase (0 = R, 1 = Y, 2 = B).
  final List<int> phases;

  /// The heavy phase (one-phase complaints; -1 otherwise).
  final int lowPhase;

  /// The sudden drop is on the span P[dropAt]–P[dropAt + 1].
  final int dropAt;

  /// ±2 V per house, and per LTDB phase.
  final List<int> jitter;
  final List<int> ltdbJitter;

  /// The reply each neighbour gives (an index into the reply lines).
  final List<int> replies;

  /// The reason question at the end.
  final M5LvWhy why;

  /// The scope chips swap places.
  final bool scopeFlip;

  bool get area => kind != M5LvKind.oneHouse;

  /// The house's incoming voltage under the evening load (illustrative).
  int volts(int h) {
    final p = M5LvGeo.poleOf(h);
    final base = switch (kind) {
      M5LvKind.oneHouse => h == caller ? 204 : 234 - p,
      M5LvKind.dtrLow => 200 - p,
      M5LvKind.gradual => 234 - 7 * (p - 1),
      M5LvKind.onePhase => phases[h] == lowPhase ? 208 - p : 234 - p,
      M5LvKind.sudden => p <= dropAt ? 234 - p : 206 - p,
    };
    return base + jitter[h];
  }

  /// Phase [ph] to N at the LTDB.
  int ltdbVolts(int ph) => (kind == M5LvKind.dtrLow ? 202 : 235) + ltdbJitter[ph];

  /// The neighbours here say their voltage is low.
  bool low(int h) => volts(h) < 218;
}

@immutable
class M5LvDeal {
  const M5LvDeal({required this.complaints, required this.coworkerAt, required this.coworkerProbe});
  final List<M5LvComplaint> complaints;

  /// The coworker comes in this complaint (always one with many houses)…
  final int coworkerAt;

  /// …on its 1st or 2nd probe.
  final int coworkerProbe;
}

bool _spansLine(List<int> phases, int ph) {
  final poles = [for (var h = 0; h < M5LvGeo.houses; h++) if (phases[h] == ph) M5LvGeo.poleOf(h)];
  return poles.length >= 3 && poles.any((p) => p <= 3) && poles.any((p) => p >= 4);
}

M5LvComplaint _dealComplaint(M5LvKind kind, math.Random rng) {
  late List<int> phases;
  var lowPhase = -1;
  while (true) {
    phases = [0, 1, 2, 0, 1, 2, 0, 1, 2, rng.nextInt(3)]..shuffle(rng);
    if (kind != M5LvKind.onePhase) break;
    final ok = [for (var ph = 0; ph < 3; ph++) if (_spansLine(phases, ph)) ph];
    if (ok.isNotEmpty) {
      lowPhase = ok[rng.nextInt(ok.length)];
      break;
    }
  }
  final dropAt = 2 + rng.nextInt(3);
  final callers = [
    for (var h = 0; h < M5LvGeo.houses; h++)
      if (switch (kind) {
        M5LvKind.oneHouse || M5LvKind.dtrLow => true,
        M5LvKind.gradual => M5LvGeo.poleOf(h) >= 5,
        M5LvKind.onePhase => phases[h] == lowPhase,
        M5LvKind.sudden => M5LvGeo.poleOf(h) > dropAt,
      })
        h,
  ];
  final whys = M5LvLines.whyFor[kind]!;
  return M5LvComplaint(
    kind: kind,
    caller: callers[rng.nextInt(callers.length)],
    phases: phases,
    lowPhase: lowPhase,
    dropAt: dropAt,
    jitter: [for (var h = 0; h < M5LvGeo.houses; h++) rng.nextInt(5) - 2],
    ltdbJitter: [for (var p = 0; p < 3; p++) rng.nextInt(5) - 2],
    replies: [for (var h = 0; h < M5LvGeo.houses; h++) rng.nextInt(3)],
    why: whys[rng.nextInt(whys.length)],
    scopeFlip: rng.nextBool(),
  );
}

/// Three complaints of different kinds, easy to hard; the coworker on one of
/// the complaints with many houses (every play has at least two).
M5LvDeal m5LvDeal(math.Random rng) {
  final kinds = [...M5LvKind.values]..shuffle(rng);
  final pick = kinds.take(3).toList()..sort((a, b) => a.index - b.index);
  final complaints = [for (final k in pick) _dealComplaint(k, rng)];
  final area = [for (var i = 0; i < complaints.length; i++) if (complaints[i].area) i];
  return M5LvDeal(complaints: complaints, coworkerAt: area[rng.nextInt(area.length)], coworkerProbe: 1 + rng.nextInt(2));
}

/// The verdict that fits a line complaint.
M5LvVerdict? m5LvRightVerdict(M5LvKind k) => switch (k) {
      M5LvKind.gradual => M5LvVerdict.gradual,
      M5LvKind.onePhase => M5LvVerdict.onePhase,
      M5LvKind.sudden => M5LvVerdict.sudden,
      _ => null,
    };

/// The readings that prove verdict [v] (the evidence gate, ruling M5-10).
bool m5LvEvidence(M5LvComplaint c, M5LvVerdict v, List<int> probed) {
  final poles = {for (final h in probed) M5LvGeo.poleOf(h)};
  switch (v) {
    case M5LvVerdict.gradual:
      return poles.length >= 3 && poles.reduce(math.min) <= 2 && poles.reduce(math.max) >= 5;
    case M5LvVerdict.onePhase:
      return probed.where((h) => c.phases[h] == c.lowPhase).length >= 2 && probed.any((h) => c.phases[h] != c.lowPhase);
    case M5LvVerdict.sudden:
      return poles.contains(c.dropAt) && poles.contains(c.dropAt + 1);
    case M5LvVerdict.company:
      return false;
  }
}

/// One card of a choice deck and what it means.
@immutable
class M5LvCard {
  const M5LvCard(this.textBn, this.value, {required this.correct});
  final String textBn;
  final Object value;
  final bool correct;
}

List<M5LvCard> m5LvRouteDeck(bool area, math.Random rng) => [
      for (final o in dealChoices(area ? M5LvLines.routeAreaRight : M5LvLines.routeOneRight,
          area ? M5LvLines.routeAreaWrong : M5LvLines.routeOneWrong, rng))
        M5LvCard(o.textBn, o.correct, correct: o.correct),
    ];

/// The right reading, the other reading, and a trap (on a low transformer
/// always the live tap change; otherwise the tap change or the myth).
List<M5LvCard> m5LvDecideDeck(M5LvComplaint c, math.Random rng) {
  final right = c.kind == M5LvKind.dtrLow ? M5LvDecide.lowDocket : M5LvDecide.okLine;
  final other = right == M5LvDecide.okLine ? M5LvDecide.lowDocket : M5LvDecide.okLine;
  final trap = c.kind == M5LvKind.dtrLow || rng.nextBool() ? M5LvDecide.liveTap : M5LvDecide.company;
  String say(M5LvDecide d) => M5LvLines.decideText[d]![rng.nextInt(2)];
  return [for (final d in [right, other, trap]) M5LvCard(say(d), d, correct: d == right)]..shuffle(rng);
}

List<M5LvCard> m5LvVerdictDeck(M5LvComplaint c, math.Random rng) => [
      for (final v in M5LvVerdict.values) M5LvCard(M5LvLines.verdictText[v]![rng.nextInt(2)], v, correct: v == m5LvRightVerdict(c.kind)),
    ]..shuffle(rng);

List<M5LvCard> m5LvDocketDeck(M5LvComplaint c, math.Random rng) {
  if (c.kind == M5LvKind.sudden) {
    final others = [for (var a = 1; a < M5LvGeo.poles; a++) if (a != c.dropAt) a]..shuffle(rng);
    return [for (final a in [c.dropAt, ...others.take(2)]) M5LvCard(M5LvLines.spanCard(a), a, correct: a == c.dropAt)]..shuffle(rng);
  }
  final otherKind = c.kind == M5LvKind.gradual ? M5LvKind.onePhase : M5LvKind.gradual;
  return [
    for (final o in dealChoices(M5LvLines.docketRight[c.kind]!, [...M5LvLines.docketWrong, ...M5LvLines.docketRight[otherKind]!], rng))
      M5LvCard(o.textBn, o.correct, correct: o.correct),
  ];
}

/// The play state (pure logic).
class M5LvRun {
  M5LvRun(this.deal);
  final M5LvDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The complaint's work is done (its reason comes next).
  var roundDone = false;
  var stage = M5LvStage.ask;

  /// Neighbours asked (the caller does not count).
  final Set<int> asked = {};

  /// LTDB readings by phase, in the order taken.
  final Map<int, int> ltdb = {};

  /// Houses probed on the line, in the order taken.
  final List<int> probed = [];

  /// Probes placed this complaint (LTDB and line).
  int probes = 0;

  M5LvComplaint get c => deal.complaints[index.clamp(0, deal.complaints.length - 1)];
  bool get done => index >= deal.complaints.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  /// Asks at house [h]: true = they say it is low there.
  bool ask(int h) {
    if (_open && stage == M5LvStage.ask && h != c.caller) asked.add(h);
    return c.low(h);
  }

  /// The scope chip: [many] houses or only this one.
  DoMistake? scope(bool many) {
    if (!_open || stage != M5LvStage.ask) return null;
    if (asked.isEmpty) return _slip(M5LvMistakes.askFirst);
    if (many != c.area) return _slip(many ? M5LvMistakes.scopeOne : M5LvMistakes.scopeMany);
    stage = M5LvStage.route;
    if (thorough) _tag(M5LvLines.caughtAsk);
    return null;
  }

  /// The route card ([right] for this scope or not).
  DoMistake? route(bool right) {
    if (!_open || stage != M5LvStage.route) return null;
    if (!right) return _slip(c.area ? M5LvMistakes.routeArea : M5LvMistakes.routeOne);
    if (c.area) {
      stage = M5LvStage.ltdb;
    } else {
      roundDone = true;
      if (thorough) _tag(M5LvLines.caughtService);
    }
    return null;
  }

  /// A probe on phase [ph] at the LTDB (the black lead on N).
  bool probeLtdb(int ph) {
    if (!_open || stage != M5LvStage.ltdb) return false;
    ltdb.remove(ph);
    ltdb[ph] = c.ltdbVolts(ph);
    probes++;
    return true;
  }

  /// The LTDB decision.
  DoMistake? decide(M5LvDecide d) {
    if (!_open || stage != M5LvStage.ltdb) return null;
    final low = c.kind == M5LvKind.dtrLow;
    switch (d) {
      case M5LvDecide.liveTap:
        return deadly = M5LvMistakes.liveTap;
      case M5LvDecide.company:
        return _slip(M5LvMistakes.company);
      case M5LvDecide.okLine:
        if (low) return _slip(M5LvMistakes.wrongDtr);
        if (ltdb.length < 3) return _slip(M5LvMistakes.threePhase);
        stage = M5LvStage.line;
        if (thorough) _tag(M5LvLines.caughtLt);
      case M5LvDecide.lowDocket:
        if (!low) return _slip(M5LvMistakes.wrongDtr);
        if (ltdb.isEmpty) return _slip(M5LvMistakes.threePhase);
        roundDone = true;
        if (thorough) _tag(M5LvLines.caughtLt);
    }
    return null;
  }

  /// A probe on house [h]'s incoming (the trainee walks there).
  bool probeHouse(int h) {
    if (!_open || stage != M5LvStage.line) return false;
    if (!probed.contains(h)) probed.add(h);
    probes++;
    return true;
  }

  /// The verdict on the line's voltage pattern (evidence-gated).
  DoMistake? verdict(M5LvVerdict v) {
    if (!_open || stage != M5LvStage.line) return null;
    if (v == M5LvVerdict.company) return _slip(M5LvMistakes.company);
    if (v != m5LvRightVerdict(c.kind)) return _slip(M5LvMistakes.wrongVerdict);
    if (!m5LvEvidence(c, v, probed)) return _slip(M5LvMistakes.evidence);
    stage = M5LvStage.docket;
    // The praise is for reading a planned set, not for probing every house.
    if (thorough && probed.length < m5LvBlanketProbes) _tag(M5LvLines.caughtRead);
    return null;
  }

  /// The docket card.
  DoMistake? docket(bool right) {
    if (!_open || stage != M5LvStage.docket) return null;
    if (!right) return _slip(M5LvMistakes.wrongDocket);
    roundDone = true;
    return null;
  }

  /// Listened to the coworker's myth.
  DoMistake listened() => _slip(M5LvMistakes.listened);

  void next() {
    index++;
    roundSlips = 0;
    roundDone = false;
    stage = M5LvStage.ask;
    asked.clear();
    ltdb.clear();
    probed.clear();
    probes = 0;
  }
}

/// Probing this many houses (of 10) is blanket probing: the verdict still
/// stands, but 'রিডিং দেখে ঠিক রায়' is not earned (every gate needs 2–4).
const m5LvBlanketProbes = 8;

/// True if this mistake sends the player back to measure (the deck closes).
bool m5LvBackToMeasure(DoMistake m) => m == M5LvMistakes.evidence || m == M5LvMistakes.threePhase;

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   an easy complaint: 3 asks + chip + route deck ≈ 9000 + reason ~8200
///   a middle one: + LTDB 3 probes + decide ≈ 21000 + reason ~8200
///   a hard one: + 4 line probes + verdict + docket ≈ 31000 + reason ~8200
/// + the coworker once ≈ 9600                                     ≈ 104000
/// 85 % ≈ 88000 → 90 s (a new level: owner to confirm).
const m5LvQuickMs = 90000;

@immutable
class M5LvPack {
  const M5LvPack({required this.id, required this.titleBn, this.quickMs = m5LvQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5LvPack> m5LvStreetReadPacks = {
  'do_5_5_a': M5LvPack(id: 'do_5_5_a', titleBn: M5LvLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M5LvStreetReadPage extends StatefulWidget {
  const M5LvStreetReadPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5LvPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5LvStreetReadPage> createState() => _M5LvStreetReadPageState();
}

class _M5LvStreetReadPageState extends State<M5LvStreetReadPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _StreetRunPage(
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

class _StreetRunPage extends ConsumerStatefulWidget {
  const _StreetRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5LvPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_StreetRunPage> createState() => _StreetRunPageState();
}

class _StreetRunPageState extends ConsumerState<_StreetRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5LvRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  // The choice deck of the moment.
  M5LvDeck _deck = M5LvDeck.none;
  List<M5LvCard> _cards = const [];
  final Set<String> _deckWrong = {};
  String? _deckPicked;
  var _deckBusy = false;

  /// The scope chip open big (two steps: its preview, then ✓), where it was
  /// tapped, and the chips set aside with ✕ this round (false = one house).
  bool? _scopePreview;
  Offset _scopeAt = Offset.zero;
  final Set<bool> _scopeAside = {};

  // The street: the last reply, the last reading, where the trainee is.
  int? _replyHouse;
  String _replyText = '';
  int _replyTok = 0;
  int? _readHouse;
  int _readTok = 0;
  int? _probePhase;
  int? _lastHouse;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final List<GlobalKey> _termKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  M5LvGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    // The deal first (a seed's play is the same).
    _run = M5LvRun(m5LvDeal(widget.rng));
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M5LvComplaint get _c => _run.c;

  @override
  void dispose() {
    disposeCoworker();
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

  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task => switch (_run.stage) {
        M5LvStage.ask => M5LvLines.askAsk,
        M5LvStage.route => M5LvLines.askRoute,
        M5LvStage.ltdb => _deck == M5LvDeck.decide ? M5LvLines.askDecide : M5LvLines.askLtdb,
        M5LvStage.line => _deck == M5LvDeck.verdict ? M5LvLines.askVerdict : M5LvLines.askLine,
        M5LvStage.docket => M5LvLines.askDocket,
      };

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() => _wake++);
    unawaited(_sayChain([if (_run.index > 0) M5LvLines.newCall, _task]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tapScene(Offset p, M5LvGeo geo) {
    if (!_canPlay || _deck != M5LvDeck.none) return;
    final stage = _run.stage;
    if (stage == M5LvStage.ask || stage == M5LvStage.line) {
      for (var h = 0; h < M5LvGeo.houses; h++) {
        if (geo.house(h).contains(p)) {
          if (stage == M5LvStage.ask) {
            _askHouse(h);
          } else {
            _probeHouse(h);
          }
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _askHouse(int h) {
    _tick();
    final low = _run.ask(h);
    final text = h == _c.caller ? M5LvLines.callerReply : (low ? M5LvLines.lowReplies : M5LvLines.okReplies)[_c.replies[h]];
    setState(() {
      _replyHouse = h;
      _replyText = text;
      _replyTok++;
      _lastHouse = h;
      _wake++;
    });
    // A neighbour speaks (device voice), not the guide.
    _hush();
    unawaited(MascotSpeechLibrary.speak(text, muted: _muted));
  }

  /// A tap on a scope chip opens it big; nothing is answered yet.
  void _openScope(bool many, Offset global) {
    if (!_canPlay || _deck != M5LvDeck.none || _run.stage != M5LvStage.ask || _scopePreview != null) return;
    setState(() {
      _scopePreview = many;
      _scopeAt = global;
    });
  }

  /// ✓ on the scope chip's preview: the answer (as one tap was before).
  void _confirmScope() {
    final many = _scopePreview;
    if (many == null) return;
    setState(() {
      _scopePreview = null;
      _scopeAside.clear();
    });
    _pickScope(many, _scopeAt);
  }

  /// ✕: that chip is set aside (dimmed), nothing is answered.
  void _rejectScope() {
    final many = _scopePreview;
    if (many == null) return;
    setState(() {
      _scopePreview = null;
      _scopeAside.add(many);
    });
  }

  void _pickScope(bool many, Offset global) {
    if (!_canPlay || _deck != M5LvDeck.none || _run.stage != M5LvStage.ask) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    final m = _run.scope(many);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    _openDeck(M5LvDeck.route);
  }

  void _maybeCoworker() {
    if (!coworkerDone && _run.index == _run.deal.coworkerAt && _run.probes == _run.deal.coworkerProbe - 1) scheduleCoworker();
  }

  void _probeLtdb(int ph) {
    if (!_canPlay || _deck != M5LvDeck.none || _run.stage != M5LvStage.ltdb) return;
    // The probes wait for the coworker once he is due.
    if (holdForCoworker()) return;
    _tick('sounds/intro/impact_metal.ogg', 0.45);
    _run.probeLtdb(ph);
    setState(() {
      _probePhase = ph;
      _wake++;
    });
    _maybeCoworker();
  }

  void _probeHouse(int h) {
    if (holdForCoworker()) return;
    _tick('sounds/intro/impact_metal.ogg', 0.45);
    _run.probeHouse(h);
    setState(() {
      _readHouse = h;
      _readTok++;
      _lastHouse = h;
      _wake++;
    });
    _maybeCoworker();
  }

  void _decideTap() {
    if (!_canPlay || _deck != M5LvDeck.none) return;
    final stage = _run.stage;
    if (stage != M5LvStage.ltdb && stage != M5LvStage.line) return;
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.5);
    _openDeck(stage == M5LvStage.ltdb ? M5LvDeck.decide : M5LvDeck.verdict);
  }

  void _openDeck(M5LvDeck d) {
    final rng = widget.rng;
    final cards = switch (d) {
      M5LvDeck.route => m5LvRouteDeck(_c.area, rng),
      M5LvDeck.decide => m5LvDecideDeck(_c, rng),
      M5LvDeck.verdict => m5LvVerdictDeck(_c, rng),
      M5LvDeck.docket => m5LvDocketDeck(_c, rng),
      M5LvDeck.none => const <M5LvCard>[],
    };
    setState(() {
      _deck = d;
      _cards = cards;
      _deckWrong.clear();
      _deckPicked = null;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([_task], mood: GuideMood.think));
  }

  void _closeDeck() {
    _deck = M5LvDeck.none;
    _cards = const [];
    _deckWrong.clear();
    _deckPicked = null;
  }

  Future<void> _pickCard(ChoiceOption o, Offset origin) async {
    if (!_canPlay || _deck == M5LvDeck.none || _deckBusy || _deckWrong.contains(o.textBn) || _deckPicked != null) return;
    final card = _cards.firstWhere((x) => x.textBn == o.textBn);
    _hush();
    final m = switch (_deck) {
      M5LvDeck.route => _run.route(card.correct),
      M5LvDeck.decide => _run.decide(card.value as M5LvDecide),
      M5LvDeck.verdict => _run.verdict(card.value as M5LvVerdict),
      M5LvDeck.docket => _run.docket(card.correct),
      M5LvDeck.none => null,
    };
    if (m != null) {
      if (!m.deadly) {
        setState(() {
          if (m5LvBackToMeasure(m)) {
            _closeDeck();
          } else {
            _deckWrong.add(card.textBn);
          }
        });
      }
      unawaited(_mistake(m, origin));
      return;
    }
    _deckBusy = true;
    setState(() => _deckPicked = card.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _deckBusy = false;
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    setState(() {
      _closeDeck();
      _wake++;
    });
    if (_run.roundDone) {
      unawaited(_roundDone());
      return;
    }
    switch (_run.stage) {
      case M5LvStage.docket:
        _openDeck(M5LvDeck.docket);
      case M5LvStage.ltdb:
        setState(() => _probePhase = null);
        unawaited(_sayChain([M5LvLines.askLtdb]));
        _maybeCoworker();
      case M5LvStage.line:
        unawaited(_sayChain([M5LvLines.askLine]));
      default:
        break;
    }
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final why = _c.why;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5LvLines.whyRight[why]!, M5LvLines.myths, widget.rng),
      question: M5LvLines.whyQ[why]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(() {
      _run.next();
      _replyHouse = null;
      _readHouse = null;
      _probePhase = null;
      _lastHouse = null;
      _closeDeck();
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5LvLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index > _run.deal.coworkerAt || _run.roundDone) return null;
    if (_run.index < _run.deal.coworkerAt) return false;
    final stage = _run.stage;
    if (stage == M5LvStage.docket) return null;
    if (stage != M5LvStage.ltdb && stage != M5LvStage.line) return false;
    if (_intro || _card != null || tableBusy || _deck != M5LvDeck.none || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to the myth: a slip (R29); the measuring goes on after it.
      await _mistake(_run.listened(), origin);
      return;
    }
    _run.caught.add(M5LvLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5LvLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5LvLines.tapWhy[_nudgeN++ % M5LvLines.tapWhy.length]
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
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('lvstreet/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A live tap change: the scene freezes grey and the transformer flashes in
  /// colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _closeDeck();
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
    final speak = await SpokenOnce.first('lvstreet/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5LvLines.deadlyWord : M5LvLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same complaint goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        unawaited(_sayChain([_task]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
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
    await _say(!_run.passed ? M5LvLines.fail : (_quickBonus ? M5LvLines.quick : M5LvLines.allSet),
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
    if (_passed) return LinemanMode.cheer;
    if (_run.stage == M5LvStage.ltdb && _probePhase != null) return LinemanMode.hold;
    if (_run.stage == M5LvStage.line && _readHouse != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  Rect _traineeAt(M5LvGeo geo) {
    final stage = _run.stage;
    if (stage == M5LvStage.ltdb) return geo.atLtdb;
    final h = _lastHouse;
    return h == null ? geo.onRoad : geo.byHouse(h);
  }

  /// A design-px rect of the scene on screen (null before layout).
  Rect? _sceneRect(Rect r) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// The gesture hand: how to touch, never what. Asking: a tap ripple on the
  /// empty road (tap a house). LTDB: a sweep over R, Y and B alike. Line: a
  /// sweep over all ten houses, left to right.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.stage) {
      case M5LvStage.ask:
        final r = _sceneRect(Rect.fromCenter(center: geo.roadSpot, width: 2, height: 2));
        return r == null ? null : HintSpec.tap(r.center);
      case M5LvStage.ltdb:
        final rects = [for (final k in _termKeys) ?HintSpec.globalRectOf(k)];
        return rects.length < 2 ? null : HintSpec.sweep(rects);
      case M5LvStage.line:
        final houses = [for (var h = 0; h < M5LvGeo.houses; h++) h]..sort((a, b) => geo.house(a).center.dx.compareTo(geo.house(b).center.dx));
        final rects = [for (final h in houses) ?_sceneRect(geo.house(h))];
        return rects.length < 2 ? null : HintSpec.sweep(rects);
      default:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5LvGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final caller = _c.caller;
    final callerRect = geo.house(caller);
    final reply = _replyHouse;
    final read = _readHouse;
    final asking = _run.stage == M5LvStage.ask;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('street'),
                child: RepaintBoundary(child: CustomPaint(painter: M5LvStreetPainter(geo: geo, seed: 3))),
              ),
              // The house that phoned.
              if (!_run.done)
                Positioned(
                  key: ValueKey('caller-${_run.index}'),
                  left: callerRect.center.dx - 11,
                  top: callerRect.top - 24,
                  child: const IgnorePointer(child: _PhoneBadge()),
                ),
              // Neighbours already asked (no sign of what they said).
              if (asking)
                for (final h in _run.asked)
                  Positioned(
                    key: ValueKey('asked-$h'),
                    left: geo.house(h).right - 12,
                    top: geo.house(h).top + 2,
                    child: const IgnorePointer(child: Icon(Icons.chat_bubble_rounded, size: 11, color: Color(0xCCDCE3EA))),
                  ),
              // Meter boards already probed (no sign of the value).
              if (_run.stage == M5LvStage.line || _run.stage == M5LvStage.docket)
                for (final h in _run.probed)
                  Positioned(
                    key: ValueKey('probed-$h'),
                    left: geo.meter(h).left - 1,
                    top: geo.meter(h).top - 12,
                    child: const IgnorePointer(child: Icon(Icons.bolt_rounded, size: 11, color: Color(0xFFFFE08A))),
                  ),
              AnimatedPositioned.fromRect(
                key: const ValueKey('trainee'),
                rect: _traineeAt(geo),
                duration: Duration(milliseconds: quiet ? 1 : 650),
                curve: Curves.easeInOut,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (asking && reply != null && !_freeze)
        Positioned(
          key: ValueKey('reply-$_replyTok'),
          left: (geo.house(reply).center.dx - 80).clamp(4.0, 196.0),
          top: geo.house(reply).top - 46,
          width: 160,
          child: IgnorePointer(child: _Bubble(text: _replyText, quiet: quiet)),
        ),
      if (_run.stage == M5LvStage.line && read != null && !_freeze)
        Positioned(
          key: ValueKey('read-$_readTok'),
          left: (geo.house(read).center.dx - 30).clamp(4.0, 296.0),
          top: geo.house(read).top - 30,
          width: 60,
          child: IgnorePointer(child: _ReadChip(volts: _c.volts(read), quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5LvLines.sceneLabel,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M5LvFlashPainter(geo: geo, v: v)),
            ),
          ),
        ),
      // The next complaint: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.6, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  /// The notebook rows: plain numbers, in the order taken (at the LTDB its
  /// three phases; on the line the houses — the LTDB is done by then).
  List<(String, int)> get _rows => _run.stage == M5LvStage.ltdb
      ? [for (final e in _run.ltdb.entries) ('${M5LvLines.ltdbLabel} ${_phaseNames[e.key]}', e.value)]
      : [for (final h in _run.probed) ('P${M5LvGeo.poleOf(h)} ${_phaseNames[_c.phases[h]]}', _c.volts(h))];

  Widget _bottomControls(EdgeInsets pad) {
    final stage = _run.stage;
    switch (stage) {
      case M5LvStage.ask:
        final chips = [
          CardAside(
            aside: _scopeAside.contains(false),
            child: _ActionChip(label: M5LvLines.scopeOne, icon: Icons.home_rounded, onTap: (g) => _openScope(false, g)),
          ),
          CardAside(
            aside: _scopeAside.contains(true),
            child: _ActionChip(label: M5LvLines.scopeMany, icon: Icons.holiday_village_rounded, onTap: (g) => _openScope(true, g)),
          ),
        ];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in _c.scopeFlip ? chips.reversed : chips)
              Flexible(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c)),
          ],
        );
      case M5LvStage.ltdb:
        // Right-aligned: the corner guide stands on the left.
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_run.ltdb.isNotEmpty) ...[
              _ActionChip(label: M5LvLines.decide, icon: Icons.fact_check_rounded, onTap: (_) => _decideTap()),
              const SizedBox(height: 8),
            ],
            _LtdbPanel(keys: _termKeys, readings: _run.ltdb, probe: _probePhase, onProbe: _probeLtdb),
          ],
        );
      case M5LvStage.line:
        return Center(
          child: _run.probed.isEmpty
              ? const SizedBox(height: 48)
              : _ActionChip(label: M5LvLines.decide, icon: Icons.fact_check_rounded, onTap: (_) => _decideTap()),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final ownDeck = _deck != M5LvDeck.none && _cards.isNotEmpty;
    final deckUp = reasonOpen || coworkerChoiceUp || (ownDeck && playing);
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final waitStage = _run.stage == M5LvStage.ask || _run.stage == M5LvStage.ltdb || _run.stage == M5LvStage.line;
    final rows = _rows;
    final notebookFit = _Notebook.fitFor(rows.length, m5LvNotebookRoom(size, pad), MediaQuery.textScalerOf(context));
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
              labels: M5LvLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && waitStage && !tableBusy && !_deckBusy && _scopePreview == null,
            hintKey: '${_run.index}/${_run.stage.name}/${_run.probes}/${_run.asked.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              // Kept above the far row of houses and their reading chips, so a
              // short phone never hides a house while the line is worked.
              if (playing && rows.isNotEmpty && _mark == null)
                Positioned(
                  key: const ValueKey('hud-notebook'),
                  right: 8,
                  top: m5LvNotebookTop(pad),
                  width: _Notebook.widthFor(notebookFit),
                  child: IgnorePointer(child: _Notebook(rows: rows, fit: notebookFit)),
                ),
              if (handsOn)
                Positioned(
                  key: ValueKey('hud-controls-${_run.index}-${_run.stage.name}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: _bottomControls(pad),
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
                                key: ValueKey('deck-${_run.index}-${_deck.name}'),
                                options: [for (final c in _cards) ChoiceOption(c.textBn, c.correct)],
                                quiet: quiet,
                                muted: _muted,
                                wrong: _deckWrong,
                                picked: _deckPicked,
                                onPick: (o, at) => unawaited(_pickCard(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  // On the verge under the street (never over a house); above
                  // the LTDB panel while it is up (no house is tapped then).
                  bottom: pad.bottom + (deckUp ? 236 : (handsOn && _run.stage == M5LvStage.ltdb ? 164 : 64)),
                  onLeft: !coworkerOnScreen || coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _scopePreview != null && _run.stage == M5LvStage.ask)
                Positioned.fill(
                  key: ValueKey('scope-preview-$_scopePreview'),
                  child: CardPreviewOverlay(
                    textBn: _scopePreview! ? M5LvLines.scopeMany : M5LvLines.scopeOne,
                    icon: _scopePreview! ? Icons.holiday_village_rounded : Icons.home_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmScope,
                    onReject: _rejectScope,
                  ),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  sound: FailSound.thud,
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
                  line: M5LvLines.intro,
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

class _PhoneBadge extends StatelessWidget {
  const _PhoneBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1B2A44),
        border: Border.all(color: SlmColors.gold300, width: 1.6),
      ),
      child: const Icon(Icons.phone_in_talk_rounded, size: 13, color: SlmColors.gold300),
    );
  }
}

/// A neighbour's reply over the house (pops in once).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: Duration(milliseconds: quiet ? 1 : 260),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.8 + 0.2 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFBF0),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.25, color: const Color(0xFF1E2430))),
      ),
    );
  }
}

/// The meter's reading by the probed house: a plain number.
class _ReadChip extends StatelessWidget {
  const _ReadChip({required this.volts, required this.quiet});
  final int volts;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: Duration(milliseconds: quiet ? 1 : 220),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xEE101A2B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6E7C90), width: 1.4),
        ),
        child: Text('$volts V', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}

/// The notebook tab's top edge on screen (under the header and round dots).
double m5LvNotebookTop(EdgeInsets pad) => pad.top + 64;

/// The height (screen px) the notebook may take on a [screen] with [pad]
/// before it would reach the far row of houses or a reading chip over one
/// (the far-row chip stands 30 design px above the roof). Follows
/// [FullSceneFrame]'s cover fit of the 360-wide scene.
double m5LvNotebookRoom(Size screen, EdgeInsets pad) {
  final w = math.max(1.0, screen.width);
  final sh = (360 * screen.height / w).clamp(560.0, 900.0);
  final scale = math.max(screen.width / 360, screen.height / sh);
  final dy = (screen.height - sh * scale) / 2;
  final geo = M5LvGeo.forScene(sh, pad.bottom * 360 / w);
  final farTop = dy + (geo.house(0).top - 30) * scale;
  return farTop - 6 - m5LvNotebookTop(pad);
}

/// The notebook tab: every reading as a plain number, in the order taken.
/// It never grows over the street: when its lines run out it goes to two
/// columns, then drops its head, and past that keeps the latest readings.
class _Notebook extends StatelessWidget {
  const _Notebook({required this.rows, required this.fit});
  final List<(String, int)> rows;

  /// How it fits its room ([fitFor]).
  final ({int lines, bool two, bool head}) fit;

  /// Padding and border.
  static const double _chrome = 5 + 6 + 2.4;
  static double _rowH(TextScaler s) => s.scale(14);

  /// The head and the gap under it.
  static double _headH(TextScaler s) => s.scale(18) + 2;

  /// How [rows] readings fit in [room] screen px: the lines per column (at
  /// least one), two columns or one, and whether the head still fits.
  static ({int lines, bool two, bool head}) fitFor(int rows, double room, TextScaler s) {
    int lines(bool head) => math.max(1, ((room - _chrome - (head ? _headH(s) : 0)) / _rowH(s)).floor());
    final withHead = lines(true);
    if (rows <= withHead) return (lines: withHead, two: false, head: true);
    if (rows <= withHead * 2) return (lines: withHead, two: true, head: true);
    return (lines: lines(false), two: true, head: false);
  }

  static double widthFor(({int lines, bool two, bool head}) fit) => fit.two ? 136 : 116;

  Widget _row(String label, int v, double h) => SizedBox(
        height: h,
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF2A2F3A))),
            ),
            Text('$v', style: const TextStyle(fontSize: 11.5, height: 1.15, fontWeight: FontWeight.w900, color: Color(0xFF1E2430))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final rowH = _rowH(scaler);
    final two = fit.two;
    final cap = two ? fit.lines * 2 : fit.lines;
    final shown = rows.length > cap ? rows.sublist(rows.length - cap) : rows;
    final perCol = two ? (shown.length + 1) ~/ 2 : shown.length;
    final cols = two ? [shown.sublist(0, perCol), shown.sublist(perCol)] : [shown];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xF2F3EEDC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8C7A55), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fit.head)
            SizedBox(
              height: _headH(scaler),
              child: Text(M5LvLines.notebook,
                  maxLines: 1, style: bangla(fontSize: 11, height: 1.3, fontWeight: FontWeight.w900, color: const Color(0xFF4A3B22))),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cols.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final (label, v) in cols[i]) _row(label, v, rowH)],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A round action button with its name (scope chips, সিদ্ধান্ত).
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final ValueChanged<Offset> onTap;

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
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: SlmColors.gold300),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The LTDB close-up: R, Y, B terminals (tap one: the red probe goes on it,
/// the black lead stays on N), each with its last reading.
class _LtdbPanel extends StatelessWidget {
  const _LtdbPanel({required this.keys, required this.readings, required this.probe, required this.onProbe});
  final List<GlobalKey> keys;
  final Map<int, int> readings;
  final int? probe;
  final ValueChanged<int> onProbe;

  static const _cols = [Color(0xFFD9443A), Color(0xFFE8C23A), Color(0xFF3A6FD9)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7E848B), Color(0xFF555B62)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3F45), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var ph = 0; ph < 3; ph++) ...[
            Semantics(
              button: true,
              label: M5LvLines.terminalLabel(ph),
              excludeSemantics: true,
              child: GestureDetector(
                key: keys[ph],
                behavior: HitTestBehavior.opaque,
                onTap: () => onProbe(ph),
                child: SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2B3036),
                          border: Border.all(color: _cols[ph], width: 3),
                        ),
                        child: probe == ph
                            ? const Icon(Icons.edit_rounded, size: 20, color: Color(0xFFE5483C))
                            : Text(_phaseNames[ph], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                      const SizedBox(height: 3),
                      Text(readings[ph] == null ? '—' : '${readings[ph]}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // N with the black lead clipped on.
          SizedBox(
            width: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2B3036), border: Border.all(color: Colors.black, width: 3)),
                  child: const Text('N', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 3),
                const Icon(Icons.cable_rounded, size: 14, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
