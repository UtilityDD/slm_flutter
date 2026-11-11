import 'learn_board_models.dart';

/// Module 3 Lesson 3.9 (গার্ড ওয়্যার ও ক্রেডল গার্ডিং: অতিরিক্ত সুরক্ষা জাল),
/// the picture board (rung `3.9/learn`, pack `learn_3_9`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board39_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * cross: guarding is mandatory where a line crosses a road, a railway or
///    a telecom line (Indian Electricity Rules) — public safety;
///  * catch: a snapped live conductor falls on the earthed cradle (or the
///    cage on a vertical-formation line): a heavy phase-to-earth fault, the
///    relay trips the breaker and the line goes dead. Stolen / poor earthing
///    leaves the net itself live; a broken net weakens the whole structure;
///  * build: the minimum vertical clearance between the live conductor and
///    the net is mandatory (or an arc / short); firm joints and clamps; the
///    right tension (too tight snaps, too slack sags); the earthing wire run
///    through a pipe against theft;
///  * patrol: at crossings check the net is intact; rust, broken wires, a
///    sagging net (the wind swings it into the live wire) and a stolen earth
///    wire are faults;
///  * repair: treat the guarding as live until the line above is shut down
///    and earthed; control the traffic below.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack39 = LearnBoardPack(
  lessonId: '3.9',
  titleBn: 'গার্ড ওয়্যার ও ক্রেডল গার্ডিং: অতিরিক্ত সুরক্ষা জাল',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'রাস্তা বা রেললাইনের ওপর লাইনের নিচে থাকে সুরক্ষা জাল — ক্রেডল গার্ডিং। চিনে নিন।',
  earnedBn: 'ক্রসিংয়ে গার্ডিং, প্রতিটি পোলে আর্থ — আর গার্ডিংকে সবসময় লাইভ ধরে কাজ।',
  slots: [
    LearnBoardSlot(
      id: 'cross',
      promptBn: 'লাইন কোনো কিছুর ওপর দিয়ে পার হচ্ছে — কোন ছবিটা নিয়মমাফিক?',
      options: [
        LearnBoardOption(
          id: 'road',
          labelBn: 'রাস্তার ওপর লাইনের নিচে গার্ডিং',
          asset: 'assets/game/art/m3_board39/cross_road.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rail',
          labelBn: 'রেললাইনের ওপর লাইনের নিচে গার্ডিং',
          asset: 'assets/game/art/m3_board39/cross_rail.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'road_bare',
          labelBn: 'গার্ডিং ছাড়াই রাস্তা পার',
          asset: 'assets/game/art/m3_board39/cross_road_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'রাস্তা পার হলে গার্ডিং বাধ্যতামূলক — তার ছিঁড়লে নিচের মানুষ আর গাড়ির ওপর পড়বে।',
        ),
        LearnBoardOption(
          id: 'rail_bare',
          labelBn: 'গার্ডিং ছাড়াই রেললাইন পার',
          asset: 'assets/game/art/m3_board39/cross_rail_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভারতীয় বিদ্যুৎ নিয়মাবলী অনুযায়ী রেললাইন অতিক্রমে গার্ডিং বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'tele_bare',
          labelBn: 'গার্ডিং ছাড়াই টেলিকম লাইন পার',
          asset: 'assets/game/art/m3_board39/cross_tele_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'টেলিকম লাইনের ওপর দিয়ে গেলেও গার্ডিং বাধ্যতামূলক — ছেঁড়া তার অন্য লাইনে পড়ে মারাত্মক দুর্ঘটনা ঘটায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রাস্তা, রেল বা টেলিকম লাইন পারে গার্ডিং বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ছেঁড়া তার নিচে না পড়ে জালের ওপর আটকে থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গার্ডিং জনসাধারণের সুরক্ষার এক অপরিহার্য ব্যবস্থা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গার্ডিং শুধু হাইওয়েতে লাগে, রেললাইনে নয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টেলিকম লাইনের ওপর দিয়ে গেলে গার্ডিং লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তার মজবুত হলে ক্রসিংয়েও গার্ডিং বাড়তি খরচ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছেঁড়া তার নিচে পড়ার আগেই নিজে থেকে বন্ধ হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গার্ডিং শুধু লাইনের সৌন্দর্যের জন্য লাগানো হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রাতে গাড়ি কম চলে, তাই রাস্তায় গার্ডিং লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'catch',
      promptBn: 'ক্রসিংয়ে ওপরের লাইভ তার ছিঁড়ে পড়েছে — কোন গার্ডিং তার কাজ করেছে?',
      options: [
        LearnBoardOption(
          id: 'cradle',
          labelBn: 'ছেঁড়া তার ক্রেডলে আটকে, ব্রেকার ট্রিপ',
          asset: 'assets/game/art/m3_board39/catch_cradle.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cage',
          labelBn: 'ছেঁড়া তার খাঁচায় আটকে, ব্রেকার ট্রিপ',
          asset: 'assets/game/art/m3_board39/catch_cage.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'road',
          labelBn: 'গার্ডিং নেই, তার রাস্তায় পড়েছে',
          asset: 'assets/game/art/m3_board39/catch_road.svg',
          scene: true,
          correct: false,
          rejectBn: 'গার্ডিং না থাকলে ছেঁড়া লাইভ তার নিচের মানুষ আর যানবাহনের ওপর পড়ে মহাবিপদ ঘটায়।',
        ),
        LearnBoardOption(
          id: 'noearth',
          labelBn: 'আর্থিং চুরি যাওয়া জালে তার পড়েছে',
          asset: 'assets/game/art/m3_board39/catch_noearth.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্থিং চুরি বা নষ্ট হলে গার্ডিং কার্যকারিতা হারায় — পুরো জালটাই লাইভ হয়ে মারণফাঁদ।',
        ),
        LearnBoardOption(
          id: 'torn',
          labelBn: 'ছেঁড়া জালের ফাঁক গলে তার পড়েছে',
          asset: 'assets/game/art/m3_board39/catch_torn.svg',
          scene: true,
          correct: false,
          rejectBn: 'গার্ডিং একটি সম্মিলিত সিস্টেম — ছেঁড়া জাল পুরো কাঠামোকে দুর্বল করে, তার আটকাতে পারে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আর্থ করা জালে তার পড়লেই ভারী আর্থ ফল্ট হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রিলে ফল্ট ধরে ব্রেকার ট্রিপ করায়, লাইন বন্ধ হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভার্টিকাল লাইনে এই কাজ করে খাঁচা বা কেজ গার্ডিং', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জালে তার পড়লে লাইন চালু থাকাই ভালো লক্ষণ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আর্থিং ছাড়া জালেই ছেঁড়া তার বেশি নিরাপদে থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গার্ডিংয়ে আর্থ ফল্ট হলে ব্রেকার ট্রিপ করে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'খাঁচা গার্ডিং শুধু অনুভূমিক লাইনেই বসানো হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জাল একটু ছেঁড়া থাকলেও তার ঠিকই আটকে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্রেকার ট্রিপ মানে গার্ডিং ঠিকমতো কাজ করেনি', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'build',
      promptBn: 'রাস্তার ওপর নতুন ক্রেডল গার্ডিং বসানো হলো — কোনটা নিয়মমাফিক?',
      options: [
        LearnBoardOption(
          id: 'gap',
          labelBn: 'লাইভ তার আর জালের মাঝে নিরাপদ দূরত্ব',
          asset: 'assets/game/art/m3_board39/build_gap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pipe',
          labelBn: 'আর্থিং তার পাইপের ভেতর দিয়ে সুরক্ষিত',
          asset: 'assets/game/art/m3_board39/build_pipe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'close',
          labelBn: 'লাইভ তারের ঠিক নিচে জাল',
          asset: 'assets/game/art/m3_board39/build_close.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইভ তার আর জালের মাঝে ন্যূনতম উল্লম্ব দূরত্ব আইনত বাধ্যতামূলক — কম হলে আর্ক বা শর্ট সার্কিট।',
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'অতিরিক্ত টানে জালের তার ছিঁড়েছে',
          asset: 'assets/game/art/m3_board39/build_tight.svg',
          scene: true,
          correct: false,
          rejectBn: 'টান হবে ঠিকঠাক — খুব বেশিও নয়, খুব কমও নয়। অতিরিক্ত টানে তার ছিঁড়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'slack',
          labelBn: 'কম টানে জাল ঝুলে পড়েছে',
          asset: 'assets/game/art/m3_board39/build_slack.svg',
          scene: true,
          correct: false,
          rejectBn: 'কম টানে জাল ঝুলে পড়ে — তারে সঠিক টান দিন, খুব বেশিও নয়, খুব কমও নয়।',
        ),
        LearnBoardOption(
          id: 'joint',
          labelBn: 'দুর্বল ক্ল্যাম্প খুলে জাল ঝুলছে',
          asset: 'assets/game/art/m3_board39/build_joint.svg',
          scene: true,
          correct: false,
          rejectBn: 'জালের ক্ল্যাম্প ও জয়েন্ট মজবুত রাখুন — একটা দুর্বল জয়েন্ট পুরো গার্ডিংকে অকেজো করে দিতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তার আর জালের মাঝে উল্লম্ব দূরত্ব আইনত বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'জালের তারে টান হবে ঠিকঠাক, বেশিও নয়, কমও নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চুরি ঠেকাতে আর্থিং তার পাইপের ভেতর দিয়ে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জাল লাইভ তারের যত কাছে, তত ভালো আটকায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জালের তার যত বেশি টানে, গার্ডিং তত মজবুত', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটা জয়েন্ট দুর্বল হলেও বাকিরা সামলে নেয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্থিং তার চুরি গেলেও গার্ডিং ঠিক কাজ করে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জাল একটু ঝুলে থাকলে তার আরও ভালো আটকায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রাস্তার ওপর গ্রাউন্ড ক্লিয়ারেন্সের নিয়ম নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'patrol',
      promptBn: 'লাইন পেট্রোলিং-এ ক্রসিংয়ের গার্ডিং দেখছেন — কোনটা ঠিক অবস্থায় আছে?',
      options: [
        LearnBoardOption(
          id: 'intact',
          labelBn: 'জাল অক্ষত, ঠিক টানে, দুই পোলে আর্থ',
          asset: 'assets/game/art/m3_board39/patrol_intact.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'পাইপে ঢাকা আর্থিং তার অক্ষত',
          asset: 'assets/game/art/m3_board39/patrol_earth.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'জালের তারে মরিচা ধরেছে',
          asset: 'assets/game/art/m3_board39/patrol_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্যালভানাইজিং নষ্ট হলে GI তারে মরিচা ধরে, জাল দুর্বল হয়ে পড়ে।',
        ),
        LearnBoardOption(
          id: 'broken',
          labelBn: 'জালের দুটো তার ছিঁড়ে ঝুলছে',
          asset: 'assets/game/art/m3_board39/patrol_broken.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটা-দুটো তার ছিঁড়লেও পুরো কাঠামোর যান্ত্রিক শক্তি দুর্বল হয়, ঝুলে পড়ে অন্য বিপদ ঘটায়।',
        ),
        LearnBoardOption(
          id: 'sag',
          labelBn: 'ঝোলা জাল বাতাসে লাইভ তার ছুঁচ্ছে',
          asset: 'assets/game/art/m3_board39/patrol_sag.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঝুলে পড়া গার্ডিং বাতাসের দোলায় লাইভ তার ছুঁয়ে শর্ট সার্কিট ঘটাতে পারে।',
        ),
        LearnBoardOption(
          id: 'stolen',
          labelBn: 'পোলের আর্থিং তার চুরি হয়ে গেছে',
          asset: 'assets/game/art/m3_board39/patrol_stolen.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্থিং কানেকশন চুরি গেলে গার্ডিং কার্যকারিতা হারায় — জাল নিজেই লাইভ হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ক্রসিংয়ে জাল ছেঁড়া বা ঝুলে পড়েছে কিনা দেখুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মরিচা বা ক্ষয়ে জাল দুর্বল হয়েছে কিনা দেখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আর্থিং তার চুরি বা ক্ষয় হয়েছে কিনা দেখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটা-দুটো তার ছিঁড়লে কিছু হয় না, বাকিরা আছে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মরিচা ধরা জাল আরও শক্ত হয়ে টিকে থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঝুলে পড়া জাল ছেঁড়া তার আটকাতে আরও ভালো পারে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্থিং তার না থাকলেও জালের কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ক্রসিং পয়েন্টে গার্ডিং দেখার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাতাসে দোলা জাল লাইভ তার ছুঁলেও বিপদ নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'repair',
      promptBn: 'ক্রসিংয়ের গার্ডিং মেরামত করবেন — কোনটা নিরাপদ?',
      options: [
        LearnBoardOption(
          id: 'earthed',
          labelBn: 'শাটডাউন ও আর্থ করে জালে কাজ',
          asset: 'assets/game/art/m3_board39/repair_earthed.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'traffic',
          labelBn: 'আর্থ করা লাইন, নিচে ট্র্যাফিক থামানো',
          asset: 'assets/game/art/m3_board39/repair_traffic.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'ওপরের লাইন চালু রেখেই জালে কাজ',
          asset: 'assets/game/art/m3_board39/repair_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওপরের লাইন সম্পূর্ণ বন্ধ ও আর্থ না হওয়া পর্যন্ত গার্ডিংকে লাইভ ধরে নিন।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে গার্ডিংয়ের তার ধরা',
          asset: 'assets/game/art/m3_board39/repair_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্থিং দুর্বল থাকলে লাইভ তার ছুঁয়ে পুরো গার্ডিং লাইভ হয়ে যেতে পারে — খালি হাতে নয়।',
        ),
        LearnBoardOption(
          id: 'cars',
          labelBn: 'নিচ দিয়ে গাড়ি চলছে, কাজও চলছে',
          asset: 'assets/game/art/m3_board39/repair_cars.svg',
          scene: true,
          correct: false,
          rejectBn: 'গার্ডিং বসানো বা মেরামত ঝুঁকিপূর্ণ কাজ — নিচে ট্র্যাফিক নিয়ন্ত্রণ অত্যন্ত জরুরি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইন বন্ধ ও আর্থ না হলে গার্ডিংকে লাইভ ধরুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজের সময় নিচে ট্র্যাফিক নিয়ন্ত্রণ চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গার্ডিংয়ের কাজ ঝুঁকিপূর্ণ, সব নিয়ম মানুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গার্ডিংয়ের তারে কারেন্ট নেই, লাইন চালু থাকুক', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গার্ডিং আর্থ করা, তাই খালি হাতে ধরা নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নিচে গাড়ি চললেও ওপরের কাজে কোনো ঝুঁকি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অল্প সময়ের মেরামতে শাটডাউন নেওয়ার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ট্র্যাফিক থামানো পুলিশের কাজ, আমাদের নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'জাল লাইনের নিচে, তাই কখনো লাইভ হয় না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board39Lines.rivalTaunt,
    rivalLineBn: M3Board39Lines.rivalMyth,
    exitBn: M3Board39Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'খালি হাতে গার্ডিংয়ের তার',
      'দুর্বল আর্থিংয়ে জাল লাইভ',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'আর্থিং দুর্বল হলে পুরো জাল লাইভ হতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'গার্ডিংকে সবসময় বিপজ্জনক, লাইভ ধরে কাজ করুন', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'লাইভ তার ছুঁলে জালটাই হাই-ভোল্টেজ মারণফাঁদ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'গার্ডিংয়ের তারে কখনোই কোনো কারেন্ট আসে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'জাল আর্থ করা, তাই খালি হাতে ধরলেও কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'আর্থিং চুরি গেলেও গার্ডিং নিরাপদই থাকে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'গার্ডিং লাইনের নিচে থাকে, তাই ছোঁয়া যায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অভিজ্ঞ লাইনম্যান গার্ডিংয়ে গ্লাভস পরে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'শুধু ওপরের তারই বিপদ, নিচের জাল নিরাপদ', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board39Lines {
  static const rivalTaunt = 'আরে, ওটা তো শুধু গার্ডের তার! ওতে আবার গ্লাভস লাগে নাকি?';

  /// Lesson 3.9's first myth buster, word for word.
  static const rivalMyth = 'গার্ডিং-এর তারে তো কোনো কারেন্ট থাকে না, তাই ওটা খালি হাতে ধরলেও চলে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
