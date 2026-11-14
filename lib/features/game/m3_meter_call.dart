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
import 'm3_meter_call_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_meter_call_world.dart' show M3MeterCallGeo, M3MeterCallRoom, M3MeterCallSpot, M3MeterCallTerm;

// Lesson 3.8 "সার্ভিস কেবিল ও এনার্জি মিটার", কাজ 2 "গ্রাহকের ডাক" (Module 3).
// Three complaint calls at houses, dealt in a fresh order each play:
//   • আলো কাঁপছে — a loose connection at the meter terminal (lesson point 3:
//     loose connection → flickering, low voltage; it heats and can start a
//     fire). Hands on: the meter box is a live panel — switch the incoming
//     supply OFF and take the insulated tool (lesson point 2's safety tip;
//     film S5_03), then tighten the loose terminal.
//   • মিটার জোরে চলছে — the meter is fine (myth 1): the house's load — an old
//     fridge or an earth leakage — keeps drawing power. Choose: explain to
//     the customer politely and simply (pro tip 4), keep the company seal
//     intact (pro tip 3; film S5_02).
//   • যন্ত্র পুড়ে গেছে — the LT line's neutral is cut (lesson point 3; film
//     S3_03: the line's neutral, not the drop) → dangerous voltage swings.
//     Choose: repair the line's neutral only after shutdown, test, earth; never
//     a bare hand on a neutral (myth 2).
// Every call: inspect the four spots (the LT line at the pole, the service
// cable, the meter box, the house's load through the window) and find the
// fault before acting (lesson point 1's daily check: "অভিযোগ পরীক্ষা করার সময়
// দেখুন").
//
// Deadly (lesson): a bare hand on the neutral ("নিউট্রাল তো মরা" — myth 2);
// a bare-metal tool on the live meter terminals (the box is a live panel).
// Slips: acting before the fault was found (or on the wrong load); the supply
// left ON; a plain tool (on any terminal of the panel); blaming the meter;
// cutting the seal; being rude; the wrong neutral (the drop's) or the wrong
// fix. Three slips strike out. Tightening a sound terminal safely is only
// needless: no slip, but the clean play loses its top stars.
//
// The careless coworker comes once a play on his call, while his push still
// fits: on the fast-meter call after the first look, "সিলটা কেটে দেখে নাও"
// (listening = the seal cut, a slip); on the burnt call once the LT line was
// looked at, "নিউট্রাল তো মরা, খালি হাতে ধরো" (listening = deadly: a bare hand
// on the neutral is on MODULE3_LADDER's deadly list). সিদ্ধান্ত নিই waits for
// him (holdForCoworker), so a fast decision cannot skip him.
//
// Gesture hints (how, never what): a sweep over the four spots, the HUD
// controls or all four terminals alike; a tap only on সিদ্ধান্ত নিই once every
// spot was looked at. Look tags and rings are one neutral colour.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_meter_call_world.dart), corner guide, ◆ on the table → "কেন …?" →
// the next call by itself. Voice: the guide's lines by device TTS; the
// coworker's exit line is recorded, his two pushes are not yet (the kit shows
// an unrecorded push as a held caption, never in the device voice).
//
// Praise window: the scene, the HUD and his arrival all wait while a right
// move's ◆ is on the table ([ReasonTable.tableBusy]).
//
// Flagged to the owner: how the meter's incoming supply is switched off is
// not in the lesson (a HUD switch "ইনকামিং", no device drawn); where the
// meter terminal sits relative to the sealed cover is not modelled; the
// neutral repair is shown only as "shutdown, test, earth, then" (the brief's
// line-work rule; the lesson gives no repair procedure).

// ============================================================================
// Content
// ============================================================================

/// The complaint.
enum M3MeterCallKind { flicker, fastMeter, burnt }

/// The fast meter's real cause (myth 1).
enum M3MeterCallCause { fridge, leak }

/// The tool in hand on the flicker call.
enum M3MeterCallTool { none, insulated, plain }

/// What a tap on a terminal did.
enum M3MeterCallTap { tight, needTool, mistake, fixed }

@immutable
class M3MeterCallCase {
  const M3MeterCallCase({
    required this.id,
    required this.kind,
    this.loose = M3MeterCallTerm.pIn,
    this.cause = M3MeterCallCause.fridge,
    this.breakRight = false,
    this.look = 0,
  });

  final String id;
  final M3MeterCallKind kind;

  /// [M3MeterCallKind.flicker]: the loose terminal.
  final M3MeterCallTerm loose;

  /// [M3MeterCallKind.fastMeter]: what really draws the power.
  final M3MeterCallCause cause;

  /// [M3MeterCallKind.burnt]: the cut is on the span over the house.
  final bool breakRight;

  /// The house's colours (0–2).
  final int look;

  /// Where the fault is.
  M3MeterCallSpot get fault => switch (kind) {
        M3MeterCallKind.flicker => M3MeterCallSpot.meter,
        M3MeterCallKind.fastMeter => M3MeterCallSpot.house,
        M3MeterCallKind.burnt => M3MeterCallSpot.line,
      };

  M3MeterCallRoom get room => switch (kind) {
        M3MeterCallKind.flicker => M3MeterCallRoom.lamp,
        M3MeterCallKind.fastMeter => cause == M3MeterCallCause.fridge ? M3MeterCallRoom.fridge : M3MeterCallRoom.leak,
        M3MeterCallKind.burnt => M3MeterCallRoom.burnt,
      };
}

