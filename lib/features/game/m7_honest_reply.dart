import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'choice_deck.dart';
import 'coworker_moment.dart';
import 'do_parts.dart';
import 'full_scene_frame.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm7_honest_reply_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm7_honest_reply_world.dart' show M7HonestGeo, M7Look, M7Mood, kM7Looks;

// Lesson 7.9 "গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব", কাজ 2 "সৎ জবাব"
// (pack do_7_9_b, engineType m7_honest_reply). A para lane at noon beside a
// pole-mounted transformer; the trainee has just changed a meter on a veranda
// (the old one in a bag, a 'জব শিট' on a nail). Three silent customers come
// one at a time, each with 2–3 caption bubbles held for a reading time; the
// player listens (a tile dropped while bubbles still come is interrupting,
// a slip), then builds a reply: two phrase tiles dragged onto the speech
// strip, then 'বলুন'. Only now does the customer react. Both tiles honest
// (one of two honest roles each: the plain fact and the next step; for the
// meter owner what was done and why) → he calms, the ◆ goes on the table and
// "কেন …?" follows. Any trap tile (false promise, brush-off, argument, a
// denied right) → his reaction and a slip card; the tiles are dealt again
// with other phrasings. The meter owner (always in the deal, 1st–3rd) is
// then given his job-sheet: drag the clipboard to him to sign, then 'চলুন';
// 'চলুন' with no signature is a slip.
//
// Deadly: none (owner M7-6: no deadly in 7.9). Slips (R26 confirmed, M7-6):
// interrupting, false promise, brush-off, arguing, denying a right, leaving
// without the job-sheet signature, listening to the coworker (his myth-2
// line: X2/B1, the act he pushes is a slip here). Three slips strike out.
//
// Built on the shared level kit: guide first, the full scene (m7_honest_
// reply_world.dart), corner guide; a right reply puts ◆ on the table → the
// reason deck at once; the coworker once a play at one dealt customer's
// 'বলুন' (the strip full; 'বলুন' waits for him: holdForCoworker). Gesture
// hands (how, never what): a sweep over the six tiles, then a nudge up from
// the tray's top edge; a tap on 'বলুন' once both slots are filled; a sweep
// over the job sheet and 'চলুন'. None while bubbles come.

// ============================================================================
// Content
// ============================================================================

/// The six situations (the meter owner is always one of the three).
enum M7Situation { transformer, bill, outage, complaint, connection, meter }

/// The four kinds of trap tile.
enum M7Trap { promise, brushOff, argue, denied }

/// What a reason asks about.
enum M7Why { reply, listen, promise, sheet }

/// The coworker's single push this level (lesson myth 2, word for word).
abstract final class M7HonestReplyLines {
  static const title = 'সৎ জবাব';
  // DRAFT wording — owner (M6-12).
  static const intro = 'পাড়ার লোক প্রশ্ন নিয়ে আসছেন — সত্যি কথা, শান্ত মাথায়।';

  // The guide's task now (tap him: the same task, a different way).
  static const askListen = 'আগে পুরো কথাটা শুনুন।';
  static const askAnswer = 'কথা শেষ। দুটো বাক্য সাজিয়ে জবাব দিন।';
  static const askSay = 'দুটো বাক্য সাজানো হলো — এবার বলুন।';
  static const askSheet = 'জব শিটে গ্রাহকের সই নিন, তারপর চলুন।';
  static const needTwo = 'আগে দুটো বাক্য সাজান।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static List<String> get tasks => [askListen, askAnswer, askSay, askSheet];

  // What a worker reads or says on the scene.
  static const say = 'বলুন';
  static const go = 'চলুন';
  static const sheetLabel = 'জব শিট';
  static const sceneLabel = 'পাড়ার রাস্তা';
  static const stripLabel = 'আপনার জবাব';
  static String customer(int n) => enDigits('গ্রাহক $n');

  /// Each customer's caption bubbles: two wordings per situation, 2–3
  /// bubbles each (silent: held for a reading time, never voiced).
  static const bubbles = <M7Situation, List<List<String>>>{
    M7Situation.transformer: [
      ['ট্রান্সফরমারটা তো খারাপ হয়ে গেছে।', 'তিন দিন ধরে বাড়িতে আলো নেই।', 'কবে বদলে দেবেন, বলুন?'],
      ['আমাদের পাড়ার ট্রান্সফরমার পুড়ে গেছে।', 'রান্না, পড়া, সব বন্ধ হয়ে আছে।'],
    ],
    M7Situation.bill: [
      ['এ মাসের বিলটা দেখুন, অনেক বেশি এসেছে।', 'আমরা তো এত বিদ্যুৎ পোড়াইনি।', 'ঠিক করে দেবেন তো?'],
      ['বিলে এত টাকা কেন, কিছুই বুঝছি না।', 'গত মাসে অর্ধেক এসেছিল।'],
    ],
    M7Situation.outage: [
      ['দিনে দশবার কারেন্ট চলে যায়!', 'ফ্যান, পাম্প, কিছুই চলে না।', 'এর কারণটা কী?'],
      ['রোজ সন্ধ্যায় বারবার কারেন্ট যায়।', 'ছেলেমেয়েরা পড়তে পারে না।'],
    ],
    M7Situation.complaint: [
      ['আমি নালিশ করব, ওপরে লিখে জানাব!', 'কতবার বলেছি, কেউ শোনে না।'],
      ['এবার আমি সোজা অভিযোগ করব।', 'আপনারা কাজই করেন না।', 'কে শুনবে আমার কথা?'],
    ],
    M7Situation.connection: [
      ['আমার নতুন দোকানের জন্য কারেন্ট চাই।', 'কী করতে হবে, কোথায় যাব?'],
      ['বাড়ির পেছনে নতুন ঘর তুলেছি।', 'সেখানে সংযোগ নিতে চাই।', 'কীভাবে আবেদন করব?'],
    ],
    M7Situation.meter: [
      ['আমার মিটার খুলে নিলেন কেন?', 'আগে তো কিছুই বলেননি।', 'পুরনো মিটারটা ব্যাগে কেন?'],
      ['বিনা খবরে মিটার বদলে দিলেন?', 'আমি জানব না, কী করলেন?'],
    ],
  };

