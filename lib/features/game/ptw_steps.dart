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
import 'level_juice.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'ptw_yard.dart';
import 'reason_table.dart';
import 'scene_kit.dart';
import 'spoken_once.dart';

// Lesson 1.6, কাজ 2: "সোনালি ধাপ ও লাইন ক্লিয়ার" — the order move, done on a
// drawn shutdown site (ptw_yard.dart). The player does each step by tapping
// what it needs in the scene: the supervisor's phone, the breaker in the
// control-room window, the permit book, the clipboard, the rod and tester,
// the team, the van.
//
// Round 1, the permit's golden steps (lesson 1.6 point 2): request (phone) →
// isolation + LOTO (the breaker goes OFF, lock and tag) → the permit number
// (the operator's book) → the team receives the paper (clipboard) → discharge
// & test (one step, as the lesson lists it: rod + tester on the line) → start
// work (the team climbs).
// Round 2, line clear (point 3): everyone down (tap each worker on the
// ladder), then the discharge/earth rod off the line (lesson 10.6: people
// down first, the earth comes off last — taking it off with men aloft is a
// slip) → "line clear" call (phone) → permit returned (clipboard or book) →
// LOTO off (breaker).
//
// Starting work is never a single tap on people: tapping the team raises an
// "উঠতে বলুন" button and only that sends them up.
//
// Deadly (owner decisions 2026-11-08): starting work with no signed permit in
// hand (a verbal permit), or before the discharge & test — also by listening
// to the coworker's "permit = 100% safe" myth, which comes right after the
// paper arrives (MODULE1_LADDER.md step 18: the act he pushes, skipping the
// test, is on the owner's deadly list). He can't be skipped by playing fast:
// the rod (the test) and the climb wait for him ([holdForCoworker]); after the
// test his push no longer fits and he does not come. Slips: any other step
// out of order; leaving in the van before the permit is returned (lesson: "a
// serious offence" — a slip with its own card, by decision).
//
// Gesture hint: while the site waits, a sweep over every thing on it (left to
// right, never the step order); taps on nothing count as misses.
//
// Voice: the guide on device TTS (every fixed line in StepLines); the
// coworker in his recorded voice. Mistake pictures: assets/game/art/ptw/
// (+ the 1.5 clock picture for skipping the test).

// ============================================================================
// Content
// ============================================================================

/// A step card (an older order deck). Kept: fire_pass.dart and
/// golden_minute.dart build their decks from it.
@immutable
class StepCard {
  const StepCard(this.id, this.titleBn, this.subBn, this.icon);
  final String id;
  final String titleBn;
  final String subBn;
  final IconData icon;
}

abstract final class StepIds {
  static const request = 'request';
  static const isolate = 'isolate';
  static const issue = 'issue';
  static const receive = 'receive';
  static const test = 'test';
  static const start = 'start';
  static const count = 'count';
  static const tools = 'tools';
  static const clear = 'clear';
  static const cancel = 'cancel';
  static const unlock = 'unlock';
  static const leave = 'leave';

  /// Worker [i] climbs down (round 2).
  static String worker(int i) => 'down$i';

  static const permit = [request, isolate, issue, receive, test, start];
  static const clearAfter = [clear, cancel, unlock];
}

/// The things on the site the player can tap.
enum PtwThing { phone, breaker, book, clipboard, rod, crew, worker, van }

/// The reason decks (the milestones of the job).
enum PtwWhy { isolate, receive, test, count, giveBack }

