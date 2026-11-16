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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_bill_listen_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_bill_listen_world.dart'
    show M8BillComplaint, M8BillGeo, M8BillLook, M8BillMood, M8BillPlace, M8BillZone, kM8BillLooks, kM8BillSkies, m8BillZoneOf;

// Lesson 8.1 "WBERC পরিচিতি: রাজ্যের পাওয়ার বস", কাজ "তর্ক নয়, তথ্য দিন"
// (pack do_8_1_a, rung 8.1/do/0, engineType m8_bill_listen).
//
// The core verb: hold to listen, then show the chart. An angry consumer talks
// in bursts (silent caption bubbles). The player holds the round 'শুনছি' pad
// the whole time: a release before his real end is interrupting = a slip (his
// last burst replays, louder). False pauses ('…' stays open, hands moving) are
// the trap. Not held ~2 s after he starts → he stops with 'শুনছেন?' and waits
// (no slip). At the real end (the bubble closes, he holds out the bill or
// points at the wall) the release opens the evidence step: swipe the bill up
// (door, roadside) or drag the scene sideways to the notice board (office).
// Then tap the part of the table that answers his question (3 equal zones,
// the header always on top, the two rows in dealt order). A wrong zone = slip.
// The right zone: the trainee's reply (silent caption), ◆ on the table → "কেন?".
//
// No deadly in lesson 8.1 (ruling M8-1: law and billing, nobody exposed); every
// mistake is a slip (R7); three slips strike out.
//
// The coworker (lesson myth 1 as a shortcut, M8-14) comes once a play on a
// dealt round after his question lands and before the flip/pan; both the flip
// and the pan wait for him (holdForCoworker). Listening = slip (X2/B1), the
// consumer storms off, then the round resumes at the evidence step.
//
// Gesture hands (how, never what): the hold hint on the pad while he waits,
// a swipe-up on the bill, a short sideways drag at the office, a sweep over
// the three zones. Off during the intro, while the pad is held, coworker
// beat 1, the praise window, cards, strike-out and result.

// ============================================================================
// Content
// ============================================================================

abstract final class M8BillListenLines {
  static const title = 'তর্ক নয়, তথ্য দিন';
  // DRAFT wording — owner (M8-14 / M6-12): every line below until the owner
  // gives the natural wording.
  static const intro = 'গ্রাহক বিল নিয়ে রেগে আছেন — আগে শুনুন, তারপর তথ্য দিন।';

  // The guide's task (tap him: the next of the pool).
  static const askListen = 'আগে পুরোটা শুনুন।';
  static const tapQuestion = 'ওঁর প্রশ্নটা কী ছিল?';
  static const tapPaper = 'উত্তরটা কাগজেই আছে — কোথায়?';
  static const tapFacts = 'তর্ক নয়, তথ্য।';
  static const tasks = [askListen, tapQuestion, tapPaper, tapFacts];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The consumer's words (silent captions, ruling M8-10; English digits).
  static const areYouListening = 'শুনছেন?';
  static const storm = 'তাহলে কোম্পানিকে ধরব!';

  /// The four complaints; the last burst of a round is one of these.
  static String complaint(M8BillComplaint c) => switch (c) {
        M8BillComplaint.company => 'কোম্পানি ইচ্ছেমতো রেট বাড়িয়েছে!',
        M8BillComplaint.lineman => 'তোমরা লাইনম্যানরাই রেট ঠিক করো!',
        M8BillComplaint.unit => 'ইউনিট প্রতি দাম এত কেন, কে ঠিক করল?',
        M8BillComplaint.fixed => 'ফিক্সড চার্জ কেন দেব, কে বসাল?',
      };

  /// Earlier bursts: venting that names no part of the bill.
  static const fillers = [
    'আমি তো বিল দেখে হতবাক!',
    'গত মাসেও এত আসেনি।',
    'সংসার চালানো দায় হয়ে গেছে।',
    'কেউ কিছু বুঝিয়ে বলছে না!',
    'এই বিল আমি মানব না!',
    'রোজ রোজ এই এক ঝামেলা।',
    'আমাকে কেউ জবাব দেবে?',
  ];

  // The table (a bill's back, or the notice board's paper): the lesson's
  // words; figures are greyed bars.
  static const tableHead = 'WBERC ট্যারিফ অর্ডার';
  static const rowUnit = 'ইউনিট প্রতি দাম';
  static const rowFixed = 'ফিক্সড চার্জ';
  static String zoneLabel(M8BillZone z) => switch (z) {
        M8BillZone.header => tableHead,
        M8BillZone.unit => rowUnit,
        M8BillZone.fixed => rowFixed,
      };

  /// The trainee's reply (lesson 8.1 tariff, word for word; a silent caption).
  static const reply = 'স্যার, এই রেট আমাদের কোম্পানি ঠিক করে না, এটা কমিশনের অর্ডার।';

  static const padWord = 'শুনছি';
  static const billWord = 'বিল';
  static const sceneLabel = 'গ্রাহকের সঙ্গে কথা';

