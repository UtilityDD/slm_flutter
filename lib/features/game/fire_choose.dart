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
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'fire_fx.dart';
import 'fire_world.dart';
import 'full_scene_frame.dart';
import 'level_frame.dart';
import 'level_juice.dart';
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart';
import 'spoken_once.dart';

// Lesson 1.8, কাজ 1: "কোন আগুনে কী". Three fires in the substation yard, in
// random order: burning transformer oil (Class B), a live feeder panel (an
// electrical fire: by IS 2190 a Class A/B hazard on energised equipment),
// dry grass under a pole (Class A). On the panel the isolator shows ON:
// switch it OFF first (grabbing a tool while it is ON is a slip, and it must
// still be switched off). Then the tool — water bucket, ABC powder, CO2,
// sand bucket: oil → ABC / CO2 / sand; electrical → CO2 / ABC; grass → ABC /
// water (IS 2190 cl. 10.1: Class A → water, foam, ABC powder; CO2 is not for
// Class A). Pick up an extinguisher and read its gauge: one per play is
// empty (needle in the red). Once per play, at a random fire, the careless
// coworker (level 1's rival, his art and his recorded voice) peeks in from
// the left or right edge: "এরকম কত দেখেছি! কিছুই হবে না — আপনিই নিভে যাবে।"
// Act now (a button, or just take a tool / pull the switch) or listen (a
// slip).
//
// Flow (as level 1): the mentor first, full screen — the fire and "now!";
// then the scene. He stays in the bottom-right corner with short lines (the
// next task only, no hints). A fire put out leaves its ◆ on the table; "কেন
// এটা নিলেন?" — the right reason pays it, a wrong one burns it (a right
// retry still pays 5); then on to the next fire by itself.
//
// Deadly (owner-approved list): water on an oil or electrical fire. Slips:
// the wrong tool otherwise; skipping power-off on the panel; using an empty
// extinguisher; putting back a full one (a needless stop, audit 2026-11-11);
// letting a small fire be (listening to the coworker).
//
// Kit (2026-11-11): no scene control works in a praise window (`tableBusy`);
// a tool tap on the push fire waits for the coworker (`holdForCoworker`), so a
// fast play cannot skip him; a gesture hint shows how to touch in every
// waiting state (a sweep over the tools / switch / gauge buttons, a hold on
// the squeeze) — never which one.
//
// The scene is a place (fire_world.dart, scene_kit.dart): a substation yard
// the camera pans along — sky, far village (parallax), fence, gantry,
// transformer, feeder panel, pole. The senior mentor stands in front and
// speaks (bubble = the guide's lines); the trainee (the player) takes tools
// from the fire point and does the work. Hands-on: a right extinguisher
// (after the gauge) is held down to spray at the base until the fire is
// gone; sand and water are thrown. Water on oil or the panel: the fire leaps
// up (in colour, over the frozen grey scene). Scoring is unchanged.
//
// Voice: device TTS only. Art: assets/game/art/fire/ (hand-made SVG, no text
// inside); transformer, panel and tools drawn in code; fire, smoke, sprays,
// throws, bloom and flare-up are Lottie (assets/game/anim/, fire_fx.dart).

// ============================================================================
// Content
// ============================================================================

enum FireKind { oil, electrical, grass }

enum FireTool { water, dcp, co2, sand }

extension FireToolFacts on FireTool {
  bool get extinguisher => this == FireTool.dcp || this == FireTool.co2;
  bool fits(FireKind k) => switch (k) {
        FireKind.oil => this != FireTool.water,
        FireKind.electrical => this == FireTool.co2 || this == FireTool.dcp,
        FireKind.grass => this == FireTool.dcp || this == FireTool.water,
      };
}

@immutable
class FireDeal {
  const FireDeal({required this.fires, required this.empty, required this.pushRound, required this.tools});
  final List<FireKind> fires;

  /// The extinguisher whose gauge is in the red this play.
  final FireTool empty;
  final int pushRound;

  /// Tray order.
  final List<FireTool> tools;
}

FireDeal dealFires(math.Random rng) => FireDeal(
      fires: [...FireKind.values]..shuffle(rng),
      empty: rng.nextBool() ? FireTool.dcp : FireTool.co2,
      pushRound: rng.nextInt(3),
      tools: [...FireTool.values]..shuffle(rng),
    );

