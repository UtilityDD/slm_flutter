import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'do_parts.dart';
import 'fire_choose.dart' show FireKind, FireScenePainter;
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'ptw_steps.dart' show StepCard, StepSlot, StepTrayCard;
import 'spoken_once.dart';

// Lesson 1.8, কাজ 2: "PASS". Two fires. First, where to stand — seen from
// above: wind at your back (not in the smoke), and an open way out behind you
// (not backed into a corner). Then the extinguisher, step by step: Pull the
// pin → Aim (tap the base of the fire, not the flames) → Squeeze → Sweep.
// At the end: "অর্ধেকটা রেখে দাও পরের বারের জন্য" — no, it goes for refill.
//
// Deadly: none (owner-approved list: cornered without escape costs points).
// Slips: standing downwind or cornered; a PASS step out of order; aiming at
// the flames; keeping a used extinguisher.
//
// Voice: device TTS only. Art: assets/game/art/fire/ (hand-made SVG).

// ============================================================================
// Content
// ============================================================================

enum StandSpot { upwind, cornered, downwind }

@immutable
class PassRound {
  const PassRound({required this.kind, required this.windFromLeft});
  final FireKind kind;
  final bool windFromLeft;
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
  static const askStand = 'কোথায় দাঁড়াবেন? ওপর থেকে দেখুন — বাতাস আর বেরোনোর পথ।';
  static const askPass = 'এবার PASS — পরের ধাপটা ট্যাপ করুন।';
  static const askAim = 'কোথায় তাক করবেন? আগুনে ট্যাপ করুন।';
  static const stood = 'ঠিক জায়গা — বাতাস পেছনে, পথ খোলা।';
  static const aimed = 'গোড়ায় — ঠিক!';
  static const out = 'আগুন নিভল!';
  static const next = 'পরের আগুন';
  static const wind = 'বাতাস';
  static const legendWind = 'বাতাসের দিক';
  static const tourWind = 'বাতাস এদিকে বইছে — ধোঁয়াও ওদিকে যাচ্ছে।';
  static const tourWall = 'আর এখানে দেয়াল।';
  static const tourWhere = 'কোথায় দাঁড়াবেন — এখানে? এখানে? না এখানে?';
  static const legendSmoke = 'ধোঁয়া';
  static const legendWall = 'দেয়াল';
  static const ok = [FeedbackLine('ঠিক!'), FeedbackLine('এটাই পরের ধাপ।'), FeedbackLine('বেশ!')];
  static const refillWho = 'সাথী';
  static const refillLine = 'অর্ধেকটা তো বাকি — রেখে দাও, পরের বার কাজে লাগবে।';
  static const giveIn = 'ঠিক, রেখে দিই';
  static const holdOut = 'না — রিফিলে পাঠাই';
  static const refillOk = 'ঠিক! একবার চাপলেই চাপ বেরিয়ে যায় — রিফিল চাই।';
  static const allSet = 'বাতাস পেছনে, পথ খোলা, PASS নিখুঁত — আগুন আপনার নিয়ন্ত্রণে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দাঁড়ানোর জায়গা আর PASS-এর ক্রম মনে রেখে।';
  static const caughtStand = 'বাতাস পেছনে, পথ খোলা রেখে দাঁড়ানো';
  static const caughtAim = 'আগুনের গোড়ায় তাক';
  static const caughtRefill = 'ব্যবহৃত সিলিন্ডার রিফিলে';
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
  static const order = DoMistake(
    key: '1.8/pass/order',
    textBn: 'ক্রম উল্টে গেল — P: পিন টানুন, A: গোড়ায় তাক, S: হ্যান্ডেল চাপুন, S: এপাশ-ওপাশ ঝাড়ুন।',
    art: 'assets/game/art/fire/pass_order.svg',
    lessonPoint: 3,
  );
  static const aimTip = DoMistake(
    key: '1.8/pass/aim-tip',
    textBn: 'শিখায় তাক করলে পাউডার উড়ে যায় — আগুনের গোড়ায় তাক করুন, যেখানে জ্বালানি জ্বলছে।',
    art: 'assets/game/art/fire/aim_base.svg',
    lessonPoint: 3,
  );
  static const keep = DoMistake(
    key: '1.8/pass/keep-half',
    textBn: 'একবার চাপলেই চাপ বেরিয়ে যায় — পরের বার কাজ করবে না। ব্যবহৃত সিলিন্ডার রিফিলে পাঠান।',
    art: 'assets/game/art/fire/refill.svg',
    lessonPoint: 2,
  );
  static const all = [downwind, cornered, order, aimTip, keep];
}

