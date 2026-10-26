import 'dart:convert';

import 'package:flutter/services.dart';

class DsPlanItem {
  final String id;
  final String labelBn;
  final String letter;
  final String whyBn;
  final String icon;
  final String lane;

  const DsPlanItem({
    required this.id,
    required this.labelBn,
    this.letter = '',
    this.whyBn = '',
    this.icon = '',
    this.lane = '',
  });

  factory DsPlanItem.fromJson(Map<String, dynamic> j) => DsPlanItem(
        id: j['id'] as String,
        labelBn: j['label_bn'] as String? ?? '',
        letter: j['letter'] as String? ?? '',
        whyBn: j['why_bn'] as String? ?? '',
        icon: j['icon'] as String? ?? '',
        lane: j['lane'] as String? ?? '',
      );
}

/// Lane group labels and colours for the 23-step job review sheet.
class DsLaneGroup {
  final String id;
  final String labelBn;
  final int color;

  const DsLaneGroup(this.id, this.labelBn, this.color);

  static const groups = <DsLaneGroup>[
    DsLaneGroup('office',  'অফিস',      0xFF3B82F6),
    DsLaneGroup('site',    'সাইট',       0xFF22C55E),
    DsLaneGroup('isolate', 'আইসোলেশন',  0xFFEF4444),
    DsLaneGroup('work',    'কাজ',        0xFFF59E0B),
    DsLaneGroup('close',   'ক্লোজ',      0xFF8B5CF6),
  ];

  static DsLaneGroup? of(String lane) {
    for (final g in groups) {
      if (g.id == lane) return g;
    }
    return null;
  }
}

class DsSite {
  final String id;
  final String nameBn;
  final String bg;
  final String pole;
  final String introBn;
  final String storyBn;
  final List<String> calls;

  const DsSite({
    required this.id,
    required this.nameBn,
    required this.bg,
    required this.pole,
    required this.introBn,
    this.storyBn = '',
    this.calls = const [],
  });

  factory DsSite.fromJson(Map<String, dynamic> j) => DsSite(
        id: j['id'] as String,
        nameBn: j['name_bn'] as String? ?? '',
        bg: j['bg'] as String? ?? '',
        pole: j['pole'] as String? ?? 'DP-17',
        introBn: j['intro_bn'] as String? ?? '',
        storyBn: j['story_bn'] as String? ?? '',
        calls: List<String>.from(j['calls'] as List? ?? const []),
      );
}

class DsOption {
  final String id;
  final String labelBn;
  final String image;
  final bool correct;
  final bool lethal;

  const DsOption({
    required this.id,
    required this.labelBn,
    this.image = '',
    this.correct = false,
    this.lethal = false,
  });

  factory DsOption.fromJson(Map<String, dynamic> j) => DsOption(
        id: j['id'] as String,
        labelBn: j['label_bn'] as String? ?? '',
        image: j['image'] as String? ?? '',
        correct: j['correct'] as bool? ?? false,
        lethal: j['lethal'] as bool? ?? false,
      );
}

enum DsKind { single, kit, match }

enum DsLane { office, site, isolate, work, close }

DsLane parseLane(String? raw) => switch (raw) {
      'site' => DsLane.site,
      'isolate' => DsLane.isolate,
      'work' => DsLane.work,
      'close' => DsLane.close,
      _ => DsLane.office,
    };

class DsStep {
  final String id;
  final DsLane lane;
  final DsKind kind;
  final String stamp;
  final String promptBn;
  final String hintBn;
  final String scene;
  final int missMin;
  final int missSafety;
  final List<String> essential;
  final List<String> forbidden;
  final List<DsOption> options;

  const DsStep({
    required this.id,
    required this.lane,
    required this.kind,
    required this.stamp,
    required this.promptBn,
    required this.hintBn,
    required this.options,
    this.scene = '',
    this.missMin = 8,
    this.missSafety = 10,
    this.essential = const [],
    this.forbidden = const [],
  });

  factory DsStep.fromJson(Map<String, dynamic> j) => DsStep(
        id: j['id'] as String,
        lane: parseLane(j['lane'] as String?),
        kind: switch (j['kind'] as String?) {
          'kit' => DsKind.kit,
          'match' => DsKind.match,
          _ => DsKind.single,
        },
        stamp: j['stamp'] as String? ?? '',
        promptBn: j['prompt_bn'] as String? ?? '',
        hintBn: j['hint_bn'] as String? ?? '',
        scene: j['scene'] as String? ?? '',
        missMin: (j['miss_min'] as num?)?.toInt() ?? 8,
        missSafety: (j['miss_safety'] as num?)?.toInt() ?? 10,
        essential: List<String>.from(j['essential'] as List? ?? const []),
        forbidden: List<String>.from(j['forbidden'] as List? ?? const []),
        options: [for (final o in j['options'] as List? ?? const []) DsOption.fromJson(o as Map<String, dynamic>)],
      );
}

class DsReply {
  final String id;
  final String labelBn;
  final bool ok;

  const DsReply({required this.id, required this.labelBn, required this.ok});

  factory DsReply.fromJson(Map<String, dynamic> j) => DsReply(
        id: j['id'] as String,
        labelBn: j['label_bn'] as String? ?? '',
        ok: j['ok'] as bool? ?? false,
      );
}

class DsCall {
  final String id;
  final String whoBn;
  final String portrait;
  final String lineBn;
  final List<DsReply> replies;

  const DsCall({
    required this.id,
    required this.whoBn,
    required this.portrait,
    required this.lineBn,
    required this.replies,
  });

  factory DsCall.fromJson(Map<String, dynamic> j) => DsCall(
        id: j['id'] as String,
        whoBn: j['who_bn'] as String? ?? '',
        portrait: j['portrait'] as String? ?? '',
        lineBn: j['line_bn'] as String? ?? '',
        replies: [for (final r in j['replies'] as List? ?? const []) DsReply.fromJson(r as Map<String, dynamic>)],
      );
}

class DsPack {
  final String titleBn;
  final int startHour;
  final int startMinute;
  final List<String> feeders;
  final List<DsPlanItem> plan;
  final List<DsSite> sites;
  final List<DsStep> steps;
  final List<DsCall> calls;

  const DsPack({
    required this.titleBn,
    required this.startHour,
    required this.startMinute,
    required this.feeders,
    required this.plan,
    required this.sites,
    required this.steps,
    required this.calls,
  });

  factory DsPack.fromJson(Map<String, dynamic> j) => DsPack(
        titleBn: j['title_bn'] as String? ?? 'ডিউটি স্লিপ',
        startHour: (j['start_hour'] as num?)?.toInt() ?? 20,
        startMinute: (j['start_minute'] as num?)?.toInt() ?? 10,
        feeders: List<String>.from(j['feeders'] as List? ?? const []),
        plan: [for (final p in j['plan'] as List? ?? const []) DsPlanItem.fromJson(p as Map<String, dynamic>)],
        sites: [for (final s in j['sites'] as List) DsSite.fromJson(s as Map<String, dynamic>)],
        steps: [for (final s in j['steps'] as List) DsStep.fromJson(s as Map<String, dynamic>)],
        calls: [for (final c in j['calls'] as List? ?? const []) DsCall.fromJson(c as Map<String, dynamic>)],
      );

  static Future<DsPack> load() async {
    final raw = await rootBundle.loadString('assets/data/duty_slip_job.json');
    return DsPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
