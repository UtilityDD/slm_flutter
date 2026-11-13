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
import 'choice_deck.dart';
import 'coworker_moment.dart';
import 'distance_spot.dart' show ArcJumpPainter, StreetBackdrop, StreetGeo, distanceFor, paintWireAndRuler;
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'rod_pick.dart' show RodRating, RodRatingText;
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Lesson 1.2, কাজ 2: "লম্বা টুলের ডগা". A kite is caught in a tree near a live
// line. First pick the tool: only the tested fibreglass hot stick (dry
// bamboo and the PVC pipe with a metal hook are not insulators you can
// trust). Then, hands on: drag the stick's tip — only its distance from the
// wire shows — and bring the kite down, or call "শাটডাউন চাই". If the kite is
// inside the লক্ষ্মণ রেখা the tip would be inside too, so the only right answer
// is the shutdown. Once, the careless coworker (level 1's rival, his recorded
// voice) peeps in: "শুকনো বাঁশ তো, চলবে!".
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" (the tool once, every
// decision) → next kite by itself.
//
// Deadly (owner-approved list, MODULE1_LADDER.md step 6): bamboo / PVC near a
// live line (also by listening to him — the act he pushes is on that list);
// the tool tip resting inside the distance. Slip: asking for a shutdown that
// was not needed (−10 ◆, the kite is still to do).
//
// He can't be skipped: on his round, picking a tool waits for him
// (holdForCoworker), and the tray is away while he is on — he is answered only
// on his deck (listening = taking the bamboo he pushes); a guide tap stays
// quiet while he talks (beat 1). Nothing reacts in the praise window (tableBusy). Gesture
// hints (how, never what): a sweep over the three tools; on the kite, a sweep
// over both ways (the stick's tip and শাটডাউন চাই) taking turns with a short
// sideways nudge of the tip (away from the kite). Taps on nothing count.
//
// Voice: device TTS only. The street art is shared with কাজ 1; tools, tree
// and kite are drawn in code to scale.

// ============================================================================
// Content
// ============================================================================

enum LongTool { hotStick, bamboo, pvc }

@immutable
class KiteRound {
  const KiteRound({required this.line, required this.gapM, required this.tools});
  final RodRating line;

  /// How far below the wire the kite hangs, in metres.
  final double gapM;

  /// Tray order for this round.
  final List<LongTool> tools;
  double get distanceM => distanceFor(line);
  bool get inside => gapM < distanceM;
}

@immutable
class KiteDeal {
  const KiteDeal({required this.rounds, required this.callRound});
  final List<KiteRound> rounds;

  /// The round whose tool choice the helper interrupts.
  final int callRound;
}

