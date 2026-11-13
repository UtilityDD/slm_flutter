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
import 'harness_store.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 1.4, কাজ 1: "তিন মিনিটের পরীক্ষা". Four harnesses hang on the
// store's pegboard: a waist belt (work positioning only — never fall arrest),
// one sound full body harness and two damaged ones (often one past its
// expiry date). Hands on: take one down from its hook onto the bench's stand
// (tap or pull it down), then the 3-minute check, close up: slide a finger
// along the webbing (a cut, burn or chemical stain shows only under the
// finger, and the phone buzzes), bend the stitched joint (broken stitches
// open up), turn the D-ring and buckle over, unfold the label and read its
// expiry against the wall calendar. Then পরব or বাতিল.
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// drawn scene (harness_store.dart), corner guide, ◆ on the table → "কেন …?"
// (the reasons fit what this harness had) → the next one by itself; the
// careless coworker once a play, on any full body harness, with the lesson's
// myth ("পুরনো হলেও মজবুতই লাগছে").
//
// Deadly (owner-approved list, 2026-11-08: waist belt for fall arrest;
// damaged harness): wearing the waist belt, or a harness with damaged
// webbing, broken stitching or cracked / rusted metal parts (also by
// listening to him). Slips: wearing a harness whose label has expired but
// shows no damage (lesson 1.4: not to be used); wearing a sound harness
// without all four checks (or because he said so); rejecting a sound
// harness (it stays on the stand, still to judge).
// Three slips strike the level out.
//
// The coworker cannot be skipped by playing fast: পরব / বাতিল on his harness
// waits for him (holdForCoworker). No scene input while a right call is being
// rewarded (tableBusy). Gesture hints (how, never what): a sweep over the
// harnesses on the board, over the tools still to use (then over পরব / বাতিল),
// a short drag nudge in each close look and a tap on its X once it is done.
//
// Voice: the guide's lines by device TTS; the coworker in his recorded voice.
// Art: the store and the harnesses are drawn in code; mistake pictures in
// assets/game/art/harness/.

// ============================================================================
// Content
// ============================================================================

enum HarnessKind { fullBody, waistBelt }

enum HarnessFlaw { none, cut, burn, chemical, stitch, hardware, expired }

extension HarnessFlawFacts on HarnessFlaw {
  bool get onWebbing => this == HarnessFlaw.cut || this == HarnessFlaw.burn || this == HarnessFlaw.chemical;
}

/// Webbing colours a harness comes in (dealt, so plays look different).
const harnessTints = [Color(0xFFE67E22), Color(0xFFD9A21B), Color(0xFF2E6DA4), Color(0xFF3E8E5A)];

@immutable
class HarnessItem {
  const HarnessItem({
    required this.id,
    required this.kind,
    required this.flaw,
    required this.webbingAt,
    required this.made,
    required this.expiry,
    this.tint = 0,
  });
  final String id;
  final HarnessKind kind;
  final HarnessFlaw flaw;

  /// Where along the webbing (0–1) a cut / burn / stain sits.
  final double webbingAt;
  final DateTime made;
  final DateTime expiry;

  /// Index into [harnessTints] (full body harnesses).
  final int tint;
  bool get sound => kind == HarnessKind.fullBody && flaw == HarnessFlaw.none;
  HarnessShape get shape => kind == HarnessKind.waistBelt ? HarnessShape.belt : HarnessShape.fullBody;
  Color get color => kind == HarnessKind.waistBelt ? HarnessPainter.belt : harnessTints[tint % harnessTints.length];
}

@immutable
class HarnessDeal {
  const HarnessDeal({required this.items, required this.today, required this.pushIndex});
  final List<HarnessItem> items;
  final DateTime today;

  /// The harness on which the careless coworker comes ("পুরনো হলেও মজবুত"):
  /// any full body harness, sound or damaged, so his coming does not tell.
  final int pushIndex;
}

enum HarnessCheck { webbing, stitch, hardware, label }

abstract final class HarnessLines {
  static const title = 'তিন মিনিটের পরীক্ষা';
  static const intro = 'পোলে ওঠার ডাক এসেছে! স্টোরে হারনেস ঝুলছে — পরার আগে তিন মিনিটে পরীক্ষা করুন।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];
  static const take = 'একটা হারনেস নামিয়ে আনুন।';
  static const ask = 'এই হারনেস পরে পোলে উঠবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  /// What the guide says as a close look opens (how to use it, not what to find).
  static const lensTask = [
    'আঙুল দিয়ে পুরো ফিতেটা টেনে দেখুন।',
    'সেলাইটা বাঁকিয়ে দেখুন।',
    'ডি-রিং আর বকলস উল্টে দেখুন।',
    'লেবেলটা খুলে পড়ুন।',
  ];

  // Labels a worker reads (tools, the crate, the label, the calendar).
  static const checks = ['ফিতে', 'সেলাই', 'ধাতু', 'লেবেল'];
  static const wear = 'পরব';
  static const reject = 'বাতিল';
  static const crate = 'বাতিল';
  static const stampWear = 'পরুন';
  static const close = 'বন্ধ';
  static const benchLabel = 'হারনেস';
  static String pegLabel(int i) => enDigits('হুক ${i + 1}');
  static String lensLabel(HarnessCheck c) => '${checks[c.index]} · কাছ থেকে';
  static String calendarDay(DateTime d) => enDigits(_two(d.day));
  static String calendarMonth(DateTime d) => _month(d);
  static String made(DateTime d) => 'তৈরি: ${_month(d)}';
  static String expiry(DateTime d) => 'মেয়াদ: ${_month(d)}';
  static const fullBodyName = 'ফুল বডি হারনেস';
  static const beltName = 'ওয়ার্ক পজিশনিং বেল্ট (কোমরের বেল্ট)';

  // The reasons (lesson 1.4 points 1–2 and the myth buster). Every card is
  // 37–43 letters, so none stands out by its length.
  static const whyWear = 'কেন পরলেন?';
  static const whyReject = 'কেন বাতিল করলেন?';
  static const soundWhy = [
    'ফিতে, সেলাই, ধাতু, লেবেল — সবই ঠিক পেয়েছি',
    'নিজে তিন মিনিট দেখে তবেই এতে ভরসা করেছি',
    'ফুল বডি হারনেস, মেয়াদ আছে, কোনো ক্ষতি নেই',
  ];

  /// Wrong reasons to wear it: the lesson's myth and the shortcuts a
  /// careless worker takes to wear a harness without the checks.
  static const myths = [
    'পুরনো হলেও এখনো মজবুতই তো লাগছে, চলবে',
    'মেয়াদ পেরোলেও হারনেসে আসলে কিছু হয় না',
    'বাইরে ঠিক দেখালে ফিতে ভেতরেও ঠিক থাকে',
    'ছোট্ট একটু কাটায় হারনেসের কিছু হয় না',
    'নতুনের মতো ঝকঝকে, তাই দেখার দরকার নেই',
    'গত সপ্তাহেও পরেছি, তাই আজও এটা ঠিক আছে',
  ];

