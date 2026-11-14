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
import 'm4_insulator_swap_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_insulator_swap_world.dart' show M4InsulatorSwapKind, M4InsulatorSwapDamage;

// Lesson 4.1 "পিন বা ডিস্ক ইনসুলেটর বদলানো", কাজ 2 "পোলের ওপর বদল"
// (pack do_4_1_b, engineType m4_insulator_swap). Three poles a play, each a
// damaged insulator to change: a pin insulator on a line pole, or a disc in
// a strain string on a tension pole (at least one of each). The shutdown,
// the PTW and the earthing on both sides are done (কাজ 1, m4_insulator_prep):
// the earth set is on the conductors, the trainee is up the pole in helmet
// and harness. He finds the faulty insulator and changes it with the
// lesson's steps, in the lesson's order.
//
// The lesson's rules, and only those:
//   • point 1 (pin): free the conductor from the old binding · hold it on a
//     rope support so it cannot drop or swing to the next phase · the old
//     insulator off the pin with a spanner · the new one on the pin, tight ·
//     the conductor in the head's groove, bound tight with new binding wire
//     (pro tip 3: the binding must sit firm; film S5_04: never loose);
//   • point 2 (disc): bypass the load first (come-along clamp + turnbuckle:
//     the load off the string onto the tool) — opening it without the bypass
//     is "a deadly mistake" · slacken the string · the split pin out, the
//     damaged disc out · the new disc in (cap and pin matched), its pin
//     secured · the tension back on the string slowly, the tools off;
//   • myths: the conductor is not held by hand (support it); a strain string
//     is never opened by muscle;
//   • engineering facts / film S4_03: check for electrical puncture and for
//     mechanical cracks — on the old one and on the new one;
//   • pro tip 2 / film S5_02: change an old, rusted pin with the insulator.
// The lesson's pin steps free the conductor, then rope it; roping it first is
// not a slip (it is not less safe): the slip is the spanner on an insulator
// whose conductor is still bound, or free and unsupported.
//
// Hands on (tools under the scene, shuffled each pole and never laid out in
// the order of use; tap the faulty phase with a tool):
//   pin  — প্লায়ার্স · দড়ি · স্প্যানার · নতুন ইনসুলেটর (a tray of three to
//          inspect: one cracked, one punctured, one sound) · বাইন্ডিং তার;
//   disc — কাম-অ্যালং · টার্ন-বাকেল (take the load up / give it back) ·
//          প্লায়ার্স · নতুন ডিস্ক (the tray) · স্প্লিট-পিন.
//
// Deadly: pliers on a strain string still under load (no bypass taken up).
// Slips: a tool on a sound insulator, the spanner on a bound or unsupported
// conductor, a damaged spare picked, the new insulator on a rusted pin, the
// load given back with a gap or without the split pin, listening to the
// coworker ("বাঁধন একটু ঢিলে থাকুক, চলবে"). Three slips strike the level out.
// A wrong flag (a tool on a sound insulator) costs a slip and the card stays
// neutral (it never names which one is faulty).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_insulator_swap_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next pole by itself; the careless coworker once a play on a
// pin pole, as the binding begins (the binding tap waits for him:
// holdForCoworker, so a fast play still meets him; he never comes once it is
// bound). Nothing takes a touch in the praise window (tableBusy). Gesture
// hints: a sweep over the tools, the tray's spares or the three phases —
// never the answer. Voice: the guide by device TTS; the coworker's push by
// device TTS until recorded (his exit is a recorded clip).

// ============================================================================
// Content
// ============================================================================

/// What the reason question asks about.
enum M4InsulatorSwapWhy { support, bind, check, rust, bypass, release }

/// The hands-on tools.
enum M4InsulatorSwapTool { none, pliers, rope, spanner, spare, bindWire, comeAlong, turnbuckle, splitPin }

@immutable
class M4InsulatorSwapPole {
  const M4InsulatorSwapPole({
    required this.id,
    required this.kind,
    required this.bad,
    required this.damage,
    required this.why,
    required this.spares,
    this.rusty = false,
    this.discBad = 1,
  });
  final String id;
  final M4InsulatorSwapKind kind;

  /// The faulty phase (0–2) and its damage.
  final int bad;
  final M4InsulatorSwapDamage damage;
  final M4InsulatorSwapWhy why;

  /// The tray of three spares: null = sound.
  final List<M4InsulatorSwapDamage?> spares;

  /// Pin pole: the pin under the old insulator is rusted.
  final bool rusty;

  /// Tension pole: the faulty disc in the string.
  final int discBad;
}

abstract final class M4InsulatorSwapLines {
  static const title = 'পোলের ওপর বদল';
  static const intro = 'লাইনে ভাঙা ইনসুলেটর! শাটডাউন, আর্থিং হয়ে গেছে — এবার পোলে উঠে নিয়ম মেনে বদলান।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askFind = 'কোন ইনসুলেটরটা নষ্ট? সেটাই বদলাতে হবে।';
  static const askFree = 'পুরনো ইনসুলেটরটা নিরাপদে খুলুন।';
  static const askNew = 'নতুনটা দেখে-শুনে বসান।';
  static const askBind = 'এবার তারটা খাঁজে বসিয়ে বাঁধুন।';
  static const askOpen = 'টেনশন স্ট্রিংটা নিরাপদে খুলুন।';
  static const askBack = 'এবার টান স্ট্রিংয়ে ফিরিয়ে দিন।';
  static const tasks = [askFind, askFree, askNew, askBind, askOpen, askBack];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const bindAgain = 'না — নিয়ম মেনে শক্ত করে বাঁধুন।';

