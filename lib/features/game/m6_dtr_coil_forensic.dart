import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'm6_dtr_coil_forensic_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm6_dtr_coil_forensic_world.dart' show M6Family, M6Gel, M6LeakSource, M6Part, M6Sign;

// Lesson 6.1 "ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড", কাজ 2
// "ক্ষতির খোঁজে কয়েল" (pack do_6_1_b, engineType m6_dtr_coil_forensic).
// Verb: turn the opened coil, read the damage to its cause.
//
// Four cases, dealt fresh:
//  Field (2, short): a pole-mounted DTR close up, one outside sign each
//    (lesson 6.1 section 6), dealt from a steady hum (normal), an oil leak
//    with the gauge under MIN, pink or white silica gel, dark burnt drain oil
//    after a trip, popping or crackling — never the same sign twice. Sound
//    signs: hold the ear button first. Swipe across the tank: the X-ray
//    cutaway opens. Drag from the sign and let go on the ONE inner thing it
//    harms (oil · paper · coil · connection) or on "normal" for the hum.
//    Then drag (or open and ✓) one action tag; the trap "open the tank on
//    the pole" is on every rail. Right → the harm runs along the link → ◆ on
//    the table → "কেন …?".
//  Shop (2, the core): an opened coil on a turntable. Drag to turn it; the
//    damage is drawn on one face only. Once the damage has been turned into
//    view, the damage family (a tag) names it (a tap on the damage first is
//    optional: it marks it found, +5; a tap on a clean face is a wrong flag,
//    a slip); then the cause (all seven shown). Right family + a cause from
//    its lesson group → ◆ → "কেন …?".
//
// Deadly vs slip (module 6 table after the 2026-11-15 rulings, M6-4 / X2):
// re-charging the tripped DTR with dark, burnt drain oil (R21) is DEADLY —
// it comes only as the coworker's push on the dark-oil case (listening =
// that deadly, B1). Opening the tank in the field (R20, the trap tag or the
// coworker's myth-3 push) is a SLIP (lowered by M6-4: the art of its card
// shows the DTR dead and earthed; moisture and oil vapour, not shock). Slips:
// a sign linked to the wrong inner thing; the hum called a fault; a real
// sign called normal; a wrong action; in the shop a tap on a clean face, a
// wrong family, a cause from the other group, or a family named before the
// damaged face was ever turned into view.
// Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_dtr_coil_forensic_world.dart), the corner guide, ReasonTable
// (the cards come at once), the coworker once a play on a field case after
// the link (the action rail waits for him: holdForCoworker), mistakes with
// their lesson points, the deadly freeze, the gesture hand (how, never what).

// ============================================================================
// Content
// ============================================================================

/// The actions on the field rail ([tank] is the trap on every rail).
enum M6Act { leakFix, gel, isolate, report, tank }

/// The causes on the shop's rail (lesson 6.1 points 7 and 8): the first four
/// make thermal damage; the last three make arc, inter-turn and mechanical
/// damage.
enum M6Cause { overload, lowOil, blockedAir, water, shorts, lightning, weakEarth }

/// The coworker's push (one per play, on a field case after the link).
enum M6Push { tank, recharge }

/// What a case's reason asks about.
enum M6WhyTopic { link, action, hum, family, cause }

/// The inner things each sign may be linked to (spec flow[2]).
const m6Accepted = <M6Sign, Set<M6Part>>{
  M6Sign.hum: {M6Part.normal},
  M6Sign.leak: {M6Part.coil, M6Part.paper},
  M6Sign.gel: {M6Part.paper, M6Part.oil},
  M6Sign.burnt: {M6Part.paper, M6Part.coil},
  M6Sign.crackle: {M6Part.conn},
};

/// The right action for a sign (none for the normal hum).
M6Act? m6ActFor(M6Sign s) => switch (s) {
      M6Sign.hum => null,
      M6Sign.leak => M6Act.leakFix,
      M6Sign.gel => M6Act.gel,
      M6Sign.burnt => M6Act.isolate,
      M6Sign.crackle => M6Act.report,
    };

/// A sound sign: the ear first.
bool m6Sound(M6Sign s) => s == M6Sign.hum || s == M6Sign.crackle;

/// Thermal causes (point 7); the rest belong to points 8's group.
bool m6ThermalCause(M6Cause c) => c.index < 4;

/// A cause fits a family when it is from that family's lesson group.
bool m6CauseFits(M6Family f, M6Cause c) => (f == M6Family.thermal) == m6ThermalCause(c);

/// The lesson point (0-based) that teaches a family (thermal: point 7 → 6;
/// the others: point 8 → 7).
int m6FamilyPoint(M6Family f) => f == M6Family.thermal ? 6 : 7;

abstract final class M6CoilLines {
  static const title = 'ক্ষতির খোঁজে কয়েল';

  // DRAFT wording — owner (M6-12). The intro is the spec's line.
  static const intro = 'বাইরের লক্ষণ ভেতরের কোন ক্ষতির খবর দিচ্ছে? খুঁজে দেখান।';
  static const askField = 'বাইরের লক্ষণটা খুঁজুন — ভেতরের কোন জিনিসের ক্ষতি করছে?';
  static const askAct = 'এই লক্ষণে এখন কী করবেন? কাজটা বেছে নিন।';
  static const askShop = 'এই DTR-টা শপে খোলা হয়েছে — কয়েল ঘুরিয়ে দেখুন, ক্ষতি কোথায়, কেন।';
  static const askFamily = 'এটা কোন ধরনের ক্ষতি?';
  static const askCause = 'কী কারণে এমন হলো?';
  static const tasks = [askField, askAct, askShop, askFamily, askCause];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (the X-ray zones, the ear).
  static const ear = 'কান পাতুন';
  static const sceneField = 'পোলের ডিস্ট্রিবিউশন ট্রান্সফরমার';
  static const sceneShop = 'মেরামত শপে খোলা কয়েল';
  static String part(M6Part p) => switch (p) {
        M6Part.oil => 'ভেতরের খনিজ তেল',
        M6Part.paper => 'কাগজের ইনসুলেশন',
        M6Part.coil => 'HT/LT তামার কয়েল',
        M6Part.conn => 'ভেতরের কানেকশন',
        M6Part.normal => 'স্বাভাবিক অবস্থা',
      };
  static String round(int i) => i < 2 ? 'মাঠ' : 'শপ';

  // The tags (all on every rail; 27–30 / 16–18 / 18–22 letters).
  static String act(M6Act a) => switch (a) {
        M6Act.leakFix => 'দ্রুত খবর দিন, লিক বন্ধ করান',
        M6Act.gel => 'সিলিকা জেল দ্রুত বদলে ফেলুন',
        M6Act.isolate => 'বিচ্ছিন্ন করে DGA/BDV পরীক্ষা',
        M6Act.report => 'দ্রুত রিপোর্ট, পরীক্ষার অনুরোধ',
        M6Act.tank => 'পোলেই ট্যাঙ্ক খুলে ভেতরটা দেখি',
      };
  static String family(M6Family f) => switch (f) {
        M6Family.thermal => 'তাপীয় পোড়া ক্ষতি',
        M6Family.arc => 'তীব্র আর্কের ক্ষতি',
        M6Family.turn => 'ইন্টার-টার্ন ফল্ট',
        M6Family.mech => 'যান্ত্রিক ধাক্কা',
      };
  static String cause(M6Cause c) => switch (c) {
        M6Cause.overload => 'দীর্ঘ সময় ধরে ওভারলোড',
        M6Cause.lowOil => 'ট্যাঙ্কে তেল কম ছিল',
        M6Cause.blockedAir => 'বাতাস চলার পথ বন্ধ',
        M6Cause.water => 'তেলে জল ঢুকে গিয়েছিল',
        M6Cause.shorts => 'ঘনঘন কড়া শর্ট সার্কিট',
        M6Cause.lightning => 'লাইনের ওপর বাজ পড়েছিল',
        M6Cause.weakEarth => 'আর্থিং খুব দুর্বল ছিল',
      };