  /// What a rejected harness can have (the deck asks which this one had).
  /// Every card says what was found on THIS harness, so a card shown wrong
  /// means "not what this one had", never "this safety rule is false".
  static const faults = ['belt', 'cut', 'burn', 'chemical', 'stitch', 'hardware', 'expired'];
  static String faultOf(HarnessItem h) => h.kind == HarnessKind.waistBelt ? 'belt' : h.flaw.name;
  static List<String> faultWhy(String f) => switch (f) {
        'belt' => const ['এটা কোমরের বেল্ট, পড়লে চাপ পেট-শিরদাঁড়ায়', 'এটা ওয়ার্ক পজিশনিং বেল্ট, পতন থামায় না'],
        'cut' => const ['এর ফিতেয় কাটা, শক্তি 50% পর্যন্ত কমতে পারে', 'আঙুল টেনে এর ফিতেয় একটা কাটা খুঁজে পেয়েছি'],
        'burn' => const ['এর ফিতেয় পোড়া দাগ, সন্দেহ মানেই বাতিল', 'আঙুল টেনে এর ফিতেয় পোড়া দাগ খুঁজে পেয়েছি'],
        'chemical' => const ['ফিতেয় রাসায়নিকের দাগ, সন্দেহ মানেই বাতিল', 'আঙুল টেনে ফিতেয় রাসায়নিকের ক্ষতি পেয়েছি'],
        'stitch' => const ['বাঁকাতেই এর সেলাই খোলা দেখা গেল, তাই বাতিল', 'এর সেলাই ছিঁড়ে গেছে, এতে হারনেস দুর্বল হয়'],
        'hardware' => const ['এর ডি-রিংয়ে ফাটল আর অতিরিক্ত মরিচা দেখেছি', 'উল্টে দেখি এর ধাতব অংশে ফাটল ধরেছে, বাতিল'],
        _ => const ['এর লেবেলে মেয়াদ পেরিয়ে গেছে, তাই বাতিল', 'লেবেলের মেয়াদ আজকের তারিখের আগেই শেষ হয়েছে'],
      };

  /// The right reasons for what [h] had.
  static List<String> whyRight(HarnessItem h) => h.sound ? soundWhy : faultWhy(faultOf(h));

  /// The wrong cards: worn (sound) → the myths; rejected → what the other
  /// harnesses could have had, but this one did not.
  static List<String> whyWrong(HarnessItem h) => h.sound
      ? myths
      : [
          for (final f in faults)
            if (f != faultOf(h)) ...faultWhy(f),
        ];

  /// The careless coworker (his recorded voice), the lesson's myth.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'হারনেসটা একটু পুরনো, কিন্তু এখনও মজবুতই লাগছে! মেয়াদ গেলে কী হবে? পরে নাও।',
    exitLine: coworkerExit,
    right: ['না, আগে তিন মিনিট পুরো দেখে নিই', 'বাইরে মজবুত দেখালেই ভরসা করব না', 'মেয়াদ আর ফিতে না দেখে পরব না'],
    wrong: ['ঠিক, পুরনো হলেও এখনো মজবুতই আছে', 'ঠিক আছে, দেরি না করে পরে নিই', 'মেয়াদ পেরোলেও হারনেসে কিছু হয় না', 'সবাই তো এমন হারনেসই পরে কাজ করে', 'আচ্ছা, আজ দেখা বাদ দিয়েই পরি'],
    asks: [
      'ও বলছে না দেখেই পরে নিতে। কী করবেন?',
      'পরে নেবেন, না আগে পুরোটা দেখবেন?',
      'কার কথা শুনবেন — ওর, না হারনেসের?',
    ],
  );

  static const callHeld = 'ঠিক! বাইরে মজবুত দেখালেও ফিতে ভেতর থেকে দুর্বল হতে পারে।';
  static const allSet = 'তিন মিনিটের পরীক্ষা পাকা! ফিতে, সেলাই, ধাতব অংশ, লেবেল।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — চারটে দেখা না করে পরবেন না।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtBelt = 'কোমরের বেল্ট দিয়ে পতন-সুরক্ষা নয়';
  static const caughtWebbing = 'আঙুল টেনে ফিতের ক্ষতি ধরেছেন';
  static const caughtExpired = 'মেয়াদ পেরোনো হারনেস বাতিল';
  static const caughtStitch = 'খোলা সেলাই / ভাঙা ধাতু ধরেছেন';
  static const caughtHabit = 'চারটে দেখে তবে পরেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// The name shown on a rejected harness once the reason is paid.
  static String faultBn(HarnessItem h) => switch (faultOf(h)) {
        'belt' => 'কোমরের বেল্ট',
        'cut' => 'ফিতেয় কাটা',
        'burn' => 'ফিতেয় পোড়া দাগ',
        'chemical' => 'রাসায়নিকের দাগ',
        'stitch' => 'খোলা সেলাই',
        'hardware' => 'ফাটা ডি-রিং, মরিচা',
        'expired' => 'মেয়াদ পেরিয়ে গেছে',
        _ => '',
      };

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _month(DateTime d) => enDigits('${_two(d.month)}-${d.year}');
}

abstract final class HarnessMistakes {
  static const waistBelt = DoMistake(
    key: '1.4/harness/waist-belt',
    textBn: 'কোমরের বেল্ট শুধু ওয়ার্ক পজিশনিং-এর জন্য — পড়লে সব চাপ পেটে আর শিরদাঁড়ায়। পতন-সুরক্ষায় ফুল বডি হারনেস চাই।',
    art: 'assets/game/art/harness/belt_vs_harness.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const webbing = DoMistake(
    key: '1.4/harness/webbing',
    textBn: 'ছোট্ট কাটাও ফিতের শক্তি 50% পর্যন্ত কমিয়ে দিতে পারে; পোড়া দাগ বা রাসায়নিকের ক্ষতিতেও ফিতে দুর্বল — এমন হারনেস বাতিল।',
    art: 'assets/game/art/harness/webbing_damage.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const stitch = DoMistake(
    key: '1.4/harness/stitch',
    textBn: 'সেলাই খুলে বা ছিঁড়ে গেছে — হারনেস দুর্বল হয়ে পড়ে। খোলা সেলাই মানে হারনেস বাতিল।',
    art: 'assets/game/art/harness/stitch_hardware.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const hardware = DoMistake(
    key: '1.4/harness/hardware',
    textBn: 'ডি-রিং / বকলসে ফাটল আর মরিচা — এমন হারনেস বাতিল। সন্দেহ মানেই বাতিল।',
    art: 'assets/game/art/harness/stitch_hardware.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const expired = DoMistake(
    key: '1.4/harness/expired',
    textBn: 'লেবেলের মেয়াদ পেরিয়ে গেছে — রোদে ফিতে ভেতর থেকে দুর্বল হয়, বাইরে বোঝা যায় না। মেয়াদ উত্তীর্ণ হারনেস নয়।',
    art: 'assets/game/art/harness/harness_label.svg',
    lessonPoint: 1,
  );
  static const skipped = DoMistake(
    key: '1.4/harness/skipped-check',
    textBn: 'হারনেস ঠিক ছিল — কিন্তু চারটে দেখা না করেই পরলেন। ফিতে, সেলাই, ধাতব অংশ, লেবেল — প্রতিবার।',
    art: 'assets/game/art/harness/three_minute.svg',
    lessonPoint: 1,
  );
  static const goodRejected = DoMistake(
    key: '1.4/harness/good-rejected',
    textBn: 'এই হারনেসটা ঠিক ছিল — ফিতে, সেলাই, ধাতু, মেয়াদ সব ঠিক। দেখে-শুনে সিদ্ধান্ত নিন।',
    art: 'assets/game/art/harness/three_minute.svg',
    lessonPoint: 1,
  );
  static DoMistake forFlaw(HarnessItem h) => h.kind == HarnessKind.waistBelt
      ? waistBelt
      : switch (h.flaw) {
          HarnessFlaw.cut || HarnessFlaw.burn || HarnessFlaw.chemical => webbing,
          HarnessFlaw.stitch => stitch,
          HarnessFlaw.hardware => hardware,
          HarnessFlaw.expired => expired,
          HarnessFlaw.none => skipped,
        };
  static const all = [waistBelt, webbing, stitch, hardware, expired, skipped, goodRejected];
}

