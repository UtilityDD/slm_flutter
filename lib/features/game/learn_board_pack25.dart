import 'learn_board_models.dart';

/// Module 2 Lesson 2.5 (অপারেটিং রড (হট স্টিক): দূরত্বের সুরক্ষা), the
/// picture board (rung `2.5/learn`, pack `learn_2_5`).
///
/// Picture cards are vector scenes from `tool/m2_board25_art.py`. Every round
/// and every trap comes from the lesson text:
///  * check: before every use run a hand along the full length for cracks,
///    deep scratches or a damaged glaze; clean and fully dry; every telescopic
///    section locked (pro tip 4);
///  * hold: the attachment fitted firmly (a loose one can fall from above,
///    pro tip 3); two hands for control and stability (pro tip 2); smoothness
///    is skill — no jerk or force (pro tip 1);
///  * fuse: the DO fuse — stand to the side or at an angle, never straight
///    under or in front (an arc / flash, hot gas, molten metal); hook the fuse
///    puller firmly in the ring; one quick, controlled pull with the face and
///    body aside; goggles or face shield and insulated gloves;
///  * switch: an AB switch / isolator only off-load (the breaker opened
///    first — it has no arc quenching); a spline / socket on the handle,
///    turned slowly and in control; on-load = a huge arc;
///  * care: a soft dry cloth after use; a waterproof bag or hung on a wall —
///    not on the ground or a vehicle floor (scratches); never an ordinary
///    stick for other work.
/// The rival's myth is the lesson's own (the bamboo stick). The lesson's
/// lab-test figures (75–100 kV per foot) are left out of the board.
const learnBoardPack25 = LearnBoardPack(
  lessonId: '2.5',
  titleBn: 'অপারেটিং রড (হট স্টিক): দূরত্বের সুরক্ষা',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'দূর থেকে কাজ, হাত লম্বা আর ইনসুলেটেড — হট স্টিক শুধু লাঠি নয়, সুরক্ষার বর্ম।',
  earnedBn: 'যাচাই করা, শুকনো, রেটেড স্টিক — দুই হাতে, পাশে দাঁড়িয়ে, আইসোলেটর শুধু অফ-লোডে।',
  slots: [
    LearnBoardSlot(
      id: 'check',
      promptBn: 'কাজে বেরোনোর আগে হট স্টিক হাতে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'feel', labelBn: 'পুরো দৈর্ঘ্যে হাত বুলিয়ে দেখা', asset: 'assets/game/art/m2_board25/check_feel.svg', scene: true, correct: true),
        LearnBoardOption(id: 'lock', labelBn: 'প্রতিটি সেকশনের লক দেখে নেওয়া', asset: 'assets/game/art/m2_board25/check_lock.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'ফাটল-ধরা স্টিক নিয়েই রওনা',
          asset: 'assets/game/art/m2_board25/check_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফাটল দিয়ে ভেতরের ফোমে আর্দ্রতা ঢোকে — ইনসুলেশন ভেতর থেকে নষ্ট হয়।',
        ),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'ভেজা স্টিক না মুছেই কাজে',
          asset: 'assets/game/art/m2_board25/check_wet.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা স্টিকের ইনসুলেটিং ক্ষমতা মারাত্মকভাবে কমে — স্টিক হবে পরিষ্কার আর সম্পূর্ণ শুকনো।',
        ),
        LearnBoardOption(
          id: 'scratch',
          labelBn: 'গভীর আঁচড় দেখেও ব্যবহার',
          asset: 'assets/game/art/m2_board25/check_scratch.svg',
          scene: true,
          correct: false,
          rejectBn: 'গভীর আঁচড় বা নষ্ট গ্লেজ আর্দ্রতার পথ খুলে দেয় — বাইরে থেকে ক্ষতি বোঝা যায় না।',
        ),
        LearnBoardOption(
          id: 'grease',
          labelBn: 'গ্রিজ-ময়লা মাখা স্টিক তোলা',
          asset: 'assets/game/art/m2_board25/check_grease.svg',
          scene: true,
          correct: false,
          rejectBn: 'নোংরা স্টিকের ইনসুলেশন কমে যায় — অনুমোদিত সলভেন্টে পরিষ্কার করে তবে ব্যবহার।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রতিবার ব্যবহারের আগে পুরো স্টিক দেখুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্ষত বা ঢিলা স্টিকে ভরসা নয়, আগে যাচাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্টিকই হাত আর লাইভ তারের মাঝের বাধা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছোট ফাটলে কিছু হয় না, কাজ চলে যাবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ভেজা স্টিক কাজের মধ্যেই শুকিয়ে যাবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আঁচড় তো বাইরে, ভেতরটা ঠিকই থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'স্টিক দেখা সময় নষ্ট, আগে কাজ সারি', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্রিজ মাখা থাকলে স্টিক আরও ভালো চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'টেলিস্কোপিক সেকশন নিজে থেকেই আটকায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hold',
      promptBn: 'মাথায় ফিউজ পুলার লাগিয়ে স্টিক তুলছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'two_hands', labelBn: 'দুই হাতে শক্ত করে ধরে তোলা', asset: 'assets/game/art/m2_board25/hold_two_hands.svg', scene: true, correct: true),
        LearnBoardOption(id: 'check_head', labelBn: 'অ্যাটাচমেন্ট টাইট আছে দেখা', asset: 'assets/game/art/m2_board25/hold_check_head.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'one_hand',
          labelBn: 'এক হাতে দুলিয়ে স্টিক তোলা',
          asset: 'assets/game/art/m2_board25/hold_one_hand.svg',
          scene: true,
          correct: false,
          rejectBn: 'হট স্টিক দুই হাতে ধরুন — তাতেই ভালো নিয়ন্ত্রণ আর স্থিতিশীলতা।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'ঢিলা অ্যাটাচমেন্ট নিয়েই তোলা',
          asset: 'assets/game/art/m2_board25/hold_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঢিলা অ্যাটাচমেন্ট ওপর থেকে পড়ে গিয়ে বিপদ ঘটাতে পারে — শুরুর আগে দেখে নিন।',
        ),
        LearnBoardOption(
          id: 'slid',
          labelBn: 'সেকশন লক না করেই তোলা',
          asset: 'assets/game/art/m2_board25/hold_slid.svg',
          scene: true,
          correct: false,
          rejectBn: 'টেলিস্কোপিক স্টিকের প্রতিটি সেকশন ব্যবহারের আগে ঠিকভাবে লক করা চাই।',
        ),
        LearnBoardOption(
          id: 'jerk',
          labelBn: 'ঝাঁকিয়ে জোর খাটিয়ে ঠেলা',
          asset: 'assets/game/art/m2_board25/hold_jerk.svg',
          scene: true,
          correct: false,
          rejectBn: 'মসৃণতাই দক্ষতা — হট স্টিকে ঝাঁকুনি বা জোর খাটানোর দরকার হওয়া উচিত নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নিয়ন্ত্রিত, মসৃণ কাজেই হট স্টিক নিরাপদ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তোলার আগে স্টিক আর মাথা পোক্ত কিনা দেখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঢিলা জিনিস বা টলমলে হাত ওপরে বিপদ ডাকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'এক হাতে ধরলেও স্টিক ঠিকই সামলানো যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'অ্যাটাচমেন্ট একটু ঢিলা থাকলে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সেকশন লক না হলেও স্টিক খাড়া থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জোরে ঝাঁকালে কাজ তাড়াতাড়ি শেষ হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ওপরে পৌঁছে তবে অ্যাটাচমেন্ট দেখা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fuse',
      promptBn: 'ডিও ফিউজ খুলবেন, স্টিক তৈরি — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'side', labelBn: 'রিং-এ আটকে মুখ সরিয়ে টান', asset: 'assets/game/art/m2_board25/fuse_side.svg', scene: true, correct: true),
        LearnBoardOption(id: 'open', labelBn: 'পাশে দাঁড়িয়ে এক টানে খোলা', asset: 'assets/game/art/m2_board25/fuse_open.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'under',
          labelBn: 'ফিউজের ঠিক নিচে দাঁড়িয়ে টান',
          asset: 'assets/game/art/m2_board25/fuse_under.svg',
          scene: true,
          correct: false,
          rejectBn: 'সরাসরি নিচে দাঁড়ালে গরম গ্যাস বা গলিত ধাতু মুখে-শরীরে পড়ে — পাশে বা কোণাকুণি দাঁড়ান।',
        ),
        LearnBoardOption(
          id: 'no_shield',
          labelBn: 'ফেস শিল্ড ছাড়া ফিউজের দিকে চেয়ে',
          asset: 'assets/game/art/m2_board25/fuse_no_shield.svg',
          scene: true,
          correct: false,
          rejectBn: 'খোলার সময় আর্ক বা ফ্ল্যাশ হতে পারে — সেফটি গগলস বা ফেস শিল্ড পরুন, মুখ একপাশে।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে স্টিক ধরে ফিউজ খোলা',
          asset: 'assets/game/art/m2_board25/fuse_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই কাজ সবসময় ইনসুলেটেড গ্লাভস পরে — সঙ্গে গগলস বা ফেস শিল্ড।',
        ),
        LearnBoardOption(
          id: 'miss',
          labelBn: 'রিং-এ না আটকে খোঁচা দেওয়া',
          asset: 'assets/game/art/m2_board25/fuse_miss.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজ পুলার আগে রিং-এর মধ্যে দৃঢ়ভাবে আটকান — তারপর দ্রুত, নিয়ন্ত্রিত টান।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'খোলার সময় আর্ক বা ফ্ল্যাশ হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পাশে দাঁড়ালে গরম গ্যাস মুখে আসে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফেস শিল্ড আর গ্লাভস পরে তবেই টান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ঠিক নিচে দাঁড়ালে টান সোজা পড়ে, ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'স্টিক আছে, তাই গ্লাভস লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফ্ল্যাশ এক মুহূর্তের, চোখ বুজলেই হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিং-এ না আটকে খোঁচালেও খুলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মুখ ফিউজের দিকে রাখলে ভালো দেখা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'switch',
      promptBn: 'AB সুইচ (আইসোলেটর) খুলবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'slow', labelBn: 'সকেট বসিয়ে ধীরে হ্যান্ডেল ঘোরানো', asset: 'assets/game/art/m2_board25/switch_slow.svg', scene: true, correct: true),
        LearnBoardOption(id: 'breaker', labelBn: 'আগে ব্রেকার খোলা নিশ্চিত করা', asset: 'assets/game/art/m2_board25/switch_breaker.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'on_load',
          labelBn: 'লোড চলা অবস্থায় সুইচ খোলা',
          asset: 'assets/game/art/m2_board25/switch_on_load.svg',
          scene: true,
          correct: false,
          rejectBn: 'আইসোলেটর শুধু অফ-লোডে — অন-লোডে খুললে বিশাল আর্ক, সুইচ আর মানুষ দুই-ই ক্ষতিগ্রস্ত।',
        ),
        LearnBoardOption(
          id: 'rush',
          labelBn: 'তাড়াহুড়োয় জোরে ঘুরিয়ে দেওয়া',
          asset: 'assets/game/art/m2_board25/switch_rush.svg',
          scene: true,
          correct: false,
          rejectBn: 'হ্যান্ডেল ধীরে ধীরে, নিয়ন্ত্রিতভাবে ঘোরান — তাড়াহুড়ো নয়।',
        ),
        LearnBoardOption(
          id: 'no_socket',
          labelBn: 'সকেট না বসিয়েই ঘোরানোর চেষ্টা',
          asset: 'assets/game/art/m2_board25/switch_no_socket.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্প্লাইন বা সকেট অ্যাটাচমেন্ট হ্যান্ডেলের সাথে ঠিকভাবে সংযুক্ত করে তবে ঘোরান।',
        ),
        LearnBoardOption(
          id: 'force',
          labelBn: 'স্টিক বাঁকিয়ে গায়ের জোরে চাপ',
          asset: 'assets/game/art/m2_board25/switch_force.svg',
          scene: true,
          correct: false,
          rejectBn: 'হট স্টিকে জোর খাটানোর দরকার হওয়া উচিত নয় — মসৃণ অপারেশনই সঠিক ব্যবহার।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আইসোলেটরে আর্ক নেভানোর ব্যবস্থা নেই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'অফ-লোড মানে লাইনে কারেন্ট বইছে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে ব্রেকার খুলে তবে আইসোলেটর খোলা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লোড থাকলেও আইসোলেটর খোলা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জোরে ঘোরালে আর্ক হওয়ার সময় পায় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সকেট না বসালেও হ্যান্ডেল ঘুরে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ব্রেকার খোলা কিনা দেখা অন্যের কাজ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্টিক বাঁকলেও জোর দিলে সুইচ খোলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'care',
      promptBn: 'কাজ শেষ, এবার স্টিকটা নিয়ে কী করবেন?',
      options: [
        LearnBoardOption(id: 'wipe', labelBn: 'নরম শুকনো কাপড়ে মুছে নেওয়া', asset: 'assets/game/art/m2_board25/care_wipe.svg', scene: true, correct: true),
        LearnBoardOption(id: 'hang', labelBn: 'দেওয়ালের হুকে ঝুলিয়ে রাখা', asset: 'assets/game/art/m2_board25/care_hang.svg', scene: true, correct: true),
        LearnBoardOption(id: 'bag', labelBn: 'ওয়াটারপ্রুফ ব্যাগে ভরে রাখা', asset: 'assets/game/art/m2_board25/care_bag.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'ground',
          labelBn: 'মাটিতে ফেলে রেখে চলে যাওয়া',
          asset: 'assets/game/art/m2_board25/care_ground.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটিতে বা গাড়ির মেঝেতে ফেলে রাখলে আঁচড় লাগে — ব্যাগে ভরুন বা দেওয়ালে ঝোলান।',
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'স্টিক দিয়ে গাছের ডাল নাড়া',
          asset: 'assets/game/art/m2_board25/care_branch.svg',
          scene: true,
          correct: false,
          rejectBn: 'হট স্টিক কখনো সাধারণ লাঠি বা অন্য কাজে নয় — এর যত্ন মানে নিজের জীবনের যত্ন।',
        ),
        LearnBoardOption(
          id: 'drag',
          labelBn: 'মাটিতে ঘষটে টেনে নিয়ে যাওয়া',
          asset: 'assets/game/art/m2_board25/care_drag.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটিতে ঘষটালে গায়ে আঁচড় পড়ে — সেই আঁচড়ে আর্দ্রতা ঢুকে ইনসুলেশন নষ্ট করে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ভেজা-নোংরা স্টিকের ইনসুলেশন কমে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আঁচড় থেকে বাঁচাতে যত্ন করে রাখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্টিকের যত্ন মানে নিজের জীবনের যত্ন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'হট স্টিক তো লাঠি, যেকোনো কাজে চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মাটিতে রাখলে স্টিকের কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গাড়ির মেঝেতে ফেলে রাখাই সবচেয়ে সহজ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাজ শেষ, এখন আর মোছার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বছরের পর বছর পরীক্ষা ছাড়াই চলে যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: HotStickBoardLines.rivalTaunt,
    rivalLineBn: HotStickBoardLines.rivalMyth,
    exitBn: HotStickBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'বাঁশের লাঠিতে ফিউজ খোলা',
      'রেটেড হট স্টিক ছাড়া কাজ',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'বাঁশের ভেতরে আর্দ্রতা থাকে, কারেন্ট বয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'বাঁশের ডাই-ইলেকট্রিক স্ট্রেন্থ খুব কম', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'শুধু রেটেড ফাইবারগ্লাস স্টিকই নিরাপদ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'শুকনো বাঁশ রবারের মতোই ইনসুলেটর', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ফিউজ খুলতে যেকোনো লম্বা লাঠি চলে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'বাঁশ হালকা, তাই ওটাই বেশি নিরাপদ', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'হট স্টিক আনতে গাড়িতে যাওয়া সময় নষ্ট', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'রোদে শুকোলে বাঁশে কারেন্ট বয় না', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. The taunt and the exit are
/// already recorded (`learnRivalVoice`); the myth line goes through device
/// TTS until it is recorded ([toRecord]).
abstract final class HotStickBoardLines {
  /// Already recorded (reused).
  static const rivalTaunt = 'শুকনো বাঁশ তো, চলবে! হট স্টিক আনতে গাড়ি পর্যন্ত কে যাবে?';

  /// Lesson 2.5's first myth buster, word for word.
  static const rivalMyth = 'শুকনো বাঁশের লাঠিও তো ইনসুলেটর, এটা দিয়ে ফিউজ খোলা যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the owner to record.
  static const toRecord = [rivalMyth];
}
