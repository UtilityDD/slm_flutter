import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
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
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm8_solar_backfeed_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm8_solar_backfeed_world.dart' show M8Clue, M8Decoy, M8Fault, M8Geo, M8House, M8SolarDeal, M8WhyKind;

// Lesson 8.8 "নেট মিটারিং (Net Metering) রেগুলেশন: সৌরশক্তির নিয়ম", কাজ
// "ছাদে সূর্য, লাইনে বিপদ" (pack do_8_8_a, rung 8.8/do/0, engineType
// m8_solar_backfeed). The shutdown is taken: the DTR at the lane's far end is
// OFF (AB switch open, handle locked and tagged, HG fuses: ruling M8-19), but
// some roofs in the lane carry solar. The lane is wider than the screen (swipe
// to pan). The core verb: trace service cables, pull solar fuses.
//
//  Look   swipe to pan; hold any roof to look over its parapet (the same for
//         every roof); tap any meter box to zoom it (the same for every box).
//  Mark   tap a house door to chalk a sun mark, tap again to wipe it. No
//         feedback: a mark is the player's own note.
//  Trace  drag from a marked house's wall clip along its service cable to the
//         pole (the cable lights under the finger only; the crossings are the
//         puzzle). Reaching the pole selects the carrier it really ends at.
//  Pull   drag the selected carrier down into the belt pouch. A solar house =
//         right (praise, ◆; the reason on the first right pull — "কেন?" —
//         and on the first house known only by its sticker or net meter —
//         "কী দেখে?"). A house with no solar = a slip (R18): the carrier
//         springs back and its card names what the roof or box really was.
//  Climb  drag the ladder onto the pole. The live line is live from the start:
//         any solar house's fuse still in = DEADLY, every time, whatever the
//         dealt inverter would do (R2, ruling M8-2): grey freeze, then in
//         colour the sun -> panels -> running inverter -> meter -> service
//         cable -> pole -> the trainee's hand; card and near-miss/death fall.
//         All solar fuses out -> ◆ -> reason 'সব সোলার ফিউজ খোলার পরেই উঠলেন
//         কেন?' -> a short coda: the crew's tester on a live point, then 0 V
//         (ডেড), the earths (ruling M8-17: shown, no scoring) -> pass panel.
//
// The coworker (the lesson's myth 1 in his own words): after the first right
// pull, held at the next fuse pull or at the climb control; or at the first
// touch of the climb control if that comes before any right pull. Either way a
// solar fuse is always still in. Listening = he lifts the ladder and the
// trainee climbs = DEADLY (X2/B1). Refusing him pays.
//
// No giveaway: no solar count, the pouch shows only what was pulled, the
// carriers are unlabelled and shuffled, the cables cross, every roof and box
// answers alike, decoy roofs and sticker-less solar houses are dealt, marks
// get no feedback, a needless pull costs a slip, and brute force (mark all,
// pull all) strikes out: at least 3 houses in every lane have no solar.
//
// Gesture hands (how, never what): lane at rest, a horizontal swipe then a
// sweep over every roof and meter box alike (alternating); a marked house, a
// short drag nudge from its own clip toward the pole, stopping short; a
// carrier selected, a drag-down nudge on it; some pulled, a sweep over the
// whole fuse row and the ladder. Decks have their own. Off during the intro,
// the coworker's first beat, praise, cards, the freeze, the coda.

// ============================================================================
// Content
// ============================================================================

/// What a carrier pull did.
enum M8Pull { right, needless, already }

/// The lesson point (0-based) the cards open: anti-islanding / back-feed.
const int kM8SolarLessonPoint = 2;

abstract final class M8SolarBackfeedLines {
  static const title = 'ছাদে সূর্য, লাইনে বিপদ';
  // DRAFT wording — owner (M6-12 / M8-14): every new line below until the owner
  // gives the natural wording.
  static const intro = 'গলির লাইনে শাটডাউন হয়েছে। ওঠার আগে নিশ্চিত হন — লাইন সত্যিই ডেড তো?';

