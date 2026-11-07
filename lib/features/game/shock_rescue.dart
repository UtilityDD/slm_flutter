import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'do_parts.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'spoken_once.dart';

// Lesson 1.7, কাজ 1: "ছোঁবেন না!". A colleague is stuck to a live wire and
// every second counts (a whole-second countdown). First action: where a
// switch / MCB is at hand, switch the source off — that is best. Where it is
// not, separate him: pick a dry non-conductor (dry bamboo, plastic chair, dry
// plank — not a wet stick, iron rod or aluminium ladder) and push his arm or
// leg, not the chest or head. Three scenes a play (house, pump room, field,
// roadside), at least one with a switch at hand and one without.
//
// Deadly (owner-approved list): touching the victim (by hand or by his
// shirt); a wet or metal object. Slips: separating when the switch was right
// there; pushing the chest or head; running out of time.
//
// Voice: device TTS only. Art: assets/game/art/shock/ (hand-made SVG, no
// text inside); the victim, wire and objects are drawn in code.

// ============================================================================
// Content
// ============================================================================

enum ShockScene { house, pump, field, roadside }

extension ShockSceneFacts on ShockScene {
  /// A switch / MCB / starter is at hand.
  bool get switchNear => this == ShockScene.house || this == ShockScene.pump;
  String get art => switch (this) {
        ShockScene.house => 'assets/game/art/shock/scene_house.svg',
        ShockScene.pump => 'assets/game/art/shock/scene_pump.svg',
        _ => 'assets/game/art/shock/scene_field.svg',
      };
}

enum RescueAction { grabHand, grabShirt, switchOff, separate }

enum RescueObject { bamboo, chair, plank, wetStick, ironRod, ladder }

extension RescueObjectFacts on RescueObject {
  bool get safe => this == RescueObject.bamboo || this == RescueObject.chair || this == RescueObject.plank;
}

enum BodyZone { head, chest, arm, leg }

@immutable
class RescueRound {
  const RescueRound({required this.scene, required this.objects});
  final ShockScene scene;
  final List<RescueObject> objects;
}

abstract final class RescueLines {
  static const title = 'ছোঁবেন না!';
  static const intro = 'সহকর্মী তারে আটকে গেছে! নিজে বাঁচুন, তারপর বাঁচান — প্রতি সেকেন্ড মূল্যবান।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static String scene(ShockScene s) => switch (s) {
        ShockScene.house => 'বাড়ির ভেতর · মেইন বোর্ড হাতের কাছে',
        ShockScene.pump => 'পাম্প ঘর · স্টার্টার বাক্স পাশে',
        ShockScene.field => 'মাঠে ছেঁড়া এলটি তার · সুইচ নেই, ফোনে নেটওয়ার্ক নেই',
        ShockScene.roadside => 'রাস্তার পাশে ছেঁড়া সার্ভিস তার · সুইচ নেই',
      };
  static const askAction = 'প্রথমে কী করবেন?';
  static const askObject = 'কী দিয়ে আলাদা করবেন?';
  static const askPush = 'কোথায় ধাক্কা দেবেন? ছবিতে ট্যাপ করুন।';
  static String secs(int s) => '${enDigits('$s')} সেকেন্ড';
  static String action(RescueAction a, ShockScene s) => switch (a) {
        RescueAction.grabHand => 'ছুটে গিয়ে হাত ধরে টানি',
        RescueAction.grabShirt => 'জামা ধরে টেনে সরাই',
        RescueAction.switchOff => s == ShockScene.pump ? 'স্টার্টার বন্ধ করি' : 'মেইন সুইচ / MCB বন্ধ করি',
        RescueAction.separate => 'শুকনো কিছু দিয়ে আলাদা করি',
      };
  static const freed = 'আলাদা হলো! এবার সাড়া আর শ্বাস দেখুন।';
  static const switched = 'সোর্স বন্ধ — সবচেয়ে নিরাপদ পথ!';
  static const next = 'পরেরটা';
  static const finish = 'ফলাফল';
  static const objectOk = [FeedbackLine('শুকনো — ঠিক জিনিস!'), FeedbackLine('বিদ্যুৎ টানবে না।'), FeedbackLine('এটাই।')];
  static const allSet = 'মাথা ঠান্ডা, হাত শুকনো — জীবন বাঁচানোর পথ জানেন!';
  static const quick = 'ঝটপট আর নির্ভুল!';
  static const fail = 'আরেকবার — আগে সোর্স, না হলে শুকনো কিছু দিয়ে হাত-পায়ে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtSwitch = 'হাতের কাছের সুইচ আগে বন্ধ';
  static const caughtObject = 'শুকনো জিনিস দিয়ে আলাদা';
  static const caughtPush = 'হাত-পায়ে ধাক্কা';
}

