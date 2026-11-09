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
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'level_frame.dart';
import 'level_juice.dart' show Combo, ComboPop, FreezeFrame, RescueBurst, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'pole_read.dart' show PoleCase, PoleDefect, PoleFlaw, PoleKind, PolePainter, PoleSide;
import 'pole_yard.dart' show PoleGeo, PoleYardPainter;
import 'ptw_site.dart' show PtwGeo, PtwSitePainter;
import 'reason_table.dart';
import 'rod_van.dart' show RodVanGeo, RodVanPainter;
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'sky_world.dart' show SkyBolt, SkyGeo, SkyWeather, SkyWorldPainter;

// Step 30 (Module 1 Rank Gate): "প্রথম ডকেট" (First Real Field Docket).
// A full-scale 5-station emergency field dispatch combining all 5 moves of Module 1:
//   Station 1: ভ্যান ও টুলস বাছাই — Pick the certified 11 kV discharge rod, reject PVC jugaad & damaged gear.
//   Station 2: পারমিট ও সাইট যাচাই — Match written PTW with pole feeder plate; refuse verbal phone call shortcut.
//   Station 3: পোলের ৩৬০° ও শব্দ পরীক্ষা — 360° orbit inspection & acoustic hammer knock (solid ঠক্ ঠক্ vs hollow).
//   Station 4: আগে মাটি, পরে লাইন — Earth spike first, hook R-Y-B phases with live blue spark discharge!
//   Station 5: ঝড়-বৃষ্টি ও সহকর্মীর চাপ — Darkening storm sky, rival coworker pushes to rush; choose safety & van shelter.
//
// Passing this gate awards the Trainee ("ট্রেইনি") rank and the "সুরক্ষা কবচ" badge.

// ============================================================================
// Content & Models
// ============================================================================

@immutable
class GateFieldPack {
  const GateFieldPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const gateFieldPacks = {
  'gate_m1': GateFieldPack(id: 'gate_m1', titleBn: GateLines.title),
};

enum GateStation { van, ptw, pole, discharge, storm }

abstract final class GateMistakes {
  static const jugaadRod = DoMistake(
    key: 'm1/gate/jugaad-rod',
    textBn: 'পিভিসি পাইপ বা বাঁশের জুগাড় রড প্রাণঘাতী — ভেজা ও ময়লায় হাই-ভোল্টেজ আর্ক সরাসরি শরীরে ঢুকে যায়।',
    art: 'assets/game/art/rod/jugaad_vs_standard.svg',
    deadly: true,
    lessonPoint: 4,
  );

  static const damagedRod = DoMistake(
    key: 'm1/gate/damaged-rod',
    textBn: 'ফাটলযুক্ত বা কাটা কেবিলের রড বাতিল করতে হবে — ফাটা স্টিক নিজেই বিদ্যুৎ পরিবাহী হতে পারে।',
    art: 'assets/game/art/rod/rod_flaws.svg',
    lessonPoint: 2,
  );

  static const verbalPtw = DoMistake(
    key: 'm1/gate/verbal-ptw',
    textBn: 'ফোনে বা মৌখিক ভরসায় কাজ শুরু সাক্ষাৎ মৃত্যু — হাতে স্বাক্ষরিত লিখিত PTW ছাড়া লাইনে হাত নয়।',
    art: 'assets/game/art/ptw/verbal_vs_written.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const condemnedPole = DoMistake(
    key: 'm1/gate/condemned-pole',
    textBn: 'শব্দ পরীক্ষা ও চারপাশ না দেখে পোলে উঠবেন না — ফাঁপা বা ক্ষয়প্রাপ্ত পোল লাইনম্যানের ভারে ভেঙে পড়ে।',
    art: 'assets/game/art/pole/pole_sound.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const lineBeforeEarth = DoMistake(
    key: 'm1/gate/line-before-earth',
    textBn: 'আগে লাইনে হুক, পরে আর্থ মারাত্মক ভুল — লাইনে জমে থাকা ক্যাপাসিটিভ চার্জ লাইনম্যানের শরীর দিয়ে নামবে।',
    art: 'assets/game/art/discharge/wrong_right.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const stormLadderSlip = DoMistake(
    key: 'm1/gate/storm-ladder-slip',
    textBn: 'ঝড় ও প্রবল বাতাসে মই বেয়ে ওঠা মারাত্মক — ভিজে পিচ্ছিল ধাপে পা পিছলে নিচে পড়ে যাওয়ার ঝুঁকি! কালবৈশাখীতে উঁচুতে কাজ বন্ধ রাখা বাধ্যতামূলক।',
    art: 'assets/game/art/storm_board/push_lightning.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const lightningBackfeed = DoMistake(
    key: 'm1/gate/lightning-backfeed',
    textBn: 'লাইন বন্ধ থাকলেও বজ্রপাতের সময় সঞ্চালন তারে হাজার হাজার ভোল্টের আবেশিত বিদ্যুৎ (Induced Voltage) সৃষ্টি হয়! ঝড়বৃষ্টিতে তারে স্পর্শ সাক্ষাৎ মৃত্যু।',
    art: 'assets/game/art/storm_board/push_lightning.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const stormClimb = DoMistake(
    key: 'm1/gate/storm-climb',
    textBn: 'মেঘের গর্জন বা বজ্র শুনলে উঁচুতে কাজ বন্ধ — কোনো পিপিই বজ্রপাত ঠেকাতে পারে না। নেমে আসা বাধ্যতামূলক।',
    art: 'assets/game/art/storm_board/push_lightning.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const shelterTree = DoMistake(
    key: 'm1/gate/shelter-tree',
    textBn: 'মাঠের একা গাছতলা বা পোলের গোড়া আশ্রয় নয় — সরাসরি বজ্র বা স্টেপ পটেনশিয়াল মারাত্মক। গাড়িতে নিরাপদ আশ্রয় নিন।',
    art: 'assets/game/art/storm_board/push_shelter.svg',
    deadly: true,
    lessonPoint: 1,
  );

  static const all = [
    jugaadRod,
    damagedRod,
    verbalPtw,
    condemnedPole,
    lineBeforeEarth,
    stormLadderSlip,
    lightningBackfeed,
    stormClimb,
    shelterTree,
  ];
}

abstract final class GateLines {
  static const title = 'প্রথম ডকেট · র‍্যাঙ্ক গেট';
  static const intro =
      'জরুরি ডকেট এলো! ১১ কেভি ফিডার মেরামত। ভ্যান থেকে সঠিক রড বাছাই, পারমিট মেলানো, পোলের শব্দ পরীক্ষা, ডিসচার্জ স্পার্ক এবং ঝড় থেকে নিরাপদে ফিরে ট্রেইনি পদোন্নতি অর্জন করুন!';

  static const askVan = 'ডকেট ১১ কেভি লাইনের। ভ্যান থেকে ঠিক রডটি বেছে নিন।';
  static const askPtw = 'সাইটের ফিডার প্লেট দেখুন। ফোনে কাজ শুরু করবেন, না থামবেন?';
  static const askPole = 'পোল ঘুরে দেখুন ও হাতুড়ি ঠুকে পোলের ভাষা পড়ুন। উঠবেন?';
  static const askDischarge = 'ডিসচার্জ ক্রম: আগে মাটি, পরে তিন ফেজে হুক ঠেকান।';
  static const askStorm = 'আকাশে বজ্র ডাকছে! সহকর্মীর চাপ মানবেন, না নিরাপদ আশ্রয়ে যাবেন?';

  static const ptwPhoneLine = 'লাইন বন্ধ করেছি, তোমরা কাজ শুরু করো — কাগজ পরে পাঠাচ্ছি।';
  static const knockSolidWord = 'ঠক্ ঠক্';

  // Station 1: Van Reasons
  static const whyRodRight = [
    'ডকেটের ভোল্টেজ ১১ কেভি, রডের রেটিংও ১১ কেভি',
    'রেটিং মিলেছে এবং স্টিক ও আর্থ লিড সম্পূর্ণ অক্ষত',
  ];
  static const whyRodWrong = [
    'যেকোনো রড দিয়েই কাজ চলে, রেটিংয়ের দরকার নেই',
    'প্লাস্টিক বা পিভিসি পাইপ হলেও রডের কাজ চলে যায়',
    'লাইন বন্ধ থাকলে রডের রেটিং মেলানোর দরকার পড়ে না',
  ];

  // Station 2: PTW Reasons
  static const whyPtwRight = [
    'ফোনের কথায় নয়, হাতে লিখিত ও স্বাক্ষরিত পারমিট চাই',
    'স্বাক্ষরিত পিটিডব্লিউ ছাড়া লাইনে হাত দেওয়া নিষিদ্ধ',
  ];
  static const whyPtwWrong = [
    'সাবস্টেশনের অপারেটর বলেছে, তাই শুরু করলেই হতো',
    'কাগজ আসতে দেরি হবে, ফোনের ভরসায় কাজ শেষ করা ভালো',
    'জরুরি কাজে লিখিত পারমিটের কোনো বাধ্যবাধকতা নেই',
  ];