  // Labels a worker reads (tools, the docket).
  static const sceneLabel = 'পোলের মাথা';
  static const pliers = 'প্লায়ার্স';
  static const rope = 'দড়ি';
  static const spanner = 'স্প্যানার';
  static const spareIns = 'নতুন ইনসুলেটর';
  static const spareDisc = 'নতুন ডিস্ক';
  static const bindWire = 'বাইন্ডিং তার';
  static const comeAlong = 'কাম-অ্যালং';
  static const turnbuckle = 'টার্ন-বাকেল';
  static const splitPin = 'স্প্লিট-পিন';
  static const spare = 'নতুন';
  static const docket = 'ডকেট';
  static const docketDone = 'শাটডাউন · পারমিট (PTW) · দুই দিকে আর্থিং';
  static String jobBn(M4InsulatorSwapKind k) => switch (k) {
        M4InsulatorSwapKind.pin => 'পিন ইনসুলেটর বদল',
        M4InsulatorSwapKind.disc => 'টেনশন স্ট্রিংয়ে ডিস্ক বদল',
      };
  static const stampDone = 'বদল সম্পূর্ণ';

  // The reasons (lesson 4.1): the right ones fit this pole and what was
  // done; the wrong ones are the lesson's myths and field excuses — never a
  // true rule marked wrong.
  static const whySupportQ = 'কেন খোলার আগে তারটা দড়িতে ধরলেন?';
  static const whyBindQ = 'কেন নতুন তারে শক্ত করে বাঁধলেন?';
  static const whyCheckQ = 'কেন লাগানোর আগে নতুনটা দেখে নিলেন?';
  static const whyRustQ = 'কেন পিনটাও বদলে দিলেন?';
  static const whyBypassQ = 'কেন আগে কাম-অ্যালংয়ে লোড নিলেন?';
  static const whyReleaseQ = 'কেন পিন আটকে তবে টান ফেরালেন?';
  static const supportWhy = ['দড়ির সাপোর্টে তার নিচে বা পাশের ফেজে যায় না', 'তার ছুটে গেলে পাশের ফেজে লেগে বিপদ হতে পারে'];
  static const bindWhy = ['খাঁজে বসিয়ে নিয়মে বাঁধলে তার দৃঢ় বসে থাকে', 'ঢিলে বাঁধনে তার খাঁজ থেকে সরে যেতে পারে'];
  static const checkWhy = ['নতুনেও ফাটল বা পাংচার থাকতে পারে, তাই দেখা', 'ফাটা বা পাংচার ইনসুলেটর লাগালে আবার ফল্ট'];
  static const rustWhy = ['পুরনো, মরিচা ধরা পিনও সঙ্গে বদলানো নিয়ম', 'মরিচা ধরা পিনে নতুন ইনসুলেটর ভরসার নয়'];
  static const bypassWhy = ['টেনশন স্ট্রিং প্রচণ্ড টানে থাকে, আগে লোড টুলে', 'লোড বাইপাস না করে স্ট্রিং খোলা মারাত্মক ভুল'];
  static const releaseWhy = ['পিন আটকানো না থাকলে টানে স্ট্রিং খুলে যেতে পারে', 'ডিস্ক বসিয়ে পিন আটকে, তবেই ধীরে ধীরে টান'];
  static const myths = [
    'লাইন তো বন্ধ, তারটা হাতে ধরে রাখলেই চলে',
    'গায়ের জোরে টানলেই টেনশন স্ট্রিং খুলে যায়',
    'বাঁধন একটু ঢিলে থাকলে কোনো ক্ষতি হয় না',
    'নতুন ইনসুলেটর কখনো খারাপ হয় না, দেখার কী',
    'পুরনো পিনে একটু মরিচা থাকলেও কিছু হয় না',
    'তাড়াতাড়ি সারলে লাইন তাড়াতাড়ি চালু হবে',
    'পুরনো বাইন্ডিং তারটাই আবার জড়ালে চলে',
    'অভিজ্ঞ লোকের হাতে নিয়মের অত দরকার নেই',
  ];
  static const allRight = [...supportWhy, ...bindWhy, ...checkWhy, ...rustWhy, ...bypassWhy, ...releaseWhy];

  static List<String> whyRight(M4InsulatorSwapWhy w) => switch (w) {
        M4InsulatorSwapWhy.support => supportWhy,
        M4InsulatorSwapWhy.bind => bindWhy,
        M4InsulatorSwapWhy.check => checkWhy,
        M4InsulatorSwapWhy.rust => rustWhy,
        M4InsulatorSwapWhy.bypass => bypassWhy,
        M4InsulatorSwapWhy.release => releaseWhy,
      };
  static String whyQuestion(M4InsulatorSwapWhy w) => switch (w) {
        M4InsulatorSwapWhy.support => whySupportQ,
        M4InsulatorSwapWhy.bind => whyBindQ,
        M4InsulatorSwapWhy.check => whyCheckQ,
        M4InsulatorSwapWhy.rust => whyRustQ,
        M4InsulatorSwapWhy.bypass => whyBypassQ,
        M4InsulatorSwapWhy.release => whyReleaseQ,
      };

