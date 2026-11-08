import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'coworker_moment.dart';
import 'do_parts.dart';
import 'glove_check.dart';
import 'mistake_kit.dart';

// Ladder step 3's helmet station (lesson 1.1, কাজ 2, after the gloves): pick
// your own helmet from the van's shelf, then look it over the way the lesson's
// daily check says — a torch swept across the shell (a hairline crack shows
// only where the light rakes across it), the inside (metal parts; the date and
// test stamp, readable only up close) and the chin strap's lock. Pack it or
// send it back. Packing a bad helmet is a slip, never deadly (owner, 2026-11-08).
//
// Content (lesson 1.1, point 2 "সেফটি হেলমেট", the myths and pro tip 5
// "মেয়াদ ও স্ট্যাম্প দেখুন"): a bike helmet or a vented construction cap is
// "চরম বিপজ্জনক" for line work; a cracked shell can no longer take a blow; metal
// parts inside or vents — never on line work; the chin strap must lock; look for
// the manufacture date and test stamp inside (pro tip 5).
//
// Voice: device TTS for the guide (every fixed line is in [HelmetLines]); the
// careless coworker's push is in his recorded voice.

// ============================================================================
// Data
// ============================================================================

enum HelmetKind { good, flawed, wrong }

/// The three looks of the daily check.
enum HelmetCheck { shell, inside, strap }

enum HelmetFlawKind { crack, metal, noStamp, strap }

@immutable
class HelmetFlaw {
  const HelmetFlaw({required this.kind, required this.labelBn, required this.lineBn, this.lessonPoint = 1});
  final HelmetFlawKind kind;
  final String labelBn;
  final String lineBn;

  /// 0-based point of lesson 1.1 that teaches it.
  final int lessonPoint;

  /// The look that finds it.
  HelmetCheck get check => switch (kind) {
        HelmetFlawKind.crack => HelmetCheck.shell,
        HelmetFlawKind.metal || HelmetFlawKind.noStamp => HelmetCheck.inside,
        HelmetFlawKind.strap => HelmetCheck.strap,
      };
}

@immutable
class HelmetItem {
  const HelmetItem({
    required this.id,
    required this.kind,
    required this.asset,
    required this.aspect,
    required this.labelBn,
    this.lineBn = '',
    this.flaw,
    this.crackAt,
  });

  final String id;
  final HelmetKind kind;
  final String asset;
  final double aspect;
  final String labelBn;
  final String lineBn;
  final HelmetFlaw? flaw;

  /// Crack only: where it runs on the shell (0–1 of the picture box).
  final Offset? crackAt;

  /// A line helmet (sound or flawed) gets the three looks; a wrong one is plain to see.
  bool get lineHelmet => kind != HelmetKind.wrong;

  HelmetItem withFlaw(HelmetFlaw f, {Offset? crackAt}) => HelmetItem(
        id: '$id#${f.kind.name}',
        kind: HelmetKind.flawed,
        asset: asset,
        aspect: aspect,
        labelBn: f.labelBn,
        lineBn: f.lineBn,
        flaw: f,
        crackAt: crackAt,
      );
}

/// Fixed lines (device TTS until recorded).
abstract final class HelmetLines {
  static const station = 'হেলমেট';
  static const ask = 'শেষে নিজের হেলমেট। তাক থেকে বেছে নিন।';
  static const head = 'ভালো করে দেখুন';
  static const tabShell = 'খোলস';
  static const tabInside = 'ভেতর';
  static const tabStrap = 'ফিতে';
  static const torchTask = 'টর্চ টেনে পুরো খোলসে আলো ফেলুন। ফাটল চোখে পড়লে সেখানে ছুঁয়ে দিন।';
  static const insideTask = 'ভেতরটা চোখের কাছে এনে দেখুন।';
  static const strapTask = 'ফিতের লকটা লাগিয়ে দেখুন।';
  static const checkFirst = 'আগে খোলস, ভেতর আর ফিতে—তিনটেই দেখুন!';
  static const guessed = 'ঠিক, কিন্তু আন্দাজে নয়—আগে ভালো করে দেখুন।';
  static const caught = 'ঠিক ধরেছেন!';
  static const rejectedGood = 'এই হেলমেটটা তো ঠিক ছিল!';
  static const crackSpotted = 'ঠিক ধরেছেন—খোলসে সূক্ষ্ম ফাটল!';
  static const locked = 'ক্লিক—লক হলো।';
  static const noLock = 'লক হচ্ছে না!';
  static const packed = 'ব্যাগে তোলা হলো।';

  /// Slip cards (the line under the picture).
  static const uncheckedCard = 'হেলমেটটা ঠিক ছিল—কিন্তু না দেখে নিলেন। খোলস, ভেতর, ফিতে—তিনটেই দেখে তবে নিন।';
  static const goodCard = 'এই হেলমেটে ফাটল, মেটাল বা ভেন্ট নেই, স্ট্যাম্প আছে, ফিতেও লক হয়—এটাই নেওয়ার কথা।';

