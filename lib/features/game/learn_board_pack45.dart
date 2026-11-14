import 'learn_board_models.dart';

/// Module 4 Lesson 4.5 (ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা পরীক্ষা), the
/// picture board (rung `4.5/learn`, pack `learn_4_5`, engineType `learn_cards`).
///
/// Picture cards are vector scenes from `tool/m4_board45_art.py`. Every round
/// and every trap comes from the lesson text or its film script:
///  * level: the conservator's glass gauge — the oil sits near the marked
///    line; heat expands the oil and the level rises; below Min is a serious
///    danger sign — lower still and the winding comes out of the oil, cooling
///    and insulation fail and the transformer can burn; leaks cause low oil;
///  * check: the level is read from a distance / from the ground with the
///    line on; heat is measured from a distance with an infrared thermometer,
///    no hand on the tank (film); going near a hot transformer is danger;
///  * heat: a mild hum and some warmth are normal, a summer noon or peak load
///    runs warmer; a boiling-oil sound / louder hum means overheating (main
///    cause overloading); creepers or dust on the fins stop the air;
///  * leak: a leak at a bushing gasket or the drain cock / valve is reported
///    to the supervisor at once (the climb trap's "shutdown" is the house
///    rule, not the lesson's words);
///  * topup: transformer shut down first; filtered new oil of the same grade;
///    wrong or wet oil damages it; engine oil means fire.
/// The rival's myth is the lesson's first myth buster, word for word.
const learnBoardPack45 = LearnBoardPack(
  lessonId: '4.5',
  titleBn: 'ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা পরীক্ষা',
  badgeBn: 'কাজের কারিগর',
  introBn: 'ট্রান্সফরমার লাইনের হৃৎপিণ্ড, তেল তার রক্ত। ডাক্তারের মতো এর রক্তচাপ আর জ্বর মাপা শিখুন।',
  earnedBn: 'তেল দাগের কাছে, তাপ দূর থেকে — লিক দেখলেই রিপোর্ট, টপ-আপ শুধু লাইন বন্ধ করে খাঁটি মিনারেল অয়েলে।',
  slots: [
    LearnBoardSlot(
      id: 'level',
      promptBn: 'কনজারভেটরের কাঁচের গেজ — কোন ছবিতে তেলের লেভেল ঠিক আছে?',
      options: [
        LearnBoardOption(
          id: 'mark',
          labelBn: 'তেল চিহ্নিত দাগের কাছাকাছি',
          asset: 'assets/game/art/m4_board45/level_mark.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'warm',
          labelBn: 'রোদে তেল প্রসারিত, লেভেল একটু ওপরে',
          asset: 'assets/game/art/m4_board45/level_warm.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'low',
          labelBn: 'তেল Min দাগের নিচে',
          asset: 'assets/game/art/m4_board45/level_low.svg',
          scene: true,
          correct: false,
          rejectBn: 'লেভেল Min দাগের নিচে নামা মানেই গুরুতর বিপদ সংকেত — অবিলম্বে সুপারভাইজারকে রিপোর্ট করুন।',
        ),
        LearnBoardOption(
          id: 'empty',
          labelBn: 'গেজ খালি, ওয়াইন্ডিং তেলের বাইরে',
          asset: 'assets/game/art/m4_board45/level_empty.svg',
          scene: true,
          correct: false,
          rejectBn: 'ওয়াইন্ডিং তেলের বাইরে এলে কুলিং আর ইনসুলেশন দুটোই ব্যাহত — ট্রান্সফরমার গরম হয়ে পুড়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'leak',
          labelBn: 'ড্রেন কক থেকে লিক, লেভেল Min-এর নিচে',
          asset: 'assets/game/art/m4_board45/level_leak.svg',
          scene: true,
          correct: false,
          rejectBn: 'কম তেলের প্রধান কারণ লিক — ড্রেন কক থেকে তেল লিক করছে, লেভেল Min-এর নিচে। এখনই রিপোর্ট করুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'তেলের লেভেল চিহ্নিত দাগের কাছাকাছি থাকা উচিত', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'গরমে তেল প্রসারিত হয়, তাই লেভেল একটু বাড়ে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'Min দাগের নিচে নামা মানেই গুরুতর বিপদ সংকেত', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'গেজে যতটুকু তেল দেখা যায়, ততটুকুই যথেষ্ট', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'Min দাগের নিচে নামলেও ট্রান্সফরমার নিরাপদ', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'গেজ খালি থাকলেও ওয়াইন্ডিং তেলে ডুবে থাকে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'লেভেল দেখতে আগে লাইন বন্ধ করতেই হবে', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'শীতে বা গরমে তেলের লেভেল একই থাকে সবসময়', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'তেল কমলে শুধু শব্দ বাড়ে, আর কোনো ক্ষতি নেই', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'check',
      promptBn: 'চালু ট্রান্সফরমারের তেল আর তাপ দেখবেন — কোনটা নিরাপদ উপায়?',
      options: [
        LearnBoardOption(
          id: 'ground',
          labelBn: 'নিচে দাঁড়িয়ে দূর থেকে গেজ দেখা',
          asset: 'assets/game/art/m4_board45/check_ground.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ir',
          labelBn: 'দূর থেকে ইনফ্রারেড থার্মোমিটারে তাপ মাপা',
          asset: 'assets/game/art/m4_board45/check_ir.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'hand',
          labelBn: 'গরম ট্যাঙ্কে হাত রেখে তাপ বোঝা',
          asset: 'assets/game/art/m4_board45/check_hand.svg',
          scene: true,
          correct: false,
          rejectBn: 'তাপ মাপতে ট্যাঙ্কে হাত দেবেন না — দূর থেকে ইনফ্রারেড থার্মোমিটারে মাপুন।',
        ),
        LearnBoardOption(
          id: 'ear',
          labelBn: 'গরম ট্যাঙ্কের গা ঘেঁষে শব্দ শোনা',
          asset: 'assets/game/art/m4_board45/check_ear.svg',
          scene: true,
          correct: false,
          rejectBn: 'গরম ট্রান্সফরমারের কাছে যাওয়া মানে নিজের বিপদ ডেকে আনা — দূরে থাকুন, দূর থেকে মাপুন।',
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'চালু ট্রান্সফরমারের ওপর উঠে গেজ দেখা',
          asset: 'assets/game/art/m4_board45/check_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'অয়েল লেভেল দূর থেকে বা নিচে দাঁড়িয়েই দেখা যায় — চালু ট্রান্সফরমারের ওপরে উঠবেন না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অয়েল লেভেল নিচে দাঁড়িয়ে দূর থেকেই দেখা যায়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'তাপ মাপুন দূর থেকে ইনফ্রারেড থার্মোমিটারে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'গরম ট্রান্সফরমারের কাছে গেলে নিজেরই বিপদ', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'ট্যাঙ্কে হাত রেখে তাপ বোঝাই সবচেয়ে নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'গেজ দেখতে ট্রান্সফরমারের ওপরে উঠতেই হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'কান লাগিয়ে শুনলে তবেই হামিং বোঝা যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'চালু ট্রান্সফরমারের ওপর দাঁড়ানো নিরাপদ', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ইনফ্রারেড থার্মোমিটার শুধু ল্যাবের জিনিস', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'দূর থেকে গেজের দাগ কখনো দেখা যায় না', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'heat',
      promptBn: 'কোন ছবির ট্রান্সফরমার স্বাভাবিকভাবে চলছে?',
      options: [
        LearnBoardOption(
          id: 'hum',
          labelBn: 'মৃদু হামিং, সামান্য গরম',
          asset: 'assets/game/art/m4_board45/heat_hum.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'noon',
          labelBn: 'গ্রীষ্মের দুপুরে একটু বেশি গরম',
          asset: 'assets/game/art/m4_board45/heat_noon.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'boil',
          labelBn: 'তেল ফোটার মতো শব্দ, প্রচণ্ড তাপ',
          asset: 'assets/game/art/m4_board45/heat_boil.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফুটন্ত তেলের মতো শব্দ বা বাড়তি হামিং অতিরিক্ত গরমের লক্ষণ — প্রধান কারণ ওভারলোডিং। লোড পরীক্ষা করে রিপোর্ট করুন।',
        ),
        LearnBoardOption(
          id: 'vines',
          labelBn: 'কুলিং ফিন লতাপাতায় ঢাকা',
          asset: 'assets/game/art/m4_board45/heat_vines.svg',
          scene: true,
          correct: false,
          rejectBn: 'ফিন লতাপাতায় ঢাকলে হাওয়া চলাচল বন্ধ — তেল ঠান্ডা হয় না, ট্রান্সফরমার অতিরিক্ত গরম হয়। ফিন পরিষ্কার রাখুন।',
        ),
        LearnBoardOption(
          id: 'dust',
          labelBn: 'কুলিং ফিনে পুরু ধুলোর স্তর',
          asset: 'assets/game/art/m4_board45/heat_dust.svg',
          scene: true,
          correct: false,
          rejectBn: 'ধুলোবালিতে ঢাকা ফিনে বাতাস লাগে না — তেল দ্রুত ঠান্ডা হতে পারে না। ফিন পরিষ্কার রাখুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'চলার সময় মৃদু হামিং আর তাপ থাকা স্বাভাবিক', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দুপুরে বা পিক লোডে বেশি গরম হওয়া স্বাভাবিক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'পরিষ্কার ফিনে বাতাস লেগে তেল ঠান্ডা হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'একটু গরম হলেই ট্রান্সফরমার খারাপ হয়ে গেছে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফুটন্ত তেলের মতো শব্দ মানে সব ঠিক আছে', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লতাপাতা ফিনকে রোদ থেকে ঠান্ডা রাখে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ফিনে ধুলো জমলে তাপ বের হতে সুবিধা হয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'ওভারলোডে ট্রান্সফরমারের তাপ একটুও বাড়ে না', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'হামিং যত জোরে, ট্রান্সফরমার তত সুস্থ', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'leak',
      promptBn: 'বুশিং বা ড্রেন কক থেকে তেল চুঁইয়ে পড়ছে — এবার কী করবেন?',
      options: [
        LearnBoardOption(
          id: 'call_drain',
          labelBn: 'ড্রেন ককের লিক সুপারভাইজারকে জানানো',
          asset: 'assets/game/art/m4_board45/leak_call_drain.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'call_bush',
          labelBn: 'বুশিংয়ের লিক সঙ্গে সঙ্গে রিপোর্ট',
          asset: 'assets/game/art/m4_board45/leak_call_bush.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'ignore',
          labelBn: 'লিক দেখেও ফোন দেখতে দেখতে চলে যাওয়া',
          asset: 'assets/game/art/m4_board45/leak_ignore.svg',
          scene: true,
          correct: false,
          rejectBn: 'লিক দেখলে সঙ্গে সঙ্গে রিপোর্ট করুন — তেল কমলে ওয়াইন্ডিং বেরিয়ে ট্রান্সফরমার পুড়ে যেতে পারে।',
        ),
        LearnBoardOption(
          id: 'bucket',
          labelBn: 'নিচে বালতি পেতে রেখে চলে যাওয়া',
          asset: 'assets/game/art/m4_board45/leak_bucket.svg',
          scene: true,
          correct: false,
          rejectBn: 'বালতিতে লিক সারে না — অবিলম্বে সুপারভাইজারকে রিপোর্ট; টপ-আপ আর লিক সারানোর ব্যবস্থা করতে হবে।',
        ),
        LearnBoardOption(
          id: 'climb',
          labelBn: 'চালু ট্রান্সফরমারে উঠে নিজেই বুশিং টাইট',
          asset: 'assets/game/art/m4_board45/leak_climb.svg',
          scene: true,
          correct: false,
          rejectBn: 'চালু ট্রান্সফরমারে উঠে নিজে কাজ নয় — আগে সুপারভাইজারকে রিপোর্ট, লিক সারানো হবে শাটডাউন নিয়ে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'লিক দেখলে সঙ্গে সঙ্গে সুপারভাইজারকে রিপোর্ট', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'কম তেলের প্রধান কারণ হলো তেল লিক করা', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'বুশিং গ্যাসকেট বা ড্রেন কক থেকে লিক হতে পারে', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'অল্প লিক হলে পরের মাসে জানালেই চলবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'বালতি পেতে রাখলেই লিকের সমস্যা মিটে যায়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'চালু ট্রান্সফরমারে উঠে নিজে টাইট দেওয়া যায়', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বুশিং থেকে লিক কখনোই হয় না, চিন্তা নেই', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'তেল লিক করলে ট্রান্সফরমারের কোনো ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'লিকের খবর দেওয়া লাইনম্যানের কাজই নয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'topup',
      promptBn: 'ট্রান্সফরমারে তেল টপ-আপ করতে হবে — কোনটা ঠিক?',
      options: [
        LearnBoardOption(
          id: 'drum',
          labelBn: 'লাইন বন্ধ, ফিল্টার করা নতুন তেল',
          asset: 'assets/game/art/m4_board45/topup_drum.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'pump',
          labelBn: 'লাইন বন্ধ, সিল করা ড্রামের নতুন তেল',
          asset: 'assets/game/art/m4_board45/topup_pump.svg',
          scene: true,
          correct: true,
        ),
        LearnBoardOption(
          id: 'engine',
          labelBn: 'গাড়ির ইঞ্জিন অয়েল ঢেলে দেওয়া',
          asset: 'assets/game/art/m4_board45/topup_engine.svg',
          scene: true,
          correct: false,
          rejectBn: 'ইঞ্জিন অয়েল চলবে না — উচ্চ ডাই-ইলেকট্রিক ক্ষমতার খাঁটি মিনারেল অয়েল ছাড়া অন্য তেলে মুহূর্তে আগুন ধরে যাবে।',
        ),
        LearnBoardOption(
          id: 'wet',
          labelBn: 'বৃষ্টিতে খোলা বালতির তেল ঢালা',
          asset: 'assets/game/art/m4_board45/topup_wet.svg',
          scene: true,
          correct: false,
          rejectBn: 'ভুল তেল বা আর্দ্র তেল ব্যবহার করলে ট্রান্সফরমারের ক্ষতি হবে — শুধু ফিল্টার করা নতুন তেল।',
        ),
        LearnBoardOption(
          id: 'live',
          labelBn: 'চালু লাইনেই তেল টপ-আপ',
          asset: 'assets/game/art/m4_board45/topup_live.svg',
          scene: true,
          correct: false,
          rejectBn: 'তেল টপ-আপের আগে ট্রান্সফরমার বন্ধ করতে হয় — লাইন বন্ধ করে তবেই তেল ঢালুন।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'টপ-আপের আগে ট্রান্সফরমার বন্ধ করে নিতে হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'একই গ্রেডের, ফিল্টার করা নতুন তেলই ঢালুন', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'আর্দ্র বা ভুল তেলে ট্রান্সফরমারের ক্ষতি হয়', correct: true),
        LearnWhyChip(id: 'w4', textBn: 'যেকোনো পরিষ্কার তেল দিলেই কাজ চলে যায়', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'চালু লাইনেই তেল ঢাললে সময় বাঁচে, ঝুঁকি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'বৃষ্টির জল মেশানো তেলে কোনো সমস্যা নেই', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'না ছাঁকা পুরোনো তেলই বেশি ভালো কাজ দেয়', correct: false),
        LearnWhyChip(id: 'w8', textBn: 'গ্রেড আলাদা হলেও তেল তো তেলই, চলে যাবে', correct: false),
        LearnWhyChip(id: 'w9', textBn: 'ইঞ্জিন অয়েল ঢাললেও ট্রান্সফরমার চলবে', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: M4Board45Lines.rivalTaunt,
    rivalLineBn: M4Board45Lines.rivalMyth,
    exitBn: M4Board45Lines.rivalExit,
    believeNoIsCorrect: true,
    stingBn: 'এই লোক যা বলছে… বিশ্বাস করেন?',
    dangerHints: [
      'গাড়ির ইঞ্জিন অয়েল',
      'যেকোনো তেল ভরে দেওয়া',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'ট্রান্সফরমার অয়েল বিশেষ ধরনের মিনারেল অয়েল', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'অন্য তেল দিলে মুহূর্তে খারাপ, আগুনও লাগে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'এর উচ্চ ডাই-ইলেকট্রিক স্ট্রেন্থ আর তাপ পরিবাহিতা', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'ইঞ্জিন অয়েলও তো তেল, ট্রান্সফরমারে চলে যায়', correct: false),
      LearnWhyChip(id: 'm5', textBn: 'যেকোনো তেল ভরলেই ভেতরের কুলিং ঠিক থাকে', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'তেলের গ্রেড দেখার কাজ শুধু ইঞ্জিনিয়ারের', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'কয়েক দিনের জন্য যেকোনো তেলেই কাজ চলে যায়', correct: false),
      LearnWhyChip(id: 'm8', textBn: 'ইঞ্জিন অয়েলে আগুন লাগার কোনো ভয়ই নেই', correct: false),
      LearnWhyChip(id: 'm9', textBn: 'তেল কমলে হাতের কাছে যে তেল আছে তাই ঢেলে দিন', correct: false),
    ],
  ),
);

/// The careless coworker's lines on this board. [rivalExit] is already in his
/// recorded voice; [toRecord] play through device TTS until recorded.
abstract final class M4Board45Lines {
  static const rivalTaunt = 'আরে, তেল কমেছে তো কী! গাড়ির তেল আছে, ঢেলে দিই।';

  /// Lesson 4.5's first myth buster, word for word.
  static const rivalMyth = 'ট্রান্সফরমারের তেল কমে গেলে তাতে সাধারণ গাড়ির ইঞ্জিন অয়েল বা যেকোনো তেল ভরে দিলেই চলে।';

  /// Already recorded (reused).
  static const rivalExit = 'হুঁ! যা খুশি করুন।';

  /// New rival lines for the voice session.
  static const toRecord = [rivalTaunt, rivalMyth];
}