/// Four harnesses: the waist belt, one sound harness, two damaged ones (one
/// of them often expired); dates are real dates around [today]. The
/// coworker comes on any of the three full body harnesses.
HarnessDeal dealHarnesses(math.Random rng, DateTime today) {
  DateTime months(int m) => DateTime(today.year, today.month + m, 1);
  var n = 0;
  final tints = [for (var i = 0; i < harnessTints.length; i++) i]..shuffle(rng);
  HarnessItem item(HarnessKind k, HarnessFlaw f) {
    final expired = f == HarnessFlaw.expired;
    final off = expired ? -(1 + rng.nextInt(18)) : 6 + rng.nextInt(30);
    final exp = months(off);
    // Made 2–6 years before the expiry (always before today): the lesson
    // gives no service life, so none is implied by a fixed gap.
    final made = months(math.min(off - (24 + rng.nextInt(49)), -3));
    final i = n++;
    return HarnessItem(
      id: 'h$i',
      kind: k,
      flaw: f,
      webbingAt: 0.2 + rng.nextDouble() * 0.6,
      made: made,
      expiry: exp,
      tint: tints[i % tints.length],
    );
  }

  final flaws = [HarnessFlaw.cut, HarnessFlaw.burn, HarnessFlaw.chemical, HarnessFlaw.stitch, HarnessFlaw.hardware]..shuffle(rng);
  final second = rng.nextInt(3) < 2 ? HarnessFlaw.expired : flaws[1];
  final items = [
    item(HarnessKind.waistBelt, HarnessFlaw.none),
    item(HarnessKind.fullBody, HarnessFlaw.none),
    item(HarnessKind.fullBody, flaws[0]),
    item(HarnessKind.fullBody, second),
  ]..shuffle(rng);
  final full = [
    for (var i = 0; i < items.length; i++)
      if (items[i].kind == HarnessKind.fullBody) i,
  ];
  return HarnessDeal(items: items, today: today, pushIndex: full[rng.nextInt(full.length)]);
}

/// The play state (pure logic).
class HarnessRun {
  HarnessRun(this.deal) : order = [...deal.items];
  final HarnessDeal deal;

  /// The harnesses in the order they are taken down.
  final List<HarnessItem> order;
  int index = 0;
  final Set<HarnessCheck> checks = {};
  bool shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= order.length;
  bool get ended => done || deadly != null;
  HarnessItem get current => order[index.clamp(0, order.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Every check made on this one (earns the +5 on a right call).
  bool get thorough => checks.length == HarnessCheck.values.length;

  /// The harness the coworker comes on (dealt; moves on if he missed it).
  late String pushId = deal.items[deal.pushIndex].id;

  /// The coworker's harness is the one in hand.
  bool get pushOnHand => !done && current.id == pushId;

  /// He was due on a harness judged before he could come: he comes on the
  /// next full body harness still on the board instead. false = none left.
  bool movePush() {
    for (final h in onBoard) {
      if (h.kind == HarnessKind.fullBody) {
        pushId = h.id;
        return true;
      }
    }
    return false;
  }

  /// Still on the board (not yet taken down).
  List<HarnessItem> get onBoard => order.sublist(math.min(index, order.length));

  /// Take [id] down next: any harness still on the board.
  bool take(String id) {
    if (ended || shown) return false;
    final j = order.indexWhere((h) => h.id == id);
    if (j < index) return false;
    final h = order.removeAt(j);
    order.insert(index, h);
    checks.clear();
    return true;
  }

  void check(HarnessCheck c) {
    if (!ended && !shown) checks.add(c);
  }

  /// Wear (true) or reject (false). Returns the mistake, if any. Rejecting
  /// a sound harness is a slip and it stays on the stand, still to judge.
  /// [pushed]: worn because the coworker said so; on a sound harness that is
  /// the wear-without-checking slip, however much was checked.
  DoMistake? decide({required bool wear, bool pushed = false}) {
    if (ended || shown) return null;
    shown = true;
    final h = current;
    void tag(String t) {
      if (!caught.contains(t)) caught.add(t);
    }

    if (wear) {
      // An expired label with no visible damage is a slip (owner, 2026-11-08);
      // the harness goes off to the crate after the card.
      if (h.flaw == HarnessFlaw.expired) {
        slips++;
        return HarnessMistakes.expired;
      }
      if (!h.sound) return deadly = HarnessMistakes.forFlaw(h);
      if (pushed || !checks.containsAll(HarnessCheck.values)) {
        slips++;
        return HarnessMistakes.skipped;
      }
      tag(HarnessLines.caughtHabit);
      return null;
    }
    if (h.sound) {
      // Still on the stand: judge it again (so slips can add up to three).
      slips++;
      shown = false;
      return HarnessMistakes.goodRejected;
    }
    if (h.kind == HarnessKind.waistBelt) {
      tag(HarnessLines.caughtBelt);
    } else if (h.flaw.onWebbing) {
      tag(HarnessLines.caughtWebbing);
    } else if (h.flaw == HarnessFlaw.expired) {
      tag(HarnessLines.caughtExpired);
    } else {
      tag(HarnessLines.caughtStitch);
    }
    return null;
  }

  void next() {
    if (ended) return;
    index++;
    checks.clear();
    shown = false;
  }
}

@immutable
class HarnessPack {
  const HarnessPack({required this.id, required this.titleBn, this.quickMs = 120000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const harnessPack14 = HarnessPack(id: 'do_1_4_a', titleBn: HarnessLines.title);
const harnessPacks = {'do_1_4_a': harnessPack14};

// ============================================================================
// Page
// ============================================================================

class HarnessCheckPage extends StatefulWidget {
  const HarnessCheckPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.today});

  final LevelContext ctx;
  final HarnessPack pack;
  final bool muted;
  final int? seed;

  /// Tests: a fixed "today" for the label dates.
  final DateTime? today;

  @override
  State<HarnessCheckPage> createState() => _HarnessCheckPageState();
}

class _HarnessCheckPageState extends State<HarnessCheckPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) {
    final now = widget.today ?? DateTime.now();
    return _HarnessRunPage(
      key: ValueKey(_round),
      ctx: widget.ctx,
      pack: widget.pack,
      muted: _muted,
      today: DateTime(now.year, now.month, now.day),
      rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
      onRetry: (m) => setState(() {
        _muted = m;
        _round++;
      }),
    );
  }
}

class _HarnessRunPage extends ConsumerStatefulWidget {
  const _HarnessRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.today, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final HarnessPack pack;
  final bool muted;
  final DateTime today;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HarnessRunPage> createState() => _HarnessRunPageState();
}

class _HarnessRunPageState extends ConsumerState<_HarnessRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final HarnessRun _run = HarnessRun(dealHarnesses(widget.rng, widget.today));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

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

  /// The harness in hand is on the bench's stand (taken down from its hook).
  var _taken = false;

