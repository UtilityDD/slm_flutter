import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
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
import 'm6_dtr_photo_report_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_dtr_photo_report_world.dart' show M6Cam, M6Part, M6PhotoGeo, m6Coverage;

// Lesson 6.1 "ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড", কাজ 1
// "দু'মিনিটের ছবি-রিপোর্ট" (pack do_6_1_a, engineType m6_dtr_photo_report).
// After a trip, a customer complaint or on patrol (dealt) the trainee stands
// on the ground under a roadside pole-mounted DTR with his phone. The JE's
// chat names five things one at a time — four photos (the nameplate always,
// three dealt from the oil stain, the MIN/MAX gauge glass, the breather gel,
// the HT or the LT bushings, the fins, the conservator drum) and the sound
// (its place in the list dealt) — each by its job or its voltage, never by
// pointing (lesson 6.1 point 5, the six-point check made standing on the
// ground, and point 2, the parts' jobs).
//
// Photos: drag the viewfinder over the scene (one finger), zoom with the rail
// or a pinch, shutter. The shutter judges: the part asked for at least 70 %
// in the frame at a readable zoom (the gauge and the nameplate whole: MIN,
// MAX and the oil line; the kVA, serial and Dyn11 rows at 2.5x or more),
// alone. Too far = the JE "পড়া যাচ্ছে না" (time only); too close to hold it
// whole, or another part in the frame with it, = a JE reply (time only); a
// close-up of another part = a slip and its card; the HT and the LT bushings
// in one frame = a slip (no hedging the size check, lesson pro tip 1). An accepted shot flies to its slot → ◆ on the table →
// "কেন …?" about what the shot shows (healthy or faulty). The sound: hold the
// ear button, then write one of three readings (lesson 6.1 point 3); a wrong
// reading is a slip. Five slots → 'রিপোর্ট পাঠান' → the JE "পেয়েছি".
//
// Deadly / slip (module 6 table and rulings, 2026-11-15): the careless
// coworker comes once a play, after the player has already framed (moved or
// zoomed to it this slot) or heard what he talks about, with one of three dealt pushes: (a) myth 1 at the
// stain shot (a wet stain dealt) — listening = slip; (b) myth 2 after a
// normal hum, before the readings — listening = slip; (c) "climb up and wipe
// the nameplate" at the nameplate shot — listening = DEADLY (ruling M6-4:
// climbing a live DTR's platform on his word, R22; X2/B1). The shutter or
// the readings wait for him (holdForCoworker). Slips: a photo of the wrong
// part, a wrong sound reading, listening to (a) or (b). Three slips strike
// out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first with
// the dealt trigger (no start, no skip), the full scene
// (m6_dtr_photo_report_world.dart), the corner guide (tap: the request again,
// a different way), the reason table after every slot, the two-beat
// coworker, gesture hands (how, never what): a fixed drag nudge from the
// frame's centre up-left, a drag nudge up the zoom thumb, a tap on the
// shutter once the frame has moved and zoomed, the ear's hold ring, a tap on
// 'রিপোর্ট পাঠান' (none while the guide reads the JE out). The guide's bubble
// clears once a JE line is read (the words stay on the phone's chat), so it
// never stands over the DTR while the player aims. Idle = zero frames.

// ============================================================================
// Content
// ============================================================================

enum M6Trigger { trip, complaint, patrol }

enum M6Sound { hum, rattle, crackle }

/// The coworker's push (one per play): (a) myth 1 at the stain, (b) myth 2
/// at a normal hum, (c) climb to wipe the nameplate.
enum M6Push { leak, hum, climb }

/// What a slot's reason asks about (fits what the shot shows).
enum M6WhyTopic { stainWet, stainDry, gaugeOk, gaugeLow, gelDry, gelWet, htId, ltId, bushFault, bushClean, fins, drum, plate, hum, rattle, crackle }

/// far: below the readable zoom; partial: most of the part, not all; close:
/// the frame too small to hold the part whole; crowded: another part whole in
/// the frame with it; both: the HT and the LT bushings together (a slip);
/// wrong: a close-up of another part (a slip); empty: nothing.
enum M6ShotResult { accepted, far, partial, close, crowded, both, empty, wrong }

/// One request of the JE: a photo of [part], or the sound ([part] null);
/// [phrasing] picks one of its wordings.
@immutable
class M6Request {
  const M6Request(this.part, this.phrasing);
  const M6Request.sound(this.phrasing) : part = null;
  final M6Part? part;
  final int phrasing;
  bool get isSound => part == null;
}

abstract final class M6PhotoLines {
  static const title = "দু'মিনিটের ছবি-রিপোর্ট";

  // The guide's opening, by the dealt trigger (spec wording; DRAFT — owner).
  static const introTrip = 'লাইন ট্রিপ করেছে! DTR দেখে JE সাহেবকে 2 মিনিটে ছবি-রিপোর্ট পাঠান।';
  static const introComplaint = 'গ্রাহকের অভিযোগ এসেছে — DTR-টা দেখে ছবি-রিপোর্ট পাঠান।';
  static const introPatrol = 'টহলে DTR-টা দেখে JE সাহেবকে রিপোর্ট পাঠান।';
  static String intro(M6Trigger t) => switch (t) {
        M6Trigger.trip => introTrip,
        M6Trigger.complaint => introComplaint,
        M6Trigger.patrol => introPatrol,
      };
  static const start = 'JE সাহেব কী চাইছেন, দেখুন।';

  // The JE's requests (read out by the guide): by job or voltage, never by
  // pointing. DRAFT wording — owner.
  static const requests = <M6Part, List<String>>{
    M6Part.stain: ['ট্যাঙ্কের ঠিক নিচের মাটির ছবি দিন — তেলের দাগ আছে কি না।', 'ট্রান্সফরমারের নিচে মাটিটা কেমন, তার ছবি দিন।'],
    M6Part.gauge: ['বাড়তি তেল যেখানে জায়গা পায়, তার পাশের কাঁচে তেল কোথায় — ছবি দিন।', 'তেলের লেভেল দেখার কাঁচটার ছবি দিন — MIN আর MAX সমেত।'],
    M6Part.gel: ['ট্রান্সফরমার যেখান দিয়ে শ্বাস নেয়, তার জেলের রঙের ছবি দিন।', 'ভেতরে ঢোকা বাতাসের আর্দ্রতা যে জেল শুষে নেয়, তার ছবি দিন।'],
    M6Part.ht: ['11 kV যে বুশিং দিয়ে ঢোকে, সেগুলোর ছবি দিন।', 'হাই ভোল্টেজ দিকের বুশিংগুলোর ছবি দিন।'],
    M6Part.lt: ['415 V যে বুশিং দিয়ে বেরোয়, সেগুলোর ছবি দিন।', 'লো ভোল্টেজ দিকের বুশিংগুলোর ছবি দিন।'],
    M6Part.fins: ['তেল ঠান্ডা করার খাঁজকাটা পাতগুলোর ছবি দিন।', 'যে পাতগুলো বাতাসে তেলের তাপ ছাড়ে, তাদের ছবি দিন।'],
    M6Part.drum: ['গরমে বাড়া তেল যেখানে জায়গা পায়, সেই ড্রামের ছবি দিন।', 'তেল বাড়লে-কমলে যে পাত্র জায়গা দেয়, তার ছবি দিন।'],
    M6Part.plate: ['নেমপ্লেটের একটা স্পষ্ট ছবি দিন — kVA, সিরিয়াল, Dyn11 যেন পড়া যায়।', 'রেটিং আর সিরিয়াল নম্বর লেখা প্লেটটার পরিষ্কার ছবি দিন।'],
  };
  static const soundAsks = ['আওয়াজটা কেমন? শুনে লিখুন।', 'ট্রান্সফরমারটা কেমন আওয়াজ করছে? শুনে জানান।'];
  static String request(M6Request r) => r.isSound ? soundAsks[r.phrasing % 2] : requests[r.part]![r.phrasing % 2];

  // The JE's replies in the chat (read out by the guide). DRAFT — owner.
  static const jeFar = 'পড়া যাচ্ছে না — আরও কাছে জুম করে আবার তুলুন।';
  static const jePartial = 'পুরোটা ছবিতে আসেনি — আবার তুলুন।';
  static const jeEmpty = 'ছবিতে কিছুই বোঝা যাচ্ছে না — আবার তুলুন।';
  static const jeClose = 'খুব কাছে — জুম একটু কমিয়ে আবার তুলুন।';
  static const jeOnly = 'শুধু যেটা চেয়েছি, সেটারই ছবি দিন।';
  static const jeGot = 'পেয়েছি, ধন্যবাদ।';

  // The guide (DRAFT — owner).
  static const soundAsk = 'কী শুনলেন? লিখুন।';
  static const sendNow = 'সব তোলা হয়েছে — রিপোর্ট পাঠান।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The phone (words on the controls).
  static const jeName = 'JE সাহেব';
  static const send = 'রিপোর্ট পাঠান';
  static const shutter = 'ছবি তুলুন';
  static const listen = 'শুনুন';
  static const zoom = 'জুম';
  static const sceneLabel = 'ট্রান্সফরমার';

