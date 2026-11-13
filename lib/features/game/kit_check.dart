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
import 'mistake_kit.dart';
import 'level_shell.dart';
import 'reason_table.dart';
import 'choice_deck.dart';
import 'scene_kit.dart';
import 'store_room.dart';
import 'spoken_once.dart';

// ============================================================================
// Data
// ============================================================================

/// Body part a kit item goes on, dressed in this order.
enum KitSlot { torso, legs, feet }

/// good: the right item, sound. flawed: the right item with a defect only a
/// close look shows. wrong: the wrong item for line work.
enum KitKind { good, flawed, wrong }

/// Defects painted over a picture (placeholders until flawed photos exist).
enum KitFlawKind { grease, burn, tear, oil, nail, crack }

/// One way a good item can turn up damaged. [marks] are positions inside the
/// picture box (0–1 on each axis); [inspectAsset] replaces the painted marks
/// with a real photo of the damaged item when one exists.
@immutable
class KitFlaw {
  const KitFlaw({
    required this.id,
    required this.kind,
    required this.marks,
    required this.labelBn,
    required this.lineBn,
    this.inspectAsset,
    this.deadly,
  });

  final String id;
  final KitFlawKind kind;
  final List<Offset> marks;
  final String labelBn;
  final String lineBn;
  final String? inspectAsset;

  /// Wearing an item with this flaw is deadly (owner decision 2026-11-08:
  /// a nail in the sole). Null = a slip.
  final DoMistake? deadly;
}

@immutable
class KitItem {
  const KitItem({
    required this.id,
    required this.slot,
    required this.kind,
    required this.asset,
    required this.aspect,
    required this.labelBn,
    this.lineBn = '',
    this.flaws = const [],
    this.flaw,
    this.wornAsset,
    this.deadly,
  });

  /// Stable id. A dealt flawed copy is `<good id>#<flaw id>`.
  final String id;
  final KitSlot slot;
  final KitKind kind;
  final String asset;
  final double aspect;
  final String labelBn;

  /// Why it is wrong / what the flaw is.
  final String lineBn;

  /// Good items only: the ways this item can turn up damaged.
  final List<KitFlaw> flaws;

  /// Flawed copies only: the defect it has.
  final KitFlaw? flaw;

  /// The figure wearing this wrong item — the "what would happen" picture.
  final String? wornAsset;

  /// Wearing it is deadly (owner decision 2026-11-08: synthetic clothing, a
  /// nail in the boot sole). Null = wearing it is a slip.
  final DoMistake? deadly;

  KitItem withFlaw(KitFlaw f) => KitItem(
        id: '$id#${f.id}',
        slot: slot,
        kind: KitKind.flawed,
        asset: asset,
        aspect: aspect,
        labelBn: f.labelBn,
        lineBn: f.lineBn,
        flaw: f,
        deadly: f.deadly,
      );

  /// Key for the "explain once" memory: the flaw kind, or the wrong item.
  String get lessonKey => flaw != null ? 'flaw/${flaw!.kind.name}' : 'item/$id';
}

/// Someone rushing the player before one slot is dressed.
typedef KitCaller = DoCaller;

@immutable
class KitCheckPack {
  const KitCheckPack({
    required this.id,
    required this.titleBn,
    required this.sceneBn,
    required this.introBn,
    required this.pool,
    required this.callers,
    required this.callBefore,
    required this.quickMs,
  });

  final String id;
  final String titleBn;

  /// Where and when, shown at the start ("সকাল 7টা · …").
  final String sceneBn;
  final String introBn;

  /// Every good and wrong item that can be dealt; flawed copies are made
  /// from the good items' [KitItem.flaws] at deal time.
  final List<KitItem> pool;
  final List<KitCaller> callers;

  /// The pressure call comes before one of these slots (picked per play).
  final List<KitSlot> callBefore;

  /// A clean play faster than this earns the "ঝটপট ও নির্ভুল" bonus.
  final int quickMs;
}

/// Fixed coach lines (recorded with the Learn voice pack).
abstract final class KitLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askTorso, askLegs, askFeet];

  static const askTorso = 'আগে জামা। হাতে নিয়ে ভালো করে দেখুন।';
  static const askLegs = 'এবার প্যান্ট। দেখে তবেই পরুন।';
  static const askFeet = 'এবার জুতো। সোলটা দেখতে ভুলবেন না।';
  static const caught = 'ঠিক ধরেছেন!';

  /// The mistakes book's line for a sound item sent back (after the play).
  static const rejectedGood = 'এটা তো ঠিক ছিল!';

  /// What the guide says and the card shows when a sound item is sent back:
  /// neutral (audit 2026-11-11) — it never says the item was fine.
  static const lookAgain = 'থামুন, ভালো করে দেখুন।';
  static const callHeld = 'ঠিক। তাড়াহুড়োতেই দুর্ঘটনা হয়।';
  static const callRushed = 'না! চেক বাদ দেওয়া মানেই ঝুঁকি।';
  static const allSet = 'সব ঠিক আছে। এবার কাজে নামা যায়।';
  static const fail = 'এবার হলো না। দেখে নিয়ে আবার চেষ্টা করুন।';
  static const quick = 'ঝটপট আর নির্ভুল! বোনাস পেলেন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const checkFirst = DoLines.checkFirst;
  static const rushOn = DoLines.rushOn;


  // The reason after each piece worn (lesson 1.1): one right and two wrong
  // dealt, all about the same length.
  static const whyAsk = 'কেন এটা পরলেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const whyTorsoRight = [
    'সুতি বা FR গলে চামড়ায় সেঁটে যায় না',
    'পুরো হাত ঢাকা — স্পার্কে চামড়া বাঁচে',
    'আর্ক ফ্ল্যাশে সুতি গলে না, চামড়া বাঁচে',
  ];
  static const whyTorsoWrong = [
    'গরমে পলিয়েস্টারই সবচেয়ে আরাম দেয়',
    'মেটাল জিপার থাকলে আরও নিরাপদ হয়',
    'রঙিন জামা দূর থেকে দেখা যায় বলে',
    'ঢিলে জামায় পোলে ওঠা সহজ হয় বলে',
    'হাফ-হাতায় কাজ করতে সুবিধা অনেক বেশি',
  ];
  static const whyLegsRight = [
    'পুরো পা ঢাকা — ঘষা আর স্পার্কে বাঁচায়',
    'সুতি আগুনে গলে চামড়ায় সাঁটে না',
    'তেলমুক্ত প্যান্ট ফুলকিতে জ্বলে ওঠে না',
  ];
  static const whyLegsWrong = [
    'হাফ প্যান্টে পোলে ওঠা অনেক সহজ হয়',
    'ঢিলে পাজামায় বাতাস খেলে, আরাম লাগে',
    'তেল লাগা প্যান্টে জল ঢুকতে পারে না',
    'যেকোনো প্যান্ট পরলেই কাজ চলে যায়',
    'গরমে পা খোলা রাখাই সবচেয়ে ভালো',
  ];
  static const whyFeetRight = [
    'অক্ষত রাবার সোল কারেন্টের পথ আটকায়',
    'শক্ত গ্রিপে মই আর পোলে পা হড়কায় না',
    'বুট পা ঢেকে রাখে, আঘাত থেকে বাঁচায়',
  ];
  static const whyFeetWrong = [
    'চপ্পলে হাঁটা সহজ, তাই বেশি নিরাপদ',
    'সাধারণ জুতোও কারেন্ট আটকে দেয়',
    'সোলে পেরেক থাকলে গ্রিপ আরও বাড়ে',
    'সোল একটু ফাটা হলেও কাজ চলে যায়',
    'খালি পায়ে মাটির সাথে ভালো যোগ থাকে',
  ];
  static List<String> whyRight(KitSlot s) => switch (s) {
        KitSlot.torso => whyTorsoRight,
        KitSlot.legs => whyLegsRight,
        KitSlot.feet => whyFeetRight,
      };
  static List<String> whyWrong(KitSlot s) => switch (s) {
        KitSlot.torso => whyTorsoWrong,
        KitSlot.legs => whyLegsWrong,
        KitSlot.feet => whyFeetWrong,
      };

  /// The careless coworker (his recorded voice) pushes to skip the check.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const choiceRight = [
    'না — আগে দেখে তবেই পরব',
    'চেক বাদ দিয়ে কাজে নামব না',
    'দেখতে এক মিনিটই তো লাগবে',
    'আগে দেখে নিই, তারপর গাড়িতে',
  ];
  static const choiceWrong = [
    'ঠিক বলেছে, দেখার দরকার নেই',
    'যা পাই তাই পরে নিই, চলো',
    'পরে দেখে নেব, এখন চলি',
    'একবার চোখ বুলিয়ে নিলেই হবে',
    'সবাই তো এভাবেই পরে নেয়',
  ];
  static const choiceAsks = [
    'ও বলছে দেখার সময় নেই। আপনি কী করবেন?',
    'চেক বাদ দেবেন, না দেখে তবেই পরবেন?',
    'কার কথা শুনবেন — ওর, না নিয়মের?',
  ];
  static const coworkerHurry = CoworkerScript(
    line: 'চল চল, দেরি হচ্ছে! এসব দেখার সময় নেই।',
    exitLine: coworkerExit,
    right: choiceRight,
    wrong: choiceWrong,
    asks: choiceAsks,
  );
  static const coworkerVan = CoworkerScript(
    line: 'জলদি করো! গাড়ি দাঁড়িয়ে আছে। চেক-টেক পরে হবে!',
    exitLine: coworkerExit,
    right: choiceRight,
    wrong: choiceWrong,
    asks: choiceAsks,
  );

  static String ask(KitSlot s) => switch (s) {
        KitSlot.torso => askTorso,
        KitSlot.legs => askLegs,
        KitSlot.feet => askFeet,
      };

  static const coach = [askTorso, askLegs, askFeet, caught, rejectedGood, lookAgain, callHeld, callRushed, allSet, fail, quick, deadlyWord, nearMissWord];
}

