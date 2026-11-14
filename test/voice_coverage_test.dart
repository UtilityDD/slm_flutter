// VOICE_GUIDE.md: every line the app speaks must have a recorded clip, unless it
// is on the shrinking to-do list tool/voice_pending.json. tool/voice_inventory.json
// is the committed list of spoken lines (regenerate with the SLM_VOICE_INVENTORY
// test run before a release).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_voice.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';

bool _hasClip(String text, {required bool rival}) {
  final clean = MascotSpeechLibrary.toNaturalFieldBangla(text);
  if (rival) {
    return LearnVoice.resolve(text, rival: true) != null || LearnVoice.resolve(clean, rival: true) != null;
  }
  return DsVoice.hasAudio(text) ||
      DsVoice.hasAudio(clean) ||
      LearnVoice.resolve(text) != null ||
      LearnVoice.resolve(clean) != null;
}

void main() {
  final inventory = (jsonDecode(File('tool/voice_inventory.json').readAsStringSync()) as Map)['lines'] as List;
  final pending = {
    for (final l in (jsonDecode(File('tool/voice_pending.json').readAsStringSync()) as Map)['lines'] as List) l as String,
  };

  test('every spoken line has a recorded clip or is on the pending list', () {
    final missing = <String>[];
    for (final e in inventory) {
      final m = e as Map;
      final text = m['text'] as String;
      if (pending.contains(text)) continue;
      if (!_hasClip(text, rival: m['rival'] == true)) missing.add(text);
    }
    expect(missing, isEmpty,
        reason: 'Spoken without a clip (record it in the Subrata voice system, VOICE_GUIDE.md):\n${missing.take(20).join('\n')}');
  });

  test('the pending list only holds lines that still lack a clip (it must shrink)', () {
    final rivalOf = {for (final e in inventory) (e as Map)['text'] as String: e['rival'] == true};
    final done = [
      for (final t in pending)
        if (_hasClip(t, rival: rivalOf[t] ?? false)) t,
    ];
    expect(done, isEmpty, reason: 'Recorded now — remove from tool/voice_pending.json:\n${done.take(20).join('\n')}');
  });
}
