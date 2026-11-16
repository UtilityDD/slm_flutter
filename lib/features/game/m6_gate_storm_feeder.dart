import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kLongPressTimeout;
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
import 'content_catalog.dart';
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
import 'm6_gate_storm_feeder_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

// Module 6 rank gate (rung m6/gate, pack gate_m6, engineType
// m6_gate_storm_feeder): "ঝড়ের রাত: ফিডার ফেরান" — one feeder after a stormy
// night, one verb: drag a crew tool off the belt onto a piece of equipment
// (lessons 6.1–6.11; spec docs/module_specs/module6_items/gate_m6.json,
// rulings docs/module_specs/module6_rulings.md — the rulings win).
//
// The scene is a ~4-screen panorama panned by swipe: the substation window
// (breaker panel and relay), recloser R-12, AB-1, the road crossing where the
// main line dips into a UG cable, a pole capacitor bank (some plays), a main
// line pole, the junction pole with sectionalizer S-3 and branch A (AB-A),
// AB-2, the DTR (HG fuses, drain valve, earth strip) with its LT box, and an
// AB-cable lane to houses with veranda meters. The house windows are the live
// cue. Bottom: seven fixed, same-size belt tokens চোখ · রেডিও · হাতল ·
// আর্থ সেট · ডিসচার্জ রড · ক্রু · টেস্টার (X1 adds the tester). Top: the
// ডকেট with the call only and a plain section sketch (the chalk target); the
// wristwatch (game time; a tap waits one minute).
//
// One fault family of six is dealt (never the same twice in a row): F-A a
// permanent fault on branch A (S-3 open, rest lit), F-B on the main section
// (R-12 locked out; the operator may answer while it is still mid-cycle),
// F-C the UG crossing struck (breaker tripped, flags, short circuit), F-D a
// DTR with burnt oil (one HG gone), F-E a coordination fault (HG gone, oil
// clean, a jugaad wire in the LT box), F-F one LT way dark (HRC gone, an
// AB-cable nick with water). One engine ([M6GRun]) applies every rule to one
// moving state — no Module 6 level mechanic is replayed.
//
// Beats: guide first → A find (চোখ, then the chalk on one sketch section; ◆)
// → B make it dead (PTW by radio on every crew-up path, X1: isolators,
// চোখ on the gaps, টেস্টার 0 V, আর্থ — crew hands before the 0 V or the earth
// = deadly; the DTR: LT switch OFF first, then its AB, M6-2/X3; LT work: the
// DTR's PTW + LT switch OFF + lock + tag + 0 V, X4, and the HRC with gloves
// and the puller, A5 — no PPE after the isolation = slip; the capacitor
// bank: its switch OFF, 5 game minutes on the watch, the rod — clamp first —
// on every terminal, M6-6) → C fix the cause (ক্রু on the faulty device, a
// 'কী কাজ?' deck dealt to the cause; ◆) → D restore (earths off, AB লাগানো
// first and its blades seen, then the breaker / R-12 / S-3 / LT ON; ◆) →
// the twist in about half the plays (a house still dark). The coworker comes
// once, held by the path's decisive control; listening is deadly in every
// variant (X2). Pass: rank সিনিয়র, badge 'যন্ত্র গুরু', unlockRank(6).
//
// Scoring as the module's levels: ◆ 15 per reason, a right cause card +10
// where no reason follows, the coworker refused +10, slip −10, pass +20,
// quick bonus +10; mark 100 − 15 × slips; 3 slips strike out; a deadly move
// freezes the scene. The quick-bonus time (5 min) is the builder's estimate,
// about 85 % of a clean play (owner ruling after Wave A).
//
// Every spoken line is listed in M6GateLines.newGuideLines / newRivalLines
// (DRAFT wording — owner, M6-12).

// ============================================================================
// Content
// ============================================================================

/// The fault family (F-A … F-F).
enum M6GFam { branch, main, ug, dtrOil, coord, ltWay }

/// The sketch's sections (the chalk targets).
enum M6GSec { main, branch, dtr, lt }

/// The devices on the panorama (left to right).
/// [abT] is the tie to ফিডার-5 (normally open; sometimes left closed — the
/// main section's backfeed source, ruling M6-10). Model: ফিডার-5 tripped too
/// when the fault hit through the closed tie, so the main reads 0 V and its
/// windows stay dark, but it is not isolated — ফিডার-5 can come back on at
/// any time. Earths may go on (they guard against exactly that); crew up
/// with the tie still closed = deadly (R1).
enum M6GDev { cb, r12, ab1, ug, bank, span, s3, abA, branch, ab2, dtr, ltbox, house, abT }

/// The belt's tokens (fixed order).
enum M6GTok { eye, radio, handle, earth, rod, crew, tester }

/// The control room's requests (each device offers all of its own).
enum M6GReq { relay, cbOffPtw, cbOn, rcCount, rcNrPtw, rcNormal, s3Info, s3Open, s3Close, dtrInfo, dtrPtw, dtrOff }

/// The LT switch (MCCB) choices.
enum M6GLt { offLock, offOnly, on }

/// The crew's 'কী কাজ?' decks.
enum M6GDeck { storm, joint, oil, jugaad, hg, strip, nick, hrc, bank, twistLcd, twistBlank }

/// A card's class in a crew deck.
enum M6GCard { right, slip, deadly }

/// The ◆ questions.
enum M6GReason { find, relay, reAsk, bothEnds, tie, gaps, bank, oil, fuse, joint, restore, twistLcd, twistBlank }

/// The coworker's variants (spec letters).
enum M6GPush { a, b, c, d, e, f, g }

/// Isolators with a ground handle and a handle earth lead.
const m6gAbs = {M6GDev.ab1, M6GDev.ab2, M6GDev.abA, M6GDev.dtr, M6GDev.abT};

/// The control-room devices (the radio talks about these).
const m6gRadioDevs = {M6GDev.cb, M6GDev.r12, M6GDev.s3, M6GDev.dtr};

/// Requests that only ask (allowed before the fault is marked).
const m6gInfoReqs = {M6GReq.relay, M6GReq.rcCount, M6GReq.s3Info, M6GReq.dtrInfo};

/// The requests offered on [d].
List<M6GReq> m6gReqsOf(M6GDev d) => switch (d) {
      M6GDev.cb => const [M6GReq.relay, M6GReq.cbOffPtw, M6GReq.cbOn],
      M6GDev.r12 => const [M6GReq.rcCount, M6GReq.rcNrPtw, M6GReq.rcNormal],
      M6GDev.s3 => const [M6GReq.s3Info, M6GReq.s3Open, M6GReq.s3Close],
      M6GDev.dtr => const [M6GReq.dtrInfo, M6GReq.dtrPtw, M6GReq.dtrOff],
      _ => const [],
    };

/// The HT section a device stands on (null: no HT section — the LT side or
/// a control-room device).
M6GSec? m6gSecOf(M6GDev d) => switch (d) {
      M6GDev.ab1 || M6GDev.ug || M6GDev.bank || M6GDev.span || M6GDev.ab2 || M6GDev.abT => M6GSec.main,
      M6GDev.abA || M6GDev.branch => M6GSec.branch,
      M6GDev.dtr => M6GSec.dtr,
      M6GDev.ltbox || M6GDev.house => M6GSec.lt,
      _ => null,
    };

/// The isolators at the ends of an HT section.
List<M6GDev> m6gEndsOf(M6GSec s) => switch (s) {
      M6GSec.main => const [M6GDev.ab1, M6GDev.ab2],
      M6GSec.branch => const [M6GDev.abA],
      M6GSec.dtr => const [M6GDev.dtr],
      M6GSec.lt => const [],
    };

extension M6GFamFacts on M6GFam {
  /// The section the chalk must mark.
  M6GSec get sec => switch (this) {
        M6GFam.branch => M6GSec.branch,
        M6GFam.main || M6GFam.ug => M6GSec.main,
        M6GFam.dtrOil || M6GFam.coord => M6GSec.dtr,
        M6GFam.ltWay => M6GSec.lt,
      };

  /// The main 11 kV section is dead (the breaker tripped / R-12 locked out).
  bool get mainDead => this == M6GFam.main || this == M6GFam.ug;

  /// Spec letter (A–F).
  String get letter => 'ABCDEF'[index];
}

abstract final class M6GateLines {
  static const title = 'ঝড়ের রাত: ফিডার ফেরান';

  /// The module's badge (owner 2026-11-15, same as the lessons).
  static const badge = 'যন্ত্র গুরু';

  // The ranks (fallbacks when the catalog is not loaded).
  static const rankFrom = 'অ্যাডভান্সড';
  static const rankTo = 'সিনিয়র';
  static const rankUp = 'নতুন র‍্যাঙ্ক!';

  /// Spoken on the pass. DRAFT wording — owner.
  static String promoted(String rank) => badge.isEmpty ? 'অভিনন্দন! আপনি এখন $rank লাইনম্যান।' : 'অভিনন্দন! আপনি এখন $rank লাইনম্যান — $badge।';

  // DRAFT wording — owner (M6-12), every line below.
  static const intro = 'ঝড়ের রাতে এলাকা অন্ধকার! ফল্ট খুঁজুন, নিরাপদে সারান, ঠিক ক্রমে আলো ফেরান।';

  // The stage tasks (never name a device or a step).
  static const taskFind = 'ফল্টটা কোথায়? যন্ত্রগুলো কী বলছে, দেখুন।';
  static const taskDead = 'ক্রু কাজ ধরবে — লাইনটা সত্যি ডেড তো?';
  static const taskFix = 'এবার আসল কারণটা সারান।';
  static const taskRestore = 'আলো ফেরানোর পালা — কোনটা আগে?';
  static const taskTwist = 'আলো ফিরেছে — সব বাড়ি দেখে নিন।';
  static const taskLifted = 'কোন যন্ত্রে লাগাবেন? যন্ত্রের ওপর রাখুন।';
  static const taskChalk = 'চকটা কোন সেকশনে দেবেন?';
  static const taskRadio = 'কন্ট্রোল রুমকে কী বলবেন?';
  static const taskSend = 'রেডিও চেপে ধরে বলুন।';
  static const taskStroke = 'হাতলটা এক টানে শেষ পর্যন্ত টানুন।';
  static const taskLt = 'LT সুইচে কী করবেন?';
  static const taskRod = 'রডটা কোথায় কোথায় লাগাবেন?';
  static const taskDeck = 'কী কাজ করবেন?';
  static const taskLens = 'দেখা হলে বন্ধ করুন।';
  static const tasks = [
    taskFind, taskDead, taskFix, taskRestore, taskTwist, taskLifted, taskChalk,
    taskRadio, taskSend, taskStroke, taskLt, taskRod, taskDeck, taskLens,
  ];
  static const tapWhy = ['ঠিক কারণটা কোনটা?', 'কেন করলেন, বেছে নিন।'];

  // Soft lines (no cost).
  static const markFirst = 'আগে ফল্টটা কোথায় — ডকেটের চকে চিহ্ন দিন।';
  static const radioWhere = 'রেডিওতে কন্ট্রোল রুমের যন্ত্রের কথাই বলা যায়।';
  static const noUse = 'এই যন্ত্রে এটার কাজ নেই।';
  static const tieStays = 'টাই সুইচ খোলাই থাকে।';
  static const crewDown = 'ক্রু নেমে এল।';
  static const waited = 'এক মিনিট অপেক্ষা।';
  static const lit = 'আলো ফিরল!';
  static const refused = 'ঠিক! চাপে নিয়ম ভাঙা নয়।';
  static const fixRight = 'ঠিক কাজ!';
  static const sentShop = 'DTR লাইনের বাইরে রইল, রিপোর্ট গেল।';
  static const fail = 'আরেকবার — আগে দেখে বুঝুন, ডেড প্রমাণ করে কাজ, ঠিক ক্রমে আলো।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static String call(int feeder) => enDigits('ফিডার-$feeder · ঝড়ের পর এলাকা অন্ধকার · নিরাপদে আলো ফেরান');
  static const chalk = 'চক';
  static const send = 'চেপে ধরে বলুন';
  static const act = 'চেপে ধরে করুন';
  static const close = 'বন্ধ';
  static const radioTitle = 'রেডিও · কন্ট্রোল রুম';
  static const ltTitle = 'LT সুইচ (MCCB)';
  static const rodTitle = 'ডিসচার্জ রড';
  static const strokeOpen = 'AB খুলুন';
  static const strokeClose = 'AB লাগান';
  static const substation = 'সাবস্টেশন';
  static const feeder5 = 'ফিডার-5';

  static String tok(M6GTok t) => switch (t) {
        M6GTok.eye => 'চোখ',
        M6GTok.radio => 'রেডিও',
        M6GTok.handle => 'হাতল',
        M6GTok.earth => 'আর্থ সেট',
        M6GTok.rod => 'ডিসচার্জ রড',
        M6GTok.crew => 'ক্রু',
        M6GTok.tester => 'টেস্টার',
      };

  static String sec(M6GSec s) => switch (s) {
        M6GSec.main => 'মেইন লাইন',
        M6GSec.branch => 'ব্রাঞ্চ A',
        M6GSec.dtr => 'DTR',
        M6GSec.lt => 'LT লাইন',
      };

  static String dev(M6GDev d) => switch (d) {
        M6GDev.cb => 'সাবস্টেশন ব্রেকার',
        M6GDev.r12 => 'রিক্লোজার R-12',
        M6GDev.ab1 => 'AB-1',
        M6GDev.ug => 'রাস্তার UG কেবিল',
        M6GDev.bank => 'ক্যাপাসিটর ব্যাংক',
        M6GDev.span => 'মেইন লাইনের পোল',
        M6GDev.s3 => 'সেকশনালাইজার S-3',
        M6GDev.abA => 'AB-A (ব্রাঞ্চ A)',
        M6GDev.branch => 'ব্রাঞ্চ A-র লাইন',
        M6GDev.ab2 => 'AB-2',
        M6GDev.dtr => 'DTR ও তার AB',
        M6GDev.ltbox => 'LT বক্স',
        M6GDev.house => 'বাড়ির AB কেবিল ও মিটার',
        M6GDev.abT => 'AB-T (ফিডার-5-এর টাই)',
      };

  /// The plate painted on the device (worker-readable only).
  static String plate(M6GDev d, {int kva = 63}) => switch (d) {
        M6GDev.cb => 'VCB',
        M6GDev.r12 => 'R-12',
        M6GDev.ab1 => 'AB-1',
        M6GDev.ab2 => 'AB-2',
        M6GDev.abA => 'AB-A',
        M6GDev.abT => 'AB-T',
        M6GDev.s3 => 'S-3',
        M6GDev.dtr => enDigits('$kva kVA'),
        M6GDev.ltbox => 'LT',
        _ => '',
      };

  static String req(M6GReq r) => switch (r) {
        M6GReq.relay => 'রিলেতে কী ফ্ল্যাগ, জানান',
        M6GReq.cbOffPtw => 'ব্রেকার OFF করে PTW দিন',
        M6GReq.cbOn => 'ব্রেকার এবার ON করে দিন',
        M6GReq.rcCount => 'R-12 কতবার চেষ্টা করেছে?',
        M6GReq.rcNrPtw => 'R-12 Non-Reclose, PTW দিন',
        M6GReq.rcNormal => 'R-12 এবার নরমালে দিন',
        M6GReq.s3Info => 'S-3 এখন কী অবস্থায়?',
        M6GReq.s3Open => 'S-3 এখনই খুলে দিন',
        M6GReq.s3Close => 'S-3 এবার লাগিয়ে দিন',
        M6GReq.dtrInfo => 'DTR-এর এলাকার খবর দিন',
        M6GReq.dtrPtw => 'DTR-এ কাজের PTW দিন',
        M6GReq.dtrOff => 'পুরো ফিডার OFF করুন',
      };

  static String lt(M6GLt c) => switch (c) {
        M6GLt.offLock => 'LT সুইচ OFF, তালা-ট্যাগ দাও',
        M6GLt.offOnly => 'শুধু LT সুইচটা OFF করে দাও',
        M6GLt.on => 'LT সুইচটা এবার ON করে দাও',
      };

  static const rodClamp = 'আর্থ ক্ল্যাম্প';
  static String rodTerm(int i) => '${'RYB'[i]} টার্মিনাল';

  // --- what the lens shows (raw readings, plates) ---------------------------
  static String look(M6GRun r, M6GDev d) {
    final x = r.deal;
    final f = x.fam;
    String lead(M6GDev ab) => switch (x.leads[ab] ?? M6GLead.ok) {
          M6GLead.ok => 'হাতলের আর্থ লিড শক্ত করে লাগানো',
          M6GLead.cut => 'হাতলের আর্থ লিড কাটা',
          M6GLead.loose => 'হাতলের আর্থ লিড ঢিলা',
        };
    String blades(M6GDev ab) {
      final open = r.abOpen[ab] ?? false;
      if (open) return r.stuck == ab ? 'R আর B ব্লেড খোলা — Y ব্লেড আটকে আছে' : 'তিনটে ব্লেডই খোলা, ফাঁক স্পষ্ট';
      return r.partSeat == ab ? 'R আর B পুরো বসেছে — Y ব্লেড আধখানা বসে' : 'তিনটে ব্লেডই লাগানো';
    }

    return switch (d) {
      M6GDev.cb => f == M6GFam.ug && !r.cbOnDone
          ? enDigits('লাল বাতি নিভে, সবুজ বাতি জ্বলছে · রিলে ফ্ল্যাগ: ${x.flags} · শর্ট সার্কিট')
          : 'লাল বাতি জ্বলছে, সবুজ নিভে · রিলেতে কোনো ফ্ল্যাগ নেই',
      M6GDev.r12 => switch (f) {
          M6GFam.main when !r.rcNormalDone => enDigits('হাতল নিচে ঝুলে · কাউন্টার ${x.counter + x.tries}'),
          M6GFam.branch => enDigits('হাতল ওপরে · কাউন্টার ${x.counter + x.tries}'),
          M6GFam.ug when !r.cbOnDone => enDigits('হাতল ওপরে · কাউন্টার ${x.counter} · সাপ্লাই নেই'),
          _ => enDigits('হাতল ওপরে · কাউন্টার ${x.counter}'),
        },
      M6GDev.ab1 || M6GDev.ab2 || M6GDev.abA || M6GDev.abT => '${blades(d)} · ${lead(d)}',
      M6GDev.ug => f == M6GFam.ug
          ? 'রাস্তা খোঁড়া, পাশে খননযন্ত্র · রাইজারের কাছে পোড়া দাগ'
          : x.excavator
              ? 'পাশে খননযন্ত্র দাঁড়িয়ে · রাস্তা খোঁড়া হয়নি, রাইজার পরিষ্কার'
              : 'রাস্তা ঠিক আছে · রাইজার পরিষ্কার',
      M6GDev.bank => enDigits('প্লেট: বিপদ! সঞ্চিত শক্তি। স্পর্শ করার আগে 5-10 মিনিট অপেক্ষা করুন · '
          '${r.bankRemoved ? 'ফোলা ইউনিট খুলে নামানো' : x.swollen ? 'একটা ইউনিট ফুলে উঠেছে' : 'সব ইউনিট সমান, ঠিক আছে'}'
          ' · ব্যাংকের সুইচ ${r.bankOff ? 'OFF' : 'ON'}'),
      M6GDev.span => f == M6GFam.main && !r.fixed
          ? 'তারের ওপর ভাঙা ডাল · একটা ইনসুলেটরে ফাটল'
          : x.crows
              ? 'তারের ওপর কয়েকটা কাক বসে · ইনসুলেটর ঠিক'
              : 'তার আর ইনসুলেটর ঠিক দেখাচ্ছে',
      M6GDev.s3 => f == M6GFam.branch && !r.s3CloseDone ? 'S-3 খোলা, ঝুলে আছে · ব্রাঞ্চ A-র দিকে' : 'S-3 লাগানো',
      M6GDev.branch => f == M6GFam.branch && !r.fixed ? 'ব্রাঞ্চের তারে ভাঙা ডাল · একটা ইনসুলেটরে ফাটল' : 'ব্রাঞ্চের তার আর ইনসুলেটর ঠিক',
      M6GDev.dtr => [
          switch (f) {
            M6GFam.dtrOil => 'একটা HG-তে তার নেই · ড্রেনের তেল কালো, পোড়া গন্ধ',
            M6GFam.coord => r.hgDone ? 'তিনটে HG-তেই তার · ড্রেনের তেল পরিষ্কার' : 'একটা HG-তে তার নেই · ড্রেনের তেল পরিষ্কার',
            _ => 'তিনটে HG-তেই তার · ড্রেনের তেল পরিষ্কার',
          },
          x.stripCut && !r.stripFixed ? 'আর্থ স্ট্রিপ মাঝখানে কাটা' : 'আর্থ স্ট্রিপ অটুট',
          'AB: ${blades(d)} · ${lead(d)}',
          enDigits('প্লেট: ${x.kva} kVA'),
        ].join(' · '),
      M6GDev.ltbox => [
          switch (f) {
            M6GFam.coord when !r.jugaadOut => 'একটা ওয়েতে ফিউজের জায়গায় মোটা তামার তার',
            M6GFam.ltWay when !r.hrcDone => enDigits('ওয়ে ${x.way}-এর HRC-র লাল ডট নেই'),
            _ => enDigits('${x.ways}টা ওয়ের ফিউজই ঠিক'),
          },
          'LT সুইচ ${r.ltOff ? 'OFF' : 'ON'}${r.ltOff && r.ltLocked ? ', তালা ও ট্যাগ' : ''}',
        ].join(' · '),
      M6GDev.house => r.twistDue
          ? (x.twist == M6GTwist.lcd ? 'একটা বাড়ি অন্ধকার · মিটার ON, আলো নেই' : 'একটা বাড়ি অন্ধকার · মিটারের ডিসপ্লে নিভে')
          : f == M6GFam.ltWay && !r.nickSealed
              ? 'AB কেবিলে একটা কাটা দাগ, ভেতরে জল'
              : 'AB কেবিল ঠিক · মিটারের ডিসপ্লে চলছে',
    };
  }