/// The two kit mistakes that end a play (lesson 1.1, owner decision
/// 2026-11-08). Every other wrong pick is a slip.
abstract final class KitMistakes {
  /// Lesson 1.1 point 1 (importance): synthetic cloth melts onto the skin.
  static const synthetic = DoMistake(
    key: '1.1/kit/synthetic',
    textBn: 'লাইনে সামান্য স্পার্ক বা আর্কিং ফ্ল্যাশ হলেই সিন্থেটিক কাপড় প্লাস্টিকের মতো গলে সোজা চামড়ায় সেঁটে যায়। পরুন শুধু সুতি বা FR কাপড়।',
    art: 'assets/duty_slip/dress/mistake_synthetic.svg',
    deadly: true,
    lessonPoint: 0,
  );

  /// Lesson 1.1 point 3 (daily check): a nail in the sole is the current's
  /// path to the ground.
  static const nail = DoMistake(
    key: '1.1/kit/boot-nail',
    textBn: 'সোলে পেরেক গেঁথে থাকলে সেটাই কারেন্টের মাটিতে নামার রাস্তা বানিয়ে দেয় — সাক্ষাৎ মৃত্যুফাঁদ। জুতোর তলা রোজ দেখে নিন।',
    art: 'assets/duty_slip/dress/mistake_nail.svg',
    deadly: true,
    lessonPoint: 2,
  );

  static const all = [synthetic, nail];

  /// Listening to the careless coworker (playbook row 8): a slip, never
  /// deadly. Lesson 1.1's daily check (clothes = point 1, shoes = point 3).
  static const rushedKey = '1.1/kit/rushed';
  static const rushedBn = 'তাড়ার কথায় চেক বাদ নয়। কাজ শুরুর আগে পোশাক আর জুতো রোজ দেখে নিন।';
  static DoMistake rushed(KitSlot before) => DoMistake(
        key: rushedKey,
        textBn: rushedBn,
        art: '$_d/myth_rival_bad.webp',
        lessonPoint: before == KitSlot.feet ? 2 : 0,
      );
}

const _d = 'assets/duty_slip/dress';
const _ppe = 'assets/safety/library/ppe';

const _greaseLine = 'জামায় তেল-গ্রিজ লেগে আছে। ফুলকি পড়লেই জ্বলে উঠবে।';
const _burnLine = 'জামায় পোড়া ফুটো। ওখান দিয়েই আগুনের তাপ চামড়ায় লাগবে।';
const _tearLine = 'হাতা ছেঁড়া। ঝুলন্ত কাপড় তারে বা যন্ত্রে আটকে যাবে।';
const _oilLine = 'প্যান্টে মোবিলের দাগ। আগুনের ফুলকিতে দপ করে জ্বলবে।';
const _nailLine = 'সোলে পেরেক গেঁথে আছে। কারেন্ট মাটিতে নামার রাস্তা পেয়ে যাবে।';
const _crackLine = 'সোল ফেটে গেছে। ফাটল দিয়ে জল আর কারেন্ট দুটোই ঢুকবে।';

/// Lesson 1.1, first Do: dress for work from the store's old kit — and look
/// before you wear. A fresh set is dealt every play.
const kitCheckPack11 = KitCheckPack(
  id: 'kit_check_1_1',
  titleBn: 'কবচ যাচাই',
  sceneBn: 'সকাল 7টা · সাবস্টেশনের স্টোর রুম',
  introBn: 'কাল রাতের ঝড়ে লাইন পড়েছে। স্টোরের কিট পুরনো—প্রতিটা জিনিস দেখে তবেই পরুন।',
  quickMs: 75000,
  callBefore: [KitSlot.legs, KitSlot.feet],
  callers: [
    KitCaller(id: 'je', whoBn: 'JE সাহেব (ফোনে)', lineBn: 'জলদি করো! গাড়ি দাঁড়িয়ে আছে। চেক-টেক পরে হবে!', icon: Icons.phone_in_talk_rounded),
    KitCaller(id: 'crowd', whoBn: 'বাইরে গ্রাহকেরা', lineBn: 'কারেন্ট কখন আসবে? সকাল থেকে বসে আছি!', icon: Icons.groups_rounded),
    KitCaller(id: 'mate', whoBn: 'সহকর্মী', lineBn: 'চল চল, দেরি হচ্ছে! এসব দেখার সময় নেই।', icon: Icons.directions_run_rounded),
  ],
  pool: [
    // ---- জামা
    KitItem(
      id: 'shirt',
      slot: KitSlot.torso,
      kind: KitKind.good,
      asset: '$_d/tray_shirt.webp',
      aspect: 435 / 512,
      labelBn: 'সুতি ফুল-হাতা জামা',
      flaws: [
        KitFlaw(
          id: 'grease',
          kind: KitFlawKind.grease,
          marks: [Offset(0.40, 0.46), Offset(0.58, 0.62), Offset(0.66, 0.38), Offset(0.30, 0.70)],
          labelBn: 'গ্রিজ লাগা জামা',
          lineBn: _greaseLine,
        ),
        KitFlaw(id: 'burn', kind: KitFlawKind.burn, marks: [Offset(0.62, 0.40)], labelBn: 'পোড়া ফুটো জামা', lineBn: _burnLine),
        KitFlaw(id: 'tear', kind: KitFlawKind.tear, marks: [Offset(0.86, 0.66)], labelBn: 'ছেঁড়া হাতার জামা', lineBn: _tearLine),
      ],
    ),
    KitItem(id: 'poly', slot: KitSlot.torso, kind: KitKind.wrong, asset: '$_d/tray_poly.webp', aspect: 431 / 512, labelBn: 'পলিয়েস্টার জামা', lineBn: 'আর্ক ফ্ল্যাশের তাপে পলিয়েস্টার গলে চামড়ায় সেঁটে যায়।', wornAsset: '$_d/worn_poly.webp', deadly: KitMistakes.synthetic),
    KitItem(id: 'halftee', slot: KitSlot.torso, kind: KitKind.wrong, asset: '$_d/tray_halftee.webp', aspect: 473 / 512, labelBn: 'হাফ-হাতা গেঞ্জি', lineBn: 'হাত খোলা থাকলে সামান্য স্পার্কেই চামড়া পুড়ে যাবে।'),
    KitItem(id: 'fatua', slot: KitSlot.torso, kind: KitKind.wrong, asset: '$_d/tray_fatua.webp', aspect: 473 / 512, labelBn: 'ফতুয়া', lineBn: 'ঢিলে ফতুয়া বাতাসে উড়ে তারে জড়িয়ে যেতে পারে।'),
    // ---- প্যান্ট
    KitItem(
      id: 'pant',
      slot: KitSlot.legs,
      kind: KitKind.good,
      asset: '$_d/tray_pant.webp',
      aspect: 223 / 512,
      labelBn: 'সুতির ফুল প্যান্ট',
      flaws: [
        KitFlaw(id: 'oil', kind: KitFlawKind.oil, marks: [Offset(0.35, 0.55), Offset(0.66, 0.72), Offset(0.42, 0.33)], labelBn: 'মোবিল লাগা প্যান্ট', lineBn: _oilLine),
      ],
    ),
    KitItem(id: 'halfpant', slot: KitSlot.legs, kind: KitKind.wrong, asset: '$_d/tray_halfpant.webp', aspect: 456 / 512, labelBn: 'হাফ প্যান্ট', lineBn: 'পা খোলা রেখে লাইনের কাজ নয়। তারের ঘষায় চামড়া কাটবে।'),
    KitItem(id: 'pajama', slot: KitSlot.legs, kind: KitKind.wrong, asset: '$_d/tray_pajama.webp', aspect: 245 / 512, labelBn: 'ঢিলে পাজামা', lineBn: 'ঢিলে পাজামা যন্ত্রে আটকে ভারসাম্য নষ্ট করে।'),
    // ---- জুতো
    KitItem(
      id: 'boot',
      slot: KitSlot.feet,
      kind: KitKind.good,
      asset: '$_d/tray_boot.webp',
      aspect: 512 / 342,
      labelBn: 'সেফটি বুট',
      flaws: [
        KitFlaw(id: 'boot-nail', kind: KitFlawKind.nail, marks: [Offset(0.26, 0.90)], labelBn: 'পেরেক গাঁথা বুট', lineBn: _nailLine, deadly: KitMistakes.nail),
        KitFlaw(id: 'boot-crack', kind: KitFlawKind.crack, marks: [Offset(0.12, 0.88)], labelBn: 'ফাটা সোলের বুট', lineBn: _crackLine),
      ],
    ),
    KitItem(
      id: 'boot2',
      slot: KitSlot.feet,
      kind: KitKind.good,
      asset: '$_ppe/Lineman_Boot_2.webp',
      aspect: 600 / 597,
      labelBn: 'লাইনম্যান বুট',
      flaws: [
        KitFlaw(id: 'boot2-nail', kind: KitFlawKind.nail, marks: [Offset(0.46, 0.92)], labelBn: 'পেরেক গাঁথা বুট', lineBn: _nailLine, deadly: KitMistakes.nail),
        KitFlaw(id: 'boot2-crack', kind: KitFlawKind.crack, marks: [Offset(0.22, 0.90)], labelBn: 'ফাটা সোলের বুট', lineBn: _crackLine),
      ],
    ),
    KitItem(
      id: 'boot3',
      slot: KitSlot.feet,
      kind: KitKind.good,
      asset: '$_ppe/Lineman_Boot_3.webp',
      aspect: 704 / 621,
      labelBn: 'সেফটি জুতো',
      flaws: [
        KitFlaw(id: 'boot3-nail', kind: KitFlawKind.nail, marks: [Offset(0.46, 0.43)], labelBn: 'পেরেক গাঁথা জুতো', lineBn: _nailLine, deadly: KitMistakes.nail),
        KitFlaw(id: 'boot3-crack', kind: KitFlawKind.crack, marks: [Offset(0.14, 0.41)], labelBn: 'ফাটা সোলের জুতো', lineBn: _crackLine),
      ],
    ),
    KitItem(id: 'slipper', slot: KitSlot.feet, kind: KitKind.wrong, asset: '$_d/tray_slipper.webp', aspect: 455 / 512, labelBn: 'চপ্পল', lineBn: 'চপ্পলে গ্রিপ নেই। পা হড়কালেই পতন।', wornAsset: '$_d/worn_slip.webp'),
    KitItem(id: 'shoe', slot: KitSlot.feet, kind: KitKind.wrong, asset: '$_d/tray_normalshoe.webp', aspect: 512 / 249, labelBn: 'সাধারণ জুতো', lineBn: 'সাধারণ সোলে বৈদ্যুতিক সুরক্ষা নেই।'),
  ],
);

