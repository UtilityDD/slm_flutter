import 'learn_board_models.dart';

/// Module 4 Lesson 4.3 (নতুন সার্ভিস কানেকশন দেওয়া), the picture board
/// (rung `4.3/learn`, pack `learn_4_3`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board43_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * plan: the approved connection order, meter details, permits and the
///    right materials first; survey the straightest, safest route from the
///    pole to the meter — not over a tree, another house or an obstacle; over
///    a road the cable keeps its lawful ground clearance (no figure given);
///  * anchor: a rack bolt / eye hook firmly on the house wall, an anchor clamp
///    on the pole below the LT line; the GI supporting wire is pulled first
///    to the right tension — it carries all the pull; a weak anchor lets the
///    line sag or snap (in a storm, a big accident);
///  * ipc: the pole joint is an insulation piercing connector — no stripping,
///    its teeth pierce the insulation; tighten the nut until the shear head
///    breaks off by itself (the right torque); a stripped-and-twisted joint
///    is not waterproof, corrodes, works loose and makes a hotspot (myth 2);
///  * meter: the cable is strapped to the GI wire neatly at even spacing;
///    into the meter's incoming terminal through a water-stopping drip loop;
///    phase and neutral marked and on their right terminals;
///  * test: all joints checked tight; with the pole fuse in, a multimeter on
///    the meter's incoming terminal reads 230-240 V (single phase); then the
///    customer is shown the meter and main switch; scraps cleared away.
/// No worker is drawn on the pole (close-ups of the hardware only).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack43 = LearnBoardPack(
  lessonId: '4.3',
  titleBn: 'নতুন সার্ভিস কানেকশন দেওয়া',
  badgeBn: 'কাজের কারিগর',
  introBn: 'পোল থেকে মিটার — নতুন সার্ভিস কানেকশন দায়সারা কাজ নয়, নিয়ম মেনে পেশাদার কাজ।',
  earnedBn: 'আগে GI সাপোর্টিং তার, পোলে IPC, মিটারে ড্রিপ লুপ — শেষে 230-240V মেপে তবে চালু।',
  slots: [
    LearnBoardSlot(
      id: 'plan',
      promptBn: 'নতুন কানেকশনের অর্ডার এসেছে — কাজ শুরুর আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'order',
          labelBn: 'অর্ডার, কাগজপত্র আর মালামাল মিলিয়ে নেওয়া',
          asset: 'assets/game/art/m4_board43/plan_order.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'survey',
          labelBn: 'পোল থেকে মিটার সোজা, নিরাপদ রুট জরিপ',
          asset: 'assets/game/art/m4_board43/plan_survey.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tree',
          labelBn: 'গাছের ওপর দিয়ে কেবিলের রুট',
          asset: 'assets/game/art/m4_board43/plan_tree.svg',
          scene: true,
          correct: false,
          rejectBn: 'রুট এমন হবে যাতে কেবিল কোনো গাছ, অন্য বাড়ি বা বাধার ওপর দিয়ে না যায়।',
        ),
        LearnBoardOption(
          id: 'roof',
          labelBn: 'পাশের বাড়ির ছাদের ওপর দিয়ে রুট',
          asset: 'assets/game/art/m4_board43/plan_roof.svg',
          scene: true,
          correct: false,
          rejectBn: 'অন্য বাড়ির ওপর দিয়ে কেবিল নয় — পোল থেকে মিটার সবচেয়ে সোজা ও নিরাপদ রাস্তা বেছে নিন।',
        ),
        LearnBoardOption(
          id: 'road',
          labelBn: 'রাস্তার ওপর নিচু হয়ে ঝোলা কেবিল',
          asset: 'assets/game/art/m4_board43/plan_road.svg',
          scene: true,
          correct: false,
          rejectBn: 'কেবিল রাস্তা পার হলে মাটি থেকে তার উচ্চতা (ক্লিয়ারেন্স) আইন অনুযায়ী ঠিক রাখতেই হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সঠিক পরিকল্পনায় কাজ দ্রুত, সহজ আর নিরাপদ হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হাতে চাই অনুমোদিত কানেকশন অর্ডার ও অনুমতিপত্র', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কেবিল যাবে না গাছ, অন্য বাড়ি বা বাধার ওপর দিয়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রুট যত ঘুরপথে, কেবিল তত বেশি নিরাপদ থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মালামাল কাজের মাঝপথে এসে জোগাড় করলেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রাস্তার ওপর কেবিল যত নিচু, ততই সুবিধা', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অর্ডার ছাড়াই আগে কানেকশন, পরে কাগজপত্র', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গাছের ডালে কেবিল ঠেকিয়ে রাখলে ভার কমে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পাশের বাড়ির ছাদ দিয়ে টানলে কেবিল বাঁচে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'anchor',
      promptBn: 'সার্ভিস লাইনের সব টান কে নেবে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'rack',
          labelBn: 'বাড়ির দেওয়ালে মজবুত র‍্যাক বোল্ট',
          asset: 'assets/game/art/m4_board43/anchor_rack.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clamp',
          labelBn: 'পোলে LT লাইনের নিচে অ্যাঙ্কর ক্ল্যাম্প',
          asset: 'assets/game/art/m4_board43/anchor_clamp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nowire',
          labelBn: 'GI তার ছাড়াই শুধু কেবিল টানা',
          asset: 'assets/game/art/m4_board43/anchor_nowire.svg',
          scene: true,
          correct: false,
          rejectBn: 'কেবিলের কন্ডাক্টর নিজের ওজন আর বাতাসের চাপ সইতে পারে না — সাপোর্টিং তার ছাড়া ঝুলে পড়বে বা ছিঁড়ে যাবে।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'দেওয়াল থেকে খুলে আসা আলগা হুক',
          asset: 'assets/game/art/m4_board43/anchor_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'অ্যাঙ্কর দুর্বল হলে পুরো সার্ভিস লাইন ঝুলে পড়ে বা ছিঁড়ে যায় — ঝড়ে বড় দুর্ঘটনা।',
        ),
        LearnBoardOption(
          id: 'slack',
          labelBn: 'ঢিলে হয়ে ঝুলে থাকা GI তার',
          asset: 'assets/game/art/m4_board43/anchor_slack.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে GI সাপোর্টিং তার টেনে সঠিক টেনশনে আনুন — কেবিলের সমস্ত টান এই বিয়ারার তার নেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কেবিলের সমস্ত টান নেয় GI সাপোর্টিং তার', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আগে বাড়ি থেকে পোল পর্যন্ত GI তার টানটান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দুর্বল অ্যাঙ্করে ঝড়ে কেবিল ছিঁড়ে পড়তে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সার্ভিস কেবিল নিজেই নিজের ভার সইতে পারে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'র‍্যাক বোল্ট একটু আলগা থাকলে টান কম পড়ে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'GI তার ঢিলে রাখলে কেবিল বেশি দিন টেকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অ্যাঙ্কর ক্ল্যাম্প বসে LT লাইনের ঠিক ওপরে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কেবিল আগে টেনে পরে GI তার দিলেও চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঝড়-বাতাসে সার্ভিস কেবিলের কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ipc',
      promptBn: 'পোলে LT লাইনের সাথে সার্ভিস কেবিল জুড়বেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'fit',
          labelBn: 'ইনসুলেশন না ছিলে IPC কানেক্টরে জোড়',
          asset: 'assets/game/art/m4_board43/ipc_fit.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shear',
          labelBn: 'শেয়ার হেড নিজে ভেঙে পড়া পর্যন্ত টাইট',
          asset: 'assets/game/art/m4_board43/ipc_shear.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'head',
          labelBn: 'শেয়ার হেড না ভাঙতেই টাইট দেওয়া শেষ',
          asset: 'assets/game/art/m4_board43/ipc_head.svg',
          scene: true,
          correct: false,
          rejectBn: 'নাট ততক্ষণ টাইট দিন যতক্ষণ না শেয়ার হেড নিজে থেকে ভেঙে পড়ে — তবেই সঠিক টর্ক নিশ্চিত।',
        ),
        LearnBoardOption(
          id: 'twist',
          labelBn: 'ইনসুলেশন ছিলে তার পেঁচিয়ে জোড়',
          asset: 'assets/game/art/m4_board43/ipc_twist.svg',
          scene: true,
          correct: false,
          rejectBn: 'পেঁচানো জোড় জলরোধী নয় — করোশন হয়, কয়েকদিনেই লুজ হয়ে হটস্পট তৈরি করে।',
        ),
        LearnBoardOption(
          id: 'burn',
          labelBn: 'লুজ পেঁচানো জোড়ে হটস্পট, পোড়া দাগ',
          asset: 'assets/game/art/m4_board43/ipc_burn.svg',
          scene: true,
          correct: false,
          rejectBn: 'IPC ছাড়া তার পেঁচিয়ে জোড় দিলে লুজ হয়ে পুড়ে যায়, দুর্ঘটনা ঘটে — পোলে জোড় মানেই IPC।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'IPC-র ধারালো দাঁত নিজেই ইনসুলেশন ভেদ করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শেয়ার হেড ভাঙা মানে সঠিক টর্ক দেওয়া হয়েছে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'IPC-র রাবারের সিল জোড়টাকে জলরোধী রাখে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'IPC লাগাতে আগে LT লাইনের ইনসুলেশন ছিলুন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শেয়ার হেড অক্ষত থাকলেই জোড় বেশি মজবুত', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পেঁচানো জোড় বৃষ্টিতেও জলরোধী থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হটস্পট হলে জোড় আরও শক্ত হয়ে বসে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তাড়াহুড়োয় নাট অর্ধেক টাইট দিলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'খোলা তামার জোড়ে করোশন কখনো হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'meter',
      promptBn: 'কেবিল এবার গ্রাহকের বাড়ির মিটারে পৌঁছাবে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'strap',
          labelBn: 'GI তারে সমান দূরত্বে স্ট্র্যাপে বাঁধা',
          asset: 'assets/game/art/m4_board43/meter_strap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'drip',
          labelBn: 'ড্রিপ লুপ করে মিটারের ইনকামিং-এ',
          asset: 'assets/game/art/m4_board43/meter_drip.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nodrip',
          labelBn: 'ওপর থেকে সোজা মিটারে ঢোকানো কেবিল',
          asset: 'assets/game/art/m4_board43/meter_nodrip.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটারের মুখে জল আটকানো ড্রিপ লুপ চাই — না হলে কেবিল বেয়ে জল মিটারে ঢোকে।',
        ),
        LearnBoardOption(
          id: 'swap',
          labelBn: 'ফেজ আর নিউট্রাল উল্টো টার্মিনালে',
          asset: 'assets/game/art/m4_board43/meter_swap.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফেজ ও নিউট্রাল তার চিহ্নিত করে সঠিক টার্মিনালে লাগান — ভুল সংযোগ বিপদ ঘটাতে পারে।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'দু-এক জায়গায় বেঁধে ঝুলে থাকা কেবিল',
          asset: 'assets/game/art/m4_board43/meter_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'সার্ভিস কেবিল GI তারের সাথে সুন্দরভাবে, সমান দূরত্বে স্ট্র্যাপ বা বাইন্ডিং তারে বাঁধুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কেবিল GI তারে সমান দূরত্বে বাঁধা থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ড্রিপ লুপ মিটারের মুখে বৃষ্টির জল আটকায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফেজ ও নিউট্রাল চিহ্নিত করে সঠিক টার্মিনালে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কেবিল সোজা ওপর থেকে মিটারে ঢোকানোই ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফেজ-নিউট্রাল যেকোনো টার্মিনালে লাগালেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দুই মাথায় দুটো স্ট্র্যাপই যথেষ্ট, মাঝে নয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ড্রিপ লুপ শুধু দেখতে সুন্দর, কাজের নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তাড়াহুড়োয় কাজ সারলে ভুলের ভয় কম থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বৃষ্টির জল মিটারে ঢুকলেও কোনো ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'test',
      promptBn: 'সব জোড়া শেষ — লাইন চালুর আগে আর পরে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'measure',
          labelBn: 'ইনকামিং টার্মিনালে মাল্টিমিটারে 230V মাপা',
          asset: 'assets/game/art/m4_board43/test_measure.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'explain',
          labelBn: 'সব ঠিক হলে গ্রাহককে মিটার-সুইচ বোঝানো',
          asset: 'assets/game/art/m4_board43/test_explain.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'skip',
          labelBn: 'না মেপেই গ্রাহকের মেইন সুইচ চালু',
          asset: 'assets/game/art/m4_board43/test_skip.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলের ফিউজ লাগিয়ে আগে মিটারের ইনকামিং টার্মিনালে মাপুন — সিঙ্গেল-ফেজে 230-240 ভোল্ট আসা চাই।',
        ),
        LearnBoardOption(
          id: 'litter',
          labelBn: 'কেবিলের টুকরো, প্যাকেট ফেলে চলে যাওয়া',
          asset: 'assets/game/art/m4_board43/test_litter.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শেষে কেবিলের টুকরো, প্যাকেট আর আবর্জনা পরিষ্কার করুন — পরিচ্ছন্ন কাজেই পেশাদারিত্ব।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'টার্মিনাল টাইট না দেখেই চলে যাওয়া',
          asset: 'assets/game/art/m4_board43/test_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে আর মিটারে সব কানেকশন টাইট আছে কিনা পরীক্ষা করুন, কেবিল ঠিক ঝুলছে কিনা দেখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সিঙ্গেল-ফেজে ইনকামিং-এ চাই 230-240 ভোল্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পোলে আর মিটারে সব কানেকশন টাইট কিনা দেখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাজ শেষে কেবিলের টুকরো পরিষ্কার করে যান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্রাহকের বাতি জ্বললেই আর মাপার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আলগা টার্মিনাল সময়ের সাথে নিজেই টাইট হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফেলে রাখা টুকরো পরের লাইনম্যান তুলে নেবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গ্রাহককে মিটার-সুইচ বোঝানো আমাদের কাজ নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সরু কেবিলে ভোল্টেজ ড্রপের কোনো ভয় নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মাল্টিমিটার ছাড়া চোখে দেখেই ভোল্ট বোঝা যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board43Lines.rivalTaunt,
    rivalLineBn: M4Board43Lines.rivalMyth,
    exitBn: M4Board43Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'সাপোর্টিং তার ছাড়া কেবিল',
      'ঝড়ে ঝুলে ছিঁড়ে পড়া তার',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'কেবিলের কন্ডাক্টর নিজের ওজন আর বাতাস সইতে পারে না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'সাপোর্টিং তার ছাড়া কয়েক মাসেই কেবিল ঝুলে পড়ে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সার্ভিস কেবিলের সমস্ত টান নেয় GI বিয়ারার তার', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'সার্ভিস কেবিল এত মজবুত যে আলাদা তার লাগে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ছোট দূরত্বে কেবিল নিজেই সব টান সয়ে নেয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'GI তার শুধু বাড়তি খরচ, কাজে কোনো লাগে না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ঝড়-বাতাসে ঝোলা কেবিল আরও শক্ত হয়ে বসে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'কেবিল ঝুলে পড়লে পরে টেনে দিলেই আবার ঠিক', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'অভিজ্ঞ লাইনম্যানের কাজে সাপোর্টিং তার লাগে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board43Lines {
  static const rivalTaunt = 'আরে, আবার আলাদা তার কেন? কেবিলটাই সোজা টেনে দাও!';

  /// Lesson 4.3's first myth buster, word for word.
  static const rivalMyth = 'সাপোর্টিং তার ছাড়াই সার্ভিস কেবিল টেনে দিলে চলে, ওটা যথেষ্ট মজবুত।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