  // --- what the control room says (raw) -------------------------------------
  static String reply(M6GDeal x, M6GReq q, {required bool complete}) {
    final f = x.fam;
    final ptw = enDigits('PTW নং ${x.ptwNo}');
    return switch (q) {
      M6GReq.relay => f == M6GFam.ug ? enDigits('রিলে: ${x.flags} ফ্ল্যাগ · শর্ট সার্কিট — লিখে রাখলাম') : 'ব্রেকার ON আছে, রিলেতে কিছু নেই',
      M6GReq.cbOffPtw => f == M6GFam.ug
          ? (complete ? 'ব্রেকার OFF নিশ্চিত, ট্যাগ লাগানো। $ptw দিলাম।' : 'ব্রেকার তো ট্রিপ করেই আছে… দেখছি, পরে বলছি।')
          : needlessFeeder,
      M6GReq.cbOn => 'ব্রেকার ON হলো।',
      M6GReq.rcCount => switch (f) {
          M6GFam.main => enDigits('R-12 ${x.tries} বার চেষ্টা করে লক-আউট।'),
          M6GFam.branch => enDigits('R-12 ${x.tries} বার চেষ্টা করে চালু আছে।'),
          M6GFam.ug => 'R-12-এ সাপ্লাই নেই, চেষ্টাও করেনি।',
          _ => 'R-12 নরমাল, কোনো চেষ্টা হয়নি।',
        },
      M6GReq.rcNrPtw => switch (f) {
          M6GFam.main => complete ? 'R-12 Non-Reclose-এ, লক-আউট নিশ্চিত। $ptw দিলাম।' : 'R-12 এখনও চেষ্টা করছে… Non-Reclose দিচ্ছি, পরে বলছি।',
          M6GFam.branch => complete ? 'R-12 Non-Reclose-এ দেওয়া হলো। $ptw দিলাম।' : 'Non-Reclose দিচ্ছি… একটু দাঁড়ান, পরে বলছি।',
          _ => 'R-12 Non-Reclose-এ দেওয়া হলো।',
        },
      M6GReq.rcNormal => 'R-12 নরমালে দেওয়া হলো।',
      M6GReq.s3Info => f == M6GFam.branch ? 'S-3 খোলা — ব্রাঞ্চ A-তে সাপ্লাই নেই।' : 'S-3 লাগানো আছে।',
      M6GReq.s3Open => f == M6GFam.branch ? 'S-3 তো খোলাই আছে।' : needlessFeeder,
      M6GReq.s3Close => f == M6GFam.branch ? 'S-3 লাগানো হলো, R-12 নরমালে ফিরল।' : 'S-3 তো লাগানোই আছে।',
      M6GReq.dtrInfo => switch (f) {
          M6GFam.dtrOil || M6GFam.coord => 'ওই DTR-এর সব বাড়ি থেকে অন্ধকারের ফোন।',
          M6GFam.ltWay => 'DTR-এর একটা লেন থেকে অন্ধকারের ফোন।',
          M6GFam.branch => 'ব্রাঞ্চ A থেকে ফোন, DTR-এর এলাকা ঠিক।',
          _ => 'সব এলাকা থেকেই অন্ধকারের ফোন।',
        },
      M6GReq.dtrPtw => complete ? 'DTR-এ কাজের $ptw দিলাম।' : 'DTR-এর PTW? দাঁড়ান, খাতায় তুলে পরে বলছি।',
      M6GReq.dtrOff => needlessFeeder,
    };
  }

  static const needlessFeeder = 'অকারণে লাইন বন্ধ — সুস্থ এলাকাও অন্ধকার হলো, পরে আবার চালু।';
  static const askedAgain = 'একবার তো পুরো নিশ্চিত করেছি!';
  static const alreadyOn = 'ওটা তো চালুই আছে।';
  static const onNoLight = 'চালু হলো, কিন্তু সব আলো এল না।';

  // --- the tester, the earth, the rod (raw) ---------------------------------
  static const testerDead = 'টেস্টার: চালু উৎসে ঠিক → লাইনে 0 V → আবার চালু উৎসে ঠিক';
  static const testerLive = 'টেস্টার: লাইনে ভোল্টেজ আছে!';
  static const earthOn = 'আর্থ সেট লাগানো হলো';
  static const earthOff = 'আর্থ সেট খোলা হলো';
  static const leadFixed = 'ক্রু হাতলের আর্থ লিড জুড়ে টাইট করল';
  static const freed = 'আবার টানতেই আটকে থাকা ব্লেডও খুলল';
  static const seated = 'আবার টানতেই তিনটে ব্লেডই পুরো বসল';
  static const opened = 'AB খোলা হলো';
  static const closed = 'AB লাগানো হলো';
  static const bankOffNote = 'ব্যাংকের সুইচ OFF';
  static const bankOnNote = 'ব্যাংকের সুইচ ON';
  static const rodDone = 'তিনটে টার্মিনালেই রডে ডিসচার্জ হলো';
  static const ltOffNote = 'LT সুইচ OFF';
  static const ltLockNote = 'LT সুইচ OFF, তালা আর ট্যাগ লাগানো';
  static const ltOnNote = 'LT সুইচ ON';
  static const nothingHere = 'ক্রু দেখল — এখানে সব ঠিক আছে';
  static const bankSound = 'ক্রু দেখল — ব্যাংকের ইউনিট সব ঠিক আছে';

  // --- the crew decks (each set within 1.3×) ---------------------------------
  static List<String> deckCards(M6GDeck d, M6GCard c, {int kva = 63}) => switch ((d, c)) {
        (M6GDeck.storm, M6GCard.right) => const ['ভাঙা ডাল সরিয়ে ফাটা ইনসুলেটর বদলাও', 'ডাল নামিয়ে ফাটল ধরা ইনসুলেটর পাল্টাও'],
        (M6GDeck.storm, _) => const ['ডালটা সরাও, ফাটা ইনসুলেটর পরে দেখব', 'ইনসুলেটর মুছে দাও, বদলানোর দরকার নেই', 'শুধু ডাল কেটে দাও, বাকিটা ঠিকই আছে'],
        (M6GDeck.joint, M6GCard.right) => const ['সার্টিফায়েড জয়েন্টার ডেকে জয়েন্ট করাও', 'প্রশিক্ষিত জয়েন্টার এনে কেবিল জোড়াও'],
        (M6GDeck.joint, _) => const ['আমরাই টেপ জড়িয়ে জয়েন্ট করে দিই', 'ওভারহেডের মতো আমরাই জোড়া দিয়ে দিই', 'কেবিল কেটে নিজেরাই গিঁট দিয়ে জুড়ি'],
        (M6GDeck.oil, M6GCard.right) => const ['লাইন থেকে বিচ্ছিন্ন রেখে DGA/BDV পরীক্ষা', 'চার্জ নয় — তেলের DGA/BDV রিপোর্ট আনাও'],
        (M6GDeck.oil, M6GCard.deadly) => const ['নতুন HG তার বেঁধে আবার চার্জ করো', 'HG-তে তার দিয়ে একবার চার্জ করে দেখি'],
        (M6GDeck.oil, _) => const ['ট্যাঙ্ক খুলে কয়েলটা একবার দেখে নিই', 'পোলেই ট্যাঙ্কের ঢাকনা খুলে দেখি'],
        (M6GDeck.jugaad, M6GCard.right) => const ['মোটা তামার তার খুলে ঠিক মাপের ফিউজ', 'জুগাড়ের তার সরিয়ে রেটিংয়ের ফিউজ দাও'],
        (M6GDeck.jugaad, M6GCard.deadly) => const ['মোটা তারটাই থাক, ওটা বেশ শক্ত আছে', 'আরও মোটা তার দাও, আর উড়বে না কখনো'],
        (M6GDeck.jugaad, _) => const ['আগে HG বাঁধি, LT বক্স পরে দেখা যাবে', 'বক্সের দরজা বন্ধ করে দাও, পরে দেখব'],
        (M6GDeck.hg, M6GCard.right) => [enDigits('$kva kVA-র HG-তে ${m6gHgAmp(kva)} ফিউজ তার বাঁধো')],
        (M6GDeck.hg, M6GCard.deadly) => const ['HG-তে মোটা তামার তার বেঁধে দাও', 'HG-তে GI বাইন্ডিং তার বেঁধে দাও'],
        (M6GDeck.hg, _) => [for (final a in m6gHgWrongAmps(kva)) enDigits('$kva kVA-র HG-তে $a ফিউজ তার বাঁধো')],
        (M6GDeck.strip, M6GCard.right) => const ['কাটা আর্থ স্ট্রিপ জুড়ে বোল্ট টাইট করো', 'আর্থ স্ট্রিপ জোড়া দিয়ে বোল্ট শক্ত করো'],
        (M6GDeck.strip, M6GCard.deadly) => const ['স্ট্রিপ পরে জুড়ব, আগে চার্জ করে দিই', 'একটু কাটা তো কী, চার্জ করে দাও এখনই'],
        (M6GDeck.strip, _) => const ['স্ট্রিপ থাক, শুধু HG-তে তার বেঁধে দাও', 'কাটা স্ট্রিপে টেপ জড়িয়ে রেখে দাও'],
        (M6GDeck.nick, M6GCard.right) => const ['গ্লাভস পরে নিকটা জলরোধী টেপে সিল করো', 'গ্লাভস পরে কাটাটা জলরোধী টেপে মোড়ো'],
        (M6GDeck.nick, M6GCard.deadly) => const ['ইনসুলেটেড তো, খালি হাতেই টেপ জড়াও', 'গ্লাভস লাগবে না, খালি হাতে সিল করো'],
        (M6GDeck.nick, _) => const ['কাটা থাক, শুধু ফিউজটা বদলে দিই', 'নিকটা পরে দেখব, আগে ফিউজ লাগাই'],
        (M6GDeck.hrc, M6GCard.right) => const ['গ্লাভস পরে পুলারে একই মাপের HRC বসাও', 'গ্লাভস-গগলসে, পুলারে একই রেটিংয়ের HRC'],
        (M6GDeck.hrc, M6GCard.deadly) => const ['HRC-র জায়গায় মোটা তার বা পাত দাও', 'ফিউজের বদলে তামার পাত বসিয়ে দাও'],
        (M6GDeck.hrc, _) => const ['গ্লাভস পরে পুলারে বড় রেটিংয়ের HRC দাও', 'পুলারে দুই মাপ বড় HRC দাও, আর উড়বে না', ...hrcNoPpe],
        (M6GDeck.bank, M6GCard.right) => const ['ফোলা ইউনিটটা খুলে সার্ভিস থেকে সরাও', 'ফোলা ক্যাপাসিটর ইউনিট খুলে নামাও'],
        (M6GDeck.bank, _) => const ['ফোলা ইউনিট থাক, ব্যাংক চালু থাকুক', 'ফোলা ক্যানটা টেপে বেঁধে রেখে দাও', 'একটু ফোলা তো কী, পরের মাসে দেখব'],
        (M6GDeck.twistLcd, M6GCard.right) => const ['নিউট্রাল কাটা — নিউট্রালটা দেখি', 'মিটার ON, আলো নেই — নিউট্রাল দেখি'],
        (M6GDeck.twistBlank, M6GCard.right) => const ['আগে ইনকামিংয়ে ভোল্টেজ দেখি', 'মিটারের ইনকামিংয়ে ভোল্টেজ মাপি'],
        (M6GDeck.twistLcd || M6GDeck.twistBlank, _) => const ['মিটারটাই খারাপ, নতুন বদলে দিই', 'মিটারটা খুলে নতুন একটা লাগাই', 'মিটার পুরনো হয়েছে, নতুন বসাই'],
      };

  /// The HRC deck's no-PPE slip cards (A5/X4: no PPE after a proven
  /// isolation = slip; lesson 6.3 point 5).
  static const hrcNoPpe = ['প্লায়ার্সে টেনেই একই মাপের HRC বসাও', 'খালি হাতেই একই মাপের নতুন HRC দাও'];

  /// Every card a deck can show (for the length test).
  static List<String> deckAll(M6GDeck d, {int kva = 63}) => {
        for (final c in M6GCard.values) ...deckCards(d, c, kva: kva),
      }.toList();

  // --- the ◆ questions and their cards ---------------------------------------
  static String question(M6GReason r) => switch (r) {
        M6GReason.find => 'ফল্টটা এই সেকশনেই — কী দেখে বুঝলেন?',
        M6GReason.relay => 'রিলের খবর কেন লিখে রাখলেন?',
        M6GReason.reAsk => 'অপারেটর পুরো নিশ্চিত না করায় কেন থামলেন?',
        M6GReason.bothEnds => 'কেন দুই প্রান্তের আইসোলেটরই খুললেন?',
        M6GReason.tie => 'টাই সুইচটা কেন দেখলেন?',
        M6GReason.gaps => 'তিনটে ফেজের গ্যাপ কেন নিজের চোখে দেখলেন?',
        M6GReason.bank => 'লাইনে আর্থ থাকা সত্ত্বেও ব্যাংকে কেন আলাদা রড?',
        M6GReason.oil => 'কালো, পোড়া গন্ধের তেল দেখে কেন আবার চার্জ করলেন না?',
        M6GReason.fuse => 'ফিউজ বাঁধার আগে কেন কারণ খুঁজলেন?',
        M6GReason.joint => 'কেবিলের জয়েন্ট কেন জয়েন্টারকে দিলেন?',
        M6GReason.restore => 'আলো ফেরাতে কেন আগে AB লাগালেন, পরে চালু?',
        M6GReason.twistLcd => 'মিটার ON অথচ আলো নেই — কেন নিউট্রাল দেখলেন?',
        M6GReason.twistBlank => 'ডিসপ্লে নিভে — কেন আগে ইনকামিং দেখলেন?',
      };

  /// Realistic wrong reasons: habit, hurry, orders, a guess.
  static const excuses = [
    'সবাই তো এভাবেই করে, তাই করলাম',
    'তাড়া ছিল, তাই সহজটাই বেছে নিলাম',
    'অফিস বলেছে, তাই চোখ বুজে করলাম',
    'আন্দাজে মনে হলো, তাই এটাই করলাম',
    'আগেরবারও এভাবেই কাজ হয়েছিল তো',
  ];

  static List<String> whyRight(M6GReason r, {M6GFam fam = M6GFam.main}) => switch (r) {
        M6GReason.find => switch (fam) {
            M6GFam.branch => const ['S-3 খুলে ব্রাঞ্চ A আলাদা, বাকি সব আলো', 'শুধু ব্রাঞ্চ A অন্ধকার, S-3 খোলা পড়ে'],
            M6GFam.main => const ['R-12-এর হাতল নিচে — লক-আউট হয়ে আছে', 'রিক্লোজার লক-আউট, তাই মেইন লাইনে ফল্ট'],
            M6GFam.ug => const ['শর্ট সার্কিট, আর রাস্তাটা খোঁড়া পড়ে', 'ব্রেকার সবুজ, খোঁড়া রাস্তায় শর্ট'],
            M6GFam.dtrOil => const ['HG তার নেই, ড্রেনের তেল কালো-পোড়া', 'শুধু DTR-এর বাড়ি অন্ধকার, তেল পোড়া'],
            M6GFam.coord => const ['HG উড়েছে, তেল ঠিক — LT বক্সে জুগাড়', 'তেল পরিষ্কার, HG নেই, LT-তে মোটা তার'],
            M6GFam.ltWay => const ['একটা ওয়ের HRC ডট নেই, ওই লেন অন্ধকার', 'শুধু একটা লেন অন্ধকার, HRC উড়েছে'],
          },
        M6GReason.relay => const ['কোন ফেজে, কী ফল্ট — খোঁজার আসল সূত্র', 'রিলের ইন্ডিকেশন ফল্ট খুঁজতে খুব জরুরি'],
        M6GReason.reAsk => const ['পুরো নিশ্চিত আর PTW ছাড়া কেউ উঠবে না', 'আধা কথায় লাইন ডেড ধরা যায় না কখনো'],
        M6GReason.bothEnds => const ['অন্য দিক থেকে ব্যাক-ফিড আসতে পারে', 'এক প্রান্ত খোলা মানে লাইন ডেড নয়'],
        M6GReason.tie => const ['টাই লাগানো মানে ফিডার-5-এর ব্যাক-ফিড', 'সব উৎস খোলা না হলে লাইন ডেড নয়'],
        M6GReason.gaps => const ['একটা ফেজ আটকে থাকলে লাইন চালু থাকে', 'তিন ব্লেডই খুলেছে কি না দেখাই নিয়ম'],
        M6GReason.bank => const ['ক্যাপাসিটর আর্থের পরেও চার্জ ধরে রাখে', 'অপেক্ষার পরেও রডে সরাসরি ডিসচার্জ চাই'],
        M6GReason.oil => const ['পোড়া তেল মানে ভেতরে কয়েল পুড়েছে', 'চার্জের ঝুঁকি নয় — আগে DGA/BDV দেখা'],
        M6GReason.fuse => const ['কারণ না সারালে ফিউজ আবার উড়বে', 'বারবার ফিউজ চার্জ করা চলে না কখনো'],
        M6GReason.joint => const ['UG জয়েন্ট আলাদা প্রশিক্ষণের কাজ', 'ভুল জয়েন্টে কেবিল আবার ফেটে যাবে'],
        M6GReason.restore => const ['AB শুধু লোড ছাড়া লাগানো যায়, নিয়ম', 'লোডে AB লাগালে মারাত্মক আর্ক হয়'],
        M6GReason.twistLcd => const ['মিটার ON, আলো নেই — নিউট্রাল কাটা', 'এমন হলে সাধারণত নিউট্রাল কেটে যায়'],
        M6GReason.twistBlank => const ['আগে ইনকামিংয়ে ভোল্টেজ, তারপর মিটার', 'ভোল্টেজ না থাকলে দোষ সার্ভিস কেবিলে'],
      };