  /// Its hook, for the flight down.
  int _fromPeg = 0;

  /// The close look open now.
  HarnessCheck? _lens;

  /// The call made on it: worn (true) / rejected (false); null = not yet.
  bool? _wore;
  var _stamped = false;

  /// After a paid reject reason: the fault is named on it.
  var _named = false;

  /// It goes: into the crate (rejected) or off the stand (worn).
  var _leaving = false;
  int _wake = 0;

  /// A deadly call: the store freezes grey while the fall plays in colour.
  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints: where the things to touch are on screen.
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _pegKeys = {};
  final _toolKeys = [for (var i = 0; i < HarnessCheck.values.length; i++) GlobalKey()];
  final _rejectKey = GlobalKey();
  final _wearKey = GlobalKey();
  final _lensKey = GlobalKey();
  final _lensCloseKey = GlobalKey();

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
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

  /// After the guide's intro: the clock runs; take one down.
  Future<void> _start() async {
    _clock.start();
    unawaited(_sayChain([HarnessLines.take]));
  }

  bool get _canPlay =>
      !_intro && !_busy && !_ended && !tableBusy && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && _lens == null && !_leaving;

  // --- choose: take one down from its hook ---------------------------------------
  void _take(HarnessItem h, int peg) {
    if (!_canPlay || _taken) return;
    if (!_run.take(h.id)) return;
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.5, muted: false));
    setState(() {
      _taken = true;
      _fromPeg = peg;
      _wake++;
    });
    // The coworker comes once, on his harness, a moment after a first check
    // (or at once if the call comes first: _decide waits for him).
    if (!coworkerDone && _run.pushOnHand) scheduleCoworker();
    unawaited(_sayChain([HarnessLines.ask]));
  }

  // --- inspect: the four close looks --------------------------------------------
  void _openLens(HarnessCheck c) {
    if (!_canPlay || !_taken) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.4, muted: false));
    setState(() {
      _lens = c;
      _wake++;
    });
    unawaited(_sayChain([HarnessLines.lensTask[c.index]]));
  }

  void _checked(HarnessCheck c) {
    if (_run.checks.contains(c)) return;
    _run.check(c);
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.4, muted: false));
    setState(() {});
  }

  void _closeLens() {
    if (_lens == null) return;
    _hush();
    setState(() => _lens = null);
  }

  void _tapItem(Offset local, Size size) {
    if (!_canPlay || !_taken) return;
    final z = HarnessPainter.zoneAt(_run.current.shape, local, size);
    if (z == null) {
      _hints.missTap();
      return;
    }
    _openLens(HarnessCheck.values[z]);
  }

  // --- the decision ---------------------------------------------------------------
  Future<void> _decide(bool wear, Offset origin, {bool pushed = false}) async {
    if (!_canPlay || !_taken) return;
    // On his harness the call waits for him (he cannot be skipped).
    if (holdForCoworker()) return;
    _hush();
    final m = _run.decide(wear: wear, pushed: pushed);
    HapticFeedback.mediumImpact();
    setState(() {
      _wore = wear;
      _wake++;
    });
    if (m == null) {
      // Right: the stamp, the ◆ wait on the table, then "কেন …?".
      if (!_muted) {
        unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.7, muted: false));
        unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      }
      setState(() => _stamped = true);
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final h = _run.current;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(HarnessLines.whyRight(h), HarnessLines.whyWrong(h), widget.rng),
        question: wear ? HarnessLines.whyWear : HarnessLines.whyReject,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  /// It goes into the crate or off the stand; then the next (or the result).
  void _sendOff() {
    if (!mounted || _ended) return;
    if (!_muted) unawaited(ZlFx.cue(_wore == false ? 'sounds/intro/drop.ogg' : 'sounds/learn/rush_out.wav', volume: 0.5, muted: false));
    setState(() => _leaving = true);
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 60 : 560), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  void _next() {
    _run.next();
    // Safety net: his harness was judged without him (the call waits for him,
    // so this should not happen) → he comes on the next full body one.
    if (!coworkerDone && !coworkerOpen && !_run.onBoard.any((x) => x.id == _run.pushId)) _run.movePush();
    if (_run.done) {
      setState(() => _leaving = false);
      unawaited(_finish());
      return;
    }
    setState(() {
      _taken = false;
      _wore = null;
      _stamped = false;
      _named = false;
      _leaving = false;
      _lens = null;
      _wake++;
    });
    unawaited(_sayChain([HarnessLines.take]));
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
    if (_wore != false) {
      _sendOff();
      return;
    }
    // A reject paid: now its fault is named on it, then into the crate.
    final idx = _run.index;
    setState(() => _named = true);
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 700 : 1500), () {
      if (mounted && !_ended && _run.index == idx) _sendOff();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => HarnessLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || !_run.pushOnHand || _run.shown) return null;
    // Never into the praise window of a right move.
    if (tableBusy) return false;
    if (_intro || _busy || !_taken || _card != null || reasonOpen || _lens != null || _leaving || _run.checks.isEmpty) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: he wears it on his say-so (deadly on a damaged
      // harness, the wear-without-checking slip on a sound one).
      await _decide(true, origin, pushed: true);
      return;
    }
    _run.caught.add(HarnessLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([HarnessLines.callHeld, HarnessLines.ask], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? HarnessLines.tapWhy[_nudgeN++ % HarnessLines.tapWhy.length]
            : _nudge.next(_taken ? HarnessLines.ask : HarnessLines.take);
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
    final speak = await SpokenOnce.first('harness/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly call: the store freezes grey and the fall plays in colour;
  /// then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _lens = null;
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
    final speak = await SpokenOnce.first('harness/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? HarnessLines.deadlyWord : HarnessLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        if (_run.shown) {
          _sendOff();
        } else {
          // A sound harness rejected: it is still on the stand to judge.
          setState(() => _wore = null);
          unawaited(_sayChain([HarnessLines.ask]));
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
    await _say(!_run.passed ? HarnessLines.fail : (_quickBonus ? HarnessLines.quick : HarnessLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (_lens != null) {
      _closeLens();
      return;
    }
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

  // --- gesture hints (how to touch, never the answer) -------------------------
  HintSpec? _hint() {
    final lens = _lens;
    if (lens != null) {
      // Done here: put it down (the X). Else a short nudge of the gesture.
      if (_run.checks.contains(lens)) return HintSpec.tapOn(_lensCloseKey);
      final r = HintSpec.globalRectOf(_lensKey);
      if (r == null) return null;
      final y = r.top + r.height * 0.42;
      return switch (lens) {
        // Short, from the far left: it ends before the 0.2 band where damage
        // can sit, so the hand never glides over a hidden cut.
        // The strip starts 5 (card border) + 14 (painter side) in; the band
        // begins 0.2 of its length further. Stop 14 dp short of it at any width.
        HarnessCheck.webbing => HintSpec.drag(Offset(r.left + 24, y),
            toward: const Offset(1, 0), travel: math.max(8.0, 19 + 0.2 * (r.width - 38) - 14 - 24)),
        HarnessCheck.stitch => HintSpec.drag(Offset(r.center.dx, y - 20), toward: const Offset(0, 1)),
        HarnessCheck.hardware => HintSpec.drag(Offset(r.center.dx - 40, y), toward: const Offset(1, 0), travel: 80),
        HarnessCheck.label => HintSpec.drag(Offset(r.left + 107, r.top + 112), toward: const Offset(0, -1)),
      };
    }
    if (!_taken) {
      final keys = [for (final x in _run.onBoard) ?_pegKeys[x.id]];
      if (keys.isEmpty) return null;
      return keys.length == 1 ? HintSpec.tapOn(keys.single) : HintSpec.sweepOver(keys);
    }
    final open = [
      for (final c in HarnessCheck.values)
        if (!_run.checks.contains(c)) _toolKeys[c.index],
    ];
    return HintSpec.sweepOver(open.isNotEmpty ? open : [_rejectKey, _wearKey]);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_stamped && _wore == true) return LinemanMode.cheer;
    if (_taken) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  /// The slot (hook) each harness hangs on: its place in the deal.
  int _pegOf(HarnessItem h) => _run.deal.items.indexWhere((x) => x.id == h.id);

  List<Widget> _scene(SceneMetrics m) {
    final geo = HarnessGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final h = _run.current;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final board = [
      for (final x in _run.onBoard)
        if (!(_taken && x.id == h.id)) x,
    ];
    final item = geo.item;
    // Where it goes: into the crate, or up off the stand (worn).
    final out = _wore == false
        ? Rect.fromCenter(center: geo.crate.center.translate(0, -6), width: geo.crate.width * 0.7, height: geo.crate.width * 0.7 / HarnessPainter.aspect * 0.5)
        : item.translate(-60, -item.height * 0.4).deflate(item.width * 0.2);
    final from = geo.pegItem(_fromPeg);
    // The stamp sits in the gap between the reason deck (its top ≈ 236 dp up)
    // and the guide's bubble over it (≈ 236 + 116 + 5 dp up), on the
    // harness's lower half: the guide stands to its right, so nothing hides it.
    final k = 360 / math.max(1.0, MediaQuery.sizeOf(context).width);
    final stampTop = (geo.bottom - 351 * k).clamp(item.top + item.height * 0.3, math.max(item.top + item.height * 0.3, item.bottom - 48)).toDouble();
    final world = <Widget>[
      Positioned.fill(
        key: const ValueKey('store'),
        // A tap on the bare store hits nothing: it counts toward the hint.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_canPlay) _hints.missTap();
          },
          child: RepaintBoundary(child: CustomPaint(painter: HarnessStorePainter(geo: geo))),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('calendar'),
        rect: geo.calendar,
        child: _Calendar(today: widget.today),
      ),
      // The harnesses still on their hooks: tap one, or pull it down.
      for (final x in board)
        Positioned.fromRect(
          key: ValueKey('peg-${x.id}'),
          rect: geo.pegItem(_pegOf(x)),
          child: KeyedSubtree(
            key: _pegKeys.putIfAbsent(x.id, GlobalKey.new),
            child: Semantics(
              button: true,
              label: HarnessLines.pegLabel(_pegOf(x)),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _take(x, _pegOf(x)),
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 0) _take(x, _pegOf(x));
                },
                child: CustomPaint(painter: HarnessPainter(shape: x.shape, color: x.color)),
              ),
            ),
          ),
        ),
      // The trainee, behind the bench.
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: IgnorePointer(child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
      ),
      Positioned.fill(
        key: const ValueKey('bench'),
        child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: HarnessBenchPainter(geo: geo)))),
      ),
      Positioned(
        key: const ValueKey('crate-word'),
        left: geo.crate.left,
        width: geo.crate.width,
        top: geo.crate.top + 8,
        child: IgnorePointer(
          child: Text(HarnessLines.crate,
              textAlign: TextAlign.center, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFFFF3E8))),
        ),
      ),
      // The harness in hand: down from its hook onto the stand, then away.
      if (_taken && !_run.done)
        TweenAnimationBuilder<double>(
          key: ValueKey('item-${h.id}-${_leaving ? 'out' : 'in'}'),
          tween: Tween(begin: quiet ? 1 : 0, end: 1),
          duration: Duration(milliseconds: _leaving ? 520 : 480),
          builder: (_, t, child) {
            final k = _leaving ? Curves.easeInCubic.transform(t) : Curves.easeOutBack.transform(t);
            final r = _leaving ? Rect.lerp(item, out, k)! : Rect.lerp(from, item, k)!;
            // Worn: it fades as it goes up off the stand.
            return Positioned.fromRect(rect: r, child: Opacity(opacity: _leaving && _wore != false ? (1 - t).clamp(0.0, 1.0) : 1.0, child: child));
          },
          child: RepaintBoundary(
            child: Semantics(
              label: HarnessLines.benchLabel,
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tapItem(d.localPosition, box.biggest),
                  child: CustomPaint(painter: HarnessPainter(shape: h.shape, color: h.color), size: box.biggest),
                ),
              ),
            ),
          ),
        ),
      // The stamp, and the fault's name above it once paid.
      if (_stamped && !_leaving && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: item.center.dx - 90,
          width: 180,
          top: stampTop,
          child: IgnorePointer(child: _StampPop(text: _wore == true ? HarnessLines.stampWear : HarnessLines.reject, good: _wore == true, quiet: quiet)),
        ),
      if (_named && !_leaving)
        Positioned(
          key: ValueKey('named-${_run.index}'),
          left: item.center.dx - 110,
          width: 220,
          top: stampTop - 46,
          child: IgnorePointer(child: _NameChip(text: HarnessLines.faultBn(h), quiet: quiet)),
        ),
    ];
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(colorFilter: grey, child: Stack(children: world)),
      ),
    ];
  }

  /// The deadly call, in colour over the grey store and above the freeze's
  /// red tint: drawn in the scene's design pixels, mapped as the frame maps
  /// the scene (360 wide, BoxFit.cover).
  Widget _fall(Size size, EdgeInsets pad) {
    final w = math.max(1.0, size.width);
    final dh = (360 * size.height / w).clamp(560.0, 900.0);
    final item = HarnessGeo.forScene(dh, pad.bottom * 360 / w).item;
    final h = _run.current;
    return Positioned.fill(
      key: const ValueKey('fall'),
      child: IgnorePointer(
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 360,
              height: dh,
              child: HarnessFall(
                centre: Offset(180, item.center.dy),
                radius: math.min(150.0, item.height * 0.5 + 20),
                belt: h.kind == HarnessKind.waistBelt,
                quiet: _quiet,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && _taken && !_busy && !tableBusy && !_run.shown && !deckUp && !coworkerOpen && _card == null && _lens == null && !_leaving;
    // The hand shows only while the level waits for a touch on the scene
    // (the decks and the proceed card bring their own hints).
    final boardWait = playing && !_taken && _canPlay;
    final lensWait = playing && _lens != null && _card == null && !coworkerOpen && !_busy;
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
              labels: HarnessLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: boardWait || handsOn || lensWait,
            hintKey: '${_run.index}|$_taken|${_lens?.name}|${_run.checks.length}|${_card?.key}|$coworkerDone',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 6,
                  bottom: pad.bottom + 72,
                  child: Row(
                    children: [
                      for (final c in HarnessCheck.values)
                        KeyedSubtree(
                          key: _toolKeys[c.index],
                          child: _ToolButton(
                            icon: _toolIcons[c.index],
                            label: HarnessLines.checks[c.index],
                            done: _run.checks.contains(c),
                            onTap: () => _openLens(c),
                          ),
                        ),
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
                      Expanded(
                        child: KeyedSubtree(
                          key: _rejectKey,
                          child: DoBigButton(label: HarnessLines.reject, filled: false, onDark: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: KeyedSubtree(
                          key: _wearKey,
                          child: DoBigButton(label: HarnessLines.wear, filled: true, onTapUp: (d) => unawaited(_decide(true, d.globalPosition))),
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
              if (_lens != null && playing)
                _Lens(
                  key: ValueKey('lens-${_lens!.name}'),
                  check: _lens!,
                  item: _run.current,
                  today: widget.today,
                  quiet: quiet,
                  muted: _muted,
                  cardKey: _lensKey,
                  closeKey: _lensCloseKey,
                  onChecked: _checked,
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
              if (_freeze && _card == null) _fall(size, pad),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: HarnessLines.intro,
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

  static const _toolIcons = [Icons.swipe_rounded, Icons.texture_rounded, Icons.link_rounded, Icons.label_rounded];
}

// ============================================================================
// Pieces
// ============================================================================

/// A hands-on tool: a round icon with its name under it (a tick once done).
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.done, required this.onTap});
  final IconData icon;
  final String label;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                      border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.6),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Icon(icon, size: 24, color: SlmColors.gold300),
                  ),
                  if (done)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E8B45)),
                        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                ],
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

/// The wall calendar: today's day, month and year.
class _Calendar extends StatelessWidget {
  const _Calendar({required this.today});
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: Column(
        children: [
          Container(
            height: 16,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFC63A2E), borderRadius: BorderRadius.vertical(top: Radius.circular(3))),
            child: FittedBox(child: Text(HarnessLines.calendarMonth(today), style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          Expanded(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(HarnessLines.calendarDay(today), style: bangla(fontSize: 30, fontWeight: FontWeight.w900, color: const Color(0xFF22262B))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.good, required this.quiet});
  final String text;
  final bool good;
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
      child: Center(child: DoStamp(text: text, good: good)),
    );
  }
}

/// What a rejected harness had, named once the reason is paid.
class _NameChip extends StatelessWidget {
  const _NameChip({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(opacity: t.clamp(0.0, 1.0), child: Transform.scale(scale: 0.8 + 0.2 * t, child: child)),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6)]),
          child: Text(text, maxLines: 1, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ),
    );
  }
}

/// A close look over the dimmed store: the harness part, big, to work with
/// the fingers. Tap outside (or the X) to put it down.
class _Lens extends StatelessWidget {
  const _Lens({
    super.key,
    required this.check,
    required this.item,
    required this.today,
    required this.quiet,
    required this.muted,
    required this.cardKey,
    required this.closeKey,
    required this.onChecked,
    required this.onClose,
  });
  final HarnessCheck check;
  final HarnessItem item;
  final DateTime today;
  final bool quiet;
  final bool muted;

  /// Where the card and its X are (the gesture hint).
  final GlobalKey cardKey;
  final GlobalKey closeKey;
  final ValueChanged<HarnessCheck> onChecked;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = math.min(340.0, size.width - 28);
    const h = 300.0;
    final top = size.height * 0.42 - h / 2;
    final left = (size.width - w) / 2;
    void done() => onChecked(check);
    final Widget body = switch (check) {
      HarnessCheck.webbing => _WebbingLook(item: item, muted: muted, onDone: done),
      HarnessCheck.stitch => _StitchLook(item: item, onDone: done),
      HarnessCheck.hardware => _HardwareLook(item: item, onDone: done),
      HarnessCheck.label => _LabelLook(item: item, today: today, onDone: done),
    };
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
                top: top,
                width: w,
                height: h,
                child: Semantics(
                  key: cardKey,
                  label: HarnessLines.lensLabel(check),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: quiet ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      builder: (_, t, child) => Transform.scale(scale: 0.8 + 0.2 * t, child: child),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E1D0),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: SlmColors.gold300, width: 5),
                          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 20)],
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(19), child: body),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left + w - 38,
                top: top - 10,
                child: Semantics(
                  key: closeKey,
                  button: true,
                  label: HarnessLines.close,
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

/// The gesture to try (a faint glyph until the first touch).
class _Try extends StatelessWidget {
  const _Try({super.key, required this.icon, required this.show});
  final IconData icon;
  final bool show;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.82),
          child: AnimatedOpacity(
            opacity: show ? 0.55 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, size: 40, color: const Color(0xFF3A3F47)),
          ),
        ),
      );
}