abstract final class StepLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askPermit, askClear];

  static const title = 'সোনালি ধাপ';
  static const intro = 'আজ শাটডাউনের কাজ! পারমিট নেওয়া থেকে লাইন ক্লিয়ার — একটা ধাপও বাদ নয়।';
  static const rounds = ['পারমিট', 'লাইন ক্লিয়ার'];
  static const askPermit = 'কাজ শুরুর আগে পারমিটের পরের ধাপটা কী? যা লাগে, ট্যাপ করুন।';
  static const askClear = 'কাজ শেষ। লাইন ক্লিয়ারের পরের ধাপটা কী? যা লাগে, ট্যাপ করুন।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const permitDone = 'পারমিটের সোনালি ধাপ সম্পূর্ণ! দল এবার লাইনে।';
  static const ok = [FeedbackLine('ঠিক!'), FeedbackLine('এটাই পরের ধাপ।'), FeedbackLine('বেশ!')];
  static const allSet = 'নেওয়া থেকে ফেরত — পুরো পারমিট চক্র পাকা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কোন ধাপের পরে কোনটা, মনে রেখে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtTest = 'পারমিটের পরেও ডিসচার্জ-টেস্ট';
  static const caughtCount = 'লাইন ক্লিয়ারের আগে দল গোনা';
  static const caughtReturn = 'পারমিট ফেরত দিয়ে তবে ফেরা';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// The button that sends the team up the ladder (after a tap on them).
  static const climbAsk = 'উঠতে বলুন';
  static const feeders = ['রামপুর 11 kV', 'হাটখোলা 11 kV', 'নদীপাড় 11 kV', 'স্টেশন রোড 11 kV'];

  // Labels a worker would read on the site, and the things' names (for
  // screen readers).
  static const controlRoom = 'কন্ট্রোল রুম';
  static const on = 'ON';
  static const off = 'OFF';
  static const ptw = 'PTW';
  static String permitNo(int n) => 'No. ${enDigits('$n')}';
  static const cancelled = 'বাতিল';
  static const dead = 'ডেড ✓';
  static String down(int n, int of) => enDigits('নিচে $n/$of');
  static const phone = 'ফোন';
  static const breaker = 'ব্রেকার';
  static const book = 'পারমিট বই';
  static const clipboard = 'পারমিট';
  static const rod = 'রড ও টেস্টার';
  static const crew = 'দল';
  static String worker(int i) => 'কর্মী ${enDigits('${i + 1}')}';
  static const van = 'ভ্যান';

  // The reasons (lesson 1.6): the right ones fit the step just done; the
  // wrong ones are the other steps' reasons (true in the lesson, wrong for
  // this step) and the field's myths. Every card is 42–50 letters.
  static String whyAsk(PtwWhy w) => switch (w) {
        PtwWhy.isolate => 'কেন তালা আর ট্যাগ?',
        PtwWhy.receive => 'কেন কাগজটা হাতে নেওয়া জরুরি?',
        PtwWhy.test => 'পারমিট তো হাতে — তবু টেস্ট কেন?',
        PtwWhy.count => 'কেন সবাইকে গুনে নামালেন?',
        PtwWhy.giveBack => 'কেন পারমিট ফেরত দিলেন?',
      };

  static List<String> whyRight(PtwWhy w) => switch (w) {
        PtwWhy.isolate => const ['তালা থাকলে কেউ ভুল করে ব্রেকার চালু করতে পারবে না', 'ট্যাগে লেখা থাকে কেন বন্ধ, কার অনুমতিতে খোলা যাবে'],
        PtwWhy.receive => const [
            'হাতে স্বাক্ষরিত PTW ছাড়া কাজ শুরু করা যায় না',
            'ফোনে বলা ‘লাইন বন্ধ’ কথার কোনো সুরক্ষা ভিত্তি নেই',
            'PTW-তে লেখা ফিডার আর এই লাইন মিলিয়ে নিতে হবে',
          ],
        PtwWhy.test => const [
            'ভুল করে অন্য কোনো ফিডার বন্ধ হয়ে থাকতে পারে',
            'লাইনে ইন্ডুসড ভোল্টেজ থেকে যেতে পারে, যাচাই চাই',
            'পারমিটে বিশ্বাস, কিন্তু টেস্ট করে যাচাই করতে হয়',
          ],
        PtwWhy.count => const ['কেউ পোলে থেকে গেলে লাইন চালু হবে তার ওপরেই', 'লাইন ক্লিয়ারের আগে নিশ্চিত হতে হয় সবাই নিরাপদ'],
        PtwWhy.giveBack => const ['ফেরত না দিলে কন্ট্রোল রুম ভাববে কাজ এখনও চলছে', 'যার নামে পারমিট ইস্যু, ফেরত দেওয়ার দায়ও তারই'],
      };

  /// The lesson's myths and field excuses: wrong for every step.
  static const myths = [
    'সুপারভাইজার পারমিট নিয়েছেন, আমার ভাবার কিছু নেই',
    'পারমিট নেওয়া মানেই লাইন পুরোপুরি নিরাপদ হয়ে গেছে',
    'ফোনে লাইন বন্ধ শুনলেই সোজা কাজ শুরু করা যায়',
    'নিয়মটা শুধু অফিসের কাগজপত্র ঠিক রাখার জন্য',
    'এভাবে করলে কাজটা অনেক তাড়াতাড়ি শেষ হয়ে যায়',
  ];

  /// Other steps' reasons that also answer this deck's question (so they are
  /// never dealt as its wrong cards): the feeder check sits on both the paper
  /// and the test; a lock also keeps a man aloft from being switched on.
  static const notWrong = <PtwWhy, List<String>>{
    PtwWhy.isolate: ['কেউ পোলে থেকে গেলে লাইন চালু হবে তার ওপরেই'],
    PtwWhy.receive: ['ভুল করে অন্য কোনো ফিডার বন্ধ হয়ে থাকতে পারে'],
    PtwWhy.test: ['PTW-তে লেখা ফিডার আর এই লাইন মিলিয়ে নিতে হবে'],
  };

  static List<String> whyWrong(PtwWhy w) => [
        for (final o in PtwWhy.values)
          if (o != w)
            for (final r in whyRight(o))
              if (!(notWrong[w]?.contains(r) ?? false)) r,
        ...myths,
      ];

  /// The careless coworker (his recorded voice): the lesson's myth, right
  /// after the permit is in hand.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'পারমিট নেওয়া হয়ে গেছে মানে লাইন 100% নিরাপদ। আর টেস্ট করার কী দরকার?',
    exitLine: coworkerExit,
    right: ['না, পারমিট থাকলেও আগে ডিসচার্জ আর টেস্ট', 'অন্য ফিডার বন্ধ হতে পারে, আগে টেস্ট করব', 'বিশ্বাস করি, তবু টেস্ট করে যাচাই করব'],
    wrong: [
      'ঠিক, পারমিট আছে, সোজা কাজে লেগে যাই',
      'ঠিক আছে, টেস্ট বাদ দিয়েই উঠে পড়ি',
      'পারমিট মানেই লাইন ডেড, টেস্ট লাগে না',
      'সবাই তো টেস্ট ছাড়াই কাজ শুরু করে দেয়',
      'সময় নেই ভাই, আজ টেস্টটা বাদই থাক',
    ],
    asks: [
      'ও বলছে টেস্ট লাগবে না। আপনি কী করবেন?',
      'পারমিট হাতে — সোজা কাজ, না আগে টেস্ট?',
      'কার কথা শুনবেন — ওর, না নিয়মের?',
    ],
  );
  static const callHeld = 'ঠিক! পারমিটে বিশ্বাস, তবু টেস্ট করে যাচাই।';
}