abstract final class FireLines {
  static const title = 'কোন আগুনে কী';
  static const intro = 'আগুন চিনুন, তারপর অস্ত্র — ভুল অস্ত্রে আগুন বাড়ে।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static String scene(FireKind k) => switch (k) {
        FireKind.oil => 'ট্রান্সফরমারের তেলে আগুন',
        FireKind.electrical => 'প্যানেলে স্পার্ক, আগুন',
        FireKind.grass => 'পোলের নিচে শুকনো ঘাসে আগুন',
      };
  static const askPower = 'জলদি! কী করবেন?';
  static String alarmFirst(FireKind k) => switch (k) {
        FireKind.oil => 'সাবস্টেশনে আগুন! ট্রান্সফরমারের তেল জ্বলছে — এখনই নেভান!',
        FireKind.electrical => 'সাবস্টেশনে আগুন! প্যানেলে আগুন লেগেছে — এখনই ব্যবস্থা নিন!',
        FireKind.grass => 'সাবস্টেশনে আগুন! পোলের নিচে শুকনো ঘাস জ্বলছে — এখনই নেভান!',
      };
  static String alarm(FireKind k) => switch (k) {
        FireKind.oil => 'ট্রান্সফরমারের তেলে আগুন! জলদি!',
        FireKind.electrical => 'প্যানেলে আগুন! জলদি!',
        FireKind.grass => 'পোলের নিচে ঘাসে আগুন! জলদি!',
      };
  static const switchLabel = 'পাওয়ার সুইচ';
  static const whyTool = 'কেন এটা নিলেন?';
  static const whySwitch = 'কেন আগে সুইচ বন্ধ করলেন?';

  // Option libraries: each choice deals one right and two wrong at random,
  // so plays don't repeat; all options about the same length (no guessing
  // by length). Reasons follow the lesson's mistake texts and IS 2190
  // (Class A: cooling by water / ABC powder; Class B: blanketing).
  static const whyOilRight = [
    'তেল জলে ভাসে, তাই আগুন ছড়ায়',
    'তেলের আগুনে জল দিলে আগুন বাড়ে',
    'তেলের আগুন ঢেকে নেভাতে হয়',
  ];
  static const whyOilSand = ['বালি তেলের আগুনকে ঢেকে দেয়'];
  static const whyOilWrong = [
    'যত বেশি জল, তত তাড়াতাড়ি নেভে',
    'হাতের কাছে এটাই পড়ে ছিল বলে',
    'তেলের আগুন নিজে থেকেই নিভে যায়',
    'জল আর বালি আসলে একই কাজ করে',
    'ট্রান্সফরমারে জলই সবচেয়ে ভালো',
    'ঢেকে দিলে তেলের আগুন আরও জ্বলে',
  ];
  static const whySwitchRight = [
    'পাওয়ার বন্ধ হলে শকের ভয় থাকে না',
    'বিদ্যুৎ বন্ধ হলে সাধারণ আগুন হয়',
    'লাইভ প্যানেলে নেভাতে গেলে শক লাগে',
  ];
  static const whySwitchWrong = [
    'পাওয়ার বন্ধ করা নেহাতই ঐচ্ছিক কাজ',
    'আলো নিভলে আগুন ভালো দেখা যায়',
    'সুইচ বন্ধ করলেই আগুন নিভে যায়',
    'বিদ্যুৎ থাকলে আগুন তাড়াতাড়ি নেভে',
    'নিয়ম আছে বলে, কারণ কিছু নেই',
    'প্যানেলের আগুনে শকের ভয় থাকে না',
  ];
  static const whyGrassWater = [
    'ঘাস-কাঠের আগুন জল ঠান্ডা করে নেভায়',
    'শুকনো ঘাসের আগুনে জলই ঠিক কাজ করে',
  ];
  static const whyGrassAbc = [
    'ABC পাউডার ঘাস-কাঠের আগুনেও চলে',
    'গায়ে ABC লেখা — ঘাসের আগুনে চলে',
  ];
  static const whyGrassWrong = [
    'ছোট ঘাসের আগুন নিজেই নিভে যায়',
    'ঘাসের আগুনে শুধু CO2 দিলেই হয়',
    'পোলের নিচের আগুনে কিছু করার নেই',
    'ঘাস পুড়লে ক্ষতি নেই, ছেড়ে দিই',
    'যে কোনো পাউডারেই ঘাসের আগুন নেভে',
    'ABC পাউডার শুধু তেলের আগুনে চলে',
    'জল দিলে ঘাসের আগুন আরও ছড়ায়',
    'ঘাস-কাঠের আগুনে CO2-ই সবচেয়ে ভালো',
  ];

  /// Right reasons for this fire (and the tool used on it).
  static List<String> whyRight(FireKind k, FireTool? used) => switch (k) {
        FireKind.oil => [...whyOilRight, if (used == FireTool.sand) ...whyOilSand],
        FireKind.electrical => whySwitchRight,
        FireKind.grass => used == FireTool.dcp ? whyGrassAbc : whyGrassWater,
      };
  static List<String> whyWrong(FireKind k) => switch (k) {
        FireKind.oil => whyOilWrong,
        FireKind.electrical => whySwitchWrong,
        FireKind.grass => whyGrassWrong,
      };
  /// The key words of each fire's reasons — the tool just used (জল, ABC,
  /// বালি), the switch (পাওয়ার, বন্ধ) and the fire itself. None of them may
  /// stand on the dealt right card alone.
  static const whyKeys = {
    FireKind.oil: ['তেল', 'জল', 'ঢেকে', 'বালি'],
    FireKind.electrical: ['পাওয়ার', 'বিদ্যুৎ', 'বন্ধ', 'শক', 'প্যানেল'],
    FireKind.grass: ['জল', 'ABC', 'পাউডার', 'ঘাস-কাঠ'],
  };

  /// One right reason and two wrong ones, at random — but the two wrong ones
  /// always carry every key word of the right one, so the tool just used (or
  /// the switch) never points at the right card in the hand actually dealt.
  static List<ChoiceOption> whyDeal(FireKind k, FireTool? used, math.Random rng) {
    final rights = whyRight(k, used);
    final right = rights[rng.nextInt(rights.length)];
    final keys = [for (final w in whyKeys[k]!) if (right.contains(w)) w];
    final wrong = whyWrong(k);
    final pairs = [
      for (var i = 0; i < wrong.length; i++)
        for (var j = i + 1; j < wrong.length; j++)
          if (keys.every((w) => wrong[i].contains(w) || wrong[j].contains(w))) [wrong[i], wrong[j]],
    ];
    final two = pairs.isNotEmpty ? pairs[rng.nextInt(pairs.length)] : ([...wrong]..shuffle(rng)).take(2).toList();
    return [ChoiceOption(right, true), for (final t in two) ChoiceOption(t, false)]..shuffle(rng);
  }

  static const powerOff = 'নিরাপদ হলে আগে পাওয়ার বন্ধ';
  static const rushIn = 'সোজা নেভাতে যাই';
  static const askTool = 'কী দিয়ে নেভাবেন?';
  static String tool(FireTool t) => switch (t) {
        FireTool.water => 'জলের বালতি',
        FireTool.dcp => 'ABC পাউডার',
        FireTool.co2 => 'CO2',
        FireTool.sand => 'বালির বালতি',
      };
  static const gaugeTitle = 'প্রেশার গেজ দেখুন';
  static const use = 'ব্যবহার করি';
  static const other = 'অন্যটা নিই';
  static const out = 'আগুন নিভল!';
  static const squeeze = 'চেপে ধরুন';
  static String toolShort(FireTool t) => switch (t) {
        FireTool.water => 'জল',
        FireTool.dcp => 'ABC',
        FireTool.co2 => 'CO2',
        FireTool.sand => 'বালি',
      };
  static const sprayGo = 'চেপে ধরুন!';
  static const next = 'পরেরটা';
  static const finish = 'ফলাফল';
  /// The careless coworker (level 1's rival) — lines in his recorded voice.
  static const coworkerTag = 'অসাবধান লাইনম্যান';
  static const coworkerLine = 'এরকম কত দেখেছি! কিছুই হবে না — আপনিই নিভে যাবে।';
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLines = [coworkerLine, coworkerExit];
  /// After the coworker: one way to act now, two ways to listen to him.
  static const choiceRight = [
    'এখনই নেভাই — বাড়তে দেব না',
    'দাঁড়িয়ে না থেকে এখনই নেভাই',
    'ও যা-ই বলুক, আমি এখনই নেভাই',
    'বড় হওয়ার আগে এখনই নেভাই',
  ];
  /// The kit deals this deck (one right, two wrong at random), so the right
  /// cards' key words — নেভাই, এখনই — stand on every wrong card, and ছোট /
  /// দেরি / ওর কথা are on wrong cards only: no hand has a word on the right
  /// card alone.
  static const choiceWrong = [
    'ওর কথাই ঠিক — এখনই নেভাই না',
    'এখনই না, নিজে না নিভলে নেভাই',
    'ছোট আগুন — এখনই না, পরে নেভাই',
    'ধোঁয়া কমলে নেভাই, এখনই না',
    'চা খেয়ে এসে নেভাই, এখনই না',
    'এখনই না — বড় হলে তবে নেভাই',
    'একটু দেরিতে নেভাই, এখনই না',
    'সবাই বসে আছে, এখনই কেন নেভাই?',
  ];
  /// The key words of his deck (see [choiceWrong]).
  static const choiceKeys = ['নেভাই', 'এখনই', 'ছোট', 'দেরি', 'ওর কথা'];

  /// The guide puts the coworker's push to the player (a different way each time).
  static const choiceAsk = [
    'আপনি কী করবেন — ওর কথা শুনবেন?',
    'ও বলছে নিজেই নিভে যাবে। শুনবেন, না এখনই নেভাবেন?',
    'কার কথা শুনবেন — ওর, না আগুনের?',
  ];

  /// The pressure moment (shared `CoworkerMoment`).
  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: choiceRight,
    wrong: choiceWrong,
    asks: choiceAsk,
    tag: coworkerTag,
  );

  // Tap the guide: the task again, a different way each time (never the answer).
  static const tapPower = ['জলদি! কী করবেন?', 'প্যানেলে আগুন — কী করবেন?', 'চারদিকে ভালো করে দেখুন।'];
  static const tapTool = ['কী দিয়ে নেভাবেন?', 'স্ট্যান্ড থেকে ঠিক জিনিসটা নিন।', 'আগুনটা দেখুন — কোনটা কাজে লাগবে?'];
  static const tapSpray = ['চেপে ধরে রাখুন — পুরো নেভা পর্যন্ত।', 'ছাড়বেন না — চেপে ধরুন!'];
  static const tapWhy = ['কেন এটা নিলেন — কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const callHeld = 'ঠিক! ছোট থাকতেই নেভান — কয়েক মিনিটে বড় হয়।';
  static const poweredOff = 'সাবাশ! এবার নেভান।';
  static const ok = [FeedbackLine('ঠিক অস্ত্র!'), FeedbackLine('আগুন চিনেছেন।'), FeedbackLine('নিখুঁত!')];
  static const allSet = 'আগুন চেনা আর অস্ত্র বাছা — দুটোই পাকা!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — তেল আর বিদ্যুতে জল নয়।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtClass = 'আগুনের ধরন বুঝে অস্ত্র';
  static const caughtPower = 'প্যানেলে আগে পাওয়ার বন্ধ';
  static const caughtGauge = 'গেজ দেখে খালি সিলিন্ডার ধরেছেন';
  static const caughtCall = 'ছোট আগুনে দেরি নয়';
}