  /// The two honest tiles: [0] the plain fact (for the meter owner: what was
  /// done), [1] the next step (for him: why). Two phrasings each.
  static const honest = <M7Situation, List<List<String>>>{
    M7Situation.transformer: [
      ['ট্রান্সফরমার বদলানো আমার হাতে নেই।', 'কবে বদলাবে, তা আমি নিজে জানি না।'],
      ['বিষয়টা ঊর্ধ্বতন কর্তৃপক্ষকে জানাব।', 'আপনার কথা আমি ওপরে জানিয়ে দেব।'],
    ],
    M7Situation.bill: [
      ['বিলের হিসেব আমার কাছে এখন নেই।', 'বিল ঠিক কি ভুল, এখনই বলতে পারছি না।'],
      ['আপনার অভিযোগটা আমি লিখে নিচ্ছি।', 'লিখে নিলাম, অফিসে জানিয়ে দেব।'],
    ],
    M7Situation.outage: [
      ['কেন যাচ্ছে, কারণটা আমার এখন অজানা।', 'খুঁজে না দেখে কারণ বলতে পারব না।'],
      ['সমস্যাটা লিখে ওপরে জানিয়ে দেব।', 'অভিযোগটা নথিভুক্ত করে জানাব ওপরে।'],
    ],
    M7Situation.complaint: [
      ['অভিযোগ জানানোর অধিকার আপনার আছে।', 'নালিশ করা আপনার ন্যায্য অধিকার।'],
      ['আমি এখনই অভিযোগটা লিখে নিচ্ছি।', 'লিখে নিলাম, দ্রুত সমাধান চাইব।'],
    ],
    M7Situation.connection: [
      ['নতুন সংযোগের আবেদন করতে পারেন।', 'আবেদন করা আপনার ন্যায্য অধিকার।'],
      ['কীভাবে আবেদন হয়, আমি বলে দিচ্ছি।', 'আবেদনের নিয়মটা আমি বুঝিয়ে বলছি।'],
    ],
    M7Situation.meter: [
      ['আপনার মিটারটা আমি বদলে দিয়েছি।', 'পুরনো মিটার খুলে নতুনটা লাগিয়েছি।'],
      ['ঠিকঠাক রিডিংয়ের জন্য বদলাতে হয়।', 'সঠিক মাপের জন্যই এই বদল করা হলো।'],
    ],
  };

  /// The trap tiles: per situation and kind, two phrasings.
  static const traps = <M7Situation, Map<M7Trap, List<String>>>{
    M7Situation.transformer: {
      M7Trap.promise: ['কালকের মধ্যেই বদলে দেব, চিন্তা নেই।', 'দু-একদিনেই নতুন ট্রান্সফরমার বসবে।'],
      M7Trap.brushOff: ['ওসব আমার দেখার বিষয় নয়, দাদা।', 'আমাকে বলে কী হবে, অন্য জায়গায় বলুন।'],
      M7Trap.argue: ['আপনি ভুল বলছেন, আমরা ঠিকই করেছি।', 'দোষটা আমাদের নয়, আগে শুনুন তো!'],
      M7Trap.denied: ['এসব নিয়ে অভিযোগ লেখার নিয়ম নেই।', 'এ নিয়ে অভিযোগ করার অধিকার নেই।'],
    },
    M7Situation.bill: {
      M7Trap.promise: ['বিল কালই ঠিক হয়ে যাবে, চিন্তা নেই।', 'টাকা ফেরত পাবেনই, আমি কথা দিচ্ছি।'],
      M7Trap.brushOff: ['বিলের ব্যাপার আমার নয়, অফিসে যান।', 'ওসব বিল-টিল আমি দেখি না, ভাই, যান।'],
      M7Trap.argue: ['বিল ঠিকই এসেছে, ভুলটা আপনারই, মানুন।', 'বেশি খরচ করেছেন আপনিই, মেনে নিন।'],
      M7Trap.denied: ['বিল নিয়ে নালিশ এখানে চলে না, ভাই।', 'বিলের অভিযোগ জানানোর অধিকার নেই।'],
    },
    M7Situation.outage: {
      M7Trap.promise: ['আজ থেকে আর একবারও কারেন্ট যাবে না।', 'কাল সকালের মধ্যেই সব ঠিক হয়ে যাবে।'],
      M7Trap.brushOff: ['কারেন্ট যায় তো আমি কী করব, ভাই?', 'আমার ব্যাপার নয়, অফিসে ফোন করুন।'],
      M7Trap.argue: ['কই, আমি তো যেতে দেখিনি! ভুল বলছেন।', 'সবার বাড়িতেই যায়, নতুন কিছু নয়।'],
      M7Trap.denied: ['কারেন্টের অভিযোগ নেওয়ার নিয়ম নেই।', 'কারেন্ট নিয়ে নালিশ করা যায় না।'],
    },
    M7Situation.complaint: {
      M7Trap.promise: ['নালিশ ছাড়ুন, কালই সব ঠিক করে দেব।', 'কথা দিচ্ছি, আজই সমাধান হয়ে যাবে।'],
      M7Trap.brushOff: ['যা পারেন করুন, আমার কিছু যায় আসে না।', 'আমাকে ভয় দেখিয়ে লাভ নেই, যান।'],
      M7Trap.argue: ['নালিশ করার মতো কিছু হয়নি, আপনি ভুল।', 'আপনার কথাটাই ভুল, সেটা মানতে হবে।'],
      M7Trap.denied: ['নালিশ নেওয়া হবে না, নিয়ম নেই।', 'অভিযোগ নথিভুক্ত করা যায় না, ভাই।'],
    },
    M7Situation.connection: {
      M7Trap.promise: ['আবেদন করুন, কালই সংযোগ পেয়ে যাবেন।', 'সাত দিনে লাইন বসে যাবে, কথা দিলাম।'],
      M7Trap.brushOff: ['এসব অফিসের কাজ, আমি কিছু জানি না।', 'সংযোগ নিয়ে আমাকে বিরক্ত করবেন না।'],
      M7Trap.argue: ['আপনার তো সংযোগ পাওয়ার কথাই নয়।', 'এখানে সংযোগ হয় না, আপনি ভুল বলছেন।'],
      M7Trap.denied: ['নতুন সংযোগের আবেদন নেওয়া হয় না।', 'আপনি আবেদন করতেই পারেন না, বুঝলেন?'],
    },
    M7Situation.meter: {
      M7Trap.promise: ['এ মিটারে বিল অর্ধেক হয়ে যাবে, দেখবেন।', 'আর কোনোদিন বিল বেশি আসবে না, দেখবেন।'],
      M7Trap.brushOff: ['মিটার নিয়ে আপনাকে বলার কিছু নেই।', 'ওসব আপনি বুঝবেন না, কাজ করতে দিন।'],
      M7Trap.argue: ['আমার কাজে ভুল ধরবেন না, ঠিকই করেছি।', 'আমি ঠিক, আপনি ভুল ভাবছেন, ব্যস।'],
      M7Trap.denied: ['মিটার খোলার কারণ জানার অধিকার নেই।', 'এই কাজে আপনার কিছু জানার নেই, যান।'],
    },
  };