  // Station 3: Pole Reasons
  static const whyPoleRight = [
    'চারপাশ ঘুরে দেখেছি এবং হাতুড়ি ঠুকে নিরেট শব্দ পেয়েছি',
    'পোলের গোড়া শক্ত এবং ঠুকলে পরিষ্কার ঠক্ ঠক্ শব্দ হয়েছে',
  ];
  static const whyPoleWrong = [
    'নতুন দেখতে পোলে হাতুড়ি ঠুকে দেখার কোনো দরকার পড়ে না',
    'সিমেন্টের পোলে ভেতর ফাঁপা থাকলেও উপরে ওঠা নিরাপদ',
    'বাইরে ঠিক দেখালে পোলের ভেতরে ফাটল থাকার সম্ভাবনা নেই',
  ];

  // Station 4: Discharge Reasons
  static const whyDischargeRight = [
    'আগে মাটি, যাতে জমে থাকা চার্জ নিরাপদে মাটিতে নামে',
    'আগে আর্থ ক্ল্যাম্প না দিলে চার্জ শরীর দিয়ে নামত',
  ];
  static const whyDischargeWrong = [
    'আগে তারে হুক দিলে স্পার্কটা দেখতে বেশি ভালো লাগে',
    'লাইন ৫ মিনিট বন্ধ থাকলে আর কোনো চার্জ জমে থাকে না',
    'আগে মাটিতে ক্ল্যাম্প দিলে রডটা তুলতে বেশ ভারী লাগে',
  ];

  // Station 5: Storm Reasons
  static const whyStormRight = [
    'বজ্র শুনলে উঁচুতে কাজ বন্ধ এবং ধাতব গাড়িতে নিরাপদ আশ্রয়',
    'জীবনের চেয়ে কোনো কাজ বড় নয়, বজ্রের শব্দেই নেমে এসেছি',
  ];
  static const whyStormWrong = [
    'রাবারের জুতো থাকলে বজ্রপাতে কোনো ক্ষতি হতে পারে না',
    'সহকর্মী বলেছে তাই আর পাঁচ মিনিট কাজ শেষ করে নামা উচিত',
    'মাঠের মাঝে বড় গাছের নিচে দাঁড়ালে বজ্র থেকে বাঁচা যায়',
  ];

  // Coworker Script
  static const coworker = CoworkerScript(
    line: 'আর একটু, শেষ করে নামি! এইটুকু কাজ ফেলে কেউ নামে?',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: [
      'না, এখনই কাজ থামিয়ে নেমে আসছি',
      'না, আকাশ যা বলছে সেটাই শুনব',
      'কাজের চেয়ে জীবন বড়, এখনই নামছি',
    ],
    wrong: [
      'ঠিক, আর একটু করে তবেই নামি',
      'এইটুকু কাজ ফেলে নামা যায় না',
      'সবাই তো এভাবেই কাজ শেষ করে',
      'ঠিক আছে, শেষ নাটটা কষে নিই',
    ],
    asks: [
      'ও বলছে শেষ করে নামতে। আপনি কী করবেন?',
      'আকাশের কথা শুনবেন, না ওর?',
      'থামবেন, না আর একটু চালাবেন?',
    ],
  );

  static const allSet = 'অভিনন্দন! প্রথম ডকেট সম্পূর্ণ সফল! আপনি এখন অনুমোদিত ট্রেইনি লাইনম্যান!';
  static const fail = 'আরেকবার — পাঁচটা স্টেশনের প্রতিটি নিয়ম নিখুঁতভাবে পালন করে ট্রেইনি ব্যাজ জিতুন।';
}

// ============================================================================
// Game Logic
// ============================================================================

enum RodChoice { kv11Ok, kv33High, pvcJugaad, crackedStick }

class GateRun {
  GateRun(this.seed);
  final int seed;

  GateStation station = GateStation.van;
  final Set<GateStation> completed = {};
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // Station 3 (Pole) interaction trackers
  bool poleWalked = false;
  bool poleKnocked = false;

  // Station 4 (Discharge) interaction trackers
  bool earthClamped = false;
  final Set<String> phasesTouched = {};

  bool get done => completed.length == GateStation.values.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  // 1. Van Rod Pick
  DoMistake? chooseRod(RodChoice choice) {
    switch (choice) {
      case RodChoice.kv11Ok:
        tag('১১ কেভি সঠিক রড বাছাই');
        return null;
      case RodChoice.pvcJugaad:
        return deadly = GateMistakes.jugaadRod;
      case RodChoice.crackedStick:
        slips++;
        return GateMistakes.damagedRod;
      case RodChoice.kv33High:
        slips++;
        return GateMistakes.damagedRod;
    }
  }

  // 2. PTW Answer
  DoMistake? answerPtw({required bool stopWork}) {
    if (stopWork) {
      tag('মৌখিক নির্দেশে কাজ বন্ধ');
      return null;
    } else {
      return deadly = GateMistakes.verbalPtw;
    }
  }

  // 3. Pole Decision
  DoMistake? decidePole({required bool climb}) {
    if (!poleWalked || !poleKnocked) {
      slips++;
      return GateMistakes.condemnedPole;
    }
    if (climb) {
      tag('পোলের নিরেট শব্দ যাচাই');
      return null;
    } else {
      slips++;
      return GateMistakes.condemnedPole;
    }
  }

  // 4. Discharge Steps
  DoMistake? touchDischargeElement(String id) {
    if (id == 'earth') {
      earthClamped = true;
      tag('আগে আর্থ ক্ল্যাম্প সংযোগ');
      return null;
    }
    if (!earthClamped) {
      return deadly = GateMistakes.lineBeforeEarth;
    }
    phasesTouched.add(id);
    if (phasesTouched.length == 3) {
      tag('৩ ফেজ ডিসচার্জ সম্পন্ন');
    }
    return null;
  }

  // 5. Storm Shelter Pick
  DoMistake? chooseShelter({required bool vanChosen}) {
    if (vanChosen) {
      tag('গাড়িতে নিরাপদ আশ্রয়');
      return null;
    } else {
      return deadly = GateMistakes.shelterTree;
    }
  }

  void advanceStation() {
    completed.add(station);
    final nextIdx = station.index + 1;
    if (nextIdx < GateStation.values.length) {
      station = GateStation.values[nextIdx];
    }
  }
}

// ============================================================================
// UI Page
// ============================================================================

class GateFieldPage extends StatefulWidget {
  const GateFieldPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final GateFieldPack pack;
  final bool muted;
  final int? seed;

  @override
  State<GateFieldPage> createState() => _GateFieldPageState();
}

class _GateFieldPageState extends State<GateFieldPage> {
  var _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _GateFieldRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        seed: (widget.seed ?? 101) + _round,
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _GateFieldRunPage extends ConsumerStatefulWidget {
  const _GateFieldRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.seed,
    required this.onRetry,
  });

  final LevelContext ctx;
  final GateFieldPack pack;
  final bool muted;
  final int seed;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_GateFieldRunPage> createState() => _GateFieldRunPageState();
}

class _GateFieldRunPageState extends ConsumerState<_GateFieldRunPage>
    with TickerProviderStateMixin, DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final GateRun _run = GateRun(widget.seed);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  var _wake = 0;
  final _combo = Combo();
  int _comboN = 0;
  int _comboMult = 1;
  var _sparkActive = false;
  Offset? _sparkAt;
  var _thunderFlash = false;
  double _poleOrbit = 0.0;
  String? _poleSoundWord;

  // Real Lineman Physical Animation & State
  RodChoice? _selectedRod;
  late final AnimationController _climbCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addListener(() {
      if (mounted) setState(() {});
    });
  var _climbing = false;
  var _verdictClimbed = false;
  var _poleTilted = false;
  var _hammerSwing = false;
  var _earthClamped = false;
  var _zapActive = false;
  Offset? _zapFrom;
  Offset? _zapTo;
  var _lightningActive = false;
  Offset? _lightningTarget;
  var _docketOpen = false;
  var _ladderWobble = 0.0;
  var _fallArrested = false;

  /// A deadly move: the scene freezes in grey while the consequence plays.
  var _freeze = false;
  Completer<void>? _frozen;

  /// A station completed: the rescue bloom over the yard.
  var _bloomActive = false;
  int _bloomRound = 0;

  void _triggerBloom() {
    if (_bloomActive || !mounted) return;
    setState(() {
      _bloomActive = true;
      _bloomRound++;
    });
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _bloomActive = false);
    });
  }

  /// A right move scores with the combo multiplier (and pops "×2" when it rises).
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
  LevelContext get deathCtx => widget.ctx;

  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    _climbCtl.dispose();
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

  Future<void> _start() async {
    setState(() {
      _intro = false;
      _docketOpen = true;
    });
    _clock.start();
    await _enterStation();
  }

  Future<void> _enterStation() async {
    setState(() => _wake++);
    final taskLine = switch (_run.station) {
      GateStation.van => GateLines.askVan,
      GateStation.ptw => GateLines.askPtw,
      GateStation.pole => GateLines.askPole,
      GateStation.discharge => GateLines.askDischarge,
      GateStation.storm => GateLines.askStorm,
    };
    await _say(taskLine);

    if (_run.station == GateStation.ptw) {
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.8, muted: false));
      }
    }

    if (_run.station == GateStation.storm && !coworkerDone) {
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/learn/thunder_near.wav', volume: 0.75, muted: false));
      }
      setState(() => _thunderFlash = true);
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _thunderFlash = false);
      });
      scheduleCoworker();
    }
  }

  // --- Lineman Physical Actions per Station ----------------------------------

  Future<void> _onChooseRod(RodChoice choice, Offset origin) async {
    if (_busy || _ended || _card != null || reasonOpen) return;
    _busy = true;
    _hush();

    setState(() {
      _selectedRod = choice;
      _wake++;
    });

    final m = _run.chooseRod(choice);
    if (m == null) {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: false));
      final delta = _scored(20);
      _totalDelta += delta;
      _runScore += delta;
      await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: GuideMood.celebrate, muted: _muted);
      await _say('সঠিক নির্বাচন! ১১ কেভি সার্টিফাইড রড নির্বাচন সম্পূর্ণ।', mood: GuideMood.celebrate);
      _run.advanceStation();
      _triggerBloom();
      _busy = false;
      await _enterStation();
      return;
    }
    await _handleMistake(m);
  }

  Future<void> _onAnswerPtw(bool stopWork, Offset origin) async {
    if (_busy || _ended || _card != null || _climbing) return;
    _busy = true;
    _hush();

    if (!stopWork) {
      // Climbed pole without written PTW: Backfeed Arc Flash!
      setState(() {
        _climbing = true;
        _wake++;
      });
      await _climbCtl.animateTo(0.42, duration: const Duration(milliseconds: 650));
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.95, muted: false));
      setState(() {
        _zapActive = true;
        _zapFrom = const Offset(PtwGeo.poleX, 160);
        _zapTo = const Offset(PtwGeo.poleX + 18, 300);
        _wake++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 550));
      final m = _run.answerPtw(stopWork: false);
      if (m != null) await _handleMistake(m);
      setState(() {
        _climbing = false;
        _zapActive = false;
        _climbCtl.value = 0;
      });
      _busy = false;
      return;
    }

    // Stopped work: refused oral shortcut
    final m = _run.answerPtw(stopWork: true);
    if (m == null) {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: false));
      final delta = _scored(20);
      _totalDelta += delta;
      _runScore += delta;
      await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: GuideMood.celebrate, muted: _muted);
      await _say('খাঁটি সিদ্ধান্ত! লিখিত PTW ছাড়া লাইনে কোনো কাজ নয়।', mood: GuideMood.celebrate);
      _run.advanceStation();
      _triggerBloom();
      _busy = false;
      await _enterStation();
      return;
    }
    await _handleMistake(m);
  }

  Future<void> _onPoleOrbit() async {
    if (_busy || _ended || _card != null || _climbing) return;
    HapticFeedback.selectionClick();
    setState(() {
      _poleOrbit = (_poleOrbit + 0.5) % 1.0;
      _run.poleWalked = true;
      _wake++;
    });
  }

