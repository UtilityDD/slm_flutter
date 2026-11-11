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
import 'learn_feedback_lines.dart';
import 'level_frame.dart';
import 'level_juice.dart' show FreezeFrame, freezeFilter, starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm2_comealong_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'rod_van.dart' show RodVanGeo, RodVanPainter;
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.4, কাজ 1: "সঠিক কাম-অ্যালং". Behind the van before a wire-pulling
// job: read the docket on the door (the conductor — ACSR, AAAC or insulated —
// and the pull the job needs, in tonnes), take a tool off the rack (its rating
// plate or grip label is readable only up close), feel along it by hand (hook
// and safety latch, ratchet and pawl, the wire rope; or the grip's teeth) —
// a flaw shows only where the hand has been — then take it or put it back
// (a damaged one found by hand goes aside, tagged বাতিল). Three dockets, easy
// to hard: the come-along (plate ≥ the docket's pull), the wire grip (made for
// the docket's conductor), and a last one where nothing on the rack is right —
// hold the job. Once a play the careless coworker (level 1's rival) peeps in:
// "বড় তার? ছোটটাতেই হবে" (the 1-tonne puller with a pipe on the handle), or
// the lesson's myth "ACSR আর AAAC-তে আর কী তফাৎ". Built on the shared level
// kit (GAME_LEVEL_PLAYBOOK.md): guide first, full scene (the van of lesson
// 1.5, reused read-only), corner guide, ◆ on the table → "কেন …?" → next
// docket by itself.
//
// Deadly: a come-along rated below the job's pull (lesson 2.4 point 1: it can
// break under the load; point 2: a failure is a deadly sling-shot) — also by
// listening to him. Slips: a damaged tool (latch, pawl, rope, greasy or worn
// teeth); the wrong grip for the conductor (the lesson's myth: it damages the
// conductor for good); holding the job when the right tool was there.
//
// Voice: the guide's lines on device TTS; the coworker's new lines on device
// TTS too (to be recorded; listed in M2ComeAlongLines.toRecord). Art: drawn
// in code (m2_comealong_world.dart); the mistake cards use the existing tool
// photos in assets/safety/library/tools/.

// ============================================================================
// Content
// ============================================================================

enum CaKind { puller, grip }

/// The conductor a grip is made for (lesson 2.4 point 1: ACSR, AAAC, insulated).
enum CaWire { acsr, aaac, insulated }

extension CaWireText on CaWire {
  /// Printed on the grip.
  String get tag => switch (this) {
        CaWire.acsr => 'ACSR',
        CaWire.aaac => 'AAAC',
        CaWire.insulated => 'INSULATED',
      };

  /// As the docket names it.
  String get bn => switch (this) {
        CaWire.acsr => 'ACSR',
        CaWire.aaac => 'AAAC',
        CaWire.insulated => 'ইনসুলেটেড',
      };
}

enum CaFlaw { none, latch, pawl, rope, grease, teeth }

const _pullerFlaws = [CaFlaw.latch, CaFlaw.pawl, CaFlaw.rope];
const _gripFlaws = [CaFlaw.grease, CaFlaw.teeth];

@immutable
class CaItem {
  const CaItem.puller({required this.id, required int this.tons, this.flaw = CaFlaw.none})
      : kind = CaKind.puller,
        wire = null;
  const CaItem.grip({required this.id, required CaWire this.wire, this.flaw = CaFlaw.none})
      : kind = CaKind.grip,
        tons = null;
  final String id;
  final CaKind kind;

  /// A come-along's plate (1 or 2 tonnes).
  final int? tons;

  /// A grip's conductor.
  final CaWire? wire;
  final CaFlaw flaw;

  /// The plate / label as printed (lesson's plate: "2 TON · 20 kN").
  String get tag => kind == CaKind.puller ? '$tons TON · ${tons! * 10} kN' : wire!.tag;
}

@immutable
class CaDocket {
  const CaDocket({required this.wire, required this.loadTenths, required this.feederBn});
  final CaWire wire;

  /// The pull the job needs, in tenths of a tonne (15 = 1.5 t).
  final int loadTenths;
  final String feederBn;

  String get loadBn => '${loadTenths ~/ 10}.${loadTenths % 10}';
}

@immutable
class CaRoundDeal {
  const CaRoundDeal({required this.kind, required this.docket, required this.items});
  final CaKind kind;
  final CaDocket docket;
  final List<CaItem> items;

  /// The puller's plate is below the job's pull.
  bool underRated(CaItem i) => i.kind == CaKind.puller && i.tons! * 10 < docket.loadTenths;

  /// The grip is made for another conductor.
  bool wrongWire(CaItem i) => i.kind == CaKind.grip && i.wire != docket.wire;

  bool fits(CaItem i) => i.kind == kind && i.flaw == CaFlaw.none && !underRated(i) && !wrongWire(i);

  /// Rated / made right (sound or not): the one whose state decides the hold.
  bool matches(CaItem i) => i.kind == kind && !underRated(i) && !wrongWire(i);

  /// Nothing on the rack is right: the job must be held.
  bool get noneFits => !items.any(fits);
}

/// What the careless coworker pushes.
enum CaPush { rating, grip }

@immutable
class CaDeal {
  const CaDeal({required this.rounds, required this.callRound});
  final List<CaRoundDeal> rounds;

  /// The docket on which the careless coworker peeps in (or the next one).
  final int callRound;
}

