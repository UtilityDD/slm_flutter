// Lesson 3.2, কাজ 1 (কোথায় কোন ইনসুলেটর): rules of the poles (pin where the
// line runs straight, shackle where an LT line ends, a disc string where an
// HT line ends — one disc for 11 kV, three for 33 kV; chipped and cracked ones
// are slips), the close look (a crack shows only where the hand has been, a
// chip only on the back), deal variety, fair reason libraries, and the level
// in the shell (idle perf; the guide first; a full clean flow with the board,
// a chipped one set aside, the reasons and the coworker; slip cards; three
// slips fail).
import 'dart:async';
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_insulator_pick.dart';
import 'package:slm_flutter/features/game/m3_insulator_pick_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

typedef _L = M3InsulatorPickLines;
typedef _M = M3InsulatorPickMistakes;
typedef _K = M3InsulatorPickKind;
typedef _S = M3InsulatorPickSite;
typedef _F = M3InsulatorPickFlaw;
typedef _Item = M3InsulatorPickItem;
typedef _Round = M3InsulatorPickRound;
typedef _Spot = M3InsulatorPickSpot;

const _ctx = LevelContext(
  rungId: '3.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.2',
  lessonTitleBn: '',
  ladderStep: 3,
  doIndex: 1,
  doCount: 2,
);

/// Serves this level's mistake art from disk (its folder joins pubspec when
/// the director wires the level), everything else from the app bundle.
class _ArtBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_insulator_pick/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(Uint8List.fromList(b).buffer);
    }
    return rootBundle.load(key);
  }
}

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) => MaterialApp(
      navigatorKey: nav,
      builder: (context, child) => DefaultAssetBundle(bundle: _ArtBundle(), child: child!),
      home: home,
    );

