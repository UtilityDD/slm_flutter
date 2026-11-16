import 'learn_board_models.dart';

/// Module 7 Lesson 7.8 (পরিবেশগত আইন: আমাদের দায়িত্ব), the picture board
/// (rung `7.8/learn`, pack `learn_7_8`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m7_board78_art.py` (no words in
/// the art; every card of a round shares one frame — the DTR with its AB
/// switch opened and locked, never a DO — and only the act in front of it
/// differs). Every round and trap comes from the live lesson text
/// (`tool/all_training_chapters_bn.json`, 7.8) and the Module 7 rulings
/// (`docs/module_specs/module7_rulings.md`, item spec
/// `docs/module_specs/module7_items/board_78.json`):
///  * oil: point 1 — old transformer oil is 'বিপজ্জনক বর্জ্য' (it may hold
///    PCBs); under the Hazardous Waste Management Rules pouring it on the soil
///    or into a drain is a punishable offence; it is collected in a leak-proof
///    drum and handed over only to an authorised recycling agency. Traps: the
///    soil, the roadside drain, an open bucket, an unmarked stranger's van;
///  * spill: pro tip 1 — a spill kit (absorbent pads, boom) at an oil change
///    or a leak; myth 1's reality — soil soaks the oil in, but it reaches the
///    groundwater. Traps: left to soak in, hosed to the drain, soil kicked
///    over it;
///  * ewaste: point 2 — lead and acid in old batteries (Battery Waste
///    Management Rules, 2022), bad circuit boards (E-Waste (Management) Rules,
///    2022): never with ordinary garbage, to the company's collection centre.
///    The live lesson names the battery rule for batteries, so a battery in the
///    garbage vat teaches with it (ruling X3; spec note 'M7-L4');
///  * lamp: point 3 — mercury in tube lights, CFLs and sodium / mercury vapour
///    lamps; hazardous waste, collected whole and sent to an authorised
///    disposal agency. Traps: snapped, in the dustbin, tossed loose;
///  * sep: pro tip 2 and myth 2's reality — hazardous waste (oily rags) apart
///    from ordinary waste in its own bin; the law binds any person or body,
///    and the fine can fall on the person and the company.
/// No deadly act in lesson 7.8 (ruling M7-6): every wrong card is a slip. The
/// board has no freeze (kit design), so each trap teaches with the lesson's
/// own words. The rival's myth is the lesson's first myth, word for word
/// (ruling M7-10).
///
/// Every new line here is a DRAFT for the owner's wording (ruling M6-12).
/// No YouTube explainer id (owner decision 14).
// DRAFT wording — owner (prompts, labels, reason chips, intro, earned line).
const learnBoardPack78 = LearnBoardPack(
  lessonId: '7.8',
  titleBn: 'পরিবেশগত আইন: আমাদের দায়িত্ব',
  badgeBn: 'আইন কি বলে?',
  introBn: M7Board78Lines.intro,
  earnedBn: M7Board78Lines.earned,
  slots: [
    LearnBoardSlot(
      id: 'oil',
      promptBn: 'পুরনো ট্রান্সফরমার অয়েল বদলানো হচ্ছে — কোন ছবিতে কাজ ঠিক?',
      options: [
        LearnBoardOption(
          id: 'drum',
          labelBn: 'পুরনো তেল পাইপে লিক-প্রুফ ড্রামে ভরা',
          asset: 'assets/game/art/m7_board78/oil_drum.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'agency',
          labelBn: 'ড্রাম অনুমোদিত রিসাইক্লিং এজেন্সির গাড়িতে',
          asset: 'assets/game/art/m7_board78/oil_agency.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'soil',
          labelBn: 'পুরনো তেল ক্যান থেকে মাটিতে ঢেলে ফেলা',
          asset: 'assets/game/art/m7_board78/oil_soil.svg',
          scene: true,
          correct: false,
          rejectBn: '\'Hazardous Waste Management Rules\' অনুযায়ী এই তেল মাটিতে ফেলা দণ্ডনীয় অপরাধ — লিক-প্রুফ ড্রামে সংগ্রহ করুন।',
        ),
        LearnBoardOption(
          id: 'drain',
          labelBn: 'পুরনো তেল রাস্তার ধারের ড্রেনে ঢেলে দেওয়া',
          asset: 'assets/game/art/m7_board78/oil_drain.svg',
          scene: true,
          correct: false,
          rejectBn: 'এক লিটার তেল লক্ষ লক্ষ লিটার জলকে দূষিত করতে পারে — ড্রেনে ফেলাও দণ্ডনীয় অপরাধ।',
        ),
        LearnBoardOption(
          id: 'bucket',
          labelBn: 'পুরনো তেল খোলা বালতিতে ঢেলে ধরে রাখা',
          asset: 'assets/game/art/m7_board78/oil_bucket.svg',
          scene: true,
          correct: false,
          rejectBn: 'পুরনো তেল বিপজ্জনক বর্জ্য — খোলা বালতিতে নয়, লিক-প্রুফ ড্রামে সংগ্রহ করতে হবে।',
        ),
        LearnBoardOption(
          id: 'stranger',
          labelBn: 'ড্রাম অচেনা লোকের চিহ্নহীন গাড়িতে তোলা',
          asset: 'assets/game/art/m7_board78/oil_stranger.svg',
          scene: true,
          correct: false,
          rejectBn: 'ড্রাম শুধুমাত্র অনুমোদিত রিসাইক্লিং এজেন্সির কাছে হস্তান্তর করতে হবে, অন্য কারো হাতে নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পুরনো ট্রান্সফরমার তেল বিপজ্জনক বর্জ্য', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এক লিটার তেল লক্ষ লিটার জল দূষিত করতে পারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সংগ্রহ ড্রামে, হস্তান্তর অনুমোদিত এজেন্সিকে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মাটি তেল শুষে নেয়, তাই ঢাললে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ড্রেনে ফেললে জল তেল ধুয়ে নিয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'খোলা বালতিতে রাখলেও তেল নিরাপদ থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ড্রাম যেকোনো গাড়িতে তুলে দিলেই চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পুরনো তেলে ক্ষতিকারক রাসায়নিক থাকে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'মাটিতে তেল ফেললে আইনে কোনো দোষ হয় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'spill',
      promptBn: 'তেল বদলানোর সময় তেল লিক হয়ে মাটিতে গড়াচ্ছে — কোন ছবিতে ঠিক কাজ?',
      options: [
        LearnBoardOption(
          id: 'boom',
          labelBn: 'স্পিল কিটের বুম দিয়ে তেলের চারপাশ ঘেরা',
          asset: 'assets/game/art/m7_board78/spill_boom.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pads',
          labelBn: 'তেল শোষণকারী প্যাড তেলের ওপর বিছিয়ে দেওয়া',
          asset: 'assets/game/art/m7_board78/spill_pads.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: 'মাটি শুষে নেবে ভেবে তেল গড়াতে ছেড়ে দেওয়া',
          asset: 'assets/game/art/m7_board78/spill_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটি শুষে নিলেও তেল মাটির গভীরে গিয়ে ভূগর্ভস্থ জলকে দূষিত করে — এটি দীর্ঘস্থায়ী ক্ষতি।',
        ),
        LearnBoardOption(
          id: 'wash',
          labelBn: 'তেল ধুয়ে ড্রেনের দিকে ঠেলতে হোসের জল',
          asset: 'assets/game/art/m7_board78/spill_wash.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল ড্রেনে গেলে লক্ষ লক্ষ লিটার জল দূষিত হতে পারে — ড্রেনে ফেলা দণ্ডনীয় অপরাধ। স্পিল কিট ব্যবহার করুন।',
        ),
        LearnBoardOption(
          id: 'cover',
          labelBn: 'তেলের ওপর বেলচায় মাটি চাপা দিয়ে দেওয়া',
          asset: 'assets/game/art/m7_board78/spill_cover.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটি চাপা দিলেও তেল মাটিতেই থাকে, গভীরে গিয়ে ভূগর্ভস্থ জল দূষিত করে — প্যাড দিয়ে শুষে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্পিল কিটে থাকে তেল শোষণকারী প্যাড আর বুম', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'মাটির তেল গভীরে গিয়ে ভূগর্ভস্থ জল নষ্ট করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'লিক হলেই মাটি দূষণ আটকাতে স্পিল কিট চাই', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মাটি শুষে নিলে ভূগর্ভস্থ জলের ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ড্রেনে জল দিয়ে ধুয়ে দিলেই তেল সরে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মাটি চাপা দিলে তেল আর কোনো ক্ষতি করে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছোট লিক হলে কিছু না করলেও চলে যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'স্পিল কিট শুধু বড় কারখানার কাজেই লাগে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'তেল শুকিয়ে গেলে আপনিই নিরাপদ হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'ewaste',
      promptBn: 'কন্ট্রোল প্যানেলের পুরনো ব্যাটারি আর খারাপ সার্কিট বোর্ড — কোন ছবিতে ঠিক?',
      options: [
        LearnBoardOption(
          id: 'battery',
          labelBn: 'পুরনো ব্যাটারি কোম্পানির সংগ্রহ কেন্দ্রের বাক্সে',
          asset: 'assets/game/art/m7_board78/ewaste_battery.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'board',
          labelBn: 'খারাপ সার্কিট বোর্ড সংগ্রহ কেন্দ্রের বাক্সে জমা',
          asset: 'assets/game/art/m7_board78/ewaste_board.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'vat',
          labelBn: 'ব্যাটারি আর বোর্ড পৌরসভার ময়লার ভ্যাটে ফেলা',
          asset: 'assets/game/art/m7_board78/ewaste_vat.svg',
          scene: true,
          correct: false,
          // Live point 2: the battery rule for batteries, the e-waste rule for
          // boards (ruling X3).
          rejectBn: '\'Battery Waste Management Rules, 2022\' আর \'E-Waste (Management) Rules, 2022\' অনুযায়ী এই বর্জ্য সাধারণ ময়লার সাথে ফেলা যাবে না।',
        ),
        LearnBoardOption(
          id: 'bury',
          labelBn: 'ব্যাটারি আর বোর্ড মাটির নিচে পুঁতে দেওয়া',
          asset: 'assets/game/art/m7_board78/ewaste_bury.svg',
          scene: true,
          correct: false,
          rejectBn: 'ই-ওয়েস্ট মাটির নিচে মিশে ক্ষতিকারক রাসায়নিক ছাড়ে, যা খাদ্য আর জলের মাধ্যমে শরীরে ঢোকে।',
        ),
        LearnBoardOption(
          id: 'acid',
          labelBn: 'ফাটা ব্যাটারি মাটিতে ফেলে রাখা, অ্যাসিড গড়াচ্ছে',
          asset: 'assets/game/art/m7_board78/ewaste_acid.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যাটারিতে সীসা আর অ্যাসিডের মতো ক্ষতিকারক পদার্থ থাকে — পুরোটাই সংগ্রহ কেন্দ্রে জমা দিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ব্যাটারি আর বোর্ডে ক্ষতিকারক পদার্থ থাকে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'এই বর্জ্য সাধারণ ময়লার সাথে ফেলা যায় না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'জমা দিতে হয় কোম্পানির সংগ্রহ কেন্দ্রে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ব্যাটারি ছোট, ভ্যাটে ফেললে ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মাটির নিচে চাপা দিলে রাসায়নিক ছড়ায় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ফাটা ব্যাটারি মাটিতে পড়ে থাকলেও চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সার্কিট বোর্ড সাধারণ ময়লার মতোই জিনিস', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ই-ওয়েস্ট শরীরে ঢোকার কোনো পথ নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সংগ্রহ কেন্দ্রে দেওয়ার কোনো নিয়ম নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'lamp',
      promptBn: 'পুরনো টিউব লাইট আর CFL — কোন ছবিতে ঠিক?',
      options: [
        LearnBoardOption(
          id: 'box',
          labelBn: 'টিউব আর CFL না ভেঙে সাবধানে বাক্সে রাখা',
          asset: 'assets/game/art/m7_board78/lamp_box.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'agency',
          labelBn: 'বাক্স অনুমোদিত ডিসপোজাল এজেন্সির গাড়িতে',
          asset: 'assets/game/art/m7_board78/lamp_agency.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'snap',
          labelBn: 'টিউব লাইট হাঁটুর ওপর ভেঙে ছোট করে ফেলা',
          asset: 'assets/game/art/m7_board78/lamp_snap.svg',
          scene: true,
          correct: false,
          rejectBn: 'ল্যাম্পে পারদ থাকে, যা মারাত্মক নিউরোটক্সিন — না ভেঙে সাবধানে সংগ্রহ করতে হবে।',
        ),
        LearnBoardOption(
          id: 'bin',
          labelBn: 'পুরনো CFL সাধারণ ডাস্টবিনে ফেলে দেওয়া',
          asset: 'assets/game/art/m7_board78/lamp_bin.svg',
          scene: true,
          correct: false,
          rejectBn: 'এই ল্যাম্পগুলোও বিপজ্জনক বর্জ্য হিসেবে গণ্য — অনুমোদিত ডিসপোজাল এজেন্সিতে পাঠাতে হবে।',
        ),
        LearnBoardOption(
          id: 'toss',
          labelBn: 'ল্যাম্প গাড়ির পেছনে ছুঁড়ে ছুঁড়ে তোলা',
          asset: 'assets/game/art/m7_board78/lamp_toss.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছুঁড়ে দিলে ল্যাম্প ভাঙে, পারদ বেরোয় — না ভেঙে সাবধানে সংগ্রহ করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ল্যাম্পের ভেতরে পারদের মতো বিষাক্ত পদার্থ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পারদ মানুষ-বন্যপ্রাণীর স্বাস্থ্যের ক্ষতি করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'না ভেঙে জমিয়ে অনুমোদিত এজেন্সিতে পাঠাতে হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ভাঙা ল্যাম্পের পারদে কোনো ক্ষতি হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পুরনো ল্যাম্প সাধারণ ময়লার মতোই ফেলা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ছোট টুকরো করলে ল্যাম্প আর বিপজ্জনক নয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'শুধু টিউব লাইট বিপজ্জনক, CFL বা ভেপার নয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পারদ ছড়িয়ে পড়লেও বন্যপ্রাণীর কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ল্যাম্প যেকোনো গাড়িতে তুলে পাঠালেই চলে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'sep',
      promptBn: 'কাজ শেষ, বর্জ্য গোছানোর পালা — কোন ছবিতে ঠিক?',
      options: [
        LearnBoardOption(
          id: 'rag',
          labelBn: 'তেল-মাখা কাপড় আলাদা নির্দিষ্ট লাল ডাস্টবিনে',
          asset: 'assets/game/art/m7_board78/sep_rag.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'two',
          labelBn: 'বিপজ্জনক আর সাধারণ বর্জ্য আলাদা দুই ডাস্টবিনে',
          asset: 'assets/game/art/m7_board78/sep_two.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'mixed',
          labelBn: 'তেল-মাখা কাপড় চায়ের কাপের সাথে সবুজ বিনে',
          asset: 'assets/game/art/m7_board78/sep_mixed.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল-মাখা কাপড় বিপজ্জনক বর্জ্য — সাধারণ বর্জ্য থেকে আলাদা করে নির্দিষ্ট ডাস্টবিনে ফেলুন।',
        ),
        LearnBoardOption(
          id: 'pads',
          labelBn: 'তেল-মাখা প্যাড সাধারণ ময়লার সবুজ বিনে',
          asset: 'assets/game/art/m7_board78/sep_pads.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল-মাখা প্যাডও বিপজ্জনক বর্জ্য — সাধারণ ময়লায় নয়, নির্দিষ্ট ডাস্টবিনে।',
        ),
        LearnBoardOption(
          id: 'smallcrew',
          labelBn: 'ছোট দল বলে সব বর্জ্য এক বিনে ফেলে দেওয়া',
          asset: 'assets/game/art/m7_board78/sep_smallcrew.svg',
          scene: true,
          correct: false,
          rejectBn: 'আইন যে কোনো ব্যক্তি বা সংস্থার জন্য প্রযোজ্য — ব্যক্তির আর কোম্পানির — দুজনেরই বড় জরিমানা হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তেল-মাখা জিনিস বিপজ্জনক বর্জ্যের ডাস্টবিনে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বিপজ্জনক আর সাধারণ বর্জ্য আলাদা রাখতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আইন ছোট দল বা ব্যক্তির ওপরও সমান খাটে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তেল-মাখা কাপড় তো সাধারণ ময়লারই অংশ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'সব বর্জ্য এক বিনে ফেললে কাজ তাড়াতাড়ি হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পরিবেশের আইন শুধু বড় ফ্যাক্টরির জন্য', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নিয়ম ভাঙলে শুধু কোম্পানির জরিমানা হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ছোট দলের বর্জ্য নিয়ে কেউ প্রশ্ন করে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'দুটো বিন রাখার পেছনে কোনো আইনি কারণ নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M7Board78Lines.rivalTaunt,
    rivalLineBn: M7Board78Lines.rivalMyth,
    exitBn: M7Board78Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: M7Board78Lines.sting,
    flipStingBn: M7Board78Lines.flipSting,
    dangerHints: [
      'মাটি শুষে নিলেই শেষ?',
      'তেল যায় কোথায়?',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'মাটি শুষলেও তেল গভীরে গিয়ে জল দূষিত করে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ভূগর্ভস্থ জল আমাদের পানীয় জলের উৎস', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'একটু তেলের ক্ষতিও থাকে বহুদিন ধরে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'মাটি তেল শুষে নিলে ক্ষতি মিটে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'অল্প তেলে ভূগর্ভস্থ জলের কিছু হয় না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'মাটির নিচের জল পান করার কাজে লাগে না', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'তেল মাটিতে পড়লে কয়েক দিনেই উবে যায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'মাটি সব বিষ নিজেই পরিষ্কার করে নেয়', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'শুধু বেশি তেল পড়লেই দূষণ হয়ে থাকে', correct: false),
    ],
  ),
);

/// The board's spoken lines: the careless coworker's (his recorded voice) and
/// the guide's. [rivalExit] and [sting] are already recorded; the rest wait
/// for the voice session (ruling M7-10), silent with the caption held until
/// then (the rival never falls back to the device voice).
abstract final class M7Board78Lines {
  /// Already recorded.
  static const flipSting = 'এই লোক যা বলছে… সেটা কি ভুল?';
  /// DRAFT wording — owner.
  static const intro = 'পুরনো তেল, ব্যাটারি আর ল্যাম্প মাটি-জল নষ্ট করে — আইনমতো ফেলতে শিখে নিন।';

  /// DRAFT wording — owner.
  static const earned = 'তেল ড্রামে, ব্যাটারি-বোর্ড-ল্যাম্প আলাদা জমা; মাটি বা ড্রেনে কিছু নয়।';

  /// DRAFT wording — owner.
  static const rivalTaunt = 'এইটুকু তেল নিয়ে এত ভাবনা কীসের?';

  /// Lesson 7.8's first myth, word for word (not new text; needs a clip).
  static const rivalMyth = 'একটু তেল মাটিতে পড়লে কিছু হয় না, মাটি তো শুষে নেয়।';

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
    final p = learnBoardPack78;
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
      p.myth.flipStingBn,
      for (final w in p.myth.whyChips)
        if (w.correct) w.textBn,
      p.earnedBn,
    ];
  }
}
