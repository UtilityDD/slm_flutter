import 'dart:convert';

import 'package:flutter/services.dart';

class ShSite {
  final String id;
  final String nameBn;
  final String bg;
  final String introBn;

  const ShSite({
    required this.id,
    required this.nameBn,
    required this.bg,
    required this.introBn,
  });

  factory ShSite.fromJson(Map<String, dynamic> j) => ShSite(
        id: j['id'] as String,
        nameBn: j['name_bn'] as String? ?? '',
        bg: j['bg'] as String? ?? '',
        introBn: j['intro_bn'] as String? ?? '',
      );
}

class ShOption {
  final String id;
  final String labelBn;
  final String image;
  final bool correct;

  const ShOption({
    required this.id,
    required this.labelBn,
    this.image = '',
    this.correct = false,
  });

  factory ShOption.fromJson(Map<String, dynamic> j) => ShOption(
        id: j['id'] as String,
        labelBn: j['label_bn'] as String? ?? '',
        image: j['image'] as String? ?? '',
        correct: j['correct'] as bool? ?? false,
      );
}

enum ShKind { single, multi }

class ShStep {
  final String id;
  final String mantra;
  final ShKind kind;
  final String promptBn;
  final String voiceBn;
  final String hintBn;
  final int reward;
  final int penalty;
  final List<String> essential;
  final List<String> forbidden;
  final List<ShOption> options;

  const ShStep({
    required this.id,
    required this.mantra,
    required this.kind,
    required this.promptBn,
    required this.voiceBn,
    required this.reward,
    required this.penalty,
    required this.options,
    this.hintBn = '',
    this.essential = const [],
    this.forbidden = const [],
  });

  factory ShStep.fromJson(Map<String, dynamic> j) => ShStep(
        id: j['id'] as String,
        mantra: j['mantra'] as String? ?? '',
        kind: (j['kind'] as String?) == 'multi' ? ShKind.multi : ShKind.single,
        promptBn: j['prompt_bn'] as String? ?? '',
        voiceBn: j['voice_bn'] as String? ?? '',
        hintBn: j['hint_bn'] as String? ?? '',
        reward: (j['reward'] as num?)?.toInt() ?? 20,
        penalty: (j['penalty'] as num?)?.toInt() ?? 10,
        essential: List<String>.from(j['essential'] as List? ?? const []),
        forbidden: List<String>.from(j['forbidden'] as List? ?? const []),
        options: [for (final o in j['options'] as List) ShOption.fromJson(o as Map<String, dynamic>)],
      );
}

class ShDisturbance {
  final String id;
  final String lineBn;
  final int penalty;

  const ShDisturbance({required this.id, required this.lineBn, required this.penalty});

  factory ShDisturbance.fromJson(Map<String, dynamic> j) => ShDisturbance(
        id: j['id'] as String,
        lineBn: j['line_bn'] as String? ?? '',
        penalty: (j['penalty'] as num?)?.toInt() ?? 8,
      );
}

class SafeHomePack {
  final String titleBn;
  final String subtitleBn;
  final int timeSeconds;
  final List<ShSite> sites;
  final List<ShStep> steps;
  final List<ShDisturbance> disturbances;

  const SafeHomePack({
    required this.titleBn,
    required this.subtitleBn,
    required this.timeSeconds,
    required this.sites,
    required this.steps,
    required this.disturbances,
  });

  factory SafeHomePack.fromJson(Map<String, dynamic> j) => SafeHomePack(
        titleBn: j['title_bn'] as String? ?? 'SAFE HOME',
        subtitleBn: j['subtitle_bn'] as String? ?? '',
        timeSeconds: (j['time_seconds'] as num?)?.toInt() ?? 240,
        sites: [for (final s in j['sites'] as List) ShSite.fromJson(s as Map<String, dynamic>)],
        steps: [for (final s in j['steps'] as List) ShStep.fromJson(s as Map<String, dynamic>)],
        disturbances: [
          for (final d in j['disturbances'] as List? ?? const []) ShDisturbance.fromJson(d as Map<String, dynamic>),
        ],
      );

  static Future<SafeHomePack> load() async {
    final raw = await rootBundle.loadString('assets/data/safe_home_snapped.json');
    return SafeHomePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
