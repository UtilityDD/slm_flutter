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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_lug_pick_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.3, কাজ 1: "সঠিক ল্যাগ". At the workshop bench, a new cable's end
// in the vice — its sheath print says the metal and the size (AL / CU, sq mm).
// Take a lug from the tray (its stamp is readable only up close), run a finger
// along the barrel (a crack shows only where the hand has been), look into its
// mouth (oil and grime inside), then take it or put it back. With the right
// lug: lay it beside the cable end and set the knife to the barrel's depth,
// then strip — the conductor must go fully into the barrel and the insulation
// stay outside it, no bare strand left out. Three cables, easy to hard; on the
// last one no lug in the tray is right — get the right one from the store
// (lesson: তারের সাইজ আর মেটেরিয়াল মিলিয়ে নিন; ভুল সাইজে লুজ কানেকশন).
// Once a play the careless coworker (level 1's rival) peeps in: "একটু বড়
// ল্যাগ, চেপে দিলেই হবে" — or a copper lug on an aluminium cable. Built on the
// shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full scene, corner
// guide, ◆ on the table → "কেন …?" → next cable by itself.
//
// Deadly: none — the lesson makes these faults (wrong metal, wrong size, a
// cracked or dirty lug, a wrong strip) a bad connection that heats and fails
// later, not a death on the spot. Every fault is a slip; 3 slips fail.
//
// Voice: the guide's lines on device TTS; the coworker's push is new (device
// TTS in his voice settings until recorded); his exit line is recorded.
// Art: the scene, the lugs and the strip bench are drawn in code
// (m2_lug_pick_world.dart); the mistake cards use assets/game/art/m2_lug_pick/.

// ============================================================================
// Content
// ============================================================================

/// The conductor's metal.
enum LugMetal { al, cu }

extension LugMetalText on LugMetal {
  /// As printed on a cable and stamped on a lug.
  String get tag => this == LugMetal.al ? 'AL' : 'CU';
  String get bn => this == LugMetal.al ? 'অ্যালুমিনিয়াম' : 'তামা';
  LugMetal get other => this == LugMetal.al ? LugMetal.cu : LugMetal.al;
}

/// Standard cable / lug sizes, sq mm.
const kLugSizes = [10, 16, 25, 35, 50, 70, 95];

int lugSizeAbove(int size) => kLugSizes[math.min(kLugSizes.indexOf(size) + 1, kLugSizes.length - 1)];

enum LugFlaw { none, crack, dirt }

@immutable
class LugItem {
  const LugItem({required this.id, required this.metal, required this.size, this.flaw = LugFlaw.none});
  final String id;
  final LugMetal metal;
  final int size;
  final LugFlaw flaw;

  /// The stamp on its palm.
  String get stamp => '${metal.tag} ${enDigits('$size')}';
}

@immutable
class LugCable {
  const LugCable({required this.metal, required this.size});
  final LugMetal metal;
  final int size;

  /// Its sheath print.
  String get print => '${metal.tag} · ${enDigits('$size')} sq mm';
  bool fits(LugItem l) => l.metal == metal && l.size == size && l.flaw == LugFlaw.none;
}

@immutable
class LugRoundDeal {
  const LugRoundDeal({required this.cable, required this.lugs});
  final LugCable cable;
  final List<LugItem> lugs;

  /// No lug in the tray is right: get the right one from the store.
  bool get noneFits => !lugs.any(cable.fits);

  /// The lug of the cable's own metal and size (sound or not), if any.
  LugItem? get twin {
    for (final l in lugs) {
      if (l.metal == cable.metal && l.size == cable.size && l.flaw != LugFlaw.none) return l;
    }
    return null;
  }
}

/// What the careless coworker pushes.
enum LugPush { bigger, metal }

@immutable
class LugDeal {
  const LugDeal({required this.rounds, required this.callRound, required this.callMetal});
  final List<LugRoundDeal> rounds;

  /// The cable on which the coworker peeps in (or a later one, if that one
  /// was done before he could).
  final int callRound;

  /// He pushes a copper lug for the aluminium cable (only on an AL cable);
  /// otherwise the bigger lug.
  final bool callMetal;
}

