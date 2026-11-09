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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';
import 'storm_push_world.dart';

// Lesson 1.9, কাজ 2: "সুপারভাইজারের চাপ". A crew's job is half done on a village
// roadside and the weather turns. Three situations a play, each a fresh docket
// and a fresh sky: light drizzle with no wind or lightning (a routine job — or
// an emergency fault), rain with a gale (trees bent, wires galloping), or a
// thunderstorm (flashes). Once a play the supervisor (level 1's rival art,
// puppet and recorded voice) peeps in with the lesson's myth — "হালকা বৃষ্টি,
// শেষ করো!" — and the guide puts the choice on a 3-card deck.
// Hands on: drag up the ladder to climb, or lay the ladder down to stop (say
// no); take the waterproof gloves off a hook on the van; in a thunderstorm,
// touch where the crew shelters (the van, the lone tree, the pole's foot).
// What the lesson says (1.9 point 1–3): routine maintenance stops in rain;
// only an emergency fault repair goes on, with the utmost care and waterproof
// gloves; lightning seen or heard = stop work at height and go to a safe
// shelter (no PPE helps; a direct strike on a pole or in the open is deadly);
// a strong wind = stop work at height (balance, galloping wires).
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// drawn scene, corner guide, ◆ on the table → "কেন …?" (reasons that fit the
// sky and the docket) → the next situation by itself.
//
// Deadly (owner-approved list): climbing in a storm under pressure — up the
// ladder in a gale or a thunderstorm (also by listening to him). Slips: a
// routine job in drizzle; an emergency climb without the waterproof gloves;
// a shelter under the lone tree or at the pole's foot. Laying the ladder down
// on the emergency fault in plain drizzle costs nothing ("Stop Work আপনার
// অধিকার"): the guide says the lesson allows it; a second "না" moves on, no ◆.
//
// Voice: the guide's lines by device TTS; the supervisor in the rival's
// recorded voice. Art: drawn in code (storm_push_world.dart); mistake
// pictures in assets/game/art/storm_board/push_*.svg.

// ============================================================================
// Content
// ============================================================================

/// What the sky is doing.
enum StormCue { drizzle, wind, thunder }

/// The docket's job.
enum StormJob { routine, emergency }

/// Where the crew can go in a thunderstorm.
enum StormPlace { van, tree, pole }

@immutable
class StormCase {
  const StormCase({required this.cue, required this.job});
  final StormCue cue;
  final StormJob job;

  /// The lesson lets only this go on: an emergency fault in plain drizzle
  /// (no wind, no lightning), with the waterproof gloves.
  bool get mayGoOn => cue == StormCue.drizzle && job == StormJob.emergency;

  /// Up the ladder here is deadly (a storm).
  bool get stormy => cue != StormCue.drizzle;

  bool get needsShelter => cue == StormCue.thunder;

  StormWeather get weather => switch (cue) {
        StormCue.drizzle => StormWeather.drizzle,
        StormCue.wind => StormWeather.gale,
        StormCue.thunder => StormWeather.thunder,
      };

  @override
  bool operator ==(Object other) => other is StormCase && other.cue == cue && other.job == job;

  @override
  int get hashCode => Object.hash(cue, job);
}

@immutable
class StormDeal {
  const StormDeal({required this.cases, required this.callRound});
  final List<StormCase> cases;

  /// The situation the supervisor pushes in (never the one that may go on).
  final int callRound;
}

/// Three situations: always a thunderstorm; a gale or a routine job in
/// drizzle; and one more of drizzle-routine, drizzle-emergency or gale
/// (different from the second). The supervisor comes in one of the unsafe ones.
StormDeal dealStorm(math.Random rng) {
  StormJob anyJob() => rng.nextBool() ? StormJob.routine : StormJob.emergency;
  const drizzleRoutine = StormCase(cue: StormCue.drizzle, job: StormJob.routine);
  const drizzleEmergency = StormCase(cue: StormCue.drizzle, job: StormJob.emergency);
  final second = rng.nextBool() ? drizzleRoutine : StormCase(cue: StormCue.wind, job: anyJob());
  final thirdPool = <StormCase>[
    drizzleRoutine,
    drizzleEmergency,
    StormCase(cue: StormCue.wind, job: anyJob()),
  ].where((c) => c.cue != second.cue || c.job != second.job).where((c) => !(c.cue == StormCue.wind && second.cue == StormCue.wind)).toList();
  final third = thirdPool[rng.nextInt(thirdPool.length)];
  final cases = [StormCase(cue: StormCue.thunder, job: anyJob()), second, third]..shuffle(rng);
  final unsafe = [
    for (var i = 0; i < cases.length; i++)
      if (!cases[i].mayGoOn) i,
  ];
  return StormDeal(cases: cases, callRound: unsafe[rng.nextInt(unsafe.length)]);
}

/// What laying the ladder down did.
enum StormStop {
  /// Not now (not the hands' turn).
  ignored,

  /// The right call: ◆, then why.
  right,

  /// The emergency in plain drizzle: the lesson allows it (no cost, stays).
  mayGoOn,

  /// "না" again to it: the worker's right; on, with no ◆ and no cost.
  declined,
}

enum StormPhase {
  /// Climb, or lay the ladder down.
  judge,

  /// Stopped in a thunderstorm: where to shelter (after the reason).
  shelter,

  /// The situation is answered (the reason, or the slip card, then the next).
  shown,
}

