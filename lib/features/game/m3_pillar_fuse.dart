import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm3_pillar_fuse_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 3.7 "এলটি ডিস্ট্রিবিউশন বক্স/ফিডার পিলার", কাজ 1 "ফিউজ বদলাও ঠিকঠাক"
// (pack do_3_7_a, engineType m3_pillar_fuse). Three street pillars a play;
// at each, the docket names the dead feeder and phase (one fuse has blown).
// The trainee puts on full PPE, opens the pillar, finds why the fuse blew,
// pulls the blown fuse (only that one) with the insulated fuse puller, fits a
// new HRC fuse — never a copper strip or a thick wire — and closes and locks
// the door before he signs off.
//
// The lesson's rules, and only those:
//   • point 1: a fault on one line takes out only that line (each feeder has
//     its own fuses) — so only the docket's fuse is pulled;
//   • point 2: inside, the pillar is as dangerous as a live panel — full PPE
//     and insulated tools; the feeders' fuses are HRC fuses;
//   • point 3: the causes — loose connection / hotspot (black marks, burnt
//     smell), water ingress (a broken seal), rodents cutting the insulation —
//     all lead to short circuits;
//   • myth 1: 415 V is no small thing — the fault current can make an arc
//     flash that burns in a moment; myth 2: a thick wire or a strip in place
//     of the fuse destroys its protection — the cable or transformer burns;
//   • advanced: the HRC fuse's quartz sand absorbs the arc;
//   • pro tip 1: lock the pillar door after the work (children, the public).
// Inferred (flagged in REGISTER.md): the cause is found before the new fuse
// goes in (else it blows again); the fuse puller as the insulated tool; how
// the cause is mended is not in the lesson, so the level marks it put right
// once the trainee has spotted it.
//
// Deadly: any work on a fuse with no PPE (an arc flash); a copper strip or a
// thick wire in the fuse's place (also by listening to the coworker, "তামার
// পাত লাগিয়ে দাও, আর উড়বে না!" — the act he pushes is on MODULE3_LADDER.md
// row 20's deadly list, so listening stays deadly here). Slips: a hand on a
// fuse (no puller), pulling a healthy feeder's fuse, calling a sound spot the
// cause (a wrong flag: once per spot a pillar), a new fuse before the cause is
// found, signing off with the door open or unlocked. Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_pillar_fuse_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next pillar by itself; the careless coworker once a play, as the new
// fuse is about to go in. Kit (2026-11-11): no scene control works in a praise
// window (`tableBusy`); the tray waits for the coworker (`holdForCoworker`), so
// a fast fit cannot skip him; the tool row is dealt in a shuffled order (never
// the job's order); each reason deck carries one myth that shares the
// question's key word (no word only on the right card); gesture hints sweep
// over every tool / tray item and the pillar (never one), and a tap on nothing
// counts as a miss. Voice: the guide by device TTS; the coworker's push has
// no clip yet (silent, caption held — the director records it); his exit line
// is his existing clip.

// ============================================================================
// Content
// ============================================================================

/// What the reason question asks about.
enum M3PillarFuseWhy { hrc, cause, ppe, lock }

/// What can go in the empty fuse slot (the tray).
enum M3PillarFuseItem { hrc, strip, wire }

/// The hands-on tool row (dealt in a shuffled order, never the job's order).
enum M3PillarFuseTool { ppe, puller, lock, signOff }

@immutable
class M3PillarFuseRound {
  const M3PillarFuseRound({
    required this.id,
    required this.feeder,
    required this.phase,
    required this.cause,
    required this.why,
    required this.tray,
    this.tools = const [M3PillarFuseTool.lock, M3PillarFuseTool.ppe, M3PillarFuseTool.signOff, M3PillarFuseTool.puller],
  });
  final String id;

  /// The dead feeder (0..2 = F1..F3) and the phase of its blown fuse (0..2 = R, Y, B).
  final int feeder;
  final int phase;
  final M3PillarFuseCause cause;
  final M3PillarFuseWhy why;

  /// The tray's order.
  final List<M3PillarFuseItem> tray;

  /// The tool row's order.
  final List<M3PillarFuseTool> tools;
}

