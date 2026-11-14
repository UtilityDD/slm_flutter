// Life skills (জীবন দক্ষতা) as lucky-toolbox prizes: the bundled content
// loads, a skill is invisible until won and then listed under "আমার জীবন
// দক্ষতা", the detail screen renders (card, sections, pro tip, myth buster,
// narration with an offline note) and sits still, and the narration is saved
// on the phone only after one full streamed play (no real network here).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/home/home_toolbox.dart';
import 'package:slm_flutter/features/training/training_screen.dart' show passedLessonKeysProvider;
import 'package:slm_flutter/features/life_skills/life_skill_audio.dart';
import 'package:slm_flutter/features/life_skills/life_skills_data.dart';
import 'package:slm_flutter/features/life_skills/life_skills_menu_row.dart';
import 'package:slm_flutter/features/life_skills/life_skills_screen.dart';

/// Reads bundled files from disk at once (on the fake test clock).
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async => File(key).readAsStringSync();
}

class _SeededSave extends GameSaveController {
  _SeededSave(this.seed);

  final GameSave seed;

  @override
  GameSave build() => seed;
}

Override _seed(GameSave s) => gameSaveProvider.overrideWith(() => _SeededSave(s));

class _GuestAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(profile: LinemanProfile.guest());
}

GameSave _won(List<String> ids) => GameSave.empty.copyWith(toolbox: ToolboxSave(lifeSkills: ids));

Widget _app(GameSave save, Widget home) => ProviderScope(
      overrides: [_seed(save)],
      child: MaterialApp(home: home),
    );

/// Counts frames and rebuilds over ~1 s of an idle screen.
Future<(int, int)> _idleFrames(WidgetTester t) async {
  var rebuilds = 0;
  debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
  var frames = 0;
  for (var i = 0; i < 60; i++) {
    if (t.binding.hasScheduledFrame) frames++;
    await t.pump(const Duration(milliseconds: 16));
  }
  debugOnRebuildDirtyWidget = null;
  return (frames, rebuilds);
}