abstract final class RescueMistakes {
  static const touch = DoMistake(
    key: '1.7/rescue/touch',
    textBn: 'শক লাগা মানুষকে ছুঁলেই আপনিও সার্কিটের অংশ — দুজন আহত। নিজে বাঁচুন, তারপর বাঁচান।',
    art: 'assets/game/art/shock/shock_touch.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const shirt = DoMistake(
    key: '1.7/rescue/shirt',
    textBn: 'জামা ধরে টানাও ছোঁয়া — ঘামে ভেজা কাপড় বিদ্যুৎ টানে।',
    art: 'assets/game/art/shock/shock_touch.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const wetStick = DoMistake(
    key: '1.7/rescue/wet-stick',
    textBn: 'ভেজা লাঠি বিদ্যুৎ টানে — শুধু শুকনো কাঠ, বাঁশ, প্লাস্টিকের চেয়ার।',
    art: 'assets/game/art/shock/shock_objects.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const metal = DoMistake(
    key: '1.7/rescue/metal',
    textBn: 'লোহা বা অ্যালুমিনিয়াম — সোজা বিদ্যুতের পথ। শুকনো অপরিবাহী জিনিস চাই।',
    art: 'assets/game/art/shock/shock_objects.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const switchNear = DoMistake(
    key: '1.7/rescue/switch-near',
    textBn: 'সুইচ / MCB হাতের কাছেই ছিল — আগে সোর্স বন্ধ, সেটাই সবচেয়ে নিরাপদ আর দ্রুত।',
    art: 'assets/game/art/shock/shock_source.svg',
    lessonPoint: 1,
  );
  static const chestHead = DoMistake(
    key: '1.7/rescue/chest-head',
    textBn: 'বুক বা মাথায় নয় — ধাক্কা দিন হাতে বা পায়ে, তারের থেকে দূরে।',
    art: 'assets/game/art/shock/shock_push.svg',
    lessonPoint: 1,
  );
  static const late = DoMistake(
    key: '1.7/rescue/late',
    textBn: 'দেরি হয়ে গেল — যতক্ষণ তারে আটকে, ততক্ষণ ভেতরে পুড়ছে। প্রতি সেকেন্ড মূল্যবান।',
    art: 'assets/game/art/shock/shock_source.svg',
    lessonPoint: 1,
  );
  static const all = [touch, shirt, wetStick, metal, switchNear, chestHead, late];
}

/// Three scenes: one with a switch at hand, one without, one either; four
/// objects each (one or two safe).
List<RescueRound> dealRescues(math.Random rng) {
  final a = rng.nextBool() ? ShockScene.house : ShockScene.pump;
  final b = rng.nextBool() ? ShockScene.field : ShockScene.roadside;
  final rest = [...ShockScene.values]..removeWhere((s) => s == a || s == b);
  final scenes = [a, b, rest[rng.nextInt(rest.length)]]..shuffle(rng);
  RescueRound round(ShockScene s) {
    final safe = [RescueObject.bamboo, RescueObject.chair, RescueObject.plank]..shuffle(rng);
    final unsafe = [RescueObject.wetStick, RescueObject.ironRod, RescueObject.ladder]..shuffle(rng);
    final nSafe = 1 + rng.nextInt(2);
    return RescueRound(scene: s, objects: [...safe.take(nSafe), ...unsafe.take(4 - nSafe)]..shuffle(rng));
  }

  return [for (final s in scenes) round(s)];
}

enum RescuePhase { action, object, push, done }

/// The play state (pure logic).
class RescueRun {
  RescueRun(this.rounds);
  final List<RescueRound> rounds;
  int round = 0;
  RescuePhase phase = RescuePhase.action;
  int slips = 0;
  DoMistake? deadly;
  bool late = false;
  final List<String> caught = [];