abstract final class M3MeterCallLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askFlicker, askFast, askBurnt];

  static const title = 'গ্রাহকের ডাক';
  static const intro = 'আজ তিন বাড়ি থেকে অভিযোগ। দেখে, বুঝে, নিরাপদে সারান।';
  static const rounds = ['ক', 'খ', 'গ'];
  static const askFlicker = 'এই বাড়িতে আলো কাঁপছে। সমস্যা খুঁজে সারান।';
  static const askFast = 'গ্রাহক বলছেন মিটার খুব জোরে চলছে। দোষ খুঁজুন।';
  static const askBurnt = 'এই বাড়িতে টিভি-ফ্যান পুড়ে গেছে। কারণ খুঁজুন।';
  static String ask(M3MeterCallKind k) => switch (k) {
        M3MeterCallKind.flicker => askFlicker,
        M3MeterCallKind.fastMeter => askFast,
        M3MeterCallKind.burnt => askBurnt,
      };
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const tapAct = ['কী করবেন, বেছে নিন।', 'কোন কাজটা ঠিক?'];
  static const actAsk = 'কী করবেন?';

  // Labels a worker reads.
  static const sceneLabel = 'পোল, কেবিল, মিটার আর বাড়ি';
  static const supplyOn = 'ইনকামিং ON';
  static const supplyOff = 'ইনকামিং OFF';
  static const insulated = 'ইনসুলেটেড টুল';
  static const plain = 'সাধারণ টুল';
  static const decide = 'সিদ্ধান্ত নিই';

  // What a look shows (a short tag at the spot).
  static String finding(M3MeterCallCase c, M3MeterCallSpot s) => switch (s) {
        M3MeterCallSpot.line => c.kind == M3MeterCallKind.burnt ? 'এলটি লাইনের নিউট্রাল কাটা!' : 'এলটি লাইন ঠিক আছে',
        M3MeterCallSpot.cable => 'কেবিল অক্ষত, টান বিয়ারারে',
        M3MeterCallSpot.meter => c.kind == M3MeterCallKind.flicker ? 'টার্মিনাল ঢিলা, গরম দাগ!' : 'সিল অক্ষত, মিটার ঠিক',
        M3MeterCallSpot.house => switch (c.kind) {
            M3MeterCallKind.flicker => 'ঘরে আলো কাঁপছে',
            M3MeterCallKind.fastMeter => c.cause == M3MeterCallCause.fridge ? 'পুরোনো ফ্রিজ, চলছেই!' : 'ঘরে আর্থ লিকেজ!',
            M3MeterCallKind.burnt => 'যন্ত্র পুড়ে গেছে',
          },
      };
  static const tight = 'টাইট আছে';

  // The action deck (fast meter, burnt). 35–45 letters each. No word sits
  // only on the right cards (a test splits every right card into words):
  // the wrong ones share the cause, "ধীরে বুঝিয়ে", the LT line, "কাটা" and
  // "শাটডাউন, টেস্ট, আর্থ", so the pick is the real decision (the load seen
  // at the window; polite or not; which neutral; bare hand or not).
  static const fastLeak = ['ঘরে আর্থ লিকেজ — গ্রাহককে ধীরে বুঝিয়ে বলি', 'মিটার নয়, লিকেজ — ভদ্রভাবে সহজ করে বোঝাই'];
  static const fastFridge = ['পুরোনো ফ্রিজ খরচ বাড়ায় — ধীরে বুঝিয়ে বলি', 'মিটার নয়, ফ্রিজ — ভদ্রভাবে সহজ করে বোঝাই'];
  static const fastNewMeter = 'মিটারই খারাপ — ধীরে বুঝিয়ে বলি, নতুন দিই';
  static const fastSeal = 'সিল কেটে মিটারের ভেতরটা খুলে দেখে নিই';
  static const fastScoldLeak = 'ঘরে আর্থ লিকেজ — গ্রাহককে ধমকে দোষ দিই';
  static const fastScoldFridge = 'পুরোনো ফ্রিজ খরচ বাড়ায় — ধমকে দোষ দিই';
  static const fastWalk = 'কিছু না বলে চুপচাপ গাড়িতে ফিরে আসি';
  static const burntRight = ['এলটি লাইনের নিউট্রাল কাটা — শাটডাউনে সারাই', 'লাইনের নিউট্রাল সারাই — শাটডাউন, টেস্ট, আর্থ'];
  static const burntDrop = 'ড্রপের নিউট্রাল সারাই — শাটডাউন, টেস্ট, আর্থ';
  static const burntBare = 'এলটি লাইনের নিউট্রাল কাটা — খালি হাতে জুড়ি';
  static const burntMeter = 'শাটডাউনে মিটারটাই খুলে নতুন লাগিয়ে দিই';
  static const burntCustomer = 'গ্রাহকের যন্ত্রই খারাপ — ওঁরাই বদলে নিন';

  static List<String> actRight(M3MeterCallCase c) => c.kind == M3MeterCallKind.burnt ? burntRight : (c.cause == M3MeterCallCause.leak ? fastLeak : fastFridge);
  static List<String> actWrong(M3MeterCallCase c) => [...actWrongMistake(c).keys];

  /// Each wrong action and the mistake it books. On the fast meter the other
  /// cause's polite explanation is wrong too (the window shows which load).
  static Map<String, DoMistake> actWrongMistake(M3MeterCallCase c) => c.kind == M3MeterCallKind.burnt
      ? {
          burntDrop: M3MeterCallMistakes.dropNeutral,
          burntBare: M3MeterCallMistakes.bareNeutral,
          burntMeter: M3MeterCallMistakes.neutralMissed,
          burntCustomer: M3MeterCallMistakes.neutralMissed,
          fastSeal: M3MeterCallMistakes.sealCut,
        }
      : {
          fastNewMeter: M3MeterCallMistakes.meterBlamed,
          fastSeal: M3MeterCallMistakes.sealCut,
          (c.cause == M3MeterCallCause.leak ? fastScoldLeak : fastScoldFridge): M3MeterCallMistakes.rude,
          (c.cause == M3MeterCallCause.leak ? fastFridge : fastLeak).last: M3MeterCallMistakes.noLook,
          fastWalk: M3MeterCallMistakes.rude,
        };

  // The reasons: the right ones fit what was done; the wrong ones are field
  // excuses and myths. 37–49 letters each.
  static String whyAsk(M3MeterCallKind k) => switch (k) {
        M3MeterCallKind.flicker => 'কেন সাপ্লাই বন্ধ করে, ইনসুলেটেড টুলে?',
        M3MeterCallKind.fastMeter => 'কেন মিটার না খুলে বুঝিয়ে বললেন?',
        M3MeterCallKind.burnt => 'কেন লাইনের নিউট্রাল, আর শাটডাউনে?',
      };
  static const flickerWhy = ['মিটার বক্স লাইভ প্যানেল, তাই বন্ধ ও ইনসুলেটেড টুল', 'ঢিলা টার্মিনালে আলো কাঁপে, গরমে আগুনও লাগে'];
  static const flickerMyths = [
    'গ্রাহক তাড়া দিচ্ছিলেন, তাই তাড়াতাড়ি সারলাম',
    'মিটারের তারে অল্প কারেন্ট, ভয়ের কিছু নেই',
    'ঢিলা টার্মিনাল এমনিতেই একসময় ঠিক হয়ে যায়',
    'আলো কাঁপা মানেই বাল্ব খারাপ, তাই দেখে নিলাম',
    'সাথী বলেছিল, তাই কিছু না ভেবেই করে দিলাম',
  ];
  static const fastWhy = ['মিটার দ্রুত চলা মানেই মিটার খারাপ নয়, দোষ ঘরের', 'সিল অক্ষত রেখে ভদ্রভাবে বোঝানোই আমার কাজ'];
  static const fastWhyLeak = 'আর্থ লিকেজে বিদ্যুৎ ক্রমাগত খরচ হতেই থাকে';
  static const fastWhyFridge = 'পুরোনো ফ্রিজ ক্রমাগত বিদ্যুৎ খরচ করতে থাকে';
  static const fastMyths = [
    'মিটার খোলা ঝামেলার, তাই কথায় সেরে দিলাম',
    'নতুন মিটার আনতে দেরি হবে, তাই বুঝিয়ে দিলাম',
    'গ্রাহকরা সবসময় বাড়িয়ে বলেন, তাই এড়ালাম',
    'সিল কাটলে কেউ টের পায় না, তবু ছেড়ে দিলাম',
    'আজ সময় নেই, অন্যদিন মিটারটা খুলে দেখব',
  ];
  static const burntWhy = ['লাইনের নিউট্রাল কাটায় ভোল্টেজ ওঠানামা করে', 'ফল্টে নিউট্রালও প্রাণঘাতী, তাই আগে শাটডাউন'];
  static const burntMyths = [
    'ড্রপ কেবিল বদলাতে খরচ বেশি, তাই লাইনেরটা',
    'শাটডাউন নিলে কাজটা নিজে থেকেই সেরে যায়',
    'গ্রাহকের যন্ত্রগুলো পুরোনো, তাই পুড়ে গেছে',
    'মিটারের ভুলেই যন্ত্র পোড়ে, তাই লাইন দেখছি',
    'সুপারভাইজার বলেছেন, তাই কিছু না ভেবেই করি',
  ];

  static List<String> whyRight(M3MeterCallCase c) => switch (c.kind) {
        M3MeterCallKind.flicker => flickerWhy,
        M3MeterCallKind.fastMeter => [...fastWhy, c.cause == M3MeterCallCause.leak ? fastWhyLeak : fastWhyFridge],
        M3MeterCallKind.burnt => burntWhy,
      };
  static List<String> whyWrong(M3MeterCallCase c) => switch (c.kind) {
        M3MeterCallKind.flicker => flickerMyths,
        M3MeterCallKind.fastMeter => fastMyths,
        M3MeterCallKind.burnt => burntMyths,
      };

  /// The careless coworker: cut the seal (fast meter) / a bare hand on the
  /// neutral (burnt).
  static const exitLine = 'হুঁ! যা খুশি করুন।';
  static const coworkerSeal = CoworkerScript(
    line: 'মিটারটাই খারাপ! সিলটা কেটে দেখে নাও, কে দেখছে?',
    exitLine: exitLine,
    right: ['না, সিল ভাঙব না — আগে ঘরের লোড', 'না, সিল অক্ষত থাকবে, দোষ খুঁজি', 'না, সিল কাটা মানে ট্যাম্পারিং'],
    wrong: ['ঠিক আছে, সিলটা কেটে দেখে নিই', 'হ্যাঁ, মিটারই খারাপ, খুলে ফেলি', 'আচ্ছা, সিল পরে লাগালেই হবে', 'ঠিক বলেছ, কেউ তো এখন দেখছে না', 'তাড়া আছে, সিল কেটেই দেখে নিই'],
    asks: ['ও সিল কাটতে বলছে। আপনি কী করবেন?', 'সিল কাটবেন?', 'সিল ভাঙবেন, না আগে দোষ খুঁজবেন?'],
  );
  static const coworkerNeutral = CoworkerScript(
    line: 'নিউট্রাল তো মরা, খালি হাতে ধরো! দেরি কীসের?',
    exitLine: exitLine,
    right: ['না, নিউট্রালও প্রাণঘাতী হতে পারে', 'খালি হাতে নয় — আগে শাটডাউন', 'না, ফল্টে নিউট্রালেও ফেজ ভোল্টেজ'],
    wrong: ['ঠিক, নিউট্রালে কারেন্ট নেই, ধরি', 'আচ্ছা, খালি হাতেই জুড়ে দিচ্ছি', 'হ্যাঁ, নিউট্রাল ধরলে কিছু হয় না', 'তাড়া আছে, হাতেই ধরে ফেলছি', 'ঠিক বলেছ, গ্লাভস তো লাগবে না'],
    asks: ['ও খালি হাতে ধরতে বলছে। আপনি কী করবেন?', 'নিউট্রাল খালি হাতে ধরবেন?', 'ধরবেন, না আগে শাটডাউন?'],
  );

  static const callHeldSeal = 'ঠিক! সিল অক্ষত — আগে আসল দোষ।';
  static const callHeldNeutral = 'ঠিক! নিউট্রালও প্রাণ নিতে পারে।';
  static const allSet = 'তিন বাড়ির অভিযোগ মিটল — দেখে, বুঝে, নিরাপদে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে দোষ খুঁজুন, তারপর নিরাপদে কাজ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  static String stamp(M3MeterCallKind k) => switch (k) {
        M3MeterCallKind.flicker => 'টার্মিনাল টাইট',
        M3MeterCallKind.fastMeter => 'গ্রাহক বুঝলেন',
        M3MeterCallKind.burnt => 'শাটডাউনের ডাক',
      };

  // "আজ যা ধরলেন".
  static const caughtLoose = 'ঢিলা টার্মিনাল ধরেছেন';
  static const caughtSafeTool = 'বন্ধ করে, ইনসুলেটেড টুলে';
  static const caughtLoad = 'মিটার নয়, ঘরের লোড';
  static const caughtPolite = 'ভদ্রভাবে বুঝিয়েছেন';
  static const caughtNeutral = 'লাইনের নিউট্রাল কাটা ধরেছেন';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M3MeterCallMistakes {
  static const _dir = 'assets/game/art/m3_meter_call';

  static const noLook = DoMistake(
    key: '3.8/m3_meter_call/no-look',
    textBn: 'দোষটা না খুঁজেই সিদ্ধান্ত নিলেন। পোল, কেবিল, মিটার, ঘর — আগে দেখুন, তারপর কাজ।',
    art: '$_dir/no_look.svg',
    lessonPoint: 2,
  );
  static const supplyOn = DoMistake(
    key: '3.8/m3_meter_call/supply-on',
    textBn: 'মিটার বক্স লাইভ প্যানেল। টার্মিনালে হাত দেওয়ার আগে ইনকামিং সাপ্লাই বন্ধ করুন।',
    art: '$_dir/supply_on.svg',
    lessonPoint: 1,
  );
  static const plainTool = DoMistake(
    key: '3.8/m3_meter_call/plain-tool',
    textBn: 'মিটার বক্সে কাজ মানেই ইনসুলেটেড টুলস। সাধারণ ধাতুর টুল এখানে নয়।',
    art: '$_dir/plain_tool.svg',
    lessonPoint: 1,
  );
  static const livePlainTool = DoMistake(
    key: '3.8/m3_meter_call/live-plain-tool',
    textBn: 'চালু লাইভ প্যানেলে খালি ধাতুর টুল! আগে ইনকামিং বন্ধ, হাতে ইনসুলেটেড টুল — তবেই টার্মিনাল।',
    art: '$_dir/live_plain_tool.svg',
    deadly: true,
    lessonPoint: 1,
  );

  /// Myth 1 (not a lesson point: "পাঠে দেখুন" opens the lesson start).
  static const meterBlamed = DoMistake(
    key: '3.8/m3_meter_call/meter-blamed',
    textBn: 'মিটার দ্রুত চলা মানেই মিটার খারাপ নয়। বেশিরভাগ সময় দোষ ঘরের — পুরোনো যন্ত্র বা আর্থ লিকেজ। আগে লোড দেখুন।',
    art: '$_dir/meter_blamed.svg',
  );

  /// Pro tip 3.
  static const sealCut = DoMistake(
    key: '3.8/m3_meter_call/seal-cut',
    textBn: 'কোম্পানির সিল ভাঙা মানেই মিটার ট্যাম্পারিং-এর সন্দেহ। সিল অক্ষত রেখে কাজ করুন।',
    art: '$_dir/seal_cut.svg',
  );

  /// Pro tip 4.
  static const rude = DoMistake(
    key: '3.8/m3_meter_call/rude',
    textBn: 'আপনিই কোম্পানির মুখ। ধৈর্য আর ভদ্রতায় গ্রাহককে সমস্যাটা সহজ ভাষায় বোঝান।',
    art: '$_dir/rude.svg',
  );
  static const dropNeutral = DoMistake(
    key: '3.8/m3_meter_call/drop-neutral',
    textBn: 'ড্রপ কেবিল ঠিক ছিল — কাটা এলটি লাইনের নিউট্রাল। ওটা না সারালে ভোল্টেজের তারতম্য থামবে না।',
    art: '$_dir/drop_neutral.svg',
    lessonPoint: 2,
  );
  static const neutralMissed = DoMistake(
    key: '3.8/m3_meter_call/neutral-missed',
    textBn: 'যন্ত্র পোড়ার কারণ এলটি লাইনের নিউট্রাল কাটা — বিপজ্জনক ভোল্টেজ তারতম্য। মিটার বা গ্রাহক দোষী নন।',
    art: '$_dir/neutral_missed.svg',
    lessonPoint: 2,
  );

  /// Myth 2.
  static const bareNeutral = DoMistake(
    key: '3.8/m3_meter_call/bare-neutral',
    textBn: 'নিউট্রাল “মরা” নয়! আনব্যালেন্স বা ফল্টে নিউট্রালেও ফেজের সমান ভোল্টেজ। খালি হাতে কখনো নয়।',
    art: '$_dir/bare_neutral.svg',
    deadly: true,
  );

  static List<DoMistake> get all => [noLook, supplyOn, plainTool, livePlainTool, meterBlamed, sealCut, rude, dropNeutral, neutralMissed, bareNeutral];
}

