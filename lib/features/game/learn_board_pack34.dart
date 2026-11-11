import 'learn_board_models.dart';

/// Module 3 Lesson 3.4 (ডিও (DO) ফিউজ ও হর্ন গ্যাপ ফিউজ: নীরব প্রহরী), the
/// picture board (rung `3.4/learn`, pack `learn_3_4`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board34_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * three: a DO fuse that has blown drops out — the hanging barrel is the
///    fault sign seen from afar; on a three-phase transformer the other two
///    phases' fuses are opened too, to isolate it fully ("দুটি নয়, তিনটিই
///    খুলুন"); a blown fuse means a fault on the line;
///  * operate: a DO fuse is opened / closed with a hot stick and the correct
///    body position (it is also used as a switch to isolate a line); a small
///    bang on opening is normal — the boric-acid lining makes gas that throws
///    the arc out. "Standing right under the barrel" is our picture of a wrong
///    position (the lesson only says "correct body position");
///  * link: the ampere rating is read off the plate on the transformer or
///    pole; a thicker wire lets the transformer burn on overload, a too-thin
///    one blows on normal load again and again, an ordinary wire has no known
///    melting point; K type is fast-acting, T type slow-blow;
///  * fit: the link is tied correctly and at the right tension; a loose or
///    wrongly tied link does not work properly; dirt or carbon on the top and
///    bottom contacts sparks and ruins them;
///  * horn: the arc rises with the hot air and, as the gap between the horns
///    widens, goes out by itself; it quenches arcs poorly — dangerous on a big
///    fault, less reliable than a DO fuse.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack34 = LearnBoardPack(
  lessonId: '3.4',
  titleBn: 'ডিও (DO) ফিউজ ও হর্ন গ্যাপ ফিউজ: নীরব প্রহরী',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'ফিউজ লাইনের নীরব প্রহরী — নিজে গলে ট্রান্সফরমার বাঁচায়। চিনে নিন।',
  earnedBn: 'রেটিং মিলিয়ে লিঙ্ক, হট স্টিকে খোলা, পরিষ্কার কন্টাক্ট — আর একটা উড়লে তিনটিই খুলুন।',
  slots: [
    LearnBoardSlot(
      id: 'three',
      promptBn: 'থ্রি-ফেজের একটা ডিও ফিউজ উড়েছে — এবার কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'open2',
          labelBn: 'হট স্টিকে বাকি ফেজের ফিউজও খোলা',
          asset: 'assets/game/art/m3_board34/three_open2.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'all3',
          labelBn: 'তিনটে ফেজের ফিউজই খোলা অবস্থায়',
          asset: 'assets/game/art/m3_board34/three_all3.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'উড়ে যাওয়া ফিউজটাই আবার লাগানো',
          asset: 'assets/game/art/m3_board34/three_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিউজ উড়ে যাওয়া মানে লাইনে ফল্ট আছে — আগে বাকি দুটো ফিউজও খুলে ট্রান্সফরমার পুরো বিচ্ছিন্ন করুন।',
        ),
        LearnBoardOption(
          id: 'two',
          labelBn: 'দুটো খুলে তৃতীয়টা চালু রেখে চলে যাওয়া',
          asset: 'assets/game/art/m3_board34/three_two.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুটি নয়, তিনটিই খুলুন — একটা ফেজ চালু থাকলে ট্রান্সফরমার পুরো বিচ্ছিন্ন হয় না।',
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: 'বাকি দুটো ফিউজ চালু রেখে চলে যাওয়া',
          asset: 'assets/game/art/m3_board34/three_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটা ফিউজ উড়লে বাকি দুটো ফেজের ফিউজও খুলে দেওয়া নিয়ম — তবেই ট্রান্সফরমার পুরো বিচ্ছিন্ন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একটা উড়লে বাকি দুটো ফেজের ফিউজও খুলতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঝুলে পড়া ব্যারেল দূর থেকেই ফল্টের সংকেত দেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'তিনটে খুললে তবেই ট্রান্সফরমার পুরো বিচ্ছিন্ন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটা ফেজ খুললেই ট্রান্সফরমার পুরো বিচ্ছিন্ন', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'উড়ে যাওয়া ফিউজ সঙ্গে সঙ্গে আবার লাগিয়ে দিন', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ড্রপ-আউট ব্যারেল মানে লাইনে কোনো ফল্ট নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দুটো ফেজ খোলাই যথেষ্ট, তৃতীয়টা চালু থাক', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফিউজ উড়লে লাইনে কিছু খোঁজার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাকি দুটো ফেজ চালু রাখলে ক্ষতির ভয় নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'operate',
      promptBn: 'মাটি থেকে ডিও ফিউজ খুলবেন — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'open',
          labelBn: 'হট স্টিকে পাশে দাঁড়িয়ে ফিউজ খোলা',
          asset: 'assets/game/art/m3_board34/operate_open.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'steady',
          labelBn: 'খোলার শব্দেও স্টিক হাতে স্থির থাকা',
          asset: 'assets/game/art/m3_board34/operate_steady.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rod',
          labelBn: 'লোহার রড দিয়ে ফিউজ টেনে খোলা',
          asset: 'assets/game/art/m3_board34/operate_rod.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ রড নয় — ডিও ফিউজ খোলা বা লাগানোর সময় হট স্টিক ব্যবহার অপরিহার্য।',
        ),
        LearnBoardOption(
          id: 'under',
          labelBn: 'ব্যারেলের ঠিক নিচে দাঁড়িয়ে খোলা',
          asset: 'assets/game/art/m3_board34/operate_under.svg',
          scene: true,
          correct: false,
          rejectBn: 'হট স্টিকের সঙ্গে সঠিক শারীরিক অবস্থানও অপরিহার্য — খোলা ব্যারেল মাধ্যাকর্ষণে নিচেই ঝুলে পড়ে।',
        ),
        LearnBoardOption(
          id: 'bang',
          labelBn: 'শব্দে ভয় পেয়ে স্টিক ফেলে দেওয়া',
          asset: 'assets/game/art/m3_board34/operate_bang.svg',
          scene: true,
          correct: false,
          rejectBn: 'খোলার সময় ছোট বিস্ফোরণের মতো শব্দ স্বাভাবিক — বোরিক অ্যাসিডের গ্যাস আর্ককে বাইরে বের করে দেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ডিও খোলা-লাগানোয় হট স্টিক ব্যবহার অপরিহার্য', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হট স্টিকের সঙ্গে সঠিক শারীরিক অবস্থানও চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'খোলার সময় ছোট বিস্ফোরণের শব্দ স্বাভাবিক', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো লম্বা লোহার রডেই ডিও খোলা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছোট বিস্ফোরণের শব্দ মানে ফিউজটাই খারাপ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হট স্টিক থাকলে দাঁড়ানোর ভঙ্গি কোনো ব্যাপার না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হাতে ধরে টানলেই ডিও তাড়াতাড়ি খুলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শব্দ হলেই স্টিক ফেলে সরে যাওয়া নিয়ম', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ডিও ফিউজ কখনো সুইচ হিসেবে ব্যবহার হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'link',
      promptBn: 'ডিও ফিউজে নতুন ফিউজ লিঙ্ক লাগাবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'plate',
          labelBn: 'প্লেট দেখে অ্যাম্পিয়ার রেটিং মেলানো',
          asset: 'assets/game/art/m3_board34/link_plate.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'packet',
          labelBn: 'প্যাকেটের রেটেড ফিউজ লিঙ্ক নেওয়া',
          asset: 'assets/game/art/m3_board34/link_packet.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'thick',
          labelBn: 'রেটিংয়ের চেয়ে মোটা তামার তার',
          asset: 'assets/game/art/m3_board34/link_thick.svg',
          scene: true,
          correct: false,
          rejectBn: 'মোটা তার ওভারলোডে ফিউজ উড়তে দেয় না — ট্রান্সফরমারের মতো দামী সরঞ্জাম পুড়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'thin',
          labelBn: 'খুব সরু তার বারবার বাঁধা',
          asset: 'assets/game/art/m3_board34/link_thin.svg',
          scene: true,
          correct: false,
          rejectBn: 'খুব সরু তার স্বাভাবিক লোডেই বারবার উড়ে যাবে — প্লেটের রেটিং মিলিয়ে লিঙ্ক বাছুন।',
        ),
        LearnBoardOption(
          id: 'any',
          labelBn: 'বাড়ির তার কেটে লিঙ্ক বানানো',
          asset: 'assets/game/art/m3_board34/link_any.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ তার কখন গলবে তার কোনো নিশ্চয়তা নেই — ফিউজ লিঙ্কের গলনাঙ্ক নিখুঁতভাবে মাপা থাকে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ট্রান্সফরমার বা পোলের প্লেটে রেটিং লেখা থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মোটা তার ওভারলোডে ফিউজকে উড়তে দেয় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফিউজ লিঙ্কের গলনাঙ্ক নিখুঁতভাবে মাপা থাকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো ধাতব তার দিয়েই ফিউজ লিঙ্ক হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যত মোটা তার, ট্রান্সফরমার তত নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সরু তার স্বাভাবিক লোডে কখনো ওড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রেটিং সব ট্রান্সফরমারে একই, প্লেট দেখা বৃথা', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'K টাইপ ধীরগতির, আর T টাইপ দ্রুত কাটে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাড়ির তারও রেটেড লিঙ্কের মতোই গলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fit',
      promptBn: 'ব্যারেলে ফিউজ লিঙ্ক বেঁধে আবার লাগাবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'taut',
          labelBn: 'সোজা ও সঠিক টানে লিঙ্ক বাঁধা',
          asset: 'assets/game/art/m3_board34/fit_taut.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clean',
          labelBn: 'ওপর-নিচের কন্টাক্ট পরিষ্কার করা',
          asset: 'assets/game/art/m3_board34/fit_clean.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'ঢিলা লিঙ্ক, লেজ খোলা',
          asset: 'assets/game/art/m3_board34/fit_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঢিলা কানেকশনের ফিউজ ঠিকমতো কাজ করে না — লিঙ্ক সঠিক টানে বাঁধুন।',
        ),
        LearnBoardOption(
          id: 'kink',
          labelBn: 'গিঁট পাকানো লিঙ্ক',
          asset: 'assets/game/art/m3_board34/fit_kink.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুলভাবে বাঁধা ফিউজ ঠিকমতো কাজ করে না — সামান্য ভুলে বড় দুর্ঘটনা ঘটতে পারে।',
        ),
        LearnBoardOption(
          id: 'carbon',
          labelBn: 'কার্বন জমা কন্টাক্টেই লাগানো',
          asset: 'assets/game/art/m3_board34/fit_carbon.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্টাক্টে ময়লা বা কার্বন জমলে স্পার্কিং হয়ে কন্টাক্ট নষ্ট হয় — আগে পরিষ্কার করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লিঙ্ক সঠিকভাবে ও সঠিক টানে বাঁধা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কন্টাক্টে কার্বন জমলে স্পার্কিং হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঢিলা বা ভুলে বাঁধা ফিউজ ঠিক কাজ করে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লিঙ্ক একটু ঢিলা থাকলেই ভালো কাজ করে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কন্টাক্টে কার্বন থাকলে সংযোগ মজবুত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লিঙ্কে গিঁট দিলে ফিউজ বেশি টেকসই হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কন্টাক্ট পরিষ্কার করার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লিঙ্কের লেজ খোলা থাকলেও কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ময়লা কন্টাক্টে স্পার্কিং কখনো হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'horn',
      promptBn: 'হর্ন গ্যাপ ফিউজের তার গলে আর্ক জ্বলেছে — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'rise',
          labelBn: 'গরম বাতাসে আর্ক ওপরে উঠছে',
          asset: 'assets/game/art/m3_board34/horn_rise.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'out',
          labelBn: 'ওপরে ফাঁক বেড়ে আর্ক নিভছে',
          asset: 'assets/game/art/m3_board34/horn_out.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'down',
          labelBn: 'আর্ক নিচে ক্রস-আর্মের দিকে নামছে',
          asset: 'assets/game/art/m3_board34/horn_down.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্ক গরম বাতাসের সাথে ওপরের দিকে ওঠে — নিচে নামে না।',
        ),
        LearnBoardOption(
          id: 'stuck',
          labelBn: 'আর্ক নিচের সরু ফাঁকেই আটকে',
          asset: 'assets/game/art/m3_board34/horn_stuck.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্ক ওপরে ওঠে, আর হর্ন দুটির দূরত্ব বাড়তে থাকায় একসময় নিজেই নিভে যায়।',
        ),
        LearnBoardOption(
          id: 'parallel',
          labelBn: 'সমান্তরাল দুটো সোজা রডে আর্ক',
          asset: 'assets/game/art/m3_board34/horn_parallel.svg',
          scene: true,
          correct: false,
          rejectBn: 'হর্ন দুটি শিং-এর মতো ওপরে ছড়ানো — দূরত্ব বাড়তে থাকায় তবেই আর্ক নিজে নেভে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আর্ক গরম বাতাসের সাথে ওপরের দিকে ওঠে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হর্নের দূরত্ব বাড়লে আর্ক নিজেই নিভে যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বড় ফল্টে হর্ন গ্যাপ ফিউজ বিপজ্জনক হতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'হর্ন গ্যাপ ফিউজ ডিও-র চেয়ে বেশি নির্ভরযোগ্য', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'আর্ক নিচের দিকে নেমে মাটিতে মিশে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হর্ন গ্যাপের আর্ক নেভানোর ক্ষমতা অনেক বেশি', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্ক সবসময় নিচের সরু ফাঁকেই জ্বলতে থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'হর্ন দুটি জোড়া থাকে, মাঝে কোনো ফাঁক নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বড় ফল্টেও হর্ন গ্যাপ ফিউজ পুরো নিরাপদ', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board34Lines.rivalTaunt,
    rivalLineBn: M3Board34Lines.rivalMyth,
    exitBn: M3Board34Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ফিউজে মোটা তার',
      'ফল্ট না খুঁজেই আবার চালু',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'বারবার ফিউজ ওড়া মানে লাইনে কোনো ফল্ট আছে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'মোটা তারে ফিউজের সুরক্ষা কবচই নষ্ট হয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'মোটা তারে ট্রান্সফরমার বা পুরো লাইন পুড়তে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মোটা তার দিলে ফিউজ আর ওড়ে না, তাই সমাধান', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'বারবার ওড়া মানে শুধু ফিউজটাই দুর্বল ছিল', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ট্রান্সফরমার নিজেই ওভারলোড সামলে নেয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ফল্ট খোঁজার চেয়ে মোটা তার লাগানো সহজ পথ', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অভিজ্ঞ লাইনম্যান মোটা তারেই নিরাপদে চালায়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'মোটা তারে শুধু ফিউজ একটু গরম হয়, আর কিছু না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board34Lines {
  static const rivalTaunt = 'আরে, আবার ফিউজ উড়েছে! এত ঝামেলা কেন, মোটা তার আছে তো!';

  /// Lesson 3.4's first myth buster, word for word.
  static const rivalMyth = 'ফিউজ বারবার উড়ে যাচ্ছে, তাই একটা মোটা তার লাগিয়ে দিলেই সমস্যা সমাধান হয়ে যাবে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
