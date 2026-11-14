import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local content catalog — order and playability live here, not in Dart consts.
class ContentCatalog {
  final int version;
  final int softCap;
  final int doSlotsPerLesson;
  final List<CatalogModule> modules;
  final List<CatalogLesson> lessons;
  final List<CatalogRungDef> rungDefs;
  final Map<String, CatalogGamePack> packsById;
  final List<CatalogGuideLine> guideLines;

  const ContentCatalog({
    required this.version,
    required this.softCap,
    required this.doSlotsPerLesson,
    required this.modules,
    required this.lessons,
    required this.rungDefs,
    required this.packsById,
    required this.guideLines,
  });

  factory ContentCatalog.fromJson(Map<String, dynamic> json) {
    final packs = <CatalogGamePack>[
      for (final raw in (json['gamePacks'] as List? ?? const []))
        CatalogGamePack.fromJson(Map<String, dynamic>.from(raw as Map)),
    ];
    return ContentCatalog(
      version: (json['version'] as num?)?.toInt() ?? 1,
      softCap: (json['softCap'] as num?)?.toInt() ?? 400,
      doSlotsPerLesson: (json['doSlotsPerLesson'] as num?)?.toInt() ?? 2,
      modules: [
        for (final raw in (json['modules'] as List? ?? const []))
          CatalogModule.fromJson(Map<String, dynamic>.from(raw as Map)),
      ]..sort((a, b) => a.order.compareTo(b.order)),
      lessons: [
        for (final raw in (json['lessons'] as List? ?? const []))
          CatalogLesson.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      rungDefs: [
        for (final raw in (json['rungDefs'] as List? ?? const []))
          CatalogRungDef.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      packsById: {for (final p in packs) p.id: p},
      guideLines: [
        for (final raw in (json['guideLines'] as List? ?? const []))
          CatalogGuideLine.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
    );
  }

  static Future<ContentCatalog> loadAsset({
    String path = 'assets/game/catalog/content_catalog.json',
  }) async {
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final catalog = ContentCatalog.fromJson(json);
    catalog.validate();
    return catalog;
  }

  void validate() {
    if (modules.length != 10) {
      throw StateError('Expected 10 modules, got ${modules.length}');
    }
    if (lessons.length != 109) {
      throw StateError('Expected 109 lessons, got ${lessons.length}');
    }
    if (rungDefs.length != 327) {
      throw StateError('Expected 327 rungs, got ${rungDefs.length}');
    }
    for (final r in rungDefs) {
      if (!packsById.containsKey(r.packId)) {
        throw StateError('Missing pack ${r.packId} for rung ${r.id}');
      }
    }
  }
}

enum CatalogRungKind { learn, doKind, gate }

enum CatalogRungStatus { playable, comingSoon }

class CatalogModule {
  final String id;
  final int order;
  final String rankName;
  final String sceneryZone;
  final String gateRungId;
  final int lessonCount;

  const CatalogModule({
    required this.id,
    required this.order,
    required this.rankName,
    required this.sceneryZone,
    required this.gateRungId,
    required this.lessonCount,
  });

  factory CatalogModule.fromJson(Map<String, dynamic> json) => CatalogModule(
        id: json['id'] as String,
        order: (json['order'] as num).toInt(),
        rankName: json['rankName'] as String? ?? '',
        sceneryZone: json['sceneryZone'] as String? ?? '',
        gateRungId: json['gateRungId'] as String? ?? '',
        lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
      );
}

class CatalogLesson {
  final String id;
  final String moduleId;
  final int order;
  final String titleBn;
  final String learnPackId;
  final List<String> doSlotIds;

  const CatalogLesson({
    required this.id,
    required this.moduleId,
    required this.order,
    required this.titleBn,
    required this.learnPackId,
    required this.doSlotIds,
  });

  factory CatalogLesson.fromJson(Map<String, dynamic> json) => CatalogLesson(
        id: json['id'] as String,
        moduleId: json['moduleId'] as String,
        order: (json['order'] as num).toInt(),
        titleBn: json['titleBn'] as String? ?? '',
        learnPackId: json['learnPackId'] as String? ?? '',
        doSlotIds: [
          for (final v in (json['doSlotIds'] as List? ?? const [])) v.toString(),
        ],
      );
}

class CatalogRungDef {
  final String id;
  final CatalogRungKind kind;
  final String? lessonId;
  final String moduleId;
  final String packId;
  final CatalogRungStatus status;
  final int orderInModule;

  const CatalogRungDef({
    required this.id,
    required this.kind,
    required this.lessonId,
    required this.moduleId,
    required this.packId,
    required this.status,
    required this.orderInModule,
  });

  factory CatalogRungDef.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'] as String? ?? 'do';
    final kind = switch (kindRaw) {
      'learn' => CatalogRungKind.learn,
      'gate' => CatalogRungKind.gate,
      _ => CatalogRungKind.doKind,
    };
    final statusRaw = json['status'] as String? ?? 'comingSoon';
    final status = statusRaw == 'playable' ? CatalogRungStatus.playable : CatalogRungStatus.comingSoon;
    return CatalogRungDef(
      id: json['id'] as String,
      kind: kind,
      lessonId: json['lessonId'] as String?,
      moduleId: json['moduleId'] as String,
      packId: json['packId'] as String,
      status: status,
      orderInModule: (json['orderInModule'] as num?)?.toInt() ?? 0,
    );
  }
}

class CatalogGamePack {
  final String id;
  final String engineType;
  final String? lessonId;
  final String? moduleId;
  final int? slot;
  final CatalogRungStatus status;
  final String? legacyHint;
  final List<String> deadlyRules;

  /// Number of the built Do level (`dsLevels`) this pack opens until it has an
  /// engine of its own. Chosen by topic, so the Do after a lesson practises
  /// that lesson. Null: no mapping (the ladder falls back to play order).
  final int? legacyLevel;

  const CatalogGamePack({
    required this.id,
    required this.engineType,
    required this.lessonId,
    required this.moduleId,
    required this.slot,
    required this.status,
    required this.legacyHint,
    required this.deadlyRules,
    this.legacyLevel,
  });

  factory CatalogGamePack.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'comingSoon';
    return CatalogGamePack(
      id: json['id'] as String,
      engineType: json['engineType'] as String? ?? 'placeholder',
      lessonId: json['lessonId'] as String?,
      moduleId: json['moduleId'] as String?,
      slot: (json['slot'] as num?)?.toInt(),
      status: statusRaw == 'playable' ? CatalogRungStatus.playable : CatalogRungStatus.comingSoon,
      legacyHint: json['legacyHint'] as String?,
      deadlyRules: [
        for (final v in (json['deadlyRules'] as List? ?? const [])) v.toString(),
      ],
      legacyLevel: (json['legacyLevel'] as num?)?.toInt(),
    );
  }
}

class CatalogGuideLine {
  final String id;
  final String mood;
  final String bnText;
  final String when;

  const CatalogGuideLine({
    required this.id,
    required this.mood,
    required this.bnText,
    required this.when,
  });

  factory CatalogGuideLine.fromJson(Map<String, dynamic> json) => CatalogGuideLine(
        id: json['id'] as String,
        mood: json['mood'] as String? ?? 'talk',
        bnText: json['bnText'] as String? ?? '',
        when: json['when'] as String? ?? '',
      );
}

final contentCatalogProvider = FutureProvider<ContentCatalog>((ref) async {
  ref.keepAlive();
  return ContentCatalog.loadAsset();
});