  // The guide's task now, by stage (tap him: the same task, another way).
  static const look = ['কাজের আগে গলিটা দেখে নিন।', 'যে বাড়িতে সন্দেহ হয়, তার দরজায় একটা দাগ দিন।'];
  static const trace = ['দাগ দেওয়া বাড়ির তার ধরে পোল পর্যন্ত যান।', 'দেয়ালের ক্লিপ থেকে তার ধরে পোলের দিকে টানুন।'];
  static const pull = ['ফিউজটা টেনে নামান।', 'ফিউজ ধরে নিচে টেনে পাউচে রাখুন।'];
  static const next = ['গলিটা আরেকবার দেখে নিন, তারপর মই।', 'আর কিছু করার থাকলে করুন, নইলে মই পোলে লাগান।'];
  static List<String> get tasks => [...look, ...trace, ...pull, ...next];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The reasons: the right ones state the lesson's rule; the wrong ones are
  // myths and field excuses (all about the same length).
  static const whyQ = <M8WhyKind, String>{
    M8WhyKind.backfeed: 'ট্রান্সফরমার OFF, তবু এই বাড়ির ফিউজ খুললেন কেন?',
    M8WhyKind.clue: 'কী দেখে বুঝলেন এ বাড়িতে সোলার আছে?',
    M8WhyKind.climb: 'সব সোলার ফিউজ খোলার পরেই উঠলেন কেন?',
  };
  static const whyRight = <M8WhyKind, List<String>>{
    M8WhyKind.backfeed: [
      'গ্রিড বন্ধেও সোলার চললে ব্যাক-ফিডে লাইন সজীব থাকে',
      'ছাদের সোলার ভোল্টেজ পাঠিয়ে লাইন সজীব রাখতে পারে',
      'ট্রান্সফরমার OFF হলেও সোলার লাইনে কারেন্ট পাঠায়',
    ],
    M8WhyKind.climb: [
      'বিশ্বাসে মিলায় বস্তু, সোলারে নয় — আগে ফিউজ খুলেছি',
      'ইনভার্টার বন্ধ না হলে ব্যাক-ফিডে বিপদ, তাই আগে ফিউজ',
      'ট্রান্সফরমার OFF হলেও সোলার লাইন সজীব রাখে, তাই ফিউজ',
    ],
  };
  static const clueRight = <M8Clue, List<String>>{
    M8Clue.stickerBox: ['মিটার বক্সে সবুজ সোলার স্টিকার লাগানো ছিল', 'বাড়ির মিটার বক্সে সবুজ স্টিকার সাঁটা ছিল'],
    M8Clue.netMeter: ['মিটারে Import আর Export আলাদা দেখাচ্ছিল', 'মিটারের পর্দায় Import-Export দুটো পাতা ছিল', 'মিটারে তীরের চিহ্ন দুই দিকেই দেখাচ্ছিল'],
    M8Clue.stickerCarrier: ['পোলের ফিউজে সবুজ সোলার স্টিকার লাগানো ছিল', 'পোলের ফিউজ কার্ট্রিজে সবুজ স্টিকার সাঁটা ছিল'],
  };
  static const _wrongBy = <M8WhyKind, List<String>>{
    M8WhyKind.backfeed: [
      'বাড়ির মিটার রিডিং থামাতে হয় বলে ফিউজ খোলা হয়',
      'গ্রাহক যেন এই মাসে বিল না পায় সেই জন্য খোলা',
      'পুরনো ফিউজ কার্ট্রিজ বদলাতে হবে বলে খুলেছি',
      'ট্রান্সফরমারের চাপ কমাতে হয় বলে ফিউজ খোলা হয়',
      'নিয়মে গলির সব ফিউজই একসঙ্গে খুলতে হয় বলে',
    ],
    M8WhyKind.clue: [
      'বাড়িটা নতুন রং করা ছিল বলেই বুঝেছি',
      'ছাদে জলের ট্যাঙ্ক অনেকগুলো ছিল বলেই বুঝেছি',
      'মিটারে ইউনিট অনেক বেশি উঠেছিল বলে বুঝি',
      'বাড়ির সামনে একটা গাড়ি দাঁড়ানো ছিল',
      'জানলায় কাচ লাগানো দেখেছি তাই বুঝলাম',
    ],
    M8WhyKind.climb: [
      'ট্রান্সফরমার OFF ছিল, তাই আর কিছু লাগেনি বলে উঠেছি',
      'ফিউজ খুললে কাজ তাড়াতাড়ি শেষ হয় বলে খুলেছি',
      'নিয়মে মই লাগানোর আগে সব ফিউজ খুলতে হয় বলে',
      'গ্রাহক ফোন করে বলেছিল সোলার বন্ধ আছে, তাই উঠেছি',
      'সোলার ইনভার্টার সব সময় নিজে বন্ধ হয়ে যায় বলে',
    ],
  };

  /// The right reasons of a question (for a clue question: the house's clue).
  static List<String> rightFor(M8WhyKind k, {M8Clue? clue}) => k == M8WhyKind.clue ? clueRight[clue]! : whyRight[k]!;
  static List<String> wrongFor(M8WhyKind k) => _wrongBy[k]!;
  static List<String> get allWhyRight => [
        ...whyRight[M8WhyKind.backfeed]!,
        ...whyRight[M8WhyKind.climb]!,
        for (final l in clueRight.values) ...l,
      ];
  static List<String> get allWhyWrong => [for (final l in _wrongBy.values) ...l];

  // The careless coworker: the lesson's myth 1 (the on-grid system stops with
  // the grid) in his own words, pushing the deadly climb (DRAFT: owner words it).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'ট্রান্সফরমার তো OFF! গ্রিড গেলে ইনভার্টার নিজেই বন্ধ হয়ে যায় — বাড়ি বাড়ি ফিউজ খুলে সময় নষ্ট কোরো না, উঠে পড়ো।',
    exitLine: coworkerExit,
    right: [
      'না, সোলার বাড়ির সব ফিউজ খুলে তবেই আমি উঠব',
      'ইনভার্টার বন্ধ হল কি না দেখা যায় না, আগে ফিউজ',
      'ট্রান্সফরমার OFF হলেও ব্যাক-ফিড হতে পারে, আগে ফিউজ',
    ],
    wrong: [
      'ঠিকই, ইনভার্টার তো গ্রিড গেলে বন্ধ হয়ে যায়',
      'ট্রান্সফরমার OFF, এতেই হবে, চলো উঠে পড়ি',
      'ঠিক বলেছ, ফিউজ খোলার দরকার নেই, উঠে পড়ি',
      'হ্যাঁ, গ্রিড না থাকলে সোলারও থাকে না, উঠছি',
      'আচ্ছা, সময় নষ্ট না করে এখনই সোজা উঠে পড়ি',
      'ঠিক, ফিউজের ঝামেলা পরে হবে, এখন মই লাগাই',
    ],
    asks: ['ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! ইনভার্টার বন্ধ হওয়ার কথা, কিন্তু আগে নিজের হাতে ফিউজ খুলে নিশ্চিত হতে হয়।';

  static const allSet = 'গলি নিরাপদ — সোলারের সব ফিউজ খুলে তবেই উঠেছেন!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ওঠার আগে সোলারের প্রতিটা বাড়ির ফিউজ খুলুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // The crew's coda (silent captions; art only, no scoring: M8-17).
  static const crewLive = 'টেস্টার · লাইভে ঠিক';
  static const crewDead = '0 V · ডেড';
  static const crewEarth = 'আর্থ লাগানো';

  // The silent captions of the meter zoom and the roof peek.
  static const importWord = 'Import';
  static const exportWord = 'Export';
  static const solarSticker = 'সোলার';
  static const meterLabel = 'মিটার বক্স';
  static const roofLabel = 'ছাদ';
  static const pouchLabel = 'কোমরের পাউচ';
  static const ladderLabel = 'মই';
  static const sceneLabel = 'গলি';

  /// "আজ যা ধরলেন": each solar house and the clue that showed it.
  static String clueName(M8Clue c) => switch (c) {
        M8Clue.panelsLane => 'ছাদে প্যানেল',
        M8Clue.panelsParapet => 'প্যারাপেটের আড়ালে প্যানেল',
        M8Clue.stickerBox => 'মিটার বক্সে সবুজ স্টিকার',
        M8Clue.stickerCarrier => 'পোলের ফিউজে সবুজ স্টিকার',
        M8Clue.netMeter => 'নেট মিটার (Import/Export)',
      };
  static String caughtHouse(M8House h) => 'সোলারের বাড়ি: ${clueName(m8ClueShown(h))}';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Lines spoken here that already have a clip (the exit, the old asks, the
  /// old why-taps, the death words, the quick-pass line).
  static const reused = {coworkerExit, 'ওকে কী বলবেন?', 'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?', 'থামুন!', 'অল্পের জন্য!', quick};

  /// The coworker's new line (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworker.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks.where((l) => !reused.contains(l)),
        for (final k in M8WhyKind.values) whyQ[k]!,
        callHeld,
        allSet,
        fail,
        for (final m in M8SolarBackfeedMistakes.all) m.textBn,
      ];

  /// Every line the level speaks (guide and coworker).
  static List<String> get spokenLines => [...newGuideLines, ...newRivalLines, ...reused];
}

/// The clue a "caught" row names (the house's most plain one).
M8Clue m8ClueShown(M8House h) {
  for (final c in const [M8Clue.panelsLane, M8Clue.panelsParapet, M8Clue.stickerBox, M8Clue.stickerCarrier, M8Clue.netMeter]) {
    if (h.clues.contains(c)) return c;
  }
  return M8Clue.panelsLane;
}

/// The non-roof clue a "কী দেখে?" question is asked about.
M8Clue? m8ClueAsked(M8House h) {
  for (final c in const [M8Clue.netMeter, M8Clue.stickerBox, M8Clue.stickerCarrier]) {
    if (h.clues.contains(c)) return c;
  }
  return null;
}

abstract final class M8SolarBackfeedMistakes {
  static const _dir = 'assets/game/art/m8_solar_backfeed';