  static String placeName(M8BillPlace p) => switch (p) {
        M8BillPlace.door => 'বাড়ির দরজা',
        M8BillPlace.roadside => 'রাস্তার ধার',
        M8BillPlace.office => 'সেকশন অফিস',
      };

  // The reasons (the right ones state the lesson's rule; the wrong ones are
  // myths and field excuses).
  static String whyQ(M8BillZone z) => switch (z) {
        M8BillZone.header => 'কেন চার্টের এই জায়গাটা দেখালেন?',
        M8BillZone.unit => 'কেন ইউনিট প্রতি দামের লাইনটা দেখালেন?',
        M8BillZone.fixed => 'কেন ফিক্সড চার্জের লাইনটা দেখালেন?',
      };
  static const whyRight = <M8BillZone, List<String>>{
    M8BillZone.header: ['রেট কোম্পানি ঠিক করে না — এটা কমিশনের অর্ডার', 'দাম ঠিক করা WBERC-এর কাজ, কোম্পানির নয়'],
    M8BillZone.unit: ['ইউনিট প্রতি দাম কত হবে, ঠিক করে WBERC', 'ইউনিট রেট কমিশনের অর্ডার, কোম্পানির নয়'],
    M8BillZone.fixed: ['ফিক্সড চার্জ কত হবে, সেটাও ঠিক করে WBERC', 'ফিক্সড চার্জও কমিশনের অর্ডার মেনে বসে'],
  };
  static const _wrongBy = <M8BillZone, List<String>>{
    M8BillZone.header: [
      'কোম্পানি যা খুশি রেট বাড়ায়, আমি কী করব',
      'চার্ট দেখালে গ্রাহক চুপ করে যান, তাই দেখালাম',
      'লাইনম্যানরাই রেট ঠিক করে দেন, তাই জানি',
      'অফিসারদের ব্যাপার, আমার কিছু জানার নেই',
      'বিল বেশি এলে মিটারই খারাপ হয়, তাই দেখালাম',
    ],
    M8BillZone.unit: [
      'ইউনিট রেট কোম্পানি রোজ বদলায়, তাই দেখালাম',
      'ইউনিট রেট লাইনম্যান কমাতে পারেন, তাই দেখালাম',
      'ইউনিট রেট গ্রাহক নিজেই বেছে নেন, তাই দেখালাম',
      'ইউনিট রেট শুধু অফিসাররা জানেন, তাই দেখালাম',
      'ইউনিট রেট কোম্পানির ইচ্ছেয় চলে, তাই দেখালাম',
    ],
    M8BillZone.fixed: [
      'ফিক্সড চার্জ কোম্পানির বাড়তি লাভ, তাই দেখালাম',
      'ফিক্সড চার্জ লাইনম্যান মাফ করতে পারেন, তাই',
      'ফিক্সড চার্জ কোম্পানি নিজে বসায়, তাই দেখালাম',
      'ফিক্সড চার্জ না দিলেও চলে, তাই দেখালাম',
      'ফিক্সড চার্জ শুধু অফিসারদের ব্যাপার, তাই',
    ],
  };
  static List<String> whyWrong(M8BillZone z) => _wrongBy[z]!;
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => [for (final l in _wrongBy.values) ...l];

  // The careless coworker: lesson myth 1 as a shortcut (M8-14).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'বলে দাও কোম্পানি নিজের ইচ্ছেমতো রেট বাড়িয়েছে — ঝামেলা মিটে যাবে।',
    exitLine: coworkerExit,
    right: [
      'না — রেট কোম্পানি ঠিক করে না, কমিশনের অর্ডার',
      'না — কোম্পানি প্রস্তাব দেয়, রেট দেয় WBERC',
    ],
    wrong: [
      'ঠিক, ঝামেলা এড়াতে কোম্পানির ঘাড়েই চাপাই',
      'বলে দিই, কোম্পানিই রেট বাড়িয়েছে, আমরা কী করব',
      'ঝামেলা মেটাতে ওর কথাই বলে দিই, কী আর হবে',
      'বলি, রেট তো কোম্পানির নিজের ইচ্ছেয় চলে',
      'বলে দিই, অফিসাররাই রেট বাড়িয়ে দেন, আমরা নই',
    ],
    asks: ['ওর কথা মানবেন?', 'ওকে কী বলবেন?', 'কী করবেন?'],
  );
  static const callHeld = 'ঠিক! রেট কমিশনের অর্ডারে ঠিক হয়, কোম্পানির ইচ্ছেয় নয়।';

  static const allSet = 'গ্রাহক শান্ত — তর্ক নয়, তথ্য দিয়েছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে পুরোটা শুনুন, তারপর চার্টে দেখান।';

  // "আজ যা ধরলেন".
  static String caughtZone(M8BillZone z) => switch (z) {
        M8BillZone.header => 'রেট ঠিক করে কমিশন — অর্ডার দেখালেন',
        M8BillZone.unit => 'ইউনিট প্রতি দাম — কমিশনের অর্ডার',
        M8BillZone.fixed => 'ফিক্সড চার্জ — কমিশনের অর্ডার',
      };
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (his exit, the old asks, the
  /// quick-pass line).
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', quick};

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  /// The consumer's words and the trainee's reply are silent captions.
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        for (final z in M8BillZone.values) whyQ(z),
        ...coworker.asks.where((a) => !reused.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M8BillListenMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused, ...tapWhy];
}