  /// The customer's reaction (a caption bubble, silent), after 'বলুন'.
  static const calmReaction = ['ঠিক আছে, এবার বুঝলাম।', 'আচ্ছা, তাহলে তো ঠিকই আছে।', 'ধন্যবাদ, সত্যিটা বললেন।'];
  static const trapReaction = <M7Trap, String>{
    M7Trap.promise: 'তাহলে কালই হয়ে যাবে তো? কথা দিলেন কিন্তু!',
    M7Trap.brushOff: 'তাহলে আমি কার কাছে যাব?',
    M7Trap.argue: 'আমি মিথ্যে বলছি? এভাবে কথা বলছেন?',
    M7Trap.denied: 'আমার কোনো অধিকারই নেই তাহলে?',
  };
  static const interruptReaction = 'আমার কথা তো শেষই হয়নি!';
  static const signedReaction = 'এই নিন, সই করে দিলাম।';

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses (all about the same length).
  static const whyQ = <M7Why, String>{
    M7Why.reply: 'কেন এই জবাব দিলেন?',
    M7Why.listen: 'কেন আগে পুরো কথা শুনলেন?',
    M7Why.promise: 'কেন কথা দিলেন না?',
    M7Why.sheet: 'কেন জব শিটে সই নিলেন?',
  };
  static const whyRight = <M7Why, List<String>>{
    M7Why.reply: ['সত্যি কথা বলাই গ্রাহকের প্রতি আমার দায়িত্ব', 'সঠিক তথ্য দিলে গ্রাহক কোম্পানিকে ভরসা করেন'],
    M7Why.listen: ['শান্ত হয়ে শুনলে গ্রাহক বোঝেন, মেটাতেই এসেছি', 'পুরো কথা না শুনলে সমস্যাটাই ঠিক বোঝা যায় না'],
    M7Why.promise: ['যা আমার হাতে নেই, তাতে মিথ্যা কথা দেব না', 'সমাধান ওপরের হাতে, আমি শুধু জানাতে পারি'],
    M7Why.sheet: ['সই-সহ জব শিটই আমার কাজের প্রমাণ হয়ে থাকে', 'মিটার বদলের মতো বড় কাজে সই নিয়ে শিট ভরতে হয়'],
  };
  static const myths = [
    'গ্রাহক কিছু বোঝেন না, যা-খুশি বললেই চলে',
    'কথা দিয়ে দিলে গ্রাহক তখনকার মতো শান্ত হন',
    'তর্কে জিতলে গ্রাহক আর অভিযোগ করবেন না',
    'অভিযোগ নিলে কাজ বাড়ে, তাই এড়িয়ে যাওয়া ভালো',
    'জব শিট শুধু অফিসের কাগজ, সই ছাড়াও চলে',
    'কথা শেষ হওয়ার আগেই জবাব দিয়ে দেওয়া ভালো',
    'ঝামেলা এড়াতে অধিকারের কথাটা না বলাই ভালো',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, at one dealt customer's 'বলুন').
  // His line is lesson myth 2 word for word (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerMyth = CoworkerScript(
    line: 'গ্রাহক তো কিছুই বোঝেন না, তাকে যা-খুশি বুঝিয়ে দিলেই হলো।',
    exitLine: coworkerExit,
    right: ['না, সঠিক তথ্য দেওয়াই আমার দায়িত্ব', 'না, সততাই কোম্পানির সম্মান বাড়ায়', 'না, সহজ ভাষায় সত্যিটাই বুঝিয়ে বলব'],
    wrong: [
      'ঠিক, যা হোক একটা কিছু বুঝিয়ে দিই',
      'ঠিকই বলেছ, উনি কিছুই বুঝবেন না',
      'হ্যাঁ, যা-খুশি বলে মিটিয়ে দিই',
      'ঠিক আছে, তাড়াতাড়ি সামলে দিই',
      'আচ্ছা, অত সত্যি বলার দরকার নেই',
    ],
    asks: ['কী করবেন?', 'সাথীর কথা শুনবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const allCoworkers = [coworkerMyth];
  static const callHeld = 'ঠিক! সঠিক আর স্বচ্ছ তথ্য দেওয়াই আমাদের দায়িত্ব।';

  static const allSet = 'তিন গ্রাহকই খুশি — সত্যি কথা, শান্ত মাথায়!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে শুনুন, তারপর সত্যি আর সঠিক কথা বলুন।';

  // "আজ যা ধরলেন".
  static const caughtListen = 'আগে পুরো কথা শুনেছেন';
  static const caughtHonest = 'কথা না দিয়ে সত্যিটা বলেছেন';
  static const caughtExplain = 'কাজ আর কারণ বুঝিয়েছেন';
  static const caughtSheet = 'জব শিটে সই নিয়েছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new push (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        needTwo,
        ...tapWhy,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        callHeld,
        allSet,
        fail,
        for (final m in M7HonestReplyMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M7HonestReplyMistakes {
  static const _dir = 'assets/game/art/m7_honest_reply';

  // DRAFT wording — owner (M6-12). No deadly mistake in 7.9 (M7-6).
  static const interrupt = DoMistake(
    key: '7.9/m7_honest_reply/interrupt',
    textBn: 'গ্রাহকের কথা শেষ হওয়ার আগে জবাব সাজাবেন না। শান্তভাবে পুরোটা শুনুন, তারপর বলুন।',
    art: '$_dir/interrupt.svg',
    lessonPoint: 2,
  );
  static const falsePromise = DoMistake(
    key: '7.9/m7_honest_reply/false-promise',
    textBn: 'যে কাজ আপনার হাতে নেই, তাতে কথা দেবেন না। সঠিক তথ্য দিন আর বলুন যে ঊর্ধ্বতন কর্তৃপক্ষকে জানাবেন।',
    art: '$_dir/false_promise.svg',
  );
  static const brushOff = DoMistake(
    key: '7.9/m7_honest_reply/brush-off',
    textBn: 'গ্রাহকের কথা ঝেড়ে ফেলবেন না। অভিযোগ নথিভুক্ত করানো আর দ্রুত সমাধান পাওয়া তাঁর অধিকার।',
    art: '$_dir/brush_off.svg',
    lessonPoint: 0,
  );
  static const arguing = DoMistake(
    key: '7.9/m7_honest_reply/arguing',
    textBn: 'রাগী গ্রাহকের সঙ্গে তর্ক নয়। শান্তভাবে কথা শুনুন আর বোঝান যে সমস্যা মেটাতেই এসেছেন।',
    art: '$_dir/arguing.svg',
    lessonPoint: 2,
  );
  static const deniedRight = DoMistake(
    key: '7.9/m7_honest_reply/denied-right',
    textBn: 'অভিযোগ করা, ঠিক বিল পাওয়া, নতুন সংযোগ চাওয়া — সবই গ্রাহকের অধিকার। কোনো অধিকার অস্বীকার করবেন না।',
    art: '$_dir/denied_right.svg',
    lessonPoint: 0,
  );
  static const noSignature = DoMistake(
    key: '7.9/m7_honest_reply/no-signature',
    textBn: 'মিটার বদলের পর গ্রাহকের সই-সহ জব শিট ভরুন — সেটাই আপনার কাজের প্রমাণ। সই না নিয়ে যাবেন না।',
    art: '$_dir/no_signature.svg',
  );
  // Lesson 7.9 myth 2 and its reality (not a numbered point).
  static const listenMyth = DoMistake(
    key: '7.9/m7_honest_reply/listen-myth',
    textBn: '“গ্রাহক কিছুই বোঝেন না” — এটা ভুল মনোভাব। সঠিক আর স্বচ্ছ তথ্য দেওয়াই আপনার দায়িত্ব।',
    art: '$_dir/listen_myth.svg',
  );

  static DoMistake forTrap(M7Trap t) => switch (t) {
        M7Trap.promise => falsePromise,
        M7Trap.brushOff => brushOff,
        M7Trap.argue => arguing,
        M7Trap.denied => deniedRight,
      };

  static const List<DoMistake> all = [interrupt, falsePromise, brushOff, arguing, deniedRight, noSignature, listenMyth];
}

/// One phrase tile.
@immutable
class M7Tile {
  const M7Tile({required this.text, required this.honest, this.trap, this.role = 0});
  final String text;
  final bool honest;

  /// Which trap it is (null for an honest tile).
  final M7Trap? trap;

  /// Honest tiles: 0 the plain fact (meter: what), 1 the next step (meter: why).
  final int role;

  @override
  bool operator ==(Object other) => other is M7Tile && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// The six tiles of an answer: the two honest ones (one of each role) and one
/// trap of each kind, each in one of its two phrasings (changing with
/// [attempt], so a re-deal never repeats the wording), in a shuffled order.
List<M7Tile> m7DealTiles(M7Situation s, int attempt, math.Random rng, {int? base0}) {
  final tiles = <M7Tile>[];
  final base = base0 ?? rng.nextInt(2);
  final honest = M7HonestReplyLines.honest[s]!;
  for (var r = 0; r < 2; r++) {
    tiles.add(M7Tile(text: honest[r][(base + attempt + r) % 2], honest: true, role: r));
  }
  for (final (i, t) in M7Trap.values.indexed) {
    final lib = M7HonestReplyLines.traps[s]![t]!;
    tiles.add(M7Tile(text: lib[(base + attempt + i) % 2], honest: false, trap: t));
  }
  return tiles..shuffle(rng);
}

/// One dealt customer.
@immutable
class M7Customer {
  const M7Customer({required this.situation, required this.look, required this.right, required this.wording});
  final M7Situation situation;

  /// Index into [kM7Looks].
  final int look;

  /// Stands to the right in the lane (else left).
  final bool right;

  /// Which of the two bubble wordings.
  final int wording;

  bool get owner => situation == M7Situation.meter;
  List<String> get bubbles => M7HonestReplyLines.bubbles[situation]![wording];
}

@immutable
class M7HonestDeal {
  const M7HonestDeal({required this.customers, required this.coworkerAt, required this.why});
  final List<M7Customer> customers;

  /// The customer at whose 'বলুন' he comes in.
  final int coworkerAt;

  /// What each customer's reason asks about (fits what was done).
  final List<M7Why> why;
}

/// Situations where "why did you not promise?" fits.
bool m7PromiseFits(M7Situation s) => s == M7Situation.transformer || s == M7Situation.outage || s == M7Situation.connection || s == M7Situation.bill;

M7HonestDeal m7HonestDeal(math.Random rng) {
  final others = [for (final s in M7Situation.values) if (s != M7Situation.meter) s]..shuffle(rng);
  final ownerAt = rng.nextInt(3);
  final sits = <M7Situation>[];
  var o = 0;
  for (var i = 0; i < 3; i++) {
    sits.add(i == ownerAt ? M7Situation.meter : others[o++]);
  }
  final looks = [for (var i = 0; i < kM7Looks.length; i++) i]..shuffle(rng);
  final customers = [
    for (final (i, s) in sits.indexed) M7Customer(situation: s, look: looks[i], right: rng.nextBool(), wording: rng.nextInt(2)),
  ];
  final why = <M7Why>[
    for (final c in customers)
      if (c.owner)
        M7Why.reply
      else if (m7PromiseFits(c.situation) && rng.nextBool())
        M7Why.promise
      else
        rng.nextBool() ? M7Why.listen : M7Why.reply,
  ];
  return M7HonestDeal(customers: customers, coworkerAt: rng.nextInt(3), why: why);
}

/// Where a customer round stands.
enum M7Phase { arriving, listening, stopped, said, sheet, done }

/// What a drop of a tile on the strip did.
@immutable
class M7Drop {
  const M7Drop({this.placed = false, this.mistake});
  final bool placed;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class M7HonestRun {
  M7HonestRun(this.deal, {math.Random? rng}) : _rng = rng ?? math.Random(1) {
    _startCustomer();
  }
  final M7HonestDeal deal;
  final math.Random _rng;

  int index = 0;
  int slips = 0;
  int customerSlips = 0;
  final List<String> caught = [];
  M7Phase phase = M7Phase.arriving;

  /// How many bubbles have been shown (the customer's words so far).
  int bubblesShown = 0;
  final List<M7Tile?> slots = [null, null];
  List<M7Tile> tray = const [];
  int attempt = 0;
  var sheetSigned = false;

  /// Which phrasing the first deal used (a re-deal flips every tile).
  int _base = 0;

  /// This customer: a trap slipped / the player interrupted.
  final Set<M7Trap> trapped = {};
  var interruptedHere = false;
  var interruptedEver = false;

  M7Customer get customer => deal.customers[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => customerSlips == 0;
  bool get stripFull => slots[0] != null && slots[1] != null;

  /// More bubbles are to come: a tile dropped now is interrupting.
  bool get bubblesComing => phase == M7Phase.listening;

  /// The round's reply is judged right (its reason follows) / the sheet is done.
  bool get roundDone => phase == M7Phase.said || phase == M7Phase.done;

  void _startCustomer() {
    phase = M7Phase.arriving;
    bubblesShown = 0;
    attempt = 0;
    sheetSigned = false;
    trapped.clear();
    interruptedHere = false;
    customerSlips = 0;
    slots[0] = slots[1] = null;
    _base = _rng.nextInt(2);
    tray = m7DealTiles(customer.situation, 0, _rng, base0: _base);
  }

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    customerSlips++;
    return m;
  }

  /// He has walked up: the first bubble comes.
  void startListening() {
    if (phase == M7Phase.arriving) phase = M7Phase.listening;
  }

  void showBubble(int i) {
    if (phase == M7Phase.listening) bubblesShown = i + 1;
  }

  /// The last bubble was held: he has said it all.
  void stopListening() {
    if (phase == M7Phase.listening) phase = M7Phase.stopped;
  }

  /// A tile dropped on a slot of the strip. While he walks up: ignored. While
  /// bubbles still come: interrupting (a slip; the tile stays in the tray).
  M7Drop drop(M7Tile t, int slot) {
    if (phase == M7Phase.arriving) return const M7Drop();
    if (phase == M7Phase.listening) {
      interruptedHere = true;
      interruptedEver = true;
      return M7Drop(mistake: _slip(M7HonestReplyMistakes.interrupt));
    }
    if (phase != M7Phase.stopped || slots[slot] != null || slots.contains(t)) return const M7Drop();
    slots[slot] = t;
    return const M7Drop(placed: true);
  }

  /// A tile taken off the strip, back to the tray.
  bool remove(int slot) {
    if (phase != M7Phase.stopped || slots[slot] == null) return false;
    slots[slot] = null;
    return true;
  }

  /// 'বলুন': both honest → he calms (the round's reply is done); any trap →
  /// that trap's slip, the strip cleared and the tiles dealt again in other
  /// phrasings. [ready] false: the strip is not full, nothing happens.
  ({bool ready, DoMistake? mistake, M7Trap? trap}) sayIt() {
    if (phase != M7Phase.stopped || !stripFull) return (ready: false, mistake: null, trap: null);
    final bad = slots.firstWhere((t) => !t!.honest, orElse: () => null);
    if (bad == null) {
      phase = M7Phase.said;
      _tag(M7HonestReplyLines.caughtHonest);
      if (customer.owner) _tag(M7HonestReplyLines.caughtExplain);
      if (!interruptedEver) _tag(M7HonestReplyLines.caughtListen);
      return (ready: true, mistake: null, trap: null);
    }
    final trap = bad.trap!;
    trapped.add(trap);
    final m = _slip(M7HonestReplyMistakes.forTrap(trap));
    attempt++;
    slots[0] = slots[1] = null;
    tray = m7DealTiles(customer.situation, attempt, _rng, base0: _base);
    return (ready: true, mistake: m, trap: trap);
  }

  /// After the owner's reason: his job sheet.
  void toSheet() {
    if (phase == M7Phase.said && customer.owner) phase = M7Phase.sheet;
  }

  /// The job sheet dragged to him: he signs.
  bool giveSheet() {
    if (phase != M7Phase.sheet || sheetSigned) return false;
    sheetSigned = true;
    return true;
  }

  /// 'চলুন': with no signature a slip (the sheet is still to be signed).
  DoMistake? leave() {
    if (phase != M7Phase.sheet) return null;
    if (!sheetSigned) return _slip(M7HonestReplyMistakes.noSignature);
    phase = M7Phase.done;
    _tag(M7HonestReplyLines.caughtSheet);
    return null;
  }

  /// Listened to the coworker (his myth-2 line: a slip here).
  DoMistake pushSlip() => _slip(M7HonestReplyMistakes.listenMyth);

  void next() {
    index++;
    if (!done) _startCustomer();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, bubbles held for their reading time (~2–3 s each):
///   a customer: walk-up ≈ 900, 2–3 bubbles ≈ 7000, two tiles + বলুন ≈ 4500
///     + a reason ≈ 8200                                      ≈ 20600 × 3
///   the meter owner: + the sheet ≈ 3000 and a second reason ≈ 8200
///   + the coworker once ≈ 9600                               ≈ 82000
/// 85 % ≈ 70000 (a builder's estimate; owner may tune).
const m7HonestReplyQuickMs = 70000;

@immutable
class M7HonestReplyPack {
  const M7HonestReplyPack({required this.id, required this.titleBn, this.quickMs = m7HonestReplyQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7HonestReplyPack> m7HonestReplyPacks = {
  'do_7_9_b': M7HonestReplyPack(id: 'do_7_9_b', titleBn: M7HonestReplyLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7HonestReplyProbe {
  static M7HonestRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7HonestReplyPage extends StatefulWidget {
  const M7HonestReplyPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7HonestReplyPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7HonestReplyPage> createState() => _M7HonestReplyPageState();
}

class _M7HonestReplyPageState extends State<M7HonestReplyPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _HonestRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _HonestRunPage extends ConsumerStatefulWidget {
  const _HonestRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7HonestReplyPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HonestRunPage> createState() => _HonestRunPageState();
}

class _HonestRunPageState extends ConsumerState<_HonestRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7HonestRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  int _bubbleTok = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  /// What the customer's bubble shows now (his words, or his reaction).
  String? _bubble;
  var _mood = M7Mood.waiting;
  var _dragging = false;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _trayKey = GlobalKey();
  final _sayKey = GlobalKey();
  final _sheetKey = GlobalKey();
  final _goKey = GlobalKey();
  final List<GlobalKey> _tileKeys = [for (var i = 0; i < 6; i++) GlobalKey()];
  int _hintN = 0;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _run = M7HonestRun(m7HonestDeal(widget.rng), rng: widget.rng);
    M7HonestReplyProbe.run = _run;
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _bubbleTok++;
    if (identical(M7HonestReplyProbe.run, _run)) M7HonestReplyProbe.run = null;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk}) async {
    if (line.trim().isEmpty || !mounted) return;
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line);
    await MascotSpeechLibrary.speak(line, muted: _muted);
  }

  Future<void> _sayChain(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    final chain = ++_chain;
    for (final l in lines) {
      if (!mounted || chain != _chain) return;
      await _say(l, mood: mood);
    }
  }

  void _hush() {
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
  }

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  M7Customer get _cust => _run.customer;

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen;

  String get _task => switch (_run.phase) {
        M7Phase.arriving || M7Phase.listening => M7HonestReplyLines.askListen,
        M7Phase.stopped => _run.stripFull ? M7HonestReplyLines.askSay : M7HonestReplyLines.askAnswer,
        _ => M7HonestReplyLines.askSheet,
      };

  Future<void> _start() async {
    _clock.start();
    _startCustomer();
  }

  /// A customer walks up; his bubbles come one at a time, each held for a
  /// reading time (paused while a card or the coworker is up).
  void _startCustomer() {
    setState(() {
      _wake++;
      _mood = M7Mood.waiting;
      _bubble = null;
      _dragging = false;
    });
    unawaited(_sayChain([M7HonestReplyLines.askListen]));
    unawaited(_bubbles(++_bubbleTok));
  }

  bool get _blocked => _card != null || coworkerOpen || reasonOpen || tableBusy || _intro;

  Future<bool> _wait(int tok, int ms) async {
    var acc = 0;
    while (acc < ms) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || tok != _bubbleTok || _ended) return false;
      if (_blocked) continue;
      acc += 100;
    }
    return true;
  }

  Future<void> _bubbles(int tok) async {
    if (!await _wait(tok, _quiet ? 300 : 900)) return;
    _run.startListening();
    final lines = _cust.bubbles;
    for (var i = 0; i < lines.length; i++) {
      if (!mounted || tok != _bubbleTok) return;
      setState(() {
        _run.showBubble(i);
        _bubble = lines[i];
        _wake++;
      });
      final hold = MascotSpeechLibrary.readHold(lines[i]).inMilliseconds;
      if (!await _wait(tok, hold + 500)) return;
    }
    _run.stopListening();
    if (!mounted) return;
    setState(() => _steps++);
    if (_run.index == _run.deal.coworkerAt && !coworkerDone && !coworkerDue) scheduleCoworker();
    unawaited(_sayChain([M7HonestReplyLines.askAnswer]));
  }

  /// The coworker's customer: 'বলুন' waits for him once he is due.
  bool _waitForHim() => _run.index == _run.deal.coworkerAt && holdForCoworker();

  // --- hands on -----------------------------------------------------------------
  void _tapScene() {
    if (!_canPlay) return;
    _hints.missTap();
  }

  /// A tile dropped on a slot.
  void _drop(M7Tile t, int slot, Offset at) {
    _dragging = false;
    if (!_canPlay) return;
    final d = _run.drop(t, slot);
    if (d.mistake != null) {
      setState(() {
        _bubble = M7HonestReplyLines.interruptReaction;
        _mood = M7Mood.upset;
        _wake++;
      });
      unawaited(_mistake(d.mistake!, at));
      return;
    }
    if (!d.placed) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _steps++);
    if (_run.stripFull) unawaited(_sayChain([M7HonestReplyLines.askSay]));
  }

  void _unplace(int slot) {
    if (!_canPlay) return;
    if (_run.remove(slot)) {
      _tick();
      setState(() => _steps++);
    }
  }

  void _sayTap(Offset at) {
    if (!_canPlay) return;
    if (!_run.stripFull) {
      if (_run.phase == M7Phase.stopped) {
        _tick();
        unawaited(_sayChain([M7HonestReplyLines.needTwo]));
      } else {
        _hints.missTap();
      }
      return;
    }
    if (_waitForHim()) return;
    final r = _run.sayIt();
    if (!r.ready) return;
    _tick('sounds/intro/click.ogg', 0.6);
    if (r.mistake == null) {
      setState(() {
        _mood = M7Mood.calm;
        _bubble = M7HonestReplyLines.calmReaction[widget.rng.nextInt(M7HonestReplyLines.calmReaction.length)];
        _wake++;
      });
      unawaited(_replyDone());
      return;
    }
    setState(() {
      _mood = M7Mood.upset;
      _bubble = M7HonestReplyLines.trapReaction[r.trap!];
      _wake++;
    });
    unawaited(_mistake(r.mistake!, at));
  }

  Future<void> _replyDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final dealt = _run.deal.why[_run.index];
    // "Why listen first?" would not fit a play that interrupted; "why no
    // promise?" would not fit one that fell for the promise tile.
    final topic = switch (dealt) {
      M7Why.listen when _run.interruptedHere => M7Why.reply,
      M7Why.promise when _run.trapped.contains(M7Trap.promise) => M7Why.reply,
      _ => dealt,
    };
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M7HonestReplyLines.whyRight[topic]!, M7HonestReplyLines.myths, widget.rng),
      question: M7HonestReplyLines.whyQ[topic]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  /// The job sheet dragged to the owner: he signs.
  void _sheetGiven(Offset at) {
    if (!_canPlay) return;
    if (!_run.giveSheet()) return;
    _tick('sounds/learn/tag_slap.ogg', 0.6);
    setState(() {
      _mood = M7Mood.calm;
      _bubble = M7HonestReplyLines.signedReaction;
      _steps++;
      _wake++;
    });
    unawaited(_levelDelta(5, at, mood: GuideMood.glad));
  }

  void _goTap(Offset at) {
    if (!_canPlay || _run.phase != M7Phase.sheet) return;
    final m = _run.leave();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, at));
      return;
    }
    _tick('sounds/intro/click.ogg', 0.6);
    setState(() => _steps++);
    unawaited(_sheetDone());
  }

  Future<void> _sheetDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    putOnTable(10);
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M7HonestReplyLines.whyRight[M7Why.sheet]!, M7HonestReplyLines.myths, widget.rng),
      question: M7HonestReplyLines.whyQ[M7Why.sheet]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    _bubbleTok++;
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startCustomer();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  // --- the shared success beat (ReasonTable) ---------------------------------
  @override
  bool get reasonMuted => _muted;
  @override
  bool get reasonEnded => _ended;
  @override
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void reasonHush() => _hush();
  @override
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood}) => _levelDelta(delta, origin, mood: mood);
  @override
  void onReasonPaid() {
    final idx = _run.index;
    final first = _run.phase == M7Phase.said;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (!mounted || _ended || _run.index != idx) return;
      if (first && _run.customer.owner) {
        // The meter owner: now his job sheet.
        setState(() {
          _run.toSheet();
          _steps++;
          _wake++;
        });
        unawaited(_sayChain([M7HonestReplyLines.askSheet]));
        return;
      }
      _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M7HonestReplyLines.coworkerMyth;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerAt || _run.phase.index >= M7Phase.said.index) return null;
    if (_intro || _card != null || tableBusy || _dragging || _run.phase != M7Phase.stopped || !_run.stripFull) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.pushSlip();
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7HonestReplyLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7HonestReplyLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7HonestReplyLines.tapWhy[_nudgeN++ % M7HonestReplyLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7honest/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    // The same customer goes on from where he was (a fresh deal of tiles
    // after a trap; the bubbles carry on after an interruption).
    _hush();
    setState(() {
      _card = null;
      _mood = M7Mood.waiting;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _finish() async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    final save = ref.read(gameSaveProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final centre = Offset(size.width / 2, size.height * 0.45);
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M7HonestReplyLines.fail : (_quickBonus ? M7HonestReplyLines.quick : M7HonestReplyLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (deathPending) {
      if (_popped) return;
      _popped = true;
      await dieAndLeave();
      return;
    }
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    return LinemanMode.idle;
  }

  /// The gesture hand: how to touch, never what. Tiles waiting: a sweep over
  /// the six tiles, next idle a nudge up from the tray's top edge (a generic
  /// way, not at a slot); the strip full: a tap on 'বলুন' (the one way on);
  /// the job sheet: a sweep over the clipboard and 'চলুন'. None while the
  /// customer's bubbles still come.
  HintSpec? _hint() {
    final n = _hintN++;
    switch (_run.phase) {
      case M7Phase.stopped:
        if (_run.stripFull) return HintSpec.tapOn(_sayKey);
        if (n.isEven) {
          final keys = [for (var i = 0; i < _run.tray.length; i++) if (!_run.slots.contains(_run.tray[i])) _tileKeys[i]];
          return HintSpec.sweepOver(keys);
        }
        final r = HintSpec.globalRectOf(_trayKey);
        return r == null ? null : HintSpec.drag(Offset(r.center.dx, r.top + 8), toward: const Offset(0, -1), travel: 56);
      case M7Phase.sheet:
        return HintSpec.sweepOver([_sheetKey, _goKey]);
      default:
        return null;
    }
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M7HonestGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final c = _cust;
    final box = geo.customer(c.right);
    final sheetLive = _run.phase == M7Phase.sheet && !_run.sheetSigned;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: RepaintBoundary(child: CustomPaint(painter: M7HonestWorldPainter(geo: geo))),
      ),
      // A tap on the lane that is nothing (a miss, for the hint).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7HonestReplyLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tapScene),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      // The customer: he walks up from the lane's edge, then stands.
      Positioned.fromRect(
        key: ValueKey('customer-${_run.index}'),
        rect: box,
        child: DragTarget<String>(
          onWillAcceptWithDetails: (_) => sheetLive && _canPlay,
          onAcceptWithDetails: (d) => _sheetGiven(d.offset),
          builder: (_, _, _) => IgnorePointer(
            child: _CustomerFigure(
              key: ValueKey('figure-${_run.index}'),
              look: kM7Looks[c.look],
              mood: _mood,
              faceLeft: !c.right,
              fromRight: c.right,
              quiet: quiet,
            ),
          ),
        ),
      ),
      if (_bubble != null && !_intro)
        Positioned.fromRect(
          key: const ValueKey('bubble-box'),
          rect: geo.bubble,
          child: IgnorePointer(child: _CaptionBubble(key: ValueKey('bubble-${_run.index}-$_bubble'), text: _bubble!, quiet: quiet, tailX: (box.center.dx - geo.bubble.left).clamp(24.0, 212.0))),
        ),
      // The job sheet on its nail: a prop all play; dragged only when its turn comes.
      Positioned.fromRect(
        key: const ValueKey('sheet-box'),
        rect: geo.sheet,
        child: _JobSheet(
          key: _sheetKey,
          signed: _run.sheetSigned,
          live: sheetLive && _canPlay,
          onTapped: _tapScene,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final sheetPhase = _run.phase == M7Phase.sheet;
    final handsOn = playing && _card == null && !deckUp && !coworkerOpen && !tableBusy;
    final tilesOn = handsOn && (_run.phase == M7Phase.listening || _run.phase == M7Phase.stopped || _run.phase == M7Phase.arriving);
    final hintOn = handsOn && (_run.phase == M7Phase.stopped || sheetPhase);
    final tileW = (size.width - 16 - 8) / 2;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        body: ScoreFlyHost(
          scoreKey: _scoreKey,
          child: FullSceneFrame(
            ctx: widget.ctx,
            titleBn: widget.pack.titleBn,
            scoreKey: _scoreKey,
            levelScore: _runScore,
            muted: _muted,
            onClose: () => unawaited(_leave()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            progress: DoProgress(
              labels: [for (var i = 0; i < 3; i++) M7HonestReplyLines.customer(i + 1)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintOn,
            hintKey: '${_run.index}/${_run.phase.name}/$_steps/${_run.attempt}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && !sheetPhase && !_run.roundDone && !deckUp && !_run.done) ...[
                // The speech strip: two slots and 'বলুন'.
                Positioned(
                  key: ValueKey('hud-strip-${_run.index}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 6 + _trayH + 8,
                  child: _Strip(
                    slots: _run.slots,
                    canDrop: tilesOn && _card == null,
                    full: _run.stripFull,
                    sayKey: _sayKey,
                    onDrop: (t, i, at) => _drop(t, i, at),
                    onRemove: _unplace,
                    onSay: _sayTap,
                  ),
                ),
                // The tray of six phrase tiles.
                Positioned(
                  key: ValueKey('hud-tray-${_run.index}-${_run.attempt}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 6,
                  child: KeyedSubtree(
                    key: _trayKey,
                    child: _Tray(
                      tiles: _run.tray,
                      placed: _run.slots,
                      keys: _tileKeys,
                      tileW: tileW,
                      canDrag: tilesOn,
                      onDragStart: () => _dragging = true,
                      onDragEnd: () => _dragging = false,
                      onTap: _tapScene,
                    ),
                  ),
                ),
              ],
              if (sheetPhase && playing && !deckUp)
                Positioned(
                  key: const ValueKey('hud-go'),
                  left: 24,
                  bottom: pad.bottom + 40,
                  child: _GoButton(key: _goKey, onTap: _goTap),
                ),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 236 : (sheetPhase || _run.roundDone ? 96 : _trayH + _stripH + 22)),
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
                  mistake: _card!,
                  tone: MistakeTone.slip,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
                          _hush();
                          unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.thud,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M7HonestReplyLines.intro,
                  alarm: 'sounds/learn/rush_in.ogg',
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    unawaited(_start());
                  },
                ),
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _run.passed
                            ? LevelPassPanel(
                                mark: _mark!,
                                levelScore: _runScore,
                                totalDelta: _totalDelta,
                                ms: _clock.elapsedMilliseconds,
                                caughtBn: _run.caught,
                                quickBonus: _quickBonus,
                                stars: _stars,
                                onNext: () => _popOnce(true),
                                onRetry: () => widget.onRetry(_muted),
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 2, muted: _muted)),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _tileH = 40;
  static const double _trayH = _tileH * 3 + 6 * 2;
  static const double _stripH = 48;
}

// ============================================================================
// Pieces
// ============================================================================

/// A customer, sliding in from the lane's edge once, then still.
class _CustomerFigure extends StatelessWidget {
  const _CustomerFigure({super.key, required this.look, required this.mood, required this.faceLeft, required this.fromRight, required this.quiet});
  final M7Look look;
  final M7Mood mood;
  final bool faceLeft;
  final bool fromRight;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final fig = RepaintBoundary(child: CustomPaint(painter: M7CustomerPainter(look: look, mood: mood, faceLeft: faceLeft), size: Size.infinite));
    if (quiet) return fig;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: 1 - v * 0.8, child: Transform.translate(offset: Offset((fromRight ? 1 : -1) * v * 90, 0), child: child)),
      child: fig,
    );
  }
}

/// A customer's words, as a caption bubble with a tail toward him.
class _CaptionBubble extends StatelessWidget {
  const _CaptionBubble({super.key, required this.text, required this.quiet, required this.tailX});
  final String text;
  final bool quiet;
  final double tailX;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 208),
              child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, height: 1.3, color: const Color(0xFF2A2018))),
            ),
          ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(padding: EdgeInsets.only(left: tailX - 8), child: const CustomPaint(size: Size(16, 10), painter: _TailPainter())),
        ),
      ],
    );
    return Semantics(
      label: text,
      child: Align(
        alignment: Alignment.topCenter,
        child: quiet
            ? body
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, alignment: Alignment.bottomCenter, child: child),
                child: body,
              ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(0, -2)
      ..lineTo(s.width, -2)
      ..lineTo(s.width / 2, s.height)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFFFFBF0));
    c.drawLine(Offset(0, 0), Offset(s.width / 2, s.height), Paint()
      ..color = const Color(0xFF8A6A3C)
      ..strokeWidth = 2);
    c.drawLine(Offset(s.width, 0), Offset(s.width / 2, s.height), Paint()
      ..color = const Color(0xFF8A6A3C)
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// One phrase tile: all six alike (one colour, one length band).
class _TileCard extends StatelessWidget {
  const _TileCard({required this.text, this.ghost = false, this.lifted = false});
  final String text;
  final bool ghost;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ghost ? 0.28 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 10 : 4, offset: Offset(0, lifted ? 6 : 2))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.2, color: SlmColors.ivory)),
          ),
        ),
      ),
    );
  }
}

