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
import 'm2_skin_tools_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_skin_tools_world.dart' show BladeFlaw, SkinCable, SkinTool, SkinToolPainter, kBladeBins;

// Lesson 2.6 কেবিল স্কিনিং-এর শিল্প, কাজ 1: "সঠিক ছুরি, সঠিক প্রস্তুতি".
// At a roadside pole the cable end hangs ready for a joint. Three jobs, one
// cable each (small service wire, LT PVC cable, AB cable — dealt in a fresh
// order): put on the cut-resistant gloves (lesson: সর্বদা কাটা-রোধী গ্লাভস),
// prove the cable dead with the tester (on one job of most plays it is still
// LIVE — hold the job), take the right tool from the roll for this cable
// (lesson: স্কিনিং নাইফ / ওয়্যার স্ট্রিপার / এবি কেবিলের বিশেষ টুল — never
// a সাধারণ ছুরি), and look the blade over under the lens before cutting
// (lesson daily check: ধারালো এবং পরিষ্কার). Once a play the careless coworker
// peeps in with the lesson's myth ("দাঁত দিয়েই ছিলে ফেলো") or the shortcut
// "টেস্ট লাগবে না". Built on the shared kit (GAME_LEVEL_PLAYBOOK.md): guide
// first, full scene, corner guide, ◆ on the table → "কেন …?" → next job by
// itself.
//
// Deadly: cutting a live cable (with or without testing; also by listening to
// "টেস্ট লাগবে না" on the live job). Slips: cutting untested (dead cable), the
// kitchen knife, the wrong tool for the cable, a blunt or dirty blade, no
// gloves, the teeth, holding a job the tester proved dead.
//
// Content flag: "prove dead before you cut" is not in lesson 2.6's text; it is
// the Module 1 rule (1.5/1.6: test before work, even after a shutdown).
//
// Voice: the guide on device TTS; the coworker's new lines on TTS until his
// voice records them (SkinLines.recordLines).

// ============================================================================
// Content
// ============================================================================

extension SkinCableText on SkinCable {
  /// As the job card names it.
  String get nameBn => switch (this) {
        SkinCable.wire => 'ছোট সার্ভিস তার',
        SkinCable.ltPvc => 'এলটি পিভিসি কেবিল',
        SkinCable.ab => 'এবি কেবিল (XLPE)',
      };

  /// The right tool for it (lesson 2.6, point 1 and pro tip 4).
  SkinTool get rightTool => switch (this) {
        SkinCable.wire => SkinTool.stripper,
        SkinCable.ltPvc => SkinTool.skinKnife,
        SkinCable.ab => SkinTool.abTool,
      };
}

extension SkinToolText on SkinTool {
  String get nameBn => switch (this) {
        SkinTool.skinKnife => 'কেবিল স্কিনিং নাইফ',
        SkinTool.stripper => 'ওয়্যার স্ট্রিপার',
        SkinTool.abTool => 'এবি কেবিল স্ট্রিপার',
        SkinTool.kitchen => 'রান্নাঘরের ছুরি',
      };
}

@immutable
class SkinItem {
  const SkinItem({required this.id, required this.tool, this.flaw = BladeFlaw.none});
  final String id;
  final SkinTool tool;
  final BladeFlaw flaw;
}

@immutable
class SkinJob {
  const SkinJob({required this.cable, required this.items, this.live = false, this.siteBn = ''});
  final SkinCable cable;
  final List<SkinItem> items;

  /// The tester will show LIVE: the job must be held.
  final bool live;
  final String siteBn;
}

/// What the careless coworker pushes.
enum SkinPush { teeth, skipTest }

@immutable
class SkinDeal {
  const SkinDeal({required this.jobs, required this.callRound, required this.callTeeth});
  final List<SkinJob> jobs;

  /// The job on which he peeps in (or a later one, if he could not yet).
  final int callRound;

  /// He pushes the teeth on the small-wire job when he can; otherwise the
  /// skipped test.
  final bool callTeeth;
}

abstract final class SkinLines {
  static const title = 'সঠিক ছুরি, সঠিক প্রস্তুতি';
  static const intro = 'জয়েন্টের জন্য কেবিলের মুখ ছিলতে হবে! আগে প্রস্তুতি, ঠিক টুল — তারপর ছুরি।';
  static const rounds = ['প্রথম কাজ', 'দ্বিতীয় কাজ', 'শেষ কাজ'];
  static const ask = 'কাজের কার্ড দেখুন। কেবিলটা ছিলতে তৈরি হোন।';
  static const inspectAsk = 'ব্লেডটা ভালো করে দেখুন। এটা দিয়েই ছিলবেন?';
  static const tasks = [ask, inspectAsk];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const jobCard = 'কাজের কার্ড';
  static const shutdown = 'শাটডাউন নেওয়া হয়েছে';
  static String jobLine(SkinJob j) => 'কেবিল: ${j.cable.nameBn}';
  static const forJoint = 'জয়েন্টের জন্য মুখ ছিলুন';
  static const toolLabel = 'টুল';
  static const glovesLabel = 'কাটা-রোধী গ্লাভস';
  static const testerLabel = 'টেস্টার';
  static const cableLabel = 'কেবিলের মুখ';
  static const handLabel = 'ব্লেড লেন্সে';
  static const live = 'LIVE';
  static const dead = '0 V';
  static const take = 'এটা দিয়েই ছিলব';
  static const putBack = 'ফেরত রাখুন';
  static const hold = 'কাটব না — কাজ স্থগিত';
  static const rejected = 'বাতিল';

