import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'choice_deck.dart';
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'rod_pick.dart' show RodRating, RodRatingText;
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Lesson 1.2, কাজ 1: "কতটা দূরে?". A street seen from the side under a live
// line: people on a ladder, on a roof, with a long pole, a truck's boom. The
// player drags the লক্ষ্মণ রেখা out from the wire — only its distance shows
// (মি · ফুট), no target, no hint — and sets it: everyone under its edge is
// stopped. The real band shows only after the check (proof when right, the
// hint when wrong). Three streets: LT dry; 11/33 kV dry with a long tool whose
// tip is inside; 11 kV in rain, where the distance grows (10–12 ft).
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" → next street by itself.
//
// Deadly (owner-approved list): someone left inside the distance. Slips: a
// band short of the lesson's distance (no one left inside), or far past it /
// stopping someone who was safe. Three slips fail the level.
//
// No careless coworker on this step (MODULE1_LADDER.md: he comes on step 6).
// Gesture hints (how, never what): before the band moves, a short downward
// nudge on its handle; once it moved, a tap on the check button (the one way
// to set it). The reason deck brings its own sweep.
//
// Voice: device TTS only. Art: assets/game/art/distance/ (hand-made SVG, no
// text inside); the line, people and machines are drawn in code to scale.

// ============================================================================
// Content
// ============================================================================

enum ReachKind { ladder, roof, pole, boom }

/// One figure in the street: what it is and how far its highest point
/// (hand or tool tip) is below the wire, in metres.
@immutable
class StreetFigure {
  const StreetFigure({required this.id, required this.kind, required this.gapM});
  final String id;
  final ReachKind kind;
  final double gapM;
  bool get tool => kind == ReachKind.pole || kind == ReachKind.boom;
}

@immutable
class StreetRound {
  const StreetRound({required this.line, required this.rain, required this.placeBn, required this.figures})
      : assert(!rain || line == RodRating.kv11, 'rain rounds are 11 kV only (lesson 1.2)');
  final RodRating line;
  final bool rain;
  final String placeBn;
  final List<StreetFigure> figures;

  /// The লক্ষ্মণ রেখা in metres (lesson 1.2: LT 1.2 · 11 kV 2.5 · 33 kV 3.0;
  /// in rain 11 kV keeps 10–12 ft — at least 3.0 m).
  double get distanceM => distanceFor(line, rain: rain);
  bool inside(StreetFigure f) => f.gapM < distanceM;

  /// The band edge the level accepts: from the লক্ষ্মণ রেখা to a little past
  /// it (in rain on 11 kV, the lesson's 10–12 ft: 3.0–3.7 m).
  double get minM => distanceM;
  double get maxM => rain ? 3.7 : distanceM + 0.6;
}

/// The lesson gives a rain figure only for 11 kV (10–12 ft), and no standard
/// gives a rain multiplier, so rain rounds are dealt on 11 kV only (owner,
/// 2026-11-08).
double distanceFor(RodRating line, {bool rain = false}) {
  assert(!rain || line == RodRating.kv11, 'rain rounds are 11 kV only (lesson 1.2)');
  return switch (line) {
    RodRating.lt => 1.2,
    RodRating.kv11 => rain ? 3.0 : 2.5,
    RodRating.kv33 => 3.0,
  };
}

