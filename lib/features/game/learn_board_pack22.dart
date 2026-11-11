import 'learn_board_models.dart';

/// Rung 2.2/learn — Module 2 Lesson 2.2 (মাল্টিমিটারের জাদু), the picture
/// board (engineType `learn_cards`, pack `learn_2_2`).
///
/// Picture cards are vector scenes from `tool/m2_board22_art.py`. Every round
/// and every trap comes from the lesson text:
///  * check: before use, look at the probe leads for a cut or damage and
///    check the battery level; rusty or blunt probe tips give no right
///    reading (pro tip 1);
///  * port: the black probe in COM, the red one in VΩmA; 10A is for high
///    current; a probe in the wrong port gives a wrong reading or the fuse
///    blows;
///  * volt: our distribution lines carry AC — dial on V~; always start at the
///    highest range and come down; the two tips touch the two points in
///    parallel; a wrong setting gives a wrong reading or blows the fuse;
///  * off: continuity (beep) only with the supply fully off — never on a live
///    line; resistance (Ω) only with the power off too; dial in continuity
///    mode;
///  * beep: the lesson's second myth turned into a round — a beep only says
///    there is a connection; whether it is weak or of high resistance, the Ω
///    reading tells; wait a second or two for the numbers to settle
///    (pro tip 3).
/// The rival's myth is the lesson's first: "যেকোনো মাল্টিমিটার দিয়ে
/// যেকোনো লাইনের ভোল্টেজ মাপা যায়।" — CAT rating (CAT II vs CAT IV).
/// Not drawn: ghost voltage (pro tip 4) — "it is not real voltage" is risky
/// as a picture card for a lineman; left for the director to decide.
const learnBoardPack22 = LearnBoardPack(
  lessonId: '2.2',
  titleBn: 'মাল্টিমিটারের জাদু',
  badgeBn: 'হাতিয়ারের ওস্তাদ',
  introBn: 'জাদুর বাক্স ডিজিটাল মাল্টিমিটার — ভয় নয়, বন্ধুত্ব। ঠিক পোর্ট, ঠিক ডায়াল চিনে নিন।',
  earnedBn: 'কালো COM-এ, লাল VΩmA-তে, সর্বোচ্চ রেঞ্জে শুরু — আর বিপ বা Ω মাপার আগে পাওয়ার বন্ধ।',
  slots: [
    LearnBoardSlot(
      id: 'check',
      promptBn: 'মাল্টিমিটার হাতে নিলেন — ব্যবহারের আগে কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'lead', labelBn: 'প্রোবের তারে কাটা খোঁজা', asset: 'assets/game/art/m2_board22/check_lead.svg', scene: true, correct: true),
        LearnBoardOption(id: 'battery', labelBn: 'ব্যাটারি লেভেল দেখে নেওয়া', asset: 'assets/game/art/m2_board22/check_battery.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'cut',
          labelBn: 'কাটা তারের প্রোবেই মাপা',
          asset: 'assets/game/art/m2_board22/check_cut.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে দেখে নিন প্রোবের তারে কোনো কাটা বা ক্ষতি আছে কিনা — কাটা তারে মাপা নয়।',
        ),
        LearnBoardOption(
          id: 'rusty',
          labelBn: 'মরিচা ধরা প্রোবে মাপা',
          asset: 'assets/game/art/m2_board22/check_rusty.svg',
          scene: true,
          correct: false,
          rejectBn: 'মরিচা ধরা বা ভোঁতা প্রোব সঠিক রিডিং দেয় না — ডগা দুটি পরিষ্কার আর ধারালো রাখুন।',
        ),
        LearnBoardOption(
          id: 'low_batt',
          labelBn: 'খালি ব্যাটারিতে মাপতে যাওয়া',
          asset: 'assets/game/art/m2_board22/check_low_batt.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্যবহারের আগে যন্ত্রের ব্যাটারি লেভেল পরীক্ষা করুন — খালি ব্যাটারিতে ভরসা নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'প্রোবের তারে কাটা বা ক্ষতি আগেই দেখে নিতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ব্যবহারের আগে যন্ত্রের ব্যাটারি পরীক্ষা করুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'মরিচা ধরা, ভোঁতা প্রোব ঠিক রিডিং দেয় না', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তারে একটু কাটা থাকলে রিডিং আরও ভালো আসে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ব্যাটারি কমে গেলেও রিডিং একদম ঠিকই থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'প্রোবের ডগায় মরিচা থাকলে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'নতুন যন্ত্র, তাই রোজ দেখে নেওয়ার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'কাটা তারে টেপ না জড়িয়েই কাজ চালানো যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ডিসপ্লেতে কিছু এলেই যন্ত্র ঠিক আছে ধরা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'port',
      promptBn: 'ভোল্টেজ মাপবেন — প্রোব দুটো কোন পোর্টে লাগবে?',
      options: [
        LearnBoardOption(id: 'com_v', labelBn: 'কালো COM-এ, লাল VΩmA-তে', asset: 'assets/game/art/m2_board22/port_com_v.svg', scene: true, correct: true),
        LearnBoardOption(id: 'com_v2', labelBn: 'কালো COM-এ রেখে লাল VΩmA-তে', asset: 'assets/game/art/m2_board22/port_com_v2.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'red_10a',
          labelBn: 'লাল প্রোব 10A পোর্টে',
          asset: 'assets/game/art/m2_board22/port_red_10a.svg',
          scene: true,
          correct: false,
          rejectBn: '10A পোর্ট উচ্চ কারেন্ট মাপার জন্য — ভুল পোর্টে প্রোব মানে ভুল রিডিং বা ফিউজ উড়ে যাওয়া।',
        ),
        LearnBoardOption(
          id: 'swap',
          labelBn: 'লাল COM-এ, কালো VΩmA-তে',
          asset: 'assets/game/art/m2_board22/port_swap.svg',
          scene: true,
          correct: false,
          rejectBn: 'COM কালো প্রোবের জন্য, VΩmA লাল প্রোবের জন্য — উল্টো লাগালে চলবে না।',
        ),
        LearnBoardOption(
          id: 'black_10a',
          labelBn: 'কালো প্রোব 10A পোর্টে',
          asset: 'assets/game/art/m2_board22/port_black_10a.svg',
          scene: true,
          correct: false,
          rejectBn: 'কালো প্রোবের জায়গা COM — ভুল পোর্টে প্রোব লাগালে যন্ত্র ক্ষতিগ্রস্ত হতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কালো প্রোব সবসময় COM পোর্টেই লাগে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভোল্ট আর ওহম মাপতে লাল প্রোব VΩmA-তে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভুল পোর্টে রিডিং ভুল বা ফিউজ উড়ে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: '10A পোর্টে লাগালে ভোল্টেজ আরও ঠিক আসে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেকোনো পোর্টে লাগালেই রিডিং একই আসে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লাল-কালো উল্টো হলে কোনো তফাত হয় না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'COM পোর্টটা শুধু কারেন্ট মাপার জন্য', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'যে পোর্ট কাছে, প্রোব সেখানেই লাগানো যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'volt',
      promptBn: 'টার্মিনালে ফেজ-নিউট্রাল ভোল্টেজ মাপবেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'parallel', labelBn: 'V~ সর্বোচ্চ রেঞ্জে, দুই পয়েন্টে প্রোব', asset: 'assets/game/art/m2_board22/volt_parallel.svg', scene: true, correct: true),
        LearnBoardOption(id: 'high_range', labelBn: 'আগে ডায়াল V~ সর্বোচ্চ রেঞ্জে', asset: 'assets/game/art/m2_board22/volt_high_range.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'dc',
          labelBn: 'ডায়াল V--- (ডিসি)-তে রেখে মাপা',
          asset: 'assets/game/art/m2_board22/volt_dc.svg',
          scene: true,
          correct: false,
          rejectBn: 'আমাদের ডিস্ট্রিবিউশন লাইনে এসি ভোল্টেজ — ডায়াল V~-এ রাখুন, V--- ব্যাটারি বা সোলারের ডিসি-র জন্য।',
        ),
        LearnBoardOption(
          id: 'low_range',
          labelBn: 'সবচেয়ে ছোট রেঞ্জে শুরু',
          asset: 'assets/game/art/m2_board22/volt_low_range.svg',
          scene: true,
          correct: false,
          rejectBn: 'সর্বদা ডায়াল সর্বোচ্চ ভোল্টেজ রেঞ্জে রেখে শুরু করুন, প্রয়োজনে রেঞ্জ কমান — যন্ত্র বাঁচবে।',
        ),
        LearnBoardOption(
          id: 'amp_dial',
          labelBn: 'ডায়াল A-তে রেখে ভোল্টেজ মাপা',
          asset: 'assets/game/art/m2_board22/volt_amp_dial.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল সেটিং-এ ডায়াল রাখলে ভুল রিডিং আসে, ফিউজ উড়ে যন্ত্র ক্ষতিগ্রস্ত হতে পারে।',
        ),
        LearnBoardOption(
          id: 'ohm_live',
          labelBn: 'লাইভ টার্মিনালে Ω-তে মাপা',
          asset: 'assets/game/art/m2_board22/volt_ohm_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'রেজিস্ট্যান্স মাপার আগে পাওয়ার সাপ্লাই অবশ্যই বন্ধ — লাইভ টার্মিনালে Ω নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ডিস্ট্রিবিউশন লাইনে এসি, তাই ডায়াল V~-এ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সর্বোচ্চ রেঞ্জে শুরু, দরকারে রেঞ্জ কমান', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'প্রোবের দুই ডগা দুই পয়েন্টে সমান্তরালে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ছোট রেঞ্জে শুরু করলে যন্ত্র বেশি বাঁচে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'লাইনের ভোল্টেজ মাপতে ডায়াল V---তে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডায়াল যেখানেই থাকুক, রিডিং ঠিক আসবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'A-তে রেখেও ভোল্টেজ দিব্যি মাপা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'একটা প্রোব ছোঁয়ালেই ভোল্টেজ জানা যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লাইভ টার্মিনালে Ω মাপাও একদম নিরাপদ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'off',
      promptBn: 'ফিউজ ভালো না উড়ে গেছে — কন্টিনিউটি টেস্টে কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'switch_off', labelBn: 'আগে সাপ্লাইয়ের সুইচ বন্ধ', asset: 'assets/game/art/m2_board22/off_switch_off.svg', scene: true, correct: true),
        LearnBoardOption(id: 'beep_off', labelBn: 'পাওয়ার বন্ধ রেখে বিপ টেস্ট', asset: 'assets/game/art/m2_board22/off_beep_off.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'live_beep',
          labelBn: 'সুইচ অন রেখেই বিপ টেস্ট',
          asset: 'assets/game/art/m2_board22/off_live_beep.svg',
          scene: true,
          correct: false,
          rejectBn: 'কন্টিনিউটি টেস্টের আগে পাওয়ার সাপ্লাই সম্পূর্ণ বন্ধ — লাইভ লাইনে এই টেস্ট করা যাবে না।',
        ),
        LearnBoardOption(
          id: 'wrong_dial',
          labelBn: 'ডায়াল V~-এ রেখে ফিউজ দেখা',
          asset: 'assets/game/art/m2_board22/off_wrong_dial.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডায়াল কন্টিনিউটি মোডে (বিপের চিহ্ন) রাখুন — ভুল সেটিং-এ যন্ত্র ভুল রিডিং দেয়।',
        ),
        LearnBoardOption(
          id: 'live_ohm',
          labelBn: 'সুইচ অন রেখেই Ω মাপা',
          asset: 'assets/game/art/m2_board22/off_live_ohm.svg',
          scene: true,
          correct: false,
          rejectBn: 'রেজিস্ট্যান্স মাপার আগেও সার্কিটের পাওয়ার সাপ্লাই অবশ্যই বন্ধ করতে হবে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কন্টিনিউটি টেস্টের আগে সাপ্লাই পুরো বন্ধ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লাইভ লাইনে কন্টিনিউটি টেস্ট করা যাবে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'Ω মাপার আগেও পাওয়ার অবশ্যই বন্ধ করুন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সুইচ অন থাকলে বিপ আরও জোরে শোনা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ছোট ফিউজে লাইভ টেস্ট করলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডায়াল যেখানেই থাকুক, বিপ ঠিকই হবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পাওয়ার বন্ধ করলে কন্টিনিউটি বোঝা যায় না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সুইচ বন্ধ করতে গেলে শুধু সময় নষ্ট হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'beep',
      promptBn: "প্রোব ছোঁয়াতেই 'বিপ' — সংযোগ সত্যিই ভালো কিনা বুঝবেন কীভাবে?",
      options: [
        LearnBoardOption(id: 'ohm_read', labelBn: 'ডায়াল Ω-তে, রিডিং দেখে নেওয়া', asset: 'assets/game/art/m2_board22/beep_ohm_read.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ohm_check', labelBn: 'জোড়ের দুই প্রান্তে Ω মাপা', asset: 'assets/game/art/m2_board22/beep_ohm_check.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'beep_done',
          labelBn: 'বিপ শুনেই সব ঠিক ধরা',
          asset: 'assets/game/art/m2_board22/beep_beep_done.svg',
          scene: true,
          correct: false,
          rejectBn: "'বিপ' শুধু বলে সংযোগ আছে — দুর্বল বা উচ্চ রেজিস্ট্যান্সের সংযোগ বুঝতে ওহম (Ω) রিডিং দেখুন।",
        ),
        LearnBoardOption(
          id: 'weak_joint',
          labelBn: 'মরিচা জোড়ে বিপেই পাস',
          asset: 'assets/game/art/m2_board22/beep_weak_joint.svg',
          scene: true,
          correct: false,
          rejectBn: 'বিপ পুরো চিত্র দেয় না — জোড়টা দুর্বল কিনা, তা বলে ওহম (Ω) রিডিং।',
        ),
        LearnBoardOption(
          id: 'jumpy',
          labelBn: 'সংখ্যা নড়তে নড়তেই লেখা',
          asset: 'assets/game/art/m2_board22/beep_jumpy.svg',
          scene: true,
          correct: false,
          rejectBn: 'প্রোব লাগানোর পর ডিসপ্লের সংখ্যা স্থির হতে এক-দুই সেকেন্ড অপেক্ষা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: "'বিপ' শুধু বলে সংযোগ আছে, ভালো কিনা নয়", correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সংযোগ দুর্বল কিনা বোঝায় ওহম (Ω) রিডিং', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সংখ্যা স্থির হতে এক-দুই সেকেন্ড অপেক্ষা', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'বিপ হলেই সার্কিট সবসময় একদম ভালো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মরিচা পড়া জোড়ও বিপ দিলে ঠিকই আছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'প্রথম যে সংখ্যা আসে, সেটাই আসল রিডিং', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'Ω রিডিং দেখা মানে শুধুই সময়ের অপচয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'বিপ যত জোরে, সংযোগ তত বেশি মজবুত', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: MeterBoardLines.rivalTaunt,
    rivalLineBn: MeterBoardLines.rivalMyth,
    exitBn: MeterBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'সাধারণ মিটারে ওভারহেড লাইন মাপা',
      'CAT রেটিং না দেখা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'প্রতিটি মিটারের সর্বোচ্চ ভোল্ট ও CAT রেটিং আছে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'CAT II মিটারে ওভারহেড লাইন মাপা মারাত্মক বিপদ', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'লাইনম্যানের দরকার CAT III বা CAT IV রেটেড মিটার', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'যেকোনো মিটার দিয়েই যেকোনো লাইন মাপা যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'CAT রেটিং শুধু দোকানের লেবেল, কাজে লাগে না', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'ছোট মিটার হলেও ডায়াল ঘোরালেই সব মাপা যায়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়ে থাকে', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ইলেকট্রিশিয়ানের মিটারই লাইনের জন্য যথেষ্ট', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'মিটার কখনো বিস্ফোরিত হয় না, ভয়ের কিছু নেই', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. The exit line is already
/// recorded (`learnRivalVoice`); the taunt and the myth are new and play
/// through device TTS until the owner records them ([toRecord]).
abstract final class MeterBoardLines {
  static const rivalTaunt = 'আরে! মিটার তো মিটারই — এত বাছাবাছির কী আছে?';

  /// Lesson 2.2's first myth buster, word for word.
  static const rivalMyth = 'যেকোনো মাল্টিমিটার দিয়ে যেকোনো লাইনের ভোল্টেজ মাপা যায়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival clips to record (`r_<sha1>.mp3` via `tool/make_learn_voice.py`).
  static const toRecord = [rivalTaunt, rivalMyth];
}
