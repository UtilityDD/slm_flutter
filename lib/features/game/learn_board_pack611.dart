import 'learn_board_models.dart';

/// Module 6 Lesson 6.11 (আর্থিং সিস্টেম: অদৃশ্য অভিভাবক), the picture board
/// (rung `6.11/learn`, pack `learn_6_11`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board611_art.py` (the only
/// labels a worker reads — the earth tester's reading, a pipe's length — are
/// stroke glyphs with English digits). Every round and trap comes from the
/// live lesson text and the Module 6 rulings
/// (`docs/module_specs/module6_rulings.md`, item spec
/// `docs/module_specs/module6_items/board_611.json`):
///  * role: why earthing matters (section 1) — the pillar's metal body bonded
///    (equipment earthing), the DTR neutral earthed (system earthing), double
///    earthing from two separate pits (pro tip 1). Traps: a new breaker with
///    its body unearthed, a pole's earth wire cut while the line runs (myth 1's
///    reality), an LA with no earth below (section 1: no fuse, breaker or LA
///    works without earthing);
///  * type: pipe and plate earthing (section 2) — a perforated GI pipe of
///    about 2.5-3 m driven upright; a 60 x 60 cm copper plate buried deep where
///    a very low resistance is needed (no 'সাবস্টেশনে' wording: the item spec).
///    Traps: any rusty iron rod (myth 2's reality), the GI pipe laid flat, a
///    short stub half above ground;
///  * joint: the patrol look at a pole's earth joint (section 3, pro tip 2,
///    maintenance) — a clean tight brass nut-bolt, a welded joint, a joint
///    brushed, greased and tightened. Traps: a rusty ordinary iron nut, the
///    earth wire only twisted on, a torn strip hanging;
///  * pit: building and caring for the pit (section 3 and 4) — charcoal and
///    salt round the electrode, water by funnel on a dry day, a clean concrete
///    chamber with its lid on. Traps: sand only, a broken chamber with no lid
///    and rubbish inside, a cracked dry pit never watered;
///  * test: soil and the test before sign-off (pro tips 3 and 4, ruling M6-13:
///    the instrument is [M6Board611Lines.earthTester] on screen, ≤ 5 Ω good) —
///    a reading inside 5 ohm then the signature, several electrodes joined in
///    rocky soil, bentonite in sandy soil. Traps: one untreated electrode in
///    rocky soil, a pit signed without a test, a high reading signed.
/// Five rounds (owner answers after Wave A: boards are 5 rounds). The item
/// spec's sixth round (the substation's touch and step potential, gravel and
/// earth mat — the lesson's engineering facts, not a lineman's pit) left the
/// board; its soil-and-test round took the electrodes and bentonite.
/// The rival's myth is the lesson's second myth, word for word (the item
/// spec's `mythBn`; board 4.6 used myth 1).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack611 = LearnBoardPack(
  lessonId: '6.11',
  titleBn: 'আর্থিং সিস্টেম: অদৃশ্য অভিভাবক',
  badgeBn: 'যন্ত্র গুরু',
  introBn: 'আর্থিং চোখে দেখা যায় না, কিন্তু ফল্টে এটাই মানুষ আর যন্ত্র বাঁচায়। ঠিক আর্থিং চিনে নিন।',
  earnedBn: 'ঠিক উপাদানের খাড়া ইলেক্ট্রোড, টাইট জোড়, যত্নে রাখা পিট — আর ${M6Board611Lines.earthTester}-এ 5 ওহমের মধ্যে, তবেই সই।',
  slots: [
    LearnBoardSlot(
      id: 'role',
      promptBn: 'ফল্ট হলে সুরক্ষা ঠিক কাজ করবে — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'body',
          labelBn: 'পিলারের ধাতব বডি আর্থ পাতে শক্ত করে বাঁধা',
          asset: 'assets/game/art/m6_board611/role_body.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'ট্রান্সফরমারের নিউট্রাল পয়েন্ট আর্থ করা আছে',
          asset: 'assets/game/art/m6_board611/role_neutral.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'double',
          labelBn: 'DTR-এ দুটো আলাদা পিট থেকে ডাবল আর্থিং',
          asset: 'assets/game/art/m6_board611/role_double.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'unearthed',
          labelBn: 'নতুন ব্রেকার বসানো, তার বডিতে কোনো আর্থ নেই',
          asset: 'assets/game/art/m6_board611/role_unearthed.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই বডিতে আর্থ নেই — লাইভ তার বডিতে ঠেকলে লো-রেজিস্ট্যান্স পথ পাবে না, ফিউজ বা ব্রেকার ট্রিপ করবে না।',
        ),
        LearnBoardOption(
          id: 'cut',
          labelBn: 'পোলের আর্থ তার কাটা, লাইন দিব্যি চলছে',
          asset: 'assets/game/art/m6_board611/role_cut.svg',
          scene: true,
          correct: false,
          // Lesson 6.11 myth 1's reality.
          rejectBn: 'লাইন স্বাভাবিক অবস্থায় চলবে, কিন্তু ফল্টের সময় আর্থিং কাজ না করলে সার্কিট ব্রেকার ট্রিপ করবে না।',
        ),
        LearnBoardOption(
          id: 'la',
          labelBn: 'পোলে LA বসানো, কিন্তু নিচে আর্থ লিড নেই',
          asset: 'assets/game/art/m6_board611/role_la.svg',
          scene: true,
          correct: false,
          // Lesson 6.11 section 1 'importance'.
          rejectBn: 'এই LA-র নিচে আর্থ নেই — আর্থিং ছাড়া কোনো সুরক্ষা ডিভাইস (ফিউজ, ব্রেকার, LA) সঠিকভাবে কাজ করতে পারে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বডি আর্থ থাকলে ফল্টে ফিউজ-ব্রেকার ট্রিপ করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নিউট্রাল আর্থ সিস্টেমের ভোল্টেজ স্থির রাখে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দুটো আলাদা পিট — একটা ব্যর্থ হলেও অন্যটা আছে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আর্থিং ছাড়া ফিউজ, ব্রেকার বা LA কাজ করে না', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'লাইন চলছে মানেই আর্থিং একদম ঠিকঠাক আছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আর্থ তার শুধু দেখানোর জন্য, কোনো কাজে লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নতুন ব্রেকারের বডিতে আলাদা আর্থ লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'একটা পিটই যথেষ্ট, দুটো পিট বাড়তি খরচ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'LA নিজেই সুরক্ষা দেয়, আর্থ ছাড়াও চলে', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'আর্থ তার একটু কাটা থাকলে কিছুই হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'type',
      promptBn: 'নতুন আর্থ ইলেক্ট্রোড বসছে — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'pipe',
          labelBn: 'ছিদ্রওয়ালা GI পাইপ, 2.5-3 মিটার, খাড়া পোঁতা',
          asset: 'assets/game/art/m6_board611/type_pipe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'plate',
          labelBn: '60 x 60 সেমি তামার প্লেট মাটির গভীরে পোঁতা',
          asset: 'assets/game/art/m6_board611/type_plate.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rod',
          labelBn: 'মরিচা ধরা যেকোনো একটা লোহার রড পোঁতা',
          asset: 'assets/game/art/m6_board611/type_rod.svg',
          scene: true,
          correct: false,
          // Lesson 6.11 myth 2's reality.
          rejectBn: 'কার্যকর আর্থিং-এর জন্য সঠিক উপাদান (যেমন GI বা কপার) চাই — এটা একটা বিজ্ঞান, শুধু একটা রড পুঁতে দেওয়া নয়।',
        ),
        LearnBoardOption(
          id: 'flat',
          labelBn: 'GI পাইপটা গর্তে শুইয়ে রেখে মাটি চাপা',
          asset: 'assets/game/art/m6_board611/type_flat.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই পাইপ শুইয়ে রাখা — পাইপ আর্থিং-এ GI পাইপ মাটিতে উল্লম্বভাবে পোঁতা হয়, ইনস্টলেশনের পদ্ধতিও জরুরি।',
        ),
        LearnBoardOption(
          id: 'stub',
          labelBn: 'ছোট্ট এক টুকরো পাইপ, অর্ধেক মাটির ওপরে',
          asset: 'assets/game/art/m6_board611/type_stub.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই পাইপ খুব ছোট — মাটির সাথে বিশাল পৃষ্ঠতলের সংযোগ চাই, তাই সাধারণত 2.5-3 মিটার পাইপ পোঁতা হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'GI বা কপার, সঠিক দৈর্ঘ্য, সঠিক পদ্ধতি চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'GI পাইপ 2.5-3 মিটার লম্বা, খাড়া করে পোঁতা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মাটির সাথে বড় সংযোগে ফল্ট কারেন্ট ছড়ায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো লোহার রড পুঁতলেই ভালো আর্থিং', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পাইপ শুইয়ে দিলেও আর্থিং একই রকম হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পাইপ যত ছোট হয়, আর্থিং তত ভালো হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মরিচা ধরা রডেই আর্থ সবচেয়ে ভালো ধরে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'উপাদান কিছু নয়, শুধু রড পোঁতাটাই আসল', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অর্ধেক পাইপ ওপরে থাকলে দেখতে সুবিধা', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'joint',
      promptBn: 'পেট্রোলিং-এ পোলের আর্থ জোড় দেখছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'brass',
          labelBn: 'পরিষ্কার, টাইট পিতলের নাট-বল্টুর জোড়',
          asset: 'assets/game/art/m6_board611/joint_brass.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'weld',
          labelBn: 'আর্থ পাত ওয়েল্ডিং করা মজবুত জোড়',
          asset: 'assets/game/art/m6_board611/joint_weld.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'grease',
          labelBn: 'ব্রাশে পরিষ্কার করে, গ্রিজ দিয়ে টাইট',
          asset: 'assets/game/art/m6_board611/joint_grease.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'iron',
          labelBn: 'সাধারণ লোহার নাট, মরিচায় লাল হয়ে আছে',
          asset: 'assets/game/art/m6_board611/joint_iron.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই নাটে মরিচা ধরেছে — আর্থিং কানেকশনে সাধারণ নাট-বল্টুর বদলে পিতল বা স্টেইনলেস স্টিলের নাট-বল্টু দিন।',
        ),
        LearnBoardOption(
          id: 'twist',
          labelBn: 'আর্থ তার শুধু পেঁচিয়ে রাখা, ঢিলে',
          asset: 'assets/game/art/m6_board611/joint_twist.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই জোড় শুধু পেঁচানো, ঢিলে — জোড় মজবুত, পরিষ্কার ও টাইট চাই; লুজ জোড় আর্থের রেজিস্ট্যান্স বহুগুণ বাড়ায়।',
        ),
        LearnBoardOption(
          id: 'torn',
          labelBn: 'আর্থ পাত ছিঁড়ে গিয়ে পোলের নিচে ঝুলছে',
          asset: 'assets/game/art/m6_board611/joint_torn.svg',
          scene: true,
          correct: false,
          // Lesson 6.11 section 3.
          rejectBn: 'এই পাত ছেঁড়া — আর্থিং তার বা পাতটি কোথাও কাটা, ছেঁড়া বা অতিরিক্ত মরিচা ধরা উচিত নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জোড় মজবুত, পরিষ্কার আর টাইট হওয়া চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পিতল বা স্টেইনলেসের নাটে সহজে মরিচা ধরে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লুজ জোড়ে আর্থের রেজিস্ট্যান্স বহুগুণ বাড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পেট্রোলিং-এ প্রতিটি পোলের আর্থ চোখে দেখা', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'সাধারণ লোহার নাটই আর্থিং-এ সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তার পেঁচিয়ে দিলেই জোড় পাকা হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একটু মরিচা থাকলে আর্থ আরও ভালো ধরে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছেঁড়া পাত মাটি ছুঁয়ে থাকলেই আর্থ হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আর্থের জোড় দেখা শুধু অফিসারের কাজ', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'ঢিলে জোড়েও রেজিস্ট্যান্স একই থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pit',
      promptBn: 'আর্থ পিটের ভেতরটা দেখছেন — কোন যত্নটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'salt',
          labelBn: 'ইলেক্ট্রোড ঘিরে কাঠকয়লা আর লবণের স্তর',
          asset: 'assets/game/art/m6_board611/pit_salt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'water',
          labelBn: 'শুকনো দিনে ফানেল দিয়ে পিটে জল ঢালা',
          asset: 'assets/game/art/m6_board611/pit_water.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lid',
          labelBn: 'পরিষ্কার কংক্রিট চেম্বার, ঢাকনা লাগানো',
          asset: 'assets/game/art/m6_board611/pit_lid.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sand',
          labelBn: 'ইলেক্ট্রোডের চারপাশে শুধু বালি ভরা',
          asset: 'assets/game/art/m6_board611/pit_sand.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু বালিতে রেজিস্ট্যান্স বেশি — ইলেক্ট্রোড ঘিরে কাঠকয়লা ও লবণের স্তর পরিবাহিতা বাড়ায়, আর্দ্রতা ধরে রাখে।',
        ),
        LearnBoardOption(
          id: 'broken',
          labelBn: 'চেম্বার ভাঙা, ঢাকনা নেই, ভেতরে আবর্জনা',
          asset: 'assets/game/art/m6_board611/pit_broken.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই পিট ভাঙা, খোলা — আর্থ পিটের চারপাশ পরিষ্কার, কংক্রিটের চেম্বারে সুরক্ষিত আর ঢাকনা ঠিকমতো লাগানো থাকবে।',
        ),
        LearnBoardOption(
          id: 'dry',
          labelBn: 'মাটি ফেটে চৌচির, পিটে কখনো জল পড়েনি',
          asset: 'assets/game/art/m6_board611/pit_dry.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই পিট শুকিয়ে ফেটেছে — শুকনো আবহাওয়ায় পিটে জল দিলে চারপাশের মাটির আর্দ্রতা বাড়ে, আর্থ রেজিস্ট্যান্স কমে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কয়লা-লবণ পরিবাহিতা বাড়ায়, আর্দ্রতা রাখে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শুকনো দিনে জল দিলে আর্থ রেজিস্ট্যান্স কমে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পিট পরিষ্কার, চেম্বারে ঢাকা, ঢাকনা লাগানো', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শুধু বালি ভরলে আর্থিং সবচেয়ে ভালো হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পিটে জল দিলে আর্থ রেজিস্ট্যান্স বেড়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঢাকনা না থাকলে পিটে বাতাস ঢোকে, তাই ভালো', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পিট একবার বানালে আর দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আবর্জনা জমলে পিট আরও বেশি ভিজে থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কাঠকয়লা-লবণ শুধু খরচ, কোনো কাজে লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'test',
      promptBn: 'নতুন DTR-এর আর্থ পিট সই করার আগে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'ok',
          labelBn: '${M6Board611Lines.earthTester}-এ 3.2 ওহম, 5-এর মধ্যে — তবে সই',
          asset: 'assets/game/art/m6_board611/test_ok.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'multi',
          labelBn: 'পাথুরে মাটিতে কয়েকটা ইলেক্ট্রোড জুড়ে দেওয়া',
          asset: 'assets/game/art/m6_board611/test_multi.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bento',
          labelBn: 'বালুমাটিতে বেন্টোনাইট দিয়ে মাটির ট্রিটমেন্ট',
          asset: 'assets/game/art/m6_board611/test_bento.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'পাথুরে মাটিতে একটাই ইলেক্ট্রোড, ট্রিটমেন্ট নেই',
          asset: 'assets/game/art/m6_board611/test_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'পাথুরে বা বালুকাময় মাটির রেজিস্ট্যান্স বেশি — এখানে একাধিক ইলেক্ট্রোড বা বেন্টোনাইট ট্রিটমেন্ট লাগে।',
        ),
        LearnBoardOption(
          id: 'skip',
          labelBn: '${M6Board611Lines.earthTester}-এ না মেপেই পিট সই করে দেওয়া',
          asset: 'assets/game/art/m6_board611/test_skip.svg',
          scene: true,
          correct: false,
          // Lesson 6.11 pro tip 4 (its 'আর্থ মেগার' is the constant on screen, ruling M6-13).
          rejectBn: 'এই পিট মাপাই হয়নি — ${M6Board611Lines.earthTester} দিয়ে রেজিস্ট্যান্স মাপাই আর্থিং-এর স্বাস্থ্য পরীক্ষার সবচেয়ে নির্ভরযোগ্য উপায়।',
        ),
        LearnBoardOption(
          id: 'high',
          labelBn: '${M6Board611Lines.earthTester}-এ 18 ওহম, তবু সই করে দেওয়া',
          asset: 'assets/game/art/m6_board611/test_high.svg',
          scene: true,
          correct: false,
          rejectBn: 'এখানে 18 ওহম — আর্থ রেজিস্ট্যান্স নির্দিষ্ট সীমার (যেমন 5 ওহম) মধ্যে থাকা উচিত, বেশি হলে আর্থিং দুর্বল।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আর্থ রেজিস্ট্যান্স 5 ওহমের মধ্যে থাকা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মেপে দেখাই আর্থের সবচেয়ে ভরসার পরীক্ষা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পাথুরে মাটিতে একাধিক ইলেক্ট্রোড জুড়তে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চোখে ঠিক লাগলে মাপার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রিডিং যত বেশি, আর্থিং তত মজবুত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মাটি যেমনই হোক, একটা ইলেক্ট্রোডই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পাথুরে মাটিতে আর্থ এমনিতেই ভালো হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বেন্টোনাইট দিলে মানে কোনো ফারাক হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: '18 ওহম হলেও সই করে দিলে কোনো ক্ষতি নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board611Lines.rivalTaunt,
    rivalLineBn: M6Board611Lines.rivalMyth,
    exitBn: M6Board611Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ফল্টে ট্রিপ হবে না',
      'বডিতে কারেন্ট থেকে যাবে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'উপাদান চাই GI বা কপার, যেকোনো লোহা নয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'সঠিক দৈর্ঘ্য আর সঠিক পদ্ধতিতে পোঁতা চাই', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'মাটির অবস্থাও জরুরি — আর্থিং একটা বিজ্ঞান', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'যেকোনো লোহার রডেই ভালো আর্থিং হয়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'রডে মরিচা ধরলে আর্থ আরও ভালো ধরে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'রড যত ছোট, পোঁতা তত সহজ, তাই ভালো', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'মাটি যেমনই হোক, একটা রড পুঁতলেই চলে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'আর্থ মাপার দরকার নেই, একটা রডই যথেষ্ট', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'পোলে তার জড়িয়ে দিলেও আর্থ হয়ে যায়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M6Board611Lines {
  /// The earth-resistance instrument's on-screen name, in one place (ruling
  /// M6-13; owner after Wave A: 'আর্থ টেস্টার'). The lesson's own word is
  /// 'আর্থ মেগার'; switch here if a WBSEDCL lineman says that is the field word.
  static const earthTester = 'আর্থ টেস্টার';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'এত কয়লা-লবণ, এত মাপজোখ! আমরা তো এমনিই কাজ সারি।';

  /// Lesson 6.11's second myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'যেকোনো একটি লোহার রড মাটিতে পুঁতে দিলেই ভালো আর্থিং হয়ে যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack611;
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
