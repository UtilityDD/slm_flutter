/// Data for the "জিরো লস" field-command game.
///
/// The scenario file is a template: `{district}`, `{office}`, `{placeA}`,
/// `{placeB}`, `{hospital}`, `{weather}` and `{crew}` are filled per play.
library;

/// The two memory tracks of the ৮ মন্ত্র, each with recorded Tool Box Talk audio.
enum TbtTrack { safe, sobai }

/// One spoken step of a Tool Box Talk track; times are speech cues in ms.
class MantraLine {
  final String letter;
  final String word;
  final String file;
  final String bodyBn;
  final int wordAt;
  final int nameAt;
  final int bodyAt;

  const MantraLine({
    required this.letter,
    required this.word,
    required this.file,
    required this.bodyBn,
    this.wordAt = 0,
    this.nameAt = 0,
    this.bodyAt = 0,
  });

  factory MantraLine.fromJson(Map<String, dynamic> j) => MantraLine(
        letter: j['letter'] as String,
        word: j['word'] as String,
        file: j['file'] as String,
        bodyBn: j['body_bn'] as String? ?? '',
        wordAt: (j['word_at'] as num?)?.toInt() ?? 0,
        nameAt: (j['name_at'] as num?)?.toInt() ?? (j['word_at'] as num?)?.toInt() ?? 0,
        bodyAt: (j['body_at'] as num?)?.toInt() ?? 0,
      );
}

class TbtIntro {
  final String title;
  final String subtitleBn;
  final String file;

  const TbtIntro({required this.title, required this.subtitleBn, required this.file});

  factory TbtIntro.fromJson(Map<String, dynamic> j) => TbtIntro(
        title: j['title'] as String,
        subtitleBn: j['subtitle_bn'] as String? ?? '',
        file: j['file'] as String,
      );
}

class SafetyMantra {
  final String id;
  final String nameBn;
  final String chantBn;
  final String ruleBn;
  final Map<TbtTrack, MantraLine> lines;

  const SafetyMantra({
    required this.id,
    required this.nameBn,
    required this.ruleBn,
    this.chantBn = '',
    this.lines = const {},
  });

  factory SafetyMantra.fromJson(Map<String, dynamic> j) => SafetyMantra(
        id: j['id'] as String,
        nameBn: j['name_bn'] as String,
        chantBn: j['chant_bn'] as String? ?? '',
        ruleBn: j['rule_bn'] as String? ?? '',
        lines: {
          for (final t in TbtTrack.values)
            if (j[t.name] is Map) t: MantraLine.fromJson(Map<String, dynamic>.from(j[t.name] as Map)),
        },
      );
}

enum GearKind { safety, tool, job, decoy }

/// Worn by each lineman ([body]) or carried on the truck ([truck]).
enum GearArea { body, truck }

/// One item of kit. [isPacked] is per-mission state.
class Gear {
  final String id;
  final String nameBn;
  final String image;
  final String emoji;
  final String icon;
  final GearKind kind;
  final GearArea area;
  final String bodySlot;
  final String mantra;
  final String? decoyNoteBn;

  /// [AccidentCause.id] this item prevents (or, for a decoy, provokes).
  final String cause;
  final bool isPacked;

  const Gear({
    required this.id,
    required this.nameBn,
    required this.image,
    required this.emoji,
    required this.kind,
    required this.mantra,
    this.icon = '',
    this.area = GearArea.truck,
    this.bodySlot = '',
    this.decoyNoteBn,
    this.cause = '',
    this.isPacked = false,
  });

  Gear copyWith({bool? isPacked}) => Gear(
        id: id,
        nameBn: nameBn,
        image: image,
        emoji: emoji,
        icon: icon,
        kind: kind,
        area: area,
        bodySlot: bodySlot,
        mantra: mantra,
        decoyNoteBn: decoyNoteBn,
        cause: cause,
        isPacked: isPacked ?? this.isPacked,
      );

