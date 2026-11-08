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
import 'pole_yard.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 1.3: "পোলের ভাষা". One engine, two packs:
//   কাজ 1 "৩৬০° পোল পাঠ"   — PCC poles (hairline crack, spalling + rebar,
//                             eroded base, lean, hollow sound, hardware:
//                             a broken insulator, a loose cross-arm).
//   কাজ 2 "স্টিলের ক্যান্সার" — steel poles (rust at ground level, rust at the
//                             weld joint, bent, hardware).
// Four poles a play, on a drawn village roadside. Hands on: swipe (or walk)
// round the pole — some faults are on the back only — scan it close with the
// lens from the base to the top, tap it with the hammer (some faults are only
// heard: ঠক্ / দপ্, টন / ভোঁতা), then decide: উঠব, or উঠব না — রিপোর্ট.
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" (the reasons fit what this
// pole had; after a report the fault is shown only once the reason is paid)
// → the next pole by itself; the careless coworker once a play, on any pole.
//
// Deadly (owner-approved list): climbing a condemned pole (also by listening
// to him). Slips: climbing a sound pole without walking round, looking at the
// base and tapping it, or because he said so; reporting a sound pole (then it
// is still to read).
// Three slips strike the level out.
//
// Voice: the guide's lines by device TTS; the coworker in his recorded voice.
// Art: the yard and the pole are drawn in code (pole_yard.dart, PolePainter);
// mistake pictures in assets/game/art/pole/.

// ============================================================================
// Content
// ============================================================================

enum PoleKind { pcc, steel }

enum PoleSide { front, back }

enum PoleZone { base, waist, top }

enum PoleDefect { hairline, spalling, erosion, lean, hollow, groundRust, weldRust, bent, insulator, crossArm }

extension PoleDefectFacts on PoleDefect {
  PoleZone get zone => switch (this) {
        PoleDefect.erosion || PoleDefect.lean || PoleDefect.groundRust => PoleZone.base,
        PoleDefect.insulator || PoleDefect.crossArm => PoleZone.top,
        _ => PoleZone.waist,
      };

  /// Seen from every side (no need to walk round).
  bool get allSides => this == PoleDefect.lean || this == PoleDefect.bent || this == PoleDefect.erosion || this == PoleDefect.crossArm;

  /// Only the hammer finds it.
  bool get heardOnly => this == PoleDefect.hollow;

  /// Makes the hammer sound wrong (lesson 1.3 point 2: weak concrete or a
  /// void inside; rust that sounds dull and flakes off). Spalling is found by
  /// sight.
  bool get soundsBad => this == PoleDefect.hollow || this == PoleDefect.groundRust || this == PoleDefect.weldRust;
}

@immutable
class PoleFlaw {
  const PoleFlaw(this.defect, this.side);
  final PoleDefect defect;
  final PoleSide side;
  bool seenFrom(PoleSide s) => !defect.heardOnly && (defect.allSides || side == s);
}

@immutable
class PoleCase {
  const PoleCase({required this.id, required this.kind, required this.flaws, this.rail = false});
  final String id;
  final PoleKind kind;
  final List<PoleFlaw> flaws;

  /// Steel: a rail / H-beam pole instead of a tube.
  final bool rail;
  bool get condemned => flaws.isNotEmpty;
  bool has(PoleDefect d) => flaws.any((f) => f.defect == d);
  bool get soundsBad => flaws.any((f) => f.defect.soundsBad);
}

abstract final class PoleLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const titlePcc = '৩৬০° পোল পাঠ';
  static const titleSteel = 'স্টিলের ক্যান্সার';
  static const introPcc = 'চারটে পিসিসি পোলে আজ কাজ — কোনটা ভেতরে ভাঙা? ওঠার আগে পোলের ভাষা পড়ুন!';
  static const introSteel = 'স্টিলের পোলে মরিচা লুকিয়ে থাকে! চারটে পোল — ওঠার আগে প্রতিটা পড়ুন।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];
  static const ask = 'পোলটা পড়ুন। উঠবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The hands-on tools (labels a worker would read on a button).
  static const walk = 'ঘুরে দেখুন';
  static const look = 'কাছ থেকে দেখুন';
  static const tap = 'ঠুকে দেখুন';
  static const poleLabel = 'পোল';
  static const lensLabel = 'লেন্স';
  static const lensClose = 'বন্ধ';
  static const climb = 'উঠব';
  static const report = 'উঠব না — রিপোর্ট';
  static const front = 'সামনে';
  static const back = 'পেছনে';

  // What the hammer says (the sound only, never its meaning).
  static const solid = 'ঠক্ ঠক্';
  static const hollow = 'দপ্ দপ্';
  static const ring = 'টন টন';
  static const dull = 'ঠপ্ ঠপ্';

  static const stampReport = 'রিপোর্ট';
  static const stampClimb = 'উঠুন';
  static const told = 'সুপারভাইজারকে জানানো হলো';

  // The reasons (lesson 1.3): the right ones fit what this pole had. Every
  // card is 36–40 letters, so none stands out by its length.
  static const whyClimb = 'কেন উঠলেন?';
  static const whyReport = 'কেন উঠলেন না?';
  static const soundPcc = [
    'নিরেট ঠক্ ঠক্ শব্দ, গায়ে কোনো ফাটল নেই',
    'চারপাশ, গোড়া আর শব্দ — সবই ঠিক পেয়েছি',
    'নিজে পরীক্ষা করে তবেই পোলকে ভরসা করেছি',
  ];
  static const soundSteel = [
    'পরিষ্কার টন টন শব্দ, কোথাও মরিচা নেই',
    'চারপাশ, গোড়া আর শব্দ — সবই ঠিক পেয়েছি',
    'নিজে পরীক্ষা করে তবেই পোলকে ভরসা করেছি',
  ];

  /// Why not to climb a pole with [d]. On a report the wrong cards are the
  /// other faults' reasons: true in the lesson, wrong for this pole.
  static List<String> defectWhy(PoleDefect d) => switch (d) {
        PoleDefect.hairline => const ['ফাটল দিয়ে জল ঢুকে ভেতরের রডে মরিচা ধরে', 'চুলের মতো ফাটলই বড় বিপদের প্রথম লক্ষণ'],
        PoleDefect.spalling => const ['কংক্রিট খসে রড বেরিয়ে, শক্তি প্রায় শেষ', 'রড বেরোনো মানে পোলের শক্তি প্রায় শেষ'],
        PoleDefect.erosion => const ['গোড়ায় মাটি ক্ষয়ে গর্ত, জলও জমে আছে', 'ভিত্তিই পোলের শক্তি, সেটাই ক্ষয়ে গেছে'],
        PoleDefect.lean => const ['হেলা পোল শরীরের ভারে ভেঙে পড়তে পারে', 'হেলা পোল হঠাৎ সোজা হয়ে তার ছিঁড়তে পারে'],
        PoleDefect.hollow => const ['ঠুকলে দপ্ দপ্, ভেতরের কংক্রিট দুর্বল', 'ফাঁপা শব্দ মানেই পোলের কাঠামো দুর্বল'],
        PoleDefect.groundRust => const ['মাটির কাছে মরিচা, হঠাৎ ভেঙে পড়তে পারে', 'ঠুকলে ভোঁতা শব্দ, মরিচার স্তর খসে পড়ে'],
        PoleDefect.weldRust => const ['ওয়েল্ডিং জয়েন্টে মরিচা, সেখানেই বিপদ', 'জোড়ে মরিচা মানে স্টিলের ক্যান্সার ধরেছে'],
        PoleDefect.bent => const ['পোল বেঁকে গেছে, স্টিলের পোলও ভেঙে পড়ে', 'বাঁকা-মোচড়ানো পোল বিপদের স্পষ্ট লক্ষণ'],
        PoleDefect.insulator => const ['ভাঙা ইনসুলেটরে কারেন্ট লিক করতে পারে', 'পুরো পোলটাই বিদ্যুতায়িত হয়ে যেতে পারে'],
        PoleDefect.crossArm => const ['আলগা ক্রস-আর্ম ঘুরে বা ভেঙে পড়তে পারে', 'ক্রস-আর্ম আলগা হয়ে হেলে আছে, ভরসা নেই'],
      };

  /// The lesson's myths: wrong reasons to climb.
  static const mythsPcc = [
    'সিমেন্টের পোলে চুলের মতো ফাটল তো থাকেই',
    'নতুন দেখতে পোল কখনোই দুর্বল হতে পারে না',
    'পোল একটু হেলে থাকলে তাতে কিছু হয় না',
    'বাইরে ঠিক দেখালে পোলের ভেতরও ঠিক থাকে',
    'ঠুকে শোনার দরকার নেই, চোখে দেখাই যথেষ্ট',
  ];
  static const mythsSteel = [
    'স্টিলের পোল শুধু বাঁকে, কখনো ভাঙে না',
    'একটু-আধটু মরিচা তো সব স্টিলের পোলেই থাকে',
    'নতুন দেখতে পোল কখনোই দুর্বল হতে পারে না',
    'বাইরে ঠিক দেখালে পোলের ভেতরও ঠিক থাকে',
    'ঠুকে শোনার দরকার নেই, চোখে দেখাই যথেষ্ট',
  ];
  static List<String> myths(PoleKind k) => k == PoleKind.pcc ? mythsPcc : mythsSteel;

  /// The right reasons for what [p] had.
  static List<String> whyRight(PoleCase p) => p.condemned ? defectWhy(p.flaws.first.defect) : (p.kind == PoleKind.pcc ? soundPcc : soundSteel);

  /// The wrong cards for [p]'s deck. A sound pole was climbed: the myths
  /// (wrong reasons to climb). A condemned pole was reported: the reasons of
  /// the kind's other faults, which this pole did not have (wrong reasons
  /// not to climb it), so the deck asks what the player actually found.
  static List<String> whyWrong(PoleCase p) => p.condemned
      ? [
          for (final d in p.kind == PoleKind.pcc ? pccDefects : steelDefects)
            if (!p.has(d)) ...defectWhy(d),
        ]
      : myths(p.kind);

  /// The careless coworker (his recorded voice), the lesson's myths.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerAsks = [
    'ও বলছে উঠে পড়তে। আপনি কী করবেন?',
    'উঠে পড়বেন, না আগে পোলটা পড়বেন?',
    'কার কথা শুনবেন — ওর, না পোলের?',
  ];
  static const coworkerPcc = CoworkerScript(
    line: 'চুলের মতো ফাটল তো থাকেই, ওতে কিছু হয় না! উঠে পড়ো।',
    exitLine: coworkerExit,
    right: ['না, আগে পুরো পোলটা পড়ে নিই', 'ফাটলেই বিপদের শুরু, আগে দেখি', 'না দেখে কোনো পোলে উঠব না'],
    wrong: ['ঠিক, চুলের ফাটলে কিছু হয় না', 'ঠিক আছে, তাড়াতাড়ি উঠে পড়ি', 'সবাই তো এমন পোলেই উঠে যায়', 'ফাটল ছোট, উঠলে কিছু হবে না', 'আচ্ছা, তাহলে একবার উঠেই দেখি'],
    asks: coworkerAsks,
  );
  static const coworkerSteel = CoworkerScript(
    line: 'স্টিলের পোল তো শুধু বাঁকে, ভাঙে না! উঠে পড়ো।',
    exitLine: coworkerExit,
    right: ['না, আগে পুরো পোলটা পড়ে নিই', 'স্টিলের পোলও ভাঙে, আগে দেখি', 'না দেখে কোনো পোলে উঠব না'],
    wrong: ['ঠিক, স্টিলের পোল ভাঙে না', 'ঠিক আছে, তাড়াতাড়ি উঠে পড়ি', 'সবাই তো এমন পোলেই উঠে যায়', 'একটু মরিচায় কিছু হবে না', 'আচ্ছা, তাহলে একবার উঠেই দেখি'],
    asks: coworkerAsks,
  );
  static CoworkerScript coworker(PoleKind k) => k == PoleKind.pcc ? coworkerPcc : coworkerSteel;

  static const callHeld = 'ঠিক! কোনো পোলকেই না দেখে বিশ্বাস নয়।';
  static const allSet = 'পোলের ভাষা পড়তে শিখে গেছেন — চারপাশ, গোড়া, শব্দ, তারপর ওঠা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চারপাশ, গোড়া, শব্দ, ওপর।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtBack = 'পেছনের দিকের খুঁতও ধরেছেন';
  static const caughtSound = 'শব্দ শুনে ধরেছেন';
  static const caughtReport = 'বিপজ্জনক পোলে রিপোর্ট';
  static const caughtHabit = 'দেখে-শুনে তবে উঠেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static String defectBn(PoleDefect d) => switch (d) {
        PoleDefect.hairline => 'চুলের মতো ফাটল',
        PoleDefect.spalling => 'কংক্রিট খসে রড বেরিয়ে',
        PoleDefect.erosion => 'গোড়ায় মাটি ক্ষয়, জল',
        PoleDefect.lean => 'পোল হেলে আছে',
        PoleDefect.hollow => 'ভেতরটা ফাঁপা',
        PoleDefect.groundRust => 'মাটির কাছে মরিচা',
        PoleDefect.weldRust => 'জোড়ে মরিচা',
        PoleDefect.bent => 'পোল বেঁকে গেছে',
        PoleDefect.insulator => 'ভাঙা ইনসুলেটর',
        PoleDefect.crossArm => 'আলগা ক্রস-আর্ম',
      };
}