@immutable
class M3MeterCallDeal {
  const M3MeterCallDeal({required this.cases, required this.callAt});
  final List<M3MeterCallCase> cases;

  /// The call the careless coworker comes on (the fast meter or the burnt).
  final int callAt;
}

/// Three calls, one of each kind, in a fresh order; a fresh loose terminal,
/// cause, break and house colours; the coworker on the fast-meter or the
/// burnt call.
M3MeterCallDeal dealM3MeterCall(math.Random rng) {
  final kinds = [...M3MeterCallKind.values]..shuffle(rng);
  final looks = [0, 1, 2]..shuffle(rng);
  final cases = <M3MeterCallCase>[
    for (var i = 0; i < 3; i++)
      M3MeterCallCase(
        id: 'c$i',
        kind: kinds[i],
        loose: M3MeterCallTerm.values[rng.nextInt(4)],
        cause: M3MeterCallCause.values[rng.nextInt(2)],
        breakRight: rng.nextBool(),
        look: looks[i],
      ),
  ];
  final can = [
    for (final (i, c) in cases.indexed)
      if (c.kind != M3MeterCallKind.flicker) i,
  ];
  return M3MeterCallDeal(cases: cases, callAt: can[rng.nextInt(can.length)]);
}

/// The play state (pure logic).
class M3MeterCallRun {
  M3MeterCallRun(this.deal) {
    _startRound();
  }

