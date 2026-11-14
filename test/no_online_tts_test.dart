import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Privacy guard for the Play release: voices are made on the phone (bundled
/// clips or flutter_tts). No lesson text may go to an online TTS service.
void main() {
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