  // DRAFT wording — owner (M6-12). Needless pull of a house with no solar
  // (R18): each card names what THIS house really had (X6).
  static const needlessTarp = DoMistake(
    key: '8.8/m8_solar_backfeed/needless-tarp',
    textBn: 'ছাদের নীল ত্রিপল সোলার প্যানেল নয় — এ বাড়িতে সোলার নেই, ফিউজ খোলার দরকার ছিল না।',
    art: '$_dir/tarp.svg',
    lessonPoint: kM8SolarLessonPoint,
  );
  static const needlessSkylight = DoMistake(
    key: '8.8/m8_solar_backfeed/needless-skylight',
    textBn: 'ছাদের কাচের স্কাইলাইট সোলার প্যানেল নয় — এ বাড়িতে সোলার নেই, ফিউজ খোলার দরকার ছিল না।',
    art: '$_dir/skylight.svg',
    lessonPoint: kM8SolarLessonPoint,
  );
  static const needlessTanks = DoMistake(
    key: '8.8/m8_solar_backfeed/needless-tanks',
    textBn: 'ছাদে জলের ট্যাঙ্কের সারি, সোলার নয় — এ বাড়ির ফিউজ খোলার দরকার ছিল না।',
    art: '$_dir/tanks.svg',
    lessonPoint: kM8SolarLessonPoint,
  );
  static const needlessPlain = DoMistake(
    key: '8.8/m8_solar_backfeed/needless-plain',
    textBn: 'এ বাড়িতে সাধারণ মিটার, সোলার নেই। শুধু সোলারের বাড়ির ফিউজই খুলতে হয়।',
    art: '$_dir/meter_plain.svg',
    lessonPoint: 0,
  );

  // Climbing with any solar house's fuse still in (R2, M8-2): deadly every
  // time, whatever the dealt inverter would do.
  static const climbLive = DoMistake(
    key: '8.8/m8_solar_backfeed/climb-live',
    textBn: 'সোলারের বাড়ির ফিউজ লাগানো থাকলে ট্রান্সফরমার OFF হলেও ব্যাক-ফিডে লাইন সজীব — ওঠার আগে ওই বাড়ির ফিউজ খুলতেই হবে।',
    art: '$_dir/climb_live.svg',
    deadly: true,
    lessonPoint: kM8SolarLessonPoint,
  );

  // Listening to the coworker: the myth 'the inverter switches itself off',
  // the climb he pushes (B1: deadly here).
  static const pushListen = DoMistake(
    key: '8.8/m8_solar_backfeed/push-listen',
    textBn: 'গ্রিড গেলে ইনভার্টার বন্ধ হওয়ার কথা, কিন্তু বন্ধ হল কি না লাইনম্যান দেখতে পায় না। সোলারের ফিউজ না খুলে ওঠা মানে ব্যাক-ফিডে প্রাণের ঝুঁকি।',
    art: '$_dir/inverter.svg',
    deadly: true,
    lessonPoint: kM8SolarLessonPoint,
  );

  static DoMistake needless(M8House h) => switch (h.decoy) {
        M8Decoy.tarp => needlessTarp,
        M8Decoy.skylight => needlessSkylight,
        M8Decoy.tanks => needlessTanks,
        M8Decoy.none => needlessPlain,
      };

  static const List<DoMistake> all = [needlessTarp, needlessSkylight, needlessTanks, needlessPlain, climbLive, pushListen];