Future<void> _onPoleKnock() async {
    if (_busy || _ended || _card != null || _climbing) return;
    HapticFeedback.mediumImpact();
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/learn/knock_solid.wav', volume: 0.85, muted: false));
    }
    setState(() {
      _run.poleKnocked = true;
      _poleSoundWord = GateLines.knockSolidWord;
      _hammerSwing = true;
      _wake++;
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _poleSoundWord = null;
          _hammerSwing = false;
        });
      }
    });
  }

  Future<void> _onDecidePole(bool climb, Offset origin) async {
    if (_busy || _ended || _card != null || reasonOpen || _climbing) return;
    _busy = true;
    _hush();

    if (climb) {
      setState(() {
        _climbing = true;
        _wake++;
      });
      final m = _run.decidePole(climb: true);
      if (m != null) {
        // Bad / uninspected pole: starts climbing, pole tilts & cracks!
        await _climbCtl.animateTo(0.45, duration: const Duration(milliseconds: 700));
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.9, muted: false));
        setState(() {
          _poleTilted = true;
          _wake++;
        });
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await _handleMistake(m);
        setState(() {
          _climbing = false;
          _poleTilted = false;
          _climbCtl.value = 0;
        });
        _busy = false;
        return;
      }

      // Solid inspected pole: climbs to the top!
      await _climbCtl.animateTo(1.0, duration: const Duration(milliseconds: 1100));
      setState(() {
        _verdictClimbed = true;
        _wake++;
      });
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: false));
      final delta = _scored(20);
      _totalDelta += delta;
      _runScore += delta;
      await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: GuideMood.celebrate, muted: _muted);
      putOnTable(delta);
      await askReason(
        deal: () => dealChoices(GateLines.whyPoleRight, GateLines.whyPoleWrong, math.Random(widget.seed + 3)),
        question: 'কেন এই পোলে ওঠার সিদ্ধান্ত নিলেন?',
        stillValid: () => mounted && !_ended,
      );
      setState(() {
        _climbing = false;
        _verdictClimbed = false;
        _climbCtl.value = 0;
      });
      _busy = false;
    } else {
      // Reported defect
      final m = _run.decidePole(climb: false);
      if (m == null) {
        final delta = _scored(20);
        _totalDelta += delta;
        _runScore += delta;
        await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: GuideMood.celebrate, muted: _muted);
        putOnTable(delta);
        await askReason(
          deal: () => dealChoices(GateLines.whyPoleRight, GateLines.whyPoleWrong, math.Random(widget.seed + 3)),
          question: 'কেন ত্রুটি রিপোর্ট করলেন?',
          stillValid: () => mounted && !_ended,
        );
      } else {
        await _handleMistake(m);
      }
      _busy = false;
    }
  }

  Future<void> _onDischargeElement(String id, Offset origin) async {
    if (_busy || _ended || _card != null || reasonOpen) return;
    _hush();

    if (id == 'earth') {
      _run.touchDischargeElement('earth');
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.8, muted: false));
      setState(() {
        _earthClamped = true;
        _wake++;
      });
      return;
    }

    // Touching line phase (R, Y, B):
    if (!_run.earthClamped) {
      // Deadly accident: line before earth!
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.95, muted: false));
      setState(() {
        _zapActive = true;
        _zapFrom = origin;
        _zapTo = const Offset(PoleGeo.cx - 20, 360);
        _wake++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final m = _run.touchDischargeElement(id);
      if (m != null) await _handleMistake(m);
      setState(() => _zapActive = false);
      return;
    }

    // Safely earthed: spark crackles!
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.85, muted: false));
    setState(() {
      _sparkAt = origin;
      _sparkActive = true;
      _wake++;
    });
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _sparkActive = false);
    });

    final m = _run.touchDischargeElement(id);
    if (m == null && _run.phasesTouched.length == 3) {
      _busy = true;
      final delta = _scored(20);
      _totalDelta += delta;
      _runScore += delta;
      await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: GuideMood.celebrate, muted: _muted);
      putOnTable(delta);
      await askReason(
        deal: () => dealChoices(GateLines.whyDischargeRight, GateLines.whyDischargeWrong, math.Random(widget.seed + 4)),
        question: 'কেন মাটিতে আগে আর্থ ক্ল্যাম্প সংযোগ করলেন?',
        stillValid: () => mounted && !_ended,
      );
      _busy = false;
    }
  }

  Future<void> _onChooseShelter(bool vanChosen, Offset origin) async {
    if (_busy || _ended || _card != null || reasonOpen) return;
    _busy = true;
    _hush();

    if (!vanChosen) {
      // Lightning strikes tree or pole!
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/learn/thunder_near.wav', volume: 0.95, muted: false));
        unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.85, muted: false));
      }
      setState(() {
        _lightningActive = true;
        _lightningTarget = origin;
        _thunderFlash = true;
        _wake++;
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final m = _run.chooseShelter(vanChosen: false);
      if (m != null) await _handleMistake(m);
      setState(() {
        _lightningActive = false;
        _thunderFlash = false;
      });
      _busy = false;
      return;
    }

    // Van chosen! Safe inside Faraday cage
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: false));
    final delta = _scored(20);
    _totalDelta += delta;
    _runScore += delta;
    await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: GuideMood.celebrate, muted: _muted);
    putOnTable(delta);
    await askReason(
      deal: () => dealChoices(GateLines.whyStormRight, GateLines.whyStormWrong, math.Random(widget.seed + 5)),
      question: 'কেন গাড়িতে নিরাপদ আশ্রয় নিলেন?',
      stillValid: () => mounted && !_ended,
    );
    _busy = false;
  }

  Future<void> _onClimbStormLadder(Offset origin) async {
    if (_busy || _ended || _card != null || reasonOpen || _climbing) return;
    _busy = true;
    _hush();

    setState(() {
      _climbing = true;
      _wake++;
    });

    if (!_muted) unawaited(ZlFx.cue('sounds/learn/wind_gust.wav', volume: 0.9, muted: false));
    await _climbCtl.animateTo(0.48, duration: const Duration(milliseconds: 700));

    // Sudden gust & foot slip
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.95, muted: false));
      unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.8, muted: false));
    }
    HapticFeedback.heavyImpact();

    setState(() {
      _ladderWobble = 1.0;
      _fallArrested = true;
      _wake++;
    });

    await Future<void>.delayed(const Duration(milliseconds: 750));

    final m = GateMistakes.stormLadderSlip;
    _run.deadly = m;
    await _handleMistake(m);

    setState(() {
      _climbing = false;
      _ladderWobble = 0.0;
      _fallArrested = false;
      _climbCtl.value = 0;
    });
    _busy = false;
  }

  Future<void> _onTouchConductorInStorm(Offset origin) async {
    if (_busy || _ended || _card != null || reasonOpen) return;
    _busy = true;
    _hush();

    // Distant lightning induces tens of thousands of volts on the de-energized conductor!
    if (!_muted) {
      unawaited(ZlFx.cue('sounds/learn/thunder_near.wav', volume: 0.95, muted: false));
      unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.95, muted: false));
    }
    HapticFeedback.heavyImpact();

    setState(() {
      _thunderFlash = true;
      _zapActive = true;
      _zapFrom = origin;
      _zapTo = const Offset(195, 280);
      _wake++;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));

    final m = GateMistakes.lightningBackfeed;
    _run.deadly = m;
    await _handleMistake(m);

    setState(() {
      _thunderFlash = false;
      _zapActive = false;
    });
    _busy = false;
  }

  Future<void> _handleMistake(DoMistake m) async {
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.75, muted: false));
    _combo.miss();

    if (m.deadly) {
      final frozen = _frozen = Completer<void>();
      setState(() => _freeze = true);
      final outcome = await bookDeadly(m, runScore: _runScore);
      await frozen.future;
      if (!mounted) return;
      setState(() {
        _freeze = false;
        _card = m;
        _cardTone = outcome == DeadlyOutcome.nearMiss ? MistakeTone.nearMiss : MistakeTone.deadly;
        _busy = false;
      });
    } else {
      final out = strike(m);
      setState(() {
        _card = m;
        _cardTone = MistakeTone.slip;
        _busy = false;
      });
      if (out) {
        unawaited(recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore));
      }
    }
  }

  // --- ReasonTable hooks -----------------------------------------------------
  @override
  bool get reasonMuted => _muted;

  @override
  bool get reasonEnded => _ended;

  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);

  @override
  void reasonHush() => _hush();

  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) async {
    _totalDelta += delta;
    _runScore += delta;
    await BeatFx.levelDelta(ref, delta, originGlobal: origin, mood: mood, muted: _muted);
  }

  @override
  void onReasonPaid() {
    _run.advanceStation();
    _triggerBloom();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: false));
    if (_run.done) {
      unawaited(_finish());
    } else {
      unawaited(_enterStation());
    }
  }

  Future<void> _finish() async {
    _clock.stop();
    final ms = _clock.elapsedMilliseconds;
    final mark = _run.percent;
    final passed = _run.passed;
    final quick = passed && ms <= widget.pack.quickMs && _run.slips == 0;
    final stars = starsFor(passed: passed, strikes: _run.slips, quick: quick);

    final save = ref.read(gameSaveProvider.notifier);
    await save.recordLevelResult(widget.ctx.rungId, mark);
    await save.commitLevelScore(widget.ctx.rungId, _runScore);
    if (passed) {
      await save.markRungCleared(widget.ctx.rungId);
      await save.unlockRank(1); // Promotes to Trainee (Rank 1)!
    }

    setState(() {
      _ended = true;
      _mark = mark;
      _stars = stars;
      _quickBonus = quick;
    });

    if (passed) {
      if (!_muted) unawaited(ZlFx.cue('sounds/level_done.wav', volume: 0.85, muted: false));
      await _say(GateLines.allSet, mood: GuideMood.celebrate);
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/level_fail.wav', volume: 0.7, muted: false));
      await _say(GateLines.fail, mood: GuideMood.warn);
    }
  }

  // --- CoworkerMoment hooks --------------------------------------------------
  @override
  CoworkerScript get coworkerScript => GateLines.coworker;

  @override
  math.Random get coworkerRng => math.Random(widget.seed);

  @override
  bool get coworkerMuted => _muted;

  @override
  bool? coworkerCanCome() {
    if (_ended || _intro || _card != null || reasonOpen || _run.station != GateStation.storm) {
      return null;
    }
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);

  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (held) {
      _run.tag('সহকর্মীর চাপে "না" বলা');
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.7, muted: false));
      setState(() => _wake++);
      await _say('ঝড় শুরু হয়ে গেছে! দ্রুত নিরাপদ আশ্রয়ে যান!', mood: GuideMood.warn);
    } else {
      await _handleMistake(GateMistakes.stormClimb);
    }
  }

  // --- Dismiss & Leave -------------------------------------------------------
  void _dismissCard() {
    if (_card == null) return;
    final tone = _cardTone;
    setState(() => _card = null);
    if (tone == MistakeTone.deadly) {
      unawaited(dieAndLeave());
    } else if (tone == MistakeTone.nearMiss) {
      widget.onRetry(_muted);
    } else {
      if (struckOut) {
        widget.onRetry(_muted);
      }
    }
  }

  Future<void> _leave() async {
    _hush();
    if (deathPending) {
      await dieAndLeave();
      return;
    }
    if (_runScore > 0 && !_ended) {
      final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
      if (leave != true || !mounted) return;
    }
    _popOnce(false);
  }

  void _popOnce(bool passed) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(passed);
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final taskLine = switch (_run.station) {
      GateStation.van => GateLines.askVan,
      GateStation.ptw => GateLines.askPtw,
      GateStation.pole => GateLines.askPole,
      GateStation.discharge => GateLines.askDischarge,
      GateStation.storm => GateLines.askStorm,
    };
    ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.talk, line: taskLine);
    unawaited(MascotSpeechLibrary.speak(taskLine, muted: _muted));
  }

  static Rect traineeClimbBox(PoleGeo geo, double progress) {
    final h = 1.85 * geo.ppm;
    final w = h / 2;
    final startY = geo.groundY - h;
    final targetY = geo.y(7.2) - h;
    final y = startY + (targetY - startY) * progress;
    return Rect.fromLTWH(PoleGeo.cx - w / 2, y, w, h);
  }

  static Rect traineeGroundBox(PoleGeo geo) {
    final h = 1.90 * geo.ppm;
    final w = h / 2;
    return Rect.fromLTWH(PoleGeo.cx - 52, geo.groundY - h, w, h);
  }

  // --- Visual Scene Builders per Station -------------------------------------
  List<Widget> _buildStationLayers(BuildContext context, SceneMetrics m) {
    final quiet = _quiet;

    switch (_run.station) {
      case GateStation.van:
        final geo = RodVanGeo(m.height);
        return [
          Positioned.fill(
            key: const ValueKey('van-back'),
            child: RepaintBoundary(child: CustomPaint(painter: RodVanPainter(geo))),
          ),
          Positioned.fill(
            key: const ValueKey('van-rods'),
            child: RepaintBoundary(child: CustomPaint(painter: _VanRackPainter(geo: geo, selected: _selectedRod))),
          ),
          // Lineman by the van
          Positioned.fromRect(
            key: const ValueKey('van-trainee'),
            rect: geo.trainee,
            child: LinemanFigure(
              look: LinemanLook.trainee,
              mode: _selectedRod == null ? LinemanMode.idle : LinemanMode.hold,
              wake: _wake,
              quiet: quiet,
            ),
          ),
          // Tappable slots over the 4 rods in the van rack
          for (var i = 0; i < 4; i++)
            Positioned.fromRect(
              key: ValueKey('slot-$i'),
              rect: geo.slot(i, 4).inflate(8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => unawaited(
                  _onChooseRod(
                    const [RodChoice.kv11Ok, RodChoice.kv33High, RodChoice.pvcJugaad, RodChoice.crackedStick][i],
                    d.globalPosition,
                  ),
                ),
              ),
            ),
        ];

      case GateStation.ptw:
        final geo = PtwGeo.forScene(m.height, m.inset);
        final climbBox = traineeClimbBox(geo.pole, _climbCtl.value);
        return [
          Positioned.fill(
            key: const ValueKey('ptw-bg'),
            child: RepaintBoundary(child: CustomPaint(painter: PtwSitePainter(geo: geo))),
          ),
          Positioned.fill(
            key: const ValueKey('ptw-ladder'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _LadderPainter(
                  baseX: PtwGeo.poleX - 44,
                  baseY: geo.groundY,
                  topX: PtwGeo.poleX - 8,
                  topY: geo.pole.y(7.2),
                ),
              ),
            ),
          ),
          Positioned.fill(
            key: const ValueKey('ptw-lines'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _OverheadLinesPainter(
                  geo: geo.pole,
                  phaseFault: true,
                ),
              ),
            ),
          ),
          // Lineman standing / climbing
          Positioned.fromRect(
            key: const ValueKey('ptw-trainee'),
            rect: _climbing ? climbBox : geo.traineeRect,
            child: LinemanFigure(
              look: LinemanLook.trainee,
              mode: _climbing ? LinemanMode.walk : LinemanMode.hold,
              wake: _wake,
              quiet: quiet,
            ),
          ),
          // Ringing phone on van bonnet
          Positioned.fromRect(
            key: const ValueKey('ptw-phone'),
            rect: geo.phoneRect.inflate(14),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => unawaited(_onAnswerPtw(true, d.globalPosition)),
              child: _RingingPhoneWidget(quiet: quiet),
            ),
          ),
          // Tapping the pole ladder to climb (unsafe without written PTW)
          if (!_climbing)
            Positioned(
              left: PtwGeo.poleX - 48,
              top: geo.pole.y(7.2),
              width: 50,
              height: geo.groundY - geo.pole.y(7.2),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => unawaited(_onAnswerPtw(false, d.globalPosition)),
              ),
            ),
          // Arc flash if climbed without PTW
          if (_zapActive && _zapFrom != null && _zapTo != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ZapPainter(from: _zapFrom!, to: _zapTo!, flash: 1.0),
                ),
              ),
            ),
        ];

      case GateStation.pole:
        final geo = PoleGeo.forScene(m.height, m.inset);
        const pccCase = PoleCase(
          id: 'pcc_gate',
          kind: PoleKind.pcc,
          flaws: [
            PoleFlaw(PoleDefect.hairline, PoleSide.back),
          ],
        );
        final tb = _climbing ? traineeClimbBox(geo, _climbCtl.value) : traineeGroundBox(geo);
        return [
          Positioned.fill(
            key: const ValueKey('pole-bg'),
            child: RepaintBoundary(child: CustomPaint(painter: PoleYardPainter(geo: geo, orbit: _poleOrbit))),
          ),
          Positioned.fill(
            key: const ValueKey('pole-ladder'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _LadderPainter(
                  baseX: PoleGeo.cx - 52,
                  baseY: geo.groundY,
                  topX: PoleGeo.cx - 8,
                  topY: geo.y(7.2),
                ),
              ),
            ),
          ),
          Positioned.fill(
            key: ValueKey('pole-pnt-$_poleOrbit'),
            child: Transform.rotate(
              angle: _poleTilted ? 0.16 : 0.0,
              origin: Offset(PoleGeo.cx, geo.groundY),
              child: CustomPaint(painter: PolePainter(pole: pccCase, geo: geo, orbit: _poleOrbit)),
            ),
          ),
          Positioned.fill(
            key: const ValueKey('pole-lines'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _OverheadLinesPainter(
                  geo: geo,
                  phaseFault: true,
                ),
              ),
            ),
          ),
          // 360 Drag detector across the scene
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) {
                if (_climbing || _busy) return;
                setState(() {
                  _poleOrbit = (_poleOrbit - d.delta.dx / 260.0) % 1.0;
                  if (_poleOrbit < 0) _poleOrbit += 1.0;
                  _run.poleWalked = true;
                  _wake++;
                });
              },
            ),
          ),
          // 360 inspection badge
          if (_run.poleWalked)
            Positioned(
              left: PoleGeo.cx + 24,
              top: geo.y(4.5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SlmColors.navy900.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SlmColors.gold400, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: SlmColors.gold300),
                    const SizedBox(width: 4),
                    Text('৩৬০° নিরীক্ষা ✓', style: bangla(fontSize: 10, fontWeight: FontWeight.bold, color: SlmColors.gold300)),
                  ],
                ),
              ),
            ),
          // Lineman on ground or climbing
          Positioned.fromRect(
            key: const ValueKey('pole-trainee'),
            rect: tb,
            child: Transform.rotate(
              angle: _poleTilted ? 0.16 : 0.0,
              origin: Offset(tb.width / 2, tb.height),
              child: LinemanFigure(
                look: LinemanLook.trainee,
                mode: _climbing ? LinemanMode.walk : (_verdictClimbed ? LinemanMode.cheer : LinemanMode.hold),
                wake: _wake,
                quiet: quiet,
              ),
            ),
          ),
          // Hammer swing animation
          if (_hammerSwing)
            Positioned(
              left: tb.right - 14,
              top: tb.top + 28,
              width: 50,
              height: 50,
              child: IgnorePointer(child: _HammerSwingWidget(quiet: quiet)),
            ),
          // Acoustic word ripple popup
          if (_poleSoundWord != null)
            Positioned(
              left: PoleGeo.cx + 20,
              top: geo.y(1.8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: SlmColors.gold400,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12)],
                ),
                child: Text(_poleSoundWord!, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black)),
              ),
            ),
          // Direct tap on the pole ladder to climb
          if (!_climbing)
            Positioned(
              left: PoleGeo.cx - 52,
              top: geo.y(6.0),
              width: 60,
              height: geo.groundY - geo.y(6.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => unawaited(_onDecidePole(true, d.globalPosition)),
              ),
            ),
        ];

      case GateStation.discharge:
        final geo = PoleGeo.forScene(m.height, m.inset);
        const pccCase = PoleCase(
          id: 'pcc_gate',
          kind: PoleKind.pcc,
          flaws: [],
        );
        final tb = Rect.fromLTWH(PoleGeo.cx - 52, geo.groundY - 1.90 * geo.ppm, 0.95 * geo.ppm, 1.90 * geo.ppm);
        final spikePos = Offset(PoleGeo.cx - 96, geo.groundY - 14);
        final rPos = Offset(PoleGeo.cx - 56, geo.y(8.3));
        final yPos = Offset(PoleGeo.cx, geo.y(8.8));
        final bPos = Offset(PoleGeo.cx + 56, geo.y(8.3));
        return [
          Positioned.fill(
            key: const ValueKey('discharge-bg'),
            child: RepaintBoundary(child: CustomPaint(painter: PoleYardPainter(geo: geo, orbit: 0.15))),
          ),
          Positioned.fill(
            key: const ValueKey('discharge-pole'),
            child: RepaintBoundary(child: CustomPaint(painter: PolePainter(pole: pccCase, geo: geo, orbit: 0.15))),
          ),
          Positioned.fill(
            key: const ValueKey('discharge-ladder'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _LadderPainter(
                  baseX: PoleGeo.cx - 52,
                  baseY: geo.groundY,
                  topX: PoleGeo.cx - 8,
                  topY: geo.y(7.2),
                ),
              ),
            ),
          ),
          Positioned.fill(
            key: const ValueKey('discharge-lines'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _OverheadLinesPainter(
                  geo: geo,
                  phaseFault: true,
                  groundLeadClamped: _earthClamped,
                  groundLeadTo: Offset(PoleGeo.cx - 36, geo.groundY - 100),
                  dischargedPhases: _run.phasesTouched,
                ),
              ),
            ),
          ),
          // Lineman holding rod
          Positioned.fromRect(
            key: const ValueKey('discharge-trainee'),
            rect: tb,
            child: LinemanFigure(
              look: LinemanLook.trainee,
              mode: LinemanMode.hold,
              wake: _wake,
              quiet: quiet,
            ),
          ),
          // Ground Spike in Earth
          Positioned(
            left: spikePos.dx - 22,
            top: spikePos.dy - 24,
            width: 44,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => unawaited(_onDischargeElement('earth', d.globalPosition)),
              child: _EarthSpikeWidget(clamped: _earthClamped),
            ),
          ),
          // 3 Phase Jumpers (R, Y, B) on Crossarm
          for (final (id, pos, col) in [
            ('R', rPos, const Color(0xFFE53935)),
            ('Y', yPos, const Color(0xFFFDD835)),
            ('B', bPos, const Color(0xFF1E88E5)),
          ])
            Positioned(
              left: pos.dx - 22,
              top: pos.dy - 22,
              width: 44,
              height: 44,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => unawaited(_onDischargeElement(id, d.globalPosition)),
                child: _PhasePinWidget(label: id, color: col, done: _run.phasesTouched.contains(id)),
              ),
            ),
          // Blue Spark FX
          if (_sparkActive && _sparkAt != null)
            Positioned(
              left: _sparkAt!.dx - 40,
              top: _sparkAt!.dy - 40,
              width: 80,
              height: 80,
              child: IgnorePointer(child: CustomPaint(painter: _SparkPainter(0.5))),
            ),
          // Arc flash if touched before earth
          if (_zapActive && _zapFrom != null && _zapTo != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ZapPainter(from: _zapFrom!, to: _zapTo!, flash: 1.0),
                ),
              ),
            ),
        ];

      case GateStation.storm:
        final geo = SkyGeo.forScene(m.height, m.inset);
        final poleGeo = PoleGeo.forScene(m.height, m.inset);
        const pccCase = PoleCase(
          id: 'pcc_gate',
          kind: PoleKind.pcc,
          flaws: [],
        );
        final weather = SkyWeather(
          cloud: 0.95,
          dark: 0.78,
          rain: 0.65,
          wind: 65,
          bolt: SkyBolt.near,
        );
        final tb = _fallArrested
            ? Rect.fromLTWH(PoleGeo.cx - 65, poleGeo.groundY - 140, 52, 110)
            : Rect.fromLTWH(170, geo.groundY - 110, 52, 110);
        final vanRect = Rect.fromLTWH(16, geo.groundY - 76, 118, 76);
        final treeRect = Rect.fromLTWH(265, geo.groundY - 150, 90, 150);
        return [
          Positioned.fill(
            key: const ValueKey('sky-bg'),
            child: AwakeClock(
              wake: _wake,
              builder: (_, t) => RepaintBoundary(
                child: CustomPaint(
                  painter: SkyWorldPainter(
                    geo: geo,
                    weather: weather,
                    t: t,
                    flash: const AlwaysStoppedAnimation(0.0),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            key: const ValueKey('storm-pole'),
            child: RepaintBoundary(child: CustomPaint(painter: PolePainter(pole: pccCase, geo: poleGeo, orbit: 0.0))),
          ),
          Positioned.fill(
            key: const ValueKey('storm-ladder'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _LadderPainter(
                  baseX: PoleGeo.cx - 52,
                  baseY: geo.groundY,
                  topX: PoleGeo.cx - 8,
                  topY: poleGeo.y(7.2),
                  wobble: _ladderWobble,
                ),
              ),
            ),
          ),
          Positioned.fill(
            key: const ValueKey('storm-lines'),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _OverheadLinesPainter(
                  geo: poleGeo,
                  windSway: 1.0,
                  phaseFault: true,
                ),
              ),
            ),
          ),
          if (_thunderFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ),
          // Service Van (Faraday cage safe shelter)
          Positioned.fromRect(
            key: const ValueKey('storm-van'),
            rect: vanRect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => unawaited(_onChooseShelter(true, d.globalPosition)),
              child: _StormVanWidget(quiet: quiet),
            ),
          ),
          // Lone Tree (Dangerous step potential)
          Positioned.fromRect(
            key: const ValueKey('storm-tree'),
            rect: treeRect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => unawaited(_onChooseShelter(false, d.globalPosition)),
              child: _StormTreeWidget(quiet: quiet),
            ),
          ),
          // Pole ladder (Dangerous climb in storm - slip & fall hazard)
          Positioned(
            left: PoleGeo.cx - 58,
            top: poleGeo.y(7.2),
            width: 50,
            height: geo.groundY - poleGeo.y(7.2),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => unawaited(_onClimbStormLadder(d.globalPosition)),
            ),
          ),
          // Overhead Conductor touch in storm (Lightning induced voltage shock)
          Positioned(
            left: PoleGeo.cx - 65,
            top: poleGeo.y(8.8) - 15,
            width: 130,
            height: 35,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => unawaited(_onTouchConductorInStorm(d.globalPosition)),
            ),
          ),
          // Lineman
          Positioned.fromRect(
            key: const ValueKey('storm-trainee'),
            rect: tb,
            child: LinemanFigure(
              look: LinemanLook.trainee,
              mode: _climbing ? LinemanMode.walk : (_fallArrested ? LinemanMode.worried : LinemanMode.worried),
              wake: _wake,
              quiet: quiet,
            ),
          ),
          // Arc flash or lightning zap
          if (_zapActive && _zapFrom != null && _zapTo != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ZapPainter(from: _zapFrom!, to: _zapTo!, flash: 1.0),
                ),
              ),
            ),
          // Lightning strike FX
          if (_lightningActive && _lightningTarget != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LightningPainter(target: _lightningTarget!),
                ),
              ),
            ),
        ];
    }
  }

  // --- Main Build ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final playing = !_intro && _mark == null && !struckOut && _card == null;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && _card == null && !coworkerChoiceUp;

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
              labels: const ['১', '২', '৩', '৪', '৫'],
              done: {for (final s in _run.completed) s.index},
              current: _run.done ? null : _run.station.index,
              quiet: quiet,
            ),
            layers: (c, m) => [
              Positioned.fill(
                key: const ValueKey('scene'),
                child: ColorFiltered(
                  colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                  child: Stack(children: _buildStationLayers(c, m)),
                ),
              ),
            ],
            overlays: [
              // Deadly freeze: the scene greys out while the consequence plays.
              if (_freeze && _card == null)
                Positioned.fill(
                  child: FreezeFrame(
                    muted: _muted,
                    ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2200,
                    onDone: () {
                      final f = _frozen;
                      if (f != null && !f.isCompleted) f.complete();
                    },
                  ),
                ),

              // A station completed: the rescue bloom over the yard.
              if (_bloomActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RescueBurst(
                      key: ValueKey('bloom-$_bloomRound'),
                      muted: _muted,
                      cloud: false,
                    ),
                  ),
                ),

              if (_comboN > 0)
                Positioned(
                  top: pad.top + 92,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ComboPop(
                      key: ValueKey('combo-$_comboN'),
                      mult: _comboMult,
                    ),
                  ),
                ),

              ...tableLayers(at: Offset(size.width / 2, pad.top + 130), quiet: quiet),

              // Station Header Chip (Minimal, translucent & non-intrusive at top right)
              if (playing && _card == null)
                Positioned(
                  top: pad.top + 46,
                  right: 14,
                  child: _StationHeaderChip(
                    stationNum: 'স্টেশন ${_run.station.index + 1}/৫',
                    title: switch (_run.station) {
                      GateStation.van => 'স্টেশন ১ · ভ্যানে রড বাছাই',
                      GateStation.ptw => 'স্টেশন ২ · পারমিট ও ফিডার যাচাই',
                      GateStation.pole => 'স্টেশন ৩ · পোলের ৩৬০° ও শব্দ পরীক্ষা',
                      GateStation.discharge => 'স্টেশন ৪ · আগে মাটি, পরে লাইন',
                      GateStation.storm => 'স্টেশন ৫ · কালবৈশাখী ও সহকর্মীর চাপ',
                    },
                    onOpenDocket: () {
                      if (!_muted) unawaited(ZlFx.cue('sounds/learn/card_deal_a.wav', volume: 0.8, muted: false));
                      setState(() => _docketOpen = true);
                    },
                  ),
                ),

              // Station 2: Action buttons
              if (handsOn && _run.station == GateStation.ptw)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SimpleActionButton(
                          label: 'মৌখিক নির্দেশ বাতিল · কাজ বন্ধ',
                          isDanger: false,
                          onTapUp: (d) => unawaited(_onAnswerPtw(true, d.globalPosition)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DoBigButton(
                          label: 'পোলে উঠুন (Climb)',
                          filled: true,
                          onTapUp: (d) => unawaited(_onAnswerPtw(false, d.globalPosition)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Station 3: Tools & Climb
              if (handsOn && _run.station == GateStation.pole) ...[
                Positioned(
                  key: const ValueKey('hud-tools-station3'),
                  left: 14,
                  bottom: pad.bottom + 74,
                  child: Row(
                    children: [
                      _ToolButton(
                        icon: Icons.threesixty_rounded,
                        label: '৩৬০° ঘুরুন',
                        enabled: !_climbing,
                        onTap: _onPoleOrbit,
                      ),
                      const SizedBox(width: 10),
                      _ToolButton(
                        icon: Icons.hardware_rounded,
                        label: 'হাতুড়ি ঠুকুন',
                        enabled: !_climbing,
                        onTap: _onPoleKnock,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  key: const ValueKey('hud-decide-station3'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SimpleActionButton(
                          label: 'ত্রুটি রিপোর্ট করুন',
                          isDanger: false,
                          onTapUp: (d) => unawaited(_onDecidePole(false, d.globalPosition)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DoBigButton(
                          label: 'পোলে উঠুন (Climb)',
                          filled: true,
                          onTapUp: (d) => unawaited(_onDecidePole(true, d.globalPosition)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Bottom Choice / Reason Deck
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),

              // Mascot in corner
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : 72),
                  onLeft: coworkerFromRight,
                ),

              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),

              // Mistake Card
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () => unawaited(
                            openLessonPoint(
                              context,
                              ref,
                              lessonId: widget.ctx.lessonId,
                              point: _card!.lessonPoint,
                              muted: _muted,
                            ),
                          ),
                  onGo: _dismissCard,
                ),

              // 3 Strikes Out Card
              if (struckOut && _card == null)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy ?? GateMistakes.damagedRod,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),

              // Pass / Fail Panel
              if (_mark != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xE6050A16),
                    child: SafeArea(
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
                                  onRead: () => unawaited(
                                    openLessonPoint(
                                      context,
                                      ref,
                                      lessonId: widget.ctx.lessonId,
                                      point: 0,
                                      muted: _muted,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Intro Overlay
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: GateLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),

              // Interactive Docket Slip Modal
              if (_docketOpen)
                Positioned.fill(
                  key: const ValueKey('docket-modal'),
                  child: _DocketSheetModal(
                    onClose: () {
                      if (!_muted) unawaited(ZlFx.cue('sounds/learn/card_deal_a.wav', volume: 0.8, muted: false));
                      setState(() => _docketOpen = false);
                    },
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
// UI Helper Widgets & Visual Painters
// ============================================================================

class _StationHeaderChip extends StatelessWidget {
  const _StationHeaderChip({
    required this.stationNum,
    required this.title,
    required this.onOpenDocket,
  });

  final String stationNum;
  final String title;
  final VoidCallback onOpenDocket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE60A1324),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.65), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SlmColors.gold400.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stationNum,
              style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: SlmColors.gold300),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: SlmColors.ivory),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: Colors.white24),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenDocket,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_rounded, size: 14, color: SlmColors.gold300),
                const SizedBox(width: 4),
                Text(
                  'ডকেট DKT-11K',
                  style: bangla(fontSize: 11, fontWeight: FontWeight.bold, color: SlmColors.gold300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverheadLinesPainter extends CustomPainter {
  const _OverheadLinesPainter({
    required this.geo,
    this.windSway = 0.0,
    this.phaseFault = true,
    this.groundLeadClamped = false,
    this.groundLeadTo,
    this.dischargedPhases = const {},
  });

  final PoleGeo geo;
  final double windSway;
  final bool phaseFault;
  final bool groundLeadClamped;
  final Offset? groundLeadTo;
  final Set<String> dischargedPhases;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = PoleGeo.cx;
    final rY = geo.y(8.3);
    final yY = geo.y(8.8);
    final bY = geo.y(8.3);

    final rPos = Offset(cx - 56, rY);
    final yPos = Offset(cx, yY);
    final bPos = Offset(cx + 56, bY);

    final wirePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final sagR = 12.0 + windSway * 4;
    final sagB = 12.0 + windSway * 4;

    // Phase R
    final pathRLeft = Path()
      ..moveTo(-40, rY - 6)
      ..quadraticBezierTo((cx - 56 - 40) / 2, rY + sagR, rPos.dx, rPos.dy);
    final pathRRight = Path()
      ..moveTo(rPos.dx, rPos.dy)
      ..quadraticBezierTo((rPos.dx + size.width + 40) / 2, rY + sagR, size.width + 40, rY - 6);
    canvas.drawPath(pathRLeft, wirePaint);
    canvas.drawPath(pathRRight, wirePaint);

    // Phase B
    final pathBLeft = Path()
      ..moveTo(-40, bY - 6)
      ..quadraticBezierTo((cx + 56 - 40) / 2, bY + sagB, bPos.dx, bPos.dy);
    final pathBRight = Path()
      ..moveTo(bPos.dx, bPos.dy)
      ..quadraticBezierTo((bPos.dx + size.width + 40) / 2, bY + sagB, size.width + 40, bY - 6);
    canvas.drawPath(pathBLeft, wirePaint);
    canvas.drawPath(pathBRight, wirePaint);

    // Phase Y
    if (phaseFault) {
      final pathYLeft = Path()
        ..moveTo(-40, yY - 8)
        ..quadraticBezierTo((cx - 40) / 2, yY + 14, yPos.dx, yPos.dy);
      canvas.drawPath(pathYLeft, wirePaint);

      final dangle = Path()
        ..moveTo(yPos.dx, yPos.dy)
        ..quadraticBezierTo(
          yPos.dx + 12 + windSway * 18,
          yPos.dy + 65,
          yPos.dx + 4 + windSway * 28,
          yPos.dy + 110,
        );
      canvas.drawPath(dangle, wirePaint);

      canvas.drawCircle(
        Offset(yPos.dx + 4 + windSway * 28, yPos.dy + 110),
        2.5,
        Paint()..color = const Color(0xFFF39C12),
      );

      final pathYRight = Path()
        ..moveTo(cx + 80, yY + 70)
        ..quadraticBezierTo((cx + 80 + size.width + 40) / 2, yY + 28, size.width + 40, yY - 8);
      canvas.drawPath(pathYRight, wirePaint);
    } else {
      final pathYLeft = Path()
        ..moveTo(-40, yY - 8)
        ..quadraticBezierTo((cx - 40) / 2, yY + 14, yPos.dx, yPos.dy);
      final pathYRight = Path()
        ..moveTo(yPos.dx, yPos.dy)
        ..quadraticBezierTo((yPos.dx + size.width + 40) / 2, yY + 14, size.width + 40, yY - 8);
      canvas.drawPath(pathYLeft, wirePaint);
      canvas.drawPath(pathYRight, wirePaint);
    }

    if (groundLeadClamped) {
      final spikePos = Offset(cx - 96, geo.groundY - 14);
      final target = groundLeadTo ?? Offset(cx - 36, geo.groundY - 120);

      final leadPath = Path()
        ..moveTo(spikePos.dx, spikePos.dy)
        ..cubicTo(
          spikePos.dx - 20,
          (spikePos.dy + target.dy) / 2,
          target.dx - 30,
          (spikePos.dy + target.dy) / 2 + 30,
          target.dx,
          target.dy,
        );

      canvas.drawPath(
        leadPath,
        Paint()
          ..color = const Color(0x66000000)
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke,
      );

      canvas.drawPath(
        leadPath,
        Paint()
          ..color = const Color(0xFF2ECC71)
          ..strokeWidth = 3.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawPath(
        leadPath,
        Paint()
          ..color = const Color(0xFFF1C40F)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      for (final ph in dischargedPhases) {
        final pos = ph == 'R' ? rPos : (ph == 'Y' ? yPos : bPos);
        canvas.drawLine(
          pos,
          pos + const Offset(0, 18),
          Paint()
            ..color = const Color(0xFFF1C40F)
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(pos, 5.0, Paint()..color = const Color(0xFF2ECC71));
      }
    }
  }

  @override
  bool shouldRepaint(_OverheadLinesPainter old) =>
      old.windSway != windSway ||
      old.phaseFault != phaseFault ||
      old.groundLeadClamped != groundLeadClamped ||
      old.groundLeadTo != groundLeadTo ||
      old.dischargedPhases != dischargedPhases;
}

class _LadderPainter extends CustomPainter {
  const _LadderPainter({
    required this.baseX,
    required this.baseY,
    required this.topX,
    required this.topY,
    this.wobble = 0.0,
  });

  final double baseX;
  final double baseY;
  final double topX;
  final double topY;
  final double wobble;

  @override
  void paint(Canvas canvas, Size size) {
    final shiftX = wobble * 14.0;
    final b = Offset(baseX, baseY);
    final t = Offset(topX + shiftX, topY);

    final angle = math.atan2(t.dy - b.dy, t.dx - b.dx);
    final normal = Offset(-math.sin(angle), math.cos(angle)) * 14.0;

    final leftRailB = b - normal;
    final leftRailT = t - normal;
    final rightRailB = b + normal;
    final rightRailT = t + normal;

    final railPaint = Paint()
      ..color = const Color(0xFFBDC3C7)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;

    final railHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.6;

    canvas.drawLine(leftRailB, leftRailT, railPaint);
    canvas.drawLine(leftRailB, leftRailT, railHighlight);
    canvas.drawLine(rightRailB, rightRailT, railPaint);
    canvas.drawLine(rightRailB, rightRailT, railHighlight);

    final footPaint = Paint()..color = const Color(0xFF2C3E50);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: leftRailB + const Offset(0, 3), width: 10, height: 8), const Radius.circular(2)), footPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: rightRailB + const Offset(0, 3), width: 10, height: 8), const Radius.circular(2)), footPaint);

    final dist = (t - b).distance;
    final numRungs = (dist / 26).floor();
    final rungPaint = Paint()
      ..color = const Color(0xFF7F8C8D)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < numRungs; i++) {
      final f = i / numRungs;
      final lp = Offset.lerp(leftRailB, leftRailT, f)!;
      final rp = Offset.lerp(rightRailB, rightRailT, f)!;
      canvas.drawLine(lp, rp, rungPaint);
      canvas.drawLine(lp, rp, railHighlight);
    }
  }

  @override
  bool shouldRepaint(_LadderPainter old) =>
      old.baseX != baseX || old.baseY != baseY || old.topX != topX || old.topY != topY || old.wobble != wobble;
}

class _DocketSheetModal extends StatelessWidget {
  const _DocketSheetModal({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC4BBA5), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B3A57),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: SlmColors.gold300, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'পশ্চিমবঙ্গ রাজ্য বিদ্যুৎ বণ্টন সংস্থা',
                            style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            'জরুরি বিদ্যুৎ ফল্ট ডকেট (Field Fault Docket)',
                            style: bangla(fontSize: 10, fontWeight: FontWeight.w600, color: SlmColors.gold300),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),

              // Specs Table
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAE5D5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFB8AE96)),
                          ),
                          child: Text(
                            'ডকেট নং: DKT-11K-0842',
                            style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF2C3E50)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE53935)),
                          ),
                          child: Text(
                            'জরুরি মেরামত (SOS)',
                            style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFC62828)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFFD4CBBB), height: 1),
                    const SizedBox(height: 8),
                    const _DocketRow(
                      icon: Icons.bolt_rounded,
                      label: 'সাবস্টেশন ও ফিডার',
                      value: 'রামপুর ৩৩/১১ কেভি · রামপুর ১১ কেভি ফিডার',
                      color: Color(0xFFE65100),
                    ),
                    const _DocketRow(
                      icon: Icons.place_rounded,
                      label: 'সাইট লোকেশন',
                      value: 'পোল নং ৪২ (শিউলিতলা মোড়)',
                      color: Color(0xFF1565C0),
                    ),
                    const _DocketRow(
                      icon: Icons.warning_rounded,
                      label: 'ফল্ট বিবরণ',
                      value: '১১ কেভি কন্ডাক্টর জাম্পার ব্রেকডাউন ও স্পার্ক',
                      color: Color(0xFFC62828),
                    ),
                    const _DocketRow(
                      icon: Icons.handyman_rounded,
                      label: 'অনুমোদিত সরঞ্জাম',
                      value: '১১ কেভি সার্টিফাইড ডিসচার্জ রড (11 kV Only)',
                      color: Color(0xFF2E7D32),
                    ),
                    const _DocketRow(
                      icon: Icons.verified_user_rounded,
                      label: 'সুরক্ষা নির্দেশ',
                      value: 'কন্ট্রোল রুমের লিখিত স্বাক্ষরিত PTW ছাড়া লাইনে হাত নয়',
                      color: Color(0xFF6A1B9A),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
                      ),
                      child: Center(
                        child: Text(
                          '★ অনুমোদিত জরুরি ফিল্ড ডিউটি · সুরক্ষাবিধি মান্য করুন ★',
                          style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'ডকেট বুঝে নিলাম · কাজ শুরু করুন',
                          style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                        ),
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocketRow extends StatelessWidget {
  const _DocketRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: bangla(fontSize: 11.5, fontWeight: FontWeight.normal, color: const Color(0xFF2C3E50), height: 1.3),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(
                    color: enabled ? SlmColors.gold300.withValues(alpha: 0.9) : const Color(0xFF4A5568),
                    width: 1.6,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: enabled ? SlmColors.gold300 : const Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xCC0B1324),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: bangla(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: enabled ? SlmColors.ivory : const Color(0xFF718096),
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

class _SimpleActionButton extends StatelessWidget {
  const _SimpleActionButton({required this.label, required this.isDanger, required this.onTapUp});
  final String label;
  final bool isDanger;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1324),
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
            border: Border.all(
              color: isDanger ? SlmColors.danger : SlmColors.gold400,
              width: 1.8,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Custom Visual Elements
// ----------------------------------------------------------------------------

class _VanRackPainter extends CustomPainter {
  const _VanRackPainter({required this.geo, this.selected});
  final RodVanGeo geo;
  final RodChoice? selected;

  @override
  void paint(Canvas canvas, Size size) {
    const choices = [
      RodChoice.kv11Ok,
      RodChoice.kv33High,
      RodChoice.pvcJugaad,
      RodChoice.crackedStick,
    ];
    for (var i = 0; i < 4; i++) {
      final slot = geo.slot(i, 4);
      final choice = choices[i];
      if (selected == choice) continue;

      final cx = slot.center.dx;
      final top = slot.top + 10;
      final bottom = slot.bottom - 12;

      switch (choice) {
        case RodChoice.kv11Ok:
          // Tested 11 kV stick: yellow-orange fibreglass with brass chuck & hook
          canvas.drawLine(
            Offset(cx, top + 18),
            Offset(cx, bottom),
            Paint()
              ..color = const Color(0xFFE67E22)
              ..strokeWidth = 4.5
              ..strokeCap = StrokeCap.round,
          );
          // 11 kV certification label band
          canvas.drawLine(
            Offset(cx, top + 45),
            Offset(cx, top + 60),
            Paint()..color = Colors.white..strokeWidth = 5.5,
          );
          // Brass chuck & hook
          canvas.drawCircle(Offset(cx, top + 18), 3.5, Paint()..color = const Color(0xFFF1C40F));
          final hook = Path()
            ..moveTo(cx, top + 18)
            ..lineTo(cx + 6, top + 10)
            ..quadraticBezierTo(cx + 8, top + 2, cx, top + 2)
            ..quadraticBezierTo(cx - 8, top + 2, cx - 6, top + 8);
          canvas.drawPath(
            hook,
            Paint()
              ..color = const Color(0xFFD4AC0D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
          // Rubber grip handle at bottom
          canvas.drawLine(
            Offset(cx, bottom - 24),
            Offset(cx, bottom),
            Paint()..color = const Color(0xFF2C3E50)..strokeWidth = 6.0,
          );

        case RodChoice.kv33High:
          // Heavy 33 kV stick: thicker dark-red with wide rain skirts
          canvas.drawLine(
            Offset(cx, top + 12),
            Offset(cx, bottom),
            Paint()
              ..color = const Color(0xFF922B21)
              ..strokeWidth = 7.0
              ..strokeCap = StrokeCap.round,
          );
          // 2 rain skirts (sheds)
          for (final sy in [top + 40, top + 65]) {
            final skirt = Path()
              ..moveTo(cx - 10, sy + 6)
              ..lineTo(cx, sy)
              ..lineTo(cx + 10, sy + 6)
              ..close();
            canvas.drawPath(skirt, Paint()..color = const Color(0xFF641E16));
          }
          canvas.drawCircle(Offset(cx, top + 12), 4.5, Paint()..color = const Color(0xFFBDC3C7));

        case RodChoice.pvcJugaad:
          // PVC pipe jugaad: white-grey plastic pipe with bent rebar hook
          canvas.drawLine(
            Offset(cx, top + 20),
            Offset(cx, bottom),
            Paint()
              ..color = const Color(0xFFBDC3C7)
              ..strokeWidth = 6.2
              ..strokeCap = StrokeCap.square,
          );
          // Pipe coupling joint
          canvas.drawRect(
            Rect.fromCenter(center: Offset(cx, top + 70), width: 9, height: 12),
            Paint()..color = const Color(0xFF95A5A6),
          );
          // Bent rusty rebar hook
          final jugaadHook = Path()
            ..moveTo(cx, top + 20)
            ..lineTo(cx + 8, top + 8)
            ..lineTo(cx + 3, top)
            ..lineTo(cx - 5, top + 4);
          canvas.drawPath(
            jugaadHook,
            Paint()
              ..color = const Color(0xFF7F8C8D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.8,
          );
          // Black electrical tape wrapped around base of hook
          canvas.drawRect(
            Rect.fromCenter(center: Offset(cx, top + 22), width: 8, height: 10),
            Paint()..color = Colors.black87,
          );

        case RodChoice.crackedStick:
          // Cracked 11 kV stick: yellow with jagged black fracture
          canvas.drawLine(
            Offset(cx, top + 18),
            Offset(cx, bottom),
            Paint()
              ..color = const Color(0xFFF39C12)
              ..strokeWidth = 4.5
              ..strokeCap = StrokeCap.round,
          );
          // Jagged dark fracture
          final crack = Path()
            ..moveTo(cx - 3, top + 70)
            ..lineTo(cx + 3, top + 74)
            ..lineTo(cx - 2, top + 78)
            ..lineTo(cx + 4, top + 82);
          canvas.drawPath(
            crack,
            Paint()
              ..color = const Color(0xFF17202A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2,
          );
          canvas.drawCircle(Offset(cx, top + 18), 3.5, Paint()..color = const Color(0xFFF1C40F));
      }
    }
  }

  @override
  bool shouldRepaint(_VanRackPainter old) => old.selected != selected;
}

class _RingingPhoneWidget extends StatelessWidget {
  const _RingingPhoneWidget({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF1E272E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SlmColors.warning, width: 1.6),
        boxShadow: const [
          BoxShadow(color: Color(0x99FFB300), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.phone_in_talk_rounded, color: SlmColors.warning, size: 20),
        ],
      ),
    );
  }
}

class _HammerSwingWidget extends StatelessWidget {
  const _HammerSwingWidget({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.38,
      child: const Icon(Icons.hardware_rounded, size: 38, color: SlmColors.gold300),
    );
  }
}

class _EarthSpikeWidget extends StatelessWidget {
  const _EarthSpikeWidget({required this.clamped});
  final bool clamped;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 38,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF4A3525),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        Positioned(
          bottom: 4,
          child: Container(
            width: 7,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFD35400),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          top: 6,
          child: Container(
            width: 18,
            height: 14,
            decoration: BoxDecoration(
              color: clamped ? SlmColors.success : const Color(0xFFF39C12),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white, width: clamped ? 1.5 : 0.8),
            ),
            child: Icon(
              clamped ? Icons.check_rounded : Icons.link_rounded,
              size: 11,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhasePinWidget extends StatelessWidget {
  const _PhasePinWidget({required this.label, required this.color, required this.done});
  final String label;
  final Color color;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? SlmColors.success : color,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              if (!done) BoxShadow(color: color.withValues(alpha: 0.65), blurRadius: 8),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            done ? '✓' : label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ),
        const SizedBox(height: 2),
        Container(width: 4, height: 12, color: const Color(0xFFBDC3C7)),
      ],
    );
  }
}

class _StormVanWidget extends StatelessWidget {
  const _StormVanWidget({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SlmColors.success, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car_rounded, color: SlmColors.success, size: 30),
          const SizedBox(height: 2),
          Text(
            'ভ্যানে আশ্রয় (নিরাপদ)',
            style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: SlmColors.ivory),
          ),
        ],
      ),
    );
  }
}

