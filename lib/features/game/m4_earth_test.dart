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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm4_earth_test_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_earth_test_world.dart' show M4EarthTestFault, M4EarthTestGeo, m4EarthTestPitNames, m4EarthTestOhms;

// Lesson 4.6 "সঠিক আর্থিং পরীক্ষা ও রক্ষণাবেক্ষণ", কাজ 1 "মাটির পরীক্ষা"
// (pack do_4_6_a, engine m4_earth_test). A pole-mounted distribution
// transformer with its double earthing (pro tip 1, film line 4: the neutral
// and the body, each to two separate pits — N-1 N-2 B-1 B-2). Three stations:
//   ক look (spot) — lesson point 2, the visual check: an earth strip cut or
//     stolen, a rusty / loose joint at the electrode, a pit with its cover
//     off. 1–2 dealt a play; tap each, then "দেখা শেষ". Missing one = a slip.
//   খ, গ test one neutral pit and one body pit (order) — lesson point 3,
//     "শুধু চাক্ষুষ পরিদর্শন যথেষ্ট নয়": the earth tester, two temporary
//     spikes driven into the soil (fall of potential), the leads, TEST; the
//     leads before both spikes, or TEST before the circuit is made = a slip;
//   then read: the tester shows ohms; mark it ঠিক or বেশি against the
//     lesson's value for a distribution line (less than 5–8 Ω). One pit a
//     play reads good (≤ 4.2 Ω), the other high (≥ 12 Ω); a wrong mark = slip.
// The careless coworker (one of two pushes, dealt): before the first test
// "চোখে দেখেই হলো, মেগার লাগবে না" (lesson point 3), or on the high reading
// "লাইন তো চলছে, ঠিক লিখে দাও" (myth 1). Listening = a slip.
// No deadly move: the lesson gives none for the test itself.
//
// Flagged to the owner: the spike spacing, the tester's E/P/C terminals, and
// whether the earth lead is disconnected for the test are not in the lesson
// or the film — left out. The lesson gives one value for "a distribution
// line" (less than 5–8 Ω) and one for a substation (< 1 Ω); no separate
// targets per neutral / body / LA earth — the line value is used for all.

// ============================================================================
// Content
// ============================================================================

enum M4EarthTestStation { look, pitA, pitB }

abstract final class M4EarthTestLines {
  static const title = 'মাটির পরীক্ষা';
  static const intro = 'আর্থিং অদৃশ্য রক্ষক! DTR-এর আর্থ পিটগুলো পরীক্ষা করুন।';
  static const rounds = ['ক', 'খ', 'গ'];

  static const askLook = 'আগে চোখে দেখুন — আর্থ তার, জোড় আর পিট।';
  static String askRig(int pit) => '${m4EarthTestPitNames[pit]} পিটের আর্থ রেজিস্ট্যান্স মাপুন।';
  static const askRead = 'টেস্টারে কত এল? খাতায় লিখুন।';
  static const tasks = [askLook, askRead];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'DTR-এর আর্থ পিট';
  static const lookDone = 'দেখা শেষ';
  static const spike = 'স্পাইক';
  static const leads = 'লিড জুড়ুন';
  static const test = 'TEST';
  static const tester = 'আর্থ টেস্টার';
  static const markOk = 'মান ঠিক';
  static const markHigh = 'মান বেশি';
  static const docket = 'ডকেট';
  static const job = 'আর্থ রেজিস্ট্যান্স মাপা';
  static const site = 'DTR · ডাবল আর্থিং';

  // The reasons (lesson 4.6). The right ones state the lesson's rule; the
  // wrong ones are field excuses and the lesson's myths.
  static const whyLook = 'কেন আগে চোখে দেখলেন?';
  static const whyOk = 'কেন মান ঠিক লিখলেন?';
  static const whyHigh = 'কেন মান বেশি লিখলেন?';

