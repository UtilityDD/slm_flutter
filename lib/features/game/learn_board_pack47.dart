import 'learn_board_models.dart';

/// Module 4 Lesson 4.7 (ডিপি (DP) স্ট্রাকচার ড্রেসিং: পরিচ্ছন্নতার শিল্প), the
/// picture board (rung `4.7/learn`, pack `learn_4_7`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board47_art.py`, all views of
/// one DP structure. Every round and every trap comes from the lesson text and
/// its film script:
///  * jumper: a smooth, even 'U' or 'C' shape; a tangled jumper is a sign of
///    danger; measure the jumper's length; no needless strain on the wire;
///  * align: crossarms, insulators and fittings exactly horizontal / vertical;
///    the two sides of the structure as symmetrical as possible (load shared
///    evenly);
///  * cable: the transformer's LT cables are bunched and brought down with
///    cable ties or clamps, never left hanging; clearance between HT and LT;
///  * gap: cut off the spare binding-wire tail (in the wind it touches another
///    wire); check clearance from a distance again and again; phase-to-phase
///    and live-to-structure clearance is mandatory; insulated wires rubbing
///    wear through (the lesson's second myth);
///  * finish: tighten every nut, bolt and connector (do not forget it for the
///    look); keep a photo of good work as a record; leave room for future
///    maintenance and new connections; start at the HT top and come down to
///    the LT side.
/// Anyone on the structure wears a helmet and a harness, and the HT line
/// carries portable earths in that picture (house rule; not put into words).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack47 = LearnBoardPack(
  lessonId: '4.7',
  titleBn: 'ডিপি (DP) স্ট্রাকচার ড্রেসিং: পরিচ্ছন্নতার শিল্প',
  badgeBn: 'কাজের কারিগর',
  introBn: 'ড্রেসিং শুধু সৌন্দর্য নয় — পরিপাটি ডিপি মানে নিরাপদ দূরত্ব আর সহজ রক্ষণাবেক্ষণ।',
  earnedBn: 'মসৃণ জাম্পার, বাঁধা কেবিল, ঠিক ক্লিয়ারেন্স, টাইট কানেকশন — এটাই পাকা লাইনম্যানের ড্রেসিং।',
  slots: [
    LearnBoardSlot(
      id: 'jumper',
      promptBn: 'ডিপির মাথায় জাম্পার — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'u',
          labelBn: 'মসৃণ, সুষম U আকৃতির জাম্পার',
          asset: 'assets/game/art/m4_board47/jumper_u.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'c',
          labelBn: 'মসৃণ, সুষম C আকৃতির জাম্পার',
          asset: 'assets/game/art/m4_board47/jumper_c.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tangle',
          labelBn: 'তাড়াহুড়োয় জট পাকানো জাম্পার',
          asset: 'assets/game/art/m4_board47/jumper_tangle.svg',
          scene: true,
          correct: false,
          rejectBn: 'জট পাকানো, এলোমেলো জাম্পার বিপদের লক্ষণ — দৈর্ঘ্য মেপে নিন, মসৃণ বাঁক দিন।',
        ),
        LearnBoardOption(
          id: 'taut',
          labelBn: 'টান টান করে টেনে লাগানো জাম্পার',
          asset: 'assets/game/art/m4_board47/jumper_taut.svg',
          scene: true,
          correct: false,
          rejectBn: 'তারে অপ্রয়োজনীয় চাপ বা টান পড়লে আয়ু কমে — জাম্পারকে মসৃণ U বা C আকৃতি দিন।',
        ),
        LearnBoardOption(
          id: 'long',
          labelBn: 'না মেপে লাগানো লম্বা ঝোলা জাম্পার',
          asset: 'assets/game/art/m4_board47/jumper_long.svg',
          scene: true,
          correct: false,
          rejectBn: 'লম্বা জাম্পার ঝুলে পাশের ফেজের কাছে চলে যায় — নিরাপদ দূরত্ব নষ্ট। দৈর্ঘ্য মেপে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'জাম্পারকে মসৃণ ও সুষম U বা C আকৃতি দিতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লাগানোর আগে জাম্পারের দৈর্ঘ্য মেপে নিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জট পাকানো জাম্পার শর্ট সার্কিটের ফাঁদ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জাম্পার যত টান টান, কাজ তত মজবুত হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জাম্পার একটু লম্বা রাখলে কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'জাম্পারের আকার শুধু দেখার ব্যাপার মাত্র', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তাড়া থাকলে জট পাকানো জাম্পারও চলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'জাম্পারের দৈর্ঘ্য চোখের আন্দাজেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লাইন চললেই জাম্পারের আকার কোনো বিষয় নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'align',
      promptBn: 'ক্রস-আর্ম আর ইনসুলেটর বসানো শেষ — কোন স্ট্রাকচার ঠিক?',
      options: [
        LearnBoardOption(
          id: 'level',
          labelBn: 'ক্রস-আর্ম সোজা, ইনসুলেটর খাড়া',
          asset: 'assets/game/art/m4_board47/align_level.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'even',
          labelBn: 'দুই পাশ প্রতিসম, সব সমান করে বসানো',
          asset: 'assets/game/art/m4_board47/align_even.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tilt',
          labelBn: 'একদিকে হেলে থাকা ক্রস-আর্ম',
          asset: 'assets/game/art/m4_board47/align_tilt.svg',
          scene: true,
          correct: false,
          rejectBn: 'সব ক্রস-আর্ম নিখুঁতভাবে অনুভূমিক রাখতে হয় — হেলানো আর্মে বিন্যাস নষ্ট হয়।',
        ),
        LearnBoardOption(
          id: 'lean',
          labelBn: 'এদিক-ওদিক হেলানো ইনসুলেটর',
          asset: 'assets/game/art/m4_board47/align_lean.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেটর ও অন্যান্য সরঞ্জাম নিখুঁতভাবে উল্লম্ব বা খাড়া করে লাগাতে হয়।',
        ),
        LearnBoardOption(
          id: 'lopsided',
          labelBn: 'সব ইনসুলেটর এক পাশে গাদা করা',
          asset: 'assets/game/art/m4_board47/align_lopsided.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুই দিক যতটা সম্ভব প্রতিসম রাখুন — তাতে মেকানিক্যাল লোড সমানভাবে ভাগ হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ক্রস-আর্ম অনুভূমিক আর ইনসুলেটর উল্লম্ব থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'প্রতিসম স্ট্রাকচারে লোড সমানভাবে ভাগ হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দুই পাশ যতটা সম্ভব সিমেট্রিকাল রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ক্রস-আর্ম একটু হেলে থাকলে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সব সরঞ্জাম এক পাশে রাখলেই কাজ সহজ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ইনসুলেটর হেলে থাকলেও লাইন ঠিকই চলবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'প্রতিসাম্য শুধু দেখার জন্য, কাজের নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বিন্যাস নিয়ে ভাবা সময় নষ্ট ছাড়া কিছু নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'এক পাশে বেশি ভার পড়লেও কোনো সমস্যা নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'cable',
      promptBn: 'ট্রান্সফরমারের এলটি সাইড থেকে কেবিল নামাবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'tie',
          labelBn: 'কেবিল টাই দিয়ে বেঁধে নামানো',
          asset: 'assets/game/art/m4_board47/cable_tie.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clamp',
          labelBn: 'ক্ল্যাম্পে পোলের গায়ে আটকে নামানো',
          asset: 'assets/game/art/m4_board47/cable_clamp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hang',
          labelBn: 'এলোমেলোভাবে ঝুলে থাকা কেবিল',
          asset: 'assets/game/art/m4_board47/cable_hang.svg',
          scene: true,
          correct: false,
          rejectBn: 'এলটি কেবিল এলোমেলো ঝুলিয়ে রাখা সাধারণ ভুল — কেবিল টাই বা ক্ল্যাম্পে সাজিয়ে দিন।',
        ),
        LearnBoardOption(
          id: 'strain',
          labelBn: 'বুশিং থেকে টান টান করে টানা কেবিল',
          asset: 'assets/game/art/m4_board47/cable_strain.svg',
          scene: true,
          correct: false,
          rejectBn: 'কেবিলের ওপর অপ্রয়োজনীয় চাপ বা টান যেন না পড়ে — তাতেই কেবিলের আয়ু বাড়ে।',
        ),
        LearnBoardOption(
          id: 'near',
          labelBn: 'HT-র কাছ দিয়ে ঘুরিয়ে আনা কেবিল',
          asset: 'assets/game/art/m4_board47/cable_near.svg',
          scene: true,
          correct: false,
          rejectBn: 'HT আর LT-র মাঝে সবসময় নির্ধারিত নিরাপদ দূরত্ব (ক্লিয়ারেন্স) রাখতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'এলটি কেবিল গুছিয়ে বেঁধে (বাঞ্চিং) নামাতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কেবিল টাই বা ক্ল্যাম্পে কেবিল সাজিয়ে রাখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'HT আর LT-র মাঝে নিরাপদ দূরত্ব রাখা চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কেবিল ঝুলে থাকলেও বিদ্যুৎ ঠিকই যাবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টান টান কেবিলেই সবচেয়ে বেশি আয়ু হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'এলটি কেবিল HT-র পাশ দিয়ে নিলেও চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কেবিল বাঁধা শুধু দেখনদারির কাজ মাত্র', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ইনসুলেটেড কেবিল যেখানে খুশি ঝোলানো যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'কেবিল টাই লাগালে ফল্ট খোঁজা কঠিন হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'gap',
      promptBn: 'বাঁধাই আর জাম্পারের কাজ শেষ — ক্লিয়ারেন্স নিয়ে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'trim',
          labelBn: 'বাইন্ডিং তারের বাড়তি লেজ কাটা',
          asset: 'assets/game/art/m4_board47/gap_trim.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'look',
          labelBn: 'দূর থেকে দেখে ক্লিয়ারেন্স যাচাই',
          asset: 'assets/game/art/m4_board47/gap_look.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tail',
          labelBn: 'বাইন্ডিং তারের লম্বা লেজ রেখে দেওয়া',
          asset: 'assets/game/art/m4_board47/gap_tail.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাইন্ডিং তারের বাড়তি লেজ কেটে ফেলুন — বাতাসে উড়ে ওটাই অন্য তার ছুঁয়ে শর্ট করায়।',
        ),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'দুটো ইনসুলেটেড কেবিল ঘষা খাচ্ছে',
          asset: 'assets/game/art/m4_board47/gap_touch.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্রমাগত ঘষায় বা আবহাওয়ায় ইনসুলেশন নষ্ট হয়ে শর্ট সার্কিট হয় — ক্লিয়ারেন্স বাধ্যতামূলক।',
        ),
        LearnBoardOption(
          id: 'body',
          labelBn: 'পোলের গা ঘেঁষে থাকা জাম্পার',
          asset: 'assets/game/art/m4_board47/gap_body.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইভ অংশ আর পোলের কাঠামোর মাঝে নির্ধারিত নিরাপদ দূরত্ব রাখা আইনত বাধ্যতামূলক।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বাইন্ডিং তারের বাড়তি লেজ বাতাসে উড়ে শর্ট করায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বারবার দূর থেকে দেখে ক্লিয়ারেন্স পরীক্ষা করুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফেজ-টু-ফেজ ও বডির মাঝে ক্লিয়ারেন্স বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ইনসুলেটেড তার ছুঁয়ে থাকলে কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাইন্ডিং তারের লেজ রেখে দিলে বাঁধন মজবুত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পোলের কাছে জাম্পার থাকলে তেমন কোনো বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাছ থেকে একবার দেখলেই ক্লিয়ারেন্স বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাতাসে তার নড়লেও দূরত্বের কোনো বদল হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ক্লিয়ারেন্স শুধু বড় সাবস্টেশনেই দরকার হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'finish',
      promptBn: 'ড্রেসিং প্রায় শেষ — কাজ গুটিয়ে নেওয়ার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'tight',
          labelBn: 'প্রতিটি নাট-বল্টু ঠিকভাবে টাইট দেওয়া',
          asset: 'assets/game/art/m4_board47/finish_tight.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'photo',
          labelBn: 'পরিপাটি কাজের ছবি তুলে রাখা',
          asset: 'assets/game/art/m4_board47/finish_photo.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'বাঁক সাজাতে গিয়ে নাট ঢিলা রাখা',
          asset: 'assets/game/art/m4_board47/finish_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'সৌন্দর্যে মন দিতে গিয়ে কানেকশন টাইট দিতে ভোলা চলবে না — প্রতিটি নাট-বল্টু টাইট করুন।',
        ),
        LearnBoardOption(
          id: 'cram',
          labelBn: 'ক্রস-আর্মে একটুও জায়গা ফাঁকা না রাখা',
          asset: 'assets/game/art/m4_board47/finish_cram.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভবিষ্যতের রক্ষণাবেক্ষণ বা নতুন সংযোগের জন্য স্ট্রাকচারে জায়গা ফাঁকা রাখুন।',
        ),
        LearnBoardOption(
          id: 'bottom',
          labelBn: 'ওপরে জট রেখে নিচ থেকে শুরু',
          asset: 'assets/game/art/m4_board47/finish_bottom.svg',
          scene: true,
          correct: false,
          rejectBn: 'ড্রেসিং শুরু করুন ওপর থেকে — আগে HT অংশ, তারপর নিচের LT সাইড।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রতিটি নাট-বল্টু আর কানেক্টর টাইট করা জরুরি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভালো কাজের ছবি নিজের কাজের রেকর্ড হয়ে থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নতুন সংযোগের জন্য স্ট্রাকচারে জায়গা রাখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দেখতে সুন্দর হলে কানেকশন ঢিলা থাকলেও চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ক্রস-আর্মের প্রতিটি জায়গা ভরাট করাই নিয়ম', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নিচের এলটি থেকে শুরু করাই সবচেয়ে ভালো অভ্যাস', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাজের ছবি তোলা মানে শুধু সময় নষ্ট করা', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নাট-বল্টু পরে কেউ এসে টাইট দিয়ে দেবে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ভবিষ্যতের সংযোগের কথা এখন ভাবার দরকার নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board47Lines.rivalTaunt,
    rivalLineBn: M4Board47Lines.rivalMyth,
    exitBn: M4Board47Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'জট পাকানো জাম্পার',
      'এলোমেলো ঝোলা কেবিল',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'খারাপ ড্রেসিং থেকেই শর্ট সার্কিট আর ফল্ট তৈরি হয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'পরিপাটি স্ট্রাকচারে ফল্ট খোঁজা আর মেরামত সহজ হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ঠিক ড্রেসিং সুরক্ষার একটা অপরিহার্য অংশ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'লাইন চললে ড্রেসিং কেমন, তাতে কিছু যায় আসে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ড্রেসিং শুধু অফিসারকে দেখানোর জন্যই করা হয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অগোছালো তারে নির্ভরযোগ্যতার কোনো তফাত হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'জট পাকানো জাম্পারেও লাইন বছরের পর বছর চলে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'রক্ষণাবেক্ষণ সহজ হোক বা কঠিন, কোনো তফাত নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ড্রেসিংয়ে সময় দেওয়া মানে সময় নষ্ট করা', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board47Lines {
  static const rivalTaunt = 'আরে, এত সাজিয়ে-গুছিয়ে কী হবে? তার জুড়ে দিলেই তো কাজ শেষ!';

  /// Lesson 4.7's first myth buster, word for word.
  static const rivalMyth = 'ড্রেসিং তো শুধু দেখানোর জন্য, লাইন চললেই হলো।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