  // The reasons (spoken questions; the cards are not spoken). The right ones
  // fit what was done; the wrong ones are the lesson's myths and field
  // excuses. All 28–40 letters.
  static const whyQ = <M6WhyTopic, String>{
    M6WhyTopic.link: 'লক্ষণটা ভেতরে কোথায় ক্ষতি করছে, কেন?',
    M6WhyTopic.action: 'এই লক্ষণে এই কাজটাই কেন?',
    M6WhyTopic.hum: 'গুনগুন শব্দে রিপোর্ট করলেন না কেন?',
    M6WhyTopic.family: 'শপের কয়েলে এটাকে কেন এই ক্ষতি ধরলেন?',
    M6WhyTopic.cause: 'এই কারণটাই কেন বাছলেন?',
  };
  static const whyLink = <M6Sign, List<String>>{
    M6Sign.leak: ['তেল কমে কয়েল গরম হয়, ফাঁকে জলীয় বাষ্পও ঢোকে', 'লিকে তেল কমে — কয়েল ঠান্ডা হয় না, কাগজ ভেজে'],
    M6Sign.gel: ['গোলাপি জেল মানে আর্দ্রতা ঢুকছে — তেল ও কাগজ দুর্বল', 'ব্রিদার দিয়ে বাষ্প ঢুকে তেল ও কাগজ ভিজছে'],
    M6Sign.burnt: ['পোড়া কালো তেল মানে আর্ক — কাগজ পুড়ে কয়লা', 'ভেতরে আর্ক বা ওভারহিটে কয়েলের কাগজ পুড়েছে'],
    M6Sign.crackle: ['পটপট শব্দ মানে আলগা কানেকশন বা ওয়াইন্ডিং ফল্ট', 'ছড়ছড় শব্দ মানে ভেতরে আলগা কানেকশনের খবর'],
  };
  static const whyAct = <M6Sign, List<String>>{
    M6Sign.leak: ['তেল কমলে কয়েল পোড়ে — তাই খবর দিয়ে লিক বন্ধ', 'লিক থামালে তেলও থাকে, জলীয় বাষ্পও ঢোকে না'],
    M6Sign.gel: ['ভেজা জেল আর আর্দ্রতা শোষে না — বদলাতেই হবে', 'নতুন জেল আবার বাষ্প শুষবে, ভেতরটা শুকনো থাকবে'],
    M6Sign.burnt: ['পোড়া তেলে চার্জ নয় — বিচ্ছিন্ন করে তেল পরীক্ষা', 'বড় ক্ষতির সঙ্কেত, তাই বিচ্ছিন্ন করে DGA বা BDV'],
    M6Sign.crackle: ['আগাম ফল্ট ধরা পড়লে দ্রুত রিপোর্ট আর পরীক্ষা চাই', 'আলগা কানেকশন ভেতরের ব্যাপার — রিপোর্ট ও পরীক্ষা'],
  };
  static const whyHum = ['হালকা একটানা গুনগুন শব্দ সম্পূর্ণ স্বাভাবিক', 'কোরের চুম্বকত্বে এই গুনগুন হয় — এটা স্বাভাবিক'];
  static const whyFamily = <M6Family, List<String>>{
    M6Family.thermal: ['ওপরের দিকের কাগজ কালো — গরম তেল ওপরে ওঠে', 'কাগজ পুড়ে কার্বন হয়েছে — এটা তাপীয় ক্ষতি'],
    M6Family.arc: ['তামা গলে দলা পাকিয়েছে — তীব্র আর্কের প্রমাণ', 'তার গলে ছিটকে গেছে — হাই-কারেন্ট আর্ক হয়েছিল'],
    M6Family.turn: ['এক জায়গায় টার্ন পুড়ে ফেটে আছে — টার্নে শর্ট', 'কয়েলের টার্নে টার্নে শর্ট হয়েছে — ইন্টার-টার্ন'],
    M6Family.mech: ['কয়েল বেঁকে ফুলে সরে গেছে — চৌম্বকীয় ধাক্কা', 'শর্ট সার্কিটের ধাক্কায় কয়েল জায়গা থেকে সরেছে'],
  };
  static const whyCauseThermal = ['তাপীয় ক্ষতি আসে ওভারলোড, তেল কম বা বাতাস বন্ধে', 'দীর্ঘ গরমেই কাগজ পোড়ে — ওভারলোড, তেল কম, জল'];
  static const whyCauseHeavy = ['এমন ক্ষতি আসে কড়া শর্ট, বাজ বা দুর্বল আর্থিংয়ে', 'বড় কারেন্টের ধাক্কা — শর্ট, বাজ বা দুর্বল আর্থ'];
  static const myths = [
    'সামান্য তেল চুইয়ে পড়লে কিছু যায় আসে না',
    'গুনগুন শব্দ মানেই ভেতরে বড় কোনো গোলমাল',
    'পোলের ওপরেই ট্যাঙ্ক খুলে কয়েল সারানো যায়',
    'সিলিকা জেলের রঙ বদলালে কিছুই যায় আসে না',
    'তেল কালো হলেও আবার চার্জ করলে দিব্যি চলবে',
    'আন্দাজে বলে দিলেই হয়, খুঁটিয়ে দেখার দরকার নেই',
    'বাজ পড়লে শুধু ফিউজ যায়, কয়েলের কিছু হয় না',
  ];

  static List<String> whyRight(M6WhyTopic t, {M6Sign? sign, M6Family? family}) => switch (t) {
        M6WhyTopic.link => whyLink[sign]!,
        M6WhyTopic.action => whyAct[sign]!,
        M6WhyTopic.hum => whyHum,
        M6WhyTopic.family => whyFamily[family]!,
        M6WhyTopic.cause => family == M6Family.thermal ? whyCauseThermal : whyCauseHeavy,
      };
  static List<String> get allWhyRight => [
        for (final l in whyLink.values) ...l,
        for (final l in whyAct.values) ...l,
        ...whyHum,
        for (final l in whyFamily.values) ...l,
        ...whyCauseThermal,
        ...whyCauseHeavy,
      ];

  // The careless coworker (one push a play). His exit is already recorded.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';