/// Lets real image decodes finish, then settles the frame.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final ch in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    messenger.setMockMethodCallHandler(MethodChannel(ch), (_) async => 1);
  }
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LifeSkillsRepo.instance = LifeSkillsRepo(bundle: _DiskBundle());
  });

  group('content', () {
    test('13 modules load, each with its lesson, quiz (with answers) and bundled pictures', () async {
      final repo = LifeSkillsRepo(bundle: _DiskBundle());
      final modules = await repo.modules();
      expect([for (final m in modules) m.id], kLifeSkillIds);
      // Works for CRLF and LF checkouts.
      final pubspec = File('pubspec.yaml').readAsStringSync().replaceAll('\r\n', '\n');
      for (final m in modules) {
        expect(m.titleBn, isNotEmpty);
        expect(m.code, startsWith('LS'));
        expect(m.audioUrl, startsWith('https://raw.githubusercontent.com/UtilityDD/slm_audio/main/life_skill_'));
        expect(File(m.cardAsset).existsSync(), isTrue, reason: m.cardAsset);
        final lesson = (await repo.lesson(m.id))!;
        expect(lesson.sections, isNotEmpty);
        expect(lesson.proTips, isNotEmpty);
        expect(lesson.myths, isNotEmpty);
        for (final p in lesson.sections.expand((s) => s.points)) {
          if (p.image.isNotEmpty) expect(File(p.image).existsSync(), isTrue, reason: p.image);
          expect(p.image.startsWith('assets/life_skills/images/') || p.image.isEmpty, isTrue);
        }
        final quiz = await repo.questions(m.id);
        expect(quiz.length, greaterThanOrEqualTo(20));
        expect(quiz.every((q) => q.correctIndex >= 0 && q.correctIndex < q.options.length), isTrue);
      }
      for (final dir in ['assets/life_skills/', 'assets/life_skills/lessons/', 'assets/life_skills/questions/', 'assets/life_skills/cards/', 'assets/life_skills/images/']) {
        expect(pubspec, contains('    - $dir\n'), reason: dir);
      }
      // The WAVs are streamed, never bundled.
      expect(Directory('assets/life_skills').listSync(recursive: true).where((f) => f.path.endsWith('.wav')), isEmpty);
    });
  });

  group('menu', () {
    Widget sheet() => Scaffold(
          body: Column(
            children: [
              const Text('টুলবক্স'),
              const LifeSkillsMenuRow(closeSheetFirst: false),
              const Text('শেষ'),
            ],
          ),
        );

    testWidgets('hidden before any life skill is won', (t) async {
      await t.pumpWidget(_app(GameSave.empty, sheet()));
      await t.pump();
      expect(find.text(LifeSkillLines.menu), findsNothing);
      expect(find.byKey(const ValueKey('life-skills-menu-row')), findsNothing);
      // Unknown ids (never a real prize) do not show it either.
      await t.pumpWidget(_app(_won(['nope']), sheet()));
      await t.pump();
      expect(find.text(LifeSkillLines.menu), findsNothing);
    });

    testWidgets('a won life skill appears in the menu, then in the list, and opens its page', (t) async {
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(_won(['supp_10_3', 'supp_10_1']), sheet()));
      await t.pump();
      expect(find.text(LifeSkillLines.menu), findsOneWidget);
      expect(find.text('2/13'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('life-skills-menu-row')));
      await t.pumpAndSettle();
      expect(find.byType(LifeSkillsListPage), findsOneWidget);
      final repo = LifeSkillsRepo(bundle: _DiskBundle());
      final s3 = (await repo.module('supp_10_3'))!;
      final s1 = (await repo.module('supp_10_1'))!;
      expect(find.text(s3.titleBn), findsOneWidget);
      expect(find.text(s1.titleBn), findsOneWidget);
      // Only won ones are listed: in the order they were won.
      expect(t.getTopLeft(find.byKey(const ValueKey('life-skill-supp_10_3'))).dy,
          lessThan(t.getTopLeft(find.byKey(const ValueKey('life-skill-supp_10_1'))).dy));
      expect(find.byKey(const ValueKey('life-skill-supp_10_2')), findsNothing);
      await t.tap(find.byKey(const ValueKey('life-skill-supp_10_3')));
      await t.pumpAndSettle();
      expect(find.byType(LifeSkillDetailPage), findsOneWidget);
    });
  });

  group('toolbox sheet', () {
    Future<void> openSheet(WidgetTester t, GameSave save) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          _seed(save),
          authProvider.overrideWith(_GuestAuth.new),
          passedLessonKeysProvider.overrideWithValue(const <String>{}),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(builder: (c) => HomeToolboxButton(onTap: () => openHomeToolbox(c))),
            ),
          ),
        ),
      ));
      await t.tap(find.byType(HomeToolboxButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
    }

    testWidgets('the row is hidden in the real sheet until a skill is won', (t) async {
      await openSheet(t, GameSave.empty);
      expect(find.text(LifeSkillLines.menu), findsNothing);
    });

    testWidgets('once won it sits after আমার পাঠ, closes the sheet and opens the list', (t) async {
      await openSheet(t, _won(['supp_10_5']));
      expect(find.text(LifeSkillLines.menu), findsOneWidget);
      expect(find.text('1/13'), findsOneWidget);
      final lessons = t.getTopLeft(find.text('আমার পাঠ')).dy;
      final row = t.getTopLeft(find.text(LifeSkillLines.menu)).dy;
      final emergency = t.getTopLeft(find.text('জরুরি নম্বর')).dy;
      expect(row, greaterThan(lessons));
      expect(row, lessThan(emergency));
      await t.tap(find.byKey(const ValueKey('life-skills-menu-row')));
      await t.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(LifeSkillsListPage), findsOneWidget);
      expect(find.byKey(const ValueKey('life-skill-supp_10_5')), findsOneWidget);
    });
  });

  group('detail', () {
    for (final cached in [false, true]) {
      testWidgets('renders card, sections, pro tip, myths and the audio note, and sits still (${cached ? 'audio saved' : 'not saved yet'})', (t) async {
        t.view.physicalSize = const Size(800, 1600);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        final root = Directory.systemTemp.createTempSync('ls_audio');
        addTearDown(() => root.deleteSync(recursive: true));
        final repo = LifeSkillsRepo(bundle: _DiskBundle());
        final m = (await repo.module('supp_10_1'))!;
        final lesson = (await repo.lesson('supp_10_1'))!;
        final audio = LifeSkillAudioCache(root: () async => root, fetch: (_) async => throw StateError('no network in tests'));
        if (cached) {
          final f = (await audio.fileFor(m.audioUrl))!;
          f.parent.createSync(recursive: true);
          f.writeAsBytesSync([1, 2, 3]);
        }
        await t.pumpWidget(_app(_won(['supp_10_1']), LifeSkillDetailPage(moduleId: 'supp_10_1', repo: repo, audio: audio)));
        await t.pump();
        await _settle(t);
        expect(find.text(m.titleBn), findsWidgets);
        expect(find.byKey(const ValueKey('life-skill-audio')), findsOneWidget);
        expect(find.text(cached ? LifeSkillLines.savedNote : LifeSkillLines.offlineNote), findsOneWidget);
        expect(find.text(lesson.sections.first.title.replaceAll('১', '1')), findsOneWidget);
        await t.scrollUntilVisible(find.byKey(const ValueKey('life-skill-pro-tip')), 400);
        await _settle(t);
        expect(find.byKey(const ValueKey('life-skill-pro-tip')), findsOneWidget);
        await t.scrollUntilVisible(find.byKey(const ValueKey('life-skill-myth-0')), 400);
        expect(find.descendant(of: find.byKey(const ValueKey('life-skill-myth-0')), matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
        await _settle(t);
        await t.pump(const Duration(seconds: 2));
        final (frames, rebuilds) = await _idleFrames(t);
        expect(frames, 0);
        expect(rebuilds, 0);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('the list sits still too', (t) async {
      await t.pumpWidget(_app(_won(['supp_10_2']), const LifeSkillsListPage()));
      await t.pump();
      await _settle(t);
      expect(find.byKey(const ValueKey('life-skill-supp_10_2')), findsOneWidget);
      final (frames, rebuilds) = await _idleFrames(t);
      expect(frames, 0);
      expect(rebuilds, 0);
    });
  });

  group('audio cache', () {
    const url = 'https://raw.githubusercontent.com/UtilityDD/slm_audio/main/life_skill_07.wav';

    test('the file name and place come from the URL', () async {
      expect(LifeSkillAudioCache.fileNameFor(url), 'life_skill_07.wav');
      expect(LifeSkillAudioCache.fileNameFor(''), isNull);
      expect(LifeSkillAudioCache.fileNameFor('not a url'), isNull);
      expect(LifeSkillAudioCache.fileNameFor('https://x.org/a/..'), isNull);
      final root = Directory.systemTemp.createTempSync('ls_audio');
      addTearDown(() => root.deleteSync(recursive: true));
      final cache = LifeSkillAudioCache(root: () async => root, fetch: (_) async => throw StateError('offline'));
      final f = (await cache.fileFor(url))!;
      expect(f.path, endsWith('${LifeSkillAudioCache.folder}${Platform.pathSeparator}life_skill_07.wav'));
      expect(f.path, startsWith(root.path));
      expect(await cache.cached(url), isNull);
    });

    test('saved only after a full play; a failed download leaves nothing; saved once', () async {
      final root = Directory.systemTemp.createTempSync('ls_audio');
      addTearDown(() => root.deleteSync(recursive: true));
      var calls = 0;
      var online = false;
      final cache = LifeSkillAudioCache(
        root: () async => root,
        fetch: (u) async {
          calls++;
          expect(u.toString(), url);
          if (!online) throw const SocketException('offline');
          return utf8.encode('RIFF....WAVE');
        },
      );
      // Offline: nothing saved, no half file.
      expect(await cache.saveAfterFullPlay(url), isFalse);
      expect(await cache.cached(url), isNull);
      expect(root.listSync(recursive: true).whereType<File>(), isEmpty);
      online = true;
      expect(await cache.saveAfterFullPlay(url), isTrue);
      final saved = (await cache.cached(url))!;
      expect(saved.readAsStringSync(), 'RIFF....WAVE');
      expect(File('${saved.path}.part').existsSync(), isFalse);
      // Already saved: no second download.
      expect(await cache.saveAfterFullPlay(url), isTrue);
      expect(calls, 2);
    });
  });
}