/// Run a finger along the webbing: a cut, burn or stain shows only under the
/// finger (and the phone buzzes there); once felt it stays marked.
class _WebbingLook extends StatefulWidget {
  const _WebbingLook({required this.item, required this.muted, required this.onDone});
  final HarnessItem item;
  final bool muted;
  final VoidCallback onDone;

  @override
  State<_WebbingLook> createState() => _WebbingLookState();
}

class _WebbingLookState extends State<_WebbingLook> {
  double? _finger;
  double _lo = 1;
  double _hi = 0;
  var _found = false;
  var _covered = false;

  void _slide(double u) {
    final v = u.clamp(0.0, 1.0);
    // A fast finger jumps between touch points: the fault is felt if it lies
    // anywhere between the last point and this one.
    final from = _finger ?? v;
    setState(() {
      _finger = v;
      _lo = math.min(_lo, v);
      _hi = math.max(_hi, v);
    });
    final h = widget.item;
    final passed = h.webbingAt >= math.min(from, v) - 0.045 && h.webbingAt <= math.max(from, v) + 0.045;
    if (!_found && h.flaw.onWebbing && passed) {
      HapticFeedback.heavyImpact();
      if (!widget.muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.5, muted: false));
      setState(() => _found = true);
    } else if ((v * 20).floor() != (from * 20).floor()) {
      HapticFeedback.selectionClick();
    }
    if (!_covered && _hi - _lo > 0.85) {
      _covered = true;
      widget.onDone();
    }
  }

  void _lift() {
    if (_finger == null) return;
    setState(() => _finger = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) => _slide((d.localPosition.dx - 14) / (c.maxWidth - 28)),
        onPanUpdate: (d) => _slide((d.localPosition.dx - 14) / (c.maxWidth - 28)),
        onPanEnd: (_) => _lift(),
        onPanCancel: _lift,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _WebbingPainter(item: widget.item, finger: _finger, found: _found, lo: _lo, hi: _hi))),
            _Try(icon: Icons.swipe_rounded, show: _hi < _lo),
          ],
        ),
      ),
    );
  }
}