abstract final class FireMistakes {
  static const waterOil = DoMistake(
    key: '1.8/fire/water-oil',
    textBn: 'তেলের আগুনে জল — তেল জলে ভাসে, আগুন আরও ছড়ায়। ABC পাউডার, CO2 বা বালি।',
    art: 'assets/game/art/fire/water_no.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const waterElectric = DoMistake(
    key: '1.8/fire/water-electric',
    textBn: 'বৈদ্যুতিক আগুনে জল — জল বিদ্যুৎ টানে, শক লাগবে। আগে পাওয়ার বন্ধ, তারপর CO2 বা ABC পাউডার।',
    art: 'assets/game/art/fire/water_no.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const wrongTool = DoMistake(
    key: '1.8/fire/wrong-tool',
    textBn: 'এই আগুনে এটা ঠিক অস্ত্র নয় — তেল: ABC/CO2/বালি · বিদ্যুৎ: CO2/ABC · ঘাস-কাঠ: জল বা ABC পাউডার।',
    art: 'assets/game/art/fire/fire_class.svg',
    lessonPoint: 2,
  );
  static const noPowerOff = DoMistake(
    key: '1.8/fire/no-power-off',
    textBn: 'বৈদ্যুতিক আগুনে প্রথম কাজ — নিরাপদ হলে পাওয়ার বন্ধ। তখন আগুন সাধারণ আগুনের মতো হয়ে যায়।',
    art: 'assets/game/art/fire/water_no.svg',
    lessonPoint: 1,
  );
  static const empty = DoMistake(
    key: '1.8/fire/empty',
    textBn: 'গেজের কাঁটা লাল দাগে — চাপ নেই, কাজ করবে না। ব্যবহারের আগে দেখুন কাঁটা সবুজে আছে কিনা।',
    art: 'assets/game/art/fire/gauge.svg',
    lessonPoint: 2,
  );
  static const waited = DoMistake(
    key: '1.8/fire/waited',
    textBn: 'ছোট আগুন নিজে থেকে নেভে না — কয়েক মিনিটে বড় আগুন। ছোট থাকতেই নেভান।',
    art: 'assets/game/art/fire/fire_class.svg',
    lessonPoint: 0,
  );
  static const fullBack = DoMistake(
    key: '1.8/fire/full-back',
    textBn: 'গেজের কাঁটা সবুজে — চাপ ঠিক আছে, এটাই কাজ করত। ফেরত রাখলে দেরি হয়, আগুন বাড়ে।',
    art: 'assets/game/art/fire/gauge.svg',
    lessonPoint: 2,
  );
  static const all = [waterOil, waterElectric, wrongTool, noPowerOff, empty, waited, fullBack];
}

enum FirePhase { power, tool, gauge, out }

/// The play state (pure logic).
class FireRun {
  FireRun(this.deal);
  final FireDeal deal;
  int round = 0;
  late FirePhase phase = _startPhase;
  FireTool? held;
  final Set<FireTool> spent = {};
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => round >= deal.fires.length;
  bool get ended => done || deadly != null;
  FireKind get current => deal.fires[round.clamp(0, deal.fires.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  FirePhase get _startPhase => current == FireKind.electrical ? FirePhase.power : FirePhase.tool;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Power off first (true) or rush in.
  DoMistake? power({required bool off}) {
    if (ended || phase != FirePhase.power) return null;
    phase = FirePhase.tool;
    if (!off) {
      slips++;
      return FireMistakes.noPowerOff;
    }
    _tag(FireLines.caughtPower);
    return null;
  }

  /// A tool grabbed while the panel is still live: water is deadly, anything
  /// else a slip — and the power must still go off.
  DoMistake? grabLive(FireTool t) {
    if (ended || phase != FirePhase.power) return null;
    if (t == FireTool.water) return deadly = FireMistakes.waterElectric;
    slips++;
    return FireMistakes.noPowerOff;
  }

  DoMistake? pick(FireTool t) {
    if (ended || phase != FirePhase.tool || spent.contains(t)) return null;
    final k = current;
    if (t == FireTool.water && k != FireKind.grass) {
      return deadly = k == FireKind.oil ? FireMistakes.waterOil : FireMistakes.waterElectric;
    }
    if (!t.fits(k)) {
      slips++;
      return FireMistakes.wrongTool;
    }
    if (t.extinguisher) {
      held = t;
      phase = FirePhase.gauge;
      return null;
    }
    phase = FirePhase.out;
    _tag(FireLines.caughtClass);
    return null;
  }

  /// After reading the gauge: use it (true) or put it back. Putting back a
  /// full one (needle in the green) is a needless stop: a slip.
  DoMistake? useHeld({required bool use}) {
    final t = held;
    if (ended || phase != FirePhase.gauge || t == null) return null;
    held = null;
    final empty = t == deal.empty;
    if (!use) {
      phase = FirePhase.tool;
      if (!empty) {
        slips++;
        return FireMistakes.fullBack;
      }
      spent.add(t);
      _tag(FireLines.caughtGauge);
      return null;
    }
    if (empty) {
      spent.add(t);
      phase = FirePhase.tool;
      slips++;
      return FireMistakes.empty;
    }
    phase = FirePhase.out;
    _tag(FireLines.caughtClass);
    return null;
  }

  void next() {
    round++;
    held = null;
    if (!done) phase = _startPhase;
  }
}

@immutable
class FirePack {
  const FirePack({required this.id, required this.titleBn, this.quickMs = 50000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const firePack18 = FirePack(id: 'do_1_8_a', titleBn: FireLines.title);
const firePacks = {'do_1_8_a': firePack18};

// ============================================================================
// Page
// ============================================================================

class FireChoosePage extends StatefulWidget {
  const FireChoosePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final FirePack pack;
  final bool muted;
  final int? seed;

  @override
  State<FireChoosePage> createState() => _FireChoosePageState();
}

class _FireChoosePageState extends State<FireChoosePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FireRunPage(
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

class _FireRunPage extends ConsumerStatefulWidget {
  const _FireRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final FirePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FireRunPage> createState() => _FireRunPageState();
}

class _FireRunPageState extends ConsumerState<_FireRunPage>
    with DoDeathGuard, DoStrikeOut, SingleTickerProviderStateMixin, ReasonTable, CoworkerMoment {
  /// The camera pans from fire to fire.
  late final AnimationController _cam = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..addStatusListener((_) {
      if (mounted) setState(() {});
    });
  late double _camFrom = FireWorld.cameraFor(_run.current);
  late double _camTo = _camFrom;
  double get _camX => _camFrom + (_camTo - _camFrom) * Curves.easeInOutCubic.transform(_cam.value);

  /// Fires already put out (scorched ground).
  final Set<FireKind> _doneKinds = {};

  final _scoreKey = GlobalKey();
  late final FireRun _run = FireRun(dealFires(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);


  // The scene is laid out for the screen: a tall screen gets more sky.
  double _lift = 0;
  double _inset = 0;

  final _combo = Combo();
  int _comboN = 0;
  int _comboMult = 1;
  int? _stars;

  /// Bumped on every move: the fire and smoke move for a few seconds after.
  int _wake = 0;

  /// How much of this round's fire is left (1 → 0); sizes the flames.
  final _fire = ValueNotifier<double>(1);

  /// A right extinguisher in hand: hold to spray until the fire is gone.
  FireTool? _spraying;
  var _holding = false;
  Timer? _sprayTick;
  Offset _sprayFrom = Offset.zero;

  /// Sand or water in the air.
  FireTool? _throwing;

  /// The empty extinguisher coughs.
  FireTool? _puff;

  bool get _isOut => _run.phase == FirePhase.out && _spraying == null && _throwing == null;

  /// A deadly move: the scene freezes in grey while the consequence plays.
  var _freeze = false;
  Completer<void>? _frozen;

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

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;

  /// The tool that put this fire out (the right reason fits it).
  FireTool? _usedTool;
  int _tapN = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int _totalDelta = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    disposeCoworker();
    _sprayTick?.cancel();
    _fire.dispose();
    _cam.dispose();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk, bool other = false}) async {
    if (line.trim().isEmpty || !mounted) return;
    if (!other) ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted, rival: other);
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

  /// After the guide's intro: the clock runs and play begins.
  Future<void> _start() async {
    _clock.start();
    setState(() => _wake++);
    _scheduleCoworker();
    unawaited(_sayChain([_ask]));
  }

  String get _ask => _run.phase == FirePhase.power ? FireLines.askPower : FireLines.askTool;

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
  CoworkerScript get coworkerScript => FireLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("it will go out by itself") fits only while this fire burns.
    if (_ended || _run.ended || _run.round != _run.deal.pushRound) return null;
    final ph = _run.phase;
    if (ph == FirePhase.out || _spraying != null || _throwing != null) return null;
    if (_card != null || _busy || _intro || _freeze || tableBusy || ph == FirePhase.gauge) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();
  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      _run.slips++;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(FireMistakes.waited);
      return;
    }
    _run.caught.add(FireLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([FireLines.callHeld, _ask], mood: GuideMood.glad);
    }());
  }

  /// On the push fire, the coworker turns up a moment after it is seen.
  void _scheduleCoworker() {
    if (_run.round == _run.deal.pushRound) scheduleCoworker();
  }

  /// Tap the guide: he says the task on screen again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended || _card != null) return;
    final ways = coworkerOpen
        ? FireLines.choiceAsk
        : reasonOpen
            ? FireLines.tapWhy
            : _spraying != null
                ? FireLines.tapSpray
                : switch (_run.phase) {
                    FirePhase.power => FireLines.tapPower,
                    FirePhase.tool || FirePhase.gauge => FireLines.tapTool,
                    FirePhase.out => const <String>[],
                  };
    if (ways.isEmpty) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([ways[_tapN++ % ways.length]]));
  }