abstract final class ToolTipLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askTool, askReach];

  /// The hands-on reach: only the tip's distance from the wire shows.
  static const stickLabel = 'হট স্টিক';
  static String tipReadout(double m) => 'ডগা: ${m.toStringAsFixed(1)} মি · ${(m * 3.281).round()} ফুট';

  // The reasons (lesson 1.2): one right, two wrong, all about the same length.
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const toolAsk = 'কেন হট স্টিক নিলেন?';
  static const toolRight = [
    'ফাইবারগ্লাস হট স্টিকই বিদ্যুৎ আটকায়',
    'শুকনো বাঁশেও ভেতরের আর্দ্রতা বিদ্যুৎ টানে',
    'পিভিসি জুগাড় ফাটে, ভিজে গিয়ে লিক করে',
  ];
  static const toolWrong = [
    'বাঁশ শুকনো হলে লাইনের কাছে কোনো ভয় নেই',
    'পিভিসি পাইপ তো সব সময় বিদ্যুৎ আটকায়',
    'যে টুল যত লম্বা, সেটা তত বেশি নিরাপদ',
    'হট স্টিক ভারী, তাই বাঁশেই কাজ সহজ',
    'হাতে গ্লাভস থাকলে যে কোনো টুলই চলে',
    'ফাইবারগ্লাস হোক বা বাঁশ, শুকনো হলেই চলে',
    'জুগাড় পাইপ নতুন হলে ফাটার ভয় নেই',
    'রোদে শুকানো বাঁশে আর্দ্রতা থাকে না',
  ];
  static const reachAsk = 'কেন ডগা দিয়ে নামালেন?';
  static const reachRight = [
    'ঘুড়ি রেখার বাইরে, তাই ডগাও বাইরে থাকে',
    'ডগা লক্ষ্মণ রেখার বাইরে থাকলে নিরাপদ',
  ];
  static const shutAsk = 'কেন শাটডাউন চাইলেন?';
  static const shutRight = [
    'ঘুড়ি রেখার ভেতরে, ডগাও ভেতরে ঢুকত',
    'রেখার ভেতরে কাজ মানেই লাইন বন্ধ চাই',
  ];
  static const decideWrong = [
    'টুল লম্বা হলে রেখা মানার দরকার নেই',
    'ডগা একটু ভেতরে গেলে কিছুই হয় না',
    'তাড়াতাড়ি সারলে দূরত্ব না মানলেও চলে',
    'ঘুড়ি তো কাগজের, তাতে কারেন্ট আসে না',
    'লাইন বন্ধ চাইলে লোকে রাগ করবে, তাই',
    'হাত রেখার বাইরে, ডগা নিয়ে ভাবনা নেই',
    'লক্ষ্মণ রেখা শরীরের, টুলের ডগার নয়',
    'শুকনো হট স্টিক হলে ভেতরেও নিরাপদ',
  ];

  /// The careless coworker (his recorded voice) pushes the dry bamboo.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: helperLine,
    exitLine: coworkerExit,
    right: [
      'হট স্টিক এনেই তবে কাজটা করব',
      'বাঁশ নয়, পরীক্ষিত হট স্টিক আনি',
      'গাড়ি দূরে হোক, হট স্টিকই আনব',
    ],
    wrong: [
      'ঠিক, শুকনো বাঁশই নিয়ে নিই',
      'বাঁশ তো শুকনো, এতেই চলবে',
      'একবার বাঁশ দিয়ে চেষ্টা করি',
      'সবাই তো বাঁশ দিয়েই নামায়',
      'হট স্টিক থাক, বাঁশেই সারি',
      'হট স্টিক আনতে দেরি, বাঁশই নিই',
      'গাড়ি তো দূরে, বাঁশই নিয়ে নিই',
      'পরীক্ষিত না হোক, বাঁশেই চলবে',
    ],
    asks: [
      'ও বলছে বাঁশেই চলবে। আপনি কী করবেন?',
      'বাঁশ নেবেন, না হট স্টিক আনবেন?',
      'কার কথা শুনবেন — ওর, না নিয়মের?',
    ],
  );


  static const title = 'লম্বা টুলের ডগা';
  static const intro = 'লাইভ লাইনের পাশে গাছে ঘুড়ি আটকেছে। হাতে লম্বা টুল নিলে তার ডগাও আপনার হাত।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const askTool = 'কোন টুল নেবেন?';
  static const askReach = 'ডগা টেনে ঘুড়ি নামাবেন, না শাটডাউন চাইবেন?';
  static const shutdown = 'শাটডাউন চাই';
  static String scene(KiteRound r) => '${r.line.lineBn} লাইন · গাছে আটকানো ঘুড়ি';
  static String band(KiteRound r) => switch (r.line) {
        RodRating.lt => 'এলটি: কমপক্ষে 1.2 মিটার (প্রায় 4 ফুট)',
        RodRating.kv11 => '11 কেভি: কমপক্ষে 2.5 মিটার (প্রায় 8 ফুট)',
        RodRating.kv33 => '33 কেভি: কমপক্ষে 3.0 মিটার (প্রায় 10 ফুট)',
      };
  static const helperLine = 'শুকনো বাঁশ তো, চলবে! হট স্টিক আনতে গাড়ি পর্যন্ত কে যাবে?';
  static const callHeld = 'ঠিক! শুকনো বাঁশও বিদ্যুৎ টানে।';
  static const toolOk = [FeedbackLine('ফাইবারগ্লাস — ঠিক টুল।'), FeedbackLine('পরীক্ষিত হট স্টিক!'), FeedbackLine('এটাই।')];
  static const reachOk = 'ডগা রেখার বাইরে — ঘুড়ি নামল।';
  static const shutOk = 'ঠিক! রেখার ভেতরে কাজ মানেই লাইন বন্ধ চাই।';
  static const allSet = 'টুল আর ডগা — দুটোই রেখার নিয়মে!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ডগাও আপনার হাত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtTool = 'বাঁশ / পিভিসি নয়, হট স্টিক';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const caughtShut = 'রেখার ভেতরে কাজে শাটডাউন';
  static const caughtReach = 'ডগা রেখার বাইরে রেখেছেন';
}

