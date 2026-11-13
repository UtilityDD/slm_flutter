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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_comealong_pull_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm2_comealong_pull_world.dart' show PullAnchor, PullGeo, PullSpot;

// Lesson 2.4 "কাম-অ্যালং ক্ল্যাম্প: নিয়ন্ত্রিত শক্তি", কাজ 2 "নিয়ন্ত্রিত টান"
// (pack do_2_4_b, engine m2_comealong_pull). The line is dead: shutdown, PTW
// and the earth set on all three conductors (drawn on the pole; the docket
// says so). One conductor of the span sags low; the trainee is up the
// dead-end pole with the come-along and a wire grip and brings it to the
// right sag. Four stations a play:
//   ক rig — the lesson's steps 1–3: the come-along's fixed end on a strong,
//     reliable anchor (the pole strap or the cross-arm's base — not the
//     insulator string, the arm's tip or the danger plate's loose bracket),
//     then the grip on the conductor, then the hook on the grip's eye-bolt;
//   খ spot — before the pull, where to stand: never right in front of or
//     behind the line of pull (the slingshot), always beside it;
//   গ pull — step 4: slow, controlled strokes (hold the handle down), and
//     after every stroke see that the ratchet locked (once a play the pawl
//     does not seat and the wheel runs back: seat it before the next stroke);
//     stop at the right sag (the two good conductors beside it) — sag down,
//     tension up (advanced fact), never past the tool's capacity (point 1);
//     the careless coworker pushes "a pipe on the handle" (pro tip 4);
//   ঘ release — point 3: once the conductor is in its clamp, let the load off
//     slowly, notch by notch, never all at once.
//
// Deadly (lesson point 2, the slingshot): standing in the line of pull.
// Slips: a weak anchor, the grip before the anchor, a stroke (or "done") with
// the pawl not seated, pulling past the right sag, "done" while it still sags
// (a stop before the right sag: no free probing — audit 2026-11-11), the pipe
// on the handle (listening to the coworker), letting the load off at once.
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m2_comealong_pull_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next station by itself; the coworker once a play, mid-pull:
// the next stroke (or "done") waits for him (holdForCoworker), and once the
// conductor is at the right sag his push no longer fits (he does not come).
// A station is won once: taps after it (e.g. a second spot) do nothing.
// Gesture hints: a sweep over the choices (tools, places on the pole, spots,
// the handle's controls); a tap only on the hook (the one way forward) or
// the one tool left.
// Voice: the guide's lines by device TTS; the coworker's push has no clip
// yet (silent, caption held); his exit line is recorded.

// ============================================================================
// Content
// ============================================================================

enum PullStation { rig, spot, pull, release }

enum PullTool { comeAlong, grip }

