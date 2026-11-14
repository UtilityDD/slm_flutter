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
import 'm4_insulator_prep_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_insulator_prep_world.dart' show M4InsulatorPrepFault, M4InsulatorPrepItem, M4InsulatorPrepKind;

// Lesson 4.1 "পিন বা ডিস্ক ইনসুলেটর বদলানো", কাজ 1 "বদলের আগে"
// (pack do_4_1_a, engineType m4_insulator_prep). Three poles a play, each
// with a damaged insulator on its docket. Before anyone climbs, the trainee
// gets everything ready.
//
// The lesson's rules, and only those:
//   • point 1 (প্রস্তুতি): a valid permit-to-work (PTW) first; the line fully
//     de-energised and earthed from both sides; the right new insulator, the
//     binding wire and the hardware at hand ("without the right kit, danger
//     halfway through the job");
//   • point 2: pin insulator — the conductor is held on a rope (support) while
//     the insulator is changed, then bound with new binding wire;
//   • point 3: disc (tension) string — the load is bypassed with a come-along
//     clamp and a turnbuckle (or ratchet puller) first;
//   • myth 1: a dead line can still carry induced voltage;
//   • advanced fact 1 (and the film): check for both electrical failure
//     (puncture / flashover) and mechanical failure (a crack).
// From the module's safety rules (the brief and lesson 1.6, NOT lesson 4.1's
// text — flagged in REGISTER.md): test the line dead before the earths go on,
// and helmet + harness before climbing.
//
// Hands on: tap the faulty insulator on the pole (spot); the van's shelf —
// the new insulator of the right kind (a cracked spare of each kind waits
// there: inspect), and its fittings (choose); PTW · টেস্টার · আর্থ (tap the
// line left and right of the pole) · হার্নেস; then tap the pole to climb
// (order).
//
// Deadly: climbing a line with no PTW / shutdown, or with the earth not on
// both sides (also by listening to the coworker, "এক দিকে আর্থ দিলেই হবে").
// Slips: a good insulator called faulty, the wrong kind of insulator, a
// fitting for the other kind, a cracked spare, an earth on a live / untested line, climbing without helmet
// + harness or without the full kit. Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_insulator_prep_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next pole by itself; the careless coworker once a play, on
// one pole, after the line is proven dead — the second earth and the climb
// wait for him (holdForCoworker), so a fast play cannot skip him; he never
// comes once both earths are on. Voice: the guide by device TTS; the
// coworker's push stays silent with its caption held until it is recorded
// (his exit line is his existing recorded clip).
//
// No giveaways: the tool row is dealt in a fresh order each pole (never
// PTW → tester → earth → harness), the kit button lights for "something
// packed", not for "the right kit", and a good insulator called faulty costs
// a slip with a neutral reply. Gesture hints (how, never what) for each
// waiting state: a sweep over the insulators, over the tools and the pole,
// over the shelf, or over the line and the pole while the earth is in hand.

// ============================================================================
// Content
// ============================================================================

/// What the reason question asks about.
enum M4InsulatorPrepWhy { earth, ptw, kit, spare }

/// The hands-on tool in hand.
enum M4InsulatorPrepTool { none, earth }

/// The buttons on the tool row (dealt in a fresh order each pole).
enum M4InsulatorPrepButton { kit, ptw, tester, earth, harness }

/// True when [row] shows the safe order PTW → tester → earth → harness left
/// to right (the kit anywhere): a row like that would give the order away.
bool m4InsulatorPrepRowInOrder(List<M4InsulatorPrepButton> row) {
  const order = [M4InsulatorPrepButton.ptw, M4InsulatorPrepButton.tester, M4InsulatorPrepButton.earth, M4InsulatorPrepButton.harness];
  final seen = [for (final b in row) if (b != M4InsulatorPrepButton.kit) b];
  for (var i = 0; i < order.length; i++) {
    if (seen[i] != order[i]) return false;
  }
  return true;
}

@immutable
class M4InsulatorPrepSite {
  const M4InsulatorPrepSite({
    required this.id,
    required this.kind,
    required this.fault,
    required this.faulty,
    required this.why,
    required this.shelf,
    required this.poleNo,
    this.tools = const [
      M4InsulatorPrepButton.harness,
      M4InsulatorPrepButton.earth,
      M4InsulatorPrepButton.kit,
      M4InsulatorPrepButton.ptw,
      M4InsulatorPrepButton.tester,
    ],
  });

  /// The tool row, left to right (never the safe order: [m4InsulatorPrepRowInOrder]).
  final List<M4InsulatorPrepButton> tools;
  final String id;
  final M4InsulatorPrepKind kind;
  final M4InsulatorPrepFault fault;

  /// The faulty insulator: pin 0–2, or disc string 0–5.
  final int faulty;
  final M4InsulatorPrepWhy why;

  /// The van's shelf, in this site's order.
  final List<M4InsulatorPrepItem> shelf;
  final int poleNo;

  M4InsulatorPrepItem get rightSpare => kind == M4InsulatorPrepKind.pin ? M4InsulatorPrepItem.pinNew : M4InsulatorPrepItem.discNew;

  /// The fittings the job needs (lesson 4.1 points 2 and 3).
  List<M4InsulatorPrepItem> get fittings => kind == M4InsulatorPrepKind.pin
      ? const [M4InsulatorPrepItem.binding, M4InsulatorPrepItem.rope]
      : const [M4InsulatorPrepItem.comeAlong, M4InsulatorPrepItem.turnbuckle];
}

