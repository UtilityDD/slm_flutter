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
import 'm4_earth_fix_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_earth_fix_world.dart' show M4EarthFixGeo, M4EarthFixLook, M4EarthFixSpot;

// Lesson 4.6 "সঠিক আর্থিং পরীক্ষা ও রক্ষণাবেক্ষণ", কাজ 2 "আর্থ মেরামত"
// (Module 4). An LT feeder pillar's body earth is weak; the job is done under
// shutdown (the pillar's handle at OFF). Three rounds a play, each a fresh
// fault in a fresh order:
//   • a loose, rusty joint — at the body clamp or at the electrode's clamp in
//     the pit (lesson point 2: "লুজ বা মরিচা ধরা কানেকশন"); the fix: open it,
//     clean the rust, grease, tighten with a brass/stainless nut (point 4 +
//     pro tip 3);
//   • the earth strip cut / stolen (point 2: "আর্থিং তার চুরি"); the fix:
//     clean both joints, a new earth lead, tighten (flagged: the lesson names
//     the theft, not the replacement steps — clean + tighten are point 4);
//   • the pipe-earth pit dry in dry weather (point 4: water the pit); the
//     fix: open the cover, water through the funnel, refit the cover (point 2:
//     the cover must sit properly).
// Moves: inspect (tap the joint, the strip, the pit — a ring: fine / fault),
// choose (the fix, on a 3-card deck), order (the fix's steps), measure (the
// earth tester, two spikes — fall of potential, point 3), then "কাজ শেষ".
//
// Deadly (lesson myth 1: "আর্থিং তার একটু কাটা থাকলেও লাইন চলে" → no trip
// in a fault, a death): signing off with the earth still cut — also by
// listening to the careless coworker, who comes once on the cut round right
// after the cut is seen: "তার কেটে গেছে? ঝুলিয়ে রাখো, কেউ দেখবে না।".
// Slips: a wrong fix, a step out of order, signing off with a high earth
// left (rusty / dry), signing off without measuring after the fix. Three
// slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_earth_fix_world.dart), corner guide, ◆ on the table → "কেন …?" →
// the next round by itself. Voice: the guide's lines by device TTS; the
// coworker's push by TTS until recorded (his exit line is recorded).
//
// Flagged to the owner: the readings are ours (before: 14.8–36.2 Ω, or "OL"
// on a cut strip; after: 2.3–4.4 Ω, under the lesson's 5–8 Ω for a
// distribution line); the feeder pillar as the site and "under shutdown" are
// ours (the lesson does not say whether earth repair needs a shutdown); the
// replacement steps for a stolen lead are inferred (see above).

// ============================================================================
// Content
// ============================================================================

/// What is wrong with the earth this round.
enum M4EarthFixFault { loose, cut, dry }

/// The fix's steps, in their right order (ids).
List<String> m4EarthFixSteps(M4EarthFixFault f) => switch (f) {
      M4EarthFixFault.loose => const ['open', 'clean', 'grease', 'tight'],
      M4EarthFixFault.cut => const ['clean', 'lead', 'tight'],
      M4EarthFixFault.dry => const ['cover', 'water', 'close'],
    };

@immutable
class M4EarthFixCase {
  const M4EarthFixCase({required this.id, required this.fault, required this.at, required this.before, required this.after});

  final String id;
  final M4EarthFixFault fault;

  /// Where the fault is seen.
  final M4EarthFixSpot at;

  /// The tester before the fix (Ω); null = over range ("OL": the strip is cut).
  final double? before;

  /// The tester after the right fix (Ω), under the lesson's target.
  final double after;

  List<String> get steps => m4EarthFixSteps(fault);

  M4EarthFixLook get look => switch (fault) {
        M4EarthFixFault.loose => M4EarthFixLook.rusty,
        M4EarthFixFault.cut => M4EarthFixLook.cut,
        M4EarthFixFault.dry => M4EarthFixLook.dry,
      };
}

abstract final class M4EarthFixLines {
  static const title = 'আর্থ মেরামত';
  static const intro = 'শাটডাউন নেওয়া আছে। পিলারের আর্থ রিডিং বেশি — খুঁজে সারান!';
  static const rounds = ['ক', 'খ', 'গ'];