abstract final class DistanceLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askAny];

  static const title = 'কতটা দূরে?';
  static const intro = 'লাইনে কারেন্ট, নিচে লোকজন! লক্ষ্মণ রেখা টেনে সবাইকে বাঁচান।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];

  /// The task: the line is named (its plate shows it too), never the distance.
  static const askAny = 'লক্ষ্মণ রেখা কতদূর? টেনে নামান।';
  static String ask(StreetRound r) => '${r.line.lineBn} লাইন। $askAny';
  static const again = 'আবার ভেবে রেখাটা টানুন।';
  static const check = 'এখানেই রেখা';
  static const dragLabel = 'লক্ষ্মণ রেখা';

  /// The band's distance from the wire, the only number on the scene.
  static String readout(double m) => '${m.toStringAsFixed(1)} মি · ${(m * 3.281).round()} ফুট';
  static const stop = 'থামুন';
  static const rain = 'বৃষ্টি';
  static const places = ['বাজারের রাস্তা', 'স্কুলের সামনে', 'নতুন বাড়ির গলি', 'হাটের মোড়', 'মন্দিরের পাশের রাস্তা'];
  static String scene(StreetRound r) => '${r.placeBn} · ${r.line.lineBn} লাইন${r.rain ? ' · $rain' : ''}';
  static String band(StreetRound r) => switch ((r.line, r.rain)) {
        (RodRating.lt, false) => 'এলটি: কমপক্ষে 1.2 মিটার (প্রায় 4 ফুট)',
        (RodRating.kv11, false) => '11 কেভি: কমপক্ষে 2.5 মিটার (প্রায় 8 ফুট)',
        (RodRating.kv33, false) => '33 কেভি: কমপক্ষে 3.0 মিটার (প্রায় 10 ফুট)',
        (RodRating.kv11, true) => 'বৃষ্টিতে 11 কেভি: 10–12 ফুট (3–3.7 মিটার)',
        (_, true) => 'বৃষ্টিতে দূরত্ব আরও বাড়ান',
      };
  static const allSet = 'চোখের মাপ পাকা! ভোল্টেজ আর আবহাওয়া — দুটোই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — কোন লাইনে কত দূর, পাঠে দেখে আসুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtBody = 'রেখার ভেতরের মানুষ থামিয়েছেন';
  static const caughtTool = 'টুলের ডগাও ধরেছেন';
  static const caughtRain = 'বৃষ্টিতে দূরত্ব বাড়িয়েছেন';

  // The reason after a right band (lesson 1.2): one right, two wrong.
  static const whyAsk = 'কেন রেখা এতদূরে টানলেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const whyLt = ['এলটিতেও অন্তত 1.2 মিটার দূরে থাকতে হয়', 'কাছে গেলেই বিদ্যুৎ লাফায়, এলটিতে 4 ফুট'];
  static const whyKv11 = ['11 কেভিতে অন্তত 2.5 মিটার দূরে থাকতে হয়', 'ভোল্টেজ বেশি, তাই 11 কেভিতে অন্তত 8 ফুট'];
  static const whyKv33 = ['33 কেভিতে অন্তত 3.0 মিটার দূরে থাকতে হয়', 'ভোল্টেজ যত বেশি, দূরত্বও তত বেশি লাগে'];
  static const whyTool = ['লম্বা টুলের ডগাও হাত, তাকেও বাইরে রাখি'];
  static const whyRain = ['বৃষ্টিতে ভেজা বাতাসে দূরত্ব বাড়াতে হয়', 'বৃষ্টিতে 11 কেভিতে 8 নয়, 10–12 ফুট দূরে'];
  /// Wrong reasons in the right ones' own words (the dealt right reason's
  /// voltage, tool or rain also shows on a wrong card, so no word gives the
  /// answer away).
  /// Each wrong list pairs by index with its right list (same unit, same
  /// phrasing), so the dealt twin shares the right card's words.
  static const whyLtWrong = ['এলটিতে অন্তত 0.3 মিটার দূরে থাকলেই চলে', 'কম ভোল্টেজ, তাই এলটিতে 1 ফুটই যথেষ্ট'];
  static const whyKv11Wrong = ['11 কেভিতে অন্তত 1 মিটার দূরে থাকলেই চলে', 'ভোল্টেজ যা-ই হোক, 11 কেভিতে 4 ফুটই যথেষ্ট'];
  static const whyKv33Wrong = ['33 কেভিতে অন্তত 1.2 মিটার দূরে থাকলেই চলে', 'ভোল্টেজ বেশি হলেও দূরত্ব একই রাখা যায়'];
  static const whyToolWrong = ['লম্বা টুলের ডগা রেখার ভেতরে গেলেও চলে', 'শুধু শরীর মাপি, টুলের ডগা তো হাত নয়'];
  static const whyRainWrong = ['বৃষ্টিতে ভেজা বাতাসে দূরত্ব কমানো যায়', 'বৃষ্টিতেও 11 কেভিতে 8 ফুট দূরেই চলে'];

  /// General wrong reasons (any street).
  static const whyWrong = [
    'না ছুঁলে তারের কাছে গেলেও কিছু হয় না',
    'রবারের জুতো থাকলে তারের কাছে যাওয়া যায়',
    'সব লাইনেই এক হাত দূরে থাকলেই কাজ চলে',
    'বাঁশের লাঠি হলে তারের কাছে ভয় নেই',
    'বৃষ্টিতেও শুকনো দিনের দূরত্বই যথেষ্ট',
    'অল্প সময়ের কাজে দূরত্ব না মানলেও চলে',
    'এলটি লাইনে দূরত্ব রাখার দরকারই নেই',
  ];

  /// The right reasons for what this street asked (its voltage; a long
  /// tool's tip inside; the rain).
  static List<String> whyRight(StreetRound r) => [
        ...(r.rain
            ? whyRain
            : switch (r.line) {
                RodRating.lt => whyLt,
                RodRating.kv11 => whyKv11,
                RodRating.kv33 => whyKv33,
              }),
        if (r.figures.any((f) => f.tool && r.inside(f))) ...whyTool,
      ];

  /// The wrong cards that mirror the right card [right] (same topic).
  static List<String> mirrorOf(String right) {
    if (whyTool.contains(right)) return whyToolWrong;
    if (whyRain.contains(right)) return whyRainWrong;
    if (whyKv33.contains(right)) return whyKv33Wrong;
    if (whyKv11.contains(right)) return whyKv11Wrong;
    return whyLtWrong;
  }

  /// Every wrong reason this street can deal: the general ones and the
  /// mirrors of its right ones.
  static List<String> whyWrongFor(StreetRound r) => [
        ...whyWrong,
        for (final m in {for (final w in whyRight(r)) mirrorOf(w)}) ...m,
      ];

  static const _pairs = [
    (whyTool, whyToolWrong),
    (whyRain, whyRainWrong),
    (whyKv33, whyKv33Wrong),
    (whyKv11, whyKv11Wrong),
    (whyLt, whyLtWrong),
  ];

  /// The wrong card paired with the right card [right]: same topic, same
  /// unit and phrasing (by index).
  static String twinOf(String right) {
    for (final (rights, wrongs) in _pairs) {
      final i = rights.indexOf(right);
      if (i >= 0) return wrongs[i % wrongs.length];
    }
    return whyLtWrong.first;
  }

  /// One right reason, its paired wrong twin, one other wrong; shuffled.
  static List<ChoiceOption> dealWhy(StreetRound r, math.Random rng) {
    final rights = whyRight(r);
    final right = rights[rng.nextInt(rights.length)];
    final w1 = twinOf(right);
    final rest = [for (final w in whyWrongFor(r)) if (w != w1) w];
    final w2 = rest[rng.nextInt(rest.length)];
    return [ChoiceOption(right, true), ChoiceOption(w1, false), ChoiceOption(w2, false)]..shuffle(rng);
  }
}