  static const lookRight = [
    'বেশিরভাগ আর্থিং সমস্যা জোড়ের জায়গাতেই হয়',
    'জং ধরা বা ঢিলে জোড়ে রেজিস্ট্যান্স অনেক বাড়ে',
    'কাটা বা চুরি যাওয়া আর্থ তার আগেই ধরতে হয়',
  ];
  static const okRight = [
    'লাইনের আর্থে 5–8 ওহমের কম মানই ভালো মান',
    'মান যত কম, আর্থিং তত ভালোভাবে কাজ করে',
    'এই মানে ফল্ট কারেন্ট সহজে মাটিতে যাবে',
  ];
  static const highRight = [
    '5–8 ওহমের বেশি মানে আর্থিং দুর্বল হয়ে গেছে',
    'বেশি রেজিস্ট্যান্সে ফল্টে ব্রেকার ট্রিপ করে না',
    'এমন আর্থে রক্ষণাবেক্ষণ লাগবে, ঠিক লেখা যাবে না',
  ];

  /// Field excuses and the lesson's myths (wrong on every deck).
  static const excuses = [
    'লাইন তো চলছে, তাই আর্থ নিয়ে ভাবনা নেই',
    'টেস্টারে যা আসে, আন্দাজে লিখলেই তো চলে',
    'আর্থের মান যত বেশি, সুরক্ষাও তত বেশি',
    'একটা লোহার রড পুঁতলেই তো ভালো আর্থ হয়',
    'সুপারভাইজার দেখছেন না, এতেই কাজ চলবে',
    'সবাই তো এভাবেই করে, কিছু হয় না কখনো',
  ];

  /// The careless coworker's exit line (already recorded in his voice).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';

