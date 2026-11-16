import 'learn_board_models.dart';

/// Module 8 Lesson 8.1 (WBERC পরিচিতি: রাজ্যের পাওয়ার বস), the picture board
/// (rung `8.1/learn`, pack `learn_8_1`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board81_art.py` (no words in
/// the art; the names live in the Bangla labels). Every round and trap comes
/// from the live lesson text (`tool/all_training_chapters_bn.json`, lesson 8.1,
/// version 5) and the Module 8 rulings (`docs/module_specs/module8_rulings.md`,
/// item spec `docs/module_specs/module8_items/board_81.json`):
///  * ref: the referee. WBERC is an independent body, not under the state
///    government or the company (the live 'স্বাধীন বা ইন্ডিপেন্ডেন্ট সংস্থা'
///    line); it watches both the company and the consumer (pro tip 1 wording
///    as the lesson's own 'রেফারি' analogy);
///  * bal: the balance of interests ('একদিকে গ্রাহকের স্বার্থ, অন্যদিকে কোম্পানির
///    স্থায়িত্ব'; 'যাতে কেউ ক্ষতিগ্রস্ত না হয়');
///  * bill: a high-bill complaint. Pro tip 1: 'তর্ক নয়, তথ্য দিন'; the unit
///    price and fixed charge are set by the commission, not the company (the
///    live 'ট্যারিফ' point and its daily check: the tariff chart on the bill's
///    back or the notice board);
///  * sop: the time limit for a fuse complaint and a new connection (the SoP
///    point, pro tip 2: 'ঢিলেমি মানেই কোম্পানির ঘাড়ে জরিমানার কেস');
///  * lic: the licence (distribution, transmission, trading); a broken rule can
///    cost the licence (the live 'লাইসেন্স বাতিলও' line); APTEL is the special
///    tribunal for electricity cases when the commission's order is not
///    accepted ('আপিল ট্রাইব্যুনাল (APTEL)').
/// Five rounds (ruling M8-21): the new-rate round (`rounds[3]` of the
/// six-round spec, the public hearing) left the board; `do_8_1_b` plays it.
/// The rival's myth is lesson 8.1's second myth, word for word; its reality
/// uses the live text ('সাপ্লাই কোড' and CEA's safety regulation, ruling X3).
///
/// Module 8 lesson 8.1 is slip-only (ruling M8-1): there is no deadly card on
/// this board, so a wrong card costs the round's ◆ only (ruling M8-8).
///
/// Every new line here is a DRAFT for the owner's wording (rulings M8-14,
/// X6). No YouTube explainer id (ruling M6-14, owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack81 = LearnBoardPack(
  lessonId: '8.1',
  titleBn: 'WBERC পরিচিতি: রাজ্যের পাওয়ার বস',
  badgeBn: 'জরুরী রেগুলেশন (WBERC ফোকাস)',
  introBn: 'WBERC হলো বিদ্যুতের রেফারি। কার কী কাজ, কোন ছবিটা ঠিক, চিনে নিন।',
  earnedBn: 'WBERC স্বাধীন রেফারি: দাম, সময়সীমা আর লাইসেন্স ঠিক করে, কোম্পানি নিজে নয়।',
  slots: [
    LearnBoardSlot(
      id: 'ref',
      promptBn: 'বিদ্যুতের মাঠে রেফারি কে — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'sep',
          labelBn: 'আলাদা ভবনে WBERC, কারও সঙ্গে জোড়া নয়',
          asset: 'assets/game/art/m8_board81/ref_sep.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'mid',
          labelBn: 'রেফারি মাঝখানে, দুই দিকে চেয়ে আছেন',
          asset: 'assets/game/art/m8_board81/ref_mid.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'plate',
          labelBn: 'কোম্পানির অফিসে WBERC বিভাগের প্লেট',
          asset: 'assets/game/art/m8_board81/ref_plate.svg',
          scene: true,
          correct: false,
          rejectBn: 'WBERC স্বাধীন সংস্থা — বিদ্যুৎ কোম্পানির অধীন নয়।',
        ),
        LearnBoardOption(
          id: 'tilt',
          labelBn: 'কোম্পানির রঙের জামা, বাঁশি শুধু বাড়িতে',
          asset: 'assets/game/art/m8_board81/ref_tilt.svg',
          scene: true,
          correct: false,
          rejectBn: 'রেফারি দুই দিক দেখে — কোম্পানি যেন গ্রাহক ঠকিয়ে বেশি লাভ না করে, গ্রাহকও যেন নিয়ম মানে।',
        ),
        LearnBoardOption(
          id: 'board',
          labelBn: 'কোম্পানির কর্তারা একা বোর্ডরুমে নিয়ম লিখছেন',
          asset: 'assets/game/art/m8_board81/ref_board.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোম্পানি চাইলেই যা খুশি করতে পারে না — মাথার ওপর রেফারি WBERC।',
        ),
        LearnBoardOption(
          id: 'counter',
          labelBn: 'একই অফিসে দুই কাউন্টার: নিয়ম আর বিক্রি',
          asset: 'assets/game/art/m8_board81/ref_counter.svg',
          scene: true,
          correct: false,
          rejectBn: '2003-এর আইনে বলা হলো — ব্যবসা আর বিচার এক হাতে থাকতে পারে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'WBERC স্বাধীন সংস্থা, কোম্পানির অধীন নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রেফারি দুই দিক দেখে: কোম্পানি আর গ্রাহক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ব্যবসা আর বিচার এক হাতে থাকতে পারে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কোম্পানির ভবনে বসলে WBERCও কোম্পানির অংশ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রেফারি শুধু গ্রাহককে দেখে, কোম্পানিকে নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কোম্পানি নিজেই নিজের নিয়ম বানিয়ে নেয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বড় অফিসাররাই শুধু নিয়ম ঠিক করেন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'খেলার মাঠের রেফারির সঙ্গে এর কোনো মিল নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কোম্পানির রেট নিয়ে WBERC কিছু বলে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bal',
      promptBn: 'দাম আর নিয়ম ঠিক করতে WBERC কী মাপে?',
      options: [
        LearnBoardOption(
          id: 'scale',
          labelBn: 'দাড়িপাল্লায় একদিকে বাড়ি, অন্যদিকে অফিস',
          asset: 'assets/game/art/m8_board81/bal_scale.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'files',
          labelBn: 'কমিশনের টেবিলে দুই ফাইল: বাড়ি আর অফিস',
          asset: 'assets/game/art/m8_board81/bal_files.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tipco',
          labelBn: 'পাল্লা ভারী, টাকার থলির দিকে বেশি ঝুঁকে',
          asset: 'assets/game/art/m8_board81/bal_tipco.svg',
          scene: true,
          correct: false,
          rejectBn: 'WBERC দেখে কোম্পানি যেন গ্রাহক ঠকিয়ে বেশি লাভ না করে।',
        ),
        LearnBoardOption(
          id: 'tiphome',
          labelBn: 'পাল্লা বাড়ির দিকে, অফিসে তালা ঝুলছে',
          asset: 'assets/game/art/m8_board81/bal_tiphome.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোম্পানির স্থায়িত্বও দেখতে হয় — এমন দাম, যাতে কেউ ক্ষতিগ্রস্ত না হয়।',
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'এক পাল্লার দাড়িপাল্লায় শুধু খরচের কাগজ',
          asset: 'assets/game/art/m8_board81/bal_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'একদিকে গ্রাহক, অন্যদিকে কোম্পানির স্থায়িত্ব — দুটোই মাপে WBERC।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একদিকে গ্রাহক, অন্যদিকে কোম্পানির স্থায়িত্ব', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দাম আর নিয়ম দুদিক মেপে ঠিক করে WBERC', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কোম্পানি যেন গ্রাহক ঠকিয়ে বেশি লাভ না করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কোম্পানির লাভই WBERC-এর একমাত্র মাপকাঠি', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গ্রাহকের স্বার্থ দেখা WBERC-এর কাজ নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কোম্পানির খরচের হিসাবই যথেষ্ট, গ্রাহক লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দাম ঠিক করে কোম্পানির নিজের অফিসের টেবিলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভারসাম্য নয়, বেশি দামই WBERC-এর লক্ষ্য', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কোনো মাপকাঠি লাগে না, যা খুশি দাম বসে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bill',
      promptBn: 'গ্রাহক বেশি বিল নিয়ে রেগে গেছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'door',
          labelBn: 'দরজায় বিল উল্টে পেছনের ট্যারিফ টেবিল দেখানো',
          asset: 'assets/game/art/m8_board81/bill_door.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'chart',
          labelBn: 'নোটিশ বোর্ডের ট্যারিফ চার্ট দেখিয়ে বোঝানো',
          asset: 'assets/game/art/m8_board81/bill_chart.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shout',
          labelBn: 'মুখোমুখি চিৎকার, হাতে মুচড়ানো বিল',
          asset: 'assets/game/art/m8_board81/bill_shout.svg',
          scene: true,
          correct: false,
          rejectBn: 'তর্ক নয়, তথ্য দিন — শান্তভাবে বলুন দাম ঠিক করা কমিশনের কাজ, কোম্পানির নয়।',
        ),
        LearnBoardOption(
          id: 'shrug',
          labelBn: 'কাঁধ ঝাঁকিয়ে কোম্পানির অফিসের দিকে আঙুল',
          asset: 'assets/game/art/m8_board81/bill_shrug.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই রেট কোম্পানি ঠিক করে না — এটা কমিশনের অর্ডার।',
        ),
        LearnBoardOption(
          id: 'strike',
          labelBn: 'বিলের একটা লাইন কলম দিয়ে কেটে দেওয়া',
          asset: 'assets/game/art/m8_board81/bill_strike.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইউনিট প্রতি দাম, ফিক্সড চার্জ — সব ঠিক করে WBERC।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দাম ঠিক করা কমিশনের কাজ, কোম্পানির নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ইউনিট দাম আর ফিক্সড চার্জ WBERC ঠিক করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শান্তভাবে তথ্য দিন, তর্কে জড়াবেন না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্রাহকের সঙ্গে গলা তুলে তর্ক করাই ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'এই রেট তো কোম্পানিই নিজে ঠিক করে দেয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বিলের লাইন কেটে দাম কমিয়ে দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বিল নিয়ে প্রশ্ন উঠলে কিছুই বলার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'চুপ থাকলে গ্রাহক নিজেই শান্ত হয়ে যান', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'তর্ক জিতলে গ্রাহককে মেনে নিতে হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'sop',
      promptBn: 'ফিউজ গেছে, কমপ্লেইন এসেছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'leave',
          labelBn: 'অভিযোগের স্লিপ নিয়ে ঘড়ি দেখে গাড়িতে ওঠা',
          asset: 'assets/game/art/m8_board81/sop_leave.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'file',
          labelBn: 'ক্যালেন্ডারের কয়েক পাতা, নতুন কানেকশনের ফাইল',
          asset: 'assets/game/art/m8_board81/sop_file.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tea',
          labelBn: 'চায়ের গ্লাসের নিচে অভিযোগের স্লিপ পড়ে আছে',
          asset: 'assets/game/art/m8_board81/sop_tea.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঢিলেমি মানেই কোম্পানির ঘাড়ে জরিমানার কেস — সময়সীমা বেঁধে দেয় WBERC।',
        ),
        LearnBoardOption(
          id: 'dark',
          labelBn: 'অন্ধকার বাড়ি, জানালায় গ্রাহক, পাতা উড়ছে',
          asset: 'assets/game/art/m8_board81/sop_dark.svg',
          scene: true,
          correct: false,
          rejectBn: 'দেরি হলে কোম্পানিকে গ্রাহকের কাছে জরিমানা বা ক্ষতিপূরণ দিতে হতে পারে।',
        ),
        LearnBoardOption(
          id: 'cob',
          labelBn: 'তাকে ধুলো আর মাকড়সার জাল মাখা পুরনো ফাইল',
          asset: 'assets/game/art/m8_board81/sop_cob.svg',
          scene: true,
          correct: false,
          rejectBn: 'নতুন কানেকশন কত দিনে দিতে হবে — সেই সময়সীমাও WBERC বেঁধে দেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফিউজ গেলে সারানোর সময়সীমা WBERC বেঁধে দেয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দেরি হলে কোম্পানিকে জরিমানা বা ক্ষতিপূরণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নতুন কানেকশনের সময়সীমাও WBERC ঠিক করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ঢিলেমি করলে কোম্পানির কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সময়সীমা শুধু অফিসের খাতায় লেখা থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফিউজ পড়ে থাকলে ক্ষতি নেই, দায়ও নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নতুন কানেকশন যত দেরিতে, তত ভালো ধরা হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কমপ্লেইন চাপা দিলেই সমস্যা মিটে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সময়সীমার কথা শুধু বড় অফিসাররা জানেন', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'lic',
      promptBn: 'রাজ্যে কে বিদ্যুৎ বেচবে, কে তার টানবে — অনুমতি দেয় কে?',
      options: [
        LearnBoardOption(
          id: 'wall',
          labelBn: 'অফিসের দেওয়ালে WBERC সিলের লাইসেন্স',
          asset: 'assets/game/art/m8_board81/lic_wall.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'three',
          labelBn: 'কমিশনের টেবিলে তিন রকম সার্টিফিকেট',
          asset: 'assets/game/art/m8_board81/lic_three.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'self',
          labelBn: 'কর্তা নিজের কোম্পানির নামের লাইসেন্সে সই',
          asset: 'assets/game/art/m8_board81/lic_self.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাজ্যে কে বিদ্যুৎ বেচবে আর কে তার টানবে, সেই লাইসেন্স দেয় WBERC।',
        ),
        LearnBoardOption(
          id: 'torn',
          labelBn: 'চিরকাল বৈধ লাইসেন্স, পাশে ছেঁড়া নিয়মের বই',
          asset: 'assets/game/art/m8_board81/lic_torn.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিয়ম ভাঙলে WBERC লাইসেন্স বাতিলও করতে পারে।',
        ),
        LearnBoardOption(
          id: 'apt',
          labelBn: 'আদালতের বেঞ্চে APTEL, সেখান থেকে লাইসেন্স',
          asset: 'assets/game/art/m8_board81/lic_apt.svg',
          scene: true,
          correct: false,
          rejectBn: 'APTEL-এ যেতে হয় WBERC-এর রায়ে খুশি না হলে — লাইসেন্স দেয় WBERC।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বিদ্যুৎ বেচা ও তার টানার লাইসেন্স WBERC দেয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নিয়ম ভাঙলে WBERC লাইসেন্স বাতিল করতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তিন ধরনের লাইসেন্স, সবই WBERC দেয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কোম্পানি নিজের নামে নিজেই লাইসেন্স দেয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লাইসেন্স একবার পেলে চিরকাল বৈধ থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রায়ে খুশি না হলে সুপ্রিম কোর্টে যাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লাইসেন্স দেওয়ার অধিকার শুধু আদালতের', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'WBERC লাইসেন্স দেয় না, শুধু বিল দেখে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লাইসেন্স লাগে না, যে কেউ তার টানতে পারে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    rivalLineBn: M8Board81Lines.rivalMyth,
    believeNoIsCorrect: true,
    tauntBn: M8Board81Lines.rivalTaunt,
    exitBn: M8Board81Lines.rivalExit,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'আইন না জানলে নিজেরই দায়',
      'রোজের নিয়ম ভেঙে পড়া',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'WBERC-এর সাপ্লাই কোড মেনেই রোজ কাজ করতে হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'CEA-এর সেফটি রেগুলেশনও রোজের নিয়ম', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আইন না জানলে নিজের অজান্তেই অপরাধ হতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'লাইনম্যান কখনো নিয়মের ভেতরে পড়ে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'সাপ্লাই কোড শুধু বড় অফিসারদের জন্য লেখা', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'সেফটি নিয়ম শিখে লাভ নেই, হাতের কাজই আসল', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'WBERC-এর নিয়ম শুধু কাগজে থাকে, মাঠে লাগে না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'কাজের সময় নিয়ম ভাঙলে কেউ খোঁজে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'নিয়ম জানা লাইনম্যানের কোনো কাজে আসে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M8Board81Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'WBERC নিয়ে এত মাথা ঘামানোর কী আছে? আমরা তো শুধু তার টানি!';

  /// Lesson 8.1's second myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'WBERC শুধুমাত্র বড় অফিসারদের ব্যাপার, লাইনম্যানদের এতে কোনো ভূমিকা নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack81;
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