abstract final class M4InsulatorPrepLines {
  static const title = 'বদলের আগে';
  static const intro = 'ভাঙা ইনসুলেটর মানেই ফল্ট! বদলের আগে সব প্রস্তুত — তবেই পোলে।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askSpot = 'কোন ইনসুলেটরটা খারাপ?';
  static const askPrep = 'ওঠার আগে সব প্রস্তুত করুন।';
  static const tasks = [askSpot, askPrep];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the shelf, the docket).
  static const sceneLabel = 'লাইনের পোল';
  static const kit = 'সরঞ্জাম';
  static const ptw = 'PTW';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ';
  static const harness = 'হার্নেস';
  static const shelfTitle = 'ভ্যানের তাক';
  static const shelfDone = 'ঠিক আছে';
  static const docket = 'ডকেট';
  static const docketJob = 'ইনসুলেটর খারাপ — বদলাতে হবে';
  static String poleBn(int n) => 'পোল নং $n';
  static const ptwStamp = 'পারমিট (PTW) · শাটডাউন';
  static const testerLive = 'লাইভ';
  static const testerDead = 'মৃত';
  static const stampUp = 'প্রস্তুত';
  static String itemBn(M4InsulatorPrepItem i) => switch (i) {
        M4InsulatorPrepItem.pinNew || M4InsulatorPrepItem.pinBad => 'পিন ইনসুলেটর',
        M4InsulatorPrepItem.discNew || M4InsulatorPrepItem.discBad => 'ডিস্ক ইনসুলেটর',
        M4InsulatorPrepItem.binding => 'বাইন্ডিং তার',
        M4InsulatorPrepItem.rope => 'দড়ি',
        M4InsulatorPrepItem.comeAlong => 'কাম-অ্যালং',
        M4InsulatorPrepItem.turnbuckle => 'টার্ন-বাকেল',
      };

  // The reasons (lesson 4.1 and its film): the right ones fit what was done;
  // the wrong ones are myths and field excuses — never a true rule marked
  // wrong. Every card 35–44 letters.
  static const whyEarthQ = 'কেন দুই দিকে আর্থ দিয়ে তবে উঠলেন?';
  static const whyPtwQ = 'কেন সবার আগে পারমিট (PTW) নিলেন?';
  static const whyKitQ = 'কেন ওঠার আগে সব সরঞ্জাম মিলিয়ে নিলেন?';
  static const whySpareQ = 'কেন নতুন ইনসুলেটরটাও দেখে নিলেন?';
  static const earthWhy = ['বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ — দুই দিকে আর্থ', 'কাজের জায়গার দুই দিকেই আর্থ — তবেই পোলে ওঠা'];
  static const ptwWhy = ['বৈধ পারমিট (PTW) আর শাটডাউন ছাড়া লাইনে হাত নয়', 'কাজের প্রথম শর্ত বৈধ পারমিট (PTW), তারপর বাকি সব'];
  static const kitWhy = ['সরঞ্জাম না থাকলে কাজের মাঝপথে বিপদ হতে পারে', 'ইনসুলেটর, বাইন্ডিং, সাপোর্ট — সব নিচেই মেলাই'];
  static const spareWhy = ['ফাটা নতুনটা লাগালে লাইনে আবার ফল্ট হবে', 'নতুনটাতেও ফাটল বা পোড়া দাগ থাকতে পারে'];
  static const _mythNoEarth = 'লাইন বন্ধ থাকলে আর্থের কোনো দরকারই নেই';
  static const _mythOneEarth = 'এক দিকে আর্থ দিলেই পুরো লাইন নিরাপদ হয়';
  static const _mythTwoLong = 'দুই দিকে আর্থ শুধু লম্বা লাইনের কাজে লাগে';
  static const _mythOldHand = 'অভিজ্ঞ লোকের পারমিট (PTW) ছাড়াও কাজ চলে যায়';
  static const _mythVerbal = 'মুখে বলে দিলেই চলে, পারমিট (PTW) কাগজ পরে নিলেই হবে';
  static const _mythWhatever = 'যা আছে নিয়ে উঠি, বাকিটা পরে দেখা যাবে';
  static const _mythAskUp = 'সরঞ্জাম কম পড়লে পোলে উঠে চেয়ে নেওয়া যায়';
  static const _mythNotAll = 'সব সরঞ্জাম লাগে না, যা আছে তা নিয়েই উঠি';
  static const _mythSmallCrack = 'অল্প ফাটা ইনসুলেটর আরও কিছুদিন চলে যায়';
  static const _mythBoxed = 'নতুন ইনসুলেটর বাক্স থেকে এলে দেখার কিছু নেই';
  static const myths = [
    _mythNoEarth,
    _mythOneEarth,
    _mythTwoLong,
    _mythOldHand,
    _mythVerbal,
    _mythWhatever,
    _mythAskUp,
    _mythNotAll,
    _mythSmallCrack,
    _mythBoxed,
    'কাজ ছোট, তাই তাড়াতাড়ি সেরে ফেললাম',
    'পিন আর ডিস্ক — যেকোনোটা লাগালেই চলে',
  ];
  static const allRight = [...earthWhy, ...ptwWhy, ...kitWhy, ...spareWhy];

  /// The myths on the same topic as a reason (they share its key words).
  static List<String> nearMyths(M4InsulatorPrepWhy w) => switch (w) {
        M4InsulatorPrepWhy.earth => const [_mythTwoLong, _mythOneEarth, _mythNoEarth],
        M4InsulatorPrepWhy.ptw => const [_mythOldHand, _mythVerbal],
        M4InsulatorPrepWhy.kit => const [_mythAskUp, _mythNotAll],
        M4InsulatorPrepWhy.spare => const [_mythSmallCrack, _mythBoxed],
      };

  /// The words of a card or question (punctuation dropped).
  static Set<String> cardWords(String s) => {
        for (final w in s.split(RegExp(r'[\s,?!।—–]+')))
          if (w.isNotEmpty) w,
      };

  /// The reason deck: one right card, one myth on the same topic, one other —
  /// dealt so that every word of the question the right card repeats is on a
  /// wrong card too (no word shows only on the right card).
  static List<ChoiceOption> dealWhy(M4InsulatorPrepSite s, math.Random rng) {
    final right = whyRight(s);
    final r = right[rng.nextInt(right.length)];
    final echo = cardWords(whyQuestion(s)).intersection(cardWords(r));
    final near = nearMyths(s.why);
    bool covers(String a, String b) {
      final w = {...cardWords(a), ...cardWords(b)};
      return echo.every(w.contains);
    }

    final hands = <(String, String)>[
      for (final a in near)
        for (final b in myths)
          if (a != b && covers(a, b)) (a, b),
    ];
    final (a, b) = hands.isEmpty ? (near[0], near[1]) : hands[rng.nextInt(hands.length)];
    return [ChoiceOption(r, true), ChoiceOption(a, false), ChoiceOption(b, false)]..shuffle(rng);
  }

  static List<String> whyRight(M4InsulatorPrepSite s) => switch (s.why) {
        M4InsulatorPrepWhy.earth => earthWhy,
        M4InsulatorPrepWhy.ptw => ptwWhy,
        M4InsulatorPrepWhy.kit => kitWhy,
        M4InsulatorPrepWhy.spare => spareWhy,
      };
  static String whyQuestion(M4InsulatorPrepSite s) => switch (s.why) {
        M4InsulatorPrepWhy.earth => whyEarthQ,
        M4InsulatorPrepWhy.ptw => whyPtwQ,
        M4InsulatorPrepWhy.kit => whyKitQ,
        M4InsulatorPrepWhy.spare => whySpareQ,
      };

  /// The careless coworker: one earth is enough.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'লাইন তো বন্ধ! এক দিকে আর্থ দিলেই হবে, তাড়াতাড়ি উঠে পড়ো।',
    exitLine: coworkerExit,
    right: ['না, দুই দিকে আর্থ দিয়ে তবে উঠব', 'না, অন্য দিকেও আর্থ চাই, তারপর ওঠা', 'না, এক দিকের আর্থে পোলে উঠব না'],
    wrong: [
      'ঠিক, এক দিকের আর্থেই উঠে পড়ি',
      'আচ্ছা, লাইন তো বন্ধ, এখনই উঠি',
      'হ্যাঁ, অন্য দিকটা পরে দেখা যাবে',
      'ঠিক আছে, এক দিকেই যথেষ্ট আর্থ',
      'তাড়া আছে, এক আর্থেই কাজ সারি',
    ],
    asks: ['ও বলছে এক দিকের আর্থেই উঠতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'এক দিকের আর্থে পোলে উঠবেন?'],
  );

  static const callHeld = 'ঠিক! দুই দিকে আর্থ, তবেই পোলে।';
  static const allSet = 'তিন পোলেই সব প্রস্তুত — পারমিট (PTW), মৃত প্রমাণ, দুই দিকে আর্থ, ঠিক সরঞ্জাম।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে পারমিট (PTW), মৃত প্রমাণ, দুই দিকে আর্থ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtSpot = 'খারাপ ইনসুলেটর চিনেছেন';
  static const caughtSpare = 'ঠিক ধরনের ভালো নতুন ইনসুলেটর';
  static const caughtFittings = 'বাইন্ডিং, সাপোর্ট, কাম-অ্যালং — যা লাগে';
  static const caughtPtw = 'সবার আগে পারমিট (PTW) আর শাটডাউন';
  static const caughtDead = 'টেস্টারে মৃত প্রমাণ';
  static const caughtEarth = 'দুই দিকে আর্থ';
  static const caughtHarness = 'হেলমেট-হার্নেস পরে তবে ওঠা';
  static const caughtCall = 'এক দিকের আর্থে “না” বলেছেন';
}

