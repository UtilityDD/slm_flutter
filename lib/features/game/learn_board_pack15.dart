import 'learn_board_models.dart';

/// Ladder step 13 — Module 1 Lesson 1.5 (ডিসচার্জ রড ব্যবহারের কায়দা), the
/// picture board (mode like steps 7 and 10).
///
/// Picture cards are vector scenes from `tool/rod_board_art.py`. Every round
/// and every trap comes from the lesson text:
///  * the rod's rating label must match the line voltage on the docket — an
///    11 kV rod on a 33 kV line is suicide, never a lower rating; no PVC-pipe
///    jugaad (it can crack, leak when wet or dirty; not a certified rod);
///  * the 30-second check before every use — insulating stick clean, dry and
///    crack-free; copper cable's insulation not cut or torn, both end
///    connections firm; clamp and hook clean with a firm grip;
///  * a dead line can hold capacitive charge and induced voltage: the permit
///    is a process, discharging is the physical safety — discharge the three
///    phases yourself; put the work off in wet or stormy weather;
///  * earth first, then the line: the earth clamp first on a reliable
///    earthing point (earth rod, the pole's earthing strip); a rusty or loose
///    earth does not work; hook first sends the charge through the body;
///  * the brass/copper shorting chain after the rod, never instead of it; no
///    rusty / broken / iron chain; never bare-handed on an unverified line.
/// The rival's myth is the lesson's own: "লাইন তো মাত্র 5 মিনিটের জন্য বন্ধ…".
const learnBoardPack15 = LearnBoardPack(
  lessonId: '1.5',
  titleBn: 'ডিসচার্জ রড ব্যবহারের কায়দা',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'ঘুমন্ত বাঘও বাঘ — বন্ধ লাইনেও লুকানো চার্জ থাকতে পারে। ঠিক রড, ঠিক ক্রম চিনুন।',
  earnedBn: 'আগে মাটি, পরে লাইন — রেটিং মিলিয়ে, রড দেখে, তারপর চেইন।',
  slots: [
    LearnBoardSlot(
      id: 'pick',
      promptBn: 'ডকেটে লাইনের ভোল্টেজ লেখা — কোন রড নেবেন?',
      options: [
        LearnBoardOption(id: 'ok33', labelBn: 'ডকেট 33 kV, রড 33 kV', asset: 'assets/game/art/rod_board/pick_33_ok.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok11', labelBn: 'ডকেট 11 kV, রড 11 kV', asset: 'assets/game/art/rod_board/pick_11_ok.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'low',
          labelBn: 'ডকেট 33 kV, রড 11 kV',
          asset: 'assets/game/art/rod_board/pick_33_low.svg',
          scene: true,
          correct: false,
          rejectBn: '11 kV রড 33 kV লাইনে ব্যবহার করা আত্মহত্যার সামিল — রেটিং মিলিয়ে নিন।',
        ),
        LearnBoardOption(
          id: 'lt',
          labelBn: 'ডকেট 11 kV, রড LT',
          asset: 'assets/game/art/rod_board/pick_11_lt.svg',
          scene: true,
          correct: false,
          rejectBn: 'নিচু রেটিংয়ের রড কখনোই নয় — 11 kV লাইনে 11 kV রেটেড রড চাই।',
        ),
        LearnBoardOption(
          id: 'pvc',
          labelBn: 'পিভিসি পাইপের জুগাড়',
          asset: 'assets/game/art/rod_board/pick_33_pvc.svg',
          scene: true,
          correct: false,
          rejectBn: 'পিভিসি জুগাড় সার্টিফায়েড রড নয় — ফাটতে পারে, ভেজা-ময়লায় লিক হতে পারে।',
        ),
        LearnBoardOption(
          id: 'pvc_taped',
          labelBn: 'টেপ জোড়া পিভিসি রড',
          asset: 'assets/game/art/rod_board/pick_11_pvc.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্লাস্টিক দেখে নিরাপদ ভাবা ভুল — স্ট্যান্ডার্ড রড আর সঠিক রেটিং ছাড়া ডিসচার্জ নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রডের রেটিং ডকেটের ভোল্টেজের সঙ্গে মিলতে হবে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পরীক্ষিত স্টিক আর সঠিক রেটিং ছাড়া ডিসচার্জ নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'যেকোনো ডিসচার্জ রড সব লাইনেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'লাইন তো বন্ধ, তাই রেটিং দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পিভিসি তো প্লাস্টিক, তাই ওটাতেই কাজ চলবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নিচু রেটিংয়ের রড একটু সাবধানে চালালেই হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রডের লেবেল শুধু স্টোরের হিসাব রাখার জন্য', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'check',
      promptBn: 'রড হাতে নিলেন — 30 সেকেন্ডের চেকে কোনটা পাস?',
      options: [
        LearnBoardOption(id: 'stick_ok', labelBn: 'পরিষ্কার, শুকনো, অক্ষত স্টিক', asset: 'assets/game/art/rod_board/check_stick_ok.svg', scene: true, correct: true),
        LearnBoardOption(id: 'clamp_ok', labelBn: 'মজবুত ক্ল্যাম্প ও কানেকশন', asset: 'assets/game/art/rod_board/check_clamp_ok.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'ফাটা স্টিক',
          asset: 'assets/game/art/rod_board/check_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফাটা ইনসুলেটিং স্টিক নিজেই বিদ্যুৎ পরিবাহী হয়ে উঠতে পারে।',
        ),
        LearnBoardOption(
          id: 'dirty',
          labelBn: 'কাদা মাখা ভেজা স্টিক',
          asset: 'assets/game/art/rod_board/check_dirty.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্টিক হবে পরিষ্কার আর শুকনো — ময়লা বা ভেজা রড বিপজ্জনক।',
        ),
        LearnBoardOption(
          id: 'cable_cut',
          labelBn: 'কাটা কেবিল',
          asset: 'assets/game/art/rod_board/check_cable_cut.svg',
          scene: true,
          correct: false,
          rejectBn: 'কপার কেবিলের ইনসুলেশন কাটা বা ছেঁড়া — এমন রড চলবে না।',
        ),
        LearnBoardOption(
          id: 'clamp_loose',
          labelBn: 'আলগা ক্ল্যাম্প, খোলা কানেকশন',
          asset: 'assets/game/art/rod_board/check_clamp_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ল্যাম্পের গ্রিপ আর কেবিলের দুই প্রান্তের কানেকশন মজবুত হতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রতিবার ব্যবহারের আগে পুরো রড সেট দেখা চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'স্টিক শুকনো, কেবিল আর ক্ল্যাম্প মজবুত চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'স্টিকে ছোট ফাটলে রডের কিছুই যায় আসে না', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'কেবিল একটু কাটা থাকলেও দিব্যি কাজ চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ভেজা স্টিক আরও ভালো করে চার্জ নামায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ক্ল্যাম্প আলগা হলেও হাতে চেপে রাখা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নতুন রড হলে চেক করার দরকার পড়ে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'dead',
      promptBn: 'পারমিট হাতে, লাইন বন্ধ — কাজের আগে কোনটা?',
      options: [
        LearnBoardOption(id: 'rod_strip', labelBn: 'আগে রড দিয়ে ডিসচার্জ', asset: 'assets/game/art/rod_board/dead_rod_strip.svg', scene: true, correct: true),
        LearnBoardOption(id: 'rod_spike', labelBn: 'আর্থ রডে ক্ল্যাম্প, তারে হুক', asset: 'assets/game/art/rod_board/dead_rod_spike.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'রড ছাড়াই তারে হাত',
          asset: 'assets/game/art/rod_board/dead_touch.svg',
          scene: true,
          correct: false,
          rejectBn: 'বন্ধ লাইনেও জমা চার্জ মারাত্মক শক দিতে পারে — আগে তিন ফেজ ডিসচার্জ।',
        ),
        LearnBoardOption(
          id: 'permit',
          labelBn: 'পারমিট হাতে সোজা ওঠা',
          asset: 'assets/game/art/rod_board/dead_permit.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট একটা প্রক্রিয়া মাত্র — নিজের হাতে তিন ফেজ ডিসচার্জ না করা পর্যন্ত লাইন লাইভ ধরুন।',
        ),
        LearnBoardOption(
          id: 'rain',
          labelBn: 'ঝড়-বৃষ্টিতে রড লাগানো',
          asset: 'assets/game/art/rod_board/dead_rain.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেজা রড বা ইনসুলেটর বিপজ্জনক — ভেজা বা ঝড়ো আবহাওয়ায় কাজ স্থগিত করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বন্ধ লাইনেও ক্যাপাসিটিভ চার্জ জমে থাকতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পাশের চালু লাইন বন্ধ লাইনে ভোল্টেজ আনতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পারমিট শুধু প্রক্রিয়া, ডিসচার্জই আসল সুরক্ষা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'পারমিট পেলেই লাইন পুরোপুরি নিরাপদ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বন্ধ লাইনে কোনো বিপদ থাকতেই পারে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বৃষ্টিতে রড লাগালে চার্জ আরও তাড়াতাড়ি নামে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কন্ট্রোল রুম বলেছে, তাই যাচাই লাগে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছোট্ট স্পার্ক মানেই রডটা খারাপ হয়ে গেছে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'order',
      promptBn: 'পোলের নিচে রড হাতে — প্রথম কাজটা কে ঠিক করছেন?',
      options: [
        LearnBoardOption(id: 'strip', labelBn: 'আগে আর্থিং স্ট্রিপে ক্ল্যাম্প', asset: 'assets/game/art/rod_board/order_strip.svg', scene: true, correct: true),
        LearnBoardOption(id: 'spike', labelBn: 'আগে আর্থ রডে ক্ল্যাম্প', asset: 'assets/game/art/rod_board/order_spike.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'hook_first',
          labelBn: 'আগে তারে হুক',
          asset: 'assets/game/art/rod_board/order_hook_first.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে লাইনে হুক দিলে জমা চার্জ আপনার শরীর দিয়ে মাটিতে যেতে চায় — মুহূর্তে মৃত্যু হতে পারে।',
        ),
        LearnBoardOption(
          id: 'soil',
          labelBn: 'মাটিতে ক্ল্যাম্প ফেলে রাখা',
          asset: 'assets/game/art/rod_board/order_soil.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ল্যাম্প লাগাতে হয় নির্ভরযোগ্য আর্থিং পয়েন্টে — আর্থ রড বা পোলের আর্থিং স্ট্রিপে।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'মরিচা ধরা আর্থে ক্ল্যাম্প',
          asset: 'assets/game/art/rod_board/order_rust.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধরা বা আলগা কানেকশনে আর্থিং ঠিকমতো কাজ করে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে মাটি, পরে লাইন — এর কোনো ব্যতিক্রম নেই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'উল্টো করলে চার্জ শরীর দিয়ে মাটিতে নামতে চায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে তারে হুক লাগালে কাজ তাড়াতাড়ি হয়', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'ক্ল্যাম্প আগে না পরে, তাতে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মরিচা ধরা আর্থেও চার্জ ঠিকঠাক নেমে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'স্পার্ক ভালো দেখতে আগে লাইনে ছোঁয়ানো ভালো', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্ল্যাম্প মাটিতে ফেলে রাখলেই আর্থিং হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'chain',
      promptBn: 'ডিসচার্জ শেষ — শর্টিং চেইন কীভাবে?',
      options: [
        LearnBoardOption(id: 'rod_chain', labelBn: 'রড লাগানো, তারপর চেইন', asset: 'assets/game/art/rod_board/chain_rod.svg', scene: true, correct: true),
        LearnBoardOption(id: 'rod_throw', labelBn: 'রডের পর চেইন ছোড়া', asset: 'assets/game/art/rod_board/chain_rod_throw.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'chain_only',
          labelBn: 'রড ছাড়া শুধু চেইন',
          asset: 'assets/game/art/rod_board/chain_only.svg',
          scene: true,
          correct: false,
          rejectBn: 'চেইন রডের বদলি নয় — চেইন শুধু ফেজ শর্ট করে, চার্জ নামায় রড।',
        ),
        LearnBoardOption(
          id: 'iron',
          labelBn: 'মরিচা ধরা ভাঙা লোহার চেইন',
          asset: 'assets/game/art/rod_board/chain_iron.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধরা, ভাঙা বা লোহার জুগাড় চেইন নয় — শুধু পরিষ্কার ব্রাস/কপার চেইন।',
        ),
        LearnBoardOption(
          id: 'hand',
          labelBn: 'খালি হাতে চেইন ধরা',
          asset: 'assets/game/art/rod_board/chain_hand.svg',
          scene: true,
          correct: false,
          rejectBn: 'যাচাই না করা লাইনে খালি হাতে চেইন নয় — আগে ডিসচার্জ রড, তারপর চেইন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'রড চার্জ নামায়, চেইন শুধু ফেজ শর্ট রাখে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শর্ট সার্কিট মানেই আর্থিং নয় — দুটোই চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চেইন থাকলে ডিসচার্জ রড আর লাগে না', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'লোহার চেইনও ব্রাসের মতোই কাজ করে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মরিচা ধরা চেইনেও শর্ট ঠিকঠাক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যাচাই ছাড়াই আগে চেইন ছুঁড়ে দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চেইন খালি হাতে ধরলে কোনো ক্ষতি নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: RodBoardLines.rivalTaunt,
    rivalLineBn: RodBoardLines.rivalMyth,
    exitBn: RodBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'শুনলেন তো ওর কথা? সত্যি কি ওর এই বিপজ্জনক কথায় কান দেবেন?',
    dangerHints: [
      'ডিসচার্জ না করেই লাইনে হাত',
      'জমা চার্জে মারাত্মক শক লাগতে পারে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'চার্জ ও ইন্ডুসড ভোল্টেজ মুহূর্তে তৈরি হতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'সময় যত কমই হোক, ডিসচার্জ বাধ্যতামূলক', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'পারমিট প্রক্রিয়া মাত্র, ডিসচার্জই সুরক্ষা', correct: true),
      LearnWhyChip(id: 'm4', textBn: '5 মিনিটে কোনো লাইনে চার্জ জমতে পারে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'লাইন বন্ধ মানেই তারে আর কোনো বিপদ নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'পারমিট হাতে থাকলে আর ডিসচার্জ লাগে না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ডিসচার্জ শুধু লম্বা শাটডাউনেই দরকার হয়', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board, in his recorded voice
/// (`r_<sha1>.mp3` in `learnRivalVoice`). The guide's lines stay in the pack
/// (device TTS until the owner records them).
abstract final class RodBoardLines {
  static const rivalTaunt = 'আরে! পারমিট তো হাতেই, লাইন বন্ধ — রড-টড কীসের?';

  /// Lesson 1.5's myth buster, word for word (digits in English).
  static const rivalMyth = 'লাইন তো মাত্র 5 মিনিটের জন্য বন্ধ করা হয়েছে, এর মধ্যে আর কী চার্জ জমবে? ডিসচার্জ করার দরকার নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// The new clips this board added.
  static const recorded = [rivalTaunt, rivalMyth];
}