  static const askFind = 'আর্থ দুর্বল। গোলমালটা কোথায়? খুঁজে দেখুন।';
  static const askFix = 'কী করে সারাবেন?';
  static const askSteps = 'এবার সারাই — কোন ধাপ আগে?';
  static const askAfter = 'সারাই হলো। এবার কী করবেন?';

  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askFind, askFix, askSteps, askAfter];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// A spot that is fine.
  static const fine = ['এটা ঠিক আছে।', 'এখানে গোলমাল নেই।', 'এটা মজবুত আছে।'];

  /// What he sees at the fault.
  static String seen(M4EarthFixFault f) => switch (f) {
        M4EarthFixFault.loose => 'জোড়ে মরিচা, জোড় লুজ!',
        M4EarthFixFault.cut => 'আর্থ তার কাটা — চুরি গেছে!',
        M4EarthFixFault.dry => 'পিটের মাটি শুকিয়ে ফেটে গেছে!',
      };

  // Labels a worker reads (and screen-reader labels; nothing is written on the scene).
  static const sceneLabel = 'পিলার, আর্থ তার আর আর্থ পিট';
  static const measure = 'মাপুন';
  static const signOff = 'কাজ শেষ — রিপোর্ট';
  static const tester = 'EARTH TESTER';
  static const unit = 'Ω';
  static const settling = '- - -';
  static const over = 'OL';
  static const stepsHead = 'সারাইয়ের ধাপ';
  static String ohm(double? v) => v == null ? over : enDigits(v.toStringAsFixed(1));

  static String step(String id) => switch (id) {
        'open' => 'জোড় খুলুন',
        'clean' => 'মরিচা পরিষ্কার করুন',
        'grease' => 'গ্রিজ লাগান',
        'tight' => 'পিতলের নাটে টাইট দিন',
        'lead' => 'নতুন আর্থ তার লাগান',
        'cover' => 'পিটের ঢাকনা খুলুন',
        'water' => 'ফানেলে জল ঢালুন',
        'close' => 'ঢাকনা ঠিকমতো লাগান',
        _ => id,
      };

  static const stamp = 'আর্থ মজবুত';

  // The fix (choose): right per fault; wrong = field shortcuts and myths
  // (+ another fault's fix that cannot help here). 36–44 letters.
  static List<String> fixRight(M4EarthFixFault f) => switch (f) {
        M4EarthFixFault.loose => const ['জোড় খুলে মরিচা তুলে, গ্রিজ দিয়ে টাইট দিই', 'মরিচা পরিষ্কার করে গ্রিজ লাগিয়ে টাইট করি'],
        M4EarthFixFault.cut => const ['কাটা জায়গায় নতুন আর্থ তার লাগিয়ে টাইট দিই', 'চুরি যাওয়া তার বদলে পুরো নতুন তার লাগাই'],
        M4EarthFixFault.dry => const ['পিটের ফানেলে জল ঢেলে চারপাশের মাটি ভেজাই', 'শুকনো পিটে জল দিয়ে মাটি ভেজা করে তুলি'],
      };
  static const fixShortcuts = [
    'জোড়ের ওপর টেপ জড়িয়ে ঢেকে দিয়ে চলে যাই',
    'মরিচার ওপরেই রং লাগিয়ে চকচকে করে দিই',
    'পাশে একটা লোহার রড পুঁতে দিলেই হবে',
    'কিছু না করে রিপোর্টে আর্থ ঠিক লিখে দিই',
    'সাধারণ লোহার নাট দিয়ে কোনোমতে আটকে দিই',
  ];
  static List<String> fixWrong(M4EarthFixFault f) => switch (f) {
        M4EarthFixFault.loose => [...fixShortcuts, fixRight(M4EarthFixFault.dry).first],
        M4EarthFixFault.cut => [...fixShortcuts, fixRight(M4EarthFixFault.dry).last, 'কাটা তারটা ঝুলিয়ে রেখে পরে দেখা যাবে'],
        M4EarthFixFault.dry => [...fixShortcuts, fixRight(M4EarthFixFault.cut).last],
      };

  // The reason (after "কাজ শেষ"): right ones fit what this round was.
  static const whyAsk = 'কেন কাজ শেষ বললেন?';
  static List<String> whyRight(M4EarthFixFault f) => switch (f) {
        M4EarthFixFault.loose => const ['জোড় সাফ করে টাইট দিয়েছি, মেপে 5 Ω-এর কম', 'মরিচা তুলে টাইট করেছি, রিডিং এখন কম এসেছে'],
        M4EarthFixFault.cut => const ['নতুন তার লাগিয়েছি, মেপে রিডিং 5 Ω-এর কম', 'কাটা তার বদলে মেপেছি, রিডিং এখন কম এসেছে'],
        M4EarthFixFault.dry => const ['পিটে জল দিয়েছি, মেপে রিডিং 5 Ω-এর কম', 'শুকনো পিট ভিজিয়ে মেপেছি, রিডিং এখন কম'],
      };
  static const whyWrong = [
    'লাইন তো চলছিল, আর্থ নিয়ে ভাবার কিছু নেই',
    'যেকোনো লোহার রড পুঁতলেই আর্থ ভালো হয়',
    'দেখতে ঠিক লাগছিল, মাপার দরকার ছিল না',
    'সুপারভাইজার তাড়া দিচ্ছিলেন, তাই শেষ',
    'রিডিং যা-ই আসুক, জোড় তো লাগানো আছে',
    'আর্থিং তো শুধু ঝড়ের দিনে কাজে লাগে',
  ];

  /// The careless coworker: a cut earth is nobody's business to him.
  static const coworker = CoworkerScript(
    line: 'তার কেটে গেছে? ঝুলিয়ে রাখো, কেউ দেখবে না। চলো!',
    exitLine: 'হুঁ! যা খুশি করুন।',
    right: ['না, কাটা আর্থ রেখে কাজ শেষ বলব না', 'না, নতুন তার লাগিয়ে মেপে তবেই শেষ', 'আর্থ কাটা মানে সুরক্ষা নেই, সারাব'],
    wrong: ['ঠিক, লাইন তো চলছে, ঝুলিয়ে রাখি', 'আচ্ছা, কেউ তো দেখবে না, চলো যাই', 'হ্যাঁ, পরে কেউ এসে ঠিক করে দেবে', 'ঠিক আছে, রিপোর্টে লিখে দিই সব ঠিক', 'তাড়া আছে, আজ তারটা এভাবেই থাক'],
    asks: ['ও বলছে ঝুলিয়ে রেখে চলে যেতে। আপনি?', 'কাটা আর্থ রেখে চলে যাবেন?', 'ওর কথা শুনবেন, না সারাবেন?'],
  );

  static const callHeld = 'ঠিক! কাটা আর্থ মানে সুরক্ষা নেই — সারাতেই হবে।';
  static const allSet = 'আর্থ মেরামত শিখে গেছেন — দেখা, সারানো, আবার মাপা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — খুঁজুন, ঠিক সারাই, তারপর মেপে দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtInspect = 'তিন জায়গাই চোখে দেখেছেন';
  static const caughtLoose = 'মরিচা ধরা জোড় সারিয়েছেন';
  static const caughtCut = 'কাটা আর্থ তার বদলেছেন';
  static const caughtDry = 'শুকনো পিটে জল দিয়েছেন';
  static const caughtRetest = 'সারাইয়ের পরে ওহম মেপেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';

  static String caughtFix(M4EarthFixFault f) => switch (f) {
        M4EarthFixFault.loose => caughtLoose,
        M4EarthFixFault.cut => caughtCut,
        M4EarthFixFault.dry => caughtDry,
      };
}