abstract final class M8BillListenMistakes {
  static const _dir = 'assets/game/art/m8_bill_listen';

  /// Lesson 8.1 point 3 (0-based 2) is the tariff.
  static const _point = 2;

  // DRAFT wording — owner (M8-14 / M6-12).
  // Releasing the pad before he finished (pro tip 1; a tip, not a numbered point).
  static const interrupt = DoMistake(
    key: '8.1/m8_bill_listen/interrupt',
    textBn: 'তর্কে জড়াবেন না — শান্তভাবে পুরোটা শুনে তারপর তথ্য দিন।',
    art: '$_dir/interrupt.svg',
  );

  // The wrong part of the table (the card names THIS complaint's right part).
  static const wrongCompany = DoMistake(
    key: '8.1/m8_bill_listen/wrong-zone-company',
    textBn: 'রেট কোম্পানি ঠিক করে না — চার্টের মাথায় WBERC-এর ট্যারিফ অর্ডার দেখিয়ে বলুন।',
    art: '$_dir/tariff_chart.svg',
    lessonPoint: _point,
  );
  static const wrongLineman = DoMistake(
    key: '8.1/m8_bill_listen/wrong-zone-lineman',
    textBn: 'রেট লাইনম্যান ঠিক করে না — চার্টের মাথায় WBERC-এর ট্যারিফ অর্ডার দেখিয়ে বলুন।',
    art: '$_dir/tariff_chart.svg',
    lessonPoint: _point,
  );
  static const wrongUnit = DoMistake(
    key: '8.1/m8_bill_listen/wrong-zone-unit',
    textBn: 'ইউনিট প্রতি দাম কত হবে, কমিশন ঠিক করে — ওই লাইনটা দেখান।',
    art: '$_dir/tariff_chart.svg',
    lessonPoint: _point,
  );
  static const wrongFixed = DoMistake(
    key: '8.1/m8_bill_listen/wrong-zone-fixed',
    textBn: 'ফিক্সড চার্জ কত হবে, সেটাও কমিশন ঠিক করে — ওই লাইনটা দেখান।',
    art: '$_dir/tariff_chart.svg',
    lessonPoint: _point,
  );

  // Listening to the coworker (lesson 8.1 myth 1 and its reality; X2/B1: slip).
  static const pushListen = DoMistake(
    key: '8.1/m8_bill_listen/push-listen',
    textBn: 'না — কোম্পানি শুধু প্রস্তাব দেয় যে তাদের খরচ বেড়েছে। WBERC জনশুনানি করে, সব দিক বিচার করে তারপর নতুন রেট ঘোষণা করে।',
    art: '$_dir/commission.svg',
  );

  static DoMistake wrongZone(M8BillComplaint c) => switch (c) {
        M8BillComplaint.company => wrongCompany,
        M8BillComplaint.lineman => wrongLineman,
        M8BillComplaint.unit => wrongUnit,
        M8BillComplaint.fixed => wrongFixed,
      };

  static const List<DoMistake> all = [interrupt, wrongCompany, wrongLineman, wrongUnit, wrongFixed, pushListen];
}

// ============================================================================
// Deal and rules
// ============================================================================

/// One round: who complains of what, where, how he talks.
@immutable
class M8BillRound {
  const M8BillRound({
    required this.complaint,
    required this.place,
    required this.bursts,
    required this.pauseAfter,
    required this.unitFirst,
    required this.look,
  });

  final M8BillComplaint complaint;
  final M8BillPlace place;

  /// 2–4 bursts; the last is the complaint (his question).
  final List<String> bursts;

  /// The gaps after these bursts are false pauses ('…' stays open).
  final Set<int> pauseAfter;

  /// The unit row is above the fixed row (the header stays on top).
  final bool unitFirst;
  final int look;

  M8BillZone get zone => m8BillZoneOf(complaint);

  /// A bill in his hand (flip) rather than the counter (pan).
  bool get flips => place != M8BillPlace.office;
}

@immutable
class M8BillDeal {
  const M8BillDeal({required this.rounds, required this.coworkerRound, required this.light});
  final List<M8BillRound> rounds;
  final int coworkerRound;
  final int light;
}

M8BillRound m8BillDealRound(M8BillComplaint c, M8BillPlace place, math.Random rng) {
  final n = 2 + rng.nextInt(3);
  final fill = [...M8BillListenLines.fillers]..shuffle(rng);
  final bursts = [...fill.take(n - 1), M8BillListenLines.complaint(c)];
  // 1–2 false pauses among the n − 1 gaps.
  final gaps = [for (var i = 0; i < n - 1; i++) i]..shuffle(rng);
  final want = math.min(1 + rng.nextInt(2), n - 1);
  return M8BillRound(
    complaint: c,
    place: place,
    bursts: bursts,
    pauseAfter: gaps.take(want).toSet(),
    unitFirst: rng.nextBool(),
    look: rng.nextInt(kM8BillLooks.length),
  );
}