  static List<String> whyWrong(M6GReason r) => [
        ...switch (r) {
          M6GReason.find => const ['সাবস্টেশনের সবচেয়ে কাছে, তাই এখানেই', 'এই সেকশনটা গাড়ি থেকে সবচেয়ে কাছে'],
          M6GReason.relay => const ['লিখলে অফিসের খাতা ভরা দেখায় শুধু', 'রিলে লিখলে ব্রেকার নিজেই চালু হয়'],
          M6GReason.reAsk => const ['ফোনে কথা বললে সময়টা কাটে, তাই', 'অপারেটরকে একটু ব্যস্ত রাখতে চাইলাম'],
          M6GReason.bothEnds => const ['দুটো খুললে কাজ বেশি দেখায় অফিসে', 'একটা খুললে হাতল জ্যাম হয়ে যায় তো'],
          M6GReason.tie => const ['টাই খুললে ফিডার-5-এর লোড কমে যায়', 'টাই দেখলে অফিসের খাতা ভরা দেখায়'],
          M6GReason.gaps => const ['চোখে দেখলে টেস্টার আর লাগে না তো', 'ব্লেড দেখলে হাতল হালকা হয়ে যায়'],
          M6GReason.bank => const ['রড না দিলে অফিস বকাবকি করে তো', 'রড দিলে ব্যাংক তাড়াতাড়ি ঠান্ডা হয়'],
          M6GReason.oil => const ['তেল কালো হলে DTR আর ঠান্ডা হয় না', 'নতুন HG তারের দাম অনেক বেশি তো'],
          M6GReason.fuse => const ['ফিউজ তার বাঁচাতে, দাম অনেক বেশি', 'কারণ খুঁজলে ওভারটাইম বেশি পাওয়া যায়'],
          M6GReason.joint => const ['জয়েন্টার ডাকলে আমাদের ছুটি মেলে', 'নিজেরা করলে টেপ বেশি লেগে যায়'],
          M6GReason.restore => const ['আগে AB দিলে মিটার তাড়াতাড়ি ঘোরে', 'AB পরে দিলে হাতল জ্যাম হয়ে যায়'],
          M6GReason.twistLcd || M6GReason.twistBlank => const ['মিটার বদলালে বিল কম আসে, তাই তো', 'মিটার খুললে গ্রাহক খুশি হয় তাই'],
        },
        ...excuses,
      ];

  /// "আজ যা ধরলেন" — from the player's own moves (on screen only).
  static String caught(M6GReason r) => switch (r) {
        M6GReason.find => 'যন্ত্র পড়ে ঠিক সেকশন ধরা',
        M6GReason.relay => 'রিলের খবর লিখে রাখা',
        M6GReason.reAsk => 'আধা কথায় নয়, পুরো নিশ্চয়তা',
        M6GReason.bothEnds => 'দুই প্রান্ত খোলা, 0 V, আর্থ',
        M6GReason.tie => 'টাই খোলা, দুই প্রান্ত, 0 V, আর্থ',
        M6GReason.gaps => 'তিন ব্লেড দেখে, 0 V, আর্থ',
        M6GReason.bank => '5 মিনিট, ক্ল্যাম্প আগে, তারপর রড',
        M6GReason.oil => 'পোড়া তেলে চার্জ নয়',
        M6GReason.fuse => 'আগে কারণ, তারপর ফিউজ',
        M6GReason.joint => 'জয়েন্ট সার্টিফায়েড জয়েন্টারকে',
        M6GReason.restore => 'আগে AB লাগানো, পরে চালু',
        M6GReason.twistLcd => 'মিটার ON, আলো নেই — নিউট্রাল',
        M6GReason.twistBlank => 'ডিসপ্লে নিভে — আগে ইনকামিং',
      };
  static const caughtPush = 'চাপে নিয়ম ভাঙা নয়';

  // --- the careless coworker (level 1's rival; his recorded voice) -----------
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const _asks = ['ও যা বলছে, করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'];

  /// (a) F-C at the crew drop: lesson 6.2 myth 1, word for word (recorded).
  static const pushA = CoworkerScript(
    line: 'সার্কিট ব্রেকার ট্রিপ করেছে মানে লাইনটি সম্পূর্ণ বন্ধ। এতে কোনো ভোল্টেজ নেই।',
    exitLine: coworkerExit,
    right: ['না — দুই প্রান্ত খোলা আর আর্থ ছাড়া কেউ উঠবে না', 'না — ব্যাক-ফিড থাকতে পারে, আগে টেস্টার আর আর্থ'],
    wrong: [
      'ঠিক, ব্রেকার তো ট্রিপ করেই আছে, উঠে পড়ো তবে',
      'সবুজ বাতি মানেই লাইন ডেড, এখনই উঠে পড়ো তবে',
      'দেরি না করে উঠে কাজটা তাড়াতাড়ি সেরে ফেলো',
      'ভোল্টেজ নেই তো, আর্থ ছাড়াই কাজটা চলবে বেশ',
      'ট্রিপ মানে বন্ধ — টেস্টার আর আর্থ লাগবে না',
    ],
    asks: _asks,
  );

  /// (b) F-A/F-B at the crew drop: lesson 6.8 myth 1, word for word.
  static const pushB = CoworkerScript(
    line: 'লাইনটা তো ট্রিপ করে আছে, রিক্লোজার নিশ্চয়ই লক-আউট হয়ে গেছে। কাজ করতে কোনো ভয় নেই।',
    exitLine: coworkerExit,
    right: ['না — Non-Reclose আর PTW নিশ্চিত না হলে ওঠা নয়', 'না — রিক্লোজার মাঝ-সাইকেলে থাকতে পারে, আগে PTW'],
    wrong: [
      'ঠিক, লক-আউট তো হয়েই আছে, উঠে পড়ো এখনই',
      'রিক্লোজার আর চেষ্টা করবে না, উঠে কাজ ধরো',
      'Non-Reclose-এর ঝামেলা ছাড়াই উঠে পড়ো তবে',
      'PTW পরে নেওয়া যাবে, আগে উঠে কাজটা সারো',
      'ট্রিপ করে আছে মানে ভয় নেই, উঠে পড়ো তবে',
    ],
    asks: _asks,
  );

  /// (c) a swollen bank in the section, at the first crew drop on the main
  /// section (the bank or the storm damage — every F-B path passes it):
  /// lesson 6.7 myth 1, word for word.
  static const pushC = CoworkerScript(
    line: 'লাইন তো বন্ধ এবং আর্থ করা আছে, তাই ক্যাপাসিটর ব্যাংকে কাজ করতে কোনো ভয় নেই।',
    exitLine: coworkerExit,
    right: ['না — সব টার্মিনালে রড না দিয়ে ব্যাংকে হাত নয়', 'না — ক্যাপাসিটর আলাদা করে, সরাসরি ডিসচার্জ চাই'],
    wrong: [
      'ঠিক, লাইনের আর্থই ব্যাংক খালি করে দিয়েছে',
      'আর্থ তো আছেই, রড ছাড়াই ব্যাংকে হাত দাও',
      'ছোট ক্যাপাসিটর, তেমন বিপদ নেই, ধরে ফেলো',
      'অপেক্ষা হয়ে গেছে, রডের আর দরকার নেই তো',
      'লাইন বন্ধ মানে ব্যাংকও খালি, কাজ ধরে ফেলো',
    ],
    asks: _asks,
  );

  /// (d) F-C at the হাতল drop on AB-1/AB-2 before the breaker OFF is
  /// confirmed: lesson 6.4 myth 1, word for word (recorded).
  static const pushD = CoworkerScript(
    line: 'সামান্য লোড থাকলে আইসোলেটর খোলা যায়, কিছু হয় না।',
    exitLine: coworkerExit,
    right: ['না — আগে OFF নিশ্চিত, তারপরই AB খোলা যাবে', 'না — আইসোলেটর শুধু লোড ছাড়া খোলা যায়, নিয়ম'],
    wrong: [
      'ঠিক, লোড তো সামান্য, এখনই AB খুলে ফেলো',
      'OFF-এর খবরের দরকার নেই, হাতল টেনে দাও',
      'সামান্য লোডে কিছু হবে না, খুলে ফেলো তবে',
      'অপারেটরের অপেক্ষা না করে AB খুলে দাও',
      'ব্রেকার তো ট্রিপ করেই আছে, AB খোলো এখনই',
    ],
    asks: _asks,
  );

  /// (e) F-C, restore, at the first AB লাগানো (recorded line).
  static const pushE = CoworkerScript(
    line: 'আইসোলেটর আর ব্রেকার একই জিনিস — আগে ব্রেকার দিতে বলো।',
    exitLine: coworkerExit,
    right: ['না — আগে AB লাগাব, তারপর ব্রেকার ON হবে', 'না — আইসোলেটর লোডে লাগানো যায় না, আগে AB'],
    wrong: [
      'ঠিক, আগে ব্রেকার ON করাই, AB পরে দেব',
      'দুটো একই জিনিস, আগে ব্রেকার দিতে বলি',
      'ব্রেকার আগে দিলে সময় বাঁচে, তাই বলি',
      'আগে ব্রেকার, তারপর AB — তাতে কী হবে',
      'অপারেটরকে বলি ব্রেকার দিক, AB পরে হবে',
    ],
    asks: _asks,
  );

  /// (f) F-E/F-F at the fuse fit: lesson 6.9 myth 2, word for word.
  static const pushF = CoworkerScript(
    line: 'ফিউজের জায়গায় একটা মোটা তার বা পাত লাগিয়ে দিলে আর বারবার ফিউজ যাওয়ার সমস্যা থাকবে না।',
    exitLine: coworkerExit,
    right: ['না — মোটা তারে ফিউজ উড়বে না, কেবিল-DTR পুড়বে', 'না — শুধু ঠিক রেটিংয়ের ফিউজ, জুগাড় কখনো নয়'],
    wrong: [
      'ঠিক, মোটা তার দিলে আর উড়বে না, দিয়ে দাও',
      'একটা তামার পাত বসিয়ে দাও, ঝামেলা শেষ হবে',
      'মোটা তারই ভালো, বারবার আসতে হবে না আর',
      'ফিউজের দরকার নেই, মোটা তারেই চলবে বেশ',
      'আজকের মতো পাত দাও, পরে ফিউজ বসানো যাবে',
    ],
    asks: _asks,
  );

  /// (g) F-D at the HG fit: the do_6_1_b line (recorded).
  static const pushG = CoworkerScript(
    line: 'তেল একটু কালো তো কী! HG ফিউজের তার বেঁধে আবার চার্জ করে দেখি, চলবে।',
    exitLine: coworkerExit,
    right: ['না — পোড়া তেল মানে কাগজ পুড়েছে, চার্জ নয়', 'না — চার্জের ঝুঁকি নয়, আগে DGA/BDV পরীক্ষা'],
    wrong: [
      'ঠিক, HG-তে তার বেঁধে একবার চার্জ করো',
      'তেল একটু কালো তো কী, চার্জ করে দেখো',
      'চার্জ করলে টিকে যেতেও পারে, দিয়ে দেখো',
      'একবার চার্জে কী আর এমন ক্ষতি হবে বলো',
      'এলাকা অন্ধকার, তাড়াতাড়ি চার্জ করে দাও',
    ],
    asks: _asks,
  );

  static CoworkerScript script(M6GPush p) => switch (p) {
        M6GPush.a => pushA,
        M6GPush.b => pushB,
        M6GPush.c => pushC,
        M6GPush.d => pushD,
        M6GPush.e => pushE,
        M6GPush.f => pushF,
        M6GPush.g => pushG,
      };

  static const coworkers = [pushA, pushB, pushC, pushD, pushE, pushF, pushG];

  /// His pushes (the director records the ones with no clip yet with
  /// tool/rival_clip.py; until then silent, caption held).
  static List<String> get newRivalLines => [for (final s in coworkers) s.line];

  /// Every spoken guide line (DRAFT — owner wording, then recorded). The
  /// readings, replies and notes are shown, never spoken.
  static List<String> get newGuideLines => <String>{
        intro,
        ...tasks,
        ...tapWhy,
        markFirst,
        radioWhere,
        noUse,
        tieStays,
        lit,
        refused,
        fixRight,
        sentShop,
        fail,
        deadlyWord,
        nearMissWord,
        for (final r in M6GReason.values) question(r),
        for (final s in coworkers) ...s.asks,
        promoted(rankTo),
        for (final m in M6GMistakes.all) m.textBn,
      }.toList();
}

/// The HG fuse wire for a DTR's kVA (lesson 6.3 point 0).
String m6gHgAmp(int kva) => switch (kva) {
      25 => '2A',
      63 => '5A',
      _ => '10A',
    };

/// Wrong ratings for a DTR's kVA (another kVA's wire).
List<String> m6gHgWrongAmps(int kva) => switch (kva) {
      25 => const ['5A', '10A'],
      63 => const ['2A', '10A'],
      _ => const ['2A', '5A'],
    };

// ============================================================================
// Mistakes (the module table, after the rulings)
// ============================================================================

const _art = 'assets/game/art/m6_gate_storm_feeder';

/// One gate mistake and the lesson that teaches it.
@immutable
class M6GMistake {
  const M6GMistake(this.lessonId, this.m);
  final String lessonId;
  final DoMistake m;
}

abstract final class M6GMistakes {
  // --- deadly (DRAFT wording — owner) -----------------------------------------
  static const crewLive = M6GMistake('6.2', DoMistake(
    key: 'm6/gate/crew-live',
    textBn: 'সবুজ বাতি বা ট্রিপ মানেই লাইন ডেড নয় — অন্য দিক থেকে ব্যাক-ফিড আসতে পারে। দুই প্রান্তে আইসোলেটর খুলে, টেস্টারে ডেড প্রমাণ করে, আর্থ দিয়ে তবে ক্রু উঠবে।',
    art: '$_art/crew_live.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const noNonReclose = M6GMistake('6.8', DoMistake(
    key: 'm6/gate/no-non-reclose',
    textBn: 'রিক্লোজারের লাইনে Non-Reclose আর PTW নিশ্চিত না করে ক্রু তোলা — রিক্লোজার কোনো সতর্কবার্তা ছাড়াই লাইন চালু করে দিতে পারে। অপারেটরের পুরো নিশ্চয়তা আর PTW নিয়ে তবে কাজ।',
    art: '$_art/ptw.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const noPtw = M6GMistake('6.2', DoMistake(
    key: 'm6/gate/no-ptw',
    textBn: 'কন্ট্রোল রুমের PTW হাতে না নিয়ে ক্রু তোলা — অপারেটরের পুরো নিশ্চয়তা আর PTW ছাড়া কেউ লাইনে উঠবে না।',
    art: '$_art/ptw.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const abOnLoad = M6GMistake('6.4', DoMistake(
    key: 'm6/gate/ab-on-load',
    textBn: 'লোডে আইসোলেটর খোলা — সামান্য লোডেও মারাত্মক আর্ক হয়। AB খোলার আগে ব্রেকার বা রিক্লোজার OFF নিশ্চিত করুন; DTR-এর AB-র আগে LT সুইচ OFF।',
    art: '$_art/ab_load.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const abCloseOnLoad = M6GMistake('6.4', DoMistake(
    key: 'm6/gate/ab-close-on-load',
    textBn: 'লাইন চালুর পরে AB লাগানো — লোডে আইসোলেটর লাগালে মারাত্মক আর্ক হয়। আগে AB লাগিয়ে ব্লেড দেখুন, তারপর ব্রেকার, রিক্লোজার বা LT ON।',
    art: '$_art/ab_load.svg',
    deadly: true,
    lessonPoint: 1,
  ));
  static const earthLive = M6GMistake('6.2', DoMistake(
    key: 'm6/gate/earth-live',
    textBn: 'চালু লাইনে আর্থ সেট — মুহূর্তে আর্ক আর বিস্ফোরণ। আগে দুই প্রান্ত খুলে টেস্টারে ডেড প্রমাণ, তারপর আর্থ।',
    art: '$_art/earth.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const handsNoEarth = M6GMistake('6.2', DoMistake(
    key: 'm6/gate/hands-no-earth',
    textBn: 'টেস্টারে ডেড প্রমাণ আর আর্থ ছাড়া ক্রুর হাত লাইনে — হঠাৎ চালু হলে বাঁচার পথ নেই। আগে 0 V, তারপর আর্থ, তবে কাজ।',
    art: '$_art/earth.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const bankTouch = M6GMistake('6.7', DoMistake(
    key: 'm6/gate/bank-touch',
    textBn: 'প্রতিটা টার্মিনাল রডে ডিসচার্জের আগে ব্যাংকে হাত — লাইন আর্থ করা থাকলেও ক্যাপাসিটর চার্জ ধরে রাখে। আলাদা করে, সরাসরি ডিসচার্জ করুন।',
    art: '$_art/bank.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const rodHook = M6GMistake('6.7', DoMistake(
    key: 'm6/gate/rod-hook-first',
    textBn: 'রডের আর্থ ক্ল্যাম্প দেওয়ার আগেই হুক টার্মিনালে — চার্জ আপনার শরীর দিয়ে নামবে। আগে ক্ল্যাম্প আর্থে, তারপর হুক।',
    art: '$_art/bank.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const nonFuse = M6GMistake('6.3', DoMistake(
    key: 'm6/gate/non-fuse',
    textBn: 'ফিউজের জায়গায় মোটা তার বা পাত — ফল্টে ফিউজ না উড়ে কেবিল বা ট্রান্সফরমার পুড়ে যাবে, আগুন লাগবে। শুধু ঠিক রেটিংয়ের ফিউজ।',
    art: '$_art/fuse.svg',
    deadly: true,
    lessonPoint: 4,
  ));
  static const liveLt = M6GMistake('6.9', DoMistake(
    key: 'm6/gate/live-lt',
    textBn: 'চালু সাপ্লাইয়ে LT ফিউজ বা কেবিলে হাত — 415 V-এর বিশাল ফল্ট কারেন্টে আর্ক ফ্ল্যাশ হয়। আগে DTR-এর LT সুইচ OFF, তালা-ট্যাগ, টেস্টারে 0 V।',
    art: '$_art/lt_live.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const recharge = M6GMistake('6.1', DoMistake(
    key: 'm6/gate/recharge-burnt',
    textBn: 'পোড়া তেলের DTR আবার চার্জ — ভেতরে কয়েল পুড়েছে, চার্জ করার ঝুঁকি নেবেন না। লাইন থেকে বিচ্ছিন্ন রেখে DGA/BDV পরীক্ষা।',
    art: '$_art/dtr_oil.svg',
    deadly: true,
    lessonPoint: 5,
  ));
  static const bareAb = M6GMistake('6.6', DoMistake(
    key: 'm6/gate/bare-ab-cable',
    textBn: 'খালি হাতে AB কেবিল — ইনসুলেশনে অদৃশ্য পিন-হোল বা ফাটল থাকতে পারে, মারাত্মক শক। সবসময় গ্লাভস।',
    art: '$_art/ab_cable.svg',
    deadly: true,
    lessonPoint: 2,
  ));
  static const stripCut = M6GMistake('6.11', DoMistake(
    key: 'm6/gate/strip-cut',
    textBn: 'আর্থ স্ট্রিপ কাটা রেখে DTR চার্জ — ফল্টে আর্থিং কাজ করবে না, ব্রেকার ট্রিপ করবে না। আগে স্ট্রিপ জুড়ে বোল্ট টাইট, তারপর চার্জ।',
    art: '$_art/strip.svg',
    deadly: true,
    lessonPoint: 0,
  ));
  static const chargeCrew = M6GMistake('6.4', DoMistake(
    key: 'm6/gate/charge-crew',
    textBn: 'আর্থ লাগানো বা ক্রু লাইনে থাকতেই লাইন চালু — মানেই মৃত্যু। সবাই নেমে, আর্থ খুলে, AB লাগিয়ে তবে লাইন চালু।',
    art: '$_art/earth.svg',
    deadly: true,
    lessonPoint: 3,
  ));
  static const chargeFault = M6GMistake('6.3', DoMistake(
    key: 'm6/gate/charge-fault',
    textBn: 'কারণ না সারিয়েই লাইন চালু — ফল্টের ওপর আবার চার্জ করা যায় না। আগে কারণ খুঁজে সারান।',
    art: '$_art/find.svg',
    deadly: true,
    lessonPoint: 5,
  ));