abstract final class M4EarthFixMistakes {
  static const _dir = 'assets/game/art/m4_earth_fix';

  static const wrongFixLoose = DoMistake(
    key: '4.6/m4_earth_fix/wrong-fix-loose',
    textBn: 'জোড় লুজ, মরিচা ধরা — এতে রেজিস্ট্যান্স বহুগুণ বাড়ে। খুলে পরিষ্কার করুন, গ্রিজ দিয়ে পিতল বা স্টেইনলেস নাটে টাইট দিন।',
    art: '$_dir/fix_loose.svg',
    lessonPoint: 3,
  );
  static const wrongFixCut = DoMistake(
    key: '4.6/m4_earth_fix/wrong-fix-cut',
    textBn: 'আর্থ তার কাটা — মাটিতে যাওয়ার পথটাই নেই। নতুন তার লাগিয়ে দুই জোড় টাইট না দিলে আর্থিং অকেজো।',
    art: '$_dir/fix_cut.svg',
    lessonPoint: 1,
  );
  static const wrongFixDry = DoMistake(
    key: '4.6/m4_earth_fix/wrong-fix-dry',
    textBn: 'জোড় আর তার ঠিক আছে, পিট শুকনো। শুকনো আবহাওয়ায় পিটে জল দিলে মাটির আর্দ্রতা বাড়ে, রেজিস্ট্যান্স কমে।',
    art: '$_dir/fix_dry.svg',
    lessonPoint: 3,
  );
  static const orderLoose = DoMistake(
    key: '4.6/m4_earth_fix/order-loose',
    textBn: 'ধাপ উল্টো হলো। আগে জোড় খুলে মরিচা পরিষ্কার, তারপর গ্রিজ, শেষে টাইট — ময়লা জোড়ে টাইট দিলে লাভ নেই।',
    art: '$_dir/fix_loose.svg',
    lessonPoint: 3,
  );
  static const orderCut = DoMistake(
    key: '4.6/m4_earth_fix/order-cut',
    textBn: 'ধাপ উল্টো হলো। আগে জোড়ের জায়গা পরিষ্কার, তারপর নতুন তার, শেষে টাইট — মরিচার ওপর জোড় দুর্বল হয়।',
    art: '$_dir/fix_cut.svg',
    lessonPoint: 3,
  );
  static const orderDry = DoMistake(
    key: '4.6/m4_earth_fix/order-dry',
    textBn: 'ধাপ উল্টো হলো। ঢাকনা খুলে ফানেলে জল, তারপর ঢাকনা ঠিকমতো লাগান — পিটের কভার ঠিকমতো লাগানো থাকা চাই।',
    art: '$_dir/fix_dry.svg',
    lessonPoint: 3,
  );
  static const highLeft = DoMistake(
    key: '4.6/m4_earth_fix/high-left',
    textBn: 'দুর্বল আর্থ রেখেই কাজ শেষ বললেন। আর্থিং ছাড়া ফিউজ, ব্রেকার বা LA ঠিকমতো কাজ করে না — আগে সারান, তারপর মাপুন।',
    art: '$_dir/high_left.svg',
    lessonPoint: 0,
  );
  static const noRetest = DoMistake(
    key: '4.6/m4_earth_fix/no-retest',
    textBn: 'সারাইয়ের পরে মাপেননি। শুধু চোখে দেখা যথেষ্ট নয় — আর্থ টেস্টারে ওহম মাপুন; সাধারণ লাইনে 5–8 Ω-এর কম চাই।',
    art: '$_dir/no_retest.svg',
    lessonPoint: 2,
  );
  static const cutLeft = DoMistake(
    key: '4.6/m4_earth_fix/cut-left',
    textBn: 'কাটা আর্থ ঝুলিয়ে রেখে কাজ শেষ! লাইন চলবে, কিন্তু ফল্টের সময় ব্রেকার ট্রিপ করবে না — বডি ছুঁয়ে মানুষ মরতে পারে।',
    art: '$_dir/cut_left.svg',
    deadly: true,
    lessonPoint: 0,
  );