abstract final class PullLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askRig, askHook, askSpot, askPull, askRelease];

  static const title = 'নিয়ন্ত্রিত টান';
  static const intro = 'লাইন বন্ধ, আর্থ লাগানো। ঝুলে পড়া তারটা কাম-অ্যালং দিয়ে টেনে ঠিক করুন — নিয়ন্ত্রিত টানে!';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];

  static const askRig = 'কাম-অ্যালং আর গ্রিপ লাগান।';
  static const askHook = 'এবার হুকটা লাগান।';
  static const askSpot = 'টান দেওয়ার আগে — কোথায় দাঁড়াবেন?';
  static const askPull = 'তারটা টানুন — পাশের তারগুলোর মতো স্যাগে আনুন।';
  static const askRelease = 'তার ক্ল্যাম্পে আটকানো। এবার কাম-অ্যালং-এর লোড ছাড়ুন।';
  static String ask(PullStation s, {bool rigged = false}) => switch (s) {
        PullStation.rig => rigged ? askHook : askRig,
        PullStation.spot => askSpot,
        PullStation.pull => askPull,
        PullStation.release => askRelease,
      };
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// "done" while the conductor still sags more than the others (the slip
  /// card's head line idea; kept for the voice script).
  static const stillSlack = 'তারটা এখনো পাশের তারগুলোর চেয়ে বেশি ঝুলে আছে।';

  // Labels a worker reads.
  static const sceneLabel = 'পোলের মাথা';
  static const comeAlong = 'কাম-অ্যালং';
  static const grip = 'ওয়্যার গ্রিপ';
  static const ratchet = 'র‍্যাচেট';
  static const pull = 'টানুন';
  static const done = 'টান ঠিক আছে';
  static const slowRelease = 'ধীরে ছাড়ুন';
  static const fastRelease = 'এক ঝটকায় ছাড়ুন';
  static const docket = 'ডকেট';
  static const job = 'স্যাগ ঠিক করা';
  static const permit = 'শাটডাউন · PTW · আর্থ';
  static const stampDone = 'টান ঠিক';

  // The reasons (lesson 2.4): the right ones state this station's rule; the
  // wrong ones are field excuses — never a true rule marked wrong.
  static const whyRig = 'কেন এভাবে লাগালেন?';
  static const whySpot = 'কেন ওখানে দাঁড়ালেন?';
  static const whyPull = 'টানটা এভাবে কেন দিলেন?';
  static const whyRelease = 'লোড এভাবে কেন ছাড়লেন?';
  static String why(PullStation s) => switch (s) {
        PullStation.rig => whyRig,
        PullStation.spot => whySpot,
        PullStation.pull => whyPull,
        PullStation.release => whyRelease,
      };

  static const rigWhy = [
    'সব টান অ্যাঙ্করে পড়ে, তাই মজবুত জায়গা চাই',
    'পোলের স্ট্র্যাপ বা ক্রস-আর্মের গোড়াই মজবুত',
    'আগে অ্যাঙ্কর, পরে গ্রিপ, শেষে হুক — এই ধাপ',
  ];
  static const spotWhy = [
    'কিছু খুললে স্লিং-শট টানের লাইন ধরেই ছোটে',
    'লাইনের সামনে-পেছনে নয়, পাশে থাকতে হয়',
    'গ্রিপ পিছলালে আঘাতটা টানের লাইনেই লাগে',
  ];
  static const pullWhy = [
    'মসৃণ টানই ঠিক, ঝাঁকুনি মানেই বিপদের লক্ষণ',
    'প্রতি টানে র‍্যাচেট লক হলো কি না দেখতে হয়',
    'স্যাগ যত কমে টেনশন তত বাড়ে, তাই বেশি নয়',
  ];
  static const releaseWhy = [
    'হঠাৎ ছাড়লে তার আর যন্ত্র দুটোরই ক্ষতি হয়',
    'লোড ছাড়াই সবচেয়ে ঝুঁকির ধাপ, তাই ধীরে',
    'ধৈর্য আর নিয়ন্ত্রণেই লোড নিরাপদে নামে',
  ];
  static List<String> whyRight(PullStation s) => switch (s) {
        PullStation.rig => rigWhy,
        PullStation.spot => spotWhy,
        PullStation.pull => pullWhy,
        PullStation.release => releaseWhy,
      };

  /// Field excuses (wrong on every deck).
  static const excuses = [
    'তাড়াতাড়ি শেষ হবে, তাই এভাবেই করলাম',
    'সবাই তো এভাবেই করে, কিছু হয় না কখনো',
    'যন্ত্রটা খুব শক্ত, এতে কিছুই ভাঙবে না',
    'সুপারভাইজার দেখছেন না, এতেই চলে যাবে',
    'লাইন তো বন্ধ, তাই আর কোনো বিপদ নেই',
    'অভিজ্ঞ লাইনম্যান আন্দাজেই কাজটা সারে',
  ];

  /// The careless coworker: a pipe on the handle (pro tip 4).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'হ্যান্ডেলে একটা পাইপ লাগিয়ে জোরে টানো! এক টানেই হয়ে যাবে।',
    exitLine: coworkerExit,
    right: ['না, পাইপ লাগালে যন্ত্র ভেঙে যেতে পারে', 'না, হ্যান্ডেলেই ধীরে ধীরে টেনে নেব', 'না, বাড়তি লিভারেজ যন্ত্রের সীমার বাইরে'],
    wrong: ['ঠিক, পাইপ দিলে এক টানেই হয়ে যাবে', 'আচ্ছা, একটা পাইপ এনে এখনই লাগাই', 'জোরে টানলেই কাজটা তাড়াতাড়ি হয়', 'যন্ত্র তো শক্ত, পাইপে কিছু হবে না', 'ঠিক আছে, শেষ টানটা পাইপ দিয়েই দিই'],
    asks: ['ও বলছে পাইপ লাগাতে। আপনি কী করবেন?', 'পাইপ লাগাবেন, না হ্যান্ডেলেই টানবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );

  static const allSet = 'নিয়ন্ত্রিত টান শিখে গেছেন — মজবুত অ্যাঙ্কর, পাশে দাঁড়ানো, ধীরে টান, ধীরে ছাড়া।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ধাপ মেনে, পাশে দাঁড়িয়ে, ধীরে।';
  static const deadlyWord = 'সরে দাঁড়ান!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtAnchor = 'মজবুত অ্যাঙ্কর, ধাপ মেনে';
  static const caughtSpot = 'টানের লাইনের পাশে দাঁড়িয়েছেন';
  static const caughtPawl = 'র‍্যাচেট লক না হওয়া ধরেছেন';
  static const caughtSag = 'ধীরে টেনে ঠিক স্যাগ';
  static const caughtRelease = 'লোড ধীরে ধীরে ছেড়েছেন';
  static const caughtCall = 'চাপে “না” — পাইপ নয়';
}

abstract final class PullMistakes {
  static const _dir = 'assets/game/art/m2_comealong_pull';