abstract final class StepMistakes {
  static const noPermit = DoMistake(
    key: '1.6/steps/no-permit',
    textBn: 'হাতে স্বাক্ষরিত PTW আসার আগেই কাজ শুরু — অনুরোধ, ফোন বা মুখের কথা পারমিট নয়। হাতে স্বাক্ষরিত PTW ছাড়া লাইনে হাত নয়।',
    art: 'assets/game/art/ptw/verbal_vs_written.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const skipTest = DoMistake(
    key: '1.6/steps/skip-test',
    textBn: 'পারমিট মানেই 100% নিরাপদ নয় — ভুল করে অন্য ফিডার বন্ধ হতে পারে, ইন্ডুসড ভোল্টেজ থাকতে পারে। ডিসচার্জ আর টেস্ট করে তবে কাজ।',
    art: 'assets/game/art/discharge/five_min.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const permitOrder = DoMistake(
    key: '1.6/steps/permit-order',
    textBn: 'ধাপ উল্টে গেল — অনুরোধ, আইসোলেশন আর LOTO, পারমিট নম্বর, পারমিট হাতে, ডিসচার্জ-টেস্ট, তারপর কাজ।',
    art: 'assets/game/art/ptw/golden_steps.svg',
    lessonPoint: 1,
  );
  static const clearEarly = DoMistake(
    key: '1.6/steps/clear-early',
    textBn: 'দল না গুনে লাইন ক্লিয়ারের ধাপ — কেউ পোলে থাকলে লাইন চালু হবে তার ওপরেই। আগে সবাই নিচে, মাথা গুনে।',
    art: 'assets/game/art/ptw/line_clear.svg',
    lessonPoint: 2,
  );
  static const earthEarly = DoMistake(
    key: '1.6/steps/earth-early',
    textBn: 'ওপরে কর্মী থাকতেই আর্থ রড খোলা — খুব বিপজ্জনক। আগে সবাই নিচে, মাথা গুনে, তারপর সবার শেষে আর্থ খোলা।',
    art: 'assets/game/art/ptw/line_clear.svg',
    lessonPoint: 2,
  );
  static const toolsLeft = DoMistake(
    key: '1.6/steps/tools-left',
    textBn: 'লাইনে যন্ত্রপাতি রেখেই লাইন ক্লিয়ারের ধাপ — আগে সব যন্ত্রপাতি সরিয়ে, তবে লাইন ক্লিয়ার।',
    art: 'assets/game/art/ptw/line_clear.svg',
    lessonPoint: 2,
  );
  static const clearOrder = DoMistake(
    key: '1.6/steps/clear-order',
    textBn: 'লাইন ক্লিয়ারের ধাপ উল্টে গেল — সবাই নিচে আর যন্ত্র সরানো, লাইন ক্লিয়ার ফোন, পারমিট ফেরত, তারপর LOTO খোলা।',
    art: 'assets/game/art/ptw/line_clear.svg',
    lessonPoint: 2,
  );
  static const leftWithPermit = DoMistake(
    key: '1.6/steps/left-with-permit',
    textBn: 'পারমিট ফেরত না দিয়ে ফিল্ড ছেড়ে চলে যাওয়া একটি গুরুতর অপরাধ — কন্ট্রোল রুম ধরে নেবে লাইনে এখনও কাজ চলছে।',
    art: 'assets/game/art/ptw/line_clear.svg',
    lessonPoint: 2,
  );
  static const all = [noPermit, skipTest, permitOrder, clearEarly, earthEarly, toolsLeft, clearOrder, leftWithPermit];
}

/// The play state: what is done, slips, the deadly end. Pure logic.
class PtwStepsRun {
  PtwStepsRun({required this.crew}) : assert(crew >= 2 && crew <= 3);

  /// A fresh play: 2 or 3 climb (the page's first draw from [rng]).
  factory PtwStepsRun.deal(math.Random rng) => PtwStepsRun(crew: 2 + rng.nextInt(2));

  /// Workers who climb (the trainee is the first).
  final int crew;

  /// 0 = the permit, 1 = line clear, 2 = done.
  int round = 0;
  final Set<String> _done = {};
  int slips = 0;
  DoMistake? deadly;

  /// "আজ যা ধরলেন".
  final List<String> caught = [];

  bool get done => round >= 2;
  bool get ended => done || deadly != null;
  bool isDone(String id) => _done.contains(id);
  int get down => [for (var i = 0; i < crew; i++) if (_done.contains(StepIds.worker(i))) i].length;
  bool get allDown => down == crew;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The next golden step (round 1).
  String? get nextPermit => round == 0 ? StepIds.permit.firstWhere((s) => !_done.contains(s)) : null;

  OrderTap tap(String id) {
    if (ended || _done.contains(id)) return const OrderTap(OrderTapKind.ignored);
    if (round == 0) {
      if (!StepIds.permit.contains(id)) return const OrderTap(OrderTapKind.ignored);
      if (id == nextPermit) {
        _done.add(id);
        if (id != StepIds.start) return const OrderTap(OrderTapKind.ok);
        round = 1;
        return const OrderTap(OrderTapKind.ok, roundDone: true);
      }
      if (id == StepIds.start) return _mistake(_done.contains(StepIds.receive) ? StepMistakes.skipTest : StepMistakes.noPermit);
      return _mistake(StepMistakes.permitOrder);
    }
    if (id == StepIds.leave) return _done.contains(StepIds.cancel) ? const OrderTap(OrderTapKind.ignored) : _mistake(StepMistakes.leftWithPermit);
    if (id.startsWith('down')) {
      _done.add(id);
      return const OrderTap(OrderTapKind.ok);
    }
    if (id == StepIds.tools) {
      // The earth comes off last, with everyone down (lesson 10.6).
      if (!allDown) return _mistake(StepMistakes.earthEarly);
      _done.add(id);
      return const OrderTap(OrderTapKind.ok);
    }
    if (!StepIds.clearAfter.contains(id)) return const OrderTap(OrderTapKind.ignored);
    if (!allDown) return _mistake(StepMistakes.clearEarly);
    if (!_done.contains(StepIds.tools)) return _mistake(StepMistakes.toolsLeft);
    if (id != StepIds.clearAfter.firstWhere((s) => !_done.contains(s))) return _mistake(StepMistakes.clearOrder);
    _done.add(id);
    if (id != StepIds.unlock) return const OrderTap(OrderTapKind.ok);
    round = 2;
    return const OrderTap(OrderTapKind.ok, roundDone: true, allDone: true);
  }

