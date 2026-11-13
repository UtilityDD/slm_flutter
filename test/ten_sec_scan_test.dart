// Lesson 1.10, কাজ 1 "10 সেকেন্ডের স্ক্যান" (ladder step 29): the lesson's ten
// questions in order, the deal (4–6 safe checks, at least one deadly fault,
// the coworker on a check of either kind), the owner's rulings, captions that
// never give the answer, option libraries, English digits, and the level in
// the shell: a full play that passes and saves the clear and the stars, the
// coworker's check asked after him, a deadly GO that freezes first, and the
// 3-slip strike-out.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/do_games.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/mistakes_book.dart';
import 'package:slm_flutter/features/game/ten_sec_scan.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _rung = '1.10/do/0';
final _pack = tenSecPacks['do_1_10_a']!;

const _ctx = LevelContext(
  rungId: _rung,
  kind: CatalogRungKind.doKind,
  lessonId: '1.10',
  lessonTitleBn: '১০ সেকেন্ডের মেন্টাল চেকলিস্ট',
  ladderStep: 29,
  doIndex: 0,
  doCount: 1,
);

final _bnDigit = RegExp('[০-৯]');

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Picks the right card of the deck; a reason deck then waits on proceed.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  await t.pump();
  for (var i = 0; i < 60 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => TenSecScanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Finder get _go => find.text(TenSecLines.goBtn);
Finder get _stop => find.text(TenSecLines.stopBtn);

/// Refuses the coworker on his check: his deck, then the reason.
Future<void> _refuseHim(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  expect(_go, findsNothing, reason: 'no GO/STOP while he is coming');
  await _pickRight(t, TenSecLines.coworker.right);
  await _pickRight(t, TenSecLines.coworkerWhyRight);
  await _pump(t, 1200);
}

/// Plays check [i] right: GO or STOP, then the reason.
Future<void> _playRight(WidgetTester t, TenSecDeal deal, int i) async {
  final c = deal.checks[i];
  if (i == deal.coworkerRound) await _refuseHim(t);
  expect(await _pumpUntil(t, _go), isTrue, reason: 'check $i is asked');
  expect(find.byKey(ValueKey('scan-card-$i')), findsOneWidget, reason: 'check $i on the card');
  await t.tap(c.isSafe ? _go : _stop);
  await _pump(t, 300);
  expect(find.byType(MistakeCard), findsNothing, reason: 'check $i (${c.id})');
  await _pickRight(t, c.whyRight);
  await _pump(t, 900);
}

int _seedWhere(bool Function(TenSecDeal d) ok) {
  for (var s = 0; s < 5000; s++) {
    if (ok(dealTenSec(math.Random(s)))) return s;
  }
  throw StateError('no seed');
}

/// Every string the level can put on screen.
List<String> _onScreenStrings() => [
      TenSecLines.title, TenSecLines.intro, TenSecLines.ask, TenSecLines.stopBtn, TenSecLines.goBtn,
      TenSecLines.why, TenSecLines.coworkerWhy, ...TenSecLines.tapWhy, ...TenSecLines.taskNudges,
      TenSecLines.deadlyWord, TenSecLines.nearMissWord, TenSecLines.caughtCall,
      TenSecLines.allSet, TenSecLines.quick, TenSecLines.fail,
      TenSecLines.coworker.line, TenSecLines.coworker.exitLine, ...TenSecLines.coworker.right,
      ...TenSecLines.coworker.wrong, ...TenSecLines.coworker.asks,
      ...TenSecLines.coworkerWhyRight, ...TenSecLines.coworkerWhyWrong,
      for (final tp in tenSecTopics.values) ...[tp.nameBn, tp.askBn, ...tp.whyWrong],
      for (final c in TenSecChecks.all) ...[...c.whyRight, c.caughtTag],
      for (final m in TenSecMistakes.all) m.textBn,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final ch in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(ch), (_) async => 1);
  }
  ZlFx.setMuted(true);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('catalog & engine registration', () {
    test('content_catalog has 1.10/do/0 as playable', () {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      final catalog = ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final rung = catalog.rungDefs.firstWhere((r) => r.id == _rung);
      expect(rung.status, CatalogRungStatus.playable);
      expect(rung.packId, 'do_1_10_a');
      expect(rung.lessonId, '1.10');
    });

    test('doGameFor returns the TenSecScanPage builder for do_1_10_a', () {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      final catalog = ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final pack = catalog.packsById['do_1_10_a']!;
      expect(pack.engineType, 'ten_sec_scan');
      expect(doGameFor(pack)!(_ctx, true), isA<TenSecScanPage>());
    });

    test('knownMistakes registers every TenSecMistakes entry', () {
      for (final mk in TenSecMistakes.all) {
        expect(knownMistakes[mk.key], equals(mk), reason: mk.key);
      }
      expect(TenSecMistakes.all.map((x) => x.key).toSet(), hasLength(TenSecMistakes.all.length));
    });
  });

  group('content', () {
    test('the lesson\'s ten questions, in its order, each with safe pictures and faults', () {
      expect(ScanTopic.values, hasLength(10));
      expect(tenSecTopics.keys, ScanTopic.values);
      expect(TenSecChecks.byTopic.keys, ScanTopic.values);
      for (final t in ScanTopic.values) {
        final pool = TenSecChecks.byTopic[t]!;
        expect(pool.where((c) => c.isSafe), isNotEmpty, reason: '$t: a safe picture');
        expect(pool.where((c) => !c.isSafe), isNotEmpty, reason: '$t: a fault');
        expect(pool.every((c) => c.topic == t), isTrue, reason: '$t');
      }
      // The lesson's own words (lesson 1.10, point 2).
      expect(tenSecTopics[ScanTopic.ppe]!.askBn, 'আমার PPE কি 100% ঠিক আছে?');
      expect(tenSecTopics[ScanTopic.escape]!.askBn, contains('পালানোর পথ'));
    });

    test('owner rulings 2026-11-08: nail, polyester, cut webbing deadly; an expired label alone a slip', () {
      expect(TenSecMistakes.bootsNail.deadly, isTrue);
      expect(TenSecMistakes.polyester.deadly, isTrue);
      expect(TenSecMistakes.frayedWebbing.deadly, isTrue);
      expect(TenSecMistakes.expiredLabel.deadly, isFalse);
      for (final c in TenSecChecks.all) {
        expect(c.death != null, c.deadly, reason: '${c.id}: a deadly fault has its consequence, a slip none');
      }
      expect(TenSecChecks.all.firstWhere((c) => c.fault == TenSecMistakes.bootsNail).death, ScanDeath.nail);
      expect(TenSecChecks.all.firstWhere((c) => c.fault == TenSecMistakes.polyester).death, ScanDeath.synthetic);
    });

    test('pictures: every check its own picture, all on disk, mistakes too', () {
      final arts = TenSecChecks.all.map((c) => c.art).toList();
      expect(arts.toSet(), hasLength(arts.length), reason: 'no picture stands in for another check');
      for (final a in [...arts, ...TenSecMistakes.all.map((x) => x.art)]) {
        expect(File(a).existsSync(), isTrue, reason: a);
      }
      for (final c in TenSecChecks.all.where((c) => !c.isSafe)) {
        expect(c.fault!.art, c.art, reason: '${c.id}: the card shows the picture of the fault');
      }
    });

    test('"পাঠে দেখুন" opens a real point of the lesson that teaches the fault', () {
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      int points(String id) {
        final l = lessons.cast<Map<String, dynamic>>().firstWhere((x) => x['id'] == id);
        final sections = (l['content'] as Map<String, dynamic>)['sections'] as List<dynamic>;
        return sections.fold<int>(0, (n, s) => n + ((s as Map<String, dynamic>)['points'] as List<dynamic>).length);
      }

      for (final mk in TenSecMistakes.all) {
        final src = TenSecMistakes.sourceOf[mk.key];
        expect(src, isNotNull, reason: mk.key);
        expect(src!.$2, lessThan(points(src.$1)), reason: '${mk.key}: point ${src.$2} of ${src.$1}');
        expect(mk.lessonPoint, lessThan(points('1.10')), reason: '${mk.key}: the mistakes book opens lesson 1.10');
      }
    });

    test('libraries: every check ≥ 2 right and ≥ 5 wrong, all within 1.3×', () {
      for (final c in TenSecChecks.all) {
        final wrong = tenSecTopics[c.topic]!.whyWrong;
        expectLibrary(c.id, c.whyRight, wrong);
        expectSameLength(c.id, [...c.whyRight, ...wrong]);
      }
      expectLibrary('coworker why', TenSecLines.coworkerWhyRight, TenSecLines.coworkerWhyWrong);
      expectSameLength('coworker why', [...TenSecLines.coworkerWhyRight, ...TenSecLines.coworkerWhyWrong]);
      final s = TenSecLines.coworker;
      expectLibrary('coworker deck', s.right, s.wrong);
      expectSameLength('coworker deck', [...s.right, ...s.wrong]);
    });

    test('a dealt reason deck: one right, three different options', () {
      final rng = math.Random(3);
      for (final c in TenSecChecks.all) {
        final opts = dealChoices(c.whyRight, tenSecTopics[c.topic]!.whyWrong, rng);
        expect(opts, hasLength(3));
        expect(opts.where((o) => o.correct), hasLength(1), reason: c.id);
        expect(opts.map((o) => o.textBn).toSet(), hasLength(3));
      }
    });

    test('every on-screen string: English digits and the house words', () {
      for (final l in _onScreenStrings()) {
        expect(l, isNot(matches(_bnDigit)), reason: '"$l": English digits on screen');
        for (final bad in ['ডোকেট', 'শাট ডাউন', 'পানি', 'গ্লাভ্স', 'বলতা', 'আর্দিং']) {
          expect(l, isNot(contains(bad)), reason: '"$l": "$bad"');
        }
      }
    });

    test('his lines are his recorded clips', () {
      for (final line in TenSecLines.coworker.recordedLines) {
        final clip = LearnVoice.resolve(line, rival: true);
        expect(clip, isNotNull, reason: 'rival clip for "$line"');
        expect(File('assets/$clip').lengthSync(), greaterThan(4000));
      }
    });
  });

  group('the deal', () {
    test('ten checks in the lesson\'s order, 4–6 safe, at least one deadly fault, plays differ', () {
      final seen = <String>{};
      var safeAtHim = 0, faultAtHim = 0;
      final safeCounts = <int>{};
      for (var s = 0; s < 400; s++) {
        final d = dealTenSec(math.Random(s));
        expect(d.checks.map((c) => c.topic), ScanTopic.values, reason: 'seed $s');
        final safe = d.checks.where((c) => c.isSafe).length;
        expect(safe, inInclusiveRange(kMinSafe, kMaxSafe), reason: 'seed $s');
        safeCounts.add(safe);
        expect(d.checks.where((c) => c.deadly), isNotEmpty, reason: 'seed $s: a deadly check every play');
        expect(d.coworkerRound, inInclusiveRange(2, 5), reason: 'seed $s');
        d.checks[d.coworkerRound].isSafe ? safeAtHim++ : faultAtHim++;
        seen.add(d.checks.map((c) => c.id).join(','));
      }
      expect(safeCounts, {4, 5, 6});
      expect(seen.length, greaterThan(300), reason: 'every play dealt fresh');
      expect(safeAtHim, greaterThan(40), reason: 'he comes on safe checks too');
      expect(faultAtHim, greaterThan(40), reason: 'he comes on faults too');
    });
  });

  group('TenSecRun', () {
    test('right calls: 100 and pass', () {
      final run = TenSecRun(dealTenSec(math.Random(42)));
      for (var i = 0; i < 10; i++) {
        expect(run.evaluate(run.current.isSafe), isNull);
        expect(run.caught, contains(run.current.caughtTag));
        run.advance();
      }
      expect(run.passed, isTrue);
      expect(run.percent, 100);
    });

    test('the shared Do mark: 100 − 15 per slip, pass at 55', () {
      final run = TenSecRun(dealTenSec(math.Random(1)));
      for (var i = 0; i < 10; i++) {
        run.advance();
      }
      run.slip();
      run.slip();
      expect(run.percent, 70);
      expect(run.passed, isTrue);
      run.slip();
      expect(run.percent, 55);
      expect(run.passed, isTrue, reason: 'pass ≥ 55 (the 3rd slip strikes out in the level first)');
      run.slip();
      expect(run.passed, isFalse);
    });

    test('STOP on a safe check is a slip; GO on a deadly fault ends the play', () {
      final d = dealTenSec(math.Random(_seedWhere((d) => d.checks.first.isSafe)));
      final run = TenSecRun(d);
      expect(run.evaluate(false), TenSecMistakes.safeStopped);
      expect(run.slips, 1);
      while (!run.current.deadly) {
        run.advance();
      }
      final mk = run.evaluate(true);
      expect(mk!.deadly, isTrue);
      expect(run.ended, isTrue);
      expect(run.passed, isFalse);
    });
  });

  group('the level', () {
    testWidgets('the card shows the lesson\'s question, never the answer', (t) async {
      final seed = _seedWhere((d) => !d.checks.first.isSafe && d.coworkerRound > 0);
      final d = dealTenSec(math.Random(seed));
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, _go), isTrue);
      final card = d.checks.first;
      expect(find.descendant(of: find.byType(ScanCard), matching: find.text(tenSecTopics[card.topic]!.askBn)), findsOneWidget);
      expect(find.text(card.caughtTag), findsNothing);
      expect(find.text(card.fault!.textBn), findsNothing);
      // English digits everywhere on screen.
      for (final e in find.byType(Text).evaluate()) {
        final w = e.widget as Text;
        final s = w.data ?? w.textSpan?.toPlainText() ?? '';
        expect(s, isNot(matches(_bnDigit)), reason: '"$s"');
      }
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('full play: right call and reason each time, he is refused and his check asked → pass, clear and stars saved', (t) async {
      final seed = _seedWhere((d) => true);
      final deal = dealTenSec(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 10; i++) {
        await _playRight(t, deal, i);
      }
      expect(await _pumpUntil(t, find.byType(LevelPassPanel), maxMs: 12000), isTrue);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThanOrEqualTo(2));
      expect(s.bestTimeMsByRung[_rung], greaterThan(0));
      expect(s.bestMarkByRung[_rung], 100);
      expect(find.text(TenSecLines.caughtCall), findsOneWidget, reason: 'the refusal is in "আজ যা ধরলেন"');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('listening to him is a slip, then the same check is asked', (t) async {
      final seed = _seedWhere((d) => d.coworkerRound == 2);
      final deal = dealTenSec(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 2; i++) {
        await _playRight(t, deal, i);
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      final wrong = _onScreen(TenSecLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, TenSecMistakes.mindRushed.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(await _pumpUntil(t, _go), isTrue, reason: 'his check is asked now');
      expect(find.byKey(const ValueKey('scan-card-2')), findsOneWidget);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he comes once');
      await _close(t, c);
    });

    testWidgets('GO on a deadly fault: the scene freezes first, then the card', (t) async {
      final seed = _seedWhere((d) => d.checks.first.deadly && d.coworkerRound > 0);
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, _go), isTrue);
      await t.tap(_go);
      await _pump(t, 600);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(ScanDeathView), findsOneWidget, reason: 'the consequence in colour');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.deadly, isTrue);
      expect(s.rungProgress[_rung], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('three slips strike out', (t) async {
      final seed = _seedWhere((d) => d.coworkerRound >= 3 && d.checks.take(3).every((c) => !c.deadly));
      final deal = dealTenSec(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        expect(await _pumpUntil(t, _go), isTrue, reason: 'check $i');
        await t.tap(deal.checks[i].isSafe ? _stop : _go);
        await _pump(t, 600);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget, reason: 'slip $i shows its card');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((e) => e.key).toSet(), {for (final ch in deal.checks.take(3)) (ch.fault ?? TenSecMistakes.safeStopped).key});
      expect(s.rungProgress[_rung], isNot('cleared'));
      expect(s.bestMarkByRung[_rung] ?? 0, lessThan(100));
      await _close(t, c);
    });
  });
}