  // --- slips --------------------------------------------------------------------
  static const wrongSec = M6GMistake('6.2', DoMistake(
    key: 'm6/gate/wrong-section',
    textBn: 'ভুল সেকশনে চিহ্ন — যন্ত্রগুলো যা বলছে মিলিয়ে দেখুন: ব্রেকার, রিক্লোজার, S-3, HG আর LT ফিউজ।',
    art: '$_art/find.svg',
    lessonPoint: 2,
  ));
  static const needless = M6GMistake('6.8', DoMistake(
    key: 'm6/gate/needless-outage',
    textBn: 'দরকার ছাড়াই লাইন বন্ধ — সুস্থ অংশও অন্ধকার হয়। ফল্টের অংশটুকুই আলাদা করুন।',
    art: '$_art/find.svg',
    lessonPoint: 1,
  ));
  static const askAgain = M6GMistake('6.8', DoMistake(
    key: 'm6/gate/ask-again',
    textBn: 'পুরো নিশ্চিত হওয়ার পরেও আবার জিজ্ঞেস — অপারেটরের সময় নষ্ট। একবার পুরো নিশ্চয়তা আর PTW পেলেই যথেষ্ট।',
    art: '$_art/ptw.svg',
    lessonPoint: 2,
  ));
  static const noRelay = M6GMistake('6.2', DoMistake(
    key: 'm6/gate/no-relay',
    textBn: 'ট্রিপের পর রিলের ইন্ডিকেশন (কোন ফেজে, কী ধরনের ফল্ট) নোট না করেই কাজ — ফল্ট খোঁজার জন্য এটা অত্যন্ত জরুরি।',
    art: '$_art/find.svg',
    lessonPoint: 2,
  ));
  static const leadBad = M6GMistake('6.4', DoMistake(
    key: 'm6/gate/handle-lead',
    textBn: 'হাতলের আর্থ লিড না দেখে, বা কাটা-ঢিলা লিড নিয়েই হাতল ধরা — আগে লিডটা দেখুন। ক্রু লিড জুড়ে দিল, এবার হাতল।',
    art: '$_art/ab_gap.svg',
    lessonPoint: 3,
  ));
  static const stall = M6GMistake('6.4', DoMistake(
    key: 'm6/gate/stall',
    textBn: 'হাতল মাঝপথে থামল — দ্রুত এবং দৃঢ়ভাবে, এক টানে শেষ পর্যন্ত হ্যান্ডেলটি ঘোরানো উচিত; মাঝপথে থামবেন না।',
    art: '$_art/ab_gap.svg',
    lessonPoint: 3,
  ));
  static const gapsUnseen = M6GMistake('6.4', DoMistake(
    key: 'm6/gate/gaps-unseen',
    textBn: 'তিন ফেজের গ্যাপ না দেখেই আর্থ — যান্ত্রিক সমস্যায় একটা ফেজ আটকে যেতে পারে। তিনটে ব্লেডই খুলেছে কি না নিজের চোখে দেখুন।',
    art: '$_art/ab_gap.svg',
    lessonPoint: 3,
  ));
  static const partSeat = M6GMistake('6.4', DoMistake(
    key: 'm6/gate/part-seated',
    textBn: 'আধখানা বসা ব্লেড নিয়েই লাইন চালু — আংশিক লাগা কন্টাক্ট হটস্পট তৈরি করে। AB লাগানোর পর তিনটে কন্টাক্টই পুরো বসেছে কি না দেখুন।',
    art: '$_art/ab_gap.svg',
    lessonPoint: 3,
  ));
  static const earthUntested = M6GMistake('6.2', DoMistake(
    key: 'm6/gate/earth-untested',
    textBn: 'টেস্টারে ডেড প্রমাণের আগেই আর্থ — আগে টেস্টারে 0 V, তারপর আর্থ।',
    art: '$_art/earth.svg',
    lessonPoint: 2,
  ));
  static const rodEarly = M6GMistake('6.7', DoMistake(
    key: 'm6/gate/rod-early',
    textBn: 'ব্যাংকের সুইচ OFF-এর পর 5 মিনিট না যেতেই রড — কমপক্ষে 5-10 মিনিট অপেক্ষা বাধ্যতামূলক, তারপর রডে ডিসচার্জ।',
    art: '$_art/bank.svg',
    lessonPoint: 2,
  ));
  static const swollenLeft = M6GMistake('6.7', DoMistake(
    key: 'm6/gate/swollen-left',
    textBn: 'ফোলা ক্যাপাসিটর = ভেতরে ফল্ট, ফেটে যেতে পারে — সার্ভিস থেকে সরান।',
    art: '$_art/bank.svg',
    lessonPoint: 3,
  ));
  static const refuseEarly = M6GMistake('6.3', DoMistake(
    key: 'm6/gate/refuse-early',
    textBn: 'কারণ না সারিয়েই ফিউজ — জুগাড় বা ফল্ট থাকলে ফিউজ আবার উড়বে। আগে কারণ, তারপর ফিউজ; বারবার ফিউজ চার্জ করবেন না।',
    art: '$_art/fuse.svg',
    lessonPoint: 5,
  ));
  static const wrongRating = M6GMistake('6.3', DoMistake(
    key: 'm6/gate/wrong-rating',
    textBn: 'ভুল রেটিংয়ের ফিউজ তার — 25 kVA-তে 2A বা 3A, 63 kVA-তে 5A, 100 kVA-তে 8A বা 10A; বড় হলে ফল্টে গলবে না, ছোট হলে বারবার উড়বে।',
    art: '$_art/fuse.svg',
    lessonPoint: 0,
  ));
  static const wrongHrc = M6GMistake('6.9', DoMistake(
    key: 'm6/gate/wrong-hrc',
    textBn: 'বড় রেটিংয়ের HRC — ফল্টে ফিউজ সময়মতো উড়বে না, কেবিল পুড়বে। ওয়েতে একই মাপের HRC বসান।',
    art: '$_art/fuse.svg',
    lessonPoint: 1,
  ));
  static const noPpe = M6GMistake('6.3', DoMistake(
    key: 'm6/gate/no-ppe',
    textBn: 'গ্লাভস, গগলস আর ইনসুলেটেড পুলার ছাড়া HRC — ডেড বোর্ডেও এটাই নিয়ম। প্লায়ার্স বা খালি হাত দিয়ে টানার চেষ্টা করবেন না।',
    art: '$_art/fuse.svg',
    lessonPoint: 5,
  ));
  static const selfJoint = M6GMistake('6.5', DoMistake(
    key: 'm6/gate/self-joint',
    textBn: 'নিজেরাই HT কেবিল জয়েন্ট — UG জয়েন্টিং জটিল কাজ, বিশেষ টুলস আর প্রশিক্ষণ লাগে। সার্টিফায়েড জয়েন্টার ডাকুন।',
    art: '$_art/ug_joint.svg',
    lessonPoint: 2,
  ));
  static const nickOpen = M6GMistake('6.6', DoMistake(
    key: 'm6/gate/nick-open',
    textBn: 'কাটা জায়গা খোলা রেখে শুধু ফিউজ — নিক দিয়ে জল ঢুকে আবার ফল্ট হবে। আগে জলরোধী টেপে সিল।',
    art: '$_art/ab_cable.svg',
    lessonPoint: 2,
  ));
  static const meterWrong = M6GMistake('6.10', DoMistake(
    key: 'm6/gate/meter-blamed',
    textBn: 'মিটারকে দোষ — মিটার ON অথচ আলো নেই মানে সাধারণত নিউট্রাল কাটা; ডিসপ্লে নিভে থাকলে আগে ইনকামিং টার্মিনালে ভোল্টেজ দেখুন।',
    art: '$_art/meter.svg',
    lessonPoint: 2,
  ));
  static const ltNoLock = M6GMistake('6.9', DoMistake(
    key: 'm6/gate/lt-no-lock',
    textBn: 'LT সুইচ OFF, কিন্তু তালা-ট্যাগ বা টেস্টারে 0 V ছাড়াই কাজ — কেউ চালু করে দিতে পারে। OFF, তালা-ট্যাগ, টেস্টারে 0 V।',
    art: '$_art/lt_live.svg',
    lessonPoint: 2,
  ));
  static const tankOpen = M6GMistake('6.1', DoMistake(
    key: 'm6/gate/tank-open',
    textBn: 'মাঠে ট্যাঙ্ক খোলা — ভেতরে আর্দ্রতা ও তেল-বাষ্পে আগুনের ঝুঁকি; ট্যাঙ্ক খোলা হয় শুধু মেরামত শপে বা শুকনো পরিবেশে।',
    art: '$_art/dtr_oil.svg',
    lessonPoint: 3,
  ));
  static const stormLeft = M6GMistake('6.8', DoMistake(
    key: 'm6/gate/damage-left',
    textBn: 'ক্ষতি পুরো না সারিয়েই — ফাটা ইনসুলেটর লাইনে থাকলে ফল্ট আবার ফিরবে, রিক্লোজার আবার লক-আউট হবে।',
    art: '$_art/storm.svg',
    lessonPoint: 0,
  ));
  static const stripLeft = M6GMistake('6.11', DoMistake(
    key: 'm6/gate/strip-left',
    textBn: 'কাটা আর্থ স্ট্রিপ ফেলে রাখা — ফল্টে আর্থিং কাজ না করলে ব্রেকার ট্রিপ করবে না। জুড়ে বোল্ট টাইট না করে DTR চার্জ নয়।',
    art: '$_art/strip.svg',
    lessonPoint: 0,
  ));

  static const values = [
    crewLive, noNonReclose, noPtw, abOnLoad, abCloseOnLoad, earthLive, handsNoEarth, bankTouch, rodHook, nonFuse,
    liveLt, recharge, bareAb, stripCut, chargeCrew, chargeFault,
    wrongSec, needless, askAgain, noRelay, leadBad, stall, gapsUnseen, partSeat, earthUntested, rodEarly,
    swollenLeft, refuseEarly, wrongRating, wrongHrc, selfJoint, nickOpen, meterWrong, ltNoLock, tankOpen, stormLeft,
    stripLeft, noPpe,
  ];

  static List<DoMistake> get all => [for (final x in values) x.m];

  /// The lesson that teaches [m] (for the mistakes book and পাঠে দেখুন).
  static String lessonOf(DoMistake m) => values.firstWhere((x) => x.m.key == m.key, orElse: () => const M6GMistake('6.11', DoMistake(key: '', textBn: '', art: ''))).lessonId;
}

// ============================================================================
// The deal
// ============================================================================

/// A handle earth lead's state.
enum M6GLead { ok, cut, loose }

/// The twist: one house still dark after the light is back.
enum M6GTwist { none, lcd, blank }

@immutable
class M6GDeal {
  const M6GDeal({
    required this.fam,
    required this.feederNo,
    required this.ptwNo,
    required this.incomplete,
    required this.stuck,
    required this.partSeat,
    required this.leads,
    required this.bank,
    required this.swollen,
    required this.stripCut,
    required this.kva,
    required this.flags,
    required this.tries,
    required this.counter,
    required this.twist,
    required this.excavator,
    required this.crows,
    required this.push,
    required this.reqOrder,
    required this.way,
    required this.ways,
    required this.hour,
    required this.minute,
    this.tieClosed = false,
  });

  final M6GFam fam;
  final int feederNo;
  final int ptwNo;

  /// The operator's first answer to the path's PTW request is incomplete.
  final bool incomplete;

  /// The AB whose Y blade sticks on the first opening (or null). Only where
  /// the AB's source is confirmed OFF (main, branch): an unseen stuck blade is
  /// then a slip (R35). Never the DTR's AB, whose HT side stays live.
  final M6GDev? stuck;

  /// The AB whose Y blade seats only half on the first closing (or null).
  final M6GDev? partSeat;

  /// Each isolator's handle earth lead.
  final Map<M6GDev, M6GLead> leads;

  /// A capacitor bank stands on the main section.
  final bool bank;

  /// One of its units is swollen (only where the main is dead: F-B/F-C).
  final bool swollen;

  /// The DTR's earth strip is cut (F-E only: in F-D the DTR goes to the shop
  /// and the strip would never come into play).
  final bool stripCut;
  final int kva;

  /// The relay flags (F-C), e.g. 'R, Y'.
  final String flags;
  final int tries;
  final int counter;
  final M6GTwist twist;
  final bool excavator;
  final bool crows;
  final M6GPush push;

  /// Each control-room device's requests, in the dealt order.
  final Map<M6GDev, List<M6GReq>> reqOrder;

  /// The dark LT way (F-F) and how many ways the LT box has.
  final int way;
  final int ways;
  final int hour;
  final int minute;

  /// The tie AB-T to ফিডার-5 was left closed (only where the main is the dead
  /// section): the main is not isolated until it is opened.
  final bool tieClosed;

  /// The isolators on the family's path.
  List<M6GDev> get pathAbs => switch (fam) {
        M6GFam.branch => const [M6GDev.abA],
        M6GFam.main || M6GFam.ug => const [M6GDev.ab1, M6GDev.ab2],
        M6GFam.dtrOil || M6GFam.coord => const [M6GDev.dtr],
        M6GFam.ltWay => const [],
      };

  M6GPlan get plan => M6GPlan(bank: bank, excavator: excavator, kva: kva, ways: ways, fam: fam.index);
}

/// Deals a feeder from lesson facts only; every play fresh. [avoid]: the
/// previous play's family (never the same twice in a row).
M6GDeal dealM6G(math.Random rng, {M6GFam? avoid}) {
  var fam = M6GFam.values[rng.nextInt(M6GFam.values.length)];
  if (fam == avoid) fam = M6GFam.values[(fam.index + 1 + rng.nextInt(M6GFam.values.length - 1)) % M6GFam.values.length];
  final abs = switch (fam) {
    M6GFam.branch => const [M6GDev.abA],
    M6GFam.main || M6GFam.ug => const [M6GDev.ab1, M6GDev.ab2],
    M6GFam.dtrOil || M6GFam.coord => const [M6GDev.dtr],
    M6GFam.ltWay => const <M6GDev>[],
  };
  M6GDev? pick(int oneIn) => abs.isEmpty || rng.nextInt(oneIn) != 0 ? null : abs[rng.nextInt(abs.length)];
  final leads = <M6GDev, M6GLead>{
    for (final a in m6gAbs) a: rng.nextInt(3) == 0 ? (rng.nextBool() ? M6GLead.cut : M6GLead.loose) : M6GLead.ok,
  };
  final bank = rng.nextInt(5) < 3;
  final flagsPool = ['R, Y', 'Y, B', 'R, B', 'R, Y, B', 'Y'];
  final reqOrder = {for (final d in m6gRadioDevs) d: [...m6gReqsOf(d)]..shuffle(rng)};
  const kvas = [25, 63, 100];
  final push = switch (fam) {
    M6GFam.branch => M6GPush.b,
    M6GFam.main => M6GPush.b, // (c) replaces it below when the bank is swollen
    M6GFam.ug => const [M6GPush.a, M6GPush.d, M6GPush.e][rng.nextInt(3)],
    M6GFam.dtrOil => M6GPush.g,
    M6GFam.coord || M6GFam.ltWay => M6GPush.f,
  };
  final swollen = bank && fam.mainDead && rng.nextBool();
  final ways = 3 + rng.nextInt(2);
  // Never ফিডার-5: that is the tie's feeder.
  const feeders = [2, 3, 4, 6, 7, 8, 9];
  final stuck = pick(4);
  return M6GDeal(
    fam: fam,
    feederNo: feeders[rng.nextInt(feeders.length)],
    ptwNo: 100 + rng.nextInt(900),
    incomplete: rng.nextBool(),
    stuck: abs.contains(M6GDev.dtr) ? null : stuck,
    partSeat: pick(4),
    leads: leads,
    bank: bank,
    swollen: swollen,
    stripCut: fam == M6GFam.coord && rng.nextBool(),
    kva: kvas[rng.nextInt(3)],
    flags: flagsPool[rng.nextInt(flagsPool.length)],
    tries: 2 + rng.nextInt(2),
    counter: 100 + rng.nextInt(800),
    twist: fam == M6GFam.dtrOil || rng.nextBool() ? M6GTwist.none : (rng.nextBool() ? M6GTwist.lcd : M6GTwist.blank),
    excavator: fam != M6GFam.ug && rng.nextInt(5) < 2,
    crows: rng.nextBool(),
    push: fam == M6GFam.main && swollen && rng.nextBool() ? M6GPush.c : push,
    reqOrder: reqOrder,
    way: 1 + rng.nextInt(ways),
    ways: ways,
    hour: 1 + rng.nextInt(3),
    minute: rng.nextInt(50),
    tieClosed: fam.mainDead && rng.nextInt(3) == 0,
  );
}

// ============================================================================
// The run (pure rules)
// ============================================================================

/// What a move leads to (the page plays it out in this order).
@immutable
class M6GOutcome {
  const M6GOutcome({this.mistake, this.note, this.reason, this.deck, this.say, this.lit = false, this.done = false, this.pay = 0, this.slipFirst = false});

  /// A deadly move (ends the play) or a slip.
  final DoMistake? mistake;

  /// The raw note (a reading, a reply, what the crew did).
  final String? note;

  /// ◆ after the move.
  final M6GReason? reason;

  /// A crew deck opens.
  final M6GDeck? deck;

  /// A soft guide line (no cost).
  final String? say;

  /// The light came back (restore done).
  final bool lit;

  /// The play is finished (pass panel next).
  final bool done;

  /// Points without a reason (a right cause card).
  final int pay;

  /// The slip card comes before the deck/reason (one slip per move).
  final bool slipFirst;

  bool get deadly => mistake?.deadly ?? false;
}

class M6GRun {
  M6GRun(this.deal) {
    abOpen[M6GDev.abT] = !deal.tieClosed;
  }
  final M6GDeal deal;

  M6GFam get fam => deal.fam;

  var marked = false;
  final asked = <M6GReq>{};

  /// PTW requests answered: complete or incomplete.
  final complete = <M6GReq>{};
  final incompleteAsked = <M6GReq>{};
  var relayLogged = false;
  var cbOnDone = false;
  var rcNormalDone = false;
  var s3CloseDone = false;

  final abOpen = <M6GDev, bool>{};
  final looked = <M6GDev>{};

  /// The isolators whose handle earth lead has been checked.
  final leadChecked = <M6GDev>{};

  /// The isolators whose blades were looked at since their last stroke.
  final bladesSeen = <M6GDev>{};
  final fixedLeads = <M6GDev>{};
  M6GDev? stuck;
  M6GDev? partSeat;
  var _stuckUsed = false;
  var _partUsed = false;

  var ltOff = false;
  var ltLocked = false;
  var ltTested = false;
  final tested = <M6GSec>{};
  final earthed = <M6GSec>{};

  var bankOff = false;
  int bankOffAt = 0;
  var clamp = false;
  final rodded = <int>{};
  var rodSlipped = false;
  var bankRemoved = false;
  var bankRight = false;

  var fixed = false; // the main cause (storm damage, joint, oil, nick)
  var jugaadOut = false;
  var hgDone = false;
  var stripFixed = false;
  var nickSealed = false;
  var hrcDone = false;
  var restored = false;
  var twistDue = false;
  var twistDone = false;
  var finished = false;

  int slips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  bool quick = true;

  /// Game minutes since the call.
  int minutes = 0;

  /// Moments judged so far (the hint key moves on with them).
  int judged = 0;

  bool get ended => finished || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => finished && deadly == null && percent >= 55;

  void tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// The PTW request of the family's path (X1: every crew-up path; the LT
  /// way's work takes the DTR's PTW, lesson 6.6 'PTW, PPE').
  M6GReq get ptwReq => switch (fam) {
        M6GFam.branch || M6GFam.main => M6GReq.rcNrPtw,
        M6GFam.ug => M6GReq.cbOffPtw,
        M6GFam.dtrOil || M6GFam.coord || M6GFam.ltWay => M6GReq.dtrPtw,
      };

  /// The PTW for work on [s] is in hand (a complete answer).
  bool ptwFor(M6GSec s) => switch (s) {
        M6GSec.main => fam.mainDead && complete.contains(ptwReq),
        M6GSec.branch => fam == M6GFam.branch && complete.contains(M6GReq.rcNrPtw),
        M6GSec.dtr || M6GSec.lt => complete.contains(M6GReq.dtrPtw),
      };

  /// The upstream of [ab] is confirmed OFF (an opening is off-load).
  bool offConfirmed(M6GDev ab) => switch (ab) {
        M6GDev.ab1 || M6GDev.ab2 || M6GDev.abT => fam.mainDead && complete.contains(ptwReq) && !_mainOn,
        M6GDev.abA => fam == M6GFam.branch && !s3CloseDone && (asked.contains(M6GReq.s3Info) || looked.contains(M6GDev.s3)),
        M6GDev.dtr => ltOff,
        _ => false,
      };

