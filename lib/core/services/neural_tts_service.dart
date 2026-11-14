// There is no online voice in the app. Lessons and quizzes use bundled
// recorded clips and the phone's own Bangla voice (flutter_tts).
//
// The old client for Microsoft's unofficial Edge "Read Aloud" service was
// removed (Play release, 2026-11-13): it sent lesson text off the phone, which
// the privacy policy says never happens. A future voice pack must ship as
// pre-generated assets, never as a live call. `test/no_online_tts_test.dart`
// fails if an online TTS client comes back.
//
// What is left here only sequences clips through the device voice, for the
// old LearnRunnerPage (lib/features/game/learn_runner.dart); it goes with it.

/// One spoken line and the silence that follows it.
class NeuralClip {
  final String text;
  final String rate;
  final String pitch;
  final String volume;
  final int pauseMs;

  const NeuralClip(
    this.text, {
    this.pauseMs = 0,
    this.rate = NeuralTtsService.baseRate,
    this.pitch = NeuralTtsService.basePitch,
    this.volume = '+0%',
  });

  NeuralClip withPause(int ms) => NeuralClip(text, pauseMs: ms, rate: rate, pitch: pitch, volume: volume);
}

/// Speaks a list of [NeuralClip]s in order, with their pauses, through the
/// device voice passed as `fallback`. Nothing leaves the phone.
class NeuralTtsService {
  /// Builds nothing native.
  NeuralTtsService();

  static const baseRate = '-1%';
  static const basePitch = '+0Hz';

  int _run = 0;
  bool speaking = false;
  void Function(bool speaking)? onSpeakingChanged;

  void _mark(bool value) {
    if (speaking == value) return;
    speaking = value;
    onSpeakingChanged?.call(value);
  }

  /// Plays [clips] in order through [fallback] (the device voice).
  /// Returns false when nothing could be spoken at all.
  Future<bool> play(
    List<NeuralClip> clips, {
    void Function(int index, NeuralClip clip)? onClip,
    Future<bool> Function(String text)? fallback,
  }) async {
    final mine = ++_run;
    if (clips.isEmpty || fallback == null) return false;

    var spoke = false;
    for (var i = 0; i < clips.length; i++) {
      if (mine != _run) return spoke;
      onClip?.call(i, clips[i]);
      _mark(true);
      if (await fallback(clips[i].text)) spoke = true;
      if (mine != _run) return spoke;
      if (clips[i].pauseMs > 0) await Future<void>.delayed(Duration(milliseconds: clips[i].pauseMs));
    }
    if (mine == _run) _mark(false);
    return spoke;
  }

  Future<void> stop() async {
    _run++;
    _mark(false);
  }

  Future<void> dispose() => stop();
}