abstract final class PoleMistakes {
  static DoMistake climbed(PoleDefect d) => switch (d) {
        PoleDefect.hairline => const DoMistake(
            key: '1.3/pole/hairline',
            textBn: 'চুলের মতো ফাটল দিয়ে জল ঢোকে, ভেতরের রডে মরিচা ধরে — বড় বিপদের শুরু। রিপোর্ট করুন, উঠবেন না।',
            art: 'assets/game/art/pole/pole_crack.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.spalling => const DoMistake(
            key: '1.3/pole/spalling',
            textBn: 'কংক্রিট খসে ভেতরের রড বেরিয়ে আছে — পোলের শক্তি প্রায় শেষ।',
            art: 'assets/game/art/pole/pole_crack.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.erosion => const DoMistake(
            key: '1.3/pole/erosion',
            textBn: 'গোড়ার মাটি ক্ষয়ে গর্ত, জল জমেছে — পোলের ভিত্তিই তার আসল শক্তি।',
            art: 'assets/game/art/pole/pole_base.svg',
            deadly: true,
            lessonPoint: 0),
        PoleDefect.lean => const DoMistake(
            key: '1.3/pole/lean',
            textBn: 'পোল হেলে আছে — আপনার ভারে ভেঙে পড়তে পারে, বা হঠাৎ সোজা হয়ে তার ছিঁড়তে পারে।',
            art: 'assets/game/art/pole/pole_base.svg',
            deadly: true,
            lessonPoint: 0),
        PoleDefect.hollow => const DoMistake(
            key: '1.3/pole/hollow',
            textBn: 'ঠুকলে ফাঁপা ‘দপ্’ শব্দ — ভেতরের কংক্রিট দুর্বল, ফাঁপা। বাইরে ঠিক দেখালেও উঠবেন না।',
            art: 'assets/game/art/pole/pole_sound.svg',
            deadly: true,
            lessonPoint: 1),
        PoleDefect.groundRust => const DoMistake(
            key: '1.3/pole/ground-rust',
            textBn: 'মাটির কাছে মরিচা — স্টিলের ক্যান্সার। স্টিলের পোলও সতর্কবার্তা ছাড়াই ভেঙে পড়ে।',
            art: 'assets/game/art/pole/steel_rust.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.weldRust => const DoMistake(
            key: '1.3/pole/weld-rust',
            textBn: 'ওয়েল্ডিং জয়েন্টে মরিচা — মরিচা স্টিলের ক্যান্সার, যেখানে দেখবেন সেখানেই বিপদ লুকিয়ে থাকতে পারে।',
            art: 'assets/game/art/pole/steel_rust.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.bent => const DoMistake(
            key: '1.3/pole/bent',
            textBn: 'পোল বেঁকে বা মুচড়ে গেছে — বিপদের লক্ষণ। স্টিলের পোল শুধু বাঁকে না, ভেঙেও পড়ে।',
            art: 'assets/game/art/pole/pole_base.svg',
            deadly: true,
            lessonPoint: 2),
        PoleDefect.insulator => const DoMistake(
            key: '1.3/pole/insulator',
            textBn: 'ইনসুলেটর ভাঙা — কারেন্ট লিক করে পুরো পোল বিদ্যুতায়িত হতে পারে।',
            art: 'assets/game/art/pole/pole_hardware.svg',
            deadly: true,
            lessonPoint: 3),
        PoleDefect.crossArm => const DoMistake(
            key: '1.3/pole/cross-arm',
            textBn: 'ক্রস-আর্ম আলগা — আপনার ভারে ঘুরে যেতে বা ভেঙে পড়তে পারে।',
            art: 'assets/game/art/pole/pole_hardware.svg',
            deadly: true,
            lessonPoint: 3),
      };

  static const skipped = DoMistake(
    key: '1.3/pole/skipped-check',
    textBn: 'পোলটা ঠিক ছিল — কিন্তু না দেখেই উঠলেন। চারপাশ ঘুরুন, গোড়া দেখুন, ঠুকে শুনুন — তারপর উঠুন।',
    art: 'assets/game/art/pole/check_first.svg',
    lessonPoint: 0,
  );
  static const falseReport = DoMistake(
    key: '1.3/pole/false-report',
    textBn: 'এই পোলটা ঠিক ছিল — চারপাশ, গোড়া, শব্দ, ওপর সব ঠিক। দেখে-শুনে সিদ্ধান্ত নিন।',
    art: 'assets/game/art/pole/check_first.svg',
    lessonPoint: 1,
  );
  static List<DoMistake> get all => [for (final d in PoleDefect.values) climbed(d), skipped, falseReport];
}

const pccDefects = [PoleDefect.hairline, PoleDefect.spalling, PoleDefect.erosion, PoleDefect.lean, PoleDefect.hollow, PoleDefect.insulator, PoleDefect.crossArm];
const steelDefects = [PoleDefect.groundRust, PoleDefect.weldRust, PoleDefect.bent, PoleDefect.insulator, PoleDefect.crossArm];

@immutable
class PoleDeal {
  const PoleDeal({required this.poles, required this.callPole});
  final List<PoleCase> poles;

  /// The pole on which the careless coworker comes: any pole, sound or
  /// condemned, so his coming does not tell the answer.
  final int callPole;
}

/// Four poles: 2–3 condemned, at least one whose fault hides (on the back or
/// heard only), the rest sound; the main fault of the kind comes first-class.
PoleDeal dealPoles(math.Random rng, PoleKind kind) {
  final pool = kind == PoleKind.pcc ? pccDefects : steelDefects;
  final bad = 2 + rng.nextInt(2);
  final picks = [...pool]..shuffle(rng);
  // The lesson's headline fault always shows up once.
  final headline = kind == PoleKind.pcc ? PoleDefect.hairline : PoleDefect.groundRust;
  picks
    ..remove(headline)
    ..insert(0, headline);
  final poles = <PoleCase>[];
  for (var i = 0; i < 4; i++) {
    final flaws = <PoleFlaw>[];
    if (i < bad) {
      final d = picks[i % picks.length];
      // The first condemned pole hides its fault on the back (if it can).
      final side = i == 0 && !d.allSides ? PoleSide.back : (rng.nextBool() ? PoleSide.front : PoleSide.back);
      flaws.add(PoleFlaw(d, side));
    }
    poles.add(PoleCase(id: 'p$i', kind: kind, flaws: flaws, rail: kind == PoleKind.steel && rng.nextInt(3) == 0));
  }
  poles.shuffle(rng);
  return PoleDeal(poles: poles, callPole: rng.nextInt(poles.length));
}

