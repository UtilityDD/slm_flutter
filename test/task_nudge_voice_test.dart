// Tapping the guide in a Do level repeats the task a different way each time
// (TaskNudge). Every way is spoken in Subrata's recorded voice: a repeat with
// no clip of its own plays the prefix's clip, then the task's clip.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/do_parts.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/learn_voice_map.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_lug_pick.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

const _again = 'আবার বলছি — ';
const _rush = 'তাড়াহুড়ো নয়। ';
const _look = 'ভালো করে দেখুন। ';

/// Tasks whose «আবার বলছি — …» repeat was recorded whole.
final _recordedTasks = [
  for (final k in learnCoachVoice.keys)
    if (k.startsWith(_again)) k.substring(_again.length),
];

Future<void> _pumpUntil(WidgetTester t, bool Function() done, {int maxMs = 40000}) async {
  for (var ms = 0; ms < maxMs && !done(); ms += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('resolution', () {
    test('each nudge prefix has its own clip on disk', () {
      expect(LearnVoice.nudgePrefixes, [_again, _rush, _look]);
      for (final p in LearnVoice.nudgePrefixes) {
        final clip = LearnVoice.resolve(p);
        expect(clip, isNotNull, reason: p);
        expect(File('assets/$clip').existsSync(), isTrue, reason: clip);
      }
    });

    test('prefix + recorded task → the prefix clip, then the task clip', () {
      expect(_recordedTasks, isNotEmpty);
      for (final task in _recordedTasks) {
        final taskClip = LearnVoice.resolve(task);
        expect(taskClip, isNotNull, reason: task);
        for (final p in [_rush, _look]) {
          final line = '$p$task';
          // A few of these were recorded whole: that clip wins (next test).
          if (LearnVoice.resolve(line) != null) continue;
          expect(LearnVoice.resolveNudge(line), [LearnVoice.resolve(p), taskClip], reason: line);
        }
      }
    });

    test('a whole recorded line wins (no split)', () {
      final whole = [
        for (final k in learnCoachVoice.keys)
          if (LearnVoice.nudgePrefixes.any((p) => k.startsWith(p))) k,
      ];
      expect(whole.length, greaterThan(_recordedTasks.length));
      for (final line in whole) {
        expect(LearnVoice.resolveNudge(line), isNull, reason: line);
      }
    });

    test('an unrecorded task, or a line that is not a nudge, is left as it was', () {
      const unknown = 'এই লাইনটা কোথাও রেকর্ড করা হয়নি — পরীক্ষা মাত্র।';
      expect(LearnVoice.resolve(unknown), isNull);
      for (final p in LearnVoice.nudgePrefixes) {
        expect(LearnVoice.resolveNudge('$p$unknown'), isNull);
      }
      expect(LearnVoice.resolveNudge(_recordedTasks.first), isNull, reason: 'the task alone has its own clip');
      expect(LearnVoice.resolveNudge('কিছু একটা। ${_recordedTasks.first}'), isNull);
    });

    test('TaskNudge cycles the task and the three prefixes', () {
      final n = TaskNudge();
      const t = 'কাজটা';
      expect([for (var i = 0; i < 5; i++) n.next(t)], [t, '$_again$t', '$_rush$t', '$_look$t', t]);
    });
  });

  group('playback', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);

    // Each "clip" lasts 600 ms; the lips are sampled half-way through it.
    final played = <String>[];
    final lipsMid = <bool>[];
    Future<bool> fakeClip(String f) async {
      played.add(f);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      lipsMid.add(MascotTalk.active.value);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return true;
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      played.clear();
      lipsMid.clear();
      LearnVoice.debugPlay = fakeClip;
    });
    tearDown(() {
      LearnVoice.debugPlay = null;
      MascotTalk.reset();
    });

    testWidgets('speak: two clips in a row, lips open for both, done only after the second', (t) async {
      final task = _recordedTasks.first;
      var done = false;
      MascotSpeechLibrary.speak('$_rush$task').then((_) => done = true);
      await t.pump(const Duration(milliseconds: 700));
      expect(done, isFalse, reason: 'still on the second clip');
      expect(MascotTalk.active.value, isTrue);
      await _pumpUntil(t, () => done);
      expect(done, isTrue);
      expect(played, [LearnVoice.resolve(_rush), LearnVoice.resolve(task)]);
      expect(lipsMid, [true, true]);
      expect(MascotTalk.active.value, isFalse, reason: 'lips close when both have played');
    });

    testWidgets('speak: stop() during the prefix ends the sequence (no task clip)', (t) async {
      final task = _recordedTasks.first;
      LearnVoice.debugPlay = (f) async {
        if (played.isEmpty) {
          Future<void>.delayed(const Duration(milliseconds: 200), MascotSpeechLibrary.stop);
        }
        return fakeClip(f);
      };
      var done = false;
      MascotSpeechLibrary.speak('$_look$task').then((_) => done = true);
      await _pumpUntil(t, () => done);
      expect(played, [LearnVoice.resolve(_look)]);
      expect(MascotTalk.active.value, isFalse);
    });

    testWidgets('speak: an exact clip plays alone', (t) async {
      final task = _recordedTasks.first;
      var done = false;
      MascotSpeechLibrary.speak('$_again$task').then((_) => done = true);
      await _pumpUntil(t, () => done);
      expect(played, [LearnVoice.resolve('$_again$task')]);
    });

    testWidgets('Do level (2.3 lug pick): tapping the guide speaks every way in recorded clips', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const ctx = LevelContext(
        rungId: '2.3/do/0',
        kind: CatalogRungKind.doKind,
        lessonId: '2.3',
        lessonTitleBn: '',
        ladderStep: 7,
        doIndex: 1,
        doCount: 2,
      );
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: M2LugPickPage(ctx: ctx, pack: m2LugPickPack23, seed: 0)),
      ));
      await t.pump(const Duration(milliseconds: 400));
      await waitIntro(t);
      await t.pump(const Duration(seconds: 2));
      expect(LearnVoice.resolve(LugLines.ask), isNotNull, reason: 'the task is recorded');

      final guide = t.getRect(find.byType(AiLinemanGuide).last);
      final task = LearnVoice.resolve(LugLines.ask)!;
      // A whole recorded line plays alone; otherwise the prefix clip, then the task's.
      List<String> expected(String line) {
        final whole = LearnVoice.resolve(line);
        if (whole != null) return [whole];
        final p = LearnVoice.nudgePrefixes.firstWhere(line.startsWith);
        return [LearnVoice.resolve(p)!, task];
      }

      final heard = <String>[];
      for (var i = 0; i < 4; i++) {
        played.clear();
        await t.tapAt(guide.bottomRight - const Offset(50, 50));
        await t.pump(const Duration(milliseconds: 50));
        final line = c.read(guideDirectorProvider).line;
        expect(line, endsWith(LugLines.ask));
        heard.add(line);
        final want = expected(line);
        await _pumpUntil(t, () => played.length >= want.length, maxMs: 3000);
        await t.pump(const Duration(milliseconds: 700));
        expect(played, want, reason: line);
        expect(find.text(line), findsWidgets, reason: 'the bubble shows the whole line');
      }
      expect(heard.toSet(), hasLength(4));
      // This level has whole clips for «আবার বলছি» and «তাড়াহুড়ো নয়»; «ভালো করে দেখুন» is split.
      expect(expected('$_look${LugLines.ask}'), [LearnVoice.resolve(_look), task]);
      expect(t.takeException(), isNull);

      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
