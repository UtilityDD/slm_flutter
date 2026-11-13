import 'learn_board_models.dart';

/// Module 5 Lesson 5.8 (ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের রোগ নির্ণয়),
/// the picture board (rung `5.8/learn`, pack `learn_5_8`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board58_art.py`: one DTR on
/// its plinth, the HT DO fuses above it, the LT distribution box on the pole.
/// Every round and every trap comes from the lesson text (switch-off and
/// prove-dead from the Module 5 rules, `docs/module_specs/module5_rulings.md`):
///  * htfuse: the HT DO fuse blows again at once. First sectionalize (lesson
///    5.4: every LT way out, then the HT DO in); a faulty DTR is isolated and
///    sent to the workshop. Charging a DTR with an inside fault again and
///    again can make it explode (M5-1: deadly class); the cause can also be a
///    big LT short or a punctured HT bushing;
///  * noise: loud, irregular sound instead of the hum is the DTR's "language";
///    overloading can raise it, so the load is checked first (the tong tester
///    is the module's tool for "লোড পরীক্ষা করুন"); load normal and still noisy
///    → report to the supervisor;
///  * leak: find the source and amount; small leak with the level fine →
///    watch it; big leak → the DTR off, the leak repaired, oil topped up; a
///    leak also lets moisture in;
///  * ltdead: HT fuse sound, one LT phase dead → the DTR off, the tester
///    shows dead (M5-2: a tool before 0 V is deadly class), then the LT
///    bushing connection checked; connection sound → the DTR replaced;
///  * proof (pro tips): megger IR near zero on an ISOLATED DTR, very dark oil
///    with carbon specks, a cracked bushing with a flashover track; water in
///    oil is its biggest enemy (myth 2, M5-6: a slip); the old records give
///    clues.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack58 = LearnBoardPack(
  lessonId: '5.8',
  titleBn: 'ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের রোগ নির্ণয়',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'ট্রান্সফরমার নেটওয়ার্কের হৃৎপিণ্ড। লক্ষণ দেখে রোগ ধরুন — কখন প্রাথমিক চিকিৎসা, কখন ওয়ার্কশপ।',
  earnedBn: 'আগে সেকশনালাইজিং, আগে লোড, আগে লিকের উৎস — বন্ধ করে ডেড প্রমাণ, তবেই হাত।',
  slots: [
    LearnBoardSlot(
      id: 'htfuse',
      promptBn: 'ডিও-তে নতুন ফিউজ দিতেই আবার উড়ে গেল — এখন কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'section',
          labelBn: 'সব এলটি ফিউজ খুলে, তারপর এইচটি ডিও',
          asset: 'assets/game/art/m5_board58/htfuse_section.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'workshop',
          labelBn: 'দোষী ট্রান্সফরমার খুলে ওয়ার্কশপে',
          asset: 'assets/game/art/m5_board58/htfuse_workshop.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'third',
          labelBn: 'তৃতীয়বার ডিও-তে ফিউজ ঠেলে দেওয়া',
          asset: 'assets/game/art/m5_board58/htfuse_third.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভেতরে ফল্ট থাকা ট্রান্সফরমারকে বারবার চার্জ করলে সেটি বিস্ফোরিত হতে পারে — এটা মারাত্মক ভুল।',
        ),
        LearnBoardOption(
          id: 'htonly',
          labelBn: 'শুধু এইচটি লাইন ধরে খুঁজতে যাওয়া',
          asset: 'assets/game/art/m5_board58/htfuse_htonly.svg',
          scene: true,
          correct: false,
          rejectBn: 'এলটি সাইডে বড় শর্টও কারণ হতে পারে — আগে সেকশনালাইজিং করে নিশ্চিত হন।',
        ),
        LearnBoardOption(
          id: 'bushing',
          labelBn: 'ফাটা বুশিং-এর ওপরই ডিও লাগানো',
          asset: 'assets/game/art/m5_board58/htfuse_bushing.svg',
          scene: true,
          correct: false,
          rejectBn: 'এইচটি বুশিং পাংচারও কারণ — দোষ ট্রান্সফরমারে হলে বিচ্ছিন্ন করে ওয়ার্কশপে পাঠান।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বারবার চার্জে ট্রান্সফরমার বিস্ফোরিত হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সব এলটি খুলে ডিও দিলে বোঝা যায় দোষ কোথায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভেতরে দোষ হলে বিচ্ছিন্ন করে ওয়ার্কশপে পাঠান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'এলটি শর্ট বা বুশিং পাংচারেও ফিউজ উড়ে যায়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'বারবার ফিউজ দিলে ফল্ট জ্বলে নিজেই সেরে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'এইচটি ফিউজ উড়লে দোষ শুধু এইচটি লাইনেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মোটা তার দিয়ে ফিউজ বাঁধলে আর উড়বে না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফাটা বুশিং নিয়েও ট্রান্সফরমার দিব্যি চলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'এলটি সাইডের শর্টে এইচটি ফিউজের কিছু হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'noise',
      promptBn: 'ট্রান্সফরমার হামিং-এর বদলে জোরে, অনিয়মিত খটখট করছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'load',
          labelBn: 'টং টেস্টারে আগে লোড পরীক্ষা',
          asset: 'assets/game/art/m5_board58/noise_load.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'report',
          labelBn: 'লোড ঠিক, শব্দ চলছে — সুপারভাইজারকে ফোন',
          asset: 'assets/game/art/m5_board58/noise_report.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'walkaway',
          labelBn: 'শব্দ পাত্তা না দিয়ে চলে যাওয়া',
          asset: 'assets/game/art/m5_board58/noise_walkaway.svg',
          scene: true,
          correct: false,
          rejectBn: 'জোরালো, অনিয়মিত শব্দ স্বাভাবিক হামিং নয় — শব্দ হলো ট্রান্সফরমারের \'ভাষা\', সে বিপদের কথা বলছে।',
        ),
        LearnBoardOption(
          id: 'tickok',
          labelBn: 'লোড ঠিক দেখে খাতায় \'ঠিক আছে\' লেখা',
          asset: 'assets/game/art/m5_board58/noise_tickok.svg',
          scene: true,
          correct: false,
          rejectBn: 'লোড স্বাভাবিক থাকলেও শব্দ বন্ধ না হলে সমস্যা ভেতরের — সুপারভাইজারকে রিপোর্ট করুন।',
        ),
        LearnBoardOption(
          id: 'guess',
          labelBn: 'লোড না মেপেই \'ভেতরে শর্ট\' লিখে দেওয়া',
          asset: 'assets/game/art/m5_board58/noise_guess.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওভারলোডিং-এর কারণেও শব্দ বাড়তে পারে — আগে লোড পরীক্ষা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অস্বাভাবিক শব্দ মানে ট্রান্সফরমার বিপদ জানাচ্ছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ওভারলোডেও শব্দ বাড়ে, তাই আগে লোড পরীক্ষা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লোড ঠিক তবু শব্দ থামেনি — সুপারভাইজারকে জানান', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ট্রান্সফরমার একটু খটখট করলে কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লোড ঠিক থাকলে শব্দ নিয়ে ভাবার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'শব্দ শুনেই ভেতরের শর্ট ধরে নেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'জোরে শব্দ মানে শুধু ট্রান্সফরমারটা পুরনো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'রাতে লোড কমলে শব্দ নিজে থেকেই চলে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'leak',
      promptBn: 'ট্রান্সফরমারের গা বেয়ে তেল চুইয়ে পড়ছে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'watch',
          labelBn: 'সামান্য লিক, লেভেল ঠিক — নজরে রাখা',
          asset: 'assets/game/art/m5_board58/leak_watch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'fix',
          labelBn: 'বড় লিক — বন্ধ করে সারানো, তেল টপ-আপ',
          asset: 'assets/game/art/m5_board58/leak_fix.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'driveoff',
          labelBn: 'বড় তেলের দাগ দেখেও গাড়ি নিয়ে চলে যাওয়া',
          asset: 'assets/game/art/m5_board58/leak_driveoff.svg',
          scene: true,
          correct: false,
          rejectBn: 'লিক বেশি হলে ট্রান্সফরমার বন্ধ করে লিক সারান এবং তেল টপ-আপ করুন।',
        ),
        LearnBoardOption(
          id: 'wipe',
          labelBn: 'তেলের দাগ মুছে দিয়ে কাজ শেষ',
          asset: 'assets/game/art/m5_board58/leak_wipe.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল লিক মানে শুধু তেল নষ্ট নয় — ভেতরে আর্দ্রতা ঢোকার পথও তৈরি হয়।',
        ),
        LearnBoardOption(
          id: 'pour',
          labelBn: 'উৎস না খুঁজেই তেল ঢেলে দেওয়া',
          asset: 'assets/game/art/m5_board58/leak_pour.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে লিকের উৎস আর পরিমাণ নির্ণয় করুন — গ্যাসকেট, ওয়েল্ডিং জয়েন্ট না আঘাত।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লিক দিয়ে ভেতরে আর্দ্রতা ঢোকার পথ তৈরি হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আগে লিকের উৎস আর পরিমাণ নির্ণয় করুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বড় লিকে বন্ধ করে সারিয়ে তেল টপ-আপ করুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সামান্য লিকে লেভেল ঠিক থাকলে নজরে রাখুন', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'তেলের দাগ মুছে দিলেই লিক সেরে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'উৎস না খুঁজে তেল ঢেলে দিলেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তেল লিক মানে শুধু একটু তেল নষ্ট হওয়া', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বড় লিকেও ট্রান্সফরমার চালু রাখা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মাটির তেলের দাগ পুরনো, ভাবার কিছু নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ltdead',
      promptBn: 'এইচটি ফিউজ ঠিক আছে, কিন্তু এলটি-র একটা ফেজে ভোল্টেজ নেই — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'check',
          labelBn: 'বন্ধ করে টেস্টারে ডেড, তারপর বুশিং কানেকশন',
          asset: 'assets/game/art/m5_board58/ltdead_check.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'swap',
          labelBn: 'কানেকশন ঠিক — ট্রান্সফরমার বদলানো',
          asset: 'assets/game/art/m5_board58/ltdead_swap.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'livespanner',
          labelBn: 'ডিও লাগানো অবস্থায় এলটি বুশিং-এ স্প্যানার',
          asset: 'assets/game/art/m5_board58/ltdead_livespanner.svg',
          scene: true,
          correct: false,
          rejectBn: 'চালু ট্রান্সফরমারে স্প্যানার মারাত্মক — আগে বন্ধ করে টেস্টারে ডেড প্রমাণ, তারপর এলটি বুশিং-এর কানেকশন।',
        ),
        LearnBoardOption(
          id: 'newlink',
          labelBn: 'না-ওড়া ডিও-তে নতুন ফিউজ লাগানো',
          asset: 'assets/game/art/m5_board58/ltdead_newlink.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই লক্ষণে এইচটি ফিউজ ঠিক আছে — দোষ এলটি বুশিং-এর কানেকশনে বা ভেতরের এলটি ওয়াইন্ডিং-এ।',
        ),
        LearnBoardOption(
          id: 'leftrun',
          labelBn: 'কানেকশন ঠিক, তবু ট্রান্সফরমার চালু রাখা',
          asset: 'assets/game/art/m5_board58/ltdead_leftrun.svg',
          scene: true,
          correct: false,
          rejectBn: 'কানেকশন ঠিক থাকলে সমস্যাটি ভেতরের — ট্রান্সফরমারটি বদলাতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে বন্ধ, টেস্টারে ডেড প্রমাণ, তারপর হাত', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এলটি বুশিং-এর কানেকশন খুললেও ফেজ মরে যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কানেকশন ঠিক থাকলে দোষ ভেতরে — বদলাতে হবে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'এইচটি ফিউজ ঠিক থাকলেও নতুন ফিউজ দিলেই হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চালু অবস্থায় স্প্যানারে কানেকশন টাইট চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'এক ফেজ মরা থাকলেও ট্রান্সফরমার চলুক', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'গ্লাভস থাকলে টেস্টার ছাড়াই কাজ করা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কানেকশন ঠিক মানে ট্রান্সফরমারও নিশ্চয় ঠিক', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'proof',
      promptBn: 'সন্দেহের ট্রান্সফরমার — ভেতরের রোগ ধরতে কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'ir',
          labelBn: 'বিচ্ছিন্ন ট্রান্সফরমারে মেগারে IR প্রায় শূন্য',
          asset: 'assets/game/art/m5_board58/proof_ir.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'oil',
          labelBn: 'খুব কালো তেলে কার্বনের কণা ভাসছে',
          asset: 'assets/game/art/m5_board58/proof_oil.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bushing',
          labelBn: 'বুশিং-এ ফাটল আর ফ্ল্যাশওভারের দাগ',
          asset: 'assets/game/art/m5_board58/proof_bushing.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'livemegger',
          labelBn: 'চালু ট্রান্সফরমারেই মেগারের লিড',
          asset: 'assets/game/art/m5_board58/proof_livemegger.svg',
          scene: true,
          correct: false,
          rejectBn: 'চালু ট্রান্সফরমারে মেগারের লিড মারাত্মক — মেগার পরীক্ষা ট্রান্সফরমারকে লাইন থেকে বিচ্ছিন্ন করে তবেই।',
        ),
        LearnBoardOption(
          id: 'water',
          labelBn: 'তেলে জলের ফোঁটা দেখেও অবহেলা',
          asset: 'assets/game/art/m5_board58/proof_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'জল তেলের সবচেয়ে বড় শত্রু — ডাই-ইলেকট্রিক স্ট্রেন্থ নাটকীয়ভাবে কমায়।',
        ),
        LearnBoardOption(
          id: 'records',
          labelBn: 'পুরনো রেকর্ড খাতা ফেলে দেওয়া',
          asset: 'assets/game/art/m5_board58/proof_records.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরনো রেকর্ড দেখুন — আগেও খারাপ হয়েছিল কি, বারবার ওভারলোড হয় কি; ইতিহাস অনেক সূত্র দেবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মেগার পরীক্ষা শুধু বিচ্ছিন্ন ট্রান্সফরমারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'IR প্রায় শূন্য মানে ভেতরে শর্টের প্রমাণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কালো, পোড়া গন্ধের তেল মানে ভেতরে আর্কিং', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বুশিং-এ ফাটল বা ফ্ল্যাশওভারের দাগ খুঁজুন', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'চালু অবস্থাতেই মেগারে IR মাপা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তেল জলকে আলাদা রাখে, তাই জলে ভয় নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তেল কালো হলেও ভেতরের ইনসুলেশন ঠিক থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পুরনো রেকর্ড দেখে রোগ ধরায় কোনো লাভ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বুশিং-এর কালো দাগ শুধুই ধুলোর পুরনো ছাপ', correct: false),
        LearnWhyChip(id: 'w10', textBn: 'IR কম হলেও ট্রান্সফরমার চালানো যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board58Lines.rivalTaunt,
    rivalLineBn: M5Board58Lines.rivalMyth,
    exitBn: M5Board58Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    // The turned-round ask (about half the runs) — a yes/no question with a
    // guide clip, as on board 5.7.
    flipStingBn: 'এই লোক যা বলছে… সেটা কি ভুল?',
    // Point at the weak spots of his claim, never at the answer (the right
    // myth chips must not be read off these tags).
    dangerHints: [
      'এলটি-তে ফিউজ নেই — তাই নিরাপদ?',
      '"কিছু হয় না" — সত্যি?',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'বড় এলটি শর্ট ট্রান্সফরমারে প্রচণ্ড চাপ দেয়', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'এলটি শর্টেও এইচটি ফিউজ উড়ে যেতে পারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'দীর্ঘ এলটি ফল্টে ট্রান্সফরমার পুড়ে যেতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'এলটি ফিউজ না থাকলে ফল্ট নিজেই থেমে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'এলটি-র শর্ট কখনো এইচটি ফিউজে পৌঁছায় না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ট্রান্সফরমার এলটি ফল্ট টেরই পায় না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ডিপি স্ট্রাকচারে এলটি ফল্টে কোনো ভয় নেই', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'এলটি শর্ট শুধু গ্রাহকের বাড়ির সমস্যা', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'এইচটি ফিউজ উড়লে দোষ শুধু এইচটি লাইনে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held) until the director
/// records them with `tool/rival_clip.py`.
abstract final class M5Board58Lines {
  static const rivalTaunt = 'আরে, এলটি-র শর্ট নিয়ে এত মাথাব্যথা কেন?';

  /// Lesson 5.8's first myth buster, word for word.
  static const rivalMyth = 'ট্রান্সফরমারের এলটি সাইডে ফিউজ থাকে না, তাই এলটি ফল্টে ট্রান্সফরমারের কিছু হয় না।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
