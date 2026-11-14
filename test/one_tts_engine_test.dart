// The guide's device voice (MascotSpeechLibrary) and the lesson reader
// (BanglaReadAloud) must share one flutter_tts engine.
//
// flutter_tts sends every platform callback (speak.onStart, speak.onComplete…)
// over one static MethodChannel to whichever FlutterTts was built last, and
// `awaitSpeakCompletion` is one plugin-wide flag. With two FlutterTts objects
// the newer one took every callback and the two set the flag opposite ways:
//  * reader after the guide: the reader's lines never heard their completion
//    and waited out a 15 s timeout;
//  * guide after the reader: speak() returned at once (flag false), so his lips
//    closed as the voice began and "wait until quiet" stopped waiting.
// The fake platform below behaves like the plugin: it reports start, and
// `speak` returns only at completion while the flag is true.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/home/bangla_read_aloud.dart';

const _channel = MethodChannel('flutter_tts');

class _FakeTts {
  final calls = <String>[];
  var awaitCompletion = false;
  double pitch = 1.0;
  final spokenAtPitch = <double>[];
  Completer<void>? _speaking;

  TestDefaultBinaryMessenger get _m => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void install() {
    _m.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'awaitSpeakCompletion':
          awaitCompletion = call.arguments as bool;
          return 1;
        case 'isLanguageAvailable':
          return call.arguments == 'bn-IN';
        case 'getLanguages':
          return ['bn-IN'];
        case 'getVoices':
          return <Object>[];
        case 'setPitch':
          pitch = (call.arguments as num).toDouble();
          return 1;
        case 'speak':
          spokenAtPitch.add(pitch);
          final done = _speaking = Completer<void>();
          scheduleMicrotask(() => _send('speak.onStart'));
          if (awaitCompletion) await done.future;
          return 1;
        case 'stop':
          if (_speaking case final s? when !s.isCompleted) {
            _speaking = null;
            s.complete();
            _send('speak.onCancel');
          }
          return 1;
        default:
          return 1;
      }
    });
  }

  /// The engine finished the utterance.
  void complete() {
    final s = _speaking;
    _speaking = null;
    _send('speak.onComplete');
    if (s != null && !s.isCompleted) s.complete();
  }

  void _send(String method) {
    _m.handlePlatformMessage(
      _channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
      (_) {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fake = _FakeTts()..install();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }

  Future<void> readerLine(BanglaReadAloud reader, String what) async {
    final read = reader.speakAwait('পাঠের একটি বাক্য।');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    fake.complete();
    await expectLater(read.timeout(const Duration(seconds: 2)), completes, reason: '$what: the reader hears its own end');
  }

  Future<void> guideLine(String what, {double pitch = 1.0}) async {
    const line = 'এই লাইনের কোনো রেকর্ড করা ক্লিপ নেই, যন্ত্রের গলায় বলবে।';
    final guide = MascotSpeechLibrary.speak(line, pitch: pitch);
    var done = false;
    unawaited(guide.then((_) => done = true));
    for (var i = 0; i < 20 && !MascotTalk.active.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(MascotTalk.active.value, isTrue, reason: '$what: his lips move while the voice runs');
    expect(done, isFalse, reason: '$what: speak() waits for the voice');
    fake.complete();
    await guide.timeout(const Duration(seconds: 1));
    expect(MascotTalk.active.value, isFalse, reason: '$what: lips close when the voice ends');
  }

  test('guide and reader share one device voice; each hears its own end', () async {
    // App start warms the guide's voice; later a lesson page makes a reader.
    await MascotSpeechLibrary.warmUp();
    final reader = BanglaReadAloud();
    await reader.init();
    await readerLine(reader, 'reader first');
    await guideLine('guide after the reader', pitch: 0.82);
    await readerLine(reader, 'reader after the guide');
    expect(fake.spokenAtPitch.sublist(fake.spokenAtPitch.length - 2), [0.82, 1.0],
        reason: 'a voice\'s pitch (an operator at 0.82) does not stay on for the reader');
    final second = BanglaReadAloud();
    await second.init();
    await guideLine('guide after a second reader');
    expect(fake.calls.where((c) => c == 'awaitSpeakCompletion').length, lessThanOrEqualTo(1),
        reason: 'one engine sets the plugin-wide flag once');
  });
}