  // The reason after the helmet is packed (lesson 1.1): one right, two wrong.
  static const whyAsk = 'কেন এই হেলমেটটা নিলেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const whyRight = [
    'ফাটলহীন, ছিদ্রহীন খোলসই মাথা বাঁচায়',
    'ভেন্ট বা মেটাল নেই—লাইনের কাজের হেলমেট',
    'ফিতে লক হয়, পোল ঝাঁকালেও খসবে না',
    'স্ট্যাম্প আর তারিখ দেখে তবেই নিয়েছি',
  ];
  static const whyWrong = [
    'একটু ফাটল থাকলেও হেলমেট চলে যায়',
    'যেকোনো শক্ত টুপিই মাথা বাঁচিয়ে দেয়',
    'ভেন্ট থাকলে মাথা ঠান্ডা থাকে, সেটাই ভালো',
    'চিন স্ট্র্যাপ না বাঁধলেও কাজ চলে যায়',
    'বাইকের হেলমেটও তো মাথা বাঁচায় দিব্যি',
    'রং উজ্জ্বল থাকলেই হেলমেট ভালো হয়',
  ];

  /// The careless coworker (his recorded voice) on the helmet ("একটু ফাটা
  /// হেলমেটে কিছু হয় না" — the ladder's pressure line, from the myths).
  static const coworkerLine = 'দেখার কী আছে? একটু ফাটা হেলমেটে কিছু হয় না!';
  static const choiceRight = [
    'না — খোলস, ভেতর, ফিতে দেখে নেব',
    'ফাটা হেলমেট মাথা বাঁচায় না, দেখব',
    'আগে দেখে নেব, তারপর মাথায় দেব',
    'ফিতে লক হয় কিনা, সেটাও দেখব',
  ];
  static const choiceWrong = [
    'ঠিক, একটু ফাটলে কিছুই হয় না',
    'যেটা হাতে আসে সেটাই পরে নিই',
    'চলো, না দেখেই মাথায় দিয়ে দিই',
    'পরে সময় পেলে দেখে নেব একবার',
    'সবাই তো না দেখেই পরে নেয় এমনি',
  ];
  static const choiceAsks = [
    'ও বলছে দেখার কিছু নেই। আপনি কী করবেন?',
    'দেখে নেবেন, না এমনিই মাথায় দেবেন?',
    'কার কথা শুনবেন — ওর, না নিয়মের?',
  ];
  /// The close look's tasks (tap the guide: he says the current one again).
  static const lookTasks = [torchTask, insideTask, strapTask];

  static const coworker = CoworkerScript(
    line: coworkerLine,
    exitLine: GloveLines.coworkerExit,
    right: choiceRight,
    wrong: choiceWrong,
    asks: choiceAsks,
  );
  static const callHeld = 'ঠিক। ফাটা হেলমেট মানে ফুটো ছাতা।';
  static const callRushed = 'না! ফাটা হেলমেট আর আঘাত নিতে পারে না।';

  static const all = [
    ask, torchTask, insideTask, strapTask, checkFirst, guessed, caught, rejectedGood, crackSpotted, locked, noLock, packed,
    uncheckedCard, goodCard, callHeld, callRushed,
  ];
}

const _dress = 'assets/duty_slip/dress';

/// The line helmet: non-vented, metal-free, chin strap (tray picture).
const helmetLine = HelmetItem(
  id: 'elec',
  kind: HelmetKind.good,
  asset: '$_dress/tray_elec_helmet.webp',
  aspect: 688 / 621,
  labelBn: 'লাইনের হেলমেট',
);

const helmetWrongs = [
  HelmetItem(
    id: 'vent',
    kind: HelmetKind.wrong,
    asset: '$_dress/tray_vent_helmet.webp',
    aspect: 512 / 413,
    labelBn: 'ভেন্টেড টুপি',
    lineBn: 'ফুটোওয়ালা (ভেন্টেড) টুপি—গর্ত দিয়ে মাথায় কারেন্ট ছোঁয়ার ঝুঁকি। লাইনের কাজে চলবে না।',
  ),
  HelmetItem(
    id: 'bike',
    kind: HelmetKind.wrong,
    asset: '$_dress/tray_bike_helmet.webp',
    aspect: 512 / 420,
    labelBn: 'বাইকের হেলমেট',
    lineBn: 'বাইকের হেলমেট পথ-দুর্ঘটনার জন্য—লাইনের শকের জন্য তৈরি নয়। কাজে পরা নিষেধ।',
  ),
];

const helmetFlaws = [
  HelmetFlaw(kind: HelmetFlawKind.crack, labelBn: 'ফাটা হেলমেট', lineBn: 'খোলসে সূক্ষ্ম ফাটল—ফাটা হেলমেট মানে ফুটো ছাতা, আর আঘাত নিতে পারে না।'),
  HelmetFlaw(kind: HelmetFlawKind.metal, labelBn: 'ভেতরে মেটাল পার্টস', lineBn: 'ভেতরে মেটাল পার্টস—লাইনের কাজে ভুলেও ব্যবহার করবেন না।'),
  HelmetFlaw(kind: HelmetFlawKind.noStamp, labelBn: 'স্ট্যাম্পহীন হেলমেট', lineBn: 'ভেতরে তারিখ বা পরীক্ষার স্ট্যাম্প নেই। স্টোর থেকে নতুনটা চেয়ে নেওয়া আপনার অধিকার।'),
  HelmetFlaw(kind: HelmetFlawKind.strap, labelBn: 'ফিতের লক ভাঙা', lineBn: 'চিন স্ট্র্যাপ লক হয় না—পোল ঝাঁকালেই হেলমেট খসে নিচে পড়বে।'),
];

/// Where a hairline crack can run on the line helmet's shell (picture box 0–1).
const helmetCrackSpots = [Offset(0.40, 0.24), Offset(0.62, 0.34), Offset(0.34, 0.44)];

/// How close to the crack a tap must land to spot it, in picture widths.
const kHelmetSpotReach = 0.10;

/// A tap that travels less than this (logical px) is a "there it is" tap.
const kHelmetTapSlop = 14.0;

/// Does a tap at [tap] (picture box 0–1) point at the crack at [crack]?
bool helmetSpotsCrack(Offset tap, Offset? crack, double aspect) => crack != null && helmetDist(tap, crack, aspect) <= kHelmetSpotReach;

/// Points on the shell the torch must pass over for a full sweep.
const helmetSweepPoints = [
  Offset(0.28, 0.30),
  Offset(0.50, 0.14),
  Offset(0.72, 0.24),
  Offset(0.50, 0.40),
  Offset(0.82, 0.42),
  Offset(0.24, 0.52),
];

/// The torch beam's radius and the sweep's reach, in picture widths.
const kHelmetBeam = 0.26;
const kHelmetSweepReach = 0.17;

