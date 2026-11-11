import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'order_steps.dart';
import 'pole_yard.dart' show PoleGeo, PoleYardPainter;
import 'reason_table.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 1.5, কাজ 2: "আগে মাটি, পরে লাইন". The permit is in hand and the
// 11 kV line is off — but a dead line can still hold charge. At the pole, with
// the hands: drag the rod's earth clamp onto a sound earth spike (one is
// rusty), drag the rod's hook up to R, Y and B (a spark and a crackle = the
// charge went to earth), then throw the shorting chain over the wires. Work
// done: take it off in reverse — the chain and the hook down, the earth last.
// Once, the careless coworker (level 1's rival, his recorded voice) peeps in:
// "লাইন তো 5 মিনিট বন্ধ, ডিসচার্জ লাগবে না".
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// drawn scene (the village roadside of lesson 1.3, seen from another side),
// corner guide, ◆ on the table → "কেন …?" (earth, the three phases, the
// chain, the earth last) → the play goes on by itself.
//
// Deadly (owner-approved list): hook on the line before the earth; chain in
// place of the rod (before the earth); skipping the discharge (listening to
// him). Slips: a rusty earth point; the chain before all three phases; the
// earth off first.
//
// Voice: the guide's lines use device TTS; the coworker speaks in his
// recorded voice. Art: drawn in code (the mistake cards keep their SVGs
// under assets/game/art/discharge/).

// ============================================================================
// Content
// ============================================================================

abstract final class DischargeLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askOn, askNext, askOff];

  static const title = 'আগে মাটি, পরে লাইন';
  static const intro = 'পারমিট হাতে, লাইন বন্ধ। কিন্তু ঘুমন্ত বাঘও বাঘ — রড দিয়ে লাইনটা সত্যিই নিরাপদ করুন!';
  static const rounds = ['লাগানো', 'খোলা'];
  static const askOn = 'ডিসচার্জ রড হাতে। কোনটা আগে?';
  static const askNext = 'এবার পরের ধাপ — কোনটা?';
  static const askOff = 'কাজ শেষ। এবার খুলুন — ঠিক ক্রমে।';

  /// The drag surface (screen readers only; nothing is written on the scene).
  static const sceneLabel = 'খুঁটির কাছে রড, ক্ল্যাম্প আর চেইন';

  /// Phase tags on the crossarm (what a lineman reads on the pole).
  static const phaseTag = {DischargeIds.r: 'R', DischargeIds.y: 'Y', DischargeIds.b: 'B'};

  static const spark = [
    FeedbackLine('চট্! চার্জ নামল।'),
    FeedbackLine('স্পার্ক — ভালো লক্ষণ।'),
    FeedbackLine('নামল!'),
    FeedbackLine('চট্!'),
  ];
  static const offStep = [FeedbackLine('নামল।'), FeedbackLine('ঠিক আছে।'), FeedbackLine('বেশ।')];
  static const onDone = 'লাইন এবার সত্যিই নিরাপদ। কাজ চলুক।';
  static const callHeld = 'ঠিক! চার্জ চোখে দেখা যায় না।';
  static const allSet = 'আগে মাটি, পরে লাইন — খোলার সময় উল্টো। দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট! মাঠে এভাবেই।';
  static const fail = 'আরেকবার — এবার ক্রমটা মনে রেখে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtEarth = 'আর্থ আগে';
  static const caughtPhases = 'R · Y · B ডিসচার্জ';
  static const caughtChain = 'চেইন রডের পরে';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const caughtOff = 'আর্থ সবার শেষে খোলা';

  // The reasons (lesson 1.5): one right, two wrong, all about the same length.
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const earthAsk = 'কেন আগে আর্থে ক্ল্যাম্প দিলেন?';
  static const earthRight = [
    'আগে মাটি, চার্জ শরীরে নয়, মাটিতে নামে',
    'উল্টো হলে চার্জ আমার শরীর দিয়ে নামত',
    'আগে আর্থ না দিলে আমিই সেতু হয়ে যেতাম',
  ];
  static const earthWrong = [
    'আগে আর্থ দিলে কাজটা একটু তাড়াতাড়ি হয়',
    'পারমিট আছে, ক্রম যা খুশি হলেও চলে',
    'ক্ল্যাম্পটা হাতের কাছে ছিল, তাই আগে',
    'আর্থ আগে দিলে পরে আর চেইন লাগে না',
    'নিয়মের খাতায় লেখা আছে, তাই দিয়েছি',
    'মাটিতে ক্ল্যাম্প থাকলে রড হালকা লাগে',
  ];
  static const phaseAsk = 'কেন তিনটে ফেজেই হুক ছোঁয়ালেন?';
  static const phaseRight = [
    'বন্ধ লাইনেও প্রতিটা তারে চার্জ থাকতে পারে',
    'তিনটে না নামানো পর্যন্ত লাইনটা লাইভ ধরি',
    'প্রতিটা ফেজ আলাদা, তিনটেই নিজে হাতে নামাই',
  ];
  static const phaseWrong = [
    'একটা ফেজ নামালেই বাকি দুটোও নেমে যায়',
    'লাইন 5 মিনিট বন্ধ, চার্জ থাকার কথা না',
    'পারমিট হাতে থাকলে চার্জের ভয় থাকে না',
    'স্পার্ক দেখতে ভালো লাগে, তাই ছোঁয়ালাম',
    'চেইন ছুড়লে এমনিতেই সব চার্জ নেমে যায়',
    'তিনটে ছোঁয়ানো শুধু অফিসের খাতার নিয়ম',
  ];
  static const chainAsk = 'কেন রডের পরে চেইন ছুড়লেন?';
  static const chainRight = [
    'রড চার্জ নামায়, চেইন শুধু ফেজ শর্ট রাখে',
    'শর্ট সার্কিট মানেই আর্থিং নয়, রড আগে',
    'চেইন রডের বদলি নয়, শুধু রডের সঙ্গী',
  ];
  static const chainWrong = [
    'চেইন থাকলে রড না দিলেও আসলে কাজ চলত',
    'চেইনটা ভারী, তাই সবার শেষে ছুড়েছি',
    'চেইন দিয়েই আসলে চার্জ মাটিতে নামে',
    'চেইন আগে দিলে স্পার্কটা দেখা যায় না',
    'লোহার যে কোনো চেইনেও একই কাজ হয়',
    'চেইন ছুড়লে লাইনে আর হাত দিতে হয় না',
  ];
  static const lastAsk = 'কেন আর্থ সবার শেষে খুললেন?';
  static const lastRight = [
    'হুক-চেইন নামা পর্যন্ত লাইন মাটিতে ধরা থাকে',
    'লাইন থেকে সব নামার আগে আর্থ খুলি না',
    'হুক লাইনে থাকতে আর্থ খুললে উল্টো ক্রম হয়',
  ];
  static const lastWrong = [
    'ক্ল্যাম্প খুলতে সবচেয়ে বেশি সময় লাগে',
    'কাজ শেষ, তাই এখন ক্রম মানার দরকার নেই',
    'আর্থ আগে খুললে চেইনটা নিচে পড়ে যেত',
    'মাটির ক্ল্যাম্প নোংরা, তাই শেষে ধরেছি',
    'লাইন তো এখনও বন্ধ, ক্রমে কিছু যায় না',
    'ক্ল্যাম্পটা নিচে ছিল, তাই শেষে হাত গেল',
  ];

  /// The careless coworker (his recorded voice) pushes the lesson's myth.
  static const coworkerLine = 'লাইন তো 5 মিনিট বন্ধ, ডিসচার্জ লাগবে না';
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: [
      'না, আগে তিনটে ফেজ ডিসচার্জ করব',
      'বন্ধ লাইনেও চার্জ থাকে, রড লাগাব',
      '5 মিনিট হোক, ডিসচার্জ ছাড়া নয়',
    ],
    wrong: [
      'ঠিক, 5 মিনিটে আর কী চার্জ জমবে',
      'পারমিট তো আছে, সরাসরি উঠে পড়ি',
      'লাইন ডেড, আজ আর রড লাগবে না',
      'একবার বাদ দিলে কিছুই হবে না',
      'ও পুরোনো লোক, ওর কথাই তো ঠিক',
    ],
    asks: [
      'ও বলছে ডিসচার্জ লাগবে না। আপনি কী করবেন?',
      'রড লাগাবেন, না সরাসরি উঠবেন?',
      'কার কথা শুনবেন — ওর, না নিয়মের?',
    ],
  );
}