  static const weakAnchor = DoMistake(
    key: '2.4/pull/weak-anchor',
    textBn: 'পুরো টান অ্যাঙ্করে পড়ে। ইনসুলেটর, ক্রস-আর্মের ডগা বা ঢিলে ব্র্যাকেট নয় — পোলের স্ট্র্যাপ বা ক্রস-আর্মের গোড়ার মতো মজবুত জায়গায় অ্যাঙ্কর করুন।',
    art: '$_dir/anchor.svg',
    lessonPoint: 1,
  );
  static const gripFirst = DoMistake(
    key: '2.4/pull/grip-before-anchor',
    textBn: 'ধাপ মেনে চলুন: আগে কাম-অ্যালং মজবুত অ্যাঙ্করে, তারপর তারে গ্রিপ, তারপর হুক গ্রিপের আই-বোল্টে — শেষে টান।',
    art: '$_dir/order.svg',
    lessonPoint: 1,
  );
  static const inLine = DoMistake(
    key: '2.4/pull/in-line-of-pull',
    textBn: 'টানের লাইনের সোজা সামনে বা পেছনে দাঁড়িয়েছিলেন। হুক খুললে বা গ্রিপ পিছলালে স্লিং-শট এফেক্ট সামনে যা থাকে তাকেই আঘাত করে। সবসময় পাশে দাঁড়ান।',
    art: '$_dir/line.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const pawlOpen = DoMistake(
    key: '2.4/pull/ratchet-not-locked',
    textBn: 'র‍্যাচেট লক হয়নি, তবু এগোলেন। প্রতিবার লিভার টানার পর দেখুন র‍্যাচেট ঠিকমতো লক হচ্ছে কি না।',
    art: '$_dir/pawl.svg',
    lessonPoint: 1,
  );
  static const overPull = DoMistake(
    key: '2.4/pull/over-tension',
    textBn: 'বেশি টানলেন — স্যাগ যত কমে, টেনশন তত বাড়ে। ঠিক স্যাগেই থামুন; যন্ত্রের লোড ক্ষমতার বাইরে কখনো নয়।',
    art: '$_dir/overpull.svg',
    lessonPoint: 0,
  );

  /// "টান ঠিক আছে" while it still sags (the mission: bring the sagging
  /// conductor to the right tension). No lesson point: "পাঠে দেখুন" opens the
  /// lesson from its start (the mission briefing).
  static const stoppedSlack = DoMistake(
    key: '2.4/pull/stopped-slack',
    textBn: 'তারটা এখনো পাশের তারগুলোর চেয়ে বেশি ঝুলে আছে, তবু থামলেন। পাশের দুটো তারের সাথে মিলিয়ে দেখুন — ঠিক স্যাগে এলে তবেই থামুন।',
    art: '$_dir/slack.svg',
  );

  /// Pro tip 4: the pro tips are not a lesson point, so "পাঠে দেখুন" opens
  /// the lesson from its start.
  static const pipe = DoMistake(
    key: '2.4/pull/pipe-on-handle',
    textBn: 'হ্যান্ডেলে পাইপ লাগিয়ে লিভারেজ বাড়ালে যন্ত্র তার ডিজাইন ক্ষমতার বাইরে যায় — ভেঙে যেতে পারে। হ্যান্ডেলেই ধীরে টানুন।',
    art: '$_dir/pipe.svg',
  );
  static const suddenRelease = DoMistake(
    key: '2.4/pull/sudden-release',
    textBn: 'হঠাৎ পুরো লোড ছেড়ে দিলেন। র‍্যাচেট সাবধানে রিলিজ পজিশনে এনে ধীরে ধীরে, নিয়ন্ত্রিতভাবে লোড কমান।',
    art: '$_dir/release.svg',
    lessonPoint: 2,
  );

  static const all = [weakAnchor, gripFirst, inLine, pawlOpen, overPull, stoppedSlack, pipe, suddenRelease];
}

/// One play: how many strokes bring the conductor to the right sag, on which
/// stroke the pawl fails to seat, after which stroke he comes, how many
/// notches let the load off, and the order of the two tools on his belt.
@immutable
class PullDeal {
  const PullDeal({required this.need, required this.lostAt, required this.callAt, required this.notches, this.gripLeft = false});
  final int need;

  /// The wire grip is on the left of the tool tray (the tray is never laid
  /// out in the lesson's order every play).
  final bool gripLeft;

  /// The tools left to right.
  List<PullTool> get tray => gripLeft ? const [PullTool.grip, PullTool.comeAlong] : const [PullTool.comeAlong, PullTool.grip];

  /// The stroke (counting every finished stroke, from 1) after which the pawl
  /// does not seat and the wheel runs back.
  final int lostAt;

  /// He comes once this many strokes hold (1 ≤ callAt < need).
  final int callAt;
  final int notches;
}

PullDeal dealPull(math.Random rng) {
  final need = 4 + rng.nextInt(3);
  final lostAt = 2 + rng.nextInt(need - 2);
  final callAt = 1 + rng.nextInt(need - 1);
  final notches = 3 + rng.nextInt(2);
  return PullDeal(need: need, lostAt: lostAt, callAt: callAt, notches: notches, gripLeft: rng.nextBool());
}

/// What "done" found.
enum PullCheck { slack, ok }

/// The play state (pure logic).
class PullRun {
  PullRun(this.deal);
  final PullDeal deal;

