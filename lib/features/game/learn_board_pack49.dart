import 'learn_board_models.dart';

/// Module 4 Lesson 4.9 (রাস্তার আলো (Street Light) মেরামত), the picture board
/// (rung `4.9/learn`, pack `learn_4_9`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board49_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * dark: a light that does not come on — step 1 is the supply (voltage at
///    the terminal with a multimeter; none = supply line or fuse), then the
///    lamp, last the gear (ignitor / ballast, or the LED driver); a whole dark
///    area points to the common controller at the feeder pillar;
///  * day: burning day and night — the photocell is bad, dirty or turned the
///    wrong way: clean it, turn its sensor to the sky or replace it; a
///    headlight or shop light must not fall straight on it;
///  * cycle: on-off-on is the classic end of life of an old HPSV lamp, or a
///    loose connection — change the lamp, tighten every connection; each lamp
///    needs a ballast of its own wattage and type; old lamps and ballasts
///    (mercury or other hazardous matter) are disposed of by the rules;
///  * isolate: switch off that light's fuse / MCB, then prove with a tester
///    or multimeter that the fixture has no voltage — no guessing;
///  * platform: ladder or sky lift stable, secured and a safe distance from
///    overhead lines. (Helmet and harness up top: house rule, drawn.)
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack49 = LearnBoardPack(
  lessonId: '4.9',
  titleBn: 'রাস্তার আলো (Street Light) মেরামত: রাতের প্রহরীকে বাঁচান',
  badgeBn: 'কাজের কারিগর',
  introBn: 'রাস্তার আলো রাতের প্রহরী। ধাপ মেনে দোষ খুঁজুন, নিরাপদে সারান।',
  earnedBn: 'আগে সাপ্লাই, তারপর ল্যাম্প, শেষে গিয়ার — আর লাইন বিচ্ছিন্ন করে, পরীক্ষা করে তবেই হাত।',
  slots: [
    LearnBoardSlot(
      id: 'dark',
      promptBn: 'রাস্তার লাইট জ্বলছে না — কোথা থেকে শুরু করবেন?',
      options: [
        LearnBoardOption(
          id: 'volt',
          labelBn: 'টার্মিনালে মাল্টিমিটারে ভোল্টেজ মাপা',
          asset: 'assets/game/art/m4_board49/dark_volt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'area',
          labelBn: 'পুরো এলাকা অন্ধকার — ফিডার পিলারের কন্ট্রোলার',
          asset: 'assets/game/art/m4_board49/dark_area.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'gear',
          labelBn: 'মাপামাপি ছাড়াই সোজা ব্যালাস্ট বদল',
          asset: 'assets/game/art/m4_board49/dark_gear.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধাপ মেনে খুঁজুন — আগে সাপ্লাই, তারপর ল্যাম্প, শেষে ব্যালাস্ট, ইগনিটর বা ড্রাইভার।',
        ),
        LearnBoardOption(
          id: 'cell',
          labelBn: 'না জ্বলা লাইটের ফটোসেল বদল',
          asset: 'assets/game/art/m4_board49/dark_cell.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইট না জ্বললে প্রথম ধাপ সাপ্লাই পরীক্ষা — টার্মিনালে ভোল্টেজ মাপুন, অনুমানে যন্ত্রাংশ বদল নয়।',
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'পুরো পাড়া অন্ধকার, একটা ল্যাম্প বদল',
          asset: 'assets/game/art/m4_board49/dark_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরো এলাকার আলো বন্ধ থাকলে সমস্যা সম্ভবত কমন কন্ট্রোলারে বা তার সাপ্লাই লাইনে — একটা ল্যাম্পে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রথম ধাপ: টার্মিনালে ভোল্টেজ আছে কিনা মাপা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভোল্টেজ না থাকলে দোষ সাপ্লাই লাইন বা ফিউজে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পুরো এলাকা অন্ধকার মানে কমন কন্ট্রোলার দেখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সবার আগে ব্যালাস্ট আর ইগনিটর বদলে দেখুন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ভোল্টেজ না মেপেই নতুন ল্যাম্প লাগিয়ে দিন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাইট না জ্বললে দোষ সবসময় ফটোসেলের', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'এলাকা অন্ধকার হলেও প্রতিটা ল্যাম্প বদলান', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সাপ্লাই পরীক্ষা সবার শেষে করলেও চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফিডার পিলারের কন্ট্রোলার কখনো খারাপ হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'day',
      promptBn: 'দুপুরেও রাস্তার লাইট জ্বলছে — কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'clean',
          labelBn: 'ফটোসেলের ময়লা পরিষ্কার করা',
          asset: 'assets/game/art/m4_board49/day_clean.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sky',
          labelBn: 'ফটোসেলের সেন্সর আকাশের দিকে ঘোরানো',
          asset: 'assets/game/art/m4_board49/day_sky.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lamp',
          labelBn: 'ল্যাম্পটাই নতুন করে বদলে দেওয়া',
          asset: 'assets/game/art/m4_board49/day_lamp.svg',
          scene: true,
          correct: false,
          rejectBn: 'দিন-রাত জ্বলা মানে ল্যাম্প জ্বলছে ঠিকই — দোষ ফটোসেলে: খারাপ, ময়লা জমা বা ভুল দিকে ঘোরানো।',
        ),
        LearnBoardOption(
          id: 'gear',
          labelBn: 'ব্যালাস্ট বা ড্রাইভার বদলে দেওয়া',
          asset: 'assets/game/art/m4_board49/day_gear.svg',
          scene: true,
          correct: false,
          rejectBn: 'দিন-রাত জ্বলার কারণ ফটোসেল — পরিষ্কার করুন, সেন্সর আকাশের দিকে ঘোরান বা ফটোসেল বদলান।',
        ),
        LearnBoardOption(
          id: 'down',
          labelBn: 'ফটোসেলের সেন্সর রাস্তার দিকে নামানো',
          asset: 'assets/game/art/m4_board49/day_down.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফটোসেলের সেন্সর থাকবে আকাশের দিকে — ভুল দিকে ঘোরানো থাকলে লাইট দিন-রাত জ্বলতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দিন-রাত জ্বললে দোষ ফটোসেলে — খারাপ বা ময়লা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফটোসেলের সেন্সর থাকবে আকাশের দিকে মুখ করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গাড়ির হেডলাইট যেন সরাসরি ফটোসেলে না পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দিন-রাত জ্বলা মানে ল্যাম্পের আয়ু শেষ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফটোসেলের ময়লায় লাইটের কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সেন্সর রাস্তার দিকে থাকলেই ভালো কাজ করে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দোকানের আলো ফটোসেলে পড়লেই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'দিনে জ্বললে আগে ব্যালাস্টটা বদলে দিন', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফটোসেল কখনোই পরিষ্কার করার দরকার পড়ে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'cycle',
      promptBn: 'পুরোনো সোডিয়াম লাইট বারবার জ্বলছে-নিভছে — কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'lamp',
          labelBn: 'পুরোনো HPSV ল্যাম্প বদলে নতুন',
          asset: 'assets/game/art/m4_board49/cycle_lamp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'সব কানেকশন পরীক্ষা করে টাইট',
          asset: 'assets/game/art/m4_board49/cycle_tight.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cell',
          labelBn: 'জ্বলা-নেভার জন্য ফটোসেল বদল',
          asset: 'assets/game/art/m4_board49/cycle_cell.svg',
          scene: true,
          correct: false,
          rejectBn: 'বারবার জ্বলা-নেভা পুরোনো HPSV ল্যাম্পের আয়ু শেষের লক্ষণ, বা ঢিলা কানেকশন — ল্যাম্প বদলান, কানেকশন টাইট দিন।',
        ),
        LearnBoardOption(
          id: 'any',
          labelBn: 'হাতের কাছের যেকোনো ব্যালাস্ট লাগানো',
          asset: 'assets/game/art/m4_board49/cycle_any.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি ল্যাম্পের জন্য নির্দিষ্ট ওয়াটের ও ধরনের ব্যালাস্ট চাই — ভুল হলে ল্যাম্প জ্বলবে না বা তাড়াতাড়ি খারাপ হবে।',
        ),
        LearnBoardOption(
          id: 'dump',
          labelBn: 'পুরোনো ল্যাম্প নালায় ছুঁড়ে ফেলা',
          asset: 'assets/game/art/m4_board49/cycle_dump.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরোনো সোডিয়াম ল্যাম্প ও ব্যালাস্টে পারদ বা বিপজ্জনক পদার্থ থাকতে পারে — নিয়ম মেনে ডিসপোজ করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জ্বলা-নেভা মানে পুরোনো HPSV ল্যাম্পের আয়ু শেষ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বেশিরভাগ সমস্যাই ঢিলা বা ক্ষয়ে যাওয়া কানেকশনে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পুরোনো ল্যাম্প নিয়ম মেনে ডিসপোজ করতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো ব্যালাস্ট যেকোনো ল্যাম্পে চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জ্বলা-নেভা মানে ফটোসেলটাই বদলাতে হবে এখনই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পুরোনো ল্যাম্প নালায় ফেললে কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কানেকশন টাইট দেওয়ার কোনো দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বড় ওয়াটের ব্যালাস্ট দিলে ল্যাম্প বেশি টেকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নতুন ল্যাম্প দিলেও জ্বলা-নেভা থামবে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'isolate',
      promptBn: 'ল্যাম্প হোল্ডারে হাত দেওয়ার আগে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'mcb',
          labelBn: 'MCB বন্ধ, টেস্টারে ভোল্টেজ নেই দেখা',
          asset: 'assets/game/art/m4_board49/isolate_mcb.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'ফিউজ খুলে মাল্টিমিটারে নিশ্চিত হওয়া',
          asset: 'assets/game/art/m4_board49/isolate_fuse.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'লাইন চালু রেখে সাবধানে ল্যাম্প বদল',
          asset: 'assets/game/art/m4_board49/isolate_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'ল্যাম্প হোল্ডারের ভেতরের কন্টাক্ট লাইভ থাকে — আগে ওই লাইটের ফিউজ বা MCB বন্ধ করুন।',
        ),
        LearnBoardOption(
          id: 'notest',
          labelBn: 'MCB বন্ধ করেই পরীক্ষা ছাড়া কাজ',
          asset: 'assets/game/art/m4_board49/isolate_notest.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোনো অনুমান নয় — বন্ধ করার পরও টেস্টার বা মাল্টিমিটারে নিশ্চিত হোন যে ফিক্সচারে ভোল্টেজ নেই।',
        ),
        LearnBoardOption(
          id: 'glow',
          labelBn: 'টেস্টার জ্বলছে, তবু কাজ চালানো',
          asset: 'assets/game/art/m4_board49/isolate_glow.svg',
          scene: true,
          correct: false,
          rejectBn: 'টেস্টার জ্বললে ফিক্সচারে এখনো ভোল্টেজ আছে — হাত সরান, ওই নির্দিষ্ট লাইটের ফিউজ বা MCB বন্ধ করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে ওই নির্দিষ্ট লাইটের ফিউজ বা MCB বন্ধ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বন্ধের পরও টেস্টারে দেখুন ভোল্টেজ নেই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হোল্ডারের ভেতরের কন্টাক্ট লাইভ থাকতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শুধু ল্যাম্প বদলাতে লাইন বন্ধ লাগে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'MCB বন্ধ করলে আর পরীক্ষার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'টেস্টার জ্বললেও গ্লাভস পরে কাজ চালানো যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সাবধানে হাত দিলে লাইভ হোল্ডারে বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পাশের যেকোনো লাইটের MCB বন্ধ করলেই হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'স্ট্রিট লাইটের সার্কিটে কখনো ভোল্টেজ থাকে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'platform',
      promptBn: 'ওপরে ফিক্সচারে কাজ — কোন প্ল্যাটফর্ম নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'lift',
          labelBn: 'স্থির স্কাই লিফট, তার থেকে দূরে',
          asset: 'assets/game/art/m4_board49/platform_lift.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ladder',
          labelBn: 'পোলে বাঁধা মই, হারনেস আটকানো',
          asset: 'assets/game/art/m4_board49/platform_ladder.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'near',
          labelBn: 'ওভারহেড তারের গা ঘেঁষে বাকেট',
          asset: 'assets/game/art/m4_board49/platform_near.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্ল্যাটফর্ম থাকবে ওভারহেড লাইন থেকে নিরাপদ দূরত্বে — তারের কাছে বাকেট তোলা নয়।',
        ),
        LearnBoardOption(
          id: 'slope',
          labelBn: 'পাথরের ওপর নড়বড়ে মই',
          asset: 'assets/game/art/m4_board49/platform_slope.svg',
          scene: true,
          correct: false,
          rejectBn: 'মই হতে হবে স্থিতিশীল ও সুরক্ষিত — পাথরে দাঁড় করানো নড়বড়ে মইয়ে ওঠা নয়।',
        ),
        LearnBoardOption(
          id: 'tilt',
          labelBn: 'ঢালে হেলে থাকা স্কাই লিফট',
          asset: 'assets/game/art/m4_board49/platform_tilt.svg',
          scene: true,
          correct: false,
          rejectBn: 'হেলে থাকা লিফট স্থিতিশীল নয় — আগে প্ল্যাটফর্ম স্থির ও সুরক্ষিত করুন, তবে ওপরে উঠুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মই বা লিফট হতে হবে স্থিতিশীল ও সুরক্ষিত', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'প্ল্যাটফর্ম থাকবে ওভারহেড লাইন থেকে দূরে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ওপরের কাজে হেলমেট আর হারনেস সবসময় চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ওভারহেড তারের কাছে বাকেট তুললে সুবিধা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মই একটু নড়লেও কাজ চালিয়ে যাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঢালু জায়গায় লিফট দাঁড় করালেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অল্প সময়ের কাজে হারনেস না বাঁধলেও চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পাথরের ওপর মই রাখলে উচ্চতা বেড়ে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মই পোলের সঙ্গে বাঁধার কোনো দরকার পড়ে না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board49Lines.rivalTaunt,
    rivalLineBn: M4Board49Lines.rivalMyth,
    exitBn: M4Board49Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'লাইভ হোল্ডারে খালি আন্দাজে হাত',
      'লাইন বন্ধ না করেই ল্যাম্প বদল',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ল্যাম্প হোল্ডারের ভেতরের কন্টাক্ট লাইভ থাকে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'হাত লাগলে বা শর্ট সার্কিটে মারাত্মক দুর্ঘটনা', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সবসময় লাইন বিচ্ছিন্ন করে তবেই কাজ শুরু', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'শুধু ল্যাম্প বদলাতে লাইন বন্ধের দরকার নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'খুব সাবধানে করলে লাইভ হোল্ডারে কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অভিজ্ঞ লাইনম্যানের হাত লাইভ পিনে লাগে না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ছোট কাজে ফিউজ বা MCB নামানো সময় নষ্ট', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'বাল্ব খুলে নিলে হোল্ডারে আর কারেন্ট থাকে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'গ্লাভস থাকলে লাইভ হোল্ডারে কাজ পুরো নিরাপদ', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board49Lines {
  static const rivalTaunt = 'আরে, শুধু তো একটা বাল্ব! এর জন্য আবার লাইন বন্ধ কেন?';

  /// Lesson 4.9's first myth buster, word for word.
  static const rivalMyth = 'শুধু ল্যাম্পটা বদলানোর জন্য লাইন বন্ধ করার দরকার নেই, খুব সাবধানে করলে কিছু হয় না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
