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
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm5_dark_eyes_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm5_dark_eyes_world.dart' show M5Landmark, M5Clue, M5Sound, M5DarkEyesGeo;

// Lesson 5.7 "রাতের বেলা ফল্ট খোঁজার কৌশল", কাজ 2 "আঁধারে চোখ-কান" (pack
// do_5_7_b, engineType m5_dark_eyes). About 2 a.m. at a village edge; an
// in-service 11 kV line keeps tripping and reclosing. The trainee patrols it
// on foot, from the ground only (ruling M5-3 / R7: no PTW needed for a ground
// patrol of an in-service line; any climb or touch is deadly). The core verb:
// lights off, wait, then mark.
//
// One play (three rounds on the progress dots):
//  খোঁজ   optional: tap the lit door — the resident names a landmark ("বাঁশঝাড়ের
//         ওদিকে একটা ঝলকানি দেখেছি"). Drag along the path with the headlamp on
//         (off = a stumble or a hole: a slip). Three stretches, each with two
//         poles and a landmark (pond, bamboo grove, temple; order dealt). The
//         coworker comes on entering the first stretch (the walk, the lights
//         and the dark wait wait for him). At a stretch, switch torch and
//         headlamp off and keep still: the stars come out; after the wait
//         (no counter) the fault's own light — corona glow, tracking or an
//         intermittent flash — fades in, on the fault stretch only, with a
//         wordless sound wave when a hiss or খটখট is dealt. Any light or
//         movement resets the wait. → ◆ → "কেন আলো নিভিয়ে অপেক্ষা করলেন?"
//  চিহ্ন  long-press the exact insulator → ◆ → "কেন এই ইনসুলেটরটাই খারাপ?".
//         Under the torch every insulator glints: marking a glint costs.
//  খবর    torch on, tap the faulty pole's number plate, then "এখন কী করবেন?":
//         report it from the ground (right) → ◆ → "কেন পোলে না উঠে জায়গাটা
//         জানালেন?" → the pass panel.
//
// Lesson 5.7, and only that: pro tip 1 (after a bright torch, lights off and
// wait so the eyes adapt; a faint corona or spark may show), point 3 (spark/
// flash shows the fault's place; corona invisible by day, seen from far at
// night; tracking proves the insulator bad), point 4 (sounds such as হিসহিস্
// or খটখট carry far at night; ask the locals, they are often awake), point 0
// (stumbling, holes: higher risk at night), point 1 (torch and headlamp),
// myth 1 (the coworker, word for word). Module 5 rulings: R19 climbing a live
// pole to look closer = deadly; R20 a bamboo poke at a live insulator =
// deadly; R29 listening to a myth with no immediate danger = slip; R30
// marking a sound item = slip; R31 closing a search with the finding missed
// = slip; M5-10 a right answer without its evidence = slip.
//
// Not from the lesson (open questions in the report): the adaptation time
// (about 5 s here for "কিছুক্ষণ"); the pole number plate and who the report
// goes to; the hiss/খটখট sounds (shown as a wordless wave, no SFX yet).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m5_dark_eyes_world.dart), corner guide, ◆ on the table → "কেন …?",
// the careless coworker once a play (two beats, his recorded voice), gesture
// hints for every waiting state (how, never what; never on the light switches
// before the find; none during the dark wait), mistakes with lesson points,
// the deadly freeze, three slips strike out, idle = zero frames.

// ============================================================================
// Content
// ============================================================================

/// The play's rounds.
enum M5DarkRound { search, mark, report }

/// Which reason is being asked.
enum M5DarkWhy { resident, dark, mark, report }

/// The final deck's acts.
enum M5DarkFinal { report, climb, poke, morning, walkOn }

abstract final class M5DarkEyesLines {
  static const title = 'আঁধারে চোখ-কান';
  static const intro = 'গ্রামের দিকে লাইন ট্রিপ করছে! রাতেই ফল্ট খুঁজে বের করুন।';
  static const rounds = ['খোঁজ', 'চিহ্ন', 'খবর'];

  // The guide's task now (tap him: the same task, a different way).
  static const askWalk = 'লাইন ধরে হেঁটে ফল্ট খুঁজুন।';
  static const askLook = 'এই অংশটা ভালো করে দেখুন।';
  static const askMark = 'খারাপ ইনসুলেটরটা চেপে ধরে চিহ্ন দিন।';
  static const askPlate = 'ওই পোলের নম্বরটা পড়ে নিন।';
  static const askReport = 'এখন কী করবেন?';
  static const tasks = [askWalk, askLook, askMark, askPlate, askReport];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'রাতের লাইন';
  static const torch = 'টর্চ';
  static const headlamp = 'হেডল্যাম্প';
  static String plate(int n) => enDigits('পোল নং $n');