  static DoMistake wrongFix(M4EarthFixFault f) => switch (f) {
        M4EarthFixFault.loose => wrongFixLoose,
        M4EarthFixFault.cut => wrongFixCut,
        M4EarthFixFault.dry => wrongFixDry,
      };
  static DoMistake order(M4EarthFixFault f) => switch (f) {
        M4EarthFixFault.loose => orderLoose,
        M4EarthFixFault.cut => orderCut,
        M4EarthFixFault.dry => orderDry,
      };

  static List<DoMistake> get all => [wrongFixLoose, wrongFixCut, wrongFixDry, orderLoose, orderCut, orderDry, highLeft, noRetest, cutLeft];
}

@immutable
class M4EarthFixDeal {
  const M4EarthFixDeal({required this.cases, required this.callAt});
  final List<M4EarthFixCase> cases;

  /// The round the careless coworker comes on (the cut one).
  final int callAt;
}

/// Three rounds: a loose rusty joint (at the body or in the pit), a cut
/// strip and a dry pit, in a fresh order with fresh readings.
M4EarthFixDeal m4EarthFixDeal(math.Random rng) {
  T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
  final faults = [...M4EarthFixFault.values]..shuffle(rng);
  final cases = <M4EarthFixCase>[
    for (final (i, f) in faults.indexed)
      M4EarthFixCase(
        id: 'e$i',
        fault: f,
        at: switch (f) {
          M4EarthFixFault.loose => rng.nextBool() ? M4EarthFixSpot.joint : M4EarthFixSpot.pit,
          M4EarthFixFault.cut => M4EarthFixSpot.strip,
          M4EarthFixFault.dry => M4EarthFixSpot.pit,
        },
        before: f == M4EarthFixFault.cut ? null : pick(const [14.8, 18.6, 22.4, 27.9, 31.5, 36.2]),
        after: pick(const [2.3, 2.8, 3.4, 3.9, 4.4]),
      ),
  ];
  return M4EarthFixDeal(cases: cases, callAt: faults.indexOf(M4EarthFixFault.cut));
}