abstract final class DistanceMistakes {
  static const insideMissed = DoMistake(
    key: '1.2/distance/inside-missed',
    textBn: 'লক্ষ্মণ রেখার ভেতরে ঢুকেছেন—না ছুঁলেও কারেন্ট লাফিয়ে আসে! ভোল্টেজ দেখে নিরাপদ দূরত্ব রাখুন।',
    art: 'assets/game/art/distance/arc_jump.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const toolTipMissed = DoMistake(
    key: '1.2/distance/tool-tip-missed',
    textBn: 'শরীর দূরে, কিন্তু লম্বা টুলের ডগা রেখার ভেতরে — টুলের ডগাও আপনার হাত।',
    art: 'assets/game/art/distance/tool_tip.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const rainMissed = DoMistake(
    key: '1.2/distance/rain-missed',
    textBn: 'বৃষ্টিতে বাতাস ভেজা — দূরত্ব বাড়াতে হয়। 11 কেভিতে 8 ফুট নয়, 10–12 ফুট।',
    art: 'assets/game/art/distance/rain_distance.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const falseStop = DoMistake(
    key: '1.2/distance/false-stop',
    textBn: 'এ তো নিরাপদ দূরত্বেই ছিল — রেখা অনেক বড় টেনেছেন। কোন লাইনে কত দূর, পাঠে দেখে নিন।',
    art: 'assets/game/art/distance/man_ruler.svg',
    lessonPoint: 1,
  );
  static const bandShort = DoMistake(
    key: '1.2/distance/band-short',
    textBn: 'রেখা ছোট পড়েছে — এই ভোল্টেজে আরও দূরে থাকতে হয়। কোন লাইনে কত দূর, পাঠে দেখে নিন।',
    art: 'assets/game/art/distance/arc_jump.svg',
    lessonPoint: 1,
  );
  static const rainShort = DoMistake(
    key: '1.2/distance/rain-short',
    textBn: 'বৃষ্টিতে বাতাস ভেজা — রেখা আরও বড় হয়। বৃষ্টিতে কত দূর, পাঠে দেখে নিন।',
    art: 'assets/game/art/distance/rain_distance.svg',
    lessonPoint: 2,
  );
  static const bandLong = DoMistake(
    key: '1.2/distance/band-long',
    textBn: 'এত বড় রেখা লাগে না — ভোল্টেজ দেখে ঠিক দূরত্বটা জানুন। কোন লাইনে কত দূর, পাঠে দেখে নিন।',
    art: 'assets/game/art/distance/man_ruler.svg',
    lessonPoint: 1,
  );
  static const all = [insideMissed, toolTipMissed, rainMissed, falseStop, bandShort, rainShort, bandLong];
}

/// Scene scale: 40 px per metre, the wire 8.25 m up.
abstract final class StreetGeo {
  static const size = Size(360, 480);
  static const ppm = 40.0;
  static const groundY = 440.0;
  static const lineY = 110.0;
  static const lineM = (groundY - lineY) / ppm;
  static const slots = [118.0, 205.0, 292.0];
  static double y(double gapM) => lineY + gapM * ppm;

  /// The band handle's height (design px); its centre sits on the band edge.
  static const handleH = 30.0;

  /// Where the street picture sits in a full scene [h] high (design px): low,
  /// so a tall phone gets more sky; the controls stay under the road.
  static double topIn(double h) => math.max(64.0, h - size.height - 150);
}

/// Largest gap below the wire each kind can show (so a roof stays a roof).
double _maxGap(ReachKind k) => switch (k) {
      ReachKind.ladder => StreetGeo.lineM - 3.0,
      ReachKind.roof => StreetGeo.lineM - 4.6,
      ReachKind.pole => StreetGeo.lineM - 3.5,
      ReachKind.boom => StreetGeo.lineM - 2.5,
    };

/// A fresh street each play: places, kinds, gaps and slots vary.
List<StreetRound> dealStreets(math.Random rng) {
  var n = 0;
  double u(double a, double b) => a + rng.nextDouble() * (b - a);
  StreetFigure fig(ReachKind k, double gap) => StreetFigure(id: 'f${n++}', kind: k, gapM: gap.clamp(0.3, _maxGap(k)));
  ReachKind pick(List<ReachKind> from, double needGap) {
    final ok = [for (final k in from) if (_maxGap(k) >= needGap) k];
    return ok[rng.nextInt(ok.length)];
  }

  final places = [...DistanceLines.places]..shuffle(rng);
  List<StreetFigure> spread(List<StreetFigure> f) => f..shuffle(rng);

  // 1: LT, dry — one in, one out, one either.
  const d1 = 1.2;
  final k1 = [...ReachKind.values]..shuffle(rng);
  final g1out = d1 + u(0.8, 1.6);
  final g1in = d1 * u(0.3, 0.7);
  final r1 = [
    fig(k1[0], g1in),
    fig(pick(k1.sublist(1), g1out), g1out),
    rng.nextBool() ? fig(k1[2], d1 * u(0.3, 0.7)) : fig(pick([ReachKind.ladder, ReachKind.boom, ReachKind.pole], d1 + 1.0), d1 + u(0.9, 1.6)),
  ];

  // 2: 11 or 33 kV, dry — a long tool's tip inside while its holder is far below.
  final line2 = rng.nextBool() ? RodRating.kv11 : RodRating.kv33;
  final d2 = distanceFor(line2);
  final tool = rng.nextBool() ? ReachKind.pole : ReachKind.boom;
  final g2out = d2 + u(0.8, 1.3);
  final r2 = [
    fig(tool, d2 * u(0.35, 0.7)),
    fig(pick([ReachKind.ladder, ReachKind.roof], g2out), g2out),
    rng.nextBool() ? fig(ReachKind.ladder, d2 * u(0.3, 0.6)) : fig(pick([ReachKind.ladder, ReachKind.boom], d2 + 1.0), d2 + u(0.9, 1.4)),
  ];

  // 3: 11 kV in rain — one figure safe on a dry day is inside now.
  final r3 = [
    fig(rng.nextBool() ? ReachKind.ladder : ReachKind.roof, u(2.6, 2.74)),
    fig(pick([ReachKind.ladder, ReachKind.pole, ReachKind.boom], 4.2), u(4.2, 4.7)),
    fig(rng.nextBool() ? ReachKind.boom : ReachKind.pole, u(1.0, 2.0)),
  ];

  return [
    StreetRound(line: RodRating.lt, rain: false, placeBn: places[0], figures: spread(r1)),
    StreetRound(line: line2, rain: false, placeBn: places[1], figures: spread(r2)),
    StreetRound(line: RodRating.kv11, rain: true, placeBn: places[2], figures: spread(r3)),
  ];
}

