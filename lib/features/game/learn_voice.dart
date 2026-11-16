import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/en_digits.dart';
import 'learn_voice_map.dart';

/// Recorded Learn lines: the coach always in the coach's voice, the rival in
/// his own. Regenerate with tool/make_learn_voice.py after changing lines.
abstract final class LearnVoice {
  static final _player = AudioPlayer();
  static var _ready = false;

  /// Clip for [text] (or its English-digit form), or null when not recorded.
  static String? resolve(String text, {bool rival = false}) {
    final map = rival ? learnRivalVoice : learnCoachVoice;
    final t = text.trim();
    return map[t] ?? map[enDigits(t)];
  }

  /// The ways the guide's task nudge (TaskNudge in do_parts.dart) opens a
  /// repeat of the task. Each prefix (trimmed) has its own short clip, so a
  /// nudge line with no clip of its own is spoken as the prefix clip then the
  /// task's clip ([resolveNudge]).
  static const nudgePrefixes = ['আবার বলছি — ', 'তাড়াহুড়ো নয়। ', 'ভালো করে দেখুন। '];

  /// The two clips (prefix, then task) that speak a task-nudge [text] with no
  /// clip of its own; null when [text] has its own clip (that one wins), is
  /// not a nudge, or the prefix or the task is not recorded.
  static List<String>? resolveNudge(String text) {
    final t = text.trim();
    if (resolve(t) != null) return null;
    for (final p in nudgePrefixes) {
      if (!t.startsWith(p)) continue;
      final head = resolve(p);
      final task = resolve(t.substring(p.length));
      return head == null || task == null ? null : [head, task];
    }
    return null;
  }

  /// Bumped by [stop], so a [play] still setting up never starts after it.
  static var _gen = 0;

  /// Tests: stands in for the player; gets each file [play] is asked to play
  /// and completes when that "clip" has ended.
  @visibleForTesting
  static Future<bool> Function(String file)? debugPlay;

  /// Plays [file] (from [resolve]) and completes when it has finished.
  static Future<bool> play(String file) async {
    final fake = debugPlay;
    if (fake != null) return fake(file);
    final gen = _gen;
    try {
      if (!_ready) {
        _ready = true;
        await _player.setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
        );
      }
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      if (gen != _gen) return false;
      final done = Completer<void>();
      late StreamSubscription<void> sub;
      sub = _player.onPlayerComplete.listen((_) {
        sub.cancel();
        if (!done.isCompleted) done.complete();
      });
      await _player.play(AssetSource(file));
      await done.future.timeout(const Duration(seconds: 14), onTimeout: () => sub.cancel());
      return true;
    } catch (_) {
      return false;
    }
  }

  static void stop() {
    _gen++;
    try {
      _player.stop();
    } catch (_) {}
  }
}