enum PoleCheck { walk, base, sound, top }

/// The play state (pure logic).
class PoleRun {
  PoleRun(this.deal);
  final PoleDeal deal;
  int index = 0;
  final Set<PoleCheck> checks = {};
  bool shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.poles.length;
  bool get ended => done || deadly != null;
  PoleCase get current => deal.poles[index.clamp(0, deal.poles.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Every check made on this pole (earns the +5 on a right call).
  bool get thorough => checks.length == PoleCheck.values.length;

  void check(PoleCheck c) {
    if (!ended && !shown) checks.add(c);
  }

  /// Climb (true) or report (false). Returns the mistake, if any. Reporting
  /// a sound pole is a slip and the pole is still to read (and climb).
  /// [pushed]: he climbs because the coworker said so; on a sound pole that
  /// is the climb-without-reading slip, however much he had checked.
  DoMistake? decide({required bool climb, bool pushed = false}) {
    if (ended || shown) return null;
    shown = true;
    final p = current;
    if (climb && p.condemned) return deadly = PoleMistakes.climbed(p.flaws.first.defect);
    if (climb && (pushed || !checks.containsAll(const [PoleCheck.walk, PoleCheck.base, PoleCheck.sound]))) {
      slips++;
      return PoleMistakes.skipped;
    }
    if (!climb && !p.condemned) {
      slips++;
      shown = false;
      return PoleMistakes.falseReport;
    }
    void tag(String t) {
      if (!caught.contains(t)) caught.add(t);
    }

    if (climb) {
      tag(PoleLines.caughtHabit);
    } else {
      tag(PoleLines.caughtReport);
      final f = p.flaws.first;
      if (f.defect.heardOnly) tag(PoleLines.caughtSound);
      if (!f.defect.allSides && !f.defect.heardOnly && f.side == PoleSide.back) tag(PoleLines.caughtBack);
    }
    return null;
  }

  void next() {
    index++;
    checks.clear();
    shown = false;
  }
}

@immutable
class PoleReadPack {
  const PoleReadPack({required this.id, required this.kind, required this.titleBn, this.quickMs = 90000});
  final String id;
  final PoleKind kind;
  final String titleBn;
  final int quickMs;
}

const poleReadPacks = {
  'do_1_3_a': PoleReadPack(id: 'do_1_3_a', kind: PoleKind.pcc, titleBn: PoleLines.titlePcc),
  'do_1_3_b': PoleReadPack(id: 'do_1_3_b', kind: PoleKind.steel, titleBn: PoleLines.titleSteel),
};

/// What a deadly climb looks like (in colour, over the frozen grey scene).
enum PoleCollapse { fall, spark, arm }

PoleCollapse collapseFor(PoleDefect d) => switch (d) {
      PoleDefect.insulator => PoleCollapse.spark,
      PoleDefect.crossArm => PoleCollapse.arm,
      _ => PoleCollapse.fall,
    };

/// Which side faces the viewer after walking [orbit] turns round the pole.
PoleSide poleSideOf(double orbit) {
  final t = orbit - orbit.floorToDouble();
  return t >= 0.25 && t < 0.75 ? PoleSide.back : PoleSide.front;
}

// ============================================================================
// Page
// ============================================================================

class PoleReadPage extends StatefulWidget {
  const PoleReadPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final PoleReadPack pack;
  final bool muted;
  final int? seed;

  @override
  State<PoleReadPage> createState() => _PoleReadPageState();
}

class _PoleReadPageState extends State<PoleReadPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PoleRunPage(
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

class _PoleRunPage extends ConsumerStatefulWidget {
  const _PoleRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final PoleReadPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PoleRunPage> createState() => _PoleRunPageState();
}

enum _Verdict { climbed, reported }

class _PoleRunPageState extends ConsumerState<_PoleRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final PoleRun _run = PoleRun(dealPoles(widget.rng, widget.pack.kind));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// Turns walked round the pole (0 = front, 0.5 = back).
  final _orbit = ValueNotifier<double>(0);
  late final AnimationController _orbitCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..addListener(_onOrbitTick)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _arrived();
    });
  double _orbitFrom = 0;
  double _orbitTo = 0;
  var _dragging = false;

