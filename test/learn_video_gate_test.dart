// Learn explainer video gate (lib/features/game/learn_video_gate.dart): the
// first watch of a lesson's video can't be skipped; later visits can. A fake
// player stands in for YouTube (no webview).
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_explainer_videos.dart';
import 'package:slm_flutter/features/game/learn_video_gate.dart';
import 'package:slm_flutter/features/game/learn_video_player.dart';
import 'package:slm_flutter/features/rank/cloud_save.dart';

class _FakePlayer implements LearnVideoPlayer {
  _FakePlayer({LearnVideoStatus initial = LearnVideoStatus.ready}) : _status = initial;

  final double duration = 100;
  final _ctl = StreamController<LearnVideoStatus>.broadcast();
  LearnVideoStatus _status;
  double pos = 0;
  final seeks = <double>[];
  int plays = 0;
  int pauses = 0;
  int positionReads = 0;
  bool locked = false;
  bool closed = false;

  void emit(LearnVideoStatus s) {
    _status = s;
    if (!_ctl.isClosed) _ctl.add(s);
  }

  @override
  Stream<LearnVideoStatus> get statusStream => _ctl.stream;

  @override
  LearnVideoStatus get status => _status;

  @override
  Future<double> positionSeconds() async {
    positionReads++;
    return pos;
  }

  @override
  Future<double> durationSeconds() async => duration;

  @override
  Future<void> play() async {
    plays++;
    emit(LearnVideoStatus.playing);
  }

  @override
  Future<void> pause() async {
    pauses++;
    if (_status == LearnVideoStatus.playing) emit(LearnVideoStatus.paused);
  }

  @override
  Future<void> seekTo(double seconds) async {
    seeks.add(seconds);
    pos = seconds;
  }

  @override
  Widget view({
    required bool locked,
    required Widget Function(BuildContext context, Widget? fullscreenButton) lockedControls,
  }) {
    this.locked = locked;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Builder(
        builder: (ctx) => Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (locked) lockedControls(ctx, null) else const Text('YT_CONTROLS'),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    closed = true;
    await _ctl.close();
  }
}

class _Rig {
  _Rig(this.container);
  final ProviderContainer container;
  final players = <_FakePlayer>[];
  var nowMs = 0;
  var reads = 0;
  _FakePlayer get player => players.last;
  GameSave get save => container.read(gameSaveProvider);
}

const _mustWatch = 'প্রথমবার পুরো ভিডিওটি দেখতে হবে';
const _needNet = 'ভিডিওটি দেখতে ইন্টারনেট দরকার';
final _guide = find.byKey(const ValueKey('guide'));
final _board = find.text('BOARD');
final _skip = find.byKey(const ValueKey('learnVideoSkip'));

Future<_Rig> _open(
  WidgetTester tester, {
  required bool watched,
  _FakePlayer Function(int attempt)? makePlayer,
}) async {
  SharedPreferences.setMockInitialValues({});
  // Orientation calls answer at once (no real platform in tests).
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(gameSaveProvider);
  await tester.pump();
  if (watched) await container.read(gameSaveProvider.notifier).markVideoWatched('1.1');
  final rig = _Rig(container);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: LearnVideoGatePage(
          rungId: '1.1/learn',
          lessonId: '1.1',
          ladderIndex: 0,
          pack: learnBoardPackFor('1.1')!,
          youtubeId: 'gm8u-yXIbZs',
          muted: true,
          wallClock: () => Duration(milliseconds: rig.nowMs),
          playerFactory: (id, {required firstWatch}) {
            final p = makePlayer?.call(rig.players.length) ?? _FakePlayer();
            rig.players.add(p);
            return p;
          },
          boardBuilder: (_) => const Scaffold(body: Text('BOARD')),
          guideBuilder: (line, onDone) => Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('guide'),
              behavior: HitTestBehavior.opaque,
              onTap: onDone,
              child: ColoredBox(color: Colors.black, child: Text(line)),
            ),
          ),
          onReadLesson: (_) async => rig.reads++,
        ),
      ),
    ),
  );
  await tester.pump();
  // Listen guide → video.
  await tester.tap(_guide);
  await tester.pump();
  await tester.pump();
  return rig;
}