  /// A deadly answer outside the site (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  OrderTap _mistake(DoMistake m) {
    if (m.deadly) {
      deadly = m;
    } else {
      slips++;
    }
    return OrderTap(OrderTapKind.mistake, mistake: m);
  }
}

/// What a tap on [thing] means in [round] (null: nothing now).
String? stepFor(PtwThing thing, int round, {int worker = 0}) => switch ((thing, round)) {
      (PtwThing.phone, 0) => StepIds.request,
      (PtwThing.breaker, 0) => StepIds.isolate,
      (PtwThing.book, 0) => StepIds.issue,
      (PtwThing.clipboard, 0) => StepIds.receive,
      (PtwThing.rod, 0) => StepIds.test,
      (PtwThing.crew, 0) => StepIds.start,
      (PtwThing.worker, 1) => StepIds.worker(worker),
      (PtwThing.rod, 1) => StepIds.tools,
      (PtwThing.phone, 1) => StepIds.clear,
      (PtwThing.clipboard, 1) || (PtwThing.book, 1) => StepIds.cancel,
      (PtwThing.breaker, 1) => StepIds.unlock,
      (PtwThing.van, 1) => StepIds.leave,
      _ => null,
    };

@immutable
class StepsPack {
  const StepsPack({required this.id, required this.titleBn, this.quickMs = 120000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const stepsPack16 = StepsPack(id: 'do_1_6_b', titleBn: StepLines.title);
const stepsPacks = {'do_1_6_b': stepsPack16};

// ============================================================================
// Page
// ============================================================================

class PtwStepsPage extends StatefulWidget {
  const PtwStepsPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final StepsPack pack;
  final bool muted;
  final int? seed;

  @override
  State<PtwStepsPage> createState() => _PtwStepsPageState();
}

class _PtwStepsPageState extends State<PtwStepsPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _StepsRunPage(
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

class _StepsRunPage extends ConsumerStatefulWidget {
  const _StepsRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final StepsPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_StepsRunPage> createState() => _StepsRunPageState();
}

class _StepsRunPageState extends ConsumerState<_StepsRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();

  // The deal (in this order): how many climb, the feeder, the permit's number.
  late final PtwStepsRun _run;
  late final String _feeder;
  late final int _permitNo;

  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _okBag = LineBag(StepLines.ok);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
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

  /// Bumped on every move: the people animate a moment.
  int _wake = 0;

  /// Phone calls made (keys the call chip), and whether one is on now.
  int _calls = 0;

  /// After a paid reason: what comes next.
  VoidCallback? _afterPaid;

  /// The gesture hint (taps on nothing are reported to it).
  final _hints = IdleHintController();

  /// The things on the site now (design px), left to right: the hint's sweep.
  List<Rect> _hintRects = const [];

  /// A deadly start: the team goes up the ladder, then the site freezes.
  var _climbAll = false;
  var _freeze = false;
  Completer<void>? _frozen;

  /// The thing just tapped wrong (it shakes).
  PtwThing? _shook;
  int _shakes = 0;

  /// The team was tapped (round 1): the "উঠতে বলুন" button is up.
  var _climbAsk = false;

  /// The operator answers a step done in the control room (a short pose,
  /// only after the player's tap — never while a step waits).
  int _opAct = 0;
  var _opBusy = false;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  String get _task => _run.round == 0 ? StepLines.askPermit : StepLines.askClear;

  @override
  void initState() {
    super.initState();
    _run = PtwStepsRun.deal(widget.rng);
    _feeder = StepLines.feeders[widget.rng.nextInt(StepLines.feeders.length)];
    _permitNo = 1000 + widget.rng.nextInt(9000);
  }

  @override
  void dispose() {
    disposeCoworker();
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

  /// After the guide's intro: the clock runs and the first task is said.
  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([StepLines.askPermit]));
  }

  /// The site takes a tap: never in a praise window or while a deck is up
  /// ([tableBusy]), nor while the coworker is in.
  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen;

  // --- the moves ---------------------------------------------------------------
  /// A tap on the standing team: the button that sends them up (again: away).
  void _tapCrew() {
    if (!_canPlay || _run.round != 0) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', 0.5);
    setState(() => _climbAsk = !_climbAsk);
  }

  void _tapThing(PtwThing thing, Offset origin, {int worker = 0}) {
    if (!_canPlay) return;
    if (_climbAsk) setState(() => _climbAsk = false);
    final id = stepFor(thing, _run.round, worker: worker);
    if (id == null || _run.isDone(id)) {
      _hints.missTap();
      return;
    }
    // The test (or the climb) would end his moment: he comes first.
    if ((id == StepIds.test || id == StepIds.start) && holdForCoworker()) return;
    final t = _run.tap(id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        _hints.missTap();
        return;
      case OrderTapKind.mistake:
        final m = t.mistake!;
        setState(() {
          _shook = thing;
          _shakes++;
        });
        if (m.deadly) {
          unawaited(_deadly(m));
        } else {
          unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
          unawaited(_slip(m));
        }
      case OrderTapKind.ok:
        _did(id, t, origin);
    }
  }

  void _cue(String asset, [double volume = 0.6]) {
    if (!_muted) unawaited(ZlFx.cue(asset, volume: volume, muted: false));
  }

  /// A right step: its sound and motion, then its points or its reason deck.
  void _did(String id, OrderTap t, Offset origin) {
    HapticFeedback.lightImpact();
    _hush();
    setState(() {
      _wake++;
      _shook = null;
      if (id == StepIds.request || id == StepIds.clear) _calls++;
    });
    if (const [StepIds.isolate, StepIds.issue, StepIds.cancel, StepIds.unlock].contains(id)) _operatorAnswers();
    switch (id) {
      case StepIds.request || StepIds.clear:
        _cue('sounds/quiz_select.wav');
        _praise(origin);
      case StepIds.isolate:
        _cue('sounds/intro/impact_metal.ogg', 0.7);
        _cue('sounds/learn/tag_slap.wav', 0.5);
        _ask(PtwWhy.isolate);
      case StepIds.issue:
        _cue('sounds/quiz_flip.wav');
        _praise(origin);
      case StepIds.receive:
        _cue('sounds/quiz_flip.wav');
        _ask(PtwWhy.receive, then: _armCoworker);
      case StepIds.test:
        _cue('sounds/learn/tock.wav', 0.7);
        if (!_run.caught.contains(StepLines.caughtTest)) _run.caught.add(StepLines.caughtTest);
        _ask(PtwWhy.test);
      case StepIds.start:
        _cue('sounds/learn/stomp.wav', 0.4);
        unawaited(_levelDelta(15, origin, mood: GuideMood.glad));
        unawaited(_toLineClear());
      case StepIds.tools:
        _cue('sounds/intro/drop.ogg');
        _praise(origin);
      case StepIds.cancel:
        _cue('sounds/quiz_flip.wav');
        if (!_run.caught.contains(StepLines.caughtReturn)) _run.caught.add(StepLines.caughtReturn);
        _ask(PtwWhy.giveBack);
      case StepIds.unlock:
        _cue('sounds/intro/impact_metal.ogg', 0.6);
        unawaited(_levelDelta(15, origin, mood: GuideMood.celebrate));
        unawaited(_wrapUp());
      default:
        // A worker comes down the ladder; the last one: the head count's reason.
        _cue('sounds/learn/stomp.wav', 0.35);
        if (_run.allDown) {
          if (!_run.caught.contains(StepLines.caughtCount)) _run.caught.add(StepLines.caughtCount);
          _ask(PtwWhy.count);
        }
    }
  }

  /// The operator talks a moment (he did what the player's tap asked).
  void _operatorAnswers() {
    final n = ++_opAct;
    setState(() => _opBusy = true);
    unawaited(Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && n == _opAct) setState(() => _opBusy = false);
    }));
  }

  void _praise(Offset origin) {
    unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
    unawaited(_sayChain([_okBag.next().shownBn], mood: GuideMood.glad));
  }

  /// A milestone: its ◆ wait on the table, then "কেন …?"; [then] once paid.
  void _ask(PtwWhy why, {VoidCallback? then}) {
    _afterPaid = then;
    putOnTable(5);
    unawaited(askReason(
      deal: () => dealChoices(StepLines.whyRight(why), StepLines.whyWrong(why), widget.rng),
      question: StepLines.whyAsk(why),
      stillValid: () => !_ended,
    ));
  }

  /// Round 1 done: the team climbs, a moment of work, then line clear.
  Future<void> _toLineClear() async {
    setState(() => _busy = true);
    unawaited(_sayChain([StepLines.permitDone], mood: GuideMood.glad));
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 2600));
    if (!mounted || _ended) return;
    setState(() {
      _busy = false;
      _wake++;
    });
    unawaited(_sayChain([StepLines.askClear]));
  }

  /// LOTO off: a beat on the clear site, then the result.
  Future<void> _wrapUp() async {
    setState(() => _busy = true);
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 900));
    if (!mounted) return;
    await _finish();
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
    final then = _afterPaid;
    _afterPaid = null;
    setState(() {});
    if (then != null) {
      then();
      return;
    }
    unawaited(_sayChain([_task]));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  /// The permit is in hand: he comes a moment from now; the test and the
  /// climb wait for him ([holdForCoworker] in [_tapThing]).
  void _armCoworker() {
    if (coworkerDone) {
      unawaited(_sayChain([_task]));
      return;
    }
    scheduleCoworker();
  }

  @override
  CoworkerScript get coworkerScript => StepLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // "Why test?" fits only between the paper in hand and the test.
    if (_ended || _run.round != 0 || !_run.isDone(StepIds.receive) || _run.isDone(StepIds.test)) return null;
    if (_intro || _busy || _card != null || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the team goes up untested — deadly.
      _run.failDeadly(StepMistakes.skipTest);
      await _deadly(StepMistakes.skipTest);
      return;
    }
    _run.caught.add(StepLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([StepLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? StepLines.tapWhy[_nudgeN++ % StepLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  /// The third small mistake: the level fails and the lesson card insists.
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
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav', 0.7);
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('steps/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Work started too soon: the team goes up, the site freezes grey and the
  /// line answers in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/stomp.wav', 0.5);
    setState(() {
      _climbAll = true;
      _wake++;
    });
    if (!_quiet) await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _cue('sounds/learn/spark.wav', 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('steps/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? StepLines.deadlyWord : StepLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _shook = null;
        });
        // The step is still to do.
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
      _busy = false;
    });
    await _say(!_run.passed ? StepLines.fail : (_quickBonus ? StepLines.quick : StepLines.allSet),
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
  PtwYardGeo _geo(double h, double inset) {
    final size = MediaQuery.sizeOf(context);
    final k = 360 / math.max(1.0, size.width);
    return PtwYardGeo.forScene(h, inset, (MediaQuery.paddingOf(context).top + 92) * k);
  }

  bool _onLadder(int i) => (_climbAll || _run.isDone(StepIds.start)) && !_run.isDone(StepIds.worker(i));

  /// A tappable thing in the scene (design px).
  Widget _spot(String key, Rect r, String label, VoidCallback onTap) => Positioned.fromRect(
        key: ValueKey('spot-$key'),
        rect: r,
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              _lastTap = d.globalPosition;
              onTap();
            },
          ),
        ),
      );
  Offset _lastTap = Offset.zero;

  /// Shakes once when one of [things] was just tapped out of turn.
  Widget _shaker(List<PtwThing> things, Widget child) {
    final on = things.contains(_shook) && !_quiet;
    return TweenAnimationBuilder<double>(
      key: ValueKey('shake-${things.first.name}-${on ? _shakes : 0}'),
      tween: Tween(begin: on ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, t, c) => Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 5 * (1 - t), 0), child: c),
      child: child,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo(m.height, m.inset);
    final quiet = _quiet;
    final ms = quiet ? 0 : 1;
    final r = _run;
    final off = r.isDone(StepIds.isolate);
    final locked = off && !r.isDone(StepIds.unlock);
    final open = r.isDone(StepIds.issue);
    final returned = r.isDone(StepIds.cancel);
    final paper = r.isDone(StepIds.receive) && !returned;
    final hooked = r.isDone(StepIds.test) && !r.isDone(StepIds.tools);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final inset = geo.inset;
    final crew = r.crew;
    final calling = _calls;

    // Under the freeze filter: the whole site.
    final site = <Widget>[
      Positioned.fill(
        key: const ValueKey('yard'),
        child: RepaintBoundary(child: CustomPaint(painter: PtwYardPainter(geo))),
      ),
      // The control room's window: breaker, lock and tag, the operator, the book.
      Positioned.fromRect(
        key: const ValueKey('room'),
        rect: inset,
        child: _shaker(const [PtwThing.breaker, PtwThing.book], Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: off ? 1 : 0),
                duration: Duration(milliseconds: 520 * ms),
                curve: Curves.easeInOutBack,
                builder: (_, o, _) => TweenAnimationBuilder<double>(
                  tween: Tween(end: locked ? 1 : 0),
                  duration: Duration(milliseconds: 420 * ms),
                  curve: Curves.bounceOut,
                  builder: (_, l, _) => CustomPaint(painter: PtwRoomPainter(off: o.clamp(0.0, 1.0), lock: l.clamp(0.0, 1.0), open: open, cancelled: returned)),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: PtwYardGeo.operatorLocal,
              child: LinemanFigure(
                look: PtwLooks.operator,
                mode: _opBusy ? LinemanMode.talk : LinemanMode.idle,
                wake: _wake,
                quiet: quiet,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 6,
              height: 16,
              child: Center(child: Text(StepLines.controlRoom, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            Positioned(
              left: PtwYardGeo.breakerLocal.left,
              width: PtwYardGeo.breakerLocal.width,
              top: PtwYardGeo.breakerLocal.top + 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_feeder, maxLines: 1, style: bangla(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                ),
              ),
            ),
            Positioned(
              left: PtwYardGeo.breakerLocal.left + 12,
              width: PtwYardGeo.breakerLocal.width - 24,
              top: PtwYardGeo.breakerLocal.top + 16,
              height: 17,
              child: Container(
                alignment: Alignment.center,
                color: const Color(0xFF1E2329),
                child: Text(off ? StepLines.off : StepLines.on,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: off ? const Color(0xFF3CCB5E) : const Color(0xFFFF6B5E))),
              ),
            ),
            if (!open)
              Positioned(
                key: const ValueKey('book-cover'),
                left: PtwYardGeo.bookLocal.left + 10,
                width: PtwYardGeo.bookLocal.width - 20,
                top: PtwYardGeo.bookLocal.top + 14,
                child: const Text(StepLines.ptw, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
              )
            else
              Positioned(
                key: const ValueKey('book-page'),
                left: PtwYardGeo.bookLocal.left,
                width: PtwYardGeo.bookLocal.width,
                top: PtwYardGeo.bookLocal.top + 8,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: quiet ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 380),
                  builder: (_, t, c) => Opacity(opacity: t, child: c),
                  child: Column(
                    children: [
                      const Text(StepLines.ptw, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF1F5F8F))),
                      Text(StepLines.permitNo(_permitNo), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF31363C))),
                      if (returned)
                        Text(StepLines.cancelled, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFFC0392B))),
                    ],
                  ),
                ),
              ),
          ],
        )),
      ),
      // The rod and tester: on the tarp, then hooked on the line.
      Positioned.fill(
        key: const ValueKey('rod'),
        child: IgnorePointer(
          child: _shaker(
            const [PtwThing.rod],
            TweenAnimationBuilder<double>(
              tween: Tween(end: hooked ? 1 : 0),
              duration: Duration(milliseconds: 750 * ms),
              curve: Curves.easeInOutCubic,
              builder: (_, t, _) => CustomPaint(painter: PtwRodPainter(geo: geo, t: t, tested: r.isDone(StepIds.test))),
            ),
          ),
        ),
      ),
      if (hooked)
        Positioned(
          key: const ValueKey('dead'),
          left: geo.hook.dx + 8,
          top: geo.hook.dy + 14,
          // (It pops when the rod and tester reach the line.)
          child: IgnorePointer(child: _Chip(text: StepLines.dead, color: const Color(0xFF2E8B45), quiet: quiet, delayMs: 760)),
        ),
      // The supervisor behind his table.
      Positioned.fromRect(
        key: const ValueKey('supervisor'),
        rect: geo.supervisor,
        child: LinemanFigure(look: PtwLooks.supervisor, mode: calling > 0 && _busyCall ? LinemanMode.talk : LinemanMode.idle, wake: _wake, quiet: quiet),
      ),
      // The team: at the pole foot, or up the ladder.
      for (var i = crew - 1; i >= 0; i--)
        AnimatedPositioned.fromRect(
          key: ValueKey('worker-$i'),
          duration: Duration(milliseconds: (900 + 220 * i) * ms),
          curve: Curves.easeInOut,
          rect: PtwYardGeo.figureAt(_onLadder(i) ? geo.crewLadder(i) : geo.crewGround(i, crew)),
          child: LinemanFigure(
            look: i == 0 ? LinemanLook.trainee : PtwLooks.crew,
            mode: _onLadder(i) ? LinemanMode.hold : (r.done ? LinemanMode.cheer : LinemanMode.idle),
            wake: _wake,
            quiet: quiet,
          ),
        ),
      Positioned.fill(key: const ValueKey('table'), child: RepaintBoundary(child: CustomPaint(painter: PtwTablePainter(geo)))),
      Positioned.fromRect(
        key: const ValueKey('phone'),
        rect: geo.phone,
        child: _shaker(const [PtwThing.phone], CustomPaint(painter: PtwPhonePainter(lit: _busyCall))),
      ),
      Positioned.fromRect(
        key: const ValueKey('clipboard'),
        rect: geo.clipboard,
        child: _shaker(
          const [PtwThing.clipboard],
          Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: PtwClipboardPainter(paper: paper))),
              if (paper)
                Positioned(
                  key: const ValueKey('paper'),
                  left: 6,
                  right: 6,
                  top: 11,
                  child: Column(
                    children: [
                      const Text(StepLines.ptw, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1F5F8F))),
                      Text(StepLines.permitNo(_permitNo), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF31363C))),
                      FittedBox(child: Text(_feeder, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF31363C), height: 1.3))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      // A call on: the phone's screen says who.
      if (calling > 0)
        Positioned(
          key: ValueKey('call-$calling'),
          left: geo.phone.left - 6,
          top: geo.phone.top - 26,
          child: IgnorePointer(child: _CallChip(quiet: quiet, onEnd: () {
            if (mounted) setState(() => _callShown = calling);
          })),
        ),
      // Counting the team down.
      // (Only once someone is down: it confirms the counting, never announces it.)
      if (r.round == 1 && r.down >= 1 && r.down < crew)
        Positioned(
          key: const ValueKey('count'),
          left: geo.ladderFoot.dx + 16,
          top: (geo.ladderTop.dy + geo.ladderFoot.dy) / 2 - 10,
          child: IgnorePointer(child: _Chip(text: StepLines.down(r.down, crew), color: const Color(0xFF1F5F8F), quiet: quiet)),
        ),
    ];

    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final crewRect = Rect.fromLTRB(geo.crewGround(0, crew).dx - 26, geo.ground - 96, geo.crewGround(crew - 1, crew).dx + 26, geo.ground + 4);
    final spots = <Widget>[
      if (playing) ...[
        _spot('van', geo.van, StepLines.van, () => _tapThing(PtwThing.van, _lastTap)),
        _spot('breaker', geo.breaker, StepLines.breaker, () => _tapThing(PtwThing.breaker, _lastTap)),
        _spot('book', geo.book.inflate(8), StepLines.book, () => _tapThing(PtwThing.book, _lastTap)),
        if (r.round == 0) _spot('crew', crewRect, StepLines.crew, _tapCrew),
        if (r.round == 0 && _climbAsk && _canPlay)
          Positioned(
            key: const ValueKey('climb-ask'),
            left: crewRect.center.dx - 66,
            width: 132,
            top: crewRect.top - 62,
            child: _Pop(
              quiet: quiet,
              child: DoBigButton(label: StepLines.climbAsk, filled: true, onTapUp: (d) => _tapThing(PtwThing.crew, d.globalPosition)),
            ),
          ),
        if (r.round == 1)
          for (var i = 0; i < crew; i++)
            if (_onLadder(i)) _spot('worker-$i', PtwYardGeo.figureAt(geo.crewLadder(i)).inflate(4), StepLines.worker(i), () => _tapThing(PtwThing.worker, _lastTap, worker: i)),
        _spot(
          'rod',
          hooked
              ? Rect.fromLTRB(geo.hook.dx - 14, geo.hook.dy + 40, geo.hook.dx + 34, geo.ground - 12)
              : Rect.fromLTRB(geo.tarp.left - 12, geo.tarp.top - 20, geo.tarp.right + 12, geo.tarp.bottom + 16),
          StepLines.rod,
          () => _tapThing(PtwThing.rod, _lastTap),
        ),
        _spot('phone', Rect.fromLTRB(geo.phone.left - 10, geo.phone.top - 10, geo.phone.right + 6, geo.phone.bottom + 10), StepLines.phone, () => _tapThing(PtwThing.phone, _lastTap)),
        _spot('clipboard', geo.clipboard.inflate(4), StepLines.clipboard, () => _tapThing(PtwThing.clipboard, _lastTap)),
      ],
    ];

    _hintRects = playing
        ? ([
            geo.van,
            geo.breaker,
            geo.book.inflate(8),
            if (r.round == 0) crewRect,
            if (r.round == 0 && _climbAsk) Rect.fromLTWH(crewRect.center.dx - 66, crewRect.top - 62, 132, 48),
            if (r.round == 1)
              for (var i = 0; i < crew; i++)
                if (_onLadder(i)) PtwYardGeo.figureAt(geo.crewLadder(i)),
            hooked
                ? Rect.fromLTRB(geo.hook.dx - 14, geo.hook.dy + 40, geo.hook.dx + 34, geo.ground - 12)
                : Rect.fromLTRB(geo.tarp.left - 12, geo.tarp.top - 20, geo.tarp.right + 12, geo.tarp.bottom + 16),
            geo.phone,
            geo.clipboard,
          ]..sort((a, b) => a.center.dx.compareTo(b.center.dx)))
        : const [];

    final top = geo.crewLadder(0);
    return [
      Positioned.fill(
        key: const ValueKey('site'),
        child: ColorFiltered(colorFilter: grey, child: Stack(children: site)),
      ),
      ...spots,
      // The deadly start, in colour over the grey site: the line answers.
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 2400),
              builder: (_, t, _) => CustomPaint(painter: PtwArcPainter(from: Offset(geo.hook.dx + 14, geo.wireLeftY(0, geo.hook.dx + 14)), to: Offset(top.dx - 6, top.dy - 66), t: t)),
            ),
          ),
        ),
    ];
  }

  int _callShown = 0;

  /// A call is on (the chip is up).
  bool get _busyCall => _calls > _callShown;

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
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
              labels: StepLines.rounds,
              done: {if (_run.round >= 1) 0, if (_run.done) 1},
              current: _run.ended ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            // How to touch the site (a sweep over all of it), never which step.
            hint: () => _hintRects.length < 2 ? null : HintSpec.sweep(_hintRects, space: HintSpace.scene),
            hintWaiting: playing && _canPlay && !deckUp && !coworkerOnScreen,
            hintKey: '${_run.round}-$_wake-$_climbAsk',
            hintController: _hints,
            hintAutoMiss: true,
            overlays: [
              // Empty sky top left, under the header and above the sun, the
              // wires and the rod's hook (not over the pole top or the test).
              ...tableLayers(at: Offset(size.width * 0.14, pad.top + 96), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$_shakes'),
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
                  sound: FailSound.paper,
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
                  line: StepLines.intro,
                  alarm: 'sounds/van_arrive.wav',
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

/// A small label on the site (the tester's "dead", the head count).
class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, required this.quiet, this.delayMs = 0});
  final String text;
  final Color color;
  final bool quiet;

  /// It pops this long after it is put on.
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final total = delayMs + 360;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutBack),
      builder: (_, t, c) => Transform.scale(scale: t, child: c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Text(text, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}

/// A control that pops in once (the "উঠতে বলুন" button).
class _Pop extends StatelessWidget {
  const _Pop({required this.quiet, required this.child});
  final bool quiet;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (_, t, c) => Transform.scale(scale: t, child: c),
        child: child,
      );
}

