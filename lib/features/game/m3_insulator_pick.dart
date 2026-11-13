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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm3_insulator_pick_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_insulator_pick_world.dart' show M3InsulatorPickKind, M3InsulatorPickSite;

// Lesson 3.2, কাজ 1: "কোথায় কোন ইনসুলেটর". A new line is going up; at each
// pole the store's insulators lie on a tarp at its foot. Read the pole — does
// the line run straight past it, or end there (dead end, a stay wire pulling
// back)? HT or LT (its danger board)? — and pick the insulator the lesson
// gives for that spot: a pin insulator where the line runs straight (up to
// 33 kV); a shackle where an LT line ends or turns; a string of discs where an
// HT line ends (one disc for 11 kV, three for 33 kV — count them). Take one
// in hand first: run a finger over it (a hairline crack shows only where the
// hand has been) and turn it to see its back (a chipped shed). Three poles,
// easy to hard. Once a play the careless coworker (level 1's rival) peeps in:
// "পিন ইনসুলেটরেই চলবে, ডিস্ক লাগবে না!" (or শ্যাকল), or the lesson's myth
// "এক কোণা একটু ভেঙেছে তো কী হয়েছে?". Built on the shared level kit
// (GAME_LEVEL_PLAYBOOK.md): guide first, full scene, corner guide, ◆ on the
// table → "কেন …?" → the next pole by itself.
//
// Deadly: none — the line is new and not yet charged; the lesson makes a
// wrong or broken insulator a fault that breaks, leaks or flashes over later
// (“মৃত্যুফাঁদ” for whoever works there afterwards), not a death on the spot.
// Every fault is a slip; 3 slips fail.
//
// Numbers used (lesson 3.2 + its reviewed film script only): pin up to 33 kV on
// straight lines; one disc = 11 kV, three = 33 kV. The 132 kV string (film:
// 8–10 discs; the lesson's older "6 or more") is not played — no distribution
// pole carries it.
//
// Voice: the guide's lines on device TTS; the coworker's pushes are new
// (silent with the caption held until recorded); his exit line is recorded.
//
// Kit timing (audit 2026-11-11): the scene takes no input in the praise
// window ([ReasonTable.tableBusy]); lifting an insulator off the tarp waits
// for the coworker when he is due ([CoworkerMoment.holdForCoworker]) — he
// always comes before anything is in hand, so his push is about the tarp;
// gesture hints: a sweep over the tarp, a rub-and-turn on the insulator in
// hand, then a sweep over its two buttons; a tap to close the board.
// Art: the scene and the insulators are drawn in code
// (m3_insulator_pick_world.dart); the mistake cards use
// assets/game/art/m3_insulator_pick/.

// ============================================================================
// Content
// ============================================================================

typedef _Kind = M3InsulatorPickKind;
typedef _Site = M3InsulatorPickSite;

enum M3InsulatorPickFlaw { none, chip, crack }

typedef _Flaw = M3InsulatorPickFlaw;

@immutable
class M3InsulatorPickItem {
  const M3InsulatorPickItem({required this.id, required this.kind, this.discs = 0, this.flaw = M3InsulatorPickFlaw.none});
  final String id;
  final M3InsulatorPickKind kind;

  /// Discs in the string (a disc string only).
  final int discs;
  final M3InsulatorPickFlaw flaw;
}

/// The pole being fitted.
@immutable
class M3InsulatorPickSpot {
  const M3InsulatorPickSpot({required this.site, this.kv = 0});
  final M3InsulatorPickSite site;

  /// The line's voltage, kV (HT only).
  final int kv;

  bool get ht => site != M3InsulatorPickSite.endLt;

  /// The danger board's text.
  String get plate => ht ? '${enDigits('$kv')} kV' : '440 V';

  /// The lesson's disc count for an HT line: 1 for 11 kV, 3 for 33 kV.
  int get discsNeeded => kv >= 33 ? 3 : 1;

  /// The kind the lesson gives for this spot.
  M3InsulatorPickKind get rightKind => switch (site) {
        M3InsulatorPickSite.straightHt => M3InsulatorPickKind.pin,
        M3InsulatorPickSite.endLt => M3InsulatorPickKind.shackle,
        M3InsulatorPickSite.endHt => M3InsulatorPickKind.disc,
      };

  bool suits(M3InsulatorPickItem i) => i.kind == rightKind && (i.kind != M3InsulatorPickKind.disc || i.discs == discsNeeded);
  bool fits(M3InsulatorPickItem i) => suits(i) && i.flaw == M3InsulatorPickFlaw.none;
}

@immutable
class M3InsulatorPickRound {
  const M3InsulatorPickRound({required this.spot, required this.items});
  final M3InsulatorPickSpot spot;
  final List<M3InsulatorPickItem> items;

  /// The right kind, but chipped or cracked.
  M3InsulatorPickItem? get twin {
    for (final i in items) {
      if (spot.suits(i) && i.flaw != M3InsulatorPickFlaw.none) return i;
    }
    return null;
  }
}

/// What the careless coworker pushes: a chipped one ("এক কোণা একটু ভেঙেছে
/// তো কী হয়েছে?"), or a pin where the line ends.
enum M3InsulatorPickPush { chip, pin }

