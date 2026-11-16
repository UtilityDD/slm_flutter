import 'learn_board_models.dart';

/// Module 8 Lesson 8.3 (স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য), the
/// picture board (rung `8.3/learn`, pack `learn_8_3`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m8_board83_art.py` (no words in
/// the art; the times, dates and rules a worker reads are in the labels). Each
/// round's cards share one scene: a card differs only in what its label says,
/// so the picture never gives the verdict on its own. Every round, pick and
/// reason comes from the live lesson text (X3) and the Module 8 rulings
/// (`docs/module_specs/module8_rulings.md`, item spec
/// `docs/module_specs/module8_items/board_83.json`):
///  * clock: the SoP clock starts when the complaint is logged (call centre or
///    the consumer's phone), not when the van leaves, the lineman arrives or
///    the work starts. Traps: van, on site, fuse unit opened;
///  * fuse: fuse-off limits: town 3 h; village 6 h, 8 h in June–September. The
///    docket is closed when the job is done (daily check). Traps: town 5 h,
///    village 7 h in January, docket left open;
///  * dtr: a burnt DTR goes to the JE or the station manager at once; new DTR
///    town 12 h, village 48 h; an 11 kV pole town 12 h. Traps: the call put off
///    to tomorrow, village 52 h, town 30 h, pole 16 h in town;
///  * plan: a maintenance block only in the 06:00–17:00 window for jobs up to
///    6 h, with miking; a shutdown over 6 h needs at least 3 days' notice (M8-12;
///    the live text). Traps: 18:00–21:00 block, an 8 h job on one day's notice,
///    a lane never miked;
///  * delay: a storm break needs photos and a register (force majeure, live tip
///    1); tell the consumer by SMS or in person (live tip 3); the LT jumpering
///    from the next DTR while the new one comes (live tip 2). Traps: no camera,
///    a silent delay, a penalty shrugged off.
/// The round 'meter and voltage' (spec rounds[3]) left the board (M8-21): its
/// numbers are obsolete (loose contact 15 days, LT ±6 %).
/// The rival's myth is the lesson's second myth, word for word, with English
/// digits (ruling X3 / M8-14); no YouTube explainer id (ruling M6-14).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// Every option group (labels, reasons) is within 1.3x in length, so the right
/// one cannot be spotted by its length (playbook §4).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack83 = LearnBoardPack(
  lessonId: '8.3',
  titleBn: 'স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য',
  // The lesson's own badge_name (M8-16; the owner may rename M8Board83Lines.badge).
  badgeBn: M8Board83Lines.badge,
  introBn: 'কমপ্লেইন নথিভুক্ত হলেই SoP-এর ঘড়ি চলে। কোন কাজ কত সময়ে শেষ হতে হয়, চিনে নিন।',
  earnedBn: 'ঘড়ি কমপ্লেইনের মুহূর্ত থেকে চলে, কাজ শেষে ডকেট ক্লোজ করুন, আর শহর-গ্রামের সময়সীমা আলাদা।',
  slots: [
    LearnBoardSlot(
      id: 'clock',
      promptBn: 'কমপ্লেইন এসেছে — SoP-এর ঘড়ি কখন থেকে চলে?',
      options: [
        LearnBoardOption(
          id: 'call',
          labelBn: 'কল সেন্টারে কমপ্লেইন নথিভুক্ত · ঘড়ি চালু',
          asset: 'assets/game/art/m8_board83/clock_call.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sms',
          labelBn: 'গ্রাহকের ফোনে কমপ্লেইন নম্বর এল · ঘড়ি চালু',
          asset: 'assets/game/art/m8_board83/clock_sms.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'van',
          labelBn: 'অফিস থেকে ভ্যান বেরোল · সেই মুহূর্তে ঘড়ি চালু',
          asset: 'assets/game/art/m8_board83/clock_van.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঘড়ি ভ্যান ছাড়ার সময় থেকে নয় — কল সেন্টারে কমপ্লেইন নথিভুক্ত হওয়ার পর থেকেই কাউন্টডাউন শুরু।',
        ),
        LearnBoardOption(
          id: 'site',
          labelBn: 'লাইনম্যান পোলের নিচে পৌঁছলেন · ঘড়ি চালু',
          asset: 'assets/game/art/m8_board83/clock_site.svg',
          scene: true,
          correct: false,
          rejectBn: 'পৌঁছনোর আগেই ঘড়ি চলছে — কমপ্লেইন নথিভুক্ত হওয়া মাত্র কাউন্টডাউন শুরু হয়।',
        ),
        LearnBoardOption(
          id: 'work',
          labelBn: 'ফিউজ ইউনিট খুলতে শুরু হল · ঘড়ি চালু',
          asset: 'assets/game/art/m8_board83/clock_work.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ শুরুর সময় নয় — কল সেন্টারে কমপ্লেইন নথিভুক্ত হওয়ার মুহূর্ত থেকেই SoP-এর সময় গোনা হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কমপ্লেইন নথিভুক্ত হওয়ার মুহূর্ত থেকেই ঘড়ি চলে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভ্যান বা পৌঁছনো নয়, নথিভুক্তি থেকেই গোনা হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কল সেন্টার বা গ্রাহকের ফোন, নথিভুক্তিই শুরু', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ঘড়ি কাজ শুরু হওয়ার সময় থেকেই চালু হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লাইনম্যান পোলে উঠলে তবেই ঘড়ি শুরু হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভ্যান বেরোলেই SoP-এর সময়টা গোনা শুরু হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ঘড়ি শুধু ফিউজ খোলার সময়েই চলে, তার আগে নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ডকেট ক্লোজের পর থেকেই SoP-এর সময় গোনা হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fuse',
      promptBn: 'ফিউজ অফ — কোন কাজটা SoP-এর সময়ের মধ্যে শেষ?',
      options: [
        LearnBoardOption(
          id: 'urban_in_time',
          labelBn: 'শহর · কমপ্লেইন 14:00 · আলো ফিরল 16:30 · ডকেট ক্লোজ',
          asset: 'assets/game/art/m8_board83/fuse_urban_in_time.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rural_in_time',
          labelBn: 'গ্রাম · জুলাই · কমপ্লেইন 09:00 · আলো ফিরল 16:00 · ডকেট ক্লোজ',
          asset: 'assets/game/art/m8_board83/fuse_rural_in_time.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'urban_late',
          labelBn: 'শহর · কমপ্লেইন 14:00 · আলো ফিরল 19:00 · ডকেট ক্লোজ',
          asset: 'assets/game/art/m8_board83/fuse_urban_late.svg',
          scene: true,
          correct: false,
          rejectBn: 'শহরে ফিউজ অফ 3 ঘন্টার মধ্যে সারাতে হয় — এখানে 5 ঘন্টা লেগেছে।',
        ),
        LearnBoardOption(
          id: 'rural_late',
          labelBn: 'গ্রাম · জানুয়ারি · কমপ্লেইন 09:00 · আলো ফিরল 16:00 · ডকেট ক্লোজ',
          asset: 'assets/game/art/m8_board83/fuse_rural_late.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রামে বর্ষার বাইরে 6 ঘন্টার মধ্যে ফিউজ অফ সারাতে হয় — এখানে 7 ঘন্টা।',
        ),
        LearnBoardOption(
          id: 'docket_open',
          labelBn: 'শহর · কমপ্লেইন 14:00 · আলো ফিরল 15:30 · ডকেট খোলা রইল',
          asset: 'assets/game/art/m8_board83/fuse_docket_open.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজ করলেন কিন্তু ডকেট ক্লোজ করলেন না — কোম্পানির খাতায় আপনি এখনো কাজ করেননি, পেনাল্টি বাড়ছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শহরে 3 ঘন্টা, গ্রামে বর্ষায় 8 ও বাকি সময় 6 ঘন্টা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কাজ শেষে ডকেট ক্লোজ না করলে কাজ ধরা হয় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সময় মাপা হয় কমপ্লেইন থেকে আলো ফেরা পর্যন্ত', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'শহর-গ্রাম সবখানে ফিউজ অফ 24 ঘন্টায় সারাতে হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ডকেট খোলা রাখলেও কাজ ঠিকই ধরা হয় কোম্পানিতে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আলো ফিরলেই হয়, ডকেট পরে ক্লোজ করলেও চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গ্রামে ফিউজ অফ-এর কোনো নির্দিষ্ট সময়সীমা নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বর্ষা বা শীত, গ্রামের সময় সবসময় 8 ঘন্টা', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'dtr',
      promptBn: 'DTR জ্বলেছে বা পোল ভেঙেছে — কোনটা SoP মেনে হচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'call_now',
          labelBn: 'শহরে DTR জ্বলেছে · লাইনম্যান তখনই JE-কে ফোন করে দিলেন',
          asset: 'assets/game/art/m8_board83/dtr_call_now.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'urban_in_time',
          labelBn: 'শহরের DTR · জ্বলল সোম 20:00 · JE-কে 20:05 ফোন · নতুন মঙ্গল 06:00',
          asset: 'assets/game/art/m8_board83/dtr_urban_in_time.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'call_later',
          labelBn: 'শহরে DTR জ্বলেছে · লাইনম্যান বললেন কাল সকালে জানাব',
          asset: 'assets/game/art/m8_board83/dtr_call_later.svg',
          scene: true,
          correct: false,
          rejectBn: 'ট্রান্সফরমার জ্বললে দেরি না করে সাথে সাথে জুনিয়র ইঞ্জিনিয়ার বা স্টেশন ম্যানেজারকে জানান।',
        ),
        LearnBoardOption(
          id: 'rural_late',
          labelBn: 'গ্রামের DTR · জ্বলল সোম 08:00 · JE-কে 08:10 ফোন · নতুন বুধ 12:00',
          asset: 'assets/game/art/m8_board83/dtr_rural_late.svg',
          scene: true,
          correct: false,
          rejectBn: 'গ্রামাঞ্চলে DTR বদলের সময় 48 ঘন্টা — এখানে 52 ঘন্টা লেগেছে।',
        ),
        LearnBoardOption(
          id: 'urban_late',
          labelBn: 'শহরের DTR · জ্বলল সোম 08:00 · JE-কে 08:10 ফোন · নতুন মঙ্গল 14:00',
          asset: 'assets/game/art/m8_board83/dtr_urban_late.svg',
          scene: true,
          correct: false,
          rejectBn: 'শহরে জ্বলে যাওয়া DTR 12 ঘন্টার মধ্যে বদলাতে হয় — এখানে 30 ঘন্টা।',
        ),
        LearnBoardOption(
          id: 'breakdown_late',
          labelBn: 'শহরের 11 kV পোল ভেঙেছে · কমপ্লেইন 06:00 · নতুন পোল 22:00',
          asset: 'assets/game/art/m8_board83/dtr_breakdown_late.svg',
          scene: true,
          correct: false,
          rejectBn: 'শহরে 11 kV পোল 12 ঘন্টার মধ্যে বদলাতে হয় — এখানে 16 ঘন্টা লেগেছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'DTR জ্বললে তখনই JE বা স্টেশন ম্যানেজারকে জানান', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শহরের DTR 12 ঘন্টায়, গ্রামের DTR 48 ঘন্টায় বদলাতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'শহর-গ্রামে DTR বদলানোর সময়সীমা আলাদা, নিয়ম এক নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'DTR জ্বললে কাজ শেষে কাল সকালে জানালেই চলে, তাড়া নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'শহর ও গ্রাম দুটোতেই DTR বদলাতে 24 ঘন্টা সময় দেওয়া হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গ্রামের DTR 72 ঘন্টার মধ্যে বদলালেই চলে, তাড়া নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পোল ভাঙলে কোনো সময়সীমা নেই, যখন হয় তখন সারানো হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'DTR-এর কাজ শুধু বড় অফিসের লোক করে, আপনার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'plan',
      promptBn: 'মেইনটেন্যান্সের জন্য শাটডাউন — কোন পরিকল্পনাটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'short_a',
          labelBn: 'নোটিশ সোম 10:00 · শাটডাউন বুধ 10:00–13:00 · মাইকিং হয়েছে',
          asset: 'assets/game/art/m8_board83/plan_short_a.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'short_b',
          labelBn: 'নোটিশ সোম 09:00 · শাটডাউন বুধ 11:00–15:00 · পাড়ায় মাইকিং হয়েছে',
          asset: 'assets/game/art/m8_board83/plan_short_b.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'evening_block',
          labelBn: 'নোটিশ সোম 10:00 · শাটডাউন বুধ 18:00–21:00 · মাইকিং হয়েছে',
          asset: 'assets/game/art/m8_board83/plan_evening_block.svg',
          scene: true,
          correct: false,
          rejectBn: 'সন্ধ্যা 5টা থেকে সকাল 6টার মধ্যে মেইনটেন্যান্স শাটডাউন নেওয়া নিষেধ — জরুরী অবস্থা ছাড়া।',
        ),
        LearnBoardOption(
          id: 'one_day',
          labelBn: 'নোটিশ বুধ 08:00 · শাটডাউন বৃহস্পতি 08:00–16:00 · মাইকিং হয়েছে',
          asset: 'assets/game/art/m8_board83/plan_one_day_notice.svg',
          scene: true,
          correct: false,
          rejectBn: 'না, 6 ঘন্টার বেশি লাইন বন্ধ রাখলে অন্তত 3 দিন আগে গ্রাহকদের নোটিশ দিতেই হবে।',
        ),
        LearnBoardOption(
          id: 'no_miking',
          labelBn: 'নোটিশ সোম 10:00 · শাটডাউন বুধ 10:00–13:00 · পাড়ায় মাইকিং হয়নি',
          asset: 'assets/game/art/m8_board83/plan_no_miking.svg',
          scene: true,
          correct: false,
          rejectBn: 'শাটডাউন নেওয়ার আগে নিশ্চিত হন যে এলাকায় মাইকিং হয়েছে বা গ্রাহকরা জানে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ছয় ঘন্টা বা তার কম কাজে 06:00–17:00-এর মধ্যে নিন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শাটডাউনের আগে এলাকায় মাইকিং হয়ে থাকা চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: '6 ঘন্টার বেশি বন্ধে অন্তত 3 দিন আগে নোটিশ দিতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো শাটডাউনে এক দিন আগের নোটিশই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'রাতে শাটডাউন নিলে কেউ টের পায় না, তাই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মাইকিং না করলেও গ্রাহক নিজে থেকে সব জেনে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দু-দিন আগের নোটিশ আর যেকোনো সময়ের শাটডাউন চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মাইকিং হলেই সন্ধ্যার পরেও শাটডাউন নেওয়া যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'delay',
      promptBn: 'দেরি হবেই — এখন কোন কাজটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'storm_photos',
          labelBn: 'ঝড়ে ভাঙা পোল · ছবি তোলা আর নথিতে লিখে রাখা',
          asset: 'assets/game/art/m8_board83/delay_storm_photos.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lt_jumper',
          labelBn: 'DTR আসতে দেরি · পাশের DTR থেকে LT জাম্পারিং',
          asset: 'assets/game/art/m8_board83/delay_lt_jumper.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sms_consumer',
          labelBn: 'গ্রাহককে SMS-এ জানানো · কাজ চলছে, একটু দেরি হবে',
          asset: 'assets/game/art/m8_board83/delay_sms_consumer.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'storm_no_photos',
          labelBn: 'ঝড়ে ভাঙা পোল · ক্যামেরা নেই, মুখে বলে দেব',
          asset: 'assets/game/art/m8_board83/delay_storm_no_photos.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঝড়-বন্যায় দেরি হলে SoP-এর পেনাল্টি লাগে না ঠিকই — কিন্তু তার জন্য সঠিক ডকুমেন্টেশন আর ছবি রাখা জরুরি।',
        ),
        LearnBoardOption(
          id: 'silent_delay',
          labelBn: 'গ্রাহকরা অন্ধকারে, কর্মী কিছু জানায়নি এখনও',
          asset: 'assets/game/art/m8_board83/delay_silent_delay.svg',
          scene: true,
          correct: false,
          rejectBn: 'দেরি হবে বুঝলে গ্রাহককে SMS বা মুখে জানিয়ে দিন — "কাজ চলছে" জানলে গ্রাহক সাধারণত কেস করে না।',
        ),
        LearnBoardOption(
          id: 'penalty_whim',
          labelBn: 'কর্মী কাঁধ ঝাঁকাল · জরিমানা? ইচ্ছে হলে দেবে',
          asset: 'assets/game/art/m8_board83/delay_penalty_whim.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল — পোর্টালে অনেক সময় জরিমানার অটোমেটিক ক্যালকুলেশন হয়, আর গ্রাহক কমিশনে অভিযোগ করলে কোম্পানি দিতে বাধ্য।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'দেরি হবে বুঝলে চুপ না থেকে কিছু করতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দেরির ঘটনা ছবি তুলে নথিতে লিখে রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সঠিক ব্যবস্থা নিলে দেরি সামলানো যায়, পেনাল্টিও কমে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ঝড়ে ভাঙলে ক্যামেরা লাগে না, মুখে বললেই হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গ্রাহক অন্ধকারে থাকলে কিছু বলার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পেনাল্টি কোম্পানির ইচ্ছেমতো, তাই ভয় নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দেরি হবেই, তাই কাজ বন্ধ রেখে বসে থাকলেও চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পেন্ডিং ডকেট নিয়ে কোনো চিন্তার কারণ নেই, চলবে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M8Board83Lines.rivalTaunt,
    rivalLineBn: M8Board83Lines.rivalMyth,
    exitBn: M8Board83Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ঘড়ি বন্ধ হয় না',
      'জরিমানা বাড়ে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'SoP-এর ঘড়ি গ্রাম-শহর সবখানে নথিভুক্তি থেকে চলে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'গ্রামের গ্রাহকও কমপ্লেইন করেন, WBERC গ্রামও দেখে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'গ্রামের সময়সীমা আলাদা হতে পারে, ঘড়ি বন্ধ থাকে না', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'গ্রামে কোনো সময়সীমা নেই, তাই দেরি করা চলে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'ঘড়ি চলে শুধু শহরের কমপ্লেইনে, গ্রামে কখনো নয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'জরিমানা কোম্পানির ইচ্ছেয়, তাই কোনো ভয় নেই', correct: false),
      LearnWhyChip(id: 'm7', textBn: '24 ঘন্টা পরেই গ্রামের SoP-এর ঘড়ি শুরু হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'গ্রামে কমপ্লেইন লেখা হয় না, তাই ঘড়িও নেই', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice (the same line as the other boards); [toRecord] stay silent
/// (caption held for reading) until the director records them with
/// `tool/rival_clip.py`.
abstract final class M8Board83Lines {
  /// The lesson's badge_name (live text, M8-16). The owner may rename it.
  // OWNER may rename
  static const badge = 'জরুরী রেগুলেশন (WBERC ফোকাস)';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'ওরে বাবা! ঘড়ি ঘড়ি করে জান শেষ! গ্রামে কে দেখতে আসবে?';

  /// Lesson 8.3's myth 2, word for word with English digits (not new text;
  /// needs a clip).
  static const rivalMyth = 'গ্রামে কারেন্ট না থাকলে কেউ দেখার নেই, 24 ঘন্টা কোনো ব্যাপার না।';

  /// Already recorded (reused from the other boards).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Every new rival line on this board (M8-14), pinned by the test. The same
  /// list as [toRecord] until the owner adds more.
  static const newRivalLines = toRecord;

  /// The guide's new spoken lines on this board (DRAFT wording — owner; each
  /// becomes a recorded clip): the intro, every round's question, every
  /// trap's reason, every right reason chip (spoken the first time it is
  /// chosen) and the closing line. The sting is already recorded.
  // DRAFT wording — owner.
  static List<String> get newGuideLines {
    final p = learnBoardPack83;
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