@immutable
class StreetCheck {
  const StreetCheck({required this.caught, required this.falseStops, this.deadly, this.slip, this.missed});
  final List<StreetFigure> caught;
  final List<StreetFigure> falseStops;
  final DoMistake? deadly;

  /// A band check's one slip (short, long, or a safe person stopped).
  final DoMistake? slip;

  /// The first person left inside (deadly).
  final StreetFigure? missed;
}

/// The play state (pure logic).
class DistanceRun {
  DistanceRun(this.rounds);
  final List<StreetRound> rounds;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => round >= rounds.length;
  bool get ended => done || deadly != null;
  StreetRound get current => rounds[round.clamp(0, rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Checks the marks on the current street (does not move on).
  StreetCheck check(Set<String> marked) {
    if (ended) return const StreetCheck(caught: [], falseStops: []);
    final r = current;
    final caughtNow = <StreetFigure>[];
    final wrong = <StreetFigure>[];
    DoMistake? fatal;
    for (final f in r.figures) {
      final inside = r.inside(f);
      final on = marked.contains(f.id);
      if (inside && on) caughtNow.add(f);
      if (!inside && on) wrong.add(f);
      if (inside && !on && fatal == null) {
        fatal = r.rain && f.gapM >= distanceFor(r.line)
            ? DistanceMistakes.rainMissed
            : (f.tool ? DistanceMistakes.toolTipMissed : DistanceMistakes.insideMissed);
      }
    }
    if (fatal != null) {
      deadly = fatal;
    } else {
      slips += wrong.length;
      for (final f in caughtNow) {
        final tag = r.rain && f.gapM >= distanceFor(r.line)
            ? DistanceLines.caughtRain
            : (f.tool ? DistanceLines.caughtTool : DistanceLines.caughtBody);
        if (!caught.contains(tag)) caught.add(tag);
      }
    }
    return StreetCheck(caught: caughtNow, falseStops: wrong, deadly: fatal);
  }

  /// The band's edge starts near the wire; the player drags it out.
  static const bandStart = 0.5;
  static const bandMin = 0.3;
  static const bandMax = 6.0;

  /// The gesture hint's drag nudge from [bandStart] (metres): it ends at
  /// 0.9 m, short of the nearest street's 1.2 m, so it never shows a band
  /// that passes.
  static const nudgeM = 0.4;

  /// Checks the player's band on the current street (does not move on):
  /// everyone whose gap is under [bandM] is stopped. Someone inside left out
  /// is deadly; otherwise a band short of the lesson's distance, past the
  /// accepted edge or stopping a safe person is one slip.
  StreetCheck checkBand(double bandM) {
    // Over (passed, or someone left inside): nothing more counts.
    if (ended) return const StreetCheck(caught: [], falseStops: []);
    const eps = 1e-6;
    final r = current;
    final caughtNow = <StreetFigure>[];
    final wrong = <StreetFigure>[];
    StreetFigure? missed;
    for (final f in r.figures) {
      final inside = r.inside(f);
      final on = f.gapM < bandM;
      if (inside && on) caughtNow.add(f);
      if (!inside && on) wrong.add(f);
      if (inside && !on) missed ??= f;
    }
    if (missed != null) {
      final fatal = r.rain && missed.gapM >= distanceFor(r.line)
          ? DistanceMistakes.rainMissed
          : (missed.tool ? DistanceMistakes.toolTipMissed : DistanceMistakes.insideMissed);
      deadly = fatal;
      return StreetCheck(caught: caughtNow, falseStops: wrong, deadly: fatal, missed: missed);
    }
    final DoMistake? slip = bandM < r.minM - eps
        ? (r.rain ? DistanceMistakes.rainShort : DistanceMistakes.bandShort)
        : wrong.isNotEmpty
            ? DistanceMistakes.falseStop
            : (bandM > r.maxM + eps ? DistanceMistakes.bandLong : null);
    if (slip != null) {
      slips++;
    } else {
      for (final f in caughtNow) {
        final tag = r.rain && f.gapM >= distanceFor(r.line)
            ? DistanceLines.caughtRain
            : (f.tool ? DistanceLines.caughtTool : DistanceLines.caughtBody);
        if (!caught.contains(tag)) caught.add(tag);
      }
    }
    return StreetCheck(caught: caughtNow, falseStops: wrong, slip: slip);
  }

  void next() => round++;
}

@immutable
class DistancePack {
  const DistancePack({required this.id, required this.titleBn, this.quickMs = 60000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const distancePack12 = DistancePack(id: 'do_1_2_a', titleBn: DistanceLines.title);
const distancePacks = {'do_1_2_a': distancePack12};

// ============================================================================
// Page
// ============================================================================

class DistanceSpotPage extends StatefulWidget {
  const DistanceSpotPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final DistancePack pack;
  final bool muted;
  final int? seed;

  @override
  State<DistanceSpotPage> createState() => _DistanceSpotPageState();
}

class _DistanceSpotPageState extends State<DistanceSpotPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DistanceRunPage(
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

class _DistanceRunPage extends ConsumerStatefulWidget {
  const _DistanceRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final DistancePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DistanceRunPage> createState() => _DistanceRunPageState();
}

class _DistanceRunPageState extends ConsumerState<_DistanceRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable {
  final _scoreKey = GlobalKey();
  late final DistanceRun _run = DistanceRun(dealStreets(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;

  /// The lower edge of the player's band, in metres below the wire.
  double _bandM = DistanceRun.bandStart;
  StreetCheck? _shown;
  var _streetSlipped = false;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  var _freeze = false;
  Completer<void>? _frozen;
  int? _mark;
  int _totalDelta = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// Gesture hints: the band's handle (drag nudge) and the check button (tap).
  final _hints = IdleHintController();
  final _handleKey = GlobalKey();
  final _checkKey = GlobalKey();

  /// The player has moved the band on this street.
  var _moved = false;

  /// Bands set on this street (a new waiting state after each slip).
  int _tries = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
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

  /// After the guide's intro: the clock runs and he gives the first task.
  Future<void> _start() async {
    _clock.start();
    await _sayChain([DistanceLines.ask(_run.current)]);
  }

  bool get _canDrag => !_intro && !_busy && !_ended && !_freeze && _shown == null && _card == null && !tableBusy;

  /// The gesture hint for the street: how to touch, never where to stop.
  /// Before the band moves (and again after a slip, when the same band would
  /// slip again) a short drag nudge on the handle; once it moved, the check
  /// button.
  HintSpec? _hint() {
    if (_moved) return HintSpec.tapOn(_checkKey);
    final r = HintSpec.globalRectOf(_handleKey);
    if (r == null) return null;
    // The nudge's length in metres, scaled like the street (FittedBox), so
    // the hand stops well short of every street's distance.
    final s = r.height / StreetGeo.handleH;
    return HintSpec.drag(r.center, toward: const Offset(0, 1), travel: DistanceRun.nudgeM * StreetGeo.ppm * s);
  }

  /// A tap on the sky or the road around the street (nothing to touch there).
  void _missTap() {
    if (_canDrag) _hints.missTap();
  }

  /// The finger sets the band's lower edge (0.1 m steps); only its distance
  /// shows — no target, no hint.
  void _dragBand(double y) {
    if (!_canDrag) return;
    final m = ((y - StreetGeo.lineY) / StreetGeo.ppm).clamp(DistanceRun.bandMin, DistanceRun.bandMax);
    final snapped = (m * 10).round() / 10;
    if (snapped == _bandM) return;
    if ((snapped * 2).floor() != (_bandM * 2).floor()) HapticFeedback.selectionClick();
    setState(() {
      _bandM = snapped;
      _moved = true;
    });
  }

  Future<void> _check(Offset origin) async {
    if (!_canDrag) return;
    _busy = true;
    _hush();
    final c = _run.checkBand(_bandM);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.ogg', volume: 0.5, muted: false));
    setState(() => _shown = c);
    final quiet = MediaQuery.disableAnimationsOf(context);
    if (c.deadly != null) {
      await _deadly(c.deadly!);
      return;
    }
    if (c.slip != null) {
      _streetSlipped = true;
      HapticFeedback.heavyImpact();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await Future<void>.delayed(quiet ? Duration.zero : const Duration(milliseconds: 700));
      if (!mounted) return;
      _busy = false;
      await _slip(c.slip!);
      return;
    }
    // Right: the ◆ wait on the table, then "কেন …?".
    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.ogg', volume: 0.6, muted: false));
    putOnTable(10 * c.caught.length + (_streetSlipped ? 0 : 10));
    _busy = false;
    final round = _run.round;
    unawaited(askReason(
      deal: () => DistanceLines.dealWhy(_run.current, widget.rng),
      question: DistanceLines.whyAsk,
      stillValid: () => _run.round == round && !_ended,
    ));
  }

  /// The next street (or the result) — by itself, after the reason.
  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _shown = null;
      _bandM = DistanceRun.bandStart;
      _streetSlipped = false;
      _moved = false;
      _tries = 0;
    });
    unawaited(_sayChain([DistanceLines.ask(_run.current)]));
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

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final line = reasonOpen ? DistanceLines.tapWhy[_nudgeN++ % DistanceLines.tapWhy.length] : _nudge.next(DistanceLines.ask(_run.current));
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
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

  /// A wrong band: the real band shows (the hint, only now) with its card.
  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', volume: 0.7, muted: false));
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('distance/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Someone left inside: the street freezes grey, the arc jumps in colour.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.ogg', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.ogg', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('distance/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? DistanceLines.deadlyWord : DistanceLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        // The real band goes away again; the player sets the band anew.
        // The same band would slip again, so the hand shows the drag nudge
        // again (never a tap on the check button).
        setState(() {
          _card = null;
          _shown = null;
          _moved = false;
          _tries++;
        });
        unawaited(_sayChain([DistanceLines.again]));
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
    if (!mounted) return;
    setState(() {
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? DistanceLines.fail : (_quickBonus ? DistanceLines.quick : DistanceLines.allSet),
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

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final r = _run.current;
    final shown = _shown;
    final playing = !_intro && _mark == null && !struckOut;
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
            hint: _hint,
            hintWaiting: playing && _canDrag,
            hintKey: ('street', _run.round, _tries, _moved),
            hintController: _hints,
            progress: DoProgress(
              labels: DistanceLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) {
              final top = StreetGeo.topIn(m.height);
              return [
                Positioned.fill(
                  key: const ValueKey('sky'),
                  child: ColorFiltered(
                    colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _missTap(),
                      child: StreetBackdrop(streetTop: top),
                    ),
                  ),
                ),
                Positioned(
                  key: const ValueKey('street'),
                  left: 0,
                  top: top,
                  width: StreetGeo.size.width,
                  height: StreetGeo.size.height,
                  child: ColorFiltered(
                    colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                    child: _StreetScene(
                      key: ValueKey('street-${_run.round}'),
                      round: r,
                      bandM: _bandM,
                      shown: shown,
                      quiet: quiet,
                      handleKey: _handleKey,
                      onDrag: _dragBand,
                    ),
                  ),
                ),
                if (_freeze && shown?.missed != null)
                  Positioned(
                    key: const ValueKey('arc'),
                    left: 0,
                    top: top,
                    width: StreetGeo.size.width,
                    height: StreetGeo.size.height,
                    child: IgnorePointer(child: CustomPaint(painter: ArcJumpPainter(_arcTo(r, shown!.missed!)))),
                  ),
              ];
            },
            overlays: [
              // The street's ◆ waiting on the table.
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (playing && shown == null && _card == null && !reasonOpen)
                Positioned(
                  key: const ValueKey('hud-check'),
                  left: 16,
                  right: 136,
                  bottom: pad.bottom + 22,
                  child: DoBigButton(key: _checkKey, label: DistanceLines.check, filled: true, onTapUp: (d) => unawaited(_check(d.globalPosition))),
                ),
              if (reasonOpen)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonDeck(quiet: quiet, key: const ValueKey('why-deck')),
                  ),
                ),
              if (playing && _card == null && !_freeze) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (reasonOpen ? 236 : 8)),
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
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.electric,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
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
                  line: DistanceLines.intro,
                  alarm: 'sounds/learn/spark.ogg',
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

  /// Where the arc lands: the missed figure's highest point (hand or tip).
  Offset _arcTo(StreetRound r, StreetFigure f) {
    final i = r.figures.indexOf(f);
    final x = StreetGeo.slots[math.max(0, i)];
    final dx = switch (f.kind) {
      ReachKind.ladder => 14.0,
      ReachKind.roof => 12.0,
      ReachKind.pole => 22.0,
      ReachKind.boom => -4.0,
    };
    return Offset(x + dx, StreetGeo.y(f.gapM));
  }
}

// ============================================================================
// Scene
// ============================================================================

/// Sky above the street picture and road below it, so the scene runs edge
/// to edge on any phone (lesson 1.2's street levels).
class StreetBackdrop extends StatelessWidget {
  const StreetBackdrop({super.key, required this.streetTop});
  final double streetTop;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: streetTop + 2,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6E9CC6), Color(0xFFA9CBE6)],
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, top: 0, height: streetTop + 120, child: const IgnorePointer(child: CustomPaint(painter: _CloudsPainter()))),
          Positioned(left: 0, right: 0, top: streetTop + StreetGeo.size.height - 2, bottom: 0, child: const ColoredBox(color: Color(0xFF5E5B56))),
        ],
      );
}

/// A few soft clouds in the sky over the street (static).
class _CloudsPainter extends CustomPainter {
  const _CloudsPainter();

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0x8CFFFFFF);
    for (final (x, y, r) in const [(70.0, 0.30, 16.0), (250.0, 0.18, 20.0), (310.0, 0.55, 13.0), (160.0, 0.62, 11.0)]) {
      final o = Offset(x, s.height * y);
      c.drawCircle(o, r, p);
      c.drawCircle(o.translate(r * 1.1, r * 0.25), r * 0.8, p);
      c.drawCircle(o.translate(-r * 1.1, r * 0.3), r * 0.7, p);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - r * 1.8, o.dy, r * 3.7, r * 0.9), Radius.circular(r * 0.45)), p);
    }
  }

  @override
  bool shouldRepaint(_CloudsPainter old) => false;
}

