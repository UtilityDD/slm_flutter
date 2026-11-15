import 'learn_board_models.dart';

/// Module 6 Lesson 6.2 (সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা), the picture
/// board (rung `6.2/learn`, pack `learn_6_2`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board62_art.py` (no words in
/// the art: lamps, the spring flag and the position pointer are drawn; the
/// operation counter is seven-segment English digits). Every round and every
/// trap comes from the lesson text (item spec
/// `docs/module_specs/module6_items/board_62.json`, Module 6 rulings):
///  * reset: a breaker cuts the circuit on a fault and is reset afterwards;
///    a fuse is replaced; the relay is the brain, the breaker its muscle; an
///    isolator is off-load only (live myth 2 text, ruling X3) and an ordinary
///    switch cannot break a fault arc;
///  * vcb: VCB contacts in a vacuum chamber, the arc goes out at once
///    (modern, low maintenance); OCB contacts in oil, the arc boils the oil
///    into a gas bubble (old, more maintenance);
///  * lamp: red = ON, green = OFF (open / tripped); TRIP CIRCUIT HEALTHY and
///    SPRING CHARGED say nothing about ON/OFF. Five rounds, as the Module 5
///    boards (ruling M5-11): the spring round, which overlapped the lamp
///    round most, left the board (owner 2026-11-15);
///  * rack: hands-on work only with the trolley racked out (ISOLATED: power
///    and control both cut; both safe cards show the shut cubicle with its
///    lamps dark, one with the trolley's cover open); SERVICE = fully
///    connected; TEST = power cut but control still connected (ruling M6-5:
///    hands-on in TEST = slip);
///  * line: green only means the breaker is open — isolators open at both
///    ends, the line proved dead with a tester, then earthed (live pro tip 1,
///    ruling X1: the safe card puts the tester before the earth); back-feed
///    from another feeder and induced voltage (myth 1 reality). The worker
///    stands on the ground on a safe card and on two traps, and is up the
///    pole on a safe card and on two traps, so his pose never marks the
///    answer.
/// The rival says the lesson's first myth word for word. Boards have no
/// deadly freeze (kit design); the deadly-class traps (climbing on green,
/// hands-on in SERVICE) cost the pending ◆ and say their lesson text.
const learnBoardPack62 = LearnBoardPack(
  lessonId: '6.2',
  titleBn: 'সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা',
  badgeBn: 'যন্ত্র গুরু',
  // DRAFT wording — owner.
  introBn: 'ফিউজ যদি সৈনিক হয়, সার্কিট ব্রেকার প্রশিক্ষিত কমান্ডো। চলুন, ওর ভাষা বুঝি।',
  // DRAFT wording — owner.
  earnedBn: 'সবুজ মানেই নিরাপদ নয় — দুই প্রান্তে আইসোলেটর খুলে, টেস্টারে ডেড প্রমাণ, তারপর আর্থিং।',
  slots: [
    LearnBoardSlot(
      id: 'reset',
      promptBn: 'ফল্ট হলে সার্কিট কেটে দেয়, পরে আবার চালু করা যায় — কোনটা?',
      options: [
        LearnBoardOption(
          id: 'vcb',
          labelBn: 'ট্রলিতে বসানো VCB প্যানেল',
          asset: 'assets/game/art/m6_board62/reset_vcb.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ocb',
          labelBn: 'তেলের ট্যাঙ্কসহ OCB প্যানেল',
          asset: 'assets/game/art/m6_board62/reset_ocb.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'ক্যারিয়ারে উড়ে যাওয়া ফিউজ',
          asset: 'assets/game/art/m6_board62/reset_fuse.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজ একবার উড়ে গেলে বদলে ফেলতে হয় — ব্রেকারের মতো রিসেট হয় না।',
        ),
        LearnBoardOption(
          id: 'isolator',
          labelBn: 'ব্লেড খোলা একটা আইসোলেটর',
          asset: 'assets/game/art/m6_board62/reset_isolator.svg',
          scene: true,
          correct: false,
          rejectBn: 'আইসোলেটর শুধু লোড ছাড়া (OFF-লোড) খোলা-বন্ধের জন্য — ফল্ট কারেন্ট বাধা দিতে পারে না।',
        ),
        LearnBoardOption(
          id: 'relay',
          labelBn: 'শুধু রিলে বসানো প্যানেল',
          asset: 'assets/game/art/m6_board62/reset_relay.svg',
          scene: true,
          correct: false,
          rejectBn: 'রিলে হলো মস্তিষ্ক, নির্দেশ দেয় — সার্কিট কাটে ব্রেকার, তার পেশী।',
        ),
        LearnBoardOption(
          id: 'switch',
          labelBn: 'দেওয়ালে বসানো সাধারণ সুইচ',
          asset: 'assets/game/art/m6_board62/reset_switch.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ সুইচ ফল্টের প্রচণ্ড আর্ক আর ফল্ট কারেন্ট সামলাতে তৈরি নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ট্রিপের পর ব্রেকার রিসেট করে আবার চালু হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফিউজ উড়লে বদলাতে হয়, ব্রেকার রিসেট হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ব্রেকারের ফল্ট কাটার ক্ষমতা ফিউজের চেয়ে বেশি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো সুইচই ফল্টের সময় সার্কিট কাটতে পারে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আইসোলেটর দিয়েই ফল্ট কারেন্ট আটকানো যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রিলে নিজেই সার্কিট কাটে, ব্রেকার লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'উড়ে যাওয়া ফিউজ রিসেট করলেই আবার চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফিউজ আর ব্রেকার একই, শুধু নামটা আলাদা', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্রেকার একবার ট্রিপ করলে নতুন লাগাতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'vcb',
      promptBn: 'কন্টাক্ট ভ্যাকুয়াম চেম্বারে — আধুনিক, কম রক্ষণাবেক্ষণের VCB কোনটা?',
      options: [
        LearnBoardOption(
          id: 'bottles',
          labelBn: 'তিনটে সিল করা ভ্যাকুয়াম বোতল',
          asset: 'assets/game/art/m6_board62/vcb_bottles.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cutaway',
          labelBn: 'ভ্যাকুয়ামে কন্টাক্ট খুলতেই আর্ক শেষ',
          asset: 'assets/game/art/m6_board62/vcb_cutaway.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'oiltank',
          labelBn: 'ট্যাঙ্কের তেলে ডোবানো কন্টাক্ট',
          asset: 'assets/game/art/m6_board62/vcb_oiltank.svg',
          scene: true,
          correct: false,
          rejectBn: 'এটা OCB — কন্টাক্ট তেলে ডোবানো, পুরনো প্রযুক্তি, রক্ষণাবেক্ষণ বেশি।',
        ),
        LearnBoardOption(
          id: 'bubble',
          labelBn: 'আর্কে তেল ফুটে গ্যাসের বুদবুদ',
          asset: 'assets/game/art/m6_board62/vcb_bubble.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল গ্যাস হয়ে উচ্চ চাপের বুদবুদে আর্ক নেভে — এটা OCB-র পদ্ধতি।',
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'গলে যাওয়া লিংকসহ ফিউজ ক্যারিয়ার',
          asset: 'assets/game/art/m6_board62/vcb_fuse.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজ নিজে উড়ে গিয়ে সিস্টেম বাঁচায় — এটা ব্রেকার নয়, বদলাতে হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভ্যাকুয়ামে আর্ক মুহূর্তে নিভে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'VCB আধুনিক, রক্ষণাবেক্ষণ লাগে কম', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'VCB-র কন্টাক্ট ভ্যাকুয়াম চেম্বারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'VCB-র কন্টাক্ট তেলে ডোবানো থাকে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'OCB নতুন প্রযুক্তি, রক্ষণাবেক্ষণ নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভ্যাকুয়ামে আর্ক অনেকক্ষণ জ্বলতে থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'VCB-তে তেলের বুদবুদে আর্ক নেভানো হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'VCB আর ফিউজ আসলে একই রকম জিনিস', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'OCB-র ট্যাঙ্কে তেল নয়, শুধু বাতাস', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'lamp',
      promptBn: 'ব্রেকার এখন খোলা (OFF) — প্যানেলের বাতি কেমন হবে?',
      options: [
        LearnBoardOption(
          id: 'green',
          labelBn: 'সবুজ জ্বলছে, লাল নেভা, স্প্রিং চার্জড',
          asset: 'assets/game/art/m6_board62/lamp_green.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'green2',
          labelBn: 'সবুজ জ্বলছে, লাল নেভা, স্প্রিং ডিসচার্জড',
          asset: 'assets/game/art/m6_board62/lamp_green2.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'red',
          labelBn: 'লাল জ্বলছে, সবুজ নেভা, বাকি সব নেভা',
          asset: 'assets/game/art/m6_board62/lamp_red.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাল বাতি মানে ON — ব্রেকার চালু, সার্কিটে যুক্ত।',
        ),
        LearnBoardOption(
          id: 'healthy',
          labelBn: 'লাল জ্বলছে, ট্রিপ সার্কিট হেলদিও জ্বলছে',
          asset: 'assets/game/art/m6_board62/lamp_healthy.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাল জ্বলছে মানে ON — হেলদি বাতি শুধু ট্রিপ সার্কিট ঠিক থাকার খবর।',
        ),
        LearnBoardOption(
          id: 'spring',
          labelBn: 'লাল জ্বলছে, সবুজ নেভা, স্প্রিং চার্জড',
          asset: 'assets/game/art/m6_board62/lamp_spring.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাল মানে ON — স্প্রিং চার্জড শুধু পরের অপারেশনের প্রস্তুতি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সবুজ বাতি মানে ব্রেকার খোলা বা ট্রিপ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লাল বাতি ON, সবুজ বাতি OFF বোঝায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'খোলা ব্রেকারে সবুজ জ্বলে, লাল নেভে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লাল বাতি জ্বলা মানে ব্রেকার খোলা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হেলদি বাতি জ্বললে ব্রেকার বন্ধ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্প্রিং চার্জড মানে ব্রেকার এখন ON', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দুটো বাতিই নিভলে ব্রেকার খোলা', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাউন্টারের সংখ্যাই ON-OFF বলে দেয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাতির রঙে ব্রেকারের কিছু বোঝা যায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'rack',
      promptBn: 'ব্রেকারের ওপর হাতে রক্ষণাবেক্ষণ — ট্রলি কোথায় থাকবে?',
      options: [
        LearnBoardOption(
          id: 'out',
          labelBn: 'ট্রলি র‍্যাক-আউট করে মেঝেতে, আইসোলেটেড',
          asset: 'assets/game/art/m6_board62/rack_out.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'side',
          labelBn: 'র‍্যাক-আউট ট্রলির কভার খুলে কাজ চলছে',
          asset: 'assets/game/art/m6_board62/rack_side.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'service',
          labelBn: 'ট্রলি ভেতরে, সার্ভিস পজিশনে কাজ চলছে',
          asset: 'assets/game/art/m6_board62/rack_service.svg',
          scene: true,
          correct: false,
          rejectBn: 'সার্ভিস পজিশনে ব্রেকার সার্কিটের সাথে সম্পূর্ণ যুক্ত।',
        ),
        LearnBoardOption(
          id: 'test',
          labelBn: 'ট্রলি আধা ভেতরে, টেস্ট পজিশনে কাজ চলছে',
          asset: 'assets/game/art/m6_board62/rack_test.svg',
          scene: true,
          correct: false,
          rejectBn: 'টেস্টে মূল পাওয়ার কাটা, কিন্তু কন্ট্রোল সার্কিট যুক্ত — সম্পূর্ণ বিচ্ছিন্ন নয়।',
        ),
        LearnBoardOption(
          id: 'green',
          labelBn: 'সার্ভিসে সবুজ জ্বলছে, কভার খোলা হচ্ছে',
          asset: 'assets/game/art/m6_board62/rack_green.svg',
          scene: true,
          correct: false,
          rejectBn: 'সবুজ মানে শুধু ব্রেকার খোলা — সার্ভিসে ব্রেকারটা এখনও সার্কিটে যুক্ত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আইসোলেটেডে পাওয়ার, কন্ট্রোল দুটোই কাটা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'র‍্যাক-আউট করলে তবেই নিরাপদে হাতে কাজ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হাতে কাজের আগে ট্রলি পুরো বের করে আনুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টেস্ট পজিশনেই হাতে কাজ করা নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সবুজ জ্বললে সার্ভিসেই কভার খোলা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সার্ভিস পজিশনে ব্রেকার বিচ্ছিন্ন থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'টেস্টে কন্ট্রোল সার্কিটও কাটা থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ট্রলি একটু টেনে আনলেই যথেষ্ট নিরাপদ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'র‍্যাক-আউট শুধু নতুন ব্রেকারে লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'line',
      promptBn: 'ফিডার ব্রেকার ট্রিপ, সবুজ জ্বলছে — লাইনে কাজের আগে কোনটা চাই?',
      options: [
        LearnBoardOption(
          id: 'ends',
          labelBn: 'লাইনের দুই প্রান্তে আইসোলেটর খোলা',
          asset: 'assets/game/art/m6_board62/line_ends.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'earth',
          labelBn: 'টেস্টারে ডেড প্রমাণ করে তিন ফেজে আর্থ',
          asset: 'assets/game/art/m6_board62/line_earth.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'সবুজ দেখেই ক্রু পোলে উঠে পড়ছে',
          asset: 'assets/game/art/m6_board62/line_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'সবুজ বাতি মানে শুধু ব্রেকার খোলা — লাইন কাজের জন্য নিরাপদ নয়।',
        ),
        LearnBoardOption(
          id: 'tie',
          labelBn: 'দূরের প্রান্ত আরেক চালু ফিডারে জোড়া',
          asset: 'assets/game/art/m6_board62/line_tie.svg',
          scene: true,
          correct: false,
          rejectBn: 'অন্য ফিডার থেকে ব্যাক-ফিডিং-এ লাইনে তখনও বিপজ্জনক ভোল্টেজ থাকতে পারে।',
        ),
        LearnBoardOption(
          id: 'oneend',
          labelBn: 'শুধু কাছের প্রান্ত খোলা, আর্থ নেই',
          asset: 'assets/game/art/m6_board62/line_oneend.svg',
          scene: true,
          correct: false,
          rejectBn: 'এক প্রান্ত খোলা যথেষ্ট নয় — দুই প্রান্তে আইসোলেটর খুলে, টেস্টারে ডেড প্রমাণ করে, আর্থিং চাই।',
        ),
        LearnBoardOption(
          id: 'hand',
          labelBn: 'আর্থ ছাড়াই তারের দিকে হাত বাড়ানো',
          asset: 'assets/game/art/m6_board62/line_hand.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইন্ডুসড ভোল্টেজে লাইনে তখনও বিপদ থাকতে পারে — আর্থিং ছাড়া নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দুই প্রান্তে আইসোলেটর খুলে বিচ্ছিন্ন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টেস্টারে ডেড প্রমাণ করে তবেই আর্থিং', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আর্থিং করার পরই লাইন কাজের জন্য নিরাপদ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সবুজ বাতি মানে শুধু ব্রেকারটা খোলা', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'সবুজ বাতি জ্বললেই লাইনে ওঠা নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'এক প্রান্ত খুললেই লাইন পুরো ডেড', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ট্রিপ করা লাইনে টেস্টার লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আগে আর্থ, পরে টেস্টার দিলেও চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অন্য ফিডারে জোড়া থাকলেও ভয় নেই', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'ইন্ডুসড ভোল্টেজে কখনো বিপদ হয় না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board62Lines.rivalTaunt,
    rivalLineBn: M6Board62Lines.rivalMyth,
    exitBn: M6Board62Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    // DRAFT wording — owner. Questions about the claim (as pack 5.8), so the
    // tags do not repeat a right chip word for word.
    dangerHints: [
      'ট্রিপ মানেই ভোল্টেজ নেই?',
      'সবুজ মানেই নিরাপদ?',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ব্রেকার শুধু সোর্সের দিক থেকে লাইন কাটে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'অন্য ফিডারের ব্যাক-ফিডিং-এ ভোল্টেজ থাকে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'ইন্ডুসড ভোল্টেজেও লাইনে বিপদ থাকতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ট্রিপ মানেই লাইনে আর কোনো ভোল্টেজ নেই', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'সবুজ বাতি জ্বললেই লাইনে ওঠা নিরাপদ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'শুধু সোর্সের ব্রেকার খোলাই যথেষ্ট', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ট্রিপ করা লাইনে আর্থিং দিতে হয় না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ব্যাক-ফিডিং বইয়ের কথা, মাঠে হয় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'টেস্টার লাগে শুধু চালু থাকা লাইনে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py`.
abstract final class M6Board62Lines {
  // DRAFT wording — owner.
  static const rivalTaunt = 'আরে, সবুজ বাতি তো জ্বলছে! এত সাবধানের কী আছে?';

  /// Lesson 6.2's first myth, word for word.
  static const rivalMyth = 'সার্কিট ব্রেকার ট্রিপ করেছে মানে লাইনটি সম্পূর্ণ বন্ধ। এতে কোনো ভোল্টেজ নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session (ruling M6-12).
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Same list under the Module 6 name (ruling M6-12).
  static const newRivalLines = toRecord;
}
