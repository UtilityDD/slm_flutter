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
import 'm3_fuse_rating_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 3.4, কাজ 1: "সঠিক ফিউজ তার". At the line van under a DTR on the
// docket: the DO fuse barrels are down at the van (shutdown done), and new
// fuse links must go in. Read the transformer's plate (its fuse rating is
// readable only up close — lesson: "ট্রান্সফরমারের গায়ে বা পোলের ওপর একটি
// প্লেটে লেখা থাকে যে কত অ্যাম্পিয়ারের ফিউজ"), pick the reel whose tag
// matches it (the lesson's own figures, 10A and 25A), then at the barrel wipe
// the soot off the top and bottom contacts and pull the link to the right
// tension before tying it (lesson pro tips 3 and 4). Three DTRs, a fresh
// deal each play. Once a play the careless coworker (level 1's rival) peeps
// in: "মোটা তার জুড়ে দাও, বারবার উড়বে না!" — the lesson's myth.
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" → next DTR by itself.
//
// Deadly: a thick copper wire in the barrel (taken from the van, or on his
// word) — the lesson calls it "আত্মহত্যার সামিল": the fuse can never blow,
// and the transformer or the whole line can burn ("পুড়িয়ে দিতে পারে").
// Listening to him stays deadly because the act he pushes is on Module 3's
// deadly list (MODULE3_LADDER.md row 11). A wrong rating, plain GI wire, a
// sooty contact or a slack tie is a slip; 3 slips fail.
// He cannot be skipped by a fast play: taking a reel waits for him
// (holdForCoworker). Gesture hints: a sweep over the plate and the reels, over
// put back / take, over the barrel's contacts, tail and tie; a tap to put the
// plate down.
//
// Voice: the guide's lines on device TTS; the coworker's push is new (device
// TTS in his voice settings until recorded); his exit line is recorded.
// Art: the scene, the reels and the barrel are drawn in code
// (m3_fuse_rating_world.dart); the mistake cards use assets/game/art/m3_fuse_rating/.

// ============================================================================
// Content
// ============================================================================

/// What the van carries.
enum M3FuseRatingKind { link, copper, plain }

/// The fuse ratings on the plates and the link tags (the lesson's examples).
const kM3FuseRatingAmps = [10, 25];

/// A barrel's two contacts.
enum M3FuseRatingSpot { top, bottom }

/// How taut the link must be pulled before it is tied (0 slack … 1 taut).
const kM3FuseRatingTaut = 0.8;

@immutable
class M3FuseRatingReel {
  const M3FuseRatingReel({required this.id, required this.kind, this.amps = 0});
  final String id;
  final M3FuseRatingKind kind;

  /// A link's rating (0 for plain wire).
  final int amps;

  /// The tag a worker reads (links only).
  String get tag => kind == M3FuseRatingKind.link ? 'FUSE LINK ${enDigits('$amps')}A' : '';

  M3FuseRatingWire get wire => switch (kind) {
        M3FuseRatingKind.link => M3FuseRatingWire.link,
        M3FuseRatingKind.copper => M3FuseRatingWire.copper,
        M3FuseRatingKind.plain => M3FuseRatingWire.plain,
      };
}

/// Which reason the DTR asks for after its barrel is ready.
enum M3FuseRatingAsk { rating, contacts, tie }

@immutable
class M3FuseRatingRound {
  const M3FuseRatingRound({required this.amps, required this.reels, required this.dirty, required this.ask});

  /// The fuse rating on this DTR's plate.
  final int amps;
  final List<M3FuseRatingReel> reels;

  /// The barrel's sooty contacts.
  final Set<M3FuseRatingSpot> dirty;
  final M3FuseRatingAsk ask;

  bool fits(M3FuseRatingReel r) => r.kind == M3FuseRatingKind.link && r.amps == amps;
  M3FuseRatingReel get right => reels.firstWhere(fits);
  M3FuseRatingReel get copper => reels.firstWhere((r) => r.kind == M3FuseRatingKind.copper);
}

@immutable
class M3FuseRatingDeal {
  const M3FuseRatingDeal({required this.rounds, required this.callRound});
  final List<M3FuseRatingRound> rounds;

  /// The DTR on which the coworker peeps in (or a later one, if that one was
  /// done before he could).
  final int callRound;
}

