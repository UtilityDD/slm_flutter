import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

AudioContext _mixContext() => AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();

/// Pauses the music bed and the clock tick while the app is out of sight.
class _Background {
  static AppLifecycleListener? _listener;
  static var away = false;

  static void ensure() {
    if (_listener != null) return;
    try {
      _listener = AppLifecycleListener(onStateChange: _changed);
    } catch (_) {}
  }

  static void _changed(AppLifecycleState state) {
    final gone = state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    if (gone && !away) {
      away = true;
      unawaited(ZlMusic._background(true));
      ZlFx._kick();
    } else if (state == AppLifecycleState.resumed && away) {
      away = false;
      unawaited(ZlMusic._background(false));
      ZlFx._kick();
    }
  }
}

/// One shared set of short-cue players for the whole app.
///
/// Each cue file keeps up to [_perFile] pre-loaded low-latency players that are
/// reused, so a tap costs a stop + play instead of a new native player.
class SlmSfx {
  static const _perFile = 2;
  // Every cue is shorter than this, so a slot started earlier is free again.
  static const _busyFor = Duration(milliseconds: 1500);
  static final _clock = Stopwatch()..start();
  static final _slots = <String, List<_SfxSlot>>{};

  /// Plays [file] (an asset path under assets/). [mix] keeps other audio
  /// playing, as ZlFx cues always did; the lesson cues used default focus.
  static Future<void> play(String file, {double volume = 0.7, bool mix = true}) async {
    final slot = _pick('$file|$mix', file, mix);
    try {
      await slot.play(volume);
    } catch (_) {}
  }

  static _SfxSlot _pick(String key, String file, bool mix) {
    final list = _slots.putIfAbsent(key, () => []);
    final now = _clock.elapsed;
    _SfxSlot? oldest;
    for (final s in list) {
      if (now - s.startedAt >= _busyFor) return s..startedAt = now;
      if (oldest == null || s.startedAt < oldest.startedAt) oldest = s;
    }
    if (list.length < _perFile || oldest == null) {
      final slot = _SfxSlot(file, mix)..startedAt = now;
      list.add(slot);
      return slot;
    }
    return oldest..startedAt = now;
  }
}

/// A player nobody reads the position of. audioplayers otherwise polls the
/// position on every frame while it is "playing" (forcing frames), and a
/// low-latency or looping player never leaves that state.
AudioPlayer _quietPlayer() => AudioPlayer()..positionUpdater = null;

class _SfxSlot {
  _SfxSlot(this.file, this.mix) {
    _ready = _prepare();
  }

  final String file;
  final bool mix;
  final AudioPlayer _player = _quietPlayer();
  late Future<bool> _ready;
  double? _volume;
  Duration startedAt = Duration.zero;

  Future<bool> _prepare() async {
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      if (mix) await _player.setAudioContext(_mixContext());
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setSource(AssetSource(file));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> play(double volume) async {
    if (!await _ready) {
      _ready = _prepare();
      if (!await _ready) return;
    }
    // A low-latency player resumes its finished stream unless stopped first.
    await _player.stop();
    if (_volume != volume) {
      _volume = volume;
      await _player.setVolume(volume);
    }
    await _player.resume();
  }
}

/// Quiet bed under the whole shift. Effects stay on their own player.
class ZlMusic {
  static final _player = _quietPlayer();
  static var _ready = false;
  static var _playing = false;
  static var _muted = false;
  // Paused by the app going to the background, owed a resume.
  static var _held = false;

  static bool get muted => _muted;

  static Future<void> start() async {
    _Background.ensure();
    try {
      if (!_ready) {
        _ready = true;
        await _player.setAudioContext(_mixContext());
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(0.14);
      }
      if (_muted || _playing) return;
      _playing = true;
      if (_Background.away) {
        // Started while out of sight: set the source now, sound on return.
        await _player.setSource(AssetSource('sounds/safe_home.wav'));
        _held = true;
        return;
      }
      await _player.play(AssetSource('sounds/safe_home.wav'));
    } catch (_) {
      _playing = false;
    }
  }

  static Future<void> _background(bool away) async {
    try {
      if (away) {
        if (_playing && !_muted) {
          _held = true;
          await _player.pause();
        }
      } else if (_held) {
        _held = false;
        if (_playing && !_muted) await _player.resume();
      }
    } catch (_) {}
  }

  static Future<void> setMuted(bool value) async {
    if (_muted == value) return;
    _muted = value;
    try {
      if (value) {
        await _player.pause();
      } else if (_playing && _Background.away) {
        _held = true;
      } else if (_playing) {
        await _player.resume();
      } else {
        await start();
      }
    } catch (_) {}
  }

  static Future<void> stop() async {
    _playing = false;
    _held = false;
    try {
      await _player.stop();
    } catch (_) {}
  }
}

/// Short original cues. The clock runs for the whole timed stretch of a job.
class ZlFx {
  static final _clock = _quietPlayer();
  static var _clockReady = false;
  static var _playing = false;
  static var _holds = 0;
  static var _muted = false;
  static var _busy = false;
  static var _again = false;

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
    _Background.ensure();
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

  static bool get _wanted => _holds > 0 && !_muted && !_Background.away;

  static Future<void> _apply() async {
    try {
      if (!_wanted) {
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
        await _clock.setAudioContext(_mixContext());
        await _clock.setReleaseMode(ReleaseMode.loop);
        await _clock.setVolume(0.38);
      }
      if (!_wanted) {
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
    await SlmSfx.play(file, volume: volume);
  }
}
