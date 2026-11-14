import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../bangla_read_aloud.dart';

const _enders = '।?!';
const _closers = '"\'”’)]»';

/// Words that end in a full stop without ending the sentence.
const _abbreviations = {'kv', 'v', 'a', 'ma', 'kw', 'mw', 'dr', 'mr', 'mrs', 'st', 'no', 'vs', 'etc', 'eg', 'ie', 'sr', 'jr'};

bool _isSpace(String ch) => ch.trim().isEmpty;

bool _isDigit(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 0x30 && c <= 0x39) || (c >= 0x09E6 && c <= 0x09EF);
}

bool _isLatinLetter(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
}

/// A '.' at [i] ends a sentence only before a space or the end, after a
/// word that is not a number ("6.5", "1.") or an abbreviation ("kV.", "e.g.").
bool _dotEnds(String text, int i) {
  final next = i + 1 < text.length ? text[i + 1] : ' ';
  if (!_isSpace(next)) return false;
  if (i == 0) return false;
  final prev = text[i - 1];
  if (prev == '.' || _isDigit(prev) || _isSpace(prev)) return false;
  // The Latin word right before the dot, dots inside it removed (e.g. → eg).
  var s = i;
  while (s > 0 && (_isLatinLetter(text[s - 1]) || text[s - 1] == '.')) {
    s--;
  }
  final word = text.substring(s, i).replaceAll('.', '').toLowerCase();
  if (word.isEmpty) return true; // Bangla word before the dot.
  if (word.length == 1) return false;
  return !_abbreviations.contains(word);
}

/// Sentence spans of [text]: each ends after । ? ! (with any closing quote or
/// bracket) or at a newline. Spans are trimmed; empty ones are dropped.
List<TextRange> banglaSentenceRanges(String text) {
  final out = <TextRange>[];
  void push(int start, int end) {
    while (start < end && _isSpace(text[start])) {
      start++;
    }
    while (end > start && _isSpace(text[end - 1])) {
      end--;
    }
    if (end > start) out.add(TextRange(start: start, end: end));
  }

  var start = 0;
  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    if (ch == '\n') {
      push(start, i);
      start = ++i;
      continue;
    }
    final ends = _enders.contains(ch) || (ch == '.' && _dotEnds(text, i));
    if (!ends) {
      i++;
      continue;
    }
    var j = i + 1;
    while (j < text.length && (_enders.contains(text[j]) || _closers.contains(text[j]))) {
      j++;
    }
    push(start, j);
    start = i = j;
  }
  push(start, text.length);
  return out;
}

/// Splits Bangla text into sentences on । ? ! and newlines, keeping the
/// punctuation. Numbers like "৬.৫" and abbreviations like "kV" stay whole.
List<String> splitBanglaSentences(String text) =>
    [for (final r in banglaSentenceRanges(text)) r.textInside(text)];

/// One paragraph as a single [Text.rich]; the sentence being read gets a soft
/// background and full ink. Static: no animation, nothing ticks while idle.
class HighlightedParagraph extends StatelessWidget {
  const HighlightedParagraph({
    super.key,
    required this.text,
    required this.activeSentence,
    required this.style,
    required this.highlight,
  });

  final String text;

  /// Index into [splitBanglaSentences] of [text]; null shows plain text.
  final int? activeSentence;
  final TextStyle style;
  final Color highlight;

  /// Background alpha of the active sentence.
  static const highlightAlpha = 0.2;

  @override
  Widget build(BuildContext context) {
    final active = activeSentence;
    final ranges = active == null ? const <TextRange>[] : banglaSentenceRanges(text);
    if (active == null || active < 0 || active >= ranges.length) {
      return Text.rich(TextSpan(text: text, style: style));
    }
    final r = ranges[active];
    final ink = style.color;
    final activeStyle = TextStyle(
      backgroundColor: highlight.withValues(alpha: highlightAlpha),
      color: ink?.withValues(alpha: 1),
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (r.start > 0) TextSpan(text: text.substring(0, r.start)),
          TextSpan(text: r.textInside(text), style: activeStyle),
          if (r.end < text.length) TextSpan(text: text.substring(r.end)),
        ],
      ),
    );
  }
}

