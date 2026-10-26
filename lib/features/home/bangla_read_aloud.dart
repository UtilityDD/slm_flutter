import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Strips lesson markup so Bangla TTS reads clean prose.
String lessonSpeechText(String raw) {
  var text = raw;
  // ((media|label)) → keep spoken label only
  text = text.replaceAllMapped(RegExp(r'\(\((.*?)\)\)'), (m) {
    final inner = m.group(1) ?? '';
    final pipe = inner.indexOf('|');
    if (pipe >= 0) {
      final label = inner.substring(pipe + 1).trim();
      return label.isEmpty ? '' : ' $label ';
    }
    return '';
  });
  // [[image|caption]] → speak caption if present
  text = text.replaceAllMapped(RegExp(r'\[\[(.*?)\]\]'), (m) {
    final parts = (m.group(1) ?? '')
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'inline')
        .toList();
    if (parts.length <= 1) return '';
    return ' ${parts.skip(1).join(' ')} ';
  });
  text = text
      .replaceAll(RegExp(r'[•·]+'), '। ')
      .replaceAll(RegExp(r'\s*\|\s*'), '। ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  // Soft pauses for Bangla punctuation.
  text = text.replaceAll('।', '। ');
  text = text.replaceAll('?', '? ');
  text = text.replaceAll('!', '! ');
  return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

/// One spoken piece, cut on punctuation so the voice can pause there.
class SpeechBit {
  final String shown;
  final String spoken;
  final Duration pause;

  const SpeechBit(this.shown, this.spoken, this.pause);
}

bool _isSpeechBreak(String ch) => '।.?!,:;،'.contains(ch);

Duration _pauseFor(String mark) => switch (mark) {
      ',' || '،' || ';' || ':' => const Duration(milliseconds: 280),
      '?' || '!' => const Duration(milliseconds: 520),
      _ => const Duration(milliseconds: 460),
    };

/// Splits [raw] into clauses. The danda and the comma become a silence, not a spoken word.
List<SpeechBit> speechBits(String raw) {
  final clean = lessonSpeechText(raw);
  if (clean.isEmpty) return const [];
  final bits = <SpeechBit>[];
  final buf = StringBuffer();
  void take(String mark) {
    final words = buf.toString().trim();
    buf.clear();
    if (words.isEmpty) return;
    final shownMark = mark == '.' ? '।' : mark;
    final spoken = (mark == '?' || mark == '!') ? '$words$mark' : words;
    bits.add(SpeechBit('$words$shownMark', spoken, _pauseFor(mark)));
  }

  for (final rune in clean.runes) {
    final ch = String.fromCharCode(rune);
    if (_isSpeechBreak(ch)) {
      take(ch);
    } else {
      buf.write(ch);
    }
  }
  final tail = buf.toString().trim();
  if (tail.isNotEmpty) bits.add(SpeechBit(tail, tail, Duration.zero));
  if (bits.isEmpty) return const [];
  final last = bits.removeLast();
  bits.add(SpeechBit(last.shown, last.spoken, Duration.zero));
  return bits;
}

/// Device TTS tuned for clear Bangla narration.
class BanglaReadAloud {
  BanglaReadAloud();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool speaking = false;
  String? language;
  Completer<void>? _wait;
  int _token = 0;

  void Function(bool speaking)? onSpeakingChanged;

  Future<void> init() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(false);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Slightly slower than default → clearer Bangla syllables.
    await _tts.setSpeechRate(0.42);
    try {
      await _tts.setSharedInstance(true);
    } catch (_) {}
    language = await _pickBanglaLanguage();
    if (language != null) {
      await _tts.setLanguage(language!);
      await _pickBanglaVoice(language!);
    }
    void mark(bool value) {
      speaking = value;
      onSpeakingChanged?.call(value);
    }

    _tts.setStartHandler(() => mark(true));
    _tts.setCompletionHandler(() {
      mark(false);
      _endWait();
    });
    _tts.setCancelHandler(() {
      mark(false);
      _endWait();
    });
    _tts.setErrorHandler((_) {
      mark(false);
      _endWait();
    });
    _ready = true;
  }

  Future<String?> _pickBanglaLanguage() async {
    final preferred = ['bn-BD', 'bn_BD', 'bn-IN', 'bn_IN', 'bn'];
    for (final code in preferred) {
      try {
        final ok = await _tts.isLanguageAvailable(code);
        if (ok == true) return code.contains('_') ? code.replaceAll('_', '-') : code;
      } catch (_) {}
    }
    try {
      final langs = await _tts.getLanguages;
      if (langs is List) {
        for (final item in langs) {
          final code = '$item';
          if (code.toLowerCase().startsWith('bn')) {
            return code.replaceAll('_', '-');
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pickBanglaVoice(String lang) async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      Map<String, String>? best;
      for (final raw in voices) {
        if (raw is! Map) continue;
        final locale = '${raw['locale'] ?? raw['localeId'] ?? ''}'.replaceAll('_', '-');
        final name = '${raw['name'] ?? ''}';
        if (!locale.toLowerCase().startsWith('bn') && !name.toLowerCase().contains('beng')) {
          continue;
        }
        final map = <String, String>{
          'name': name,
          'locale': locale.isEmpty ? lang : locale,
        };
        // Prefer Google / network / female-quality Bangla voices when present.
        final score = _voiceScore(name, locale);
        if (best == null || score > _voiceScore(best['name']!, best['locale']!)) {
          best = map;
        }
      }
      if (best != null) {
        await _tts.setVoice(best);
      }
    } catch (_) {}
  }

  int _voiceScore(String name, String locale) {
    var score = 0;
    final n = name.toLowerCase();
    final l = locale.toLowerCase();
    if (l.contains('bd')) score += 4;
    if (l.contains('in')) score += 2;
    if (n.contains('google')) score += 5;
    if (n.contains('network')) score += 3;
    if (n.contains('enhanced') || n.contains('premium')) score += 3;
    if (n.contains('female') || n.contains('bn-in-x') || n.contains('bn-bd')) score += 2;
    return score;
  }

  void _endWait() {
    final wait = _wait;
    _wait = null;
    if (wait != null && !wait.isCompleted) wait.complete();
  }

  Future<bool> speak(String raw, {double rate = 0.42, void Function(int index)? onClause}) async {
    final clean = lessonSpeechText(raw);
    if (clean.isEmpty) return false;
    final mine = ++_token;
    _endWait();
    try {
      await _tts.stop();
    } catch (_) {}
    if (mine != _token) return false;
    await init();
    if (mine != _token) return false;
    if (language == null) return false;
    await _tts.setSpeechRate(rate);
    if (mine != _token) return false;

    if (onClause != null) {
      unawaited(_runClauses(clean, mine, onClause));
    } else {
      speaking = true;
      final wait = Completer<void>();
      _wait = wait;
      await _tts.speak(clean);
      await wait.future.timeout(const Duration(seconds: 15), onTimeout: () {});
      if (mine == _token) speaking = false;
    }
    return true;
  }

  /// Speaks [raw] and finishes when the voice finishes, so the next line can wait.
  Future<void> speakAwait(String raw, {double rate = 0.42}) async {
    final clean = lessonSpeechText(raw);
    if (clean.isEmpty) return;
    final mine = ++_token;
    _endWait();
    try {
      await _tts.stop();
    } catch (_) {}
    if (mine != _token) return;
    await init();
    if (mine != _token || language == null) return;
    await _tts.setSpeechRate(rate);
    if (mine != _token) return;
    speaking = true;
    final wait = Completer<void>();
    _wait = wait;
    await _tts.speak(clean);
    await wait.future.timeout(const Duration(seconds: 20), onTimeout: () {});
    if (mine == _token) speaking = false;
  }

  /// Speaks one clause at a time and rests on the punctuation.
  Future<void> _runClauses(String clean, int mine, void Function(int index)? onClause) async {
    final bits = speechBits(clean);
    for (var i = 0; i < bits.length; i++) {
      if (mine != _token) return;
      onClause?.call(i);
      final wait = Completer<void>();
      _wait = wait;
      speaking = true;
      await _tts.speak(bits[i].spoken);
      await wait.future.timeout(const Duration(seconds: 12), onTimeout: () {});
      if (mine != _token) return;
      if (bits[i].pause > Duration.zero) await Future<void>.delayed(bits[i].pause);
    }
    if (mine == _token) speaking = false;
  }

  Future<void> stop() async {
    _token++;
    speaking = false;
    _endWait();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }
}