  /// Lesson 6.1 myth 3 word for word, then his push (DRAFT wording — owner).
  static const myth3 = 'মাঠে পোলের ওপরে ঝুলন্ত অবস্থাতেই ট্রান্সফরমারের ট্যাঙ্ক খুলে কয়েল ঠিক করে ফেলা যায়।';
  static const coworkerTank = CoworkerScript(
    line: '$myth3 চলো, ঢাকনাটা খুলি!',
    exitLine: coworkerExit,
    right: ['না, ট্যাঙ্ক খোলা হয় শুধু মেরামত শপে', 'না, খোলা বাতাসে ট্যাঙ্ক খোলা বারণ', 'না, ধুলো আর আর্দ্রতা ভেতরে ঢুকবে'],
    wrong: [
      'ঠিক, ঢাকনাটা এখনই খুলে দেখে নিই',
      'আচ্ছা, পোলেই কয়েলটা সারিয়ে দিই',
      'হ্যাঁ, শপে পাঠানোর ঝামেলা কে করে',
      'ঠিক আছে, একটু খুলে দেখলে ক্ষতি নেই',
      'হ্যাঁ, এখানেই খুলে কাজ সেরে ফেলি',
    ],
    asks: ['কী করবেন?', 'ও বলছে পোলেই ট্যাঙ্ক খুলতে। কী করবেন?', 'মাঠে ট্যাঙ্ক খুলবেন?'],
  );

  /// The recharge push (the dark-oil case only; DRAFT wording — owner).
  static const coworkerRecharge = CoworkerScript(
    line: 'তেল একটু কালো তো কী! HG ফিউজের তার বেঁধে আবার চার্জ করে দেখি, চলবে।',
    exitLine: coworkerExit,
    right: ['না, পোড়া তেল মানে কাগজ পুড়েছে', 'না, পরীক্ষার আগে চার্জ করা যাবে না', 'না, আগে তেলের DGA/BDV পরীক্ষা হবে'],
    wrong: [
      'ঠিক, HG ফিউজের তার বেঁধে চার্জ করে দেখি',
      'আচ্ছা, একটু কালো তেলে কী আর হয়',
      'হ্যাঁ, চালিয়ে দেখি, চললে তো ভালো',
      'ঠিক আছে, পরীক্ষার ঝামেলা কে করে',
      'হ্যাঁ, লোকের লাইন তো ফেরাতে হবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে আবার চার্জ করতে। কী করবেন?', 'পোড়া তেলে চার্জ করবেন?'],
  );
  static CoworkerScript coworker(M6Push p) => switch (p) {
        M6Push.tank => coworkerTank,
        M6Push.recharge => coworkerRecharge,
      };
  static const allCoworkers = [coworkerTank, coworkerRecharge];

  static String callHeld(M6Push p) => switch (p) {
        M6Push.tank => 'ঠিক! ট্যাঙ্ক খোলা শুধু মেরামত শপে।',
        M6Push.recharge => 'একদম ঠিক! পোড়া তেলে আর চার্জ নয়।',
      };

  static const allSet = 'বাইরের লক্ষণ থেকে ভেতরের ক্ষতি — সবই ঠিক ধরেছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — লক্ষণ দেখে ভেতরের ক্ষতি, তারপর কাজ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static String caughtSign(M6Sign s) => switch (s) {
        M6Sign.hum => 'গুনগুন শব্দ স্বাভাবিক — চিনেছেন',
        M6Sign.leak => 'লিক আর কম তেল → কয়েল গরম',
        M6Sign.gel => 'গোলাপি জেল → ভেতরে আর্দ্রতা',
        M6Sign.burnt => 'পোড়া কালো তেল → কাগজ পুড়েছে',
        M6Sign.crackle => 'পটপট শব্দ → আলগা কানেকশন',
      };
  static String caughtFamily(M6Family f) => 'শপে চিনেছেন: ${family(f)}';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new line the guide speaks (DRAFT wording — owner; device voice
  /// until recorded). The mistake texts are spoken too (the first time).
  static List<String> get newGuideLines => [
        intro,
        askField,
        askAct,
        askShop,
        askFamily,
        askCause,
        ...whyQ.values,
        for (final cw in allCoworkers) ...cw.asks.where((a) => a != 'কী করবেন?'),
        for (final p in M6Push.values) callHeld(p),
        allSet,
        fail,
        for (final m in M6CoilMistakes.all) m.textBn,
      ];

  /// The coworker's new lines (his recorded voice; no clip yet).
  static List<String> get newRivalLines => [coworkerTank.line, coworkerRecharge.line];
}

abstract final class M6CoilMistakes {
  static const _dir = 'assets/game/art/m6_dtr_coil_forensic';
  static const _k = '6.1/m6_dtr_coil_forensic';

  // DRAFT wording — owner (M6-12), built from lesson 6.1's own words.
  static const humFault = DoMistake(
    key: '$_k/hum-fault',
    textBn: 'হালকা, একটানা গুনগুন শব্দ সম্পূর্ণ স্বাভাবিক — এর জন্য রিপোর্ট বা মেরামত লাগে না।',
    art: '$_dir/hum.svg',
    lessonPoint: 2,
  );
  static const calledNormal = DoMistake(
    key: '$_k/called-normal',
    textBn: 'এটা স্বাভাবিক নয়! বাইরের এই লক্ষণ ভেতরের ক্ষতির খবর দিচ্ছে।',
    art: '$_dir/normal_no.svg',
    lessonPoint: 5,
  );
  static const linkLeak = DoMistake(
    key: '$_k/link-leak',
    textBn: 'তেল চুঁইয়ে পড়ছে, তেলও কম → কয়েল ঠান্ডা হতে পারছে না; আর ফাটল দিয়ে জল ঢুকে ভেতরের কাগজ নষ্ট।',
    art: '$_dir/leak.svg',
    lessonPoint: 5,
  );
  static const linkGel = DoMistake(
    key: '$_k/link-gel',
    textBn: 'গোলাপি সিলিকা জেল → জলীয় বাষ্প ঢুকেছে → ভেতরের তেল ও ইনসুলেশন কাগজ আর্দ্রতা শুষে দুর্বল হচ্ছে।',
    art: '$_dir/gel.svg',
    lessonPoint: 5,
  );
  static const linkBurnt = DoMistake(
    key: '$_k/link-burnt',
    textBn: 'পোড়া গন্ধ বা কালচে তেল → ভেতরে তীব্র আর্ক বা ওভারহিটিং → কয়েলের ইনসুলেশন কাগজ পুড়ে কয়লা।',
    art: '$_dir/burnt.svg',
    lessonPoint: 5,
  );
  static const linkCrackle = DoMistake(
    key: '$_k/link-crackle',
    textBn: 'শব্দ বদলে পটপট বা ছড়ছড় → ভেতরে কোথাও আলগা কানেকশন বা ওয়াইন্ডিংয়ে আগাম ফল্ট।',
    art: '$_dir/crackle.svg',
    lessonPoint: 5,
  );
  static const actLeak = DoMistake(
    key: '$_k/act-leak',
    textBn: 'তেল লিক আর তেল কমে গেলে কাজ: দ্রুত খবর দেওয়া ও লিক বন্ধ করার ব্যবস্থা।',
    art: '$_dir/leak.svg',
    lessonPoint: 5,
  );
  static const actGel = DoMistake(
    key: '$_k/act-gel',
    textBn: 'গোলাপি বা সাদাটে জেলে কাজ: দ্রুত সিলিকা জেল বদলে ফেলা।',
    art: '$_dir/gel.svg',
    lessonPoint: 5,
  );
  static const actBurnt = DoMistake(
    key: '$_k/act-burnt',
    textBn: 'পোড়া গন্ধের কালচে তেলে কাজ: দ্রুত লাইন থেকে বিচ্ছিন্ন করে DGA বা BDV পরীক্ষা।',
    art: '$_dir/burnt.svg',
    lessonPoint: 5,
  );
  static const actCrackle = DoMistake(
    key: '$_k/act-crackle',
    textBn: 'পটপট বা ছড়ছড় শব্দে কাজ: দ্রুত রিপোর্ট করুন ও পরীক্ষার অনুরোধ জানান।',
    art: '$_dir/crackle.svg',
    lessonPoint: 5,
  );

