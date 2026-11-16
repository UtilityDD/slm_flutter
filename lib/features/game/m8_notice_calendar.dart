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
import 'm8_notice_calendar_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_notice_calendar_world.dart'
    show M8Deal, M8Geo, M8House, M8Kind, M8Label, M8Receipt, M8Tile, kM8Dow, kM8Months, kM8MonthsShort, kM8Skies, m8Answer, m8DateText, m8DealHouse, m8DealPlay, m8GridStart, m8IsAct, m8Live, m8PlannerStart;

// Lesson 8.2 "সাপ্লাই কোড (Supply Code): গ্রাহক পরিষেবার নিয়মাবলী", কাজ
// "দিন গুনুন, তারপর কাটুন" (pack do_8_2_a, rung 8.2/do/0, engineType
// m8_notice_calendar).
//
// A morning residential lane: three houses dealt from six, one at a time.
// Each house's paper (the docket) opens with plain dates among decoys; a paper
// wall calendar hangs under it (a rolling ten-week month grid for the arrears
// houses, a 12-month year planner for the cut lines).
//
// The core verb: drag a ribbon across the calendar from the date you choose to
// 'আজ'. Only a neutral running count shows ('N দিন'): no mark at 15 or 180,
// the same colour at every length. Re-measuring is free. Once a count is made
// the decision tiles rise (equal size and colour, dealt order; a tile opens
// big and only its ✓ answers, playbook 1.4):
//   live line  → 'লাইন কাটুন' · 'এখন নয়'
//   cut line   → 'জুড়ে দিন' · 'খুলে স্টোরে' · 'এখন নয়'
// The right decision depends on the dates and the receipt, never on the tiles:
//   written notice 15+ clear days ago        → cut (notebook, then hold)
//   no written notice, or fewer than 15 days → hold
//   dues AND reconnection charge on the receipt → reconnect (the receipt is
//     tapped open first, then the tile works)
//   cut 180+ days ago and nothing paid        → dismantle (meter and wire to
//     the store crate, not the consumer's verandah)
//   any other cut line                        → hold
// Cut: the notebook slides up: roll 5 digit wheels to the meter's counter, tap
// a seal chip, press 'নোট হলো'; then HOLD the disconnect control. Holding it
// with no note = a slip.
//
// Every mistake is a SLIP (ruling M8-1: law and paperwork, nobody exposed; no
// deadly row on this level). Needless 'এখন নয়' on a valid act is a slip; a
// wrong card in a field decision deck is a slip; a wrong 'why' card costs the
// table ◆ only (M8-8). A wrong decision resolves to the right state after its
// card (no ◆, no reason for that house). Three slips strike out.
//
// The coworker (the two lesson myths word for word, M8-14, and a pity line):
// once a play at a dealt house (no/short-notice, a cut-line hold, or a paid
// reconnection). The first count at his house calls him; the tiles wait for
// him (holdForCoworker). Listening = a slip (X2/B1: nothing here is deadly).
//
// Gesture hands (how, never what): docket — tap; calendar — a short drag along
// a middle row from a cell that is no docket date; tiles — a sweep over all;
// receipt — a tap; notebook — a swipe up on the first wheel, a sweep over both
// seal chips, a tap on 'নোট হলো' only when it is the last control; disconnect
// — a hold; dismantle — a straight-up nudge on the meter, a sweep over both
// pads. Off during the intro, the fade between houses, the praise window, the
// coworker, cards and results.

// ============================================================================
// Content
// ============================================================================

/// Which reason deck a finished house asks.
enum M8Why { holdNoNotice, holdShort, cut, note, reconnect, notReconnect, notDismantle, crate }

abstract final class M8NoticeLines {
  static const title = 'দিন গুনুন, তারপর কাটুন';
  // DRAFT wording — owner (M6-12 / M8-14): every line below until the owner
  // gives the natural wording.
  static const intro = 'আজ তিনটে বাড়ি — কাগজ মিলিয়ে, দিন গুনে কাজ।';

  // The guide's tasks per stage (tap him: the next of the stage's pool).
  static const askDocketFirst = 'প্রথম বাড়ির কাগজ খুলুন।';
  static const askDocket = 'এই বাড়ির কাগজ খুলুন।';
  static const askCount = 'কাগজের তারিখ ধরে আজ পর্যন্ত দিন গুনুন।';
  static const askDecide = 'দিন গুনেছেন — এবার কী করবেন?';
  static const askNote = 'কাটার আগের কাজটা সারুন।';
  static const askCrate = 'মিটার আর তার কোথায় রাখবেন?';
  static const tapDocket = 'কাগজটা খুলে দেখুন, কী লেখা আছে।';
  static const tapCount = 'ক্যালেন্ডারে আঙুল টেনে দিন মেপে নিন।';
  static const tapDecide = 'কাগজ আর দিনের হিসাব মিলিয়ে ঠিক করুন।';
  static const tapNote = 'মিটার দেখে খাতা ভরুন।';
  static const tapCrate = 'দুটো জিনিসই ঠিক জায়গায় পৌঁছে দিন।';
  static const docketPool = [askDocket, tapDocket];
  static const countPool = [askCount, tapCount];
  static const decidePool = [askDecide, tapDecide];
  static const notePool = [askNote, tapNote];
  static const cratePool = [askCrate, tapCrate];
  static const tasks = [askDocketFirst, askDocket, tapDocket, askCount, tapCount, askDecide, tapDecide, askNote, tapNote, askCrate, tapCrate];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The calendar, docket and tiles (words a worker reads; English digits).
  static const todayWord = 'আজ';
  static String count(int n) => enDigits('$n দিন');
  static const docketWord = 'ডকেট';
  static const calendarWord = 'দেয়াল ক্যালেন্ডার';
  static const tileCut = 'লাইন কাটুন';
  static const tileHold = 'এখন নয়';
  static const tileReconnect = 'জুড়ে দিন';
  static const tileDismantle = 'খুলে স্টোরে';
  static String tile(M8Tile t) => switch (t) {
        M8Tile.cut => tileCut,
        M8Tile.hold => tileHold,
        M8Tile.reconnect => tileReconnect,
        M8Tile.dismantle => tileDismantle,
      };
  static String label(M8Label l) => switch (l) {
        M8Label.bill => 'বিলের তারিখ',
        M8Label.notice => 'লিখিত নোটিশ',
        M8Label.spoken => 'নোটিশ',
        M8Label.cut => 'লাইন কাটা',
        M8Label.reading => 'মিটার রিডিং',
      };
  static const spokenNotice = 'মুখে জানানো হয়েছে';
  static String entryValue(M8House h, M8Label l) => l == M8Label.spoken ? spokenNotice : m8DateText(h.dateOf(l)!);
  static String entryText(M8House h, M8Label l) => '${label(l)} ${entryValue(h, l)}';

  // The receipt (two printed lines: amounts, never a verdict word).
  static const receiptWord = 'রসিদ';
  static String duesLine(M8House h) => enDigits('বকেয়া বিল ₹${h.due} · জমা ₹${h.paid}');
  static String chargeLine(M8House h) =>
      h.receipt == M8Receipt.chargeBlank ? 'রিকানেকশন চার্জ · ————' : enDigits('রিকানেকশন চার্জ · রসিদ নং ${h.receiptNo}');

  // The notebook and the controls.
  static const notebookWord = 'মিটারের খাতা';
  static const readingWord = 'রিডিং';
  static const sealOk = 'সীল ঠিক';
  static const sealBroken = 'সীল ভাঙা';
  static const noted = 'নোট হলো';
  static const discWord = 'সংযোগ কাটা';
  static const meterWord = 'মিটার';
  static const coilWord = 'সার্ভিস তার';
  static const crateWord = 'স্টোর ক্রেট';
  static const verandaWord = 'বারান্দা';
  static const sceneLabel = 'বাড়ির সামনে';
  static String houseName(int i) => const ['প্রথম বাড়ি', 'দ্বিতীয় বাড়ি', 'তৃতীয় বাড়ি'][i];

  static const noteDone = 'নোট হয়ে গেছে — এবার কাটুন।';