  // The resident (a villager: device TTS).
  static const _place = {M5Landmark.pond: 'পুকুরপাড়ের', M5Landmark.bamboo: 'বাঁশঝাড়ের', M5Landmark.temple: 'মন্দিরের'};
  static String residentLine(M5Landmark l, String noticed) => '${_place[l]} ওদিকে $noticed।';
  static const noticedFlash = 'একটা ঝলকানি দেখেছি';
  static const noticedGlow = 'নীলচে আলো দেখেছি';
  static const noticedHiss = 'হিসহিস্ শব্দ শুনেছি';
  static const noticedRattle = 'খটখট শব্দ শুনেছি';
  static List<String> get allResidentLines => [
        for (final l in M5Landmark.values)
          for (final n in [noticedFlash, noticedGlow, noticedHiss, noticedRattle]) residentLine(l, n),
      ];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses. 45–54 letters.
  static const whyQ = {
    M5DarkWhy.resident: 'কেন বাড়ির লোককে জিজ্ঞাসা করলেন?',
    M5DarkWhy.dark: 'কেন আলো নিভিয়ে অপেক্ষা করলেন?',
    M5DarkWhy.mark: 'কেন এই ইনসুলেটরটাই খারাপ?',
    M5DarkWhy.report: 'কেন পোলে না উঠে জায়গাটা জানালেন?',
  };
  static const whyResident = ['রাতে স্থানীয়রা জেগে থাকেন, তাঁরা আলো দেখে থাকতে পারেন', 'বাসিন্দারা শব্দ বা ঝলকানি দেখলে জায়গাটা বলতে পারেন'];
  static const whyDark = ['আলো নেভালে চোখ অন্ধকারে সয়ে যায়, হালকা আভা দেখা যায়', 'চোখ অন্ধকারে অভ্যস্ত হলে হালকা করোনাও চোখে পড়ে'];
  static const whyMark = <M5Clue, List<String>>{
    M5Clue.corona: ['এর চারপাশেই হালকা নীল-বেগুনি আভা — এটাই করোনা', 'অন্ধকারে এটাকে ঘিরেই করোনার নীলচে আভা দেখা গেল'],
    M5Clue.tracking: ['এর গায়ে নীলচে স্পার্কের রেখা — ট্র্যাকিং, তাই খারাপ', 'পৃষ্ঠে ছোট নীলচে স্পার্কের লাইন মানেই ইনসুলেটর খারাপ'],
    M5Clue.flash: ['অন্ধকারে ঝলকানিটা বারবার এই ইনসুলেটর থেকেই আসছিল', 'স্পার্কের ঝলক এখান থেকেই আসছিল — এটাই ফল্টের জায়গা'],
  };
  static const whyReport = ['লাইন চালু আছে — পোলে ওঠা বা খোঁচা দেওয়া মানেই বিপদ', 'চালু লাইনে টহল শুধু মাটি থেকে, পোলে ওঠা চলবে না'];
  static const myths = [
    'রাতে কিছু দেখা যায় না, সকালে এসে খোঁজাই ভালো',
    'গাড়ির হেডলাইটই যথেষ্ট, আলাদা টর্চের দরকার নেই',
    'টর্চের আলোয় যেটা সবচেয়ে চকচক করে সেটাই খারাপ',
    'তাড়াতাড়ি সারতে হবে, তাই আন্দাজেই একটা বেছে নিলাম',
    'একা গেলেই কাজ তাড়াতাড়ি হয়, সঙ্গীর দরকার নেই',
    'কাছ থেকে না দেখলে বোঝা যায় না, তাই উঠতেই হবে',
    'যেটা হাতের কাছে পেলাম, সেটাতেই চিহ্ন দিয়ে দিলাম',
  ];
  static List<String> whyRight(M5DarkWhy w, M5Clue clue) => switch (w) {
        M5DarkWhy.resident => whyResident,
        M5DarkWhy.dark => whyDark,
        M5DarkWhy.mark => whyMark[clue]!,
        M5DarkWhy.report => whyReport,
      };
  static List<String> get allWhyRight => [...whyResident, ...whyDark, for (final l in whyMark.values) ...l, ...whyReport];

  // The final deck "এখন কী করবেন?" (36–43 letters).
  static const finalRight = ['মাটি থেকেই পোলের নম্বর আর ফেজ জানিয়ে দিই', 'পোলে না উঠে নম্বর আর ইনসুলেটরটা জানিয়ে দিই'];
  static const finalWrong = <String, M5DarkFinal>{
    'পোলে উঠে কাছ থেকে ইনসুলেটরটা দেখে আসি': M5DarkFinal.climb,
    'মই লাগিয়ে উঠে ইনসুলেটরটা ভালো করে দেখি': M5DarkFinal.climb,
    'বাঁশ দিয়ে খুঁচিয়ে দেখি ইনসুলেটর নড়ে কিনা': M5DarkFinal.poke,
    'লম্বা বাঁশে ঠুকে দেখি ইনসুলেটর ভাঙা কিনা': M5DarkFinal.poke,
    'সকাল হলে এসে ভালো করে দেখে তবে জানাব': M5DarkFinal.morning,
    'নম্বরটা মনে রাখি, বাকি লাইন দেখে পরে জানাব': M5DarkFinal.walkOn,
    'আগে বাকি লাইনটা ঘুরে দেখি, তারপর জানাব': M5DarkFinal.walkOn,
  };
  static M5DarkFinal finalKind(String text) => finalWrong[text] ?? M5DarkFinal.report;
  static bool _deadlyKind(M5DarkFinal k) => k == M5DarkFinal.climb || k == M5DarkFinal.poke;

  /// The final deck: one right, one deadly (climb / poke) and one slip (wait /
  /// put off), in a dealt order — every play meets the temptation to go up.
  static List<ChoiceOption> dealFinal(math.Random rng) {
    final deadly = [for (final e in finalWrong.entries) if (_deadlyKind(e.value)) e.key];
    final slips = [for (final e in finalWrong.entries) if (!_deadlyKind(e.value)) e.key];
    return dealChoices(finalRight, [deadly[rng.nextInt(deadly.length)], slips[rng.nextInt(slips.length)]], rng);
  }

  /// The careless coworker: lesson 5.7's myth 1, word for word.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।',
    exitLine: coworkerExit,
    right: ['না, স্পার্ক-করোনা রাতেই ভালো দেখা যায়', 'না, বিদ্যুৎ ফেরানো জরুরি, এখনই খুঁজব', 'না, অন্ধকারেই আভা দূর থেকে চোখে পড়ে'],
    wrong: [
      'ঠিক বলেছ, সকালে এসে খুঁজলেই হবে',
      'আচ্ছা, অন্ধকারে খুঁজে কোনো লাভ নেই',
      'হ্যাঁ, ভোর পর্যন্ত গাড়িতে বসে থাকি',
      'ঠিক আছে, রাতে কিছুই চোখে পড়বে না',
      'হ্যাঁ, সকালের আলোয় দেখাই সবচেয়ে ভালো',
    ],
    asks: ['ও বলছে সকাল পর্যন্ত অপেক্ষা করতে। কী করবেন?', 'ওর কথা শুনবেন, না এখনই খুঁজবেন?', 'রাতে খোঁজা কি সত্যিই বৃথা?'],
  );

  /// His lines with no recorded clip yet (the director records them with
  /// tool/rival_clip.py; his exit line is his existing clip).
  static const rivalLinesToRecord = [
    'রাতে কিছু দেখা যায় না, তাই পেট্রোলিং করে লাভ নেই। সকাল হওয়ার জন্য অপেক্ষা করাই ভালো।',
  ];

  static const callHeld = 'ঠিক! স্পার্ক আর করোনা রাতেই সবচেয়ে ভালো দেখা যায়।';
  static const allSet = 'অন্ধকারকেই কাজে লাগালেন — মাটি থেকে খুঁজে, নিরাপদে জানালেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — হেডল্যাম্পে হাঁটুন, আলো নিভিয়ে অপেক্ষা করুন, সূত্র দেখে চিহ্ন দিন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtResident = 'বাড়ির লোকের কাছে খোঁজ নিয়েছেন';
  static const caughtDark = 'আলো নিভিয়ে চোখ সইয়ে দেখেছেন';
  static const caughtMark = 'ঠিক ইনসুলেটরেই চিহ্ন দিয়েছেন';
  static const caughtReport = 'পোলে না উঠে মাটি থেকে জানিয়েছেন';
  static const caughtCall = 'সকালের অপেক্ষায় “না” বলেছেন';
  static const caughtLamp = 'হেডল্যাম্প জ্বেলে নিরাপদে হেঁটেছেন';
}

