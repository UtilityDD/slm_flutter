import 'learn_board_models.dart';

/// Module 5 Lesson 5.9 (কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা), the picture board
/// (rung `5.9/learn`, pack `learn_5_9`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board59_art.py`. Every round
/// and every trap comes from the lesson text (spec
/// `docs/module_specs/module5_items/board_59.json`, rulings
/// `docs/module_specs/module5_rulings.md`):
///  * cause: a digging machine hitting the cable (the most common cause),
///    moisture in a joint, rats or termites cutting the sheath; a UG cable is
///    safe from the weather, and a dry, well-made joint is no cause;
///  * short: zero or very low megger reading between two cores (R, Y) =
///    short circuit; a high reading = no short; core-to-armour low = earth
///    fault; no continuity beep across a core's ends = open circuit;
///  * earth: very low reading between one core (Y) and the armour = earth
///    fault; core-to-core low = short; a high core-to-armour reading = no
///    earth fault; continuity end to end finds a cut core;
///  * route: walk the route with the map; fresh digging, wet or burnt patches;
///    open the joint pits and look for burn marks; a hole off the route is not
///    this cable's clue; no map = "throwing stones in the dark";
///  * locate: the TDR gives the distance in metres; the thumper's 'thump' is
///    heard with a special microphone; before digging the owners of the other
///    underground lines are asked (ruling M5-7); trenching the whole route is
///    what the tools prevent; UG fault work is a specialist job (myth 2).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack59 = LearnBoardPack(
  lessonId: '5.9',
  titleBn: 'কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'মাটির নিচের ফল্ট চোখে দেখা যায় না — সূত্র আর যন্ত্র ধরে অদৃশ্য শত্রুকে খুঁজুন।',
  earnedBn: 'মেগারে ফল্টের ধরন, রুটে সূত্র, TDR-থাম্পারে জায়গা — জানিয়ে তবেই খোঁড়া।',
  slots: [
    LearnBoardSlot(
      id: 'cause',
      promptBn: 'কোনটা ইউজি কেবিল ফল্টের সাধারণ কারণ?',
      options: [
        LearnBoardOption(
          id: 'dig',
          labelBn: 'খোঁড়ার সময় যন্ত্রের আঘাত কেবিলে',
          asset: 'assets/game/art/m5_board59/cause_dig.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'joint',
          labelBn: 'জয়েন্টে আর্দ্রতা ঢুকে পড়া',
          asset: 'assets/game/art/m5_board59/cause_joint.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rat',
          labelBn: 'ইঁদুর-উইপোকায় কাটা আবরণ',
          asset: 'assets/game/art/m5_board59/cause_rat.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'storm',
          labelBn: 'ঝড়ে ওভারহেড তারের দোলা',
          asset: 'assets/game/art/m5_board59/cause_storm.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইউজি কেবিল আবহাওয়া থেকে সুরক্ষিত — বিপদ মাটি খোঁড়া, আর্দ্রতা, রাসায়নিক আর জয়েন্ট।',
        ),
        LearnBoardOption(
          id: 'dry',
          labelBn: 'শুকনো, ঠিকঠাক করা জয়েন্ট',
          asset: 'assets/game/art/m5_board59/cause_dry.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্দ্রতা ঢুকলে বা ভুলভাবে করা হলে তবেই জয়েন্ট খারাপ হয়।',
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'ওভারহেড তারে গাছের ডাল',
          asset: 'assets/game/art/m5_board59/cause_branch.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওটা ওভারহেড লাইনের বিপদ — ইউজি কেবিলে ফল্ট আনে খোঁড়ার আঘাত, আর্দ্রতা, রাসায়নিক আর জয়েন্ট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মাটি খোঁড়ার আঘাতই কেবিল ফল্টের সাধারণ কারণ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জয়েন্টই কেবিল সিস্টেমের সবচেয়ে দুর্বল অংশ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আর্দ্রতা আর রাসায়নিকে ইনসুলেশন দুর্বল হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ইঁদুর-উইপোকা আবরণ কেটে ইনসুলেশন নষ্ট করে', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'মাটির নিচের কেবিলে কখনো ফল্ট হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝড়-বাতাসই ইউজি কেবিলের সবচেয়ে বড় শত্রু', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জয়েন্টে জল ঢুকলেও ইনসুলেশনের ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আবরণ কাটা থাকলেও কেবিল নিরাপদে চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নতুন খোঁড়াখুঁড়ির সাথে কেবিল ফল্টের যোগ নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'short',
      promptBn: 'কোন রিডিং বলছে R আর Y কোরের মধ্যে শর্ট সার্কিট?',
      options: [
        LearnBoardOption(
          id: 'needle',
          labelBn: 'R–Y মেগারে কাঁটা শূন্যে',
          asset: 'assets/game/art/m5_board59/short_needle.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'digital',
          labelBn: 'R–Y ডিজিটাল মেগারে 0.00 MΩ',
          asset: 'assets/game/art/m5_board59/short_digital.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'inf',
          labelBn: 'R–Y মেগারে কাঁটা ∞-তে',
          asset: 'assets/game/art/m5_board59/short_inf.svg',
          scene: true,
          correct: false,
          rejectBn: "রিডিং বেশি মানে শর্ট নেই — শর্টে রিডিং 'শূন্য' বা খুব কম।",
        ),
        LearnBoardOption(
          id: 'armour',
          labelBn: 'R আর আর্মারের মধ্যে শূন্য',
          asset: 'assets/game/art/m5_board59/short_armour.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোর আর আর্মারের মধ্যে খুব কম রিডিং — এটা আর্থ ফল্ট।',
        ),
        LearnBoardOption(
          id: 'open',
          labelBn: 'R কোরের দুই প্রান্তে বিপ নেই',
          asset: 'assets/game/art/m5_board59/short_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোরের দুই প্রান্তে বিপ নেই মানে কোর ভেতরে কাটা — ওপেন সার্কিট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দুই কোরের মধ্যে শূন্য বা কম রিডিং মানে শর্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শর্ট সার্কিট মাপা হয় দুই কোরের মধ্যে, মেগারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফল্টের ধরন জানলে পরের পরীক্ষার যন্ত্র ঠিক হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দুই কোরের মধ্যে রিডিং বেশি হলেই শর্ট সার্কিট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কোর আর আর্মারের কম রিডিংও শর্ট সার্কিট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বিপ না হলেই বুঝবেন কোর দুটো শর্ট হয়েছে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফল্টের ধরন না জেনেও সোজা খুঁড়তে নামা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মেগারের কাঁটা যেদিকেই থাকুক, মানে একই কথা', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'earth',
      promptBn: 'কোন রিডিং বলছে Y কোরে আর্থ ফল্ট?',
      options: [
        LearnBoardOption(
          id: 'needle',
          labelBn: 'Y আর আর্মারে কাঁটা শূন্যে',
          asset: 'assets/game/art/m5_board59/earth_needle.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'digital',
          labelBn: 'Y–আর্মার ডিজিটালে 0.00 MΩ',
          asset: 'assets/game/art/m5_board59/earth_digital.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'yb',
          labelBn: 'Y–B মেগারে কাঁটা শূন্যে',
          asset: 'assets/game/art/m5_board59/earth_yb.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুই কোরের মধ্যে কম রিডিং শর্ট সার্কিট — আর্থ ফল্ট দেখতে কোর আর আর্মারের মধ্যে মাপুন।',
        ),
        LearnBoardOption(
          id: 'inf',
          labelBn: 'Y–আর্মার ডিজিটালে ∞',
          asset: 'assets/game/art/m5_board59/earth_inf.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোর আর আর্মারের মধ্যে রিডিং বেশি মানে আর্থ ফল্ট নেই — আর্থ ফল্টে রিডিং খুব কম।',
        ),
        LearnBoardOption(
          id: 'beep',
          labelBn: 'Y কোরের দুই প্রান্তে বিপ',
          asset: 'assets/game/art/m5_board59/earth_beep.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্টিনিউটি কাটা কোর ধরে — আর্থ ফল্ট মেগারে কোর-আর্মারে মাপুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কোর-আর্মারে খুব কম রিডিং মানে আর্থ ফল্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আর্থ ফল্ট মাপতে মেগার লাগে কোর আর আর্মারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দুই কোরে কম রিডিং শর্ট, আর্মারে কম রিডিং আর্থ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আর্থ ফল্ট দেখতে দুই কোরের মধ্যে মাপলেই হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কোর-আর্মারে রিডিং বেশি মানেই আর্থ ফল্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কন্টিনিউটির বিপ শুনেই আর্থ ফল্ট ধরা পড়ে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্মারে কম রিডিং থাকলেও কেবিল ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আর্থ ফল্ট শুধু চোখে দেখেই বুঝে ফেলা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'route',
      promptBn: 'কেবিলের রুট ধরে হেঁটে খুঁজছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'dig',
          labelBn: 'রুটের ওপর নতুন খোঁড়ার দাগ',
          asset: 'assets/game/art/m5_board59/route_dig.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'burn',
          labelBn: 'রুটের ওপর ভেজা-পোড়া জায়গা',
          asset: 'assets/game/art/m5_board59/route_burn.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pit',
          labelBn: 'জয়েন্ট পিট খুলে পোড়া দাগ দেখা',
          asset: 'assets/game/art/m5_board59/route_pit.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'off',
          labelBn: 'রুটের বাইরের গর্তের পেছনে ছোটা',
          asset: 'assets/game/art/m5_board59/route_off.svg',
          scene: true,
          correct: false,
          rejectBn: 'রুটের বাইরের দাগ এই কেবিলের সূত্র নয়।',
        ),
        LearnBoardOption(
          id: 'shut',
          labelBn: 'বন্ধ পিট না খুলেই চলে যাওয়া',
          asset: 'assets/game/art/m5_board59/route_shut.svg',
          scene: true,
          correct: false,
          rejectBn: 'জয়েন্ট বক্স খুলে দেখুন ভেতরে পোড়া দাগ আছে কিনা।',
        ),
        LearnBoardOption(
          id: 'nomap',
          labelBn: 'রুট ম্যাপ ছাড়াই আন্দাজে হাঁটা',
          asset: 'assets/game/art/m5_board59/route_nomap.svg',
          scene: true,
          correct: false,
          rejectBn: 'রুট ম্যাপ ছাড়া ইউজি কেবিলে কাজ অন্ধকারে ঢিল ছোঁড়ার মতো।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রুটে খোঁড়ার চিহ্ন, ভেজা বা পোড়া জায়গা দেখুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জয়েন্ট পিট খুলে ভেতরে পোড়া দাগ খুঁজুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সঠিক রুট ম্যাপ ছাড়া ইউজি কেবিলে কাজ নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রুটের বাইরের যেকোনো গর্তই এই কেবিলের সূত্র', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বন্ধ পিট খোলার দরকার নেই, ওপর থেকে দেখুন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অভিজ্ঞ চোখে রুট ম্যাপ ছাড়াই কেবিল মেলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মাটির দাগ দেখে ফল্টের কিছুই বোঝা যায় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রুটের ভেজা জায়গা মানে শুধু বৃষ্টি, ফল্ট নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'locate',
      promptBn: 'ফল্টের জায়গায় খুঁড়বেন — তার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'tdr',
          labelBn: 'TDR দিয়ে মিটারে ফল্টের দূরত্ব',
          asset: 'assets/game/art/m5_board59/locate_tdr.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'thump',
          labelBn: 'থাম্পার চালিয়ে মাইক্রোফোনে ঠক্ শোনা',
          asset: 'assets/game/art/m5_board59/locate_thump.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'call',
          labelBn: 'ভূগর্ভস্থ লাইনের মালিকদের আগে ফোন',
          asset: 'assets/game/art/m5_board59/locate_call.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'trench',
          labelBn: 'পুরো রুট জুড়ে নালা খুঁড়ে ফেলা',
          asset: 'assets/game/art/m5_board59/locate_trench.svg',
          scene: true,
          correct: false,
          rejectBn: 'থাম্পার আর TDR অপ্রয়োজনীয় খোঁড়াখুঁড়ি বন্ধ করে।',
        ),
        LearnBoardOption(
          id: 'nocall',
          labelBn: 'কাউকে না জানিয়েই খোঁড়া শুরু',
          asset: 'assets/game/art/m5_board59/locate_nocall.svg',
          scene: true,
          correct: false,
          rejectBn: 'খোঁড়ার আগে কেবিল রুট রেকর্ড দেখুন এবং অন্য ভূগর্ভস্থ লাইনের (টেলিফোন, জল, গ্যাস) মালিকদের জানান।',
        ),
        LearnBoardOption(
          id: 'alone',
          labelBn: 'ওভারহেড লাইনম্যান একা HV জয়েন্টে',
          asset: 'assets/game/art/m5_board59/locate_alone.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইউজি ফল্ট লোকেটিং আর জয়েন্টিং বিশেষ দক্ষতার কাজ — আলাদা প্রশিক্ষণ লাগে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'TDR সিগন্যাল ফেরার সময় মেপে দূরত্ব বলে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'থাম্পারের ঠক্ মাইক্রোফোনে শুনে জায়গা মেলে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'খোঁড়ার আগে অন্য ভূগর্ভস্থ লাইনের খোঁজ নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'TDR, থাম্পার অপ্রয়োজনীয় খোঁড়াখুঁড়ি কমায়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'পুরো রুট খুঁড়লেই ফল্ট সবচেয়ে দ্রুত মেলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'খোঁড়ার আগে কাউকে জানানোর দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ওভারহেডের জ্ঞানেই ইউজি জয়েন্টিং করা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আন্দাজে এক জায়গায় খুঁড়ে দেখাই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'থাম্পারের শব্দ মাটির ওপর শোনা যায় না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board59Lines.rivalTaunt,
    rivalLineBn: M5Board59Lines.rivalMyth,
    exitBn: M5Board59Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'মাটি খোঁড়ার আঘাত',
      'জয়েন্টে আর্দ্রতা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'আঘাত, আর্দ্রতা আর জয়েন্টে ইউজি কেবিলেও ফল্ট হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ইউজি কেবিলের ফল্ট খোঁজা ও মেরামত অনেক বেশি কঠিন', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আবহাওয়া থেকে বাঁচলেও মাটির রাসায়নিক ইনসুলেশন খায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মাটির নিচে থাকলে কেবিলে কোনো বিপদ পৌঁছায় না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ইউজি কেবিলের ফল্ট ওভারহেডের চেয়ে সহজে মেলে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মাটির রাসায়নিক কেবিলের কোনো ক্ষতিই করে না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'জয়েন্টে আর্দ্রতা ঢুকলেও কেবিল দিব্যি চলতে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ইউজি কেবিল একবার বসালে আর দেখার দরকারই নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'খোঁড়াখুঁড়ির আঘাতে কেবিলের আর্মার কখনো কাটে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held) until the director
/// records them with `tool/rival_clip.py`.
abstract final class M5Board59Lines {
  static const rivalTaunt = 'আরে, কেবিল তো মাটির নিচে! ওখানে আবার ফল্ট কীসের?';

  /// Lesson 5.9's first myth buster, word for word.
  static const rivalMyth = 'মাটির নিচে থাকায় ইউজি কেবিল ওভারহেড লাইনের চেয়ে অনেক বেশি নিরাপদ এবং এতে ফল্ট হয় না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
