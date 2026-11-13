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
import 'fire_choose.dart' show FireKind;
import 'fire_fx.dart';
import 'fire_world.dart';
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
import 'ptw_steps.dart' show StepCard;
import 'reason_table.dart';
import 'scene_kit.dart';
import 'spoken_once.dart';

// Lesson 1.8, কাজ 2: "PASS" — rebuilt on the shared level kit
// (GAME_LEVEL_PLAYBOOK.md). Two fires in the substation yard (transformer oil,
// dry grass under a pole). The guide first (what burns, "now"); then the yard,
// full screen, with the wind showing (a windsock, streaks, the smoke drifting)
// and a wall. Where to stand: three places on the ground — upwind with the way
// out open (right), against the wall (cornered; the wall is dealt behind the
// far upwind or the far downwind place), downwind in the smoke.
// Then PASS with the hands: drag the pin out (P), tap the fire's base, not the
// flames (A), hold the handle (S) and slide side to side (S: sweep — only a
// moving jet puts it out). Each fire out → its ◆ on the table → "কেন …?"
// (first fire: where you stood; second: the aim). At the end the careless
// coworker peeps in: "অর্ধেকটা তো বাকি — রেখে দাও" — the guide asks; refill is right.
//
// Deadly: none (owner-approved list: cornered without escape costs points).
// Slips: standing downwind or cornered; a PASS step out of order (squeezing
// with the pin in, aiming before the pin); aiming at the flames; keeping a
// used extinguisher (listening to the coworker). Points as before; the
// fire-out points wait on the table, and the scene takes no input while a
// right move is praised (`tableBusy`).
//
// No giveaways (audit 2026-11-11): each fire deals its own wind side, where
// the wall stands (behind the far upwind place, or behind the far downwind
// place) and which side the windsock is on, so the right place is found by
// reading the wind, not by "next to the wall", "by the sock" or "the other
// side from the last fire".
// The reason and refill libraries share their key words with the wrong
// options. Gesture hints: a sweep over the places, a sweep over the
// extinguisher's head, the fire and the handle (never one of them), and a
// hold-and-slide nudge on the handle once it is the only way forward.
//
// The coworker comes only after the last fire (his push is the refill, and
// no player control can finish that item before him), so the level needs no
// `holdForCoworker` gate.
//
// Voice: device TTS for the guide; the coworker's lines are clips in his voice.

// ============================================================================
// Content
// ============================================================================

enum StandSpot { upwind, cornered, downwind }

@immutable
class PassRound {
  const PassRound({required this.kind, required this.windFromLeft, this.wallUpwind = true, this.sockUpwind = true});
  final FireKind kind;
  final bool windFromLeft;

  /// The wall stands behind the far upwind place (that place is cornered) or
  /// behind the far downwind place (cornered and in the smoke).
  final bool wallUpwind;

  /// The windsock's pole stands on the upwind side (else the downwind side);
  /// it always points downwind.
  final bool sockUpwind;

  /// The wall is on the left of the fire.
  bool get wallOnLeft => wallUpwind == windFromLeft;

  /// The windsock is on the left of the fire.
  bool get sockOnLeft => sockUpwind == windFromLeft;
}

abstract final class PassIds {
  static const pull = 'pull';
  static const aim = 'aim';
  static const squeeze = 'squeeze';
  static const sweep = 'sweep';
}

const passCards = [
  StepCard(PassIds.pull, 'টানুন (Pull)', 'সেফটি পিন টেনে খুলুন', Icons.push_pin_rounded),
  StepCard(PassIds.aim, 'তাক করুন (Aim)', 'নজল আগুনের দিকে', Icons.center_focus_strong_rounded),
  StepCard(PassIds.squeeze, 'চাপুন (Squeeze)', 'হ্যান্ডেল চেপে ধরুন', Icons.back_hand_rounded),
  StepCard(PassIds.sweep, 'ঝাড়ুন (Sweep)', 'এপাশ-ওপাশ, পুরো না নেভা পর্যন্ত', Icons.swap_horiz_rounded),
];

