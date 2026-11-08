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
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'spoken_once.dart';

// Lesson 1.3: "পোলের ভাষা". One engine, two packs:
//   কাজ 1 "৩৬০° পোল পাঠ"   — PCC poles (crack, spalling + rebar, eroded base,
//                             lean, hollow sound, hardware).
//   কাজ 2 "স্টিলের ক্যান্সার" — steel poles (rust at ground level, rust at the
//                             weld joint, bent, hardware).
// Four poles a play. Walk around (some faults are on the back only), look
// close at base / waist / top, tap with the hammer (some faults are only
// heard), then decide: উঠব, or উঠব না — রিপোর্ট.
//
// Deadly (owner-approved list): climbing a condemned pole. Slips: climbing a
// sound pole without walking round, looking at the base and tapping it; and
// reporting a sound pole. Pressure: "চুলের মতো ফাটল তো থাকেই" (PCC) /
// "স্টিলের পোল শুধু বাঁকে, ভাঙে না" (steel).
//
// Voice: device TTS only. Art: assets/game/art/pole/ (hand-made SVG, no text
// inside); the pole and its faults are drawn in code; knock sounds are new.

// ============================================================================
// Content
// ============================================================================

enum PoleKind { pcc, steel }

enum PoleSide { front, back }

enum PoleZone { base, waist, top }

enum PoleDefect { hairline, spalling, erosion, lean, hollow, groundRust, weldRust, bent, insulator, crossArm }

extension PoleDefectFacts on PoleDefect {
  PoleZone get zone => switch (this) {
        PoleDefect.erosion || PoleDefect.lean || PoleDefect.groundRust => PoleZone.base,
        PoleDefect.insulator || PoleDefect.crossArm => PoleZone.top,
        _ => PoleZone.waist,
      };

  /// Seen from every side (no need to walk round).
  bool get allSides => this == PoleDefect.lean || this == PoleDefect.bent || this == PoleDefect.erosion || this == PoleDefect.crossArm;

  /// Only the hammer finds it.
  bool get heardOnly => this == PoleDefect.hollow;

  /// Makes the hammer sound wrong.
  bool get soundsBad => this == PoleDefect.hollow || this == PoleDefect.spalling || this == PoleDefect.groundRust || this == PoleDefect.weldRust;
}

@immutable
class PoleFlaw {
  const PoleFlaw(this.defect, this.side);
  final PoleDefect defect;
  final PoleSide side;
  bool seenFrom(PoleSide s) => !defect.heardOnly && (defect.allSides || side == s);
}

@immutable
class PoleCase {
  const PoleCase({required this.id, required this.kind, required this.flaws, this.rail = false});
  final String id;
  final PoleKind kind;
  final List<PoleFlaw> flaws;

  /// Steel: a rail / H-beam pole instead of a tube.
  final bool rail;
  bool get condemned => flaws.isNotEmpty;
  bool has(PoleDefect d) => flaws.any((f) => f.defect == d);
  bool get soundsBad => flaws.any((f) => f.defect.soundsBad);
}