/// Plays [seconds] of real time in 500 ms steps; the fake video advances
/// only while playing and ends at its duration.
Future<void> _play(WidgetTester tester, _Rig rig, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.5) {
    rig.nowMs += 500;
    final p = rig.player;
    if (p.status == LearnVideoStatus.playing) {
      p.pos = math.min(p.duration, p.pos + 0.5);
      if (p.pos >= p.duration) p.emit(LearnVideoStatus.ended);
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _wait(WidgetTester tester, _Rig rig, double seconds) async {
  rig.nowMs += (seconds * 1000).round();
  await tester.pump(Duration(milliseconds: (seconds * 1000).round()));
}

String _pctText(int pct) => '$pct%';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirstWatchTracker', () {
    test('normal play counts; a forward jump is a skip and seeks back', () {
      final t = FirstWatchTracker();
      for (var i = 1; i <= 20; i++) {
        expect(t.sample(i * 0.5, 0.5, counting: true), isNull);
      }
      expect(t.watched, closeTo(10, 1e-9));
      expect(t.sample(60, 0.5, counting: true), 10);
      expect(t.watched, closeTo(10, 1e-9));
      expect(t.position, 10);
      // Backward seeks are fine (no credit); going back to watched ground too.
      expect(t.sample(4, 0.5, counting: true), isNull);
      expect(t.sample(9.8, 0.5, counting: true), isNull);
      expect(t.watched, closeTo(10, 1e-9));
    });

    test('paused or buffering never counts, and a jump while paused is a skip', () {
      final t = FirstWatchTracker();
      t.sample(5, 4, counting: true); // allowed 6.35
      expect(t.watched, 5);
      expect(t.sample(5, 30, counting: false), isNull);
      expect(t.watched, 5);
      expect(t.sample(5.3, 30, counting: false), isNull); // within jitter
      expect(t.watched, 5);
      expect(t.sample(20, 30, counting: false), 5.3);
    });

    test('completion needs 95 % watched AND the end', () {
      final t = FirstWatchTracker();
      t.watched = 94;
      expect(t.complete(100, atEnd: true), isFalse);
      t.watched = 95;
      expect(t.complete(100, atEnd: false), isFalse);
      expect(t.complete(100, atEnd: true), isTrue);
      expect(t.atEnd(98.1, 100, ended: false), isTrue);
      expect(t.atEnd(97, 100, ended: false), isFalse);
      expect(t.atEnd(0, 100, ended: true), isTrue);
      expect(t.complete(0, atEnd: true), isFalse); // unknown duration
      t.watched = 90;
      // 5 s missing: restart early enough to watch them before the end window.
      expect(t.replayFrom(100), 92);
    });
  });

  group('GameSave.videosWatched', () {
    test('survives the JSON round trip and the cloud blob; old saves default empty', () {
      final s = GameSave.empty.copyWith(videosWatched: {'2.3', '1.1'});
      final back = GameSave.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.videosWatched, {'1.1', '2.3'});
      final old = Map<String, dynamic>.from(GameSave.empty.toJson())..remove('videosWatched');
      expect(GameSave.fromJson(old).videosWatched, isEmpty);
      final cloud = decodeCloudSave(encodeCloudSave(s)!)!;
      expect(GameSave.fromJson(cloud.game).videosWatched, {'1.1', '2.3'});
    });
  });

  test('lessonsWithVideo lists only lessons with a usable id or URL', () {
    final ids = LearnExplainerVideos.lessonsWithVideo();
    expect(ids, contains('1.1'));
    for (final id in ids) {
      expect(LearnExplainerVideos.youtubeIdFor(id), isNotNull, reason: id);
    }
    expect(LearnExplainerVideos.parseVideoId('https://youtu.be/gm8u-yXIbZs'), 'gm8u-yXIbZs');
  });

  testWidgets('first watch: no skip, jumps pulled back, full watch marks it and opens the board', (tester) async {
    final rig = await _open(tester, watched: false);
    final p = rig.player;
    expect(p.locked, isTrue);
    expect(_skip, findsNothing);
    expect(find.text('YT_CONTROLS'), findsNothing);
    expect(find.byKey(const ValueKey('learnVideoPlayPause')), findsOneWidget);
    expect(find.byKey(const ValueKey('learnVideoWatched')), findsOneWidget);

    p.emit(LearnVideoStatus.playing);
    await tester.pump();
    await _play(tester, rig, 10);
    expect(find.text(_pctText(10)), findsOneWidget);

    // Skip ahead: pulled back to the last watched second, gentle toast.
    p.pos = 80;
    await _play(tester, rig, 0.5);
    await tester.pump();
    expect(p.seeks.last, closeTo(10, 0.6));
    expect(find.text(_mustWatch), findsOneWidget);
    expect(find.text(_pctText(10)), findsOneWidget);

    // Jump straight to the end (ended state): also rejected, and it plays on.
    p.pos = p.duration;
    p.emit(LearnVideoStatus.ended);
    await tester.pump();
    await tester.pump();
    expect(p.seeks.last, lessThan(15));
    expect(rig.save.videosWatched, isEmpty);
    expect(_board, findsNothing);
    p.emit(LearnVideoStatus.playing);
    await tester.pump();

    await _play(tester, rig, 100);
    expect(rig.save.videosWatched, contains('1.1'));
    // Existing "play carefully" guide line, then the board.
    expect(find.textContaining('সাবধানে খেলুন'), findsOneWidget);
    await tester.tap(_guide);
    await tester.pump();
    expect(_board, findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('later visit: normal controls and a skip button straight to the board', (tester) async {
    final rig = await _open(tester, watched: true);
    expect(rig.player.locked, isFalse);
    expect(find.text('YT_CONTROLS'), findsOneWidget);
    expect(find.byKey(const ValueKey('learnVideoWatched')), findsNothing);
    expect(_skip, findsOneWidget);
    expect(find.text('এড়িয়ে যান ›'), findsOneWidget);
    await tester.tap(_skip);
    await tester.pump();
    expect(_board, findsOneWidget);
    expect(rig.player.closed, isTrue);
  });

  testWidgets('offline first watch: board locked, retry and read the lesson; never marked', (tester) async {
    final rig = await _open(
      tester,
      watched: false,
      makePlayer: (attempt) => _FakePlayer(initial: attempt == 0 ? LearnVideoStatus.error : LearnVideoStatus.loading),
    );
    expect(find.text(_needNet), findsOneWidget);
    expect(find.byKey(const ValueKey('learnVideoRetry')), findsOneWidget);
    expect(find.text('পাঠ পড়ুন'), findsOneWidget);
    expect(_skip, findsNothing);
    expect(_board, findsNothing);

    await tester.tap(find.byKey(const ValueKey('learnVideoRead')));
    await tester.pump();
    expect(rig.reads, 1);
    expect(_board, findsNothing);

    // Retry: the player never answers -> offline again after the load timeout.
    await tester.tap(find.byKey(const ValueKey('learnVideoRetry')));
    await tester.pump();
    await tester.pump();
    expect(rig.players, hasLength(2));
    expect(find.text(_needNet), findsNothing);
    await _wait(tester, rig, 16);
    expect(find.text(_needNet), findsOneWidget);
    expect(_board, findsNothing);
    expect(rig.save.videosWatched, isEmpty);
  });

  testWidgets('offline later visit goes straight to the board', (tester) async {
    await _open(
      tester,
      watched: true,
      makePlayer: (_) => _FakePlayer(initial: LearnVideoStatus.error),
    );
    expect(find.text(_needNet), findsNothing);
    expect(_board, findsOneWidget);
  });

  testWidgets('pause and buffering do not count; backgrounding pauses', (tester) async {
    final rig = await _open(tester, watched: false);
    final p = rig.player;
    p.emit(LearnVideoStatus.playing);
    await tester.pump();
    await _play(tester, rig, 10);
    expect(find.text(_pctText(10)), findsOneWidget);

    p.emit(LearnVideoStatus.paused);
    await tester.pump();
    await _wait(tester, rig, 20);
    p.emit(LearnVideoStatus.buffering);
    await tester.pump();
    await _wait(tester, rig, 5);
    expect(find.text(_pctText(10)), findsOneWidget);

    p.emit(LearnVideoStatus.playing);
    await tester.pump();
    await _play(tester, rig, 10);
    expect(find.text(_pctText(20)), findsOneWidget);

    // App goes to the background: the video pauses, watch time is kept.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(p.pauses, 1);
    expect(p.status, LearnVideoStatus.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text(_pctText(20)), findsOneWidget);
    expect(rig.save.videosWatched, isEmpty);
  });

  testWidgets('idle: zero frames and no sampling while paused', (tester) async {
    final rig = await _open(tester, watched: false);
    final p = rig.player;
    p.emit(LearnVideoStatus.playing);
    await tester.pump();
    await _play(tester, rig, 3);
    // Our own play/pause button pauses it.
    await tester.tap(find.byKey(const ValueKey('learnVideoPlayPause')));
    await tester.pump();
    expect(p.status, LearnVideoStatus.paused);
    await _wait(tester, rig, 2);
    final reads = p.positionReads;
    await _wait(tester, rig, 5);
    expect(p.positionReads, reads, reason: 'no position polling while paused');
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
