import 'learn_board_models.dart';

/// Module 6 Lesson 6.5 (আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো নেটওয়ার্ক), the
/// picture board (rung `6.5/learn`, pack `learn_6_5`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board65_art.py` (no words in
/// the art: the kit boxes carry a drawn cross-section of their cable type).
/// Every round and every trap comes from the lesson text (item spec
/// `docs/module_specs/module6_items/board_65.json`, Module 6 rulings):
///  * layers: an HT UG cable is a many-layered armour — the outer PVC jacket
///    keeps out moisture and chemicals, the steel armour takes blows and
///    digging, the copper metallic screen carries the earth fault current;
///  * kits: XLPE and PILC (paper + lead) need their own jointing kit, tools
///    and method; an overhead joint is not a UG joint (myth 2's reality);
///  * joint: HV jointing is specialist work (training and certification) and
///    needs a clean, dry place and dry hands — moisture, dust or sweat can
///    spoil the joint (pro tip 4). The pit art shows the red isolation tag
///    and a working earth on the cable: it is shut down, proved dead and
///    earthed before anyone works on it (ruling X1);
///  * termination: where the cable rises to a line or a DTR its end is sealed
///    in an end termination kit (moisture out, stress controlled); stress
///    control tubing spreads the stress where the screen ends; 90% of UG
///    faults are at terminations and joints. The DTR is drawn with no
///    drop-out fuse (ruling M6-2);
///  * lay: a new cable, not energised — no bend tighter than its minimum
///    bending radius (pro tip 2), the armour earthed at both ends (pro tip 3;
///    one end only is a slip, ruling M6-5), the jacket print read (pro tip 1).
/// The rival's myth is the lesson's first myth, word for word (its reality
/// says "মারাত্মক ভুল"; ruling M6-1/R25 make a digger strike on a live cable
/// deadly in do_6_5_b). The danger tags name the harm without sharing a word
/// with the right reason chips. Boards are not scored deadly/slip; a miss costs the
/// round's ◆ and a board with too many misses fails (the runner's rule).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12);
/// the lesson's own words (myth, rejects quoted from the lesson) are not new.
const learnBoardPack65 = LearnBoardPack(
  lessonId: '6.5',
  titleBn: 'আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো নেটওয়ার্ক',
  badgeBn: 'যন্ত্র গুরু',
  // DRAFT wording — owner.
  introBn: 'নেটওয়ার্কের বড় অংশ মাটির নিচে, চোখের আড়ালে। ইউজি কেবিলের স্তর, কিট আর জয়েন্ট চিনে নিন।',
  // DRAFT wording — owner.
  earnedBn: 'সব স্তর অটুট, ঠিক কিট, শুকনো-পরিষ্কার জয়েন্ট, সিল করা মুখ, আলতো বাঁক আর দুই প্রান্তে আর্মার আর্থ।',
  slots: [
    LearnBoardSlot(
      id: 'layers',
      promptBn: 'মাটির নিচে যাবে এমন কেবিল — কোনটার সব সুরক্ষা-স্তর অটুট?',
      options: [
        LearnBoardOption(
          id: 'whole',
          labelBn: 'কাটা মুখে প্রতিটি স্তর গোটা',
          asset: 'assets/game/art/m6_board65/layers_whole.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'stepped',
          labelBn: 'ধাপে ধাপে খোলা, সব স্তর গোটা',
          asset: 'assets/game/art/m6_board65/layers_stepped.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'jacket',
          labelBn: 'বাইরের PVC জ্যাকেটে ফাটল',
          asset: 'assets/game/art/m6_board65/layers_jacket.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাইরের জ্যাকেট ছেঁড়া — এই PVC স্তরই আর্দ্রতা আর রাসায়নিক থেকে কেবিল বাঁচায়।',
        ),
        LearnBoardOption(
          id: 'armour',
          labelBn: 'স্টিলের আর্মারে গভীর কাটা',
          asset: 'assets/game/art/m6_board65/layers_armour.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্মার কাটা — এই স্টিলের স্তরই আঘাত আর খোঁড়াখুঁড়ি থেকে কেবিল বাঁচায়।',
        ),
        LearnBoardOption(
          id: 'screen',
          labelBn: 'তামার স্ক্রিনের তার ছেঁড়া',
          asset: 'assets/game/art/m6_board65/layers_screen.svg',
          scene: true,
          correct: false,
          rejectBn: 'মেটালিক স্ক্রিন ছেঁড়া — আর্থ ফল্ট কারেন্টের পথ তো এটাই।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জ্যাকেট আর্দ্রতা আর রাসায়নিক থেকে বাঁচায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আর্মার আঘাত আর খোঁড়াখুঁড়ি থেকে বাঁচায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তামার স্ক্রিন আর্থ ফল্ট কারেন্টের পথ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জ্যাকেট শুধু দেখতে ভালো লাগার জন্য', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আর্মার কাটা থাকলেও ভেতরে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্ক্রিনের দু-একটা তার ছিঁড়লে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ইনসুলেশন ঠিক থাকলে বাকি স্তর লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মাটির নিচে কেবিলে আর্দ্রতা ঢোকেই না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'স্ক্রিন শুধু কেবিলকে মোটা করার জন্য', correct: false),
      ],
    ),
    // The card names show only on the card chosen (the runner), so each names
    // the cable and the kit: the verdict says what the cut end showed.
    // DRAFT wording — owner.
    LearnBoardSlot(
      id: 'kits',
      promptBn: 'কাটা মুখ দেখে চিনুন — কোন কেবিলের পাশে ঠিক জয়েন্টিং কিট?',
      options: [
        LearnBoardOption(
          id: 'xlpe',
          labelBn: 'XLPE কেবিলের পাশে XLPE জয়েন্টিং কিট',
          asset: 'assets/game/art/m6_board65/kits_xlpe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pilc',
          labelBn: 'PILC কেবিলের পাশে PILC জয়েন্টিং কিট',
          asset: 'assets/game/art/m6_board65/kits_pilc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'xlpe_pilc',
          labelBn: 'XLPE কেবিলের পাশে PILC জয়েন্টিং কিট',
          asset: 'assets/game/art/m6_board65/kits_xlpe_pilc.svg',
          scene: true,
          correct: false,
          rejectBn: 'XLPE আর PILC-র জয়েন্টিং কিট, টুলস আর পদ্ধতি সম্পূর্ণ আলাদা।',
        ),
        LearnBoardOption(
          id: 'pilc_xlpe',
          labelBn: 'PILC কেবিলের পাশে XLPE জয়েন্টিং কিট',
          asset: 'assets/game/art/m6_board65/kits_pilc_xlpe.svg',
          scene: true,
          correct: false,
          rejectBn: 'PILC কেবিলে XLPE-র কিট নয় — দুটির কিট আর পদ্ধতি সম্পূর্ণ আলাদা।',
        ),
        LearnBoardOption(
          id: 'sleeve',
          labelBn: 'XLPE কেবিলের পাশে ওভারহেডের স্লিভ',
          asset: 'assets/game/art/m6_board65/kits_sleeve.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওভারহেডের জয়েন্ট আর ইউজির জয়েন্ট এক নয় — স্তর পুনর্গঠন আর আর্দ্রতা রোধ লাগে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'XLPE আর PILC-র কিট ও পদ্ধতি সম্পূর্ণ আলাদা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আগে কাটা মুখ দেখে কেবিলের প্রকার চিনুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'PILC-তে তেলে ভেজা কাগজ আর সীসার আবরণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো কিটেই যেকোনো কেবিল জোড়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ওভারহেড আর ইউজির জয়েন্টিং একই কাজ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'PILC আর XLPE দেখতে আলাদা, কাজে এক', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কিট না মিললে টেপ পেঁচালেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নতুন XLPE কিট পুরনো PILC কেবিলেও চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কেবিলের প্রকার জানার কোনো দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'joint',
      promptBn: 'হাই-ভোল্টেজ কেবিল জয়েন্টিং চলছে — কোন ছবিতে কাজ ঠিক পথে?',
      options: [
        LearnBoardOption(
          id: 'certified',
          labelBn: 'আইডি কার্ড পরা জয়েন্টার, শুকনো গর্তে',
          asset: 'assets/game/art/m6_board65/joint_certified.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cover',
          labelBn: 'ছাউনির নিচে, হাত মুছে শুকিয়ে কাজ',
          asset: 'assets/game/art/m6_board65/joint_cover.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rain',
          labelBn: 'বৃষ্টির মধ্যেই খোলা জয়েন্টে কাজ',
          asset: 'assets/game/art/m6_board65/joint_rain.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্দ্রতা ঢুকলেই পুরো জয়েন্ট নষ্ট হয়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'dust',
          labelBn: 'ধুলো উড়ছে, ঘাম ঝরছে, কাজ চলছে',
          asset: 'assets/game/art/m6_board65/joint_dust.svg',
          scene: true,
          correct: false,
          rejectBn: 'সামান্য ধুলো বা ঘামও হাই-ভোল্টেজ জয়েন্ট নষ্ট করে দিতে পারে।',
        ),
        LearnBoardOption(
          id: 'helper',
          labelBn: 'আইডি ছাড়া হেল্পার জয়েন্ট করছে',
          asset: 'assets/game/art/m6_board65/joint_helper.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই কাজে আলাদা প্রশিক্ষণ আর সার্টিফিকেশন লাগে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আর্দ্রতা ঢুকলে পুরো জয়েন্ট নষ্ট হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সামান্য ধুলো বা ঘামও জয়েন্ট নষ্ট করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এই কাজে আলাদা প্রশিক্ষণ ও সার্টিফিকেশন লাগে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বৃষ্টিতে জয়েন্ট করলে তাড়াতাড়ি ঠান্ডা হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হাতে একটু ঘাম থাকলে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেকোনো হেল্পার দেখে দেখেই জয়েন্ট পারে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জয়েন্টে একটু কাদা লাগলে কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ইউজি জয়েন্ট ওভারহেডের মতোই সহজ কাজ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ধুলো শুধু বাইরে থাকে, ভেতরে যায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'term',
      promptBn: 'কেবিল মাটি থেকে উঠে লাইনে বা ট্রান্সফরমারে যাচ্ছে — কোন মুখটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'pole',
          labelBn: 'পোলে ওঠা কেবিলের মুখ কিটে সিল করা',
          asset: 'assets/game/art/m6_board65/term_pole.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dtr',
          labelBn: 'ট্রান্সফরমারে ঢোকা মুখ কিটে সিল করা',
          asset: 'assets/game/art/m6_board65/term_dtr.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'পোলে কেবিলের মুখ খোলা, কিছু নেই',
          asset: 'assets/game/art/m6_board65/term_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'খোলা মুখে আর্দ্রতা ঢোকে, চাপও নিয়ন্ত্রণ হয় না — এন্ড টার্মিনেশন কিট লাগে।',
        ),
        LearnBoardOption(
          id: 'stress',
          labelBn: 'স্ক্রিন যেখানে শেষ, সেখানে কিছু নেই',
          asset: 'assets/game/art/m6_board65/term_stress.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্ক্রিন যেখানে শেষ, সেখানে চাপ জমে ইনসুলেশন পাংচার করতে পারে — স্ট্রেস কন্ট্রোল টিউবিং লাগে।',
        ),
        LearnBoardOption(
          id: 'cracked',
          labelBn: 'ফাটা টার্মিনেশন, ভেতরে জল জমেছে',
          asset: 'assets/game/art/m6_board65/term_cracked.svg',
          scene: true,
          correct: false,
          rejectBn: 'টার্মিনেশন আর জয়েন্টেই 90% ফল্ট হয় — আর্দ্রতা ঢুকলে সব নষ্ট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টার্মিনেশন কিট মুখটা আর্দ্রতা থেকে বাঁচায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'স্ট্রেস কন্ট্রোল টিউবিং চাপ মসৃণভাবে ছড়ায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ইউজির 90% ফল্ট টার্মিনেশন আর জয়েন্টে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'খোলা মুখে বাতাস লাগলে কেবিল ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'স্ক্রিনের শেষ প্রান্তে কোনো চাপ জমে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'টার্মিনেশন একটু ফাটলেও কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফল্ট বেশি হয় কেবিলের মাঝখানে, মুখে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পোলের ওপরে কেবিলের মুখে জল ঢোকে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সিল না করলেও কেবিল নিজেই জল আটকায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'lay',
      promptBn: 'নতুন কেবিল পাতা হচ্ছে — কোন কাজটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'bend',
          labelBn: 'ট্রেঞ্চের কোণে চওড়া, আলতো বাঁক',
          asset: 'assets/game/art/m6_board65/lay_bend.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bond',
          labelBn: 'দুই প্রান্তেই আর্মার আর্থে বাঁধা',
          asset: 'assets/game/art/m6_board65/lay_bond.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'print',
          labelBn: 'জ্যাকেটের লেখা ডকেটের সাথে মেলানো',
          asset: 'assets/game/art/m6_board65/lay_print.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'kink',
          labelBn: 'ট্রেঞ্চের কোণে কেবিলে তীক্ষ্ণ ভাঁজ',
          asset: 'assets/game/art/m6_board65/lay_kink.svg',
          scene: true,
          correct: false,
          rejectBn: 'ন্যূনতম বেন্ডিং রেডিয়াসের চেয়ে বেশি বাঁকালে ভেতরের ইনসুলেশন বা স্ক্রিন ক্ষতিগ্রস্ত হতে পারে।',
        ),
        LearnBoardOption(
          id: 'riser',
          labelBn: 'পোলের গোড়ায় কেবিলে তীক্ষ্ণ বাঁক',
          asset: 'assets/game/art/m6_board65/lay_riser.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলের গোড়ায় তীক্ষ্ণ বাঁক — ভেতরের ইনসুলেশন বা স্ক্রিন ক্ষতিগ্রস্ত হতে পারে।',
        ),
        LearnBoardOption(
          id: 'oneend',
          labelBn: 'আর্মার শুধু এক প্রান্তে আর্থ করা',
          asset: 'assets/game/art/m6_board65/lay_oneend.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্মার আর্থিং দুই প্রান্তেই — ফল্ট কারেন্টের নিরাপদ পথ চাই।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বেন্ডিং রেডিয়াস না মানলে ভেতর নষ্ট হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আর্মার দুই প্রান্তেই আর্থ করতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জ্যাকেটের লেখায় ভোল্টেজ, সাইজ, প্রকার থাকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আর্থ করা আর্মার ফল্ট কারেন্টের নিরাপদ পথ', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'কেবিল যত খুশি বাঁকানো যায়, কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আর্মার এক প্রান্তে আর্থ করলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জ্যাকেটের লেখা পড়ার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কোণে চেপে ভাঁজ করলে কেবিলও কম লাগে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নতুন কেবিলে আর্মার আর্থের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'বাইরে ঠিক থাকলে ভেতরের স্ক্রিনও ঠিক', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board65Lines.rivalTaunt,
    rivalLineBn: M6Board65Lines.rivalMyth,
    exitBn: M6Board65Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    // DRAFT wording — owner.
    dangerHints: [
      'খোঁড়ার দাঁতে হাই-ভোল্টেজ',
      'মাটি ফুঁড়ে আগুনের ঝলক',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'মেশিন আর্মার-ইনসুলেশন মুহূর্তে ছিঁড়ে দেয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'আঘাতে বিস্ফোরণ বা আর্ক ফ্ল্যাশ হতে পারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'মেশিনের অপারেটরের জীবন মারাত্মক ঝুঁকিতে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'আর্মার থাকলে মেশিনের আঘাতে কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ইনসুলেশন থাকলে লাইভ কেবিলে ভয় নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মাটির নিচের কেবিলে আর্ক ফ্ল্যাশ হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'মেশিনের ভেতরে অপারেটর পুরো নিরাপদ', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'আঘাত লাগলে কেবিলটা শুধু একটু টোল খায়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'লাইভ কেবিল খুঁড়লে বড়জোর ফিউজ কাটে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py` (ruling M6-12: the
/// owner gives the wording first).
abstract final class M6Board65Lines {
  // DRAFT wording — owner.
  static const rivalTaunt = 'আরে, কেবিল তো মাটির নিচে, আর্মার দেওয়া! এত ভয় কিসের?';

  /// Lesson 6.5's first myth, word for word (shared with the do_6_5_b push).
  static const rivalMyth = 'ইউজি কেবিল তো ইনসুলেটেড এবং আর্মার্ড, তাই এটা লাইভ থাকা অবস্থায় মাটি খোঁড়ার মেশিনের আঘাতে কিছু হবে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Same list under the Module 6 name (ruling M6-12).
  static const newRivalLines = toRecord;
}