/// The phone's call screen for a moment: "কন্ট্রোল রুম".
class _CallChip extends StatelessWidget {
  const _CallChip({required this.quiet, required this.onEnd});
  final bool quiet;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: quiet ? 900 : 1800),
      onEnd: onEnd,
      builder: (_, t, c) {
        final a = t < 0.15 ? t / 0.15 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
        return Opacity(opacity: a.clamp(0.0, 1.0), child: c);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF1E6B34), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_rounded, size: 10, color: Colors.white),
            const SizedBox(width: 3),
            Text(StepLines.controlRoom, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A numbered place in the sequence: empty, or the step that belongs there.
/// (Kept for golden_minute.dart's deck.)
class StepSlot extends StatelessWidget {
  const StepSlot({super.key, required this.index, required this.card, required this.note, required this.quiet});
  final int index;
  final StepCard? card;
  final String? note;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final c = card;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c != null ? const Color(0xFF2E8B45) : const Color(0x22FFFFFF),
            ),
            child: Text(enDigits('${index + 1}'), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: quiet ? Duration.zero : const Duration(milliseconds: 260),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c != null ? const Color(0xFFE9F6EC) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c != null ? const Color(0xFF2E8B45) : const Color(0x44FFFFFF), width: 1.4),
              ),
              child: c == null
                  ? const SizedBox()
                  : Row(
                      children: [
                        Icon(c.icon, size: 18, color: const Color(0xFF2E8B45)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.titleBn, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: SlmColors.ink)),
                              Text(note ?? c.subBn, style: bangla(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3A4660))),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A step card waiting in the tray; shakes once when tapped out of turn.
/// (Kept for golden_minute.dart's deck.)
class StepTrayCard extends StatelessWidget {
  const StepTrayCard({super.key, required this.card, required this.shake, required this.quiet, required this.onTap});
  final StepCard card;
  final bool shake;
  final bool quiet;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 28 - 8) / 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: shake && !quiet ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, t, child) => Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0), child: child),
      child: Semantics(
        button: true,
        label: card.titleBn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(d.globalPosition),
          child: Container(
            width: w,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SlmColors.ivory,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Row(
              children: [
                Icon(card.icon, size: 22, color: const Color(0xFF8C6A2A)),
                const SizedBox(width: 8),
                Expanded(child: Text(card.titleBn, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ink))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
