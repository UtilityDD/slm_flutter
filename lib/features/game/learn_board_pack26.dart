import 'learn_board_models.dart';

/// Module 2 Lesson 2.6 (কেবিল স্কিনিং-এর শিল্প), the picture board
/// (rung `2.6/learn`, pack `learn_2_6`, played by the learn board runner).
///
/// Picture cards are vector scenes from `tool/m2_board26_art.py`. Every round
/// and every trap comes from the lesson text:
///  * tool: the cable skinning knife (its blade cuts insulation, not the
///    conductor) and the wire stripper; an ordinary knife is "a deadly
///    mistake"; a blunt tool needs extra force and slips onto the hand or the
///    conductor; the daily check: the blade sharp and clean; teeth (the
///    lesson's second myth) damage teeth and conductor;
///  * stroke: the 'pencil sharpening' technique — a slight angle, the thumb
///    on the blunt back, cut away from the body, never towards it; never cut
///    round (a ring mark on the conductor); cut-resistant gloves always;
///  * length: strip to the crimping lug / terminal barrel's length, measured
///    first — not too long, not too short;
///  * inspect: the conductor smooth and bright, no deep nick, black mark or
///    cut strand; the insulation edge smooth and at 90°, not torn or uneven;
///  * ab: AB cable insulation is much harder — the special stripping tool;
///    start light (a groove first, then more pressure); in very cold weather
///    insulation goes hard and brittle and cracks easily.
/// The rival's myth is the lesson's first: a small nick on the conductor
/// "does nothing, crimping puts it right" (the nick is a hotspot and the
/// wire breaks there under vibration).
const learnBoardPack26 = LearnBoardPack(
  lessonId: '2.6',
  titleBn: 'কেবিল স্কিনিং-এর শিল্প',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'ইনসুলেশন তারের বর্ম, কন্ডাক্টর তার আত্মা — বর্ম সরান, আত্মা অক্ষত রাখুন।',
  earnedBn: 'সঠিক টুল, বাইরের দিকে টান, মাপমতো দৈর্ঘ্য — মসৃণ কন্ডাক্টরেই নিখুঁত সংযোগ।',
  slots: [
    LearnBoardSlot(
      id: 'tool',
      promptBn: 'কেবিলের ইনসুলেশন ছিলবেন — কোন হাতিয়ার ঠিক?',
      options: [
        LearnBoardOption(id: 'skinning', labelBn: 'কেবিল স্কিনিং নাইফ', asset: 'assets/game/art/m2_board26/tool_skinning.svg', scene: true, correct: true),
        LearnBoardOption(id: 'stripper', labelBn: 'মাপমতো ওয়্যার স্ট্রিপার', asset: 'assets/game/art/m2_board26/tool_stripper.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'kitchen',
          labelBn: 'সাধারণ ছুরি দিয়ে ছেলা',
          asset: 'assets/game/art/m2_board26/tool_kitchen.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ ছুরি মারাত্মক ভুল — কন্ডাক্টরে আঁচড় বা নিক পড়ে, সেখানে হটস্পট হয়।',
        ),
        LearnBoardOption(
          id: 'blunt',
          labelBn: 'ভোঁতা কাটারে জোর দিয়ে কাটা',
          asset: 'assets/game/art/m2_board26/tool_blunt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভোঁতা হাতিয়ারে অতিরিক্ত বল লাগে — সহজেই পিছলে হাতে বা কন্ডাক্টরে লাগে।',
        ),
        LearnBoardOption(
          id: 'rusty',
          labelBn: 'মরচে ধরা নোংরা ব্লেড',
          asset: 'assets/game/art/m2_board26/tool_rusty.svg',
          scene: true,
          correct: false,
          rejectBn: 'রোজ দেখে নিন ব্লেড ধারালো আর পরিষ্কার কিনা — ভোঁতা, নোংরা ব্লেড বিপজ্জনক।',
        ),
        LearnBoardOption(
          id: 'teeth',
          labelBn: 'দাঁত দিয়ে ইনসুলেশন ছেলা',
          asset: 'assets/game/art/m2_board26/tool_teeth.svg',
          scene: true,
          correct: false,
          rejectBn: 'দাঁতে ছিলানো বিপজ্জনক, অপেশাদার অভ্যাস — দাঁত আর কন্ডাক্টর দুটোরই ক্ষতি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সঠিক টুল ইনসুলেশন কাটে, কন্ডাক্টরকে নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভুল বা ভোঁতা টুল পিছলে হাতে-তারে লাগে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কন্ডাক্টরে নিক মানে দুর্বল জায়গা, হটস্পট', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যে-কোনো ধারালো ছুরিতেই কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছোট তার দাঁতে ছিললেই সবচেয়ে দ্রুত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভোঁতা ব্লেডে জোর দিলেই কাটা ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্লেডে মরচে থাকলেও কাটায় কোনো ফারাক নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্ট্রিপার শুধু নতুন কর্মীদের জন্য দরকার', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কন্ডাক্টরে একটু আঁচড় লাগলে ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'stroke',
      promptBn: 'ছুরিতে ইনসুলেশন ছিলছেন — কোন টান ঠিক?',
      options: [
        LearnBoardOption(id: 'away', labelBn: 'সামান্য কোণে, শরীরের বাইরে ঠেলা', asset: 'assets/game/art/m2_board26/stroke_away.svg', scene: true, correct: true),
        LearnBoardOption(id: 'thumb', labelBn: 'বুড়ো আঙুলে ভোঁতা দিকে সাপোর্ট', asset: 'assets/game/art/m2_board26/stroke_thumb.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'toward',
          labelBn: 'ছুরি নিজের দিকে টানা',
          asset: 'assets/game/art/m2_board26/stroke_toward.svg',
          scene: true,
          correct: false,
          rejectBn: 'কখনোই নিজের দিকে টানবেন না — শরীর থেকে বাইরের দিকে কাটলে মারাত্মক আঘাত এড়ায়।',
        ),
        LearnBoardOption(
          id: 'round',
          labelBn: 'তারের চারপাশে গোল করে কাটা',
          asset: 'assets/game/art/m2_board26/stroke_round.svg',
          scene: true,
          correct: false,
          rejectBn: 'গোল করে কাটবেন না — কন্ডাক্টরের ওপর রিং-এর মতো দাগ পড়ে।',
        ),
        LearnBoardOption(
          id: 'steep',
          labelBn: 'ব্লেড খাড়া করে চেপে কাটা',
          asset: 'assets/game/art/m2_board26/stroke_steep.svg',
          scene: true,
          correct: false,
          rejectBn: 'পেন্সিল ছোলার মতো সামান্য কোণে রাখুন — খাড়া ব্লেড কন্ডাক্টরে আঁচড় কাটে।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে ছুরি চালানো',
          asset: 'assets/game/art/m2_board26/stroke_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'সর্বদা কাটা-রোধী গ্লাভস পরে এই কাজ করুন — খালি হাতে ছুরি পিছলালেই কাটবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শরীরের বাইরের দিকে কাটলে আঘাত এড়ানো যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সামান্য কোণে ব্লেড কন্ডাক্টর ছোঁয় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পেন্সিল ছোলার মতো নিয়ন্ত্রিত চাপে কাটা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নিজের দিকে টানলে কাটায় জোর বেশি পাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গোল করে কাটলে ইনসুলেশন তাড়াতাড়ি খোলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ব্লেড খাড়া রাখলে কাটা বেশি পরিষ্কার হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'খালি হাতে ছুরি ধরলে নিয়ন্ত্রণ ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কন্ডাক্টরে রিং-দাগ পড়লে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যেদিকে সুবিধা সেদিকে টানলেই কাজ হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'length',
      promptBn: 'তারে ক্রিম্পিং ল্যাগ লাগবে — কতটা ছিলবেন?',
      options: [
        LearnBoardOption(id: 'match', labelBn: 'ল্যাগের ব্যারেলের সমান দৈর্ঘ্য', asset: 'assets/game/art/m2_board26/length_match.svg', scene: true, correct: true),
        LearnBoardOption(id: 'measure', labelBn: 'আগে ব্যারেল মেপে দাগ দেওয়া', asset: 'assets/game/art/m2_board26/length_measure.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'long',
          labelBn: 'ব্যারেলের চেয়ে অনেক বেশি ছেলা',
          asset: 'assets/game/art/m2_board26/length_long.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যারেলের দৈর্ঘ্য অনুযায়ী ছিলুন — খুব বেশি নয়, খোলা কন্ডাক্টর বেরিয়ে থাকে।',
        ),
        LearnBoardOption(
          id: 'short',
          labelBn: 'ব্যারেলের চেয়ে কম ছেলা',
          asset: 'assets/game/art/m2_board26/length_short.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যারেলের দৈর্ঘ্য অনুযায়ী ছিলুন — খুব কম নয়, কন্ডাক্টর পুরো ঢোকে না।',
        ),
        LearnBoardOption(
          id: 'guess',
          labelBn: 'না মেপে আন্দাজে কাটা',
          asset: 'assets/game/art/m2_board26/length_guess.svg',
          scene: true,
          correct: false,
          rejectBn: 'সংযোগের জন্য প্রয়োজনীয় দৈর্ঘ্য আগে মেপে নিন — আন্দাজে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ল্যাগের ব্যারেল যতটা, ততটাই ছিলতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'খুব বেশি বা খুব কম ছেলা — দুটোই ভুল', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাটার আগে প্রয়োজনীয় দৈর্ঘ্য মেপে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বেশি ছিললে পরে কাজে সুবিধা হয় সবসময়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'অল্প ছিললেও ক্রিম্পে সব ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অভিজ্ঞ হাতে মাপার কোনো দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'খোলা কন্ডাক্টর বেরিয়ে থাকলে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ব্যারেলের মাপ দেখা শুধু সময় নষ্ট করা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যতটা খুশি ছিলুন, ল্যাগ ঠিকই এঁটে যাবে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'inspect',
      promptBn: 'ছেলা শেষ — কোন কন্ডাক্টরে সংযোগ দেওয়া চলে?',
      options: [
        LearnBoardOption(id: 'copper', labelBn: 'মসৃণ, উজ্জ্বল কন্ডাক্টর', asset: 'assets/game/art/m2_board26/inspect_copper.svg', scene: true, correct: true),
        LearnBoardOption(id: 'solid', labelBn: '90° কোণে মসৃণ কাটা প্রান্ত', asset: 'assets/game/art/m2_board26/inspect_solid.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'nick',
          labelBn: 'কন্ডাক্টরে গভীর আঁচড়',
          asset: 'assets/game/art/m2_board26/inspect_nick.svg',
          scene: true,
          correct: false,
          rejectBn: 'গভীর আঁচড় বা নিক তারের যান্ত্রিক শক্তি কমায়, ওই বিন্দুতে হটস্পট তৈরি করে।',
        ),
        LearnBoardOption(
          id: 'black',
          labelBn: 'কন্ডাক্টরে কালো দাগ',
          asset: 'assets/game/art/m2_board26/inspect_black.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ডাক্টরের পৃষ্ঠে কোনো কালো দাগ থাকা উচিত নয় — মসৃণ ও উজ্জ্বল চাই।',
        ),
        LearnBoardOption(
          id: 'strand',
          labelBn: 'স্ট্র্যান্ড কেটে বেরিয়ে আছে',
          asset: 'assets/game/art/m2_board26/inspect_strand.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাটা স্ট্র্যান্ড থাকা চলবে না — কন্ডাক্টর কমে যায়, সংযোগ দুর্বল হয়।',
        ),
        LearnBoardOption(
          id: 'torn',
          labelBn: 'ছেঁড়া, অসম ইনসুলেশন প্রান্ত',
          asset: 'assets/game/art/m2_board26/inspect_torn.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেশনের কাটা প্রান্ত মসৃণ, 90-ডিগ্রী কোণে চাই — ছেঁড়া বা অসম নয়।',
        ),
      ],
      whyChips: [
        // Both safe cards are the same good result (one shows the bright
        // stranded surface, one the square edge), so every right reason fits.
        LearnWhyChip(id: 'w1', textBn: 'পৃষ্ঠ মসৃণ আর উজ্জ্বল — আঁচড় বা দাগ নেই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ইনসুলেশনের প্রান্ত মসৃণ, 90° কোণে কাটা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিখুঁত স্কিনিং-ই টেকসই সংযোগের প্রথম ধাপ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কালো দাগ থাকলে তারের জোর আরও বাড়ে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দু-একটা স্ট্র্যান্ড কাটা গেলে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ইনসুলেশনের প্রান্ত ছেঁড়া হলেও কাজ চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আঁচড় সামান্য হলে ক্রিম্পে ঢাকা পড়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাজ শেষে পরিদর্শন শুধু সময়ের অপচয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রিং-দাগ থাকলে তার আরও শক্ত করে ধরে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ab',
      promptBn: 'এবি কেবিলের শক্ত ইনসুলেশন ছিলবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'tool', labelBn: 'এবি কেবিলের বিশেষ স্ট্রিপিং টুল', asset: 'assets/game/art/m2_board26/ab_tool.svg', scene: true, correct: true),
        LearnBoardOption(id: 'light', labelBn: 'আগে হালকা খাঁজ, পরে চাপ', asset: 'assets/game/art/m2_board26/ab_light.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'force',
          labelBn: 'সাধারণ ছুরিতে গায়ের জোরে কাটা',
          asset: 'assets/game/art/m2_board26/ab_force.svg',
          scene: true,
          correct: false,
          rejectBn: 'এবি কেবিলের ইনসুলেশন অনেক বেশি শক্ত — জোর দিলে ছুরি পিছলে হাতে লাগে। বিশেষ টুল নিন।',
        ),
        LearnBoardOption(
          id: 'cold',
          labelBn: 'কনকনে ঠান্ডায় জোরে বাঁকানো',
          asset: 'assets/game/art/m2_board26/ab_cold.svg',
          scene: true,
          correct: false,
          rejectBn: 'খুব ঠান্ডায় ইনসুলেশন শক্ত আর ভঙ্গুর হয়, সহজেই ফেটে যায় — সাবধানে কাজ করুন।',
        ),
        LearnBoardOption(
          id: 'oneshot',
          labelBn: 'প্রথম টানেই পুরো ইনসুলেশন কাটা',
          asset: 'assets/game/art/m2_board26/ab_oneshot.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রথমবারে পুরো ইনসুলেশন কাটার চেষ্টা নয় — আগে হালকা খাঁজ, তারপর ধীরে চাপ।',
        ),
        LearnBoardOption(
          id: 'blunt',
          labelBn: 'ভোঁতা ছুরিতে শক্ত ইনসুলেশন',
          asset: 'assets/game/art/m2_board26/ab_blunt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভোঁতা ব্লেড বিপজ্জনক — শক্ত ইনসুলেশনে অতিরিক্ত বল লাগে, পিছলে কন্ডাক্টরে লাগে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'এবি কেবিলের ইনসুলেশন সাধারণের চেয়ে শক্ত', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হালকা হাতে শুরু করে ধীরে ধীরে চাপ বাড়ান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জোর কম লাগলে ব্লেড পিছলানোর ঝুঁকিও কম', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শক্ত ইনসুলেশন এক টানে কাটাই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঠান্ডায় ইনসুলেশন নরম হয়, তাই ফাটে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সাধারণ ছুরিতে জোর দিলেই এবি কেবিল কাটে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বিশেষ টুল শুধু অফিসের লোকের দেখানোর জিনিস', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সব কেবিলের ইনসুলেশন একই রকম নরম হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ভোঁতা ছুরিতে চেপে ধরলেই কাটা মসৃণ হয়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: SkinBoardLines.rivalTaunt,
    rivalLineBn: SkinBoardLines.rivalMyth,
    exitBn: SkinBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'আঁচড় পড়া কন্ডাক্টরে ক্রিম্পিং',
      'নিক থেকে হটস্পট আর তার ছেঁড়া',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'আঁচড়ের বিন্দুতে কন্ডাক্টরের এরিয়া কমে যায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'রেজিস্ট্যান্স বেড়ে ওখানেই হটস্পট তৈরি হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'কম্পনে তার ওই দুর্বল জায়গা থেকেই ছেঁড়ে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ক্রিম্পিং-এর চাপে আঁচড় নিজেই মিলিয়ে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'সামান্য আঁচড়ে কারেন্টের কোনো ফারাক নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'আঁচড় ল্যাগের ভেতরে ঢাকা পড়লে নিরাপদ', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'মোটা তারে ছোট নিক কোনো ক্ষতিই করে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'আঁচড় পড়লে তার বরং আরও শক্ত হয়ে যায়', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. The exit line is already
/// recorded (`learnRivalVoice`); the taunt and the myth are new and play
/// through device TTS until they are recorded ([toRecord]).
abstract final class SkinBoardLines {
  static const rivalTaunt = 'আরে! এত মাপজোক কীসের? ছুরি চালান, কাজ শেষ করুন।';

  /// Lesson 2.6's first myth buster, word for word.
  static const rivalMyth = 'কন্ডাক্টরের ওপর সামান্য আঁচড় লাগলে কিছু হয় না, ক্রিম্পিং-এর পর সব ঠিক হয়ে যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New clips this board needs recorded in the rival's voice.
  static const toRecord = [rivalTaunt, rivalMyth];
}