abstract final class PoleLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const titlePcc = '৩৬০° পোল পাঠ';
  static const titleSteel = 'স্টিলের ক্যান্সার';
  static const introPcc = 'পোলে হাত দেওয়ার আগে পোলের ভাষা পড়ুন — চারপাশ ঘুরে, গোড়া-মাঝ-মাথায় ট্যাপ করে কাছ থেকে দেখে, ঠুকে শুনে।';
  static const introSteel = 'স্টিলের পোলে মরিচাই ক্যান্সার — বিশেষ করে মাটির কাছে আর জোড়ে। চারপাশ ঘুরে, ট্যাপ করে কাছ থেকে দেখে, ঠুকে তবে উঠুন।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];
  static const ask = 'পোলটা পড়ুন। উঠবেন?';
  static String scene(PoleCase c) => c.kind == PoleKind.pcc ? 'গ্রামের রাস্তা · পিসিসি পোল' : (c.rail ? 'গ্রামের রাস্তা · রেল পোল' : 'গ্রামের রাস্তা · স্টিলের টিউবুলার পোল');
  static const front = 'সামনে';
  static const back = 'পেছনে';
  static const walk = 'ঘুরে দেখুন';
  static const tap = 'ঠুকে দেখুন';
  static const climb = 'উঠব';
  static const report = 'উঠব না — রিপোর্ট';
  static const next = 'পরের পোল';
  static const finish = 'ফলাফল';
  static const checks = ['চারপাশ', 'গোড়া', 'শব্দ', 'ওপর'];
  static const zoneHint = 'পোলের গোড়া, মাঝ বা ওপরে ট্যাপ করে কাছ থেকে দেখুন';
  static const solid = 'ঠক্ ঠক্ — নিরেট';
  static const hollow = 'দপ্ দপ্ — ফাঁপা!';
  static const ring = 'টন টন — পরিষ্কার';
  static const dull = 'ভোঁতা শব্দ, মরিচা খসে!';
  static const sound = 'পোল ঠিক — উঠুন।';
  static const reported = 'ঠিক ধরেছেন — রিপোর্ট গেল, পোলে কেউ উঠবে না।';
  static const pressureWhoPcc = 'সাথী';
  static const pressurePcc = 'চুলের মতো ফাটল তো সব পোলেই থাকে, ওতে কিছু হয় না — উঠে পড়ো!';
  static const pressureWhoSteel = 'ঠিকাদারের লোক';
  static const pressureSteel = 'স্টিলের পোল শুধু বাঁকে, ভাঙে না — দেরি কোরো না, ওঠো!';
  static const giveIn = 'ঠিক, উঠি';
  static const holdOut = 'না, আগে দেখি';
  static const callHeld = 'ঠিক! কোনো পোলকেই না দেখে বিশ্বাস নয়।';
  static const right = [FeedbackLine('ঠিক পড়েছেন!'), FeedbackLine('পোলের ভাষা বুঝেছেন।'), FeedbackLine('নিখুঁত!')];
  static const allSet = 'পোলের ভাষা পড়তে শিখে গেছেন — গোড়া, শব্দ, তারপর ওঠা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চারপাশ, গোড়া, শব্দ, ওপর।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtBack = 'পেছনের ফাটলও ধরেছেন';
  static const caughtSound = 'শব্দ শুনে ধরেছেন';
  static const caughtReport = 'বিপজ্জনক পোলে রিপোর্ট';
  static const caughtHabit = 'দেখে-শুনে তবে উঠেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static String defectBn(PoleDefect d) => switch (d) {
        PoleDefect.hairline => 'চুলের মতো ফাটল',
        PoleDefect.spalling => 'কংক্রিট খসে রড বেরিয়ে',
        PoleDefect.erosion => 'গোড়ায় মাটি ক্ষয়, জল',
        PoleDefect.lean => 'পোল হেলে আছে',
        PoleDefect.hollow => 'ভেতরটা ফাঁপা',
        PoleDefect.groundRust => 'মাটির কাছে মরিচা',
        PoleDefect.weldRust => 'জোড়ে মরিচা',
        PoleDefect.bent => 'পোল বেঁকে গেছে',
        PoleDefect.insulator => 'ভাঙা ইনসুলেটর',
        PoleDefect.crossArm => 'বাঁকা ক্রস-আর্ম',
      };
}

abstract final class PoleMistakes {
  static DoMistake climbed(PoleDefect d) => switch (d) {
        PoleDefect.hairline => const DoMistake(
            key: '1.3/pole/hairline',
            textBn: 'চুলের মতো ফাটল দিয়ে জল ঢোকে, ভেতরের রডে মরিচা ধরে — বড় বিপদের শুরু। রিপোর্ট করুন, উঠবেন না।',
            art: 'assets/game/art/pole/pole_crack.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.spalling => const DoMistake(
            key: '1.3/pole/spalling',
            textBn: 'কংক্রিট খসে ভেতরের রড বেরিয়ে আছে — পোলের শক্তি প্রায় শেষ।',
            art: 'assets/game/art/pole/pole_crack.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.erosion => const DoMistake(
            key: '1.3/pole/erosion',
            textBn: 'গোড়ার মাটি ক্ষয়ে গর্ত, জল জমেছে — পোলের ভিত্তিই তার আসল শক্তি।',
            art: 'assets/game/art/pole/pole_base.svg',
            deadly: true,
            lessonPoint: 0),
        PoleDefect.lean => const DoMistake(
            key: '1.3/pole/lean',
            textBn: 'পোল হেলে আছে — আপনার ভারে ভেঙে পড়তে পারে, বা হঠাৎ সোজা হয়ে তার ছিঁড়তে পারে।',
            art: 'assets/game/art/pole/pole_base.svg',
            deadly: true,
            lessonPoint: 0),
        PoleDefect.hollow => const DoMistake(
            key: '1.3/pole/hollow',
            textBn: 'ঠুকলে ফাঁপা ‘দপ্’ শব্দ — ভেতরের কংক্রিট দুর্বল, ফাঁপা। বাইরে ঠিক দেখালেও উঠবেন না।',
            art: 'assets/game/art/pole/pole_sound.svg',
            deadly: true,
            lessonPoint: 1),
        PoleDefect.groundRust => const DoMistake(
            key: '1.3/pole/ground-rust',
            textBn: 'মাটির কাছে মরিচা — স্টিলের ক্যান্সার। স্টিলের পোলও সতর্কবার্তা ছাড়াই ভেঙে পড়ে।',
            art: 'assets/game/art/pole/steel_rust.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.weldRust => const DoMistake(
            key: '1.3/pole/weld-rust',
            textBn: 'ওয়েল্ডিং জয়েন্টে মরিচা — জোড়ের শক্তি নেই, ভার পড়লেই খুলে যেতে পারে।',
            art: 'assets/game/art/pole/steel_rust.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.bent => const DoMistake(
            key: '1.3/pole/bent',
            textBn: 'পোল বেঁকে বা মুচড়ে গেছে — কাঠামো আর আপনার ভার নিতে পারবে না।',
            art: 'assets/game/art/pole/pole_base.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.insulator => const DoMistake(
            key: '1.3/pole/insulator',
            textBn: 'ইনসুলেটর ভাঙা — কারেন্ট লিক করে পুরো পোল বিদ্যুতায়িত হতে পারে।',
            art: 'assets/game/art/pole/pole_hardware.svg',
            deadly: true,
            lessonPoint: 3),
        PoleDefect.crossArm => const DoMistake(
            key: '1.3/pole/cross-arm',
            textBn: 'ক্রস-আর্ম বাঁকা — আপনার ভারে ঘুরে যেতে বা ভেঙে পড়তে পারে।',
            art: 'assets/game/art/pole/pole_hardware.svg',
            deadly: true,
            lessonPoint: 3),
      };

