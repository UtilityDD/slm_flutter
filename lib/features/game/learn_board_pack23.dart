import 'learn_board_models.dart';

/// Rung `2.3/learn` — Module 2 Lesson 2.3 (ল্যাগস ক্রিম্পিং: সঠিক চাপ,
/// নিরাপদ কানেকশন), the picture board (engineType `learn_cards`, pack
/// `learn_2_3`).
///
/// Picture cards are vector close-ups on the work bench from
/// `tool/m2_board23_art.py`. Every round and every trap comes from the lesson:
///  * match: the wire's size = the lug's size; aluminium wire → aluminium
///    lug, copper wire → copper lug (two metals together → galvanic
///    corrosion); a wrong size is too loose or too tight (damages the
///    conductor from inside);
///  * tool: a hand crimper for small wire, a hydraulic crimper for big cable;
///    the die must match the wire and the lug; ordinary pliers cannot give
///    the right pressure or shape (the lesson's second myth);
///  * prep (golden rules 1–2 + the safety tip): strip to the right length so
///    the conductor goes fully into the barrel and the insulation stays
///    outside; brush the conductor clean (oil or dirt raises resistance);
///    the circuit's power supply off before crimping;
///  * press (golden rule 3 + pro tip 2): the die on the right place of the
///    barrel, full pressure until the tool releases itself / completes its
///    cycle — half pressure makes a weak crimp;
///  * check (golden rule 4 + good vs bad): smooth symmetric (hexagonal)
///    crimp, die marks clear, no crack, all strands inside, the pull test;
///    under-crimp, over-crimp (cracked lug), wrong shape, strands outside.
/// The rival's myth is the lesson's first: soldering after crimping makes it
/// stronger (it does not — crimping is a cold weld; solder heat softens the
/// conductor and vibration loosens it).
const learnBoardPack23 = LearnBoardPack(
  lessonId: '2.3',
  titleBn: 'ল্যাগস ক্রিম্পিং: সঠিক চাপ, নিরাপদ কানেকশন',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'নেটওয়ার্ক ততটাই শক্তিশালী, যতটা তার সবচেয়ে দুর্বল সংযোগ। নিখুঁত ক্রিম্পিং চিনে নিন।',
  earnedBn: 'মাপ মিলিয়ে, পুরো চাপে, টেনে দেখে — ক্রিম্পিং এখন আপনার হাতে নিরাপদ।',
  slots: [
    LearnBoardSlot(
      id: 'match',
      promptBn: 'তারে ল্যাগ লাগানোর আগে — কোনটা পারফেক্ট ম্যাচ?',
      options: [
        LearnBoardOption(id: 'al_al', labelBn: 'অ্যালুমিনিয়াম তারে অ্যালুমিনিয়াম ল্যাগ', asset: 'assets/game/art/m2_board23/match_al_al.svg', scene: true, correct: true),
        LearnBoardOption(id: 'cu_cu', labelBn: 'তামার তারে তামার ল্যাগ', asset: 'assets/game/art/m2_board23/match_cu_cu.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'al_cu',
          labelBn: 'অ্যালুমিনিয়াম তারে তামার ল্যাগ',
          asset: 'assets/game/art/m2_board23/match_al_cu.svg',
          scene: true,
          correct: false,
          rejectBn: 'দুটি ভিন্ন মেটেরিয়াল একসাথে মানে গ্যালভানিক করোশন — অ্যালুমিনিয়াম তারে অ্যালুমিনিয়াম ল্যাগ।',
        ),
        LearnBoardOption(
          id: 'cu_al',
          labelBn: 'তামার তারে অ্যালুমিনিয়াম ল্যাগ',
          asset: 'assets/game/art/m2_board23/match_cu_al.svg',
          scene: true,
          correct: false,
          rejectBn: 'তামা আর অ্যালুমিনিয়াম একসাথে মানে গ্যালভানিক করোশন — তামার তারে তামার ল্যাগ।',
        ),
        LearnBoardOption(
          id: 'thin',
          labelBn: 'সরু তারে মোটা ব্যারেলের ল্যাগ',
          asset: 'assets/game/art/m2_board23/match_thin.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল সাইজের ল্যাগে ক্রিম্পিং খুব ঢিলা হয় — লুজ কানেকশন। তারের সাইজেই ল্যাগ।',
        ),
        LearnBoardOption(
          id: 'fat',
          labelBn: 'মোটা তারে সরু ব্যারেলের ল্যাগ',
          asset: 'assets/game/art/m2_board23/match_fat.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল সাইজে ক্রিম্পিং খুব বেশি টাইট হয় — কন্ডাক্টর ভেতর থেকে ক্ষতিগ্রস্ত হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তারের যে সাইজ, ঠিক সেই সাইজের ল্যাগ চাই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'একই মেটেরিয়াল মেলালে গ্যালভানিক করোশন হয় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঠিক ম্যাচে ক্রিম্প ঢিলাও নয়, বেশি টাইটও নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো ধাতুর ল্যাগ হলেই কারেন্ট ঠিক চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বড় ল্যাগ নিলে তার সহজে ঢোকে, তাই ভালো', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তামা ভালো পরিবাহী, তাই সব তারে তামার ল্যাগ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সাইজ একটু কমবেশি হলে চাপেই মিলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'মোটা তারের কিছু স্ট্র্যান্ড কেটে ঢুকিয়ে দিই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ল্যাগের সাইজ মেলানো স্টোরের লোকের কাজ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'tool',
      promptBn: 'ক্রিম্প করবেন কী দিয়ে — কোনটা ঠিক টুল আর ডাই?',
      options: [
        LearnBoardOption(id: 'hand', labelBn: 'ছোট তারে হ্যান্ড ক্রিম্পার, মাপের ডাই', asset: 'assets/game/art/m2_board23/tool_hand.svg', scene: true, correct: true),
        LearnBoardOption(id: 'hydraulic', labelBn: 'বড় কেবিলে হাইড্রোলিক ক্রিম্পার', asset: 'assets/game/art/m2_board23/tool_hydraulic.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'pliers',
          labelBn: 'সাধারণ প্লায়ার্স দিয়ে ল্যাগ চাপা',
          asset: 'assets/game/art/m2_board23/tool_pliers.svg',
          scene: true,
          correct: false,
          rejectBn: 'সাধারণ প্লায়ার্স সঠিক চাপ আর আকৃতি দিতে পারে না — সংযোগ দুর্বল, অনির্ভরযোগ্য।',
        ),
        LearnBoardOption(
          id: 'hand_big',
          labelBn: 'বড় কেবিলে ছোট হ্যান্ড ক্রিম্পার',
          asset: 'assets/game/art/m2_board23/tool_hand_big.svg',
          scene: true,
          correct: false,
          rejectBn: 'বড় কেবিলের জন্য হাইড্রোলিক ক্রিম্পার — হ্যান্ড ক্রিম্পার ছোট তারের জন্য।',
        ),
        LearnBoardOption(
          id: 'die_big',
          labelBn: 'ল্যাগের চেয়ে বড় মাপের ডাই',
          asset: 'assets/game/art/m2_board23/tool_die_big.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাই তার আর ল্যাগের সাইজে না মিললে ক্রিম্প খুব ঢিলা হয় — লুজ কানেকশন।',
        ),
        LearnBoardOption(
          id: 'die_small',
          labelBn: 'ল্যাগের চেয়ে ছোট মাপের ডাই',
          asset: 'assets/game/art/m2_board23/tool_die_small.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল ডাইয়ে ক্রিম্প খুব বেশি টাইট হয় — কন্ডাক্টর ভেতর থেকে ক্ষতিগ্রস্ত হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ছোট তারে হ্যান্ড, বড় কেবিলে হাইড্রোলিক টুল', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'টুলের ডাই তার আর ল্যাগের সাইজে মিলতে হবে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সঠিক ক্রিম্পিং টুলই ঠিক চাপ আর আকৃতি দেয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো প্লায়ার্স দিয়েই ছোট ল্যাগ চাপা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ডাই বড় হলেও জোরে চাপলে ঠিক বসে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হাতের কাছে যে টুল আছে, সেটাই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বড় কেবিলেও হ্যান্ড ক্রিম্পারে কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছোট ডাইয়ে বেশি টাইট হয়, তাই আরও মজবুত', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হাতুড়ি দিয়ে ঠুকে দিলেও ক্রিম্প হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'prep',
      promptBn: 'ল্যাগে তার ঢোকানোর আগে প্রস্তুতি — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'ok', labelBn: 'কন্ডাক্টর পুরো ব্যারেলে, ইনসুলেশন বাইরে', asset: 'assets/game/art/m2_board23/prep_ok.svg', scene: true, correct: true),
        LearnBoardOption(id: 'brush', labelBn: 'ঢোকানোর আগে ব্রাশে কন্ডাক্টর সাফ', asset: 'assets/game/art/m2_board23/prep_brush.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'half',
          labelBn: 'কন্ডাক্টর অর্ধেক ব্যারেলে ঢোকানো',
          asset: 'assets/game/art/m2_board23/prep_half.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ডাক্টরটিকে ল্যাগের ভেতরে সম্পূর্ণভাবে ঢোকান — অর্ধেক খালি ব্যারেলে নির্ভরযোগ্য সংযোগ হয় না।',
        ),
        LearnBoardOption(
          id: 'ins_in',
          labelBn: 'কম ছিলে ইনসুলেশনসহ ব্যারেলে',
          asset: 'assets/game/art/m2_board23/prep_ins_in.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইনসুলেশন সঠিক মাপে ছিলুন — ইনসুলেশন থাকবে ব্যারেলের বাইরে, ভেতরে শুধু কন্ডাক্টর।',
        ),
        LearnBoardOption(
          id: 'oily',
          labelBn: 'তেল-ময়লা মাখা কন্ডাক্টর ঢোকানো',
          asset: 'assets/game/art/m2_board23/prep_oily.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল বা ময়লা থাকলে রেজিস্ট্যান্স বেড়ে যায় — আগে পরিষ্কার ব্রাশে কন্ডাক্টর সাফ করুন।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'সার্কিট চালু রেখেই ক্রিম্পিং',
          asset: 'assets/game/art/m2_board23/prep_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'ক্রিম্পিং করার আগে নিশ্চিত করুন যে সার্কিটের পাওয়ার সাপ্লাই বন্ধ আছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কন্ডাক্টর পুরো ব্যারেলে, ইনসুলেশন থাকে বাইরে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পরিষ্কার কন্ডাক্টরে রেজিস্ট্যান্স কম থাকে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ক্রিম্পিংয়ের আগে সার্কিটের পাওয়ার বন্ধ চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তেল-ময়লা থাকলেও চাপে সব ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ইনসুলেশন ভেতরে গেলে সংযোগ আরও শক্ত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অর্ধেক ঢোকালেই ক্রিম্প ধরে, পুরোটা লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চালু সার্কিটেও সাবধানে ক্রিম্প করা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছিলার মাপ আন্দাজে করলেই কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ব্রাশ দিয়ে সাফ করা শুধু সময় নষ্ট', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'press',
      promptBn: 'ডাই ব্যারেলে বসেছে — চাপ দেওয়ার সময় কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'full', labelBn: 'টুল নিজে রিলিজ হওয়া পর্যন্ত পুরো চাপ', asset: 'assets/game/art/m2_board23/press_full.svg', scene: true, correct: true),
        LearnBoardOption(id: 'hyd_full', labelBn: 'হাইড্রোলিকের পুরো সাইকেল শেষ করা', asset: 'assets/game/art/m2_board23/press_hyd_full.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'half',
          labelBn: 'অর্ধেক চাপ দিয়েই হাতল ছেড়ে দেওয়া',
          asset: 'assets/game/art/m2_board23/press_half.svg',
          scene: true,
          correct: false,
          rejectBn: 'অর্ধেক চাপ দিয়ে করা ক্রিম্পিং দুর্বল হয় — টুল সাইকেল শেষ না করা পর্যন্ত পুরো চাপ।',
        ),
        LearnBoardOption(
          id: 'hyd_half',
          labelBn: 'হাইড্রোলিক পাম্প মাঝপথে থামানো',
          asset: 'assets/game/art/m2_board23/press_hyd_half.svg',
          scene: true,
          correct: false,
          rejectBn: 'হাইড্রোলিক টুলেও সম্পূর্ণ চাপ দিন, যতক্ষণ না সাইকেল শেষ হয় — মাঝপথে থামলে ক্রিম্প দুর্বল।',
        ),
        LearnBoardOption(
          id: 'palm',
          labelBn: 'ব্যারেল ছেড়ে ল্যাগের মাথায় চাপ',
          asset: 'assets/game/art/m2_board23/press_palm.svg',
          scene: true,
          correct: false,
          rejectBn: 'টুল রাখতে হবে ল্যাগের ব্যারেলের ওপর সঠিক জায়গায় — চ্যাপ্টা মাথায় চাপে তার ধরে না।',
        ),
        LearnBoardOption(
          id: 'edge',
          labelBn: 'ব্যারেলের কিনারে আধাআধি ডাই',
          asset: 'assets/game/art/m2_board23/press_edge.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডাই বসাতে হবে ব্যারেলের ওপর সঠিক জায়গায় — কিনারে আধাআধি বসালে ক্রিম্প ভুল আকৃতির হয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পুরো চাপ দিন, যতক্ষণ না টুল নিজে রিলিজ হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সাইকেল শেষ হলে তবেই ক্রিম্প পুরো মজবুত', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ডাই বসবে ব্যারেলের ওপর ঠিক জায়গায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অর্ধেক চাপেই কাজ হয়, বাকিটা দরকার নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ল্যাগের যেকোনো জায়গায় চাপলেই চলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'তাড়াতাড়ি করতে মাঝপথে হাতল ছাড়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পাম্প মাঝপথে থামালেও তার ঠিক আটকে থাকে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কিনারে চাপ দিলে ক্রিম্প বেশি শক্ত হয়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'টুল রিলিজ না হলে জোর করে খুলে নিই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'check',
      promptBn: 'ক্রিম্প শেষ — পরিদর্শনে কোনটা ভালো ক্রিম্প?',
      options: [
        LearnBoardOption(id: 'hex', labelBn: 'মসৃণ ষড়ভুজাকার ক্রিম্প, স্ট্র্যান্ড ভেতরে', asset: 'assets/game/art/m2_board23/check_hex.svg', scene: true, correct: true),
        LearnBoardOption(id: 'pull', labelBn: 'হাতে টেনে দেখা — সংযোগ আলগা নয়', asset: 'assets/game/art/m2_board23/check_pull.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'under',
          labelBn: 'অসম্পূর্ণ চাপে তার বেরিয়ে আসছে',
          asset: 'assets/game/art/m2_board23/check_under.svg',
          scene: true,
          correct: false,
          rejectBn: 'অসম্পূর্ণ চাপ (Under-crimped) — পুল টেস্টে আলগা। খারাপ ক্রিম্প চিনে আবার করাই দক্ষতা।',
        ),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'অতিরিক্ত চাপে ফেটে যাওয়া ল্যাগ',
          asset: 'assets/game/art/m2_board23/check_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'অতিরিক্ত চাপে (Over-crimped) ল্যাগ ফেটে যায় — ভালো ক্রিম্পে ল্যাগের গায়ে কোনো ফাটল নেই।',
        ),
        LearnBoardOption(
          id: 'shape',
          labelBn: 'ভুল ডাইয়ে বাঁকা, অসম আকৃতি',
          asset: 'assets/game/art/m2_board23/check_shape.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল ডাই ব্যবহারে ভুল আকৃতি তৈরি হয় — ভালো ক্রিম্প মসৃণ ও প্রতিসম।',
        ),
        LearnBoardOption(
          id: 'strands',
          labelBn: 'ব্যারেলের মুখে স্ট্র্যান্ড বেরিয়ে',
          asset: 'assets/game/art/m2_board23/check_strands.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্ডাক্টরের স্ট্র্যান্ড বাইরে বেরিয়ে থাকা খারাপ ক্রিম্প — সব স্ট্র্যান্ড থাকবে ভেতরে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মসৃণ, প্রতিসম আকৃতি আর ডাই-এর চিহ্ন স্পষ্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পুল টেস্টে টানলেও সংযোগ আলগা হয় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ফাটল নেই, সব স্ট্র্যান্ড ব্যারেলের ভেতরে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটু ফাটা ল্যাগেও কারেন্ট ঠিকই চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'টেনে দেখলে সংযোগ নষ্ট হয়, তাই টানি না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'দু-একটা স্ট্র্যান্ড বাইরে থাকলে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আকৃতি যেমনই হোক, চাপ পড়লেই কাজ হলো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'খারাপ ক্রিম্প আবার করা লজ্জার ব্যাপার', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'বেশি চাপে ল্যাগ ফাটলে আরও শক্ত হয়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: CrimpBoardLines.rivalTaunt,
    rivalLineBn: CrimpBoardLines.rivalMyth,
    exitBn: CrimpBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'ক্রিম্পের ওপর সোল্ডারিং',
      'তাপে নরম কন্ডাক্টর',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ক্রিম্পিং কোল্ড-ওয়েল্ডিং, ঝালাই লাগে না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'সোল্ডারের তাপ কন্ডাক্টরকে নরম করে দেয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'কম্পনে সোল্ডার করা সংযোগ আলগা হতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ঝালাই দিলে যেকোনো সংযোগ আরও মজবুত হয়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'সোল্ডারের তাপে কন্ডাক্টর আরও শক্ত হয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ক্রিম্প আর ঝালাই দুটো মিলিয়ে ডবল সুরক্ষা', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'ভালো ক্রিম্পেও সবসময় সোল্ডার লাগে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'কম্পনে ঝালাই করা জোড় কখনো নড়ে না', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'ঢিলা ক্রিম্প ঝালাই দিয়ে ঠিক করা যায়', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board. The exit is already in his
/// recorded voice; the taunt and the myth play through device TTS until they
/// are recorded (`toRecord`).
abstract final class CrimpBoardLines {
  static const rivalTaunt = 'আরে! ক্রিম্প তো হলো, এবার একটু ঝালাই দিয়ে দাও!';

  /// Lesson 2.3's first myth buster, word for word.
  static const rivalMyth = 'ক্রিম্পিং-এর পর সংযোগটি সোল্ডার করে দিলে এটি আরও মজবুত হয়ে যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival clips this board needs recorded.
  static const toRecord = [rivalTaunt, rivalMyth];
}
