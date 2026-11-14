import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_catalog.dart';

/// One display rung on the mountain. Numbers are computed — never saved.
class BuiltRung {
  final int number;
  final CatalogRungDef def;
  final CatalogModule module;
  final CatalogLesson? lesson;
  final CatalogGamePack pack;

  const BuiltRung({
    required this.number,
    required this.def,
    required this.module,
    required this.lesson,
    required this.pack,
  });

  String get id => def.id;
  CatalogRungKind get kind => def.kind;
  CatalogRungStatus get status => def.status;
  bool get isComingSoon => status != CatalogRungStatus.playable;
  bool get isGate => kind == CatalogRungKind.gate;
  bool get isLearn => kind == CatalogRungKind.learn;
}

class BuiltLadder {
  final ContentCatalog catalog;
  final List<BuiltRung> rungs;
  final int softCap;

  const BuiltLadder({
    required this.catalog,
    required this.rungs,
    required this.softCap,
  });

  int get length => rungs.length;

  BuiltRung? byId(String id) {
    for (final r in rungs) {
      if (r.id == id) return r;
    }
    return null;
  }
}

class LadderBuilder {
  const LadderBuilder();

  BuiltLadder build(ContentCatalog catalog) {
    final modulesById = {for (final m in catalog.modules) m.id: m};
    final lessonsById = {for (final l in catalog.lessons) l.id: l};

    // Stable climb order: module.order, then orderInModule.
    final defs = [...catalog.rungDefs]..sort((a, b) {
        final ma = modulesById[a.moduleId]?.order ?? 0;
        final mb = modulesById[b.moduleId]?.order ?? 0;
        if (ma != mb) return ma.compareTo(mb);
        return a.orderInModule.compareTo(b.orderInModule);
      });

    final rungs = <BuiltRung>[];
    for (var i = 0; i < defs.length; i++) {
      final def = defs[i];
      final module = modulesById[def.moduleId];
      if (module == null) {
        throw StateError('Unknown module ${def.moduleId}');
      }
      final pack = catalog.packsById[def.packId];
      if (pack == null) {
        throw StateError('Unknown pack ${def.packId}');
      }
      rungs.add(
        BuiltRung(
          number: i + 1,
          def: def,
          module: module,
          lesson: def.lessonId == null ? null : lessonsById[def.lessonId!],
          pack: pack,
        ),
      );
    }

    return BuiltLadder(
      catalog: catalog,
      rungs: rungs,
      softCap: catalog.softCap,
    );
  }
}

final ladderBuilderProvider = Provider<LadderBuilder>((ref) => const LadderBuilder());

final builtLadderProvider = FutureProvider<BuiltLadder>((ref) async {
  ref.keepAlive();
  final catalog = await ref.watch(contentCatalogProvider.future);
  return ref.watch(ladderBuilderProvider).build(catalog);
});