abstract final class DischargeMistakes {
  static const lineBeforeEarth = DoMistake(
    key: '1.5/discharge/line-before-earth',
    textBn: 'আগে লাইনে হুক, পরে আর্থ — জমা চার্জ আপনার শরীর দিয়ে মাটিতে নামে। সবসময় আগে মাটি, পরে লাইন।',
    art: 'assets/game/art/discharge/wrong_right.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const chainInsteadOfRod = DoMistake(
    key: '1.5/discharge/chain-instead-of-rod',
    textBn: 'চেইন রডের বদলি নয় — চেইন শুধু ফেজ শর্ট করে, চার্জ মাটিতে নামায় না। আগে রড, পরে চেইন।',
    art: 'assets/game/art/discharge/chain_after_rod.svg',
    deadly: true,
    lessonPoint: 5,
  );
  static const skipDischarge = DoMistake(
    key: '1.5/discharge/skip-discharge',
    textBn: 'বন্ধ লাইনেও চার্জ জমে থাকে — 5 মিনিট হোক বা 5 ঘণ্টা, ডিসচার্জ না করে লাইনে হাত নয়।',
    art: 'assets/game/art/discharge/five_min.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const rustyEarth = DoMistake(
    key: '1.5/discharge/rusty-earth',
    textBn: 'মরিচা ধরা, ভাঙা আর্থে চার্জ ঠিকমতো নামে না। পরিষ্কার, মজবুত আর্থ পয়েন্টে ক্ল্যাম্প দিন।',
    art: 'assets/game/art/discharge/rusty_vs_clean.svg',
    lessonPoint: 1,
  );
  static const chainEarly = DoMistake(
    key: '1.5/discharge/chain-early',
    textBn: 'তিনটে ফেজ — R, Y, B — ডিসচার্জ শেষ করে তবেই চেইন ছুড়ুন।',
    art: 'assets/game/art/discharge/chain_after_rod.svg',
    lessonPoint: 5,
  );
  static const earthOffFirst = DoMistake(
    key: '1.5/discharge/earth-off-first',
    textBn: 'খোলার সময় আর্থ সবার শেষে — আগে চেইন আর হুক নামান, তারপর ক্ল্যাম্প।',
    art: 'assets/game/art/discharge/earth_last.svg',
    lessonPoint: 1,
  );
  static const all = [lineBeforeEarth, chainInsteadOfRod, skipDischarge, rustyEarth, chainEarly, earthOffFirst];
}

/// The pushers of the level before the kit (a phone call). Kept so the deal
/// stays the same play for play; the careless coworker now does the pushing.
const dischargeCallers = [
  DoCaller(
    id: 'jeo',
    whoBn: 'জেই, ফোনে',
    lineBn: 'লাইন তো 5 মিনিট আগে বন্ধ হয়েছে! ডিসচার্জ-টিসচার্জ ছাড়ো, তাড়াতাড়ি ওঠো।',
    icon: Icons.phone_in_talk_rounded,
  ),
  DoCaller(
    id: 'helper',
    whoBn: 'সাথী হেল্পার',
    lineBn: 'দাদা, পারমিট তো হাতে, লাইন ডেড। রড লাগিয়ে সময় নষ্ট কেন?',
    icon: Icons.engineering_rounded,
  ),
  DoCaller(
    id: 'consumer',
    whoBn: 'পাড়ার লোক',
    lineBn: 'দু’ঘণ্টা ধরে কারেন্ট নেই! এত দেরি করছেন কেন? তাড়াতাড়ি করুন!',
    icon: Icons.record_voice_over_rounded,
  ),
];

/// Ids of the steps.
abstract final class DischargeIds {
  static const earth = 'earth';
  static const rusty = 'rusty';
  static const r = 'R';
  static const y = 'Y';
  static const b = 'B';
  static const chain = 'chain';
  static const chainOff = 'chain-off';
  static const hookOff = 'hook-off';
  static const clampOff = 'clamp-off';
  static const phases = [r, y, b];
}

/// One play's variation: where the sound earth is, when the coworker comes,
/// and which side of the village the pole stands on.
@immutable
class DischargeDeal {
  const DischargeDeal({required this.goodLeft, required this.callAfter, required this.caller, this.view = 0.5});

  /// The sound earth spike is on the left (the rusty one on the right), or the other way.
  final bool goodLeft;

  /// Steps of round 1 done when the coworker comes (0 = soon after the
  /// player's first move; he always comes before the last phase counts).
  final int callAfter;

  /// Kept from the phone-call version (see [dischargeCallers]).
  final DoCaller caller;

  /// The village behind the pole (an orbit of the roadside panorama).
  final double view;
}

DischargeDeal dealDischarge(math.Random rng) => DischargeDeal(
      goodLeft: rng.nextBool(),
      callAfter: rng.nextInt(3),
      caller: dischargeCallers[rng.nextInt(dischargeCallers.length)],
      view: rng.nextDouble(),
    );

List<OrderRoundSpec> dischargeRounds() => const [
      OrderRoundSpec(
        groups: [
          OrderGroup(
            [DischargeIds.earth],
            skipMistake: DischargeMistakes.lineBeforeEarth,
            earlyBy: {DischargeIds.chain: DischargeMistakes.chainInsteadOfRod},
          ),
          OrderGroup(DischargeIds.phases, skipMistake: DischargeMistakes.chainEarly),
          OrderGroup([DischargeIds.chain], skipMistake: DischargeMistakes.chainEarly),
        ],
        traps: {DischargeIds.rusty: DischargeMistakes.rustyEarth},
      ),
      OrderRoundSpec(
        groups: [
          OrderGroup([DischargeIds.chainOff, DischargeIds.hookOff], skipMistake: DischargeMistakes.earthOffFirst),
          OrderGroup([DischargeIds.clampOff], skipMistake: DischargeMistakes.earthOffFirst),
        ],
      ),
    ];

