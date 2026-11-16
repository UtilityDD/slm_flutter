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
import 'm7_rule_question_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_rule_question_world.dart' show M7RqGeo, M7RqKind, M7RqLead, M7RqLine, M7RqLook, M7RqPlate;

// Lesson 7.1 "ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন: আপনার বাইবেল", কাজ 2
// "প্রশ্ন করার অধিকার" (pack do_7_1_b, engineType m7_rule_question; owner
// ruling M7-1 approved this redesign). An LT lane on a shutdown morning
// (m7_rule_question_world.dart). The supervisor sends work orders to the
// trainee's phone (he is heard only through the phone); each order's words
// are the same whether it is lawful or not — only the lane decides:
//
//   '<helper> আজ পোলে উঠবে।'            → the helper's ID card back
//   'পিলারটা চালু করে দাও।'              → the danger plate on the pillar door
//   'ট্রান্সফরমার চালুর জন্য রেডি করো।'   → the DTR's body and neutral earth leads
//   'বারান্দার পাশের সার্ভিস লাইনটা চালু করে দাও।' → the line by the new balcony
//   'স্টোরের কিট নিয়েই কাজ শুরু করো।'      → the helmet in the kit crate
//
// Look (free): tap a lane object for a close-up. Decide: tap 'ঠিক আছে' (a
// preview, then ✓: the crew carries the order out) or hold
// 'সুপারভাইজারকে ফোন' 1.2 s. On a call the supervisor asks 'কোন নিয়মে?';
// the pocket rulebook opens (five pages in a fixed order, today's CEA 2023
// numbers, X3: Reg 3 · Reg 20 · Reg 43 ও 50 · Reg 60 থেকে 63 ও 71 · the
// company-duty page); swipe its pages and drag the open page onto the phone.
//
// Right page on an unlawful order → the supervisor agrees, ◆ on the table →
// 'কেন প্রশ্ন করলেন?' → এগিয়ে যান → the lawful fix plays. Wrong page = slip
// (R28; the card names the right page; page again). A call on a lawful order
// = slip (needless stop, R29; the order then goes ahead). 'ঠিক আছে' on an
// unlawful order = slip (R28; the act plays). The first right 'ঠিক আছে' of a
// play also asks 'কেন মেনে নিলেন?'. 6 orders a play (all five kinds, one
// repeated; its second version is dealt on its own, so the first never gives
// it away), 2–4 unlawful.
//
// Each order is its own moment: a new order starts with the lane back in its
// shutdown state (the helper at the pole's foot, the crew at the van, the
// pillar and the service line dead, the DTR tagged), so no charge is ever
// shown with a man up and no man climbs a charged lane (M5-1 / X7). The
// DTR order only readies it (the tag comes off, the AB stays open): nothing
// is charged in 7.1, and a broken earth stays a slip (M7-6; charging it
// would be deadly, M6-1).
//
// No deadly in lesson 7.1 (M7-6): every mistake here is a slip; Reg 3 on a
// shutdown (non-live) job is a legal breach, never "allowed" (M7-5). Three
// slips strike out.
//
// The careless coworker once a play, on a dealt order (lawful or not alike):
// the first touch on either decision control waits for him (holdForCoworker).
// Beat 1: lesson 7.1 myth 1 word for word; beat 2: the guide asks, refuse /
// listen (listening = slip, X2/B1). Then the order still waits for the
// player's own decision.
//
// Gesture hands (how, never what): a sweep over the five lane objects and
// both decision controls alike; a tap on a close-up's close button; on the
// rulebook a swipe left, a swipe right, then a short drag from the booklet
// toward the phone (the only drop target, so it shows how, not which page).

// ============================================================================
// Content
// ============================================================================

/// The rulebook's pages, in their fixed order.
enum M7RqPage { reg3, reg20, reg43, reg60, rights }

/// The page that backs a question about [k].
M7RqPage m7RqPageFor(M7RqKind k) => switch (k) {
      M7RqKind.helper => M7RqPage.reg3,
      M7RqKind.pillar => M7RqPage.reg20,
      M7RqKind.earth => M7RqPage.reg43,
      M7RqKind.balcony => M7RqPage.reg60,
      M7RqKind.kit => M7RqPage.rights,
    };

/// Where the order runs: the phone text arriving (voice-locked), deciding,
/// the supervisor asking 'কোন নিয়মে?', the rulebook open, settled.
enum M7RqStage { arriving, deciding, asking, paging, settled }

abstract final class M7RuleQuestionLines {
  static const title = 'প্রশ্ন করার অধিকার';