  /// Field tank opening (R20): a SLIP after M6-4 (the card's art shows the
  /// DTR dead and earthed). Card text: the ruling's DRAFT + the lesson.
  static const tankOpen = DoMistake(
    key: '$_k/tank-open',
    textBn: 'মাঠে ট্যাঙ্ক খোলা বারণ — ভেতরে আর্দ্রতা ও তেল-বাষ্পে আগুনের ঝুঁকি। ট্যাঙ্ক খোলা হয় শুধু মেরামত শপে, শুকনো পরিবেশে।',
    art: '$_dir/tank_open.svg',
    lessonPoint: 3,
  );

  /// Re-charging the burnt-oil DTR (R21): DEADLY (lesson 6.1 point 8's
  /// safety tip, M6-4).
  static const recharge = DoMistake(
    key: '$_k/recharge',
    textBn: 'পোড়া কালো তেল মানে ভেতরের কাগজ পুড়ে কয়লা — পুনরায় কোনোভাবে চার্জ করার ঝুঁকি নেবেন না! বিচ্ছিন্ন রেখে DGA বা BDV পরীক্ষা।',
    art: '$_dir/recharge.svg',
    deadly: true,
    lessonPoint: 7,
  );

  static const famThermal = DoMistake(
    key: '$_k/family-thermal',
    textBn: 'কাগজ কালো হয়ে কার্বন, তাও কয়েলের ওপরের দিকে — এটা তাপীয় ক্ষতি।',
    art: '$_dir/s_thermal.svg',
    lessonPoint: 6,
  );
  static const famArc = DoMistake(
    key: '$_k/family-arc',
    textBn: 'তামার তার গলে দলা পাকানো বা ছিটকে যাওয়া — তীব্র আর্কের প্রমাণ।',
    art: '$_dir/s_arc.svg',
    lessonPoint: 7,
  );
  static const famTurn = DoMistake(
    key: '$_k/family-turn',
    textBn: 'এক জায়গায় তারের টার্ন পুড়ে ফেটে আছে — কয়েলের ইন্টার-টার্ন ফল্ট।',
    art: '$_dir/s_turn.svg',
    lessonPoint: 7,
  );
  static const famMech = DoMistake(
    key: '$_k/family-mech',
    textBn: 'গোটা কয়েল বেঁকে, ফুলে বা সরে গেছে — শর্ট সার্কিটের প্রচণ্ড চৌম্বকীয় ধাক্কা।',
    art: '$_dir/s_mech.svg',
    lessonPoint: 7,
  );
  static const causeThermal = DoMistake(
    key: '$_k/cause-thermal',
    textBn: 'তাপীয় ক্ষতির কারণ: দীর্ঘ ওভারলোড, ট্যাঙ্কে তেল কম, বাতাসের পথ বন্ধ বা তেলে জল।',
    art: '$_dir/s_thermal.svg',
    lessonPoint: 6,
  );
  static const causeHeavy = DoMistake(
    key: '$_k/cause-heavy',
    textBn: 'গলা তামা, ফাটা টার্ন বা বাঁকা কয়েলের কারণ: ঘনঘন কড়া শর্ট সার্কিট, লাইনে বাজ বা খুব দুর্বল আর্থিং।',
    art: '$_dir/s_arc.svg',
    lessonPoint: 7,
  );
  static const cleanFace = DoMistake(
    key: '$_k/clean-face',
    textBn: 'এদিকে ক্ষতি নেই — কাগজ স্বাভাবিক হলুদ-বাদামি, তামাও ঠিক আছে। ভালো করে চিনে তবেই ক্ষতি দেখান।',
    art: '$_dir/clean.svg',
    lessonPoint: 6,
  );
  static const guess = DoMistake(
    key: '$_k/guess',
    textBn: 'আগে কয়েল ঘুরিয়ে ক্ষতিটা খুঁজে দেখুন — না দেখে আন্দাজে ক্ষতির নাম নয়।',
    art: '$_dir/guess.svg',
    lessonPoint: 6,
  );

  static DoMistake link(M6Sign s) => switch (s) {
        M6Sign.hum => humFault,
        M6Sign.leak => linkLeak,
        M6Sign.gel => linkGel,
        M6Sign.burnt => linkBurnt,
        M6Sign.crackle => linkCrackle,
      };
  static DoMistake act(M6Sign s) => switch (s) {
        M6Sign.hum => humFault,
        M6Sign.leak => actLeak,
        M6Sign.gel => actGel,
        M6Sign.burnt => actBurnt,
        M6Sign.crackle => actCrackle,
      };
  static DoMistake family(M6Family f) => switch (f) {
        M6Family.thermal => famThermal,
        M6Family.arc => famArc,
        M6Family.turn => famTurn,
        M6Family.mech => famMech,
      };
  static DoMistake cause(M6Family f) => f == M6Family.thermal ? causeThermal : causeHeavy;
  static DoMistake push(M6Push p) => switch (p) {
        M6Push.tank => tankOpen,
        M6Push.recharge => recharge,
      };

  static const List<DoMistake> all = [
    humFault,
    calledNormal,
    linkLeak,
    linkGel,
    linkBurnt,
    linkCrackle,
    actLeak,
    actGel,
    actBurnt,
    actCrackle,
    tankOpen,
    recharge,
    famThermal,
    famArc,
    famTurn,
    famMech,
    causeThermal,
    causeHeavy,
    cleanFace,
    guess,
  ];

  /// The level's deadly mistake keys (catalog deadlyRules).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

/// One field case.
@immutable
class M6FieldCase {
  const M6FieldCase({required this.sign, required this.acts, this.source = M6LeakSource.gasket, this.gel = M6Gel.blue, this.pop = false, this.light = 0});

  final M6Sign sign;

  /// The rail's tags, shuffled (all five, the trap among them).
  final List<M6Act> acts;
  final M6LeakSource source;
  final M6Gel gel;

  /// The sound of a popping (পটপট) or a crackling (ছড়ছড়) DTR.
  final bool pop;
  final int light;
}

/// One shop coil.
@immutable
class M6ShopCase {
  const M6ShopCase({required this.family, required this.damageFace, required this.startFace, required this.families, required this.causes, this.light = 0});

  final M6Family family;

  /// The face with the damage and the face turned to the player at first
  /// (never the same).
  final int damageFace;
  final int startFace;

  /// The rails, shuffled.
  final List<M6Family> families;
  final List<M6Cause> causes;
  final int light;
}

@immutable
class M6CoilDeal {
  const M6CoilDeal({required this.field, required this.shop, required this.coworkerCase, required this.push, required this.why});

  /// Two field cases (different signs), then two shop coils (different
  /// families).
  final List<M6FieldCase> field;
  final List<M6ShopCase> shop;

  /// The field case he comes on (never the hum) and his push.
  final int coworkerCase;
  final M6Push push;