  /// The scene takes a move now: never in a praise window (`tableBusy`), a
  /// freeze, a card or while the coworker is on.
  bool get _idle => !_busy && !_ended && !_freeze && !_intro && !coworkerOpen && _card == null && !tableBusy;

  // --- gesture hints (how to touch, never which) ------------------------------
  final _hints = IdleHintController();
  final Map<FireTool, GlobalKey> _toolKeys = {for (final t in FireTool.values) t: GlobalKey()};
  final _switchKey = GlobalKey();
  final _squeezeKey = GlobalKey();
  final _gaugeUseKey = GlobalKey();
  final _gaugeOtherKey = GlobalKey();

  /// The level waits for the player's touch on the scene (the decks and the
  /// zoomed reason card carry their own hints).
  bool get _hintWaiting {
    if (_intro || _ended || _busy || _freeze || _card != null || coworkerOnScreen || tableBusy) return false;
    if (_cam.isAnimating || _throwing != null || _puff != null) return false;
    if (_spraying != null) return !_holding;
    return _run.phase != FirePhase.out;
  }

  /// Spraying: hold the squeeze (the one way on). The gauge: a sweep over both
  /// buttons. Otherwise a sweep over every tool left on the stand (and the
  /// switch while the panel is live) — never one of them alone.
  HintSpec? _hint() {
    if (_spraying != null) return HintSpec.holdOn(_squeezeKey);
    // The sweep order is mixed per wait (from the deal and the state, not the
    // level's rng), so a lap never always ends on the same — right — control.
    final mix = math.Random(_run.deal.tools.fold<int>(_run.deal.empty.index + 1, (a, t) => a * 5 + t.index) * 97 +
        _run.round * 31 +
        _run.phase.index * 7 +
        _run.spent.length * 3 +
        _run.slips);
    if (_run.phase == FirePhase.gauge) return HintSpec.sweepOver([_gaugeOtherKey, _gaugeUseKey]..shuffle(mix));
    final keys = [
      for (final t in _run.deal.tools)
        if (!_run.spent.contains(t) && !_taken(t)) _toolKeys[t]!,
      if (_run.phase == FirePhase.power) _switchKey,
    ]..shuffle(mix);
    return keys.length < 2 ? null : HintSpec.sweepOver(keys);
  }

  Object get _hintKey => '${_run.round}-${_run.phase.name}-${_spraying?.name}-${_run.spent.length}-${_run.slips}';