abstract final class M4InsulatorPrepMistakes {
  static const _dir = 'assets/game/art/m4_insulator_prep';
  static const _live = '$_dir/climb_live.svg';
  static const _earth = '$_dir/earth_both.svg';
  static const _spot = '$_dir/spot_fault.svg';
  static const _spare = '$_dir/spare_check.svg';
  static const _kit = '$_dir/kit_ready.svg';
  static const _ppe = '$_dir/harness_on.svg';

  /// The key prefix (the Module 4 pattern `<lesson>/m4_<level>/…`).
  static const prefix = '4.1/m4_insulator_prep/';

  /// Keys saved before 2026-11-11 (`4.1/insulator_prep/…`).
  static const legacyPrefix = '4.1/insulator_prep/';

  static const climbLive = DoMistake(
    key: '${prefix}climb-live',
    textBn: 'লাইন চালু! বৈধ পারমিট (PTW) আর শাটডাউন ছাড়া পোলে ওঠা নয় — তারপর মৃত প্রমাণ, দুই দিকে আর্থ।',
    art: _live,
    deadly: true,
    lessonPoint: 0,
  );
  static const earthBoth = DoMistake(
    key: '${prefix}earth-both-sides',
    textBn: 'দুই দিকে আর্থ ছাড়া পোলে ওঠা নয়! বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ থাকতে পারে — কাজের জায়গার দুই দিকেই আর্থ।',
    art: _earth,
    deadly: true,
    lessonPoint: 0,
  );
  // Earthing a line that is still on / not yet proven dead: the module's
  // rule (lesson 1.6), not lesson 4.1's text.
  static const earthLive = DoMistake(
    key: '${prefix}earth-live',
    textBn: 'লাইন এখনো চালু! আগে পারমিট (PTW) নিয়ে শাটডাউন, টেস্টারে মৃত প্রমাণ — তবে আর্থ।',
    art: _earth,
    lessonPoint: 0,
  );
  static const earthUntested = DoMistake(
    key: '${prefix}earth-untested',
    textBn: 'আর্থ লাগানোর আগে টেস্টারে দেখে নিন লাইন সত্যিই মৃত।',
    art: _earth,
  );
  static const noHarness = DoMistake(
    key: '${prefix}no-harness',
    textBn: 'পোলে ওঠার আগে হেলমেট আর হার্নেস পরে নিন, হার্নেস ঠিক আছে কি না দেখে নিন।',
    art: _ppe,
  );
  static const noKit = DoMistake(
    key: '${prefix}kit-not-ready',
    textBn: 'সঠিক নতুন ইনসুলেটর, বাইন্ডিং তার বা সাপোর্ট, কাম-অ্যালং — যা লাগে সব নিচেই মেলান। নইলে কাজের মাঝপথে বিপদ।',
    art: _kit,
    lessonPoint: 0,
  );
  static const wrongKind = DoMistake(
    key: '${prefix}wrong-kind',
    textBn: 'এটা অন্য ধরনের ইনসুলেটর। পোলে যেটা ভেঙেছে, ঠিক সেই ধরনের আর সাইজের নতুনটা নিন।',
    art: _kit,
    lessonPoint: 0,
  );
  // Packing a fitting for the other kind of insulator (a rope on a disc job,
  // a come-along on a pin job): the over-call of the shelf (audit item 5).
  static const wrongFitting = DoMistake(
    key: '${prefix}wrong-fitting',
    textBn: 'এটা অন্য ধরনের ইনসুলেটরের কাজের জিনিস। পোলে যেটা ভেঙেছে, সেই কাজের সরঞ্জামই মেলান।',
    art: _kit,
    lessonPoint: 0,
  );
  static const crackedSpare = DoMistake(
    key: '${prefix}cracked-spare',
    textBn: 'নতুনটাও দেখে নিন! ফাটা বা চলটা ওঠা ইনসুলেটর লাগালে লাইনে আবার ফল্ট হবে।',
    art: _spare,
    lessonPoint: 0,
  );
  static const misSpot = DoMistake(
    key: '${prefix}good-one-called-bad',
    textBn: 'ভালো করে আবার দেখুন। ফাটল (মেকানিক্যাল) আর পোড়া দাগ বা পাংচার (ইলেকট্রিক্যাল) — দুটোই খুঁজুন।',
    art: _spot,
  );

