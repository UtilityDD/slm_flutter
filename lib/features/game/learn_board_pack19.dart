import 'learn_board_models.dart';

/// Ladder step 25 — Module 1 Lesson 1.9 (ঝড়-বৃষ্টিতে কাজ: কখন 'না' বলবেন),
/// the picture board (mode like steps 7, 10 and 13).
///
/// Picture cards are vector scenes from `tool/storm_board_art.py`. Every round
/// and every trap comes from the lesson text:
///  * rain: a wet pole, cross-arm, ladder and tools are slippery (a fall);
///    wet PPE and wet air conduct (flashover / arc flash); heavy rain hides
///    the wires; routine maintenance stops in the rain — only an emergency
///    fault repair, with the utmost care;
///  * lightning is the red line: no PPE works; seen or heard, work at height
///    stops at once and the worker comes down to a safe shelter; a direct
///    strike on the pole or in the open is deadly; a strike nearby shocks
///    through the ground and the line;
///  * strong wind (usually over 40–50 km/h): balance lost on the pole, flying
///    dust in the eyes, conductor galloping (a phase-to-phase short, the safe
///    distance shrinks); never fight the wind;
///  * step potential (the lesson's engineering note): a strike spreads
///    voltage through the ground, a shock between the two feet — no big
///    steps in lightning, "hops/shelter" rules;
///  * the pro tips: check the weather before and during the job, trust the
///    feeling that it is unsafe, Stop Work is a right — saying 'না' to unsafe
///    work is a duty, not cowardice (the shelter plan is not drawn: the
///    lesson names no shelter).
/// The rival's myth is the lesson's own: "আমি রাবারের জুতো আর গ্লাভস পরে
/// আছি, তাই বজ্রপাতে আমার কিছু হবে না।" (The supervisor-pressure myth is
/// step 27's.)
const learnBoardPack19 = LearnBoardPack(
  lessonId: '1.9',
  titleBn: "ঝড়-বৃষ্টিতে কাজ: কখন 'না' বলবেন",
  badgeBn: 'সুরক্ষা কবচ',
  introBn: "প্রকৃতি রুদ্র হলে বীরত্ব নয়, বুদ্ধি। কখন থামবেন, কখন 'না' বলবেন — চিনে নিন।",
  earnedBn: "বাজ মানে নেমে আসা — বৃষ্টিতে রুটিন কাজ বন্ধ, অনিরাপদ কাজে 'না' বলুন।",
  slots: [
    LearnBoardSlot(
      id: 'rain',
      promptBn: 'বৃষ্টি নেমেছে, আজ রুটিন মেইনটেন্যান্স — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'packed', labelBn: 'রুটিন কাজ বন্ধ, ব্যাগ গুছিয়ে ফেরা', asset: 'assets/game/art/storm_board/rain_packed.svg', scene: true, correct: true),
        LearnBoardOption(id: 'down', labelBn: 'বৃষ্টি নামতেই মই থেকে নামা', asset: 'assets/game/art/storm_board/rain_down.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'arc',
          labelBn: 'ভেজা গ্লাভসে তারের কাছে কাজ',
          asset: 'assets/game/art/storm_board/rain_arc.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা পিপিই আর ভেজা বাতাসে পরিবাহিতা বাড়ে — ফ্ল্যাশওভার বা আর্ক ফ্ল্যাশের ঝুঁকি।',
        ),
        LearnBoardOption(
          id: 'slip',
          labelBn: 'ভেজা মইয়ে তাড়াহুড়োয় ওঠা',
          asset: 'assets/game/art/storm_board/rain_slip.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা পোল, ক্রস-আর্ম, মই আর টুলস পিছল — ছোট একটা স্লিপই শেষ ভুল হতে পারে।',
        ),
        LearnBoardOption(
          id: 'blind',
          labelBn: 'ঝাপসা বৃষ্টিতে পোলে কাজ',
          asset: 'assets/game/art/storm_board/rain_blind.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভারী বৃষ্টিতে তার আর বিপদ দেখা কঠিন — সাধারণ কাজ বৃষ্টিতে বন্ধ।',
        ),
        LearnBoardOption(
          id: 'raise',
          labelBn: 'বৃষ্টিতে রুটিন কাজ শুরু',
          asset: 'assets/game/art/storm_board/rain_raise.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ মেইনটেন্যান্স বৃষ্টিতে বন্ধ — শুধু জরুরি ফল্ট মেরামত, সর্বোচ্চ সতর্কতায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভেজা পোল, মই আর টুলস পিছল — পতনের ঝুঁকি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভেজা পিপিই-বাতাসে আর্ক ফ্ল্যাশের ঝুঁকি বাড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'রুটিন কাজ বৃষ্টিতে বন্ধ, শুধু জরুরি মেরামত', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বৃষ্টিতে তার ঠান্ডা থাকে, তাই কাজ নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ভেজা গ্লাভস আরও ভালো করে কারেন্ট আটকায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটু সাবধানে উঠলে ভেজা মইয়ে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বৃষ্টিতে তার দেখা না গেলেও আন্দাজে চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রুটিন কাজ আজই সেরে ফেলাটাই আসল দায়িত্ব', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বৃষ্টির জলে গা ভিজলে শক অনেক কম লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'thunder',
      promptBn: 'পোলে কাজ চলছে, হঠাৎ বাজ চমকাল — এখন কী?',
      options: [
        LearnBoardOption(id: 'down', labelBn: 'বাজ দেখেই মই থেকে নামা', asset: 'assets/game/art/storm_board/thunder_down.svg', scene: true, correct: true),
        LearnBoardOption(id: 'away', labelBn: 'নেমে এসে আশ্রয়ের পথে', asset: 'assets/game/art/storm_board/thunder_away.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'finish',
          labelBn: 'শেষ নাটটা টাইট দেওয়া',
          asset: 'assets/game/art/storm_board/thunder_finish.svg',
          scene: true,
          correct: false,
          rejectBn: 'বজ্র দেখলে বা শুনলে উচ্চতায় কাজ তৎক্ষণাৎ বন্ধ — শেষ নাটটাও নয়।',
        ),
        LearnBoardOption(
          id: 'wait_top',
          labelBn: 'ক্রস-আর্মে বসে অপেক্ষা',
          asset: 'assets/game/art/storm_board/thunder_wait_top.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে সরাসরি বজ্রপাত মারাত্মক — ওপরে বসে অপেক্ষা নয়, নেমে আসুন।',
        ),
        LearnBoardOption(
          id: 'climb_up',
          labelBn: 'বাজের মধ্যে মই বেয়ে ওঠা',
          asset: 'assets/game/art/storm_board/thunder_climb_up.svg',
          scene: true,
          correct: false,
          rejectBn: 'বজ্র মানে রেড লাইন — কোনো পিপিই কাজ করে না। ওঠা নয়, কাজ বন্ধ।',
        ),
        LearnBoardOption(
          id: 'lean_pole',
          labelBn: 'পোলে হেলান দিয়ে অপেক্ষা',
          asset: 'assets/game/art/storm_board/thunder_lean_pole.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাছে বাজ পড়লে মাটি আর লাইন দিয়েও শক আসে — পোলের গায়ে আশ্রয় নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বজ্র রেড লাইন — কোনো পিপিই তা আটকায় না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বজ্র দেখলে বা শুনলে উচ্চতায় কাজ তখনই বন্ধ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পোলে আর খোলা জায়গায় সরাসরি বাজ মারাত্মক', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বাজ দূরে পড়ছে, তাই পোলে থাকা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শেষ নাটটা টাইট দিয়ে তারপর নামলেই চলবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পোলের গায়ে দাঁড়ালে বাজ গায়ে লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ওপরে বসে থাকলে বাজ নিচে মাটিতে পড়ে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'হেলমেট পরা থাকলে বাজে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাজের আলো দেখে ঘাবড়ে যাওয়ার কিছু নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'wind',
      promptBn: 'ঝোড়ো হাওয়ায় গাছ নুইছে, তার দুলছে — কী করবেন?',
      options: [
        LearnBoardOption(id: 'wait', labelBn: 'উঁচুর কাজ স্থগিত, নিচে অপেক্ষা', asset: 'assets/game/art/storm_board/wind_wait.svg', scene: true, correct: true),
        LearnBoardOption(id: 'down', labelBn: 'হাওয়া বাড়তেই নেমে আসা', asset: 'assets/game/art/storm_board/wind_down.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'sway',
          labelBn: 'দুলতে দুলতে ওপরে কাজ',
          asset: 'assets/game/art/storm_board/wind_sway.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রবল বাতাসে ব্যালান্স হারানো সহজ — পোলে দাঁড়িয়ে থাকাই কঠিন।',
        ),
        LearnBoardOption(
          id: 'gallop',
          labelBn: 'দুলন্ত তারের পাশে কাজ',
          asset: 'assets/game/art/storm_board/wind_gallop.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ডাক্টর গ্যালপিং — তার দুলে ফেজে ফেজে শর্ট হতে পারে, নিরাপদ দূরত্ব কমে যায়।',
        ),
        LearnBoardOption(
          id: 'dust',
          labelBn: 'ধুলোয় চোখ ঢেকে ওঠা',
          asset: 'assets/game/art/storm_board/wind_dust.svg',
          scene: true,
          correct: false,
          rejectBn: 'উড়ন্ত ধুলো-বালি চোখ আর মনোযোগ কেড়ে নেয় — উঁচুতে কাজ বন্ধ।',
        ),
        LearnBoardOption(
          id: 'raise',
          labelBn: 'হাওয়ার সাথে লড়ে মই তোলা',
          asset: 'assets/game/art/storm_board/wind_raise.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাতাসের সাথে লড়াই জিতবেন না — সাধারণত 40–50 km/h-এর বেশি হাওয়ায় উঁচুতে কাজ বন্ধ, সন্দেহ হলে স্থগিত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রবল বাতাসে পোলে ব্যালান্স রাখা কঠিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তার দুললে নিরাপদ দূরত্ব কমে, শর্ট হতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সাধারণত 40–50 km/h ছাড়ালে উঁচুতে কাজ বন্ধ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জোরে হাওয়ায় তাড়াতাড়ি কাজ সারা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শক্ত করে ধরলে হাওয়া কিছুই করতে পারে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তার যতই দুলুক, নিরাপদ দূরত্ব একই থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চোখে ধুলো গেলে এক হাতে কাজ চালানো যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মই হাওয়ার সাথে লড়ে ঠিকই খাড়া রাখা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হাওয়া থামার অপেক্ষা মানে শুধু সময় নষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'step',
      promptBn: 'কাছেই পোলে বাজ পড়ল, আপনি মাটিতে — কীভাবে সরবেন?',
      options: [
        LearnBoardOption(id: 'small', labelBn: 'ছোট ছোট পা ফেলে সরা', asset: 'assets/game/art/storm_board/step_small.svg', scene: true, correct: true),
        LearnBoardOption(id: 'hop', labelBn: 'দুই পা জোড়া করে লাফ', asset: 'assets/game/art/storm_board/step_hop.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'stride',
          labelBn: 'লম্বা পা ফেলে দৌড়',
          asset: 'assets/game/art/storm_board/step_stride.svg',
          scene: true,
          correct: false,
          rejectBn: 'বজ্রে বড় পদক্ষেপ নয় — মাটিতে ছড়ানো ভোল্টেজ দুই পায়ের মধ্যে শক দেয়।',
        ),
        LearnBoardOption(
          id: 'wide',
          labelBn: 'পা ফাঁক করে দাঁড়ানো',
          asset: 'assets/game/art/storm_board/step_wide.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাজ মাটিতে পড়লে ভোল্টেজ ছড়ায় — দুই পায়ের মধ্যে স্টেপ পোটেনশিয়াল শক।',
        ),
        LearnBoardOption(
          id: 'pole',
          labelBn: 'পোলের গোড়ায় আশ্রয়',
          asset: 'assets/game/art/storm_board/step_pole.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে সরাসরি বজ্রপাত মারাত্মক — পোলের গোড়া আশ্রয় নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বাজ মাটিতে পড়লে ভোল্টেজ চারপাশে ছড়ায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দুই পায়ের মধ্যে ভোল্টেজের ফারাকে শক লাগে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বজ্রে বড় পদক্ষেপ নয় — আশ্রয় নিন, কাজ বন্ধ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লম্বা পা ফেললে তাড়াতাড়ি পৌঁছানো যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পা ফাঁক করে দাঁড়ালে শরীর মজবুত থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পোলের গোড়ায় বসলে বাজ গায়ে লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মাটিতে নামলেই বাজের সব বিপদ শেষ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রাবারের বুট থাকলে মাটির শক লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'plan',
      promptBn: 'দূরে কালো মেঘ জমছে, আকাশ বদলাচ্ছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'forecast', labelBn: 'আবহাওয়ার খবর দেখে নেওয়া', asset: 'assets/game/art/storm_board/plan_forecast.svg', scene: true, correct: true),
        LearnBoardOption(id: 'say_no', labelBn: "অনিরাপদ দেখে 'না' বলা", asset: 'assets/game/art/storm_board/plan_say_no.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'rush',
          labelBn: 'মেঘ দেখে তাড়াহুড়োয় ওঠা',
          asset: 'assets/game/art/storm_board/plan_rush.svg',
          scene: true,
          correct: false,
          rejectBn: 'মেঘ দেখে তাড়াহুড়োয় ওঠা নয় — নিরাপদ না মনে হলে সেই অনুভূতিকে গুরুত্ব দিন, কাজ থামান।',
        ),
        LearnBoardOption(
          id: 'back',
          labelBn: 'মেঘে পিঠ রেখে ওপরে কাজ',
          asset: 'assets/game/art/storm_board/plan_back.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শুরুর আগে আর কাজ চলাকালেও আবহাওয়া দেখুন — আকাশ বদলাচ্ছে।',
        ),
        LearnBoardOption(
          id: 'mate',
          labelBn: 'সঙ্গীর সতর্কতা উড়িয়ে দেওয়া',
          asset: 'assets/game/art/storm_board/plan_mate.svg',
          scene: true,
          correct: false,
          rejectBn: "স্টপ ওয়ার্ক আপনার অধিকার — অনিরাপদ কাজে 'না' বলা ভীরুতা নয়, দায়িত্ব।",
        ),
        LearnBoardOption(
          id: 'raise',
          labelBn: 'মেঘ উপেক্ষা করে মই তোলা',
          asset: 'assets/game/art/storm_board/plan_raise.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শুরুর আগেই আবহাওয়া দেখুন — অনিরাপদ মনে হলে শুরু নয়, স্টপ ওয়ার্ক।',
        ),
      ],
      whyChips: [
        // Both safe cards (checking the forecast, saying 'না') are the same
        // act — stop and read the sky before going up — so every right reason
        // fits either picture (playbook §4).
        LearnWhyChip(id: 'w1', textBn: 'নিরাপদ না মনে হলে সেই অনুভূতিকে গুরুত্ব দিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আকাশ বদলালে থেমে বুঝুন, অনিরাপদ হলে কাজ নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জীবন কাজের চেয়ে বড় — ঝুঁকি দেখলে আগে থামুন', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'মেঘ আসার আগে তাড়াতাড়ি কাজ সেরে ফেলি', correct: false),
        LearnWhyChip(id: 'w6', textBn: "'না' বললে সবাই ভীতু ভাববে, তাই চুপ থাকি", correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একবার কাজ শুরু হলে আকাশ দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সঙ্গী বেশি ভয় পায়, ওর কথা শোনার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আবহাওয়ার খবর দেখা অফিসের লোকের কাজ', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'কাজ বন্ধ করলে লোকে আমায় ফাঁকিবাজ বলবে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: StormBoardLines.rivalTaunt,
    rivalLineBn: StormBoardLines.rivalMyth,
    exitBn: StormBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'বাজের মধ্যে পোলে কাজ',
      'রাবারের জুতো-গ্লাভসে ভরসা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'বাজ মিলিয়ন ভোল্ট — রাবারের পিপিই আটকায় না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'বজ্র রেড লাইন — কাজ থামিয়ে আশ্রয় নিন', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'বজ্রে কোনো পিপিই কাজ করে না, নামতে হয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'রাবারের জুতো পরলে বাজ গায়ে লাগে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'গ্লাভস পরা থাকলে বাজের মধ্যেও কাজ চলে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'বাজ দূরে পড়ছে, তাই ওপরে থাকা যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'রাবার সব বিদ্যুৎ আটকে দেয়, বাজও আটকাবে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'শুকনো জুতো পরা থাকলে বাজে কোনো ভয় নেই', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board, in his recorded voice
/// (`r_<sha1>.mp3` in `learnRivalVoice`). The guide's lines stay in the pack
/// (device TTS until the owner records them).
abstract final class StormBoardLines {
  static const rivalTaunt = 'আরে! একটু মেঘ ডাকছে বলে কাজ ফেলে নামব নাকি?';

  /// Lesson 1.9's first myth buster, word for word.
  static const rivalMyth = 'আমি রাবারের জুতো আর গ্লাভস পরে আছি, তাই বজ্রপাতে আমার কিছু হবে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// The new clips this board added.
  static const recorded = [rivalTaunt, rivalMyth];
}