abstract final class M2ComeAlongLines {
  static const title = 'সঠিক কাম-অ্যালং';
  static const intro = 'তার টানার কাজ! ডকেট দেখে ঠিক কাম-অ্যালং আর গ্রিপ বাছুন — হাতে নিয়ে যাচাই করে।';
  static const rounds = ['প্রথম', 'দ্বিতীয়', 'শেষ'];
  static const askPuller = 'ডকেটে কত টন টান? কোন কাম-অ্যালং?';
  static const askGrip = 'ডকেটে কোন তার? কোন গ্রিপটা?';
  static String ask(CaKind k) => k == CaKind.puller ? askPuller : askGrip;
  static const inspectPuller = 'হাত বুলিয়ে হুক, ল্যাচ, র‍্যাচেট আর কেবিল দেখুন। নেবেন?';
  static const inspectGrip = 'হাত বুলিয়ে গ্রিপের দাঁত আর আই দেখুন। নেবেন?';
  static String inspect(CaKind k) => k == CaKind.puller ? inspectPuller : inspectGrip;
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const wireWord = 'তার';
  static const loadWord = 'টান';
  static const tonWord = 'টন';
  static String line(CaDocket d) => 'তার: ${d.wire.bn} · টান ${d.loadBn} টন';
  static String job(CaDocket d) => 'তার টানা · ${d.feederBn}';
  static const toolLabel = 'যন্ত্র';
  static const handLabel = 'যন্ত্র হাতে';
  static const take = 'এটাই নিন';
  static const putBack = 'ফেরত রাখুন';
  static const hold = 'কোনোটাই ঠিক নয় — কাজ স্থগিত';
  static const rejected = 'বাতিল';

  // The reasons (lesson 2.4): the right ones fit what this docket and this
  // rack had. Every card is about 30–43 letters, so none stands out by its length.
  static const pullerAsk = 'কেন এই কাম-অ্যালংটা নিলেন?';
  static const gripAsk = 'কেন এই গ্রিপটা নিলেন?';
  static const holdAsk = 'কেন কাজ স্থগিত করলেন?';
  static String pullerMatch(CaDocket d) => 'ডকেটে টান ${d.loadBn} টন, প্লেটে 2 টন লেখা';
  static const pullerSound = [
    'প্লেটের ক্ষমতা কাজের টানের চেয়ে বেশি',
    'হুক-ল্যাচ, র‍্যাচেট আর কেবিল সব ঠিক',
  ];
  static const pullerMyths = [
    'ছোটটাতেও হ্যান্ডেলে পাইপ দিলে চলে',
    'প্লেটে যা-ই লেখা থাক, সব পুলার এক',
    'হালকা যন্ত্র বইতে সুবিধা, তাই নিলাম',
    'রং নতুন দেখে মনে হলো ভালো যন্ত্র',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিলাম',
    'একটু ঝাঁকুনি দিয়ে টানলেই কাজ হয়ে যায়',
  ];
  static List<String> pullerRight(CaDocket d) => [pullerMatch(d), ...pullerSound];
  static List<String> pullerWrong(CaDocket d) => pullerMyths;

  static String gripMatch(CaWire w) => 'ডকেটের তার ${w.bn}, গ্রিপের লেবেলেও তাই';
  static const gripSound = [
    'দাঁত পরিষ্কার আর ধারালো, তার পিছলাবে না',
    'তারের ধরন মিলেছে, দাঁতও পরিষ্কার-ধারালো',
  ];
  static const gripMyths = [
    'গ্রিপ তো গ্রিপই, যেকোনো তারেই চলে যায়',
    'দাঁতে তেল থাকলে আরও ভালো কামড়ায়',
    'ACSR আর AAAC-তে আসলে কোনো তফাৎ নেই',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিলাম',
    'বড় গ্রিপ হলে যেকোনো তারই ধরে ফেলে',
  ];
  static List<String> gripRight(CaWire w) => [gripMatch(w), ...gripSound];

  /// The other conductors' matches (true elsewhere, not here) and the myths.
  static List<String> gripWrong(CaWire w) => [
        for (final x in CaWire.values)
          if (x != w) gripMatch(x),
        ...gripMyths,
      ];

  static String flawWhy(CaRoundDeal r, CaFlaw f) {
    final who = r.kind == CaKind.puller ? '2 টনেরটার' : 'মানানসই গ্রিপের';
    return switch (f) {
      CaFlaw.latch => 'একমাত্র $who হুকের ল্যাচ ভাঙা',
      CaFlaw.pawl => 'একমাত্র $who র‍্যাচেটের পল ভাঙা',
      CaFlaw.rope => 'একমাত্র $who কেবিলে গিঁট পড়েছে',
      CaFlaw.grease => 'একমাত্র $who দাঁতে তেল-ময়লা',
      _ => 'একমাত্র $who দাঁত ক্ষয়ে ভোঁতা',
    };
  }

  static const holdSound = [
    'ঠিক মাপের অক্ষত যন্ত্র নেই, তাই টান নয়',
    'যন্ত্র না মিললে টান নয়, আগে জানাই',
  ];
  static const holdExcuses = [
    'শাটডাউনের সময় কম, তাই কাজটা বাদ দিলাম',
    'যন্ত্র বইতে ভারী লাগছিল, তাই নিলাম না',
    'স্টোরকিপার বকবে, তাই কিছুই নিইনি',
    'রোদ বেশি, দুপুরে কাজ না করাই ভালো',
    'সুপারভাইজার না এলে কাজ শুরুই হয় না',
  ];

  static CaFlaw _heldFlaw(CaRoundDeal r) => r.items.firstWhere(r.matches, orElse: () => const CaItem.puller(id: '-', tons: 0)).flaw;

  /// Why the job was held: the rule, and — only when the player has seen it
  /// ([flawKnown]: found by hand, or shown on a card) — what the right tool had.
  static List<String> holdRight(CaRoundDeal r, {required bool flawKnown}) {
    final f = _heldFlaw(r);
    return [if (flawKnown && f != CaFlaw.none) flawWhy(r, f), ...holdSound];
  }