@immutable
class DischargePack {
  const DischargePack({required this.id, required this.titleBn, this.quickMs = 45000});
  final String id;
  final String titleBn;

  /// A clean play under this time earns the quick bonus.
  final int quickMs;
}

const dischargePack15 = DischargePack(id: 'do_1_5_b', titleBn: DischargeLines.title);
const dischargePacks = {'do_1_5_b': dischargePack15};

// ============================================================================
// Scene geometry (design px, 360 wide × the scene's height)
// ============================================================================

/// Where things stand at the pole. Public so tests can aim their drags.
@immutable
class DischargeGeo {
  const DischargeGeo.forScene(this.height, double inset) : groundY = height - 212 - inset;

  final double height;

  /// Where the poles and the spikes enter the soil.
  final double groundY;

  static const poleX = 100.0;
  static const farX = 326.0;
  static const farScale = 0.9;
  static const traineeX = 242.0;

  /// The Y wire at the near pole (the highest).
  double get topY => math.max(140.0, groundY - 440);

  /// The near pole above the ground (to its top pin).
  double get len => groundY - topY;

  /// Spacing scale of the crossarm and insulators.
  double get sp => (len / 430).clamp(1.0, 1.12);

  double get farBaseY => groundY - 34;

  /// Where wire [p] sits on the near (or far) pole's insulator.
  Offset attach(String p, {bool far = false}) {
    final f = far ? farScale : 1.0;
    final x = far ? farX : poleX;
    final top = far ? farBaseY - f * len : topY;
    final k = sp * f;
    return switch (p) {
      DischargeIds.r => Offset(x - 40 * k, top + 38 * k),
      DischargeIds.b => Offset(x + 40 * k, top + 82 * k),
      _ => Offset(x, top),
    };
  }

  /// The wire's height at [x] (spans: from off screen left, between the
  /// poles, on to the right). Between the poles all three sag together, so
  /// they stay apart.
  double wireY(String p, double x) {
    final a = attach(p);
    final b = attach(p, far: true);
    if (x > a.dx && x <= b.dx) {
      final t = (x - a.dx) / (b.dx - a.dx);
      final u = ((x - poleX) / (farX - poleX)).clamp(0.0, 1.0);
      return a.dy + (b.dy - a.dy) * t + 4 * 16 * sp * u * (1 - u);
    }
    final (Offset s, Offset e, double sag) = x <= a.dx ? (Offset(-60, a.dy + 10), a, 12 * sp) : (b, Offset(b.dx + 120, b.dy - 6), 8 * sp);
    final t = ((x - s.dx) / (e.dx - s.dx)).clamp(0.0, 1.0);
    final c = (s.dy + e.dy) / 2 + 2 * sag;
    return (1 - t) * (1 - t) * s.dy + 2 * t * (1 - t) * c + t * t * e.dy;
  }

  /// The three spans of wire [p], as a path.
  Path wirePath(String p) {
    final a = attach(p);
    final b = attach(p, far: true);
    final path = Path()..moveTo(-60, a.dy + 10);
    for (var x = -56.0; x < a.dx; x += 4) {
      path.lineTo(x, wireY(p, x));
    }
    path.lineTo(a.dx, a.dy);
    for (var x = a.dx + 4; x < b.dx; x += 4) {
      path.lineTo(x, wireY(p, x));
    }
    path.lineTo(b.dx, b.dy);
    for (var x = b.dx + 4; x <= b.dx + 120; x += 4) {
      path.lineTo(x, wireY(p, x));
    }
    return path;
  }

  /// The wire nearest to [at] within reach of the hook, or null.
  String? wireNear(Offset at, {double tol = 15}) {
    if (at.dx < 6 || at.dx > 354) return null;
    String? best;
    var d = tol;
    for (final p in DischargeIds.phases) {
      final dy = (at.dy - wireY(p, at.dx)).abs();
      if (dy <= d) {
        d = dy;
        best = p;
      }
    }
    return best;
  }

  /// How far an earth spike stands out of the soil (to its terminal's top).
  static const spikeRise = 34.0;

  /// The two earth spikes (tops of their terminals).
  Offset get spikeLeft => Offset(34, groundY - spikeRise);
  Offset get spikeRight => Offset(158, groundY - spikeRise);
  Offset spike({required bool good, required bool goodLeft}) => good == goodLeft ? spikeLeft : spikeRight;

  /// The rod set on the ground: the earth clamp and the coiled chain.
  Offset get clampRest => Offset(202, groundY - 6);
  Offset get coilRest => Offset(300, groundY - 6);

  /// The trainee's box (feet on the ground) and the hands on the rod.
  Rect get traineeBox {
    final h = (1.8 * len / 9).clamp(64.0, 96.0);
    return Rect.fromLTWH(traineeX - h / 4, groundY - h + 2, h / 2, h);
  }

  Offset get hands {
    final box = traineeBox;
    final tip = LinemanFigure.tipOf(LinemanMode.hold, Carry.none, box.size);
    // He faces the pole (drawn mirrored).
    return Offset(box.right - tip.dx, box.top + tip.dy);
  }

  /// The hook held up, ready (half way between the hands and the wires).
  Offset get hookRest {
    final h = hands;
    final x = h.dx - 34;
    return Offset(x, h.dy - 0.5 * (h.dy - wireY(DischargeIds.b, x)));
  }

  /// The chain thrown over the wires at [x]: where its hanging end is.
  Offset chainGrab(double x) => Offset(x + 6, wireY(DischargeIds.b, x) + 34);

  /// The chain's x when thrown at [x] (kept between the poles).
  double chainSpot(double x) => x.clamp(poleX + 60, farX - 40);

  @override
  bool operator ==(Object other) => other is DischargeGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

// ============================================================================
// Page
// ============================================================================

class DischargeOrderPage extends StatefulWidget {
  const DischargeOrderPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final DischargePack pack;
  final bool muted;
  final int? seed;