  static const skipped = DoMistake(
    key: '1.3/pole/skipped-check',
    textBn: 'পোলটা ঠিক ছিল — কিন্তু না দেখেই উঠলেন। চারপাশ ঘুরুন, গোড়া দেখুন, ঠুকে শুনুন — তারপর উঠুন।',
    art: 'assets/game/art/pole/check_first.svg',
    lessonPoint: 0,
  );
  static const falseReport = DoMistake(
    key: '1.3/pole/false-report',
    textBn: 'এই পোলটা ঠিক ছিল — চারপাশ, গোড়া, শব্দ, ওপর সব ঠিক। দেখে-শুনে সিদ্ধান্ত নিন।',
    art: 'assets/game/art/pole/check_first.svg',
    lessonPoint: 1,
  );
  static List<DoMistake> get all => [for (final d in PoleDefect.values) climbed(d), skipped, falseReport];
}

const pccDefects = [PoleDefect.hairline, PoleDefect.spalling, PoleDefect.erosion, PoleDefect.lean, PoleDefect.hollow, PoleDefect.insulator, PoleDefect.crossArm];
const steelDefects = [PoleDefect.groundRust, PoleDefect.weldRust, PoleDefect.bent, PoleDefect.insulator, PoleDefect.crossArm];

@immutable
class PoleDeal {
  const PoleDeal({required this.poles, required this.callPole});
  final List<PoleCase> poles;

  /// The pole on which the pressure call comes (a condemned one).
  final int callPole;
}

/// Four poles: 2–3 condemned, at least one whose fault hides (on the back or
/// heard only), the rest sound; the main fault of the kind comes first-class.
PoleDeal dealPoles(math.Random rng, PoleKind kind) {
  final pool = kind == PoleKind.pcc ? pccDefects : steelDefects;
  final bad = 2 + rng.nextInt(2);
  final picks = [...pool]..shuffle(rng);
  // The lesson's headline fault always shows up once.
  final headline = kind == PoleKind.pcc ? PoleDefect.hairline : PoleDefect.groundRust;
  picks
    ..remove(headline)
    ..insert(0, headline);
  final poles = <PoleCase>[];
  for (var i = 0; i < 4; i++) {
    final flaws = <PoleFlaw>[];
    if (i < bad) {
      final d = picks[i % picks.length];
      // The first condemned pole hides its fault on the back (if it can).
      final side = i == 0 && !d.allSides ? PoleSide.back : (rng.nextBool() ? PoleSide.front : PoleSide.back);
      flaws.add(PoleFlaw(d, side));
    }
    poles.add(PoleCase(id: 'p$i', kind: kind, flaws: flaws, rail: kind == PoleKind.steel && rng.nextInt(3) == 0));
  }
  poles.shuffle(rng);
  final condemnedIdx = [for (var i = 0; i < 4; i++) if (poles[i].condemned) i];
  final headlineIdx = poles.indexWhere((p) => p.has(headline));
  return PoleDeal(poles: poles, callPole: headlineIdx >= 0 ? headlineIdx : condemnedIdx.first);
}