  /// The keys the catalog pack lists as deadly rules.
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

// ============================================================================
// Deal and rules
// ============================================================================

/// 6-8 houses of the eight sites, 2-4 with solar and at least 3 without (so
/// "mark all, pull all" strikes out); the clue mix, the decoys, the carrier
/// order and the cable sags shuffled; at least one solar house shows a single
/// non-roof clue; the pole carrier's sticker on at most one house.
M8SolarDeal m8SolarDeal(math.Random rng) {
  final n = 6 + rng.nextInt(3);
  final sites = [for (var i = 0; i < 8; i++) i]..shuffle(rng);
  final chosen = sites.take(n).toList()..sort();
  final solarCount = 2 + rng.nextInt(math.min(4, n - 3) - 1);
  final order = [...chosen]..shuffle(rng);
  final solarSites = order.take(solarCount).toList();
  final slots = [for (var i = 0; i < n; i++) i]..shuffle(rng);
  var carrierSticker = false;
  final clues = <int, Set<M8Clue>>{};
  // The one house known by a single non-roof clue.
  final single = solarSites.first;
  final singlePool = [M8Clue.stickerBox, M8Clue.netMeter, if (rng.nextInt(4) == 0) M8Clue.stickerCarrier];
  final pick = singlePool[rng.nextInt(singlePool.length)];
  if (pick == M8Clue.stickerCarrier) carrierSticker = true;
  clues[single] = {pick};
  for (final s in solarSites.skip(1)) {
    final c = <M8Clue>{
      if (rng.nextInt(100) < 50) M8Clue.panelsLane,
      if (rng.nextInt(100) < 35) M8Clue.panelsParapet,
      if (rng.nextInt(100) < 35) M8Clue.stickerBox,
      if (rng.nextInt(100) < 40) M8Clue.netMeter,
      if (!carrierSticker && rng.nextInt(100) < 20) M8Clue.stickerCarrier,
    };
    if (c.contains(M8Clue.stickerCarrier)) carrierSticker = true;
    if (c.isEmpty) c.add(rng.nextBool() ? M8Clue.panelsLane : M8Clue.panelsParapet);
    clues[s] = c;
  }
  final decoys = <int, M8Decoy>{};
  final nonSolar = chosen.where((s) => !solarSites.contains(s)).toList();
  for (final s in nonSolar) {
    decoys[s] = M8Decoy.values[rng.nextInt(M8Decoy.values.length)];
  }
  if (decoys.values.every((d) => d == M8Decoy.none)) {
    decoys[nonSolar[rng.nextInt(nonSolar.length)]] = M8Decoy.values[1 + rng.nextInt(3)];
  }
  final houses = [
    for (var i = 0; i < n; i++)
      M8House(
        site: chosen[i],
        solar: solarSites.contains(chosen[i]),
        clues: clues[chosen[i]] ?? const {},
        decoy: decoys[chosen[i]] ?? M8Decoy.none,
        slot: slots[i],
        sag: 28.0 + rng.nextInt(46),
        mirror: rng.nextBool(),
        palette: rng.nextInt(5),
        clutter: rng.nextInt(4),
      ),
  ];
  return M8SolarDeal(houses: houses, fault: M8Fault.values[rng.nextInt(3)], light: rng.nextInt(3));
}

/// The play state (pure logic).
class M8SolarRun {
  M8SolarRun(this.deal);
  final M8SolarDeal deal;

  /// The chalk marks (the player's own note; never scored).
  final Set<int> marked = {};

  /// Houses whose cable was traced to the pole at least once.
  final Set<int> traced = {};

  /// The carrier selected by a finished trace (a house site).
  int? selected;

  /// Sites whose carrier is out of the board (right pulls only).
  final Set<int> out = {};
  final List<int> pulledOrder = [];
  int slips = 0;
  bool climbed = false;
  DoMistake? deadly;
  bool askedBackfeed = false;
  bool askedClue = false;
  final List<String> caught = [];

  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get ended => climbed || deadly != null;
  bool get passed => climbed && deadly == null && percent >= 55;
  bool get allOut => deal.solarHouses.every((h) => out.contains(h.site));

  M8House house(int site) => deal.at(site)!;

  /// A trace reached the pole: the carrier it really ends at is selected.
  void select(int site) {
    traced.add(site);
    if (!out.contains(site)) selected = site;
  }

  /// A carrier pulled: right for a solar house; a slip for any other (the
  /// carrier springs back).
  (M8Pull, DoMistake?) pull(int site) {
    if (ended || out.contains(site)) return (M8Pull.already, null);
    final h = house(site);
    selected = null;
    if (!h.solar) {
      slips++;
      return (M8Pull.needless, M8SolarBackfeedMistakes.needless(h));
    }
    out.add(site);
    pulledOrder.add(site);
    caught.add(M8SolarBackfeedLines.caughtHouse(h));
    return (M8Pull.right, null);
  }

  /// The reasons due after a right pull of [site], in order: the back-feed
  /// question on the first right pull, the clue question on the first house
  /// known only by its sticker or net meter (after the first question when it
  /// is the same house).
  List<M8WhyKind> whyAfterPull(int site) {
    final h = house(site);
    return [
      if (!askedBackfeed) M8WhyKind.backfeed,
      if (!askedClue && h.nonRoofOnly) M8WhyKind.clue,
    ]..forEach((k) {
        if (k == M8WhyKind.backfeed) askedBackfeed = true;
        if (k == M8WhyKind.clue) askedClue = true;
      });
  }

  /// The ladder on the pole: deadly while any solar house's fuse is in (R2).
  DoMistake? climb() {
    if (ended) return null;
    if (!allOut) return deadly = M8SolarBackfeedMistakes.climbLive;
    climbed = true;
    return null;
  }

  /// Listened to the coworker: he lifts the ladder and the trainee climbs
  /// with a solar fuse in (always the case when he comes).
  DoMistake listen() => deadly = M8SolarBackfeedMistakes.pushListen;

