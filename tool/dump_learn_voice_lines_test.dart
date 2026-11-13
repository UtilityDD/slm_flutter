// Lists every fixed coach / rival line that has no recorded clip yet, for
// tool/make_learn_voice.py. Run from the repo root:
//   flutter test tool/dump_learn_voice_lines_test.dart
// Writes tool/learn_voice_lines.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/core/en_digits.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_voice.dart';
import 'package:slm_flutter/features/game/m2_comealong_pick.dart' as m2_comealong_pick;
import 'package:slm_flutter/features/game/m2_comealong_pull.dart' as m2_comealong_pull;
import 'package:slm_flutter/features/game/m2_crimp_steps.dart' as m2_crimp_steps;
import 'package:slm_flutter/features/game/m2_dead_test.dart' as m2_dead_test;
import 'package:slm_flutter/features/game/m2_gate_field.dart' as m2_gate_field;
import 'package:slm_flutter/features/game/m2_hotstick_check.dart' as m2_hotstick_check;
import 'package:slm_flutter/features/game/m2_hotstick_operate.dart' as m2_hotstick_operate;
import 'package:slm_flutter/features/game/m2_hydraulic_pick.dart' as m2_hydraulic_pick;
import 'package:slm_flutter/features/game/m2_hydraulic_use.dart' as m2_hydraulic_use;
import 'package:slm_flutter/features/game/m2_lug_pick.dart' as m2_lug_pick;
import 'package:slm_flutter/features/game/m2_megger_prep.dart' as m2_megger_prep;
import 'package:slm_flutter/features/game/m2_megger_read.dart' as m2_megger_read;
import 'package:slm_flutter/features/game/m2_meter_setup.dart' as m2_meter_setup;
import 'package:slm_flutter/features/game/m2_phase_meter.dart' as m2_phase_meter;
import 'package:slm_flutter/features/game/m2_phase_swap.dart' as m2_phase_swap;
import 'package:slm_flutter/features/game/m2_skin_cut.dart' as m2_skin_cut;
import 'package:slm_flutter/features/game/m2_skin_tools.dart' as m2_skin_tools;
import 'package:slm_flutter/features/game/m2_tool_care.dart' as m2_tool_care;
import 'package:slm_flutter/features/game/m2_tool_use.dart' as m2_tool_use;
import 'package:slm_flutter/features/game/m2_toolbox_pack.dart' as m2_toolbox_pack;
import 'package:slm_flutter/features/game/m3_conductor_id.dart' as m3_conductor_id;
import 'package:slm_flutter/features/game/m3_conductor_joint.dart' as m3_conductor_joint;
import 'package:slm_flutter/features/game/m3_crossarm_check.dart' as m3_crossarm_check;
import 'package:slm_flutter/features/game/m3_crossarm_pick.dart' as m3_crossarm_pick;
import 'package:slm_flutter/features/game/m3_dtr_checkup.dart' as m3_dtr_checkup;
import 'package:slm_flutter/features/game/m3_dtr_tap.dart' as m3_dtr_tap;
import 'package:slm_flutter/features/game/m3_fuse_rating.dart' as m3_fuse_rating;
import 'package:slm_flutter/features/game/m3_gate_field.dart' as m3_gate_field;
import 'package:slm_flutter/features/game/m3_guard_patrol.dart' as m3_guard_patrol;
import 'package:slm_flutter/features/game/m3_guard_repair.dart' as m3_guard_repair;
import 'package:slm_flutter/features/game/m3_horngap_set.dart' as m3_horngap_set;
import 'package:slm_flutter/features/game/m3_insulator_patrol.dart' as m3_insulator_patrol;
import 'package:slm_flutter/features/game/m3_insulator_pick.dart' as m3_insulator_pick;
import 'package:slm_flutter/features/game/m3_la_earth.dart' as m3_la_earth;
import 'package:slm_flutter/features/game/m3_la_patrol.dart' as m3_la_patrol;
import 'package:slm_flutter/features/game/m3_meter_call.dart' as m3_meter_call;
import 'package:slm_flutter/features/game/m3_pillar_fuse.dart' as m3_pillar_fuse;
import 'package:slm_flutter/features/game/m3_pillar_inspect.dart' as m3_pillar_inspect;
import 'package:slm_flutter/features/game/m3_service_drop.dart' as m3_service_drop;
import 'package:slm_flutter/features/game/m3_sld_isolate.dart' as m3_sld_isolate;
import 'package:slm_flutter/features/game/m4_do_open.dart' as m4_do_open;
import 'package:slm_flutter/features/game/m4_do_refuse.dart' as m4_do_refuse;
import 'package:slm_flutter/features/game/m4_dp_dress.dart' as m4_dp_dress;
import 'package:slm_flutter/features/game/m4_dp_survey.dart' as m4_dp_survey;
import 'package:slm_flutter/features/game/m4_dtr_temp.dart' as m4_dtr_temp;
import 'package:slm_flutter/features/game/m4_earth_fix.dart' as m4_earth_fix;
import 'package:slm_flutter/features/game/m4_earth_test.dart' as m4_earth_test;
import 'package:slm_flutter/features/game/m4_gate_field.dart' as m4_gate_field;
import 'package:slm_flutter/features/game/m4_insulator_prep.dart' as m4_insulator_prep;
import 'package:slm_flutter/features/game/m4_insulator_swap.dart' as m4_insulator_swap;
import 'package:slm_flutter/features/game/m4_jumper_make.dart' as m4_jumper_make;
import 'package:slm_flutter/features/game/m4_jumper_tight.dart' as m4_jumper_tight;
import 'package:slm_flutter/features/game/m4_oil_level.dart' as m4_oil_level;
import 'package:slm_flutter/features/game/m4_service_connect.dart' as m4_service_connect;
import 'package:slm_flutter/features/game/m4_service_plan.dart' as m4_service_plan;
import 'package:slm_flutter/features/game/m4_streetlight_find.dart' as m4_streetlight_find;
import 'package:slm_flutter/features/game/m4_streetlight_fix.dart' as m4_streetlight_fix;
import 'package:slm_flutter/features/game/m4_tree_cut.dart' as m4_tree_cut;
import 'package:slm_flutter/features/game/m4_tree_plan.dart' as m4_tree_plan;
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
import 'package:slm_flutter/features/game/discharge_order.dart';
import 'package:slm_flutter/features/game/fire_choose.dart';
import 'package:slm_flutter/features/game/fire_pass.dart';
import 'package:slm_flutter/features/game/gate_watch.dart';
import 'package:slm_flutter/features/game/glove_check.dart';
import 'package:slm_flutter/features/game/golden_minute.dart';
import 'package:slm_flutter/features/game/harness_check.dart';
import 'package:slm_flutter/features/game/harness_fit.dart';
import 'package:slm_flutter/features/game/helmet_check.dart';
import 'package:slm_flutter/features/game/pole_read.dart';
import 'package:slm_flutter/features/game/ptw_match.dart';
import 'package:slm_flutter/features/game/ptw_steps.dart';
import 'package:slm_flutter/features/game/rod_pick.dart';
import 'package:slm_flutter/features/game/shock_rescue.dart';
import 'package:slm_flutter/features/game/sky_read.dart';
import 'package:slm_flutter/features/game/storm_push.dart';
import 'package:slm_flutter/features/game/tool_tip.dart';
import 'package:slm_flutter/features/game/kit_check.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_feedback_lines.dart';
import 'package:slm_flutter/features/game/lesson_day_card.dart';
import 'package:slm_flutter/features/game/lesson_promises.dart';
import 'package:slm_flutter/features/game/read_lesson_offer.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';

