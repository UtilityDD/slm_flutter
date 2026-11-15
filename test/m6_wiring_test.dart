// Module 6 Wave A wiring: catalog status and engine, doGameFor, the mistakes
// book and the Learn board lookup, for the 15 rungs of lessons 6.1–6.5
// (10 Do levels, 5 boards). Lessons 6.6–6.11 and the gate stay comingSoon.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/do_games.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/mistakes_book.dart';
import 'package:slm_flutter/features/game/m6_ab_gap_log.dart' as m6_ab_gap_log;
import 'package:slm_flutter/features/game/m6_ab_unjam.dart' as m6_ab_unjam;
import 'package:slm_flutter/features/game/m6_breaker_rack.dart' as m6_breaker_rack;
import 'package:slm_flutter/features/game/m6_dtr_coil_forensic.dart' as m6_dtr_coil_forensic;
import 'package:slm_flutter/features/game/m6_dtr_photo_report.dart' as m6_dtr_photo_report;
import 'package:slm_flutter/features/game/m6_fuse_chain.dart' as m6_fuse_chain;
import 'package:slm_flutter/features/game/m6_fuse_gauge.dart' as m6_fuse_gauge;
import 'package:slm_flutter/features/game/m6_trip_log.dart' as m6_trip_log;
import 'package:slm_flutter/features/game/m6_ug_cable_lay.dart' as m6_ug_cable_lay;
import 'package:slm_flutter/features/game/m6_ug_dig_guard.dart' as m6_ug_dig_guard;

const _ctx = LevelContext(
  rungId: '6.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '6.1',
  lessonTitleBn: 'পাঠ',
  ladderStep: 151,
);

class _Wire {
  const _Wire(this.engine, this.isPage, this.mistakes);
  final String engine;
  final bool Function(Widget) isPage;
  final List<DoMistake> mistakes;
}

/// Wave A: lessons 6.1–6.5.
const _waveA = {'6.1', '6.2', '6.3', '6.4', '6.5'};

void main() {
  final wires = <String, _Wire>{
    'do_6_1_a': _Wire('m6_dtr_photo_report', (w) => w is m6_dtr_photo_report.M6DtrPhotoReportPage,
        m6_dtr_photo_report.M6PhotoMistakes.all),
    'do_6_1_b': _Wire('m6_dtr_coil_forensic', (w) => w is m6_dtr_coil_forensic.M6DtrCoilForensicPage,
        m6_dtr_coil_forensic.M6CoilMistakes.all),
    'do_6_2_a': _Wire('m6_trip_log', (w) => w is m6_trip_log.M6TripLogPage, m6_trip_log.M6TripLogMistakes.all),
    'do_6_2_b': _Wire('m6_breaker_rack', (w) => w is m6_breaker_rack.M6BreakerRackPage,
        m6_breaker_rack.M6BreakerRackMistakes.all),
    'do_6_3_a': _Wire('m6_fuse_gauge', (w) => w is m6_fuse_gauge.M6FuseGaugePage, m6_fuse_gauge.M6FuseGaugeMistakes.all),
    'do_6_3_b': _Wire('m6_fuse_chain', (w) => w is m6_fuse_chain.M6FuseChainPage, m6_fuse_chain.M6ChainMistakes.all),
    'do_6_4_a': _Wire('m6_ab_gap_log', (w) => w is m6_ab_gap_log.M6AbGapLogPage, m6_ab_gap_log.M6AbGapLogMistakes.all),
    'do_6_4_b': _Wire('m6_ab_unjam', (w) => w is m6_ab_unjam.M6AbUnjamPage, m6_ab_unjam.M6AbUnjamMistakes.all),
    'do_6_5_a': _Wire('m6_ug_cable_lay', (w) => w is m6_ug_cable_lay.M6UgCablePage,
        m6_ug_cable_lay.M6UgCableMistakes.all),
    'do_6_5_b': _Wire('m6_ug_dig_guard', (w) => w is m6_ug_dig_guard.M6UgDigGuardPage,
        m6_ug_dig_guard.M6DigMistakes.all),
  };

  final cat = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map;
  final packs = {for (final p in (cat['gamePacks'] as List).cast<Map<String, dynamic>>()) p['id'] as String: p};
  final rungs = [
    for (final r in (cat['rungDefs'] as List).cast<Map<String, dynamic>>())
      if (r['moduleId'] == 'm6') r,
  ];
  final waveA = [for (final r in rungs) if (_waveA.contains(r['lessonId'])) r];

  test('the 15 Wave A rungs and their packs are playable; the rest of Module 6 is not yet', () {
    expect(waveA, hasLength(15));
    for (final r in waveA) {
      expect(r['status'], 'playable', reason: r['id'] as String);
      expect(packs[r['packId']]?['status'], 'playable', reason: r['packId'] as String);
    }
    for (final r in rungs) {
      if (_waveA.contains(r['lessonId'])) continue;
      expect(r['status'], 'comingSoon', reason: r['id'] as String);
    }
    expect(packs['gate_m6']?['status'], 'comingSoon');
  });

  test('every Wave A Do pack opens its own page', () {
    expect(wires.keys.toSet(), {
      for (final r in waveA)
        if (r['kind'] == 'do') r['packId'] as String,
    });
    for (final e in wires.entries) {
      final json = packs[e.key]!;
      expect(json['engineType'], e.value.engine, reason: e.key);
      final b = doGameFor(CatalogGamePack.fromJson(json));
      expect(b, isNotNull, reason: e.key);
      expect(e.value.isPage(b!(_ctx, true)), isTrue, reason: e.key);
    }
  });

  test("a Do pack's deadlyRules list exactly its level's deadly mistakes", () {
    for (final e in wires.entries) {
      final deadly = {for (final m in e.value.mistakes) if (m.deadly) m.key};
      expect(deadly, isNotEmpty, reason: e.key);
      final rules = (packs[e.key]!['deadlyRules'] as List).cast<String>();
      expect(rules.toSet(), deadly, reason: e.key);
      expect(rules, hasLength(rules.toSet().length), reason: '${e.key}: no duplicate rule');
    }
  });

  test('every Wave A mistake is in the mistakes book (no key clash)', () {
    for (final e in wires.entries) {
      for (final m in e.value.mistakes) {
        expect(knownMistakes[m.key], same(m), reason: '${e.key}: ${m.key}');
      }
    }
  });

  test('every Wave A lesson has its Learn board', () {
    final boards = {
      '6.1': learnBoardPack61,
      '6.2': learnBoardPack62,
      '6.3': learnBoardPack63,
      '6.4': learnBoardPack64,
      '6.5': learnBoardPack65,
    };
    for (final e in boards.entries) {
      expect(learnBoardPackFor(e.key), same(e.value), reason: e.key);
      expect(e.value.lessonId, e.key);
      expect(packs['learn_${e.key.replaceAll('.', '_')}']?['engineType'], 'learn_cards', reason: e.key);
    }
  });
}
