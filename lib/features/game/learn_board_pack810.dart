import 'learn_board_models.dart';

/// Module 8 Lesson 8.10 (রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ), the picture
/// board (rung `8.10/learn`, pack `learn_8_10`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board810_art.py` (no words in
/// the art; every label is below). Every round and trap comes from the live
/// lesson 8.10 text (`tool/all_training_chapters_bn.json`, the live text wins,
/// ruling X3) and the Module 8 rulings (`docs/module_specs/module8_rulings.md`,
/// item spec `docs/module_specs/module8_items/board_810.json`):
///  * log: the logbook page at shutdown and sign-off — times, the work done,
///    read twice before the signature (live 'দুবার পড়ে দেখুন');
///  * climb: a phone or verbal 'line OFF' does not put anyone on the pole. The
///    written permit in hand AND the own earth set after the tester shows 0 V
///    (live pro tip 1 says AND; ruling X1 / M8-17 puts the tester before the
///    earth). Traps: the phone at the ear, the coworker's thumbs-up, a shrug;
///  * customer: the uniform makes him the company's face; a shout, a turned
///    back or a hot head breaks the SoP (live 8.10 behaviour section);
///  * bribe: cash for a hook or a bypass is never help — the act is a slip,
///    the card says the law will not spare him (ruling M8-6);
///  * circular: the notice board and the training meeting keep the rules
///    current; an old paper or a coworker's jugaad does not (live pro tip 3,
///    myth 1 reality).
/// Five rounds: the carbon-copy round (rounds[1]) left the board (ruling
/// M8-21), so board 8.10 keeps rounds[0], [2], [3], [4] and [5].
///
/// Ruling M8-1: a wrong pick on the climb round (phone, thumbs-up, shrug) is
/// a deadly-class act (R1); the board kit has no freeze, so it teaches with
/// the lesson's own words and costs the round, like every other trap (the
/// same kit design as board 6.3). A wrong reason costs the table ◆ only
/// (ruling M8-8). Every new Bangla line is a DRAFT for the owner's wording
/// (ruling M6-12). No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack810 = LearnBoardPack(
  lessonId: '8.10',
  titleBn: 'রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'লগবুক, পারমিট, গ্রাহক, ঘুষ আর নতুন সার্কুলার — মাঠের প্রতিটি ধাপে সঠিক কাজটা চিনে নিন।',
  earnedBn: 'সময় লিখে লগবুক দুবার পড়ুন, PTW-এর কপি বইয়েই রাখুন, লিখিত পারমিট আর নিজের আর্থিং ছাড়া পোলে উঠবেন না।',
  slots: [
    LearnBoardSlot(
      id: 'log',
      promptBn: 'ডিউটি শেষ — কোন লগবুকের পাতাটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'full',
          labelBn: 'সময় আর কাজ লেখা ভরা পাতা',
          asset: 'assets/game/art/m8_board810/log_full.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'reread',
          labelBn: 'সইয়ের আগে আরেকবার পড়ছেন',
          asset: 'assets/game/art/m8_board810/log_reread.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'blank',
          labelBn: 'শুধু সই, পাতায় কিছু লেখা নেই',
          asset: 'assets/game/art/m8_board810/log_blank.svg',
          scene: true,
          correct: false,
          rejectBn: 'লেখা নেই মানে প্রমাণ নেই — তদন্ত কমিটি ধরে নেবে আপনি কাজটা করেননি বা নিয়ম মানেননি।',
        ),
        LearnBoardOption(
          id: 'notimes',
          labelBn: 'কাজ লেখা, সময়ের ঘর ফাঁকা',
          asset: 'assets/game/art/m8_board810/log_notimes.svg',
          scene: true,
          correct: false,
          rejectBn: 'কখন শাটডাউন নিলেন, কখন ছাড়লেন, কী কাজ করলেন — সব পুঙ্খানুপুঙ্খভাবে লিখে রাখতে হয়।',
        ),
        LearnBoardOption(
          id: 'rush',
          labelBn: 'হাঁটতে হাঁটতে এক হাতে সই করা',
          asset: 'assets/game/art/m8_board810/log_rush.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডিউটি শেষে লগবুক সাইন করার আগে দুবার পড়ে দেখুন সব ঠিক আছে কি না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শাটডাউন নেওয়া, ছাড়া আর কাজ লেখা থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তদন্তে আগে লগবুক দেখা হয়, লেখাই প্রমাণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সই করার আগে দুবার পড়ে ঠিক কি না দেখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লেখা না থাকলেও শুধু সই দিলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কাজ হয়েছে লিখলেই সময় লেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হাঁটতে হাঁটতে সই করলে সময় অনেক বাঁচে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লগবুক শুধু অফিসারের, আমার দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তদন্ত হলে লগবুক ছাড়াই সব বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সময়ের ঘর ফাঁকা থাকলে কিছু যায় আসে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'climb',
      promptBn: "ফোনে শুনলেন 'লাইন OFF আছে, উঠে পড়' — পোলে ওঠার আগে কোনটা চাই?",
      options: [
        LearnBoardOption(
          id: 'ptw',
          labelBn: 'হাতে ভরা, সই করা লিখিত পারমিট',
          asset: 'assets/game/art/m8_board810/climb_ptw.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'টেস্টারে 0 দেখে নিজের হাতে আর্থিং',
          asset: 'assets/game/art/m8_board810/climb_earth.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'phone',
          labelBn: 'ফোনে কানে, এক পা পোলের ধাপে',
          asset: 'assets/game/art/m8_board810/climb_phone.svg',
          scene: true,
          correct: false,
          rejectBn: "মুখের কথায় কাজ নয় — অফিসার বা যেই হোন, ফোনে 'লাইন OFF আছে' বললেই বিশ্বাস করবেন না।",
        ),
        LearnBoardOption(
          id: 'mate',
          labelBn: 'সহকর্মীর থাম্বস-আপ, কর্মী উঠছেন',
          asset: 'assets/game/art/m8_board810/climb_mate.svg',
          scene: true,
          correct: false,
          // Live pro tip 1, word for word (AND, not OR; ruling M8-17 / X1).
          rejectBn: 'লিখিত পারমিট হাতে না পাওয়া এবং নিজের হাতে আর্থিং না করা পর্যন্ত পোল-এ উঠবেন না।',
        ),
        LearnBoardOption(
          id: 'shrug',
          labelBn: 'কাঁধ ঝাঁকিয়ে পোলে উঠে পড়া',
          asset: 'assets/game/art/m8_board810/climb_shrug.svg',
          scene: true,
          correct: false,
          // Live myth 2 reality, word for word.
          rejectBn: "সুরক্ষার নিয়ম মানার দায় শুধু অফিসারের নয়—যে নিজের হাতে কাজটি করছে (আপনি), তারও। আপনি 'না' বলতে পারেন যদি কাজটা নিরাপদ না মনে হয়।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পারমিট হাতে আর নিজের আর্থিং, দুটোই আগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মুখের কথায় বা ইশারায় পোলে ওঠা যায় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিরাপদ না মনে হলে "না" বলা আপনার দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফোনে অফিসার বললেই লাইন ডেড ধরে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সহকর্মী থাম্বস-আপ দিলে পারমিট লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নিচু পদের কর্মীর কোনো দায় থাকে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সময় বাঁচাতে আর্থিং বাদ দিলেই চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পোলে উঠে তারপর পারমিট লিখলেও ঠিক হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'টেস্টার না দেখেও আর্থিং দেওয়া যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'customer',
      promptBn: 'লাইন OFF, রাগী গ্রাহক এসে চেঁচাচ্ছেন — ইউনিফর্ম পরা আপনি?',
      options: [
        LearnBoardOption(
          id: 'explain',
          labelBn: 'খোলা হাত, শান্ত মুখে বুঝিয়ে বলছেন',
          asset: 'assets/game/art/m8_board810/customer_explain.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'listen',
          labelBn: 'হেলমেট হাতে, মুখে হাসি নিয়ে শুনছেন',
          asset: 'assets/game/art/m8_board810/customer_listen.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shout',
          labelBn: 'চেঁচিয়ে জবাব, আঙুল তুলে ধমক',
          asset: 'assets/game/art/m8_board810/customer_shout.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইউনিফর্ম পরা অবস্থায় আপনি কোম্পানির প্রতিনিধি — গ্রাহকের সাথে দুর্ব্যবহারে কোম্পানির লাইসেন্সের শর্ত লঙ্ঘিত হয়।',
        ),
        LearnBoardOption(
          id: 'away',
          labelBn: 'কথার মাঝে গ্রাহকের দিকে পিঠ',
          asset: 'assets/game/art/m8_board810/customer_away.svg',
          scene: true,
          correct: false,
          rejectBn: 'WBERC-এর SoP শুধু টাইমিং নিয়ে নয়, গ্রাহকের সাথে ব্যবহারের কথাও বলে।',
        ),
        LearnBoardOption(
          id: 'hot',
          labelBn: 'লাল মুখে রেগে, হাতে রেঞ্চ তুলে',
          asset: 'assets/game/art/m8_board810/customer_hot.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজের চাপে মাথা গরম হলেও মুখে হাসি বা শান্ত ভাব বজায় রাখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ইউনিফর্মে আপনিই কোম্পানির প্রতিনিধি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দুর্ব্যবহারে লাইসেন্সের শর্ত ভাঙে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'SoP শুধু সময় নয়, ব্যবহারের নিয়মও বলে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ধমক দিলে রাগী গ্রাহক তাড়াতাড়ি থামে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ইউনিফর্ম থাকলে কথা বলার দায় থাকে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মুখ ঘুরিয়ে নিলে গ্রাহক নিজেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গরম মাথায় চেঁচানোই সবচেয়ে ভালো উপায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্রাহক যা বলেন তা শোনার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রাগ দেখালেই গ্রাহক কথা শুনে নেয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bribe',
      promptBn: "টাকা হাতে কেউ বলছে 'হুকিংটা লাগিয়ে দাও' — কোনটা ঠিক?",
      options: [
        LearnBoardOption(
          id: 'palm',
          labelBn: 'হাতের তালু বাড়িয়ে, নোট ফিরিয়ে দিচ্ছেন',
          asset: 'assets/game/art/m8_board810/bribe_palm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'walk',
          labelBn: 'গ্রাহকের হাতে তার রেখে কাজে ফিরছেন',
          asset: 'assets/game/art/m8_board810/bribe_walk.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'takehook',
          labelBn: 'নোট পকেটে, হাতে হুকিংয়ের তারটা',
          asset: 'assets/game/art/m8_board810/bribe_takehook.svg',
          scene: true,
          correct: false,
          rejectBn: 'টাকার বিনিময়ে হুকিং করতে সাহায্য করা শুধু দুর্নীতি নয়, নিজের পায়ে কুড়ুল মারা।',
        ),
        LearnBoardOption(
          id: 'bypass',
          labelBn: 'মিটারের দুই টার্মিনালে একটা তার',
          asset: 'assets/game/art/m8_board810/bribe_bypass.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটার বাইপাস করে দেওয়া দুর্নীতি — ধরা পড়লে আইন আপনাকে ছাড়বে না।',
        ),
        LearnBoardOption(
          id: 'pliers',
          labelBn: 'প্লায়ার্স দিয়ে লাইনের দিকে আঙুল',
          asset: 'assets/game/art/m8_board810/bribe_pliers.svg',
          scene: true,
          correct: false,
          rejectBn: 'অবৈধ কাজে কোনোভাবেই সাহায্য নয় — হুকিং-এ সাহায্য করা মানেই নিজের পায়ে কুড়ুল।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টাকার বিনিময়ে হুকিং বা বাইপাসে সাহায্য নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ধরা পড়লে আইন ছাড়বে না, নিজের পায়ে কুড়ুল', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অবৈধ কাজে কোনো রকম সাহায্য করা যায় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছোট ঘুষ হলে কেউ টের পায় না, ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মিটার বাইপাস করলে বিল কমে, তাই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বন্ধুর কাজ, তাই একটু হাত লাগানো ঠিক', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গ্রাহক খুশি থাকলে কোম্পানির কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টাকা নিলে ঝামেলা হয় না, ছেড়ে দেয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হুকিং-এ সাহায্য করলে কাজ তাড়াতাড়ি শেষ হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'circular',
      promptBn: 'নিয়ম বদলায় — নতুন সার্কুলারের খোঁজ কীভাবে রাখবেন?',
      options: [
        LearnBoardOption(
          id: 'board',
          labelBn: 'অফিসের নোটিশ বোর্ড, নতুন কাগজ দেখছেন',
          asset: 'assets/game/art/m8_board810/circular_board.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'meeting',
          labelBn: 'ট্রেনিং ক্লাসে নতুন সার্কুলার হাতে',
          asset: 'assets/game/art/m8_board810/circular_meeting.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pastby',
          labelBn: 'নোটিশ বোর্ড পাশ দিয়ে, একবারও না তাকিয়ে',
          asset: 'assets/game/art/m8_board810/circular_pastby.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিয়ম বদলায় — অফিসের নোটিশ বোর্ড থেকে নতুন সার্কুলারের খোঁজ রাখুন।',
        ),
        LearnBoardOption(
          id: 'oldpaper',
          labelBn: 'ভ্যানের জানালায় বছর-পুরনো হলদে কাগজ',
          asset: 'assets/game/art/m8_board810/circular_oldpaper.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিয়ম বদলায় — ট্রেনিং বা ইউনিয়ন মিটিং থেকে নতুন নিয়মের খোঁজ রাখুন।',
        ),
        LearnBoardOption(
          id: 'jugaad',
          labelBn: 'চায়ের দোকানে সহকর্মী কাগজ সরিয়ে দিচ্ছেন',
          asset: 'assets/game/art/m8_board810/circular_jugaad.svg',
          scene: true,
          correct: false,
          rejectBn: 'জুগাড় দিয়ে আজ হয়তো কাজ চলবে, কিন্তু দুর্ঘটনার দিন সেই জুগাড়ই জেলে পাঠাবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিয়ম বদলায়, তাই নোটিশ বোর্ড দেখা জরুরি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ট্রেনিং বা মিটিংয়ে নতুন নিয়ম জানা যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পুরনো কাগজের নিয়ম আজ আর ধরা যায় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একবার শিখলে নিয়ম চিরকাল একই থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সহকর্মী যা বলে সেটাই নতুন নিয়ম হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নোটিশ বোর্ড দেখার সময় নেই, তাই চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চায়ের দোকানের খবরই তো আসল খবর হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জুগাড় চললে নতুন সার্কুলার লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মুখস্থ থাকলে কাগজ দেখার দরকার নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    rivalLineBn: M8Board810Lines.rivalMyth,
    believeNoIsCorrect: true,
    tauntBn: M8Board810Lines.rivalTaunt,
    exitBn: M8Board810Lines.rivalExit,
    dangerHints: [
      'দুর্ঘটনার দিন',
      'জেলে যাবেন আপনি',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'জুগাড়ে আজ চললেও দুর্ঘটনায় জেলে পাঠায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'স্ট্যান্ডার্ড পদ্ধতিই দীর্ঘ দিন নিরাপদ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'লগবুক আর PTW-ই আপনার আইনি প্রমাণ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'জুগাড় করলে সময় বাঁচে, তাই সেটাই ভালো', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'বইয়ের নিয়ম শুধু কাগজে, মাঠে লাগে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মাঠের অভিজ্ঞতাই সব, নিয়ম মানার দরকার নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অফিসার দায় নিলে আমার কিছু যায় আসে না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'জুগাড় দেখলে অফিসারও কিছু বলে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'নিয়ম মানলে কাজ আটকে যায়, এড়ানোই ভালো', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice (reused from board 6.3); [toRecord] stay silent (caption
/// held for reading) until the director records them with `tool/rival_clip.py`.
abstract final class M8Board810Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'জুগাড়েই তো চলছে বছরের পর বছর! এত নিয়মের কী দরকার?';

  /// Lesson 8.10's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'আইন-কানুন সব বইয়ের পাতায়, মাঠে \'জুগাড়\' (Jugaad) দিয়েই কাজ চলে।';

  /// Already recorded (reused from board 6.3).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is the kit's recorded line.
  static List<String> get newGuideLines {
    final p = learnBoardPack810;
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
