// Lists every fixed coach / rival line that has no recorded clip yet, for
// tool/make_learn_voice.py. Run from the repo root:
//   flutter test tool/dump_learn_voice_lines_test.dart
// Writes tool/learn_voice_lines.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/core/en_digits.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_voice.dart';
import 'package:slm_flutter/features/game/discharge_order.dart';
import 'package:slm_flutter/features/game/fire_choose.dart';
import 'package:slm_flutter/features/game/fire_pass.dart';
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
    // Steps 16, 19, 22, 25 (lesson 1.6–1.9 boards): the rival's taunt and myth.
    for (final l in [...PtwBoardLines.recorded, ...AidBoardLines.recorded, ...FireBoardLines.recorded, ...StormBoardLines.recorded]) {
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