/// Years back from today on the stamp of a line helmet (a recent one).
const kHelmetFreshAge = 1;

// ============================================================================
// Deal + rules (pure, tested)
// ============================================================================

@immutable
class HelmetDeal {
  const HelmetDeal({required this.shelf, required this.month});

  /// The shelf in the van, already in its dealt order.
  final List<HelmetItem> shelf;

  /// The stamp's month (the year comes from today, so it never goes stale).
  final int month;
}

/// The shelf: the sound line helmet, a look-alike with one hidden fault (the
/// same picture: only the three looks tell them apart) and one or two wrong
/// helmets (vented cap, bike helmet). Order shuffled.
HelmetDeal dealHelmets(math.Random rng) {
  final flaw = helmetFlaws[rng.nextInt(helmetFlaws.length)];
  final spot = helmetCrackSpots[rng.nextInt(helmetCrackSpots.length)];
  final bad = helmetLine.withFlaw(flaw, crackAt: flaw.kind == HelmetFlawKind.crack ? spot : null);
  final wrongs = [...helmetWrongs]..shuffle(rng);
  final shelf = [helmetLine, bad, ...wrongs.take(1 + rng.nextInt(2))]..shuffle(rng);
  return HelmetDeal(shelf: shelf, month: 1 + rng.nextInt(12));
}

/// The date moulded inside [h] (`MM/YYYY`, English digits), counted back from
/// [now]; null when the helmet has no stamp.
String? helmetStampDate(HelmetItem h, HelmetDeal d, DateTime now) {
  if (!h.lineHelmet || h.flaw?.kind == HelmetFlawKind.noStamp) return null;
  return '${d.month.toString().padLeft(2, '0')}/${now.year - kHelmetFreshAge}';
}

/// Distance between two picture-box points, in picture widths.
double helmetDist(Offset a, Offset b, double aspect) {
  final dx = a.dx - b.dx;
  final dy = (a.dy - b.dy) / aspect;
  return math.sqrt(dx * dx + dy * dy);
}

/// How much of a hairline crack the torch shows (0 = none). Nothing without
/// the light or outside the beam; washed out with the light straight on it;
/// clearest where the beam's edge rakes across it.
double crackVisibility(Offset? torch, Offset crack, double aspect) {
  if (torch == null) return 0;
  final d = helmetDist(torch, crack, aspect);
  const peak = kHelmetBeam * 0.45;
  if (d >= kHelmetBeam) return 0;
  if (d <= peak) return 0.45 + 0.55 * (d / peak);
  return 1 - (d - peak) / (kHelmetBeam - peak);
}

/// Sweep points lit by a torch at [torch].
Iterable<int> helmetSweepHits(Offset torch, double aspect) sync* {
  for (var i = 0; i < helmetSweepPoints.length; i++) {
    if (helmetDist(torch, helmetSweepPoints[i], aspect) <= kHelmetSweepReach) yield i;
  }
}

/// Like the gloves' air test: a sound line helmet is packed only after all
/// three looks; sending back a faulty one without the look that finds its
/// fault is a lucky guess; a wrong helmet is plain to see.
GloveOutcome judgeHelmet(HelmetItem h, GloveChoice c, {required Set<HelmetCheck> checks}) {
  switch ((h.kind, c)) {
    case (HelmetKind.good, GloveChoice.wear):
      if (!checks.containsAll(HelmetCheck.values)) {
        return const GloveOutcome(
            right: false, clean: false, delta: -5, packs: false, leavesTray: false, stampBn: gloveStampWrong, wordBn: HelmetLines.checkFirst, reasonBn: HelmetLines.uncheckedCard);
      }
      return const GloveOutcome(right: true, clean: true, delta: 10, packs: true, leavesTray: true, stampBn: gloveStampRight);
    case (HelmetKind.good, GloveChoice.reject):
      return const GloveOutcome(
          right: false, clean: false, delta: -5, packs: false, leavesTray: false, stampBn: gloveStampWrong, wordBn: HelmetLines.rejectedGood, reasonBn: HelmetLines.goodCard);
    case (_, GloveChoice.wear):
      return GloveOutcome(right: false, clean: false, delta: -5, packs: false, leavesTray: true, stampBn: gloveStampWrong, reasonBn: h.lineBn);
    case (HelmetKind.flawed, GloveChoice.reject) when !checks.contains(h.flaw!.check):
      return GloveOutcome(right: true, clean: false, delta: 0, packs: false, leavesTray: true, stampBn: gloveStampReject, wordBn: HelmetLines.guessed, reasonBn: h.lineBn);
    case (_, GloveChoice.reject):
      return GloveOutcome(right: true, clean: true, delta: 5, packs: false, leavesTray: true, stampBn: gloveStampReject, wordBn: HelmetLines.caught, reasonBn: h.lineBn);
  }
}

/// The slip card for a wrong decision on [h].
DoMistake helmetMistake(HelmetItem h, GloveOutcome o) {
  final key = switch (h.kind) {
    HelmetKind.good => o.wordBn == HelmetLines.checkFirst ? 'unchecked' : 'rejected-good',
    HelmetKind.flawed => h.flaw!.kind.name,
    HelmetKind.wrong => h.id,
  };
  return DoMistake(key: '1.1/helmet/$key', textBn: o.reasonBn, art: h.asset, lessonPoint: h.flaw?.lessonPoint ?? 1);
}

class HelmetRound {
  HelmetRound(this.deal);

  final HelmetDeal deal;
  HelmetItem? packed;
  final caught = <HelmetItem>[];
  final _gone = <String>{};
  final _tried = <String>{};
  final _checks = <String, Set<HelmetCheck>>{};
  int asked = 0;
  int clean = 0;

  bool get done => packed != null;
  List<HelmetItem> get shelf => done ? const [] : [for (final h in deal.shelf) if (!_gone.contains(h.id)) h];

