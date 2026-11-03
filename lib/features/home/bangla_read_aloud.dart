import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../../core/services/neural_tts_service.dart';

const _rateSub = '-2%';

/// Part A: fixed welcome before every lesson.
const lessonWelcomeClips = [
  NeuralClip('নমস্কার লাইনম্যান ভাই!', pauseMs: 500),
  NeuralClip('স্মার্ট লাইনম্যানের আজকের সুরক্ষা পাঠে আপনাকে স্বাগতম।', pauseMs: 650),
  NeuralClip('লাইনে বা পোলে কাজে নামার আগে এই পাঠের প্রতিটি নিয়ম মনোযোগ দিয়ে শুনুন এবং মনে গেঁথে নিন।', pauseMs: 800),
];

/// Part C: fixed close that sends the reader to the quiz.
const lessonQuizCallClips = [
  NeuralClip('এই পাঠের মূল আলোচনা এখানেই সম্পন্ন হলো।', pauseMs: 650),
  NeuralClip('মনে রাখবেন: আগে জীবন, তারপর কাজ!', pauseMs: 600),
  NeuralClip('নিজের সুরক্ষা জ্ঞান ঝালিয়ে নিতে এবং দক্ষতা প্রমাণ করতে এখনই নিচের কুইজে অংশ নিন,', pauseMs: 400),
  NeuralClip('সঠিক উত্তর দিয়ে পরবর্তী লেভেল আনলক করুন।'),
];

const quizWelcomeClips = [
  NeuralClip('সুরক্ষা কুইজে স্বাগতম!', pauseMs: 500),
  NeuralClip('এখানে আপনার ফিল্ড রিফ্লেক্স ও সুরক্ষা জ্ঞানের পরীক্ষা হবে।', pauseMs: 450),
  NeuralClip('প্রতিটি প্রশ্ন মনোযোগ দিয়ে শুনুন এবং নিরাপদতম অপশনটি বেছে নিন।', pauseMs: 700),
];

List<NeuralClip> lessonTitleClips(int chapter, String title) => [
      NeuralClip('পাঠ $chapter: ${_speechClean(title)}', volume: '+10%', pitch: '+1Hz', pauseMs: 750),
    ];

List<NeuralClip> lessonSubheadClips(String text) {
  final t = _speechClean(text).replaceAll(RegExp(r'[।.:]+$'), '').trim();
  return t.isEmpty ? const [] : [NeuralClip(t, rate: _rateSub, pauseMs: 500)];
}

const _optionNames = ['এ', 'বি', 'সি', 'ডি', 'ই', 'এফ'];

/// "প্রশ্ন N, মোট M।" → question → spaced options.
List<NeuralClip> quizQuestionClips({
  required String question,
  required List<String> options,
  required int index,
  required int total,
  bool hasImage = false,
  bool Function(String option)? isImage,
}) {
  final out = <NeuralClip>[
    NeuralClip('প্রশ্ন ${index + 1}, মোট $total।', pauseMs: 500),
    ..._sentences(_speechClean(question)),
  ];
  if (hasImage) out.add(const NeuralClip('এখানে একটি ছবি আছে।'));
  _setLastPause(out, 600);
  for (var i = 0; i < options.length; i++) {
    final name = i < _optionNames.length ? _optionNames[i] : '${i + 1}';
    final opt = isImage?.call(options[i]) == true ? 'ছবি' : _speechClean(options[i]);
    out.add(NeuralClip('অপশন $name: $opt', pauseMs: i == options.length - 1 ? 0 : 350));
  }
  return out;
}

List<NeuralClip> quizResultClips({required bool passed, required int score, required int total}) => passed
    ? [
        const NeuralClip('খুব ভালো!', pauseMs: 400),
        NeuralClip('আপনি $total-এ $score পেয়ে সফলভাবে এই কুইজ সম্পন্ন করেছেন।', pauseMs: 600),
        const NeuralClip('মনে রাখবেন: আগে জীবন, তারপর কাজ!', pauseMs: 450),
        const NeuralClip('পরের লেভেলে এগিয়ে চলুন।'),
      ]
    : [
        const NeuralClip('সাবধান!', pauseMs: 400),
        const NeuralClip('ফিল্ডে সামান্য অসাবধানতাই বড় দুর্ঘটনার কারণ হতে পারে।', pauseMs: 500),
        NeuralClip('আপনার স্কোর $score।', pauseMs: 250),
        const NeuralClip('কুইজ পাস করতে অন্তত 70 শতাংশ সঠিক উত্তর প্রয়োজন।', pauseMs: 500),
        const NeuralClip('পাঠটি আরেকবার মনোযোগ দিয়ে পড়ুন এবং পুনরায় পরীক্ষা দিন।'),
      ];

final _bulletLead = RegExp(r'^(?:[•·\-*–]|[0-9০-৯]+[.)।])\s*');
final _headingLine = RegExp(r'^(?:#{1,6}\s+.+|\*\*[^*]+\*\*\s*:?)$');

