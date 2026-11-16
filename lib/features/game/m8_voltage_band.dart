import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
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
import 'm8_voltage_band_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm8_voltage_band_world.dart' show M8VbBus, M8VbBusX, M8VbGeo, M8VbInset, m8VbFrac, m8VbReading;

// Lesson 8.4 "গ্রিড কোড (Grid Code): সিস্টেম শৃঙ্খলার নিয়ম", কাজ 2 "ভোল্টেজ সীমায়
// রাখো" (pack do_8_4_b, engineType m8_voltage_band). The substation's control
// panel: the 11 kV (or 33 kV) bus voltmeter — plain kV numerals, no band, no
// mark on the declared value — the OLTC with its tap digit and two hold
// buttons, RAISE and LOWER, the capacitor bank breaker and its twist switch,
// and the shift log with its pen.
//
// The core verb (hold-step the OLTC tap, reading the needle): three rounds,
// one log entry each. The needle settles at a dealt reading. Press and HOLD
// RAISE or LOWER (a ring fills, ~0.8 s) and the tap steps one position with a
// clunk, the needle eases; a short tap does nothing. TWIST the capacitor
// switch (a drag across it) to put the bank ON — it is never switched OFF.
// Tap the pen on the log to write the entry (the decisive control).
//
// Rules (live lesson 8.4, rulings M8-12, X3: out above +6 % or below -9 %):
//  - the entry is right when the bus voltage is inside the band, and a low
//    round also has the capacitor bank ON (lesson pro tip 2). Normal rounds
//    are right with no touch (or after only turning the bank ON, which is
//    never wrong); stray steps that leave the band, then writing = a slip.
//  - the capacitor starts OFF in every low round and in about half of the
//    normal rounds, ON in high rounds and the other normal rounds, so its
//    state alone tells nothing.
//  - dealt readings never sit in the 6-9 % grey zone: high rounds are +10 % or
//    more, low rounds -10 % or less, normal rounds within about +-3.6 %.
//
// Slips (module 8 table R9, R22, M8-1: the harm is to equipment and consumer
// motors, not the worker; nothing in this level is deadly): an entry with the
// voltage beyond the band (a consequence close-up follows: the LA and
// insulators burst / the pump motor smokes), a low round written with the
// capacitor OFF, and listening to the coworker (B1: 'a little more or less
// is nothing, write it down' / B2: 'no need to look at the tap changer') —
// the entry is then written as it stands and the same slip carries the
// consequence close-up. He comes once a play, on a dealt round (any kind);
// the pen waits for him there (holdForCoworker). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m8_voltage_band_world.dart), corner guide, a right entry puts ◆
// on the table → "কেন …?" (the deck opens at once) → এগিয়ে যান → the next
// round. Gesture hands: a sweep over RAISE, LOWER, the capacitor switch and
// the pen alike; two short taps on one hold button → a hold hand on THAT
// button; the capacitor touched without a twist → a short generic nudge over
// it. No hand during the intro, the coworker's beats, the cards, the insets
// or the results.

// ============================================================================
// Content
// ============================================================================

/// What a round is dealt as.
enum M8VbKind { high, low, normal }

/// The coworker's push (one a play, on his dealt round, any kind).
enum M8VbPush { logIt, skipTap }

/// What a round's reason asks about (fits what the player did).
enum M8VbWhy { tapDown, tapUpCap, capOn, noChange, inBand }

/// Why a control did nothing (the guide says it; never a cost).
enum M8VbNote { tapEnd, capAlready }

/// The lesson point (0-based) the fail panel opens: the voltage limits.
const int m8VbLessonPoint = 0;

abstract final class M8VoltageBandLines {
  static const title = 'ভোল্টেজ সীমায় রাখো';
  // DRAFT wording — owner (M6-12). The spec's intro line, 'পড়ুন' as 'দেখুন'.
  static const intro = 'আজ ভোল্টেজ লাফাচ্ছে! মিটার দেখুন, ট্যাপ চেঞ্জার ঠিক পজিশনে রাখুন!';

  // The guide's task now (tap him: the same task, a different way). The
  // question is asked and never answered. DRAFT wording — owner (M6-12).
  static String askRound(int n) => enDigits('এন্ট্রি $n: বাসের ভোল্টেজ কেমন?');
  static const askWrite = 'ভোল্টেজ দেখে নিয়ে, খাতায় এন্ট্রি লিখুন।';
  static List<String> get tasks => [for (var n = 1; n <= 3; n++) askRound(n), askWrite];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Why a control did nothing (DRAFT wording — owner).
  static String note(M8VbNote n) => switch (n) {
        M8VbNote.tapEnd => 'ট্যাপ আর এগোবে না, শেষ পজিশনে এসে গেছে।',
        M8VbNote.capAlready => 'ক্যাপাসিটর ব্যাংক তো ON আছে।',
      };