  factory Gear.fromJson(Map<String, dynamic> j) => Gear(
        id: j['id'] as String,
        nameBn: j['name_bn'] as String,
        image: j['image'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '',
        icon: j['icon'] as String? ?? '',
        kind: GearKind.values.byName(j['kind'] as String? ?? 'tool'),
        area: GearArea.values.byName(j['area'] as String? ?? 'truck'),
        bodySlot: j['body_slot'] as String? ?? '',
        mantra: j['mantra'] as String? ?? '',
        decoyNoteBn: j['decoy_note_bn'] as String?,
        cause: j['cause'] as String? ?? '',
      );
}

/// Kit lists for the shift TBT preview (required vs not required).
class ShiftKitPreview {
  final List<Gear> requiredBody;
  final List<Gear> requiredTruck;
  final List<Gear> notRequiredBody;
  final List<Gear> notRequiredTruck;

  const ShiftKitPreview({
    required this.requiredBody,
    required this.requiredTruck,
    required this.notRequiredBody,
    required this.notRequiredTruck,
  });
}

/// What actually happens when a safety step is skipped, with a picture of the moment.
class AccidentCause {
  final String id;
  final String titleBn;
  final String lineBn;
  final String image;

  /// The victim is a member of the public, not the crew.
  final bool publicVictim;

  const AccidentCause({
    required this.id,
    required this.titleBn,
    required this.lineBn,
    required this.image,
    this.publicVictim = false,
  });

  factory AccidentCause.fromJson(String id, Map<String, dynamic> j) => AccidentCause(
        id: id,
        titleBn: j['title_bn'] as String,
        lineBn: j['line_bn'] as String? ?? '',
        image: j['image'] as String? ?? '',
        publicVictim: j['public'] as bool? ?? false,
      );
}

/// A crew member. Fatigue is 0–100; safety rating is 1–5.
class SmartLineman {
  final String id;
  final String name;
  final String art;
  final String noteBn;
  final int fatigueLevel;
  final bool isInjured;
  final int safetyRating;

  const SmartLineman({
    required this.id,
    required this.name,
    required this.noteBn,
    required this.fatigueLevel,
    required this.safetyRating,
    this.art = '',
    this.isInjured = false,
  });

  SmartLineman copyWith({int? fatigueLevel, bool? isInjured}) => SmartLineman(
        id: id,
        name: name,
        art: art,
        noteBn: noteBn,
        fatigueLevel: fatigueLevel ?? this.fatigueLevel,
        safetyRating: safetyRating,
        isInjured: isInjured ?? this.isInjured,
      );

  factory SmartLineman.fromJson(Map<String, dynamic> j) => SmartLineman(
        id: j['id'] as String,
        name: j['name_bn'] as String,
        art: j['art'] as String? ?? '',
        noteBn: j['note_bn'] as String? ?? '',
        fatigueLevel: (j['fatigue'] as num).toInt(),
        safetyRating: (j['safety_rating'] as num).toInt(),
      );
}

class HazardOption {
  final String id;
  final String icon;
  final String shortBn;
  final String textBn;
  final bool best;
  final int safety;
  final int satisfaction;
  final int minutes;
  final double risk;
  final String feedbackBn;

  /// [AccidentCause.id] this choice can lead to.
  final String cause;

  const HazardOption({
    required this.id,
    required this.textBn,
    this.icon = '',
    this.shortBn = '',
    required this.best,
    required this.safety,
    required this.satisfaction,
    required this.minutes,
    required this.risk,
    required this.feedbackBn,
    this.cause = '',
  });