/// The tray: six tiles, two across; a tile on the strip leaves a faint ghost.
class _Tray extends StatelessWidget {
  const _Tray({required this.tiles, required this.placed, required this.keys, required this.tileW, required this.canDrag, required this.onDragStart, required this.onDragEnd, required this.onTap});
  final List<M7Tile> tiles;
  final List<M7Tile?> placed;
  final List<GlobalKey> keys;
  final double tileW;
  final bool canDrag;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget cell(int i) {
      final t = tiles[i];
      final on = placed.contains(t);
      final card = SizedBox(width: tileW, height: _HonestRunPageState._tileH, child: _TileCard(text: t.text, ghost: on));
      if (on) return SizedBox(key: keys[i], width: tileW, height: _HonestRunPageState._tileH, child: card);
      return Semantics(
        key: ValueKey('tile-${t.text}'),
        button: true,
        label: t.text,
        excludeSemantics: true,
        child: Draggable<M7Tile>(
          key: keys[i],
          data: t,
          maxSimultaneousDrags: canDrag ? 1 : 0,
          onDragStarted: onDragStart,
          onDragEnd: (_) => onDragEnd(),
          onDraggableCanceled: (_, _) => onDragEnd(),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: tileW, height: _HonestRunPageState._tileH, child: _TileCard(text: t.text, lifted: true)),
          ),
          childWhenDragging: SizedBox(width: tileW, height: _HonestRunPageState._tileH, child: _TileCard(text: t.text, ghost: true)),
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < 3; r++) ...[
          if (r > 0) const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (var k = 0; k < 2; k++) cell(r * 2 + k)],
          ),
        ],
      ],
    );
  }
}