  /// The excuses, and (when the fault is known) the faults it did not have.
  static List<String> holdWrong(CaRoundDeal r, {required bool flawKnown}) {
    final f = _heldFlaw(r);
    return [
      if (flawKnown && f != CaFlaw.none)
        for (final x in r.kind == CaKind.puller ? _pullerFlaws : _gripFlaws)
          if (x != f) flawWhy(r, x),
      ...holdExcuses,
    ];
  }

  /// The careless coworker (level 1's rival; these lines on device TTS until recorded).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerRating = CoworkerScript(
    line: 'বড় তার? ছোটটাতেই হবে! এক টনেরটা নাও, হ্যান্ডেলে পাইপ গুঁজলেই টানবে।',
    exitLine: coworkerExit,
    right: ['না — প্লেটের সীমার বেশি টান নয়', 'হ্যান্ডেলে পাইপ গুঁজে জোর নয়', 'টানের চেয়ে কম টনেরটা নেব না'],
    wrong: [
      'ঠিক বলেছ, এক টনেরটাই নিয়ে যাই',
      'পাইপ গুঁজলে তো জোর এমনিই বাড়ে',
      'একবার এক টনেরটায় চালিয়ে নিই',
      'টন-টন সব এক, যেটা হোক নিয়ে নিই',
      'হালকাটাই নিই, বয়ে নিতে সুবিধা',
    ],
    asks: ['ও বলছে এক টনেরটাতেই হবে। আপনি কী করবেন?', 'কম টনেরটা নেবেন, না প্লেট মিলিয়ে?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerGrip = CoworkerScript(
    line: 'গ্রিপ তো গ্রিপই! ACSR আর AAAC-তে আর কী তফাৎ? যেটা হাতে আছে লাগাও।',
    exitLine: coworkerExit,
    right: ['না — তারের ধরন মিলিয়ে গ্রিপ নেব', 'ভুল গ্রিপে তারের স্ট্র্যান্ড কাটে', 'লেবেল না মিললে গ্রিপ নেব না'],
    wrong: [
      'ঠিক, যেটা হাতে আছে সেটাই নিই',
      'গ্রিপ তো গ্রিপই, কী আর তফাৎ',
      'একবার ভুল গ্রিপেই চালিয়ে নিই',
      'সবাই তো যেটা পায় সেটাই নেয়',
      'তার শক্ত, একটু ঘষায় কিছু হয় না',
    ],
    asks: ['ও বলছে যেকোনো গ্রিপেই চলবে। আপনি কী করবেন?', 'যেকোনো গ্রিপ, না তার মিলিয়ে?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(CaPush p) => p == CaPush.rating ? coworkerRating : coworkerGrip;

  /// His new lines (not yet in his recorded voice).
  static List<String> get toRecord => [coworkerRating.line, coworkerGrip.line];

  static const callHeld = 'ঠিক! প্লেট, লেবেল আর অবস্থা মিলিয়েই যন্ত্র।';
  static const aside = 'ঠিক — ভাঙা যন্ত্র বাতিল।';
  static const allSet = 'কাম-অ্যালং বাছাইয়ে পাকা হাত! প্লেট, লেবেল আর অবস্থা — সবই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — প্লেটের টন, গ্রিপের লেবেল আর অবস্থা দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtRating = 'প্লেটের টন আর কাজের টান মিলিয়েছেন';
  static const caughtGrip = 'তারের ধরন মিলিয়ে গ্রিপ নিয়েছেন';
  static const caughtHold = 'ঠিক যন্ত্র না পেয়ে কাজ স্থগিত';
  static const caughtFlaw = 'ভাঙা যন্ত্র বাতিল';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
}

abstract final class M2ComeAlongMistakes {
  static const _puller = 'assets/safety/library/tools/Hand_Ratchet_Cable_Puller.webp';
  static const _grip = 'assets/safety/library/tools/come_along_clamp.webp';

  static const underRated = DoMistake(
    key: '2.4/comealong/under-rated',
    textBn: 'প্লেটের ক্ষমতা কাজের টানের চেয়ে কম — কম ক্ষমতার পুলার লোডের তলায় ভেঙে যেতে পারে, আর পুরো সিস্টেম স্লিং-শটের মতো ছিটকে আসে। প্লেটের সীমার বাইরে লোড কখনো নয়।',
    art: _puller,
    deadly: true,
    lessonPoint: 0,
  );
  static const latch = DoMistake(
    key: '2.4/comealong/latch',
    textBn: 'হুকের সেফটি ল্যাচ ভাঙা — টানের মধ্যে হুক খুলে যেতে পারে। ব্যবহারের আগে হুক আর ল্যাচ দেখুন। এমন যন্ত্র বাতিল।',
    art: _puller,
    lessonPoint: 0,
  );
  static const pawl = DoMistake(
    key: '2.4/comealong/pawl',
    textBn: 'র‍্যাচেটের পল ভাঙা — র‍্যাচেট লক হবে না, টান হঠাৎ ছুটে যেতে পারে। ব্যবহারের আগে র‍্যাচেট দেখুন। এমন যন্ত্র বাতিল।',
    art: _puller,
    lessonPoint: 0,
  );
  static const rope = DoMistake(
    key: '2.4/comealong/rope',
    textBn: 'কেবিলে গিঁট আর ছেঁড়া স্ট্র্যান্ড — লোডে ছিঁড়ে যেতে পারে। ব্যবহারের আগে পুরো কেবিল দেখুন। এমন যন্ত্র বাতিল।',
    art: _puller,
    lessonPoint: 0,
  );
  static const grease = DoMistake(
    key: '2.4/comealong/grease',
    textBn: 'গ্রিপের দাঁতে তেল-ময়লা — কার্যকারিতা কমে, গ্রিপ পিছলে যেতে পারে। দাঁত পরিষ্কার চাই; এমন গ্রিপে টান নয়।',
    art: _grip,
    lessonPoint: 0,
  );
  static const teeth = DoMistake(
    key: '2.4/comealong/worn-teeth',
    textBn: 'গ্রিপের দাঁত ক্ষয়ে ভোঁতা — তার ঠিকমতো কামড়ে ধরবে না, পিছলে যেতে পারে। দাঁত ধারালো চাই। এমন গ্রিপ বাতিল।',
    art: _grip,
    lessonPoint: 0,
  );
  static const wrongGrip = DoMistake(
    key: '2.4/comealong/wrong-grip',
    textBn: 'ভুল গ্রিপ — ACSR, AAAC আর ইনসুলেটেড তারের জন্য আলাদা গ্রিপ। ভুল গ্রিপে স্ট্র্যান্ড কেটে কন্ডাক্টর চিরস্থায়ীভাবে ক্ষতিগ্রস্ত হয়। ডকেটের তার আর গ্রিপের লেবেল মিলিয়ে নিন।',
    art: _grip,
    lessonPoint: 0,
  );
  static const heldWhenRight = DoMistake(
    key: '2.4/comealong/held-when-right',
    textBn: 'ঠিক যন্ত্রটা র‍্যাকেই ছিল — প্লেটের টন, গ্রিপের লেবেল আর অবস্থা ভালো করে দেখুন।',
    art: _puller,
    lessonPoint: 0,
  );
  static DoMistake flaw(CaFlaw f) => switch (f) {
        CaFlaw.latch => latch,
        CaFlaw.pawl => pawl,
        CaFlaw.rope => rope,
        CaFlaw.grease => grease,
        _ => teeth,
      };
  static const all = [underRated, latch, pawl, rope, grease, teeth, wrongGrip, heldWhenRight];
}

/// A fresh rack each play: dockets, decoys, flaws, rack order and the
/// coworker's moment vary.
CaDeal dealComeAlong(math.Random rng) {
  var n = 0;
  CaFlaw pf() => _pullerFlaws[rng.nextInt(_pullerFlaws.length)];
  CaFlaw gf() => _gripFlaws[rng.nextInt(_gripFlaws.length)];
  CaItem puller(int t, [CaFlaw f = CaFlaw.none]) => CaItem.puller(id: 'ca${n++}', tons: t, flaw: f);
  CaItem grip(CaWire w, [CaFlaw f = CaFlaw.none]) => CaItem.grip(id: 'ca${n++}', wire: w, flaw: f);
  CaWire wire() => CaWire.values[rng.nextInt(CaWire.values.length)];
  // A job above one tonne (so the 1-tonne puller is too small) for the pullers.
  int heavy() => const [12, 15, 18][rng.nextInt(3)];
  CaDocket docket(CaWire w, int load) => CaDocket(wire: w, loadTenths: load, feederBn: M2ComeAlongLines.feeders[rng.nextInt(M2ComeAlongLines.feeders.length)]);
  List<CaItem> others(CaWire w) => [for (final x in CaWire.values) if (x != w) grip(x)];

  // 1: the come-along — the right 2 t, the 1 t (too small), a damaged one.
  final r1 = [puller(2), puller(1), puller(rng.nextBool() ? 2 : 1, pf())]..shuffle(rng);
  // 2: the grip — the right one, its damaged twin, the two other conductors'.
  final w2 = wire();
  final r2 = [grip(w2), grip(w2, gf()), ...others(w2)]..shuffle(rng);
  // 3: nothing fits — the right one is damaged.
  final last = rng.nextBool() ? CaKind.puller : CaKind.grip;
  final w3 = wire();
  final r3 = (last == CaKind.puller ? [puller(2, pf()), puller(1), puller(1, pf())] : [grip(w3, gf()), ...others(w3)])..shuffle(rng);
  final rounds = [
    CaRoundDeal(kind: CaKind.puller, docket: docket(wire(), heavy()), items: r1),
    CaRoundDeal(kind: CaKind.grip, docket: docket(w2, heavy()), items: r2),
    CaRoundDeal(kind: last, docket: docket(w3, heavy()), items: r3),
  ];
  return CaDeal(rounds: rounds, callRound: rng.nextInt(rounds.length));
}

/// What the careless coworker can push on docket [r] now: the too-small
/// puller, or a grip for another conductor — only one still on the rack.
CaPush? caPushFor(CaRoundDeal r, Set<String> rejected) {
  final left = r.items.where((x) => !rejected.contains(x.id));
  if (r.kind == CaKind.puller) return left.any(r.underRated) ? CaPush.rating : null;
  return left.any(r.wrongWire) ? CaPush.grip : null;
}

enum CaVerdict { right, slip, deadly }

@immutable
class CaOutcome {
  const CaOutcome(this.verdict, {this.mistake});
  final CaVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class M2ComeAlongRun {
  M2ComeAlongRun(this.deal);
  final CaDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;

  /// This docket is decided (the right tool taken, or the job held).
  bool shown = false;

  /// Tools set aside on this docket.
  final Set<String> rejected = {};

  /// Tools on this docket whose flaw the player has seen.
  final Set<String> spotted = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  CaRoundDeal get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Takes [item] for the job.
  CaOutcome take(CaItem item) {
    if (ended || shown || rejected.contains(item.id)) return const CaOutcome(CaVerdict.slip);
    final r = current;
    if (r.underRated(item)) return _deadly(M2ComeAlongMistakes.underRated);
    if (r.wrongWire(item)) {
      slips++;
      return const CaOutcome(CaVerdict.slip, mistake: M2ComeAlongMistakes.wrongGrip);
    }
    if (item.flaw != CaFlaw.none) {
      slips++;
      rejected.add(item.id);
      spotted.add(item.id);
      return CaOutcome(CaVerdict.slip, mistake: M2ComeAlongMistakes.flaw(item.flaw));
    }
    _tag(r.kind == CaKind.puller ? M2ComeAlongLines.caughtRating : M2ComeAlongLines.caughtGrip);
    shown = true;
    return const CaOutcome(CaVerdict.right);
  }

  /// Listened to the careless coworker: the too-small puller is deadly; the
  /// wrong grip is a slip.
  CaOutcome heed(CaPush p) {
    if (p == CaPush.rating) return _deadly(M2ComeAlongMistakes.underRated);
    slips++;
    return const CaOutcome(CaVerdict.slip, mistake: M2ComeAlongMistakes.wrongGrip);
  }

  /// The player's hand found [item]'s flaw in the close look.
  void spot(CaItem item) {
    if (item.flaw != CaFlaw.none) spotted.add(item.id);
  }

  /// The tool that would be right here is damaged, and the player has seen how.
  bool get flawKnown => current.items.any((x) => current.matches(x) && x.flaw != CaFlaw.none && spotted.contains(x.id));

  /// Puts [item] back: a damaged tool whose flaw the player found goes aside
  /// (true); anything else goes back on the rack (false) — putting back never
  /// tells which tools are damaged. Never costs anything.
  bool putBack(CaItem item) {
    if (ended || shown || rejected.contains(item.id)) return false;
    if (!spotted.contains(item.id)) return false;
    rejected.add(item.id);
    _tag(M2ComeAlongLines.caughtFlaw);
    return true;
  }

  /// "কোনোটাই ঠিক নয় — কাজ স্থগিত".
  CaOutcome holdJob() {
    if (ended || shown) return const CaOutcome(CaVerdict.slip);
    if (!current.noneFits) {
      slips++;
      return const CaOutcome(CaVerdict.slip, mistake: M2ComeAlongMistakes.heldWhenRight);
    }
    _tag(M2ComeAlongLines.caughtHold);
    shown = true;
    return const CaOutcome(CaVerdict.right);
  }

  /// The next docket (after the reason).
  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    shown = false;
  }

  CaOutcome _deadly(DoMistake m) {
    deadly = m;
    return CaOutcome(CaVerdict.deadly, mistake: m);
  }
}

@immutable
class M2ComeAlongPack {
  const M2ComeAlongPack({required this.id, required this.titleBn, this.quickMs = 80000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2ComeAlongPack24 = M2ComeAlongPack(id: 'do_2_4_a', titleBn: M2ComeAlongLines.title);
const m2ComeAlongPacks = {'do_2_4_a': m2ComeAlongPack24};

// ============================================================================
// Page
// ============================================================================

class M2ComeAlongPage extends StatefulWidget {
  const M2ComeAlongPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2ComeAlongPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2ComeAlongPage> createState() => _M2ComeAlongPageState();
}

class _M2ComeAlongPageState extends State<M2ComeAlongPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _CaRunPage(
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

class _CaRunPage extends ConsumerStatefulWidget {
  const _CaRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2ComeAlongPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_CaRunPage> createState() => _CaRunPageState();
}

class _CaRunPageState extends ConsumerState<_CaRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M2ComeAlongRun _run = M2ComeAlongRun(dealComeAlong(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;

  /// The guide's full-screen intro is up; the game starts when it is done.
  var _intro = true;
  int _chain = 0;

  /// The tool in the trainee's hands (the close look), and the one packed.
  CaItem? _held;
  String? _packed;
  var _docketOpen = false;
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
  CaPush _push = CaPush.rating;

  /// The trainee's pose (moves a few seconds after each change).
  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;

  /// A deadly move: the van freezes grey, the consequence plays in colour.
  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  // ---- voice (never holds the player) -------------------------------------------

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

  String get _task => _held != null ? M2ComeAlongLines.inspect(_run.current.kind) : M2ComeAlongLines.ask(_run.current.kind);
  String get _askLine => M2ComeAlongLines.ask(_run.current.kind);

  // ---- flow -----------------------------------------------------------------------

  /// After the guide's intro: the clock runs and he gives the first task.
  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([_askLine]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || _run.shown || _freeze;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  /// A tool comes off the rack into the trainee's hands.
  void _pick(CaItem r, Offset origin) {
    // Taking another tool while he is still talking refuses him too.
    if (coworkerOpen && !coworkerChoiceUp && !_isPushed(r)) unawaited(answerCoworker(true, origin, direct: true));
    if (_blocked || coworkerOpen || _held != null || _docketOpen || _run.rejected.contains(r.id) || _packed == r.id) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.45, muted: false));
    _hush();
    setState(() {
      _held = r;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([M2ComeAlongLines.inspect(r.kind)]));
  }

  bool _isPushed(CaItem r) => _push == CaPush.rating ? _run.current.underRated(r) : _run.current.wrongWire(r);

  /// A flaw came into view under the hand.
  void _found() {
    final r = _held;
    if (r != null) _run.spot(r);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/tock.wav', volume: 0.6, muted: false));
  }

  void _putBack() {
    final r = _held;
    if (r == null || _blocked) return;
    final aside = _run.putBack(r);
    HapticFeedback.selectionClick();
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    if (aside) {
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([M2ComeAlongLines.aside, _askLine], mood: GuideMood.glad));
    } else {
      if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
      unawaited(_sayChain([_askLine]));
    }
  }

  void _take(Offset origin) {
    final r = _held;
    if (r == null || _blocked) return;
    setState(() => _held = null);
    final o = _run.take(r);
    switch (o.verdict) {
      case CaVerdict.right:
        HapticFeedback.lightImpact();
        if (!_muted) {
          unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
          unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.5, muted: false));
        }
        setState(() {
          _packed = r.id;
          _setMode(LinemanMode.cheer);
        });
        final d = _run.current.docket;
        if (r.kind == CaKind.puller) {
          _ask(15, () => dealChoices(M2ComeAlongLines.pullerRight(d), M2ComeAlongLines.pullerWrong(d), widget.rng), M2ComeAlongLines.pullerAsk);
        } else {
          _ask(15, () => dealChoices(M2ComeAlongLines.gripRight(d.wire), M2ComeAlongLines.gripWrong(d.wire), widget.rng), M2ComeAlongLines.gripAsk);
        }
      case CaVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, origin));
      case CaVerdict.deadly:
        // The tool stays in his hands (off the rack) while the scene freezes.
        setState(() => _packed = r.id);
        unawaited(_deadly(o.mistake!));
    }
  }

  void _holdJob(Offset origin) {
    if (_blocked || coworkerOpen || _held != null || _docketOpen) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == CaVerdict.right) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      final r = _run.current;
      final known = _run.flawKnown;
      _ask(
        20,
        () => dealChoices(M2ComeAlongLines.holdRight(r, flawKnown: known), M2ComeAlongLines.holdWrong(r, flawKnown: known), widget.rng),
        M2ComeAlongLines.holdAsk,
      );
      return;
    }
    setState(() => _setMode(LinemanMode.worried));
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  /// A right move: the ◆ wait on the table, then "কেন …?".
  void _ask(int points, List<ChoiceOption> Function() deal, String question) {
    putOnTable(points);
    final round = _run.round;
    unawaited(askReason(deal: deal, question: question, stillValid: () => _run.round == round && !_ended));
  }

  /// The next docket (or the result) — by itself, after the reason.
  void _nextRound() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _packed = null;
      _setMode(LinemanMode.idle);
    });
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([_askLine]));
  }

  void _openDocket() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: false));
    setState(() => _docketOpen = true);
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
  void onReasonPaid() => _nextRound();

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M2ComeAlongLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    if (_blocked || _held != null || _docketOpen) return false;
    // Nothing left on the rack to push: he tries again later (the next docket).
    final push = caPushFor(_run.current, _run.rejected);
    if (push == null) return false;
    _push = push;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Took what he pushed: the too-small puller (deadly), or the wrong grip (a slip).
      final o = _run.heed(_push);
      if (o.verdict == CaVerdict.deadly) {
        await _deadly(o.mistake!);
      } else {
        setState(() => _setMode(LinemanMode.worried));
        await _slip(o.mistake!, origin);
      }
      return;
    }
    _run.caught.add(M2ComeAlongLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([M2ComeAlongLines.callHeld, _askLine], mood: GuideMood.glad);
    }());
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M2ComeAlongLines.tapWhy[_nudgeN++ % M2ComeAlongLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    unawaited(_sayChain([line]));
  }

  // ---- mistakes ---------------------------------------------------------------------

  /// The third small mistake: the level fails and the lesson card insists.
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    unawaited(bookMistake(ref, widget.ctx, m));
    await recordStrikeOut(widget.ctx, percent: _run.percent, runScore: _runScore);
    if (mounted) setState(() {});
  }

  Future<void> _slip(DoMistake m, Offset origin) async {
    if (strike(m)) {
      await _struckOut(m);
      return;
    }
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('ca/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A deadly move: the van freezes grey, the snap plays in colour,
  /// then the card.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _held = null;
      _docketOpen = false;
      _setMode(LinemanMode.worried);
      _freeze = true;
    });
    await frozen.future;
    if (!mounted) return;
    if (!_muted) unawaited(ZlFx.cue('sounds/accident.wav', volume: 0.9, muted: false));
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('ca/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M2ComeAlongLines.deadlyWord : M2ComeAlongLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(LinemanMode.idle);
        });
        unawaited(_sayChain([_askLine]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
  }

  // ---- score and result ---------------------------------------------------------------

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
    await _say(!_run.passed ? M2ComeAlongLines.fail : (_quickBonus ? M2ComeAlongLines.quick : M2ComeAlongLines.allSet),
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

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = RodVanGeo(m.height);
    final r = _run.current;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final aside = [for (final x in r.items) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_docketOpen;
    return [
      Positioned.fill(
        key: const ValueKey('van'),
        child: ColorFiltered(colorFilter: grey, child: RepaintBoundary(child: CustomPaint(painter: RodVanPainter(geo)))),
      ),
      // The docket on the left door (tap to read it close).
      Positioned.fromRect(
        key: ValueKey('docket-${_run.round}'),
        rect: geo.docket,
        child: ColorFiltered(
          colorFilter: grey,
          child: _DocketSheet(docket: r.docket, quiet: quiet, onTap: _openDocket),
        ),
      ),
      // The rack: one slot per tool (its slot stays, empty, once it is gone).
      for (var i = 0; i < r.items.length; i++)
        Positioned.fromRect(
          key: ValueKey('slot-${_run.round}-$i'),
          rect: geo.slot(i, r.items.length),
          child: ColorFiltered(
            colorFilter: grey,
            child: DoDealIn(
              index: i,
              quiet: quiet,
              muted: true,
              child: _RackTool(
                item: r.items[i],
                gone: _run.rejected.contains(r.items[i].id) || _packed == r.items[i].id || _held?.id == r.items[i].id,
                enabled: canPick,
                onTake: (at) => _pick(r.items[i], at),
              ),
            ),
          ),
        ),
      // Tools set aside hang on the right door, tagged বাতিল.
      for (var i = 0; i < aside.length && i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: ColorFiltered(colorFilter: grey, child: _AsideTool(item: aside[i], quiet: quiet)),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: ColorFiltered(
          colorFilter: grey,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final holdUp = playing && _held == null && !_docketOpen && _card == null && !deckUp && !_run.shown && !coworkerOpen;
    final held = _held;
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
              labels: M2ComeAlongLines.rounds,
              done: {for (var i = 0; i < math.min(_run.round, 3); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (holdUp)
                Positioned(
                  key: const ValueKey('hud-hold'),
                  left: 12,
                  right: 128,
                  bottom: pad.bottom + 18,
                  child: _HoldButton(onTapUp: (d) => _holdJob(d.globalPosition)),
                ),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  item: held,
                  docket: _run.current.docket,
                  quiet: quiet,
                  onFound: _found,
                  onTake: _take,
                  onPutBack: _putBack,
                ),
              if (_docketOpen && playing)
                _DocketZoom(
                  key: const ValueKey('docket-zoom'),
                  docket: _run.current.docket,
                  quiet: quiet,
                  onClose: () => setState(() => _docketOpen = false),
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
              if (playing && _card == null && !_docketOpen)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
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
                          unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: _card!.lessonPoint, muted: _muted));
                        },
                  onGo: _cardGo,
                ),
              if (struckOut)
                StruckOutCard(
                  key: const ValueKey('struck'),
                  mistake: strikeOutBy!,
                  lessonId: widget.ctx.lessonId,
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: quiet ? 300 : 2200,
                  consequence: _CaFlash(quiet: quiet),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: M2ComeAlongLines.intro,
                  alarm: 'sounds/van_arrive.wav',
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, point: 0, muted: _muted)),
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

const _paper = Color(0xFFF7F1E1);
const _ink = Color(0xFF1E2228);
const _brown = Color(0xFF8C6A2A);
const _grey = Color(0xFF5A6478);

/// Behind the tool in the close look (and the wash over what is not looked at yet).
const _bench = Color(0xFF26303B);

/// The docket sheet on the clipboard (design px): the conductor and the pull
/// big, the rest small — tap it to read it close.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.docket, required this.quiet, required this.onTap});
  final CaDocket docket;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: quiet ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Transform.translate(offset: Offset(0, -30 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(M2ComeAlongLines.docket, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
                    Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
                    Text(M2ComeAlongLines.wireWord, style: bangla(fontSize: 7, fontWeight: FontWeight.w700, color: _grey, height: 1.1)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(docket.wire.bn, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: _ink, height: 1.15)),
                    ),
                    const SizedBox(height: 2),
                    Text(M2ComeAlongLines.loadWord, style: bangla(fontSize: 7, fontWeight: FontWeight.w700, color: _grey, height: 1.1)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('${docket.loadBn} ${M2ComeAlongLines.tonWord}', style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: _ink, height: 1.15)),
                    ),
                    const SizedBox(height: 2),
                    Text(docket.feederBn, maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w700, color: _grey, height: 1.2)),
                    const Spacer(),
                    for (var i = 0; i < 2; i++) Container(height: 0.8, color: const Color(0x33000000), margin: const EdgeInsets.only(top: 3, right: 10)),
                  ],
                ),
              ),
            ),
            // The clip.
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 28,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD9DEE2), Color(0xFF8D969E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(3),
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

/// The docket held up close (tap anywhere to put it back on the door).
class _DocketZoom extends StatelessWidget {
  const _DocketZoom({super.key, required this.docket, required this.quiet, required this.onClose});
  final CaDocket docket;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: const Color(0xB3050A16),
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
              child: Container(
                width: 280,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB59B62), width: 1.5),
                  boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: _brown, size: 22),
                        const SizedBox(width: 8),
                        Text(M2ComeAlongLines.docket, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text(M2ComeAlongLines.line(docket), style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(M2ComeAlongLines.job(docket), style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: _grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tool drawn upright as it hangs: the come-along by its anchor hook, the
/// grip by its eye (from the top of the box).
class _Hanging extends StatelessWidget {
  const _Hanging({required this.item});
  final CaItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final grip = item.kind == CaKind.grip;
        final len = grip ? math.min(box.maxHeight, box.maxWidth * 2.6) : box.maxHeight;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: box.maxWidth,
            height: len,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RotatedBox(quarterTurns: grip ? 3 : 1, child: CustomPaint(painter: CaToolPainter(item))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A tool hanging on the rack (design px). At this distance its plate or
/// label is too small to read and its flaws do not show. Tap it, or pull it
/// down off the rail, to take it in hand.
class _RackTool extends StatefulWidget {
  const _RackTool({required this.item, required this.gone, required this.enabled, required this.onTake});
  final CaItem item;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  State<_RackTool> createState() => _RackToolState();
}

class _RackToolState extends State<_RackTool> {
  double _pull = 0;
  Offset _at = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (widget.gone) return Semantics(label: M2ComeAlongLines.toolLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: M2ComeAlongLines.toolLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.enabled ? (d) => widget.onTake(d.globalPosition) : null,
        onVerticalDragStart: widget.enabled ? (d) => _at = d.globalPosition : null,
        onVerticalDragUpdate: widget.enabled
            ? (d) {
                _at = d.globalPosition;
                setState(() => _pull = (_pull + d.delta.dy).clamp(0.0, 70.0));
              }
            : null,
        onVerticalDragEnd: widget.enabled
            ? (_) {
                final out = _pull > 26;
                setState(() => _pull = 0);
                if (out) widget.onTake(_at);
              }
            : null,
        child: Transform.translate(
          offset: Offset(0, _pull),
          child: _Hanging(item: item),
        ),
      ),
    );
  }
}

/// A tool set aside on the right door, tagged বাতিল.
class _AsideTool extends StatelessWidget {
  const _AsideTool({required this.item, required this.quiet});
  final CaItem item;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(-60 * (1 - t), 0), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Transform.rotate(
        angle: -0.06,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(child: _Hanging(item: item)),
            Positioned(
              top: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
                child: Text(M2ComeAlongLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The close look, hands on: the tool held up big, its plate or label
/// readable; run a finger along the top (hook and latch, ratchet and pawl —
/// or the grip's teeth) and along the bottom (the wire rope — or the grip's
/// eye): a flaw shows only where the hand has been. Then take it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.item,
    required this.docket,
    required this.quiet,
    required this.onFound,
    required this.onTake,
    required this.onPutBack,
  });
  final CaItem item;
  final CaDocket docket;
  final bool quiet;
  final VoidCallback onFound;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _top = {};
  final Set<int> _low = {};
  Offset? _hand;
  var _found = false;

  void _touch(Offset p, Size s) {
    final top = p.dy < s.height * 0.52;
    final b = caBin(CaToolPainter.uAt(s, widget.item.kind, p.dx));
    final set = top ? _top : _low;
    final before = set.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kCaBins) set.add(x);
    }
    final grew = set.length != before;
    if (!_found && CaToolPainter.flawSeen(widget.item, _top, _low)) {
      _found = true;
      widget.onFound();
    }
    if (grew || _hand != p) setState(() => _hand = p);
  }

  Widget _closeUp(CaItem item) => LayoutBuilder(
        builder: (context, box) {
          final s = Size(box.maxWidth, box.maxHeight);
          final plate = CaToolPainter.plate(s, item.kind);
          final tool = CaToolPainter.box(s, item.kind);
          return Semantics(
            label: M2ComeAlongLines.handLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _touch(d.localPosition, s),
              onPanUpdate: (d) => _touch(d.localPosition, s),
              onPanEnd: (_) => setState(() => _hand = null),
              onPanCancel: () => setState(() => _hand = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: CaToolPainter(item, seenTop: _top, seenLow: _low, veil: _bench)),
                  ),
                  // The plate / label, readable up close.
                  Positioned(
                    left: plate.left - 6,
                    top: item.kind == CaKind.puller ? plate.top - 30 : plate.bottom + 6,
                    child: IgnorePointer(child: _Tag(text: item.tag, plate: item.kind == CaKind.puller)),
                  ),
                  // Where to run the hand: along the top, along the bottom.
                  if (_top.isEmpty) _Puck(at: Offset(tool.left + tool.width * 0.08, s.height * 0.3)),
                  if (_low.isEmpty) _Puck(at: Offset(tool.left + tool.width * 0.6, s.height * 0.78)),
                  if (_hand != null) _Puck(at: _hand!, live: true),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: widget.quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Transform.translate(
              offset: Offset(0, 80 * (1 - t)),
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The docket, clipped beside the tool.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFB59B62)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: _brown, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('${M2ComeAlongLines.docket} · ${M2ComeAlongLines.line(widget.docket)}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AspectRatio(
                    aspectRatio: 2.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF3A4654), _bench],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 30, 10, 4),
                        child: _closeUp(item),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: DoBigButton(label: M2ComeAlongLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                      const SizedBox(width: 12),
                      Expanded(child: DoBigButton(label: M2ComeAlongLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
                    ],
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

/// The printed plate (orange-red, as on the come-along) or the grip's
/// stamped label.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.plate});
  final String text;
  final bool plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: plate ? const Color(0xFFE5532D) : const Color(0xFFF2D27A),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: plate ? const Color(0xFF3A1B12) : const Color(0xFF7A5A0E), width: 1.4),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: plate ? Colors.white : _ink, height: 1.1)),
    );
  }
}

