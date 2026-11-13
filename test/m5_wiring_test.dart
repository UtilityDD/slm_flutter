// Module 5 wiring: catalog status and engine, doGameFor, the mistakes book and
// the Learn board lookup, for all 30 rungs (19 Do levels, 10 boards, the gate).
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
import 'package:slm_flutter/features/game/m5_anneal_cut.dart' as m5_anneal_cut;
import 'package:slm_flutter/features/game/m5_cable_fault_type.dart' as m5_cable_fault_type;
import 'package:slm_flutter/features/game/m5_cable_route_locate.dart' as m5_cable_route_locate;
import 'package:slm_flutter/features/game/m5_cause_strike.dart' as m5_cause_strike;
import 'package:slm_flutter/features/game/m5_culprit_case.dart' as m5_culprit_case;
import 'package:slm_flutter/features/game/m5_dark_eyes.dart' as m5_dark_eyes;
import 'package:slm_flutter/features/game/m5_fault_address.dart' as m5_fault_address;
import 'package:slm_flutter/features/game/m5_fault_casebook.dart' as m5_fault_casebook;
import 'package:slm_flutter/features/game/m5_feeder_sectionalize.dart' as m5_feeder_sectionalize;
import 'package:slm_flutter/features/game/m5_gate_case.dart' as m5_gate_case;
import 'package:slm_flutter/features/game/m5_live_wire_guard.dart' as m5_live_wire_guard;
import 'package:slm_flutter/features/game/m5_lv_load_test.dart' as m5_lv_load_test;
import 'package:slm_flutter/features/game/m5_lv_street_read.dart' as m5_lv_street_read;
import 'package:slm_flutter/features/game/m5_pm_thermal_round.dart' as m5_pm_thermal_round;
import 'package:slm_flutter/features/game/m5_reblow_clock.dart' as m5_reblow_clock;
import 'package:slm_flutter/features/game/m5_recloser_watch.dart' as m5_recloser_watch;
import 'package:slm_flutter/features/game/m5_searchlight_patrol.dart' as m5_searchlight_patrol;
import 'package:slm_flutter/features/game/m5_sense_walk.dart' as m5_sense_walk;
import 'package:slm_flutter/features/game/m5_trip_call.dart' as m5_trip_call;
import 'package:slm_flutter/features/game/m5_workshop_referral.dart' as m5_workshop_referral;

const _ctx = LevelContext(
  rungId: '5.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '5.1',
  lessonTitleBn: 'পাঠ',
  ladderStep: 121,
);

class _Wire {
  const _Wire(this.engine, this.isPage, this.mistakes);
  final String engine;
  final bool Function(Widget) isPage;
  final List<DoMistake> mistakes;
}

