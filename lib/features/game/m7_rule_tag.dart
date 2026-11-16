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
import 'm7_rule_tag_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_rule_tag_world.dart'
    show M7TagGeo, M7TagLook, M7TagPart, M7TagReg, M7TagSite, M7TagSiteKind, kM7TagSkies, m7TagBreach, m7TagFixedParts, m7TagLooks, m7TagRegOf;

// Lesson 7.1 "ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন: আপনার বাইবেল", কাজ
// "নিয়মের পাতা লাগান" (pack do_7_1_a, rung 7.1/do/0, engineType m7_rule_tag).
// A neighbourhood patrol at mid-morning: three sites dealt from four (a DTR on
// a double-pole structure, a feeder pillar at a market corner, a lane where a
// new balcony and a new rooftop room came up under the LT line, a DTR on a
// plinth by a school wall), in dealt order. The pocket CEA rulebook stands on
// the bottom edge with four fixed tabs in booklet order — the live CEA 2023
// numbers of lesson 7.1 point 3 (X3): রেগুলেশন 3 (উপযুক্ত ব্যক্তি), 20
// (বিপজ্জনক নোটিশ), 43 ও 50 (আর্থিং), 60–63 ও 71 (ক্লিয়ারেন্স).
//
// The core verb: drag a tab onto a part of the site (spot, then classify).
//  breach + its regulation → a red tag sticks; the first pin of each
//    regulation in a play puts ◆ on the table → "কেন এখানে রেগুলেশন N?"
//    (the right card states the lesson's rule); a later pin of the same
//    regulation pays at once;
//  breach + another regulation → slip (wrong page), the tab springs back;
//    the part can be pinned again;
//  a compliant part → slip (needless flag, R29);
//  empty ground → the tab springs back (a missed tap for the hand).
// Hold a tab: its one-line rule from the lesson shows above the booklet (no
// cost, never names a part); hold the spine: all four. A swipe across the
// inspection register signs the site off at any time (no "left" counter):
// each breach left unpinned = one slip with its card (spec; owner question),
// then the camera pans to the next site.
//
// No deadly in lesson 7.1 (ruling M7-6): nothing is charged or touched, a
// cut earth seen at the register is a slip. Every mistake is a slip (R28,
// R29, R30); three slips strike out.
//
// The coworker (lesson myth 2 word for word, M7-10) comes once a play at site
// 2 or 3 (dealt): the first time the player lifts a tab there he is called;
// the drop and the register wait for him (holdForCoworker). Listening = slip
// (X2/B1: nothing on this level is deadly).
//
// Gesture hands (how, never what): with no tab in hand, a sweep over every
// checkable part alike, a short drag up from the booklet's centre (between
// two tabs, never from one), a hold on the booklet's spine. The register is
// never hinted. Off during the intro, pans, the praise window, the coworker,
// cards and results.

// ============================================================================
// Content
// ============================================================================

abstract final class M7RuleTagLines {
  static const title = 'নিয়মের পাতা লাগান';
  // DRAFT wording — owner (M6-12 / M7-10): every line below until the owner
  // gives the natural wording.
  static const intro = 'আজ এলাকার টহল — CEA রুলবুক হাতে নিয়ম ভাঙা খুঁজে বের করুন।';

