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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm6_capbank_meter_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_capbank_meter_world.dart' show M6CbmGeo, M6CbmMeter, M6CbmSky, M6CbmState, m6CbmFrac, m6CbmValue;

// Lesson 6.7 "ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার", কাজ 2 "মিটারে ব্যাংকের নাড়ি"
// (pack do_6_7_b, engineType m6_capbank_meter). A 33/11 kV substation at
// dusk; the load is rising and three capacitor banks wait in the yard.
//
//  The yard: tap any bank and it comes close (every bank zooms the same way).
//    Up close a swollen can bulges with an oil streak, a blown external fuse
//    hangs open; a sound bank and a weak one look exactly alike (pro tip 1:
//    the internal fuses cannot be seen from outside).
//  The panel, one bank at a time (1, 2, 3): the feeder ammeter and the PF
//    meter, the log sheet with an A strip and a PF strip, each bank's lever
//    (ON / OFF) and its 'চালু করবেন না' tag hook, and one 'লগে সই' button
//    that closes the bank's row as it stands.
//
// The core verb (log meters, switch once, compare the swing): put the pencil
// where each needle stands (a misread is not kept and costs nothing; the
// value is never shown before the mark is right); flick the lever ON once;
// the needles swing (the panel is locked meanwhile; swings vary in size);
// log the after-readings; then judge from the two marks — a clear amp drop
// with PF toward 1.0 (lesson point 1: the bank takes the extra current off)
// → leave it ON and sign; little change (point 4: capacitance falls with
// age) → OFF, tag, sign. A blown fuse → tag and sign (point 4: no new fuse
// before the cause is found). A swollen can → never in service: tag it, or
// switch it OFF and tag it when it is found in service (point 4, M6-5).
//
// Slips (module 6 table, rulings M6-5, R11, R32, R33): a swollen bank switched
// in or left in service; a bank that barely moved the meters left in service
// (a blown-fuse bank too); a sound bank tagged (R32), and a tag on a bank
// with no outward defect before it was ever measured (R32: isolation without
// cause); switching a bank ON again after OFF to re-test (pro tip 2). The
// lever, the tag and the sign answer the same way for every bank whatever it
// is (no button reveals the state).
//
// Deadly (R8, R39 with X2/B1): only by listening to the coworker on a swollen
// bank — 'ফোলা ক্যানটা হাত দিয়ে টিপে দেখো …' — a hand on a can of a bank not
// switched OFF, waited and rod-discharged (point 3). His other pushes are
// slips: on a sound or weak bank, once both after-readings are logged,
// 'আরেকবার OFF-ON করে দেখো …' (pro tip 2); on a blown-fuse bank, at the start
// of its row, 'ফিউজ উড়েছে? নতুন একটা লাগিয়ে …' (R33). The lever, the tag
// and the sign of his bank wait for him (holdForCoworker). Three slips strike
// out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_capbank_meter_world.dart), corner guide, a right bank puts ◆
// on the table → "কেন …?" (the deck opens at once) → এগিয়ে যান → the next
// bank. Gesture hands: in the yard a sweep over the three banks and a tap on
// 'প্যানেলে যান' in turn; on a zoom a tap on 'ফিরে যান'; on the panel a short
// generic nudge of the pencil (left, up or down in turn — never to a value)
// and a sweep over the lever, the tag hook and the sign alike; no hand while
// the needles swing.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one a play, on his dealt bank; fits its state).
enum M6CbmPush { reSwitch, refit, touch }

/// What a bank's reason asks about.
enum M6CbmWhy { keepOn, tagOff, noRefit, swollen, noRetest }

/// Why a control did nothing (the guide says it; never a cost).
enum M6CbmNote { logFirst, afterFirst, offFirst, tagHangs, decideFirst, misread }

/// The view: the yard or the control-room panel.
enum M6CbmView { yard, panel }

/// The lesson point (0-based) the fail panel opens: troubleshooting.
const int m6CbmLessonPoint = 3;

abstract final class M6CapbankMeterLines {
  static const title = 'মিটারে ব্যাংকের নাড়ি';
  // The spec's intro line (DRAFT wording — owner, M6-12).
  static const intro = 'সন্ধ্যা নামছে, লোড বাড়ছে। ব্যাংকগুলো লাইনে আনার দায়িত্ব আপনার।';

  // The guide's task now (tap him: the same task, a different way).
  // DRAFT wording — owner (M6-12).
  static const askYard = 'আগে ইয়ার্ডে ব্যাংকগুলো ঘুরে দেখুন।';
  static String askBank(int n) => enDigits('ব্যাংক $n: লাইনে আনুন, নয়তো ট্যাগ দিয়ে বাইরে রাখুন।');
  static const askAfter = 'কাঁটা থেমেছে — এবার পরের রিডিং লিখুন।';
  static const askDecide = 'দুই রিডিং মিলিয়ে সিদ্ধান্ত নিন, তারপর লগে সই।';
  static List<String> get tasks => [askYard, for (var n = 1; n <= 3; n++) askBank(n), askAfter, askDecide];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Why a control did nothing (DRAFT wording — owner).
  static String note(M6CbmNote n) => switch (n) {
        M6CbmNote.logFirst => 'আগে মিটার দুটো লগে লিখুন।',
        M6CbmNote.afterFirst => 'আগে পরের রিডিং লিখে নিন।',
        M6CbmNote.offFirst => 'ট্যাগের আগে লিভার OFF করুন।',
        M6CbmNote.tagHangs => 'ট্যাগ ঝুলছে — এ ব্যাংক চালু নয়।',
        M6CbmNote.decideFirst => 'আগে ব্যাংকটা নিয়ে সিদ্ধান্ত নিন।',
        M6CbmNote.misread => 'কাঁটাটা আবার ভালো করে দেখুন।',
      };