@immutable
class M3InsulatorPickDeal {
  const M3InsulatorPickDeal({required this.rounds, required this.callRound, required this.callChip});
  final List<M3InsulatorPickRound> rounds;

  /// The pole on which the coworker peeps in (or a later one, if that one
  /// was done before he could).
  final int callRound;

  /// He pushes the chipped one (when it is still there); otherwise the pin.
  final bool callChip;
}

abstract final class M3InsulatorPickLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask, inspectAsk];

  static const title = 'কোথায় কোন ইনসুলেটর';
  static const intro = 'নতুন লাইন বসছে! প্রতিটা পোলে ঠিক ইনসুলেটর বাছুন।';
  static const rounds = ['প্রথম পোল', 'দ্বিতীয় পোল', 'শেষ পোল'];
  static const ask = 'লাইন আর বোর্ড দেখুন। কোন ইনসুলেটরটা?';
  static const inspectAsk = 'গায়ে আঙুল বুলিয়ে, ঘুরিয়েও দেখুন। লাগাবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (and screen-reader names).
  static const itemLabel = 'ইনসুলেটর';
  static const handLabel = 'ইনসুলেটর হাতে';
  static const backLabel = 'পেছন দিক';
  static const plateLabel = 'পোলের বোর্ড';
  static String plateBn(M3InsulatorPickSpot s) => s.ht ? '${enDigits('${s.kv}')} কেভি লাইন' : 'এলটি লাইন';
  static const take = 'এটাই লাগান';
  static const putBack = 'ফেরত রাখুন';
  static const rejected = 'বাদ';

  // The reasons (lesson 3.2): the right ones fit this pole. Every card is
  // 36–46 letters, so none stands out by its length.
  static const packAsk = 'কেন এই ইনসুলেটরটা নিলেন?';
  static const _pin = 'সোজা লাইনে 33 কেভি পর্যন্ত পিন ইনসুলেটরই চলে';
  static const _shackle = 'এলটি লাইনের শেষে টান বেশি — তাই শ্যাকল নিলাম';
  static const _disc11 = '11 কেভির টানের জায়গায় এক ডিস্কের মালা';
  static const _disc33 = '33 কেভিতে তিন ডিস্কের মালা — গুনে নিয়েছি';
  static const _straightNot = 'লাইন সোজা গেছে, তাই পিন ইনসুলেটরই যথেষ্ট';
  static const _endNot = 'লাইনের শেষে টান বেশি, তাই টান সইবে এমনটা নিলাম';
  static const packMyths = [
    'যেকোনো ইনসুলেটর যেকোনো পোলে লাগানো যায়',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিয়ে নিলাম',
    'বড়টা দেখতে বেশি মজবুত, তাই সেটাই নিলাম',
    'কোণা একটু ভাঙা হলেও কাজ ঠিক চলে যায়',
    'চিনামাটি তো মোটা, একটু ফাটলে কিছু হয় না',
  ];

  /// Why this insulator at [s]: the lesson's rule for the spot.
  static List<String> packRight(M3InsulatorPickSpot s) => switch (s.site) {
        M3InsulatorPickSite.straightHt => const [_pin, 'লাইন সোজা গেছে, তাই পিন — শেডেও কোনো ভাঙন নেই'],
        M3InsulatorPickSite.endLt => const [_shackle, 'মোড়ে বা ডেড-এন্ডে পিন ভাঙে, শ্যাকল টান সয়'],
        M3InsulatorPickSite.endHt => [s.discsNeeded == 3 ? _disc33 : _disc11, 'লাইনের শেষের প্রচণ্ড টানে ডিস্কের মালাই টেকে'],
      };

  /// Wrong reasons that name the very kind fitted at [s] (a wrong
  /// rationale): the right card is never the only one with that word.
  static List<String> packDecoys(M3InsulatorPickSpot s) => switch (s.site) {
        M3InsulatorPickSite.straightHt => const [
            'পিন নিলাম, কারণ ওটাই সবচেয়ে হালকা আর ছোট',
            'পিন সব পোলেই চলে, তাই কিছু না দেখেই পিন নিলাম',
            'পিন নিলাম — নতুন জিনিস, গা দেখার দরকার নেই',
          ],
        M3InsulatorPickSite.endLt => const [
            'শ্যাকল নিলাম, দেখতে গোল তাই সব জায়গায় চলে',
            'শ্যাকল সবচেয়ে সস্তা, তাই শ্যাকলই তুলে নিলাম',
            'শ্যাকল নিলাম — ছোট জিনিস, ভাঙলেও কিছু হয় না',
          ],
        M3InsulatorPickSite.endHt => const [
            'ডিস্কের মালা লম্বা, তাই গুনে দেখার দরকার নেই',
            'ডিস্কের মালা দেখতে বড়, তাই সেটাই নিয়ে নিলাম',
            'ডিস্ক নিলাম — চিনামাটি মোটা, ফাটল দেখিনি',
          ],
      };

  /// The decoys, the other spots' rules (true elsewhere, not here) and the myths.
  static List<String> packWrong(M3InsulatorPickSpot s) => [
        ...packDecoys(s),
        ...switch (s.site) {
          M3InsulatorPickSite.straightHt => const [_shackle, _endNot, ...packMyths],
          M3InsulatorPickSite.endLt => const [_pin, _straightNot, _disc11, ...packMyths],
          M3InsulatorPickSite.endHt => [_pin, _straightNot, _shackle, s.discsNeeded == 3 ? _disc11 : _disc33, ...packMyths],
        },
      ];

  /// The "কেন?" hand at [s]: one right reason, one decoy that names the
  /// same kind, and one more wrong one — so the kind's name never picks
  /// the right card.
  static List<ChoiceOption> dealPack(M3InsulatorPickSpot s, math.Random rng) {
    final decoys = packDecoys(s);
    final decoy = decoys[rng.nextInt(decoys.length)];
    final rest = [for (final w in packWrong(s)) if (w != decoy) w]..shuffle(rng);
    final right = packRight(s);
    return [
      ChoiceOption(right[rng.nextInt(right.length)], true),
      ChoiceOption(decoy, false),
      ChoiceOption(rest.first, false),
    ]..shuffle(rng);
  }

  /// The careless coworker: the shortcuts the lesson warns of.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerChip = CoworkerScript(
    line: 'এক কোণা একটু ভেঙেছে তো কী হয়েছে? লাগিয়ে দাও!',
    exitLine: coworkerExit,
    right: ['না — ভাঙা ইনসুলেটর বদলাতেই হবে', 'ভাঙা খাঁজে জল জমে কারেন্ট লিক করে', 'কোণা ভাঙা ইনসুলেটর লাগাব না, ভাই'],
    wrong: [
      'ঠিক, ভাঙাটাই লাগিয়ে দিই এবার',
      'একটু ভাঙায় কিছু হয় না, ওটাই নিই',
      'মোটা চিনামাটি, ওতেই চলে যাবে',
      'এবারটা ভাঙাটাতেই চালিয়ে নিই',
      'সবাই তো হাতের কাছেরটাই নেয়',
    ],
    asks: ['ও বলছে কোণা ভাঙায় কিছু হয় না। কী করবেন?', 'ভাঙাটা লাগাবেন, না ভালোটা?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerPinShackle = CoworkerScript(
    line: 'পিন ইনসুলেটরেই চলবে, শ্যাকল লাগবে না!',
    exitLine: coworkerExit,
    right: ['না — লাইনের শেষে পিন ভেঙে যাবে', 'ডেড-এন্ডের টান পিন সইতে পারে না', 'এখানে শ্যাকলই লাগবে, পিন নয়, ভাই'],
    wrong: [
      'ঠিক, পিনটাই লাগিয়ে দিই এবার',
      'পিন তো হাতের কাছেই, ওটাই নিই',
      'টান তো সামান্য, পিনেই চলে যাবে',
      'এবারটা পিনেই চালিয়ে নিই, ভাই',
      'সবাই তো যেটা পায় সেটাই লাগায়',
    ],
    asks: ['ও বলছে পিনেই চলবে। কী করবেন?', 'পিন লাগাবেন, না শ্যাকল?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerPinDisc = CoworkerScript(
    line: 'পিন ইনসুলেটরেই চলবে, ডিস্ক লাগবে না!',
    exitLine: coworkerExit,
    right: ['না — লাইনের শেষে পিন ভেঙে যাবে', 'টানের জায়গায় ডিস্কের মালাই লাগে', 'এখানে ডিস্কের মালা চাই, পিন নয়'],
    wrong: [
      'ঠিক, পিনটাই লাগিয়ে দিই এবার',
      'মালা ঝোলানো ঝামেলা, পিনই নিই',
      'টান তো সামান্য, পিনেই চলে যাবে',
      'এবারটা পিনেই চালিয়ে নিই, ভাই',
      'সবাই তো যেটা পায় সেটাই লাগায়',
    ],
    asks: ['ও বলছে ডিস্ক লাগবে না। কী করবেন?', 'পিন লাগাবেন, না ডিস্কের মালা?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(M3InsulatorPickPush p, M3InsulatorPickSite site) => p == M3InsulatorPickPush.chip
      ? coworkerChip
      : (site == M3InsulatorPickSite.endHt ? coworkerPinDisc : coworkerPinShackle);

  /// His new lines (no clip yet: silent with the caption held until recorded).
  static const newRivalLines = [
    'এক কোণা একটু ভেঙেছে তো কী হয়েছে? লাগিয়ে দাও!',
    'পিন ইনসুলেটরেই চলবে, শ্যাকল লাগবে না!',
    'পিন ইনসুলেটরেই চলবে, ডিস্ক লাগবে না!',
  ];

  static const callHeld = 'ঠিক! জায়গা বুঝে, ভালো ইনসুলেটরই লাগান।';
  static const fitted = 'ঠিক জায়গায় ঠিক ইনসুলেটর!';
  static const allSet = 'ইনসুলেটর বাছাইয়ে পাকা হাত! জায়গা, ডিস্ক আর অবস্থা — সবই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — লাইন সোজা, না শেষ? আর ইনসুলেটরের গা ভালো করে দেখুন।';
  static const caughtMatch = 'জায়গা বুঝে ইনসুলেটর';
  static const caughtDiscs = 'ডিস্ক গুনে মালা';
  static const caughtFlaw = 'ভাঙা-ফাটা ইনসুলেটর বাদ';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// Every fixed line the guide says (for recording).
  static const guideLines = [intro, ask, inspectAsk, ...tapWhy, packAsk, callHeld, fitted, allSet, quick, fail];
}

abstract final class M3InsulatorPickMistakes {
  static const _where = 'assets/game/art/m3_insulator_pick/where_which.svg';
  static const _count = 'assets/game/art/m3_insulator_pick/disc_count.svg';
  static const _flaws = 'assets/game/art/m3_insulator_pick/flaws.svg';

  // Lesson 3.2's points (0-based, as DoMistake.lessonPoint): 0 = what an
  // insulator is, 1 = pin, 2 = shackle, 3 = disc (its daily check: the
  // hairline crack).
  static const pinAtEnd = DoMistake(
    key: '3.2/m3_insulator_pick/pin-at-end',
    textBn: 'লাইন যেখানে শেষ হয় বা মোড় নেয়, সেখানে পিন ইনসুলেটর চলবে না — প্রচণ্ড টানে ভেঙে যাবে। এলটিতে শ্যাকল, এইচটিতে ডিস্কের মালা।',
    art: _where,
    lessonPoint: 2,
  );
  static const shackleOnStraight = DoMistake(
    key: '3.2/m3_insulator_pick/shackle-on-straight',
    textBn: 'লাইন এখানে সোজা গেছে — 33 কেভি পর্যন্ত সোজা লাইনে পিন ইনসুলেটরই রাজা। শ্যাকল লাগে লাইনের শেষে বা মোড়ে, মূলত এলটিতে।',
    art: _where,
    lessonPoint: 1,
  );
  static const shackleOnHt = DoMistake(
    key: '3.2/m3_insulator_pick/shackle-on-ht',
    textBn: 'এটা এইচটি লাইনের শেষ প্রান্ত — 11 কেভি বা তার ওপরের লাইনে টানের জায়গায় ডিস্কের মালা লাগে। শ্যাকল মূলত এলটি লাইনের।',
    art: _where,
    lessonPoint: 3,
  );
  static const discOnLt = DoMistake(
    key: '3.2/m3_insulator_pick/disc-on-lt',
    textBn: 'এটা এলটি লাইনের শেষ — এখানে শ্যাকল ইনসুলেটর, ডি-আয়রন ক্ল্যাম্পে। ডিস্কের মালা 11 কেভি বা তার ওপরের লাইনের।',
    art: _where,
    lessonPoint: 2,
  );
  static const fewDiscs = DoMistake(
    key: '3.2/m3_insulator_pick/few-discs',
    textBn: 'ডিস্ক গুনুন: একটা ডিস্ক 11 কেভির, তিনটে 33 কেভির। 33 কেভির লাইনে এক ডিস্কের মালা কম পড়বে।',
    art: _count,
    lessonPoint: 3,
  );
  static const chip = DoMistake(
    key: '3.2/m3_insulator_pick/chipped',
    textBn: 'এক কোণা ভাঙা — ভাঙা খাঁজে জল-ধুলো জমে, সেখান থেকেই লিকেজ কারেন্ট শুরু হয়। ভাঙা ইনসুলেটর লাগানো নয়, বদলাতেই হবে।',
    art: _flaws,
    lessonPoint: 0,
  );
  static const crack = DoMistake(
    key: '3.2/m3_insulator_pick/cracked',
    textBn: 'সরু চুলের মতো ফাটল (Hairline Crack) — হাই ভোল্টেজে ওই ফাটল দিয়েই ব্লাস্ট হয়। ফাটা ইনসুলেটর কখনো লাগাবেন না।',
    art: _flaws,
    lessonPoint: 3,
  );
  static List<DoMistake> get all => const [pinAtEnd, shackleOnStraight, shackleOnHt, discOnLt, fewDiscs, chip, crack];

  /// What taking [i] at [s] gets wrong, or null when it is the right kind
  /// (and the right count of discs).
  static DoMistake? wrongFor(M3InsulatorPickSpot s, M3InsulatorPickItem i) {
    if (s.suits(i)) return null;
    return switch ((s.site, i.kind)) {
      (_Site.straightHt, _) => shackleOnStraight,
      (_Site.endLt, _Kind.pin) => pinAtEnd,
      (_Site.endLt, _) => discOnLt,
      (_Site.endHt, _Kind.pin) => pinAtEnd,
      (_Site.endHt, _Kind.shackle) => shackleOnHt,
      (_Site.endHt, _Kind.disc) => fewDiscs,
    };
  }
}

/// A fresh line each play: voltages, flaws, the tarp's order and the
/// coworker's moment vary.
M3InsulatorPickDeal m3InsulatorPickDeal(math.Random rng) {
  var n = 0;
  M3InsulatorPickItem item(_Kind k, {int discs = 0, _Flaw f = _Flaw.none}) =>
      M3InsulatorPickItem(id: 'ins${n++}', kind: k, discs: discs, flaw: f);
  int kv() => rng.nextBool() ? 11 : 33;

  // 1: easy — the line runs straight past an HT pole: a pin, a chipped pin, a shackle.
  final s1 = M3InsulatorPickSpot(site: _Site.straightHt, kv: kv());
  final r1 = [item(_Kind.pin), item(_Kind.pin, f: _Flaw.chip), item(_Kind.shackle)]..shuffle(rng);
  // 2: an LT line ends — a shackle, a faulty shackle, a pin, a one-disc string.
  const s2 = M3InsulatorPickSpot(site: _Site.endLt);
  final r2 = [
    item(_Kind.shackle),
    item(_Kind.shackle, f: rng.nextBool() ? _Flaw.chip : _Flaw.crack),
    item(_Kind.pin),
    item(_Kind.disc, discs: 1),
  ]..shuffle(rng);
  // 3: an HT line ends — the right string, the same string with a hairline
  // crack, a pin, a shackle; on 33 kV also a one-disc string (count them).
  final s3 = M3InsulatorPickSpot(site: _Site.endHt, kv: kv());
  final d = s3.discsNeeded;
  final r3 = [
    item(_Kind.disc, discs: d),
    item(_Kind.disc, discs: d, f: _Flaw.crack),
    item(_Kind.pin),
    item(_Kind.shackle),
    if (d == 3) item(_Kind.disc, discs: 1),
  ]..shuffle(rng);
  final rounds = [
    M3InsulatorPickRound(spot: s1, items: r1),
    M3InsulatorPickRound(spot: s2, items: r2),
    M3InsulatorPickRound(spot: s3, items: r3),
  ];
  return M3InsulatorPickDeal(rounds: rounds, callRound: rng.nextInt(rounds.length), callChip: rng.nextBool());
}

/// The insulator the coworker would push on pole [r] now (still on the tarp), or null.
M3InsulatorPickItem? m3InsulatorPickPushed(M3InsulatorPickRound r, Set<String> gone, M3InsulatorPickPush p) {
  for (final i in r.items) {
    if (gone.contains(i.id)) continue;
    if (p == M3InsulatorPickPush.chip && i.flaw == _Flaw.chip) return i;
    if (p == M3InsulatorPickPush.pin && r.spot.site != _Site.straightHt && i.kind == _Kind.pin) return i;
  }
  return null;
}

/// What the coworker can push on pole [r] now: the dealt push first
/// ([preferChip]), else the other; null when neither is on the tarp.
M3InsulatorPickPush? m3InsulatorPickPushFor(M3InsulatorPickRound r, Set<String> gone, {required bool preferChip}) {
  final chip = m3InsulatorPickPushed(r, gone, M3InsulatorPickPush.chip) != null;
  final pin = m3InsulatorPickPushed(r, gone, M3InsulatorPickPush.pin) != null;
  if (preferChip && chip) return M3InsulatorPickPush.chip;
  if (pin) return M3InsulatorPickPush.pin;
  return chip ? M3InsulatorPickPush.chip : null;
}

enum M3InsulatorPickVerdict { right, slip }

@immutable
class M3InsulatorPickOutcome {
  const M3InsulatorPickOutcome(this.verdict, {this.mistake});
  final M3InsulatorPickVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class M3InsulatorPickRun {
  M3InsulatorPickRun(this.deal);
  final M3InsulatorPickDeal deal;
  int round = 0;
  int slips = 0;

  /// The right insulator, fitted: the reason comes, then [next].
  M3InsulatorPickItem? fitted;
  bool get shown => fitted != null;

  /// Insulators set aside on this pole (wrong ones taken by mistake). Putting
  /// one back never sets it aside: it goes back on the tarp, whatever it is,
  /// so the reply stays neutral before the decision.
  final Set<String> rejected = {};

  /// Insulators on this pole whose fault the player has seen.
  final Set<String> spotted = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  M3InsulatorPickRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  M3InsulatorPickOutcome _slip(DoMistake m, M3InsulatorPickItem i) {
    slips++;
    rejected.add(i.id);
    return M3InsulatorPickOutcome(M3InsulatorPickVerdict.slip, mistake: m);
  }

  /// Fits [i] at the pole.
  M3InsulatorPickOutcome take(M3InsulatorPickItem i) {
    if (done || shown || rejected.contains(i.id)) return const M3InsulatorPickOutcome(M3InsulatorPickVerdict.slip);
    final s = current.spot;
    final wrong = M3InsulatorPickMistakes.wrongFor(s, i);
    if (wrong != null) return _slip(wrong, i);
    if (i.flaw != _Flaw.none) {
      spotted.add(i.id);
      return _slip(i.flaw == _Flaw.chip ? M3InsulatorPickMistakes.chip : M3InsulatorPickMistakes.crack, i);
    }
    fitted = i;
    _tag(M3InsulatorPickLines.caughtMatch);
    if (i.kind == _Kind.disc && i.discs > 1) _tag(M3InsulatorPickLines.caughtDiscs);
    // The pole closes: a fault the player found and did not fit (the faulty
    // ones fitted went aside as slips) was a flaw caught.
    if (spotted.any((id) => !rejected.contains(id))) _tag(M3InsulatorPickLines.caughtFlaw);
    return const M3InsulatorPickOutcome(M3InsulatorPickVerdict.right);
  }

  /// The player's hand or eye found [i]'s fault in the close look.
  void spot(M3InsulatorPickItem i) {
    if (i.flaw != _Flaw.none) spotted.add(i.id);
  }

  /// The next pole (after the reason).
  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    fitted = null;
  }
}

@immutable
class M3InsulatorPickPack {
  const M3InsulatorPickPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3InsulatorPickPack32 = M3InsulatorPickPack(id: 'do_3_2_a', titleBn: M3InsulatorPickLines.title);
const Map<String, M3InsulatorPickPack> m3InsulatorPickPacks = {'do_3_2_a': m3InsulatorPickPack32};

// ============================================================================
// Page
// ============================================================================

typedef _L = M3InsulatorPickLines;
typedef _Item = M3InsulatorPickItem;

class M3InsulatorPickPage extends StatefulWidget {
  const M3InsulatorPickPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3InsulatorPickPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3InsulatorPickPage> createState() => _M3InsulatorPickPageState();
}

class _M3InsulatorPickPageState extends State<M3InsulatorPickPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _RunPage(
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

class _RunPage extends ConsumerStatefulWidget {
  const _RunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3InsulatorPickPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_RunPage> createState() => _RunPageState();
}

class _RunPageState extends ConsumerState<_RunPage> with DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3InsulatorPickRun _run = M3InsulatorPickRun(m3InsulatorPickDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The insulator in the trainee's hands (the close look).
  _Item? _held;
  var _plateOpen = false;
  DoMistake? _card;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  M3InsulatorPickPush _push = M3InsulatorPickPush.pin;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final _itemKeys = <String, GlobalKey>{};
  /// A fresh key per lift (the close look of one insulator).
  var _inspectKey = GlobalKey<_InspectState>();
  final _plateZoomKey = GlobalKey();

  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice (never holds the player) -------------------------------------------

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

  String get _task => _held != null ? _L.inspectAsk : _L.ask;

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([_L.ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || tableBusy || reasonOpen || _run.shown;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// An insulator comes off the tarp into the trainee's hands.
  void _pick(_Item i, Offset origin) {
    // While he is on screen every tarp tap is ignored alike (the one he
    // pushes too): a tap that did something on some insulators and nothing
    // on his would point him out. The player answers him on the deck.
    if (_blocked || coworkerOpen || _held != null || _plateOpen || _run.rejected.contains(i.id)) return;
    // The decisive control: while he is due, he comes in now (with nothing
    // in hand, so his push is about the tarp) and this lift waits.
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.5, muted: false));
    _hush();
    setState(() {
      _held = i;
      _inspectKey = GlobalKey<_InspectState>(debugLabel: 'inspect-${i.id}');
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([_L.inspectAsk]));
  }

  /// A fault came into view under the hand or the eye. Silent on purpose:
  /// a sound or buzz here would tell a fault the eye has not seen.
  void _found() {
    final i = _held;
    if (i != null) _run.spot(i);
  }

  /// Back on the tarp — every insulator the same way, sound or faulty, with
  /// the same neutral reply (never a hint before the decision; a fault found
  /// is credited when the pole closes on a right fit).
  void _putBack() {
    final i = _held;
    if (i == null || _blocked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
    unawaited(_sayChain([_L.ask]));
  }

  void _take(Offset origin) {
    final i = _held;
    if (i == null || _blocked) return;
    setState(() => _held = null);
    _judgeTake(i, origin);
  }

  void _judgeTake(_Item i, Offset origin) {
    final o = _run.take(i);
    if (o.verdict == M3InsulatorPickVerdict.right) {
      HapticFeedback.lightImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      final s = _run.current.spot;
      _ask(15, () => _L.dealPack(s, widget.rng), _L.packAsk, lead: _L.fitted);
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  /// A right move: the ◆ wait on the table, then "কেন …?".
  void _ask(int points, List<ChoiceOption> Function() deal, String question, {String? lead}) {
    putOnTable(points);
    final round = _run.round;
    unawaited(() async {
      if (lead != null) {
        await _sayChain([lead], mood: GuideMood.glad);
        if (!mounted || _run.round != round || _ended) return;
      }
      await askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended);
    }());
  }

  /// The next pole (or the result) — by itself, after the reason.
  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() => _setMode(LinemanMode.idle));
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([_L.ask]));
  }

  void _openPlate() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: false));
    setState(() => _plateOpen = true);
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
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _L.coworker(_push, _run.current.spot.site);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    final push = m3InsulatorPickPushFor(_run.current, _run.rejected, preferChip: _run.deal.callChip);
    // Nothing left on this pole for him to push (insulators only leave the
    // tarp): his moment on this pole has passed; the next pole re-arms him.
    if (push == null) return null;
    if (_blocked || tableBusy || _held != null || _plateOpen) return false;
    _push = push;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Took what he pushed: the chipped one, or a pin where the line ends.
      final i = m3InsulatorPickPushed(_run.current, _run.rejected, _push);
      if (i != null) _judgeTake(i, origin);
      return;
    }
    _run.caught.add(_L.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([_L.callHeld, _L.ask], mood: GuideMood.glad);
    }());
  }

  // ---- gesture hints (how to touch, never which one) -------------------------

  /// The level waits for the player's hands now (no intro, card, deck,
  /// praise window, coworker or result).
  bool get _hintWaiting => !_intro && _mark == null && !struckOut && !_blocked && !coworkerOnScreen;

  /// A new waiting state resets the count of hints shown.
  Object get _hintKey => '${_run.round}|${_held?.id}|$_plateOpen|${_run.rejected.length}';

  GlobalKey _itemKey(_Item i) => _itemKeys.putIfAbsent(i.id, GlobalKey.new);

  /// The board up close: tap to look away. An insulator in hand: rub it,
  /// turn it, then a sweep over its two buttons. At the tarp: a sweep over
  /// every insulator still on it (never one of them alone).
  HintSpec? _hint() {
    if (_plateOpen) return HintSpec.tapOn(_plateZoomKey);
    if (_held != null) return _inspectKey.currentState?.hint();
    final r = _run.current;
    final keys = [
      for (final x in r.items)
        if (!_run.rejected.contains(x.id) && _run.fitted?.id != x.id) _itemKey(x),
    ];
    return keys.length < 2 ? null : HintSpec.sweepOver(keys);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? _L.tapWhy[_nudgeN++ % _L.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes ---------------------------------------------------------------------

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() => _card = m);
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m3ins/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _setMode(LinemanMode.idle);
    });
    unawaited(_sayChain([_task]));
  }

  // ---- score and result ---------------------------------------------------------------

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
    _busy = true;
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
    await _say(!_run.passed ? _L.fail : (_quickBonus ? _L.quick : _L.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = M3InsulatorPickGeo(m.height);
    final r = _run.current;
    final aside = [for (final x in r.items) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_plateOpen;
    final fitted = _run.fitted;
    return [
      Positioned.fill(
        key: const ValueKey('field'),
        child: RepaintBoundary(child: CustomPaint(painter: M3InsulatorPickFieldPainter(geo))),
      ),
      // The pole layer covers the field: a tap on it hit nothing (hints).
      Positioned.fill(
        key: ValueKey('pole-${_run.round}-${fitted?.id}'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hints.missTap,
          child: RepaintBoundary(
            child: CustomPaint(painter: M3InsulatorPickPolePainter(geo, site: r.spot.site, fitted: fitted?.kind, discs: fitted?.discs ?? 0)),
          ),
        ),
      ),
      // The danger board's text (tap it to read it close).
      Positioned.fromRect(
        key: ValueKey('plate-${_run.round}'),
        rect: geo.plate.inflate(8),
        child: _PlateTap(spot: r.spot, onTap: _openPlate),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      for (var i = 0; i < r.items.length; i++)
        Positioned.fromRect(
          key: ValueKey('slot-${_run.round}-$i'),
          rect: geo.slot(i, r.items.length),
          child: DoDealIn(
            index: i,
            quiet: quiet,
            muted: true,
            child: _TarpItem(
              key: _itemKey(r.items[i]),
              item: r.items[i],
              gone: _run.rejected.contains(r.items[i].id) || _held?.id == r.items[i].id || fitted?.id == r.items[i].id,
              enabled: canPick,
              onTake: (at) => _pick(r.items[i], at),
            ),
          ),
        ),
      for (var i = 0; i < aside.length && i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: _AsideItem(item: aside[i], seen: _run.spotted.contains(aside[i].id), quiet: quiet),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final held = _held;
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
              labels: _L.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (held != null && playing)
                _Inspect(
                  key: _inspectKey,
                  item: held,
                  spot: _run.current.spot,
                  quiet: quiet,
                  onFound: _found,
                  onTake: _take,
                  onPutBack: _putBack,
                  onMiss: _hints.missTap,
                ),
              if (_plateOpen && playing)
                _PlateZoom(
                  key: const ValueKey('plate-zoom'),
                  cardKey: _plateZoomKey,
                  spot: _run.current.spot,
                  quiet: quiet,
                  onClose: () => setState(() => _plateOpen = false),
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
              if (playing && _card == null && !_plateOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: _L.intro,
                  alarm: 'sounds/intro/impact_metal.ogg',
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _slate = Color(0xFF26303B);

/// The danger board's voltage, small; tap to read it close.
class _PlateTap extends StatelessWidget {
  const _PlateTap({required this.spot, required this.onTap});
  final M3InsulatorPickSpot spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _L.plateLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 21, 11, 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(spot.plate,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFC62828), letterSpacing: 0.2, height: 1)),
          ),
        ),
      ),
    );
  }
}

/// The danger board up close (tap anywhere to look away).
class _PlateZoom extends StatelessWidget {
  const _PlateZoom({super.key, required this.cardKey, required this.spot, required this.quiet, required this.onClose});
  final GlobalKey cardKey;
  final M3InsulatorPickSpot spot;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                key: cardKey,
                width: 260,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F1E8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC62828), width: 4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dangerous_rounded, color: Color(0xFFC62828), size: 30),
                          Text(spot.plate,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFC62828), letterSpacing: 1, height: 1.1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_L.plateBn(spot), style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An insulator standing on the tarp. At this distance its faults do not