/// Do packs by game pack id (catalog `gamePacks[].id`).
const kitCheckPacks = <String, KitCheckPack>{'do_1_1_a': kitCheckPack11};

// ============================================================================
// Deal + rules (pure, tested)
// ============================================================================

/// One play's set: what is on offer per slot, and who calls before which slot.
@immutable
class KitDeal {
  const KitDeal({required this.items, required this.callBefore, required this.caller});
  final List<KitItem> items;
  final KitSlot callBefore;
  final KitCaller caller;
}

/// Deals a fresh set: per slot one sound item, a damaged copy that looks the
/// same in the tray (always for shirt and boots, often for trousers), and 1–2
/// wrong items. Picture, flaw, wrong items, caller and call slot all vary.
KitDeal dealKit(KitCheckPack pack, math.Random rng) {
  T pick<T>(List<T> l) => l[rng.nextInt(l.length)];
  final items = <KitItem>[];
  for (final slot in KitSlot.values) {
    final goods = [for (final i in pack.pool) if (i.slot == slot && i.kind == KitKind.good) i];
    final wrongs = [for (final i in pack.pool) if (i.slot == slot && i.kind == KitKind.wrong) i]..shuffle(rng);
    final good = pick(goods);
    items.add(good);
    final flawable = [for (final g in goods) if (g.flaws.isNotEmpty) g];
    if (flawable.isNotEmpty && (slot != KitSlot.legs || rng.nextBool())) {
      // Mostly the same picture as the sound one, so only a close look tells them apart.
      final base = flawable.contains(good) && rng.nextDouble() < 0.7 ? good : pick(flawable);
      items.add(base.withFlaw(pick(base.flaws)));
    }
    final wrongCount = slot == KitSlot.torso ? 2 : 1 + rng.nextInt(2);
    items.addAll(wrongs.take(math.min(wrongCount, wrongs.length)));
  }
  return KitDeal(items: items, callBefore: pick(pack.callBefore), caller: pick(pack.callers));
}

enum KitChoice { wear, reject }

/// What a decision means. [stampBn] lands on the card; [reasonBn] is spoken
/// the first time this flaw / wrong item is met, shown as text after that.
@immutable
class KitOutcome {
  const KitOutcome({
    required this.right,
    required this.delta,
    required this.wears,
    required this.leavesTray,
    required this.stampBn,
    this.reasonBn = '',
    this.deadly,
  });

  final bool right;
  final int delta;
  final bool wears;
  final bool leavesTray;
  final String stampBn;
  final String reasonBn;

  /// Set when the decision ends the play (wearing a deadly item).
  final DoMistake? deadly;
}

const kitStampRight = 'ঠিক';
const kitStampReject = 'বাতিল';
const kitStampWrong = 'ভুল';

KitOutcome judgeKit(KitItem item, KitChoice choice) {
  switch ((item.kind, choice)) {
    case (KitKind.good, KitChoice.wear):
      return const KitOutcome(right: true, delta: 10, wears: true, leavesTray: true, stampBn: kitStampRight);
    case (KitKind.good, KitChoice.reject):
      return const KitOutcome(right: false, delta: -5, wears: false, leavesTray: false, stampBn: kitStampWrong);
    case (_, KitChoice.wear):
      return KitOutcome(right: false, delta: -5, wears: false, leavesTray: true, stampBn: kitStampWrong, reasonBn: item.lineBn, deadly: item.deadly);
    case (_, KitChoice.reject):
      return KitOutcome(right: true, delta: 5, wears: false, leavesTray: true, stampBn: kitStampReject, reasonBn: item.lineBn);
  }
}

/// The mistakes-book entry for a wrong decision that is not deadly: a stable
/// key per flaw / wrong item (or the sound item sent back) and the lesson
/// point that teaches it (clothing = point 1, shoes = point 3).
DoMistake kitSlip(KitItem item, KitOutcome o) {
  final goodRejected = item.kind == KitKind.good;
  return DoMistake(
    key: goodRejected ? '1.1/kit/rejected-good' : '1.1/kit/${item.lessonKey}',
    textBn: goodRejected || o.reasonBn.isEmpty ? KitLines.rejectedGood : o.reasonBn,
    art: item.asset,
    lessonPoint: item.slot == KitSlot.feet ? 2 : 0,
  );
}

/// One play: which slot is being dressed, what is left in the tray, what is
/// worn, what was caught, and the first-try mark.
class KitCheckRound {
  KitCheckRound(this.deal);

  final KitDeal deal;
  final worn = <KitSlot>{};
  final caught = <KitItem>[];
  final _gone = <String>{};
  final _tried = <String>{};
  int asked = 0;
  int clean = 0;
  bool callDone = false;

  /// The deadly item worn (the play ends there).
  DoMistake? deadly;

  KitSlot? get slot {
    for (final s in KitSlot.values) {
      if (!worn.contains(s)) return s;
    }
    return null;
  }

  bool get done => slot == null;
  bool get callDue => !callDone && slot == deal.callBefore;

  List<KitItem> get tray => [
        for (final i in deal.items)
          if (i.slot == slot && !_gone.contains(i.id)) i,
      ];

  /// The play is over (a deadly item worn, or every slot dressed).
  bool get ended => deadly != null || done;

  /// Judges [item]; once the play has [ended] nothing more is recorded.
  KitOutcome decide(KitItem item, KitChoice choice) {
    final o = judgeKit(item, choice);
    if (ended) return o;
    deadly ??= o.deadly;
    if (_tried.add(item.id)) {
      asked++;
      if (o.right) clean++;
    }
    if (o.right && choice == KitChoice.reject) caught.add(item);
    if (o.leavesTray) _gone.add(item.id);
    if (o.wears) worn.add(item.slot);
    return o;
  }

  void answerCall({required bool heldCheck}) {
    if (callDone || ended) return;
    callDone = true;
    asked++;
    if (heldCheck) clean++;
  }

  int get percent => asked == 0 ? 0 : (clean * 100 / asked).round();
  bool get passed => deadly == null && percent >= kLessonPassMark;
}

/// Figure picture for what is worn (every combination exists in the dress art).
String kitFigureAsset(Set<KitSlot> worn) {
  final parts = [
    if (worn.contains(KitSlot.torso)) 'shirt',
    if (worn.contains(KitSlot.legs)) 'pant',
    if (worn.contains(KitSlot.feet)) 'boot',
  ];
  if (parts.isEmpty) return '$_d/body.webp';
  if (parts.length == 3) return '$_d/all.webp';
  return '$_d/${parts.join('_')}.webp';
}

/// Every fixed coach line of [p] for the voice pack.
Iterable<String> kitCheckSpokenLines(KitCheckPack p) sync* {
  yield p.introBn;
  yield* KitLines.coach;
  for (final m in KitMistakes.all) {
    yield m.textBn;
  }
  yield KitMistakes.rushedBn;
  for (final i in p.pool) {
    if (i.lineBn.isNotEmpty) yield i.lineBn;
    for (final f in i.flaws) {
      yield f.lineBn;
    }
  }
}