abstract final class M3FuseRatingLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask, lookAsk, barrelAsk];

  static const title = 'সঠিক ফিউজ তার';
  static const intro = 'ডকেটের তিন ডিটিআর-এ নতুন ফিউজ চাই! প্লেট দেখে সঠিক ফিউজ তার বাছুন।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const ask = 'ট্রান্সফরমারের প্লেট দেখুন। কোন ফিউজ তার?';
  static const lookAsk = 'গায়ের লেখাটা পড়ুন। এটা নেবেন?';
  static const barrelAsk = 'ওপর-নিচের কন্টাক্ট দেখুন, তারপর লিঙ্ক টেনে বাঁধুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static String plateAmps(int a) => '${enDigits('$a')} A';
  static const plateHead = 'DO FUSE LINK';
  static String plateBn(int a) => 'ডিও ফিউজ লিঙ্ক · ${enDigits('$a')} অ্যাম্পিয়ার';
  static String reelBn(M3FuseRatingReel r) => switch (r.kind) {
        M3FuseRatingKind.link => 'ফিউজ লিঙ্ক · ${enDigits('${r.amps}')} অ্যাম্পিয়ার',
        M3FuseRatingKind.copper => 'মোটা তামার তার',
        M3FuseRatingKind.plain => 'সাধারণ জিআই তার',
      };
  static const plateLabel = 'ট্রান্সফরমারের প্লেট';
  static const plateWord = 'প্লেট';
  static const reelLabel = 'ফিউজ তারের রিল';
  static const topLabel = 'ওপরের কন্টাক্ট';
  static const bottomLabel = 'নিচের কন্টাক্ট';
  static const tailLabel = 'লিঙ্কের লেজ';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const tie = 'বাঁধুন';
  static const rejected = 'বাদ';

  // The reasons (lesson 3.4). Every card is 35–43 letters.
  static const whyRating = 'কেন এই ফিউজ লিঙ্কটা নিলেন?';
  static const whyContacts = 'কেন কন্টাক্ট মুছে নিলেন?';
  static const whyTie = 'কেন লিঙ্কটা টেনে বাঁধলেন?';
  static String ratingMatch(int a) => 'প্লেটে লেখা ${enDigits('$a')}A, তাই লিঙ্কও ঠিক ${enDigits('$a')}A নিলাম';
  static const ratingSound = [
    'ট্রান্সফরমারের প্লেট দেখে রেটিং মিলিয়েছি',
    'রেটেড লিঙ্কই মাপা কারেন্টে নিশ্চিত গলে যায়',
  ];
  static const ratingMyths = [
    'মোটা তার দিলে ফিউজ আর বারবার উড়বে না',
    'যেকোনো ধাতব তারেই ফিউজের কাজ হয়ে যায়',
    'বেশি রেটিং দিলে ট্রান্সফরমার বেশি নিরাপদ',
    'হাতের কাছে যে রিলটা ছিল সেটাই তুলে নিলাম',
    'সরু হোক বা মোটা, ফিউজ তার তো একই জিনিস',
  ];
  static List<String> ratingRight(int a) => [ratingMatch(a), ...ratingSound];

  /// The other plate's match (true elsewhere, not here) and the myths.
  static List<String> ratingWrong(int a) => [
        for (final x in kM3FuseRatingAmps)
          if (x != a) ratingMatch(x),
        ...ratingMyths,
      ];
  // No giveaway word: every key word of a right card (see
  // [contactsKeys]/[tieKeys]) also sits on at least half the wrong cards,
  // and the question's own word (কন্টাক্ট, লিঙ্ক, বাঁধ) on all but one at
  // most, so a dealt hand of 1 right + 2 wrong never singles it out.
  static const contactsRight = [
    'কন্টাক্টে ময়লা-কার্বন থাকলে স্পার্কিং হয়',
    'ময়লা-কার্বনে স্পার্কিং হয়ে কন্টাক্ট নষ্ট',
  ];
  static const contactsWrong = [
    'ময়লা-কার্বনে কন্টাক্ট নষ্ট দেখায় বলে মুছি',
    'কার্বন মুছলে কন্টাক্টে স্পার্কিং দেখা যায়',
    'ময়লা-কার্বন থাকলে ব্যারেল কন্টাক্টে বসে না',
    'স্পার্কিংয়ের দাগে কন্টাক্ট নষ্ট দেখায়',
    'ময়লায় কন্টাক্টের স্পার্কিং চোখে পড়ে না',
    'মুছলে নষ্ট কন্টাক্টেও আর স্পার্কিং হয় না',
  ];
  static const contactsEcho = ['কন্টাক্ট'];
  static const contactsKeys = ['স্পার্কিং', 'ময়লা', 'কার্বন', 'নষ্ট'];
  static const tieRight = [
    'ঢিলা করে বাঁধা লিঙ্ক ঠিকমতো কাজ করে না',
    'সঠিক টানে বাঁধা লিঙ্কই ঠিকমতো কাজ করে',
  ];
  static const tieWrong = [
    'ঢিলা লিঙ্কও ঠিকমতো কাজ করে, দেখতে খারাপ',
    'ঢিলা লিঙ্কের রেটিং কমে, তাই সঠিক টানে বাঁধা',
    'সঠিক টানে বাঁধলে লিঙ্ক দ্বিগুণ লোডে কাজ করে',
    'ঢিলা নয়, টানটান বাঁধা লিঙ্ক কখনো গলে না',
    'সুপারভাইজার দেখবেন বলে লিঙ্ক ঠিকমতো বাঁধা',
    'সঠিক কাজ দেখাতে লিঙ্কটা ঠিকমতো বাঁধলাম',
  ];
  static const tieEcho = ['লিঙ্ক', 'বাঁধ'];
  static const tieKeys = ['ঠিকমতো', 'কাজ', 'ঢিলা', 'সঠিক', 'টান'];

  static String question(M3FuseRatingAsk a) => switch (a) {
        M3FuseRatingAsk.rating => whyRating,
        M3FuseRatingAsk.contacts => whyContacts,
        M3FuseRatingAsk.tie => whyTie,
      };
  static List<String> right(M3FuseRatingRound r) => switch (r.ask) {
        M3FuseRatingAsk.rating => ratingRight(r.amps),
        M3FuseRatingAsk.contacts => contactsRight,
        M3FuseRatingAsk.tie => tieRight,
      };
  static List<String> wrong(M3FuseRatingRound r) => switch (r.ask) {
        M3FuseRatingAsk.rating => ratingWrong(r.amps),
        M3FuseRatingAsk.contacts => contactsWrong,
        M3FuseRatingAsk.tie => tieWrong,
      };

  /// The careless coworker: the lesson's myth.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLine = 'মোটা তার জুড়ে দাও, বারবার উড়বে না!';
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: ['না — প্লেটের রেটিংয়ের লিঙ্কই দেব', 'বারবার উড়লে লাইনে ফল্ট, আগে খুঁজব', 'মোটা তারে ট্রান্সফরমার পুড়তে পারে'],
    wrong: [
      'ঠিক, মোটা তামার তারই জুড়ে দিই',
      'বারবার ওঠা-নামার চেয়ে মোটাই ভালো',
      'একবার মোটা দিলে আর ঝামেলা নেই',
      'এবারটা মোটা তারেই চালিয়ে নিই',
      'সবাই তো মোটা তারই জুড়ে দেয়',
    ],
    asks: ['ও বলছে মোটা তার জুড়ে দিতে। কী করবেন?', 'মোটা তার জুড়বেন, না প্লেটের রেটিং?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );

  /// His new lines (device TTS until recorded in his voice).
  static const newRivalLines = [coworkerLine];

  static const callHeld = 'ঠিক! প্লেটের রেটিংয়ের লিঙ্কই — মোটা তার কখনো নয়।';
  static const takeRight = 'ঠিক রিল! এবার ব্যারেল।';
  static const tieDone = 'ব্যারেল তৈরি — পরিষ্কার কন্টাক্ট, টানটান লিঙ্ক।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const allSet = 'তিন ডিটিআর-এই সঠিক ফিউজ! প্লেট, কন্টাক্ট আর টান — সব দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — প্লেটের লেখা আর রিলের ট্যাগ মিলিয়ে দেখুন।';
  static const caughtRating = 'প্লেট দেখে সঠিক রেটিংয়ের লিঙ্ক';
  static const caughtClean = 'কন্টাক্টের কার্বন মুছেছেন';
  static const caughtTie = 'লিঙ্ক সঠিক টানে বেঁধেছেন';
  static const caughtCall = 'মোটা তারে “না” বলেছেন';
}