/// Speaks one sentence. Returns false when nothing could be spoken (no
/// Bangla voice on the phone).
typedef SentenceSpeak = Future<bool> Function(String sentence);

/// Reads [sentences] one by one and publishes the index being read in
/// [active], so a [HighlightedParagraph] can follow along.
///
/// By default it speaks through the app's shared device voice
/// ([BanglaReadAloud.speakAwait]); tests inject [speak] / [stopSpeech].
/// The reader never starts by itself: call [start] from a tap. While [muted]
/// it says nothing.
class SentenceReader {
  SentenceReader(
    List<String> sentences, {
    SentenceSpeak? speak,
    Future<void> Function()? stopSpeech,
    BanglaReadAloud? voice,
    this._muted = false,
    this.gap = const Duration(milliseconds: 250),
    this.onDone,
  }) : _sentences = List.unmodifiable(sentences) {
    if (speak != null) {
      _speak = speak;
      _stopSpeech = stopSpeech ?? _noop;
    } else {
      final v = voice ?? (_ownVoice = BanglaReadAloud());
      _speak = (s) async {
        await v.speakAwait(s);
        return v.language != null;
      };
      _stopSpeech = stopSpeech ?? v.stop;
    }
  }

  static Future<void> _noop() async {}

  late final SentenceSpeak _speak;
  late final Future<void> Function() _stopSpeech;
  BanglaReadAloud? _ownVoice;

  /// Silence after each sentence (the voice already pauses on the danda).
  final Duration gap;

  /// Called when the last sentence finished (not after [stop]).
  final VoidCallback? onDone;

  List<String> _sentences;
  List<String> get sentences => _sentences;

  final ValueNotifier<int?> _active = ValueNotifier<int?>(null);

  /// The sentence being read, or null when silent.
  ValueListenable<int?> get active => _active;

  bool _speaking = false;
  bool get speaking => _speaking;

  int _run = 0;

  bool _muted;
  bool get muted => _muted;

  /// Muting stops any reading at once.
  set muted(bool value) {
    _muted = value;
    if (value) unawaited(stop());
  }

  /// New text (for example the next page). Stops the current reading.
  void setSentences(List<String> sentences) {
    if (_speaking) unawaited(stop());
    _sentences = List.unmodifiable(sentences);
  }

  /// Reads from sentence [from] to the end. Returns false when nothing could
  /// be spoken (muted, no text, or no Bangla voice), so the caller can tell
  /// the player.
  Future<bool> start({int from = 0}) async {
    if (_muted || _sentences.isEmpty || from < 0 || from >= _sentences.length) return false;
    if (_speaking) await stop();
    final run = ++_run;
    _speaking = true;
    var spoke = false;
    for (var i = from; i < _sentences.length; i++) {
      if (run != _run) return spoke;
      _active.value = i;
      final ok = await _speak(_sentences[i]);
      if (run != _run) return spoke;
      if (!ok) break;
      spoke = true;
      if (gap > Duration.zero && i < _sentences.length - 1) {
        await Future<void>.delayed(gap);
      }
    }
    if (run != _run) return spoke;
    _speaking = false;
    _active.value = null;
    if (spoke) onDone?.call();
    return spoke;
  }

  /// Stops at once; [active] goes back to null. Leaves the shared voice alone
  /// when this reader was not speaking (another page may own it).
  Future<void> stop() async {
    final was = _speaking;
    _run++;
    _speaking = false;
    _active.value = null;
    if (!was) return;
    try {
      await _stopSpeech();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    _active.dispose();
    await _ownVoice?.dispose();
  }
}
