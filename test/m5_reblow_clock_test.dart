// Lesson 5.4 (ফিউজ বারবার উড়ে যাওয়া: অস্থায়ী বনাম স্থায়ী ফল্ট), কাজ 2
// "লাগাতেই, না পরে?": the rules (read today's page; a blank page needs a
// look and a re-fit first — the permanent fault blasts, the transient one
// holds and the clock runs it out; re-fit after an instant blast = deadly,
// after a delayed blow = slip; a stamp needs evidence; the permanent fault's
// order deck and the transient fault's "where to look" pictures), the deal,
// the libraries, and the level in the shell: the guide first, a full clean
// play with the coworker refused, a slip card that keeps the DTR, three
// slips, the deadly freeze (re-fit on a blast page; listening to him), the
// order deck waiting for him, and the gesture hand (how, never what).
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
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m5_reblow_clock.dart';
import 'package:slm_flutter/features/game/m5_reblow_clock_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '5.4/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '5.4',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m5ReblowPacks['do_5_4_b']!;

/// The art may not be in the test bundle yet: read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
  }
}

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

final _do = find.byKey(const ValueKey('reblow-do'));
final _dial = find.byKey(const ValueKey('reblow-clock'));
final _look = find.byKey(const ValueKey('reblow-check'));
final _today = find.byKey(const ValueKey('reblow-today'));
Finder _stampF(M5ReblowKind k) => find.byKey(ValueKey('reblow-stamp-${k.name}'));
Finder _spotF(M5ReblowSpot s) => find.byKey(ValueKey('reblow-spot-${s.name}'));

M5ReblowKind _other(M5ReblowKind k) => k == M5ReblowKind.permanent ? M5ReblowKind.transient : M5ReblowKind.permanent;

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

Future<void> _hold(WidgetTester t, Finder f, {int ms = 1200}) async {
  final g = await t.startGesture(t.getCenter(f));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 150);
}

Future<void> _stamp(WidgetTester t, M5ReblowKind k) async {
  final from = t.getCenter(_stampF(k));
  final to = t.getCenter(_today);
  final g = await t.startGesture(from);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)!);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, 400);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M5ReblowPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 3000);
}

/// A blank page: look, re-fit, and see what the fuse does.
Future<void> _bringEvidence(WidgetTester t, M5ReblowCase c) async {
  await t.tap(_look);
  await _pump(t, 1500);
  await _hold(t, _do);
  if (c.kind == M5ReblowKind.permanent) {
    await _pump(t, 2000);
  } else {
    await _pump(t, 1000);
    expect(_do, findsNothing, reason: 'the clock is the only control');
    await _hold(t, _dial);
    await _pump(t, 1800);
  }
}

/// One DTR, right all the way (the coworker refused on the permanent one).
Future<void> _playCase(WidgetTester t, M5ReblowCase c) async {
  if (c.page == M5ReblowLog.fresh) await _bringEvidence(t, c);
  await _stamp(t, c.kind);
  await _reason(t, M5ReblowLines.stampWhy(c.kind));
  if (c.kind == M5ReblowKind.permanent) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, M5ReblowLines.coworker.right);
    await _pump(t, 2600);
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the order deck');
    await _pump(t, 600);
    await _pickRight(t, M5ReblowLines.orderRight);
    await _pump(t, 600);
    await _reason(t, M5ReblowLines.whyPatrol);
  } else {
    expect(await _pumpUntil(t, _spotF(c.rightSpot)), isTrue, reason: 'the picture deck');
    await _pump(t, 600);
    await t.tap(_spotF(c.rightSpot));
    await _pump(t, 900);
    await _reason(t, M5ReblowLines.whySpot);
  }
  await _pump(t, 1500);
}

int _seedWhere(bool Function(M5ReblowDeal d) f) => [for (var s = 0; s < 500; s++) s].firstWhere((s) => f(m5ReblowDeal(math.Random(s))));

