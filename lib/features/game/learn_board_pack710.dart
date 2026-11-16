import 'learn_board_models.dart';

/// Module 7 Lesson 7.10 (একজন 'সার্টিফায়েড' লাইনম্যান: লাইসেন্স ও যোগ্যতার
/// গুরুত্ব), the picture board (rung `7.10/learn`, pack `learn_7_10`,
/// engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board710_art.py` (no words in
/// the art). Every round and trap comes from the live lesson text and the
/// Module 7 rulings (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_710.json`):
///  * comp: who the law calls 'উপযুক্ত' (point 1) — the live text has NO age
///    rule (ruling X3, open item O2), so the under-18 helper of the item spec
///    is replaced by a man whose name is not on the company register. Safe:
///    a government certificate (or work permit) + his name on the register
///    + a senior beside him; a man who knows the danger and keeps his crew
///    away from it. Traps: a new man sent up the pole on his first day, a
///    strong labourer with no training, a joiner left alone with a booklet,
///    a certificate with no name on the register. A trap here is a slip,
///    worded as a breach of the law, never as allowed (ruling M7-5);
///  * permit: how a workman permit comes (point 2): schooling such as ITI, a
///    set number of years of work, and an exam or interview before the state
///    licensing board. The lesson says 'ভারতের অনেক রাজ্যে' and 'সাধারণত',
///    so no year count and no qualification level is dealt. Traps: experience
///    and no exam, an exam and an empty logbook, the company ID shown as the
///    permit;
///  * paper: the paper a big contractor asks for — the workman permit (point
///    2's importance line), on its own or on top of the ITI file. Traps: only
///    a first aid and fire safety certificate, only words, only an ITI
///    certificate;
///  * grow: what a good professional does next (point 3): live-line training,
///    HV cable jointing certification, first aid and fire safety training (the
///    lesson's three examples). Traps: skipping the company's training,
///    leaving the new tool unopened, 'I know it all';
///  * habit: pro tips 1–4 — the personal logbook, asking the senior, a goal and
///    a course to match. Traps: certificates torn and scattered, a silent
///    junior, framed certificates with the gloves still in their wrapper.
/// No deadly anywhere on this board (the deadly act of 7.10, an uncertified
/// man on energised live-line work, is do_7_10_a only — ruling M7-5), and
/// boards have no freeze (kit design): every trap costs the round's ◆ and says
/// its lesson words. The rival's myth is the lesson's first myth, word for
/// word (ruling M7-10; the second myth is the Do level's coworker line).
///
/// Every new line here is a DRAFT for the owner's wording (rulings M6-12,
/// M7-10). No YouTube explainer id (ruling M6-14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack710 = LearnBoardPack(
  lessonId: '7.10',
  titleBn: "একজন 'সার্টিফায়েড' লাইনম্যান: লাইসেন্স ও যোগ্যতার গুরুত্ব",
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board710Lines.intro,
  earnedBn: M7Board710Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'comp',
      promptBn: "বিদ্যুৎ লাইনে কাজের জন্য আইন যাকে 'উপযুক্ত' বলে — কোনটা?",
      options: [
        LearnBoardOption(
          id: 'cert',
          labelBn: 'সরকারি সার্টিফিকেট আছে, রেজিস্টারে নাম, পাশে সিনিয়র',
          asset: 'assets/game/art/m7_board710/comp_cert.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'aware',
          labelBn: 'বিপদ চেনেন, ডেঞ্জার প্লেট দেখিয়ে সবাইকে সরাচ্ছেন',
          asset: 'assets/game/art/m7_board710/comp_aware.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'new',
          labelBn: 'প্রথম দিনের নতুন লোককে পোলে উঠতে বলা হচ্ছে',
          asset: 'assets/game/art/m7_board710/comp_new.svg',
          scene: true,
          correct: false,
          // Live point 1's importance line, word for word.
          rejectBn: 'প্রশিক্ষণ ছাড়া আপনাকে কোনো ঝুঁকিপূর্ণ কাজে পাঠানোটা আইনের লঙ্ঘন।',
        ),
        LearnBoardOption(
          id: 'strong',
          labelBn: 'গায়ে জোর আছে, প্রশিক্ষণ নেই, ক্রস-আর্ম তুলছেন',
          asset: 'assets/game/art/m7_board710/comp_strong.svg',
          scene: true,
          correct: false,
          rejectBn: 'গায়ের জোর নয় — চাই পর্যাপ্ত প্রশিক্ষণ ও অভিজ্ঞতা, যাতে বিপদ চিনে এড়াতে পারেন।',
        ),
        LearnBoardOption(
          id: 'booklet',
          labelBn: 'হাতে শুধু একটা বই, "নিজে বুঝে নাও" বলে সরে গেলেন',
          asset: 'assets/game/art/m7_board710/comp_booklet.svg',
          scene: true,
          correct: false,
          rejectBn: 'সঠিক প্রশিক্ষণ দিতে কোম্পানি আইনত বাধ্য — নিজে বুঝে নিয়ে ঝুঁকির কাজে নয়।',
        ),
        LearnBoardOption(
          id: 'noreg',
          labelBn: 'সার্টিফিকেট আছে, কিন্তু রেজিস্টারে নামটাই নেই',
          asset: 'assets/game/art/m7_board710/comp_noreg.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোম্পানির রেজিস্টারে নাম থাকতেই হবে — না থাকলে কাজে পাঠানো আইনের লঙ্ঘন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সার্টিফিকেট বা পারমিট, রেজিস্টারে নাম আর প্রশিক্ষণ চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বিপদ চিনে তা এড়াতে জানাই আসল যোগ্যতা, গায়ের জোর নয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কর্মীকে সঠিক প্রশিক্ষণ দিতে কোম্পানি আইনত বাধ্য', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গায়ে জোর থাকলেই লাইনের কাজের জন্য যোগ্য ধরা হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটা বই হাতে ধরিয়ে দিলেই প্রশিক্ষণ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রেজিস্টারে নাম না থাকলেও সার্টিফিকেট থাকলেই চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'প্রথম দিন থেকে পোলে উঠলে কাজ তাড়াতাড়ি শেখা হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'দেখে দেখে শিখে নিলে আলাদা প্রশিক্ষণ লাগে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সবাই লাইনে কাজ করে, তাই আলাদা যোগ্যতা লাগে না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'permit',
      promptBn: 'ওয়ার্কম্যান পারমিট পাওয়ার সাধারণ পথ কোনটা?',
      options: [
        LearnBoardOption(
          id: 'path',
          labelBn: 'ITI-র সার্টিফিকেট, কাজের বছর আর পরীক্ষার কাগজ',
          asset: 'assets/game/art/m7_board710/permit_path.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'board',
          labelBn: 'রাজ্যের লাইসেন্সিং বোর্ডের টেবিলে ইন্টারভিউ',
          asset: 'assets/game/art/m7_board710/permit_board.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'expnoexam',
          labelBn: 'অনেক বছরের অভিজ্ঞতা, পরীক্ষার কাগজ সরিয়ে দিচ্ছেন',
          asset: 'assets/game/art/m7_board710/permit_expnoexam.svg',
          scene: true,
          correct: false,
          rejectBn: 'অভিজ্ঞতার সাথে পরীক্ষা বা ইন্টারভিউ পাশও লাগে — তবেই পারমিট।',
        ),
        LearnBoardOption(
          id: 'examnoexp',
          labelBn: 'পরীক্ষায় পাশ, কিন্তু অভিজ্ঞতার লগবুক ফাঁকা',
          asset: 'assets/game/art/m7_board710/permit_examnoexp.svg',
          scene: true,
          correct: false,
          rejectBn: 'নির্দিষ্ট বছরের কাজের অভিজ্ঞতাও লাগে — শুধু পরীক্ষায় পারমিট হয় না।',
        ),
        LearnBoardOption(
          id: 'compid',
          labelBn: 'কোম্পানির পরিচয়পত্রই পারমিট বলে দেখানো হচ্ছে',
          asset: 'assets/game/art/m7_board710/permit_compid.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট দেয় রাজ্য সরকারের লাইসেন্সিং বোর্ড — কোম্পানির পরিচয়পত্র নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সাধারণত শিক্ষা, কাজের বছর আর পরীক্ষা বা ইন্টারভিউ লাগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'রাজ্য সরকারের লাইসেন্সিং বোর্ড থেকেই পারমিট মেলে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এই পারমিটই প্রমাণ করে আপনি কাজের জন্য আইনত যোগ্য', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অভিজ্ঞতা থাকলে পরীক্ষা বা ইন্টারভিউ বাদ দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পরীক্ষায় পাশ করলে অভিজ্ঞতা ছাড়াই পারমিট মেলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কোম্পানির পরিচয়পত্র আর সরকারি পারমিট একই জিনিস', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পারমিট কোম্পানি নিজেই ছাপিয়ে কর্মীর হাতে দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পারমিটের জন্য শুধু একটা আবেদন জমা দিলেই হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ঠিকাদার বললেই বোর্ড ছাড়াই পারমিট হাতে মেলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'paper',
      promptBn: 'বড় ঠিকাদারের কাজে ডাক পেলেন — কোন কাগজ আপনার যোগ্যতা প্রমাণ করবে?',
      options: [
        LearnBoardOption(
          id: 'permit',
          labelBn: 'ঠিকাদারের অফিসে ওয়ার্কম্যান পারমিট কার্ড দেখানো',
          asset: 'assets/game/art/m7_board710/paper_permit.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'withiti',
          labelBn: 'ওয়ার্কম্যান পারমিটের নিচে ITI-র কাগজও গোছানো',
          asset: 'assets/game/art/m7_board710/paper_withiti.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'firstaid',
          labelBn: 'হাতে শুধু ফার্স্ট এইড আর ফায়ার সেফটির সার্টিফিকেট',
          asset: 'assets/game/art/m7_board710/paper_firstaid.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফার্স্ট এইড প্রশিক্ষণ দামি, কিন্তু অনেক ঠিকাদারের শর্ত ওয়ার্কম্যান পারমিট।',
        ),
        LearnBoardOption(
          id: 'word',
          labelBn: 'খালি হাতে শুধু মুখে বলা, "বছরের পর বছর করছি"',
          asset: 'assets/game/art/m7_board710/paper_word.svg',
          scene: true,
          correct: false,
          rejectBn: 'মুখের কথা নয় — লাইসেন্সই প্রমাণ করে আপনি আইনত যোগ্য ও দক্ষ।',
        ),
        LearnBoardOption(
          id: 'iti',
          labelBn: 'হাতে শুধু ITI-র সার্টিফিকেট, ওয়ার্কম্যান পারমিট নেই',
          asset: 'assets/game/art/m7_board710/paper_iti.svg',
          scene: true,
          correct: false,
          rejectBn: 'ITI পারমিটের একটা যোগ্যতা মাত্র — অভিজ্ঞতা আর পরীক্ষা পেরিয়ে তবেই পারমিট।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ওয়ার্কম্যান পারমিটই আপনার আইনি যোগ্যতার প্রমাণ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বড় ঠিকাদারের অনেক কাজে এটা আবশ্যক শর্ত', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'এতে আপনার পেশাগত মূল্য ও বিশ্বাসযোগ্যতা বাড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মুখে অভিজ্ঞ বললেই ঠিকাদার যোগ্য বলে মেনে নেয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফার্স্ট এইডের সার্টিফিকেট থাকলে পারমিট লাগে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কাগজ দেখানোর দরকার নেই, কাজের কথাই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ITI-র সার্টিফিকেটই সব জায়গায় পারমিটের কাজ করে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পারমিট থাকা না থাকায় কাজ পাওয়ায় ফারাক হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বড় কোম্পানি কর্মীর কাছে কোনো কাগজই চায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'grow',
      promptBn: 'কাজ শিখে গেছেন — এরপর একজন ভালো পেশাদার কী করেন?',
      options: [
        LearnBoardOption(
          id: 'live',
          labelBn: 'লাইভ লাইন কাজের ক্লাস, হাতে ইনসুলেটেড রড',
          asset: 'assets/game/art/m7_board710/grow_live.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hv',
          labelBn: 'HV কেবিল জয়েন্টিংয়ের সার্টিফিকেশন, পাশে পরীক্ষক',
          asset: 'assets/game/art/m7_board710/grow_hv.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'aid',
          labelBn: 'ডামিতে CPR আর আগুন নেভানোর ফার্স্ট এইড ট্রেনিং',
          asset: 'assets/game/art/m7_board710/grow_aid.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'skip',
          labelBn: 'প্রশিক্ষণের নোটিশ পেরিয়ে বাড়ির দিকে হাঁটা',
          asset: 'assets/game/art/m7_board710/grow_skip.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোম্পানির প্রশিক্ষণের সুযোগ কখনো হাতছাড়া করবেন না।',
        ),
        LearnBoardOption(
          id: 'old',
          labelBn: 'নতুন যন্ত্রের বাক্স বন্ধ, পুরোনো পদ্ধতিতেই কাজ',
          asset: 'assets/game/art/m7_board710/grow_old.svg',
          scene: true,
          correct: false,
          rejectBn: 'নতুন সরঞ্জাম, নতুন নিয়ম আসছে — আপডেট না থাকলে কাজের মান ও সুরক্ষা কমে।',
        ),
        LearnBoardOption(
          id: 'knowall',
          labelBn: 'ক্লাসঘরের বাইরে হাত গুটিয়ে "সব জানি" ভাব',
          asset: 'assets/game/art/m7_board710/grow_knowall.svg',
          scene: true,
          correct: false,
          rejectBn: 'শেখার কোনো শেষ নেই — নিজেকে আপডেট না করলে পিছিয়ে পড়বেন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'নতুন সরঞ্জাম আর নিয়ম শিখলে কাজে সুরক্ষা থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্রমাগত শিখলে ক্যারিয়ারে এগোনোর পথ খুলে যায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কোম্পানির আয়োজন করা প্রশিক্ষণ নিলেই দক্ষতা বাড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'দক্ষ লাইনম্যান হওয়ার পর আর প্রশিক্ষণ লাগে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'প্রশিক্ষণ শুধু নতুন কর্মীদের জন্য, পুরোনোদের নয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পুরোনো পদ্ধতিতে কাজ চালালে সুরক্ষা আরও বাড়ে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'প্রশিক্ষণে সময় দিলে ক্যারিয়ারে পিছিয়ে পড়তে হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সার্টিফিকেশন নেওয়া শুধু অফিসের লোকের কাজ', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নতুন সরঞ্জাম এলে সেটা না খুলে রাখাই ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'habit',
      promptBn: 'নিজের পেশাকে গড়ে তোলার ঠিক অভ্যাস কোনটা?',
      options: [
        LearnBoardOption(
          id: 'log',
          labelBn: 'দিনের কাজ, প্রকল্প আর প্রশিক্ষণ নিজের লগবুকে লেখা',
          asset: 'assets/game/art/m7_board710/habit_log.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'senior',
          labelBn: 'পোলের নিচে সিনিয়রকে প্রশ্ন করে শিখে নেওয়া',
          asset: 'assets/game/art/m7_board710/habit_senior.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'goal',
          labelBn: 'কেবিল জয়েন্টিংয়ের কোর্স বেছে লক্ষ্য ঠিক করা',
          asset: 'assets/game/art/m7_board710/habit_goal.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'norec',
          labelBn: 'সার্টিফিকেটগুলো গাড়ির মেঝেতে ছেঁড়া, এলোমেলো',
          asset: 'assets/game/art/m7_board710/habit_norec.svg',
          scene: true,
          correct: false,
          rejectBn: 'কী কাজ, কোন প্রকল্প, কোন প্রশিক্ষণ — লগবুকে লিখুন; লাইসেন্স ও ইন্টারভিউতে কাজে দেবে।',
        ),
        LearnBoardOption(
          id: 'shy',
          labelBn: 'কিছু না বুঝে গাড়ির আড়ালে চুপ করে লুকানো',
          asset: 'assets/game/art/m7_board710/habit_shy.svg',
          scene: true,
          correct: false,
          rejectBn: 'সিনিয়ররা জ্ঞানের ভান্ডার — প্রশ্ন করতে কখনো লজ্জা পাবেন না।',
        ),
        LearnBoardOption(
          id: 'paper',
          labelBn: 'দেয়ালে সার্টিফিকেটের সারি, গ্লাভস প্যাকেটেই বন্ধ',
          asset: 'assets/game/art/m7_board710/habit_paper.svg',
          scene: true,
          correct: false,
          rejectBn: 'অভিজ্ঞতা অপরিহার্য — সার্টিফিকেট সেই অভিজ্ঞতারই আইনগত স্বীকৃতি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'এই অভ্যাস লাইসেন্স পাওয়া ও ইন্টারভিউতে কাজে দেয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শেখার জন্য নিজে উদ্যোগ নেওয়াই পেশা গড়ার পথ', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সার্টিফিকেটের পেছনে সত্যিকারের কাজের অভিজ্ঞতা চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সার্টিফিকেট সামলে রাখা সময় নষ্ট, কাজই আসল', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'প্রশ্ন করলে সবাই ভাববে আমি কিছুই জানি না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দেয়ালে সার্টিফিকেট সাজালেই অভিজ্ঞতা হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লক্ষ্য ঠিক না করে যা পাই তাই শিখলেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কী কাজ করলাম তা মনে রাখার কোনো দরকারই নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'নিজে নিজে আন্দাজে কাজ চালানোই সবচেয়ে ভালো', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board710Lines.rivalTaunt,
    rivalLineBn: M7Board710Lines.rivalMyth,
    exitBn: M7Board710Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'সুরক্ষার নিয়ম পাল্টায়',
      'না শিখলে পিছিয়ে পড়া',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'প্রযুক্তি আর সুরক্ষার নিয়ম প্রতিদিনই পাল্টাচ্ছে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'নিজেকে আপডেট না করলে কাজের মান ও সুরক্ষা কমে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'শিখে গেছি বলে থেমে গেলে পিছিয়ে পড়তে হয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'একবার শিখলেই সারা জীবনের মতো কাজ চলে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'নতুন সরঞ্জাম এলেও পুরোনো পদ্ধতিই সবচেয়ে ঠিক', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'নতুন নিয়ম শেখা শুধু অফিসারের কাজ, লাইনম্যানের নয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'আপডেট না থাকলে কাজের মান আরও বেড়ে যায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'প্রশিক্ষণে গেলে শুধু সময় নষ্ট, লাভ কিছু নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'যত পুরোনো কর্মী, নতুন নিয়ম তার তত কম লাগে', correct: false),
    ],
  ),
);

/// The board's fixed lines: the guide's intro and closing line, and the
/// careless coworker's lines. [rivalExit] is already in his recorded voice;
/// [toRecord] stay silent (caption held for reading) until the director
/// records them with `tool/rival_clip.py`.
abstract final class M7Board710Lines {
  /// DRAFT wording — owner.
  static const intro = 'লাইনের কাজে কে আইনত যোগ্য, পারমিট কীভাবে মেলে, শেখা কেন থামে না — ছবি দেখে চিনে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'সার্টিফিকেট বা পারমিট, রেজিস্টারে নাম আর প্রশিক্ষণ — তবেই উপযুক্ত। শেখা থামাবেন না, লগবুকে সব লিখে রাখুন।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'কাজ তো শিখেই গেছি, আবার শেখার কী আছে?';

  /// Lesson 7.10's first myth, word for word (ruling M7-10; not new text, but
  /// it needs a clip).
  static const rivalMyth = 'একবার কাজ শিখে গেলে আর নতুন করে শেখার কিছু নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Rulings M6-12 / M7-10: the rival's new lines (the taunt is a draft; the
  /// myth is the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// Rulings M6-12 / M7-10: every guide line on this board, for the owner's
  /// wording pass and the voice session (lesson quotes in the trap reasons
  /// included, since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting, the myth's right reasons, the earned
  /// line).
  static List<String> get guideSpoken {
    final p = learnBoardPack710;
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