List<PassRound> dealPass(math.Random rng) {
  final kinds = [FireKind.oil, FireKind.grass]..shuffle(rng);
  final left = rng.nextBool();
  return [
    PassRound(kind: kinds[0], windFromLeft: left),
    PassRound(kind: kinds[1], windFromLeft: !left),
  ];
}

List<OrderRoundSpec> passOrderRounds() => [
      OrderRoundSpec(groups: [for (final c in passCards) OrderGroup([c.id], skipMistake: PassMistakes.order)]),
    ];

enum PassPhase { stand, order, aim, out, refill }

@immutable
class PassPack {
  const PassPack({required this.id, required this.titleBn, this.quickMs = 50000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const passPack18 = PassPack(id: 'do_1_8_b', titleBn: PassLines.title);
const passPacks = {'do_1_8_b': passPack18};

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

class _PassRunPageState extends ConsumerState<_PassRunPage> with DoStrikeOut {
  final _scoreKey = GlobalKey();
  late final List<PassRound> _rounds;
  late final List<List<StepCard>> _trays;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _okBag = LineBag(PassLines.ok);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  // The guided tour points at these (on the top view).
  final _windKey = GlobalKey();
  final _wallKey = GlobalKey();
  final Map<StandSpot, GlobalKey> _spotKeys = {for (final sp in StandSpot.values) sp: GlobalKey()};

  final _combo = Combo();
  int _comboN = 0;
  int _comboMult = 1;
  int? _stars;

  List<TourBeat> get _tourBeats {
    // The spots are pointed at in a shuffled order (never the answer first by rule).
    final order = [...StandSpot.values]..shuffle(math.Random(_round * 7 + 3));
    return [
      TourBeat(PassLines.tourWind, target: _windKey),
      TourBeat(PassLines.tourWall, target: _wallKey),
      TourBeat(PassLines.tourWhere, targets: [for (final sp in order) _spotKeys[sp]!]),
    ];
  }

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
  final List<String> _caught = [];

  int _round = 0;
  PassPhase _phase = PassPhase.stand;
  OrderRun _order = OrderRun(passOrderRounds());
  int _slips = 0;
  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  int _shakes = 0;
  String? _shook;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  String get _rungId => widget.ctx.rungId;
  PassRound get _r => _rounds[_round];
  int get _percent => (100 - 15 * _slips).clamp(0, 100);
  bool get _passedRun => _percent >= 55;

  @override
  void initState() {
    super.initState();
    _rounds = dealPass(widget.rng);
    _trays = [for (var i = 0; i < 2; i++) [...passCards]..shuffle(widget.rng)];
  }

  @override
  void dispose() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk, bool other = false}) async {
    if (line.trim().isEmpty || !mounted) return;
    if (!other) ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted, rival: other);
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

  /// After the guide's intro: the clock runs and play begins.
  Future<void> _start() async {
    _clock.start();
  }

  bool get _idle => !_ended && _card == null;

  Future<void> _stand(StandSpot s, Offset origin) async {
    if (!_idle || _phase != PassPhase.stand) return;
    _hush();
    if (s != StandSpot.upwind) {
      _slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(s == StandSpot.downwind ? PassMistakes.downwind : PassMistakes.cornered);
      return;
    }
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
    if (!_caught.contains(PassLines.caughtStand)) _caught.add(PassLines.caughtStand);
    unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
    setState(() => _phase = PassPhase.order);
    unawaited(_sayChain([PassLines.stood, PassLines.askPass], mood: GuideMood.glad));
  }

  void _tapCard(StepCard c, Offset origin) {
    if (!_idle || _phase != PassPhase.order) return;
    final t = _order.tap(c.id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        return;
      case OrderTapKind.mistake:
        _slips++;
        setState(() {
          _shakes++;
          _shook = c.id;
        });
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(t.mistake!));
      case OrderTapKind.ok:
        HapticFeedback.lightImpact();
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
        unawaited(_levelDelta(_scored(5), origin, mood: GuideMood.glad));
        if (c.id == PassIds.aim) {
          setState(() => _phase = PassPhase.aim);
          unawaited(_sayChain([PassLines.askAim]));
          return;
        }
        if (t.allDone) {
          HapticFeedback.mediumImpact();
          if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
          unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
          setState(() => _phase = PassPhase.out);
          unawaited(_sayChain([PassLines.out], mood: GuideMood.glad));
          return;
        }
        setState(() {});
        unawaited(_sayChain([_okBag.next().shownBn], mood: GuideMood.glad));
    }
  }