abstract final class M5DarkEyesMistakes {
  static const _dir = 'assets/game/art/m5_dark_eyes';

  static const walkDark = DoMistake(
    key: '5.7/m5_dark_eyes/walk-dark',
    textBn: 'রাতে হাঁটার সময় হেডল্যাম্প জ্বালান — অন্ধকারে হোঁচট খাওয়া বা গর্তে পড়ার ঝুঁকি বাড়ে।',
    art: '$_dir/walk_dark.svg',
    lessonPoint: 0,
  );
  static const hole = DoMistake(
    key: '5.7/m5_dark_eyes/hole',
    textBn: 'গর্তে পা! হেডল্যাম্পের আলোয় পথ দেখে ধীরে ধীরে চলুন।',
    art: '$_dir/hole.svg',
    lessonPoint: 0,
  );
  static const markGlint = DoMistake(
    key: '5.7/m5_dark_eyes/mark-glint',
    textBn: 'টর্চের আলোয় সব ইনসুলেটরই চকচক করে — ওটা ফল্ট নয়। আলো নিভিয়ে আভা বা স্পার্ক খুঁজুন।',
    art: '$_dir/mark_glint.svg',
    lessonPoint: 2,
  );
  static const markSound = DoMistake(
    key: '5.7/m5_dark_eyes/mark-sound',
    textBn: 'এই ইনসুলেটরটা ভালো। যেখান থেকে আভা, ট্র্যাকিং বা ঝলকানি আসছে, ঠিক সেটাতেই চিহ্ন দিন।',
    art: '$_dir/mark_sound.svg',
    lessonPoint: 2,
  );
  static const markGuess = DoMistake(
    key: '5.7/m5_dark_eyes/mark-guess',
    textBn: 'আন্দাজে চিহ্ন নয়। আলো নিভিয়ে কিছুক্ষণ অপেক্ষা করুন, সূত্র দেখে তবে চিহ্ন দিন।',
    art: '$_dir/mark_guess.svg',
    lessonPoint: 2,
  );
  static const leftClue = DoMistake(
    key: '5.7/m5_dark_eyes/left-clue',
    textBn: 'সূত্র দেখেও চিহ্ন না দিয়ে চলে যাচ্ছেন! যে ইনসুলেটরে আভা বা স্পার্ক দেখলেন, সেটাই চিহ্নিত করুন।',
    art: '$_dir/left_clue.svg',
    lessonPoint: 2,
  );
  static const noNote = DoMistake(
    key: '5.7/m5_dark_eyes/no-note',
    textBn: 'পোলের নম্বর না পড়েই চলে যাচ্ছেন! টর্চ জ্বেলে ওই পোলের নম্বর পড়ে নিন।',
    art: '$_dir/no_note.svg',
    lessonPoint: 1,
  );
  static const walkedPast = DoMistake(
    key: '5.7/m5_dark_eyes/walked-past',
    textBn: 'ফল্ট না দেখেই সব অংশ পেরিয়ে এলেন। প্রতিটি অংশে আলো নিভিয়ে কিছুক্ষণ অপেক্ষা করে দেখুন।',
    art: '$_dir/walked_past.svg',
    lessonPoint: 2,
  );
  static const listened = DoMistake(
    key: '5.7/m5_dark_eyes/listened',
    textBn: 'ভুল কথা! স্পার্ক আর করোনা রাতেই সবচেয়ে ভালো দেখা যায় — আর বিদ্যুৎ ফেরানো জরুরি।',
    art: '$_dir/listened.svg',
    lessonPoint: 2,
  );
  static const wrongPlate = DoMistake(
    key: '5.7/m5_dark_eyes/wrong-plate',
    textBn: 'এটা অন্য পোল! যে পোলের ইনসুলেটরে সূত্র দেখলেন, সেই পোলের নম্বরই পড়ুন।',
    art: '$_dir/wrong_plate.svg',
  );
  static const morning = DoMistake(
    key: '5.7/m5_dark_eyes/morning',
    textBn: 'সকাল পর্যন্ত নয় — বিদ্যুৎ ফেরানো জরুরি। পোলের নম্বর আর জায়গা এখনই জানান।',
    art: '$_dir/report_late.svg',
    lessonPoint: 2,
  );
  static const walkOn = DoMistake(
    key: '5.7/m5_dark_eyes/walk-on',
    textBn: 'নম্বর আর জায়গা এখনই জানান — দেরি মানে বিদ্যুৎ ফিরতে দেরি।',
    art: '$_dir/report_late.svg',
  );
  // Module 5 rulings R19 / R20 (deadly).
  static const climb = DoMistake(
    key: '5.7/m5_dark_eyes/climb-live',
    textBn: 'চালু লাইনের পোলে ওঠা মানেই মৃত্যুর ঝুঁকি! রাতের টহল শুধু মাটি থেকে — জায়গাটা জানিয়ে দিন।',
    art: '$_dir/climb.svg',
    deadly: true,
  );
  static const poke = DoMistake(
    key: '5.7/m5_dark_eyes/bamboo-poke',
    textBn: 'চালু ইনসুলেটরে বাঁশের খোঁচা — বিদ্যুৎ বাঁশ বেয়ে হাতে নামে! মাটি থেকে শুধু দেখে জানান।',
    art: '$_dir/poke.svg',
    deadly: true,
  );