  // Reasons (lesson 2.6): the right ones fit this cable and what the player
  // did; every card is 37–46 letters, so none stands out by its length.
  static const toolAsk = 'কেন এই টুলটা নিলেন?';
  static const holdAsk = 'কেন কাজ স্থগিত করলেন?';
  static List<String> toolFor(SkinCable c) => switch (c) {
        SkinCable.wire => const ['ছোট তারে ওয়্যার স্ট্রিপারই সবচেয়ে নিরাপদ', 'নির্দিষ্ট মাপের তারে স্ট্রিপার নিখুঁত কাটে'],
        SkinCable.ltPvc => const ['নাইফের ব্লেড ইনসুলেশন কাটে, কন্ডাক্টর নয়', 'স্কিনিং নাইফ ইনসুলেশন কাটার জন্যই তৈরি'],
        SkinCable.ab => const ['এবি কেবিলের শক্ত ইনসুলেশনে বিশেষ স্ট্রিপিং টুল', 'শক্ত XLPE ইনসুলেশন, তাই এবি কেবিলের নিজস্ব টুল'],
      };
  static const bladeChecked = 'ব্লেড ধারালো আর পরিষ্কার — হাতে নিয়ে দেখেছি';
  static const toolMyths = [
    'যেকোনো ধারালো ছুরিতেই ইনসুলেশন উঠে যায়',
    'হাতের কাছে যেটা ছিল, সেটাই তুলে নিলাম',
    'জোর দিলে ভোঁতা ব্লেডেও ইনসুলেশন কাটা যায়',
    'নতুন টুল, তাই ব্লেড খুঁটিয়ে দেখার দরকার নেই',
    'সামান্য আঁচড় তো ক্রিম্পিং-এর পরে ঢেকে যায়',
  ];

  /// Why this tool, on a [c] job; the blade line only when it was looked over.
  static List<String> toolRight(SkinCable c, {required bool looked}) => [...toolFor(c), if (looked) bladeChecked];

  /// The other cables' tools (true elsewhere, not here) and the myths.
  static List<String> toolWrong(SkinCable c) => [
        for (final x in SkinCable.values)
          if (x != c) ...toolFor(x),
        ...toolMyths,
      ];

  static const holdRight = ['টেস্টারে লাইভ — ডেড প্রমাণ ছাড়া ছুরি নয়', 'লাইভ কেবিলে কাজ নয়, আগে জানিয়ে লাইন বন্ধ'];
  static const holdWrong = [
    'শাটডাউন আছে, তবু মনটা খুঁতখুঁত করছিল',
    'টুলগুলো ভোঁতা লাগছিল, তাই কাজ থামালাম',
    'গ্লাভস ঢিলে ছিল, তাই কাজ বন্ধ রাখলাম',
    'রোদ বেশি, দুপুরে কাজ না করাই ভালো',
    'সুপারভাইজার না এলে কাজ শুরু হয় না',
  ];