/// The street: background art, the live wire, the figures (drawn to scale),
/// rain, the player's band (drag its edge) and, after the check, the real
/// লক্ষ্মণ রেখা.
class _StreetScene extends StatelessWidget {
  const _StreetScene({super.key, required this.round, required this.bandM, required this.shown, required this.quiet, required this.handleKey, required this.onDrag});
  final StreetRound round;
  final GlobalKey handleKey;
  final double bandM;
  final StreetCheck? shown;
  final bool quiet;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final s = shown;
    final reveal = s != null;
    final wrong = s != null && (s.slip != null || s.deadly != null);
    final d = round.distanceM * StreetGeo.ppm;
    final b = bandM * StreetGeo.ppm;
    final bandCol = !reveal ? const Color(0xFFF2B632) : (wrong ? SlmColors.danger : const Color(0xFF2E8B45));
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: SvgPicture.asset('assets/game/art/distance/street_side.svg', fit: BoxFit.fill)),
        if (round.rain) const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x40324A66)))),
        // The player's band, both sides of the wire.
        Positioned(
          left: 0,
          right: 0,
          top: StreetGeo.lineY - b,
          height: 2 * b,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bandCol.withValues(alpha: 0.22),
                border: Border.symmetric(horizontal: BorderSide(color: bandCol, width: 2)),
              ),
            ),
          ),
        ),
        // The real লক্ষ্মণ রেখা: after a right band as the proof, after a
        // wrong one as the hint.
        Positioned(
          left: 0,
          right: 0,
          top: StreetGeo.lineY - d,
          height: 2 * d,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: reveal ? 1 : 0,
              duration: quiet ? Duration.zero : const Duration(milliseconds: 500),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.95), width: 2.5)),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _StreetPainter(round)))),
        // The line's plate at eye level on the pole (the handle never reaches it).
        Positioned(left: 8, top: 330, child: _Plate(text: round.line.tag)),
        for (var i = 0; i < round.figures.length; i++) _figureMark(round.figures[i], StreetGeo.slots[i]),
        // The handle on the band's edge: its distance only.
        Positioned(
          left: 44,
          top: StreetGeo.lineY + b - StreetGeo.handleH / 2,
          height: StreetGeo.handleH,
          child: IgnorePointer(child: _BandHandle(key: handleKey, text: DistanceLines.readout(bandM), color: bandCol)),
        ),
        if (reveal)
          Positioned(
            key: const ValueKey('band-label'),
            left: 60,
            right: 8,
            top: math.max(4, StreetGeo.lineY - d + 4),
            child: IgnorePointer(child: Center(child: _BandLabel(text: DistanceLines.band(round)))),
          ),
        // Drag (or tap) anywhere on the street: the band's edge follows.
        Positioned.fill(
          key: const ValueKey('drag'),
          child: Semantics(
            slider: true,
            label: DistanceLines.dragLabel,
            value: DistanceLines.readout(bandM),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (e) => onDrag(e.localPosition.dy),
              onVerticalDragStart: (e) => onDrag(e.localPosition.dy),
              onVerticalDragUpdate: (e) => onDrag(e.localPosition.dy),
            ),
          ),
        ),
      ],
    );
  }

  /// Everyone under the band's edge is stopped (live as the band moves);
  /// after the check each gets ✓ or ✗.
  Widget _figureMark(StreetFigure f, double x) {
    final top = StreetGeo.y(f.gapM) - 18;
    final on = f.gapM < bandM;
    final s = shown;
    final verdict = s == null ? null : (round.inside(f) == on);
    return Positioned(
      left: x - 40,
      top: top,
      width: 80,
      height: StreetGeo.groundY - top,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            if (on)
              Positioned(
                top: -14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pan_tool_rounded, size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(DistanceLines.stop, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            if (verdict != null)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: verdict ? const Color(0xFF2E8B45) : SlmColors.danger),
                  child: Icon(verdict ? Icons.check_rounded : Icons.close_rounded, size: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The band's edge handle: grip lines and the distance (মি · ফুট).
class _BandHandle extends StatelessWidget {
  const _BandHandle({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.unfold_more_rounded, size: 16, color: Color(0xFF1E2228)),
            const SizedBox(width: 3),
            Text(text, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1E2228))),
          ],
        ),
      );
}