  // The reasons (the right ones state the lesson's rule for what was just
  // done; the wrong ones are field excuses and myths; all within 1.3x).
  static const whyQ = <M8Why, String>{
    M8Why.holdNoNotice: 'কেন আজ লাইন কাটলেন না?',
    M8Why.holdShort: 'কেন আজ লাইন কাটলেন না?',
    M8Why.cut: 'কেন লাইন কাটলেন?',
    M8Why.note: 'কাটার আগে কেন রিডিং আর সীল লিখলেন?',
    M8Why.reconnect: 'কেন লাইন জুড়ে দিলেন?',
    M8Why.notReconnect: 'কেন লাইন জুড়লেন না?',
    M8Why.notDismantle: 'কেন এখনই মিটার খুললেন না?',
    M8Why.crate: 'কেন মিটার আর তার স্টোরে দিলেন?',
  };
  static const whyRight = <M8Why, List<String>>{
    M8Why.holdNoNotice: ['লিখিত নোটিশ ছাড়া সাধারণ বকেয়ায় লাইন কাটা যায় না', 'সেকশন 56 অনুযায়ী 15 দিনের লিখিত নোটিশ বাধ্যতামূলক'],
    M8Why.holdShort: ['15 দিনের ক্লিয়ার নোটিশ পিরিয়ড এখনও শেষ হয়নি', 'নোটিশের মেয়াদ পূর্ণ হওয়ার আগে লাইন কাটা যায় না'],
    M8Why.cut: ['লিখিত নোটিশের 15 দিন পুরো হয়েছে, বকেয়া মেটেনি', 'নোটিশ পিরিয়ড শেষ, তাই নিয়ম মেনে লাইন কাটা যায়'],
    M8Why.note: ['কাটার আগে মিটারের রিডিং আর সীলের অবস্থা নোট করতে হয়', 'নিয়ম মেনে কাটার আগে রিডিং আর সীলের হিসাব রাখতে হয়'],
    M8Why.reconnect: ['গ্রাহক পুরো টাকা আর রিকানেকশন চার্জ জমা দিয়েছেন', 'রসিদে বকেয়া আর চার্জ দুটোই জমা, তাই লাইন জোড়া যায়'],
    M8Why.notReconnect: ['পুরো টাকা আর রিকানেকশন চার্জ জমা না দিলে জোড়া যায় না', 'রসিদে টাকা বা চার্জ বাকি, তাই লাইন জোড়া চলে না'],
    M8Why.notDismantle: ['লাইন কাটার পর 180 দিন পার না হলে খোলা যায় না', '180 দিন (6 মাস) পূর্ণ না হলে লাইন খোলা চলে না'],
    M8Why.crate: ['180 দিন পরেও টাকা না মেলায় সব স্টোরে জমা দিতে হয়', 'সার্ভিস তার আর মিটার সবকিছু স্টোরে জমা দেওয়াই নিয়ম'],
  };
  static const myths = [
    'একজনের জন্য নিয়ম একটু বাঁকালে কিছু হয় না',
    'সবাই যেমন করে, আমরাও তেমনই করি, এতে দোষ নেই',
    'এসব নিয়ম শুধু কাগজে থাকে, মাঠে কেউ মানে না',
    'ওপরওয়ালা না বললে নিয়ম দেখার কোনো দরকার নেই',
  ];
  static const _wrongBy = <M8Why, List<String>>{
    M8Why.holdNoNotice: ['মুখের কথাই যথেষ্ট, তবে আজ আমার একটু সময় নেই', 'বিল বাকি থাকলে কাটা যায়, তবে আজ ছুটির মেজাজ'],
    M8Why.holdShort: ['বিলের তারিখ থেকে অনেকদিন হয়ে গেছে, তবু ছাড় দিলাম', 'গ্রাহক আমার চেনা লোক, তাই আজ আর লাইন কাটলাম না'],
    M8Why.cut: ['বিল অনেকদিন বাকি, তাই নোটিশ ধরার দরকার হয় না', 'ওপর থেকে চাপ ছিল, তাই চটপট লাইন কেটে দিলাম'],
    M8Why.note: ['নোট করলে কাজ তাড়াতাড়ি হয়, তাই লিখে রাখলাম', 'অফিসে খাতা দেখাতে হবে বলেই শুধু লিখে নিলাম'],
    M8Why.reconnect: ['রসিদ আছে মানেই জুড়তে হয়, বাকি কিছু দেখার নেই', 'গ্রাহক খুব অনুরোধ করলেন, তাই জুড়ে দিলাম আজ'],
    M8Why.notReconnect: ['গ্রাহকের কথা শোনা আমাদের কাজ নয়, তাই জুড়িনি', 'আজ জুড়লে কাল আবার বিল বাকি পড়বে, তাই জুড়িনি'],
    M8Why.notDismantle: ['মিটার খুললে গ্রাহক চেঁচামেচি করবে, তাই এখন নয়', 'আজ গাড়ি ভরা, তাই মিটার খুলে রাখার জায়গা নেই'],
    M8Why.crate: ['গ্রাহকের বারান্দায় রাখলে পরে সে নিজেই পৌঁছে দেবে', 'মিটার নিজের কাছে রাখলে পরে কাজে লাগতে পারে'],
  };