  static const all = [climbLive, earthBoth, earthLive, earthUntested, noHarness, noKit, wrongKind, wrongFitting, crackedSpare, misSpot];

  /// The same cards under their old keys, so mistakes saved before the
  /// rename still show their picture in the mistakes book.
  static final List<DoMistake> legacy = [
    for (final m in all)
      DoMistake(key: legacyPrefix + m.key.substring(prefix.length), textBn: m.textBn, art: m.art, deadly: m.deadly, lessonPoint: m.lessonPoint),
  ];

  /// The current card for a saved key (old or new), or null.
  static DoMistake? byKey(String key) {
    final k = key.startsWith(legacyPrefix) ? prefix + key.substring(legacyPrefix.length) : key;
    for (final m in all) {
      if (m.key == k) return m;
    }
    return null;
  }
}

@immutable
class M4InsulatorPrepDeal {
  const M4InsulatorPrepDeal({required this.sites, required this.callAt});
  final List<M4InsulatorPrepSite> sites;

  /// The pole the careless coworker comes to.
  final int callAt;
}

/// Three poles: both kinds of insulator in every play (the third at random),
/// both kinds of damage, a different reason on each pole, the shelf shuffled.
M4InsulatorPrepDeal m4InsulatorPrepDeal(math.Random rng) {
  final kinds = [M4InsulatorPrepKind.pin, M4InsulatorPrepKind.disc, M4InsulatorPrepKind.values[rng.nextInt(2)]]..shuffle(rng);
  final faults = [M4InsulatorPrepFault.crack, M4InsulatorPrepFault.burn, M4InsulatorPrepFault.values[rng.nextInt(2)]]..shuffle(rng);
  final whys = [...M4InsulatorPrepWhy.values]..shuffle(rng);
  final firstPole = 10 + rng.nextInt(80);
  final sites = <M4InsulatorPrepSite>[
    for (final (i, k) in kinds.indexed)
      M4InsulatorPrepSite(
        id: 'p$i',
        kind: k,
        fault: faults[i],
        faulty: rng.nextInt(k == M4InsulatorPrepKind.pin ? 3 : 6),
        why: whys[i],
        shelf: [...M4InsulatorPrepItem.values]..shuffle(rng),
        poleNo: firstPole + i * (2 + rng.nextInt(3)),
        tools: m4InsulatorPrepDealRow(rng),
      ),
  ];
  return M4InsulatorPrepDeal(sites: sites, callAt: rng.nextInt(3));
}

/// A tool row in a random order that never shows the safe order.
List<M4InsulatorPrepButton> m4InsulatorPrepDealRow(math.Random rng) {
  final row = [...M4InsulatorPrepButton.values]..shuffle(rng);
  while (m4InsulatorPrepRowInOrder(row)) {
    row.shuffle(rng);
  }
  return List.unmodifiable(row);
}

/// The play state (pure logic).
class M4InsulatorPrepRun {
  M4InsulatorPrepRun(this.deal);
  final M4InsulatorPrepDeal deal;
  int index = 0;
  int slips = 0;
  int siteSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this pole ---
  var spotted = false;
  var ptw = false;
  var tested = false;
  final Set<int> earths = {};
  var harness = false;
  final Set<M4InsulatorPrepItem> bag = {};
  var climbed = false;
  M4InsulatorPrepTool tool = M4InsulatorPrepTool.none;

