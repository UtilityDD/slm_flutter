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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_megger_read_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.7 "'মেগার' (Megger) কী ও কেন?", কাজ 2 "পড়ুন আর ছাড়ুন". The pump
// cable is disconnected (the panel's isolator OFF, padlocked, tagged; the
// lugs lifted off) and has to be tested before it goes back in service: three
// rounds a play, one core (R, Y, B — any order) each, against the armour.
// Hands on, in the room: check the tester (battery, leads) → discharge the
// core with the earthed rod → E clip on the armour, L clip on the core → the
// selector on the test voltage for the docket's 415 V (500 V) → hold TEST for
// the full minute → read the needle (MΩ) → ভালো or দুর্বল → discharge the core
// again → only then take the L clip off.
//
// The lesson's rules, and only those:
//   • point 1, daily check: battery level and the test leads (insulation intact);
//   • point 2, step 1: disconnect and discharge first; using a megger without
//     discharging is strictly forbidden; step 2: L on the conductor, E on the
//     armour; step 3: test voltage by the operating voltage (500 V for 415 V);
//     step 4: hold TEST for the set time (usually 1 minute), note MΩ / GΩ;
//   • point 3: the higher the IR the better; 1 MΩ is the minimum safe value
//     (Indian Electricity Rules), below it the insulation is weak / damp /
//     damaged and unsafe; after the test discharge again — the test voltage
//     stays in the cable as a charge.
// Readings are dealt well clear of 1 MΩ (≥ 250 MΩ or ≤ 0.6 MΩ), so the read
// never sits on the line. Phase-to-phase tests are NOT in the lesson (only
// conductor-to-armour) and are left out (flagged in REGISTER.md).
//
// Deadly (candidate, flagged for the owner): taking the L clip off a core
// still charged by the test — also on the coworker's "রিডিং হয়ে গেছে, তার খুলে
// নাও". Slips: testing unchecked / with a cracked lead or a weak battery, the L
// clip on a core not discharged, the clips swapped, the wrong test voltage,
// letting go of TEST before the minute, a wrong verdict. Three slips strike
// out. Needless acts (a fix where nothing was wrong, discharging a core that
// was not charged) are not scored.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m2_megger_read_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next core by itself; the careless coworker once a play, on round 2 or
// 3, right after the minute's test.
// Voice: the guide's lines by device TTS; the coworker's push is a new line
// (device TTS until recorded, see M2MeggerLines.coworker); his exit line is
// his recorded "হুঁ! যা খুশি করুন।".

// ============================================================================
// Content
// ============================================================================

/// A fault on the tester (the daily check).
enum MeggerFault { none, lead, battery }

/// What the player has in hand.
enum MeggerHold { none, lClip, eClip, rod }

abstract final class M2MeggerLines {
  static const title = 'পড়ুন আর ছাড়ুন';
  static const intro = 'পাম্পের কেবিল আবার চালুর আগে মেগার দিয়ে তিনটে কোরই মাপতে হবে — নিয়ম মেনে!';
  static const ask = 'একটা কোর মাপুন, রিডিং পড়ে বলুন — তারপর তার ছাড়ুন।';
  static const tasks = [ask];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const rounds = ['ক', 'খ', 'গ'];

  // Labels a worker reads.
  static const sceneLabel = 'কেবিল আর মেগার';
  static const testLabel = 'TEST';
  static const check = 'যাচাই';
  static const rod = 'ডিসচার্জ রড';
  static const good = 'ইনসুলেশন ভালো';
  static const weak = 'ইনসুলেশন দুর্বল';
  static const docket = 'ডকেট';
  static const docketJob = 'পাম্পের কেবিল · 415 V';
  static const kitTitle = 'মেগার যাচাই';
  static const battery = 'ব্যাটারি';
  static const leads = 'টেস্ট লিড';
  static const newLead = 'লিড বদলাই';
  static const newBattery = 'ব্যাটারি বদলাই';
  static const kitOk = 'ঠিক আছে';
  static const idleReadout = '- - -';
  static String seconds(int s) => enDigits('$s s');
  static String volts(int v) => enDigits('$v V');

  /// A reading as the tester shows it.
  static String reading(double mohm) {
    if (mohm >= 1000) {
      final g = mohm / 1000;
      return enDigits('${g == g.roundToDouble() ? g.toStringAsFixed(0) : g.toStringAsFixed(1)} GΩ');
    }
    return enDigits('${mohm >= 1 ? mohm.toStringAsFixed(0) : mohm.toStringAsFixed(mohm < 0.1 ? 2 : 1)} MΩ');
  }

