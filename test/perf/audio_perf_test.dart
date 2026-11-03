// Audio perf regression guard. Fakes the audioplayers, flutter_tts and
// path_provider platform channels and counts what the app asks the OS for.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/core/services/neural_tts_service.dart';
import 'package:slm_flutter/features/home/bangla_read_aloud.dart';
import 'package:slm_flutter/features/home/lesson_quiz_sfx.dart';
import 'package:slm_flutter/features/home/level_lessons_sheet.dart';
import 'package:slm_flutter/features/radio/radio_player_provider.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

const _codec = StandardMethodCodec();
const _player = MethodChannel('xyz.luan/audioplayers');
const _global = MethodChannel('xyz.luan/audioplayers.global');
const _globalEvents = 'xyz.luan/audioplayers.global/events';
const _tts = MethodChannel('flutter_tts');
const _paths = MethodChannel('plugins.flutter.io/path_provider');

TestDefaultBinaryMessenger get _bm => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Every audioplayers call, as "method" or "method:playerId".
final _calls = <String>[];
final _ttsCalls = <String>[];
var _creates = 0;
var _disposes = 0;

int _count(String method, [String? id]) =>
    _calls.where((c) => id == null ? c.startsWith('$method:') : c == '$method:$id').length;

void _emit(String id, Map<String, Object?> event) {
  unawaited(_bm.handlePlatformMessage(
    'xyz.luan/audioplayers/events/$id',
    _codec.encodeSuccessEnvelope(event),
    (_) {},
  ));
}

void _installAudio(Directory tmp) {
  _bm.setMockMethodCallHandler(_paths, (call) async => tmp.path);
  _bm.setMockMethodCallHandler(_global, (call) async => 1);
  _bm.setMockMethodCallHandler(const MethodChannel(_globalEvents), (call) async => null);
  _bm.setMockMethodCallHandler(_player, (call) async {
    final args = (call.arguments as Map?) ?? const {};
    final id = '${args['playerId']}';
    _calls.add('${call.method}:$id');
    switch (call.method) {
      case 'create':
        _creates++;
        _bm.setMockMethodCallHandler(MethodChannel('xyz.luan/audioplayers/events/$id'), (_) async => null);
      case 'dispose':
        _disposes++;
      case 'setSourceUrl':
        scheduleMicrotask(() => _emit(id, {'event': 'audio.onPrepared', 'value': true}));
      case 'resume':
        // A real MediaPlayer reports completion; SoundPool never does. Report it
        // anyway so the old per-cue players get their dispose.
        Timer(const Duration(milliseconds: 5), () => _emit(id, {'event': 'audio.onComplete'}));
      case 'getCurrentPosition' || 'getDuration':
        return 0;
    }
    return 1;
  });
}

void _ttsEvent(String method) {
  unawaited(_bm.handlePlatformMessage('flutter_tts', _codec.encodeMethodCall(MethodCall(method)), (_) {}));
}

void _installTts() {
  _bm.setMockMethodCallHandler(_tts, (call) async {
    _ttsCalls.add(call.method);
    switch (call.method) {
      case 'isLanguageAvailable':
        return call.arguments == 'bn-BD';
      case 'getVoices':
        return <Object>[];
      case 'getLanguages':
        return <Object>['bn-BD'];
      case 'speak':
        Timer(const Duration(milliseconds: 20), () => _ttsEvent('speak.onStart'));
        Timer(const Duration(milliseconds: 60), () => _ttsEvent('speak.onComplete'));
        return 1;
    }
    return 1;
  });
}

