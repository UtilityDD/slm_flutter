import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'shock_scene.dart';
import 'spoken_once.dart';

// Lesson 1.7, কাজ 1: "ছোঁবেন না!". A colleague is stuck to a live wire and
// every second counts (a whole-second countdown per scene). Three scenes a
// play (house, pump room, field, roadside — at least one with a switch at hand
// and one without), drawn full screen (shock_scene.dart).
// Hands on: where a switch is at hand (house: the main board; pump room: the
// pump's switch box), pull its lever down to OFF — the best way (lesson
// 1.7 point 2). Where there is none, drag a dry non-conductor from what lies
// about (dry bamboo, plastic chair, dry plank, fibreglass hot stick — not the
// wet stick, the iron rod or the aluminium ladder) onto his arm or leg — the
// push goes on the limbs, not the chest or head ("ধাক্কাটি হাত বা পায়ে, বুক
// বা মাথায় নয়").
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" (the reasons fit what this
// scene had: the switch, or the thing he pushed with) → the next scene comes
// by itself; the careless coworker once a play ("হাত দিয়ে টেনে নাও"). On his
// scene the decisive move (the lever pulled, a thing pushed onto him) waits
// for him ([CoworkerMoment.holdForCoworker]), so a fast play can't skip him;
// he never comes once the colleague is free (his push no longer fits) nor in
// a praise window ([ReasonTable.tableBusy]). Gesture hints: a sweep over the
// things the hands can take beside a switch, a short nudge of a floor thing
// elsewhere — never which one.
//
// Deadly (owner-approved list): touching the victim (a tap on him, or doing
// what the coworker says — MODULE1_LADDER.md step 20: his push is the deadly
// touch itself); a wet or metal object on him. Slips: separating
// when the switch was right there, pushing the chest or head (owner decision
// 2026-11-08: a slip — the scene stays to be done again), running out of time.
// Three slips strike the level out.
//
// Voice: the guide's lines by device TTS; the coworker in his recorded voice.
// Art: the places, the colleague, the switch and the things are drawn in code;
// mistake pictures in assets/game/art/shock/.

// ============================================================================
// Content
// ============================================================================

enum ShockScene { house, pump, field, roadside }

extension ShockSceneFacts on ShockScene {
  /// A switch is at hand (house: the main board; pump room: the pump's switch box).
  bool get switchNear => this == ShockScene.house || this == ShockScene.pump;
}

enum RescueObject { bamboo, chair, plank, hotStick, wetStick, ironRod, ladder }

extension RescueObjectFacts on RescueObject {
  /// A dry non-conductor (lesson 1.7 point 2: dry wood, bamboo, plastic chair, fibreglass hot stick).
  bool get safe => this == RescueObject.bamboo || this == RescueObject.chair || this == RescueObject.plank || this == RescueObject.hotStick;
}

enum BodyZone { head, chest, arm, leg }

extension BodyZoneFacts on BodyZone {
  bool get limb => this == BodyZone.arm || this == BodyZone.leg;
}

@immutable
class RescueRound {
  const RescueRound({required this.scene, required this.objects});
  final ShockScene scene;
  final List<RescueObject> objects;
}

/// One play: three scenes, and the scene where the coworker peeps in.
@immutable
class RescueDeal {
  const RescueDeal({required this.rounds, required this.callScene});
  final List<RescueRound> rounds;
  final int callScene;
}