abstract final class StormLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askJudge, askShelter];

  static const title = 'সুপারভাইজারের চাপ';
  static const intro = 'কাজের মাঝেই কালবৈশাখীর মেঘ ডাকছে! সুপারভাইজার তাড়াহুড়ো করে শেষ করার হুকুম দিলেও—জীবনের চেয়ে কোনো কাজ বড় নয়। মাথা ঠান্ডা রেখে "না" বলুন, নিরাপদ আশ্রয়ে যান।';
  static const askJudge = 'উঠবেন? মই বেয়ে ওপরে টানুন। থামবেন? মই নামিয়ে দিন।';
  static const askShelter = 'কোথায় আশ্রয় নেবেন? জায়গাটা ছুঁয়ে দিন।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker would read, and the scene's touch places (screen readers).
  static const docket = 'ডকেট';
  static String job(StormJob j) => j == StormJob.routine ? 'রুটিন মেরামত' : 'জরুরি ফল্ট মেরামত';
  static const ladderLabel = 'মই';
  static const glovesLabel = 'গ্লাভস';
  static String placeLabel(StormPlace p) => switch (p) {
        StormPlace.van => 'গাড়ি',
        StormPlace.tree => 'গাছ',
        StormPlace.pole => 'পোল',
      };

  static const glovesOn = 'ওয়াটারপ্রুফ গ্লাভস পরা হলো।';

  // --- the reasons (lesson 1.9): one right, two wrong, all about the same length.
  static const whyDrizzle = 'কেন কাজ থামালেন?';
  static const whyWind = 'কেন উঠলেন না?';
  static const whyThunder = 'কেন কাজ বন্ধ করলেন?';
  static const whyGo = 'কেন উঠলেন?';
  static const whyShelter = 'কেন পোল ছেড়ে গাড়িতে গেলেন?';

  // No shape gives the answer away: rule statements and "…, তাই …" reasons
  // are on both sides; the wrong ones are comfort, convenience or a myth.
  static const drizzleRight = [
    'বৃষ্টিতে সাধারণ মেরামত বন্ধ রাখতে হয়',
    'ভেজা পোল আর মই পিছল, তাই থামলাম',
    'ভেজা পিপিই আর বাতাসে আর্ক ফ্ল্যাশের ভয়',
  ];
  static const windRight = [
    'প্রবল বাতাসে পোলে ভারসাম্য থাকে না',
    'তার দুলে নিরাপদ দূরত্ব কমে, তাই উঠিনি',
    'এমন বাতাসে উঁচুতে কাজ বন্ধ রাখতে হয়',
  ];
  static const thunderRight = [
    'বজ্র দেখলে বা শুনলেই উঁচুতে কাজ বন্ধ',
    'কোনো পিপিই বজ্র আটকায় না, তাই থামলাম',
    'বজ্র পোলে বা খোলা জায়গায় মারাত্মক',
  ];
  static const stopWrong = [
    'ভিজলে ঠান্ডা লাগবে, জ্বর আসতে পারে',
    'আজ লোক কম, কাল সবাই মিলে করে নেব',
    'চায়ের সময় হয়ে গেছে, একটু জিরোই',
    'সুপারভাইজার আজ সাইটেই আসেননি যে',
    'মই ভিজলে রং উঠে যাবে, তাই থামলাম',
    'বৃষ্টি এলে কাজে আমার মনই বসে না',
  ];
  static const goRight = [
    'বৃষ্টিতে কেবল জরুরি ফল্টের কাজ চলে',
    'জরুরি কাজে ওয়াটারপ্রুফ গ্লাভস, সাবধানে',
    'বাতাস নেই, বজ্র নেই — ডকেট জরুরি ফল্টের',
  ];
  static const goWrong = [
    'বৃষ্টিতে সব কাজই গ্লাভসে চালানো যায়',
    'গ্লাভস পরে সাবধানে, বজ্রেও কাজ চলে',
    'সাবধানে উঠলে ঝড়ো হাওয়াতেও কাজ চলে',
    'সুপারভাইজার বলেছেন, তাই উঠে গেলাম',
    'ভেজা পোল বা মইয়ে পিছলানোর ভয় নেই',
  ];
  // Lesson 1.9: a direct strike on a pole or in the open is deadly; a strike
  // nearby shocks through the ground; plan the shelter on arrival (pro tip 4).
  static const shelterRight = [
    'পোল আর খোলা জায়গায় বজ্র মারাত্মক',
    'পোলের কাছে মাটি দিয়েও শক আসতে পারে',
    'আশ্রয় আগেই ঠিক ছিল — আমাদের গাড়ি',
  ];
  static const shelterWrong = [
    'গাড়িতে বসে একটু জিরিয়ে নেওয়া যায়',
    'ভিজে গেলে জামাকাপড় নষ্ট হয়ে যাবে',
    'সুপারভাইজারের সঙ্গে গল্প করা যাবে',
    'বজ্র শুধু গাছেই পড়ে, পোলে পড়ে না',
    'রাবারের জুতো থাকলে বজ্রে কিছু হয় না',
  ];

  static List<String> whyRight(StormCase c) => c.mayGoOn
      ? goRight
      : switch (c.cue) {
          StormCue.drizzle => drizzleRight,
          StormCue.wind => windRight,
          StormCue.thunder => thunderRight,
        };
  static List<String> whyWrong(StormCase c) => c.mayGoOn ? goWrong : stopWrong;
  static String whyAsk(StormCase c) => c.mayGoOn
      ? whyGo
      : switch (c.cue) {
          StormCue.drizzle => whyDrizzle,
          StormCue.wind => whyWind,
          StormCue.thunder => whyThunder,
        };

  // --- the supervisor (the rival's recorded voice) --------------------------
  static const pushDrizzle = 'হালকা বৃষ্টি, শেষ করো!';
  static const pushWind = 'হালকা বৃষ্টি, একটু হাওয়া — শেষ করো!';
  static const pushThunder = 'হালকা বৃষ্টি, শেষ করো! রাবারের জুতো-গ্লাভস তো পরাই আছে।';
  static const pushExit = 'হুঁ! যা খুশি করুন।';
  static const pushLines = [pushDrizzle, pushWind, pushThunder];
  static const supervisorTag = 'সুপারভাইজার';

  // "না" opens cards on both sides, so it is no tell.
  static const refuseAny = [
    'জীবন কাজের চেয়ে বড়, আমি থামছি',
    'না — অনিরাপদে না বলা আমার দায়িত্ব',
  ];
  static const refuseDrizzle = 'না — বৃষ্টিতে সাধারণ মেরামত বন্ধ';
  static const refuseWind = 'এই ঝড়ো হাওয়ায় উঁচুতে কাজ নয়';
  static const refuseThunder = 'বজ্র শুনেছি — উঁচুতে কাজ বন্ধ, নামছি';
  static const listen = [
    'ঠিক আছে, তাড়াতাড়ি উঠে শেষ করি',
    'আপনি যখন বলছেন, তখন উঠে পড়ছি',
    'হালকা বৃষ্টি তো, শেষ করেই নামি',
    'চাপ যখন, কাজটা শেষ করতেই হবে',
    'রাবারের জুতো পরা আছে, উঠেই যাই',
    'না না, কিছু হবে না — উঠে শেষ করি',
  ];
  static const asks = [
    'সুপারভাইজার বলছেন শেষ করতে। আপনি কী করবেন?',
    'ওঁর চাপ মানবেন, না পাঠের নিয়ম?',
    'চাপ এসেছে। ওঁকে কী বলবেন?',
  ];

  static CoworkerScript coworker(StormCue cue) => CoworkerScript(
        line: switch (cue) {
          StormCue.drizzle => pushDrizzle,
          StormCue.wind => pushWind,
          StormCue.thunder => pushThunder,
        },
        exitLine: pushExit,
        right: [
          switch (cue) {
            StormCue.drizzle => refuseDrizzle,
            StormCue.wind => refuseWind,
            StormCue.thunder => refuseThunder,
          },
          ...refuseAny,
        ],
        wrong: listen,
        asks: asks,
        tag: supervisorTag,
      );

  /// The go-on case (an emergency fault in plain drizzle) laid down: no cost.
  /// The first time the guide says what the lesson allows; a second "না" is
  /// the worker's right (pro tips 2–3) and the situation moves on, no ◆.
  static const mayGoOn = 'শুধু হালকা বৃষ্টি, বাতাস-বজ্র নেই, ডকেট জরুরি ফল্টের — পাঠ বলে, ওয়াটারপ্রুফ গ্লাভস পরে সর্বোচ্চ সতর্ক হয়ে এটা সারা যায়।';
  static const mayGoOnStill = 'তবু মন না চাইলে আবার মই নামান — থামা আপনার অধিকার।';
  static const declined = 'ঠিক আছে — নিরাপদ মনে না হলে থামাই দায়িত্ব।';

  static const callHeld = 'ঠিক! কোনো কাজ জীবনের চেয়ে বড় নয়।';
  static const allSet = 'চাপ এলেও আকাশ দেখে ঠিক সিদ্ধান্ত!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — জীবন কাজের চেয়ে বড়।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtDrizzle = 'হালকা বৃষ্টিতে সাধারণ কাজ থামিয়েছেন';
  static const caughtWind = 'ঝড়ো হাওয়ায় উঁচুতে ওঠেননি';
  static const caughtThunder = 'বজ্রে কাজ বন্ধ করেছেন';
  static const caughtShelter = 'পোল ছেড়ে আগে ঠিক করা আশ্রয়ে';
  static const caughtEmergency = 'জরুরি ফল্টে ওয়াটারপ্রুফ গ্লাভস';
  static const caughtCall = 'সুপারভাইজারের চাপে “না” বলেছেন';
}