abstract final class PassLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askStand, askPass, askAim];

  static const title = 'PASS';
  static const intro = 'হাতে অগ্নি নির্বাপক — আগে ঠিক জায়গায় দাঁড়ান, তারপর PASS।';
  static const rounds = ['প্রথম', 'দ্বিতীয়'];

  /// The guide first: what burns and "now" (no hints).
  static String alarmFirst(FireKind k) => switch (k) {
        FireKind.oil => 'ট্রান্সফরমারে আবার আগুন! হাতে অগ্নি নির্বাপক — ঠিকভাবে নেভান!',
        FireKind.grass => 'পোলের নিচে ঘাসে আগুন! হাতে অগ্নি নির্বাপক — ঠিকভাবে নেভান!',
        FireKind.electrical => 'প্যানেলে আগুন! হাতে অগ্নি নির্বাপক — ঠিকভাবে নেভান!',
      };
  static String alarm(FireKind k) => switch (k) {
        FireKind.oil => 'এবার ট্রান্সফরমারে আগুন! জলদি!',
        FireKind.grass => 'এবার ঘাসে আগুন! জলদি!',
        FireKind.electrical => 'এবার প্যানেলে আগুন! জলদি!',
      };
  static const askStand = 'কোথায় দাঁড়িয়ে নেভাবেন?';
  static const askPass = 'এবার নেভান!';
  static const askAim = 'কোথায় তাক করবেন?';
  static const stood = 'ঠিক!';
  static const out = 'আগুন নিভল!';
  static const spot = 'জায়গা';
  static const pin = 'পিন';
  static const base = 'গোড়া';
  static const flames = 'শিখা';
  static const squeeze = 'চেপে ধরুন';
  static const ok = [FeedbackLine('ঠিক!'), FeedbackLine('এটাই পরের ধাপ।'), FeedbackLine('বেশ!')];
  static const refillOk = 'ঠিক! একবার চাপলেই চাপ বেরিয়ে যায় — রিফিল চাই।';
  static const allSet = 'বাতাস পেছনে, পথ খোলা, PASS নিখুঁত — আগুন আপনার নিয়ন্ত্রণে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দাঁড়ানোর জায়গা আর PASS-এর ক্রম মনে রেখে।';
  static const caughtStand = 'বাতাস পেছনে, পথ খোলা রেখে দাঁড়ানো';
  static const caughtAim = 'আগুনের গোড়ায় তাক';
  static const caughtRefill = 'ব্যবহৃত সিলিন্ডার রিফিলে';

  // Tap the guide: the task again, a different way each time (never the answer).
  static const tapStand = ['কোথায় দাঁড়িয়ে নেভাবেন?', 'ঠিক জায়গাটা বেছে নিন।', 'চারপাশটা ভালো করে দেখুন।'];
  static const tapPass = ['এবার নেভান!', 'নির্বাপকটা ভালো করে দেখুন।', 'আগে কী করবেন?'];
  static const tapSweep = ['চেপে ধরে রাখুন — পুরো না নেভা পর্যন্ত।', 'ছাড়বেন না — নেভান!'];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The reason after each fire (first fire: where you stood; second: the aim).
  static const whyStand = 'কেন ওখানে দাঁড়ালেন?';
  static const whyAim = 'কেন গোড়ায় তাক করলেন?';
  static const whyStandRight = [
    'বাতাস পেছনে থাকলে ধোঁয়া-তাপ গায়ে আসে না',
    'পেছনের পথ খোলা থাকলে দরকারে সরা যায়',
    'বাতাস পিঠে আর পেছনে সরার পথ খোলা',
  ];
  static const whyStandWrong = [
    'আগুনের যত কাছে, তত তাড়াতাড়ি নেভে',
    'পেছনে দেয়াল থাকলে আড়াল পাওয়া যায়',
    'ধোঁয়ার দিক থেকে আগুন ভালো দেখা যায়',
    'বাতাস যেদিকেই থাক, কিছু যায় আসে না',
    'যেখানে খুশি দাঁড়ালেই কাজ হয়ে যায়',
    'পথ খোলা রাখার চেয়ে কাছে যাওয়া জরুরি',
  ];
  static const whyAimRight = [
    'জ্বালানি জ্বলছে গোড়ায় — সেখানেই তাক',
    'শিখায় নয়, গোড়াতেই স্প্রে চাই',
    'গোড়ায় এপাশ-ওপাশ ঝাড়লে পুরো নেভে',
  ];
  static const whyAimWrong = [
    'শিখার মাথায় তাক করলেই আগুন নেভে',
    'এক জায়গায় ধরে রাখলেই যথেষ্ট',
    'ধোঁয়ার দিকে স্প্রে করলেই হয়ে যায়',
    'যত দূর থেকে স্প্রে, তত ভালো কাজ',
    'একটু চেপে ছেড়ে দিলেই আগুন নেভে',
    'গোড়ায় একবার ছিটালেই আগুন নিজে নেভে',
    'গোড়ায় তাক করলে কাছে যেতে হয় না',
  ];

  /// The careless coworker at the end: keep the half-used cylinder.
  static const refillLine = 'অর্ধেকটা তো বাকি — রেখে দাও, পরের বার কাজে লাগবে।';
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const refillRight = [
    'না — আজই রিফিলে পাঠিয়ে দিই',
    'ব্যবহৃত সিলিন্ডার রিফিলে যাবে',
    'চাপ বেরিয়ে গেছে — রিফিল চাই',
  ];
  static const refillWrong = [
    'ঠিক বলেছে, অর্ধেকটা রেখে দিই',
    'পরের বারের জন্য তুলে রাখি',
    'অর্ধেক তো আছে, কাজ চলে যাবে',
    'গেজ দেখার দরকার নেই, রাখি',
    'স্টোরে এমনিই ফেরত রেখে দিই',
    'রিফিল পরে হবে, এখন তুলে রাখি',
    'রিফিলের দরকার নেই, অর্ধেক আছে',
    'রিফিলে পাঠানো ঝামেলা, রেখে দিই',
  ];
  static const refillAsks = [
    'ও বলছে রেখে দিতে। আপনি কী করবেন?',
    'ব্যবহার করা সিলিন্ডার — কী করবেন?',
    'অর্ধেকটা রাখবেন, না রিফিলে পাঠাবেন?',
  ];
  static const coworker = CoworkerScript(
    line: refillLine,
    exitLine: coworkerExit,
    right: refillRight,
    wrong: refillWrong,
    asks: refillAsks,
  );
}