  // The reasons. Right ones state the lesson's rule for what he did; wrong
  // ones are myths (the lesson's own) and field excuses — never a true rule.
  static const whyGood = 'কেন ইনসুলেশন ভালো বললেন?';
  static const whyWeak = 'কেন ইনসুলেশন দুর্বল বললেন?';
  static const whyDischarge = 'কেন আগে ডিসচার্জ করলেন?';
  static const goodRight = [
    'রিডিং 1 MΩ-এর অনেক ওপরে, ইনসুলেশন ভালো',
    'আইআর যত বেশি, ইনসুলেশন তত ভালো থাকে',
    'শত শত MΩ মানে ইনসুলেশন সুস্থ আর শুকনো',
  ];
  static const goodWrong = [
    'মাল্টিমিটারে ইনফিনিটি দেখালেই কেবিল ঠিক',
    'কেবিলটা দেখতে নতুন, তাই ঠিকই আছে ধরলাম',
    'পাম্প কাল পর্যন্ত চলছিল, তাই চিন্তা নেই',
    'কাঁটা একটু নড়লেই ইনসুলেশন ভালো ধরা হয়',
    'সুপারভাইজার তাড়া দিচ্ছেন, তাই ভালো লিখলাম',
    'রিডিং দেখার দরকার নেই, তার তো অক্ষত',
  ];
  static const weakRight = [
    '1 MΩ-এর কম মানে ইনসুলেশন দুর্বল বা ভেজা',
    '1 MΩ-এর নিচে কেবিল ব্যবহারে নিরাপদ নয়',
    'কম আইআর আগেভাগে বড় ফল্টের সতর্কবার্তা',
  ];
  static const weakWrong = [
    'রিডিং কম মানে মেগারটাই খারাপ হয়ে গেছে',
    'কেবিলটা পুরনো দেখতে, তাই ফল্ট বললাম',
    'রিডিং যত বেশি, ইনসুলেশন তত খারাপ হয়',
    'কম রিডিং মানে কেবিলে এখন কারেন্ট নেই',
    'কাঁটা নড়েনি, তাই আন্দাজে ফল্ট বললাম',
    'ফল্ট বললে আজ আর কাজ করতে হবে না',
  ];
  static const dischargeRight = [
    'টেস্টের ভোল্টেজ কেবিলে চার্জ হয়ে জমে থাকে',
    'মেগারের উচ্চ ভোল্টেজ কোরে চার্জ রেখে যায়',
    'ডিসচার্জ না করে খুললে জমা চার্জে শক লাগে',
  ];
  static const dischargeWrong = [
    'মেগার ছেড়ে দিলেই কেবিলের সব চার্জ চলে যায়',
    'রিডিং হয়ে গেলে কেবিলে আর কিছু থাকে না',
    'ডিসচার্জ শুধু হাই-ভোল্টেজ লাইনেই লাগে',
    'ও দেখছিল, তাই নিয়মটা দেখিয়ে দিলাম',
    'রড হাতে নিলে কাজটা দেখতে বেশ ভালো লাগে',
    'কেবিল বিচ্ছিন্ন, তাতে চার্জ থাকতেই পারে না',
  ];

  /// The careless coworker: pull the lead now (new line: device TTS until
  /// recorded); refused, his recorded snarl.
  static const coworker = CoworkerScript(
    line: 'রিডিং তো হয়ে গেছে, তার খুলে নাও! ডিসচার্জ-টিসচার্জ লাগবে না।',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, আগে ডিসচার্জ করে তবে লিড খুলব', 'না, কোরে চার্জ জমে আছে, আগে ডিসচার্জ', 'আগে রড ছোঁয়াব, তারপর ক্লিপ খুলব'],
    wrong: ['ঠিক, রিডিং তো হয়েই গেছে, খুলে ফেলি', 'আচ্ছা, তাড়াতাড়ি ক্লিপটা খুলে নিই', 'কেবিল বিচ্ছিন্ন, ডিসচার্জ লাগবে না', 'ঠিক আছে, শুধু লাল ক্লিপটা খুলি', 'সবাই তো এভাবেই সোজা খুলে নেয়'],
    asks: ['ও বলছে এখনই তার খুলতে। আপনি কী করবেন?', 'রিডিং হয়ে গেছে। এখন কী করবেন?', 'খুলবেন, নাকি আগে অন্য কিছু?'],
  );

