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
import 'do_parts.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'ptw_steps.dart' show StepCard, StepSlot, StepTrayCard;
import 'spoken_once.dart';

// Lesson 1.7, কাজ 2: "গোল্ডেন মিনিট". The colleague is off the wire but does
// not move. Round 1 (order): check response → check breathing → have someone
// call the ambulance → CPR (if trained) → keep going until help comes.
// Round 2 (say no): the crowd's advice, three of four each play — "মাটিতে
// পুঁতে দাও", "পোড়ায় বরফ ঘষো", "কথা বলছে, হাসপাতাল লাগবে না", "এলটি শক,
// কিছু হয় না".
//
// Deadly: none (owner-approved list: "wrong order costs points"). Slips:
// steps out of order; giving in to the crowd.
//
// Voice: device TTS only. Art: assets/game/art/shock/ (hand-made SVG).

// ============================================================================
// Content
// ============================================================================

abstract final class GoldenIds {
  static const response = 'response';
  static const breathing = 'breathing';
  static const call = 'call';
  static const cpr = 'cpr';
  static const keep = 'keep';
}

const goldenCards = [
  StepCard(GoldenIds.response, 'সাড়া দেখা', 'কাঁধে আলতো ঝাঁকুনি, জোরে — “আপনি ঠিক আছেন?”', Icons.record_voice_over_rounded),
  StepCard(GoldenIds.breathing, 'শ্বাস দেখা', 'বুক ওঠানামা করছে কিনা দেখা', Icons.air_rounded),
  StepCard(GoldenIds.call, 'অ্যাম্বুলেন্স ডাকা', 'একজনকে এখনই অ্যাম্বুলেন্সে কল করতে বলা', Icons.local_hospital_rounded),
  StepCard(GoldenIds.cpr, 'CPR শুরু', 'প্রশিক্ষিত হলে বুকের মাঝখানে চাপ', Icons.favorite_rounded),
  StepCard(GoldenIds.keep, 'চালিয়ে যাওয়া', 'অ্যাম্বুলেন্স না আসা বা জ্ঞান না ফেরা পর্যন্ত', Icons.timer_rounded),
];

enum CrowdMyth { mud, ice, home, lowVolt }

