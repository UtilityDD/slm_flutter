import 'learn_board_models.dart';

/// Module 6 Lesson 6.7 (ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার), the picture board
/// (rung `6.7/learn`, pack `learn_6_7`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board67_art.py` (no words in
/// the art; the labels a worker reads — a meter's A / kW / V / PF and its
/// figures, a stopwatch — are drawn as stroke glyphs with English digits).
/// Every round and trap comes from the live lesson text and the Module 6
/// rulings (`docs/module_specs/module6_rulings.md`, item spec
/// `docs/module_specs/module6_items/board_67.json`):
///  * pf: low power factor = the line carries more current (kVA) for the same
///    work (kW); the bank cuts that extra current, so I²R loss and voltage
///    drop fall and the transformer and line get room for load (point 1).
///    PF 1.0 ideal, 0.8 the lesson's low example. The meter figures are
///    illustrative (spec unsupported[0]);
///  * build: cans in star or delta; every bank has its own dedicated switch and
///    fuse (point 2); not switched ON-OFF often, a special switch that takes
///    the switching surge (pro tip 2); APFC switches the bank by load (pro tip
///    4);
///  * wait: switched OFF, the bank holds a dangerous voltage like a charged
///    battery; at least 5-10 minutes' wait, then the discharge rod — its earth
///    on first, then the hook (lesson 1.5, R9) — even after the wait; a bank is
///    never an ordinary load (point 3 and its safety tip; ruling M6-6: the
///    minimum is 5 minutes, the board quotes the lesson's 5-10);
///  * earthed: myth 1 — a bank fitted after the line's fuse can stay charged
///    with the line earthed, so discharge it separately and directly; myth 2 —
///    size does not measure danger, even a small power capacitor (R8). Every
///    card shows the bank's fuse dropped open (the bank cut off from the
///    earthed line);
///  * patrol: a swollen or leaking unit can burst — cut it off the line at
///    once (R11, slip in the Do levels: ruling M6-5); a blown fuse is not
///    refitted before the cause is found (R33); internal fuses blow unseen
///    (pro tip 1: the 'outer' trap shows one can cold — no heat shimmer,
///    frost — yet the outer fuses are taken as proof). A sound bank, every can
///    warm, is passed (no needless report, R32). The safe 'cause' card looks
///    for the cause from the ground — no tool near a can (ruling M6-6).
///    The spec's fourth trap (an old rusty bank taken as new) left the round:
///    a round holds 4-6 cards (rulings, 'Owner answers after Wave A').
/// The rival's myth is the lesson's first myth, word for word.
///
/// Term rules (owner, after Wave A): switch states ON / OFF (the lesson's
/// 'অন-অফ' and 'সুইচ অফ' are written ON-OFF / OFF here), English digits.
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack67 = LearnBoardPack(
  lessonId: '6.7',
  titleBn: 'ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার',
  badgeBn: 'যন্ত্র গুরু',
  introBn: 'ক্যাপাসিটর ব্যাংক লাইনের বাড়তি কারেন্ট কমায়, কিন্তু সুইচ OFF-এর পরও চার্জ ধরে রাখে। চিনে নিন।',
  earnedBn: 'সুইচ OFF, 5-10 মিনিট অপেক্ষা, আর্থ দেওয়া রডে প্রতিটি টার্মিনাল — তবেই ব্যাংকে হাত; ফোলা ক্যান লাইন থেকে সরান।',
  slots: [
    LearnBoardSlot(
      id: 'pf',
      promptBn: 'পাওয়ার ফ্যাক্টর কম — ক্যাপাসিটর ব্যাংক চালু হলে লাইনে কী হয়?',
      options: [
        LearnBoardOption(
          id: 'amps',
          labelBn: 'ব্যাংক চালু: অ্যামিটার নামল, kW একই',
          asset: 'assets/game/art/m6_board67/pf_amps.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'volt',
          labelBn: 'লাইনের শেষ মাথায় ভোল্টেজ আর অত নামছে না',
          asset: 'assets/game/art/m6_board67/pf_volt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'load',
          labelBn: 'ট্রান্সফরমারের লোড বার নেমে জায়গা হলো',
          asset: 'assets/game/art/m6_board67/pf_load.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'kw',
          labelBn: 'ব্যাংক চালু হতেই kW মিটার লাফিয়ে উঠল',
          asset: 'assets/game/art/m6_board67/pf_kw.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্যাপাসিটর আসল কাজ (kW) বাড়ায় না — রিয়্যাক্টিভ পাওয়ার জুগিয়ে বাড়তি কারেন্ট (kVA) কমায়।',
        ),
        LearnBoardOption(
          id: 'hot',
          labelBn: 'ব্যাংক চালু হতেই অ্যামিটার উঠল, তার গরম',
          asset: 'assets/game/art/m6_board67/pf_hot.svg',
          scene: true,
          correct: false,
          rejectBn: 'কম পাওয়ার ফ্যাক্টরেই লাইনে বেশি কারেন্ট বয় — ক্যাপাসিটর সেই বাড়তি কারেন্ট কমায়, I²R লস কমে।',
        ),
        LearnBoardOption(
          id: 'pfdown',
          labelBn: 'ব্যাংক চালু হতেই PF কাঁটা 0.8-এর নিচে',
          asset: 'assets/game/art/m6_board67/pf_pfdown.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্যাপাসিটর পাওয়ার ফ্যাক্টর উন্নত করে — আদর্শ 1.0-এর দিকে তোলে, নিচে নামায় না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'একই kW-এর জন্য লাইনে কারেন্ট কমে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কারেন্ট কমলে I²R লস আর ভোল্টেজ ড্রপ কমে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ট্রান্সফরমার আর লাইনে লোড নেওয়ার জায়গা বাড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ক্যাপাসিটর লাইনের আসল কাজ kW বাড়িয়ে দেয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ব্যাংক চালু হলে লাইনে কারেন্ট আরও বাড়ে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ক্যাপাসিটর পাওয়ার ফ্যাক্টর নিচে নামিয়ে আনে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পাওয়ার ফ্যাক্টর কম থাকাই লাইনের পক্ষে ভালো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ব্যাংক চালু হলে কন্ডাক্টর আরও গরম হয়ে ওঠে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ক্যাপাসিটর আসলে শুধু ভোল্টেজ মাপার যন্ত্র', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'build',
      promptBn: 'ব্যাংকের গঠন, সুইচ আর সুরক্ষা — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'star',
          labelBn: 'ক্যান স্টারে জোড়া, নিজস্ব সুইচ আর ফিউজ',
          asset: 'assets/game/art/m6_board67/build_star.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'delta',
          labelBn: 'ক্যান ডেল্টায় জোড়া, নিজস্ব সুইচ আর ফিউজ',
          asset: 'assets/game/art/m6_board67/build_delta.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'apfc',
          labelBn: 'APFC প্যানেল লোড বুঝে নিজেই ধাপ জোড়ে',
          asset: 'assets/game/art/m6_board67/build_apfc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'direct',
          labelBn: 'সুইচ-ফিউজ ছাড়াই ক্যান সোজা লাইনে জোড়া',
          asset: 'assets/game/art/m6_board67/build_direct.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রতিটি ক্যাপাসিটর ব্যাংকের সাথে একটি ডেডিকেটেড সুইচ আর ফিউজ থাকে — এটাই ফল্ট থেকে রক্ষা করে।',
        ),
        LearnBoardOption(
          id: 'hourly',
          labelBn: 'ঘণ্টায় ঘণ্টায় হাতে ব্যাংক ON-OFF করা',
          asset: 'assets/game/art/m6_board67/build_hourly.svg',
          scene: true,
          correct: false,
          // Lesson 6.7 pro tip 2 (term rule: ON-OFF for 'অন-অফ').
          rejectBn: 'ক্যাপাসিটর ব্যাংককে ঘন ঘন ON-OFF করা উচিত নয়।',
        ),
        LearnBoardOption(
          id: 'domestic',
          labelBn: 'বাড়ির সাধারণ সুইচ দিয়ে ব্যাংক চালানো',
          asset: 'assets/game/art/m6_board67/build_domestic.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যাংকের জন্য বিশেষ সুইচ বা ব্রেকার লাগে, যা সুইচিং সার্জ সহ্য করতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রতিটি ব্যাংকের নিজস্ব সুইচ আর ফিউজ থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্যানগুলো স্টার বা ডেল্টায় জুড়ে দেওয়া হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'APFC লোড বুঝে নিজেই ব্যাংক ON-OFF করে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ব্যাংকের বিশেষ সুইচ সুইচিং সার্জ সইতে পারে', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'সুইচ-ফিউজ ছাড়া ক্যান সোজা লাইনেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ব্যাংক যত ঘন ঘন ON-OFF হয়, তত ভালো', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বাড়ির সাধারণ সুইচেই ব্যাংক চালানো যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফিউজ থাকলে ব্যাংকের সুইচের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ক্যান যেমন খুশি জুড়লেই ব্যাংক চলে যায়', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'APFC থাকলে ব্যাংকে আর ফিউজ লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'wait',
      promptBn: 'ব্যাংকের সুইচ OFF হলো — এরপর কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'watch',
          labelBn: 'সুইচ OFF, দূরে দাঁড়িয়ে ঘড়ি ধরে অপেক্ষা',
          asset: 'assets/game/art/m6_board67/wait_watch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rod',
          labelBn: 'অপেক্ষার পর আর্থ দেওয়া রড টার্মিনালে',
          asset: 'assets/game/art/m6_board67/wait_rod.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'সুইচ OFF হতেই খালি হাতে টার্মিনাল ধরা',
          asset: 'assets/game/art/m6_board67/wait_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'সুইচ OFF-এর পরও ক্যাপাসিটর চার্জ করা ব্যাটারির মতো বিপজ্জনক ভোল্টেজ ধরে রাখে — ডিসচার্জ না করে ছুঁলে প্রাণঘাতী শক।',
        ),
        LearnBoardOption(
          id: 'early',
          labelBn: 'সুইচ নামতে না নামতেই রডের হুক টার্মিনালে',
          asset: 'assets/game/art/m6_board67/wait_early.svg',
          scene: true,
          correct: false,
          rejectBn: 'সুইচ OFF করার পর কাজের আগে কমপক্ষে 5-10 মিনিট অপেক্ষা বাধ্যতামূলক — তারপর রড।',
        ),
        LearnBoardOption(
          id: 'norod',
          labelBn: '10 মিনিট পেরিয়েছে, রড ছাড়াই হাত দেওয়া',
          asset: 'assets/game/art/m6_board67/wait_norod.svg',
          scene: true,
          correct: false,
          // Lesson sentence + DRAFT tail (owner): the rod is the protection, not
          // an extra (rulings M6-5 / M6-6) — a hand without it is deadly.
          rejectBn: 'অপেক্ষার পরেও উপযুক্ত ডিসচার্জ রডে টার্মিনাল ডিসচার্জ আর আর্থিং করে নিতে হয় — রড ছাড়া হাত দেওয়া প্রাণঘাতী।',
        ),
        LearnBoardOption(
          id: 'load',
          labelBn: 'সাধারণ লোড ভেবে সোজা স্প্যানার লাগানো',
          asset: 'assets/game/art/m6_board67/wait_load.svg',
          scene: true,
          correct: false,
          // Lesson 6.7 point 3 safety tip.
          rejectBn: 'ক্যাপাসিটর ব্যাংক সাধারণ লোড নয় — এটি একটি শক্তি সঞ্চয়কারী ডিভাইস।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সুইচ OFF-এর পরও ক্যাপাসিটর চার্জ ধরে রাখে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজের আগে কমপক্ষে 5-10 মিনিট অপেক্ষা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'অপেক্ষার পরও রডে ডিসচার্জ আর আর্থিং', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'রডের আর্থ আগে, তারপর হুক টার্মিনালে', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'সুইচ OFF হলেই ক্যাপাসিটর পুরো খালি হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: '10 মিনিট পেরোলে রড ছাড়াই হাত দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্যাপাসিটর ব্যাংক বাতির মতোই সাধারণ লোড', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সুইচ নামার সাথে সাথেই রড লাগানো ভালো', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'গ্লাভস থাকলে টার্মিনাল এখনই ধরা যায়', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'হুক আগে, রডের আর্থ পরে দিলেও চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'earthed',
      promptBn: 'লাইন বন্ধ, লাইনে আর্থ লাগানো — ব্যাংকে হাত দেওয়ার আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'own',
          labelBn: 'লাইনে আর্থ, তবু ব্যাংকের টার্মিনালে আলাদা রড',
          asset: 'assets/game/art/m6_board67/earthed_own.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'small',
          labelBn: 'ছোট ক্যাপাসিটরেও হাতের আগে রড ছোঁয়ানো',
          asset: 'assets/game/art/m6_board67/earthed_small.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'trust',
          labelBn: 'লাইনে আর্থ দেখে রড ছাড়াই ক্যানে হাত',
          asset: 'assets/game/art/m6_board67/earthed_trust.svg',
          scene: true,
          correct: false,
          // Lesson 6.7 myth 1's reality.
          rejectBn: 'ব্যাংক লাইনের ফিউজের পরে লাগানো থাকলে লাইন আর্থ করা সত্ত্বেও ক্যাপাসিটর চার্জড থাকতে পারে।',
        ),
        LearnBoardOption(
          id: 'smallbare',
          labelBn: 'ছোট ক্যাপাসিটর বলে খালি হাতেই খুলে ফেলা',
          asset: 'assets/game/art/m6_board67/earthed_smallbare.svg',
          scene: true,
          correct: false,
          // Lesson 6.7 myth 2's reality.
          rejectBn: 'আকার দিয়ে বিপদ মাপা যায় না — ছোট পাওয়ার ক্যাপাসিটরও মারাত্মক শক দেওয়ার মতো শক্তি ধরে রাখে।',
        ),
        LearnBoardOption(
          id: 'lineonly',
          labelBn: 'রড শুধু লাইনের তারে ছুঁইয়ে ব্যাংকে হাত',
          asset: 'assets/game/art/m6_board67/earthed_lineonly.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্যাপাসিটরকে সবসময় আলাদাভাবে এবং সরাসরি ডিসচার্জ করা অপরিহার্য — লাইন ডিসচার্জে ব্যাংক খালি হয় না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লাইন আর্থ থাকলেও ব্যাংক চার্জড থাকতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্যাপাসিটরকে আলাদা করে সরাসরি ডিসচার্জ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ছোট পাওয়ার ক্যাপাসিটরেও মারাত্মক শক', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'লাইনে আর্থ মানেই ব্যাংকও পুরো খালি', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছোট ক্যাপাসিটরে শক লাগার কোনো ভয় নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাইনের তারে রড ছোঁয়ালেই ব্যাংক খালি', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আকারে ছোট হলে খালি হাতে খোলা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফিউজের পরের ব্যাংকে কোনো চার্জ থাকে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লাইন বন্ধ থাকলে রডের কোনো দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'patrol',
      promptBn: 'লাইন পেট্রোলিংয়ে ব্যাংক দেখলেন — কোন ছবিতে ঠিক কাজ হচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'sound',
          labelBn: 'ক্যান সোজা, শুকনো — পেট্রোলিং এগিয়ে চলল',
          asset: 'assets/game/art/m6_board67/patrol_sound.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bulge',
          labelBn: 'ফোলা ক্যান: ব্যাংক বিচ্ছিন্ন, ফোনে খবর',
          asset: 'assets/game/art/m6_board67/patrol_bulge.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cause',
          labelBn: 'ফিউজ উড়েছে: আগে কারণ খোঁজা, নতুনটা ব্যাগে',
          asset: 'assets/game/art/m6_board67/patrol_cause.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'leak',
          labelBn: 'ফোলা, তেল চুঁইয়ে পড়া ক্যান রেখেই চলে যাওয়া',
          asset: 'assets/game/art/m6_board67/patrol_leak.svg',
          scene: true,
          correct: false,
          // Lesson 6.7 point 4 (করণীয়).
          rejectBn: 'ফুলে যাওয়া বা লিক করা ইউনিট যেকোনো মুহূর্তে বিস্ফোরিত হতে পারে — অবিলম্বে লাইন থেকে বিচ্ছিন্ন করুন।',
        ),
        LearnBoardOption(
          id: 'refuse',
          labelBn: 'ফিউজ উড়েছে, কারণ না দেখেই নতুন ফিউজ',
          asset: 'assets/game/art/m6_board67/patrol_refuse.svg',
          scene: true,
          correct: false,
          rejectBn: 'কারণ খুঁজে বের না করে আবার ফিউজ লাগানো উচিত নয় — খারাপ ইউনিট বা ভেতরের শর্ট থাকতে পারে।',
        ),
        LearnBoardOption(
          id: 'outer',
          labelBn: 'একটা ক্যান ঠান্ডা, তবু বাইরের ফিউজ দেখে সব ঠিক',
          asset: 'assets/game/art/m6_board67/patrol_outer.svg',
          scene: true,
          correct: false,
          // Lesson 6.7 pro tip 1.
          rejectBn: 'ক্যাপাসিটরের ফিউজ প্রায়ই ভেতরে গলে যায়, বাইরে থেকে বোঝা যায় না — সন্দেহ হলে ফিউজ পরীক্ষা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফোলা বা লিক করা ক্যান যেকোনো সময় ফাটতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কারণ না খুঁজে আবার ফিউজ লাগানো একদম নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভেতরের ফিউজ গললে বাইরে থেকে বোঝা যায় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফোলা ক্যানও আরও কিছুদিন দিব্যি চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফিউজ উড়লে নতুন ফিউজ দিলেই সমস্যা শেষ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বাইরের ফিউজ ঠিক থাকলে সব ইউনিটই ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তেল চুঁইয়ে পড়লে একটু মুছে দিলেই কাজ চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পেট্রোলিংয়ে ব্যাংকের দিকে তাকানোর দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফোলা ক্যান দেখলে শুধু খাতায় লিখে রাখলেই হয়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board67Lines.rivalTaunt,
    rivalLineBn: M6Board67Lines.rivalMyth,
    exitBn: M6Board67Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    // DRAFT wording — owner. Shown, not spoken; no word shared with the
    // right reason chips.
    dangerHints: [
      'ক্যানে লুকানো ভোল্টেজ',
      'ছুঁলেই প্রাণঘাতী শক',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ফিউজের পরের ব্যাংকে চার্জ থেকে যেতে পারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ক্যাপাসিটর আলাদা করে সরাসরি ডিসচার্জ করুন', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'লাইন আর্থ করলেই ব্যাংক খালি হয় না', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'লাইন আর্থ থাকলে ব্যাংকও নিজে খালি হয়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'সুইচ OFF মানেই ক্যাপাসিটরে আর চার্জ নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ছোট ব্যাংকে চার্জ থাকলেও কোনো ভয় নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'রড শুধু লাইনের তারে ছোঁয়ালেই যথেষ্ট', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ভেতরের রেসিস্টর থাকলে রড লাগে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'আর্থ দেওয়া লাইনে কোনো ঝুঁকিই থাকে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py` (ruling M6-12: the owner
/// gives the wording first).
abstract final class M6Board67Lines {
  /// DRAFT wording — owner.
  static const rivalTaunt = 'আরে, লাইন তো বন্ধ, আর্থও দেওয়া! আবার রড কিসের?';

  /// Lesson 6.7's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'লাইন তো বন্ধ এবং আর্থ করা আছে, তাই ক্যাপাসিটর ব্যাংকে কাজ করতে কোনো ভয় নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Same list under the Module 6 name (ruling M6-12).
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen), the myth's right chips and the closing line. The sting is
  /// already recorded.
  static List<String> get newGuideLines {
    final p = learnBoardPack67;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