  /// The wrong reasons for [w] (≥ 5: its own excuses + the myths).
  static List<String> whyWrong(M8Why w) => [..._wrongBy[w]!, ...myths];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in _wrongBy.values) ...l, ...myths];

  // The careless coworker: lesson myths word for word (M8-14) and a pity line.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerNoNotice = CoworkerScript(
    line: 'বিল বাকি থাকলে নোটিশ ছাড়াই লাইন কাটা যায়।',
    exitLine: coworkerExit,
    right: [
      'না, সেকশন 56 অনুযায়ী 15 দিনের লিখিত নোটিশ লাগে',
      'ভুল কথা, লিখিত নোটিশ ছাড়া সাধারণ বকেয়ায় কাটা যায় না',
      'নোটিশের 15 দিন পুরো না হলে আমি লাইনে হাত দেব না',
    ],
    wrong: [
      'নোটিশ না থাকলে আরও ভালো, কেটে দিই আর ছুটি পাই',
      'তুমি বললে যখন, নোটিশ ছাড়াই আজ কেটে দিচ্ছি ভাই',
      'ঠিক, নোটিশ তো শুধু কাগজের নিয়ম, কেটেই ফেলি ভাই',
      'ঠিক বলেছ, নোটিশ-টোটিশ পরে হবে, এখনই কেটে দিই',
      'হ্যাঁ, বিল বাকি মানেই কাটা যায়, নোটিশ লাগে না',
    ],
    asks: _asks,
  );
  static const coworkerPity = CoworkerScript(
    line: 'বেচারা কাঁদছে, বাকি টাকা পরে দেবে — জুড়ে দাও।',
    exitLine: coworkerExit,
    right: [
      'দুঃখ হচ্ছে, কিন্তু পুরো টাকা-চার্জ ছাড়া জোড়া যায় না',
      'পুরো টাকা আর রিকানেকশন চার্জ জমা না হলে জুড়ব না',
      'দয়া করে জুড়লে আমিই বিপদে পড়ব, নিয়ম মানতেই হবে',
    ],
    wrong: [
      'কাঁদছে যখন, জুড়েই দিই ভাই, পরে দেখা যাবে সব',
      'ঠিক, একটু দয়া দেখালে কেউ কিছু বলবে না ভাই',
      'টাকা পরে আসবে বলছে, তাই এখনই জুড়ে দিই ভাই',
      'হ্যাঁ, বাকি টাকা পরে দিলেও চলবে, জুড়ে দিই',
      'ঠিক বলেছ, বেচারার জন্য আজ নিয়মটা একটু বাঁকাই',
    ],
    asks: _asks,
  );
  static const coworkerMeter = CoworkerScript(
    line: 'লাইনম্যান চাইলেই যেকোনো সময় গ্রাহকের মিটার শিফট বা সরাতে পারে।',
    exitLine: coworkerExit,
    right: [
      'না, মিটার সরাতে নির্দিষ্ট ফি জমা আর ফিজিবিলিটি চেক লাগে',
      'বিনা অর্ডারে মিটার সরালে চুরির দায় আমারই ঘাড়ে আসবে',
      'আগে ফি জমা আর নতুন জায়গা দেখা, তারপর মিটার সরানো',
    ],
    wrong: [
      'ঠিক বলেছ, ফিজিবিলিটি-টিজিবিলিটি পরে দেখব, সরাই',
      'গ্রাহক বললেই মিটার সরানো যায়, ঝামেলা কীসের ভাই',
      'ঠিক, গ্রাহকের সুবিধার জন্য মিটার সরিয়েই দিই ভাই',
      'আমরা চাইলেই মিটার সরাতে পারি, অর্ডার লাগে না',
      'হ্যাঁ, ফি-টি পরে দেখা যাবে, মিটারটা এখনই সরাই',
    ],
    asks: _asks,
  );
  static const _asks = ['ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];
  static const scripts = [coworkerNoNotice, coworkerPity, coworkerMeter];

  /// The script he speaks at a house of [k].
  static CoworkerScript coworkerFor(M8Kind k) => switch (k) {
        M8Kind.shortNotice || M8Kind.noNotice => coworkerNoNotice,
        M8Kind.recentCut => coworkerPity,
        _ => coworkerMeter,
      };
  static const callHeld = 'ঠিক! আগে নিয়ম, তারপর কাজ।';

  static const allSet = 'তিনটে বাড়ির কাজ শেষ — নিয়ম মেনে, দিন গুনে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কাগজ দেখে, দিন গুনে তবেই কাজ।';

  // "আজ যা ধরলেন".
  static String caught(M8Kind k) => switch (k) {
        M8Kind.shortNotice => 'নোটিশের 15 দিন পূর্ণ হয়নি, তাই লাইন কাটেননি',
        M8Kind.longNotice => 'নোটিশ পেরিয়েছে, রিডিং আর সীল লিখে লাইন কেটেছেন',
        M8Kind.noNotice => 'লিখিত নোটিশ ছাড়া লাইন কাটেননি',
        M8Kind.recentCut => 'টাকা আর চার্জ ছাড়া লাইন জোড়েননি, মিটার খোলেননি',
        M8Kind.oldCut => '180 দিন পরে মিটার আর তার স্টোরে জমা দিয়েছেন',
        M8Kind.paidCut => 'পুরো টাকা আর চার্জ দেখে লাইন জুড়েছেন',
      };
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip.
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', quick};
  static const _oldWhyTaps = {'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final s in scripts) s.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        ...tapWhy.where((l) => !_oldWhyTaps.contains(l)),
        ...{...whyQ.values},
        ...coworkerNoNotice.asks.where((a) => !reused.contains(a)),
        callHeld,
        noteDone,
        allSet,
        fail,
        for (final m in M8NoticeMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused, ...tapWhy];
}

abstract final class M8NoticeMistakes {
  static const _dir = 'assets/game/art/m8_notice_calendar';
  static const _k = '8.2/m8_notice_calendar';

  /// Lesson 8.2 point 3 (0-based 2: বকেয়া বিলের নিয়ম) holds the 15-day
  /// notice, the reading and seal note and the reconnection rule; point 4
  /// (0-based 3: ডিসম্যান্টলিং) the 180 days.
  static const _notice = 2;
  static const _dismantle = 3;

  // DRAFT wording — owner (M6-12). Cutting.
  static const cutNoNotice = DoMistake(
    key: '$_k/cut-no-notice',
    textBn: 'বিল বাকি থাকলেও সাধারণ বকেয়ায় 15 দিনের লিখিত নোটিশ বাধ্যতামূলক — নোটিশ ছাড়া লাইন কাটা যায় না।',
    art: '$_dir/notice.svg',
    lessonPoint: _notice,
  );
  static const cutShort = DoMistake(
    key: '$_k/cut-short',
    textBn: 'নোটিশের 15 দিনের ক্লিয়ার পিরিয়ড শেষ হয়নি — তার আগে সাধারণ বকেয়ার জন্য লাইন কাটা যায় না।',
    art: '$_dir/notice.svg',
    lessonPoint: _notice,
  );
  static const holdCut = DoMistake(
    key: '$_k/hold-cut',
    textBn: 'লিখিত নোটিশের 15 দিন পার হয়ে গেছে আর বকেয়া মেটেনি — এবার নিয়ম মেনে লাইন কাটতে হয়।',
    art: '$_dir/calendar.svg',
    lessonPoint: _notice,
  );

  // The notebook before the cut.
  static const noNote = DoMistake(
    key: '$_k/no-note',
    textBn: 'লাইন কাটার আগে মিটারের বর্তমান রিডিং আর সীলের অবস্থা নোট করে নিতে হয়।',
    art: '$_dir/notebook.svg',
    lessonPoint: _notice,
  );
  static const noteReading = DoMistake(
    key: '$_k/note-reading',
    textBn: 'রিডিং মেলেনি — কাটার আগে মিটারের বর্তমান রিডিং ঠিকঠাক নোট করতে হয়।',
    art: '$_dir/meter.svg',
    lessonPoint: _notice,
  );
  static const noteSeal = DoMistake(
    key: '$_k/note-seal',
    textBn: 'সীলের অবস্থা মেলেনি — মিটারের সীল যেমন আছে তেমনই নোট করতে হয়।',
    art: '$_dir/meter.svg',
    lessonPoint: _notice,
  );

  // Reconnecting.
  static const reconnectPart = DoMistake(
    key: '$_k/reconnect-part',
    textBn: 'বকেয়ার টাকা পুরো জমা পড়েনি — লাইন জুড়তে পুরো টাকা আর রিকানেকশন চার্জ লাগে। দয়া করে জুড়ে দিলে আপনিই বিপদে পড়বেন।',
    art: '$_dir/receipt.svg',
    lessonPoint: _notice,
  );
  static const reconnectNoCharge = DoMistake(
    key: '$_k/reconnect-no-charge',
    textBn: 'রিকানেকশন চার্জ জমা পড়েনি — লাইন জুড়তে পুরো টাকা আর রিকানেকশন চার্জ লাগে। দয়া করে জুড়ে দিলে আপনিই বিপদে পড়বেন।',
    art: '$_dir/receipt.svg',
    lessonPoint: _notice,
  );
  static const reconnectNoPay = DoMistake(
    key: '$_k/reconnect-no-pay',
    textBn: 'টাকা জমা না দিলে লাইন জোড়া যায় না — পুরো টাকা আর রিকানেকশন চার্জ জমা দিতে হবে। দয়া করে জুড়ে দিলে আপনিই বিপদে পড়বেন।',
    art: '$_dir/receipt.svg',
    lessonPoint: _notice,
  );
  static const holdReconnect = DoMistake(
    key: '$_k/hold-reconnect',
    textBn: 'পুরো টাকা আর রিকানেকশন চার্জ জমা পড়ে গেছে — এখন নিয়ম মেনে লাইন জুড়ে দেওয়া যায়।',
    art: '$_dir/receipt.svg',
    lessonPoint: _notice,
  );

  // Dismantling.
  static const dismantleEarly = DoMistake(
    key: '$_k/dismantle-early',
    textBn: 'লাইন কাটার পর 180 দিন (6 মাস) পার না হলে লাইন পার্মানেন্টলি খোলা যায় না।',
    art: '$_dir/calendar.svg',
    lessonPoint: _dismantle,
  );
  static const dismantlePaid = DoMistake(
    key: '$_k/dismantle-paid',
    textBn: 'গ্রাহক পুরো টাকা আর রিকানেকশন চার্জ জমা দিয়েছেন — তাঁর লাইন খোলার কথা নয়, জুড়ে দিতে হয়।',
    art: '$_dir/receipt.svg',
    lessonPoint: _notice,
  );
  static const holdDismantle = DoMistake(
    key: '$_k/hold-dismantle',
    textBn: 'লাইন কাটার পর 180 দিন কেটে গেছে আর গ্রাহক টাকা দেননি — তখন সার্ভিস তার, মিটার সব খুলে স্টোরে জমা দিতে হয়।',
    art: '$_dir/crate.svg',
    lessonPoint: _dismantle,
  );
  static const crateWrong = DoMistake(
    key: '$_k/crate-wrong',
    textBn: 'সার্ভিস তার আর মিটার খুলে স্টোরে জমা দিতে হয় — গ্রাহকের বারান্দায় রেখে আসা চলে না।',
    art: '$_dir/crate.svg',
    lessonPoint: _dismantle,
  );

  // Listening to the coworker (lesson myths and their realities; X2/B1).
  static const pushNoNotice = DoMistake(
    key: '$_k/push-no-notice',
    textBn: 'ভুল! ইলেকট্রিসিটি অ্যাক্ট 2003-এর সেকশন 56 অনুযায়ী 15 দিনের লিখিত নোটিশ বাধ্যতামূলক। তবে চুরির ক্ষেত্রে (Sec 135) কোনো নোটিশ লাগে না।',
    art: '$_dir/notice.svg',
    lessonPoint: _notice,
  );
  static const pushPity = DoMistake(
    key: '$_k/push-pity',
    textBn: 'পুরো টাকা আর রিকানেকশন চার্জ জমা না দিলে লাইন জোড়া যায় না। দয়া করে লাইন জুড়ে দিলে আপনিই বিপদে পড়বেন।',
    art: '$_dir/receipt.svg',
    lessonPoint: _notice,
  );
  static const pushMeter = DoMistake(
    key: '$_k/push-meter',
    textBn: 'একদম না। মিটার শিফটিং-এর জন্য নির্দিষ্ট ফি জমা দিতে হয় আর নতুন জায়গার টেকনিক্যাল ফিজিবিলিটি চেক করতে হয়। বিনা অর্ডারে মিটার সরালে চুরির দায় আপনার ওপর আসতে পারে।',
    art: '$_dir/meter.svg',
  );

  static DoMistake push(M8Kind k) => switch (k) {
        M8Kind.shortNotice || M8Kind.noNotice => pushNoNotice,
        M8Kind.recentCut => pushPity,
        _ => pushMeter,
      };

  static const List<DoMistake> all = [
    cutNoNotice,
    cutShort,
    holdCut,
    noNote,
    noteReading,
    noteSeal,
    reconnectPart,
    reconnectNoCharge,
    reconnectNoPay,
    holdReconnect,
    dismantleEarly,
    dismantlePaid,
    holdDismantle,
    crateWrong,
    pushNoNotice,
    pushPity,
    pushMeter,
  ];
}

// ============================================================================
// Rules
// ============================================================================

/// The reason deck a finished house asks (the cut alternates with the note).
M8Why m8WhyFor(M8House h, {required bool noteWhy}) => switch (h.kind) {
      M8Kind.shortNotice => M8Why.holdShort,
      M8Kind.noNotice => M8Why.holdNoNotice,
      M8Kind.longNotice => noteWhy ? M8Why.note : M8Why.cut,
      M8Kind.recentCut => h.receipt == M8Receipt.none ? M8Why.notDismantle : M8Why.notReconnect,
      M8Kind.oldCut => M8Why.crate,
      M8Kind.paidCut => M8Why.reconnect,
    };

/// The play state (pure logic).
class M8NoticeRun {
  M8NoticeRun(this.deal);
  final M8Deal deal;

  int index = 0;
  int slips = 0;

  /// The reason decks asked this play (a repeat pays at once).
  final Set<M8Why> asked = {};
  final List<String> caught = [];

  M8House get house => deal.houses[index.clamp(0, deal.houses.length - 1)];
  bool get done => index >= deal.houses.length;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  M8Why get why => m8WhyFor(house, noteWhy: deal.noteWhy[index.clamp(0, deal.houses.length - 1)]);

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// A decision tile confirmed: right (null) or the slip.
  (bool, DoMistake?) decide(M8Tile t) {
    final h = house;
    if (t == h.answer) return (true, null);
    final m = switch (t) {
      M8Tile.cut => h.kind == M8Kind.noNotice ? M8NoticeMistakes.cutNoNotice : M8NoticeMistakes.cutShort,
      M8Tile.hold => switch (h.kind) {
          M8Kind.longNotice => M8NoticeMistakes.holdCut,
          M8Kind.oldCut => M8NoticeMistakes.holdDismantle,
          _ => M8NoticeMistakes.holdReconnect,
        },
      M8Tile.reconnect => switch (h.receipt) {
          M8Receipt.part => M8NoticeMistakes.reconnectPart,
          M8Receipt.chargeBlank => M8NoticeMistakes.reconnectNoCharge,
          _ => M8NoticeMistakes.reconnectNoPay,
        },
      M8Tile.dismantle => h.kind == M8Kind.paidCut ? M8NoticeMistakes.dismantlePaid : M8NoticeMistakes.dismantleEarly,
    };
    return (false, _slip(m));
  }

  /// The notebook: wrong digits and a wrong seal are a slip each.
  List<DoMistake> checkNote(List<int> digits, bool intact) {
    final h = house;
    return [
      if (digits.join() != h.counter) _slip(M8NoticeMistakes.noteReading),
      if (intact != h.sealIntact) _slip(M8NoticeMistakes.noteSeal),
    ];
  }

  DoMistake noNoteSlip() => _slip(M8NoticeMistakes.noNote);
  DoMistake crateSlip() => _slip(M8NoticeMistakes.crateWrong);
  DoMistake pushSlip() => _slip(M8NoticeMistakes.push(house.kind));

  bool reasonDue(M8Why w) => asked.add(w);

  void finishHouse() => caught.add(M8NoticeLines.caught(house.kind));
  void next() => index++;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per house: open the docket 2500, a count 5000 (read the dates, drag, a
///     re-measure), the tile 4500 (open, ✓) ≈ 12000
///   + the cut house's notebook and hold (~16000) and the dismantle's two
///     drags (~9000)                                            ≈ 25000
///   + a reason deck for the ~2.3 kinds met (2.3 × 8200)        ≈ 19000
///   + the coworker once                                        ≈  9600
///   3 × 12000 + 25000 × (≈ 0.9 of the plays) + 19000 + 9600    ≈ 88000
/// 85 % ≈ 75000 → 75 s (a builder's estimate; owner may tune after playtest).
const m8NoticeCalendarQuickMs = 75000;

@immutable
class M8NoticeCalendarPack {
  const M8NoticeCalendarPack({required this.id, required this.titleBn, this.quickMs = m8NoticeCalendarQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8NoticeCalendarPack> m8NoticeCalendarPacks = {
  'do_8_2_a': M8NoticeCalendarPack(id: 'do_8_2_a', titleBn: M8NoticeLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8NoticeProbe {
  static M8NoticeRun? run;

  /// The stage of the house on screen (docket, measure, note, crate).
  static String stage = '';
  static int? count;
  static bool measured = false;
  static bool noted = false;
}

enum _Stage { docket, measure, note, crate }

// ============================================================================
// Page
// ============================================================================

class M8NoticeCalendarPage extends StatefulWidget {
  const M8NoticeCalendarPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8NoticeCalendarPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8NoticeCalendarPage> createState() => _M8NoticeCalendarPageState();
}

class _M8NoticeCalendarPageState extends State<M8NoticeCalendarPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CalRunPage(
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

class _CalRunPage extends ConsumerStatefulWidget {
  const _CalRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8NoticeCalendarPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CalRunPage> createState() => _CalRunPageState();
}

class _CalRunPageState extends ConsumerState<_CalRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8NoticeRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

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
  String _poolKey = '';
  int _whyN = 0;
  int _steps = 0;
  int _hintN = 0;

  // The house on screen.
  var _stage = _Stage.docket;
  var _measured = false;
  var _decided = false;
  var _slippedHere = false;
  var _receiptOpen = false;
  var _receiptSeen = false;
  var _fading = false;
  DateTime? _rStart;
  Offset? _rFinger;
  int? _count;
  DateTime? _prevStart;
  int? _prevCount;
  var _calDown = false;
  M8Tile? _tilePreview;
  Offset _tileAt = Offset.zero;
  final Set<M8Tile> _tileAside = {};

  // The notebook.
  final List<int> _digits = [0, 0, 0, 0, 0];
  final List<double> _acc = [0, 0, 0, 0, 0];
  var _wheelTouched = false;
  bool? _seal;
  var _noted = false;
  var _cutting = false;
  var _held = false;

  // The dismantle.
  final Set<int> _crated = {};
  int? _item;
  Offset _itemAt = Offset.zero;

  final _hints = IdleHintController();
  M8Geo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M8NoticeRun(m8DealPlay(widget.rng));
    M8NoticeProbe.run = _run;
    _hold.addStatusListener((s) {
      if (s == AnimationStatus.completed) _discDone();
    });
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M8House get _house => _run.house;
  bool get _atHis => _run.index == _run.deal.hisHouse;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _hold.dispose();
    if (identical(M8NoticeProbe.run, _run)) M8NoticeProbe.run = null;
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_fading && !_run.done && !struckOut && !_cutting;

  List<String> get _pool => switch (_stage) {
        _Stage.docket => M8NoticeLines.docketPool,
        _Stage.measure => _measured ? M8NoticeLines.decidePool : M8NoticeLines.countPool,
        _Stage.note => M8NoticeLines.notePool,
        _Stage.crate => M8NoticeLines.cratePool,
      };

  String get _task => _stage == _Stage.docket && _run.index == 0 ? M8NoticeLines.askDocketFirst : _pool.first;

  Future<void> _start() async {
    _clock.start();
    _startHouse();
  }

  void _startHouse() {
    setState(() {
      _wake++;
      _hintN = 0;
    });
    unawaited(_sayChain([_task]));
  }

  void _stepDone() {
    _steps++;
    _hintN = 0;
    setState(() => _wake++);
  }

  // --- the docket and the count -----------------------------------------------
  void _openDocket() {
    if (!_canPlay || _stage != _Stage.docket) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _stage = _Stage.measure);
    _stepDone();
    unawaited(_sayChain([M8NoticeLines.askCount]));
  }

  void _calStart(Offset p, M8Geo geo) {
    _calDown = false;
    if (!_canPlay || _stage != _Stage.measure || _decided || _tilePreview != null || _receiptOpen) return;
    final d = geo.dateAt(_house, p);
    if (d == null || d.isAfter(_house.today)) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/tick.ogg', 0.35);
    _calDown = true;
    setState(() {
      _prevStart = _rStart;
      _prevCount = _count;
      _rStart = d;
      _rFinger = p;
      _count = _house.today.difference(d).inDays;
    });
  }

  void _calUpdate(Offset p) {
    if (!_calDown) return;
    if (!_canPlay) {
      _calLift();
      return;
    }
    setState(() => _rFinger = p);
  }

  /// The ribbon lifts without a count: the last measure (if any) comes back.
  void _calLift() {
    _calDown = false;
    setState(() {
      _rStart = _prevStart;
      _count = _prevCount;
      _rFinger = null;
    });
  }

  void _calEnd(M8Geo geo) {
    if (!_calDown) return;
    final s = _rStart;
    final f = _rFinger;
    if (s == null || f == null) {
      _calDown = false;
      return;
    }
    final from = geo.dateRect(_house, s)!.center;
    final today = geo.todayRect(_house).inflate(24);
    if (!_canPlay || (f - from).distance < 24 || !today.contains(f)) {
      // Short or off 'আজ': the ribbon lifts, no cost (a missed touch).
      _calLift();
      _hints.missTap();
      return;
    }
    _calDown = false;
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    HapticFeedback.mediumImpact();
    final first = !_measured;
    setState(() {
      _rFinger = null;
      _measured = true;
    });
    _stepDone();
    if (first) {
      // His house: the first count calls him in; the tiles wait for him.
      if (_atHis && !coworkerDone && !coworkerDue) scheduleCoworker();
      unawaited(_sayChain([M8NoticeLines.askDecide]));
    }
  }

  // --- the tiles ----------------------------------------------------------------
  /// A tap on a tile opens it big; nothing is answered yet.
  void _openTile(M8Tile t, Offset global) {
    if (!_canPlay || _stage != _Stage.measure || !_measured || _decided || _tilePreview != null || _receiptOpen) return;
    // His house: the tiles wait for him.
    if (_atHis && holdForCoworker()) return;
    // The receipt is tapped open first (a cut line with a consumer's paper).
    if (t == M8Tile.reconnect && _house.hasReceipt && !_receiptSeen) {
      _openReceipt();
      return;
    }
    _tick('sounds/intro/tick.ogg', 0.4);
    setState(() {
      _tilePreview = t;
      _tileAt = global;
      _wake++;
    });
  }

  void _rejectTile() {
    final t = _tilePreview;
    if (t == null) return;
    setState(() {
      _tilePreview = null;
      _tileAside.add(t);
    });
  }

  /// ✓ on the tile's preview: the decision (as one tap was before).
  void _confirmTile() {
    final t = _tilePreview;
    if (t == null) return;
    setState(() {
      _tilePreview = null;
      _tileAside.clear();
    });
    _decide(t, _tileAt);
  }

  void _openReceipt() {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _receiptOpen = true;
      _receiptSeen = true;
    });
    _stepDone();
  }

  void _closeReceipt() {
    if (!_receiptOpen) return;
    _tick();
    setState(() => _receiptOpen = false);
  }

  void _decide(M8Tile t, Offset origin) {
    if (!_canPlay || _decided) return;
    if (_atHis && holdForCoworker()) return;
    final (ok, m) = _run.decide(t);
    if (!ok) {
      _slippedHere = true;
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      _afterCards = () => _resolve(_house.answer);
      unawaited(_slip(m!));
      return;
    }
    _go(t);
  }

  /// The house goes on in the state the decision led to.
  void _go(M8Tile t) {
    switch (t) {
      case M8Tile.hold || M8Tile.reconnect:
        setState(() => _decided = true);
        _stepDone();
        _complete();
      case M8Tile.cut:
        _toNote();
      case M8Tile.dismantle:
        _toCrate();
    }
  }

  /// After a wrong decision's card: the house resolves to the correct state.
  void _resolve(M8Tile answer) {
    if (_ended) return;
    _go(answer);
  }

  void _toNote() {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _decided = true;
      _stage = _Stage.note;
      for (var i = 0; i < 5; i++) {
        _digits[i] = 0;
        _acc[i] = 0;
      }
      _wheelTouched = false;
      _seal = null;
      _noted = false;
    });
    _stepDone();
    unawaited(_sayChain([M8NoticeLines.askNote]));
  }

  void _toCrate() {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _decided = true;
      _stage = _Stage.crate;
      _crated.clear();
      _item = null;
    });
    _stepDone();
    unawaited(_sayChain([M8NoticeLines.askCrate]));
  }

  // --- the notebook and the cut -----------------------------------------------------
  void _wheelStep(int i, int d) {
    if (!_canPlay || _stage != _Stage.note || _noted) return;
    _tick('sounds/intro/tick.ogg', 0.3);
    setState(() {
      _digits[i] = (_digits[i] + d) % 10;
      if (_digits[i] < 0) _digits[i] += 10;
      _wheelTouched = true;
    });
  }

  void _wheelDrag(int i, double dy) {
    _acc[i] += dy;
    while (_acc[i] <= -18) {
      _acc[i] += 18;
      _wheelStep(i, 1);
    }
    while (_acc[i] >= 18) {
      _acc[i] -= 18;
      _wheelStep(i, -1);
    }
  }

  void _chip(bool intact) {
    if (!_canPlay || _stage != _Stage.note || _noted) return;
    _tick('sounds/intro/tick.ogg', 0.4);
    setState(() => _seal = _seal == intact ? null : intact);
  }

  void _noteSubmit() {
    if (!_canPlay || _stage != _Stage.note || _noted) return;
    final seal = _seal;
    if (seal == null) {
      _hints.missTap();
      return;
    }
    final ms = _run.checkNote(_digits, seal);
    _noted = true;
    if (ms.isEmpty) {
      _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
      HapticFeedback.mediumImpact();
      _stepDone();
      unawaited(_sayChain([M8NoticeLines.noteDone]));
      return;
    }
    // The notebook then shows the true entries.
    setState(() {
      for (var i = 0; i < 5; i++) {
        _digits[i] = _house.meter[i];
      }
      _seal = _house.sealIntact;
    });
    _slippedHere = true;
    unawaited(_levelDelta(-10 * ms.length, Offset(180, _geoNow?.notebook.top ?? 300), mood: GuideMood.warn));
    _cardQueue
      ..clear()
      ..addAll(ms.skip(1));
    _afterCards = () => unawaited(_sayChain([M8NoticeLines.noteDone]));
    _stepDone();
    unawaited(_slip(ms.first));
  }

  void _discDown() {
    if (!_canPlay || _stage != _Stage.note || _cutting) return;
    setState(() => _held = true);
    _hold.forward(from: 0);
  }

  void _discUp() {
    if (_cutting) return;
    if (_hold.isAnimating || _hold.value > 0) _hold.reset();
    if (_held) setState(() => _held = false);
  }

  void _discDone() {
    if (!mounted || _cutting || !_canPlay || _stage != _Stage.note) return;
    if (!_noted) {
      // The disconnect control held with no note: the slip.
      _hold.reset();
      setState(() => _held = false);
      _slippedHere = true;
      unawaited(_levelDelta(-10, Offset(180, _geoNow?.discBtn.top ?? 300), mood: GuideMood.warn));
      unawaited(_slip(_run.noNoteSlip()));
      return;
    }
    _cutting = true;
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() => _wake++);
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || _ended) return;
      setState(() => _held = false);
      _complete();
    }());
  }

  // --- the dismantle ------------------------------------------------------------------
  Rect _itemRect(int i, M8Geo geo) => i == 0 ? geo.meterItem : geo.coilItem;

  void _itemStart(Offset p, M8Geo geo) {
    _item = null;
    if (!_canPlay || _stage != _Stage.crate) return;
    for (final i in [0, 1]) {
      if (!_crated.contains(i) && _itemRect(i, geo).inflate(10).contains(p)) {
        _tick('sounds/intro/click.ogg', 0.4);
        setState(() {
          _item = i;
          _itemAt = p;
        });
        return;
      }
    }
    _hints.missTap();
  }

  void _itemMove(Offset p) {
    if (_item == null) return;
    if (!_canPlay) {
      setState(() => _item = null);
      return;
    }
    setState(() => _itemAt = p);
  }

  void _itemEnd(M8Geo geo) {
    final i = _item;
    if (i == null) return;
    final at = _itemAt;
    setState(() => _item = null);
    if (!_canPlay) return;
    final crateSide = _run.deal.crateLeft[_run.index] ? 0 : 1;
    final onCrate = geo.pad(crateSide).inflate(6).contains(at);
    final onVeranda = geo.pad(1 - crateSide).inflate(6).contains(at);
    if (onVeranda) {
      _slippedHere = true;
      unawaited(_levelDelta(-10, at, mood: GuideMood.warn));
      unawaited(_slip(_run.crateSlip()));
      return;
    }
    if (!onCrate) {
      // Dropped anywhere else: it springs back (a missed touch).
      _hints.missTap();
      return;
    }
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    HapticFeedback.mediumImpact();
    setState(() => _crated.add(i));
    _stepDone();
    if (_crated.length == 2) _complete();
  }

  // --- a house done: the reason, then the next ---------------------------------------
  void _complete() {
    if (_ended) return;
    _hush();
    setState(() => _decided = true);
    if (_slippedHere) {
      unawaited(_goNext());
      return;
    }
    final why = _run.why;
    if (_run.reasonDue(why)) {
      putOnTable(15);
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M8NoticeLines.whyRight[why]!, M8NoticeLines.whyWrong(why), widget.rng),
        question: M8NoticeLines.whyQ[why]!,
        stillValid: () => _run.index == idx && !_ended,
      ));
    } else {
      unawaited(_levelDelta(10, Offset(180, _geoNow?.guideTop ?? 400), mood: GuideMood.glad));
      unawaited(_goNext());
    }
  }

  Future<void> _goNext() async {
    if (_ended) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _ended) return;
    _run.finishHouse();
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _stage = _Stage.docket;
      _measured = false;
      _decided = false;
      _slippedHere = false;
      _receiptOpen = false;
      _receiptSeen = false;
      _rStart = null;
      _rFinger = null;
      _count = null;
      _prevStart = null;
      _prevCount = null;
      _calDown = false;
      _tilePreview = null;
      _tileAside.clear();
      _cutting = false;
      _noted = false;
      _crated.clear();
      _fading = !_quiet;
    });
    if (_fading) {
      // A short dip to black between houses (one tween; reduced motion: none).
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted || _ended) return;
      setState(() => _fading = false);
    }
    _startHouse();
  }

  // --- the shared success beat (ReasonTable) ---------------------------------------
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
  void onReasonPaid() => unawaited(_goNext());

  // --- the shared pressure moment (CoworkerMoment) ---------------------------------
  @override
  CoworkerScript get coworkerScript => M8NoticeLines.coworkerFor(_house.kind);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.done || _run.index > _run.deal.hisHouse) return null;
    if (!_atHis || _intro || _card != null || tableBusy || _fading || _tilePreview != null || _receiptOpen || _calDown) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      _slippedHere = true;
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8NoticeLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8NoticeLines.callHeld, M8NoticeLines.askDecide], mood: GuideMood.glad));
  }

  /// Tap the guide: the next task line of the stage's pool, from the start.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line;
    if (coworkerOpen) {
      line = nextCoworkerAsk();
    } else if (reasonOpen) {
      line = M8NoticeLines.tapWhy[_whyN++ % M8NoticeLines.tapWhy.length];
    } else {
      final pool = _pool;
      final key = '${_stage.name}/$_measured';
      if (key != _poolKey) {
        _poolKey = key;
        _taskN = 0;
      }
      line = pool[++_taskN % pool.length];
    }
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
      _item = null;
      _wake++;
    });
    if (_calDown) _calLift();
    if (_stage == _Stage.note) _discUp();
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8cal/${m.key}');
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
    await _say(!_run.passed ? M8NoticeLines.fail : (_quickBonus ? M8NoticeLines.quick : M8NoticeLines.allSet),
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
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_held || _item != null || _calDown) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  List<M8Tile> get _tiles => _run.deal.tileOrder[math.min(_run.index, _run.deal.houses.length - 1)];

  /// The gesture hand: how to touch, never what.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null || _run.done) return null;
    final h = _house;
    final n = _hintN++;
    const s = HintSpace.scene;
    switch (_stage) {
      case _Stage.docket:
        return HintSpec.tap(geo.closedDocket.center, space: s);
      case _Stage.measure:
        if (_tilePreview != null || _receiptOpen || _decided) return null;
        if (!_measured) return HintSpec.drag(geo.hintCell(h), toward: const Offset(1, 0), travel: 80, space: s);
        if (h.hasReceipt && !_receiptSeen && n.isOdd) return HintSpec.tap(geo.receiptIcon.center, space: s);
        return HintSpec.sweep([for (var i = 0; i < _tiles.length; i++) geo.tile(i, _tiles.length)], space: s);
      case _Stage.note:
        if (_cutting) return null;
        if (_noted) return HintSpec.hold(geo.discBtn.center, space: s);
        final digits = _wheelTouched, chip = _seal != null;
        if (digits && chip) return HintSpec.tap(geo.noteBtn.center, space: s);
        final swipe = HintSpec.swipe(geo.wheel(0).center, toward: const Offset(0, -1), travel: 56, space: s);
        final chips = HintSpec.sweep([geo.chipOk, geo.chipBroken], space: s);
        if (!digits && !chip) return n.isEven ? swipe : chips;
        return digits ? chips : swipe;
      case _Stage.crate:
        if (n.isEven) return HintSpec.drag(geo.meterItem.center, toward: const Offset(0, -1), travel: 64, space: s);
        return HintSpec.sweep([geo.pad(0), geo.pad(1)], space: s);
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8Geo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final idx = math.min(_run.index, _run.deal.houses.length - 1);
    final h = _run.deal.houses[idx];
    final stage = _stage;
    final crateLeft = _run.deal.crateLeft[idx];
    final tiles = _run.deal.tileOrder[idx];
    return [
      Positioned.fill(
        key: ValueKey('back-$idx'),
        child: RepaintBoundary(child: CustomPaint(painter: M8BackPainter(geo: geo, light: _run.deal.light, wall: h.wall, consumer: !h.live))),
      ),
      // A tap on nothing is a missed touch for the hand.
      Positioned.fill(
        key: const ValueKey('nothing'),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _canPlay ? _hints.missTap() : null),
      ),
      if (stage == _Stage.docket) ...[
        Positioned.fromRect(
          key: ValueKey('trainee-$idx'),
          rect: Rect.fromLTWH(22, geo.guideTop - 124, 46, 112),
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
        Positioned.fromRect(
          key: ValueKey('docket-closed-$idx'),
          rect: geo.closedDocket,
          child: _ClosedDocket(onTap: _openDocket),
        ),
      ],
      if (stage == _Stage.measure) ...[
        Positioned.fromRect(key: ValueKey('docket-$idx'), rect: geo.docket, child: _Docket(house: h)),
        if (_measured && _count != null)
          Positioned.fromRect(
            key: ValueKey('count-$idx'),
            rect: h.hasReceipt ? geo.countChip : geo.countChip.translate(0, -14),
            child: _CountChip(text: M8NoticeLines.count(_count!)),
          ),
        if (h.hasReceipt)
          Positioned.fromRect(
            key: ValueKey('receipt-icon-$idx'),
            rect: geo.receiptIcon,
            child: _ReceiptIcon(onTap: () {
              if (_canPlay && _stage == _Stage.measure && _tilePreview == null) _openReceipt();
            }),
          ),
        Positioned.fromRect(
          key: ValueKey('cal-$idx'),
          rect: geo.cal,
          child: Semantics(
            label: M8NoticeLines.calendarWord,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: (d) => _calStart(d.localPosition + geo.cal.topLeft, geo),
              onPanUpdate: (d) => _calUpdate(d.localPosition + geo.cal.topLeft),
              onPanEnd: (_) => _calEnd(geo),
              onPanCancel: () {
                if (_calDown) _calLift();
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: M8CalGridPainter(geo: geo, house: h)),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: M8RibbonPainter(geo: geo, house: h, start: _rStart, finger: _rFinger)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_measured && !_decided)
          for (var i = 0; i < tiles.length; i++)
            Positioned.fromRect(
              key: ValueKey('tile-$idx-${tiles[i].name}'),
              rect: geo.tile(i, tiles.length),
              child: CardAside(
                aside: _tileAside.contains(tiles[i]),
                child: _Tile(label: M8NoticeLines.tile(tiles[i]), onTap: (g) => _openTile(tiles[i], g)),
              ),
            ),
      ],
      if (stage == _Stage.note) ...[
        Positioned.fromRect(key: ValueKey('meter-$idx'), rect: geo.meterBox, child: _MeterFace(digits: h.meter, sealIntact: h.sealIntact, lampOn: !_cutting)),
        Positioned.fromRect(
          key: ValueKey('disc-$idx'),
          rect: geo.discBtn,
          child: _DiscButton(ctl: _hold, onDown: _discDown, onUp: _discUp),
        ),
        Positioned.fromRect(
          key: ValueKey('notebook-$idx'),
          rect: geo.notebook,
          child: _Notebook(
            geo: geo,
            digits: _digits,
            seal: _seal,
            noted: _noted,
            onWheelDrag: _wheelDrag,
            onWheelTap: _wheelStep,
            onChip: _chip,
            onNote: _noteSubmit,
          ),
        ),
      ],
      if (stage == _Stage.crate) ...[
        for (final i in [0, 1])
          Positioned.fromRect(
            key: ValueKey('pad-$idx-$i'),
            rect: geo.pad(i),
            child: (i == 0) == crateLeft
                ? _Pad(label: M8NoticeLines.crateWord, crate: true, held: _crated.length)
                : const _Pad(label: M8NoticeLines.verandaWord, crate: false, held: 0),
          ),
        for (final i in [0, 1])
          if (!_crated.contains(i) && _item != i)
            Positioned.fromRect(
              key: ValueKey('item-$idx-$i'),
              rect: _itemRect(i, geo),
              child: _Item(meter: i == 0, house: h),
            ),
        Positioned.fill(
          key: ValueKey('crate-touch-$idx'),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: (d) => _itemStart(d.localPosition, geo),
            onPanUpdate: (d) => _itemMove(d.localPosition),
            onPanEnd: (_) => _itemEnd(geo),
            onPanCancel: () {
              if (_item != null) setState(() => _item = null);
            },
          ),
        ),
        if (_item != null)
          Positioned(
            key: const ValueKey('item-drag'),
            left: _itemAt.dx - 46,
            top: _itemAt.dy - 62,
            width: 92,
            height: 66,
            child: IgnorePointer(child: _Item(meter: _item == 0, house: h, lifted: true)),
          ),
      ],
      if (_receiptOpen)
        Positioned.fill(
          key: const ValueKey('receipt-barrier'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeReceipt,
            child: ColoredBox(
              color: const Color(0x66050A16),
              child: Stack(
                children: [
                  Positioned.fromRect(
                    key: const ValueKey('receipt-card'),
                    rect: geo.receiptCard,
                    child: _ReceiptCard(house: h),
                  ),
                ],
              ),
            ),
          ),
        ),
      // A short dip to black between houses (reduced motion: none).
      if (_fading && !quiet)
        Positioned.fill(
          key: ValueKey('fade-$idx'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 360),
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
    final handsOn = playing && !_fading && !deckUp && !coworkerOpen && _card == null && !_run.done && !_cutting;
    M8NoticeProbe.stage = _stage.name;
    M8NoticeProbe.count = _count;
    M8NoticeProbe.measured = _measured;
    M8NoticeProbe.noted = _noted;
    final calBusy = _calDown;
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
              labels: [for (var i = 0; i < _run.deal.houses.length; i++) M8NoticeLines.houseName(i)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _tilePreview == null && !_receiptOpen && !_held && _item == null && !calBusy,
            hintKey: '${_run.index}/${_stage.name}/$_steps/${_run.slips}/$_measured/$_wheelTouched/$_seal',
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
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : pad.bottom * 0.6 + 2, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && _tilePreview != null)
                Positioned.fill(
                  key: ValueKey('tile-preview-${_tilePreview!.name}'),
                  child: CardPreviewOverlay(
                    textBn: M8NoticeLines.tile(_tilePreview!),
                    icon: Icons.touch_app_rounded,
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmTile,
                    onReject: _rejectTile,
                  ),
                ),
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
                  line: M8NoticeLines.intro,
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

const _ink = Color(0xFF2A2018);
const _brown = Color(0xFF8A6A3C);
const _paper = Color(0xFFFBF6E6);

/// The pinned paper before it is opened.
class _ClosedDocket extends StatelessWidget {
  const _ClosedDocket({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8NoticeLines.docketWord,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.rotate(
                angle: -0.05,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _brown, width: 1.6),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, child: Text(M8NoticeLines.docketWord, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: _ink))),
                        const SizedBox(height: 6),
                        for (var i = 0; i < 4; i++)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Container(height: 4, margin: EdgeInsets.only(right: i.isOdd ? 14 : 0), color: const Color(0x44806040))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(top: -4, left: 40, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFC62828), shape: BoxShape.circle))),
          ],
        ),
      ),
    );
  }
}

