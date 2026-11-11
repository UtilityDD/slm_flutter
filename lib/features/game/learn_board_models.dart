// Shared Learn choice-board models (PickGear + MythRival spine).
// Modes beyond PickGear (OrderSteps, MeasureRule, …) reuse the same pending/Why flow later.

import 'learn_board_pack13.dart';
import 'learn_board_pack14.dart';
import 'learn_board_pack15.dart';
import 'learn_board_pack16.dart';
import 'learn_board_pack17.dart';
import 'learn_board_pack18.dart';
import 'learn_board_pack19.dart';
import 'learn_board_pack110.dart';
import 'learn_board_pack29.dart';
import 'learn_board_pack28.dart';
import 'learn_board_pack27.dart';
import 'learn_board_pack24.dart';
import 'learn_board_pack25.dart';
import 'learn_board_pack26.dart';
import 'learn_board_pack23.dart';
import 'learn_board_pack22.dart';
import 'learn_board_pack21.dart';

export 'learn_board_pack13.dart' show learnBoardPack13, PoleBoardLines;
export 'learn_board_pack14.dart' show learnBoardPack14;
export 'learn_board_pack15.dart' show learnBoardPack15, RodBoardLines;
export 'learn_board_pack16.dart' show learnBoardPack16, PtwBoardLines;
export 'learn_board_pack17.dart' show learnBoardPack17, AidBoardLines;
export 'learn_board_pack18.dart' show learnBoardPack18, FireBoardLines;
export 'learn_board_pack19.dart' show learnBoardPack19, StormBoardLines;
export 'learn_board_pack110.dart' show learnBoardPack110, ScanBoardLines;
export 'learn_board_pack29.dart' show learnBoardPack29, HydraulicBoardLines;
export 'learn_board_pack28.dart' show learnBoardPack28, M2Board28Lines;
export 'learn_board_pack27.dart' show learnBoardPack27, MeggerBoardLines;
export 'learn_board_pack24.dart' show learnBoardPack24, ClampBoardLines;
export 'learn_board_pack25.dart' show learnBoardPack25;
export 'learn_board_pack26.dart' show learnBoardPack26, SkinBoardLines;
export 'learn_board_pack23.dart' show learnBoardPack23, CrimpBoardLines;
export 'learn_board_pack22.dart' show learnBoardPack22, MeterBoardLines;
export 'learn_board_pack21.dart' show learnBoardPack21, ToolboxBoardLines;

enum LearnBoardMode { pickGear, mythRival }

/// Anything dealt onto a board: an item card or a "why" chip.
abstract interface class LearnPick {
  String get id;
  bool get correct;
}

class LearnBoardOption implements LearnPick {
  const LearnBoardOption({
    required this.id,
    required this.labelBn,
    required this.asset,
    required this.correct,
    this.rejectBn = '',
    this.scene = false,
  });

  @override
  final String id;
  final String labelBn;
  final String asset;
  @override
  final bool correct;

  /// Spoken / shown when this trap is tapped.
  final String rejectBn;

  /// A whole scene (e.g. a worker under a wire), shown edge to edge in the
  /// card; false = an object on the pedestal.
  final bool scene;
}

class LearnWhyChip implements LearnPick {
  const LearnWhyChip({required this.id, required this.textBn, required this.correct});

  @override
  final String id;
  final String textBn;
  @override
  final bool correct;
}

class LearnBoardSlot {
  const LearnBoardSlot({
    required this.id,
    required this.promptBn,
    required this.options,
    required this.whyChips,
    this.wearAsset = '',
    this.pendingPoints = 15,
    this.cards = 4,
    this.whyCards = 3,
  });

  final String id;
  final String promptBn;

  /// Item pool: every run deals one safe item and [cards] − 1 traps from it;
  /// unseen traps swap in after a mistake.
  final List<LearnBoardOption> options;

