import 'learn_board_models.dart';

/// Ladder step 7 — Module 1 Lesson 1.3 (পোলের 'ভাষা' পড়তে শিখুন), the
/// picture board (mode like step 4).
///
/// Picture cards are vector scenes from `tool/pole_board_art.py`; each card
/// carries its own cue (the board shows a card's name only once tapped):
/// a walking loop round the pole, the state of the foot, a cut-away of the
/// pole's inside with the shape of the hammer's sound, rust and cracks, the
/// hardware seen from below. Everything comes from lesson 1.3: walk 360°
/// before touching a pole (not from afar, not one side only); the base
/// (eroded soil, standing water that the lesson only says to check for, a
/// cracked foundation, a lean); the sound test at waist height (PCC healthy
/// 'ঠক্ ঠক্' vs weak 'দপ্ দপ্' (ফাঁপা); steel clear metallic 'টন টন' vs a
/// 'ভোঁতা শব্দ' where rust flakes off); the visual scan (hairline crack,
/// spalling, rod showing, rust at ground level, welds and bolts); hardware
/// (bent / loose cross-arm, broken insulator, clamps; hives, nests and cable
/// tangle are reported first, climbed after they are cleared). Steel poles
/// are the lesson's three kinds — rail, H-beam (RSJ) and stepped tubular;
/// insulators are brown-glazed porcelain pin insulators (IS 731) with a grey
/// polymer one on some steel poles. No ladder here (ladders are lesson 1.2).
/// The rival's myth is the lesson's own: "স্টিলের পোল তো শুধু বাঁকতে পারে,
/// ভাঙে না।"
const learnBoardPack13 = LearnBoardPack(
  lessonId: '1.3',
  titleBn: "পোলের 'ভাষা' পড়তে শিখুন",
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'পোলে ওঠার আগে শেষ চেকপয়েন্ট পোল নিজেই। দেখে, ঠুকে, শুনে ওর ভাষা পড়ুন।',
  earnedBn: 'পোলের ভাষা পড়তে শিখেছেন — গোড়া দেখুন, ঠুকে শুনুন, তারপর উঠুন।',
  slots: [
    LearnBoardSlot(
      id: 'walk',
      promptBn: 'পোলের কাছে পৌঁছেছেন — প্রথম কাজ কোনটা?',
      options: [
        LearnBoardOption(id: 'walk_round', labelBn: 'চারপাশে একবার ঘোরা', asset: 'assets/game/art/pole_board/walk_round.svg', scene: true, correct: true),
        LearnBoardOption(id: 'walk_back', labelBn: 'পেছন দিকও ঘুরে দেখা', asset: 'assets/game/art/pole_board/walk_back.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'climb_now',
          labelBn: 'পৌঁছেই উঠে পড়া',
          asset: 'assets/game/art/pole_board/climb_now.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে চারপাশে ঘুরে দেখুন — নতুন দেখতে পোলেরও ভিত্তি দুর্বল থাকতে পারে।',
        ),
        LearnBoardOption(
          id: 'from_far',
          labelBn: 'দূর থেকে দেখেই ঠিক ধরা',
          asset: 'assets/game/art/pole_board/from_far.svg',
          scene: true,
          correct: false,
          rejectBn: 'দূর থেকে গোড়া বোঝা যায় না — কাছে গিয়ে চারপাশে একবার ঘুরে আসুন।',
        ),
        LearnBoardOption(
          id: 'lean_on',
          labelBn: 'না দেখেই পোলে হেলান',
          asset: 'assets/game/art/pole_board/lean_on.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে হাত দেওয়ার আগে তার চারপাশে সম্পূর্ণ একবার ঘুরে আসুন।',
        ),
        LearnBoardOption(
          id: 'one_side',
          labelBn: 'শুধু সামনে থেকে দেখা',
          asset: 'assets/game/art/pole_board/one_side.svg',
          scene: true,
          correct: false,
          rejectBn: 'এক পাশ দেখলে হবে না — পেছনের গোড়াটাই হয়তো ক্ষয়ে গেছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'হাত দেওয়ার আগে চারপাশ ঘুরে দেখতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সব দিক ঘুরলে বোঝা যায় পোল হেলে আছে কিনা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নতুন দেখতে পোল সবসময় নিরাপদই হয়', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'সামনে থেকে দেখলেই পুরো পোল বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'তাড়া থাকলে ঘুরে দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দূর থেকে একবার দেখলেই পোল চেনা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অফিস যে পোল দিয়েছে সেটা ঠিকই থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'base',
      promptBn: 'গোড়াটা দেখুন — কোন পোলে ওঠা যায়?',
      options: [
        LearnBoardOption(id: 'base_firm', labelBn: 'শক্ত মাটি, সোজা পোল', asset: 'assets/game/art/pole_board/base_firm.svg', scene: true, correct: true),
        LearnBoardOption(id: 'base_dry', labelBn: 'অটুট ভিত, শুকনো গোড়া', asset: 'assets/game/art/pole_board/base_dry.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'erosion',
          labelBn: 'গোড়ার মাটি ক্ষয়ে গর্ত',
          asset: 'assets/game/art/pole_board/base_erosion.svg',
          scene: true,
          correct: false,
          rejectBn: 'গোড়ার মাটি ক্ষয়ে গেছে — পোলের ভিত্তিই তার আসল শক্তি।',
        ),
        LearnBoardOption(
          id: 'water',
          labelBn: 'গোড়ায় জল জমে আছে',
          asset: 'assets/game/art/pole_board/base_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'গোড়ায় জল জমে আছে — আগে দেখে নিন, বিপজ্জনক মনে হলে সুপারভাইজারকে জানান।',
        ),
        LearnBoardOption(
          id: 'lean',
          labelBn: 'হেলে থাকা পোল',
          asset: 'assets/game/art/pole_board/base_lean.svg',
          scene: true,
          correct: false,
          rejectBn: 'হেলে থাকা পোল আপনার শরীরের ভারে ভেঙে পড়তে পারে।',
        ),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'ফাউন্ডেশনে ফাটল',
          asset: 'assets/game/art/pole_board/base_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফাউন্ডেশনে ফাটল — হিরো হবেন না, সুপারভাইজারকে জানান।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'গোড়ার ভিত্তিই পোলের আসল শক্তি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হেলে থাকা পোল শরীরের ভারে ভাঙতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গোড়ায় জমা জল দেখার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'একটু হেলে থাকলে কোনো সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'তারের টানেই পোল দাঁড়িয়ে থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফাউন্ডেশনের ফাটল শুধু দেখতে খারাপ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ওপর ঠিক থাকলে গোড়া দেখা লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'sound',
      promptBn: 'হাতুড়ি ঠুকে শুনুন — কোন পোলে ওঠা যায়?',
      options: [
        LearnBoardOption(id: 'pcc_solid', labelBn: "PCC পোলে নিরেট 'ঠক্ ঠক্'", asset: 'assets/game/art/pole_board/sound_pcc_solid.svg', scene: true, correct: true),
        LearnBoardOption(id: 'steel_ring', labelBn: "পরিষ্কার ধাতব 'টন টন' শব্দ", asset: 'assets/game/art/pole_board/sound_steel_ring.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'pcc_hollow',
          labelBn: "ফাঁপা 'দপ্ দপ্' শব্দ",
          asset: 'assets/game/art/pole_board/sound_pcc_hollow.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফাঁপা শব্দ মানে ভেতরে কংক্রিট দুর্বল বা ফাটল আছে।',
        ),
        LearnBoardOption(
          id: 'steel_dull',
          labelBn: "মরিচার জায়গায় 'ভোঁতা শব্দ'",
          asset: 'assets/game/art/pole_board/sound_steel_dull.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচার জায়গায় ভোঁতা শব্দ, স্তর খসে পড়ছে — পোল বিপজ্জনকভাবে দুর্বল।',
        ),
        LearnBoardOption(
          id: 'no_tap',
          labelBn: 'না ঠুকেই ওঠা',
          asset: 'assets/game/art/pole_board/sound_no_tap.svg',
          scene: true,
          correct: false,
          rejectBn: 'গোড়ায় আর জয়েন্টে হাতুড়ি ঠুকে না শুনে উঠবেন না।',
        ),
      ],
      whyChips: [
        // Both right reasons fit both safe cards (solid PCC, ringing steel).
        LearnWhyChip(id: 'w1', textBn: 'শব্দে কোনো ফাঁপা বা ভোঁতা ভাব নেই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সুস্থ পোলের শব্দ নিরেট আর পরিষ্কার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দপ্ দপ্ শব্দ মানে পোল নিরেট আছে', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'ভোঁতা শব্দ মানে স্টিল বেশি মোটা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শব্দ শুনে পোলের কিছুই বোঝা যায় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শুধু পোলের মাথায় ঠুকলেই চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বাইরে ভালো দেখালে ঠোকা লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'scan',
      promptBn: 'গোড়া থেকে ওপরে চোখ বুলান — কোনটা সুস্থ?',
      options: [
        LearnBoardOption(id: 'pcc_clean', labelBn: 'অক্ষত মসৃণ PCC পোল', asset: 'assets/game/art/pole_board/scan_pcc_clean.svg', scene: true, correct: true),
        LearnBoardOption(id: 'steel_clean', labelBn: 'মরিচাহীন এইচ-বিম পোল', asset: 'assets/game/art/pole_board/scan_steel_clean.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'hairline',
          labelBn: 'চুলের মতো ফাটল',
          asset: 'assets/game/art/pole_board/scan_hairline.svg',
          scene: true,
          correct: false,
          rejectBn: 'সূক্ষ্ম ফাটল দিয়ে জল ঢুকে ভেতরের রডে মরিচা ধরে — বড় বিপদের লক্ষণ।',
        ),
        LearnBoardOption(
          id: 'spalling',
          labelBn: 'কংক্রিট খসে রড বেরিয়ে',
          asset: 'assets/game/art/pole_board/scan_spalling.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেতরের রড বেরিয়ে আসা মানে পোলের শক্তি প্রায় শেষ।',
        ),
        LearnBoardOption(
          id: 'rust_ground',
          labelBn: 'মাটির কাছে মরিচা',
          asset: 'assets/game/art/pole_board/scan_rust_ground.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটির সংযোগস্থলে মরিচা — শরীরের ভারেই পোল ভেঙে পড়তে পারে।',
        ),
        LearnBoardOption(
          id: 'rust_weld',
          labelBn: 'জয়েন্টে আর বল্টুতে মরিচা',
          asset: 'assets/game/art/pole_board/scan_rust_weld.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওয়েল্ডিং জয়েন্ট আর নাট-বল্টুর মরিচা — মরিচা স্টিলের ক্যান্সার।',
        ),
      ],
      whyChips: [
        // Every right reason fits both safe cards (clean PCC and clean steel),
        // so whichever the player picked, the dealt reason matches it.
        LearnWhyChip(id: 'w1', textBn: 'গোড়া থেকে মাথা — ফাটল বা মরিচা নেই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফাটল, খসা বা মরিচা — সবই বিপদের লক্ষণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গোড়া থেকে ওপরে ধীরে চোখ বুলাতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চুলের মতো ফাটল তো সব পোলেই থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মরিচা শুধু রং নষ্ট করে, শক্তি নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নতুন রং করা পোলে কোনো বিপদ থাকে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জয়েন্টের মরিচায় কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'একটু খসা কংক্রিটে কিছুই হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hardware',
      promptBn: 'নিচ থেকে মাথাটা দেখুন — কোনটা ঠিক আছে?',
      options: [
        LearnBoardOption(id: 'top_ok', labelBn: 'ক্রস-আর্ম সোজা, ইনসুলেটর অটুট', asset: 'assets/game/art/pole_board/top_ok_pcc.svg', scene: true, correct: true),
        LearnBoardOption(id: 'top_ok_steel', labelBn: 'ক্ল্যাম্প টাইট, সব অটুট', asset: 'assets/game/art/pole_board/top_ok_steel.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'arm_bent',
          labelBn: 'বাঁকা ক্রস-আর্ম',
          asset: 'assets/game/art/pole_board/top_arm_bent.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্রস-আর্ম বেঁকে গেছে — নিচ থেকেই দেখে রিপোর্ট করুন, ওঠা নয়।',
        ),
        LearnBoardOption(
          id: 'insulator_broken',
          labelBn: 'ভাঙা ইনসুলেটর',
          asset: 'assets/game/art/pole_board/top_insulator_broken.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা ইনসুলেটরে কারেন্ট লিক করে পুরো পোল বিদ্যুতায়িত হতে পারে।',
        ),
        LearnBoardOption(
          id: 'clamp_loose',
          labelBn: 'আলগা ক্ল্যাম্প, মরিচা বল্টু',
          asset: 'assets/game/art/pole_board/top_clamp_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'আলগা ক্ল্যাম্পে ক্রস-আর্ম আপনার ভারে ঘুরে যেতে বা ভেঙে পড়তে পারে।',
        ),
        LearnBoardOption(
          id: 'hive_nest',
          labelBn: 'চাক, বাসা আর কেবলের জট',
          asset: 'assets/game/art/pole_board/top_hive_nest.svg',
          scene: true,
          correct: false,
          rejectBn: 'চাক, বাসা বা কেবলের জট — আগে রিপোর্ট করুন, সরানো হলে তবেই উঠুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিচ থেকে দেখে নিয়েছি, সব অটুট আছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভাঙা ইনসুলেটরে পোলে কারেন্ট আসতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ক্রস-আর্ম একটু বাঁকা হলে সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'ফাটা ইনসুলেটরও কারেন্ট আটকে রাখে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বোলতার চাক ওপরে থাকে, তাই ভয় নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নাট-বল্টুর মরিচায় কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ঝড়ের পরে হার্ডওয়্যার দেখা লাগে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: PoleBoardLines.rivalTaunt,
    rivalLineBn: PoleBoardLines.rivalMyth,
    exitBn: 'যত্তসব নতুন নিয়ম! আমি চললাম…',
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'গোড়ার মরিচা না দেখেই ওঠা',
      'হাতুড়ি ঠুকে শব্দ শোনেনি',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'গোড়ার মরিচায় স্টিলের পোলও হঠাৎ ভাঙে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'মরিচা ধরা পোল শরীরের ভারেও ভাঙতে পারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'স্টিল কখনও ভাঙে না, শুধু বাঁকে', correct: false),
      LearnWhyChip(id: 'm4', textBn: 'মরিচা শুধু ওপরের রংটাই নষ্ট করে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ভাঙার আগে পোল সবসময় জানান দেয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ভারী পোলে মরিচায় কিছু হয় না', correct: false),
    ],
  ),
);

/// The careless lineman's new lines on this board, in his recorded voice
/// (`r_<sha1>.mp3` in `learnRivalVoice`). The guide's lines stay in the pack
/// (device TTS until the owner records them).
abstract final class PoleBoardLines {
  static const rivalTaunt = 'আরে! এত বছর এই পোলেই উঠছি, কিছু তো হয়নি!';
  static const rivalMyth = 'স্টিলের পোল তো শুধু বাঁকে, ভাঙে না! গোড়ায় একটু মরিচা থাকলে কী হয়?';

  static const recorded = [rivalTaunt, rivalMyth];
}