  /// The main has been switched back on.
  bool get _mainOn => cbOnDone || rcNormalDone;

  /// The upstream of [ab] is ON again (closing now is on load).
  bool upstreamOn(M6GDev ab) => switch (ab) {
        M6GDev.ab1 || M6GDev.ab2 => !fam.mainDead || _mainOn,
        M6GDev.abA => fam != M6GFam.branch || s3CloseDone,
        M6GDev.dtr => !ltOff,
        _ => true,
      };

  /// Both ends open (and, on the main, the tie AB-T open): every source is
  /// isolated. [tie] false: only whether the section is dead now — a closed
  /// tie's ফিডার-5 is tripped (0 V) but could come back (see [M6GDev.abT]).
  /// A stuck blade does not make the section live: it is only dealt where
  /// the AB's source is confirmed OFF, so it is a slip (R35, M6-3), not a
  /// live phase; it must still be freed and seen before the restore.
  bool isolated(M6GSec s, {bool tie = true}) => switch (s) {
        M6GSec.lt => ltOff,
        _ => m6gEndsOf(s).every((a) => abOpen[a] ?? false) &&
            (s != M6GSec.branch || fam == M6GFam.branch) &&
            (!tie || s != M6GSec.main || (abOpen[M6GDev.abT] ?? false)),
      };

  M6GOutcome _slip(M6GMistake x, {String? note, M6GReason? reason, M6GDeck? deck}) {
    slips++;
    quick = false;
    judged++;
    return M6GOutcome(mistake: x.m, note: note, reason: reason, deck: deck, slipFirst: true);
  }

  M6GOutcome _die(M6GMistake x) {
    deadly = x.m;
    return M6GOutcome(mistake: x.m);
  }

  /// Soft block: nothing but looking and asking before the fault is marked.
  M6GOutcome? _markFirst() => marked ? null : const M6GOutcome(say: M6GateLines.markFirst);

  // --- চোখ -----------------------------------------------------------------
  M6GOutcome look(M6GDev d) {
    if (ended) return const M6GOutcome();
    minutes += 1;
    looked.add(d);
    if (m6gAbs.contains(d)) {
      bladesSeen.add(d);
      leadChecked.add(d);
    }
    return M6GOutcome(note: M6GateLines.look(this, d));
  }

  // --- the chalk ------------------------------------------------------------
  M6GOutcome mark(M6GSec s) {
    if (ended || marked) return const M6GOutcome();
    if (s != fam.sec) return _slip(M6GMistakes.wrongSec);
    marked = true;
    judged++;
    return const M6GOutcome(reason: M6GReason.find);
  }

  /// Waiting on the watch.
  void wait() {
    if (!ended) minutes += 1;
  }

  // --- রেডিও ------------------------------------------------------------------
  M6GOutcome radio(M6GReq q) {
    if (ended) return const M6GOutcome();
    if (!m6gInfoReqs.contains(q)) {
      final mf = _markFirst();
      if (mf != null) return mf;
    }
    minutes += 2;
    final x = deal;
    final isPtw = q == M6GReq.cbOffPtw || q == M6GReq.rcNrPtw || q == M6GReq.dtrPtw;
    if (isPtw && complete.contains(q)) return _slip(M6GMistakes.askAgain, note: M6GateLines.askedAgain);
    asked.add(q);
    switch (q) {
      case M6GReq.relay:
        if (fam != M6GFam.ug) return M6GOutcome(note: M6GateLines.reply(x, q, complete: true));
        final first = !relayLogged;
        relayLogged = true;
        if (first) judged++;
        return M6GOutcome(note: M6GateLines.reply(x, q, complete: true), reason: first ? M6GReason.relay : null);
      case M6GReq.cbOffPtw:
        if (fam != M6GFam.ug) return _slip(M6GMistakes.needless, note: M6GateLines.needlessFeeder);
        return _ptwAnswer(q);
      case M6GReq.rcNrPtw:
        if (fam == M6GFam.main || fam == M6GFam.branch) return _ptwAnswer(q);
        complete.add(q);
        return M6GOutcome(note: M6GateLines.reply(x, q, complete: true));
      case M6GReq.dtrPtw:
        if (fam == M6GFam.dtrOil || fam == M6GFam.coord || fam == M6GFam.ltWay) return _ptwAnswer(q);
        complete.add(q);
        return M6GOutcome(note: M6GateLines.reply(x, q, complete: true));
      case M6GReq.dtrOff:
        return _slip(M6GMistakes.needless, note: M6GateLines.needlessFeeder);
      case M6GReq.s3Open:
        if (fam != M6GFam.branch) return _slip(M6GMistakes.needless, note: M6GateLines.needlessFeeder);
        return M6GOutcome(note: M6GateLines.reply(x, q, complete: true));
      case M6GReq.cbOn:
        if (fam != M6GFam.ug || cbOnDone) return const M6GOutcome(note: M6GateLines.alreadyOn);
        return _switchOn(q);
      case M6GReq.rcNormal:
        if (fam == M6GFam.main && !rcNormalDone) return _switchOn(q);
        rcNormalDone = rcNormalDone || fam == M6GFam.branch;
        return M6GOutcome(note: fam == M6GFam.branch ? M6GateLines.reply(x, q, complete: true) : M6GateLines.alreadyOn);
      case M6GReq.s3Close:
        if (fam == M6GFam.branch && !s3CloseDone) return _switchOn(q);
        return M6GOutcome(note: M6GateLines.reply(x, q, complete: true));
      case M6GReq.rcCount || M6GReq.s3Info || M6GReq.dtrInfo:
        return M6GOutcome(note: M6GateLines.reply(x, q, complete: true));
    }
  }

  M6GOutcome _ptwAnswer(M6GReq q) {
    if (deal.incomplete && !incompleteAsked.contains(q)) {
      incompleteAsked.add(q);
      return M6GOutcome(note: M6GateLines.reply(deal, q, complete: false));
    }
    complete.add(q);
    final reAsked = incompleteAsked.contains(q);
    if (reAsked) judged++;
    return M6GOutcome(note: M6GateLines.reply(deal, q, complete: true), reason: reAsked ? M6GReason.reAsk : null);
  }

  /// The breaker ON / R-12 normal / S-3 লাগানো: the restore's last step.
  M6GOutcome _switchOn(M6GReq q) {
    final s = fam.sec;
    if (earthed.contains(s)) return _die(M6GMistakes.chargeCrew);
    if (!fixed) return _die(M6GMistakes.chargeFault);
    switch (q) {
      case M6GReq.cbOn:
        cbOnDone = true;
      case M6GReq.rcNormal:
        rcNormalDone = true;
      default:
        s3CloseDone = true;
        // F-A: the operator puts R-12 back to normal with S-3 (the reply says so).
        rcNormalDone = true;
    }
    final allIn = m6gEndsOf(s).every((a) => !(abOpen[a] ?? false));
    if (!allIn) return const M6GOutcome(note: M6GateLines.onNoLight);
    return _restoreDone(M6GateLines.reply(deal, q, complete: true));
  }

  /// The light is back: a part-seated blade or a swollen unit left costs one
  /// slip; then the restore ◆ (or +10 where no reason is asked).
  M6GOutcome _restoreDone(String note) {
    restored = true;
    twistDue = deal.twist != M6GTwist.none;
    judged++;
    final ps = partSeat;
    if (ps != null) {
      partSeat = null;
      return _slipLit(M6GMistakes.partSeat, note);
    }
    if (deal.swollen && !bankRemoved) return _slipLit(M6GMistakes.swollenLeft, note);
    if (fam == M6GFam.ltWay) return M6GOutcome(note: note, lit: true, pay: 10, done: !twistDue);
    return M6GOutcome(note: note, lit: true, reason: M6GReason.restore);
  }

  M6GOutcome _slipLit(M6GMistake x, String note) {
    slips++;
    quick = false;
    return M6GOutcome(mistake: x.m, note: note, lit: true, done: !twistDue, slipFirst: true);
  }

  // --- হাতল -------------------------------------------------------------------
  /// The handle dropped on [d]: null = the stroke sheet opens next (the
  /// handle is in hand), else what happened instead.
  M6GOutcome? handleDrop(M6GDev d) {
    if (ended) return const M6GOutcome();
    final mf = _markFirst();
    if (mf != null) return mf;
    if (d == M6GDev.bank) {
      minutes += 1;
      bankOff = !bankOff;
      if (bankOff) bankOffAt = minutes;
      return M6GOutcome(note: bankOff ? M6GateLines.bankOffNote : M6GateLines.bankOnNote);
    }
    if (!m6gAbs.contains(d)) return M6GOutcome(say: d == M6GDev.ltbox ? null : M6GateLines.noUse);
    final open = abOpen[d] ?? false;
    // The tie stays open (normally open point): no cost, no stroke.
    if (d == M6GDev.abT && open) return const M6GOutcome(say: M6GateLines.tieStays);
    // Deadly first: an opening on load (R4, X3/N2). A re-stroke that frees a
    // stuck blade or seats a half-seated one is the same operation again.
    if (!open && partSeat != d && !offConfirmed(d)) return _die(M6GMistakes.abOnLoad);
    // The lead (M6-1 / R35): looked at first, and whole. The crew fixes it
    // after the slip; the stroke waits.
    final bad = (deal.leads[d] ?? M6GLead.ok) != M6GLead.ok && !fixedLeads.contains(d);
    if (!leadChecked.contains(d) || bad) {
      leadChecked.add(d);
      fixedLeads.add(d);
      return _slip(M6GMistakes.leadBad, note: bad ? M6GateLines.leadFixed : null);
    }
    return null;
  }

  /// The stroke made (open or close by the AB's state); [stalled]: stopped
  /// midway (M6-3: only that is a slip).
  M6GOutcome stroke(M6GDev d, {required bool stalled}) {
    if (ended) return const M6GOutcome();
    minutes += 3;
    if (stalled) return _slip(M6GMistakes.stall);
    final open = abOpen[d] ?? false;
    if (open && stuck == d) {
      stuck = null;
      bladesSeen.remove(d);
      return const M6GOutcome(note: M6GateLines.freed);
    }
    if (!open && partSeat == d) {
      partSeat = null;
      bladesSeen.remove(d);
      return const M6GOutcome(note: M6GateLines.seated);
    }
    if (!open) {
      abOpen[d] = true;
      bladesSeen.remove(d);
      if (deal.stuck == d && !_stuckUsed) {
        _stuckUsed = true;
        stuck = d;
      }
      // The tie opened after the earths went on: now every source is open.
      if (d == M6GDev.abT && earthed.contains(M6GSec.main)) {
        judged++;
        return const M6GOutcome(note: M6GateLines.opened, reason: M6GReason.tie);
      }
      return const M6GOutcome(note: M6GateLines.opened);
    }
    // Closing.
    final s = m6gSecOf(d)!;
    if (upstreamOn(d)) {
      // The DTR's AB with its LT load on, or any AB after the line is ON.
      return _die(M6GMistakes.abCloseOnLoad);
    }
    if (d == M6GDev.dtr) {
      if (earthed.contains(s)) return _die(M6GMistakes.chargeCrew);
      if (fam == M6GFam.dtrOil) return _die(M6GMistakes.recharge);
      if (deal.stripCut && !stripFixed) return _die(M6GMistakes.stripCut);
      if (fam == M6GFam.coord && (!hgDone || !jugaadOut)) return _die(M6GMistakes.chargeFault);
    }
    abOpen[d] = false;
    bladesSeen.remove(d);
    if (deal.partSeat == d && !_partUsed) {
      _partUsed = true;
      partSeat = d;
    }
    return const M6GOutcome(note: M6GateLines.closed);
  }

  // --- the LT switch -----------------------------------------------------------
  M6GOutcome lt(M6GLt c) {
    if (ended) return const M6GOutcome();
    final mf = _markFirst();
    if (mf != null) return mf;
    minutes += 2;
    switch (c) {
      case M6GLt.offLock || M6GLt.offOnly:
        if (fam == M6GFam.branch && !ltOff) {
          ltOff = true;
          ltLocked = c == M6GLt.offLock;
          ltTested = false;
          return _slip(M6GMistakes.needless, note: M6GateLines.needlessFeeder);
        }
        ltOff = true;
        ltLocked = c == M6GLt.offLock;
        ltTested = false;
        return M6GOutcome(note: ltLocked ? M6GateLines.ltLockNote : M6GateLines.ltOffNote);
      case M6GLt.on:
        if (!ltOff) return const M6GOutcome(note: M6GateLines.alreadyOn);
        ltOff = false;
        ltLocked = false;
        ltTested = false;
        if (fam == M6GFam.ltWay && hrcDone && nickSealed && !restored) return _restoreDone(M6GateLines.ltOnNote);
        if (fam == M6GFam.coord && hgDone && jugaadOut && !(abOpen[M6GDev.dtr] ?? false) && !restored) {
          return _restoreDone(M6GateLines.ltOnNote);
        }
        return const M6GOutcome(note: M6GateLines.ltOnNote);
    }
  }

  // --- আর্থ সেট -----------------------------------------------------------------
  M6GOutcome earth(M6GDev d) {
    if (ended) return const M6GOutcome();
    final mf = _markFirst();
    if (mf != null) return mf;
    final s = m6gSecOf(d);
    if (s == null || s == M6GSec.lt) return const M6GOutcome(say: M6GateLines.noUse);
    minutes += 4;
    if (earthed.contains(s)) {
      earthed.remove(s);
      return const M6GOutcome(note: M6GateLines.earthOff);
    }
    // An earth on a live section (R29), then the order (N3, R35). A closed
    // tie's ফিডার-5 is tripped: the earth may go on (it guards against it).
    if (!isolated(s, tie: false)) return _die(M6GMistakes.earthLive);
    earthed.add(s);
    if (!tested.contains(s)) return _slip(M6GMistakes.earthUntested, note: M6GateLines.earthOn);
    final ends = m6gEndsOf(s);
    if (!ends.every(bladesSeen.contains) || ends.contains(stuck)) return _slip(M6GMistakes.gapsUnseen, note: M6GateLines.earthOn);
    // The tie still closed: its ◆ comes when it is opened.
    if (!isolated(s)) return const M6GOutcome(note: M6GateLines.earthOn);
    judged++;
    final why = s != M6GSec.main ? M6GReason.gaps : (deal.tieClosed ? M6GReason.tie : M6GReason.bothEnds);
    return M6GOutcome(note: M6GateLines.earthOn, reason: why);
  }

  // --- টেস্টার -----------------------------------------------------------------
  M6GOutcome test(M6GDev d) {
    if (ended) return const M6GOutcome();
    final mf = _markFirst();
    if (mf != null) return mf;
    final s = m6gSecOf(d);
    if (s == null) return const M6GOutcome(say: M6GateLines.noUse);
    minutes += 2;
    if (s == M6GSec.lt) {
      if (!ltOff) return const M6GOutcome(note: M6GateLines.testerLive);
      ltTested = true;
      return const M6GOutcome(note: M6GateLines.testerDead);
    }
    if (!isolated(s, tie: false)) return const M6GOutcome(note: M6GateLines.testerLive);
    tested.add(s);
    return const M6GOutcome(note: M6GateLines.testerDead);
  }

  // --- ডিসচার্জ রড ----------------------------------------------------------------
  /// The rod's clamp on earth.
  M6GOutcome rodClamp() {
    if (ended) return const M6GOutcome();
    clamp = true;
    return const M6GOutcome();
  }

  /// The rod's hook on terminal [i] (0–2).
  M6GOutcome rodHook(int i) {
    if (ended || rodded.contains(i)) return const M6GOutcome();
    if (!clamp) return _die(M6GMistakes.rodHook);
    // The rod is earthed: on a live section it is an earth on a live line.
    if (!isolated(M6GSec.main, tie: false)) return _die(M6GMistakes.earthLive);
    minutes += 1;
    rodded.add(i);
    final early = !bankOff || minutes - bankOffAt < 5;
    if (early && !rodSlipped) {
      rodSlipped = true;
      final r = _slip(M6GMistakes.rodEarly);
      if (rodded.length == 3) return M6GOutcome(mistake: r.mistake, note: M6GateLines.rodDone, slipFirst: true);
      return r;
    }
    if (rodded.length == 3) {
      if (rodSlipped) return const M6GOutcome(note: M6GateLines.rodDone);
      judged++;
      return const M6GOutcome(note: M6GateLines.rodDone, reason: M6GReason.bank);
    }
    return const M6GOutcome();
  }

  /// The rod may be used on [d] (only the bank has terminals for it).
  bool rodFits(M6GDev d) => d == M6GDev.bank && deal.bank;

  // --- ক্রু ------------------------------------------------------------------------
  /// The checks before any hands-on HT work on [s] (deadly first).
  M6GOutcome? _htReady(M6GSec s) {
    // A section in service (not the dealt fault's) is live: crew up = R1.
    final inService = switch (s) {
      M6GSec.main => !fam.mainDead,
      M6GSec.branch => fam != M6GFam.branch,
      M6GSec.dtr => fam != M6GFam.dtrOil && fam != M6GFam.coord,
      M6GSec.lt => false,
    };
    if (inService) return _die(M6GMistakes.crewLive);
    if (!ptwFor(s)) {
      // Crew up without the PTW (N8); on a recloser line without Non-Reclose (R3).
      final recloser = s == M6GSec.branch || (s == M6GSec.main && fam == M6GFam.main);
      return _die(recloser ? M6GMistakes.noNonReclose : M6GMistakes.noPtw);
    }
    // Every source open (the tie too, R1), then 0 V (X1: hands before the
    // 0 V = deadly), then the earth.
    if (!isolated(s)) return _die(M6GMistakes.crewLive);
    if (!tested.contains(s) || !earthed.contains(s)) return _die(M6GMistakes.handsNoEarth);
    return null;
  }

  /// The checks before LT work (X4): live = deadly; no PTW = deadly (X1,
  /// lesson 6.6 'PTW, PPE'); not locked or not proved = one slip (N4), and
  /// the work goes on.
  M6GOutcome? _ltReady() {
    if (!ltOff) return _die(M6GMistakes.liveLt);
    if (!ptwFor(M6GSec.lt)) return _die(M6GMistakes.noPtw);
    return null;
  }

  bool get _ltLoose => !ltLocked || !ltTested;

  /// The crew on [d]: a deck to pick from, or what happened.
  M6GOutcome crew(M6GDev d) {
    if (ended) return const M6GOutcome();
    final mf = _markFirst();
    if (mf != null) return mf;
    if (d == M6GDev.cb || d == M6GDev.r12 || d == M6GDev.s3) return const M6GOutcome(say: M6GateLines.noUse);
    // A cut or loose handle earth lead seen with চোখ: the crew fixes it at the
    // ground handle (no HT work).
    if (leadFixDue(d)) {
      minutes += 2;
      fixedLeads.add(d);
      return const M6GOutcome(note: M6GateLines.leadFixed);
    }
    minutes += 6;
    // The twist: the house after the light is back.
    if (d == M6GDev.house && twistDue && !twistDone) {
      return M6GOutcome(deck: deal.twist == M6GTwist.lcd ? M6GDeck.twistLcd : M6GDeck.twistBlank);
    }
    final s = m6gSecOf(d)!;
    if (s == M6GSec.lt) {
      final r = _ltReady();
      if (r != null) return r;
      final deck = switch (d) {
        M6GDev.ltbox when fam == M6GFam.coord && !jugaadOut => M6GDeck.jugaad,
        M6GDev.ltbox when fam == M6GFam.ltWay && !hrcDone => M6GDeck.hrc,
        M6GDev.house when fam == M6GFam.ltWay && !nickSealed => M6GDeck.nick,
        _ => null,
      };
      if (deck == null) return const M6GOutcome(note: M6GateLines.nothingHere);
      if (_ltLoose) return _slip(M6GMistakes.ltNoLock, deck: deck);
      return M6GOutcome(deck: deck);
    }
    final r = _htReady(s);
    if (r != null) return r;
    if (d == M6GDev.bank) {
      if (!deal.bank) return const M6GOutcome(say: M6GateLines.noUse);
      if (rodded.length < 3) return _die(M6GMistakes.bankTouch);
      if (deal.swollen && !bankRemoved) return const M6GOutcome(deck: M6GDeck.bank);
      return const M6GOutcome(note: M6GateLines.bankSound);
    }
    final deck = switch (d) {
      M6GDev.branch when fam == M6GFam.branch && !fixed => M6GDeck.storm,
      M6GDev.span when fam == M6GFam.main && !fixed => M6GDeck.storm,
      M6GDev.ug when fam == M6GFam.ug && !fixed => M6GDeck.joint,
      M6GDev.dtr when fam == M6GFam.dtrOil && !fixed => M6GDeck.oil,
      M6GDev.dtr when fam == M6GFam.coord && deal.stripCut && !stripFixed && looked.contains(M6GDev.dtr) => M6GDeck.strip,
      M6GDev.dtr when fam == M6GFam.coord && !hgDone => M6GDeck.hg,
      _ => null,
    };
    if (deck == null) return const M6GOutcome(note: M6GateLines.nothingHere);
    if (fam == M6GFam.ug && deck == M6GDeck.joint && !relayLogged) return _slip(M6GMistakes.noRelay, deck: deck);
    return M6GOutcome(deck: deck);
  }

