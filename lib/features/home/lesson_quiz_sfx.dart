import 'package:audioplayers/audioplayers.dart';

/// Short UI cues for the lesson quiz. Independent of TTS mute.
class LessonQuizSfx {
  LessonQuizSfx();

  final AudioPlayer _a = AudioPlayer();
  final AudioPlayer _b = AudioPlayer();
  bool _useA = true;
  bool _disposed = false;

  Future<void> shuffle() => _play('sounds/quiz_shuffle.wav', volume: 0.8);
  Future<void> flip() => _play('sounds/quiz_flip.wav', volume: 0.7);
  Future<void> select() => _play('sounds/quiz_select.wav', volume: 0.55);
  Future<void> complete() => _play('sounds/quiz_complete.wav', volume: 0.85);
  Future<void> success() => _play('sounds/quiz_right.wav', volume: 0.9);
  Future<void> failure() => _play('sounds/quiz_wrong.wav', volume: 0.85);

  Future<void> result(bool passed) => passed ? success() : failure();

  Future<void> _play(String asset, {double volume = 0.8}) async {
    if (_disposed) return;
    final player = _useA ? _a : _b;
    _useA = !_useA;
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.release);
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setVolume(volume);
      await player.play(AssetSource(asset));
    } catch (_) {
      // Ignore missing assets / platform audio failures.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _a.dispose();
    await _b.dispose();
  }
}