  /// The careless coworker: the lesson's myth, and the skipped test.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerTeeth = CoworkerScript(
    line: 'স্ট্রিপার খুঁজছ কেন? দাঁত দিয়েই ছিলে ফেলো, তাড়াতাড়ি হবে!',
    exitLine: coworkerExit,
    right: ['না — দাঁত নয়, ঠিক টুল দিয়েই ছিলব', 'দাঁতে তার ছিলানো বিপজ্জনক, করব না', 'ছোট তারেও ওয়্যার স্ট্রিপারই নেব'],
    wrong: [
      'ঠিক, দাঁত দিয়েই ঝটপট ছিলে নিই',
      'ছোট তার তো, দাঁতেই হয়ে যাবে',
      'একবার দাঁতে ছিললে কিছু হবে না',
      'সবাই তো দাঁত দিয়েই ছিলে নেয়',
      'স্ট্রিপার খোঁজার সময় নেই, দাঁতেই',
    ],
    asks: ['ও বলছে দাঁত দিয়েই ছিলতে। আপনি কী করবেন?', 'দাঁত, না ঠিক টুল?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerSkip = CoworkerScript(
    line: 'শাটডাউন তো নেওয়াই আছে! টেস্ট লাগবে না, কেটে ফেলো।',
    exitLine: coworkerExit,
    right: ['না — আগে টেস্টারে ডেড প্রমাণ করব', 'টেস্ট না করে কেবিলে ছুরি নয়', 'শাটডাউন থাকলেও আগে টেস্ট করব'],
    wrong: [
      'ঠিক, শাটডাউন তো আছে, কেটে ফেলি',
      'টেস্টের সময় নেই, এখনই কাটি',
      'একবার টেস্ট ছাড়া কাটলে কী হবে',
      'সবাই তো টেস্ট ছাড়াই কেটে নেয়',
      'কাগজে শাটডাউন আছে, টেস্ট বাদ',
    ],
    asks: ['ও বলছে টেস্ট লাগবে না। আপনি কী করবেন?', 'টেস্ট করবেন, না সোজা কাটবেন?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(SkinPush p) => p == SkinPush.teeth ? coworkerTeeth : coworkerSkip;

  /// His new lines, for his recorded voice (device TTS until then).
  static List<String> get recordLines => [coworkerTeeth.line, coworkerSkip.line];

  static const callHeld = 'ঠিক! শর্টকাট নয় — নিয়ম মেনেই কাজ।';
  static const glovesOn = 'গ্লাভস পরা হলো।';
  static const asideBad = 'ঠিক — এটা বাতিল।';
  static const allSet = 'টুলের ওস্তাদ! প্রস্তুতি, টেস্ট, ঠিক টুল — সব মিলিয়েছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে প্রস্তুতি, তারপর ঠিক টুল।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtGloves = 'কাটা-রোধী গ্লাভস পরেছেন';
  static const caughtTest = 'কাটার আগে টেস্ট করেছেন';
  static const caughtTool = 'কেবিল মিলিয়ে টুল বেছেছেন';
  static const caughtBlade = 'ভোঁতা-ময়লা ব্লেড বাতিল';
  static const caughtKnife = 'রান্নাঘরের ছুরি বাতিল';
  static const caughtHold = 'লাইভ কেবিলে কাজ স্থগিত';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const sites = ['বাজার রোড, পোল 14', 'স্কুলপাড়া, পোল 7', 'নদীঘাট, পোল 22', 'হাসপাতাল মোড়, পোল 3'];
}

abstract final class SkinMistakes {
  static const _dir = 'assets/game/art/m2_skin_tools';
  static const liveCut = DoMistake(
    key: '2.6/skin/live-cut',
    textBn: 'লাইভ কেবিলে ছুরি — শক আর আর্কে প্রাণ যায়। টেস্টারে ডেড প্রমাণ না হলে কেবিল ছোঁবেন না।',
    art: '$_dir/test_dead.svg',
    deadly: true,
  );
  static const untested = DoMistake(
    key: '2.6/skin/untested',
    textBn: 'টেস্ট না করে কেবিলে ছুরি নয় — শাটডাউন থাকলেও আগে টেস্টারে ডেড প্রমাণ করুন।',
    art: '$_dir/test_dead.svg',
  );
  static const kitchen = DoMistake(
    key: '2.6/skin/kitchen-knife',
    textBn: 'সাধারণ ছুরি ইনসুলেশনের জন্য নয় — পিছলে হাতে বা কন্ডাক্টরে লাগে। স্কিনিং নাইফ বা স্ট্রিপার নিন।',
    art: '$_dir/right_tool.svg',
    lessonPoint: 0,
  );
  static const mismatch = DoMistake(
    key: '2.6/skin/wrong-size-tool',
    textBn: 'ওয়্যার স্ট্রিপার নির্দিষ্ট মাপের ছোট তারের জন্য। এলটি কেবিলে স্কিনিং নাইফ, এবি কেবিলে বিশেষ স্ট্রিপিং টুল।',
    art: '$_dir/tool_match.svg',
    lessonPoint: 0,
  );
  static const blunt = DoMistake(
    key: '2.6/skin/blunt-blade',
    textBn: 'ভোঁতা ব্লেডে বাড়তি জোর লাগে — পিছলে হাতে লাগে, কন্ডাক্টরে নিক পড়ে। ধারালো ব্লেড চাই।',
    art: '$_dir/blade_check.svg',
    lessonPoint: 0,
  );
  static const dirty = DoMistake(
    key: '2.6/skin/dirty-blade',
    textBn: 'ব্লেডে ময়লা-মরিচা — ব্লেড ধারালো আর পরিষ্কার কিনা রোজ দেখুন। এমন টুল বাতিল।',
    art: '$_dir/blade_check.svg',
    lessonPoint: 0,
  );
  static const noGloves = DoMistake(
    key: '2.6/skin/no-gloves',
    textBn: 'কাটা-রোধী গ্লাভস ছাড়া স্কিনিং নয় — ব্লেড পিছলালে গ্লাভসই হাত বাঁচায়।',
    art: '$_dir/cut_gloves.svg',
    lessonPoint: 1,
  );
  static const teeth = DoMistake(
    key: '2.6/skin/teeth',
    textBn: 'দাঁত দিয়ে ইনসুলেশন ছিলানো বিপজ্জনক — দাঁতের ক্ষতি, কন্ডাক্টরেরও ক্ষতি, সংযোগ হয় অনির্ভরযোগ্য।',
    art: '$_dir/no_teeth.svg',
    lessonPoint: 0,
  );
  static const heldWhenDead = DoMistake(
    key: '2.6/skin/held-when-dead',
    textBn: 'টেস্টারে কোনো ভোল্টেজ ছিল না — কেবিল ডেড প্রমাণিত, কাজ থামানোর দরকার ছিল না।',
    art: '$_dir/test_dead.svg',
  );
  static const all = [liveCut, untested, kitchen, mismatch, blunt, dirty, noGloves, teeth, heldWhenDead];
}

BladeFlaw _anyFlaw(math.Random rng) => rng.nextBool() ? BladeFlaw.blunt : BladeFlaw.dirty;

/// A fresh set of jobs each play: the cable order, which job is live, the
/// flawed twins, the roll order and the coworker's moment vary.
SkinDeal dealSkin(math.Random rng) {
  var n = 0;
  SkinItem item(SkinTool t, [BladeFlaw f = BladeFlaw.none]) => SkinItem(id: 't${n++}', tool: t, flaw: f);
  final cables = [...SkinCable.values]..shuffle(rng);
  // Most plays have one live job (never the first).
  final liveAt = rng.nextDouble() < 0.7 ? 1 + rng.nextInt(2) : -1;
  final sureTwin = rng.nextInt(3);
  final sites = [...SkinLines.sites]..shuffle(rng);
  final jobs = <SkinJob>[];
  for (var i = 0; i < 3; i++) {
    final c = cables[i];
    final right = c.rightTool;
    // The small wire always has a flawed twin (it has no wrong-size decoy).
    final twin = c == SkinCable.wire || i == sureTwin || rng.nextBool();
    final items = [
      item(right),
      item(SkinTool.kitchen),
      if (twin) item(right, _anyFlaw(rng)),
      // The wire stripper on a big cable: the wrong size (lesson: নির্দিষ্ট সাইজের তারের জন্য).
      if (c == SkinCable.ab || (c == SkinCable.ltPvc && !twin)) item(SkinTool.stripper),
    ]..shuffle(rng);
    jobs.add(SkinJob(cable: c, items: items, live: i == liveAt, siteBn: sites[i]));
  }
  return SkinDeal(jobs: jobs, callRound: rng.nextInt(3), callTeeth: rng.nextBool());
}

/// What he can push on [job] now: the teeth only on the small wire; the
/// skipped test only before the tester has been used. The dealt push first.
SkinPush? skinPushFor(SkinJob job, {required bool tested, required bool shown, required bool preferTeeth}) {
  if (shown) return null;
  final teeth = job.cable == SkinCable.wire;
  final skip = !tested;
  if (preferTeeth && teeth) return SkinPush.teeth;
  if (skip) return SkinPush.skipTest;
  return teeth ? SkinPush.teeth : null;
}

enum SkinVerdict { right, slip, deadly }

@immutable
class SkinOutcome {
  const SkinOutcome(this.verdict, {this.mistake, this.aside = false});
  final SkinVerdict verdict;
  final DoMistake? mistake;

  /// The tool went aside (tagged বাতিল).
  final bool aside;
}

/// The play state (pure logic).
class SkinRun {
  SkinRun(this.deal);
  final SkinDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;
  var gloves = false;

  /// The tester has been held to this job's cable.
  var tested = false;

  /// This job is decided (skinned with the right tool, or held): the reason
  /// comes, then [next].
  var shown = false;

  /// Tools set aside on this job.
  final Set<String> rejected = {};

  /// Tools whose blade flaw the player has seen (lens, or the card).
  final Set<String> spotted = {};

  /// Tools whose whole blade the player looked over.
  final Set<String> looked = {};
  final List<String> caught = [];

  bool get done => round >= deal.jobs.length;
  bool get ended => done || deadly != null;
  SkinJob get current => deal.jobs[round.clamp(0, deal.jobs.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  void wearGloves() {
    if (gloves) return;
    gloves = true;
    _tag(SkinLines.caughtGloves);
  }

  /// The tester on this job's cable: true = LIVE.
  bool test() {
    if (!tested && !current.live) _tag(SkinLines.caughtTest);
    tested = true;
    return current.live;
  }

  /// Skins the cable with [it].
  SkinOutcome take(SkinItem it) {
    if (ended || shown || rejected.contains(it.id)) return const SkinOutcome(SkinVerdict.slip);
    if (current.live) return _deadly(SkinMistakes.liveCut);
    if (!tested) return _slip(SkinMistakes.untested);
    if (it.tool == SkinTool.kitchen) return _slip(SkinMistakes.kitchen, aside: it);
    if (it.tool != current.cable.rightTool) return _slip(SkinMistakes.mismatch, aside: it);
    if (it.flaw != BladeFlaw.none) {
      spotted.add(it.id);
      return _slip(it.flaw == BladeFlaw.blunt ? SkinMistakes.blunt : SkinMistakes.dirty, aside: it);
    }
    if (!gloves) return _slip(SkinMistakes.noGloves);
    _tag(SkinLines.caughtTool);
    shown = true;
    return const SkinOutcome(SkinVerdict.right);
  }

  /// The lens found [it]'s flaw / went over its whole blade.
  void spot(SkinItem it) {
    if (it.flaw != BladeFlaw.none) spotted.add(it.id);
  }

  void lookedOver(SkinItem it) => looked.add(it.id);

  /// Puts [it] back: the kitchen knife and the wrong-size tool (they show to
  /// the eye), or a blade whose flaw was found, go aside (true); anything
  /// else back in the roll (false) — putting back never tells which blade is
  /// bad. Never costs anything.
  bool putBack(SkinItem it) {
    if (ended || shown || rejected.contains(it.id)) return false;
    final plain = it.tool == SkinTool.kitchen || it.tool != current.cable.rightTool;
    if (!plain && !spotted.contains(it.id)) return false;
    rejected.add(it.id);
    _tag(it.tool == SkinTool.kitchen ? SkinLines.caughtKnife : (plain ? SkinLines.caughtTool : SkinLines.caughtBlade));
    return true;
  }

  /// "কাটব না — কাজ স্থগিত" (offered once the tester was used).
  SkinOutcome holdJob() {
    if (ended || shown || !tested) return const SkinOutcome(SkinVerdict.slip);
    if (!current.live) return _slip(SkinMistakes.heldWhenDead);
    _tag(SkinLines.caughtHold);
    shown = true;
    return const SkinOutcome(SkinVerdict.right);
  }

  /// Listened to the coworker's push.
  SkinOutcome listen(SkinPush p) {
    if (ended) return const SkinOutcome(SkinVerdict.slip);
    if (p == SkinPush.teeth) return _slip(SkinMistakes.teeth);
    if (current.live) return _deadly(SkinMistakes.liveCut);
    return _slip(SkinMistakes.untested);
  }

  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    looked.clear();
    tested = false;
    shown = false;
  }

  SkinOutcome _slip(DoMistake m, {SkinItem? aside}) {
    slips++;
    if (aside != null) rejected.add(aside.id);
    return SkinOutcome(SkinVerdict.slip, mistake: m, aside: aside != null);
  }

  SkinOutcome _deadly(DoMistake m) {
    deadly = m;
    return SkinOutcome(SkinVerdict.deadly, mistake: m);
  }
}

@immutable
class M2SkinToolsPack {
  const M2SkinToolsPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2SkinToolsPack26 = M2SkinToolsPack(id: 'do_2_6_a', titleBn: SkinLines.title);
const m2SkinToolsPacks = {'do_2_6_a': m2SkinToolsPack26};

// ============================================================================
// Page
// ============================================================================

class M2SkinToolsPage extends StatefulWidget {
  const M2SkinToolsPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M2SkinToolsPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2SkinToolsPage> createState() => _M2SkinToolsPageState();
}

class _M2SkinToolsPageState extends State<M2SkinToolsPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SkinRunPage(
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

class _SkinRunPage extends ConsumerStatefulWidget {
  const _SkinRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2SkinToolsPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SkinRunPage> createState() => _SkinRunPageState();
}

/// The trainee before the gloves go on (bare hands).
const _bareHands = LinemanLook(
  helmet: Color(0xFFFFD34E),
  shirt: Color(0xFF1F5F8F),
  vest: Color(0xFFFF851B),
  pants: Color(0xFF26303D),
  skin: Color(0xFFA86E48),
);

class _SkinRunPageState extends ConsumerState<_SkinRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final SkinRun _run = SkinRun(dealSkin(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The tool under the lens, and the one the cable was skinned with.
  SkinItem? _held;
  String? _used;
  var _cardOpen = false;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  SkinPush _push = SkinPush.skipTest;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;

  var _freeze = false;
  Completer<void>? _frozen;
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

  // ---- voice (never holds the player) -----------------------------------------

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

  String get _task => _held != null ? SkinLines.inspectAsk : SkinLines.ask;

  // ---- flow -------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([SkinLines.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || _run.shown || _freeze;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// Going on with the job while he is still talking refuses him.
  void _refuseByWork(Offset origin) {
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, origin, direct: true));
  }

  void _wearGloves(Offset origin) {
    _refuseByWork(origin);
    if (_blocked || coworkerOpen || _held != null || _cardOpen || _run.gloves) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.5, muted: false));
    setState(() {
      _run.wearGloves();
      _setMode(LinemanMode.cheer);
    });
    unawaited(_sayChain([SkinLines.glovesOn]));
  }

  void _test(Offset origin) {
    if (_push == SkinPush.skipTest) _refuseByWork(origin);
    if (_blocked || coworkerOpen || _held != null || _cardOpen || _run.tested) return;
    HapticFeedback.mediumImpact();
    final live = _run.test();
    if (!_muted) unawaited(ZlFx.cue(live ? 'sounds/quiz_wrong.wav' : 'sounds/intro/click.ogg', volume: 0.6, muted: false));
    setState(() => _setMode(LinemanMode.hold));
    unawaited(_sayChain([SkinLines.ask]));
  }

  void _pick(SkinItem it, Offset origin) {
    if (_push == SkinPush.teeth) _refuseByWork(origin);
    if (_blocked || coworkerOpen || _held != null || _cardOpen || _run.rejected.contains(it.id) || _used == it.id) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.4, muted: false));
    _hush();
    setState(() {
      _held = it;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([SkinLines.inspectAsk]));
  }

  void _found() {
    final it = _held;
    if (it != null) _run.spot(it);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.6, muted: false));
  }

  void _allSeen() {
    final it = _held;
    if (it != null) _run.lookedOver(it);
  }

  void _putBack() {
    final it = _held;
    if (it == null || _blocked) return;
    final aside = _run.putBack(it);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([SkinLines.asideBad, SkinLines.ask], mood: GuideMood.glad));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
      unawaited(_sayChain([SkinLines.ask]));
    }
  }

  void _take(Offset origin) {
    final it = _held;
    if (it == null || _blocked) return;
    setState(() => _held = null);
    final o = _run.take(it);
    switch (o.verdict) {
      case SkinVerdict.right:
        HapticFeedback.lightImpact();
        if (!_muted) {
          unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
          unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.5, muted: false));
        }
        setState(() {
          _used = it.id;
          _setMode(LinemanMode.cheer);
        });
        final c = _run.current.cable;
        final looked = _run.looked.contains(it.id);
        _ask(15, () => dealChoices(SkinLines.toolRight(c, looked: looked), SkinLines.toolWrong(c), widget.rng), SkinLines.toolAsk);
      case SkinVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, origin));
      case SkinVerdict.deadly:
        setState(() => _used = it.id);
        unawaited(_deadly(o.mistake!));
    }
  }

  void _holdJob(Offset origin) {
    if (_blocked || coworkerOpen || _held != null || _cardOpen) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == SkinVerdict.right) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      _ask(20, () => dealChoices(SkinLines.holdRight, SkinLines.holdWrong, widget.rng), SkinLines.holdAsk);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  void _ask(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _used = null;
      _setMode(LinemanMode.idle);
    });
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([SkinLines.ask]));
  }

  void _openCard() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: false));
    setState(() => _cardOpen = true);
  }

  // --- the shared success beat (ReasonTable) ----------------------------------
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
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) -----------------------------
  @override
  CoworkerScript get coworkerScript => SkinLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    final push = skinPushFor(_run.current, tested: _run.tested, shown: _run.shown, preferTeeth: _run.deal.callTeeth);
    if (push == null) return _run.round >= _run.deal.jobs.length - 1 ? null : false;
    if (_blocked || _held != null || _cardOpen) return false;
    _push = push;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final o = _run.listen(_push);
      if (o.verdict == SkinVerdict.deadly) {
        await _deadly(o.mistake!);
      } else if (o.mistake != null) {
        setState(() => _setMode(LinemanMode.worried));
        await _slip(o.mistake!, origin);
      }
      return;
    }
    _run.caught.add(SkinLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([SkinLines.callHeld, SkinLines.ask], mood: GuideMood.glad);
    }());
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? SkinLines.tapWhy[_nudgeN++ % SkinLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes -------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('skin/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _held = null;
      _cardOpen = false;
      _setMode(LinemanMode.worried);
      _freeze = true;
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
    final speak = await SpokenOnce.first('skin/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? SkinLines.deadlyWord : SkinLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(LinemanMode.idle);
        });
        unawaited(_sayChain([SkinLines.ask]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  // ---- score and result -----------------------------------------------------------

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
    await _say(!_run.passed ? SkinLines.fail : (_quickBonus ? SkinLines.quick : SkinLines.allSet),
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

  // ---- build ----------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = SkinWorldGeo(m.height);
    final j = _run.current;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final aside = [for (final x in j.items) if (_run.rejected.contains(x.id)) x];
    final canAct = !_blocked && _held == null && !_cardOpen;
    final testerState = _run.tested ? j.live : null;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(colorFilter: grey, child: RepaintBoundary(child: CustomPaint(painter: SkinWorldPainter(geo)))),
      ),
      Positioned.fill(
        key: ValueKey('cable-${_run.round}'),
        child: ColorFiltered(
          colorFilter: grey,
          child: IgnorePointer(child: CustomPaint(painter: SkinCablePainter(geo: geo, cable: j.cable, skinned: _used != null && !_freeze))),
        ),
      ),
      // The job card on the pole (tap to read it close).
      Positioned.fromRect(
        key: ValueKey('job-${_run.round}'),
        rect: geo.jobCard,
        child: ColorFiltered(colorFilter: grey, child: _JobSheet(job: j, quiet: quiet, onTap: _openCard)),
      ),
      // The roll: one pocket per tool (the pocket stays, empty, once it is gone).
      for (var i = 0; i < j.items.length; i++)
        Positioned.fromRect(
          key: ValueKey('pocket-${_run.round}-$i'),
          rect: geo.pocket(i, j.items.length),
          child: ColorFiltered(
            colorFilter: grey,
            child: DoDealIn(
              index: i,
              quiet: quiet,
              muted: true,
              child: _RollTool(
                item: j.items[i],
                gone: _run.rejected.contains(j.items[i].id) || _used == j.items[i].id || _held?.id == j.items[i].id,
                enabled: canAct,
                onTake: (at) => _pick(j.items[i], at),
              ),
            ),
          ),
        ),
      for (var i = 0; i < aside.length && i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: ColorFiltered(colorFilter: grey, child: _AsideTool(item: aside[i], quiet: quiet)),
        ),
      if (!_run.gloves)
        Positioned.fromRect(
          key: const ValueKey('gloves'),
          rect: geo.gloves,
          child: ColorFiltered(
            colorFilter: grey,
            child: _Tappable(
              label: SkinLines.glovesLabel,
              onTapUp: canAct ? _wearGloves : null,
              child: const CustomPaint(painter: SkinGlovesPainter()),
            ),
          ),
        ),
      // The tester: on the bench, or held to the cable showing its reading.
      AnimatedPositioned(
        key: const ValueKey('tester'),
        duration: quiet ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        left: (_run.tested ? geo.testerOn : geo.tester).left,
        top: (_run.tested ? geo.testerOn : geo.tester).top,
        width: geo.tester.width,
        height: geo.tester.height,
        child: ColorFiltered(
          colorFilter: grey,
          child: _Tappable(
            label: SkinLines.testerLabel,
            onTapUp: canAct && !_run.tested ? _test : null,
            child: CustomPaint(painter: SkinTesterPainter(state: testerState)),
          ),
        ),
      ),
      if (testerState != null)
        Positioned(
          key: ValueKey('reading-${_run.round}'),
          left: geo.testerOn.right + 2,
          top: geo.testerOn.top - 2,
          child: ColorFiltered(colorFilter: grey, child: _Reading(live: testerState, quiet: quiet)),
        ),
      // The cable end takes the tester too (tap the cable to test it).
      Positioned.fromRect(
        key: const ValueKey('cable-tap'),
        rect: geo.cableEnd,
        child: _Tappable(label: SkinLines.cableLabel, onTapUp: canAct && !_run.tested ? _test : null, child: const SizedBox.expand()),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: ColorFiltered(
          colorFilter: grey,
          child: LinemanFigure(look: _run.gloves ? LinemanLook.trainee : _bareHands, mode: _mode, wake: _wake, quiet: quiet),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final holdUp = playing && _run.tested && _held == null && !_cardOpen && _card == null && !deckUp && !_run.shown && !coworkerOpen;
    final held = _held;
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
              labels: SkinLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (holdUp)
                Positioned(
                  key: const ValueKey('hud-hold'),
                  left: 12,
                  right: 128,
                  bottom: pad.bottom + 18,
                  child: _HoldButton(onTapUp: (d) => _holdJob(d.globalPosition)),
                ),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  item: held,
                  job: _run.current,
                  quiet: quiet,
                  onFound: _found,
                  onAllSeen: _allSeen,
                  onTake: _take,
                  onPutBack: _putBack,
                ),
              if (_cardOpen && playing)
                _JobZoom(
                  key: const ValueKey('job-zoom'),
                  job: _run.current,
                  quiet: quiet,
                  onClose: () => setState(() => _cardOpen = false),
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
              if (playing && _card == null && !_cardOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: quiet ? 300 : 2200,
                  consequence: _LiveFlash(cable: _run.current.cable, quiet: quiet),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: SkinLines.intro,
                  alarm: 'sounds/van_arrive.wav',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _brown = Color(0xFF8C6A2A);
const _bench = Color(0xFF26303B);

/// A tappable scene thing with a screen-reader label.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.label, required this.onTapUp, required this.child});
  final String label;
  final void Function(Offset at)? onTapUp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tap = onTapUp;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: tap == null ? null : (d) => tap(d.globalPosition),
        child: child,
      ),
    );
  }
}

/// The tester's reading beside it: LIVE (red) or 0 V (green).
class _Reading extends StatelessWidget {
  const _Reading({required this.live, required this.quiet});
  final bool live;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF101418),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: live ? const Color(0xFFFF3B30) : const Color(0xFF34C759), width: 1.2),
        ),
        child: Text(live ? SkinLines.live : SkinLines.dead,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: live ? const Color(0xFFFF6B60) : const Color(0xFF5BE07F), height: 1.1)),
      ),
    );
  }
}

