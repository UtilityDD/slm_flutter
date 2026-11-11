import 'learn_board_models.dart';

/// Module 3 Lesson 3.5 (লাইটনিং অ্যারেস্টার (LA): বজ্রপাতের কবচ), the picture
/// board (rung `3.5/learn`, pack `learn_3_5`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m3_board35_art.py`. Every round
/// and every trap comes from the lesson text and its film script:
///  * fit: the LA sits right beside the transformer's HT bushing, as close as
///    possible (further away it works less well); each phase R, Y, B gets its
///    own LA; without a proper LA lightning can burn the transformer;
///  * work: at normal voltage the LA is an insulator (no current); on a surge
///    the MOV conducts and sends it straight to earth, then it is an insulator
///    again; it neither stops nor attracts lightning; with a weak earth the
///    surge goes through the transformer instead;
///  * body: no crack, break or burn mark on the porcelain / polymer housing;
///    a broken / blown LA means a big surge came, and a damaged LA protects
///    nothing;
///  * earth: the earth wire from the bottom terminal firmly connected, not cut
///    anywhere (a small cut or loose joint raises the resistance many times);
///    a hanging earth wire (the disconnector fired) proves the LA is bad;
///    the lower the ohms, the better the LA;
///  * patrol: on patrol, look whether the LA beside the transformer is fitted
///    and whole; look at the body and the earth rod regularly.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack35 = LearnBoardPack(
  lessonId: '3.5',
  titleBn: 'লাইটনিং অ্যারেস্টার (LA): বজ্রপাতের কবচ',
  badgeBn: 'লাইন চেনার জাদুকর',
  introBn: 'বাজের সার্জ এলে LA সেটাকে মাটিতে নামিয়ে দেয়। তার আসল শক্তি — আর্থিং।',
  earnedBn: 'LA বাজ আটকায় না, সার্জকে মাটিতে পাঠায় — কাছে, প্রতি ফেজে, শক্ত আর্থিংয়ে।',
  slots: [
    LearnBoardSlot(
      id: 'fit',
      promptBn: 'নতুন ট্রান্সফরমারে LA বসানো হবে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'porc',
          labelBn: 'বুশিংয়ের পাশে পোর্সেলিন LA',
          asset: 'assets/game/art/m3_board35/fit_porc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'poly',
          labelBn: 'বুশিংয়ের পাশে পলিমার LA',
          asset: 'assets/game/art/m3_board35/fit_poly.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'one',
          labelBn: 'তিন ফেজের জন্য মাত্র একটা LA',
          asset: 'assets/game/art/m3_board35/fit_one.svg',
          scene: true,
          correct: false,
          rejectBn: 'থ্রি-ফেজ সিস্টেমে R, Y, B — প্রতিটি ফেজের জন্য আলাদা আলাদা LA লাগানো হয়।',
        ),
        LearnBoardOption(
          id: 'far',
          labelBn: 'ট্রান্সফরমার থেকে অনেক দূরে LA',
          asset: 'assets/game/art/m3_board35/fit_far.svg',
          scene: true,
          correct: false,
          rejectBn: 'LA যাকে রক্ষা করবে, তার যতটা সম্ভব কাছে লাগান — দূরত্ব বাড়লে কার্যকারিতা কমে যায়।',
        ),
        LearnBoardOption(
          id: 'none',
          labelBn: 'LA ছাড়াই ট্রান্সফরমার চালু',
          asset: 'assets/game/art/m3_board35/fit_none.svg',
          scene: true,
          correct: false,
          rejectBn: 'বজ্রপাতের সময় সঠিক LA না থাকলে ট্রান্সফরমার পুড়ে যেতে পারে — পুরো গ্রিডের ক্ষতি।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'LA বসে ট্রান্সফরমারের HT বুশিংয়ের ঠিক পাশে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'R, Y, B — প্রতিটি ফেজের জন্য আলাদা LA চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'দূরত্ব বাড়লে LA-এর কার্যকারিতা কমে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'তিন ফেজের জন্য একটা LA লাগালেই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'LA যত দূরে বসে, ট্রান্সফরমার তত নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'পলিমার LA শুধু দেখনদারি, কাজের কিছু নয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ছোট ট্রান্সফরমারে LA-এর কোনো দরকার নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শুধু R ফেজে LA থাকলেই বাকিরাও বেঁচে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'LA যেকোনো খুঁটিতে বসালেই একই কাজ হয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'work',
      promptBn: 'সুস্থ LA, ভালো আর্থিং — কোন ছবিতে LA ঠিক কাজ করছে?',
      options: [
        LearnBoardOption(
          id: 'calm',
          labelBn: 'স্বাভাবিক ভোল্টেজে LA চুপচাপ',
          asset: 'assets/game/art/m3_board35/work_calm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'surge',
          labelBn: 'বাজের সার্জ LA দিয়ে মাটিতে',
          asset: 'assets/game/art/m3_board35/work_surge.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'leak',
          labelBn: 'ঝড় নেই, তবু LA দিয়ে কারেন্ট',
          asset: 'assets/game/art/m3_board35/work_leak.svg',
          scene: true,
          correct: false,
          rejectBn: 'স্বাভাবিক ভোল্টেজে LA ইনসুলেটরের মতো — এর মধ্যে দিয়ে কোনো কারেন্ট যায় না।',
        ),
        LearnBoardOption(
          id: 'burn',
          labelBn: 'সার্জ ঢুকছে ট্রান্সফরমারে',
          asset: 'assets/game/art/m3_board35/work_burn.svg',
          scene: true,
          correct: false,
          rejectBn: 'আর্থিং কাটা বা দুর্বল হলে সার্জ মাটিতে না গিয়ে ট্রান্সফরমার জ্বালিয়ে দেয় — তখন LA থাকা না থাকা সমান।',
        ),
        LearnBoardOption(
          id: 'attract',
          labelBn: 'LA আকাশ থেকে বাজ টেনে আনছে',
          asset: 'assets/game/art/m3_board35/work_attract.svg',
          scene: true,
          correct: false,
          rejectBn: 'LA বজ্রপাতকে আকর্ষণ করে না, আটকায়ও না — লাইনে আসা সার্জকে শুধু মাটিতে যাওয়ার পথ করে দেয়।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'স্বাভাবিক ভোল্টেজে LA ইনসুলেটরের মতো কাজ করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সার্জ এলে MOV পরিবাহী হয়ে সার্জ মাটিতে পাঠায়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'সার্জ পাস হতেই LA আবার ইনসুলেটর হয়ে যায়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'স্বাভাবিক সময়েও LA দিয়ে সারাক্ষণ কারেন্ট যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'LA আকাশ থেকে বাজ টেনে এনে মাটিতে ফেলে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'সার্জ এলে LA লাইনটা চিরকালের মতো কেটে দেয়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্থিং দুর্বল হলেও LA পুরো সুরক্ষা দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'সার্জ কারেন্ট ট্রান্সফরমার হয়ে মাটিতে যায়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'সার্জ সামলাতে LA কয়েক মিনিট সময় নেয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'body',
      promptBn: 'পেট্রোলিং-এ LA-এর বডি দেখছেন — কোনটা সুস্থ?',
      options: [
        LearnBoardOption(
          id: 'porc',
          labelBn: 'ফাটল-দাগহীন পোর্সেলিন LA',
          asset: 'assets/game/art/m3_board35/body_porc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'poly',
          labelBn: 'অক্ষত পলিমার হাউজিং-এর LA',
          asset: 'assets/game/art/m3_board35/body_poly.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'পোর্সেলিন বডিতে সরু ফাটল',
          asset: 'assets/game/art/m3_board35/body_crack.svg',
          scene: true,
          correct: false,
          rejectBn: 'বাইরের আবরণে কোনো ফাটল থাকা চলবে না — ক্ষতিগ্রস্ত LA কোনো সুরক্ষা দিতে পারে না।',
        ),
        LearnBoardOption(
          id: 'burnt',
          labelBn: 'বডিতে কালো পোড়া দাগ',
          asset: 'assets/game/art/m3_board35/body_burnt.svg',
          scene: true,
          correct: false,
          rejectBn: 'পোর্সেলিন বা পলিমারের আবরণে পোড়া দাগ থাকা উচিত নয় — এমন LA ক্ষতিগ্রস্ত।',
        ),
        LearnBoardOption(
          id: 'blown',
          labelBn: 'বিস্ফোরণে ভেঙে যাওয়া LA',
          asset: 'assets/game/art/m3_board35/body_blown.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা বা বিস্ফোরিত LA মানে লাইনে বড় সার্জ এসেছিল — এই LA আর সুরক্ষা দিতে পারে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'আবরণে ফাটল, ভাঙা বা পোড়া দাগ থাকা চলবে না', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'ক্ষতিগ্রস্ত LA কোনো সুরক্ষাই দিতে পারে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ভাঙা LA মানে ওই লাইনে বড় সার্জ এসেছিল', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'সরু ফাটল থাকলেও LA পুরো সুরক্ষা দেয়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'পোড়া দাগ মানে LA ভালোভাবে কাজ করছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বিস্ফোরিত LA-ও পরের বাজ সামলে নেবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বডি দেখার দরকার নেই, আর্থিং থাকলেই হলো', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'পলিমার LA একটু ফাটলেও কিছুই হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ভাঙা LA দেখলে বুঝবেন লাইনে কিছুই হয়নি', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'earth',
      promptBn: 'LA-এর নিচ থেকে নামা আর্থিং তার — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'porc',
          labelBn: 'LA থেকে রড পর্যন্ত অক্ষত তার',
          asset: 'assets/game/art/m3_board35/earth_porc.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'poly',
          labelBn: 'আর্থিং রডে মজবুত করে আঁটা তার',
          asset: 'assets/game/art/m3_board35/earth_poly.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'nick',
          labelBn: 'একটু কাটা তার, বাকিটা তো ঠিক',
          asset: 'assets/game/art/m3_board35/earth_nick.svg',
          scene: true,
          correct: false,
          rejectBn: 'সামান্য কাটা আর্থিং তার রেজিস্ট্যান্স বহুগুণ বাড়ায় — সার্জ মাটিতে না গিয়ে ট্রান্সফরমারে ঢোকে।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'রডের ক্ল্যাম্পে ঢিলে কানেকশন',
          asset: 'assets/game/art/m3_board35/earth_loose.svg',
          scene: true,
          correct: false,
          rejectBn: 'লুজ কানেকশনেও রেজিস্ট্যান্স বহুগুণ বাড়ে — আর্থিং তার মজবুতভাবে সংযুক্ত থাকা চাই।',
        ),
        LearnBoardOption(
          id: 'hang',
          labelBn: 'ডিসকানেক্টর খুলে ঝুলছে তার',
          asset: 'assets/game/art/m3_board35/earth_hang.svg',
          scene: true,
          correct: false,
          rejectBn: 'ডিসকানেক্টর খুলে ঝুলে থাকা আর্থিং তার প্রমাণ করে যে LA-টি খারাপ হয়ে গেছে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'LA-এর কার্যকারিতা পুরোপুরি আর্থিংয়ের ওপর', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'আর্থিং যত কম ওহম, LA তত বেশি কার্যকর', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঝুলে থাকা আর্থিং তার মানে LA খারাপ হয়ে গেছে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'আর্থিং তার একটু কাটা থাকলেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঢিলে কানেকশনেও সার্জ ঠিকই মাটিতে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আর্থিং যত বেশি ওহম, LA তত বেশি কার্যকর', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ঝুলে থাকা আর্থিং তার মানে LA ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'খারাপ আর্থিং থাকলেও LA অর্ধেক কাজ করে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'আর্থিং রডের ক্ল্যাম্প আলগা থাকাই ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'patrol',
      promptBn: 'ট্রান্সফরমারের পাশ দিয়ে লাইন পেট্রোলিং — কোন অভ্যাস ঠিক?',
      options: [
        LearnBoardOption(
          id: 'la',
          labelBn: 'LA বসানো ও অক্ষত কিনা দেখা',
          asset: 'assets/game/art/m3_board35/patrol_la.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'rod',
          labelBn: 'আর্থিং তার ও রড চোখে পরখ',
          asset: 'assets/game/art/m3_board35/patrol_rod.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'skip',
          labelBn: 'না তাকিয়েই পাশ কাটিয়ে যাওয়া',
          asset: 'assets/game/art/m3_board35/patrol_skip.svg',
          scene: true,
          correct: false,
          rejectBn: 'পেট্রোলিং-এ দেখুন ট্রান্সফরমারের পাশে LA বসানো আছে কিনা, আর সেটা অক্ষত কিনা।',
        ),
        LearnBoardOption(
          id: 'hang',
          labelBn: 'ঝুলন্ত তার দেখেও চলে যাওয়া',
          asset: 'assets/game/art/m3_board35/patrol_hang.svg',
          scene: true,
          correct: false,
          rejectBn: 'ঝুলে থাকা আর্থিং তার প্রমাণ করে LA খারাপ — খারাপ LA কোনো সুরক্ষা দিতে পারে না।',
        ),
        LearnBoardOption(
          id: 'blown',
          labelBn: 'ভাঙা LA দেখেও এগিয়ে যাওয়া',
          asset: 'assets/game/art/m3_board35/patrol_blown.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভাঙা LA মানে লাইনে বড় সার্জ এসেছিল — ক্ষতিগ্রস্ত LA ট্রান্সফরমারকে বাঁচাতে পারে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'পেট্রোলিং-এ দেখুন LA বসানো ও অক্ষত আছে কিনা', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'বডি ও আর্থিং রড নিয়মিত চোখে পরখ করুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ঝুলন্ত আর্থিং তার বা ভাঙা বডি মানে LA খারাপ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ভালো দিনে LA দেখার কোনো দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঝুলন্ত আর্থিং তার নিজে থেকেই ঠিক হয়ে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ভাঙা LA থাকলেও পরের ঝড়ে কাজ চালিয়ে নেবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'আর্থিং রড মাটির নিচে, তাই দেখার কিছু নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'একবার বসানো LA আর কখনো দেখতে হয় না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ট্রান্সফরমার চললে LA-ও নিশ্চয়ই ঠিক আছে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M3Board35Lines.rivalTaunt,
    rivalLineBn: M3Board35Lines.rivalMyth,
    exitBn: M3Board35Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'LA বাজ আটকায় ভেবে নিশ্চিন্ত',
      'আর্থিং আর বডি না দেখা',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'LA বজ্রপাত আটকায় না, আকর্ষণও করে না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'LA লাইনে আসা সার্জকে মাটিতে পথ করে দেয়', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'LA হলো ডাইভার্টার — সার্জের পথ বদলে দেয়', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'LA থাকলে ওই লাইনে কখনো বাজ পড়ে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'LA আকাশের বাজ টেনে নিজের দিকে আনে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'নামেই অ্যারেস্টার, তাই বাজ আটকে রাখে', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'LA থাকলে আর্থিং দেখার কোনো দরকার নেই', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'LA বাজকে লাইনের ভেতরেই আটকে রাখে', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'LA থাকলে ঝড়ে লাইনে কোনো সার্জ আসে না', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M3Board35Lines {
  static const rivalTaunt = 'আরে, LA তো বসানোই আছে! এখানে বাজ পড়বেই না, ভয় কীসের?';

  /// Lesson 3.5's first myth buster, word for word.
  static const rivalMyth = "লাইটনিং অ্যারেস্টার বজ্রপাতকে 'আটকায়' বা প্রতিরোধ করে।";

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
