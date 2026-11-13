import 'learn_board_models.dart';

/// Ladder step 28 — Module 1 Lesson 1.10 (১০ সেকেন্ডের মেন্টাল চেকলিস্ট),
/// the picture board (completes all 10 Learn picture boards of Module 1).
///
/// Picture cards are vector scenes from `tool/scan_board_art.py`; each round
/// is one scene with one thing changed, and the generator asserts that no
/// colour or backdrop marks the safe card in any hand. The rounds follow the
/// lesson's own 10-second scan (lesson 1.10, point 2) and the lessons it
/// recalls:
///  * ppe: "আমার PPE কি 100% ঠিক আছে?" — the kit on the bench (lesson 1.1):
///    a hairline crack in the helmet, a nail in the sole, a pinhole in the
///    air test, a synthetic shirt;
///  * harness_tool: "বকলস, ফিতে এবং ফিটিং" — the harness on him (lesson 1.4):
///    four fingers, chest strap mid-chest; open, at the neck, twisted, cut;
///  * ptw_mind: the permit number and conditions (lessons 1.6, 1.10) and
///    "আমি কি ক্লান্ত, বিক্ষিপ্ত বা তাড়াহুড়োর মধ্যে আছি?";
///  * pole_distance: the pole checked myself (lesson 1.3: lean, base, the
///    hammer's sound, rust at the ground line) and the লক্ষ্মণ রেখা (lesson
///    1.2: a long tool's tip counts as your hand);
///  * hazard_rescue: "জল, ট্র্যাফিক, মৌমাছি", the weather (lesson 1.9:
///    lightning is the red line) and the escape route / rescue plan.
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
      promptBn: 'প্রথম 5 সেকেন্ড — আজকের পিপিই-র কোন সেটটা 100% ঠিক?',
      options: [
        LearnBoardOption(
          id: 'kit_ok_a',
          labelBn: 'অক্ষত হেলমেট, সোল, গ্লাভস ও সুতির জামা',
          asset: 'assets/game/art/scan_board/kit_ok_a.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'kit_ok_b',
          labelBn: 'ফাটলহীন হেলমেট, লিকহীন গ্লাভস',
          asset: 'assets/game/art/scan_board/kit_ok_b.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'helmet_crack',
          labelBn: 'হেলমেটে চুলের মতো ফাটল',
          asset: 'assets/game/art/scan_board/kit_helmet_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফাটল ধরা হেলমেট মানে ফুটো ছাতা — আঘাতের শক আর নিতে পারে না।',
        ),
        LearnBoardOption(
          id: 'nail_sole',
          labelBn: 'বুটের সোলে পেরেক গাঁথা',
          asset: 'assets/game/art/scan_board/kit_nail_sole.svg',
          scene: true,
          correct: false,
          rejectBn: 'সোলে পেরেক থাকলে সেটাই কারেন্ট মাটিতে নামার রাস্তা — সাক্ষাৎ মৃত্যুফাঁদ।',
        ),
        LearnBoardOption(
          id: 'glove_leak',
          labelBn: 'এয়ার টেস্টে গ্লাভস থেকে হাওয়া বেরোচ্ছে',
          asset: 'assets/game/art/scan_board/kit_glove_leak.svg',
          scene: true,
          correct: false,
          rejectBn: 'পিনের ডগার মতো ফুটো থাকলেও মৃত্যু নিশ্চিত — লিক থাকলে সেই গ্লাভস নয়।',
        ),
        LearnBoardOption(
          id: 'polyester',
          labelBn: 'চকচকে পলিয়েস্টারের জামা',
          asset: 'assets/game/art/scan_board/kit_polyester.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্পার্ক বা আর্কিং ফ্ল্যাশে সিন্থেটিক কাপড় গলে সোজা চামড়ায় সেঁটে যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'হেলমেট থেকে জুতোর সোল পর্যন্ত নিজের চোখে দেখা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফাটল, পেরেক, লিক বা সিন্থেটিক দেখলেই সেটা বাতিল', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এয়ার টেস্টে লিক নেই, সোল অক্ষত — তবেই পোলের দিকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রোজকার চেনা জামাকাপড় আলাদা করে দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সাথী তো দেখেই নিয়েছে, নিজে আর দেখার কী দরকার', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটু ফাটা হেলমেটেও মাথা ঠিকই বেঁচে যায় সব সময়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পলিয়েস্টার জামা পরলেও ছোটখাটো কাজে ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জুতোয় পেরেক ঢুকলেও রাবার তা সহজে আটকে দিতে পারে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নতুন গ্লাভস হলে আর এয়ার টেস্ট করার দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'harness_tool',
      promptBn: 'হারনেস পরা হলো — বকলস, ফিতে আর ফিটিং: কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'harness_snug',
          labelBn: 'ফিতের নিচে 4 আঙুল, বকলস আঁটা',
          asset: 'assets/game/art/scan_board/harness_snug.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'harness_tail',
          labelBn: 'বুকের ফিতে মাঝ বুকে, বকলস লক',
          asset: 'assets/game/art/scan_board/harness_tail.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'harness_loose_chest',
          labelBn: 'বুকের ফিতে খোলা ঝুলছে',
          asset: 'assets/game/art/scan_board/harness_loose_chest.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঢিলেঢালা হারনেস পতনের সময় শরীর থেকে খুলে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'harness_chest_high',
          labelBn: 'বুকের ফিতে গলার কাছে',
          asset: 'assets/game/art/scan_board/harness_chest_high.svg',
          scene: true,
          correct: false,
          rejectBn: 'বুকের ফিতে থাকবে বুকের মাঝ বরাবর — ভুল জায়গায় চাপে গুরুতর আঘাত।',
        ),
        LearnBoardOption(
          id: 'harness_twisted',
          labelBn: 'কাঁধের ফিতে পেঁচানো',
          asset: 'assets/game/art/scan_board/harness_twisted.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিতে পেঁচিয়ে থাকা মানে ভুল ফিটিং — পড়লে ভুল জায়গায় চাপ পড়ে।',
        ),
        LearnBoardOption(
          id: 'harness_frayed',
          labelBn: 'কাটা, সুতো ওঠা ফিতে',
          asset: 'assets/game/art/scan_board/harness_frayed.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছোট কাটা বা ছেঁড়া ফিতেই হারনেসের শক্তি 50% পর্যন্ত কমিয়ে দেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফিতের নিচে 4 আঙুল, বুকের ফিতে মাঝ বরাবর — এটাই ফিট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বকলস লক, ফিতে সোজা আর অক্ষত — তবেই হারনেসে ভরসা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাটা, পেঁচানো বা ঢিলে ফিতে দেখলে আগে ঠিক, নয় বাতিল', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বুকের ফিতে খোলা রাখলে পোলে কাজ করতে অনেক সুবিধা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হারনেসের ফিতে ঢিলেঢালা রাখলে শরীরে আরাম পাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পুরনো হারনেস হলেও দেখতে ভালো থাকলে নিশ্চিন্তে চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সামান্য সুতো উঠলেও হারনেসের জোর একই থেকে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফিতে একটু পেঁচিয়ে থাকলেও পড়ার সময় কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অভিজ্ঞ হাতে পরা হারনেসের ফিটিং আর দেখার দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ptw_mind',
      promptBn: 'পারমিট আর নিজের মন — পা মাটি ছাড়ার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'ptw_signed',
          labelBn: 'হাতে লিখিত, সই করা পারমিট',
          asset: 'assets/game/art/scan_board/ptw_signed.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'mind_calm',
          labelBn: 'শান্ত মন, পারমিট হাতে, পোল দেখছেন',
          asset: 'assets/game/art/scan_board/mind_calm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ptw_verbal_phone',
          labelBn: 'ফোনে "লাইন বন্ধ" শুনেই কাজ',
          asset: 'assets/game/art/scan_board/ptw_verbal_phone.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফোনে "লাইন বন্ধ আছে" শুনে কাজ শুরু করা মারাত্মক ভুল — লিখিত পারমিট চাই।',
        ),
        LearnBoardOption(
          id: 'mind_rushed',
          labelBn: 'ঘড়ি দেখে তাড়াহুড়ো',
          asset: 'assets/game/art/scan_board/mind_rushed.svg',
          scene: true,
          correct: false,
          rejectBn: 'তাড়াহুড়ো চেকলিস্টের প্রধান শত্রু — এটা রেস নয়, আগে নিরাপদে ফেরা।',
        ),
        LearnBoardOption(
          id: 'mind_tired',
          labelBn: 'ক্লান্ত, হাই তুলছেন',
          asset: 'assets/game/art/scan_board/mind_tired.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্লান্ত বা বিক্ষিপ্ত মন ছোট কিন্তু জরুরি ধাপ ভুলে যায় — থামুন।',
        ),
        LearnBoardOption(
          id: 'ptw_no_read',
          labelBn: 'পারমিট না পড়েই পকেটে',
          asset: 'assets/game/art/scan_board/ptw_no_read.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট নম্বর আর শর্ত না জেনে ওঠা নয় — ফিডারের নামও মিলিয়ে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সই করা পারমিটের নম্বর আর শর্ত জেনে তবেই কাজ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মন শান্ত না হলে থামুন — তাড়াহুড়ো আর ক্লান্তি শত্রু', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফোনের কথা পারমিট নয় — কাগজে ফিডারের নাম মিলিয়ে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফোনে কেউ লাইন বন্ধ বললে সরাসরি কাজ শুরু করা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দেরি হয়ে যাচ্ছে ভেবে দ্রুত গতিতে কাজে নামা উচিত', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'খুব ক্লান্ত লাগলেও কাজ ফেলে বিশ্রাম নেওয়া বোকামি', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পারমিট পকেটে থাকলেই হলো, পড়ে দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লাইন বন্ধের কথা সুপারভাইজার জানলেই আর কাগজ লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অভিজ্ঞ লোকের মন সবসময় স্থির, নিজেকে দেখার দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'pole_distance',
      promptBn: 'পোল আর লক্ষ্মণ রেখা — ওঠার ঠিক আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'pole_sound',
          labelBn: 'গোড়ায় হাতুড়ি: নিরেট "ঠক্ ঠক্"',
          asset: 'assets/game/art/scan_board/pole_sound.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clearance_spot',
          labelBn: 'টুলের ডগা লক্ষ্মণ রেখার বাইরে',
          asset: 'assets/game/art/scan_board/clearance_spot.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pole_lean',
          labelBn: 'হেলে থাকা পোল, গোড়ায় ফাটল',
          asset: 'assets/game/art/scan_board/pole_lean.svg',
          scene: true,
          correct: false,
          rejectBn: 'হেলে থাকা পোল আপনার শরীরের ভারে ভেঙে পড়তে পারে — গোড়াই আসল শক্তি।',
        ),
        LearnBoardOption(
          id: 'clearance_inside',
          labelBn: 'টুলের ডগা লক্ষ্মণ রেখার ভেতরে',
          asset: 'assets/game/art/scan_board/clearance_inside.svg',
          scene: true,
          correct: false,
          rejectBn: 'টুলের ডগাও আপনার হাত — না ছুঁয়েও বিদ্যুৎ বাতাস ভেদ করে লাফিয়ে আসে।',
        ),
        LearnBoardOption(
          id: 'pole_skip_scan',
          labelBn: 'না দেখেই পোলে ওঠা',
          asset: 'assets/game/art/scan_board/pole_skip_scan.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি পোলে ওঠার আগে নিজে পরীক্ষা — ফাটল, মরিচা বা বাসার কথা ভাবুন।',
        ),
        LearnBoardOption(
          id: 'pole_rusted_base',
          labelBn: 'মাটির কাছে জং, ভোঁতা শব্দ',
          asset: 'assets/game/art/scan_board/pole_rusted_base.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটির সংযোগস্থলে মরিচা ক্যান্সারের মতো — ভোঁতা শব্দ মানে পোল দুর্বল।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'গোড়ায় হাতুড়ি ঠুকে সাউন্ড টেস্ট — নিরেট শব্দে তবেই ওঠা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টুলের ডগাও হাত — তাকেও লক্ষ্মণ রেখার বাইরে রাখা চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হেলে থাকা, ফাটা বা জং ধরা পোলে ওপরে ওঠা বারণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রোজকার চেনা পোল পরীক্ষা না করে উঠলেও বিপদ হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লক্ষ্মণ রেখার ভেতর হাত বাড়ালেও তার না ছুঁলে চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটু হেলে থাকা পোলে সাবধানে কাজ করলে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'স্টিলের পোল শুধু বাঁকে, জং ধরলেও কখনো ভাঙে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'চোখ দিয়ে পোল দেখলেই হয়, হাতুড়ি ঠোকার কোনো কাজ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লম্বা টুলের ডগা তারে না ছুঁলে দূরত্বের হিসেব লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hazard_rescue',
      promptBn: 'চারপাশ, আকাশ আর নামার পথ — ওঠার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'rescue_mate',
          labelBn: 'সঙ্গী নিচে তৈরি, নামার পথ ফাঁকা',
          asset: 'assets/game/art/scan_board/rescue_mate.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'site_clear',
          labelBn: 'শুকনো গোড়া, ফাঁকা রাস্তা, শান্ত আকাশ',
          asset: 'assets/game/art/scan_board/site_clear.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hazard_beehive',
          labelBn: 'ক্রস-আর্মের নিচে মৌচাক',
          asset: 'assets/game/art/scan_board/hazard_beehive.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে বোলতা বা মৌমাছির চাক মানেই বিপদ — না উঠে আগে জানান।',
        ),
        LearnBoardOption(
          id: 'hazard_traffic',
          labelBn: 'গা ঘেঁষে চলছে গাড়ি',
          asset: 'assets/game/art/scan_board/hazard_traffic.svg',
          scene: true,
          correct: false,
          rejectBn: 'আশেপাশের ট্র্যাফিকও বিপদ — চারপাশ না দেখে পা মাটি ছাড়বেন না।',
        ),
        LearnBoardOption(
          id: 'hazard_storm_sky',
          labelBn: 'আকাশে বাজ পড়ছে',
          asset: 'assets/game/art/scan_board/hazard_storm_sky.svg',
          scene: true,
          correct: false,
          rejectBn: 'বজ্রপাতে কোনো PPE কাজ করে না — এটা রেড লাইন, ওঠা নয়।',
        ),
        LearnBoardOption(
          id: 'hazard_water',
          labelBn: 'পোলের গোড়ায় জল জমে',
          asset: 'assets/game/art/scan_board/hazard_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলের গোড়ায় জল জমে আছে — জলও বিপদ, আগে গোড়া পরীক্ষা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নামার পথ ফাঁকা আর সঙ্গী তৈরি — এটাই রেসকিউ প্ল্যান', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জল, ট্র্যাফিক, মৌমাছি আর আকাশ দেখে তবেই ওঠা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আকাশে বাজ দেখলে কাজ নয় — বজ্রপাত হলো রেড লাইন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নিচে গাড়ি চলাচল করলেও পোলে উঠে কাজ করা নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মৌচাক থাকলেও বিরক্ত না করলে কোনো হুল ফোটে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নামার পথ বন্ধ থাকলেও কাজের কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রাবারের জুতো-গ্লাভস থাকলে বাজেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গোড়ায় একটু জল জমলে পোলের কিছুই যায় আসে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রেসকিউর কথা আগে ভাবলে কাজে অমঙ্গল ডেকে আনে', correct: false),
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
      LearnWhyChip(id: 'm1', textBn: 'অভিজ্ঞতা চেকলিস্টের জায়গা নেয় না, তাকে আরও শক্ত করে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'পাইলটও হাজার ঘণ্টা উড়ার পরেও চেকলিস্ট অনুসরণ করেন', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'রুটিন কাজেই মানুষ সবচেয়ে বেশি ভুল করে, তাই চেকলিস্ট', correct: true),
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