  @override
  State<DischargeOrderPage> createState() => _DischargeOrderPageState();
}

class _DischargeOrderPageState extends State<DischargeOrderPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DischargeRun(
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

class _DischargeRun extends ConsumerStatefulWidget {
  const _DischargeRun({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final DischargePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DischargeRun> createState() => _DischargeRunState();
}

/// What the hands can pick up in the scene.
enum _Item { clamp, hook, chain }

/// Which deadly picture plays in colour over the frozen scene.
enum _Zap { hook, chain, bare }

@immutable
class _Drag {
  const _Drag(this.item, this.at);
  final _Item item;

  /// Where the item is now (design px).
  final Offset at;
}

class _DischargeRunState extends ConsumerState<_DischargeRun> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final DischargeDeal _deal = dealDischarge(widget.rng);
  final OrderRun _run = OrderRun(dischargeRounds());
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _sparkBag = LineBag(DischargeLines.spark);
  final _offBag = LineBag(DischargeLines.offStep);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;
  var _callHeld = false;

  // What the scene shows.
  var _clamped = false;
  String? _hookOn;
  double _hookX = 0;
  double? _chainX;
  final _drag = ValueNotifier<_Drag?>(null);
  Offset _grab = Offset.zero;
  Offset _lastGlobal = Offset.zero;
  int _moves = 0;
  int _sparks = 0;
  Offset? _sparkAt;
  int _pings = 0;
  Offset? _pingAt;
  int _wake = 0;
  var _cheer = false;
  _Zap? _zap;

  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  var _freeze = false;
  Completer<void>? _frozen;
  VoidCallback? _afterPaid;
  int? _mark;
  int _stars = 0;
  int _totalDelta = 0;

  /// The scene's geometry of the last build (for drags).
  DischargeGeo? _geo;

  String get _rungId => widget.ctx.rungId;

  @override
  LevelContext get deathCtx => widget.ctx;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _drag.dispose();
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

  String get _task => _run.round >= 1 ? DischargeLines.askOff : (_run.stepsDone == 0 ? DischargeLines.askOn : DischargeLines.askNext);

  // ---- flow -----------------------------------------------------------------------

  /// After the guide's intro: the clock runs and he gives the task.
  Future<void> _start() async {
    _clock.start();
    await _sayChain([DischargeLines.askOn]);
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || struckOut;

  Offset _hookPoint(DischargeGeo g) {
    final p = _hookOn;
    return p == null ? g.hookRest : Offset(_hookX, g.wireY(p, _hookX));
  }

  Offset get _goodSpike => _geo!.spike(good: true, goodLeft: _deal.goodLeft);

  /// What the hands can take now, and where it is.
  List<(_Item, Offset)> _grabs(DischargeGeo g) {
    if (_run.round == 0) {
      return [
        if (!_clamped) (_Item.clamp, g.clampRest),
        (_Item.hook, _hookPoint(g)),
        if (_chainX == null) (_Item.chain, g.coilRest),
      ];
    }
    return [
      if (_chainX != null) (_Item.chain, g.chainGrab(_chainX!)),
      if (_hookOn != null) (_Item.hook, _hookPoint(g)),
      if (_clamped) (_Item.clamp, _goodSpike.translate(0, 4)),
    ];
  }

  void _panStart(DragStartDetails d) {
    final g = _geo;
    if (g == null || _blocked || _run.ended || coworkerChoiceUp) return;
    final p = d.localPosition;
    _Item? item;
    var at = Offset.zero;
    var best = 38.0;
    for (final (i, o) in _grabs(g)) {
      final dist = (o - p).distance;
      if (dist < best) {
        best = dist;
        item = i;
        at = o;
      }
    }
    // The rod can be taken by its stick too.
    if (item == null) {
      final hook = _hookPoint(g);
      if (_distToSegment(p, hook, g.hands) < 18 && (_run.round == 0 || _hookOn != null)) {
        item = _Item.hook;
        at = hook;
      }
    }
    if (item == null) return;
    // Going on with the work while he is still talking refuses him.
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, d.globalPosition, direct: true));
    HapticFeedback.selectionClick();
    _grab = at - p;
    _lastGlobal = d.globalPosition;
    _drag.value = _Drag(item, at);
  }

  void _panUpdate(DragUpdateDetails d) {
    final cur = _drag.value;
    final g = _geo;
    if (cur == null || g == null) return;
    if (coworkerOpen) {
      // He peeped in mid-drag: the hands stop so the player sees him.
      _drag.value = null;
      return;
    }
    _lastGlobal = d.globalPosition;
    final p = d.localPosition + _grab;
    _drag.value = _Drag(cur.item, Offset(p.dx.clamp(4.0, 356.0), p.dy.clamp(40.0, g.groundY + 4)));
  }

  void _panEnd() {
    final cur = _drag.value;
    final g = _geo;
    _drag.value = null;
    // He came in while this was in the hands: the hands stop (nothing counts).
    if (cur == null || g == null || _blocked || _run.ended || coworkerOpen) return;
    _moves++;
    _armCoworker();
    final at = cur.at;
    String? id;
    var point = at;
    if (_run.round == 0) {
      switch (cur.item) {
        case _Item.clamp:
          final good = g.spike(good: true, goodLeft: _deal.goodLeft);
          final bad = g.spike(good: false, goodLeft: _deal.goodLeft);
          if ((at - good).distance < 32) {
            id = DischargeIds.earth;
            point = good;
          } else if ((at - bad).distance < 32) {
            id = DischargeIds.rusty;
            point = bad;
          }
        case _Item.hook:
          final w = g.wireNear(at);
          if (w != null) {
            id = w;
            point = Offset(at.dx, g.wireY(w, at.dx));
          }
        case _Item.chain:
          if (at.dx > DischargeGeo.poleX + 20 &&
              at.dx < DischargeGeo.farX - 16 &&
              at.dy < g.wireY(DischargeIds.b, at.dx) + 18 &&
              at.dy > g.wireY(DischargeIds.y, at.dx) - 70) {
            id = DischargeIds.chain;
            point = Offset(g.chainSpot(at.dx), g.wireY(DischargeIds.y, g.chainSpot(at.dx)));
          }
      }
    } else {
      switch (cur.item) {
        case _Item.chain:
          if (at.dy > g.wireY(DischargeIds.b, _chainX!) + 64) id = DischargeIds.chainOff;
        case _Item.hook:
          if ((at - _hookPoint(g)).distance > 46) id = DischargeIds.hookOff;
        case _Item.clamp:
          if ((at - _goodSpike).distance > 36) id = DischargeIds.clampOff;
      }
    }
    if (id == null || _holdForHim(id)) {
      // Back where it was (no cost).
      setState(() {});
      return;
    }
    _act(id, point);
  }

  void _act(String id, Offset point) {
    final t = _run.tap(id);
    switch (t.kind) {
      case OrderTapKind.ignored:
        // A wire already discharged: the hook simply rests there.
        setState(() {
          if (DischargeIds.phases.contains(id)) {
            _hookOn = id;
            _hookX = point.dx;
          }
        });
        return;
      case OrderTapKind.mistake:
        final m = t.mistake!;
        if (m.deadly) {
          // Show what was done: the hook on the wire, the chain on the line.
          setState(() {
            if (DischargeIds.phases.contains(id)) {
              _hookOn = id;
              _hookX = point.dx;
            }
            if (id == DischargeIds.chain) _chainX = point.dx;
          });
          unawaited(_deadly(m, id == DischargeIds.chain ? _Zap.chain : _Zap.hook));
        } else {
          unawaited(_slip(m, point));
        }
        return;
      case OrderTapKind.ok:
        unawaited(_stepDone(id, t, point));
    }
  }

  Future<void> _stepDone(String id, OrderTap t, Offset point) async {
    final phase = DischargeIds.phases.contains(id);
    if (phase) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    } else {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.55, muted: false));
    }
    setState(() {
      _wake++;
      switch (id) {
        case DischargeIds.earth:
          _clamped = true;
        case DischargeIds.chain:
          _chainX = point.dx;
        case DischargeIds.chainOff:
          _chainX = null;
        case DischargeIds.hookOff:
          _hookOn = null;
        case DischargeIds.clampOff:
          _clamped = false;
      }
      if (phase) {
        _hookOn = id;
        _hookX = point.dx;
        _sparks++;
        _sparkAt = point;
      }
    });
    final origin = _lastGlobal;
    final ok = !_muted;
    if (id == DischargeIds.earth) {
      if (ok) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: false));
      _ask(10, DischargeLines.earthRight, DischargeLines.earthWrong, DischargeLines.earthAsk, then: _goOn);
      return;
    }
    if (phase) {
      if (DischargeIds.phases.every(_run.isDone)) {
        _ask(5, DischargeLines.phaseRight, DischargeLines.phaseWrong, DischargeLines.phaseAsk, then: _goOn);
        return;
      }
      unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
      unawaited(_sayChain([_sparkBag.next().shownBn], mood: GuideMood.glad));
      return;
    }
    if (id == DischargeIds.chain) {
      if (ok) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: false));
      _ask(10, DischargeLines.chainRight, DischargeLines.chainWrong, DischargeLines.chainAsk, then: () => unawaited(_roundTwo()));
      return;
    }
    if (t.allDone) {
      if (ok) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.55, muted: false));
      setState(() => _cheer = true);
      _ask(5, DischargeLines.lastRight, DischargeLines.lastWrong, DischargeLines.lastAsk, then: () => unawaited(_finish()));
      return;
    }
    unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
    unawaited(_sayChain([_offBag.next().shownBn], mood: GuideMood.glad));
  }

  /// A milestone: its ◆ wait on the table, then "কেন …?"; [then] once paid.
  void _ask(int amount, List<String> right, List<String> wrong, String question, {required VoidCallback then}) {
    _afterPaid = then;
    putOnTable(amount);
    unawaited(askReason(
      deal: () => dealChoices(right, wrong, widget.rng),
      question: question,
      stillValid: () => !_ended,
    ));
  }

  /// After a paid reason in round 1: the next task.
  void _goOn() {
    setState(() {});
    unawaited(_sayChain([_task]));
  }

  /// Round 1 done: a short look at the safe line, then off in reverse.
  Future<void> _roundTwo() async {
    _busy = true;
    setState(() {
      _cheer = true;
      _wake++;
    });
    unawaited(_sayChain([DischargeLines.onDone, DischargeLines.askOff], mood: GuideMood.glad));
    await Future<void>.delayed(MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _cheer = false;
      _wake++;
    });
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
    then?.call();
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => DischargeLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // Too late once the three phases are discharged (or the play is over).
    if (_ended || _run.ended || _run.round != 0 || DischargeIds.phases.every(_run.isDone)) return null;
    // His moment is dealt (after this many steps); not over a card or a deck.
    // Mid-drag is fine: the hands stop when he comes (_panUpdate / _panEnd).
    if (_run.stepsDone < _deal.callAfter || _blocked) return false;
    return true;
  }

  /// He is sent for once, at the player's first move (an idle screen never
  /// calls him); the mixin then waits for his dealt moment and a free screen.
  /// Later drops do not restart his timer, so a player who keeps working
  /// still meets him.
  var _coworkerArmed = false;

  void _armCoworker() {
    if (_coworkerArmed || coworkerDone || _run.round != 0 || _moves == 0) return;
    _coworkerArmed = true;
    scheduleCoworker();
  }

  /// His moment is due and he has not come yet: the last phase waits for
  /// him (the hook goes back, nothing counts, no cost), so a fast player
  /// still meets the push before the discharge is done.
  bool _holdForHim(String id) =>
      _run.round == 0 &&
      !coworkerDone &&
      !coworkerOpen &&
      _run.isDone(DischargeIds.earth) &&
      DischargeIds.phases.contains(id) &&
      !_run.isDone(id) &&
      DischargeIds.phases.where((p) => p != id).every(_run.isDone);

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Up to the line without the discharge.
      _run.failDeadly(DischargeMistakes.skipDischarge);
      await _deadly(DischargeMistakes.skipDischarge, _Zap.bare);
      return;
    }
    _callHeld = true;
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([DischargeLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? DischargeLines.tapWhy[_nudgeN++ % DischargeLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes -------------------------------------------------------------------

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

  Future<void> _slip(DoMistake m, Offset point) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _pings++;
      _pingAt = point;
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(_levelDelta(-10, _lastGlobal, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('order/${m.key}');
    if (!mounted || _card != m) return;
    // The rule is read aloud the first time only; after that a short word
    // (the card shows the rule).
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the roadside freezes grey while the charge finds its way
  /// in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m, _Zap zap) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 1, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _zap = zap;
    });
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('order/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? DischargeLines.deadlyWord : DischargeLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    final m = _card;
    if (m == null) return;
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
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
    });
    await _say(!_run.passed ? DischargeLines.fail : (_quickBonus ? DischargeLines.quick : DischargeLines.allSet),
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

  List<String> get _caught => [
        DischargeLines.caughtEarth,
        DischargeLines.caughtPhases,
        DischargeLines.caughtChain,
        if (_callHeld) DischargeLines.caughtCall,
        DischargeLines.caughtOff,
      ];

  // ---- build ------------------------------------------------------------------------

  /// His face (his hands stay on the rod).
  LinemanMode get _mood {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_cheer) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  List<Widget> _scene(SceneMetrics m, bool quiet) {
    final g = _geo = DischargeGeo.forScene(m.height, m.inset);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final yard = PoleGeo(height: m.height, groundY: g.groundY, length: g.len);
    final box = g.traineeBox;
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(child: CustomPaint(painter: PoleYardPainter(geo: yard, orbit: 0.38 + 0.24 * _deal.view))),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('rig'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(child: CustomPaint(painter: _RigPainter(geo: g, goodLeft: _deal.goodLeft))),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: box,
        child: ColorFiltered(
          colorFilter: grey,
          child: Transform.flip(
            flipX: true,
            child: LinemanFigure(look: LinemanLook.trainee, mode: LinemanMode.hold, mood: _mood, wake: _wake, quiet: quiet),
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('gear'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GearPainter(
                geo: g,
                drag: _drag,
                hook: _hookPoint(g),
                hookOn: _hookOn != null,
                clamp: _clamped ? g.spike(good: true, goodLeft: _deal.goodLeft).translate(0, 4) : g.clampRest,
                clamped: _clamped,
                chainX: _chainX,
              ),
            ),
          ),
        ),
      ),
      if (_sparkAt != null && _sparks > 0 && !quiet)
        Positioned(
          key: const ValueKey('spark'),
          left: _sparkAt!.dx - 40,
          top: _sparkAt!.dy - 40,
          width: 80,
          height: 80,
          child: IgnorePointer(child: _OneShot(key: ValueKey('spark-$_sparks'), ms: 520, painter: _SparkPainter.new)),
        ),
      if (_pingAt != null && _pings > 0 && !quiet)
        Positioned(
          key: const ValueKey('ping'),
          left: _pingAt!.dx - 40,
          top: _pingAt!.dy - 40,
          width: 80,
          height: 80,
          child: IgnorePointer(child: _OneShot(key: ValueKey('ping-$_pings'), ms: 560, painter: _PingPainter.new)),
        ),
      // The deadly moment, in colour over the grey roadside.
      if (_freeze && _zap != null)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: _OneShot(
              ms: quiet ? 1 : 1400,
              painter: (t) => _ZapPainter(t, path: _zapPath(g, _zap!), figure: box, chainX: _zap == _Zap.chain ? _chainX : null, geo: g),
            ),
          ),
        ),
      // The hands: pick up the clamp, the rod or the chain and drag.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: DischargeLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
    ];
  }

  /// The way the charge goes in the deadly picture.
  List<Offset> _zapPath(DischargeGeo g, _Zap z) {
    final box = g.traineeBox;
    final feet = Offset(box.center.dx, box.bottom - 2);
    switch (z) {
      case _Zap.hook:
        final hook = _hookPoint(g);
        return [hook, Offset.lerp(hook, g.hands, 0.5)!, g.hands, box.center, feet];
      case _Zap.chain:
        final x = _chainX ?? g.chainSpot(g.hands.dx);
        return [g.chainGrab(x), g.hands, box.center, feet];
      case _Zap.bare:
        final x = box.center.dx;
        final wire = Offset(x, g.wireY(DischargeIds.b, x));
        return [wire, Offset(x - 6, box.top + 4), box.center, feet];
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
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
              labels: DischargeLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 2); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m, quiet),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$_pings'),
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
                  sound: FailSound.electric,
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
                  line: DischargeLines.intro,
                  alarm: 'sounds/learn/spark.wav',
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