  final M3MeterCallDeal deal;
  int index = 0;

  final Set<M3MeterCallSpot> looked = {};
  var supplyOn = true;
  var tool = M3MeterCallTool.none;
  var fixed = false;

  var shown = false;
  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  M3MeterCallCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !shown;

  /// The fault's spot was looked at.
  bool get found => looked.contains(current.fault);

  /// The +5: every spot looked at before acting.
  bool get thorough => looked.length == M3MeterCallSpot.values.length;

  /// Needless work on a sound terminal (switched off, insulated tool): no
  /// slip, but a clean play loses its top stars.
  int needless = 0;

  void _startRound() {
    looked.clear();
    supplyOn = true;
    tool = M3MeterCallTool.none;
    fixed = false;
    shown = false;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Look at [s]: what it shows (null when the call is over).
  String? inspect(M3MeterCallSpot s) {
    if (!_open) return null;
    looked.add(s);
    return M3MeterCallLines.finding(current, s);
  }

  void toggleSupply() {
    if (!_open) return;
    supplyOn = !supplyOn;
  }

  void pickTool(M3MeterCallTool t) {
    if (!_open) return;
    tool = tool == t ? M3MeterCallTool.none : t;
  }

  /// The flicker call: the tool on terminal [t] (after the meter was looked
  /// at). [mistake] is set when it went wrong. Without a tool nothing happens
  /// (and nothing is revealed). A tool on any terminal of the live panel
  /// counts: a plain tool with the supply ON is deadly, a plain tool or the
  /// supply ON a slip — on a sound terminal too. Done safely on a sound
  /// terminal it is only needless ([needless]; "টাইট আছে").
  DoMistake? mistake;
  M3MeterCallTap? tapTerminal(M3MeterCallTerm t) {
    mistake = null;
    if (!_open || current.kind != M3MeterCallKind.flicker || !looked.contains(M3MeterCallSpot.meter)) return null;
    if (tool == M3MeterCallTool.none) return M3MeterCallTap.needTool;
    if (t != current.loose && tool == M3MeterCallTool.insulated && !supplyOn) {
      needless++;
      return M3MeterCallTap.tight;
    }
    shown = true;
    if (tool == M3MeterCallTool.plain && supplyOn) {
      mistake = deadly = M3MeterCallMistakes.livePlainTool;
      return M3MeterCallTap.mistake;
    }
    if (tool == M3MeterCallTool.plain) {
      slips++;
      mistake = M3MeterCallMistakes.plainTool;
      return M3MeterCallTap.mistake;
    }
    if (supplyOn) {
      slips++;
      mistake = M3MeterCallMistakes.supplyOn;
      return M3MeterCallTap.mistake;
    }
    fixed = true;
    _tag(M3MeterCallLines.caughtLoose);
    _tag(M3MeterCallLines.caughtSafeTool);
    return M3MeterCallTap.fixed;
  }

  /// The fast-meter or burnt call: the action picked on the deck.
  DoMistake? choose(String option) {
    if (!_open) return null;
    final c = current;
    shown = true;
    if (M3MeterCallLines.actRight(c).contains(option)) {
      if (!found) {
        slips++;
        return M3MeterCallMistakes.noLook;
      }
      if (c.kind == M3MeterCallKind.burnt) {
        _tag(M3MeterCallLines.caughtNeutral);
      } else {
        _tag(M3MeterCallLines.caughtLoad);
        _tag(M3MeterCallLines.caughtPolite);
      }
      return null;
    }
    final m = M3MeterCallLines.actWrongMistake(c)[option] ?? M3MeterCallMistakes.noLook;
    if (m.deadly) return deadly = m;
    slips++;
    return m;
  }

  /// Listened to the coworker on his call.
  DoMistake? listen() {
    if (!_open) return null;
    shown = true;
    if (current.kind == M3MeterCallKind.burnt) return deadly = M3MeterCallMistakes.bareNeutral;
    slips++;
    return M3MeterCallMistakes.sealCut;
  }

  void next() {
    index++;
    if (!done) _startRound();
  }
}

/// The quick bonus: a little under a thorough play (~85 %). A thorough call
/// (ms): the ask ~3500; four looks × 1500; the action (flicker: switch, tool,
/// terminal ~4500; the deck: rise 1500 + read 3000); the reason ~8200; the
/// move on ~1200 ≈ 24000. Three calls ≈ 72000, the coworker ~9600 ≈ 81600;
/// 85 % ≈ 70 s.
const kM3MeterCallQuickMs = 70000;

@immutable
class M3MeterCallPack {
  const M3MeterCallPack({required this.id, required this.titleBn, this.quickMs = kM3MeterCallQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3MeterCallPacks = {
  'do_3_8_b': M3MeterCallPack(id: 'do_3_8_b', titleBn: M3MeterCallLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3MeterCallPage extends StatefulWidget {
  const M3MeterCallPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3MeterCallPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3MeterCallPage> createState() => _M3MeterCallPageState();
}

class _M3MeterCallPageState extends State<M3MeterCallPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CallRunPage(
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

class _CallRunPage extends ConsumerStatefulWidget {
  const _CallRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3MeterCallPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CallRunPage> createState() => _CallRunPageState();
}

class _CallRunPageState extends ConsumerState<_CallRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3MeterCallRun _run = M3MeterCallRun(dealM3MeterCall(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  var _stamped = false;
  var _coworkerArmed = false;

  /// What each looked-at spot showed (this call).
  final Map<M3MeterCallSpot, String> _tags = {};

  /// A "টাইট আছে" tag on a terminal for a moment.
  M3MeterCallTerm? _tightAt;
  Timer? _tightTimer;

  /// The tool's tip on a terminal (the flicker call).
  M3MeterCallTerm? _toolAt;

  // The action deck.
  var _actOpen = false;
  List<ChoiceOption> _actOpts = const [];
  String? _actWrong;
  String? _actPicked;
  int _actN = 0;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // The gesture hint (how to touch, never what): the HUD controls it sweeps.
  final _hints = IdleHintController();
  final _supplyKey = GlobalKey();
  final _insulatedKey = GlobalKey();
  final _plainKey = GlobalKey();
  final _decideKey = GlobalKey();
  // Which side each tool sits on, shuffled per call (no giveaway order).
  var _toolOrder = const [M3MeterCallTool.insulated, M3MeterCallTool.plain];

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _tightTimer?.cancel();
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

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !_actOpen && !_run.shown;

  void _startRound() {
    _tightTimer?.cancel();
    setState(() {
      _stamped = false;
      _tags.clear();
      _tightAt = null;
      _toolAt = null;
      _actOpen = false;
      _actWrong = null;
      _actPicked = null;
      _toolOrder = widget.rng.nextBool()
          ? const [M3MeterCallTool.insulated, M3MeterCallTool.plain]
          : const [M3MeterCallTool.plain, M3MeterCallTool.insulated];
      _wake++;
    });
    unawaited(_sayChain([M3MeterCallLines.ask(_run.current.kind)]));
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p, M3MeterCallGeo geo) {
    if (!_canPlay) return;
    final c = _run.current;
    // The flicker call, the meter looked at: the terminals take the tool.
    if (c.kind == M3MeterCallKind.flicker && _run.looked.contains(M3MeterCallSpot.meter)) {
      for (final t in M3MeterCallTerm.values) {
        if (geo.terminalHit(t).contains(p)) {
          _terminal(t);
          return;
        }
      }
    }
    for (final s in M3MeterCallSpot.values) {
      if (geo.spotHit(s).contains(p)) {
        _look(s);
        return;
      }
    }
    _hints.missTap();
  }

  void _look(M3MeterCallSpot s) {
    final tag = _run.inspect(s);
    if (tag == null) return;
    HapticFeedback.selectionClick();
    // One sound for every look: the fault is read from the tag, not heard.
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    setState(() {
      _tags[s] = tag;
      _wake++;
    });
    // His moment, while his push still fits: on the fast meter after the
    // first look; on the burnt call once the LT line was looked at (he talks
    // about the neutral). A fast decision brings him in too ([_openAct]).
    final burnt = _run.current.kind == M3MeterCallKind.burnt;
    if (!burnt || s == M3MeterCallSpot.line) _armCoworker();
  }

  /// Schedules him once, on his call.
  void _armCoworker() {
    if (_coworkerArmed || _run.index != _run.deal.callAt) return;
    _coworkerArmed = true;
    scheduleCoworker();
  }

  void _terminal(M3MeterCallTerm t) {
    final r = _run.tapTerminal(t);
    if (r == null) return;
    HapticFeedback.selectionClick();
    switch (r) {
      case M3MeterCallTap.tight:
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        _tightTimer?.cancel();
        setState(() => _tightAt = t);
        _tightTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _tightAt = null);
        });
      case M3MeterCallTap.needTool:
        _cue('sounds/intro/tick.ogg', volume: 0.5);
        _hints.missTap();
        setState(() => _wake++);
      case M3MeterCallTap.mistake:
        setState(() => _toolAt = t);
        unawaited(_afterMistake(_run.mistake!, _mid));
      case M3MeterCallTap.fixed:
        setState(() => _toolAt = t);
        unawaited(_success(_mid));
    }
  }

  /// Where a score from the scene flies from (the screen's middle).
  Offset get _mid {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.5);
  }

  void _toggleSupply() {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    _run.toggleSupply();
    setState(() => _wake++);
  }

  void _pickTool(M3MeterCallTool t) {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    _run.pickTool(t);
    setState(() => _wake++);
  }

  // --- the action deck --------------------------------------------------------------
  void _openAct() {
    if (!_canPlay) return;
    // The decisive control: on his call he comes before the deck, even when
    // the player decides at once.
    _armCoworker();
    if (holdForCoworker()) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.5);
    final c = _run.current;
    setState(() {
      _actOpen = true;
      _actWrong = null;
      _actPicked = null;
      _actOpts = dealChoices(M3MeterCallLines.actRight(c), M3MeterCallLines.actWrong(c), widget.rng);
    });
    unawaited(_sayChain([M3MeterCallLines.actAsk]));
  }

  Future<void> _onAct(ChoiceOption o, Offset origin) async {
    if (!_actOpen || _actWrong != null || _actPicked != null || _ended) return;
    setState(() => o.correct ? _actPicked = o.textBn : _actWrong = o.textBn);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _actOpen = false);
    final m = _run.choose(o.textBn);
    if (m == null) {
      await _success(origin);
      return;
    }
    await _afterMistake(m, origin);
  }

  // --- right and wrong ------------------------------------------------------------------
  Future<void> _success(Offset origin) async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    setState(() {
      _stamped = true;
      _wake++;
    });
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final c = _run.current;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M3MeterCallLines.whyRight(c), M3MeterCallLines.whyWrong(c), widget.rng),
      question: M3MeterCallLines.whyAsk(c.kind),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Future<void> _afterMistake(DoMistake m, Offset origin) async {
    _hush();
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  CoworkerScript get _script => _run.deal.cases[_run.deal.callAt].kind == M3MeterCallKind.burnt ? M3MeterCallLines.coworkerNeutral : M3MeterCallLines.coworkerSeal;
  @override
  CoworkerScript get coworkerScript => _script;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_intro || _busy || _card != null || tableBusy || _actOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listen();
      if (m != null) await _afterMistake(m, origin);
      return;
    }
    if (!_run.caught.contains(M3MeterCallLines.caughtCall)) _run.caught.add(M3MeterCallLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (!mounted || _ended) return;
    unawaited(_sayChain([_run.current.kind == M3MeterCallKind.burnt ? M3MeterCallLines.callHeldNeutral : M3MeterCallLines.callHeldSeal]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3MeterCallLines.tapWhy[_nudgeN++ % M3MeterCallLines.tapWhy.length]
            : _actOpen
                ? M3MeterCallLines.tapAct[_actN++ % M3MeterCallLines.tapAct.length]
                : _nudge.next(M3MeterCallLines.ask(_run.current.kind));
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
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
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m3call/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// The scene freezes grey and the flash plays in colour (at the terminal,
  /// or at the cut neutral); then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() => _freeze = true);
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m3call/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3MeterCallLines.deadlyWord : M3MeterCallLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        _next();
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
      if (mark == 100 && _run.needless == 0 && _clock.elapsedMilliseconds < widget.pack.quickMs) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    // Needless work on a sound terminal costs the top stars (not a slip).
    final stars = starsFor(passed: _run.passed, strikes: strikes + _run.needless, quick: _clock.elapsedMilliseconds < widget.pack.quickMs);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M3MeterCallLines.fail : (_quickBonus ? M3MeterCallLines.quick : M3MeterCallLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_stamped) return LinemanMode.cheer;
    if (_run.current.kind == M3MeterCallKind.flicker && _run.tool != M3MeterCallTool.none) return LinemanMode.hold;
    return LinemanMode.point;
  }

  Offset _zap(M3MeterCallGeo geo) {
    final c = _run.current;
    if (c.kind == M3MeterCallKind.burnt) return Offset(geo.breakX(c.breakRight), geo.neutralY + 24);
    return geo.terminal(c.loose);
  }

  /// The scene's geometry as last laid out (for the gesture hint).
  M3MeterCallGeo? _geo;

  /// Which waiting state the hint is for (a new one resets its count).
  String get _hintStage {
    if (_run.done) return 'done';
    final c = _run.current;
    if (c.kind == M3MeterCallKind.flicker && _run.looked.contains(M3MeterCallSpot.meter)) {
      return _run.tool == M3MeterCallTool.none ? 'hud' : 'terminals';
    }
    if (c.kind != M3MeterCallKind.flicker && _run.thorough) return 'decide';
    return 'spots';
  }

  /// The gesture hint (how to touch, never what): a sweep over the four
  /// spots, over the HUD controls, or over all four terminals alike; a tap
  /// only on সিদ্ধান্ত নিই once every spot was looked at (the one way on).
  HintSpec? _hint() {
    final geo = _geo;
    if (geo == null) return null;
    return switch (_hintStage) {
      'hud' => HintSpec.sweepOver([_supplyKey, for (final t in _toolOrder) t == M3MeterCallTool.insulated ? _insulatedKey : _plainKey]),
      'terminals' => HintSpec.sweep([for (final t in M3MeterCallTerm.values) geo.terminalHit(t)], space: HintSpace.scene),
      'decide' => HintSpec.tapOn(_decideKey),
      'spots' => HintSpec.sweep([for (final s in M3MeterCallSpot.values) geo.spotHit(s).intersect(Rect.fromLTWH(0, 0, 360, geo.height))], space: HintSpace.scene),
      _ => null,
    };
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M3MeterCallGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final tb = geo.trainee;
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final meterLooked = _run.looked.contains(M3MeterCallSpot.meter);
    final flicker = c.kind == M3MeterCallKind.flicker;
    final toolTip = _toolAt == null ? null : geo.terminal(_toolAt!);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('land'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M3MeterCallWorldPainter(
                      geo: geo,
                      room: c.room,
                      look: c.look,
                      looked: {..._run.looked},
                      hot: flicker && meterLooked ? c.loose : null,
                      fixed: _run.fixed,
                      neutralBreak: c.kind == M3MeterCallKind.burnt ? geo.breakX(c.breakRight) : null,
                      selected: _toolAt,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: tb,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              if (toolTip != null && _run.tool != M3MeterCallTool.none && !_stamped)
                Positioned.fill(
                  key: const ValueKey('tool'),
                  child: IgnorePointer(
                    child: CustomPaint(painter: M3MeterCallToolPainter(hand: hand, tip: toolTip, insulated: _run.tool == M3MeterCallTool.insulated)),
                  ),
                ),
            ],
          ),
        ),
      ),
      // What each look showed, at the spot.
      for (final e in _tags.entries)
        Positioned(
          key: ValueKey('tag-${_run.index}-${e.key.name}'),
          left: geo.tagAt(e.key, breakRight: c.kind == M3MeterCallKind.burnt && c.breakRight).dx,
          top: geo.tagAt(e.key, breakRight: c.kind == M3MeterCallKind.burnt && c.breakRight).dy,
          child: IgnorePointer(child: _FindTag(text: e.value, quiet: quiet)),
        ),
      if (_tightAt != null)
        Positioned(
          key: ValueKey('tight-${_tightAt!.name}'),
          left: geo.terminal(_tightAt!).dx - 34,
          top: geo.termY - 46,
          child: const IgnorePointer(child: _FindTag(text: M3MeterCallLines.tight, quiet: true)),
        ),
      if (_stamped && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: geo.box.left - 30,
          width: geo.box.width + 20,
          top: geo.box.top + 22,
          child: IgnorePointer(child: _StampPop(text: M3MeterCallLines.stamp(c.kind), quiet: quiet)),
        ),
      // Tap a spot to look; on the flicker call, a terminal with the tool.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3MeterCallLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3MeterCallZapPainter(at: _zap(geo), v: v)),
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp || _actOpen;
    final handsOn = playing && !_run.done && !_run.shown && !deckUp && !coworkerOpen && _card == null && !tableBusy;
    final flicker = !_run.done && _run.current.kind == M3MeterCallKind.flicker;
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
              labels: M3MeterCallLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !coworkerOnScreen,
            hintKey: '${_run.index}-$_hintStage',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && flicker)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _ToolButton(
                        key: _supplyKey,
                        icon: _run.supplyOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                        label: _run.supplyOn ? M3MeterCallLines.supplyOn : M3MeterCallLines.supplyOff,
                        active: false,
                        onTap: _toggleSupply,
                      ),
                      // The two tools change sides per call: left to right is
                      // never a fixed (or the right) order.
                      for (final t in _toolOrder) ...[
                        const SizedBox(width: 4),
                        if (t == M3MeterCallTool.insulated)
                          _ToolButton(
                            key: _insulatedKey,
                            icon: Icons.build_rounded,
                            label: M3MeterCallLines.insulated,
                            active: _run.tool == M3MeterCallTool.insulated,
                            tint: const Color(0xFFE2631B),
                            onTap: () => _pickTool(M3MeterCallTool.insulated),
                          )
                        else
                          _ToolButton(
                            key: _plainKey,
                            icon: Icons.build_rounded,
                            label: M3MeterCallLines.plain,
                            active: _run.tool == M3MeterCallTool.plain,
                            tint: const Color(0xFFC9CED3),
                            onTap: () => _pickTool(M3MeterCallTool.plain),
                          ),
                      ],
                    ],
                  ),
                ),
              if (handsOn && !flicker)
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 110,
                  bottom: pad.bottom + 12,
                  child: DoBigButton(key: _decideKey, label: M3MeterCallLines.decide, filled: true, onTapUp: (_) => _openAct()),
                ),
              if (deckUp)
                Positioned(
                  key: const ValueKey('hud-deck'),
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : _actOpen
                            ? ChoiceDeck(
                                key: ValueKey('act-deck-${_run.index}'),
                                options: _actOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: {?_actWrong},
                                picked: _actPicked,
                                onPick: (o, at) => unawaited(_onAct(o, at)),
                              )
                            : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  sound: FailSound.electric,
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
                  line: M3MeterCallLines.intro,
                  alarm: 'sounds/learn/spark.ogg',
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
}