  static DoMistake? forFinal(M5DarkFinal k) => switch (k) {
        M5DarkFinal.report => null,
        M5DarkFinal.climb => climb,
        M5DarkFinal.poke => poke,
        M5DarkFinal.morning => morning,
        M5DarkFinal.walkOn => walkOn,
      };

  static const all = [walkDark, hole, markGlint, markSound, markGuess, leftClue, noNote, walkedPast, listened, wrongPlate, morning, walkOn, climb, poke];
}

@immutable
class M5DarkEyesDeal {
  const M5DarkEyesDeal({
    required this.stretch,
    required this.pole,
    required this.phase,
    required this.landmarks,
    required this.clue,
    required this.sound,
    required this.holes,
    required this.poleBase,
    required this.residentHeard,
  });

  /// The faulty insulator: stretch (0–2), pole (0–1), phase (0 left pin,
  /// 1 pole top, 2 right pin).
  final int stretch;
  final int pole;
  final int phase;

  /// The landmark of each stretch.
  final List<M5Landmark> landmarks;
  final M5Clue clue;
  final M5Sound sound;

  /// Holes on the path (world x).
  final List<double> holes;
  final int poleBase;

  /// The resident heard the sound (else he saw the light).
  final bool residentHeard;

  (int, int, int) get fault => (stretch, pole, phase);

  String get residentLine {
    final noticed = residentHeard
        ? (sound == M5Sound.hiss ? M5DarkEyesLines.noticedHiss : M5DarkEyesLines.noticedRattle)
        : (clue == M5Clue.flash ? M5DarkEyesLines.noticedFlash : M5DarkEyesLines.noticedGlow);
    return M5DarkEyesLines.residentLine(landmarks[stretch], noticed);
  }
}

M5DarkEyesDeal m5DarkEyesDeal(math.Random rng) {
  final landmarks = [...M5Landmark.values]..shuffle(rng);
  final stretch = rng.nextInt(3);
  final pole = rng.nextInt(2);
  final phase = rng.nextInt(3);
  final clue = M5Clue.values[rng.nextInt(M5Clue.values.length)];
  final sound = M5Sound.values[rng.nextInt(M5Sound.values.length)];
  final gaps = [0, 1, 2]..shuffle(rng);
  final n = 1 + rng.nextInt(2);
  final holes = [
    for (final g in gaps.take(n)) M5DarkEyesGeo.holeGaps[g].$1 + rng.nextDouble() * (M5DarkEyesGeo.holeGaps[g].$2 - M5DarkEyesGeo.holeGaps[g].$1),
  ]..sort();
  return M5DarkEyesDeal(
    stretch: stretch,
    pole: pole,
    phase: phase,
    landmarks: landmarks,
    clue: clue,
    sound: sound,
    holes: holes,
    poleBase: 11 + rng.nextInt(70),
    residentHeard: sound != M5Sound.none && rng.nextBool(),
  );
}

/// The play state (pure logic).
class M5DarkEyesRun {
  M5DarkEyesRun(this.deal);
  final M5DarkEyesDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The round's work is done (its reason comes next).
  var roundDone = false;

  double walker = M5DarkEyesGeo.startX;
  var facingRight = true;
  var headlamp = true;
  var torch = false;

  /// The eyes have adapted (both lights off, kept still for the wait).
  var adapted = false;
  final Set<int> passedHoles = {};

  var asked = false;
  var clueSeen = false;
  var marked = false;
  var plateRead = false;
  var reported = false;
  var _walkSlip = false;
  var _walkedPast = false;
  final Set<M5DarkRound> _leftSlipped = {};