Future<void> _settle([int ms = 40]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('slm_audio_perf');
    _installAudio(tmp);
    _installTts();
  });

  setUp(() {
    _calls.clear();
    _ttsCalls.clear();
    _creates = 0;
    _disposes = 0;
  });

  test('SFX: native players created for 60 cues across 3 helpers', () async {
    const files = [
      'sounds/quiz_flip.wav',
      'sounds/quiz_select.wav',
      'sounds/quiz_right.wav',
      'sounds/quiz_wrong.wav',
    ];
    // A burst far denser than any screen fires (one cue every 10 ms).
    Future<void> round() async {
      for (var i = 0; i < 40; i++) {
        await ZlFx.cue(files[i % files.length]);
        await _settle(10);
      }
      final quiz = LessonQuizSfx();
      for (var i = 0; i < 4; i++) {
        await quiz.select();
        await quiz.flip();
        await quiz.success();
        await quiz.failure();
        await _settle(10);
      }
      for (var i = 0; i < 4; i++) {
        await playLessonCue(i.isEven);
        await _settle(10);
      }
      await quiz.dispose();
      await _settle(100);
    }

    int calls() => _calls.where((c) => !c.startsWith('getCurrentPosition') && !c.startsWith('getDuration')).length;

    await round();
    final first = _creates;
    final firstCalls = calls();
    final firstResumes = _count('resume');
    await round();
    final second = _creates - first;
    final secondCalls = calls() - firstCalls;
    // ignore: avoid_print
    print('[perf:audio] SFX round 1 (60 cues): players created=$first platform calls=$firstCalls; '
        'round 2 (60 cues): created=$second calls=$secondCalls; live=${_creates - _disposes}');
    // ignore: avoid_print
    print('[perf:audio] SFX position polls (getCurrentPosition) over 120 cues: ${_count('getCurrentPosition')}');
    expect(_count('getCurrentPosition'), 0, reason: 'no per-frame position polling');
    expect(firstResumes, 60, reason: 'every cue must still start a sound');
    expect(_count('resume'), 120);
    // 8 (file, focus) pairs, at most 2 players each, made once.
    expect(first, lessThanOrEqualTo(16), reason: 'cues reuse pooled players');
    expect(second, 0, reason: 'a warm pool creates nothing per cue');
  });

  test('TTS: second reader keeps its own completion; init runs once', () async {
    final a = BanglaReadAloud();
    await a.init();
    final firstInit = _ttsCalls.length;
    _ttsCalls.clear();
    final b = BanglaReadAloud();
    await b.init();
    final secondInit = _ttsCalls.length;
    final watch = Stopwatch()..start();
    var aSpeaking = <bool>[];
    a.onSpeakingChanged = aSpeaking.add;
    await a.speakAwait('নমস্কার লাইনম্যান ভাই।').timeout(const Duration(seconds: 25));
    watch.stop();
    // ignore: avoid_print
    print('[perf:audio] TTS init calls first=$firstInit second=$secondInit; '
        'older reader speakAwait took ${watch.elapsedMilliseconds} ms; a events=$aSpeaking');
    expect(watch.elapsedMilliseconds, lessThan(2000), reason: 'no 20 s silent wait');
    expect(secondInit, 0, reason: 'second page does not redo voice setup');
    expect(a.speaking, isFalse);

    // The newest caller wins; the older one is released at once, not after a timeout.
    final aRun = a.speakAwait('প্রথম লাইন।');
    await _settle(5);
    final w2 = Stopwatch()..start();
    await b.speakAwait('দ্বিতীয় লাইন।').timeout(const Duration(seconds: 25));
    await aRun.timeout(const Duration(seconds: 25));
    w2.stop();
    expect(w2.elapsedMilliseconds, lessThan(2000));
    await a.dispose();
    await b.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('Neural TTS (disabled) and radio create no player until used', () async {
    final n = NeuralTtsService();
    await _settle();
    await n.stop();
    await n.dispose();
    final neural = _creates;
    _creates = 0;
    final container = ProviderContainer();
    container.read(radioProvider);
    container.read(radioProvider.notifier).closePlayer();
    await _settle();
    final radio = _creates;
    container.dispose();
    await _settle();
    // ignore: avoid_print
    print('[perf:audio] players created: neural page=$neural radio first frame=$radio');
    expect(neural, 0);
    expect(radio, 0);
  });

  test('Background pauses music + clock tick and resume restores them', () async {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await ZlMusic.start();
    ZlFx.holdClock();
    await _settle(80);
    // audioplayers' default position updater re-polls on every frame (and asks
    // for that frame) while a player "plays"; looping and low-latency players
    // never stop "playing". Headless tests pump no frames, so count first polls.
    final polls = _count('getCurrentPosition');
    // ignore: avoid_print
    print('[perf:audio] position polls for music+clock start: $polls');
    expect(polls, 0, reason: 'no player polls a position nobody reads');
    _calls.clear();
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      binding.handleAppLifecycleStateChanged(s);
    }
    await _settle(80);
    final paused = _count('pause');
    final stopped = _count('stop');
    _calls.clear();
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      binding.handleAppLifecycleStateChanged(s);
    }
    await _settle(80);
    final resumed = _count('resume');
    // ignore: avoid_print
    print('[perf:audio] background: pause=$paused stop=$stopped; foreground: resume=$resumed');
    expect(paused + stopped, greaterThanOrEqualTo(2), reason: 'music and clock go quiet in background');
    expect(resumed, greaterThanOrEqualTo(2), reason: 'music and clock come back on resume');
    ZlFx.stopClock();
    await ZlMusic.stop();
    await _settle();
  });
}