  /// Walking along the road to the next pole: 0 → 1 (travel = 1 − value).
  late final AnimationController _walkIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200), value: 0)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _arrivedAtPole();
    });
  late final Listenable _sceneMotion = Listenable.merge([_orbit, _walkIn]);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
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

  /// The lens is open at this height (metres above the ground).
  double? _lens;

  /// The hammer: what it said last, and how many knocks so far (keys the swing).
  String? _knock;
  int _knocks = 0;
  int _wake = 0;
  _Verdict? _verdict;

  /// After a paid report reason: the ring names the fault.
  var _revealed = false;
  var _coworkerArmed = false;

  /// A deadly climb: the scene freezes in grey while the pole goes, in colour.
  var _freeze = false;
  Completer<void>? _frozen;
  PoleCollapse _collapse = PoleCollapse.fall;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _pcc => widget.pack.kind == PoleKind.pcc;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  bool get _moving => _dragging || _orbitCtl.isAnimating || _walkIn.isAnimating;

  @override
  void dispose() {
    disposeCoworker();
    _orbitCtl.dispose();
    _walkIn.dispose();
    _orbit.dispose();
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

  /// After the guide's intro: the clock runs and the trainee walks to the first pole.
  Future<void> _start() async {
    _clock.start();
    _walkToPole();
  }

  bool get _canPlay =>
      !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && _lens == null && !_moving;

  void _afterCheck(PoleCheck c) => _run.check(c);

  // --- walking: along the road, and round the pole ----------------------------
  void _walkToPole() {
    setState(() {
      _orbit.value = 0;
      _knock = null;
    });
    if (_quiet) {
      _walkIn.value = 1;
      _arrivedAtPole();
    } else {
      unawaited(_walkIn.forward(from: 0));
    }
  }

  void _arrivedAtPole() {
    if (!mounted || _ended) return;
    setState(() => _wake++);
    // The coworker comes once, on his pole: armed on arrival, he walks in a
    // moment later, as soon as the player has made a first check (so a quick
    // decision does not slip past him).
    if (!_coworkerArmed && _run.index == _run.deal.callPole) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
    unawaited(_sayChain([PoleLines.ask]));
  }

  void _onOrbitTick() {
    final k = Curves.easeInOut.transform(_orbitCtl.value);
    _orbit.value = _orbitFrom + (_orbitTo - _orbitFrom) * k;
  }

  void _orbitTowards(double target, int ms) {
    _orbitFrom = _orbit.value;
    _orbitTo = target;
    if (_quiet || (target - _orbitFrom).abs() < 0.002) {
      _orbit.value = target;
      _arrived();
      return;
    }
    _orbitCtl.duration = Duration(milliseconds: ms);
    setState(() {});
    unawaited(_orbitCtl.forward(from: 0));
  }

  void _arrived() {
    if (!mounted) return;
    final o = _orbit.value;
    _orbit.value = o - o.floorToDouble();
    setState(() => _wake++);
    if (poleSideOf(_orbit.value) == PoleSide.back) _afterCheck(PoleCheck.walk);
  }

  /// The walk button: go round to the other side.
  void _walkRound() {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.3, muted: false));
    setState(() => _knock = null);
    _orbitTowards((_orbit.value * 2).roundToDouble() / 2 + 0.5, 1100);
  }

  void _dragStart(DragStartDetails _) {
    if (!_canPlay) return;
    setState(() {
      _dragging = true;
      _knock = null;
    });
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _orbit.value -= d.delta.dx / 380;
  }

  void _dragEnd() {
    if (!_dragging) return;
    _dragging = false;
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/rush_in.wav', volume: 0.25, muted: false));
    _orbitTowards((_orbit.value * 2).roundToDouble() / 2, 420);
  }

  // --- looking close: the lens ---------------------------------------------------
  void _tapScene(Offset p, PoleGeo geo) {
    if (!_canPlay) return;
    final half = 30 * geo.s + 14;
    if ((p.dx - PoleGeo.cx).abs() > half * 1.8 || p.dy < geo.y(9.6) || p.dy > geo.groundY + 30) return;
    _openLens(geo.m(p.dy));
  }

  void _openLens(double metres) {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.4, muted: false));
    setState(() {
      _lens = metres.clamp(0.25, 9.0);
      _knock = null;
    });
    _lensCheck();
  }

  void _moveLens(double metres) {
    if (_lens == null) return;
    setState(() => _lens = metres.clamp(0.25, 9.0));
    _lensCheck();
  }

  void _lensCheck() {
    final m = _lens;
    if (m == null) return;
    if (m <= 1.4) _afterCheck(PoleCheck.base);
    if (m >= 7.6) _afterCheck(PoleCheck.top);
  }

  void _closeLens() {
    if (_lens == null) return;
    setState(() => _lens = null);
  }

  // --- the hammer ---------------------------------------------------------------
  void _knockPole() {
    if (!_canPlay) return;
    final bad = _run.current.soundsBad;
    HapticFeedback.mediumImpact();
    final cue = _pcc ? (bad ? 'sounds/learn/knock_hollow.wav' : 'sounds/learn/knock_solid.wav') : (bad ? 'sounds/learn/dull_steel.wav' : 'sounds/learn/ring_steel.wav');
    if (!_muted) unawaited(ZlFx.cue(cue, volume: 0.9, muted: false));
    setState(() {
      _knocks++;
      _wake++;
      _knock = _pcc ? (bad ? PoleLines.hollow : PoleLines.solid) : (bad ? PoleLines.dull : PoleLines.ring);
    });
    _afterCheck(PoleCheck.sound);
  }

  // --- the decision ---------------------------------------------------------------
  Future<void> _decide(bool climb, Offset origin, {bool pushed = false}) async {
    if (!_canPlay) return;
    _hush();
    final m = _run.decide(climb: climb, pushed: pushed);
    HapticFeedback.mediumImpact();
    if (m == null) {
      // Right: stamp, the ◆ wait on the table, then "কেন …?".
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.7, muted: false));
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      }
      setState(() {
        _verdict = climb ? _Verdict.climbed : _Verdict.reported;
        _knock = null;
        _wake++;
      });
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final p = _run.current;
      final idx = _run.index;
      // The fault is not shown yet: the reason deck asks what he found.
      unawaited(askReason(
        deal: () => dealChoices(PoleLines.whyRight(p), PoleLines.whyWrong(p), widget.rng),
        question: climb ? PoleLines.whyClimb : PoleLines.whyReport,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() => _knock = null);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  /// Next pole (or the result) — by itself, after the reason or the slip card.
  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _verdict = null;
      _revealed = false;
      _lens = null;
    });
    _walkToPole();
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
    final p = _run.current;
    if (_verdict != _Verdict.reported || !p.condemned) {
      _next();
      return;
    }
    // A report paid: now show what he caught. He walks round to the fault's
    // side, the red ring names it, then the next pole comes by itself.
    final idx = _run.index;
    final f = p.flaws.first;
    var walk = 0;
    if (!f.defect.allSides && !f.defect.heardOnly && poleSideOf(_orbit.value) != f.side) {
      _orbitTowards((_orbit.value * 2).roundToDouble() / 2 + 0.5, 900);
      walk = _quiet ? 0 : 950;
    }
    bool still() => mounted && !_ended && _run.index == idx;
    unawaited(() async {
      if (walk > 0) await Future<void>.delayed(Duration(milliseconds: walk));
      if (!still()) return;
      setState(() => _revealed = true);
      await Future<void>.delayed(Duration(milliseconds: _quiet ? 700 : 1600));
      if (still()) _next();
    }());
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => PoleLines.coworker(widget.pack.kind);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callPole || _run.shown) return null;
    if (_intro || _busy || _card != null || reasonOpen || _lens != null || _moving || _run.checks.isEmpty) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: up the pole on his say-so (deadly on a condemned
      // pole, the climb-without-reading slip on a sound one).
      await _decide(true, origin, pushed: true);
      return;
    }
    _run.caught.add(PoleLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([PoleLines.callHeld, PoleLines.ask], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? PoleLines.tapWhy[_nudgeN++ % PoleLines.tapWhy.length]
            : _nudge.next(PoleLines.ask);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
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
    final speak = await SpokenOnce.first('pole/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly climb: the trainee goes up, the roadside freezes grey and the
  /// pole gives way in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    final d = _run.current.flaws.first.defect;
    _collapse = collapseFor(d);
    if (!_muted) {
      unawaited(ZlFx.cue(_collapse == PoleCollapse.spark ? 'sounds/learn/spark.wav' : 'sounds/learn/stomp.wav', volume: 0.9, muted: false));
    }
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _lens = null;
      _knock = null;
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
    final speak = await SpokenOnce.first('pole/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? PoleLines.deadlyWord : PoleLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        if (_run.shown) {
          _next();
        } else {
          // A false report: this pole is still to read.
          unawaited(_sayChain([PoleLines.ask]));
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
    await _say(!_run.passed ? PoleLines.fail : (_quickBonus ? PoleLines.quick : PoleLines.allSet),
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
  /// The trainee's pose now.
  LinemanMode get _mode {
    if (_moving) return LinemanMode.walk;
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_verdict == _Verdict.climbed) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  /// The trainee beside the pole: his hammer reaches the pole at waist height.
  static Rect traineeBox(PoleCase p, PoleGeo geo) {
    final h = 1.95 * geo.ppm;
    final w = h / 2;
    final grip = LinemanFigure.tipOf(LinemanMode.hold, Carry.none, Size(w, h));
    final gripY = geo.groundY - h + grip.dy;
    final reach = PolePainter.halfAt(p, geo, gripY) + _Hammer.length(geo) * 0.96;
    return Rect.fromLTWH(PoleGeo.cx - reach - grip.dx, geo.groundY - h, w, h);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = PoleGeo.forScene(m.height, m.inset);
    final p = _run.current;
    final orbit = _orbit.value;
    final travel = 1 - _walkIn.value;
    final slide = travel * 300;
    final quiet = _quiet;
    final tb = traineeBox(p, geo);
    final grip = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final hit = Offset(PoleGeo.cx - PolePainter.halfAt(p, geo, grip.dy), grip.dy);
    final prev = _run.index > 0 && travel > 0 ? _run.deal.poles[_run.index - 1] : null;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final reveal = _run.shown && !_freeze;
    final named = reveal && _revealed;
    // Where the corner guide's bubble starts (design px), and the stamp above it.
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final k = 360 / math.max(1.0, size.width);
    final deckUp = reasonOpen || coworkerChoiceUp;
    final guideTop = (size.height - pad.bottom - (deckUp ? 236 : 72) - 116 - 96) * k;
    final stampTop = math.max(math.min(geo.y(6.9), guideTop - _stampH), (pad.top + 134) * k);
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: ColorFiltered(
          colorFilter: grey,
          child: RepaintBoundary(child: CustomPaint(painter: PoleYardPainter(geo: geo, orbit: orbit, travel: travel))),
        ),
      ),
      // The pole (hidden while it gives way: that is drawn in colour on top).
      if (!_freeze)
        Positioned.fill(
          key: ValueKey('pole-${_run.index}'),
          child: CustomPaint(
            painter: PolePainter(pole: p, geo: geo, orbit: orbit, dx: slide, prev: prev, prevDx: slide - 300),
          ),
        ),
      // The trainee with his hammer.
      if (!_freeze)
        Positioned.fromRect(
          key: const ValueKey('trainee'),
          rect: tb,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      if (!_freeze && _mode == LinemanMode.hold)
        Positioned(
          key: const ValueKey('hammer'),
          left: grip.dx - 40,
          top: grip.dy - 40,
          width: 80,
          height: 80,
          child: IgnorePointer(
            // It swings only for the knock just made (its word still up), not
            // each time it comes back after a walk or a card.
            child: _HammerSwing(key: ValueKey('swing-$_knocks'), swing: _knock != null, len: _Hammer.length(geo), quiet: quiet),
          ),
        ),
      if (_knock != null && !_freeze) ...[
        Positioned(
          key: const ValueKey('knock-ring'),
          left: hit.dx - 40,
          top: hit.dy - 40,
          width: 80,
          height: 80,
          child: IgnorePointer(
            child: _KnockRipple(key: ValueKey('ripple-$_knocks'), flakes: !_pcc && p.soundsBad, quiet: quiet),
          ),
        ),
        Positioned(
          key: const ValueKey('knock-word'),
          left: PoleGeo.cx + 30 * geo.s + 8,
          top: hit.dy - 46,
          child: IgnorePointer(child: _KnockWord(key: ValueKey('word-$_knocks'), text: _knock!, quiet: quiet)),
        ),
      ],
      // After the decision: where the fault was, the stamp, the report.
      // (The ring and its name only once the reason is paid: the deck asks.)
      if (named)
        for (final (i, f) in p.flaws.indexed)
          Positioned.fromRect(
            key: ValueKey('reveal-$i'),
            rect: _zoneRect(f.defect.zone, geo),
            child: IgnorePointer(
              child: _RevealRing(
                text: '${PoleLines.defectBn(f.defect)}${f.defect.allSides || f.defect.heardOnly ? '' : ' · ${f.side == PoleSide.front ? PoleLines.front : PoleLines.back}'}',
                // At the base the name goes under the ring, clear of the guide's bubble.
                below: f.defect.zone == PoleZone.base,
                quiet: quiet,
              ),
            ),
          ),
      // The stamp, then the told-chip under it, right of the pole: kept above
      // the corner guide's bubble (it rises with the deck on short phones).
      if (reveal && _verdict != null)
        AnimatedPositioned(
          key: ValueKey('stamp-${_run.index}'),
          duration: Duration(milliseconds: quiet ? 1 : 280),
          curve: Curves.easeOutCubic,
          left: PoleGeo.cx + 50 * geo.s,
          width: 160,
          top: stampTop,
          child: IgnorePointer(child: _StampPop(text: _verdict == _Verdict.reported ? PoleLines.stampReport : PoleLines.stampClimb, quiet: quiet)),
        ),
      if (reveal && _verdict == _Verdict.reported && stampTop + _stampH + _chipH <= guideTop)
        Positioned(
          key: const ValueKey('told'),
          right: 8,
          top: stampTop + _stampH,
          child: IgnorePointer(child: _ToldChip(quiet: quiet)),
        ),
      // Swipe round the pole; tap it to look close.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: PoleLines.poleLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onHorizontalDragStart: _dragStart,
            onHorizontalDragUpdate: _dragUpdate,
            onHorizontalDragEnd: (_) => _dragEnd(),
            onHorizontalDragCancel: _dragEnd,
          ),
        ),
      ),
      // The deadly climb, in colour over the grey roadside.
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('collapse'),
          child: IgnorePointer(child: _CollapseView(kind: _collapse, pole: p, geo: geo, orbit: orbit, quiet: quiet)),
        ),
    ];
  }

  /// The stamp's and the told-chip's heights (design px), for placing them.
  static const _stampH = 58.0;
  static const _chipH = 30.0;

  static Rect _zoneRect(PoleZone z, PoleGeo geo) {
    final s = geo.s;
    const cx = PoleGeo.cx;
    return switch (z) {
      PoleZone.base => Rect.fromLTRB(cx - 46 * s, geo.y(1.4), cx + 46 * s, geo.groundY + 22 * s),
      PoleZone.waist => Rect.fromLTRB(cx - 40 * s, geo.y(5.2), cx + 40 * s, geo.y(1.2)),
      PoleZone.top => Rect.fromLTRB(cx - 84 * s, geo.y(9.5), cx + 84 * s, geo.y(7.9)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final h = (360 * size.height / math.max(1.0, size.width)).clamp(560.0, 900.0);
    final geo = PoleGeo.forScene(h, pad.bottom * 360 / math.max(1.0, size.width));
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && _lens == null;
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
              labels: PoleLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            animation: _sceneMotion,
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 10,
                  bottom: pad.bottom + 72,
                  child: Row(
                    children: [
                      _ToolButton(icon: Icons.threesixty_rounded, label: PoleLines.walk, enabled: !_moving, onTap: _walkRound),
                      const SizedBox(width: 6),
                      _ToolButton(icon: Icons.search_rounded, label: PoleLines.look, enabled: !_moving, onTap: () => _openLens(0.7)),
                      const SizedBox(width: 6),
                      _ToolButton(icon: Icons.hardware_rounded, label: PoleLines.tap, enabled: !_moving, onTap: _knockPole),
                    ],
                  ),
                ),
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _ReportButton(onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: DoBigButton(label: PoleLines.climb, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
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
              if (_lens != null && playing)
                _Lens(
                  key: const ValueKey('lens'),
                  pole: _run.current,
                  geo: geo,
                  orbit: _orbit.value,
                  metres: _lens!,
                  quiet: quiet,
                  onMove: _moveLens,
                  onClose: _closeLens,
                ),
              if (playing && _card == null && _lens == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  line: _pcc ? PoleLines.introPcc : PoleLines.introSteel,
                  alarm: _pcc ? 'sounds/learn/knock_hollow.wav' : 'sounds/learn/dull_steel.wav',
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

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1324),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.9), width: 1.8),
          ),
          child: Text(PoleLines.report, textAlign: TextAlign.center, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.6),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: SlmColors.gold300),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The hammer in the trainee's hand: at rest it is raised a little; each tap
