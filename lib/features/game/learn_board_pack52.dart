import 'learn_board_models.dart';

/// Module 5 Lesson 5.2 (লাইন পেট্রোলিং-এর সঠিক নিয়ম), the picture board
/// (rung `5.2/learn`, pack `learn_5_2`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board52_art.py`. Every round
/// and every trap comes from the lesson text (section points, pro tips, the
/// two myth busters):
///  * start: patrol from the source (substation) toward the load; a long line
///    is split between two teams from both ends who keep in touch; T-off
///    points are looked at first; the feeder map is carried (pro tip 4). The
///    hand radio on the card is art only — the lesson says "যোগাযোগ বজায়
///    রাখুন";
///  * eyes: binoculars show fine damage high up without climbing (pro tip 1);
///    look down too (vehicle marks, pole base, anchor); stop, look, then walk
///    (looking up while walking = a stumble or a pothole);
///  * senses: listen (hiss or hum) and smell (burnt insulation or oil); a fault
///    can leave no mark at all — a dirty insulator, a small bird or lizard
///    (myth buster 2);
///  * wire: a wire on the ground is taken as live and avoided with all one's
///    might; at least 10 m (about 33 ft) kept round it and the area cordoned
///    (ruling M5-4: round the wire and the fence / tree / vehicle it touches);
///    on dry soil or tar a live wire may not spark (myth buster 1);
///  * exit: the ground near it may carry voltage — leave with both feet
///    together in small steps, or hopping (ruling M5-4).
/// The rival's myth is the lesson's first myth buster, word for word.
///
/// Deadly / slip (docs/module_specs/module5_items/board_52.json, rulings
/// M5-3, M5-4): on this board every trap costs the same; the Do levels grade
/// them (climbing to look R19/R1, a long stride out of the zone R15, entering
/// 10 m R13, touching the wire R14 = deadly; a cordon under 10 m R16 = slip).
const learnBoardPack52 = LearnBoardPack(
  lessonId: '5.2',
  titleBn: 'লাইন পেট্রোলিং-এর সঠিক নিয়ম',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'পেট্রোলিং মানে শুধু লাইন ধরে হাঁটা নয় — চোখ, কান আর নাক দিয়ে সূত্র খোঁজা। গোয়েন্দার মতো খুঁজুন, নিরাপদে।',
  earnedBn: 'সোর্স থেকে লোডে, থেমে দেখা-শোনা-গন্ধ নেওয়া; পড়ে থাকা তার লাইভ — 10 মিটার দূরে, পা জোড়া রেখে বেরোনো।',
  slots: [
    LearnBoardSlot(
      id: 'start',
      promptBn: 'লম্বা ফিডার ট্রিপ করেছে — পেট্রোলিং কীভাবে শুরু করবেন?',
      options: [
        LearnBoardOption(
          id: 'source',
          labelBn: 'সাবস্টেশন থেকে লোডের দিকে হাঁটা',
          asset: 'assets/game/art/m5_board52/start_source.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'split',
          labelBn: 'দুই দল দুই মাথা থেকে, যোগাযোগ রেখে',
          asset: 'assets/game/art/m5_board52/start_split.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'middle',
          labelBn: 'ফিডারের মাঝখান থেকে শুরু করা',
          asset: 'assets/game/art/m5_board52/start_middle.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাঝখান থেকে শুরু করলে অংশ বাদ পড়ে — সোর্স থেকে লোডের দিকে চলুন।',
        ),
        LearnBoardOption(
          id: 'skiptee',
          labelBn: 'টি-অফ পয়েন্ট পেরিয়ে সোজা চলে যাওয়া',
          asset: 'assets/game/art/m5_board52/start_skiptee.svg',
          scene: true,
          correct: false,
          rejectBn: 'টি-অফ পয়েন্টে ফল্টের সম্ভাবনা বেশি — আগে ওখানেই দেখুন।',
        ),
        LearnBoardOption(
          id: 'nocontact',
          labelBn: 'দুই দল দুই মাথায়, কোনো যোগাযোগ নেই',
          asset: 'assets/game/art/m5_board52/start_nocontact.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন ভাগ করে দুই দিক থেকে চললে যোগাযোগ বজায় রাখুন।',
        ),
        LearnBoardOption(
          id: 'nomap',
          labelBn: 'ম্যাপ ছাড়া মোড়ে এসে দিশেহারা',
          asset: 'assets/game/art/m5_board52/start_nomap.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিডারের ম্যাপ সাথে রাখুন — রুট আর টি-অফ পয়েন্ট সহজে মেলে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সোর্স থেকে লোডে চললে কোনো অংশ বাদ পড়ে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টি-অফ পয়েন্টে ফল্টের সম্ভাবনা বেশি থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভাগ করে খুঁজলেও দুই দলে যোগাযোগ রাখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মাঝখান থেকে শুরু করলেই ফল্ট আগে মেলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টি-অফ শাখায় সাধারণত কোনো ফল্ট হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দুই দল আলাদা চললে কথা বলার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অভিজ্ঞ লোকের ফিডারের ম্যাপ লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যেখান থেকে খুশি শুরু করলেও একই কথা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লম্বা লাইনও একজনেই পুরোটা হেঁটে নেবে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'eyes',
      promptBn: 'সামনের পোলে ক্ষতি থাকতে পারে — কীভাবে দেখবেন?',
      options: [
        LearnBoardOption(
          id: 'bino',
          labelBn: 'থেমে বাইনোকুলারে পোলের মাথা দেখা',
          asset: 'assets/game/art/m5_board52/eyes_bino.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'base',
          labelBn: 'থেমে পোলের গোড়া আর অ্যাঙ্কর দেখা',
          asset: 'assets/game/art/m5_board52/eyes_base.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'ইনসুলেটর দেখতে পোলে উঠে পড়া',
          asset: 'assets/game/art/m5_board52/eyes_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'দেখার জন্য পোলে ওঠা নয় — বাইনোকুলারে পোলে না চড়েই ওপরের সূক্ষ্ম ফাটল দেখা যায়।',
        ),
        LearnBoardOption(
          id: 'walkup',
          labelBn: 'বাইনোকুলার চোখে রেখেই হেঁটে চলা',
          asset: 'assets/game/art/m5_board52/eyes_walkup.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওপরে তাকিয়ে হাঁটলে হোঁচট বা গর্তে পড়া — থামুন, দেখুন, তারপর হাঁটুন।',
        ),
        LearnBoardOption(
          id: 'onlyup',
          labelBn: 'শুধু ওপরে দেখা, ভাঙা গোড়া চোখে পড়েনি',
          asset: 'assets/game/art/m5_board52/eyes_onlyup.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিচেও দেখুন — গাড়ির ধাক্কার চিহ্ন, পোলের গোড়া বা অ্যাঙ্করের ক্ষতি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বাইনোকুলারে পোলে না চড়েই ফাটল দেখা যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নিচে পোলের গোড়া আর অ্যাঙ্করও দেখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হাঁটার সময় থামুন, দেখুন, তারপর হাঁটুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পোলে উঠে কাছ থেকে দেখাই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হাঁটতে হাঁটতে ওপরে তাকালে সময় বাঁচে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ক্ষতি সবসময় ওপরেই থাকে, নিচে থাকে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বাইনোকুলার শুধু রাতের টহলেই কাজে লাগে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গাড়ির ধাক্কায় পোলের গোড়ার কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'টহলে পায়ের দিকে তাকানোর দরকার পড়ে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'senses',
      promptBn: 'চোখে কিছু ভাঙা দেখা যাচ্ছে না — আর কীভাবে খুঁজবেন?',
      options: [
        LearnBoardOption(
          id: 'ear',
          labelBn: 'থেমে কান পেতে অস্বাভাবিক শব্দ শোনা',
          asset: 'assets/game/art/m5_board52/senses_ear.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nose',
          labelBn: 'থেমে পোড়া গন্ধের উৎস খোঁজা',
          asset: 'assets/game/art/m5_board52/senses_nose.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'earphone',
          labelBn: 'কানে গান গুঁজে টহল দেওয়া',
          asset: 'assets/game/art/m5_board52/senses_earphone.svg',
          scene: true,
          correct: false,
          rejectBn: 'সব ইন্দ্রিয় সজাগ রাখুন — হিসহিস্ বা ভনভন শব্দই সূত্র।',
        ),
        LearnBoardOption(
          id: 'shrug',
          labelBn: 'কিছু ভাঙা নেই, তাই চলে যাওয়া',
          asset: 'assets/game/art/m5_board52/senses_shrug.svg',
          scene: true,
          correct: false,
          rejectBn: 'ময়লা জমা ইনসুলেটর বা ছোট পাখি-গিরগিটিও চিহ্ন ছাড়া ফল্ট ঘটায়।',
        ),
        LearnBoardOption(
          id: 'holdnose',
          labelBn: 'নাক চেপে গন্ধ পেরিয়ে যাওয়া',
          asset: 'assets/game/art/m5_board52/senses_holdnose.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোড়া ইনসুলেশন বা তেলের গন্ধই ফল্টের দিকে নিয়ে যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'হিসহিস্ বা ভনভন শব্দ ফল্টের সূত্র দেয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পোড়া ইনসুলেশন বা তেলের গন্ধও সূত্র', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চিহ্ন ছাড়াও ময়লা বা পাখিতে ফল্ট হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফল্ট মানেই কিছু ছেঁড়া বা ভাঙা থাকবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গান শুনতে শুনতে টহলে মন ভালো থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গন্ধ শুঁকে ফল্ট খোঁজা শুধু সময়ের অপচয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লাইনের শব্দ শুনে ফল্ট বোঝা যায় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কিছু চোখে না পড়লে পরের পোলে যান', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পোড়া গন্ধের সাথে লাইনের সম্পর্ক নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'wire',
      promptBn: 'মাটিতে একটা তার পড়ে আছে, স্পার্ক নেই — কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'cordon',
          labelBn: '10 মিটার দূর দিয়ে দড়িতে ঘেরা',
          asset: 'assets/game/art/m5_board52/wire_cordon.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'stop',
          labelBn: 'লাইভ ধরে নিয়ে দূরেই থেমে যাওয়া',
          asset: 'assets/game/art/m5_board52/wire_stop.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'stick',
          labelBn: 'লাঠি দিয়ে তারটা তুলে সরানো',
          asset: 'assets/game/art/m5_board52/wire_stick.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্পার্ক না করলেও তার লাইভ থাকতে পারে — ছোঁয়া মানেই মৃত্যু।',
        ),
        LearnBoardOption(
          id: 'close',
          labelBn: 'শুকনো পিচে ঝুঁকে তারটা দেখা',
          asset: 'assets/game/art/m5_board52/wire_close.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুকনো মাটি বা পিচে লাইভ তারও স্পার্ক না-ও করতে পারে — দূরে থাকুন।',
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'তারের দুই পা দূরে দড়ি টানা',
          asset: 'assets/game/art/m5_board52/wire_tight.svg',
          scene: true,
          correct: false,
          rejectBn: 'তার এবং তার ছুঁয়ে থাকা বেড়া/গাছ/গাড়ির চারপাশে কমপক্ষে 10 মিটার দূর দিয়ে ঘিরে দিন।',
        ),
        LearnBoardOption(
          id: 'stepover',
          labelBn: 'তারের ওপর দিয়ে পা ফেলে পার হওয়া',
          asset: 'assets/game/art/m5_board52/wire_stepover.svg',
          scene: true,
          correct: false,
          rejectBn: 'পড়ে থাকা তার সর্বশক্তি দিয়ে এড়িয়ে চলুন — ধরে নিন এটি লাইভ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মাটিতে পড়া তার সবসময় লাইভ ধরে নিতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'চারপাশে কমপক্ষে 10 মিটার দূরত্ব রাখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শুকনো পিচে লাইভ তারও স্পার্ক না-ও করতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'স্পার্ক না করলে তারটা ডেড ধরে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শুকনো কাঠের লাঠিতে তার ছুঁলে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দুই পা দূরে দড়ি দিলেই এলাকা নিরাপদ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তার ডিঙিয়ে গেলে ছোঁয়া লাগে না, ভয় নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পিচের রাস্তায় পড়ে থাকা তারে কারেন্ট থাকে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কাছে গিয়ে ভালো করে দেখে তারপর ঘেরা', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'exit',
      promptBn: 'পড়ে থাকা তারের কাছেই দাঁড়িয়ে আছেন — কীভাবে বেরোবেন?',
      options: [
        LearnBoardOption(
          id: 'shuffle',
          labelBn: 'দুই পা একসাথে, ছোট ছোট পদক্ষেপ',
          asset: 'assets/game/art/m5_board52/exit_shuffle.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hop',
          labelBn: 'দুই পা জোড়া করে লাফিয়ে বেরোনো',
          asset: 'assets/game/art/m5_board52/exit_hop.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'stride',
          labelBn: 'লম্বা লম্বা পা ফেলে দৌড়ানো',
          asset: 'assets/game/art/m5_board52/exit_stride.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটিতেও ভোল্টেজ থাকতে পারে — দুই পা একসাথে রেখে ছোট পদক্ষেপে বা লাফিয়ে বেরোন।',
        ),
        LearnBoardOption(
          id: 'wide',
          labelBn: 'দুই পা ফাঁক করে দাঁড়িয়ে থাকা',
          asset: 'assets/game/art/m5_board52/exit_wide.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুই পা ফাঁক নয় — পা একসাথে রেখে ছোট ছোট পদক্ষেপে এলাকা থেকে বেরোন।',
        ),
        LearnBoardOption(
          id: 'toward',
          labelBn: 'তারের দিকেই হেঁটে যাওয়া',
          asset: 'assets/game/art/m5_board52/exit_toward.svg',
          scene: true,
          correct: false,
          rejectBn: 'তারের দিকে নয় — উল্টো দিকে, 10 মিটারের বাইরে বেরিয়ে আসুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তারের কাছে মাটিতেও ভোল্টেজ থাকতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দুই পা একসাথে রেখে ছোট পদক্ষেপে বেরোন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জোড়া পায়ে লাফিয়েও এলাকা ছাড়া যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যত বড় পা ফেলবেন, তত দ্রুত নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'তার ছুঁয়ে না থাকলে মাটিতে ভোল্টেজ নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দুই পা ফাঁক রাখলে শরীর টাল সামলায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দৌড়ে বেরোলেই মাটির ভোল্টেজ এড়ানো যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তারের পাশ ঘেঁষে হাঁটাই সবচেয়ে নিরাপদ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'জুতো পরা থাকলে যেভাবে খুশি হাঁটা যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board52Lines.rivalTaunt,
    rivalLineBn: M5Board52Lines.rivalMyth,
    exitBn: M5Board52Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'শুকনো পিচে লাইভ তার',
      'ছোঁয়া মানেই মৃত্যু',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'শুকনো মাটিতে লাইভ তারও স্পার্ক না-ও করতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'পড়ে থাকা তার সবসময় লাইভ ধরে নিতে হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'এমন তার স্পর্শ করা মানেই নিশ্চিত মৃত্যু', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'স্পার্ক নেই মানে তারে কোনো কারেন্ট নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'চুপচাপ পড়ে থাকা তার ছুঁলেও বিপদ নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ট্রিপ করা লাইনের পড়া তার তো ডেডই থাকে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'শুকনো পিচে পড়লে তার নিজে থেকেই ডেড হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ধোঁয়া বা শব্দ না থাকলে পড়ে থাকা তার নিরাপদ', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'কাছে গিয়ে দেখলেই বোঝা যায় তার ডেড কিনা', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py`.
abstract final class M5Board52Lines {
  static const rivalTaunt = 'আরে, এত ঘোরাঘুরি কেন? তারটা তো চুপচাপ পড়ে আছে!';

  /// Lesson 5.2's first myth buster, word for word.
  static const rivalMyth = 'মাটিতে পড়ে থাকা তারটি স্পার্ক করছে না, তার মানে ওটা ডেড।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