  /// What each case's reason asks about (four, in case order).
  final List<M6WhyTopic> why;
}

M6CoilDeal m6CoilDeal(math.Random rng) {
  final signs = [...M6Sign.values]..shuffle(rng);
  final field = <M6FieldCase>[];
  final why = <M6WhyTopic>[];
  for (final s in signs.take(2)) {
    final gel = s == M6Sign.gel ? (rng.nextBool() ? M6Gel.pink : M6Gel.white) : (rng.nextBool() ? M6Gel.blue : M6Gel.orange);
    field.add(M6FieldCase(
      sign: s,
      acts: [...M6Act.values]..shuffle(rng),
      source: M6LeakSource.values[rng.nextInt(3)],
      gel: gel,
      pop: rng.nextBool(),
      light: rng.nextInt(m6LightCount),
    ));
    why.add(s == M6Sign.hum ? M6WhyTopic.hum : (rng.nextBool() ? M6WhyTopic.link : M6WhyTopic.action));
  }
  final fams = [...M6Family.values]..shuffle(rng);
  final shop = <M6ShopCase>[];
  for (final f in fams.take(2)) {
    final dmg = rng.nextInt(m6Faces);
    shop.add(M6ShopCase(
      family: f,
      damageFace: dmg,
      startFace: (dmg + 1 + rng.nextInt(m6Faces - 1)) % m6Faces,
      families: [...M6Family.values]..shuffle(rng),
      causes: [...M6Cause.values]..shuffle(rng),
      light: rng.nextInt(m6LightCount),
    ));
    why.add(rng.nextBool() ? M6WhyTopic.family : M6WhyTopic.cause);
  }
  final able = [for (var i = 0; i < 2; i++) if (field[i].sign != M6Sign.hum) i];
  final at = able[rng.nextInt(able.length)];
  final push = field[at].sign == M6Sign.burnt && rng.nextBool() ? M6Push.recharge : M6Push.tank;
  return M6CoilDeal(field: field, shop: shop, coworkerCase: at, push: push, why: why);
}

/// The play state (pure logic).
class M6CoilRun {
  M6CoilRun(this.deal);
  final M6CoilDeal deal;

  int index = 0;
  int slips = 0;
  int caseSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The case is answered (its reason comes next).
  var roundDone = false;

  // The field case.
  var listened = false;
  var xray = false;
  M6Part? linked;
  var acted = false;

  // The shop coil.
  int facing = 0;
  final Set<int> seen = {};
  var found = false;
  var familyDone = false;

  static const cases = 4;
  bool get done => index >= cases;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => caseSlips == 0;
  bool get _open => !ended && !roundDone;

  bool get inField => index < 2;
  M6FieldCase get field => deal.field[index.clamp(0, 1)];
  M6ShopCase get shop => deal.shop[(index - 2).clamp(0, 1)];

  /// The sign can be dragged: a sound sign only once heard.
  bool get pinReady => inField && (!m6Sound(field.sign) || listened);

  /// The rail is up: the link made on a real sign, no action yet.
  bool get actionUp => inField && linked != null && field.sign != M6Sign.hum && !acted && !roundDone;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    caseSlips++;
    return m;
  }

  /// Hold the ear: the DTR's sound (the sound marks show in a sound case).
  void listen() {
    if (_open && inField) listened = true;
  }

  /// A swipe across the tank: the X-ray cutaway.
  void openXray() {
    if (_open && inField) xray = true;
  }

  /// The sign dropped on [p]. A link the sign may take sets it (the hum on
  /// "normal" ends the case); anything else is a slip and nothing is set.
  DoMistake? link(M6Part p) {
    if (!_open || !inField || !xray || !pinReady || linked != null) return null;
    final s = field.sign;
    if (m6Accepted[s]!.contains(p)) {
      linked = p;
      if (s == M6Sign.hum) {
        roundDone = true;
        _tag(M6CoilLines.caughtSign(s));
      }
      return null;
    }
    if (s == M6Sign.hum) return _slip(M6CoilMistakes.humFault);
    if (p == M6Part.normal) return _slip(M6CoilMistakes.calledNormal);
    return _slip(M6CoilMistakes.link(s));
  }

  /// The action tag committed (the trap: a slip after M6-4, never deadly).
  DoMistake? act(M6Act a) {
    if (!actionUp) return null;
    if (a == M6Act.tank) return _slip(M6CoilMistakes.tankOpen);
    if (a != m6ActFor(field.sign)) return _slip(M6CoilMistakes.act(field.sign));
    acted = true;
    roundDone = true;
    _tag(M6CoilLines.caughtSign(field.sign));
    return null;
  }

  /// The coil turned to face [f].
  void turnTo(int f) {
    if (!_open || inField) return;
    facing = f % m6Faces;
    seen.add(facing);
  }

  /// A tap on the coil's face toward the player (optional): the damage marks
  /// it found; a clean face is a wrong flag (a slip, PARALLEL_BUILD_PLAN §4).
  DoMistake? tapCoil() {
    if (!_open || inField || found) return null;
    if (facing != shop.damageFace) return _slip(M6CoilMistakes.cleanFace);
    found = true;
    return null;
  }

  /// The family tag. Named before the damaged face was ever turned into view
  /// it is a guess (a slip); once it has been seen, naming it is the find.
  DoMistake? family(M6Family f) {
    if (!_open || inField || familyDone) return null;
    if (!found) {
      if (!seen.contains(shop.damageFace)) return _slip(M6CoilMistakes.guess);
      found = true;
    }
    if (f != shop.family) return _slip(M6CoilMistakes.family(shop.family));
    familyDone = true;
    return null;
  }

  /// The cause tag: one from the family's lesson group.
  DoMistake? cause(M6Cause c) {
    if (!_open || inField || !familyDone) return null;
    if (!m6CauseFits(shop.family, c)) return _slip(M6CoilMistakes.cause(shop.family));
    roundDone = true;
    _tag(M6CoilLines.caughtFamily(shop.family));
    return null;
  }

  /// His moment: his case, the link made, the action not yet.
  bool get coworkerGate => index == deal.coworkerCase && actionUp;