abstract final class GoldenLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askOrder, askCrowd];

  static const title = 'গোল্ডেন মিনিট';
  static const intro = 'সহকর্মী তার থেকে আলাদা — কিন্তু নড়ছে না। মাথা ঠান্ডা, ধাপে ধাপে।';
  static const rounds = ['ধাপ', 'ভিড়ের কথা'];
  static const scene = 'সহকর্মী তারের থেকে আলাদা · নড়ছে না';
  static const askOrder = 'কোনটা আগে? পরের ধাপটা ট্যাপ করুন।';
  static const askCrowd = 'ভিড় জমেছে — সবাই কিছু না কিছু বলছে।';
  static const ordered = 'ধাপ ঠিক — এবার ভিড় সামলান।';
  static const next = 'ভিড়ের কথায়';
  static const finish = 'ফলাফল';
  static const ok = [FeedbackLine('ঠিক!'), FeedbackLine('এটাই পরের ধাপ।'), FeedbackLine('বেশ!')];
  static const crowdWho = 'ভিড়ের একজন';
  static String myth(CrowdMyth m) => switch (m) {
        CrowdMyth.mud => 'মাটিতে পুঁতে দাও, কাদা মাখাও — বিদ্যুৎ বেরিয়ে যাবে!',
        CrowdMyth.ice => 'পোড়া জায়গায় বরফ ঘষে দাও, মলম লাগাও!',
        CrowdMyth.home => 'জ্ঞান ফিরেছে, কথা বলছে — হাসপাতাল লাগবে না।',
        CrowdMyth.lowVolt => 'এলটি লাইনের শক তো — তেমন কিছু না, একটু জল খাইয়ে দাও।',
      };
  static String giveIn(CrowdMyth m) => switch (m) {
        CrowdMyth.mud => 'ঠিক, পুঁতে দিই',
        CrowdMyth.ice => 'ঠিক, বরফ দিই',
        CrowdMyth.home => 'ঠিক, বাড়ি পাঠাই',
        CrowdMyth.lowVolt => 'ঠিক, জল দিই',
      };
  static String holdOut(CrowdMyth m) => switch (m) {
        CrowdMyth.mud => 'না — অ্যাম্বুলেন্স',
        CrowdMyth.ice => 'না — হাত দেব না',
        CrowdMyth.home => 'না — হাসপাতালে নেব',
        CrowdMyth.lowVolt => 'না — হাসপাতাল',
      };
  static String right(CrowdMyth m) => switch (m) {
        CrowdMyth.mud => 'ঠিক! কাদা-মাটি সময় নষ্ট আর ক্ষতে সংক্রমণ।',
        CrowdMyth.ice => 'ঠিক! পোড়ায় বরফ-মলম নয় — ডাক্তার দেখবেন।',
        CrowdMyth.home => 'ঠিক! ভেতরের ক্ষতি বাইরে দেখা যায় না।',
        CrowdMyth.lowVolt => 'ঠিক! ভোল্টেজ নয়, কারেন্ট মারে — এলটিও।',
      };
  static const allSet = 'গোল্ডেন মিনিটের হিরো — ধাপে ধাপে, গুজবে না।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — সাড়া, শ্বাস, অ্যাম্বুলেন্স, CPR।';
  static const caughtOrder = 'সাড়া → শ্বাস → অ্যাম্বুলেন্স → CPR';
  static const caughtCrowd = 'ভিড়ের গুজবে “না”';
}

abstract final class GoldenMistakes {
  static const order = DoMistake(
    key: '1.7/golden/order',
    textBn: 'ধাপ উল্টে গেল — আগে সাড়া আর শ্বাস দেখা, তারপর অ্যাম্বুলেন্স ডাকা, তারপর CPR, সাহায্য না আসা পর্যন্ত।',
    art: 'assets/game/art/shock/cpr_order.svg',
    lessonPoint: 3,
  );
  static DoMistake myth(CrowdMyth m) => switch (m) {
        CrowdMyth.mud => const DoMistake(
            key: '1.7/golden/mud',
            textBn: 'মাটিতে পোঁতা বা কাদা মাখানো ভয়ঙ্কর গুজব — সময় নষ্ট, পোড়া ক্ষতে সংক্রমণ। একমাত্র পথ অ্যাম্বুলেন্স আর ডাক্তার।',
            art: 'assets/game/art/shock/mud_myth.svg',
            lessonPoint: 3),
        CrowdMyth.ice => const DoMistake(
            key: '1.7/golden/ice',
            textBn: 'পোড়া জায়গায় বরফ, জল বা মলম নয় — হাত দেবেন না, ডাক্তারের কাছে নিন।',
            art: 'assets/game/art/shock/burn_care.svg',
            lessonPoint: 3),
        CrowdMyth.home => const DoMistake(
            key: '1.7/golden/home',
            textBn: 'কথা বললেও হাসপাতালে নিন — শকের ভেতরের ক্ষতি বাইরে দেখা যায় না।',
            art: 'assets/game/art/shock/mud_myth.svg',
            lessonPoint: 3),
        CrowdMyth.lowVolt => const DoMistake(
            key: '1.7/golden/low-volt',
            textBn: 'ভোল্টেজ নয়, কারেন্ট মারে — এলটি শকও ভেজা শরীরে হৃৎপিণ্ড থামাতে পারে। হাসপাতালে নিন।',
            art: 'assets/game/art/shock/mud_myth.svg',
            lessonPoint: 3),
      };
  static List<DoMistake> get all => [order, for (final m in CrowdMyth.values) myth(m)];
}

