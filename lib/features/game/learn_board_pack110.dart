import 'learn_board_models.dart';

/// Ladder step 28 — Module 1 Lesson 1.10 (১০ সেকেন্ডের মেন্টাল চেকলিস্ট),
/// the picture board (completes all 10 Learn picture boards of Module 1).
///
/// Picture cards are vector scenes from `tool/scan_board_art.py`. Every round
/// and every trap comes directly from lesson 1.10:
///  * ppe: personal PPE check (chin strap locked, clean EH boots without nail in sole,
///    cotton full sleeves vs unstrapped, torn cloth, nail in sole, directly climbing);
///  * harness_tool: full body harness snug (chest strap locked, 4 fingers gap),
///    tools neatly stowed in pouch vs unfastened chest, climbing with tool in hand,
///    overloaded pockets, frayed harness;
///  * ptw_mind: signed written PTW verified, calm and focused mindset vs verbal
///    mobile call, frantic rush, exhaustion, unread PTW;
///  * pole_distance: 360° sound test at base with hammer, safe clearance to
///    live conductors vs leaning pole, inside Lakshman Rekha, uninspected pole,
///    rusted steel base;
///  * hazard_rescue: clear ground escape path & rescue rope, roadside cones
///    vs beehive on cross-arm, zooming traffic, storm clouds, blocked exit.
///
/// The rival's myth is lesson 1.10's own:
/// "আমি 20 বছর ধরে এই কাজ করছি, আমার এসব চেকলিস্টের দরকার নেই। সবকিছু আমার মাথায় আছে।"
const learnBoardPack110 = LearnBoardPack(
  lessonId: '1.10',
  titleBn: '10 সেকেন্ডের মেন্টাল চেকলিস্ট',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'পা মাটি ছাড়ার আগে মাত্র 10 সেকেন্ড — মস্তিষ্কই সেরা সুরক্ষা কবচ। যাচাই করে নিন।',
  earnedBn: 'অভিজ্ঞতা নয়, চেকলিস্টই সুরক্ষা — 10 সেকেন্ডের স্ক্যান এবার আপনার মজ্জাগত।',
  slots: [
    LearnBoardSlot(
      id: 'ppe',
      promptBn: 'পা মাটি ছাড়ার আগে প্রথম 5 সেকেন্ড — পিপিই স্ক্যানে কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'strap_sole',
          labelBn: 'হেলমেটের স্ট্র্যাপ লক করা',
          asset: 'assets/game/art/scan_board/ppe_strap_sole.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'head_toe',
          labelBn: 'পরিষ্কার ইনসুলেটেড বুটের সোল',
          asset: 'assets/game/art/scan_board/ppe_head_toe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'unstrapped',
          labelBn: 'স্ট্র্যাপ আলগা রেখেই হেলমেট চাপানো',
          asset: 'assets/game/art/scan_board/ppe_unstrapped.svg',
          scene: true,
          correct: false,
          rejectBn: 'হেলমেটের স্ট্র্যাপ না বাঁধলে সামান্য ঝাঁকুনিতেই হেলমেট পড়ে যাবে — মাথা অরক্ষিত।',
        ),
        LearnBoardOption(
          id: 'dirty_cut',
          labelBn: 'ছেঁড়া পলিয়েস্টার জামা পরা',
          asset: 'assets/game/art/scan_board/ppe_dirty_cut.svg',
          scene: true,
          correct: false,
          rejectBn: 'জামা ফাটা বা পলিয়েস্টার হলে আর্ক ফ্ল্যাশের শিখায় গলে চামড়ায় আটকে যায়।',
        ),
        LearnBoardOption(
          id: 'nail_sole',
          labelBn: 'সোলে তার বা পেরেক বিঁধা বুট',
          asset: 'assets/game/art/scan_board/ppe_nail_sole.svg',
          scene: true,
          correct: false,
          rejectBn: 'জুতোর সোলে পেরেক বা তার থাকলে মাটির সাথে সার্কিট তৈরি হয়ে কারেন্ট টানে।',
        ),
        LearnBoardOption(
          id: 'no_check',
          labelBn: 'PPE না দেখেই সরাসরি ওঠা',
          asset: 'assets/game/art/scan_board/ppe_no_check.svg',
          scene: true,
          correct: false,
          rejectBn: 'পা মাটি ছাড়ার আগে মাত্র 5 সেকেন্ড — স্ট্র্যাপ থেকে সোল নিশ্চিত না হয়ে পোলে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মাথা থেকে পা পর্যন্ত পিপিই নিখুঁত যাচাই জরুরি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'স্ট্র্যাপ আর সোলে পেরেক না থাকা জীবনের সুরক্ষা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ছেঁড়া জামা বা ফাটল থাকলে সঙ্গে সঙ্গে বদলান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রোজকার চেনা জামাকাপড় আলাদা করে দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'স্ট্র্যাপ না বাঁধলেও হেলমেট মাথায় ঠিক আটকে থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটু ফাটা জুতো পরলে মাটিতে কারেন্ট কিছু করে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তাড়াহুড়োর সময় পিপিই দেখার চেয়ে কাজ সারা জরুরি', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পলিয়েস্টার জামা পরলেও ছোটখাটো কাজে ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'জুতোয় পেরেক ঢুকলেও রাবার তা সহজে আটকে দিতে পারে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'harness_tool',
      promptBn: 'হারনেস আর টুলস প্রস্তুত — পোলে ওঠার মুখে কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'harness_snug',
          labelBn: 'বুকের বকলস আঁটা ও 4 আঙুল ফাঁক',
          asset: 'assets/game/art/scan_board/harness_snug.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tool_bagged',
          labelBn: 'টুলস ব্যাগে গোছানো ও আটকানো',
          asset: 'assets/game/art/scan_board/tool_bagged.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'harness_loose_chest',
          labelBn: 'বুকের স্ট্র্যাপ খোলা রাখা',
          asset: 'assets/game/art/scan_board/harness_loose_chest.svg',
          scene: true,
          correct: false,
          rejectBn: 'বুকের স্ট্র্যাপ খোলা থাকলে পড়ে যাওয়ার মুহূর্তে শরীর হারনেস থেকে পিছলে বেরিয়ে যায়।',
        ),
        LearnBoardOption(
          id: 'tool_hand_climb',
          labelBn: 'হাতে ভারী রেঞ্জ নিয়ে ওঠা',
          asset: 'assets/game/art/scan_board/tool_hand_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'হাতে টুলস নিয়ে ওঠা বারণ — দুই হাত ও এক পা দিয়ে তিন বিন্দু স্পর্শ রেখে উঠতে হবে।',
        ),
        LearnBoardOption(
          id: 'tool_overload',
          labelBn: 'পকেটে আলগা ভারী টুলস গোঁজা',
          asset: 'assets/game/art/scan_board/tool_overload.svg',
          scene: true,
          correct: false,
          rejectBn: 'অপ্রয়োজনীয় ভারী টুলস নড়াচড়ায় বাধা দেয় এবং নিচে থাকা সঙ্গীর মাথায় পড়তে পারে।',
        ),
        LearnBoardOption(
          id: 'harness_expired',
          labelBn: 'ছেঁড়া ও কাটা ফিতের হারনেস',
          asset: 'assets/game/art/scan_board/harness_expired.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিতে ঘষা বা মেয়াদ শেষ হওয়া হারনেস শরীরের ভর সামলাতে পারবে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বুকের বকলস আঁটা ও 4 আঙুল ফাঁক রাখা নিরাপদ ফিট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টুলস সবসময় নির্দিষ্ট ব্যাগে গোছানো ও আটকানো চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ছেঁড়া বা মেয়াদোত্তীর্ণ হারনেস কখনো পরা যাবে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বুকের স্ট্র্যাপ খোলা রাখলে কাজ করতে অনেক সুবিধা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'এক হাতে ভারী রেঞ্জ নিয়ে মইয়ে চড়া অনেক সহজ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পকেটে আলগা নাটবল্টু ভরে নিলে কাজ অনেক দ্রুত সারা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পুরনো হারনেস হলেও দেখতে ভালো থাকলে নিশ্চিন্তে চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টুলস ব্যাগে না ভরে হাতে ঝুলিয়ে মইয়ে ওঠা বেশি ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হারনেসের ফিতে ঢিলেঢালা রাখলে শরীরে আরাম পাওয়া যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ptw_mind',
      promptBn: 'পারমিট ও নিজের মনের প্রস্তুতি — লাইনে ওঠার আগে কোনটা সঠিক?',
      options: [
        LearnBoardOption(
          id: 'ptw_signed',
          labelBn: 'হাতে সই করা বৈধ পারমিট',
          asset: 'assets/game/art/scan_board/ptw_signed.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ptw_calm_team',
          labelBn: 'সঙ্গীর সাথে পারমিট মেলানো',
          asset: 'assets/game/art/scan_board/ptw_calm_team.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ptw_verbal_phone',
          labelBn: 'ফোনে মৌখিক কথায় লাইনে ওঠা',
          asset: 'assets/game/art/scan_board/ptw_verbal_phone.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফোনের কথায় লাইন বন্ধ ভাবা মারাত্মক — হাতে লিখিত সই করা পারমিট ছাড়া কাজ নয়।',
        ),
        LearnBoardOption(
          id: 'mind_rushed',
          labelBn: 'দেরি হচ্ছে ভেবে তাড়াহুড়ো করা',
          asset: 'assets/game/art/scan_board/mind_rushed.svg',
          scene: true,
          correct: false,
          rejectBn: 'তাড়াহুড়ো আর রাগ মানুষের বিচারবুদ্ধি কেড়ে নেয় — বিভ্রান্ত মনে কাজ করা মারাত্মক ভুল।',
        ),
        LearnBoardOption(
          id: 'mind_tired',
          labelBn: 'অতিরিক্ত ক্লান্তিতে হাই তোলা',
          asset: 'assets/game/art/scan_board/mind_tired.svg',
          scene: true,
          correct: false,
          rejectBn: 'শরীর অত্যন্ত ক্লান্ত বা অসুস্থ থাকলে উঁচুতে কাজ নয় — সুপারভাইজারকে জানিয়ে বিশ্রাম নিন।',
        ),
        LearnBoardOption(
          id: 'ptw_no_read',
          labelBn: 'কাগজ না পড়ে পকেটে গোঁজা',
          asset: 'assets/game/art/scan_board/ptw_no_read.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিটের শর্ত ও ফিডার না মিলিয়ে কাজ শুরু করলে ভুল লাইনে ওঠার ঝুঁকি থাকে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'হাতে সই করা পারমিট ছাড়া লাইনে হাত দেওয়া নিষেধ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শান্ত মনে ফিডার ও শর্ত মিলিয়ে তবেই কাজ শুরু করা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ক্লান্ত বা তাড়াহুড়ো থাকলে আগে নিজেকে সংযত করা চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফোনে কেউ লাইন বন্ধ বললে সরাসরি কাজ শুরু করা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দেরি হয়ে যাচ্ছে ভেবে দ্রুত গতিতে কাজে নামা উচিত', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'খুব ক্লান্ত লাগলেও কাজ ফেলে বিশ্রাম নেওয়া বোকামি', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাগজ না দেখে শুধু মৌখিক ভরসায় কাজ করাই স্মার্টনেস', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পারমিট পকেটে গুঁজে না পড়ে লাইনে ওঠা অনেক নিরাপদ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লাইন বন্ধের কথা সুপারভাইজার জানলেই আর কাগজ লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pole_distance',
      promptBn: 'পোল ও তারের দূরত্ব — ওঠার ঠিক আগে কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'pole_sound',
          labelBn: 'পোলের গোড়ায় সাউন্ড টেস্ট',
          asset: 'assets/game/art/scan_board/pole_sound.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clearance_spot',
          labelBn: 'লক্ষ্মণ রেখার নিরাপদ দূরত্ব',
          asset: 'assets/game/art/scan_board/clearance_spot.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pole_hug_lean',
          labelBn: 'গোড়া ফাটা ও হেলে থাকা পোল',
          asset: 'assets/game/art/scan_board/pole_hug_lean.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলের গোড়ায় ফাটল বা ক্ষয় থাকলে মানুষের ওজন ও টানে পোল ভেঙে পড়তে পারে।',
        ),
        LearnBoardOption(
          id: 'clearance_inside',
          labelBn: 'লক্ষ্মণ রেখার ভেতরে হাত দেওয়া',
          asset: 'assets/game/art/scan_board/clearance_inside.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্পর্শ না করলেও লক্ষ্মণ রেখার ভেতর ঢুকলে বিদ্যুৎ বাতাস ভেদ করে লাফিয়ে ধরে।',
        ),
        LearnBoardOption(
          id: 'pole_skip_scan',
          labelBn: 'পোল পরীক্ষা না করে ওঠা',
          asset: 'assets/game/art/scan_board/pole_skip_scan.svg',
          scene: true,
          correct: false,
          rejectBn: 'রোজকার চেনা পোলেও রাতে ফাটল বা ক্ষয় হতে পারে — প্রতিটি পোলে নতুন পরীক্ষা।',
        ),
        LearnBoardOption(
          id: 'pole_rusted_base',
          labelBn: 'মাটির কাছে জং ধরা ক্ষয়প্রাপ্ত পোল',
          asset: 'assets/game/art/scan_board/pole_rusted_base.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্টিল পোলের আসল শত্রু মাটির নিচের জং — গোড়া ক্ষয়ে গেলে পোল যেকোনো মুহূর্তে ধসে পড়ে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পোলের গোড়ায় হাতুড়ি ঠুকে সাউন্ড টেস্ট করা বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লাইভ তারের লক্ষ্মণ রেখা চিনে বাইরে থাকা জীবনের দাবি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্টিল পোলের গোড়ায় জং বা ফাটল থাকলে ওপরে ওঠা বারণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রোজকার চেনা পোল পরীক্ষা না করে উঠলেও বিপদ হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লক্ষ্মণ রেখার ভেতর হাত বাড়ালেও তার না ছুঁলে চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটু হেলে থাকা পোলে সাবধানে কাজ করলে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'স্টিল পোলে জং ধরলেও সহজে তা ভাঙে না বলে জানা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'চোখ দিয়ে পোল দেখলেই হয়, হাতুড়ি ঠোকার কোনো কাজ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'দূরত্ব না মেপে আন্দাজে কাজ করা অভিজ্ঞ লোকের অভ্যাস', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hazard_rescue',
      promptBn: 'চারপাশের বিপদ ও রেসকিউ — ওঠার ঠিক আগের স্ক্যানে কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'rescue_ready',
          labelBn: 'রেসকিউ রশি ও পালানোর পথ',
          asset: 'assets/game/art/scan_board/rescue_ready.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'site_barricade',
          labelBn: 'ট্র্যাফিক কোণ দিয়ে ব্যারিকেড',
          asset: 'assets/game/art/scan_board/site_barricade.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hazard_beehive',
          labelBn: 'ক্রস-আর্মে মৌমাছির বাসা',
          asset: 'assets/game/art/scan_board/hazard_beehive.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে মৌমাছি বা ভীমরুলের বাসা থাকলে কামড়ের চোটে উঁচুতে হাত ফসকে পড়ে যাবেন।',
        ),
        LearnBoardOption(
          id: 'hazard_traffic',
          labelBn: 'চলন্ত গাড়ির মুখে কোনো কোণ ছাড়া',
          asset: 'assets/game/art/scan_board/hazard_traffic.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিচে ট্র্যাফিক আটকানোর ব্যবস্থা না থাকলে দ্রুতগতির গাড়ি মইয়ে ধাক্কা দিতে পারে।',
        ),
        LearnBoardOption(
          id: 'hazard_storm_sky',
          labelBn: 'আকাশে ঝড় ও বজ্রবিদ্যুৎ',
          asset: 'assets/game/art/scan_board/hazard_storm_sky.svg',
          scene: true,
          correct: false,
          rejectBn: 'মেঘের ডাক বা বাজের সংকেত পেলে উঁচুতে ওঠা সম্পূর্ণ নিষিদ্ধ — রেড লাইন।',
        ),
        LearnBoardOption(
          id: 'rescue_blocked',
          labelBn: 'পালানোর পথে কাঁটাতার ও জটলা',
          asset: 'assets/game/art/scan_board/rescue_blocked.svg',
          scene: true,
          correct: false,
          rejectBn: 'জরুরি বিপদে মাটিতে নামার পথ বন্ধ থাকলে দ্রুত রেসকিউ অসম্ভব হয়ে যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জরুরি বিপদে পালানোর ফাঁকা পথ ও রেসকিউ রশি রাখা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রাস্তার কাজের জায়গায় ট্র্যাফিক কোণ বসানো খুব জরুরি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আকাশে মেঘ ডাকলে বা মৌচাক থাকলে কাজ স্থগিত রাখা চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নিচে গাড়ি চলাচল করলেও মইয়ে উঠে কাজ করা নিরাপদ হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মৌচাক থাকলেও বিরক্ত না করলে কোনো হুল ফোটে না মাঠে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'জরুরি নামার পথ বন্ধ থাকলেও কাজের কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আকাশে বিদ্যুৎ চমকালেও নিচে দাঁড়িয়ে কাজ চালিয়ে যান', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ট্র্যাফিক কোণ না বসিয়ে হাত দেখিয়ে গাড়ি থামানোই ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মইয়ের গোড়া তার দিয়ে জট পাকানো থাকলেও ওঠা ঠিকঠাক', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: ScanBoardLines.rivalTaunt,
    rivalLineBn: ScanBoardLines.rivalMyth,
    exitBn: ScanBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'চেকলিস্ট ছাড়া পোলে ওঠা',
      'অতিরিক্ত আত্মবিশ্বাসে গা ভাসানো',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'অভিজ্ঞতা কখনোই চেকলিস্টের আবশ্যিকতাকে বাদ দেয় না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'পাইলটও হাজার ঘণ্টা উড়ার পরেও চেকলিস্ট অনুসরণ করেন', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'মাত্র 10 সেকেন্ডের সতর্কতা একটি অমূল্য জীবন বাঁচায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: '20 বছর ধরে কাজ করলে চেকলিস্ট ছাড়াই সবকিছু সম্ভব হয়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'চেকলিস্ট মেনে কাজ করলে অকারণে অনেক সময় নষ্ট হয়ে যায়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মাঠে দাঁড়িয়ে ভাবলে কাজের গতি কমে যায় এবং ঝামেলা বাড়ে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ মানুষের মাথায় সব নিয়ম এমনিতেই গেঁথে রাখা থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'আত্মবিশ্বাস বেশি থাকলে দুর্ঘটনা কখনোই কাছে আসতে পারে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'চেকলিস্ট শুধু নতুন ও আনাড়ি কর্মীদের শেখার জন্যই দরকার', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board, in his recorded voice
/// (`r_<sha1>.mp3` in `learnRivalVoice`).
abstract final class ScanBoardLines {
  static const rivalTaunt = 'কী ভাবছেন দাঁড়িয়ে? 20 বছর ধরে তো কাজ করছি, এসব চেকলিস্টের কী দরকার!';

  /// Lesson 1.10's first myth buster, word for word.
  static const rivalMyth = 'আমি 20 বছর ধরে এই কাজ করছি, আমার এসব চেকলিস্টের দরকার নেই। সবকিছু আমার মাথায় আছে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// The new clips this board added.
  static const recorded = [rivalTaunt, rivalMyth];
}