  DoMistake pushSlip(DoMistake m) => _slip(m);
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    caseSlips = 0;
    roundDone = false;
    listened = false;
    xray = false;
    linked = null;
    acted = false;
    found = false;
    familyDone = false;
    seen.clear();
    if (!inField && !done) {
      facing = shop.startFace;
      seen.add(facing);
    }
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   field (visual): swipe, link drag, action drag, harm ≈ 6500 + reason ~8200
///   field (sound): + the ear ≈ 8000 + reason ~8200
///   shop: two turns, tap, family, cause ≈ 7500 + reason ~8200 (× 2)
/// + the coworker once ≈ 9600                                     ≈ 72800
/// 85 % ≈ 61900 → 60 s.
const m6CoilQuickMs = 60000;

@immutable
class M6CoilPack {
  const M6CoilPack({required this.id, required this.titleBn, this.quickMs = m6CoilQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6CoilPack> m6CoilPacks = {
  'do_6_1_b': M6CoilPack(id: 'do_6_1_b', titleBn: M6CoilLines.title),
};

/// The listening clips: a running DTR's steady hum (module 5's clip), and
/// the popping / crackling of a loose connection — wordless.
const m6HumSteady = 'game/art/m5_cause_strike/hum_steady.ogg';
const m6Pop = 'game/art/m6_dtr_coil_forensic/pop.ogg';
const m6Crackle = 'game/art/m6_dtr_coil_forensic/crackle.ogg';

/// What the ear hears on a case (null: silence — the tripped DTR).
String? m6EarClip(M6FieldCase c) => switch (c.sign) {
      M6Sign.burnt => null,
      M6Sign.crackle => c.pop ? m6Pop : m6Crackle,
      _ => m6HumSteady,
    };

// ============================================================================
// Page
// ============================================================================

enum _TagKind { act, family, cause }

@immutable
class _Tag {
  const _Tag(this.kind, this.value);
  final _TagKind kind;
  final int value;

  String get text => switch (kind) {
        _TagKind.act => M6CoilLines.act(M6Act.values[value]),
        _TagKind.family => M6CoilLines.family(M6Family.values[value]),
        _TagKind.cause => M6CoilLines.cause(M6Cause.values[value]),
      };
  String get id => '${kind.name}-$value';

  @override
  bool operator ==(Object other) => other is _Tag && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);
}

class M6DtrCoilForensicPage extends StatefulWidget {
  const M6DtrCoilForensicPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6CoilPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6DtrCoilForensicPage> createState() => _M6DtrCoilForensicPageState();
}

class _M6DtrCoilForensicPageState extends State<M6DtrCoilForensicPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CoilRunPage(
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

class _CoilRunPage extends ConsumerStatefulWidget {
  const _CoilRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6CoilPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CoilRunPage> createState() => _CoilRunPageState();
}

class _CoilRunPageState extends ConsumerState<_CoilRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  final _sceneKey = GlobalKey();
  late final M6CoilRun _run;
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

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The harm running along the link (after the right action).
  var _harm = false;

  /// The link line (sign → finger while dragging; sign → part once linked).
  final _line = ValueNotifier<(Offset, Offset)?>(null);

  /// The coil's turn (radians).
  final _angle = ValueNotifier<double>(0);

  // A drag on the scene: the X-ray swipe, the sign's pin, the coil's turn.
  Offset? _swipeFrom;
  Offset _swipeNow = Offset.zero;
  var _pinDrag = false;
  double? _turnFrom;
  double _turnBase = 0;

  /// A tag being dragged from the tray (its ghost follows the finger).
  _Tag? _dragTag;
  Offset _dragAt = Offset.zero;

  /// A tag's preview is open (two-step pick); tags set aside.
  _Tag? _preview;
  final Set<_Tag> _aside = {};

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _earKey = GlobalKey();
  final Map<_Tag, GlobalKey> _tagKeys = {};
  int _hintN = 0;
  M6CoilGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M6CoilRun(m6CoilDeal(widget.rng));
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _line.dispose();
    _angle.dispose();
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
      !_run.roundDone &&
      !_freeze &&
      !_harm &&
      _preview == null;

  String get _task {
    if (_run.inField) return _run.linked == null ? M6CoilLines.askField : M6CoilLines.askAct;
    if (!_run.found) return M6CoilLines.askShop;
    return _run.familyDone ? M6CoilLines.askCause : M6CoilLines.askFamily;
  }

  /// The waiting state (the gesture hand's key): 1 X-ray (the ear's ring
  /// shares it on every case alike), 0 listen (a sound sign not heard after
  /// the X-ray), 2 link, 3 action; 4 find, 5 family, 6 cause.
  int get _stage {
    if (_run.inField) {
      if (!_run.xray) return 1;
      if (!_run.pinReady) return 0;
      return _run.linked == null ? 2 : 3;
    }
    if (!_run.found) return 4;
    return _run.familyDone ? 6 : 5;
  }

  /// The tags on the tray now (none when no rail is up).
  List<_Tag> get _tags {
    if (_run.ended || _run.roundDone) return const [];
    if (_run.inField) {
      return _run.actionUp ? [for (final a in _run.field.acts) _Tag(_TagKind.act, a.index)] : const [];
    }
    final s = _run.shop;
    return _run.familyDone ? [for (final c in s.causes) _Tag(_TagKind.cause, c.index)] : [for (final f in s.families) _Tag(_TagKind.family, f.index)];
  }

  GlobalKey _keyOf(_Tag t) => _tagKeys.putIfAbsent(t, GlobalKey.new);

  Future<void> _start() async {
    _clock.start();
    _startCase();
  }

  void _startCase() {
    _line.value = null;
    if (!_run.inField) _angle.value = _run.shop.startFace * math.pi / 2;
    setState(() {
      _aside.clear();
      _preview = null;
      _dragTag = null;
    });
    unawaited(_sayChain([_task]));
  }

  // --- the field -----------------------------------------------------------------
  void _holdEar() {
    if (!_canPlay || !_run.inField) return;
    HapticFeedback.mediumImpact();
    final clip = m6EarClip(_run.field);
    if (clip != null) _cue(clip, volume: 0.9);
    _run.listen();
    setState(() {});
  }

  /// The scene's touch layer (design px).
  void _panStart(Offset p) {
    final geo = _geoNow;
    if (!_canPlay || geo == null) return;
    if (_run.inField) {
      if (!_run.xray && geo.tank.contains(p)) {
        _swipeFrom = p;
        _swipeNow = p;
        return;
      }
      if (_run.xray && _run.linked == null && _run.pinReady && geo.pinHit(_run.field.sign).contains(p)) {
        _pinDrag = true;
        _line.value = (geo.pin(_run.field.sign), p);
        return;
      }
      return;
    }
    if (geo.coil.inflate(14).contains(p)) {
      _turnFrom = p.dx;
      _turnBase = _angle.value;
    }
  }

  void _panUpdate(Offset p) {
    final geo = _geoNow;
    if (geo == null) return;
    if (_swipeFrom != null) {
      _swipeNow = p;
    } else if (_pinDrag) {
      _line.value = (geo.pin(_run.field.sign), p);
    } else if (_turnFrom != null) {
      // Drag right: the faces move to the right (the coil turns with the finger).
      _angle.value = _turnBase - (p.dx - _turnFrom!) / 80 * (math.pi / 2);
    }
  }

  void _panEnd() {
    final geo = _geoNow;
    if (geo == null) return;
    if (_swipeFrom != null) {
      final from = _swipeFrom!;
      _swipeFrom = null;
      if (!_canPlay) return;
      if ((_swipeNow.dx - from.dx).abs() >= 60) {
        _tick('sounds/intro/glass.ogg', 0.5);
        _run.openXray();
        setState(() {});
      } else {
        _hints.missTap();
      }
      return;
    }
    if (_pinDrag) {
      _pinDrag = false;
      final end = _line.value?.$2;
      _line.value = null;
      if (end == null || !_canPlay) return;
      for (final part in M6Part.values) {
        if (geo.zone(part).contains(end)) {
          _link(part, geo);
          return;
        }
      }
      _hints.missTap();
      return;
    }
    if (_turnFrom != null) {
      _turnFrom = null;
      final q = (_angle.value / (math.pi / 2)).round();
      _angle.value = q * math.pi / 2;
      final face = ((q % m6Faces) + m6Faces) % m6Faces;
      if (face != _run.facing) _tick('sounds/intro/click.ogg', 0.4);
      _run.turnTo(face);
      setState(() {});
    }
  }

  void _tapScene(Offset p, Offset global) {
    final geo = _geoNow;
    if (!_canPlay || geo == null) return;
    if (!_run.inField && geo.coil.contains(p)) {
      if (_run.found) {
        _hints.missTap();
        return;
      }
      final m = _run.tapCoil();
      if (m != null) {
        setState(() {});
        unawaited(_mistake(m, global));
        return;
      }
      if (!_run.found) return;
      HapticFeedback.lightImpact();
      _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
      unawaited(_levelDelta(5, global, mood: GuideMood.glad));
      setState(() {});
      unawaited(_sayChain([M6CoilLines.askFamily], mood: GuideMood.think));
      return;
    }
    _hints.missTap();
  }

  void _link(M6Part part, M6CoilGeo geo) {
    final m = _run.link(part);
    final origin = _toGlobal(geo.zone(part).center);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, origin));
      return;
    }
    if (_run.linked == null) return;
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
    _line.value = (geo.pin(_run.field.sign), geo.zone(part).center);
    if (_run.roundDone) {
      // The hum on "normal": the case is answered.
      setState(() {});
      unawaited(_caseDone());
      return;
    }
    unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
    if (_run.coworkerGate && !coworkerDone && !coworkerDue) scheduleCoworker();
    setState(() {});
    unawaited(_sayChain([M6CoilLines.askAct]));
  }