  Future<void> _aim(bool base, Offset origin) async {
    if (!_idle || _phase != PassPhase.aim) return;
    _hush();
    if (!base) {
      _slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(PassMistakes.aimTip);
      return;
    }
    HapticFeedback.lightImpact();
    if (!_caught.contains(PassLines.caughtAim)) _caught.add(PassLines.caughtAim);
    unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
    setState(() => _phase = PassPhase.order);
    unawaited(_sayChain([PassLines.aimed], mood: GuideMood.glad));
  }

  void _next() {
    if (!_idle || _phase != PassPhase.out) return;
    if (_round == _rounds.length - 1) {
      // The used extinguisher: keep it, or send it for refill?
      _hush();
      HapticFeedback.heavyImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.6, muted: false));
      setState(() => _phase = PassPhase.refill);
      unawaited(_say(PassLines.refillLine, other: true));
      return;
    }
    setState(() {
      _round++;
      _order = OrderRun(passOrderRounds());
      _phase = PassPhase.stand;
    });
    unawaited(_sayChain([PassLines.askStand]));
  }

  Future<void> _refill(bool held, Offset origin) async {
    if (!_idle || _phase != PassPhase.refill) return;
    _hush();
    if (!held) {
      _slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(PassMistakes.keep);
      return;
    }
    _caught.add(PassLines.caughtRefill);
    unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
    unawaited(_sayChain([PassLines.refillOk], mood: GuideMood.glad));
    unawaited(_finish());
  }

  /// The third small mistake: the level fails and the lesson card insists.
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
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
    setState(() => _card = m);
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

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final r = _r;
    final top = _phase == PassPhase.stand;
    final placed = [for (final c in passCards) if (_order.isDone(c.id) || _order.done) c.id];
    final tray = [for (final c in _trays[_round]) if (!placed.contains(c.id)) c];
    final base = FireScenePainter.baseOf(r.kind);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Column(
                  children: [
                    LevelShellBar(
                      context_: widget.ctx,
                      titleBn: widget.pack.titleBn,
                      scoreKey: _scoreKey,
                      levelScore: _runScore,
                      muted: _muted,
                      onClose: () => unawaited(_leave()),
                      onToggleMute: () {
                        unawaited(MascotSpeechLibrary.stop());
                        setState(() => _muted = !_muted);
                      },
                    ),
                    DoProgress(
                      labels: PassLines.rounds,
                      done: {if (_round >= 1) 0, if (_mark != null) 1},
                      current: _mark != null ? null : _round,
                      quiet: quiet,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 250,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 360,
                              height: 300,
                              child: top
                                  ? _TopView(
                                      key: ValueKey('top-$_round'),
                                      windFromLeft: r.windFromLeft,
                                      windKey: _windKey,
                                      wallKey: _wallKey,
                                      spotKeys: _spotKeys,
                                      onSpot: (s, o) => unawaited(_stand(s, o)),
                                    )
                                  : Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: -120,
                                          width: 360,
                                          height: 420,
                                          child: Stack(
                                            children: [
                                              Positioned.fill(child: SvgPicture.asset('assets/game/art/fire/yard.svg', fit: BoxFit.fill)),
                                              Positioned.fill(
                                                child: CustomPaint(painter: FireScenePainter(kind: r.kind, out: _phase == PassPhase.out || _phase == PassPhase.refill)),
                                              ),
                                              if (_phase == PassPhase.out)
                                                Positioned.fromRect(
                                                  rect: Rect.fromCenter(center: base.translate(0, -30), width: 300, height: 220),
                                                  child: RescueBurst(key: ValueKey('rescue-$_round'), muted: _muted),
                                                ),
                                              if (_phase == PassPhase.aim) ...[
                                                Positioned.fromRect(
                                                  rect: Rect.fromCenter(center: base.translate(0, -6), width: 170, height: 26),
                                                  child: Semantics(
                                                    button: true,
                                                    label: 'গোড়া',
                                                    child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => unawaited(_aim(true, d.globalPosition))),
                                                  ),
                                                ),
                                                Positioned.fromRect(
                                                  rect: Rect.fromCenter(center: base.translate(0, -50), width: 170, height: 52),
                                                  child: Semantics(
                                                    button: true,
                                                    label: 'শিখা',
                                                    child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => unawaited(_aim(false, d.globalPosition))),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: switch (_phase) {
                        PassPhase.stand => Center(
                            child: Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _legend(Icons.east_rounded, const Color(0xFF6FA8E8), PassLines.legendWind),
                                _legend(Icons.cloud_rounded, const Color(0xFFB0B6BC), PassLines.legendSmoke),
                                _legend(Icons.fence_rounded, const Color(0xFFB59B76), PassLines.legendWall),
                              ],
                            ),
                          ),
                        PassPhase.refill => Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 22),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(22)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(PassLines.refillWho, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
                                  const SizedBox(height: 6),
                                  Text('“${PassLines.refillLine}”',
                                      textAlign: TextAlign.center,
                                      style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.4)),
                                  const SizedBox(height: 14),
                                  if (_mark == null && !_ended)
                                    Row(
                                      children: [
                                        Expanded(child: DoBigButton(label: PassLines.giveIn, filled: false, onTapUp: (d) => unawaited(_refill(false, d.globalPosition)))),
                                        const SizedBox(width: 10),
                                        Expanded(child: DoBigButton(label: PassLines.holdOut, filled: true, onTapUp: (d) => unawaited(_refill(true, d.globalPosition)))),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        _ => ListView(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            children: [
                              for (var i = 0; i < passCards.length; i++)
                                StepSlot(
                                  index: i,
                                  card: placed.contains(passCards[i].id) ? passCards[i] : null,
                                  note: null,
                                  quiet: quiet,
                                ),
                              const SizedBox(height: 8),
                              if (_phase == PassPhase.order)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final c in tray)
                                      StepTrayCard(
                                        key: ValueKey('tray-$_round-${c.id}-${_shook == c.id ? _shakes : 0}'),
                                        card: c,
                                        shake: _shook == c.id,
                                        quiet: quiet,
                                        onTap: (o) => _tapCard(c, o),
                                      ),
                                  ],
                                ),
                              if (_phase == PassPhase.out)
                                DoBigButton(label: PassLines.next, filled: true, onTapUp: (_) => _next()),
                            ],
                          ),
                      },
                    ),
                    Opacity(opacity: _card == null ? 1 : 0, child: DoCoachStrip(tasks: PassLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
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
                          unawaited(openLessonPoint(context, ref,
                              lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
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
                GuidedTour(
                  beats: _tourBeats,
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
                                onRead: () => unawaited(openLessonPoint(context, ref,
                                    lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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

Widget _legend(IconData icon, Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(text, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
      ],
    );

// ============================================================================
// Top view: fire, wind, wall, three places to stand
// ============================================================================

class _TopView extends StatelessWidget {
  const _TopView({
    super.key,
    required this.windFromLeft,
    required this.windKey,
    required this.wallKey,
    required this.spotKeys,
    required this.onSpot,
  });
  final bool windFromLeft;
  final GlobalKey windKey;
  final GlobalKey wallKey;
  final Map<StandSpot, GlobalKey> spotKeys;
  final void Function(StandSpot s, Offset origin) onSpot;

  /// Spot centres (scene 360 x 300); mirrored when the wind comes from the right.
  Map<StandSpot, Offset> get spots {
    double x(double v) => windFromLeft ? v : 360 - v;
    return {
      StandSpot.upwind: Offset(x(70), 210),
      StandSpot.cornered: Offset(x(84), 78),
      StandSpot.downwind: Offset(x(292), 150),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sp = spots;
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _TopPainter(windFromLeft: windFromLeft, spots: sp))),
        // Regions the guided tour lights up.
        Positioned.fromRect(
          rect: const Rect.fromLTRB(100, 246, 260, 292),
          child: KeyedSubtree(key: windKey, child: const IgnorePointer(child: SizedBox.expand())),
        ),
        Positioned.fromRect(
          rect: windFromLeft ? const Rect.fromLTRB(24, 24, 156, 136) : const Rect.fromLTRB(204, 24, 336, 136),
          child: KeyedSubtree(key: wallKey, child: const IgnorePointer(child: SizedBox.expand())),
        ),
        for (final e in sp.entries)
          Positioned.fromRect(
            rect: Rect.fromCenter(center: e.value, width: 64, height: 64),
            child: KeyedSubtree(key: spotKeys[e.key], child: Semantics(
              button: true,
              label: 'জায়গা',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => onSpot(e.key, d.globalPosition)),
            )),
          ),
      ],
    );
  }
}

class _TopPainter extends CustomPainter {
  _TopPainter({required this.windFromLeft, required this.spots});
  final bool windFromLeft;
  final Map<StandSpot, Offset> spots;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFC9B98F));
    final dot = Paint()..color = const Color(0x22000000);
    final rnd = math.Random(2);
    for (var i = 0; i < 60; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height), 1.5, dot);
    }
    double x(double v) => windFromLeft ? v : 360 - v;
    // The wall boxing in the corner spot.
    final wall = Paint()..color = const Color(0xFF7A6A52);
    c.drawRect(Rect.fromLTRB(math.min(x(30), x(150)), 30, math.max(x(30), x(150)), 44), wall);
    c.drawRect(Rect.fromLTRB(math.min(x(30), x(44)), 30, math.max(x(30), x(44)), 130), wall);
    // The fire (seen from above) and its smoke blowing downwind.
    const fire = Offset(180, 150);
    final smoke = Paint()..color = const Color(0x888D949B);
    for (var i = 1; i <= 4; i++) {
      c.drawCircle(Offset(x(180 + i * 34.0), 150 - i * 4.0), 14.0 + i * 5, smoke);
    }
    c.drawCircle(fire, 34, Paint()..color = const Color(0xFFF05A28));
    c.drawCircle(fire, 20, Paint()..color = const Color(0xFFFFD21F));
    // Wind arrows.
    final arrow = Paint()
      ..color = const Color(0xFF2F6FD0)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final y in const [258.0, 280.0]) {
      final a = Offset(x(110), y);
      final b = Offset(x(250), y);
      c.drawLine(a, b, arrow);
      final d = windFromLeft ? -1.0 : 1.0;
      c.drawLine(b, b.translate(10 * d, -7), arrow);
      c.drawLine(b, b.translate(10 * d, 7), arrow);
    }
    // Places to stand.
    for (final p in spots.values) {
      c.drawCircle(p, 22, Paint()..color = const Color(0xCCFFFFFF));
      c.drawCircle(
        p,
        22,
        Paint()
          ..color = const Color(0xFF31363C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      c.drawCircle(p.translate(0, -6), 6, Paint()..color = const Color(0xFFF0C9A0));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 8), width: 16, height: 14), const Radius.circular(4)),
          Paint()..color = const Color(0xFF3F5E8C));
    }
  }

  @override
  bool shouldRepaint(_TopPainter old) => old.windFromLeft != windFromLeft;
}