enum PoleCheck { walk, base, sound, top }

/// The play state (pure logic).
class PoleRun {
  PoleRun(this.deal);
  final PoleDeal deal;
  int index = 0;
  final Set<PoleCheck> checks = {};
  bool shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.poles.length;
  bool get ended => done || deadly != null;
  PoleCase get current => deal.poles[index.clamp(0, deal.poles.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void check(PoleCheck c) {
    if (!ended && !shown) checks.add(c);
  }

  /// Climb (true) or report (false). Returns the mistake, if any.
  DoMistake? decide({required bool climb}) {
    if (ended || shown) return null;
    shown = true;
    final p = current;
    if (climb && p.condemned) return deadly = PoleMistakes.climbed(p.flaws.first.defect);
    if (climb && !checks.containsAll(const [PoleCheck.walk, PoleCheck.base, PoleCheck.sound])) {
      slips++;
      return PoleMistakes.skipped;
    }
    if (!climb && !p.condemned) {
      slips++;
      return PoleMistakes.falseReport;
    }
    void tag(String t) {
      if (!caught.contains(t)) caught.add(t);
    }

    if (climb) {
      tag(PoleLines.caughtHabit);
    } else {
      tag(PoleLines.caughtReport);
      final f = p.flaws.first;
      if (f.defect.heardOnly) tag(PoleLines.caughtSound);
      if (!f.defect.allSides && !f.defect.heardOnly && f.side == PoleSide.back) tag(PoleLines.caughtBack);
    }
    return null;
  }

  void next() {
    index++;
    checks.clear();
    shown = false;
  }
}

@immutable
class PoleReadPack {
  const PoleReadPack({required this.id, required this.kind, required this.titleBn, this.quickMs = 90000});
  final String id;
  final PoleKind kind;
  final String titleBn;
  final int quickMs;
}

const poleReadPacks = {
  'do_1_3_a': PoleReadPack(id: 'do_1_3_a', kind: PoleKind.pcc, titleBn: PoleLines.titlePcc),
  'do_1_3_b': PoleReadPack(id: 'do_1_3_b', kind: PoleKind.steel, titleBn: PoleLines.titleSteel),
};

// ============================================================================
// Page
// ============================================================================

class PoleReadPage extends StatefulWidget {
  const PoleReadPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final PoleReadPack pack;
  final bool muted;
  final int? seed;

  @override
  State<PoleReadPage> createState() => _PoleReadPageState();
}

class _PoleReadPageState extends State<PoleReadPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PoleRunPage(
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

class _PoleRunPage extends ConsumerStatefulWidget {
  const _PoleRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final PoleReadPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PoleRunPage> createState() => _PoleRunPageState();
}

class _PoleRunPageState extends ConsumerState<_PoleRunPage> with DoDeathGuard, DoStrikeOut {
  final _scoreKey = GlobalKey();
  late final PoleRun _run = PoleRun(dealPoles(widget.rng, widget.pack.kind));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _rightBag = LineBag(PoleLines.right);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  PoleSide _side = PoleSide.front;
  PoleZone? _lens;
  String? _knock;
  int _knocks = 0;
  var _callOpen = false;
  var _callDone = false;
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
  bool get _pcc => widget.pack.kind == PoleKind.pcc;

  @override
  void initState() {
    super.initState();
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

  bool get _idle => !_busy && !_ended && !_callOpen && _card == null && !_run.shown;

  /// After the first look at the pole the pressure call comes (once).
  bool _maybeCall() {
    if (_callDone || _run.index != _run.deal.callPole || _run.shown || _run.ended) return false;
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
    setState(() {
      _callOpen = true;
      _lens = null;
    });
    unawaited(_say(_pcc ? PoleLines.pressurePcc : PoleLines.pressureSteel, other: true));
    return true;
  }

  void _afterCheck(PoleCheck c) {
    _run.check(c);
    setState(() {});
    _maybeCall();
  }

  void _walk() {
    if (!_idle) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.35, muted: false));
    setState(() {
      _side = _side == PoleSide.front ? PoleSide.back : PoleSide.front;
      _lens = null;
      _knock = null;
    });
    _afterCheck(PoleCheck.walk);
  }

  void _look(PoleZone z) {
    if (!_idle) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.4, muted: false));
    setState(() => _lens = z);
    if (z == PoleZone.base) _afterCheck(PoleCheck.base);
    if (z == PoleZone.top) _afterCheck(PoleCheck.top);
  }