  /// The careless coworker: leave the binding loose.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'বাঁধন একটু ঢিলে থাকুক, চলবে! অত শক্ত করে বাঁধার সময় কোথায়?',
    exitLine: coworkerExit,
    right: ['না, খাঁজে বসিয়ে নিয়ম মেনে শক্ত করে বাঁধব', 'না, ঢিলে বাঁধনে তার খাঁজ থেকে সরে যাবে', 'না, বাঁধন ঢিলে রেখে পোল থেকে নামব না'],
    wrong: [
      'ঠিক, একটু ঢিলে থাকলে কিছুই হবে না',
      'আচ্ছা, দু-পাক জড়িয়েই নেমে পড়ি তাহলে',
      'হ্যাঁ, অত শক্ত করে বাঁধার দরকার নেই',
      'ঠিক আছে, পরে কেউ এসে টাইট দিয়ে দেবে',
      'হ্যাঁ, তাড়া আছে, আলগা রেখেই নামি',
    ],
    asks: ['ও বলছে বাঁধন ঢিলে রাখতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'ঢিলে বাঁধনেই কাজ শেষ করবেন?'],
  );

  static const callHeld = 'ঠিক! বাঁধন শক্ত, তার খাঁজে দৃঢ়।';
  static const allSet = 'তিনটে পোলেই নিখুঁত বদল — নিয়ম মেনে, ধাপে ধাপে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে তার বা লোড সামলান, তারপর বদল।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtFind = 'নষ্ট ইনসুলেটর চিনেছেন';
  static const caughtSupport = 'খোলার আগে তার দড়িতে ধরেছেন';
  static const caughtCheck = 'নতুনটাও দেখে নিয়েছেন';
  static const caughtRust = 'মরিচা ধরা পিনও বদলেছেন';
  static const caughtBind = 'খাঁজে বসিয়ে শক্ত করে বেঁধেছেন';
  static const caughtBypass = 'আগে লোড বাইপাস করেছেন';
  static const caughtRelease = 'পিন আটকে ধীরে টান ফিরিয়েছেন';
  static const caughtCall = 'ঢিলে বাঁধনে “না” বলেছেন';
}

abstract final class M4InsulatorSwapMistakes {
  static const _dir = 'assets/game/art/m4_insulator_swap';

  static const wrongOne = DoMistake(
    key: '4.1/m4_insulator_swap/sound-one',
    textBn: 'আগে নষ্টটা চিনে নিন! তিনটে ইনসুলেটরই ভালো করে দেখুন — যেটায় ফাটল বা পাংচারের পোড়া দাগ, শুধু সেটাই বদলান।',
    art: '$_dir/find_bad.svg',
  );
  static const unbindFirst = DoMistake(
    key: '4.1/m4_insulator_swap/still-bound',
    textBn: 'তার এখনও বাঁধা! আগে পুরনো বাইন্ডিং তার খুলে কন্ডাক্টর মুক্ত করুন, তারপর ইনসুলেটর খুলুন।',
    art: '$_dir/unbind_first.svg',
    lessonPoint: 1,
  );
  static const noRope = DoMistake(
    key: '4.1/m4_insulator_swap/no-support',
    textBn: 'মুক্ত তার সাপোর্ট ছাড়া! দড়িতে ধরে রাখুন, নইলে নিচে পড়বে বা পাশের ফেজে লাগবে।',
    art: '$_dir/rope_support.svg',
    lessonPoint: 1,
  );
  static const badSpare = DoMistake(
    key: '4.1/m4_insulator_swap/bad-spare',
    textBn: 'নতুনটাও খারাপ — ফাটল বা পাংচারের দাগ! লাগানোর আগে দুটোই দেখে নিন, ভালোটা বসান।',
    art: '$_dir/check_spare.svg',
  );
  static const rustyPin = DoMistake(
    key: '4.1/m4_insulator_swap/rusty-pin',
    textBn: 'পিনে মরিচা! ইনসুলেটর বদলের সময় পুরনো, মরিচা ধরা পিন বা নাট-বল্টুও বদলে দিন।',
    art: '$_dir/rusty_pin.svg',
  );
  static const looseBind = DoMistake(
    key: '4.1/m4_insulator_swap/loose-binding',
    textBn: 'বাঁধন ঢিলে রাখা চলবে না! খাঁজে তার বসিয়ে নতুন বাইন্ডিং তারে নিয়ম মেনে শক্ত করে বাঁধুন।',
    art: '$_dir/tight_bind.svg',
    lessonPoint: 1,
  );
  static const noBypass = DoMistake(
    key: '4.1/m4_insulator_swap/no-bypass',
    textBn: 'টানের মধ্যে স্ট্রিং খোলা মারাত্মক ভুল! আগে কাম-অ্যালং আর টার্ন-বাকেলে লোড বাইপাস করে টুলের ওপর নিন।',
    art: '$_dir/no_bypass.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const releaseGap = DoMistake(
    key: '4.1/m4_insulator_swap/release-gap',
    textBn: 'স্ট্রিংয়ে ফাঁক রেখে টান ফেরানো নয়! আগে নতুন ডিস্ক বসিয়ে পিন আটকান, তারপর ধীরে ধীরে টান।',
    art: '$_dir/pin_first.svg',
    lessonPoint: 2,
  );
  static const noSplitPin = DoMistake(
    key: '4.1/m4_insulator_swap/no-split-pin',
    textBn: 'নতুন ডিস্কের পিন আটকানো হয়নি! স্প্লিট-পিন সুরক্ষিত করে তবেই টান ফেরান।',
    art: '$_dir/pin_first.svg',
    lessonPoint: 2,
  );