  factory HazardOption.fromJson(Map<String, dynamic> j) => HazardOption(
        id: j['id'] as String,
        icon: j['icon'] as String? ?? '',
        shortBn: j['short_bn'] as String? ?? '',
        textBn: j['text_bn'] as String,
        best: j['best'] as bool? ?? false,
        safety: (j['safety'] as num?)?.toInt() ?? 0,
        satisfaction: (j['satisfaction'] as num?)?.toInt() ?? 0,
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
        risk: (j['risk'] as num?)?.toDouble() ?? 0,
        feedbackBn: j['feedback_bn'] as String? ?? '',
        cause: j['cause'] as String? ?? '',
      );
}

/// One sprite or picture placed on a scene. Coordinates are fractions of a 3:4 stage:
/// [x] is the horizontal centre, [y] the baseline (feet), [h] the height.
class SceneLayer {
  /// Asset path of the picture (scene-kit sprite or any library image).
  final String image;
  final double x;
  final double y;
  final double h;
  final bool flip;

  /// `lead` / `junior`: shows the assigned crew member's name above the sprite.
  final String role;

  /// When the layer is visible: `before`, `after`, `best`, `wrong`, `pick:<optionId>`. Empty means always.
  final List<String> when;

  const SceneLayer({
    required this.image,
    required this.x,
    required this.y,
    required this.h,
    this.flip = false,
    this.role = '',
    this.when = const [],
  });

  factory SceneLayer.fromJson(Map<String, dynamic> j) => SceneLayer(
        image: sceneAsset(j['sprite'] as String? ?? '', j['image'] as String?),
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        h: (j['h'] as num).toDouble(),
        flip: j['flip'] as bool? ?? false,
        role: j['role'] as String? ?? '',
        when: switch (j['when']) {
          final String w => [w],
          final List<dynamic> w => w.cast<String>(),
          _ => const [],
        },
      );

  bool visibleFor(HazardOption? picked) {
    if (when.isEmpty) return true;
    for (final w in when) {
      final hit = switch (w) {
        'before' => picked == null,
        'after' => picked != null,
        'best' => picked?.best ?? false,
        'wrong' => picked != null && !picked.best,
        _ => w.startsWith('pick:') && picked?.id == w.substring(5),
      };
      if (hit) return true;
    }
    return false;
  }
}

/// A hazard the player can find by tapping the scene.
class SceneSpot {
  final double x;
  final double y;
  final double r;
  final String labelBn;
  final String icon;

  const SceneSpot({required this.x, required this.y, required this.labelBn, this.r = 0.09, this.icon = ''});

  factory SceneSpot.fromJson(Map<String, dynamic> j) => SceneSpot(
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        r: (j['r'] as num?)?.toDouble() ?? 0.09,
        labelBn: j['label_bn'] as String,
        icon: j['icon'] as String? ?? '',
      );
}

/// A composed, interactive scene built from the reusable scene kit.
class ScenePlan {
  final String background;
  final bool storm;
  final bool indoor;
  final List<SceneLayer> layers;
  final List<SceneSpot> spots;

  /// Where sparks fly on an unsafe choice.
  final double failX;
  final double failY;

  const ScenePlan({
    required this.background,
    this.storm = true,
    this.indoor = false,
    this.layers = const [],
    this.spots = const [],
    this.failX = 0.5,
    this.failY = 0.3,
  });

  factory ScenePlan.fromJson(Map<String, dynamic> j) {
    final fail = (j['fail_at'] as List?)?.cast<num>();
    return ScenePlan(
      background: sceneAsset('bg_${j['bg']}', null),
      storm: j['storm'] as bool? ?? true,
      indoor: j['indoor'] as bool? ?? false,
      layers: [for (final l in j['layers'] as List? ?? const []) SceneLayer.fromJson(Map<String, dynamic>.from(l as Map))],
      spots: [for (final s in j['spots'] as List? ?? const []) SceneSpot.fromJson(Map<String, dynamic>.from(s as Map))],
      failX: fail == null ? 0.5 : fail[0].toDouble(),
      failY: fail == null ? 0.3 : fail[1].toDouble(),
    );
  }
}

/// Scene-kit names (`man_point`, `bg_pole_storm`) map to `assets/zero_loss/scene/<name>.webp`.
String sceneAsset(String name, String? path) {
  if (path != null && path.isNotEmpty) return path;
  final file = name.startsWith('bg_') || name.startsWith('spr_') || name.startsWith('prop_') ? name : _kitName(name);
  return 'assets/zero_loss/scene/$file.webp';
}

String _kitName(String name) => switch (name) {
      'cones_tape' || 'earth_set' || 'lock_board' || 'truck' => 'prop_$name',
      _ => 'spr_$name',
    };

class HazardEvent {
  final String id;
  final String mantra;
  final String image;
  final ScenePlan? scene;