/// show. Tap it to take it in hand.
class _TarpItem extends StatelessWidget {
  const _TarpItem({super.key, required this.item, required this.gone, required this.enabled, required this.onTake});
  final _Item item;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  Widget build(BuildContext context) {
    if (gone) return Semantics(label: _L.itemLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: _L.itemLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: enabled ? (d) => onTake(d.globalPosition) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: RotatedBox(
            quarterTurns: 3,
            child: CustomPaint(painter: M3InsulatorPickItemPainter(kind: item.kind, discs: item.discs, seen: const {})),
          ),
        ),
      ),
    );
  }
}

/// An insulator set aside by the trainee's feet, tagged বাদ.
class _AsideItem extends StatelessWidget {
  const _AsideItem({required this.item, required this.seen, required this.quiet});
  final _Item item;
  final bool seen;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, -20 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: 3,
              child: CustomPaint(
                painter: M3InsulatorPickItemPainter(
                  kind: item.kind,
                  discs: item.discs,
                  crack: seen && item.flaw == _Flaw.crack,
                  chip: item.flaw == _Flaw.chip,
                  backSeen: seen,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
              child: Text(_L.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pole's board as a pill, for the close look.
class _SpotPill extends StatelessWidget {
  const _SpotPill({required this.spot});
  final M3InsulatorPickSpot spot;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1E8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC62828), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dangerous_rounded, color: Color(0xFFC62828), size: 16),
            const SizedBox(width: 4),
            Text(spot.plate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFC62828), letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}

/// The close look, hands on: the insulator held up big; run a finger over it
/// (a hairline crack shows only where the hand has been), turn it to see its
/// back (a chipped shed). Then fit it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.item,
    required this.spot,
    required this.quiet,
    required this.onFound,
    required this.onTake,
    required this.onPutBack,
    required this.onMiss,
  });
  final _Item item;
  final M3InsulatorPickSpot spot;
  final bool quiet;
  final VoidCallback onFound;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  /// A tap on the backdrop (nothing to press there).
  final VoidCallback onMiss;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _seen = {};
  var _back = false;
  Offset? _hand;
  var _found = false;
  final _faceKey = GlobalKey();
  final _backKey = GlobalKey();
  final _putKey = GlobalKey();
  final _takeKey = GlobalKey();

  /// The gesture hint in hand, the same for every insulator: rub it (a short
  /// stroke along its face), turn it, then a sweep over both buttons.
  HintSpec? hint() {
    if (_seen.isEmpty) {
      final r = HintSpec.globalRectOf(_faceKey);
      if (r == null) return null;
      return HintSpec.drag(
        Offset(r.left + r.width * 0.1, r.center.dy),
        toward: const Offset(1, 0),
        travel: math.min(HintSpec.maxDragTravel, r.width * 0.5),
      );
    }
    if (!_back) return HintSpec.tapOn(_backKey);
    return HintSpec.sweepOver([_putKey, _takeKey]);
  }

  void _check() {
    final i = widget.item;
    final seen = switch (i.flaw) {
      _Flaw.none => false,
      _Flaw.crack => M3InsulatorPickItemPainter.crackSeen(i.kind, i.discs, _seen),
      _Flaw.chip => _back,
    };
    if (!_found && seen) {
      _found = true;
      widget.onFound();
    }
  }

  void _touch(Offset p, Size s) {
    final b = m3InsulatorPickBin((p.dx / s.width).clamp(0.0, 1.0));
    final before = _seen.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kM3InsulatorPickBins) _seen.add(x);
    }
    final grew = _seen.length != before;
    _check();
    if (grew || _hand != p) setState(() => _hand = p);
  }

  void _turn() {
    if (_back) return;
    HapticFeedback.selectionClick();
    setState(() => _back = true);
    _check();
  }

  Widget _side(_Item item) => LayoutBuilder(
        builder: (context, box) {
          final s = Size(box.maxWidth, box.maxHeight);
          return Semantics(
            label: _L.handLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _touch(d.localPosition, s),
              onPanUpdate: (d) => _touch(d.localPosition, s),
              onPanEnd: (_) => setState(() => _hand = null),
              onPanCancel: () => setState(() => _hand = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: M3InsulatorPickItemPainter(
                        kind: item.kind,
                        discs: item.discs,
                        crack: item.flaw == _Flaw.crack,
                        chip: item.flaw == _Flaw.chip,
                        seen: _seen,
                        backSeen: _back,
                        veil: _slate,
                      ),
                    ),
                  ),
                  if (_seen.isEmpty) _Puck(at: Offset(s.width * 0.1, s.height * 0.5)),
                  if (_hand != null) _Puck(at: _hand!, live: true),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onMiss,
        child: ColoredBox(
          color: const Color(0xC0050A16),
          child: Align(
            alignment: const Alignment(0, -0.42),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.translate(
                offset: Offset(0, 80 * (1 - t)),
                child: Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                decoration: BoxDecoration(
                  color: SlmColors.ivory,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SpotPill(spot: widget.spot),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 2.3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF3A4654), _slate],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                          child: Row(
                            children: [
                              // Turn it round: its back.
                              AspectRatio(
                                aspectRatio: 1,
                                child: Semantics(
                                  key: _backKey,
                                  button: true,
                                  label: _L.backLabel,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (_) => _turn(),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: M3InsulatorPickBackPainter(kind: item.kind, chip: item.flaw == _Flaw.chip, seen: _back),
                                          ),
                                        ),
                                        if (!_back) const Center(child: Icon(Icons.flip_camera_android_rounded, color: Color(0xFFFF851B), size: 26)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: KeyedSubtree(key: _faceKey, child: _side(item))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: KeyedSubtree(key: _putKey, child: DoBigButton(label: _L.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KeyedSubtree(key: _takeKey, child: DoBigButton(label: _L.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A gloved hand's mark: where to slide (still), or under the finger.
class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 20.0 : 15.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}
