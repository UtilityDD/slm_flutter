import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

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

  /// Plays [file] (from [resolve]) and completes when it has finished.
  static Future<bool> play(String file) async {
    try {
      if (!_ready) {
        _ready = true;
        await _player.setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
        );
      }
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
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
    try {
      _player.stop();
    } catch (_) {}
  }
}
