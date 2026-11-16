// Module 6 wiring: catalog status and engine, doGameFor, the mistakes book and
// the Learn board lookup, for the 33 rungs of lessons 6.1–6.11 and the gate
// (21 Do levels, 11 boards, the gate). Wave A (6.1–6.5) wired 2026-11-15,
// Wave B (6.6–6.11 and the gate) 2026-11-16.
//
// A rung still being built sits in [_pending] and must stay comingSoon. When it
// lands: take its pack id out of [_pending], add its import and its `_Wire`
// line to `wires`. The end state is an empty [_pending].
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
import 'package:slm_flutter/features/game/m6_abc_clamp_seat.dart' as m6_abc_clamp_seat;
import 'package:slm_flutter/features/game/m6_abc_nick_seal.dart' as m6_abc_nick_seal;
import 'package:slm_flutter/features/game/m6_breaker_rack.dart' as m6_breaker_rack;
import 'package:slm_flutter/features/game/m6_capbank_meter.dart' as m6_capbank_meter;
import 'package:slm_flutter/features/game/m6_capbank_wait.dart' as m6_capbank_wait;
import 'package:slm_flutter/features/game/m6_dtr_coil_forensic.dart' as m6_dtr_coil_forensic;
import 'package:slm_flutter/features/game/m6_dtr_photo_report.dart' as m6_dtr_photo_report;
import 'package:slm_flutter/features/game/m6_earth_pit_test.dart' as m6_earth_pit_test;
import 'package:slm_flutter/features/game/m6_fuse_chain.dart' as m6_fuse_chain;
import 'package:slm_flutter/features/game/m6_fuse_gauge.dart' as m6_fuse_gauge;
import 'package:slm_flutter/features/game/m6_gate_storm_feeder.dart' as m6_gate_storm_feeder;
import 'package:slm_flutter/features/game/m6_meter_pulse.dart' as m6_meter_pulse;
import 'package:slm_flutter/features/game/m6_meter_swap_proof.dart' as m6_meter_swap_proof;
import 'package:slm_flutter/features/game/m6_pillar_newway.dart' as m6_pillar_newway;
import 'package:slm_flutter/features/game/m6_pillar_thermal.dart' as m6_pillar_thermal;
import 'package:slm_flutter/features/game/m6_reclose_count.dart' as m6_reclose_count;
import 'package:slm_flutter/features/game/m6_trip_log.dart' as m6_trip_log;
import 'package:slm_flutter/features/game/m6_ug_cable_lay.dart' as m6_ug_cable_lay;
import 'package:slm_flutter/features/game/m6_ug_dig_guard.dart' as m6_ug_dig_guard;
import 'package:slm_flutter/features/game/m6_upstream_trace.dart' as m6_upstream_trace;

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

/// Rungs still being built (comingSoon until they land). Empty: all 33 are wired.
const _pending = <String>{};

/// Do levels with no deadly mistake at all (their deadlyRules is []).
const _noDeadly = {'do_6_10_a'};