/// The play state (pure logic).
class M4EarthFixRun {
  M4EarthFixRun(this.deal) {
    _startRound();
  }

  final M4EarthFixDeal deal;
  int index = 0;

  final Set<M4EarthFixSpot> looked = {};
  var fixPicked = false;
  int stepsDone = 0;

  /// Measured after the fix was complete.
  var retested = false;

  var shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  M4EarthFixCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  bool get found => looked.contains(current.at);
  bool get fixed => fixPicked && stepsDone >= current.steps.length;

  /// The +5: every spot looked at before signing off.
  bool get thorough => looked.length == M4EarthFixSpot.values.length;

  void _startRound() {
    looked.clear();
    fixPicked = false;
    stepsDone = 0;
    retested = false;
    shown = false;
  }

  /// Look closely at [s]: true when the fault is there.
  bool inspect(M4EarthFixSpot s) {
    if (!_open) return false;
    looked.add(s);
    return s == current.at;
  }

  /// The fix from the deck: a wrong one is a slip (the round goes on).
  DoMistake? pickFix({required bool right}) {
    if (!_open || fixPicked) return null;
    if (right) {
      fixPicked = true;
      return null;
    }
    slips++;
    return M4EarthFixMistakes.wrongFix(current.fault);
  }

  /// A step of the fix: the next one in order, or a slip (the round goes on).
  DoMistake? step(String id) {
    if (!_open || !fixPicked || fixed) return null;
    final steps = current.steps;
    if (steps.indexOf(id) < stepsDone) return null;
    if (steps[stepsDone] == id) {
      stepsDone++;
      return null;
    }
    slips++;
    return M4EarthFixMistakes.order(current.fault);
  }