/// Callers' lines, spoken in the rival's (other) voice.
Iterable<String> kitCheckCallerLines(KitCheckPack p) => p.callers.map((c) => c.lineBn);

// ============================================================================
// Page
// ============================================================================

/// A kit-check Do level inside the shared level shell. "আবার খেলুন" remounts
/// the play (with a new deal) on the same route, so the ladder keeps waiting.
class KitCheckPage extends StatefulWidget {
  const KitCheckPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final KitCheckPack pack;
  final bool muted;

  /// Fixed deal for tests; null = a fresh random deal every play.
  final int? seed;

  @override
  State<KitCheckPage> createState() => _KitCheckPageState();
}

class _KitCheckPageState extends State<KitCheckPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _KitCheckRun(
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

class _KitCheckRun extends ConsumerStatefulWidget {
  const _KitCheckRun({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.rng,
    required this.onRetry,
  });

  final LevelContext ctx;
  final KitCheckPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_KitCheckRun> createState() => _KitCheckRunState();
}

enum _Overlay { none, inspect, consequence }

class _KitCheckRunState extends ConsumerState<_KitCheckRun> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();

  /// Gesture hints: the tray (its cards are found under this key) and the
  /// inspect card's two buttons.
  final _hints = IdleHintController();
  final _trayKey = GlobalKey();
  final _rejectKey = GlobalKey();
  final _wearKey = GlobalKey();
  late final KitDeal _deal = dealKit(widget.pack, widget.rng);
  late final KitCheckRound _r = KitCheckRound(_deal);
  late final List<KitItem> _order = [..._deal.items]..shuffle(widget.rng);
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _rightBag = LineBag(LearnFeedbackLines.right);
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; play starts when it is done.
  var _introCard = true;
  int _chain = 0;
  int _wave = 0;
  int _figureWave = 0;

  /// Slot whose tray is on screen (the first is dealt with the page).
  KitSlot? _dealtSlot = KitSlot.torso;

  /// A short hold the player can cut with a tap (see [_dwell]).
  Completer<void>? _skip;

  _Overlay _overlay = _Overlay.none;
  KitItem? _held;
  KitItem? _shown;
  KitOutcome? _verdict;
  var _leaving = false;
  Completer<void>? _gone;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int? _mark;
  int? _stars;
  int _totalDelta = 0;

  /// A deadly item was worn: the store freezes grey, the consequence plays in
  /// colour, then the near-miss / death card.
  var _freeze = false;
  Completer<void>? _frozen;
  KitItem? _deathItem;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.deadly;

  String get _rungId => widget.ctx.rungId;

  @override
  LevelContext get deathCtx => widget.ctx;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  List<KitItem> get _tray {
    final left = _r.tray.map((i) => i.id).toSet();
    return [for (final i in _order) if (left.contains(i.id)) i];
  }

  // ---- voice -----------------------------------------------------------------

  /// Speaks [line] (the caption shows it). Muted: returns at once — the text
  /// stays in the strip, and nothing waits on reading time.
  Future<void> _say(String line, {GuideMood mood = GuideMood.talk, bool other = false}) async {
    if (line.trim().isEmpty || !mounted) return;
    if (!other) ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted, rival: other);
  }

  /// Speaks [lines] in order unless the player moves on (a pick cuts it).
  Future<void> _sayChain(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    for (final l in lines) {
      if (!mounted || chain != _chain) return;
      await _say(l, mood: mood);
    }
  }

  /// Waits [d], or less if the player taps to move on.
  Future<void> _dwell(Duration d) async {
    final skip = _skip = Completer<void>();
    await Future.any([skip.future, Future<void>.delayed(d)]);
    if (identical(_skip, skip)) _skip = null;
  }

  void _skipDwell() {
    final s = _skip;
    if (s != null && !s.isCompleted) s.complete();
  }

  // ---- flow ------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    await _askSlot();
  }

  Future<void> _askSlot() async {
    final s = _r.slot;
    if (s == null || !mounted) return;
    if (_r.callDue) scheduleCoworker();
    if (s != _dealtSlot) {
      setState(() {
        _dealtSlot = s;
        _wave++;
      });
    }
    // The player may already be looking at a card: don't talk over it.
    if (_overlay == _Overlay.none) await _sayChain([KitLines.ask(s)]);
  }

  /// Tap on the shade before deciding: the item goes back to the tray.
  void _putBack() {
    if (_busy || _verdict != null || _overlay != _Overlay.inspect) return;
    HapticFeedback.selectionClick();
    setState(() {
      _overlay = _Overlay.none;
      _held = null;
    });
  }

  /// The tray takes a pick: nothing else on screen, and never in the praise
  /// window of a right move ([tableBusy]).
  bool get _canPick => !_busy && !_ended && !_introCard && _overlay == _Overlay.none && !coworkerOpen && !tableBusy;

  void _pickUp(KitItem item) {
    if (coworkerOpen && !coworkerChoiceUp) unawaited(answerCoworker(true, _screenCentre, direct: true));
    if (!_canPick) return;
    // He is due before this piece: he cuts in now (a fast play never skips him).
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: false));
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    // A fresh look: yesterday's caption ("ঠিক ধরেছেন!") must not linger.
    ref.read(guideDirectorProvider.notifier).clearLine();
    setState(() {
      _held = item;
      _verdict = null;
      _leaving = false;
      _overlay = _Overlay.inspect;
    });
  }

  Future<void> _decide(KitChoice choice, Offset origin) async {
    final item = _held;
    if (item == null || _busy || _ended || _verdict != null || tableBusy) return;
    // Still due (the card was opened before his moment): the card goes back
    // and he cuts in before anything is decided.
    if (holdForCoworker()) {
      setState(() {
        _overlay = _Overlay.none;
        _held = null;
      });
      return;
    }
    _busy = true;
    final o = _r.decide(item, choice);
    if (o.deadly != null) {
      await _deadly(item, o.deadly!);
      return;
    }
    if (!o.right) {
      // A slip goes into the mistakes book; the third ends the play.
      final slip = kitSlip(item, o);
      unawaited(bookMistake(ref, widget.ctx, slip));
      if (strike(slip)) {
        await _struckOut();
        return;
      }
    }
    if (o.right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/stomp.wav', volume: o.right ? 0.45 : 0.7, muted: false));
    if (o.wears) {
      putOnTable(o.delta);
    } else {
      unawaited(_levelDelta(o.delta, origin, mood: o.right ? GuideMood.glad : GuideMood.warn));
      // The coach reacts on his own time; his voice never holds the player.
      unawaited(_react(item, o, choice));
    }

    final worstWear = !o.right && choice == KitChoice.wear && item.wornAsset != null;
    if (worstWear) {
      // Straight to "what would happen": short, and a tap skips it.
      if (!_muted) unawaited(ZlFx.cue('sounds/dress_wrong.wav', volume: 0.7, muted: false));
      setState(() {
        _overlay = _Overlay.consequence;
        _shown = item;
        _held = null;
      });
      await _dwell(const Duration(milliseconds: 1600));
      if (!mounted) return;
      setState(() {
        _overlay = _Overlay.none;
        _shown = null;
      });
      _busy = false;
      return;
    }

    // Stamp + flaw pulse for a moment (a tap moves on sooner), then the card
    // goes: onto the body, out of the store, or a shake back to the tray.
    setState(() => _verdict = o);
    // Short: the reason stays in the coach strip after the card has gone.
    await _dwell(Duration(milliseconds: o.reasonBn.isEmpty ? 750 : 1000));
    if (!mounted) return;
    final gone = _gone = Completer<void>();
    setState(() => _leaving = true);
    await gone.future.timeout(const Duration(seconds: 1), onTimeout: () {});
    if (!mounted) return;
    setState(() {
      _overlay = _Overlay.none;
      _held = null;
      _verdict = null;
      _leaving = false;
      if (o.wears) _figureWave++;
    });
    _busy = false;
    if (o.wears) {
      // "কেন এটা পরলেন?" — the right reason pays the table, then the next piece.
      final slot = item.slot;
      unawaited(askReason(
        deal: () => dealChoices(KitLines.whyRight(slot), KitLines.whyWrong(slot), widget.rng),
        question: KitLines.whyAsk,
      ));
    }
  }

  Offset get _screenCentre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  @override
  bool get reasonMuted => _muted;
  @override
  bool get reasonEnded => _ended;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void reasonHush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) => _levelDelta(delta, origin, mood: mood);
  @override
  void onReasonPaid() {
    if (_r.done) {
      unawaited(_finish());
    } else {
      unawaited(_askSlot());
    }
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => _deal.caller.id == 'je' ? KitLines.coworkerVan : KitLines.coworkerHurry;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _r.callDone || _r.slot != _deal.callBefore) return null;
    // Never in the praise window of a right move, nor over a card.
    if (_overlay != _Overlay.none || _busy || tableBusy || _introCard) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (_ended) return;
    _r.answerCall(heldCheck: held);
    unawaited(_levelDelta(held ? 5 : -10, origin, mood: held ? GuideMood.glad : GuideMood.warn));
    if (!held) {
      // Listening to him is a slip (playbook row 8): booked; the third ends the play.
      final slip = KitMistakes.rushed(_deal.callBefore);
      unawaited(bookMistake(ref, widget.ctx, slip));
      if (strike(slip)) {
        await _struckOut();
        return;
      }
    }
    if (direct) return;
    final s = _r.slot;
    final next = [if (s != null) KitLines.ask(s)];
    if (held) {
      final chain = _chain;
      unawaited(() async {
        await coworkerSnarl();
        if (!mounted || chain != _chain) return;
        await _sayChain([KitLines.callHeld, ...next], mood: GuideMood.glad);
      }());
    } else {
      unawaited(_sayChain([KitLines.callRushed, ...next], mood: GuideMood.warn));
    }
  }

  /// Tap the guide: the task on screen again, a different way each time.
  final _nudge = TaskNudge();
  void _tapGuide() {
    if (_introCard || _ended) return;
    final s = _r.slot;
    final String? line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? KitLines.tapWhy[_nudgeN++ % KitLines.tapWhy.length]
            : (s == null ? null : _nudge.next(KitLines.ask(s)));
    if (line == null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  int _nudgeN = 0;

  /// One short word; the reason is spoken in full the first time this flaw or
  /// wrong item is met, and only shown as text after that.
  Future<void> _react(KitItem item, KitOutcome o, KitChoice choice) async {
    final chain = ++_chain;
    final goodRejected = item.kind == KitKind.good && choice == KitChoice.reject;
    final word = goodRejected
        ? KitLines.lookAgain
        : (o.right ? (choice == KitChoice.reject ? KitLines.caught : _rightBag.next().shownBn) : _wrongBag.next().shownBn);
    final mood = o.right ? GuideMood.glad : GuideMood.warn;
    final reason = o.reasonBn == KitLines.rejectedGood ? '' : o.reasonBn;
    final speakReason = reason.isNotEmpty && await SpokenOnce.first('kit/${widget.pack.id}/${item.lessonKey}');
    if (!mounted || chain != _chain) return;
    await _say(word, mood: mood);
    if (!mounted || chain != _chain || reason.isEmpty) return;
    if (speakReason) {
      await _say(reason, mood: mood);
    } else {
      // Already heard once: the reason stays as text in the strip.
      ref.read(guideDirectorProvider.notifier).say(mood: mood, line: reason);
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
    final mark = _r.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_r.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_r.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _r.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    final end = !_r.passed ? KitLines.fail : (_quickBonus ? KitLines.quick : KitLines.allSet);
    await _say(end, mood: _r.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  /// The third wrong decision: the level fails and the lesson card insists.
  Future<void> _struckOut() async {
    if (_ended) return;
    _ended = true;
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    _clock.stop();
    await recordStrikeOut(widget.ctx, percent: _r.percent, runScore: _runScore);
    if (!mounted) return;
    setState(() {
      _overlay = _Overlay.none;
      _held = null;
      _busy = false;
    });
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  /// A deadly item worn: the store freezes grey and what it does on the line
  /// plays in colour; then near-miss (play again) or death (back to the ladder).
  Future<void> _deadly(KitItem item, DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _overlay = _Overlay.none;
      _held = null;
      _verdict = null;
      _shown = null;
      _deathItem = item;
      _freeze = true;
    });
    // Booked at once (as fire_choose does), so leaving during the freeze
    // cannot skip the mistakes book, the near-miss or the death.
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('kit/${widget.pack.id}/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? KitLines.deadlyWord : KitLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    if (_cardTone == MistakeTone.deadly) {
      if (_popped) return;
      _popped = true;
      unawaited(dieAndLeave());
    } else {
      widget.onRetry(_muted);
    }
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
    // The freeze plays out first (it is short); its card is the way out.
    if (_freeze && _card == null) return;
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // ---- gesture hints (how to interact, never which item) ----------------------

  /// The level waits for the player: the tray to pick from, or the inspect
  /// card's two buttons — no intro, card, deck, praise window or verdict.
  bool get _hintWaiting {
    if (_introCard || _ended || _mark != null || _freeze || _card != null || struckOut) return false;
    if (_busy || coworkerOnScreen || tableBusy) return false;
    return switch (_overlay) {
      _Overlay.none => _tray.isNotEmpty,
      _Overlay.inspect => _held != null && _verdict == null,
      _Overlay.consequence => false,
    };
  }

  /// A new waiting state resets the count of hints shown.
  Object get _hintKey => '${_r.slot?.name}|${_overlay.name}|${_held?.id}|${_tray.length}';

  /// Inspect card: glide over both buttons. Tray: glide over every card (one
  /// card left: tap it to look — the single way forward).
  HintSpec? _hint() {
    if (_overlay == _Overlay.inspect) return HintSpec.sweepOver([_rejectKey, _wearKey]);
    if (_overlay != _Overlay.none) return null;
    final rects = _trayCardRects();
    if (rects.isEmpty) return null;
    return rects.length == 1 ? HintSpec.tap(rects.single.center) : HintSpec.sweep(rects);
  }

  /// The tray's cards on screen (global), in the order they are shown.
  List<Rect> _trayCardRects() {
    final rects = <Rect>[];
    void visit(Element e) {
      if (e.widget is DoTrayCard) {
        final box = e.renderObject;
        if (box is RenderBox && box.attached && box.hasSize) rects.add(box.localToGlobal(Offset.zero) & box.size);
        return;
      }
      e.visitChildElements(visit);
    }

    _trayKey.currentContext?.visitChildElements(visit);
    return rects;
  }

  // ---- build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final size = MediaQuery.sizeOf(context);
    final screenH = size.height;
    final pad = MediaQuery.paddingOf(context);
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
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            hintAutoMiss: true,
            onClose: () => unawaited(_leave()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            progress: DoProgress(
              labels: const ['জামা', 'প্যান্ট', 'জুতো'],
              done: {for (final s in _r.worn) s.index},
              current: _r.slot?.index,
              quiet: quiet,
            ),
            layers: (context, m) => [
              Positioned.fill(
                key: const ValueKey('room'),
                child: ColorFiltered(
                  colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                  child: const CustomPaint(painter: StoreRoomPainter()),
                ),
              ),
            ],
            overlays: [
              // The man in what he wears, and the tray of kit.
              Positioned.fill(
                key: const ValueKey('figure'),
                child: ColorFiltered(
                  colorFilter: _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        Expanded(
                          child: _Figure(
                            asset: kitFigureAsset(_r.worn),
                            wave: _figureWave,
                            quiet: quiet,
                            cacheHeight: (screenH * dpr * 0.55).round(),
                          ),
                        ),
                        if (_mark == null)
                          Padding(
                            padding: EdgeInsets.only(bottom: pad.bottom),
                            child: KeyedSubtree(
                              key: _trayKey,
                              child: DoTray(
                                key: ValueKey('tray-$_wave'),
                                entries: [for (final i in _tray) DoTrayEntry(id: i.id, asset: i.asset)],
                                quiet: quiet,
                                muted: _muted,
                                onPick: (n) => _pickUp(_tray[n]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // The piece's ◆ waiting on the table (over the man).
              ...tableLayers(at: Offset(size.width / 2, size.height * 0.2), quiet: quiet),
              // The answers: level 1's cards — the reason, or the coworker choice.
              if (deckUp)
                Positioned(
                  key: const ValueKey('deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              // The guide in the corner, above the tray (or the deck).
              if (!_introCard && _overlay == _Overlay.none && _mark == null && !_freeze)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 124), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_overlay == _Overlay.inspect && _held != null)
                _InspectCard(
                  key: ValueKey('inspect-${_held!.id}'),
                  item: _held!,
                  verdict: _verdict,
                  leaving: _leaving,
                  quiet: quiet,
                  rejectKey: _rejectKey,
                  wearKey: _wearKey,
                  onDecide: (c, o) => unawaited(_decide(c, o)),
                  onTapCard: _skipDwell,
                  onTapShade: _putBack,
                  onGone: () {
                    final g = _gone;
                    if (g != null && !g.isCompleted) g.complete();
                  },
                ),
              if (_overlay == _Overlay.consequence && _shown?.wornAsset != null)
                _Consequence(key: const ValueKey('consequence'), item: _shown!, quiet: quiet, onTap: _skipDwell),
              // The deadly item on the line, in colour over the grey store.
              // It stays under the card: with reduce motion the freeze is over at
              // once, and this is where the consequence is seen.
              if (_freeze && _deathItem != null)
                Positioned.fill(
                  key: const ValueKey('kit-death'),
                  child: IgnorePointer(
                    child: KitDeathView(
                      kind: _deathItem!.flaw?.kind == KitFlawKind.nail ? KitDeath.nail : KitDeath.synthetic,
                      quiet: quiet,
                    ),
                  ),
                ),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}'),
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
              if (_introCard)
                GuideIntro(
                  line: widget.pack.introBn,
                  alarm: 'sounds/learn/rush_in.wav',
                  muted: _muted,
                  onDone: () {
                    setState(() => _introCard = false);
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
                        child: _r.passed
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: [for (final c in _r.caught) c.labelBn],
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
// Pieces (every animation plays once, then the screen is still)
// ============================================================================

/// The man in what he wears: pops in, with a warm glow, when a piece goes on.
class _Figure extends StatelessWidget {
  const _Figure({required this.asset, required this.wave, required this.quiet, required this.cacheHeight});

  final String asset;
  final int wave;
  final bool quiet;
  final int cacheHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 6, 48, 4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!quiet && wave > 0)
            TweenAnimationBuilder<double>(
              key: ValueKey('glow-$wave'),
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, _) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [SlmColors.gold300.withValues(alpha: 0.45 * v), Colors.transparent],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          AnimatedSwitcher(
            duration: quiet ? Duration.zero : const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
            ),
            child: Image.asset(asset, key: ValueKey('fig-$wave'), fit: BoxFit.contain, cacheHeight: cacheHeight),
          ),
        ],
      ),
    );
  }
}

/// Close look at one item. While deciding it is still; after a decision the
/// flaw pulses and a stamp drops — and it stays while the coach speaks — then
/// it leaves: onto the body, out of the store, or a shake back to the tray.
class _InspectCard extends StatefulWidget {
  const _InspectCard({
    super.key,
    required this.item,
    required this.verdict,
    required this.leaving,
    required this.quiet,
    required this.rejectKey,
    required this.wearKey,
    required this.onDecide,
    required this.onTapCard,
    required this.onTapShade,
    required this.onGone,
  });

  final KitItem item;
  final KitOutcome? verdict;
  final bool leaving;
  final bool quiet;

  /// The two buttons, for the gesture hint's sweep.
  final GlobalKey rejectKey;
  final GlobalKey wearKey;
  final void Function(KitChoice choice, Offset origin) onDecide;

  /// After a decision: move on now instead of waiting out the stamp.
  final VoidCallback onTapCard;

  /// Before a decision: put the item back.
  final VoidCallback onTapShade;
  final VoidCallback onGone;

  @override
  State<_InspectCard> createState() => _InspectCardState();
}

class _InspectCardState extends State<_InspectCard> with TickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _stamp = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void initState() {
    super.initState();
    if (widget.quiet) {
      _lift.value = 1;
    } else {
      _lift.forward();
    }
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onGone();
    });
  }

  @override
  void didUpdateWidget(_InspectCard old) {
    super.didUpdateWidget(old);
    if (widget.verdict != null && old.verdict == null) {
      if (widget.quiet) {
        _stamp.value = 1;
      } else {
        _stamp.forward(from: 0);
      }
    }
    if (widget.leaving && !old.leaving) {
      if (widget.quiet) {
        _exit.value = 1;
        widget.onGone();
      } else {
        _exit.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _lift.dispose();
    _stamp.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final v = widget.verdict;
    final px = (300 * MediaQuery.devicePixelRatioOf(context)).round();
    final inspectAsset = item.flaw?.inspectAsset;
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: SlmColors.ivory,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ভালো করে দেখুন', style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: Center(
              child: AspectRatio(
                aspectRatio: item.aspect,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Image(image: ResizeImage(AssetImage(inspectAsset ?? item.asset), height: px, policy: ResizeImagePolicy.fit), fit: BoxFit.fill),
                    if (item.flaw != null && inspectAsset == null) CustomPaint(painter: _FlawPainter(item.flaw!)),
                    // After the decision: the flaw pulses, so the player sees what was wrong.
                    if (v != null && item.flaw != null)
                      CustomPaint(painter: DoPulsePainter(item.flaw!.marks, _stamp)),
                    if (v != null)
                      AnimatedBuilder(
                        animation: _stamp,
                        builder: (_, _) {
                          final t = Curves.easeOutBack.transform((_stamp.value / 0.3).clamp(0.0, 1.0));
                          return Center(
                            child: Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.rotate(angle: -0.22, child: Transform.scale(scale: 2.2 - 1.2 * t, child: DoStamp(text: v.stampBn, good: v.stampBn == kitStampRight))),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (v == null)
            Row(
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: widget.rejectKey,
                    child: DoBigButton(label: 'বাদ দিন', filled: false, onTapUp: (d) => widget.onDecide(KitChoice.reject, d.globalPosition)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KeyedSubtree(
                    key: widget.wearKey,
                    child: DoBigButton(label: 'পরে নিন', filled: true, onTapUp: (d) => widget.onDecide(KitChoice.wear, d.globalPosition)),
                  ),
                ),
              ],
            )
          else
            // The why, right on the item; a tap anywhere on the card moves on.
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (v.right ? SlmColors.emerald500 : SlmColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                v.reasonBn.isNotEmpty ? v.reasonBn : (v.wears ? 'পরে নিলেন।' : KitLines.lookAgain),
                textAlign: TextAlign.center,
                style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.35),
              ),
            ),
        ],
      ),
    );

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: v == null ? widget.onTapShade : widget.onTapCard,
              child: _animatedCard(GestureDetector(onTap: v == null ? null : widget.onTapCard, child: card)),
            ),
          ),
          // The coach talks above the shade, under the card — not hidden behind it.
          if (!widget.leaving) const Positioned(left: 0, right: 0, bottom: 8, child: DoCoachStrip()),
        ],
      ),
    );
  }

  Widget _animatedCard(Widget card) {
    final v = widget.verdict;
    return AnimatedBuilder(
        animation: Listenable.merge([_lift, _exit]),
        child: card,
        builder: (_, child) {
          final lift = Curves.easeOutBack.transform(_lift.value);
          final e = Curves.easeInCubic.transform(_exit.value);
          var dx = 0.0, dy = 0.0, rot = 0.0, scale = 0.7 + 0.3 * lift;
          var fade = 1.0;
          if (v != null && _exit.value > 0) {
            if (v.wears) {
              dy = -220 * e; // up onto the body
              scale *= 1 - 0.8 * e;
              fade = 1 - e;
            } else if (v.leavesTray) {
              dx = 420 * e; // tossed out of the store
              rot = 0.6 * e;
              fade = 1 - e;
            } else {
              dx = math.sin(_exit.value * math.pi * 6) * 14 * (1 - _exit.value); // shake back to the tray
              scale *= 1 - 0.3 * e;
              fade = 1 - e;
            }
          }
          return ColoredBox(
            color: Color.fromRGBO(5, 10, 22, 0.8 * (1 - e)),
            child: Align(
              alignment: const Alignment(0, -0.35),
              child: Opacity(
                opacity: (fade * _lift.value).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(dx, dy + 40 * (1 - lift)),
                  child: Transform.rotate(angle: rot, child: Transform.scale(scale: scale, child: child)),
                ),
              ),
            ),
          );
        },
      );
  }
}