  // Labels a worker reads.
  static const toPanel = 'প্যানেলে যান';
  static const toYard = 'ইয়ার্ডে যান';
  static const sign = 'লগে সই';
  static const zoomClose = 'ফিরে যান';
  static const yardLabel = 'ক্যাপাসিটর ব্যাংক ইয়ার্ড';
  static const panelLabel = 'কন্ট্রোল প্যানেল';
  static String bankLabel(int n) => enDigits('ব্যাংক $n');

  // The reasons: the right ones fit what was done; the wrong ones are field
  // excuses and the lesson's myth. DRAFT wording — owner.
  static const whyQ = <M6CbmWhy, String>{
    M6CbmWhy.keepOn: 'ব্যাংক চালু রাখলেন কেন?',
    M6CbmWhy.tagOff: 'ব্যাংক OFF রেখে ট্যাগ দিলেন কেন?',
    M6CbmWhy.noRefit: 'নতুন ফিউজ লাগালেন না কেন?',
    M6CbmWhy.swollen: 'ফোলা ইউনিটের ব্যাংক বিচ্ছিন্ন রাখলেন কেন?',
    M6CbmWhy.noRetest: 'আবার OFF-ON করলেন না কেন?',
  };

  /// The blown-fuse question once he was heard on 'fit a new one' (the
  /// player agreed, so 'why no new fuse?' would not fit what happened).
  static const whyQBlownTag = 'ফিউজ ওড়া ব্যাংকে ট্যাগ দিলেন কেন?';
  static const whyRight = <M6CbmWhy, List<String>>{
    M6CbmWhy.keepOn: ['অ্যাম্পিয়ার কমেছে, PF 1.0-এর দিকে উঠেছে', 'লাইনের বাড়তি কারেন্ট কমেছে, ব্যাংক কাজ করছে'],
    M6CbmWhy.tagOff: ['মিটার প্রায় নড়েনি, ক্যাপাসিট্যান্স কমে গেছে', 'চালিয়েও PF প্রায় ওঠেনি, ব্যাংক দুর্বল হয়েছে'],
    M6CbmWhy.noRefit: ['কারণ না খুঁজে আবার ফিউজ লাগানো উচিত নয়', 'খারাপ ইউনিট বা শর্টে ফিউজ ওড়ে, আগে কারণ'],
    M6CbmWhy.swollen: ['ফোলা ক্যাপাসিটর মানে ভেতরে ফল্ট, ফাটতে পারে', 'ফোলা ইউনিট যেকোনো মুহূর্তে ফেটে যেতে পারে'],
    M6CbmWhy.noRetest: ['ব্যাংক ঘন ঘন ON-OFF করা একদম উচিত নয়', 'একবারের রিডিংই বলেছে ব্যাংকটা দুর্বল'],
  };
  static const myths = [
    'যত বেশি ব্যাংক চালু, লাইন তত বেশি নিরাপদ',
    'মিটার না দেখেও সব ব্যাংক চালু রাখা যায়',
    'ফিউজ উড়লে মোটা তারে চালিয়ে দিলেই হয়',
    'ফোলা ক্যান একটু চাপ দিলেই ঠিক হয়ে যায়',
    'বারবার চালালে দুর্বল ব্যাংকও সেরে ওঠে',
    'ছোট ক্যাপাসিটর তেমন বিপজ্জনক কিছু নয়',
    'PF যত নিচে থাকে, লাইন তত ভালোভাবে চলে',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, on his dealt bank).
  // DRAFT wording — owner (M6-12): his three pushes are the spec's, with the
  // owner's term rule (OFF-ON, never অফ-অন).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerReSwitch = CoworkerScript(
    line: 'আরেকবার OFF-ON করে দেখো, ঠিক চালু হয়ে যাবে।',
    exitLine: coworkerExit,
    right: ['না, ঘন ঘন ON-OFF ব্যাংকের ক্ষতি', 'না, একবারের রিডিংই যথেষ্ট', 'না, মিটারে যা দেখেছি তাতেই চলব'],
    wrong: [
      'ঠিক, আরেকবার চালিয়ে দেখি',
      'আচ্ছা, দুবার করলে ক্ষতি নেই',
      'হ্যাঁ, এবার হয়তো ঠিক চলবে',
      'ঠিক আছে, আবার OFF-ON করি',
      'হ্যাঁ, বারবার দেখাই ভালো',
    ],
    asks: ['কী করবেন?', 'ও বলছে আবার OFF-ON করতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerRefit = CoworkerScript(
    line: 'ফিউজ উড়েছে? নতুন একটা লাগিয়ে চালিয়ে দাও।',
    exitLine: coworkerExit,
    right: ['না, আগে ফিউজ ওড়ার কারণ খুঁজব', 'না, কারণ না জেনে ফিউজ নয়', 'না, ট্যাগ দিয়ে রিপোর্ট করব'],
    wrong: [
      'ঠিক, নতুন ফিউজ লাগিয়ে দিই',
      'আচ্ছা, ফিউজ তো সস্তা জিনিস',
      'হ্যাঁ, লাগালেই চালু হবে',
      'ঠিক আছে, এখনই বদলে দিচ্ছি',
      'হ্যাঁ, কারণ পরে দেখা যাবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে নতুন ফিউজ লাগাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerTouch = CoworkerScript(
    line: 'ফোলা ক্যানটা হাত দিয়ে টিপে দেখো তো কতটা ফুলেছে।',
    exitLine: coworkerExit,
    right: ['না, চার্জ থাকা ক্যানে হাত নয়', 'না, OFF, অপেক্ষা, রড — তারপর', 'না, ফোলা ক্যান ছোঁয়া মারাত্মক'],
    wrong: [
      'ঠিক, হাত দিয়ে একটু টিপে দেখি',
      'আচ্ছা, একটু হাত দিলে কী আর হবে',
      'হ্যাঁ, টিপে দেখি কতটা ফুলেছে',
      'ঠিক আছে, আঙুলে টিপে দেখি',
      'হ্যাঁ, ক্যানে তো কারেন্ট নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে ফোলা ক্যানে হাত দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6CbmPush p) => switch (p) {
        M6CbmPush.reSwitch => coworkerReSwitch,
        M6CbmPush.refit => coworkerRefit,
        M6CbmPush.touch => coworkerTouch,
      };
  static const allCoworkers = [coworkerReSwitch, coworkerRefit, coworkerTouch];

  static String callHeld(M6CbmPush p) => switch (p) {
        M6CbmPush.reSwitch => 'ঠিক! ঘন ঘন ON-OFF করলে ব্যাংকের ক্ষতি।',
        M6CbmPush.refit => 'ঠিক! কারণ না খুঁজে ফিউজ লাগানো চলে না।',
        M6CbmPush.touch => 'ঠিক! চার্জ থাকা ক্যানে কখনও হাত নয়।',
      };

  static const allSet = 'তিন ব্যাংকেই ঠিক সিদ্ধান্ত — লাইন এখন হালকা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — মিটার লিখুন, একবার চালান, তারপর মিলিয়ে দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtKeepOn = 'ভালো ব্যাংক লাইনে রেখেছেন';
  static const caughtWeak = 'দুর্বল ব্যাংক ট্যাগে বাইরে';
  static const caughtBlown = 'উড়ে যাওয়া ফিউজ — ট্যাগ, রিপোর্ট';
  static const caughtSwollen = 'ফোলা ক্যান — সার্ভিস থেকে বাইরে';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        askYard,
        for (var n = 1; n <= 3; n++) askBank(n),
        askAfter,
        askDecide,
        for (final n in M6CbmNote.values) note(n),
        ...whyQ.values,
        whyQBlownTag,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        for (final p in M6CbmPush.values) callHeld(p),
        allSet,
        fail,
        for (final m in M6CapbankMeterMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M6CapbankMeterMistakes {
  static const _dir = 'assets/game/art/m6_capbank_meter';

  // DRAFT wording — owner (M6-12). Sources: lesson 6.7 point 4 (করণীয়, the
  // troubleshooting list), point 1, point 3 and pro tip 2.
  static const swollenIn = DoMistake(
    key: '6.7/m6_capbank_meter/swollen-in',
    textBn: 'ফোলা ক্যাপাসিটর মানে ভেতরে ফল্ট — যেকোনো মুহূর্তে ফেটে যেতে পারে। এমন ব্যাংক চালু নয়: OFF করে ট্যাগ দিন, সার্ভিস থেকে সরান।',
    art: '$_dir/swollen.svg',
    lessonPoint: 3,
  );
  static const weakLeft = DoMistake(
    key: '6.7/m6_capbank_meter/weak-left',
    textBn: 'ব্যাংক চালু করেও মিটার প্রায় নড়েনি — সময়ের সাথে ক্যাপাসিট্যান্স কমে গেছে। এমন ব্যাংক লাইনে রেখে লাভ নেই; OFF করে ট্যাগ দিন।',
    art: '$_dir/weak.svg',
    lessonPoint: 3,
  );
  static const blownLeft = DoMistake(
    key: '6.7/m6_capbank_meter/blown-left',
    textBn: 'এই ব্যাংকের একটা ফিউজ উড়ে গেছে — খারাপ ইউনিট বা ভেতরের শর্ট। কারণ না খুঁজে এ ব্যাংক লাইনে নয়; OFF করে ট্যাগ দিন, রিপোর্ট করুন।',
    art: '$_dir/refit.svg',
    lessonPoint: 3,
  );
  static const refit = DoMistake(
    key: '6.7/m6_capbank_meter/refit',
    textBn: 'ফিউজ উড়লে আগে কারণ খুঁজতে হয় — খারাপ ইউনিট বা ভেতরের শর্ট। কারণ না খুঁজে আবার ফিউজ লাগানো উচিত নয়; ট্যাগ দিয়ে রিপোর্ট করুন।',
    art: '$_dir/refit.svg',
    lessonPoint: 3,
  );
  static const needlessTag = DoMistake(
    key: '6.7/m6_capbank_meter/needless-tag',
    textBn: 'ব্যাংক চালু হতেই অ্যাম্পিয়ার কমেছিল, PF 1.0-এর দিকে উঠেছিল — ব্যাংক ঠিক কাজ করছে। ভালো ব্যাংক ট্যাগ দিয়ে বাইরে রাখবেন না।',
    art: '$_dir/tag.svg',
    lessonPoint: 0,
  );
  static const untestedTag = DoMistake(
    key: '6.7/m6_capbank_meter/untested-tag',
    textBn: 'এই ব্যাংকে বাইরে থেকে কোনো দোষ দেখা যায় না। না মেপে ট্যাগ নয় — আগে রিডিং লিখে একবার চালিয়ে মিটারে দেখুন।',
    art: '$_dir/tag.svg',
    lessonPoint: 0,
  );
  // Pro tip 2 (not a numbered point).
  static const reSwitch = DoMistake(
    key: '6.7/m6_capbank_meter/re-switch',
    textBn: 'ক্যাপাসিটর ব্যাংক ঘন ঘন ON-OFF করা উচিত নয় — প্রতিবার সুইচিং সার্জ। একবার চালিয়ে মিটারে যা দেখলেন, তাতেই সিদ্ধান্ত।',
    art: '$_dir/reswitch.svg',
  );
  static const touch = DoMistake(
    key: '6.7/m6_capbank_meter/touch-can',
    textBn: 'ফোলা ক্যানে হাত! OFF করে অপেক্ষা হয়নি, ডিসচার্জ রড লাগেনি — ক্যাপাসিটর চার্জ ধরে রাখে, মারাত্মক শক দিতে পারে। আগে OFF, অপেক্ষা, তারপর রডে ডিসচার্জ ও আর্থিং।',
    art: '$_dir/touch.svg',
    deadly: true,
    lessonPoint: 2,
  );

  /// Listening to his push is the act it pushes (X2/B1).
  static DoMistake push(M6CbmPush p) => switch (p) {
        M6CbmPush.reSwitch => reSwitch,
        M6CbmPush.refit => refit,
        M6CbmPush.touch => touch,
      };

  static const List<DoMistake> all = [swollenIn, weakLeft, blownLeft, refit, needlessTag, untestedTag, reSwitch, touch];
}

/// One bank as dealt.
@immutable
class M6CbmBank {
  const M6CbmBank({required this.state, required this.defect, required this.relief, this.inService = false});

  final M6CbmState state;

  /// The can (swollen) or the fuse (blown) that is bad: 0, 1 or 2.
  final int defect;

  /// How hard the bank pulls the meters when it goes in (illustrative,
  /// M6-13): its swing is [m6CbmAmpSwing] amps and [m6CbmPfSwing] PF, the
  /// same whichever banks are already in.
  final double relief;

  /// Found ON (only a swollen bank, some plays).
  final bool inService;
}

@immutable
class M6CbmDeal {
  const M6CbmDeal({required this.banks, required this.amps0, required this.pf0, required this.sky, required this.coworkerBank, required this.why});

  final List<M6CbmBank> banks;

  /// The feeder with every bank out (illustrative, M6-13; 0.8 is the lesson's).
  final double amps0;
  final double pf0;
  final M6CbmSky sky;

  /// The bank the coworker comes in at (his push fits its state).
  final int coworkerBank;

  /// What each bank's reason asks about (fits what is right for it).
  final List<M6CbmWhy> why;

  M6CbmPush get push => m6CbmPushFor(banks[coworkerBank].state);
}

/// His push on a bank: a sound or weak one 'switch it again', a blown fuse
/// 'fit a new one', a swollen can 'press it with your hand'.
M6CbmPush m6CbmPushFor(M6CbmState s) => switch (s) {
      M6CbmState.healthy || M6CbmState.weak => M6CbmPush.reSwitch,
      M6CbmState.blown => M6CbmPush.refit,
      M6CbmState.swollen => M6CbmPush.touch,
    };

/// The relief a bank of a state is dealt (illustrative): a sound bank a clear
/// swing (19-26 A, +0.046-0.061 PF), a weak or blown one little (at most
/// 4.8 A, +0.012 PF), so a sound swing is always more than 2x any weak or
/// blown one in both meters, in any play order. The most that can be in
/// together (two sound banks and a swollen one) keeps PF under 1.0.
(double, double) m6CbmReliefRange(M6CbmState s) => switch (s) {
      M6CbmState.healthy => (0.24, 0.32),
      M6CbmState.weak => (0.02, 0.05),
      M6CbmState.blown => (0.03, 0.06),
      M6CbmState.swollen => (0.12, 0.18),
    };

M6CbmDeal m6CbmDeal(math.Random rng) {
  // At most one swollen bank, at least one sound one, never three sound ones.
  late List<M6CbmState> states;
  do {
    states = [for (var i = 0; i < 3; i++) M6CbmState.values[rng.nextInt(4)]];
  } while (states.where((s) => s == M6CbmState.swollen).length > 1 ||
      !states.contains(M6CbmState.healthy) ||
      states.every((s) => s == M6CbmState.healthy));
  final banks = [
    for (final s in states)
      () {
        final (lo, hi) = m6CbmReliefRange(s);
        return M6CbmBank(
          state: s,
          defect: rng.nextInt(3),
          relief: lo + rng.nextDouble() * (hi - lo),
          inService: s == M6CbmState.swollen && rng.nextBool(),
        );
      }(),
  ];
  final why = [
    for (final s in states)
      switch (s) {
        M6CbmState.healthy => M6CbmWhy.keepOn,
        M6CbmState.weak => rng.nextBool() ? M6CbmWhy.tagOff : M6CbmWhy.noRetest,
        M6CbmState.blown => M6CbmWhy.noRefit,
        M6CbmState.swollen => M6CbmWhy.swollen,
      },
  ];
  return M6CbmDeal(
    banks: banks,
    amps0: 250.0 + rng.nextInt(80),
    pf0: 0.76 + rng.nextInt(9) * 0.01,
    sky: M6CbmSky.values[rng.nextInt(M6CbmSky.values.length)],
    coworkerBank: rng.nextInt(3),
    why: why,
  );
}

/// The swing a bank of [relief] puts on the meters (additive, illustrative).
double m6CbmAmpSwing(double relief) => relief * 80;
double m6CbmPfSwing(double relief) => relief * 0.19;

/// How close a pencil mark must sit to the needle to be kept.
double m6CbmTolerance(M6CbmMeter m) => m == M6CbmMeter.amps ? 15 : 0.025;

/// The play state (pure logic).
class M6CbmRun {
  M6CbmRun(this.deal)
      : on = [for (final b in deal.banks) b.inService],
        tagged = [false, false, false] {
    _startRound();
  }
  final M6CbmDeal deal;

  /// Each bank's lever (ON) and tag, as they stand.
  final List<bool> on;
  final List<bool> tagged;

  int index = 0;
  int slips = 0;
  int bankSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The bank's row is signed (right: its reason comes next).
  var roundDone = false;

  /// The row was signed wrong: a slip, and the next bank follows its card.
  var closedWrong = false;

  /// This round the player switched the bank ON (and then OFF again).
  var switchedOn = false;
  var switchedOff = false;

  /// This round a re-switch was made (or his 'again' heard), or his 'fit a
  /// new fuse' was heard:
  /// the reason then asks what fits what happened.
  var reSwitched = false;
  var refitHeard = false;

  /// The player's kept marks (the true reading once the mark was close).
  final Map<M6CbmMeter, double> before = {};
  final Map<M6CbmMeter, double> after = {};

  /// Why the last control did nothing (null: it did something).
  M6CbmNote? note;

  M6CbmBank get bank => deal.banks[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => bankSlips == 0;
  bool get _open => !ended && !roundDone;

  // --- the meters (illustrative, M6-13: each bank in service takes its own
  // fixed swing off the amps and adds it to PF, whatever else is in, so the
  // player's two marks always tell a sound bank from a weak one) ------------
  double _sum(double Function(double) f) {
    var x = 0.0;
    for (var i = 0; i < 3; i++) {
      if (on[i]) x += f(deal.banks[i].relief);
    }
    return x;
  }

  double get amps => deal.amps0 - _sum(m6CbmAmpSwing);
  double get pf => math.min(0.995, deal.pf0 + _sum(m6CbmPfSwing));
  double value(M6CbmMeter m) => m == M6CbmMeter.amps ? amps : pf;

  bool get beforeDone => before.length == 2;
  bool get afterDone => after.length == 2;

  /// The bank was switched in this round and its after-readings are owed
  /// (a swollen bank owes none: it must come out at once).
  bool get needAfter => switchedOn && on[index.clamp(0, 2)] && !afterDone && bank.state != M6CbmState.swollen;

  /// The pencil writes now: before the switch, or after it while ON.
  bool get canLog => _open && (!switchedOn || (on[index] && !afterDone));

  /// His moment on his bank: a sound or weak bank once both after-readings
  /// are in (his 'switch it again' fits only then); a blown or swollen bank
  /// from the start of its row.
  bool get coworkerMoment => switch (bank.state) {
        M6CbmState.healthy || M6CbmState.weak => afterDone,
        _ => true,
      };

  void _startRound() {
    switchedOn = false;
    switchedOff = false;
    reSwitched = false;
    refitHeard = false;
    before.clear();
    after.clear();
    roundDone = false;
    closedWrong = false;
    bankSlips = 0;
    note = null;
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    bankSlips++;
    return m;
  }

  DoMistake _close(DoMistake m) {
    roundDone = true;
    closedWrong = true;
    return _slip(m);
  }

  /// The pencil on [m]'s strip at [v]: kept (the true reading) when close to
  /// the needle; a misread is not kept and costs nothing.
  bool log(M6CbmMeter m, double v) {
    note = null;
    if (!canLog) return false;
    final real = value(m);
    if ((v - real).abs() > m6CbmTolerance(m)) {
      note = M6CbmNote.misread;
      return false;
    }
    (switchedOn ? after : before)[m] = real;
    return true;
  }

  /// The current bank's lever: ON (both readings logged, no tag; ON again
  /// after an OFF this round = the re-switch slip, once) or OFF (the
  /// after-readings logged).
  DoMistake? lever() {
    note = null;
    if (!_open) return null;
    final i = index;
    if (on[i]) {
      if (needAfter) {
        note = M6CbmNote.afterFirst;
        return null;
      }
      on[i] = false;
      if (switchedOn) switchedOff = true;
      return null;
    }
    if (tagged[i]) {
      note = M6CbmNote.tagHangs;
      return null;
    }
    if (switchedOn && switchedOff) {
      // ON again after OFF: it happens (the needles swing) so the row can
      // still close by the bank's real state; the slip is charged once a
      // round, so a confused player does not strike out on one bank.
      on[i] = true;
      if (reSwitched) return null;
      reSwitched = true;
      return _slip(M6CapbankMeterMistakes.reSwitch);
    }
    if (!beforeDone) {
      note = M6CbmNote.logFirst;
      return null;
    }
    on[i] = true;
    switchedOn = true;
    if (bank.state == M6CbmState.swollen) return _slip(M6CapbankMeterMistakes.swollenIn);
    return null;
  }

  /// The current bank's tag hook: hang the tag on an OFF bank, or take it
  /// back. A tag on a bank with no outward defect that was never measured =
  /// isolation without cause (R32).
  DoMistake? tag() {
    note = null;
    if (!_open) return null;
    final i = index;
    if (on[i]) {
      note = M6CbmNote.offFirst;
      return null;
    }
    if (tagged[i]) {
      tagged[i] = false;
      return null;
    }
    final s = bank.state;
    if (!switchedOn && (s == M6CbmState.healthy || s == M6CbmState.weak)) return _slip(M6CapbankMeterMistakes.untestedTag);
    tagged[i] = true;
    return null;
  }

  /// 'লগে সই': the bank's row closes as it stands. ON: right only for a sound
  /// bank; OFF + tag: right unless the bank was sound.
  DoMistake? sign() {
    note = null;
    if (!_open) return null;
    final i = index;
    final s = bank.state;
    if (on[i]) {
      if (needAfter) {
        note = M6CbmNote.afterFirst;
        return null;
      }
      switch (s) {
        case M6CbmState.healthy:
          _done();
          return null;
        case M6CbmState.weak:
          return _close(M6CapbankMeterMistakes.weakLeft);
        case M6CbmState.blown:
          return _close(M6CapbankMeterMistakes.blownLeft);
        case M6CbmState.swollen:
          // Switched in by the player: that slip was charged at the lever and
          // its card said OFF + tag; R11 counts once a bank, so the row waits.
          if (switchedOn) {
            note = M6CbmNote.offFirst;
            return null;
          }
          return _close(M6CapbankMeterMistakes.swollenIn);
      }
    }
    if (!tagged[i]) {
      note = M6CbmNote.decideFirst;
      return null;
    }
    if (s == M6CbmState.healthy) return _close(M6CapbankMeterMistakes.needlessTag);
    _done();
    return null;
  }

  void _done() {
    roundDone = true;
    _tag(switch (bank.state) {
      M6CbmState.healthy => M6CapbankMeterLines.caughtKeepOn,
      M6CbmState.weak => M6CapbankMeterLines.caughtWeak,
      M6CbmState.blown => M6CapbankMeterLines.caughtBlown,
      M6CbmState.swollen => M6CapbankMeterLines.caughtSwollen,
    });
  }

  /// Listened to a slip-line coworker (the bank's row goes on).
  DoMistake pushSlip(DoMistake m) {
    if (identical(m, M6CapbankMeterMistakes.reSwitch)) reSwitched = true;
    if (identical(m, M6CapbankMeterMistakes.refit)) refitHeard = true;
    return _slip(m);
  }

  /// What this bank's reason asks about: the dealt topic, unless a re-switch
  /// this round makes 'why not again?' not fit (then 'why OFF and tagged?').
  M6CbmWhy get why {
    final w = deal.why[index.clamp(0, 2)];
    return w == M6CbmWhy.noRetest && reSwitched ? M6CbmWhy.tagOff : w;
  }

  /// The question for [why] as things went.
  String get whyQuestion => why == M6CbmWhy.noRefit && refitHeard ? M6CapbankMeterLines.whyQBlownTag : M6CapbankMeterLines.whyQ[why]!;

  /// Fails the play (listening to a deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    if (!done) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   the yard (three zooms and back, the panel button) ≈ 10000
///   a measured bank: two marks, ON + the swing (1400), two marks, the
///     decision (sign; or OFF, tag, sign) ≈ 10000–13000
///   a tagged bank (blown, swollen): tag (an OFF first), sign ≈ 3000–4500
///   + a reason each (~8200 × 3) + the coworker once ≈ 9600       ≈ 66000–82000
/// 85 % ≈ 64000 → 70 s (a builder's estimate; owner may tune).
const m6CapbankMeterQuickMs = 70000;

@immutable
class M6CapbankMeterPack {
  const M6CapbankMeterPack({required this.id, required this.titleBn, this.quickMs = m6CapbankMeterQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6CapbankMeterPack> m6CapbankMeterPacks = {
  'do_6_7_b': M6CapbankMeterPack(id: 'do_6_7_b', titleBn: M6CapbankMeterLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M6CapbankMeterProbe {
  static M6CbmRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M6CapbankMeterPage extends StatefulWidget {
  const M6CapbankMeterPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6CapbankMeterPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6CapbankMeterPage> createState() => _M6CapbankMeterPageState();
}

class _M6CapbankMeterPageState extends State<M6CapbankMeterPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CbmRunPage(
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

class _CbmRunPage extends ConsumerStatefulWidget {
  const _CbmRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6CapbankMeterPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CbmRunPage> createState() => _CbmRunPageState();
}

class _CbmRunPageState extends ConsumerState<_CbmRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6CbmRun _run;
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

  var _view = M6CbmView.yard;

  /// The bank brought close in the yard (null: none).
  int? _zoom;

  /// The pencil in hand (its tip, design px) — null: at rest.
  Offset? _pen;

  /// The needles' swing after a lever: from → to, on [_swing].
  late final AnimationController _swing = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  var _swinging = false;
  double _fromA = 0, _fromPf = 0, _toA = 0, _toPf = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _viewKey = GlobalKey();
  final _signKey = GlobalKey();
  final _closeKey = GlobalKey();
  final _leverKey = GlobalKey();
  final _tagKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M6CbmGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6CbmRun(m6CbmDeal(widget.rng));
    M6CapbankMeterProbe.run = _run;
    _toA = _fromA = _run.amps;
    _toPf = _fromPf = _run.pf;
    _swing.addStatusListener((s) {
      if (s == AnimationStatus.completed) _swingDone();
    });
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _swing.dispose();
    _chain++;
    if (identical(M6CapbankMeterProbe.run, _run)) M6CapbankMeterProbe.run = null;
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_swinging;

  String get _task {
    if (_view == M6CbmView.yard) return M6CapbankMeterLines.askYard;
    if (_run.needAfter) return M6CapbankMeterLines.askAfter;
    if (_run.switchedOn && _run.afterDone) return M6CapbankMeterLines.askDecide;
    return M6CapbankMeterLines.askBank(_run.index + 1);
  }

  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  /// His moment on his bank: once due, the lever, the tag and the sign wait.
  void _maybeCoworker() {
    if (_run.index == _run.deal.coworkerBank && !coworkerDone && !coworkerDue && _run.coworkerMoment && !_run.roundDone) {
      scheduleCoworker();
    }
  }

  bool _waitForHim() => _run.index == _run.deal.coworkerBank && holdForCoworker();

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- views ----------------------------------------------------------------------
  void _toggleView() {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() {
      _view = _view == M6CbmView.yard ? M6CbmView.panel : M6CbmView.yard;
      _zoom = null;
      _pen = null;
    });
    _stepDone();
    if (_view == M6CbmView.panel) _maybeCoworker();
    unawaited(_sayChain([_task]));
  }

  void _openZoom(int i) {
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _zoom = i);
    _stepDone();
  }

  void _closeZoom() {
    if (_zoom == null || !_canPlay) return;
    _tick();
    setState(() => _zoom = null);
    _stepDone();
  }

  // --- hands on -----------------------------------------------------------------
  void _note() {
    final n = _run.note;
    _tick();
    if (n != null) unawaited(_sayChain([M6CapbankMeterLines.note(n)]));
  }

  void _tapScene(Offset p, M6CbmGeo geo, Offset global) {
    if (!_canPlay) return;
    if (_view == M6CbmView.yard) {
      if (_zoom != null) return;
      final b = geo.bankAt(p);
      if (b != null) {
        _openZoom(b);
        return;
      }
      _hints.missTap();
      return;
    }
    final i = _run.index;
    final strip = geo.stripAt(p);
    if (strip != null) {
      _log(strip, geo.valueAtX(strip, p.dx));
      return;
    }
    if (geo.leverHit(i).contains(p)) {
      _lever(global);
      return;
    }
    if (geo.tagHit(i).contains(p)) {
      _tagHook(global);
      return;
    }
    _hints.missTap();
  }

  void _log(M6CbmMeter m, double v) {
    if (!_canPlay) return;
    if (!_run.canLog) {
      _hints.missTap();
      return;
    }
    final kept = _run.log(m, v);
    if (!kept) {
      _note();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.55);
    _stepDone();
    if (_run.switchedOn && _run.afterDone) {
      _maybeCoworker();
      unawaited(_sayChain([_task]));
    }
  }

  void _lever(Offset global) {
    if (_waitForHim()) return;
    final a0 = _run.amps;
    final pf0 = _run.pf;
    final m = _run.lever();
    final moved = (_run.amps - a0).abs() > 1e-9;
    if (moved) {
      HapticFeedback.mediumImpact();
      _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
      _startSwing(a0, pf0);
    }
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (!moved) {
      _note();
      return;
    }
    _stepDone();
  }

  void _startSwing(double a0, double pf0) {
    _fromA = a0;
    _fromPf = pf0;
    _toA = _run.amps;
    _toPf = _run.pf;
    if (_quiet) {
      _swing.value = 1;
      setState(() {});
      return;
    }
    setState(() => _swinging = true);
    _hush();
    unawaited(_swing.forward(from: 0));
  }

  void _swingDone() {
    if (!mounted) return;
    final was = _swinging;
    setState(() {
      _swinging = false;
      _wake++;
    });
    if (was && _card == null && !_ended) unawaited(_sayChain([_task]));
  }

  void _tagHook(Offset global) {
    if (_waitForHim()) return;
    final was = _run.tagged[_run.index];
    final m = _run.tag();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.tagged[_run.index] == was) {
      _note();
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    _stepDone();
  }

  void _signLog(Offset global) {
    if (!_canPlay) return;
    if (_waitForHim()) return;
    final m = _run.sign();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.roundDone) {
      _note();
      return;
    }
    _stepDone();
    unawaited(_bankDone());
  }

  // The pencil: a drag from anywhere on the log sheet picks it up.
  void _panStart(Offset p, M6CbmGeo geo) {
    _pen = null;
    if (!_canPlay || _view != M6CbmView.panel) return;
    if (!geo.log.inflate(10).contains(p)) return;
    if (!_run.canLog) {
      _hints.missTap();
      return;
    }
    setState(() => _pen = p);
  }

  void _panUpdate(Offset p) {
    if (_pen == null) return;
    if (!_canPlay) {
      setState(() => _pen = null);
      return;
    }
    setState(() => _pen = p);
  }

  void _panEnd(M6CbmGeo geo) {
    final p = _pen;
    if (p == null) return;
    setState(() => _pen = null);
    final m = _penStrip(geo, p);
    if (m == null) {
      _hints.missTap();
      return;
    }
    _log(m, geo.valueAtX(m, p.dx));
  }

  /// The strip under the pencil (the nearest one while over the log).
  M6CbmMeter? _penStrip(M6CbmGeo geo, Offset p) {
    final hit = geo.stripAt(p);
    if (hit != null) return hit;
    if (!geo.log.contains(p)) return null;
    final da = (p.dy - geo.strip(M6CbmMeter.amps).center.dy).abs();
    final dp = (p.dy - geo.strip(M6CbmMeter.pf).center.dy).abs();
    return da <= dp ? M6CbmMeter.amps : M6CbmMeter.pf;
  }

  Future<void> _bankDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.why;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M6CapbankMeterLines.whyRight[topic]!, M6CapbankMeterLines.myths, widget.rng),
      question: _run.whyQuestion,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(() {
      _run.next();
      _pen = null;
    });
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _stepDone();
    _maybeCoworker();
    unawaited(_sayChain([_task]));
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
  CoworkerScript get coworkerScript => M6CapbankMeterLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerBank || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _freeze || _swinging || _view != M6CbmView.panel || _pen != null || !_run.coworkerMoment) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.deal.push;
    if (!held) {
      final m = M6CapbankMeterMistakes.push(p);
      if (m.deadly) {
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6CapbankMeterLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6CapbankMeterLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6CapbankMeterLines.tapWhy[_nudgeN++ % M6CapbankMeterLines.tapWhy.length]
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
      _pen = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6cbm/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on the swollen can: the scene freezes grey, the can is shown
  /// close and the flash comes off it in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _view = M6CbmView.yard;
      _zoom = _run.index.clamp(0, 2);
      _pen = null;
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
    final speak = await SpokenOnce.first('m6cbm/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6CapbankMeterLines.deadlyWord : M6CapbankMeterLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        if (_run.closedWrong) {
          // The row was signed wrong: on to the next bank.
          _next();
          return;
        }
        // The same bank goes on from where it was.
        _maybeCoworker();
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
    await _say(!_run.passed ? M6CapbankMeterLines.fail : (_quickBonus ? M6CapbankMeterLines.quick : M6CapbankMeterLines.allSet),
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
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. The yard: a sweep over the
  /// three banks and a tap on 'প্যানেলে যান' in turn (a zoom: a tap on 'ফিরে
  /// যান'). The panel: a short generic nudge of the pencil (left, then up-left
  /// or down-left — never to a value) and a sweep over the lever, the tag hook
  /// and the sign alike; only the sweep once the readings are in, only the
  /// nudge while after-readings are owed.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (_view == M6CbmView.yard) {
      if (_zoom != null) return HintSpec.tapOn(_closeKey);
      if (n.isEven) return HintSpec.sweep([for (var i = 0; i < 3; i++) geo.bank(i)], space: HintSpace.scene);
      return HintSpec.tapOn(_viewKey);
    }
    final decide = HintSpec.sweepOver([_leverKey, _tagKey, _signKey]);
    if (_run.switchedOn && !_run.canLog) return decide;
    if (_run.needAfter || n.isEven) {
      final dir = switch ((n ~/ 2) % 3) {
        0 => const Offset(-1, 0),
        1 => const Offset(-0.94, -0.34),
        _ => const Offset(-0.94, 0.34),
      };
      return HintSpec.drag(geo.pencilRest, toward: dir, travel: 40, space: HintSpace.scene);
    }
    return decide;
  }

  M6CbmPanelRig get _panelRig => M6CbmPanelRig(on: List.of(_run.on), tagged: List.of(_run.tagged), current: _run.index.clamp(0, 2), sky: _run.deal.sky);

  M6CbmLogRig _logRig(M6CbmGeo geo) {
    final p = _pen;
    return M6CbmLogRig(
      bank: _run.index,
      before: Map.of(_run.before),
      after: Map.of(_run.after),
      pencilX: p?.dx,
      pencilOn: p == null ? null : (_penStrip(geo, p) ?? M6CbmMeter.amps),
    );
  }

  Widget _needles(M6CbmGeo geo) {
    Widget paint(double a, double pf) => Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: M6CbmNeedlePainter(geo: geo, meter: M6CbmMeter.amps, value: a))),
            Positioned.fill(child: CustomPaint(painter: M6CbmNeedlePainter(geo: geo, meter: M6CbmMeter.pf, value: pf))),
          ],
        );
    if (!_swinging) return paint(_run.amps, _run.pf);
    return AnimatedBuilder(
      animation: _swing,
      builder: (_, _) {
        final k = Curves.easeOutBack.transform(_swing.value);
        return paint(_fromA + (_toA - _fromA) * k, _fromPf + (_toPf - _fromPf) * k);
      },
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6CbmGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final yard = _view == M6CbmView.yard;
    final i = _run.index.clamp(0, 2);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              if (yard) ...[
                Positioned.fill(
                  key: const ValueKey('yard'),
                  child: RepaintBoundary(child: CustomPaint(painter: M6CbmYardPainter(geo: geo, sky: _run.deal.sky))),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: geo.trainee,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ] else ...[
                Positioned.fill(
                  key: const ValueKey('panel'),
                  child: RepaintBoundary(child: CustomPaint(painter: M6CbmPanelPainter(geo: geo, rig: _panelRig))),
                ),
                Positioned.fill(
                  key: const ValueKey('needles'),
                  child: RepaintBoundary(child: _needles(geo)),
                ),
                Positioned.fill(
                  key: const ValueKey('log'),
                  child: RepaintBoundary(child: CustomPaint(painter: M6CbmLogPainter(geo: geo, rig: _logRig(geo)))),
                ),
              ],
            ],
          ),
        ),
      ),
      // The current bank's lever and tag hook, for the sweep (no paint).
      if (!yard) ...[
        Positioned.fromRect(
          key: ValueKey('lever-box-$i'),
          rect: geo.leverHit(i),
          child: IgnorePointer(child: SizedBox.expand(key: _leverKey)),
        ),
        Positioned.fromRect(
          key: ValueKey('tag-box-$i'),
          rect: geo.tagHit(i),
          child: IgnorePointer(child: SizedBox.expand(key: _tagKey)),
        ),
      ],
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: yard ? M6CapbankMeterLines.yardLabel : M6CapbankMeterLines.panelLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () {
              if (_pen != null) setState(() => _pen = null);
            },
          ),
        ),
      ),
      // The next bank: a short fade.
      if (!_intro && !_freeze && !yard)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.5, end: 0),
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
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final yard = _view == M6CbmView.yard;
    final btnW = math.min(110.0, (size.width - 16) / 3);
    final zoom = _zoom;
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
              labels: [for (var n = 1; n <= 3; n++) M6CapbankMeterLines.bankLabel(n)],
              done: {for (var k = 0; k < math.min(_run.index, 3); k++) k},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_swinging && _pen == null,
            hintKey: '${_run.index}/$_steps/${_view.name}/$_zoom',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && zoom == null)
                Positioned(
                  key: ValueKey('hud-buttons-${_view.name}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  child: Row(
                    children: [
                      _ActionButton(
                        key: _viewKey,
                        icon: yard ? Icons.dashboard_rounded : Icons.forest_rounded,
                        label: yard ? M6CapbankMeterLines.toPanel : M6CapbankMeterLines.toYard,
                        width: btnW,
                        onTap: (_) => _toggleView(),
                      ),
                      if (!yard)
                        _ActionButton(
                          key: _signKey,
                          icon: Icons.draw_rounded,
                          label: M6CapbankMeterLines.sign,
                          width: btnW,
                          onTap: _signLog,
                        ),
                    ],
                  ),
                ),
              if (zoom != null)
                Positioned(
                  key: ValueKey('zoom-$zoom'),
                  left: 18,
                  right: 18,
                  top: pad.top + 118,
                  height: math.min(size.height * 0.52, 430),
                  child: ColorFiltered(
                    colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                    child: Column(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: M6CapbankMeterLines.bankLabel(zoom + 1),
                            child: RepaintBoundary(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: M6CbmZoomPainter(state: _run.deal.banks[zoom].state, defect: _run.deal.banks[zoom].defect, bank: zoom),
                              ),
                            ),
                          ),
                        ),
                        if (!_freeze && !_ended) ...[
                          const SizedBox(height: 8),
                          _ActionButton(
                            key: _closeKey,
                            icon: Icons.close_rounded,
                            label: M6CapbankMeterLines.zoomClose,
                            width: btnW,
                            onTap: (_) => _closeZoom(),
                          ),
                        ],
                      ],
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
                      builder: (_, v, _) => CustomPaint(painter: M6CbmFlashPainter(at: Offset(size.width / 2, pad.top + 118 + math.min(size.height * 0.52, 430) * 0.45), v: v)),
                    ),
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
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
                  line: M6CapbankMeterLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: m6CbmLessonPoint, muted: _muted)),
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

/// A bottom button: a round icon with its name under it.
class _ActionButton extends StatelessWidget {
  const _ActionButton({super.key, required this.icon, required this.label, required this.onTap, this.width = 90});
  final IconData icon;
  final String label;
  final double width;
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
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: SlmColors.gold300),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
