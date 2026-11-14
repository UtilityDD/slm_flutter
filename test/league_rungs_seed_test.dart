// slm_app.league_rungs is APPEND-ONLY (supabase/slm_app_11_league_rungs_seed.sql):
// packed league stars use each rung's idx as the position, so an existing
// (rung_id, idx) pair may never change. test/fixtures/league_rungs_v1.txt is
// the frozen list of 2026-11-14 (idx 0..326 in ladder order). New rungs may
// only be added after it, in catalog (ladder) order, with the next idx.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/ladder_builder.dart';

/// (rung_id, idx, min_ms) rows of the seed file, in file order.
List<(String, int, int)> _seed() {
  final sql = File('supabase/slm_app_11_league_rungs_seed.sql').readAsStringSync();
  return [
    for (final m in RegExp(r"\('([^']+)',\s*(\d+),\s*(\d+)\)").allMatches(sql))
      (m.group(1)!, int.parse(m.group(2)!), int.parse(m.group(3)!)),
  ];
}

List<String> _frozen() => File('test/fixtures/league_rungs_v1.txt')
    .readAsLinesSync()
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the frozen v1 list keeps its idx: the seed starts with it, unchanged', () {
    final seed = _seed();
    final frozen = _frozen();
    expect(frozen, hasLength(327));
    expect(seed.length, greaterThanOrEqualTo(frozen.length));
    for (var i = 0; i < frozen.length; i++) {
      expect(seed[i].$1, frozen[i], reason: 'idx $i must stay ${frozen[i]} (append-only)');
      expect(seed[i].$2, i, reason: '${frozen[i]} keeps idx $i');
    }
  });

  test('idx runs 0..n-1 in file order, ids and idx are unique, min_ms is set', () {
    final seed = _seed();
    expect([for (final r in seed) r.$2], List.generate(seed.length, (i) => i));
    expect({for (final r in seed) r.$1}.length, seed.length);
    for (final r in seed) {
      expect(r.$3, greaterThan(0), reason: '${r.$1} needs a min_ms');
      expect(RegExp(r'^[0-9]+\.[0-9]+/(learn|do/[0-9])$|^m[0-9]+/gate$').hasMatch(r.$1), isTrue, reason: r.$1);
    }
  });

  test('every catalog rung is registered; new ones are appended in catalog order', () async {
    final ladder = const LadderBuilder().build(await ContentCatalog.loadAsset());
    final ids = [for (final r in ladder.rungs) r.id];
    final seedIds = [for (final r in _seed()) r.$1];
    final frozen = _frozen().toSet();

    final missing = [for (final id in ids) if (!seedIds.contains(id)) id];
    expect(missing, isEmpty, reason: 'add new rungs at the END of slm_app_11_league_rungs_seed.sql with the next idx');

    // Rungs added after v1 come in the catalog's order.
    final added = [for (final id in seedIds) if (!frozen.contains(id)) id];
    final addedInCatalogOrder = [for (final id in ids) if (added.contains(id)) id];
    expect(added.where(ids.contains).toList(), addedInCatalogOrder);
  });

  test('v1 matches the catalog ladder order of 2026-11-14', () async {
    final ladder = const LadderBuilder().build(await ContentCatalog.loadAsset());
    final ids = [for (final r in ladder.rungs) r.id];
    final frozen = _frozen();
    // Today's catalog has exactly these rungs in this order. If the catalog is
    // reordered on purpose later, the registry still must not change: relax
    // only this check, never the append-only ones above.
    expect([for (final id in ids) if (frozen.contains(id)) id], frozen);
  });

  test('the SQL refuses changes to idx and rung_id (append-only trigger)', () {
    final sql = File('supabase/slm_app_10_league.sql').readAsStringSync();
    expect(sql, contains('CREATE TRIGGER league_rungs_append_only'));
    expect(sql, contains('BEFORE UPDATE OR DELETE ON slm_app.league_rungs'));
  });
}