/// The speech strip: two slots and 'বলুন'.
class _Strip extends StatelessWidget {
  const _Strip({required this.slots, required this.canDrop, required this.full, required this.sayKey, required this.onDrop, required this.onRemove, required this.onSay});
  final List<M7Tile?> slots;
  final bool canDrop;
  final bool full;
  final GlobalKey sayKey;
  final void Function(M7Tile t, int slot, Offset at) onDrop;
  final ValueChanged<int> onRemove;
  final ValueChanged<Offset> onSay;

  @override
  Widget build(BuildContext context) {
    Widget slot(int i) => Expanded(
          child: DragTarget<M7Tile>(
            key: ValueKey('slot-$i'),
            onWillAcceptWithDetails: (_) => canDrop,
            onAcceptWithDetails: (d) => onDrop(d.data, i, d.offset),
            builder: (_, cand, _) {
              final t = slots[i];
              final hot = cand.isNotEmpty;
              return Semantics(
                label: M7HonestReplyLines.stripLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: t == null ? null : () => onRemove(i),
                  child: Container(
                    height: _HonestRunPageState._stripH,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t == null ? const Color(0x990B1324) : const Color(0xFFFFFBF0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: hot ? SlmColors.gold300 : const Color(0x88F2D58A), width: hot ? 2.4 : 1.6),
                    ),
                    child: t == null
                        ? Icon(Icons.chat_bubble_outline_rounded, size: 20, color: SlmColors.gold300.withValues(alpha: 0.55))
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 124),
                              child: Text(t.text, key: ValueKey('placed-$i'), textAlign: TextAlign.center, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.2, color: const Color(0xFF2A2018))),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        );
    return Row(
      children: [
        slot(0),
        const SizedBox(width: 6),
        slot(1),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: M7HonestReplyLines.say,
          excludeSemantics: true,
          child: GestureDetector(
            key: sayKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onSay(d.globalPosition),
            child: Container(
              width: 64,
              height: _HonestRunPageState._stripH,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: full ? const [Color(0xFFF7D774), Color(0xFFD9A441)] : const [Color(0xFFB9A978), Color(0xFF8D7F58)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8A6A3C), width: 1.6),
              ),
              child: Text(M7HonestReplyLines.say, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
            ),
          ),
        ),
      ],
    );
  }
}

