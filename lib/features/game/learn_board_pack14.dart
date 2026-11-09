import 'learn_board_models.dart';

/// Ladder step 10 — Module 1 Lesson 1.4 (সেফটি হারনেস: আপনার লাইফলাইন).
///
/// Picture cards are vector scenes from `tool/harness_board_art.py`. Every
/// round and every trap comes from the lesson text:
///  * full body harness (shoulders, chest, thighs) for fall arrest; the waist
///    belt is for work positioning only and in a fall loads belly and spine;
///  * the 3-minute check before every wear — webbing (cut, torn, burn,
///    chemical), stitching, metal parts (crack, deformation, heavy rust), the
///    label's expiry date; a small cut can cut strength by up to 50 %; any
///    doubt = reject;
///  * fit — no twisted strap, about four fingers under a strap, chest strap
///    across mid-chest, back D-ring between the shoulders; a loose harness can
///    slip off in a fall;
///  * the lanyard to a strong anchor — never a broken cross-arm or a weak
///    insulator pin;
///  * suspension trauma — hanging long can make a worker faint within minutes,
///    so a quick rescue must be planned.
const learnBoardPack14 = LearnBoardPack(
  lessonId: '1.4',
  titleBn: 'সেফটি হারনেস: আপনার লাইফলাইন',
  badgeBn: 'সুরক্ষা কবচ',
  introBn: 'হারনেস আপনার প্যারাশুট। ছেঁড়া প্যারাশুট নিয়ে কেউ লাফ দেয় না — ঠিকটা চিনুন।',
  earnedBn: 'লাইফলাইন চিনেছেন — প্রতিবার পরীক্ষা, সন্দেহ হলেই বাতিল।',
  slots: [
    LearnBoardSlot(
      id: 'type',
      promptBn: 'পোলে উঠছেন — পা পিছলালে কী বাঁচাবে?',
      options: [
        LearnBoardOption(id: 'fbh', labelBn: 'ফুল বডি হারনেস, অ্যাঙ্কর করা', asset: 'assets/game/art/harness_board/type_fbh.svg', scene: true, correct: true),
        LearnBoardOption(id: 'fbh_reach', labelBn: 'ফুল বডি হারনেস, অ্যাঙ্কর করা', asset: 'assets/game/art/harness_board/type_fbh_reach.svg', scene: true, correct: true),
        LearnBoardOption(id: 'fall_fbh', labelBn: 'হারনেসে আটকে গেছেন', asset: 'assets/game/art/harness_board/type_fall_fbh.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'belt',
          labelBn: 'শুধু কোমরের বেল্ট',
          asset: 'assets/game/art/harness_board/type_belt.svg', scene: true,
          correct: false,
          rejectBn: 'কোমরের বেল্ট শুধু ওয়ার্ক পজিশনিংয়ের জন্য — পতন থামায় না।',
        ),
        LearnBoardOption(
          id: 'fall_belt',
          labelBn: 'কোমরের বেল্টে ঝুলে',
          asset: 'assets/game/art/harness_board/type_fall_belt.svg', scene: true,
          correct: false,
          rejectBn: 'পড়লে কোমরের বেল্ট সব চাপ পেট আর শিরদাঁড়ায় ফেলে — মৃত্যু বা পঙ্গুত্ব হতে পারে।',
        ),
        LearnBoardOption(
          id: 'none',
          labelBn: 'কিছুই না, শুধু সাবধানে',
          asset: 'assets/game/art/harness_board/type_none.svg', scene: true,
          correct: false,
          rejectBn: 'মাধ্যাকর্ষণ অভিজ্ঞতা মানে না — হারনেসই একমাত্র দ্বিতীয় সুযোগ।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফুল বডি হারনেস ভার কাঁধ-বুক-ঊরুতে ভাগ করে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'পতন থামাতে ফুল বডি হারনেস বাধ্যতামূলক', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'কোমরের বেল্টই পতনে সবচেয়ে ভালো ধরে রাখে', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'খুব সাবধানে থাকলে হারনেস লাগেই না কখনো', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'অভিজ্ঞ লাইনম্যান কখনো পোল থেকে পড়ে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'হারনেস শুধু নতুন কর্মীদের জন্য দরকার', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বেল্ট আর হারনেস পতনে একই কাজ করে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'webbing',
      promptBn: 'পরার আগে ফিতে আর সেলাই — কোনটা পরবেন?',
      options: [
        LearnBoardOption(id: 'ok', labelBn: 'ফিতে আর সেলাই অক্ষত', asset: 'assets/game/art/harness_board/web_ok.svg', scene: true, correct: true),
        LearnBoardOption(id: 'ok_buckle', labelBn: 'অক্ষত ফিতে ও বকলস', asset: 'assets/game/art/harness_board/web_ok_buckle.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'cut',
          labelBn: 'ফিতের কিনারায় কাটা',
          asset: 'assets/game/art/harness_board/web_cut.svg', scene: true,
          correct: false,
          rejectBn: 'ছোট একটা কাটাও ফিতের শক্তি 50% পর্যন্ত কমিয়ে দিতে পারে।',
        ),
        LearnBoardOption(
          id: 'burn',
          labelBn: 'ফিতেয় পোড়া দাগ',
          asset: 'assets/game/art/harness_board/web_burn.svg', scene: true,
          correct: false,
          rejectBn: 'পোড়া দাগে ফিতে দুর্বল — সন্দেহ মানেই বাতিল।',
        ),
        LearnBoardOption(
          id: 'chem',
          labelBn: 'রাসায়নিকের দাগ',
          asset: 'assets/game/art/harness_board/web_chem.svg', scene: true,
          correct: false,
          rejectBn: 'রাসায়নিকে ফিতে নষ্ট হয় — এমন হারনেস বাতিল করুন।',
        ),
        LearnBoardOption(
          id: 'stitch',
          labelBn: 'সেলাই খুলে গেছে',
          asset: 'assets/game/art/harness_board/web_stitch.svg', scene: true,
          correct: false,
          rejectBn: 'সেলাই খুলে বা ছিঁড়ে গেলে হারনেস দুর্বল হয়ে পড়ে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ছোট কাটাও ফিতের শক্তি 50% পর্যন্ত কমাতে পারে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সেলাই ছিঁড়লে বা খুললে হারনেস দুর্বল হয়', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'একটু কাটা থাকলেও হারনেস ঠিকই ধরে রাখে', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'দাগ শুধু দেখতে খারাপ, শক্তিতে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'দু-একটা সেলাই খুললে তেমন ক্ষতি নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'নতুন কেনা হারনেস দেখার দরকার পড়ে না', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'রোদে রাখলে ফিতে আরও মজবুত হয়ে যায়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'metal',
      promptBn: 'এবার ধাতব অংশ আর লেবেল — কোনটা চলবে?',
      options: [
        LearnBoardOption(id: 'dring_ok', labelBn: 'অক্ষত ডি-রিং', asset: 'assets/game/art/harness_board/hw_dring_ok.svg', scene: true, correct: true),
        LearnBoardOption(id: 'label_ok', labelBn: 'মেয়াদ আছে এমন লেবেল', asset: 'assets/game/art/harness_board/hw_label_ok.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'crack',
          labelBn: 'ফাটা ডি-রিং',
          asset: 'assets/game/art/harness_board/hw_dring_crack.svg', scene: true,
          correct: false,
          rejectBn: 'ডি-রিংয়ে ফাটল — ধাতব অংশে ফাটল থাকলে হারনেস বাতিল।',
        ),
        LearnBoardOption(
          id: 'rust',
          labelBn: 'মরিচা ধরা ডি-রিং',
          asset: 'assets/game/art/harness_board/hw_dring_rust.svg', scene: true,
          correct: false,
          rejectBn: 'অতিরিক্ত মরিচা ধরা ধাতুতে ভরসা নেই — হারনেস বাতিল।',
        ),
        LearnBoardOption(
          id: 'bent',
          labelBn: 'বেঁকে যাওয়া বকলস',
          asset: 'assets/game/art/harness_board/hw_buckle_bent.svg', scene: true,
          correct: false,
          rejectBn: 'বকলস বিকৃত হলে সন্দেহ — আর সন্দেহ মানেই বাতিল।',
        ),
        LearnBoardOption(
          id: 'expired',
          labelBn: 'মেয়াদ পেরোনো লেবেল',
          asset: 'assets/game/art/harness_board/hw_label_expired.svg', scene: true,
          correct: false,
          rejectBn: 'মেয়াদ উত্তীর্ণ হারনেস ব্যবহার করা যাবে না — মজবুত দেখালেও।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ফাটা, বাঁকা বা মরিচা ধরা ধাতু মানেই বাতিল', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'লেবেলের মেয়াদ পেরোলে হারনেস আর চলবে না', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'ধাতু শক্ত, তাই ছোট ফাটলে কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'মজবুত লাগলে মেয়াদ পেরোলেও দিব্যি চলে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'একটু মরিচা থাকলে হারনেস আরও শক্ত হয়', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'লেবেল শুধু কোম্পানির নাম লেখার জন্য', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'বকলস একটু বাঁকা হলেও দিব্যি আটকে থাকে', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'fit',
      promptBn: 'হারনেস পরলেন — কার ফিটিং ঠিক?',
      options: [
        LearnBoardOption(id: 'ok', labelBn: 'বুকের ফিতে মাঝ বরাবর', asset: 'assets/game/art/harness_board/fit_ok.svg', scene: true, correct: true),
        LearnBoardOption(id: 'back_ok', labelBn: 'ডি-রিং দুই কাঁধের মাঝে', asset: 'assets/game/art/harness_board/fit_back_ok.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'neck',
          labelBn: 'বুকের ফিতে গলার কাছে',
          asset: 'assets/game/art/harness_board/fit_neck.svg', scene: true,
          correct: false,
          rejectBn: 'বুকের ফিতে থাকবে বুকের মাঝ বরাবর — গলার কাছে নয়।',
        ),
        LearnBoardOption(
          id: 'twisted',
          labelBn: 'পেঁচানো ফিতে',
          asset: 'assets/game/art/harness_board/fit_twisted.svg', scene: true,
          correct: false,
          rejectBn: 'ফিতে পেঁচিয়ে থাকা চলবে না — সোজা করে তারপর পরুন।',
        ),
        LearnBoardOption(
          id: 'loose',
          labelBn: 'ঢিলেঢালা হারনেস',
          asset: 'assets/game/art/harness_board/fit_loose.svg', scene: true,
          correct: false,
          rejectBn: 'ঢিলে হারনেস পতনের সময় শরীর থেকে খুলে যেতে পারে — ফিতের নিচে চার আঙুল ঢোকার মতো ফিট চাই।',
        ),
        LearnBoardOption(
          id: 'dring_low',
          labelBn: 'ডি-রিং কোমরের কাছে',
          asset: 'assets/game/art/harness_board/fit_dring_low.svg', scene: true,
          correct: false,
          rejectBn: 'পেছনের ডি-রিং থাকবে দুই কাঁধের মাঝখানে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'বুকের ফিতে মাঝ বুকে, ডি-রিং দুই কাঁধের মাঝে', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'সঠিক ফিটিংই পতনের সময় সুরক্ষা নিশ্চিত করে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'যত ঢিলে করে পরবেন, পোলে তত আরামে কাজ', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'বুকের ফিতে গলার কাছে থাকলেই বেশি নিরাপদ', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ফিতে একটু পেঁচানো থাকলে কিছু যায় আসে না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'ডি-রিং পিঠের যেখানে খুশি থাকলেই চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'যত টাইট, তত নিরাপদ — আঙুল না ঢুকলেই ভালো', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'anchor',
      promptBn: 'পোলের মাথায় — ল্যানিয়ার্ড কোথায় লাগাবেন?',
      options: [
        LearnBoardOption(id: 'sling', labelBn: 'পোলে মজবুত অ্যাঙ্কর', asset: 'assets/game/art/harness_board/anc_sling.svg', scene: true, correct: true),
        LearnBoardOption(id: 'sling_reach', labelBn: 'পোলে মজবুত অ্যাঙ্কর', asset: 'assets/game/art/harness_board/anc_sling_reach.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'broken_arm',
          labelBn: 'ভাঙা ক্রস-আর্মে',
          asset: 'assets/game/art/harness_board/anc_broken_arm.svg', scene: true,
          correct: false,
          rejectBn: 'ভাঙা ক্রস-আর্ম কখনো ভালো অ্যাঙ্কর পয়েন্ট হতে পারে না।',
        ),
        LearnBoardOption(
          id: 'pin',
          labelBn: 'ইনসুলেটর পিনে',
          asset: 'assets/game/art/harness_board/anc_pin.svg', scene: true,
          correct: false,
          rejectBn: 'দুর্বল ইনসুলেটর পিন কখনো ভালো অ্যাঙ্কর হতে পারে না।',
        ),
        LearnBoardOption(
          id: 'none',
          labelBn: 'ল্যানিয়ার্ড ঝুলছে',
          asset: 'assets/game/art/harness_board/anc_none.svg', scene: true,
          correct: false,
          rejectBn: 'ল্যানিয়ার্ড অ্যাঙ্করে না লাগালে হারনেস পতন থামাবে না।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'অ্যাঙ্কর দুর্বল হলে পুরো সিস্টেমই ব্যর্থ হয়', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'অ্যাঙ্কর আমার ওজনের অনেক গুণ ভার সইবে', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হাতের কাছে যা পাই, সেখানেই লাগানো যায়', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'ইনসুলেটর পিন শক্ত, তাই ভালো অ্যাঙ্কর', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ভালো হারনেস থাকলে অ্যাঙ্কর নিয়ে ভাবনা নেই', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'অল্প সময়ের কাজে অ্যাঙ্কর না করলেও চলে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ক্রস-আর্ম একটু ফাটা হলেও ভার সয়ে নেয়', correct: false),
      ],
    ),
    LearnBoardSlot(
      id: 'rescue',
      promptBn: 'সঙ্গী পড়ে হারনেসে ঝুলছেন — কোনটা ঠিক?',
      options: [
        LearnBoardOption(id: 'ladder', labelBn: 'সঙ্গে সঙ্গে উদ্ধার', asset: 'assets/game/art/harness_board/rescue_ladder.svg', scene: true, correct: true),
        LearnBoardOption(id: 'run', labelBn: 'দৌড়ে উদ্ধারে যাওয়া', asset: 'assets/game/art/harness_board/rescue_run.svg', scene: true, correct: true),
        LearnBoardOption(
          id: 'tea',
          labelBn: 'চা খেয়ে তারপর',
          asset: 'assets/game/art/harness_board/rescue_tea.svg', scene: true,
          correct: false,
          rejectBn: 'ঝুলে থাকলে পায়ে রক্ত জমে — কয়েক মিনিটেই অজ্ঞান হতে পারেন।',
        ),
        LearnBoardOption(
          id: 'phone',
          labelBn: 'ফোন করে শুধু অপেক্ষা',
          asset: 'assets/game/art/harness_board/rescue_phone.svg', scene: true,
          correct: false,
          rejectBn: 'অপেক্ষার সময় নেই — দীর্ঘক্ষণ ঝুললে মস্তিষ্কে রক্ত কমে যায়, দ্রুত উদ্ধার চাই।',
        ),
        LearnBoardOption(
          id: 'watch',
          labelBn: 'নিচে দাঁড়িয়ে দেখা',
          asset: 'assets/game/art/harness_board/rescue_watch.svg', scene: true,
          correct: false,
          rejectBn: 'দাঁড়িয়ে দেখা নয় — কয়েক মিনিটেই প্রাণ যেতে পারে।',
        ),
      ],
      whyChips: [
        LearnWhyChip(id: 'w1', textBn: 'ঝুলে থাকলে কয়েক মিনিটেই অজ্ঞান হতে পারেন', correct: true),
        LearnWhyChip(id: 'w2', textBn: 'দ্রুত উদ্ধারের পরিকল্পনা আগে থেকেই চাই', correct: true),
        LearnWhyChip(id: 'w3', textBn: 'হারনেসে আটকে গেলে আর কোনো বিপদ নেই', correct: false),
        LearnWhyChip(id: 'w4', textBn: 'সে নিজেই একটু পরে ঠিকঠাক নেমে আসবে', correct: false),
        LearnWhyChip(id: 'w5', textBn: 'ঘণ্টাখানেক ঝুলে থাকলেও কিছু হয় না', correct: false),
        LearnWhyChip(id: 'w6', textBn: 'আগে অফিসে খবর দিই, উদ্ধার পরে হবে', correct: false),
        LearnWhyChip(id: 'w7', textBn: 'ঝুলে থাকা লোককে নিয়ে তাড়াহুড়োর কিছু নেই', correct: false),
      ],
    ),
  ],
  myth: LearnMythBeat(
    bodyAsset: 'assets/duty_slip/dress/myth_rival_bad.webp',
    tauntBn: learnBoardPack14Taunt,
    rivalLineBn: learnBoardPack14MythLine,
    exitBn: 'যত্তসব নতুন নিয়ম! আমি চললাম…',
    believeNoIsCorrect: true,
    stingBn: 'শুনলেন তো ওর কথা? সত্যি কি ওর এই বিপজ্জনক কথায় কান দেবেন?',
    dangerHints: [
      'গায়ে কোনো হারনেস নেই',
      'পড়লে থামানোর কিছুই নেই',
    ],
    whyChips: [
      LearnWhyChip(id: 'm1', textBn: 'মাধ্যাকর্ষণ অভিজ্ঞতাকে সম্মান করে না', correct: true),
      LearnWhyChip(id: 'm2', textBn: 'পিছলে বা ঝোড়ো হাওয়ায় যে কেউ পড়তে পারে', correct: true),
      LearnWhyChip(id: 'm3', textBn: 'হারনেসই পতনের পর একমাত্র দ্বিতীয় সুযোগ', correct: true),
      LearnWhyChip(id: 'm4', textBn: 'খুব সাবধানে থাকলে কেউ কখনো পড়ে না', correct: false),
      LearnWhyChip(id: 'm5', textBn: '20 বছরের অভিজ্ঞতাই আসল সুরক্ষা কবচ', correct: false),
      LearnWhyChip(id: 'm6', textBn: 'অভিজ্ঞ লোকের কথাই সবসময় ঠিক হয়', correct: false),
      LearnWhyChip(id: 'm7', textBn: 'হারনেস পরলে কাজ ধীর হয়, তাই বাদ দিই', correct: false),
      LearnWhyChip(id: 'm8', textBn: '20 বছরে কিছু হয়নি, তাই আর হবেও না', correct: false),
    ],
  ),
);

/// The careless lineman storms in with this (his recorded voice).
const learnBoardPack14Taunt = 'আরে! হারনেস-টারনেস ছাড়াই তো সারা জীবন পোলে উঠলাম!';

/// The careless lineman's myth (lesson 1.4 myth buster), in his recorded voice.
const learnBoardPack14MythLine = 'আমি 20 বছর ধরে কাজ করছি, খুব সাবধানে থাকি। আমার কখনো হারনেস লাগে না।';
