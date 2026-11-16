import 'learn_board_models.dart';

/// Module 7 Lesson 7.1 (ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন: আপনার বাইবেল), the
/// picture board (rung `7.1/learn`, pack `learn_7_1`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board71_art.py` (no words in
/// the art; the Act's year on its cover is drawn as stroke glyphs with English
/// digits). Every round and trap comes from the live lesson text and the
/// Module 7 rulings (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_71.json`). The live CEA 2023
/// regulation numbers win over the spec's old ones (ruling X3): danger notice
/// = Reg 20, earthing = Reg 43 and 50, the fit person = Reg 3.
///  * book: where the rulebook is followed — the Electricity Act, 2003 taken
///    down and read, the CEA safety regulations open in hand (mission
///    briefing, points 1–2). Traps: rules locked away for engineers only
///    (briefing), a senior's own notebook, a contractor's own rules (point
///    2's safety tip, word for word), the CEA book left in a dusty file;
///  * plate: Reg 20 — a danger plate on every installation (transformer,
///    feeder pillar). Traps: no plate, a bare pillar door, the plate lying on
///    the ground;
///  * earth: Reg 43 and 50 — every metal body and the system's neutral
///    earthed. Traps: the body's earth lead cut, the neutral's lead loose, a
///    pillar with no earth. A cut lead seen here is a slip (ruling M7-6:
///    nothing is being charged);
///  * person: Reg 3 — only a fit person: trained AND authorized (both shown
///    on both safe cards). Traps: the
///    consumer's son, trained but not authorized, a helper who learned by
///    watching, the local electrician. No age rule (ruling X3: the live 7.10
///    text has none). Non-live work by an unfit person is a slip, worded as a
///    breach of the law (ruling M7-5);
///  * ask: the job looks unsafe by the CEA rules (pro tips 1–4) — question
///    the supervisor, ask for the right tools and PPE. Traps: going up
///    without a word, starting with whatever is at hand, "knowing the rules
///    is not my job" (pro tip 3), the law as a burden.
/// No deadly anywhere on this board (ruling M7-6), and boards have no freeze
/// (kit design): every trap costs the round's ◆ and says its lesson words.
/// The rival's myth is the lesson's first myth, word for word (ruling M7-10).
///
/// Every new line here is a DRAFT for the owner's wording (rulings M6-12,
/// M7-10). No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack71 = LearnBoardPack(
  lessonId: '7.1',
  // The live level_title, without the repealed names: owner answer XL7.1-T1
  // (module7_rulings.md) puts this new title on the 7.1 board and levels.
  titleBn: 'ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন: আপনার বাইবেল',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board71Lines.intro,
  earnedBn: M7Board71Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'book',
      // The round is about how the rulebook is treated (used, or locked away,
      // replaced, left in a file), so no trap shows the wrong document under a
      // "which document" question.
      promptBn: 'বিদ্যুতের রুলবুক — কোথায় নিয়ম ঠিকভাবে মানা হচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'act',
          labelBn: 'তাক থেকে ইলেকট্রিসিটি অ্যাক্ট, 2003 নেওয়া',
          asset: 'assets/game/art/m7_board71/book_act.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cea',
          labelBn: 'হাতে খোলা CEA-র সুরক্ষা রেগুলেশন বই',
          asset: 'assets/game/art/m7_board71/book_cea.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'locked',
          labelBn: 'আলমারিতে তালা: শুধু ইঞ্জিনিয়ারদের নিয়ম',
          asset: 'assets/game/art/m7_board71/book_locked.svg',
          scene: true,
          correct: false,
          // Live mission briefing.
          rejectBn: 'এই নিয়ম শুধু ইঞ্জিনিয়ার বা ম্যানেজারদের জন্য নয় — আপনার মতো ফিল্ড কর্মীদের সুরক্ষার জন্যই তৈরি।',
        ),
        LearnBoardOption(
          id: 'notebook',
          labelBn: 'সিনিয়রের নিজের হাতে লেখা নিয়মের খাতা',
          asset: 'assets/game/art/m7_board71/book_notebook.svg',
          scene: true,
          correct: false,
          rejectBn: 'রুলবুকের প্রধান দুই অংশ ইলেকট্রিসিটি অ্যাক্ট, 2003 আর CEA-র সুরক্ষা নিয়মাবলী — কারও নিজের খাতা নয়।',
        ),
        LearnBoardOption(
          id: 'contract',
          labelBn: 'ঠিকাদারের নিজের নিয়মের বোর্ড, CEA সরানো',
          asset: 'assets/game/art/m7_board71/book_contract.svg',
          scene: true,
          correct: false,
          // Live point 2's safety tip, word for word.
          rejectBn: 'আইন অনুযায়ী, প্রতিটি বিদ্যুৎ কর্মী এবং ঠিকাদার এই সুরক্ষা নিয়মগুলো মানতে বাধ্য।',
        ),
        LearnBoardOption(
          id: 'dusty',
          labelBn: 'ধুলো-পড়া ফাইলে ফেলে রাখা CEA-র বই',
          asset: 'assets/game/art/m7_board71/book_dusty.svg',
          scene: true,
          correct: false,
          rejectBn: 'আপনার কাজের জন্য সবচেয়ে গুরুত্বপূর্ণ নথি এই CEA রেগুলেশন — ফাইলে ফেলে রাখার জিনিস নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রুলবুক মানে অ্যাক্ট, 2003 আর CEA রেগুলেশন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কর্মী, ঠিকাদার — সবাই এই নিয়ম মানতে বাধ্য', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এই নিয়ম ফিল্ড কর্মীদের সুরক্ষার জন্যই তৈরি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'এই নিয়ম শুধু ইঞ্জিনিয়ার আর ম্যানেজারদের জন্য', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সিনিয়রের নিজের খাতার নিয়মই মাঠের আসল নিয়ম', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঠিকাদারের লোকদের CEA নিয়ম মানতে হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আইনের বই শুধু অফিসের ফাইলে তুলে রাখার জন্য', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যে যার নিজের নিয়মে কাজ করলেই যথেষ্ট হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মাঠে কাজ চললে রুলবুক দেখার কোনো দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'plate',
      promptBn: 'রেগুলেশন 20 — কোন ইনস্টলেশন নিয়ম মেনেছে?',
      options: [
        LearnBoardOption(
          id: 'dtr',
          labelBn: 'ট্রান্সফরমারের গায়ে ডেঞ্জার প্লেট লাগানো',
          asset: 'assets/game/art/m7_board71/plate_dtr.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pillar',
          labelBn: 'ফিডার পিলারের দরজায় ডেঞ্জার প্লেট লাগানো',
          asset: 'assets/game/art/m7_board71/plate_pillar.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dtrbare',
          labelBn: 'ট্রান্সফরমারের কোথাও ডেঞ্জার প্লেট নেই',
          asset: 'assets/game/art/m7_board71/plate_dtrbare.svg',
          scene: true,
          correct: false,
          // Live point 3, Reg 20.
          rejectBn: 'রেগুলেশন 20: প্রতিটি বিদ্যুৎ ইনস্টলেশনের গায়ে একটি বিপদ চিহ্ন বা ডেঞ্জার প্লেট লাগানো বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'pillarbare',
          labelBn: 'ফিডার পিলারের দরজা ফাঁকা, কোনো প্লেট নেই',
          asset: 'assets/game/art/m7_board71/plate_pillarbare.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিডার পিলারও বিদ্যুৎ ইনস্টলেশন — এর গায়েও ডেঞ্জার প্লেট লাগানো বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'ground',
          labelBn: 'প্লেট খুলে পিলারের পাশে মাটিতে পড়ে আছে',
          asset: 'assets/game/art/m7_board71/plate_ground.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডেঞ্জার প্লেট ইনস্টলেশনের গায়ে লাগানো থাকতে হয় — মাটিতে পড়ে থাকা প্লেট নিয়ম মানে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রতিটি ইনস্টলেশনের গায়ে ডেঞ্জার প্লেট চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রেগুলেশন 20: বিপদ চিহ্ন লাগানো বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ট্রান্সফরমার, পিলার — সবার গায়ে বিপদ চিহ্ন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শুধু বড় ট্রান্সফরমারেই ডেঞ্জার প্লেট লাগে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'প্লেট কাছাকাছি কোথাও রাখলেই নিয়ম মানা হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পাড়ার লোক সব জানে, তাই প্লেটের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফিডার পিলারে বিপদ চিহ্নের কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ডেঞ্জার প্লেট শুধু সাজানোর জিনিস, নিয়ম নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'earth',
      promptBn: 'রেগুলেশন 43 ও 50 — কোথায় আর্থিং নিয়ম মতো করা?',
      options: [
        LearnBoardOption(
          id: 'dtr',
          labelBn: 'ট্যাঙ্কের বডি আর নিউট্রাল, দুটোই আর্থ করা',
          asset: 'assets/game/art/m7_board71/earth_dtr.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pillar',
          labelBn: 'পিলারের ধাতব বডি থেকে আর্থ তার মাটিতে',
          asset: 'assets/game/art/m7_board71/earth_pillar.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bodycut',
          labelBn: 'ট্যাঙ্কের বডির আর্থ তার মাঝখানে কাটা',
          asset: 'assets/game/art/m7_board71/earth_bodycut.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধাতব বডির আর্থ তার কাটা — রেগুলেশন 43 ও 50-এ যন্ত্রপাতির ধাতব বডি আর্থ করা বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'বডি আর্থ করা, নিউট্রালের আর্থ তার খোলা',
          asset: 'assets/game/art/m7_board71/earth_neutral.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু বডি নয় — সিস্টেমের নিউট্রালকেও সঠিকভাবে আর্থিং করা বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'pillarnone',
          labelBn: 'পিলারের ধাতব বডিতে কোনো আর্থ তারই নেই',
          asset: 'assets/game/art/m7_board71/earth_pillarnone.svg',
          scene: true,
          correct: false,
          rejectBn: 'পিলারের ধাতব বডিতে আর্থ নেই — সমস্ত যন্ত্রপাতির ধাতব বডি আর্থ করতে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ধাতব বডি আর নিউট্রাল, দুটোই আর্থ করা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রেগুলেশন 43 ও 50: সঠিক আর্থিং বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আর্থ তার যন্ত্র থেকে মাটি পর্যন্ত অটুট চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বডি আর্থ করলেই হলো, নিউট্রালের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পিলারে আর্থ লাগে না, ওটা তো শুধু বাক্স', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কাটা আর্থ তার দেখতে খারাপ, তাতে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্থিং শুধু বড় সাবস্টেশনের জন্য, এখানে নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নিউট্রাল আর্থ থাকলে বডির আর্থ লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'person',
      promptBn: 'রেগুলেশন 3 — বিদ্যুৎ লাইনে কাজ করতে পারেন কে?',
      options: [
        LearnBoardOption(
          id: 'id',
          // Both halves of Reg 3 named and drawn: the training seal on the ID
          // card, the stamp on the letter.
          labelBn: 'প্রশিক্ষিত লাইনম্যান, হাতে ID আর অনুমোদনপত্র',
          asset: 'assets/game/art/m7_board71/person_id.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cert',
          labelBn: 'প্রশিক্ষণের সার্টিফিকেট আর অনুমোদন, দুটোই',
          asset: 'assets/game/art/m7_board71/person_cert.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'son',
          labelBn: 'গ্রাহকের ছেলে প্লায়ার্স হাতে পোলে উঠছে',
          asset: 'assets/game/art/m7_board71/person_son.svg',
          scene: true,
          correct: false,
          // Live point 3, Reg 3.
          rejectBn: 'আইন অনুযায়ী, শুধুমাত্র প্রশিক্ষিত এবং অনুমোদিত ব্যক্তিই বিদ্যুৎ লাইনে কাজ করতে পারবেন।',
        ),
        LearnBoardOption(
          id: 'trained',
          labelBn: 'প্রশিক্ষণের সার্টিফিকেট আছে, অনুমোদন নেই',
          asset: 'assets/game/art/m7_board71/person_trained.svg',
          scene: true,
          correct: false,
          rejectBn: 'উপযুক্ত মানে প্রশিক্ষিত এবং অনুমোদিত — অনুমোদন ছাড়া লাইনে কাজ করা আইনভঙ্গ।',
        ),
        LearnBoardOption(
          id: 'helper',
          labelBn: 'দেখে দেখে শেখা হেল্পার লাইনে হাত দিচ্ছে',
          asset: 'assets/game/art/m7_board71/person_helper.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু দেখে শেখা কেউ উপযুক্ত নন — প্রশিক্ষণ আর অনুমোদন ছাড়া লাইনে কাজ আইনে নিষেধ।',
        ),
        LearnBoardOption(
          id: 'mistri',
          labelBn: 'পাড়ার মিস্ত্রি ফিডার পিলারের দরজা খুলেছে',
          asset: 'assets/game/art/m7_board71/person_mistri.svg',
          scene: true,
          correct: false,
          rejectBn: 'অনুমোদন নেই এমন কেউ পিলারে হাত দিতে পারেন না — রেগুলেশন 3: শুধু উপযুক্ত ব্যক্তি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইনে কাজ শুধু প্রশিক্ষিত ও অনুমোদিত লোকের', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'উপযুক্ত মানে প্রশিক্ষণ আর অনুমোদন, দুটোই চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রেগুলেশন 3: লাইনের কাজ শুধু উপযুক্ত ব্যক্তির', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'প্রশিক্ষণ থাকলেই হলো, অনুমোদনের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দেখে দেখে শিখে নিলেই লাইনে কাজ করা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গ্রাহক নিজের বাড়ির লাইন নিজেই সারাতে পারেন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পাড়ার মিস্ত্রি অভিজ্ঞ, তাঁর অনুমোদন লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছোট কাজে উপযুক্ত ব্যক্তির দরকার পড়ে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ask',
      promptBn: 'কাজটা CEA নিয়মে অসুরক্ষিত মনে হচ্ছে — কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'super',
          labelBn: 'রুলবুক হাতে কাজের আগে সুপারভাইজারকে প্রশ্ন',
          asset: 'assets/game/art/m7_board71/ask_super.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'store',
          labelBn: 'স্টোরে স্লিপ দিয়ে সঠিক টুলস আর PPE চাওয়া',
          asset: 'assets/game/art/m7_board71/ask_store.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'silent',
          labelBn: 'কাউকে কিছু না বলে চুপচাপ পোলে উঠে যাওয়া',
          asset: 'assets/game/art/m7_board71/ask_silent.svg',
          scene: true,
          correct: false,
          // Live pro tip 4.
          rejectBn: 'প্রশ্ন করার অধিকার আপনার আছে — কাজ অসুরক্ষিত মনে হলে আপনার সুপারভাইজারের সাথে কথা বলুন।',
        ),
        LearnBoardOption(
          id: 'nokit',
          labelBn: 'হাতের কাছে যা আছে তাই দিয়েই কাজ শুরু',
          asset: 'assets/game/art/m7_board71/ask_nokit.svg',
          scene: true,
          correct: false,
          // Live pro tip 2, word for word.
          rejectBn: 'আইন অনুযায়ী, আপনার কোম্পানি আপনাকে সঠিক টুলস, PPE এবং নিরাপদ কাজের পরিবেশ দিতে বাধ্য।',
        ),
        LearnBoardOption(
          id: 'excuse',
          labelBn: 'অফিসারকে বলা: নিয়ম জানা আমার কাজ নয়',
          asset: 'assets/game/art/m7_board71/ask_excuse.svg',
          scene: true,
          correct: false,
          // Live pro tip 3 (knowing the basic rules is your professional duty).
          rejectBn: "'আমি আইনটি জানতাম না' — দুর্ঘটনার পর এটি অজুহাত হিসেবে গৃহীত হয় না। প্রাথমিক নিয়ম জানা আপনার পেশাগত দায়িত্ব।",
        ),
        LearnBoardOption(
          id: 'burden',
          labelBn: 'নিয়ম বোঝা ভেবে রুলবুক ছুড়ে কাজে নামা',
          asset: 'assets/game/art/m7_board71/ask_burden.svg',
          scene: true,
          correct: false,
          // Live pro tip 1.
          rejectBn: 'সুরক্ষা আইন আপনার ওপর বোঝা চাপানোর জন্য নয় — আপনাকে আর সাধারণ মানুষকে বাঁচানোর জন্য তৈরি।',
        ),
      ],
      whyChips: [
        // Right reasons fit both safe picks (questioning the supervisor, asking
        // the store for tools and PPE): pro tips 2 and 4.
        LearnWhyChip(id: 'w1', textBn: 'অসুরক্ষিত মনে হলে চুপ না থেকে মুখ খুলুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আইন আপনার পক্ষে — যা দরকার, চেয়ে নিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিরাপদে কাজ করার অধিকার আইনই আপনাকে দেয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সুপারভাইজারকে প্রশ্ন করা মানেই বেয়াদবি', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যা আছে তাই দিয়ে কাজ সারাই আসল দক্ষতা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দুর্ঘটনার পর আইন না জানলে মাফ পাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'PPE চাইলে লোকে ভীতু ভাববে, চুপ থাকুন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সুরক্ষা আইন শুধু কাজের ওপর বাড়তি বোঝা', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board71Lines.rivalTaunt,
    rivalLineBn: M7Board71Lines.rivalMyth,
    exitBn: M7Board71Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'তদন্তে CEA নিয়মই মাপকাঠি',
      'জরিমানা থেকে জেল',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'যেকোনো দুর্ঘটনার তদন্তে CEA নিয়মই মাপকাঠি', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'নিয়ম ভাঙা প্রমাণ হলে জরিমানা থেকে জেলও হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আপনার সুরক্ষা এই নিয়ম মানার ওপরই নির্ভর করে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মাঠে কেউ না মানলে নিয়মের কোনো দাম নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'আইনের নিয়ম শুধু অফিসের ফাইলেই আটকে থাকে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অভিজ্ঞ হাত থাকলে নিয়ম না মানলেও কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'তদন্তে শুধু লাইনম্যানের মুখের কথাই শোনা হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'জরিমানা শুধু কোম্পানির হয়, কর্মীর নয়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'নিয়ম মানলে কাজ দেরি হয়, তাই বাদ দিন', correct: false),
    ],
  ),
);

/// The board's fixed lines: the guide's intro and closing line, and the
/// careless coworker's lines. [rivalExit] is already in his recorded voice;
/// [toRecord] stay silent (caption held for reading) until the director
/// records them with `tool/rival_clip.py`.
abstract final class M7Board71Lines {
  /// DRAFT wording — owner.
  static const intro = 'বিদ্যুতের কাজেরও রুলবুক আছে — অ্যাক্ট আর CEA নিয়ম। মাঠে কোনটা আইন মেনেছে, চিনে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'ডেঞ্জার প্লেট, আর্থিং আর উপযুক্ত ব্যক্তি — CEA নিয়ম মাঠেরই আইন; কাজ অসুরক্ষিত মনে হলে প্রশ্ন করুন।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'আইনের বই পড়ে কি লাইন চলে? কাজ তো হাতে হয়!';

  /// Lesson 7.1's first myth, word for word (ruling M7-10; not new text, but
  /// it needs a clip).
  static const rivalMyth = 'এসব আইনকানুন তো শুধু কাগজের জন্য, মাঠে কেউ মানে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Rulings M6-12 / M7-10: the rival's new lines (the taunt is a draft; the
  /// myth is the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// Rulings M6-12 / M7-10: every guide line on this board, for the owner's
  /// wording pass and the voice session (lesson quotes in the trap reasons
  /// included, since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting, the myth's right reasons, the earned
  /// line).
  static List<String> get guideSpoken {
    final p = learnBoardPack71;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      p.myth.stingBn,
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