  Offset _toGlobal(Offset scene) {
    final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return scene;
    return box.localToGlobal(scene);
  }

  Offset? _toScene(Offset global) {
    final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  // --- the tags --------------------------------------------------------------------
  void _tapTag(_Tag t) {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _preview = t);
  }

  void _confirmPreview() {
    final t = _preview;
    if (t == null) return;
    setState(() => _preview = null);
    final size = MediaQuery.sizeOf(context);
    _commit(t, Offset(size.width / 2, size.height * 0.45));
  }

  void _rejectPreview() {
    final t = _preview;
    if (t == null) return;
    setState(() {
      _aside.add(t);
      _preview = null;
    });
  }

  void _tagDragStart(_Tag t, Offset global) {
    if (!_canPlay) return;
    setState(() {
      _dragTag = t;
      _dragAt = global;
    });
  }

  void _tagDragUpdate(Offset global) {
    if (_dragTag == null) return;
    setState(() => _dragAt = global);
  }

  void _tagDragEnd() {
    final t = _dragTag;
    final geo = _geoNow;
    setState(() => _dragTag = null);
    if (t == null || geo == null || !_canPlay) return;
    final at = _toScene(_dragAt);
    final target = _run.inField ? geo.tank.inflate(18) : geo.coil.inflate(18);
    if (at != null && target.contains(at)) {
      _commit(t, _dragAt);
    } else {
      _hints.missTap();
    }
  }

  void _commit(_Tag t, Offset global) {
    switch (t.kind) {
      case _TagKind.act:
        unawaited(_commitAct(M6Act.values[t.value], global));
      case _TagKind.family:
        _commitFamily(M6Family.values[t.value], global);
      case _TagKind.cause:
        _commitCause(M6Cause.values[t.value], global);
    }
  }