class _StormTreeWidget extends StatelessWidget {
  const _StormTreeWidget({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2A1E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SlmColors.danger, width: 1.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.park_rounded, color: SlmColors.danger, size: 38),
          const SizedBox(height: 2),
          Text(
            'একা গাছতলা (বিপজ্জনক)',
            style: bangla(fontSize: 9, fontWeight: FontWeight.w700, color: SlmColors.silver),
          ),
        ],
      ),
    );
  }
}

class _ZapPainter extends CustomPainter {
  _ZapPainter({required this.from, required this.to, required this.flash});
  final Offset from;
  final Offset to;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final arc = Path()..moveTo(from.dx, from.dy);
    const n = 6;
    for (var j = 1; j <= n; j++) {
      final p = Offset.lerp(from, to, j / n)!;
      final jitter = j == n ? 0.0 : (rnd.nextDouble() - 0.5) * 22;
      arc.lineTo(p.dx + jitter, p.dy + (rnd.nextDouble() - 0.5) * 8);
    }
    // Glow
    canvas.drawPath(
      arc,
      Paint()
        ..color = const Color(0xAA00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Core
    canvas.drawPath(
      arc,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ZapPainter old) => true;
}

class _LightningPainter extends CustomPainter {
  _LightningPainter({required this.target});
  final Offset target;

  @override
  void paint(Canvas canvas, Size size) {
    final top = Offset(target.dx + 35, 0);
    final rnd = math.Random(19);
    final arc = Path()..moveTo(top.dx, top.dy);
    const n = 8;
    for (var j = 1; j <= n; j++) {
      final p = Offset.lerp(top, target, j / n)!;
      final jitter = j == n ? 0.0 : (rnd.nextDouble() - 0.5) * 36;
      arc.lineTo(p.dx + jitter, p.dy);
    }
    canvas.drawPath(
      arc,
      Paint()
        ..color = const Color(0xDD80D8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      arc,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LightningPainter old) => true;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final fade = 1 - t;
    canvas.drawCircle(
      c,
      8 + 18 * t,
      Paint()
        ..color = Color.fromRGBO(0, 229, 255, 0.8 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final ray = Paint()
      ..color = Color.fromRGBO(255, 255, 255, fade)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (6 + 8 * t), c + d * (16 + 22 * t), ray);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}