abstract final class PassMistakes {
  static const downwind = DoMistake(
    key: '1.8/pass/downwind',
    textBn: 'বাতাস আপনার মুখের দিকে — ধোঁয়া আর তাপ আপনার দিকেই আসবে। বাতাস পেছনে রেখে দাঁড়ান।',
    art: 'assets/game/art/fire/wind_exit.svg',
    lessonPoint: 3,
  );
  static const cornered = DoMistake(
    key: '1.8/pass/cornered',
    textBn: 'পেছনে দেয়াল — আগুন বাড়লে বেরোনোর পথ নেই। পেছনের পথ সবসময় খোলা রাখুন।',
    art: 'assets/game/art/fire/wind_exit.svg',
    lessonPoint: 3,
  );
  static const downwindWall = DoMistake(
    key: '1.8/pass/downwind-wall',
    textBn: 'বাতাস মুখের দিকে, পেছনে দেয়াল — ধোঁয়া-তাপ আপনার দিকে, সরার পথও নেই। বাতাস পেছনে, পথ খোলা রেখে দাঁড়ান।',
    art: 'assets/game/art/fire/wind_exit.svg',
    lessonPoint: 3,
  );
  static const order = DoMistake(
    key: '1.8/pass/order',
    textBn: 'ক্রম উল্টে গেল — P: পিন টানুন, A: গোড়ায় তাক, S: হ্যান্ডেল চাপুন, S: এপাশ-ওপাশ ঝাড়ুন।',
    art: 'assets/game/art/fire/pass_order.svg',
    lessonPoint: 3,
  );
  static const aimTip = DoMistake(
    key: '1.8/pass/aim-tip',
    textBn: 'শিখায় স্প্রে করলে আগুন নেভে না — আগুনের গোড়ায় তাক করুন, যেখানে জ্বালানি জ্বলছে।',
    art: 'assets/game/art/fire/aim_base.svg',
    lessonPoint: 3,
  );
  static const keep = DoMistake(
    key: '1.8/pass/keep-half',
    textBn: 'একবার চাপলেই চাপ বেরিয়ে যায় — পরের বার কাজ করবে না। ব্যবহৃত সিলিন্ডার রিফিলে পাঠান।',
    art: 'assets/game/art/fire/refill.svg',
    lessonPoint: 2,
  );
  static const all = [downwind, cornered, downwindWall, order, aimTip, keep];

  /// The slip for standing at [s] in round [r] (null: the right place).
  static DoMistake? forSpot(StandSpot s, PassRound r) => switch (s) {
        StandSpot.upwind => null,
        StandSpot.downwind => downwind,
        StandSpot.cornered => r.wallUpwind ? cornered : downwindWall,
      };
}

/// Two fires. Each fire deals its own wind side, wall side (upwind or
/// downwind) and windsock side, so the second fire cannot be worked out from
/// the first (a fixed "the wind turns" or "the wall swaps" would give it
/// away): the wind has to be read every time.
List<PassRound> dealPass(math.Random rng) {
  final kinds = [FireKind.oil, FireKind.grass]..shuffle(rng);
  return [
    for (final k in kinds)
      PassRound(kind: k, windFromLeft: rng.nextBool(), wallUpwind: rng.nextBool(), sockUpwind: rng.nextBool()),
  ];
}

List<OrderRoundSpec> passOrderRounds() => [
      OrderRoundSpec(groups: [for (final c in passCards) OrderGroup([c.id], skipMistake: PassMistakes.order)]),
    ];

enum PassPhase { stand, pass, out, refill }

@immutable
class PassPack {
  const PassPack({required this.id, required this.titleBn, this.quickMs = 50000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const passPack18 = PassPack(id: 'do_1_8_b', titleBn: PassLines.title);
const passPacks = {'do_1_8_b': passPack18};

/// The fire stands at x 180 of the 360-wide scene; the three places to stand
/// on the ground in front of it (design pixels, before the lift). With the
/// wind from the left the upwind side is the left. The wall is behind the
/// far upwind place ([wallUpwind]: cornered, two places upwind) or behind
/// the far downwind place (cornered in the smoke, two places downwind);
/// downwind is in the smoke.
abstract final class PassStage {
  static const fireX = 180.0;

  /// Just above the guide's bubble band on the bottom right.
  static const spotY = 322.0;
  static double spotX(StandSpot s, bool windFromLeft, {bool wallUpwind = true}) {
    final left = wallUpwind
        ? switch (s) {
            StandSpot.cornered => 24.0,
            StandSpot.upwind => 88.0,
            StandSpot.downwind => 300.0,
          }
        : switch (s) {
            StandSpot.upwind => 64.0,
            StandSpot.downwind => 248.0,
            StandSpot.cornered => 330.0,
          };
    return windFromLeft ? left : 360 - left;
  }

  /// [spotX] for round [r]'s wind and wall.
  static double spotXIn(StandSpot s, PassRound r) => spotX(s, r.windFromLeft, wallUpwind: r.wallUpwind);

  /// The fire's base (world pixels) and a smaller size than step 23's, so
  /// there is room to stand back and spray across.
  static (Offset, double) fireAt(FireKind k) {
    final (b, sz) = FireWorld.fireAt(k);
    return (b, sz * 0.62);
  }

  static double cameraFor(FireKind k) => (FireWorld.fireAt(k).$1.dx - fireX).clamp(0.0, FireWorld.width - FireWorld.viewW);
}

// ============================================================================
// Page
// ============================================================================

class FirePassPage extends StatefulWidget {
  const FirePassPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final PassPack pack;
  final bool muted;
  final int? seed;

  @override
  State<FirePassPage> createState() => _FirePassPageState();
}

class _FirePassPageState extends State<FirePassPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PassRunPage(
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

class _PassRunPage extends ConsumerStatefulWidget {
  const _PassRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final PassPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PassRunPage> createState() => _PassRunPageState();
}

class _PassRunPageState extends ConsumerState<_PassRunPage>
    with DoStrikeOut, SingleTickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final List<PassRound> _rounds = dealPass(widget.rng);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The camera walks from the first fire to the second.
  late final AnimationController _cam = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..addStatusListener((_) {
      if (mounted) setState(() {});
    });
  late double _camFrom = PassStage.cameraFor(_rounds.first.kind);
  late double _camTo = _camFrom;
  double get _camX => _camFrom + (_camTo - _camFrom) * Curves.easeInOutCubic.transform(_cam.value);

  final _combo = Combo();
  int _comboN = 0;
  int _comboMult = 1;
  int? _stars;
  final List<String> _caught = [];

  int _round = 0;
  PassPhase _phase = PassPhase.stand;
  OrderRun _order = OrderRun(passOrderRounds());
  int _slips = 0;
  int _runScore = 0;
  final Set<FireKind> _doneKinds = {};

  // The scene is laid out for the screen.
  double _lift = 0;
  double _inset = 0;
  int _wake = 0;

  /// How much of this fire is left (1 → 0); it shrinks only while swept.
  final _fire = ValueNotifier<double>(1);

  // This fire's PASS: where he stands, the pin, the aim, the squeeze/sweep.
  StandSpot? _spot;
  var _pinOut = false;
  var _aimed = false;
  var _squeezing = false;
  var _squeezedOnce = false;
  var _swept = false;
  double _sweepX = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  int _tapN = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  /// The gesture hint (how to touch, never what): misses come from taps on
  /// the bare yard.
  final _hints = IdleHintController();

  /// The scene's design height (for the PASS panel's place in hints).
  double _sceneH = 640;

  String get _rungId => widget.ctx.rungId;
  PassRound get _r => _rounds[_round];
  int get _percent => (100 - 15 * _slips).clamp(0, 100);
  bool get _passedRun => _percent >= 55;

  /// The scene takes a move: not ended, no card, no coworker, and not while a
  /// right move is praised or its reason is asked (`tableBusy`).
  bool get _idle => !_ended && _card == null && !coworkerOpen && !tableBusy;

  int _scored(int base) {
    final (mult, up) = _combo.hit();
    if (up) {
      setState(() {
        _comboN++;
        _comboMult = _combo.mult;
      });
    }
    return base * mult;
  }

  @override
  void dispose() {
    disposeCoworker();
    _fire.dispose();
    _cam.dispose();
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
  void onReasonPaid() => _next();

  // --- the shared pressure moment (CoworkerMoment): keep the used cylinder? --
  @override
  CoworkerScript get coworkerScript => PassLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _phase != PassPhase.refill) return null;
    if (tableBusy) return false;
    return _card == null;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();
  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      _slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(PassMistakes.keep);
      return;
    }
    _caught.add(PassLines.caughtRefill);
    unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted) return;
    await _sayChain([PassLines.refillOk], mood: GuideMood.glad);
    unawaited(_finish());
  }