double _distToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final l2 = ab.distanceSquared;
  if (l2 == 0) return (p - a).distance;
  final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / l2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

// ============================================================================
// Painters
// ============================================================================

/// The two concrete poles with their crossarms and insulators, the three
/// conductors R, Y, B (tags on the near crossarm), and the two earth spikes —
/// one sound, one rusty and loose. Static: repaints only when the scene size changes.
class _RigPainter extends CustomPainter {
  const _RigPainter({required this.geo, required this.goodLeft});
  final DischargeGeo geo;
  final bool goodLeft;

  static const _tagColour = {DischargeIds.r: Color(0xFFD63A2F), DischargeIds.y: Color(0xFFF2C230), DischargeIds.b: Color(0xFF2F6FD6)};

  @override
  void paint(Canvas c, Size s) {
    final g = geo;
    _pole(c, far: true);
    _pole(c, far: false);
    // The conductors.
    final dark = Paint()
      ..color = const Color(0xFF2A2E33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * g.sp
      ..strokeCap = StrokeCap.round;
    final shine = Paint()
      ..color = const Color(0x66C9D2DA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final p in DischargeIds.phases) {
      final path = g.wirePath(p);
      c.drawPath(path, dark);
      c.drawPath(path.shift(const Offset(0, -0.8)), shine);
    }
    // Phase tags under the near insulators.
    for (final p in DischargeIds.phases) {
      final a = g.attach(p);
      final at = p == DischargeIds.y ? a.translate(12 * g.sp, 26 * g.sp) : a.translate(0, 32 * g.sp);
      c.drawCircle(at, 7.5 * g.sp, Paint()..color = _tagColour[p]!);
      c.drawCircle(
        at,
        7.5 * g.sp,
        Paint()
          ..color = const Color(0xCCFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: DischargeLines.phaseTag[p],
          style: TextStyle(fontSize: 9.5 * g.sp, fontWeight: FontWeight.w900, color: p == DischargeIds.y ? const Color(0xFF2A2200) : Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
    }
    // The earth spikes, each in its little pit.
    _spike(c, g.spike(good: true, goodLeft: goodLeft), good: true);
    _spike(c, g.spike(good: false, goodLeft: goodLeft), good: false);
  }

  void _pole(Canvas c, {required bool far}) {
    final g = geo;
    final f = far ? DischargeGeo.farScale : 1.0;
    final k = g.sp * f;
    final x = far ? DischargeGeo.farX : DischargeGeo.poleX;
    final base = far ? g.farBaseY : g.groundY;
    final yTop = far ? g.farBaseY - f * g.len : g.topY;
    final top = yTop + 18 * k;
    final bw = 8.5 * k;
    final tw = 5.0 * k;
    final body = Path()
      ..moveTo(x - bw, base + 2)
      ..lineTo(x - tw, top)
      ..lineTo(x + tw, top)
      ..lineTo(x + bw, base + 2)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(colors: far ? const [Color(0xFF9EA3A6), Color(0xFF7D8285)] : const [Color(0xFFC9CCCB), Color(0xFF8E9394)])
            .createShader(Rect.fromLTRB(x - bw, top, x + bw, base)),
    );
    // A shadow line down one side, and the soil ring at the foot.
    c.drawLine(Offset(x + tw * 0.4, top), Offset(x + bw * 0.4, base), Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 2 * k);
    c.drawOval(Rect.fromCenter(center: Offset(x, base + 2), width: bw * 4, height: 5 * k), Paint()..color = const Color(0x55402A14));
    // The crossarm (seen a little from the side) with its brace.
    final armY = yTop + 76 * k;
    final a0 = Offset(x - 44 * k, armY - 22 * k);
    final a1 = Offset(x + 44 * k, armY + 22 * k);
    final steel = Paint()
      ..color = far ? const Color(0xFF4A4F55) : const Color(0xFF3A3F45)
      ..strokeWidth = 5.5 * k
      ..strokeCap = StrokeCap.butt;
    c.drawLine(a0, a1, steel);
    c.drawLine(Offset(x, armY + 24 * k), Offset.lerp(a0, a1, 0.2)!, steel..strokeWidth = 2.4 * k);
    c.drawLine(Offset(x, armY + 24 * k), Offset.lerp(a0, a1, 0.8)!, steel);
    // Insulators: a pin on each arm end, one on the pole top.
    for (final p in DischargeIds.phases) {
      final w = g.attach(p, far: far);
      _insulator(c, w, k, p == DischargeIds.y ? top : w.dy + 16 * k);
    }
  }

  static void _insulator(Canvas c, Offset wire, double k, double footY) {
    c.drawLine(Offset(wire.dx, footY), Offset(wire.dx, wire.dy + 6 * k), Paint()
      ..color = const Color(0xFF6B6F73)
      ..strokeWidth = 2.2 * k);
    final porcelain = Paint()..color = const Color(0xFFF1E9DA);
    final rim = Paint()
      ..color = const Color(0xFFB8A98E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (var i = 0; i < 3; i++) {
      final cy = wire.dy + (3 + 4.2 * i) * k;
      final r = Rect.fromCenter(center: Offset(wire.dx, cy), width: (10 - i * 1.2) * k, height: 3.6 * k);
      c.drawOval(r, porcelain);
      c.drawOval(r, rim);
    }
  }

  /// An earth spike in its pit, drawn big enough to read on a phone: the
  /// sound one is a clean copper rod with a bright brass terminal and bolt;
  /// the bad one is rusted through, bent, its terminal broken off and lying
  /// in the dirt.
  void _spike(Canvas c, Offset top, {required bool good}) {
    final y0 = geo.groundY;
    final h = y0 - top.dy;
    c.save();
    c.translate(top.dx, y0);
    // The pit.
    c.drawOval(Rect.fromCenter(center: const Offset(0, 2), width: 54, height: 13), Paint()..color = const Color(0xFF5E4630));
    c.drawOval(Rect.fromCenter(center: const Offset(0, 1), width: 36, height: 7), Paint()..color = const Color(0xFF3F2E1E));
    if (good) {
      // The copper-bonded rod, round (lit from the left).
      final rod = Rect.fromLTRB(-4.5, -h + 9, 4.5, 1);
      c.drawRect(
        rod,
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF4B983), Color(0xFFC77A3E), Color(0xFF8E4E22)], stops: [0, 0.45, 1]).createShader(rod),
      );
      // The brass terminal block with its bolt.
      final lug = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -h + 8), width: 20, height: 13), const Radius.circular(3));
      c.drawRRect(
        lug,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF6D27A), Color(0xFFC08A2A)]).createShader(lug.outerRect),
      );
      c.drawRRect(lug, Paint()
        ..color = const Color(0xFF7A5512)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1);
      c.drawCircle(Offset(0, -h + 8), 3.6, Paint()..color = const Color(0xFF8C6A20));
      c.drawCircle(Offset(-0.8, -h + 7.2), 1.4, Paint()..color = const Color(0xFFFFF0C0));
      // A glint: bright metal.
      c.drawLine(Offset(-7, -h + 4), Offset(-3, -h + 4), Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round);
    } else {
      // The rusted rod, bent over near the top, its end snapped off.
      final rod = Path()
        ..moveTo(-4.8, 1)
        ..lineTo(-3.6, -h + 17)
        ..lineTo(5.0, -h + 7)
        ..lineTo(8.6, -h + 9)
        ..lineTo(7.4, -h + 11.5)
        ..lineTo(9.4, -h + 13)
        ..lineTo(3.4, -h + 19)
        ..lineTo(4.4, 1)
        ..close();
      c.drawPath(rod, Paint()..color = const Color(0xFF7E3F1C));
      c.drawPath(rod, Paint()
        ..color = const Color(0xFF4A220E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      // Rust: orange flakes and dark pits all over.
      final flake = Paint()..color = const Color(0xFFD0702E);
      final pit = Paint()..color = const Color(0xFF3E1A08);
      for (final (dx, dy, r) in const [(-1.5, 4.0, 2.2), (1.8, 9.0, 1.7), (-0.8, 15.0, 2.4), (2.2, 21.0, 1.6), (-2.0, 26.0, 1.4), (5.2, -4.0, 1.6)]) {
        c.drawCircle(Offset(dx, -h + 10 + dy), r, flake);
      }
      for (final (dx, dy) in const [(1.0, 6.0), (-2.2, 12.0), (1.6, 18.0), (-1.0, 24.0)]) {
        c.drawCircle(Offset(dx, -h + 10 + dy), 0.9, pit);
      }
      // Rust stain on the soil around it.
      c.drawOval(Rect.fromCenter(center: const Offset(1, 0), width: 22, height: 4), Paint()..color = const Color(0x88A0501E));
      // The broken terminal, lying in the dirt beside it, cracked.
      c.save();
      c.translate(17, -4);
      c.rotate(0.6);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 17, height: 10), const Radius.circular(2.5)),
          Paint()..color = const Color(0xFF6E5136));
      c.drawCircle(const Offset(1, 0), 2.6, Paint()..color = const Color(0xFF3A2A1A));
      c.drawLine(const Offset(-6, -5), const Offset(-1, 1), Paint()
        ..color = const Color(0xFF2A1A0A)
        ..strokeWidth = 1.3);
      c.drawLine(const Offset(-1, 1), const Offset(-3, 5), Paint()
        ..color = const Color(0xFF2A1A0A)
        ..strokeWidth = 1.3);
      c.restore();
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_RigPainter old) => old.geo != geo || old.goodLeft != goodLeft;
}