abstract final class RescueLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'ছোঁবেন না!';
  static const intro = 'সহকর্মী লাইভ তারে আটকে গেছে! প্রতি সেকেন্ড মূল্যবান — এখনই ছাড়ান!';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];

  /// The task at each scene (never the answer).
  static const ask = 'সহকর্মী তারে আটকে! নিজে বাঁচিয়ে ওকে ছাড়ান।';
  static const arrive = [ask, 'আবার! আরেকজন তারে আটকে — দ্রুত ছাড়ান।', 'শেষজন! মাথা ঠান্ডা রেখে ওকে ছাড়ান।'];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static String secs(int s) => '${enDigits('$s')} সেকেন্ড';

  // Semantics only (no text on the scene).
  static const sceneLabel = 'দৃশ্য';
  static const switchLabel = 'সুইচ';

  // The reasons (lesson 1.7 point 2). Every card is 35–45 letters, so none
  // stands out by its length, and the right ones are no longer than the wrong
  // ones on average. The right ones fit what this scene had. Every deal holds a
  // "twin" — a wrong reason that names the same place or thing — and no word
  // of a right card is missing from the wrong ones (no word gives it away).
  static const whySwitch = 'কেন সুইচ নামালেন?';
  static const whyPush = 'কেন এটা দিয়ে ঠেললেন?';
  static const switchHouse = ['মেইন সুইচ কাছেই, আগে সোর্স বন্ধ করেছি', 'সুইচ পাশেই ছিল, বিদ্যুৎ বন্ধই সেরা পথ'];
  static const switchPump = ['পাম্পের সুইচ কাছেই, আগে সোর্স বন্ধ করেছি', 'পাম্পের সুইচ পাশেই, বিদ্যুৎ বন্ধই সেরা পথ'];
  /// Wrong reasons that start like the right ones of this place (so no
  /// word or name sits on the right card only); one is dealt every time.
  static const twinHouse = ['মেইন সুইচ কাছেই, আগে নামালেই কাজ শেষ', 'সুইচ পাশেই ছিল, ধাক্কার চেয়ে কম খাটুনি'];
  static const twinPump = ['পাম্পের সুইচ কাছেই, আগে নামালেই কাজ শেষ', 'পাম্পের সুইচ পাশেই, ধাক্কার চেয়ে কম খাটুনি'];
  static const switchWrong = [
    'টেনে আনতে ভয় লাগল, তাই সুইচটা নামালাম',
    'বোর্ডে ON দেখে এমনিই সোর্স বন্ধ করেছি',
    'সোর্স বন্ধ হলেই হলো, ওকে আর দেখার কিছু নেই',
    'বিদ্যুৎ বন্ধ করলে শক শরীর থেকে বেরিয়ে যায়',
    'আগে সুইচ নামালে ও নিজে থেকেই উঠে দাঁড়াবে',
    'বিদ্যুৎ বন্ধই সেরা পথ, পরে আর কিছু দেখতে নেই',
  ];
  static List<String> objectWhy(RescueObject o) => switch (o) {
        RescueObject.bamboo => const ['সুইচ নেই, শুকনো বাঁশ দিয়ে হাত-পায়ে ঠেলেছি', 'শুকনো বাঁশ অপরিবাহী, তাই আমি সার্কিটে নেই'],
        RescueObject.plank => const ['সুইচ নেই, শুকনো কাঠ দিয়ে হাত-পায়ে ঠেলেছি', 'শুকনো কাঠ অপরিবাহী, তাই আমি সার্কিটে নেই'],
        RescueObject.chair => const ['সুইচ নেই, প্লাস্টিক চেয়ারে হাত-পায়ে ঠেলেছি', 'প্লাস্টিকের চেয়ার অপরিবাহী, আমি নিরাপদ'],
        RescueObject.hotStick => const ['সুইচ নেই, হট স্টিক দিয়ে হাত-পায়ে ঠেলেছি', 'ফাইবারগ্লাস হট স্টিক অপরিবাহী, আমি নিরাপদ'],
        // Never right: these are deadly.
        RescueObject.wetStick || RescueObject.ironRod || RescueObject.ladder => const [],
      };

  /// Wrong reasons that name the thing he pushed with (see [twinHouse]).
  static List<String> objectTwin(RescueObject o) => switch (o) {
        RescueObject.bamboo => const ['বাঁশটা লম্বা, তাই দূর থেকে বুকে ঠেলে দিয়েছি', 'শুকনো বা ভেজা — বাঁশ তো বাঁশই, শক লাগে না'],
        RescueObject.plank => const ['কাঠটা ভারী, তাই জোরে একটা ঘা দিয়ে দিয়েছি', 'শুকনো বা ভেজা — কাঠ তো কাঠই, শক লাগে না'],
        RescueObject.chair => const ['প্লাস্টিকের চেয়ার, ভেজা হলেও তো চলত', 'প্লাস্টিক চেয়ারে বুকে ঠেলাই সবচেয়ে দ্রুত'],
        RescueObject.hotStick => const ['হট স্টিক লম্বা, তাই দূর থেকে মাথায় ঠেলেছি', 'ফাইবারগ্লাস হট স্টিক ভেজা হলেও অপরিবাহী'],
        RescueObject.wetStick || RescueObject.ironRod || RescueObject.ladder => const [],
      };
  static const pushAny = 'সুইচ নেই, তাই শুকনো অপরিবাহী দিয়ে আলাদা';
  static const pushWrong = [
    'হাতের কাছে যা পেয়েছি, তা দিয়েই আলাদা করেছি',
    'জোরে একটা ধাক্কা দিলেই হলো, জিনিস যা-ই হোক',
    'সুইচ নেই, তাই যা পেলাম তা দিয়েই ঠেলেছি',
    'বুকে ধাক্কা দিলে এক ধাক্কাতেই ছেড়ে দেয়',
    'অপরিবাহী হলে বুকে-মাথায় ঠেলাও নিরাপদ',
    'লোহার রড দিয়ে ঠেললেও আমি সার্কিটে নেই',
    'হাত-পায়ে ঠেললে ভেজা লাঠিতেও শক লাগে না',
    'সুইচ খোঁজার চেয়ে ঠেলে দেওয়াই অনেক দ্রুত',
    'শুকনো হোক বা না হোক, শক্ত হলেই ঠেলা যায়',
    'অপরিবাহী হলে ভেজা হলেও আমি সার্কিটে নেই',
    'শুকনো অপরিবাহী খুঁজতে দেরি, হাতেই আলাদা করি',
    'হাত-পায়ে হোক বা বুকে, ঠেলা দিলেই ছেড়ে দেয়',
    'অপরিবাহী না হলেও এক ঝটকায় সার্কিটে ঢুকব না',
    'রাবার জুতো পরা থাকলে খালি হাতেও নিরাপদ',
  ];

  /// The right reasons for what [scene] had: the switch ([used] null) or the thing pushed with.
  static List<String> whyRight(ShockScene scene, RescueObject? used) =>
      used == null ? (scene == ShockScene.pump ? switchPump : switchHouse) : [...objectWhy(used), pushAny];

  /// The wrong reasons that look like this scene's right ones (one is dealt every time).
  static List<String> whyTwins(ShockScene scene, RescueObject? used) =>
      used == null ? (scene == ShockScene.pump ? twinPump : twinHouse) : objectTwin(used);

  /// Every wrong reason that can be dealt for this scene.
  static List<String> whyWrong(ShockScene scene, RescueObject? used) =>
      [...whyTwins(scene, used), ...(used == null ? switchWrong : pushWrong)];

  /// The key words of a reason (the place, the thing, and why it is safe).
  /// Each one on the dealt right card is on a wrong card of the same deal too.
  static const whyMarks = [
    'শুকনো', 'অপরিবাহী', 'সোর্স', 'বন্ধ', 'বিদ্যুৎ', 'কাছেই', 'পাশেই', 'হাত-পায়ে', 'সার্কিটে', 'নিরাপদ', //
    'আলাদা', 'আগে', 'ফাইবারগ্লাস', 'হট স্টিক', 'প্লাস্টিক', 'চেয়ার', 'বাঁশ', 'কাঠ', 'পাম্পের', 'মেইন',
  ];
  static Iterable<String> marksOf(String t) => whyMarks.where(t.contains);

  /// One right reason, one twin and one other wrong one, in a random order.
  /// The two wrong ones are picked so that every key word of the right one is
  /// on one of them (no word in this deal sits on the right card only).
  static List<ChoiceOption> dealWhy(ShockScene scene, RescueObject? used, math.Random rng) {
    final right = whyRight(scene, used);
    final pick = right[rng.nextInt(right.length)];
    final twins = whyTwins(scene, used);
    final rest = used == null ? switchWrong : pushWrong;
    final marks = marksOf(pick).toList();
    final all = [for (final t in twins) for (final x in rest) (t, x)];
    final fair = all.where((p) => marks.every((m) => p.$1.contains(m) || p.$2.contains(m))).toList();
    final (twin, other) = (fair.isEmpty ? all : fair)[rng.nextInt(fair.isEmpty ? all.length : fair.length)];
    return [ChoiceOption(pick, true), ChoiceOption(twin, false), ChoiceOption(other, false)]..shuffle(rng);
  }

  /// The careless coworker (his recorded voice): grab him by hand.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'হাত দিয়ে টেনে নাও, তাড়াতাড়ি!',
    exitLine: coworkerExit,
    right: [
      'না, ছুঁলে আমিও সার্কিটে ঢুকে যাব',
      'না, ছোঁব না — আগে নিজে বাঁচি',
      'ছোঁব না, শুকনো কিছু বা সুইচ চাই',
      'না, টানব না — ছুঁলে আমিও সার্কিটে',
    ],
    wrong: [
      'ঠিক, হাত দিয়েই এক্ষুনি টেনে আনি',
      'জামা ধরে টানলে তো ছোঁয়া হয় না',
      'এক ঝটকায় টানলে সার্কিটে ঢুকব না',
      'ছুঁলে কিছু হবে না, হাত দিয়েই টানি',
      'সুইচ খুঁজতে দেরি, হাত দিয়েই টানি',
      'আগে ওকে টানি, নিজে বাঁচব পরে',
      'ছোঁব না, শুধু জামা ধরে টেনে আনি',
      'না, সময় নেই — হাত দিয়েই টানি',
      'ও তো সহকর্মী, ছুঁয়েই টেনে আনি',
      'শুকনো হাতে ধরলে তো শক লাগে না',
    ],
    asks: ['ও বলছে হাত দিয়ে টানতে। আপনি কী করবেন?', 'হাত দিয়ে টানবেন, না অন্য পথ?', 'কার কথা শুনবেন — ওর, না পাঠের?'],
  );

  static const callHeld = 'ঠিক! ছুঁলে দুজন আহত — নিজে বাঁচুন, তারপর বাঁচান।';
  static const allSet = 'মাথা ঠান্ডা, হাত শুকনো — জীবন বাঁচানোর পথ জানেন!';
  static const quick = 'ঝটপট আর নির্ভুল!';
  static const fail = 'আরেকবার — আগে সোর্স, না হলে শুকনো কিছু দিয়ে হাত-পায়ে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtSwitch = 'হাতের কাছের সুইচ আগে বন্ধ';
  static const caughtObject = 'শুকনো জিনিস দিয়ে আলাদা';
  static const caughtPush = 'হাত-পায়ে ধাক্কা';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class RescueMistakes {
  static const touch = DoMistake(
    key: '1.7/rescue/touch',
    textBn: 'শক লাগা মানুষকে ছুঁলেই আপনিও সার্কিটের অংশ — দুজন আহত। নিজে বাঁচুন, তারপর বাঁচান।',
    art: 'assets/game/art/shock/shock_touch.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const shirt = DoMistake(
    key: '1.7/rescue/shirt',
    textBn: 'জামা ধরে টানাও তাকে ছোঁয়া — ভিকটিম Live, আপনিও সার্কিটে ঢুকে যান।',
    art: 'assets/game/art/shock/shock_touch.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const wetStick = DoMistake(
    key: '1.7/rescue/wet-stick',
    textBn: 'ভেজা লাঠি বিদ্যুৎ টানে — শুধু শুকনো কাঠ, বাঁশ, প্লাস্টিকের চেয়ার বা হট স্টিক।',
    art: 'assets/game/art/shock/shock_objects.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const metal = DoMistake(
    key: '1.7/rescue/metal',
    textBn: 'লোহা বা অ্যালুমিনিয়াম — সোজা বিদ্যুতের পথ। শুকনো অপরিবাহী জিনিস চাই।',
    art: 'assets/game/art/shock/shock_objects.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const switchNear = DoMistake(
    key: '1.7/rescue/switch-near',
    textBn: 'সুইচ হাতের কাছেই ছিল — আগে সোর্স বন্ধ, সেটাই সবচেয়ে নিরাপদ আর দ্রুত।',
    art: 'assets/game/art/shock/shock_source.svg',
    lessonPoint: 1,
  );
  static const chestHead = DoMistake(
    key: '1.7/rescue/chest-head',
    textBn: 'বুক বা মাথায় নয় — ধাক্কা দিন হাতে বা পায়ে।',
    art: 'assets/game/art/shock/shock_push.svg',
    lessonPoint: 1,
  );
  static const late = DoMistake(
    key: '1.7/rescue/late',
    textBn: 'দেরি হয়ে গেল — যতক্ষণ তারে আটকে, ততক্ষণ ভেতরে পুড়ছে। প্রতি সেকেন্ড মূল্যবান।',
    art: 'assets/game/art/shock/shock_source.svg',
    lessonPoint: 1,
  );
  static const all = [touch, shirt, wetStick, metal, switchNear, chestHead, late];
}