  /// `lead` / `junior` (from the assigned crew), or `substation`, `helper`, `public`.
  final String speaker;
  final String alertBn;
  final String lineBn;
  final String situationBn;
  final List<HazardOption> options;

  const HazardEvent({
    required this.id,
    required this.mantra,
    required this.image,
    required this.speaker,
    required this.situationBn,
    required this.options,
    this.alertBn = '',
    this.lineBn = '',
    this.scene,
  });

  factory HazardEvent.fromJson(Map<String, dynamic> j) => HazardEvent(
        id: j['id'] as String,
        mantra: j['mantra'] as String,
        image: j['image'] as String? ?? '',
        scene: j['scene'] is Map ? ScenePlan.fromJson(Map<String, dynamic>.from(j['scene'] as Map)) : null,
        speaker: j['speaker'] as String? ?? 'lead',
        alertBn: j['alert_bn'] as String? ?? '',
        lineBn: j['line_bn'] as String? ?? '',
        situationBn: j['situation_bn'] as String,
        options: [for (final o in j['options'] as List) HazardOption.fromJson(o as Map<String, dynamic>)],
      );
}

enum FaultWork { climb, ground }

/// Visual weather for a single job — storm is only one option.
enum JobMood { day, overcast, dusk, storm }

/// Operator call ↔ worksite visual contract for one fault.
class SiteHazardPack {
  final String faultId;
  final String bgAsset;
  final FaultWork work;
  final String operatorLineBn;
  final String placeHintBn;
  final bool needsClimb;
  final List<String> baseActs;

  /// Normalized 0–1 spots for climb / ground work sprites.
  final double climbX;
  final double climbY;
  final double workX;
  final double workY;

  const SiteHazardPack({
    required this.faultId,
    required this.bgAsset,
    required this.work,
    required this.operatorLineBn,
    required this.placeHintBn,
    required this.needsClimb,
    required this.baseActs,
    this.climbX = 0.52,
    this.climbY = 0.28,
    this.workX = 0.48,
    this.workY = 0.62,
  });

  factory SiteHazardPack.fromFault(FaultDispatch f) {
    final needsClimb = f.work == FaultWork.climb;
    final acts = <String>[
      'ppe',
      'barricade',
      'ptw',
      'earth',
      'loto',
      if (needsClimb) 'climb',
      'work',
    ];
    // Per-job sprite anchors — wire on road is ground work; poles climb high.
    final (cx, cy, wx, wy) = switch (f.id) {
      'wire_on_ground' || 'service_connection' => (0.5, 0.35, 0.45, 0.68),
      'tree_trimming' => (0.55, 0.22, 0.5, 0.55),
      'leaning_pole_repair' => (0.48, 0.25, 0.42, 0.6),
      'ug_cable_joint' => (0.5, 0.4, 0.5, 0.7),
      _ => needsClimb ? (0.52, 0.26, 0.5, 0.58) : (0.5, 0.35, 0.48, 0.65),
    };
    final where = f.wireSpotsBn.isNotEmpty ? f.wireSpotsBn.first : (needsClimb ? 'খুঁটিতে' : 'মাঠে');
    return SiteHazardPack(
      faultId: f.id,
      bgAsset: f.sceneImage,
      work: f.work,
      operatorLineBn: '${f.shortTitleBn}। ${f.detailBn.replaceAll(RegExp(r'\{place[A-Z]?\}'), where)}',
      placeHintBn: where,
      needsClimb: needsClimb,
      baseActs: acts,
      climbX: cx,
      climbY: cy,
      workX: wx,
      workY: wy,
    );
  }
}

class FaultDispatch {
  final String id;
  final String slot;
  final String shortTitleBn;
  final String titleBn;
  final String detailBn;
  final String severity;
  final FaultWork work;
  final int urgencyMinutes;
  final int requiredCrewCount;
  final int travelMinutes;
  final int repairMinutes;
  final List<String> requiredGear;
  final List<String> jobGear;
  final List<HazardEvent> events;