abstract final class M3FuseRatingMistakes {
  static const _rating = 'assets/game/art/m3_fuse_rating/rating_match.svg';
  static const _bodge = 'assets/game/art/m3_fuse_rating/thick_wire.svg';
  static const _barrel = 'assets/game/art/m3_fuse_rating/barrel_care.svg';

  static const tooBig = DoMistake(
    key: '3.4/m3_fuse_rating/too-big',
    textBn: 'প্লেটের চেয়ে বেশি রেটিংয়ের মোটা লিঙ্ক ওভারলোডে উড়বে না — ট্রান্সফরমার পুড়ে যেতে পারে। প্লেটে যত অ্যাম্পিয়ার, লিঙ্কও তত।',
    art: _rating,
    lessonPoint: 3,
  );
  static const tooSmall = DoMistake(
    key: '3.4/m3_fuse_rating/too-small',
    textBn: 'প্লেটের চেয়ে কম রেটিংয়ের সরু লিঙ্ক স্বাভাবিক লোডেই বারবার উড়ে যাবে। প্লেট দেখে ঠিক অ্যাম্পিয়ারের লিঙ্ক নিন।',
    art: _rating,
    lessonPoint: 3,
  );
  static const plainWire = DoMistake(
    key: '3.4/m3_fuse_rating/plain-wire',
    textBn: 'সাধারণ তার ফিউজ লিঙ্ক নয় — সেটি কখন গলবে তার কোনো নিশ্চয়তা নেই। নির্দিষ্ট গলনাঙ্কের রেটেড ফিউজ লিঙ্কই চাই।',
    art: _rating,
    lessonPoint: 3,
  );
  static const thickCopper = DoMistake(
    key: '3.4/m3_fuse_rating/thick-copper',
    textBn: 'মোটা তামার তার জুড়লে ফিউজের সুরক্ষাই শেষ — ওভারলোড বা শর্ট সার্কিটে ফিউজ উড়বে না, ট্রান্সফরমার বা পুরো লাইন পুড়ে যেতে পারে। বারবার উড়লে আগে ফল্ট খুঁজুন।',
    art: _bodge,
    deadly: true,
    lessonPoint: 3,
  );
  static const dirtyContact = DoMistake(
    key: '3.4/m3_fuse_rating/dirty-contact',
    textBn: 'কন্টাক্টে ময়লা-কার্বন রেখেই বাঁধলেন — সেখানে স্পার্কিং হয়ে কন্টাক্ট নষ্ট হতে পারে। ওপর-নিচের কন্টাক্ট আগে পরিষ্কার করুন।',
    art: _barrel,
    lessonPoint: 1,
  );
  static const looseTie = DoMistake(
    key: '3.4/m3_fuse_rating/loose-tie',
    textBn: 'ঢিলা বাঁধা ফিউজ লিঙ্ক ঠিকমতো কাজ করে না। লিঙ্কের লেজ টেনে সঠিক টানে বেঁধে তবেই ব্যারেল তৈরি।',
    art: _barrel,
    lessonPoint: 1,
  );
  static List<DoMistake> get all => const [tooBig, tooSmall, plainWire, thickCopper, dirtyContact, looseTie];
}