M5ReblowCase _case(M5ReblowKind kind, M5ReblowLog page, {M5ReblowSpot right = M5ReblowSpot.sagHeavy}) => M5ReblowCase(
      kind: kind,
      page: page,
      held: kind == M5ReblowKind.permanent ? M5ReblowLines.held0 : '3 ঘ 30 মি',
      weather: M5ReblowWeather.wind,
      note: kind == M5ReblowKind.permanent ? M5ReblowLines.blastNotes.first : M5ReblowLines.weatherNote(M5ReblowWeather.wind),
      phase: 1,
      dtr: 17,
      village: 'শালবনি',
      time: 0,
      spots: [M5ReblowSpot.treeSafe, right, M5ReblowSpot.sagNormal],
      spotPoles: const [3, 7, 12],
      older: const [
        M5ReblowOldPage(5, ['a', 'b']),
        M5ReblowOldPage(20, ['c', 'd']),
      ],
    );

M5ReblowRun _run(M5ReblowCase a, M5ReblowCase b) => M5ReblowRun(M5ReblowDeal(cases: [a, b], stampsSwapped: false));

void main() {
  group('rules', () {
    test('deals: one permanent + one transient; a written page in ≥ 50 % of plays; pictures with one right; plays differ', () {
      final seen = <String>{};
      var history = 0;
      for (var s = 0; s < 200; s++) {
        final d = m5ReblowDeal(math.Random(s));
        expect(d.cases, hasLength(2));
        expect(d.cases.map((c) => c.kind).toSet(), M5ReblowKind.values.toSet());
        if (d.hasHistory) history++;
        for (final c in d.cases) {
          expect(c.phase, inInclusiveRange(0, 2));
          if (c.kind == M5ReblowKind.permanent) {
            expect(c.held, M5ReblowLines.held0);
            expect(M5ReblowLines.blastNotes, contains(c.note));
          } else {
            expect(M5ReblowLines.heldTimes, contains(c.held));
            expect(c.note, M5ReblowLines.weatherNote(c.weather));
          }
          expect(c.spots, hasLength(3));
          expect(c.spots.toSet(), hasLength(3));
          expect(c.spots.where(m5ReblowSpotRight.contains), hasLength(1));
          expect(c.spotPoles.toSet(), hasLength(3));
          expect(c.older, hasLength(2));
        }
        expect(d.cases[0].dtr, isNot(d.cases[1].dtr));
        expect(d.cases[0].village, isNot(d.cases[1].village));
        seen.add([
          for (final c in d.cases) '${c.kind.name}/${c.page.name}/${c.held}/${c.note}/${c.phase}/${c.spots.map((x) => x.name).join(',')}',
          d.stampsSwapped,
        ].join('|'));
      }
      expect(history / 200, greaterThanOrEqualTo(0.5));
      expect(seen.length, greaterThan(150));
    });

    test('permanent, blank page: a stamp needs evidence; re-fit needs the look; then it blasts and a second re-fit is deadly', () {
      final r = _run(_case(M5ReblowKind.permanent, M5ReblowLog.fresh), _case(M5ReblowKind.transient, M5ReblowLog.fresh));
      expect(r.stamp(M5ReblowKind.permanent), M5ReblowMistakes.noEvidence);
      expect(r.refit(), M5ReblowMistakes.noCheck);
      expect(r.refitted, isFalse);
      r.check();
      expect(r.refit(), isNull);
      expect(r.evidence, isTrue);
      expect(r.stage, M5ReblowStage.read);
      final m = r.refit();
      expect(m, M5ReblowMistakes.refitBlast, reason: 'just seen the blast');
      expect(m!.deadly, isTrue);
      expect(r.ended, isTrue);
      expect(r.slips, 2);
    });

    test('permanent: a written blast page — re-fit is deadly at once; the wrong stamp is a slip; the orders', () {
      final a = _run(_case(M5ReblowKind.permanent, M5ReblowLog.history), _case(M5ReblowKind.transient, M5ReblowLog.fresh));
      expect(a.refit(), M5ReblowMistakes.refitBlast);
      final b = _run(_case(M5ReblowKind.permanent, M5ReblowLog.history), _case(M5ReblowKind.transient, M5ReblowLog.fresh));
      expect(b.stamp(M5ReblowKind.transient), M5ReblowMistakes.stampWasPermanent);
      expect(b.stamp(M5ReblowKind.permanent), isNull);
      expect(b.stage, M5ReblowStage.follow);
      expect(b.refit(), isNull, reason: 'stamped: the DO is done');
      expect(b.caught, contains(M5ReblowLines.caughtPermanent));
      for (final w in M5ReblowLines.orderWrong) {
        final c = _run(_case(M5ReblowKind.permanent, M5ReblowLog.history), _case(M5ReblowKind.transient, M5ReblowLog.fresh))..stamp(M5ReblowKind.permanent);
        final m = c.order(w);
        expect(m?.deadly, isTrue, reason: w);
        expect(m, M5ReblowLines.orderKillsFuse(w) ? M5ReblowMistakes.thickWire : M5ReblowMistakes.orderRecharge, reason: w);
      }
      expect(b.order(M5ReblowLines.orderRight.first), isNull);
      expect(b.followDone, isTrue);
      expect(b.caught, contains(M5ReblowLines.caughtPatrol));
      expect(b.slips, 1);
    });

    test('transient, blank page: look, re-fit holds; the clock runs it out; re-fit after = slip; the pictures', () {
      final r = _run(_case(M5ReblowKind.transient, M5ReblowLog.fresh, right: M5ReblowSpot.branchClose), _case(M5ReblowKind.permanent, M5ReblowLog.history));
      r.check();
      expect(r.refit(), isNull);
      expect(r.stage, M5ReblowStage.holding);
      expect(r.evidence, isFalse);
      expect(r.stamp(M5ReblowKind.transient), isNull, reason: 'no stamp while the line holds');
      expect(r.stamped, isNull);
      r.runClock();
      expect(r.stage, M5ReblowStage.read);
      expect(r.evidence, isTrue);
      expect(r.refit(), M5ReblowMistakes.refitDelayed);
      expect(r.ended, isFalse);
      expect(r.stamp(M5ReblowKind.permanent), M5ReblowMistakes.stampWasTransient);
      expect(r.stamp(M5ReblowKind.transient), isNull);
      expect(r.caught, containsAll([M5ReblowLines.caughtCheck, M5ReblowLines.caughtTransient]));
      expect(r.spot(M5ReblowSpot.treeSafe), M5ReblowMistakes.wrongSpot);
      expect(r.spot(M5ReblowSpot.branchClose), isNull);
      expect(r.followDone, isTrue);
      expect(r.slips, 3);
      r.next();
      expect(r.index, 1);
      expect(r.stage, M5ReblowStage.read);
      expect(r.checked, isFalse);
      expect(r.evidence, isTrue, reason: 'the second page is written');
      expect(r.refit(), M5ReblowMistakes.refitBlast);
    });

    test('transient, written page: re-fit before checking the sag and branches = slip; the play passes on 0–2 slips', () {
      final r = _run(_case(M5ReblowKind.transient, M5ReblowLog.history), _case(M5ReblowKind.permanent, M5ReblowLog.history));
      expect(r.refit(), M5ReblowMistakes.refitDelayed);
      expect(r.stamp(M5ReblowKind.transient), isNull);
      expect(r.spot(M5ReblowSpot.sagHeavy), isNull);
      r.next();
      expect(r.stamp(M5ReblowKind.permanent), isNull);
      expect(r.order(M5ReblowLines.orderRight.last), isNull);
      r.next();
      expect(r.done, isTrue);
      expect(r.percent, 85);
      expect(r.passed, isTrue);
    });

    test('English digits only; every mistake has its picture; the deadly four; keys unique; lesson points 0–3', () {
      final all = <String>[
        M5ReblowLines.intro,
        ...M5ReblowLines.tasks,
        M5ReblowLines.askNext,
        ...M5ReblowLines.allWhyRight,
        ...M5ReblowLines.myths,
        ...M5ReblowLines.orderRight,
        ...M5ReblowLines.orderWrong,
        ...M5ReblowLines.heldTimes,
        ...M5ReblowLines.blastNotes,
        ...M5ReblowLines.times,
        ...M5ReblowLines.olderNotes,
        for (final w in M5ReblowWeather.values) M5ReblowLines.weatherNote(w),
        ...M5ReblowLines.coworker.recordedLines,
        ...M5ReblowLines.coworker.right,
        ...M5ReblowLines.coworker.wrong,
        ...M5ReblowLines.coworker.asks,
        for (final m in M5ReblowMistakes.all) m.textBn,
        M5ReblowLines.allSet,
        M5ReblowLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M5ReblowMistakes.all.where((m) => m.deadly).toSet(),
          {M5ReblowMistakes.refitBlast, M5ReblowMistakes.faultBurning, M5ReblowMistakes.orderRecharge, M5ReblowMistakes.thickWire});
      expect(M5ReblowMistakes.all.map((m) => m.key).toSet(), hasLength(M5ReblowMistakes.all.length));
      final arts = <String>{};
      for (final m in M5ReblowMistakes.all) {
        expect(m.key, startsWith('5.4/m5_reblow_clock/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        arts.add(m.art.split('/').last);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      // Every picture in the folder is used (no unused assets).
      final files = Directory('assets/game/art/m5_reblow_clock').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, arts);
      expect(m5ReblowPacks.keys, ['do_5_4_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; the coworker says the lesson myth word for word', () {
      expectSameLength('why', [...M5ReblowLines.allWhyRight, ...M5ReblowLines.myths]);
      expect(M5ReblowLines.myths.toSet().intersection(M5ReblowLines.allWhyRight.toSet()), isEmpty);
      for (final k in M5ReblowKind.values) {
        for (final (q, right) in [(M5ReblowLines.stampWhyQ(k), M5ReblowLines.stampWhy(k)), (M5ReblowLines.followWhyQ(k), M5ReblowLines.followWhy(k))]) {
          expectLibrary(q, right, M5ReblowLines.myths);
          for (var s = 0; s < 10; s++) {
            final deal = dealChoices(right, M5ReblowLines.myths, math.Random(s));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
      }
      expect(M5ReblowLines.stampWhyQ(M5ReblowKind.permanent), 'কেন স্থায়ী ফল্ট?');
      expect(M5ReblowLines.stampWhyQ(M5ReblowKind.transient), 'কেন অস্থায়ী ফল্ট?');
      expect(M5ReblowLines.followWhyQ(M5ReblowKind.permanent), 'কেন আবার চার্জ না করে পেট্রোলিং?');
      expect(M5ReblowLines.followWhyQ(M5ReblowKind.transient), 'কেন এই জায়গাগুলো দেখলেন?');
      expectSameLength('order', [...M5ReblowLines.orderRight, ...M5ReblowLines.orderWrong]);
      expectLibrary('order', M5ReblowLines.orderRight, M5ReblowLines.orderWrong);
      expect(M5ReblowLines.orderWrong.where(M5ReblowLines.orderKillsFuse), hasLength(2));
      final cw = M5ReblowLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.right, contains('না — এটা ফল্ট বার্নিং, কঠোরভাবে নিষিদ্ধ। আগে পেট্রোলিং।'));
      expect(cw.asks, contains('কী করবেন?'));
      // Lesson 5.4, myth 1, word for word. It keeps the lesson's code points
      // (precomposed য় U+09DF) while the file's other strings use য + ়: copy
      // the rival clip key from M5ReblowLines.coworker.line, never retype it.
      final lessons = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
      final l54 = lessons.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '5.4');
      final myth = (((l54['content'] as Map)['myth_buster'] as Map)['myths'] as List).first['myth'] as String;
      expect(cw.line, myth);
    });

    test('spot cards: every span looks different, so no deal shows two cards alike', () {
      expect(M5ReblowSpot.values.map(m5ReblowSpotLook).toSet(), hasLength(M5ReblowSpot.values.length));
      for (var s = 0; s < 500; s++) {
        for (final c in m5ReblowDeal(math.Random(s)).cases) {
          expect(c.spots.map(m5ReblowSpotLook).toSet(), hasLength(3), reason: 'seed $s: ${c.spots}');
        }
      }
    });

    test('rival lines: his exit line has its clip; his push is new (listed for recording)', () {
      final cw = M5ReblowLines.coworker;
      expect(cw.recordedLines, [cw.line, cw.exitLine]);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      // The push has no clip yet: it plays silent with its caption held (the
      // director records it with tool/rival_clip.py and lists it in the dump test).
      expect(cw.line, isNotEmpty);
    });

    test('controls do not overlap and stay on the 360-wide scene, below the header', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 24.0]) {
          final g = M5ReblowGeo.forScene(h, inset);
          for (var phase = 0; phase < 3; phase++) {
            final rects = [g.doHit(phase), g.log, g.stamp(0), g.stamp(1), g.check];
            for (final r in rects) {
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(360));
              expect(r.top, greaterThan(110), reason: 'below the header');
              expect(r.bottom, lessThanOrEqualTo(h - inset * 0.5), reason: 'above the inset');
            }
            for (var i = 0; i < rects.length; i++) {
              for (var j = i + 1; j < rects.length; j++) {
                final x = rects[i].intersect(rects[j]);
                expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h phase $phase: $i/$j');
              }
            }
            expect(g.log.contains(g.dial.center), isTrue);
            expect(g.log.contains(g.today.center), isTrue);
            expect(g.trainee.right, lessThan(g.doHit(phase).left + 4), reason: 'he stands to the side of the barrel');
            // Ruling M5-8: the fuse-rating tag hangs on the DO arm, clear of
            // every control and the trainee.
            final tag = g.ratingTag;
            expect(tag.left, greaterThanOrEqualTo(0));
            expect(tag.top, greaterThan(110));
            expect(tag.right, lessThan(g.armEnd.dx));
            for (final r in [...rects, g.trainee]) {
              final x = tag.intersect(r);
              expect(x.width <= 0 || x.height <= 0, isTrue, reason: 'h $h: the rating tag over $r');
            }
          }
        }
      }
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('the guide comes first: a tap does not skip him; then the DO, the stamps and the look', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(home: M5ReblowPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_do, findsOneWidget);
      expect(_stampF(M5ReblowKind.permanent), findsOneWidget);
      expect(_stampF(M5ReblowKind.transient), findsOneWidget);
      expect(_look, findsOneWidget);
      // The stamps look alike (same size), only the word differs.
      expect(t.getSize(_stampF(M5ReblowKind.permanent)), t.getSize(_stampF(M5ReblowKind.transient)));
      // Ruling M5-8: the fuse's rating tag hangs on the DO arm.
      expect(find.descendant(of: find.byKey(const ValueKey('rating-tag')), matching: find.text(M5ReblowLines.ratingTag)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M5ReblowLines.askRead)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('older pages swipe in (noise) and back; a stamp on an older page does nothing', (t) async {
      final seed = _seedWhere((d) => d.cases[0].page == M5ReblowLog.history);
      final deal = m5ReblowDeal(math.Random(seed));
      final c = await _open(t, seed);
      expect(find.text(deal.cases[0].note), findsOneWidget);
      await t.drag(find.byKey(const ValueKey('reblow-log')), const Offset(120, 0));
      await _pump(t, 400);
      expect(find.text(deal.cases[0].note), findsNothing);
      expect(find.text(M5ReblowLines.daysAgo(deal.cases[0].older.first.daysAgo)), findsOneWidget);
      await t.drag(find.byKey(const ValueKey('reblow-log')), const Offset(-120, 0));
      await _pump(t, 400);
      expect(find.text(deal.cases[0].note), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    for (final (name, pick) in [
      ('blank pages', (M5ReblowDeal d) => d.cases.every((c) => c.page == M5ReblowLog.fresh)),
      ('written pages, transient first', (M5ReblowDeal d) => d.cases.every((c) => c.page == M5ReblowLog.history) && d.cases[0].kind == M5ReblowKind.transient),
    ]) {
      testWidgets('flow ($name): read, stamp, refuse him, patrol, look at the spans; right reasons → pass', (t) async {
        final seed = _seedWhere(pick);
        final deal = m5ReblowDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (final k in deal.cases) {
          await _playCase(t, k);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['5.4/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['5.4/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M5ReblowLines.caughtCall), findsOneWidget);
        expect(find.text(M5ReblowLines.caughtPatrol), findsOneWidget);
        expect(find.text(M5ReblowLines.caughtSpot), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (stamp on a blank page) shows its card; the same DTR goes on after it', (t) async {
      final seed = _seedWhere((d) => d.cases[0].page == M5ReblowLog.fresh);
      final c = await _open(t, seed);
      await _stamp(t, M5ReblowKind.permanent);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M5ReblowMistakes.noEvidence.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_do, findsOneWidget, reason: 'the same DTR');
      expect(c.read(gameSaveProvider).mistakes.single.key, M5ReblowMistakes.noEvidence.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => true);
      final deal = m5ReblowDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        // Blank page: no evidence; written page: the wrong stamp.
        await _stamp(t, _other(deal.cases[0].kind));
        await _pump(t, 600);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('re-fit on a written blast page: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _seedWhere((d) => d.cases[0].page == M5ReblowLog.history && d.cases[0].kind == M5ReblowKind.permanent);
      final c = await _open(t, seed);
      await _hold(t, _do);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5ReblowMistakes.refitBlast.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the order deck waits for him; listening to him = deadly: freeze, then the card', (t) async {
      final seed = _seedWhere((d) => d.cases[0].page == M5ReblowLog.history && d.cases[0].kind == M5ReblowKind.permanent);
      final c = await _open(t, seed);
      await _stamp(t, M5ReblowKind.permanent);
      await _reason(t, M5ReblowLines.whyPermanent);
      expect(find.byKey(const ValueKey('order-deck-0')), findsNothing, reason: 'no orders before he comes');
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      expect(find.byKey(const ValueKey('order-deck-0')), findsNothing);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5ReblowLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M5ReblowMistakes.faultBurning.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a wrong order (thick wire / another charge) is deadly', (t) async {
      final seed = _seedWhere((d) => d.cases[0].page == M5ReblowLog.history && d.cases[0].kind == M5ReblowKind.permanent);
      final c = await _open(t, seed);
      await _stamp(t, M5ReblowKind.permanent);
      await _reason(t, M5ReblowLines.whyPermanent);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M5ReblowLines.coworker.right);
      await _pump(t, 2600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M5ReblowLines.orderWrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a wrong picture is a slip; the deck stays for the right one', (t) async {
      final seed = _seedWhere((d) => d.cases[0].page == M5ReblowLog.history && d.cases[0].kind == M5ReblowKind.transient);
      final deal = m5ReblowDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _stamp(t, M5ReblowKind.transient);
      await _reason(t, M5ReblowLines.whyTransient);
      final k = deal.cases[0];
      final decoy = k.spots.firstWhere((s) => !m5ReblowSpotRight.contains(s));
      expect(await _pumpUntil(t, _spotF(decoy)), isTrue);
      await _pump(t, 600);
      await t.tap(_spotF(decoy));
      await _pump(t, 800);
      expect(find.text(M5ReblowMistakes.wrongSpot.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await t.tap(_spotF(k.rightSpot));
      await _pump(t, 900);
      await _reason(t, M5ReblowLines.whySpot);
      expect(c.read(gameSaveProvider).mistakes.single.key, M5ReblowMistakes.wrongSpot.key);
      await _close(t, c);
    });

    testWidgets('gesture hand: a swipe on the logbook, then a sweep over DO + stamps + look; a hold on the clock; a sweep over the pictures', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.cases[0].page == M5ReblowLog.fresh && d.cases[0].kind == M5ReblowKind.transient);
      final deal = m5ReblowDeal(math.Random(seed));
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while reading');
      expect(scene().debugOptions, isEmpty, reason: 'first a page-flip swipe');
      for (var ms = 0; ms < 40000 && !(scene().showing && scene().debugOptions.isNotEmpty); ms += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(scene().showing, isTrue, reason: 'the next hint');
      expect(scene().debugOptions, hasLength(4), reason: 'the DO, both stamps, the look — all alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // Look and re-fit: the line holds, the clock is the only control.
      await t.tap(_look);
      await _pump(t, 1500);
      await _hold(t, _do);
      await _pump(t, 1000);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle while the line holds');
      expect(scene().debugOptions, isEmpty, reason: 'a hold on the one control');
      await _hold(t, _dial);
      await _pump(t, 1800);
      await _stamp(t, M5ReblowKind.transient);
      await _reason(t, M5ReblowLines.whyTransient);
      expect(await _pumpUntil(t, _spotF(deal.cases[0].rightSpot)), isTrue);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the pictures');
      expect(scene().debugOptions, hasLength(3), reason: 'every picture');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