  void markChecked(HelmetItem h, HelmetCheck c) => (_checks[h.id] ??= <HelmetCheck>{}).add(c);
  Set<HelmetCheck> checksOf(HelmetItem h) => _checks[h.id] ?? const {};

  GloveOutcome decide(HelmetItem h, GloveChoice c) {
    final o = judgeHelmet(h, c, checks: checksOf(h));
    if (_tried.add(h.id)) {
      asked++;
      if (o.clean) clean++;
    }
    if (o.right && c == GloveChoice.reject) caught.add(h);
    if (o.leavesTray) _gone.add(h.id);
    if (o.packs) packed = h;
    return o;
  }
}

/// Every fixed line of the helmet station (record-later list, tests).
Iterable<String> helmetCheckLines() sync* {
  yield* HelmetLines.all;
  for (final h in helmetWrongs) {
    yield h.lineBn;
  }
  for (final f in helmetFlaws) {
    yield f.lineBn;
  }
}

// ============================================================================
// Close look
// ============================================================================

/// Close look at a helmet. A line helmet gets the three looks (tabs): the torch
/// on the shell, the inside up close, the chin strap's lock. Then decide.
class HelmetInspect extends StatefulWidget {
  const HelmetInspect({
    super.key,
    required this.item,
    required this.stampDate,
    required this.checks,
    required this.verdict,
    required this.leaving,
    required this.quiet,
    required this.muted,
    required this.onCheck,
    required this.onSay,
    required this.onDecide,
    required this.onTapCard,
    required this.onTapShade,
    required this.onGone,
  });

  final HelmetItem item;

  /// `MM/YYYY` moulded inside, or null (no stamp).
  final String? stampDate;
  final Set<HelmetCheck> checks;
  final GloveOutcome? verdict;
  final bool leaving;
  final bool quiet;
  final bool muted;
  final ValueChanged<HelmetCheck> onCheck;

  /// A guide line (the next task in a look, the strap's result).
  final ValueChanged<String> onSay;
  final void Function(GloveChoice c, Offset origin) onDecide;
  final VoidCallback onTapCard;
  final VoidCallback onTapShade;
  final VoidCallback onGone;

  @override
  State<HelmetInspect> createState() => _HelmetInspectState();
}