/// A long run of webbing pulled through the fingers.
class _WebbingPainter extends CustomPainter {
  _WebbingPainter({required this.item, required this.finger, required this.found, required this.lo, required this.hi});
  final HarnessItem item;
  final double? finger;
  final bool found;
  final double lo;
  final double hi;

  @override
  void paint(Canvas c, Size s) {
    const side = 14.0;
    final len = s.width - 2 * side;
    final h = 58.0;
    final top = s.height * 0.42 - h / 2;
    final strip = Rect.fromLTWH(0, top, s.width, h);
    final col = item.color;
    c.drawRect(strip.shift(const Offset(0, 4)), Paint()..color = const Color(0x33000000));
    c.drawRect(strip, Paint()..color = col);
    final weave = Paint()
      ..color = const Color(0x2A000000)
      ..strokeWidth = 1;
    for (var y = top + 4; y < top + h; y += 4) {
      c.drawLine(Offset(0, y), Offset(s.width, y), weave);
    }
    final edge = Paint()..color = Color.lerp(col, Colors.black, 0.3)!;
    c.drawRect(Rect.fromLTWH(0, top, s.width, 3), edge);
    c.drawRect(Rect.fromLTWH(0, top + h - 3, s.width, 3), edge);
    // Where the finger has been: a faint line under the strap.
    if (hi > lo) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(side + lo * len, top + h + 10, side + hi * len, top + h + 15), const Radius.circular(3)),
        Paint()..color = const Color(0xAA2E8B45),
      );
    }
    final f = finger;
    final fx = f == null ? null : side + f * len;
    // The damage: only where the finger is (or once felt).
    if (item.flaw.onWebbing) {
      final x = side + item.webbingAt * len;
      final near = fx != null && (fx - x).abs() < 34;
      if (found || near) {
        c.save();
        if (!found && fx != null) c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(fx, top + h / 2), radius: 34)));
        _damage(c, x, top, h);
        c.restore();
      }
      if (found) {
        c.drawCircle(
          Offset(x, top + h / 2),
          h * 0.75,
          Paint()
            ..color = SlmColors.danger
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
    if (fx != null) {
      // The fingertip pressing on the strap's lower edge (the face stays in view).
      final o = Offset(fx, top + h + 6);
      c.drawOval(Rect.fromCenter(center: o + const Offset(2, 4), width: 30, height: 36), Paint()..color = const Color(0x33000000));
      c.drawOval(Rect.fromCenter(center: o, width: 28, height: 34), Paint()..color = const Color(0xF0C98E66));
      c.drawOval(Rect.fromCenter(center: o.translate(0, -7), width: 18, height: 12), Paint()..color = const Color(0x66FFE6D2));
    }
  }

  void _damage(Canvas c, double x, double top, double h) {
    switch (item.flaw) {
      case HarnessFlaw.cut:
        c.drawPath(
          Path()
            ..moveTo(x - 7, top)
            ..lineTo(x, top + h * 0.5)
            ..lineTo(x + 7, top)
            ..close(),
          Paint()..color = const Color(0xFFE9E1D0),
        );
        final fray = Paint()
          ..color = Color.lerp(item.color, Colors.black, 0.4)!
          ..strokeWidth = 1.2;
        for (final (a, b) in const [(-1.0, -8.0), (1.5, 8.0), (-0.5, -5.0), (0.8, 6.0)]) {
          c.drawLine(Offset(x + a, top + h * 0.45), Offset(x + b, top + h * 0.66), fray);
        }
      case HarnessFlaw.burn:
        c.drawOval(Rect.fromCenter(center: Offset(x, top + h / 2), width: 26, height: 18), Paint()..color = const Color(0xFF4A2C12));
        c.drawOval(Rect.fromCenter(center: Offset(x, top + h / 2), width: 12, height: 8), Paint()..color = const Color(0xFF1F130A));
        c.drawOval(
          Rect.fromCenter(center: Offset(x, top + h / 2), width: 32, height: 24),
          Paint()
            ..color = const Color(0x664A2C12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      default:
        c.drawOval(Rect.fromCenter(center: Offset(x, top + h / 2), width: 44, height: h * 0.85), Paint()..color = const Color(0xAAC9D24A));
        c.drawOval(Rect.fromCenter(center: Offset(x + 6, top + h / 2 + 4), width: 18, height: 12), Paint()..color = const Color(0x8890A030));
    }
  }

  @override
  bool shouldRepaint(_WebbingPainter old) => old.finger != finger || old.found != found || old.lo != lo || old.hi != hi || old.item != item;
}

/// Bend the stitched joint: push down (or up) on it and it bends; broken
/// stitches open up as it bends.
class _StitchLook extends StatefulWidget {
  const _StitchLook({required this.item, required this.onDone});
  final HarnessItem item;
  final VoidCallback onDone;

  @override
  State<_StitchLook> createState() => _StitchLookState();
}

class _StitchLookState extends State<_StitchLook> {
  double _bend = 0;
  double _pull = 0;
  var _touched = false;
  var _done = false;

  void _move(double dy) {
    _pull += dy;
    final b = (_pull.abs() / 110).clamp(0.0, 1.0);
    setState(() {
      _bend = b;
      _touched = true;
    });
    if ((b * 6).floor() != ((b - dy.abs() / 110) * 6).floor()) HapticFeedback.selectionClick();
    if (!_done && b >= 0.8) {
      _done = true;
      widget.onDone();
    }
  }

  void _release() => setState(() {
        _pull = 0;
        _bend = 0;
      });

  @override
  Widget build(BuildContext context) {
    final h = widget.item;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => _move(d.delta.dy),
      onVerticalDragEnd: (_) => _release(),
      onVerticalDragCancel: _release,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StitchPainter(broken: h.flaw == HarnessFlaw.stitch, color: h.color, bend: _bend))),
          _Try(icon: Icons.swipe_vertical_rounded, show: !_touched),
        ],
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  _StitchPainter({required this.broken, required this.color, required this.bend});
  final bool broken;
  final Color color;
  final double bend;

  @override
  void paint(Canvas c, Size s) {
    // Two straps sewn over each other, bending about the middle.
    final cx = s.width / 2;
    final cy = s.height * 0.42;
    final half = s.width * 0.42;
    final sag = 46 * bend;
    Offset at(double u, double off) {
      // u in -1..1 along the strap, off across it.
      final y = cy + sag * (1 - u * u) - sag * 0.5;
      final slope = -2 * sag * u / half;
      final n = Offset(-slope, 1) / math.sqrt(1 + slope * slope);
      return Offset(cx + u * half, y) + n * off;
    }

    Path band(double w) {
      final p = Path();
      for (var i = 0; i <= 24; i++) {
        final q = at(-1 + i / 12, -w / 2);
        i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
      }
      for (var i = 24; i >= 0; i--) {
        final q = at(-1 + i / 12, w / 2);
        p.lineTo(q.dx, q.dy);
      }
      return p..close();
    }

    c.drawPath(band(70).shift(const Offset(0, 5)), Paint()..color = const Color(0x33000000));
    c.drawPath(band(70), Paint()..color = Color.lerp(color, Colors.black, 0.2)!);
    c.drawPath(band(56), Paint()..color = color);
    // The box-and-cross stitches: four boxes along the joint.
    final thread = Paint()
      ..color = const Color(0xFF2B2015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < 4; b++) {
      final u0 = -0.7 + b * 0.36;
      final u1 = u0 + 0.28;
      final gone = broken && (b == 1 || b == 2);
      final corners = [at(u0, -20), at(u1, -20), at(u1, 20), at(u0, 20)];
      if (!gone) {
        c.drawPath(Path()..addPolygon(corners, true), thread);
        c.drawLine(corners[0], corners[2], thread);
        c.drawLine(corners[1], corners[3], thread);
        continue;
      }
      // Broken: flat it looks almost whole; bent, the threads part and hang.
      final open = bend;
      if (open < 0.25) {
        c.drawPath(Path()..addPolygon(corners, true), thread..strokeWidth = 1.6);
        c.drawLine(corners[0], corners[2], thread);
        thread.strokeWidth = 2.2;
        continue;
      }
      final gap = Paint()..color = Color.lerp(color, Colors.black, 0.55)!;
      c.drawPath(
        Path()
          ..moveTo(at(u0 + 0.04, -4 * open).dx, at(u0 + 0.04, -4 * open).dy)
          ..lineTo(at(u1 - 0.04, -4 * open).dx, at(u1 - 0.04, -4 * open).dy)
          ..lineTo(at(u1 - 0.04, 4 * open).dx, at(u1 - 0.04, 4 * open).dy)
          ..lineTo(at(u0 + 0.04, 4 * open).dx, at(u0 + 0.04, 4 * open).dy)
          ..close(),
        gap,
      );
      for (final (u, side) in [(u0, -1.0), (u1, 1.0), (u0 + 0.1, 1.0), (u1 - 0.1, -1.0)]) {
        final a = at(u, 20 * side);
        final loose = a + Offset(6 * side, 14 + 18 * open);
        c.drawPath(Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(a.dx + 10 * side, a.dy + 6, loose.dx, loose.dy), thread);
      }
    }
  }

  @override
  bool shouldRepaint(_StitchPainter old) => old.bend != bend || old.broken != broken || old.color != color;
}