  // The three readings (equal length, shuffled; lesson 6.1 point 3).
  static const readings = <M6Sound, String>{
    M6Sound.hum: 'হালকা একটানা গুনগুন — স্বাভাবিক',
    M6Sound.rattle: 'খটখট-গরগর — সতর্ক হওয়ার শব্দ',
    M6Sound.crackle: 'ছড়ছড় স্পার্কিংয়ের শব্দ — সতর্ক',
  };
  static M6Sound soundOf(String reading) => readings.entries.firstWhere((e) => e.value == reading).key;
  static String soundShort(M6Sound s) => switch (s) {
        M6Sound.hum => 'গুনগুন',
        M6Sound.rattle => 'খটখট',
        M6Sound.crackle => 'ছড়ছড়',
      };

  // The reasons (spoken questions from the spec; cards DRAFT — owner).
  static const qShot = 'এই ছবিটা রিপোর্টে কেন জরুরি?';
  static const qHt = 'কেন এগুলোকেই HT (11 kV) বুশিং ধরলেন?';
  static const qLt = 'কেন এগুলোকেই LT (415 V) বুশিং ধরলেন?';
  static const qPlate = 'নেমপ্লেটের ছবি রিপোর্টে কেন লাগে?';
  static const qSound = 'আওয়াজটা নিয়ে এমন লিখলেন কেন?';
  static String whyQ(M6WhyTopic t) => switch (t) {
        M6WhyTopic.htId => qHt,
        M6WhyTopic.ltId => qLt,
        M6WhyTopic.plate => qPlate,
        M6WhyTopic.hum || M6WhyTopic.rattle || M6WhyTopic.crackle => qSound,
        _ => qShot,
      };
  static const whyRight = <M6WhyTopic, List<String>>{
    M6WhyTopic.stainWet: ['মাটিতে তেলের দাগ — লিক হচ্ছে, তেল কমছে', 'নিচে তেলের ছোপ — লিক হচ্ছে, জানাতে হবে'],
    M6WhyTopic.stainDry: ['ট্যাঙ্কের নিচে মাটি শুকনো — লিকের দাগ নেই', 'নিচে তেলের ভেজা দাগ নেই, তাই লিক নেই'],
    M6WhyTopic.gaugeOk: ['তেল MIN আর MAX-এর মাঝামাঝি — লেভেল ঠিক', 'কাঁচে তেল দুই দাগের মাঝে, তাই লেভেল ঠিক'],
    M6WhyTopic.gaugeLow: ['তেল MIN-এর নিচে — কয়েল গরম হয়ে উঠবে', 'লেভেল MIN-এর নিচে — তেল কমে গেছে'],
    M6WhyTopic.gelDry: ['জেল নীল বা কমলা — এখনও শুকনো, ঠিক আছে', 'জেলের রং ঠিক আছে, আর্দ্রতা শুষতে পারছে'],
    M6WhyTopic.gelWet: ['জেল গোলাপি বা সাদাটে — আর্দ্রতা ভরে গেছে', 'জেল রং বদলেছে — এখনই বদলানো দরকার'],
    M6WhyTopic.htId: ['HT বুশিং LT-র চেয়ে বড়, খাঁজও চওড়া', 'লম্বা বুশিং, চওড়া খাঁজ — এগুলোই 11 kV-র'],
    M6WhyTopic.ltId: ['LT বুশিং HT-র চেয়ে আকারে ছোট হয়', 'বেঁটে বুশিং, সরু খাঁজ — এগুলোই 415 V-র'],
    M6WhyTopic.bushFault: ['বুশিংয়ে ফাটল বা পোড়া কালো ছোপ আছে', 'ফ্ল্যাশ মার্ক দেখা যাচ্ছে — জানাতে হবে'],
    M6WhyTopic.bushClean: ['বুশিং পরিষ্কার — ফাটল বা পোড়া দাগ নেই', 'চিনেমাটিতে কোনো ফাটল বা কালো ছোপ নেই'],
    M6WhyTopic.fins: ['ফিন বাতাসে তেলকে তাড়াতাড়ি ঠান্ডা করে', 'খাঁজকাটা পাত তেলের তাপ বাতাসে ছাড়ে'],
    M6WhyTopic.drum: ['গরমে তেল বাড়লে এই ড্রামে জায়গা পায়', 'তেল বাড়লে-কমলে ড্রামটাই জায়গা দেয়'],
    M6WhyTopic.plate: ['kVA, সিরিয়াল, Dyn11 — ফল্ট রিপোর্টে লাগে', 'প্লেটের তথ্যেই JE ট্রান্সফরমারটা চেনেন'],
    M6WhyTopic.hum: ['হালকা একটানা গুনগুন — এটাই স্বাভাবিক', 'কোরের চুম্বকত্বে মৃদু গুনগুন হয়ই'],
    M6WhyTopic.rattle: ['খটখট-গরগর আওয়াজ — এটা চিন্তার কারণ', 'একটানা গুনগুন নয়, খটখট — সতর্ক হতে হবে'],
    M6WhyTopic.crackle: ['ছড়ছড় শব্দ — আলগা কানেকশনের লক্ষণ', 'স্পার্কিংয়ের মতো ছড়ছড় — ফল্টের লক্ষণ'],
  };

  /// The wrong reasons: a myth or excuse about the same part (the lesson's
  /// myths among them), dealt with the field excuses that fit any shot.
  static const _excuses = [
    'ছবিটা দেখতে ভালো লাগছিল, তাই তুললাম',
    'রিপোর্টে এসব খুঁটিনাটি কেউ দেখে না',
    'পোলে উঠে ট্যাঙ্ক খুলে দেখলেই সব বোঝা যায়',
  ];
  static const _wrongStain = ['সামান্য তেল পড়লে কিছু যায় আসে না', 'নিচের মাটি দেখে লিক বোঝা যায় না'];
  static const _wrongGauge = ['তেল যত বেশি, তত ভালো — MAX ছাড়ালেও ঠিক', 'লেভেলের কাঁচ দেখে কিছু বোঝা যায় না'];
  static const _wrongGel = ['জেলের রং দেখে কিছুই বোঝা যায় না', 'গোলাপি জেলই সবচেয়ে শুকনো আর ভালো'];
  static const _wrongBush = ['বড়-ছোট সব বুশিং একই, কোনো তফাত নেই', 'LT বুশিং সবসময় HT-র চেয়ে বড় হয়', 'বুশিংয়ের কালো ছোপ শুধু ধুলো, কিছু না'];
  static const _wrongJob = ['ফিন আর ড্রাম শুধু সাজ, কোনো কাজ নেই', 'ড্রামটা শুধু ওপরের একটা ঢাকনা মাত্র'];
  static const _wrongPlate = ['সব ট্রান্সফরমারের প্লেটে একই লেখা থাকে', 'নেমপ্লেটের ছবি শুধু খাতা ভরানোর জন্য'];
  static const _wrongSound = ['গুনগুন শব্দ হলেই ভেতরে বড় গোলমাল', 'খটখট আওয়াজ চালু অবস্থায় স্বাভাবিক', 'আওয়াজ শুনে আসলে কিছুই বোঝা যায় না'];

  /// The wrong reasons dealt on a [t] question (at least five).
  static List<String> wrongFor(M6WhyTopic t) => [
        ...switch (t) {
          M6WhyTopic.stainWet || M6WhyTopic.stainDry => _wrongStain,
          M6WhyTopic.gaugeOk || M6WhyTopic.gaugeLow => _wrongGauge,
          M6WhyTopic.gelDry || M6WhyTopic.gelWet => _wrongGel,
          M6WhyTopic.htId || M6WhyTopic.ltId || M6WhyTopic.bushFault || M6WhyTopic.bushClean => _wrongBush,
          M6WhyTopic.fins || M6WhyTopic.drum => _wrongJob,
          M6WhyTopic.plate => _wrongPlate,
          M6WhyTopic.hum || M6WhyTopic.rattle || M6WhyTopic.crackle => _wrongSound,
        },
        ..._excuses,
      ];

  /// Every wrong reason (the library the lengths are kept within).
  static List<String> get myths => [..._excuses, ..._wrongStain, ..._wrongGauge, ..._wrongGel, ..._wrongBush, ..._wrongJob, ..._wrongPlate, ..._wrongSound];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker. (a) and (b) push the lesson's myths 1 and 2 word
  // for word plus his ask; (c) the climb push (ruling M6-4). DRAFT — owner.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';