abstract final class LugLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask, inspectAsk, stripAsk];

  static const title = 'সঠিক ল্যাগ';
  static const intro = 'নতুন কেবিলের মাথায় ল্যাগ বসাতে হবে! তারের ধাতু আর মাপ দেখে ঠিক ল্যাগটা বাছুন।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const ask = 'তারের গায়ের লেখা দেখুন। কোন ল্যাগটা?';
  static const inspectAsk = 'ব্যারেলে আঙুল বুলিয়ে, মুখের ভেতরটাও দেখুন। নেবেন?';
  static const stripAsk = 'ল্যাগ পাশে রেখে মাপুন। কতটা ছিলবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const cableWord = 'তার';
  static String cableBn(LugCable c) => '${c.metal.bn} কেবিল · ${enDigits('${c.size}')} বর্গ মিমি';
  static const lugLabel = 'ল্যাগ';
  static const cableLabel = 'কেবিল';
  static const handLabel = 'ল্যাগ হাতে';
  static const mouthLabel = 'ব্যারেলের মুখ';
  static const stripLabel = 'ছিলার জায়গা';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const strip = 'ছিলুন';
  static const hold = 'ঠিক ল্যাগ নেই — স্টোর থেকে আনাই';
  static const rejected = 'বাদ';

  // The reasons (lesson 2.3): the right ones fit this cable and this tray.
  // Every card is 38–47 letters, so none stands out by its length.
  static const packAsk = 'কেন এই ল্যাগটা নিলেন?';
  static const holdAsk = 'কেন স্টোর থেকে আনাতে চাইলেন?';
  static String packMatch(LugMetal m) =>
      m == LugMetal.al ? 'তার অ্যালুমিনিয়ামের, ল্যাগও তাই — মাপও এক' : 'তার তামার, ল্যাগও তামার — তারের মাপেই ল্যাগ';
  static const packSound = [
    'মাপ আর ধাতু মিলেছে, ব্যারেলেও কোনো ফাটল নেই',
    'একই সাইজ, একই ধাতু — ব্যারেলের ভেতরটাও পরিষ্কার',
  ];
  static const packMyths = [
    'একটু বড় ল্যাগ চেপে দিলেই ঠিক হয়ে যায়',
    'তামা ভালো, তাই যেকোনো তারে তামার ল্যাগ চলে',
    'ল্যাগ তো ল্যাগই, মাপে কিছু আসে যায় না',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিয়ে নিলাম',
    'পরে সোল্ডার করে দিলে সব মজবুত হয়ে যাবে',
  ];

  /// Why this lug on a [m] cable: metal and size matched, and it was sound.
  static List<String> packRight(LugMetal m) => [packMatch(m), ...packSound];

  /// The other metal's match (true elsewhere, not here) and the myths.
  static List<String> packWrong(LugMetal m) => [packMatch(m.other), ...packMyths];

  static String flawWhy(LugFlaw f) => f == LugFlaw.crack ? 'মাপমতো ল্যাগটার ব্যারেলেই ফাটল ধরেছে' : 'মাপমতো ল্যাগটার ভেতরে তেল-ময়লা জমেছে';
  static const holdSound = [
    'মাপ-ধাতু মেলানো ভালো ল্যাগ ট্রেতে নেই',
    'মিল না থাকলে ক্রিম্প নয়, আগে ঠিকটা আনি',
  ];
  static const holdExcuses = [
    'ক্রিম্প করতে সময় লাগে, তাই বাদ দিলাম',
    'স্টোরকিপার বকবে, তাই কোনো ল্যাগ নিইনি',
    'টুলটা ভারী, আজ ক্রিম্প করার ইচ্ছে নেই',
    'সুপারভাইজার না এলে কাজ শুরুই হয় না',
    'দুপুর হয়ে গেছে, পরে করলেই চলে যাবে',
  ];

  /// Why the right lug was sent for: the rule, and — only when the player
  /// has seen it ([flawKnown]) — what the cable's own-size lug had.
  static List<String> holdRight(LugRoundDeal r, {required bool flawKnown}) {
    final f = r.twin?.flaw ?? LugFlaw.none;
    return [if (flawKnown && f != LugFlaw.none) flawWhy(f), ...holdSound];
  }

  /// The excuses, and (when the fault is known) the fault it did not have.
  static List<String> holdWrong(LugRoundDeal r, {required bool flawKnown}) {
    final f = r.twin?.flaw ?? LugFlaw.none;
    return [
      if (flawKnown && f != LugFlaw.none)
        for (final x in const [LugFlaw.crack, LugFlaw.dirt])
          if (x != f) flawWhy(x),
      ...holdExcuses,
    ];
  }

  /// The careless coworker: the shortcuts the lesson warns of.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerBigger = CoworkerScript(
    line: 'একটু বড় ল্যাগ, চেপে দিলেই হবে!',
    exitLine: coworkerExit,
    right: ['না — তারের মাপের ল্যাগই নেব', 'বড় ল্যাগ চাপলেও সংযোগ ঢিলা থাকে', 'মাপ না মিললে ক্রিম্প করব না'],
    wrong: [
      'ঠিক, বড়টাই চেপে বসিয়ে দিই',
      'একটু বড়তে কিছু হয় না, নিই',
      'জোরে চাপলেই তো টাইট হয়ে যাবে',
      'এবারটা বড় ল্যাগেই চালিয়ে নিই',
      'সবাই তো হাতের কাছেরটাই নেয়',
    ],
    asks: ['ও বলছে বড় ল্যাগ চেপে দিলেই হবে। কী করবেন?', 'বড় ল্যাগ নেবেন, না তারের মাপের?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerMetal = CoworkerScript(
    line: 'অ্যালুমিনিয়ামের তারে তামার ল্যাগই দাও, তামা তো ভালো!',
    exitLine: coworkerExit,
    right: ['না — অ্যালুমিনিয়ামে অ্যালুমিনিয়াম', 'দুই ধাতু মেশালে গ্যালভানিক ক্ষয় হয়', 'ধাতু না মিললে ল্যাগ নেব না, ভাই'],
    wrong: [
      'ঠিক, তামার ল্যাগটাই লাগিয়ে দিই',
      'তামা তো ভালো, ওটাই নিয়ে নিই',
      'ধাতুতে কিছু আসে যায় না, নিয়ে নিই',
      'এবারটা তামাতেই চালিয়ে নিই, ভাই',
      'সবাই তো যেটা পায় সেটাই নেয়',
    ],
    asks: ['ও বলছে তামার ল্যাগই ভালো। কী করবেন?', 'তামার ল্যাগ নেবেন, না তারের ধাতুর?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(LugPush p) => p == LugPush.bigger ? coworkerBigger : coworkerMetal;

  /// His new lines (device TTS until recorded in his voice).
  static const newRivalLines = [
    'একটু বড় ল্যাগ, চেপে দিলেই হবে!',
    'অ্যালুমিনিয়ামের তারে তামার ল্যাগই দাও, তামা তো ভালো!',
  ];

  static const callHeld = 'ঠিক! তারের মাপ আর ধাতু মিলিয়েই ল্যাগ।';
  static const asideFlaw = 'ঠিক — খারাপ ল্যাগ বাদ।';
  static const stripRight = 'ঠিক মাপে ছিলেছেন — কন্ডাক্টর পুরো ভেতরে, ইনসুলেশন বাইরে।';
  static const allSet = 'ল্যাগ বাছাইয়ে পাকা হাত! মাপ, ধাতু আর অবস্থা — সবই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — তারের গায়ের লেখা আর ল্যাগের ছাপ মিলিয়ে দেখুন।';
  static const caughtMatch = 'তারের মাপ আর ধাতু মিলিয়ে ল্যাগ';
  static const caughtFlaw = 'খারাপ ল্যাগ বাদ দিয়েছেন';
  static const caughtStrip = 'ব্যারেলের মাপে ছিলেছেন';
  static const caughtHold = 'ঠিক ল্যাগ না পেয়ে স্টোরে';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class LugMistakes {
  static const _match = 'assets/game/art/m2_lug_pick/lug_match.svg';
  static const _flaws = 'assets/game/art/m2_lug_pick/lug_flaws.svg';
  static const _strip = 'assets/game/art/m2_lug_pick/strip_length.svg';

  static const wrongMetal = DoMistake(
    key: '2.3/lug/wrong-metal',
    textBn: 'অ্যালুমিনিয়ামের তারে অ্যালুমিনিয়ামের ল্যাগ, তামার তারে তামার ল্যাগ — দুই ভিন্ন ধাতু একসাথে হলে গ্যালভানিক করোশন হয়।',
    art: _match,
    lessonPoint: 1,
  );
  static const wrongSize = DoMistake(
    key: '2.3/lug/wrong-size',
    textBn: 'ভুল সাইজের ল্যাগে ক্রিম্প ঢিলা হয় — লুজ কানেকশন গরম হয়ে ফল্ট ঘটায়। তার যত sq mm, ল্যাগও ঠিক তত।',
    art: _match,
    lessonPoint: 1,
  );
  static const crack = DoMistake(
    key: '2.3/lug/cracked',
    textBn: 'ব্যারেলে ফাটল — এমন ল্যাগে সংযোগ মজবুত হয় না। ভালো ল্যাগের গায়ে কোনো ফাটল থাকে না। ফাটা ল্যাগ বাদ।',
    art: _flaws,
    lessonPoint: 3,
  );
  static const dirt = DoMistake(
    key: '2.3/lug/dirty',
    textBn: 'ল্যাগের ভেতরে তেল-ময়লা — রেজিস্ট্যান্স বেড়ে যায়, সংযোগ গরম হয়। ক্রিম্পের আগে ভেতরটা পরিষ্কার চাই।',
    art: _flaws,
    lessonPoint: 2,
  );
  static const heldWhenRight = DoMistake(
    key: '2.3/lug/held-when-right',
    textBn: 'মাপ আর ধাতু মেলানো ভালো ল্যাগটা ট্রেতেই ছিল — ল্যাগের গায়ের ছাপ ভালো করে দেখুন।',
    art: _match,
    lessonPoint: 1,
  );
  static const stripShort = DoMistake(
    key: '2.3/lug/strip-short',
    textBn: 'কম ছিলেছেন — কন্ডাক্টর ব্যারেলের শেষ পর্যন্ত ঢোকেনি, ইনসুলেশন ব্যারেলে ঠেকে গেছে। ল্যাগ পাশে রেখে ব্যারেলের মাপে ছিলুন।',
    art: _strip,
    lessonPoint: 2,
  );
  static const stripLong = DoMistake(
    key: '2.3/lug/strip-long',
    textBn: 'বেশি ছিলেছেন — খোলা কন্ডাক্টর ব্যারেলের বাইরে থেকে গেল। কন্ডাক্টর পুরো ভেতরে, ইনসুলেশন ঠিক ব্যারেলের মুখে।',
    art: _strip,
    lessonPoint: 2,
  );
  static const all = [wrongMetal, wrongSize, crack, dirt, heldWhenRight, stripShort, stripLong];
}

/// How far off the barrel's depth a strip may be (a share of the depth).
const kStripTolerance = 0.15;

/// A fresh tray each play: cables, decoys, flaws, tray order and the
/// coworker's moment vary.
LugDeal dealLugs(math.Random rng) {
  var n = 0;
  LugItem lug(LugMetal m, int size, [LugFlaw f = LugFlaw.none]) => LugItem(id: 'lug${n++}', metal: m, size: size, flaw: f);
  T pick<T>(List<T> xs) => xs[rng.nextInt(xs.length)];

  // 1: easy — a copper cable; the right lug, one size up, the aluminium one.
  final s1 = pick(const [10, 16, 25]);
  final c1 = LugCable(metal: LugMetal.cu, size: s1);
  final r1 = [lug(LugMetal.cu, s1), lug(LugMetal.cu, lugSizeAbove(s1)), lug(LugMetal.al, s1)]..shuffle(rng);
  // 2: an aluminium cable — the right lug, a faulty twin, one size up, copper.
  final s2 = pick(const [25, 35, 50, 70]);
  final c2 = LugCable(metal: LugMetal.al, size: s2);
  final r2 = [
    lug(LugMetal.al, s2),
    lug(LugMetal.al, s2, rng.nextBool() ? LugFlaw.crack : LugFlaw.dirt),
    lug(LugMetal.al, lugSizeAbove(s2)),
    lug(LugMetal.cu, s2),
  ]..shuffle(rng);
  // 3: nothing fits — the own-size lug is cracked; one size up; the other metal.
  final m3 = rng.nextBool() ? LugMetal.al : LugMetal.cu;
  final s3 = pick(const [16, 25, 35, 50]);
  final c3 = LugCable(metal: m3, size: s3);
  final r3 = [lug(m3, s3, LugFlaw.crack), lug(m3, lugSizeAbove(s3)), lug(m3.other, s3)]..shuffle(rng);
  final rounds = [
    LugRoundDeal(cable: c1, lugs: r1),
    LugRoundDeal(cable: c2, lugs: r2),
    LugRoundDeal(cable: c3, lugs: r3),
  ];
  final call = rng.nextInt(rounds.length);
  return LugDeal(rounds: rounds, callRound: call, callMetal: rounds[call].cable.metal == LugMetal.al && rng.nextBool());
}

/// The lug the coworker would push on cable [r] now (still in the tray), or null.
LugItem? lugPushed(LugRoundDeal r, Set<String> gone, LugPush p) {
  for (final l in r.lugs) {
    if (gone.contains(l.id)) continue;
    if (p == LugPush.bigger && l.metal == r.cable.metal && l.size > r.cable.size) return l;
    if (p == LugPush.metal && r.cable.metal == LugMetal.al && l.metal == LugMetal.cu) return l;
  }
  return null;
}

/// What the coworker can push on cable [r] now: the dealt push first
/// ([preferMetal]), else the other; null when neither lug is in the tray.
LugPush? lugPushFor(LugRoundDeal r, Set<String> gone, {required bool preferMetal}) {
  final metal = lugPushed(r, gone, LugPush.metal) != null;
  final bigger = lugPushed(r, gone, LugPush.bigger) != null;
  if (preferMetal && metal) return LugPush.metal;
  if (bigger) return LugPush.bigger;
  return metal ? LugPush.metal : null;
}

enum LugVerdict { right, slip }

@immutable
class LugOutcome {
  const LugOutcome(this.verdict, {this.mistake});
  final LugVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class LugRun {
  LugRun(this.deal);
  final LugDeal deal;
  int round = 0;
  int slips = 0;

  /// The right lug, taken: the strip comes next.
  LugItem? fitted;

  /// This cable is decided (stripped right, or sent to the store): the
  /// reason comes, then [next].
  bool shown = false;

  /// Lugs set aside on this cable (wrong ones taken by mistake, or put aside).
  final Set<String> rejected = {};

  /// Lugs on this cable whose fault the player has seen (found by hand, or
  /// shown on the card after taking it).
  final Set<String> spotted = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done;
  LugRoundDeal get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  /// The right lug is in hand and the cable is not stripped yet.
  bool get stripping => fitted != null && !shown;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  LugOutcome _slip(DoMistake m, LugItem l) {
    slips++;
    rejected.add(l.id);
    return LugOutcome(LugVerdict.slip, mistake: m);
  }

  /// Takes [l] for the cable.
  LugOutcome take(LugItem l) {
    if (ended || shown || stripping || rejected.contains(l.id)) return const LugOutcome(LugVerdict.slip);
    final c = current.cable;
    if (l.metal != c.metal) return _slip(LugMistakes.wrongMetal, l);
    if (l.size != c.size) return _slip(LugMistakes.wrongSize, l);
    if (l.flaw != LugFlaw.none) {
      spotted.add(l.id);
      return _slip(l.flaw == LugFlaw.crack ? LugMistakes.crack : LugMistakes.dirt, l);
    }
    fitted = l;
    _tag(LugLines.caughtMatch);
    return const LugOutcome(LugVerdict.right);
  }

  /// The player's hand or eye found [l]'s fault in the close look.
  void spot(LugItem l) {
    if (l.flaw != LugFlaw.none) spotted.add(l.id);
  }

  /// The own-size lug of this cable is faulty, and the player has seen how.
  bool get flawKnown {
    final t = current.twin;
    return t != null && spotted.contains(t.id);
  }

  /// Puts [l] back: a faulty lug whose fault the player found goes aside
  /// (true); anything else back in the tray (false) — putting back never
  /// tells which lugs are faulty. Never costs anything.
  bool putBack(LugItem l) {
    if (ended || shown || stripping || rejected.contains(l.id)) return false;
    if (!spotted.contains(l.id)) return false;
    rejected.add(l.id);
    _tag(LugLines.caughtFlaw);
    return true;
  }

  /// Strips the cable by [u] barrel depths (1 = exactly the barrel's depth).
  LugOutcome strip(double u) {
    if (!stripping) return const LugOutcome(LugVerdict.slip);
    if (u < 1 - kStripTolerance) {
      slips++;
      return const LugOutcome(LugVerdict.slip, mistake: LugMistakes.stripShort);
    }
    if (u > 1 + kStripTolerance) {
      slips++;
      return const LugOutcome(LugVerdict.slip, mistake: LugMistakes.stripLong);
    }
    shown = true;
    _tag(LugLines.caughtStrip);
    return const LugOutcome(LugVerdict.right);
  }

  /// "ঠিক ল্যাগ নেই — স্টোর থেকে আনাই".
  LugOutcome holdJob() {
    if (ended || shown || stripping) return const LugOutcome(LugVerdict.slip);
    if (!current.noneFits) {
      slips++;
      return const LugOutcome(LugVerdict.slip, mistake: LugMistakes.heldWhenRight);
    }
    _tag(LugLines.caughtHold);
    shown = true;
    return const LugOutcome(LugVerdict.right);
  }

  /// The next cable (after the reason).
  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    fitted = null;
    shown = false;
  }
}

@immutable
class M2LugPickPack {
  const M2LugPickPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2LugPickPack23 = M2LugPickPack(id: 'do_2_3_a', titleBn: LugLines.title);
const Map<String, M2LugPickPack> m2LugPickPacks = {'do_2_3_a': m2LugPickPack23};

// ============================================================================
// Page
// ============================================================================

class M2LugPickPage extends StatefulWidget {
  const M2LugPickPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2LugPickPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2LugPickPage> createState() => _M2LugPickPageState();
}

class _M2LugPickPageState extends State<M2LugPickPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _LugRunPage(
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

class _LugRunPage extends ConsumerStatefulWidget {
  const _LugRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2LugPickPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_LugRunPage> createState() => _LugRunPageState();
}

class _LugRunPageState extends ConsumerState<_LugRunPage> with DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final LugRun _run = LugRun(dealLugs(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The lug in the trainee's hands (the close look).
  LugItem? _held;
  var _cableOpen = false;
  DoMistake? _card;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  LugPush _push = LugPush.bigger;

  /// A fresh strip bench after a wrong strip (the end is cut back and tried again).
  int _stripTry = 0;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice (never holds the player) -------------------------------------------

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

  String get _task => _run.stripping ? LugLines.stripAsk : (_held != null ? LugLines.inspectAsk : LugLines.ask);

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([LugLines.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || _run.shown || _run.stripping;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// A lug comes out of the tray into the trainee's hands.
  void _pick(LugItem l, Offset origin) {
    // Taking another lug while he is still talking refuses him too.
    if (coworkerOpen && !coworkerChoiceUp && lugPushed(_run.current, _run.rejected, _push)?.id != l.id) {
      unawaited(answerCoworker(true, origin, direct: true));
    }
    if (_blocked || coworkerOpen || _held != null || _cableOpen || _run.rejected.contains(l.id)) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.5, muted: false));
    _hush();
    setState(() {
      _held = l;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([LugLines.inspectAsk]));
  }

  /// A fault came into view under the hand or the eye.
  void _found() {
    final l = _held;
    if (l != null) _run.spot(l);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.6, muted: false));
  }

  void _putBack() {
    final l = _held;
    if (l == null || _blocked) return;
    final aside = _run.putBack(l);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([LugLines.asideFlaw, LugLines.ask], mood: GuideMood.glad));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
      unawaited(_sayChain([LugLines.ask]));
    }
  }

  void _take(Offset origin) {
    final l = _held;
    if (l == null || _blocked) return;
    setState(() => _held = null);
    _judgeTake(l, origin);
  }

  void _judgeTake(LugItem l, Offset origin) {
    final o = _run.take(l);
    if (o.verdict == LugVerdict.right) {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.hold));
      unawaited(_sayChain([LugLines.stripAsk]));
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  /// The knife went through at [u] barrel depths; the lug has been pushed on.
  void _cut(double u, Offset origin) {
    if (!_run.stripping || _ended) return;
    final o = _run.strip(u);
    if (o.verdict == LugVerdict.right) {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
      final metal = _run.current.cable.metal;
      _ask(15, () => dealChoices(LugLines.packRight(metal), LugLines.packWrong(metal), widget.rng), LugLines.packAsk, lead: LugLines.stripRight);
      return;
    }
    setState(() {
      _stripTry++;
      _setMode(LinemanMode.worried);
    });
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  void _holdJob(Offset origin) {
    if (_blocked || coworkerOpen || _held != null || _cableOpen) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == LugVerdict.right) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      final r = _run.current;
      final known = _run.flawKnown;
      _ask(20, () => dealChoices(LugLines.holdRight(r, flawKnown: known), LugLines.holdWrong(r, flawKnown: known), widget.rng), LugLines.holdAsk);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  /// A right move: the ◆ wait on the table, then "কেন …?".
  void _ask(int points, List<ChoiceOption> Function() deal, String question, {String? lead}) {
    putOnTable(points);
    final round = _run.round;
    unawaited(() async {
      if (lead != null) {
        await _sayChain([lead], mood: GuideMood.glad);
        if (!mounted || _run.round != round || _ended) return;
      }
      await askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended);
    }());
  }

  /// The next cable (or the result) — by itself, after the reason.
  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _stripTry = 0;
      _setMode(LinemanMode.idle);
    });
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([LugLines.ask]));
  }

  void _openCable() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: false));
    setState(() => _cableOpen = true);
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
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => LugLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    if (_blocked || _held != null || _cableOpen) return false;
    final push = lugPushFor(_run.current, _run.rejected, preferMetal: _run.deal.callMetal);
    if (push == null) return false;
    _push = push;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Took what he pushed: the bigger lug, or copper on aluminium.
      final l = lugPushed(_run.current, _run.rejected, _push);
      if (l != null) _judgeTake(l, origin);
      return;
    }
    _run.caught.add(LugLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([LugLines.callHeld, LugLines.ask], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? LugLines.tapWhy[_nudgeN++ % LugLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes ---------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() => _card = m);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('lug/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _setMode(_run.stripping ? LinemanMode.hold : LinemanMode.idle);
    });
    unawaited(_sayChain([_task]));
  }

  // ---- score and result ---------------------------------------------------------------

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
    _busy = true;
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
    await _say(!_run.passed ? LugLines.fail : (_quickBonus ? LugLines.quick : LugLines.allSet),
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

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = LugBenchGeo(m.height);
    final r = _run.current;
    final aside = [for (final x in r.lugs) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_cableOpen;
    final al = r.cable.metal == LugMetal.al;
    final fitted = _run.fitted;
    return [
      Positioned.fill(
        key: const ValueKey('wall'),
        child: RepaintBoundary(child: CustomPaint(painter: LugWallPainter(geo))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: ValueKey('bench-$al'),
        child: RepaintBoundary(child: CustomPaint(painter: LugBenchPainter(geo, al: al))),
      ),
      // The cable's sheath print (tap the cable to read it close).
      Positioned.fromRect(
        key: ValueKey('print-${_run.round}'),
        rect: geo.cableTap,
        child: _CableTap(cable: r.cable, printRect: geo.print.shift(-geo.cableTap.topLeft), onTap: _openCable),
      ),
      if (fitted != null && _run.shown)
        Positioned.fromRect(
          key: ValueKey('fitted-${fitted.id}'),
          rect: geo.fitted,
          child: CustomPaint(painter: LugSidePainter(al: fitted.metal == LugMetal.al)),
        ),
      for (var i = 0; i < r.lugs.length; i++)
        Positioned.fromRect(
          key: ValueKey('slot-${_run.round}-$i'),
          rect: geo.slot(i, r.lugs.length),
          child: DoDealIn(
            index: i,
            quiet: quiet,
            muted: true,
            child: _TrayLug(
              lug: r.lugs[i],
              gone: _run.rejected.contains(r.lugs[i].id) || _held?.id == r.lugs[i].id || fitted?.id == r.lugs[i].id,
              enabled: canPick,
              onTake: (at) => _pick(r.lugs[i], at),
            ),
          ),
        ),
      for (var i = 0; i < aside.length && i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: _AsideLug(lug: aside[i], quiet: quiet),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final holdUp = playing && _held == null && !_cableOpen && _card == null && !deckUp && !_run.shown && !_run.stripping && !coworkerOpen;
    final held = _held;
    final fitted = _run.fitted;
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
              labels: LugLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (holdUp)
                Positioned(
                  key: const ValueKey('hud-hold'),
                  left: 12,
                  right: 128,
                  bottom: pad.bottom + 18,
                  child: _HoldButton(onTapUp: (d) => _holdJob(d.globalPosition)),
                ),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  lug: held,
                  cable: _run.current.cable,
                  quiet: quiet,
                  onFound: _found,
                  onTake: _take,
                  onPutBack: _putBack,
                ),
              if (fitted != null && _run.stripping && playing && _card == null)
                _StripBench(
                  key: ValueKey('strip-${_run.round}-$_stripTry'),
                  lug: fitted,
                  cable: _run.current.cable,
                  start: (_run.round + _stripTry).isEven ? 0.45 : 1.8,
                  quiet: quiet,
                  onCut: _cut,
                ),
              if (_cableOpen && playing)
                _CableZoom(
                  key: const ValueKey('cable-zoom'),
                  cable: _run.current.cable,
                  quiet: quiet,
                  onClose: () => setState(() => _cableOpen = false),
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
              if (playing && _card == null && !_cableOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: LugLines.intro,
                  alarm: 'sounds/intro/impact_metal.ogg',
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _bench = Color(0xFF26303B);

/// The cable's run right of the vice: its sheath print, small; tap to read it close.
class _CableTap extends StatelessWidget {
  const _CableTap({required this.cable, required this.printRect, required this.onTap});
  final LugCable cable;
  final Rect printRect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LugLines.cableLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: printRect,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(cable.print,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFE8E8E2), letterSpacing: 0.4, height: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The cable's print held up close (tap anywhere to put it back).
class _CableZoom extends StatelessWidget {
  const _CableZoom({super.key, required this.cable, required this.quiet, required this.onClose});
  final LugCable cable;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                width: 300,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The sheath, big, with its print.
                    Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF454A51), Color(0xFF17191C), Color(0xFF2C2F33)],
                        ),
                      ),
                      child: Text(cable.print,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFF2F2EC), letterSpacing: 1)),
                    ),
                    const SizedBox(height: 10),
                    Text(LugLines.cableBn(cable), style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A lug lying in its tray compartment, palm up. At this distance its stamp
/// cannot be read and its faults do not show. Tap it to take it in hand.
class _TrayLug extends StatelessWidget {
  const _TrayLug({required this.lug, required this.gone, required this.enabled, required this.onTake});
  final LugItem lug;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  Widget build(BuildContext context) {
    if (gone) return Semantics(label: LugLines.lugLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: LugLines.lugLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTake(d.globalPosition) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: RotatedBox(
            quarterTurns: 3,
            child: CustomPaint(painter: LugSidePainter(al: lug.metal == LugMetal.al, crack: lug.flaw == LugFlaw.crack, seenBarrel: const {})),
          ),
        ),
      ),
    );
  }
}