/// Turn the D-ring and the buckle over (drag sideways) to see both faces.
class _HardwareLook extends StatefulWidget {
  const _HardwareLook({required this.item, required this.onDone});
  final HarnessItem item;
  final VoidCallback onDone;

  @override
  State<_HardwareLook> createState() => _HardwareLookState();
}

class _HardwareLookState extends State<_HardwareLook> {
  double _turn = 0;
  var _touched = false;
  var _done = false;

  void _move(double dx) {
    final t = (_turn + dx.abs() / 200).clamp(0.0, 1.0);
    if ((t * 4).floor() != (_turn * 4).floor()) HapticFeedback.selectionClick();
    setState(() {
      _turn = t;
      _touched = true;
    });
    if (!_done && t >= 0.9) {
      _done = true;
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.item;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => _move(d.delta.dx),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HardwarePainter(broken: h.flaw == HarnessFlaw.hardware, belt: h.kind == HarnessKind.waistBelt, turn: _turn, color: h.color)),
          ),
          _Try(icon: Icons.swipe_rounded, show: !_touched),
        ],
      ),
    );
  }
}

class _HardwarePainter extends CustomPainter {
  _HardwarePainter({required this.broken, required this.belt, required this.turn, required this.color});
  final bool broken;
  final bool belt;
  final double turn;
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final back = turn >= 0.5;
    final sx = math.max(0.06, math.cos(math.pi * turn).abs());
    final cy = s.height * 0.42;
    final steel = broken ? const [Color(0xFFB5ADA2), Color(0xFF6E6559)] : const [Color(0xFFE2E6EA), Color(0xFF7D868E)];
    // The D-ring (left) and the buckle (right), turning together, each on
    // its strap.
    for (final (cx, ring) in [(s.width * 0.3, true), (s.width * 0.72, false)]) {
      c.save();
      c.translate(cx, cy);
      c.scale(sx, 1);
      final strap = Paint()..color = color;
      final shade = Paint()..color = const Color(0x33000000);
      if (ring) {
        c.drawRect(const Rect.fromLTWH(-56, 40, 112, 26), strap);
        c.drawRect(const Rect.fromLTWH(-56, 40, 112, 4), shade);
      } else {
        c.drawRect(const Rect.fromLTWH(-80, -13, 160, 26), strap);
        c.drawRect(const Rect.fromLTWH(-80, -13, 160, 4), shade);
      }
      final paint = Paint()
        ..shader = LinearGradient(colors: back ? steel.reversed.toList() : steel).createShader(const Rect.fromLTWH(-50, -60, 100, 120))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11;
      if (ring) {
        c.drawPath(
          Path()
            ..moveTo(-38, 50)
            ..lineTo(-38, -10)
            ..quadraticBezierTo(-38, -58, 0, -58)
            ..quadraticBezierTo(38, -58, 38, -10)
            ..lineTo(38, 50)
            ..close(),
          paint,
        );
      } else {
        final w = belt ? 92.0 : 76.0;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: 58), const Radius.circular(8)), paint..strokeWidth = 9);
        c.drawLine(const Offset(0, -24), const Offset(0, 24), paint..strokeWidth = 7);
      }
      if (broken) {
        // Rust spots on both faces; the crack on the back.
        final rust = Paint()..color = const Color(0xFFA0522D);
        for (final o in ring ? const [Offset(-38, 18), Offset(38, 30), Offset(-30, -40)] : const [Offset(-34, -10), Offset(30, 20), Offset(10, -26)]) {
          c.drawCircle(o, 6, rust);
          c.drawCircle(o + const Offset(4, 3), 3.5, Paint()..color = const Color(0xFF7A3A1C));
        }
        if (back && ring) {
          c.drawPath(
            Path()
              ..moveTo(18, -56)
              ..lineTo(26, -44)
              ..lineTo(21, -34)
              ..lineTo(32, -26),
            Paint()
              ..color = const Color(0xFF1B140C)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_HardwarePainter old) => old.turn != turn || old.broken != broken || old.belt != belt || old.color != color;
}

/// The label tag, folded over: push it up to unfold it and read the dates;
/// the wall calendar beside it says today.
class _LabelLook extends StatefulWidget {
  const _LabelLook({required this.item, required this.today, required this.onDone});
  final HarnessItem item;
  final DateTime today;
  final VoidCallback onDone;

  @override
  State<_LabelLook> createState() => _LabelLookState();
}

class _LabelLookState extends State<_LabelLook> {
  double _open = 0;
  var _done = false;

  void _move(double dy) {
    final o = (_open - dy / 120).clamp(0.0, 1.0);
    setState(() => _open = o);
    if (!_done && o >= 0.8) {
      _done = true;
      HapticFeedback.selectionClick();
      widget.onDone();
    }
  }

  void _settle() {
    if (_open >= 0.5) setState(() => _open = 1);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.item;
    final belt = h.kind == HarnessKind.waistBelt;
    final ink = bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.ink);
    final face = Container(
      width: 178,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF31363C), width: 1.6)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(belt ? HarnessLines.beltName : HarnessLines.fullBodyName, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ink)),
          const SizedBox(height: 8),
          Text(HarnessLines.made(h.made), style: ink),
          Text(HarnessLines.expiry(h.expiry), style: ink.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => _move(d.delta.dy),
      onVerticalDragEnd: (_) => _settle(),
      child: Stack(
        children: [
          // The strap the tag is sewn to.
          Positioned(key: const ValueKey('label-strap'), left: 0, right: 0, top: 62, height: 40, child: ColoredBox(color: h.color)),
          Positioned(
            key: const ValueKey('label-face'),
            left: 18,
            top: 82,
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateX((1 - _open) * math.pi * 0.5),
              child: Opacity(opacity: (_open * 1.6).clamp(0.0, 1.0), child: face),
            ),
          ),
          // The folded tag (its blank back), until it is pushed up.
          if (_open < 0.95)
            Positioned(
              key: const ValueKey('label-fold'),
              left: 18,
              top: 82,
              child: Container(
                width: 178,
                height: 52 * (1 - _open) + 4,
                decoration: BoxDecoration(color: const Color(0xFFF4F1EA), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF9AA0A8))),
              ),
            ),
          // Today, on the wall calendar.
          Positioned(key: const ValueKey('label-calendar'), right: 18, top: 86, width: 86, height: 104, child: _Calendar(today: widget.today)),
          _Try(key: const ValueKey('label-try'), icon: Icons.swipe_up_rounded, show: _open == 0),
        ],
      ),
    );
  }
}