_Item _right(_Round r) => r.items.firstWhere(r.spot.fits);
_Item _kind(_Round r, _K k) => r.items.firstWhere((x) => x.kind == k && !r.spot.suits(x));

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The first seed whose coworker comes on pole [round].
int _seedCalling(int round) {
  for (var s = 0;; s++) {
    if (m3InsulatorPickDeal(math.Random(s)).callRound == round) return s;
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

const _spots = [
  _Spot(site: _S.straightHt, kv: 11),
  _Spot(site: _S.straightHt, kv: 33),
  _Spot(site: _S.endLt),
  _Spot(site: _S.endHt, kv: 11),
  _Spot(site: _S.endHt, kv: 33),
];

void main() {
  group('rules', () {
    test('every deal: straight HT → pin, LT end → shackle, HT end → disc string by kV; one right each; a faulty twin each', () {
      for (var s = 0; s < 80; s++) {
        final d = m3InsulatorPickDeal(math.Random(s));
        expect(d.rounds.map((r) => r.spot.site), [_S.straightHt, _S.endLt, _S.endHt]);
        for (final r in d.rounds) {
          expect(r.items.where(r.spot.fits).length, 1);
          expect(r.twin, isNotNull, reason: 'a chipped or cracked one of the right kind');
          expect(r.items.where((x) => x.flaw != _F.none).length, 1);
          expect(r.items.map((x) => x.id).toSet().length, r.items.length);
        }
        expect(_right(d.rounds[0]).kind, _K.pin);
        expect(d.rounds[0].twin!.flaw, _F.chip, reason: 'the myth: a chipped corner');
        expect(_right(d.rounds[1]).kind, _K.shackle);
        final end = d.rounds[2];
        expect(_right(end).kind, _K.disc);
        expect(_right(end).discs, end.spot.kv == 33 ? 3 : 1, reason: 'lesson: 1 disc = 11 kV, 3 = 33 kV');
        expect(end.twin!.flaw, _F.crack, reason: 'lesson: a hairline crack on a disc');
        expect(end.items.any((x) => x.kind == _K.pin), isTrue, reason: 'what the coworker pushes');
        if (end.spot.kv == 33) expect(end.items.any((x) => x.kind == _K.disc && x.discs == 1), isTrue, reason: 'count the discs');
        expect(end.items.any((x) => x.kind == _K.disc && x.discs > end.spot.discsNeeded), isFalse, reason: 'too many discs is not a lesson fault');
        for (final r in d.rounds) {
          for (final x in r.items) {
            if (x.kind == _K.disc) expect(x.discs, anyOf(1, 3));
          }
        }
        expect(d.rounds[0].items.any((x) => x.kind == _K.disc), isFalse, reason: 'no disc on the straight run (the lesson gives pin there)');
      }
    });

    test('a clean play: pin, shackle, the disc string', () {
      final run = M3InsulatorPickRun(m3InsulatorPickDeal(math.Random(3)));
      for (var i = 0; i < 3; i++) {
        final r = run.current;
        expect(run.take(_right(r)).verdict, M3InsulatorPickVerdict.right);
        expect(run.shown, isTrue);
        expect(run.take(r.twin!).mistake, isNull, reason: 'nothing more once fitted');
        expect(run.round, i, reason: 'the pole moves on only after the reason');
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, contains(_L.caughtMatch));
    });

    test('the wrong kind at each spot: its own slip, and it goes aside', () {
      final cases = <(_Spot, _Item, DoMistake)>[
        (_spots[1], const _Item(id: 'a', kind: _K.shackle), _M.shackleOnStraight),
        (_spots[2], const _Item(id: 'a', kind: _K.pin), _M.pinAtEnd),
        (_spots[2], const _Item(id: 'a', kind: _K.disc, discs: 1), _M.discOnLt),
        (_spots[3], const _Item(id: 'a', kind: _K.pin), _M.pinAtEnd),
        (_spots[4], const _Item(id: 'a', kind: _K.shackle), _M.shackleOnHt),
        (_spots[4], const _Item(id: 'a', kind: _K.disc, discs: 1), _M.fewDiscs),
      ];
      for (final (s, i, m) in cases) {
        expect(_M.wrongFor(s, i), m, reason: '${s.site} ${i.kind} ${i.discs}');
      }
      for (final s in _spots) {
        expect(_M.wrongFor(s, _Item(id: 'x', kind: s.rightKind, discs: s.discsNeeded)), isNull);
      }

      final run = M3InsulatorPickRun(m3InsulatorPickDeal(math.Random(5)))..round = 2;
      final r = run.current;
      expect(run.take(_kind(r, _K.pin)).mistake, _M.pinAtEnd);
      expect(run.take(_kind(r, _K.shackle)).mistake, _M.shackleOnHt);
      expect(run.take(r.twin!).mistake, _M.crack);
      expect(run.rejected.length, 3);
      expect(run.slips, 3);
      expect(run.take(r.twin!).mistake, isNull, reason: 'already aside');
      run.round = 0;
      run.rejected.clear();
      expect(run.take(run.current.twin!).mistake, _M.chip);
    });

    test('putting back: a faulty one whose fault was found goes aside for free; anything else back on the tarp', () {
      final run = M3InsulatorPickRun(m3InsulatorPickDeal(math.Random(5)))..round = 1;
      final r = run.current;
      final twin = r.twin!;
      expect(run.putBack(_right(r)), isFalse);
      expect(run.putBack(_kind(r, _K.pin)), isFalse);
      expect(run.putBack(twin), isFalse, reason: 'not looked for: putting back gives nothing away');
      run.spot(_right(r));
      expect(run.spotted, isEmpty, reason: 'a sound one has nothing to find');
      run.spot(twin);
      expect(run.putBack(twin), isTrue);
      expect(run.slips, 0);
      expect(run.caught, contains(_L.caughtFlaw));
      run.take(_right(r));
      run.next();
      expect(run.spotted, isEmpty, reason: 'a fresh pole');
      expect(run.fitted, isNull);
    });

    test('the coworker pushes only one still on the tarp: the chipped one, or a pin where the line ends', () {
      final d = m3InsulatorPickDeal(math.Random(1));
      final straight = d.rounds[0];
      expect(m3InsulatorPickPushFor(straight, {}, preferChip: false), M3InsulatorPickPush.chip, reason: 'no pin push on a straight run');
      expect(m3InsulatorPickPushed(straight, {}, M3InsulatorPickPush.pin), isNull);
      expect(m3InsulatorPickPushFor(straight, {straight.twin!.id}, preferChip: true), isNull);
      final end = d.rounds[2];
      expect(m3InsulatorPickPushFor(end, {}, preferChip: true), M3InsulatorPickPush.pin, reason: 'a cracked string is no chip');
      expect(m3InsulatorPickPushed(end, {}, M3InsulatorPickPush.pin)!.kind, _K.pin);
      expect(m3InsulatorPickPushFor(end, {_kind(end, _K.pin).id}, preferChip: true), isNull);
      const lt = _Round(spot: _Spot(site: _S.endLt), items: [
        _Item(id: 'a', kind: _K.shackle),
        _Item(id: 'b', kind: _K.shackle, flaw: _F.chip),
        _Item(id: 'c', kind: _K.pin),
      ]);
      expect(m3InsulatorPickPushFor(lt, {}, preferChip: true), M3InsulatorPickPush.chip);
      expect(m3InsulatorPickPushFor(lt, {}, preferChip: false), M3InsulatorPickPush.pin);
      expect(m3InsulatorPickPushFor(lt, {'c'}, preferChip: false), M3InsulatorPickPush.chip);
      expect(_L.coworker(M3InsulatorPickPush.pin, _S.endHt), _L.coworkerPinDisc);
      expect(_L.coworker(M3InsulatorPickPush.pin, _S.endLt), _L.coworkerPinShackle);
      expect(_L.coworker(M3InsulatorPickPush.chip, _S.endHt), _L.coworkerChip);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) m3InsulatorPickDeal(math.Random(s))];
      expect(deals.map((d) => d.rounds[0].spot.kv).toSet(), {11, 33});
      expect(deals.map((d) => d.rounds[2].spot.kv).toSet(), {11, 33});
      expect(deals.map((d) => d.rounds[1].twin!.flaw).toSet(), {_F.chip, _F.crack});
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.callChip).toSet(), {true, false});
      for (var i = 0; i < 3; i++) {
        expect(deals.map((d) => d.rounds[i].items.indexWhere(d.rounds[i].spot.fits)).toSet().length, greaterThan(2));
      }
    });

    test('the close look: a crack shows only where the hand has been; the board reads the line', () {
      for (final k in _K.values) {
        for (final n in k == _K.disc ? const [1, 3] : const [0]) {
          expect(M3InsulatorPickItemPainter.crackSeen(k, n, {}), isFalse);
          expect(M3InsulatorPickItemPainter.crackSeen(k, n, {0, 1, 2}), isFalse);
          expect(M3InsulatorPickItemPainter.crackSeen(k, n, {m3InsulatorPickBin(M3InsulatorPickItemPainter.crackU(k, n))}), isTrue);
          expect(M3InsulatorPickItemPainter.crackSeen(k, n, null), isTrue);
          final u = M3InsulatorPickItemPainter.crackU(k, n);
          expect(u, inInclusiveRange(0.25, 0.75), reason: 'on the porcelain, not the iron');
        }
      }
      expect(_spots[1].plate, '33 kV');
      expect(_spots[2].plate, '440 V');
      expect(_spots[3].discsNeeded, 1);
      expect(_spots[4].discsNeeded, 3);
    });

    test('reason and choice libraries: same length, big enough, fit the pole; his exit line is recorded; the mistakes book', () {
      expectSameLength('pack', [for (final s in _spots) ...[..._L.packRight(s), ..._L.packWrong(s)]]);
      for (final s in _spots) {
        expectLibrary('pack ${s.site.name} ${s.kv}', _L.packRight(s), _L.packWrong(s));
        for (final x in _L.packRight(s)) {
          expect(_L.packWrong(s), isNot(contains(x)));
        }
        for (final o in _spots) {
          if (o.rightKind != s.rightKind || (s.rightKind == _K.disc && o.discsNeeded != s.discsNeeded)) {
            expect(_L.packRight(s), isNot(contains(_L.packRight(o).first)), reason: 'each spot its own rule');
          }
        }
      }
      for (final c in [_L.coworkerChip, _L.coworkerPinShackle, _L.coworkerPinDisc]) {
        expectSameLength('choice ${c.line}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${c.line}', c.right, c.wrong);
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull, reason: c.exitLine);
        expect(_L.newRivalLines, contains(c.line), reason: 'his new push is listed for recording');
      }
      // Lesson 3.2's points: 1 = insulator, 2 = pin, 3 = shackle, 4 = disc.
      final keys = <String>{};
      for (final m in _M.all) {
        expect(m.deadly, isFalse);
        expect(m.key, startsWith('3.2/m3_insulator_pick/'));
        expect(keys.add(m.key), isTrue, reason: 'unique ${m.key}');
        expect(m.lessonPoint, inInclusiveRange(1, 4));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      for (final s in _spots) {
        for (final k in _K.values) {
          for (final n in k == _K.disc ? const [1, 3] : const [0]) {
            final m = _M.wrongFor(s, _Item(id: 'x', kind: k, discs: n));
            if (m != null) expect(_M.all, contains(m));
          }
        }
      }
      expect(m3InsulatorPickPacks['do_3_2_a'], m3InsulatorPickPack32);
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final msg = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      msg.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    Future<(ProviderContainer, M3InsulatorPickDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = m3InsulatorPickDeal(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M3InsulatorPickPage(ctx: _ctx, pack: m3InsulatorPickPack32, muted: true, seed: seed),
      )));
      await _pump(t, 1500);
      await waitIntro(t);
      return (c, deal);
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    final items = _label(_L.itemLabel);

    Future<void> lift(WidgetTester t, _Round r, _Item i) async {
      await t.tap(items.at(r.items.indexOf(i)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(_L.take), findsOneWidget);
    }

    /// Runs a finger along it and turns it to see the back.
    Future<void> inspect(WidgetTester t) async {
      final box = t.getRect(_label(_L.handLabel));
      final g = await t.startGesture(Offset(box.left + 2, box.center.dy));
      for (var i = 1; i <= 24; i++) {
        await g.moveTo(Offset(box.left + 2 + (box.width - 4) * i / 24, box.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(_label(_L.backLabel), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> fitRight(WidgetTester t, _Round r) async {
      await lift(t, r, _right(r));
      await inspect(t);
      await t.tap(find.text(_L.take));
      await _pump(t, 3500);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pickRight(t, _L.packRight(r.spot));
      await _pump(t, 3500);
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the pole (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: _app(M3InsulatorPickPage(ctx: _ctx, pack: m3InsulatorPickPack32, muted: true, seed: _seedCalling(1)))));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF insulator pick ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(items, findsNWidgets(3));
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('guide first: no start button, a tap does not skip; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: _app(M3InsulatorPickPage(ctx: _ctx, pack: m3InsulatorPickPack32, muted: true, seed: _seedCalling(2))),
      ));
      await _pump(t, 400);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(360, 800));
      await _pump(t, 600);
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      final guide = t.getRect(find.byType(AiLinemanGuide).last);
      final heard = <String>{};
      for (var i = 0; i < 3; i++) {
        await t.tapAt(guide.bottomRight - const Offset(50, 50));
        await _pump(t, 200);
        final line = c.read(guideDirectorProvider).line;
        expect(line, contains(_L.ask));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: the board, refuse the coworker, the chipped one aside, three poles with reasons → pass', (t) async {
      final (c, deal) = await open(t, _seedCalling(0));

      // He peeps in on the first pole; the guide asks; refuse him.
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, _L.coworkerChip.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      // Pole 1: read the board close.
      final r1 = deal.rounds[0];
      await t.tap(_label(_L.plateLabel));
      await _pump(t, 500);
      expect(find.text(_L.plateBn(r1.spot)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text(_L.plateBn(r1.spot)), findsNothing);
      // The shackle, put back unlooked: back on the tarp, no tag.
      await lift(t, r1, _kind(r1, _K.shackle));
      await t.tap(find.text(_L.putBack));
      await _pump(t, 800);
      expect(find.text(_L.rejected), findsNothing);
      // The chipped pin, turned over: its chip shows, so it goes aside.
      await lift(t, r1, r1.twin!);
      await inspect(t);
      await t.tap(find.text(_L.putBack));
      await _pump(t, 800);
      expect(find.text(_L.rejected), findsOneWidget, reason: 'found, so set aside');
      await fitRight(t, r1);

      // Pole 2 (LT end) and pole 3 (HT end): the right ones.
      await fitRight(t, deal.rounds[1]);
      await fitRight(t, deal.rounds[2]);
      await _pump(t, 4000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.2/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.2/do/0'], greaterThan(0));
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtFlaw), findsOneWidget);
      expect(find.text(_L.caughtMatch), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him fits the chipped one — a slip card', (t) async {
      final (c, _) = await open(t, _seedCalling(0));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(_L.coworkerChip.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(_M.chip.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: a shackle on the straight run is a slip and goes aside; then on to the next pole', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      await lift(t, r1, _kind(r1, _K.shackle));
      await t.tap(find.text(_L.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(_M.shackleOnStraight.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(_L.rejected), findsOneWidget);
      await fitRight(t, r1);
      expect(items, findsNWidgets(4), reason: 'on to pole 2');
      expect(c.read(gameSaveProvider).mistakes.length, 1);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      for (final i in [_kind(r1, _K.shackle), r1.twin!]) {
        await lift(t, r1, i);
        await t.tap(find.text(_L.take));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await fitRight(t, r1);
      final r2 = deal.rounds[1];
      await lift(t, r2, _kind(r2, _K.pin));
      await t.tap(find.text(_L.take));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('3.2/do/0'), isTrue);
      expect(s.rungProgress['3.2/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