/// A lug set aside at the bench's front, tagged বাদ.
class _AsideLug extends StatelessWidget {
  const _AsideLug({required this.lug, required this.quiet});
  final LugItem lug;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, -20 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RotatedBox(quarterTurns: 3, child: CustomPaint(painter: LugSidePainter(al: lug.metal == LugMetal.al, crack: lug.flaw == LugFlaw.crack))),
          ),
          Positioned(
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
              child: Text(LugLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// "ঠিক ল্যাগ নেই — স্টোর থেকে আনাই".
class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1A33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.85), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(LugLines.hold,
                    textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The cable's print as a pill, for the close-up cards.
class _CablePill extends StatelessWidget {
  const _CablePill({required this.cable});
  final LugCable cable;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
        decoration: BoxDecoration(color: const Color(0xFF1E2126), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${LugLines.cableWord} ', style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFB9BEC4))),
            Text(cable.print, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFF2F2EC), letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}

/// The close look, hands on: the lug held up big, its stamp readable; run a
/// finger along the barrel (a crack shows only where the hand has been), look
/// into its mouth (oil and grime). Then take it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.lug,
    required this.cable,
    required this.quiet,
    required this.onFound,
    required this.onTake,
    required this.onPutBack,
  });
  final LugItem lug;
  final LugCable cable;
  final bool quiet;
  final VoidCallback onFound;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _barrel = {};
  var _mouth = false;
  Offset? _hand;
  var _found = false;

  void _check() {
    final l = widget.lug;
    final seen = switch (l.flaw) {
      LugFlaw.none => false,
      LugFlaw.crack => LugSidePainter.crackSeen(_barrel),
      LugFlaw.dirt => _mouth,
    };
    if (!_found && seen) {
      _found = true;
      widget.onFound();
    }
  }

  void _touch(Offset p, Size s) {
    final b = lugBin(LugSidePainter.barrelU(s, p.dx));
    final before = _barrel.length;
    if (p.dx <= LugSidePainter.barrelX1(s) + 6) {
      for (final x in [b - 1, b, b + 1]) {
        if (x >= 0 && x < kLugBins) _barrel.add(x);
      }
    }
    final grew = _barrel.length != before;
    _check();
    if (grew || _hand != p) setState(() => _hand = p);
  }

  void _lookIn() {
    if (_mouth) return;
    HapticFeedback.selectionClick();
    setState(() => _mouth = true);
    _check();
  }

  Widget _side(LugItem lug) => LayoutBuilder(
        builder: (context, box) {
          final s = Size(box.maxWidth, box.maxHeight);
          final al = lug.metal == LugMetal.al;
          return Semantics(
            label: LugLines.handLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _touch(d.localPosition, s),
              onPanUpdate: (d) => _touch(d.localPosition, s),
              onPanEnd: (_) => setState(() => _hand = null),
              onPanCancel: () => setState(() => _hand = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: LugSidePainter(al: al, crack: lug.flaw == LugFlaw.crack, seenBarrel: _barrel, veil: _bench)),
                  ),
                  // The stamp on the palm.
                  Positioned(
                    left: s.width * 0.69,
                    top: s.height * 0.5 - 11,
                    width: s.width * 0.14,
                    height: 22,
                    child: FittedBox(
                      child: Text(lug.stamp,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: metalDark(al).withValues(alpha: 0.95), height: 1)),
                    ),
                  ),
                  if (_barrel.isEmpty) _Puck(at: Offset(s.width * 0.1, s.height * 0.5)),
                  if (_hand != null) _Puck(at: _hand!, live: true),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final lug = widget.lug;
    final al = lug.metal == LugMetal.al;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.translate(
              offset: Offset(0, 80 * (1 - t)),
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CablePill(cable: widget.cable),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 2.3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF3A4654), _bench],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                        child: Row(
                          children: [
                            // Look into the mouth.
                            AspectRatio(
                              aspectRatio: 1,
                              child: Semantics(
                                button: true,
                                label: LugLines.mouthLabel,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) => _lookIn(),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(child: CustomPaint(painter: LugMouthPainter(al: al, dirt: lug.flaw == LugFlaw.dirt, seen: _mouth))),
                                      if (!_mouth)
                                        const Center(child: Icon(Icons.visibility_rounded, color: Color(0xFFFF851B), size: 26)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _side(lug)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: DoBigButton(label: LugLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                      const SizedBox(width: 12),
                      Expanded(child: DoBigButton(label: LugLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A gloved hand's mark: where to slide (still), or under the finger.
class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 20.0 : 15.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}

/// The strip: the lug laid beside the cable's end, its barrel's bottom over
/// the end; drag the knife along the insulation to where the barrel's mouth
/// is, then strip — the insulation comes off to the knife and the lug is
/// pushed on: the right length fills the barrel with the insulation at its
/// mouth; too short leaves the barrel's bottom empty; too long leaves bare
/// strands outside.
class _StripBench extends StatefulWidget {
  const _StripBench({super.key, required this.lug, required this.cable, required this.start, required this.quiet, required this.onCut});
  final LugItem lug;
  final LugCable cable;

  /// Where the knife starts, in barrel depths.
  final double start;
  final bool quiet;
  final void Function(double u, Offset origin) onCut;

  @override
  State<_StripBench> createState() => _StripBenchState();
}

class _StripBenchState extends State<_StripBench> {
  late double _u = widget.start;
  double? _cut;
  double _maxU = 3;

  Future<void> _strip(Offset origin) async {
    if (_cut != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _cut = _u);
    await Future<void>.delayed(Duration(milliseconds: widget.quiet ? 250 : 1300));
    if (!mounted) return;
    widget.onCut(_u, origin);
  }

  @override
  Widget build(BuildContext context) {
    final al = widget.cable.metal == LugMetal.al;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.translate(offset: Offset(0, 80 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CablePill(cable: widget.cable),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 1.9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFB08A5C), Color(0xFF8E6A40)],
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final s = Size(box.maxWidth, box.maxHeight);
                          final g = LugStripGeo(s, widget.lug.size);
                          _maxU = g.maxU;
                          final cut = _cut;
                          final lugAl = widget.lug.metal == LugMetal.al;
                          final from = g.lugRect(g.cableEnd - g.depth, g.lugY);
                          final to = cut == null ? from : g.lugRect(g.cableEnd - g.depth * math.min(cut, 1.0), g.cableY);
                          return Semantics(
                            label: LugLines.stripLabel,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              dragStartBehavior: DragStartBehavior.down,
                              onHorizontalDragUpdate: cut != null
                                  ? null
                                  : (d) => setState(() => _u = (_u - d.delta.dx / g.depth).clamp(0.15, _maxU)),
                              child: Stack(
                                children: [
                                  Positioned.fill(child: CustomPaint(painter: LugStripPainter(geo: g, al: al, knife: _u, cut: cut))),
                                  TweenAnimationBuilder<Rect?>(
                                    key: ValueKey(cut == null),
                                    tween: RectTween(begin: from, end: to),
                                    duration: Duration(milliseconds: cut == null || widget.quiet ? 0 : 900),
                                    curve: Curves.easeInOut,
                                    builder: (_, r, _) => Positioned.fromRect(
                                      rect: r ?? to,
                                      child: CustomPaint(painter: LugSidePainter(al: lugAl, glass: cut != null)),
                                    ),
                                  ),
                                  if (cut != null)
                                    Positioned.fill(
                                      child: IgnorePointer(child: CustomPaint(painter: LugStripPainter(geo: g, al: al, knife: _u, cut: cut, outline: true))),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DoBigButton(label: LugLines.strip, filled: true, onTapUp: (d) => unawaited(_strip(d.globalPosition))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