/// The arc jumping from the wire to [to] (in colour over the frozen grey
/// street) — lesson 1.2's deadly moment.
class ArcJumpPainter extends CustomPainter {
  ArcJumpPainter(this.to);
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final from = Offset(to.dx - 6, StreetGeo.lineY);
    final rnd = math.Random(5);
    final path = Path()..moveTo(from.dx, from.dy);
    const n = 7;
    for (var i = 1; i < n; i++) {
      final p = Offset.lerp(from, to, i / n)!;
      path.lineTo(p.dx + (rnd.nextDouble() - 0.5) * 18, p.dy);
    }
    path.lineTo(to.dx, to.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xAAFFE27A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(to, 12, Paint()..color = const Color(0xCCFFF3B0)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(ArcJumpPainter old) => old.to != to;
}

class _Plate extends StatelessWidget {
  const _Plate({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(color: const Color(0xFFFFF6D6), border: Border.all(color: const Color(0xFFC0392B), width: 1.2)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E2228))),
      );
}

class _BandLabel extends StatelessWidget {
  const _BandLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
      );
}

/// The live wire and the man-height ruler hanging from it (two 1.7 m men,
/// head to toe) — shared by the street scenes of lesson 1.2. [withRuler]: false
/// draws the wire alone.
void paintWireAndRuler(Canvas canvas, Size size, {bool withRuler = true}) {
  canvas.drawLine(
    const Offset(48, StreetGeo.lineY),
    Offset(size.width, StreetGeo.lineY + 2),
    Paint()
      ..color = const Color(0xFF2A2F35)
      ..strokeWidth = 3,
  );
  if (!withRuler) return;
  final ruler = Paint()..color = const Color(0x8C2E8B45);
  for (var i = 0; i < 2; i++) {
    final top = StreetGeo.lineY + 4 + i * 1.7 * StreetGeo.ppm;
    paintMan(canvas, Offset(66, top), 1.7 * StreetGeo.ppm - 4, ruler);
  }
  canvas.drawLine(const Offset(66, StreetGeo.lineY), const Offset(66, StreetGeo.lineY + 4), ruler..strokeWidth = 1.5);
}