  /// The decisive control of his case: it waits for him.
  Future<void> _commitAct(M6Act a, Offset global) async {
    if (!_canPlay) return;
    if (holdForCoworker()) return;
    final m = _run.act(a);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.acted) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    _hush();
    setState(() {
      _harm = true;
      _aside.clear();
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 1100));
    if (!mounted || _ended) return;
    setState(() => _harm = false);
    unawaited(_caseDone());
  }

  void _commitFamily(M6Family f, Offset global) {
    if (!_canPlay) return;
    final m = _run.family(f);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.familyDone) return;
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.55);
    unawaited(_levelDelta(5, global, mood: GuideMood.glad));
    setState(_aside.clear);
    unawaited(_sayChain([M6CoilLines.askCause], mood: GuideMood.think));
  }

  void _commitCause(M6Cause c, Offset global) {
    if (!_canPlay) return;
    final m = _run.cause(c);
    if (m != null) {
      setState(() {});
      unawaited(_mistake(m, global));
      return;
    }
    if (!_run.roundDone) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(_aside.clear);
    unawaited(_caseDone());
  }

  Future<void> _caseDone() async {
    _hush();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.deal.why[_run.index];
    final idx = _run.index;
    final sign = _run.inField ? _run.field.sign : null;
    final family = _run.inField ? null : _run.shop.family;
    unawaited(askReason(
      deal: () => dealChoices(M6CoilLines.whyRight(topic, sign: sign, family: family), M6CoilLines.myths, widget.rng),
      question: M6CoilLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCase();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1000), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6CoilLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.coworkerGate) return null;
    if (_intro || _card != null || tableBusy || _freeze || _harm || _preview != null || _dragTag != null) return false;
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
      final m = M6CoilMistakes.push(p);
      if (m.deadly) {
        final geo = _geoNow;
        if (geo != null) _flashAt = geo.tank.center;
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6CoilLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6CoilLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6CoilLines.tapWhy[_nudgeN++ % M6CoilLines.tapWhy.length]
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
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6coil/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The burnt DTR charged again: the scene freezes grey and it bursts in
  /// colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    _line.value = null;
    setState(() {
      _freeze = true;
      _preview = null;
      _dragTag = null;
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
    final speak = await SpokenOnce.first('m6coil/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6CoilLines.deadlyWord : M6CoilLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same case goes on from where it was.
        _hush();
        setState(() => _card = null);
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
    final ms = _clock.elapsedMilliseconds;
    final quick = ms < widget.pack.quickMs;
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
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: quick);
    if (_run.passed) {
      await save.recordBestTime(_rungId, ms);
      // Right after the best time: without it the rung never counts in the league.
      await save.recordStars(_rungId, stars);
    }
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M6CoilLines.fail : (_quickBonus ? M6CoilLines.quick : M6CoilLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the gesture hand ---------------------------------------------------------------
  /// How to touch, never what: before the X-ray, on every field case alike,
  /// the ear's hold ring (not heard yet) in turn with a swipe across the
  /// tank; the ear's ring after the X-ray only while a sound sign is not
  /// heard; a short drag up from the sign (fixed direction, never toward a
  /// part); a sweep over every tag alike; in the shop a turn both ways on
  /// the coil, and once it has been turned, a sweep over the family rail in
  /// turn (keyed on the turns made, never on where the damage is).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    switch (_stage) {
      case 0:
        return HintSpec.holdOn(_earKey);
      case 1:
        if (!_run.listened && n.isEven) return HintSpec.holdOn(_earKey);
        return HintSpec.swipe(Offset(geo.tank.left + 20, geo.tank.center.dy), toward: const Offset(1, 0), travel: geo.tank.width - 50, space: HintSpace.scene);
      case 2:
        return HintSpec.drag(geo.pin(_run.field.sign), toward: const Offset(0, -1), travel: 64, space: HintSpace.scene);
      case 4:
        final tags = _tags;
        if (_run.seen.length > 1 && n % 3 == 2 && tags.length > 1) return HintSpec.sweepOver([for (final t in tags) _keyOf(t)]);
        final c = geo.coil.center;
        return n.isEven
            ? HintSpec.swipe(c.translate(-40, 0), toward: const Offset(1, 0), travel: 80, space: HintSpace.scene)
            : HintSpec.swipe(c.translate(40, 0), toward: const Offset(-1, 0), travel: 80, space: HintSpace.scene);
      default:
        final tags = _tags;
        if (tags.length < 2) return null;
        return HintSpec.sweepOver([for (final t in tags) _keyOf(t)]);
    }
  }

  // --- the scene ---------------------------------------------------------------
  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6CoilGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final field = _run.inField && !_run.done;
    final f = _run.field;
    final s = _run.shop;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(
            child: field
                ? CustomPaint(
                    key: ValueKey('field-${_run.index}'),
                    painter: M6FieldPainter(
                      geo: geo,
                      rig: M6FieldRig(sign: f.sign, source: f.source, gel: f.gel, light: f.light, listened: _run.listened, xray: _run.xray),
                    ),
                  )
                : CustomPaint(
                    key: ValueKey('shop-${_run.index}'),
                    painter: M6ShopPainter(geo: geo, family: s.family, damageFace: s.damageFace, angle: _angle, light: s.light, found: _run.found),
                  ),
          ),
        ),
      ),
      // The X-ray zones' labels (every part alike).
      if (field && _run.xray && !_freeze)
        for (final p in M6Part.values)
          Positioned.fromRect(
            key: ValueKey('zone-${p.name}'),
            rect: geo.zone(p),
            child: IgnorePointer(child: _ZoneLabel(text: M6CoilLines.part(p), outside: p == M6Part.normal)),
          ),
      if (field)
        Positioned.fill(
          key: ValueKey('link-${_run.index}'),
          child: IgnorePointer(
            child: RepaintBoundary(
              child: _harm && !quiet
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1000),
                      builder: (_, v, _) => CustomPaint(painter: M6LinkPainter(line: _line, glow: v)),
                    )
                  : CustomPaint(painter: M6LinkPainter(line: _line)),
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: field ? M6CoilLines.sceneField : M6CoilLines.sceneShop,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // From the finger-down point: the drag starts on the sign itself.
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(),
          ),
        ),
      ),
      // The ear: not needed once the sign is linked (the tag tray rises there).
      if (field && !_freeze && _run.linked == null)
        Positioned.fromRect(
          key: const ValueKey('ear'),
          rect: geo.ear,
          child: _EarButton(key: _earKey, heard: _run.listened, onHold: _holdEar, onTap: _hints.missTap),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6FlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // The next case: a short fade.
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null && !_harm;
    final tags = handsOn ? _tags : const <_Tag>[];
    final trayRows = (tags.length / 2).ceil();
    final trayH = trayRows == 0 ? 0.0 : trayRows * 46.0 + 8;
    final preview = _preview;
    final drag = _dragTag;
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
              labels: [for (var i = 0; i < M6CoilRun.cases; i++) M6CoilLines.round(i)],
              done: {for (var i = 0; i < math.min(_run.index, M6CoilRun.cases); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => [KeyedSubtree(key: _sceneKey, child: SizedBox(width: 360, height: m.height, child: Stack(children: _scene(m))))],
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && preview == null && drag == null,
            hintKey: _run.index * 10 + _stage,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (tags.isNotEmpty)
                Positioned(
                  key: ValueKey('tray-${_run.index}-$_stage'),
                  left: 6,
                  right: 6,
                  bottom: pad.bottom + 8,
                  height: trayH,
                  child: _TagTray(
                    tags: tags,
                    keyOf: _keyOf,
                    aside: _aside,
                    dragging: drag,
                    onTap: _tapTag,
                    onDragStart: _tagDragStart,
                    onDragUpdate: _tagDragUpdate,
                    onDragEnd: _tagDragEnd,
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (tags.isNotEmpty ? trayH + 14 : 12)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              // Over the corner guide: nothing may cover the card's ✓ / ✕.
              if (handsOn && preview != null)
                Positioned.fill(
                  key: ValueKey('tag-preview-${preview.id}'),
                  child: CardPreviewOverlay(
                    textBn: preview.text,
                    icon: _tagIcon(preview.kind),
                    quiet: quiet,
                    muted: _muted,
                    bottom: pad.bottom,
                    onConfirm: _confirmPreview,
                    onReject: _rejectPreview,
                  ),
                ),
              if (drag != null)
                Positioned(
                  key: const ValueKey('tag-ghost'),
                  left: _dragAt.dx - 80,
                  top: _dragAt.dy - 26,
                  width: 160,
                  child: IgnorePointer(child: Opacity(opacity: 0.9, child: _TagChip(text: drag.text, icon: _tagIcon(drag.kind), lifted: true))),
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
                  line: M6CoilLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 5, muted: _muted)),
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

  static IconData _tagIcon(_TagKind k) => switch (k) {
        _TagKind.act => Icons.assignment_rounded,
        _TagKind.family => Icons.search_rounded,
        _TagKind.cause => Icons.help_outline_rounded,
      };
}

// ============================================================================
// Pieces
// ============================================================================

/// An X-ray zone's label (every part the same chip).
class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel({required this.text, this.outside = false});
  final String text;
  final bool outside;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xCCFFF3C4), width: 1.2),
        color: outside ? const Color(0xCC1C2E4A) : const Color(0x22000000),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xD9101A2B), borderRadius: BorderRadius.circular(5)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
          ),
        ),
      ),
    );
  }
}

/// The ear: hold to listen (a plain tap does nothing; the hand shows the hold).
class _EarButton extends StatelessWidget {
  const _EarButton({super.key, required this.heard, required this.onHold, required this.onTap});
  final bool heard;
  final VoidCallback onHold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = heard ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: M6CoilLines.ear,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onHold,
        onTap: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                border: Border.all(color: ring, width: 1.8),
              ),
              child: Icon(Icons.hearing_rounded, size: 22, color: ring),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(6)),
              child: Text(M6CoilLines.ear, style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// The rail: every tag the same chip, two to a row. Tap → its preview (✓ to
/// commit); or drag it onto the DTR / the coil.
class _TagTray extends StatelessWidget {
  const _TagTray({
    required this.tags,
    required this.keyOf,
    required this.aside,
    required this.dragging,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final List<_Tag> tags;
  final GlobalKey Function(_Tag) keyOf;
  final Set<_Tag> aside;
  final _Tag? dragging;
  final ValueChanged<_Tag> onTap;
  final void Function(_Tag t, Offset global) onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 6) / 2;
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final t in tags)
              SizedBox(
                key: keyOf(t),
                width: w,
                height: 42,
                child: Semantics(
                  button: true,
                  label: t.text,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onTap: () => onTap(t),
                    onPanStart: (d) => onDragStart(t, d.globalPosition),
                    onPanUpdate: (d) => onDragUpdate(d.globalPosition),
                    onPanEnd: (_) => onDragEnd(),
                    child: CardAside(
                      aside: aside.contains(t),
                      child: Opacity(
                        opacity: dragging == t ? 0.35 : 1,
                        child: _TagChip(text: t.text, icon: _CoilRunPageState._tagIcon(t.kind)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.icon, this.lifted = false});
  final String text;
  final IconData icon;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.4),
        boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 12 : 5, offset: Offset(0, lifted ? 6 : 2))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SlmColors.gold300),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.2, color: SlmColors.ivory),
            ),
          ),
        ],
      ),
    );
  }
}
