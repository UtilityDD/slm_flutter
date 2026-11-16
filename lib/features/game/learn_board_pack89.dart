import 'learn_board_models.dart';

/// Module 8 Lesson 8.9 (পরিবেশগত নিয়মাবলী: রাজ্যের দৃষ্টিকোণ), the picture
/// board (rung `8.9/learn`, pack `learn_8_9`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board89_art.py` (no words in
/// the art). Five rounds (ruling M8-21: the pre-monsoon round left the board),
/// each with two safe pictures and three or four traps. Every round and trap
/// comes from the live lesson 8.9 text (`tool/all_training_chapters_bn.json`)
/// and the Module 8 rulings (`docs/module_specs/module8_rulings.md`, item spec
/// `docs/module_specs/module8_items/board_89.json`):
///  * trim: prune only the branch resting on the 11 kV conductor, under a
///    shutdown with the earth set; the trunk is never felled, the nest is
///    left, and no branch is cut with the line live (live pro tip and daily
///    check: 'শাটডাউন নিয়ে ডাল কাটার সময়');
///  * permit: a stamped written permission from the Forest Department or the
///    Panchayat or Municipality before any whole tree comes down (lesson
///    myth 2 reality; the trim-or-fell line of the first section);
///  * oil: old transformer oil may hold PCBs: plastic sheet under the work,
///    গ্লাভস and mask, capped drums to a disposal centre (advanced section,
///    ruling M8-6: a slip, the harm is long-term);
///  * leak: sand or sawdust on a leaking drum, never water (pro tip 2);
///  * scrap: old lead-acid batteries only to an authorised recycler, wire
///    offcuts never left in the grass (pro tip 3, section 2).
/// The rival's myth is the lesson's first myth, word for word (ruling M8-14:
/// it needs a clip). Its reality is the lesson's own.
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// English letters for LT, HT, 11 kV and kVA; PCBs in English; ON / OFF for
/// states. No YouTube explainer id (ruling M6-14, owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack89 = LearnBoardPack(
  lessonId: '8.9',
  titleBn: 'পরিবেশগত নিয়মাবলী: রাজ্যের দৃষ্টিকোণ',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'গাছের ডাল, পোড়া তেল আর বাতিল ব্যাটারি। নিয়ম মেনে কাজ করুন, পরিবেশও বাঁচান।',
  earnedBn: 'শাটডাউন নিয়ে শুধু বিপদের ডাল ছাঁটুন; পুরনো তেল ড্রামে সিল করে পাঠান, ব্যাটারি দিন অথরাইজড রিসাইক্লারকে।',
  slots: [
    LearnBoardSlot(
      id: 'trim',
      promptBn: 'শাটডাউনে লাইনের ধারের গাছ — কোন ছবির কাজটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'touch',
          labelBn: 'শাটডাউনে আর্থিং, শুধু তারে ঠেকা ডাল ছাঁটা',
          asset: 'assets/game/art/m8_board89/trim_touch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nest',
          labelBn: 'পোল-প্রুনারে তারের ডাল ছাঁটা, বাসা রেখে দেওয়া',
          asset: 'assets/game/art/m8_board89/trim_nest.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fell',
          labelBn: 'করাত দিয়ে পুরো গাছের গুঁড়ি কেটে ফেলা',
          asset: 'assets/game/art/m8_board89/trim_fell.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরো গাছ কাটার অধিকার আমাদের নেই — অনুমতি ছাড়া কাটলে আইনি মামলা হতে পারে।',
        ),
        LearnBoardOption(
          id: 'nestcut',
          labelBn: 'বাসাসহ ডাল কেটে ফেলা, ডাল নিচে পড়ছে',
          asset: 'assets/game/art/m8_board89/trim_nestcut.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল কাটার সময় খেয়াল রাখুন — পাখির বাসা যেন নষ্ট না হয়।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'লাইনের দূরের ডালও সব ছেঁটে ফেলা হচ্ছে',
          asset: 'assets/game/art/m8_board89/trim_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু যে ডাল লাইনের বিপদ ঘটাচ্ছে সেটাই ছাঁটা যায় — গাছের ক্ষতি কম হোক।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'লাইন চালু, আর্থিং নেই — ডাল কাটা হচ্ছে',
          asset: 'assets/game/art/m8_board89/trim_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল কাটা হয় শাটডাউন নিয়ে — লাইন চালু রেখে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শুধু লাইনের বিপদ ঘটানো ডালই ছাঁটা যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শাটডাউন নিয়ে ডাল কাটতে হয়, চালু লাইনে নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পাখির বাসা যেন নষ্ট না হয়, তাই বাসা রাখি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পুরো গাছ কাটা আমাদের নিজেদের অধিকার', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সব ডাল ছেঁটে দিলে গাছ আরও ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাইন চালু থাকলেও ডাল কাটা যায়, ভয় নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্থিং না দিয়েও ডাল কাটা চলে, সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাসাসহ ডাল কাটলে পাখি নিজে সরিয়ে নেয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যত ডাল খুশি কাটা যায়, নিয়মের দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'permit',
      promptBn: 'পুরো গাছ সরানোর কথা উঠেছে — কোনটা নিয়ম মেনে?',
      options: [
        LearnBoardOption(
          id: 'forest',
          labelBn: 'ফরেস্ট দপ্তরের সিলমোহর দেওয়া লিখিত অনুমতি',
          asset: 'assets/game/art/m8_board89/permit_forest.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'local',
          labelBn: 'পঞ্চায়েত বা মিউনিসিপালিটির লিখিত অনুমতি',
          asset: 'assets/game/art/m8_board89/permit_local.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'phone',
          labelBn: 'শুধু ফোনে বলা "কেটে দাও", করাত হাতে তৈরি',
          asset: 'assets/game/art/m8_board89/permit_phone.svg',
          scene: true,
          correct: false,
          rejectBn: 'মুখের কথায় নয় — পুরো গাছ কাটতে লিখিত অনুমতি লাগে।',
        ),
        LearnBoardOption(
          id: 'govt',
          labelBn: 'কোনো কাগজ নেই, ব্যক্তিগত বাগানের পাশে কুড়াল',
          asset: 'assets/game/art/m8_board89/permit_govt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফরেস্ট এলাকা বা ব্যক্তিগত গাছ হলে নোটিশ বা অনুমতি বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'quarrel',
          labelBn: 'আম গাছের মালিকের সঙ্গে চেঁচামেচি করা',
          asset: 'assets/game/art/m8_board89/permit_quarrel.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঝগড়া নয়, সচেতনতাই সমাধান — আগে গ্রাহককে বুঝিয়ে বলুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পুরো গাছ কাটতে সবসময় লিখিত অনুমতি লাগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফরেস্ট বা ব্যক্তিগত গাছে নোটিশ বা অনুমতি লাগে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অনুমতি ছাড়া কাটলে আইনি মামলা হতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মুখের কথাই যথেষ্ট, কাগজের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সরকারি লাইনের গাছে কারও অনুমতি লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝগড়া করে গ্রাহককে রাজি করানোই ভালো', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্যক্তিগত গাছ হলে কুড়াল দিয়ে কাটা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গাছের মালিক না থাকলে অনুমতির দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লিখিত অনুমতি শুধু অফিসের খাতায় লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'oil',
      promptBn: 'পুরনো ট্রান্সফরমার নামানো হয়েছে — তেলের কাজ কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'sheet',
          labelBn: 'প্লাস্টিক শিটের ওপর ট্রান্সফরমার, গ্লাভস-মাস্ক',
          asset: 'assets/game/art/m8_board89/oil_sheet.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'drums',
          labelBn: 'ঢাকনা আঁটা ড্রাম, ডিসপোজালের গাড়ির কাছে',
          asset: 'assets/game/art/m8_board89/oil_drums.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'soil',
          labelBn: 'খালি মাটিতে ট্রান্সফরমারের তেল চুইয়ে পড়ছে',
          asset: 'assets/game/art/m8_board89/oil_soil.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটিতে প্লাস্টিক শিট বিছিয়ে নিন — এক ফোঁটা তেলও যেন মাটিতে না পড়ে।',
        ),
        LearnBoardOption(
          id: 'drain',
          labelBn: 'রাস্তার ধারের ড্রেনে পুরনো তেল ঢালা হচ্ছে',
          asset: 'assets/game/art/m8_board89/oil_drain.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোড়া তেল ড্রেনে বা মাঠে ফেলা আইনত দণ্ডনীয়।',
        ),
        LearnBoardOption(
          id: 'open',
          labelBn: 'ঢাকনা খোলা ড্রাম, ঢালু হয়ে তেল পড়ছে',
          asset: 'assets/game/art/m8_board89/oil_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল ড্রামে ভরে সিল করে নির্দিষ্ট ডিসপোজাল সেন্টারে পাঠাতে হয়।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'ট্রান্সফরমারের ভালভে খালি হাত, মাস্ক নেই',
          asset: 'assets/game/art/m8_board89/oil_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরনো ট্রান্সফরমারের তেলে PCBs থাকতে পারে — গ্লাভস ও মাস্ক বাধ্যতামূলক।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পুরনো তেলে PCBs, তাই গ্লাভস ও মাস্ক জরুরি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তেল ড্রামে ভরে সিল করে ডিসপোজাল সেন্টারে পাঠান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'প্লাস্টিক শিটে তেল পড়লেও মাটি বাঁচে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তেল মাটিতে গেলে শুকিয়ে যায়, ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'খোলা ড্রাম রাস্তায় রাখলে অসুবিধা নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তেলে PCBs নেই, তাই মাস্কের দরকার হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ড্রেনে ঢাললে কেউ টের পায় না, তাই চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পুরনো ট্রান্সফরমার হলেও গ্লাভস লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অল্প তেল হলে যেখানে খুশি ফেলে দেওয়া যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'leak',
      promptBn: 'স্টোরে তেলের ড্রাম লিক করছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'sand',
          labelBn: 'তেলের ছোপে বালু ছড়িয়ে দেওয়া হচ্ছে',
          asset: 'assets/game/art/m8_board89/leak_sand.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'saw',
          labelBn: 'তেলের ছোপে কাঠের গুঁড়ো ছড়িয়ে দেওয়া',
          asset: 'assets/game/art/m8_board89/leak_saw.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hose',
          labelBn: 'তেলের ছোপে জলের পাইপ দিয়ে ধুয়ে দেওয়া',
          asset: 'assets/game/art/m8_board89/leak_hose.svg',
          scene: true,
          correct: false,
          rejectBn: 'জল দিয়ে ধুবেন না — তাতে তেল আরও ছড়িয়ে পড়ে।',
        ),
        LearnBoardOption(
          id: 'ignored',
          labelBn: 'লিক বাড়ছে, আশেপাশে কেউ নেই, চুপচাপ',
          asset: 'assets/game/art/m8_board89/leak_ignored.svg',
          scene: true,
          correct: false,
          rejectBn: 'লিক দেখলে সঙ্গে সঙ্গে বালু বা কাঠের গুঁড়ো ছড়িয়ে দিন।',
        ),
        LearnBoardOption(
          id: 'broom',
          labelBn: 'ঝাড়ু দিয়ে তেল ফ্লোরের ড্রেনে ফেলা',
          asset: 'assets/game/art/m8_board89/leak_broom.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল ড্রেনে ফেলা আইনত দণ্ডনীয় — ঝাড়ু দিয়ে ড্রেনে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জল দিলে তেল আরও বেশি ছড়িয়ে পড়ে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লিক দেখলেই বালু বা কাঠের গুঁড়ো ছড়ান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তেল ড্রেনে ফেলা আইনত দণ্ডনীয় হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জল দিয়ে ধুলে তেল পুরো সাফ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লিক বাড়লেও একটু পরে ব্যবস্থা নিলেই হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝাড়ু দিয়ে ড্রেনে ফেললে সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বালুর বদলে জল ঢাললে সবচেয়ে ভালো হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তেল মাটিতে ছড়ালে মাটি নিজে পরিষ্কার করে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লিক সামলাতে দেরি করলে কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'scrap',
      promptBn: 'কাজ শেষ — বাতিল জিনিস কোথায় যাবে?',
      options: [
        LearnBoardOption(
          id: 'van',
          labelBn: 'পুরনো ব্যাটারি অথরাইজড রিসাইক্লারের ভ্যানে',
          asset: 'assets/game/art/m8_board89/scrap_van.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bag',
          labelBn: 'তারের টুকরো ঘাস থেকে তুলে বস্তায় ভরা',
          asset: 'assets/game/art/m8_board89/scrap_bag.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cart',
          labelBn: 'ব্যাটারি রাস্তার কাবাড়িওয়ালার ঠেলায় বিক্রি',
          asset: 'assets/game/art/m8_board89/scrap_cart.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাবস্টেশনের বাতিল ব্যাটারি শুধু অথরাইজড রিসাইক্লারকেই বিক্রি বা ফেরত দেওয়া যায়।',
        ),
        LearnBoardOption(
          id: 'pond',
          labelBn: 'পুকুরের পাড়ে পুরনো ব্যাটারি ফেলে রাখা',
          asset: 'assets/game/art/m8_board89/scrap_pond.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যাটারির সীসা আর এসিড পরিবেশের জন্য মারাত্মক ক্ষতিকর।',
        ),
        LearnBoardOption(
          id: 'field',
          labelBn: 'তারের টুকরো মাঠের ঘাসের ওপর ফেলে রাখা',
          asset: 'assets/game/art/m8_board89/scrap_field.svg',
          scene: true,
          correct: false,
          rejectBn: 'তারের টুকরো মাঠে ফেলে আসবেন না — গরু-ছাগল খেয়ে মারা যেতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সাবস্টেশনের ব্যাটারি শুধু অথরাইজড রিসাইক্লারকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ব্যাটারির সীসা আর এসিড পরিবেশের জন্য ক্ষতিকর', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তারের টুকরো মাঠে ফেললে গরু-ছাগল খেয়ে ফেলে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পুরনো ব্যাটারি পুকুরে ফেললে মাটি পরিষ্কার হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কাবাড়িওয়ালাকে বিক্রি করলে কোনো সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তারের টুকরো মাঠে ফেললে কারও ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্যাটারি খোলা জায়গায় রাখলে ঠিকই আছে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাতিল জিনিস যেখানে খুশি ফেলে রাখা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাতিল ব্যাটারি কাবাড়িওয়ালাকে বেচলে লাভ হয়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board89Lines.rivalTaunt,
    rivalLineBn: M8Board89Lines.rivalMyth,
    exitBn: M8Board89Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'মাটি চিরতরে অনুর্বর',
      'ভূগর্ভস্থ জল দূষিত',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'তেলে মাটি চিরতরে অনুর্বর হয়ে যায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ভূগর্ভস্থ জল দূষিত হয়, এটি বড় অপরাধ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'তেল ড্রামে ভরে ডিসপোজাল সেন্টারে পাঠান', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মাটিতে ঢাললে আগাছা মরে, তাই ভালো', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'মাটিতে ঢাললে তেল নিজে থেকে উধাও হয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ট্রান্সফরমারের তেলে মাটির কোনো ক্ষতি নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'পোড়া তেল মাটিতে ঢাললে ফসল আরও বাড়ে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অল্প তেল হলে মাটিতে ঢাললে ঠিক আছে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'আগাছা মরলে মাটি আরও উর্বর হয়ে ওঠে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M8Board89Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'আগাছার জন্য এর চেয়ে সস্তা আর কী আছে! ঢেলে দিন না!';

  /// Lesson 8.9's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'পোড়া মবিল বা ট্রান্সফরমার অয়েল আগাছা মারার জন্য খুব ভালো, তাই ওটা মাটিতে ঢেলে দিই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  // DRAFT wording — owner.
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack89;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