/// Three scenes: one with a switch at hand, one without, one either; four
/// things lying about each (one or two dry non-conductors); the coworker's scene.
RescueDeal dealRescues(math.Random rng) {
  final a = rng.nextBool() ? ShockScene.house : ShockScene.pump;
  final b = rng.nextBool() ? ShockScene.field : ShockScene.roadside;
  final rest = [...ShockScene.values]..removeWhere((s) => s == a || s == b);
  final scenes = [a, b, rest[rng.nextInt(rest.length)]]..shuffle(rng);
  RescueRound round(ShockScene s) {
    final safe = [RescueObject.bamboo, RescueObject.chair, RescueObject.plank, RescueObject.hotStick]..shuffle(rng);
    final unsafe = [RescueObject.wetStick, RescueObject.ironRod, RescueObject.ladder]..shuffle(rng);
    final nSafe = 1 + rng.nextInt(2);
    return RescueRound(scene: s, objects: [...safe.take(nSafe), ...unsafe.take(4 - nSafe)]..shuffle(rng));
  }

  return RescueDeal(rounds: [for (final s in scenes) round(s)], callScene: rng.nextInt(3));
}

/// The play state (pure logic).
class RescueRun {
  RescueRun(this.deal);
  final RescueDeal deal;
  List<RescueRound> get rounds => deal.rounds;
  int round = 0;

