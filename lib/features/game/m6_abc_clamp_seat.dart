import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm6_abc_clamp_seat_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_abc_clamp_seat_world.dart' show M6Clamp, M6ClampStage, M6Messenger, M6PoleKind;

// Lesson 6.6 "এবি কেবিল (AB Cable): ঝঞ্ঝাটমুক্ত আধুনিক লাইন", কাজ 1
// "মেসেঞ্জারে ঝোলাও" (pack do_6_6_a, rung 6.6/do/0, engineType
// m6_abc_clamp_seat). A town lane: a bare LT run is being replaced with AB
// cable. The PTW is signed at pole 1, the crew has isolated, proved dead and
// earthed (X1; drawn, not scored); the lesson's safety tip still says: treat
// the AB cable as live while working (PTW, PPE).
//
//  The pull: drag rollers out of the kit bag onto the poles' brackets, then
//    hold 'টানুন'. A pole with no roller scuffs the insulation (a slip; the
//    cable goes back on the drum). A clean pull → ◆ → "কেন?" (rollers).
//  Each pole, left to right: read its place from the lane (the start and the
//    last pole are ends, the road may turn at one middle pole; no labels).
//    Tap the clamp pouch (its three clamps in a dealt order: suspension,
//    tension, an ordinary bare-conductor clamp) and drag one up: the lens.
//  The lens (the core): swipe up / down to roll the twisted bundle; read the
//    ridges (1/2/3) against the messenger (bare, thicker, or a subtle mark —
//    dealt per play); hold the bolt to close the jaw on the core under it.
//    The right clamp on the messenger → ◆ → "কেন?" → এগিয়ে যান, then tap
//    the next pole. The last pole done: the run is up; the pass panel.
//
// Deadly (R23; lesson myth 1 and the safety tip): the first touch of the AB
// cable with no gloves on — the first roll of the bundle or the first jaw
// closed, whichever comes first. The gloves are never prompted:
// they are a bag item, dragged onto the trainee. Slips (R24, needsOwner
// cleared as designed by M6-5): a pull with a pole missing its roller; a jaw
// on a phase core (redo in the lens); a suspension clamp at an end or a turn;
// an ordinary clamp; a tension clamp on a straight pole (an inference, owner).
// A wrong clamp goes back into the pouch. Listening to the coworker (myth 2
// word for word, at the pouch on pole 2 or 3): a slip (B1: the act he pushes
// is a slip). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_abc_clamp_seat_world.dart), the corner guide, ReasonTable
// (the "কেন?" cards at once), CoworkerMoment (the clamp drag waits for him),
// gesture hands for every waiting state (how, never what), MistakeCard,
// FreezeFrame + DoDeathGuard, DoStrikeOut, the pass panel with stars. Idle =
// zero frames (the pull and the roll are one-shots).

// ============================================================================
// Content
// ============================================================================

/// The kit bag's items ([rollers] and [gloves] are dragged out; [pouch] is
/// tapped open on a pole).
enum M6ClampBag { rollers, gloves, pouch }

/// What a reason asks about.
enum M6ClampWhy { rollers, messenger, tension, suspension, identify, gloves }

abstract final class M6ClampLines {
  static const title = 'মেসেঞ্জারে ঝোলাও';

  // DRAFT wording — owner (M6-12): every guide line below is new text.
  static const intro = 'নতুন এবি কেবিল ঝোলাতে হবে — ঠিক ক্ল্যাম্প, ঠিক তারে।';
  static const askPull = 'কেবিলটা পোলগুলোর ওপর দিয়ে টেনে তুলুন।';
  static const askPole = 'এই পোলে কেবিলটা ক্ল্যাম্পে ধরুন।';
  static const askNext = 'পরের পোলে চলুন।';
  static const tasks = [askPull, askPole, askNext];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  static String ask(M6ClampStage s) => switch (s) {
        M6ClampStage.pull => askPull,
        M6ClampStage.pole => askPole,
        M6ClampStage.next || M6ClampStage.done => askNext,
      };

  // On screen (a worker's own words; not spoken).
  static const docket = 'PTW · শাটডাউন · আর্থ';
  static const pull = 'টানুন';
  static const sceneLane = 'গলির লাইন আর পোল';
  static const sceneLens = 'পোলের মাথায় কেবিল আর ক্ল্যাম্প';
  static const backBn = 'ক্ল্যাম্প থলিতে ফেরত';
  static const pouchTitle = 'ক্ল্যাম্প থলি';
  static const stages = ['কেবিল টানা', 'ক্ল্যাম্প লাগানো'];

  static String bag(M6ClampBag b) => switch (b) {
        M6ClampBag.rollers => 'রোলার',
        M6ClampBag.gloves => 'গ্লাভস',
        M6ClampBag.pouch => 'ক্ল্যাম্প থলি',
      };

  static String clamp(M6Clamp c) => switch (c) {
        M6Clamp.suspension => 'সাসপেনশন ক্ল্যাম্প',
        M6Clamp.tension => 'টেনশন ক্ল্যাম্প',
        // A trade name, not 'সাধারণ' (that names the decoy outright; DRAFT).
        M6Clamp.bare => 'বেয়ার ক্ল্যাম্প',
      };

