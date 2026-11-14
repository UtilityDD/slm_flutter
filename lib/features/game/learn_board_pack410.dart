import 'learn_board_models.dart';

/// Module 4 Lesson 4.10 (এলটি (LT) লাইনের ফেজ ব্যালেন্সিং), the picture board
/// (rung `4.10/learn`, pack `learn_4_10`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board410_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * spot: one phase's fuse blowing again and again and low-voltage
///    complaints from one area are clear signs of unbalance; the clamp-on
///    meter (tong tester) is the main tool — clamp each phase (R, Y, B) and the
///    neutral at the feeder pillar; balancing without measuring is guesswork;
///  * measure: at peak-load time measure each phase and the neutral and make a
///    list (step 1);
///  * plan: the lesson's own readings R=120A, Y=70A, B=50A — move some service
///    lines from the overloaded phase (R) to the lightly loaded ones (Y, B);
///  * work: change the phase connection at the pillar only with PTW and the
///    safety rules (the film: after shutdown); tell the customer first. The
///    shutdown card also draws a tag and an earth lead (house rule; the lesson
///    says only "PTW and the safety rules");
///  * check: measure every phase again — the neutral current near zero; keep
///    a record of which customer is on which phase; an unbalanced line's
///    neutral carries current and can be dangerous (the film: lethal).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack410 = LearnBoardPack(
  lessonId: '4.10',
  titleBn: 'এলটি (LT) লাইনের ফেজ ব্যালেন্সিং',
  badgeBn: 'কাজের কারিগর',
  introBn: 'তিন ফেজে লোড প্রায় সমান থাকাই আদর্শ। মাপুন, ভাগ করুন, আবার মাপুন।',
  earnedBn: 'ক্ল্যাম্প মিটারে মেপে বেশি লোডের ফেজ থেকে লাইন সরান — নিউট্রাল কারেন্ট শূন্যের কাছাকাছি আনুন।',
  slots: [
    LearnBoardSlot(
      id: 'spot',
      promptBn: 'এক ফেজের ফিউজ বারবার উড়ছে, পাড়ায় লো-ভোল্টেজ — কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'phase',
          labelBn: 'ক্ল্যাম্প মিটারে ফেজের কারেন্ট মাপা',
          asset: 'assets/game/art/m4_board410/spot_phase.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'neutral',
          labelBn: 'নিউট্রাল তারেও ক্ল্যাম্প করে মাপা',
          asset: 'assets/game/art/m4_board410/spot_neutral.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fuse',
          labelBn: 'আবার শুধু নতুন ফিউজ লাগিয়ে দেওয়া',
          asset: 'assets/game/art/m4_board410/spot_fuse.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটা ফেজের ফিউজ বারবার উড়ে যাওয়া আনব্যালেন্সের স্পষ্ট লক্ষণ — শুধু ফিউজ বদলে নয়, আগে কারেন্ট মাপুন।',
        ),
        LearnBoardOption(
          id: 'guess',
          labelBn: 'না মেপেই আন্দাজে লাইন সরানো',
          asset: 'assets/game/art/m4_board410/spot_guess.svg',
          scene: true,
          correct: false,
          rejectBn: 'সঠিক পরিমাপ ছাড়া লোড ব্যালেন্সিং মানে অনুমানের ওপর কাজ — ক্ল্যাম্প মিটারই আসল চিত্রটা দেখায়।',
        ),
        LearnBoardOption(
          id: 'ignore',
          labelBn: 'অভিযোগ শুনেও পিলার বন্ধ করে ফেরা',
          asset: 'assets/game/art/m4_board410/spot_ignore.svg',
          scene: true,
          correct: false,
          rejectBn: 'এক এলাকা থেকে বারবার লো-ভোল্টেজের অভিযোগ আনব্যালেন্সের স্পষ্ট লক্ষণ — উপেক্ষা নয়, মেপে দেখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বারবার ফিউজ ওড়া আনব্যালেন্সের স্পষ্ট লক্ষণ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্ল্যাম্প মিটারই ব্যালেন্সিং-এর প্রধান হাতিয়ার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'R, Y, B আর নিউট্রাল — প্রতিটি তারে কারেন্ট মাপুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফিউজ উড়লে শুধু নতুন ফিউজ লাগালেই সমস্যা শেষ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লো-ভোল্টেজের অভিযোগের সঙ্গে লোডের কোনো যোগ নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অভিজ্ঞ লাইনম্যান আন্দাজেই ঠিক ফেজ ধরে ফেলেন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নিউট্রাল তারে মাপার কোনো দরকারই পড়ে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অভিযোগ বারবার এলেও নিজে থেকে ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ক্ল্যাম্প মিটার শুধু বড় কারখানার কাজে লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'measure',
      promptBn: 'আনব্যালেন্স মাপবেন — কখন আর কীভাবে মাপা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'peak',
          labelBn: 'পিক-লোডের সন্ধ্যায় ক্ল্যাম্পে মাপা',
          asset: 'assets/game/art/m4_board410/measure_peak.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'list',
          labelBn: 'প্রতিটি ফেজের রিডিং তালিকায় লেখা',
          asset: 'assets/game/art/m4_board410/measure_list.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'noon',
          labelBn: 'দুপুরের হালকা লোডে মেপে নেওয়া',
          asset: 'assets/game/art/m4_board410/measure_noon.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রথম ধাপ: পিক-লোডের সময়ে প্রতিটি ফেজ আর নিউট্রালের কারেন্ট মেপে তালিকা করুন।',
        ),
        LearnBoardOption(
          id: 'count',
          labelBn: 'বাড়ি গুনে ফেজের লোড আন্দাজ',
          asset: 'assets/game/art/m4_board410/measure_count.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাড়ি গুনে আন্দাজ মানে অনুমানের ওপর কাজ — ক্ল্যাম্প মিটারে সরাসরি অ্যাম্পিয়ারে কারেন্ট মাপুন।',
        ),
        LearnBoardOption(
          id: 'bulb',
          labelBn: 'বাতির আলো দেখে লোড বিচার',
          asset: 'assets/game/art/m4_board410/measure_bulb.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাতির আলো দেখে লোড বোঝা যায় না — মাপ ছাড়া ব্যালেন্সিং অনুমান, ক্ল্যাম্প মিটারে মাপুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পিক-লোডের সময়ে প্রতিটি ফেজের কারেন্ট মাপুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ফেজ আর নিউট্রালের রিডিং দিয়ে তালিকা বানান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ক্ল্যাম্প মিটারে সরাসরি অ্যাম্পিয়ারে মান দেখুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দুপুরের হালকা লোডেই আসল ছবিটা পাওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বাড়ির সংখ্যা গুনলেই ফেজের লোড জানা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাতির আলো দেখেই কারেন্ট বোঝা যথেষ্ট হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রিডিং মনে রাখলেই হবে, লেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যেকোনো একটা ফেজ মাপলেই বাকিগুলো বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নিউট্রালের রিডিং তালিকায় রাখার মানে নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'plan',
      promptBn: 'রিডিং R=120A, Y=70A, B=50A — কোন পরিকল্পনা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'r_to_b',
          labelBn: 'R থেকে একটা লাইন B ফেজে',
          asset: 'assets/game/art/m4_board410/plan_r_to_b.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'r_to_y',
          labelBn: 'R থেকে একটা লাইন Y ফেজে',
          asset: 'assets/game/art/m4_board410/plan_r_to_y.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'b_to_r',
          labelBn: 'B থেকে একটা লাইন R ফেজে',
          asset: 'assets/game/art/m4_board410/plan_b_to_r.svg',
          scene: true,
          correct: false,
          rejectBn: 'R-ই ওভারলোডেড (120A) — তাতে আরও লোড দিলে ফিউজ উড়বে, ট্রান্সফরমার গরম হবে। সরান R থেকে।',
        ),
        LearnBoardOption(
          id: 'y_to_r',
          labelBn: 'Y থেকে একটা লাইন R ফেজে',
          asset: 'assets/game/art/m4_board410/plan_y_to_r.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন সরাতে হয় ওভারলোডেড ফেজ (R) থেকে কম লোডযুক্ত ফেজে (Y, B) — উল্টো দিকে নয়।',
        ),
        LearnBoardOption(
          id: 'all_to_b',
          labelBn: 'R-এর প্রায় সব লাইন B ফেজে',
          asset: 'assets/game/art/m4_board410/plan_all_to_b.svg',
          scene: true,
          correct: false,
          rejectBn: 'লক্ষ্য তিন ফেজে প্রায় সমান লোড — R-এর প্রায় সব লাইন B-তে দিলে এবার B-ই ওভারলোডেড হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বেশি লোডের ফেজ থেকে কম লোডের ফেজে লাইন সরান', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আগে বড় থ্রি-ফেজ লোড, পরে সিঙ্গেল-ফেজ ভাগ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লক্ষ্য হলো তিন ফেজে প্রায় সমান কারেন্ট', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সবচেয়ে বেশি লোডের ফেজে আরও লাইন দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো ফেজ থেকে যেকোনো ফেজে সরালেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'R-এর সব লাইন একটা ফেজে দিলেই ব্যালেন্স শেষ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কম লোডের ফেজ থেকেই লাইন সরানো সবচেয়ে সহজ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রিডিং দেখে পরিকল্পনা করার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বড় থ্রি-ফেজ লোড শেষে দেখলেই চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'work',
      promptBn: 'সার্ভিস লাইনের ফেজ কানেকশন বদলাবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'shutdown',
          labelBn: 'শাটডাউন ও পারমিট (PTW) নিয়ে R থেকে B-তে বদল',
          asset: 'assets/game/art/m4_board410/work_shutdown.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'notify',
          labelBn: 'কাজের আগে গ্রাহককে জানিয়ে রাখা',
          asset: 'assets/game/art/m4_board410/work_notify.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'চালু পিলারেই তার খুলে বদল',
          asset: 'assets/game/art/m4_board410/work_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফেজ বদল সঠিক পারমিট (PTW) আর সুরক্ষা নিয়ম মেনে, শাটডাউন নিয়েই — চালু পিলারে তার খোলা মানে মৃত্যুর ঝুঁকি।',
        ),
        LearnBoardOption(
          id: 'surprise',
          labelBn: 'গ্রাহককে না জানিয়ে হঠাৎ বন্ধ',
          asset: 'assets/game/art/m4_board410/work_surprise.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোনো গ্রাহকের সংযোগ বদলাতে হলে, সম্ভব হলে তাঁকে আগে থেকে জানিয়ে রাখুন।',
        ),
        LearnBoardOption(
          id: 'wrong',
          labelBn: 'শাটডাউনে B থেকে R-এ লাইন বদল',
          asset: 'assets/game/art/m4_board410/work_wrong.svg',
          scene: true,
          correct: false,
          rejectBn: 'R আগে থেকেই ওভারলোডেড — লাইন সরাতে হয় বেশি লোডের ফেজ থেকে কম লোডের ফেজে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফেজ বদল শুধু শাটডাউন ও পারমিট (PTW) নিয়ে, নিয়ম মেনে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সংযোগ বদলের আগে গ্রাহককে আগাম জানিয়ে রাখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বেশি লোডের ফেজের লাইন কম লোডের ফেজে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছোট সার্ভিস লাইন চালু অবস্থাতেই বদলানো যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গ্রাহককে জানালে শুধু ঝামেলা আর দেরি বাড়ে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পারমিট (PTW) শুধু HT লাইনের কাজে লাগে, LT-তে নয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'যে ফেজে জায়গা পাওয়া যায় সেখানেই জুড়ে দিন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পিলারের সুইচ চালু রেখেই কাজ দ্রুত হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রাতে না জানিয়ে বন্ধ করলে কেউ টের পায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'check',
      promptBn: 'ফেজ বদল শেষ, লাইন আবার চালু — এবার কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'again',
          labelBn: 'আবার মেপে নিউট্রাল প্রায় শূন্য দেখা',
          asset: 'assets/game/art/m4_board410/check_again.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'record',
          labelBn: 'কোন গ্রাহক কোন ফেজে, খাতায় লেখা',
          asset: 'assets/game/art/m4_board410/check_record.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: 'না মেপেই কাজ শেষ বলে ফেরা',
          asset: 'assets/game/art/m4_board410/check_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শেষে আবার ক্ল্যাম্প মিটারে প্রতিটি ফেজ মেপে দেখুন, লোড কতটা ব্যালেন্সড হলো।',
        ),
        LearnBoardOption(
          id: 'high',
          labelBn: 'নিউট্রালে বেশি কারেন্ট দেখেও ফেরা',
          asset: 'assets/game/art/m4_board410/check_high.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিউট্রাল কারেন্ট যত বেশি, সিস্টেম তত আনব্যালেন্সড — লক্ষ্য তাকে শূন্যের কাছাকাছি আনা।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'নিউট্রাল তার খালি হাতে ধরা',
          asset: 'assets/game/art/m4_board410/check_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'আনব্যালেন্সড লাইনে নিউট্রাল দিয়েও কারেন্ট বয় — তা বিপজ্জনক, প্রাণঘাতীও হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কাজের পর আবার মেপে দেখুন লোড কতটা ব্যালেন্সড', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নিউট্রাল কারেন্ট শূন্যের কাছাকাছি আনাই লক্ষ্য', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গ্রাহক-ফেজের রেকর্ড পরের কাজ সহজ করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একবার ব্যালেন্স করলে আর কখনো দেখতে হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নিউট্রালে কারেন্ট বেশি থাকলেও কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কে কোন ফেজে আছেন, মনে রাখলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নিউট্রাল তার সবসময় খালি হাতে ধরা নিরাপদ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাজ শেষ হলে আবার মাপা শুধু সময় নষ্ট', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নতুন গ্রাহক এলেও ব্যালেন্স আর নষ্ট হয় না', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board410Lines.rivalTaunt,
    rivalLineBn: M4Board410Lines.rivalMyth,
    exitBn: M4Board410Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'আনব্যালেন্সড লাইনের নিউট্রাল',
      'খালি হাতে নিউট্রাল ধরা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'আনব্যালেন্সড লাইনে নিউট্রাল দিয়েও কারেন্ট বয়ে যায়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'নিউট্রালে কারেন্ট শূন্য শুধু পুরো ব্যালেন্সড সিস্টেমে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'বাস্তবে প্রায় সব লাইনেই কম-বেশি আনব্যালেন্স থাকে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'নিউট্রালে ভোল্টেজ নেই, তাই কারেন্টও থাকতে পারে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'নিউট্রাল তার যেকোনো সময় খালি হাতে ধরা নিরাপদ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'নিউট্রালের কারেন্ট মাপার কোনো মানেই হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আনব্যালেন্সে শুধু ফেজের তারেই কারেন্ট বাড়ে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'নিউট্রালে ক্ল্যাম্প লাগালে মিটার কিছুই দেখায় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'নিউট্রাল কারেন্ট বাড়লেও সিস্টেমের কোনো ক্ষতি নেই', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board410Lines {
  static const rivalTaunt = 'আরে, নিউট্রাল তো ঠান্ডা তার! ওটা আবার মাপতে হয় নাকি?';

  /// Lesson 4.10's first myth buster, word for word.
  static const rivalMyth = 'নিউট্রালে তো কোনো ভোল্টেজ থাকে না, তাই ওতে কারেন্টও থাকে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