  bool get done => round >= rounds.length;
  bool get ended => done || deadly != null;
  RescueRound get current => rounds[round.clamp(0, rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  List<RescueAction> get actions => current.scene.switchNear
      ? const [RescueAction.grabHand, RescueAction.switchOff, RescueAction.grabShirt, RescueAction.separate]
      : const [RescueAction.grabHand, RescueAction.separate, RescueAction.grabShirt];

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake? act(RescueAction a) {
    if (ended || phase != RescuePhase.action) return null;
    switch (a) {
      case RescueAction.grabHand:
        return deadly = RescueMistakes.touch;
      case RescueAction.grabShirt:
        return deadly = RescueMistakes.shirt;
      case RescueAction.switchOff:
        phase = RescuePhase.done;
        _tag(RescueLines.caughtSwitch);
        return null;
      case RescueAction.separate:
        if (current.scene.switchNear) {
          slips++;
          return RescueMistakes.switchNear;
        }
        phase = RescuePhase.object;
        return null;
    }
  }

  DoMistake? pick(RescueObject o) {
    if (ended || phase != RescuePhase.object) return null;
    if (o == RescueObject.wetStick) return deadly = RescueMistakes.wetStick;
    if (!o.safe) return deadly = RescueMistakes.metal;
    phase = RescuePhase.push;
    _tag(RescueLines.caughtObject);
    return null;
  }

  DoMistake? push(BodyZone z) {
    if (ended || phase != RescuePhase.push) return null;
    if (z == BodyZone.head || z == BodyZone.chest) {
      slips++;
      return RescueMistakes.chestHead;
    }
    phase = RescuePhase.done;
    _tag(RescueLines.caughtPush);
    return null;
  }

  /// The countdown ran out on this scene.
  DoMistake? timeout() {
    if (ended || phase == RescuePhase.done) return null;
    slips++;
    late = true;
    phase = RescuePhase.done;
    return RescueMistakes.late;
  }

  void next() {
    round++;
    phase = RescuePhase.action;
    late = false;
  }
}

@immutable
class RescuePack {
  const RescuePack({required this.id, required this.titleBn, this.seconds = 15, this.quickMs = 40000});
  final String id;
  final String titleBn;

  /// Countdown per scene.
  final int seconds;
  final int quickMs;
}

const rescuePack17 = RescuePack(id: 'do_1_7_a', titleBn: RescueLines.title);
const rescuePacks = {'do_1_7_a': rescuePack17};

// ============================================================================
// Page
// ============================================================================

class ShockRescuePage extends StatefulWidget {
  const ShockRescuePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final RescuePack pack;
  final bool muted;
  final int? seed;

  @override
  State<ShockRescuePage> createState() => _ShockRescuePageState();
}

class _ShockRescuePageState extends State<ShockRescuePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RescueRunPage(
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

class _RescueRunPage extends ConsumerStatefulWidget {
  const _RescueRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final RescuePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RescueRunPage> createState() => _RescueRunPageState();
}

class _RescueRunPageState extends ConsumerState<_RescueRunPage> with DoDeathGuard {
  final _scoreKey = GlobalKey();
  late final RescueRun _run = RescueRun(dealRescues(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _objectBag = LineBag(RescueLines.objectOk);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  int _chain = 0;
  /// The countdown: only its chip listens (no page rebuild each second).
  late final ValueNotifier<int> _secs = ValueNotifier(widget.pack.seconds);
  Timer? _tick;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _secs.dispose();
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

  Future<void> _start() async {
    _clock.start();
    _startClock();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.8, muted: false));
    await _sayChain([RescueLines.intro, RescueLines.askAction]);
  }

  /// One tick a second (one rebuild a second): the countdown pauses while a
  /// card is up or the scene is done.
  void _startClock() {
    _tick?.cancel();
    _secs.value = widget.pack.seconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended || _card != null || _run.phase == RescuePhase.done) return;
      _secs.value = math.max(0, _secs.value - 1);
      if (_secs.value == 0) {
        final m = _run.timeout();
        if (m != null) {
          unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
          unawaited(_slip(m));
        }
      } else if (_secs.value <= 5) {
        HapticFeedback.selectionClick();
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/tick.wav', volume: 0.4, muted: false));
      }
    });
  }

  Offset _centre() {
    final s = MediaQuery.sizeOf(context);
    return Offset(s.width / 2, s.height * 0.45);
  }

  bool get _idle => !_busy && !_ended && _card == null;

  Future<void> _act(RescueAction a, Offset origin) async {
    if (!_idle) return;
    _hush();
    final m = _run.act(a);
    setState(() {});
    if (m != null) {
      await _mistake(m, origin);
      return;
    }
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
    unawaited(_levelDelta(10 + (_run.phase == RescuePhase.done ? _secs.value : 0), origin, mood: GuideMood.glad));
    unawaited(_sayChain([_run.phase == RescuePhase.done ? RescueLines.switched : RescueLines.askObject], mood: GuideMood.glad));
  }