  PullStation station = PullStation.rig;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// Slips at the current station (a clean station pays +5).
  int stationSlips = 0;

  // rig
  PullAnchor? anchor;
  bool grip = false;
  bool hooked = false;

  // spot
  PullSpot? spot;

  // pull
  int strokes = 0;
  int finished = 0;
  bool pawlSeated = true;
  bool _lost = false;

  // release
  bool clamped = false;
  int notchesOff = 0;
  bool released = false;

  bool get ended => deadly != null || released;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => released && deadly == null && percent >= 55;
  bool get clean => stationSlips == 0;
  double get tension => strokes / deal.need;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  static bool strong(PullAnchor a) => a == PullAnchor.sling || a == PullAnchor.armBase;

  /// The come-along's fixed end on [a].
  DoMistake? placeComeAlong(PullAnchor a) {
    if (ended || station != PullStation.rig || anchor != null) return null;
    if (!strong(a)) return _slip(PullMistakes.weakAnchor);
    anchor = a;
    return null;
  }

  /// The grip on the conductor (only after the anchor).
  DoMistake? placeGrip() {
    if (ended || station != PullStation.rig || grip) return null;
    if (anchor == null) return _slip(PullMistakes.gripFirst);
    grip = true;
    return null;
  }

  /// The hook on the grip's eye-bolt; true = rigged.
  bool hook() {
    if (ended || station != PullStation.rig || anchor == null || !grip || hooked) return false;
    hooked = true;
    _tag(PullLines.caughtAnchor);
    return true;
  }

  /// Where he stands for the pull: in the line of pull is deadly.
  DoMistake? stand(PullSpot s) {
    if (ended || station != PullStation.spot || spot != null) return null;
    if (s != PullSpot.side) return deadly = PullMistakes.inLine;
    spot = s;
    _tag(PullLines.caughtSpot);
    return null;
  }

  /// A finished stroke of the handle. With the pawl lifted: a slip (the page
  /// seats it after the card). The [deal.lostAt]-th stroke does not hold: the
  /// pawl stays off the teeth and the wheel runs back. Past the right sag: a
  /// slip, and it is let back to the right sag.
  DoMistake? stroke() {
    if (ended || station != PullStation.pull) return null;
    if (!pawlSeated) return _slip(PullMistakes.pawlOpen);
    finished++;
    if (!_lost && finished == deal.lostAt) {
      _lost = true;
      pawlSeated = false;
      return null;
    }
    strokes++;
    if (strokes > deal.need) {
      strokes = deal.need;
      return _slip(PullMistakes.overPull);
    }
    return null;
  }

  /// The stroke that did not hold (the pawl is off the teeth).
  bool get slipping => !pawlSeated;

  /// Seat the pawl in the teeth (he looked at the ratchet).
  void seatPawl({bool byHand = true}) {
    if (pawlSeated) return;
    pawlSeated = true;
    if (byHand) _tag(PullLines.caughtPawl);
  }

  /// "টান ঠিক আছে": the pawl must be seated; still sagging = a slip (a stop
  /// before the right sag is a wrong call, never a free look).
  (PullCheck?, DoMistake?) check() {
    if (ended || station != PullStation.pull) return (null, null);
    if (!pawlSeated) return (null, _slip(PullMistakes.pawlOpen));
    if (strokes < deal.need) return (PullCheck.slack, _slip(PullMistakes.stoppedSlack));
    _tag(PullLines.caughtSag);
    return (PullCheck.ok, null);
  }

  /// Listened to him: the pipe on the handle.
  DoMistake listenPipe() => _slip(PullMistakes.pipe);

  /// One notch of the load let off; true = all off.
  bool releaseNotch() {
    if (ended || station != PullStation.release) return false;
    notchesOff++;
    if (notchesOff >= deal.notches) {
      released = true;
      _tag(PullLines.caughtRelease);
      return true;
    }
    return false;
  }

  /// The whole load at once: a slip (the load stays on).
  DoMistake? releaseAtOnce() {
    if (ended || station != PullStation.release) return null;
    return _slip(PullMistakes.suddenRelease);
  }