  /// This scene is over: he is free, or the time ran out.
  var cleared = false;
  var late = false;

  /// What freed him (null: the switch).
  RescueObject? used;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => round >= rounds.length;
  bool get ended => done || deadly != null;
  bool get open => !ended && !cleared;
  RescueRound get current => rounds[round.clamp(0, rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// The lever pulled down to OFF (only where a switch is at hand): true = he is free.
  bool switchOff() {
    if (!open || !current.scene.switchNear) return false;
    cleared = true;
    used = null;
    _tag(RescueLines.caughtSwitch);
    return true;
  }

  /// A bare hand on him (the shirt counts): deadly.
  DoMistake? touch(BodyZone z) {
    if (!open) return null;
    return deadly = z == BodyZone.chest ? RescueMistakes.shirt : RescueMistakes.touch;
  }

  /// [o] pushed against his [z]. A wet or metal thing is deadly; with the
  /// switch at hand, or on the chest / head, a slip and the scene stays.
  DoMistake? push(RescueObject o, BodyZone z) {
    if (!open) return null;
    if (o == RescueObject.wetStick) return deadly = RescueMistakes.wetStick;
    if (!o.safe) return deadly = RescueMistakes.metal;
    if (current.scene.switchNear) {
      slips++;
      return RescueMistakes.switchNear;
    }
    if (!z.limb) {
      slips++;
      return RescueMistakes.chestHead;
    }
    cleared = true;
    used = o;
    _tag(RescueLines.caughtObject);
    _tag(RescueLines.caughtPush);
    return null;
  }

  /// The countdown ran out on this scene: a slip, and the scene is over.
  DoMistake? timeout() {
    if (!open) return null;
    slips++;
    late = true;
    cleared = true;
    return RescueMistakes.late;
  }

  void next() {
    round++;
    cleared = false;
    late = false;
    used = null;
  }
}

@immutable
class RescuePack {
  const RescuePack({required this.id, required this.titleBn, this.seconds = 15, this.quickMs = 40000});
  final String id;
  final String titleBn;

  /// Countdown per scene (whole seconds).
  final int seconds;

  /// The quick bonus: the play's time under this, not counting the "কেন …?"
  /// deck and the coworker's visit (they were not in the play before).
  final int quickMs;
}

const rescuePack17 = RescuePack(id: 'do_1_7_a', titleBn: RescueLines.title);
const rescuePacks = {'do_1_7_a': rescuePack17};

// ============================================================================
// Page
// ============================================================================

class ShockRescuePage extends StatefulWidget {
  const ShockRescuePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final RescuePack pack;
  final bool muted;
  final int? seed;

  @override
  State<ShockRescuePage> createState() => _ShockRescuePageState();
}

class _ShockRescuePageState extends State<ShockRescuePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RescueRunPage(
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

class _RescueRunPage extends ConsumerStatefulWidget {
  const _RescueRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final RescuePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RescueRunPage> createState() => _RescueRunPageState();
}

/// A thing in the hands, under the finger (design px).
@immutable
class _Held {
  const _Held(this.slot, this.object, this.at);
  final int slot;
  final RescueObject object;
  final Offset at;
}

/// What the hands did to him (the trainee steps up; drawn in the scene).
@immutable
class _Reach {
  const _Reach({required this.at, this.object, this.slot});

  /// Where it touches him (design px).
  final Offset at;

  /// What is in the hands (null: the bare hand).
  final RescueObject? object;
  final int? slot;
}

class _RescueRunPageState extends ConsumerState<_RescueRunPage>
    with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final RescueDeal _deal = dealRescues(widget.rng);
  late final RescueRun _run = RescueRun(_deal);
  final _clock = Stopwatch();

  /// Runs while the "কেন …?" deck or the coworker is up: that time is not the play's.
  final _beats = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;

  /// The countdown: only its chip listens (no page rebuild each second).
  late final ValueNotifier<int> _secs = ValueNotifier(widget.pack.seconds);
  Timer? _tick;

  // The hands.
  final _held = ValueNotifier<_Held?>(null);
  final _lever = ValueNotifier<double>(0);
  var _leverDrag = false;
  _Reach? _reach;

  /// The "how to touch" hand (taps on nothing are reported to it).
  final _hints = IdleHintController();

  /// Which thing on the floor the next drag hint nudges (round robin: no favourite).
  int _hintN = 0;

  /// Wakes the spark, the tremor and the trainee for a few seconds.
  int _wake = 0;
  var _coworkerArmed = false;

  /// The scene he peeps in on (dealt; moves on if that scene ends before he came).
  late int _callScene = _deal.callScene;

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

  /// A deadly touch: the scene freezes grey, the current's path in colour.
  var _freeze = false;
  Completer<void>? _frozen;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  /// The play's time: the clock without the reason deck and the coworker.
  int get _playMs => math.max(0, _clock.elapsedMilliseconds - _beats.elapsedMilliseconds);

  /// Keeps [_beats] running exactly while a deck or the coworker is up (both
  /// open and close with a setState, so the build sees every change).
  void _syncBeats() {
    final on = _clock.isRunning && (reasonOpen || coworkerOpen);
    if (on && !_beats.isRunning) _beats.start();
    if (!on && _beats.isRunning) _beats.stop();
  }

  ShockGeo _geoNow() {
    final size = MediaQuery.sizeOf(context);
    final w = math.max(1.0, size.width);
    final h = (360 * size.height / w).clamp(560.0, 900.0);
    return ShockGeo.forScene(h, MediaQuery.paddingOf(context).bottom * 360 / w);
  }

  @override
  void dispose() {
    disposeCoworker();
    _tick?.cancel();
    _secs.dispose();
    _held.dispose();
    _lever.dispose();
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

  // --- flow ---------------------------------------------------------------------
  /// After the guide's intro: the clock runs and the first scene begins.
  Future<void> _start() async {
    _clock.start();
    _arrive();
  }

  /// A scene begins: the spark buzzes, the countdown runs, the guide gives the task.
  void _arrive() {
    setState(() {
      _wake++;
      _reach = null;
      _lever.value = 0;
    });
    _startClock();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.8, muted: false));
    if (!_coworkerArmed && _run.round == _callScene) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
    unawaited(_sayChain([RescueLines.arrive[_run.round.clamp(0, RescueLines.arrive.length - 1)]]));
  }

  /// The countdown is held while a card, a deck or the coworker is up, or the scene is over.
  bool get _clockHeld => _intro || _ended || _card != null || reasonOpen || coworkerOpen || !_run.open || struckOut;

  /// One tick a second (one chip rebuild a second).
  void _startClock() {
    _tick?.cancel();
    _secs.value = widget.pack.seconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _clockHeld || _busy) return;
      _secs.value = math.max(0, _secs.value - 1);
      if (_secs.value == 0) {
        final m = _run.timeout();
        if (m != null) {
          _held.value = null;
          _leverDrag = false;
          unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
          unawaited(_slip(m));
        }
      } else if (_secs.value <= 5) {
        HapticFeedback.selectionClick();
        if (!_muted) unawaited(ZlFx.cue('sounds/learn/tick.wav', volume: 0.4, muted: false));
      }
    });
  }

  Offset _centre() {
    final s = MediaQuery.sizeOf(context);
    return Offset(s.width / 2, s.height * 0.45);
  }

  bool get _canPlay =>
      !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerChoiceUp && _run.open && !struckOut;

  /// The scene waits for the hands (no intro, card, deck, praise, coworker or freeze).
  bool get _waitingForHands => _canPlay && !coworkerOnScreen && !_freeze && _mark == null;

  /// How to touch (never what): beside a switch, a sweep over every thing the
  /// hands can take (the floor and the switch alike); elsewhere a short
  /// up-left nudge of one thing on the floor, round robin (never toward him).
  HintSpec? _hint() {
    if (!_run.open) return null;
    final g = _geoNow();
    final r = _run.current;
    if (r.scene.switchNear) {
      // The switch takes a new place in the lap each time, never the last one
      // (the hand rests on the last one as it fades: that would point at it).
      final at = _hintN++ % r.objects.length;
      final opts = [for (var i = 0; i < r.objects.length; i++) g.slot(i)]..insert(at, g.switchRect);
      return HintSpec.sweep(opts, space: HintSpace.scene);
    }
    final i = _hintN++ % r.objects.length;
    return HintSpec.drag(g.slot(i).center, toward: const Offset(-0.5, -1), travel: 44, space: HintSpace.scene);
  }

  /// Going on with the work while he is still talking refuses him.
  void _refuseByWorking(Offset at) {
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, at, direct: true));
  }

  // --- the hands: the switch ---------------------------------------------------
  void _leverStart(DragStartDetails d) {
    if (!_canPlay || !_run.current.scene.switchNear) return;
    _refuseByWorking(d.globalPosition);
    HapticFeedback.selectionClick();
    _leverDrag = true;
  }

  void _leverMove(DragUpdateDetails d, double height) {
    if (!_leverDrag) return;
    if (coworkerOpen) {
      _leverDrag = false;
      _lever.value = 0;
      return;
    }
    _lever.value = (_lever.value + d.delta.dy / (height * 0.42)).clamp(0.0, 1.0);
  }

  void _leverEnd(Offset origin) {
    if (!_leverDrag) return;
    _leverDrag = false;
    if (!_canPlay || _lever.value < 0.55) {
      _lever.value = 0;
      return;
    }
    // His scene: the lever snaps back and he comes first (a fast pull can't skip him).
    if (holdForCoworker()) {
      _lever.value = 0;
      return;
    }
    _lever.value = 1;
    if (!_run.switchOff()) return;
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.7, muted: false));
    _cleared(origin, 10 + _secs.value);
  }

  // --- the hands: what lies about, and him ------------------------------------
  void _panStart(DragStartDetails d) {
    if (!_canPlay) return;
    final g = _geoNow();
    final p = d.localPosition;
    final r = _run.current;
    for (var i = 0; i < r.objects.length; i++) {
      if (g.slot(i).inflate(4).contains(p)) {
        _refuseByWorking(d.globalPosition);
        HapticFeedback.selectionClick();
        if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.4, muted: false));
        _held.value = _Held(i, r.objects[i], p);
        return;
      }
    }
    // A drag that took nothing up.
    if (g.zoneAt(p) == null) _hints.missTap();
  }

  void _panUpdate(DragUpdateDetails d) {
    final cur = _held.value;
    if (cur == null) return;
    if (coworkerOpen) {
      // He peeped in mid-drag: the hands stop so the player sees him.
      _held.value = null;
      return;
    }
    final g = _geoNow();
    final p = d.localPosition;
    _held.value = _Held(cur.slot, cur.object, Offset(p.dx.clamp(6.0, 354.0), p.dy.clamp(80.0, g.height - 6)));
  }

  void _panEnd(DragEndDetails? d) {
    final cur = _held.value;
    _held.value = null;
    if (cur == null || !_canPlay || coworkerOpen) return;
    final g = _geoNow();
    final z = g.zoneAt(cur.at);
    if (z == null) return; // Put back down: nothing counts.
    // His scene: the thing goes back down and he comes first (a fast push can't skip him).
    if (holdForCoworker()) return;
    unawaited(_push(cur, z, g));
  }

  void _tapScene(TapUpDetails d) {
    if (!_canPlay) return;
    final g = _geoNow();
    final z = g.zoneAt(d.localPosition);
    if (z == null) {
      _hints.missTap();
      return;
    }
    unawaited(_touch(z, d.localPosition));
  }

  /// A bare hand on him: deadly.
  Future<void> _touch(BodyZone z, Offset at) async {
    final m = _run.touch(z);
    if (m == null) return;
    setState(() => _reach = _Reach(at: at));
    await _deadly(m);
  }

  Future<void> _push(_Held h, BodyZone z, ShockGeo g) async {
    _hush();
    final at = _clampInto(h.at, g.zone(z), z == BodyZone.arm ? (g.backArm.contains(h.at) ? g.backArm : g.frontArm) : null);
    final m = _run.push(h.object, z);
    if (m != null && m.deadly) {
      setState(() => _reach = _Reach(at: at, object: h.object, slot: h.slot));
      await _deadly(m);
      return;
    }
    if (m != null) {
      // A slip: the thing goes back down; the scene stays.
      unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.6, muted: false));
    setState(() => _reach = _Reach(at: at, object: h.object, slot: h.slot));
    _cleared(_centre(), 20 + _secs.value);
  }

  static Offset _clampInto(Offset p, Rect zone, Rect? arm) {
    final r = arm ?? zone;
    return Offset(p.dx.clamp(r.left + 2, r.right - 2), p.dy.clamp(r.top + 2, r.bottom - 2));
  }

  /// He is free: the ◆ wait on the table, then "কেন …?".
  void _cleared(Offset origin, int amount) {
    _hush();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
    setState(() => _wake++);
    putOnTable(amount);
    final r = _run.current;
    final used = _run.used;
    final idx = _run.round;
    unawaited(askReason(
      deal: () => RescueLines.dealWhy(r.scene, used, widget.rng),
      question: used == null ? RescueLines.whySwitch : RescueLines.whyPush,
      stillValid: () => _run.round == idx && !_ended,
    ));
  }

  /// Next scene (or the result) — by itself, after the reason or the late card.
  void _next() {
    _run.next();
    if (_run.done) {
      _tick?.cancel();
      unawaited(_finish());
      return;
    }
    _arrive();
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
  void onReasonPaid() => _next();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => RescueLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    // Never in a right move's praise window or over its reason deck.
    if (tableBusy) return false;
    // He missed his scene while a later one is on: this one will do.
    if (_run.round > _callScene) _callScene = _run.round;
    if (!_run.open) {
      // His scene ended before he came: he comes on the next one (once a play).
      if (_run.round + 1 < _run.rounds.length) {
        _callScene = _run.round + 1;
        _coworkerArmed = false;
      }
      return null;
    }
    if (_intro || _busy || _card != null || reasonOpen || _held.value != null || _leverDrag) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a bare hand on his arm — the deadly touch.
      await _touch(BodyZone.arm, _geoNow().frontArm.center);
      return;
    }
    _run.caught.add(RescueLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([RescueLines.callHeld], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? RescueLines.tapWhy[_nudgeN++ % RescueLines.tapWhy.length]
            : _nudge.next(RescueLines.ask);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  /// The third small mistake: the level fails and the lesson card insists.
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _tick?.cancel();
    _hush();
    _clock.stop();
    _beats.stop();
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
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('rescue/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly touch: the trainee's hand (or the wet / metal thing) is on him,
  /// the scene freezes grey and the current runs through the helper in colour;
  /// then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _tick?.cancel();
    _clock.stop();
    _beats.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
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
    final speak = await SpokenOnce.first('rescue/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? RescueLines.deadlyWord : RescueLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        if (_run.cleared) {
          // The time ran out on this scene: the next one comes.
          _next();
        } else {
          // The same scene is still to do.
          unawaited(_sayChain([RescueLines.ask]));
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
    _beats.stop();
    final ms = _playMs;
    final save = ref.read(gameSaveProvider.notifier);
    final centre = _centre();
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && ms < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, ms);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: ms < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? RescueLines.fail : (_quickBonus ? RescueLines.quick : RescueLines.allSet),
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
  /// Where the trainee stands: at home, or stepped up so his hands reach [r].
  Rect _traineeBox(ShockGeo g, _Reach? r) {
    final home = g.traineeHome;
    if (r == null) return home;
    final hand = LinemanFigure.tipOf(LinemanMode.hold, Carry.none, ShockGeo.traineeSize);
    final reach = switch (r.object) {
      null => 0.0,
      RescueObject.chair => 34.0,
      RescueObject.ladder => 96.0,
      _ => 86.0,
    };
    final left = (r.at.dx - reach - hand.dx).clamp(4.0, ShockGeo.vx - 40 - hand.dx);
    return Rect.fromLTWH(left, home.top, home.width, home.height);
  }

  LinemanMode get _mode {
    if (_reach != null) return LinemanMode.hold;
    if (_run.cleared && _run.used == null && !_run.late) return LinemanMode.point;
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    return LinemanMode.idle;
  }

  /// The current's path in the deadly picture: the wire, through him, through the helper, to the ground.
  (List<Offset>, List<Offset>) _zapPath(ShockGeo g, Rect box, _Reach r) {
    final hand = box.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, box.size);
    final chest = Offset(box.center.dx, box.top + box.height * 0.38);
    final feet = Offset(box.center.dx, box.bottom - 2);
    return (
      [g.grip, g.chest, r.at, hand, chest, feet],
      [g.chest, chest],
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final g = ShockGeo.forScene(m.height, m.inset);
    final r = _run.current;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final reach = _reach;
    final box = _traineeBox(g, reach);
    final hand = box.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, box.size);
    final state = !_run.cleared || _run.late
        ? VictimState.stuck
        : (_run.used == null ? VictimState.slumped : VictimState.pushed);
    // Stuck (also while the freeze shows the touch).
    final victim = _freeze ? VictimState.stuck : state;
    return [
      Positioned.fill(
        key: ValueKey('place-${_run.round}'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(child: CustomPaint(painter: ShockPlacePainter(scene: r.scene, geo: g))),
        ),
      ),
      if (r.scene.switchNear)
        Positioned.fromRect(
          key: const ValueKey('switch-art'),
          rect: g.switchRect,
          child: ColorFiltered(
            colorFilter: grey,
            child: ValueListenableBuilder<double>(
              valueListenable: _lever,
              builder: (_, v, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: v),
                duration: Duration(milliseconds: quiet || _leverDrag ? 0 : 160),
                builder: (_, vv, _) => CustomPaint(painter: ShockSwitchPainter(v: vv, steel: r.scene == ShockScene.pump)),
              ),
            ),
          ),
        ),
      // The things on the floor.
      Positioned.fill(
        key: ValueKey('floor-${_run.round}'),
        child: ColorFiltered(
          colorFilter: grey,
          child: ValueListenableBuilder<_Held?>(
            valueListenable: _held,
            builder: (_, h, _) => CustomPaint(
              painter: ShockFloorPainter(
                objects: r.objects,
                geo: g,
                hidden: {?h?.slot, if (reach?.slot != null && !(_card != null && _cardTone == MistakeTone.slip)) reach!.slot!},
              ),
            ),
          ),
        ),
      ),
      // The colleague and the wire.
      Positioned.fill(
        key: const ValueKey('victim'),
        child: ColorFiltered(
          colorFilter: grey,
          child: AwakeClock(
            wake: _wake,
            quiet: quiet || state != VictimState.stuck || _freeze,
            awake: const Duration(milliseconds: 3200),
            builder: (_, t) => CustomPaint(painter: ShockVictimPainter(scene: r.scene, geo: g, state: victim, t: t)),
          ),
        ),
      ),
      // The trainee (steps up to push).
      AnimatedPositioned(
        key: const ValueKey('trainee'),
        duration: Duration(milliseconds: quiet ? 1 : 320),
        curve: Curves.easeOutCubic,
        left: box.left,
        top: box.top,
        width: box.width,
        height: box.height,
        child: ColorFiltered(
          colorFilter: grey,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, point: 2.6, wake: _wake, quiet: quiet),
        ),
      ),
      // What his hands push with.
      if (reach != null && reach.object != null && !(_card != null && _cardTone == MistakeTone.slip))
        Positioned.fill(
          key: ValueKey('pushing-${_run.round}'),
          child: IgnorePointer(
            child: ColorFiltered(
              colorFilter: grey,
              child: CustomPaint(painter: RescueObjectPainter(object: reach.object!, a: hand - (reach.at - hand) / math.max(1.0, (reach.at - hand).distance) * 14, b: reach.at)),
            ),
          ),
        ),
      // Invisible marks for the hands (and tests): the slots and his body.
      for (var i = 0; i < r.objects.length; i++)
        Positioned.fromRect(key: ValueKey('slot-$i'), rect: g.slot(i), child: const IgnorePointer(child: SizedBox.expand())),
      for (final z in BodyZone.values)
        Positioned.fromRect(key: ValueKey('zone-${z.name}'), rect: g.zone(z), child: const IgnorePointer(child: SizedBox.expand())),
      // The hands: pick up a thing and drag it onto him; a tap on him is a touch.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: RescueLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: _tapScene,
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: _panEnd,
            onPanCancel: () => _panEnd(null),
          ),
        ),
      ),
      // The switch: pull the lever down.
      if (r.scene.switchNear)
        Positioned.fromRect(
          key: const ValueKey('switch'),
          rect: g.switchRect.inflate(6),
          child: Semantics(
            button: true,
            label: RescueLines.switchLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: _leverStart,
              onVerticalDragUpdate: (d) => _leverMove(d, g.switchRect.height),
              onVerticalDragEnd: (d) => _leverEnd(_centre()),
              onVerticalDragCancel: () => _leverEnd(_centre()),
            ),
          ),
        ),
      // The thing in the hands, under the finger.
      Positioned.fill(
        key: const ValueKey('held'),
        child: IgnorePointer(
          child: ValueListenableBuilder<_Held?>(
            valueListenable: _held,
            builder: (_, h, _) => h == null
                ? const SizedBox.shrink()
                : CustomPaint(painter: RescueObjectPainter(object: h.object, a: h.at + const Offset(-58, 34), b: h.at)),
          ),
        ),
      ),
      // The deadly touch: the current through the helper, in colour.
      if (_freeze && reach != null)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 1400),
              builder: (_, t, _) {
                final (path, halos) = _zapPath(g, box, reach);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: ShockZapPainter(t: t, path: path, halos: halos)),
                    // The thing that carried it stays clear to see, over the glow.
                    if (reach.object != null) CustomPaint(painter: RescueObjectPainter(object: reach.object!, a: hand, b: reach.at)),
                  ],
                );
              },
            ),
          ),
        ),
      // A new scene comes in from dark.
      Positioned.fill(
        key: ValueKey('arrive-${_run.round}'),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet || _run.round == 0 ? 0 : 1, end: 0),
            duration: const Duration(milliseconds: 420),
            builder: (_, v, _) => v <= 0 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _syncBeats();
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
            progress: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DoProgress(
                  labels: RescueLines.rounds,
                  done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
                  current: _run.done ? null : _run.round,
                  quiet: quiet,
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<int>(
                  valueListenable: _secs,
                  builder: (_, s, _) => _Countdown(secs: s, total: widget.pack.seconds, stopped: !_run.open || _intro),
                ),
              ],
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: _waitingForHands,
            hintKey: '${_run.round}-${_run.slips}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 132), quiet: quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 12), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.round}-${_run.slips}'),
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
                  line: RescueLines.intro,
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
                                ms: _playMs,
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

/// The whole-second countdown under the round dots.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.secs, required this.total, required this.stopped});
  final int secs;
  final int total;
  final bool stopped;

  @override
  Widget build(BuildContext context) {
    final urgent = secs <= 5 && !stopped;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? SlmColors.danger : const Color(0x99091329),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: urgent ? const Color(0xFFFFB4AB) : SlmColors.gold400.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 15, color: SlmColors.ivory),
          const SizedBox(width: 4),
          Text(RescueLines.secs(secs), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ],
      ),
    );
  }
}