const _packs = [learnBoardPack11];

void main() {
  test('dump learn voice lines', () {
    final coach = <String>{};
    final rival = <String>{};

    void addCoach(String raw, {String? voiceKey}) {
      final t = enDigits(raw).trim();
      if (t.isEmpty) return;
      if (voiceKey != null && DsVoice.hasAudio(voiceKey)) return;
      if (DsVoice.hasAudio(t) || DsVoice.hasAudio(MascotSpeechLibrary.toNaturalFieldBangla(t))) return;
      coach.add(t);
    }

    for (final pool in [
      LearnFeedbackLines.wrong,
      LearnFeedbackLines.wrongAgain,
      LearnFeedbackLines.right,
      LearnFeedbackLines.whyAsk,
      LearnFeedbackLines.mythWhyAsk,
      LearnFeedbackLines.pickAsk,
      LearnFeedbackLines.failed,
    ]) {
      for (final l in pool) {
        addCoach(l.spokenBn, voiceKey: l.voiceKey);
        if (l.shownBn != l.spokenBn) addCoach(l.shownBn, voiceKey: l.voiceKey);
      }
    }
    LearnCoachLines.all.forEach(addCoach);
    for (final n in ReadLessonNudges.all) {
      addCoach(n.title);
    }
    LadderComebackLines.climbed.forEach(addCoach);
    LadderComebackLines.same.forEach(addCoach);
    PromiseLines.all.forEach(addCoach);
    for (final p in lessonPromises.values) {
      addCoach(p.textBn);
    }
    for (final d in lessonDays.values) {
      addCoach(d.lineBn);
    }

    for (final p in _packs) {
      addCoach(p.introBn);
      addCoach(p.myth.stingBn);
      addCoach(p.myth.flipStingBn);
      // A right "why" is spoken back as the rule.
      for (final c in [for (final s in p.slots) ...s.whyChips, ...p.myth.whyChips]) {
        if (c.correct) addCoach(c.textBn);
      }
      addCoach(LearnCoachLines.badgeEarned(p.badgeBn));
      for (final s in p.slots) {
        for (final o in s.options) {
          addCoach(o.rejectBn);
        }
      }
      for (final r in [p.myth.tauntBn, p.myth.rivalLineBn, p.myth.exitBn]) {
        final t = enDigits(r).trim();
        if (t.isNotEmpty) rival.add(t);
      }
    }

    // Do games in the level shell: coach lines, and the supervisor in the rival's voice.
    for (final pack in kitCheckPacks.values) {
      kitCheckSpokenLines(pack).forEach(addCoach);
    }
    for (final pack in kitCheckPacks.values) {
      for (final l in kitCheckCallerLines(pack)) {
        rival.add(enDigits(l).trim());
      }
    }

    // Step 4 (lesson 1.2 board): the rival's myth line in his own voice (the
    // guide's lines stay on device TTS for now).
    rival.add(enDigits(learnBoardPack12.myth.rivalLineBn).trim());
    // Steps 7 and 10 (lesson 1.3 / 1.4 boards): the rival's taunt and myth.
    for (final l in [...PoleBoardLines.recorded, learnBoardPack14.myth.tauntBn, learnBoardPack14.myth.rivalLineBn]) {
      rival.add(enDigits(l).trim());
    }
    // Step 13 (lesson 1.5 board): the rival's taunt and myth.
    for (final l in RodBoardLines.recorded) {
      rival.add(enDigits(l).trim());
    }
    // Steps 16, 19, 22, 25, 28 (lesson 1.6–1.10 boards): the rival's taunt and myth.
    for (final l in [
      ...PtwBoardLines.recorded,
      ...AidBoardLines.recorded,
      ...FireBoardLines.recorded,
      ...StormBoardLines.recorded,
      ...ScanBoardLines.recorded,
    ]) {
      rival.add(enDigits(l).trim());
    }
    // Module 5 lesson boards (5.1–5.10): the rival's taunt and myth.
    for (final l in [
      ...M5Board51Lines.toRecord,
      ...M5Board52Lines.toRecord,
      ...M5Board53Lines.toRecord,
      ...M5Board54Lines.toRecord,
      ...M5Board55Lines.toRecord,
      ...M5Board56Lines.toRecord,
      ...M5Board57Lines.toRecord,
      ...M5Board58Lines.toRecord,
      ...M5Board59Lines.toRecord,
      ...M5Board510Lines.recorded,
    ]) {
      rival.add(enDigits(l).trim());
    }
    // Step 24: the coworker's refill push in his own voice.
    for (final l in PassLines.coworker.recordedLines) {
      rival.add(enDigits(l).trim());
    }
    // Do levels on the kit: the careless coworker's pushes in his own voice.
    for (final c in [
      KitLines.coworkerHurry, KitLines.coworkerVan, GloveLines.coworkerNew, GloveLines.coworkerTrip, // steps 2–3
      ToolTipLines.coworker, // step 6
      PoleLines.coworkerPcc, PoleLines.coworkerSteel, // steps 8–9
      HarnessLines.coworker, // step 11
      FitLines.coworkerLoose, FitLines.coworkerPin, FitLines.coworkerYears, // step 12
      RodLines.coworkerJugaad, RodLines.coworkerRating, // step 14
      DischargeLines.coworker, // step 15
      HelmetLines.coworker, // step 3 (helmet station)
      PtwLines.coworker, // step 17
      StepLines.coworker, // step 18
      RescueLines.coworker, // step 20
      GoldenLines.coworkerMud, GoldenLines.coworkerIce, GoldenLines.coworkerHome, // step 21
      SkyLines.coworker, // step 26
      for (final c in StormCue.values) StormLines.coworker(c), // step 27
      GateLines.coworker, // step 30 (rank gate)
      // Modules 2–4 (2026-11-11).
      m2_comealong_pick.M2ComeAlongLines.coworkerRating,
      m2_comealong_pick.M2ComeAlongLines.coworkerGrip,
      m2_comealong_pull.PullLines.coworker,
      m2_crimp_steps.CrimpLines.coworker,
      m2_dead_test.DeadLines.coworker,
      m2_gate_field.M2GateLines.coworker,
      m2_hotstick_check.HotStickLines.coworkerWet,
      m2_hotstick_check.HotStickLines.coworkerBamboo,
      m2_hotstick_operate.HsLines.coworkerDo,
      m2_hotstick_operate.HsLines.coworkerAb,
      m2_hydraulic_pick.HydLines.coworkerLeak,
      m2_hydraulic_pick.HydLines.coworkerDie,
      m2_hydraulic_pick.HydLines.coworkerRelease,
      m2_hydraulic_use.HydLines.coworker,
      m2_lug_pick.LugLines.coworkerBigger,
      m2_lug_pick.LugLines.coworkerMetal,
      m2_megger_prep.MeggerPrepLines.coworker,
      m2_megger_read.M2MeggerLines.coworker,
      m2_meter_setup.M2MeterLines.coworkerSocket,
      m2_meter_setup.M2MeterLines.coworkerAnyMeter,
      m2_phase_meter.PmLines.skipScript,
      m2_phase_meter.PmLines.clipScript,
      m2_phase_swap.PhaseLines.coworker,
      m2_skin_cut.SkinLines.coworkerCut,
      m2_skin_cut.SkinLines.coworkerBench,
      m2_skin_tools.SkinLines.coworkerTeeth,
      m2_skin_tools.SkinLines.coworkerSkip,
      m2_tool_care.CareLines.coworkerToss,
      m2_tool_care.CareLines.coworkerGrease,
      m2_tool_care.CareLines.coworkerCrack,
      m2_tool_use.TuLines.coworkerNut,
      m2_tool_use.TuLines.coworkerStrip,
      m2_tool_use.TuLines.coworkerCrimp,
      m2_toolbox_pack.TbLines.coworkerTape,
      m2_toolbox_pack.TbLines.coworkerGloves,
      m3_conductor_id.M3ConductorIdLines.coworkerNearest,
      m3_conductor_id.M3ConductorIdLines.coworkerStrand,
      m3_conductor_joint.M3ConductorJointLines.coworker,
      m3_crossarm_check.M3CrossarmCheckLines.coworkerBent,
      m3_crossarm_check.M3CrossarmCheckLines.coworkerRust,
      m3_crossarm_pick.M3CrossarmPickLines.coworkerClamp,
      m3_crossarm_pick.M3CrossarmPickLines.coworkerRust,
      m3_dtr_checkup.M3DtrCheckupLines.coworkerLeak,
      m3_dtr_checkup.M3DtrCheckupLines.coworkerClimb,
      m3_dtr_tap.M3DtrTapLines.coworker,
      m3_fuse_rating.M3FuseRatingLines.coworker,
      m3_gate_field.M3GateLines.coworker,
      m3_guard_patrol.M3GuardPatrolLines.coworker,
      m3_guard_repair.M3GuardRepairLines.coworker,
      m3_horngap_set.M3HorngapSetLines.coworker,
      m3_insulator_patrol.M3InsulatorPatrolLines.coworker,
      m3_insulator_pick.M3InsulatorPickLines.coworkerChip,
      m3_insulator_pick.M3InsulatorPickLines.coworkerPinShackle,
      m3_insulator_pick.M3InsulatorPickLines.coworkerPinDisc,
      m3_la_earth.M3LaEarthLines.coworker,
      m3_la_patrol.M3LaPatrolLines.coworker,
      m3_meter_call.M3MeterCallLines.coworkerSeal,
      m3_meter_call.M3MeterCallLines.coworkerNeutral,
      m3_pillar_fuse.M3PillarFuseLines.coworker,
      m3_pillar_inspect.M3PillarInspectLines.coworker,
      m3_service_drop.M3ServiceDropLines.coworker,
      m3_sld_isolate.M3SldIsolateLines.coworker,
      m4_do_open.M4DoOpenLines.coworkerHeavy,
      m4_do_open.M4DoOpenLines.coworkerFault,
      m4_do_refuse.M4DoRefuseLines.coworkerLink,
      m4_do_refuse.M4DoRefuseLines.coworkerReblow,
      m4_dp_dress.M4DpDressLines.coworker,
      m4_dp_survey.M4DpSurveyLines.coworkerAsIs,
      m4_dp_survey.M4DpSurveyLines.coworkerInsulated,
      m4_dtr_temp.M4DtrTempLines.coworker,
      m4_earth_fix.M4EarthFixLines.coworker,
      m4_earth_test.M4EarthTestLines.coworkerSkip,
      m4_earth_test.M4EarthTestLines.coworkerRuns,
      m4_gate_field.M4GateLines.coworker,
      m4_insulator_prep.M4InsulatorPrepLines.coworker,
      m4_insulator_swap.M4InsulatorSwapLines.coworker,
      m4_jumper_make.M4JumperMakeLines.coworker,
      m4_jumper_tight.M4JumperTightLines.coworker,
      m4_oil_level.M4OilLevelLines.coworker,
      m4_service_connect.M4ServiceConnectLines.coworker,
      m4_service_plan.M4ServicePlanLines.coworkerPapers,
      m4_service_plan.M4ServicePlanLines.coworkerRoute,
      m4_service_plan.M4ServicePlanLines.coworkerKit,
      m4_streetlight_find.M4StreetlightFindLines.coworker,
      m4_streetlight_fix.M4StreetlightFixLines.coworker,
      m4_streetlight_fix.M4StreetlightFixLines.coworkerTop,
      m4_tree_cut.M4TreeCutLines.coworker,
      m4_tree_plan.M4TreePlanLines.coworker,
      // Module 5 (2026-11-12).
      m5_trip_call.M5TripLines.coworker,
      m5_recloser_watch.M5RecloserLines.coworker,
      m5_fault_address.M5FaLines.coworker,
      m5_sense_walk.SenseWalkLines.wireCall,
      m5_sense_walk.SenseWalkLines.lookCall,
      m5_culprit_case.M5CulpritLines.coworker,
      m5_anneal_cut.M5AnnealLines.coworker,
      m5_feeder_sectionalize.M5FeederLines.coworker,
      m5_reblow_clock.M5ReblowLines.coworker,
      m5_lv_street_read.M5LvLines.coworker,
      ...m5_lv_load_test.M5LvLoadLines.coworkerScripts,
      m5_fault_casebook.M5CasebookLines.coworker,
      ...m5_live_wire_guard.M5LiveWireLines.coworkers,
      m5_searchlight_patrol.M5SearchlightLines.coworker,
      m5_dark_eyes.M5DarkEyesLines.coworker,
      m5_cause_strike.M5CauseStrikeLines.coworkerHum,
      m5_cause_strike.M5CauseStrikeLines.coworkerHumLate,
      m5_cause_strike.M5CauseStrikeLines.coworkerLive,
      m5_cause_strike.M5CauseStrikeLines.coworkerClimb,
      m5_cause_strike.M5CauseStrikeLines.coworkerSmall,
      m5_workshop_referral.M5WrLines.coworkerCharge,
      m5_workshop_referral.M5WrLines.coworkerWater,
      m5_cable_fault_type.M5CableLines.coworkerA1,
      m5_cable_fault_type.M5CableLines.coworkerA2,
      m5_cable_route_locate.M5CrlLines.coworkerTeam,
      m5_cable_route_locate.M5CrlLines.coworkerMap,
      m5_pm_thermal_round.M5PmLines.coworkerA,
      m5_pm_thermal_round.M5PmLines.coworkerB,
      m5_gate_case.M5GateLines.chargeNight,
      m5_gate_case.M5GateLines.chargeDay,
      m5_gate_case.M5GateLines.waitMorning, // m5 rank gate
    ]) {
      for (final l in c.recordedLines) {
        rival.add(enDigits(l).trim());
      }
    }
    // Step 23: the careless coworker (level 1's rival) in his own voice.
    for (final l in FireLines.coworkerLines) {
      rival.add(enDigits(l).trim());
    }

    for (final id in MascotCueId.values) {
      for (var i = 0; i < 64; i++) {
        final cue = MascotSpeechLibrary.cueFor(id);
        addCoach(cue.displayBn, voiceKey: cue.voiceKey);
      }
    }
    for (var i = 0; i < 400; i++) {
      final cue = MascotSpeechLibrary.randomFunnyIdle();
      addCoach(cue.displayBn, voiceKey: cue.voiceKey);
    }

    final catalog = jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map;
    for (final g in (catalog['guideLines'] as List? ?? const [])) {
      final text = (g as Map)['bnText']?.toString() ?? '';
      addCoach(MascotSpeechLibrary.toNaturalFieldBangla(text));
    }

    List<Map<String, String>> rows(Set<String> keys) => [
          for (final k in keys.toList()..sort())
            {'key': k, 'say': MascotSpeechLibrary.toNaturalFieldBangla(k)},
        ];
    File('tool/learn_voice_lines.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'coach': rows(coach), 'rival': rows(rival)}),
    );
    // ignore: avoid_print
    print('coach ${coach.length}, rival ${rival.length}');
  });
}