abstract final class ToolTipMistakes {
  static const bamboo = DoMistake(
    key: '1.2/tool/bamboo',
    textBn: 'শুকনো বাঁশ বা কাঠেও ভেতরের আর্দ্রতা আর বাইরের ময়লা বিদ্যুৎ টানে। লাইভ লাইনের কাছে শুধু পরীক্ষিত ফাইবারগ্লাস হট স্টিক।',
    art: 'assets/game/art/distance/bamboo_vs_hot_stick.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const pvc = DoMistake(
    key: '1.2/tool/pvc-jugaad',
    textBn: 'পিভিসি পাইপে মেটাল হুক — জুগাড়, হট স্টিক নয়। ফাটে, ভিজে লিক করে; প্লাস্টিক দেখে নিরাপদ ভাববেন না।',
    art: 'assets/game/art/rod/jugaad_vs_standard.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const tipInside = DoMistake(
    key: '1.2/tool/tip-inside',
    textBn: 'ঘুড়িটা লক্ষ্মণ রেখার ভেতরে — সরাতে গেলে টুলের ডগাও ভেতরে। এমন কাজে শাটডাউন চাই।',
    art: 'assets/game/art/distance/tool_tip.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const needlessShutdown = DoMistake(
    key: '1.2/tool/needless-shutdown',
    textBn: 'ঘুড়িটা রেখার বাইরেই ছিল — ডগাও বাইরে থাকত। কোন লাইনে কত দূর, পাঠে দেখে নিন।',
    art: 'assets/game/art/distance/man_ruler.svg',
    lessonPoint: 1,
  );
  static const all = [bamboo, pvc, tipInside, needlessShutdown];
}

/// Three kites: each voltage once, at least one inside and one outside.
KiteDeal dealKites(math.Random rng) {
  final lines = [...RodRating.values]..shuffle(rng);
  final insides = <bool>[true, false, rng.nextBool()]..shuffle(rng);
  double u(double a, double b) => a + rng.nextDouble() * (b - a);
  return KiteDeal(
    rounds: [
      for (var i = 0; i < 3; i++)
        KiteRound(
          line: lines[i],
          gapM: insides[i]
              ? distanceFor(lines[i]) * u(0.35, 0.72)
              : math.min(distanceFor(lines[i]) + u(0.8, 1.5), StreetGeo.lineM - 3.2),
          tools: [...LongTool.values]..shuffle(rng),
        ),
    ],
    callRound: rng.nextInt(3),
  );
}

enum KitePhase { tool, decide, shown }

/// The play state (pure logic).
class KiteRun {
  KiteRun(this.deal);
  final KiteDeal deal;
  int round = 0;
  KitePhase phase = KitePhase.tool;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The last decision: true = reached, false = asked for a shutdown.
  bool? reached;

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  KiteRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Picks a tool; null = right, else the deadly mistake.
  DoMistake? pickTool(LongTool t) {
    if (ended || phase != KitePhase.tool) return null;
    switch (t) {
      case LongTool.hotStick:
        phase = KitePhase.decide;
        if (!caught.contains(ToolTipLines.caughtTool)) caught.add(ToolTipLines.caughtTool);
        return null;
      case LongTool.bamboo:
        return deadly = ToolTipMistakes.bamboo;
      case LongTool.pvc:
        return deadly = ToolTipMistakes.pvc;
    }
  }

  /// The tip comes to rest [tipGapM] below the wire: inside the distance is
  /// deadly (null = safe there).
  DoMistake? restTip(double tipGapM) {
    if (ended || phase != KitePhase.decide) return null;
    if (tipGapM < current.distanceM) return deadly = ToolTipMistakes.tipInside;
    return null;
  }

  /// Reach (true) or ask for a shutdown (false). Returns the mistake, if any.
  /// A needless shutdown is a slip and the kite is still to do.
  DoMistake? decide({required bool reach}) {
    if (ended || phase != KitePhase.decide) return null;
    final r = current;
    if (reach && r.inside) {
      reached = reach;
      phase = KitePhase.shown;
      return deadly = ToolTipMistakes.tipInside;
    }
    if (!reach && !r.inside) {
      slips++;
      return ToolTipMistakes.needlessShutdown;
    }
    reached = reach;
    phase = KitePhase.shown;
    final tag = reach ? ToolTipLines.caughtReach : ToolTipLines.caughtShut;
    if (!caught.contains(tag)) caught.add(tag);
    return null;
  }

  void next() {
    round++;
    phase = KitePhase.tool;
    reached = null;
  }
}