void main() {
  final wires = <String, _Wire>{
    // Wave A
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
    // Wave B
    'do_6_6_a': _Wire('m6_abc_clamp_seat', (w) => w is m6_abc_clamp_seat.M6ClampSeatPage,
        m6_abc_clamp_seat.M6ClampMistakes.all),
    'do_6_6_b': _Wire('m6_abc_nick_seal', (w) => w is m6_abc_nick_seal.M6NickSealPage,
        m6_abc_nick_seal.M6NickSealMistakes.all),
    'do_6_7_a': _Wire('m6_capbank_wait', (w) => w is m6_capbank_wait.M6CapbankWaitPage,
        m6_capbank_wait.M6CapMistakes.all),
    'do_6_7_b': _Wire('m6_capbank_meter', (w) => w is m6_capbank_meter.M6CapbankMeterPage,
        m6_capbank_meter.M6CapbankMeterMistakes.all),
    'do_6_8_a': _Wire('m6_reclose_count', (w) => w is m6_reclose_count.M6RecloseCountPage,
        m6_reclose_count.M6RecloseCountMistakes.all),
    'do_6_8_b': _Wire('m6_upstream_trace', (w) => w is m6_upstream_trace.M6UpstreamTracePage,
        m6_upstream_trace.M6UpstreamTraceMistakes.all),
    'do_6_9_a': _Wire('m6_pillar_thermal', (w) => w is m6_pillar_thermal.M6PillarThermalPage,
        m6_pillar_thermal.M6PillarThermalMistakes.all),
    'do_6_9_b': _Wire('m6_pillar_newway', (w) => w is m6_pillar_newway.M6PillarNewwayPage,
        m6_pillar_newway.M6PillarNewwayMistakes.all),
    'do_6_10_a': _Wire('m6_meter_pulse', (w) => w is m6_meter_pulse.M6MeterPulsePage,
        m6_meter_pulse.M6MeterPulseMistakes.all),
    'do_6_10_b': _Wire('m6_meter_swap_proof', (w) => w is m6_meter_swap_proof.M6MeterSwapPage,
        m6_meter_swap_proof.M6MeterSwapMistakes.all),
    'do_6_11_a': _Wire('m6_earth_pit_test', (w) => w is m6_earth_pit_test.M6EarthPitPage,
        m6_earth_pit_test.M6EarthPitMistakes.all),
    'gate_m6': _Wire('m6_gate_storm_feeder', (w) => w is m6_gate_storm_feeder.M6GateStormFeederPage,
        m6_gate_storm_feeder.M6GMistakes.all),
  };

  final boards = {
    '6.1': learnBoardPack61,
    '6.2': learnBoardPack62,
    '6.3': learnBoardPack63,
    '6.4': learnBoardPack64,
    '6.5': learnBoardPack65,
    '6.6': learnBoardPack66,
    '6.7': learnBoardPack67,
    '6.8': learnBoardPack68,
    '6.9': learnBoardPack69,
    '6.10': learnBoardPack610,
    '6.11': learnBoardPack611,
  };

  final cat = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map;
  final packs = {for (final p in (cat['gamePacks'] as List).cast<Map<String, dynamic>>()) p['id'] as String: p};
  final rungs = [
    for (final r in (cat['rungDefs'] as List).cast<Map<String, dynamic>>())
      if (r['moduleId'] == 'm6') r,
  ];
  final ready = [for (final r in rungs) if (!_pending.contains(r['packId'])) r];

  test('the 33 Module 6 rungs: all playable except the pending ones', () {
    expect(rungs, hasLength(33));
    expect(ready, hasLength(33 - _pending.length));
    for (final r in rungs) {
      final want = _pending.contains(r['packId']) ? 'comingSoon' : 'playable';
      expect(r['status'], want, reason: r['id'] as String);
      expect(packs[r['packId']]?['status'], want, reason: r['packId'] as String);
    }
  });

  test('every ready Do pack and the gate open their own page', () {
    expect(wires.keys.toSet(), {
      for (final r in ready)
        if (r['kind'] != 'learn') r['packId'] as String,
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
      final rules = (packs[e.key]!['deadlyRules'] as List).cast<String>();
      if (e.key == 'gate_m6') {
        // Same shape as gate_m5: the gate's own deadly list lives in M6GMistakes.
        expect(rules, ['lethal_any_marked']);
        expect(e.value.mistakes.where((m) => m.deadly), isNotEmpty);
        continue;
      }
      final deadly = {for (final m in e.value.mistakes) if (m.deadly) m.key};
      if (_noDeadly.contains(e.key)) {
        expect(deadly, isEmpty, reason: '${e.key} is listed as having no deadly mistake');
      } else {
        expect(deadly, isNotEmpty, reason: e.key);
      }
      expect(rules.toSet(), deadly, reason: e.key);
      expect(rules, hasLength(rules.toSet().length), reason: '${e.key}: no duplicate rule');
    }
  });

  test('every Module 6 mistake is in the mistakes book (no key clash)', () {
    for (final e in wires.entries) {
      for (final m in e.value.mistakes) {
        expect(knownMistakes[m.key], same(m), reason: '${e.key}: ${m.key}');
      }
    }
  });

  test('every Module 6 lesson has its Learn board', () {
    expect(boards.keys.toSet(), {for (final r in rungs) if (r['kind'] == 'learn') r['lessonId'] as String});
    for (final e in boards.entries) {
      expect(learnBoardPackFor(e.key), same(e.value), reason: e.key);
      expect(e.value.lessonId, e.key);
      expect(packs['learn_${e.key.replaceAll('.', '_')}']?['engineType'], 'learn_cards', reason: e.key);
    }
  });
}