List<OrderRoundSpec> goldenRounds() => [
      OrderRoundSpec(groups: [
        for (final c in goldenCards) OrderGroup([c.id], skipMistake: GoldenMistakes.order),
      ]),
    ];

/// The play's crowd: three of the four myths, in random order.
List<CrowdMyth> dealCrowd(math.Random rng) => ([...CrowdMyth.values]..shuffle(rng)).take(3).toList();

@immutable
class GoldenPack {
  const GoldenPack({required this.id, required this.titleBn, this.quickMs = 45000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const goldenPack17 = GoldenPack(id: 'do_1_7_b', titleBn: GoldenLines.title);
const goldenPacks = {'do_1_7_b': goldenPack17};

// ============================================================================
// Page
// ============================================================================

class GoldenMinutePage extends StatefulWidget {
  const GoldenMinutePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final GoldenPack pack;
  final bool muted;
  final int? seed;

  @override
  State<GoldenMinutePage> createState() => _GoldenMinutePageState();
}

class _GoldenMinutePageState extends State<GoldenMinutePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GoldenRunPage(
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

class _GoldenRunPage extends ConsumerStatefulWidget {
  const _GoldenRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final GoldenPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GoldenRunPage> createState() => _GoldenRunPageState();
}

class _GoldenRunPageState extends ConsumerState<_GoldenRunPage> with DoStrikeOut {
  final _scoreKey = GlobalKey();
  final OrderRun _order = OrderRun(goldenRounds());
  // Dealt in a fixed order in initState: the crowd first, then the tray.
  late final List<CrowdMyth> _crowd;
  late final List<StepCard> _tray;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _okBag = LineBag(GoldenLines.ok);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final List<String> _caught = [];

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  int _shakes = 0;
  String? _shook;

  /// 0 = ordering, 1 = between, 2 = crowd.
  int _stage = 0;
  int _crowdIndex = 0;
  int _crowdSlips = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  String get _rungId => widget.ctx.rungId;
  int get _slips => _order.slips + _crowdSlips;
  int get _percent => (100 - 15 * _slips).clamp(0, 100);
  bool get _passedRun => _percent >= 55;

  @override
  void initState() {
    super.initState();
    _crowd = dealCrowd(widget.rng);
    _tray = [...goldenCards]..shuffle(widget.rng);
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

  void _tap(StepCard c, Offset origin) {
    if (_ended || _card != null || _stage != 0) return;
    final t = _order.tap(c.id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        return;
      case OrderTapKind.mistake:
        setState(() {
          _shakes++;
          _shook = c.id;
        });
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(t.mistake!));
      case OrderTapKind.ok:
        HapticFeedback.lightImpact();
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.5, muted: false));
        unawaited(_levelDelta(t.roundDone ? 15 : 5, origin, mood: GuideMood.glad));
        if (t.allDone) {
          if (_order.slips == 0) _caught.add(GoldenLines.caughtOrder);
          setState(() => _stage = 1);
          unawaited(_sayChain([GoldenLines.ordered], mood: GuideMood.glad));
          return;
        }
        setState(() {});
        unawaited(_sayChain([_okBag.next().shownBn], mood: GuideMood.glad));
    }
  }

  void _toCrowd() {
    if (_stage != 1) return;
    setState(() => _stage = 2);
    _askMyth();
  }

  void _askMyth() {
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/customer.wav', volume: 0.5, muted: false));
    _hush();
    unawaited(_say(GoldenLines.myth(_crowd[_crowdIndex]), other: true));
  }

  Future<void> _answer(bool held, Offset origin) async {
    if (_ended || _card != null || _stage != 2 || _advancePending) return;
    final m = _crowd[_crowdIndex];
    _hush();
    if (held) {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
      unawaited(_sayChain([GoldenLines.right(m)], mood: GuideMood.glad));
      _advance();
      return;
    }
    _crowdSlips++;
    _advancePending = true;
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(GoldenMistakes.myth(m));
  }

  /// Next bystander, or the result after the last one.
  void _advance() {
    if (_crowdIndex >= _crowd.length - 1) {
      if (_crowdSlips == 0) _caught.add(GoldenLines.caughtCrowd);
      unawaited(_finish());
      return;
    }
    setState(() => _crowdIndex++);
    _askMyth();
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
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() => _card = m);
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('golden/${m.key}');
    if (!mounted || _card != m) return;
    unawaited(_sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn));
  }