abstract final class StormMistakes {
  static const routineInRain = DoMistake(
    key: '1.9/push/routine-in-rain',
    textBn: 'হালকা বৃষ্টিতেও সাধারণ মেরামত বন্ধ — ভেজা পোল-মই পিছল, আর্কের ভয়। বৃষ্টিতে শুধু জরুরি ফল্ট, সর্বোচ্চ সতর্ক হয়ে।',
    art: 'assets/game/art/storm_board/push_rain_routine.svg',
    lessonPoint: 0,
  );
  static const noGloves = DoMistake(
    key: '1.9/push/no-waterproof-gloves',
    textBn: 'বৃষ্টিতে জরুরি ফল্ট সারতে হলে আগে ওয়াটারপ্রুফ গ্লাভস, তারপর সর্বোচ্চ সতর্ক হয়ে কাজ।',
    art: 'assets/game/art/storm_board/push_waterproof_gloves.svg',
    lessonPoint: 0,
  );
  static const galeClimb = DoMistake(
    key: '1.9/push/climb-in-gale',
    textBn: 'ঝড়ো হাওয়ায় পোলে ভারসাম্য থাকে না, তার দুলে নিরাপদ দূরত্ব কমে। চাপ দিলেও উঁচুতে কাজ বন্ধ।',
    art: 'assets/game/art/storm_board/push_gale.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const lightningClimb = DoMistake(
    key: '1.9/push/climb-in-lightning',
    textBn: 'বজ্র দেখলে বা শুনলে উঁচুতে কাজ বন্ধ — কোনো পিপিই বজ্র আটকায় না। নেমে নিরাপদ আশ্রয়ে যান।',
    art: 'assets/game/art/storm_board/push_lightning.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const shelterTree = DoMistake(
    key: '1.9/push/shelter-tree',
    textBn: 'মাঠের মাঝে একা গাছতলাও খোলা জায়গা — বজ্রে খোলা জায়গায় সরাসরি আঘাত মারাত্মক। কাজে পৌঁছেই ঠিক করুন, ঝড় হলে কোথায় আশ্রয়।',
    art: 'assets/game/art/storm_board/push_shelter.svg',
    lessonPoint: 1,
  );
  static const shelterPole = DoMistake(
    key: '1.9/push/shelter-pole',
    textBn: 'পোলের গোড়া আশ্রয় নয় — পোলে বজ্র পড়লে মারাত্মক, কাছে পড়লে মাটি দিয়েও শক আসে।',
    art: 'assets/game/art/storm_board/push_shelter.svg',
    lessonPoint: 1,
  );
  static const all = [routineInRain, noGloves, galeClimb, lightningClimb, shelterTree, shelterPole];
}