/// A fresh docket each play: plates, tray order, sooty contacts and the
/// coworker's moment vary.
M3FuseRatingDeal m3FuseRatingDeal(math.Random rng) {
  var n = 0;
  List<M3FuseRatingReel> tray() => [
        for (final a in kM3FuseRatingAmps) M3FuseRatingReel(id: 'r${n++}', kind: M3FuseRatingKind.link, amps: a),
        M3FuseRatingReel(id: 'r${n++}', kind: M3FuseRatingKind.copper),
        M3FuseRatingReel(id: 'r${n++}', kind: M3FuseRatingKind.plain),
      ]..shuffle(rng);
  // The first two plates differ; the last is either.
  final amps = [...kM3FuseRatingAmps]..shuffle(rng);
  amps.add(kM3FuseRatingAmps[rng.nextInt(kM3FuseRatingAmps.length)]);
  const spots = M3FuseRatingSpot.values;
  final dirty2 = const [<M3FuseRatingSpot>{}, {M3FuseRatingSpot.top}, {M3FuseRatingSpot.bottom}, {M3FuseRatingSpot.top, M3FuseRatingSpot.bottom}][rng.nextInt(4)];
  final rounds = [
    M3FuseRatingRound(amps: amps[0], reels: tray(), dirty: const {}, ask: M3FuseRatingAsk.rating),
    M3FuseRatingRound(amps: amps[1], reels: tray(), dirty: {spots[rng.nextInt(2)]}, ask: M3FuseRatingAsk.contacts),
    M3FuseRatingRound(amps: amps[2], reels: tray(), dirty: dirty2, ask: M3FuseRatingAsk.tie),
  ];
  return M3FuseRatingDeal(rounds: rounds, callRound: rng.nextInt(rounds.length));
}

enum M3FuseRatingVerdict { right, slip, deadly }