  Future<void> _pick(RescueObject o, Offset origin) async {
    if (!_idle) return;
    _hush();
    final m = _run.pick(o);
    setState(() {});
    if (m != null) {
      await _mistake(m, origin);
      return;
    }
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.5, muted: false));
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(_sayChain([_objectBag.next().shownBn, RescueLines.askPush], mood: GuideMood.glad));
  }

  Future<void> _push(BodyZone z, Offset origin) async {
    if (!_idle) return;
    _hush();
    final m = _run.push(z);
    setState(() {});
    if (m != null) {
      await _mistake(m, origin);
      return;
    }
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.6, muted: false));
    unawaited(_levelDelta(10 + _secs.value, origin, mood: GuideMood.glad));
    unawaited(_sayChain([RescueLines.freed], mood: GuideMood.glad));
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
    } else {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
    }
  }

  void _next() {
    if (!_idle || _run.phase != RescuePhase.done) return;
    _run.next();
    if (_run.done) {
      _tick?.cancel();
      unawaited(_finish());
      return;
    }
    setState(() {});
    _startClock();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.8, muted: false));
    unawaited(_sayChain([RescueLines.askAction]));
  }

  Future<void> _slip(DoMistake m) async {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('rescue/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _tick?.cancel();
    _clock.stop();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('rescue/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? RescueLines.deadlyWord : RescueLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
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
    final centre = _centre();
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
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? RescueLines.fail : (_quickBonus ? RescueLines.quick : RescueLines.allSet),
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

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final r = _run.current;
    final phase = _run.phase;
    final freed = phase == RescuePhase.done && !_run.late;
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
                      labels: RescueLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
                      current: _run.done ? null : _run.round,
                      quiet: quiet,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(RescueLines.scene(r.scene),
                                style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.gold200)),
                          ),
                          const SizedBox(width: 8),
                          ValueListenableBuilder<int>(
                            valueListenable: _secs,
                            builder: (_, s, _) => _Countdown(secs: s, total: widget.pack.seconds, stopped: phase == RescuePhase.done),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 360,
                              height: 420,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: SvgPicture.asset(r.scene.art, fit: BoxFit.fill)),
                                  Positioned.fill(child: CustomPaint(painter: _VictimPainter(scene: r.scene, freed: freed || (phase == RescuePhase.done)))),
                                  if (phase == RescuePhase.push)
                                    for (final e in _zones.entries)
                                      Positioned.fromRect(
                                        rect: e.value,
                                        child: Semantics(
                                          button: true,
                                          label: 'শরীর',
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTapUp: (d) => unawaited(_push(e.key, d.globalPosition)),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_mark == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                        child: switch (phase) {
                          RescuePhase.action => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final a in _run.actions)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DoBigButton(
                                        label: RescueLines.action(a, r.scene),
                                        filled: false,
                                        onDark: true,
                                        onTapUp: (d) => unawaited(_act(a, d.globalPosition)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          RescuePhase.object => SizedBox(
                              height: 96,
                              child: Row(
                                children: [
                                  for (var i = 0; i < r.objects.length; i++)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: DoDealIn(
                                          index: i,
                                          quiet: quiet,
                                          muted: true,
                                          child: Semantics(
                                            button: true,
                                            label: 'জিনিস',
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTapUp: (d) => unawaited(_pick(r.objects[i], d.globalPosition)),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: SlmColors.ivory,
                                                  borderRadius: BorderRadius.circular(14),
                                                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: CustomPaint(painter: _ObjectPainter(r.objects[i]), size: Size.infinite),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          RescuePhase.push => SizedBox(
                              height: 52,
                              child: Center(
                                child: Text(RescueLines.askPush,
                                    style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                              ),
                            ),
                          RescuePhase.done => SizedBox(
                              width: double.infinity,
                              child: DoBigButton(
                                label: _run.round >= _run.rounds.length - 1 ? RescueLines.finish : RescueLines.next,
                                filled: true,
                                onTapUp: (_) => _next(),
                              ),
                            ),
                        },
                      ),
                    Opacity(opacity: _card == null ? 1 : 0, child: const DoCoachStrip()),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}-${_run.slips}'),
                  mistake: _card!,
                  tone: _cardTone,
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
              if (_mark != null)
                Positioned.fill(
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
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref,
                                    lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

  static const _zones = {
    BodyZone.head: Rect.fromLTRB(146, 134, 194, 180),
    BodyZone.chest: Rect.fromLTRB(146, 182, 186, 248),
    BodyZone.arm: Rect.fromLTRB(186, 184, 226, 248),
    BodyZone.leg: Rect.fromLTRB(144, 252, 198, 322),
  };
}

// ============================================================================
// Pieces
// ============================================================================

class _Countdown extends StatelessWidget {
  const _Countdown({required this.secs, required this.total, required this.stopped});
  final int secs;
  final int total;
  final bool stopped;

  @override
  Widget build(BuildContext context) {
    final urgent = secs <= 5 && !stopped;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? SlmColors.danger : const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 14, color: SlmColors.ivory),
          const SizedBox(width: 4),
          Text(RescueLines.secs(secs), style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ],
      ),
    );
  }
}

/// The colleague stuck to the wire (spark at the hand), or let go.
class _VictimPainter extends CustomPainter {
  _VictimPainter({required this.scene, required this.freed});
  final ShockScene scene;
  final bool freed;

  @override
  void paint(Canvas c, Size s) {
    const hand = Offset(212, 236);
    final wire = Paint()
      ..color = const Color(0xFF1E2228)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final path = Path();
    switch (scene) {
      case ShockScene.house:
        path
          ..moveTo(55, 300)
          ..quadraticBezierTo(120, 330, freed ? 230 : hand.dx, freed ? 318 : hand.dy);
      case ShockScene.pump:
        path
          ..moveTo(88, 246)
          ..quadraticBezierTo(150, 300, freed ? 236 : hand.dx, freed ? 312 : hand.dy);
      case ShockScene.field:
      case ShockScene.roadside:
        path
          ..moveTo(300, 60)
          ..quadraticBezierTo(280, 160, freed ? 260 : hand.dx, freed ? 300 : hand.dy);
        if (!freed) path.quadraticBezierTo(240, 280, 250, 302);
    }
    c.drawPath(path, wire);

    const ground = 318.0;
    const cx = 170.0;
    final cloth = Paint()..color = const Color(0xFF3F5E8C);
    final skin = Paint()..color = const Color(0xFFF0C9A0);
    final limb = Paint()
      ..color = const Color(0xFF2F3B52)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    c.save();
    if (freed) {
      // Pushed clear: he sits back, away from the wire.
      c.translate(cx, ground);
      c.rotate(-0.35);
      c.translate(-cx, -ground);
    }
    c.drawLine(const Offset(cx - 10, 250), const Offset(cx - 14, ground), limb);
    c.drawLine(const Offset(cx + 10, 250), const Offset(cx + 16, ground), limb);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(cx - 22, 182, cx + 22, 256), const Radius.circular(12)), cloth);
    final arm = Paint()
      ..color = const Color(0xFF3F5E8C)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(cx - 20, 192), const Offset(cx - 34, 246), arm);
    c.drawLine(const Offset(cx + 20, 192), freed ? const Offset(cx + 34, 246) : hand, arm);
    c.drawCircle(freed ? const Offset(cx + 34, 250) : hand, 6, skin);
    c.drawCircle(const Offset(cx - 34, 250), 6, skin);
    c.drawCircle(const Offset(cx, 162), 15, skin);
    c.drawArc(Rect.fromCircle(center: const Offset(cx, 156), radius: 16), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2B632));
    c.restore();
    if (!freed) {
      // A static spark at the grip (no loop: the scene stays still).
      final glow = Paint()
        ..color = const Color(0x99FFD21F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      c.drawCircle(hand, 16, glow);
      final ray = Paint()
        ..color = const Color(0xFFFFD21F)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 7; i++) {
        final a = i * math.pi * 2 / 7;
        c.drawLine(hand + Offset(math.cos(a), math.sin(a)) * 10, hand + Offset(math.cos(a), math.sin(a)) * 20, ray);
      }
      // Body tremor marks.
      final mark = Paint()
        ..color = const Color(0xFFE8590C)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(cx - 34, 170), const Offset(cx - 42, 166), mark);
      c.drawLine(const Offset(cx - 36, 210), const Offset(cx - 45, 210), mark);
      c.drawLine(const Offset(cx + 30, 160), const Offset(cx + 38, 154), mark);
    }
  }

  @override
  bool shouldRepaint(_VictimPainter old) => old.scene != scene || old.freed != freed;
}