  /// Preferred plate per mood (day/overcast/dusk/storm). Falls back to event art.
  final Map<JobMood, String> sceneByMood;

  /// Place words for the control call (মাঠে, রাস্তায়, পুকুরে…).
  final List<String> wireSpotsBn;

  /// Optional fixed mood from data; otherwise setup stamps a random one.
  final JobMood? mood;

  const FaultDispatch({
    required this.id,
    required this.slot,
    required this.shortTitleBn,
    required this.titleBn,
    required this.detailBn,
    required this.severity,
    required this.work,
    required this.urgencyMinutes,
    required this.requiredCrewCount,
    required this.travelMinutes,
    required this.repairMinutes,
    required this.requiredGear,
    required this.jobGear,
    required this.events,
    this.sceneByMood = const {},
    this.wireSpotsBn = const [],
    this.mood,
  });

  String get sceneImage {
    final m = mood ?? JobMood.day;
    final keyed = sceneByMood[m];
    if (keyed != null && keyed.isNotEmpty) return keyed;
    if (events.isNotEmpty && events.first.image.isNotEmpty) return events.first.image;
    return 'assets/zero_loss/scene/bg_pole_storm.webp';
  }

  FaultDispatch copyWith({
    String? id,
    String? slot,
    String? shortTitleBn,
    String? titleBn,
    String? detailBn,
    String? severity,
    FaultWork? work,
    int? urgencyMinutes,
    int? requiredCrewCount,
    int? travelMinutes,
    int? repairMinutes,
    List<String>? requiredGear,
    List<String>? jobGear,
    List<HazardEvent>? events,
    Map<JobMood, String>? sceneByMood,
    List<String>? wireSpotsBn,
    JobMood? mood,
  }) =>
      FaultDispatch(
        id: id ?? this.id,
        slot: slot ?? this.slot,
        shortTitleBn: shortTitleBn ?? this.shortTitleBn,
        titleBn: titleBn ?? this.titleBn,
        detailBn: detailBn ?? this.detailBn,
        severity: severity ?? this.severity,
        work: work ?? this.work,
        urgencyMinutes: urgencyMinutes ?? this.urgencyMinutes,
        requiredCrewCount: requiredCrewCount ?? this.requiredCrewCount,
        travelMinutes: travelMinutes ?? this.travelMinutes,
        repairMinutes: repairMinutes ?? this.repairMinutes,
        requiredGear: requiredGear ?? this.requiredGear,
        jobGear: jobGear ?? this.jobGear,
        events: events ?? this.events,
        sceneByMood: sceneByMood ?? this.sceneByMood,
        wireSpotsBn: wireSpotsBn ?? this.wireSpotsBn,
        mood: mood ?? this.mood,
      );