M8BillDeal m8BillDeal(math.Random rng) {
  final complaints = [...M8BillComplaint.values]..shuffle(rng);
  List<M8BillPlace> places;
  do {
    places = [for (var i = 0; i < 3; i++) M8BillPlace.values[rng.nextInt(3)]];
    // At least one bill-flip round and one notice-board round.
  } while (!places.contains(M8BillPlace.office) || places.every((p) => p == M8BillPlace.office));
  return M8BillDeal(
    rounds: [for (var i = 0; i < 3; i++) m8BillDealRound(complaints[i], places[i], rng)],
    coworkerRound: rng.nextInt(3),
    light: rng.nextInt(kM8BillSkies.length),
  );
}

/// What the rant's clock did on a tick.
enum M8RantEvent { none, word, burst, waiting, ended }

/// His talking, one 100 ms tick at a time (pure, so it is unit-tested). He
/// talks word by word; the gap after a burst is short, or a false pause. Not
/// held for ~2 s → he stops and waits ([waiting]); the real end only closes
/// while the pad is held.
class M8Rant {
  M8Rant(this.round);
  final M8BillRound round;

  static const tickMs = 100;
  static const wordMs = 200;
  static const graceMs = 2000;
  static const shortGapMs = 500;
  static const pauseGapMs = 1800;
  static const endLagMs = 600;

  int burst = 0;
  int word = 0;
  int gapLeft = 0;
  int unheld = 0;
  int _acc = 0;
  int _endLeft = 0;
  bool inPause = false;
  bool closing = false;
  bool waiting = false;

  /// The real end was reached (the bubble is closed).
  bool ended = false;
  bool louder = false;

  List<String> get _words => round.bursts[burst].split(' ');
  bool get lastBurst => burst == round.bursts.length - 1;

  /// The caption now: the burst so far (a false pause keeps it open with '…').
  String get shown {
    final w = _words.take(word).join(' ');
    return inPause ? '$w …' : w;
  }

  void _rewind() {
    word = 0;
    gapLeft = 0;
    inPause = false;
    closing = false;
    _acc = 0;
  }

  /// The pad was pressed while he waited: he goes on from his burst's start.
  void resume() {
    if (!waiting) return;
    waiting = false;
    unheld = 0;
    _rewind();
  }

  /// After an interruption: his last burst again, louder.
  void replay() {
    louder = true;
    waiting = false;
    unheld = 0;
    _rewind();
  }

  M8RantEvent tick({required bool padDown}) {
    if (ended || waiting) return M8RantEvent.none;
    if (padDown) {
      unheld = 0;
    } else {
      unheld += tickMs;
      if (unheld >= graceMs) {
        waiting = true;
        _rewind();
        return M8RantEvent.waiting;
      }
    }
    if (closing) {
      _endLeft -= tickMs;
      if (_endLeft > 0) return M8RantEvent.none;
      if (padDown) {
        ended = true;
        return M8RantEvent.ended;
      }
      // Nobody listened to the end: he goes round again.
      waiting = true;
      _rewind();
      return M8RantEvent.waiting;
    }
    if (gapLeft > 0) {
      gapLeft -= tickMs;
      if (gapLeft <= 0) {
        burst++;
        word = 0;
        inPause = false;
        _acc = 0;
        return M8RantEvent.burst;
      }
      return M8RantEvent.none;
    }
    _acc += tickMs;
    if (_acc < wordMs) return M8RantEvent.none;
    _acc = 0;
    if (word < _words.length) {
      word++;
      if (word == _words.length) {
        if (lastBurst) {
          closing = true;
          _endLeft = endLagMs;
        } else {
          inPause = round.pauseAfter.contains(burst);
          gapLeft = inPause ? pauseGapMs : shortGapMs;
        }
      }
      return M8RantEvent.word;
    }
    return M8RantEvent.none;
  }
}

/// What a tap on the table did.
enum M8BillTap { right, wrong }

/// The play state (pure logic).
class M8BillRun {
  M8BillRun(this.deal);
  final M8BillDeal deal;

  int index = 0;
  int slips = 0;
  final List<String> caught = [];

  M8BillRound get round => deal.rounds[index.clamp(0, deal.rounds.length - 1)];
  bool get done => index >= deal.rounds.length;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  DoMistake _slip(DoMistake m) {
    slips++;
    return m;
  }

  /// The pad released before his real end.
  DoMistake interrupt() => _slip(M8BillListenMistakes.interrupt);

  /// A tap on a zone of the table.
  (M8BillTap, DoMistake?) tap(M8BillZone z) {
    if (done) return (M8BillTap.wrong, null);
    if (z == round.zone) {
      caught.add(M8BillListenLines.caughtZone(z));
      return (M8BillTap.right, null);
    }
    return (M8BillTap.wrong, _slip(M8BillListenMistakes.wrongZone(round.complaint)));
  }

  /// Listened to the coworker.
  DoMistake pushSlip() => _slip(M8BillListenMistakes.pushListen);

