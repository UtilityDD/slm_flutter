import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/core/services/neural_tts_service.dart';

/// Privacy guard for the Play release: voices are made on the phone (bundled
/// clips or flutter_tts). No lesson text may go to an online TTS service.
void main() {
  test('the online voice flag is off', () {
    expect(neuralVoiceEnabled, isFalse);
  });

  test('every clip is spoken by the device voice, in order', () async {
    final said = <String>[];
    final n = NeuralTtsService();
    final spoke = await n.play(
      const [NeuralClip('এক'), NeuralClip('দুই'), NeuralClip('তিন')],
      fallback: (text) async {
        said.add(text);
        return true;
      },
    );
    expect(spoke, isTrue);
    expect(said, ['এক', 'দুই', 'তিন']);
    expect(n.speaking, isFalse);
    await n.dispose();
  });

  test('stop ends a run before the next clip', () async {
    final said = <String>[];
    final n = NeuralTtsService();
    await n.play(
      const [NeuralClip('এক'), NeuralClip('দুই')],
      fallback: (text) async {
        said.add(text);
        await n.stop();
        return true;
      },
    );
    expect(said, ['এক']);
    await n.dispose();
  });

  test('no online TTS client is reachable from lib/', () {
    // Endpoints and client code of online speech services (Edge Read Aloud,
    // Azure, Google Cloud TTS, Google Translate TTS, Polly, ElevenLabs).
    final banned = RegExp(
      r'speech\.platform|bing\.com|readaloud/|TrustedClientToken|wss://|WebSocket'
      r'|tts\.speech\.microsoft|cognitiveservices|texttospeech\.googleapis|translate_tts'
      r'|polly\.|elevenlabs',
      caseSensitive: false,
    );
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (banned.hasMatch(line)) hits.add('${f.path}:${i + 1}: $line');
      }
    }
    expect(hits, isEmpty, reason: 'Online TTS must not ship (privacy policy: voices are made on the phone).');
  });
}