/// The opened docket: its plain dates, none highlighted.
class _Docket extends StatelessWidget {
  const _Docket({required this.house});
  final M8House house;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _brown, width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          alignment: WrapAlignment.start,
          children: [
            for (final l in house.order)
              SizedBox(
                width: 112,
                height: 26,
                child: Semantics(
                  label: M8NoticeLines.entryText(house, l),
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(M8NoticeLines.label(l), style: bangla(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF6A5232), height: 1.1)),
                          Text(M8NoticeLines.entryValue(house, l), maxLines: 1, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFF14304A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2AA7A1), width: 1.6)),
        child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)))),
      ),
    );
  }
}

class _ReceiptIcon extends StatelessWidget {
  const _ReceiptIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8NoticeLines.receiptWord,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: _brown, width: 1.4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_rounded, size: 16, color: _brown),
              const SizedBox(width: 4),
              Text(M8NoticeLines.receiptWord, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: _ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The consumer's receipt, open: two printed lines with amounts.
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.house});
  final M8House house;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M8NoticeLines.receiptWord,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _brown, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(M8NoticeLines.receiptWord, textAlign: TextAlign.center, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: _brown)),
              const SizedBox(height: 10),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(M8NoticeLines.duesLine(house), maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w800, color: _ink))),
              const SizedBox(height: 10),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(M8NoticeLines.chargeLine(house), maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w800, color: _ink))),
            ],
          ),
        ),
      ),
    );
  }
}