  /// Push 1 (before the first test): eyes only (lesson point 3).
  static const coworkerSkip = CoworkerScript(
    line: 'চোখে তো সবই দেখলে! মেগার-টেগার লাগবে না, চলো।',
    exitLine: coworkerExit,
    right: ['না, চোখে দেখা যথেষ্ট নয়, মাপতেই হবে', 'না, আর্থ টেস্টার দিয়ে মেপেই যাব', 'না, আসল পরীক্ষা হলো ওহম মাপা'],
    wrong: ['ঠিক, চোখে দেখেই তো সব বোঝা যায়', 'আচ্ছা, মাপামাপি বাদ দিয়ে চলো যাই', 'হ্যাঁ, পিট তো দেখতে ভালোই আছে', 'ঠিক বলেছ, মাপতে শুধু সময় নষ্ট', 'চলো, খাতায় সব ঠিকঠাক লিখে দিই'],
    asks: ['ও বলছে মাপার দরকার নেই। কী করবেন?', 'মাপবেন, না চোখে দেখেই ছাড়বেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );

  /// Push 2 (on the high reading): the line runs (myth 1).
  static const coworkerRuns = CoworkerScript(
    line: 'লাইন তো দিব্যি চলছে! খাতায় মান ঠিক লিখে দাও, ঝামেলা কোরো না।',
    exitLine: coworkerExit,
    right: ['না, বেশি মান মানে দুর্বল আর্থ', 'না, যা মাপলাম সেটাই খাতায় লিখব', 'না, ফল্টের সময় এ আর্থ কাজ করবে না'],
    wrong: ['ঠিক, লাইন চলছে মানে আর্থও ঠিক', 'আচ্ছা, খাতায় মান ঠিক লিখে দিই', 'হ্যাঁ, একটু বেশিতে কিছু হয় না', 'ঠিক, পরে তো কেউ আর মাপবে না', 'চলো, ঝামেলা না করে ঠিকই লিখি'],
    asks: ['ও বলছে ঠিক লিখে দিতে। কী লিখবেন?', 'মাপা মান লিখবেন, না ওর কথা?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );

  static const allSet = 'অদৃশ্য রক্ষকের পরীক্ষা শিখে গেছেন — চোখে দেখা, মাপা, ঠিক মান লেখা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চোখে দেখে, দুটি স্পাইকে মেপে, সৎ মান লিখে।';

  // "আজ যা ধরলেন".
  static const caughtLook = 'চোখে দেখে আর্থের গোলমাল ধরেছেন';
  static const caughtRig = 'দুটি স্পাইক পুঁতে মেপেছেন';
  static const caughtHigh = 'বেশি মান ধরেছেন';
  static const caughtOk = 'ভালো মান চিনেছেন';
  static const caughtCall = 'চাপে “না” — মেপেই লেখা';
}

abstract final class M4EarthTestMistakes {
  static const _dir = 'assets/game/art/m4_earth_test';

  static const missedCut = DoMistake(
    key: '4.6/m4_earth_test/missed-cut-strip',
    textBn: 'একটা আর্থ তার কাটা বা চুরি হয়ে গেছে — চোখ এড়িয়ে গেল। পোল বেয়ে নামা আর্থ তার কোথাও কাটা, ছেঁড়া বা জং ধরা কি না দেখুন।',
    art: '$_dir/cut.svg',
    lessonPoint: 1,
  );
  static const missedRust = DoMistake(
    key: '4.6/m4_earth_test/missed-rusty-joint',
    textBn: 'ইলেক্ট্রোডের জোড়টা জং ধরা, ঢিলে — চোখ এড়িয়ে গেল। লুজ বা মরিচা ধরা কানেকশন আর্থিং-এর রেজিস্ট্যান্স বহুগুণ বাড়ায়।',
    art: '$_dir/rust.svg',
    lessonPoint: 1,
  );
  static const missedCover = DoMistake(
    key: '4.6/m4_earth_test/missed-pit-cover',
    textBn: 'একটা আর্থ পিটের কভার নেই — চোখ এড়িয়ে গেল। পিটের চারপাশ পরিষ্কার আর কভার ঠিকমতো লাগানো কি না দেখুন।',
    art: '$_dir/cover.svg',
    lessonPoint: 1,
  );
  static DoMistake missed(M4EarthTestFault f) => switch (f) {
        M4EarthTestFault.cut => missedCut,
        M4EarthTestFault.rust => missedRust,
        M4EarthTestFault.cover => missedCover,
      };

  static const leadsFirst = DoMistake(
    key: '4.6/m4_earth_test/leads-before-spikes',
    textBn: 'স্পাইক না পুঁতেই লিড জুড়তে গেলেন। আগে দুটি অস্থায়ী স্পাইক মাটিতে পুঁতুন, তারপর টেস্টারের লিড জুড়ে সার্কিট তৈরি করুন।',
    art: '$_dir/spikes.svg',
    lessonPoint: 2,
  );
  static const testEarly = DoMistake(
    key: '4.6/m4_earth_test/test-before-circuit',
    textBn: 'সার্কিট তৈরির আগেই TEST চাপলেন। দুটি স্পাইক পুঁতে, লিড জুড়ে তবেই টেস্টার সরাসরি ওহমে মান দেখায়।',
    art: '$_dir/test.svg',
    lessonPoint: 2,
  );
  static const passedHigh = DoMistake(
    key: '4.6/m4_earth_test/high-reading-passed',
    textBn: 'বেশি মানকে ঠিক লিখলেন। সাধারণ ডিস্ট্রিবিউশন লাইনে আর্থ রেজিস্ট্যান্স 5–8 ওহমের কম চাই — এর বেশি মানে আর্থিং দুর্বল, রক্ষণাবেক্ষণ দরকার।',
    art: '$_dir/reading.svg',
    lessonPoint: 2,
  );
  static const flaggedGood = DoMistake(
    key: '4.6/m4_earth_test/good-reading-flagged',
    textBn: 'ভালো মানকে বেশি লিখলেন। সাধারণ ডিস্ট্রিবিউশন লাইনে 5–8 ওহমের কম মানই ভালো — রেজিস্ট্যান্স যত কম, তত ভালো।',
    art: '$_dir/reading.svg',
    lessonPoint: 2,
  );
  static const eyesOnly = DoMistake(
    key: '4.6/m4_earth_test/eyes-only',
    textBn: 'শুধু চাক্ষুষ পরিদর্শন যথেষ্ট নয়। আর্থ রেজিস্ট্যান্স টেস্টার দিয়ে ওহম মেপেই আর্থিং-এর আসল কার্যকারিতা বোঝা যায়।',
    art: '$_dir/eyes.svg',
    lessonPoint: 2,
  );

  /// The lesson's myth 1 (the myth buster is not a lesson point: "পাঠে দেখুন"
  /// opens the lesson from its start).
  static const lineRuns = DoMistake(
    key: '4.6/m4_earth_test/line-runs-myth',
    textBn: 'মারাত্মক ভুল। লাইন স্বাভাবিক অবস্থায় চলবে, কিন্তু ফল্টের সময় আর্থিং কাজ না করলে ব্রেকার ট্রিপ করবে না — ছোট সমস্যা প্রাণহানির কারণ হতে পারে।',
    art: '$_dir/myth.svg',
  );

  static List<DoMistake> get all => [missedCut, missedRust, missedCover, leadsFirst, testEarly, passedHigh, flaggedGood, eyesOnly, lineRuns];
}

/// Good readings (Ω) for a distribution line earth, and high ones.
const m4EarthTestGoodOhms = [1.8, 2.2, 2.5, 3.1, 3.6, 4.2];
const m4EarthTestHighOhms = [12.0, 14.5, 18.0, 22.0, 27.5];

/// The lesson's value for a distribution line: less than 5–8 Ω. The deal
/// never reads between 5 and 8 (the lesson gives a range, not one number).
bool m4EarthTestIsHigh(double ohms) => ohms > 8;

/// One play: the visual faults, the two pits tested (one neutral, one body,
/// in order) with their readings, and which push the coworker makes.
@immutable
class M4EarthTestDeal {
  const M4EarthTestDeal({required this.faults, required this.pits, required this.ohms, required this.runsPush});

  final Map<int, M4EarthTestFault> faults;

  /// The two pits to test, in order.
  final List<int> pits;

  /// Their readings (Ω), aligned with [pits]: one good, one high.
  final List<double> ohms;

  /// true: "the line runs, write it OK" on the high reading; false: "eyes
  /// are enough" before the first test.
  final bool runsPush;

  int get highAt => m4EarthTestIsHigh(ohms[0]) ? 0 : 1;
}

M4EarthTestDeal m4EarthTestDeal(math.Random rng) {
  final idx = [0, 1, 2, 3]..shuffle(rng);
  final n = 1 + rng.nextInt(2);
  final kinds = [...M4EarthTestFault.values]..shuffle(rng);
  final faults = {for (var k = 0; k < n; k++) idx[k]: kinds[k]};
  final pits = [rng.nextInt(2), 2 + rng.nextInt(2)];
  if (rng.nextBool()) {
    final a = pits[0];
    pits[0] = pits[1];
    pits[1] = a;
  }
  final good = m4EarthTestGoodOhms[rng.nextInt(m4EarthTestGoodOhms.length)];
  final high = m4EarthTestHighOhms[rng.nextInt(m4EarthTestHighOhms.length)];
  final ohms = rng.nextBool() ? [good, high] : [high, good];
  return M4EarthTestDeal(faults: faults, pits: pits, ohms: ohms, runsPush: rng.nextBool());
}

/// The play state (pure logic).
class M4EarthTestRun {
  M4EarthTestRun(this.deal);
  final M4EarthTestDeal deal;

  M4EarthTestStation station = M4EarthTestStation.look;
  int slips = 0;
  int stationSlips = 0;
  final List<String> caught = [];

  // look
  final Set<int> spotted = {};

  // the pit under test
  int spikes = 0;
  bool leads = false;
  bool tested = false;
  bool marked = false;
  final Map<int, M4EarthTestMark> marks = {};

  bool finished = false;

  bool get ended => finished;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && percent >= 55;
  bool get clean => stationSlips == 0;

  /// 0 or 1 while testing a pit.
  int get testIndex => station == M4EarthTestStation.pitB ? 1 : 0;
  int? get testPit => station == M4EarthTestStation.look ? null : deal.pits[testIndex];
  double get reading => deal.ohms[testIndex];
  bool get readingHigh => m4EarthTestIsHigh(reading);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  /// Tap earth point [i] while looking: true = a fault, tagged now.
  bool tapEarth(int i) {
    if (station != M4EarthTestStation.look) return false;
    if (!deal.faults.containsKey(i) || spotted.contains(i)) return false;
    spotted.add(i);
    return true;
  }

  /// "দেখা শেষ": a fault not yet tagged is a slip.
  DoMistake? lookDone() {
    if (station != M4EarthTestStation.look) return null;
    for (final e in deal.faults.entries) {
      if (!spotted.contains(e.key)) return _slip(M4EarthTestMistakes.missed(e.value));
    }
    _tag(M4EarthTestLines.caughtLook);
    return null;
  }

  /// A spike driven into its place; true = driven.
  bool driveSpike() {
    if (testPit == null || tested || spikes >= 2) return false;
    spikes++;
    return true;
  }

  /// The tester's leads to the electrode and the two spikes.
  DoMistake? connectLeads() {
    if (testPit == null || leads || tested) return null;
    if (spikes < 2) return _slip(M4EarthTestMistakes.leadsFirst);
    leads = true;
    return null;
  }

  /// TEST: only on a made circuit.
  DoMistake? pressTest() {
    if (testPit == null || tested) return null;
    if (!leads) return _slip(M4EarthTestMistakes.testEarly);
    tested = true;
    _tag(M4EarthTestLines.caughtRig);
    return null;
  }

  /// The reading written down: [high] = "মান বেশি".
  DoMistake? mark({required bool high}) {
    if (testPit == null || !tested || marked) return null;
    if (high != readingHigh) return _slip(readingHigh ? M4EarthTestMistakes.passedHigh : M4EarthTestMistakes.flaggedGood);
    marked = true;
    marks[testPit!] = M4EarthTestMark(reading, high: high);
    _tag(high ? M4EarthTestLines.caughtHigh : M4EarthTestLines.caughtOk);
    return null;
  }

  /// Listened to the coworker.
  DoMistake listen() => _slip(deal.runsPush ? M4EarthTestMistakes.lineRuns : M4EarthTestMistakes.eyesOnly);

  /// On to the next station (after the last pit: the play is done).
  void next() {
    stationSlips = 0;
    spikes = 0;
    leads = false;
    tested = false;
    marked = false;
    switch (station) {
      case M4EarthTestStation.look:
        station = M4EarthTestStation.pitA;
      case M4EarthTestStation.pitA:
        station = M4EarthTestStation.pitB;
      case M4EarthTestStation.pitB:
        finished = true;
    }
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
///   look: ~2 taps + done ~4000 + reason ~8200                        12200
///   a pit: 2 spikes + leads + TEST ~4000, reading 1600, mark 1500,
///     reason ~8200 → 15300 × 2                                       30600
///   the coworker: his line ~3500 + deck 910 + pick 3500              7900
///   ≈ 50700 ms; 85 % ≈ 43100 → 45 s.
const kM4EarthTestQuickMs = 45000;

@immutable
class M4EarthTestPack {
  const M4EarthTestPack({required this.id, required this.titleBn, this.quickMs = kM4EarthTestQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m4EarthTestPacks = {
  'do_4_6_a': M4EarthTestPack(id: 'do_4_6_a', titleBn: M4EarthTestLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4EarthTestPage extends StatefulWidget {
  const M4EarthTestPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M4EarthTestPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4EarthTestPage> createState() => _M4EarthTestPageState();
}

class _M4EarthTestPageState extends State<M4EarthTestPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _EarthRunPage(
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

class _EarthRunPage extends ConsumerStatefulWidget {
  const _EarthRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4EarthTestPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_EarthRunPage> createState() => _EarthRunPageState();
}

class _EarthRunPageState extends ConsumerState<_EarthRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4EarthTestRun _run = M4EarthTestRun(m4EarthTestDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The tester's display counting up to the reading.
  late final AnimationController _meter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _settled();
    });

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  var _shown = false;
  final List<(int, Offset)> _taps = [];
  int _tapN = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _meter.dispose();
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

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  String get _task {
    final pit = _run.testPit;
    if (pit == null) return M4EarthTestLines.askLook;
    return _run.tested ? M4EarthTestLines.askRead : M4EarthTestLines.askRig(pit);
  }

  void _start() {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  /// The coworker's moment is due now: the tools wait for him.
  bool get _coworkerDue {
    if (coworkerDone) return false;
    if (_run.deal.runsPush) return _run.testIndex == _run.deal.highAt && _run.tested && _shown && !_run.marked && _run.testPit != null;
    return _run.station == M4EarthTestStation.pitA && !_run.leads;
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !coworkerOpen && !struckOut && !_coworkerDue;

  // --- taps on the scene -------------------------------------------------------------
  void _tapScene(Offset p, M4EarthTestGeo geo, Offset global) {
    if (!_canPlay) return;
    if (_run.station == M4EarthTestStation.look) {
      for (var i = 0; i < 4; i++) {
        if (geo.earthRect(i).contains(p)) {
          if (_run.tapEarth(i)) {
            HapticFeedback.mediumImpact();
            _cue('sounds/learn/tag_slap.wav', volume: 0.6);
            setState(() => _wake++);
            return;
          }
          break;
        }
      }
    } else if (!_run.tested && _run.spikes < 2) {
      for (var k = 0; k < 2; k++) {
        if (k == _run.spikes && geo.spikeRect(k).contains(p)) {
          _run.driveSpike();
          HapticFeedback.heavyImpact();
          _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
          setState(() => _wake++);
          return;
        }
      }
    }
    _plainTap(p);
  }

  void _plainTap(Offset p) {
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    setState(() {
      _taps.add((_tapN++, p));
      if (_taps.length > 4) _taps.removeAt(0);
    });
  }

  Future<void> _lookDone(Offset origin) async {
    if (!_canPlay || _run.station != M4EarthTestStation.look) return;
    final m = _run.lookDone();
    if (m != null) {
      await _slipOut(m, origin);
      return;
    }
    _stationRight(origin);
  }

  Future<void> _connect(Offset origin) async {
    if (!_canPlay || _run.testPit == null || _run.tested) return;
    final m = _run.connectLeads();
    if (m != null) {
      await _slipOut(m, origin);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.7);
    setState(() => _wake++);
  }

  Future<void> _test(Offset origin) async {
    if (!_canPlay || _run.testPit == null || _run.tested) return;
    final m = _run.pressTest();
    if (m != null) {
      await _slipOut(m, origin);
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.wav', volume: 0.5);
    setState(() {
      _shown = false;
      _wake++;
    });
    if (_quiet) {
      _meter.value = 1;
      _settled();
    } else {
      unawaited(_meter.forward(from: 0));
    }
  }

  void _settled() {
    if (!mounted || _shown || !_run.tested) return;
    _cue('sounds/intro/tick.ogg', volume: 0.6);
    setState(() => _shown = true);
    if (_coworkerDue) {
      scheduleCoworker();
    } else {
      unawaited(_sayChain([M4EarthTestLines.askRead]));
    }
  }

  Future<void> _markIt(bool high, Offset origin) async {
    if (!_canPlay || !_shown || _run.marked) return;
    final m = _run.mark(high: high);
    if (m != null) {
      await _slipOut(m, origin);
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.6);
    setState(() => _wake++);
    _stationRight(origin);
  }

  // --- a station done right: the ◆ and the reason ---------------------------------
  void _stationRight(Offset origin) {
    _hush();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    final station = _run.station;
    final look = station == M4EarthTestStation.look;
    final high = !look && _run.readingHigh;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(
          look
              ? M4EarthTestLines.lookRight
              : high
                  ? M4EarthTestLines.highRight
                  : M4EarthTestLines.okRight,
          M4EarthTestLines.excuses,
          widget.rng),
      question: look
          ? M4EarthTestLines.whyLook
          : high
              ? M4EarthTestLines.whyHigh
              : M4EarthTestLines.whyOk,
      stillValid: () => _run.station == station && !_ended,
    ));
  }

  void _nextStation() {
    _run.next();
    if (_run.finished) {
      unawaited(_finish());
      return;
    }
    _meter.value = 0;
    setState(() {
      _shown = false;
      _taps.clear();
      _wake++;
    });
    unawaited(_sayChain([_task]));
    if (!_run.deal.runsPush && _run.station == M4EarthTestStation.pitA) scheduleCoworker();
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
    final st = _run.station;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.station == st) _nextStation();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _run.deal.runsPush ? M4EarthTestLines.coworkerRuns : M4EarthTestLines.coworkerSkip;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (!_coworkerDue) return _run.station == M4EarthTestStation.pitB && _run.marked ? null : false;
    if (_intro || _card != null || reasonOpen || struckOut) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      await _slipOut(_run.listen(), origin);
      return;
    }
    _run.caught.add(M4EarthTestLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (mounted && !_ended) unawaited(_sayChain([_task]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4EarthTestLines.tapWhy[_nudgeN++ % M4EarthTestLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _slipOut(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m4_earth_test/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _finish() async {
    if (_mark != null || _ended) return;
    _ended = true;
    _clock.stop();
    setState(() => _wake++);
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
    await _say(!_run.passed ? M4EarthTestLines.fail : (_quickBonus ? M4EarthTestLines.quick : M4EarthTestLines.allSet),
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
    if (_mark != null && _passed) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  M4EarthTestView get _view => M4EarthTestView(
        faults: _run.deal.faults,
        spotted: {..._run.spotted},
        testPit: _run.testPit,
        spikes: _run.spikes,
        leads: _run.leads,
        marks: {..._run.marks},
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = M4EarthTestGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final spiking = _run.testPit != null && !_run.tested && _run.spikes < 2 && _canPlay;
    return [
      Positioned.fill(
        key: const ValueKey('land'),
        child: RepaintBoundary(child: CustomPaint(painter: M4EarthTestWorldPainter(geo: geo, view: _view))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      for (final (id, p) in _taps)
        Positioned(
          key: ValueKey('tap-$id'),
          left: p.dx - 14,
          top: p.dy - 14,
          width: 28,
          height: 28,
          child: IgnorePointer(child: _Ring(quiet: quiet)),
        ),
      if (spiking)
        Positioned.fromRect(
          key: ValueKey('spike-${_run.spikes}'),
          rect: geo.spikeRect(_run.spikes),
          child: IgnorePointer(child: _Ring(quiet: quiet, big: true)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4EarthTestLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended && !_coworkerDue;
    final st = _run.station;
    final looking = handsOn && st == M4EarthTestStation.look && !reasonOpen;
    final testing = st != M4EarthTestStation.look && playing && !_run.ended;
    final rigTray = handsOn && testing && !_run.tested;
    final marking = handsOn && testing && _run.tested && _shown && !_run.marked;
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
              labels: M4EarthTestLines.rounds,
              done: {for (var i = 0; i < st.index; i++) i, if (_run.finished) 2},
              current: _run.finished ? null : st.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: const IgnorePointer(child: _DocketChip()),
                ),
              if (testing)
                Positioned(
                  key: const ValueKey('hud-tester'),
                  right: 10,
                  top: pad.top + 96,
                  width: 150,
                  child: _TesterPanel(
                    meter: _meter,
                    ohms: _run.tested ? _run.reading : null,
                    live: _run.leads,
                    onTest: rigTray ? (d) => unawaited(_test(d.globalPosition)) : null,
                  ),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (looking)
                Positioned(
                  key: const ValueKey('hud-look'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      const Spacer(flex: 2),
                      Expanded(
                        flex: 3,
                        child: DoBigButton(
                          label: M4EarthTestLines.lookDone,
                          filled: true,
                          onTapUp: (d) => unawaited(_lookDone(d.globalPosition)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (rigTray)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: _Chip(
                    label: M4EarthTestLines.leads,
                    icon: Icons.cable_rounded,
                    done: _run.leads,
                    onTapUp: (d) => unawaited(_connect(d.globalPosition)),
                  ),
                ),
              if (marking)
                Positioned(
                  key: const ValueKey('hud-mark'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: DoBigButton(
                          label: M4EarthTestLines.markOk,
                          filled: false,
                          onDark: true,
                          onTapUp: (d) => unawaited(_markIt(false, d.globalPosition)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DoBigButton(
                          label: M4EarthTestLines.markHigh,
                          filled: false,
                          onDark: true,
                          onTapUp: (d) => unawaited(_markIt(true, d.globalPosition)),
                        ),
                      ),
                    ],
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${st.name}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
                  quiet: quiet,
                  onRead: () {
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
                  line: M4EarthTestLines.intro,
                  alarm: null,
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _start();
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

/// The docket: the job and the place (words a worker reads).
class _DocketChip extends StatelessWidget {
  const _DocketChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M4EarthTestLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4EarthTestLines.job, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          Text(M4EarthTestLines.site, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E4F6B))),
        ],
      ),
    );
  }
}

/// The earth tester close up: its display (counting, then the reading in Ω)
/// and its TEST button.
class _TesterPanel extends StatelessWidget {
  const _TesterPanel({required this.meter, required this.ohms, required this.live, required this.onTest});
  final Animation<double> meter;
  final double? ohms;
  final bool live;
  final GestureTapUpCallback? onTest;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M4EarthTestLines.tester,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7C21A), Color(0xFFDDA204)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6B5208), width: 1.6),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              width: double.infinity,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFF233127), borderRadius: BorderRadius.circular(6)),
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: meter,
                  builder: (_, _) {
                    final o = ohms;
                    final String s;
                    if (o == null) {
                      s = live ? '0.0 Ω' : '- - -';
                    } else if (meter.value < 1) {
                      // Counting up, the last digits restless until it settles.
                      final v = o * Curves.easeOut.transform(meter.value) * (1 + 0.15 * math.sin(meter.value * 40) * (1 - meter.value));
                      s = '${v.toStringAsFixed(1)} Ω';
                    } else {
                      s = '${m4EarthTestOhms(o)} Ω';
                    }
                    return Text(s, style: bangla(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF9CF2A6), height: 1.1));
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: M4EarthTestLines.test,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: onTest,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: onTest == null ? const Color(0xFF8E3A2E) : const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF4A120C), width: 1.6),
                  ),
                  child: const Text(M4EarthTestLines.test, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tool chip (the leads).
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, required this.done, required this.onTapUp});
  final String label;
  final IconData icon;
  final bool done;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = done ? SlmColors.success : const Color(0x99FFFFFF);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: done ? null : onTapUp,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ring, width: 1.6),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(done ? Icons.check_circle_rounded : icon, size: 22, color: ring),
              const SizedBox(width: 6),
              Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain white ring (a tap, or a place for a spike).
class _Ring extends StatelessWidget {
  const _Ring({required this.quiet, this.big = false});
  final bool quiet;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.scale(scale: 1.4 - 0.4 * v, child: Opacity(opacity: (0.4 + 0.6 * v).clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: big ? const Color(0x33FFFFFF) : const Color(0x22FFFFFF),
          border: Border.all(color: const Color(0xEEFFFFFF), width: big ? 2.6 : 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
        ),
      ),
    );
  }
}
