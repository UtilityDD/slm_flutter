// Lists every fixed coach / rival line that has no recorded clip yet, for
// tool/make_learn_voice.py. Run from the repo root:
//   flutter test tool/dump_learn_voice_lines_test.dart
// Writes tool/learn_voice_lines.json.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/core/en_digits.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_voice.dart';
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