  /// On to the next station.
  void next() {
    stationSlips = 0;
    switch (station) {
      case PullStation.rig:
        station = PullStation.spot;
      case PullStation.spot:
        station = PullStation.pull;
      case PullStation.pull:
        station = PullStation.release;
        clamped = true;
      case PullStation.release:
        break;
    }
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
///   rig: two tools, three taps ~7000 + reason ~8200                 15200
///   spot: one tap ~2500 + reason ~8200                              10700
///   pull: ~5 strokes × (900 hold + 1500) + the pawl 2500 + done 1500
///     + reason ~8200                                                24200
///   the coworker: his line ~3500 + deck 910 + pick 3500             7900
///   release: ~3.5 notches × (700 + 1500) + reason ~8200             15900
///   ≈ 73900 ms; 85 % ≈ 62800 → 65 s.
const kPullQuickMs = 65000;

@immutable
class M2ComealongPullPack {
  const M2ComealongPullPack({required this.id, required this.titleBn, this.quickMs = kPullQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2ComealongPullPacks = {
  'do_2_4_b': M2ComealongPullPack(id: 'do_2_4_b', titleBn: PullLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M2ComealongPullPage extends StatefulWidget {
  const M2ComealongPullPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M2ComealongPullPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2ComealongPullPage> createState() => _M2ComealongPullPageState();
}

class _M2ComealongPullPageState extends State<M2ComealongPullPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PullRunPage(
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

class _PullRunPage extends ConsumerStatefulWidget {
  const _PullRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2ComealongPullPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PullRunPage> createState() => _PullRunPageState();
}

class _PullRunPageState extends ConsumerState<_PullRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final PullRun _run = PullRun(dealPull(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The handle's stroke (pull) or one notch let off (release), 0 → 1 while held.
  late final AnimationController _stroke = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _strokeDone();
    });

  /// The trainee moving to his spot.
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Listenable _sceneMotion = Listenable.merge([_stroke, _move]);

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
  PullTool? _tool;
  var _holding = false;
  var _stamp = false;
  var _coworkerArmed = false;

  /// This station's right move is in (the ◆ is on the table or paid): the
  /// station takes no more moves until the next one starts.
  var _won = false;
  final List<(int, Offset)> _taps = [];
  int _tapN = 0;

  /// Where he stood before moving to his spot, and where he goes.
  final PullSpot _from = PullSpot.front;
  PullSpot _to = PullSpot.front;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final Map<PullTool, GlobalKey> _toolKeys = {for (final t in PullTool.values) t: GlobalKey()};
  final _pawlKey = GlobalKey();
  final _handleKey = GlobalKey();
  final _otherKey = GlobalKey();
  PullGeo? _geoNow;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _stroke.dispose();
    _move.dispose();
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

  String get _task => PullLines.ask(_run.station, rigged: _run.anchor != null && _run.grip);

  void _start() {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  bool get _canPlay =>
      !_intro && !_busy && !_ended && !_won && _card == null && !tableBusy && !coworkerOpen && !struckOut && !_move.isAnimating;

  // --- rig and spot: taps on the scene ---------------------------------------------
  void _pickTool(PullTool t) {
    if (!_canPlay || _run.station != PullStation.rig) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.wav', volume: 0.45);
    setState(() => _tool = _tool == t ? null : t);
  }

  void _tapScene(Offset p, PullGeo geo, Offset global) {
    if (!_canPlay) return;
    switch (_run.station) {
      case PullStation.rig:
        _tapRig(p, geo, global);
      case PullStation.spot:
        // One stand a play: once he is at a spot, more taps do not move him.
        if (_run.spot != null) return;
        for (final s in PullSpot.values) {
          if (geo.spotRect(s).contains(p)) {
            unawaited(_stand(s, global));
            return;
          }
        }
        _plainTap(p);
      case PullStation.pull:
      case PullStation.release:
        _plainTap(p);
    }
  }

  void _plainTap(Offset p) {
    _hints.missTap();
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    setState(() {
      _taps.add((_tapN++, p));
      if (_taps.length > 4) _taps.removeAt(0);
    });
  }

  void _tapRig(Offset p, PullGeo geo, Offset global) {
    final r = _run;
    if (r.anchor != null && r.grip && !r.hooked && geo.hookRect(r.anchor!).contains(p)) {
      r.hook();
      _cue('sounds/intro/click.ogg', volume: 0.7);
      HapticFeedback.mediumImpact();
      setState(() => _wake++);
      _stationRight(global);
      return;
    }
    if (_tool == PullTool.comeAlong && r.anchor == null) {
      for (final a in PullAnchor.values) {
        if (geo.anchorRect(a).contains(p)) {
          final m = r.placeComeAlong(a);
          if (m != null) {
            unawaited(_slipOut(m, global));
            return;
          }
          _placed();
          return;
        }
      }
    }
    if (_tool == PullTool.grip && !r.grip && geo.gripRect.contains(p)) {
      final m = r.placeGrip();
      if (m != null) {
        unawaited(_slipOut(m, global));
        return;
      }
      _placed();
      return;
    }
    _plainTap(p);
  }

  void _placed() {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.6);
    setState(() {
      _tool = null;
      _wake++;
    });
    if (_run.anchor != null && _run.grip) unawaited(_sayChain([PullLines.askHook]));
  }

  Future<void> _stand(PullSpot s, Offset global) async {
    final m = _run.stand(s);
    if (m == null && _run.spot != s) return;
    HapticFeedback.selectionClick();
    setState(() {
      _to = s;
      _wake++;
    });
    if (_quiet) {
      _move.value = 1;
    } else {
      await _move.forward(from: 0);
    }
    if (!mounted) return;
    if (m != null) {
      await _deadly(m);
      return;
    }
    _stationRight(global);
  }

  // --- pull and release: the handle ---------------------------------------------------
  void _holdStart() {
    if (!_canPlay || _holding) return;
    if (_run.station != PullStation.pull && _run.station != PullStation.release) return;
    if (_run.station == PullStation.pull && !_run.pawlSeated) {
      // A stroke with the pawl off the teeth.
      unawaited(_slipOut(_run.stroke()!, _handleCentre()));
      return;
    }
    // The next stroke waits for the coworker (he can't be skipped by pulling fast).
    if (_run.station == PullStation.pull && holdForCoworker()) return;
    _holding = true;
    HapticFeedback.selectionClick();
    _stroke.duration = Duration(milliseconds: _run.station == PullStation.pull ? 900 : 700);
    unawaited(_stroke.forward(from: _stroke.value));
  }

  void _holdEnd() {
    if (!_holding) return;
    _holding = false;
    if (_stroke.isAnimating && _stroke.value < 1) unawaited(_stroke.reverse());
  }

  Offset _handleCentre() {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width * 0.25, size.height * 0.8);
  }

  void _strokeDone() {
    if (!mounted || _ended) return;
    _holding = false;
    final origin = _handleCentre();
    if (_run.station == PullStation.release) {
      _stroke.value = 0;
      final all = _run.releaseNotch();
      _cue('sounds/intro/tick.ogg', volume: 0.6);
      HapticFeedback.lightImpact();
      setState(() => _wake++);
      if (all) {
        _cue('sounds/intro/drop.ogg', volume: 0.5);
        _stationRight(origin);
      }
      return;
    }
    final before = _run.strokes;
    final m = _run.stroke();
    _stroke.value = 0;
    if (m != null) {
      unawaited(_slipOut(m, origin));
      return;
    }
    if (_run.strokes == before) {
      // The pawl did not seat: the wheel runs back.
      HapticFeedback.heavyImpact();
      _cue('sounds/intro/drop.ogg', volume: 0.6);
    } else {
      HapticFeedback.lightImpact();
      _cue('sounds/intro/click.ogg', volume: 0.8);
    }
    setState(() => _wake++);
    _armCoworker();
  }

  /// He is dealt to come once this many strokes hold (and the pawl is seated).
  void _armCoworker() {
    if (_coworkerArmed || _run.station != PullStation.pull || !_run.pawlSeated) return;
    if (_run.strokes < _run.deal.callAt || _run.strokes >= _run.deal.need) return;
    _coworkerArmed = true;
    scheduleCoworker();
  }

  void _tapPawl() {
    if (!_canPlay || _run.station != PullStation.pull) return;
    HapticFeedback.selectionClick();
    if (_run.slipping) {
      _run.seatPawl();
      _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    } else {
      _cue('sounds/intro/tick.ogg', volume: 0.4);
    }
    setState(() => _wake++);
    _armCoworker();
  }

  Future<void> _checkDone(Offset origin) async {
    if (!_canPlay || _run.station != PullStation.pull || _holding) return;
    if (holdForCoworker()) return;
    final (res, m) = _run.check();
    if (m != null) {
      await _slipOut(m, origin);
      return;
    }
    if (res != PullCheck.ok) return;
    _hush();
    setState(() => _stamp = true);
    _stationRight(origin);
  }

  Future<void> _releaseAtOnce(Offset origin) async {
    if (!_canPlay || _run.station != PullStation.release || _holding) return;
    final m = _run.releaseAtOnce();
    if (m != null) await _slipOut(m, origin);
  }

  // --- a station done right: the ◆ and the reason ---------------------------------
  void _stationRight(Offset origin) {
    if (_won) return;
    _won = true;
    _hush();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    final station = _run.station;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(PullLines.whyRight(station), PullLines.excuses, widget.rng),
      question: PullLines.why(station),
      stillValid: () => _run.station == station && !_ended,
    ));
  }

  void _nextStation() {
    if (_run.station == PullStation.release) {
      unawaited(_finish());
      return;
    }
    _run.next();
    setState(() {
      _won = false;
      _stamp = false;
      _taps.clear();
      _wake++;
    });
    if (_run.station == PullStation.release) _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    unawaited(_sayChain([_task]));
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
  CoworkerScript get coworkerScript => PullLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.station.index > PullStation.pull.index) return null;
    if (_run.station != PullStation.pull) return false;
    // "A pipe, one big pull and it's done" fits only while it still sags.
    if (_won || _run.strokes >= _run.deal.need) return null;
    if (_intro || _busy || _holding || _card != null || tableBusy || !_run.pawlSeated) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      await _slipOut(_run.listenPipe(), origin);
      return;
    }
    _run.caught.add(PullLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (mounted && !_ended) unawaited(_sayChain([PullLines.askPull]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? PullLines.tapWhy[_nudgeN++ % PullLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _slipOut(DoMistake m, Offset origin) async {
    setState(() => _tool = null);
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
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('pull/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// In the line of pull: the pole top freezes grey, the grip lets go and
  /// the come-along whips along the line to him in colour; then near-miss or
  /// death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
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
    final speak = await SpokenOnce.first('pull/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? PullLines.deadlyWord : PullLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        // A stroke with the pawl off: it is seated now (he has seen it).
        if (_card == PullMistakes.pawlOpen) _run.seatPawl(byHand: false);
        setState(() {
          _card = null;
          _wake++;
        });
        unawaited(_sayChain([_task]));
        _armCoworker();
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
    if (_ended && !_run.released) return;
    if (_mark != null) return;
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
    await _say(!_run.passed ? PullLines.fail : (_quickBonus ? PullLines.quick : PullLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_mark != null && _passed) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  Rect _traineeBox(PullGeo geo) =>
      Rect.lerp(geo.spotBox(_from), geo.spotBox(_to), Curves.easeInOut.transform(_move.value))!;

  PullRig get _rigState {
    final r = _run;
    final release = r.station == PullStation.release;
    final live = r.station == PullStation.pull && _holding && r.pawlSeated ? _stroke.value / r.deal.need : 0.0;
    return PullRig(
      anchor: r.anchor,
      grip: r.grip,
      hooked: r.hooked,
      tension: (r.tension + live).clamp(0.0, 1.3),
      clamped: r.clamped,
      slackOut: release ? ((r.notchesOff + (_holding ? _stroke.value : 0)) / r.deal.notches).clamp(0.0, 1.0) : 0,
      removed: r.released,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = PullGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = _traineeBox(geo);
    final behind = tb.left > PullGeo.px;
    final spotting = _run.station == PullStation.spot && _run.spot == null && !_freeze && !_move.isAnimating && !reasonOpen && _card == null;
    // Everything is seen through the close-up camera (taps land in design px).
    return [
      Positioned.fill(
        key: const ValueKey('camera'),
        child: Transform(
          transform: geo.camera,
          child: Stack(children: _sceneLayers(geo, quiet, grey, tb, behind, spotting)),
        ),
      ),
    ];
  }

  List<Widget> _sceneLayers(PullGeo geo, bool quiet, ColorFilter grey, Rect tb, bool behind, bool spotting) {
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(child: CustomPaint(painter: PullWorldPainter(geo: geo, rig: _rigState))),
              ),
              Positioned.fill(
                key: const ValueKey('strap'),
                child: IgnorePointer(child: CustomPaint(painter: PullStrapPainter(box: tb, flip: behind))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: Transform.flip(
                  flipX: behind,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ),
            ],
          ),
        ),
      ),
      if (!_freeze)
        for (final (id, p) in _taps)
          Positioned(
            key: ValueKey('tap-$id'),
            left: p.dx - 14,
            top: p.dy - 14,
            width: 28,
            height: 28,
            child: IgnorePointer(child: _Ring(quiet: quiet)),
          ),
      // Where he could stand: three plain rings, the same for each.
      if (spotting)
        for (final s in PullSpot.values)
          Positioned.fromRect(
            key: ValueKey('spot-${s.name}'),
            rect: geo.spotRect(s),
            child: IgnorePointer(child: _Ring(quiet: quiet, big: true)),
          ),
      if (_stamp && !_freeze)
        Positioned(
          key: const ValueKey('stamp'),
          left: PullGeo.px - 150,
          top: geo.lineY + 56,
          child: IgnorePointer(child: _StampPop(text: PullLines.stampDone, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: PullLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('sling'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 900),
              builder: (_, v, _) => CustomPaint(painter: PullSlingPainter(geo: geo, at: geo.spotRect(_to).center, v: v)),
            ),
          ),
        ),
    ];
  }

  // --- the gesture hint (how to touch, never what) ------------------------------
  /// A design-px rect on the pole as it shows through the close-up camera.
  static Rect _view(PullGeo geo, Rect r) => Rect.fromPoints(geo.view(r.topLeft), geo.view(r.bottomRight));

  /// Left to right on the scene (never the enum's order, which starts with
  /// the right answers).
  static List<Rect> _leftToRight(Iterable<Rect> rects) => [...rects]..sort((a, b) => a.center.dx.compareTo(b.center.dx));

  HintSpec? _hint() {
    final r = _run;
    final geo = _geoNow;
    switch (r.station) {
      case PullStation.rig:
        if (geo == null) return null;
        // The hook is the one way forward once the anchor and the grip are on.
        if (r.anchor != null && r.grip) return HintSpec.tap(geo.view(geo.hookRect(r.anchor!).center), space: HintSpace.scene);
        // A tool in hand: every place on the pole it could go, the same for either tool.
        if (_tool != null) {
          return HintSpec.sweep(
            _leftToRight([for (final a in PullAnchor.values) _view(geo, geo.anchorRect(a)), _view(geo, geo.gripRect)]),
            space: HintSpace.scene,
          );
        }
        final open = [
          for (final t in r.deal.tray)
            if (!(t == PullTool.comeAlong ? r.anchor != null : r.grip)) _toolKeys[t]!,
        ];
        // One tool left (the anchor is on): tap it; both open: sweep over both.
        return open.length == 1 ? HintSpec.tapOn(open.single) : HintSpec.sweepOver(open);
      case PullStation.spot:
        if (geo == null) return null;
        return HintSpec.sweep(_leftToRight([for (final s in PullSpot.values) _view(geo, geo.spotRect(s))]), space: HintSpace.scene);
      case PullStation.pull:
        return HintSpec.sweepOver([_pawlKey, _handleKey, _otherKey]);
      case PullStation.release:
        return HintSpec.sweepOver([_handleKey, _otherKey]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended;
    final st = _run.station;
    final rigTray = handsOn && st == PullStation.rig && !(_run.anchor != null && _run.grip);
    final handle = handsOn && (st == PullStation.pull || st == PullStation.release) && !_stamp && !(st == PullStation.release && _run.released);
    final hintWaiting = handsOn && _canPlay && !_holding;
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
              labels: PullLines.rounds,
              done: {for (var i = 0; i < st.index; i++) i, if (_run.released) 3},
              current: _run.released ? null : st.index,
              quiet: quiet,
            ),
            animation: _sceneMotion,
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintWaiting,
            hintKey: '${st.name}|${_run.anchor != null}|${_run.grip}|${_tool?.name}',
            hintController: _hints,
            overlays: [
              if (playing && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: const IgnorePointer(child: _DocketChip()),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (rigTray)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  left: 10,
                  bottom: pad.bottom + 14,
                  child: Row(
                    children: [
                      // Dealt order (never the lesson's order every play).
                      for (final (i, t) in _run.deal.tray.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _ToolChip(
                          key: _toolKeys[t],
                          label: t == PullTool.comeAlong ? PullLines.comeAlong : PullLines.grip,
                          icon: t == PullTool.comeAlong ? Icons.settings_rounded : Icons.back_hand_rounded,
                          selected: _tool == t,
                          used: t == PullTool.comeAlong ? _run.anchor != null : _run.grip,
                          onTap: () => _pickTool(t),
                        ),
                      ],
                    ],
                  ),
                ),
              if (handle) ...[
                Positioned(
                  key: const ValueKey('hud-ratchet'),
                  left: 10,
                  bottom: pad.bottom + 76,
                  width: 168,
                  height: 116,
                  child: _RatchetPanel(
                    handle: _stroke,
                    pawlSeated: _run.pawlSeated,
                    turn: (st == PullStation.pull ? _run.finished : -_run.notchesOff).toDouble(),
                    release: st == PullStation.release,
                    onPawl: _tapPawl,
                    pawlKey: _pawlKey,
                  ),
                ),
                Positioned(
                  key: ValueKey('hud-handle-${st.name}'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _HoldButton(
                          key: _handleKey,
                          label: st == PullStation.pull ? PullLines.pull : PullLines.slowRelease,
                          progress: _stroke,
                          onDown: _holdStart,
                          onUp: _holdEnd,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: DoBigButton(
                          key: _otherKey,
                          label: st == PullStation.pull ? PullLines.done : PullLines.fastRelease,
                          filled: false,
                          onDark: true,
                          onTapUp: (d) => unawaited(st == PullStation.pull ? _checkDone(d.globalPosition) : _releaseAtOnce(d.globalPosition)),
                        ),
                      ),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (handle ? 198 : 72)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${st.name}'),
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
                  line: PullLines.intro,
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

/// The docket: the job and that the line is dead (words a worker reads).
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
          Text(PullLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(PullLines.job, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          Text(PullLines.permit, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E6B3A))),
        ],
      ),
    );
  }
}

/// A tool from his belt: tap to take it, then tap where it goes.
class _ToolChip extends StatelessWidget {
  const _ToolChip({super.key, required this.label, required this.icon, required this.selected, required this.used, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = used ? SlmColors.success : (selected ? SlmColors.gold300 : const Color(0x99FFFFFF));
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: used ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 52, minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xF21C2E4A) : const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ring, width: selected ? 2.4 : 1.4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(used ? Icons.check_circle_rounded : icon, size: 22, color: ring),
              const SizedBox(width: 6),
              Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The come-along close up: the ratchet, its pawl (tap it), the handle.
class _RatchetPanel extends StatelessWidget {
  const _RatchetPanel({required this.handle, required this.pawlSeated, required this.turn, required this.release, required this.onPawl, this.pawlKey});
  final Animation<double> handle;
  final Key? pawlKey;
  final bool pawlSeated;
  final double turn;
  final bool release;
  final VoidCallback onPawl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE60B1324),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x55FFFFFF), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(builder: (context, box) {
        final s = Size(box.maxWidth, box.maxHeight);
        final area = RatchetPainter.pawlArea(s);
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: RatchetPainter(handle: handle, pawlSeated: pawlSeated, turn: turn, release: release)),
              ),
            ),
            Positioned.fromRect(
              rect: area.inflate(4),
              child: Semantics(
                key: pawlKey,
                button: true,
                label: PullLines.ratchet,
                excludeSemantics: true,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onPawl),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Hold to work the handle: it fills while held (one stroke / one notch).
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.label, required this.progress, required this.onDown, required this.onUp});
  final String label;
  final Animation<double> progress;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: SlmColors.gold700),
                AnimatedBuilder(
                  animation: progress,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.value.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0x55FFFFFF)),
                  ),
                ),
                Center(child: Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain white ring (a tap, or a place he could stand).
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
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