abstract final class M3PillarFuseLines {
  static const title = 'ফিউজ বদলাও ঠিকঠাক';
  static const intro = 'একটা ফিডার বন্ধ, পাড়া অন্ধকার! পিলারের ফিউজ বদলান — নিয়ম মেনে।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askOpen = 'ডকেটের ফিডারে আলো নেই। কাজ শুরু করুন।';
  static const askFix = 'ফিডারটা আবার চালু করতে হবে — নিরাপদে।';
  static const askFit = 'খালি ঘরে কী লাগাবেন?';
  static const askClose = 'আলো ফিরেছে। এবার কাজটা শেষ করুন।';
  static const tasks = [askOpen, askFix, askFit, askClose];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // When the cause is spotted (lesson 3.7 point 3).
  static String causeSeen(M3PillarFuseCause c) => switch (c) {
        M3PillarFuseCause.hotspot => 'কালো দাগ, পোড়া গন্ধ — ঢিলা কানেকশনে হটস্পট!',
        M3PillarFuseCause.water => 'ভাঙা সিল দিয়ে জল ঢুকেছে — শর্ট সার্কিট!',
        M3PillarFuseCause.rodent => 'ইঁদুর কেবিল কেটেছে — শর্ট সার্কিট!',
      };
  static const causeMended = 'কারণটা সারানো হলো।';

  // Labels a worker reads (tools, the tray, the docket).
  static const sceneLabel = 'ফিডার পিলার';
  static const ppe = 'পিপিই';
  static const puller = 'ফিউজ পুলার';
  static const lock = 'তালা';
  static const signOff = 'কাজ শেষ';
  static const docket = 'ডকেট';
  static String itemBn(M3PillarFuseItem i) => switch (i) {
        M3PillarFuseItem.hrc => 'HRC ফিউজ',
        M3PillarFuseItem.strip => 'তামার পাত',
        M3PillarFuseItem.wire => 'মোটা তার',
      };
  static const phaseNames = ['R', 'Y', 'B'];
  static String docketBn(M3PillarFuseRound r) => 'F${r.feeder + 1} · ${phaseNames[r.phase]} ফেজে আলো নেই';
  static const stampLights = 'আলো ফিরল';

  // The reasons (lesson 3.7): the right ones fit what was done; the wrong
  // ones are the lesson's myths and field excuses — never a true rule marked
  // wrong. Every card 35–45 letters.
  static const whyHrcQ = 'কেন পাত বা তার নয়, HRC ফিউজই লাগালেন?';
  static const whyCauseQ = 'কেন ফিউজ বদলের আগে কারণ খুঁজলেন?';
  static const whyPpeQ = 'কেন পুরো পিপিই পরে তবে বক্সে হাত দিলেন?';
  static const whyLockQ = 'কেন যাওয়ার আগে দরজায় তালা দিলেন?';
  static const hrcWhy = ['ফল্টে HRC ফিউজ উড়ে কেবিল বাঁচায়, পাত উড়ে না', 'HRC ফিউজের বালু আর্ক শুষে নেয়, বিস্ফোরণ নেই'];
  static const causeWhy = ['কারণ না সারালে নতুন ফিউজটাও আবার উড়বে', 'হটস্পট, জল না ইঁদুর — আগে কারণ, তবে ফিউজ'];
  static const ppeWhy = ['পিলারের ভেতর লাইভ প্যানেল, আর্ক ফ্ল্যাশে পোড়ায়', 'পুরো পিপিই আর ইনসুলেটেড টুল ছাড়া বক্সে হাত নয়'];
  static const lockWhy = ['খোলা দরজা বাচ্চা আর পথচারীর জন্য মারাত্মক বিপদ', 'দরজা লক থাকলে সাধারণ মানুষ লাইভ বক্সে হাত দেয় না'];
  static const myths = [
    'মাত্র 415 ভোল্ট, এতে তেমন কোনো বিপদ নেই',
    'তামার পাত দিলে ফিউজ আর বারবার উড়বে না',
    'মোটা তার দিলেই চলে, ফিউজ কেনার দরকার নেই',
    'ফিউজ উড়েছে মানে শুধু ফিউজটাই খারাপ ছিল',
    'রোজকার চেনা বক্স, পিপিই ছাড়াই কাজ চলে',
    'দরজা ভেজিয়ে রাখলেই হলো, তালার দরকার নেই',
    'পাড়ার লোক তাড়া দিচ্ছেন, তাই তাড়াতাড়ি সারলাম',
    ...hrcEcho,
    ...causeEcho,
    'পিপিই শুধু এইচটি লাইনে লাগে, পিলারে নয়',
    'দরজা খোলা থাকলে বাতাসে বক্স ঠান্ডা থাকে',
  ];

