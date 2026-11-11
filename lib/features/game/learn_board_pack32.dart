import 'learn_board_models.dart';

/// Module 3 Lesson 3.2 (ইনসুলেটর পরিচিতি: পিন, ডিস্ক, শ্যাকল), the picture
/// board (rung `3.2/learn`, pack `learn_3_2`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board32_art.py`. Every round
/// and every trap comes from the lesson text and its checked film script:
///  * look: before going up, check the insulators from below — binoculars or
///    the naked eye — for a break or black marks; a broken insulator is a
///    death trap; without a sound insulator the current comes down the pole,
///    and whoever touches that pole is finished;
///  * pin: on a straight line (up to 33 kV) the pin insulator; the conductor
///    sits in the groove on its head; a loose binding sparks and the
///    insulator cracks; the petticoat (shed) keeps rain off the pin; a broken
///    edge gathers water and dust and starts a leak; wet bird droppings act
///    like a wire;
///  * end: at a dead end or a turn a pin insulator will break — a shackle
///    (reel) on a D-iron / clamp takes the pull (mostly LT); a shackle worn
///    sharp can cut the conductor's insulation or the wire;
///  * disc: discs hang as a string at tension or suspension points; one disc
///    = 11 kV, three = 33 kV, a long string = 132 kV (the lesson says 6 or
///    more, the film 8–10 — the card draws 8 and no count is put into words);
///    a hairline crack is never ignored — at high voltage it blasts;
///  * clean: by factories or the sea a salt layer forms, and in fog or rain it
///    leaks and flashes over — routine insulator washing; bird droppings or a
///    nest are cleaned off or the line trips on a rainy day; polymer
///    insulators are light, hard to break and do better in dirty places.
///    The cleaning card draws the line earthed (house rule: work only after
///    shutdown, PTW, test and earth — the lesson does not say it).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack32 = LearnBoardPack(
  lessonId: '3.2',
  titleBn: 'ইনসুলেটর পরিচিতি: পিন, ডিস্ক, শ্যাকল',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'ইনসুলেটর লাইনের বডিগার্ড — কারেন্টকে তারে ধরে রাখে। চিনুন, যত্ন নিন।',
  earnedBn: 'ইনসুলেটর ভালো তো লাইন ভালো — সোজায় পিন, মোড়ে শ্যাকল, হাই-ভোল্টেজে ডিস্কের মালা।',
  slots: [
    LearnBoardSlot(
      id: 'look',
      promptBn: 'কাজে ওঠার আগে পোলের নিচে দাঁড়িয়ে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'binoc',
          labelBn: 'বাইনোকুলারে ইনসুলেটর দেখে নেওয়া',
          asset: 'assets/game/art/m3_board32/look_binoc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'eye',
          labelBn: 'নিচ থেকে চোখে ভাঙা-দাগ খোঁজা',
          asset: 'assets/game/art/m3_board32/look_eye.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'broken',
          labelBn: 'ভাঙা ইনসুলেটরের পোলেই ওঠা',
          asset: 'assets/game/art/m3_board32/look_broken.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা ইনসুলেটর মানেই সাক্ষাৎ মৃত্যুফাঁদ — ওঠার আগে নিচ থেকে দেখে নিন।',
        ),
        LearnBoardOption(
          id: 'black',
          labelBn: 'কালচে দাগ উপেক্ষা করে ওঠা',
          asset: 'assets/game/art/m3_board32/look_black.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিচ থেকে দেখতে হয় — ইনসুলেটর ভাঙা কি না, কালচে দাগ আছে কি না। দাগ দেখে উপেক্ষা নয়।',
        ),
        LearnBoardOption(
          id: 'lean',
          labelBn: 'ভাঙা ইনসুলেটরের পোলে হেলান',
          asset: 'assets/game/art/m3_board32/look_lean.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেটর ফেইল করলে কারেন্ট পোল হয়ে মাটিতে নামে — যে পোলে হাত দেয়, সে ওখানেই শেষ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ওঠার আগে নিচ থেকে ইনসুলেটর দেখে নিতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভাঙা ইনসুলেটর মানেই সাক্ষাৎ মৃত্যুফাঁদ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ইনসুলেটর ফেইল করলে পোলটাই লাইভ হয়ে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ওপরে উঠে কাছ থেকে দেখাই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কালচে দাগ শুধু ময়লা, ওতে ভয়ের কিছু নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভাঙা ইনসুলেটরেও কারেন্ট তারেই থেকে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পোলের গায়ে কখনো কারেন্ট আসতেই পারে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাইনোকুলার শুধু বড় অফিসারদের কাজের জিনিস', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রোজকার লাইনে আগে দেখার দরকার পড়ে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pin',
      promptBn: 'সোজা চলা লাইনের পিন ইনসুলেটর — কোনটা ঠিক অবস্থা?',
      options: [
        LearnBoardOption(
          id: 'tight',
          labelBn: 'মাথার খাঁজে তার, বাইন্ডিং টাইট',
          asset: 'assets/game/art/m3_board32/pin_tight.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rain',
          labelBn: 'বৃষ্টির জল পেটিকোট বেয়ে পড়ছে',
          asset: 'assets/game/art/m3_board32/pin_rain.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'বাইন্ডিং তার আলগা হয়ে আছে',
          asset: 'assets/game/art/m3_board32/pin_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাইন্ডিং লুজ হলে স্পার্কিং হবে আর ইনসুলেটর ফেটে যাবে — বাইন্ডিং টাইট চাই।',
        ),
        LearnBoardOption(
          id: 'chip',
          labelBn: 'পেটিকোটের কোণা ভাঙা',
          asset: 'assets/game/art/m3_board32/pin_chip.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা খাঁজে জল-ধুলো জমে লিকেজ কারেন্ট শুরু হয় — কোণা ভাঙা ইনসুলেটর বদলাতেই হবে।',
        ),
        LearnBoardOption(
          id: 'bird',
          labelBn: 'গায়ে ভেজা পাখির বিষ্ঠা',
          asset: 'assets/game/art/m3_board32/pin_bird.svg',
          scene: true,
          correct: false,
          rejectBn: 'পাখির বিষ্ঠা ভিজলে তারের মতো কাজ করে — পরিষ্কার না করলে বৃষ্টির দিনে লাইন ট্রিপ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পেটিকোট বৃষ্টির জল সরাসরি পিনে যেতে দেয় না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কন্ডাক্টর বসে ইনসুলেটরের মাথার খাঁজে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লুজ বাইন্ডিংয়ে স্পার্কিং, ইনসুলেটর ফাটে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বাইন্ডিং একটু আলগা থাকলে তার নড়তে পারে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পেটিকোটের খাঁজ শুধু দেখতে সুন্দর করার জন্য', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মোটা চিনামাটির কোণা ভাঙলে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পাখির বিষ্ঠা ভিজলেও কারেন্ট বইতে পারে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ডেড-এন্ডেও পিন ইনসুলেটরই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বৃষ্টির জল পিনে পৌঁছালে লাইন আরও ঠান্ডা থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'end',
      promptBn: 'এলটি লাইন এখানে শেষ হয়েছে বা মোড় নিয়েছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'dead',
          labelBn: 'ডেড-এন্ডে ডি-আয়রনে শ্যাকল',
          asset: 'assets/game/art/m3_board32/end_dead.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'angle',
          labelBn: 'মোড়ের পোলে শ্যাকল ইনসুলেটর',
          asset: 'assets/game/art/m3_board32/end_angle.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pin_dead',
          labelBn: 'ডেড-এন্ডে পিন ইনসুলেটর',
          asset: 'assets/game/art/m3_board32/end_pin_dead.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন যেখানে শেষ, সেখানে টান প্রচুর — পিন ইনসুলেটর চলবে না, ভেঙে যাবে। লাগে শ্যাকল।',
        ),
        LearnBoardOption(
          id: 'pin_turn',
          labelBn: 'মোড়ের পোলে পিন ইনসুলেটর',
          asset: 'assets/game/art/m3_board32/end_pin_turn.svg',
          scene: true,
          correct: false,
          rejectBn: 'মোড়ে পিন ইনসুলেটর টান সইতে না পেরে ভেঙে যাবে — মোড়ের সাথী শ্যাকল।',
        ),
        LearnBoardOption(
          id: 'sharp',
          labelBn: 'ঘষা খেয়ে ধারালো শ্যাকল',
          asset: 'assets/game/art/m3_board32/end_sharp.svg',
          scene: true,
          correct: false,
          rejectBn: 'শ্যাকলের পোর্সেলিন ঘষা খেয়ে ধারালো হলে কন্ডাক্টরের ইনসুলেশন বা তার কেটে দিতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শ্যাকল প্রচুর মেকানিক্যাল টান সইতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ডেড-এন্ড বা মোড়ে পিন ইনসুলেটর ভেঙে যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শ্যাকল ডি-আয়রন বা ক্ল্যাম্পে পোলে লাগে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মোড়ের টান পিন ইনসুলেটর সহজেই সামলায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ধারালো শ্যাকল তারকে আরও শক্ত করে ধরে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শ্যাকল শুধু সোজা লাইনের মাঝখানে বসে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লাইন যেখানে শেষ, সেখানে কোনো টানই পড়ে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ঘষা লাগা শ্যাকলে কন্ডাক্টরের ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যেকোনো ইনসুলেটর যেকোনো পোলে চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'disc',
      promptBn: 'নিচ থেকে দেখে বলুন — 33 কেভি লাইনের ঠিকঠাক ডিস্কের মালা কোনটা?',
      options: [
        LearnBoardOption(
          id: 'sus3',
          labelBn: 'তিনটে ডিস্কের ঝোলানো মালা',
          asset: 'assets/game/art/m3_board32/disc_sus3.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ten3',
          labelBn: 'টেনশন পয়েন্টে তিনটে ডিস্ক',
          asset: 'assets/game/art/m3_board32/disc_ten3.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'একটা মাত্র ডিস্ক',
          asset: 'assets/game/art/m3_board32/disc_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটা ডিস্ক মানে ওটা 11 কেভি লাইন — 33 কেভিতে মালায় থাকে তিনটে ডিস্ক।',
        ),
        LearnBoardOption(
          id: 'many',
          labelBn: 'অনেকগুলো ডিস্কের লম্বা মালা',
          asset: 'assets/game/art/m3_board32/disc_many.svg',
          scene: true,
          correct: false,
          rejectBn: 'এত লম্বা মালা মানে হাই-ভোল্টেজ 132 কেভি লাইন — 33 কেভিতে তিনটে ডিস্ক।',
        ),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'চুলের মতো ফাটল ধরা ডিস্ক',
          asset: 'assets/game/art/m3_board32/disc_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'সরু চুলের মতো ফাটল ইগনোর নয় — হাই ভোল্টেজে ওই ফাটল দিয়েই ব্লাস্ট হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একটা ডিস্ক 11 কেভি, তিনটে ডিস্ক 33 কেভি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভোল্টেজ বাড়লে মালায় ডিস্কের সংখ্যা বাড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হেয়ারলাইন ফাটল দিয়েই হাই ভোল্টেজে ব্লাস্ট', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মালায় ডিস্ক যতই থাকুক, ভোল্টেজ একই থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চুলের মতো সরু ফাটল উপেক্ষা করাই যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটা ডিস্ক নষ্ট হলে গোটা মালাই ফেলতে হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তিনটে ডিস্কের মালা মানেই 132 কেভি লাইন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ওপরে না উঠে ভোল্টেজ বোঝার কোনো উপায় নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ডিস্ক ইনসুলেটর শুধু এলটি লাইনে লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'clean',
      promptBn: 'সাগরপাড়ে বা কারখানার ধারে লাইন — ইনসুলেটরের যত্নে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'wash',
          labelBn: 'শাটডাউন, আর্থ দিয়ে ইনসুলেটর পরিষ্কার',
          asset: 'assets/game/art/m3_board32/clean_wash.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'polymer',
          labelBn: 'নোংরা জায়গায় পলিমার ইনসুলেটর',
          asset: 'assets/game/art/m3_board32/clean_polymer.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'salt',
          labelBn: 'লবণের আস্তরণ নিয়েই কুয়াশায় লাইন',
          asset: 'assets/game/art/m3_board32/clean_salt.svg',
          scene: true,
          correct: false,
          rejectBn: 'কুয়াশা বা বৃষ্টিতে লবণের লেয়ার দিয়েই কারেন্ট লিক করে ফ্ল্যাশওভার — রুটিন ইনসুলেটর ওয়াশিং মাস্ট।',
        ),
        LearnBoardOption(
          id: 'dust',
          labelBn: 'কারখানার ধুলোয় ঢাকা ইনসুলেটর',
          asset: 'assets/game/art/m3_board32/clean_dust.svg',
          scene: true,
          correct: false,
          rejectBn: 'কলকারখানার ধারে ইনসুলেটরের গায়ে আস্তরণ পড়ে — বৃষ্টিতে ফ্ল্যাশওভার হতে পারে। ধোলাই করা মাস্ট।',
        ),
        LearnBoardOption(
          id: 'nest',
          labelBn: 'ইনসুলেটরের ওপর পাখির বাসা',
          asset: 'assets/game/art/m3_board32/clean_nest.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেটরের ওপর পাখির বাসা বা বিষ্ঠা দেখলে পরিষ্কার করুন — নইলে বৃষ্টির দিনে লাইন ট্রিপ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লবণের স্তরে কুয়াশা পড়লে ফ্ল্যাশওভার হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নোংরা জায়গায় পলিমার চিনামাটির চেয়ে ভালো', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রুটিন করে ইনসুলেটর ওয়াশিং করা মাস্ট', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বৃষ্টি পড়লে ইনসুলেটর নিজেই সাফ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পলিমার ইনসুলেটর খেলনা, অবহেলা করাই যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পাখির বাসায় ইনসুলেটরের কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লবণের আস্তরণ কারেন্ট আরও ভালো আটকায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'চালু লাইনেই হাত দিয়ে ময়লা মুছে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ধুলো জমলে ক্রিপেজ পথ আরও লম্বা হয়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board32Lines.rivalTaunt,
    rivalLineBn: M3Board32Lines.rivalMyth,
    exitBn: M3Board32Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ভাঙা কোণায় জল-ধুলো জমা',
      'লিকেজ কারেন্ট শুরু',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ভাঙা কোণায় জল আর ধুলো জমে লিকেজ শুরু হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ডিজাইন এমন, যাতে বৃষ্টির জল গড়িয়ে পড়ে যায়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'কোণা ভাঙা ইনসুলেটর বদলাতেই হবে, দেরি নয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মোটা চিনামাটি একটু ভাঙলেও পুরো কাজ করে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ছোট্ট কোণা ভাঙলে লিকেজ হওয়ার ভয় নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ভাঙা কোণায় জল জমলে ইনসুলেটর ঠান্ডা থাকে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'পুরো দুই টুকরো না হলে বদলানোর দরকার নেই', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'কোণা ভাঙা ইনসুলেটর আরও বেশি টান সয়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ধুলো জমলে বরং কারেন্ট আরও ভালো আটকায়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board32Lines {
  static const rivalTaunt = 'আরে, এক কোণা ভেঙেছে বলে আবার ইনসুলেটর বদলাবে? চলো তো!';

  /// Lesson 3.2's first myth buster, word for word.
  static const rivalMyth = 'এক কোণা একটু ভেঙেছে তো কী হয়েছে? ওটা তো অনেক মোটা চিনামাটি।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