  static const allSet = 'তিনটে কোরই নিয়ম মেনে মাপলেন — পড়লেন, ডিসচার্জ করলেন, তবে ছাড়লেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — যাচাই, ডিসচার্জ, লিড, ভোল্টেজ, এক মিনিট, রিডিং, আবার ডিসচার্জ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtKit = 'মেগার আর লিড আগে যাচাই';
  static const caughtFirst = 'আগে ডিসচার্জ, তারপর লিড';
  static const caughtVolts = '415 V কেবিলে 500 V টেস্ট';
  static const caughtMinute = 'পুরো 1 মিনিট টেস্ট';
  static const caughtGood = 'ভালো রিডিং চিনেছেন';
  static const caughtWeak = '1 MΩ-এর কম মানে ফল্ট';
  static const caughtAfter = 'টেস্টের পর ডিসচার্জ, তবে খোলা';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M2MeggerMistakes {
  static const _dir = 'assets/game/art/m2_megger_read';

  static const unchecked = DoMistake(
    key: '2.7/megger/unchecked',
    textBn: 'ব্যবহারের আগে মেগারের ব্যাটারি আর টেস্ট লিড দেখে নিন — লিডের ইনসুলেশন যেন পুরো অক্ষত থাকে।',
    art: '$_dir/kit_check.svg',
    lessonPoint: 0,
  );
  static const badKit = DoMistake(
    key: '2.7/megger/bad-kit',
    textBn: 'ফাটা লিড বা দুর্বল ব্যাটারি নিয়ে টেস্ট নয়। মেগার নিজেই উচ্চ ভোল্টেজের উৎস — আগে বদলে নিন।',
    art: '$_dir/kit_check.svg',
    lessonPoint: 0,
  );
  static const dischargeFirst = DoMistake(
    key: '2.7/megger/discharge-first',
    textBn: 'আগে বিচ্ছিন্ন করে ভালোভাবে ডিসচার্জ, তারপর লিড। ডিসচার্জ না করে মেগার লাগানো কঠোরভাবে নিষিদ্ধ।',
    art: '$_dir/discharge_first.svg',
    lessonPoint: 1,
  );
  static const wrongLead = DoMistake(
    key: '2.7/megger/wrong-lead',
    textBn: "'লাইন' (L) লিড কন্ডাক্টরে, 'আর্থ' (E) লিড কেবিলের আর্মারে।",
    art: '$_dir/wrong_lead.svg',
    lessonPoint: 1,
  );
  static const wrongVolts = DoMistake(
    key: '2.7/megger/wrong-voltage',
    textBn: 'সরঞ্জামের অপারেটিং ভোল্টেজ দেখে টেস্ট ভোল্টেজ — 415 V সিস্টেমে 500 V।',
    art: '$_dir/volts.svg',
    lessonPoint: 1,
  );
  static const shortTest = DoMistake(
    key: '2.7/megger/short-test',
    textBn: "'টেস্ট' বাটন পুরো সময় — সাধারণত 1 মিনিট — চেপে রাখুন, তারপর MΩ রিডিং নোট করুন।",
    art: '$_dir/one_minute.svg',
    lessonPoint: 1,
  );
  static const misread = DoMistake(
    key: '2.7/megger/misread',
    textBn: 'আইআর যত বেশি, ইনসুলেশন তত ভালো। 1 MΩ ন্যূনতম নিরাপদ মান — এর কম মানে দুর্বল, আর্দ্র বা ক্ষতিগ্রস্ত।',
    art: '$_dir/reading.svg',
    lessonPoint: 2,
  );
  static const charged = DoMistake(
    key: '2.7/megger/no-discharge-after',
    textBn: 'টেস্টের পর আগে ডিসচার্জ, তারপর লিড খুলুন — মেগারের টেস্ট ভোল্টেজ কেবিলে চার্জ হয়ে জমে থাকে।',
    art: '$_dir/charged.svg',
    deadly: true,
    lessonPoint: 2,
  );

  static const all = [unchecked, badKit, dischargeFirst, wrongLead, wrongVolts, shortTest, misread, charged];
}

/// Good readings (MΩ) — well above 1 MΩ; weak ones — well below.
const kMeggerGood = [250.0, 500.0, 850.0, 1200.0, 2000.0];
const kMeggerWeak = [0.05, 0.2, 0.4, 0.6];

@immutable
class MeggerDeal {
  const MeggerDeal({required this.readings, required this.fault, required this.startVolts, required this.callAt});

  /// Each core's IR to the armour (MΩ): R, Y, B.
  final List<double> readings;
  final MeggerFault fault;

  /// Where the selector was left (the last job).
  final int startVolts;

  /// The round the careless coworker comes on (1 or 2).
  final int callAt;

  bool weak(int core) => readings[core] < 1;
}

/// One or two weak cores; the tester's fault (a cracked lead 2 in 5, a weak
/// battery 1 in 5, none 2 in 5); the selector left at 500 V 1 in 3 plays.
MeggerDeal dealMegger(math.Random rng) {
  final weakN = 1 + rng.nextInt(2);
  final order = [0, 1, 2]..shuffle(rng);
  final weakSet = order.take(weakN).toSet();
  final readings = [
    for (var i = 0; i < 3; i++) weakSet.contains(i) ? kMeggerWeak[rng.nextInt(kMeggerWeak.length)] : kMeggerGood[rng.nextInt(kMeggerGood.length)],
  ];
  final f = rng.nextInt(5);
  final fault = f < 2 ? MeggerFault.lead : (f < 3 ? MeggerFault.battery : MeggerFault.none);
  final volts = rng.nextInt(3) == 0 ? 500 : meggerVolts[1 + rng.nextInt(3)];
  return MeggerDeal(readings: readings, fault: fault, startVolts: volts, callAt: 1 + rng.nextInt(2));
}

/// The play state (pure logic).
class MeggerRun {
  MeggerRun(this.deal) : volts = deal.startVolts;
  final MeggerDeal deal;

  int volts;
  var checked = false;
  var fixed = false;

  /// Cores holding a charge (at the start: just cut off the supply).
  final Set<int> charged = {0, 1, 2};
  int? lOn;
  var eOn = false;
  var testing = false;

  /// The core the last full test was on (its reading is on the display).
  int? readFor;
  final Map<int, bool> verdicts = {};
  final Set<int> completed = {};
  int slips = 0;
  var roundSlip = false;
  DoMistake? deadly;
  final List<String> caught = [];