void main() {
  final wires = <String, _Wire>{
    'do_5_1_a': _Wire('m5_trip_call', (w) => w is m5_trip_call.M5TripCallPage, m5_trip_call.M5TripMistakes.all),
    'do_5_1_b': _Wire('m5_recloser_watch', (w) => w is m5_recloser_watch.M5RecloserPage,
        m5_recloser_watch.M5RecloserMistakes.all),
    'do_5_2_a': _Wire('m5_fault_address', (w) => w is m5_fault_address.M5FaultAddressPage,
        m5_fault_address.M5FaMistakes.all),
    'do_5_2_b': _Wire('m5_sense_walk', (w) => w is m5_sense_walk.SenseWalkPage, m5_sense_walk.SenseWalkMistakes.all),
    'do_5_3_a': _Wire('m5_culprit_case', (w) => w is m5_culprit_case.M5CulpritCasePage,
        m5_culprit_case.M5CulpritMistakes.all),
    'do_5_3_b': _Wire('m5_anneal_cut', (w) => w is m5_anneal_cut.M5AnnealPage, m5_anneal_cut.M5AnnealMistakes.all),
    'do_5_4_a': _Wire('m5_feeder_sectionalize', (w) => w is m5_feeder_sectionalize.M5FeederSectionalizePage,
        m5_feeder_sectionalize.M5FeederMistakes.all),
    'do_5_4_b': _Wire('m5_reblow_clock', (w) => w is m5_reblow_clock.M5ReblowPage, m5_reblow_clock.M5ReblowMistakes.all),
    'do_5_5_a': _Wire('m5_lv_street_read', (w) => w is m5_lv_street_read.M5LvStreetReadPage,
        m5_lv_street_read.M5LvMistakes.all),
    'do_5_5_b': _Wire('m5_lv_load_test', (w) => w is m5_lv_load_test.M5LvLoadTestPage,
        m5_lv_load_test.M5LvLoadMistakes.all),
    'do_5_6_a': _Wire('m5_fault_casebook', (w) => w is m5_fault_casebook.M5FaultCasebookPage,
        m5_fault_casebook.M5CasebookMistakes.all),
    'do_5_6_b': _Wire('m5_live_wire_guard', (w) => w is m5_live_wire_guard.M5LiveWireGuardPage,
        m5_live_wire_guard.M5LiveWireMistakes.all),
    'do_5_7_a': _Wire('m5_searchlight_patrol', (w) => w is m5_searchlight_patrol.M5SearchlightPage,
        m5_searchlight_patrol.M5SearchlightMistakes.all),
    'do_5_7_b': _Wire('m5_dark_eyes', (w) => w is m5_dark_eyes.M5DarkEyesPage, m5_dark_eyes.M5DarkEyesMistakes.all),
    'do_5_8_a': _Wire('m5_cause_strike', (w) => w is m5_cause_strike.M5CauseStrikePage,
        m5_cause_strike.M5CauseStrikeMistakes.all),
    'do_5_8_b': _Wire('m5_workshop_referral', (w) => w is m5_workshop_referral.M5WorkshopReferralPage,
        m5_workshop_referral.M5WrMistakes.all),
    'do_5_9_a': _Wire('m5_cable_fault_type', (w) => w is m5_cable_fault_type.M5CableFaultTypePage,
        m5_cable_fault_type.M5CableMistakes.all),
    'do_5_9_b': _Wire('m5_cable_route_locate', (w) => w is m5_cable_route_locate.M5CableRouteLocatePage,
        m5_cable_route_locate.M5CrlMistakes.all),
    'do_5_10_a': _Wire('m5_pm_thermal_round', (w) => w is m5_pm_thermal_round.M5PmThermalRoundPage,
        m5_pm_thermal_round.M5PmMistakes.all),
    'gate_m5': _Wire('m5_gate_case', (w) => w is m5_gate_case.M5GateCasePage, m5_gate_case.M5GateMistakes.all),
  };

  final cat = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map;
  final packs = {for (final p in (cat['gamePacks'] as List).cast<Map<String, dynamic>>()) p['id'] as String: p};
  final rungs = [
    for (final r in (cat['rungDefs'] as List).cast<Map<String, dynamic>>())
      if (r['moduleId'] == 'm5') r,
  ];

  test('all 30 Module 5 rungs and their packs are playable', () {
    expect(rungs, hasLength(30));
    for (final r in rungs) {
      expect(r['status'], 'playable', reason: r['id'] as String);
      expect(packs[r['packId']]?['status'], 'playable', reason: r['packId'] as String);
    }
  });

  test('every Do pack and the gate open their own page', () {
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
      if (e.key == 'gate_m5') continue;
      final deadly = {for (final m in e.value.mistakes) if (m.deadly) m.key};
      expect((packs[e.key]!['deadlyRules'] as List).toSet(), deadly, reason: e.key);
    }
  });

  test('every Module 5 mistake is in the mistakes book (no key clash)', () {
    for (final e in wires.entries) {
      for (final m in e.value.mistakes) {
        expect(knownMistakes[m.key], same(m), reason: '${e.key}: ${m.key}');
      }
    }
  });

  test('every Module 5 lesson has its Learn board', () {
    final boards = {
      '5.1': learnBoardPack51,
      '5.2': learnBoardPack52,
      '5.3': learnBoardPack53,
      '5.4': learnBoardPack54,
      '5.5': learnBoardPack55,
      '5.6': learnBoardPack56,
      '5.7': learnBoardPack57,
      '5.8': learnBoardPack58,
      '5.9': learnBoardPack59,
      '5.10': learnBoardPack510,
    };
    for (final e in boards.entries) {
      expect(learnBoardPackFor(e.key), same(e.value), reason: e.key);
      expect(e.value.lessonId, e.key);
    }
  });
}