  // The guide's new questions while he is on (the other asks are recorded).
  static const askLeak = 'ও বলছে দাগের ছবি বাদ দিতে। কী করবেন?';
  static const askHum = 'ও বলছে বড় গোলমাল লিখতে। কী করবেন?';
  static const askClimb = 'ও বলছে মাচায় উঠতে। কী করবেন?';
  static const coworkerLeak = CoworkerScript(
    line: 'ট্রান্সফরমার থেকে সামান্য তেল চুঁইয়ে পড়লে কিছু যায় আসে না, যতক্ষণ না পুরো তেল ফুরিয়ে যাচ্ছে। ও ছবি বাদ দাও!',
    exitLine: coworkerExit,
    right: ['না, সামান্য লিকেও তেল কমে — ছবি যাবে', 'না, লিকের দাগের ছবি রিপোর্টে যাবেই', 'না, ওই ফাঁক দিয়ে আর্দ্রতাও ঢোকে'],
    wrong: [
      'ঠিক, সামান্য তেল পড়লে কী আর হয়',
      'আচ্ছা, দাগের ছবিটা তাহলে বাদই দিই',
      'হ্যাঁ, পুরো তেল তো এখনও ফুরোয়নি',
      'ঠিক আছে, ও ছবি JE-র লাগবেই না',
      'হ্যাঁ, এটুকু লিক তো সবারই হয়ে থাকে',
    ],
    asks: ['কী করবেন?', askLeak, 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerHum = CoworkerScript(
    line: 'ট্রান্সফরমার থেকে গুনগুন (হামিং) শব্দ হলেই বুঝতে হবে ভেতরে বড় কোনো গোলমাল হয়েছে। লিখে দাও — বড় গোলমাল!',
    exitLine: coworkerExit,
    right: ['না, হালকা একটানা গুনগুন স্বাভাবিক', 'না, মিথ্যে রিপোর্ট লিখব না', 'না, এ গুনগুন কোরের স্বাভাবিক শব্দ'],
    wrong: [
      'ঠিক, গুনগুন মানেই বড় গোলমাল',
      'আচ্ছা, বড় গোলমালই লিখে দিই',
      'হ্যাঁ, শব্দ হচ্ছে মানেই বিপদ',
      'ঠিক আছে, বাড়িয়ে লিখলে ক্ষতি নেই',
      'হ্যাঁ, লিখে দিই — ভেতরে গোলমাল',
    ],
    asks: ['কী করবেন?', askHum, 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerClimb = CoworkerScript(
    line: 'মাচায় উঠে নেমপ্লেটটা মুছে ছবি তোলো!',
    exitLine: coworkerExit,
    right: ['না, মাটিতে দাঁড়িয়েই জুম করে তুলব', 'না, চালু ট্রান্সফরমারে উঠব না', 'না, এই চেক মাটি থেকেই করতে হয়'],
    wrong: [
      'ঠিক, উঠে মুছে ঝকঝকে ছবি তুলি',
      'আচ্ছা, এক মিনিটে উঠে নেমে আসি',
      'হ্যাঁ, কাছ থেকে ছবিই ভালো হয়',
      'ঠিক আছে, মাচায় উঠে মুছে দিই',
      'হ্যাঁ, একটু উঠলে কিছু হবে না',
    ],
    asks: ['কী করবেন?', askClimb, 'চালু ট্রান্সফরমারে উঠবেন?'],
  );
  static CoworkerScript coworker(M6Push p) => switch (p) {
        M6Push.leak => coworkerLeak,
        M6Push.hum => coworkerHum,
        M6Push.climb => coworkerClimb,
      };
  static const allCoworkers = [coworkerLeak, coworkerHum, coworkerClimb];
  static String callHeld(M6Push p) => switch (p) {
        M6Push.leak => 'ঠিক! সামান্য লিকও রিপোর্টে যাবে।',
        M6Push.hum => 'ঠিক! একটানা গুনগুন স্বাভাবিক।',
        M6Push.climb => 'ঠিক! চালু ট্রান্সফরমারে ওঠা নয় — জুমই যথেষ্ট।',
      };

  static const allSet = "দু'মিনিটে খাঁটি রিপোর্ট — মাটিতে দাঁড়িয়েই!";
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — যা চাওয়া হয়েছে, ঠিক সেটারই ছবি।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtPlate = 'নেমপ্লেটের স্পষ্ট ছবি পাঠিয়েছেন';
  static const caughtHtLt = 'HT আর LT বুশিং আকারে চিনেছেন';
  static const caughtFault = 'খারাপ লক্ষণ ধরে রিপোর্টে দিয়েছেন';
  static const caughtSound = 'আওয়াজ শুনে ঠিক লিখেছেন';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// New coworker lines for recording (his exit is recorded already).
  static List<String> get newRivalLines => [coworkerLeak.line, coworkerHum.line, coworkerClimb.line];

  /// New guide lines for recording (spoken: intro, requests, the JE's
  /// replies read out, the reason questions, the praise lines, his three new
  /// asks while the coworker is on, and every mistake text — the guide reads
  /// a mistake out the first time it comes).
  static List<String> get newGuideLines => [
        introTrip,
        introComplaint,
        introPatrol,
        start,
        for (final l in requests.values) ...l,
        ...soundAsks,
        jeFar,
        jePartial,
        jeEmpty,
        jeClose,
        jeOnly,
        jeGot,
        soundAsk,
        sendNow,
        qShot,
        qHt,
        qLt,
        qPlate,
        qSound,
        for (final p in M6Push.values) callHeld(p),
        allSet,
        fail,
        askLeak,
        askHum,
        askClimb,
        for (final m in M6PhotoMistakes.all) m.textBn,
      ];
}

abstract final class M6PhotoMistakes {
  static const _dir = 'assets/game/art/m6_dtr_photo_report';
  static const _k = '6.1/m6_dtr_photo_report';

  // Lesson points (0-based): 1 the parts, 2 the outside health signs, 4 the
  // six-point check, 5 outside sign → inside cause.
  static const wrongStain = DoMistake(
    key: '$_k/wrong-stain',
    textBn: 'এটা ট্যাঙ্কের নিচের মাটি নয়। লিক ধরতে ট্যাঙ্কের ঠিক নিচের মাটির ছবি চাই — ভেজা দাগ আছে কি না।',
    art: '$_dir/stain.svg',
    lessonPoint: 4,
  );
  static const wrongGauge = DoMistake(
    key: '$_k/wrong-gauge',
    textBn: 'এটা লেভেলের কাঁচ নয়। কনজারভেটর ড্রামের পাশের কাঁচে MIN, MAX আর তেলের দাগ — তিনটেই ছবিতে চাই।',
    art: '$_dir/gauge.svg',
    lessonPoint: 2,
  );
  static const wrongGel = DoMistake(
    key: '$_k/wrong-gel',
    textBn: 'এটা ব্রিদার নয়। ব্রিদারের কাঁচে সিলিকা জেলের রং দেখা যায় — নীল বা কমলা আছে, নাকি গোলাপি হয়েছে।',
    art: '$_dir/gel.svg',
    lessonPoint: 1,
  );
  static const wrongHt = DoMistake(
    key: '$_k/wrong-ht',
    textBn: 'এগুলো HT বুশিং নয়। 11 kV-র HT বুশিং আকারে বড়, খাঁজও বেশি চওড়া।',
    art: '$_dir/bushings.svg',
    lessonPoint: 1,
  );
  static const wrongLt = DoMistake(
    key: '$_k/wrong-lt',
    textBn: 'এগুলো LT বুশিং নয়। 415 V-র LT বুশিং HT-র চেয়ে আকারে ছোট।',
    art: '$_dir/bushings.svg',
    lessonPoint: 1,
  );
  static const wrongFins = DoMistake(
    key: '$_k/wrong-fins',
    textBn: 'এটা ফিন নয়। ট্যাঙ্কের গায়ে খাঁজকাটা পাতগুলোই ফিন — বাতাসে তেল ঠান্ডা করে।',
    art: '$_dir/fins_drum.svg',
    lessonPoint: 1,
  );
  static const wrongDrum = DoMistake(
    key: '$_k/wrong-drum',
    textBn: 'এটা কনজারভেটর ড্রাম নয়। ট্যাঙ্কের ওপরে আড়াআড়ি ড্রামেই গরমে বাড়া তেল জায়গা পায়।',
    art: '$_dir/fins_drum.svg',
    lessonPoint: 1,
  );
  static const wrongPlate = DoMistake(
    key: '$_k/wrong-plate',
    textBn: 'এটা নেমপ্লেট নয়। ট্যাঙ্কের গায়ের মেটাল প্লেটে kVA, সিরিয়াল নম্বর আর Dyn11 লেখা থাকে।',
    art: '$_dir/plate.svg',
    lessonPoint: 4,
  );
  // HT and LT in one frame: the size check hedged (lesson pro tip 1).
  static const bushBoth = DoMistake(
    key: '$_k/bush-both',
    textBn: 'দুই সারি বুশিংই ছবিতে। 11 kV-র HT বড়, 415 V-র LT ছোট — আকার দেখে শুধু চাওয়া সারিটার ছবি দিন।',
    art: '$_dir/bushings.svg',
    lessonPoint: 1,
  );
  static const soundHum = DoMistake(
    key: '$_k/sound-hum',
    textBn: 'হালকা একটানা গুনগুন স্বাভাবিক — একে গোলমাল লিখলে রিপোর্ট ভুল যায়।',
    art: '$_dir/sound.svg',
    lessonPoint: 2,
  );
  static const soundMissed = DoMistake(
    key: '$_k/sound-missed',
    textBn: 'খটখট, গরগর বা ছড়ছড় আওয়াজ স্বাভাবিক নয় — সতর্ক হয়ে রিপোর্টে লিখুন।',
    art: '$_dir/sound.svg',
    lessonPoint: 2,
  );
  static const soundMixed = DoMistake(
    key: '$_k/sound-mixed',
    textBn: 'খটখট-গরগর আর ছড়ছড় আলাদা শব্দ — যা শুনলেন, ঠিক সেটাই লিখুন।',
    art: '$_dir/sound.svg',
    lessonPoint: 2,
  );
  static const pushLeak = DoMistake(
    key: '$_k/push-leak',
    textBn: 'সামান্য লিক মানেও তেল কমছে, আর সেই ফাঁক দিয়ে জলীয় বাষ্প ঢোকে — দাগের ছবি বাদ নয়।',
    art: '$_dir/stain.svg',
    lessonPoint: 5,
  );
  static const pushHum = DoMistake(
    key: '$_k/push-hum',
    textBn: 'হালকা একটানা গুনগুন স্বাভাবিক — “বড় গোলমাল” লিখলে মিথ্যে রিপোর্ট যায়।',
    art: '$_dir/sound.svg',
    lessonPoint: 2,
  );
  // Module 6 table R22 (ruling M6-4) and X6: the check is made standing on
  // the ground.
  static const climbLive = DoMistake(
    key: '$_k/climb-live',
    textBn: 'চালু ট্রান্সফরমারের মাচায় ওঠা একদম নয়! 6-পয়েন্ট চেক মাটিতে দাঁড়িয়েই — নেমপ্লেটের ছবি জুম করে তুলুন।',
    art: '$_dir/climb_live.svg',
    deadly: true,
    lessonPoint: 4,
  );

  static DoMistake wrong(M6Part p) => switch (p) {
        M6Part.stain => wrongStain,
        M6Part.gauge => wrongGauge,
        M6Part.gel => wrongGel,
        M6Part.ht => wrongHt,
        M6Part.lt => wrongLt,
        M6Part.fins => wrongFins,
        M6Part.drum => wrongDrum,
        M6Part.plate => wrongPlate,
      };

  /// A wrong reading: [heard] written as [wrote].
  static DoMistake sound(M6Sound heard, M6Sound wrote) {
    if (heard == M6Sound.hum) return soundHum;
    if (wrote == M6Sound.hum) return soundMissed;
    return soundMixed;
  }

  static DoMistake push(M6Push p) => switch (p) {
        M6Push.leak => pushLeak,
        M6Push.hum => pushHum,
        M6Push.climb => climbLive,
      };

  static const List<DoMistake> all = [
    wrongStain,
    wrongGauge,
    wrongGel,
    wrongHt,
    wrongLt,
    wrongFins,
    wrongDrum,
    wrongPlate,
    bushBoth,
    soundHum,
    soundMissed,
    soundMixed,
    pushLeak,
    pushHum,
    climbLive,
  ];
}

/// The DTR this play.
@immutable
class M6DtrState {
  const M6DtrState({
    this.wet = false,
    this.leakAt = M6LeakAt.gasket,
    this.gaugeLow = false,
    this.gel = M6Gel.blue,
    this.bush = M6Bush.clean,
    this.faultBushing = 1,
    this.sound = M6Sound.hum,
    this.kva = 63,
    this.serial = '610428',
    this.light = M6Light.noon,
  });

  final bool wet;
  final M6LeakAt leakAt;
  final bool gaugeLow;
  final M6Gel gel;
  final M6Bush bush;
  final int faultBushing;
  final M6Sound sound;
  final int kva;
  final String serial;
  final M6Light light;

  bool get gelWet => gel == M6Gel.pink || gel == M6Gel.white;

  /// Does [p] (null = the sound) show a fault?
  bool faulty(M6Part? p) => switch (p) {
        null => sound != M6Sound.hum,
        M6Part.stain => wet,
        M6Part.gauge => gaugeLow,
        M6Part.gel => gelWet,
        M6Part.ht => bush == M6Bush.ht,
        M6Part.lt => bush == M6Bush.lt,
        M6Part.fins || M6Part.drum || M6Part.plate => false,
      };

  M6DtrLook get look => M6DtrLook(wet: wet, leakAt: leakAt, gaugeLow: gaugeLow, gel: gel, bush: bush, faultBushing: faultBushing, kva: kva, serial: serial, light: light);
}

@immutable
class M6PhotoDeal {
  const M6PhotoDeal({required this.trigger, required this.requests, required this.state, required this.push, required this.why});

  final M6Trigger trigger;

  /// Five requests: four photos (the nameplate always) and the sound.
  final List<M6Request> requests;
  final M6DtrState state;
  final M6Push push;

  /// What each slot's reason asks about.
  final List<M6WhyTopic> why;

  /// The slot the coworker comes on (his subject's).
  int get pushAt => requests.indexWhere((r) => switch (push) {
        M6Push.leak => r.part == M6Part.stain,
        M6Push.hum => r.isSound,
        M6Push.climb => r.part == M6Part.plate,
      });

  int get faults => [for (final r in requests) if (state.faulty(r.part)) r].length;
}

/// The pushes a deal allows: (a) needs a wet stain asked for, (b) a normal
/// hum; (c) always (the nameplate is always asked for).
List<M6Push> m6PushesFor(M6DtrState s, List<M6Request> requests) => [
      if (s.wet && requests.any((r) => r.part == M6Part.stain)) M6Push.leak,
      if (s.sound == M6Sound.hum) M6Push.hum,
      M6Push.climb,
    ];

const _faultable = {M6Part.stain, M6Part.gauge, M6Part.gel, M6Part.ht, M6Part.lt};

M6WhyTopic _whyFor(M6Request r, M6DtrState s, math.Random rng) {
  final p = r.part;
  if (p == null) {
    return switch (s.sound) {
      M6Sound.hum => M6WhyTopic.hum,
      M6Sound.rattle => M6WhyTopic.rattle,
      M6Sound.crackle => M6WhyTopic.crackle,
    };
  }
  return switch (p) {
    M6Part.stain => s.wet ? M6WhyTopic.stainWet : M6WhyTopic.stainDry,
    M6Part.gauge => s.gaugeLow ? M6WhyTopic.gaugeLow : M6WhyTopic.gaugeOk,
    M6Part.gel => s.gelWet ? M6WhyTopic.gelWet : M6WhyTopic.gelDry,
    M6Part.ht => rng.nextBool() ? M6WhyTopic.htId : (s.bush == M6Bush.ht ? M6WhyTopic.bushFault : M6WhyTopic.bushClean),
    M6Part.lt => rng.nextBool() ? M6WhyTopic.ltId : (s.bush == M6Bush.lt ? M6WhyTopic.bushFault : M6WhyTopic.bushClean),
    M6Part.fins => M6WhyTopic.fins,
    M6Part.drum => M6WhyTopic.drum,
    M6Part.plate => M6WhyTopic.plate,
  };
}

/// A fresh play: the trigger; three photo parts from the seven plus the
/// nameplate, shuffled, with the sound at a dealt place; two wordings each;
/// 1–3 faults among the parts asked for and the sound (a fully healthy DTR
/// only on patrol, at most 1 in 4); at least one of (a) a wet stain asked for or
/// (b) a normal hum; the coworker's push from those that fit, or the climb.
M6PhotoDeal m6PhotoDeal(math.Random rng) {
  while (true) {
    final trigger = M6Trigger.values[rng.nextInt(3)];
    final pool = [M6Part.stain, M6Part.gauge, M6Part.gel, M6Part.ht, M6Part.lt, M6Part.fins, M6Part.drum]..shuffle(rng);
    final photos = [...pool.take(3), M6Part.plate]..shuffle(rng);
    final requests = [for (final p in photos) M6Request(p, rng.nextInt(2))]..insert(rng.nextInt(5), M6Request.sound(rng.nextInt(2)));
    final capable = <M6Part?>[for (final p in photos) if (_faultable.contains(p)) p, null]..shuffle(rng);
    // Healthy is drawn on 1 patrol in 10: deals that fit no myth push are
    // dealt again, which keeps more of the healthy ones (≈ 1 in 6 in play).
    var n = trigger == M6Trigger.patrol && rng.nextInt(10) == 0 ? 0 : 1 + rng.nextInt(3);
    n = math.min(n, capable.length);
    final faulty = capable.take(n).toSet();
    // One bushing side at most.
    if (faulty.contains(M6Part.ht) && faulty.contains(M6Part.lt)) faulty.remove(rng.nextBool() ? M6Part.ht : M6Part.lt);
    final state = M6DtrState(
      wet: faulty.contains(M6Part.stain),
      leakAt: M6LeakAt.values[rng.nextInt(3)],
      gaugeLow: faulty.contains(M6Part.gauge),
      gel: faulty.contains(M6Part.gel) ? (rng.nextBool() ? M6Gel.pink : M6Gel.white) : (rng.nextBool() ? M6Gel.blue : M6Gel.orange),
      bush: faulty.contains(M6Part.ht) ? M6Bush.ht : (faulty.contains(M6Part.lt) ? M6Bush.lt : M6Bush.clean),
      faultBushing: rng.nextInt(12),
      sound: faulty.contains(null) ? (rng.nextBool() ? M6Sound.rattle : M6Sound.crackle) : M6Sound.hum,
      kva: const [25, 63, 100][rng.nextInt(3)],
      serial: '${610000 + rng.nextInt(89999)}',
      light: M6Light.values[rng.nextInt(3)],
    );
    final pushes = m6PushesFor(state, requests);
    if (pushes.length < 2) continue;
    final push = pushes[rng.nextInt(pushes.length)];
    return M6PhotoDeal(trigger: trigger, requests: requests, state: state, push: push, why: [for (final r in requests) _whyFor(r, state, rng)]);
  }
}

/// The zoom a part is readable at (the frame no bigger than the part needs).
const m6MinZoom = <M6Part, double>{
  M6Part.stain: 2.0,
  M6Part.gauge: 2.5,
  M6Part.gel: 2.5,
  M6Part.ht: 2.0,
  M6Part.lt: 3.0,
  M6Part.fins: 2.0,
  M6Part.drum: 3.0,
  M6Part.plate: 2.5,
};

/// How much of a part a good photo holds: the gauge (MIN, MAX and the oil
/// line) and the nameplate (every row) whole; the rest 70 %.
double m6Need(M6Part p) => p == M6Part.gauge || p == M6Part.plate ? 0.9 : 0.7;

/// The other bushing set (HT and LT), or null.
M6Part? m6PairOf(M6Part p) => switch (p) {
      M6Part.ht => M6Part.lt,
      M6Part.lt => M6Part.ht,
      _ => null,
    };

/// The other bushing set this much in the frame makes a bushing photo a
/// hedge (both sets shown, no size judged).
const m6PairLimit = 0.5;

/// The shutter's verdict on a photo meant for [want]: below its readable
/// zoom always "too far" (whatever is in the frame, so a wide shot tells
/// nothing). Then: the HT and the LT bushings together (both, a slip: no
/// hedging lesson pro tip 1); the part whole and alone (accepted) or with
/// another part whole beside it (crowded); a frame too small to hold the part
/// whole, aimed at it (close); most of it (partial); a close-up of another
/// part (wrong); or nothing.
({M6ShotResult result, M6Part? subject}) m6Judge(M6Part want, Rect frame, double zoom, M6PhotoGeo geo) {
  if (zoom + 1e-6 < m6MinZoom[want]!) return (result: M6ShotResult.far, subject: null);
  final r = geo.part(want);
  final cov = m6Coverage(r, frame);
  final pair = m6PairOf(want);
  if (pair != null && cov >= 0.7 && m6Coverage(geo.part(pair), frame) >= m6PairLimit) return (result: M6ShotResult.both, subject: pair);
  if (cov >= m6Need(want)) {
    for (final p in M6Part.values) {
      if (p != want && m6Coverage(geo.part(p), frame) >= 0.7) return (result: M6ShotResult.crowded, subject: p);
    }
    return (result: M6ShotResult.accepted, subject: want);
  }
  // The most of the part a frame this size could ever hold.
  final most = math.min(1.0, frame.width / r.width) * math.min(1.0, frame.height / r.height);
  if (most < m6Need(want) && cov >= most * 0.5) return (result: M6ShotResult.close, subject: want);
  if (cov >= 0.7) return (result: M6ShotResult.partial, subject: want);
  M6Part? best;
  var bestCov = 0.0;
  for (final p in M6Part.values) {
    if (p == want) continue;
    final c = m6Coverage(geo.part(p), frame);
    if (c > bestCov) {
      bestCov = c;
      best = p;
    }
  }
  if (best != null && bestCov >= 0.7) return (result: M6ShotResult.wrong, subject: best);
  return (result: M6ShotResult.empty, subject: null);
}

/// The play state (pure logic).
class M6PhotoRun {
  M6PhotoRun(this.deal);
  final M6PhotoDeal deal;

  int index = 0;
  int slips = 0;
  int slotSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The slot's photo / reading is in (its reason comes next).
  var roundDone = false;
  var soundHeard = false;
  var reportSent = false;

  M6Request get request => deal.requests[index.clamp(0, deal.requests.length - 1)];
  bool get allShot => index >= deal.requests.length;
  bool get done => reportSent;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get _open => !ended && !roundDone && !allShot;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    slotSlips++;
    return m;
  }

  /// The shutter on [frame] at [zoom]: null when no photo is due now.
  ({M6ShotResult result, DoMistake? mistake})? shoot(Rect frame, double zoom, M6PhotoGeo geo) {
    if (!_open || request.isSound) return null;
    final want = request.part!;
    final j = m6Judge(want, frame, zoom, geo);
    switch (j.result) {
      case M6ShotResult.wrong:
        return (result: j.result, mistake: _slip(M6PhotoMistakes.wrong(want)));
      case M6ShotResult.both:
        return (result: j.result, mistake: _slip(M6PhotoMistakes.bushBoth));
      case M6ShotResult.accepted:
        roundDone = true;
        if (want == M6Part.plate) _tag(M6PhotoLines.caughtPlate);
        if (want == M6Part.ht || want == M6Part.lt) _tag(M6PhotoLines.caughtHtLt);
        if (deal.state.faulty(want)) _tag(M6PhotoLines.caughtFault);
        return (result: j.result, mistake: null);
      case M6ShotResult.far:
      case M6ShotResult.partial:
      case M6ShotResult.close:
      case M6ShotResult.crowded:
      case M6ShotResult.empty:
        return (result: j.result, mistake: null);
    }
  }

  /// The ear held (the sound slot only).
  void hear() {
    if (_open && request.isSound) soundHeard = true;
  }

  /// A reading written down: right closes the slot; wrong is a slip.
  DoMistake? pickSound(M6Sound s) {
    if (!_open || !request.isSound || !soundHeard) return null;
    final heard = deal.state.sound;
    if (s != heard) return _slip(M6PhotoMistakes.sound(heard, s));
    roundDone = true;
    _tag(M6PhotoLines.caughtSound);
    if (heard != M6Sound.hum) _tag(M6PhotoLines.caughtFault);
    return null;
  }

  /// Listened to a slip-line coworker.
  DoMistake pushSlip(DoMistake m) => _slip(m);

  /// Fails the play (listening to the deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  void advance() {
    if (allShot) return;
    index++;
    roundDone = false;
    slotSlips = 0;
    soundHeard = false;
  }

  /// 'রিপোর্ট পাঠান' once every slot is in.
  bool sendReport() {
    if (!allShot || ended) return false;
    reportSent = true;
    return true;
  }
}

/// The quick bonus (owner, module 6 rulings M6-13: 120 s accepted as
/// designed). A clean play ≈ 4 photos × (aim ~6 s + reason ~8 s) + the sound
/// (~13 s) + the coworker (~10 s) + the report ≈ 81 s.
const m6PhotoQuickMs = 120000;

@immutable
class M6PhotoPack {
  const M6PhotoPack({required this.id, required this.titleBn, this.quickMs = m6PhotoQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6PhotoPack> m6PhotoPacks = {
  'do_6_1_a': M6PhotoPack(id: 'do_6_1_a', titleBn: M6PhotoLines.title),
};

/// The three sounds (wordless, synthesised: the lesson gives only the words).
const m6SoundClips = <M6Sound, String>{
  M6Sound.hum: 'game/art/m6_dtr_photo_report/hum.ogg',
  M6Sound.rattle: 'game/art/m6_dtr_photo_report/rattle.ogg',
  M6Sound.crackle: 'game/art/m6_dtr_photo_report/crackle.ogg',
};

/// Test hook (tests only): the open play's camera, scene and deal.
class M6PhotoProbe {
  M6PhotoProbe._(this._s);
  final _PhotoRunPageState _s;
  static M6PhotoProbe? current;

  M6Cam get cam => _s._cam.value;
  M6PhotoGeo? get geo => _s._geoNow;
  M6PhotoRun get run => _s._run;

  /// Puts the frame on [part] at [zoom] (as a drag and the rail would).
  void aim(M6Part part, double zoom) {
    final g = _s._geoNow;
    if (g != null) aimAt(g.part(part).center, zoom);
  }

  void aimAt(Offset centre, double zoom) => _s._aimAt(centre, zoom);

  /// Puts [line] on the JE's chat (read out, as a reply would be).
  void jeSay(String line) => _s._jeSay(line);
}

// ============================================================================
// Page
// ============================================================================

class M6DtrPhotoReportPage extends StatefulWidget {
  const M6DtrPhotoReportPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6PhotoPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6DtrPhotoReportPage> createState() => _M6DtrPhotoReportPageState();
}

class _M6DtrPhotoReportPageState extends State<M6DtrPhotoReportPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PhotoRunPage(
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

class _PhotoRunPage extends ConsumerStatefulWidget {
  const _PhotoRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6PhotoPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PhotoRunPage> createState() => _PhotoRunPageState();
}

class _PhotoRunPageState extends ConsumerState<_PhotoRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  static const _trayH = 62.0;
  static const _shutterD = 68.0;
  static const _liveW = 108.0;
  static const _liveH = 81.0;

  final _scoreKey = GlobalKey();
  late final M6PhotoRun _run;
  late final int _seed = widget.rng.nextInt(1 << 20);
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
  var _sent = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;

  // The phone camera.
  final _cam = ValueNotifier<M6Cam>(const M6Cam(Offset(180, 400), 1));
  M6PhotoGeo? _geoNow;
  M6DtrPainter? _world;
  var _camSet = false;

  /// This slot: the frame moved / the zoom changed (the hints), his subject
  /// framed (the coworker's gate).
  var _moved = false;
  var _zoomed = false;
  var _seen = false;
  double _zoomAtStart = 1;

  // Pointers on the scene (one finger pans, two pinch).
  final Map<int, Offset> _ptrs = {};
  Offset _downAt = Offset.zero;
  var _downMoved = false;
  double? _pinchD0;
  double _pinchZ0 = 1;

  // The JE's chat.
  String _je = '';
  int _jeTok = 0;

  /// The speech chain reading a JE line out (the gesture hand waits), or -1.
  int _taskChain = -1;

  /// The zoom rail's height on this screen.
  double _railH = _ZoomRail.maxHeight;

  /// The photos in the tray (their crop on the scene), by slot.
  final Map<int, Rect> _shots = {};
  int _flashTok = 0;
  ({int slot, Rect from, int tok})? _fly;
  int _flyTok = 0;

  // The sound slot.
  var _hearing = false;
  int _hearTok = 0;
  Timer? _hearTimer;
  List<ChoiceOption> _soundOpts = const [];
  final Set<String> _soundWrong = {};
  String? _soundPicked;
  var _soundBusy = false;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _shutterKey = GlobalKey();
  final _earKey = GlobalKey();
  final _sendKey = GlobalKey();
  final _zoomThumbKey = GlobalKey();
  int _hintN = 0;

  @override
  void initState() {
    super.initState();
    _run = M6PhotoRun(m6PhotoDeal(widget.rng));
    _cam.addListener(_onCam);
    M6PhotoProbe.current = M6PhotoProbe._(this);
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M6PhotoDeal get _deal => _run.deal;
  M6Request get _req => _run.request;

  @override
  void dispose() {
    disposeCoworker();
    _hearTimer?.cancel();
    _cam.removeListener(_onCam);
    _cam.dispose();
    _chain++;
    if (M6PhotoProbe.current?._s == this) M6PhotoProbe.current = null;
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

  /// A task line read out (the JE's request or reply, the task again): the
  /// gesture hand waits while it is said (spoken, or its reading time when
  /// muted); then the guide's bubble clears — the words stay on the phone's
  /// chat — so it never stands over the DTR while the player aims.
  Future<void> _sayTask(List<String> lines, {GuideMood mood = GuideMood.talk}) async {
    if (lines.isEmpty) return;
    final chain = _chain + 1;
    _taskChain = chain;
    await _sayChain(lines, mood: mood);
    if (_muted) await Future<void>.delayed(MascotSpeechLibrary.readHold(lines.last));
    if (!mounted || chain != _chain) return;
    final guide = ref.read(guideDirectorProvider);
    if (guide.line == lines.last) ref.read(guideDirectorProvider.notifier).softClearLine();
    setState(() => _taskChain = -1);
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

  bool get _soundUp => _soundOpts.isNotEmpty;

  bool get _canPlay =>
      !_intro &&
      !_ended &&
      !_sent &&
      _card == null &&
      !reasonOpen &&
      !tableBusy &&
      !coworkerOpen &&
      !_run.roundDone &&
      !_freeze &&
      !_hearing &&
      !_soundUp;

  /// A photo is due now (the frame and the zoom work).
  bool get _aiming => !_run.allShot && !_req.isSound;

  String get _task {
    if (_run.allShot) return M6PhotoLines.sendNow;
    if (_req.isSound && _soundUp) return M6PhotoLines.soundAsk;
    return M6PhotoLines.request(_req);
  }

  // --- the flow ----------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    final g = _geoNow;
    if (g != null && !_camSet) {
      _camSet = true;
      _cam.value = g.startCam;
    }
    _openRequest(first: true);
  }

  /// The JE's next message: the slot opens.
  void _openRequest({bool first = false}) {
    setState(() {
      _moved = false;
      _zoomed = false;
      _seen = false;
      _zoomAtStart = _cam.value.zoom;
      _je = M6PhotoLines.request(_req);
      _jeTok++;
      _wake++;
    });
    _cue('sounds/intro/glass.ogg', volume: 0.45);
    unawaited(_sayTask([if (first) M6PhotoLines.start, _je]));
  }

  /// A JE reply in the chat, read out by the guide.
  void _jeSay(String line) {
    setState(() {
      _je = line;
      _jeTok++;
    });
    _cue('sounds/intro/glass.ogg', volume: 0.45);
    unawaited(_sayTask([line]));
  }

  /// The coworker's slot for a photo push ((a) the stain, (c) the plate).
  bool get _hisPhotoSlot => !coworkerDone && _deal.push != M6Push.hum && _run.index == _deal.pushAt;

  void _markSeen() {
    if (_seen) return;
    _seen = true;
    if (_hisPhotoSlot && !coworkerDue) scheduleCoworker();
  }

  /// The part asked for framed by this slot's own aim: the frame moved or
  /// zoomed since the request, near the part's readable zoom, the part mostly
  /// in (the wide start view holding it does not count).
  bool _framed(M6PhotoGeo g, M6Cam cam) {
    final want = _req.part!;
    return (_moved || _zoomed) && cam.zoom + 0.5 >= m6MinZoom[want]! && m6Coverage(g.part(want), cam.frame) >= 0.7;
  }

  void _onCam() {
    final g = _geoNow;
    if (g == null || !_aiming || _run.roundDone) return;
    if (_framed(g, _cam.value)) _markSeen();
  }

  void _setCam(M6Cam c) {
    final g = _geoNow;
    final next = g == null ? c : g.clampCam(c);
    if (next == _cam.value) return;
    _cam.value = next;
  }

  void _panBy(Offset d) {
    _setCam(M6Cam(_cam.value.center + d, _cam.value.zoom));
    if (!_moved && d.distance > 0) setState(() => _moved = true);
    _onCam();
  }

  void _setZoom(double z) {
    _setCam(M6Cam(_cam.value.center, z));
    if (!_zoomed && (_cam.value.zoom - _zoomAtStart).abs() > 0.05) setState(() => _zoomed = true);
    _onCam();
  }

  void _aimAt(Offset centre, double zoom) {
    if (!_canPlay || !_aiming) return;
    _setCam(M6Cam(centre, zoom));
    setState(() {
      _moved = true;
      _zoomed = true;
    });
    _onCam();
  }

  bool get _canAim => _canPlay && _aiming;

  void _pointerDown(PointerDownEvent e) {
    _ptrs[e.pointer] = e.localPosition;
    if (_ptrs.length == 1) {
      _downAt = e.localPosition;
      _downMoved = false;
    } else if (_ptrs.length == 2) {
      final p = _ptrs.values.toList();
      _pinchD0 = (p[0] - p[1]).distance;
      _pinchZ0 = _cam.value.zoom;
      _downMoved = true;
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    final prev = _ptrs[e.pointer];
    if (prev == null) return;
    _ptrs[e.pointer] = e.localPosition;
    if ((e.localPosition - _downAt).distance > 6) _downMoved = true;
    if (!_canAim) return;
    if (_ptrs.length == 1) {
      _panBy(e.localPosition - prev);
    } else if (_ptrs.length >= 2) {
      final d0 = _pinchD0;
      final p = _ptrs.values.toList();
      if (d0 != null && d0 > 4) _setZoom(_pinchZ0 * (p[0] - p[1]).distance / d0);
    }
  }

  void _pointerUp(PointerEvent e) {
    _ptrs.remove(e.pointer);
    if (_ptrs.length < 2) _pinchD0 = null;
    if (_ptrs.isEmpty && !_downMoved && e is PointerUpEvent && _canPlay) _hints.missTap();
  }

  void _railDrag(double dy) {
    if (!_canAim) return;
    _setZoom(_cam.value.zoom - dy / (_railH - _ZoomRail.thumb) * (m6ZoomMax - m6ZoomMin));
  }

  // --- the shutter ---------------------------------------------------------------
  void _shoot(Offset global) {
    if (!_canPlay || !_aiming) return;
    final g = _geoNow;
    if (g == null) return;
    final cam = _cam.value;
    final frame = cam.frame;
    // His subject framed by this slot's aim (a photo would finish it): he
    // comes now.
    if (_hisPhotoSlot && _framed(g, cam)) _markSeen();
    if (_hisPhotoSlot && holdForCoworker()) return;
    HapticFeedback.lightImpact();
    _cue('sounds/intro/click.ogg', volume: 0.8);
    setState(() => _flashTok++);
    final shot = _run.shoot(frame, cam.zoom, g);
    if (shot == null) return;
    switch (shot.result) {
      case M6ShotResult.accepted:
        _accept(frame);
      case M6ShotResult.far:
        _jeSay(M6PhotoLines.jeFar);
      case M6ShotResult.partial:
        _jeSay(M6PhotoLines.jePartial);
      case M6ShotResult.close:
        _jeSay(M6PhotoLines.jeClose);
      case M6ShotResult.crowded:
        _jeSay(M6PhotoLines.jeOnly);
      case M6ShotResult.empty:
        _jeSay(M6PhotoLines.jeEmpty);
      case M6ShotResult.wrong:
      case M6ShotResult.both:
        setState(() => _wake++);
        unawaited(_mistake(shot.mistake!, global));
    }
  }

  /// A slot is in: the photo flies to the tray (or the reading is written),
  /// ◆ on the table, the reason.
  void _slotIn({Rect? frame}) {
    final i = _run.index;
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    setState(() {
      if (frame != null) {
        _shots[i] = frame;
        _fly = (slot: i, from: frame, tok: ++_flyTok);
      }
      _wake++;
    });
    putOnTable(10 + (_run.slotSlips == 0 ? 5 : 0));
    final topic = _deal.why[i];
    unawaited(askReason(
      deal: () => dealChoices(M6PhotoLines.whyRight[topic]!, M6PhotoLines.wrongFor(topic), widget.rng),
      question: M6PhotoLines.whyQ(topic),
      stillValid: () => _run.index == i && !_ended,
    ));
  }

  void _accept(Rect frame) => _slotIn(frame: frame);

  void _next() {
    setState(_run.advance);
    if (_run.allShot) {
      setState(() {
        _je = M6PhotoLines.sendNow;
        _wake++;
      });
      unawaited(_sayTask([M6PhotoLines.sendNow]));
      return;
    }
    _openRequest();
  }

  // --- the sound ---------------------------------------------------------------
  void _hear() {
    if (!_canPlay || _run.allShot || !_req.isSound || _run.soundHeard) return;
    HapticFeedback.mediumImpact();
    _run.hear();
    _cue(m6SoundClips[_deal.state.sound]!, volume: 0.9);
    setState(() {
      _hearing = true;
      _hearTok++;
      _wake++;
    });
    _hearTimer?.cancel();
    _hearTimer = Timer(Duration(milliseconds: _quiet ? 600 : 2000), () {
      if (!mounted || _ended) return;
      setState(() => _hearing = false);
      _openSoundDeck();
    });
  }

  /// The three readings; with a normal hum and his push (b) dealt, he comes
  /// first (the readings wait for him).
  void _openSoundDeck() {
    if (_ended || _run.allShot || !_req.isSound || _run.roundDone || !_run.soundHeard || _soundUp) return;
    if (_deal.push == M6Push.hum && _run.index == _deal.pushAt && !coworkerDone) {
      if (!coworkerDue) scheduleCoworker();
      if (holdForCoworker()) return;
    }
    final opts = [for (final e in M6PhotoLines.readings.entries) ChoiceOption(e.value, e.key == _deal.state.sound)]..shuffle(widget.rng);
    setState(() {
      _soundOpts = opts;
      _soundWrong.clear();
      _soundPicked = null;
      _wake++;
    });
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    unawaited(_sayChain([M6PhotoLines.soundAsk], mood: GuideMood.think));
  }

  Future<void> _pickSound(ChoiceOption o, Offset origin) async {
    if (_ended || _card != null || _soundBusy || _soundWrong.contains(o.textBn) || _soundPicked != null) return;
    _hush();
    final m = _run.pickSound(M6PhotoLines.soundOf(o.textBn));
    if (m != null) {
      setState(() => _soundWrong.add(o.textBn));
      unawaited(_mistake(m, origin));
      return;
    }
    if (!_run.roundDone) return;
    _soundBusy = true;
    setState(() => _soundPicked = o.textBn);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _ended) return;
    _soundBusy = false;
    setState(() => _soundOpts = const []);
    _slotIn();
  }

  // --- the report ---------------------------------------------------------------
  Future<void> _send() async {
    if (_intro || _ended || _sent || _card != null || !_run.allShot || tableBusy) return;
    if (!_run.sendReport()) return;
    _tick('sounds/intro/confirm.ogg', 0.6);
    setState(() => _sent = true);
    _jeSay(M6PhotoLines.jeGot);
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1400));
    if (!mounted) return;
    await _finish();
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M6PhotoLines.coworker(_deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    final at = _deal.pushAt;
    if (_ended || _run.allShot || _run.index > at || _run.roundDone) return null;
    if (_deal.push == M6Push.hum && _soundUp) return null;
    if (_run.index < at || _intro || _card != null || tableBusy || _freeze || _hearing) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _deal.push;
    if (!held) {
      final m = M6PhotoMistakes.push(p);
      if (m.deadly) {
        final g = _geoNow;
        if (g != null) _flashAt = g.part(M6Part.ht).topCenter;
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6PhotoLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    if (p == M6Push.hum) {
      unawaited(_sayChain([M6PhotoLines.callHeld(p)], mood: GuideMood.glad));
      _openSoundDeck();
      return;
    }
    unawaited(_sayTask([M6PhotoLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    _tick('sounds/intro/tick.ogg', 0.5);
    if (coworkerOpen) {
      unawaited(_sayChain([nextCoworkerAsk()]));
    } else if (reasonOpen) {
      unawaited(_sayChain([M6PhotoLines.tapWhy[_nudgeN++ % M6PhotoLines.tapWhy.length]]));
    } else {
      unawaited(_sayTask([_nudge.next(_task)]));
    }
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _hearTimer?.cancel();
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
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6photo/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Listening to the climb: the scene freezes grey and the arc comes off it
  /// in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _hearTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _soundOpts = const [];
      _fly = null;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m6photo/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6PhotoLines.deadlyWord : M6PhotoLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same slot goes on from where it was.
        _hush();
        setState(() {
          _card = null;
          _wake++;
        });
        if (!_run.allShot && _req.isSound && _run.soundHeard && !_soundUp && !_run.roundDone) {
          _openSoundDeck();
          return;
        }
        unawaited(_sayTask([_task]));
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
    await _say(!_run.passed ? M6PhotoLines.fail : (_quickBonus ? M6PhotoLines.quick : M6PhotoLines.allSet),
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

  // --- the gesture hand ------------------------------------------------------------
  /// How to touch, never what: a fixed drag nudge from the frame's centre
  /// up-left (whatever is asked for); once the frame has moved, a drag nudge
  /// up the zoom thumb; once it has also zoomed, those two and a tap on the
  /// shutter in turn. The ear's hold ring; a tap on 'রিপোর্ট পাঠান'.
  HintSpec? _hint() {
    final n = _hintN++;
    if (_run.allShot) return HintSpec.tapOn(_sendKey);
    if (_req.isSound) return _run.soundHeard ? null : HintSpec.holdOn(_earKey);
    final pan = HintSpec.drag(_cam.value.center, toward: const Offset(-0.7071, -0.7071), travel: 64, space: HintSpace.scene);
    if (!_moved) return pan;
    final zoom = HintSpec.dragFrom(_zoomThumbKey, toward: const Offset(0, -1), travel: 48);
    if (!_zoomed) return zoom ?? pan;
    return [pan, zoom, HintSpec.tapOn(_shutterKey)][n % 3] ?? pan;
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_passed) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  M6DtrPainter _worldFor(M6PhotoGeo geo) {
    final w = _world;
    if (w != null && w.geo == geo) return w;
    return _world = M6DtrPainter(geo: geo, look: _deal.state.look, seed: _seed);
  }

  static M6PhotoGeo _geoOf(Size size, EdgeInsets pad) {
    final w = math.max(1.0, size.width);
    final h = (360 * size.height / w).clamp(560.0, 900.0);
    return M6PhotoGeo.forScene(h, pad.bottom * 360 / w, topInset: pad.top * 360 / w);
  }

  /// A scene rect (design px) on the screen (the frame covers the screen).
  static Rect _toScreen(Rect r, Size size) {
    final w = math.max(1.0, size.width);
    final sh = (360 * size.height / w).clamp(560.0, 900.0);
    final s = math.max(size.width / 360, size.height / sh);
    final dx = (size.width - 360 * s) / 2;
    final dy = (size.height - sh * s) / 2;
    return Rect.fromLTWH(dx + r.left * s, dy + r.top * s, r.width * s, r.height * s);
  }

  Rect _slotRect(int i, Size size, EdgeInsets pad) {
    const gap = 6.0;
    final w = (size.width - 16 - gap * 4) / 5;
    return Rect.fromLTWH(8 + i * (w + gap), size.height - pad.bottom - 8 - _trayH, w, _trayH);
  }

  List<Widget> _scene(SceneMetrics m) {
    final w = math.max(1.0, MediaQuery.sizeOf(context).width);
    final geo = _geoNow = M6PhotoGeo.forScene(m.height, m.inset, topInset: MediaQuery.paddingOf(context).top * 360 / w);
    final world = _worldFor(geo);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final aiming = !_intro && _aiming && !_freeze && _mark == null;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(key: const ValueKey('dtr'), child: RepaintBoundary(child: CustomPaint(painter: world))),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      if (aiming)
        Positioned.fill(
          key: const ValueKey('frame'),
          child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M6FramePainter(cam: _cam)))),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6PhotoLines.sceneLabel,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerUp,
          ),
        ),
      ),
      if (_flashTok > 0 && !quiet && !_freeze)
        Positioned.fill(
          key: ValueKey('shutter-flash-$_flashTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 0),
              duration: const Duration(milliseconds: 260),
              builder: (_, v, _) => v <= 0.01 ? const SizedBox.shrink() : ColoredBox(color: Colors.white.withValues(alpha: v)),
            ),
          ),
        ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('flash'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6FlashPainter(at: _flashAt, v: v)),
            ),
          ),
        ),
    ];
  }

  Widget _slot(int i, M6DtrPainter world) {
    final r = _deal.requests[i];
    final crop = _shots[i];
    final doneSound = r.isSound && (_run.index > i || (_run.index == i && _run.roundDone));
    final now = !_run.allShot && _run.index == i;
    final Widget body;
    if (crop != null) {
      body = RepaintBoundary(child: CustomPaint(painter: M6CropPainter(world: world, crop: crop), size: Size.infinite));
    } else if (doneSound) {
      body = Stack(children: [
        Positioned.fill(child: CustomPaint(painter: M6WavePainter(kind: _deal.state.sound.index))),
        Positioned(
          left: 2,
          right: 2,
          bottom: 3,
          child: Text(M6PhotoLines.soundShort(_deal.state.sound),
              textAlign: TextAlign.center, maxLines: 1, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory)),
        ),
      ]);
    } else {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(r.isSound ? Icons.hearing_rounded : Icons.photo_camera_rounded, size: 20, color: SlmColors.ivory.withValues(alpha: now ? 0.95 : 0.5)),
            Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SlmColors.ivory.withValues(alpha: now ? 0.95 : 0.5))),
          ],
        ),
      );
    }
    return Container(
      key: ValueKey('slot-$i'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xCC0B1A33),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: now ? SlmColors.gold400 : const Color(0x55FFFFFF), width: now ? 2 : 1),
      ),
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final geo = _geoOf(size, pad);
    final world = _worldFor(_geoNow ?? geo);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final soundUp = _soundUp && playing;
    final deckUp = reasonOpen || coworkerChoiceUp || soundUp;
    final handsOn = playing && !_sent && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final aiming = handsOn && _aiming;
    final soundSlot = handsOn && !_run.allShot && _req.isSound;
    final fly = _fly;
    final controlBottom = pad.bottom + 8 + _trayH + 10;
    final guideBottom = pad.bottom + 8 + _trayH + 2;
    // The phone's live view top right, right of every part and under the JE's
    // chat (three lines); the zoom rail under it, above the corner guide.
    final liveTop = pad.top + 152;
    final railTop = liveTop + _liveH + 10;
    _railH = (size.height - guideBottom - 116 - 8 - railTop).clamp(96.0, _ZoomRail.maxHeight);
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_hearing && fly == null && _taskChain != _chain,
            hintKey: '${_run.index}/${_run.allShot}',
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 170), quiet: quiet),
              if (!_intro && _je.isNotEmpty)
                Positioned(
                  key: const ValueKey('je-chat'),
                  left: 8,
                  right: 8,
                  top: pad.top + 62,
                  child: IgnorePointer(child: _JeChat(text: _je, tok: _jeTok, quiet: quiet)),
                ),
              if (playing && !_run.allShot)
                Positioned(
                  key: const ValueKey('live-view'),
                  right: 8,
                  top: liveTop,
                  width: _liveW,
                  height: _liveH,
                  child: IgnorePointer(
                    child: _req.isSound
                        ? _hearing && !quiet
                            ? TweenAnimationBuilder<double>(
                                key: ValueKey('wave-$_hearTok'),
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 1800),
                                builder: (_, v, _) => CustomPaint(painter: M6WavePainter(kind: _deal.state.sound.index, v: v)),
                              )
                            : CustomPaint(painter: M6WavePainter(kind: _run.soundHeard ? _deal.state.sound.index : null))
                        : _LiveView(world: world, cam: _cam),
                  ),
                ),
              if (aiming)
                Positioned(
                  key: ValueKey('zoom-rail-${_run.index}'),
                  right: 6,
                  top: railTop,
                  width: _ZoomRail.width,
                  height: _railH,
                  child: _ZoomRail(cam: _cam, height: _railH, thumbKey: _zoomThumbKey, onDrag: _railDrag),
                ),
              if (aiming)
                Positioned(
                  key: const ValueKey('shutter'),
                  left: size.width / 2 - _shutterD / 2,
                  bottom: controlBottom,
                  width: _shutterD,
                  height: _shutterD,
                  child: _Shutter(key: _shutterKey, onTap: _shoot),
                ),
              if (soundSlot)
                Positioned(
                  key: const ValueKey('ear'),
                  left: size.width / 2 - 70,
                  bottom: controlBottom,
                  width: 140,
                  height: _shutterD,
                  child: _EarButton(key: _earKey, heard: _run.soundHeard || _hearing, onHold: _hear, onTap: _hints.missTap),
                ),
              if (handsOn && _run.allShot)
                Positioned(
                  key: const ValueKey('send'),
                  left: size.width / 2 - 80,
                  bottom: controlBottom + 6,
                  width: 160,
                  height: 56,
                  child: _SendButton(key: _sendKey, onTap: () => unawaited(_send())),
                ),
              if (!_intro)
                Positioned(
                  key: const ValueKey('tray'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 8,
                  height: _trayH,
                  child: IgnorePointer(
                    child: Row(
                      children: [
                        for (var i = 0; i < _deal.requests.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(child: _slot(i, world)),
                        ],
                      ],
                    ),
                  ),
                ),
              if (fly != null && !quiet)
                Positioned.fill(
                  key: ValueKey('fly-${fly.tok}'),
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 560),
                      curve: Curves.easeInOutCubic,
                      onEnd: () {
                        if (mounted && _fly?.tok == fly.tok) setState(() => _fly = null);
                      },
                      builder: (_, t, _) {
                        final r = Rect.lerp(_toScreen(fly.from, size), _slotRect(fly.slot, size, pad), t)!;
                        return Stack(children: [
                          Positioned.fromRect(
                            rect: r,
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                              child: CustomPaint(painter: M6CropPainter(world: world, crop: fly.from)),
                            ),
                          ),
                        ]);
                      },
                    ),
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerChoiceUp
                            ? coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck'))
                            : ChoiceDeck(
                                key: ValueKey('sound-deck-${_run.index}'),
                                options: _soundOpts,
                                quiet: quiet,
                                muted: _muted,
                                wrong: _soundWrong,
                                picked: _soundPicked,
                                onPick: (o, at) => unawaited(_pickSound(o, at)),
                              ),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: deckUp ? pad.bottom + 236 : guideBottom, onLeft: coworkerFromRight),
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
                  line: M6PhotoLines.intro(_deal.trigger),
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 4, muted: _muted)),
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