  // The guide's task (tap him: the next of the pool, from the start).
  static const askSite = 'এই সাইটে নিয়ম ভাঙা কোথায়? রুলবুকের পাতা টেনে লাগান।';
  static const tapRead = 'রুলবুক হাতে সাইটটা পড়ুন।';
  static const tapShow = 'কোন নিয়ম কোথায় ভেঙেছে, পাতা লাগিয়ে দেখান।';
  static const tapSign = 'সব দেখা হলে রেজিস্টারে সই করুন।';
  static const tasks = [askSite, tapRead, tapShow, tapSign];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The booklet (a worker's own words; English digits).
  static const regWord = 'রেগুলেশন';
  static String regNo(M7TagReg r) => switch (r) {
        M7TagReg.r3 => '3',
        M7TagReg.r20 => '20',
        M7TagReg.r43 => '43 ও 50',
        M7TagReg.r60 => '60–63 ও 71',
      };
  static String regName(M7TagReg r) => switch (r) {
        M7TagReg.r3 => 'উপযুক্ত ব্যক্তি',
        M7TagReg.r20 => 'বিপজ্জনক নোটিশ',
        M7TagReg.r43 => 'আর্থিং',
        M7TagReg.r60 => 'ক্লিয়ারেন্স',
      };

  /// The red tag that sticks on a pinned part.
  static String tag(M7TagReg r) => enDigits('$regWord ${regNo(r)}');

  /// The tab's label (screen readers; the tab shows the three lines).
  static String tabLabel(M7TagReg r) => '${tag(r)} · ${regName(r)}';

  /// A held tab's one-line rule (lesson 7.1 point 3, the live text).
  static String rule(M7TagReg r) => switch (r) {
        M7TagReg.r3 => 'শুধু প্রশিক্ষিত এবং অনুমোদিত ব্যক্তিই বিদ্যুৎ লাইনে কাজ করতে পারবেন।',
        M7TagReg.r20 => 'প্রতিটি বিদ্যুৎ ইনস্টলেশনের গায়ে ডেঞ্জার প্লেট লাগানো বাধ্যতামূলক।',
        M7TagReg.r43 => 'যন্ত্রপাতির ধাতব বডি আর সিস্টেমের নিউট্রাল আর্থিং করা বাধ্যতামূলক।',
        M7TagReg.r60 => 'মাটি, বাড়ি আর অন্য লাইন থেকে ন্যূনতম ক্লিয়ারেন্সের চার্ট আছে।',
      };

  static const registerWord = 'ইন্সপেকশন রেজিস্টার';
  static const signHere = 'সই';
  static const sceneLabel = 'টহলের সাইট';

  static String siteName(M7TagSiteKind k) => switch (k) {
        M7TagSiteKind.dtrPole => 'ডাবল পোলের ট্রান্সফরমার',
        M7TagSiteKind.pillar => 'বাজারের ফিডার পিলার',
        M7TagSiteKind.lane => 'নতুন বাড়ির গলি',
        M7TagSiteKind.plinth => 'স্কুলের পাশের ট্রান্সফরমার',
      };

  // The reasons (the right ones state the lesson's rule for the regulation
  // just pinned; the wrong ones are myths and field excuses).
  static String whyQ(M7TagReg r) => enDigits('কেন এখানে $regWord ${regNo(r)}?');
  static const whyRight = <M7TagReg, List<String>>{
    M7TagReg.r3: ['শুধু প্রশিক্ষিত ও অনুমোদিত লোকই লাইনে কাজ করবেন', 'অনুমোদন ছাড়া কারও লাইনে কাজ করা আইনে বারণ'],
    M7TagReg.r20: ['প্রতিটি ইনস্টলেশনের গায়ে ডেঞ্জার প্লেট বাধ্যতামূলক', 'ডেঞ্জার প্লেট গায়ে না থাকলে নিয়ম ভাঙা হয়'],
    M7TagReg.r43: ['ধাতব বডি আর নিউট্রাল আর্থ করা বাধ্যতামূলক', 'আর্থ লিড ঠিকমতো লাগানো না থাকলে নিয়ম ভাঙা'],
    M7TagReg.r60: ['লাইন থেকে বাড়ির ন্যূনতম ক্লিয়ারেন্স রাখতেই হবে', 'বাড়িতে লাইন ঠেকে থাকা মানে ক্লিয়ারেন্স নেই'],
  };
  static const myths = [
    'আইনকানুন তো কাগজের জন্য, মাঠে কেউ মানে না',
    'এসব নিয়ম শুধু বড় ইঞ্জিনিয়ারদের দেখার বিষয়',
    'দুর্ঘটনা না ঘটলে নিয়ম ভাঙায় কিছু যায় আসে না',
    'পুরোনো জিনিসে এসব নিয়ম আর খাটে না, ছেড়ে দিন',
  ];
  static const _wrongBy = <M7TagReg, List<String>>{
    M7TagReg.r3: ['যে কাজটা জানে, তার আর অনুমোদনের দরকার নেই', 'পাড়ার মিস্ত্রিও দরকারে লাইনে হাত দিতে পারেন'],
    M7TagReg.r20: ['সবাই জানে এটা বিদ্যুতের, প্লেট না হলেও চলে', 'প্লেট মাটিতে পড়ে থাকলেও নিয়ম মানাই হয়েছে'],
    M7TagReg.r43: ['আর্থ লিড শুধু বাজ পড়লে কাজে লাগে, রোজ নয়', 'একটা আর্থ ঠিক থাকলেই অন্য আর্থটা না হলেও চলে'],
    M7TagReg.r60: ['বাড়ির মালিকের ব্যাপার, আমাদের দেখার নয়', 'লাইন আগে ছিল, বাড়ি পরে হয়েছে — তাই চলবে'],
  };

  /// The wrong reasons for a regulation (≥ 5: its own excuses + the myths).
  static List<String> whyWrong(M7TagReg r) => [..._wrongBy[r]!, ...myths];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in _wrongBy.values) ...l, ...myths];

  // The careless coworker: lesson 7.1 myth 2, word for word (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'আইন তো শুধু বড় বড় ইঞ্জিনিয়ারদের জন্য, আমাদের এসব জেনে কী হবে?',
    exitLine: coworkerExit,
    right: [
      'বিপদের মুখে আমরাই — আইন আমাদের জন্যই বেশি দরকারি',
      'আইন জানলে আত্মবিশ্বাসী আর পেশাদার হওয়া যায়',
      'না, সরাসরি বিপদে কাজ করি আমরাই, আইন আমাদেরও',
    ],
    wrong: [
      'ঠিক, এসব ইঞ্জিনিয়ার সাহেবরাই দেখে নেবেন',
      'রুলবুক পকেটেই থাক, টহলটা তাড়াতাড়ি সেরে ফেলি',
      'হ্যাঁ, আইন জানা আমাদের কাজের মধ্যে পড়ে না',
      'ঠিক, নিয়ম দেখার লোক তো অফিসেই বসে আছে',
      'আচ্ছা, রুলবুক না দেখেই রেজিস্টারে সই করি',
    ],
    asks: ['ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! যে বিপদের মুখে কাজ করে, আইন তার জন্যই সবচেয়ে দরকারি।';

  static const allSet = 'টহল শেষ — নিয়ম ভাঙা ধরে রেজিস্টারে তুলেছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — রুলবুক হাতে প্রতিটা জিনিস মিলিয়ে দেখুন।';

  // "আজ যা ধরলেন".
  static String caughtSite(M7TagSiteKind k, Iterable<M7TagReg> regs) =>
      enDigits('${siteName(k)}: $regWord ${[for (final r in M7TagReg.values) if (regs.contains(r)) regNo(r)].join(' · ')}');
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (the exit, the old asks,
  /// the quick-pass line).
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', quick};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        ...tapWhy.where((l) => !_oldWhyTaps.contains(l)),
        for (final r in M7TagReg.values) whyQ(r),
        ...coworker.asks.where((a) => !reused.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M7RuleTagMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused, ...tapWhy];
  static const _oldWhyTaps = {'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};
}

abstract final class M7RuleTagMistakes {
  static const _dir = 'assets/game/art/m7_rule_tag';

  /// Lesson 7.1 point 3 (0-based 2) holds the four regulations.
  static const _point = 2;

  // DRAFT wording — owner (M6-12). Wrong page on a real breach (R28).
  static const wrongReg3 = DoMistake(
    key: '7.1/m7_rule_tag/wrong-reg-3',
    textBn: 'কে লাইনে কাজ করবেন, সেই নিয়ম রেগুলেশন 3-এ — উপযুক্ত ব্যক্তি।',
    art: '$_dir/person_bad.svg',
    lessonPoint: _point,
  );
  static const wrongReg20 = DoMistake(
    key: '7.1/m7_rule_tag/wrong-reg-20',
    textBn: 'ডেঞ্জার প্লেটের নিয়ম রেগুলেশন 20-এ — বিপজ্জনক নোটিশ।',
    art: '$_dir/plate_bad.svg',
    lessonPoint: _point,
  );
  static const wrongReg43 = DoMistake(
    key: '7.1/m7_rule_tag/wrong-reg-43',
    textBn: 'আর্থ লিডের নিয়ম রেগুলেশন 43 ও 50-এ — আর্থিং।',
    art: '$_dir/earth_bad.svg',
    lessonPoint: _point,
  );
  static const wrongReg60 = DoMistake(
    key: '7.1/m7_rule_tag/wrong-reg-60',
    textBn: 'বাড়ি থেকে লাইনের দূরত্বের নিয়ম রেগুলেশন 60–63 ও 71-এ — ক্লিয়ারেন্স।',
    art: '$_dir/span_bad.svg',
    lessonPoint: _point,
  );

  // A tab on a compliant part (a needless flag, R29).
  static const needlessPlate = DoMistake(
    key: '7.1/m7_rule_tag/needless-plate',
    textBn: 'এখানে নিয়ম মানা আছে — ডেঞ্জার প্লেট গায়ে লাগানো।',
    art: '$_dir/plate_ok.svg',
    lessonPoint: _point,
  );
  static const needlessBodyEarth = DoMistake(
    key: '7.1/m7_rule_tag/needless-body-earth',
    textBn: 'এখানে নিয়ম মানা আছে — বডির আর্থ লিড ঠিকমতো লাগানো।',
    art: '$_dir/earth_ok.svg',
    lessonPoint: _point,
  );
  static const needlessNeutralEarth = DoMistake(
    key: '7.1/m7_rule_tag/needless-neutral-earth',
    textBn: 'এখানে নিয়ম মানা আছে — নিউট্রালের আর্থ লিড ঠিকমতো লাগানো।',
    art: '$_dir/earth_ok.svg',
    lessonPoint: _point,
  );
  static const needlessPerson = DoMistake(
    key: '7.1/m7_rule_tag/needless-person',
    textBn: 'এখানে নিয়ম মানা আছে — কোম্পানির অনুমোদিত কর্মী, গলায় আইডি কার্ড।',
    art: '$_dir/person_ok.svg',
    lessonPoint: _point,
  );
  // A clear span: never "not touching = rule kept" (a small gap is still a
  // breach; 7.1 has a minimum-clearance chart, 7.3 gives 2.5 m over a roof).
  static const needlessBalcony = DoMistake(
    key: '7.1/m7_rule_tag/needless-balcony-span',
    textBn: 'এখানে নিয়ম মানা আছে — লাইন নতুন বারান্দার অনেক উপর দিয়ে গেছে, ক্লিয়ারেন্স আছে।',
    art: '$_dir/span_ok.svg',
    lessonPoint: _point,
  );
  static const needlessRoof = DoMistake(
    key: '7.1/m7_rule_tag/needless-roof-span',
    textBn: 'এখানে নিয়ম মানা আছে — লাইন ছাদের নতুন ঘরের অনেক উপর দিয়ে গেছে, ক্লিয়ারেন্স আছে।',
    art: '$_dir/span_ok.svg',
    lessonPoint: _point,
  );

  // The register signed with a breach unpinned (R28; one slip per breach).
  static const missedPlate = DoMistake(
    key: '7.1/m7_rule_tag/missed-plate',
    textBn: 'সই করলেন, কিন্তু ইনস্টলেশনের গায়ে ডেঞ্জার প্লেট লাগানো ছিল না — রেগুলেশন 20।',
    art: '$_dir/plate_bad.svg',
    lessonPoint: _point,
  );
  static const missedBodyEarth = DoMistake(
    key: '7.1/m7_rule_tag/missed-body-earth',
    textBn: 'সই করলেন, কিন্তু ধাতব বডির আর্থ লিড ঠিক ছিল না — রেগুলেশন 43 ও 50।',
    art: '$_dir/earth_bad.svg',
    lessonPoint: _point,
  );
  static const missedNeutralEarth = DoMistake(
    key: '7.1/m7_rule_tag/missed-neutral-earth',
    textBn: 'সই করলেন, কিন্তু নিউট্রালের আর্থ লিড ঠিক ছিল না — রেগুলেশন 43 ও 50।',
    art: '$_dir/earth_bad.svg',
    lessonPoint: _point,
  );
  static const missedPerson = DoMistake(
    key: '7.1/m7_rule_tag/missed-person',
    textBn: 'সই করলেন, কিন্তু অনুমোদন ছাড়া লোক লাইনে কাজ করছিল — এটা আইনে বারণ, রেগুলেশন 3।',
    art: '$_dir/person_bad.svg',
    lessonPoint: _point,
  );
  // Each span its own card and book entry (X6: the card names THIS part).
  static const missedBalcony = DoMistake(
    key: '7.1/m7_rule_tag/missed-balcony-span',
    textBn: 'সই করলেন, কিন্তু লাইন নতুন বারান্দায় ঠেকে ছিল — ক্লিয়ারেন্স নেই, রেগুলেশন 60–63 ও 71।',
    art: '$_dir/span_bad.svg',
    lessonPoint: _point,
  );
  static const missedRoof = DoMistake(
    key: '7.1/m7_rule_tag/missed-roof-span',
    textBn: 'সই করলেন, কিন্তু লাইন ছাদের নতুন ঘরে ঠেকে ছিল — ক্লিয়ারেন্স নেই, রেগুলেশন 60–63 ও 71।',
    art: '$_dir/span_bad.svg',
    lessonPoint: _point,
  );

  // Listening to the coworker (lesson 7.1 myth 2 and its reality; R30, X2/B1).
  static const pushListen = DoMistake(
    key: '7.1/m7_rule_tag/push-listen',
    textBn: 'একেবারেই নয়। যে সরাসরি বিপদের মুখে কাজ করছেন, আইন তাঁর জন্যই সবচেয়ে বেশি প্রাসঙ্গিক — আইন জানলে আত্মবিশ্বাসী আর পেশাদার হওয়া যায়।',
    art: '$_dir/rulebook.svg',
  );

  static DoMistake wrongReg(M7TagReg r) => switch (r) {
        M7TagReg.r3 => wrongReg3,
        M7TagReg.r20 => wrongReg20,
        M7TagReg.r43 => wrongReg43,
        M7TagReg.r60 => wrongReg60,
      };

  static DoMistake needless(M7TagPart p) => switch (p) {
        M7TagPart.plate => needlessPlate,
        M7TagPart.bodyEarth => needlessBodyEarth,
        M7TagPart.neutralEarth => needlessNeutralEarth,
        M7TagPart.person => needlessPerson,
        M7TagPart.balconySpan => needlessBalcony,
        M7TagPart.roofSpan => needlessRoof,
      };

  static DoMistake missed(M7TagPart p) => switch (p) {
        M7TagPart.plate => missedPlate,
        M7TagPart.bodyEarth => missedBodyEarth,
        M7TagPart.neutralEarth => missedNeutralEarth,
        M7TagPart.person => missedPerson,
        M7TagPart.balconySpan => missedBalcony,
        M7TagPart.roofSpan => missedRoof,
      };

  static const List<DoMistake> all = [
    wrongReg3,
    wrongReg20,
    wrongReg43,
    wrongReg60,
    needlessPlate,
    needlessBodyEarth,
    needlessNeutralEarth,
    needlessPerson,
    needlessBalcony,
    needlessRoof,
    missedPlate,
    missedBodyEarth,
    missedNeutralEarth,
    missedPerson,
    missedBalcony,
    missedRoof,
    pushListen,
  ];
}

// ============================================================================
// Deal and rules
// ============================================================================

@immutable
class M7TagDeal {
  const M7TagDeal({required this.sites, required this.coworkerSite, required this.light});

  /// The three sites in patrol order.
  final List<M7TagSite> sites;

  /// The site the coworker comes in at (2nd or 3rd).
  final int coworkerSite;

  /// The morning light (index into [kM7TagSkies]).
  final int light;
}

/// Who stands at a site: the lane always has someone on the ladder; at the
/// pillar the company man, a local electrician or nobody (a third each); at
/// a DTR someone half the plays.
M7TagLook? _dealPerson(M7TagSiteKind k, math.Random rng) => switch (k) {
      M7TagSiteKind.lane => rng.nextBool() ? M7TagLook.crew : M7TagLook.local,
      M7TagSiteKind.pillar => [M7TagLook.crew, M7TagLook.local, null][rng.nextInt(3)],
      _ => rng.nextBool() ? null : (rng.nextBool() ? M7TagLook.crew : M7TagLook.local),
    };

M7TagSite m7TagDealSite(M7TagSiteKind k, math.Random rng) {
  final fixed = m7TagFixedParts(k);
  // His look is dealt first at every site (the lane too), so "the person
  // only" and "both spans clear" can happen at the lane.
  final person = _dealPerson(k, rng);
  final parts = [...fixed, if (person != null && !fixed.contains(M7TagPart.person)) M7TagPart.person];
  // 1–3 breaches, never all (the person, if any, is one of them by his look).
  final want = 1 + rng.nextInt(math.min(3, parts.length - 1));
  final order = [...parts]..shuffle(rng);
  final breach = <M7TagPart>{};
  if (person == M7TagLook.local) breach.add(M7TagPart.person);
  for (final p in order) {
    if (breach.length >= want) break;
    if (p == M7TagPart.person) continue;
    breach.add(p);
  }
  final looks = <M7TagPart, M7TagLook>{};
  for (final p in parts) {
    if (p == M7TagPart.person) {
      looks[p] = person!;
      continue;
    }
    final choices = m7TagLooks(p, breach: breach.contains(p));
    looks[p] = choices[rng.nextInt(choices.length)];
  }
  return M7TagSite(
    kind: k,
    looks: looks,
    mirror: rng.nextBool(),
    doorOpen: k == M7TagSiteKind.pillar && (person == M7TagLook.local || (person == M7TagLook.crew && rng.nextBool())),
  );
}

M7TagDeal m7TagDeal(math.Random rng) {
  final kinds = [...M7TagSiteKind.values]..shuffle(rng);
  final sites = [for (final k in kinds.take(3)) m7TagDealSite(k, rng)];
  return M7TagDeal(sites: sites, coworkerSite: 1 + rng.nextInt(2), light: rng.nextInt(kM7TagSkies.length));
}

/// What a dropped tab did.
enum M7TagDrop { pinned, wrongReg, needless, already }

/// The play state (pure logic).
class M7TagRun {
  M7TagRun(this.deal);
  final M7TagDeal deal;

  int index = 0;
  int slips = 0;
  int siteSlips = 0;

  /// The parts pinned on this site.
  final Set<M7TagPart> pinned = {};

  /// The regulations whose reason was already asked this play.
  final Set<M7TagReg> asked = {};
  final List<String> caught = [];

  M7TagSite get site => deal.sites[index.clamp(0, deal.sites.length - 1)];
  bool get done => index >= deal.sites.length;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  /// The site's breaches still unpinned.
  List<M7TagPart> get unpinned => [for (final p in site.breaches) if (!pinned.contains(p)) p];

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  /// A tab dropped on [part]: the result and the slip (if any).
  (M7TagDrop, DoMistake?) drop(M7TagPart part, M7TagReg reg) {
    final look = site.looks[part];
    if (done || look == null) return (M7TagDrop.already, null);
    if (pinned.contains(part)) return (M7TagDrop.already, null);
    if (!m7TagBreach(look)) return (M7TagDrop.needless, _slip(M7RuleTagMistakes.needless(part)));
    final right = m7TagRegOf(part);
    if (reg != right) return (M7TagDrop.wrongReg, _slip(M7RuleTagMistakes.wrongReg(right)));
    pinned.add(part);
    return (M7TagDrop.pinned, null);
  }

  /// The first pin of this regulation in the play: its reason is due.
  bool reasonDue(M7TagReg reg) => asked.add(reg);

  /// The register signed: one slip per breach left unpinned (in scene order).
  List<DoMistake> sign() {
    if (done) return const [];
    final missed = [for (final p in unpinned) _slip(M7RuleTagMistakes.missed(p))];
    final regs = {for (final p in pinned) m7TagRegOf(p)};
    if (regs.isNotEmpty) caught.add(M7RuleTagLines.caughtSite(site.kind, regs));
    return missed;
  }

  /// Listened to the coworker.
  DoMistake pushSlip() => _slip(M7RuleTagMistakes.pushListen);

  void next() {
    index++;
    pinned.clear();
    siteSlips = 0;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per site: the pan 1600, a look over the parts ~3000, 2 pins × 2500,
///     the swipe 1500 ≈ 11100 × 3                              ≈ 33300
///   + a reason for each regulation pinned (~3.3 × 8200)       ≈ 27000
///   + the coworker once                                       ≈  9600
///                                                             ≈ 70000
/// 85 % ≈ 59500 → 60 s (a builder's estimate; owner may tune after playtest).
const m7RuleTagQuickMs = 60000;

@immutable
class M7RuleTagPack {
  const M7RuleTagPack({required this.id, required this.titleBn, this.quickMs = m7RuleTagQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7RuleTagPack> m7RuleTagPacks = {
  'do_7_1_a': M7RuleTagPack(id: 'do_7_1_a', titleBn: M7RuleTagLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7RuleTagProbe {
  static M7TagRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7RuleTagPage extends StatefulWidget {
  const M7RuleTagPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7RuleTagPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7RuleTagPage> createState() => _M7RuleTagPageState();
}

class _M7RuleTagPageState extends State<M7RuleTagPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TagRunPage(
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

class _TagRunPage extends ConsumerStatefulWidget {
  const _TagRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7RuleTagPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TagRunPage> createState() => _TagRunPageState();
}

class _TagRunPageState extends ConsumerState<_TagRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7TagRun _run;
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

  /// The camera pans from the site before ([_from]) to this one.
  var _panning = false;
  int? _from;

  /// A tab in hand (its pin, design px) and a held tab / spine.
  M7TagReg? _drag;
  Offset _dragAt = Offset.zero;
  M7TagReg? _held;
  var _spineHeld = false;

  /// A swipe on the register.
  Offset? _signFrom;
  Offset _signNow = Offset.zero;
  final Set<int> _signed = {};

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _siteHintN = 0;
  int _steps = 0;
  M7TagGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7TagRun(m7TagDeal(widget.rng));
    M7RuleTagProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M7RuleTagProbe.run, _run)) M7RuleTagProbe.run = null;
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

  bool get _atHisSite => _run.index == _run.deal.coworkerSite;

  Future<void> _start() async {
    _clock.start();
    _startSite();
  }

  void _startSite() {
    setState(() {
      _wake++;
      _siteHintN = 0;
      _drag = null;
      _held = null;
      _spineHeld = false;
      _signFrom = null;
    });
    unawaited(_sayChain([M7RuleTagLines.askSite]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- hands on -----------------------------------------------------------------
  M7TagReg? _tabAt(Offset p, M7TagGeo geo) {
    for (final r in M7TagReg.values) {
      if (geo.tab(r).contains(p)) return r;
    }
    return null;
  }

  void _tapScene(Offset p, M7TagGeo geo) {
    if (!_canPlay) return;
    // A tab or the register only answers a drag / a swipe; a tap is a miss.
    _hints.missTap();
  }

  void _panStart(Offset p, M7TagGeo geo) {
    _drag = null;
    _signFrom = null;
    if (!_canPlay) return;
    final tab = _tabAt(p, geo);
    if (tab != null) {
      _tick('sounds/intro/click.ogg', 0.4);
      // His site: the first lift calls him in (the drop waits for him).
      if (_atHisSite && !coworkerDone && !coworkerDue) scheduleCoworker();
      setState(() {
        _drag = tab;
        _dragAt = p.translate(0, -M7TagGeo.lift);
        _held = null;
        _spineHeld = false;
      });
      return;
    }
    if (geo.register.contains(p)) {
      _signFrom = p;
      _signNow = p;
    }
  }

  void _panUpdate(Offset p) {
    if (_drag != null) {
      if (!_canPlay) {
        setState(() => _drag = null);
        return;
      }
      setState(() => _dragAt = p.translate(0, -M7TagGeo.lift));
      return;
    }
    if (_signFrom != null) _signNow = p;
  }

  void _panEnd(Offset global) {
    final tab = _drag;
    if (tab != null) {
      final pin = _dragAt;
      setState(() => _drag = null);
      _drop(tab, pin, global);
      return;
    }
    final from = _signFrom;
    _signFrom = null;
    if (from == null || !_canPlay) return;
    if ((_signNow.dx - from.dx).abs() < 40) {
      _hints.missTap();
      return;
    }
    _sign(global);
  }

  void _drop(M7TagReg reg, Offset pin, Offset global) {
    if (!_canPlay) return;
    final geo = _geoNow;
    if (geo == null) return;
    final part = geo.partAt(_run.site, pin);
    if (part == null) {
      // Empty ground: the tab springs back (a missed tap for the hand).
      _hints.missTap();
      return;
    }
    if (_atHisSite && holdForCoworker()) return;
    final (res, m) = _run.drop(part, reg);
    switch (res) {
      case M7TagDrop.already:
        _tick();
      case M7TagDrop.needless || M7TagDrop.wrongReg:
        setState(() => _wake++);
        unawaited(_levelDelta(-10, global, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M7TagDrop.pinned:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _stepDone();
        if (_run.reasonDue(reg)) {
          _hush();
          putOnTable(15);
          final idx = _run.index;
          unawaited(askReason(
            deal: () => dealChoices(M7RuleTagLines.whyRight[reg]!, M7RuleTagLines.whyWrong(reg), widget.rng),
            question: M7RuleTagLines.whyQ(reg),
            stillValid: () => _run.index == idx && !_ended,
          ));
        } else {
          unawaited(_levelDelta(10, global, mood: GuideMood.glad));
        }
    }
  }

  void _sign(Offset global) {
    if (!_canPlay) return;
    if (_atHisSite && !coworkerDone) {
      if (!coworkerDue) scheduleCoworker();
      if (holdForCoworker()) return;
    }
    _hush();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    final missed = _run.sign();
    setState(() {
      _signed.add(_run.index);
      _wake++;
    });
    if (missed.isEmpty) {
      unawaited(_goNext());
      return;
    }
    unawaited(_levelDelta(-10 * missed.length, global, mood: GuideMood.warn));
    _cardQueue
      ..clear()
      ..addAll(missed.skip(1));
    _afterCards = () => unawaited(_goNext());
    unawaited(_slip(missed.first));
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
      _startSite();
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
    _startSite();
  }

  void _longStart(Offset p, M7TagGeo geo) {
    if (!_canPlay || _drag != null) return;
    final tab = _tabAt(p, geo);
    if (tab != null) {
      _tick();
      setState(() => _held = tab);
      return;
    }
    if (geo.spine.contains(p)) {
      _tick();
      setState(() => _spineHeld = true);
      return;
    }
    _hints.missTap();
  }

  void _longEnd() {
    if (_held == null && !_spineHeld) return;
    setState(() {
      _held = null;
      _spineHeld = false;
    });
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
    // The same site goes on (more may be broken; nothing says how many).
    if (mounted) setState(() => _wake++);
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7RuleTagLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.done || _run.index > _run.deal.coworkerSite || _signed.contains(_run.deal.coworkerSite)) return null;
    if (!_atHisSite || _intro || _card != null || tableBusy || _panning || _drag != null || _held != null || _spineHeld) return false;
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
    _run.caught.add(M7RuleTagLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7RuleTagLines.callHeld, M7RuleTagLines.askSite], mood: GuideMood.glad));
  }

  /// Tap the guide: the next task line of the pool, from the start.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7RuleTagLines.tapWhy[_whyN++ % M7RuleTagLines.tapWhy.length]
            : M7RuleTagLines.tasks[++_taskN % M7RuleTagLines.tasks.length];
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
      _drag = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7tag/${m.key}');
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
    unawaited(_sayChain([M7RuleTagLines.askSite]));
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
    await _say(!_run.passed ? M7RuleTagLines.fail : (_quickBonus ? M7RuleTagLines.quick : M7RuleTagLines.allSet),
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
    if (_drag != null || _held != null || _spineHeld) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. In turn: a sweep over every
  /// checkable part of the site alike, a short drag up from the booklet's
  /// centre (between two tabs), a hold on the booklet's spine.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final s = _run.site;
    final n = _siteHintN++;
    return switch (n % 3) {
      0 => HintSpec.sweep([for (final p in s.parts) geo.partRect(s.kind, p, mirror: s.mirror)], space: HintSpace.scene),
      1 => HintSpec.drag(geo.bookCentre, toward: const Offset(0, -1), travel: 64, space: HintSpace.scene),
      _ => HintSpec.hold(geo.spine.center, space: HintSpace.scene),
    };
  }

  Widget _siteLayer(M7TagGeo geo, int i, {required bool showTags}) {
    final s = _run.deal.sites[i];
    return Stack(
      children: [
        Positioned.fill(
          key: const ValueKey('site-art'),
          child: RepaintBoundary(child: CustomPaint(painter: M7TagSitePainter(geo: geo, site: s))),
        ),
        if (showTags)
          for (final p in _run.pinned)
            Positioned(
              key: ValueKey('pin-$i-${p.name}'),
              left: geo.tagAt(s.kind, p, mirror: s.mirror).dx - 34,
              top: geo.tagAt(s.kind, p, mirror: s.mirror).dy - 9,
              width: 68,
              child: IgnorePointer(child: _RedTag(text: M7RuleTagLines.tag(m7TagRegOf(p)))),
            ),
      ],
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7TagGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final idx = math.min(_run.index, _run.deal.sites.length - 1);
    final from = _from;
    return [
      Positioned.fill(
        key: const ValueKey('back'),
        child: RepaintBoundary(child: CustomPaint(painter: M7TagBackPainter(geo: geo, light: _run.deal.light))),
      ),
      if (_panning && from != null)
        Positioned.fill(
          key: ValueKey('pan-$idx'),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeInOut,
            onEnd: _panDone,
            child: _siteLayer(geo, idx, showTags: false),
            builder: (_, v, child) => Stack(
              children: [
                Positioned.fill(left: -360 * v, right: 360 * v, child: _siteLayer(geo, from, showTags: false)),
                Positioned.fill(left: 360 * (1 - v), right: -360 * (1 - v), child: child!),
              ],
            ),
          ),
        )
      else
        Positioned.fill(key: ValueKey('site-$idx'), child: _siteLayer(geo, idx, showTags: true)),
      // The register and the trainee on the pavement.
      Positioned.fromRect(
        key: const ValueKey('register'),
        rect: geo.register,
        child: _Register(signed: _signed.contains(_run.index) && !_panning),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // The pocket rulebook.
      Positioned.fromRect(
        key: const ValueKey('book'),
        rect: geo.book,
        child: _Booklet(geo: geo, lifted: _drag, held: _held),
      ),
      if (_held != null || _spineHeld)
        Positioned(
          key: ValueKey('rule-${_held?.name ?? 'all'}'),
          left: 10,
          right: 10,
          bottom: m.height - geo.bookTop + 6,
          child: IgnorePointer(child: _RuleCard(regs: _held == null ? M7TagReg.values : [_held!])),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7RuleTagLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: () {
              if (_drag != null) setState(() => _drag = null);
              _signFrom = null;
            },
            onLongPressStart: (d) => _longStart(d.localPosition, geo),
            onLongPressEnd: (_) => _longEnd(),
            onLongPressCancel: _longEnd,
          ),
        ),
      ),
      // The tab in hand, its pin at the finger's tip.
      if (_drag != null)
        Positioned(
          key: const ValueKey('drag-tag'),
          left: _dragAt.dx - 34,
          top: _dragAt.dy - 22,
          width: 68,
          child: IgnorePointer(child: _RedTag(text: M7RuleTagLines.tag(_drag!), lifted: true)),
        ),
      // The next site: a short fade in reduced motion.
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_panning && !deckUp && !coworkerOpen && _card == null && !_run.done;
    // The guide stands just above the rulebook (screen px).
    final guideBottom = M7TagGeo.bookH * size.width / 360 + pad.bottom * 0.6 + 2;
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
              labels: [for (final s in _run.deal.sites) M7RuleTagLines.siteName(s.kind)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _drag == null && _held == null && !_spineHeld,
            hintKey: '${_run.index}/$_steps/${_run.slips}',
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
                  line: M7RuleTagLines.intro,
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

/// A red regulation tag (pinned on a part, or in hand while dragged).
class _RedTag extends StatelessWidget {
  const _RedTag({required this.text, this.lifted = false});
  final String text;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFFFE3E0), width: 1),
            boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 8 : 3, offset: Offset(0, lifted ? 4 : 1))],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, softWrap: false, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
          ),
        ),
        // The pin.
        Container(width: 2, height: 8, color: const Color(0xFF5B1010)),
      ],
    );
  }
}

/// The pocket CEA rulebook: a spine and four fixed tabs in booklet order,
/// all alike (the lifted one dims in the book while it is in hand).
class _Booklet extends StatelessWidget {
  const _Booklet({required this.geo, required this.lifted, required this.held});
  final M7TagGeo geo;
  final M7TagReg? lifted;
  final M7TagReg? held;

  @override
  Widget build(BuildContext context) {
    final b = geo.book;
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
        // The spine (hold it: all four rules).
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: geo.spine.width,
          child: Semantics(
            label: 'CEA রুলবুক',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0E1A2E),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                border: Border(right: BorderSide(color: SlmColors.gold300.withValues(alpha: 0.6))),
              ),
              child: const Center(
                child: RotatedBox(quarterTurns: 3, child: Text('CEA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE9C46A), letterSpacing: 2))),
              ),
            ),
          ),
        ),
        for (final r in M7TagReg.values)
          Positioned(
            left: geo.tab(r).left - b.left,
            top: geo.tab(r).top - b.top,
            width: geo.tab(r).width,
            height: geo.tab(r).height,
            child: Semantics(
              label: M7RuleTagLines.tabLabel(r),
              child: Opacity(
                opacity: lifted == r ? 0.35 : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: held == r ? const Color(0xFFFFF6DA) : const Color(0xFFF7F1DE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF8A6A3C), width: 1.4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, child: Text(M7RuleTagLines.regWord, style: bangla(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF6A5232)))),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(M7RuleTagLines.regNo(r), maxLines: 1, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
                        ),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(M7RuleTagLines.regName(r), maxLines: 1, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF8A2A16)))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A held tab's rule (or all four, the spine held) above the booklet.
class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.regs});
  final List<M7TagReg> regs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF20B1324),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in regs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${M7RuleTagLines.tag(r)}: ', style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
                    TextSpan(text: M7RuleTagLines.rule(r), style: bangla(fontSize: 11, fontWeight: FontWeight.w600, color: SlmColors.ivory, height: 1.3)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The inspection register on its clipboard; a swipe across signs it.
class _Register extends StatelessWidget {
  const _Register({required this.signed});
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M7RuleTagLines.registerWord,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF8A6A3C),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
              ),
            ),
          ),
          Positioned.fill(
            left: 5,
            right: 5,
            top: 10,
            bottom: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFF7F1DE), borderRadius: BorderRadius.circular(3)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(M7RuleTagLines.registerWord, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16))),
                    ),
                    Expanded(child: CustomPaint(painter: _LinesPainter())),
                    SizedBox(
                      height: 22,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 3,
                            child: Container(height: 1, color: const Color(0xFF8A6A3C)),
                          ),
                          Positioned(
                            left: 0,
                            bottom: 4,
                            child: Text(M7RuleTagLines.signHere, style: bangla(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF8A6A3C))),
                          ),
                          if (signed) Positioned.fill(child: CustomPaint(painter: _SignaturePainter())),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // The clip.
          Positioned(
            top: -4,
            left: 0,
            right: 0,
            child: Center(child: Container(width: 28, height: 10, decoration: BoxDecoration(color: const Color(0xFF9AA2A8), borderRadius: BorderRadius.circular(3)))),
          ),
        ],
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0x553A2A16)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.22);
      c.drawLine(Offset(2, y), Offset(size.width - (i.isOdd ? 14 : 4), y), p);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => false;
}

class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1F3F8F)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(14, size.height - 6);
    for (var i = 0; i < 5; i++) {
      final x = 18.0 + i * (size.width - 24) / 5;
      path.quadraticBezierTo(x, i.isEven ? 2 : size.height - 2, x + (size.width - 24) / 10, size.height / 2);
    }
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => false;
}