  Future<void> _power(bool off, Offset origin) async {
    if (coworkerOpen && _run.phase == FirePhase.power) await answerCoworker(true, origin, direct: true);
    if (!_idle || _run.phase != FirePhase.power) return;
    _hush();
    final m = _run.power(off: off);
    setState(() {});
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.7, muted: false));
    setState(() => _wake++);
    unawaited(_levelDelta(_scored(10), origin, mood: GuideMood.glad));
    unawaited(_sayChain([FireLines.poweredOff], mood: GuideMood.glad));
  }

  Future<void> _pick(FireTool t, Offset origin) async {
    if (coworkerOpen) await answerCoworker(true, origin, direct: true);
    if (!_idle) return;
    // On the push fire a tool would settle it before he speaks: he comes now.
    if (holdForCoworker()) return;
    _hush();
    final m = _run.phase == FirePhase.power ? _run.grabLive(t) : _run.pick(t);
    setState(() => _wake++);
    if (m != null && m.deadly) {
      // The bucket flies first; the fire answers. Nothing else moves meanwhile.
      _busy = true;
      setState(() => _throwing = FireTool.water);
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.ogg', volume: 0.5, muted: false));
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      await _after(m, origin);
      return;
    }
    if (m == null && _run.phase == FirePhase.out) {
      // Sand or water: thrown at the base; the fire dies as it lands.
      setState(() {
        _throwing = t;
        _usedTool = t;
      });
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.ogg', volume: 0.5, muted: false));
      _dropFire(origin);
      return;
    }
    await _after(m, origin);
  }

  /// The thrown load lands: the fire shrinks to nothing, then it is out.
  void _dropFire(Offset origin) {
    _sprayTick?.cancel();
    var wait = 10; // ~0.4 s in the air
    _sprayTick = Timer.periodic(const Duration(milliseconds: 42), (tm) {
      if (!mounted) return tm.cancel();
      if (wait-- > 0) return;
      _fire.value = math.max(0, _fire.value - 0.06);
      if (_fire.value <= 0) {
        tm.cancel();
        _outNow(origin);
      }
    });
  }

  /// Held down on the squeeze: spray (the fire shrinks while held).
  void _hold(bool down, [Offset? at]) {
    if (_spraying == null || _ended) return;
    if (down == _holding) return;
    _sprayTick?.cancel();
    setState(() {
      _holding = down;
      if (down) _wake++;
    });
    if (!down) return;
    if (at != null) _sprayFrom = at;
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_out.ogg', volume: 0.5, muted: false));
    var n = 0;
    _sprayTick = Timer.periodic(const Duration(milliseconds: 42), (tm) {
      if (!mounted) return tm.cancel();
      if (++n % 6 == 0) HapticFeedback.selectionClick();
      _fire.value = math.max(0, _fire.value - 0.028);
      if (_fire.value <= 0) {
        tm.cancel();
        _holding = false;
        _outNow(_sprayFrom);
      }
    });
  }

  /// The fire is out: the rescue moment; its ◆ wait on the table until the
  /// player says why (level 1's rule — shared `ReasonTable`).
  void _outNow(Offset origin) {
    if (!mounted) return;
    final pend = _scored(15);
    setState(() {
      _spraying = null;
      _throwing = null;
      _holding = false;
      _wake++;
    });
    putOnTable(pend);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.7, muted: false));
    final round = _run.round;
    final k = _run.current;
    unawaited(askReason(
      deal: () => FireLines.whyDeal(k, _usedTool, widget.rng),
      question: k == FireKind.electrical ? FireLines.whySwitch : FireLines.whyTool,
      stillValid: () => _run.round == round,
    ));
  }

  Future<void> _useHeld(bool use, Offset origin) async {
    if (!_idle) return;
    _hush();
    final tool = _run.held;
    final m = _run.useHeld(use: use);
    setState(() => _wake++);
    if (!use && m == null) return;
    if (m == FireMistakes.empty) {
      // Squeeze: a weak cough of powder, nothing more.
      setState(() => _puff = tool);
      _busy = true;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _busy = false;
      setState(() => _puff = null);
    }
    if (m == null && _run.phase == FirePhase.out && tool != null) {
      setState(() {
        _spraying = tool;
        _usedTool = tool;
      });
      _sprayFrom = origin;
      unawaited(_sayChain([FireLines.sprayGo]));
      return;
    }
    await _after(m, origin);
  }

  Future<void> _after(DoMistake? m, Offset origin) async {
    if (m == null) {
      if (_run.phase == FirePhase.out) _outNow(origin);
      return;
    }
    if (m.deadly) {
      await _deadly(m);
    } else {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
    }
  }

  /// On to the next fire by itself (after the reason is paid).
  void _next() {
    if (!_idle || !_isOut) return;
    _doneKinds.add(_run.current);
    _run.next();
    _fire.value = 1;
    _wake++;
    reasonOpen = false;
    if (_run.done) {
      setState(() {});
      unawaited(_finish());
      return;
    }
    // Walk on to the next fire.
    _camFrom = _camX;
    _camTo = FireWorld.cameraFor(_run.current);
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    setState(() {});
    if (quiet) {
      _cam.value = 1;
      _arrive();
    } else {
      unawaited(_cam.forward(from: 0).then((_) => _arrive()));
    }
  }

  /// At the next fire: the alarm, what burns and "now" — or the push call.
  void _arrive() {
    if (!mounted || _ended) return;
    setState(() => _wake++);
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/fire_alarm.ogg', volume: 0.5, muted: false));
    _scheduleCoworker();
    unawaited(_sayChain([FireLines.alarm(_run.current), _ask], mood: GuideMood.warn));
  }

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

  Future<void> _slip(DoMistake m) async {
    _combo.miss();
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('fire/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.ogg', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    await frozen.future;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('fire/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? FireLines.deadlyWord : FireLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        unawaited(_sayChain([_ask]));
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
    _stars = stars;
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? FireLines.fail : (_quickBonus ? FireLines.quick : FireLines.allSet),
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

  /// World → scene pixels (the yard sits [_lift] lower on a tall screen).
  Offset _view(Offset world) => Offset(world.dx - _camX, world.dy + _lift);

  /// This fire's base on screen and its size.
  (Offset, double) _fireOnScreen(FireKind k) {
    final (b, sz) = FireWorld.fireAt(k);
    return (_view(b), sz);
  }

  /// Places a [w]x[h] animation so its own point [own] sits on this fire's
  /// base (moved by [shift]), scaled by the fire's size times [scale].
  Widget _at(FireKind k, double w, double h, Offset own, double scale, Widget child, {Offset shift = Offset.zero}) {
    final (b, sz) = _fireOnScreen(k);
    final sc = sz * scale;
    final p = b + shift * sz;
    return Positioned(left: p.dx - own.dx * sc, top: p.dy - own.dy * sc, width: w * sc, height: h * sc, child: child);
  }

  Rect get _traineeBox => Rect.fromLTWH(64, 206 + _lift, 72, 144);

  Carry _carryOf(FireTool t) => switch (t) {
        FireTool.water => Carry.water,
        FireTool.sand => Carry.sand,
        FireTool.dcp => Carry.dcp,
        FireTool.co2 => Carry.co2,
      };

  (LinemanMode, Carry) get _trainee {
    if (_cam.isAnimating) return (LinemanMode.walk, Carry.none);
    final th = _throwing;
    if (th != null) return (LinemanMode.throwIt, _carryOf(th));
    final sp = _spraying;
    if (sp != null) return (_holding ? LinemanMode.spray : LinemanMode.hold, _carryOf(sp));
    final pf = _puff;
    if (pf != null) return (LinemanMode.spray, _carryOf(pf));
    final held = _run.held;
    if (_run.phase == FirePhase.gauge && held != null) return (LinemanMode.hold, _carryOf(held));
    if (_freeze || (_card != null && _cardTone == MistakeTone.slip)) return (LinemanMode.worried, Carry.none);
    if (_isOut && !_ended) return (LinemanMode.cheer, Carry.none);
    return (LinemanMode.idle, Carry.none);
  }

  bool _taken(FireTool t) => _run.held == t || _spraying == t || _throwing == t || _puff == t;

  /// The isolator lever is up (ON) until the panel's power is switched off.
  bool get _isolatorOn =>
      !_doneKinds.contains(FireKind.electrical) && !(_run.current == FireKind.electrical && _run.phase != FirePhase.power);

  List<Widget> _scene(FireKind k, FirePhase phase, bool quiet) {
    final (base, size) = _fireOnScreen(k);
    // Aim at the near edge of the fire's base.
    final aim = base.translate(-40 * size, -6);
    final paused = _card != null || _ended || coworkerOpen || _intro;
    final burning = !_isOut;
    final zoom = 1 + 0.05 * math.sin(math.pi * _cam.value);
    final (tMode, tCarry) = _trainee;
    final tb = _traineeBox;
    final tip = tb.topLeft + LinemanFigure.tipOf(tMode == LinemanMode.throwIt ? LinemanMode.throwIt : LinemanMode.spray, tCarry, tb.size);
    final iso = _view(FireWorld.isolator);
    return [
      // The world, behind everything (it leans in a touch while the camera travels).
      Positioned.fill(
        child: Transform.scale(
          scale: zoom,
          child: Stack(
            children: [
              Positioned.fill(
                child: AwakeClock(
                  wake: _wake,
                  quiet: quiet || paused,
                  builder: (_, t) => ValueListenableBuilder<double>(
                    valueListenable: t,
                    builder: (_, v, _) => CustomPaint(
                      painter: FireWorldPainter(
                        camX: _camX,
                        t: v,
                        burning: burning ? k : null,
                        done: {..._doneKinds, if (!burning) k},
                        powerOn: _isolatorOn,
                        lift: _lift,
                      ),
                    ),
                  ),
                ),
              ),
              // The isolator: ON until the player pulls it down.
              Positioned(
                left: iso.dx - 42,
                top: iso.dy - 50,
                width: 84,
                height: 106,
                child: _IsolatorSwitch(
                  key: _switchKey,
                  on: _isolatorOn,
                  // Not while his choice deck is up (the tool stand is hidden then too).
                  live: k == FireKind.electrical && phase == FirePhase.power && !_intro && !coworkerChoiceUp,
                  quiet: quiet,
                  onOff: (o) => unawaited(_power(true, o)),
                ),
              ),
              // Smoke above the fire (thick while it burns, a thin wisp after).
              _at(
                k,
                320,
                210,
                const Offset(160, 150),
                1.1,
                ValueListenableBuilder<double>(
                  valueListenable: _fire,
                  builder: (_, v, child) => Opacity(opacity: burning ? 0.25 + 0.55 * v : 0.35, child: child),
                  child: FxLoop(FireAnim.smoke, key: ValueKey('smoke-${_run.round}'), wake: _wake, paused: paused, quiet: quiet),
                ),
                shift: const Offset(0, -70),
              ),
              if (burning && !_cam.isAnimating)
                _at(
                  k,
                  320,
                  210,
                  const Offset(160, 192),
                  1,
                  ValueListenableBuilder<double>(
                    valueListenable: _fire,
                    builder: (_, v, child) => Opacity(
                      opacity: (v / 0.15).clamp(0.0, 1.0),
                      child: Transform(
                        alignment: const Alignment(0, 0.83),
                        transform: Matrix4.diagonal3Values(0.55 + 0.45 * v, 0.2 + 0.8 * v, 1),
                        child: child,
                      ),
                    ),
                    child: FxLoop(FireAnim.fire, key: ValueKey('flames-${_run.round}'), wake: _wake, paused: paused, quiet: quiet),
                  ),
                ),
              if (_isOut && !_freeze && !_cam.isAnimating) ...[
                _at(k, 320, 240, const Offset(160, 130), 1.2, FxOnce(FireAnim.bloom, key: ValueKey('bloom-${_run.round}'), ms: 1700, quiet: quiet)),
                Positioned.fromRect(
                  rect: Rect.fromCenter(center: base.translate(0, -30), width: 300, height: 220),
                  child: RescueBurst(key: ValueKey('rescue-${_run.round}'), muted: _muted, cloud: false),
                ),
              ],
            ],
          ),
        ),
      ),
      // The trainee does the work.
      Positioned.fromRect(
        rect: tb,
        child: LinemanFigure(look: LinemanLook.trainee, mode: tMode, carry: tCarry, wake: _wake, quiet: quiet),
      ),
      // The jet while squeezed, the empty cough, the thrown load.
      if (_spraying != null && _holding)
        FxBeam(
          a: tip,
          b: aim,
          thick: 1.8,
          child: FxLoop(_spraying == FireTool.co2 ? FireAnim.sprayCo2 : FireAnim.sprayDcp, wake: _wake, quiet: quiet, still: 0.5),
        ),
      if (_puff != null) FxBeam(a: tip, b: aim, thick: 1.8, child: FxOnce(FireAnim.weak, ms: 800, quiet: quiet)),
      if (_throwing != null)
        FxBeam(
          a: tip,
          b: base.translate(-20 * size, -4),
          from: const Offset(20, 100),
          to: const Offset(250, 100),
          thick: 1.3,
          child: FxOnce(_throwing == FireTool.sand ? FireAnim.sand : FireAnim.water,
              key: ValueKey('throw-${_run.round}-$_throwing'), ms: 1100, quiet: quiet),
        ),
    ];
  }

  /// What sits on the scene's bottom edge: the tools, the squeeze, the reason
  /// cards, the ◆ on the table, and the guide (the app's mascot) in the corner.
  List<Widget> _hud(FireKind k, FirePhase phase, bool quiet) {
    final b = _inset;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final rackOn = !_intro && !deckUp && (phase == FirePhase.power || phase == FirePhase.tool || phase == FirePhase.gauge);
    final squeezeOn = _spraying != null;
    final (base, _) = _fireOnScreen(k);
    return [
      if (rackOn) Positioned(key: const ValueKey('hud-rack'), left: 6, bottom: b + 4, width: 214, height: 92, child: _rack(phase)),
      if (squeezeOn)
        Positioned(
            key: const ValueKey('hud-squeeze'),
            left: 14,
            right: 128,
            bottom: b + 12,
            height: 62,
            child: _SqueezeButton(key: _squeezeKey, holding: _holding, onHold: (down, at) => _hold(down, at))),
      // The fire's ◆ waiting on the table (or burning away).
      ...tableLayers(at: base.translate(0, -132), quiet: quiet),
      // The answers: one deck, level 1's cards — the coworker choice or the reason.
      if (deckUp)
        Positioned(
          key: const ValueKey('hud-deck'),
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: b),
            child: reasonOpen
                ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-${_run.round}'))
                : coworkerDeck(quiet: quiet, key: ValueKey('choice-deck-${_run.round}')),
          ),
        ),
      // The guide in the corner (opposite the coworker; above the deck).
      if (!_intro) cornerGuide(onTap: _tapGuide, bottom: b + (deckUp ? 236 : 2), onLeft: coworkerFromRight),
    ];
  }

  /// The red fire-point stand with the four tools (pictures, short names).
  Widget _rack(FirePhase phase) {
    final canPick = phase == FirePhase.tool || phase == FirePhase.power;
    return CustomPaint(
      painter: const _StandPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Row(
          children: [
            for (final t in _run.deal.tools)
              Expanded(
                key: _toolKeys[t],
                child: Semantics(
                  button: true,
                  label: FireLines.tool(t),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: canPick && !_run.spent.contains(t) && !_taken(t) ? (d) => unawaited(_pick(t, d.globalPosition)) : null,
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            painter: RackToolPainter(tool: t, taken: _taken(t), spent: _run.spent.contains(t)),
                            size: Size.infinite,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2, bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xD9091329), borderRadius: BorderRadius.circular(6)),
                          child: Text(FireLines.toolShort(t),
                              maxLines: 1, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFFF5F7FA))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final k = _run.current;
    final phase = _run.phase;
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
            animation: _cam,
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            hintAutoMiss: true,
            progress: DoProgress(
              labels: FireLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) {
              _lift = m.lift;
              _inset = m.inset;
              return [
                Positioned.fill(
                  key: const ValueKey('scene'),
                  child: ColorFiltered(
                    colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                    child: Stack(children: _scene(k, phase, quiet)),
                  ),
                ),
                // What would have happened — in colour over the frozen scene.
                if (_freeze) KeyedSubtree(key: const ValueKey('flare'), child: _flare(k, quiet)),
                ..._hud(k, phase, quiet),
              ];
            },
            overlays: [
              if (phase == FirePhase.gauge && _run.held != null)
                _GaugeCard(
                  key: ValueKey('gauge-${_run.held}'),
                  tool: _run.held!,
                  empty: _run.held == _run.deal.empty,
                  quiet: quiet,
                  useKey: _gaugeUseKey,
                  otherKey: _gaugeOtherKey,
                  onUse: (use, o) => unawaited(_useHeld(use, o)),
                ),
              ?coworkerPeek(quiet: quiet, key: ValueKey('coworker-${_run.round}')),
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
                          unawaited(openLessonPoint(context, ref,
                              lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.fire,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_comboN > 0)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 92,
                  left: 0,
                  right: 0,
                  child: Center(child: ComboPop(key: ValueKey('combo-$_comboN'), mult: _comboMult)),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2200,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  line: FireLines.alarmFirst(k),
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
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
                                onRead: () => unawaited(openLessonPoint(context, ref,
                                    lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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

  /// The flare-up over the frozen scene (water on oil / the live panel).
  Widget _flare(FireKind k, bool quiet) => Stack(children: [_at(k, 320, 360, const Offset(160, 356), 1.15, FxOnce(FireAnim.flare, ms: 2000, quiet: quiet))]);
}

// ============================================================================
// Pieces
// ============================================================================

/// The picked-up extinguisher's pressure gauge: green = ready, red = empty.
class _GaugeCard extends StatelessWidget {
  const _GaugeCard({super.key, required this.tool, required this.empty, required this.quiet, required this.onUse, this.useKey, this.otherKey});
  final FireTool tool;
  final bool empty;
  final bool quiet;

  /// The two buttons (the gesture hint sweeps over both).
  final GlobalKey? useKey;
  final GlobalKey? otherKey;
  final void Function(bool use, Offset origin) onUse;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.scale(scale: 0.9 + 0.1 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(22)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${FireLines.tool(tool)} · ${FireLines.gaugeTitle}',
                      style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ink)),
                  const SizedBox(height: 10),
                  SizedBox(width: 170, height: 120, child: CustomPaint(painter: _GaugePainter(empty: empty))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: DoBigButton(key: otherKey, label: FireLines.other, filled: false, onTapUp: (d) => onUse(false, d.globalPosition))),
                      const SizedBox(width: 10),
                      Expanded(child: DoBigButton(key: useKey, label: FireLines.use, filled: true, onTapUp: (d) => onUse(true, d.globalPosition))),
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

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.empty});
  final bool empty;

  @override
  void paint(Canvas c, Size s) {
    // A half dial that fits its box.
    final r = math.min(s.width * 0.42, s.height * 0.78);
    final centre = Offset(s.width / 2, s.height * 0.92);
    final face = Rect.fromCircle(center: centre, radius: r + 8);
    c.drawArc(face, math.pi, math.pi, true, Paint()..color = Colors.white);
    c.drawArc(
      face,
      math.pi,
      math.pi,
      true,
      Paint()
        ..color = const Color(0xFF31363C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final rect = Rect.fromCircle(center: centre, radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    c.drawArc(rect, math.pi, math.pi * 0.38, false, arc..color = const Color(0xFFC0392B));
    c.drawArc(rect, math.pi * 1.38, math.pi * 0.24, false, arc..color = const Color(0xFF2E8B45));
    c.drawArc(rect, math.pi * 1.62, math.pi * 0.38, false, arc..color = const Color(0xFFC0392B));
    final a = empty ? math.pi * 1.12 : math.pi * 1.5;
    c.drawLine(centre, centre + Offset(math.cos(a), math.sin(a)) * (r - 8), Paint()..color = const Color(0xFF31363C)..strokeWidth = 4..strokeCap = StrokeCap.round);
    c.drawCircle(centre, 6, Paint()..color = const Color(0xFF31363C));
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.empty != empty;
}

/// A tool picture: water bucket, DCP / CO2 extinguisher, sand bucket.
class ToolIconPainter extends CustomPainter {
  ToolIconPainter(this.tool);
  final FireTool tool;

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final h = s.height;
    switch (tool) {
      case FireTool.water:
      case FireTool.sand:
        final body = Path()
          ..moveTo(cx - h * 0.32, h * 0.25)
          ..lineTo(cx + h * 0.32, h * 0.25)
          ..lineTo(cx + h * 0.24, h * 0.95)
          ..lineTo(cx - h * 0.24, h * 0.95)
          ..close();
        c.drawPath(body, Paint()..color = tool == FireTool.water ? const Color(0xFF8D949B) : const Color(0xFFC0392B));
        c.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.25), width: h * 0.64, height: h * 0.14),
            Paint()..color = tool == FireTool.water ? const Color(0xFF5AA0D8) : const Color(0xFFD8B26A));
        c.drawArc(Rect.fromCenter(center: Offset(cx, h * 0.25), width: h * 0.7, height: h * 0.4), math.pi, math.pi, false,
            Paint()..color = const Color(0xFF3B3F45)..style = PaintingStyle.stroke..strokeWidth = 2);
      case FireTool.dcp:
      case FireTool.co2:
        final w = h * 0.3;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w / 2, h * 0.22, w, h * 0.74), Radius.circular(w * 0.4)), Paint()..color = const Color(0xFFC0392B));
        c.drawRect(Rect.fromLTWH(cx - w / 2, h * 0.45, w, h * 0.16), Paint()..color = tool == FireTool.dcp ? const Color(0xFF2F6FD0) : const Color(0xFF31363C));
        c.drawRect(Rect.fromLTWH(cx - w * 0.2, h * 0.08, w * 0.4, h * 0.16), Paint()..color = const Color(0xFF3B3F45));
        if (tool == FireTool.co2) {
          // CO2: a wide horn.
          c.drawPath(
            Path()
              ..moveTo(cx + w * 0.2, h * 0.14)
              ..lineTo(cx + w * 1.2, h * 0.24)
              ..lineTo(cx + w * 1.5, h * 0.12)
              ..lineTo(cx + w * 1.4, h * 0.36)
              ..close(),
            Paint()..color = const Color(0xFF2B2F35),
          );
        } else {
          c.drawPath(
            Path()
              ..moveTo(cx + w * 0.2, h * 0.14)
              ..quadraticBezierTo(cx + w * 1.3, h * 0.12, cx + w * 1.2, h * 0.5),
            Paint()
              ..color = const Color(0xFF2B2F35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }
    }
  }

  @override
  bool shouldRepaint(ToolIconPainter old) => old.tool != tool;
}

/// The fire scene in the yard (360 x 420): transformer with burning oil,
/// a sparking panel, or dry grass under a pole; flames are still shapes (no
/// loop); after it is out, grey smoke.
class FireScenePainter extends CustomPainter {
  FireScenePainter({required this.kind, required this.out, this.powerOff = true, this.flames = true});
  final FireKind kind;
  final bool out;

  /// Paint the still flames and smoke (off where the Lottie fire plays).
  final bool flames;

  /// The panel's power is off (no spark).
  final bool powerOff;

  static void flame(Canvas c, Offset base, double s) {
    final outer = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx - 22 * s, base.dy - 10 * s, base.dx - 18 * s, base.dy - 40 * s, base.dx - 4 * s, base.dy - 56 * s)
      ..cubicTo(base.dx - 6 * s, base.dy - 38 * s, base.dx + 8 * s, base.dy - 36 * s, base.dx + 6 * s, base.dy - 52 * s)
      ..cubicTo(base.dx + 22 * s, base.dy - 36 * s, base.dx + 24 * s, base.dy - 10 * s, base.dx, base.dy)
      ..close();
    c.drawPath(outer, Paint()..color = const Color(0xFFF05A28));
    final inner = Path()
      ..moveTo(base.dx, base.dy - 2 * s)
      ..cubicTo(base.dx - 12 * s, base.dy - 8 * s, base.dx - 10 * s, base.dy - 26 * s, base.dx - 2 * s, base.dy - 36 * s)
      ..cubicTo(base.dx, base.dy - 26 * s, base.dx + 8 * s, base.dy - 26 * s, base.dx + 6 * s, base.dy - 34 * s)
      ..cubicTo(base.dx + 14 * s, base.dy - 22 * s, base.dx + 12 * s, base.dy - 8 * s, base.dx, base.dy - 2 * s)
      ..close();
    c.drawPath(inner, Paint()..color = const Color(0xFFFFD21F));
  }

  static void smoke(Canvas c, Offset base) {
    final p = Paint()..color = const Color(0x998D949B);
    c.drawCircle(base.translate(-10, -20), 14, p);
    c.drawCircle(base.translate(8, -38), 18, p);
    c.drawCircle(base.translate(-4, -62), 22, p);
  }

  /// Where the fire's base is (for aiming).
  static Offset baseOf(FireKind k) => switch (k) {
        FireKind.oil => const Offset(200, 298),
        FireKind.electrical => const Offset(180, 250),
        FireKind.grass => const Offset(170, 300),
      };

  @override
  void paint(Canvas c, Size s) {
    switch (kind) {
      case FireKind.oil:
        // Transformer: tank, radiator fins, bushings, plinth, oil pool.
        c.drawRect(const Rect.fromLTRB(140, 286, 270, 300), Paint()..color = const Color(0xFF9D9A90));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(160, 180, 250, 286), const Radius.circular(6)), Paint()..color = const Color(0xFF7F8A84));
        final fin = Paint()..color = const Color(0xFF6B756F);
        for (var x = 254.0; x < 270; x += 5) {
          c.drawRect(Rect.fromLTWH(x, 196, 3, 80), fin);
        }
        final bush = Paint()..color = const Color(0xFFB98B54);
        for (final x in const [176.0, 205.0, 234.0]) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 5, 150, 10, 32), const Radius.circular(4)), bush);
        }
        c.drawOval(const Rect.fromLTRB(120, 292, 290, 310), Paint()..color = const Color(0xFF2B1D0E));
        if (!flames) {
        } else if (out) {
          smoke(c, const Offset(200, 296));
        } else {
          for (final (x, sc) in const [(140.0, 0.8), (170.0, 1.1), (205.0, 1.3), (240.0, 1.0), (272.0, 0.7)]) {
            flame(c, Offset(x, 302), sc);
          }
        }
      case FireKind.electrical:
        // Feeder pillar / panel with its door open.
        c.drawRect(const Rect.fromLTRB(120, 290, 240, 300), Paint()..color = const Color(0xFF9D9A90));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(130, 170, 230, 292), const Radius.circular(4)), Paint()..color = const Color(0xFF8E979F));
        c.drawRect(const Rect.fromLTRB(140, 182, 220, 282), Paint()..color = const Color(0xFF2B2F35));
        c.drawPath(
          Path()
            ..moveTo(230, 172)
            ..lineTo(270, 186)
            ..lineTo(270, 296)
            ..lineTo(230, 290)
            ..close(),
          Paint()..color = const Color(0xFF9AA3AB),
        );
        final bus = Paint()
          ..color = const Color(0xFFB98B54)
          ..strokeWidth = 4;
        for (final y in const [200.0, 220.0, 240.0]) {
          c.drawLine(Offset(148, y), Offset(212, y), bus);
        }
        if (!out && !powerOff) {
          // Spark (power still on).
          final ray = Paint()
            ..color = const Color(0xFFFFD21F)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round;
          const sp = Offset(186, 222);
          for (var i = 0; i < 8; i++) {
            final a = i * math.pi / 4;
            c.drawLine(sp + Offset(math.cos(a), math.sin(a)) * 6, sp + Offset(math.cos(a), math.sin(a)) * 18, ray);
          }
        }
        if (!flames) {
        } else if (out) {
          smoke(c, const Offset(180, 250));
        } else {
          flame(c, const Offset(166, 262), 0.9);
          flame(c, const Offset(192, 270), 1.2);
        }
      case FireKind.grass:
        // Pole with dry grass at its foot.
        c.drawRect(const Rect.fromLTRB(244, 60, 258, 300), Paint()..color = const Color(0xFFB9B6AD));
        c.drawRect(const Rect.fromLTRB(228, 74, 274, 80), Paint()..color = const Color(0xFF5F676F));
        final grass = Paint()
          ..color = const Color(0xFFC9A55A)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        final rnd = math.Random(5);
        for (var i = 0; i < 70; i++) {
          final x = 90 + rnd.nextDouble() * 200;
          c.drawLine(Offset(x, 300), Offset(x + (rnd.nextDouble() - 0.5) * 10, 300 - 10 - rnd.nextDouble() * 16), grass);
        }
        if (out) {
          c.drawOval(const Rect.fromLTRB(110, 292, 240, 306), Paint()..color = const Color(0xFF3B3326));
          if (flames) smoke(c, const Offset(170, 296));
        } else if (flames) {
          for (final (x, sc) in const [(120.0, 0.7), (150.0, 1.0), (180.0, 1.2), (212.0, 0.9)]) {
            flame(c, Offset(x, 302), sc);
          }
        }
    }
  }

  @override
  bool shouldRepaint(FireScenePainter old) => old.kind != kind || old.out != out || old.powerOff != powerOff || old.flames != flames;
}