  int get round => completed.length;
  bool get done => completed.length >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get kitOk => deal.fault == MeggerFault.none || fixed;
  bool get leadCracked => deal.fault == MeggerFault.lead && !fixed;
  bool get batteryLow => deal.fault == MeggerFault.battery && !fixed;

  /// The verdict is still to give for the reading on the display.
  bool get verdictDue => readFor != null && !verdicts.containsKey(readFor);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlip = true;
    return m;
  }

  void openCheck() {
    if (!ended) checked = true;
  }

  /// A fix on the tester; needless ones change nothing (not scored).
  void fix(MeggerFault f) {
    if (!ended && f == deal.fault) fixed = true;
  }

  void turnKnob() {
    if (ended || testing) return;
    volts = meggerVolts[(meggerVolts.indexOf(volts) + 1) % meggerVolts.length];
  }

  /// The rod on [core]: true when it held a charge (the spark).
  bool discharge(int core) {
    if (ended || testing) return false;
    return charged.remove(core);
  }

  /// The E clip on the armour (right) or on a core (swapped: a slip).
  DoMistake? clipE({required bool armour}) {
    if (ended || eOn) return null;
    if (!armour) return _slip(M2MeggerMistakes.wrongLead);
    eOn = true;
    return null;
  }

  /// The L clip on [core] (null: on the armour — swapped). False in the
  /// record = nothing happened (a finished core).
  DoMistake? clipL(int? core) {
    if (ended || lOn != null) return null;
    if (core == null) return _slip(M2MeggerMistakes.wrongLead);
    if (completed.contains(core)) return null;
    if (charged.contains(core)) return _slip(M2MeggerMistakes.dischargeFirst);
    lOn = core;
    if (readFor != core) readFor = null;
    _tag(M2MeggerLines.caughtFirst);
    return null;
  }

  void unclipE() {
    if (!ended && !testing) eOn = false;
  }

  /// The L clip off its core: deadly while the core is charged.
  DoMistake? unclipL() {
    final c = lOn;
    if (ended || testing || c == null) return null;
    if (charged.contains(c)) return deadly = M2MeggerMistakes.charged;
    lOn = null;
    if (readFor == c) _tag(M2MeggerLines.caughtAfter);
    return null;
  }

  /// Whether TEST can run at all (both clips on).
  bool get circuit => lOn != null && eOn;

  /// TEST pressed: a slip if the tester was not checked, is faulty, or is on
  /// the wrong voltage; otherwise the test runs and charges the core.
  DoMistake? startTest() {
    if (ended || testing || !circuit) return null;
    if (!checked) return _slip(M2MeggerMistakes.unchecked);
    if (!kitOk) return _slip(M2MeggerMistakes.badKit);
    if (volts != 500) return _slip(M2MeggerMistakes.wrongVolts);
    testing = true;
    charged.add(lOn!);
    readFor = null;
    _tag(M2MeggerLines.caughtKit);
    _tag(M2MeggerLines.caughtVolts);
    return null;
  }

  /// TEST let go: [full] = after the minute (the reading stands).
  DoMistake? endTest({required bool full}) {
    if (!testing) return null;
    testing = false;
    if (!full) return _slip(M2MeggerMistakes.shortTest);
    readFor = lOn;
    _tag(M2MeggerLines.caughtMinute);
    return null;
  }

  /// ভালো ([good]) or দুর্বল for the reading on the display.
  DoMistake? verdict({required bool good}) {
    final c = readFor;
    if (ended || c == null || verdicts.containsKey(c)) return null;
    if (good == deal.weak(c)) return _slip(M2MeggerMistakes.misread);
    verdicts[c] = good;
    _tag(good ? M2MeggerLines.caughtGood : M2MeggerLines.caughtWeak);
    return null;
  }

  /// The core just finished (verdict given, L clip off), once; or null.
  int? finishCore() {
    final c = readFor;
    if (c == null || !verdicts.containsKey(c) || lOn == c || completed.contains(c)) return null;
    completed.add(c);
    return c;
  }

  void nextRound() => roundSlip = false;
}

/// The quick bonus (~85 % of a thorough play, rounded to 10 s). Round 1:
/// check card 4000, discharge 3000, two clips 4000, the selector 1500, TEST
/// 3000 + 1500, verdict 1500, discharge 2500, unclip 1500, reason 8210 ≈ 30700;
/// rounds 2–3 without the check, the E clip and the selector ≈ 23200 each;
/// the coworker once ≈ 9600; the next-core pauses 1500 × 2 → ≈ 89700; 85 % ≈
/// 76200 → 80 s.
const kMeggerQuickMs = 80000;

