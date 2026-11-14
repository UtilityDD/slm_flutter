import '../zero_loss/zero_loss_fx.dart';

/// Short UI cues for the lesson quiz. Independent of TTS mute.
/// Plays through the shared [SlmSfx] players; nothing native is owned here.
class LessonQuizSfx {
  LessonQuizSfx();

  bool _disposed = false;

  Future<void> shuffle() => _play('sounds/quiz_shuffle.ogg', volume: 0.8);
  Future<void> flip() => _play('sounds/quiz_flip.ogg', volume: 0.7);
  Future<void> select() => _play('sounds/quiz_select.ogg', volume: 0.55);
  Future<void> complete() => _play('sounds/quiz_complete.ogg', volume: 0.85);
  Future<void> success() => _play('sounds/quiz_right.ogg', volume: 0.9);
  Future<void> failure() => _play('sounds/quiz_wrong.ogg', volume: 0.85);

  Future<void> result(bool passed) => passed ? success() : failure();

  Future<void> _play(String asset, {double volume = 0.8}) async {
    if (_disposed) return;
    await SlmSfx.play(asset, volume: volume, mix: false);
  }

  Future<void> dispose() async {
    _disposed = true;
  }
}
