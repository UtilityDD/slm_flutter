import 'learn_board_models.dart';

/// Module 5 Lesson 5.4 (ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী বনাম স্থায়ী
/// ফল্ট), the picture board (rung `5.4/learn`, pack `learn_5_4`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m5_board54_art.py`. Every round
/// and every trap comes from the lesson text (section "একই অপরাধ, বারবার"),
/// its pro tips and its myth buster:
///  * where: a DTR's HT DO fuse that keeps blowing can have its fault on the
///    HT line before the DTR (bad insulator, a branch), inside the DTR (a
///    winding short, the most serious) or on the LT side (a big short in the
///    LT network or a consumer's house) — never "HT only" (myth 2); a thick
///    wire in the barrel ruins the diagnostic tool (pro tip 1); charging again
///    and again is 'Fault Burning' (myth 1, strictly forbidden);
///  * transient: lightning, two conductors clashing in wind, a bird or small
///    animal; a snapped wire on the ground, a broken insulator and a fault
///    inside the DTR are permanent;
///  * blast: a fuse that blows at once with a big blast and arc is a
///    permanent fault — trying to charge again is 'মারাত্মক ভুল' (Module 5
///    ruling M5-1, deadly class); patrol, find, repair, then charge;
///  * reblow: a fuse that holds for hours, then blows: line history, weather
///    and a visual check of spans sagging low and branches too close;
///  * section: when unsure, every LT outgoing out, then the HT fuse; LT ways
///    back one at a time; the megger on the suspect feeder afterwards
///    (pro tip 3); a loud abnormal DTR sound is a danger sign (pro tip 2);
///    patience, never a hurried guess (pro tip 4).
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack54 = LearnBoardPack(
  lessonId: '5.4',
  titleBn: 'ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী বনাম স্থায়ী ফল্ট',
  badgeBn: 'ফল্ট ফাইন্ডার',
  introBn: 'ফিউজ লাগালেন, আবার উড়ল! অভিজ্ঞ ডাক্তারের মতো কারণ খুঁজুন — অস্থায়ী না স্থায়ী ফল্ট?',
  earnedBn: 'সাথে সাথে বিস্ফোরণ মানে স্থায়ী ফল্ট — আবার চার্জ নয়, পেট্রোলিং আর মেরামত। নিশ্চিত না হলে সেকশনালাইজিং।',
  slots: [
    LearnBoardSlot(
      id: 'where',
      promptBn: 'ডিটিআর-এর এইচটি ডিও ফিউজ বারবার উড়ছে। ফল্ট কোথায় থাকতে পারে?',
      options: [
        LearnBoardOption(
          id: 'htline',
          labelBn: 'ডিটিআর-এর আগের এইচটি লাইনে ডাল বা খারাপ ইনসুলেটর',
          asset: 'assets/game/art/m5_board54/where_htline.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'tank',
          labelBn: 'ট্রান্সফরমারের ভেতরের ওয়াইন্ডিং-এ শর্ট',
          asset: 'assets/game/art/m5_board54/where_tank.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'lt',
          labelBn: 'এলটি নেটওয়ার্কে বা গ্রাহকের বাড়িতে বড় শর্ট',
          asset: 'assets/game/art/m5_board54/where_lt.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'htonly',
          labelBn: 'এইচটি ফিউজ উড়েছে, তাই শুধু এইচটি লাইন খোঁজা',
          asset: 'assets/game/art/m5_board54/where_htonly.svg',
          scene: true,
          correct: false,
          rejectBn: 'না। একটি বড় এলটি শর্ট সার্কিটও ট্রান্সফরমারের এইচটি ফিউজকে উড়িয়ে দিতে পারে — এইচটি, এলটি বা ট্রান্সফরমারের ভেতরে, যেকোনো জায়গায়।',
        ),
        LearnBoardOption(
          id: 'thick',
          labelBn: 'ফিউজ ব্যারেলে মোটা তামার তার জড়ানো',
          asset: 'assets/game/art/m5_board54/where_thick.svg',
          scene: true,
          correct: false,
          rejectBn: 'মোটা তার বা ভুল রেটিং-এর ফিউজ নয় — এটি আপনার ডায়াগনস্টিক টুলকেই নষ্ট করে।',
        ),
        LearnBoardOption(
          id: 'burn',
          labelBn: 'বারবার লাগিয়ে ফল্টটা জ্বালিয়ে দেওয়া',
          asset: 'assets/game/art/m5_board54/where_burn.svg',
          scene: true,
          correct: false,
          rejectBn: "এটা 'Fault Burning' — যন্ত্রপাতি আরও ক্ষতিগ্রস্ত হয়, আগুন লাগতে পারে। এই অভ্যাস কঠোরভাবে নিষিদ্ধ।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'এইচটি, ডিটিআর বা এলটি — তিন জায়গাতেই ফল্ট হতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বড় এলটি শর্টও ট্রান্সফরমারের এইচটি ফিউজ ওড়াতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে সমস্যার উৎসকে ছোট করে আনাই প্রথম কাজ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ট্রান্সফরমারের ভেতরের শর্ট সবচেয়ে গুরুতর সমস্যা', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'এইচটি ফিউজ উড়লে সমস্যা সবসময় এইচটি লাইনেই থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গ্রাহকের বাড়ির শর্ট কখনো এইচটি ফিউজ ওড়ায় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'মোটা তার জড়ালে ফিউজ আর ওড়ে না, সমস্যা শেষ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কয়েকবার চার্জ দিলে ফল্ট নিজেই পুড়ে সেরে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ট্রান্সফরমারের ভেতরে কখনো কোনো ফল্ট হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'transient',
      promptBn: 'ফিউজ লাগানোর পর লাইন কিছুক্ষণ ঠিক চলল, তারপর আবার উড়ল। কোনটা এমন অস্থায়ী ফল্টের কারণ?',
      options: [
        LearnBoardOption(
          id: 'lightning',
          labelBn: 'লাইনের কাছে বজ্রপাত',
          asset: 'assets/game/art/m5_board54/transient_lightning.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'clash',
          labelBn: 'বাতাসে দুটি তার একে অপরের সাথে লাগা',
          asset: 'assets/game/art/m5_board54/transient_clash.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'bird',
          labelBn: 'দুই তারের মাঝে বসা পাখি',
          asset: 'assets/game/art/m5_board54/transient_bird.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'snapped',
          labelBn: 'ছিঁড়ে মাটিতে পড়ে থাকা তার',
          asset: 'assets/game/art/m5_board54/transient_snapped.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছিঁড়ে পড়া তার নিজে থেকে ঠিক হয় না — এটা স্থায়ী ফল্ট, মেরামত লাগে।',
        ),
        LearnBoardOption(
          id: 'insulator',
          labelBn: 'ভাঙা পিন ইনসুলেটর',
          asset: 'assets/game/art/m5_board54/transient_insulator.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা ইনসুলেটর স্থায়ী ফল্ট — নিজে সারে না, মেরামত লাগে।',
        ),
        LearnBoardOption(
          id: 'smoke',
          labelBn: 'ট্রান্সফরমার ট্যাঙ্ক থেকে ধোঁয়া',
          asset: 'assets/game/art/m5_board54/transient_smoke.svg',
          scene: true,
          correct: false,
          rejectBn: 'ট্রান্সফরমারের ভেতরের ফল্ট স্থায়ী ফল্ট — বারবার চার্জে আরও ক্ষতি, আগুনের ঝুঁকি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অস্থায়ী ফল্টের কারণ ক্ষণস্থায়ী, নিজেই সরে যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বজ্রপাত, বাতাসে তার লাগা, পাখি — অস্থায়ী কারণ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কিছুক্ষণ চলে আবার ওড়া অস্থায়ী ফল্টের লক্ষণ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ওভারহেড লাইনের প্রায় 80-90% ফল্টই অস্থায়ী', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'ছেঁড়া তার কিছুক্ষণ পরে নিজে থেকেই জুড়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভাঙা ইনসুলেটর বৃষ্টি থামলে আবার ঠিক হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ট্রান্সফরমারের ধোঁয়া একটু পরে নিজেই থামে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অস্থায়ী ফল্টে ফিউজ লাগানো মাত্রই উড়ে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'যে ফল্ট চোখে দেখা যায় সেটাই অস্থায়ী ফল্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'blast',
      promptBn: 'লাগানোর সাথে সাথেই বড় বিস্ফোরণ আর আর্ক সহ ফিউজ আবার উড়ল। এখন কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'patrol',
          labelBn: 'লাইন ধরে পেট্রোলিং করে ফল্ট খোঁজা',
          asset: 'assets/game/art/m5_board54/blast_patrol.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'repair',
          labelBn: 'খুঁজে পাওয়া ফল্ট মেরামত, তারপরই চার্জ',
          asset: 'assets/game/art/m5_board54/blast_repair.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'reclose',
          labelBn: 'রড তুলে একই ফিউজ আবার লাগানো',
          asset: 'assets/game/art/m5_board54/blast_reclose.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই ক্ষেত্রে লাইন পুনরায় চার্জ করার চেষ্টা করা একটি মারাত্মক ভুল — আগে পেট্রোলিং করে ফল্ট খুঁজে মেরামত।',
        ),
        LearnBoardOption(
          id: 'thick',
          labelBn: 'ক্যারিয়ারে মোটা তার বেঁধে আবার লাগানো',
          asset: 'assets/game/art/m5_board54/blast_thick.svg',
          scene: true,
          correct: false,
          rejectBn: 'মোটা তার কখনো নয় — এটি ডায়াগনস্টিক টুলকেই নষ্ট করে, আর স্থায়ী ফল্টে যন্ত্রপাতির আরও ক্ষতি।',
        ),
        LearnBoardOption(
          id: 'wait',
          labelBn: 'ফল্ট নিজে সরবে ভেবে বসে থাকা',
          asset: 'assets/game/art/m5_board54/blast_wait.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্থায়ী ফল্ট নিজে থেকে ঠিক হয় না — পেট্রোলিং করে খুঁজে মেরামত করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সাথে সাথে বিস্ফোরণ আর আর্ক মানে স্থায়ী ফল্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'স্থায়ী ফল্টে আবার চার্জ করা মারাত্মক ভুল', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পেট্রোলিং করে ফল্ট খুঁজে মেরামত করতেই হবে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বারবার চার্জে যন্ত্রপাতির ক্ষতি, আগুনের ঝুঁকি', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'আরেকবার লাগালে ফিউজ হয়তো এবার টিকে যাবে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মোটা তার দিলে ফিউজ বিস্ফোরণ সহ্য করে নেয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'স্থায়ী ফল্ট কিছুক্ষণ পরে নিজে থেকেই সরে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আর্ক হলেও লাইন আবার চার্জ করে দেখা নিরাপদ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বিস্ফোরণ মানে শুধু ফিউজটাই খারাপ ছিল', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'reblow',
      promptBn: 'ফিউজ কয়েক ঘণ্টা ঠিক চলে আবার উড়ল। কোথায় নজর দেবেন?',
      options: [
        LearnBoardOption(
          id: 'sag',
          labelBn: 'পাশের স্প্যানের চেয়ে অনেক বেশি ঝোলা তার',
          asset: 'assets/game/art/m5_board54/reblow_sag.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'branch',
          labelBn: 'তারের খুব কাছে চলে আসা গাছের ডাল',
          asset: 'assets/game/art/m5_board54/reblow_branch.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'log',
          labelBn: 'খাতায় লাইনের আগের ঘটনা আর আবহাওয়া দেখা',
          asset: 'assets/game/art/m5_board54/reblow_log.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'refit',
          labelBn: 'কিছু না দেখেই বারবার ফিউজ লাগানো',
          asset: 'assets/game/art/m5_board54/reblow_refit.svg',
          scene: true,
          correct: false,
          rejectBn: 'কারণ সম্পর্কে নিশ্চিত না হয়ে বারবার লাইন চার্জ করা বিপজ্জনক হতে পারে।',
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: '"চলছে তো" বলে গাড়ি নিয়ে চলে যাওয়া',
          asset: 'assets/game/art/m5_board54/reblow_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'লাইনের ইতিহাস, আবহাওয়া আর চাক্ষুষ পরিদর্শন দিয়ে ঝোলা তার আর কাছের ডাল পরীক্ষা করুন।',
        ),
        LearnBoardOption(
          id: 'burn',
          labelBn: 'ডাল পোড়াতে বারবার চার্জ করা',
          asset: 'assets/game/art/m5_board54/reblow_burn.svg',
          scene: true,
          correct: false,
          rejectBn: "এতে হয়তো ছোট ডাল পোড়ে, কিন্তু 'Fault Burning' অত্যন্ত বিপজ্জনক — এই অভ্যাস কঠোরভাবে নিষিদ্ধ।",
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ইতিহাস ও আবহাওয়া দেখে অস্থায়ী ফল্ট খুঁজুন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বেশি ঝোলা তার আর কাছের ডাল ভালো করে দেখুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'চাক্ষুষ পরিদর্শনেই লুকোনো কারণ ধরা পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কারণ না জেনে বারবার চার্জ করা বিপজ্জনক', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'কয়েক ঘণ্টা চললে লাইনে আর কোনো সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডাল ছুঁয়ে থাকলে চার্জ করে পুড়িয়ে দিলেই হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'অস্থায়ী ফল্ট খুঁজে দেখার কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ঝোলা তার কখনো ফিউজ ওড়ার কারণ হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বারবার ফিউজ লাগালেই কারণ বোঝা হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'section',
      promptBn: 'ফল্ট কোথায় নিশ্চিত নন। সেকশনালাইজিং-এর সঠিক ধাপ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'ltout',
          labelBn: 'সব এলটি আউটগোয়িং খুলে তবেই এইচটি ফিউজ',
          asset: 'assets/game/art/m5_board54/section_ltout.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'onebyone',
          labelBn: 'একটি একটি করে এলটি ফিডারের ফিউজ লাগানো',
          asset: 'assets/game/art/m5_board54/section_onebyone.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'megger',
          labelBn: 'সেকশনালাইজিং-এর পর সন্দেহজনক ফিডারে মেগার',
          asset: 'assets/game/art/m5_board54/section_megger.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'roar',
          labelBn: 'সব এলটি লাগানো রেখেই এইচটি চার্জ',
          asset: 'assets/game/art/m5_board54/section_roar.svg',
          scene: true,
          correct: false,
          rejectBn: 'আগে এলটি-র সমস্ত আউটগোয়িং খুলুন। এলটি-তে ফল্ট রেখে চার্জ করলে জোরালো অস্বাভাবিক শব্দ — এটা বিপদের সংকেত।',
        ),
        LearnBoardOption(
          id: 'allback',
          labelBn: 'সব এলটি ফিউজ একসাথে ফিরিয়ে লাগানো',
          asset: 'assets/game/art/m5_board54/section_allback.svg',
          scene: true,
          correct: false,
          rejectBn: 'একটি একটি করে এলটি ফিডার লাগান — যেটা লাগাতেই এইচটি ফিউজ উড়বে, ফল্ট সেই ফিডারেই।',
        ),
        LearnBoardOption(
          id: 'guess',
          labelBn: 'তাড়াহুড়োয় আন্দাজে একটা ফিডার ধরা',
          asset: 'assets/game/art/m5_board54/section_guess.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফল্ট খোঁজা ধৈর্যের কাজ — তাড়াহুড়ো করে ভুল সিদ্ধান্ত নয়, ধাপে ধাপে সেকশনালাইজিং।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'এলটি খুলে এইচটি টিকলে সমস্যা এলটি নেটওয়ার্কে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'যে ফিডার লাগাতেই এইচটি ওড়ে, ফল্ট সেখানেই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মেগার দিয়ে ইনসুলেশন ফল্ট সহজে ধরা যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ফল্ট খোঁজা ধৈর্যের কাজ, তাড়াহুড়োর নয়', correct: true),
        LearnWhyChip(id: 'w5', textBn: 'সব এলটি লাগানো রেখে চার্জ দিলেই কাজ দ্রুত', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সব ফিউজ একসাথে লাগালে ফল্ট নিজেই ধরা দেয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ট্রান্সফরমারের জোরালো শব্দ স্বাভাবিক ব্যাপার', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'অভিজ্ঞ লাইনম্যান আন্দাজেই ফিডার ধরে ফেলে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সেকশনালাইজিং শুধু বড় সাবস্টেশনের কাজ', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M5Board54Lines.rivalTaunt,
    rivalLineBn: M5Board54Lines.rivalMyth,
    exitBn: M5Board54Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'স্থায়ী ফল্টে বারবার চার্জ',
      'আগুনের ঝুঁকি',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: "'Fault Burning' অত্যন্ত বিপজ্জনক, কঠোরভাবে নিষিদ্ধ", correct: true),
      LearnWhyChip(id: 'm2', textBn: 'স্থায়ী ফল্টে বারবার চার্জে যন্ত্রপাতির ক্ষতি বাড়ে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'স্থায়ী ফল্টে বারবার চার্জ করলে আগুন লাগতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'কয়েকবার চার্জ দিলে যেকোনো ফল্ট পুড়ে সেরে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'পুরনো অভ্যাস, তাই এটা নিরাপদ আর পরীক্ষিত', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ডাল একবার পুড়ে গেলে লাইন চিরকাল ভালো থাকে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'চার্জ করে দেখাই ফল্ট খোঁজার সবচেয়ে সহজ পথ', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ফিউজ উড়লে কোনো যন্ত্রপাতির ক্ষতি হয় না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'বারবার চার্জ করলে ফল্ট নিজেই জায়গা দেখায়', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] stay silent (caption held for reading) until the
/// director records them with `tool/rival_clip.py`.
abstract final class M5Board54Lines {
  static const rivalTaunt = 'আরে, এত খোঁজাখুঁজি কেন? আরেকবার চার্জ দিন!';

  /// Lesson 5.4's first myth buster, word for word.
  static const rivalMyth = 'লাইনটা কয়েকবার চার্জ করে দেখলেই ফল্টটা জ্বলে গিয়ে নিজে থেকেই ঠিক হয়ে যাবে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