  // DRAFT wording — owner (M6-12 / M7-10).
  static const intro = 'আজ সুপারভাইজার ফোনে কাজের নির্দেশ দেবেন। নিয়মে না মিললে রুলবুক দেখিয়ে প্রশ্ন করুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askListen = 'ফোনে নির্দেশ আসছে — শুনুন।';
  static const askLook = 'জায়গাটা দেখে নিন — তারপর মানুন, নয়তো ফোনে প্রশ্ন করুন।';
  static const askPage = 'রুলবুকের ঠিক পাতাটা ফোনে দেখান।';
  static const askClose = 'দেখা হলে ছবিটা বন্ধ করুন।';
  static List<String> get tasks => [askListen, askLook, askPage, askClose];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The phone and the controls (a worker's own words).
  static const phoneHead = 'সুপারভাইজার';
  static const ok = 'ঠিক আছে';
  static const call = 'সুপারভাইজারকে ফোন';
  static const holdHint = 'চেপে ধরুন';
  static const close = 'বন্ধ';
  static const sceneLabel = 'লাইনের পাশের রাস্তা';
  static const bookLabel = 'রুলবুক';

  /// The helpers' names (today's, a second one, the fit lineman after a
  /// question).
  static const names = ['ছোটন', 'বাপি', 'রতন'];

  // The supervisor (heard only through the phone; device voice until
  // recorded). DRAFT wording — owner.
  static String order(M7RqKind k, {int person = 0}) => switch (k) {
        M7RqKind.helper => '${names[person]} আজ পোলে উঠবে।',
        M7RqKind.pillar => 'পিলারটা চালু করে দাও।',
        M7RqKind.earth => 'ট্রান্সফরমার চালুর জন্য রেডি করো।',
        M7RqKind.balcony => 'বারান্দার পাশের সার্ভিস লাইনটা চালু করে দাও।',
        M7RqKind.kit => 'স্টোরের কিট নিয়েই কাজ শুরু করো।',
      };
  static const askWhich = 'কোন নিয়মে?';
  static const agree = 'ঠিক, আগে ওটা ঠিক করো।';
  static const notThere = 'এতে তো এ কথা নেই।';
  static const allFine = 'সব তো ঠিক আছে, দেখেছ?';

  /// Every line the supervisor speaks (to record in the rival's voice, as
  /// kit_check's caller; until then the device voice, a little lower).
  static List<String> get supervisorLines => [
        for (final k in M7RqKind.values)
          if (k == M7RqKind.helper) ...[order(k), order(k, person: 1)] else order(k),
        askWhich,
        agree,
        notThere,
        allFine,
      ];

  // The close-ups' names (what is being looked at, never its state).
  static String closeTitle(M7RqKind k) => switch (k) {
        M7RqKind.helper => 'আইডি কার্ড · পিছন',
        M7RqKind.pillar => 'ফিডার পিলার',
        M7RqKind.earth => 'ট্রান্সফরমারের আর্থ লিড',
        M7RqKind.balcony => 'বারান্দার পাশের সার্ভিস লাইন',
        M7RqKind.kit => 'ভ্যানের কিট',
      };
  static const cardName = 'নাম';
  static const cardTraining = 'প্রশিক্ষণ';
  static const cardAuth = 'অনুমোদন';
  static const trainingDone = 'সম্পূর্ণ';
  static const trainingOn = 'চলছে';

  // The rulebook: the lesson's own words (7.1 section 3, pro tips 2 and 4),
  // today's CEA 2023 numbers (X3), English digits.
  static String pageTitle(M7RqPage p) => switch (p) {
        M7RqPage.reg3 => 'রেগুলেশন 3 · উপযুক্ত ব্যক্তি',
        M7RqPage.reg20 => 'রেগুলেশন 20 · বিপজ্জনক নোটিশ',
        M7RqPage.reg43 => 'রেগুলেশন 43 ও 50 · আর্থিং',
        M7RqPage.reg60 => 'রেগুলেশন 60 থেকে 63 ও 71 · ক্লিয়ারেন্স',
        M7RqPage.rights => 'নিজের অধিকার · টুলস, PPE, নিরাপদ পরিবেশ',
      };
  static String pageBody(M7RqPage p) => switch (p) {
        M7RqPage.reg3 => "আইন অনুযায়ী, শুধুমাত্র 'উপযুক্ত' বা প্রশিক্ষিত এবং অনুমোদিত ব্যক্তিই বিদ্যুৎ লাইনে কাজ করতে পারবেন।",
        M7RqPage.reg20 => "প্রতিটি বিদ্যুৎ ইনস্টলেশনের (যেমন ট্রান্সফরমার, ফিডার পিলার) গায়ে একটি বিপদ চিহ্ন বা 'ডেঞ্জার প্লেট' লাগানো বাধ্যতামূলক।",
        M7RqPage.reg43 => 'সমস্ত যন্ত্রপাতির ধাতব বডি এবং সিস্টেমের নিউট্রালকে সঠিকভাবে আর্থিং করা বাধ্যতামূলক।',
        M7RqPage.reg60 => 'বিভিন্ন ভোল্টেজের লাইনের জন্য মাটি, বাড়ি এবং অন্যান্য লাইনের থেকে ন্যূনতম ক্লিয়ারেন্সের একটি নির্দিষ্ট চার্ট দেওয়া আছে।',
        M7RqPage.rights => 'আইন অনুযায়ী, আপনার কোম্পানি আপনাকে সঠিক টুলস, PPE এবং নিরাপদ কাজের পরিবেশ দিতে বাধ্য। আপনার প্রশ্ন করার অধিকার আছে।',
      };
  static String pageShort(M7RqPage p) => switch (p) {
        M7RqPage.reg3 => 'রেগুলেশন 3',
        M7RqPage.reg20 => 'রেগুলেশন 20',
        M7RqPage.reg43 => 'রেগুলেশন 43 ও 50',
        M7RqPage.reg60 => 'রেগুলেশন 60 থেকে 63 ও 71',
        M7RqPage.rights => 'নিজের অধিকার',
      };
  static String pageCount(int i) => enDigits('${i + 1} / ${M7RqPage.values.length}');

  // The reasons. 'কেন প্রশ্ন করলেন?' after a right question; 'কেন মেনে
  // নিলেন?' after the first right 'ঠিক আছে'. The right ones fit what this
  // order had; the wrong ones are the lesson's myths and field excuses.
  static const whyAsk = 'কেন প্রশ্ন করলেন?';
  static const whyOk = 'কেন মেনে নিলেন?';
  static const whyAskRight = <M7RqKind, List<String>>{
    M7RqKind.helper: ['রেগুলেশন 3: শুধু প্রশিক্ষিত ও অনুমোদিত লোকই লাইনে', 'প্রশিক্ষণ বা অনুমোদন ছাড়া লাইনে কাজ আইনে মানা'],
    M7RqKind.pillar: ['রেগুলেশন 20: পিলারের গায়ে ডেঞ্জার প্লেট বাধ্যতামূলক', 'ডেঞ্জার প্লেট ছাড়া পিলার চালু করা নিয়মভঙ্গ'],
    M7RqKind.earth: ['রেগুলেশন 43 ও 50: বডি আর নিউট্রাল আর্থিং বাধ্যতামূলক', 'আর্থ লিড ছেঁড়া রেখে ট্রান্সফরমার চালু নিয়মে মানা'],
    M7RqKind.balcony: ['রেগুলেশন 60 থেকে 63 ও 71: বাড়ি থেকে ক্লিয়ারেন্স', 'বারান্দায় ঠেকে থাকা লাইন চালু করা নিয়মভঙ্গ'],
    M7RqKind.kit: ['আইনে কোম্পানি সঠিক টুলস আর PPE দিতে বাধ্য', 'হেলমেট ছাড়া কাজ নয় — PPE পাওয়া আমার অধিকার'],
  };
  static const whyOkRight = <M7RqKind, List<String>>{
    M7RqKind.helper: ['কার্ডে প্রশিক্ষণ সম্পূর্ণ, অনুমোদনে সই-সিল আছে', 'প্রশিক্ষিত ও অনুমোদিত লোক — রেগুলেশন 3 মানা'],
    M7RqKind.pillar: ['পিলারের দরজায় ডেঞ্জার প্লেট ঠিকমতো লাগানো', 'ডেঞ্জার প্লেট আছে — রেগুলেশন 20 মানা হয়েছে'],
    M7RqKind.earth: ['বডি আর নিউট্রাল দুটো আর্থ লিডই লাগানো আছে', 'আর্থিং ঠিক আছে — রেগুলেশন 43 ও 50 মানা হয়েছে'],
    M7RqKind.balcony: ['সার্ভিস লাইন বারান্দা থেকে দূরে, ঠেকে নেই', 'বারান্দা থেকে ক্লিয়ারেন্স আছে — নিয়ম মানা'],
    M7RqKind.kit: ['ক্রেটে হেলমেট আছে — কোম্পানি PPE দিয়েছে', 'কোম্পানি হেলমেট দিয়েছে, কাজ শুরু করা যায়'],
  };
  static const myths = [
    'এসব আইনকানুন শুধু কাগজে, মাঠে কেউ মানে না',
    'আইন তো বড় ইঞ্জিনিয়ারদের জন্য, আমাদের নয়',
    'সুপারভাইজার বলেছেন, তাই আর দেখার দরকার নেই',
    'আইন না জানলে দোষ নেই, অজুহাত দেওয়া যায়',
    'তাড়াতাড়ি কাজ সারাই আসল, নিয়ম পরে দেখা যাবে',
    'একবার নিয়ম ভাঙলে কিছু হয় না, সবাই ভাঙে',
    'প্রশ্ন করলে ঝামেলা বাড়ে, চুপচাপ থাকাই ভালো',
  ];
  static List<String> get allWhyRight => [
        for (final l in whyAskRight.values) ...l,
        for (final l in whyOkRight.values) ...l,
      ];

  // The careless coworker: lesson 7.1 myth 1 word for word (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'এসব আইনকানুন তো শুধু কাগজের জন্য, মাঠে কেউ মানে না।',
    exitLine: coworkerExit,
    right: [
      'তদন্তে CEA নিয়মই মাপকাঠি — ভাঙলে জরিমানা, জেল',
      'অসুরক্ষিত মনে হলে প্রশ্ন করার অধিকার আমার আছে',
      'না, এই নিয়ম মানাতেই আমার আর সবার সুরক্ষা',
    ],
    wrong: [
      'ঠিক, সুপারভাইজার যা বলছে চুপচাপ করে ফেলি',
      'কাগজে কী আসে যায়, নিয়ম ছেড়ে কাজটা সারি',
      'হ্যাঁ, মাঠে কেউ মানে না, আমিও মানব না',
      'ঠিক আছে, আজ নিয়মের বইটা পকেটেই থাকুক',
      'আচ্ছা, প্রশ্ন না করে যা বলছে তাই করি',
    ],
    asks: ['ওঁকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! দুর্ঘটনার তদন্তে CEA নিয়মই মাপকাঠি।';

  static const allSet = 'যেখানে নিয়ম ভাঙছিল, রুলবুক দেখিয়ে প্রশ্ন করেছেন — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — নির্দেশ শুনুন, জায়গাটা দেখুন, তারপর মানুন বা প্রশ্ন করুন।';

  // "আজ যা ধরলেন": each question asked and its page.
  static String caughtQuestion(M7RqKind k) => '${_what(k)} → ${pageShort(m7RqPageFor(k))}';
  static String _what(M7RqKind k) => switch (k) {
        M7RqKind.helper => 'হেল্পারের কার্ড অসম্পূর্ণ',
        M7RqKind.pillar => 'পিলারে ডেঞ্জার প্লেট নেই',
        M7RqKind.earth => 'আর্থ লিড খোলা',
        M7RqKind.balcony => 'লাইন বারান্দায় ঠেকে',
        M7RqKind.kit => 'কিটে হেলমেট নেই',
      };
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new line (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The supervisor's lines, to record in the rival's voice (kit_check's
  /// caller precedent; the owner may choose another voice).
  static List<String> get newSupervisorLines => supervisorLines;

  /// The guide's new spoken lines, to record; until then the device voice.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        whyAsk,
        whyOk,
        ...coworker.asks,
        callHeld,
        allSet,
        quick,
        fail,
        for (final m in M7RuleQuestionMistakes.all) m.textBn,
      }.toList();
}

abstract final class M7RuleQuestionMistakes {
  static const _dir = 'assets/game/art/m7_rule_question';
  static const _k = '7.1/m7_rule_question';

  // DRAFT wording — owner (M6-12). All slips (M7-6: no deadly in 7.1).
  static const obeyHelper = DoMistake(
    key: '$_k/obey-helper',
    textBn: 'প্রশিক্ষণ বা অনুমোদন বাকি এমন লোককে লাইনে তোলা আইনভঙ্গ (রেগুলেশন 3) — শাটডাউন লাইনেও। কার্ড দেখে প্রশ্ন করা উচিত ছিল।',
    art: '$_dir/helper.svg',
    lessonPoint: 2,
  );
  static const obeyPillar = DoMistake(
    key: '$_k/obey-pillar',
    textBn: 'ডেঞ্জার প্লেট ছাড়া পিলার চালু করা নিয়মভঙ্গ (রেগুলেশন 20)। আগে প্লেট লাগাতে বলে প্রশ্ন করুন।',
    art: '$_dir/pillar.svg',
    lessonPoint: 2,
  );
  static const obeyEarth = DoMistake(
    key: '$_k/obey-earth',
    textBn: 'আর্থ লিড ছেঁড়া বা খোলা রেখে ট্রান্সফরমার চালুর জন্য রেডি করা নিয়মভঙ্গ (রেগুলেশন 43 ও 50) — এভাবে চালু করলে প্রাণঘাতী। আগে লিড জোড়া চাই।',
    art: '$_dir/earth.svg',
    lessonPoint: 2,
  );
  static const obeyBalcony = DoMistake(
    key: '$_k/obey-balcony',
    textBn: 'বারান্দায় ঠেকে থাকা লাইন চালু করা নিয়মভঙ্গ — বাড়ি থেকে ন্যূনতম ক্লিয়ারেন্স চাই (রেগুলেশন 60 থেকে 63 ও 71)। লাইন OFF রেখে প্রশ্ন করুন।',
    art: '$_dir/balcony.svg',
    lessonPoint: 2,
  );
  static const obeyKit = DoMistake(
    key: '$_k/obey-kit',
    textBn: 'হেলমেট ছাড়া কাজ শুরু নয় — আইন অনুযায়ী কোম্পানি সঠিক টুলস আর PPE দিতে বাধ্য। প্রশ্ন করে হেলমেট চেয়ে নিন।',
    art: '$_dir/kit.svg',
    lessonPoint: 1,
  );
  static const pageHelper = DoMistake(
    key: '$_k/page-helper',
    textBn: "এ প্রশ্নের পাতা 'রেগুলেশন 3 · উপযুক্ত ব্যক্তি' — শুধু প্রশিক্ষিত ও অনুমোদিত লোকই লাইনে। ঠিক পাতাটা দেখান।",
    art: '$_dir/rulebook.svg',
    lessonPoint: 2,
  );
  static const pagePillar = DoMistake(
    key: '$_k/page-pillar',
    textBn: "এ প্রশ্নের পাতা 'রেগুলেশন 20 · বিপজ্জনক নোটিশ' — পিলারে ডেঞ্জার প্লেট বাধ্যতামূলক। ঠিক পাতাটা দেখান।",
    art: '$_dir/rulebook.svg',
    lessonPoint: 2,
  );
  static const pageEarth = DoMistake(
    key: '$_k/page-earth',
    textBn: "এ প্রশ্নের পাতা 'রেগুলেশন 43 ও 50 · আর্থিং' — বডি আর নিউট্রালের আর্থিং বাধ্যতামূলক। ঠিক পাতাটা দেখান।",
    art: '$_dir/rulebook.svg',
    lessonPoint: 2,
  );
  static const pageBalcony = DoMistake(
    key: '$_k/page-balcony',
    textBn: "এ প্রশ্নের পাতা 'রেগুলেশন 60 থেকে 63 ও 71 · ক্লিয়ারেন্স' — বাড়ি থেকে ন্যূনতম দূরত্ব। ঠিক পাতাটা দেখান।",
    art: '$_dir/rulebook.svg',
    lessonPoint: 2,
  );
  static const pageKit = DoMistake(
    key: '$_k/page-kit',
    textBn: "এ প্রশ্নের পাতা 'নিজের অধিকার' — কোম্পানি সঠিক টুলস আর PPE দিতে বাধ্য। ঠিক পাতাটা দেখান।",
    art: '$_dir/rulebook.svg',
    lessonPoint: 1,
  );
  static const needless = DoMistake(
    key: '$_k/needless-call',
    textBn: 'এই নির্দেশে নিয়মের বাইরে কিছু ছিল না — অকারণে কাজ থামালেন। যে জিনিসের নির্দেশ, সেটা দেখে তবেই প্রশ্ন।',
    art: '$_dir/needless.svg',
    lessonPoint: 2,
  );
  // Lesson 7.1 myth 1 and its reality (not a numbered point).
  static const listen = DoMistake(
    key: '$_k/listen-myth',
    textBn: 'আইন শুধু কাগজে নয় — বড় দুর্ঘটনার তদন্তে CEA নিয়মই স্ট্যান্ডার্ড; লঙ্ঘন প্রমাণ হলে জরিমানা থেকে জেল পর্যন্ত হতে পারে।',
    art: '$_dir/myth.svg',
  );

  static DoMistake obey(M7RqKind k) => switch (k) {
        M7RqKind.helper => obeyHelper,
        M7RqKind.pillar => obeyPillar,
        M7RqKind.earth => obeyEarth,
        M7RqKind.balcony => obeyBalcony,
        M7RqKind.kit => obeyKit,
      };

  static DoMistake wrongPage(M7RqKind k) => switch (k) {
        M7RqKind.helper => pageHelper,
        M7RqKind.pillar => pagePillar,
        M7RqKind.earth => pageEarth,
        M7RqKind.balcony => pageBalcony,
        M7RqKind.kit => pageKit,
      };

  static const List<DoMistake> all = [
    obeyHelper,
    obeyPillar,
    obeyEarth,
    obeyBalcony,
    obeyKit,
    pageHelper,
    pagePillar,
    pageEarth,
    pageBalcony,
    pageKit,
    needless,
    listen,
  ];
}

/// One work order and the lane's answer to it.
@immutable
class M7RqOrder {
  const M7RqOrder({required this.kind, required this.lawful, this.variant = 0, this.alt = false, this.person = 0});

  final M7RqKind kind;

  /// The lane fits the order (nothing to question).
  final bool lawful;

  /// Which breach (unlawful only): helper 0 training on / 1 authorization
  /// blank; pillar 0 bare door / 1 plate on the ground; earth 0 cut / 1
  /// hanging.
  final int variant;

  /// Earth: the bad lead is the body earth (else the neutral).
  final bool alt;

  /// Helper: which man (0 today's helper, 1 a second helper).
  final int person;

  String get textBn => M7RuleQuestionLines.order(kind, person: person);

  /// The helper's card: training done, authorization signed and stamped.
  bool get trainingDone => kind != M7RqKind.helper || lawful || variant != 0;
  bool get authSigned => kind != M7RqKind.helper || lawful || variant != 1;
}

@immutable
class M7RqDeal {
  const M7RqDeal({
    required this.orders,
    required this.coworkerAt,
    this.plateRight = false,
    this.neutralLeft = true,
    this.crate = 0,
  });

  /// Six orders: every kind, one of them twice (each version dealt on its
  /// own).
  final List<M7RqOrder> orders;

  /// The order the coworker comes in on (its first decision touch).
  final int coworkerAt;

  final bool plateRight;
  final bool neutralLeft;
  final int crate;

  int get unlawful => orders.where((o) => !o.lawful).length;
}

const kM7RqOrders = 6;

M7RqDeal m7RqDeal(math.Random rng) {
  final repeat = M7RqKind.values[rng.nextInt(M7RqKind.values.length)];
  // The order of the six (the repeated kind never twice in a row).
  late List<M7RqKind> seq;
  do {
    seq = [...M7RqKind.values, repeat]..shuffle(rng);
  } while (_adjacent(seq, repeat));
  // 2–4 unlawful. The repeated kind's two versions are dealt each on its own
  // (the first never tells the second; §4 no giveaways); re-dealt until the
  // play has 2–4 breaches.
  final others = [for (final k in M7RqKind.values) if (k != repeat) k];
  late Set<M7RqKind> bad;
  late List<bool> repeatLawful;
  int breaches() => bad.length + repeatLawful.where((l) => !l).length;
  do {
    others.shuffle(rng);
    bad = others.take(rng.nextInt(5)).toSet();
    repeatLawful = [rng.nextBool(), rng.nextBool()];
  } while (breaches() < 2 || breaches() > 4);
  final seen = <M7RqKind, int>{};
  final orders = <M7RqOrder>[];
  for (final k in seq) {
    final n = seen[k] = (seen[k] ?? -1) + 1;
    final lawful = k == repeat ? repeatLawful[n] : !bad.contains(k);
    orders.add(M7RqOrder(
      kind: k,
      lawful: lawful,
      variant: rng.nextInt(2),
      alt: rng.nextBool(),
      person: k == M7RqKind.helper ? n : 0,
    ));
  }
  return M7RqDeal(
    orders: orders,
    coworkerAt: rng.nextInt(kM7RqOrders),
    plateRight: rng.nextBool(),
    neutralLeft: rng.nextBool(),
    crate: rng.nextInt(3),
  );
}

bool _adjacent(List<M7RqKind> seq, M7RqKind k) {
  for (var i = 1; i < seq.length; i++) {
    if (seq[i] == k && seq[i - 1] == k) return true;
  }
  return false;
}

/// The play state (pure logic).
class M7RqRun {
  M7RqRun(this.deal) {
    var look = M7RqLook(plateRight: deal.plateRight, neutralLeft: deal.neutralLeft, crate: deal.crate);
    // Each object shows the version of its first order from the start.
    final done = <M7RqKind>{};
    for (final o in deal.orders) {
      if (done.add(o.kind)) look = _apply(look, o);
    }
    this.look = look;
    for (final o in deal.orders) {
      if (o.kind == M7RqKind.helper) {
        _helper = o;
        break;
      }
    }
    _startOrder();
  }

  final M7RqDeal deal;

  late M7RqLook look;
  int index = 0;
  int slips = 0;
  int orderSlips = 0;
  M7RqStage stage = M7RqStage.arriving;
  final List<String> caught = [];

  /// The order is over (its reason, card or move-on comes next).
  var roundDone = false;

  /// This order was questioned with the right page (the fix plays after the
  /// reason).
  var questioned = false;

  /// The first right 'ঠিক আছে' of the play asks 'কেন মেনে নিলেন?'.
  var _okAsked = false;
  var okReason = false;

  /// The helper whose card shows now (null after a fit man came).
  M7RqOrder? _helper;
  var _fitMan = false;

  M7RqOrder get order => deal.orders[index.clamp(0, kM7RqOrders - 1)];
  bool get done => index >= kM7RqOrders;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => orderSlips == 0;

  /// The helper's card now: his name, training done, authorization signed.
  ({String name, bool training, bool signed}) get card {
    final h = _helper;
    if (_fitMan || h == null) return (name: M7RuleQuestionLines.names[2], training: true, signed: true);
    return (name: M7RuleQuestionLines.names[h.person], training: h.trainingDone, signed: h.authSigned);
  }

  static M7RqLook _apply(M7RqLook l, M7RqOrder o) => switch (o.kind) {
        M7RqKind.helper => l.copyWith(helperPerson: o.person, helperUp: false),
        M7RqKind.pillar => l.copyWith(plate: o.lawful ? M7RqPlate.fixed : (o.variant == 0 ? M7RqPlate.bare : M7RqPlate.ground), pillarOn: false),
        M7RqKind.earth => l.copyWith(lead: o.lawful ? M7RqLead.ok : (o.variant == 0 ? M7RqLead.cut : M7RqLead.hanging), badLeadIsBody: o.alt, dtrReady: false),
        M7RqKind.balcony => l.copyWith(line: o.lawful ? M7RqLine.clear : M7RqLine.resting, lineLive: false),
        M7RqKind.kit => l.copyWith(helmetIn: o.lawful, crewWorking: false),
      };

  void _startOrder() {
    stage = M7RqStage.arriving;
    roundDone = false;
    questioned = false;
    okReason = false;
    orderSlips = 0;
    // Each order is its own moment: the lane is back to its shutdown state
    // before the next order comes (the man down from the pole, the crew at
    // the van, the pillar and the service line dead, the DTR's tag on). So
    // no charge is ever shown with a man up, and no man climbs a charged
    // lane (M5-1 / X7). The fixes (a fit man, the plate, the lead, the
    // clearance, the helmet) stay.
    look = look.copyWith(helperUp: false, crewWorking: false, pillarOn: false, lineLive: false, dtrReady: false);
    final o = order;
    // The second order of a kind: its object now shows that order's version.
    if (deal.orders.take(index).any((p) => p.kind == o.kind)) {
      look = _apply(look, o);
      if (o.kind == M7RqKind.helper) {
        _helper = o;
        _fitMan = false;
      }
    }
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    orderSlips++;
    return m;
  }

  /// The order's text has been heard (the controls wake).
  void read() {
    if (!done && stage == M7RqStage.arriving) stage = M7RqStage.deciding;
  }

  bool get deciding => !done && !roundDone && stage == M7RqStage.deciding;

  /// The crew carries the order out. The DTR is only readied (the tag off,
  /// the AB still open): nothing is charged in 7.1 (M7-6 / M6-1).
  void _act(M7RqKind k) {
    look = switch (k) {
      M7RqKind.helper => look.copyWith(helperUp: true),
      M7RqKind.pillar => look.copyWith(pillarOn: true),
      M7RqKind.earth => look.copyWith(dtrReady: true),
      M7RqKind.balcony => look.copyWith(lineLive: true),
      M7RqKind.kit => look.copyWith(crewWorking: true),
    };
  }

  /// 'ঠিক আছে': the crew carries the order out. Unlawful = slip (R28).
  DoMistake? obey() {
    if (!deciding) return null;
    final o = order;
    roundDone = true;
    stage = M7RqStage.settled;
    _act(o.kind);
    if (!o.lawful) return _slip(M7RuleQuestionMistakes.obey(o.kind));
    if (!_okAsked) {
      _okAsked = true;
      okReason = true;
    }
    return null;
  }

  /// The call held through: the supervisor asks which rule.
  bool call() {
    if (!deciding) return false;
    stage = M7RqStage.asking;
    return true;
  }

  /// The rulebook opens.
  void openBook() {
    if (!done && stage == M7RqStage.asking) stage = M7RqStage.paging;
  }

  /// The open page shown on the phone. A lawful order: a needless stop (R29)
  /// and the order goes ahead. The right page: questioned. A wrong page: a
  /// slip, the book stays open.
  DoMistake? show(M7RqPage p) {
    if (done || roundDone || stage != M7RqStage.paging) return null;
    final o = order;
    if (o.lawful) {
      roundDone = true;
      stage = M7RqStage.settled;
      _act(o.kind);
      return _slip(M7RuleQuestionMistakes.needless);
    }
    if (p != m7RqPageFor(o.kind)) return _slip(M7RuleQuestionMistakes.wrongPage(o.kind));
    roundDone = true;
    questioned = true;
    stage = M7RqStage.settled;
    _tag(M7RuleQuestionLines.caughtQuestion(o.kind));
    return null;
  }

  /// The lawful fix plays (after the reason): a fit man, the plate fixed, the
  /// lead joined, the line kept off, a helmet brought.
  void applyFix() {
    if (!questioned) return;
    final k = order.kind;
    look = switch (k) {
      M7RqKind.helper => look.copyWith(helperPerson: 2, helperUp: true),
      M7RqKind.pillar => look.copyWith(plate: M7RqPlate.fixed),
      M7RqKind.earth => look.copyWith(lead: M7RqLead.ok),
      M7RqKind.balcony => look.copyWith(line: M7RqLine.clear),
      M7RqKind.kit => look.copyWith(helmetIn: true),
    };
    if (k == M7RqKind.helper) _fitMan = true;
  }

  /// Listened to the coworker (a slip; the order still waits).
  DoMistake pushSlip() => _slip(M7RuleQuestionMistakes.listen);

  void next() {
    index++;
    if (!done) _startOrder();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, a builder's
/// estimate; owner may tune). ms, ~1500 per human action:
///   per order: the phone text heard ≈ 3000, two close-ups ≈ 4500
///   lawful: 'ঠিক আছে' + ✓ ≈ 2500 (×3 ≈ 30000, + its one reason ≈ 8000)
///   unlawful: hold 1200 + 'কোন নিয়মে?' ≈ 1500 + a page or two and the
///     drag ≈ 4500 + the reason ≈ 8200 (×3 ≈ 70000 incl. looking)
///   + the coworker ≈ 9600                                    ≈ 113000
/// 85 % ≈ 96000 → 95 s.
const m7RuleQuestionQuickMs = 95000;

@immutable
class M7RuleQuestionPack {
  const M7RuleQuestionPack({required this.id, required this.titleBn, this.quickMs = m7RuleQuestionQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7RuleQuestionPack> m7RuleQuestionPacks = {
  'do_7_1_b': M7RuleQuestionPack(id: 'do_7_1_b', titleBn: M7RuleQuestionLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7RuleQuestionProbe {
  static M7RqRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7RuleQuestionPage extends StatefulWidget {
  const M7RuleQuestionPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7RuleQuestionPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7RuleQuestionPage> createState() => _M7RuleQuestionPageState();
}

class _M7RuleQuestionPageState extends State<M7RuleQuestionPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RqRunPage(
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

class _RqRunPage extends ConsumerStatefulWidget {
  const _RqRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7RuleQuestionPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RqRunPage> createState() => _RqRunPageState();
}

enum _BookMode { flip, carry }

class _RqRunPageState extends ConsumerState<_RqRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7RqRun _run;
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

  /// The phone: the supervisor's last words (the order, then his replies).
  final List<String> _phone = [];
  var _phoneTalking = false;
  int _phoneTok = 0;

  /// A close-up open (the object), the 'ঠিক আছে' preview open.
  M7RqKind? _closeup;
  var _okPreview = false;
  var _okAside = false;

  /// The rulebook: the open page, and a drag on it.
  int _page = 0;
  Offset? _bookFrom;
  Offset _bookAt = Offset.zero;
  _BookMode? _bookMode;

  /// The call button's hold.
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _callHeld();
    });

  /// A flash over the object as its fix plays.
  M7RqKind? _flashKind;
  int _flashN = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M7RqKind, GlobalKey> _objKeys = {for (final k in M7RqKind.values) k: GlobalKey()};
  final _okKey = GlobalKey();
  final _callKey = GlobalKey();
  final _closeKey = GlobalKey();
  final _bookKey = GlobalKey();
  final _phoneKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M7RqGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7RqRun(m7RqDeal(widget.rng));
    M7RuleQuestionProbe.run = _run;
    MascotTalk.active.addListener(_phoneLips);
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    MascotTalk.active.removeListener(_phoneLips);
    disposeCoworker();
    _hold.dispose();
    _chain++;
    if (identical(M7RuleQuestionProbe.run, _run)) M7RuleQuestionProbe.run = null;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  /// The supervisor speaks by the device voice, which would move the guide's
  /// mouth: keep the guide's lips still while he talks.
  void _phoneLips() {
    if (_phoneTalking && MascotTalk.active.value) scheduleMicrotask(MascotTalk.reset);
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
    _phoneTalking = false;
    unawaited(MascotSpeechLibrary.stop());
  }

  /// The supervisor on the phone: his words on its screen and in the rival's
  /// voice (kit_check's caller precedent; the device voice a little lower
  /// until recorded); the guide's bubble clears meanwhile. Input waits for
  /// him (voice-locked).
  Future<void> _phoneSay(String line, {bool fresh = false}) async {
    _hush();
    final tok = ++_phoneTok;
    final guide = ref.read(guideDirectorProvider.notifier);
    guide.softClearLine();
    guide.react(GuideMood.idle);
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    setState(() {
      if (fresh) _phone.clear();
      _phone.add(line);
      while (_phone.length > 2) {
        _phone.removeAt(0);
      }
      _phoneTalking = true;
    });
    await MascotSpeechLibrary.speak(line, muted: _muted, pitch: 0.82, rival: true);
    if (mounted && tok == _phoneTok) setState(() => _phoneTalking = false);
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  M7RqOrder get _order => _run.order;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_phoneTalking && !struckOut;

  /// Deciding: the lane can be looked at and the two controls work.
  bool get _canDecide => _canPlay && _run.deciding && _closeup == null && !_okPreview;

  String get _task {
    if (_closeup != null) return M7RuleQuestionLines.askClose;
    return switch (_run.stage) {
      M7RqStage.arriving => M7RuleQuestionLines.askListen,
      M7RqStage.paging || M7RqStage.asking => M7RuleQuestionLines.askPage,
      _ => M7RuleQuestionLines.askLook,
    };
  }

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  Future<void> _start() async {
    _clock.start();
    unawaited(_startOrder());
  }

  /// A new order slides in on the phone; the controls wake once it is heard.
  Future<void> _startOrder() async {
    final idx = _run.index;
    setState(() {
      _closeup = null;
      _okPreview = false;
      _okAside = false;
      _page = 0;
      _bookFrom = null;
      _bookMode = null;
    });
    HapticFeedback.lightImpact();
    await _phoneSay(_order.textBn, fresh: true);
    if (!mounted || _ended || _run.index != idx) return;
    setState(_run.read);
    unawaited(_sayChain([M7RuleQuestionLines.askLook]));
  }

  /// The coworker's order: the first touch on a decision control waits for
  /// him (he comes in now).
  bool _waitForHim() {
    if (_run.index != _run.deal.coworkerAt || coworkerDone) return false;
    if (!coworkerDue) scheduleCoworker();
    return holdForCoworker();
  }

  // --- looking ---------------------------------------------------------------------
  void _tapScene(Offset p) {
    if (!_canDecide) return;
    final geo = _geoNow;
    final k = geo?.kindAt(p);
    if (k == null) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _closeup = k);
    _stepDone();
  }

  void _closeCloseup() {
    if (_closeup == null) return;
    _tick();
    setState(() => _closeup = null);
    _stepDone();
  }

  // --- 'ঠিক আছে' -----------------------------------------------------------------------
  void _openOk() {
    if (!_canDecide) return;
    if (_waitForHim()) return;
    _tick();
    setState(() => _okPreview = true);
  }

  void _rejectOk() {
    if (!_okPreview) return;
    setState(() {
      _okPreview = false;
      _okAside = true;
    });
  }

  void _confirmOk() {
    if (!_okPreview) return;
    setState(() {
      _okPreview = false;
      _okAside = false;
    });
    if (!_canDecide) return;
    if (_waitForHim()) return;
    final idx = _run.index;
    final m = _run.obey();
    _stepDone();
    final origin = _origin(_okKey);
    if (m != null) {
      // The act plays, then the card.
      _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 700), () {
        if (!mounted || _ended || _run.index != idx) return;
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(m));
      }));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    if (_run.okReason) {
      _hush();
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final k = _order.kind;
      unawaited(askReason(
        deal: () => dealChoices(M7RuleQuestionLines.whyOkRight[k]!, M7RuleQuestionLines.myths, widget.rng),
        question: M7RuleQuestionLines.whyOk,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1200), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the call ---------------------------------------------------------------------------
  void _holdDown() {
    if (!_canDecide) return;
    if (_waitForHim()) return;
    HapticFeedback.selectionClick();
    _hold.forward(from: 0);
  }

  void _holdUp() {
    if (_hold.isAnimating) _hold.reset();
  }

  Future<void> _callHeld() async {
    _hold.reset();
    if (!_canDecide || !_run.call()) return;
    HapticFeedback.mediumImpact();
    _stepDone();
    final idx = _run.index;
    await _phoneSay(M7RuleQuestionLines.askWhich);
    if (!mounted || _ended || _run.index != idx) return;
    setState(() {
      _run.openBook();
      _page = 0;
    });
    _cue('sounds/quiz_flip.ogg', volume: 0.5);
    unawaited(_sayChain([M7RuleQuestionLines.askPage]));
  }

  // --- the rulebook -------------------------------------------------------------------------
  bool get _canPage => _canPlay && _run.stage == M7RqStage.paging && !_run.roundDone;

  void _bookStart(Offset g) {
    _bookFrom = null;
    _bookMode = null;
    if (!_canPage) return;
    _bookFrom = g;
    _bookAt = g;
  }

  void _bookMove(Offset g) {
    final from = _bookFrom;
    if (from == null) return;
    if (!_canPage) {
      setState(() => _bookFrom = null);
      return;
    }
    final d = g - from;
    if (_bookMode == null && d.distance > 10) _bookMode = d.dx.abs() > d.dy.abs() ? _BookMode.flip : _BookMode.carry;
    setState(() => _bookAt = g);
  }

  void _bookEnd() {
    final from = _bookFrom;
    final mode = _bookMode;
    final at = _bookAt;
    setState(() {
      _bookFrom = null;
      _bookMode = null;
    });
    if (from == null || !_canPage) return;
    final d = at - from;
    if (mode == _BookMode.flip) {
      final n = M7RqPage.values.length;
      final to = d.dx < -40 ? _page + 1 : (d.dx > 40 ? _page - 1 : _page);
      if (to == _page || to < 0 || to >= n) {
        _hints.missTap();
        return;
      }
      _tick('sounds/learn/card_deal_a.ogg', 0.45);
      setState(() => _page = to);
      _stepDone();
      return;
    }
    if (mode == _BookMode.carry) {
      final phone = HintSpec.globalRectOf(_phoneKey);
      if (phone != null && phone.inflate(18).contains(at)) {
        unawaited(_show(M7RqPage.values[_page]));
        return;
      }
    }
    _hints.missTap();
  }

  Future<void> _show(M7RqPage p) async {
    if (!_canPage) return;
    final idx = _run.index;
    final origin = _origin(_phoneKey);
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    final m = _run.show(p);
    _stepDone();
    if (m != null) {
      await _phoneSay(m == M7RuleQuestionMistakes.needless ? M7RuleQuestionLines.allFine : M7RuleQuestionLines.notThere);
      if (!mounted || _ended || _run.index != idx) return;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    await _phoneSay(M7RuleQuestionLines.agree);
    if (!mounted || _ended || _run.index != idx) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final k = _order.kind;
    unawaited(askReason(
      deal: () => dealChoices(M7RuleQuestionLines.whyAskRight[k]!, M7RuleQuestionLines.myths, widget.rng),
      question: M7RuleQuestionLines.whyAsk,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Offset _origin(GlobalKey key) {
    final r = HintSpec.globalRectOf(key);
    if (r != null) return r.center;
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.6);
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    unawaited(_startOrder());
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
    if (_run.questioned) {
      // The lawful fix plays.
      setState(() {
        _run.applyFix();
        _flashKind = _order.kind;
        _flashN++;
      });
      _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    }
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 600 : 1400), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7RuleQuestionLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.index != _run.deal.coworkerAt || _run.roundDone) return null;
    if (_run.stage != M7RqStage.deciding) return null;
    if (_intro || _card != null || tableBusy || _closeup != null || _okPreview || _phoneTalking) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    _hold.reset();
    if (!held) {
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7RuleQuestionLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7RuleQuestionLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7RuleQuestionLines.tapWhy[_nudgeN++ % M7RuleQuestionLines.tapWhy.length]
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
      _okPreview = false;
      _closeup = null;
      _bookFrom = null;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7rq/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() => _card = null);
    if (_run.roundDone) {
      // The order is over (carried out): the next one.
      _next();
      return;
    }
    // A wrong page: the book is still open. A listen: the order still waits.
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
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (_run.passed) {
      await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
      await save.recordStars(_rungId, stars);
    }
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M7RuleQuestionLines.fail : (_quickBonus ? M7RuleQuestionLines.quick : M7RuleQuestionLines.allSet),
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

  // --- the gesture hand -------------------------------------------------------------
  /// How to touch, never what: a sweep over the five lane objects and both
  /// controls alike; a tap on a close-up's close button; on the rulebook a
  /// swipe left, a swipe right, then a short drag from the booklet toward the
  /// phone (the only drop target).
  HintSpec? _hint() {
    final n = _hintN++;
    if (_closeup != null) return HintSpec.tapOn(_closeKey);
    if (_run.stage == M7RqStage.paging) {
      final book = HintSpec.globalRectOf(_bookKey);
      if (book == null) return null;
      switch (n % 3) {
        case 0:
          return HintSpec.swipe(book.center, toward: const Offset(-1, 0), travel: 90);
        case 1:
          return HintSpec.swipe(book.center, toward: const Offset(1, 0), travel: 90);
        default:
          final phone = HintSpec.globalRectOf(_phoneKey);
          if (phone == null) return null;
          final d = phone.center - book.center;
          return HintSpec.drag(book.center, toward: d / d.distance, travel: 80);
      }
    }
    return HintSpec.sweepOver([for (final k in M7RqKind.values) _objKeys[k]!, _okKey, _callKey]);
  }

  // --- the scene -----------------------------------------------------------------------
  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7RqGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final flash = _flashKind;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(child: CustomPaint(painter: M7RqLanePainter(look: _run.look, geo: geo))),
      ),
      // The objects' places, for the sweep over the choices (no paint).
      for (final k in M7RqKind.values)
        Positioned.fromRect(
          key: ValueKey('obj-${k.name}'),
          rect: geo.hit(k),
          child: IgnorePointer(child: SizedBox.expand(key: _objKeys[k])),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7RuleQuestionLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition),
          ),
        ),
      ),
      if (flash != null)
        Positioned.fill(
          key: ValueKey('fix-$_flashN'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : CustomPaint(painter: M7RqFlashPainter(rect: geo.hit(flash), v: v)),
            ),
          ),
        ),
      // The next order: a short fade (the lane may change under it).
      if (!_intro)
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final paging = playing && _run.stage == M7RqStage.paging && !_run.roundDone && _card == null && !deckUp;
    final controls = playing && !deckUp && _card == null && !paging && !_run.done;
    final waiting = playing &&
        _card == null &&
        !deckUp &&
        !coworkerOpen &&
        !tableBusy &&
        !_okPreview &&
        !_phoneTalking &&
        _bookFrom == null &&
        !_hold.isAnimating &&
        (_run.deciding || paging);
    final bookW = math.min(300.0, size.width - 32);
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
              labels: [for (var i = 0; i < kM7RqOrders; i++) enDigits('${i + 1}')],
              done: {for (var i = 0; i < math.min(_run.index, kM7RqOrders); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.index}/$_steps/${_run.stage.name}/${_closeup?.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              // The rulebook's shade: the lane takes nothing meanwhile.
              if (paging)
                Positioned.fill(
                  key: const ValueKey('book-shade'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (_) => _hints.missTap(),
                    child: const ColoredBox(color: Color(0x8C050A16)),
                  ),
                ),
              if (playing && !_run.done)
                Positioned(
                  key: const ValueKey('hud-phone'),
                  left: 8,
                  right: 128,
                  bottom: pad.bottom + 72,
                  child: _PhoneCard(
                    key: _phoneKey,
                    lines: _phone,
                    talking: _phoneTalking,
                    target: paging,
                    hot: _bookMode == _BookMode.carry,
                  ),
                ),
              if (controls)
                Positioned(
                  key: const ValueKey('hud-controls'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  child: Row(
                    children: [
                      Expanded(
                        child: CardAside(
                          aside: _okAside,
                          child: _OkButton(key: _okKey, enabled: _run.deciding && !_phoneTalking, onTap: _openOk),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HoldButton(
                          key: _callKey,
                          progress: _hold,
                          enabled: _run.deciding && !_phoneTalking,
                          onDown: _holdDown,
                          onUp: _holdUp,
                        ),
                      ),
                    ],
                  ),
                ),
              if (paging)
                Positioned(
                  key: const ValueKey('hud-book'),
                  top: pad.top + 108,
                  left: (size.width - bookW) / 2,
                  width: bookW,
                  child: _bookLayer(bookW),
                ),
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 70), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (playing && _closeup != null && _card == null)
                Positioned.fill(
                  key: ValueKey('closeup-${_closeup!.name}'),
                  child: _Closeup(
                    kind: _closeup!,
                    look: _run.look,
                    card: _run.card,
                    closeKey: _closeKey,
                    quiet: quiet,
                    onClose: _closeCloseup,
                  ),
                ),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (controls && _okPreview)
                Positioned.fill(
                  key: const ValueKey('ok-preview'),
                  child: CardPreviewOverlay(
                    textBn: M7RuleQuestionLines.ok,
                    icon: Icons.check_circle_outline_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmOk,
                    onReject: _rejectOk,
                  ),
                ),
              if (_card != null && !struckOut)
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
                  line: M7RuleQuestionLines.intro,
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

  /// The booklet: the open page follows a swipe sideways (to turn) or a drag
  /// down (to carry it to the phone).
  Widget _bookLayer(double w) {
    final from = _bookFrom;
    final d = from == null ? Offset.zero : _bookAt - from;
    final mode = _bookMode;
    final shift = switch (mode) {
      _BookMode.flip => Offset(d.dx * 0.5, 0),
      _BookMode.carry => d,
      null => Offset.zero,
    };
    return Transform.translate(
      offset: shift,
      child: Transform.scale(
        scale: mode == _BookMode.carry ? 0.82 : 1,
        child: Semantics(
          label: M7RuleQuestionLines.bookLabel,
          child: GestureDetector(
            key: _bookKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: (e) => _bookStart(e.globalPosition),
            onPanUpdate: (e) => _bookMove(e.globalPosition),
            onPanEnd: (_) => _bookEnd(),
            onPanCancel: () => setState(() {
              _bookFrom = null;
              _bookMode = null;
            }),
            child: _BookPage(page: M7RqPage.values[_page], index: _page, width: w),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Pieces
// ============================================================================

/// The trainee's phone: the supervisor's messages (the order, his replies).
class _PhoneCard extends StatelessWidget {
  const _PhoneCard({super.key, required this.lines, required this.talking, required this.target, required this.hot});
  final List<String> lines;
  final bool talking;

  /// The rulebook is open: the phone is where a page is shown.
  final bool target;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final edge = hot ? SlmColors.gold300 : (target ? const Color(0xFF9FB3C8) : const Color(0xFF3A4A60));
    return Semantics(
      container: true,
      label: M7RuleQuestionLines.phoneHead,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
        decoration: BoxDecoration(
          color: const Color(0xF20E1726),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: edge, width: hot ? 2.4 : 1.6),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(talking ? Icons.phone_in_talk_rounded : Icons.smartphone_rounded, size: 14, color: const Color(0xFF7FD48A)),
                const SizedBox(width: 4),
                Text(M7RuleQuestionLines.phoneHead, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFB9C6D6))),
              ],
            ),
            const SizedBox(height: 3),
            for (final (i, l) in lines.indexed)
              Padding(
                key: ValueKey('phone-$i-$l'),
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == lines.length - 1 ? const Color(0xFFF4F7FA) : const Color(0xFFCCD5DE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(enDigits(l),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF14202E), height: 1.25)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 'ঠিক আছে' (a tap opens its preview).
class _OkButton extends StatelessWidget {
  const _OkButton({super.key, required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M7RuleQuestionLines.ok,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: _ControlFace(
            icon: Icons.check_rounded,
            label: M7RuleQuestionLines.ok,
            sub: null,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// 'সুপারভাইজারকে ফোন' — press and hold 1.2 s (a ring fills while held).
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.progress, required this.enabled, required this.onDown, required this.onUp});
  final Animation<double> progress;
  final bool enabled;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M7RuleQuestionLines.call,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: _ControlFace(
            icon: Icons.phone_forwarded_rounded,
            label: M7RuleQuestionLines.call,
            sub: M7RuleQuestionLines.holdHint,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: progress,
                builder: (_, _) => progress.value <= 0
                    ? const SizedBox.shrink()
                    : CustomPaint(size: const Size(40, 40), painter: _RingPainter(progress.value)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlFace extends StatelessWidget {
  const _ControlFace({required this.icon, required this.label, required this.sub, required this.child});
  final IconData icon;
  final String label;
  final String? sub;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [Icon(icon, size: 24, color: SlmColors.gold300), child],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ),
                if (sub != null) Text(sub!, maxLines: 1, style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFB9C6D6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.v);
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = (Offset.zero & size).deflate(2);
    c.drawArc(
        r,
        -math.pi / 2,
        2 * math.pi * v,
        false,
        Paint()
          ..color = SlmColors.gold300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}

/// One page of the pocket rulebook (all pages alike: a title and the lesson's
/// words; the page number at the foot).
class _BookPage extends StatelessWidget {
  const _BookPage({required this.page, required this.index, required this.width});
  final M7RqPage page;
  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    // A uniform border (a rounded border must be one colour); the red spine
    // is a child strip, clipped to the corners.
    return Container(
      width: width,
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown.shade300),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 6, child: ColoredBox(color: Color(0xFF7A2E1E))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 9, 13, 7),
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CEA', style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFF7A2E1E))),
        const SizedBox(height: 2),
        Text(M7RuleQuestionLines.pageTitle(page),
            maxLines: 2, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A1A10), height: 1.2)),
        const Divider(height: 10, thickness: 1, color: Color(0x667A2E1E)),
        Expanded(
          child: Text(M7RuleQuestionLines.pageBody(page),
              overflow: TextOverflow.fade, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF3A2A1E), height: 1.35)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_left_rounded, size: 16, color: Color(0x997A2E1E)),
            Text(M7RuleQuestionLines.pageCount(index), style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF7A2E1E))),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0x997A2E1E)),
          ],
        ),
      ],
    );
  }
}

/// A close-up of a lane object (its real markings only), or the helper's ID
/// card back.
class _Closeup extends StatelessWidget {
  const _Closeup({
    required this.kind,
    required this.look,
    required this.card,
    required this.closeKey,
    required this.quiet,
    required this.onClose,
  });
  final M7RqKind kind;
  final M7RqLook look;
  final ({String name, bool training, bool signed}) card;
  final GlobalKey closeKey;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = math.min(300.0, size.width - 40);
    final body = kind == M7RqKind.helper
        ? _IdCard(card: card)
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 220,
              child: RepaintBoundary(child: CustomPaint(painter: M7RqLanePainter(look: look, zoom: M7RqGeo.zooms[kind]), size: Size.infinite)),
            ),
          );
    final card_ = Container(
      width: w,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.8), width: 1.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(M7RuleQuestionLines.closeTitle(kind), textAlign: TextAlign.center, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
          const SizedBox(height: 8),
          body,
          const SizedBox(height: 10),
          Center(
            child: Semantics(
              button: true,
              label: M7RuleQuestionLines.close,
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('closeup-close'),
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: Container(
                  key: closeKey,
                  constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF22344F), borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close_rounded, size: 18, color: SlmColors.ivory),
                      const SizedBox(width: 6),
                      Text(M7RuleQuestionLines.close, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const ColoredBox(color: Color(0x99050A16)),
          ),
        ),
        Center(
          child: quiet
              ? card_
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1),
                  duration: const Duration(milliseconds: 220),
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: card_,
                ),
        ),
      ],
    );
  }
}