  factory FaultDispatch.fromJson(Map<String, dynamic> j) {
    final scenes = <JobMood, String>{};
    final rawScenes = j['scene_by_mood'];
    if (rawScenes is Map) {
      for (final e in rawScenes.entries) {
        final mood = JobMood.values.where((m) => m.name == e.key).firstOrNull;
        if (mood != null && e.value is String) scenes[mood] = e.value as String;
      }
    }
    final moodName = j['mood'] as String?;
    return FaultDispatch(
      id: j['fault_id'] as String,
      slot: j['slot'] as String,
      shortTitleBn: j['short_title_bn'] as String? ?? j['title_bn'] as String,
      titleBn: j['title_bn'] as String,
      detailBn: j['detail_bn'] as String,
      severity: j['severity'] as String,
      work: FaultWork.values.byName(j['work'] as String? ?? 'climb'),
      urgencyMinutes: (j['urgency_minutes'] as num).toInt(),
      requiredCrewCount: (j['required_crew_count'] as num).toInt(),
      travelMinutes: (j['travel_minutes'] as num).toInt(),
      repairMinutes: (j['repair_minutes'] as num).toInt(),
      requiredGear: List<String>.from(j['required_gear'] as List),
      jobGear: List<String>.from(j['job_gear'] as List? ?? const []),
      events: [for (final e in j['events'] as List) HazardEvent.fromJson(e as Map<String, dynamic>)],
      sceneByMood: scenes,
      wireSpotsBn: List<String>.from(j['wire_spots_bn'] as List? ?? const []),
      mood: moodName == null ? null : JobMood.values.where((m) => m.name == moodName).firstOrNull,
    );
  }
}

class RegionWeather {
  final String id;
  final List<String> districts;
  final String weatherBn;
  final String weatherShortBn;
  final int travelExtraMinutes;

  const RegionWeather({
    required this.id,
    required this.districts,
    required this.weatherBn,
    required this.travelExtraMinutes,
    this.weatherShortBn = '',
  });
}

/// A member of the public who calls in while the crew is out.
class Customer {
  final String id;
  final String nameBn;
  final String image;
  final List<String> linesBn;
  final List<String> lateLinesBn;

  const Customer({
    required this.id,
    required this.nameBn,
    required this.image,
    this.linesBn = const [],
    this.lateLinesBn = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        nameBn: j['name_bn'] as String? ?? '',
        image: j['image'] as String? ?? '',
        linesBn: List<String>.from(j['lines_bn'] as List? ?? const []),
        lateLinesBn: List<String>.from(j['late_lines_bn'] as List? ?? const []),
      );
}

class ZeroLossScenario {
  final String id;
  final String titleBn;
  final int budgetTokens;
  final int timeLimitMinutes;
  final int truckCapacity;
  final int loadingSeconds;
  final int reloadSeconds;
  final int reloadMinutes;
  final int reloadTokens;
  final int reloadSatisfaction;
  final int startSatisfaction;
  final int startSafety;
  final double baseAccidentRisk;
  final double missingGearRisk;
  final int tiredThreshold;
  final double tiredRiskClimb;
  final double tiredRiskGround;
  final int chantBonusPoints;

  /// Personal PPE every lineman wears, plus extra items for climbing jobs.
  final List<String> bodyAlways;
  final List<String> bodyClimb;
  final Map<TbtTrack, TbtIntro> tbt;
  final List<SafetyMantra> mantras;
  final List<RegionWeather> regions;
  final Map<String, String> districtNamesBn;
  final List<SmartLineman> crew;
  final List<Gear> gear;
  final List<FaultDispatch> faults;

  /// Full catalog of all 12 field jobs (used for roster selection and dynamic shifts).
  final List<FaultDispatch> catalog;
  final Map<String, String> voice;
  final List<Customer> customers;
  final Map<String, AccidentCause> accidentCauses;

  /// Lines a careful crew member mutters after a risky order in duty mode.
  final List<String> hesitationBn;