@immutable
class M3FuseRatingOutcome {
  const M3FuseRatingOutcome(this.verdict, {this.mistake});
  final M3FuseRatingVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class M3FuseRatingRun {
  M3FuseRatingRun(this.deal);
  final M3FuseRatingDeal deal;
  int round = 0;
  int slips = 0;

  /// The right reel, taken: the barrel comes next.
  M3FuseRatingReel? fitted;

  /// This DTR's barrel is ready: the reason comes, then [next].
  bool shown = false;

  /// A deadly move ended the play.
  DoMistake? deadly;

  /// Reels set aside on this DTR (wrong ones taken by mistake).
  final Set<String> rejected = {};

  /// Contacts wiped clean on this DTR's barrel.
  final Set<M3FuseRatingSpot> wiped = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  M3FuseRatingRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The right reel is in hand and the barrel is not ready yet.
  bool get tying => fitted != null && !shown;

  /// The sooty contacts not wiped yet.
  Set<M3FuseRatingSpot> get dirtyLeft => current.dirty.difference(wiped);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  M3FuseRatingOutcome _slip(DoMistake m, M3FuseRatingReel r) {
    slips++;
    rejected.add(r.id);
    return M3FuseRatingOutcome(M3FuseRatingVerdict.slip, mistake: m);
  }

  /// Takes reel [r] for this DTR.
  M3FuseRatingOutcome take(M3FuseRatingReel r) {
    if (ended || shown || tying || rejected.contains(r.id)) return const M3FuseRatingOutcome(M3FuseRatingVerdict.slip);
    switch (r.kind) {
      case M3FuseRatingKind.copper:
        deadly = M3FuseRatingMistakes.thickCopper;
        return const M3FuseRatingOutcome(M3FuseRatingVerdict.deadly, mistake: M3FuseRatingMistakes.thickCopper);
      case M3FuseRatingKind.plain:
        return _slip(M3FuseRatingMistakes.plainWire, r);
      case M3FuseRatingKind.link:
        if (r.amps > current.amps) return _slip(M3FuseRatingMistakes.tooBig, r);
        if (r.amps < current.amps) return _slip(M3FuseRatingMistakes.tooSmall, r);
    }
    fitted = r;
    _tag(M3FuseRatingLines.caughtRating);
    return const M3FuseRatingOutcome(M3FuseRatingVerdict.right);
  }

  /// Contact [s] wiped clean (only a sooty one counts).
  void wipe(M3FuseRatingSpot s) {
    if (!tying || !current.dirty.contains(s)) return;
    wiped.add(s);
    _tag(M3FuseRatingLines.caughtClean);
  }

  /// Ties the link at [tension] (0 slack … 1 taut).
  M3FuseRatingOutcome tie(double tension) {
    if (!tying || ended) return const M3FuseRatingOutcome(M3FuseRatingVerdict.slip);
    if (dirtyLeft.isNotEmpty) {
      slips++;
      return const M3FuseRatingOutcome(M3FuseRatingVerdict.slip, mistake: M3FuseRatingMistakes.dirtyContact);
    }
    if (tension < kM3FuseRatingTaut) {
      slips++;
      return const M3FuseRatingOutcome(M3FuseRatingVerdict.slip, mistake: M3FuseRatingMistakes.looseTie);
    }
    shown = true;
    _tag(M3FuseRatingLines.caughtTie);
    return const M3FuseRatingOutcome(M3FuseRatingVerdict.right);
  }

  /// The next DTR (after the reason).
  void next() {
    round++;
    rejected.clear();
    wiped.clear();
    fitted = null;
    shown = false;
  }
}

@immutable
class M3FuseRatingPack {
  const M3FuseRatingPack({required this.id, required this.titleBn, this.quickMs = 120000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3FuseRatingPack34 = M3FuseRatingPack(id: 'do_3_4_a', titleBn: M3FuseRatingLines.title);
const Map<String, M3FuseRatingPack> m3FuseRatingPacks = {'do_3_4_a': m3FuseRatingPack34};

// ============================================================================
// Page
// ============================================================================

class M3FuseRatingPage extends StatefulWidget {
  const M3FuseRatingPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3FuseRatingPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3FuseRatingPage> createState() => _M3FuseRatingPageState();
}

class _M3FuseRatingPageState extends State<M3FuseRatingPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FuseRunPage(
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

class _FuseRunPage extends ConsumerStatefulWidget {
  const _FuseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3FuseRatingPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FuseRunPage> createState() => _FuseRunPageState();
}

class _FuseRunPageState extends ConsumerState<_FuseRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3FuseRatingRun _run = M3FuseRatingRun(m3FuseRatingDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The reel in the trainee's hands (the close look).
  M3FuseRatingReel? _held;
  var _plateOpen = false;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  /// A fresh barrel bench after a wrong tie (the link is undone and pulled again).
  int _tieTry = 0;

  var _freeze = false;
  Completer<void>? _frozen;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to touch, never what): the scene's design height (for
  // the reels' rects) and the close looks' controls.
  final _hints = IdleHintController();
  double? _sceneH;
  final _putBackKey = GlobalKey();
  final _takeKey = GlobalKey();
  final _plateCardKey = GlobalKey();
  final _topKey = GlobalKey();
  final _bottomKey = GlobalKey();
  final _tailKey = GlobalKey();
  final _tieKey = GlobalKey();

  @override
  LevelContext get deathCtx => widget.ctx;
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

  void _cue(String path, {double volume = 0.6}) {
    if (!_muted) unawaited(ZlFx.cue(path, volume: volume, muted: false));
  }

  String get _task => _run.tying ? M3FuseRatingLines.barrelAsk : (_held != null ? M3FuseRatingLines.lookAsk : M3FuseRatingLines.ask);

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([M3FuseRatingLines.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  /// No scene control works: intro, a card, the praise window or the reason
  /// deck ([tableBusy]), the barrel bench, the freeze or the end.
  bool get _blocked => _intro || _busy || _ended || _freeze || _card != null || tableBusy || _run.shown || _run.tying;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// A reel comes off the table into the trainee's hands.
  void _pick(M3FuseRatingReel r, Offset origin) {
    // Taking a rated reel while he is still talking refuses him too.
    if (coworkerOpen && !coworkerChoiceUp && r.kind != M3FuseRatingKind.copper) {
      unawaited(answerCoworker(true, origin, direct: true));
    }
    if (_blocked || coworkerOpen || _held != null || _plateOpen || _run.rejected.contains(r.id)) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    _hush();
    setState(() {
      _held = r;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([M3FuseRatingLines.lookAsk]));
  }

  void _putBack() {
    if (_held == null || _blocked) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/drop.ogg', volume: 0.4);
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    unawaited(_sayChain([M3FuseRatingLines.ask]));
  }

  void _take(Offset origin) {
    final r = _held;
    if (r == null || _blocked || coworkerOpen) return;
    // Taking a reel decides his item: if he is due, he cuts in now (the reel
    // stays in hand; the close look comes back after him).
    if (holdForCoworker()) return;
    setState(() => _held = null);
    _judgeTake(r, origin);
  }

  void _judgeTake(M3FuseRatingReel r, Offset origin) {
    final o = _run.take(r);
    switch (o.verdict) {
      case M3FuseRatingVerdict.right:
        HapticFeedback.lightImpact();
        _cue('sounds/quiz_right.ogg');
        setState(() => _setMode(LinemanMode.hold));
        unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
        unawaited(_sayChain([M3FuseRatingLines.takeRight, M3FuseRatingLines.barrelAsk], mood: GuideMood.glad));
      case M3FuseRatingVerdict.deadly:
        unawaited(_deadly(o.mistake!));
      case M3FuseRatingVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, origin));
    }
  }

  void _wiped(M3FuseRatingSpot s) {
    _run.wipe(s);
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tock.ogg');
  }

  void _tie(double tension, Offset origin) {
    if (!_run.tying || _ended) return;
    final o = _run.tie(tension);
    if (o.verdict == M3FuseRatingVerdict.right) {
      HapticFeedback.lightImpact();
      _cue('sounds/quiz_right.ogg');
      setState(() => _setMode(LinemanMode.cheer));
      unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
      final r = _run.current;
      _ask(15, () => dealChoices(M3FuseRatingLines.right(r), M3FuseRatingLines.wrong(r), widget.rng), M3FuseRatingLines.question(r.ask),
          lead: M3FuseRatingLines.tieDone);
      return;
    }
    setState(() {
      _tieTry++;
      _setMode(LinemanMode.worried);
    });
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

  /// The next DTR (or the result) — by itself, after the reason.
  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _tieTry = 0;
      _setMode(LinemanMode.idle);
    });
    _cue('sounds/van_arrive.ogg', volume: 0.5);
    _armCoworker();
    unawaited(_sayChain([M3FuseRatingLines.ask]));
  }

  void _openPlate() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_flip.ogg', volume: 0.4);
    setState(() => _plateOpen = true);
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
  CoworkerScript get coworkerScript => M3FuseRatingLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.ended || _run.round < _run.deal.callRound) return null;
    // "মোটা তার জুড়ে দাও" fits only while a reel is still to be chosen: once
    // the last DTR's link is in, his moment has passed.
    if (_run.fitted != null && _run.round >= _run.deal.rounds.length - 1) return null;
    if (_blocked || _held != null || _plateOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Took his word: the thick copper goes into the barrel.
      _judgeTake(_run.current.copper, origin);
      return;
    }
    _run.caught.add(M3FuseRatingLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([M3FuseRatingLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3FuseRatingLines.tapWhy[_nudgeN++ % M3FuseRatingLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
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
    _cue('sounds/quiz_wrong.ogg', volume: 0.7);
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('fuse/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Thick copper in the barrel: the yard freezes grey, the transformer
  /// burns in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _held = null;
      _plateOpen = false;
      _setMode(LinemanMode.worried);
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
    final speak = await SpokenOnce.first('fuse/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3FuseRatingLines.deadlyWord : M3FuseRatingLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(_run.tying ? LinemanMode.hold : LinemanMode.idle);
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
    await _say(!_run.passed ? M3FuseRatingLines.fail : (_quickBonus ? M3FuseRatingLines.quick : M3FuseRatingLines.allSet),
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

  // ---- gesture hints ------------------------------------------------------------------

  /// The hand shows HOW to touch, never which reel or contact is right: a
  /// sweep over every choice, a tap only on the one way forward.
  HintSpec? _hint() {
    if (_plateOpen) return HintSpec.tapOn(_plateCardKey);
    if (_run.tying) return HintSpec.sweepOver([_topKey, _bottomKey, _tailKey, _tieKey]);
    if (_held != null) return HintSpec.sweepOver([_putBackKey, _takeKey]);
    final h = _sceneH;
    if (h == null) return null;
    final geo = M3FuseRatingGeo(h);
    final reels = _run.current.reels;
    return HintSpec.sweep([
      geo.plateTap,
      for (var i = 0; i < reels.length; i++)
        if (!_run.rejected.contains(reels[i].id)) geo.slot(i, reels.length),
    ], space: HintSpace.scene);
  }

  /// The level waits for the player's touch (no intro, card, deck, coworker,
  /// praise window, freeze or result).
  bool _hintWaiting(bool playing) =>
      playing && _card == null && !reasonOpen && !coworkerOpen && !tableBusy && !_busy && !_run.shown;

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    _sceneH = m.height;
    final geo = M3FuseRatingGeo(m.height);
    final r = _run.current;
    final aside = [for (final x in r.reels) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_plateOpen;
    final fitted = _run.fitted;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        // A tap on the yard (nothing to take there) counts towards the hint.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hints.missTap,
          child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: ValueKey('yard-${_run.round}'),
                child: RepaintBoundary(child: CustomPaint(painter: M3FuseRatingYardPainter(geo, round: _run.round))),
              ),
              // The plate's print, small (tap the tank to read it close).
              Positioned.fromRect(
                key: ValueKey('plate-${_run.round}'),
                rect: geo.plate.deflate(2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(M3FuseRatingLines.plateAmps(r.amps),
                      style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: Color(0xFF30363C), height: 1)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              Positioned.fill(
                key: const ValueKey('table'),
                child: RepaintBoundary(child: CustomPaint(painter: M3FuseRatingTablePainter(geo))),
              ),
              for (var i = 0; i < r.reels.length; i++)
                Positioned.fromRect(
                  key: ValueKey('slot-${_run.round}-$i'),
                  rect: geo.slot(i, r.reels.length),
                  child: DoDealIn(
                    index: i,
                    quiet: quiet,
                    muted: true,
                    child: _TrayReel(
                      reel: r.reels[i],
                      gone: _run.rejected.contains(r.reels[i].id) || _held?.id == r.reels[i].id || fitted?.id == r.reels[i].id,
                      enabled: canPick,
                      onTake: (at) => _pick(r.reels[i], at),
                    ),
                  ),
                ),
              for (var i = 0; i < aside.length && i < 3; i++)
                Positioned.fromRect(
                  key: ValueKey('aside-${aside[i].id}'),
                  rect: geo.aside(i),
                  child: _AsideReel(reel: aside[i], quiet: quiet),
                ),
            ],
          ),
          ),
        ),
      ),
      // Tap the transformer to read its plate.
      Positioned.fromRect(
        key: const ValueKey('plate-tap'),
        rect: geo.plateTap,
        child: Semantics(
          button: true,
          label: M3FuseRatingLines.plateLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _openPlate),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('fire'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3FuseRatingFirePainter(at: geo.fireAt, v: v)),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final held = _held;
    final fitted = _run.fitted;
    final r = _run.current;
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
              labels: M3FuseRatingLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hint,
            hintWaiting: _hintWaiting(playing),
            hintKey: '${_run.round}|${held?.id}|$_plateOpen|${_run.tying}|$_tieTry|${_run.rejected.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              // The reel stays in hand while he talks; the close look comes back after him.
              if (held != null && playing && !coworkerOpen)
                _ReelLook(
                  key: ValueKey('look-${held.id}'),
                  reel: held,
                  quiet: quiet,
                  putBackKey: _putBackKey,
                  takeKey: _takeKey,
                  onMiss: _hints.missTap,
                  onTake: _take,
                  onPutBack: _putBack,
                ),
              if (fitted != null && _run.tying && playing && _card == null)
                _BarrelBench(
                  key: ValueKey('bench-${_run.round}-$_tieTry'),
                  amps: r.amps,
                  reel: fitted,
                  dirty: r.dirty,
                  wiped: {..._run.wiped},
                  quiet: quiet,
                  topKey: _topKey,
                  bottomKey: _bottomKey,
                  tailKey: _tailKey,
                  tieKey: _tieKey,
                  onMiss: _hints.missTap,
                  onWiped: _wiped,
                  onTie: _tie,
                ),
              if (_plateOpen && playing)
                _PlateZoom(
                  key: const ValueKey('plate-zoom'),
                  amps: r.amps,
                  quiet: quiet,
                  cardKey: _plateCardKey,
                  onClose: () => setState(() => _plateOpen = false),
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
              if (playing && _card == null && !_plateOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: _cardTone,
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
                  sound: FailSound.fire,
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
                  line: M3FuseRatingLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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

const _ink = Color(0xFF1E2228);

/// A reel standing on the table. At this distance its tag cannot be read.
class _TrayReel extends StatelessWidget {
  const _TrayReel({required this.reel, required this.gone, required this.enabled, required this.onTake});
  final M3FuseRatingReel reel;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  Widget build(BuildContext context) {
    if (gone) return Semantics(label: M3FuseRatingLines.reelLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: M3FuseRatingLines.reelLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTake(d.globalPosition) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: CustomPaint(painter: M3FuseRatingReelPainter(reel.wire)),
        ),
      ),
    );
  }
}

/// A wrong reel set aside on the ground, tagged বাদ.
class _AsideReel extends StatelessWidget {
  const _AsideReel({required this.reel, required this.quiet});
  final M3FuseRatingReel reel;
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
          Positioned.fill(child: CustomPaint(painter: M3FuseRatingReelPainter(reel.wire))),
          Positioned(
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
              child: Text(M3FuseRatingLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card rising over the scene (the close looks share it).
class _CloseCard extends StatelessWidget {
  const _CloseCard({required this.quiet, required this.child, this.onMiss});
  final bool quiet;
  final Widget child;

  /// A tap on the dim backdrop (nothing there): counts towards the hint.
  final VoidCallback? onMiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMiss,
        child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
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
              child: child,
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// The plate read up close (tap anywhere to put it back).
class _PlateZoom extends StatelessWidget {
  const _PlateZoom({super.key, required this.amps, required this.quiet, required this.cardKey, required this.onClose});
  final int amps;
  final bool quiet;

  /// The plate card (the hint's tap: putting it down is the one way on).
  final GlobalKey cardKey;
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
                key: cardKey,
                width: 300,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1E1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The riveted metal plate.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF6E767C), width: 2),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE6E4DA), Color(0xFFC9C6B8)],
                        ),
                      ),
                      child: Row(
                        children: [
                          const _Rivet(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(M3FuseRatingLines.plateHead,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF30363C), letterSpacing: 1.2)),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(M3FuseRatingLines.plateAmps(amps),
                                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1B2026), height: 1.05)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const _Rivet(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(M3FuseRatingLines.plateBn(amps), style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
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

class _Rivet extends StatelessWidget {
  const _Rivet();

  @override
  Widget build(BuildContext context) => Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8D949A)),
      );
}

/// The reel held up: its tag (or none) readable now. Take it or put it back.
class _ReelLook extends StatelessWidget {
  const _ReelLook({
    super.key,
    required this.reel,
    required this.quiet,
    required this.putBackKey,
    required this.takeKey,
    required this.onMiss,
    required this.onTake,
    required this.onPutBack,
  });
  final M3FuseRatingReel reel;
  final bool quiet;
  final GlobalKey putBackKey;
  final GlobalKey takeKey;
  final VoidCallback onMiss;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  Widget build(BuildContext context) {
    return _CloseCard(
      quiet: quiet,
      onMiss: onMiss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 2.1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6C7884), Color(0xFF3E4750)]),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(painter: M3FuseRatingReelPainter(reel.wire, big: true), child: const SizedBox.expand()),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: reel.tag.isEmpty
                          ? const SizedBox.shrink()
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4E7B8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFB59A4E)),
                              ),
                              child: FittedBox(
                                child: Text(reel.tag, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3A2E10), letterSpacing: 0.6)),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(M3FuseRatingLines.reelBn(reel), style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: DoBigButton(key: putBackKey, label: M3FuseRatingLines.putBack, filled: false, onTapUp: (_) => onPutBack())),
              const SizedBox(width: 12),
              Expanded(child: DoBigButton(key: takeKey, label: M3FuseRatingLines.take, filled: true, onTapUp: (d) => onTake(d.globalPosition))),
            ],
          ),
        ],
      ),
    );
  }
}

