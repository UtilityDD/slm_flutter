import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'zero_loss_models.dart';
import 'zero_loss_places.dart';

// ---------------------------------------------------------------------------
// Setup: load the scenario template and pick a real West Bengal place.
// ---------------------------------------------------------------------------

class ZeroLossSetup {
  final ZeroLossScenario scenario;
  final ZeroLossSetting setting;
  final int seed;

  const ZeroLossSetup({required this.scenario, required this.setting, required this.seed});
}

Future<ZeroLossScenario> loadZeroLossScenario() async {
  final raw = await rootBundle.loadString('assets/data/zero_loss_storm_feeder.json');
  return ZeroLossScenario.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Picks a random district that the scenario knows, with a supply office and
/// two fault sites in real towns of that district, all in Bangla.
ZeroLossSetting pickZeroLossSetting(ZeroLossScenario scenario, Random rng) {
  final districts = scenario.districtNamesBn.keys.toList()..sort();
  final district = districts[rng.nextInt(districts.length)];
  final districtBn = scenario.districtNamesBn[district] ?? district;
  final towns = [...?zeroLossTownsBn[district]]..shuffle(rng);
  String town(int i) => i < towns.length ? towns[i] : districtBn;

  return ZeroLossSetting(
    district: district,
    districtBn: districtBn,
    office: '${town(0)} সাপ্লাই অফিস',
    placeA: towns.length > 1 ? town(1) : 'হাটতলা',
    placeB: towns.length > 2 ? town(2) : 'বাজারপাড়া',
    hospital: '$districtBn জেলা হাসপাতাল',
    region: scenario.regionFor(district),
  );
}

Future<ZeroLossSetup> createZeroLossSetup({int? seed, List<String>? jobIds, bool randomize = false}) async {
  final s = seed ?? DateTime.now().millisecondsSinceEpoch;
  final rng = Random(s);
  final master = await loadZeroLossScenario();
  final setting = pickZeroLossSetting(master, rng);

  final catalog = master.catalog.isNotEmpty ? master.catalog : master.faults;
  List<FaultDispatch> activeFaults;

  if (jobIds != null && jobIds.isNotEmpty) {
    activeFaults = [
      for (var i = 0; i < min(1, jobIds.length); i++)
        catalog.firstWhere((f) => f.id == jobIds[i], orElse: () => catalog[0]).copyWith(slot: 'A'),
    ];
  } else if (randomize) {
    // One random job per game — clearer story, easier UX.
    final shuffled = [...catalog]..shuffle(rng);
    activeFaults = [shuffled.first.copyWith(slot: 'A')];
  } else {
    final wire = catalog.firstWhere((f) => f.id == 'wire_on_ground', orElse: () => catalog[0]);
    activeFaults = [wire.copyWith(slot: 'A')];
  }

  // Stamp a weather mood so not every run is storm-night.
  final moods = JobMood.values;
  activeFaults = [
    for (final f in activeFaults)
      f.mood != null ? f : f.copyWith(mood: moods[rng.nextInt(moods.length)]),
  ];

  final scenario = master.copyWith(faults: activeFaults, catalog: catalog);
  return ZeroLossSetup(scenario: scenario, setting: setting, seed: s);
}

// ---------------------------------------------------------------------------
// Game state
// ---------------------------------------------------------------------------

/// Points and meter changes during a shift.
class ZeroLossPoints {
  static const decision = 20;
  static const restore = 100;
  static const onTime = 50;
  static const zeroLoss = 200;

  static const wrongDecision = 15;
  static const chantMistake = 5;
  static const chantMistakeCap = 3;
  static const decoy = 5;
  static const shortcut = 15;

  static const reload = 10;
  static const missingJob = 10;
  static const late = 20;
  static const accident = 150;
  static const complaint = 5;
  static const complaintCap = 3;

  static const accidentSafety = 40;
  static const accidentSatisfaction = 20;
  static const lateSatisfaction = 15;
  static const wrongWearSafety = 3;
  static const shortcutSafety = 10;
  static const complaintSatisfaction = 2;
}

/// যোগ = earned, বিয়োগ = a safety fault, শাস্তি = the cost of time, money or a hurt crew.
enum ScoreKind { add, deduct, penalty }

enum ScoreCause {
  decision(ScoreKind.add, 'সঠিক সিদ্ধান্ত'),
  chant(ScoreKind.add, 'নিখুঁত মন্ত্র'),
  restore(ScoreKind.add, 'লাইন চালু'),
  onTime(ScoreKind.add, 'সময়ে শেষ'),
  zeroLoss(ScoreKind.add, 'জিরো লস'),
  wrongDecision(ScoreKind.deduct, 'ভুল সিদ্ধান্ত'),
  chantMistake(ScoreKind.deduct, 'মন্ত্রে ভুল'),
  decoy(ScoreKind.deduct, 'ভুল সরঞ্জাম'),
  shortcut(ScoreKind.deduct, 'শর্টকাট'),
  reload(ScoreKind.penalty, 'আবার লোড'),
  missingJob(ScoreKind.penalty, 'মাল আনা হয়নি'),
  late(ScoreKind.penalty, 'দেরি'),
  dutyBonus(ScoreKind.add, 'ডিউটি বোনাস'),
  accident(ScoreKind.penalty, 'দুর্ঘটনা'),
  complaint(ScoreKind.penalty, 'গ্রাহকের নালিশ');

  /// Visible during a duty shift: what a real crew would notice at once.
  bool get liveInDuty => switch (this) {
        reload || missingJob || late || complaint || restore || onTime || chant || chantMistake || accident => true,
        _ => false,
      };

  const ScoreCause(this.kind, this.labelBn);
  final ScoreKind kind;
  final String labelBn;
}

class ScoreEntry {
  final ScoreCause cause;

  /// Signed: positive for additions, negative otherwise.
  final int points;
  final String? faultId;

  const ScoreEntry(this.cause, this.points, {this.faultId});

  ScoreKind get kind => cause.kind;
}

/// অনুশীলন: right/wrong after every step. ডিউটি: no step alerts, the truth comes at the end.
enum ZeroLossMode { practice, duty }

/// One thing that raised a mission's accident risk, and what it would cause.
class RiskFactor {
  final String cause;
  final double risk;
  final String? gearId;

  /// The decoy worn instead of [gearId], if any.
  final String? decoyId;
  final String? eventId;
  final String? optionId;
  final String? linemanId;
  final bool fatigue;

  const RiskFactor({
    required this.cause,
    required this.risk,
    this.gearId,
    this.decoyId,
    this.eventId,
    this.optionId,
    this.linemanId,
    this.fatigue = false,
  });
}

enum ZeroLossPhase { briefing, tbtPreview, map, armour, loading, chant, site, outcome, debrief }

enum MissionStage { waiting, armour, loading, onSite, done }

enum MissionOutcome { safe, lucky, accident }

/// Result of putting a body item on a lineman.
enum WearResult { worn, removed, wrong, notNeeded, ignored }

class DecisionRecord {
  final String faultId;
  final HazardEvent event;
  final HazardOption option;

  const DecisionRecord({required this.faultId, required this.event, required this.option});
}

/// One truck going to one fault.
class DispatchMission {
  final String id;
  final String location;
  final List<String> assignedCrew;
  final List<Gear> packedGear;
  final int remainingTimeSeconds;
  final MissionStage stage;
  final int eventIndex;
  final int minutesUsed;
  final double choiceRisk;
  final List<String> missingSafety;
  final List<String> missingJob;
  final List<DecisionRecord> decisions;
  final MissionOutcome? outcome;
  final String? injuredCrewId;
  final double finalRisk;

  /// What caused the accident, when there was one.
  final RiskFactor? accident;

  /// Body PPE worn, per lineman id.
  final Map<String, List<String>> worn;
  final List<String> wrongWorn;
  final int? chantMistakes;
  final int complaints;

  /// Silent mistake seeds (no_barricade, no_harness, no_earth, no_ppe, no_ptw…).
  final List<String> riskSeeds;

  /// Site work flags: barricade, ptw, earth, loto, climbed, worked, counted, dangers.
  final Set<String> siteFlags;
  final int siteActions;
  final String? activeBloom;

  /// Last order per lineman id (`ppe`, `ptw`, `loto`, `climb`…). Survives panel close.
  final Map<String, String> crewOrders;

  /// Normalized cone positions 0–1 for multi-barricade placement.
  final List<(double, double)> barricadeSpots;

  const DispatchMission({
    required this.id,
    required this.location,
    this.complaints = 0,
    this.worn = const {},
    this.wrongWorn = const [],
    this.chantMistakes,
    this.assignedCrew = const [],
    this.packedGear = const [],
    this.remainingTimeSeconds = 0,
    this.stage = MissionStage.waiting,
    this.eventIndex = 0,
    this.minutesUsed = 0,
    this.choiceRisk = 0,
    this.missingSafety = const [],
    this.missingJob = const [],
    this.decisions = const [],
    this.outcome,
    this.injuredCrewId,
    this.finalRisk = 0,
    this.accident,
    this.riskSeeds = const [],
    this.siteFlags = const {},
    this.siteActions = 0,
    this.activeBloom,
    this.crewOrders = const {},
    this.barricadeSpots = const [],
  });

  bool isPacked(String gearId) => packedGear.any((g) => g.id == gearId);

  List<String> wornBy(String linemanId) => worn[linemanId] ?? const [];

  bool hasFlag(String f) => siteFlags.contains(f);

  String orderOf(String linemanId) => crewOrders[linemanId] ?? '';

  DispatchMission copyWith({
    Map<String, List<String>>? worn,
    List<String>? wrongWorn,
    int? chantMistakes,
    int? complaints,
    List<String>? assignedCrew,
    List<Gear>? packedGear,
    int? remainingTimeSeconds,
    MissionStage? stage,
    int? eventIndex,
    int? minutesUsed,
    double? choiceRisk,
    List<String>? missingSafety,
    List<String>? missingJob,
    List<DecisionRecord>? decisions,
    MissionOutcome? outcome,
    String? injuredCrewId,
    double? finalRisk,
    RiskFactor? accident,
    List<String>? riskSeeds,
    Set<String>? siteFlags,
    int? siteActions,
    String? activeBloom,
    bool clearBloom = false,
    Map<String, String>? crewOrders,
    List<(double, double)>? barricadeSpots,
  }) =>
      DispatchMission(
        id: id,
        location: location,
        worn: worn ?? this.worn,
        wrongWorn: wrongWorn ?? this.wrongWorn,
        chantMistakes: chantMistakes ?? this.chantMistakes,
        complaints: complaints ?? this.complaints,
        assignedCrew: assignedCrew ?? this.assignedCrew,
        packedGear: packedGear ?? this.packedGear,
        remainingTimeSeconds: remainingTimeSeconds ?? this.remainingTimeSeconds,
        stage: stage ?? this.stage,
        eventIndex: eventIndex ?? this.eventIndex,
        minutesUsed: minutesUsed ?? this.minutesUsed,
        choiceRisk: choiceRisk ?? this.choiceRisk,
        missingSafety: missingSafety ?? this.missingSafety,
        missingJob: missingJob ?? this.missingJob,
        decisions: decisions ?? this.decisions,
        outcome: outcome ?? this.outcome,
        injuredCrewId: injuredCrewId ?? this.injuredCrewId,
        finalRisk: finalRisk ?? this.finalRisk,
        accident: accident ?? this.accident,
        riskSeeds: riskSeeds ?? this.riskSeeds,
        siteFlags: siteFlags ?? this.siteFlags,
        siteActions: siteActions ?? this.siteActions,
        activeBloom: clearBloom ? null : (activeBloom ?? this.activeBloom),
        crewOrders: crewOrders ?? this.crewOrders,
        barricadeSpots: barricadeSpots ?? this.barricadeSpots,
      );
}

/// Result of a dispatch attempt. When [ok] is false the player must choose
/// [SmartLinemanDispatchNotifier.reloadTruck] or [SmartLinemanDispatchNotifier.takeShortcut].
class DispatchCheck {
  final bool ok;
  final List<Gear> missingSafety;
  final List<Gear> missingJob;
  final List<Gear> decoys;

  const DispatchCheck({
    required this.ok,
    this.missingSafety = const [],
    this.missingJob = const [],
    this.decoys = const [],
  });
}

class ZeroLossState {
  final ZeroLossScenario scenario;
  final ZeroLossSetting setting;
  final int seed;
  final ZeroLossPhase phase;
  final List<SmartLineman> crew;
  final Map<String, DispatchMission> missions;
  final String? selectedFaultId;
  final String? activeFaultId;
  final HazardOption? pendingFeedback;
  final DispatchCheck? pendingCheck;
  final int safety;
  final int satisfaction;
  final int tokens;
  final List<ScoreEntry> ledger;
  final ZeroLossMode mode;

  const ZeroLossState({
    required this.scenario,
    required this.setting,
    required this.seed,
    required this.phase,
    required this.crew,
    required this.missions,
    required this.safety,
    required this.satisfaction,
    required this.tokens,
    this.mode = ZeroLossMode.practice,
    this.ledger = const [],
    this.selectedFaultId,
    this.activeFaultId,
    this.pendingFeedback,
    this.pendingCheck,
  });

  bool get duty => mode == ZeroLossMode.duty;

  int get points => ledger.fold(0, (sum, e) => sum + e.points);

  int pointsOf(ScoreKind kind) => ledger.where((e) => e.kind == kind).fold(0, (sum, e) => sum + e.points);

  FaultDispatch fault(String id) => scenario.faults.firstWhere((f) => f.id == id);
  DispatchMission mission(String id) => missions[id]!;
  SmartLineman lineman(String id) => crew.firstWhere((c) => c.id == id);

  /// Fault the crew dock assigns to: the active one while loading, else the selected one.
  String? get focusFaultId => activeFaultId ?? selectedFaultId;

  String? assignedFault(String linemanId) {
    for (final m in missions.values) {
      if (m.assignedCrew.contains(linemanId)) return m.id;
    }
    return null;
  }

  bool get allDone => missions.values.every((m) => m.stage == MissionStage.done);
  bool get zeroLoss => allDone && missions.values.every((m) => m.outcome != MissionOutcome.accident);

  int finishMinute(String faultId) {
    final f = fault(faultId);
    final m = mission(faultId);
    return 5 + f.travelMinutes + setting.region.travelExtraMinutes + m.minutesUsed + f.repairMinutes;
  }

  bool isLate(String faultId) => finishMinute(faultId) > fault(faultId).urgencyMinutes;

  List<SmartLineman> _teamBySafety(String faultId) =>
      [for (final id in mission(faultId).assignedCrew) lineman(id)]
        ..sort((a, b) => b.safetyRating.compareTo(a.safetyRating));

  /// Most careful member of the team; speaks the sensible lines.
  SmartLineman? leadOf(String faultId) {
    final t = _teamBySafety(faultId);
    return t.isEmpty ? null : t.first;
  }

  /// Least careful member; the one tempted by shortcuts.
  SmartLineman? juniorOf(String faultId) {
    final t = _teamBySafety(faultId);
    return t.length < 2 ? null : t.last;
  }

  String fillFor(String faultId, String template, {String crew = ''}) => setting.fill(
        template,
        crew: crew,
        lead: leadOf(faultId)?.name ?? 'দাদা',
        junior: juniorOf(faultId)?.name ?? 'হেল্পার',
      );

  List<String> bodyKit(String faultId) => scenario.bodyKitFor(fault(faultId));

  /// Required vs not-required kit for the whole shift (TBT preview).
  ShiftKitPreview get shiftKit {
    final bodyNeed = <String>{};
    final truckNeed = <String>{};
    for (final f in scenario.faults) {
      bodyNeed.addAll(scenario.bodyKitFor(f));
      truckNeed.addAll(f.requiredGear);
      truckNeed.addAll(f.jobGear);
    }
    Gear g(String id) => scenario.gearById(id);
    return ShiftKitPreview(
      requiredBody: [for (final id in bodyNeed) g(id)],
      requiredTruck: [for (final id in truckNeed) g(id)],
      notRequiredBody: [
        for (final gear in scenario.bodyGear)
          if (!bodyNeed.contains(gear.id)) gear,
      ],
      notRequiredTruck: [
        for (final gear in scenario.truckGear)
          if (!truckNeed.contains(gear.id)) gear,
      ],
    );
  }

  /// Per mantra: `true` kept, `false` broken, absent = not tested yet.
  /// Pass [faultId] for one mission, or leave null for the whole shift.
  Map<String, bool> mantraReport([String? faultId]) {
    final report = <String, bool>{};
    void mark(String mantra, bool ok) => report[mantra] = (report[mantra] ?? true) && ok;
    for (final f in scenario.faults) {
      if (faultId != null && f.id != faultId) continue;
      final m = mission(f.id);
      if (m.stage == MissionStage.waiting) continue;
      if (m.stage != MissionStage.armour) mark('armour', true);
      for (final id in m.wrongWorn) {
        mark(scenario.gearById(id).mantra, false);
      }
      if (m.stage != MissionStage.armour) {
        for (final (_, gearId) in missingBody(f.id)) {
          mark(scenario.gearById(gearId).mantra, false);
        }
      }
      if (m.stage == MissionStage.onSite || m.stage == MissionStage.done) {
        for (final id in f.requiredGear) {
          mark(scenario.gearById(id).mantra, !m.missingSafety.contains(id));
        }
        for (final g in m.packedGear.where((g) => g.kind == GearKind.decoy)) {
          mark(g.mantra, false);
        }
      }
      for (final d in m.decisions) {
        mark(d.event.mantra, d.option.best);
      }
      if (m.stage == MissionStage.done && m.decisions.isNotEmpty) mark('mend', m.outcome != MissionOutcome.accident);
    }
    return report;
  }

  bool isDressed(String faultId) => missingBody(faultId).isEmpty;

  /// (lineman id, kit item) for every personal PPE item not worn.
  List<(String, String)> missingBody(String faultId) {
    final m = mission(faultId);
    final kit = bodyKit(faultId);
    return [
      for (final id in m.assignedCrew)
        for (final g in kit)
          if (!m.wornBy(id).contains(g)) (id, g),
    ];
  }

  /// The lineman looks ready: in practice every kit item is on, on duty every slot is filled with something.
  bool looksReady(String faultId, String linemanId) {
    final w = mission(faultId).wornBy(linemanId);
    final kit = bodyKit(faultId);
    if (!duty) return kit.every(w.contains);
    String slot(String id) => scenario.gearById(id).bodySlot;
    return kit.every((k) => w.any((x) => slot(x) == slot(k)));
  }

  /// The decoy a lineman wears in the slot of [gearId], if any.
  String? decoyInSlot(String faultId, String linemanId, String gearId) {
    final slot = scenario.gearById(gearId).bodySlot;
    for (final id in mission(faultId).wornBy(linemanId)) {
      final g = scenario.gearById(id);
      if (g.kind == GearKind.decoy && g.bodySlot == slot) return id;
    }
    return null;
  }

  ZeroLossState copyWith({
    ZeroLossPhase? phase,
    List<SmartLineman>? crew,
    Map<String, DispatchMission>? missions,
    String? selectedFaultId,
    String? activeFaultId,
    bool clearActive = false,
    HazardOption? pendingFeedback,
    bool clearFeedback = false,
    DispatchCheck? pendingCheck,
    bool clearCheck = false,
    int? safety,
    int? satisfaction,
    int? tokens,
    ZeroLossMode? mode,
    List<ScoreEntry> score = const [],
  }) =>
      ZeroLossState(
        scenario: scenario,
        setting: setting,
        seed: seed,
        phase: phase ?? this.phase,
        crew: crew ?? this.crew,
        missions: missions ?? this.missions,
        selectedFaultId: selectedFaultId ?? this.selectedFaultId,
        activeFaultId: clearActive ? null : (activeFaultId ?? this.activeFaultId),
        pendingFeedback: clearFeedback ? null : (pendingFeedback ?? this.pendingFeedback),
        pendingCheck: clearCheck ? null : (pendingCheck ?? this.pendingCheck),
        safety: (safety ?? this.safety).clamp(0, 100),
        satisfaction: (satisfaction ?? this.satisfaction).clamp(0, 100),
        tokens: tokens ?? this.tokens,
        mode: mode ?? this.mode,
        ledger: score.isEmpty ? ledger : [...ledger, ...score],
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Drives one play of জিরো লস.
///
/// Usage:
/// ```dart
/// final setup = await createZeroLossSetup();
/// ref.read(zeroLossProvider.notifier).begin(setup);
/// ```
/// Then the page reacts to [ZeroLossState.phase]:
/// briefing → map (pick fault, [assignLineman]) → loading ([toggleGear], [tick], [dispatchTruck])
/// → site ([chooseOption], [continueAfterFeedback]) → outcome → map … → debrief.
class SmartLinemanDispatchNotifier extends Notifier<ZeroLossState?> {
  late Random _rng;

  @override
  ZeroLossState? build() => null;

  void begin(ZeroLossSetup setup) {
    final scenario = setup.scenario;
    _rng = Random(setup.seed);
    state = ZeroLossState(
      scenario: scenario,
      setting: setup.setting,
      seed: setup.seed,
      phase: ZeroLossPhase.briefing,
      crew: scenario.crew,
      missions: {
        for (final f in scenario.faults)
          f.id: DispatchMission(id: f.id, location: f.slot == 'A' ? setup.setting.placeA : setup.setting.placeB),
      },
      selectedFaultId: scenario.faults.first.id,
      safety: scenario.startSafety,
      satisfaction: scenario.startSatisfaction,
      tokens: scenario.budgetTokens,
    );
  }

  ZeroLossState get _s => state!;

  void _putMission(DispatchMission m) => state = _s.copyWith(missions: {..._s.missions, m.id: m});

  void startShift({ZeroLossMode mode = ZeroLossMode.practice}) =>
      state = _s.copyWith(phase: ZeroLossPhase.map, mode: mode);

  void leaveTbtPreview() => state = _s.copyWith(phase: ZeroLossPhase.map);

  void selectFault(String faultId) => state = _s.copyWith(selectedFaultId: faultId);

  /// Adds or removes a lineman on the focused fault. Injured or busy crew are ignored.
  void assignLineman(String id) {
    final faultId = _s.focusFaultId;
    if (faultId == null) return;
    final m = _s.mission(faultId);
    if (m.stage != MissionStage.waiting) return;
    final man = _s.lineman(id);
    if (man.isInjured) return;
    final elsewhere = _s.assignedFault(id);
    if (elsewhere != null && elsewhere != faultId) return;
    if (m.assignedCrew.contains(id)) {
      _putMission(m.copyWith(assignedCrew: [...m.assignedCrew]..remove(id)));
      return;
    }
    if (m.assignedCrew.length >= _s.fault(faultId).requiredCrewCount) return;
    _putMission(m.copyWith(assignedCrew: [...m.assignedCrew, id]));
  }

  /// Team is complete: ready to put on personal PPE.
  bool canDress(String faultId) {
    final m = _s.mission(faultId);
    return m.stage == MissionStage.waiting && m.assignedCrew.length == _s.fault(faultId).requiredCrewCount;
  }

  void openArmour(String faultId) {
    if (!canDress(faultId)) return;
    final m = _s.mission(faultId);
    _putMission(m.copyWith(stage: MissionStage.armour, worn: const {}, wrongWorn: const []));
    state = _s.copyWith(phase: ZeroLossPhase.armour, activeFaultId: faultId, clearCheck: true);
  }

  /// Puts a body item on (or takes it off) a lineman of the active team.
  /// Decoys cost safety/points; on duty they go on (mistake enters the run).
  WearResult wearGear(String linemanId, String gearId) {
    final faultId = _s.activeFaultId;
    if (faultId == null || (_s.phase != ZeroLossPhase.armour && _s.phase != ZeroLossPhase.site)) {
      return WearResult.ignored;
    }
    final m = _s.mission(faultId);
    if (!m.assignedCrew.contains(linemanId)) return WearResult.ignored;
    final gear = _s.scenario.gearById(gearId);
    if (gear.area != GearArea.body) return WearResult.ignored;
    final current = m.wornBy(linemanId);
    if (current.contains(gearId)) {
      _putMission(m.copyWith(worn: {...m.worn, linemanId: [...current]..remove(gearId)}));
      return WearResult.removed;
    }
    if (gear.kind == GearKind.decoy) {
      final first = !m.wrongWorn.contains(gearId);
      _putMission(m.copyWith(
        wrongWorn: {...m.wrongWorn, gearId}.toList(),
        // On duty nobody stops you: the decoy goes on, in place of the real item.
        worn: _s.duty ? {...m.worn, linemanId: [..._withoutSlot(current, gear.bodySlot), gearId]} : null,
      ));
      state = _s.copyWith(
        safety: _s.safety - ZeroLossPoints.wrongWearSafety,
        score: [if (first) ScoreEntry(ScoreCause.decoy, -ZeroLossPoints.decoy, faultId: faultId)],
      );
      return _s.duty ? WearResult.worn : WearResult.wrong;
    }
    if (!_s.bodyKit(faultId).contains(gearId)) return WearResult.notNeeded;
    _putMission(m.copyWith(worn: {...m.worn, linemanId: [..._withoutSlot(current, gear.bodySlot), gearId]}));
    return WearResult.worn;
  }

  List<String> _withoutSlot(List<String> worn, String slot) =>
      worn.where((id) => _s.scenario.gearById(id).bodySlot != slot).toList();

  /// Put several body items on one lineman in a single update (site multi-PPE tray).
  /// Returns how many items were newly worn.
  int wearGearBatch(String linemanId, List<String> gearIds) {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.phase != ZeroLossPhase.site) return 0;
    final m = _s.mission(faultId);
    if (!m.assignedCrew.contains(linemanId)) return 0;
    var worn = [...m.wornBy(linemanId)];
    final wrong = {...m.wrongWorn};
    var added = 0;
    var safetyHit = 0;
    final score = <ScoreEntry>[];
    final kit = _s.bodyKit(faultId);
    for (final gearId in gearIds) {
      final gear = _s.scenario.gearById(gearId);
      if (gear.area != GearArea.body) continue;
      if (worn.contains(gearId)) continue;
      if (gear.kind == GearKind.decoy) {
        if (!wrong.contains(gearId)) {
          wrong.add(gearId);
          score.add(ScoreEntry(ScoreCause.decoy, -ZeroLossPoints.decoy, faultId: faultId));
        }
        safetyHit += ZeroLossPoints.wrongWearSafety;
        if (_s.duty) {
          worn = [..._withoutSlot(worn, gear.bodySlot), gearId];
          added++;
        }
        continue;
      }
      if (!kit.contains(gearId)) continue;
      worn = [..._withoutSlot(worn, gear.bodySlot), gearId];
      added++;
    }
    if (added == 0 && score.isEmpty) return 0;
    final flags = {...m.siteFlags};
    final seeds = [...m.riskSeeds];
    if (kit.every(worn.contains)) {
      flags.add('ppe');
      seeds.remove('no_ppe');
      seeds.remove('no_harness');
    } else if (worn.contains('harness')) {
      seeds.remove('no_harness');
    }
    if (wrong.isNotEmpty) {
      if (!seeds.contains('bad_ppe')) seeds.add('bad_ppe');
    }
    _putMission(m.copyWith(
      worn: {...m.worn, linemanId: worn},
      wrongWorn: wrong.toList(),
      siteFlags: flags,
      riskSeeds: seeds,
      siteActions: m.siteActions + (added > 0 ? 1 : 0),
      crewOrders: added > 0 ? {...m.crewOrders, linemanId: 'ppe'} : null,
    ));
    if (safetyHit > 0 || score.isNotEmpty) {
      state = _s.copyWith(safety: _s.safety - safetyHit, score: score);
    }
    return added;
  }

  /// Why an act is blocked right now (empty = allowed). Used by site UI.
  String siteActBlockReason(String action, {String? crewId}) {
    final faultId = _s.activeFaultId;
    if (faultId == null) return 'সাইট নেই';
    final f = _s.fault(faultId);
    final m = _s.mission(faultId);
    if (m.activeBloom != null && action != 'handle_bloom' && action != 'clear_public' && action != 'finish') {
      if (m.activeBloom == 'crowd' || m.activeBloom == 'vehicle') {
        if (action != 'clear_public') return 'আগে লোক / গাড়ি সরান';
      } else {
        return 'আগে এই বিপদ সামলান';
      }
    }
    switch (action) {
      case 'climb':
        if (f.work != FaultWork.climb) return 'এই কাজ মাটিতে';
        if (m.hasFlag('climbed')) return 'ইতিমধ্যে উঠেছেন';
      case 'work':
        if (f.work == FaultWork.climb && !m.hasFlag('climbed')) return 'আগে খুঁটিতে উঠুন';
        if (m.hasFlag('worked')) return 'মেরামত চলছে / হয়ে গেছে';
      case 'clear_public':
        if (m.activeBloom != 'crowd' && m.activeBloom != 'vehicle') {
          return 'এখন কেউ আসেনি';
        }
      case 'barricade':
        if (m.hasFlag('barricade')) return 'ব্যারিকেড আছে';
      case 'ptw':
        if (m.hasFlag('ptw')) return 'পিটিডব্লিউ চেক হয়েছে';
      case 'earth':
        if (m.hasFlag('earth')) return 'আর্থ হয়ে গেছে';
      case 'loto':
        if (!m.hasFlag('earth')) return 'আগে টেস্ট ও আর্থ করুন';
        if (m.hasFlag('loto')) return 'লোটো লাগানো আছে';
      case 'ppe':
        if (crewId == null) return 'লাইন্ম্যান বাছুন';
    }
    return '';
  }

  /// Drop one cone (normalized 0–1). Needs ≥2 then [confirmBarricade].
  String placeBarricadeSpot(double x, double y) {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.phase != ZeroLossPhase.site) return '';
    final m = _s.mission(faultId);
    if (m.hasFlag('barricade')) return 'ব্যারিকেড আছে';
    if (m.barricadeSpots.length >= 4) return 'কোন যথেষ্ট — নিশ্চিত করুন';
    final nx = x.clamp(0.08, 0.92);
    final ny = y.clamp(0.55, 0.92);
    _putMission(m.copyWith(barricadeSpots: [...m.barricadeSpots, (nx, ny)]));
    return 'কোন ${m.barricadeSpots.length + 1}';
  }

  void undoBarricadeSpot() {
    final faultId = _s.activeFaultId;
    if (faultId == null) return;
    final m = _s.mission(faultId);
    if (m.hasFlag('barricade') || m.barricadeSpots.isEmpty) return;
    _putMission(m.copyWith(barricadeSpots: m.barricadeSpots.sublist(0, m.barricadeSpots.length - 1)));
  }

  /// Close the barricade line (≥2 cones) and assign order to [crewId].
  String confirmBarricade(String crewId) {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.phase != ZeroLossPhase.site) return '';
    final m = _s.mission(faultId);
    if (m.hasFlag('barricade')) return 'ব্যারিকেড আছে';
    if (m.barricadeSpots.length < 2) return 'কমপক্ষে 2টি কোন বসান';
    return workSiteAct(crewId, 'barricade');
  }

  /// Team complete → tools. PPE is done later on site (no armour gate).
  bool canLoad(String faultId) {
    final m = _s.mission(faultId);
    if (m.assignedCrew.length != _s.fault(faultId).requiredCrewCount) return false;
    if (m.stage == MissionStage.waiting) return true;
    return m.stage == MissionStage.armour && (_s.duty || _s.isDressed(faultId));
  }

  void openLoading(String faultId) {
    if (!canLoad(faultId)) return;
    final m = _s.mission(faultId);
    _putMission(m.copyWith(
      stage: MissionStage.loading,
      remainingTimeSeconds: _s.scenario.loadingSeconds,
      packedGear: const [],
      worn: m.stage == MissionStage.waiting ? const {} : m.worn,
      wrongWorn: m.stage == MissionStage.waiting ? const [] : m.wrongWorn,
    ));
    state = _s.copyWith(phase: ZeroLossPhase.loading, activeFaultId: faultId, clearCheck: true);
  }

  /// Packs or unpacks a gear item on the active truck, within capacity.
  /// [offer] lets the yard pack Parichiti / extra items not in the scenario gear list.
  void toggleGear(String gearId, {Gear? offer}) {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.pendingCheck != null) return;
    final m = _s.mission(faultId);
    if (m.isPacked(gearId)) {
      _putMission(m.copyWith(packedGear: m.packedGear.where((g) => g.id != gearId).toList()));
      return;
    }
    if (m.packedGear.length >= _s.scenario.truckCapacity) return;
    final Gear g;
    if (offer != null) {
      g = offer.copyWith(isPacked: true);
    } else if (_s.scenario.gear.any((x) => x.id == gearId)) {
      g = _s.scenario.gearById(gearId).copyWith(isPacked: true);
    } else {
      return;
    }
    _putMission(m.copyWith(packedGear: [...m.packedGear, g]));
  }

  /// One second of loading time. Returns true when time ran out and a dispatch was forced.
  bool tick() {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.phase != ZeroLossPhase.loading || _s.pendingCheck != null) return false;
    final m = _s.mission(faultId);
    final left = m.remainingTimeSeconds - 1;
    _putMission(m.copyWith(remainingTimeSeconds: max(0, left)));
    if (left <= 0) {
      dispatchTruck();
      return true;
    }
    return false;
  }

  /// Checks the truck. Missing safety gear stops the dispatch until the player
  /// reloads or knowingly takes the shortcut.
  DispatchCheck dispatchTruck() {
    final faultId = _s.activeFaultId!;
    final f = _s.fault(faultId);
    final m = _s.mission(faultId);
    final check = DispatchCheck(
      ok: f.requiredGear.every(m.isPacked) && f.jobGear.every(m.isPacked),
      missingSafety: [for (final id in f.requiredGear) if (!m.isPacked(id)) _s.scenario.gearById(id)],
      missingJob: [for (final id in f.jobGear) if (!m.isPacked(id)) _s.scenario.gearById(id)],
      decoys: m.packedGear.where((g) => g.kind == GearKind.decoy).toList(),
    );
    if (check.ok) {
      _depart(faultId, missingSafety: const [], missingJob: const []);
    } else if (_s.duty) {
      state = _s.copyWith(pendingCheck: check);
      takeShortcut();
    } else {
      state = _s.copyWith(pendingCheck: check);
    }
    return check;
  }

  /// Goes back to the depot: costs time, tokens and public patience.
  void reloadTruck() {
    final faultId = _s.activeFaultId!;
    final m = _s.mission(faultId);
    final sc = _s.scenario;
    _putMission(m.copyWith(
      remainingTimeSeconds: sc.reloadSeconds,
      minutesUsed: m.minutesUsed + sc.reloadMinutes,
    ));
    state = _s.copyWith(
      clearCheck: true,
      tokens: max(0, _s.tokens - sc.reloadTokens),
      satisfaction: _s.satisfaction + sc.reloadSatisfaction,
      score: [ScoreEntry(ScoreCause.reload, -ZeroLossPoints.reload, faultId: faultId)],
    );
  }

  /// Leaves without the missing items. Each missing safety item raises accident risk.
  void takeShortcut() {
    final check = _s.pendingCheck!;
    final faultId = _s.activeFaultId!;
    state = _s.copyWith(
      clearCheck: true,
      safety: _s.safety - ZeroLossPoints.shortcutSafety * check.missingSafety.length,
      score: [
        for (final _ in check.missingSafety) ScoreEntry(ScoreCause.shortcut, -ZeroLossPoints.shortcut, faultId: faultId),
      ],
    );
    _depart(
      faultId,
      missingSafety: check.missingSafety.map((g) => g.id).toList(),
      missingJob: check.missingJob.map((g) => g.id).toList(),
    );
  }

  void _depart(String faultId, {required List<String> missingSafety, required List<String> missingJob}) {
    final m = _s.mission(faultId);
    _putMission(m.copyWith(
      stage: MissionStage.onSite,
      eventIndex: 0,
      missingSafety: missingSafety,
      missingJob: missingJob,
      // Forgot the part for the job: a second trip later.
      minutesUsed: m.minutesUsed + missingJob.length * _s.scenario.reloadMinutes * 2,
    ));
    state = _s.copyWith(
      // Skip chant gate — TBT already played in opening; go straight to site work.
      phase: ZeroLossPhase.site,
      satisfaction: _s.satisfaction - missingJob.length * 8,
      tokens: max(0, _s.tokens - missingJob.length * _s.scenario.reloadTokens),
      score: [
        for (final _ in m.packedGear.where((g) => g.kind == GearKind.decoy))
          ScoreEntry(ScoreCause.decoy, -ZeroLossPoints.decoy, faultId: faultId),
        for (final _ in missingJob) ScoreEntry(ScoreCause.missingJob, -ZeroLossPoints.missingJob, faultId: faultId),
      ],
    );
  }

  /// Site work panel: plant/clear silent seeds; delayed blooms; finish → resolve.
  /// Returns a short Bangla beat line for the UI (empty if nothing to say).
  String workSiteAct(String crewId, String action, {String? gearId}) {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.phase != ZeroLossPhase.site) return '';
    var m = _s.mission(faultId);
    if (m.outcome != null) return '';
    if (action == 'dangers_done') {
      _putMission(m.copyWith(siteFlags: {...m.siteFlags, 'dangers'}));
      return 'বিপদ চোখে পড়েছে';
    }
    if (!m.assignedCrew.contains(crewId) && action != 'finish') return '';
    final block = siteActBlockReason(action, crewId: crewId);
    if (block.isNotEmpty && action != 'finish' && action != 'ppe') return block;

    final flags = {...m.siteFlags};
    final seeds = [...m.riskSeeds];
    var score = <ScoreEntry>[];
    var line = '';
    var bloom = m.activeBloom;
    final f = _s.fault(faultId);

    void plant(String seed) {
      if (!seeds.contains(seed)) seeds.add(seed);
    }

    void clearSeed(String seed) => seeds.remove(seed);

    final orders = {...m.crewOrders};

    switch (action) {
      case 'barricade':
        if (m.barricadeSpots.length < 2) return 'কমপক্ষে 2টি কোন বসান';
        flags.add('barricade');
        clearSeed('no_barricade');
        orders[crewId] = 'barricade';
        line = 'ফিতে ও কোন দিয়ে জায়গা ঘেরা হল';
        score.add(ScoreEntry(ScoreCause.decision, 8, faultId: faultId));
      case 'clear_public':
        if (bloom != 'crowd' && bloom != 'vehicle') return 'এখন কেউ আসেনি';
        flags.add('public_clear');
        clearSeed('crowd');
        clearSeed('no_barricade');
        orders[crewId] = 'clear_public';
        bloom = null;
        score.add(ScoreEntry(ScoreCause.decision, 12, faultId: faultId));
        line = 'লোক / রাস্তা সামলানো হল';
      case 'ptw':
        // PTW = carefully check the permit document (not LOTO).
        flags.add('ptw');
        clearSeed('no_ptw');
        orders[crewId] = 'ptw';
        line = 'পিটিডব্লিউ ফর্ম মিলিয়ে দেখা হল';
        score.add(ScoreEntry(ScoreCause.decision, 6, faultId: faultId));
      case 'earth':
        flags.add('earth');
        clearSeed('no_earth');
        orders[crewId] = 'earth';
        line = 'টেস্ট ও আর্থ হয়ে গেল';
      case 'loto':
        // LOTO = lock & tag the isolated / earthed network.
        if (!m.hasFlag('earth') && !flags.contains('earth')) return 'আগে টেস্ট ও আর্থ করুন';
        flags.add('loto');
        clearSeed('no_loto');
        orders[crewId] = 'loto';
        line = 'লোটো — তালা ও ট্যাগ লাগল';
        score.add(ScoreEntry(ScoreCause.decision, 10, faultId: faultId));
      case 'ppe':
        if (gearId == null) return '';
        final result = wearGear(crewId, gearId);
        m = _s.mission(faultId);
        if (result == WearResult.worn || result == WearResult.wrong) {
          final kit = _s.bodyKit(faultId);
          final ok = kit.every(m.wornBy(crewId).contains);
          if (ok) {
            flags.add('ppe');
            clearSeed('no_ppe');
            clearSeed('no_harness');
          } else if (gearId == 'harness') {
            clearSeed('no_harness');
          }
          if (result == WearResult.wrong) plant('bad_ppe');
          orders[crewId] = 'ppe';
          line = result == WearResult.wrong ? 'কবচ পরল — দেখে নিন' : 'কবচ পরল';
        }
        _putMission(m.copyWith(
          siteFlags: flags,
          riskSeeds: seeds,
          siteActions: m.siteActions + 1,
          clearBloom: bloom == null,
          activeBloom: bloom,
          crewOrders: orders,
        ));
        if (score.isNotEmpty) state = _s.copyWith(score: score);
        return line;
      case 'climb':
        if (f.work != FaultWork.climb) return 'এই কাজ মাটিতে';
        flags.add('climbed');
        orders[crewId] = 'climb';
        if (!m.wornBy(crewId).contains('harness')) plant('no_harness');
        if (!flags.contains('ppe') && !_s.bodyKit(faultId).every(m.wornBy(crewId).contains)) {
          plant('no_ppe');
        }
        if (!flags.contains('earth') && !m.hasFlag('earth')) plant('no_earth');
        if (!flags.contains('ptw') && !m.hasFlag('ptw')) plant('no_ptw');
        if (!flags.contains('loto') && !m.hasFlag('loto')) plant('no_loto');
        if (!flags.contains('barricade') && !m.hasFlag('barricade')) plant('no_barricade');
        line = 'খুঁটিতে উঠল';
      case 'work':
        if (f.work == FaultWork.climb && !flags.contains('climbed') && !m.hasFlag('climbed')) {
          return 'আগে খুঁটিতে উঠুন';
        }
        flags.add('worked');
        orders[crewId] = 'work';
        if (!flags.contains('barricade') && !m.hasFlag('barricade')) plant('no_barricade');
        if (!flags.contains('earth') && !m.hasFlag('earth')) plant('no_earth');
        if (!flags.contains('ptw') && !m.hasFlag('ptw')) plant('no_ptw');
        if (!flags.contains('loto') && !m.hasFlag('loto')) plant('no_loto');
        if (f.work == FaultWork.climb && !m.wornBy(crewId).contains('harness')) plant('no_harness');
        line = 'মেরামত চলছে';
        score.add(ScoreEntry(ScoreCause.decision, 6, faultId: faultId));
      case 'handle_bloom':
        if (bloom == null) return '';
        if (bloom == 'crowd' || bloom == 'vehicle') {
          return workSiteAct(crewId, 'clear_public');
        }
        clearSeed(bloom == 'fall' ? 'no_harness' : bloom);
        bloom = null;
        line = 'বিপদ সামলানো গেল';
        score.add(ScoreEntry(ScoreCause.decision, 15, faultId: faultId));
      case 'finish':
        flags.add('counted');
        if (!flags.contains('worked') && !m.hasFlag('worked')) {
          return 'আগে কাজ শেষ করুন';
        }
        final missing = [
          ...m.missingSafety,
          if (seeds.contains('no_earth') && !m.missingSafety.contains('earth_rods')) 'earth_rods',
          if (seeds.contains('no_ptw') && !m.missingSafety.contains('ptw')) 'ptw',
          if (seeds.contains('no_loto') && !m.missingSafety.contains('lock_board')) 'lock_board',
          if (seeds.contains('no_barricade') && !m.missingSafety.contains('tape_cones')) 'tape_cones',
        ];
        _putMission(m.copyWith(
          siteFlags: flags,
          riskSeeds: seeds,
          siteActions: m.siteActions + 1,
          clearBloom: true,
          minutesUsed: m.minutesUsed + 3,
          missingSafety: missing,
          crewOrders: orders,
          choiceRisk: m.choiceRisk +
              (seeds.contains('no_harness') ? 0.22 : 0) +
              (seeds.contains('no_barricade') ? 0.2 : 0) +
              (seeds.contains('bad_ppe') ? 0.12 : 0) +
              (seeds.contains('no_earth') ? 0.2 : 0) +
              (seeds.contains('no_loto') ? 0.15 : 0),
        ));
        _resolve(faultId);
        return 'কাজ গোনা হল';
      default:
        return '';
    }

    final actions = m.siteActions + 1;
    // Delayed bloom: after a few acts, a silent seed becomes a scene threat.
    if (bloom == null && actions >= 2 && seeds.isNotEmpty) {
      if (seeds.contains('no_barricade') && actions >= 2) {
        bloom = f.work == FaultWork.ground ? 'vehicle' : 'crowd';
      } else if (seeds.contains('no_harness') && (flags.contains('climbed') || flags.contains('worked')) && actions >= 3) {
        bloom = 'fall';
      } else if (seeds.contains('no_earth') && flags.contains('worked') && actions >= 3) {
        bloom = 'shock';
      }
      if (bloom != null) {
        line = switch (bloom) {
          'vehicle' => 'গাড়ি আসছে — ব্যারিকেড ছিল না',
          'crowd' => 'লোক ভিড় করছে',
          'fall' => 'হারনেস ছাড়া উঁচুতে — পা পিছলে যাচ্ছে',
          'shock' => 'আর্থ ছাড়া কাজ — ঝলকানি!',
          _ => line,
        };
      }
    }

    _putMission(m.copyWith(
      siteFlags: flags,
      riskSeeds: seeds,
      siteActions: actions,
      minutesUsed: m.minutesUsed + 1,
      clearBloom: bloom == null,
      activeBloom: bloom,
      crewOrders: orders,
    ));
    if (score.isNotEmpty) state = _s.copyWith(score: score);
    return line;
  }

  /// The crew recite the ৮ মন্ত্র in order before work starts.
  void finishChant(int mistakes) {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.phase != ZeroLossPhase.chant) return;
    _putMission(_s.mission(faultId).copyWith(chantMistakes: mistakes));
    state = _s.copyWith(
      phase: ZeroLossPhase.site,
      safety: _s.safety + (mistakes == 0 ? 5 : 0),
      score: [
        if (mistakes == 0 && _s.scenario.chantBonusPoints > 0)
          ScoreEntry(ScoreCause.chant, _s.scenario.chantBonusPoints, faultId: faultId),
        for (var i = 0; i < min(mistakes, ZeroLossPoints.chantMistakeCap); i++)
          ScoreEntry(ScoreCause.chantMistake, -ZeroLossPoints.chantMistake, faultId: faultId),
      ],
    );
  }

  /// Answers the current hazard on the active site.
  void chooseOption(String optionId) {
    final faultId = _s.activeFaultId;
    if (faultId == null || _s.pendingFeedback != null) return;
    final f = _s.fault(faultId);
    final m = _s.mission(faultId);
    final event = f.events[m.eventIndex];
    final option = event.options.firstWhere((o) => o.id == optionId);
    _putMission(m.copyWith(
      minutesUsed: m.minutesUsed + option.minutes,
      choiceRisk: m.choiceRisk + option.risk,
      decisions: [...m.decisions, DecisionRecord(faultId: faultId, event: event, option: option)],
    ));
    state = _s.copyWith(
      pendingFeedback: option,
      safety: _s.safety + option.safety,
      satisfaction: _s.satisfaction + option.satisfaction,
      score: [
        option.best
            ? ScoreEntry(ScoreCause.decision, ZeroLossPoints.decision, faultId: faultId)
            : ScoreEntry(ScoreCause.wrongDecision, -ZeroLossPoints.wrongDecision, faultId: faultId),
      ],
    );
  }

  /// A customer called while the crew is running late. Capped per mission.
  /// Returns true when it cost points.
  bool customerComplaint(String faultId) {
    final s = state;
    if (s == null || !s.missions.containsKey(faultId)) return false;
    final m = s.mission(faultId);
    if (m.stage == MissionStage.done || m.complaints >= ZeroLossPoints.complaintCap) return false;
    _putMission(m.copyWith(complaints: m.complaints + 1));
    state = _s.copyWith(
      satisfaction: _s.satisfaction - ZeroLossPoints.complaintSatisfaction,
      score: [ScoreEntry(ScoreCause.complaint, -ZeroLossPoints.complaint, faultId: faultId)],
    );
    return true;
  }

  void continueAfterFeedback() {
    final faultId = _s.activeFaultId!;
    final f = _s.fault(faultId);
    final m = _s.mission(faultId);
    state = _s.copyWith(clearFeedback: true);
    if (m.eventIndex + 1 < f.events.length) {
      _putMission(m.copyWith(eventIndex: m.eventIndex + 1));
    } else {
      _resolve(faultId);
    }
  }

  /// Everything that raised the accident risk of a mission, each with what it would cause.
  List<RiskFactor> riskFactors(String faultId) {
    final f = _s.fault(faultId);
    final m = _s.mission(faultId);
    final sc = _s.scenario;
    final climb = f.work == FaultWork.climb;
    return [
      for (final d in m.decisions)
        if (d.option.risk > 0)
          RiskFactor(
            cause: d.option.cause.isEmpty ? (climb ? 'fall' : 'shock') : d.option.cause,
            risk: d.option.risk,
            eventId: d.event.id,
            optionId: d.option.id,
          ),
      for (final id in m.missingSafety) RiskFactor(cause: sc.gearById(id).cause, risk: sc.missingGearRisk, gearId: id),
      if (m.stage != MissionStage.waiting && m.stage != MissionStage.armour)
        for (final (man, g) in _s.missingBody(faultId))
          RiskFactor(
            cause: sc.gearById(g).cause,
            risk: sc.missingGearRisk,
            gearId: g,
            decoyId: _s.decoyInSlot(faultId, man, g),
            linemanId: man,
          ),
      for (final id in m.assignedCrew) ...[
        if (_s.lineman(id).fatigueLevel >= sc.tiredThreshold)
          RiskFactor(
            cause: climb ? 'fall' : 'shock',
            risk: climb ? sc.tiredRiskClimb : sc.tiredRiskGround,
            linemanId: id,
            fatigue: true,
          ),
        if (_s.lineman(id).safetyRating <= 2) RiskFactor(cause: climb ? 'fall' : 'shock', risk: 0.03, linemanId: id),
      ],
      if (m.isPacked('bamboo_ladder') && !m.isPacked('frp_ladder'))
        const RiskFactor(cause: 'ladder', risk: 0.1, gearId: 'bamboo_ladder'),
      if (m.isPacked('plain_pliers')) const RiskFactor(cause: 'shock', risk: 0.05, gearId: 'plain_pliers'),
    ];
  }

  /// Accident probability for a mission, from crew, missing gear and choices.
  double riskFor(String faultId) {
    final m = _s.mission(faultId);
    final risk = riskFactors(faultId).fold(_s.scenario.baseAccidentRisk + m.choiceRisk, (a, r) => a + r.risk);
    return risk.clamp(0, 0.9).toDouble();
  }

  RiskFactor _pickCause(List<RiskFactor> factors) {
    var roll = _rng.nextDouble() * factors.fold(0.0, (a, r) => a + r.risk);
    for (final r in factors) {
      roll -= r.risk;
      if (roll <= 0) return r;
    }
    return factors.last;
  }

  void _resolve(String faultId) {
    final f = _s.fault(faultId);
    final m = _s.mission(faultId);
    final risk = riskFor(faultId);
    final factors = riskFactors(faultId);
    final hadShortcut = m.choiceRisk > 0.05 ||
        factors.any((r) => r.gearId != null || r.optionId != null) ||
        m.decisions.any((d) => !d.option.best) ||
        m.riskSeeds.isNotEmpty;
    // Every mantra kept means everyone goes home: accidents only come from a broken step.
    // If a shortcut was taken or an unsafe decision made, guarantee the accident consequence scene:
    final accident = hadShortcut || (factors.isNotEmpty && _rng.nextDouble() < risk);

    if (accident) {
      final climb = f.work == FaultWork.climb;
      final cause = factors.isNotEmpty
          ? _pickCause(factors)
          : RiskFactor(
              cause: climb ? 'fall' : 'shock',
              risk: 0.5,
            );
      final public = _s.scenario.accidentCause(cause.cause).publicVictim;
      final victimId = public ? null : (cause.linemanId ?? (m.assignedCrew.isNotEmpty ? m.assignedCrew[_rng.nextInt(m.assignedCrew.length)] : null));
      _putMission(m.copyWith(
        stage: MissionStage.done,
        outcome: MissionOutcome.accident,
        injuredCrewId: victimId,
        finalRisk: risk,
        accident: cause,
      ));
      state = _s.copyWith(
        phase: ZeroLossPhase.outcome,
        crew: [for (final c in _s.crew) c.id == victimId ? c.copyWith(isInjured: true) : c],
        safety: _s.safety - ZeroLossPoints.accidentSafety,
        satisfaction: _s.satisfaction - ZeroLossPoints.accidentSatisfaction,
        score: [ScoreEntry(ScoreCause.accident, -ZeroLossPoints.accident, faultId: faultId)],
      );
      return;
    }

    _putMission(m.copyWith(
      stage: MissionStage.done,
      outcome: hadShortcut ? MissionOutcome.lucky : MissionOutcome.safe,
      finalRisk: risk,
    ));
    final late = _s.isLate(faultId);
    state = _s.copyWith(
      phase: ZeroLossPhase.outcome,
      satisfaction: _s.satisfaction + (late ? -ZeroLossPoints.lateSatisfaction : ZeroLossPoints.lateSatisfaction),
      score: [
        ScoreEntry(ScoreCause.restore, ZeroLossPoints.restore, faultId: faultId),
        late
            ? ScoreEntry(ScoreCause.late, -ZeroLossPoints.late, faultId: faultId)
            : ScoreEntry(ScoreCause.onTime, ZeroLossPoints.onTime, faultId: faultId),
      ],
    );
  }

  /// After an outcome: back to the map, or the debrief when both faults are done.
  void closeOutcome() {
    if (_s.allDone) {
      state = _s.copyWith(
        phase: ZeroLossPhase.debrief,
        clearActive: true,
        score: [if (_s.zeroLoss) const ScoreEntry(ScoreCause.zeroLoss, ZeroLossPoints.zeroLoss)],
      );
      final bonus = _s.points ~/ 2;
      if (_s.duty && bonus > 0) state = _s.copyWith(score: [ScoreEntry(ScoreCause.dutyBonus, bonus)]);
      return;
    }
    final next = _s.scenario.faults.firstWhere((f) => _s.mission(f.id).stage != MissionStage.done);
    state = _s.copyWith(phase: ZeroLossPhase.map, clearActive: true, selectedFaultId: next.id);
  }
}