  // Myths that share the question's key word (HRC · কারণ · পিপিই · দরজা):
  // one is dealt on every reason deck, so that word is never on the right
  // card alone.
  static const hrcEcho = ['HRC ফিউজ দামি, পাত দিলেও একই কাজ হয়ে যায়', 'HRC ফিউজ না পেলে মোটা তারেই কাজ চলে যায়'];
  static const causeEcho = ['কারণ খোঁজা সময় নষ্ট, নতুন ফিউজই যথেষ্ট', 'কারণ যা-ই হোক, নতুন ফিউজ দিলেই সব ঠিক হয়'];
  static const ppeEcho = ['রোজকার চেনা বক্স, পিপিই ছাড়াই কাজ চলে', 'পিপিই শুধু এইচটি লাইনে লাগে, পিলারে নয়'];
  static const lockEcho = ['দরজা ভেজিয়ে রাখলেই হলো, তালার দরকার নেই', 'দরজা খোলা থাকলে বাতাসে বক্স ঠান্ডা থাকে'];
  static List<String> whyEcho(M3PillarFuseRound r) => switch (r.why) {
        M3PillarFuseWhy.hrc => hrcEcho,
        M3PillarFuseWhy.cause => causeEcho,
        M3PillarFuseWhy.ppe => ppeEcho,
        M3PillarFuseWhy.lock => lockEcho,
      };

  /// The reason deck: one right card, one myth sharing the question's key
  /// word, one more myth — in a random order.
  static List<ChoiceOption> dealWhy(M3PillarFuseRound r, math.Random rng) {
    final right = whyRight(r);
    final echo = whyEcho(r);
    final e = echo[rng.nextInt(echo.length)];
    final rest = [for (final m in myths) if (m != e) m]..shuffle(rng);
    return [ChoiceOption(right[rng.nextInt(right.length)], true), ChoiceOption(e, false), ChoiceOption(rest.first, false)]..shuffle(rng);
  }

  static const allRight = [...hrcWhy, ...causeWhy, ...ppeWhy, ...lockWhy];

  static List<String> whyRight(M3PillarFuseRound r) => switch (r.why) {
        M3PillarFuseWhy.hrc => hrcWhy,
        M3PillarFuseWhy.cause => causeWhy,
        M3PillarFuseWhy.ppe => ppeWhy,
        M3PillarFuseWhy.lock => lockWhy,
      };
  static String whyQuestion(M3PillarFuseRound r) => switch (r.why) {
        M3PillarFuseWhy.hrc => whyHrcQ,
        M3PillarFuseWhy.cause => whyCauseQ,
        M3PillarFuseWhy.ppe => whyPpeQ,
        M3PillarFuseWhy.lock => whyLockQ,
      };

  /// The careless coworker: bridge it with a copper strip.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'তামার পাত লাগিয়ে দাও, আর উড়বে না! রোজ রোজ কে আসবে?',
    exitLine: coworkerExit,
    right: ['না, শুধু HRC ফিউজ — পাতে কেবিল পুড়বে', 'না, পাত দিলে ফিউজের সুরক্ষাই থাকে না', 'না, ফিউজের জায়গায় পাত বা তার নয়'],
    wrong: [
      'ঠিক, তামার পাত দিলে আর উড়বে না',
      'আচ্ছা, আজ পাত দিই, পরে ফিউজ দেব',
      'হ্যাঁ, একটা মোটা তারই জুড়ে দিই',
      'ঠিক আছে, পাত দিলেই কাজ চলে যাবে',
      'হ্যাঁ, ফিউজ কেনার চেয়ে পাতই ভালো',
    ],
    asks: ['ও বলছে তামার পাত লাগাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'ফিউজের জায়গায় পাত দেবেন?'],
  );

  static const callHeld = 'ঠিক! ফিউজের জায়গায় শুধু HRC ফিউজ।';
  static const allSet = 'তিন পাড়ায় আলো — কারণ সারিয়ে, HRC ফিউজে, দরজায় তালা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — পিপিই, কারণ, HRC ফিউজ, তালা।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtPpe = 'পুরো পিপিই পরে বক্সে হাত';
  static const caughtFuse = 'ডকেট মিলিয়ে ঠিক ফিউজটাই খুলেছেন';
  static const caughtCause = 'ফিউজের আগে কারণ ধরেছেন';
  static const caughtHrc = 'পাত-তার নয়, শুধু HRC ফিউজ';
  static const caughtLock = 'দরজা বন্ধ করে তালা';
  static const caughtCall = 'তামার পাতে “না” বলেছেন';
}

abstract final class M3PillarFuseMistakes {
  static const _dir = 'assets/game/art/m3_pillar_fuse';

