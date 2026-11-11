import 'learn_board_models.dart';

/// Module 4 Lesson 4.8 (গাছের ডালপালা ছাঁটা — Tree Trimming), the picture
/// board (rung `4.8/learn`, pack `learn_4_8`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board48_art.py`. Every round
/// and every trap comes from the lesson text or its film script:
///  * why: a storm-broken branch on the line (short / snapped wire); rubbing
///    wears even a service / AB cable's insulation; wet leaves on two live
///    wires short them; a dry branch on a live wire can catch fire; regular
///    trimming cuts breakdowns;
///  * plan: a branch very close to the line -> PTW and shutdown first; the
///    area below roped / taped off; never alone — a coworker below controls
///    the traffic (the earth leads drawn on the dead line are the house rule
///    "test and earth"; not put into words);
///  * tool: a long insulated fibreglass pruner / saw near the line; a chainsaw
///    for big branches, both hands, mind the kickback; strong gloves and
///    goggles besides the standard PPE;
///  * cut: the 3-cut method — an undercut first (no torn bark), the branch
///    down, the finish cut just outside the collar; a rope controls the fall;
///  * trim: topping is forbidden; directional pruning / side-trim and V-trim;
///    felling only for a dead, rotten or dangerous tree, with the forest
///    department's and local administration's written permission; 1.5–3 m
///    clearance from the conductors.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack48 = LearnBoardPack(
  lessonId: '4.8',
  titleBn: 'গাছের ডালপালা ছাঁটা',
  badgeBn: 'কাজের কারিগর',
  introBn: 'ঝড়ে ভাঙা ডাল, ঘষা খাওয়া তার — গাছ লাইনের নীরব শত্রু। ডাল ছাঁটুন নিয়ম মেনে।',
  earnedBn: 'শাটডাউন, ঘেরা, সহকর্মী — তারপর থ্রি-কাট। টপিং নয়, তার থেকে 1.5–3 মিটার ফাঁকা।',
  slots: [
    LearnBoardSlot(
      id: 'why',
      promptBn: 'ঝড়ের আগে লাইন টহল — কোন লাইনটা নিরাপদ অবস্থায় আছে?',
      options: [
        LearnBoardOption(
          id: 'clear',
          labelBn: 'ডাল ছেঁটে তার থেকে ফাঁকা রাখা লাইন',
          asset: 'assets/game/art/m4_board48/why_clear.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clear_ab',
          labelBn: 'ডাল ছেঁটে ফাঁকা রাখা এবি কেবিল',
          asset: 'assets/game/art/m4_board48/why_clear_ab.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rub',
          labelBn: 'এবি কেবিলে ডাল ঘষা খাচ্ছে',
          asset: 'assets/game/art/m4_board48/why_rub.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্রমাগত ঘষায় এবি কেবিলের ইনসুলেশনও নষ্ট হয় — ইনসুলেটেড বলে ডাল ছুঁয়ে থাকতে দেওয়া যায় না।',
        ),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'ভেজা ডালপালা দুটো তার ছুঁয়ে আছে',
          asset: 'assets/game/art/m4_board48/why_wet.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা ডাল বা পাতা দুটি লাইভ তারকে ছুঁলে শর্ট সার্কিট হতে পারে।',
        ),
        LearnBoardOption(
          id: 'storm',
          labelBn: 'ঝড়ে ভাঙা ডাল তারের ওপর',
          asset: 'assets/game/art/m4_board48/why_storm.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঝড়ে ডাল ভেঙে লাইনে পড়লে শর্ট সার্কিট হয় বা তার ছিঁড়ে যায় — আগেই ছাঁটলে ফল্ট আটকায়।',
        ),
        LearnBoardOption(
          id: 'dry',
          labelBn: 'শুকনো ডাল লাইভ তারে ঠেকে আছে',
          asset: 'assets/game/art/m4_board48/why_dry.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুকনো ডাল লাইভ তারের সংস্পর্শে এলে স্পার্কিংয়ে আগুন লেগে যেতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিয়মিত ছাঁটাই লাইনের ব্রেকডাউন অনেক কমায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভেজা ডাল দুটি তার ছুঁলে শর্ট সার্কিট হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শুকনো ডাল লাইভ তারে লাগলে আগুন লাগে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ইনসুলেটেড এবি কেবিলে ডাল ঘষলে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঝড়ে ভাঙা ডাল তারে পড়লে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভেজা পাতা কখনো বিদ্যুৎ বইতে পারে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ডাল একটু তার ছুঁলে ফল্টের ভয় নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লাইনের নিচে জঙ্গল থাকলে কাজে বাধা নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্রেকডাউন হলে তবেই ডাল ছাঁটা দরকার', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'plan',
      promptBn: 'ডাল লাইনের খুব কাছে — কাটা শুরুর আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'ptw',
          labelBn: 'শাটডাউন, PTW আর আর্থ দিয়ে কাটা',
          asset: 'assets/game/art/m4_board48/plan_ptw.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'traffic',
          labelBn: 'ঘেরা দিয়ে, সহকর্মী ট্র্যাফিক সামলাচ্ছেন',
          asset: 'assets/game/art/m4_board48/plan_traffic.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'লাইন চালু রেখেই ডাল কাটা',
          asset: 'assets/game/art/m4_board48/plan_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল লাইনের খুব কাছে হলে কাজের আগে PTW নিয়ে লাইন বন্ধ করতেই হবে — শাটডাউন ছাড়া নয়।',
        ),
        LearnBoardOption(
          id: 'nocordon',
          labelBn: 'নিচে ঘেরা না দিয়েই ডাল ফেলা',
          asset: 'assets/game/art/m4_board48/plan_nocordon.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিচে দড়ি বা টেপ দিয়ে এলাকা ঘিরুন — কাটা ডাল যেন পথচারী বা গাড়ির ওপর না পড়ে।',
        ),
        LearnBoardOption(
          id: 'alone',
          labelBn: 'রাস্তার ধারে একা একা কাজ',
          asset: 'assets/game/art/m4_board48/plan_alone.svg',
          scene: true,
          correct: false,
          rejectBn: 'ট্রি ট্রিমিং কখনো একা নয় — নিচের সহকর্মী ট্র্যাফিক সামলান আর বিপদে সতর্ক করেন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ডাল কাটার আগে PTW নিয়ে লাইনের শাটডাউন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দড়ি বা টেপে কাজের এলাকা ঘিরে রাখা চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিচে সহকর্মী থাকবেন ট্র্যাফিক সামলাতে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ডাল কাটতে লাইন বন্ধের কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রাস্তায় লোক কম থাকলে ঘেরার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অভিজ্ঞ লাইনম্যান একাই গাছ ছাঁটতে পারেন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাটা ডাল নিজেই পথচারীর পাশ কাটিয়ে পড়ে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'PTW শুধু খুঁটিতে চড়ার কাজের জন্যই লাগে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'গাড়ি এলে ডালের নিচ দিয়েই চলে যাবে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'tool',
      promptBn: 'লাইনের পাশের গাছে ডাল কাটবেন — কোনটা ঠিক যন্ত্র ও সুরক্ষা?',
      options: [
        LearnBoardOption(
          id: 'pruner',
          labelBn: 'ইনসুলেটেড লম্বা প্রুনারে ছোট ডাল',
          asset: 'assets/game/art/m4_board48/tool_pruner.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'chainsaw',
          labelBn: 'দুই হাতে চেইনসঅ, মোটা ডালে',
          asset: 'assets/game/art/m4_board48/tool_chainsaw.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'onehand',
          labelBn: 'এক হাতে চেইনসঅ চালানো',
          asset: 'assets/game/art/m4_board48/tool_onehand.svg',
          scene: true,
          correct: false,
          rejectBn: 'চেইনসঅ সবসময় দুই হাতে শক্ত করে ধরুন, বিপজ্জনক কিকব্যাক সম্পর্কে সজাগ থাকুন।',
        ),
        LearnBoardOption(
          id: 'metal',
          labelBn: 'লোহার হাতলের করাত তারের কাছে',
          asset: 'assets/game/art/m4_board48/tool_metal.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইনের কাছে ফাইবারগ্লাস হাতলের ইনসুলেটেড প্রুনার বা করাত — এটা বাড়তি সুরক্ষা দেয়।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'গগলস, গ্লাভস ছাড়াই চেইনসঅ',
          asset: 'assets/game/art/m4_board48/tool_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্ট্যান্ডার্ড PPE-র সঙ্গে শক্ত গ্লাভস আর চোখ বাঁচাতে গগলস — এই কাজে অপরিহার্য।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইনের কাছে ফাইবারগ্লাসের ইনসুলেটেড টুল', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চেইনসঅ দুই হাতে ধরে কিকব্যাকে সজাগ থাকা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শক্ত গ্লাভস আর গগলস এই কাজে অপরিহার্য', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লোহার হাতলের করাতেই লাইনের কাছে কাজ চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হাত খালি রাখতে চেইনসঅ এক হাতে ধরা ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কাঠের গুঁড়ো চোখে গেলে ক্ষতি নেই, গগলস বাদ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চেইনসঅ চালাতে আলাদা প্রশিক্ষণ লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মোটা ডাল কাটতেও ছোট হাত-করাতই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'গ্লাভস পরলে করাত ধরা যায় না ঠিকমতো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'cut',
      promptBn: 'মোটা, ভারী ডাল নামাবেন — কাটার কোন কৌশলটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'under',
          labelBn: 'প্রথমে ডালের নিচে ছোট কাট',
          asset: 'assets/game/art/m4_board48/cut_under.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rope',
          labelBn: 'দড়ি বেঁধে পতনের দিক ঠিক রাখা',
          asset: 'assets/game/art/m4_board48/cut_rope.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'collar',
          labelBn: 'শেষে কলারের ঠিক বাইরে মসৃণ কাট',
          asset: 'assets/game/art/m4_board48/cut_collar.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tear',
          labelBn: 'ওপর থেকে এক কাটেই ডাল ফেলা',
          asset: 'assets/game/art/m4_board48/cut_tear.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে ডালের নিচে ছোট কাট দিন — নইলে ডাল পড়ার সময় ছাল ছিঁড়ে যায়। এটাই থ্রি-কাট পদ্ধতি।',
        ),
        LearnBoardOption(
          id: 'fall',
          labelBn: 'দড়ি ছাড়াই ডাল ছেড়ে দেওয়া',
          asset: 'assets/game/art/m4_board48/cut_fall.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাল কোন দিকে পড়বে আগে ঠিক করুন — দরকারে দড়ি বেঁধে পতন নিয়ন্ত্রণ করুন।',
        ),
        LearnBoardOption(
          id: 'flush',
          labelBn: 'কান্ড ঘেঁষে কলারসহ কেটে ফেলা',
          asset: 'assets/game/art/m4_board48/cut_flush.svg',
          scene: true,
          correct: false,
          rejectBn: 'শেষ কাট কলারের ঠিক বাইরে, মসৃণ করে — ভুলভাবে কাটলে গাছে ইনফেকশন হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিচের ছোট কাট ডালের ছাল ছেঁড়া আটকায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দড়িতে বেঁধে ডালের পতন নিয়ন্ত্রণ করা যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফিনিশ কাট কলারের ঠিক বাইরে, মসৃণ করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'এক কাটে ডাল ফেলাই সবচেয়ে দ্রুত ও নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ডাল যেদিকে খুশি পড়ুক, পরে সরানো যাবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কান্ড ঘেঁষে কাটলে গাছ বেশি ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছাল একটু ছিঁড়লে গাছের কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ভেতরের মোটা ডাল থেকেই কাটা শুরু করুন', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'থ্রি-কাট শুধু বইয়ে থাকে, মাঠে লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'trim',
      promptBn: 'লাইন গাছের ওপর বা পাশ দিয়ে গেছে — কোন ছাঁটাই ঠিক?',
      options: [
        LearnBoardOption(
          id: 'v',
          labelBn: 'মাঝখান ফাঁকা করে ভি-ট্রিমিং',
          asset: 'assets/game/art/m4_board48/trim_v.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'side',
          labelBn: 'লাইনমুখী ডাল ছেঁটে পাশ ফাঁকা',
          asset: 'assets/game/art/m4_board48/trim_side.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'top',
          labelBn: 'গাছের মাথা গোল করে কাটা',
          asset: 'assets/game/art/m4_board48/trim_top.svg',
          scene: true,
          correct: false,
          rejectBn: 'টপিং বা মাথা গোল করে কাটা পুরোপুরি নিষিদ্ধ — শুধু লাইনের দিকে বাড়া ডাল ছাঁটুন।',
        ),
        LearnBoardOption(
          id: 'fell',
          labelBn: 'সুস্থ গাছ গোড়া থেকে কেটে ফেলা',
          asset: 'assets/game/art/m4_board48/trim_fell.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফেলিং শুধু মৃত, পচা বা ভেঙে পড়ার মুখে থাকা গাছে — তাও বন দপ্তর ও প্রশাসনের লিখিত অনুমতিতে।',
        ),
        LearnBoardOption(
          id: 'close',
          labelBn: 'একটা ডাল তারের কাছেই রেখে দেওয়া',
          asset: 'assets/game/art/m4_board48/trim_close.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ডাক্টর থেকে ডালের নিরাপদ দূরত্ব 1.5 থেকে 3 মিটার রাখতেই হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইনের দিকে বাড়া ডালই শুধু ছাঁটা হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নতুন ডাল যেন লাইনের উল্টোদিকে বাড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তার থেকে ডাল 1.5 থেকে 3 মিটার দূরে থাকবে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মাথা গোল করে কাটলে গাছ বেশি দিন ঠিক থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঝামেলা এড়াতে পুরো গাছটাই কেটে ফেলা ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গাছ কাটতে কারও অনুমতির দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তার না ছুঁলেই ডাল যত কাছে খুশি থাকুক', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লাইন ওপরে থাকলে গাছের মাথাটাই কেটে দিন', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যেকোনো দিকের সব ডাল সমান করে ছাঁটুন', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board48Lines.rivalTaunt,
    rivalLineBn: M4Board48Lines.rivalMyth,
    exitBn: M4Board48Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'শুকনো ডাল লাইভ তারে',
      'স্পার্কিং থেকে আগুন',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'শুকনো ডাল অত্যন্ত দাহ্য, সহজেই আগুন লাগে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'লাইভ তারে স্পার্কিং হলে ডালে আগুন ধরে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সেই আগুন থেকে দাবানলও ছড়াতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'বিদ্যুৎ না বইলে শুকনো ডালে কোনো বিপদ নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'শুকনো ডাল লাইভ তারে থাকলেও কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'শুধু কাঁচা সবুজ ডালই লাইনের জন্য বিপদ', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'স্পার্কিং হলেও শুকনো ডালে আগুন ধরে না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'শুকনো ডাল নিজে থেকেই একদিন পড়ে যাবে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ভালো ইনসুলেটর মানেই পুরোপুরি নিরাপদ', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board48Lines {
  static const rivalTaunt = 'আরে, শুকনো ডাল নিয়ে এত মাথাব্যথা কেন? ছেড়ে দাও!';

  /// Lesson 4.8's first myth buster, word for word.
  static const rivalMyth = 'শুকনো ডাল তো বিদ্যুৎ পরিবহন করে না, তাই ওটা লাইভ তারের সংস্পর্শে থাকলেও চলে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