/// The job card on the pole (design px): the cable big, the rest small.
class _JobSheet extends StatelessWidget {
  const _JobSheet({required this.job, required this.quiet, required this.onTap});
  final SkinJob job;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.translate(offset: Offset(0, -30 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFFB59B62), width: 0.8),
            boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SkinLines.jobCard, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
              Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
              Text(job.cable.nameBn, maxLines: 3, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: _ink, height: 1.15)),
              const Spacer(),
              Text(SkinLines.shutdown, maxLines: 2, style: bangla(fontSize: 6, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478), height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The job card held up close (tap anywhere to put it back).
class _JobZoom extends StatelessWidget {
  const _JobZoom({super.key, required this.job, required this.quiet, required this.onClose});
  final SkinJob job;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                width: 290,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_rounded, color: _brown, size: 22),
                        const SizedBox(width: 8),
                        Text(SkinLines.jobCard, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text(SkinLines.jobLine(job), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(SkinLines.forJoint, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
                    Text(enDigits(job.siteBn), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
                    Text(SkinLines.shutdown, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF5A6478))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tool standing in its pocket, blade up. From a step away a blade's flaw
/// does not show. Tap it to take it under the lens.
class _RollTool extends StatelessWidget {
  const _RollTool({required this.item, required this.gone, required this.enabled, required this.onTake});
  final SkinItem item;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  Widget build(BuildContext context) {
    if (gone) return Semantics(label: SkinLines.toolLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: SkinLines.toolLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTake(d.globalPosition) : null,
        child: RotatedBox(quarterTurns: 3, child: CustomPaint(painter: SkinToolPainter(tool: item.tool, seen: const {}))),
      ),
    );
  }
}

/// A tool set aside on the bench top, tagged বাতিল.
class _AsideTool extends StatelessWidget {
  const _AsideTool({required this.item, required this.quiet});
  final SkinItem item;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, -40 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: SkinToolPainter(tool: item.tool, flaw: item.flaw))),
          Positioned(
            right: 0,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
              child: Text(SkinLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1A33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.85), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pan_tool_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(SkinLines.hold,
                    textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The close look: the tool held up big under the lens; drag the lens along
/// the blade — a blunt edge or grime shows only where it has been. Then cut
/// with it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.item,
    required this.job,
    required this.quiet,
    required this.onFound,
    required this.onAllSeen,
    required this.onTake,
    required this.onPutBack,
  });
  final SkinItem item;
  final SkinJob job;
  final bool quiet;
  final VoidCallback onFound;
  final VoidCallback onAllSeen;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _seen = {};
  Offset? _lens;
  var _found = false;
  var _all = false;

  void _touch(Offset p, Size s) {
    final b = SkinToolPainter.binAt(widget.item.tool, p.dx / s.width);
    final before = _seen.length;
    if (b != null) {
      for (final x in [b - 1, b, b + 1]) {
        if (x >= 0 && x < kBladeBins) _seen.add(x);
      }
    }
    if (!_found && SkinToolPainter.flawSeen(widget.item.flaw, _seen)) {
      _found = true;
      widget.onFound();
    }
    if (!_all && SkinToolPainter.allSeen(_seen)) {
      _all = true;
      widget.onAllSeen();
    }
    if (_seen.length != before || _lens != p) setState(() => _lens = p);
  }

  Widget _closeUp() => LayoutBuilder(
        builder: (context, box) {
          final s = Size(box.maxWidth, box.maxHeight);
          final (a, _) = SkinToolPainter.bladeSpan(widget.item.tool);
          return Semantics(
            label: SkinLines.handLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _touch(d.localPosition, s),
              onPanUpdate: (d) => _touch(d.localPosition, s),
              onPanEnd: (_) => setState(() => _lens = null),
              onPanCancel: () => setState(() => _lens = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: SkinToolPainter(tool: widget.item.tool, flaw: widget.item.flaw, seen: _seen, veil: _bench)),
                  ),
                  if (_seen.isEmpty) _Lens(at: Offset(s.width * (a + 0.04), s.height * 0.5)),
                  if (_lens != null) _Lens(at: _lens!, live: true),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.translate(
              offset: Offset(0, 80 * (1 - t)),
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                          decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFB59B62))),
                          child: Text(SkinLines.jobLine(widget.job),
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AspectRatio(
                    aspectRatio: 2.3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4654), _bench]),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(child: Padding(padding: const EdgeInsets.fromLTRB(8, 10, 8, 10), child: _closeUp())),
                          Positioned(
                            right: 10,
                            top: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFF31363C))),
                                child: Text(widget.item.tool.nameBn, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: DoBigButton(label: SkinLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                      const SizedBox(width: 12),
                      Expanded(child: DoBigButton(label: SkinLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lens: where to slide (still), or under the finger.
class _Lens extends StatelessWidget {
  const _Lens({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 24.0 : 18.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x33FFFFFF) : const Color(0x22FFFFFF),
            border: Border.all(color: const Color(0xFFFFD34E), width: live ? 2.4 : 1.6),
          ),
          child: Icon(Icons.search_rounded, size: r * 1.1, color: const Color(0xFFFFD34E)),
        ),
      ),
    );
  }
}

/// The deadly move in colour over the frozen scene.
class _LiveFlash extends StatelessWidget {
  const _LiveFlash({required this.cable, required this.quiet});
  final SkinCable cable;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth - 40, 340.0);
        final h = math.min(w * 0.8, box.maxHeight * 0.6);
        return Align(
          alignment: const Alignment(0, -0.25),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1700),
            builder: (_, t, _) {
              final pop = (t * 6).clamp(0.0, 1.0);
              return Opacity(
                opacity: pop,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * pop,
                  child: Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SlmColors.danger, width: 2.5),
                      boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CustomPaint(painter: SkinLiveFlashPainter(t: t, cable: cable)),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