  /// A crew card picked from [deck] ([text]: the card's words, which tell
  /// the HRC deck's no-PPE slip from its wrong-rating slip).
  M6GOutcome pick(M6GDeck deck, M6GCard card, {String? text}) {
    if (ended) return const M6GOutcome();
    if (card == M6GCard.deadly) {
      return _die(switch (deck) {
        M6GDeck.oil => M6GMistakes.recharge,
        M6GDeck.jugaad || M6GDeck.hg || M6GDeck.hrc => M6GMistakes.nonFuse,
        M6GDeck.strip => M6GMistakes.stripCut,
        M6GDeck.nick => M6GMistakes.bareAb,
        _ => M6GMistakes.chargeFault,
      });
    }
    if (card == M6GCard.slip) {
      return _slip(switch (deck) {
        M6GDeck.storm => M6GMistakes.stormLeft,
        M6GDeck.joint => M6GMistakes.selfJoint,
        M6GDeck.oil => M6GMistakes.tankOpen,
        M6GDeck.jugaad => M6GMistakes.refuseEarly,
        M6GDeck.hg => M6GMistakes.wrongRating,
        M6GDeck.strip => M6GMistakes.stripLeft,
        M6GDeck.nick => M6GMistakes.nickOpen,
        M6GDeck.hrc => M6GateLines.hrcNoPpe.contains(text) ? M6GMistakes.noPpe : M6GMistakes.wrongHrc,
        M6GDeck.bank => M6GMistakes.swollenLeft,
        M6GDeck.twistLcd || M6GDeck.twistBlank => M6GMistakes.meterWrong,
      });
    }
    judged++;
    switch (deck) {
      case M6GDeck.storm:
        fixed = true;
        return const M6GOutcome(note: M6GateLines.crewDown, pay: 10);
      case M6GDeck.joint:
        fixed = true;
        return const M6GOutcome(note: M6GateLines.crewDown, reason: M6GReason.joint);
      case M6GDeck.oil:
        fixed = true;
        return const M6GOutcome(note: M6GateLines.sentShop, reason: M6GReason.oil, done: true);
      case M6GDeck.jugaad:
        jugaadOut = true;
        return const M6GOutcome(note: M6GateLines.crewDown, reason: M6GReason.fuse);
      case M6GDeck.hg:
        // The HG renewed before the jugaad is out: the cause is still there (R33).
        if (!jugaadOut) return _slip(M6GMistakes.refuseEarly);
        hgDone = true;
        fixed = true;
        return const M6GOutcome(note: M6GateLines.crewDown, pay: 10);
      case M6GDeck.strip:
        stripFixed = true;
        return const M6GOutcome(note: M6GateLines.crewDown, pay: 10);
      case M6GDeck.nick:
        nickSealed = true;
        fixed = true;
        return const M6GOutcome(note: M6GateLines.crewDown, pay: 10);
      case M6GDeck.hrc:
        if (!nickSealed) return _slip(M6GMistakes.refuseEarly);
        hrcDone = true;
        return const M6GOutcome(note: M6GateLines.crewDown, reason: M6GReason.fuse);
      case M6GDeck.bank:
        bankRemoved = true;
        return const M6GOutcome(note: M6GateLines.crewDown, pay: 10);
      case M6GDeck.twistLcd:
        twistDone = true;
        return const M6GOutcome(reason: M6GReason.twistLcd);
      case M6GDeck.twistBlank:
        twistDone = true;
        return const M6GOutcome(reason: M6GReason.twistBlank);
    }
  }

  /// The play is over (after the last reason).
  void finish() {
    if (deadly == null) finished = true;
  }

  /// The deck's three cards: one right, and one deadly (when the deck has
  /// one) plus slips to make three.
  List<(String, M6GCard)> deckFor(M6GDeck d, math.Random rng) {
    String one(M6GCard c) {
      final l = M6GateLines.deckCards(d, c, kva: deal.kva);
      return l[rng.nextInt(l.length)];
    }

    final deadlyCards = M6GateLines.deckCards(d, M6GCard.deadly, kva: deal.kva);
    final hasDeadly = switch (d) {
      M6GDeck.oil || M6GDeck.jugaad || M6GDeck.hg || M6GDeck.strip || M6GDeck.nick || M6GDeck.hrc => deadlyCards.isNotEmpty,
      _ => false,
    };
    final slips = [...M6GateLines.deckCards(d, M6GCard.slip, kva: deal.kva)]..shuffle(rng);
    return [
      (one(M6GCard.right), M6GCard.right),
      if (hasDeadly) (one(M6GCard.deadly), M6GCard.deadly),
      for (final s in slips.take(hasDeadly ? 1 : 2)) (s, M6GCard.slip),
    ]..shuffle(rng);
  }

  /// Listening to the coworker: deadly in every variant (X2).
  DoMistake listened() {
    deadly = switch (push) {
      M6GPush.a => M6GMistakes.crewLive.m,
      M6GPush.b => M6GMistakes.noNonReclose.m,
      M6GPush.c => M6GMistakes.bankTouch.m,
      M6GPush.d => M6GMistakes.abOnLoad.m,
      M6GPush.e => M6GMistakes.abCloseOnLoad.m,
      M6GPush.f => M6GMistakes.nonFuse.m,
      M6GPush.g => M6GMistakes.recharge.m,
    };
    return deadly!;
  }

  /// [d]'s handle earth lead was seen cut or loose and is not fixed yet.
  bool leadFixDue(M6GDev d) => m6gAbs.contains(d) && leadChecked.contains(d) && (deal.leads[d] ?? M6GLead.ok) != M6GLead.ok && !fixedLeads.contains(d);

  M6GPush? _pushNow;

  /// The coworker's variant now. (d) fits only while the breaker OFF is not
  /// confirmed; a player who got the PTW first meets (a) at the crew drop
  /// instead, so he still comes once in every play. Fixed once he comes.
  M6GPush get push => _pushNow ?? (deal.push == M6GPush.d && offConfirmed(M6GDev.ab1) ? M6GPush.a : deal.push);

  /// The decisive control the coworker waits on: [tok] dropped on [d]. Every
  /// variant's moment lies on every path of its family (he cannot be skipped).
  bool coworkerMoment(M6GTok tok, M6GDev d) {
    if (!marked || (tok == M6GTok.crew && leadFixDue(d))) return false;
    final p = push;
    final now = switch (p) {
      // (c): the first crew drop on the main section, the bank or the damage.
      M6GPush.a || M6GPush.b || M6GPush.c => tok == M6GTok.crew && m6gSecOf(d) == fam.sec,
      M6GPush.d => tok == M6GTok.handle && (d == M6GDev.ab1 || d == M6GDev.ab2) && !(abOpen[d] ?? false) && !offConfirmed(d),
      M6GPush.e => tok == M6GTok.handle && (d == M6GDev.ab1 || d == M6GDev.ab2) && (abOpen[d] ?? false) && stuck != d && fixed,
      M6GPush.f => tok == M6GTok.crew && d == M6GDev.ltbox,
      M6GPush.g => tok == M6GTok.crew && d == M6GDev.dtr,
    };
    if (now) _pushNow = p;
    return now;
  }

  /// The stage the guide's task line follows.
  int get stage => !marked
      ? 0
      : restored
          ? 4
          : fixedAll
              ? 3
              : _deadDone
                  ? 2
                  : 1;

  bool get _deadDone => switch (fam) {
        M6GFam.ltWay => ltOff,
        _ => earthed.contains(fam.sec),
      };

  /// Every cause of the family is put right.
  bool get fixedAll => switch (fam) {
        M6GFam.coord => jugaadOut && hgDone,
        M6GFam.ltWay => nickSealed && hrcDone,
        _ => fixed,
      };
}

// ============================================================================
// Pack, probe
// ============================================================================

@immutable
class M6GatePack {
  const M6GatePack({required this.id, required this.titleBn, this.quickMs = 300000});
  final String id;
  final String titleBn;

  /// The quick bonus: a clean play inside this time (5 min, ~85 % of a
  /// clean play — the builder's estimate).
  final int quickMs;
}

const m6GatePacks = {
  'gate_m6': M6GatePack(id: 'gate_m6', titleBn: M6GateLines.title),
};

/// Test hook: what the gate is doing now. Never used by the app.
class M6GateProbe {
  _M6GRunPageState? _s;
  M6GDeal? get deal => _s?._run.deal;
  M6GRun? get run => _s?._run;

  /// intro, idle, lifted, chalk, lens, radio, send, stroke, lt, ltSend, rod,
  /// deck, freeze, done.
  String get phase => _s?._phase.name ?? 'none';

  /// The right cards of the deck now up (reason, crew deck or coworker).
  List<String> get rightNow {
    final s = _s;
    if (s == null) return const [];
    if (s.coworkerChoiceUp) return s.coworkerScript.right;
    if (s.reasonOpen) return s._reasonRight;
    if (s._phase == _Phase.deck) return [for (final e in s._deckClass.entries) if (e.value == M6GCard.right) e.key];
    return const [];
  }

  /// The crew deck's cards of class [c] now up.
  List<String> deckOf(M6GCard c) {
    final s = _s;
    if (s == null || s._phase != _Phase.deck) return const [];
    return [for (final e in s._deckClass.entries) if (e.value == c) e.key];
  }

  bool get coworkerUp => _s?.coworkerOpen ?? false;
  bool get busy => _s?.tableBusy ?? false;
  int get score => _s?._runScore ?? 0;
  double get pan => _s?._pan ?? 0;

  /// Pans the panorama so [d] is in the middle (tests only).
  void panTo(M6GDev d) => _s?._panTo(d);
}

// ============================================================================
// Page
// ============================================================================

class M6GateStormFeederPage extends StatefulWidget {
  const M6GateStormFeederPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed, this.probe});

  final LevelContext ctx;
  final M6GatePack pack;
  final bool muted;
  final int? seed;
  final M6GateProbe? probe;

  @override
  State<M6GateStormFeederPage> createState() => _M6GateStormFeederPageState();
}

class _M6GateStormFeederPageState extends State<M6GateStormFeederPage> {
  int _round = 0;
  late bool _muted = widget.muted;
  M6GFam? _last;

  @override
  Widget build(BuildContext context) => _M6GRunPage(
        key: ValueKey(_round),
        ctx: widget.ctx,
        pack: widget.pack,
        muted: _muted,
        probe: widget.probe,
        avoid: _last,
        rng: widget.seed == null ? math.Random() : math.Random(widget.seed! + _round),
        onDealt: (f) => _last = f,
        onRetry: (m) => setState(() {
          _muted = m;
          _round++;
        }),
      );
}

class _M6GRunPage extends ConsumerStatefulWidget {
  const _M6GRunPage({
    super.key,
    required this.ctx,
    required this.pack,
    required this.muted,
    required this.rng,
    required this.onRetry,
    required this.onDealt,
    this.avoid,
    this.probe,
  });

  final LevelContext ctx;
  final M6GatePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;
  final ValueChanged<M6GFam> onDealt;
  final M6GFam? avoid;
  final M6GateProbe? probe;

  @override
  ConsumerState<_M6GRunPage> createState() => _M6GRunPageState();
}

enum _Phase { intro, idle, lifted, chalk, lens, radio, send, stroke, lt, ltSend, rod, deck, freeze, done }