  // Labels a worker reads.
  static const raise = 'RAISE';
  static const lower = 'LOWER';
  static const panelLabel = 'সাবস্টেশন কন্ট্রোল প্যানেল';
  static String entryLabel(int n) => enDigits('এন্ট্রি $n');

  // The reasons: the right ones fit what was done; the wrong ones are field
  // excuses and the myths. DRAFT wording — owner.
  static const whyQ = <M8VbWhy, String>{
    M8VbWhy.tapDown: 'কেন ট্যাপ নামালেন?',
    M8VbWhy.tapUpCap: 'কেন ট্যাপ তুললেন আর ক্যাপাসিটর ON করলেন?',
    M8VbWhy.capOn: 'কেন ক্যাপাসিটর ব্যাংক ON করলেন?',
    M8VbWhy.noChange: 'কেন কিছু বদলালেন না?',
    M8VbWhy.inBand: 'কেন ভোল্টেজ ঠিক ধরে লিখলেন?',
  };
  static const whyRight = <M8VbWhy, List<String>>{
    M8VbWhy.tapDown: [
      'হাই ভোল্টেজে ইনসুলেটর বা লাইটনিং অ্যারেস্টার ফেটে যেতে পারে',
      'বেশি ভোল্টেজে ইনসুলেটর আর লাইটনিং অ্যারেস্টার ফেটে যায়',
    ],
    M8VbWhy.tapUpCap: [
      'লো ভোল্টেজে পাম্প বা মোটর জ্বলে যায়; ক্যাপাসিটর ভোল্টেজ বাড়ায়',
      'কম ভোল্টেজে গ্রাহকের মোটর জ্বলে; ক্যাপাসিটর ভোল্টেজ বাড়ায়',
    ],
    M8VbWhy.capOn: [
      'ক্যাপাসিটর ভোল্টেজ কিছুটা বাড়ায়, পাওয়ার ফ্যাক্টরও ঠিক রাখে',
      'ব্যাংক ON করলে ভোল্টেজ কিছুটা বাড়ে, পাওয়ার ফ্যাক্টর ঠিক থাকে',
    ],
    M8VbWhy.noChange: [
      'ভোল্টেজ সীমার মধ্যে আছে, ট্যাপ ঠিক পজিশনে আছে বলে তাই',
      'মিটারে ভোল্টেজ সীমার মধ্যে, ট্যাপ বদলানোর দরকার নেই এখন',
    ],
    M8VbWhy.inBand: [
      'ভোল্টেজ সীমার মধ্যেই আছে, ট্যাপও ঠিক পজিশনে আছে বলে',
      'মিটার সীমার মধ্যে দেখাচ্ছে, তাই ঠিক ধরে লিখে দিলাম আজ',
    ],
  };
  static const myths = [
    'বেশি ভোল্টেজে গ্রাহক খুশি থাকে, তাই সীমা ছাড়ালেও চলে',
    'কম ভোল্টেজে বিল কম আসে, তাই কম থাকাই বেশ ভালো আসলে',
    'বোতাম টিপতে ভয় লাগে, তাই আমি কিছুই ছুঁইনি আজ সকাল থেকে',
    'ভোল্টেজ যতই হোক, যন্ত্রপাতি সবই সয়ে নেয় ঠিকই, চিন্তা নেই',
    'ট্যাপ বদলালে ট্রান্সফরমার নষ্ট হবে, তাই বদলাই না কখনও',
    'কাল যা ছিল আজও তাই থাকবে, দেখার দরকারই নেই তো আর ভাই',
    'ক্যাপাসিটর ব্যাংক শুধু বাড়তি ঝামেলা, না থাকলেও চলে যায়',
    'ভোল্টেজ একটু কম-বেশি হলে গ্রাহক টেরই পায় না কিছু আর',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, on his dealt round, any kind).
  // DRAFT wording — owner (M6-12): the spec's two pushes and refusals.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLogIt = CoworkerScript(
    line: 'ভোল্টেজ একটু কম-বেশি হলে কিছু যায় আসে না, খাতায় লিখে দাও!',
    exitLine: coworkerExit,
    right: [
      'সীমার বাইরে হলে ঠিক করে তবেই খাতায় লিখব',
      'না, মিটার দেখে ভোল্টেজ সীমায় এনে তবেই লিখব',
      'না, সীমা ছাড়ানো ভোল্টেজ লিখে দেওয়া চলে না',
    ],
    wrong: [
      'ঠিক, একটু কম-বেশিতে কিছু যায় আসে না ভাই',
      'আচ্ছা, যেমন আছে তেমনই খাতায় লিখে দিই তবে',
      'হ্যাঁ, এটুকু কম-বেশি তো রোজই থাকে ভাই',
      'ঠিক আছে, মিটার যা দেখাচ্ছে তাই লিখি এখন',
      'হ্যাঁ, লিখে দিলেই ঝামেলা শেষ, চলো তবে',
    ],
    asks: ['কী করবেন?', 'ও বলছে কম-বেশি হলেও লিখে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerSkipTap = CoworkerScript(
    line: 'ট্যাপ চেঞ্জার দেখার দরকার নেই, কাল যা ছিল তাই আছে!',
    exitLine: coworkerExit,
    right: [
      'রোজ দেখতে হয় ট্যাপ ঠিক পজিশনে আছে কি না',
      'না, ট্যাপ চেঞ্জারের পজিশন আজই নিজে দেখব',
      'না, কালকের পজিশনের ভরসায় খাতায় লিখব না',
    ],
    wrong: [
      'ঠিক, কাল যা ছিল আজও তাই আছে বলেই তো',
      'আচ্ছা, ট্যাপ চেঞ্জার আর দেখে কী হবে বলো',
      'হ্যাঁ, রোজ রোজ ট্যাপ দেখার সময় কোথায় ভাই',
      'ঠিক আছে, না দেখেই লিখে দিচ্ছি এখনই ভাই',
      'হ্যাঁ, ট্যাপ তো নড়েনি বলেই মনে হচ্ছে আজ',
    ],
    asks: ['কী করবেন?', 'ও বলছে ট্যাপ চেঞ্জার দেখতে হবে না। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M8VbPush p) => switch (p) {
        M8VbPush.logIt => coworkerLogIt,
        M8VbPush.skipTap => coworkerSkipTap,
      };
  static const allCoworkers = [coworkerLogIt, coworkerSkipTap];

  static String callHeld(M8VbPush p) => switch (p) {
        M8VbPush.logIt => 'ঠিক! সীমার বাইরের ভোল্টেজ খাতায় লিখে দেওয়া চলে না।',
        M8VbPush.skipTap => 'ঠিক! ট্যাপ চেঞ্জার ঠিক পজিশনে আছে কি না রোজ দেখতে হয়।',
      };

  static const allSet = 'তিন এন্ট্রিই ঠিক, ভোল্টেজ এখন সীমার মধ্যে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার, মিটার দেখুন, ট্যাপ ঠিক করুন, তারপর লিখুন।';

  // "আজ যা ধরলেন".
  static const caughtHigh = 'হাই ভোল্টেজ, ট্যাপ নামিয়ে সীমায়';
  static const caughtLow = 'লো ভোল্টেজ, ট্যাপ আর ক্যাপাসিটরে সীমায়';
  static const caughtNormal = 'সীমার ভোল্টেজ ঠিক ধরেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new pushes (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        for (var n = 1; n <= 3; n++) askRound(n),
        askWrite,
        for (final n in M8VbNote.values) note(n),
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        for (final p in M8VbPush.values) callHeld(p),
        allSet,
        fail,
        for (final m in M8VoltageBandMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M8VoltageBandMistakes {
  static const _dir = 'assets/game/art/m8_voltage_band';

  // DRAFT wording — owner (M6-12). Sources: lesson 8.4 section 3 (ভোল্টেজ
  // লিমিট: +6 % / -9 %, the consequences, the OLTC daily check) and pro tip 2
  // (ক্যাপাসিটর ব্যাংক ON).
  static const highLogged = DoMistake(
    key: '8.4/m8_voltage_band/high-logged',
    textBn: 'ভোল্টেজ ঘোষিত মানের চেয়ে 6%-এর বেশি বাড়লে চলবে না, ইনসুলেটর বা লাইটনিং অ্যারেস্টার ফেটে যেতে পারে। আগে ট্যাপ চেঞ্জারে ভোল্টেজ নামান, তারপর লিখুন।',
    art: '$_dir/high.svg',
    lessonPoint: 1,
  );
  static const lowLogged = DoMistake(
    key: '8.4/m8_voltage_band/low-logged',
    textBn: 'ভোল্টেজ ঘোষিত মানের চেয়ে 9%-এর বেশি কমলে চলবে না, গ্রাহকের পাম্প বা মোটর জ্বলে যেতে পারে। ট্যাপ তুলুন, ক্যাপাসিটর ব্যাংক ON করুন, তারপর লিখুন।',
    art: '$_dir/low.svg',
    lessonPoint: 1,
  );
  static const capOffLow = DoMistake(
    key: '8.4/m8_voltage_band/cap-off-low',
    textBn: 'লো ভোল্টেজের সমস্যায় ক্যাপাসিটর ব্যাংক ON রাখতে হয়, ভোল্টেজ কিছুটা বাড়ে, পাওয়ার ফ্যাক্টরও ঠিক থাকে। ট্যাপে ভোল্টেজ উঠলেও ব্যাংক OFF রেখে লেখা চলে না।',
    art: '$_dir/capoff.svg',
    lessonPoint: 3,
  );
  static const listenLogIt = DoMistake(
    key: '8.4/m8_voltage_band/listen-log-it',
    textBn: 'ভোল্টেজ সীমার বাইরে গেলে চলবে না, বাড়লে ইনসুলেটর আর লাইটনিং অ্যারেস্টার ফাটে, কমলে গ্রাহকের পাম্প বা মোটর জ্বলে। কম-বেশি বলে লিখে দিলে হবে না; আগে মিটার দেখে সীমায় আনুন।',
    art: '$_dir/listenlog.svg',
    lessonPoint: 0,
  );
  static const listenSkipTap = DoMistake(
    key: '8.4/m8_voltage_band/listen-skip-tap',
    textBn: 'পাওয়ার ট্রান্সফরমারের ট্যাপ চেঞ্জার (OLTC) ঠিক পজিশনে আছে কি না রোজ দেখতে হয়। কালকের পজিশনের ভরসায় লিখলে হবে না; আজকের মিটার আর ট্যাপ দেখে লিখুন।',
    art: '$_dir/listentap.svg',
    lessonPoint: 2,
  );

  /// Listening to his push is the act it pushes (X2/B1: a slip here).
  static DoMistake push(M8VbPush p) => switch (p) {
        M8VbPush.logIt => listenLogIt,
        M8VbPush.skipTap => listenSkipTap,
      };

  static const List<DoMistake> all = [highLogged, lowLogged, capOffLow, listenLogIt, listenSkipTap];
}

/// One round as dealt.
@immutable
class M8VbRound {
  const M8VbRound({required this.kind, required this.startKv, required this.startTap, required this.capStartOn});

  final M8VbKind kind;

  /// The reading the needle settles at (kV), the capacitor as it stands.
  final double startKv;

  /// The tap digit the panel starts at (1-9).
  final int startTap;
  final bool capStartOn;

  /// Steps the tap must move, with the capacitor as dealt, to enter the band:
  /// a high round steps down, a low round steps up (0 for a normal round).
  int stepsNeeded(M8VbBus b) => switch (kind) {
        M8VbKind.high => ((startKv - b.hi) / b.step - 1e-9).ceil(),
        M8VbKind.low => ((b.lo - startKv) / b.step - 1e-9).ceil(),
        M8VbKind.normal => 0,
      };

  /// A low round the capacitor bank alone brings into the band.
  bool capAloneHelps(M8VbBus b) => kind == M8VbKind.low && startKv + b.capRise >= b.lo - 1e-9;
}

@immutable
class M8VbDeal {
  const M8VbDeal({required this.bus, required this.rounds, required this.coworkerRound, required this.push});

  final M8VbBus bus;
  final List<M8VbRound> rounds;

  /// The round the coworker comes in at (his push fits any kind).
  final int coworkerRound;
  final M8VbPush push;
}

/// The reading pools (kV): safe 11 kV 10.7-11.4, 33 kV 32.0-34.0; out 11 kV
/// 12.1-12.3 / 9.7-9.9, 33 kV 36.3-36.8 / 29.4-29.7 (never inside 6-9 %).
(double, double) m8VbPool(M8VbBus b, M8VbKind k) => switch ((b, k)) {
      (M8VbBus.kv11, M8VbKind.normal) => (10.7, 11.4),
      (M8VbBus.kv33, M8VbKind.normal) => (32.0, 34.0),
      (M8VbBus.kv11, M8VbKind.high) => (12.1, 12.3),
      (M8VbBus.kv33, M8VbKind.high) => (36.3, 36.8),
      (M8VbBus.kv11, M8VbKind.low) => (9.7, 9.9),
      (M8VbBus.kv33, M8VbKind.low) => (29.4, 29.7),
    };

/// One round of [k] on [b]: a reading from its pool, 1-3 steps needed.
M8VbRound m8VbRound(M8VbKind k, M8VbBus b, math.Random rng) {
  final (lo, hi) = m8VbPool(b, k);
  while (true) {
    final kv = (lo + rng.nextDouble() * (hi - lo)) * 100;
    final r = M8VbRound(
      kind: k,
      startKv: kv.roundToDouble() / 100,
      startTap: 4 + rng.nextInt(3),
      // OFF in every low round, ON in every high round, either way in about
      // half of the normal rounds (so the lamp alone tells nothing).
      capStartOn: switch (k) {
        M8VbKind.low => false,
        M8VbKind.high => true,
        M8VbKind.normal => rng.nextBool(),
      },
    );
    if (k == M8VbKind.normal) return r;
    final n = r.stepsNeeded(b);
    if (n >= 1 && n <= 3) return r;
  }
}

M8VbDeal m8VbDeal(math.Random rng) {
  final bus = rng.nextBool() ? M8VbBus.kv11 : M8VbBus.kv33;
  // At least one high and one low, the third any kind, in a random order.
  final kinds = <M8VbKind>[M8VbKind.high, M8VbKind.low, M8VbKind.values[rng.nextInt(3)]]..shuffle(rng);
  return M8VbDeal(
    bus: bus,
    rounds: [for (final k in kinds) m8VbRound(k, bus, rng)],
    coworkerRound: rng.nextInt(3),
    push: M8VbPush.values[rng.nextInt(2)],
  );
}

/// The play state (pure logic).
class M8VbRun {
  M8VbRun(this.deal) : entries = [null, null, null] {
    _startRound();
  }
  final M8VbDeal deal;

  /// What the log holds (the reading written, null: not yet).
  final List<double?> entries;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  final List<String> caught = [];

  /// The tap digit and the capacitor, as they stand now.
  int tap = 5;
  bool capOn = false;

  /// This round the capacitor was turned ON by the player; tap steps made.
  bool capTurned = false;
  int stepsUsed = 0;

  /// The entry is written (right: its reason comes next).
  bool roundDone = false;

  /// The entry was written wrong: a slip, and the next round follows its card.
  bool closedWrong = false;

  /// Why the last control did nothing (null: it did something).
  M8VbNote? note;

  M8VbBus get bus => deal.bus;
  M8VbRound get round => deal.rounds[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !done && !roundDone;

  /// The bus voltage now (kV): the dealt reading, the tap steps and the
  /// capacitor (if the player turned it ON).
  double get kv => round.startKv + (tap - round.startTap) * bus.step + (capOn && !round.capStartOn ? bus.capRise : 0);

  /// Inside the live band: not above +6 % and not below -9 % (lesson 8.4).
  bool get inBand => kv >= bus.lo - 1e-9 && kv <= bus.hi + 1e-9;

  /// What a wrong entry now would show.
  M8VbInset? get insetNow => kv > bus.hi + 1e-9
      ? M8VbInset.high
      : kv < bus.lo - 1e-9
          ? M8VbInset.low
          : null;

  /// Something was touched this round.
  bool get touched => stepsUsed > 0 || capTurned;

  /// The coworker may come on his round while it is open.
  bool get coworkerMoment => _open;

  void _startRound() {
    final r = round;
    tap = r.startTap;
    capOn = r.capStartOn;
    capTurned = false;
    stepsUsed = 0;
    roundDone = false;
    closedWrong = false;
    roundSlips = 0;
    note = null;
  }

  /// One hold-step of the OLTC: [dir] +1 = RAISE, -1 = LOWER. False at the
  /// end of the range (nothing moved).
  bool step(int dir) {
    note = null;
    if (!_open) return false;
    final t = tap + dir;
    if (t < 1 || t > 9) {
      note = M8VbNote.tapEnd;
      return false;
    }
    tap = t;
    stepsUsed++;
    return true;
  }

  /// The capacitor switch twisted ON (never OFF). False if it was already ON.
  bool twistCap() {
    note = null;
    if (!_open) return false;
    if (capOn) {
      note = M8VbNote.capAlready;
      return false;
    }
    capOn = true;
    capTurned = true;
    return true;
  }

  DoMistake _close(DoMistake m) {
    roundDone = true;
    closedWrong = true;
    slips++;
    roundSlips++;
    return m;
  }

  /// The pen: write the entry as the panel stands. A slip when the voltage is
  /// beyond the band, or a low round has the capacitor still OFF.
  DoMistake? log() {
    note = null;
    if (!_open) return null;
    entries[index] = kv;
    if (!inBand) return _close(kv > bus.hi ? M8VoltageBandMistakes.highLogged : M8VoltageBandMistakes.lowLogged);
    if (round.kind == M8VbKind.low && !capOn) return _close(M8VoltageBandMistakes.capOffLow);
    roundDone = true;
    final tag = switch (round.kind) {
      M8VbKind.high => M8VoltageBandLines.caughtHigh,
      M8VbKind.low => M8VoltageBandLines.caughtLow,
      M8VbKind.normal => M8VoltageBandLines.caughtNormal,
    };
    if (!caught.contains(tag)) caught.add(tag);
    return null;
  }

  /// Listened to him: the entry is written as it stands, and the one slip is
  /// his push (a consequence close-up belongs to the same slip).
  DoMistake listen(M8VbPush p) {
    entries[index] = kv;
    return _close(M8VoltageBandMistakes.push(p));
  }

  /// What this round's reason asks about (fits what the player did).
  M8VbWhy get why => switch (round.kind) {
        M8VbKind.high => M8VbWhy.tapDown,
        M8VbKind.low => stepsUsed > 0 ? M8VbWhy.tapUpCap : M8VbWhy.capOn,
        M8VbKind.normal => stepsUsed > 0 ? M8VbWhy.inBand : (capTurned ? M8VbWhy.capOn : M8VbWhy.noChange),
      };

  void next() {
    index++;
    if (!done) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   a round: look (1500), two holds (2 × 1100), the capacitor twist (1200,
///     low rounds), the pen (900) ≈ 4000–6000 + a reason (~8200)
///   three rounds + the coworker once (~9600)                        ≈ 48000–58000
/// 85 % ≈ 46000 → 45 s (a builder's estimate; owner may tune).
const m8VoltageBandQuickMs = 45000;

@immutable
class M8VoltageBandPack {
  const M8VoltageBandPack({required this.id, required this.titleBn, this.quickMs = m8VoltageBandQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8VoltageBandPack> m8VoltageBandPacks = {
  'do_8_4_b': M8VoltageBandPack(id: 'do_8_4_b', titleBn: M8VoltageBandLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8VoltageBandProbe {
  static M8VbRun? run;
}

/// What the gesture hand is about next (set by a touch that did not work).
enum _HintAbout { none, raise, lower, cap }

// ============================================================================
// Page
// ============================================================================

class M8VoltageBandPage extends StatefulWidget {
  const M8VoltageBandPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8VoltageBandPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8VoltageBandPage> createState() => _M8VoltageBandPageState();
}

class _M8VoltageBandPageState extends State<M8VoltageBandPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _VbRunPage(
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

class _VbRunPage extends ConsumerStatefulWidget {
  const _VbRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8VoltageBandPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_VbRunPage> createState() => _VbRunPageState();
}

class _VbRunPageState extends ConsumerState<_VbRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8VbRun _run;
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

  /// The hold button pressed now (+1 RAISE, -1 LOWER; null: none) and its ring.
  int? _holding;
  var _holdFired = false;
  int? _holdPointer;
  late final AnimationController _holdCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  /// Short taps in a row on one hold button (two = the hold hand on it).
  int _shortDir = 0;
  int _shortRun = 0;

  /// The capacitor switch: a drag across it starts at [_twistFrom].
  Offset? _twistFrom;
  var _twistDone = false;

  /// The needle's ease: from → to on [_needleCtl].
  late final AnimationController _needleCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  var _moving = false;
  double _nFrom = 0, _nTo = 0;

  /// The consequence close-up being shown (null: none).
  M8VbInset? _inset;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _raiseKey = GlobalKey();
  final _lowerKey = GlobalKey();
  final _capKey = GlobalKey();
  final _penKey = GlobalKey();
  int _steps = 0;
  var _hintAbout = _HintAbout.none;
  M8VbGeo? _geoNow;

  static const _ease = Curves.easeOutBack;

  @override
  void initState() {
    super.initState();
    _run = M8VbRun(m8VbDeal(widget.rng));
    M8VoltageBandProbe.run = _run;
    _nFrom = _nTo = _run.kv;
    _holdCtl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _holdComplete();
    });
    _needleCtl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted && _moving) setState(() => _moving = false);
    });
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _holdCtl.dispose();
    _needleCtl.dispose();
    _chain++;
    if (identical(M8VoltageBandProbe.run, _run)) M8VoltageBandProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && _inset == null;

  String get _task => _run.touched ? M8VoltageBandLines.askWrite : M8VoltageBandLines.askRound(_run.index + 1);

  Future<void> _start() async {
    _clock.start();
    setState(() => _steps++);
    _maybeCoworker();
    unawaited(_sayChain([_task]));
  }

  /// His moment on his round: once due, the pen waits.
  void _maybeCoworker() {
    if (_run.index == _run.deal.coworkerRound && !coworkerDone && !coworkerDue && _run.coworkerMoment) scheduleCoworker();
  }

  bool _waitForHim() => _run.index == _run.deal.coworkerRound && holdForCoworker();

  void _stepDone() => setState(() => _steps++);

  // --- the needle ------------------------------------------------------------------
  /// Where the needle is drawn now (kV).
  double _displayKv() => _moving ? _nFrom + (_nTo - _nFrom) * _ease.transform(_needleCtl.value) : _nTo;

  void _animateNeedle(double from, double to, {int ms = 450}) {
    _nFrom = from;
    _nTo = to;
    if (_quiet || (from - to).abs() < 1e-9) {
      _moving = false;
      _needleCtl.value = 1;
      setState(() {});
      return;
    }
    _needleCtl.duration = Duration(milliseconds: ms);
    setState(() => _moving = true);
    unawaited(_needleCtl.forward(from: 0));
  }

  // --- hands on -----------------------------------------------------------------
  void _note() {
    final n = _run.note;
    _tick();
    if (n != null) unawaited(_sayChain([M8VoltageBandLines.note(n)]));
  }

  /// After the next frame: a press made the level not 'waiting' until the
  /// rebuild, and the hand ignores misses while it is not waiting.
  void _later(VoidCallback f) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) f();
      });

  void _fireHint(_HintAbout about) {
    _hintAbout = about;
    _later(() {
      for (var i = 0; i < 3; i++) {
        _hints.missTap();
      }
    });
  }

  // The hold buttons (a Listener on the scene: down starts the ring, up
  // before it is full is a short tap and does nothing).
  void _down(PointerDownEvent e, M8VbGeo geo) {
    _holdFired = false;
    if (!_canPlay || _holding != null) return;
    final p = e.localPosition;
    final dir = geo.raise.contains(p)
        ? 1
        : geo.lower.contains(p)
            ? -1
            : 0;
    if (dir == 0) return;
    _holdPointer = e.pointer;
    HapticFeedback.selectionClick();
    setState(() => _holding = dir);
    unawaited(_holdCtl.forward(from: 0));
  }

  void _up(PointerEvent e) {
    if (e.pointer != _holdPointer) return;
    _holdPointer = null;
    final dir = _holding;
    if (dir == null) return;
    // Let go before the ring was full: a short tap.
    _holdCtl.stop();
    setState(() => _holding = null);
    if (_holdFired) return;
    _shortRun = _shortDir == dir ? _shortRun + 1 : 1;
    _shortDir = dir;
    if (_shortRun >= 2) {
      _shortRun = 0;
      _fireHint(dir > 0 ? _HintAbout.raise : _HintAbout.lower);
    } else {
      _later(_hints.missTap);
    }
  }

  void _holdComplete() {
    final dir = _holding;
    if (!mounted || dir == null) return;
    _holdFired = true;
    _shortRun = 0;
    setState(() => _holding = null);
    if (!_canPlay) return;
    final from = _displayKv();
    if (!_run.step(dir)) {
      _note();
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    _animateNeedle(from, _run.kv);
    _stepDone();
  }

  void _tapScene(Offset p, M8VbGeo geo, Offset global) {
    if (!_canPlay) return;
    if (geo.pen.contains(p)) {
      _logEntry(global);
      return;
    }
    if (geo.cap.contains(p)) {
      _fireHint(_HintAbout.cap);
      return;
    }
    if (geo.raise.contains(p) || geo.lower.contains(p)) return;
    _hints.missTap();
  }

  // The capacitor switch: a drag across it twists it ON.
  void _panStart(Offset p, M8VbGeo geo) {
    _twistFrom = null;
    _twistDone = false;
    if (!_canPlay || _holding != null) return;
    if (!geo.cap.inflate(6).contains(p)) return;
    _twistFrom = p;
  }

  void _panUpdate(Offset p) {
    final from = _twistFrom;
    if (from == null || _twistDone) return;
    if ((p - from).distance < 30) return;
    _twistDone = true;
    if (!_canPlay) return;
    _twist();
  }

  void _panEnd() {
    final was = _twistFrom != null && !_twistDone;
    _twistFrom = null;
    // A short drag that did not twist: the same as a touch.
    if (was && _canPlay) _fireHint(_HintAbout.cap);
  }

  void _twist() {
    final moved = _run.twistCap();
    if (!moved) {
      _note();
      return;
    }
    final from = _displayKv();
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    _animateNeedle(from, _run.kv);
    _stepDone();
  }

  // The pen: the entry is written as the panel stands.
  void _logEntry(Offset global) {
    if (!_canPlay || _holding != null) return;
    if (_waitForHim()) return;
    final inset = _run.insetNow;
    final m = _run.log();
    if (m != null) {
      unawaited(_slipAfterInset(m, inset, global));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.55);
    _stepDone();
    unawaited(_entryDone());
  }

  /// A wrong entry: the consequence close-up first (when the voltage was
  /// beyond the band), then the slip card.
  Future<void> _slipAfterInset(DoMistake m, M8VbInset? inset, Offset origin) async {
    setState(() => _steps++);
    if (inset != null) {
      await _showInset(inset);
      if (!mounted || _ended) return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Future<void> _showInset(M8VbInset kind) async {
    _hush();
    HapticFeedback.heavyImpact();
    _cue(kind == M8VbInset.high ? 'sounds/learn/spark.ogg' : 'sounds/intro/impact_metal.ogg', volume: 0.9);
    setState(() => _inset = kind);
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 700 : 1900));
    if (!mounted) return;
    setState(() => _inset = null);
  }

  Future<void> _entryDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final topic = _run.why;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M8VoltageBandLines.whyRight[topic]!, M8VoltageBandLines.myths, widget.rng),
      question: M8VoltageBandLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    final from = _nTo;
    setState(() => _run.next());
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _animateNeedle(from, _run.kv, ms: 700);
    _stepDone();
    _maybeCoworker();
    unawaited(_sayChain([_task]));
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
  CoworkerScript get coworkerScript => M8VoltageBandLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerRound || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _holding != null || _twistFrom != null || _moving || _inset != null) return false;
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
      // The entry is written as it stands; one slip, with the close-up when
      // the voltage was beyond the band.
      final inset = _run.insetNow;
      final m = _run.listen(p);
      setState(() => _steps++);
      if (inset != null) {
        await _showInset(inset);
        if (!mounted || _ended) return;
      }
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8VoltageBandLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8VoltageBandLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8VoltageBandLines.tapWhy[_nudgeN++ % M8VoltageBandLines.tapWhy.length]
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
      _steps++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8vb/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _steps++;
    });
    // Every slip closed its entry as written: on to the next round.
    if (_run.closedWrong) {
      _next();
      return;
    }
    _maybeCoworker();
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
    await _say(!_run.passed ? M8VoltageBandLines.fail : (_quickBonus ? M8VoltageBandLines.quick : M8VoltageBandLines.allSet),
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
  /// The gesture hand: how to touch, never what. A sweep over RAISE, LOWER,
  /// the capacitor switch and the pen alike; after two short taps on one hold
  /// button a hold hand on THAT button; after a touch on the capacitor switch
  /// without a twist a short generic nudge over it.
  HintSpec? _hint() {
    if (_geoNow == null) return null;
    final about = _hintAbout;
    _hintAbout = _HintAbout.none;
    switch (about) {
      case _HintAbout.raise:
        return HintSpec.holdOn(_raiseKey);
      case _HintAbout.lower:
        return HintSpec.holdOn(_lowerKey);
      case _HintAbout.cap:
        return HintSpec.dragFrom(_capKey, toward: const Offset(1, 0), travel: 36);
      case _HintAbout.none:
        return HintSpec.sweepOver([_raiseKey, _lowerKey, _capKey, _penKey]);
    }
  }

  M8VbRig get _rig => M8VbRig(bus: _run.bus, tap: _run.tap, capOn: _run.capOn, entries: List.of(_run.entries), current: _run.index.clamp(0, 2));

  Widget _needleLayer(M8VbGeo geo) {
    if (!_moving) return CustomPaint(painter: M8VbNeedlePainter(geo: geo, bus: _run.bus, kv: _nTo));
    return AnimatedBuilder(
      animation: _needleCtl,
      builder: (_, _) => CustomPaint(painter: M8VbNeedlePainter(geo: geo, bus: _run.bus, kv: _displayKv())),
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8VbGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    Widget box(String id, Rect r, GlobalKey key) => Positioned.fromRect(
          key: ValueKey('box-$id'),
          rect: r,
          child: IgnorePointer(child: SizedBox.expand(key: key)),
        );
    return [
      Positioned.fill(
        key: const ValueKey('panel'),
        child: RepaintBoundary(child: CustomPaint(painter: M8VbPanelPainter(geo: geo, rig: _rig))),
      ),
      Positioned.fill(
        key: const ValueKey('needle'),
        child: RepaintBoundary(child: _needleLayer(geo)),
      ),
      box('raise', geo.raise, _raiseKey),
      box('lower', geo.lower, _lowerKey),
      box('cap', geo.cap, _capKey),
      box('pen', geo.pen, _penKey),
      if (_holding != null)
        Positioned.fill(
          key: ValueKey('ring-$_holding'),
          child: IgnorePointer(
            child: CustomPaint(painter: M8VbRingPainter(at: (_holding! > 0 ? geo.raise : geo.lower).center, progress: _holdCtl)),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8VoltageBandLines.panelLabel,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _down(e, geo),
            onPointerUp: _up,
            onPointerCancel: _up,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
              onPanStart: (d) => _panStart(d.localPosition, geo),
              onPanUpdate: (d) => _panUpdate(d.localPosition),
              onPanEnd: (_) => _panEnd(),
              onPanCancel: _panEnd,
            ),
          ),
        ),
      ),
      // The next round: a short fade.
      if (!_intro)
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
      // The consequence close-up of a wrong entry.
      if (_inset != null)
        Positioned.fromRect(
          key: ValueKey('inset-${_inset!.name}'),
          rect: geo.insetBox,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 0.6 : 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 1800),
              builder: (_, v, _) => CustomPaint(size: Size.infinite, painter: M8VbInsetPainter(kind: _inset!, v: v)),
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null && _inset == null;
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
              labels: [for (var n = 1; n <= 3; n++) M8VoltageBandLines.entryLabel(n)],
              done: {for (var k = 0; k < math.min(_run.index, 3); k++) k},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _holding == null && _twistFrom == null && !_moving,
            hintKey: '${_run.index}/$_steps',
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
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  line: M8VoltageBandLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: m8VbLessonPoint, muted: _muted)),
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