/// Placeholder defect marks until photos of damaged kit exist.
class _FlawPainter extends CustomPainter {
  _FlawPainter(this.flaw);
  final KitFlaw flaw;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (final m in flaw.marks) {
      final c = Offset(m.dx * w, m.dy * h);
      switch (flaw.kind) {
        case KitFlawKind.grease:
        case KitFlawKind.oil:
          final r = w * (flaw.kind == KitFlawKind.oil ? 0.12 : 0.07);
          canvas.drawOval(Rect.fromCenter(center: c, width: r * 2.2, height: r * 1.5), Paint()..color = const Color(0xB33B2A12));
          canvas.drawOval(Rect.fromCenter(center: c.translate(r * 0.4, r * 0.3), width: r, height: r * 0.7), Paint()..color = const Color(0xCC2A1D0B));
        case KitFlawKind.burn:
          final r = w * 0.055;
          canvas.drawCircle(c, r * 1.6, Paint()..color = const Color(0x99442A10));
          canvas.drawCircle(c, r, Paint()..color = const Color(0xFF120A04));
          canvas.drawCircle(
            c,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFFB8641E),
          );
        case KitFlawKind.tear:
          final s = w * 0.12;
          final path = Path()..moveTo(c.dx - s * 0.6, c.dy - s);
          for (var i = 0; i < 6; i++) {
            path.lineTo(c.dx + (i.isEven ? s * 0.5 : -s * 0.3), c.dy - s + i * s * 0.4);
          }
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5
              ..color = const Color(0xFFE8E2D0),
          );
        case KitFlawKind.nail:
          final s = h * 0.16;
          final p = Paint()
            ..color = const Color(0xFF8E959E)
            ..strokeWidth = s * 0.16
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(c, c.translate(-s * 0.15, s * 0.75), p);
          canvas.drawCircle(c, s * 0.18, Paint()..color = const Color(0xFFB6BCC4));
        case KitFlawKind.crack:
          final s = w * 0.16;
          final path = Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(c.dx + s * 0.3, c.dy + h * 0.02)
            ..lineTo(c.dx + s * 0.55, c.dy - h * 0.015)
            ..lineTo(c.dx + s * 0.85, c.dy + h * 0.025)
            ..lineTo(c.dx + s * 1.1, c.dy);
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = const Color(0xFFF2EBDD),
          );
      }
    }
  }

  @override
  bool shouldRepaint(_FlawPainter old) => old.flaw != flaw;
}