/// The isolator switch beside the panel: a grey box with a red lever, ON
/// (up, red lamp) or OFF (down, green lamp). Tap it or pull it down.
class _IsolatorSwitch extends StatelessWidget {
  const _IsolatorSwitch({super.key, required this.on, required this.live, required this.quiet, required this.onOff});
  final bool on;

  /// It can be switched now.
  final bool live;
  final bool quiet;
  final ValueChanged<Offset> onOff;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FireLines.switchLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: live ? (d) => onOff(d.globalPosition) : null,
        onVerticalDragUpdate: live
            ? (d) {
                if (d.delta.dy > 1.5) onOff(d.globalPosition);
              }
            : null,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: on ? 0 : 1),
          duration: quiet ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeInCubic,
          builder: (_, v, _) => CustomPaint(painter: _IsolatorPainter(v)),
        ),
      ),
    );
  }
}

class _IsolatorPainter extends CustomPainter {
  _IsolatorPainter(this.v);

  /// 0 = ON (lever up) … 1 = OFF (lever down).
  final double v;

  void _label(Canvas c, String text, Offset centre, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: col, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size size) {
    // Drawn for a 60-wide box, scaled to fit.
    final k = size.width / 60;
    c.scale(k);
    final s = Size(60, size.height / k);
    final box = Rect.fromCenter(center: Offset(s.width / 2, s.height / 2 - 4), width: 36, height: 50);
    c.drawRRect(RRect.fromRectAndRadius(box.shift(const Offset(1.5, 2)), const Radius.circular(5)), Paint()..color = const Color(0x55000000));
    c.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8F98A0), Color(0xFFC3CAD0), Color(0xFF858E96)]).createShader(box),
    );
    final on = v < 0.5;
    _label(c, 'ON', Offset(box.center.dx - 6, box.top + 8), on ? const Color(0xFFB71C1C) : const Color(0xFF5B636B));
    _label(c, 'OFF', Offset(box.center.dx - 6, box.bottom - 8), on ? const Color(0xFF5B636B) : const Color(0xFF1B7A3D));
    // Lamp.
    final lamp = Offset(box.right - 7, box.top + 8);
    final lc = on ? const Color(0xFFE5483A) : const Color(0xFF39B86A);
    c.drawCircle(lamp, 7, Paint()..shader = RadialGradient(colors: [lc.withValues(alpha: 0.55), lc.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: lamp, radius: 7)));
    c.drawCircle(lamp, 3.2, Paint()..color = lc);
    // Lever: pivots at the middle, up when ON, down when OFF.
    final pivot = Offset(box.center.dx - 4, box.center.dy);
    final a = -math.pi / 2 + 0.25 + v * (math.pi - 0.5);
    final end = pivot + Offset(math.cos(a), math.sin(a)) * 17;
    c.drawLine(pivot, end, Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round);
    c.drawCircle(end, 5.2, Paint()..color = const Color(0xFFD7261E));
    c.drawCircle(end.translate(-1.4, -1.4), 1.8, Paint()..color = const Color(0x88FFFFFF));
    c.drawCircle(pivot, 3.4, Paint()..color = const Color(0xFF3A3F46));
  }

  @override
  bool shouldRepaint(_IsolatorPainter old) => old.v != v;
}