  /// The house whose back-feed the death scene shows (a solar fuse still in).
  M8House get liveHouse => deal.solarHouses.firstWhere((h) => !out.contains(h.site), orElse: () => deal.solarHouses.first);
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   look and pan                                                ≈  4000
///   per solar house (avg 3): mark 1200, trace 3500, pull 1800   ≈ 19500
///   reasons: back-feed, clue, climb (~3 × 8000)                 ≈ 24000
///   the coworker once                                           ≈  9600
///   the ladder 2500, the coda 2600                              ≈  5100
///                                                               ≈ 62200
/// 85 % ≈ 52900 -> 50 s (a builder's estimate; owner may tune after playtest).
const m8SolarBackfeedQuickMs = 50000;

@immutable
class M8SolarBackfeedPack {
  const M8SolarBackfeedPack({required this.id, required this.titleBn, this.quickMs = m8SolarBackfeedQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M8SolarBackfeedPack> m8SolarBackfeedPacks = {
  'do_8_8_a': M8SolarBackfeedPack(id: 'do_8_8_a', titleBn: M8SolarBackfeedLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M8SolarBackfeedProbe {
  static M8SolarRun? run;
  static ValueNotifier<double>? cam;
  static M8Geo? geo;
}

// ============================================================================
// Page
// ============================================================================

class M8SolarBackfeedPage extends StatefulWidget {
  const M8SolarBackfeedPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M8SolarBackfeedPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M8SolarBackfeedPage> createState() => _M8SolarBackfeedPageState();
}

class _M8SolarBackfeedPageState extends State<M8SolarBackfeedPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SolarRunPage(
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

class _SolarRunPage extends ConsumerStatefulWidget {
  const _SolarRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M8SolarBackfeedPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SolarRunPage> createState() => _SolarRunPageState();
}

enum _Drag { none, pan, trace, pull, ladder }

enum _After { none, climb }

class _SolarRunPageState extends ConsumerState<_SolarRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M8SolarDeal _deal;
  late final M8SolarRun _run;
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
  int _taskN = 0;
  int _whyN = 0;
  int _hintN = 0;
  int _steps = 0;

  /// The camera (design px of the world's left edge): drags move it directly,
  /// nothing runs while it rests.
  final _cam = ValueNotifier<double>(M8Geo.camStart);

  /// The drag in hand and its parts.
  var _drag = _Drag.none;
  Offset _dragStart = Offset.zero;
  Offset _dragAt = Offset.zero;
  double _pullDy = 0;

  /// The trace: its house, the lit points and the finger.
  int? _traceSite;
  List<Offset>? _tracePts;
  int _traceCi = 0;
  var _traceDone = false;
  final _traceUpTo = ValueNotifier<int>(0);
  final _traceFinger = ValueNotifier<Offset?>(null);

  /// A roof held (the peek), a meter box zoomed.
  int? _peek;
  int? _zoom;

  /// The reasons still to ask after the one open, and what follows the last.
  final List<(M8WhyKind, int)> _whyQueue = [];
  var _after = _After.none;

  /// The death scene and the coda.
  var _freeze = false;
  Completer<void>? _frozen;
  var _coda = false;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  M8Geo? _geoNow;

  @override
  void initState() {
    super.initState();
    _deal = m8SolarDeal(widget.rng);
    _run = M8SolarRun(_deal);
    M8SolarBackfeedProbe.run = _run;
    M8SolarBackfeedProbe.cam = _cam;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    if (identical(M8SolarBackfeedProbe.run, _run)) {
      M8SolarBackfeedProbe.run = null;
      M8SolarBackfeedProbe.cam = null;
      M8SolarBackfeedProbe.geo = null;
    }
    _cam.dispose();
    _traceUpTo.dispose();
    _traceFinger.dispose();
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_freeze && !_coda && !struckOut;

  /// The task now, by stage (the guide's words; never the answer).
  List<String> get _stage {
    if (_run.selected != null) return M8SolarBackfeedLines.pull;
    if (_run.marked.difference(_run.traced).isNotEmpty) return M8SolarBackfeedLines.trace;
    if (_run.out.isNotEmpty) return M8SolarBackfeedLines.next;
    return M8SolarBackfeedLines.look;
  }

  String get _task => _stage.first;

  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([M8SolarBackfeedLines.look.first]));
  }

  void _stepDone() {
    _steps++;
    setState(() => _wake++);
  }

  // --- world and screen ----------------------------------------------------------
  Offset _w(Offset local) => local + Offset(_cam.value, 0);

  M8House? _hitDoor(Offset p, M8Geo g) {
    for (final h in _deal.houses) {
      if (g.door(h.site, h.mirror).inflate(8).contains(p)) return h;
    }
    return null;
  }

  M8House? _hitMeter(Offset p, M8Geo g) {
    for (final h in _deal.houses) {
      if (g.meter(h.site, h.mirror).inflate(8).contains(p)) return h;
    }
    return null;
  }

  M8House? _hitRoof(Offset p, M8Geo g) {
    for (final h in _deal.houses) {
      if (g.roof(h.site).contains(p)) return h;
    }
    return null;
  }

  M8House? _hitBracket(Offset p, M8Geo g) {
    for (final h in _deal.houses) {
      if (_run.marked.contains(h.site) && (g.bracket(h.site) - p).distance <= 28) return h;
    }
    return null;
  }

  // --- hands on -----------------------------------------------------------------
  void _tapScene(Offset local, M8Geo g) {
    if (_zoom != null) {
      _tick();
      setState(() => _zoom = null);
      return;
    }
    if (!_canPlay) return;
    final p = _w(local);
    final door = _hitDoor(p, g);
    if (door != null) {
      // The chalk mark: free, and no feedback of any kind.
      _tick('sounds/intro/click.ogg', 0.35);
      setState(() {
        if (!_run.marked.remove(door.site)) _run.marked.add(door.site);
      });
      return;
    }
    final meter = _hitMeter(p, g);
    if (meter != null) {
      _tick();
      setState(() => _zoom = meter.site);
      return;
    }
    _hints.missTap();
  }

  void _longStart(Offset local, M8Geo g) {
    if (!_canPlay || _drag != _Drag.none) return;
    if (_zoom != null) return;
    final h = _hitRoof(_w(local), g);
    if (h != null) {
      _tick();
      setState(() => _peek = h.site);
      return;
    }
    _hints.missTap();
  }

  void _longEnd() {
    if (_peek == null) return;
    setState(() => _peek = null);
  }

  void _panStart(Offset local, M8Geo g) {
    _drag = _Drag.none;
    if (!_canPlay) return;
    if (_zoom != null) setState(() => _zoom = null);
    if (_peek != null) setState(() => _peek = null);
    final p = _w(local);
    _dragStart = local;
    _dragAt = local;
    if (g.ladder.inflate(16).contains(p)) {
      _tick('sounds/intro/click.ogg', 0.4);
      setState(() => _drag = _Drag.ladder);
      return;
    }
    final sel = _run.selected;
    if (sel != null && g.slot(_run.house(sel).slot).inflate(8).contains(p)) {
      _tick('sounds/intro/click.ogg', 0.4);
      setState(() {
        _drag = _Drag.pull;
        _pullDy = 0;
      });
      return;
    }
    final br = _hitBracket(p, g);
    if (br != null) {
      _tick('sounds/intro/click.ogg', 0.4);
      _traceSite = br.site;
      _tracePts = g.cable(br);
      _traceCi = 0;
      _traceDone = false;
      _traceUpTo.value = 0;
      _traceFinger.value = p;
      setState(() {
        _drag = _Drag.trace;
        _run.selected = null;
      });
      return;
    }
    _drag = _Drag.pan;
  }

  void _panUpdate(Offset local, Offset delta, M8Geo g) {
    switch (_drag) {
      case _Drag.none:
        return;
      case _Drag.pan:
        _cam.value = (_cam.value - delta.dx).clamp(0.0, M8Geo.camMax);
      case _Drag.ladder:
        setState(() => _dragAt = local);
      case _Drag.pull:
        setState(() => _pullDy = math.max(0, local.dy - _dragStart.dy));
      case _Drag.trace:
        _traceMove(_w(local));
    }
  }

  void _traceMove(Offset p) {
    final pts = _tracePts;
    if (pts == null || _traceDone) return;
    _traceFinger.value = p;
    var best = -1;
    for (var j = _traceCi; j < math.min(_traceCi + 12, pts.length); j++) {
      if ((pts[j] - p).distance <= 24) best = j;
    }
    if (best > _traceCi) {
      _traceCi = best;
      _traceUpTo.value = best;
      if (best >= pts.length - 1) {
        _traceDone = true;
        _traced(_traceSite!);
      }
    }
  }

  void _traced(int site) {
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    _run.select(site);
    _stepDone();
    unawaited(_sayChain([M8SolarBackfeedLines.pull.first]));
  }

  void _panEnd(Offset global) {
    final d = _drag;
    _drag = _Drag.none;
    switch (d) {
      case _Drag.none:
      case _Drag.pan:
        return;
      case _Drag.trace:
        _traceFinger.value = null;
        if (!_traceDone) {
          // Let go short of the pole: the light fades, nothing else.
          _traceUpTo.value = 0;
          _hints.missTap();
        }
        _tracePts = null;
        _traceSite = null;
        setState(() => _wake++);
      case _Drag.pull:
        final site = _run.selected;
        final dy = _pullDy;
        setState(() => _pullDy = 0);
        if (site != null && dy >= 56) {
          _pull(site, global);
        } else {
          _hints.missTap();
        }
      case _Drag.ladder:
        final p = _w(_dragAt);
        final geo = _geoNow;
        setState(() => _wake++);
        if (geo != null && geo.poleDrop.contains(p)) {
          _climb(global);
        } else {
          _hints.missTap();
        }
    }
  }

  void _panCancel() {
    if (_drag == _Drag.none) return;
    final d = _drag;
    _drag = _Drag.none;
    if (d == _Drag.trace) {
      _traceUpTo.value = 0;
      _traceFinger.value = null;
      _tracePts = null;
    }
    setState(() => _pullDy = 0);
  }

  // --- pull ---------------------------------------------------------------------
  void _pull(int site, Offset origin) {
    if (!_canPlay) return;
    // The next pull waits for him once he is due (after the first right pull).
    if (holdForCoworker()) return;
    final (res, m) = _run.pull(site);
    switch (res) {
      case M8Pull.already:
        _tick();
      case M8Pull.needless:
        setState(() => _wake++);
        unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
        unawaited(_slip(m!));
      case M8Pull.right:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _stepDone();
        final first = _run.pulledOrder.length == 1;
        if (first) scheduleCoworker();
        final whys = _run.whyAfterPull(site);
        if (whys.isEmpty) {
          unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
          unawaited(_sayChain([M8SolarBackfeedLines.next.last]));
          return;
        }
        _whyQueue
          ..clear()
          ..addAll([for (final k in whys.skip(1)) (k, site)]);
        _askWhy(whys.first, site);
    }
  }

  void _askWhy(M8WhyKind kind, int site) {
    _hush();
    putOnTable(kind == M8WhyKind.backfeed ? 15 : (kind == M8WhyKind.climb ? 20 : 10));
    final clue = kind == M8WhyKind.clue ? m8ClueAsked(_run.house(site)) : null;
    unawaited(askReason(
      deal: () => dealChoices(M8SolarBackfeedLines.rightFor(kind, clue: clue), M8SolarBackfeedLines.wrongFor(kind), widget.rng),
      question: M8SolarBackfeedLines.whyQ[kind]!,
      stillValid: () => !_ended,
    ));
  }

  // --- climb --------------------------------------------------------------------
  void _climb(Offset origin) {
    if (!_canPlay) return;
    // A solar fuse is always still in when he comes: at the next pull or at
    // the first touch of the climb control, whichever is first.
    if (!coworkerDone && !coworkerDue) scheduleCoworker();
    if (holdForCoworker()) return;
    final m = _run.climb();
    if (m != null) {
      unawaited(_deadly(m));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _stepDone();
    _after = _After.climb;
    _askWhy(M8WhyKind.climb, 0);
  }

  Future<void> _startCoda() async {
    if (!mounted || _ended) return;
    _cam.value = M8Geo.camStart;
    _hush();
    setState(() {
      _coda = true;
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 3000));
    if (!mounted) return;
    unawaited(_finish());
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
    if (!mounted) return;
    if (_after == _After.climb) {
      _after = _After.none;
      unawaited(_startCoda());
      return;
    }
    if (_whyQueue.isNotEmpty) {
      final (k, site) = _whyQueue.removeAt(0);
      _askWhy(k, site);
      return;
    }
    setState(() => _wake++);
    unawaited(_sayChain([M8SolarBackfeedLines.next.last]));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M8SolarBackfeedLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || struckOut || _run.ended) return null;
    if (_intro || _card != null || tableBusy || _drag != _Drag.none || _freeze || _coda || _peek != null || _zoom != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // He lifts the ladder; the trainee climbs with a solar fuse in.
      await _deadly(_run.listen());
      return;
    }
    _run.caught.add(M8SolarBackfeedLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M8SolarBackfeedLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task of this stage again, another way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M8SolarBackfeedLines.tapWhy[_whyN++ % M8SolarBackfeedLines.tapWhy.length]
            : _stage[++_taskN % _stage.length];
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -----------------------------------------------------------------
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
      _drag = _Drag.none;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m8solar/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Up the ladder with a solar fuse in: the scene freezes grey and the
  /// back-feed comes down the chain in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    _cam.value = M8Geo.camStart;
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _drag = _Drag.none;
      _peek = null;
      _zoom = null;
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
    final speak = await SpokenOnce.first('m8solar/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M8SolarBackfeedLines.deadlyWord : M8SolarBackfeedLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
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
    if (_mark != null) return;
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
    await _say(!_run.passed ? M8SolarBackfeedLines.fail : (_quickBonus ? M8SolarBackfeedLines.quick : M8SolarBackfeedLines.allSet),
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
    if (_card != null || coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    if (_drag == _Drag.pull || _drag == _Drag.ladder || _drag == _Drag.trace) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what (see the file's header).
  HintSpec? _hint() {
    final g = _geoNow;
    if (g == null) return null;
    final cam = _cam.value;
    final n = _hintN++;
    Rect sh(Rect r) => r.shift(Offset(-cam, 0));
    bool inView(Rect r) {
      final c = sh(r).center;
      return c.dx > 6 && c.dx < 354;
    }

    final sel = _run.selected;
    if (sel != null) {
      final slot = g.slot(_run.house(sel).slot);
      if (inView(slot)) return HintSpec.drag(sh(slot).center, toward: const Offset(0, 1), travel: 52, space: HintSpace.scene);
    }
    final pend = _run.marked.difference(_run.traced);
    if (pend.isNotEmpty) {
      final b = g.bracket(pend.first);
      if (inView(Rect.fromCenter(center: b, width: 4, height: 4))) {
        final dir = M8Geo.poleX - b.dx;
        return HintSpec.drag(Offset(b.dx - cam, b.dy), toward: Offset(dir < 0 ? -1 : 1, 0.2), travel: 48, space: HintSpace.scene);
      }
      return HintSpec.swipe(Offset(180, g.groundY - 60), toward: Offset(b.dx > cam + 180 ? -1 : 1, 0), space: HintSpace.scene);
    }
    if (_run.out.isNotEmpty) {
      final rects = [
        for (final h in _deal.houses)
          if (inView(g.slot(h.slot))) sh(g.slot(h.slot)),
        if (inView(g.ladder)) sh(g.ladder),
      ];
      if (rects.length >= 2) return HintSpec.sweep(rects, space: HintSpace.scene);
    }
    if (n.isEven) return HintSpec.swipe(Offset(250, g.groundY - 60), toward: const Offset(-1, 0), space: HintSpace.scene);
    final rects = [
      for (final h in _deal.houses) ...[
        if (inView(g.roof(h.site))) sh(g.roof(h.site)),
        if (inView(g.meter(h.site, h.mirror))) sh(g.meter(h.site, h.mirror)),
      ],
    ];
    return rects.length >= 2 ? HintSpec.sweep(rects, space: HintSpace.scene) : HintSpec.swipe(Offset(250, g.groundY - 60), toward: const Offset(-1, 0), space: HintSpace.scene);
  }

  Widget _worldLayer(Key key, Widget child) => Positioned.fill(
        key: key,
        child: ClipRect(
          child: ValueListenableBuilder<double>(
            valueListenable: _cam,
            builder: (_, cam, ch) => Transform.translate(offset: Offset(-cam, 0), child: ch),
            child: OverflowBox(alignment: Alignment.topLeft, minWidth: M8Geo.worldW, maxWidth: M8Geo.worldW, child: child),
          ),
        ),
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M8SolarBackfeedProbe.geo = M8Geo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final r = _run;
    final world = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          key: const ValueKey('lane'),
          child: RepaintBoundary(child: CustomPaint(painter: M8WorldPainter(geo: geo, deal: _deal))),
        ),
        Positioned.fill(
          key: const ValueKey('board'),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: M8BoardPainter(geo: geo, deal: _deal, out: {...r.out}, selected: r.selected, pullDy: _drag == _Drag.pull ? _pullDy : 0),
            ),
          ),
        ),
        Positioned.fill(
          key: const ValueKey('marks'),
          child: IgnorePointer(child: CustomPaint(painter: M8MarksPainter(geo: geo, deal: _deal, marked: {...r.marked}))),
        ),
        Positioned.fill(
          key: const ValueKey('trace'),
          child: IgnorePointer(
            child: CustomPaint(painter: M8TracePainter(points: () => _tracePts, upTo: _traceUpTo, finger: _traceFinger)),
          ),
        ),
        if (!_coda)
          Positioned.fromRect(
            key: const ValueKey('trainee'),
            rect: geo.trainee,
            child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
          ),
        Positioned.fromRect(
          key: const ValueKey('pouch'),
          rect: geo.pouch,
          child: Semantics(label: M8SolarBackfeedLines.pouchLabel, child: CustomPaint(painter: M8PouchPainter(count: r.out.length))),
        ),
        if (!_coda)
          Positioned.fromRect(
            key: const ValueKey('ladder'),
            rect: geo.ladder,
            child: Semantics(
              label: M8SolarBackfeedLines.ladderLabel,
              child: Opacity(opacity: _drag == _Drag.ladder ? 0.3 : 1, child: const CustomPaint(painter: M8LadderPainter())),
            ),
          ),
        if (_coda) ..._codaLayers(geo, quiet),
      ],
    );
    final house = _freeze && _card == null ? r.liveHouse : null;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: ClipRect(
            child: ValueListenableBuilder<double>(
              valueListenable: _cam,
              builder: (_, cam, ch) => Transform.translate(offset: Offset(-cam, 0), child: ch),
              child: OverflowBox(alignment: Alignment.topLeft, minWidth: M8Geo.worldW, maxWidth: M8Geo.worldW, child: world),
            ),
          ),
        ),
      ),
      // The death scene's chain, in colour over the grey.
      if (house != null)
        _worldLayer(
          const ValueKey('chain'),
          IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 2100),
              builder: (_, v, _) => CustomPaint(painter: M8ChainPainter(geo: geo, house: house, fault: _deal.fault, v: v)),
            ),
          ),
        ),
      if (_peek != null)
        Positioned(
          key: ValueKey('peek-$_peek'),
          left: 100,
          top: 156,
          width: 160,
          height: 104,
          child: IgnorePointer(
            child: Semantics(
              label: M8SolarBackfeedLines.roofLabel,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SlmColors.gold300, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10)],
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CustomPaint(painter: M8RoofPlanPainter(house: r.house(_peek!)))),
              ),
            ),
          ),
        ),
      if (_zoom != null)
        Positioned(
          key: ValueKey('zoom-$_zoom'),
          left: 70,
          top: 150,
          width: 220,
          height: 168,
          child: IgnorePointer(child: _MeterZoom(house: r.house(_zoom!))),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M8SolarBackfeedLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (d) => _tapScene(d.localPosition, geo),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, d.delta, geo),
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: _panCancel,
            onLongPressStart: (d) => _longStart(d.localPosition, geo),
            onLongPressEnd: (_) => _longEnd(),
            onLongPressCancel: _longEnd,
          ),
        ),
      ),
      // The ladder in hand, under the finger.
      if (_drag == _Drag.ladder)
        Positioned(
          key: const ValueKey('drag-ladder'),
          left: _dragAt.dx - 11,
          top: _dragAt.dy - 70,
          width: 22,
          height: 124,
          child: const IgnorePointer(child: CustomPaint(painter: M8LadderPainter(vertical: true))),
        ),
    ];
  }

  /// The safe climb's coda in the world: the crew's tester, 0 V (ডেড), the
  /// earths, the trainee a few rungs up (silent captions; art only).
  List<Widget> _codaLayers(M8Geo geo, bool quiet) {
    Widget chip(String text, Offset at, double delay) => Positioned(
          key: ValueKey('coda-$text'),
          left: at.dx - 46,
          top: at.dy,
          width: 92,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 2400),
              builder: (_, v, child) => Opacity(opacity: ((v * 3) - delay).clamp(0.0, 1.0), child: child),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xEEFFFFFF), borderRadius: BorderRadius.circular(6)),
                  child: Text(text, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF1F3A1F))),
                ),
              ),
            ),
          ),
        );
    return [
      Positioned.fill(
        key: const ValueKey('crew'),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 2400),
            builder: (_, v, _) => CustomPaint(painter: M8CrewPainter(geo: geo, v: v)),
          ),
        ),
      ),
      chip(M8SolarBackfeedLines.crewLive, Offset(geo.pole.center.dx + 64, geo.groundY - 244), 0),
      chip(M8SolarBackfeedLines.crewDead, Offset(geo.pole.center.dx + 64, geo.groundY - 222), 1),
      chip(M8SolarBackfeedLines.crewEarth, Offset(geo.pole.center.dx - 64, geo.groundY - 150), 2),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_coda && !_ended;
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && _drag == _Drag.none && _peek == null && _zoom == null,
            hintKey: '${_run.marked.length}/${_run.selected}/${_run.out.length}/${_run.slips}/$_steps',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
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
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : pad.bottom * 0.6 + 2, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M8SolarBackfeedLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: kM8SolarLessonPoint, muted: _muted)),
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

