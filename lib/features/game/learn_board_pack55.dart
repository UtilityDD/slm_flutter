import 'learn_board_models.dart';

/// Module 5 Lesson 5.5 ('লো-ভোল্টেজ' সমস্যার সমাধান), the picture board
/// (rung `5.5/learn`, pack `learn_5_5`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board55_art.py` (meter
/// readings drawn as seven-segment English digits). Every round and every
/// trap comes from the lesson text (item spec
/// `docs/module_specs/module5_items/board_55.json`, Module 5 rulings):
///  * call: the first question narrows the search — one customer or many?
///    One house → the service connection or the inside wiring; the whole
///    area → the transformer or the LT network. The company keeps a set
///    voltage (myth 1);
///  * house (one house): first measure at the meter's incoming terminals,
///    always with the load on — with no load the voltage can read right
///    (pro tip 1);
///  * joint (the meter's incoming is low too): check and tighten every joint
///    of the service connection, at the pole and at the meter; a thermal
///    camera finds the hot joint (pro tip 3); a service cable too thin for
///    the load raises the drop (a new AC — pro tip 4). Supply off for the
///    tightening comes from the Module 3/4 rulings;
///  * neutral: beside phase-neutral, measure neutral-earth; more than about
///    5-10 V points to a neutral problem (pro tip 2); a weak or cut neutral
///    also gives low voltage;
///  * area (the whole neighbourhood, evening): the transformer first — the
///    voltage at the LTDB incoming (ruling M5-15c: the bushing's own cable,
///    no climb on a live DTR), the load against the nameplate (overloading
///    at peak load), the off-load tap position with the DTR switched off.
///    The area prompt asks where and how to look (not what comes "first"),
///    since the lesson checks load and tap only once the LT side reads low.
/// Hands on a DTR or a service joint are drawn only once it is proven dead
/// (ruling M5-2): drop-outs hanging open, earth set on and the meter reading
/// 0 on area_tap; cut-out pulled and the meter reading 0 on joint_pole and
/// joint_meter. The live-DTR trap (area_live) keeps the closed drop-outs,
/// lit windows and the unused earth set on the ground.
/// The rival's myth is the lesson's second myth, word for word. The danger
/// tags name the harm without repeating the right reason chips.
const learnBoardPack55 = LearnBoardPack(
  lessonId: '5.5',
  titleBn: "'লো-ভোল্টেজ' সমস্যার সমাধান",
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'বিদ্যুৎ আছে, কিন্তু টিমটিমে। দক্ষ ডাক্তারের মতো দুর্বল বিদ্যুতের কারণ খুঁজে বের করুন।',
  earnedBn: 'আগে প্রশ্ন — একজনের না অনেকের; একজনের হলে লোডে মিটারে মাপুন ও নিউট্রাল-আর্থ দেখুন, পুরো পাড়ার হলে আগে ট্রান্সফরমার।',
  slots: [
    LearnBoardSlot(
      id: 'call',
      promptBn: 'লো-ভোল্টেজের ফোন এল। প্রথমে কোন কাজটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'ask',
          labelBn: 'পাশের বাড়িতেও কম কিনা জিজ্ঞেস করা',
          asset: 'assets/game/art/m5_board55/call_ask.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sketch',
          labelBn: 'কোন কোন বাড়িতে কম — রাস্তার নকশায় দাগ',
          asset: 'assets/game/art/m5_board55/call_sketch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'কিছু না জেনেই পোলে উঠে সব জয়েন্ট টাইট',
          asset: 'assets/game/art/m5_board55/call_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে জানুন: সমস্যা একজনের, না অনেকের? এই প্রশ্নই তদন্তের এলাকা ছোট করে দেয়।',
        ),
        LearnBoardOption(
          id: 'blame',
          labelBn: 'গ্রাহককে বলা: কোম্পানি কম বিদ্যুৎ পাঠাচ্ছে',
          asset: 'assets/game/art/m5_board55/call_blame.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল। কোম্পানি নির্দিষ্ট ভোল্টেজ লেভেল বজায় রাখে; কারণ সাধারণত স্থানীয় নেটওয়ার্ক বা সার্ভিস কানেকশন।',
        ),
        LearnBoardOption(
          id: 'tap',
          labelBn: 'একটা বাড়িতেই কম, তবু ট্রান্সফরমারের ট্যাপে',
          asset: 'assets/game/art/m5_board55/call_tap.svg',
          scene: true,
          correct: false,
          rejectBn: 'শুধু একজনের সমস্যা হলে কারণ সম্ভবত তার সার্ভিস কানেকশন বা বাড়ির ভেতরের ওয়্যারিং।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে জানুন সমস্যা একজনের, না পুরো এলাকার', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'একজনের হলে সার্ভিস কানেকশন বা ঘরের ওয়্যারিং', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পুরো এলাকার হলে ট্রান্সফরমার বা এলটি নেটওয়ার্ক', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আগে সব জয়েন্ট টাইট দিলেই সমস্যা মিটে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লো-ভোল্টেজ মানে কোম্পানি কম বিদ্যুৎ পাঠাচ্ছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেকোনো লো-ভোল্টেজে আগে ট্যাপ বদলাতে হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'প্রতিবেশীকে জিজ্ঞেস করা মানে সময় নষ্ট', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অভিযোগ এলেই আগে পোলে ওঠা সবচেয়ে জরুরি', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'একটা বাড়ির সমস্যা মানেই পুরো লাইনের দোষ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'house',
      promptBn: 'শুধু এই বাড়িতেই ভোল্টেজ কম। কোথায়, কীভাবে মাপবেন?',
      options: [
        LearnBoardOption(
          id: 'incoming',
          labelBn: 'মিটারের ইনকামিং টার্মিনালে প্রোব',
          asset: 'assets/game/art/m5_board55/house_incoming.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pump',
          labelBn: 'পাম্প চালু রেখে, লোডে ভোল্টেজ মাপা',
          asset: 'assets/game/art/m5_board55/house_pump.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'off',
          labelBn: 'সব সুইচ বন্ধ করে মাপা — রিডিং ঠিক',
          asset: 'assets/game/art/m5_board55/house_off.svg',
          scene: true,
          correct: false,
          rejectBn: 'লোড ছাড়া ভোল্টেজ ঠিকই দেখাতে পারে। সবসময় লোড থাকা অবস্থায় মাপুন।',
        ),
        LearnBoardOption(
          id: 'dtr',
          labelBn: 'একটা বাড়ির জন্য ট্রান্সফরমারে মাপা',
          asset: 'assets/game/art/m5_board55/house_dtr.svg',
          scene: true,
          correct: false,
          rejectBn: 'একজনের সমস্যা: প্রথমে গ্রাহকের মিটারের ইনকামিং টার্মিনালে ভোল্টেজ মাপুন।',
        ),
        LearnBoardOption(
          id: 'socket',
          labelBn: 'ঘরের প্লাগ পয়েন্টে মেপেই সিদ্ধান্ত',
          asset: 'assets/game/art/m5_board55/house_socket.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে মিটারের ইনকামিং-এ মাপুন: সেখানে ঠিক থাকলে সমস্যা বাড়ির ভেতরে, কম থাকলে সার্ভিস কানেকশনে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রথমে মিটারের ইনকামিং টার্মিনালে মাপুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সবসময় লোড থাকা অবস্থায় ভোল্টেজ মাপুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লোড ছাড়া মাপলে ভোল্টেজ ঠিকই দেখাতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সব সুইচ বন্ধ রাখলে রিডিং সবচেয়ে সঠিক আসে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটা বাড়ির জন্যও আগে ট্রান্সফরমারে মাপুন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ঘরের যেকোনো প্লাগে মাপলেই কারণ বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ভারী লোড চললে মিটারের রিডিং ভুল আসে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মিটারের টার্মিনালে মাপার কোনো মানে নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লোড থাক বা না থাক, রিডিং একই আসে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'joint',
      promptBn: 'মিটারের ইনকামিং-এও ভোল্টেজ কম। এবার কোন কাজ?',
      options: [
        LearnBoardOption(
          id: 'pole',
          labelBn: 'সাপ্লাই বন্ধ করে পোলের জয়েন্ট টাইট',
          asset: 'assets/game/art/m5_board55/joint_pole.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'meter',
          labelBn: 'সাপ্লাই বন্ধ করে মিটারের টার্মিনাল টাইট',
          asset: 'assets/game/art/m5_board55/joint_meter.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'thermal',
          labelBn: 'থার্মাল ক্যামেরায় জয়েন্টগুলো স্ক্যান',
          asset: 'assets/game/art/m5_board55/joint_thermal.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'onlyhot',
          labelBn: 'একটা জয়েন্ট টাইট দিয়েই কাজ শেষ',
          asset: 'assets/game/art/m5_board55/joint_onlyhot.svg',
          scene: true,
          correct: false,
          rejectBn: 'সার্ভিস কানেকশনের প্রতিটি জয়েন্ট, পোলে এবং মিটারে, পরীক্ষা করে টাইট দিন।',
        ),
        LearnBoardOption(
          id: 'inside',
          labelBn: 'বাড়ির ভেতরের ওয়্যারিং খুলে বসা',
          asset: 'assets/game/art/m5_board55/joint_inside.svg',
          scene: true,
          correct: false,
          rejectBn: 'মিটারেও ভোল্টেজ কম মানে সমস্যা বাড়ির ভেতরে নয় — সার্ভিস কানেকশন দেখুন।',
        ),
        LearnBoardOption(
          id: 'thin',
          labelBn: 'নতুন এসি-র লোডে সরু কেবিল যেমন আছে',
          asset: 'assets/game/art/m5_board55/joint_thin.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রাহকের লোড অনুযায়ী সার্ভিস কেবিল খুব সরু হলে ভোল্টেজ ড্রপ বেড়ে যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লুজ কানেকশনই লো-ভোল্টেজের সবচেয়ে সাধারণ কারণ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পোলে আর মিটারে, প্রতিটি জয়েন্ট দেখে টাইট দিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'থার্মাল ক্যামেরায় লুজ জয়েন্টের হটস্পট ধরা পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লোডের তুলনায় সরু সার্ভিস কেবিলে ড্রপ বাড়ে', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'মিটারে কম মানে বাড়ির ভেতরের ওয়্যারিং খারাপ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'একটা জয়েন্ট টাইট দিলেই বাকিগুলো ঠিক থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লোড বাড়লেও সার্ভিস কেবিলের সাইজে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গরম জয়েন্ট মানে কারেন্ট ভালোভাবে চলছে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হটস্পট শুধু পুরনো লাইনে হয়, নতুনে কখনো না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'neutral',
      promptBn: 'ফেজ-নিউট্রাল মাপা হলো। নিউট্রাল নিয়ে এবার কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'ne',
          labelBn: 'নিউট্রাল আর আর্থের মধ্যে প্রোব',
          asset: 'assets/game/art/m5_board55/neutral_ne.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'note',
          labelBn: 'নিউট্রাল-আর্থে বেশি ভোল্ট — ডকেটে লেখা',
          asset: 'assets/game/art/m5_board55/neutral_note.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shrug',
          labelBn: 'নিউট্রাল-আর্থে 18 ভোল্ট, তবু পাত্তা নেই',
          asset: 'assets/game/art/m5_board55/neutral_shrug.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিউট্রাল-আর্থে 5-10 ভোল্টের বেশি মানে নিউট্রাল লাইনে সমস্যার ইঙ্গিত।',
        ),
        LearnBoardOption(
          id: 'pn',
          labelBn: 'শুধু ফেজ-নিউট্রাল মেপেই কাজ শেষ',
          asset: 'assets/game/art/m5_board55/neutral_pn.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফেজ-টু-নিউট্রালের পাশাপাশি নিউট্রাল আর আর্থের মধ্যেও ভোল্টেজ মাপুন।',
        ),
        LearnBoardOption(
          id: 'weak',
          labelBn: 'ক্ষয়ে যাওয়া নিউট্রাল রেখে শুধু ফেজ টাইট',
          asset: 'assets/game/art/m5_board55/neutral_weak.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুর্বল বা কাটা নিউট্রাল কানেকশনও লো-ভোল্টেজের কারণ হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিউট্রাল আর আর্থের মধ্যেও ভোল্টেজ মাপতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: '5-10 ভোল্টের বেশি মানে নিউট্রালে সমস্যা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দুর্বল বা কাটা নিউট্রালেও লো-ভোল্টেজ হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নিউট্রালে কখনো ভোল্টেজ থাকে না, মাপা বৃথা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফেজ-নিউট্রাল ঠিক থাকলেই সব ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নিউট্রাল-আর্থে যত ভোল্টই থাক, সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লুজ কানেকশন শুধু ফেজের জয়েন্টেই হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নিউট্রাল ক্ষয়ে গেলেও ভোল্টেজ ঠিকই থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আর্থের তার মাপার কাজে কখনো লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'area',
      promptBn: 'সন্ধ্যায় পুরো পাড়ায় ভোল্টেজ কম। খোঁজ কোথায়, কীভাবে?',
      options: [
        LearnBoardOption(
          id: 'ltdb',
          labelBn: 'ট্রান্সফরমারের এলটিডিবি-র ইনকামিং-এ মাপা',
          asset: 'assets/game/art/m5_board55/area_ltdb.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clamp',
          labelBn: 'ক্ল্যাম্প মিটারে লোড, নেমপ্লেটের সাথে মেলানো',
          asset: 'assets/game/art/m5_board55/area_clamp.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tap',
          labelBn: 'ট্রান্সফরমার বন্ধ করে ট্যাপ পজিশন দেখা',
          asset: 'assets/game/art/m5_board55/area_tap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'houses',
          labelBn: 'বাড়ি বাড়ি ঘুরে জয়েন্ট টাইট দেওয়া',
          asset: 'assets/game/art/m5_board55/area_houses.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরো এলাকার সমস্যা হলে কারণ সম্ভবত ট্রান্সফরমার বা এলটি নেটওয়ার্কে।',
        ),
        LearnBoardOption(
          id: 'evening',
          labelBn: '"সন্ধ্যায় তো একটু কম হবেই" বলে বসে থাকা',
          asset: 'assets/game/art/m5_board55/area_evening.svg',
          scene: true,
          correct: false,
          rejectBn: 'পিক-লোডে, যেমন সন্ধ্যায়, ওভারলোডেড ট্রান্সফরমারের আউটপুট ভোল্টেজ কমে যায় — পরীক্ষা করুন।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'চালু ট্রান্সফরমারে ট্যাপ চেঞ্জারে হাত',
          asset: 'assets/game/art/m5_board55/area_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'এটা অফ-লোড ট্যাপ চেঞ্জার: ট্রান্সফরমার বন্ধ করে তবেই হাত দিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পুরো এলাকায় কম: আগে ট্রান্সফরমার ও এলটি লাইন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্ষমতার বেশি লোডে ট্রান্সফরমারের ভোল্টেজ কমে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অফ-লোড ট্যাপ চেঞ্জারে হাত শুধু বন্ধ অবস্থায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সন্ধ্যায় ভোল্টেজ কম স্বাভাবিক, দেখার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পাড়াজুড়ে কম হলে আগে বাড়ির জয়েন্ট দেখুন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চালু অবস্থায় ট্যাপ ঘোরালে সময় বাঁচে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ট্রান্সফরমারে কখনো ওভারলোড হয় না, চিন্তা নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'এক ফেজে বেশি লোড থাকলেও কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নেমপ্লেটের রেটিং দেখার কোনো দরকার নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board55Lines.rivalTaunt,
    rivalLineBn: M5Board55Lines.rivalMyth,
    exitBn: M5Board55Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'লুকানো ক্ষতি',
      'মোটর-কম্প্রেসর ঝুঁকিতে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'লো-ভোল্টেজে মোটর বেশি কারেন্ট টেনে চলে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'বেশি কারেন্টে ওয়াইন্ডিং অতিরিক্ত গরম হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'মোটর-কম্প্রেসরের আয়ু মারাত্মক কমে যায়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'যন্ত্র চলছে মানেই ভোল্টেজ যথেষ্ট আছে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'কম ভোল্টে মোটর কম কারেন্টে ঠান্ডা চলে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'লো-ভোল্টেজে বিল কমে, তাই এটাই ভালো', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'কম্প্রেসর কম ভোল্টেও পুরো আয়ু পায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'একটু কম ভোল্টে কোনো যন্ত্রের ক্ষতি নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ওয়াইন্ডিং গরম হওয়া খুবই সাধারণ ব্যাপার', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py`.
abstract final class M5Board55Lines {
  static const rivalTaunt = 'আরে, বাতি তো জ্বলছে, পাখাও ঘুরছে! এত মাপামাপি কেন?';

  /// Lesson 5.5's second myth, word for word.
  static const rivalMyth = 'একটু লো-ভোল্টেজ হলে কিছু হয় না, যন্ত্রপাতি তো চলছেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