@immutable
class M2MeggerPack {
  const M2MeggerPack({required this.id, required this.titleBn, this.quickMs = kMeggerQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2MeggerPacks = {
  'do_2_7_b': M2MeggerPack(id: 'do_2_7_b', titleBn: M2MeggerLines.title),
};

/// The scene's touch areas (design px).
const kCoreHit = 24.0;
const kClipHit = 22.0;
Rect meggerArmourRect(MeggerGeo g) => Rect.fromLTRB(MeggerGeo.cx - 22, g.glandY + 6, MeggerGeo.cx + 22, g.floorY + 4);

// ============================================================================
// Page
// ============================================================================

class M2MeggerPage extends StatefulWidget {
  const M2MeggerPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2MeggerPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2MeggerPage> createState() => _M2MeggerPageState();
}

class _M2MeggerPageState extends State<M2MeggerPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _MeggerRunPage(
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

class _MeggerRunPage extends ConsumerStatefulWidget {
  const _MeggerRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2MeggerPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_MeggerRunPage> createState() => _MeggerRunPageState();
}

class _MeggerRunPageState extends ConsumerState<_MeggerRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final MeggerRun _run = MeggerRun(dealMegger(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The minute's test (0 → 1 = 60 s on the tester's clock).
  late final AnimationController _test = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _testDone();
    });

  /// The rod going to a core and back.
  late final AnimationController _touch = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  /// A discharge spark.
  late final AnimationController _spark = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final Listenable _sceneMotion = Listenable.merge([_test, _touch, _spark]);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  MeggerHold _hold = MeggerHold.none;
  var _kit = false;
  var _pressed = false;
  int? _touchCore;
  Offset? _sparkAt;
  var _cheer = false;

  /// The rod was reached for on his round before he came: he cuts in now.
  var _heldRod = false;
  var _heldThisRound = false;
  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _test.dispose();
    _touch.dispose();
    _spark.dispose();
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

  void _start() {
    _clock.start();
    unawaited(_sayChain([M2MeggerLines.ask]));
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_kit && !_touch.isAnimating && !_heldRod && !_betweenRounds;
  var _betweenRounds = false;

  // --- hands on -----------------------------------------------------------------
  void _tick() {
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.45);
  }

  void _tapScene(Offset p, MeggerGeo g) {
    if (!_canPlay || _run.testing) return;
    int? coreAt() {
      for (final (i, e) in g.coreEnds.indexed) {
        if ((e - p).distance <= kCoreHit) return i;
      }
      return null;
    }

    final core = coreAt();
    final armour = meggerArmourRect(g).contains(p);
    // The rod in hand: it goes to the core tapped.
    if (_hold == MeggerHold.rod) {
      if (core != null) {
        _dischargeCore(core);
      } else {
        _tick();
        setState(() => _hold = MeggerHold.none);
      }
      return;
    }
    final lAt = _run.lOn != null ? g.coreEnds[_run.lOn!] : g.lPark;
    final eAt = _run.eOn ? g.armourAt : g.ePark;
    // A clip in hand goes to what was tapped.
    if (_hold == MeggerHold.lClip && (core != null || armour)) {
      _hold = MeggerHold.none;
      _apply(_run.clipL(armour && core == null ? null : core), p, clip: true);
      return;
    }
    if (_hold == MeggerHold.eClip && (core != null || armour)) {
      _hold = MeggerHold.none;
      _apply(_run.clipE(armour: armour && core == null), p, clip: true);
      return;
    }
    // The clips themselves: pick up, or take off the cable.
    if ((lAt - p).distance <= kClipHit) {
      if (_run.lOn != null) {
        _unclipL(p);
      } else {
        _tick();
        setState(() => _hold = _hold == MeggerHold.lClip ? MeggerHold.none : MeggerHold.lClip);
      }
      return;
    }
    if ((eAt - p).distance <= kClipHit) {
      _tick();
      setState(() {
        if (_run.eOn) {
          _run.unclipE();
          _hold = MeggerHold.none;
        } else {
          _hold = _hold == MeggerHold.eClip ? MeggerHold.none : MeggerHold.eClip;
        }
        _wake++;
      });
      return;
    }
    if (g.selector.contains(p)) {
      HapticFeedback.selectionClick();
      _cue('sounds/intro/click.ogg', volume: 0.55);
      setState(() {
        _run.turnKnob();
        _wake++;
      });
      return;
    }
    if (_hold != MeggerHold.none) setState(() => _hold = MeggerHold.none);
  }

  /// A clip or a verdict: right goes on; a slip shows its card.
  void _apply(DoMistake? m, Offset origin, {bool clip = false}) {
    if (m == null) {
      if (clip) _cue('sounds/learn/tag_slap.wav', volume: 0.5);
      HapticFeedback.lightImpact();
      setState(() => _wake++);
      _maybeFinishCore();
      return;
    }
    setState(() => _wake++);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(_slip(m));
  }

  void _openKit() {
    if (!_canPlay || _run.testing) return;
    _cue('sounds/quiz_select.wav', volume: 0.45);
    HapticFeedback.selectionClick();
    _run.openCheck();
    setState(() {
      _kit = true;
      _hold = MeggerHold.none;
    });
  }

  void _fix(MeggerFault f) {
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    HapticFeedback.selectionClick();
    setState(() => _run.fix(f));
  }

  void _closeKit() {
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() {
      _kit = false;
      _wake++;
    });
  }

  void _takeRod() {
    if (!_canPlay || _run.testing) return;
    // On his round, right after the minute, he cuts in as the rod is reached for.
    if (_hold != MeggerHold.rod && _coworkerDue) {
      _hush();
      HapticFeedback.selectionClick();
      setState(() => _heldRod = true);
      return;
    }
    _tick();
    setState(() => _hold = _hold == MeggerHold.rod ? MeggerHold.none : MeggerHold.rod);
  }

  bool get _coworkerDue => !coworkerDone && _run.round == _run.deal.callAt && _run.readFor != null && _run.lOn == _run.readFor && _run.charged.contains(_run.lOn);

  void _dischargeCore(int core) {
    final hadCharge = _run.discharge(core);
    HapticFeedback.mediumImpact();
    setState(() {
      _touchCore = core;
      _hold = MeggerHold.none;
      _wake++;
    });
    void spark() {
      if (!mounted) return;
      if (hadCharge) {
        _cue('sounds/learn/spark.wav', volume: 0.6);
        setState(() => _sparkAt = MeggerGeo.forScene(_lastH, _lastInset).coreEnds[core]);
        if (_quiet) {
          _spark.value = 0.5;
          Timer(const Duration(milliseconds: 300), () {
            if (mounted) _spark.value = 0;
          });
        } else {
          unawaited(_spark.forward(from: 0));
        }
      } else {
        _cue('sounds/intro/click.ogg', volume: 0.4);
      }
    }

    if (_quiet) {
      _touch.value = 0;
      spark();
      Timer(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _touchCore = null);
      });
      return;
    }
    unawaited(_touch.forward(from: 0).then((_) {
      if (mounted) setState(() => _touchCore = null);
    }));
    Timer(const Duration(milliseconds: 300), spark);
  }

  double _lastH = 780;
  double _lastInset = 0;

  void _unclipL(Offset origin) {
    final m = _run.unclipL();
    if (m != null) {
      unawaited(_deadly(m));
      return;
    }
    _tick();
    setState(() => _wake++);
    _maybeFinishCore();
  }

  // --- TEST ------------------------------------------------------------------------
  void _testDown(Offset origin) {
    if (!_canPlay || _run.testing || _pressed) return;
    HapticFeedback.mediumImpact();
    if (!_run.circuit) {
      // Leads not on: the button clicks, nothing runs.
      _cue('sounds/intro/click.ogg', volume: 0.5);
      return;
    }
    final m = _run.startTest();
    if (m != null) {
      _apply(m, origin);
      return;
    }
    _cue('sounds/learn/tick.wav', volume: 0.5);
    setState(() {
      _pressed = true;
      _hold = MeggerHold.none;
    });
    unawaited(_test.forward(from: 0));
  }

  void _testUp(Offset origin) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    if (!_run.testing) return;
    _test.stop();
    final m = _run.endTest(full: false);
    _test.value = 0;
    if (m != null) _apply(m, origin);
  }

  void _testDone() {
    if (!mounted || !_run.testing) return;
    _run.endTest(full: true);
    _cue('sounds/learn/tock.wav', volume: 0.7);
    HapticFeedback.lightImpact();
    setState(() => _wake++);
    if (_run.round == _run.deal.callAt && !coworkerDone) scheduleCoworker();
  }

  void _verdict(bool good, Offset origin) {
    if (!_canPlay || _run.testing) return;
    final m = _run.verdict(good: good);
    if (m == null) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      setState(() => _cheer = true);
      Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _cheer = false);
      });
    }
    _apply(m, origin);
  }

  // --- a core done -------------------------------------------------------------
  void _maybeFinishCore() {
    final core = _run.finishCore();
    if (core == null) return;
    final clean = !_run.roundSlip;
    final held = _heldThisRound;
    _betweenRounds = true;
    if (!clean) {
      unawaited(Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _nextRound();
      }));
      return;
    }
    _cue('sounds/quiz_right.wav', volume: 0.6);
    putOnTable(15);
    final good = _run.verdicts[core]!;
    final idx = _run.round;
    unawaited(askReason(
      deal: () => held
          ? dealChoices(M2MeggerLines.dischargeRight, M2MeggerLines.dischargeWrong, widget.rng)
          : (good ? dealChoices(M2MeggerLines.goodRight, M2MeggerLines.goodWrong, widget.rng) : dealChoices(M2MeggerLines.weakRight, M2MeggerLines.weakWrong, widget.rng)),
      question: held ? M2MeggerLines.whyDischarge : (good ? M2MeggerLines.whyGood : M2MeggerLines.whyWeak),
      stillValid: () => _run.round == idx && !_ended,
    ));
  }

  void _nextRound() {
    _run.nextRound();
    _heldThisRound = false;
    _betweenRounds = false;
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() => _wake++);
    unawaited(_sayChain([M2MeggerLines.ask]));
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
    final idx = _run.round;
    unawaited(Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_ended && _run.round == idx) _nextRound();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M2MeggerLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_coworkerDue) return null;
    if (_heldRod) return true;
    if (_intro || _card != null || reasonOpen || _kit || _run.testing || _touch.isAnimating) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    _heldRod = false;
    final core = _run.lOn;
    if (!held) {
      // Listened to him: the L clip comes off the charged core.
      if (core != null) _unclipL(origin);
      return;
    }
    _run.caught.add(M2MeggerLines.caughtCall);
    _heldThisRound = true;
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    // Refused: the rod goes to the core now.
    if (core != null) _dischargeCore(core);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M2MeggerLines.tapWhy[_nudgeN++ % M2MeggerLines.tapWhy.length]
            : _nudge.next(M2MeggerLines.ask);
    _tick();
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
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
      _cardTone = MistakeTone.slip;
      _hold = MeggerHold.none;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('megger/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The L clip off a charged core: the room freezes grey and the charge
  /// jumps to his hand in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _kit = false;
      _hold = MeggerHold.none;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('megger/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M2MeggerLines.deadlyWord : M2MeggerLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        _maybeFinishCore();
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
    await _say(!_run.passed ? M2MeggerLines.fail : (_quickBonus ? M2MeggerLines.quick : M2MeggerLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_heldRod || coworkerOpen) return LinemanMode.worried;
    if (_cheer) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  (String, String, double) _display() {
    final top = M2MeggerLines.volts(_run.volts);
    if (_run.testing) {
      final v = _test.value;
      final target = meggerScale(_run.deal.readings[_run.lOn!]);
      return (top, M2MeggerLines.seconds((60 * v).floor()), target * Curves.easeOut.transform((v * 1.6).clamp(0.0, 1.0)));
    }
    final r = _run.readFor;
    if (r != null && _run.lOn == r) return (top, M2MeggerLines.reading(_run.deal.readings[r]), meggerScale(_run.deal.readings[r]));
    if (r != null && _run.lOn == null) return (top, M2MeggerLines.reading(_run.deal.readings[r]), 0);
    return (top, M2MeggerLines.idleReadout, 0);
  }

  List<Widget> _scene(SceneMetrics m) {
    final g = MeggerGeo.forScene(m.height, m.inset);
    _lastH = m.height;
    _lastInset = m.inset;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final (top, readout, needle) = _display();
    final lAt = _run.lOn != null ? g.coreEnds[_run.lOn!] : g.lPark;
    final eAt = _run.eOn ? g.armourAt : g.ePark;
    final touching = _touchCore != null;
    final tk = Curves.easeInOut.transform(_touch.value < 0.5 ? _touch.value * 2 : (1 - _touch.value) * 2);
    final rodTip = touching ? Offset.lerp(g.rodHeldTip, g.coreEnds[_touchCore!], quiet ? 1 : tk) : null;
    final rod = touching ? RodPose.touch : (_hold == MeggerHold.rod ? RodPose.held : RodPose.rest);
    final tb = g.trainee;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('room'),
                child: RepaintBoundary(child: CustomPaint(painter: MeggerRoomPainter(geo: g))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              Positioned.fill(
                key: const ValueKey('live'),
                child: CustomPaint(
                  painter: MeggerLivePainter(
                    geo: g,
                    needle: needle,
                    topLine: top,
                    readout: readout,
                    volts: _run.volts,
                    lAt: lAt,
                    eAt: eAt,
                    lLifted: _hold == MeggerHold.lClip,
                    eLifted: _hold == MeggerHold.eClip,
                    cracked: _run.leadCracked,
                    rod: rod,
                    rodTip: rodTip,
                    pressed: _pressed,
                    spark: _spark.value,
                    sparkAt: _sparkAt,
                    tags: {for (final c in _run.completed) c: _run.verdicts[c]!},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Tap the cable, the clips, the selector.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M2MeggerLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, g)),
        ),
      ),
      // TEST: press and hold.
      Positioned(
        key: const ValueKey('test'),
        left: g.testButton.dx - 28,
        top: g.testButton.dy - 28,
        width: 56,
        height: 56,
        child: Semantics(
          label: M2MeggerLines.testLabel,
          button: true,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _testDown(e.position),
            onPointerUp: (e) => _testUp(e.position),
            onPointerCancel: (e) => _testUp(e.position),
          ),
        ),
      ),
      // The charge jumps to his hand, in colour over the grey room.
      if (_freeze && _run.lOn != null)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: MeggerArcPainter(from: g.coreEnds[_run.lOn!], to: Offset(tb.right - 12, tb.top + tb.height * 0.42), v: v)),
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
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_kit && !_heldRod && !_betweenRounds;
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
              labels: M2MeggerLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            animation: _sceneMotion,
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: const IgnorePointer(child: _DocketChip()),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  right: 8,
                  bottom: pad.bottom + 72,
                  child: Row(
                    children: [
                      _ToolButton(icon: Icons.fact_check_rounded, label: M2MeggerLines.check, on: _run.checked, enabled: _canPlay, onTap: _openKit),
                      const SizedBox(width: 4),
                      _ToolButton(icon: Icons.bolt_rounded, label: M2MeggerLines.rod, on: _hold == MeggerHold.rod, enabled: _canPlay, onTap: _takeRod),
                    ],
                  ),
                ),
                if (_run.verdictDue && !_run.testing)
                  Positioned(
                    key: const ValueKey('hud-verdict'),
                    left: 12,
                    right: 12,
                    bottom: pad.bottom + 12,
                    child: Row(
                      children: [
                        Expanded(child: DoBigButton(label: M2MeggerLines.good, filled: true, onTapUp: (d) => _verdict(true, d.globalPosition))),
                        const SizedBox(width: 10),
                        Expanded(child: DoBigButton(label: M2MeggerLines.weak, filled: false, onDark: true, onTapUp: (d) => _verdict(false, d.globalPosition))),
                      ],
                    ),
                  ),
              ],
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
              if (_kit && playing)
                _KitCard(key: const ValueKey('kit'), run: _run, quiet: quiet, onFix: _fix, onClose: _closeKit),
              if (playing && _card == null && !_kit)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: !(coworkerOnScreen && !coworkerFromRight)),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: _cardTone,
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
                  line: M2MeggerLines.intro,
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
          Text(M2MeggerLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M2MeggerLines.docketJob, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once used / in hand.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.on, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 82,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tester close up (the daily check): its battery and both test leads.
/// The fixes are always offered (no tell); a needless fix changes nothing.
class _KitCard extends StatelessWidget {
  const _KitCard({super.key, required this.run, required this.quiet, required this.onFix, required this.onClose});
  final MeggerRun run;
  final bool quiet;
  final ValueChanged<MeggerFault> onFix;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    Widget button(String label, VoidCallback onTap, {bool filled = false}) => Expanded(
          child: Material(
            color: filled ? SlmColors.gold700 : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: filled ? null : Border.all(color: SlmColors.gold300.withValues(alpha: 0.6))),
                child: Text(label, textAlign: TextAlign.center, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ),
        );
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x99050A16),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.translate(offset: Offset(0, 60 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
            child: Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF101A2B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC88F1E), width: 3),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(M2MeggerLines.kitTitle, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text(M2MeggerLines.battery, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFC9D6E4)))),
                      _Battery(low: run.batteryLow),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(M2MeggerLines.leads, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFC9D6E4))),
                  const SizedBox(height: 4),
                  SizedBox(height: 56, width: double.infinity, child: CustomPaint(painter: _LeadsPainter(cracked: run.leadCracked))),
                  const SizedBox(height: 10),
                  Row(children: [
                    button(M2MeggerLines.newLead, () => onFix(MeggerFault.lead)),
                    const SizedBox(width: 8),
                    button(M2MeggerLines.newBattery, () => onFix(MeggerFault.battery)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [button(M2MeggerLines.kitOk, onClose, filled: true)]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery({required this.low});
  final bool low;

  @override
  Widget build(BuildContext context) {
    final n = low ? 1 : 4;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC9D6E4), width: 1.6), borderRadius: BorderRadius.circular(3)),
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 10,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  color: i < n ? (low ? SlmColors.danger : SlmColors.success) : const Color(0xFF26324A),
                ),
            ],
          ),
        ),
        Container(width: 3, height: 8, color: const Color(0xFFC9D6E4)),
      ],
    );
  }
}