  // The reasons (spec reasonQuestionsBn). The right ones fit what was done
  // (lesson 6.6 points 1–3, pro tips 1–2, myth 1); the wrong ones are the
  // lesson's myths and field excuses. DRAFT wording — owner.
  static const whyQ = <M6ClampWhy, String>{
    M6ClampWhy.rollers: 'টানার আগে কেন রোলার দিলেন?',
    M6ClampWhy.messenger: 'কেন ক্ল্যাম্পটা মেসেঞ্জারেই লাগালেন?',
    M6ClampWhy.tension: 'এই পোলে কেন টেনশন ক্ল্যাম্প?',
    M6ClampWhy.suspension: 'সোজা লাইনের পোলে কেন সাসপেনশন ক্ল্যাম্প?',
    M6ClampWhy.identify: 'কোনটা মেসেঞ্জার — কী দেখে চিনলেন?',
    M6ClampWhy.gloves: 'গ্লাভস পরে কেবিল ধরলেন কেন?',
  };
  static const whyRight = <M6ClampWhy, List<String>>{
    M6ClampWhy.rollers: ['বিশেষ রোলারে টানলে ইনসুলেশনে ঘষা লাগে না', 'রোলার না দিলে টানায় ইনসুলেশন কেটে যায়'],
    M6ClampWhy.messenger: ['মেসেঞ্জারই পুরো কেবিলের টান আর ওজন নেয়', 'সব ক্ল্যাম্প মেসেঞ্জারে, ফেজ কোরে কখনো না'],
    M6ClampWhy.tension: ['লাইন শেষে বা মোড়ে টেনশন ক্ল্যাম্প টান নেয়', 'ডেড এন্ড আর মোড়ে লাগে অ্যাঙ্কারিং ক্ল্যাম্প'],
    M6ClampWhy.suspension: ['সোজা লাইনে সাসপেনশন কেবিল ঝুলিয়ে রাখে', 'সোজা লাইনে মেসেঞ্জার ধরে ঝুলিয়ে রাখাই কাজ'],
    M6ClampWhy.identify: ['রিজ 1, 2, 3 ফেজের — মেসেঞ্জার আলাদা দেখতে', 'যে তারে রিজের দাগ নেই, সেটাই মেসেঞ্জার'],
    M6ClampWhy.gloves: ['ইনসুলেটেড হলেও কাজের সময় কেবিল লাইভ ধরি', 'ইনসুলেশনে অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে'],
  };
  static const myths = [
    'এবি কেবিল তো ইনসুলেটেড, খালি হাতেই ধরা যায়',
    'যেকোনো ক্ল্যাম্প দিয়েই এবি কেবিল লাগানো যায়',
    'যে কোরটা ওপরে থাকে, তাতেই ক্ল্যাম্প দিলে হয়',
    'রোলার শুধু সময় বাঁচায়, ইনসুলেশনে কিছু হয় না',
    'চারটে কোরই সমান, যেকোনোটায় টান দেওয়া যায়',
    'সাসপেনশন ক্ল্যাম্পেই লাইনের শেষের টান ধরে',
    'ফেজ কোর মোটা, ওতেই ক্ল্যাম্প বেশি শক্ত হয়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (once a play, at the pouch on pole 2 or 3). His
  // push is lesson myth 2 word for word (needs his clip; tool/rival_clip.py).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'যেকোনো ক্ল্যাম্প দিয়েই এবি কেবিল লাগানো যায়।',
    exitLine: coworkerExit,
    // DRAFT wording — owner.
    right: ['না, এবি কেবিলে ওর নিজের ক্ল্যাম্পই লাগাব', 'না, সাধারণ ক্ল্যাম্প ইনসুলেশন কেটে দেয়', 'না, ওতে সঠিক গ্রিপও হবে না, নিয়ম মানব'],
    wrong: [
      'ঠিক, তোমার ক্ল্যাম্পটাই লাগিয়ে দিই',
      'আচ্ছা, ক্ল্যাম্প তো ক্ল্যাম্পই, একই',
      'হ্যাঁ, এতে কাজটা অনেক তাড়াতাড়ি হবে',
      'ঠিক আছে, একটা পোলে তো কিছু হবে না',
      'হ্যাঁ, থলি ঘাঁটার আর দরকারই নেই তো',
    ],
    asks: ['কী করবেন?', 'ও বলছে যেকোনো ক্ল্যাম্পেই চলবে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const allCoworkers = [coworker];
  static const callHeld = 'ঠিক! এবি কেবিলে শুধু ওর জন্য তৈরি ক্ল্যাম্প।';

  static const allSet = 'কেবিল ঠিক ক্ল্যাম্পে, টান মেসেঞ্জারে — দারুণ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ঠিক ক্ল্যাম্প, ঠিক তারে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (on screen).
  static const caughtRollers = 'প্রতিটি পোলে রোলার দিয়ে টেনেছেন';
  static const caughtMessenger = 'সব ক্ল্যাম্প মেসেঞ্জারে লাগিয়েছেন';
  static const caughtType = 'শেষে ও মোড়ে টেনশন, সোজায় সাসপেনশন';
  static const caughtGloves = 'গ্লাভস পরে কেবিল ধরেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken guide line (DRAFT wording — owner; to be recorded):
  /// the intro, the tasks, the spoken "why" questions, the call held, the
  /// result lines, the guide's ask about the coworker, and every mistake
  /// text (read aloud the first time).
  static const newGuideLines = [
    intro,
    askPull,
    askPole,
    askNext,
    'টানার আগে কেন রোলার দিলেন?',
    'কেন ক্ল্যাম্পটা মেসেঞ্জারেই লাগালেন?',
    'এই পোলে কেন টেনশন ক্ল্যাম্প?',
    'সোজা লাইনের পোলে কেন সাসপেনশন ক্ল্যাম্প?',
    'কোনটা মেসেঞ্জার — কী দেখে চিনলেন?',
    'গ্লাভস পরে কেবিল ধরলেন কেন?',
    callHeld,
    allSet,
    fail,
    'ও বলছে যেকোনো ক্ল্যাম্পেই চলবে। কী করবেন?',
    M6ClampMistakes.bareHandsBn,
    M6ClampMistakes.noRollerBn,
    M6ClampMistakes.phaseCoreBn,
    M6ClampMistakes.suspensionAtEndBn,
    M6ClampMistakes.tensionOnStraightBn,
    M6ClampMistakes.ordinaryClampBn,
    M6ClampMistakes.listenAnyClampBn,
  ];

  /// The coworker's push (lesson myth 2 word for word; to be recorded in
  /// his voice). His exit line is recorded already.
  static const newRivalLines = ['যেকোনো ক্ল্যাম্প দিয়েই এবি কেবিল লাগানো যায়।'];
}

abstract final class M6ClampMistakes {
  static const _dir = 'assets/game/art/m6_abc_clamp_seat';

  // Lesson 6.6 points (0-based): 0 what AB cable is (the messenger carries the
  // load), 1 the special hardware (suspension on straight lines, tension at a
  // dead end or turn; wrong hardware or a clamp on a phase core damages the
  // cable), 2 installation (special rollers, weak anchoring) and the safety
  // tip (treat it as live; PTW, PPE).
  // DRAFT wording — owner (every text below is read aloud the first time).
  static const bareHandsBn =
      'গ্লাভস ছাড়া এবি কেবিলে হাত দিলেন! ইনসুলেশনে একটি অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, যা মারাত্মক শক দেওয়ার জন্য যথেষ্ট। কাজের সময় একে সবসময় লাইভ ধরুন — গ্লাভস পরে।';
  static const noRollerBn = 'রোলার ছাড়া পোলের ওপর দিয়ে টানলেন — ইনসুলেশনে ঘষা লেগে কেটে যায়। প্রতিটি পোলে বিশেষ রোলার দিয়ে তবে টানুন।';
  static const phaseCoreBn =
      'ক্ল্যাম্প ফেজ কোরে লাগালেন! মেসেঞ্জার তারের বদলে ফেজ কন্ডাক্টরের ওপর ক্ল্যাম্প লাগালে কেবিলটি মারাত্মকভাবে ক্ষতিগ্রস্ত হবে এবং ছিঁড়ে যেতে পারে। রিজ দেখে মেসেঞ্জার চিনে নিন।';
  static const suspensionAtEndBn = 'এই পোলে লাইন শেষ হচ্ছে বা মোড় নিচ্ছে — সাসপেনশন ক্ল্যাম্প এখানে পুরো টান ধরে রাখে না, কেবিল ঝুলে পড়তে পারে। এখানে টেনশন ক্ল্যাম্প লাগে।';
  static const tensionOnStraightBn = 'এই পোলে লাইন সোজা চলেছে — এখানে সাসপেনশন ক্ল্যাম্প মেসেঞ্জার ধরে কেবিলকে ঝুলিয়ে রাখে। টেনশন ক্ল্যাম্প লাইনের শেষে বা মোড়ে।';
  static const ordinaryClampBn = 'সাধারণ বেয়ার কন্ডাক্টরের ক্ল্যাম্প এবি কেবিলের ইনসুলেশনকে কেটে নষ্ট করে দেবে এবং সঠিক গ্রিপও দেবে না। এবি কেবিলের জন্য তৈরি ক্ল্যাম্পই লাগান।';
  static const listenAnyClampBn = 'যেকোনো ক্ল্যাম্পে এবি কেবিল লাগানো যায় না! সাধারণ বেয়ার কন্ডাক্টরের ক্ল্যাম্প ইনসুলেশন কেটে নষ্ট করে, সঠিক গ্রিপও দেয় না।';

  static const bareHands = DoMistake(key: '6.6/m6_abc_clamp_seat/bare-hands', textBn: bareHandsBn, art: '$_dir/bare_hands.svg', deadly: true, lessonPoint: 2);
  static const noRoller = DoMistake(key: '6.6/m6_abc_clamp_seat/no-roller', textBn: noRollerBn, art: '$_dir/no_roller.svg', lessonPoint: 2);
  static const phaseCore = DoMistake(key: '6.6/m6_abc_clamp_seat/phase-core', textBn: phaseCoreBn, art: '$_dir/phase_core.svg', lessonPoint: 1);
  static const suspensionAtEnd = DoMistake(key: '6.6/m6_abc_clamp_seat/suspension-at-end', textBn: suspensionAtEndBn, art: '$_dir/wrong_type.svg', lessonPoint: 1);
  static const tensionOnStraight = DoMistake(key: '6.6/m6_abc_clamp_seat/tension-on-straight', textBn: tensionOnStraightBn, art: '$_dir/wrong_type.svg', lessonPoint: 1);
  static const ordinaryClamp = DoMistake(key: '6.6/m6_abc_clamp_seat/ordinary-clamp', textBn: ordinaryClampBn, art: '$_dir/bare_clamp.svg', lessonPoint: 1);
  static const listenAnyClamp = DoMistake(key: '6.6/m6_abc_clamp_seat/listen-any-clamp', textBn: listenAnyClampBn, art: '$_dir/bare_clamp.svg', lessonPoint: 1);

  static const List<DoMistake> all = [bareHands, noRoller, phaseCore, suspensionAtEnd, tensionOnStraight, ordinaryClamp, listenAnyClamp];
}

/// One play's deal.
@immutable
class M6ClampDeal {
  const M6ClampDeal({
    required this.poles,
    required this.bend,
    required this.messenger,
    required this.order,
    required this.starts,
    required this.bag,
    required this.pouches,
    required this.coworkerPole,
    required this.whyRoll,
  });

  /// 3 or 4 poles; [bend] the middle pole where the road turns, or none.
  final int poles;
  final int? bend;

  final M6Messenger messenger;

  /// The cores round the bundle (0 the messenger, 1–3 the ridge counts).
  final List<int> order;

  /// Per pole: the index in [order] under the jaw when the lens opens.
  final List<int> starts;

  /// The kit bag's layout.
  final List<M6ClampBag> bag;

  /// Per pole: the pouch's order.
  final List<List<M6Clamp>> pouches;

  /// The pole (0-based, 1 or 2) where the coworker comes at the pouch.
  final int coworkerPole;

  final int whyRoll;

  M6PoleKind kind(int i) => m6PoleKind(i, poles, bend);
}

M6ClampDeal m6ClampDeal(math.Random rng) {
  final poles = 3 + rng.nextInt(2);
  // A turn at one middle pole about two plays in three.
  final bend = rng.nextInt(3) == 0 ? null : 1 + rng.nextInt(poles - 2);
  final order = [0, 1, 2, 3]..shuffle(rng);
  return M6ClampDeal(
    poles: poles,
    bend: bend,
    messenger: M6Messenger.values[rng.nextInt(3)],
    order: order,
    starts: [for (var i = 0; i < poles; i++) rng.nextInt(4)],
    bag: [...M6ClampBag.values]..shuffle(rng),
    pouches: [for (var i = 0; i < poles; i++) [...M6Clamp.values]..shuffle(rng)],
    coworkerPole: 1 + rng.nextInt(2),
    whyRoll: rng.nextInt(1000),
  );
}

/// The right clamp for a pole of [kind] (lesson 6.6 point 2).
M6Clamp m6RightClamp(M6PoleKind kind) => kind == M6PoleKind.straight ? M6Clamp.suspension : M6Clamp.tension;

/// The pole's reason topic: one that fits (its clamp type, the messenger, how
/// the messenger was told apart, the gloves), not asked before this play.
M6ClampWhy m6ClampPoleWhy(M6ClampDeal d, int pole, Set<M6ClampWhy> used) {
  final type = d.kind(pole) == M6PoleKind.straight ? M6ClampWhy.suspension : M6ClampWhy.tension;
  final fits = [type, M6ClampWhy.messenger, M6ClampWhy.identify, M6ClampWhy.gloves].where((w) => !used.contains(w)).toList();
  if (fits.isEmpty) return type;
  return fits[(d.whyRoll + pole * 7) % fits.length];
}

/// The right reasons for [w] (the identify ones fit this play's messenger).
List<String> m6ClampWhyRight(M6ClampWhy w, M6Messenger m) {
  if (w != M6ClampWhy.identify) return M6ClampLines.whyRight[w]!;
  return switch (m) {
    M6Messenger.bare => const ['মেসেঞ্জারটা খোলা তার, বাকি তিনটে ঢাকা', 'যে তারে ইনসুলেশন নেই, সেটাই মেসেঞ্জার'],
    M6Messenger.thick => const ['মেসেঞ্জার আকারে আলাদা, তার গায়ে রিজ নেই', 'রিজ 1, 2, 3 ফেজের — মেসেঞ্জার আকারে মোটা'],
    M6Messenger.mark => const ['মেসেঞ্জারের গায়ে আলাদা চিহ্ন, রিজ নয়', 'রিজ 1, 2, 3 ফেজের — মেসেঞ্জারে আলাদা চিহ্ন'],
  };
}

/// Every right reason the level can deal (for the length checks).
List<String> get m6ClampAllWhyRight => [
      ...M6ClampLines.allWhyRight,
      for (final m in M6Messenger.values) ...m6ClampWhyRight(M6ClampWhy.identify, m),
    ];

/// The play state (pure logic).
class M6ClampRun {
  M6ClampRun(this.deal) : tops = [...deal.starts];

  final M6ClampDeal deal;

  M6ClampStage stage = M6ClampStage.pull;

  // The pull.
  final Set<int> rollers = {};
  var pulled = false;
  int? scuffAt;
  var gloves = false;

  // The poles.
  int pole = 0;
  var pouchOpen = false;

  /// The clamp up in the lens (its jaw open), or null.
  M6Clamp? held;

  /// The jaw is closed on the messenger with the right clamp (the reason
  /// comes next).
  var closed = false;
  final List<int> tops;
  final Map<int, M6Clamp> seated = {};
  int rolls = 0;

  // Slips by kind (for "আজ যা ধরলেন").
  var _rollerSlip = false;
  var _coreSlip = false;
  var _typeSlip = false;
  var listened = false;

  /// The reason topics asked this play.
  final Set<M6ClampWhy> asked = {};

  /// The reason now on the table.
  M6ClampWhy? whyNow;

  int slips = 0;
  int stageSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get finished => stage == M6ClampStage.done;
  bool get ended => finished || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && deadly == null && percent >= 55;
  bool get _open => deadly == null && !finished;
  bool get inLens => held != null;

  M6PoleKind get kindNow => deal.kind(pole);

  /// The core now under the jaw (0 = the messenger).
  int get coreUnder => deal.order[tops[pole]];

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stageSlips++;
    return m;
  }

  // --- the pull ---------------------------------------------------------------
  /// A roller on pole [i]'s bracket; true if it is new.
  bool placeRoller(int i) {
    if (!_open || stage != M6ClampStage.pull || pulled || i < 0 || i >= deal.poles) return false;
    return rollers.add(i);
  }

  /// The gloves on; true if they were not on yet.
  bool wearGloves() {
    if (!_open || gloves) return false;
    gloves = true;
    return true;
  }

  /// Hold 'টানুন': a pole with no roller scuffs (a slip; the pull stops
  /// there); else the cable is up over every pole.
  DoMistake? pull() {
    if (!_open || stage != M6ClampStage.pull || pulled) return null;
    for (var i = 0; i < deal.poles; i++) {
      if (!rollers.contains(i)) {
        scuffAt = i;
        _rollerSlip = true;
        return _slip(M6ClampMistakes.noRoller);
      }
    }
    pulled = true;
    scuffAt = null;
    if (!_rollerSlip) _tag(M6ClampLines.caughtRollers);
    return null;
  }

  /// After a scuff: the cable back on the drum.
  void clearScuff() => scuffAt = null;

  /// After the pull's reason: to pole 1.
  void startPoles() {
    if (!pulled || stage != M6ClampStage.pull) return;
    stage = M6ClampStage.pole;
    pole = 0;
  }

  // --- a pole -----------------------------------------------------------------
  bool openPouch() {
    if (!_open || stage != M6ClampStage.pole || held != null || closed || pouchOpen) return false;
    pouchOpen = true;
    return true;
  }

  void closePouch() => pouchOpen = false;

  /// A clamp dragged up out of the pouch: the lens opens with it.
  bool take(M6Clamp c) {
    if (!_open || stage != M6ClampStage.pole || !pouchOpen || held != null) return false;
    held = c;
    pouchOpen = false;
    return true;
  }

  /// The clamp back into the pouch (before its jaw closed).
  bool putBack() {
    if (!_open || held == null || closed) return false;
    held = null;
    pouchOpen = true;
    return true;
  }

  /// A swipe on the bundle: +1 up, −1 down (rolls the next core under the
  /// jaw). Rolling is a hand on the AB cable: with no gloves it is the bare
  /// hand (deadly, R23) — true is returned and [deadly] is set, the bundle
  /// does not turn.
  bool roll(int dir) {
    if (!_open || held == null || closed) return false;
    if (!gloves) {
      deadly = M6ClampMistakes.bareHands;
      return true;
    }
    tops[pole] = ((tops[pole] + dir) % 4 + 4) % 4;
    rolls++;
    return true;
  }

  /// Hold the bolt: the jaw closes on the core under it. No gloves = a bare
  /// hand on the AB cable (deadly; the same as a bare-handed roll). An ordinary clamp, or the wrong AB clamp
  /// for this pole: a slip, back into the pouch. A phase core: a slip, the
  /// jaw opens again (roll and close again). Right: seated.
  DoMistake? closeJaw() {
    final c = held;
    if (!_open || c == null || closed) return null;
    if (!gloves) return deadly = M6ClampMistakes.bareHands;
    if (c == M6Clamp.bare) {
      held = null;
      pouchOpen = true;
      _typeSlip = true;
      return _slip(M6ClampMistakes.ordinaryClamp);
    }
    final right = m6RightClamp(kindNow);
    if (c != right) {
      held = null;
      pouchOpen = true;
      _typeSlip = true;
      return _slip(c == M6Clamp.suspension ? M6ClampMistakes.suspensionAtEnd : M6ClampMistakes.tensionOnStraight);
    }
    if (coreUnder != 0) {
      _coreSlip = true;
      return _slip(M6ClampMistakes.phaseCore);
    }
    closed = true;
    seated[pole] = c;
    return null;
  }

  /// The pole's reason was paid: the lens closes; the next pole, or the run
  /// is done.
  void poleDone() {
    if (!closed) return;
    closed = false;
    held = null;
    if (pole >= deal.poles - 1) {
      stage = M6ClampStage.done;
      if (!_coreSlip) _tag(M6ClampLines.caughtMessenger);
      if (!_typeSlip && !listened) _tag(M6ClampLines.caughtType);
      _tag(M6ClampLines.caughtGloves);
    } else {
      stage = M6ClampStage.next;
    }
  }

  /// Tap pole [i]: only the next one takes him there.
  bool goTo(int i) {
    if (!_open || stage != M6ClampStage.next || i != pole + 1) return false;
    pole = i;
    stage = M6ClampStage.pole;
    return true;
  }

  /// Listened to the coworker (an ordinary clamp: a slip, B1).
  DoMistake listen() {
    listened = true;
    return _slip(M6ClampMistakes.listenAnyClamp);
  }

  /// The table was paid: the next stage's slips count afresh.
  void tablePaid() => stageSlips = 0;
}

/// The coworker's moment: at the pouch on his dealt pole, before its clamp
/// is seated.
bool m6ClampCoworkerFits(M6ClampRun r) =>
    !r.ended && r.stage == M6ClampStage.pole && r.pole == r.deal.coworkerPole && !r.seated.containsKey(r.pole);

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   the pull: 4 rollers + gloves dragged, hold 'টানুন'     ≈ 9000
///     the pull itself 1200, its reason ~8200               ≈ 9400
///   each pole: tap it, the pouch, drag a clamp, ~2 rolls,
///     hold the bolt ≈ 9000, its reason ~8200              ≈ 17200 × 4
///   the coworker once ≈ 9600                              ≈ 96800
/// 85 % ≈ 82000 → 80 s for four poles; one pole less: −15 s (65 s).
const m6ClampQuickMs = 80000;
const m6ClampQuickPerPoleMs = 15000;

/// Test hook: the play state of the page now on screen (tests only).
abstract final class M6ClampProbe {
  @visibleForTesting
  static M6ClampRun? run;
}

@immutable
class M6ClampPack {
  const M6ClampPack({required this.id, required this.titleBn, this.quickMs = m6ClampQuickMs});
  final String id;
  final String titleBn;