/// 'চলুন'.
class _GoButton extends StatelessWidget {
  const _GoButton({super.key, required this.onTap});
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M7HonestReplyLines.go,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: Container(
          width: 120,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7D774), Color(0xFFD9A441)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 1.8),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Text(M7HonestReplyLines.go, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
        ),
      ),
    );
  }
}

/// The job sheet on its nail. Dragged to the customer when its turn comes
/// (the same prop all play, so it never tells who needs it).
class _JobSheet extends StatelessWidget {
  const _JobSheet({super.key, required this.signed, required this.live, required this.onTapped});
  final bool signed;
  final bool live;
  final VoidCallback onTapped;

  Widget _paper({bool lifted = false}) => Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1DE),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
          boxShadow: [BoxShadow(color: const Color(0x55000000), blurRadius: lifted ? 9 : 4, offset: Offset(0, lifted ? 6 : 2))],
        ),
        child: Column(
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(M7HonestReplyLines.sheetLabel, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2A16)))),
            const Divider(height: 5, thickness: 1, color: Color(0x668A6A3C)),
            for (var i = 0; i < 3; i++) Padding(padding: const EdgeInsets.only(top: 3), child: Container(height: 2, color: const Color(0x553A2A16))),
            const Spacer(),
            if (signed) const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF2E9E4F)) else const SizedBox(height: 13),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final paper = _paper();
    return Semantics(
      label: M7HonestReplyLines.sheetLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: live
                ? Draggable<String>(
                    data: 'sheet',
                    feedback: Material(color: Colors.transparent, child: SizedBox(width: 46, height: 60, child: _paper(lifted: true))),
                    childWhenDragging: Opacity(opacity: 0.3, child: paper),
                    child: paper,
                  )
                : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTapped, child: paper),
          ),
          // The clip.
          Positioned(top: -5, left: 0, right: 0, child: Center(child: Container(width: 20, height: 8, decoration: BoxDecoration(color: const Color(0xFF9AA2A8), borderRadius: BorderRadius.circular(3))))),
        ],
      ),
    );
  }
}