class _HelmetInspectState extends State<HelmetInspect> with TickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _stamp = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _strap = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  HelmetCheck _tab = HelmetCheck.shell;
  final _seen = <HelmetCheck>{};
  final _torch = ValueNotifier<Offset?>(null);
  final _lit = <int>{};

  /// The player tapped the crack while looking (no ring until then).
  var _crackSeen = false;
  Offset? _downAt;
  double _travel = 0;

  /// null = not tried; true = locked; false = would not lock.
  bool? _lock;
  var _snapping = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiet) {
      _lift.value = 1;
    } else {
      _lift.forward();
    }
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onGone();
    });
    _zoom.addStatusListener((s) {
      if (s == AnimationStatus.completed && _open) widget.onCheck(HelmetCheck.inside);
    });
    if (widget.item.lineHelmet) {
      // The guide speaks after this frame (never while the tree is building).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.verdict == null) _openTab(HelmetCheck.shell, say: true);
      });
    }
  }

  @override
  void didUpdateWidget(HelmetInspect old) {
    super.didUpdateWidget(old);
    if (widget.verdict != null && old.verdict == null) {
      if (widget.quiet) {
        _stamp.value = 1;
      } else {
        _stamp.forward(from: 0);
      }
      // Show the fault itself under the stamp.
      final f = widget.item.flaw;
      if (f != null) {
        _tab = f.check;
        if (f.kind == HelmetFlawKind.noStamp && _zoom.value < 0.5) {
          if (widget.quiet) {
            _zoom.value = 1;
          } else {
            _zoom.forward();
          }
        }
      }
    }
    if (widget.leaving && !old.leaving) {
      if (widget.quiet) {
        _exit.value = 1;
        widget.onGone();
      } else {
        _exit.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _lift.dispose();
    _stamp.dispose();
    _exit.dispose();
    _zoom.dispose();
    _strap.dispose();
    _torch.dispose();
    super.dispose();
  }

  bool get _open => widget.verdict == null;

  void _openTab(HelmetCheck c, {bool say = false}) {
    if (_tab != c) setState(() => _tab = c);
    if (_seen.add(c) || say) {
      widget.onSay(switch (c) {
        HelmetCheck.shell => HelmetLines.torchTask,
        HelmetCheck.inside => HelmetLines.insideTask,
        HelmetCheck.strap => HelmetLines.strapTask,
      });
    }
  }

  // ---- the torch on the shell -------------------------------------------------

  void _moveTorch(Offset local, Size box) {
    if (!_open) return;
    // The light sits a little above the finger so the finger does not hide it.
    final p = Offset((local.dx / box.width).clamp(0.0, 1.0), ((local.dy - 34) / box.height).clamp(0.0, 1.0));
    _torch.value = p;
    final aspect = box.width / box.height;
    final before = _lit.length;
    _lit.addAll(helmetSweepHits(p, aspect));
    if (_lit.length != before) {
      setState(() {});
      if (_lit.length == helmetSweepPoints.length) {
        HapticFeedback.lightImpact();
        widget.onCheck(HelmetCheck.shell);
      }
    }
  }

  void _torchDown(Offset local, Size box) {
    _downAt = local;
    _travel = 0;
    _moveTorch(local, box);
  }

  void _torchMove(Offset local, Size box) {
    final d = _downAt;
    if (d != null) _travel = math.max(_travel, (local - d).distance);
    _moveTorch(local, box);
  }

  /// Lift the finger. A short tap is the player pointing: "there's a crack".
  /// Only the crack itself answers it — the game never points it out.
  void _torchUp(Offset local, Size box) {
    final tapped = _downAt != null && _travel < kHelmetTapSlop;
    _downAt = null;
    _torch.value = null;
    if (!tapped || !_open || _crackSeen) return;
    final p = Offset((local.dx / box.width).clamp(0.0, 1.0), (local.dy / box.height).clamp(0.0, 1.0));
    if (!helmetSpotsCrack(p, widget.item.crackAt, box.width / box.height)) return;
    HapticFeedback.mediumImpact();
    if (!widget.muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.6, muted: false));
    setState(() => _crackSeen = true);
    widget.onSay(HelmetLines.crackSpotted);
    // Finding the fault is the shell's look done.
    widget.onCheck(HelmetCheck.shell);
  }

  void _torchOff() {
    _downAt = null;
    _torch.value = null;
  }

  // ---- inside, up close -------------------------------------------------------

  void _toggleZoom() {
    if (!_open) return;
    HapticFeedback.selectionClick();
    if (_zoom.value > 0.5) {
      if (widget.quiet) {
        _zoom.value = 0;
      } else {
        _zoom.reverse();
      }
      return;
    }
    if (widget.quiet) {
      _zoom.value = 1; // the status listener marks the look done
    } else {
      _zoom.forward();
    }
  }

  // ---- the chin strap ---------------------------------------------------------

  static const _restX = 0.30;
  static const _lockX = 0.52;

  void _dragStrap(double dx, double width) {
    if (!_open || _snapping || _lock == true) return;
    _strap.value = (_strap.value + dx / (width * (_lockX - _restX))).clamp(0.0, 1.0);
  }

  Future<void> _releaseStrap() async {
    if (!_open || _snapping || _lock == true) return;
    if (_strap.value < 0.7) {
      await _go(0);
      if (!mounted) return;
      return;
    }
    _snapping = true;
    await _go(1);
    if (!mounted) return;
    final holds = widget.item.flaw?.kind != HelmetFlawKind.strap;
    if (!widget.muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.7, muted: false));
    if (holds) {
      HapticFeedback.lightImpact();
      setState(() => _lock = true);
      widget.onSay(HelmetLines.locked);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _lock = false);
      widget.onSay(HelmetLines.noLock);
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      await _go(0);
    }
    _snapping = false;
    widget.onCheck(HelmetCheck.strap);
  }

  Future<void> _go(double v) async {
    if (widget.quiet) {
      _strap.value = v;
      return;
    }
    await _strap.animateTo(v, curve: Curves.easeOutBack);
  }

  // ---- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final h = widget.item;
    final v = widget.verdict;
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: SlmColors.ivory,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(HelmetLines.head, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
          const SizedBox(height: 10),
          if (h.lineHelmet) ...[
            Row(
              children: [
                for (final c in HelmetCheck.values) ...[
                  if (c != HelmetCheck.shell) const SizedBox(width: 6),
                  Expanded(
                    child: _Tab(
                      key: ValueKey('helmet-tab-${c.name}'),
                      check: c,
                      on: _tab == c,
                      done: widget.checks.contains(c),
                      progress: c == HelmetCheck.shell ? _lit.length / helmetSweepPoints.length : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _openTab(c);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 236,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  KeyedSubtree(key: ValueKey('view-${h.lineHelmet ? _tab.name : 'plain'}'), child: _view(h)),
                  if (v != null)
                    AnimatedBuilder(
                      key: const ValueKey('stamp'),
                      animation: _stamp,
                      builder: (_, _) {
                        final t = Curves.easeOutBack.transform((_stamp.value / 0.3).clamp(0.0, 1.0));
                        return IgnorePointer(
                          child: Center(
                            child: Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.rotate(
                                angle: -0.22,
                                child: Transform.scale(scale: 2.2 - 1.2 * t, child: DoStamp(text: v.stampBn, good: v.stampBn == gloveStampRight)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          if (h.lineHelmet && _tab == HelmetCheck.strap && _lock != null && v == null) ...[
            const SizedBox(height: 8),
            Text(
              _lock! ? HelmetLines.locked : HelmetLines.noLock,
              style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: _lock! ? SlmColors.emerald500 : SlmColors.danger),
            ),
          ],
          const SizedBox(height: 12),
          if (v == null)
            Row(
              children: [
                Expanded(child: DoBigButton(label: 'বাদ দিন', filled: false, onTapUp: (d) => widget.onDecide(GloveChoice.reject, d.globalPosition))),
                const SizedBox(width: 12),
                Expanded(child: DoBigButton(label: 'নিয়ে নিন', filled: true, onTapUp: (d) => widget.onDecide(GloveChoice.wear, d.globalPosition))),
              ],
            )
          else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (v.right ? SlmColors.emerald500 : SlmColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                v.right ? (v.reasonBn.isNotEmpty ? v.reasonBn : HelmetLines.packed) : (v.wordBn.isNotEmpty ? v.wordBn : h.labelBn),
                textAlign: TextAlign.center,
                style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.35),
              ),
            ),
        ],
      ),
    );

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: v == null ? widget.onTapShade : widget.onTapCard,
              child: AnimatedBuilder(
                animation: Listenable.merge([_lift, _exit]),
                child: GestureDetector(onTap: v == null ? () {} : widget.onTapCard, child: card),
                builder: (_, child) {
                  final lift = Curves.easeOutBack.transform(_lift.value);
                  final e = Curves.easeInCubic.transform(_exit.value);
                  var dx = 0.0, dy = 0.0, rot = 0.0, scale = 0.7 + 0.3 * lift;
                  var fade = 1.0;
                  if (v != null && _exit.value > 0) {
                    if (v.packs) {
                      dy = -200 * e; // into the bag
                      scale *= 1 - 0.8 * e;
                    } else if (v.leavesTray) {
                      dx = 420 * e; // back to the store
                      rot = 0.6 * e;
                    } else {
                      dx = math.sin(_exit.value * math.pi * 6) * 14 * (1 - _exit.value);
                      scale *= 1 - 0.3 * e;
                    }
                    fade = 1 - e;
                  }
                  return ColoredBox(
                    color: Color.fromRGBO(5, 10, 22, 0.8 * (1 - e)),
                    child: Align(
                      alignment: const Alignment(0, -0.35),
                      child: Opacity(
                        opacity: (fade * _lift.value).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(dx, dy + 40 * (1 - lift)),
                          child: Transform.rotate(angle: rot, child: Transform.scale(scale: scale, child: child)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (!widget.leaving)
            Positioned(
              key: const ValueKey('coach'),
              left: 0,
              right: 0,
              bottom: 8,
              child: DoCoachStrip(tasks: widget.item.lineHelmet ? HelmetLines.lookTasks : const [], muted: widget.muted),
            ),
        ],
      ),
    );
  }

  Widget _view(HelmetItem h) {
    final px = (300 * MediaQuery.devicePixelRatioOf(context)).round();
    final picture = Image(image: ResizeImage(AssetImage(h.asset), height: px, policy: ResizeImagePolicy.fit), fit: BoxFit.fill);
    if (!h.lineHelmet) {
      return ColoredBox(
        color: const Color(0xFFE9E2D2),
        child: Center(child: Padding(padding: const EdgeInsets.all(12), child: AspectRatio(aspectRatio: h.aspect, child: picture))),
      );
    }
    return switch (_tab) {
      HelmetCheck.shell => _shell(h, picture),
      HelmetCheck.inside => _inside(),
      HelmetCheck.strap => _strapView(),
    };
  }

  Widget _shell(HelmetItem h, Widget picture) {
    final crack = h.crackAt;
    final after = widget.verdict != null;
    return ColoredBox(
      color: const Color(0xFF0B111C),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AspectRatio(
            aspectRatio: h.aspect,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = box.biggest;
                // Raw pointer events: the light follows the finger from the first touch.
                return Listener(
                  key: const ValueKey('helmet-torch'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _torchDown(e.localPosition, size),
                  onPointerMove: (e) => _torchMove(e.localPosition, size),
                  onPointerUp: (e) => _torchUp(e.localPosition, size),
                  onPointerCancel: (_) => _torchOff(),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      KeyedSubtree(key: const ValueKey('picture'), child: picture),
                      if (crack != null)
                        CustomPaint(key: const ValueKey('crack'), painter: HelmetCrackPainter(crack, _torch, aspect: h.aspect, shown: after || _crackSeen)),
                      CustomPaint(key: const ValueKey('shade'), painter: TorchShadePainter(_torch, lit: after)),
                      // Spotted by the player: the crack and its ring stay in view over the dark.
                      if (crack != null && _crackSeen && !after) CustomPaint(key: const ValueKey('spot-ring'), painter: HelmetSpotRingPainter(crack)),
                      if (after && crack != null) CustomPaint(key: const ValueKey('pulse'), painter: DoPulsePainter([crack], _stamp)),
                      if (!after)
                        ValueListenableBuilder<Offset?>(
                          key: const ValueKey('torch-icon'),
                          valueListenable: _torch,
                          builder: (_, t, _) => t == null
                              ? const Align(
                                  alignment: Alignment(0.92, 0.95),
                                  child: Icon(Icons.flashlight_on_rounded, color: Color(0xFFFFE08A), size: 34),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _inside() {
    return GestureDetector(
      key: const ValueKey('helmet-inside'),
      behavior: HitTestBehavior.opaque,
      onTap: _toggleZoom,
      child: ColoredBox(
        color: const Color(0xFF1B2638),
        child: AnimatedBuilder(
          animation: _zoom,
          builder: (_, child) {
            final z = Curves.easeInOutCubic.transform(_zoom.value);
            return Transform.scale(scale: 1 + 3.4 * z, alignment: const Alignment(0, -0.28), child: child);
          },
          child: CustomPaint(
            painter: HelmetInsidePainter(metal: widget.item.flaw?.kind == HelmetFlawKind.metal, stampDate: widget.stampDate),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _strapView() {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return GestureDetector(
          key: const ValueKey('helmet-strap'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => _dragStrap(d.delta.dx, w),
          onHorizontalDragEnd: (_) => unawaited(_releaseStrap()),
          onHorizontalDragCancel: () => unawaited(_releaseStrap()),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: ChinStrapPainter(
                _strap,
                restX: _restX,
                lockX: _lockX,
                locked: _lock == true,
                // After the decision a broken latch shows even if it was never tried.
                broken: _lock == false || (widget.verdict != null && widget.item.flaw?.kind == HelmetFlawKind.strap),
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({super.key, required this.check, required this.on, required this.done, required this.progress, required this.onTap});
  final HelmetCheck check;
  final bool on;
  final bool done;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (check) {
      HelmetCheck.shell => (HelmetLines.tabShell, Icons.flashlight_on_rounded),
      HelmetCheck.inside => (HelmetLines.tabInside, Icons.zoom_in_rounded),
      HelmetCheck.strap => (HelmetLines.tabStrap, Icons.lock_outline_rounded),
    };
    final edge = done ? SlmColors.emerald500 : (on ? SlmColors.gold500 : SlmColors.gold300);
    return Material(
      color: on ? const Color(0xFF1B2A48) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: edge, width: on ? 2 : 1)),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(done ? Icons.check_circle_rounded : icon, size: 18, color: done ? SlmColors.emerald500 : (on ? SlmColors.gold300 : SlmColors.ink)),
                    const SizedBox(width: 4),
                    Text(label, style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: on ? SlmColors.ivory : SlmColors.ink)),
                  ],
                ),
              ),
              if (progress != null && !done && progress! > 0)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(value: progress, minHeight: 3, backgroundColor: SlmColors.gold300.withValues(alpha: 0.3), color: SlmColors.gold500),
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
// Painters
// ============================================================================

/// The dim van shelf with a torch beam: dark everywhere but a soft circle of
/// light; [lit] lifts the dark (after the decision).
class TorchShadePainter extends CustomPainter {
  TorchShadePainter(this.torch, {required this.lit}) : super(repaint: torch);
  final ValueListenable<Offset?> torch;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    if (lit) return;
    final rect = (Offset.zero & size).inflate(40);
    final t = torch.value;
    if (t == null) {
      canvas.drawRect(rect, Paint()..color = const Color(0xD9060A12));
      return;
    }
    final c = Offset(t.dx * size.width, t.dy * size.height);
    final r = size.width * kHelmetBeam;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x00060A12), Color(0x14060A12), Color(0xD9060A12)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // A warm tint in the beam.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: const [Color(0x22FFE6A8), Color(0x00FFE6A8)]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(TorchShadePainter old) => old.lit != lit || old.torch != torch;
}

/// A hairline crack in the shell: drawn only as much as the torch shows it
/// ([crackVisibility]); once the player has spotted it (a tap on it) or after
/// the decision ([shown]), a thin ring marks it.
class HelmetCrackPainter extends CustomPainter {
  HelmetCrackPainter(this.at, this.torch, {required this.aspect, required this.shown}) : super(repaint: torch);
  final Offset at;
  final ValueListenable<Offset?> torch;
  final double aspect;
  final bool shown;

  @override
  void paint(Canvas canvas, Size size) {
    final vis = math.max(crackVisibility(torch.value, at, aspect), shown ? 0.85 : 0.0);
    if (vis <= 0) return;
    final c = Offset(at.dx * size.width, at.dy * size.height);
    final s = size.width * 0.11;
    final path = helmetCrackPath(c, s);
    canvas.drawPath(
      path.shift(const Offset(0.8, 0.8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.fromRGBO(255, 214, 170, 0.6 * vis),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round
        ..color = Color.fromRGBO(58, 22, 6, vis),
    );
    if (shown) {
      canvas.drawCircle(
        c,
        s * 0.95,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = SlmColors.danger.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(HelmetCrackPainter old) => old.at != at || old.shown != shown || old.torch != torch;
}

/// The hairline crack's shape around [c] ([s] = its size).
Path helmetCrackPath(Offset c, double s) => Path()
  ..moveTo(c.dx - s * 0.7, c.dy - s * 0.35)
  ..lineTo(c.dx - s * 0.32, c.dy - s * 0.05)
  ..lineTo(c.dx - s * 0.05, c.dy - s * 0.18)
  ..lineTo(c.dx + s * 0.28, c.dy + s * 0.12)
  ..lineTo(c.dx + s * 0.62, c.dy + s * 0.04)
  ..moveTo(c.dx - s * 0.05, c.dy - s * 0.18)
  ..lineTo(c.dx + s * 0.04, c.dy - s * 0.48);

/// Over the dark shell: the crack the player spotted, lit, with a ring.
class HelmetSpotRingPainter extends CustomPainter {
  const HelmetSpotRingPainter(this.at);
  final Offset at;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(at.dx * size.width, at.dy * size.height);
    final s = size.width * 0.11;
    canvas.drawCircle(c, s * 0.95, Paint()..color = const Color(0x33FFE6A8));
    canvas.drawPath(
      helmetCrackPath(c, s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFD9A8),
    );
    canvas.drawCircle(
      c,
      s * 0.95,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = SlmColors.danger,
    );
  }

  @override
  bool shouldRepaint(HelmetSpotRingPainter old) => old.at != at;
}

/// The helmet seen from below: the shell's rim, the suspension (জালি) crossing
/// under the crown with its headband, and the moulded stamp (tiny — readable
/// only up close). [metal]: metal rivets and a metal clip in the suspension.
class HelmetInsidePainter extends CustomPainter {
  const HelmetInsidePainter({required this.metal, required this.stampDate});
  final bool metal;
  final String? stampDate;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final rx = math.min(w * 0.42, h * 0.62);
    final ry = h * 0.44;

    // Shell rim and the hollow inside.
    final rim = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(rim.shift(const Offset(0, 5)), Paint()..color = const Color(0x55000000));
    canvas.drawOval(rim, Paint()..color = const Color(0xFFF08A2A));
    final hollow = rim.deflate(rx * 0.07);
    canvas.drawOval(
      hollow,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFD9761C), Color(0xFFA9530F), Color(0xFF7A3A0A)], stops: [0, 0.7, 1])
            .createShader(hollow),
    );

    // Headband ring.
    final band = Rect.fromCenter(center: c.translate(0, ry * 0.08), width: rx * 1.32, height: ry * 1.18);
    canvas.drawOval(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFF2E3238),
    );
    canvas.drawOval(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF5A606A),
    );
    // Ratchet at the back (bottom of the view).
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, band.bottom), width: 38, height: 16), const Radius.circular(6)),
      Paint()..color = const Color(0xFF22252A),
    );

    // Suspension straps from four clips on the headband to the crown.
    final crown = c.translate(0, ry * 0.12);
    final clips = <Offset>[
      for (final a in const [-2.35, -0.79, 0.79, 2.35]) Offset(band.center.dx + band.width / 2 * math.cos(a), band.center.dy + band.height / 2 * math.sin(a)),
    ];
    for (final p in clips) {
      canvas.drawLine(
          p,
          crown,
          Paint()
            ..strokeWidth = 11
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFBDB7A8));
      canvas.drawLine(
          p,
          crown,
          Paint()
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFE8E3D6));
    }
    for (final p in clips) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 18, height: 14), const Radius.circular(4)), Paint()..color = const Color(0xFF1E2126));
      if (metal) _rivet(canvas, p, 5.5);
    }
    // The crown cross: a plastic button, or a metal clip.
    if (metal) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: crown, width: 22, height: 16), const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFFF2F4F6), Color(0xFF8A9096), Color(0xFFD5D9DD)]).createShader(Rect.fromCenter(center: crown, width: 22, height: 16)),
      );
      _rivet(canvas, crown, 4);
    } else {
      canvas.drawCircle(crown, 8, Paint()..color = const Color(0xFF2B2F35));
    }

    // The moulded stamp on the inner shell, between the two front straps.
    // Moulded in the shell's own colour: low contrast, tiny until brought close.
    final stamp = Rect.fromCenter(center: Offset(c.dx, h * 0.36), width: rx * 0.30, height: ry * 0.13);
    final date = stampDate;
    if (date != null) {
      canvas.drawRRect(RRect.fromRectAndRadius(stamp, const Radius.circular(2)), Paint()..color = const Color(0xFFC4660F));
      canvas.drawRRect(
        RRect.fromRectAndRadius(stamp, const Radius.circular(2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = const Color(0xFF8E4A0C),
      );
      final tp = TextPainter(
        text: TextSpan(
          style: TextStyle(fontSize: stamp.height * 0.28, height: 1.15, fontWeight: FontWeight.w800, color: const Color(0xFF6A3208), letterSpacing: 0.2),
          children: [const TextSpan(text: 'IS 2925\n'), TextSpan(text: 'MFD $date')],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: stamp.width);
      tp.paint(canvas, Offset(stamp.center.dx - tp.width / 2, stamp.center.dy - tp.height / 2));
      tp.dispose();
    }
  }

  void _rivet(Canvas canvas, Offset p, double r) {
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFB9C0C6), Color(0xFF6C737A)], stops: [0, 0.5, 1], center: Alignment(-0.3, -0.3))
            .createShader(Rect.fromCircle(center: p, radius: r)),
    );
  }

  @override
  bool shouldRepaint(HelmetInsidePainter old) => old.metal != metal || old.stampDate != stampDate;
}