/// How much rubbing (logical px of finger travel) wipes a sooty contact clean.
const kM3FuseRatingRub = 90.0;

/// The barrel on the table, up close: rub the soot off its contacts with the
/// cloth, pull the link's tail taut, and tie it.
class _BarrelBench extends StatefulWidget {
  const _BarrelBench({
    super.key,
    required this.amps,
    required this.reel,
    required this.dirty,
    required this.wiped,
    required this.quiet,
    required this.topKey,
    required this.bottomKey,
    required this.tailKey,
    required this.tieKey,
    required this.onMiss,
    required this.onWiped,
    required this.onTie,
  });
  final int amps;
  final M3FuseRatingReel reel;
  final Set<M3FuseRatingSpot> dirty;
  final Set<M3FuseRatingSpot> wiped;
  final bool quiet;

  /// The bench's controls, for the hint's sweep (both contacts alike).
  final GlobalKey topKey;
  final GlobalKey bottomKey;
  final GlobalKey tailKey;
  final GlobalKey tieKey;
  final VoidCallback onMiss;
  final ValueChanged<M3FuseRatingSpot> onWiped;
  final void Function(double tension, Offset origin) onTie;

  @override
  State<_BarrelBench> createState() => _BarrelBenchState();
}

class _BarrelBenchState extends State<_BarrelBench> {
  late final Map<M3FuseRatingSpot, double> _rub = {
    for (final s in M3FuseRatingSpot.values) s: widget.dirty.contains(s) && !widget.wiped.contains(s) ? 0 : kM3FuseRatingRub,
  };
  final Set<M3FuseRatingSpot> _touched = {};
  double _tension = 0.15;
  Offset? _hand;
  var _tied = false;