/// The JE's latest message on the phone's chat.
class _JeChat extends StatelessWidget {
  const _JeChat({required this.text, required this.tok, required this.quiet});
  final String text;
  final int tok;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('je-$tok'),
      tween: Tween(begin: quiet ? 1 : 0.86, end: 1),
      duration: Duration(milliseconds: quiet ? 1 : 260),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, alignment: Alignment.topLeft, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 8),
        decoration: BoxDecoration(
          color: const Color(0xF2F3F7FA),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(14), bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14), topLeft: Radius.circular(4)),
          boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1F5F8F)),
              child: const Text('JE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(M6PhotoLines.jeName, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1F5F8F))),
                  Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3, color: const Color(0xFF14202B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone's screen: what the frame holds, at its zoom.
class _LiveView extends StatelessWidget {
  const _LiveView({required this.world, required this.cam});
  final M6DtrPainter world;
  final ValueListenable<M6Cam> cam;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: M6CropPainter(world: world, cam: cam)))),
          Positioned(
            right: 4,
            bottom: 3,
            child: ValueListenableBuilder<M6Cam>(
              valueListenable: cam,
              builder: (_, c, _) => Text('${c.zoom.toStringAsFixed(1)}x',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 3)])),
            ),
          ),
        ],
      ),
    );
  }
}

