import 'learn_board_models.dart';

/// Module 5 Lesson 5.6 (শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই ভিন্ন শত্রু),
/// the picture board (rung `5.6/learn`, pack `learn_5_6`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board56_art.py`. Every round
/// and every trap comes from the lesson text:
///  * short: a very low-resistance path between conductors at different
///    voltages — two wires slapping, a fallen branch, a bird across two wires;
///    its signs are a huge current, a big arc flash, a bang and burn marks.
///    The traps are open circuits (a jumper open, a connector apart, one phase
///    of a pump off — single-phasing);
///  * open: the path is broken — a wire or jumper off, a joint or connector
///    apart, a fuse blown; the power stops with no arc or bang. The traps show
///    a flash, a blackened end after a bang, a branch across two wires;
///  * fallen: pro tip 1 — a broken wire on the ground is never safe, always
///    treat it as live; it can turn live through anything conductive it
///    touches. Dry wood is a semi-conductor (pro tip 3); the two broken ends
///    carry the full system voltage between them (the myth). Keeping people
///    away is the ruling M5-5 duty; no distance is shown (that comes from 5.2);
///  * single: pro tip 2 — one of the three phases open; a three-phase motor
///    groans or will not run, and is badly damaged;
///  * hidden: pro tip 3 — a high-resistance short through dry wood or a weak
///    contact: little fault current, the fuse or breaker does not operate, a
///    big cause of fires. The smoke wisp is an illustration. The traps are an
///    ordinary short (big flash, fuse dropped), open circuits (a jumper open
///    with the houses dark, a joint apart on one phase) and a clean span.
/// The rival's myth is the lesson's second myth buster, word for word.
const learnBoardPack56 = LearnBoardPack(
  lessonId: '5.6',
  titleBn: 'শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই ভিন্ন শত্রু',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'দুই শত্রু — শর্ট সার্কিট আর ওপেন সার্কিট। লক্ষণ দেখে চিনুন, কে কোন শত্রু।',
  earnedBn: 'শর্ট মানে ঝলক আর প্রচণ্ড কারেন্ট, ওপেন মানে পথ ভাঙা — আর ছেঁড়া তার সবসময় লাইভ।',
  slots: [
    LearnBoardSlot(
      id: 'short',
      promptBn: 'কোন ছবিতে শর্ট সার্কিট?',
      options: [
        LearnBoardOption(
          id: 'slap',
          labelBn: 'দুটো তার ঠোকাঠুকি, বড় ঝলক',
          asset: 'assets/game/art/m5_board56/short_slap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'ডাল পড়ে দুই তার জোড়া, ঝলক',
          asset: 'assets/game/art/m5_board56/short_branch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bird',
          labelBn: 'দুই তারে পাখি, ঝলক আর পোড়া দাগ',
          asset: 'assets/game/art/m5_board56/short_bird.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'jumper',
          labelBn: 'জাম্পার খুলে ঝুলছে, বাতি নেভা',
          asset: 'assets/game/art/m5_board56/short_jumper.svg',
          scene: true,
          correct: false,
          rejectBn: 'জাম্পার খুলে যাওয়া ওপেন সার্কিট — পথ ভেঙেছে, ঝলক নেই।',
        ),
        LearnBoardOption(
          id: 'connector',
          labelBn: 'কানেক্টর খুলে তার দুই ভাগ',
          asset: 'assets/game/art/m5_board56/short_connector.svg',
          scene: true,
          correct: false,
          rejectBn: 'জয়েন্ট বা কানেক্টর খুলে গেলে পথ ভাঙে — এটা ওপেন সার্কিট।',
        ),
        LearnBoardOption(
          id: 'pump',
          labelBn: 'পাম্প ঘরের একটা ফেজ খোলা',
          asset: 'assets/game/art/m5_board56/short_pump.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটা ফেজ বিচ্ছিন্ন — এটা সিঙ্গেল-ফেজিং, এক ধরনের ওপেন সার্কিট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দুই পরিবাহীর মাঝে খুব কম রেজিস্ট্যান্সের পথ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শর্টে প্রচণ্ড কারেন্ট আর বড় আর্ক ফ্ল্যাশ হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঝলক, বিস্ফোরণের শব্দ, পোড়া দাগ শর্টের লক্ষণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শর্ট মানে তারের পথ ভেঙে কারেন্ট বন্ধ হওয়া', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শর্ট সার্কিটে কারেন্ট একদম শূন্য হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝলক ছাড়া চুপচাপ বাতি নিভলেই শর্ট সার্কিট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পাখি দুই তারে ছুঁলেও কোনো ফল্ট হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ডাল পড়লে শুধু তার ছেঁড়ে, শর্ট ঘটায় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'শর্টের জায়গায় ভোল্টেজ সবচেয়ে বেশি থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'open',
      promptBn: 'কোন ছবিতে ওপেন সার্কিট?',
      options: [
        LearnBoardOption(
          id: 'jumper',
          labelBn: 'জাম্পার ঢিলে হয়ে খুলে গেছে',
          asset: 'assets/game/art/m5_board56/open_jumper.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'connector',
          labelBn: 'কানেক্টর খুলে পথ ভেঙেছে',
          asset: 'assets/game/art/m5_board56/open_connector.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'ফিউজ তার ছিঁড়ে বাড়ি অন্ধকার',
          asset: 'assets/game/art/m5_board56/open_fuse.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'দুটো তার ঠেকে বড় ঝলক',
          asset: 'assets/game/art/m5_board56/open_touch.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুটো তার ঠোকাঠুকি শর্ট সার্কিট — প্রচণ্ড কারেন্ট, বড় ঝলক।',
        ),
        LearnBoardOption(
          id: 'burnt',
          labelBn: 'বিকট শব্দ, কেবিলের মাথা পোড়া',
          asset: 'assets/game/art/m5_board56/open_burnt.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোড়া দাগ আর বিস্ফোরণের মতো শব্দ — শর্ট সার্কিটের লক্ষণ।',
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'গাছের ডাল দুই তারে, ঝলক',
          asset: 'assets/game/art/m5_board56/open_branch.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল পড়ে দুই তার জুড়ে ঝলক — এটা শর্ট সার্কিট, ওপেন নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পরিবাহী পথ ভেঙে গেলে প্রবাহ বন্ধ হয়ে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ওপেনে প্রবাহ বন্ধ, কিন্তু আর্ক বা শব্দ নেই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জয়েন্ট খোলা, তার ছেঁড়া, ফিউজ ওড়া — সবই ওপেন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ওপেন সার্কিটে কারেন্ট শূন্য হয়ে যায়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'ওপেন সার্কিটে প্রচণ্ড কারেন্ট বয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ওপেন সার্কিট মানেই বড় ঝলক আর বিকট শব্দ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পোড়া দাগ দেখলেই বুঝবেন ওপেন সার্কিট', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পথ ভাঙলেও কারেন্ট আগের মতোই চলতে থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'জাম্পার খুললে দুই তার জুড়ে শর্ট হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fallen',
      promptBn: 'ছেঁড়া তার মাটিতে, গলিতে আলো নেই — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'child',
          labelBn: 'শিশুকে তারের দিকে যেতে না দেওয়া',
          asset: 'assets/game/art/m5_board56/fallen_child.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cyclist',
          labelBn: 'সাইকেল আরোহীকে থামিয়ে দেওয়া',
          asset: 'assets/game/art/m5_board56/fallen_cyclist.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে ছেঁড়া তার তুলে ধরা',
          asset: 'assets/game/art/m5_board56/fallen_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছেঁড়া তার মাটিতে পড়ে থাকা মানেই নিরাপদ নয় — সবসময় লাইভ ধরুন।',
        ),
        LearnBoardOption(
          id: 'bamboo',
          labelBn: 'শুকনো বাঁশে তার ঠেলে সরানো',
          asset: 'assets/game/art/m5_board56/fallen_bamboo.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুকনো কাঠও অর্ধ-পরিবাহী — লাইভ তারে ঠেকানো চলে না।',
        ),
        LearnBoardOption(
          id: 'join',
          labelBn: 'ছেঁড়া দুই মাথা হাতে জোড়া',
          asset: 'assets/game/art/m5_board56/fallen_join.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুই মাথার মাঝে পুরো সিস্টেম ভোল্টেজ — জুড়তে গেলে মারাত্মক শক।',
        ),
        LearnBoardOption(
          id: 'fence',
          labelBn: 'তার পড়া বেড়ায় কাপড় মেলা',
          asset: 'assets/game/art/m5_board56/fallen_fence.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছেঁড়া তার সবসময় লাইভ ধরুন — তার ছুঁয়ে থাকা বেড়াও ছোঁয়া চলে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ছেঁড়া তার মাটিতে থাকলেও সবসময় লাইভ ধরুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পরিবাহী কিছুতে ঠেকলে তার লাইভ হতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লোকজনকে ছেঁড়া তার থেকে দূরে রাখাই আগে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আলো নেই মানে ছেঁড়া তারে কারেন্টও নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শুকনো বাঁশ দিয়ে ঠেললে কোনো বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ছেঁড়া দুই মাথা জুড়ে দিলেই আলো ফিরবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মাটিতে পড়া তার নিজে থেকেই ডেড হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লোকজন নিজেরাই বুঝে তার থেকে দূরে থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বেড়ায় পড়া তারে কাপড় মেলায় ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'single',
      promptBn: 'কোন ছবিতে সিঙ্গেল-ফেজিং?',
      options: [
        LearnBoardOption(
          id: 'onewire',
          labelBn: 'তিনটির একটা তার খোলা, মোটর গোঙাচ্ছে',
          asset: 'assets/game/art/m5_board56/single_onewire.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'onejumper',
          labelBn: 'একটা জাম্পার খোলা, পাম্প থেমে গেছে',
          asset: 'assets/game/art/m5_board56/single_onejumper.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'allok',
          labelBn: 'তিন ফেজই জোড়া, জল পড়ছে',
          asset: 'assets/game/art/m5_board56/single_allok.svg',
          scene: true,
          correct: false,
          rejectBn: 'তিন ফেজই জোড়া, পাম্প চলছে — কোনো ফল্ট নেই।',
        ),
        LearnBoardOption(
          id: 'flash',
          labelBn: 'দুই ফেজ ঠেকে ঝলক',
          asset: 'assets/game/art/m5_board56/single_flash.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঝলক আর প্রচণ্ড কারেন্ট — এটা শর্ট সার্কিট।',
        ),
        LearnBoardOption(
          id: 'allopen',
          labelBn: 'তিনটি জাম্পারই খোলা',
          asset: 'assets/game/art/m5_board56/single_allopen.svg',
          scene: true,
          correct: false,
          rejectBn: 'সিঙ্গেল-ফেজিং মানে তিনটির মধ্যে একটি ফেজ বিচ্ছিন্ন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'থ্রি-ফেজের তিনটির একটি ফেজ বিচ্ছিন্ন হয়েছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এক ফেজ ওপেনে মোটর শব্দ করে বা চলে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সিঙ্গেল-ফেজিং মোটরকে মারাত্মক ক্ষতি করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সিঙ্গেল-ফেজিং এক ধরনের ওপেন সার্কিট', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'তিন ফেজ খুলে গেলেই সিঙ্গেল-ফেজিং হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'এক ফেজ না থাকলেও মোটর আগের মতো ঠিক চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সিঙ্গেল-ফেজিং মানে দুই ফেজের ঠোকাঠুকি', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মোটরের গোঙানি শুধু পুরনো মোটরের দোষ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সিঙ্গেল-ফেজিংয়ে মোটরের কোনো ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hidden',
      promptBn: 'কোথায় লুকোনো শর্ট — ফিউজ পড়েনি, তবু ফল্ট?',
      options: [
        LearnBoardOption(
          id: 'branch',
          labelBn: 'শুকনো ডাল তারে, হালকা ধোঁয়া',
          asset: 'assets/game/art/m5_board56/hidden_branch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'awning',
          labelBn: 'ছাউনির বাঁশ তারে ঠেকে, ধোঁয়া',
          asset: 'assets/game/art/m5_board56/hidden_awning.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bigflash',
          labelBn: 'বড় ঝলক, ডিও ফিউজ খুলে পড়েছে',
          asset: 'assets/game/art/m5_board56/hidden_bigflash.svg',
          scene: true,
          correct: false,
          rejectBn: 'বড় ঝলক, ফিউজ উড়েছে — এটা সাধারণ শর্ট, সুরক্ষা কাজ করেছে।',
        ),
        LearnBoardOption(
          id: 'open',
          labelBn: 'জাম্পার খোলা, বাড়িতে আলো নেই',
          asset: 'assets/game/art/m5_board56/hidden_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'আলো নেই, পথ ভাঙা — এটা ওপেন সার্কিট।',
        ),
        LearnBoardOption(
          id: 'joint',
          labelBn: 'জয়েন্ট খুলে এক তার দুই ভাগ',
          asset: 'assets/game/art/m5_board56/hidden_joint.svg',
          scene: true,
          correct: false,
          rejectBn: 'জয়েন্ট খুলে পথ ভেঙেছে — এটা ওপেন সার্কিট, শর্ট নয়।',
        ),
        LearnBoardOption(
          id: 'clean',
          labelBn: 'পরিষ্কার স্প্যান, গাছ দূরে',
          asset: 'assets/game/art/m5_board56/hidden_clean.svg',
          scene: true,
          correct: false,
          rejectBn: 'কিছুই তারে ঠেকে নেই — ফল্টের ছাপ নেই।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শুকনো কাঠের মতো অর্ধ-পরিবাহী দিয়েও শর্ট হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এমন ফল্টে কারেন্ট কম, ফিউজ-ব্রেকার কাজ করে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'উচ্চ রেজিস্ট্যান্স ফল্ট আগুন লাগার বড় কারণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফিউজ না উড়লে লাইনে কোনো ফল্ট থাকে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শুকনো ডাল ইনসুলেটর, তারে ঠেকলেও কিছু না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাড়িতে আলো জ্বললে লাইন পুরো ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দুর্বল সংযোগে কখনো শর্ট সার্কিট হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বড় ঝলক না হলে কোনো শর্ট সার্কিট হয়নি', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্রেকার সব ফল্টেই সঙ্গে সঙ্গে ট্রিপ করে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board56Lines.rivalTaunt,
    rivalLineBn: M5Board56Lines.rivalMyth,
    exitBn: M5Board56Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    // The kit's default flip line is an either/or question that calls him lazy:
    // হ্যাঁ/না cannot answer it and it gives the answer away.
    flipStingBn: 'এই লোক যা বলছে… সেটা কি ভুল?',
    // Prompts that point at the danger without stating the rebuttal.
    dangerHints: [
      'বিদ্যুৎ বন্ধ — তাই নিরাপদ?',
      'ছেঁড়া তার — সত্যি ডেড?',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ছেঁড়া দুই মাথার মাঝে পুরো সিস্টেম ভোল্টেজ থাকে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'দুই মাথার মাঝে এলে সার্কিট পূর্ণ হয়ে মারাত্মক শক', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ওপেন সার্কিটের ছেঁড়া তারও সবসময় লাইভ ধরুন', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'বাতি নিভে গেলে তারে কোনো ভোল্টেজ থাকে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ওপেন সার্কিটে বিদ্যুৎ বন্ধ, তাই ছোঁয়া নিরাপদ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ছেঁড়া তার মাটিতে পড়লে নিজেই ডেড হয়ে যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'শুধু শর্ট সার্কিটই বিপজ্জনক, ওপেন কখনো নয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অভিজ্ঞ লোক ছেঁড়া তার খালি হাতে ধরতে পারে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'দুই মাথা জুড়ে দিলে কোনো ঝুঁকি থাকে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M5Board56Lines {
  static const rivalTaunt = 'আরে, তার তো ছেঁড়া! কারেন্ট আসবে কোথা থেকে?';

  /// Lesson 5.6's second myth buster, word for word.
  static const rivalMyth = 'একটি ওপেন সার্কিটে কোনো বিপদ নেই কারণ বিদ্যুৎ তো বন্ধই আছে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