class _M6GRunPageState extends ConsumerState<_M6GRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6GRun _run = M6GRun(dealM6G(widget.rng, avoid: widget.avoid));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The windows lighting up after the restore (0 → 1).
  late final AnimationController _lit = AnimationController(vsync: this, duration: const Duration(milliseconds: 900), value: 1);

  /// A deadly move playing out in colour (0 → 1).
  late final AnimationController _harm = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  _Phase _phase = _Phase.intro;
  int _runScore = 0;
  int _chain = 0;
  double _pan = 0;
  String? _note;

  // The move being made.
  M6GTok? _lifted;
  M6GDev? _dev;
  M6GReq? _req;
  M6GLt? _ltPick;
  String _lens = '';

  // The crew deck.
  M6GDeck? _deck;
  List<ChoiceOption> _deckOpts = const [];
  final Map<String, M6GCard> _deckClass = {};
  String? _deckPicked;
  M6GDev? _crewAt;

  // The ◆ question now and what follows its proceed.
  M6GReason? _reasonNow;
  List<String> _reasonRight = const [];
  VoidCallback? _afterReason;

  // Cards.
  DoMistake? _card;
  MistakeTone _cardTone = MistakeTone.slip;
  String _cardLesson = '6.11';
  VoidCallback? _afterCard;
  var _freeze = false;
  Completer<void>? _frozen;
  Offset _harmAt = const Offset(180, 300);

  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _lastStage = -1;
  String _rankFrom = M6GateLines.rankFrom;
  String _rankTo = M6GateLines.rankTo;

  final _nudge = TaskNudge();
  int _nudgeN = 0;
  final _hints = IdleHintController();
  var _hintFlip = false;
  final Map<String, GlobalKey> _keys = {};
  final _sendKey = GlobalKey(debugLabel: 'm6g-send');
  final _leverKey = GlobalKey(debugLabel: 'm6g-lever');
  final _lensCloseKey = GlobalKey(debugLabel: 'm6g-lens-close');
  M6GGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M6GDeal get _deal => _run.deal;

  GlobalKey _k(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    widget.probe?._s = this;
    widget.onDealt(_run.fam);
  }

  @override
  void dispose() {
    if (widget.probe?._s == this) widget.probe?._s = null;
    disposeCoworker();
    _lit.dispose();
    _harm.dispose();
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

  void _cue(String path, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(path, volume: volume, muted: false));
  }

  Offset _centre() {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  /// A device's centre on screen (global px) for the score fly.
  Offset _devGlobal(M6GDev d) {
    final g = _geo;
    if (g == null) return _centre();
    final size = MediaQuery.sizeOf(context);
    final r = g.dev(d.index, _pan);
    final k = size.width / 360;
    return Offset(r.center.dx.clamp(0.0, 360.0) * k, r.center.dy * k);
  }

  /// A device's centre in scene px (the harm painter's space).
  Offset _devScene(M6GDev d) {
    final g = _geo;
    if (g == null) return const Offset(180, 300);
    final r = g.dev(d.index, _pan);
    return Offset(r.center.dx.clamp(0.0, 360.0), r.center.dy);
  }

  void _panTo(M6GDev d) {
    if (!mounted) return;
    setState(() => _pan = M6GGeo.panFor(d.index));
  }

  // --- the play ---------------------------------------------------------------
  void _start() {
    _clock.start();
    _rankNames();
    setState(() => _phase = _Phase.idle);
    _lastStage = 0;
    unawaited(_sayChain([M6GateLines.taskFind]));
  }

  void _rankNames() {
    List<CatalogModule> mods;
    try {
      mods = ref.read(contentCatalogProvider).value?.modules ?? const [];
    } catch (_) {
      mods = const [];
    }
    for (final m in mods) {
      if (m.id == 'm5' && m.rankName.isNotEmpty) _rankFrom = m.rankName;
      if (m.id == 'm6' && m.rankName.isNotEmpty) _rankTo = m.rankName;
    }
  }

  String get _stageTask => switch (_run.stage) {
        0 => M6GateLines.taskFind,
        1 => M6GateLines.taskDead,
        2 => M6GateLines.taskFix,
        3 => M6GateLines.taskRestore,
        _ => M6GateLines.taskTwist,
      };

  /// The scene takes a touch now (no card, deck or praise window).
  bool get _free => !_ended && _card == null && !tableBusy && !coworkerOpen;

  void _toIdle() {
    if (!mounted || _ended) return;
    setState(() {
      _phase = _Phase.idle;
      _lifted = null;
      _req = null;
      _ltPick = null;
      _crewAt = null;
    });
    final st = _run.stage;
    if (st != _lastStage) {
      _lastStage = st;
      unawaited(_sayChain([_stageTask]));
    }
  }

  void _setNote(String? n) {
    if (n == null || n.isEmpty || !mounted) return;
    setState(() => _note = n);
  }

  // --- the belt ---------------------------------------------------------------
  void _tapToken(M6GTok t) {
    if (!_free || !(_phase == _Phase.idle || _phase == _Phase.lifted || _phase == _Phase.chalk)) {
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.45);
    setState(() {
      _lifted = _lifted == t ? null : t;
      _phase = _lifted == null ? _Phase.idle : _Phase.lifted;
    });
    if (_lifted != null) unawaited(_sayChain([M6GateLines.taskLifted]));
  }

  void _tapDev(M6GDev d) {
    final t = _lifted;
    if (_phase == _Phase.lifted && t != null) {
      _drop(t, d);
      return;
    }
    _hints.missTap();
  }

  void _tapChalk() {
    if (!_free || _run.marked || !(_phase == _Phase.idle || _phase == _Phase.lifted || _phase == _Phase.chalk)) {
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _lifted = null;
      _phase = _phase == _Phase.chalk ? _Phase.idle : _Phase.chalk;
    });
    if (_phase == _Phase.chalk) unawaited(_sayChain([M6GateLines.taskChalk]));
  }

  void _tapSketch(M6GSec s) {
    if (_phase == _Phase.chalk) {
      _markSec(s);
      return;
    }
    _hints.missTap();
  }

  void _markSec(M6GSec s) {
    if (!_free || _run.marked) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    _hush();
    final o = _run.mark(s);
    _toIdle();
    _apply(o, at: _centre());
  }

  void _tapWatch() {
    if (!_free || _phase != _Phase.idle) {
      _hints.missTap();
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    _run.wait();
    _setNote(M6GateLines.waited);
  }

  /// A token dropped on a device: one step.
  void _drop(M6GTok t, M6GDev d) {
    if (!_free) return;
    // The path's decisive control waits for the coworker (once a play).
    if (!coworkerDone && _run.coworkerMoment(t, d)) {
      if (!coworkerDue) scheduleCoworker();
      if (holdForCoworker()) {
        setState(() {
          _lifted = null;
          _phase = _Phase.idle;
          _dev = d;
        });
        return;
      }
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    _hush();
    final at = _devGlobal(d);
    final scene = _devScene(d);
    setState(() {
      _lifted = null;
      _dev = d;
    });
    switch (t) {
      case M6GTok.eye:
        final o = _run.look(d);
        setState(() {
          _lens = o.note ?? '';
          _phase = _Phase.lens;
        });
        unawaited(_sayChain([M6GateLines.taskLens]));
      case M6GTok.radio:
        if (!m6gRadioDevs.contains(d)) {
          _toIdle();
          unawaited(_sayChain([M6GateLines.radioWhere]));
          return;
        }
        setState(() => _phase = _Phase.radio);
        unawaited(_sayChain([M6GateLines.taskRadio]));
      case M6GTok.handle:
        if (d == M6GDev.ltbox) {
          if (!_run.marked) {
            _toIdle();
            unawaited(_sayChain([M6GateLines.markFirst]));
            return;
          }
          setState(() => _phase = _Phase.lt);
          unawaited(_sayChain([M6GateLines.taskLt]));
          return;
        }
        final o = _run.handleDrop(d);
        if (o == null) {
          setState(() => _phase = _Phase.stroke);
          unawaited(_sayChain([M6GateLines.taskStroke]));
          return;
        }
        _toIdle();
        _apply(o, at: at, scene: scene);
      case M6GTok.earth:
        _toIdle();
        _apply(_run.earth(d), at: at, scene: scene);
      case M6GTok.tester:
        _toIdle();
        _apply(_run.test(d), at: at, scene: scene);
      case M6GTok.rod:
        if (!_run.marked) {
          _toIdle();
          unawaited(_sayChain([M6GateLines.markFirst]));
          return;
        }
        if (!_run.rodFits(d)) {
          _toIdle();
          unawaited(_sayChain([M6GateLines.noUse]));
          return;
        }
        setState(() => _phase = _Phase.rod);
        unawaited(_sayChain([M6GateLines.taskRod]));
      case M6GTok.crew:
        final o = _run.crew(d);
        _toIdle();
        if (o.deck != null) setState(() => _crewAt = d);
        _apply(o, at: at, scene: scene);
    }
  }

  /// Plays a move's outcome out: deadly → freeze; else the note, then the
  /// slip card (if any), then the deck / reason / points, then what follows.
  void _apply(M6GOutcome o, {required Offset at, Offset? scene}) {
    if (!mounted || _ended) return;
    if (o.deadly) {
      unawaited(_deadly(o.mistake!, at: scene ?? const Offset(180, 300)));
      return;
    }
    _setNote(o.note);
    if (o.say != null) unawaited(_sayChain([o.say!]));
    if (o.lit) _lightUp();
    void next() {
      if (!mounted || _ended) return;
      if (o.deck != null) {
        _openDeck(o.deck!);
        return;
      }
      if (o.reason != null) {
        _reason(o.reason!, then: () => _after(o));
        return;
      }
      if (o.pay > 0) {
        unawaited(_levelDelta(o.pay, at, mood: GuideMood.glad));
        if (!o.done && !o.lit) unawaited(_sayChain([M6GateLines.fixRight], mood: GuideMood.glad));
      }
      _after(o);
    }

    if (o.mistake != null) {
      unawaited(_slip(o.mistake!, then: next));
      return;
    }
    next();
  }

  /// After a judged move: the end of the play, or back to the scene.
  void _after(M6GOutcome o) {
    if (!mounted || _ended) return;
    final r = _run;
    final closing = o.done ||
        (o.lit && !r.twistDue) ||
        (o.reason == M6GReason.restore && !r.twistDue) ||
        o.reason == M6GReason.twistLcd ||
        o.reason == M6GReason.twistBlank;
    if (closing) {
      unawaited(_finish());
      return;
    }
    _toIdle();
  }

  void _lightUp() {
    _cue('sounds/quiz_complete.ogg', volume: 0.6);
    if (_quiet) {
      _lit.value = 1;
    } else {
      unawaited(_lit.forward(from: 0));
    }
    unawaited(_sayChain([M6GateLines.lit], mood: GuideMood.glad));
  }

  void _cancelSheet() {
    HapticFeedback.selectionClick();
    _hush();
    _toIdle();
  }

  // --- the radio ---------------------------------------------------------------
  void _pickReq(M6GReq q) {
    if (_phase != _Phase.radio) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.5);
    setState(() {
      _req = q;
      _phase = _Phase.send;
    });
    unawaited(_sayChain([M6GateLines.taskSend]));
  }

  void _sendRadio() {
    final q = _req;
    if (_phase != _Phase.send || q == null || _ended) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/dmm_beep.ogg', volume: 0.55);
    _hush();
    final d = _dev ?? M6GDev.cb;
    final o = _run.radio(q);
    _toIdle();
    _apply(o, at: _devGlobal(d), scene: _devScene(d));
  }

  // --- the LT switch ---------------------------------------------------------------
  void _pickLt(M6GLt c) {
    if (_phase != _Phase.lt) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.ogg', volume: 0.5);
    setState(() {
      _ltPick = c;
      _phase = _Phase.ltSend;
    });
  }

  void _doLt() {
    final c = _ltPick;
    if (_phase != _Phase.ltSend || c == null || _ended) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_select.ogg', volume: 0.6);
    _hush();
    final o = _run.lt(c);
    _toIdle();
    _apply(o, at: _devGlobal(M6GDev.ltbox), scene: _devScene(M6GDev.ltbox));
  }

  // --- the handle's stroke -------------------------------------------------------
  void _stroked(bool stalled) {
    final d = _dev;
    if (_phase != _Phase.stroke || d == null || _ended) return;
    HapticFeedback.heavyImpact();
    _cue(stalled ? 'sounds/quiz_wrong.ogg' : 'sounds/learn/tag_slap.ogg', volume: 0.6);
    final o = _run.stroke(d, stalled: stalled);
    _toIdle();
    _apply(o, at: _devGlobal(d), scene: _devScene(d));
  }

  // --- the rod -----------------------------------------------------------------------
  void _rodClamp() {
    if (_phase != _Phase.rod || !_free) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.5);
    setState(() => _run.rodClamp());
  }

  void _rodHook(int i) {
    if (_phase != _Phase.rod || !_free) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/spark.ogg', volume: 0.35);
    final o = _run.rodHook(i);
    setState(() {});
    final done = _run.rodded.length == 3;
    if (done || o.deadly) _toIdle();
    if (o.deadly || o.mistake != null || o.reason != null || o.note != null) {
      // A slip card waits over the open rod sheet; the rest follow it.
      _apply(o, at: _devGlobal(M6GDev.bank), scene: _devScene(M6GDev.bank));
    }
  }

  // --- the crew deck -------------------------------------------------------------------
  void _openDeck(M6GDeck d) {
    final cards = _run.deckFor(d, widget.rng);
    setState(() {
      _deck = d;
      _deckClass
        ..clear()
        ..addEntries([for (final c in cards) MapEntry(c.$1, c.$2)]);
      _deckOpts = [for (final c in cards) ChoiceOption(c.$1, c.$2 == M6GCard.right)];
      _deckPicked = null;
      _phase = _Phase.deck;
      _crewAt ??= _dev;
    });
    unawaited(_sayChain([M6GateLines.taskDeck]));
  }

  Future<void> _pickDeck(ChoiceOption o) async {
    final d = _deck;
    if (_phase != _Phase.deck || d == null || _deckPicked != null) return;
    _hush();
    final c = _deckClass[o.textBn] ?? M6GCard.slip;
    setState(() => _deckPicked = o.textBn);
    if (c == M6GCard.right) {
      HapticFeedback.lightImpact();
      _cue('sounds/quiz_right.ogg', volume: 0.7);
    } else {
      HapticFeedback.mediumImpact();
      _cue('sounds/quiz_wrong.ogg');
    }
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 60 : 420));
    if (!mounted || _ended || _phase != _Phase.deck) return;
    final at = _crewAt ?? _dev ?? M6GDev.dtr;
    final out = _run.pick(d, c, text: o.textBn);
    setState(() {
      _deck = null;
      _deckOpts = const [];
      _deckClass.clear();
    });
    _toIdle();
    _apply(out, at: _devGlobal(at), scene: _devScene(at));
  }

  // --- the shared success beat (ReasonTable) ----------------------------------
  void _reason(M6GReason r, {required VoidCallback then}) {
    if (!mounted || _ended) return;
    _reasonNow = r;
    _afterReason = then;
    _reasonRight = M6GateLines.whyRight(r, fam: _run.fam);
    putOnTable(15);
    unawaited(askReason(
      deal: () => dealChoices(_reasonRight, M6GateLines.whyWrong(r), widget.rng),
      question: M6GateLines.question(r),
      stillValid: () => !_ended && _reasonNow == r,
    ));
  }

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
    final r = _reasonNow;
    if (r != null) _run.tag(M6GateLines.caught(r));
    _reasonNow = null;
    final then = _afterReason;
    _afterReason = null;
    then?.call();
  }

  // --- the shared pressure moment (CoworkerMoment) -------------------------------
  @override
  CoworkerScript get coworkerScript => M6GateLines.script(_run.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    if (_card != null || tableBusy) return false;
    return _phase == _Phase.idle || _phase == _Phase.lifted || _phase == _Phase.chalk;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listened();
      final d = _dev ?? _deal.pathAbs.firstOrNull ?? M6GDev.dtr;
      await _deadly(m, at: _devScene(d));
      return;
    }
    _run.tag(M6GateLines.caughtPush);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain || _ended) return;
      await _sayChain([M6GateLines.refused], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_phase == _Phase.intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6GateLines.tapWhy[_nudgeN++ % M6GateLines.tapWhy.length]
            : _nudge.next(switch (_phase) {
                _Phase.lifted => M6GateLines.taskLifted,
                _Phase.chalk => M6GateLines.taskChalk,
                _Phase.lens => M6GateLines.taskLens,
                _Phase.radio => M6GateLines.taskRadio,
                _Phase.send => M6GateLines.taskSend,
                _Phase.stroke => M6GateLines.taskStroke,
                _Phase.lt || _Phase.ltSend => M6GateLines.taskLt,
                _Phase.rod => M6GateLines.taskRod,
                _Phase.deck => M6GateLines.taskDeck,
                _ => _stageTask,
              });
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -----------------------------------------------------------------
  LevelContext _ctxFor(String lessonId) => LevelContext(
        rungId: widget.ctx.rungId,
        kind: widget.ctx.kind,
        lessonId: lessonId,
        lessonTitleBn: widget.ctx.lessonTitleBn,
        ladderStep: widget.ctx.ladderStep,
        doIndex: widget.ctx.doIndex,
        doCount: widget.ctx.doCount,
      );

  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, _ctxFor(_cardLesson), m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() => _phase = _Phase.done);
  }

  /// A slip: −10, its card (or the strike-out); [then] after "বুঝেছি".
  Future<void> _slip(DoMistake m, {required VoidCallback then}) async {
    if (_ended) return;
    _cardLesson = M6GMistakes.lessonOf(m);
    unawaited(_levelDelta(-10, _centre(), mood: GuideMood.warn));
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.ogg');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _afterCard = then;
    });
    unawaited(bookMistake(ref, _ctxFor(_cardLesson), m));
    final speak = await SpokenOnce.first('m6gate/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move plays out: the scene freezes grey and the consequence
  /// plays in colour at [at] (scene px); then near-miss or death.
  Future<void> _deadly(DoMistake m, {required Offset at}) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cardLesson = M6GMistakes.lessonOf(m);
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _phase = _Phase.freeze;
      _freeze = true;
      _harmAt = at;
      _deck = null;
      _deckOpts = const [];
    });
    if (_quiet) {
      _harm.value = 1;
    } else {
      unawaited(_harm.forward(from: 0));
    }
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m6gate/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6GateLines.deadlyWord : M6GateLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        final then = _afterCard;
        _afterCard = null;
        setState(() => _card = null);
        if (then != null) {
          then();
        } else {
          _toIdle();
        }
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
    _run.finish();
    _ended = true;
    _clock.stop();
    setState(() => _phase = _Phase.done);
    final save = ref.read(gameSaveProvider.notifier);
    final centre = _centre();
    final mark = _run.percent;
    await save.recordLevelResult(_rungId, mark);
    if (!mounted) return;
    final quick = _run.quick && _clock.elapsedMilliseconds <= widget.pack.quickMs;
    if (_run.passed) {
      await save.markRungCleared(_rungId);
      // The rank gate: অ্যাডভান্সড → সিনিয়র (Module 6's rank; ruling M6-10).
      await save.unlockRank(6);
      _passed = true;
      await _levelDelta(20, centre, mood: GuideMood.celebrate);
      if (mark == 100 && quick) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: quick);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    if (_run.passed) _cue('sounds/quiz_complete.ogg', volume: 0.85);
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(_run.passed ? M6GateLines.promoted(_rankTo) : M6GateLines.fail, mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- the scene -------------------------------------------------------------------
  /// Each house window: the live cue (honest, from the state).
  List<bool> _lights() {
    final r = _run;
    final f = r.fam;
    final restored = r.restored;
    final mainDark = f.mainDead && !restored;
    final branchDark = mainDark || (f == M6GFam.branch && !restored);
    final dtrDark = mainDark || r.ltOff || (r.abOpen[M6GDev.dtr] ?? false) || ((f == M6GFam.dtrOil || f == M6GFam.coord) && !restored);
    return [
      !mainDark,
      !mainDark,
      !branchDark,
      !branchDark,
      for (var i = 0; i < 3; i++)
        !dtrDark && !(f == M6GFam.ltWay && !restored && i == (_deal.way - 1) % 3) && !(r.twistDue && !r.twistDone && i == 1),
    ];
  }

  M6GView get _view => M6GView(
        pan: _pan,
        open: {for (final e in _run.abOpen.entries) if (e.value) e.key.index},
        earthed: {
          if (_run.earthed.contains(M6GSec.main)) 0,
          if (_run.earthed.contains(M6GSec.branch)) 1,
          if (_run.earthed.contains(M6GSec.dtr)) 2,
        },
        crewAt: _crewAt?.index,
        lights: _lights(),
        lit: _lit.value,
      );

  List<Widget> _scene(SceneMetrics m) {
    final g = _geo = M6GGeo(m.height, m.inset);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(colorFilter: grey, child: Stack(fit: StackFit.expand, children: _world(g))),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('harm'),
          child: IgnorePointer(child: CustomPaint(painter: M6GHarmPainter(at: _harmAt, k: _harm.value))),
        ),
    ];
  }

  List<Widget> _world(M6GGeo g) {
    final d = _deal;
    final live = _phase == _Phase.lifted;
    return [
      IgnorePointer(key: const ValueKey('pano-paint'), child: RepaintBoundary(child: CustomPaint(painter: M6GWorldPainter(geo: g, plan: d.plan, view: _view)))),
      // Labels a worker reads.
      if (M6GGeo.devX[0] - _pan > -60)
        Positioned(
          key: const ValueKey('ss-label'),
          left: M6GGeo.devX[0] - _pan - 50,
          width: 100,
          top: g.groundY - 164,
          child: IgnorePointer(
            child: Text(M6GateLines.substation, textAlign: TextAlign.center, style: bangla(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFE9EEF3))),
          ),
        ),
      // The panorama: swipe to pan; every device a drop target, all alike.
      Positioned.fromRect(
        key: const ValueKey('pano'),
        rect: g.pano,
        child: GestureDetector(
          key: const ValueKey('m6g-pano'),
          behavior: HitTestBehavior.opaque,
          onTap: _hints.missTap,
          onHorizontalDragUpdate: (det) {
            if (_phase == _Phase.intro || _freeze) return;
            setState(() => _pan = (_pan - det.delta.dx).clamp(0.0, M6GGeo.maxPan));
          },
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final dev in M6GDev.values)
                if (dev != M6GDev.bank || d.bank)
                  if (g.dev(dev.index, _pan).right > 0 && g.dev(dev.index, _pan).left < 360) _devTarget(g, dev, live),
            ],
          ),
        ),
      ),
      // The docket band: the call, the sketch and the chalk, the watch.
      Positioned.fromRect(key: const ValueKey('docket'), rect: g.docket, child: IgnorePointer(child: _DocketBand(call: M6GateLines.call(d.feederNo)))),
      for (final s in M6GSec.values)
        Positioned.fromRect(
          key: ValueKey('sec-${s.name}'),
          rect: g.sketch(s.index),
          child: DragTarget<String>(
            onWillAcceptWithDetails: (det) => det.data == 'chalk',
            onAcceptWithDetails: (_) => _markSec(s),
            builder: (context, cand, _) => GestureDetector(
              key: ValueKey('m6g-sec-${s.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tapSketch(s),
              child: _SketchBox(label: M6GateLines.sec(s), marked: _run.marked && _run.fam.sec == s, live: _phase == _Phase.chalk || cand.isNotEmpty),
            ),
          ),
        ),
      Positioned.fromRect(
        key: const ValueKey('chalk'),
        rect: g.chalk,
        child: _run.marked
            ? const SizedBox.shrink()
            : _ChalkToken(key: const ValueKey('m6g-chalk'), up: _phase == _Phase.chalk, onTap: _tapChalk, onDragStart: () {
                if (_free && _phase != _Phase.chalk) setState(() => _phase = _Phase.chalk);
              }),
      ),
      Positioned.fromRect(
        key: const ValueKey('watch'),
        rect: g.watch,
        child: GestureDetector(
          key: const ValueKey('m6g-watch'),
          behavior: HitTestBehavior.opaque,
          onTap: _tapWatch,
          child: _Watch(text: _clockText()),
        ),
      ),
      if (_note != null)
        Positioned(
          key: const ValueKey('note'),
          left: 10,
          right: 10,
          top: g.panoTop + 4,
          child: IgnorePointer(child: _NoteStrip(text: _note!)),
        ),
      // The belt.
      Positioned.fromRect(
        key: const ValueKey('belt'),
        rect: Rect.fromLTRB(0, g.beltTop, 360, g.h),
        child: const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF3A2A1A)))),
      ),
      for (final t in M6GTok.values)
        Positioned.fromRect(
          key: ValueKey('tok-${t.name}'),
          rect: g.tok(t.index),
          child: _TokenChip(
            key: ValueKey('m6g-tok-${t.name}'),
            tok: t,
            up: _lifted == t && _phase == _Phase.lifted,
            onTap: () => _tapToken(t),
            onDragStart: () {
              if (_free && (_phase == _Phase.idle || _phase == _Phase.lifted)) {
                setState(() {
                  _lifted = t;
                  _phase = _Phase.lifted;
                });
              }
            },
          ),
        ),
    ];
  }

  Widget _devTarget(M6GGeo g, M6GDev dev, bool live) {
    final r = g.dev(dev.index, _pan).shift(Offset(0, -g.panoTop));
    return Positioned.fromRect(
      key: ValueKey('dev-${dev.name}'),
      rect: r,
      child: DragTarget<M6GTok>(
        onAcceptWithDetails: (det) => _drop(det.data, dev),
        builder: (context, cand, _) => GestureDetector(
          key: ValueKey('m6g-dev-${dev.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _tapDev(dev),
          child: Semantics(
            button: true,
            label: M6GateLines.dev(dev),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // The same faint frame on every device while a tool is up.
                border: live || cand.isNotEmpty ? Border.all(color: const Color(0x88F2D27A), width: cand.isNotEmpty ? 2 : 1) : null,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _clockText() {
    final t = _deal.hour * 60 + _deal.minute + _run.minutes;
    final h = (t ~/ 60) % 12 == 0 ? 12 : (t ~/ 60) % 12;
    return enDigits('রাত $h:${(t % 60).toString().padLeft(2, '0')}');
  }

  /// How to touch now, never what.
  HintSpec? _hint() {
    final g = _geo;
    if (g == null) return null;
    switch (_phase) {
      case _Phase.lifted:
        final t = _lifted;
        if (t == null) return null;
        // A short nudge straight up out of the belt (never toward a device).
        return HintSpec.drag(g.tok(t.index).center, toward: const Offset(0, -1), travel: 56, space: HintSpace.scene);
      case _Phase.chalk:
        return HintSpec.sweep([for (var i = 0; i < 4; i++) g.sketch(i)], space: HintSpace.scene);
      default:
        // Alternately: a swipe across the panorama, a sweep over all seven tokens.
        _hintFlip = !_hintFlip;
        if (_hintFlip) return HintSpec.swipe(Offset(90, g.pano.center.dy), toward: const Offset(1, 0), travel: 180, space: HintSpace.scene);
        return HintSpec.sweep(g.tokens, space: HintSpace.scene);
    }
  }

  String get _strokeTitle {
    final d = _dev!;
    final open = _run.abOpen[d] ?? false;
    final closing = (open && _run.stuck != d) || (!open && _run.partSeat == d);
    return '${M6GateLines.dev(d)} · ${closing ? M6GateLines.strokeClose : M6GateLines.strokeOpen}';
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final scale = size.width / 360;
    final live = _phase != _Phase.intro && _mark == null && !struckOut && !_freeze;
    final scenePhase = _phase == _Phase.idle || _phase == _Phase.lifted || _phase == _Phase.chalk;
    final waiting = live && scenePhase && _card == null && !coworkerOnScreen && !tableBusy;
    final deckUp = reasonOpen || coworkerChoiceUp || (_phase == _Phase.deck && _deckOpts.isNotEmpty);
    final sheetUp = live && !deckUp && _card == null && !coworkerOnScreen && !tableBusy;
    final g = _geo;
    final beltH = g == null ? 100.0 : (g.h - g.beltTop) * scale;
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
            animation: Listenable.merge([_lit, _harm]),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.stage * 100 + _run.judged}-${_phase.name}-${_lifted?.name}',
            hintController: _hints,
            hintAutoMiss: true,
            layers: (context, m) => _scene(m),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (sheetUp && _phase == _Phase.lens)
                _sheetAt('lens', pad, _LensSheet(title: M6GateLines.dev(_dev ?? M6GDev.cb), text: _lens, closeKey: _lensCloseKey, onClose: _cancelSheet)),
              if (sheetUp && _phase == _Phase.radio)
                _sheetAt(
                  'radio',
                  pad,
                  _MenuSheet(
                    title: M6GateLines.dev(_dev ?? M6GDev.cb),
                    icon: Icons.settings_input_antenna_rounded,
                    items: [for (final q in _deal.reqOrder[_dev] ?? const <M6GReq>[]) _Item('m6g-req-${q.name}', M6GateLines.req(q), () => _pickReq(q))],
                    keyOf: _k,
                    onClose: _cancelSheet,
                  ),
                ),
              if (sheetUp && _phase == _Phase.send && _req != null)
                _sheetAt(
                  'send',
                  pad,
                  _SendBar(sendKey: _sendKey, title: M6GateLines.radioTitle, what: M6GateLines.req(_req!), label: M6GateLines.send, quiet: quiet, onSend: _sendRadio, onClose: _cancelSheet),
                ),
              if (sheetUp && _phase == _Phase.lt)
                _sheetAt(
                  'lt',
                  pad,
                  _MenuSheet(
                    title: M6GateLines.ltTitle,
                    icon: Icons.power_settings_new_rounded,
                    items: [for (final c in M6GLt.values) _Item('m6g-lt-${c.name}', M6GateLines.lt(c), () => _pickLt(c))],
                    keyOf: _k,
                    onClose: _cancelSheet,
                  ),
                ),
              if (sheetUp && _phase == _Phase.ltSend && _ltPick != null)
                _sheetAt(
                  'lt-send',
                  pad,
                  _SendBar(sendKey: _sendKey, title: M6GateLines.ltTitle, what: M6GateLines.lt(_ltPick!), label: M6GateLines.act, quiet: quiet, onSend: _doLt, onClose: _cancelSheet),
                ),
              if (sheetUp && _phase == _Phase.stroke && _dev != null)
                _sheetAt('stroke-${_dev!.name}', pad, _StrokeSheet(title: _strokeTitle, leverKey: _leverKey, onDone: _stroked, onClose: _cancelSheet)),
              if (sheetUp && _phase == _Phase.rod)
                _sheetAt('rod', pad, _RodSheet(clamp: _run.clamp, rodded: _run.rodded, keyOf: _k, onClamp: _rodClamp, onHook: _rodHook, onClose: _cancelSheet)),
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
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('crew-deck-${_deck?.name}-${_run.judged}'),
                                options: _deckOpts,
                                quiet: quiet,
                                muted: _muted,
                                picked: _deckPicked,
                                onPick: (o, _) => unawaited(_pickDeck(o)),
                              ),
                  ),
                ),
              if (live && _card == null)
                cornerGuide(
                  onTap: _tapGuide,
                  bottom: pad.bottom + (deckUp ? 300 : (sheetUp && !scenePhase) ? 300 : beltH + 4),
                  onLeft: coworkerFromRight,
                ),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.slips}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  onRead: _card!.lessonPoint == null
                      ? null
                      : () {
                          _hush();
                          unawaited(openLessonPoint(context, ref, lessonId: _cardLesson, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: _cardLesson,
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
              if (_phase == _Phase.intro) ...[
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M6GateLines.intro,
                  alarm: 'sounds/learn/card_deal_a.ogg',
                  muted: _muted,
                  onDone: _start,
                ),
                Positioned(
                  key: const ValueKey('intro-docket'),
                  left: 24,
                  right: 24,
                  top: pad.top + 66,
                  child: IgnorePointer(child: _DocketCard(line: M6GateLines.call(_deal.feederNo), quiet: quiet)),
                ),
              ],
              if (_mark != null)
                Positioned.fill(
                  key: const ValueKey('result'),
                  child: ColoredBox(
                    color: const Color(0xB3050A16),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _run.passed
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _RankUp(from: _rankFrom, to: _rankTo, quiet: quiet),
                                  const SizedBox(height: 14),
                                  LevelPassPanel(
                                    mark: _mark!,
                                    levelScore: _runScore,
                                    totalDelta: _totalDelta,
                                    ms: _clock.elapsedMilliseconds,
                                    caughtBn: _run.caught,
                                    quickBonus: _quickBonus,
                                    stars: _stars,
                                    onNext: () => _popOnce(true),
                                    onRetry: () => widget.onRetry(_muted),
                                  ),
                                ],
                              )
                            : LevelFailPanel(
                                percent: _mark!,
                                muted: _muted,
                                onRetry: () => widget.onRetry(_muted),
                                onLeave: () => _popOnce(false),
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: _cardLesson, point: 0, muted: _muted)),
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

  Widget _sheetAt(String id, EdgeInsets pad, Widget child) => Positioned(
        key: ValueKey('sheet-$id'),
        left: 0,
        right: 0,
        bottom: 0,
        child: Padding(padding: EdgeInsets.only(bottom: pad.bottom), child: child),
      );
}

// ============================================================================
// Pieces
// ============================================================================

/// The docket band: the call only (no states), the sketch boxes sit on it.
class _DocketBand extends StatelessWidget {
  const _DocketBand({required this.call});
  final String call;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFBEF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB08A4A)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      alignment: Alignment.topLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 13),
          const SizedBox(width: 3),
          Text(M6GateLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F), height: 1.2)),
          const SizedBox(width: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 82),
              child: Text(call, maxLines: 2, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 9, fontWeight: FontWeight.w700, color: SlmColors.ink, height: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One section of the plain sketch (no states; the chalk mark once judged).
class _SketchBox extends StatelessWidget {
  const _SketchBox({required this.label, required this.marked, required this.live});
  final String label;
  final bool marked;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF4EEDC),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: live ? const Color(0xFF7A5C2E) : const Color(0x557A5C2E), width: live ? 1.6 : 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(label, textAlign: TextAlign.center, maxLines: 1, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF3D3022), height: 1.1)),
            if (marked)
              const Positioned(right: 2, top: 1, child: Icon(Icons.close_rounded, size: 14, color: Color(0xFFB23A2E))),
          ],
        ),
      ),
    );
  }
}