  const ZeroLossScenario({
    required this.id,
    required this.titleBn,
    required this.budgetTokens,
    required this.timeLimitMinutes,
    required this.truckCapacity,
    required this.loadingSeconds,
    required this.reloadSeconds,
    required this.reloadMinutes,
    required this.reloadTokens,
    required this.reloadSatisfaction,
    required this.startSatisfaction,
    required this.startSafety,
    required this.baseAccidentRisk,
    required this.missingGearRisk,
    required this.tiredThreshold,
    required this.tiredRiskClimb,
    required this.tiredRiskGround,
    required this.chantBonusPoints,
    required this.bodyAlways,
    required this.bodyClimb,
    required this.mantras,
    this.tbt = const {},
    required this.regions,
    required this.districtNamesBn,
    required this.crew,
    required this.gear,
    required this.faults,
    this.catalog = const [],
    required this.voice,
    this.customers = const [],
    this.accidentCauses = const {},
    this.hesitationBn = const [],
  });

  ZeroLossScenario copyWith({
    List<FaultDispatch>? faults,
    List<FaultDispatch>? catalog,
  }) =>
      ZeroLossScenario(
        id: id,
        titleBn: titleBn,
        budgetTokens: budgetTokens,
        timeLimitMinutes: timeLimitMinutes,
        truckCapacity: truckCapacity,
        loadingSeconds: loadingSeconds,
        reloadSeconds: reloadSeconds,
        reloadMinutes: reloadMinutes,
        reloadTokens: reloadTokens,
        reloadSatisfaction: reloadSatisfaction,
        startSatisfaction: startSatisfaction,
        startSafety: startSafety,
        baseAccidentRisk: baseAccidentRisk,
        missingGearRisk: missingGearRisk,
        tiredThreshold: tiredThreshold,
        tiredRiskClimb: tiredRiskClimb,
        tiredRiskGround: tiredRiskGround,
        chantBonusPoints: chantBonusPoints,
        bodyAlways: bodyAlways,
        bodyClimb: bodyClimb,
        mantras: mantras,
        tbt: tbt,
        regions: regions,
        districtNamesBn: districtNamesBn,
        crew: crew,
        gear: gear,
        faults: faults ?? this.faults,
        catalog: catalog ?? this.catalog,
        voice: voice,
        customers: customers,
        accidentCauses: accidentCauses,
        hesitationBn: hesitationBn,
      );

  AccidentCause accidentCause(String id) =>
      accidentCauses[id] ?? AccidentCause(id: id, titleBn: 'দুর্ঘটনা', lineBn: '', image: '');

  SafetyMantra mantra(String id) =>
      mantras.firstWhere((m) => m.id == id, orElse: () => SafetyMantra(id: id, nameBn: id, ruleBn: ''));

  Gear gearById(String id) => gear.firstWhere(
        (g) => g.id == id,
        orElse: () => Gear(
          id: id,
          nameBn: id,
          image: '',
          emoji: '📦',
          kind: GearKind.tool,
          mantra: '',
        ),
      );

  List<String> bodyKitFor(FaultDispatch f) => [...bodyAlways, if (f.work == FaultWork.climb) ...bodyClimb];

  List<Gear> get bodyGear => gear.where((g) => g.area == GearArea.body).toList();

  List<Gear> get truckGear => gear.where((g) => g.area == GearArea.truck).toList();

  RegionWeather regionFor(String district) =>
      regions.firstWhere((r) => r.districts.contains(district), orElse: () => regions.last);