  void _tapHammer() {
    if (!_idle) return;
    final p = _run.current;
    final bad = p.soundsBad;
    HapticFeedback.mediumImpact();
    final cue = _pcc ? (bad ? 'sounds/learn/knock_hollow.wav' : 'sounds/learn/knock_solid.wav') : (bad ? 'sounds/learn/dull_steel.wav' : 'sounds/learn/ring_steel.wav');
    if (!_muted) unawaited(ZlFx.cue(cue, volume: 0.9, muted: false));
    setState(() {
      _lens = null;
      _knocks++;
      _knock = _pcc ? (bad ? PoleLines.hollow : PoleLines.solid) : (bad ? PoleLines.dull : PoleLines.ring);
    });
    _afterCheck(PoleCheck.sound);
  }

  Future<void> _answerCall(bool held, Offset origin) async {
    if (!_callOpen) return;
    _hush();
    setState(() {
      _callOpen = false;
      _callDone = true;
    });
    if (!held) {
      await _decide(true, origin);
      return;
    }
    _run.caught.add(PoleLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(_sayChain([PoleLines.callHeld], mood: GuideMood.glad));
  }

  Future<void> _decide(bool climb, Offset origin) async {
    if (_busy || _ended || _card != null || _run.shown) return;
    _hush();
    final m = _run.decide(climb: climb);
    HapticFeedback.mediumImpact();
    setState(() => _lens = null);
    if (m == null) {
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      final bonus = _run.checks.length == 4 ? 5 : 0;
      unawaited(_levelDelta(15 + bonus, origin, mood: GuideMood.glad));
      unawaited(_sayChain([climb ? PoleLines.sound : PoleLines.reported, _rightBag.next().shownBn], mood: GuideMood.glad));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
    } else {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
    }
  }

  void _next() {
    if (_busy || _card != null || !_run.shown) return;
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _side = PoleSide.front;
      _lens = null;
      _knock = null;
    });
    unawaited(_sayChain([PoleLines.ask]));
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
    final speak = await SpokenOnce.first('pole/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('pole/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? PoleLines.deadlyWord : PoleLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
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
    await _say(!_run.passed ? PoleLines.fail : (_quickBonus ? PoleLines.quick : PoleLines.allSet),
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
    final p = _run.current;
    final shown = _run.shown;
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
                      labels: PoleLines.rounds,
                      done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
                      current: _run.done ? null : _run.index,
                      quiet: quiet,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 360,
                              height: 480,
                              child: _PoleScene(
                                key: ValueKey('pole-${_run.index}'),
                                pole: p,
                                side: _side,
                                knock: _knock,
                                knocks: _knocks,
                                reveal: shown,
                                quiet: quiet,
                                onZone: _look,
                                onWalk: _walk,
                                onHammer: _tapHammer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: shown
                          ? SizedBox(
                              width: double.infinity,
                              child: DoBigButton(
                                label: _run.index >= _run.deal.poles.length - 1 ? PoleLines.finish : PoleLines.next,
                                filled: true,
                                onTapUp: (_) => _next(),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(child: _ReportButton(onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                                const SizedBox(width: 10),
                                Expanded(child: DoBigButton(label: PoleLines.climb, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                              ],
                            ),
                    ),
                    Opacity(opacity: _card == null && !_callOpen && _lens == null ? 1 : 0, child: DoCoachStrip(tasks: PoleLines.tasks, muted: _muted)),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              if (_lens != null)
                _Lens(
                  key: ValueKey('lens-$_lens-$_side'),
                  pole: p,
                  side: _side,
                  zone: _lens!,
                  quiet: quiet,
                  onClose: () => setState(() => _lens = null),
                ),
              if (_callOpen)
                DoCallCard(
                  caller: DoCaller(
                    id: 'pressure',
                    whoBn: _pcc ? PoleLines.pressureWhoPcc : PoleLines.pressureWhoSteel,
                    lineBn: _pcc ? PoleLines.pressurePcc : PoleLines.pressureSteel,
                    icon: Icons.record_voice_over_rounded,
                  ),
                  quiet: quiet,
                  rushBn: PoleLines.giveIn,
                  holdBn: PoleLines.holdOut,
                  onAnswer: (held, o) => unawaited(_answerCall(held, o)),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
              if (struckOut)
                StruckOutCard(
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.thud,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                LevelIntro(
                  lines: [_pcc ? PoleLines.introPcc : PoleLines.introSteel, PoleLines.ask],
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
                                onRead: () => unawaited(openLessonPoint(context, ref,
                                    lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
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

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x1AFFFFFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.85), width: 1.6),
          ),
          child: Text(PoleLines.report,
              textAlign: TextAlign.center,
              style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xE6122036),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: SlmColors.gold300),
              const SizedBox(width: 5),
              Text(label, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pole on the village road: tap base / waist / top to look close; walk
/// round and hammer from the corners. After the decision the fault is ringed.
class _PoleScene extends StatelessWidget {
  const _PoleScene({
    super.key,
    required this.pole,
    required this.side,
    required this.knock,
    required this.knocks,
    required this.reveal,
    required this.quiet,
    required this.onZone,
    required this.onWalk,
    required this.onHammer,
  });
  final PoleCase pole;
  final PoleSide side;
  final String? knock;
  final int knocks;
  final bool reveal;
  final bool quiet;
  final ValueChanged<PoleZone> onZone;
  final VoidCallback onWalk;
  final VoidCallback onHammer;

  static const zoneRects = {
    PoleZone.top: Rect.fromLTRB(110, 60, 250, 160),
    PoleZone.waist: Rect.fromLTRB(140, 220, 220, 340),
    PoleZone.base: Rect.fromLTRB(120, 370, 240, 452),
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/pole/village_road.svg', fit: BoxFit.fill)),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: quiet ? Duration.zero : const Duration(milliseconds: 320),
              transitionBuilder: (child, a) => ScaleTransition(
                scale: Tween(begin: 0.0, end: 1.0).animate(a),
                child: child,
              ),
              child: CustomPaint(
                key: ValueKey(side),
                painter: PolePainter(pole: pole, side: side),
                size: const Size(360, 480),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(10)),
            child: Text(side == PoleSide.front ? PoleLines.front : PoleLines.back,
                style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
          ),
        ),
        if (reveal)
          for (final f in pole.flaws)
            Positioned.fromRect(
              rect: zoneRects[f.defect.zone]!.inflate(4),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SlmColors.danger, width: 3),
                  ),
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '${PoleLines.defectBn(f.defect)}${f.defect.allSides || f.defect.heardOnly ? '' : ' · ${f.side == PoleSide.front ? PoleLines.front : PoleLines.back}'}',
                        style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        if (!reveal)
          for (final e in zoneRects.entries)
            Positioned.fromRect(
              rect: e.value,
              child: Semantics(
                button: true,
                label: 'পোলের অংশ',
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => onZone(e.key)),
              ),
            ),
        if (knock != null)
          Positioned(
            left: 210,
            top: 252,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('knock-$knocks'),
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: t, alignment: Alignment.centerLeft, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(12)),
                child: Text(knock!, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.ink)),
              ),
            ),
          ),
        if (!reveal) ...[
          Positioned(left: 10, bottom: 10, child: _ToolChip(icon: Icons.threesixty_rounded, label: PoleLines.walk, onTap: onWalk)),
          Positioned(right: 10, bottom: 10, child: _ToolChip(icon: Icons.handyman_rounded, label: PoleLines.tap, onTap: onHammer)),
        ],
      ],
    );
  }
}