  double _soot(M3FuseRatingSpot s) => widget.dirty.contains(s) ? (1 - _rub[s]! / kM3FuseRatingRub).clamp(0.0, 1.0) : 0;

  void _rubAt(M3FuseRatingSpot s, Offset local, double travel) {
    final before = _rub[s]!;
    final after = math.min(kM3FuseRatingRub, before + travel);
    _touched.add(s);
    setState(() {
      _rub[s] = after;
      _hand = local;
    });
    if (widget.dirty.contains(s) && before < kM3FuseRatingRub && after >= kM3FuseRatingRub) widget.onWiped(s);
  }

  Future<void> _tie(Offset origin) async {
    if (_tied) return;
    HapticFeedback.mediumImpact();
    setState(() => _tied = true);
    await Future<void>.delayed(Duration(milliseconds: widget.quiet ? 150 : 500));
    if (!mounted) return;
    widget.onTie(_tension, origin);
  }

  Widget _contact(M3FuseRatingBarrelGeo g, M3FuseRatingSpot s) {
    final r = s == M3FuseRatingSpot.top ? g.topContact : g.bottomContact;
    final box = r.inflate(10);
    return Positioned.fromRect(
      rect: box,
      child: Semantics(
        key: s == M3FuseRatingSpot.top ? widget.topKey : widget.bottomKey,
        label: s == M3FuseRatingSpot.top ? M3FuseRatingLines.topLabel : M3FuseRatingLines.bottomLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _rubAt(s, d.localPosition + box.topLeft, 0),
          onPanUpdate: (d) => _rubAt(s, d.localPosition + box.topLeft, d.delta.distance),
          onPanEnd: (_) => setState(() => _hand = null),
          onPanCancel: () => setState(() => _hand = null),
          child: _touched.contains(s) ? const SizedBox.expand() : const Center(child: _Cloth()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return _CloseCard(
      quiet: widget.quiet,
      onMiss: widget.onMiss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: _Pill(head: M3FuseRatingLines.plateWord, text: M3FuseRatingLines.plateAmps(widget.amps))),
              ),
              const SizedBox(width: 8),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: _Pill(head: '', text: reel.tag))),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 2.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A96A1), Color(0xFF5E6A75)]),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final s = Size(box.maxWidth, box.maxHeight);
                  final g = M3FuseRatingBarrelGeo(s);
                  final pull = g.pullStrip;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: M3FuseRatingBarrelPainter(
                            sootTop: _soot(M3FuseRatingSpot.top),
                            sootBottom: _soot(M3FuseRatingSpot.bottom),
                            tension: _tension,
                          ),
                        ),
                      ),
                      _contact(g, M3FuseRatingSpot.top),
                      _contact(g, M3FuseRatingSpot.bottom),
                      // Pull the tail (drag right) before tying.
                      Positioned.fromRect(
                        rect: pull,
                        child: Semantics(
                          key: widget.tailKey,
                          label: M3FuseRatingLines.tailLabel,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: _tied ? null : (d) => setState(() => _tension = (_tension + d.delta.dx / (s.width * 0.28)).clamp(0.0, 1.0)),
                            child: Align(
                              alignment: const Alignment(0.2, 0.3),
                              child: Icon(Icons.swipe_right_alt_rounded, size: 26, color: const Color(0xFFFF851B).withValues(alpha: _tension >= 0.99 ? 0 : 0.9)),
                            ),
                          ),
                        ),
                      ),
                      if (_hand != null)
                        Positioned(
                          left: _hand!.dx - 18,
                          top: _hand!.dy - 18,
                          width: 36,
                          height: 36,
                          child: const IgnorePointer(child: _Cloth(live: true)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          DoBigButton(key: widget.tieKey, label: M3FuseRatingLines.tie, filled: true, onTapUp: (d) => unawaited(_tie(d.globalPosition))),
        ],
      ),
    );
  }
}

/// The wiping cloth: where to rub (still), or under the finger.
class _Cloth extends StatelessWidget {
  const _Cloth({this.live = false});
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 18.0 : 14.0;
    return SizedBox(
      width: r * 2,
      height: r * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: live ? const Color(0x66FF851B) : const Color(0x33FF851B),
          border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
        ),
        child: Icon(Icons.cleaning_services_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.head, required this.text});
  final String head;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
      decoration: BoxDecoration(color: const Color(0xFF1E2126), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (head.isNotEmpty) Text('$head ', style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFB9BEC4))),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFF2F2EC), letterSpacing: 0.6)),
        ],
      ),
    );
  }
}