  /// Reason pool, dealt the same way ([whyCards] at a time).
  final List<LearnWhyChip> whyChips;
  final int cards;
  final int whyCards;

  /// Optional body-layer asset shown on the silhouette when locked.
  final String wearAsset;
  final int pendingPoints;
}

class LearnMythBeat {
  const LearnMythBeat({
    required this.rivalLineBn,
    required this.believeNoIsCorrect,
    required this.whyChips,
    this.pendingPoints = 15,
    this.bodyAsset = 'assets/duty_slip/dress/myth_rival_bad.webp',
    this.wornAssets = const [],
    this.dangerHints = const [],
    this.tauntBn = 'আরে! আমাদের বাপ-দাদারা তো এসব দিয়েই সারা জীবন কাজ করে গেল!',
    this.stingBn = 'শুনলেন তো ওর কথা? সত্যি কি ওর এই বিপজ্জনক কথায় কান দেবেন?',
    this.flipStingBn = 'ও তো নিজের আলসেমিতে শর্টকাট মারছে! ওর কথায় ভুলবেন, না নিজের জীবন বাঁচাবেন?',
    this.exitBn = 'যত্তসব নতুন নিয়ম! আমি চললাম…',
  });

  final String rivalLineBn;

  /// True when the correct answer to "বিশ্বাস করেন?" is না.
  final bool believeNoIsCorrect;
  final List<LearnWhyChip> whyChips;
  final int pendingPoints;

  /// Full-body aggressive rival WebP (badly dressed).
  final String bodyAsset;

  /// Optional wrong-kit slap layers (legacy); prefer dangerHints alone.
  final List<String> wornAssets;

  /// Short Bangla danger ticks (optional).
  final List<String> dangerHints;

  /// Cocky burst line as rival storms in.
  final String tauntBn;

  /// Coach sting after rival exits, before Believe CTAs.
  final String stingBn;

  /// The same question turned round ("is he wrong?"), asked on about half the
  /// runs so হ্যাঁ / না must be read, never learnt as "always না".
  final String flipStingBn;

  /// Rival parting snarl while sliding off.
  final String exitBn;
}

class LearnBoardPack {
  const LearnBoardPack({
    required this.lessonId,
    required this.titleBn,
    required this.badgeBn,
    required this.slots,
    required this.myth,
    this.introBn = '',
    this.earnedBn = '',
    this.clearBonus = 20,
  });

  final String lessonId;
  final String titleBn;
  final String badgeBn;
  final String introBn;

  /// Spoken when the level is passed. Empty → the kit line from [LearnCoachLines].
  final String earnedBn;

  final List<LearnBoardSlot> slots;
  final LearnMythBeat myth;
  final int clearBonus;
}

LearnBoardPack? learnBoardPackFor(String lessonId) {
  if (lessonId == '1.1') return learnBoardPack11;
  if (lessonId == '1.2') return learnBoardPack12;
  if (lessonId == '1.3') return learnBoardPack13;
  if (lessonId == '1.4') return learnBoardPack14;
  if (lessonId == '1.5') return learnBoardPack15;
  if (lessonId == '1.6') return learnBoardPack16;
  if (lessonId == '1.7') return learnBoardPack17;
  if (lessonId == '1.8') return learnBoardPack18;
  if (lessonId == '1.9') return learnBoardPack19;
  if (lessonId == '1.10') return learnBoardPack110;
  if (lessonId == '2.9') return learnBoardPack29;
  if (lessonId == '2.8') return learnBoardPack28;
  if (lessonId == '2.7') return learnBoardPack27;
  if (lessonId == '2.4') return learnBoardPack24;
  if (lessonId == '2.5') return learnBoardPack25;
  if (lessonId == '2.6') return learnBoardPack26;
  if (lessonId == '2.3') return learnBoardPack23;
  if (lessonId == '2.2') return learnBoardPack22;
  if (lessonId == '2.1') return learnBoardPack21;
  return null;
}