/// "What would happen": the figure wearing the wrong item, with a shake.
class _Consequence extends StatelessWidget {
  const _Consequence({super.key, required this.item, required this.quiet, required this.onTap});
  final KitItem item;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = (420 * MediaQuery.devicePixelRatioOf(context)).round();
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: const Color(0xCC1A0508),
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: quiet ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 520),
                  builder: (_, t, child) => Transform.translate(
                    offset: Offset(math.sin(t * math.pi * 7) * 14 * (1 - t), 0),
                    child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                  ),
                  child: SizedBox(
                    height: 360,
                    child: Image(image: ResizeImage(AssetImage(item.wornAsset!), height: h, policy: ResizeImagePolicy.fit), fit: BoxFit.contain),
                  ),
                ),
              ),
              const Positioned(left: 0, right: 0, bottom: 8, child: DoCoachStrip()),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// The deadly consequence (in colour over the frozen store)
// ============================================================================

/// Which deadly item was worn.
enum KitDeath { synthetic, nail }

/// What the deadly item does on the line, played once over the grey store:
/// a synthetic shirt — an arc flash at a joint in front of him, its heat
/// melting the cloth onto the body (lesson 1.1, point 1); a nail in the sole — a fallen live wire at
/// the hand and the current running down through the body and out through
/// the nail into the ground (lesson 1.1, point 3). It ends on a still frame.
class KitDeathView extends StatelessWidget {
  const KitDeathView({super.key, required this.kind, required this.quiet});