/// The two test leads, coiled straight for a look: red L and black E; a
/// cracked one shows its copper.
class _LeadsPainter extends CustomPainter {
  const _LeadsPainter({required this.cracked});
  final bool cracked;

  @override
  void paint(Canvas c, Size size) {
    void lead(double y, Color colour, bool crack) {
      final p = Path()
        ..moveTo(8, y)
        ..cubicTo(size.width * 0.3, y - 8, size.width * 0.6, y + 8, size.width - 30, y);
      c.drawPath(p, Paint()..color = const Color(0xFF8A96A8)..strokeWidth = 9..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      c.drawPath(p, Paint()..color = colour..strokeWidth = 7..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      // The crocodile clip.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 32, y - 6, 16, 12), const Radius.circular(3)), Paint()..color = colour);
      c.drawLine(Offset(size.width - 16, y - 3), Offset(size.width - 4, y - 6), Paint()..color = const Color(0xFFB9BEC2)..strokeWidth = 2.6);
      c.drawLine(Offset(size.width - 16, y + 3), Offset(size.width - 4, y + 6), Paint()..color = const Color(0xFFB9BEC2)..strokeWidth = 2.6);
      if (crack) {
        final at = Offset(size.width * 0.42, y + 0.5);
        c.drawOval(Rect.fromCenter(center: at, width: 22, height: 8), Paint()..color = const Color(0xFFF0A35A));
        c.drawOval(Rect.fromCenter(center: at, width: 22, height: 8), Paint()..color = const Color(0xFF4A1A12)..style = PaintingStyle.stroke..strokeWidth = 1.4);
        for (var i = -2; i <= 2; i++) {
          c.drawLine(at + Offset(i * 4.0, -3), at + Offset(i * 4.0 + 2, 3), Paint()..color = const Color(0xFFB0662A)..strokeWidth = 1);
        }
      }
    }

    lead(16, const Color(0xFFC8352B), cracked);
    lead(42, const Color(0xFF16181B), false);
  }

  @override
  bool shouldRepaint(_LeadsPainter old) => old.cracked != cracked;
}