  bool get done => index >= deal.sites.length;
  bool get ended => done || deadly != null;
  M4InsulatorPrepSite get site => deal.sites[index.clamp(0, deal.sites.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Done this pole without a slip (+5 on the table).
  bool get thorough => siteSlips == 0;

  /// The new insulator of the right kind and all its fittings are in the bag.
  bool get kitReady => bag.contains(site.rightSpare) && site.fittings.every(bag.contains);

  bool get _open => !ended && !climbed;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  /// Taps insulator [i] on the pole (pin 0–2 / disc string 0–5).
  DoMistake? tapInsulator(int i) {
    if (!_open || spotted) return null;
    if (i != site.faulty) return _slip(M4InsulatorPrepMistakes.misSpot);
    spotted = true;
    _tag(M4InsulatorPrepLines.caughtSpot);
    return null;
  }

  /// Takes [it] off the van's shelf into the bag (or puts it back).
  DoMistake? pick(M4InsulatorPrepItem it) {
    if (!_open || !spotted) return null;
    if (bag.contains(it)) {
      bag.remove(it);
      return null;
    }
    switch (it) {
      case M4InsulatorPrepItem.pinNew:
      case M4InsulatorPrepItem.pinBad:
      case M4InsulatorPrepItem.discNew:
      case M4InsulatorPrepItem.discBad:
        final pin = it == M4InsulatorPrepItem.pinNew || it == M4InsulatorPrepItem.pinBad;
        if (pin != (site.kind == M4InsulatorPrepKind.pin)) return _slip(M4InsulatorPrepMistakes.wrongKind);
        if (it == M4InsulatorPrepItem.pinBad || it == M4InsulatorPrepItem.discBad) return _slip(M4InsulatorPrepMistakes.crackedSpare);
        bag.add(it);
        _tag(M4InsulatorPrepLines.caughtSpare);
      default:
        if (!site.fittings.contains(it)) return _slip(M4InsulatorPrepMistakes.wrongFitting);
        bag.add(it);
    }
    if (kitReady) _tag(M4InsulatorPrepLines.caughtFittings);
    return null;
  }

  /// The permit-to-work: the line is shut down.
  void takePtw() {
    if (!_open || !spotted || ptw) return;
    ptw = true;
    _tag(M4InsulatorPrepLines.caughtPtw);
  }

  /// The tester on the line: true = live.
  bool test() {
    if (_open && spotted && ptw) {
      tested = true;
      _tag(M4InsulatorPrepLines.caughtDead);
    }
    return !ptw;
  }

  /// Picks up the earthing set (or puts it down).
  void holdEarth() {
    if (!_open || !spotted) return;
    tool = tool == M4InsulatorPrepTool.earth ? M4InsulatorPrepTool.none : M4InsulatorPrepTool.earth;
  }

  /// The earthing set on the line, [side] 0 left / 1 right of the pole.
  DoMistake? tapEarth(int side) {
    if (!_open || tool != M4InsulatorPrepTool.earth || earths.contains(side)) return null;
    if (!ptw) return _slip(M4InsulatorPrepMistakes.earthLive);
    if (!tested) return _slip(M4InsulatorPrepMistakes.earthUntested);
    earths.add(side);
    if (earths.length == 2) {
      tool = M4InsulatorPrepTool.none;
      _tag(M4InsulatorPrepLines.caughtEarth);
    }
    return null;
  }

  /// Helmet and harness on, the harness checked.
  void putHarness() {
    if (_open && spotted) harness = true;
  }

  /// Tap the pole: climb. Null and [climbed] = up, ready to work.
  DoMistake? climb() {
    if (!_open || !spotted) return null;
    if (!ptw) return deadly = M4InsulatorPrepMistakes.climbLive;
    if (earths.length < 2) return deadly = M4InsulatorPrepMistakes.earthBoth;
    if (!harness) return _slip(M4InsulatorPrepMistakes.noHarness);
    if (!kitReady) return _slip(M4InsulatorPrepMistakes.noKit);
    climbed = true;
    tool = M4InsulatorPrepTool.none;
    _tag(M4InsulatorPrepLines.caughtHarness);
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    siteSlips = 0;
    spotted = false;
    ptw = false;
    tested = false;
    earths.clear();
    harness = false;
    bag.clear();
    climbed = false;
    tool = M4InsulatorPrepTool.none;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action: spot, the shelf (open, 3 picks, close) 7500,
/// PTW, tester ~2200, earth + 2 taps 4500, harness, climb ~2500, reason ~8200
/// ≈ 30900 × 3 + the coworker once ≈ 9600 ≈ 102300; 85 % ≈ 87000 → 90 s.
const m4InsulatorPrepQuickMs = 90000;

@immutable
class M4InsulatorPrepPack {
  const M4InsulatorPrepPack({required this.id, required this.titleBn, this.quickMs = m4InsulatorPrepQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4InsulatorPrepPack> m4InsulatorPrepPacks = {
  'do_4_1_a': M4InsulatorPrepPack(id: 'do_4_1_a', titleBn: M4InsulatorPrepLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4InsulatorPrepPage extends StatefulWidget {
  const M4InsulatorPrepPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4InsulatorPrepPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4InsulatorPrepPage> createState() => _M4InsulatorPrepPageState();
}

class _M4InsulatorPrepPageState extends State<M4InsulatorPrepPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PrepRunPage(
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

class _PrepRunPage extends ConsumerStatefulWidget {
  const _PrepRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4InsulatorPrepPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PrepRunPage> createState() => _PrepRunPageState();
}

class _PrepRunPageState extends ConsumerState<_PrepRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4InsulatorPrepRun _run = M4InsulatorPrepRun(m4InsulatorPrepDeal(widget.rng));
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
  var _coworkerArmed = false;
  var _shelfOpen = false;

  /// The tester's lamp, a moment after it touches the line.
  bool? _tester;
  Timer? _testerTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to play, never the answer).
  final _hints = IdleHintController();
  final _toolKeys = {for (final b in M4InsulatorPrepButton.values) b: GlobalKey()};
  final _shelfKeys = {for (final i in M4InsulatorPrepItem.values) i: GlobalKey()};
  final _shelfDoneKey = GlobalKey();
  final _poleKey = GlobalKey();
  final _earthKeys = [GlobalKey(), GlobalKey()];

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _testerTimer?.cancel();
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

  Future<void> _start() async {
    _clock.start();
    _startSite();
  }

  /// Hands-on controls answer now (never in the praise window: tableBusy).
  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.climbed && !_freeze;

  String get _task => _run.spotted ? M4InsulatorPrepLines.askPrep : M4InsulatorPrepLines.askSpot;

  void _startSite() {
    _testerTimer?.cancel();
    setState(() {
      _tester = null;
      _shelfOpen = false;
      _wake++;
    });
    unawaited(_sayChain([M4InsulatorPrepLines.askSpot]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _openShelf() {
    if (!_canPlay) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.5);
    setState(() {
      _shelfOpen = !_shelfOpen;
      _wake++;
    });
  }

  void _closeShelf() {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.4);
    setState(() {
      _shelfOpen = false;
      _wake++;
    });
  }

  void _pick(M4InsulatorPrepItem it, Offset origin) {
    if (!_canPlay) return;
    _tick('sounds/quiz_select.ogg');
    final m = _run.pick(it);
    setState(() => _wake++);
    if (m != null) unawaited(_mistake(m, origin));
  }

  void _takePtw() {
    if (!_canPlay || _run.ptw) return;
    _tick('sounds/learn/tag_slap.ogg', 0.5);
    setState(() {
      _run.takePtw();
      _wake++;
    });
  }

  void _useTester() {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final live = _run.test();
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
    if (!live) _armCoworker();
  }

  void _holdEarth() {
    if (!_canPlay) return;
    _tick('sounds/quiz_select.ogg');
    setState(() {
      _run.holdEarth();
      _wake++;
    });
  }

  void _putHarness() {
    if (!_canPlay || _run.harness) return;
    _tick('sounds/learn/tag_slap.ogg', 0.35);
    setState(() {
      _run.putHarness();
      _wake++;
    });
  }

  /// He comes on his pole once the line is proven dead (and not yet earthed both sides).
  void _armCoworker() {
    if (_coworkerArmed || _run.index != _run.deal.callAt || _run.earths.length >= 2) return;
    _coworkerArmed = true;
    scheduleCoworker();
  }

  void _placeEarth(int side, Offset global) {
    // The second earth would end his moment: on his pole he comes first.
    if (_run.earths.length == 1 && !_run.earths.contains(side) && _run.tested && holdForCoworker()) return;
    _tick('sounds/intro/impact_metal.ogg', 0.5);
    final m = _run.tapEarth(side);
    setState(() => _wake++);
    if (m != null) unawaited(_mistake(m, global));
  }

  void _tapScene(Offset p, M4InsulatorPrepGeo geo, Offset global) {
    if (_intro || _ended || _card != null || tableBusy || _freeze || _run.climbed || _shelfOpen) return;
    final s = _run.site;
    // While he talks, only the earth on the other side answers him (it refuses him).
    if (coworkerOpen) {
      if (coworkerChoiceUp && _run.tool == M4InsulatorPrepTool.earth) {
        for (var side = 0; side < 2; side++) {
          if (geo.earthHit(side).contains(p) && !_run.earths.contains(side) && _run.tested) {
            _placeEarth(side, global);
            if (_run.earths.length == 2) unawaited(answerCoworker(true, global, direct: true));
            return;
          }
        }
      }
      return;
    }
    if (!_run.spotted) {
      for (var i = 0; i < geo.spots(s.kind); i++) {
        if (geo.spotHit(s.kind, i).contains(p)) {
          _tick();
          final m = _run.tapInsulator(i);
          setState(() => _wake++);
          if (m != null) {
            unawaited(_mistake(m, global));
          } else {
            HapticFeedback.lightImpact();
            _cue('sounds/quiz_right.ogg', volume: 0.5);
            unawaited(_sayChain([M4InsulatorPrepLines.askPrep]));
          }
          return;
        }
      }
      _hints.missTap();
      return;
    }
    if (_run.tool == M4InsulatorPrepTool.earth) {
      for (var side = 0; side < 2; side++) {
        if (geo.earthHit(side).contains(p)) {
          _placeEarth(side, global);
          return;
        }
      }
    }
    if (!geo.poleHit.contains(p)) {
      _hints.missTap();
      return;
    }
    // The climb: on his pole he comes first.
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.climb();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
    } else if (_run.climbed) {
      unawaited(_siteDone());
    }
  }

  Future<void> _siteDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final s = _run.site;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => M4InsulatorPrepLines.dealWhy(s, widget.rng),
      question: M4InsulatorPrepLines.whyQuestion(s),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startSite();
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
  CoworkerScript get coworkerScript => M4InsulatorPrepLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("one earth is enough") makes sense only until both are on.
    if (_ended || _run.index != _run.deal.callAt || _run.climbed || _run.earths.length >= 2) return null;
    if (_intro || _card != null || tableBusy || _shelfOpen || _tester != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up the pole with the earth on one side only. Deadly
      // (not the playbook's usual slip) because the act he pushes is itself on
      // the Module 4 deadly list (MODULE4_LADDER.md row 2) — an owner question.
      _run.failDeadly(M4InsulatorPrepMistakes.earthBoth);
      await _deadly(M4InsulatorPrepMistakes.earthBoth);
      return;
    }
    _run.caught.add(M4InsulatorPrepLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4InsulatorPrepLines.callHeld, M4InsulatorPrepLines.askPrep], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4InsulatorPrepLines.tapWhy[_nudgeN++ % M4InsulatorPrepLines.tapWhy.length]
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

  /// "Heard this card's full text" stays under the pre-rename key, so the
  /// key rename does not replay cards a player already heard.
  static String _spokenKey(DoMistake m) =>
      'insulator_prep/${m.key.replaceFirst(M4InsulatorPrepMistakes.prefix, M4InsulatorPrepMistakes.legacyPrefix)}';

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
    final speak = await SpokenOnce.first(_spokenKey(m));
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up a line that is not dead and earthed both sides: the scene freezes
  /// grey and the flash comes off the work point in colour; then near-miss
  /// or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _testerTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _tester = null;
      _shelfOpen = false;
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
    final speak = await SpokenOnce.first(_spokenKey(m));
    if (!mounted) return;
    await _sayChain([death ? M4InsulatorPrepLines.deadlyWord : M4InsulatorPrepLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same pole goes on from where it was.
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
    await _say(!_run.passed ? M4InsulatorPrepLines.fail : (_quickBonus ? M4InsulatorPrepLines.quick : M4InsulatorPrepLines.allSet),
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
    if (_run.climbed) return LinemanMode.hold;
    if (_run.tool != M4InsulatorPrepTool.none || _tester != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M4InsulatorPrepView get _view {
    final s = _run.site;
    return M4InsulatorPrepView(
      kind: s.kind,
      fault: s.fault,
      faulty: s.faulty,
      spotted: _run.spotted,
      earths: {..._run.earths},
      bag: {..._run.bag},
      climbed: _run.climbed,
      poleNo: s.poleNo,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M4InsulatorPrepGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final view = _view;
    final s = _run.site;
    final up = _run.climbed || _run.deadly != null;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('line'),
                child: RepaintBoundary(child: CustomPaint(painter: M4InsulatorPrepPainter(geo: geo, view: view, seed: _run.index * 5 + 3))),
              ),
              Positioned.fill(
                key: const ValueKey('trainee'),
                child: TweenAnimationBuilder<Rect?>(
                  tween: RectTween(begin: geo.trainee, end: up ? geo.traineeUp : geo.trainee),
                  duration: Duration(milliseconds: quiet ? 1 : 1100),
                  curve: Curves.easeInOut,
                  builder: (_, r, child) => Stack(children: [Positioned.fromRect(rect: r ?? geo.trainee, child: child!)]),
                  child: RepaintBoundary(child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
                ),
              ),
            ],
          ),
        ),
      ),
      // The tester's lamp up on the line.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: 40,
          top: geo.crossY + 60,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      if (_run.climbed && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 24,
          width: 130,
          top: geo.crossY + 110,
          child: IgnorePointer(child: _StampPop(text: M4InsulatorPrepLines.stampUp, quiet: quiet)),
        ),
      // Invisible anchors for the gesture hint (the pole and both sides of
      // the line): no paint, no touch.
      Positioned.fill(
        key: const ValueKey('hint-anchors'),
        child: IgnorePointer(
          child: Stack(
            children: [
              Positioned.fromRect(rect: geo.poleHit, child: SizedBox(key: _poleKey)),
              for (var side = 0; side < 2; side++)
                Positioned.fromRect(
                  rect: Rect.fromCenter(center: Offset(M4InsulatorPrepGeo.earthX[side], geo.crossY), width: 52, height: 90),
                  child: SizedBox(key: _earthKeys[side]),
                ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4InsulatorPrepLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4InsulatorPrepFlashPainter(at: geo.spotCentre(s.kind, s.faulty), v: v)),
            ),
          ),
        ),
      // The next pole: a short fade from the last one.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  /// One button of the tool row. The kit lights once something is packed —
  /// never for "the right kit" (that would give the fittings away).
  Widget _toolButton(M4InsulatorPrepButton b) {
    final key = _toolKeys[b]!;
    return switch (b) {
      M4InsulatorPrepButton.kit => _ToolButton(anchor: key, icon: Icons.inventory_2_rounded, label: M4InsulatorPrepLines.kit, on: _run.bag.isNotEmpty, onTap: _openShelf),
      M4InsulatorPrepButton.ptw => _ToolButton(anchor: key, icon: Icons.assignment_turned_in_rounded, label: M4InsulatorPrepLines.ptw, on: _run.ptw, onTap: _takePtw),
      M4InsulatorPrepButton.tester => _ToolButton(anchor: key, icon: Icons.flash_on_rounded, label: M4InsulatorPrepLines.tester, on: _tester != null, onTap: _useTester),
      M4InsulatorPrepButton.earth => _ToolButton(
          anchor: key,
          icon: Icons.link_rounded,
          label: M4InsulatorPrepLines.earth,
          on: _run.tool == M4InsulatorPrepTool.earth || _run.earths.length == 2,
          onTap: _holdEarth,
        ),
      M4InsulatorPrepButton.harness => _ToolButton(anchor: key, icon: Icons.health_and_safety_rounded, label: M4InsulatorPrepLines.harness, on: _run.harness, onTap: _putHarness),
    };
  }

  /// The gesture hint for the waiting state (how to play, never the answer):
  /// before the spot a sweep over every insulator; the shelf open, a sweep
  /// over every item and its done button; the earth in hand, a sweep over both
  /// sides of the line, the pole and the tools; otherwise over the tools and
  /// the pole.
  HintSpec? _hint() {
    if (!_run.spotted) {
      final s = _run.site;
      final geo = _geo;
      if (geo == null) return null;
      return HintSpec.sweep([for (var i = 0; i < geo.spots(s.kind); i++) geo.spotHit(s.kind, i)], space: HintSpace.scene);
    }
    if (_shelfOpen) {
      return HintSpec.sweepOver([for (final it in _run.site.shelf) _shelfKeys[it]!, _shelfDoneKey]);
    }
    final tools = [for (final b in _run.site.tools) _toolKeys[b]!];
    if (_run.tool == M4InsulatorPrepTool.earth) {
      return HintSpec.sweepOver([_earthKeys[0], _poleKey, _earthKeys[1], ...tools]);
    }
    return HintSpec.sweepOver([...tools, _poleKey]);
  }

  /// The scene's geometry from the last layout (for the scene-space hint).
  M4InsulatorPrepGeo? _geo;

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.climbed && !deckUp && !coworkerOpen && _card == null && !tableBusy;
    final s = _run.site;
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
              labels: M4InsulatorPrepLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !_ended,
            hintKey: '${_run.index}-${_run.spotted}-$_shelfOpen-${_run.tool.name}-${_run.earths.length}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(pole: s.poleNo, ptw: _run.ptw)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && _run.spotted && !_shelfOpen)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [for (final b in s.tools) _toolButton(b)],
                  ),
                ),
              if (handsOn && _shelfOpen)
                Positioned(
                  key: ValueKey('hud-shelf-${_run.index}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  child: _Shelf(
                    items: s.shelf,
                    anchors: _shelfKeys,
                    doneAnchor: _shelfDoneKey,
                    bag: _run.bag,
                    onPick: _pick,
                    onDone: _closeShelf,
                    quiet: quiet,
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
              if (playing && _card == null && !_shelfOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: !coworkerOnScreen || coworkerFromRight),
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
                  line: M4InsulatorPrepLines.intro,
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.pole, required this.ptw});
  final int pole;
  final bool ptw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${M4InsulatorPrepLines.docket} · ${M4InsulatorPrepLines.poleBn(pole)}', style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4InsulatorPrepLines.docketJob, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          if (ptw)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(border: Border.all(color: SlmColors.success, width: 1.6), borderRadius: BorderRadius.circular(4)),
                child: Text(M4InsulatorPrepLines.ptwStamp, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: SlmColors.success)),
              ),
            ),
        ],
      ),
    );
  }
}

/// The van's shelf: every item drawn, its name under it; lit while in the bag.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.items, required this.anchors, required this.doneAnchor, required this.bag, required this.onPick, required this.onDone, required this.quiet});
  final List<M4InsulatorPrepItem> items;

  /// Gesture-hint anchors (one per item, and the done button).
  final Map<M4InsulatorPrepItem, GlobalKey> anchors;
  final GlobalKey doneAnchor;
  final Set<M4InsulatorPrepItem> bag;
  final void Function(M4InsulatorPrepItem, Offset) onPick;
  final VoidCallback onDone;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 60 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xF2101A2B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.6), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(child: Text(M4InsulatorPrepLines.shelfTitle, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
                Semantics(
                  button: true,
                  label: M4InsulatorPrepLines.shelfDone,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDone,
                    child: Container(
                      key: doneAnchor,
                      constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: SlmColors.gold300, borderRadius: BorderRadius.circular(20)),
                      child: Text(M4InsulatorPrepLines.shelfDone, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (var row = 0; row < 2; row++)
              Padding(
                padding: EdgeInsets.only(top: row == 0 ? 0 : 6),
                child: Row(
                  children: [
                    for (var col = 0; col < 4; col++) ...[
                      if (col > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _ShelfTile(
                          key: ValueKey('shelf-${items[row * 4 + col].name}'),
                          item: items[row * 4 + col],
                          anchor: anchors[items[row * 4 + col]],
                          inBag: bag.contains(items[row * 4 + col]),
                          onPick: onPick,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShelfTile extends StatelessWidget {
  const _ShelfTile({super.key, required this.item, this.anchor, required this.inBag, required this.onPick});
  final M4InsulatorPrepItem item;
  final GlobalKey? anchor;
  final bool inBag;
  final void Function(M4InsulatorPrepItem, Offset) onPick;

  @override
  Widget build(BuildContext context) {
    final label = M4InsulatorPrepLines.itemBn(item);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onPick(item, d.globalPosition),
        child: Container(
          key: anchor,
          height: 92,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 3),
          decoration: BoxDecoration(
            color: inBag ? const Color(0xFF1F4A33) : const Color(0xFFE9E3D3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: inBag ? SlmColors.success : const Color(0xFF8A7A55), width: inBag ? 2.4 : 1.2),
          ),
          child: Column(
            children: [
              Expanded(child: RepaintBoundary(child: CustomPaint(painter: M4InsulatorPrepItemPainter(item), child: const SizedBox.expand()))),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.1, color: inBag ? SlmColors.ivory : const Color(0xFF2B2416))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live, required this.quiet});
  final bool live;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE101A2B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: live ? SlmColors.danger : const Color(0xFF6E7C90), width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: live ? const Color(0xFFFF5A3D) : const Color(0xFF3A3F45),
                boxShadow: live ? const [BoxShadow(color: Color(0xAAFF5A3D), blurRadius: 8, spreadRadius: 1)] : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(live ? M4InsulatorPrepLines.testerLive : M4InsulatorPrepLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({this.anchor, required this.icon, required this.label, required this.on, required this.onTap});
  final GlobalKey? anchor;
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          key: anchor,
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