// ============================================================================
// Pieces
// ============================================================================

/// What a look showed: a small tag at the spot. Every tag looks the same —
/// the words say what was seen; no red/green verdict reads it for the player.
class _FindTag extends StatelessWidget {
  const _FindTag({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.6 + 0.4 * v, alignment: Alignment.topLeft, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xEB13233A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC9D6E6), width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_rounded, size: 13, color: Color(0xFFDDE6F0)),
            const SizedBox(width: 4),
            Flexible(child: Text(text, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory))),
          ],
        ),
      ),
    );
  }
}

/// A hands-on control: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.active, required this.onTap, this.tint});
  final IconData icon;
  final String label;
  final bool active;
  final Color? tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = active ? SlmColors.gold300 : const Color(0xFF8C96A3);
    return Semantics(
      button: true,
      label: label,
      selected: active,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)]),
                  border: Border.all(color: ring.withValues(alpha: 0.95), width: active ? 3 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 26, color: tint ?? ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: active ? const Color(0xE6403206) : const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label, textAlign: TextAlign.center, maxLines: 2, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
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
      builder: (_, v, child) => Transform.rotate(angle: -0.06, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xE6FFF8E7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SlmColors.success, width: 3),
          ),
          child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.success)),
        ),
      ),
    );
  }
}