  /// After the guide's intro: the clock runs and play begins.
  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    unawaited(_sayChain([PassLines.askStand]));
  }

  /// Tap the guide: the task on screen again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended || _card != null) return;
    final ways = coworkerOpen
        ? PassLines.refillAsks
        : reasonOpen
            ? PassLines.tapWhy
            : switch (_phase) {
                PassPhase.stand => PassLines.tapStand,
                PassPhase.pass => _squeezing || (_pinOut && _aimed) ? PassLines.tapSweep : PassLines.tapPass,
                PassPhase.out || PassPhase.refill => const <String>[],
              };
    if (ways.isEmpty) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([ways[_tapN++ % ways.length]]));
  }

  Future<void> _stand(StandSpot s, Offset origin) async {
    if (!_idle || _phase != PassPhase.stand || _cam.isAnimating) return;
    _hush();
    final wrong = PassMistakes.forSpot(s, _r);
    if (wrong != null) {
      _slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(wrong);
      return;
    }
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
    if (!_caught.contains(PassLines.caughtStand)) _caught.add(PassLines.caughtStand);
    unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
    setState(() {
      _spot = s;
      _phase = PassPhase.pass;
      _wake++;
    });
    unawaited(_sayChain([PassLines.stood, PassLines.askPass], mood: GuideMood.glad));
  }

  /// One PASS step in order; out of order is the slip (as the cards were).
  bool _step(String id, Offset origin) {
    final t = _order.tap(id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        return false;
      case OrderTapKind.mistake:
        _slips++;
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(t.mistake!));
        return false;
      case OrderTapKind.ok:
        HapticFeedback.lightImpact();
        unawaited(_levelDelta(_scored(5), origin, mood: GuideMood.glad));
        return true;
    }
  }

  /// P — the pin dragged out.
  void _pull(Offset origin) {
    if (!_idle || _phase != PassPhase.pass || _pinOut) return;
    _hush();
    if (!_step(PassIds.pull, origin)) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.7, muted: false));
    setState(() => _pinOut = true);
  }

  /// A — a tap on the fire: the base, or the flames.
  Future<void> _aim(bool base, Offset origin) async {
    if (!_idle || _phase != PassPhase.pass || _aimed) return;
    _hush();
    if (!base) {
      _slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(PassMistakes.aimTip);
      return;
    }
    if (!_step(PassIds.aim, origin)) return;
    if (!_caught.contains(PassLines.caughtAim)) _caught.add(PassLines.caughtAim);
    unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
    setState(() => _aimed = true);
  }

  /// S — the handle held down (before the pin and the aim: out of order).
  void _squeezeDown(Offset origin) {
    if (!_idle || _phase != PassPhase.pass || _squeezing) return;
    if (!_squeezedOnce) {
      if (!_step(PassIds.squeeze, origin)) return;
      _squeezedOnce = true;
    }
    _hush();
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.wav', volume: 0.5, muted: false));
    setState(() {
      _squeezing = true;
      _wake++;
    });
  }

  /// S — sweeping side to side while squeezing: only a moving jet puts it out.
  void _sweep(double dx, Offset origin) {
    if (!_squeezing || _phase != PassPhase.pass || !_idle) return;
    if (dx.abs() < 0.8) return;
    if (!_swept) {
      _swept = true;
      if (!_step(PassIds.sweep, origin)) {
        setState(() => _squeezing = false);
        return;
      }
    }
    setState(() => _sweepX = (_sweepX + dx * 0.7).clamp(-46.0, 46.0));
    _fire.value = math.max(0, _fire.value - 0.012 * math.min(dx.abs() / 3, 1.6));
    if (_fire.value <= 0) _out(origin);
  }

  void _squeezeUp() {
    if (!_squeezing) return;
    setState(() => _squeezing = false);
  }

  /// The fire is out: the rescue moment; its ◆ wait on the table for the reason.
  void _out(Offset origin) {
    if (_phase != PassPhase.pass) return;
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: false));
    setState(() {
      _phase = PassPhase.out;
      _squeezing = false;
      _wake++;
    });
    putOnTable(_scored(10));
    final round = _round;
    final first = round == 0;
    unawaited(askReason(
      deal: () => first
          ? dealChoices(PassLines.whyStandRight, PassLines.whyStandWrong, widget.rng)
          : dealChoices(PassLines.whyAimRight, PassLines.whyAimWrong, widget.rng),
      question: first ? PassLines.whyStand : PassLines.whyAim,
      stillValid: () => _round == round,
    ));
  }

  /// On to the next fire by itself, or the used cylinder at the end.
  void _next() {
    if (_ended || _phase != PassPhase.out) return;
    _doneKinds.add(_r.kind);
    if (_round == _rounds.length - 1) {
      setState(() => _phase = PassPhase.refill);
      scheduleCoworker();
      return;
    }
    _camFrom = _camX;
    setState(() {
      _round++;
      _order = OrderRun(passOrderRounds());
      _phase = PassPhase.stand;
      _spot = null;
      _pinOut = false;
      _aimed = false;
      _squeezing = false;
      _squeezedOnce = false;
      _swept = false;
      _sweepX = 0;
      _wake++;
    });
    _fire.value = 1;
    _camTo = PassStage.cameraFor(_r.kind);
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    void arrive() {
      if (!mounted || _ended) return;
      setState(() => _wake++);
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/fire_alarm.wav', volume: 0.5, muted: false));
      unawaited(_sayChain([PassLines.alarm(_r.kind), PassLines.askStand], mood: GuideMood.warn));
    }

    if (quiet) {
      _cam.value = 1;
      arrive();
    } else {
      unawaited(_cam.forward(from: 0).then((_) => arrive()));
    }
  }

  /// The third small mistake: the level fails and the lesson card insists.
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    // The jet stops: nothing keeps spraying under the strike-out card.
    if (mounted) setState(() => _squeezing = false);
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    _combo.miss();
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _squeezing = false;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('pass/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    final wasKeep = _card == PassMistakes.keep;
    setState(() => _card = null);
    if (wasKeep) unawaited(_finish());
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
    final mark = _percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_passedRun) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    final stars = starsFor(passed: _passedRun, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    _stars = stars;
    if (_passedRun) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_passedRun ? PassLines.fail : (_quickBonus ? PassLines.quick : PassLines.allSet),
        mood: _passedRun ? GuideMood.celebrate : GuideMood.warn);
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

  // ==========================================================================
  // Scene
  // ==========================================================================

  /// World → scene pixels.
  Offset _view(Offset world) => Offset(world.dx - _camX, world.dy + _lift);

  (Offset, double) get _fireOnScreen {
    final (b, sz) = PassStage.fireAt(_r.kind);
    return (_view(b), sz);
  }

  Widget _atFire(double w, double h, Offset own, double scale, Widget child, {Offset shift = Offset.zero}) {
    final (b, sz) = _fireOnScreen;
    final sc = sz * scale;
    final p = b + shift * sz;
    return Positioned(left: p.dx - own.dx * sc, top: p.dy - own.dy * sc, width: w * sc, height: h * sc, child: child);
  }

  /// The trainee's box at his place (feet on the place's line).
  Rect get _traineeBox {
    final x = PassStage.spotXIn(_spot ?? StandSpot.upwind, _r);
    return Rect.fromLTWH(x - 36, PassStage.spotY + _lift - 140, 72, 144);
  }

  /// He faces the fire (mirror him on the right of it).
  bool get _traineeFlipped => PassStage.spotXIn(_spot ?? StandSpot.upwind, _r) > PassStage.fireX;

  List<Widget> _scene(bool quiet) {
    final r = _r;
    final (base, size) = _fireOnScreen;
    final burning = _phase == PassPhase.stand || _phase == PassPhase.pass;
    final paused = _card != null || _ended || coworkerOpen || _intro;
    final zoom = 1 + 0.05 * math.sin(math.pi * _cam.value);
    final walking = _cam.isAnimating;
    final tb = _traineeBox;
    final mode = _squeezing ? LinemanMode.spray : (_phase == PassPhase.out ? LinemanMode.cheer : (_card != null ? LinemanMode.worried : LinemanMode.hold));
    var tip = tb.topLeft + LinemanFigure.tipOf(LinemanMode.spray, Carry.dcp, tb.size);
    if (_traineeFlipped) tip = Offset(tb.left + tb.right - tip.dx, tip.dy);
    final aim = base.translate(_sweepX * size, -6);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: Transform.scale(
          scale: zoom,
          child: Stack(
            children: [
              Positioned.fill(
                child: AwakeClock(
                  wake: _wake,
                  quiet: quiet || paused,
                  builder: (_, t) => ValueListenableBuilder<double>(
                    valueListenable: t,
                    builder: (_, v, _) => Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: FireWorldPainter(
                            camX: _camX,
                            t: v,
                            burning: burning && !walking ? r.kind : null,
                            done: {..._doneKinds, if (!burning) r.kind},
                            powerOn: false,
                            lift: _lift,
                          ),
                        ),
                        // The wind: a windsock and streaks blowing downwind.
                        CustomPaint(painter: _WindPainter(fromLeft: r.windFromLeft, sockLeft: r.sockOnLeft, t: v, lift: _lift)),
                      ],
                    ),
                  ),
                ),
              ),
              // The wall behind the far upwind place or the far downwind place,
              // as dealt in PassRound.wallUpwind (no way out at that place).
              Positioned(
                key: const ValueKey('wall'),
                left: r.wallOnLeft ? 0 : 332,
                top: PassStage.spotY + _lift - 112,
                width: 28,
                height: 126,
                child: const CustomPaint(painter: _WallPainter()),
              ),
              // Smoke drifts downwind.
              if (!walking)
                _atFire(
                  320,
                  210,
                  const Offset(160, 150),
                  1.1,
                  Transform.flip(
                    flipX: !r.windFromLeft,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _fire,
                      builder: (_, v, child) => Opacity(opacity: burning ? 0.3 + 0.55 * v : 0.3, child: child),
                      child: FxLoop(FireAnim.smoke, key: ValueKey('smoke-$_round'), wake: _wake, paused: paused, quiet: quiet),
                    ),
                  ),
                  shift: const Offset(0, -70),
                ),
              if (burning && !walking)
                _atFire(
                  320,
                  210,
                  const Offset(160, 192),
                  1,
                  ValueListenableBuilder<double>(
                    valueListenable: _fire,
                    builder: (_, v, child) => Opacity(
                      opacity: (v / 0.15).clamp(0.0, 1.0),
                      child: Transform(
                        alignment: const Alignment(0, 0.83),
                        transform: Matrix4.diagonal3Values(0.55 + 0.45 * v, 0.2 + 0.8 * v, 1),
                        child: child,
                      ),
                    ),
                    child: FxLoop(FireAnim.fire, key: ValueKey('flames-$_round'), wake: _wake, paused: paused, quiet: quiet),
                  ),
                ),
              if (_phase == PassPhase.out && !walking) ...[
                _atFire(320, 240, const Offset(160, 130), 1.2, FxOnce(FireAnim.bloom, key: ValueKey('bloom-$_round'), ms: 1700, quiet: quiet)),
                Positioned.fromRect(
                  rect: Rect.fromCenter(center: base.translate(0, -30), width: 300, height: 220),
                  child: RescueBurst(key: ValueKey('rescue-$_round'), muted: _muted, cloud: false),
                ),
              ],
            ],
          ),
        ),
      ),
      // A tap on the bare yard: a miss for the gesture hint (three soon after
      // each other show the hand at once). Everything that takes a move sits
      // above this layer.
      Positioned.fill(
        key: const ValueKey('yard-miss'),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (_) => _hints.missTap()),
      ),
      // Where to stand: three places on the ground.
      if (_phase == PassPhase.stand && !walking && !_intro)
        for (final s in StandSpot.values)
          Positioned(
            key: ValueKey('spot-${s.name}'),
            left: PassStage.spotXIn(s, r) - 30,
            top: PassStage.spotY + _lift - 16,
            width: 60,
            height: 32,
            child: Semantics(
              button: true,
              label: PassLines.spot,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => unawaited(_stand(s, d.globalPosition)),
                child: const CustomPaint(painter: _SpotPainter()),
              ),
            ),
          ),
      // A: the base or the flames.
      if (_phase == PassPhase.pass && !_aimed) ...[
        Positioned(
          key: const ValueKey('aim-flames'),
          left: base.dx - 80,
          top: base.dy - 120,
          width: 160,
          height: 96,
          child: Semantics(
            button: true,
            label: PassLines.flames,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => unawaited(_aim(false, d.globalPosition))),
          ),
        ),
        Positioned(
          key: const ValueKey('aim-base'),
          left: base.dx - 80,
          top: base.dy - 24,
          width: 160,
          height: 40,
          child: Semantics(
            button: true,
            label: PassLines.base,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => unawaited(_aim(true, d.globalPosition))),
          ),
        ),
      ],
      // The trainee at his place, with the extinguisher.
      if (_spot != null && !walking)
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: tb,
          child: Transform.flip(
            flipX: _traineeFlipped,
            child: LinemanFigure(look: LinemanLook.trainee, mode: mode, carry: Carry.dcp, wake: _wake, quiet: quiet),
          ),
        ),
      if (_squeezing)
        KeyedSubtree(
          key: const ValueKey('jet'),
          child: Stack(children: [FxBeam(a: tip, b: aim, thick: 1.8, child: FxLoop(FireAnim.sprayDcp, wake: _wake, quiet: quiet, still: 0.5))]),
        ),
    ];
  }

  // --- gesture hints (how to touch, never what) ------------------------------

  /// The level waits for a move on the scene (not during the intro, the
  /// camera walk, a card, the praise window, a deck or the coworker; not
  /// while the handle is held).
  bool get _hintWaiting =>
      !_intro && _idle && !_cam.isAnimating && !_squeezing && (_phase == PassPhase.stand || _phase == PassPhase.pass);

  /// The three places to stand (scene pixels).
  List<Rect> get _spotRects => [
        for (final s in StandSpot.values) Rect.fromLTWH(PassStage.spotXIn(s, _r) - 30, PassStage.spotY + _lift - 16, 60, 32),
      ]..sort((a, b) => a.left.compareTo(b.left));

  /// The PASS panel's pin head and handle (scene pixels).
  Rect get _headRect => Rect.fromLTWH(8, _sceneH - _inset - 8 - 112, 104, 112);
  Rect get _handleRect => Rect.fromLTWH(120, _sceneH - _inset - 8 - 112, 360 - 126 - 120, 112);

  /// Where to stand: a sweep over all three places. PASS: a sweep over every
  /// part that still takes a touch (the fire's flames and base, the pin head,
  /// the handle — top to bottom, never in PASS order); once only the handle
  /// is left (pin out, aimed), a short hold-and-slide nudge on it.
  HintSpec? _hint() {
    if (_phase == PassPhase.stand) return HintSpec.sweep(_spotRects, space: HintSpace.scene);
    if (_phase != PassPhase.pass) return null;
    if (_pinOut && _aimed) return HintSpec.drag(_handleRect.center, toward: const Offset(1, 0), travel: 56, space: HintSpace.scene);
    final (base, _) = _fireOnScreen;
    return HintSpec.sweep([
      if (!_aimed) ...[
        Rect.fromLTWH(base.dx - 80, base.dy - 120, 160, 96),
        Rect.fromLTWH(base.dx - 80, base.dy - 24, 160, 40),
      ],
      if (!_pinOut) _headRect,
      _handleRect,
    ], space: HintSpace.scene);
  }

  /// The bottom edge: the PASS panel, the table, the decks, the guide.
  List<Widget> _hud(bool quiet) {
    final b = _inset;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final (base, _) = _fireOnScreen;
    return [
      if (_phase == PassPhase.pass && !deckUp)
        Positioned(
          key: const ValueKey('hud-pass'),
          left: 8,
          right: 126,
          bottom: b + 8,
          height: 112,
          child: _PassPanel(
            pinOut: _pinOut,
            squeezing: _squeezing,
            onPull: _pull,
            onSqueezeDown: _squeezeDown,
            onSweep: _sweep,
            onSqueezeUp: _squeezeUp,
          ),
        ),
      ...tableLayers(at: base.translate(0, -132), quiet: quiet),
      if (deckUp)
        Positioned(
          key: const ValueKey('hud-deck'),
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: b),
            child: reasonOpen
                ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-$_round'))
                : coworkerDeck(quiet: quiet, key: const ValueKey('refill-deck')),
          ),
        ),
      if (!_intro) cornerGuide(onTap: _tapGuide, bottom: b + (deckUp ? 236 : 2), onLeft: coworkerFromRight),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
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
            animation: _cam,
            progress: DoProgress(
              labels: PassLines.rounds,
              done: {for (var i = 0; i < _round + (_phase == PassPhase.refill ? 1 : 0); i++) i},
              current: _phase == PassPhase.refill ? null : _round,
              quiet: quiet,
            ),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: 'pass-$_round-${_phase.name}-$_pinOut-$_aimed',
            hintController: _hints,
            layers: (context, m) {
              _lift = m.lift;
              _inset = m.inset;
              _sceneH = m.height;
              return [..._scene(quiet), ..._hud(quiet)];
            },
            overlays: [
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$_slips'),
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
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.fire,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_comboN > 0)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 92,
                  left: 0,
                  right: 0,
                  child: Center(child: ComboPop(key: ValueKey('combo-$_comboN'), mult: _comboMult)),
                ),
              if (_intro)
                GuideIntro(
                  line: PassLines.alarmFirst(_rounds.first.kind),
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _passedRun
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: _caught,
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

/// The extinguisher's head up close (drag the ring out: the pin) and the
/// handle (hold it down: squeeze; slide side to side while holding: sweep).
class _PassPanel extends StatefulWidget {
  const _PassPanel({
    required this.pinOut,
    required this.squeezing,
    required this.onPull,
    required this.onSqueezeDown,
    required this.onSweep,
    required this.onSqueezeUp,
  });

  final bool pinOut;
  final bool squeezing;
  final ValueChanged<Offset> onPull;
  final ValueChanged<Offset> onSqueezeDown;
  final void Function(double dx, Offset at) onSweep;
  final VoidCallback onSqueezeUp;

  @override
  State<_PassPanel> createState() => _PassPanelState();
}

class _PassPanelState extends State<_PassPanel> {
  double _ring = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The head: valve, lever, and the pin through it.
        Semantics(
          label: PassLines.pin,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: widget.pinOut
                ? null
                : (d) {
                    setState(() => _ring = (_ring + d.delta.dx).clamp(0.0, 60.0));
                    if (_ring >= 36) widget.onPull(d.globalPosition);
                  },
            onHorizontalDragEnd: (_) {
              if (!widget.pinOut) setState(() => _ring = 0);
            },
            child: SizedBox(
              width: 104,
              height: 112,
              child: CustomPaint(painter: _HeadPainter(pinOut: widget.pinOut, ring: _ring, squeezing: widget.squeezing)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // The handle: hold and sweep.
        Expanded(
          child: Semantics(
            button: true,
            label: PassLines.squeeze,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => widget.onSqueezeDown(e.position),
              onPointerMove: (e) => widget.onSweep(e.delta.dx, e.position),
              onPointerUp: (_) => widget.onSqueezeUp(),
              onPointerCancel: (_) => widget.onSqueezeUp(),
              child: AnimatedScale(
                scale: widget.squeezing ? 0.95 : 1,
                duration: const Duration(milliseconds: 90),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.squeezing ? const [Color(0xFFB02A1F), Color(0xFF7E1C14)] : const [Color(0xFFE5483A), Color(0xFFB02A1F)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: widget.squeezing ? const [] : const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 6),
                        Text(PassLines.squeeze, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
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

/// The extinguisher's head: red cylinder top, valve, carry handle and squeeze
/// lever, the pin (yellow ring) through them — drawn sliding out.
class _HeadPainter extends CustomPainter {
  _HeadPainter({required this.pinOut, required this.ring, required this.squeezing});
  final bool pinOut;
  final double ring;
  final bool squeezing;

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(20)), Paint()..color = const Color(0xD90A1226));
    final cyl = Rect.fromLTWH(s.width * 0.28, s.height * 0.55, s.width * 0.44, s.height * 0.5);
    c.drawRRect(
      RRect.fromRectAndCorners(cyl, topLeft: const Radius.circular(14), topRight: const Radius.circular(14)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8E1F16), Color(0xFFE5483A), Color(0xFF9E2419)]).createShader(cyl),
    );
    final valve = Rect.fromLTWH(s.width * 0.4, s.height * 0.38, s.width * 0.2, s.height * 0.2);
    c.drawRect(valve, Paint()..color = const Color(0xFF4A4F55));
    // Carry handle (fixed) and the squeeze lever above it.
    final dark = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(s.width * 0.42, s.height * 0.4), Offset(s.width * 0.86, s.height * 0.46), dark);
    final lever = squeezing ? 0.42 : 0.26;
    c.drawLine(Offset(s.width * 0.42, s.height * 0.34), Offset(s.width * 0.86, s.height * lever), dark);
    // The hose.
    c.drawPath(
      Path()
        ..moveTo(s.width * 0.4, s.height * 0.42)
        ..quadraticBezierTo(s.width * 0.12, s.height * 0.5, s.width * 0.16, s.height * 0.9),
      Paint()
        ..color = const Color(0xFF1E2126)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (pinOut) return;
    // The pin through the handles, and its ring (drag it out to the right).
    final y = s.height * 0.37;
    final dx = ring;
    c.drawLine(Offset(s.width * 0.48 + dx, y), Offset(s.width * 0.68 + dx, y), Paint()
      ..color = const Color(0xFFD8DDE2)
      ..strokeWidth = 3);
    c.drawCircle(Offset(s.width * 0.76 + dx, y), 9, Paint()
      ..color = const Color(0xFFFFD34E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4);
    // A thin seal (tamper tag) on the ring.
    c.drawLine(Offset(s.width * 0.76 + dx, y + 9), Offset(s.width * 0.76 + dx, y + 18), Paint()
      ..color = const Color(0xFF39B86A)
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_HeadPainter old) => old.pinOut != pinOut || old.ring != ring || old.squeezing != squeezing;
}

/// A place to stand: a soft ring on the ground with two footprints.
class _SpotPainter extends CustomPainter {
  const _SpotPainter();

  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCenter(center: s.center(Offset.zero), width: s.width - 4, height: s.height - 6);
    c.drawOval(r, Paint()..color = const Color(0x40FFFFFF));
    c.drawOval(r, Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    final foot = Paint()..color = const Color(0xCC1E2126);
    for (final dx in const [-7.0, 7.0]) {
      c.drawOval(Rect.fromCenter(center: s.center(Offset(dx, 0)), width: 7, height: 12), foot);
    }
  }

  @override
  bool shouldRepaint(_SpotPainter old) => false;
}

/// A brick wall.
class _WallPainter extends CustomPainter {
  const _WallPainter();

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF9C5B43));
    final mortar = Paint()
      ..color = const Color(0xFFCDB8A2)
      ..strokeWidth = 1.2;
    for (var y = 9.0, row = 0; y < s.height; y += 9, row++) {
      c.drawLine(Offset(0, y), Offset(s.width, y), mortar);
      for (var x = row.isEven ? 0.0 : 7.0; x < s.width; x += 14) {
        c.drawLine(Offset(x, y - 9), Offset(x, y), mortar);
      }
    }
    c.drawRect(Rect.fromLTWH(0, 0, s.width, 5), Paint()..color = const Color(0xFF7A4433));
  }

  @override
  bool shouldRepaint(_WallPainter old) => false;
}

/// The wind: a windsock on a short pole (it points downwind) and streaks
/// drifting downwind (they move only while the scene is awake).
class _WindPainter extends CustomPainter {
  _WindPainter({required this.fromLeft, required this.sockLeft, required this.t, required this.lift});
  final bool fromLeft;

  /// The windsock's pole is on the left (it always points downwind).
  final bool sockLeft;
  final double t;
  final double lift;

  @override
  void paint(Canvas c, Size s) {
    final dir = fromLeft ? 1.0 : -1.0;
    // Windsock (either side, near the top of the yard).
    final px = sockLeft ? 70.0 : 290.0;
    final top = 150 + lift;
    c.drawLine(Offset(px, top), Offset(px, top + 112), Paint()
      ..color = const Color(0xFF8D98A3)
      ..strokeWidth = 2.4);
    final sway = math.sin(t * 3) * 1.6;
    final sock = Path()
      ..moveTo(px, top + 2)
      ..lineTo(px + dir * 36, top + 6 + sway)
      ..lineTo(px + dir * 36, top + 12 + sway)
      ..lineTo(px, top + 18)
      ..close();
    c.drawPath(sock, Paint()..color = const Color(0xFFFF851B));
    for (final f in const [0.33, 0.66]) {
      c.drawLine(Offset(px + dir * 36 * f, top + 2 + 4 * f), Offset(px + dir * 36 * f, top + 18 - 6 * f), Paint()
        ..color = const Color(0xFFF5F7FA)
        ..strokeWidth = 3);
    }
    // Streaks.
    final streak = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final y = 70 + lift + i * 23.0;
      final x = ((i * 53 + t * 60) % 420) - 30;
      final sx = fromLeft ? x : s.width - x;
      c.drawLine(Offset(sx, y), Offset(sx + dir * 22, y), streak);
    }
  }

  @override
  bool shouldRepaint(_WindPainter old) => old.t != t || old.fromLeft != fromLeft || old.sockLeft != sockLeft || old.lift != lift;
}