@immutable
class ToolTipPack {
  const ToolTipPack({required this.id, required this.titleBn, this.quickMs = 55000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const toolTipPack12 = ToolTipPack(id: 'do_1_2_b', titleBn: ToolTipLines.title);
const toolTipPacks = {'do_1_2_b': toolTipPack12};

// ============================================================================
// Page
// ============================================================================

class ToolTipPage extends StatefulWidget {
  const ToolTipPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final ToolTipPack pack;
  final bool muted;
  final int? seed;

  @override
  State<ToolTipPage> createState() => _ToolTipPageState();
}

class _ToolTipPageState extends State<ToolTipPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ToolTipRun(
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

class _ToolTipRun extends ConsumerStatefulWidget {
  const _ToolTipRun({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final ToolTipPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ToolTipRun> createState() => _ToolTipRunState();
}

class _ToolTipRunState extends ConsumerState<_ToolTipRun> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final KiteRun _run = KiteRun(dealKites(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _toolBag = LineBag(ToolTipLines.toolOk);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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
  var _freeze = false;
  Completer<void>? _frozen;
  int? _mark;
  int _totalDelta = 0;

  /// Gesture hints (how to touch, never what): the tools, the stick's tip and
  /// the shutdown button are their anchors; taps on nothing count.
  final _hints = IdleHintController();
  final _toolKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final _tipKey = GlobalKey();
  final _shutKey = GlobalKey();
  int _hintN = 0;

  /// The stick's tip under the finger (design px), while dragging.
  Offset? _tip;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

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

  String get _task => _run.phase == KitePhase.decide ? ToolTipLines.askReach : ToolTipLines.askTool;

  /// After the guide's intro: the clock runs and he gives the first task.
  Future<void> _start() async {
    _clock.start();
    scheduleCoworker();
    await _sayChain([ToolTipLines.askTool]);
  }

  /// The scene takes no input: never in the praise window ([tableBusy]: the ◆
  /// on the table, the reason deck), a card, a freeze or the end.
  bool get _blocked => _intro || _busy || _ended || _freeze || _card != null || tableBusy;

  void _pickTool(LongTool t, Offset origin) {
    // While he is on (both beats) the tray is away: he is answered on his deck,
    // never by a second fast tap.
    if (_blocked || coworkerOpen || _run.phase != KitePhase.tool) return;
    // His round: the pick waits for him (a fast tap never slips past him).
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    final m = _run.pickTool(t);
    if (m != null) {
      unawaited(_deadly(m));
      return;
    }
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: false));
    if (_run.round == 0) {
      // The first time: "কেন হট স্টিক?" — the ◆ wait on the table.
      putOnTable(10);
      unawaited(askReason(
        deal: () => dealChoices(ToolTipLines.toolRight, ToolTipLines.toolWrong, widget.rng),
        question: ToolTipLines.toolAsk,
      ));
      return;
    }
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    setState(() {});
    unawaited(_sayChain([_toolBag.next().shownBn, ToolTipLines.askReach], mood: GuideMood.glad));
  }

  // --- the hands-on reach: drag the tip ---------------------------------------
  bool get _canReach => !_blocked && _run.phase == KitePhase.decide;

  // --- gesture hint (how to touch, never what) --------------------------------
  /// The level waits for a touch on the scene (the tray or the kite); decks
  /// show their own sweep, cards and the coworker's beats show none.
  bool get _hintWaiting =>
      !_blocked && !coworkerOnScreen && _mark == null && !struckOut && _tip == null && _run.phase != KitePhase.shown;

  Object get _hintKey => ('tool-tip', _run.round, _run.phase, _run.slips);

  HintSpec? _hint() {
    if (_run.phase == KitePhase.tool) return HintSpec.sweepOver(_toolKeys);
    // Two ways forward (reach or call): a sweep over both, taking turns with
    // a short sideways nudge of the tip that points away from the kite.
    return (_hintN++).isEven
        ? HintSpec.sweepOver([_tipKey, _shutKey])
        : HintSpec.dragFrom(_tipKey, toward: const Offset(-1, 0), travel: 48);
  }

  /// A tap that hit nothing to work with (a hint after a few).
  void _missTap() {
    if (_hintWaiting) _hints.missTap();
  }

  void _dragTip(Offset p) {
    if (!_canReach) return;
    final tip = Offset(p.dx.clamp(60.0, 350.0), p.dy.clamp(StreetGeo.lineY + 4, StreetGeo.groundY - 60));
    if (_tip == null) HapticFeedback.selectionClick();
    setState(() => _tip = tip);
  }

  /// The finger lets go: the tip rests where it is. Inside the distance is
  /// deadly; on the kite (outside) the kite comes down; elsewhere the stick
  /// goes back.
  Future<void> _releaseTip(Offset origin) async {
    final tip = _tip;
    if (tip == null || !_canReach) {
      if (_tip != null) setState(() => _tip = null);
      return;
    }
    final gap = (tip.dy - StreetGeo.lineY) / StreetGeo.ppm;
    final m = _run.restTip(gap);
    if (m != null) {
      await _deadly(m);
      return;
    }
    if ((tip - _KiteScene.kiteAt(_run.current)).distance <= 30) {
      setState(() => _tip = null);
      await _decide(true, origin);
      return;
    }
    setState(() => _tip = null);
  }

  Future<void> _decide(bool reach, Offset origin) async {
    if (!_canReach) return;
    _hush();
    final m = _run.decide(reach: reach);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.5, muted: false));
    setState(() {});
    if (m == null) {
      // Right: the ◆ wait on the table, then "কেন …?".
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      putOnTable(15);
      final round = _run.round;
      unawaited(askReason(
        deal: () => dealChoices(reach ? ToolTipLines.reachRight : ToolTipLines.shutRight, ToolTipLines.decideWrong, widget.rng),
        question: reach ? ToolTipLines.reachAsk : ToolTipLines.shutAsk,
        stillValid: () => _run.round == round && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    _busy = true;
    await Future<void>.delayed(MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 700));
    _busy = false;
    if (!mounted) return;
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  /// Next kite (or the result) — by itself, after the reason.
  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() => _tip = null);
    scheduleCoworker();
    unawaited(_sayChain([ToolTipLines.askTool]));
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
    if (_run.phase == KitePhase.decide) {
      // The tool's reason: now the kite.
      setState(() {});
      unawaited(_sayChain([ToolTipLines.askReach]));
    } else {
      _next();
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => ToolTipLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.round != _run.deal.callRound || _run.phase != KitePhase.tool) return null;
    if (_blocked) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Took the dry bamboo near a live line.
      _run.deadly = ToolTipMistakes.bamboo;
      await _deadly(ToolTipMistakes.bamboo);
      return;
    }
    _run.caught.add(ToolTipLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([ToolTipLines.callHeld, ToolTipLines.askTool], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    // Beat 1 is his alone: the guide never talks over the coworker's push.
    if (coworkerOpen && !coworkerChoiceUp) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? ToolTipLines.tapWhy[_nudgeN++ % ToolTipLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

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
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('tooltip/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the street freezes grey, then the card.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('tooltip/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? ToolTipLines.deadlyWord : ToolTipLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        unawaited(_sayChain([ToolTipLines.askReach]));
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
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? ToolTipLines.fail : (_quickBonus ? ToolTipLines.quick : ToolTipLines.allSet),
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
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final r = _run.current;
    final phase = _run.phase;
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final trayUp = playing && phase == KitePhase.tool && !reasonOpen && !coworkerOpen;
    final callUp = playing && phase == KitePhase.decide && _card == null && !tableBusy && _tip == null;
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
              labels: ToolTipLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            hint: _hint,
            hintWaiting: playing && _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            hintAutoMiss: true,
            layers: (context, m) {
              final top = StreetGeo.topIn(m.height);
              return [
                Positioned.fill(
                  key: const ValueKey('sky'),
                  child: ColorFiltered(
                    colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                    child: StreetBackdrop(streetTop: top),
                  ),
                ),
                Positioned(
                  key: const ValueKey('street'),
                  left: 0,
                  top: top,
                  width: StreetGeo.size.width,
                  height: StreetGeo.size.height,
                  child: ColorFiltered(
                    colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                    child: _KiteScene(
                      key: ValueKey('kite-${_run.round}'),
                      round: r,
                      holding: phase != KitePhase.tool,
                      reached: _run.reached,
                      reveal: phase == KitePhase.shown || (_card != null && _cardTone == MistakeTone.slip),
                      tip: _tip,
                      tipKey: _tipKey,
                      quiet: quiet,
                      onMiss: _missTap,
                      onDrag: _dragTip,
                      onRelease: () => unawaited(_releaseTip(Offset(size.width / 2, size.height / 2))),
                    ),
                  ),
                ),
                // The tip rested inside: the arc jumps to it.
                if (_freeze && _tip != null)
                  Positioned(
                    key: const ValueKey('arc'),
                    left: 0,
                    top: top,
                    width: StreetGeo.size.width,
                    height: StreetGeo.size.height,
                    child: IgnorePointer(child: CustomPaint(painter: ArcJumpPainter(_tip!))),
                  ),
              ];
            },
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (trayUp)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 12,
                  height: 92,
                  child: _ToolTray(key: ValueKey('tray-${_run.round}'), tools: r.tools, cardKeys: _toolKeys, quiet: quiet, onPick: _pickTool),
                ),
              if (callUp)
                Positioned(
                  key: const ValueKey('hud-call'),
                  left: 16,
                  right: 136,
                  bottom: pad.bottom + 22,
                  child: KeyedSubtree(
                    key: _shutKey,
                    child: DoBigButton(label: ToolTipLines.shutdown, filled: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition))),
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (trayUp ? 112 : 8)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}'),
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
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2200,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  line: ToolTipLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
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

/// The three long tools as picture cards (no names: look at them).
class _ToolTray extends StatelessWidget {
  const _ToolTray({super.key, required this.tools, required this.cardKeys, required this.quiet, required this.onPick});
  final List<LongTool> tools;

  /// One per card, in screen order (the gesture hint's sweep anchors).
  final List<GlobalKey> cardKeys;
  final bool quiet;
  final void Function(LongTool t, Offset origin) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < tools.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: DoDealIn(
                  index: i,
                  quiet: quiet,
                  muted: true,
                  child: Semantics(
                    button: true,
                    label: 'টুল',
                    child: GestureDetector(
                      key: cardKeys[i],
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => onPick(tools[i], d.globalPosition),
                      child: Container(
                        decoration: BoxDecoration(
                          color: SlmColors.ivory,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: CustomPaint(painter: _ToolPainter(tools[i]), size: Size.infinite),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A long tool lying diagonally on its card.
class _ToolPainter extends CustomPainter {
  _ToolPainter(this.tool);
  final LongTool tool;

  @override
  void paint(Canvas c, Size s) {
    final a = Offset(s.width * 0.1, s.height * 0.88);
    final b = Offset(s.width * 0.9, s.height * 0.14);
    Offset at(double t) => Offset.lerp(a, b, t)!;
    final t = math.max(5.0, s.height * 0.1);
    switch (tool) {
      case LongTool.hotStick:
        c.drawLine(a, b, Paint()..color = const Color(0xFFE9B949)..strokeWidth = t..strokeCap = StrokeCap.round);
        c.drawLine(a, at(0.18), Paint()..color = const Color(0xFF3B3F45)..strokeWidth = t * 1.25..strokeCap = StrokeCap.round);
        c.drawLine(at(0.3), at(0.34), Paint()..color = const Color(0xFFC0392B)..strokeWidth = t * 1.2);
        for (final u in const [0.5, 0.72]) {
          c.drawLine(at(u), at(u + 0.015), Paint()..color = const Color(0xFFB88A2A)..strokeWidth = t * 1.1);
        }
        // Test label.
        final mid = at(0.6);
        c.save();
        c.translate(mid.dx, mid.dy);
        c.rotate(math.atan2(b.dy - a.dy, b.dx - a.dx));
        c.drawRect(Rect.fromCenter(center: Offset.zero, width: t * 2.4, height: t * 0.9), Paint()..color = Colors.white);
        c.drawRect(
          Rect.fromCenter(center: Offset.zero, width: t * 2.4, height: t * 0.9),
          Paint()
            ..color = const Color(0xFF2E8B45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        c.restore();
        // Fitting at the head.
        c.drawCircle(b, t * 0.55, Paint()..color = const Color(0xFF9AA3AB));
      case LongTool.bamboo:
        c.drawLine(a, b, Paint()..color = const Color(0xFFC2A766)..strokeWidth = t * 1.1..strokeCap = StrokeCap.round);
        for (var u = 0.12; u < 0.95; u += 0.17) {
          final p = at(u);
          c.drawCircle(p, t * 0.62, Paint()..color = const Color(0xFF8A7536));
        }
        c.drawLine(at(0.4), at(0.4).translate(t, -t * 0.3), Paint()..color = const Color(0xFF7C8B3A)..strokeWidth = 2);
      case LongTool.pvc:
        // White pipe with a thin grey outline.
        c.drawLine(a, b, Paint()..color = const Color(0xFFA9A9A2)..strokeWidth = t + 2..strokeCap = StrokeCap.round);
        c.drawLine(a, b, Paint()..color = const Color(0xFFFAFAF6)..strokeWidth = t..strokeCap = StrokeCap.round);
        for (final u in const [0.35, 0.62]) {
          c.drawLine(at(u), at(u + 0.05), Paint()..color = const Color(0xFF222222)..strokeWidth = t * 1.15);
        }
        // Metal hook at the head.
        final hook = Path()
          ..moveTo(b.dx, b.dy)
          ..lineTo(b.dx + t * 0.6, b.dy - t * 0.8)
          ..quadraticBezierTo(b.dx + t * 1.6, b.dy - t * 1.4, b.dx + t * 1.4, b.dy - t * 0.2);
        c.drawPath(
          hook,
          Paint()
            ..color = const Color(0xFF7A7F85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = t * 0.45
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(_ToolPainter old) => old.tool != tool;
}

/// The street with a tree and a kite caught near the wire; the lineman with
/// the hot stick (drag its tip — only the tip's distance from the wire
/// shows); after the decision, or a wrong one, the real band shows.
class _KiteScene extends StatelessWidget {
  const _KiteScene({
    super.key,
    required this.round,
    required this.holding,
    required this.reached,
    required this.reveal,
    required this.tip,
    required this.tipKey,
    required this.quiet,
    required this.onMiss,
    required this.onDrag,
    required this.onRelease,
  });
  final KiteRound round;
  final bool holding;
  final bool? reached;
  final bool reveal;
  final Offset? tip;

  /// Marks the ready stick's tip (the gesture hint's anchor; draws nothing).
  final GlobalKey tipKey;
  final bool quiet;

  /// A tap on the street that moved nothing.
  final VoidCallback onMiss;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onRelease;

  /// Where the kite hangs (design px).
  static Offset kiteAt(KiteRound r) => Offset(250, StreetGeo.y(r.gapM));

  @override
  Widget build(BuildContext context) {
    final d = round.distanceM * StreetGeo.ppm;
    final kite = kiteAt(round);
    final t = tip;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/distance/street_side.svg', fit: BoxFit.fill)),
        Positioned(
          left: 0,
          right: 0,
          top: StreetGeo.lineY - d,
          height: 2 * d,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: reveal ? 1 : 0,
              duration: quiet ? Duration.zero : const Duration(milliseconds: 500),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x33C0392B),
                  border: Border.symmetric(horizontal: BorderSide(color: SlmColors.danger.withValues(alpha: 0.9), width: 2)),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: reached == true ? 1.0 : 0.0),
              duration: quiet ? Duration.zero : const Duration(milliseconds: 650),
              curve: Curves.easeInCubic,
              builder: (_, f, _) => CustomPaint(
                painter: _KitePainter(round: round, kite: kite, holding: holding, tip: t ?? (reached == true ? kite : null), fall: f),
              ),
            ),
          ),
        ),
        // The line's plate at eye level on the pole.
        Positioned(left: 8, top: 330, child: _Plate(text: round.line.tag)),
        // Layers that come and go are keyed, so the drag surface keeps its
        // gesture while the readout appears.
        if (t != null)
          Positioned(
            key: const ValueKey('tip-readout'),
            left: math.min(t.dx + 12, StreetGeo.size.width - 112),
            top: t.dy - 34,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2B632),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  ToolTipLines.tipReadout((t.dy - StreetGeo.lineY) / StreetGeo.ppm),
                  style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1E2228)),
                ),
              ),
            ),
          ),
        if (reveal)
          Positioned(
            key: const ValueKey('band-label'),
            left: 60,
            right: 8,
            top: math.max(4, StreetGeo.lineY - d + 4),
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
                  child: Text(ToolTipLines.band(round), style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ),
          ),
        if (reveal && reached == false)
          Positioned(
            key: const ValueKey('shut-chip'),
            left: 96,
            top: 300,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: SlmColors.navy800, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_in_talk_rounded, size: 14, color: SlmColors.gold300),
                  const SizedBox(width: 4),
                  Text(ToolTipLines.shutdown, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ],
              ),
            ),
          ),
        // The ready tip's spot (an invisible anchor for the gesture hint).
        if (holding && reached == null && t == null)
          Positioned(
            key: const ValueKey('tip-anchor'),
            left: _KitePainter.readyTip.dx - 22,
            top: _KitePainter.readyTip.dy - 22,
            width: 44,
            height: 44,
            child: IgnorePointer(child: SizedBox.expand(key: tipKey)),
          ),
        // Drag on the street: the tip follows the finger.
        if (holding && reached == null)
          Positioned.fill(
            key: const ValueKey('drag'),
            child: Semantics(
              label: ToolTipLines.stickLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMiss,
                onPanStart: (e) => onDrag(e.localPosition),
                onPanUpdate: (e) => onDrag(e.localPosition),
                onPanEnd: (_) => onRelease(),
                onPanCancel: onRelease,
              ),
            ),
          ),
      ],
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFFFF6D6), border: Border.all(color: const Color(0xFFC0392B), width: 1.2)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E2228))),
      );
}

