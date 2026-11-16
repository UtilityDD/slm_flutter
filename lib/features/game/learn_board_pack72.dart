import 'learn_board_models.dart';

/// Module 7 Lesson 7.2 (ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট: দুর্ঘটনার পর আপনার
/// অধিকার), the picture board (rung `7.2/learn`, pack `learn_7_2`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board72_art.py` (no words in
/// the art; no amounts, no day counts, no death scene). Every round and trap
/// comes from the live lesson text (`tool/all_training_chapters_bn.json`, 7.2)
/// and the Module 7 rulings (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_72.json`):
///  * who: section point 1 — the law covers hazardous work, electrical work
///    included, and permanent, temporary and contract workers alike;
///  * partial: point 2 — permanent partial disablement (a finger, hand or eye
///    lost, other work still possible) told apart from temporary disablement
///    (back at work after weeks or months) and permanent total (no work at
///    all). The death head is not drawn on the board;
///  * rights: point 3 — treatment cost is wholly the employer's, an allowance
///    while under treatment, occupational disease is covered too;
///  * steps: point 4 steps 1–2 — tell the supervisor at once; the injury
///    report by a government or company doctor (a legal document);
///  * claim: point 4 steps 3–4 and pro tip 3 — a written notice, keep every
///    paper, the Labour Commissioner when the company refuses or pays less.
///    Ruling X6 trims the item spec's six rounds to five: its paperwork round
///    and its claim round are one round here (the nominee and union tips are
///    in the reason chips).
/// No deadly anywhere on this lesson (ruling M7-6); boards have no freeze. The
/// rival's myth is the lesson's first myth, word for word (ruling M7-10).
/// L7.2-2 answered: the levels never name the Act (they say «আইন»); the
/// lesson title shown in the board header is a lesson matter for the
/// director.
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack72 = LearnBoardPack(
  lessonId: '7.2',
  titleBn: 'ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট: দুর্ঘটনার পর আপনার অধিকার',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board72Lines.intro,
  earnedBn: M7Board72Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'who',
      promptBn: 'কাজের সময় দুর্ঘটনা — এই আইন কাদের সুরক্ষা দেয়?',
      options: [
        LearnBoardOption(
          id: 'perm',
          labelBn: 'স্থায়ী লাইনম্যান — পোলে কাজের সময় আহত',
          asset: 'assets/game/art/m7_board72/who_perm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'contract',
          labelBn: 'চুক্তির কর্মী — লাইন টানার সময় আহত',
          asset: 'assets/game/art/m7_board72/who_contract.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'temp',
          labelBn: 'অস্থায়ী হেল্পার — ক্রস-আর্ম বইতে আহত',
          asset: 'assets/game/art/m7_board72/who_temp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clerk',
          labelBn: 'অফিস বলছে: চুক্তির কর্মী, আপনার জন্য নয়',
          asset: 'assets/game/art/m7_board72/who_clerk.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল — আইনটি স্থায়ী, অস্থায়ী, চুক্তিভিত্তিক অনেক ধরনের কর্মীর জন্যই প্রযোজ্য।',
        ),
        LearnBoardOption(
          id: 'tempno',
          labelBn: 'অফিস বলছে: অস্থায়ী, তাই কিছু পাবেন না',
          asset: 'assets/game/art/m7_board72/who_tempno.svg',
          scene: true,
          correct: false,
          rejectBn: 'অস্থায়ী কর্মীও এই আইনের সুরক্ষা পান — শুধু স্থায়ী কর্মী নয়।',
        ),
        LearnBoardOption(
          id: 'notice',
          labelBn: 'নোটিশ বোর্ড: বিদ্যুতের কাজ আইনের বাইরে',
          asset: 'assets/game/art/m7_board72/who_notice.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল — ঝুঁকিপূর্ণ কাজের মধ্যে বিদ্যুৎ-এর কাজও অন্তর্ভুক্ত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্থায়ী, অস্থায়ী, চুক্তির — সবাই সুরক্ষা পান', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বিদ্যুতের কাজও আইনের ঝুঁকির কাজের মধ্যে পড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাজের কারণে চোট হলে কোম্পানি দিতে বাধ্য', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শুধু স্থায়ী কর্মীরাই এই আইনের সুরক্ষা পান', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চুক্তির কর্মী হলে কোনো ক্ষতিপূরণ নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বিদ্যুতের কাজ তো এই আইনের আওতার বাইরে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অস্থায়ী হেল্পার আহত হলে কিছুই পান না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কোম্পানি চাইলে দেবে, না চাইলে দেবে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আইনটা শুধু কারখানা আর খনির কর্মীদের', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'partial',
      promptBn: 'স্থায়ী আংশিক অক্ষমতা — কোন ছবিটা মেলে?',
      options: [
        LearnBoardOption(
          id: 'finger',
          labelBn: 'আঙুল নেই, এখন স্টোরে অন্য কাজ করছেন',
          asset: 'assets/game/art/m7_board72/partial_finger.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'eye',
          labelBn: 'এক চোখ নষ্ট, এখন অফিসের টেবিলে কাজে',
          asset: 'assets/game/art/m7_board72/partial_eye.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'plaster',
          labelBn: 'পায়ে চোট, কয়েক সপ্তাহ পরে আবার পোলে',
          asset: 'assets/game/art/m7_board72/partial_plaster.svg',
          scene: true,
          correct: false,
          rejectBn: 'কয়েক সপ্তাহ পরে আবার কাজে ফিরেছেন — এটা অস্থায়ী অক্ষমতা।',
        ),
        LearnBoardOption(
          id: 'bed',
          labelBn: 'বাড়িতে শয্যাশায়ী, কোনো কাজই আর পারেন না',
          asset: 'assets/game/art/m7_board72/partial_bed.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোনো ধরনের কাজ করার ক্ষমতাই হারালে — সেটা স্থায়ী সম্পূর্ণ অক্ষমতা।',
        ),
        LearnBoardOption(
          id: 'burn',
          labelBn: 'হাত পুড়েছিল, কয়েক মাস পরে একই কাজে',
          asset: 'assets/game/art/m7_board72/partial_burn.svg',
          scene: true,
          correct: false,
          rejectBn: 'কয়েক মাস কাজে অক্ষম, পরে একই কাজে ফিরেছেন — এটা অস্থায়ী অক্ষমতা।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অঙ্গ নষ্ট, তবু অন্য কাজ পারেন — স্থায়ী আংশিক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আঙুল, হাত বা চোখ গেলেও অন্য কাজ করা যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অঙ্গ চিরকালের মতো গেছে, তাই এটা স্থায়ী', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কয়েক সপ্তাহ পরে কাজে ফিরলেও আংশিক স্থায়ী', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কোনো কাজই না পারলে সেটা আংশিক অক্ষমতা', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অঙ্গ নষ্ট হলে আর কোনো ক্ষতিপূরণ নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অন্য কাজ পারলে তো সেটা অক্ষমতাই নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'হাসপাতালে কদিন থাকলেই স্থায়ী অক্ষমতা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আঙুল গেলে ছোট চোট, হিসাবে ধরা হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'rights',
      promptBn: 'চিকিৎসার সময় আর কাজের রোগে আপনার অধিকার — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'pay',
          labelBn: 'হাসপাতালের বিল মেটাচ্ছে কোম্পানির অফিসার',
          asset: 'assets/game/art/m7_board72/rights_pay.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'allow',
          labelBn: 'হাসপাতালের বেডে চিকিৎসার সময়ের ভাতা',
          asset: 'assets/game/art/m7_board72/rights_allow.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'disease',
          labelBn: 'রাসায়নিক থেকে কাজের রোগ — ক্ষতিপূরণের দাবি',
          asset: 'assets/game/art/m7_board72/rights_disease.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wife',
          labelBn: 'আহত কর্মীর স্ত্রী নিজেই বিল মেটাচ্ছেন',
          asset: 'assets/game/art/m7_board72/rights_wife.svg',
          scene: true,
          correct: false,
          rejectBn: 'আইন অনুযায়ী, দুর্ঘটনাজনিত চিকিৎসা ব্যয় সম্পূর্ণরূপে নিয়োগকর্তার দায়িত্ব।',
        ),
        LearnBoardOption(
          id: 'payslip',
          labelBn: 'বেতনের স্লিপ: হাসপাতালের দিনের বেতন 0',
          asset: 'assets/game/art/m7_board72/rights_payslip.svg',
          scene: true,
          correct: false,
          rejectBn: 'অস্থায়ী অক্ষমতায় চিকিৎসাধীন থাকার সময় নির্দিষ্ট হারে বেতন বা ভাতা পাওয়ার অধিকার আছে।',
        ),
        LearnBoardOption(
          id: 'wave',
          labelBn: 'কাশিতে ভোগা কর্মীকে: দুর্ঘটনা তো হয়নি',
          asset: 'assets/game/art/m7_board72/rights_wave.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু দুর্ঘটনা নয় — কাজের কারণে দীর্ঘস্থায়ী রোগ হলেও ক্ষতিপূরণ পাওয়া যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ক্ষতিপূরণ আপনার অধিকার, দয়া নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চিকিৎসা, ভাতা, কাজের রোগ — সবই আইনে আছে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চোট বা কাজের রোগে আইন কর্মীর পাশে থাকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চিকিৎসার বিল কর্মীর পরিবারকেই দিতে হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হাসপাতালে থাকার দিনগুলোর বেতন হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দুর্ঘটনা না হলে রোগের জন্য কিছুই নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্ষতিপূরণ কোম্পানির দয়া, চাইলে দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভাতা পেতে হলে আগে কাজে ফিরতে হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'চিকিৎসার অর্ধেক খরচ কর্মীকে দিতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'steps',
      promptBn: 'দুর্ঘটনার পরে — কোনটা ঠিক কাজ?',
      options: [
        LearnBoardOption(
          id: 'call',
          labelBn: 'চোটের সাথে সাথে সুপারভাইজারকে ফোন',
          asset: 'assets/game/art/m7_board72/steps_call.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'govdoc',
          labelBn: 'সরকারি হাসপাতালের ডাক্তার রিপোর্ট লিখছেন',
          asset: 'assets/game/art/m7_board72/steps_govdoc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'codoc',
          labelBn: 'কোম্পানির ডাক্তার আঘাতের রিপোর্ট লিখছেন',
          asset: 'assets/game/art/m7_board72/steps_codoc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hide',
          labelBn: 'চোট লুকিয়ে কাজ — কাউকে বলার দরকার নেই',
          asset: 'assets/game/art/m7_board72/steps_hide.svg',
          scene: true,
          correct: false,
          // Live lesson point 4, step 1, word for word.
          rejectBn: 'যেকোনো দুর্ঘটনা ঘটার সাথে সাথে আপনার সুপারভাইজার বা কর্তৃপক্ষকে জানান।',
        ),
        LearnBoardOption(
          id: 'late',
          labelBn: 'অনেক দিন পরে সুপারভাইজারকে জানানো',
          asset: 'assets/game/art/m7_board72/steps_late.svg',
          scene: true,
          correct: false,
          rejectBn: 'জানাতে হয় অবিলম্বে — দুর্ঘটনার সাথে সাথে, দিন গুনে নয়।',
        ),
        LearnBoardOption(
          id: 'shop',
          labelBn: 'ওষুধের দোকানের লোক একটা কাগজ লিখে দিলেন',
          asset: 'assets/game/art/m7_board72/steps_shop.svg',
          scene: true,
          correct: false,
          rejectBn: 'সরকারি বা কোম্পানির ডাক্তার দিয়ে আঘাতের রিপোর্ট করান — এটি একটি অত্যন্ত গুরুত্বপূর্ণ আইনি নথি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে জানানো, তারপর ঠিক ডাক্তারের রিপোর্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঠিক ধাপ মানলে ক্ষতিপূরণ পাওয়া সহজ হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ডাক্তারি রিপোর্ট একটা জরুরি আইনি নথি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছোট চোট হলে কাউকে জানানোর দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কয়েক দিন দেখে তারপর জানালেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেকোনো দোকানের লেখা কাগজই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্যথা সেরে গেলে ডাক্তারি রিপোর্ট লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আগে কাজ শেষ, দুর্ঘটনার কথা পরে হবে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রিপোর্ট নিজে হাতে লিখে দিলেই চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'claim',
      promptBn: 'কাগজপত্র আর দাবি — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'notice',
          labelBn: 'লিখিত নোটিশ কোম্পানিতে, কপি নিজের কাছে',
          asset: 'assets/game/art/m7_board72/claim_notice.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'file',
          labelBn: 'রিপোর্ট, বিল, চিঠি — সব কাগজ এক ফাইলে',
          asset: 'assets/game/art/m7_board72/claim_file.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'labour',
          labelBn: 'কম দিল — লেবার কমিশনারের কাছে আবেদন',
          asset: 'assets/game/art/m7_board72/claim_labour.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'guard',
          labelBn: 'গেটের দারোয়ানকে শুধু মুখে বলে দিলাম',
          asset: 'assets/game/art/m7_board72/claim_guard.svg',
          scene: true,
          correct: false,
          rejectBn: 'আইন অনুযায়ী, নির্দিষ্ট সময়ের মধ্যে কোম্পানিকে লিখিতভাবে দুর্ঘটনার নোটিশ দিতে হতে পারে।',
        ),
        LearnBoardOption(
          id: 'bin',
          labelBn: 'চিকিৎসার বিল ডাস্টবিনে — রেখে কী হবে',
          asset: 'assets/game/art/m7_board72/claim_bin.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাক্তারের রিপোর্ট, চিকিৎসার বিল আর কোম্পানির সাথে সব যোগাযোগের কপি যত্ন করে রাখুন।',
        ),
        LearnBoardOption(
          id: 'sign',
          labelBn: 'চুপচাপ সই: এটুকুই পাবেন, মেনে নিলাম',
          asset: 'assets/game/art/m7_board72/claim_sign.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ষতিপূরণের পরিমাণ আইন দ্বারা নির্ধারিত — কম দিলে লেবার কমিশনারের কাছে আবেদন করতে পারেন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লিখিত নোটিশ আর সব কাগজই দাবির ভিত্তি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্ষতিপূরণ আইনে ঠিক করা, মুখ বুজে মানবেন না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাগজ ঠিক রাখলে ক্ষতিপূরণ পাওয়া সহজ হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গেটে মুখে বলে দিলেই নোটিশ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চিকিৎসা শেষ হলে বিলগুলো ফেলে দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কোম্পানি যা দেয়, সেটাই মেনে নিতে হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নমিনির নাম একবার দিলে আর দেখতে হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আইনের ব্যাপারে ইউনিয়ন কিছু করতে পারে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লেবার কমিশনারের কাছে কর্মী যেতে পারেন না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board72Lines.rivalTaunt,
    rivalLineBn: M7Board72Lines.rivalMyth,
    exitBn: M7Board72Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board72Lines.sting,
    flipStingBn: M7Board72Lines.flipSting,
    dangerHints: [
      'অধিকার হারাবেন',
      'পরিবার বিপদে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'কাজের সময়, কাজের কারণে হলে দোষ যারই হোক', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'No-Fault নীতি: দোষ দেখে নয়, কাজ দেখে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'নিজের ভুল হলেও সাধারণত ক্ষতিপূরণ পাওয়া যায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'নিজের ভুলে দুর্ঘটনা হলে কোনো অধিকার নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'কোম্পানির দোষ প্রমাণ হলে তবেই ক্ষতিপূরণ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ভুলটা লুকিয়ে রাখলে তবেই টাকা পাওয়া যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আগে দোষ কার ঠিক হবে, তারপর চিকিৎসা', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'নিজের দোষে চোট মানে চুপ করে থাকাই ভালো', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'সাবধানে কাজ না করলে আইনের সুরক্ষা নেই', correct: false),
    ],
  ),
);

/// The board's spoken lines: the careless coworker's (his recorded voice) and
/// the guide's. [rivalExit], [sting] and [flipSting] are already recorded;
/// the rest wait for the voice session (ruling M7-10), silent with the
/// caption held until then (the rival never falls back to the device voice).
abstract final class M7Board72Lines {
  /// DRAFT wording — owner.
  static const intro = 'কাজে চোট পেলে আইন আপনার পাশে। কে পায়, কী পায়, আর তখন কী করবেন — চিনে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'সাথে সাথে জানান, সরকারি বা কোম্পানির ডাক্তারের রিপোর্ট নিন, সব কাগজ রাখুন — ক্ষতিপূরণ আপনার অধিকার, দয়া নয়।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'নিজের ভুলে চোট পেলে আবার কাগজপত্র কীসের?';

  /// Lesson 7.2's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'দুর্ঘটনাটি আমার নিজের ভুলেই হয়েছে, তাই আমি কোনো ক্ষতিপূরণ পাব না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (the board 6.3 sting, reused).
  static const sting = 'এই লোক যা বলছে… বিশ্বাস করেন?';

  /// Already recorded (boards 5.6–5.8): the flipped believe question (the
  /// runner flips it on half of all plays), so the kit's default "shortcut /
  /// save your life" line never plays on this paperwork board.
  static const flipSting = 'এই লোক যা বলছে… সেটা কি ভুল?';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Ruling M6-12 / M7-10: the rival's new lines (the taunt is a draft; the
  /// myth is the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// Ruling M6-12: every guide line on this board, for the owner's wording
  /// pass and the voice session (lesson quotes in the trap reasons included,
  /// since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting and its flipped form, the myth's right
  /// reasons, the earned line).
  static List<String> get guideSpoken {
    final p = learnBoardPack72;
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
      p.myth.flipStingBn,
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