/// The squeeze lever: hold it down to spray, let go to stop.
class _SqueezeButton extends StatelessWidget {
  const _SqueezeButton({super.key, required this.holding, required this.onHold});
  final bool holding;
  final void Function(bool down, Offset at) onHold;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FireLines.squeeze,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => onHold(true, e.position),
        onPointerUp: (e) => onHold(false, e.position),
        onPointerCancel: (e) => onHold(false, e.position),
        child: AnimatedScale(
          scale: holding ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: holding ? const [Color(0xFFB02A1F), Color(0xFF7E1C14)] : const [Color(0xFFE5483A), Color(0xFFB02A1F)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: holding ? const [] : const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Text(FireLines.squeeze, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The fire point's red stand: two posts and a rail with hooks.
class _StandPainter extends CustomPainter {
  const _StandPainter();

  @override
  void paint(Canvas c, Size s) {
    final post = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF8E1F16), Color(0xFFD23A2C), Color(0xFF8E1F16)]).createShader(Rect.fromLTWH(0, 0, 10, s.height));
    c.drawOval(Rect.fromLTWH(-4, s.height - 8, s.width + 8, 12), Paint()..color = const Color(0x40000000));
    c.drawRect(Rect.fromLTWH(2, 2, 7, s.height - 4), post);
    c.drawRect(Rect.fromLTWH(s.width - 9, 2, 7, s.height - 4), post);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 2, s.width, 7), const Radius.circular(2)), Paint()..color = const Color(0xFFC0392B));
  }

  @override
  bool shouldRepaint(_StandPainter old) => false;
}
