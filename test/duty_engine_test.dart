// Rules tests for DutySlipEngine: field-night score accounting (incl. replay),
// leaving the night, and saving / loading progress by level number.
// Run with `flutter test test/duty_engine_test.dart`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_models.dart';

final fieldIndex = dsLevels.length - 1;

late DsPack pack;

DutySlipEngine newEngine({int seed = 7}) => DutySlipEngine(pack, seed: seed);

int indexOfNumber(int n) => dsLevels.indexWhere((l) => l.number == n);

/// Let the engine's unawaited saves finish.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void openField(DutySlipEngine e) {
  e.unlocked = fieldIndex;
  e.openRoad();
  e.openLevel(fieldIndex);
  expect(e.listing, isTrue);
  e.startLevelPlay();
  expect(e.inField, isTrue);
}

/// Plays the night the way the page does, with every answer right.
void playPerfectNight(DutySlipEngine e) {
  openField(e);
  e.openPtw();
  expect(e.submitPtw(feederPick: e.feeder, polePick: e.site.pole, shiftPick: 'আজ রাত'), isTrue);
  var guard = 0;
  while (e.act != DsAct.done) {
    expect(++guard, lessThan(200));
    expect(e.act, isNot(DsAct.lethal));
    if (e.act == DsAct.call) {
      final c = e.activeCall!;
      e.answerCall(c.replies.firstWhere((r) => r.ok).id);
      continue;
    }
    final s = e.step!;
    if (s.kind == DsKind.kit) {
      final yes = <String>{};
      for (final o in s.options) {
        // The page scores each yes/no tap: +5 for a right call.
        if (s.essential.contains(o.id)) yes.add(o.id);
        e.addScore(5);
      }
      expect(e.answerKit(yes).ok, isTrue);
    } else if (s.kind == DsKind.match) {
      expect(e.answerSingle('true').ok, isTrue);
    } else {
      expect(e.answerSingle(s.options.firstWhere((o) => o.correct).id).ok, isTrue);
    }
  }
}