/// A close look at one part of the pole (3× magnifier).
class _Lens extends StatelessWidget {
  const _Lens({super.key, required this.pole, required this.side, required this.zone, required this.quiet, required this.onClose});
  final PoleCase pole;
  final PoleSide side;
  final PoleZone zone;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final focus = _PoleScene.zoneRects[zone]!.center;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.7 + 0.3 * t, child: child),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: SlmColors.gold300, width: 6),
                  boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 20)],
                ),
                child: ClipOval(
                  child: CustomPaint(painter: PolePainter(pole: pole, side: side, focus: focus, zoom: 2.6, backdrop: true)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pole drawn in scene units (360 x 480; ground at 440): PCC (tapered
/// concrete) or steel (tube, or rail), cross-arm with three insulators, and
/// the faults that can be seen from [side]. With [focus] it draws a zoomed
/// view centred there (the magnifier).
class PolePainter extends CustomPainter {
  PolePainter({required this.pole, required this.side, this.focus, this.zoom = 1, this.backdrop = false});
  final PoleCase pole;
  final PoleSide side;
  final Offset? focus;
  final double zoom;
  final bool backdrop;

  static const _cx = 180.0;
  static const _ground = 440.0;
  static const _top = 70.0;

  bool _sees(PoleDefect d) => pole.flaws.any((f) => f.defect == d && f.seenFrom(side));

  @override
  void paint(Canvas c, Size size) {
    if (focus != null) {
      c.translate(size.width / 2, size.height / 2);
      c.scale(zoom * size.width / 280);
      c.translate(-focus!.dx, -focus!.dy);
    }
    if (backdrop) {
      c.drawRect(const Rect.fromLTRB(-400, -400, 800, 360), Paint()..color = const Color(0xFFD9E5EE));
      c.drawRect(const Rect.fromLTRB(-400, 360, 800, 440), Paint()..color = const Color(0xFF9DB37A));
      c.drawRect(const Rect.fromLTRB(-400, 440, 800, 900), Paint()..color = const Color(0xFFB59A6E));
    }
    final steel = pole.kind == PoleKind.steel;
    // Base: eroded ground with water, or a clean collar.
    if (_sees(PoleDefect.erosion)) {
      c.drawPath(
        Path()
          ..moveTo(_cx - 46, _ground)
          ..quadraticBezierTo(_cx, _ground + 34, _cx + 46, _ground)
          ..close(),
        Paint()..color = const Color(0xFF5B4A33),
      );
      c.drawOval(Rect.fromCenter(center: const Offset(_cx, _ground + 9), width: 60, height: 10), Paint()..color = const Color(0xCC5AA0D8));
    } else {
      c.drawRect(Rect.fromLTRB(_cx - 30, _ground - 4, _cx + 30, _ground + 6), Paint()..color = const Color(0xFF9D9A90));
    }

    c.save();
    if (pole.has(PoleDefect.lean)) {
      c.translate(_cx, _ground);
      c.rotate(side == PoleSide.front ? 0.09 : -0.09);
      c.translate(-_cx, -_ground);
    }
    final bentAt = pole.has(PoleDefect.bent) ? 250.0 : null;

    // The body.
    final bodyPath = Path();
    if (steel) {
      const w = 11.0;
      if (bentAt != null) {
        final k = side == PoleSide.front ? 16.0 : -16.0;
        bodyPath
          ..moveTo(_cx - w, _ground)
          ..lineTo(_cx - w, bentAt + 30)
          ..quadraticBezierTo(_cx - w + k, bentAt, _cx - w + k * 0.6, bentAt - 40)
          ..lineTo(_cx - w + k * 0.6, _top)
          ..lineTo(_cx + w + k * 0.6, _top)
          ..lineTo(_cx + w + k * 0.6, bentAt - 40)
          ..quadraticBezierTo(_cx + w + k, bentAt, _cx + w, bentAt + 30)
          ..lineTo(_cx + w, _ground)
          ..close();
      } else {
        bodyPath.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(_cx - w, _top, _cx + w, _ground), const Radius.circular(4)));
      }
      c.drawPath(bodyPath, Paint()..color = const Color(0xFF8E979F));
      if (pole.rail) {
        final flange = Paint()
          ..color = const Color(0xFF6B747C)
          ..strokeWidth = 3;
        c.drawLine(Offset(_cx - 6, _top), Offset(_cx - 6, _ground), flange);
        c.drawLine(Offset(_cx + 6, _top), Offset(_cx + 6, _ground), flange);
      } else if (bentAt == null) {
        c.drawLine(Offset(_cx - 6, _top + 4), Offset(_cx - 6, _ground - 4), Paint()..color = const Color(0xFFC9D0D6)..strokeWidth = 3);
      }
      // Weld joint band.
      c.drawRect(Rect.fromLTRB(_cx - 12, 278, _cx + 12, 284), Paint()..color = const Color(0xFF6B747C));
    } else {
      bodyPath
        ..moveTo(_cx - 16, _ground)
        ..lineTo(_cx - 9, _top)
        ..lineTo(_cx + 9, _top)
        ..lineTo(_cx + 16, _ground)
        ..close();
      c.drawPath(bodyPath, Paint()..color = side == PoleSide.front ? const Color(0xFFBDBAB1) : const Color(0xFFB3B0A7));
      final dot = Paint()..color = const Color(0x55807C72);
      final rnd = math.Random(side.index + 3);
      for (var i = 0; i < 40; i++) {
        final y = _top + rnd.nextDouble() * (_ground - _top);
        final half = 9 + 7 * (y - _top) / (_ground - _top);
        c.drawCircle(Offset(_cx + (rnd.nextDouble() * 2 - 1) * (half - 2), y), 1.1, dot);
      }
    }
    c.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF6E6B63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Faults on the body.
    if (_sees(PoleDefect.hairline)) {
      final p = Path()
        ..moveTo(_cx - 2, 232)
        ..lineTo(_cx + 3, 252)
        ..lineTo(_cx - 3, 270)
        ..lineTo(_cx + 2, 292)
        ..lineTo(_cx - 1, 318);
      c.drawPath(p, Paint()..color = const Color(0xFF3B3A36)..style = PaintingStyle.stroke..strokeWidth = 1.1);
    }
    if (_sees(PoleDefect.spalling)) {
      final r = Rect.fromCenter(center: const Offset(_cx + 1, 300), width: 22, height: 30);
      c.drawOval(r, Paint()..color = const Color(0xFF8F8B80));
      final bar = Paint()
        ..color = const Color(0xFFA0522D)
        ..strokeWidth = 2.2;
      c.drawLine(Offset(_cx - 5, 288), Offset(_cx - 5, 312), bar);
      c.drawLine(Offset(_cx + 6, 287), Offset(_cx + 6, 313), bar);
      final chip = Paint()..color = const Color(0xFFADA99E);
      c.drawCircle(const Offset(_cx + 24, _ground - 2), 3, chip);
      c.drawCircle(const Offset(_cx - 20, _ground - 1), 2.4, chip);
    }
    if (_sees(PoleDefect.groundRust)) {
      c.drawRect(Rect.fromLTRB(_cx - 11, 404, _cx + 11, _ground), Paint()..color = const Color(0xFF9A4F22));
      final spot = Paint()..color = const Color(0xFFC9783A);
      for (final o in const [Offset(-5, 410), Offset(4, 420), Offset(-2, 432), Offset(6, 406)]) {
        c.drawCircle(Offset(_cx + o.dx, o.dy), 3, spot);
      }
      c.drawPath(
        Path()
          ..moveTo(_cx - 11, 418)
          ..lineTo(_cx - 5, 422)
          ..lineTo(_cx - 11, 428)
          ..close(),
        Paint()..color = const Color(0xFFD9E5EE),
      );
      final flake = Paint()..color = const Color(0xFFA0522D);
      c.drawRect(const Rect.fromLTWH(_cx + 16, _ground - 1, 5, 2), flake);
      c.drawRect(const Rect.fromLTWH(_cx - 24, _ground, 4, 2), flake);
    }
    if (_sees(PoleDefect.weldRust)) {
      c.drawRect(Rect.fromLTRB(_cx - 13, 274, _cx + 13, 290), Paint()..color = const Color(0xFF9A4F22));
      final spot = Paint()..color = const Color(0xFFC9783A);
      c.drawCircle(const Offset(_cx - 6, 280), 3, spot);
      c.drawCircle(const Offset(_cx + 5, 286), 2.5, spot);
      c.drawLine(Offset(_cx - 13, 290), Offset(_cx - 8, 296), Paint()..color = const Color(0xFF9A4F22)..strokeWidth = 2);
    }

    // Cross-arm and insulators.
    final bentArm = _sees(PoleDefect.crossArm);
    final arm = Paint()
      ..color = const Color(0xFF5F676F)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final dx = bentAt != null ? (side == PoleSide.front ? 9.6 : -9.6) : 0.0;
    if (bentArm) {
      c.drawPath(
        Path()
          ..moveTo(_cx - 62 + dx, 92)
          ..quadraticBezierTo(_cx + dx, 84, _cx + 62 + dx, 112),
        arm..style = PaintingStyle.stroke,
      );
    } else {
      c.drawLine(Offset(_cx - 62 + dx, 96), Offset(_cx + 62 + dx, 96), arm);
    }
    final ins = Paint()..color = const Color(0xFFE9E6DF);
    final insEdge = Paint()
      ..color = const Color(0xFF9C978C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final broken = _sees(PoleDefect.insulator);
    for (final (i, x) in const [(0, -54.0), (1, 0.0), (2, 54.0)]) {
      final y = bentArm ? (x < 0 ? 78.0 : (x > 0 ? 96.0 : 76.0)) : 80.0;
      final r = Rect.fromLTWH(_cx + x + dx - 6, y, 12, 12);
      if (broken && i == 2) {
        c.drawPath(
          Path()
            ..moveTo(r.left, r.bottom)
            ..lineTo(r.left, r.top + 5)
            ..lineTo(r.left + 5, r.top + 2)
            ..lineTo(r.right - 2, r.top + 7)
            ..lineTo(r.right, r.bottom)
            ..close(),
          ins,
        );
        c.drawLine(Offset(r.left + 4, r.top + 4), Offset(r.left + 7, r.bottom - 2), Paint()..color = const Color(0xFF3B3A36)..strokeWidth = 1.2);
        c.drawCircle(Offset(_cx + x + dx + 12, _ground - 2), 2.5, ins);
      } else {
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), ins);
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), insEdge);
      }
    }
    // The wires.
    final wire = Paint()
      ..color = const Color(0xFF2A2F35)
      ..strokeWidth = 2;
    for (final x in const [-54.0, 0.0, 54.0]) {
      c.drawLine(Offset(-400, 80 + (x == 0 ? -4 : 0)), Offset(_cx + x + dx, 80), wire);
      c.drawLine(Offset(_cx + x + dx, 80), Offset(800, 82), wire);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(PolePainter old) => old.pole != pole || old.side != side || old.focus != focus;
}