/// A meter box zoomed: the net meter shows Import and Export pages with their
/// arrows; an ordinary meter one reading; a sticker shows when the box wears
/// one. Every box answers alike (the card looks the same for all).
class _MeterZoom extends StatelessWidget {
  const _MeterZoom({required this.house});
  final M8House house;

  @override
  Widget build(BuildContext context) {
    const lcd = Color(0xFF9DBB8E);
    TextStyle mono(double s) => TextStyle(fontSize: s, fontWeight: FontWeight.w800, color: const Color(0xFF1F2A1F), fontFamily: 'monospace', height: 1.1);
    Widget row(String arrow, String word, String digits) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(arrow, style: mono(18)),
              const SizedBox(width: 6),
              Text(word, style: mono(14)),
              const SizedBox(width: 12),
              Text(digits, style: mono(16)),
            ],
          ),
        );
    return Semantics(
      label: M8SolarBackfeedLines.meterLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFB8BDC2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6C7278), width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 12)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: lcd, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF2E3B33), width: 2)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: house.netMeter
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  row('→', M8SolarBackfeedLines.importWord, enDigits('01234.5')),
                                  row('←', M8SolarBackfeedLines.exportWord, enDigits('00456.7')),
                                ],
                              )
                            : Center(child: Text(enDigits('01234.5 kWh'), style: mono(20))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
              Positioned(
                left: 0,
                bottom: 2,
                child: Container(width: 22, height: 14, decoration: BoxDecoration(color: const Color(0xFFE8E8E8), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF6C7278)))),
              ),
              if (house.stickerBox)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF2FA24A), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white, width: 1.2)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(M8SolarBackfeedLines.solarSticker, style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
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