/// The chin strap under the helmet's rim: the left strap ends in the buckle's
/// tongue (dragged by [t], 0 = loose, 1 = in the buckle), the right one in the
/// buckle. [broken]: the buckle's latch is snapped and will not hold.
class ChinStrapPainter extends CustomPainter {
  ChinStrapPainter(this.t, {required this.restX, required this.lockX, required this.locked, required this.broken}) : super(repaint: t);
  final Animation<double> t;
  final double restX;
  final double lockX;
  final bool locked;
  final bool broken;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final k = (h / 160).clamp(1.0, 1.8);
    // Daylight behind; the helmet's lower edge across the top.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDE6D6), Color(0xFFD8CDB6)])
            .createShader(Offset.zero & size),
    );
    final rim = Path()
      ..moveTo(-10, h * 0.20)
      ..quadraticBezierTo(w / 2, h * 0.02, w + 10, h * 0.20)
      ..lineTo(w + 10, -10)
      ..lineTo(-10, -10)
      ..close();
    canvas.drawPath(
      rim,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF9A3C), Color(0xFFD66A12)])
            .createShader(Rect.fromLTWH(0, 0, w, h * 0.22)),
    );

    final y = h * 0.66;
    final tongueX = w * (restX + (lockX - restX) * t.value);
    final buckleX = w * (lockX + 0.04);
    final webbing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * k
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFF23262B);
    final stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF4A5059);
    // Left strap to the tongue; right strap to the buckle.
    final left = Path()
      ..moveTo(w * 0.14, h * 0.13)
      ..quadraticBezierTo(w * 0.12, y, tongueX - 16 * k, y);
    final right = Path()
      ..moveTo(w * 0.86, h * 0.13)
      ..quadraticBezierTo(w * 0.88, y, buckleX + 24 * k, y);
    for (final p in [left, right]) {
      canvas.drawPath(p, webbing);
      canvas.drawPath(p, stitch);
    }

    // The buckle (receiver).
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(buckleX - 3 * k, y - 13 * k, 28 * k, 26 * k), Radius.circular(6 * k));
    canvas.drawRRect(body.shift(const Offset(0, 2)), Paint()..color = const Color(0x33000000));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2B2F35));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = locked ? SlmColors.emerald500 : const Color(0xFF5E646C),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(buckleX + 6 * k, y - 6 * k, 11 * k, 12 * k), Radius.circular(2.5 * k)), Paint()..color = const Color(0xFF474C55));
    if (broken) {
      // The snapped latch: a crack across the buckle.
      canvas.drawPath(
        Path()
          ..moveTo(buckleX + 2 * k, y - 11 * k)
          ..lineTo(buckleX + 9 * k, y - 3 * k)
          ..lineTo(buckleX + 6 * k, y + 2 * k)
          ..lineTo(buckleX + 14 * k, y + 11 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = SlmColors.danger,
      );
    }

    // The tongue: a two-pronged clip on the left strap's end.
    final tongue = Path()
      ..moveTo(tongueX - 18 * k, y - 9 * k)
      ..lineTo(tongueX - 2 * k, y - 9 * k)
      ..lineTo(tongueX + 10 * k, y - 4 * k)
      ..lineTo(tongueX + 10 * k, y + 4 * k)
      ..lineTo(tongueX - 2 * k, y + 9 * k)
      ..lineTo(tongueX - 18 * k, y + 9 * k)
      ..close();
    canvas.drawPath(tongue, Paint()..color = const Color(0xFF3A3F47));
    canvas.drawLine(
        Offset(tongueX - 2 * k, y),
        Offset(tongueX + 9 * k, y),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF15171A));
    // A finger grip while it is still loose.
    if (!locked) {
      final g = Offset(tongueX - 9 * k, y);
      canvas.drawCircle(g, 17 * k, Paint()..color = SlmColors.gold500.withValues(alpha: 0.18));
      canvas.drawCircle(
        g,
        17 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = SlmColors.gold500.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(ChinStrapPainter old) => old.locked != locked || old.broken != broken || old.t != t;
}
