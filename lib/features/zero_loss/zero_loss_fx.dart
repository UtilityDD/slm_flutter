import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Quiet bed under the whole shift. Effects stay on their own player.
class ZlMusic {
  static final _player = AudioPlayer();
  static var _ready = false;
  static var _playing = false;
  static var _muted = false;

  static bool get muted => _muted;

  static Future<void> start() async {
    try {
      if (!_ready) {
        _ready = true;
        await _player.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(0.14);
      }
      if (_muted || _playing) return;
      _playing = true;
      await _player.play(AssetSource('sounds/safe_home.wav'));
    } catch (_) {
      _playing = false;
    }
  }

  static Future<void> setMuted(bool value) async {
    if (_muted == value) return;
    _muted = value;
    try {
      if (value) {
        await _player.pause();
      } else if (_playing) {
        await _player.resume();
      } else {
        await start();
      }
    } catch (_) {}
  }

  static Future<void> stop() async {
    _playing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }
}

/// Short original cues. The clock runs for the whole timed stretch of a job.
class ZlFx {
  static final _clock = AudioPlayer();
  static var _clockReady = false;
  static var _playing = false;
  static var _holds = 0;
  static var _muted = false;
  static var _busy = false;
  static var _again = false;

  static Future<void> _mix(AudioPlayer player) {
    return player.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
  }

  /// One screen that should hear the clock. Several screens can hold it at once.
  static void holdClock() {
    _holds++;
    _kick();
  }

  static void releaseClock() {
    if (_holds > 0) _holds--;
    _kick();
  }

  /// Drop every hold. Used when the job ends so the sting is not under the tick.
  static void stopClock() {
    _holds = 0;
    _kick();
  }

  static void setMuted(bool muted) {
    if (_muted == muted) return;
    _muted = muted;
    _kick();
  }

  static void _kick() {
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    unawaited(_drain());
  }

  static Future<void> _drain() async {
    try {
      do {
        _again = false;
        await _apply();
      } while (_again);
    } finally {
      _busy = false;
      if (_again) _kick();
    }
  }

  static Future<void> _apply() async {
    final play = _holds > 0 && !_muted;
    try {
      if (!play) {
        if (_playing) {
          _playing = false;
          await _clock.stop();
        }
        return;
      }
      if (_playing) return;
      _playing = true;
      if (!_clockReady) {
        _clockReady = true;
        await _mix(_clock);
        await _clock.setReleaseMode(ReleaseMode.loop);
        await _clock.setVolume(0.38);
      }
      if (_holds == 0 || _muted) {
        _playing = false;
        return;
      }
      await _clock.play(AssetSource('sounds/clock_tick.wav'));
    } catch (_) {
      _playing = false;
    }
  }

  static Future<void> cue(String file, {double volume = 0.7, bool muted = false}) async {
    if (muted) return;
    final player = AudioPlayer();
    try {
      await _mix(player);
      await player.setVolume(volume);
      await player.setReleaseMode(ReleaseMode.stop);
      var closed = false;
      void close() {
        if (closed) return;
        closed = true;
        player.dispose();
      }

      player.onPlayerComplete.listen((_) => close());
      await player.play(AssetSource(file));
    } catch (_) {
      player.dispose();
    }
  }
}