  final KitDeath kind;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth - 40, 340.0);
        final h = math.min(w * 1.25, box.maxHeight * 0.66);
        final g = _DeathGeo(Size(w, h));
        final fig = g.figure;
        final still = Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DeathBackPainter(g))),
            Positioned.fromRect(
              rect: fig,
              child: Image(
                image: ResizeImage(
                  AssetImage(kind == KitDeath.synthetic ? '$_d/worn_poly.webp' : '$_d/all.webp'),
                  height: (fig.height * dpr).round(),
                  policy: ResizeImagePolicy.fit,
                ),
                fit: BoxFit.fill,
              ),
            ),
          ],
        );
        return Align(
          alignment: const Alignment(0, -0.2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1800),
            child: still,
            builder: (_, t, child) {
              final pop = (t * 6).clamp(0.0, 1.0);
              final shake = quiet ? 0.0 : math.sin(t * math.pi * 14) * 6 * (1 - t) * (t < 0.5 ? 1 : 0);
              return Opacity(
                opacity: pop,
                child: Transform.translate(
                  offset: Offset(shake, 0),
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * pop,
                    child: Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SlmColors.danger, width: 2.5),
                        boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 10))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Positioned.fill(child: child!),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: kind == KitDeath.synthetic ? _ArcFlashPainter(g, t) : _NailPathPainter(g, t),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Where the figure stands inside the panel; [at] maps a point of the dress
/// art (0–1 on each axis, 864×1152 pictures) into the panel.
class _DeathGeo {
  _DeathGeo(this.s) {
    var fh = s.height * 0.9;
    var fw = fh * 0.75;
    if (fw > s.width * 0.92) {
      fw = s.width * 0.92;
      fh = fw / 0.75;
    }
    figure = Rect.fromLTWH((s.width - fw) / 2, s.height * 0.07, fw, fh);
  }

  final Size s;
  late final Rect figure;

  Offset at(double x, double y) => Offset(figure.left + x * figure.width, figure.top + y * figure.height);
  double get groundY => at(0, 0.955).dy;
}

/// Dusk sky after the storm and the ground he stands on.
class _DeathBackPainter extends CustomPainter {
  _DeathBackPainter(this.g);
  final _DeathGeo g;

  @override
  void paint(Canvas c, Size s) {
    final gy = g.groundY;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2440), Color(0xFF3B4A66), Color(0xFF59627A)],
        ).createShader(Offset.zero & s),
    );
    final ground = Rect.fromLTRB(0, gy - 6, s.width, s.height);
    c.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B5236), Color(0xFF3E2E1E)],
        ).createShader(ground),
    );
    c.drawLine(
      Offset(0, gy - 6),
      Offset(s.width, gy - 6),
      Paint()
        ..color = const Color(0xFF85694A)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_DeathBackPainter old) => old.g.s != g.s;
}

/// A jagged line through [pts] (fixed zig-zag, so every play looks the same).
Path _jagged(List<Offset> pts, double amp) {
  const kinks = [0.0, 0.8, -0.6, 1.0, -0.9, 0.5, -0.4];
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  var k = 0;
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1];
    final b = pts[i];
    final d = b - a;
    final len = d.distance;
    if (len == 0) continue;
    final n = Offset(-d.dy / len, d.dx / len);
    final steps = math.max(2, (len / 14).round());
    for (var j = 1; j <= steps; j++) {
      final q = a + d * (j / steps);
      final off = j == steps ? 0.0 : kinks[k++ % kinks.length] * amp;
      p.lineTo(q.dx + n.dx * off, q.dy + n.dy * off);
    }
  }
  return p;
}

/// The part of [path] from its start to [u] (0–1) of its length.
Path _upTo(Path path, double u) {
  final out = Path();
  for (final m in path.computeMetrics()) {
    out.addPath(m.extractPath(0, m.length * u.clamp(0.0, 1.0)), Offset.zero);
  }
  return out;
}

void _glowStroke(Canvas c, Path p, {required Color glow, required Color core, double width = 3}) {
  c.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  c.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = core,
  );
}

/// Synthetic shirt: an arc flash at a joint on the line in front of him. No
/// current goes into him: the flash's light and heat wash over the shirt,
/// and the synthetic cloth shrivels and melts onto the body (lesson 1.1,
/// point 1: "লাইনে সামান্য স্পার্ক বা আর্কিং ফ্ল্যাশ হলেই সিন্থেটিক কাপড় …
/// গলে সোজা চামড়ায় সেঁটে যায়").
class _ArcFlashPainter extends CustomPainter {
  _ArcFlashPainter(this.g, this.t);
  final _DeathGeo g;
  final double t;

  // The shirt in worn_poly.webp (0–1 of the picture): torso and both sleeves.
  static const _torso = [
    (0.445, 0.215), (0.50, 0.255), (0.555, 0.215), (0.64, 0.235), (0.618, 0.37), (0.622, 0.505), //
    (0.62, 0.522), (0.50, 0.528), (0.385, 0.522), (0.38, 0.505), (0.385, 0.37), (0.36, 0.235),
  ];
  static const _sleeveL = [
    (0.36, 0.235), (0.395, 0.30), (0.392, 0.37), (0.378, 0.43), (0.372, 0.515), //
    (0.322, 0.518), (0.316, 0.45), (0.326, 0.33), (0.338, 0.26),
  ];
  static const _sleeveR = [
    (0.64, 0.235), (0.605, 0.30), (0.612, 0.37), (0.626, 0.43), (0.636, 0.515), //
    (0.69, 0.518), (0.692, 0.45), (0.68, 0.33), (0.664, 0.26),
  ];

  // The melt (x, y, radius as a share of the figure's width): overlapping
  // blobs on the side that faced the flash, and a few spots beyond.
  static const _melt = [
    (0.358, 0.305, 0.060),
    (0.412, 0.292, 0.058),
    (0.446, 0.338, 0.060),
    (0.366, 0.372, 0.052),
    (0.418, 0.398, 0.050),
    (0.520, 0.372, 0.026),
    (0.350, 0.452, 0.022),
    (0.572, 0.292, 0.020),
  ];

  // Raw burns inside the melt, where it fused to the skin.
  static const _burns = [
    (0.398, 0.302, 0.022),
    (0.448, 0.345, 0.018),
    (0.364, 0.372, 0.014),
    (0.520, 0.372, 0.009),
  ];

  // Fixed wobble of a patch's edge (every play looks the same).
  static const _edge = [1.0, 0.82, 1.1, 0.92, 1.04, 0.76, 1.08, 0.96, 0.86, 1.02];

  Path _poly(List<(double, double)> pts) {
    final p = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = g.at(pts[i].$1, pts[i].$2);
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    return p..close();
  }