/// The objects at hand, drawn so the difference shows: dry bamboo, plastic
/// chair, dry plank — wet stick (drops), iron rod (grey), aluminium ladder.
class _ObjectPainter extends CustomPainter {
  _ObjectPainter(this.o);
  final RescueObject o;

  @override
  void paint(Canvas c, Size s) {
    final a = Offset(s.width * 0.15, s.height * 0.88);
    final b = Offset(s.width * 0.85, s.height * 0.12);
    final t = math.max(5.0, s.height * 0.11);
    switch (o) {
      case RescueObject.bamboo:
        c.drawLine(a, b, Paint()..color = const Color(0xFFC2A766)..strokeWidth = t..strokeCap = StrokeCap.round);
        for (var u = 0.15; u < 0.95; u += 0.2) {
          c.drawCircle(Offset.lerp(a, b, u)!, t * 0.6, Paint()..color = const Color(0xFF8A7536));
        }
      case RescueObject.plank:
        c.save();
        c.translate(s.width / 2, s.height / 2);
        c.rotate(-0.8);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s.width * 0.95, height: t * 1.6), const Radius.circular(2)),
            Paint()..color = const Color(0xFFB98B54));
        final grain = Paint()
          ..color = const Color(0xFF8C6334)
          ..strokeWidth = 1;
        c.drawLine(Offset(-s.width * 0.4, -t * 0.3), Offset(s.width * 0.4, -t * 0.2), grain);
        c.drawLine(Offset(-s.width * 0.35, t * 0.3), Offset(s.width * 0.42, t * 0.35), grain);
        c.restore();
      case RescueObject.chair:
        final p = Paint()
          ..color = const Color(0xFF2F6FD0)
          ..strokeWidth = t * 0.7
          ..strokeCap = StrokeCap.round;
        final l = s.width * 0.28;
        final r = s.width * 0.72;
        c.drawLine(Offset(l, s.height * 0.12), Offset(l, s.height * 0.55), p);
        c.drawLine(Offset(r, s.height * 0.12), Offset(r, s.height * 0.55), p);
        c.drawLine(Offset(l, s.height * 0.12), Offset(r, s.height * 0.12), p);
        c.drawRect(Rect.fromLTRB(l - 4, s.height * 0.5, r + 4, s.height * 0.6), Paint()..color = const Color(0xFF2F6FD0));
        c.drawLine(Offset(l, s.height * 0.6), Offset(l - 6, s.height * 0.92), p);
        c.drawLine(Offset(r, s.height * 0.6), Offset(r + 6, s.height * 0.92), p);
      case RescueObject.wetStick:
        c.drawLine(a, b, Paint()..color = const Color(0xFF5E4A2E)..strokeWidth = t..strokeCap = StrokeCap.round);
        final drop = Paint()..color = const Color(0xFF5AA0D8);
        for (final u in const [0.25, 0.45, 0.65, 0.8]) {
          final p = Offset.lerp(a, b, u)!;
          c.drawCircle(p.translate(t * 0.6, t * 1.1), 2.6, drop);
        }
        c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.3, s.height * 0.95), width: s.width * 0.4, height: 6), Paint()..color = const Color(0x665AA0D8));
      case RescueObject.ironRod:
        c.drawLine(a, b, Paint()..color = const Color(0xFF6B747C)..strokeWidth = t * 0.8..strokeCap = StrokeCap.round);
        c.drawLine(Offset.lerp(a, b, 0.1)!, Offset.lerp(a, b, 0.9)!, Paint()..color = const Color(0xFFB8C0C7)..strokeWidth = 1.5);
      case RescueObject.ladder:
        final p = Paint()
          ..color = const Color(0xFFAEB6BD)
          ..strokeWidth = t * 0.5;
        final l = s.width * 0.3;
        final r = s.width * 0.7;
        c.drawLine(Offset(l, s.height * 0.05), Offset(l - 4, s.height * 0.95), p);
        c.drawLine(Offset(r, s.height * 0.05), Offset(r + 4, s.height * 0.95), p);
        for (var y = 0.15; y < 0.95; y += 0.18) {
          c.drawLine(Offset(l, s.height * y), Offset(r, s.height * y), p);
        }
    }
  }

  @override
  bool shouldRepaint(_ObjectPainter old) => old.o != o;
}
