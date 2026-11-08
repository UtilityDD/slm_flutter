import 'learn_board_models.dart';

/// Ladder step 19 — Module 1 Lesson 1.7 (শক লাগলে ফার্স্ট এইড), the picture
/// board (mode like steps 7, 10 and 13).
///
/// Picture cards are vector scenes from `tool/aid_board_art.py` (non-graphic:
/// no wounds, no burns). Every round and every trap comes from the lesson:
///  * never touch the victim — electricity turns his body into a live wire
///    and you join the circuit; two hurt instead of one; stay calm;
///  * first stop the current — a nearby switch / MCB, or phone the
///    substation / control room to switch the line off;
///  * if the source cannot be switched off, separate him with a dry
///    non-conductor: dry wood, bamboo, a plastic chair, a fibreglass hot
///    stick — and push on the arm or the leg, never the chest or the head;
///  * once the danger is gone: tap the shoulder and ask loudly "আপনি ঠিক
///    আছেন?", watch for response and breathing; send someone else to call the
///    ambulance; only if he does not respond and is not breathing, CPR (if
///    trained) — so the board's safe cards stop at the response check and the
///    call; the order check → call → CPR is step 21's job; the mud / burying
///    myth wastes time and raises infection; the golden minute is not for
///    standing about waiting;
///  * pro tips: no ice, water or ointment on an entry/exit burn — take him to
///    the doctor; never leave him alone, and hospital even if he talks.
/// The rival's myth is the lesson's own: LT shocks are "just a jolt".
const learnBoardPack17 = LearnBoardPack(
  lessonId: '1.7',
  titleBn: 'শক লাগলে ফার্স্ট এইড',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'সহকর্মী শক খেলে প্রতি সেকেন্ড মূল্যবান। নিজে বাঁচুন, তারপর বাঁচান — ঠিক পথটা চিনুন।',
  earnedBn: 'ছোঁবেন না, আগে সোর্স বন্ধ — তারপর সাড়া দেখা, অ্যাম্বুলেন্সে কল; সাড়া-শ্বাস না থাকলে CPR।',
  slots: [
    LearnBoardSlot(
      id: 'first',
      promptBn: 'সহকর্মী লাইভ তারে আটকে গেছেন — প্রথমে কী করবেন?',
      options: [
        LearnBoardOption(id: 'mcb', labelBn: 'আগে MCB বন্ধ', asset: 'assets/game/art/aid_board/first_mcb.svg', scene: true, correct: true),
        LearnBoardOption(id: 'call', labelBn: 'ফোনে লাইন বন্ধ করানো', asset: 'assets/game/art/aid_board/first_call.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'grab_hand',
          labelBn: 'ছুটে গিয়ে হাত ধরে টানা',
          asset: 'assets/game/art/aid_board/first_grab_hand.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্পর্শ করবেন না — বিদ্যুৎ তার শরীরকে Live তারে পরিণত করেছে, ছুঁলে আপনিও সার্কিটে।',
        ),
        LearnBoardOption(
          id: 'push_hands',
          labelBn: 'খালি হাতে ধাক্কা',
          asset: 'assets/game/art/aid_board/first_push_hands.svg',
          scene: true,
          correct: false,
          rejectBn: 'ছুঁলেই আপনিও সেই সার্কিটের অংশ — একজনের বদলে দুজন আহত।',
        ),
        LearnBoardOption(
          id: 'pull_shirt',
          labelBn: 'জামা ধরে টানা',
          asset: 'assets/game/art/aid_board/first_pull_shirt.svg',
          scene: true,
          correct: false,
          rejectBn: 'জামা ধরে টানাও স্পর্শ — ভিকটিম Live, আপনিও সার্কিটে।',
        ),
        LearnBoardOption(
          id: 'panic',
          labelBn: 'ভয়ে মাথায় হাত',
          asset: 'assets/game/art/aid_board/first_panic.svg',
          scene: true,
          correct: false,
          rejectBn: 'শান্ত থাকুন — আতঙ্ক সিদ্ধান্ত নষ্ট করে। আগে সোর্স বন্ধ করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আগে সোর্স বন্ধ, তারপর ভিকটিমের কাছে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ছুঁলেই আমিও সার্কিটের অংশ হয়ে যাব', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'একজনের বদলে দুজন আহত হলে বিপদ বাড়ে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'জোরে টেনে নিলেই শক আর লাগে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জামা ধরে টানলে শরীর ছোঁয়া হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বন্ধুকে বাঁচাতে আগে ঝাঁপিয়ে পড়ি', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'সাহস থাকলে খালি হাতেও বাঁচানো যায়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'আগে ভিকটিমকে টেনে সরানোই প্রথম কাজ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'object',
      promptBn: 'সুইচ নাগালে নেই — কী দিয়ে আলাদা করবেন?',
      options: [
        LearnBoardOption(id: 'bamboo', labelBn: 'শুকনো বাঁশ', asset: 'assets/game/art/aid_board/obj_bamboo.svg', scene: true, correct: true),
        LearnBoardOption(id: 'wood', labelBn: 'শুকনো কাঠ', asset: 'assets/game/art/aid_board/obj_wood.svg', scene: true, correct: true),
        LearnBoardOption(id: 'chair', labelBn: 'প্লাস্টিকের চেয়ার', asset: 'assets/game/art/aid_board/obj_chair.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'ভেজা কাঠ',
          asset: 'assets/game/art/aid_board/obj_wet.svg',
          scene: true,
          correct: false,
          rejectBn: 'কাঠ হতে হবে শুকনো — শুধু শুকনো অপরিবাহী জিনিস দিয়ে আলাদা করুন।',
        ),
        LearnBoardOption(
          id: 'iron',
          labelBn: 'লোহার রড',
          asset: 'assets/game/art/aid_board/obj_iron.svg',
          scene: true,
          correct: false,
          rejectBn: 'লোহা অপরিবাহী নয় — শুকনো কাঠ, বাঁশ বা প্লাস্টিকের চেয়ার নিন।',
        ),
        LearnBoardOption(
          id: 'ladder',
          labelBn: 'অ্যালুমিনিয়ামের মই',
          asset: 'assets/game/art/aid_board/obj_ladder.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধাতুর মই অপরিবাহী নয় — চাই শুকনো কাঠ, বাঁশ বা হট স্টিক।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'শুকনো অপরিবাহী জিনিস দিয়েই আলাদা করি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'শুকনো কাঠ, বাঁশ বা চেয়ার হাতে রাখি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'যেকোনো লম্বা জিনিস দিয়ে ঠেললেই চলে', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'লোহার রড শক্ত, তাই ঠেলতে সুবিধা', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ভেজা কাঠও তো কাঠ, তাতে ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মই লম্বা, তাই দূর থেকে নিরাপদ', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'যা হাতের কাছে পাই, তা-ই দিয়ে ঠেলি', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'push',
      promptBn: 'বাঁশ বা হট স্টিক হাতে — কোথায় ধাক্কা দেবেন?',
      options: [
        LearnBoardOption(id: 'bamboo_arm', labelBn: 'বাঁশ দিয়ে হাতে ধাক্কা', asset: 'assets/game/art/aid_board/push_bamboo_arm.svg', scene: true, correct: true),
        LearnBoardOption(id: 'stick_leg', labelBn: 'হট স্টিকে পায়ে ধাক্কা', asset: 'assets/game/art/aid_board/push_stick_leg.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'bamboo_chest',
          labelBn: 'বাঁশ দিয়ে বুকে ধাক্কা',
          asset: 'assets/game/art/aid_board/push_bamboo_chest.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধাক্কাটি হাত বা পায়ে — বুক বা মাথায় নয়।',
        ),
        LearnBoardOption(
          id: 'stick_head',
          labelBn: 'হট স্টিকে মাথায় ধাক্কা',
          asset: 'assets/game/art/aid_board/push_stick_head.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাথায় নয় — ধাক্কা দিন হাতে বা পায়ে।',
        ),
        LearnBoardOption(
          id: 'bamboo_head',
          labelBn: 'বাঁশ দিয়ে মাথায় ধাক্কা',
          asset: 'assets/game/art/aid_board/push_bamboo_head.svg',
          scene: true,
          correct: false,
          rejectBn: 'বুক বা মাথায় ধাক্কা নয় — ধাক্কাটি হাত বা পায়ে।',
        ),
        LearnBoardOption(
          id: 'stick_chest',
          labelBn: 'হট স্টিকে বুকে ধাক্কা',
          asset: 'assets/game/art/aid_board/push_stick_chest.svg',
          scene: true,
          correct: false,
          rejectBn: 'বুক বা মাথায় নয় — হাত বা পায়ে ধাক্কা দিয়ে উৎস থেকে আলাদা করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ধাক্কা হাত বা পায়ে, বুক বা মাথায় নয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'হাত-পায়ে ঠেলে উৎস থেকে আলাদা করি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বুকে ধাক্কা দিলে সবচেয়ে জোরে সরে', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'মাথায় ঠেললে তাড়াতাড়ি তার ছাড়ে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'যেখানে খুশি ধাক্কা দিলেই কাজ হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'জোরে ধাক্কা দিতে বুকই সবচেয়ে ভালো', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'হট স্টিক হলে যেখানে খুশি ঠেলা যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'golden',
      promptBn: 'তার থেকে আলাদা করলেন, তিনি পড়ে আছেন — এবার কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'ask', labelBn: 'কাঁধে ঝাঁকুনি, "আপনি ঠিক আছেন?"', asset: 'assets/game/art/aid_board/gold_ask.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ask_call', labelBn: 'সাড়া দেখা, অন্যজন অ্যাম্বুলেন্সে কল', asset: 'assets/game/art/aid_board/gold_ask_call.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'mud',
          labelBn: 'মাটি-কাদায় পুঁতে রাখা',
          asset: 'assets/game/art/aid_board/gold_mud.svg',
          scene: true,
          correct: false,
          rejectBn: 'মাটি-কাদায় \'বিদ্যুৎ\' বেরোয় না — এটা অবৈজ্ঞানিক, সময় নষ্ট করে, ক্ষতে Infection বাড়ায়।',
        ),
        LearnBoardOption(
          id: 'wait',
          labelBn: 'হাত গুটিয়ে অ্যাম্বুলেন্সের অপেক্ষা',
          asset: 'assets/game/art/aid_board/gold_wait.svg',
          scene: true,
          correct: false,
          rejectBn: 'গোল্ডেন মিনিটে হাত গুটিয়ে নয় — কাঁধে ঝাঁকুনি দিয়ে সাড়া দেখুন, কাউকে অ্যাম্বুলেন্সে কল করতে বলুন।',
        ),
        LearnBoardOption(
          id: 'leave',
          labelBn: 'একা ফেলে চলে যাওয়া',
          asset: 'assets/game/art/aid_board/gold_leave.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভিকটিমকে একা ছাড়বেন না — সাড়া আর শ্বাস দেখুন, কাউকে অ্যাম্বুলেন্সে কল করতে বলুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বিপদ কাটলে সাড়া দেখি, কাউকে কল করতে বলি', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ভিকটিমের পাশে থেকে ধাপে ধাপে সাহায্য করি', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গোল্ডেন মিনিটের সঠিক পদক্ষেপই জীবন বাঁচায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'মাটিতে পুঁতলে ভেতরের বিদ্যুৎ বেরিয়ে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'কাদা মাখালে শরীর ঠান্ডা হয়ে সেরে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অ্যাম্বুলেন্স এলে তবেই কিছু করা দরকার', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'দাঁড়িয়ে অপেক্ষা করাই এখন সবচেয়ে নিরাপদ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'একটু শুইয়ে রাখলে নিজেই উঠে বসবেন', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'care',
      promptBn: 'জ্ঞান ফিরেছে, কথাও বলছেন — এবার কী?',
      options: [
        LearnBoardOption(id: 'walk', labelBn: 'ধরে ধরে অ্যাম্বুলেন্সে', asset: 'assets/game/art/aid_board/care_walk.svg', scene: true, correct: true),
        LearnBoardOption(id: 'seat', labelBn: 'অ্যাম্বুলেন্সে বসিয়ে হাসপাতালে', asset: 'assets/game/art/aid_board/care_seat.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'ice',
          labelBn: 'পোড়া হাতে বরফ',
          asset: 'assets/game/art/aid_board/care_ice.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোড়া জায়গায় বরফ, জল বা মলম নয় — ডাক্তারের কাছে নিন।',
        ),
        LearnBoardOption(
          id: 'water',
          labelBn: 'পোড়া হাতে জল ঢালা',
          asset: 'assets/game/art/aid_board/care_water.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোড়ায় জল ঢালবেন না, হাতও দেবেন না — ডাক্তারের কাছে নিন।',
        ),
        LearnBoardOption(
          id: 'cream',
          labelBn: 'পোড়ায় মলম লাগানো',
          asset: 'assets/game/art/aid_board/care_cream.svg',
          scene: true,
          correct: false,
          rejectBn: 'Entry/Exit পোড়ায় মলম নয় — সোজা ডাক্তারের কাছে।',
        ),
        LearnBoardOption(
          id: 'home',
          labelBn: 'কথা বলছেন, তাই বাড়ি',
          asset: 'assets/game/art/aid_board/care_home.svg',
          scene: true,
          correct: false,
          rejectBn: 'কথা বললেও হাসপাতালে নিন — ভেতরের ক্ষতি বাইরে দেখা যায় না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'কথা বললেও ভেতরের ক্ষতি দেখা যায় না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পোড়ায় বরফ, জল বা মলম নয় — ডাক্তার', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কথা বলতে পারলে আর হাসপাতাল লাগে না', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'পোড়ায় বরফ দিলে তাড়াতাড়ি সেরে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'জল ঢাললেই ভেতরের ক্ষতি কমে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'মলম লাগালে ডাক্তার দেখানোর দরকার নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'একটু বিশ্রাম নিলেই সব ঠিক হয়ে যাবে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: AidBoardLines.rivalTaunt,
    rivalLineBn: AidBoardLines.rivalMyth,
    exitBn: AidBoardLines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'LT শককে হালকা ভাবা',
      'ভেজা শরীরে LT-ও প্রাণ নিতে পারে',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ভোল্টেজ নয়, Current (Ampere) মারে', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'ভেজা শরীরে LT-ও Cardiac Arrest ঘটায়', correct: true),
      LearnWhyChip(id: 'm3', textBn: '50–100 mA Current-ই হৃৎপিণ্ড থামাতে পারে', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'কম ভোল্টেজে কখনো কারও প্রাণ যায় না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'LT শক একটু ঝাঁকুনি দিয়েই ছেড়ে দেয়', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'শুধু HT লাইনের শকেই প্রাণের ঝুঁকি থাকে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ভেজা হাতে LT ধরলেও তেমন কিছু হয় না', correct: false),
    ],
  ),
);

/// The careless lineman's lines on this board, in his recorded voice
/// (`r_<sha1>.mp3` in `learnRivalVoice`). The guide's lines stay in the pack
/// (device TTS until the owner records them).
abstract final class AidBoardLines {
  static const rivalTaunt = 'আরে! LT লাইন তো — একটু ঝাঁকুনি, ও কিছু না!';

  /// Lesson 1.7's myth buster, word for word.
  static const rivalMyth = 'কম ভোল্টেজ (LT Line) শক তেমন বিপজ্জনক নয়, একটু ঝাঁকুনি দিয়েই ছেড়ে দেয়।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// The new clips this board added.
  static const recorded = [rivalTaunt, rivalMyth];
}