/// Plays a 2-choice SAFE HOME quiz (level 15) with no mistakes.
void playPerfectQuiz(DutySlipEngine e, int number) {
  final i = indexOfNumber(number);
  e.unlocked = i;
  e.openRoad();
  e.openLevel(i);
  e.startLevelPlay();
  expect(e.playing, isTrue);
  while (e.playing) {
    e.tapPlan(e.currentDeck[e.planNext].id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final raw = File('assets/data/duty_slip_job.json').readAsStringSync();
    pack = DsPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('field night score', () {
    test('max is 170: 19 cards, 11 kit items, 3 calls, PTW', () {
      expect(newEngine().fieldMaxScore, 170);
    });

    test('stores only the night\'s own score, not the career total', () async {
      final e = newEngine();
      await e.loadPersistedState();
      playPerfectQuiz(e, 15);
      final before = e.totalCumulativeScore;
      expect(before, 45);
      playPerfectNight(e);
      final night = e.levelBestScore[fieldIndex];
      expect(night, greaterThan(0));
      expect(night, lessThanOrEqualTo(170));
      expect(e.totalCumulativeScore, before + night);
      expect(e.nightTotal, before + night);
    });

    test('replaying the night (same session and next session) does not compound', () async {
      final e = newEngine();
      await e.loadPersistedState();
      playPerfectQuiz(e, 15);
      playPerfectNight(e);
      await settle();
      final first = e.totalCumulativeScore;

      // Same session: leave the report and play again.
      e.backToRoad();
      expect(e.onRoad, isTrue);
      playPerfectNight(e);
      await settle();
      expect(e.totalCumulativeScore, lessThanOrEqualTo(45 + 170));
      final second = e.totalCumulativeScore;

      // Next session: the career score is seeded from prefs.
      final e2 = newEngine(seed: 99);
      await e2.loadPersistedState();
      expect(e2.nightTotal, second);
      playPerfectNight(e2);
      await settle();
      expect(e2.totalCumulativeScore, lessThanOrEqualTo(45 + 170));
      expect(e2.totalCumulativeScore, greaterThanOrEqualTo(first));
    });

    test('a career score inflated by other beats is not absorbed into the field slot', () async {
      SharedPreferences.setMockInitialValues({'ds_career_score': 9000});
      final e = newEngine();
      await e.loadPersistedState();
      expect(e.nightTotal, 9000);
      playPerfectNight(e);
      expect(e.levelBestScore[fieldIndex], lessThanOrEqualTo(170));
    });
  });

  group('leaving the field night', () {
    test('back to ladder mid-night returns to the road with a clean night', () {
      final e = newEngine();
      openField(e);
      e.openPtw();
      e.submitPtw(feederPick: e.feeder, polePick: e.site.pole, shiftPick: 'আজ রাত');
      e.answerSingle('nope');
      e.jumpMinutes(30);
      e.backToRoad();
      expect(e.onRoad, isTrue);
      expect(e.inField, isFalse);
      expect(e.clockLive, isFalse);
      expect(e.clockScreen, isFalse);
      expect(e.briefingPage, 0);
      expect(e.stepIndex, 0);
      expect(e.stamps, isEmpty);
      expect(e.jobSeconds, 0);
      expect(e.safety, 100);
      expect(e.levelBestScore[fieldIndex], 0);
      // And the night can be started again.
      e.openLevel(fieldIndex);
      e.startLevelPlay();
      expect(e.inField, isTrue);
      expect(e.stamps, {'assign'});
    });

    test('a lethal fall in the night lands on the road, not a stale docket', () {
      final e = newEngine();
      openField(e);
      e.fallToModuleCheckpoint();
      expect(e.briefingPage, 0);
      expect(e.onRoad, isTrue);
      expect(e.stamps, isEmpty);
    });
  });

  group('progress save / load', () {
    test('round-trips by level number', () async {
      final e = newEngine();
      await e.loadPersistedState();
      playPerfectQuiz(e, 15);
      await e.savePersistedState();
      final prefs = await SharedPreferences.getInstance();
      final json = jsonDecode(prefs.getString(DutySlipEngine.progressKey)!) as Map<String, dynamic>;
      expect(json['v'], 2);
      expect((json['levels'] as Map)['15']['score'], 45);
      expect(json['unlocked'], 16);

      final e2 = newEngine();
      await e2.loadPersistedState();
      final i = indexOfNumber(15);
      expect(e2.levelBestScore[i], 45);
      expect(e2.bestRank[i], e.bestRank[i]);
      expect(e2.unlocked, indexOfNumber(16));
    });

    test('a worse replay keeps the best score', () async {
      final e = newEngine();
      playPerfectQuiz(e, 15);
      final i = indexOfNumber(15);
      expect(e.levelBestScore[i], 45);
      e.replayNow();
      e.tapPlan('not-a-step');
      while (e.playing) {
        e.tapPlan(e.currentDeck[e.planNext].id);
      }
      expect(e.levelBestScore[i], 45);
    });

    test('migrates the old 19-level index lists onto the right level numbers', () async {
      final ranks = List.filled(19, '');
      final scores = List.filled(19, '0');
      ranks[2] = 'darun'; // old L3 -> L3
      scores[2] = '30';
      ranks[11] = 'motamuti'; // old L12 (10-choice job) -> L26
      scores[11] = '40';
      ranks[18] = 'darun'; // old L19 (field night) -> L33
      scores[18] = '120';
      SharedPreferences.setMockInitialValues({
        'ds_career_score': 190,
        'ds_unlocked_level': 12, // old L13 -> L27
        'ds_best_ranks': ranks,
        'ds_best_times': List.filled(19, '0'),
        'ds_danger_counts': List.filled(19, '-1'),
        'ds_best_scores': scores,
      });
      final e = newEngine();
      await e.loadPersistedState();
      expect(e.bestRank[indexOfNumber(3)], DsLevelRank.darun);
      expect(e.levelBestScore[indexOfNumber(3)], 30);
      expect(e.bestRank[indexOfNumber(26)], DsLevelRank.motamuti);
      expect(e.levelBestScore[indexOfNumber(26)], 40);
      expect(e.bestRank[fieldIndex], DsLevelRank.darun);
      expect(e.levelBestScore[fieldIndex], 120);
      // Old index 18 must no longer land on the new level 19.
      expect(e.bestRank[indexOfNumber(19)], isNull);
      expect(e.levelBestScore[indexOfNumber(12)], 0);
      expect(e.unlocked, indexOfNumber(27));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('ds_best_ranks'), isFalse);
      expect(prefs.containsKey('ds_unlocked_level'), isFalse);
      expect(prefs.getString(DutySlipEngine.progressKey), isNotNull);

      // Loading again reads the new format and keeps everything.
      final e2 = newEngine();
      await e2.loadPersistedState();
      expect(e2.levelBestScore[indexOfNumber(26)], 40);
      expect(e2.unlocked, indexOfNumber(27));
    });

    test('33-long index lists map one to one', () async {
      final ranks = List.filled(33, '');
      ranks[20] = 'motamuti';
      SharedPreferences.setMockInitialValues({
        'ds_unlocked_level': 21,
        'ds_best_ranks': ranks,
        'ds_best_scores': List.filled(33, '0'),
      });
      final e = newEngine();
      await e.loadPersistedState();
      expect(e.bestRank[20], DsLevelRank.motamuti);
      expect(e.unlocked, 21);
    });

    test('repairs an inflated field slot and a field score moved onto level 19', () async {
      final scores = List.filled(33, '0');
      scores[indexOfNumber(15)] = '45';
      scores[indexOfNumber(19)] = '900';
      scores[fieldIndex] = '5000';
      SharedPreferences.setMockInitialValues({
        'ds_career_score': 5945,
        'ds_best_ranks': List.filled(33, ''),
        'ds_best_scores': scores,
      });
      final e = newEngine();
      await e.loadPersistedState();
      expect(e.levelBestScore[fieldIndex], 170);
      expect(e.levelBestScore[indexOfNumber(19)], 45);
      expect(e.levelBestScore[indexOfNumber(15)], 45);
      expect(e.nightTotal, 45 + 45 + 170);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('ds_career_score'), 45 + 45 + 170);
    });
  });
}