  M5DarkRound get round => M5DarkRound.values[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;

  /// The stretch he stands in (null between stretches).
  int? get zone => M5DarkEyesGeo.zoneAt(walker);
  bool get atFault => zone == deal.stretch;
  bool get lightsOff => !torch && !headlamp;

  /// The fault's own light shows now.
  bool get clueVisible => adapted && atFault && lightsOff;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  int? _holeAhead(bool forward) {
    for (var i = 0; i < deal.holes.length; i++) {
      if (passedHoles.contains(i)) continue;
      final d = (deal.holes[i] - walker) * (forward ? 1 : -1);
      if (d > 0 && d <= 90) return i;
    }
    return null;
  }

  /// A step along the path ([dx] world px; + = on along the line).
  DoMistake? walk(double dx) {
    if (!_open || dx == 0) return null;
    if (!headlamp) {
      // In the dark: a hole close ahead takes him, else he stumbles.
      _walkSlip = true;
      final h = _holeAhead(dx > 0);
      if (h != null) {
        passedHoles.add(h);
        return _slip(M5DarkEyesMistakes.hole);
      }
      return _slip(M5DarkEyesMistakes.walkDark);
    }
    adapted = false;
    facingRight = dx > 0;
    final before = zone;
    final from = walker;
    walker = (walker + dx).clamp(M5DarkEyesGeo.startX, M5DarkEyesGeo.endX);
    final lo = math.min(from, walker), hi = math.max(from, walker);
    for (var i = 0; i < deal.holes.length; i++) {
      // In the headlamp's light he steps round it.
      if (deal.holes[i] >= lo && deal.holes[i] <= hi) passedHoles.add(i);
    }
    if (before == deal.stretch && zone != before) {
      if (round == M5DarkRound.mark && !marked && _leftSlipped.add(M5DarkRound.mark)) return _slip(M5DarkEyesMistakes.leftClue);
      if (round == M5DarkRound.report && !reported && _leftSlipped.add(M5DarkRound.report)) return _slip(M5DarkEyesMistakes.noNote);
    }
    if (walker >= M5DarkEyesGeo.endX && round == M5DarkRound.search && !_walkedPast) {
      _walkedPast = true;
      return _slip(M5DarkEyesMistakes.walkedPast);
    }
    return null;
  }

  void toggleTorch() {
    if (ended) return;
    torch = !torch;
    if (torch) adapted = false;
  }

  void toggleHeadlamp() {
    if (ended) return;
    headlamp = !headlamp;
    if (headlamp) adapted = false;
  }

  /// The dark wait is over (lights off, kept still). True = the clue was
  /// found now (the search round is done).
  bool adaptDone() {
    if (ended || !lightsOff) return false;
    adapted = true;
    if (round == M5DarkRound.search && atFault && !clueSeen && !roundDone) {
      clueSeen = true;
      roundDone = true;
      if (thorough) _tag(M5DarkEyesLines.caughtDark);
      return true;
    }
    return false;
  }

  /// A long press on an insulator.
  DoMistake? mark(int stretch, int pole, int phase) {
    if (!_open || round == M5DarkRound.report) return null;
    final right = (stretch, pole, phase) == deal.fault;
    if (!right) return _slip(torch ? M5DarkEyesMistakes.markGlint : M5DarkEyesMistakes.markSound);
    if (!clueSeen) return _slip(M5DarkEyesMistakes.markGuess);
    marked = true;
    roundDone = true;
    if (thorough) _tag(M5DarkEyesLines.caughtMark);
    return null;
  }

  /// A tap on a pole's number plate (readable only in the torch light).
  DoMistake? readPlate(int stretch, int pole) {
    if (!_open || round != M5DarkRound.report || plateRead || !torch || zone != stretch) return null;
    if (stretch != deal.stretch || pole != deal.pole) return _slip(M5DarkEyesMistakes.wrongPlate);
    plateRead = true;
    return null;
  }

  /// The final "এখন কী করবেন?".
  DoMistake? report(M5DarkFinal k) {
    if (!_open || round != M5DarkRound.report || !plateRead) return null;
    final m = M5DarkEyesMistakes.forFinal(k);
    if (m == null) {
      reported = true;
      roundDone = true;
      _tag(M5DarkEyesLines.caughtReport);
      return null;
    }
    if (m.deadly) return deadly = m;
    return _slip(m);
  }

  /// Asked the resident. True = the first time, during the search (rewarded).
  bool askResident() {
    if (ended) return false;
    final first = !asked && round == M5DarkRound.search && !roundDone;
    asked = true;
    if (first) _tag(M5DarkEyesLines.caughtResident);
    return first;
  }

  /// Listened to the coworker (his myth): a slip.
  DoMistake listen() => _slip(M5DarkEyesMistakes.listened);

  void held() => _tag(M5DarkEyesLines.caughtCall);

  void next() {
    index++;
    roundSlips = 0;
    roundDone = false;
    if (done && !_walkSlip) _tag(M5DarkEyesLines.caughtLamp);
  }
}

/// The dark wait (lesson: "কিছুক্ষণ"; shortened for the game — an open
/// question for the owner).
const m5DarkAdaptMs = 5000;

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   the resident + reason ≈ 3000 + 8200; the walk to the first stretch ≈ 4000
///   the coworker ≈ 9600; the walk on to the fault ≈ 4000
///   lights off + the wait + reason ≈ 1500 + 5000 + 8200
///   the mark + reason ≈ 2000 + 8200; torch + plate + deck + reason ≈ 4500 + 8200
///                                                            ≈ 88400
/// 85 % ≈ 75000.
const m5DarkQuickMs = 75000;

@immutable
class M5DarkEyesPack {
  const M5DarkEyesPack({required this.id, required this.titleBn, this.quickMs = m5DarkQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5DarkEyesPack> m5DarkEyesPacks = {
  'do_5_7_b': M5DarkEyesPack(id: 'do_5_7_b', titleBn: M5DarkEyesLines.title),
};

/// Test hook: the live run and the camera (tests only).
class M5DarkEyesProbe {
  M5DarkEyesRun? run;
  double cam = 0;
  M5DarkEyesGeo? geo;
  bool adapting = false;
}

// ============================================================================
// Page
// ============================================================================

class M5DarkEyesPage extends StatefulWidget {
  const M5DarkEyesPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M5DarkEyesPack pack;
  final bool muted;
  final int? seed;
  final M5DarkEyesProbe? probe;

  @override
  State<M5DarkEyesPage> createState() => _M5DarkEyesPageState();
}

class _M5DarkEyesPageState extends State<M5DarkEyesPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DarkRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _DarkRunPage extends ConsumerStatefulWidget {
  const _DarkRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry, this.probe});

  final LevelContext ctx;
  final M5DarkEyesPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final M5DarkEyesProbe? probe;

  @override
  ConsumerState<_DarkRunPage> createState() => _DarkRunPageState();
}

class _DarkRunPageState extends ConsumerState<_DarkRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5DarkEyesRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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
  M5DarkWhy _why = M5DarkWhy.dark;

  // Walking.
  var _panning = false;
  var _panDead = false;
  final Set<int> _zonesSaid = {};

  /// Stretches where a dark wait showed nothing (the gesture hand nudges on).
  final Set<int> _waitedZones = {};

