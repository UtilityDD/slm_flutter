import 'learn_board_models.dart';

/// Module 7 Lesson 7.6 (ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন), the
/// picture board (rung `7.6/learn`, pack `learn_7_6`, engineType
/// `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board76_art.py` (no words in
/// the art; the glove cuff label, the type digit, the IS codes on the plates,
/// the docket's "11" and the diary's date are stroke glyphs with English
/// digits). Every round and trap comes from the live lesson text
/// (`tool/all_training_chapters_bn.json`, 7.6) and the Module 7 rulings
/// (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_76.json`):
///  * source: section 1 — the employer must supply the right PPE; asking a
///    worker to buy his own helmet or gloves is illegal, right PPE is a
///    basic right. Traps: cash at a roadside stall, cheap market PPE (myth 1's
///    reality), an empty store shelf (pro tip 1: the right to refuse the
///    risky job);
///  * glove: section 1 — PPE by the job's risk; for an 11 kV line the glove is
///    'IS 4770 টাইপ 4' (up to 17,000 volts), never "11 kV gloves" (rulings
///    X3, O3). The cuff shows the code and the palm the type digit. Traps: an
///    unmarked pair, a type 2 pair, a torn pair (the module's deadly act R10
///    when signed for or packed; boards teach, they never freeze), a pair in
///    a shop bag without certification (section 3);
///  * mark: section 3 — the IS mark, and IS 2925 for helmets, IS 15298 for
///    safety shoes. Traps: no mark, the other item's code (R12 slips);
///  * duty: section 2 — the worker's duties: use the issued PPE properly and
///    always, care for it and keep it clean, report damage at once, never
///    refuse it on a risky job; myth 2's reality (no difference between
///    the experienced and the new);
///  * size: pro tips 2, 3 and 4 — the right size, training before new PPE or
///    tools, and a record (date and whom you told) of every damage report.
/// Five rounds, as the item spec has them. The rival's myth is the lesson's
/// first myth, word for word (ruling M7-10).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack76 = LearnBoardPack(
  lessonId: '7.6',
  titleBn: 'ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board76Lines.intro,
  earnedBn: M7Board76Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'source',
      promptBn: 'কাজের PPE কোথা থেকে আসবে? কোন ছবিটা আইন মেনে?',
      options: [
        LearnBoardOption(
          id: 'store',
          labelBn: 'স্টোরের কাউন্টারে হেলমেট ও গ্লাভস',
          asset: 'assets/game/art/m7_board76/source_store.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'van',
          labelBn: 'ভ্যানের পাশে সুপারভাইজারের হাতে বাক্স',
          asset: 'assets/game/art/m7_board76/source_van.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'cash',
          labelBn: 'রাস্তার দোকানে হেলমেট নেওয়া হচ্ছে',
          asset: 'assets/game/art/m7_board76/source_cash.svg',
          scene: true,
          correct: false,
          rejectBn: 'আপনাকে নিজের টাকা দিয়ে কাজের জন্য হেলমেট বা গ্লাভস কিনতে বলাটা বেআইনি। সঠিক PPE পাওয়া আপনার মৌলিক অধিকার।',
        ),
        LearnBoardOption(
          id: 'market',
          labelBn: 'দোকানের তাকে চকচকে নতুন হেলমেট',
          asset: 'assets/game/art/m7_board76/source_market.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাজার থেকে কেনা সস্তা এবং নন-সার্টিফায়েড PPE আপনাকে সুরক্ষার মিথ্যা আশ্বাস দেয় মাত্র, আসল সুরক্ষা নয়।',
        ),
        LearnBoardOption(
          id: 'empty',
          labelBn: 'স্টোরের তাকের সামনে দাঁড়ানো লাইনম্যান',
          asset: 'assets/game/art/m7_board76/source_empty.svg',
          scene: true,
          correct: false,
          rejectBn: 'সঠিক PPE না থাকলে ঝুঁকির কাজটি করতে অস্বীকার করার সম্পূর্ণ অধিকার আছে। আপনার জীবন সবচেয়ে মূল্যবান।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'PPE দেওয়া কোম্পানির আইনি দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সঠিক PPE পাওয়া আপনার মৌলিক অধিকার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কাজের PPE-এর জন্য নিজের টাকা লাগে না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ভালো PPE চাইলে নিজের টাকায় কেনাই নিয়ম', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কোম্পানি না দিলে বাজারের PPE পরলেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'PPE ছাড়াই ঝুঁকির কাজে নামা কর্মীর কর্তব্য', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সস্তা আর সার্টিফায়েড PPE একই সুরক্ষা দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'PPE-এর খরচ কর্মীর বেতন থেকেই কাটা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'স্টোর খালি হলেও চুপচাপ কাজে নামতে হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'glove',
      promptBn: 'ডকেটে লেখা 11 kV লাইনের কাজ — কোন গ্লাভস ঝুঁকি অনুযায়ী ঠিক?',
      options: [
        LearnBoardOption(
          id: 'type4',
          labelBn: 'ডকেটের পাশে এক জোড়া গ্লাভস গ',
          asset: 'assets/game/art/m7_board76/glove_type4.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'store4',
          labelBn: 'স্টোরকিপারের হাতে এক জোড়া গ্লাভস খ',
          asset: 'assets/game/art/m7_board76/glove_store4.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'plain',
          labelBn: 'ডকেটের পাশে এক জোড়া গ্লাভস ক',
          asset: 'assets/game/art/m7_board76/glove_plain.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাজের ঝুঁকি অনুযায়ী সঠিক PPE সরবরাহ করা চাই, যেমন 11 kV লাইনের জন্য IS 4770 টাইপ 4 গ্লাভস, যা 17,000 ভোল্ট পর্যন্ত কাজের জন্য তৈরি।',
        ),
        LearnBoardOption(
          id: 'type2',
          labelBn: 'স্টোরকিপারের হাতে এক জোড়া গ্লাভস ঘ',
          asset: 'assets/game/art/m7_board76/glove_type2.svg',
          scene: true,
          correct: false,
          rejectBn: 'টাইপ 2 নয় — 11 kV লাইনের কাজে IS 4770 টাইপ 4 গ্লাভস, যা 17,000 ভোল্ট পর্যন্ত কাজের জন্য তৈরি।',
        ),
        LearnBoardOption(
          id: 'torn',
          labelBn: 'ডকেটের পাশে এক জোড়া গ্লাভস ঙ',
          asset: 'assets/game/art/m7_board76/glove_torn.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ষতিগ্রস্ত বা মেয়াদ উত্তীর্ণ PPE বদলে দেওয়ার ব্যবস্থা করা কোম্পানির দায়িত্ব — ছেঁড়া গ্লাভস নিয়ে 11 kV লাইনে কাজ করলে প্রাণ যেতে পারে, ব্যাগে নয়, বদলে নিন।',
        ),
        LearnBoardOption(
          id: 'shop',
          labelBn: 'দোকানের ব্যাগে এক জোড়া গ্লাভস চ',
          asset: 'assets/game/art/m7_board76/glove_shop.svg',
          scene: true,
          correct: false,
          rejectBn: 'নন-ব্র্যান্ডেড বা সার্টিফিকেশন ছাড়া PPE ব্যবহার করা একটি বড় ঝুঁকি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঝুঁকি অনুযায়ী ঠিক PPE দেওয়া কোম্পানির দায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: '11 kV কাজের জন্য IS 4770 টাইপ 4 গ্লাভস', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সরবরাহ করা PPE অনুমোদিত IS মানের হওয়া চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো রাবারের গ্লাভসই 11 kV কাজে চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টাইপ যা-ই হোক, গ্লাভস থাকলেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ছেঁড়া গ্লাভস একটু সেলাই করে চালানো যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দোকানের গ্লাভস কোম্পানির গ্লাভসের সমান', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'টাইপ 2 গ্লাভসেও 11 kV-র কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লেবেল ছাড়া গ্লাভসে সুরক্ষা বেশিই হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'mark',
      promptBn: 'গায়ের ছাপ পড়ুন — কোনটার মান ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'helmet',
          labelBn: 'হেলমেট ও তার গায়ের ছাপ ক',
          asset: 'assets/game/art/m7_board76/mark_helmet.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'shoe',
          labelBn: 'জুতো ও তার গায়ের ছাপ ক',
          asset: 'assets/game/art/m7_board76/mark_shoe.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nomark',
          labelBn: 'হেলমেট ও তার গায়ের ছাপ খ',
          asset: 'assets/game/art/m7_board76/mark_nomark.svg',
          scene: true,
          correct: false,
          rejectBn: 'IS মার্ক নিশ্চিত করে যে সরঞ্জামটি সুরক্ষার ন্যূনতম মানদণ্ড পূরণ করেছে — মার্ক না থাকলে সেটা ঝুঁকি।',
        ),
        LearnBoardOption(
          id: 'wrongcode',
          labelBn: 'হেলমেট ও তার গায়ের ছাপ গ',
          asset: 'assets/game/art/m7_board76/mark_wrongcode.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেফটি হেলমেটের জন্য IS 2925, আর সেফটি জুতোর জন্য IS 15298 — এই কোড জুতোর, হেলমেটের নয়।',
        ),
        LearnBoardOption(
          id: 'noshoe',
          labelBn: 'জুতো ও তার গায়ের ছাপ খ',
          asset: 'assets/game/art/m7_board76/mark_noshoe.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেফটি জুতোর জন্য IS 15298। আপনার PPE-এর গায়ে এই IS মার্ক আছে কিনা তা দেখে নিন।',
        ),
        LearnBoardOption(
          id: 'shoecode',
          labelBn: 'জুতো ও তার গায়ের ছাপ গ',
          asset: 'assets/game/art/m7_board76/mark_shoecode.svg',
          scene: true,
          correct: false,
          rejectBn: 'সেফটি জুতোর জন্য IS 15298, আর সেফটি হেলমেটের জন্য IS 2925 — এই কোড হেলমেটের, জুতোর নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'IS মার্ক মানে সুরক্ষার ন্যূনতম মান পূরণ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'PPE-এর গায়ে IS মার্ক আছে কিনা দেখে নিন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হেলমেট আর জুতোর IS কোড আলাদা, মিলিয়ে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'চকচকে চেহারা দেখেই সরঞ্জামের মান বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'IS মার্ক শুধু বাক্সের সাজসজ্জার জন্য থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যেকোনো IS কোড থাকলেই সব সরঞ্জামে চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দাম বেশি হলে মার্ক না থাকলেও চলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নতুন সরঞ্জামে মার্ক খোঁজার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মার্কের চেয়ে সরঞ্জামের রংটাই বেশি জরুরি', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'duty',
      promptBn: 'কোম্পানি PPE দিয়েছে — এবার কর্মীর দায়িত্ব কোন ছবিতে মানা হচ্ছে?',
      options: [
        LearnBoardOption(
          id: 'clean',
          labelBn: 'দিনের শেষে কিটব্যাগের কাছে লাইনম্যান',
          asset: 'assets/game/art/m7_board76/duty_clean.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'report',
          labelBn: 'সাইটে সুপারভাইজারের সামনে লাইনম্যান',
          asset: 'assets/game/art/m7_board76/duty_report.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'wear',
          labelBn: 'পোলের নিচে কাজে নামছেন লাইনম্যান',
          asset: 'assets/game/art/m7_board76/duty_wear.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'mirror',
          labelBn: 'ভ্যানের পাশে পোলের নিচে লাইনম্যান',
          asset: 'assets/game/art/m7_board76/duty_mirror.svg',
          scene: true,
          correct: false,
          rejectBn: 'কোম্পানি দ্বারা সরবরাহ করা PPE সঠিকভাবে এবং সবসময় ব্যবহার করা আপনার দায়িত্ব।',
        ),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'কিটব্যাগের কাছে হেলমেট হাতে লাইনম্যান',
          asset: 'assets/game/art/m7_board76/duty_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'PPE-তে কোনো ক্ষতি বা ত্রুটি দেখা গেলে অবিলম্বে সুপারভাইজারকে রিপোর্ট করা আপনার দায়িত্ব।',
        ),
        LearnBoardOption(
          id: 'mud',
          labelBn: 'কিটব্যাগের কাছে গ্লাভস নিয়ে লাইনম্যান',
          asset: 'assets/game/art/m7_board76/duty_mud.svg',
          scene: true,
          correct: false,
          rejectBn: 'PPE-এর সঠিক যত্ন নেওয়া এবং সেটিকে পরিষ্কার রাখা কর্মীর দায়িত্ব।',
        ),
        LearnBoardOption(
          id: 'senior',
          labelBn: 'পোলের নিচে অভিজ্ঞ প্রবীণ লাইনম্যান',
          asset: 'assets/game/art/m7_board76/duty_senior.svg',
          scene: true,
          correct: false,
          rejectBn: 'আইন অনুযায়ী, ঝুঁকিপূর্ণ কাজে নিযুক্ত প্রত্যেক কর্মীর জন্য PPE বাধ্যতামূলক — অভিজ্ঞতা এবং নতুনত্বের মধ্যে কোনো পার্থক্য নেই।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আইন কর্মীকেও নিজের কিছু দায়িত্ব দিয়েছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পরা, যত্ন নেওয়া, ক্ষতি জানানো — সবই কর্মীর দায়িত্ব', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দেওয়া PPE ঠিক রাখা আর ঠিক পরা কর্মীর কাজ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'PPE দেওয়ার পর সব দায় কোম্পানির একার', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'অভিজ্ঞ লোকের PPE না পরলেও আইনে চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'PPE না পরলেও ক্ষতিপূরণের দাবি ঠিকই থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্ষতি দেখলে চুপচাপ থাকাই ঝামেলা কম', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'নোংরা PPE ব্যবহারে কোনো সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আইনে দায়িত্ব শুধু কোম্পানির, কর্মীর নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'size',
      promptBn: 'সাইজ, প্রশিক্ষণ, রেকর্ড — কোন ছবিটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'fit',
          labelBn: 'হাতের গ্লাভস আর পায়ের জুতোর মাপ খ',
          asset: 'assets/game/art/m7_board76/size_fit.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'train',
          labelBn: 'মাঠে নতুন সরঞ্জাম দেখাচ্ছেন ট্রেনার',
          asset: 'assets/game/art/m7_board76/size_train.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'diary',
          labelBn: 'ডায়েরির পাতায় লেখা একটা লাইন ক',
          asset: 'assets/game/art/m7_board76/size_diary.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'big',
          labelBn: 'হাতের গ্লাভস আর পায়ের জুতোর মাপ ক',
          asset: 'assets/game/art/m7_board76/size_big.svg',
          scene: true,
          correct: false,
          rejectBn: 'জুতো, গ্লাভস বা হারনেসের মতো PPE সঠিক সাইজের হওয়াটা অত্যন্ত জরুরি।',
        ),
        LearnBoardOption(
          id: 'tight',
          labelBn: 'হাতের গ্লাভস আর পায়ের জুতোর মাপ গ',
          asset: 'assets/game/art/m7_board76/size_tight.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল সাইজের PPE সুরক্ষার বদলে অসুবিধার কারণ হতে পারে।',
        ),
        LearnBoardOption(
          id: 'newbox',
          labelBn: 'বাক্স থেকে বের করা নতুন সরঞ্জাম পোলে',
          asset: 'assets/game/art/m7_board76/size_newbox.svg',
          scene: true,
          correct: false,
          rejectBn: 'নতুন ধরনের PPE বা টুল ব্যবহারের আগে সঠিক প্রশিক্ষণের দাবি জানান। এটিও আপনার অধিকার।',
        ),
        LearnBoardOption(
          id: 'blank',
          labelBn: 'ডায়েরির পাতায় লেখা একটা লাইন খ',
          asset: 'assets/game/art/m7_board76/size_blank.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্ষতিগ্রস্ত PPE বদলানোর জন্য রিপোর্ট করলে তার একটি রেকর্ড (যেমন তারিখ এবং কাকে বলেছেন) নিজের কাছে রাখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'সাইজ, প্রশিক্ষণ আর রেকর্ড — তিনটেই চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সুরক্ষা শুধু PPE-তে নয়, সাইজ-শিক্ষা-রেকর্ডেও', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল সাইজ, না-শেখা সরঞ্জাম, না-লেখা রেকর্ড — সবই ঝুঁকি', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সাইজ নিয়ে মাথা ঘামানো শুধু শৌখিনদের কাজ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'নতুন সরঞ্জাম হাতে নিলেই চালাতে শেখা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'রিপোর্ট মুখে বললে লিখে রাখা অপ্রয়োজনীয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বড় সাইজ নিলে সুরক্ষা বেশি, ছোট নিলে কম', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'প্রশিক্ষণ শুধু নতুন কর্মীদের জন্যই দরকার', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'রেকর্ড রাখলে সুপারভাইজার রেগে যান, থাক', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board76Lines.rivalTaunt,
    rivalLineBn: M7Board76Lines.rivalMyth,
    exitBn: M7Board76Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board76Lines.sting,
    dangerHints: [
      'নন-সার্টিফায়েড',
      'ঝুঁকি থেকেই যায়',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'সস্তা নন-সার্টিফায়েড PPE মিথ্যা আশ্বাস মাত্র', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ঠিক PPE না দিলে কর্তৃপক্ষকে রিপোর্ট করা উচিত', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'বাজারের সস্তা PPE আসল সুরক্ষা দেয় না', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'সস্তা হলেও বাজারের PPE-তে একই সুরক্ষা মেলে', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'কোম্পানি না দিলে নিজে কেনাই একমাত্র পথ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'রিপোর্ট করলে চাকরি যায়, তাই কেনাই ভালো', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'দোকানি যা বলে তাতেই PPE-এর মান বোঝা যায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ভালো দেখতে হলেই PPE নিরাপদ ধরে নেওয়া যায়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'নিজের টাকায় কিনলে কোম্পানির দায় বাড়ে', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] and [sting] are
/// already in recorded voices; [toRecord] stay silent (caption held for
/// reading) until the director records them with `tool/rival_clip.py`.
abstract final class M7Board76Lines {
  /// DRAFT wording — owner.
  static const intro = 'PPE পাওয়া আপনার অধিকার, আর ঠিকমতো ব্যবহার করা আপনার দায়িত্ব। ছবি দেখে ঠিকটা বেছে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'PPE দেওয়া কোম্পানির দায়িত্ব; IS মার্ক দেখা, যত্ন নেওয়া আর ক্ষতি জানানো আপনার দায়িত্ব।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'কোম্পানির PPE তো সব বাজে মানের! বাজার থেকে একটা কিনে নিলেই হয়।';

  /// Lesson 7.6's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'কোম্পানি ভালো PPE দেয় না, তাই আমি বাজার থেকে সস্তার একটা কিনে ব্যবহার করি।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// Already recorded (the board 6.3 sting, reused).
  static const sting = 'এই লোক যা বলছে… বিশ্বাস করেন?';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];

  /// Ruling M6-12 / M7-10: the rival's new lines (the taunt is a draft; the
  /// myth is the lesson's own, still to be recorded).
  // DRAFT wording — owner
  static const newRivalLines = toRecord;

  /// Ruling M6-12: every guide line on this board, for the owner's wording
  /// pass and the voice session (lesson quotes in the trap reasons included,
  /// since each spoken line needs a clip).
  // DRAFT wording — owner
  static List<String> get newGuideLines => guideSpoken;

  /// Every line the guide speaks on this board (intro, round prompts, trap
  /// reasons, right reasons, the sting, the myth's right reasons, the earned
  /// line).
  static List<String> get guideSpoken {
    final p = learnBoardPack76;
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