/// swings it twice onto the pole ("ঠক্ ঠক্").
abstract final class _Hammer {
  static double length(PoleGeo geo) => 0.42 * geo.ppm;
  static const rest = -0.6;
  static const contact = 0.06;
}

class _HammerSwing extends StatelessWidget {
  const _HammerSwing({super.key, required this.swing, required this.len, required this.quiet});

  /// A knock was just made: swing (else it rests).
  final bool swing;
  final double len;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: !swing || quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 620),
      builder: (_, t, _) {
        // Two knocks: down to the pole and back, twice.
        final u = (t * 2) % 1;
        final hitK = t >= 1 ? 0.0 : (u < 0.4 ? u / 0.4 : (1 - u) / 0.6);
        final a = _Hammer.rest + (_Hammer.contact - _Hammer.rest) * Curves.easeIn.transform(hitK.clamp(0.0, 1.0));
        return CustomPaint(painter: _HammerPainter(angle: a, len: len));
      },
    );
  }
}

class _HammerPainter extends CustomPainter {
  _HammerPainter({required this.angle, required this.len});
  final double angle;
  final double len;

  @override
  void paint(Canvas c, Size s) {
    final grip = s.center(Offset.zero);
    c.save();
    c.translate(grip.dx, grip.dy);
    c.rotate(angle);
    // Handle (wood, a rubber grip), then the steel head across its end.
    c.drawLine(Offset.zero, Offset(len, 0), Paint()
      ..color = const Color(0xFFB0834F)
      ..strokeWidth = math.max(2.4, len * 0.12)
      ..strokeCap = StrokeCap.round);
    c.drawLine(Offset.zero, Offset(len * 0.3, 0), Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = math.max(3.0, len * 0.15)
      ..strokeCap = StrokeCap.round);
    final head = Rect.fromCenter(center: Offset(len, 0), width: len * 0.32, height: len * 0.62);
    c.drawRRect(
      RRect.fromRectAndRadius(head, Radius.circular(len * 0.05)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9AA3AB), Color(0xFF5E676F)]).createShader(head),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_HammerPainter old) => old.angle != angle || old.len != len;
}

/// Rings out of the knock on the pole; on rusted steel, rust flakes fall.
class _KnockRipple extends StatelessWidget {
  const _KnockRipple({super.key, required this.flakes, required this.quiet});
  final bool flakes;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (_, t, _) => CustomPaint(painter: _RipplePainter(t: t, flakes: flakes)),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.t, required this.flakes});
  final double t;
  final bool flakes;

  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    if (t < 1) {
      for (final d in const [0.0, 0.25]) {
        final k = ((t - d) / 0.6).clamp(0.0, 1.0);
        if (k <= 0 || k >= 1) continue;
        c.drawArc(
          Rect.fromCircle(center: o, radius: 6 + 22 * k),
          math.pi * 0.6,
          math.pi * 0.8,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: 0.85 * (1 - k)),
        );
      }
    }
    if (flakes) {
      // Rust flakes fall from the knock and rest at the bottom.
      final fall = Curves.easeIn.transform(t);
      final p = Paint()..color = const Color(0xFFA0522D);
      for (final (dx, w, sp) in const [(-4.0, 3.0, 1.0), (2.0, 2.4, 0.8), (-1.0, 2.0, 1.15), (5.0, 2.6, 0.9)]) {
        c.drawRect(Rect.fromCenter(center: o + Offset(dx - 6, 4 + 34 * fall * sp), width: w, height: w * 0.7), p);
      }
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.flakes != flakes;
}

/// What the hammer said, popped once beside the pole.
class _KnockWord extends StatelessWidget {
  const _KnockWord({super.key, required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: t, alignment: Alignment.centerLeft, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: SlmColors.ivory,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Text(text, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ink)),
      ),
    );
  }
}

/// After the decision: a red ring where the fault was, with its name.
class _RevealRing extends StatelessWidget {
  const _RevealRing({required this.text, required this.quiet, this.below = false});
  final String text;
  final bool quiet;

  /// The name under the ring (else on its top edge).
  final bool below;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.scale(scale: 0.8 + 0.2 * t, child: child)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: SlmColors.danger, width: 3)),
        alignment: below ? Alignment.bottomCenter : Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(0, below ? 13 : -13),
          child: OverflowBox(
            maxWidth: 280,
            alignment: below ? Alignment.bottomCenter : Alignment.topCenter,
            maxHeight: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
              child: Text(text, maxLines: 1, softWrap: false, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
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
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.8 - 0.8 * t, child: child)),
      ),
      child: Center(child: DoStamp(text: text, good: true)),
    );
  }
}

class _ToldChip extends StatelessWidget {
  const _ToldChip({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(-20 * (1 - t), 0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xE60B1324), borderRadius: BorderRadius.circular(10), border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_in_talk_rounded, size: 14, color: SlmColors.gold300),
            const SizedBox(width: 5),
            Text(PoleLines.told, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
          ],
        ),
      ),
    );
  }
}

/// A close look: a big lens over the dimmed scene, centred on [metres] up the
/// pole, seen from the side the player stands on. Drag up or down (on the lens
/// or the scale beside it) to scan from the base to the top.
class _Lens extends StatelessWidget {
  const _Lens({
    super.key,
    required this.pole,
    required this.geo,
    required this.orbit,
    required this.metres,
    required this.quiet,
    required this.onMove,
    required this.onClose,
  });
  final PoleCase pole;
  final PoleGeo geo;
  final double orbit;
  final double metres;
  final bool quiet;
  final ValueChanged<double> onMove;
  final VoidCallback onClose;

  /// Metres of pole the lens shows top to bottom (wide enough for the
  /// insulators at both ends of the cross-arm).
  static const span = 3.4;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final d = math.min(300.0, size.width - 92);
    final cy = size.height * 0.44;
    final left = (size.width - d) / 2 - 18;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xC4050A16),
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: cy - d / 2,
                width: d,
                height: d,
                child: Semantics(
                  label: PoleLines.lensLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    // The lens moves with the finger, as on the scale: drag
                    // down to look lower, up to look higher.
                    onVerticalDragUpdate: (e) => onMove(metres - e.delta.dy * span / d),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      builder: (_, t, child) => Transform.scale(scale: 0.7 + 0.3 * t, child: child),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: SlmColors.gold300, width: 6),
                          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 20)],
                        ),
                        child: ClipOval(child: CustomPaint(painter: _LensPainter(pole: pole, geo: geo, orbit: orbit, metres: metres), size: Size.infinite)),
                      ),
                    ),
                  ),
                ),
              ),
              // The scale: the whole pole, and where the lens is on it.
              Positioned(
                left: left + d + 14,
                top: cy - d / 2,
                width: 36,
                height: d,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  onVerticalDragUpdate: (e) => onMove((1 - e.localPosition.dy / d) * 9.4 - 0.2),
                  onTapDown: (e) => onMove((1 - e.localPosition.dy / d) * 9.4 - 0.2),
                  child: CustomPaint(painter: _ScalePainter(metres: metres)),
                ),
              ),
              Positioned(
                left: left + d - 40,
                top: cy - d / 2 - 6,
                child: Semantics(
                  button: true,
                  label: PoleLines.lensClose,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: SlmColors.navy900, border: Border.all(color: SlmColors.gold300, width: 2)),
                      child: const Icon(Icons.close_rounded, color: SlmColors.ivory, size: 24),
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

class _LensPainter extends CustomPainter {
  _LensPainter({required this.pole, required this.geo, required this.orbit, required this.metres});
  final PoleCase pole;
  final PoleGeo geo;
  final double orbit;
  final double metres;

  @override
  void paint(Canvas c, Size s) {
    final z = s.height / (_Lens.span * geo.ppm);
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.scale(z);
    c.translate(-PoleGeo.cx, -geo.y(metres));
    PoleYardPainter(geo: geo, orbit: orbit).paint(c, Size(360, geo.height));
    PolePainter(pole: pole, geo: geo, orbit: orbit, close: true).paint(c, Size(360, geo.height));
    c.restore();
  }

  @override
  bool shouldRepaint(_LensPainter old) => old.metres != metres || old.orbit != orbit || old.pole != pole;
}

class _ScalePainter extends CustomPainter {
  _ScalePainter({required this.metres});
  final double metres;

  @override
  void paint(Canvas c, Size s) {
    double y(double m) => s.height * (1 - (m + 0.2) / 9.4);
    final cx = s.width / 2;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 9, 0, 18, s.height), const Radius.circular(9)),
      Paint()..color = const Color(0x66FFFFFF),
    );
    // The pole in miniature, its ground and cross-arm.
    c.drawRect(Rect.fromLTRB(cx - 3, y(9), cx + 3, y(0)), Paint()..color = const Color(0xFFBDBAB1));
    c.drawRect(Rect.fromLTRB(cx - 11, y(8.45), cx + 11, y(8.35)), Paint()..color = const Color(0xFF5F676F));
    c.drawRect(Rect.fromLTRB(cx - 14, y(0), cx + 14, y(0) + 2), Paint()..color = const Color(0xFF9E7E55));
    // Where the lens looks.
    final top = y(metres + _Lens.span / 2);
    final bot = y(metres - _Lens.span / 2);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(cx - 16, top, cx + 16, bot), const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = SlmColors.gold300,
    );
    final arrow = Paint()..color = SlmColors.gold300;
    c.drawPath(Path()..moveTo(cx, top - 10)..lineTo(cx - 6, top - 3)..lineTo(cx + 6, top - 3)..close(), arrow);
    c.drawPath(Path()..moveTo(cx, bot + 10)..lineTo(cx - 6, bot + 3)..lineTo(cx + 6, bot + 3)..close(), arrow);
  }

  @override
  bool shouldRepaint(_ScalePainter old) => old.metres != metres;
}

