import 'learn_board_models.dart';

/// Module 6 Lesson 6.9 (এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার), the picture
/// board (rung `6.9/learn`, pack `learn_6_9`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m6_board69_art.py` (the only
/// labels drawn are what a worker reads: a tester's reading, as stroke glyphs
/// with English digits). Ruling M6-8 shortens the board to one recap round
/// plus the new material — four rounds (item spec
/// `docs/module_specs/module6_items/board_69.json`, Module 6 rulings
/// `docs/module_specs/module6_rulings.md`; the live lesson text wins):
///  * pillar (recap of spec rounds 0, 1 and 4): each outgoing way through its
///    own fuse unit, so a fault on one lane darkens only that lane (point 1);
///    inside, separate R, Y, B and N bars, every neutral on the common
///    neutral link, the body and the cable armour on the earthing terminal
///    (point 2) and the cores landed R on R, Y on Y, B on B (pro tip 2) — one
///    inside picture; the door shut and padlocked (pro tip 1). Traps: the
///    whole neighbourhood dark from one fault; a neutral taken through a fuse
///    unit with an armour lead hanging loose (one 'wired wrong' picture); the
///    door left open with children near. Every M6-8 idea is kept, merged so
///    the round has 6 picture cards (owner answers after Wave A: 4–6 per
///    round). Its right reasons are rules for the whole pillar, since any of
///    the three safe cards can be the pick;
///  * thermal (spec round 2): a thermal scan finds the hotspot before the eye
///    can (pro tip 3); a blackened joint noted for tightening (point 3).
///    Traps: a bare hand feeling a joint (the safety tip: a live panel),
///    water on a hot joint (water → short → arc flash, ruling M6-4), the
///    hotspot seen and left, "all fine" ticked by eye;
///  * fix (spec round 3, ruling X4): the broken top seal replaced, the rat
///    nest cleared, the loose lug tightened only after the DTR LT switch is
///    OFF, locked, tagged and proved dead. Traps: the same phase's fuse
///    replaced again with the load still unbalanced, the puddle wiped and the
///    seal left broken, the nest left by a gnawed cable;
///  * dead (new, ruling M6-8: lesson myth 1, the safety tip and the HRC fact):
///    the DTR LT switch OFF with lock and tag, the tester live-dead-live at
///    0 V, an HRC whose quartz sand soaks up and quenches the arc (all three
///    right reasons are about the fault current and the arc, so each fits
///    every safe pick; no wrong reason belongs to one card only). Traps: a
///    bare hand on a fuse because "it is only 415 V" (the myth's reality), a
///    fuse pulled with the supply on (the safety tip's own words), the switch
///    OFF but no lock, tag or test (ruling X4 / N4).
/// Boards are not scored for deadly (kit design): a deadly-class trap costs
/// the round and teaches with the lesson's words.
/// The rival's myth is the lesson's first myth (ruling M6-8: the thick-wire
/// myth lives only on board 6.3), with the owner's term rule applied (LT in
/// English letters) and English digits.
///
/// Reason chips: the runner deals a round's "কেন?" chips whatever safe card
/// was picked, so every right chip is a rule that holds for each safe card of
/// its round. Rules that only explain a trap stay in that trap's reject line.
///
/// DRAFT wording — owner (ruling M6-12): every Bangla line written for this
/// board (prompts, labels, reason chips, the intro, the earned line, the
/// rival's taunt, the danger tags) is a draft for the owner's natural
/// wording; lesson quotes are marked where they are used. No YouTube explainer
/// id (ruling M6-14).
const learnBoardPack69 = LearnBoardPack(
  lessonId: '6.9',
  titleBn: 'এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার',
  badgeBn: 'যন্ত্র গুরু',
  introBn: M6Board69Lines.intro,
  earnedBn: M6Board69Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'pillar',
      promptBn: 'ফিডার পিলার ঠিকঠাক থাকলে কেমন দেখায় — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'lane',
          labelBn: 'একটা গলিতে ফল্ট: শুধু সেই গলি অন্ধকার, বাকিরা আলোয়',
          asset: 'assets/game/art/m6_board69/pillar_lane.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'inside',
          labelBn: 'R, Y, B কোর মিলিয়ে, নিউট্রাল এক লিঙ্কে, আর্মার আর্থে',
          asset: 'assets/game/art/m6_board69/pillar_inside.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'locked',
          labelBn: 'কাজ শেষে পিলারের দরজা ভালো করে বন্ধ, তালা লাগানো',
          asset: 'assets/game/art/m6_board69/pillar_locked.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'alldark',
          labelBn: 'একটা গলিতে ফল্ট, আর তাতেই পুরো পাড়া অন্ধকার',
          asset: 'assets/game/art/m6_board69/pillar_alldark.svg',
          scene: true,
          correct: false,
          // Lesson point 1.
          rejectBn: 'পিলারে প্রতিটি আউটগোয়িং ফিডার আলাদাভাবে ফিউজ করা থাকে — একটা লাইনে ফল্ট হলে পুরো এলাকা নয়, শুধু সেই লাইনটাই বন্ধ হয়।',
        ),
        LearnBoardOption(
          id: 'wiring',
          labelBn: 'নিউট্রাল ফিউজ ইউনিটে, আর এক কেবিলের আর্মার ঝুলছে',
          asset: 'assets/game/art/m6_board69/pillar_wiring.svg',
          scene: true,
          correct: false,
          // Lesson point 2 (fuse units and neutral link; earthing terminal).
          rejectBn: 'ফিউজ ইউনিট দিয়ে নেওয়া হয় ফেজ কানেকশন, নিউট্রাল যায় কমন নিউট্রাল লিঙ্কে — আর কেবিলের আর্মার যায় আর্থিং টার্মিনালে, ঝুলিয়ে রাখা চলে না।',
        ),
        LearnBoardOption(
          id: 'door',
          labelBn: 'কাজ শেষ, পিলারের দরজা খোলা, পাশে বাচ্চারা খেলছে',
          asset: 'assets/game/art/m6_board69/pillar_door.svg',
          scene: true,
          correct: false,
          // Lesson pro tip 1.
          rejectBn: 'কাজ শেষে দরজা লক করা অত্যন্ত জরুরি — খোলা দরজা জনসাধারণ, বিশেষ করে বাচ্চাদের জন্য, আর সিস্টেমের জন্য মারাত্মক বিপদ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সাজানো পিলারে ফল্ট খোঁজা আর কাজ সহজ ও নিরাপদ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঠিকঠাক পিলার গ্রাহক আর পথচারী দুজনকেই বাঁচায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নিয়মমতো পিলারে ফল্ট আর বিপদ দুটোই কমে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নিউট্রালেও ফিউজ দিলে পিলার আরও নিরাপদ হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটা ফিউজে সব লাইন রাখলেই কাজ সবচেয়ে সহজ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আর্মার আর্থ না করলেও পিলারের কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাজ শেষে দরজা খোলা থাকলে ভেতরে হাওয়া খেলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'এক লাইনে ফল্ট হলে পুরো পাড়া বন্ধ হওয়াই নিয়ম', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ফেজ উল্টে গেলেও গ্রাহকের যন্ত্রের কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'thermal',
      promptBn: 'প্রিভেন্টিভ মেইনটেন্যান্স — ঢিলা কানেকশন আগেভাগে ধরবেন কীভাবে?',
      options: [
        LearnBoardOption(
          id: 'scan',
          labelBn: 'PPE পরে থার্মাল স্ক্যান: চোখে ঠিক জয়েন্টেও হটস্পট',
          asset: 'assets/game/art/m6_board69/thermal_scan.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'black',
          labelBn: 'কালো হয়ে যাওয়া জয়েন্ট টাইট দেওয়ার জন্য লিখে রাখা',
          asset: 'assets/game/art/m6_board69/thermal_black.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'touch',
          labelBn: 'জয়েন্ট গরম কি না, খালি হাতে ছুঁয়ে দেখা হচ্ছে',
          asset: 'assets/game/art/m6_board69/thermal_touch.svg',
          scene: true,
          correct: false,
          // Lesson safety tip (point 2); ruling X4: no hand on a live joint.
          rejectBn: 'ফিডার পিলারের ভেতরটা একটা লাইভ প্যানেলের মতোই বিপজ্জনক — চালু সাপ্লাইয়ে জয়েন্টে হাত একদম নয়।',
        ),
        LearnBoardOption(
          id: 'water',
          labelBn: 'গরম জয়েন্ট ঠান্ডা করতে মগ থেকে জল ছিটানো',
          asset: 'assets/game/art/m6_board69/thermal_water.svg',
          scene: true,
          correct: false,
          // Point 3 (water → short circuit) + myth 1 reality (arc flash).
          rejectBn: 'বক্সের ভেতরে জল শর্ট সার্কিট ঘটাতে পারে — আর এখানে শর্ট সার্কিট মানে আর্ক ফ্ল্যাশ, যা মুহূর্তে পুড়িয়ে দেয়।',
        ),
        LearnBoardOption(
          id: 'wait',
          labelBn: 'ক্যামেরায় হটস্পট দেখেও ফেলে রেখে চলে যাওয়া',
          asset: 'assets/game/art/m6_board69/thermal_wait.svg',
          scene: true,
          correct: false,
          // Point 3 and its করণীয়.
          rejectBn: 'ঢিলা কানেকশনে স্পার্কিং হয়, জায়গাটা অতিরিক্ত গরম হয় — লুজ কানেকশন টাইট দিন, ফেলে রাখবেন না।',
        ),
        LearnBoardOption(
          id: 'eye',
          labelBn: 'চোখে সব ঠিক দেখে, স্ক্যান না করেই "ঠিক আছে" লেখা',
          asset: 'assets/game/art/m6_board69/thermal_eye.svg',
          scene: true,
          correct: false,
          // Lesson pro tip 3.
          rejectBn: 'থার্মাল ক্যামেরা দিয়ে ফিডার পিলার স্ক্যান করলে চোখে দেখার আগেই লুজ কানেকশন বা হটস্পট খুঁজে বের করা যায়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঢিলা কানেকশন গরম হয়, হটস্পটই তার চিহ্ন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কালো রং বা হটস্পট দেখলেই কানেকশন টাইট দিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গরম জয়েন্ট আগেভাগে ধরলে বড় ফল্ট আটকায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চোখে ঠিক দেখালে জয়েন্টও নিশ্চয়ই ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'হাতে ছুঁয়েই গরম জয়েন্ট ধরা সবচেয়ে সহজ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'জল দিলে গরম জয়েন্ট তাড়াতাড়ি ঠান্ডা হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কালো জয়েন্ট শুধু পুরনো হওয়ার চিহ্ন', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'হটস্পট নিজে থেকেই একসময় ঠান্ডা হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'থার্মাল ক্যামেরা শুধু অফিসের কাজে লাগে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fix',
      promptBn: 'পিলারে সমস্যা ধরা পড়েছে — ঠিক সমাধান কোনটা?',
      options: [
        LearnBoardOption(
          id: 'seal',
          labelBn: 'ওপরের নষ্ট সিল বদলানো হলো, ভেতরটা শুকনো',
          asset: 'assets/game/art/m6_board69/fix_seal.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nest',
          labelBn: 'ইঁদুরের বাসা সাফ, বক্সের ভেতরটা পরিষ্কার',
          asset: 'assets/game/art/m6_board69/fix_nest.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lug',
          labelBn: 'LT OFF, তালা-ট্যাগ, টেস্টারে 0 V, তারপর লাগ টাইট',
          asset: 'assets/game/art/m6_board69/fix_lug.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fuse3',
          labelBn: 'একই ফেজের ফিউজ আবার বদলানো, লোড অসমান',
          asset: 'assets/game/art/m6_board69/fix_fuse3.svg',
          scene: true,
          correct: false,
          // Point 3 (phase unbalance) and its করণীয়.
          rejectBn: 'একটা ফেজে অন্যগুলোর চেয়ে অনেক বেশি লোড হলে সেই ফেজের ফিউজ বারবার উড়ে যায় — লোড ব্যালেন্স করুন।',
        ),
        LearnBoardOption(
          id: 'wipe',
          labelBn: 'ভেতরের জল মোছা, কিন্তু ভাঙা সিল যেমন ছিল',
          asset: 'assets/game/art/m6_board69/fix_wipe.svg',
          scene: true,
          correct: false,
          // Point 3 (water ingress) and its করণীয়.
          rejectBn: 'ভাঙা দরজা বা ওপরের নষ্ট সিল দিয়েই বৃষ্টির জল ঢোকে — পথ বন্ধ না করলে আবার শর্ট সার্কিট আর মরিচা।',
        ),
        LearnBoardOption(
          id: 'gnaw',
          labelBn: 'কাটা কেবিলের পাশে ইঁদুরের বাসা রয়েই গেছে',
          asset: 'assets/game/art/m6_board69/fix_gnaw.svg',
          scene: true,
          correct: false,
          // Point 3 (rats) and its করণীয়.
          rejectBn: 'ইঁদুর বা অন্য প্রাণী কেবিলের ইনসুলেশন কেটে শর্ট সার্কিট ঘটায় — বক্সের ভেতরটা পরিষ্কার রাখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সমস্যার কারণটাই বন্ধ করলে ফল্ট আর ফেরে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ঢিলা টাইট, জলের পথ বন্ধ, ভেতরটা পরিষ্কার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভেতরের কাজ শুধু LT OFF, ডেড প্রমাণের পর', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একই ফিউজ বারবার বদলালেই সমস্যা মিটে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জল মুছে দিলেই হলো, সিল দেখার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ইঁদুরের বাসা থাকলে কেবিলের কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চালু অবস্থাতেই লাগ টাইট দিলে সময় বাঁচে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'লোড ব্যালেন্স করা লাইনম্যানের কাজই নয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বক্সে একটু জল ঢুকলে কোনো ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'dead',
      promptBn: 'পিলারে HRC ফিউজ উড়েছে — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'lock',
          labelBn: 'DTR-এর LT সুইচ OFF, তাতে তালা আর ট্যাগ লাগানো',
          asset: 'assets/game/art/m6_board69/dead_lock.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'test',
          labelBn: 'টেস্টারে লাইভ-ডেড-লাইভ: পিলারের বাসবারে 0 V',
          asset: 'assets/game/art/m6_board69/dead_test.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'sand',
          labelBn: 'HRC-র ভেতরের কোয়ার্টজ বালু আর্ক শুষে নিভিয়েছে',
          asset: 'assets/game/art/m6_board69/dead_sand.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: '"মাত্র 415 ভোল্ট" ভেবে খালি হাতে ফিউজে হাত',
          asset: 'assets/game/art/m6_board69/dead_bare.svg',
          scene: true,
          correct: false,
          // Lesson myth 1's reality (English digits).
          rejectBn: '415 ভোল্ট মারাত্মক শক দেওয়ার জন্য যথেষ্ট। তার চেয়েও বড় বিপদ এর বিশাল ফল্ট কারেন্ট — শর্ট সার্কিটে আর্ক ফ্ল্যাশ মুহূর্তের মধ্যে পুড়িয়ে দিতে পারে।',
        ),
        LearnBoardOption(
          id: 'livepull',
          labelBn: 'সাপ্লাই চালু রেখেই পুলার দিয়ে ফিউজ টেনে খোলা',
          asset: 'assets/game/art/m6_board69/dead_livepull.svg',
          scene: true,
          correct: false,
          // Lesson safety tip: its last sentence word for word, then its order.
          rejectBn: 'চালু সাপ্লাইয়ে ফিউজ ছোঁবেন না, টানবেনও না — আগে DTR-এর LT সুইচ OFF, তালা-ট্যাগ, টেস্টারে ডেড প্রমাণ।',
        ),
        LearnBoardOption(
          id: 'nolock',
          labelBn: 'LT সুইচ OFF করেই ফিউজে হাত, তালা-ট্যাগ-টেস্ট নেই',
          asset: 'assets/game/art/m6_board69/dead_nolock.svg',
          scene: true,
          correct: false,
          // Lesson safety tip, word for word but «ডেড» (owner term rule).
          rejectBn: 'ফিউজ বদলানোর আগে DTR-এর LT সুইচ বন্ধ করে সাপ্লাই আলাদা করুন, তালা-ট্যাগ দিন, তারপর টেস্টারে (লাইভ-ডেড-লাইভ) পরীক্ষা করে ডেড প্রমাণ করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'LT-র বিশাল ফল্ট কারেন্টে আর্ক ফ্ল্যাশ হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পিলারে আসল বিপদ ফল্ট কারেন্ট আর আর্ক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আর্ক থেকে বাঁচাতেই ডেড বোর্ড আর HRC ফিউজ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গ্লাভস পরা থাকলে চালু ফিউজও টেনে খোলা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'LT-তে ফল্ট কারেন্ট সামান্য, আর্কের ভয় নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'টেস্টার শুধু HT লাইনের জন্য, LT-তে লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফিউজ উড়লেই পিলার নিজে থেকে ডেড হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'চালু পিলারে তাড়াতাড়ি কাজ সারলে বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'পিলারে মাত্র 415 ভোল্ট, এতে ভয়ের কিছু নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M6Board69Lines.rivalTaunt,
    rivalLineBn: M6Board69Lines.rivalMyth,
    exitBn: M6Board69Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    // DRAFT wording — owner.
    dangerHints: [
      'মারাত্মক শক',
      'আর্ক ফ্ল্যাশে পুড়ে যাওয়া',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: '415 ভোল্টই মারাত্মক শক দেওয়ার জন্য যথেষ্ট', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'আসল বিপদ বিশাল ফল্ট কারেন্ট আর আর্ক ফ্ল্যাশ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'আর্ক ফ্ল্যাশ মুহূর্তেই মানুষকে পুড়িয়ে দেয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'কম ভোল্টেজে শক লাগলে শুধু একটু ঝিনঝিন করে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'HT না হলে গ্লাভস ছাড়াই দিব্যি কাজ চলে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'LT বক্সে শর্ট সার্কিট হলে তেমন কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আর্ক ফ্ল্যাশ শুধু 11 kV লাইনেই হতে পারে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'অভিজ্ঞ লাইনম্যানের LT-তে শক লাগে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'LT বক্সের কাজ মানে হালকা কাজ, ভয় নেই', correct: false),
    ],
  ),
);

/// The lines on this board. The careless coworker's [rivalExit] is already in
/// his recorded voice; [toRecord] stay silent (caption held for reading) until
/// the director records them with `tool/rival_clip.py`. The guide's lines
/// ([guideSpoken]) play on the device voice until the owner's clips exist.
abstract final class M6Board69Lines {
  /// DRAFT wording — owner.
  static const intro = 'ফিডার পিলার পাড়ার বিদ্যুতের জংশন। ভেতরটা চিনুন, সমস্যা ধরুন, আর হাত দিন শুধু ডেড বোর্ডে।';

  /// DRAFT wording — owner.
  static const earned = 'প্রতিটি লাইন নিজের ফিউজে; ঢিলা জয়েন্ট আগেভাগে ধরুন; পিলারে হাত শুধু LT OFF, তালা-ট্যাগ আর ডেড প্রমাণের পর।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'আরে, এ তো LT পিলার! এত সাবধানতার কী আছে?';

  /// Lesson 6.9's first myth (ruling M6-8), word for word but for the owner's
  /// term rule (LT in English letters) and English digits. It shares a rival
  /// clip with the do_6_9_b push.
  static const rivalMyth = 'LT বক্সের ভেতরে তো শুধু 415 ভোল্ট থাকে, এটা তেমন বিপজ্জনক নয়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Ruling M6-12: the rival's new lines (the taunt is a draft; the myth is
  /// the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// Ruling M6-12: every guide line on this board, for the owner's wording
  /// pass and the voice session (lesson quotes in the trap reasons included,
  /// since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting, the myth's right reasons, the earned
  /// line), for the owner's wording pass and the voice session.
  static List<String> get guideSpoken {
    final p = learnBoardPack69;
    return [
      p.introBn,
      for (final s in p.slots) ...[
        s.promptBn,
        for (final o in s.options)
          if (!o.correct) o.rejectBn,
        for (final w in s.whyChips)
          if (w.correct) w.textBn,
      ],
      p.myth.stingBn,
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