/// The play state (pure logic).
class StormRun {
  StormRun(this.deal);
  final StormDeal deal;
  int round = 0;
  StormPhase phase = StormPhase.judge;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The waterproof gloves are on (this situation).
  var gloved = false;

  bool get done => round >= deal.cases.length;
  bool get ended => done || deadly != null;
  StormCase get current => deal.cases[round.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  void takeGloves() {
    if (ended || phase != StormPhase.judge) return;
    gloved = true;
  }

  /// Up the ladder (by choice or on his say-so: the same rule). Null = right
  /// (the emergency in drizzle, gloved); deadly in a storm; slips otherwise.
  DoMistake? climb() {
    if (ended || phase != StormPhase.judge) return null;
    final c = current;
    if (c.cue == StormCue.thunder) return deadly = StormMistakes.lightningClimb;
    if (c.cue == StormCue.wind) return deadly = StormMistakes.galeClimb;
    if (c.job == StormJob.routine) {
      slips++;
      phase = StormPhase.shown;
      return StormMistakes.routineInRain;
    }
    if (!gloved) {
      // Still to do: gloves first.
      slips++;
      return StormMistakes.noGloves;
    }
    phase = StormPhase.shown;
    _tag(StormLines.caughtEmergency);
    return null;
  }

  /// "না" to the go-on case this situation (no cost).
  var declines = 0;

  /// Lay the ladder down: say no. Right in drizzle-routine, gale and thunder.
  /// The emergency in plain drizzle costs nothing: the first time it stays
  /// (the lesson allows it), a second "না" moves on with no ◆.
  StormStop stop() {
    if (ended || phase != StormPhase.judge) return StormStop.ignored;
    final c = current;
    if (c.mayGoOn) {
      if (++declines < 2) return StormStop.mayGoOn;
      phase = StormPhase.shown;
      return StormStop.declined;
    }
    _tag(switch (c.cue) {
      StormCue.drizzle => StormLines.caughtDrizzle,
      StormCue.wind => StormLines.caughtWind,
      StormCue.thunder => StormLines.caughtThunder,
    });
    phase = c.needsShelter ? StormPhase.shelter : StormPhase.shown;
    return StormStop.right;
  }

  /// Where the crew goes in the thunderstorm: the van is right; under the
  /// lone tree or at the pole's foot is a slip (choose again).
  DoMistake? shelter(StormPlace p) {
    if (ended || phase != StormPhase.shelter) return null;
    switch (p) {
      case StormPlace.van:
        phase = StormPhase.shown;
        _tag(StormLines.caughtShelter);
        return null;
      case StormPlace.tree:
        slips++;
        return StormMistakes.shelterTree;
      case StormPlace.pole:
        slips++;
        return StormMistakes.shelterPole;
    }
  }

  void next() {
    round++;
    phase = StormPhase.judge;
    gloved = false;
    declines = 0;
  }
}

@immutable
class StormPushPack {
  const StormPushPack({required this.id, required this.titleBn, this.quickMs = 75000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const stormPushPacks = {'do_1_9_b': StormPushPack(id: 'do_1_9_b', titleBn: StormLines.title)};

// ============================================================================
// Page
// ============================================================================

class StormPushPage extends StatefulWidget {
  const StormPushPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final StormPushPack pack;
  final bool muted;
  final int? seed;

  @override
  State<StormPushPage> createState() => _StormPushPageState();
}

class _StormPushPageState extends State<StormPushPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _StormRunPage(
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

class _StormRunPage extends ConsumerStatefulWidget {
  const _StormRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final StormPushPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_StormRunPage> createState() => _StormRunPageState();
}

class _StormRunPageState extends ConsumerState<_StormRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final StormRun _run = StormRun(dealStorm(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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

  /// The sky has turned for this situation (the hands can act).
  var _ready = false;
  int _roundTok = 0;
  StormWeather _weather = StormWeather.fair;
  int _wake = 0;

  /// The ladder: 0 leaning, 1 laid down. The worker: how far up it.
  double _lay = 0;
  double _climb = 0;

  /// The hand on the ladder while dragging (−1 up … 1 down).
  double _pull = 0;
  var _dragging = false;
  var _dragDirect = false;
  Offset _drag = Offset.zero;

  /// Where he walked to shelter; inside the van once there.
  StormPlace? _place;
  var _walking = false;
  var _inVan = false;
  Timer? _walkTimer;

  /// A deadly climb: the scene freezes grey, the storm acts in colour.
  var _freeze = false;
  Completer<void>? _frozen;
  StormCue _doom = StormCue.thunder;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _walkTimer?.cancel();
    _chain++;
    _roundTok++;
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

  String get _task => _run.phase == StormPhase.shelter ? StormLines.askShelter : StormLines.askJudge;

  /// After the guide's intro: the clock runs and the sky turns.
  Future<void> _start() async {
    _clock.start();
    _beginRound();
  }

  /// A situation: the docket, the sky turns (thunder rolls in a storm), then
  /// the hands can act. The supervisor may be on his way.
  void _beginRound() {
    final tok = ++_roundTok;
    final c = _run.current;
    setState(() {
      _ready = false;
      _lay = 0;
      _climb = 0;
      _place = null;
      _inVan = false;
      _walking = false;
      _weather = c.weather;
      _wake++;
    });
    if (_run.round == _run.deal.callRound) scheduleCoworker();
    if (c.cue == StormCue.thunder && !_muted) unawaited(ZlFx.cue('sounds/learn/thunder_clap.wav', volume: 0.8, muted: false));
    unawaited(() async {
      await Future<void>.delayed(_quiet ? const Duration(milliseconds: 50) : const Duration(milliseconds: 1500));
      if (!mounted || tok != _roundTok || _ended) return;
      setState(() => _ready = true);
      // In his situation the guide waits for him (he asks after the deck).
      if (!coworkerOpen && !_waitingForHim) await _sayChain([StormLines.askJudge]);
    }());
  }

  /// In his situation he comes first: the hands wait for him.
  bool get _waitingForHim => _run.round == _run.deal.callRound && !coworkerDone && !coworkerOpen;

  bool get _canDecide =>
      !_intro && _ready && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_waitingForHim && _run.phase == StormPhase.judge;

  bool get _canShelter => !_intro && !_busy && !_ended && _card == null && !reasonOpen && !_walking && _run.phase == StormPhase.shelter;

  // --- hands on: the ladder ----------------------------------------------------
  void _ladderStart(DragStartDetails _) {
    // Laying it down while he is still talking refuses him too.
    _dragDirect = coworkerOpen && !coworkerChoiceUp;
    if (!_canDecide && !_dragDirect) return;
    _dragging = true;
    _drag = Offset.zero;
    HapticFeedback.selectionClick();
  }

  void _ladderUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _drag += d.delta;
    setState(() => _pull = (_drag.dy / 110).clamp(-1.0, 1.0));
  }

  void _ladderEnd(Offset origin) {
    if (!_dragging) return;
    _dragging = false;
    final up = _drag.dy < -36 && _drag.dy.abs() > _drag.dx.abs();
    final down = _drag.dy > 36 || _drag.dx.abs() > 56;
    setState(() => _pull = 0);
    if (_dragDirect) {
      _dragDirect = false;
      if (down && coworkerOpen && !coworkerChoiceUp) {
        unawaited(answerCoworker(true, origin, direct: true));
        unawaited(_layDown(origin));
      }
      return;
    }
    if (up) unawaited(_climbUp(origin));
    if (down && !up) unawaited(_layDown(origin));
  }

  /// Up the ladder (or on his say-so).
  Future<void> _climbUp(Offset origin) async {
    if (!_canDecide) return;
    _hush();
    final m = _run.climb();
    HapticFeedback.mediumImpact();
    if (m == null) {
      // The emergency in plain drizzle, gloved: up he goes, carefully.
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.4, muted: false));
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      }
      setState(() {
        _climb = 0.8;
        _wake++;
      });
      putOnTable(15);
      final c = _run.current;
      final round = _run.round;
      unawaited(askReason(
        deal: () => dealChoices(StormLines.whyRight(c), StormLines.whyWrong(c), widget.rng),
        question: StormLines.whyAsk(c),
        stillValid: () => _run.round == round && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    // A slip: he starts up, then the card.
    _busy = true;
    setState(() {
      _climb = 0.3;
      _wake++;
    });
    await Future<void>.delayed(_quiet ? Duration.zero : const Duration(milliseconds: 700));
    _busy = false;
    if (!mounted) return;
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  /// Lay the ladder down: "না".
  Future<void> _layDown(Offset origin) async {
    if (!_canDecide) return;
    _hush();
    final r = _run.stop();
    if (r == StormStop.ignored) return;
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
    setState(() {
      _lay = 1;
      _wake++;
    });
    if (r == StormStop.mayGoOn) {
      // The lesson allows this one; no cost. The ladder stands again.
      _busy = true;
      await Future<void>.delayed(_quiet ? Duration.zero : const Duration(milliseconds: 700));
      _busy = false;
      if (!mounted || _ended) return;
      setState(() {
        _lay = 0;
        _wake++;
      });
      unawaited(_sayChain([StormLines.mayGoOn, StormLines.mayGoOnStill], mood: GuideMood.think));
      return;
    }
    if (r == StormStop.declined) {
      // His right: on to the next situation, no ◆, no cost.
      final round = _run.round;
      await Future.wait([
        _sayChain([StormLines.declined]),
        Future<void>.delayed(_quiet ? const Duration(milliseconds: 400) : const Duration(milliseconds: 1400)),
      ]);
      if (!mounted || _ended || _run.round != round) return;
      _next();
      return;
    }
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
    putOnTable(15);
    final c = _run.current;
    final round = _run.round;
    unawaited(askReason(
      deal: () => dealChoices(StormLines.whyRight(c), StormLines.whyWrong(c), widget.rng),
      question: StormLines.whyAsk(c),
      stillValid: () => _run.round == round && !_ended,
    ));
  }

  // --- hands on: the gloves, the shelter -----------------------------------------
  void _takeGloves() {
    if (_run.gloved || _intro || _ended || _card != null || reasonOpen || _run.phase != StormPhase.judge) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.5, muted: false));
    _run.takeGloves();
    setState(() => _wake++);
    if (!coworkerOpen) unawaited(_sayChain([StormLines.glovesOn]));
  }

  Future<void> _pickShelter(StormPlace p, Offset origin) async {
    if (!_canShelter) return;
    _hush();
    final m = _run.shelter(p);
    HapticFeedback.selectionClick();
    _walkTimer?.cancel();
    setState(() {
      _place = p;
      _walking = !_quiet;
      _wake++;
    });
    final walk = _quiet ? Duration.zero : const Duration(milliseconds: 950);
    _busy = true;
    await Future<void>.delayed(walk);
    _busy = false;
    if (!mounted || _ended) return;
    setState(() {
      _walking = false;
      _inVan = m == null && p == StormPlace.van;
      _wake++;
    });
    if (m == null) {
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.6, muted: false));
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      }
      putOnTable(10);
      final round = _run.round;
      unawaited(askReason(
        deal: () => dealChoices(StormLines.shelterRight, StormLines.shelterWrong, widget.rng),
        question: StormLines.whyShelter,
        stillValid: () => _run.round == round && !_ended,
      ));
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  /// The next situation (or the result) — by itself.
  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _beginRound();
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
    if (_run.phase == StormPhase.shelter) {
      // Stopped in the thunderstorm: now where to shelter.
      setState(() => _wake++);
      unawaited(_sayChain([StormLines.askShelter]));
      return;
    }
    _next();
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => StormLines.coworker(_run.current.cue);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.round != _run.deal.callRound || _run.phase != StormPhase.judge) return null;
    if (_intro || !_ready || _busy || _card != null || reasonOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up the ladder on his say-so.
      await _climbUp(origin);
      return;
    }
    _run.caught.add(StormLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([StormLines.callHeld, StormLines.askJudge], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? StormLines.tapWhy[_nudgeN++ % StormLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
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
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('storm/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up the ladder in a storm: the roadside freezes grey while the storm
  /// acts in colour (the bolt, or the gale and the galloping wires); then
  /// near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _doom = _run.current.cue == StormCue.wind ? StormCue.wind : StormCue.thunder;
    if (!_muted) {
      unawaited(ZlFx.cue(_doom == StormCue.thunder ? 'sounds/learn/thunder_clap.wav' : 'sounds/learn/spark.wav', volume: 0.95, muted: false));
    }
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
    final speak = await SpokenOnce.first('storm/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? StormLines.deadlyWord : StormLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          // Back to where the choice was: the ladder up, the worker down.
          if (_run.phase == StormPhase.judge) {
            _lay = 0;
            _climb = 0;
          }
          _wake++;
        });
        if (_run.phase == StormPhase.shown) {
          _next();
        } else {
          unawaited(_sayChain([_task]));
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
      _wake++;
    });
    await _say(!_run.passed ? StormLines.fail : (_quickBonus ? StormLines.quick : StormLines.allSet),
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
    if (_walking) return LinemanMode.walk;
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_mark != null && _run.passed) return LinemanMode.cheer;
    if (_climb > 0) return LinemanMode.hold;
    if (_lay > 0.5) return LinemanMode.point;
    return LinemanMode.idle;
  }

  /// The worker's feet now (design px) and whether he faces left.
  (Offset, bool) _workerAt(StormGeo geo) {
    final foot = geo.ladderFoot;
    final top = geo.ladderTop;
    switch (_place) {
      case StormPlace.van:
        return (Offset(geo.van.left + 34, geo.groundY + 20), true);
      case StormPlace.tree:
        return (Offset(StormGeo.treeX - 16, geo.groundY + 8), false);
      case StormPlace.pole:
        return (Offset(StormGeo.poleX + 16, geo.groundY + 8), true);
      case null:
        break;
    }
    final up = math.max(_climb, _pull < 0 ? -_pull * 0.08 : 0.0);
    if (up <= 0) return (Offset(foot.dx + 20, geo.groundY + 10), true);
    final on = Offset.lerp(foot, top, up)!;
    return (on.translate(10, 4), true);
  }

  static const _look = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
  );
  static const _gloved = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
    gloves: true,
  );