  /// The earth tester: before the fix the high reading (null = OL), after it
  /// the good one.
  double? measure() {
    if (!_open) return 0;
    if (fixed) {
      retested = true;
      return current.after;
    }
    return current.before;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// "কাজ শেষ — রিপোর্ট".
  DoMistake? signOff() {
    if (!_open) return null;
    shown = true;
    final c = current;
    if (!fixed) {
      if (c.fault == M4EarthFixFault.cut) return deadly = M4EarthFixMistakes.cutLeft;
      slips++;
      return M4EarthFixMistakes.highLeft;
    }
    if (!retested) {
      slips++;
      return M4EarthFixMistakes.noRetest;
    }
    if (thorough) _tag(M4EarthFixLines.caughtInspect);
    _tag(M4EarthFixLines.caughtFix(c.fault));
    _tag(M4EarthFixLines.caughtRetest);
    return null;
  }

  /// Listened to the coworker: signing off as it is.
  DoMistake? giveIn() => signOff();

  void next() {
    index++;
    if (!done) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A round (ms):
/// three spots 4500 (+ the guide's line 1500), the fix deck ~5000, steps
/// 3–4 × 1200 ≈ 4200, measure 2300, sign off 1500, reason ~8200 ≈ 27200;
/// three ≈ 81600, the coworker ~9600: ≈ 91200; 85 % ≈ 78 s.
const m4EarthFixQuickMs = 78000;

@immutable
class M4EarthFixPack {
  const M4EarthFixPack({required this.id, required this.titleBn, this.quickMs = m4EarthFixQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m4EarthFixPacks = {
  'do_4_6_b': M4EarthFixPack(id: 'do_4_6_b', titleBn: M4EarthFixLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4EarthFixPage extends StatefulWidget {
  const M4EarthFixPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M4EarthFixPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4EarthFixPage> createState() => _M4EarthFixPageState();
}

class _M4EarthFixPageState extends State<M4EarthFixPage> {
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
  final M4EarthFixPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_EarthRunPage> createState() => _EarthRunPageState();
}

class _EarthRunPageState extends ConsumerState<_EarthRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4EarthFixRun _run = M4EarthFixRun(m4EarthFixDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _rightBag = LineBag(LearnFeedbackLines.right);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
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
  int _wake = 0;
  var _signed = false;
  var _coworkerArmed = false;
  int _fineN = 0;

  /// The fix deck (choose).
  List<ChoiceOption>? _fixOpts;
  String? _fixPicked;
  String? _fixWrong;

  /// The steps, in the order dealt on the tray this round.
  List<String> _stepOrder = const [];
  String? _stepWrong;

  /// The tester: settling, or its last reading (null = none yet).
  var _settling = false;
  var _spikes = false;
  var _hasReading = false;
  double? _reading;
  final List<double?> _log = [];
  Timer? _settleTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  bool get _fixDeckUp => _fixOpts != null;
  bool get _stepsUp => _run.fixPicked && !_run.fixed && !_run.shown;

  /// He is due on this round and has not come yet (the fix waits for him).
  bool get _coworkerPending => _coworkerArmed && !coworkerDone;

  @override
  void dispose() {
    disposeCoworker();
    _settleTimer?.cancel();
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

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && !_fixDeckUp;

  String get _ask {
    if (!_run.found) return M4EarthFixLines.askFind;
    if (!_run.fixPicked) return M4EarthFixLines.askFix;
    if (!_run.fixed) return M4EarthFixLines.askSteps;
    return M4EarthFixLines.askAfter;
  }

  void _startRound() {
    _settleTimer?.cancel();
    setState(() {
      _signed = false;
      _fixOpts = null;
      _fixPicked = null;
      _fixWrong = null;
      _stepWrong = null;
      _stepOrder = [..._run.current.steps]..shuffle(widget.rng);
      // Never dealt already in order.
      if (_stepOrder.join() == _run.current.steps.join()) _stepOrder = [..._stepOrder.skip(1), _stepOrder.first];
      _settling = false;
      _spikes = false;
      _hasReading = false;
      _reading = null;
      _log.clear();
      _wake++;
    });
    unawaited(_sayChain([M4EarthFixLines.askFind]));
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p, M4EarthFixGeo geo) {
    if (!_canPlay || _settling) return;
    M4EarthFixSpot? hit;
    for (final s in M4EarthFixSpot.values) {
      if (geo.spotHit(s).contains(p)) hit = s;
    }
    if (hit == null) return;
    HapticFeedback.selectionClick();
    final c = _run.current;
    final again = _run.looked.contains(hit);
    if (again && hit == c.at) {
      // The fault again: the fix deck (once he has had his say).
      if (!_run.fixPicked && !_coworkerPending) _openFixDeck();
      return;
    }
    if (again) return;
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    final bad = _run.inspect(hit);
    setState(() => _wake++);
    if (!bad) {
      unawaited(_sayChain([M4EarthFixLines.fine[_fineN++ % M4EarthFixLines.fine.length]]));
      return;
    }
    _cue('sounds/quiz_wrong.wav', volume: 0.35);
    if (_run.index == _run.deal.callAt && !coworkerDone) {
      // His moment: right after the cut is seen.
      _coworkerArmed = true;
      unawaited(_sayChain([M4EarthFixLines.seen(c.fault)], mood: GuideMood.warn));
      scheduleCoworker();
      return;
    }
    unawaited(_sayChain([M4EarthFixLines.seen(c.fault), M4EarthFixLines.askFix], mood: GuideMood.warn));
    _openFixDeck();
  }

  void _openFixDeck() {
    final f = _run.current.fault;
    setState(() {
      _fixOpts = dealChoices(M4EarthFixLines.fixRight(f), M4EarthFixLines.fixWrong(f), widget.rng);
      _fixPicked = null;
      _fixWrong = null;
    });
  }

  Future<void> _onFix(ChoiceOption o, Offset origin) async {
    if (_fixOpts == null || _fixPicked != null || _fixWrong != null || _ended) return;
    setState(() => o.correct ? _fixPicked = o.textBn : _fixWrong = o.textBn);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || _ended) return;
    final m = _run.pickFix(right: o.correct);
    setState(() {
      _fixOpts = null;
      _wake++;
    });
    if (m == null) {
      _cue('sounds/quiz_right.wav', volume: 0.6);
      unawaited(_levelDelta(5, origin, mood: GuideMood.glad));
      unawaited(_sayChain([_rightBag.next().shownBn, M4EarthFixLines.askSteps]));
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  Future<void> _onStep(String id, Offset origin) async {
    if (!_canPlay || !_stepsUp) return;
    HapticFeedback.selectionClick();
    final m = _run.step(id);
    if (m == null) {
      _cue(id == 'water' ? 'sounds/learn/tag_slap.wav' : 'sounds/intro/click.ogg', volume: 0.55);
      setState(() {
        _stepWrong = null;
        _wake++;
      });
      if (_run.fixed) {
        _cue('sounds/quiz_right.wav', volume: 0.5);
        unawaited(_sayChain([M4EarthFixLines.askAfter]));
      }
      return;
    }
    setState(() => _stepWrong = id);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _measure() {
    if (!_canPlay || _settling) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.wav', volume: 0.35);
    _settleTimer?.cancel();
    setState(() {
      _spikes = true;
      _settling = true;
      _wake++;
    });
    _settleTimer = Timer(Duration(milliseconds: _quiet ? 300 : 900), () {
      if (!mounted) return;
      final r = _run.measure();
      setState(() {
        _settling = false;
        _hasReading = true;
        _reading = r;
        _log.insert(0, r);
        if (_log.length > 4) _log.removeLast();
        _wake++;
      });
      _cue('sounds/quiz_select.wav', volume: 0.35);
    });
  }

  // --- the sign-off ----------------------------------------------------------------
  Future<void> _signOff(Offset origin) async {
    if (!_canPlay || _settling) return;
    await _commit(origin);
  }

  Future<void> _commit(Offset origin, {bool gaveIn = false}) async {
    _hush();
    _busy = false;
    _settleTimer?.cancel();
    _settling = false;
    final m = gaveIn ? _run.giveIn() : _run.signOff();
    HapticFeedback.mediumImpact();
    if (m == null) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() {
        _signed = true;
        _wake++;
      });
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final f = _run.current.fault;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(M4EarthFixLines.whyRight(f), M4EarthFixLines.whyWrong, widget.rng),
        question: M4EarthFixLines.whyAsk,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M4EarthFixLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown || _run.fixed) return null;
    if (_intro || _busy || _card != null || reasonOpen || _settling || _fixDeckUp) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the cut lead left hanging, the job signed off.
      await _commit(origin, gaveIn: true);
      return;
    }
    if (!_run.caught.contains(M4EarthFixLines.caughtCall)) _run.caught.add(M4EarthFixLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4EarthFixLines.callHeld, M4EarthFixLines.askFix]));
    if (!_run.fixPicked && !_run.shown && _card == null) _openFixDeck();
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4EarthFixLines.tapWhy[_nudgeN++ % M4EarthFixLines.tapWhy.length]
            : _nudge.next(_ask);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('earthfix/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Signed off with the earth cut: the site freezes grey; later, a fault —
  /// the pillar's body live, nothing trips (in colour); then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('earthfix/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4EarthFixLines.deadlyWord : M4EarthFixLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _stepWrong = null;
        });
        if (_run.shown) {
          _next();
        } else {
          unawaited(_sayChain([_ask]));
        }
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
    await _say(!_run.passed ? M4EarthFixLines.fail : (_quickBonus ? M4EarthFixLines.quick : M4EarthFixLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (coworkerOpen) return LinemanMode.worried;
    if (_signed) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M4EarthFixGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M4EarthFixWorldPainter(
                      geo: geo,
                      look: c.look,
                      faultAt: c.at,
                      looked: {..._run.looked},
                      fixDone: _run.fixPicked ? _run.stepsDone : 0,
                      fixSteps: c.steps.length,
                      spikes: _spikes,
                      dryDay: c.fault == M4EarthFixFault.dry,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (_signed && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: geo.pillar.left - 20,
          width: geo.pillar.width + 40,
          top: geo.pillar.top + 84,
          child: IgnorePointer(child: _StampPop(text: M4EarthFixLines.stamp, quiet: quiet)),
        ),
      // Tap the joint, the strip or the pit: look at it closely.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4EarthFixLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4EarthFixZapPainter(body: geo.pillar, cut: Offset(geo.stripBend.dx, geo.stripMid.dy), v: v)),
            ),
          ),
        ),
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
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
    final deckUp = reasonOpen || coworkerChoiceUp || _fixDeckUp;
    final free = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null;
    final handsOn = free && !_stepsUp;
    final stepsOn = free && _stepsUp;
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
              labels: M4EarthFixLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !_run.done && !deckUp && !stepsOn && (_hasReading || _settling))
                Positioned(
                  key: const ValueKey('hud-tester'),
                  left: 10,
                  bottom: pad.bottom + (handsOn ? 132 : 12),
                  child: _TesterCard(settling: _settling, reading: _reading, log: _log),
                ),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: DoBigButton(label: M4EarthFixLines.measure, filled: false, onDark: true, onTapUp: (_) => _measure()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(label: M4EarthFixLines.signOff, filled: true, onTapUp: (d) => unawaited(_signOff(d.globalPosition)))),
                    ],
                  ),
                ),
              ],
              if (stepsOn)
                Positioned(
                  key: const ValueKey('hud-steps'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: _StepTray(
                      order: _stepOrder,
                      done: _run.current.steps.take(_run.stepsDone).toSet(),
                      wrong: _stepWrong,
                      quiet: quiet,
                      onTap: (id, o) => unawaited(_onStep(id, o)),
                    ),
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('fix-deck-${_run.index}'),
                                options: _fixOpts!,
                                onPick: (o, at) => unawaited(_onFix(o, at)),
                                quiet: quiet,
                                muted: _muted,
                                wrong: {?_fixWrong},
                                picked: _fixPicked,
                              ),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (stepsOn ? 150 : 72)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  line: M4EarthFixLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 3, muted: _muted)),
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

/// The earth tester in his hand, close up: the display (Ω) and his last
/// readings.
class _TesterCard extends StatelessWidget {
  const _TesterCard({required this.settling, required this.reading, required this.log});
  final bool settling;
  final double? reading;
  final List<double?> log;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 164,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8562A), Color(0xFFB83A16)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A1600), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(M4EarthFixLines.tester, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1, color: Color(0xFFFFE9D6))),
            const SizedBox(height: 3),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFFB9C8A6), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF2B2416), width: 1.5)),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(settling ? M4EarthFixLines.settling : M4EarthFixLines.ohm(reading),
                          key: const ValueKey('tester-value'),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E2A1A))),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(M4EarthFixLines.unit, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E2A1A))),
                ],
              ),
            ),
            if (log.length > 1) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 3,
                children: [
                  for (final (i, l) in log.indexed.skip(1))
                    Container(
                      key: ValueKey('log-$i'),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0x552B1606), borderRadius: BorderRadius.circular(5)),
                      child: Text('${M4EarthFixLines.ohm(l)} ${M4EarthFixLines.unit}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFFFF3E4))),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The fix's steps, dealt out of order: tap them in the right order. Done
/// ones turn green with their number; a wrong one flashes red.
class _StepTray extends StatelessWidget {
  const _StepTray({required this.order, required this.done, required this.wrong, required this.quiet, required this.onTap});
  final List<String> order;
  final Set<String> done;
  final String? wrong;
  final bool quiet;
  final void Function(String id, Offset origin) onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final chipW = (w - 24 - 10) / 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, 40 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [SlmColors.navy900.withValues(alpha: 0.94), SlmColors.navy950.withValues(alpha: 0.98)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.45), width: 1.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(M4EarthFixLines.stepsHead, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold300, height: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in order)
                  SizedBox(
                    key: ValueKey('step-$id'),
                    width: chipW,
                    child: _StepChip(
                      label: M4EarthFixLines.step(id),
                      number: done.contains(id) ? done.toList().indexOf(id) + 1 : null,
                      wrong: wrong == id,
                      onTapUp: (d) => onTap(id, d.globalPosition),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, required this.number, required this.wrong, required this.onTapUp});
  final String label;
  final int? number;
  final bool wrong;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final isDone = number != null;
    final edge = isDone ? SlmColors.emerald500 : (wrong ? SlmColors.danger : SlmColors.gold400.withValues(alpha: 0.55));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: isDone ? null : onTapUp,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF15402C) : (wrong ? const Color(0xFF4A1A1A) : const Color(0xFF1B2A48)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: edge, width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isDone ? SlmColors.emerald500 : const Color(0x33FFFFFF)),
                child: isDone ? Text(enDigits('$number'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, maxLines: 2, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2, color: isDone ? const Color(0xFFBFEBD3) : SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.08, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