final zeroLossProvider = NotifierProvider<SmartLinemanDispatchNotifier, ZeroLossState?>(
  SmartLinemanDispatchNotifier.new,
);

// ---------------------------------------------------------------------------
// Local record (practice only — nothing goes to the server).
// ---------------------------------------------------------------------------

class ZeroLossRecord {
  final int plays;
  final int bestPoints;
  final int zeroLossCount;

  const ZeroLossRecord({this.plays = 0, this.bestPoints = 0, this.zeroLossCount = 0});

  static const _plays = 'zero_loss_plays_v1';
  static const _best = 'zero_loss_best_v1';
  static const _zero = 'zero_loss_zero_count_v1';

  static Future<ZeroLossRecord> load() async {
    final p = await SharedPreferences.getInstance();
    return ZeroLossRecord(
      plays: p.getInt(_plays) ?? 0,
      bestPoints: p.getInt(_best) ?? 0,
      zeroLossCount: p.getInt(_zero) ?? 0,
    );
  }

  /// Saves a finished play; returns the updated record and whether it beat the best.
  /// Only duty shifts count for the best score.
  static Future<(ZeroLossRecord, bool)> save({required int points, required bool zeroLoss, bool countsForBest = true}) async {
    final p = await SharedPreferences.getInstance();
    final old = await load();
    if (!countsForBest) points = 0;
    final record = ZeroLossRecord(
      plays: old.plays + 1,
      bestPoints: max(old.bestPoints, points),
      zeroLossCount: old.zeroLossCount + (zeroLoss ? 1 : 0),
    );
    await p.setInt(_plays, record.plays);
    await p.setInt(_best, record.bestPoints);
    await p.setInt(_zero, record.zeroLossCount);
    return (record, points > old.bestPoints);
  }
}

final zeroLossRecordProvider = FutureProvider.autoDispose<ZeroLossRecord>((ref) => ZeroLossRecord.load());