  void next() => index++;
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   per round: he walks in 1200, his rant ~6000 (3 bursts × ~1.6 s + gaps),
///     the release and the flip/pan 2500, a look and a tap 2500 ≈ 12200 × 3 ≈ 36600
///   + a reason each round (~8200 × 3)                          ≈ 24600
///   + the coworker once                                        ≈  9600
///                                                              ≈ 70800
/// 85 % ≈ 60200 → 60 s (a builder's estimate; owner may tune after playtest).
const m8BillListenQuickMs = 60000;

@immutable
class M8BillListenPack {
  const M8BillListenPack({required this.id, required this.titleBn, this.quickMs = m8BillListenQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8BillListenPack> m8BillListenPacks = {
  'do_8_1_a': M8BillListenPack(id: 'do_8_1_a', titleBn: M8BillListenLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8BillListenProbe {
  static M8BillRun? run;
  static M8Rant? rant;

  /// arrive · rant · endHeld · evidence · moving · table · reply
  static String phase = '';
}

enum _Ph { arrive, rant, endHeld, evidence, moving, table, reply }

// ============================================================================
// Page
// ============================================================================

class M8BillListenPage extends StatefulWidget {
  const M8BillListenPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8BillListenPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8BillListenPage> createState() => _M8BillListenPageState();
}

class _M8BillListenPageState extends State<M8BillListenPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _BillRunPage(
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

class _BillRunPage extends ConsumerStatefulWidget {
  const _BillRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8BillListenPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_BillRunPage> createState() => _BillRunPageState();
}

class _BillRunPageState extends ConsumerState<_BillRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8BillRun _run;
  late M8Rant _rant;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
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

  _Ph _phase = _Ph.arrive;
  var _padHeld = false;
  var _storm = false;
  var _replied = false;

  /// The caption now (his burst, 'শুনছেন?' or his storm line), repainted at
  /// the rant's tick rate only.
  final _caption = ValueNotifier<int>(0);
  final _beat = ValueNotifier<int>(0);
  Timer? _tick;
  final List<Timer> _timers = [];

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  M8BillGeo? _geoNow;

  // A drag on the scene (the bill swipe, the office pan).
  Offset? _dragFrom;
  Offset _dragNow = Offset.zero;

  @override
  void initState() {
    super.initState();
    _run = M8BillRun(m8BillDeal(widget.rng));
    _rant = M8Rant(_run.round);
    M8BillListenProbe.run = _run;
    M8BillListenProbe.rant = _rant;
    M8BillListenProbe.phase = 'arrive';
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _tick?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    if (identical(M8BillListenProbe.run, _run)) {
      M8BillListenProbe.run = null;
      M8BillListenProbe.rant = null;
      M8BillListenProbe.phase = '';
    }
    _caption.dispose();
    _beat.dispose();
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

  void _tickSound([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _later(int ms, VoidCallback f) {
    late final Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _timers.remove(t);
      if (mounted) f();
    });
    _timers.add(t);
  }

  void _setPhase(_Ph p) {
    _phase = p;
    M8BillListenProbe.phase = p.name;
  }

  bool get _live => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !struckOut;
  bool get _atHisRound => _run.index == _run.deal.coworkerRound;

  // --- the round -------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    _rant = M8Rant(_run.round);
    M8BillListenProbe.rant = _rant;
    _tick?.cancel();
    setState(() {
      _setPhase(_Ph.arrive);
      _wake++;
      _storm = false;
      _replied = false;
      _dragFrom = null;
    });
    _caption.value++;
    unawaited(_sayChain([M8BillListenLines.askListen]));
    _later(_quiet ? 300 : 1300, _arrived);
  }

  void _arrived() {
    if (_ended || _phase != _Ph.arrive) return;
    setState(() => _setPhase(_Ph.rant));
    _caption.value++;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: M8Rant.tickMs), (_) => _rantTick());
  }

  void _rantTick() {
    if (!mounted || _phase != _Ph.rant) return;
    // He waits while a card, the coworker or a deck is up.
    if (!_live) return;
    final ev = _rant.tick(padDown: _padHeld);
    switch (ev) {
      case M8RantEvent.none:
        return;
      case M8RantEvent.word || M8RantEvent.burst:
        if (!_quiet) _beat.value++;
        _caption.value++;
      case M8RantEvent.waiting:
        _caption.value++;
        setState(() => _wake++);
      case M8RantEvent.ended:
        _tick?.cancel();
        HapticFeedback.mediumImpact();
        setState(() {
          _setPhase(_Ph.endHeld);
          _wake++;
        });
        _caption.value++;
        // His question has landed: the coworker is due on his round.
        if (_atHisRound && !coworkerDone && !coworkerDue) scheduleCoworker();
        // Still holding: he goes on after a moment (the pad is the only control).
        _later(2500, () {
          if (_phase == _Ph.endHeld) _toEvidence();
        });
    }
  }

  void _toEvidence() {
    if (_phase != _Ph.endHeld) return;
    setState(() {
      _setPhase(_Ph.evidence);
      _wake++;
    });
    unawaited(_sayChain([M8BillListenLines.tapPaper]));
  }

  // --- the pad ---------------------------------------------------------------
  void _padDown() {
    _padHeld = true;
    if (!_live) {
      setState(() {});
      return;
    }
    if (_phase == _Ph.rant && _rant.waiting) {
      _rant.resume();
      _tickSound('sounds/intro/click.ogg', 0.4);
      _caption.value++;
    }
    setState(() => _wake++);
  }

  void _padUp() {
    final was = _padHeld;
    _padHeld = false;
    if (!was) return;
    if (_live && _phase == _Ph.rant && !_rant.waiting && !_rant.ended) {
      // He was still talking: interrupting.
      final m = _run.interrupt();
      _afterCards = () {
        _rant.replay();
        _caption.value++;
      };
      unawaited(_levelDelta(-10, _padOrigin(), mood: GuideMood.warn));
      unawaited(_slip(m));
      return;
    }
    if (_live && _phase == _Ph.endHeld) {
      _toEvidence();
      return;
    }
    setState(() => _wake++);
  }

  Offset _padOrigin() {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height - 90);
  }

  // --- the evidence step -----------------------------------------------------
  void _tapScene(Offset p, M8BillGeo geo) {
    if (!_live) return;
    if (_phase == _Ph.table) {
      for (final z in M8BillZone.values) {
        if (geo.zone(z, unitFirst: _run.round.unitFirst).contains(p)) {
          _judge(z, p);
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _panStart(Offset p) {
    _dragFrom = _live ? p : null;
    _dragNow = p;
  }

  void _panUpdate(Offset p) => _dragNow = p;

  void _panEnd(M8BillGeo geo) {
    final from = _dragFrom;
    _dragFrom = null;
    if (from == null || !_live || _phase != _Ph.evidence) return;
    final d = _dragNow - from;
    final r = _run.round;
    if (r.flips) {
      if (geo.billTouch.contains(from) && d.dy <= -50 && d.dy.abs() > d.dx.abs()) {
        _evidence(flip: true);
        return;
      }
    } else if (d.dx.abs() >= 60 && d.dx.abs() > d.dy.abs()) {
      _evidence(flip: false);
      return;
    }
    _hints.missTap();
  }

  /// The decisive control: the flip or the pan (waits for him).
  void _evidence({required bool flip}) {
    if (!_live || _phase != _Ph.evidence) return;
    if (_atHisRound && !coworkerDone && !coworkerDue) scheduleCoworker();
    if (holdForCoworker()) return;
    _tickSound('sounds/intro/click.ogg', 0.5);
    HapticFeedback.mediumImpact();
    setState(() {
      _setPhase(_Ph.moving);
      _wake++;
    });
    _later(_quiet ? 0 : (flip ? 520 : 1000), () {
      if (_ended) return;
      setState(() {
        _setPhase(_Ph.table);
        _wake++;
      });
      unawaited(_sayChain([M8BillListenLines.tapFacts]));
    });
  }

  void _judge(M8BillZone z, Offset p) {
    final (res, m) = _run.tap(z);
    final origin = _toGlobal(p);
    if (res == M8BillTap.wrong) {
      if (m == null) return;
      setState(() => _wake++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      unawaited(_slip(m));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _hush();
    setState(() {
      _setPhase(_Ph.reply);
      _replied = true;
      _wake++;
    });
    _caption.value++;
    putOnTable(15);
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M8BillListenLines.whyRight[z]!, M8BillListenLines.whyWrong(z), widget.rng),
      question: M8BillListenLines.whyQ(z),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Offset _toGlobal(Offset design) {
    final size = MediaQuery.sizeOf(context);
    final k = size.width / 360;
    return design * k;
  }

  Future<void> _goNext() async {
    if (_ended) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _ended) return;
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    if (mounted) unawaited(_goNext());
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8BillListenLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // Too late once his round is past, or its flip/pan has begun.
    if (_ended || struckOut || _run.done || _run.index > _run.deal.coworkerRound) return null;
    if (_atHisRound && (_phase == _Ph.moving || _phase == _Ph.table || _phase == _Ph.reply)) return null;
    if (!_atHisRound || _phase != _Ph.evidence || _intro || _card != null || tableBusy) return false;
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
      setState(() => _storm = true);
      _caption.value++;
      _afterCards = () {
        setState(() => _storm = false);
        _caption.value++;
        unawaited(_sayChain([M8BillListenLines.tapPaper]));
      };
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M8BillListenLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8BillListenLines.callHeld, M8BillListenLines.tapPaper], mood: GuideMood.glad));
  }

  /// Tap the guide: the next task line of the pool, never the answer.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8BillListenLines.tapWhy[_whyN++ % M8BillListenLines.tapWhy.length]
            : M8BillListenLines.tasks[++_taskN % M8BillListenLines.tasks.length];
    _tickSound('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _tick?.cancel();
    _clock.stop();
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
      _dragFrom = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8bill/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    final after = _afterCards;
    _afterCards = null;
    if (after != null) {
      after();
      return;
    }
    unawaited(_sayChain([_phase == _Ph.table ? M8BillListenLines.tapFacts : M8BillListenLines.askListen]));
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
    _tick?.cancel();
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
    await _say(!_run.passed ? M8BillListenLines.fail : (_quickBonus ? M8BillListenLines.quick : M8BillListenLines.allSet),
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
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_replied) return LinemanMode.talk;
    if (_padHeld && _phase == _Ph.rant) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M8BillMood get _mood {
    if (_storm) return M8BillMood.storm;
    if (_replied) return M8BillMood.calm;
    return switch (_phase) {
      _Ph.arrive => M8BillMood.pause,
      _Ph.rant => _rant.inPause ? M8BillMood.pause : M8BillMood.rant,
      _ => _run.round.flips ? M8BillMood.holdOut : M8BillMood.point,
    };
  }

  /// The gesture hand: how to touch, never what.
  bool get _hintLive {
    if (_intro || _ended || _card != null || coworkerOpen || reasonOpen || tableBusy || struckOut || _mark != null) return false;
    return switch (_phase) {
      _Ph.rant => _rant.waiting && !_padHeld,
      _Ph.evidence => true,
      _Ph.table => true,
      _ => false,
    };
  }

  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_phase) {
      case _Ph.rant:
        return HintSpec.hold(geo.padCentre, space: HintSpace.scene);
      case _Ph.evidence:
        return _run.round.flips
            ? HintSpec.swipe(geo.billHand.center, toward: const Offset(0, -1), travel: 64, space: HintSpace.scene)
            : HintSpec.swipe(geo.sceneCentre, toward: const Offset(-1, 0), travel: 90, space: HintSpace.scene);
      case _Ph.table:
        return HintSpec.sweep([for (final z in M8BillZone.values) geo.zone(z, unitFirst: _run.round.unitFirst)], space: HintSpace.scene);
      default:
        return null;
    }
  }

  Widget _bubble(M8BillGeo geo) {
    return ValueListenableBuilder<int>(
      valueListenable: _caption,
      builder: (context, _, _) {
        final String text;
        var closed = false;
        var reply = false;
        if (_replied) {
          text = M8BillListenLines.reply;
          reply = true;
        } else if (_storm) {
          text = M8BillListenLines.storm;
          closed = true;
        } else if (_phase == _Ph.arrive || _phase == _Ph.table || _phase == _Ph.moving) {
          text = _phase == _Ph.arrive ? '' : _rant.round.bursts.last;
          closed = true;
        } else if (_rant.waiting) {
          text = M8BillListenLines.areYouListening;
        } else if (_phase == _Ph.rant) {
          text = _rant.shown;
        } else {
          text = _rant.round.bursts.last;
          closed = true;
        }
        if (text.isEmpty) return const SizedBox.shrink();
        return _Bubble(text: text, closed: closed, reply: reply, loud: _rant.louder && !reply);
      },
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8BillGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final i = math.min(_run.index, _run.deal.rounds.length - 1);
    final r = _run.deal.rounds[i];
    final look = kM8BillLooks[r.look];
    final moving = _phase == _Ph.moving;
    final panned = !r.flips && (_phase == _Ph.moving || _phase == _Ph.table || _phase == _Ph.reply);
    final panelVisible = r.flips ? (_phase == _Ph.table || _phase == _Ph.reply || moving) : (_phase == _Ph.table || _phase == _Ph.reply);
    return [
      Positioned.fill(
        key: const ValueKey('back'),
        child: RepaintBoundary(child: CustomPaint(painter: M8BillBackPainter(geo: geo, light: _run.deal.light))),
      ),
      // The place; at the office the camera slides to the notice board.
      Positioned.fill(
        key: ValueKey('place-$i'),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: panned ? 1 : 0),
          duration: quiet ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (_, pan, _) => RepaintBoundary(child: CustomPaint(painter: M8BillPlacePainter(geo: geo, place: r.place, pan: pan))),
        ),
      ),
      // The figures slide out with the camera at the office.
      Positioned.fill(
        key: ValueKey('figures-$i'),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: panned ? 1 : 0),
          duration: quiet ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (_, pan, child) => Transform.translate(offset: Offset(-360 * pan, 0), child: child),
          child: Stack(
            children: [
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              _consumer(geo, look, i),
            ],
          ),
        ),
      ),
      if (panelVisible)
        Positioned.fromRect(
          key: ValueKey('panel-$i'),
          rect: geo.panel,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: quiet ? Duration.zero : Duration(milliseconds: r.flips ? 480 : 900),
            curve: Curves.easeOut,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.scale(scale: r.flips ? 0.45 + 0.55 * v : 1, child: child),
            ),
            child: _TariffPaper(geo: geo, unitFirst: r.unitFirst, onBoard: !r.flips),
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('bubble'),
        rect: geo.bubble,
        child: IgnorePointer(child: _bubble(geo)),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8BillListenLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(geo),
            onPanCancel: () => _dragFrom = null,
          ),
        ),
      ),
      // The listen pad: a Listener (press and release are the whole verb).
      Positioned.fromRect(
        key: const ValueKey('pad'),
        rect: geo.pad,
        child: Semantics(
          label: M8BillListenLines.padWord,
          button: true,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _padDown(),
            onPointerUp: (_) => _padUp(),
            onPointerCancel: (_) => _padUp(),
            child: _ListenPad(held: _padHeld, live: _phase == _Ph.rant || _phase == _Ph.arrive || _phase == _Ph.endHeld),
          ),
        ),
      ),
      // The next round: a short fade in reduced motion.
      if (quiet && !_intro)
        Positioned.fill(
          key: ValueKey('fade-$i'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: i == 0 ? 0 : 0.5, end: 0),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  Widget _consumer(M8BillGeo geo, M8BillLook look, int i) {
    final r = _run.deal.rounds[i];
    final child = Positioned.fromRect(
      key: ValueKey('consumer-$i'),
      rect: geo.consumer,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: M8ConsumerPainter(
            look: look,
            mood: _mood,
            bill: r.flips && !_replied && _phase != _Ph.moving && _phase != _Ph.table,
            louder: _rant.louder,
            beat: _beat,
          ),
        ),
      ),
    );
    if (_phase != _Ph.arrive || _quiet) return child;
    // He walks in from the right edge.
    return Positioned.fill(
      key: ValueKey('walk-$i'),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOut,
        builder: (_, v, c) => Transform.translate(offset: Offset(150 * v, 0), child: c),
        child: Stack(children: [child]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final guideBottom = pad.bottom * 0.6 + 4;
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
              labels: [for (final r in _run.deal.rounds) M8BillListenLines.placeName(r.place)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: _hintLive,
            hintKey: '${_run.index}/${_phase.name}/${_run.slips}/${_rant.waiting}',
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
                  line: M8BillListenLines.intro,
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

/// A caption bubble: open (dashed look, '…' possible) while he talks, closed
/// (solid) at his real end; the trainee's reply is blue.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.closed, required this.reply, required this.loud});
  final String text;
  final bool closed;
  final bool reply;
  final bool loud;

  @override
  Widget build(BuildContext context) {
    final border = reply ? const Color(0xFF1F5F8F) : (loud ? const Color(0xFFC62828) : const Color(0xFF5B4A3A));
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: reply ? const Color(0xFFEAF3FA) : const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border.withValues(alpha: closed || reply ? 1 : 0.55), width: closed || reply ? 2.4 : 1.4),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: bangla(fontSize: loud ? 17 : 15, fontWeight: loud ? FontWeight.w900 : FontWeight.w800, color: const Color(0xFF26201A), height: 1.3),
          ),
        ),
      ),
    );
  }
}