/// The deadly climb: the trainee is on the pole and it gives way — falls,
/// sparks (a broken insulator) or loses its cross-arm — in colour.
class _CollapseView extends StatelessWidget {
  const _CollapseView({required this.kind, required this.pole, required this.geo, required this.orbit, required this.quiet});
  final PoleCollapse kind;
  final PoleCase pole;
  final PoleGeo geo;
  final double orbit;
  final bool quiet;

  /// Where the climber's hands grip: the pole's side (a fall, a shock), or
  /// the cross-arm's low end (he is up at the top for the work).
  static Offset handsFor(PoleCollapse kind, PoleCase pole, PoleGeo geo, double orbit) {
    const cx = PoleGeo.cx;
    switch (kind) {
      case PoleCollapse.fall:
      case PoleCollapse.spark:
        final y = geo.y(kind == PoleCollapse.fall ? 3.0 : 2.9);
        return Offset(cx - PolePainter.halfAt(pole, geo, y) + 1, y);
      case PoleCollapse.arm:
        final turn = math.cos(2 * math.pi * orbit);
        final f = turn.abs() < 0.15 ? 0.15 * (turn < 0 ? -1 : 1) : turn;
        final tilt = pole.has(PoleDefect.crossArm) ? 0.2 : 0.0;
        final u = f > 0 ? -0.3 : 0.3;
        final reach = 64 * geo.s;
        return Offset(cx + reach * f * u * math.cos(tilt), geo.y(8.4) - reach * u * math.sin(tilt) + 4 * geo.s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = 1.95 * geo.ppm;
    final box = Size(h / 2, h);
    final grip = LinemanFigure.tipOf(LinemanMode.hold, Carry.none, box);
    final hands = handsFor(kind, pole, geo, orbit);
    final on = (hands - grip) & box;
    // Up the pole: hands on it, swung in about the hands so his feet are on
    // the pole too (climbing it, not floating beside it).
    final figure = Transform.rotate(
      angle: -0.34,
      origin: grip - box.center(Offset.zero),
      child: LinemanFigure(look: LinemanLook.trainee, mode: LinemanMode.hold, quiet: true),
    );
    final ax = PoleGeo.cx;
    final ya = geo.y(8.4);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1900),
      builder: (_, t, _) {
        final fall = kind == PoleCollapse.fall ? 0.62 * Curves.easeInCubic.transform(((t - 0.15) / 0.85).clamp(0.0, 1.0)) : 0.0;
        final drop = kind == PoleCollapse.arm ? Curves.easeInCubic.transform(((t - 0.2) / 0.8).clamp(0.0, 1.0)) : 0.0;
        // On a loose arm he goes down with it as it turns, then slips off.
        final climber = Positioned.fromRect(
          rect: on,
          child: drop == 0
              ? figure
              : Transform(
                  transform: Matrix4.identity()
                    ..translateByDouble(ax - on.left, ya - on.top + 2.2 * geo.ppm * drop * drop, 0, 1)
                    ..rotateZ(-0.9 * drop)
                    ..translateByDouble(on.left - ax, on.top - ya, 0, 1),
                  child: figure,
                ),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: Transform(
                transform: Matrix4.identity()
                  ..translateByDouble(PoleGeo.cx, geo.groundY, 0, 1)
                  ..rotateZ(fall)
                  ..translateByDouble(-PoleGeo.cx, -geo.groundY, 0, 1),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: PolePainter(pole: pole, geo: geo, orbit: orbit, armDrop: drop))),
                    climber,
                  ],
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _CollapseFx(kind: kind, t: t, geo: geo, orbit: orbit, hands: hands))),
          ],
        );
      },
    );
  }
}

class _CollapseFx extends CustomPainter {
  _CollapseFx({required this.kind, required this.t, required this.geo, required this.orbit, required this.hands});
  final PoleCollapse kind;
  final double t;
  final PoleGeo geo;
  final double orbit;

  /// Where the climber holds on (the shock goes into his hands).
  final Offset hands;

  @override
  void paint(Canvas c, Size size) {
    final s = geo.s;
    const cx = PoleGeo.cx;
    final g = geo.groundY;
    switch (kind) {
      case PoleCollapse.fall:
        // The base cracks open, then dust bursts as it goes.
        final k = (t / 0.4).clamp(0.0, 1.0);
        final crack = Paint()
          ..color = const Color(0xFFE2463A)
          ..strokeWidth = 2.4 * s
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (final (a, l) in const [(-2.3, 1.0), (-1.7, 0.8), (-1.2, 1.1), (-0.6, 0.7)]) {
          final o = Offset(cx, g - 6 * s);
          final e = o + Offset(math.cos(a), math.sin(a)) * 46 * s * l * k;
          final mid = Offset.lerp(o, e, 0.5)! + Offset(4 * s, 0);
          c.drawPath(Path()..moveTo(o.dx, o.dy)..lineTo(mid.dx, mid.dy)..lineTo(e.dx, e.dy), crack);
        }
        final dust = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
        if (dust > 0) {
          final p = Paint()..color = Color.fromRGBO(196, 170, 128, 0.7 * (1 - dust));
          for (final (dx, r) in const [(-30.0, 16.0), (-8.0, 22.0), (18.0, 18.0), (40.0, 14.0)]) {
            c.drawCircle(Offset(cx + dx * s * (1 + dust), g - 6 - 20 * dust), r * s * (0.6 + dust), p);
          }
        }
      case PoleCollapse.spark:
        // Current leaks from the broken insulator, down the pole, into the
        // climber's hands.
        final f = math.cos(2 * math.pi * orbit);
        final ins = Offset(cx + 54 * s * (f.abs() < 0.15 ? 0.15 * f.sign : f) * 0.84, geo.y(8.4) - 12 * s);
        final flick = (math.sin(t * 60) > -0.3) ? 1.0 : 0.55;
        final glow = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromRGBO(140, 200, 255, 0.85 * flick), Color.fromRGBO(140, 200, 255, 0.25 * flick)],
          ).createShader(Rect.fromLTRB(cx - 30 * s, ins.dy, cx + 30 * s, hands.dy));
        c.drawRect(Rect.fromLTRB(cx - 20 * s, geo.y(8.4), cx + 20 * s, hands.dy + 20 * s), glow);
        final rnd = math.Random((t * 30).floor());
        Path bolt(Offset a, Offset b, int n, double jitter) {
          final p = Path()..moveTo(a.dx, a.dy);
          for (var j = 1; j < n; j++) {
            final q = Offset.lerp(a, b, j / n)! + Offset((rnd.nextDouble() - 0.5) * jitter, 0);
            p.lineTo(q.dx, q.dy);
          }
          return p..lineTo(b.dx, b.dy);
        }

        final core = Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..strokeWidth = 1.6 * s
          ..style = PaintingStyle.stroke;
        final halo = Paint()
          ..color = Color.fromRGBO(255, 225, 90, 0.9 * flick)
          ..strokeWidth = 4.5 * s
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final joint = Offset(cx, geo.y(8.4));
        for (var i = 0; i < 3; i++) {
          for (final p in [bolt(ins, joint, 4, 14 * s), bolt(joint, hands, 9, 22 * s)]) {
            c.drawPath(p, halo);
            c.drawPath(p, core);
          }
        }
        for (final o in [ins, hands]) {
          c.drawCircle(o, 16 * s * (0.7 + 0.3 * flick), Paint()..color = Color.fromRGBO(255, 240, 160, 0.55 * flick));
          c.drawCircle(o, 7 * s, Paint()..color = const Color(0xEEFFFFFF));
        }
      case PoleCollapse.arm:
        final dust = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
        if (dust > 0) {
          final p = Paint()..color = Color.fromRGBO(220, 220, 220, 0.8 * (1 - dust));
          final at = Offset(cx - 30 * s, geo.y(8.1));
          for (final (dx, dy) in const [(-6.0, 0.0), (8.0, 6.0), (2.0, -8.0)]) {
            c.drawCircle(at + Offset(dx, dy) * s * (1 + 2 * dust), 6 * s * (0.5 + dust), p);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_CollapseFx old) => old.t != t || old.kind != kind || old.hands != hands;
}

/// The pole drawn in the scene's design pixels: PCC (tapered concrete) or
/// steel (tube, or rail), the cross-arm with its pin insulators and the line.
/// [orbit] turns the pole as the player walks round it: a fault on a face
/// moves across and out of view, the lean and the bend swing, the cross-arm
/// foreshortens. Far away a hairline crack is faint; [close] (the lens)
/// draws every fault at full strength.
class PolePainter extends CustomPainter {
  PolePainter({
    required this.pole,
    required this.geo,
    required this.orbit,
    this.close = false,
    this.dx = 0,
    this.prev,
    this.prevDx = 0,
    this.armDrop = 0,
  });
  final PoleCase pole;
  final PoleGeo geo;
  final double orbit;
  final bool close;
  final double dx;