/// A decision tile: the same size and colour whatever it says.
class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap});
  final String label;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 18, end: 0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Transform.translate(offset: Offset(0, v), child: child),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF233A5E), Color(0xFF142540)]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The wall meter: the counter in its window and the seal.
class _MeterFace extends StatelessWidget {
  const _MeterFace({required this.digits, required this.sealIntact, this.lampOn = true});
  final List<int> digits;
  final bool sealIntact;
  final bool lampOn;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M8NoticeLines.meterWord,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6C737A), width: 2.4),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: const Color(0xFF1B2A22), borderRadius: BorderRadius.circular(4)),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        digits.join(' '),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF9BE8B0), letterSpacing: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: lampOn ? const Color(0xFF2E9E4F) : const Color(0xFF6C737A), shape: BoxShape.circle)),
                  SizedBox(width: 30, height: 22, child: CustomPaint(painter: _SealPainter(intact: sealIntact))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lead seal on its wire: whole, or broken with the wire ends loose.
class _SealPainter extends CustomPainter {
  const _SealPainter({required this.intact});
  final bool intact;

  @override
  void paint(Canvas c, Size size) {
    final wire = Paint()
      ..color = const Color(0xFF4A5057)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final disc = Offset(size.width - 9, size.height / 2);
    if (intact) {
      c.drawArc(Rect.fromCenter(center: Offset(size.width / 2 - 2, size.height / 2), width: size.width - 6, height: size.height - 4), math.pi * 0.9, math.pi * 1.2, false, wire);
      c.drawCircle(disc, 7, Paint()..color = const Color(0xFF9AA2A8));
      c.drawCircle(disc, 7, Paint()..color = const Color(0xFF4A5057)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    } else {
      c.drawLine(const Offset(2, 8), const Offset(11, 3), wire);
      c.drawLine(Offset(size.width - 18, size.height - 3), Offset(size.width - 8, size.height - 8), wire);
      final half = Paint()..color = const Color(0xFFB0453A);
      c.drawArc(Rect.fromCircle(center: disc, radius: 7), math.pi * 0.15, math.pi, true, half);
      c.drawArc(Rect.fromCircle(center: disc.translate(2.5, -2), radius: 7), math.pi * 1.15, math.pi, true, half);
    }
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.intact != intact;
}

/// The disconnect control: hold it until the ring is full.
class _DiscButton extends StatelessWidget {
  const _DiscButton({required this.ctl, required this.onDown, required this.onUp});
  final AnimationController ctl;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M8NoticeLines.discWord,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onDown(),
        onTapUp: (_) => onUp(),
        onTapCancel: onUp,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4350), Color(0xFF232A34)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: ctl,
                  builder: (_, _) => CustomPaint(painter: _RingPainter(ctl.value)),
                ),
              ),
            ),
            Center(child: Padding(padding: const EdgeInsets.all(14), child: FittedBox(fit: BoxFit.scaleDown, child: Text(M8NoticeLines.discWord, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory))))),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas c, Size size) {
    if (t <= 0) return;
    final r = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    c.drawArc(r, -math.pi / 2, math.pi * 2 * t, false, Paint()..color = const Color(0xFFE9C46A)..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// The notebook: five digit wheels, two seal chips and 'নোট হলো'.
class _Notebook extends StatelessWidget {
  const _Notebook({
    required this.geo,
    required this.digits,
    required this.seal,
    required this.noted,
    required this.onWheelDrag,
    required this.onWheelTap,
    required this.onChip,
    required this.onNote,
  });

  final M8Geo geo;
  final List<int> digits;
  final bool? seal;
  final bool noted;
  final void Function(int i, double dy) onWheelDrag;
  final void Function(int i, int d) onWheelTap;
  final ValueChanged<bool> onChip;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final nb = geo.notebook;
    Widget at(Rect r, Widget child, {Key? key}) => Positioned(key: key, left: r.left - nb.left, top: r.top - nb.top, width: r.width, height: r.height, child: child);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF233A5E), Color(0xFF142540)]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 8, offset: Offset(0, -2))],
            ),
          ),
        ),
        Positioned(left: 18, top: 6, child: Text('${M8NoticeLines.notebookWord} · ${M8NoticeLines.readingWord}', style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.gold300))),
        for (var i = 0; i < 5; i++)
          at(
            geo.wheel(i),
            _Wheel(index: i, digit: digits[i], locked: noted, onDrag: (dy) => onWheelDrag(i, dy), onTap: (d) => onWheelTap(i, d)),
            key: ValueKey('wheel-$i'),
          ),
        at(geo.chipOk, _SealChip(label: M8NoticeLines.sealOk, selected: seal == true, onTap: () => onChip(true)), key: const ValueKey('chip-ok')),
        at(geo.chipBroken, _SealChip(label: M8NoticeLines.sealBroken, selected: seal == false, onTap: () => onChip(false)), key: const ValueKey('chip-broken')),
        at(
          geo.noteBtn,
          Semantics(
            button: true,
            label: M8NoticeLines.noted,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNote,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: noted ? const [Color(0xFF2E9E4F), Color(0xFF217A3B)] : [SlmColors.gold300, SlmColors.gold400]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(M8NoticeLines.noted, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: noted ? Colors.white : SlmColors.navy950))),
              ),
            ),
          ),
          key: const ValueKey('note-btn'),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.index, required this.digit, required this.locked, required this.onDrag, required this.onTap});
  final int index;
  final int digit;
  final bool locked;
  final ValueChanged<double> onDrag;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => Semantics(
        label: '${M8NoticeLines.readingWord} ${index + 1}',
        value: '$digit',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(d.localPosition.dy > box.maxHeight / 2 ? 1 : -1),
          onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1DE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: locked ? const Color(0xFF2E9E4F) : _brown, width: 1.6),
            ),
            child: Stack(
              children: [
                Positioned(top: 2, left: 0, right: 0, child: Center(child: Text('${(digit + 9) % 10}', style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0x88403020), height: 1)))),
                Center(child: Text('$digit', style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: _ink, height: 1))),
                Positioned(bottom: 2, left: 0, right: 0, child: Center(child: Text('${(digit + 1) % 10}', style: bangla(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0x88403020), height: 1)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SealChip extends StatelessWidget {
  const _SealChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF6DA) : const Color(0xFFE8DCC0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? SlmColors.gold400 : _brown, width: selected ? 2.4 : 1.4),
          ),
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: _ink)))),
        ),
      ),
    );
  }
}

