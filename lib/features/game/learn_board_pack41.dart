import 'learn_board_models.dart';

/// Module 4 Lesson 4.1 (পিন বা ডিস্ক ইনসুলেটর বদলানো), the picture board
/// (rung `4.1/learn`, pack `learn_4_1`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board41_art.py`. Every round
/// and every trap comes from the lesson text and its reviewed film script:
///  * prep: a valid PTW first; the line switched off and earthed from both
///    sides; the right new insulator, tools and binding wire; the pole and
///    cross-arm looked over before climbing;
///  * hold: once the old binding is opened the conductor is held on a rope or
///    other support so it neither drops nor goes near the next phase; it is
///    never held or pushed aside by hand (induced voltage). The second safe
///    card draws a rope over a block at the pole top — the lesson only says
///    "rope or other support";
///  * fit: the new insulator screwed tight on the pin; the conductor in the
///    top groove, bound tight with NEW binding wire, never loose; old / rusty
///    pins and nuts are changed too (pro tip);
///  * bypass: on a tension disc string the pull is first taken onto a
///    come-along + turnbuckle or ratchet puller from both sides of the string;
///    never opened under tension or by body strength (hundreds of kilos);
///  * disc: the new disc fitted cap to pin, its pin locked; the pull put back
///    slowly and only then the tools taken off; electrical puncture and
///    mechanical cracks are both checked.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack41 = LearnBoardPack(
  lessonId: '4.1',
  titleBn: 'পিন বা ডিস্ক ইনসুলেটর বদলানো',
  badgeBn: 'কাজের কারিগর',
  introBn: 'ভাঙা ইনসুলেটর লাইনে রাখা মানেই ফল্ট আর দুর্ঘটনা। সার্জনের মতো নিপুণ হাতে, নিয়ম মেনে বদলান।',
  earnedBn: 'PTW, দুই দিকে আর্থিং, সাপোর্টে কন্ডাক্টর, আগে লোড বাইপাস — তবেই ইনসুলেটর বদল।',
  slots: [
    LearnBoardSlot(
      id: 'prep',
      promptBn: 'ভাঙা ইনসুলেটর বদলাতে পোলে উঠবেন — ওঠার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'both',
          labelBn: 'PTW নিয়ে দুই দিকে আর্থিং, তারপর ওঠা',
          asset: 'assets/game/art/m4_board41/prep_both.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'inspect',
          labelBn: 'ওঠার আগে পোল আর ক্রস-আর্ম দেখে নেওয়া',
          asset: 'assets/game/art/m4_board41/prep_inspect.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'oneside',
          labelBn: 'শুধু এক দিকে আর্থিং দিয়েই ওঠা',
          asset: 'assets/game/art/m4_board41/prep_oneside.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইন সম্পূর্ণ বন্ধ করে দুই দিক থেকেই আর্থিং করতে হবে — এক দিকে আর্থ দিয়ে কাজ নয়।',
        ),
        LearnBoardOption(
          id: 'noearth',
          labelBn: 'আর্থিং ছাড়াই পোলে উঠে পড়া',
          asset: 'assets/game/art/m4_board41/prep_noearth.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রথম শর্ত: বৈধ PTW, লাইন সম্পূর্ণ বন্ধ, আর দুই প্রান্তে নিরেট আর্থিং — তারপর পোলে ওঠা।',
        ),
        LearnBoardOption(
          id: 'cracked',
          labelBn: 'ফাটা পোল-ক্রস-আর্ম না দেখেই ওঠা',
          asset: 'assets/game/art/m4_board41/prep_cracked.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোলে ওঠার আগে পোল আর ক্রস-আর্মের অবস্থা ভালো করে পরীক্ষা করে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বৈধ PTW নেওয়াই কাজের প্রথম ও জরুরি ধাপ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লাইন বন্ধ করে দুই দিক থেকেই আর্থিং করতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ওঠার আগে পোল ও ক্রস-আর্মের অবস্থা দেখে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সঠিক সাইজের নতুন ইনসুলেটর ও টুলস সঙ্গে নিন', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'এক দিকে আর্থিং দিলেই পুরো লাইন নিরাপদ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাইন বন্ধ থাকলে PTW নেওয়ার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্রস-আর্মের অবস্থা ওপরে উঠেই দেখে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টুলস কম পড়লে কাজের মাঝপথে জোগাড় করা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'অভিজ্ঞ হাতে পরিকল্পনা ছাড়াই কাজ শুরু করা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'hold',
      promptBn: 'পুরনো বাইন্ডিং খোলা হয়েছে — কন্ডাক্টর এখন কীভাবে ধরে রাখবেন?',
      options: [
        LearnBoardOption(
          id: 'arm',
          labelBn: 'দড়ির সাপোর্টে কন্ডাক্টর বেঁধে রাখা',
          asset: 'assets/game/art/m4_board41/hold_arm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'block',
          labelBn: 'পোলের মাথা থেকে দড়িতে ধরে রাখা',
          asset: 'assets/game/art/m4_board41/hold_block.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'খালি হাতে কন্ডাক্টর ধরে রাখা',
          asset: 'assets/game/art/m4_board41/hold_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ থাকতে পারে — কন্ডাক্টর খালি হাতে নয়, সাপোর্ট দিয়ে ধরুন।',
        ),
        LearnBoardOption(
          id: 'near',
          labelBn: 'কন্ডাক্টর পাশের ফেজের দিকে সরানো',
          asset: 'assets/game/art/m4_board41/hold_near.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ডাক্টর পাশের ফেজে লাগলে শর্ট সার্কিট (লাইন চালু থাকলে) বা অন্য বিপদ — সাপোর্টে ধরে রাখুন।',
        ),
        LearnBoardOption(
          id: 'drop',
          labelBn: 'সাপোর্ট ছাড়াই কন্ডাক্টর ছেড়ে দেওয়া',
          asset: 'assets/game/art/m4_board41/hold_drop.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাপোর্ট না দিলে কন্ডাক্টর নিচে পড়ে যায় — দড়ি বা অন্য সাপোর্টে আগে ধরে রাখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দড়ির সাপোর্টে কন্ডাক্টর নিচে পড়ে যায় না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সাপোর্ট থাকলে কন্ডাক্টর পাশের ফেজে যায় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ থাকতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লাইন বন্ধ, তাই খালি হাতে ধরলেও ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কন্ডাক্টর একটু পাশে সরিয়ে রাখাই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কন্ডাক্টর নিচে ঝুলে থাকলে কোনো বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দড়ির সাপোর্ট শুধু বড় লাইনের কাজে লাগে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বাইন্ডিং খোলার পর কন্ডাক্টর নিজেই বসে থাকে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পাশের ফেজ ছুঁলেও বন্ধ লাইনে কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fit',
      promptBn: 'নতুন পিন ইনসুলেটর লাগাবেন — কোন কাজটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'bind',
          labelBn: 'খাঁজে বসিয়ে নতুন তারে শক্ত বাঁধন',
          asset: 'assets/game/art/m4_board41/fit_bind.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'স্প্যানারে নতুন ইনসুলেটর পিনে টাইট',
          asset: 'assets/game/art/m4_board41/fit_tight.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'বাইন্ডিং ঢিলা রেখেই কাজ শেষ',
          asset: 'assets/game/art/m4_board41/fit_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'পিনের খাঁজে কন্ডাক্টরের বাইন্ডিং যেন একদম ঢিলা না থাকে — নিয়ম অনুযায়ী শক্ত করে বাঁধুন।',
        ),
        LearnBoardOption(
          id: 'old',
          labelBn: 'পুরনো বাইন্ডিং তার আবার জড়ানো',
          asset: 'assets/game/art/m4_board41/fit_old.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরনো তার নয় — নতুন বাইন্ডিং তার দিয়ে নিয়ম অনুযায়ী শক্ত করে বাঁধুন।',
        ),
        LearnBoardOption(
          id: 'wobble',
          labelBn: 'হেলে থাকা ইনসুলেটরেই তার বাঁধা',
          asset: 'assets/game/art/m4_board41/fit_wobble.svg',
          scene: true,
          correct: false,
          rejectBn: 'নতুন ইনসুলেটর আগে পিনের ওপর ভালোভাবে টাইট করে লাগান, তারপর কন্ডাক্টর বাঁধুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কন্ডাক্টর বসে ইনসুলেটরের মাথার খাঁজে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'নতুন বাইন্ডিং তার দিয়ে শক্ত করে বাঁধতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মরিচা ধরা নাট-বল্টু ও পিনও বদলে দিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বাইন্ডিং একটু ঢিলা রাখলে তার সহজে নড়ে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পুরনো বাইন্ডিং তার আবার জড়ালেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নতুন ইনসুলেটর পিনে হালকা বসালেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কন্ডাক্টর খাঁজের বাইরে রাখলেও সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মরিচা ধরা পিন নতুন ইনসুলেটরেও চলে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাঁধার নিয়ম না মানলেও তার বসে থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'bypass',
      promptBn: 'টেনশন স্ট্রিংয়ের একটা ডিস্ক ভাঙা — খোলার আগে কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'comealong',
          labelBn: 'কাম-অ্যালং ও টার্ন-বাকেলে লোড বাইপাস',
          asset: 'assets/game/art/m4_board41/bypass_comealong.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ratchet',
          labelBn: 'র‍্যাচেট পুলারে টান টুলের ওপর নেওয়া',
          asset: 'assets/game/art/m4_board41/bypass_ratchet.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nobypass',
          labelBn: 'পুরো টানের মধ্যেই স্প্লিট-পিন খোলা',
          asset: 'assets/game/art/m4_board41/bypass_nobypass.svg',
          scene: true,
          correct: false,
          rejectBn: 'টেনশন স্ট্রিং প্রচণ্ড টানে থাকে — লোড বাইপাস না করে খোলা মারাত্মক ভুল, ভয়ংকর দুর্ঘটনা ঘটতে পারে।',
        ),
        LearnBoardOption(
          id: 'muscle',
          labelBn: 'গায়ের জোরে তার টেনে স্ট্রিং খোলা',
          asset: 'assets/game/art/m4_board41/bypass_muscle.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্ট্রিং কয়েকশ কেজি টানে থাকে — গায়ের জোরে অসম্ভব ও বিপজ্জনক, সঠিক টুলস অপরিহার্য।',
        ),
        LearnBoardOption(
          id: 'half',
          labelBn: 'শুধু কন্ডাক্টরে ক্ল্যাম্প আটকানো',
          asset: 'assets/game/art/m4_board41/bypass_half.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাম-অ্যালং আর টার্ন-বাকেল স্ট্রিংয়ের দুই পাশ থেকে জুড়ুন — তবেই টান টুলের ওপর আসে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে লোড স্ট্রিং থেকে সরিয়ে টুলের ওপর আনুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টুল জুড়তে হয় স্ট্রিংয়ের দুই পাশ থেকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'টেনশন স্ট্রিং কয়েকশ কেজি টানে থাকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গায়ের জোরে টেনেই টেনশন স্ট্রিং খোলা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'স্প্লিট-পিন খুললে টান নিজেই কমে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কাম-অ্যালং শুধু নতুন লাইন টানতে লাগে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'এক পাশে ক্ল্যাম্প আটকালেই লোড বাইপাস হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বন্ধ লাইনে স্ট্রিংয়ের কোনো টান থাকে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ভাঙা ডিস্ক টানের মধ্যেই খুলে নেওয়া যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'disc',
      promptBn: 'স্ট্রিংয়ে নতুন ডিস্ক বসানো হচ্ছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'capfit',
          labelBn: 'ক্যাপ-পিন মিলিয়ে ডিস্ক, পিন আটকানো',
          asset: 'assets/game/art/m4_board41/disc_capfit.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'release',
          labelBn: 'ধীরে টার্ন-বাকেল ছেড়ে টান ফেরানো',
          asset: 'assets/game/art/m4_board41/disc_release.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nosplit',
          labelBn: 'স্প্লিট-পিন ছাড়াই ডিস্ক জোড়া',
          asset: 'assets/game/art/m4_board41/disc_nosplit.svg',
          scene: true,
          correct: false,
          rejectBn: 'নতুন ডিস্ক ক্যাপ ও পিন মিলিয়ে সঠিক দিকে লাগান, তারপর পিন সুরক্ষিতভাবে আটকে দিন।',
        ),
        LearnBoardOption(
          id: 'yank',
          labelBn: 'টান না ফিরিয়েই টুলস খুলে ফেলা',
          asset: 'assets/game/art/m4_board41/disc_yank.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে ধীরে ধীরে টার্ন-বাকেল রিলিজ করে টান স্ট্রিংয়ে ফেরান — তারপর টুলস খুলুন।',
        ),
        LearnBoardOption(
          id: 'cracked',
          labelBn: 'ফাটা পুরনো ডিস্ক আবার লাগানো',
          asset: 'assets/game/art/m4_board41/disc_cracked.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইলেকট্রিক্যাল পাংচার আর মেকানিক্যাল ফাটল — দুটোই পরীক্ষা করুন; ক্ষতিগ্রস্ত ডিস্ক বদলাতেই হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নতুন ডিস্ক বসে ক্যাপ আর পিন মিলিয়ে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টান ফেরাতে হয় ধীরে ধীরে, তারপর টুল খোলা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ডিস্কে পাংচার ও ফাটল দুটোই দেখে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'টার্ন-বাকেল এক ঝটকায় ছাড়লে কাজ দ্রুত হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'স্প্লিট-পিন না দিলেও ডিস্ক আটকে থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফাটা ডিস্কে কাজ চলে যায়, রেখে দিন', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ডিস্ক যেকোনো দিকে লাগালেই একই কাজ করে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টান ফেরানোর আগেই টুলস খুলে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বাইরে থেকে না ফাটলে ডিস্ক নিশ্চিত ভালো', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board41Lines.rivalTaunt,
    rivalLineBn: M4Board41Lines.rivalMyth,
    exitBn: M4Board41Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'খালি হাতে কন্ডাক্টর',
      'পাশের চালু লাইন',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'বন্ধ লাইনেও ইন্ডুসড ভোল্টেজ থাকতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'হাত ফসকে কন্ডাক্টর পাশের চালু লাইনে লাগতে পারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'সবসময় নিয়ম মেনে দড়ি বা সাপোর্ট ব্যবহার করুন', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'লাইন বন্ধ মানেই তারে কোনো ভোল্টেজ থাকে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'কন্ডাক্টর পাশে সরিয়ে রাখলে কোনো বিপদ নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'সাপোর্ট বাঁধা শুধু চালু লাইনের কাজে লাগে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ হাত থেকে কন্ডাক্টর কখনো ছুটে যায় না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'পাশের লাইন চালু থাকলেও ছোঁয়ায় কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'খালি হাতে ধরলে কাজ অনেক দ্রুত শেষ হয়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board41Lines {
  static const rivalTaunt = 'আরে, লাইন তো বন্ধ! দড়ি বাঁধার ঝামেলা কেন?';

  /// Lesson 4.1's first myth buster, word for word.
  static const rivalMyth = 'লাইন তো বন্ধই আছে, তাই কন্ডাক্টরটা হাত দিয়ে ধরলে বা পাশে সরিয়ে রাখলে কিছু হবে না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