class _ChalkToken extends StatelessWidget {
  const _ChalkToken({super.key, required this.up, required this.onTap, required this.onDragStart});
  final bool up;
  final VoidCallback onTap;
  final VoidCallback onDragStart;

  Widget _face({bool lifted = false}) => Container(
        decoration: BoxDecoration(
          color: lifted ? const Color(0xFFFFFFFF) : const Color(0xFFF0EDE6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: lifted ? const Color(0xFF1E88E5) : const Color(0xFF9C8E77), width: lifted ? 2 : 1),
          boxShadow: [BoxShadow(color: const Color(0x66000000), blurRadius: lifted ? 8 : 3, offset: const Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF5A4636)),
            Text(M6GateLines.chalk, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF5A4636))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M6GateLines.chalk,
      child: Draggable<String>(
        data: 'chalk',
        onDragStarted: onDragStart,
        feedback: SizedBox(width: 46, height: 32, child: Material(type: MaterialType.transparency, child: _face(lifted: true))),
        childWhenDragging: Opacity(opacity: 0.3, child: _face()),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: _face(lifted: up)),
      ),
    );
  }
}

/// The wristwatch: game time; a tap waits one minute.
class _Watch extends StatelessWidget {
  const _Watch({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E252D),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFF9AA4AE), width: 1.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.watch_later_outlined, size: 11, color: Color(0xFFBFE3FF)),
              const SizedBox(width: 3),
              Text(text, style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFFBFE3FF), height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last raw note (a reading, a reply, what the crew did).
class _NoteStrip extends StatelessWidget {
  const _NoteStrip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xE6FFFBEF), borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xFFB08A4A))),
      child: Text(enDigits(text), maxLines: 3, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w700, color: SlmColors.ink, height: 1.25)),
    );
  }
}

/// A belt token (all seven the same size; drag it or tap it up).
class _TokenChip extends StatelessWidget {
  const _TokenChip({super.key, required this.tok, required this.up, required this.onTap, required this.onDragStart});
  final M6GTok tok;
  final bool up;
  final VoidCallback onTap;
  final VoidCallback onDragStart;

  static IconData _icon(M6GTok t) => switch (t) {
        M6GTok.eye => Icons.visibility_rounded,
        M6GTok.radio => Icons.settings_input_antenna_rounded,
        M6GTok.handle => Icons.swap_vert_rounded,
        M6GTok.earth => Icons.vertical_align_bottom_rounded,
        M6GTok.rod => Icons.horizontal_rule_rounded,
        M6GTok.crew => Icons.engineering_rounded,
        M6GTok.tester => Icons.electric_bolt_rounded,
      };

  Widget _face({bool lifted = false}) => Container(
        decoration: BoxDecoration(
          color: lifted ? const Color(0xFFFFE08A) : const Color(0xFFF2B632),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: lifted ? Colors.white : const Color(0xFF7A5200), width: lifted ? 2 : 1.2),
          boxShadow: [BoxShadow(color: const Color(0x88000000), blurRadius: lifted ? 10 : 4, offset: Offset(0, lifted ? 5 : 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon(tok), size: 20, color: const Color(0xFF3A2500)),
            const SizedBox(height: 2),
            Text(
              M6GateLines.tok(tok),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF3A2500), height: 1.05),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M6GateLines.tok(tok),
      child: Draggable<M6GTok>(
        data: tok,
        onDragStarted: onDragStart,
        feedback: SizedBox(width: 46, height: 62, child: Material(type: MaterialType.transparency, child: _face(lifted: true))),
        childWhenDragging: Opacity(opacity: 0.35, child: _face()),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedSlide(offset: Offset(0, up ? -0.12 : 0), duration: const Duration(milliseconds: 160), child: _face(lifted: up)),
        ),
      ),
    );
  }
}

@immutable
class _Item {
  const _Item(this.id, this.label, this.onTap);
  final String id;
  final String label;
  final VoidCallback onTap;
}

/// A sheet of choices, all alike (2 across); the hint sweeps over all.
class _MenuSheet extends StatelessWidget {
  const _MenuSheet({required this.title, required this.icon, required this.items, required this.keyOf, this.onClose});
  final String title;
  final IconData icon;
  final List<_Item> items;
  final GlobalKey Function(String id) keyOf;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final ids = [for (final i in items) i.id].join('|');
    return IdleHint(
      waiting: items.length > 1,
      waitKey: ids,
      spec: (_) => items.length < 2 ? null : HintSpec.sweepOver([for (final i in items) keyOf(i.id)]),
      child: _SheetFrame(
        title: title,
        icon: icon,
        onClose: onClose,
        child: LayoutBuilder(
          builder: (context, box) {
            final cols = items.length == 1 ? 1 : 2;
            final w = (box.maxWidth - 8 * (cols - 1)) / cols;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final it in items)
                  SizedBox(
                    key: keyOf(it.id),
                    width: w,
                    child: Material(
                      color: const Color(0xFF1B2A44),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: ValueKey(it.id),
                        borderRadius: BorderRadius.circular(12),
                        onTap: it.onTap,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.4))),
                          child: Text(enDigits(it.label), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.25)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.icon, required this.child, this.onClose});
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SlmColors.navy900.withValues(alpha: 0.96), SlmColors.navy950.withValues(alpha: 0.99)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.45), width: 1.4)),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: SlmColors.gold300),
              const SizedBox(width: 8),
              Expanded(child: Text(enDigits(title), maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: SlmColors.gold200, height: 1.2))),
              if (onClose != null)
                Semantics(
                  button: true,
                  label: M6GateLines.close,
                  child: InkWell(
                    key: const ValueKey('m6g-sheet-close'),
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(width: 48, height: 40, child: Icon(Icons.close_rounded, color: SlmColors.ivory, size: 22)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// The lens: what the device shows, line by line (raw), then বন্ধ.
class _LensSheet extends StatelessWidget {
  const _LensSheet({required this.title, required this.text, required this.closeKey, required this.onClose});
  final String title;
  final String text;
  final GlobalKey closeKey;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final lines = text.split(' · ');
    return IdleHint(
      waiting: true,
      waitKey: text,
      // The one way forward: close the lens.
      spec: (_) => HintSpec.tapOn(closeKey),
      child: _SheetFrame(
        title: title,
        icon: Icons.visibility_rounded,
        onClose: onClose,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 6, right: 8), child: Icon(Icons.circle, size: 6, color: SlmColors.gold300)),
                    Expanded(child: Text(enDigits(l), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.3))),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: M6GateLines.close,
              child: Material(
                key: closeKey,
                color: const Color(0xFF1B2A44),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const ValueKey('m6g-lens-close'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: onClose,
                  child: SizedBox(
                    height: 48,
                    child: Center(child: Text(M6GateLines.close, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Press and hold to send (the radio's PTT, or the LT switch's lever).
class _SendBar extends StatefulWidget {
  const _SendBar({required this.sendKey, required this.title, required this.what, required this.label, required this.quiet, required this.onSend, required this.onClose});
  final GlobalKey sendKey;
  final String title;
  final String what;
  final String label;
  final bool quiet;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  State<_SendBar> createState() => _SendBarState();
}

class _SendBarState extends State<_SendBar> with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(vsync: this, duration: kLongPressTimeout);

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IdleHint(
      waiting: true,
      waitKey: widget.what,
      // The one way forward: press and hold.
      spec: (_) => HintSpec.holdOn(widget.sendKey),
      child: _SheetFrame(
        title: widget.title,
        icon: Icons.settings_input_antenna_rounded,
        onClose: widget.onClose,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(enDigits(widget.what), style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.3)),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: widget.label,
              child: GestureDetector(
                key: widget.sendKey,
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {
                  if (!widget.quiet) unawaited(_fill.forward(from: 0));
                },
                onTapUp: (_) => _fill.reverse(),
                onTapCancel: () => _fill.reverse(),
                onLongPress: () {
                  _fill.value = 1;
                  widget.onSend();
                },
                child: Container(
                  key: const ValueKey('m6g-send'),
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _fill,
                          builder: (_, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _fill.value,
                            child: DecoratedBox(decoration: BoxDecoration(color: const Color(0x55FFFFFF), borderRadius: BorderRadius.circular(14))),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(widget.label, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The AB's ground handle: pull it all the way in one firm stroke. Let go
/// midway and it stalls (M6-3: only a stall is scored).
class _StrokeSheet extends StatefulWidget {
  const _StrokeSheet({required this.title, required this.leverKey, required this.onDone, required this.onClose});
  final String title;
  final GlobalKey leverKey;
  final ValueChanged<bool> onDone;
  final VoidCallback onClose;

  @override
  State<_StrokeSheet> createState() => _StrokeSheetState();
}

class _StrokeSheetState extends State<_StrokeSheet> {
  static const _track = 170.0;
  double _t = 0;
  var _done = false;

  void _end() {
    if (_done) return;
    if (_t >= 0.9) {
      _done = true;
      widget.onDone(false);
    } else if (_t > 0.08) {
      _done = true;
      widget.onDone(true);
    } else {
      setState(() => _t = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IdleHint(
      waiting: _t == 0,
      waitKey: widget.title,
      // The one way forward: a drag down the lever's track.
      spec: (_) => HintSpec.dragFrom(widget.leverKey, toward: const Offset(0, 1), travel: 64),
      child: _SheetFrame(
        title: widget.title,
        icon: Icons.swap_vert_rounded,
        onClose: widget.onClose,
        child: SizedBox(
          height: _track + 56,
          child: Center(
            child: SizedBox(
              width: 120,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 20,
                    child: Container(width: 14, height: _track + 10, decoration: BoxDecoration(color: const Color(0xFF39424C), borderRadius: BorderRadius.circular(7))),
                  ),
                  Positioned(
                    top: _t * _track,
                    child: GestureDetector(
                      key: widget.leverKey,
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (d) => setState(() => _t = (_t + d.delta.dy / _track).clamp(0.0, 1.0)),
                      onVerticalDragEnd: (_) => _end(),
                      onVerticalDragCancel: _end,
                      child: Semantics(
                        button: true,
                        label: M6GateLines.taskStroke,
                        child: Container(
                          key: const ValueKey('m6g-lever'),
                          width: 110,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB23A2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCDD2), width: 2),
                            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 3))],
                          ),
                          child: const Icon(Icons.drag_handle_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The discharge rod: its earth clamp and the bank's three terminals, all
/// alike (the order is the player's).
class _RodSheet extends StatelessWidget {
  const _RodSheet({required this.clamp, required this.rodded, required this.keyOf, required this.onClamp, required this.onHook, required this.onClose});
  final bool clamp;
  final Set<int> rodded;
  final GlobalKey Function(String id) keyOf;
  final VoidCallback onClamp;
  final ValueChanged<int> onHook;
  final VoidCallback onClose;

  Widget _spot(String id, String label, bool done, VoidCallback onTap) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            key: keyOf(id),
            color: done ? const Color(0xFF1F3B2C) : const Color(0xFF1B2A44),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: ValueKey(id),
              borderRadius: BorderRadius.circular(12),
              onTap: done ? null : onTap,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (done) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check_rounded, size: 16, color: SlmColors.emerald300)),
                    Flexible(child: Text(label, textAlign: TextAlign.center, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.2))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final open = ['m6g-rod-clamp', for (var i = 0; i < 3; i++) if (!rodded.contains(i)) 'm6g-rod-$i'];
    return IdleHint(
      waiting: open.length > 1,
      waitKey: 'rod-$clamp-${rodded.length}',
      spec: (_) => HintSpec.sweepOver([for (final id in open) keyOf(id)]),
      child: _SheetFrame(
        title: M6GateLines.rodTitle,
        icon: Icons.horizontal_rule_rounded,
        onClose: onClose,
        child: Column(
          children: [
            Row(children: [for (var i = 0; i < 3; i++) _spot('m6g-rod-$i', M6GateLines.rodTerm(i), rodded.contains(i), () => onHook(i))]),
            Row(children: [_spot('m6g-rod-clamp', M6GateLines.rodClamp, clamp, onClamp)]),
          ],
        ),
      ),
    );
  }
}

/// The docket on the intro (the call).
class _DocketCard extends StatelessWidget {
  const _DocketCard({required this.line, required this.quiet});
  final String line;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.rotate(
        angle: -0.03 * t,
        child: Transform.translate(offset: Offset(0, -40 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB08A4A), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_rounded, color: Color(0xFF7A1F1F), size: 22),
            const SizedBox(width: 8),
            Text(M6GateLines.docket, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF7A1F1F))),
            const SizedBox(width: 12),
            Expanded(child: Text(line, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.3))),
          ],
        ),
      ),
    );
  }
}

/// The rank-up: অ্যাডভান্সড → সিনিয়র, with the module's badge (hidden while
/// the badge constant is empty, ruling M6-10).
class _RankUp extends StatelessWidget {
  const _RankUp({required this.from, required this.to, required this.quiet});
  final String from;
  final String to;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: 0.7 + 0.3 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2B1D05), Color(0xFF4A3208)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SlmColors.gold300, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x88F2B632), blurRadius: 18)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(M6GateLines.rankUp, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    from,
                    style: bangla(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xAAFFFFFF)).copyWith(decoration: TextDecoration.lineThrough),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward_rounded, color: SlmColors.gold300, size: 24)),
                const Icon(Icons.military_tech_rounded, color: SlmColors.gold300, size: 30),
                const SizedBox(width: 4),
                Flexible(child: Text(to, style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
              ],
            ),
            if (M6GateLines.badge.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(M6GateLines.badge, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
            ],
          ],
        ),
      ),
    );
  }
}