  /// The quick-bonus time for four poles.
  final int quickMs;

  int quickFor(int poles) => quickMs - (4 - poles) * m6ClampQuickPerPoleMs;
}

const Map<String, M6ClampPack> m6ClampPacks = {
  'do_6_6_a': M6ClampPack(id: 'do_6_6_a', titleBn: M6ClampLines.title),
};

/// The gesture hand in the lens (how, never what): an up swipe and a down
/// swipe on the bundle in turn; once the player has tapped the lens three
/// times for nothing, every other hint is a hold on the bolt, whatever core
/// is under the jaw.
HintSpec m6ClampLensHint(M6ClampGeo geo, int n, {required bool stuck}) {
  if (stuck && n.isOdd) return HintSpec.hold(geo.bolt, space: HintSpace.scene);
  final up = (n ~/ (stuck ? 2 : 1)).isEven;
  return HintSpec.swipe(Offset(geo.jawX + 60, geo.bundleY + (up ? 20 : -20)), toward: Offset(0, up ? -1 : 1), travel: 40, space: HintSpace.scene);
}

// ============================================================================
// Page
// ============================================================================

class M6ClampSeatPage extends StatefulWidget {
  const M6ClampSeatPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6ClampPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6ClampSeatPage> createState() => _M6ClampSeatPageState();
}

class _M6ClampSeatPageState extends State<M6ClampSeatPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _ClampRunPage(
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

class _ClampRunPage extends ConsumerStatefulWidget {
  const _ClampRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6ClampPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_ClampRunPage> createState() => _ClampRunPageState();
}

/// What a pan on the scene is doing.
enum _Pan { none, roll, swipe }

class _ClampRunPageState extends ConsumerState<_ClampRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6ClampRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  late final AnimationController _pull = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _roll = AnimationController(vsync: this, lowerBound: -1, upperBound: 1, value: 0, duration: const Duration(milliseconds: 260));

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

  /// The pull is running (the scene takes no touch).
  var _pulling = false;

  /// A bag item being dragged out (and where the finger is, global).
  M6ClampBag? _dragItem;
  Offset _dragAt = Offset.zero;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M6ClampBag, GlobalKey> _bagKeys = {for (final b in M6ClampBag.values) b: GlobalKey()};
  final Map<M6Clamp, GlobalKey> _clampKeys = {for (final c in M6Clamp.values) c: GlobalKey()};
  final _sceneKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  int _lensMisses = 0;
  M6ClampGeo? _geoNow;

  // A pan on the scene.
  _Pan _pan = _Pan.none;
  Offset _panFrom = Offset.zero;
  Offset _panNow = Offset.zero;

  static const _bareLook = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
  );
  static const _glovedLook = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
    gloves: true,
    gloveColor: LinemanLook.rubberGloves,
  );

  @override
  void initState() {
    super.initState();
    _run = M6ClampRun(m6ClampDeal(widget.rng));
    M6ClampProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  int get _quickMs => widget.pack.quickFor(_run.deal.poles);

  @override
  void dispose() {
    disposeCoworker();
    _pull.dispose();
    _roll.dispose();
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_pulling && !_run.ended;

  String get _task => M6ClampLines.ask(_run.stage);

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  /// A global point → the scene's design px (null before the first layout).
  Offset? _toScene(Offset global) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  Offset _toGlobal(Offset scene) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return scene;
    return box.localToGlobal(scene);
  }

  // --- the bag ------------------------------------------------------------------
  void _tapBag(M6ClampBag b) {
    if (!_canPlay) return;
    if (b == M6ClampBag.pouch) {
      _togglePouch();
      return;
    }
    // A drag control: a plain tap only tells the hand to show the drag.
    _hints.missTap();
  }

  void _dragStart(M6ClampBag b, Offset global) {
    if (!_canPlay || b == M6ClampBag.pouch) return;
    _tick('sounds/intro/click.ogg', 0.4);
    setState(() {
      _dragItem = b;
      _dragAt = global;
    });
  }

  void _dragMove(Offset global) {
    if (_dragItem == null) return;
    setState(() => _dragAt = global);
  }

  void _dragEnd() {
    final b = _dragItem;
    if (b == null) return;
    setState(() => _dragItem = null);
    if (!_canPlay) return;
    final p = _toScene(_dragAt);
    final geo = _geoNow;
    if (p == null || geo == null) return;
    switch (b) {
      case M6ClampBag.rollers:
        for (var i = 0; i < _run.deal.poles; i++) {
          if (geo.bracketHit(i).inflate(6).contains(p)) {
            if (_run.placeRoller(i)) {
              HapticFeedback.lightImpact();
              _cue('sounds/intro/impact_metal.ogg', volume: 0.45);
              _stepDone();
            }
            return;
          }
        }
      case M6ClampBag.gloves:
        if (_traineeRect(geo).inflate(14).contains(p)) {
          if (_run.wearGloves()) {
            HapticFeedback.lightImpact();
            _cue('sounds/intro/click.ogg', volume: 0.55);
            _stepDone();
          }
          return;
        }
      case M6ClampBag.pouch:
        break;
    }
    _hints.missTap();
  }

  Rect _traineeRect(M6ClampGeo geo) => _run.stage == M6ClampStage.pull ? geo.traineeGround : geo.traineePole(_run.pole);

  // --- the pull ------------------------------------------------------------------
  void _holdPull() {
    if (!_canPlay || _run.stage != M6ClampStage.pull) return;
    final m = _run.pull();
    _cue('sounds/learn/rush_in.ogg', volume: 0.45);
    HapticFeedback.mediumImpact();
    setState(() {
      _pulling = true;
      _wake++;
    });
    unawaited(() async {
      if (_quiet) {
        _pull.value = 1;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        await _pull.forward(from: 0);
      }
      if (!mounted || _ended) return;
      setState(() => _pulling = false);
      if (m != null) {
        final geo = _geoNow;
        unawaited(_mistake(m, geo == null ? Offset.zero : _toGlobal(geo.cableAt(_run.scuffAt ?? 0))));
        return;
      }
      _cue('sounds/intro/confirm.ogg', volume: 0.6);
      putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
      _run.whyNow = M6ClampWhy.rollers;
      _run.asked.add(M6ClampWhy.rollers);
      unawaited(askReason(
        deal: () => dealChoices(M6ClampLines.whyRight[M6ClampWhy.rollers]!, M6ClampLines.myths, widget.rng),
        question: M6ClampLines.whyQ[M6ClampWhy.rollers]!,
        stillValid: () => !_ended,
      ));
    }());
  }

  // --- a pole ----------------------------------------------------------------------
  void _togglePouch() {
    if (_run.stage != M6ClampStage.pole || _run.inLens) {
      _hints.missTap();
      return;
    }
    _tick('sounds/intro/click.ogg', 0.5);
    if (_run.pouchOpen) {
      setState(() {
        _run.closePouch();
        _wake++;
      });
      return;
    }
    _run.openPouch();
    _stepDone();
    if (!coworkerDone && m6ClampCoworkerFits(_run)) scheduleCoworker();
  }

  void _take(M6Clamp c) {
    if (!_canPlay) return;
    if (holdForCoworker()) return;
    if (!_run.take(c)) return;
    HapticFeedback.lightImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    _lensMisses = 0;
    _roll.value = 0;
    _stepDone();
  }

  void _putBack() {
    if (!_canPlay || !_run.putBack()) return;
    _tick('sounds/intro/click.ogg', 0.45);
    _stepDone();
  }

  void _rollOnce(int dir) {
    if (!_canPlay || !_run.roll(dir)) return;
    final bare = _run.deadly;
    if (bare != null) {
      // The first touch of the cable with bare hands (R23).
      final geo = _geoNow;
      final at = geo == null ? null : Offset(geo.jawX, geo.bundleY);
      if (at != null) _flashAt = at;
      setState(() => _wake++);
      unawaited(_mistake(bare, at == null ? Offset.zero : _toGlobal(at)));
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/learn/dull_steel.ogg', volume: 0.35);
    if (_quiet) {
      _roll.value = 0;
    } else {
      _roll.value = dir.toDouble();
      unawaited(_roll.animateTo(0, curve: Curves.easeOut));
    }
    _stepDone();
  }

  void _closeJaw() {
    if (!_canPlay || !_run.inLens || _run.closed) return;
    final geo = _geoNow;
    final m = _run.closeJaw();
    if (m != null) {
      if (geo != null) _flashAt = geo.bolt;
      setState(() => _wake++);
      unawaited(_mistake(m, geo == null ? Offset.zero : _toGlobal(geo.bolt)));
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
    _stepDone();
    putOnTable(15 + (_run.stageSlips == 0 ? 5 : 0));
    final topic = m6ClampPoleWhy(_run.deal, _run.pole, _run.asked);
    _run.whyNow = topic;
    _run.asked.add(topic);
    unawaited(askReason(
      deal: () => dealChoices(m6ClampWhyRight(topic, _run.deal.messenger), M6ClampLines.myths, widget.rng),
      question: M6ClampLines.whyQ[topic]!,
      stillValid: () => !_ended,
    ));
  }

  void _goTo(int i) {
    if (!_run.goTo(i)) {
      _hints.missTap();
      return;
    }
    _hush();
    _cue('sounds/learn/stomp.ogg', volume: 0.5);
    _stepDone();
    unawaited(_sayChain([_task]));
  }

  // --- the scene's touches ---------------------------------------------------------
  void _tapScene(Offset p, M6ClampGeo geo) {
    if (!_canPlay) return;
    if (_run.inLens) {
      if (geo.backHit.contains(p)) {
        _putBack();
        return;
      }
      _lensMisses++;
      _hints.missTap();
      return;
    }
    if (_run.stage == M6ClampStage.next) {
      for (var i = 0; i < _run.deal.poles; i++) {
        if (geo.poleHit(i).contains(p)) {
          _goTo(i);
          return;
        }
      }
    }
    _hints.missTap();
  }

  void _holdScene(Offset p, M6ClampGeo geo) {
    if (_canPlay && _run.inLens && geo.boltHit.contains(p)) {
      _pan = _Pan.none;
      _closeJaw();
      return;
    }
    _panStart(p, geo);
  }

  void _panStart(Offset p, M6ClampGeo geo) {
    _pan = _Pan.none;
    if (!_canPlay) return;
    _panFrom = p;
    _panNow = p;
    _pan = _run.inLens && geo.bundleHit.contains(p) ? _Pan.roll : _Pan.swipe;
  }

  void _panUpdate(Offset p) => _panNow = p;

  void _panEnd() {
    final kind = _pan;
    _pan = _Pan.none;
    final d = _panNow - _panFrom;
    switch (kind) {
      case _Pan.roll:
        if (!_canPlay) return;
        if (d.dy.abs() >= 24 && d.dy.abs() > d.dx.abs()) {
          _rollOnce(d.dy < 0 ? 1 : -1);
        } else {
          _hints.missTap();
        }
      case _Pan.swipe:
        if (_canPlay) _hints.missTap();
      case _Pan.none:
        break;
    }
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
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
    _run.tablePaid();
    _run.whyNow = null;
    if (_run.stage == M6ClampStage.pull) {
      _run.startPoles();
      setState(() => _wake++);
      unawaited(_sayChain([_task]));
      return;
    }
    _run.poleDone();
    setState(() => _wake++);
    if (_run.finished) {
      unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 900), () {
        if (mounted && !_ended) unawaited(_finish());
      }));
      return;
    }
    unawaited(_sayChain([_task]));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6ClampLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !m6ClampCoworkerFits(_run)) return null;
    if (_intro || _card != null || tableBusy || _freeze || _pulling || _dragItem != null || _run.inLens || !_run.pouchOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listen();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6ClampLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6ClampLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6ClampLines.tapWhy[_nudgeN++ % M6ClampLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
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
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6abcclamp/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A bare hand on the AB cable: the scene freezes grey and the shock comes
  /// off the bolt in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _dragItem = null;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m6abcclamp/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6ClampLines.deadlyWord : M6ClampLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The play goes on from where it was; a scuffed pull goes back on
        // the drum.
        _hush();
        setState(() {
          if (_run.scuffAt != null) {
            _run.clearScuff();
            _pull.value = 0;
          }
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
      if (mark == 100 && _clock.elapsedMilliseconds < _quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < _quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M6ClampLines.fail : (_quickBonus ? M6ClampLines.quick : M6ClampLines.allSet),
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

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_dragItem != null || _pulling || _run.inLens) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6ClampLaneRig get _laneRig => M6ClampLaneRig(
        poles: _run.deal.poles,
        bend: _run.deal.bend,
        rollers: {..._run.rollers},
        pulled: _run.pulled,
        seated: {..._run.seated},
        at: _run.stage == M6ClampStage.pull ? -1 : _run.pole,
        stage: _run.stage,
        scuffAt: _run.scuffAt,
      );

  M6ClampLensRig? get _lensRig {
    final c = _run.held;
    if (c == null) return null;
    return M6ClampLensRig(clamp: c, order: _run.deal.order, top: _run.tops[_run.pole], messenger: _run.deal.messenger, closed: _run.closed);
  }

  /// The bag items on show: the pull has all three; on the poles the gloves
  /// (until worn) and the pouch.
  List<M6ClampBag> get _bagNow => [
        for (final b in _run.deal.bag)
          if (b == M6ClampBag.pouch || (b == M6ClampBag.gloves && !_run.gloves) || (b == M6ClampBag.rollers && _run.stage == M6ClampStage.pull)) b,
      ];

  /// The gesture hand: how to touch, never what. The pull: a sweep over the
  /// bag, an upward drag out of the bag (each item in turn), a sweep over
  /// every bracket alike ('টানুন' gets none). On a pole: a sweep over the
  /// bag. The next pole: a tap on it (the one way forward). The pouch open: a
  /// sweep over its clamps and an upward drag from each in turn. The lens:
  /// [m6ClampLensHint].
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    if (_run.inLens) return m6ClampLensHint(geo, n, stuck: _lensMisses >= 3);
    if (_run.pouchOpen) {
      final order = _run.deal.pouches[_run.pole];
      if (n.isEven) return HintSpec.sweepOver([for (final c in order) _clampKeys[c]!]);
      return HintSpec.dragFrom(_clampKeys[order[(n ~/ 2) % order.length]]!, toward: const Offset(0, -1), travel: 50);
    }
    final bag = _bagNow;
    switch (_run.stage) {
      case M6ClampStage.pull:
        final drags = [for (final b in bag) if (b != M6ClampBag.pouch) b];
        final ways = <HintSpec? Function()>[
          () => HintSpec.sweepOver([for (final b in bag) _bagKeys[b]!]),
          if (drags.isNotEmpty) () => HintSpec.dragFrom(_bagKeys[drags[(n ~/ 3) % drags.length]]!, toward: const Offset(0, -1), travel: 60),
          () => HintSpec.sweep([for (var i = 0; i < _run.deal.poles; i++) geo.bracketHit(i)], space: HintSpace.scene),
        ];
        return ways[n % ways.length]();
      case M6ClampStage.pole:
        return HintSpec.sweepOver([for (final b in bag) _bagKeys[b]!]);
      case M6ClampStage.next:
        return HintSpec.tap(geo.poleHit(_run.pole + 1).center, space: HintSpace.scene);
      case M6ClampStage.done:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6ClampGeo.forScene(m.height, m.inset, poles: _run.deal.poles, bend: _run.deal.bend);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final lens = _lensRig;
    final traineeAt = _traineeRect(geo);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('lane'),
                child: RepaintBoundary(child: CustomPaint(painter: M6ClampLanePainter(geo: geo, rig: _laneRig, pull: _pull))),
              ),
              Positioned.fromRect(
                key: ValueKey('trainee-${_run.stage == M6ClampStage.pull ? 'ground' : 'pole${_run.pole}'}'),
                rect: traineeAt,
                child: LinemanFigure(look: _run.gloves ? _glovedLook : _bareLook, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (lens != null)
                Positioned.fill(
                  key: ValueKey('lens-${_run.pole}'),
                  child: RepaintBoundary(child: CustomPaint(painter: M6ClampLensPainter(geo: geo, rig: lens, roll: _roll))),
                ),
            ],
          ),
        ),
      ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: lens != null ? M6ClampLines.sceneLens : M6ClampLines.sceneLane,
          child: GestureDetector(
            key: _sceneKey,
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            // A finger that rests ~0.5 s: on the bolt, that is the hold that
            // closes the jaw; anywhere else it carries on as the same pan.
            onLongPressStart: (d) => _holdScene(d.localPosition, geo),
            onLongPressMoveUpdate: (d) => _panUpdate(d.localPosition),
            onLongPressEnd: (_) => _panEnd(),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6ClampFlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
      // A place change (the next pole, the lens): a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('place-${_run.stage.name}-${_run.pole}-${_run.inLens}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.stage == M6ClampStage.pull ? 0 : 0.4, end: 0),
              duration: const Duration(milliseconds: 420),
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
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended;
    final bag = _bagNow;
    final pullBtn = _run.stage == M6ClampStage.pull;
    final cells = bag.length + (pullBtn ? 1 : 0);
    final itemW = math.min(92.0, (size.width - 8) / math.max(1, cells));
    final drag = _dragItem;
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
              labels: M6ClampLines.stages,
              done: {if (_run.pulled) 0, if (_run.finished) 1},
              current: _run.finished ? null : (_run.pulled ? 1 : 0),
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_pulling && drag == null,
            hintKey: '${_run.stage.name}/${_run.pole}/$_steps/${_run.pouchOpen}/${_run.held?.name}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing)
                Positioned(
                  key: const ValueKey('docket'),
                  top: pad.top + 92,
                  left: 10,
                  child: const IgnorePointer(child: _DocketChip(text: M6ClampLines.docket)),
                ),
              if (handsOn && cells > 0)
                Positioned(
                  key: ValueKey('hud-bag-${_run.stage.name}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final b in bag)
                        _BagButton(
                          key: _bagKeys[b],
                          icon: _bagIcons[b]!,
                          label: M6ClampLines.bag(b),
                          width: itemW,
                          on: b == M6ClampBag.pouch ? _run.pouchOpen : drag == b,
                          onTap: () => _tapBag(b),
                          onDragStart: b == M6ClampBag.pouch ? null : (g) => _dragStart(b, g),
                          onDragMove: _dragMove,
                          onDragEnd: _dragEnd,
                        ),
                      if (pullBtn)
                        _BagButton(
                          key: const ValueKey('pull-btn'),
                          icon: Icons.swap_horiz_rounded,
                          label: M6ClampLines.pull,
                          width: itemW,
                          on: _pulling,
                          hold: true,
                          onTap: () {
                            if (_canPlay) _hints.missTap();
                          },
                          onHold: _holdPull,
                        ),
                    ],
                  ),
                ),
              if (handsOn && _run.pouchOpen)
                Positioned(
                  key: ValueKey('pouch-${_run.pole}'),
                  left: 12,
                  right: 12,
                  // In the sky where the lens opens: clear of the guide's
                  // bubble and of the poles.
                  top: pad.top + 128,
                  child: _PouchPanel(
                    order: _run.deal.pouches[_run.pole],
                    keys: _clampKeys,
                    onTake: _take,
                    onTap: () {
                      if (_canPlay) _hints.missTap();
                    },
                  ),
                ),
              if (drag != null)
                Positioned(
                  key: const ValueKey('drag-ghost'),
                  left: _dragAt.dx - 26,
                  top: _dragAt.dy - 26,
                  child: IgnorePointer(child: _Ghost(icon: _bagIcons[drag]!)),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  sound: FailSound.thud,
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
                  line: M6ClampLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
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

  static const _bagIcons = {
    M6ClampBag.rollers: Icons.album_rounded,
    M6ClampBag.gloves: Icons.back_hand_rounded,
    M6ClampBag.pouch: Icons.work_rounded,
  };
}

// ============================================================================
// Pieces
// ============================================================================

/// The docket on the job (a worker reads it).
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6F7F1DE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB03A2E), width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 13, color: Color(0xFFB03A2E)),
          const SizedBox(width: 5),
          Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
        ],
      ),
    );
  }
}