  /// Where the gloves hang (design px): on a hook by the van's rear door.
  static Rect _glovesRect(StormGeo geo) => Rect.fromLTWH(geo.van.right - 34, geo.van.top + 10, 26, 34);

  static Rect _placeRect(StormGeo geo, StormPlace p) => switch (p) {
        StormPlace.van => geo.van.inflate(4),
        StormPlace.tree => Rect.fromLTRB(StormGeo.treeX - 52, geo.crown.dy - 46, 360, geo.groundY + 12),
        StormPlace.pole => Rect.fromLTRB(StormGeo.poleX - 22, geo.topY + 30, StormGeo.poleX + 22, geo.groundY + 14),
      };

  List<Widget> _scene(SceneMetrics m) {
    final geo = StormGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final (feet, faceLeft) = _workerAt(geo);
    final ws = geo.worker;
    final lay = math.max(_lay, _pull > 0 ? _pull * 0.3 : 0.0);
    final showGloves = !_run.gloved && _run.phase == StormPhase.judge && !_freeze;
    final dark = _weather.cloud * 0.5;
    final half = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 900);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: TweenAnimationBuilder<StormWeather>(
            tween: StormWeatherTween(end: _weather),
            duration: quiet ? Duration.zero : const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
            builder: (context, w, _) => AwakeClock(
              wake: _wake,
              quiet: quiet,
              awake: const Duration(seconds: 6),
              builder: (context, clock) => Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    key: const ValueKey('w-paint'),
                    child: CustomPaint(painter: StormWorldPainter(geo: geo, weather: w, clock: clock, quiet: quiet)),
                  ),
                  if (!_freeze)
                    TweenAnimationBuilder<double>(
                      key: const ValueKey('w-ladder'),
                      tween: Tween(end: lay),
                      duration: _dragging || quiet ? Duration.zero : const Duration(milliseconds: 520),
                      curve: Curves.easeOutBack,
                      builder: (_, l, _) => CustomPaint(painter: StormLadderPainter(geo: geo, lay: l, dark: dark)),
                    ),
                  if (showGloves)
                    Positioned.fromRect(
                      key: ValueKey('w-gloves-${_run.round}'),
                      rect: _glovesRect(geo),
                      child: const IgnorePointer(child: CustomPaint(painter: StormGlovesPainter())),
                    ),
                  if (!_freeze && !_inVan)
                    Positioned.fill(
                      key: const ValueKey('w-worker'),
                      child: IgnorePointer(
                        child: TweenAnimationBuilder<Offset>(
                          tween: Tween(end: feet),
                          duration: _dragging ? Duration.zero : (_place != null ? (quiet ? Duration.zero : const Duration(milliseconds: 950)) : half),
                          curve: _place != null ? Curves.linear : Curves.easeInOut,
                          builder: (_, p, child) => Stack(
                            children: [Positioned(left: p.dx - ws.width / 2, top: p.dy - ws.height, width: ws.width, height: ws.height, child: child!)],
                          ),
                          child: Transform.flip(
                            flipX: faceLeft,
                            child: LinemanFigure(
                              look: _run.gloved ? _gloved : _look,
                              mode: _mode,
                              point: 3.0,
                              wake: _wake,
                              quiet: quiet,
                            ),
                          ),
                        ),
                      ),
                    ),
                  IgnorePointer(
                    key: const ValueKey('w-rain'),
                    child: CustomPaint(painter: StormRainPainter(geo: geo, weather: w, clock: clock)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // The hands: the ladder (drag up = climb, drag down = lay it down).
      if (playing && _run.phase == StormPhase.judge && _card == null)
        Positioned(
          key: const ValueKey('hit-ladder'),
          left: geo.ladderTop.dx - 18,
          top: geo.ladderTop.dy - 12,
          width: geo.ladderFoot.dx - geo.ladderTop.dx + 62,
          height: geo.ladderFoot.dy - geo.ladderTop.dy + 26,
          child: Builder(
            builder: (ctx) => Semantics(
              label: StormLines.ladderLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _ladderStart,
                onPanUpdate: _ladderUpdate,
                onPanEnd: (_) {
                  final box = ctx.findRenderObject() as RenderBox?;
                  final at = box == null ? Offset.zero : box.localToGlobal(box.size.center(Offset.zero));
                  _ladderEnd(at);
                },
                onPanCancel: () {
                  _dragging = false;
                  _dragDirect = false;
                  if (_pull != 0) setState(() => _pull = 0);
                },
              ),
            ),
          ),
        ),
      if (playing && showGloves && _card == null)
        Positioned(
          key: const ValueKey('hit-gloves'),
          left: _glovesRect(geo).left - 8,
          top: _glovesRect(geo).top - 6,
          width: 46,
          height: 50,
          child: Semantics(
            button: true,
            label: StormLines.glovesLabel,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _takeGloves),
          ),
        ),
      if (playing && _run.phase == StormPhase.shelter && !reasonOpen && _card == null)
        for (final p in StormPlace.values)
          Positioned.fromRect(
            key: ValueKey('hit-${p.name}'),
            rect: _placeRect(geo, p),
            child: Builder(
              builder: (ctx) => Semantics(
                button: true,
                label: StormLines.placeLabel(p),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => unawaited(_pickShelter(p, d.globalPosition)),
                ),
              ),
            ),
          ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('doom'),
          child: IgnorePointer(child: _DoomView(kind: _doom, geo: geo, quiet: quiet)),
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
              labels: StormLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (playing && !_run.done)
                Positioned(
                  key: ValueKey('hud-docket-${_run.round}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _Docket(job: _run.current.job, quiet: quiet)),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
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
                  line: StormLines.intro,
                  alarm: 'sounds/learn/thunder_clap.wav',
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

/// The docket the crew works to (what a worker reads): the job's kind.
class _Docket extends StatelessWidget {
  const _Docket({required this.job, required this.quiet});
  final StormJob job;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final urgent = job == StormJob.emergency;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.rotate(angle: -0.04 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E4),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: urgent ? SlmColors.danger : const Color(0xFF1F5F8F), width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x77000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(StormLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5A44))),
            Text(StormLines.job(job), style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: urgent ? const Color(0xFFB0281C) : SlmColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// The deadly moment in colour over the frozen roadside: he goes up the
/// ladder; a bolt strikes the pole (sparks run down it, the ground ripples),
/// or the gale swings the ladder and the galloping wires flash; he comes off
/// the ladder. Non-graphic: a figure on the verge, no injury shown.
class _DoomView extends StatelessWidget {
  const _DoomView({required this.kind, required this.geo, required this.quiet});
  final StormCue kind;
  final StormGeo geo;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final ws = geo.worker;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 2300),
      builder: (_, t, _) {
        final pose = _DoomPainter.pose(kind, geo, t);
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(key: const ValueKey('doom-paint'), painter: _DoomPainter(kind: kind, geo: geo, t: t), size: Size.infinite),
            // The worker as in play (LinemanFigure), turned as he comes off.
            Positioned(
              key: const ValueKey('doom-worker'),
              left: pose.feet.dx - ws.width / 2,
              top: pose.feet.dy - ws.height,
              width: ws.width,
              height: ws.height,
              child: Transform.rotate(
                angle: pose.angle,
                alignment: Alignment.bottomCenter,
                child: Transform.flip(
                  flipX: true,
                  child: LinemanFigure(
                    look: _StormRunPageState._look,
                    mode: pose.off ? LinemanMode.worried : LinemanMode.hold,
                    quiet: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DoomPainter extends CustomPainter {
  _DoomPainter({required this.kind, required this.geo, required this.t});
  final StormCue kind;
  final StormGeo geo;
  final double t;

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// Where the worker's feet are, how far he is turned, how much he glows
  /// (the strike), whether he is off the ladder, and the ladder's top.
  static ({Offset feet, double angle, double glow, bool off, Offset top}) pose(StormCue kind, StormGeo geo, double t) {
    final foot = geo.ladderFoot;
    final top0 = geo.ladderTop;
    final climb = 0.3 + 0.32 * Curves.easeOut.transform(_seg(t, 0, 0.28));
    if (kind == StormCue.thunder) {
      final strike = _seg(t, 0.3, 0.36);
      final fade = 1 - _seg(t, 0.38, 0.9);
      final drop = Curves.easeIn.transform(_seg(t, 0.5, 0.78));
      final onLadder = Offset.lerp(foot, top0, climb)!.translate(10, 4);
      final down = Offset(foot.dx + 34, geo.groundY + 12);
      return (
        feet: Offset.lerp(onLadder, down, drop)!,
        angle: -math.pi / 2 * drop,
        glow: strike > 0 ? fade * (1 - drop * 0.6) : 0.0,
        off: drop > 0.5,
        top: top0,
      );
    }
    final swing = math.sin(t * 26) * 0.07 * _seg(t, 0.1, 0.5);
    final topple = Curves.easeIn.transform(_seg(t, 0.55, 0.85));
    final up = top0 - foot;
    final a = math.atan2(up.dy, up.dx) + swing + (-(math.atan2(up.dy, up.dx)) * topple);
    final len = up.distance * (1 - 0.4 * topple);
    final top = foot + Offset(math.cos(a), math.sin(a)) * len;
    final fall = Curves.easeIn.transform(_seg(t, 0.6, 0.86));
    final onLadder = Offset.lerp(foot, top, climb)!.translate(10, 4);
    final down = Offset(foot.dx + 46, geo.groundY + 12);
    return (
      feet: Offset.lerp(onLadder, down, fall)!,
      angle: -math.pi / 2 * fall + swing,
      glow: 0.0,
      off: fall > 0.5,
      top: top,
    );
  }

  /// The strike's glow round him (he is drawn by LinemanFigure on top).
  void _glow(Canvas c, Offset feet, double angle, double h, double glow) {
    if (glow <= 0) return;
    final k = h / 60;
    final body = Offset(30 * k * math.sin(angle), -30 * k * math.cos(angle));
    c.drawCircle(feet + body, 34 * k, Paint()..color = const Color(0xFFDDEBFF).withValues(alpha: 0.7 * glow)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }

  void _ladder(Canvas c, Offset foot, Offset top) {
    final d = top - foot;
    final len = d.distance;
    if (len < 1) return;
    final u = d / len;
    final n = Offset(-u.dy, u.dx) * 7;
    final rail = Paint()
      ..color = const Color(0xFFD5DCE2)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(foot - n, top - n, rail);
    c.drawLine(foot + n, top + n, rail);
    for (var s = 12.0; s < len - 4; s += 14) {
      final p = foot + u * s;
      c.drawLine(p - n, p + n, rail..strokeWidth = 1.8);
    }
  }

  @override
  void paint(Canvas c, Size s) {
    final foot = geo.ladderFoot;
    final top0 = geo.ladderTop;
    final h = geo.worker.height;
    if (kind == StormCue.thunder) {
      _ladder(c, foot, top0);
      final strike = _seg(t, 0.3, 0.36);
      final fade = 1 - _seg(t, 0.38, 0.9);
      final poleTop = Offset(StormGeo.poleX, geo.topY - 12);
      if (strike > 0 && fade > 0) {
        // The bolt from the cloud to the pole top.
        final rng = math.Random(5);
        final from = Offset(StormGeo.poleX + 46, 0);
        final p = Path()..moveTo(from.dx, from.dy);
        const n = 9;
        for (var i = 1; i <= n; i++) {
          final k = i / n * strike;
          p.lineTo(from.dx + (poleTop.dx - from.dx) * k + (i == n ? 0 : (rng.nextDouble() - 0.5) * 30), from.dy + (poleTop.dy - from.dy) * k);
        }
        c.drawPath(p, Paint()..color = const Color(0xFFAFCBFF).withValues(alpha: 0.7 * fade)..style = PaintingStyle.stroke..strokeWidth = 12..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        c.drawPath(p, Paint()..color = Colors.white.withValues(alpha: fade)..style = PaintingStyle.stroke..strokeWidth = 3);
        c.drawCircle(poleTop, 46 * fade, Paint()..color = const Color(0xFFEAF2FF).withValues(alpha: 0.6 * fade)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      }
      // Sparks run down the pole and the ladder.
      final run = _seg(t, 0.34, 0.7);
      if (run > 0 && run < 1) {
        final spark = Paint()..color = const Color(0xFFFFE066);
        for (var i = 0; i < 6; i++) {
          final k = (run + i * 0.06).clamp(0.0, 1.0);
          c.drawCircle(Offset(StormGeo.poleX + (i.isEven ? -3 : 3), geo.topY + (geo.groundY - geo.topY) * k), 3, spark);
          c.drawCircle(Offset.lerp(top0, foot, k)!, 2.4, spark);
        }
      }
      // The ground ripples round the pole (step potential).
      final rip = _seg(t, 0.45, 1);
      if (rip > 0) {
        for (var i = 0; i < 3; i++) {
          final r = (rip * 90 + i * 26) % 110;
          final a = (1 - r / 110) * 0.9;
          c.drawOval(
            Rect.fromCenter(center: Offset(StormGeo.poleX, geo.groundY + 8), width: r * 2.4, height: r * 0.5),
            Paint()
              ..color = const Color(0xFFFFD34E).withValues(alpha: a)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
      // He lights up, then comes off the ladder onto the verge (the figure
      // itself is the LinemanFigure over this painter).
      final me = pose(kind, geo, t);
      _glow(c, me.feet, me.angle, h, me.glow);
      return;
    }
    // The gale: the wires gallop and flash, the ladder swings and goes.
    final top = pose(kind, geo, t).top;
    final arm = geo.armY;
    final gallop = 30 * math.sin(t * 14);
    final wire = Paint()
      ..color = const Color(0xFF1E2329)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 2; i++) {
      final y = arm - 15;
      final p = Path()
        ..moveTo(StormGeo.poleX + (i == 0 ? -40 : 40), y)
        ..quadraticBezierTo(StormGeo.poleX + 110, y + 22 + (i == 0 ? gallop : -gallop), s.width + 10, y - 26);
      c.drawPath(p, wire);
    }
    final arc = _seg(t, 0.28, 0.34) * (1 - _seg(t, 0.66, 0.82));
    if (arc > 0) {
      final at = Offset(StormGeo.poleX + 108, arm + 2);
      c.drawCircle(at, 34 * arc, Paint()..color = const Color(0xFFB9D6FF).withValues(alpha: 0.75 * arc)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      final star = Paint()
        ..color = Colors.white.withValues(alpha: arc)
        ..strokeWidth = 2;
      for (var i = 0; i < 8; i++) {
        final d = Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4));
        c.drawLine(at + d * 6, at + d * 22 * arc, star);
      }
    }
    _ladder(c, foot, top);
  }

  @override
  bool shouldRepaint(_DoomPainter old) => old.t != t || old.kind != kind || old.geo != geo;
}
