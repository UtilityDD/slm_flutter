import 'learn_board_models.dart';

/// Module 2 Lesson 2.7 ('মেগার' (Megger) কী ও কেন?), the picture board
/// (rung `2.7/learn`, pack `learn_2_7`).
///
/// Picture cards are vector scenes from `tool/m2_board27_art.py` (the meter
/// readings are drawn glyphs, not words). Every round and every trap comes
/// from the lesson text:
///  * pick: the megger puts a high DC voltage (e.g. 500V) on the insulation
///    and shows its real health; a multimeter (usually 9V) cannot. Daily
///    check: the battery level and the test leads' insulation intact;
///  * prep: disconnect from the supply and discharge well first (live or
///    undischarged = strictly forbidden); a wet or damp set-up gives a false,
///    low reading; dirt or carbon on a terminal makes a leakage path;
///  * connect: 'Line' lead on the conductor, 'Earth' lead on the armour; the
///    megger is itself a high-voltage source — don't touch exposed parts;
///  * read: higher IR = better insulation; usually 1 MΩ is the minimum safe
///    value; below 1 MΩ = weak, damp or damaged, not safe to use;
///  * after: discharge again — the test voltage can stay stored as charge.
/// The rival's myth is the lesson's first: "মাল্টিমিটার দিয়ে রেজিস্ট্যান্স
/// মেপে যদি 'ইনফিনিটি' দেখায়, তার মানে ইনসুলেশন ঠিক আছে। মেগারের দরকার নেই।"
const learnBoardPack27 = LearnBoardPack(
  lessonId: '2.7',
  titleBn: "'মেগার' (Megger) কী ও কেন?",
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'মেগার ইনসুলেশনের ডাক্তার — উচ্চ ভোল্টেজের চাপ দিয়ে তার আসল স্বাস্থ্য দেখায়। চিনে নিন।',
  earnedBn: 'আগে বিচ্ছিন্ন ও ডিসচার্জ, তারপর মেগার — 1 MΩ-এর কম মানে বিপদ, শেষে আবার ডিসচার্জ।',
  slots: [
    LearnBoardSlot(
      id: 'pick',
      promptBn: 'কেবিলের ইনসুলেশনের আসল স্বাস্থ্য দেখবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'megger', labelBn: 'মেগার লাগিয়ে টেস্ট বাটন চাপা', asset: 'assets/game/art/m2_board27/pick_megger.svg', scene: true, correct: true),
        LearnBoardOption(id: 'check', labelBn: 'আগে মেগারের লিড দেখে নেওয়া', asset: 'assets/game/art/m2_board27/pick_check.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'dmm',
          labelBn: 'মাল্টিমিটারে মেপে নিশ্চিন্ত',
          asset: 'assets/game/art/m2_board27/pick_dmm.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাল্টিমিটার কম ভোল্টেজে (সাধারণত 9 ভোল্ট) মাপে — উচ্চ ভোল্টেজের চাপে ইনসুলেশন টিকবে কিনা ধরতে পারে না।',
        ),
        LearnBoardOption(
          id: 'lead',
          labelBn: 'ফাটা লিড নিয়েই টেস্ট',
          asset: 'assets/game/art/m2_board27/pick_lead.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে টেস্ট লিড দেখুন — লিডের ইনসুলেশন সম্পূর্ণ অক্ষত চাই।',
        ),
        LearnBoardOption(
          id: 'battery',
          labelBn: 'ব্যাটারি না দেখেই টেস্ট',
          asset: 'assets/game/art/m2_board27/pick_battery.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে মেগারের ব্যাটারি লেভেল পরীক্ষা করুন — খালি ব্যাটারিতে টেস্ট নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মেগার উচ্চ DC ভোল্টেজে ইনসুলেশন পরখ করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কম ভোল্টেজে ঠিক, উচ্চ চাপে ভাঙতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে মেগারের ব্যাটারি আর লিড পরীক্ষা চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মাল্টিমিটারের 9 ভোল্টই ইনসুলেশনে যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ইনফিনিটি দেখালেই ইনসুলেশন একদম ঠিক', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লিড একটু ফাটা হলে রিডিং-এ কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্যাটারি কম থাকলেও মেগার ঠিক মাপে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'চোখে দেখে ভালো লাগলে টেস্টের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মেগার শুধু নতুন কেবিলের জন্য, পুরনোর নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'prep',
      promptBn: 'আইআর টেস্টের আগে কেবিল তৈরি করছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'isolate', labelBn: 'সাপ্লাই বন্ধ করে কেবিল খুলে নেওয়া', asset: 'assets/game/art/m2_board27/prep_isolate.svg', scene: true, correct: true),
        LearnBoardOption(id: 'discharge', labelBn: 'স্টিক দিয়ে কেবিল ডিসচার্জ করা', asset: 'assets/game/art/m2_board27/prep_discharge.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'live',
          labelBn: 'চালু লাইনেই মেগার লাগানো',
          asset: 'assets/game/art/m2_board27/prep_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইভ লাইনে মেগার ব্যবহার কঠোরভাবে নিষিদ্ধ — আগে পাওয়ার সাপ্লাই থেকে সম্পূর্ণ বিচ্ছিন্ন করুন।',
        ),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'ভেজা কেবিলেই টেস্ট শুরু',
          asset: 'assets/game/art/m2_board27/prep_wet.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা বা আর্দ্র পরিবেশে ভুল আর কম রিডিং আসে — সরঞ্জাম আর চারপাশ যতটা সম্ভব শুকনো রাখুন।',
        ),
        LearnBoardOption(
          id: 'dirty',
          labelBn: 'ময়লা প্রান্তেই লিড লাগানো',
          asset: 'assets/game/art/m2_board27/prep_dirty.svg',
          scene: true,
          correct: false,
          rejectBn: 'ময়লা বা কার্বনের স্তর লিকেজ পাথ তৈরি করে আইআর কমিয়ে দেয় — পরীক্ষার আগে পরিষ্কার করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে সাপ্লাই থেকে পুরো বিচ্ছিন্ন করা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডিসচার্জ না করে মেগার লাগানো নিষিদ্ধ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লাইভ লাইনে মেগার কঠোরভাবে নিষিদ্ধ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চালু লাইনে মাপলে রিডিং আরও ঠিক আসে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নতুন কেবিলে ডিসচার্জের কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভেজা কেবিলেও রিডিং একদম একই রকম আসে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'টার্মিনালের ময়লায় আইআর-এ কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্লাভস থাকলে লাইভ কেবিলেও টেস্ট চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সময় বাঁচাতে সংযোগ রেখেই মাপা ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'connect',
      promptBn: 'মেগারের দুটো লিড কেবিলের কোথায় লাগাবেন?',
      options: [
        LearnBoardOption(id: 'right', labelBn: 'লাইন কন্ডাক্টরে, আর্থ আর্মারে', asset: 'assets/game/art/m2_board27/connect_right.svg', scene: true, correct: true),
        LearnBoardOption(id: 'set', labelBn: 'আর্থ লিড আর্মারে আটকানো', asset: 'assets/game/art/m2_board27/connect_set.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'same',
          labelBn: 'দুটো লিডই কন্ডাক্টরে',
          asset: 'assets/game/art/m2_board27/connect_same.svg',
          scene: true,
          correct: false,
          rejectBn: "'লাইন' লিড কন্ডাক্টরে, 'আর্থ' লিড কেবিলের আর্মারে — দুটো এক জায়গায় নয়।",
        ),
        LearnBoardOption(
          id: 'armour',
          labelBn: 'দুটো লিডই আর্মারে',
          asset: 'assets/game/art/m2_board27/connect_armour.svg',
          scene: true,
          correct: false,
          rejectBn: "'লাইন' লিড যায় কন্ডাক্টরে — দুটোই আর্মারে লাগালে ইনসুলেশন মাপাই হয় না।",
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'আর্থ লিড ঝুলিয়ে রেখে টেস্ট',
          asset: 'assets/game/art/m2_board27/connect_loose.svg',
          scene: true,
          correct: false,
          rejectBn: "মেগারের দুটো লিড — 'লাইন' আর 'আর্থ' — দুটোই সঠিক জায়গায় সংযুক্ত করুন।",
        ),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'টেস্টের সময় কন্ডাক্টর ধরা',
          asset: 'assets/game/art/m2_board27/connect_touch.svg',
          scene: true,
          correct: false,
          rejectBn: 'মেগার নিজেই উচ্চ ভোল্টেজের উৎস — টেস্টের সময় সরঞ্জামের খোলা অংশ ছোঁবেন না।',
        ),
      ],
      whyChips: [
        // Both safe cards are the same hook-up (Line on the conductor, Earth on
        // the armour), so every right reason fits either picture.
        LearnWhyChip(id: 'w1', textBn: 'লাইন লিড কন্ডাক্টরে, আর্থ লিড আর্মারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টেস্টের সময় খোলা অংশ ছোঁয়া চলবে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মেগার নিজেই উচ্চ ভোল্টেজের একটা উৎস', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দুটো লিড এক জায়গায় লাগালেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আর্থ লিড না লাগালেও রিডিং ঠিক আসে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মেগারের ভোল্টেজে হাত দিলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কোন লিড কোথায়, তাতে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কন্ডাক্টর ধরে রাখলে রিডিং স্থির থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আর্মারে কখনও লিড লাগাতে নেই, বিপদ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'read',
      promptBn: '1 মিনিট টেস্টের পর রিডিং — কোন কেবিল ব্যবহারে নিরাপদ?',
      options: [
        LearnBoardOption(id: 'high', labelBn: '850 MΩ — উঁচু রিডিং', asset: 'assets/game/art/m2_board27/read_high.svg', scene: true, correct: true),
        LearnBoardOption(id: 'giga', labelBn: '2.5 GΩ — গিগা-ওহম রিডিং', asset: 'assets/game/art/m2_board27/read_giga.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'low',
          labelBn: '0.5 MΩ — চালিয়ে দেওয়া',
          asset: 'assets/game/art/m2_board27/read_low.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণত 1 MΩ ন্যূনতম নিরাপদ মান — তার কম মানে ইনসুলেশন দুর্বল, ব্যবহারে নিরাপদ নয়।',
        ),
        LearnBoardOption(
          id: 'damp',
          labelBn: '0.3 MΩ — ভেজা কেবিল',
          asset: 'assets/game/art/m2_board27/read_damp.svg',
          scene: true,
          correct: false,
          rejectBn: '1 MΩ-এর কম — ইনসুলেশন আর্দ্র বা দুর্বল। এ কেবিল ব্যবহারের জন্য নিরাপদ নয়।',
        ),
        LearnBoardOption(
          id: 'crack',
          labelBn: '0.1 MΩ — ফাটা কেবিল',
          asset: 'assets/game/art/m2_board27/read_crack.svg',
          scene: true,
          correct: false,
          rejectBn: '1 MΩ-এর অনেক কম — ইনসুলেশন ক্ষতিগ্রস্ত। কম আইআর আসন্ন বড় ফল্টের আগাম সতর্কতা।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আইআর ভ্যালু যত বেশি, ইনসুলেশন তত ভালো', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সাধারণত 1 MΩ-ই ন্যূনতম নিরাপদ মান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শুকনো ভালো কেবিলে শত শত MΩ বা GΩ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আইআর যত কম, ইনসুলেশন তত মজবুত', correct: false),
        LearnWhyChip(id: 'w5', textBn: '1 MΩ-এর কম হলেও কেবিল চালানো যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রিডিং যা-ই আসুক, কেবিল একই রকম', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভেজা কেবিলের কম রিডিং ধরতে নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শূন্যের কাছে রিডিং মানে সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'একবার ভালো এলে আর মাপার দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'after',
      promptBn: 'টেস্ট শেষ, রিডিং নেওয়া হলো — এখন কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'discharge', labelBn: 'স্টিক দিয়ে আবার ডিসচার্জ', asset: 'assets/game/art/m2_board27/after_discharge.svg', scene: true, correct: true),
        LearnBoardOption(id: 'earth', labelBn: 'আর্থ লিডে কেবিল ডিসচার্জ', asset: 'assets/game/art/m2_board27/after_earth.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'সঙ্গে সঙ্গে কন্ডাক্টর ধরা',
          asset: 'assets/game/art/m2_board27/after_touch.svg',
          scene: true,
          correct: false,
          rejectBn: 'মেগারের টেস্ট ভোল্টেজ সরঞ্জামে চার্জ হয়ে জমে থাকতে পারে — আগে আবার ভালোভাবে ডিসচার্জ।',
        ),
        LearnBoardOption(
          id: 'pull',
          labelBn: 'ডিসচার্জ ছাড়াই লিড খোলা',
          asset: 'assets/game/art/m2_board27/after_pull.svg',
          scene: true,
          correct: false,
          rejectBn: 'টেস্টের পর কেবিলে চার্জ জমে থাকে — লিড খোলার আগে আবার ডিসচার্জ করতে ভুলবেন না।',
        ),
        LearnBoardOption(
          id: 'coil',
          labelBn: 'সোজা কেবিল গুটিয়ে তোলা',
          asset: 'assets/game/art/m2_board27/after_coil.svg',
          scene: true,
          correct: false,
          rejectBn: 'জমে থাকা চার্জ নিয়ে কেবিল হাতে তোলা বিপদ — টেস্টের পর আগে ডিসচার্জ, তারপর গোটানো।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টেস্ট ভোল্টেজ কেবিলে চার্জ হয়ে জমে থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টেস্টের পরও আবার ভালোভাবে ডিসচার্জ চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ডিসচার্জের আগে খোলা অংশ ছোঁয়া চলবে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মেগার বন্ধ হলেই কেবিল পুরো নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একবার আগে ডিসচার্জ করলেই তো যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গ্লাভস থাকলে চার্জে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিডিং নেওয়া শেষ, তাই কাজও পুরো শেষ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কম ভোল্টেজের কেবিলে চার্জ জমে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লিড তাড়াতাড়ি খুললে চার্জ চলে যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: MeggerBoardLines.rivalTaunt,
    rivalLineBn: MeggerBoardLines.rivalMyth,
    exitBn: MeggerBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'মাল্টিমিটারের ইনফিনিটিতে ভরসা',
      'মেগার ছাড়াই কেবিল চালু',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'মাল্টিমিটারের কম ভোল্টেজ ছোট ফাটল ধরতে পারে না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'উচ্চ ভোল্টেজের চাপে আর্দ্রতা লিকেজ পাথ গড়ে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'শুধু মেগারের চাপই ইনসুলেশনের আসল স্বাস্থ্য দেখায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ইনফিনিটি দেখালে ইনসুলেশন সবসময়ই নিখুঁত থাকে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'মাল্টিমিটার আর মেগার একই ভোল্টেজে মাপে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মেগার শুধু নতুন কেবিল পরীক্ষার জন্যই লাগে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের মাল্টিমিটার কখনও ভুল দেখায় না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ছোট ফাটল বা আর্দ্রতায় কোনো বিপদ হয় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: '9 ভোল্টে ঠিক থাকলে উচ্চ ভোল্টেজেও ঠিক থাকে', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. The taunt and the myth are new
/// (device TTS until recorded in his voice, `r_<sha1>.mp3` in
/// `learnRivalVoice`); the exit line is already recorded.
abstract final class MeggerBoardLines {
  static const rivalTaunt = 'আরে! মাল্টিমিটারেই তো ইনফিনিটি দেখাচ্ছে, আবার মেগারের ঝামেলা কেন?';

  /// Lesson 2.7's first myth buster, word for word.
  static const rivalMyth = "মাল্টিমিটার দিয়ে রেজিস্ট্যান্স মেপে যদি 'ইনফিনিটি' দেখায়, তার মানে ইনসুলেশন ঠিক আছে। মেগারের দরকার নেই।";

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// The new clips this board needs recorded.
  static const toRecord = [rivalTaunt, rivalMyth];
}