  // The dark wait: the stars come out ([_adapt] 0..1); the clue plays once.
  late final AnimationController _adapt = AnimationController(vsync: this, duration: const Duration(milliseconds: m5DarkAdaptMs));
  late final AnimationController _clue = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000));
  var _adapting = false;
  Timer? _adaptTimer;

  // The resident.
  var _residentOut = false;
  var _residentTalking = false;

  // The final deck.
  List<ChoiceOption> _finalOpts = const [];
  final Set<String> _finalWrong = {};
  String? _finalPicked;
  var _finalBusy = false;

  var _freeze = false;
  bool _harmClimb = true;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final _torchKey = GlobalKey();
  final _lampKey = GlobalKey();
  M5DarkEyesGeo? _geoNow;
  double _cam = 0;

  @override
  void initState() {
    super.initState();
    _run = M5DarkEyesRun(m5DarkEyesDeal(widget.rng));
    _cam = M5DarkEyesGeo.camFor(_run.walker);
    widget.probe?.run = _run;
    _adapt.addStatusListener((s) {
      if (s == AnimationStatus.completed && _adapting) _adaptEnd();
    });
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _adaptTimer?.cancel();
    _adapt.dispose();
    _clue.dispose();
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

  bool get _finalUp => _run.plateRead && !_run.reported && _finalOpts.isNotEmpty;

  bool get _canPlay =>
      !_intro &&
      !_ended &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_run.roundDone &&
      !_freeze &&
      !_residentTalking;

  String get _task => switch (_run.round) {
        M5DarkRound.search => _run.zone == null ? M5DarkEyesLines.askWalk : M5DarkEyesLines.askLook,
        M5DarkRound.mark => M5DarkEyesLines.askMark,
        M5DarkRound.report => _run.plateRead ? M5DarkEyesLines.askReport : M5DarkEyesLines.askPlate,
      };

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
    _syncAdapt();
  }

  // --- the dark wait ------------------------------------------------------------
  bool get _canAdapt =>
      !_intro &&
      !_ended &&
      _card == null &&
      !_freeze &&
      !_panning &&
      !coworkerDue &&
      !coworkerOpen &&
      !reasonOpen &&
      !tableHolding &&
      !_residentTalking &&
      !_finalUp &&
      _run.lightsOff &&
      !_run.adapted &&
      !_run.roundDone;

  /// Starts the wait when the trainee is in the dark and still; any light or
  /// movement (or anything else taking the stage) resets it.
  void _syncAdapt() {
    if (!mounted) return;
    if (_canAdapt) {
      if (_adapting) return;
      _adapting = true;
      widget.probe?.adapting = true;
      if (_quiet) {
        _adaptTimer?.cancel();
        _adaptTimer = Timer(const Duration(milliseconds: m5DarkAdaptMs), _adaptEnd);
      } else {
        unawaited(_adapt.forward(from: 0));
      }
      return;
    }
    if (_adapting) {
      _adapting = false;
      widget.probe?.adapting = false;
      _adaptTimer?.cancel();
      _adapt.stop();
    }
    final v = _run.adapted ? 1.0 : 0.0;
    if (_adapt.value != v) _adapt.value = v;
  }

  void _adaptEnd() {
    if (!mounted || !_adapting) return;
    _adapting = false;
    widget.probe?.adapting = false;
    _adaptTimer?.cancel();
    if (_adapt.value != 1) _adapt.value = 1;
    final found = _run.adaptDone();
    final z = _run.zone;
    if (!found && z != null && _run.round == M5DarkRound.search && !_run.atFault) _waitedZones.add(z);
    setState(() => _wake++);
    if (_run.clueVisible) {
      if (_quiet) {
        _clue.value = 1;
      } else {
        unawaited(_clue.forward(from: 0));
      }
    }
    if (found) {
      HapticFeedback.mediumImpact();
      unawaited(_roundDone(M5DarkWhy.dark));
    }
  }

  // --- hands on -----------------------------------------------------------------
  void _toggle(bool torch, Offset global) {
    if (!_canPlay || _finalUp) return;
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.55);
    setState(() {
      if (torch) {
        _run.toggleTorch();
      } else {
        _run.toggleHeadlamp();
      }
      _wake++;
    });
    _syncAdapt();
  }

  void _panStart(DragStartDetails d) {
    _panDead = false;
    if (!_canPlay || _finalUp) {
      _panDead = true;
      return;
    }
    // The walk waits for the coworker once he is due.
    if (holdForCoworker()) {
      _panDead = true;
      return;
    }
    _panning = true;
    _syncAdapt();
  }

  void _panUpdate(DragUpdateDetails d) {
    if (_panDead || !_panning || !_canPlay) return;
    final dx = d.delta.dx;
    if (dx.abs() < 0.01) return;
    final before = _run.zone;
    final m = _run.walk(dx);
    if (m != null) {
      _panDead = true;
      _panning = false;
      setState(() => _wake++);
      unawaited(_mistake(m, d.globalPosition));
      return;
    }
    final after = _run.zone;
    setState(() {});
    if (after != before && after != null) {
      // Arrived at a stretch: he stops here (the finger lifts to go on).
      _panDead = true;
      _panning = false;
      setState(() => _wake++);
      _arrive(after);
    }
  }

  void _panEnd() {
    if (!_panning) return;
    _panning = false;
    setState(() => _wake++);
    _syncAdapt();
  }

  void _arrive(int zone) {
    if (zone == 0 && !coworkerDone && !coworkerDue) {
      // The coworker comes on entering the first stretch; the dark wait, the
      // walk and the lights wait for him.
      scheduleCoworker();
      return;
    }
    if (_run.round == M5DarkRound.search && _zonesSaid.add(zone)) unawaited(_sayChain([M5DarkEyesLines.askLook]));
    _syncAdapt();
  }

  Offset _world(Offset scene) => scene + Offset(_cam, 0);

  void _longPress(Offset p, Offset global) {
    final geo = _geoNow;
    if (geo == null || !_canPlay || _finalUp) return;
    final z = _run.zone;
    if (z == null) {
      _hints.missTap();
      return;
    }
    final w = _world(p);
    for (var pole = 0; pole < 2; pole++) {
      for (var ph = 0; ph < 3; ph++) {
        if (!geo.insulatorHit(z, pole, ph).contains(w)) continue;
        if (holdForCoworker()) return;
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.wav', volume: 0.55);
        final m = _run.mark(z, pole, ph);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, global));
        } else if (_run.marked) {
          unawaited(_roundDone(M5DarkWhy.mark));
        }
        return;
      }
    }
    _hints.missTap();
  }

  void _tapScene(Offset p, Offset global) {
    final geo = _geoNow;
    if (geo == null || !_canPlay || _finalUp) return;
    final w = _world(p);
    if (geo.doorHit.contains(w)) {
      unawaited(_askResident());
      return;
    }
    final z = _run.zone;
    if (z != null && _run.round == M5DarkRound.report) {
      for (var pole = 0; pole < 2; pole++) {
        if (!geo.plateHit(z, pole).contains(w)) continue;
        final m = _run.readPlate(z, pole);
        if (m != null) {
          setState(() => _wake++);
          unawaited(_mistake(m, global));
        } else if (_run.plateRead) {
          _tick('sounds/learn/tag_slap.wav', 0.5);
          _dealFinal();
        } else {
          _hints.missTap();
        }
        return;
      }
    }
    _hints.missTap();
  }

  Future<void> _askResident() async {
    _tick('sounds/intro/impact_metal.ogg', 0.4);
    final first = _run.askResident();
    _hush();
    final line = _run.deal.residentLine;
    setState(() {
      _residentOut = true;
      _residentTalking = true;
      _wake++;
    });
    _syncAdapt();
    final clock = Stopwatch()..start();
    // A villager speaks in the device voice (ruling M5-14).
    await MascotSpeechLibrary.speak(line, muted: _muted);
    if (!mounted || _ended) return;
    final rest = MascotSpeechLibrary.readHold(line) - clock.elapsed;
    if (_muted && rest > Duration.zero) await Future<void>.delayed(rest);
    if (!mounted || _ended) return;
    setState(() => _residentTalking = false);
    if (first) {
      unawaited(_roundDone(M5DarkWhy.resident, amount: 10));
    } else {
      _syncAdapt();
    }
  }

  void _dealFinal() {
    setState(() {
      _finalOpts = M5DarkEyesLines.dealFinal(widget.rng);
      _finalWrong.clear();
      _finalPicked = null;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.wav', volume: 0.6);
    unawaited(_sayChain([M5DarkEyesLines.askReport], mood: GuideMood.think));
  }

  Future<void> _pickFinal(ChoiceOption o, Offset origin) async {
    if (_intro || _ended || _card != null || tableBusy || !_finalUp || _finalBusy || _finalWrong.contains(o.textBn) || _finalPicked != null) return;
    _hush();
    if (!o.correct) {
      setState(() => _finalWrong.add(o.textBn));
      final m = _run.report(M5DarkEyesLines.finalKind(o.textBn));
      if (m != null) unawaited(_mistake(m, origin));
      return;
    }
    _finalBusy = true;
    setState(() => _finalPicked = o.textBn);
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _run.report(M5DarkFinal.report);
    _finalBusy = false;
    setState(() {
      _finalOpts = const [];
      _wake++;
    });
    unawaited(_roundDone(M5DarkWhy.report));
  }

  Future<void> _roundDone(M5DarkWhy why, {int? amount}) async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    _why = why;
    putOnTable(amount ?? 15 + (_run.thorough ? 5 : 0));
    _syncAdapt();
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5DarkEyesLines.whyRight(why, _run.deal.clue), M5DarkEyesLines.myths, widget.rng),
      question: M5DarkEyesLines.whyQ[why]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    final idx = _run.index;
    final why = _why;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended || _run.index != idx) return;
      if (why == M5DarkWhy.resident) {
        setState(() => _wake++);
        unawaited(_sayChain([_task]));
        _syncAdapt();
        return;
      }
      _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5DarkEyesLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.clueSeen) return null;
    if (_intro || _card != null || tableBusy || _freeze || _panning || _residentTalking) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to his myth: a slip (nobody is in danger on the spot).
      await _mistake(_run.listen(), origin);
      return;
    }
    _run.held();
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    _zonesSaid.add(0);
    unawaited(_sayChain([M5DarkEyesLines.callHeld, _task], mood: GuideMood.glad));
    _syncAdapt();
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5DarkEyesLines.tapWhy[_nudgeN++ % M5DarkEyesLines.tapWhy.length]
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
    _syncAdapt();
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    _syncAdapt();
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('darkeyes/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A climb or a poke at the live line: the scene freezes grey, the arc
  /// comes off the insulator in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _syncAdapt();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _harmClimb = m == M5DarkEyesMistakes.climb;
      _finalOpts = const [];
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
    final speak = await SpokenOnce.first('darkeyes/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5DarkEyesLines.deadlyWord : M5DarkEyesLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same round goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        unawaited(_sayChain([_task]));
        _syncAdapt();
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
    await _say(!_run.passed ? M5DarkEyesLines.fail : (_quickBonus ? M5DarkEyesLines.quick : M5DarkEyesLines.allSet),
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
    if (_panning) return LinemanMode.walk;
    if (_run.torch) return LinemanMode.point;
    return LinemanMode.idle;
  }

  M5DarkView get _view => M5DarkView(
        landmarks: _run.deal.landmarks,
        poleBase: _run.deal.poleBase,
        walker: _run.walker,
        facingRight: _run.facingRight,
        torch: _run.torch,
        headlamp: _run.headlamp,
        holes: _run.deal.holes,
        residentOut: _residentOut,
        marked: _run.marked ? _run.deal.fault : null,
      );

  /// A scene rect (world x) on screen, in global px (null before layout).
  Rect? _globalOf(Rect world) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final r = world.shift(Offset(-_cam, 0));
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// The gesture hand — how to touch, never what:
  ///  • by the house, before asking: a sweep over the door and the path head
  ///    (both alike);
  ///  • between stretches: a short forward drag from the trainee;
  ///  • at a stretch while searching: none (lights off and keep still is the
  ///    way on); after a fruitless wait there, headlamp on: a forward drag;
  ///  • at the fault stretch in the mark round: a sweep over all six
  ///    insulators alike;
  ///  • after the find (the plate): a sweep over both switches and both plates.
  /// Never on the light switches before the find; none during the dark wait.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final z = _run.zone;
    final List<Rect> rects;
    if (_run.round == M5DarkRound.report && !_run.plateRead) {
      rects = [
        ?HintSpec.globalRectOf(_torchKey),
        ?HintSpec.globalRectOf(_lampKey),
        if (z != null)
          for (var pole = 0; pole < 2; pole++) ?_globalOf(geo.plateHit(z, pole)),
      ];
    } else if (z != null && _run.round == M5DarkRound.search) {
      // Searching: the way on is lights off and keep still — no hand for
      // that (never the switches before the find). Only after a fruitless
      // wait here, with the headlamp back on, a forward nudge.
      if (!_waitedZones.contains(z) || !_run.headlamp) return null;
      return _walkHint(geo, 1);
    } else if (z != null && _run.atFault) {
      rects = [
        for (var pole = 0; pole < 2; pole++)
          for (final ph in const [0, 1, 2]) ?_globalOf(geo.insulatorHit(z, pole, ph)),
      ];
    } else if (!_run.asked && _run.walker < 330) {
      rects = [?_globalOf(geo.doorHit), ?_globalOf(geo.walker(_run.walker))];
    } else {
      // On along the line while searching; after the find, back toward it.
      final back = _run.round != M5DarkRound.search && M5DarkEyesGeo.stretchX[_run.deal.stretch] < _run.walker;
      return _walkHint(geo, back ? -1 : 1);
    }
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  HintSpec? _walkHint(M5DarkEyesGeo geo, double dir) {
    final w = _globalOf(geo.walker(_run.walker));
    return w == null ? null : HintSpec.drag(w.center, toward: Offset(dir, 0), travel: 72);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5DarkEyesGeo.forScene(m.height, m.inset);
    final cam = _cam = M5DarkEyesGeo.camFor(_run.walker);
    widget.probe
      ?..cam = cam
      ..geo = geo;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final view = _view;
    final showResident = _residentOut && _run.walker < 330 && !_freeze;
    final plateChip = _run.plateRead && !_freeze;
    final plateAt = geo.plate(_run.deal.stretch, _run.deal.pole).translate(-cam, 0);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('sky'),
                child: RepaintBoundary(child: CustomPaint(painter: M5DarkSkyPainter(geo: geo, cam: cam, adapt: _adapt))),
              ),
              Positioned.fill(
                key: const ValueKey('place'),
                child: RepaintBoundary(child: CustomPaint(painter: M5DarkWorldPainter(geo: geo, cam: cam, view: view, adapt: _adapt))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.walker(_run.walker).shift(Offset(-cam, 0)),
                child: Transform.flip(
                  flipX: !_run.facingRight,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet, point: 0.7),
                ),
              ),
              Positioned.fill(
                key: const ValueKey('beams'),
                child: IgnorePointer(child: CustomPaint(painter: M5DarkBeamPainter(geo: geo, cam: cam, view: view))),
              ),
              if (_run.clueVisible)
                Positioned.fill(
                  key: const ValueKey('clue'),
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: M5DarkCluePainter(
                          geo: geo,
                          cam: cam,
                          at: _run.deal.fault,
                          clue: _run.deal.clue,
                          sound: _run.deal.sound,
                          walker: _run.walker,
                          t: _clue,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (showResident)
        Positioned(
          key: const ValueKey('resident-say'),
          left: (geo.door.left - cam - 6).clamp(6.0, 160.0),
          top: geo.groundY - 172,
          width: 188,
          child: IgnorePointer(child: _ResidentBubble(text: _run.deal.residentLine)),
        ),
      if (plateChip)
        Positioned(
          key: const ValueKey('plate-chip'),
          left: (plateAt.dx - 44).clamp(4.0, 268.0),
          top: plateAt.dy - 46,
          width: 88,
          child: IgnorePointer(child: _PlateChip(text: M5DarkEyesLines.plate(view.poleNumber(_run.deal.stretch, _run.deal.pole)))),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5DarkEyesLines.sceneLabel,
          child: GestureDetector(
            key: _touchKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, d.globalPosition),
            onLongPressStart: (d) => _longPress(d.localPosition, d.globalPosition),
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: (_) => _panEnd(),
            onPanCancel: _panEnd,
          ),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('harm'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(
                painter: M5DarkHarmPainter(geo: geo, cam: cam, at: _run.deal.fault, walker: _run.walker, climb: _harmClimb, v: v),
              ),
            ),
          ),
        ),
      // The next round: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.35, end: 0),
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
    final deckUp = reasonOpen || coworkerChoiceUp || (_finalUp && playing);
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null && !_residentTalking;
    // No hand during the dark wait (lights off, not adapted yet) or a walk.
    final waiting = handsOn && !tableBusy && !_panning && !_adapting && !(_run.lightsOff && !_run.adapted) && !coworkerDue;
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
              labels: M5DarkEyesLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.index}/${_run.zone}/${_run.asked}/${_run.torch}/${_run.headlamp}/${_waitedZones.length}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !deckUp && _card == null)
                Positioned(
                  key: const ValueKey('hud-switches'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SwitchButton(
                        key: _torchKey,
                        icon: _run.torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                        label: M5DarkEyesLines.torch,
                        on: _run.torch,
                        onTap: (g) => _toggle(true, g),
                      ),
                      _SwitchButton(
                        key: _lampKey,
                        icon: _run.headlamp ? Icons.highlight_rounded : Icons.highlight_off_rounded,
                        label: M5DarkEyesLines.headlamp,
                        on: _run.headlamp,
                        onTap: (g) => _toggle(false, g),
                      ),
                    ],
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
                                key: const ValueKey('final-deck'),
                                options: _finalOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _finalWrong,
                                picked: _finalPicked,
                                onPick: (o, at) => unawaited(_pickFinal(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerOnScreen && coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
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
                  line: M5DarkEyesLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
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

/// The resident's words by his door (a villager's line, no answer in it).
class _ResidentBubble extends StatelessWidget {
  const _ResidentBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
      decoration: BoxDecoration(
        color: const Color(0xF2FFF4DC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text(text, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.3, color: const Color(0xFF2A1C0C))),
    );
  }
}

/// The number read off the plate.
class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xF2F2F4F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF14202E), width: 1.4),
      ),
      child: Text(text, maxLines: 1, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF14202E))),
    );
  }
}

/// A light switch: a round icon with its name under it; lit while on.
class _SwitchButton extends StatelessWidget {
  const _SwitchButton({super.key, required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? const Color(0xFFFFE08A) : SlmColors.gold300.withValues(alpha: 0.55);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF5A4A1E), Color(0xFF2A220C)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring, width: on ? 2.4 : 1.7),
                  boxShadow: [
                    const BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
                    if (on) const BoxShadow(color: Color(0x55FFD36A), blurRadius: 12, spreadRadius: 1),
                  ],
                ),
                child: Icon(icon, size: 26, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