  static List<DoMistake> get all => [wrongOne, unbindFirst, noRope, badSpare, rustyPin, looseBind, noBypass, releaseGap, noSplitPin];
}

@immutable
class M4InsulatorSwapDeal {
  const M4InsulatorSwapDeal({required this.poles, required this.callAt, this.toolOrders});
  final List<M4InsulatorSwapPole> poles;

  /// The pin pole the careless coworker comes to.
  final int callAt;

  /// The tool row of each pole, shuffled (null = the plain set, for tests).
  final List<List<M4InsulatorSwapTool>>? toolOrders;

  /// The tool row under the scene on pole [i] (clamped to the last pole, so
  /// the frames after the last pole while the level finishes never throw).
  List<M4InsulatorSwapTool> toolsAt(int i) {
    final j = i.clamp(0, poles.length - 1);
    final o = toolOrders;
    return o != null && j < o.length ? o[j] : m4InsulatorSwapTools(poles[j].kind);
  }
}

/// The orders of use a tool row must never show (the pin's first two steps
/// go either way round).
List<List<M4InsulatorSwapTool>> m4InsulatorSwapUseOrders(M4InsulatorSwapKind k) => k == M4InsulatorSwapKind.pin
    ? const [
        [M4InsulatorSwapTool.pliers, M4InsulatorSwapTool.rope, M4InsulatorSwapTool.spanner, M4InsulatorSwapTool.spare, M4InsulatorSwapTool.bindWire],
        [M4InsulatorSwapTool.rope, M4InsulatorSwapTool.pliers, M4InsulatorSwapTool.spanner, M4InsulatorSwapTool.spare, M4InsulatorSwapTool.bindWire],
      ]
    : const [
        [M4InsulatorSwapTool.comeAlong, M4InsulatorSwapTool.turnbuckle, M4InsulatorSwapTool.pliers, M4InsulatorSwapTool.spare, M4InsulatorSwapTool.splitPin],
      ];