  static const noPpe = DoMistake(
    key: '3.7/m3_pillar_fuse/no-ppe',
    textBn: 'পিপিই ছাড়া পিলারের ভেতরে হাত নয়! এখানে আর্ক ফ্ল্যাশ মুহূর্তে পুড়িয়ে দেয় — আগে পুরো পিপিই, ইনসুলেটেড টুল।',
    art: '$_dir/no_ppe.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const bodgeStrip = DoMistake(
    key: '3.7/m3_pillar_fuse/copper-strip',
    textBn: 'ফিউজের জায়গায় তামার পাত নয়! ফল্টে পাত উড়বে না — কেবিল আর ট্রান্সফরমার পুড়ে যাবে। শুধু HRC ফিউজ।',
    art: '$_dir/bodge.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const bodgeWire = DoMistake(
    key: '3.7/m3_pillar_fuse/thick-wire',
    textBn: 'ফিউজের জায়গায় মোটা তার নয়! ফল্টে তার উড়বে না — কেবিল আর ট্রান্সফরমার পুড়ে যাবে। শুধু HRC ফিউজ।',
    art: '$_dir/bodge.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const noPuller = DoMistake(
    key: '3.7/m3_pillar_fuse/hand-on-fuse',
    textBn: 'ফিউজ হাতে টেনে খুলবেন না — ইনসুলেটেড ফিউজ পুলার দিয়ে খুলুন আর লাগান।',
    art: '$_dir/no_puller.svg',
    lessonPoint: 1,
  );
  static const wrongFuse = DoMistake(
    key: '3.7/m3_pillar_fuse/wrong-fuse',
    textBn: 'এটা চালু লাইনের ফিউজ — খুললে ভালো পাড়াও অন্ধকার। ডকেটের ফিডার আর ফেজ মিলিয়ে খুলুন।',
    art: '$_dir/wrong_fuse.svg',
    lessonPoint: 0,
  );
  // "Cause first" is inferred from point 3 (flagged in REGISTER.md).
  static const noCause = DoMistake(
    key: '3.7/m3_pillar_fuse/no-cause',
    textBn: 'আগে দেখুন ফিউজ কেন উড়ল — হটস্পট, জল না ইঁদুর? কারণ না সারালে নতুন ফিউজও উড়বে।',
    art: '$_dir/no_cause.svg',
    lessonPoint: 2,
  );
  // Pro tip 1 (the door) is not a lesson point: no "পাঠে দেখুন" target there,
  // so these point at point 1 (its daily check: the door shut properly).
  static const doorOpen = DoMistake(
    key: '3.7/m3_pillar_fuse/door-open',
    textBn: 'দরজা খোলা রেখে কাজ শেষ নয় — বাচ্চা আর পথচারীর জন্য মারাত্মক বিপদ। বন্ধ করে তালা দিন।',
    art: '$_dir/door_open.svg',
    lessonPoint: 0,
  );
  static const noLock = DoMistake(
    key: '3.7/m3_pillar_fuse/no-lock',
    textBn: 'দরজা শুধু ভেজালেই হবে না — তালা দিন, যাতে কেউ লাইভ বক্স খুলতে না পারে।',
    art: '$_dir/door_open.svg',
    lessonPoint: 0,
  );

  // A wrong flag: a sound spot called the cause (point 3's causes).
  static const wrongSpot = DoMistake(
    key: '3.7/m3_pillar_fuse/wrong-spot',
    textBn: 'কারণটা ভালো করে দেখে নিন — কালো দাগ, জল না ইঁদুর?',
    art: '$_dir/no_cause.svg',
    lessonPoint: 2,
  );

  static List<DoMistake> get all => const [noPpe, bodgeStrip, bodgeWire, noPuller, wrongFuse, noCause, wrongSpot, doorOpen, noLock];
}

@immutable
class M3PillarFuseDeal {
  const M3PillarFuseDeal({required this.rounds, required this.callAt});
  final List<M3PillarFuseRound> rounds;

  /// The pillar the careless coworker comes to.
  final int callAt;
}

/// The tool row in a shuffled order that is never the job's order
/// (PPE → puller → lock → sign off).
List<M3PillarFuseTool> m3PillarFuseTools(math.Random rng) {
  while (true) {
    final t = [...M3PillarFuseTool.values]..shuffle(rng);
    var same = true;
    for (var i = 0; i < t.length; i++) {
      if (t[i] != M3PillarFuseTool.values[i]) same = false;
    }
    if (!same) return t;
  }
}

/// Three pillars: each a different cause, a different reason question; the
/// dead feeder/phase, the tray's order and the tool row's order vary.
M3PillarFuseDeal m3PillarFuseDeal(math.Random rng) {
  final causes = [...M3PillarFuseCause.values]..shuffle(rng);
  final whys = [...M3PillarFuseWhy.values]..shuffle(rng);
  final rounds = <M3PillarFuseRound>[
    for (var i = 0; i < 3; i++)
      M3PillarFuseRound(
        id: 'p$i',
        feeder: rng.nextInt(3),
        phase: rng.nextInt(3),
        cause: causes[i],
        why: whys[i],
        tray: [...M3PillarFuseItem.values]..shuffle(rng),
        tools: m3PillarFuseTools(rng),
      ),
  ];
  return M3PillarFuseDeal(rounds: rounds, callAt: rng.nextInt(3));
}