/// A drop pad (equal size and colour): the van's crate or the verandah.
class _Pad extends StatelessWidget {
  const _Pad({required this.label, required this.crate, required this.held});
  final String label;
  final bool crate;
  final int held;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC14304A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 64, height: 40, child: CustomPaint(painter: _PadArtPainter(crate: crate, held: held))),
            const SizedBox(height: 4),
            Text(label, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          ],
        ),
      ),
    );
  }
}

class _PadArtPainter extends CustomPainter {
  const _PadArtPainter({required this.crate, required this.held});
  final bool crate;
  final int held;

  @override
  void paint(Canvas c, Size s) {
    final wood = Paint()..color = const Color(0xFFC79552);
    final edge = Paint()..color = const Color(0xFF7A5426)..style = PaintingStyle.stroke..strokeWidth = 2;
    // Both pads draw a box on a floor (a crate; a mat with a step): same weight.
    c.drawRect(Rect.fromLTWH(0, s.height - 8, s.width, 8), Paint()..color = crate ? const Color(0xFF6A727A) : const Color(0xFFB9A887));
    final box = Rect.fromLTWH(10, 4, s.width - 20, s.height - 14);
    c.drawRect(box, crate ? wood : Paint()..color = const Color(0xFFD9C79F));
    c.drawRect(box, edge);
    c.drawLine(Offset(box.left, box.center.dy), Offset(box.right, box.center.dy), edge);
    if (held > 0) {
      for (var i = 0; i < held; i++) {
        c.drawCircle(Offset(box.left + 10 + i * 12, box.top + 8), 4, Paint()..color = const Color(0xFF2E9E4F));
      }
    }
  }

  @override
  bool shouldRepaint(_PadArtPainter old) => old.held != held || old.crate != crate;
}

/// An item to carry: the meter or the coiled service wire.
class _Item extends StatelessWidget {
  const _Item({required this.meter, required this.house, this.lifted = false});
  final bool meter;
  final M8House house;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: meter ? M8NoticeLines.meterWord : M8NoticeLines.coilWord,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: meter ? const Color(0xFFE9EEF2) : const Color(0xFFD9DEE2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF6C737A), width: 2),
          boxShadow: [BoxShadow(color: const Color(0x77000000), blurRadius: lifted ? 10 : 4, offset: Offset(0, lifted ? 6 : 2))],
        ),
        child: meter
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: const Color(0xFF1B2A22), borderRadius: BorderRadius.circular(3)),
                        child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(house.meter.join(' '), style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF9BE8B0))))),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(M8NoticeLines.meterWord, style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Expanded(child: CustomPaint(painter: const M8CoilPainter(), size: Size.infinite)),
                    Text(M8NoticeLines.coilWord, style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
      ),
    );
  }
}