/// The back of the helper's ID card: his name, training, the authorization
/// (signed and stamped, or blank). A game device for how authorization is
/// shown in the field (spec unsupported[4]).
class _IdCard extends StatelessWidget {
  const _IdCard({required this.card});
  final ({String name, bool training, bool signed}) card;

  @override
  Widget build(BuildContext context) {
    final ink = bangla(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E2A36));
    final key = bangla(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF5A6675));
    Widget row(String k, Widget v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 82, child: Text('$k:', style: key)),
              Expanded(child: v),
            ],
          ),
        );
    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2F6FA8), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 6, color: const Color(0xFF2F6FA8)),
          const SizedBox(height: 8),
          row(M7RuleQuestionLines.cardName, Text(card.name, style: ink)),
          row(M7RuleQuestionLines.cardTraining, Text(card.training ? M7RuleQuestionLines.trainingDone : M7RuleQuestionLines.trainingOn, style: ink)),
          row(
            M7RuleQuestionLines.cardAuth,
            SizedBox(height: 46, child: CustomPaint(painter: _SignPainter(signed: card.signed))),
          ),
        ],
      ),
    );
  }
}

/// The authorization box: a signature and a round stamp, or a blank line.
class _SignPainter extends CustomPainter {
  const _SignPainter({required this.signed});
  final bool signed;

  @override
  void paint(Canvas c, Size size) {
    final base = size.height - 6;
    c.drawLine(
        Offset(0, base),
        Offset(size.width - 6, base),
        Paint()
          ..color = const Color(0xFF8A96A3)
          ..strokeWidth = 1);
    if (!signed) return;
    final ink = Paint()
      ..color = const Color(0xFF1F3A8A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(4, base - 6);
    for (var i = 0; i < 6; i++) {
      final x = 8.0 + i * 12;
      path.quadraticBezierTo(x, base - (i.isEven ? 26 : 2), x + 6, base - 10);
    }
    c.drawPath(path, ink);
    final stamp = Offset(size.width - 34, size.height / 2 - 2);
    final red = Paint()
      ..color = const Color(0xCCB03030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawCircle(stamp, 18, red);
    c.drawCircle(stamp, 12, red..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_SignPainter old) => old.signed != signed;
}