/// The play state (pure logic).
class M3PillarFuseRun {
  M3PillarFuseRun(this.deal);
  final M3PillarFuseDeal deal;
  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this pillar ---
  var ppe = false;
  var doorOpen = false;
  var locked = false;
  var puller = false;
  var causeFound = false;
  var slotEmpty = false;
  var fitted = false;
  var signedOff = false;

  bool get done => index >= deal.rounds.length;
  bool get ended => done || deadly != null;
  M3PillarFuseRound get round => deal.rounds[index.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// The tray is up: the blown fuse is out, the new one not yet in.
  bool get trayUp => slotEmpty && !fitted && !ended;

  /// Done this pillar without a slip (+5 on the table).
  bool get thorough => roundSlips == 0;

  bool get _open => !ended && !signedOff;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  void putPpe() {
    if (_open) ppe = true;
  }

  /// Picks up the fuse puller (or puts it down).
  void holdPuller() {
    if (_open) puller = !puller;
  }

  /// The door (open ↔ shut). False = it did not move (locked).
  bool toggleDoor() {
    if (!_open || locked) return false;
    doorOpen = !doorOpen;
    if (!doorOpen) puller = false;
    return true;
  }

  /// The padlock on the shut door (or off it). False = not now.
  bool toggleLock() {
    if (!_open || doorOpen) return false;
    locked = !locked;
    if (locked) _tag(M3PillarFuseLines.caughtLock);
    return true;
  }

  /// A fuse carrier touched (with the puller in hand, or bare). Returns the mistake, if any.
  DoMistake? tapFuse(int feeder, int phase) {
    if (!_open || !doorOpen) return null;
    final blown = feeder == round.feeder && phase == round.phase;
    if (blown && (slotEmpty || fitted)) return null;
    if (!ppe) return deadly = M3PillarFuseMistakes.noPpe;
    if (!puller) return _slip(M3PillarFuseMistakes.noPuller);
    if (!blown) return _slip(M3PillarFuseMistakes.wrongFuse);
    slotEmpty = true;
    _tag(M3PillarFuseLines.caughtPpe);
    _tag(M3PillarFuseLines.caughtFuse);
    return null;
  }

  /// A look at a spot in the box. True = the cause was found just now.
  bool spot(bool onCause) {
    if (!_open || !doorOpen || causeFound || !onCause) return false;
    causeFound = true;
    _tag(M3PillarFuseLines.caughtCause);
    return true;
  }

  /// The spots called the cause this pillar although they were sound.
  final Set<int> _flagged = {};

  /// A sound spot ([zone], see [M3PillarFuseGeo.causeZones]) called the
  /// cause before it was found: a slip, once per spot a pillar.
  DoMistake? flagSound(int zone) {
    if (!_open || !doorOpen || causeFound || !_flagged.add(zone)) return null;
    return _slip(M3PillarFuseMistakes.wrongSpot);
  }

  /// Something from the tray into the empty slot. Null and [fitted] = the new HRC fuse is in.
  DoMistake? fit(M3PillarFuseItem item) {
    if (!_open || !trayUp) return null;
    switch (item) {
      case M3PillarFuseItem.strip:
        return deadly = M3PillarFuseMistakes.bodgeStrip;
      case M3PillarFuseItem.wire:
        return deadly = M3PillarFuseMistakes.bodgeWire;
      case M3PillarFuseItem.hrc:
        if (!causeFound) return _slip(M3PillarFuseMistakes.noCause);
        fitted = true;
        puller = false;
        _tag(M3PillarFuseLines.caughtHrc);
        return null;
    }
  }

  /// "কাজ শেষ". Null and [signedOff] = this pillar is done; null alone = not yet (the feeder is still dead).
  DoMistake? signOff() {
    if (!_open || !fitted) return null;
    if (doorOpen) return _slip(M3PillarFuseMistakes.doorOpen);
    if (!locked) return _slip(M3PillarFuseMistakes.noLock);
    signedOff = true;
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly ??= m;

  void next() {
    index++;
    roundSlips = 0;
    ppe = false;
    doorOpen = false;
    locked = false;
    puller = false;
    causeFound = false;
    _flagged.clear();
    slotEmpty = false;
    fitted = false;
    signedOff = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action: PPE, door, spot + its lines ~3000, puller,
/// fuse, tray, door, lock, sign off ≈ 15000; the lights ~1500; reason ~8200
/// ≈ 24700 × 3 + the coworker once ≈ 9600 ≈ 83700. 85 % ≈ 71000 → 70 s.
const kM3PillarFuseQuickMs = 70000;

@immutable
class M3PillarFusePack {
  const M3PillarFusePack({required this.id, required this.titleBn, this.quickMs = kM3PillarFuseQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M3PillarFusePack> m3PillarFusePacks = {
  'do_3_7_a': M3PillarFusePack(id: 'do_3_7_a', titleBn: M3PillarFuseLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3PillarFusePage extends StatefulWidget {
  const M3PillarFusePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3PillarFusePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3PillarFusePage> createState() => _M3PillarFusePageState();
}

class _M3PillarFusePageState extends State<M3PillarFusePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FuseRunPage(
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

class _FuseRunPage extends ConsumerStatefulWidget {
  const _FuseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3PillarFusePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FuseRunPage> createState() => _FuseRunPageState();
}

class _FuseRunPageState extends ConsumerState<_FuseRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3PillarFuseRun _run = M3PillarFuseRun(m3PillarFuseDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  /// He was scheduled for this play (once, as the tray comes up on his pillar).
  var _coworkerScheduled = false;

  // Gesture hints: how to touch (a sweep over every tool / tray item and the
  // pillar), never which one.
  final _hints = IdleHintController();
  final _touchKey = GlobalKey();
  final Map<M3PillarFuseTool, GlobalKey> _toolKeys = {for (final t in M3PillarFuseTool.values) t: GlobalKey()};
  final Map<M3PillarFuseItem, GlobalKey> _trayKeys = {for (final i in M3PillarFuseItem.values) i: GlobalKey()};

  /// The cause is still to be seen in the box (it goes once put right).
  var _causeShown = true;
  Timer? _mendTimer;

  /// Where the deadly flash comes from (design px) and whether it burns.
  Offset _flashAt = Offset.zero;
  var _flashFire = false;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _mendTimer?.cancel();
    _chain++;
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

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  /// The scene takes a move now: never in a praise window (`tableBusy`), a
  /// death freeze, a card or while he is on.
  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.signedOff && !_freeze;

  String get _task {
    if (_run.fitted) return M3PillarFuseLines.askClose;
    if (_run.trayUp) return M3PillarFuseLines.askFit;
    if (_run.doorOpen) return M3PillarFuseLines.askFix;
    return M3PillarFuseLines.askOpen;
  }

  void _startRound() {
    _mendTimer?.cancel();
    setState(() {
      _causeShown = true;
      _wake++;
    });
    unawaited(_sayChain([M3PillarFuseLines.askOpen]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _putPpe() {
    if (!_canPlay || _run.ppe) return;
    _tick('sounds/learn/tag_slap.wav', 0.35);
    setState(() {
      _run.putPpe();
      _wake++;
    });
  }

  void _holdPuller() {
    if (!_canPlay) return;
    _tick('sounds/quiz_select.wav');
    setState(() {
      _run.holdPuller();
      _wake++;
    });
  }

  void _toggleLock() {
    if (!_canPlay) return;
    if (_run.toggleLock()) {
      _tick('sounds/learn/tag_slap.wav', 0.5);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
    setState(() => _wake++);
  }

  void _signOff(Offset global) {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.signOff();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
    } else if (_run.signedOff) {
      unawaited(_roundDone());
    } else {
      unawaited(_sayChain([_nudge.next(_task)]));
    }
  }

  void _fit(M3PillarFuseItem item, Offset global) {
    final geo = _geo;
    if (!_canPlay || !_run.trayUp) return;
    // The fit is the decisive move on his pillar: he comes first.
    if (holdForCoworker()) return;
    _tick('sounds/intro/impact_metal.ogg', 0.5);
    final m = _run.fit(item);
    setState(() {
      _flashAt = geo.fuse(_run.round.feeder, _run.round.phase);
      _flashFire = true;
      _wake++;
    });
    if (m != null) {
      unawaited(_mistake(m, global));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    unawaited(_sayChain([M3PillarFuseLines.askClose]));
  }

  void _tapScene(Offset p, M3PillarFuseGeo geo, Offset global) {
    if (!_canPlay) return;
    final r = _run.round;
    if (!_run.doorOpen) {
      if (geo.body.contains(p)) {
        if (_run.toggleDoor()) {
          _tick('sounds/intro/impact_metal.ogg', 0.5);
        } else {
          _tick('sounds/intro/click.ogg', 0.3);
        }
        setState(() => _wake++);
      } else {
        _hints.missTap();
      }
      return;
    }
    if (geo.openDoorHit.contains(p)) {
      if (_run.toggleDoor()) _tick('sounds/intro/impact_metal.ogg', 0.5);
      setState(() => _wake++);
      return;
    }
    for (var f = 0; f < 3; f++) {
      for (var ph = 0; ph < 3; ph++) {
        if (!geo.fuseHit(f, ph).contains(p)) continue;
        _tick();
        final m = _run.tapFuse(f, ph);
        setState(() {
          _flashAt = geo.fuse(f, ph);
          _flashFire = false;
          _wake++;
        });
        if (m != null) {
          unawaited(_mistake(m, global));
        } else if (_run.trayUp) {
          _cue('sounds/learn/card_deal_a.wav', volume: 0.5);
          if (!_coworkerScheduled && _run.index == _run.deal.callAt) {
            _coworkerScheduled = true;
            scheduleCoworker();
          }
          unawaited(_sayChain([M3PillarFuseLines.askFit]));
        }
        return;
      }
    }
    final zones = geo.causeZones;
    final real = M3PillarFuseGeo.causeZone(r.cause, r.feeder);
    final onCause = zones[real].any((h) => h.contains(p));
    if (!onCause) {
      // A sound spot called the cause (before it was found): a slip.
      for (var z = 0; z < zones.length; z++) {
        if (z == real || !zones[z].any((h) => h.contains(p))) continue;
        final m = _run.flagSound(z);
        if (m == null) break;
        _tick('sounds/intro/click.ogg', 0.4);
        setState(() => _wake++);
        unawaited(_mistake(m, global));
        return;
      }
      _hints.missTap();
      return;
    }
    if (_run.spot(onCause)) {
      HapticFeedback.lightImpact();
      _cue('sounds/quiz_right.wav', volume: 0.5);
      setState(() => _wake++);
      unawaited(_sayChain([M3PillarFuseLines.causeSeen(r.cause), M3PillarFuseLines.causeMended]));
      _mendTimer?.cancel();
      final idx = _run.index;
      _mendTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted || _run.index != idx) return;
        setState(() {
          _causeShown = false;
          _wake++;
        });
      });
    }
  }

  Future<void> _roundDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final r = _run.round;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => M3PillarFuseLines.dealWhy(r, widget.rng),
      question: M3PillarFuseLines.whyQuestion(r),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    if (m.deadly) {
      await _deadly(m);
      return;
    }
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3PillarFuseLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push (a copper strip in the empty slot) fits only while the slot
    // is empty on his pillar; once the new fuse is in, his moment has passed.
    if (_ended || _run.ended || _run.index != _run.deal.callAt || !_run.trayUp) return null;
    if (_intro || _card != null || tableBusy || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: the copper strip goes in the fuse's place.
      final r = _run.round;
      _flashAt = _geo.fuse(r.feeder, r.phase);
      _flashFire = true;
      _run.failDeadly(M3PillarFuseMistakes.bodgeStrip);
      await _deadly(M3PillarFuseMistakes.bodgeStrip);
      return;
    }
    _run.caught.add(M3PillarFuseLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3PillarFuseLines.callHeld, M3PillarFuseLines.askFit], mood: GuideMood.glad));
  }

  /// The scene's layout (as FullSceneFrame last gave it).
  M3PillarFuseGeo _geo = M3PillarFuseGeo.forScene(780, 0);

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3PillarFuseLines.tapWhy[_nudgeN++ % M3PillarFuseLines.tapWhy.length]
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('pillar_fuse/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// No PPE in the box (an arc flash) or a bodged fuse (the slot burns): the
  /// street freezes grey and the flash comes off the fuse in colour; then
  /// near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _mendTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('pillar_fuse/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3PillarFuseLines.deadlyWord : M3PillarFuseLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same pillar goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        unawaited(_sayChain([_task]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
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
    await _say(!_run.passed ? M3PillarFuseLines.fail : (_quickBonus ? M3PillarFuseLines.quick : M3PillarFuseLines.allSet),
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
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_run.signedOff) return LinemanMode.cheer;
    if (_run.puller) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M3PillarFuseBox get _box {
    final r = _run.round;
    return M3PillarFuseBox(
      doorOpen: _run.doorOpen,
      locked: _run.locked,
      feeder: r.feeder,
      phase: r.phase,
      slotEmpty: _run.slotEmpty,
      fitted: _run.fitted,
      cause: r.cause,
      causeShown: _causeShown,
      spotted: _run.causeFound && _causeShown,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M3PillarFuseGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final box = _box;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: AwakeClock(
            wake: _wake,
            quiet: quiet,
            builder: (context, t) => Stack(
              children: [
                Positioned.fill(
                  key: const ValueKey('street'),
                  child: RepaintBoundary(child: CustomPaint(painter: M3PillarFuseWorldPainter(geo: geo, box: box, t: t, seed: _run.index * 5 + 3))),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: geo.trainee,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_run.fitted && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 236,
          width: 124,
          top: geo.groundY - 196,
          child: IgnorePointer(child: _StampPop(text: M3PillarFuseLines.stampLights, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3PillarFuseLines.sceneLabel,
          child: GestureDetector(key: _touchKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3PillarFuseFlashPainter(at: _flashAt, v: v, fire: _flashFire)),
            ),
          ),
        ),
      // The next pillar: a short fade from the last one.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
            ),
          ),
        ),
    ];
  }

  // --- gesture hints ------------------------------------------------------------
  /// A design rect of the scene in global pixels (the touch layer's local
  /// space is the design space; the frame scales it).
  Rect? _sceneRect(Rect design) {
    final box = _touchKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(design.topLeft), box.localToGlobal(design.bottomRight));
  }

  /// How to touch now: a sweep over every control on screen (the tools or
  /// the tray, and the pillar), never one of them.
  HintSpec? _hint() {
    final geo = _geo;
    final rects = <Rect>[
      if (_run.trayUp)
        for (final it in _run.round.tray) ?HintSpec.globalRectOf(_trayKeys[it]!)
      else
        for (final t in _run.round.tools) ?HintSpec.globalRectOf(_toolKeys[t]!),
      ?_sceneRect(geo.body),
      if (_run.doorOpen) ?_sceneRect(geo.openDoorHit),
    ];
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  String get _hintStage => _run.trayUp ? 'tray' : (_run.doorOpen ? 'open' : 'shut');

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.signedOff && !deckUp && !coworkerOpen && _card == null && !tableBusy;
    final r = _run.round;
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
              labels: M3PillarFuseLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !_run.done && !coworkerOnScreen,
            hintKey: '${_run.index}-$_hintStage-${_run.slips}',
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(text: M3PillarFuseLines.docketBn(r))),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && _run.trayUp)
                Positioned(
                  key: ValueKey('hud-tray-${_run.index}'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final it in r.tray)
                        _TrayItem(
                          key: _trayKeys[it],
                          item: it,
                          quiet: quiet,
                          onTapUp: (d) => _fit(it, d.globalPosition),
                        ),
                    ],
                  ),
                ),
              if (handsOn && !_run.trayUp)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final tool in r.tools)
                        switch (tool) {
                          M3PillarFuseTool.ppe => _ToolButton(
                              key: _toolKeys[tool], icon: Icons.health_and_safety_rounded, label: M3PillarFuseLines.ppe, on: _run.ppe, onTap: _putPpe),
                          M3PillarFuseTool.puller => _ToolButton(
                              key: _toolKeys[tool], icon: Icons.handyman_rounded, label: M3PillarFuseLines.puller, on: _run.puller, onTap: _holdPuller),
                          M3PillarFuseTool.lock => _ToolButton(
                              key: _toolKeys[tool], icon: Icons.lock_rounded, label: M3PillarFuseLines.lock, on: _run.locked, onTap: _toggleLock),
                          M3PillarFuseTool.signOff => _ToolButton(
                              key: _toolKeys[tool], icon: Icons.task_alt_rounded, label: M3PillarFuseLines.signOff, on: false, onTapUp: _signOff),
                        },
                    ],
                  ),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: !coworkerOnScreen || coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}-$strikes'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: () {
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
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: MediaQuery.disableAnimationsOf(context) ? 300 : 2400,
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M3PillarFuseLines.intro,
                  alarm: 'sounds/learn/rush_in.wav',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 1, muted: _muted)),
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
}

// ============================================================================
// Pieces
// ============================================================================

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M3PillarFuseLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(text, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, this.onTap, this.onTapUp});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final void Function(Offset global)? onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          onTap?.call();
          onTapUp?.call(d.globalPosition);
        },
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One thing on the fuse tray: its picture and its name.
class _TrayItem extends StatelessWidget {
  const _TrayItem({super.key, required this.item, required this.quiet, required this.onTapUp});
  final M3PillarFuseItem item;
  final bool quiet;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final label = M3PillarFuseLines.itemBn(item);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: Duration(milliseconds: 280 + 90 * item.index),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 40 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTapUp,
          child: Container(
            width: 104,
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.85), width: 1.6),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 52, height: 52, child: CustomPaint(painter: M3PillarFuseItemPainter(item.index))),
                const SizedBox(height: 4),
                Text(label, maxLines: 1, softWrap: false, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StampPop extends StatelessWidget {
  const _StampPop({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