/// A plain standing man, [h] px tall, top at [top] (silhouette).
void paintMan(Canvas c, Offset top, double h, Paint p) {
  final r = h * 0.09;
  c.drawCircle(top.translate(0, r), r, p);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(top.dx - r * 0.95, top.dy + r * 2.1, r * 1.9, h * 0.38), Radius.circular(r * 0.6)), p);
  c.drawRect(Rect.fromLTWH(top.dx - r * 0.9, top.dy + r * 2.1 + h * 0.36, r * 0.8, h * 0.42), p);
  c.drawRect(Rect.fromLTWH(top.dx + r * 0.1, top.dy + r * 2.1 + h * 0.36, r * 0.8, h * 0.42), p);
}

/// Wire, figures and rain — all to scale (40 px per metre).
class _StreetPainter extends CustomPainter {
  _StreetPainter(this.round);
  final StreetRound round;

  static const _skin = Color(0xFFF0C9A0);
  static const _cloth = Color(0xFF3F5E8C);
  static const _ink = Color(0xFF3A2E24);

  @override
  void paint(Canvas canvas, Size size) {
    paintWireAndRuler(canvas, size, withRuler: false);

    for (var i = 0; i < round.figures.length; i++) {
      _figure(canvas, round.figures[i], StreetGeo.slots[i]);
    }

    if (round.rain) {
      final drop = Paint()
        ..color = const Color(0x99B8CCE0)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final rnd = math.Random(7);
      for (var i = 0; i < 90; i++) {
        final x = rnd.nextDouble() * size.width;
        final y = rnd.nextDouble() * size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 3, y + 11), drop);
      }
    }
  }

  /// A person whose raised hand reaches [reach]; feet at [feetY].
  void _person(Canvas c, double x, double feetY, {Offset? hand}) {
    const h = 1.7 * StreetGeo.ppm;
    final head = Offset(x, feetY - h + 7);
    final body = Paint()..color = _cloth;
    final limb = Paint()
      ..color = _ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x - 4, feetY - 28), Offset(x - 6, feetY), limb);
    c.drawLine(Offset(x + 4, feetY - 28), Offset(x + 6, feetY), limb);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 8, feetY - h + 15, 16, 30), const Radius.circular(5)), body);
    final shoulder = Offset(x + 6, feetY - h + 20);
    c.drawLine(shoulder, hand ?? Offset(x + 10, feetY - h + 42), limb..color = _skin);
    c.drawLine(Offset(x - 6, feetY - h + 20), Offset(x - 10, feetY - h + 42), limb);
    c.drawCircle(head, 7, Paint()..color = _skin);
    c.drawArc(Rect.fromCircle(center: head.translate(0, -2), radius: 8), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2B632));
  }

  void _figure(Canvas c, StreetFigure f, double x) {
    final reach = StreetGeo.y(f.gapM);
    const g = StreetGeo.groundY;
    switch (f.kind) {
      case ReachKind.ladder:
        final topY = reach + 30;
        final rail = Paint()
          ..color = const Color(0xFF9AA3AB)
          ..strokeWidth = 3;
        final a0 = Offset(x - 22, g);
        final a1 = Offset(x - 4, topY);
        final b0 = Offset(x - 8, g);
        final b1 = Offset(x + 10, topY);
        c.drawLine(a0, a1, rail);
        c.drawLine(b0, b1, rail);
        for (var t = 0.08; t < 1; t += 0.11) {
          c.drawLine(Offset.lerp(a0, a1, t)!, Offset.lerp(b0, b1, t)!, rail..strokeWidth = 2);
        }
        // Standing on a rung: hand raised to the reach point.
        final feet = topY + 1.4 * StreetGeo.ppm;
        _person(c, x + 6, math.min(feet, g), hand: Offset(x + 14, reach));
      case ReachKind.roof:
        final roofY = reach + 2.1 * StreetGeo.ppm;
        c.drawRect(Rect.fromLTRB(x - 36, roofY, x + 36, g), Paint()..color = const Color(0xFFD8C7A2));
        c.drawRect(Rect.fromLTRB(x - 40, roofY - 5, x + 40, roofY + 2), Paint()..color = const Color(0xFF8D949B));
        for (var wy = roofY + 18; wy < g - 30; wy += 34) {
          c.drawRect(Rect.fromLTWH(x - 24, wy, 14, 14), Paint()..color = const Color(0xFF6F7F8F));
          c.drawRect(Rect.fromLTWH(x + 10, wy, 14, 14), Paint()..color = const Color(0xFF6F7F8F));
        }
        c.drawRect(Rect.fromLTWH(x - 8, g - 30, 16, 30), Paint()..color = const Color(0xFF7A5532));
        _person(c, x, roofY - 5, hand: Offset(x + 12, reach));
      case ReachKind.pole:
        const handY = g - 1.4 * StreetGeo.ppm;
        final hand = Offset(x + 10, handY);
        c.drawLine(
          hand,
          Offset(x + 22, reach),
          Paint()
            ..color = const Color(0xFFA9773A)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        c.drawCircle(Offset(x + 22, reach), 4, Paint()..color = const Color(0xFF7A7F85));
        _person(c, x, g, hand: hand);
      case ReachKind.boom:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - 38, g - 30, x + 30, g - 8), const Radius.circular(4)), Paint()..color = const Color(0xFFE0A33A));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x + 10, g - 48, x + 36, g - 8), const Radius.circular(5)), Paint()..color = const Color(0xFFC77F22));
        c.drawRect(Rect.fromLTRB(x + 16, g - 44, x + 32, g - 32), Paint()..color = const Color(0xFFBFD7EA));
        final wheel = Paint()..color = const Color(0xFF2A2F35);
        c.drawCircle(Offset(x - 24, g - 6), 7, wheel);
        c.drawCircle(Offset(x + 22, g - 6), 7, wheel);
        final base = Offset(x - 20, g - 32);
        final tip = Offset(x - 4, reach);
        c.drawLine(
          base,
          tip,
          Paint()
            ..color = const Color(0xFFD9A441)
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        c.drawLine(tip, tip.translate(0, 14), Paint()..color = const Color(0xFF3B3F45)..strokeWidth = 1.5);
        c.drawCircle(tip.translate(0, 16), 3, Paint()..color = const Color(0xFF3B3F45));
    }
  }

  @override
  bool shouldRepaint(_StreetPainter old) => old.round != round;
}