  /// Closing a crowd mistake moves on to the next bystander.
  void _cardGo() {
    _hush();
    setState(() => _card = null);
    if (_advancePending) {
      _advancePending = false;
      _advance();
    }
  }

  var _advancePending = false;

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
    if (_passedRun) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_passedRun ? GoldenLines.fail : (_quickBonus ? GoldenLines.quick : GoldenLines.allSet),
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
    final placed = [for (final c in goldenCards) if (_order.isDone(c.id) || _order.done) c.id];
    final tray = [for (final c in _tray) if (!placed.contains(c.id)) c];
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
                      labels: GoldenLines.rounds,
                      done: {if (_stage >= 1) 0, if (_mark != null) 1},
                      current: _mark != null ? null : (_stage == 2 ? 1 : (_stage == 0 ? 0 : null)),
                      quiet: quiet,
                    ),
                    Expanded(
                      child: _stage == 2
                          ? Center(
                              child: _CrowdCard(
                                key: ValueKey('myth-$_crowdIndex'),
                                myth: _crowd[_crowdIndex],
                                quiet: quiet,
                                enabled: _card == null && _mark == null,
                                onAnswer: (held, o) => unawaited(_answer(held, o)),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                              children: [
                                for (var i = 0; i < goldenCards.length; i++)
                                  StepSlot(
                                    index: i,
                                    card: placed.contains(goldenCards[i].id) ? goldenCards[i] : null,
                                    note: null,
                                    quiet: quiet,
                                  ),
                                const SizedBox(height: 10),
                                if (_stage == 0)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final c in tray)
                                        StepTrayCard(
                                          key: ValueKey('tray-${c.id}-${_shook == c.id ? _shakes : 0}'),
                                          card: c,
                                          shake: _shook == c.id,
                                          quiet: quiet,
                                          onTap: (o) => _tap(c, o),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                    ),
                    if (_stage == 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: DoBigButton(label: GoldenLines.next, filled: true, onTapUp: (_) => _toCrowd()),
                        ),
                      ),
                    Opacity(opacity: _card == null ? 1 : 0, child: DoCoachStrip(tasks: GoldenLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$_shakes-$_crowdIndex'),
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                LevelIntro(
                  lines: [GoldenLines.intro, GoldenLines.askOrder],
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

/// One bystander's advice with "ঠিক…" / "না…".
class _CrowdCard extends StatelessWidget {
  const _CrowdCard({super.key, required this.myth, required this.quiet, required this.enabled, required this.onAnswer});
  final CrowdMyth myth;
  final bool quiet;
  final bool enabled;
  final void Function(bool held, Offset origin) onAnswer;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.88 + 0.12 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, color: SlmColors.warning, size: 38),
            const SizedBox(height: 6),
            Text(GoldenLines.crowdWho, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
            const SizedBox(height: 8),
            Text(
              '“${GoldenLines.myth(myth)}”',
              textAlign: TextAlign.center,
              style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.4),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: !enabled,
              child: Row(
                children: [
                  Expanded(child: DoBigButton(label: GoldenLines.giveIn(myth), filled: false, onTapUp: (d) => onAnswer(false, d.globalPosition))),
                  const SizedBox(width: 10),
                  Expanded(child: DoBigButton(label: GoldenLines.holdOut(myth), filled: true, onTapUp: (d) => onAnswer(true, d.globalPosition))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
