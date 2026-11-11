import 'learn_board_models.dart';

/// Module 3 Lesson 3.7 (এলটি ডিস্ট্রিবিউশন বক্স / ফিডার পিলার), the picture
/// board (rung `3.7/learn`, pack `learn_3_7`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board37_art.py`. Every round
/// and every trap comes from the lesson text or its film script:
///  * door: after the work the pillar door is locked properly — an open door
///    is a deadly danger to the public, children above all; on patrol the
///    door, broken / rusted parts, the door seal and the bottom cable entry
///    points are checked so no water or pests get in;
///  * fuse: every outgoing feeder's phase is taken off the busbar through a
///    fuse unit (HRC fuse or SFU), so a fault darkens only that line; a thick
///    wire or a copper strip in place of a fuse kills the protection — on a
///    fault the cable or transformer burns;
///  * faults: a loose connection sparks into a hotspot (black marks, burnt
///    smell); rain water through a broken door / seal (short circuit, rust);
///    rats cut cable insulation (short circuit);
///  * balance: a new connection shares the load among the three phases as
///    equally as possible; an overloaded phase blows its fuse again and again
///    and current flows in the neutral (the film: the neutral heats up); keep
///    R-Y-B phase sequence right on a new connection;
///  * work: inside the pillar is as dangerous as a live panel — full PPE and
///    (VDE) insulated tools; each outgoing cable's IR is meggered here with
///    the line off and the fuses out (the film).
/// The rival's myth is the lesson's first myth buster, word for word (its
/// "৪১৫" in English digits).
const learnBoardPack37 = LearnBoardPack(
  lessonId: '3.7',
  titleBn: 'এলটি (LT) ডিস্ট্রিবিউশন বক্স/ফিডার পিলার: শেষ প্রবেশদ্বার',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'ট্রান্সফরমারের বিদ্যুৎ পাড়ায় পাড়ায় ভাগ হয় এই ফিডার পিলারে। ভেতরটা আর তার সমস্যা চিনে নিন।',
  earnedBn: 'দরজায় তালা, ফিউজের জায়গায় শুধু ফিউজ, তিন ফেজে লোড সমান — আর PPE ছাড়া বক্সে হাত নয়।',
  slots: [
    LearnBoardSlot(
      id: 'door',
      promptBn: 'কাজ শেষ বা পেট্রোলিং — ফিডার পিলার ছেড়ে যাওয়ার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'lock',
          labelBn: 'দরজা বন্ধ করে তালা লাগানো',
          asset: 'assets/game/art/m3_board37/door_lock.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'seal',
          labelBn: 'দরজার সিল আর কেবিল এন্ট্রি দেখা',
          asset: 'assets/game/art/m3_board37/door_seal.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'open',
          labelBn: 'দরজা খোলা রেখে চলে যাওয়া',
          asset: 'assets/game/art/m3_board37/door_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'খোলা দরজা জনসাধারণ, বিশেষ করে বাচ্চাদের জন্য মারাত্মক বিপদ — কাজ শেষে দরজা ঠিকমতো লক করুন।',
        ),
        LearnBoardOption(
          id: 'broken',
          labelBn: 'ভাঙা, মরিচা ধরা দরজা ফেলে যাওয়া',
          asset: 'assets/game/art/m3_board37/door_broken.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা দরজা বা নষ্ট সিল দিয়ে বৃষ্টির জল ঢোকে — ভেতরে শর্ট সার্কিট আর মরিচা। পেট্রোলিং-এ এটাই দেখুন।',
        ),
        LearnBoardOption(
          id: 'gap',
          labelBn: 'নিচের কেবিল এন্ট্রি খোলা রাখা',
          asset: 'assets/game/art/m3_board37/door_gap.svg',
          scene: true,
          correct: false,
          rejectBn: 'খোলা কেবিল এন্ট্রি দিয়ে জল, পোকামাকড় বা ইঁদুর ঢোকে — ইঁদুর কেবিলের ইনসুলেশন কেটে শর্ট সার্কিট ঘটায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাজ শেষে ফিডার পিলারের দরজা ঠিকমতো লক করুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'খোলা দরজা বাচ্চা ও সাধারণ মানুষের জন্য বিপদ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সিল ও কেবিল এন্ট্রি ঠিক থাকলে জল-ইঁদুর ঢোকে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কাজ শেষে দরজা খোলা রাখলে বাতাস চলাচল ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'তালা লাগানো শুধু চুরি আটকানোর জন্য, বিপদের নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভাঙা দরজা থাকলেও ভেতরে জল ঢোকার ভয় নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নিচের কেবিল এন্ট্রি খোলা থাকলে কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মরিচা ধরা বক্স পেট্রোলিং-এ এড়িয়ে গেলেই চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাচ্চারা বক্সের কাছে গেলেও তেমন কোনো বিপদ নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fuse',
      promptBn: 'আউটগোয়িং ফিডার বাসবার থেকে নেবেন — মাঝখানে কী থাকবে?',
      options: [
        LearnBoardOption(
          id: 'hrc',
          labelBn: 'প্রতিটি ফেজে HRC ফিউজ',
          asset: 'assets/game/art/m3_board37/fuse_hrc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sfu',
          labelBn: 'সুইচ ফিউজ ইউনিট (SFU)',
          asset: 'assets/game/art/m3_board37/fuse_sfu.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wire',
          labelBn: 'ফিউজের জায়গায় মোটা তার',
          asset: 'assets/game/art/m3_board37/fuse_wire.svg',
          scene: true,
          correct: false,
          rejectBn: 'এতে ফিউজের সুরক্ষা কবচটাই নষ্ট — ফল্টের সময় ফিউজ না উড়ে কেবিল বা ট্রান্সফরমার পুড়ে যাবে।',
        ),
        LearnBoardOption(
          id: 'strip',
          labelBn: 'ফিউজের জায়গায় তামার পাত',
          asset: 'assets/game/art/m3_board37/fuse_strip.svg',
          scene: true,
          correct: false,
          rejectBn: 'তামার পাত ফল্টে ওড়ে না — ফল্টের সময় সোজা কেবিল আর ট্রান্সফরমার পুড়ে ছাই হয়ে যাবে।',
        ),
        LearnBoardOption(
          id: 'direct',
          labelBn: 'ফিউজ ছাড়াই বাসবারে কেবিল',
          asset: 'assets/game/art/m3_board37/fuse_direct.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি আউটগোয়িং ফেজ ফিউজ ইউনিটের মাধ্যমে নেওয়া হয় — তবেই ফল্টে শুধু ওই লাইনটা বন্ধ হয়, পুরো এলাকা নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফল্টে ফিউজ উড়ে শুধু ওই লাইনটাই বন্ধ হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'HRC ফিউজের কোয়ার্টজ বালু প্রচণ্ড আর্ক নিভিয়ে দেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মোটা তার বা পাত লাগালে কেবিল-ট্রান্সফরমার পোড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মোটা তার লাগালে বারবার ফিউজ যাওয়ার ঝামেলা শেষ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'তামার পাত ফিউজের চেয়েও বেশি সুরক্ষা দেয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফিউজ ছাড়া সরাসরি জুড়লে লাইন বেশি ভালো চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একটা লাইনে ফল্টে পুরো এলাকা বন্ধ হওয়াই ভালো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'HRC ফিউজ গললে সবসময় বিস্ফোরণ আর আগুন হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফিউজ বারবার উড়লে তার জুড়ে দেওয়াই সমাধান', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'faults',
      promptBn: 'টর্চ জ্বেলে বক্সের ভেতর দেখছেন — কোন ছবিটা সুস্থ বক্সের?',
      options: [
        LearnBoardOption(
          id: 'tight',
          labelBn: 'পরিষ্কার, শক্ত ফিউজ কানেকশন',
          asset: 'assets/game/art/m3_board37/faults_tight.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'dry',
          labelBn: 'শুকনো তলা, সিল করা কেবিল এন্ট্রি',
          asset: 'assets/game/art/m3_board37/faults_dry.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hotspot',
          labelBn: 'কানেকশনে কালো পোড়া দাগ',
          asset: 'assets/game/art/m3_board37/faults_hotspot.svg',
          scene: true,
          correct: false,
          rejectBn: 'কালো দাগ বা পোড়া গন্ধ মানে হটস্পট — কানেকশন ঢিলা হয়ে জায়গাটা অতিরিক্ত গরম হচ্ছে।',
        ),
        LearnBoardOption(
          id: 'spark',
          labelBn: 'ঢিলা কানেকশনে স্পার্কিং',
          asset: 'assets/game/art/m3_board37/faults_spark.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাসবার বা ফিউজ ইউনিটের কানেকশন ঢিলা হলে স্পার্কিং হয়, জায়গাটা গরম হয়ে হটস্পট তৈরি হয়।',
        ),
        LearnBoardOption(
          id: 'water',
          labelBn: 'ভেতরে বৃষ্টির জল আর মরিচা',
          asset: 'assets/game/art/m3_board37/faults_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা দরজা বা নষ্ট সিল দিয়ে বৃষ্টির জল ঢুকলে শর্ট সার্কিট আর মরিচা — এ বক্স সুস্থ নয়।',
        ),
        LearnBoardOption(
          id: 'rat',
          labelBn: 'ইঁদুরে কাটা কেবিলের ইনসুলেশন',
          asset: 'assets/game/art/m3_board37/faults_rat.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইঁদুর বা অন্য প্রাণী কেবিলের ইনসুলেশন কেটে শর্ট সার্কিট ঘটায় — জল ও ইঁদুর ঢুকলে বিপদ নিশ্চিত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কালো দাগ বা পোড়া গন্ধে হটস্পট চেনা যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জল বা ইঁদুর ঢুকলে শর্ট সার্কিট প্রায় নিশ্চিত', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিয়মিত পরিদর্শনেই এই সমস্যাগুলো এড়ানো যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কানেকশন একটু ঢিলা হলে তেমন কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কালো দাগ মানে শুধু ধুলো, মুছে দিলেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বক্সে একটু জল জমলে নিজে থেকেই শুকিয়ে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ইঁদুর কেবিল কাটলেও ইনসুলেশনের কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পোড়া গন্ধ পেলেও বক্স খুলে দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মরিচা শুধু দেখতে খারাপ, বিপদের কিছু নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'balance',
      promptBn: 'এলাকায় নতুন কানেকশন দেবেন — কোন ফেজে জুড়বেন?',
      options: [
        LearnBoardOption(
          id: 'low_b',
          labelBn: 'সবচেয়ে কম লোডের B ফেজে জোড়া',
          asset: 'assets/game/art/m3_board37/balance_low_b.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'low_y',
          labelBn: 'সবচেয়ে কম লোডের Y ফেজে জোড়া',
          asset: 'assets/game/art/m3_board37/balance_low_y.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'heavy',
          labelBn: 'সবচেয়ে বেশি লোডের ফেজে জোড়া',
          asset: 'assets/game/art/m3_board37/balance_heavy.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটা ফেজে বেশি লোড দিলে সেই ফেজের ফিউজ বারবার উড়বে — তিন ফেজে লোড যতটা সম্ভব সমান ভাগ করুন।',
        ),
        LearnBoardOption(
          id: 'blown',
          labelBn: 'ভারী ফেজের ফিউজ বারবার বদলানো',
          asset: 'assets/game/art/m3_board37/balance_blown.svg',
          scene: true,
          correct: false,
          rejectBn: 'একই ফেজের ফিউজ বারবার উড়ছে মানে সেই ফেজে ওভারলোড — শুধু ফিউজ বদলালে সমস্যা মেটে না।',
        ),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'নিউট্রাল গরম, তবু এক ফেজে জোড়া',
          asset: 'assets/game/art/m3_board37/balance_neutral.svg',
          scene: true,
          correct: false,
          rejectBn: 'লোড আনব্যালেন্স হলে নিউট্রালে কারেন্ট বেড়ে নিউট্রাল গরম হয় — সিস্টেমের ওপর চাপ, বড় দুর্ঘটনার কারণ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তিন ফেজে লোড যতটা সম্ভব সমানভাবে ভাগ করুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এক ফেজে ওভারলোড হলে সেই ফিউজ বারবার উড়বে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নতুন কানেকশনে R-Y-B ফেজ সিকোয়েন্স ঠিক রাখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যে ফেজ হাতের কাছে, নতুন কানেকশন সেখানেই দিন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আনব্যালেন্স হলে নিউট্রালে কোনো কারেন্ট যায় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফিউজ বারবার উড়লে নতুন ফিউজ দিলেই সমাধান', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সব নতুন কানেকশন এক ফেজে দিলে কাজ সহজ হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফেজ সিকোয়েন্স উল্টে গেলেও গ্রাহকের ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লোড ব্যালেন্স শুধু ইঞ্জিনিয়ারদের মাথাব্যথা', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'work',
      promptBn: 'ফিডার পিলারের ভেতরে কাজ বা মেগারিং — কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'ppe',
          labelBn: 'PPE, গ্লাভস আর ইনসুলেটেড টুলসে কাজ',
          asset: 'assets/game/art/m3_board37/work_ppe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'megger',
          labelBn: 'লাইন বন্ধ, ফিউজ খুলে IR মাপা',
          asset: 'assets/game/art/m3_board37/work_megger.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে বক্সের ভেতর কাজ',
          asset: 'assets/game/art/m3_board37/work_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিডার পিলারের ভেতর লাইভ প্যানেলের মতোই বিপজ্জনক — সম্পূর্ণ PPE ছাড়া বক্সে হাত নয়।',
        ),
        LearnBoardOption(
          id: 'metal',
          labelBn: 'খোলা ধাতুর স্ক্রু-ড্রাইভারে কাজ',
          asset: 'assets/game/art/m3_board37/work_metal.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেশনহীন টুল বাসবার ছুঁলেই শর্ট সার্কিট — ভেতরে শুধু VDE ইনসুলেটেড টুলস।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'ফিউজ না খুলেই মেগার লাগানো',
          asset: 'assets/game/art/m3_board37/work_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'মেগারিং-এর আগে লাইন বন্ধ করে ফিউজ খুলুন — তারপর প্রতিটি কেবিলের IR মাপুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বক্সের ভেতরটা লাইভ প্যানেলের মতোই বিপজ্জনক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সম্পূর্ণ PPE ও VDE ইনসুলেটেড টুলস ছাড়া হাত নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লাইন বন্ধ করে ফিউজ খুলে তবেই কেবিলের IR মাপুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'LT বক্সে শুধু 415 ভোল্ট, গ্লাভস না হলেও চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো স্ক্রু-ড্রাইভার দিয়েই বক্সে কাজ চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফিউজ লাগানো অবস্থাতেই মেগারিং করা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফিউজ খুলে নিলে বাসবারেও আর বিদ্যুৎ থাকে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্লাভস পরলে খোলা ধাতুর টুলেও কোনো বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অভিজ্ঞ লাইনম্যানের ছোট কাজে PPE লাগে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board37Lines.rivalTaunt,
    rivalLineBn: M3Board37Lines.rivalMyth,
    exitBn: M3Board37Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'শুধু 415 ভোল্ট ভেবে অবহেলা',
      'শর্ট সার্কিটে আর্ক ফ্ল্যাশ',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: '415 ভোল্টই মারাত্মক শক দেওয়ার জন্য যথেষ্ট', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'বিশাল ফল্ট কারেন্টে শর্ট সার্কিট মানে আর্ক ফ্ল্যাশ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আর্ক ফ্ল্যাশ মুহূর্তে মানুষকে পুড়িয়ে দিতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'LT মানে লো ভোল্টেজ, তাই শকের কোনো ভয় নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ফল্ট কারেন্ট শুধু HT লাইনেই বিপজ্জনক হয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'LT বক্সে শর্ট সার্কিট হলে বড়জোর ফিউজ উড়বে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আর্ক ফ্ল্যাশ শুধু সাবস্টেশনে হয়, বক্সে নয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অভিজ্ঞ লাইনম্যানের LT বক্সে PPE লাগে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: '415 ভোল্টে শক লাগলে একটু ঝিনঝিন করে মাত্র', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board37Lines {
  static const rivalTaunt = 'আরে, এ তো LT বক্স! এর জন্য আবার এত সাজ-সরঞ্জাম কেন?';

  /// Lesson 3.7's first myth buster, word for word (English digits).
  static const rivalMyth = 'এলটি বক্সের ভেতরে তো শুধু 415 ভোল্ট থাকে, এটা তেমন বিপজ্জনক নয়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