bool _sameOrder(List<M4InsulatorSwapTool> a, List<M4InsulatorSwapTool> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A tool row for [k] in a random order that is never an order of use.
List<M4InsulatorSwapTool> m4InsulatorSwapShuffledTools(M4InsulatorSwapKind k, math.Random rng) {
  final use = m4InsulatorSwapUseOrders(k);
  final row = [...m4InsulatorSwapTools(k)];
  do {
    row.shuffle(rng);
  } while (use.any((u) => _sameOrder(u, row)));
  return List.unmodifiable(row);
}

/// Three poles: pin and tension both in every play; the faulty phase, its
/// damage, a rusted pin, the faulty disc and the tray vary; each pole asks a
/// different reason that fits the work done there.
M4InsulatorSwapDeal m4InsulatorSwapDeal(math.Random rng) {
  final kinds = (rng.nextBool()
      ? [M4InsulatorSwapKind.pin, M4InsulatorSwapKind.pin, M4InsulatorSwapKind.disc]
      : [M4InsulatorSwapKind.pin, M4InsulatorSwapKind.disc, M4InsulatorSwapKind.disc])
    ..shuffle(rng);
  final used = <M4InsulatorSwapWhy>{};
  final poles = <M4InsulatorSwapPole>[];
  for (final (i, k) in kinds.indexed) {
    final rusty = k == M4InsulatorSwapKind.pin && rng.nextBool();
    final options = [
      if (k == M4InsulatorSwapKind.pin) ...[M4InsulatorSwapWhy.support, M4InsulatorSwapWhy.bind, if (rusty) M4InsulatorSwapWhy.rust],
      if (k == M4InsulatorSwapKind.disc) ...[M4InsulatorSwapWhy.bypass, M4InsulatorSwapWhy.release],
      M4InsulatorSwapWhy.check,
    ].where((w) => !used.contains(w)).toList();
    final why = options[rng.nextInt(options.length)];
    used.add(why);
    poles.add(M4InsulatorSwapPole(
      id: 'p$i',
      kind: k,
      bad: rng.nextInt(3),
      damage: M4InsulatorSwapDamage.values[rng.nextInt(2)],
      why: why,
      spares: <M4InsulatorSwapDamage?>[null, M4InsulatorSwapDamage.crack, M4InsulatorSwapDamage.puncture]..shuffle(rng),
      rusty: rusty,
      discBad: rng.nextInt(3),
    ));
  }
  final pins = [
    for (final (i, p) in poles.indexed)
      if (p.kind == M4InsulatorSwapKind.pin) i,
  ];
  final callAt = pins[rng.nextInt(pins.length)];
  // Drawn last so the poles of a seed stay as they were.
  final toolOrders = [for (final p in poles) m4InsulatorSwapShuffledTools(p.kind, rng)];
  return M4InsulatorSwapDeal(poles: poles, callAt: callAt, toolOrders: toolOrders);
}

/// The tools for [k] (the set; the row under the scene is shuffled per pole:
/// [M4InsulatorSwapDeal.toolsAt]).
List<M4InsulatorSwapTool> m4InsulatorSwapTools(M4InsulatorSwapKind k) => k == M4InsulatorSwapKind.pin
    ? const [M4InsulatorSwapTool.pliers, M4InsulatorSwapTool.rope, M4InsulatorSwapTool.spanner, M4InsulatorSwapTool.spare, M4InsulatorSwapTool.bindWire]
    : const [M4InsulatorSwapTool.comeAlong, M4InsulatorSwapTool.turnbuckle, M4InsulatorSwapTool.pliers, M4InsulatorSwapTool.spare, M4InsulatorSwapTool.splitPin];

/// The play state (pure logic).
class M4InsulatorSwapRun {
  M4InsulatorSwapRun(this.deal);
  final M4InsulatorSwapDeal deal;
  int index = 0;
  int slips = 0;
  int poleSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this pole ---
  M4InsulatorSwapTool tool = M4InsulatorSwapTool.none;
  var started = false;
  var trayOpen = false;
  var spareHeld = false;
  final Set<int> setAside = {};
  var fixed = false;

  // Pin pole.
  var bound = true;
  var roped = false;
  var oldOff = false;
  var pinNew = false;
  var newOn = false;
  var newBound = false;

  // Tension pole.
  var rigOn = false;
  var takenUp = false;
  var discOut = false;
  var newDisc = false;
  var pinned = false;
  var released = false;

  bool get done => index >= deal.poles.length;
  bool get ended => done || deadly != null;
  M4InsulatorSwapPole get pole => deal.poles[index.clamp(0, deal.poles.length - 1)];
  bool get isPin => pole.kind == M4InsulatorSwapKind.pin;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Done this pole without a slip (+5 on the table).
  bool get thorough => poleSlips == 0;

  bool get _open => !ended && !fixed;

  /// The insulator (or disc) is off: the new one can go on.
  bool get gapOpen => isPin ? oldOff && !newOn : discOut && !newDisc;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    poleSlips++;
    return m;
  }

  /// Picks up [t] (or puts it down). The spare opens the tray to inspect.
  void hold(M4InsulatorSwapTool t) {
    if (!_open) return;
    if (t == M4InsulatorSwapTool.spare) {
      if (spareHeld) {
        tool = tool == t ? M4InsulatorSwapTool.none : t;
        return;
      }
      trayOpen = !trayOpen;
      tool = M4InsulatorSwapTool.none;
      return;
    }
    trayOpen = false;
    tool = tool == t ? M4InsulatorSwapTool.none : t;
  }

  /// Picks spare [j] off the tray: a damaged one is a slip (it is set aside).
  DoMistake? pickSpare(int j) {
    if (!_open || !trayOpen || setAside.contains(j)) return null;
    if (pole.spares[j] != null) {
      setAside.add(j);
      return _slip(M4InsulatorSwapMistakes.badSpare);
    }
    spareHeld = true;
    trayOpen = false;
    tool = M4InsulatorSwapTool.spare;
    return null;
  }

  /// Taps phase [i] with the tool in hand. Returns the mistake, if any.
  DoMistake? tapPhase(int i) {
    if (!_open || tool == M4InsulatorSwapTool.none) return null;
    if (i != pole.bad) {
      if (started) return null;
      return _slip(M4InsulatorSwapMistakes.wrongOne);
    }
    return isPin ? _pinTap() : _discTap();
  }

  void _begin() {
    if (!started) _tag(M4InsulatorSwapLines.caughtFind);
    started = true;
  }

  DoMistake? _pinTap() {
    switch (tool) {
      case M4InsulatorSwapTool.pliers:
        if (!bound || oldOff) return null;
        _begin();
        bound = false;
        tool = M4InsulatorSwapTool.none;
      case M4InsulatorSwapTool.rope:
        if (roped || newBound) return null;
        _begin();
        roped = true;
        tool = M4InsulatorSwapTool.none;
      case M4InsulatorSwapTool.spanner:
        if (!oldOff) {
          if (bound) return _slip(M4InsulatorSwapMistakes.unbindFirst);
          if (!roped) return _slip(M4InsulatorSwapMistakes.noRope);
          _begin();
          oldOff = true;
          _tag(M4InsulatorSwapLines.caughtSupport);
          if (!pole.rusty) tool = M4InsulatorSwapTool.none;
        } else if (pole.rusty && !pinNew && !newOn) {
          pinNew = true;
          tool = M4InsulatorSwapTool.none;
          _tag(M4InsulatorSwapLines.caughtRust);
        }
      case M4InsulatorSwapTool.spare:
        if (!spareHeld || !gapOpen) return null;
        if (pole.rusty && !pinNew) return _slip(M4InsulatorSwapMistakes.rustyPin);
        newOn = true;
        spareHeld = false;
        tool = M4InsulatorSwapTool.none;
        _tag(M4InsulatorSwapLines.caughtCheck);
      case M4InsulatorSwapTool.bindWire:
        if (!newOn || newBound) return null;
        newBound = true;
        roped = false;
        fixed = true;
        tool = M4InsulatorSwapTool.none;
        _tag(M4InsulatorSwapLines.caughtBind);
      default:
        return null;
    }
    return null;
  }

  DoMistake? _discTap() {
    switch (tool) {
      case M4InsulatorSwapTool.comeAlong:
        if (rigOn) return null;
        _begin();
        rigOn = true;
        tool = M4InsulatorSwapTool.none;
      case M4InsulatorSwapTool.turnbuckle:
        if (!rigOn) return null;
        if (!takenUp) {
          takenUp = true;
          tool = M4InsulatorSwapTool.none;
          return null;
        }
        if (!newDisc) return _slip(M4InsulatorSwapMistakes.releaseGap);
        if (!pinned) return _slip(M4InsulatorSwapMistakes.noSplitPin);
        released = true;
        fixed = true;
        tool = M4InsulatorSwapTool.none;
        _tag(M4InsulatorSwapLines.caughtRelease);
      case M4InsulatorSwapTool.pliers:
        if (discOut) return null;
        _begin();
        if (!rigOn || !takenUp) return deadly = M4InsulatorSwapMistakes.noBypass;
        discOut = true;
        tool = M4InsulatorSwapTool.none;
        _tag(M4InsulatorSwapLines.caughtBypass);
      case M4InsulatorSwapTool.spare:
        if (!spareHeld || !gapOpen) return null;
        newDisc = true;
        spareHeld = false;
        tool = M4InsulatorSwapTool.none;
        _tag(M4InsulatorSwapLines.caughtCheck);
      case M4InsulatorSwapTool.splitPin:
        if (!newDisc || pinned) return null;
        pinned = true;
        tool = M4InsulatorSwapTool.none;
      default:
        return null;
    }
    return null;
  }

  /// Listened to the coworker: a slip, and the binding is still to do right.
  DoMistake listened() => _slip(M4InsulatorSwapMistakes.looseBind);

  /// Fails the play.
  void failDeadly(DoMistake m) => deadly = m;

  /// The view for the painter.
  M4InsulatorSwapView get view => M4InsulatorSwapView(
        kind: pole.kind,
        bad: pole.bad,
        damage: pole.damage,
        discBad: pole.discBad,
        bound: bound,
        roped: roped,
        oldOff: oldOff,
        rusty: pole.rusty,
        pinNew: pinNew,
        newOn: newOn,
        newBound: newBound,
        rigOn: rigOn,
        takenUp: takenUp,
        discOut: discOut,
        newDisc: newDisc,
        pinned: pinned,
        released: released,
      );

  void next() {
    index++;
    poleSlips = 0;
    tool = M4InsulatorSwapTool.none;
    started = false;
    trayOpen = false;
    spareHeld = false;
    setAside.clear();
    fixed = false;
    bound = true;
    roped = false;
    oldOff = false;
    pinNew = false;
    newOn = false;
    newBound = false;
    rigOn = false;
    takenUp = false;
    discOut = false;
    newDisc = false;
    pinned = false;
    released = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   pin pole: 5 tools × 2 taps + the tray ~3000 + (rusty: 1 tap) ≈ 16000,
///     the stamp ~1500, reason ~8200                               ≈ 25700
///   tension pole: 6 tool steps × 2 taps + the tray ~3000 ≈ 21000,
///     the stamp, reason                                           ≈ 30700
/// three poles ≈ 82000 + the coworker once ≈ 9600                   ≈ 91600
/// 85 % ≈ 78000 → 80 s.
const m4InsulatorSwapQuickMs = 80000;

@immutable
class M4InsulatorSwapPack {
  const M4InsulatorSwapPack({required this.id, required this.titleBn, this.quickMs = m4InsulatorSwapQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4InsulatorSwapPack> m4InsulatorSwapPacks = {
  'do_4_1_b': M4InsulatorSwapPack(id: 'do_4_1_b', titleBn: M4InsulatorSwapLines.title),
};

String _toolLabel(M4InsulatorSwapTool t, M4InsulatorSwapKind k) => switch (t) {
      M4InsulatorSwapTool.pliers => M4InsulatorSwapLines.pliers,
      M4InsulatorSwapTool.rope => M4InsulatorSwapLines.rope,
      M4InsulatorSwapTool.spanner => M4InsulatorSwapLines.spanner,
      M4InsulatorSwapTool.spare => k == M4InsulatorSwapKind.pin ? M4InsulatorSwapLines.spareIns : M4InsulatorSwapLines.spareDisc,
      M4InsulatorSwapTool.bindWire => M4InsulatorSwapLines.bindWire,
      M4InsulatorSwapTool.comeAlong => M4InsulatorSwapLines.comeAlong,
      M4InsulatorSwapTool.turnbuckle => M4InsulatorSwapLines.turnbuckle,
      M4InsulatorSwapTool.splitPin => M4InsulatorSwapLines.splitPin,
      M4InsulatorSwapTool.none => '',
    };

IconData _toolIcon(M4InsulatorSwapTool t) => switch (t) {
      M4InsulatorSwapTool.pliers => Icons.content_cut_rounded,
      M4InsulatorSwapTool.rope => Icons.gesture_rounded,
      M4InsulatorSwapTool.spanner => Icons.build_rounded,
      M4InsulatorSwapTool.spare => Icons.inventory_2_rounded,
      M4InsulatorSwapTool.bindWire => Icons.all_inclusive_rounded,
      M4InsulatorSwapTool.comeAlong => Icons.link_rounded,
      M4InsulatorSwapTool.turnbuckle => Icons.sync_rounded,
      M4InsulatorSwapTool.splitPin => Icons.push_pin_rounded,
      M4InsulatorSwapTool.none => Icons.circle,
    };

// ============================================================================
// Page
// ============================================================================

class M4InsulatorSwapPage extends StatefulWidget {
  const M4InsulatorSwapPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4InsulatorSwapPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4InsulatorSwapPage> createState() => _M4InsulatorSwapPageState();
}

class _M4InsulatorSwapPageState extends State<M4InsulatorSwapPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SwapRunPage(
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

class _SwapRunPage extends ConsumerStatefulWidget {
  const _SwapRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4InsulatorSwapPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SwapRunPage> createState() => _SwapRunPageState();
}

class _SwapRunPageState extends ConsumerState<_SwapRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4InsulatorSwapRun _run = M4InsulatorSwapRun(m4InsulatorSwapDeal(widget.rng));
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
  /// The coworker was scheduled on his pole (once a play).
  var _coworkerSent = false;
  var _stamp = false;

  // Gesture hints: how to interact, never the answer.
  final _hints = IdleHintController();
  final _toolKeys = {for (final t in M4InsulatorSwapTool.values) t: GlobalKey()};
  final _spareKeys = [for (var j = 0; j < 3; j++) GlobalKey()];
  M4InsulatorSwapGeo? _geoNow;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

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

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  void _start() {
    _clock.start();
    _startPole();
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.fixed && !_freeze;

  String get _task {
    final r = _run;
    if (!r.started) return M4InsulatorSwapLines.askFind;
    if (r.isPin) {
      if (!r.oldOff) return M4InsulatorSwapLines.askFree;
      if (!r.newOn) return M4InsulatorSwapLines.askNew;
      return M4InsulatorSwapLines.askBind;
    }
    if (!r.discOut) return M4InsulatorSwapLines.askOpen;
    if (!r.newDisc) return M4InsulatorSwapLines.askNew;
    return M4InsulatorSwapLines.askBack;
  }

  void _startPole() {
    setState(() {
      _stamp = false;
      _wake++;
    });
    unawaited(_sayChain([M4InsulatorSwapLines.askFind]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _hold(M4InsulatorSwapTool t) {
    if (!_canPlay) return;
    _tick('sounds/quiz_select.ogg');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _pickSpare(int j, Offset global) {
    if (!_canPlay) return;
    _tick('sounds/learn/card_deal_a.ogg', 0.5);
    final m = _run.pickSpare(j);
    setState(() => _wake++);
    if (m != null) unawaited(_mistake(m, global));
  }

  void _tapScene(Offset p, M4InsulatorSwapGeo geo, Offset global) {
    if (_intro || _ended || _card != null || reasonOpen || tableBusy || _freeze || _run.fixed) return;
    // While he talks, going on to bind it tight with the wire refuses him.
    if (coworkerOpen) {
      if (coworkerChoiceUp && _run.tool == M4InsulatorSwapTool.bindWire && geo.phaseHit(_run.pole.kind, _run.pole.bad).contains(p)) {
        unawaited(answerCoworker(true, global, direct: true));
      }
      return;
    }
    for (var i = 0; i < 3; i++) {
      if (!geo.phaseHit(_run.pole.kind, i).contains(p)) continue;
      if (_run.tool == M4InsulatorSwapTool.none) {
        _hints.missTap();
        return;
      }
      _act(i, global);
      return;
    }
    _hints.missTap();
  }

  /// The binding tap on the new insulator: the decisive step he is dealt on.
  bool _isBindTap(int i) {
    final r = _run;
    return r.isPin && r.tool == M4InsulatorSwapTool.bindWire && i == r.pole.bad && r.newOn && !r.newBound;
  }

  void _act(int i, Offset global) {
    final r = _run;
    // On his pole the binding waits for him: a fast play still meets him.
    if (_isBindTap(i) && holdForCoworker()) {
      setState(() => _wake++);
      return;
    }
    final before = (r.bound, r.roped, r.oldOff, r.pinNew, r.newOn, r.rigOn, r.takenUp, r.discOut, r.newDisc, r.pinned);
    final m = r.tapPhase(i);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    final after = (r.bound, r.roped, r.oldOff, r.pinNew, r.newOn, r.rigOn, r.takenUp, r.discOut, r.newDisc, r.pinned);
    if (r.fixed) {
      unawaited(_poleDone());
      return;
    }
    if (before == after) {
      _tick('sounds/intro/click.ogg', 0.3);
      return;
    }
    _cue(r.oldOff || r.discOut ? 'sounds/intro/impact_metal.ogg' : 'sounds/learn/tag_slap.ogg', volume: 0.5);
    HapticFeedback.lightImpact();
    // The new insulator is on the pin: on his pole, the coworker comes now.
    if (r.isPin && r.newOn && !_coworkerSent && r.index == r.deal.callAt) {
      _coworkerSent = true;
      scheduleCoworker();
    }
    final changedStep = before.$3 != after.$3 || before.$5 != after.$5 || before.$8 != after.$8 || before.$9 != after.$9;
    if (changedStep) unawaited(_sayChain([_task]));
  }

  Future<void> _poleDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() => _stamp = true);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final p = _run.pole;
    final idx = _run.index;
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 900));
    if (!mounted || _ended || _run.index != idx) return;
    unawaited(askReason(
      deal: () => dealChoices(M4InsulatorSwapLines.whyRight(p.why), M4InsulatorSwapLines.myths, widget.rng),
      question: M4InsulatorSwapLines.whyQuestion(p.why),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startPole();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M4InsulatorSwapLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push (leave the binding loose) fits only while the new insulator
    // is on and not yet bound.
    if (_ended || _run.index != _run.deal.callAt || !_run.isPin || !_run.newOn || _run.newBound || _run.fixed) return null;
    if (_intro || _card != null || reasonOpen || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a slip; the binding is still to be done right.
      final m = _run.listened();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M4InsulatorSwapLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    if (direct) {
      // He went on binding it tight.
      _act(_run.pole.bad, origin);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4InsulatorSwapLines.callHeld, M4InsulatorSwapLines.askBind], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4InsulatorSwapLines.tapWhy[_nudgeN++ % M4InsulatorSwapLines.tapWhy.length]
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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m4swap/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Pliers on a string under load: the pole top freezes grey and the
  /// conductor whips free in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m4swap/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4InsulatorSwapLines.deadlyWord : M4InsulatorSwapLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same pole goes on from where it was.
        _hush();
        final loose = _card == M4InsulatorSwapMistakes.looseBind;
        setState(() {
          _card = null;
          _wake++;
        });
        unawaited(_sayChain([if (loose) M4InsulatorSwapLines.bindAgain else _task]));
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
    await _say(!_run.passed ? M4InsulatorSwapLines.fail : (_quickBonus ? M4InsulatorSwapLines.quick : M4InsulatorSwapLines.allSet),
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
    if (_run.fixed) return LinemanMode.cheer;
    if (_run.tool != M4InsulatorSwapTool.none) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M4InsulatorSwapGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = geo.trainee;
    final p = _run.pole;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('pole'),
                child: RepaintBoundary(child: CustomPaint(painter: M4InsulatorSwapPainter(geo: geo, view: _run.view, seed: _run.index * 7 + 2))),
              ),
              Positioned.fill(
                key: const ValueKey('strap'),
                child: IgnorePointer(child: CustomPaint(painter: M4InsulatorSwapStrapPainter(box: tb, anchor: geo.anchor))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: RepaintBoundary(child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet)),
              ),
            ],
          ),
        ),
      ),
      if (_stamp && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 20,
          width: 150,
          top: geo.armY + 70,
          child: IgnorePointer(child: _StampPop(text: M4InsulatorSwapLines.stampDone, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4InsulatorSwapLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('snap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4InsulatorSwapSnapPainter(geo: geo, bad: p.bad, v: v)),
            ),
          ),
        ),
      // The next pole: a short fade from the last one.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  /// The gesture hint for now: a sweep over the spares on the tray, over the
  /// three phases with a tool in hand, or over the tool row — never the answer.
  HintSpec? _hint() {
    final r = _run;
    if (r.done) return null;
    if (r.trayOpen) {
      final open = [
        for (var j = 0; j < 3; j++)
          if (!r.setAside.contains(j)) _spareKeys[j],
      ];
      // A sweep over one card would point at it.
      return open.length < 2 ? null : HintSpec.sweepOver(open);
    }
    if (r.tool != M4InsulatorSwapTool.none) {
      final g = _geoNow;
      if (g == null) return null;
      return HintSpec.sweep([for (var i = 0; i < 3; i++) g.phaseHit(r.pole.kind, i)], space: HintSpace.scene);
    }
    return HintSpec.sweepOver([for (final t in r.deal.toolsAt(r.index)) _toolKeys[t]!]);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.done && !_run.fixed && !deckUp && !coworkerOpen && _card == null;
    final p = _run.pole;
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
              labels: M4InsulatorSwapLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.index}-${_run.tool.name}-${_run.trayOpen}-${_run.setAside.length}-$_task',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(kind: p.kind)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && _run.trayOpen)
                Positioned(
                  key: ValueKey('tray-${_run.index}'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 96,
                  child: _SpareTray(
                    kind: p.kind,
                    spares: p.spares,
                    setAside: {..._run.setAside},
                    keys: _spareKeys,
                    quiet: quiet,
                    onPick: _pickSpare,
                  ),
                ),
              if (handsOn)
                Positioned(
                  key: ValueKey('hud-tools-${p.kind.name}'),
                  left: 2,
                  right: 2,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final t in _run.deal.toolsAt(_run.index))
                        _ToolButton(
                          key: _toolKeys[t],
                          icon: _toolIcon(t),
                          label: _toolLabel(t, p.kind),
                          on: _run.tool == t || (t == M4InsulatorSwapTool.spare && _run.trayOpen),
                          onTap: () => _hold(t),
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (_run.trayOpen && handsOn ? 236 : 96)), onLeft: !coworkerOnScreen || coworkerFromRight),
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
                  line: M4InsulatorSwapLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.kind});
  final M4InsulatorSwapKind kind;

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
          Text(M4InsulatorSwapLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4InsulatorSwapLines.jobBn(kind), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          Text(M4InsulatorSwapLines.docketDone, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D4F))),
        ],
      ),
    );
  }
}

/// The spares on a cloth on the cross-arm: three to inspect, one sound.
class _SpareTray extends StatelessWidget {
  const _SpareTray({required this.kind, required this.spares, required this.setAside, required this.keys, required this.quiet, required this.onPick});
  final M4InsulatorSwapKind kind;
  final List<M4InsulatorSwapDamage?> spares;
  final Set<int> setAside;

  /// One key per spare (the gesture hint's sweep).
  final List<GlobalKey> keys;
  final bool quiet;
  final void Function(int j, Offset global) onPick;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 30 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xF0E9DFC8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            for (var j = 0; j < spares.length; j++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Semantics(
                    key: keys[j],
                    button: true,
                    label: '${M4InsulatorSwapLines.spare} ${j + 1}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: setAside.contains(j) ? null : (d) => onPick(j, d.globalPosition),
                      child: Opacity(
                        opacity: setAside.contains(j) ? 0.25 : 1,
                        child: Container(
                          height: 118,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFB9A983)),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: CustomPaint(painter: M4InsulatorSwapSparePainter(kind: kind, damage: spares[j])),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: bangla(fontSize: 10, fontWeight: FontWeight.w800, height: 1.1, color: SlmColors.ivory)),
              ),
            ],
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
