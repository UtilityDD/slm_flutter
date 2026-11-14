import 'learn_board_models.dart';

/// Ladder step 16 — Module 1 Lesson 1.6 (পারমিট-টু-ওয়ার্ক, PTW), the
/// picture board (mode like steps 7, 10 and 13).
///
/// Picture cards are vector scenes from `tool/ptw_board_art.py`. Every round
/// and every trap comes from the lesson text:
///  * PTW is a formal written document; never start work without a PTW signed
///    by hand; every permit has a set validity — past it, stop and take a new
///    one; the operator issues the PTW with a unique permit number; read
///    every word of it;
///  * the golden steps: the supervisor requests the permit from the control
///    room, the operator isolates the feeder — Breaker OFF, then LOTO (a
///    physical lock so nobody can switch it on by mistake, a tag saying why
///    it is locked and whose permission is needed to open it);
///  * match the feeder name on the PTW with the feeder you work on;
///  * a spoken or phone "line is off" has no legal or safety basis; after the
///    permit the team discharges and tests the line dead (one step, as the
///    lesson lists it) — the PTW is an administrative safeguard, the wrong
///    feeder or induced voltage is caught only by testing;
///  * a PTW lets a set person do set work at a set place in a set time (its
///    validity has a start as well as an end);
///  * line clear: count the team, everyone down, all tools removed, the
///    supervisor calls the control room and returns the permit; leaving the
///    field without returning it is a serious offence.
/// Every round has 4 traps for a 4-card hand, so each play leaves a different
/// trap out and a miss brings in the one not yet seen.
/// The rival's myth is the lesson's own: "আমার সুপারভাইজার পারমিট নিয়েছেন…".
const learnBoardPack16 = LearnBoardPack(
  lessonId: '1.6',
  titleBn: 'পারমিট (PTW)',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'পারমিট (PTW) শুধু কাগজ নয়, একটি জীবন বীমা। ঠিক পারমিট আর ঠিক ধাপ চিনুন।',
  earnedBn: 'স্বাক্ষরিত পারমিট (PTW) হাতে, ফিডার মিলিয়ে, টেস্ট করে কাজ — শেষে পারমিট ফেরত।',
  slots: [
    LearnBoardSlot(
      id: 'form',
      promptBn: 'পারমিট (PTW) হাতে পেলেন — কোন পারমিটে কাজ শুরু করা যায়?',
      options: [
        LearnBoardOption(id: 'ok_a', labelBn: 'স্বাক্ষরিত, মেয়াদের ভেতরে', asset: 'assets/game/art/ptw_board/form_ok_a.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok_b', labelBn: 'নম্বর, সময়, স্বাক্ষর ঠিক', asset: 'assets/game/art/ptw_board/form_ok_b.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'unsigned',
          labelBn: 'স্বাক্ষর ছাড়া পারমিট (PTW)',
          asset: 'assets/game/art/ptw_board/form_unsigned.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্বাক্ষর নেই — হাতে স্বাক্ষরিত পারমিট (PTW) ছাড়া কাজ শুরু করবেন না।',
        ),
        LearnBoardOption(
          id: 'expired',
          labelBn: 'মেয়াদ পেরোনো পারমিট (PTW)',
          asset: 'assets/game/art/ptw_board/form_expired.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঘড়ি বলছে মেয়াদ পেরিয়ে গেছে — কাজ বন্ধ করে নতুন পারমিট নিন।',
        ),
        LearnBoardOption(
          id: 'early',
          labelBn: 'সময় শুরু হয়নি এমন পারমিট (PTW)',
          asset: 'assets/game/art/ptw_board/form_early.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিটের সময় এখনও শুরু হয়নি — পারমিট (PTW) নির্দিষ্ট সময়েই কাজের অনুমতি দেয়।',
        ),
        LearnBoardOption(
          id: 'no_number',
          labelBn: 'নম্বর ছাড়া পারমিট (PTW)',
          asset: 'assets/game/art/ptw_board/form_no_number.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট নম্বর নেই — অপারেটর ইউনিক পারমিট নম্বর দিয়েই পারমিট (PTW) ইস্যু করেন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্বাক্ষরিত, মেয়াদের ভেতরের পারমিট (PTW)-তেই কাজ', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পারমিট (PTW)-র প্রতিটি শব্দ আর শর্ত পড়ে নিতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পারমিট নম্বর, সময় আর স্বাক্ষর মিলিয়ে নিন', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'স্বাক্ষর পরে নিলেও কাজ শুরু করা যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'মেয়াদ একটু পেরোলে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নম্বর না থাকলেও কাগজটাই যথেষ্ট হয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফর্মে কী লেখা, তা পড়ার দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সুপারভাইজার জানে, ফর্ম দেখার দরকার নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'loto',
      promptBn: 'কন্ট্রোল রুমে আইসোলেশন — কোন ব্রেকার দেখে পারমিট (PTW) ইস্যু হবে?',
      options: [
        LearnBoardOption(id: 'ok_a', labelBn: 'Breaker OFF, Lock, Tag', asset: 'assets/game/art/ptw_board/loto_ok_a.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok_b', labelBn: 'OFF করে তালা আর ট্যাগ', asset: 'assets/game/art/ptw_board/loto_ok_b.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'on',
          labelBn: 'ব্রেকার ON, তবু ট্যাগ',
          asset: 'assets/game/art/ptw_board/loto_on.svg',
          scene: true,
          correct: false,
          rejectBn: 'ব্রেকার এখনও ON — আগে Breaker OFF, তারপর Lock আর Tag।',
        ),
        LearnBoardOption(
          id: 'bare',
          labelBn: 'OFF, তালা-ট্যাগ নেই',
          asset: 'assets/game/art/ptw_board/loto_bare.svg',
          scene: true,
          correct: false,
          rejectBn: 'তালা-ট্যাগ নেই — যে কেউ ভুল করে ব্রেকার চালু করে দিতে পারে।',
        ),
        LearnBoardOption(
          id: 'lock_only',
          labelBn: 'তালা আছে, ট্যাগ নেই',
          asset: 'assets/game/art/ptw_board/loto_lock_only.svg',
          scene: true,
          correct: false,
          rejectBn: 'ট্যাগ নেই — ট্যাগে লেখা থাকে কেন লক করা আর কার অনুমতি ছাড়া খোলা যাবে না।',
        ),
        LearnBoardOption(
          id: 'tag_only',
          labelBn: 'ট্যাগ আছে, তালা নেই',
          asset: 'assets/game/art/ptw_board/loto_tag_only.svg',
          scene: true,
          correct: false,
          rejectBn: 'তালা নেই — লক-আউট মানে ফিজিক্যাল তালা, যাতে কেউ ভুল করে চালু করতে না পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তালা থাকলে কেউ ভুল করে চালু করতে পারে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ট্যাগে লেখা থাকে কেন লক আর কে খুলতে পারবে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আগে Breaker OFF, তারপর Lock আর Tag লাগে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ব্রেকার OFF করলেই আর তালার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ট্যাগ ঝোলালেই তালার কাজ হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চালু ব্রেকারে ট্যাগ দিলেই লাইন বন্ধ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'তালা থাকলে ট্যাগের কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'LOTO শুধু বড় সাবস্টেশনের জন্য নিয়ম', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'feeder',
      promptBn: 'পারমিট (PTW)-র ফিডার আর পোলের প্লেট — কোথায় কাজ শুরু করবেন?',
      options: [
        LearnBoardOption(id: 'ok_a', labelBn: 'পারমিট (PTW) BAZAR-1, পোল BAZAR-1', asset: 'assets/game/art/ptw_board/feeder_ok_a.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok_b', labelBn: 'পারমিট (PTW) RAMPUR-2, পোল RAMPUR-2', asset: 'assets/game/art/ptw_board/feeder_ok_b.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'near',
          labelBn: 'পারমিট (PTW) BAZAR-1, পোল BAZAR-11',
          asset: 'assets/game/art/ptw_board/feeder_near.svg',
          scene: true,
          correct: false,
          rejectBn: 'BAZAR-1 আর BAZAR-11 এক নয় — পারমিট (PTW)-র ফিডার আর কাজের ফিডার মিলিয়ে নিন।',
        ),
        LearnBoardOption(
          id: 'num',
          labelBn: 'পারমিট (PTW) RAMPUR-2, পোল RAMPUR-3',
          asset: 'assets/game/art/ptw_board/feeder_num.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট (PTW)-তে RAMPUR-2, পোলে RAMPUR-3 — ফিডারের নাম এক কিনা মিলিয়ে নিন।',
        ),
        LearnBoardOption(
          id: 'other',
          labelBn: 'পারমিট (PTW) HAT-4, পোল BAZAR-1',
          asset: 'assets/game/art/ptw_board/feeder_other.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট অন্য ফিডারের — এই লাইনটি বন্ধ হয়েছে কিনা, এই পারমিট তা বলে না।',
        ),
        LearnBoardOption(
          id: 'long',
          labelBn: 'পারমিট (PTW) RAMPUR-12, পোল RAMPUR-2',
          asset: 'assets/game/art/ptw_board/feeder_long.svg',
          scene: true,
          correct: false,
          rejectBn: 'RAMPUR-12 আর RAMPUR-2 এক নয় — পারমিট (PTW)-র ফিডার আর কাজের ফিডার মিলিয়ে নিন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পারমিট (PTW)-র ফিডার আর কাজের ফিডার এক হতে হবে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পারমিট (PTW) নির্দিষ্ট স্থানেই কাজের অনুমতি দেয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'নামের একটা অক্ষরও না মিললে কাজ নয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'নামের প্রথম অংশ মিললেই চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'এক এলাকার সব ফিডার একসাথে বন্ধ থাকে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পোলের প্লেট দেখার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একটা সংখ্যার ফারাক কোনো ব্যাপার না', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পারমিট থাকলে যেকোনো পোলে ওঠা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'start',
      promptBn: "'লাইন বন্ধ আছে' শুনলেন — কাজ শুরুর আগে কোনটা ঠিক?",
      options: [
        LearnBoardOption(id: 'paper', labelBn: 'স্বাক্ষরিত পারমিট (PTW) হাতে পড়া', asset: 'assets/game/art/ptw_board/start_paper.svg', scene: true, correct: true),
        LearnBoardOption(id: 'test', labelBn: 'ডিসচার্জ ও টেস্ট করে নিশ্চিত', asset: 'assets/game/art/ptw_board/start_test.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'phone',
          labelBn: "ফোনে 'বন্ধ' শুনে উঠতে যাওয়া",
          asset: 'assets/game/art/ptw_board/start_phone.svg',
          scene: true,
          correct: false,
          rejectBn: "ফোনে বলা 'লাইন বন্ধ আছে' কথার কোনো আইনি বা সুরক্ষা ভিত্তি নেই।",
        ),
        LearnBoardOption(
          id: 'shout',
          labelBn: "মুখে 'বন্ধ' শুনেই ওঠা",
          asset: 'assets/game/art/ptw_board/start_shout.svg',
          scene: true,
          correct: false,
          rejectBn: 'মুখের কথায় কাজ নয় — হাতে স্বাক্ষরিত পারমিট (PTW) ছাড়া কাজ শুরু করবেন না।',
        ),
        LearnBoardOption(
          id: 'permit',
          labelBn: 'পারমিট হাতে, টেস্ট ছাড়াই ওঠা',
          asset: 'assets/game/art/ptw_board/start_permit.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট (PTW) প্রশাসনিক সুরক্ষা — কাজের আগে ডিসচার্জ ও টেস্ট করে লাইন ডেড নিশ্চিত করুন।',
        ),
        LearnBoardOption(
          id: 'no_permit',
          labelBn: 'মুখের কথায়, পারমিট (PTW) ছাড়াই টেস্ট',
          asset: 'assets/game/art/ptw_board/start_no_permit.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট (PTW) কোথায়? পারমিট গ্রহণ করার পরই ডিসচার্জ ও টেস্ট — মুখের কথায় নয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'মুখের বা ফোনের কথার কোনো আইনি ভিত্তি নেই', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পারমিট পেয়েও ডিসচার্জ ও টেস্ট করতে হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হাতে স্বাক্ষরিত পারমিট (PTW) ছাড়া কাজ শুরু নয়', correct: true),
        LearnWhyChip(id: 'w9', textBn: 'ভুল ফিডার বন্ধ হলে টেস্টেই তা ধরা পড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কন্ট্রোল রুম ফোনে বললেই লাইন নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পারমিট হাতে থাকলে টেস্টের দরকার নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সহকর্মী মুখে বললে কাগজ আর লাগে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'কাগজ পরে আনলেও কাজ শুরু করা যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ফোনের কথাই লিখিত পারমিটের সমান হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'clear',
      promptBn: 'কাজ শেষ — লাইন ক্লিয়ার ঠিকভাবে হচ্ছে কোথায়?',
      options: [
        LearnBoardOption(id: 'ok_a', labelBn: 'সবাই নিচে, তারপর Line Clear', asset: 'assets/game/art/ptw_board/clear_a.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok_b', labelBn: 'যন্ত্র সরিয়ে, তারপর ফোন', asset: 'assets/game/art/ptw_board/clear_b.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'worker_up',
          labelBn: 'একজন ওপরে, ফোনে Line Clear',
          asset: 'assets/game/art/ptw_board/clear_worker_up.svg',
          scene: true,
          correct: false,
          rejectBn: 'একজন এখনও ওপরে — সবাই লাইন থেকে নেমেছেন কিনা আগে নিশ্চিত করুন।',
        ),
        LearnBoardOption(
          id: 'tool_on',
          labelBn: 'রড লাইনে রেখে Line Clear',
          asset: 'assets/game/art/ptw_board/clear_tool_on.svg',
          scene: true,
          correct: false,
          rejectBn: 'রড এখনও লাইনে — সমস্ত যন্ত্রপাতি সরিয়ে তবেই Line Clear।',
        ),
        LearnBoardOption(
          id: 'coming_down',
          labelBn: 'একজন নামছেন, ফোনে Line Clear',
          asset: 'assets/game/art/ptw_board/clear_coming_down.svg',
          scene: true,
          correct: false,
          rejectBn: 'সবাই এখনও নামেননি — টিম মেম্বারদের গুনে, সবাই নিরাপদ জেনে তবেই Line Clear।',
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: 'পারমিট হাতে ফিরে যাওয়া',
          asset: 'assets/game/art/ptw_board/clear_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'পারমিট ফেরত না দিয়ে ফিল্ড ছেড়ে চলে যাওয়া একটি গুরুতর অপরাধ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফেরত না দিলে কন্ট্রোল রুম ভাবে কাজ চলছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সবাই নিচে, যন্ত্র সরানো — তারপর Line Clear', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'যার নামে পারমিট, ফেরতের দায়িত্বও তার', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'কাজ শেষ হলে পারমিট নিজেই বাতিল হয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একজন ওপরে থাকলেও Line Clear বলা যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'যন্ত্র লাইনে থাকলেও কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'পারমিট পরের দিন ফেরত দিলেও দিব্যি চলে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'না গুনেও সবাই নেমেছে ধরে নেওয়া যায়', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: PtwBoardLines.rivalTaunt,
    rivalLineBn: PtwBoardLines.rivalMyth,
    exitBn: PtwBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'কোন পারমিটে কাজ, তা না জেনে ওঠা',
      'পারমিটের শর্ত না জেনেই কাজ',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'সবার জানা চাই কোন পারমিটে কাজ চলছে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'সুরক্ষা একজনের নয়, সকলের দায়িত্ব', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'পারমিটের শর্ত প্রত্যেকের জানা উচিত', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'পারমিট শুধু সুপারভাইজারের ব্যাপার', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'বস কাগজ নিলে আর কিছু দেখার নেই', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'শর্ত জানা শুধু বড় কর্তাদের কাজ', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ সুপারভাইজারের ভুল হয় না', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'সুপারভাইজার জানলেই টিমের সবাই নিরাপদ', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board, in his recorded voice
/// (`r_<sha1>.mp3` in `learnRivalVoice`). The guide's lines stay in the pack
/// (device TTS until the owner records them).
abstract final class PtwBoardLines {
  static const rivalTaunt = 'আরে! পারমিট-টারমিট সুপারভাইজারের ব্যাপার, আমি শুধু উঠব!';

  /// Lesson 1.6's myth buster, word for word.
  static const rivalMyth = 'আমার সুপারভাইজার পারমিট নিয়েছেন, তাই আমার আর এটা নিয়ে ভাবার দরকার নেই।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// The new clips this board added.
  static const recorded = [rivalTaunt, rivalMyth];
}
