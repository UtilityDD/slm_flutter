// The guide Subrata's ladder welcome (owner-approved W01–W11, 2026-11-14):
// which line each situation gets, the priority order, and the GameSave
// fields that feed it.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/guide/welcome_chooser.dart';

WelcomeSituation pick({
  required DateTime now,
  DateTime? last,
  bool l1 = true,
  bool first = false,
  bool died = false,
  bool rank = false,
  String? name,
}) =>
    chooseWelcome(
      now: now,
      lastLadderOpen: last,
      l1Cleared: l1,
      isFirstEver: first,
      diedLastSession: died,
      rankedUpSinceLastOpen: rank,
      name: name,
    );

void main() {
  final day = DateTime(2026, 11, 14);
  DateTime at(int h, [int m = 0, int s = 0]) => DateTime(2026, 11, 14, h, m, s);
  final yesterday = DateTime(2026, 11, 13, 20);

  group('chooseWelcome', () {
    test('W01: the very first ladder open', () {
      expect(pick(now: at(9), first: true, l1: false), WelcomeSituation.firstEver);
    });

    test('W02: a new player before level 1 is cleared', () {
      expect(pick(now: at(9, 30), last: at(9), l1: false), WelcomeSituation.newBeforeL1);
      expect(pick(now: at(18), last: yesterday, l1: false), WelcomeSituation.newBeforeL1);
    });

    test('after level 1 a new player gets the normal welcomes', () {
      expect(pick(now: at(9, 30), last: at(9)), WelcomeSituation.sameDay);
    });

    test('W08: the last session ended in a death', () {
      expect(pick(now: at(10), last: at(9), died: true), WelcomeSituation.afterDeath);
    });

    test('W09: a rank-up since the last open', () {
      expect(pick(now: at(10), last: at(9), rank: true), WelcomeSituation.afterRankUp);
    });

    test('W07: 3 or more days away; 2 days is a normal first of day', () {
      expect(pick(now: at(10), last: DateTime(2026, 11, 11, 23, 59)), WelcomeSituation.afterBreak);
      expect(pick(now: at(10), last: DateTime(2026, 10, 1, 12)), WelcomeSituation.afterBreak);
      expect(pick(now: at(10), last: DateTime(2026, 11, 12, 0, 1)), WelcomeSituation.dailyMorning);
    });

    test('W03/W04/W05: first open of the day by local time (boundaries at 12:00 and 17:00)', () {
      expect(pick(now: day, last: yesterday), WelcomeSituation.dailyMorning);
      expect(pick(now: at(11, 59, 59), last: yesterday), WelcomeSituation.dailyMorning);
      expect(pick(now: at(12), last: yesterday), WelcomeSituation.dailyAfternoon);
      expect(pick(now: at(16, 59, 59), last: yesterday), WelcomeSituation.dailyAfternoon);
      expect(pick(now: at(17), last: yesterday), WelcomeSituation.dailyEvening);
      expect(pick(now: at(23, 59), last: yesterday), WelcomeSituation.dailyEvening);
    });

    test('an older save with no last-open time counts as first of the day', () {
      expect(pick(now: at(13)), WelcomeSituation.dailyAfternoon);
    });

    test('W10: a known name replaces W03–W05 on the first open of the day only', () {
      expect(pick(now: at(8), last: yesterday, name: 'দীপঙ্কর'), WelcomeSituation.dailyNamed);
      expect(pick(now: at(19), last: yesterday, name: 'দীপঙ্কর'), WelcomeSituation.dailyNamed);
      expect(pick(now: at(19), last: yesterday, name: '  '), WelcomeSituation.dailyEvening);
      expect(pick(now: at(19), last: yesterday), WelcomeSituation.dailyEvening);
      expect(pick(now: at(19), last: at(18), name: 'দীপঙ্কর'), WelcomeSituation.sameDay);
    });

    test('W06: again later the same day', () {
      expect(pick(now: at(23, 59), last: day), WelcomeSituation.sameDay);
    });

    test('priority: W01 > W02 > W08 > W09 > W07 > first of day > W06', () {
      final old = DateTime(2026, 11, 1);
      expect(pick(now: at(9), last: old, first: true, l1: false, died: true, rank: true, name: 'ক'),
          WelcomeSituation.firstEver);
      expect(pick(now: at(9), last: old, l1: false, died: true, rank: true, name: 'ক'), WelcomeSituation.newBeforeL1);
      expect(pick(now: at(9), last: old, died: true, rank: true, name: 'ক'), WelcomeSituation.afterDeath);
      expect(pick(now: at(9), last: old, rank: true, name: 'ক'), WelcomeSituation.afterRankUp);
      expect(pick(now: at(9), last: old, name: 'ক'), WelcomeSituation.afterBreak);
      expect(pick(now: at(9), last: yesterday, name: 'ক'), WelcomeSituation.dailyNamed);
      expect(pick(now: at(9), last: at(8), name: 'ক'), WelcomeSituation.sameDay);
    });
  });

  group('welcome lines', () {
    test('the owner-approved spoken texts, verbatim', () {
      String spoken(WelcomeSituation s) => MascotSpeechLibrary.welcomeCue(s).textBn;
      expect(spoken(WelcomeSituation.firstEver),
          'নমস্কার! আমি সুব্রত। নিরাপদে কাজ শেখার এই পথে আপনাকে স্বাগত জানাই — চলুন, প্রথম ধাপ থেকে শুরু করি।');
      expect(spoken(WelcomeSituation.newBeforeL1), 'আমি সুব্রত। প্রথম কাজটা দিয়েই শুরু করা যাক — আমি সঙ্গে আছি।');
      expect(spoken(WelcomeSituation.dailyMorning), 'নমস্কার, সুপ্রভাত! আমি সুব্রত — আজকের ধাপটা একসাথে নিরাপদে শেষ করি।');
      expect(spoken(WelcomeSituation.dailyAfternoon), 'আমি সুব্রত। চলুন, আজকের ধাপটা নিরাপদে এগিয়ে নিই।');
      expect(spoken(WelcomeSituation.dailyEvening), 'নমস্কার, শুভ সন্ধ্যা! আমি সুব্রত — আজকের শেষ কাজটা একসাথে করি।');
      expect(spoken(WelcomeSituation.sameDay), 'আমি সুব্রত। পরের ধাপটা তৈরি — চলুন, শুরু করি।');
      expect(spoken(WelcomeSituation.afterBreak), 'আমি সুব্রত। কয়েকদিনের বিরতির পর ফিরলেন — আজ ধীরে, নিরাপদে শুরু করি।');
      expect(spoken(WelcomeSituation.afterDeath), 'নমস্কার, আমি সুব্রত। ভুল থেকেই শেখা — চলুন, এবার সাবধানে এগোই।');
      expect(spoken(WelcomeSituation.afterRankUp),
          'আমি সুব্রত — আপনার উন্নতিতে আমি গর্বিত। নতুন মডিউলের প্রথম ধাপ অপেক্ষা করছে।');
      expect(spoken(WelcomeSituation.dailyNamed), 'সুব্রত বলছি — আজও নিরাপদে কাজ শিখি।');
      expect(MascotSpeechLibrary.homeGreetingBn, 'সুব্রত বলছি — আজকের কাজের জন্য তৈরি তো?');
      expect(MascotSpeechLibrary.welcomeSpokenLines, hasLength(11));
      expect(MascotSpeechLibrary.welcomeSpokenLines.toSet(), hasLength(11));
    });

    test('every welcome has Subrata introduce himself', () {
      for (final line in MascotSpeechLibrary.welcomeSpokenLines) {
        expect(line, contains('সুব্রত'), reason: line);
      }
    });

    test('W10: the caption carries the name, the spoken text has no placeholder or name', () {
      final spoken = MascotSpeechLibrary.welcomeCue(WelcomeSituation.dailyNamed).textBn;
      expect(spoken, isNot(contains('{')));
      expect(spoken, isNot(contains('নাম')));
      expect(spoken, isNot(contains(r'$')));
      expect(MascotSpeechLibrary.welcomeCaption(WelcomeSituation.dailyNamed, name: ' দীপঙ্কর '),
          'দীপঙ্কর, সুব্রত বলছি — আজও নিরাপদে কাজ শিখি।');
      // No name known: the caption is just the spoken text.
      expect(MascotSpeechLibrary.welcomeCaption(WelcomeSituation.dailyNamed), spoken);
      // Other welcomes never show the name.
      expect(MascotSpeechLibrary.welcomeCaption(WelcomeSituation.sameDay, name: 'দীপঙ্কর'),
          MascotSpeechLibrary.welcomeCue(WelcomeSituation.sameDay).textBn);
    });

    test('the old "হাই / হ্যালো / ওয়েলকাম ব্যাক / আবার এসেছেন" welcomes are gone', () {
      for (final line in MascotSpeechLibrary.welcomeSpokenLines) {
        for (final old in ['হাই', 'হ্যালো', 'ওয়েলকাম', 'আবার এসেছেন', 'আবার দেখা হলো']) {
          expect(line, isNot(contains(old)));
        }
      }
    });
  });

  group('GameSave welcome fields', () {
    test('JSON round trip keeps them; an old save defaults sensibly', () {
      final s = GameSave.empty.copyWith(
        lastLadderOpenMs: at(9).millisecondsSinceEpoch,
        diedLastSession: true,
        rankedUpSinceLastOpen: true,
      );
      final back = GameSave.fromJson(s.toJson());
      expect(back.lastLadderOpen, at(9));
      expect(back.diedLastSession, isTrue);
      expect(back.rankedUpSinceLastOpen, isTrue);

      final old = GameSave.fromJson({'points': 40, 'rungProgress': {'1.1/learn': 'cleared'}});
      expect(old.lastLadderOpenMs, isNull);
      expect(old.lastLadderOpen, isNull);
      expect(old.diedLastSession, isFalse);
      expect(old.rankedUpSinceLastOpen, isFalse);
    });

    test('a death sets the flag, a later pass clears it, and a welcome consumes both flags', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(gameSaveProvider);
      await Future<void>.delayed(Duration.zero);
      final save = c.read(gameSaveProvider.notifier);

      await save.recordLethalDeath(cause: 'x', lessonId: '1.5', rungId: '1.5/do/1', moduleFirstRungId: '1.1/learn');
      expect(c.read(gameSaveProvider).diedLastSession, isTrue);
      await save.markRungCleared('1.1/learn');
      expect(c.read(gameSaveProvider).diedLastSession, isFalse);

      await save.recordLethalDeath(cause: 'x', lessonId: '1.5', rungId: '1.5/do/1', moduleFirstRungId: '1.1/learn');
      await save.unlockRank(2);
      expect(c.read(gameSaveProvider).rankedUpSinceLastOpen, isTrue);
      await save.unlockRank(2); // not a new rank
      await save.noteLadderOpen(at(10), consumeFlags: false);
      expect(c.read(gameSaveProvider).diedLastSession, isTrue);
      expect(c.read(gameSaveProvider).rankedUpSinceLastOpen, isTrue);
      expect(c.read(gameSaveProvider).lastLadderOpen, at(10));

      await save.noteLadderOpen(at(11), consumeFlags: true);
      final s = c.read(gameSaveProvider);
      expect(s.diedLastSession, isFalse);
      expect(s.rankedUpSinceLastOpen, isFalse);
      expect(s.lastLadderOpen, at(11));
    });
  });

  group('GuideDirector ladder entrance', () {
    tearDown(() => GuideDirector.clock = DateTime.now);

    Future<ProviderContainer> boot(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final c = ProviderContainer();
      c.read(gameSaveProvider);
      await Future<void>.delayed(Duration.zero);
      return c;
    }

    test('first ever → W01 centre welcome; a fresh session later the same day → W02 hi-pop', () async {
      GuideDirector.clock = () => at(9);
      var c = await boot({});
      var kind = await c.read(guideDirectorProvider.notifier).beginLadderEntrance(muted: true);
      expect(kind, GuideEntranceKind.dailyWelcome);
      expect(c.read(guideDirectorProvider.notifier).entranceLine,
          MascotSpeechLibrary.welcomeCue(WelcomeSituation.firstEver).textBn);
      final saved = c.read(gameSaveProvider).toJson();
      c.dispose();

      // New app session (new container), same day, level 1 still not cleared.
      GuideDirector.clock = () => at(10);
      c = await boot({'game_save_v1': _json(saved)});
      addTearDown(c.dispose);
      kind = await c.read(guideDirectorProvider.notifier).beginLadderEntrance(muted: true);
      expect(kind, GuideEntranceKind.hiPop);
      expect(c.read(guideDirectorProvider.notifier).entranceLine,
          MascotSpeechLibrary.welcomeCue(WelcomeSituation.newBeforeL1).textBn);
    });

    test('a death last session → W08 on the next welcome, then the flag is gone', () async {
      GuideDirector.clock = () => at(14);
      final save = GameSave.empty.copyWith(
        rungProgress: {'1.1/learn': 'cleared'},
        lastLadderOpenMs: yesterday.millisecondsSinceEpoch,
        diedLastSession: true,
      );
      final c = await boot({'game_save_v1': _json(save.toJson())});
      addTearDown(c.dispose);
      final kind = await c.read(guideDirectorProvider.notifier).beginLadderEntrance(muted: true);
      expect(kind, GuideEntranceKind.dailyWelcome);
      expect(c.read(guideDirectorProvider.notifier).entranceLine,
          MascotSpeechLibrary.welcomeCue(WelcomeSituation.afterDeath).textBn);
      expect(c.read(gameSaveProvider).diedLastSession, isFalse);
      expect(c.read(gameSaveProvider).lastLadderOpen, at(14));
    });

    test('an older install (legacy welcome day, no last-open time) is not greeted as new', () async {
      GuideDirector.clock = () => at(18);
      final save = GameSave.empty.copyWith(rungProgress: {'1.1/learn': 'cleared'}, points: 30);
      final c = await boot({'game_save_v1': _json(save.toJson()), 'guide_last_welcome_day_v1': '2026-11-13'});
      addTearDown(c.dispose);
      await c.read(guideDirectorProvider.notifier).beginLadderEntrance(muted: true);
      expect(c.read(guideDirectorProvider.notifier).entranceLine,
          MascotSpeechLibrary.welcomeCue(WelcomeSituation.dailyEvening).textBn);
    });
  });
}

String _json(Map<String, dynamic> m) => jsonEncode(m);