  /// A smooth, irregular blob through wobbled points (Catmull-Rom curves).
  static Path _blob(Offset c, double r, int seed) {
    final n = _edge.length;
    final pts = [
      for (var k = 0; k < n; k++)
        c +
            Offset(math.cos(k * 2 * math.pi / n + seed * 1.3), math.sin(k * 2 * math.pi / n + seed * 1.3) * 0.85) *
                (r * _edge[(k + seed * 3) % n]),
    ];
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas c, Size s) {
    final fw = g.figure.width;
    // The line at shoulder height, ending in a joint just in front of him.
    final lineY = g.at(0, 0.27).dy;
    final joint = Offset(g.at(0.21, 0).dx, lineY);
    c.drawLine(
      Offset(-4, lineY),
      joint,
      Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2A2E33),
    );
    c.drawLine(
      Offset(-4, lineY),
      joint,
      Paint()
        ..strokeWidth = 2
        ..color = const Color(0xFF9AA3AB),
    );
    final clamp = RRect.fromRectAndRadius(Rect.fromCenter(center: joint, width: 16, height: 14), const Radius.circular(3));
    c.drawRRect(clamp, Paint()..color = const Color(0xFF7D848C));
    c.drawRRect(
      clamp,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF2A2E33),
    );

    // The flash at the joint: blinding at once, then gone.
    final rise = Curves.easeOut.transform((t / 0.14).clamp(0.0, 1.0));
    final settle = Curves.easeIn.transform(((t - 0.14) / 0.5).clamp(0.0, 1.0));
    final white = rise * (1 - settle);
    // The whole scene lights up for a moment.
    if (white > 0.01) {
      c.drawRect(Offset.zero & s, Paint()..color = Color.fromRGBO(255, 236, 190, 0.32 * white));
    }
    final r = fw * (0.16 + 0.3 * rise) * (1 - 0.55 * settle);
    c.drawCircle(
      joint,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(255, 255, 255, white),
            Color.fromRGBO(255, 232, 140, 0.9 * white),
            Color.fromRGBO(255, 130, 30, 0.45 * white),
            const Color(0x00FF6A00),
          ],
          stops: const [0, 0.2, 0.55, 1],
        ).createShader(Rect.fromCircle(center: joint, radius: r)),
    );
    if (white > 0.02) {
      final ray = Paint()
        ..color = Color.fromRGBO(255, 244, 200, 0.9 * white)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 12; i++) {
        final ang = i * math.pi / 6 + 0.25;
        final dir = Offset(math.cos(ang), math.sin(ang));
        c.drawLine(joint + dir * (r * 0.3), joint + dir * (r * (0.7 + 0.3 * (i.isEven ? 1 : 0.55))), ray);
      }
    }

    // Heat over the shirt only: the light washes over it and the melt stays on it.
    final shirt = Path()
      ..addPath(_poly(_torso), Offset.zero)
      ..addPath(_poly(_sleeveL), Offset.zero)
      ..addPath(_poly(_sleeveR), Offset.zero);
    c.save();
    c.clipPath(shirt);
    final heat = rise * (1 - 0.8 * settle);
    final reach = fw * 0.75;
    c.drawCircle(
      joint,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.fromRGBO(255, 190, 90, 0.7 * heat), Color.fromRGBO(255, 120, 30, 0.25 * heat), const Color(0x00FF7A20)],
          stops: const [0.25, 0.65, 1],
        ).createShader(Rect.fromCircle(center: joint, radius: reach)),
    );

    // The cloth shrivels back from the heat, goes glossy and sticks: one
    // puckered, shiny melt on the side that faced the flash, a few spots
    // beyond it, and raw burns where it fused to the skin.
    final m = Curves.easeOut.transform(((t - 0.16) / 0.74).clamp(0.0, 1.0));
    if (m > 0) {
      final grow = 0.35 + 0.65 * m;
      var melt = Path();
      for (var i = 0; i < _melt.length; i++) {
        final (x, y, rr) = _melt[i];
        final b = _blob(g.at(x, y), fw * rr * grow, i);
        melt = i == 0 ? b : Path.combine(PathOperation.union, melt, b);
      }
      final box = melt.getBounds();
      // Scorched cloth round the melt.
      c.drawPath(
        melt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = fw * 0.05
          ..color = Color.fromRGBO(46, 20, 12, 0.5 * m)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fw * 0.02),
      );
      // The shrivelled cloth: darker, glossy.
      c.drawPath(
        melt,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFF26368A), Color(0xFF131B58), Color(0xFF080C30)],
            stops: const [0, 0.5, 1],
          ).createShader(box),
      );
      // A curled rim: a dark lip outside, a lit edge just inside.
      c.drawPath(
        melt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xE6060820),
      );
      c.save();
      c.clipPath(melt);
      c.drawPath(
        melt.shift(const Offset(1.4, 1.8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round
          ..color = Color.fromRGBO(120, 145, 240, 0.7 * m),
      );
      c.restore();
      // Puckers: short creases that follow the melt's edge.
      final crease = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, fw * 0.004)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCC050824);
      final shine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, fw * 0.003)
        ..strokeCap = StrokeCap.round
        ..color = Color.fromRGBO(170, 190, 255, 0.6 * m);
      for (var i = 0; i < _melt.length; i++) {
        final (x, y, rr) = _melt[i];
        final p = g.at(x, y);
        final r = fw * rr * grow;
        for (var k = 0; k < 3; k++) {
          final rad = r * (0.78 - 0.2 * k);
          final start = i * 1.9 + k * 2.3;
          final sweep = 0.9 + 0.35 * ((i + k) % 3);
          final rect = Rect.fromCenter(center: p, width: rad * 2, height: rad * 1.7);
          c.drawArc(rect, start, sweep, false, crease);
          c.drawArc(rect.translate(-0.8, -1.2), start + 0.15, sweep * 0.6, false, shine);
        }
      }
      // A soft sheen across the melted plastic.
      c.drawOval(
        Rect.fromCenter(center: box.topLeft + Offset(box.width * 0.42, box.height * 0.3), width: box.width * 0.5, height: box.height * 0.16),
        Paint()
          ..color = Color.fromRGBO(200, 214, 255, 0.22 * m)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fw * 0.01),
      );
      // Raw burns where it fused to the skin, each with a dark bead of melt.
      for (var i = 0; i < _burns.length; i++) {
        final (x, y, rr) = _burns[i];
        final p = g.at(x, y);
        final r = fw * rr * grow;
        final burn = _blob(p, r, i + 4);
        c.drawPath(
          burn,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.2, -0.3),
              colors: const [Color(0xFFC0533C), Color(0xFF8E2A1E), Color(0xFF4A120D)],
              stops: const [0, 0.55, 1],
            ).createShader(Rect.fromCircle(center: p, radius: r * 1.1)),
        );
        c.drawPath(
          burn,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.6, r * 0.32)
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF080B2E),
        );
        c.drawArc(
          Rect.fromCircle(center: p, radius: r * 1.05),
          math.pi * 1.1,
          math.pi * 0.5,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, r * 0.1)
            ..strokeCap = StrokeCap.round
            ..color = Color.fromRGBO(200, 214, 255, 0.7 * m),
        );
        c.drawCircle(p + Offset(-r * 0.25, -r * 0.2), r * 0.14, Paint()..color = Color.fromRGBO(255, 220, 205, 0.55 * m));
      }
      // Still hot at the edge, then it cools.
      final hot = 1 - 0.7 * m;
      c.drawPath(
        melt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = Color.fromRGBO(255, 110, 30, 0.6 * hot + 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ArcFlashPainter old) => old.t != t || old.g.s != g.s;
}

/// A nail in the sole: the fallen live wire at his hand, the current down
/// through the body and out through the nail into the ground.
class _NailPathPainter extends CustomPainter {
  _NailPathPainter(this.g, this.t);
  final _DeathGeo g;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final hand = g.at(0.665, 0.565);
    final nail = g.at(0.40, 0.945);
    final gy = g.groundY;

    // The fallen conductor, from up out of the picture down to his hand.
    final wire = Path()
      ..moveTo(s.width + 8, -8)
      ..quadraticBezierTo(s.width * 0.95, hand.dy * 0.75, hand.dx + 4, hand.dy - 2);
    c.drawPath(
      wire,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2A2E33),
    );
    c.drawPath(
      wire,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF9AA3AB),
    );

    // Contact flash at the hand.
    final hit = (t / 0.15).clamp(0.0, 1.0);
    final hr = 10 + 16 * hit;
    c.drawCircle(
      hand,
      hr,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.fromRGBO(255, 255, 255, hit), Color.fromRGBO(255, 230, 90, 0.7 * hit), const Color(0x00FFC400)],
        ).createShader(Rect.fromCircle(center: hand, radius: hr)),
    );

    // The current's path through the body to the nail.
    final body = _jagged([
      hand,
      g.at(0.665, 0.45),
      g.at(0.635, 0.27),
      g.at(0.55, 0.33),
      g.at(0.48, 0.50),
      g.at(0.43, 0.70),
      g.at(0.41, 0.86),
      nail,
    ], 4);
    final run = Curves.easeIn.transform(((t - 0.1) / 0.5).clamp(0.0, 1.0));
    if (run > 0) {
      _glowStroke(c, _upTo(body, run), glow: const Color(0xB3FFD23C), core: const Color(0xFFFFFBE0), width: 3);
    }

    // The nail through the sole.
    final nailPaint = Paint()
      ..color = const Color(0xFFB6BCC4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(nail.translate(0, -6), nail.translate(-1, 8), nailPaint);
    c.drawCircle(nail.translate(0, -6), 4, Paint()..color = const Color(0xFFD5DADF));

    // Out through the nail into the ground.
    final out = ((t - 0.58) / 0.42).clamp(0.0, 1.0);
    if (out <= 0) return;
    final ground = Offset(nail.dx, gy + 4);
    c.drawOval(
      Rect.fromCenter(center: ground, width: 90 * out, height: 22 * out),
      Paint()
        ..color = Color.fromRGBO(255, 170, 40, 0.55 * out)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final spark = Paint()
      ..color = Color.fromRGBO(255, 230, 120, out)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final ang = math.pi * (0.05 + 0.9 * i / 8); // fanned out below the sole
      final dir = Offset(math.cos(ang), math.sin(ang) * 0.6);
      final len = (18 + (i.isEven ? 14 : 6)) * out;
      c.drawLine(nail + dir * 6, nail + dir * (6 + len), spark);
    }
    _glowStroke(c, _jagged([nail.translate(-1, 8), ground.translate(-6, 10)], 3), glow: const Color(0xB3FFD23C), core: const Color(0xFFFFFBE0), width: 2.4);
  }

  @override
  bool shouldRepaint(_NailPathPainter old) => old.t != t || old.g.s != g.s;
}
