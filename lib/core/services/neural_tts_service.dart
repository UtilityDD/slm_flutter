import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Off until a sanctioned synthesis backend is wired in; lessons and quizzes
/// keep the device voice while false.
const neuralVoiceEnabled = false;

/// One spoken clip and the silence that follows it.
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

/// Edge "Read Aloud" neural voice with an on-device cache.
///
/// The Edge service only accepts one voice + prosody per request, so pauses are
/// played as silences between clips instead of SSML breaks.
class NeuralTtsService {
  NeuralTtsService() {
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
    _completeSub = _player.onPlayerComplete.listen((_) => _endWait());
  }

  static const voice = 'Microsoft Server Speech Text to Speech Voice (bn-IN, BashkarNeural)';
  static const baseRate = '-1%';
  static const basePitch = '+0Hz';

  static const _token = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const _chromium = '130.0.2849.68';
  static const _host = 'speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';
  static final Map<String, Future<File?>> _inflight = {};
  static Directory? _dir;

  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<void> _completeSub;
  Completer<void>? _wait;
  int _run = 0;
  bool speaking = false;
  void Function(bool speaking)? onSpeakingChanged;

  void _mark(bool value) {
    if (speaking == value) return;
    speaking = value;
    onSpeakingChanged?.call(value);
  }

  void _endWait() {
    final w = _wait;
    _wait = null;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// Plays [clips] in order. A clip that cannot be fetched goes to [fallback].
  /// Returns false when nothing could be spoken at all.
  Future<bool> play(
    List<NeuralClip> clips, {
    void Function(int index, NeuralClip clip)? onClip,
    Future<bool> Function(String text)? fallback,
  }) async {
    final mine = ++_run;
    _endWait();
    await _player.stop();
    if (clips.isEmpty || mine != _run) return false;

    final ahead = <int, Future<File?>>{};
    var offline = false;
    var spoke = false;
    Future<File?> fetch(int i) => ahead.putIfAbsent(i, () => offline ? cached(clips[i]) : clipFile(clips[i]));

    for (var i = 0; i < clips.length; i++) {
      if (mine != _run) return spoke;
      for (var j = i; j < math.min(i + 3, clips.length); j++) {
        fetch(j);
      }
      final file = await fetch(i);
      if (mine != _run) return spoke;
      onClip?.call(i, clips[i]);
      if (file != null) {
        final wait = Completer<void>();
        _wait = wait;
        _mark(true);
        await _player.play(DeviceFileSource(file.path));
        await wait.future.timeout(const Duration(seconds: 45), onTimeout: () {});
        spoke = true;
      } else {
        offline = true;
        if (fallback != null) {
          _mark(true);
          if (await fallback(clips[i].text)) spoke = true;
        }
      }
      if (mine != _run) return spoke;
      if (clips[i].pauseMs > 0) await Future<void>.delayed(Duration(milliseconds: clips[i].pauseMs));
    }
    if (mine == _run) _mark(false);
    return spoke;
  }

  Future<void> stop() async {
    _run++;
    _endWait();
    _mark(false);
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _completeSub.cancel();
    await _player.dispose();
  }

  static String ssml(NeuralClip c) =>
      "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='bn-IN'>"
      "<voice name='$voice'><prosody pitch='${c.pitch}' rate='${c.rate}' volume='${c.volume}'>"
      '${_escape(c.text)}</prosody></voice></speak>';

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static Future<File> _fileFor(String doc) async {
    _dir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/neural_tts');
    final dir = _dir!;
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${md5.convert(utf8.encode(doc))}.mp3');
  }

  /// The saved clip, or null when it was never fetched.
  static Future<File?> cached(NeuralClip c) async {
    final f = await _fileFor(ssml(c));
    return await f.exists() && await f.length() > 0 ? f : null;
  }

  /// Saved clip, fetching it from Edge on the first play.
  static Future<File?> clipFile(NeuralClip c) {
    final doc = ssml(c);
    return _inflight.putIfAbsent(doc, () async {
      try {
        final f = await _fileFor(doc);
        if (await f.exists() && await f.length() > 0) return f;
        final bytes = await _synthesize(doc);
        if (bytes == null || bytes.isEmpty) return null;
        final tmp = File('${f.path}.part');
        await tmp.writeAsBytes(bytes, flush: true);
        return await tmp.rename(f.path);
      } catch (_) {
        return null;
      } finally {
        unawaited(Future<void>.delayed(Duration.zero, () => _inflight.remove(doc)));
      }
    });
  }

  static String _hex(int bytes) {
    final r = math.Random.secure();
    return List.generate(bytes, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static String _secMsGec() {
    var ticks = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 11644473600;
    ticks -= ticks % 300;
    final hundredNs = BigInt.from(ticks) * BigInt.from(10000000);
    return sha256.convert(ascii.encode('$hundredNs$_token')).toString().toUpperCase();
  }

  static String _stamp() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = DateTime.now().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${days[d.weekday - 1]} ${months[d.month - 1]} ${two(d.day)} ${d.year} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)} GMT+0000 (Coordinated Universal Time)';
  }

  static Future<Uint8List?> _synthesize(String doc) async {
    final major = _chromium.split('.').first;
    final url = 'wss://$_host?TrustedClientToken=$_token&ConnectionId=${_hex(16)}'
        '&Sec-MS-GEC=${_secMsGec()}&Sec-MS-GEC-Version=1-$_chromium';
    final client = HttpClient()
      ..userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/$major.0.0.0 Safari/537.36 Edg/$major.0.0.0'
      ..connectionTimeout = const Duration(seconds: 6);
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(url, customClient: client, headers: {
        'Pragma': 'no-cache',
        'Cache-Control': 'no-cache',
        'Origin': 'chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cookie': 'muid=${_hex(16).toUpperCase()}',
      }).timeout(const Duration(seconds: 8));

      final audio = BytesBuilder(copy: false);
      final done = Completer<bool>();
      ws.listen(
        (msg) {
          if (msg is String) {
            if (msg.contains('Path:turn.end') && !done.isCompleted) done.complete(true);
          } else if (msg is List<int>) {
            if (msg.length < 2) return;
            final headLen = (msg[0] << 8) | msg[1];
            if (msg.length < 2 + headLen) return;
            final head = ascii.decode(msg.sublist(2, 2 + headLen), allowInvalid: true);
            if (head.contains('Path:audio')) audio.add(msg.sublist(2 + headLen));
          }
        },
        onError: (_) {
          if (!done.isCompleted) done.complete(false);
        },
        onDone: () {
          if (!done.isCompleted) done.complete(false);
        },
        cancelOnError: true,
      );

      final stamp = _stamp();
      ws.add('X-Timestamp:$stamp\r\n'
          'Content-Type:application/json; charset=utf-8\r\n'
          'Path:speech.config\r\n\r\n'
          '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false",'
          '"wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}\r\n');
      ws.add('X-RequestId:${_hex(16)}\r\n'
          'Content-Type:application/ssml+xml\r\n'
          'X-Timestamp:${stamp}Z\r\n'
          'Path:ssml\r\n\r\n'
          '$doc');

      final ok = await done.future.timeout(const Duration(seconds: 20), onTimeout: () => false);
      final bytes = audio.takeBytes();
      return ok && bytes.isNotEmpty ? bytes : null;
    } catch (_) {
      return null;
    } finally {
      try {
        await ws?.close();
      } catch (_) {}
      client.close(force: true);
    }
  }
}