/// The zoom rail: drag the thumb up to zoom in (1x at the bottom, 4x at the
/// top).
class _ZoomRail extends StatelessWidget {
  const _ZoomRail({required this.cam, required this.height, required this.thumbKey, required this.onDrag});
  final ValueListenable<M6Cam> cam;
  final double height;
  final GlobalKey thumbKey;
  final ValueChanged<double> onDrag;

  static const width = 44.0;
  static const maxHeight = 196.0;
  static const thumb = 36.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M6PhotoLines.zoom,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerMove: (e) => onDrag(e.delta.dy),
        child: Stack(
          children: [
            Positioned(
              left: width / 2 - 3,
              top: thumb / 2,
              bottom: thumb / 2,
              width: 6,
              child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xAA0B1A33), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0x88FFFFFF)))),
            ),
            const Positioned(top: 0, left: 0, right: 0, child: Text('4x', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 3)]))),
            const Positioned(bottom: 0, left: 0, right: 0, child: Text('1x', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 3)]))),
            ValueListenableBuilder<M6Cam>(
              valueListenable: cam,
              builder: (_, c, _) {
                final f = ((c.zoom - m6ZoomMin) / (m6ZoomMax - m6ZoomMin)).clamp(0.0, 1.0);
                return Positioned(
                  left: (width - thumb) / 2,
                  top: (1 - f) * (height - thumb),
                  width: thumb,
                  height: thumb,
                  child: Container(
                    key: thumbKey,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF1F5F8F), width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
                    ),
                    child: Text(c.zoom.toStringAsFixed(1), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF14202B))),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({super.key, required this.onTap});
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M6PhotoLines.shutter,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF1F5F8F), width: 4),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: const Center(child: Icon(Icons.photo_camera_rounded, size: 30, color: Color(0xFF14202B))),
        ),
      ),
    );
  }
}

class _EarButton extends StatelessWidget {
  const _EarButton({super.key, required this.heard, required this.onHold, required this.onTap});
  final bool heard;
  final VoidCallback onHold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M6PhotoLines.listen,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onHold,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: heard ? const Color(0xFF1F5F8F) : Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFF1F5F8F), width: 3),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hearing_rounded, size: 26, color: heard ? Colors.white : const Color(0xFF14202B)),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(M6PhotoLines.listen, maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: heard ? Colors.white : const Color(0xFF14202B))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: M6PhotoLines.send,
      button: true,
      child: Material(
        color: SlmColors.emerald500,
        borderRadius: BorderRadius.circular(18),
        elevation: 6,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send_rounded, size: 22, color: SlmColors.navy950),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(M6PhotoLines.send, maxLines: 1, style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: SlmColors.navy950)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
