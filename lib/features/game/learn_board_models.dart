// Shared Learn choice-board models (PickGear + MythRival spine).
// Modes beyond PickGear (OrderSteps, MeasureRule, …) reuse the same pending/Why flow later.

enum LearnBoardMode { pickGear, mythRival }

class LearnBoardOption {
  const LearnBoardOption({
    required this.id,
    required this.labelBn,
    required this.asset,
    required this.correct,
    this.rejectBn = '',
  });

  final String id;
  final String labelBn;
  final String asset;
  final bool correct;

  /// Spoken / shown when this trap is tapped.
  final String rejectBn;
}

class LearnWhyChip {
  const LearnWhyChip({required this.id, required this.textBn, required this.correct});

  final String id;
  final String textBn;
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
  });

  final String id;
  final String promptBn;
  final List<LearnBoardOption> options;
  final List<LearnWhyChip> whyChips;

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
    this.stingBn = 'এই লোক যা বলছে… বিশ্বাস করেন?',
    this.exitBn = 'যত্তসব নতুন নিয়ম! আমি চললাম… হা!',
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
    this.clearBonus = 20,
  });

  final String lessonId;
  final String titleBn;
  final String badgeBn;
  final String introBn;
  final List<LearnBoardSlot> slots;
  final LearnMythBeat myth;
  final int clearBonus;
}

LearnBoardPack? learnBoardPackFor(String lessonId) {
  if (lessonId == '1.1') return learnBoardPack11;
  return null;
}

/// Prototype pack — Module 1 Lesson 1.1 (সুরক্ষা কবচ).
const learnBoardPack11 = LearnBoardPack(
  lessonId: '1.1',
  titleBn: 'প্রথম দিনের ইউনিফর্ম ও পিপিই',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'আজ প্রথম দিন। সঠিক জিনিস বেছে নিন—ভুল মানে বিপদ।',
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
      ],
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
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: 'আরে! আমাদের বাপ-দাদারা তো এসব দিয়েই সারা জীবন কাজ করে গেল!',
    rivalLineBn: 'ফাটা হেলমেট হোক বা বাইকের হেলমেট—সবই তো মাথা বাঁচায়! এত নিয়ম লাগে নাকি?',
    exitBn: 'যত্তসব নতুন নিয়ম! আমি চললাম… হা!',
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
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
    ],
  ),
);