/// Prototype pack — Module 1 Lesson 1.1 (সুরক্ষা কবচ).
const learnBoardPack11 = LearnBoardPack(
  lessonId: '1.1',
  titleBn: 'প্রথম দিনের ইউনিফর্ম ও পিপিই',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'আজ প্রথম দিন। সঠিক পোশাক বেছে নিন—ভুল মানে বিপদ।',
  slots: [
    LearnBoardSlot(
      id: 'shirt',
      promptBn: 'সঠিক জিনিস বেছে নিন',
      wearAsset: 'assets/duty_slip/dress/tray_shirt.webp',
      options: [
        LearnBoardOption(
          id: 'shirt',
          labelBn: 'সুতি ফুল-হাতা',
          asset: 'assets/duty_slip/dress/tray_shirt.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'poly',
          labelBn: 'পলিয়েস্টার',
          asset: 'assets/duty_slip/dress/tray_poly.webp',
          correct: false,
          rejectBn: 'আর্ক ফ্ল্যাশে পলিয়েস্টার গলে চামড়ায় আটকে যায়।',
        ),
        LearnBoardOption(
          id: 'fatua',
          labelBn: 'ফতুয়া',
          asset: 'assets/duty_slip/dress/tray_fatua.webp',
          correct: false,
          rejectBn: 'ঢিলে পোশাক তারে জড়িয়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'halftee',
          labelBn: 'হাফ-হাতা',
          asset: 'assets/duty_slip/dress/tray_halftee.webp',
          correct: false,
          rejectBn: 'হাত খোলা থাকলে স্পার্কে চামড়া পুড়ে যায়।',
        ),
        LearnBoardOption(
          id: 'fr_suit',
          labelBn: 'FR কভারঅল',
          asset: 'assets/safety/library/ppe/Arc_Fire_Resistant_Full_Body_Vest.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'fr_suit2',
          labelBn: 'FR কভারঅল',
          asset: 'assets/safety/library/ppe/Arc_Fire_Resistant_Full_Body_Vest_2.webp',
          correct: true,
        ),
      ],
      whyChips: [
        LearnWhyChip(
          id: 'w1',
          textBn: 'সুতি/FR গলে চামড়ায় সেঁটে যায় না',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w2',
          textBn: 'গরমে পলিয়েস্টারই সবচেয়ে আরাম',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w3',
          textBn: 'মেটাল জিপার থাকলে আরও নিরাপদ',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w4',
          textBn: 'পুরো হাত ঢাকা থাকে—স্পার্কে চামড়া বাঁচে',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w5',
          textBn: 'রঙিন জামা দূর থেকে দেখা যায়, তাই নিরাপদ',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w6',
          textBn: 'ঢিলে জামায় পোলে ওঠা সহজ',
          correct: false,
        ),
      ],
    ),
    LearnBoardSlot(
      id: 'helmet',
      promptBn: 'সঠিক জিনিস বেছে নিন',
      wearAsset: 'assets/duty_slip/dress/tray_elec_helmet.webp',
      options: [
        LearnBoardOption(
          id: 'helmet',
          labelBn: 'ক্লাস-ই হেলমেট',
          asset: 'assets/duty_slip/dress/tray_elec_helmet.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'vent',
          labelBn: 'ভেন্টেড হেলমেট',
          asset: 'assets/duty_slip/dress/tray_vent_helmet.webp',
          correct: false,
          rejectBn: 'গর্ত দিয়ে স্পার্ক বা জল ঢুকে মাথায় বিদ্যুৎ নামতে পারে।',
        ),
        LearnBoardOption(
          id: 'road',
          labelBn: 'ট্রাফিক হেলমেট',
          asset: 'assets/duty_slip/dress/tray_road_helmet.webp',
          correct: false,
          rejectBn: 'রাস্তার হেলমেট লাইনের শক আটকায় না।',
        ),
        LearnBoardOption(
          id: 'gamcha',
          labelBn: 'মাথায় গামছা',
          asset: 'assets/duty_slip/dress/tray_gamcha.webp',
          correct: false,
          rejectBn: 'গামছা আঘাতও আটকায় না, শকও না।',
        ),
        LearnBoardOption(
          id: 'helmet2',
          labelBn: 'ক্লাস-ই হেলমেট',
          asset: 'assets/safety/library/ppe/Safety_Helmet_2.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'helmet3',
          labelBn: 'ক্লাস-ই হেলমেট',
          asset: 'assets/safety/library/ppe/Safety_Helmet.webp',
          correct: true,
        ),
      ],
      whyChips: [
        LearnWhyChip(
          id: 'w1',
          textBn: 'ছিদ্রহীন ডাই-ইলেকট্রিক শেল দরকার',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w2',
          textBn: 'ভেন্ট থাকলে গরমে নিরাপদ',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w3',
          textBn: 'বাইক হেলমেটই যথেষ্ট',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w4',
          textBn: 'শক্ত শেল আঘাত আর শক—দুটোই ঠেকায়',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w5',
          textBn: 'হালকা হলেই হেলমেট ভালো',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w6',
          textBn: 'গামছা বাঁধলেও মাথা বাঁচে',
          correct: false,
        ),
      ],
    ),
    LearnBoardSlot(
      id: 'boots',
      promptBn: 'সঠিক জিনিস বেছে নিন',
      wearAsset: 'assets/duty_slip/dress/tray_boot.webp',
      options: [
        LearnBoardOption(
          id: 'boot',
          labelBn: 'EH সেফটি বুট',
          asset: 'assets/duty_slip/dress/tray_boot.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'slip',
          labelBn: 'চপ্পল',
          asset: 'assets/duty_slip/dress/tray_slipper.webp',
          correct: false,
          rejectBn: 'চপ্পলে ইনসুলেশন নেই—মইয়ে পা হড়কায়।',
        ),
        LearnBoardOption(
          id: 'normal',
          labelBn: 'সাধারণ জুতো',
          asset: 'assets/duty_slip/dress/tray_normalshoe.webp',
          correct: false,
          rejectBn: 'সাধারণ সোলে বৈদ্যুতিক সুরক্ষা নেই।',
        ),
        LearnBoardOption(
          id: 'lineboot',
          labelBn: 'লাইনম্যান EH বুট',
          asset: 'assets/safety/library/ppe/Lineman_Boot_2.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'lineboot3',
          labelBn: 'লাইনম্যান সেফটি বুট',
          asset: 'assets/safety/library/ppe/Lineman_Boot_3.webp',
          correct: true,
        ),
      ],
      cards: 3,
      whyChips: [
        LearnWhyChip(
          id: 'w1',
          textBn: 'মোটা রাবার সোল কারেন্টের আর্থ পথ বন্ধ করে',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w2',
          textBn: 'হালকা চপ্পল মইয়ে দ্রুত ওঠায়',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w3',
          textBn: 'মেটাল পেরেক গেঁথে থাকলেও চলবে',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w4',
          textBn: 'ইনসুলেটেড সোল পায়ের পথে শক আটকায়',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w5',
          textBn: 'খালি পায়ে মাটিতে গ্রিপ ভালো',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w6',
          textBn: 'জুতো ভিজে গেলেও সমস্যা নেই',
          correct: false,
        ),
      ],
    ),
    LearnBoardSlot(
      id: 'gloves',
      promptBn: 'সঠিক জিনিস বেছে নিন',
      wearAsset: 'assets/duty_slip/dress/tray_rubber_gloves.webp',
      options: [
        LearnBoardOption(
          id: 'rubber',
          labelBn: 'রাবার গ্লাভস',
          asset: 'assets/duty_slip/dress/tray_rubber_gloves.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'ভেজা গ্লাভস',
          asset: 'assets/duty_slip/dress/tray_wet_gloves.webp',
          correct: false,
          rejectBn: 'জল দিয়ে বিদ্যুৎ শরীরে নেমে আসে।',
        ),
        LearnBoardOption(
          id: 'hole',
          labelBn: 'ফুটো গ্লাভস',
          asset: 'assets/duty_slip/dress/tray_hole_gloves.webp',
          correct: false,
          rejectBn: 'পিনহোল দিয়েই হাই-ভোল্টেজ আঘাত করে।',
        ),
        LearnBoardOption(
          id: 'bike',
          labelBn: 'কাট/বাইক গ্লাভস',
          asset: 'assets/duty_slip/dress/tray_bike_gloves.webp',
          correct: false,
          rejectBn: 'কাট-গ্লাভস শক আটকায় না—শুধু ঘষা আটকায়।',
        ),
        LearnBoardOption(
          id: 'cotton',
          labelBn: 'সুতির গ্লাভস',
          asset: 'assets/duty_slip/dress/tray_cotton_gloves.webp',
          correct: false,
          rejectBn: 'সুতি ঘাম আর জল টেনে নেয়—শক আটকায় না।',
        ),
        LearnBoardOption(
          id: 'cut',
          labelBn: 'কাট-রেজিস্ট্যান্ট গ্লাভস',
          asset: 'assets/safety/library/ppe/Cut_Resistant_Gloves.webp',
          correct: false,
          rejectBn: 'এই গ্লাভস ধারালো জিনিস আটকায়, বিদ্যুৎ নয়।',
        ),
        LearnBoardOption(
          id: 'insul',
          labelBn: 'ইনসুলেটেড রাবার গ্লাভস',
          asset: 'assets/safety/library/ppe/Electrical_Gloves.webp',
          correct: true,
        ),
        LearnBoardOption(
          id: 'insul2',
          labelBn: 'ইনসুলেটেড রাবার গ্লাভস',
          asset: 'assets/safety/library/ppe/Electrical_Gloves_2.webp',
          correct: true,
        ),
      ],
      whyChips: [
        LearnWhyChip(
          id: 'w1',
          textBn: 'টেস্টেড রাবারই শক থেকে বাঁচায়',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w2',
          textBn: 'কাট-প্রতিরোধী গ্লাভসই শকের বর্ম',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w3',
          textBn: 'ভেজা রাবার আরও ভালো ইনসুলেট করে',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w4',
          textBn: 'অক্ষত রাবার বিদ্যুৎ ঢুকতে দেয় না',
          correct: true,
        ),
        LearnWhyChip(
          id: 'w5',
          textBn: 'যেকোনো মোটা গ্লাভসেই চলবে',
          correct: false,
        ),
        LearnWhyChip(
          id: 'w6',
          textBn: 'সুতির গ্লাভস ঘাম শোষে, তাই নিরাপদ',
          correct: false,
        ),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: 'আরে! আমাদের বাপ-দাদারা তো এসব দিয়েই সারা জীবন কাজ করে গেল!',
    rivalLineBn: 'ফাটা হেলমেট হোক বা বাইকের হেলমেট—সবই তো মাথা বাঁচায়! এত নিয়ম লাগে নাকি?',
    exitBn: 'যত্তসব নতুন নিয়ম! আমি চললাম…',
    believeNoIsCorrect: true,
    stingBn: 'শুনলেন তো ওর কথা? সত্যি কি ওর এই বিপজ্জনক কথায় কান দেবেন?',
    wornAssets: [],
    dangerHints: [
      'ফাটা হেলমেট—চিন-স্ট্র্যাপ খোলা',
      'এক হাতে ছেঁড়া গ্লাভস, অন্য হাত খালি',
      'চপ্পল—কোনো ইনসুলেশন নেই',
    ],
    whyChips: [
      LearnWhyChip(
        id: 'm1',
        textBn: 'লাইনে ছিদ্রহীন ক্লাস-ই হেলমেটই দরকার',
        correct: true,
      ),
      LearnWhyChip(
        id: 'm2',
        textBn: 'ভেন্ট থাকলে গরমে নিরাপদ',
        correct: false,
      ),
      LearnWhyChip(
        id: 'm3',
        textBn: 'যেকোনো হেলমেট একই কাজ করে',
        correct: false,
      ),
      LearnWhyChip(
        id: 'm4',
        textBn: 'ফাটা হেলমেটের ফাটল দিয়েই শক ঢোকে',
        correct: true,
      ),
      LearnWhyChip(
        id: 'm5',
        textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক',
        correct: false,
      ),
      LearnWhyChip(
        id: 'm6',
        textBn: 'পুরোনো নিয়মেই কাজ চলে যায়',
        correct: false,
      ),
    ],
  ),
);

/// Ladder step 4 — Module 1 Lesson 1.2 (পাওয়ার লাইনের 'লক্ষ্মণ রেখা').
///
/// Picture cards are vector scenes from `tool/lakshman_art.py`: the worker's
/// own height (about 1.7 m) is the scale, so the gap to the live wire is
/// judged by eye, as the lesson teaches; no numbers in the pictures.
/// Distances from the lesson: LT ≥ 1.2 m, 11 kV ≥ 2.5 m, 33 kV ≥ 3.0 m (dry);
/// in rain or fog keep 10–12 ft from 11 kV.
const learnBoardPack12 = LearnBoardPack(
  lessonId: '1.2',
  titleBn: "পাওয়ার লাইনের 'লক্ষ্মণ রেখা'",
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'প্রতিটা লাইভ তারের চারপাশে অদৃশ্য গণ্ডি — ভেতরে ঢুকলেই বিপদ। ঠিক জায়গাটা চিনুন।',
  earnedBn: 'লক্ষ্মণ রেখা চিনেছেন — মাঠে এই দূরত্বই আপনার ঢাল।',
  slots: [
    LearnBoardSlot(
      id: 'gap11',
      promptBn: '11 kV লাইন — কোথায় দাঁড়াবেন?',
      options: [
        LearnBoardOption(id: 'far', labelBn: 'দুই মানুষ সমান দূরে', asset: 'assets/game/art/lakshman/d11_safe_far.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok', labelBn: 'দেড় মানুষের বেশি দূরে', asset: 'assets/game/art/lakshman/d11_safe_ok.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'lt',
          labelBn: 'LT-র মাপে দূরে',
          asset: 'assets/game/art/lakshman/d11_trap_lt.svg', scene: true,
          correct: false,
          rejectBn: '1.2 মিটার LT লাইনের মাপ। 11 kV-তে কমপক্ষে 2.5 মিটার।',
        ),
        LearnBoardOption(
          id: 'half',
          labelBn: 'আধা মানুষ দূরে',
          asset: 'assets/game/art/lakshman/d11_trap_half.svg', scene: true,
          correct: false,
          rejectBn: 'এত কাছে বিদ্যুৎ বাতাস ভেদ করে লাফ দিতে পারে।',
        ),
        LearnBoardOption(
          id: 'arm',
          labelBn: 'হাত বাড়ালেই তার',
          asset: 'assets/game/art/lakshman/d11_trap_arm.svg', scene: true,
          correct: false,
          rejectBn: 'না ছুঁলেও আর্ক ফ্ল্যাশ — এটা লক্ষ্মণ রেখার একেবারে ভেতরে।',
        ),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'তারের গায়ে হাত',
          asset: 'assets/game/art/lakshman/d11_trap_touch.svg', scene: true,
          correct: false,
          rejectBn: 'প্রতিটা তারকে লাইভ ধরুন — 11 kV-তে কমপক্ষে 2.5 মিটার দূরে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: '11 kV-তে কমপক্ষে 2.5 মিটার দূরে থাকতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'না ছুঁয়েও বিদ্যুৎ লাফিয়ে আসতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'না ছুঁলে বিদ্যুৎ কিছুই করতে পারে না', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'রাবারের জুতো থাকলে কাছে যাওয়া চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হাত বাড়িয়ে না ছুঁলেই নিরাপদ থাকা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'LT লাইনের মাপই 11 kV-তে যথেষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'tool',
      promptBn: 'হাতে লম্বা টুল — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'tip_out', labelBn: 'ডগাও রেখার বাইরে', asset: 'assets/game/art/lakshman/tool_tip_out.svg', scene: true, correct: true),
        LearnBoardOption(id: 'carry_low', labelBn: 'নিচু করে বহন', asset: 'assets/game/art/lakshman/tool_carry_low.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'tip_in',
          labelBn: 'ডগা তারের কাছে',
          asset: 'assets/game/art/lakshman/tool_tip_in.svg', scene: true,
          correct: false,
          rejectBn: 'শরীর দূরে, কিন্তু টুলের ডগা ভেতরে — টুলও শরীরের অংশ।',
        ),
        LearnBoardOption(
          id: 'ladder_top',
          labelBn: 'মইয়ের মাথা তারের কাছে',
          asset: 'assets/game/art/lakshman/tool_ladder_top.svg', scene: true,
          correct: false,
          rejectBn: 'মইয়ের মাথাও লক্ষ্মণ রেখার বাইরে রাখতে হয়।',
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'ডাল তারের দিকে',
          asset: 'assets/game/art/lakshman/tool_branch.svg', scene: true,
          correct: false,
          rejectBn: 'গাছের ডালও বিদ্যুৎ টেনে আনতে পারে — ডগা রেখার বাইরে রাখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'হাতের টুলও শরীরের অংশ ধরে মাপতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টুলের ডগাও লক্ষ্মণ রেখার বাইরে রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শরীর দূরে থাকলে টুল নিয়ে চিন্তা নেই', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'লম্বা লাঠি থাকলে আরও কাছে যাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ডাল কাঠের, তাই তারে লাগলেও ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মইয়ের মাথা তারে লাগলে কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'rain',
      promptBn: 'বৃষ্টি পড়ছে, 11 kV — কোথায় থামবেন?',
      options: [
        LearnBoardOption(id: 'r12', labelBn: 'প্রায় 12 ফুট দূরে', asset: 'assets/game/art/lakshman/rain_safe_12ft.svg', scene: true, correct: true),
        LearnBoardOption(id: 'r10', labelBn: 'প্রায় 10 ফুট দূরে', asset: 'assets/game/art/lakshman/rain_safe_10ft.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'dry',
          labelBn: 'শুকনো দিনের 8 ফুট',
          asset: 'assets/game/art/lakshman/rain_trap_dry.svg', scene: true,
          correct: false,
          rejectBn: 'বৃষ্টিতে বাতাস বিদ্যুৎ টানে — 11 kV-তে 8 ফুট নয়, 10–12 ফুট।',
        ),
        LearnBoardOption(
          id: 'close',
          labelBn: 'চার ফুটের মতো দূরে',
          asset: 'assets/game/art/lakshman/rain_trap_close.svg', scene: true,
          correct: false,
          rejectBn: 'বৃষ্টিতে বিপদসীমা বাড়ে — এটা অনেক কাছে।',
        ),
        LearnBoardOption(
          id: 'near',
          labelBn: 'তারের ঠিক নিচে',
          asset: 'assets/game/art/lakshman/rain_trap_near.svg', scene: true,
          correct: false,
          rejectBn: 'ভেজা বাতাসে বিদ্যুৎ সহজে লাফায় — এত কাছে কখনও নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বৃষ্টিতে বাতাস বিদ্যুৎ বেশি পরিবহন করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বৃষ্টিতে 11 kV-তে 10–12 ফুট দূরে থাকুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বৃষ্টিতে তার ঠান্ডা থাকে, তাই নিরাপদ', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'শুকনো দিনের মাপই সব আবহাওয়ায় চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রেনকোট পরলে কাছে যাওয়া চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বৃষ্টিতে আর্ক ফ্ল্যাশ হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'stick',
      promptBn: 'লাইভ তারের কাছে কোন লাঠি?',
      options: [
        LearnBoardOption(id: 'hot', labelBn: 'ফাইবারগ্লাস হট স্টিক', asset: 'assets/game/art/lakshman/stick_hot.svg', correct: true),
        LearnBoardOption(id: 'hot_tele', labelBn: 'অপারেটিং রড', asset: 'assets/game/art/lakshman/stick_hot_tele.svg', correct: true),
        LearnBoardOption(
          id: 'bamboo',
          labelBn: 'শুকনো বাঁশ',
          asset: 'assets/game/art/lakshman/stick_bamboo.svg',
          correct: false,
          rejectBn: 'ভেতরের আর্দ্রতা বা ময়লায় শুকনো বাঁশও বিদ্যুৎ টানে।',
        ),
        LearnBoardOption(
          id: 'pvc',
          labelBn: 'পিভিসি পাইপের জুগাড়',
          asset: 'assets/game/art/lakshman/stick_pvc.svg',
          correct: false,
          rejectBn: 'পিভিসি ফাটে, ভিজলে লিক করে, হুক মেটাল — জুগাড় বাঁচায় না।',
        ),
        LearnBoardOption(
          id: 'wood',
          labelBn: 'কাঠের লাঠি',
          asset: 'assets/game/art/lakshman/stick_wood.svg',
          correct: false,
          rejectBn: 'কাঠের ভেতরের জল আর গায়ের ময়লা দিয়ে বিদ্যুৎ চলে।',
        ),
        LearnBoardOption(
          id: 'metal',
          labelBn: 'লোহার পাইপ',
          asset: 'assets/game/art/lakshman/stick_metal.svg',
          correct: false,
          rejectBn: 'ধাতু সরাসরি বিদ্যুৎ টানে — লাইভ তারের কাছে কখনও নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পরীক্ষিত ফাইবারগ্লাস হট স্টিকই নিরাপদ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বাঁশ-কাঠে ভেতরের আর্দ্রতায় বিদ্যুৎ চলে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শুকনো বাঁশ সব সময়ই ইনসুলেটর', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'পিভিসি প্লাস্টিক, তাই হট স্টিকের কাজ চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যে কোনো লম্বা লাঠি হলেই চলবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ধাতুর পাইপ শক্ত, তাই বেশি নিরাপদ', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: 'আরে! আমাদের বাপ-দাদারা তো এসব দিয়েই সারা জীবন কাজ করে গেল!',
    rivalLineBn: 'আমি তো তারটা ছুঁচ্ছি না, একটু কাছে গেলে কিছু হবে না।',
    exitBn: 'যত্তসব নতুন নিয়ম! আমি চললাম…',
    believeNoIsCorrect: true,
    stingBn: 'শুনলেন তো ওর কথা? সত্যি কি ওর এই বিপজ্জনক কথায় কান দেবেন?',
    dangerHints: [
      'তারের হাতের নাগালে দাঁড়িয়ে',
      'লক্ষ্মণ রেখার একেবারে ভেতরে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'বিদ্যুৎ বাতাস ভেদ করে লাফায় — আর্ক ফ্ল্যাশ', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ছোঁয়ার আগেই কয়েক ফুট দূর থেকে বিপদ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'না ছুঁলে বিদ্যুৎ কখনও ধরে না', correct: false),
      LearnWhyChip(id: 'm4', textBn: 'একটু কাছে গেলে কিছুই হয় না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'শুধু বড় টাওয়ারের লাইনেই লাফায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক', correct: false),
    ],
  ),
);