class _KitePainter extends CustomPainter {
  _KitePainter({required this.round, required this.kite, required this.holding, required this.tip, required this.fall});
  final KiteRound round;
  final Offset kite;
  final bool holding;

  /// Where the stick's tip is (null = held ready).
  final Offset? tip;

  /// 0..1: the kite falling after a safe reach.
  final double fall;

  /// The lineman's hand, and the hot stick's tip held ready (design px).
  static const hand = Offset(160, StreetGeo.groundY - 50);
  static final readyTip = hand + Offset.fromDirection(-1.1, 3.4 * StreetGeo.ppm);

  @override
  void paint(Canvas c, Size size) {
    paintWireAndRuler(c, size, withRuler: false);
    const g = StreetGeo.groundY;
    // The tree: trunk, crown, one branch reaching toward the wire.
    c.drawRect(const Rect.fromLTRB(296, 250, 312, g), Paint()..color = const Color(0xFF6E4724));
    c.drawCircle(const Offset(304, 250), 46, Paint()..color = const Color(0xFF4F7A3A));
    c.drawCircle(const Offset(280, 280), 30, Paint()..color = const Color(0xFF5E8A44));
    c.drawLine(const Offset(300, 230), kite.translate(8, 10), Paint()..color = const Color(0xFF6E4724)..strokeWidth = 5..strokeCap = StrokeCap.round);
    // The kite (falls to the ground after a safe reach).
    final k = Offset.lerp(kite, Offset(kite.dx, g - 14), fall)!;
    final kp = Path()
      ..moveTo(k.dx, k.dy - 14)
      ..lineTo(k.dx + 10, k.dy)
      ..lineTo(k.dx, k.dy + 14)
      ..lineTo(k.dx - 10, k.dy)
      ..close();
    c.drawPath(kp, Paint()..color = const Color(0xFFE2463A));
    c.drawLine(Offset(k.dx, k.dy - 14), Offset(k.dx, k.dy + 14), Paint()..color = const Color(0xFF7A1F18)..strokeWidth = 1.2);
    c.drawLine(Offset(k.dx - 10, k.dy), Offset(k.dx + 10, k.dy), Paint()..color = const Color(0xFF7A1F18)..strokeWidth = 1.2);
    c.drawLine(Offset(k.dx, k.dy + 14), Offset(k.dx - 6, k.dy + 34), Paint()..color = const Color(0xFFE2463A)..strokeWidth = 1);

    // The lineman on the footpath.
    const x = 150.0;
    const h = 1.7 * StreetGeo.ppm;
    final limb = Paint()
      ..color = const Color(0xFF3A2E24)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(x - 4, g - 28), const Offset(x - 6, g), limb);
    c.drawLine(const Offset(x + 4, g - 28), const Offset(x + 6, g), limb);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(x - 8, g - h + 15, 16, 30), const Radius.circular(5)), Paint()..color = const Color(0xFF2F5F9E));
    final head = const Offset(x, g - h + 7);
    c.drawCircle(head, 7, Paint()..color = const Color(0xFFF0C9A0));
    c.drawArc(Rect.fromCircle(center: head.translate(0, -2), radius: 8), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2B632));
    c.drawLine(const Offset(x + 6, g - h + 20), hand, limb..color = const Color(0xFFF0C9A0));
    if (!holding) return;
    // The hot stick: held ready (pointing up toward the tree), or reaching.
    final tip = this.tip ?? readyTip;
    c.drawLine(hand, tip, Paint()..color = const Color(0xFFE9B949)..strokeWidth = 5..strokeCap = StrokeCap.round);
    c.drawLine(hand, Offset.lerp(hand, tip, 0.14)!, Paint()..color = const Color(0xFF3B3F45)..strokeWidth = 6..strokeCap = StrokeCap.round);
    final g0 = Offset.lerp(hand, tip, 0.24)!;
    c.drawLine(g0, Offset.lerp(hand, tip, 0.27)!, Paint()..color = const Color(0xFFC0392B)..strokeWidth = 6);
    c.drawCircle(tip, 4, Paint()..color = const Color(0xFF9AA3AB));
  }

  @override
  bool shouldRepaint(_KitePainter old) => old.tip != tip || old.holding != holding || old.round != round || old.fall != fall;
}
