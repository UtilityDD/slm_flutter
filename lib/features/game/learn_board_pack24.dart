import 'learn_board_models.dart';

/// Module 2 Lesson 2.4 (কাম-অ্যালং ক্ল্যাম্প: নিয়ন্ত্রিত শক্তি), the picture
/// board (rung `2.4/learn`, pack `learn_2_4`).
///
/// Picture cards are vector scenes from `tool/m2_board24_art.py`. Every round
/// and every trap comes from the lesson text:
///  * check: before use, check the ratchet, hook, safety latch and cable; the
///    wire grip's jaws/teeth clean and sharp — oil or dirt on the teeth and
///    it can slip;
///  * rig (the golden rules, steps 1–3): the fixed end on a very strong,
///    reliable anchor (the pole strap or the cross-arm's root); the grip
///    seated evenly and firmly; the hook into the grip's eye-bolt;
///  * stand: never directly in front of or behind the line of pull — always
///    beside it (a hook coming off or a grip slipping is a sling-shot);
///  * pull (step 4 + pro tips): slow and controlled, the ratchet locked after
///    every stroke; no extra pipe on the handle; a jerk is a danger sign;
///  * release: the riskiest step — slowly, controlled, never the whole load
///    at once; know the release mechanism before the job.
/// The rival's myth is the lesson's first: "যেকোনো গ্রিপ দিয়েই যেকোনো তার
/// টানা যায়। ACSR আর AAAC-তে আর কী তফাৎ!" (the second, "a little jerk is
/// normal", is a wrong reason in the pull round).
const learnBoardPack24 = LearnBoardPack(
  lessonId: '2.4',
  titleBn: 'কাম-অ্যালং ক্ল্যাম্প: নিয়ন্ত্রিত শক্তি',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'সামান্য শক্তি বহুগুণ হয় — একটা ভুলেই স্লিং-শট। যন্ত্রটাকে নিরাপদে চালাতে শিখুন।',
  earnedBn: 'পাশে দাঁড়ান, ধীরে টানুন, ধীরে ছাড়ুন — কাম-অ্যালং এবার আপনার বশে।',
  slots: [
    LearnBoardSlot(
      id: 'check',
      promptBn: 'কাজের আগে কাম-অ্যালং আর গ্রিপ পরীক্ষা — কোনটা চলবে?',
      options: [
        LearnBoardOption(id: 'clean', labelBn: 'পরিষ্কার, ধারালো দাঁতের গ্রিপ', asset: 'assets/game/art/m2_board24/check_clean.svg', scene: true, correct: true),
        LearnBoardOption(id: 'latch', labelBn: 'সেফটি ল্যাচ আঁটা অটুট হুক', asset: 'assets/game/art/m2_board24/check_latch.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'oily',
          labelBn: 'তেল-ময়লা জমা দাঁতের গ্রিপ',
          asset: 'assets/game/art/m2_board24/check_oily.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রিপের দাঁতে তেল বা ময়লা জমলে কার্যকারিতা কমে — টানের মধ্যে পিছলে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'blunt',
          labelBn: 'ক্ষয়ে ভোঁতা হওয়া দাঁতের গ্রিপ',
          asset: 'assets/game/art/m2_board24/check_blunt.svg',
          scene: true,
          correct: false,
          rejectBn: "ব্যবহারের আগে দেখুন গ্রিপের জ' বা দাঁত পরিষ্কার আর ধারালো কিনা — ভোঁতা গ্রিপ চলবে না।",
        ),
        LearnBoardOption(
          id: 'no_latch',
          labelBn: 'সেফটি ল্যাচ ভাঙা হুক',
          asset: 'assets/game/art/m2_board24/check_no_latch.svg',
          scene: true,
          correct: false,
          rejectBn: 'হুক খুলে গেলে প্রচণ্ড টান ছিটকে আসে — মারাত্মক স্লিং-শট। আগে সেফটি ল্যাচ দেখুন।',
        ),
        LearnBoardOption(
          id: 'frayed',
          labelBn: 'তার বেরিয়ে আসা কেবিলের পুলার',
          asset: 'assets/game/art/m2_board24/check_frayed.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে কেবিল পরীক্ষা করুন — প্রচণ্ড টানে একটা অংশ ভাঙলেই স্লিং-শট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ব্যবহারের আগে র‍্যাচেট, হুক, ল্যাচ, কেবিল দেখি', correct: true),
        LearnWhyChip(id: 'w2', textBn: "গ্রিপের জ' পরিষ্কার-ধারালো, হুকে ল্যাচ আঁটা", correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কোনো অংশ বিগড়ালেই টানের মধ্যে স্লিং-শট', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দেখতে ঠিক লাগলে যন্ত্র পরীক্ষার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দাঁতে একটু তেল থাকলে গ্রিপ আরও ভালো ধরে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ল্যাচ ছাড়াও হুক টানের মধ্যে আটকে থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কেবিলের দু-একটা তার ছিঁড়লে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভোঁতা দাঁতে তারের ক্ষতি কম, তাই ওটাই ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যন্ত্র পরীক্ষা করা স্টোরের লোকের দায়িত্ব', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'rig',
      promptBn: 'তার টানার সেট-আপ — কোনটা ঠিকভাবে লাগানো?',
      options: [
        LearnBoardOption(id: 'strap', labelBn: 'পোলের স্ট্র্যাপে অ্যাঙ্কর করা', asset: 'assets/game/art/m2_board24/rig_strap.svg', scene: true, correct: true),
        LearnBoardOption(id: 'arm', labelBn: 'ক্রস-আর্মের গোড়ায় অ্যাঙ্কর করা', asset: 'assets/game/art/m2_board24/rig_arm.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'গাছের সরু ডালে অ্যাঙ্কর করা',
          asset: 'assets/game/art/m2_board24/rig_branch.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্থির প্রান্ত লাগান অত্যন্ত মজবুত, নির্ভরযোগ্য অ্যাঙ্করে — যেমন পোলের স্ট্র্যাপ বা ক্রস-আর্মের গোড়া।',
        ),
        LearnBoardOption(
          id: 'skew',
          labelBn: 'তারে বাঁকা হয়ে বসা গ্রিপ',
          asset: 'assets/game/art/m2_board24/rig_skew.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রিপ কন্ডাক্টরের ওপর সমানভাবে আর দৃঢ়ভাবে বসাতে হয় — গ্রিপ পিছলালেই স্লিং-শট।',
        ),
        LearnBoardOption(
          id: 'jaw',
          labelBn: "আই-বোল্ট ছেড়ে জ'-এ লাগানো হুক",
          asset: 'assets/game/art/m2_board24/rig_jaw.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাম-অ্যালং-এর হুক লাগান ওয়্যার গ্রিপের আই-বোল্টে — হুক খুলে গেলে স্লিং-শট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্থির প্রান্ত খুব মজবুত, নির্ভরযোগ্য অ্যাঙ্করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গ্রিপ সমান-দৃঢ়ভাবে বসে, হুক আই-বোল্টে লাগে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হুক খুলে বা গ্রিপ পিছলে গেলে স্লিং-শট হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো খুঁটি বা ডাল হলেই অ্যাঙ্কর হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গ্রিপ বাঁকা বসলেও টানের চোটে নিজেই সোজা হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হুক গ্রিপের যেখানে খুশি লাগালেও টান একই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অ্যাঙ্কর দুর্বল হলে আস্তে টানলেই হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তাড়া থাকলে এক-আধটা ধাপ বাদ দেওয়া যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'stand',
      promptBn: 'তার টানা চলছে — আপনি কোথায় দাঁড়াবেন?',
      options: [
        LearnBoardOption(id: 'side', labelBn: 'টানের লাইনের পাশে দাঁড়িয়ে লিভার', asset: 'assets/game/art/m2_board24/stand_side.svg', scene: true, correct: true),
        LearnBoardOption(id: 'side_far', labelBn: 'লাইনের অন্য পাশে দাঁড়িয়ে লিভার', asset: 'assets/game/art/m2_board24/stand_side_far.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'front',
          labelBn: 'গ্রিপের সামনে, টানের লাইনে',
          asset: 'assets/game/art/m2_board24/stand_front.svg',
          scene: true,
          correct: false,
          rejectBn: 'টানের লাইনের সরাসরি সামনে কখনোই নয় — গ্রিপ পিছলালে স্লিং-শট সামনের সবকিছুকে আঘাত করে।',
        ),
        LearnBoardOption(
          id: 'behind',
          labelBn: 'পোলের পেছনে, টানের লাইনে',
          asset: 'assets/game/art/m2_board24/stand_behind.svg',
          scene: true,
          correct: false,
          rejectBn: 'টানের লাইনের সরাসরি পেছনেও নয় — হুক খুলে গেলে পুরো টান ছিটকে আসে। পাশে দাঁড়ান।',
        ),
        LearnBoardOption(
          id: 'astride',
          labelBn: 'কেবিলের দু-পাশে পা রেখে দাঁড়ানো',
          asset: 'assets/game/art/m2_board24/stand_astride.svg',
          scene: true,
          correct: false,
          rejectBn: 'টানের লাইনের ওপর দাঁড়ানো মানেই বিপদ জোনে থাকা — সবসময় পাশে দাঁড়িয়ে কাজ করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টানের লাইনের সামনে-পেছনে কখনো দাঁড়াই না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হুক খুললে বা গ্রিপ পিছলালে স্লিং-শট আসে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সবসময় লাইনের পাশে দাঁড়িয়ে কাজ করতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লাইনের সামনে থাকলে গ্রিপ ভালো দেখা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পোলের আড়ালে দাঁড়ালে কোনো বিপদ থাকে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কেবিলের ওপর দাঁড়ালে টানটা ভালো বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'টান যতই হোক, হুক কখনো খুলে আসে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অভিজ্ঞ লোকের হাতে গ্রিপ কখনো পিছলায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pull',
      promptBn: 'লিভার চালিয়ে টেনশন দিচ্ছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'slow', labelBn: 'ধীরে, নিয়ন্ত্রিতভাবে লিভার টানা', asset: 'assets/game/art/m2_board24/pull_slow.svg', scene: true, correct: true),
        LearnBoardOption(id: 'lock', labelBn: 'প্রতি টানে র‍্যাচেটের লক দেখা', asset: 'assets/game/art/m2_board24/pull_lock.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'pipe',
          labelBn: 'হ্যান্ডেলে পাইপ জুড়ে জোর বাড়ানো',
          asset: 'assets/game/art/m2_board24/pull_pipe.svg',
          scene: true,
          correct: false,
          rejectBn: 'হ্যান্ডেলে বাড়তি পাইপ নয় — এটা যন্ত্রের ডিজাইন ক্ষমতার বাইরে, যন্ত্র ভেঙে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'yank',
          labelBn: 'ঝাঁকুনি দিয়ে জোরে হ্যাঁচকা টান',
          asset: 'assets/game/art/m2_board24/pull_yank.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঝাঁকুনি বা হঠাৎ স্লিপ বিপদের লক্ষণ — যন্ত্রে অতিরিক্ত চাপ পড়ে। টান হোক মসৃণ।',
        ),
        LearnBoardOption(
          id: 'let_go',
          labelBn: 'লক না দেখেই লিভার ছেড়ে দেওয়া',
          asset: 'assets/game/art/m2_board24/pull_let_go.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিবার লিভার টানার পর র‍্যাচেট ঠিকমতো লক হচ্ছে কিনা নিশ্চিত করুন — তাড়াহুড়ো নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ধীরে, নিয়ন্ত্রিত টান — তাড়াহুড়ো একদম নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'প্রতিবার টানের পর র‍্যাচেট লক হল কিনা দেখি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মসৃণ টানই বলে যন্ত্রটা ঠিকভাবে চলছে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পাইপ জুড়ে লিভার লম্বা করলে কাজ সহজ হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হ্যাঁচকা টানে তার তাড়াতাড়ি টাইট হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তার টানার সময় একটু-আধটু ঝাঁকুনি তো হবেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'র‍্যাচেট নিজেই লক হয়, দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লোড ক্যাপাসিটির একটু বেশি দিলেও চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'release',
      promptBn: 'কাজ শেষ, এবার টেনশন রিলিজ — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'ease', labelBn: 'ধীরে ধীরে, নিয়ন্ত্রিতভাবে লোড কমানো', asset: 'assets/game/art/m2_board24/release_ease.svg', scene: true, correct: true),
        LearnBoardOption(id: 'learn', labelBn: 'কাজের আগেই রিলিজ বুঝে নেওয়া', asset: 'assets/game/art/m2_board24/release_learn.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'snap',
          labelBn: 'হঠাৎ পুরো লোড একসাথে ছেড়ে দেওয়া',
          asset: 'assets/game/art/m2_board24/release_snap.svg',
          scene: true,
          correct: false,
          rejectBn: 'হঠাৎ পুরো লোড ছাড়লে যন্ত্র আর কন্ডাক্টর দুটোরই ক্ষতি, মারাত্মক বিপদও — ধীরে, নিয়ন্ত্রিতভাবে কমান।',
        ),
        LearnBoardOption(
          id: 'front',
          labelBn: 'টানের লাইনের সামনে দাঁড়িয়ে রিলিজ',
          asset: 'assets/game/art/m2_board24/release_front.svg',
          scene: true,
          correct: false,
          rejectBn: 'রিলিজই সবচেয়ে ঝুঁকিপূর্ণ ধাপ — টানের লাইনের সামনে বা পেছনে নয়, পাশে দাঁড়ান।',
        ),
        LearnBoardOption(
          id: 'unhook',
          labelBn: 'টান থাকতেই গ্রিপ থেকে হুক খোলা',
          asset: 'assets/game/art/m2_board24/release_unhook.svg',
          scene: true,
          correct: false,
          rejectBn: 'টান থাকতে হুক খোলা মানে হঠাৎ পুরো লোড ছাড়া — আগে র‍্যাচেটে ধীরে ধীরে লোড কমান।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রিলিজ সবচেয়ে ঝুঁকিপূর্ণ ধাপ — ধৈর্য চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লোড কমাতে হয় অত্যন্ত ধীরে, নিয়ন্ত্রিতভাবে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রিলিজ কীভাবে কাজ করে, কাজের আগেই জানি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কাজ শেষ, তাই লোড একবারে ছাড়লেই চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রিলিজ তো সোজা কাজ, বোঝার কিছুই নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হুক খুলে দিলে টান নিজে থেকেই কমে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লোড কমানোর সময় সামনে দাঁড়ালে সুবিধা', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তাড়াতাড়ি রিলিজ করলে যন্ত্রের ক্ষতি কম', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: ClampBoardLines.rivalTaunt,
    rivalLineBn: ClampBoardLines.rivalMyth,
    exitBn: ClampBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'তার না বুঝে যেকোনো গ্রিপ',
      'স্ট্র্যান্ড কেটে তার দুর্বল',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ACSR-এর ভেতরে স্টিলের কোর, চাই মজবুত গ্রিপ', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ভুল গ্রিপে কন্ডাক্টর চিরস্থায়ী ক্ষতিগ্রস্ত হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ACSR, AAAC, ইনসুলেটেড — আলাদা ডিজাইনের গ্রিপ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'সব তারই তো তার, যেকোনো গ্রিপেই ধরে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ACSR আর AAAC-র মধ্যে আসলে কোনো তফাৎ নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'গ্রিপ শক্ত করে আঁটলে ধরন দেখার দরকার নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'স্ট্র্যান্ড একটু কাটলে তারের কিছুই হয় না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'হাতের কাছে যে গ্রিপ, সেটাই সবচেয়ে ভালো', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. [rivalExit] is already in his
/// recorded voice (`learnRivalVoice`); the lines in [toRecord] play through
/// device TTS until the owner records them (tool/make_learn_voice.py).
abstract final class ClampBoardLines {
  static const rivalTaunt = 'আরে! গ্রিপ তো গ্রিপই — যেটা হাতের কাছে আছে, লাগিয়ে দাও!';

  /// Lesson 2.4's first myth buster, word for word.
  static const rivalMyth = 'যেকোনো গ্রিপ দিয়েই যেকোনো তার টানা যায়। ACSR আর AAAC-তে আর কী তফাৎ!';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines this board adds, to record in his voice.
  static const toRecord = [rivalTaunt, rivalMyth];
}