  factory ZeroLossScenario.fromJson(Map<String, dynamic> j) {
    final regions = <RegionWeather>[
      for (final e in (j['regions'] as Map<String, dynamic>).entries)
        RegionWeather(
          id: e.key,
          districts: List<String>.from((e.value as Map)['districts'] as List),
          weatherBn: (e.value as Map)['weather_bn'] as String,
          weatherShortBn: (e.value as Map)['weather_short_bn'] as String? ?? '',
          travelExtraMinutes: ((e.value as Map)['travel_extra_minutes'] as num?)?.toInt() ?? 0,
        ),
    ];
    return ZeroLossScenario(
      id: j['scenario_id'] as String,
      titleBn: j['title_bn'] as String,
      budgetTokens: (j['initial_budget_tokens'] as num).toInt(),
      timeLimitMinutes: (j['time_limit_minutes'] as num).toInt(),
      truckCapacity: (j['truck_capacity'] as num).toInt(),
      loadingSeconds: (j['loading_seconds'] as num).toInt(),
      reloadSeconds: (j['reload_seconds'] as num).toInt(),
      reloadMinutes: (j['reload_minutes'] as num).toInt(),
      reloadTokens: (j['reload_tokens'] as num).toInt(),
      reloadSatisfaction: (j['reload_satisfaction'] as num).toInt(),
      startSatisfaction: (j['start_satisfaction'] as num).toInt(),
      startSafety: (j['start_safety'] as num).toInt(),
      baseAccidentRisk: (j['base_accident_risk'] as num).toDouble(),
      missingGearRisk: (j['missing_gear_risk'] as num).toDouble(),
      tiredThreshold: (j['tired_fatigue_threshold'] as num).toInt(),
      tiredRiskClimb: (j['tired_risk_climb'] as num).toDouble(),
      tiredRiskGround: (j['tired_risk_ground'] as num).toDouble(),
      chantBonusPoints: (j['chant_bonus_points'] as num?)?.toInt() ?? 0,
      bodyAlways: List<String>.from((j['personal_ppe'] as Map?)?['always'] as List? ?? const []),
      bodyClimb: List<String>.from((j['personal_ppe'] as Map?)?['climb'] as List? ?? const []),
      tbt: {
        for (final t in TbtTrack.values)
          if ((j['tbt'] as Map?)?[t.name] is Map)
            t: TbtIntro.fromJson(Map<String, dynamic>.from((j['tbt'] as Map)[t.name] as Map)),
      },
      mantras: [for (final m in j['mantras'] as List) SafetyMantra.fromJson(m as Map<String, dynamic>)],
      regions: regions,
      districtNamesBn: Map<String, String>.from(j['district_names_bn'] as Map),
      crew: [for (final c in j['crew'] as List) SmartLineman.fromJson(c as Map<String, dynamic>)],
      gear: [for (final g in j['gear'] as List) Gear.fromJson(g as Map<String, dynamic>)],
      faults: [for (final f in j['faults'] as List) FaultDispatch.fromJson(f as Map<String, dynamic>)],
      catalog: [for (final f in j['faults'] as List) FaultDispatch.fromJson(f as Map<String, dynamic>)],
      voice: Map<String, String>.from(j['voice'] as Map),
      customers: [for (final c in j['customers'] as List? ?? const []) Customer.fromJson(c as Map<String, dynamic>)],
      accidentCauses: {
        for (final e in ((j['accident_causes'] as Map?) ?? const {}).entries)
          e.key as String: AccidentCause.fromJson(e.key as String, Map<String, dynamic>.from(e.value as Map)),
      },
      hesitationBn: List<String>.from(j['hesitation_bn'] as List? ?? const []),
    );
  }
}

/// The real-world place this play is set in.
class ZeroLossSetting {
  final String district;
  final String districtBn;
  final String office;
  final String placeA;
  final String placeB;
  final String hospital;
  final RegionWeather region;

  const ZeroLossSetting({
    required this.district,
    required this.districtBn,
    required this.office,
    required this.placeA,
    required this.placeB,
    required this.hospital,
    required this.region,
  });

  String fill(String template, {String crew = '', String lead = '', String junior = ''}) => template
      .replaceAll('{lead}', lead)
      .replaceAll('{junior}', junior)
      .replaceAll('{district}', districtBn)
      .replaceAll('{office}', office)
      .replaceAll('{placeA}', placeA)
      .replaceAll('{placeB}', placeB)
      .replaceAll('{hospital}', hospital)
      .replaceAll('{weather}', region.weatherBn)
      .replaceAll('{crew}', crew);
}