  /// The pole just left behind (walking on to the next), drawn at [prevDx].
  final PoleCase? prev;
  final double prevDx;

  /// 0 → 1: the cross-arm swinging down (a deadly climb).
  final double armDrop;

  /// Half the body's width at design y [y].
  static double halfAt(PoleCase p, PoleGeo geo, double y) {
    final s = geo.s;
    if (p.kind == PoleKind.steel) return (p.rail ? 10 : 11) * s;
    final k = ((y - geo.topY) / geo.length).clamp(0.0, 1.0);
    return (9 + 7 * k) * s;
  }

  @override
  void paint(Canvas c, Size size) {
    final pv = prev;
    if (pv != null) _paintPole(c, pv, prevDx, 0);
    _paintPole(c, pole, dx, orbit);
  }

  /// How square-on face [side] is to the viewer (1 facing, ≤ 0 away) and
  /// where across the body it shows (−1 … 1).
  (double, double) _face(PoleSide side, double orbit) {
    final a = (side == PoleSide.front ? 0.0 : math.pi) - 2 * math.pi * orbit;
    return (math.cos(a), math.sin(a));
  }

  double _show(PoleFlaw f, double orbit) {
    if (f.defect.heardOnly) return 0;
    if (f.defect.allSides) return 1;
    final (v, _) = _face(f.side, orbit);
    return ((v - 0.15) / 0.7).clamp(0.0, 1.0);
  }

  void _paintPole(Canvas c, PoleCase p, double dx, double orbit) {
    final s = geo.s;
    final g = geo.groundY;
    final top = geo.topY;
    final cx = PoleGeo.cx + dx;
    final turn = math.cos(2 * math.pi * orbit);
    final steel = p.kind == PoleKind.steel;
    PoleFlaw? flaw(PoleDefect d) {
      for (final f in p.flaws) {
        if (f.defect == d) return f;
      }
      return null;
    }

    // Shadow on the shoulder.
    c.drawOval(Rect.fromCenter(center: Offset(cx + 30 * s, g + 7), width: 104 * s, height: 10 * s), Paint()..color = const Color(0x38000000));

    // The base: an eroded hole with water, or packed earth and a collar.
    if (p.has(PoleDefect.erosion)) {
      final hole = Path()
        ..moveTo(cx - 54 * s, g)
        ..quadraticBezierTo(cx, g + 34 * s, cx + 54 * s, g)
        ..close();
      c.drawPath(hole, Paint()..color = const Color(0xFF4E3E2A));
      c.drawOval(Rect.fromCenter(center: Offset(cx, g + 11 * s), width: 70 * s, height: 10 * s), Paint()..color = const Color(0xD06FA9D6));
      c.drawLine(Offset(cx - 18 * s, g + 10 * s), Offset(cx + 6 * s, g + 10 * s), Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = 1.2);
      // The foundation shows, cracked.
      c.drawRect(Rect.fromLTRB(cx - 20 * s, g - 2, cx + 20 * s, g + 7 * s), Paint()..color = const Color(0xFF8E8A80));
      c.drawPath(
        Path()
          ..moveTo(cx - 8 * s, g)
          ..lineTo(cx - 4 * s, g + 4 * s)
          ..lineTo(cx - 9 * s, g + 7 * s),
        Paint()
          ..color = const Color(0xFF2E2B26)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
      // Loose clods around the rim.
      final clod = Paint()..color = const Color(0xFF7A6040);
      for (final o in const [Offset(-58, -3), Offset(-46, 1), Offset(50, -2), Offset(60, 0)]) {
        c.drawCircle(Offset(cx + o.dx * s, g + o.dy), 3 * s, clod);
      }
    } else {
      c.drawPath(
        Path()
          ..moveTo(cx - 34 * s, g + 4)
          ..quadraticBezierTo(cx, g - 10 * s, cx + 34 * s, g + 4)
          ..close(),
        Paint()..color = const Color(0xFF8E7350),
      );
      c.drawRect(Rect.fromLTRB(cx - 21 * s, g - 7 * s, cx + 21 * s, g + 3), Paint()..color = steel ? const Color(0xFFA8A49A) : const Color(0xFF9D9A90));
    }

    c.save();
    final lean = p.has(PoleDefect.lean) ? 0.085 * turn : 0.0;
    if (lean != 0) {
      c.translate(cx, g);
      c.rotate(lean);
      c.translate(-cx, -g);
    }
    // A bent steel pole kinks at about 4 m; above it the pole stands off.
    final bend = p.has(PoleDefect.bent) ? 18 * s * turn : 0.0;
    final kinkY = geo.y(4.2);
    final topShift = bend * 0.7;

    // The body.
    final body = Path();
    double half(double y) => halfAt(p, geo, y);
    if (steel && bend != 0) {
      final w = half(g);
      body
        ..moveTo(cx - w, g)
        ..lineTo(cx - w, kinkY + 36 * s)
        ..quadraticBezierTo(cx - w + bend, kinkY, cx - w + topShift, kinkY - 46 * s)
        ..lineTo(cx - w + topShift, top)
        ..lineTo(cx + w + topShift, top)
        ..lineTo(cx + w + topShift, kinkY - 46 * s)
        ..quadraticBezierTo(cx + w + bend, kinkY, cx + w, kinkY + 36 * s)
        ..lineTo(cx + w, g)
        ..close();
    } else {
      body
        ..moveTo(cx - half(g), g)
        ..lineTo(cx - half(top), top)
        ..lineTo(cx + half(top), top)
        ..lineTo(cx + half(g), g)
        ..close();
    }
    final hb = half(g);
    final lightAt = 0.34 + 0.12 * math.sin(2 * math.pi * orbit);
    final shade = Rect.fromLTRB(cx - hb - bend.abs(), top, cx + hb + bend.abs(), g);
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: steel
              ? const [Color(0xFF5E676F), Color(0xFFD5DCE2), Color(0xFF9AA3AB), Color(0xFF59626A)]
              : const [Color(0xFF8A877F), Color(0xFFD8D5CC), Color(0xFFBDBAB1), Color(0xFF85827A)],
          stops: [0, lightAt, 0.66, 1],
        ).createShader(shade),
    );
    if (!steel) {
      // Concrete pores that turn with the pole.
      final rnd = math.Random(p.id.hashCode);
      final dot = Paint()..color = const Color(0x55706C62);
      for (var i = 0; i < 70; i++) {
        final y = top + rnd.nextDouble() * (g - top);
        final ph = rnd.nextDouble() * 2 * math.pi;
        final a = ph - 2 * math.pi * orbit;
        if (math.cos(a) < 0.1) continue;
        c.drawCircle(Offset(cx + math.sin(a) * (half(y) - 2), y), (close ? 0.9 : 0.8) * s, dot);
      }
    } else if (p.rail) {
      final flange = Paint()
        ..color = const Color(0xFF4F575F)
        ..strokeWidth = 2.4 * s;
      final fx = 6 * s * turn.abs().clamp(0.3, 1.0);
      c.drawLine(Offset(cx - fx, top), Offset(cx - fx, g), flange);
      c.drawLine(Offset(cx + fx, top), Offset(cx + fx, g), flange);
    }
    c.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF5E5B54)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Steel tube: the weld joint band low on the pole.
    final weldY = geo.y(1.5);
    if (steel && !p.rail) {
      c.drawRect(Rect.fromLTRB(cx - hb - 1.5 * s, weldY - 3 * s, cx + hb + 1.5 * s, weldY + 3 * s), Paint()..color = const Color(0xFF6B747C));
      c.drawLine(Offset(cx - hb - 1.5 * s, weldY), Offset(cx + hb + 1.5 * s, weldY), Paint()
        ..color = const Color(0xFF4A5259)
        ..strokeWidth = 1);
    }
    // Pole cap.
    c.drawRect(Rect.fromLTRB(cx + topShift - half(top) - 1, top - 4 * s, cx + topShift + half(top) + 1, top), Paint()..color = const Color(0xFF4A4F55));