/// Part B: lesson text cut into sentence clips with the pause hierarchy.
List<NeuralClip> lessonBodyClips(String raw) {
  final out = <NeuralClip>[];
  var inList = false;
  for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    if (_headingLine.hasMatch(line)) {
      inList = false;
      out.addAll(lessonSubheadClips(line));
      continue;
    }
    final inline = line.contains('•') ? line.split('•').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() : null;
    final isBullet = _bulletLead.hasMatch(line) && !RegExp(r'^[0-9০-৯]+\.[0-9০-৯]').hasMatch(line);
    final items = inline != null && (inline.length > 1 || isBullet) ? inline : (isBullet ? [line] : null);
    if (items == null) {
      inList = false;
      out.addAll(_sentences(_speechClean(line)));
      continue;
    }
    for (final item in items) {
      final clips = _sentences(_speechClean(item.replaceFirst(_bulletLead, '')));
      if (clips.isEmpty) continue;
      if (!inList) {
        _setLastPause(out, 400, atLeast: true);
        inList = true;
      }
      out.addAll(clips);
      _setLastPause(out, 350);
    }
  }
  return out;
}

void _setLastPause(List<NeuralClip> clips, int ms, {bool atLeast = false}) {
  if (clips.isEmpty) return;
  final last = clips.last;
  if (atLeast && last.pauseMs >= ms) return;
  clips[clips.length - 1] = last.withPause(ms);
}

/// Markup and token cleanup for the neural voice.
String _speechClean(String raw) => lessonSpeechText(raw)
    .replaceAll(RegExp(r'[*_#>`~]+'), ' ')
    .replaceAll(RegExp(r'\s+([।,?!:;])'), r'$1')
    .replaceAll(RegExp(r'\s{2,}'), ' ')
    .trim();

/// One clip per sentence; the danda and ?/! set the rest after it.
List<NeuralClip> _sentences(String text) {
  final out = <NeuralClip>[];
  final buf = StringBuffer();
  final chars = text.runes.map(String.fromCharCode).toList();
  void flush(int pause) {
    final s = buf.toString().trim();
    buf.clear();
    if (s.replaceAll(RegExp(r'[\s।.,?!:;]'), '').isEmpty) return;
    out.add(NeuralClip(s, pauseMs: pause));
  }

  for (var i = 0; i < chars.length; i++) {
    final ch = chars[i];
    buf.write(ch);
    final next = i + 1 < chars.length ? chars[i + 1] : ' ';
    final prev = i > 0 ? chars[i - 1] : '';
    if (ch == '।') {
      flush(450);
    } else if ((ch == '?' || ch == '!') && next != '?' && next != '!') {
      flush(500);
    } else if (ch == '.' && next.trim().isEmpty && !RegExp(r'[0-9]').hasMatch(prev)) {
      flush(450);
    }
  }
  flush(450);
  return out;
}

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

/// The one device voice for the app.
///
/// flutter_tts sends every callback over one static channel to whichever
/// FlutterTts was built last, so a FlutterTts per page left older pages
/// waiting out 12-20 s timeouts. One engine, set up once; the reader that
/// spoke last owns the callbacks.
class _DeviceTts {
  _DeviceTts._();
  static final instance = _DeviceTts._();

  FlutterTts? _engine;
  FlutterTts get _tts => _engine ??= FlutterTts();
  Future<void>? _setup;
  String? language;
  BanglaReadAloud? owner;

  Future<void> init() async {
    final running = _setup ??= _init();
    try {
      await running;
    } catch (_) {
      if (identical(_setup, running)) _setup = null;
      rethrow;
    }
  }

  /// [reader] is about to speak. A different reader that was mid-line is
  /// cut off at once (its voice is about to be stopped) instead of waiting.
  void claim(BanglaReadAloud reader) {
    final prev = owner;
    owner = reader;
    if (prev == null || identical(prev, reader)) return;
    prev._token++;
    if (prev.speaking) prev._mark(false);
    prev._endWait();
  }

  void release(BanglaReadAloud reader) {
    if (identical(owner, reader)) owner = null;
  }

  Future<void> stop() => _tts.stop();
  Future<void> speak(String text) => _tts.speak(text);
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  Future<void> _init() async {
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
    _tts.setStartHandler(() => owner?._mark(true));
    _tts.setCompletionHandler(() => owner?._finished());
    _tts.setCancelHandler(() => owner?._finished());
    _tts.setErrorHandler((_) => owner?._finished());
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
}

/// Device TTS tuned for clear Bangla narration. Every reader shares one engine.
class BanglaReadAloud {
  BanglaReadAloud();

  static _DeviceTts get _device => _DeviceTts.instance;

  bool speaking = false;
  Completer<void>? _wait;
  int _token = 0;

  /// The Bangla language the device voice uses, or null when it has none.
  String? get language => _device.language;

  void Function(bool speaking)? onSpeakingChanged;

  Future<void> init() => _device.init();

  void _mark(bool value) {
    speaking = value;
    onSpeakingChanged?.call(value);
  }

  void _finished() {
    _mark(false);
    _endWait();
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
    _device.claim(this);
    _endWait();
    try {
      await _device.stop();
    } catch (_) {}
    if (mine != _token) return false;
    await init();
    if (mine != _token) return false;
    if (language == null) return false;
    await _device.setSpeechRate(rate);
    if (mine != _token) return false;

    if (onClause != null) {
      unawaited(_runClauses(clean, mine, onClause));
    } else {
      speaking = true;
      final wait = Completer<void>();
      _wait = wait;
      await _device.speak(clean);
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
    _device.claim(this);
    _endWait();
    try {
      await _device.stop();
    } catch (_) {}
    if (mine != _token) return;
    await init();
    if (mine != _token || language == null) return;
    await _device.setSpeechRate(rate);
    if (mine != _token) return;
    speaking = true;
    final wait = Completer<void>();
    _wait = wait;
    await _device.speak(clean);
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
      await _device.speak(bits[i].spoken);
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
      await _device.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    _device.release(this);
  }
}