/// A kit-bag item (or the 'টানুন' hold): a round icon with its name under it.
/// Dragged items report the finger in global px; [hold]: a hold control.
class _BagButton extends StatelessWidget {
  const _BagButton({
    super.key,
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onHold,
    this.hold = false,
    this.width = 80,
  });
  final IconData icon;
  final String label;
  final double width;
  final bool on;
  final bool hold;
  final VoidCallback onTap;
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset>? onDragMove;
  final VoidCallback? onDragEnd;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    final drags = onDragStart != null;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTap: onTap,
        onLongPress: onHold,
        onPanStart: drags ? (d) => onDragStart!(d.globalPosition) : null,
        onPanUpdate: drags ? (d) => onDragMove?.call(d.globalPosition) : null,
        onPanEnd: drags ? (_) => onDragEnd?.call() : null,
        onPanCancel: drags ? () => onDragEnd?.call() : null,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: hold ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: hold ? BorderRadius.circular(14) : null,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, softWrap: false, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The item under the finger while it is dragged out of the bag.
class _Ghost extends StatelessWidget {
  const _Ghost({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xCC1C2E4A),
        border: Border.all(color: SlmColors.gold300, width: 2),
      ),
      child: Icon(icon, size: 26, color: SlmColors.gold300),
    );
  }
}