/// The rod (fibreglass stick from the trainee's hands to the hook), its
/// copper cable down to the earth clamp, the clamp, and the shorting chain
/// (coiled on the ground or thrown over the wires). Repaints while dragging.
class _GearPainter extends CustomPainter {
  _GearPainter({
    required this.geo,
    required this.drag,
    required this.hook,
    required this.hookOn,
    required this.clamp,
    required this.clamped,
    required this.chainX,
  }) : super(repaint: drag);

  final DischargeGeo geo;
  final ValueNotifier<_Drag?> drag;
  final Offset hook;
  final bool hookOn;
  final Offset clamp;
  final bool clamped;
  final double? chainX;

  @override
  void paint(Canvas c, Size s) {
    final g = geo;
    final d = drag.value;
    final hookAt = d?.item == _Item.hook ? d!.at : hook;
    final clampAt = d?.item == _Item.clamp ? d!.at : clamp;
    final chainDrag = d?.item == _Item.chain ? d!.at : null;
    final hands = g.hands;

    // The chain: on the wires, or coiled on the ground, or in the hand.
    if (chainDrag != null) {
      if (chainX != null) {
        _drapedChain(c, chainX!, tail: chainDrag);
      } else {
        _coil(c, chainDrag);
      }
    } else if (chainX != null) {
      _drapedChain(c, chainX!);
    } else {
      _coil(c, g.coilRest);
    }

    // The rod. Stylised: it runs from the hands to wherever the hook is, so
    // it reads longer when the hook is up at a wire than at rest.
    final dir = hands - hookAt;
    final n = dir.distance == 0 ? const Offset(0, 1) : dir / dir.distance;
    final head = hookAt + n * 12;
    final grip = hands + n * 4;
    c.drawLine(head, grip, Paint()
      ..color = const Color(0xFFE6C35C)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round);
    c.drawLine(Offset.lerp(head, grip, 0.62)!, Offset.lerp(head, grip, 0.66)!, Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 5.2);
    c.drawLine(Offset.lerp(head, grip, 0.82)!, grip.translate(n.dx * 6, n.dy * 6), Paint()
      ..color = const Color(0xFF34383D)
      ..strokeWidth = 5.4
      ..strokeCap = StrokeCap.round);
    // The hook: a J over the wire.
    final side = Offset(-n.dy, n.dx);
    final hp = Path()
      ..moveTo(head.dx, head.dy)
      ..lineTo(hookAt.dx + side.dx * 1.5, hookAt.dy + 1.5)
      ..quadraticBezierTo(hookAt.dx - n.dx * 9 + side.dx * 2, hookAt.dy - n.dy * 9 - 2, hookAt.dx - side.dx * 7, hookAt.dy - 3);
    c.drawPath(
      hp,
      Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    // The copper cable from the rod's head down to the clamp.
    final from = Offset.lerp(head, grip, 0.08)!;
    final ctl = Offset((from.dx + clampAt.dx) / 2 + 18, math.max(from.dy, clampAt.dy) + 26);
    final cable = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctl.dx, ctl.dy, clampAt.dx, clampAt.dy - 2);
    c.drawPath(
      cable,
      Paint()
        ..color = const Color(0xFF8A5A1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
    c.drawPath(
      cable,
      Paint()
        ..color = const Color(0xFFD9954A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _clamp(c, clampAt, on: clamped && d?.item != _Item.clamp);
  }

  /// A G-clamp: the jaw, the screw and its T-handle.
  static void _clamp(Canvas c, Offset at, {required bool on}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(1.4);
    final steel = Paint()
      ..color = const Color(0xFF8E979F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final jaw = Path()
      ..moveTo(6, -8)
      ..lineTo(-5, -8)
      ..quadraticBezierTo(-10, -8, -10, -3)
      ..lineTo(-10, 3)
      ..quadraticBezierTo(-10, 8, -5, 8)
      ..lineTo(6, 8);
    c.drawPath(jaw, Paint()
      ..color = const Color(0xFF4A5056)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round);
    c.drawPath(jaw, steel);
    c.drawLine(const Offset(6, 12), const Offset(6, -4), steel..strokeWidth = 2);
    c.drawLine(const Offset(2, 12), const Offset(10, 12), steel..strokeWidth = 2.4);
    if (on) c.drawCircle(const Offset(6, -8), 2.4, Paint()..color = const Color(0xFFD9A441));
    c.restore();
  }

  /// The brass ball-chain coiled on the ground (or in the hand).
  static void _coil(Canvas c, Offset at) {
    final bead = Paint()..color = const Color(0xFFD2A43C);
    final dark = Paint()..color = const Color(0xFF8C6A20);
    for (var ring = 0; ring < 3; ring++) {
      final rx = 13.0 - ring * 3;
      final ry = 5.0 - ring * 1.1;
      final cy = at.dy - ring * 2.6;
      for (var i = 0; i < 18 - ring * 4; i++) {
        final a = i / (18 - ring * 4) * 2 * math.pi;
        final p = Offset(at.dx + rx * math.cos(a), cy + ry * math.sin(a));
        c.drawCircle(p.translate(0.4, 0.5), 1.7, dark);
        c.drawCircle(p, 1.6, bead);
      }
    }
  }

  /// The chain over the three wires at [x], its end hanging (or held at [tail]).
  void _drapedChain(Canvas c, double x, {Offset? tail}) {
    final g = geo;
    final yY = g.wireY(DischargeIds.y, x);
    final yR = g.wireY(DischargeIds.r, x + 3);
    final yB = g.wireY(DischargeIds.b, x + 6);
    final end = tail ?? g.chainGrab(x);
    final path = Path()
      ..moveTo(x - 12, yY + 16)
      ..quadraticBezierTo(x - 6, yY - 4, x, yY)
      ..lineTo(x + 3, yR)
      ..lineTo(x + 6, yB)
      ..quadraticBezierTo(x + 8, (yB + end.dy) / 2, end.dx, end.dy);
    final bead = Paint()..color = const Color(0xFFD2A43C);
    final dark = Paint()..color = const Color(0xFF8C6A20);
    for (final m in path.computeMetrics()) {
      for (var t = 0.0; t < m.length; t += 4.2) {
        final p = m.getTangentForOffset(t)!.position;
        c.drawCircle(p.translate(0.5, 0.6), 2.1, dark);
        c.drawCircle(p, 1.9, bead);
      }
    }
  }

  @override
  bool shouldRepaint(_GearPainter old) =>
      old.geo != geo || old.hook != hook || old.hookOn != hookOn || old.clamp != clamp || old.clamped != clamped || old.chainX != chainX || old.drag != drag;
}

/// Runs its painter once from 0 to 1, then rests (draws nothing more).
class _OneShot extends StatefulWidget {
  const _OneShot({super.key, required this.ms, required this.painter});
  final int ms;
  final CustomPainter Function(Animation<double> t) painter;

  @override
  State<_OneShot> createState() => _OneShotState();
}

class _OneShotState extends State<_OneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: widget.painter(_c));
}

/// "চট্": a white-yellow flash with short rays.
class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    final c = size.center(Offset.zero);
    final fade = 1 - v;
    canvas.drawCircle(
      c,
      6 + 16 * v,
      Paint()
        ..color = Color.fromRGBO(255, 244, 180, 0.85 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final ray = Paint()
      ..color = Color.fromRGBO(255, 210, 31, fade)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (8 + 10 * v), c + d * (16 + 20 * v), ray);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}

/// A red ring where a wrong move landed.
class _PingPainter extends CustomPainter {
  _PingPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      10 + 26 * v,
      Paint()
        ..color = Color.fromRGBO(192, 57, 43, 1 - v)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_PingPainter old) => false;
}

/// The deadly moment in colour: the charge jumps along [path] (the hook or
/// the chain, through the trainee's body to the ground), the body glows red.
class _ZapPainter extends CustomPainter {
  _ZapPainter(this.t, {required this.path, required this.figure, required this.geo, this.chainX}) : super(repaint: t);
  final Animation<double> t;
  final List<Offset> path;
  final Rect figure;
  final DischargeGeo geo;
  final double? chainX;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final flash = v < 0.2 ? v / 0.2 : (1 - (v - 0.2) / 0.8);
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 240, 230, 0.4 * flash.clamp(0.0, 1.0)));
    // The body takes the charge.
    canvas.drawOval(
      figure.inflate(8),
      Paint()
        ..color = const Color(0x99FF3B2F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final rnd = math.Random(v >= 1 ? 7 : (v * 14).floor());
    final arc = Path()..moveTo(path.first.dx, path.first.dy);
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1];
      final b = path[i];
      const n = 5;
      for (var j = 1; j <= n; j++) {
        final p = Offset.lerp(a, b, j / n)!;
        final jitter = j == n ? 0.0 : (rnd.nextDouble() - 0.5) * 14;
        arc.lineTo(p.dx + jitter, p.dy + jitter * 0.3);
      }
    }
    canvas.drawPath(
      arc,
      Paint()
        ..color = const Color(0xAA8FD3FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      arc,
      Paint()
        ..color = const Color(0xFFFFF7D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );
    // Sparks where it starts.
    final ray = Paint()
      ..color = const Color(0xFFFFD21F)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final o = path.first;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + v * 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(o + d * 6, o + d * (14 + 6 * flash.clamp(0.0, 1.0)), ray);
    }
  }

  @override
  bool shouldRepaint(_ZapPainter old) => false;
}