/// The deadly consequence: an under-rated come-along snaps under the
/// conductor's pull; the rig whips back like a sling-shot.
class _CaFlash extends StatelessWidget {
  const _CaFlash({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth - 40, 340.0);
        final h = math.min(w * 1.0, box.maxHeight * 0.7);
        return Align(
          alignment: const Alignment(0, -0.25),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1700),
            builder: (_, t, _) {
              final pop = (t * 6).clamp(0.0, 1.0);
              return Opacity(
                opacity: pop,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * pop,
                  child: Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SlmColors.danger, width: 2.5),
                      boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CustomPaint(painter: CaSnapPainter(t: t), size: Size(w, h)),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
/// "কোনোটাই ঠিক নয় — কাজ স্থগিত", readable on the road.
class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1A33),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.85), width: 1.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pan_tool_rounded, size: 18, color: SlmColors.warning),
              const SizedBox(width: 8),
              Flexible(
                child: Text(M2ComeAlongLines.hold,
                    textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gloved hand's mark: where to slide (still), or under the finger.
class _Puck extends StatelessWidget {
  const _Puck({required this.at, this.live = false});
  final Offset at;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final r = live ? 22.0 : 17.0;
    return Positioned(
      left: at.dx - r,
      top: at.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? const Color(0x55FF851B) : const Color(0x33FF851B),
            border: Border.all(color: const Color(0xFFFF851B), width: live ? 2 : 1.4),
          ),
          child: Icon(Icons.back_hand_rounded, size: r * 1.05, color: const Color(0xFFB4560E)),
        ),
      ),
    );
  }
}