/// The open clamp pouch: three clamps side by side, all the same size, in
/// the pole's dealt order. Drag one up to take it; a tap does nothing.
class _PouchPanel extends StatelessWidget {
  const _PouchPanel({required this.order, required this.keys, required this.onTake, required this.onTap});
  final List<M6Clamp> order;
  final Map<M6Clamp, GlobalKey> keys;
  final ValueChanged<M6Clamp> onTake;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xF2101A2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M6ClampLines.pouchTitle, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.gold300)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final c in order)
                Expanded(
                  child: _ClampTile(key: ValueKey('clamp-${c.name}'), hintKey: keys[c]!, clamp: c, onTake: () => onTake(c), onTap: onTap),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClampTile extends StatefulWidget {
  const _ClampTile({super.key, required this.hintKey, required this.clamp, required this.onTake, required this.onTap});
  final GlobalKey hintKey;
  final M6Clamp clamp;
  final VoidCallback onTake;
  final VoidCallback onTap;

  @override
  State<_ClampTile> createState() => _ClampTileState();
}

class _ClampTileState extends State<_ClampTile> {
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    final label = M6ClampLines.clamp(widget.clamp);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onVerticalDragStart: (_) => _dy = 0,
        onVerticalDragUpdate: (d) => setState(() => _dy = math.min(0.0, _dy + d.delta.dy)),
        onVerticalDragEnd: (_) {
          final up = _dy <= -40;
          setState(() => _dy = 0);
          if (up) widget.onTake();
        },
        onVerticalDragCancel: () => setState(() => _dy = 0),
        child: KeyedSubtree(
          key: widget.hintKey,
          child: Transform.translate(
            offset: Offset(0, _dy.clamp(-60.0, 0.0)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2E4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40, width: 64, child: CustomPaint(painter: _ClampIconPainter(widget.clamp))),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1, softWrap: false, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
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

/// A clamp drawn small in the pouch (each the same size).
class _ClampIconPainter extends CustomPainter {
  const _ClampIconPainter(this.clamp);
  final M6Clamp clamp;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final metal = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD5DBE1), Color(0xFF8C959F)]).createShader(Offset.zero & size);
    final dark = Paint()..color = const Color(0xFF4E565F);
    final wire = Paint()
      ..color = const Color(0xFF8C959F)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    switch (clamp) {
      case M6Clamp.suspension:
        canvas.drawLine(Offset(c.dx, 2), Offset(c.dx, c.dy - 6), wire);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + const Offset(0, 2), width: 40, height: 14), const Radius.circular(7)), metal);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + const Offset(0, 9), width: 34, height: 6), const Radius.circular(3)), dark);
      case M6Clamp.tension:
        canvas.drawArc(Rect.fromCenter(center: Offset(c.dx - 24, c.dy), width: 14, height: 20), math.pi / 2, math.pi, false, wire);
        final body = Path()
          ..moveTo(c.dx - 18, c.dy - 8)
          ..lineTo(c.dx + 28, c.dy - 3)
          ..lineTo(c.dx + 28, c.dy + 6)
          ..lineTo(c.dx - 18, c.dy + 6)
          ..close();
        canvas.drawPath(body, metal);
        canvas.drawRect(Rect.fromLTWH(c.dx - 16, c.dy + 3, 40, 4), dark);
      case M6Clamp.bare:
        canvas.drawLine(Offset(c.dx, 2), Offset(c.dx, c.dy - 8), wire);
        canvas.drawRect(Rect.fromCenter(center: c - const Offset(0, 2), width: 40, height: 12), dark);
        for (final ux in [c.dx - 12, c.dx + 12]) {
          canvas.drawArc(Rect.fromCenter(center: Offset(ux, c.dy + 6), width: 12, height: 14), 0, math.pi, false, wire);
        }
    }
  }

  @override
  bool shouldRepaint(_ClampIconPainter old) => old.clamp != clamp;
}