/// The round 'শুনছি' pad with an ear.
class _ListenPad extends StatelessWidget {
  const _ListenPad({required this.held, required this.live});
  final bool held;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: live ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: held ? const [Color(0xFFE9C46A), Color(0xFFC48A2E)] : const [Color(0xFF2F4F7E), Color(0xFF1A2F52)],
          ),
          border: Border.all(color: SlmColors.gold300, width: held ? 3.4 : 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hearing_rounded, size: 28, color: held ? const Color(0xFF3A2A16) : SlmColors.ivory),
            const SizedBox(height: 1),
            Text(M8BillListenLines.padWord, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: held ? const Color(0xFF3A2A16) : SlmColors.ivory, height: 1.0)),
          ],
        ),
      ),
    );
  }
}

/// The tariff table: a bill's back or the notice board's paper. Three equal,
/// alike zones (the header on top); figures are greyed bars.
class _TariffPaper extends StatelessWidget {
  const _TariffPaper({required this.geo, required this.unitFirst, required this.onBoard});
  final M8BillGeo geo;
  final bool unitFirst;
  final bool onBoard;

  @override
  Widget build(BuildContext context) {
    final t = geo.table;
    final p = geo.panel;
    Widget zone(M8BillZone z) {
      final header = z == M8BillZone.header;
      return Expanded(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF6E6),
            border: Border(bottom: BorderSide(color: Color(0xFF8A7A5A), width: 1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: header
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(M8BillListenLines.zoneLabel(z), style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF26201A))),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(M8BillListenLines.zoneLabel(z), style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF26201A))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final w in const [22.0, 14.0]) ...[
                        Container(width: w, height: 10, decoration: BoxDecoration(color: const Color(0xFFB8B2A2), borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
          ),
        ),
      );
    }

    final order = [M8BillZone.header, if (unitFirst) ...[M8BillZone.unit, M8BillZone.fixed] else ...[M8BillZone.fixed, M8BillZone.unit]];
    return Semantics(
      label: onBoard ? 'নোটিশ বোর্ড' : M8BillListenLines.billWord,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: onBoard ? const Color(0xFF3F7A5B) : const Color(0xFFF4EEDA),
                borderRadius: BorderRadius.circular(onBoard ? 8 : 6),
                border: Border.all(color: onBoard ? const Color(0xFF7A5A34) : const Color(0xFF8A7A5A), width: onBoard ? 5 : 2),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
            ),
          ),
          Positioned.fromRect(
            rect: t.shift(-p.topLeft),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8A7A5A), width: 1.4)),
              child: Column(children: [for (final z in order) zone(z)]),
            ),
          ),
        ],
      ),
    );
  }
}