    // Faults on a face (they turn away as the player walks round).
    for (final f in p.flaws) {
      final k = _show(f, orbit);
      if (k <= 0) continue;
      final (_, across) = f.defect.allSides ? (1.0, 0.0) : _face(f.side, orbit);
      switch (f.defect) {
        case PoleDefect.hairline:
          final x0 = cx + across * half(geo.y(3.5)) * 0.55;
          final pts = [
            Offset(x0 - 1 * s, geo.y(4.8)),
            Offset(x0 + 3 * s, geo.y(4.3)),
            Offset(x0 - 3 * s, geo.y(3.8)),
            Offset(x0 + 2 * s, geo.y(3.2)),
            Offset(x0 - 1 * s, geo.y(2.6)),
            Offset(x0 + 1.5 * s, geo.y(2.2)),
          ];
          final path = Path()..moveTo(pts.first.dx, pts.first.dy);
          for (final q in pts.skip(1)) {
            path.lineTo(q.dx, q.dy);
          }
          path
            ..moveTo(pts[2].dx, pts[2].dy)
            ..lineTo(pts[2].dx + 5 * s, pts[2].dy + 6 * s);
          c.drawPath(
            path,
            Paint()
              ..color = Color.fromRGBO(46, 44, 40, (close ? 0.95 : 0.4) * k)
              ..style = PaintingStyle.stroke
              ..strokeWidth = (close ? 0.55 : 0.8) * s,
          );
          if (close) {
            // A damp stain along the crack.
            c.drawOval(Rect.fromCenter(center: Offset(x0, geo.y(3.4)), width: 7 * s, height: 30 * s), Paint()..color = Color.fromRGBO(90, 100, 110, 0.12 * k));
          }
        case PoleDefect.spalling:
          final o = Offset(cx + across * half(geo.y(3.3)) * 0.4, geo.y(3.3));
          final patch = Rect.fromCenter(center: o, width: 22 * s, height: 34 * s);
          c.drawOval(patch, Paint()..color = Color.fromRGBO(128, 123, 112, 0.95 * k));
          c.drawOval(
            patch,
            Paint()
              ..color = Color.fromRGBO(80, 76, 68, 0.9 * k)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          final bar = Paint()
            ..color = Color.fromRGBO(160, 82, 45, k)
            ..strokeWidth = 2.2 * s;
          c.drawLine(o + Offset(-5 * s, -13 * s), o + Offset(-5 * s, 13 * s), bar);
          c.drawLine(o + Offset(5 * s, -12 * s), o + Offset(5 * s, 14 * s), bar);
          final chip = Paint()..color = Color.fromRGBO(173, 169, 158, k);
          c.drawCircle(Offset(cx + 26 * s, g - 2), 3 * s, chip);
          c.drawCircle(Offset(cx - 22 * s, g - 1), 2.4 * s, chip);
        case PoleDefect.groundRust:
          final face = Rect.fromLTRB(cx - hb, geo.y(0.95), cx + hb, g);
          c.drawRect(face, Paint()..color = Color.fromRGBO(154, 79, 34, 0.9 * k));
          final spot = Paint()..color = Color.fromRGBO(201, 120, 58, k);
          for (final o in const [Offset(-5, 0.8), Offset(4, 0.6), Offset(-2, 0.3), Offset(6, 0.15)]) {
            c.drawCircle(Offset(cx + o.dx * s + across * 3 * s, geo.y(o.dy)), 3 * s, spot);
          }
          // Rusted through: a hole.
          c.drawOval(Rect.fromCenter(center: Offset(cx + across * hb * 0.35, geo.y(0.4)), width: 7 * s, height: 11 * s), Paint()..color = Color.fromRGBO(30, 18, 10, k));
          final flake = Paint()..color = Color.fromRGBO(160, 82, 45, k);
          c.drawRect(Rect.fromLTWH(cx + 18 * s, g - 1, 5 * s, 2 * s), flake);
          c.drawRect(Rect.fromLTWH(cx - 26 * s, g, 4 * s, 2 * s), flake);
        case PoleDefect.weldRust:
          c.drawRect(Rect.fromLTRB(cx - hb - 2 * s, weldY - 8 * s, cx + hb + 2 * s, weldY + 9 * s), Paint()..color = Color.fromRGBO(154, 79, 34, 0.92 * k));
          final spot = Paint()..color = Color.fromRGBO(201, 120, 58, k);
          c.drawCircle(Offset(cx - 5 * s + across * 3 * s, weldY - 2 * s), 3 * s, spot);
          c.drawCircle(Offset(cx + 5 * s + across * 3 * s, weldY + 4 * s), 2.5 * s, spot);
          final drip = Paint()
            ..color = Color.fromRGBO(154, 79, 34, k)
            ..strokeWidth = 1.6 * s
            ..strokeCap = StrokeCap.round;
          c.drawLine(Offset(cx - 4 * s, weldY + 9 * s), Offset(cx - 4 * s, weldY + 22 * s), drip);
          c.drawLine(Offset(cx + 6 * s, weldY + 9 * s), Offset(cx + 6 * s, weldY + 16 * s), drip);
        default:
          break;
      }
    }

    // The cross-arm (it foreshortens as the player walks round) and braces.
    final ya = geo.y(8.4);
    final ax = cx + topShift;
    final f = turn.abs() < 0.15 ? 0.15 * (turn < 0 ? -1 : 1) : turn;
    final reach = 64 * s;
    final looseArm = p.has(PoleDefect.crossArm);
    // A loose cross-arm has turned on its clamp: one end (the same physical
    // end from either side) hangs low; its brace has come away.
    final tilt = looseArm ? 0.2 : 0.0;
    c.save();
    if (armDrop > 0) {
      // The deadly climb: the arm turns down on the climber's side (left).
      c.translate(ax, ya);
      c.rotate(-0.9 * armDrop);
      c.translate(-ax, -ya);
    }
    final armPaint = Paint()
      ..color = const Color(0xFF586068)
      ..strokeWidth = 6 * s
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    Offset armAt(double u) => Offset(ax + reach * f * u * math.cos(tilt), ya - reach * u * math.sin(tilt));

    c.drawLine(armAt(-1), armAt(1), armPaint);
    final brace = Paint()
      ..color = const Color(0xFF6B737B)
      ..strokeWidth = 2.4 * s;
    final braceFoot = Offset(ax, ya + 24 * s);
    if (looseArm) {
      // One brace still holds; the other hangs free from the low end, and the
      // clamp bolt stands out of a gap.
      c.drawLine(armAt(0.5), braceFoot, brace);
      final low = armAt(-0.5);
      c.drawLine(low, low + Offset(-3 * s * f.sign, 22 * s), brace);
      c.drawRect(Rect.fromCenter(center: Offset(ax, ya), width: 10 * s, height: 12 * s), Paint()..color = const Color(0xFF3B3F45));
      c.drawLine(Offset(ax - 9 * s, ya + 2 * s), Offset(ax + 9 * s, ya - 1 * s), Paint()
        ..color = const Color(0xFF9A4F22)
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round);
    } else {
      c.drawLine(armAt(-0.5), braceFoot, brace);
      c.drawLine(armAt(0.5), braceFoot, brace);
    }

    // Pin insulators: on each end of the arm and on the pole top.
    final insFlaw = flaw(PoleDefect.insulator);
    final broken = insFlaw != null && _show(insFlaw, orbit) > 0;
    final tops = <Offset>[];
    for (final (i, u) in const [(0, -0.84), (1, 0.0), (2, 0.84)]) {
      final base = i == 1 ? Offset(ax, top - 4 * s) : armAt(u) - Offset(0, 3 * s);
      final w = 11 * s;
      final hgt = 15 * s;
      final bodyR = Rect.fromLTWH(base.dx - w / 2, base.dy - hgt, w, hgt);
      c.drawRect(Rect.fromCenter(center: base.translate(0, -1.5 * s), width: 3 * s, height: 3 * s), Paint()..color = const Color(0xFF3B3F45));
      final glaze = Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFB9B4A8), Color(0xFFF4F1EA), Color(0xFFCFCABE)]).createShader(bodyR);
      if (broken && i == 2) {
        // A chunk broken off the top skirt, a crack down the body.
        c.drawPath(
          Path()
            ..moveTo(bodyR.left, bodyR.bottom)
            ..lineTo(bodyR.left, bodyR.top + 6 * s)
            ..lineTo(bodyR.left + 4 * s, bodyR.top + 2 * s)
            ..lineTo(bodyR.left + 6 * s, bodyR.top + 7 * s)
            ..lineTo(bodyR.right - 1 * s, bodyR.top + 9 * s)
            ..lineTo(bodyR.right, bodyR.bottom)
            ..close(),
          glaze,
        );
        c.drawLine(
          Offset(bodyR.left + 4 * s, bodyR.top + 5 * s),
          Offset(bodyR.left + 7 * s, bodyR.bottom - 2 * s),
          Paint()
            ..color = const Color(0xFF2E2B26)
            ..strokeWidth = (close ? 0.7 : 1.0) * s,
        );
        // The fallen chip at the foot of the pole.
        c.drawCircle(Offset(cx + 34 * s, g + 2), 2.6 * s, Paint()..color = const Color(0xFFE9E6DF));
        tops.add(Offset(base.dx, bodyR.top + 8 * s));
      } else {
        c.drawRRect(RRect.fromRectAndRadius(bodyR, Radius.circular(3 * s)), glaze);
        // The sheds (skirts).
        final rim = Paint()
          ..color = const Color(0xFF9C978C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        for (final k in const [0.35, 0.65]) {
          c.drawLine(Offset(bodyR.left - 1.5 * s, bodyR.top + hgt * k), Offset(bodyR.right + 1.5 * s, bodyR.top + hgt * k), rim);
        }
        tops.add(Offset(base.dx, bodyR.top));
      }
    }
    c.restore();
    c.restore();

    // The line: conductors from the edges of the scene to each insulator top
    // (mapped out of the lean so the wires do not tilt with the pole).
    if (armDrop == 0) {
      Offset out(Offset q) {
        if (lean == 0) return q;
        final d = q - Offset(cx, g);
        final cs = math.cos(lean), sn = math.sin(lean);
        return Offset(cx, g) + Offset(d.dx * cs - d.dy * sn, d.dx * sn + d.dy * cs);
      }

      final wire = Paint()
        ..color = const Color(0xFF2A2F35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      for (final q in tops) {
        final t = out(q);
        c.drawPath(Path()..moveTo(cx - 400, t.dy + 4)..quadraticBezierTo((cx - 400 + t.dx) / 2, t.dy + 16, t.dx, t.dy), wire);
        c.drawPath(Path()..moveTo(t.dx, t.dy)..quadraticBezierTo((t.dx + cx + 400) / 2, t.dy + 16, cx + 400, t.dy + 4), wire);
      }
    }
  }

  @override
  bool shouldRepaint(PolePainter old) =>
      old.pole != pole || old.geo != geo || old.orbit != orbit || old.dx != dx || old.prev != prev || old.prevDx != prevDx || old.armDrop != armDrop || old.close != close;
}
