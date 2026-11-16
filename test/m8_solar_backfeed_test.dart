// Lesson 8.8 (নেট মিটারিং রেগুলেশন), কাজ "ছাদে সূর্য, লাইনে বিপদ": the rules
// (a solar house's fuse pulled is right; a house with no solar = a slip; the
// ladder with any solar fuse in = deadly every time; listening to the coworker
// = deadly), the deal (6-8 houses, 2-4 solar, at least 3 without, clue mix,
// decoys, shuffled carriers, crossing cables), the live lesson lines, the
// libraries, every spoken line listed, the drawn places, and the level in the
// shell: the guide first, a full clean flow (marks, traces, pulls, reasons,
// the coworker refused, the ladder, the coda) to a pass, a slip card that
// restores the carrier, three slips, the deadly freeze (a live fuse; the
// coworker's push), the praise window, the look and zoom, and the gesture hand.
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
import 'package:slm_flutter/features/game/m8_solar_backfeed.dart';
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
  rungId: '8.8/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '8.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m8SolarBackfeedPacks['do_8_8_a']!;
typedef L = M8SolarBackfeedLines;
typedef Mk = M8SolarBackfeedMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('\u09DC', '\u09A1\u09BC').replaceAll('\u09DD', '\u09A2\u09BC').replaceAll('\u09DF', '\u09AF\u09BC');

/// The new art is not in pubspec's bundle in tests until the director wires
/// it: tests read it from disk when the bundle does not have it.
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

/// Design px -> screen px on the 392 x 850 test screen.
const _k = 392 / 360;
M8SolarRun get _live => M8SolarBackfeedProbe.run!;
M8Geo get _geo => M8SolarBackfeedProbe.geo!;
M8SolarDeal get _deal => _live.deal;
double get _cam => M8SolarBackfeedProbe.cam!.value;

Offset _scr(Offset world) => Offset(world.dx - _cam, world.dy) * _k;

Future<void> _setCam(WidgetTester t, double x) async {
  M8SolarBackfeedProbe.cam!.value = x;
  await t.pump(const Duration(milliseconds: 50));
}

double _camFor(M8House h) => M8Geo.isLeft(h.site) ? 0 : 240;

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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M8SolarBackfeedPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M8SolarDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m8SolarDeal(math.Random(s))));

/// A drag along [pts] (world px; the camera as it is now), a few px a step.
Future<void> _dragAlong(WidgetTester t, List<Offset> pts, {bool lift = true}) async {
  final g = await t.startGesture(_scr(pts.first));
  for (final p in pts.skip(1)) {
    await g.moveTo(_scr(p));
    await t.pump(const Duration(milliseconds: 16));
  }
  if (lift) await g.up();
  await _pump(t, 300);
}

Future<void> _tapWorld(WidgetTester t, Offset p) async {
  await t.tapAt(_scr(p));
  await _pump(t, 300);
}

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await waitChoiceDeck(t);
  final r = _onScreen(L.coworker.right);
  expect(r, hasLength(1));
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
  await _pump(t, 2600);
}

Future<void> _refuseIfHere(WidgetTester t) async {
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) await _refuse(t);
}

Future<void> _mark(WidgetTester t, M8House h, {bool guard = true}) async {
  if (guard) await _refuseIfHere(t);
  if (_live.marked.contains(h.site)) return;
  await _setCam(t, _camFor(h));
  await _tapWorld(t, _geo.door(h.site, h.mirror).center);
  expect(_live.marked, contains(h.site));
}

Future<void> _trace(WidgetTester t, M8House h, {bool guard = true}) async {
  if (guard) await _refuseIfHere(t);
  await _setCam(t, _camFor(h));
  await _dragAlong(t, _geo.cable(h));
  expect(_live.selected, h.site, reason: 'the cable reached its carrier');
}

Future<void> _pullDrag(WidgetTester t, M8House h) async {
  final s = _geo.slot(h.slot).center;
  await _dragAlong(t, [for (var i = 0; i <= 8; i++) s + Offset(0, 11.0 * i)]);
}

/// Answers every reason deck that opens next (right cards); returns how many.
Future<int> _answerReasons(WidgetTester t, {int maxMs = 1500}) async {
  var n = 0;
  while (await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: maxMs)) {
    if (find.byType(CoworkerPeek).evaluate().isNotEmpty) break;
    await waitChoiceDeck(t);
    final r = _onScreen(L.allWhyRight);
    expect(r, hasLength(1), reason: 'one right card on the deck');
    await t.tap(r.single, warnIfMissed: false);
    await tapReasonProceed(t);
    await _pump(t, 1500);
    n++;
  }
  return n;
}

/// Mark, trace and pull a solar house; the coworker refused when he cuts in;
/// its reasons answered.
Future<void> _rightPull(WidgetTester t, M8House h) async {
  await _mark(t, h);
  await _trace(t, h);
  await _setCam(t, _camFor(h));
  await _pullDrag(t, h);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_live.out, isNot(contains(h.site)), reason: 'the pull waited for him');
    await _refuse(t);
    await _setCam(t, _camFor(h));
    await _pullDrag(t, h);
  }
  expect(_live.out, contains(h.site), reason: 'pulled');
  expect(find.byType(MistakeCard), findsNothing);
  await _answerReasons(t);
}

Future<void> _ladderDrag(WidgetTester t) async {
  await _setCam(t, 0);
  final from = _geo.ladder.center;
  final to = Offset(M8Geo.poleX, _geo.groundY - 100);
  await _dragAlong(t, [for (var i = 0; i <= 10; i++) Offset.lerp(from, to, i / 10)!]);
}

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '8.8');
}

bool _segCross(Offset a, Offset b, Offset c, Offset d) {
  double o(Offset p, Offset q, Offset r) => (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
  return o(a, b, c) * o(a, b, d) < 0 && o(c, d, a) * o(c, d, b) < 0;
}

bool _cablesCross(M8Geo g, M8House x, M8House y) {
  final a = g.cable(x), b = g.cable(y);
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < b.length - 1; j++) {
      if (_segCross(a[i], a[i + 1], b[j], b[j + 1])) return true;
    }
  }
  return false;
}

void main() {
  group('rules', () {
    test('deals: 6-8 houses, 2-4 solar, at least 3 without; clues, decoys, carriers, light and the fault vary; plays differ', () {
      final seen = <String>{};
      final ns = <int>{}, solars = <int>{}, lights = <int>{}, faults = <M8Fault>{}, clutter = <int>{};
      final clues = <M8Clue>{}, decoys = <M8Decoy>{};
      var mirrored = 0, parapetOnly = 0, singleNonRoof = 0, carrierSticker = 0, sitesBack = 0, sitesFront = 0;
      for (var s = 0; s < 400; s++) {
        final d = m8SolarDeal(math.Random(s));
        ns.add(d.n);
        expect(d.n, inInclusiveRange(6, 8));
        expect(d.houses.map((h) => h.site).toSet(), hasLength(d.n));
        expect([for (final h in d.houses) h.site], [for (final h in d.houses) h.site]..sort(), reason: 'site order');
        final solar = d.solarHouses.toList();
        solars.add(solar.length);
        expect(solar.length, inInclusiveRange(2, 4));
        expect(d.n - solar.length, greaterThanOrEqualTo(3), reason: 'mark all, pull all must strike out');
        expect(d.houses.map((h) => h.slot).toList()..sort(), [for (var i = 0; i < d.n; i++) i], reason: 'the carriers are a permutation');
        expect(d.rows, (d.n + 1) ~/ 2);
        var single = 0, carriers = 0;
        for (final h in d.houses) {
          if (h.solar) {
            expect(h.clues, isNotEmpty);
            expect(h.decoy, M8Decoy.none, reason: 'decoys sit on houses with no solar');
            clues.addAll(h.clues);
            if (h.clues.length == 1 && h.nonRoofOnly) single++;
            if (h.panelsParapet && !h.panelsLane && h.clues.length == 1) parapetOnly++;
            if (h.stickerCarrier) carriers++;
          } else {
            expect(h.clues, isEmpty);
            decoys.add(h.decoy);
          }
          clutter.add(h.clutter);
          if (h.mirror) mirrored++;
          M8Geo.isFront(h.site) ? sitesFront++ : sitesBack++;
        }
        singleNonRoof += single > 0 ? 1 : 0;
        expect(single, greaterThanOrEqualTo(1), reason: 'at least one solar house shows a single non-roof clue');
        expect(carriers, lessThanOrEqualTo(1), reason: 'the pole carrier sticker: at most one a play');
        carrierSticker += carriers;
        expect(d.houses.where((h) => !h.solar && h.decoy != M8Decoy.none), isNotEmpty, reason: 'a decoy roof is always dealt');
        lights.add(d.light);
        faults.add(d.fault);
        seen.add('${d.light}${d.fault.index}|${d.houses.map((h) => '${h.site}${h.solar}${h.slot}${h.mirror}${h.decoy.index}${h.clues.map((c) => c.index).join()}').join('|')}');
      }
      expect(seen.length, greaterThan(390));
      expect(ns, {6, 7, 8});
      expect(solars, {2, 3, 4});
      expect(clues, M8Clue.values.toSet());
      expect(decoys, M8Decoy.values.toSet());
      expect(lights, {0, 1, 2});
      expect(faults, M8Fault.values.toSet());
      expect(clutter, {0, 1, 2, 3});
      expect(mirrored, inInclusiveRange(800, 2400));
      expect(parapetOnly, greaterThan(5), reason: 'a solar house seen only by holding its roof is dealt');
      expect(singleNonRoof, 400);
      expect(carrierSticker, greaterThan(10));
      expect(sitesFront, greaterThan(500));
      expect(sitesBack, greaterThan(500));
    });

    test('a pull: a solar house is right once; a house with no solar is a slip and the carrier stays; its card names what the house had', () {
      final d = m8SolarDeal(math.Random(_seedWhere((d) => d.houses.any((h) => !h.solar && h.decoy == M8Decoy.tarp))));
      final bad = d.houses.firstWhere((h) => !h.solar && h.decoy == M8Decoy.tarp);
      final good = d.solarHouses.first;
      final r = M8SolarRun(d);
      r.select(bad.site);
      expect(r.selected, bad.site);
      expect(r.pull(bad.site), (M8Pull.needless, Mk.needlessTarp));
      expect(r.slips, 1);
      expect(r.out, isEmpty);
      expect(r.selected, isNull);
      r.select(good.site);
      expect(r.pull(good.site), (M8Pull.right, null));
      expect(r.out, {good.site});
      expect(r.pull(good.site), (M8Pull.already, null), reason: 'already out');
      expect(r.slips, 1);
      expect(r.percent, 85);
      expect(r.caught.single, L.caughtHouse(good));
      r.select(good.site);
      expect(r.selected, isNull, reason: 'an empty slot is not selected');
      expect(r.traced, contains(good.site));
      // Every look of a no-solar house has its own card.
      expect(Mk.needless(M8House(site: 0, solar: false, slot: 0, sag: 30, mirror: false, palette: 0, clutter: 0)), Mk.needlessPlain);
      expect({for (final k in M8Decoy.values) Mk.needless(M8House(site: 0, solar: false, slot: 0, sag: 30, mirror: false, palette: 0, clutter: 0, decoy: k)).key}, hasLength(4));
    });

    test('the climb: deadly while any solar fuse is in (whatever the dealt inverter), safe once all are out; listening is deadly', () {
      for (final f in M8Fault.values) {
        final base = m8SolarDeal(math.Random(7));
        final d = M8SolarDeal(houses: base.houses, fault: f, light: base.light);
        final r = M8SolarRun(d);
        expect(r.climb(), Mk.climbLive, reason: 'no fuse out, $f');
        expect(r.deadly, Mk.climbLive);
        expect(r.ended, isTrue);
        expect(r.passed, isFalse);
      }
      final d = m8SolarDeal(math.Random(_seedWhere((d) => d.solarHouses.length >= 3)));
      final r = M8SolarRun(d);
      final solar = d.solarHouses.toList();
      for (final h in solar.take(solar.length - 1)) {
        r.pull(h.site);
      }
      expect(r.allOut, isFalse);
      expect(r.liveHouse, solar.last, reason: 'the death scene shows a house whose fuse is still in');
      expect(r.climb(), Mk.climbLive, reason: 'one solar fuse still in');
      final ok = M8SolarRun(d);
      for (final h in solar) {
        ok.pull(h.site);
      }
      expect(ok.allOut, isTrue);
      expect(ok.climb(), isNull);
      expect(ok.climbed, isTrue);
      expect(ok.passed, isTrue);
      // A pulled house with no solar never counts toward "all out".
      final nons = d.houses.firstWhere((h) => !h.solar);
      final x = M8SolarRun(d);
      x.pull(nons.site);
      expect(x.allOut, isFalse);
      expect(M8SolarRun(d).listen(), Mk.pushListen);
    });

    test('the reasons: back-feed on the first right pull; the clue question on the first house known only by a sticker or net meter', () {
      final d = m8SolarDeal(math.Random(_seedWhere((d) => d.solarHouses.first.nonRoofOnly && d.solarHouses.any((h) => !h.nonRoofOnly))));
      final solar = d.solarHouses.toList();
      final only = solar.firstWhere((h) => h.nonRoofOnly);
      final roof = solar.firstWhere((h) => !h.nonRoofOnly);
      // A roof-seen house first: back-feed only; the sticker house later: the clue question.
      final r = M8SolarRun(d);
      expect(r.whyAfterPull(roof.site), [M8WhyKind.backfeed]);
      expect(r.whyAfterPull(roof.site), isEmpty);
      expect(r.whyAfterPull(only.site), [M8WhyKind.clue]);
      expect(r.whyAfterPull(only.site), isEmpty, reason: 'the clue is asked once a play');
      // The sticker house first: both questions, back-feed first.
      final r2 = M8SolarRun(d);
      expect(r2.whyAfterPull(only.site), [M8WhyKind.backfeed, M8WhyKind.clue]);
      expect(r2.whyAfterPull(roof.site), isEmpty);
      expect(m8ClueAsked(only), isNotNull);
      expect(m8ClueAsked(only), anyOf(M8Clue.netMeter, M8Clue.stickerBox, M8Clue.stickerCarrier));
      expect(L.clueRight, contains(m8ClueAsked(only)));
    });

    test('mistakes: keys, pictures, lesson points, the deadly pair; every art file is used', () {
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.climbLive, Mk.pushListen});
      expect(Mk.deadlyKeys, ['8.8/m8_solar_backfeed/climb-live', '8.8/m8_solar_backfeed/push-listen']);
      for (final m in Mk.all) {
        expect(m.key, startsWith('8.8/m8_solar_backfeed/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, isNotNull);
      }
      expect(Mk.climbLive.lessonPoint, 2, reason: 'point 3 holds the anti-islanding back-feed');
      expect(Mk.needlessPlain.lessonPoint, 0, reason: 'the meter point');
      const dir = 'assets/game/art/m8_solar_backfeed/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m8SolarBackfeedPacks.keys, ['do_8_8_a']);
      // Cards that follow a slip describe THIS house (X6).
      expect(Mk.needlessTarp.textBn, contains('ত্রিপল'));
      expect(Mk.needlessSkylight.textBn, contains('স্কাইলাইট'));
      expect(Mk.needlessTanks.textBn, contains('ট্যাঙ্ক'));
      expect(Mk.needlessPlain.textBn, contains('সাধারণ মিটার'));
    });

    test('the live lesson: the back-feed rule, the sticker and the meter clues, the anti-islanding and the myth word for word', () {
      final text = _nk(jsonEncode(_lesson()));
      for (final q in [
        'শুধু ট্রান্সফরমার অফ করবেন না। পোল থেকে ওই বাড়ির ফিউজও খুলে দিন',
        'বিশ্বাসে মিলায় বস্তু, কিন্তু সোলারে মিলায় মৃত্যু',
        'সবুজ স্টিকার',
        'মিটার বক্সে বা পোলে একটা সবুজ স্টিকার',
        'তীরের চিহ্ন (Arrow) কোন দিকে',
        'Import/Export আলাদা দেখাচ্ছে কি না',
        'ব্যাক-ফিড',
        'গ্রিড বন্ধ থাকার পরেও সোলার চলতে থাকে',
        'গ্রিড বন্ধ হলে সোলারও বন্ধ হয়ে যায়',
        'ছাদ থেকে সোলার প্যানেল ভোল্টেজ পাঠিয়ে লাইন সজীব',
      ]) {
        expect(text, contains(_nk(q)), reason: q);
      }
      expect(L.whyRight[M8WhyKind.climb]!.first, contains('বিশ্বাসে মিলায় বস্তু'));
      expect(_nk(L.whyRight[M8WhyKind.backfeed]![1]), contains('সোলার ভোল্টেজ পাঠিয়ে লাইন সজীব'));
      expect(L.clueRight[M8Clue.netMeter]!.any((l) => l.contains('Import') && l.contains('Export')), isTrue);
      expect(L.coworker.line, contains('ইনভার্টার নিজেই বন্ধ হয়ে যায়'), reason: 'the myth the lesson busts (on-grid: grid off = solar off, but he cannot see it)');
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, LT/HT/kV in letters, base + nukta, no "AB বন্ধ"; option groups within 1.3x', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        for (final k in M8WhyKind.values) L.whyQ[k]!,
        ...L.allWhyRight,
        ...L.allWhyWrong,
        L.coworker.line,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.crewLive,
        L.crewDead,
        L.crewEarth,
        L.solarSticker,
        for (final c in M8Clue.values) L.clueName(c),
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp(r'(এলটি|এইচটি|কেভি|(^|[\s,।—“])(অফ|অন)($|[\s,।—”]))').hasMatch(l), isFalse, reason: 'ON/OFF and kV in letters: $l');
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expect(L.coworker.line, contains('OFF'));
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final k in [M8WhyKind.backfeed, M8WhyKind.climb]) {
        expectLibrary('why $k', L.whyRight[k]!, L.wrongFor(k), minRight: 3);
        expectSameLength('why $k', [...L.whyRight[k]!, ...L.wrongFor(k)]);
      }
      for (final c in L.clueRight.keys) {
        expectLibrary('clue $c', L.clueRight[c]!, L.wrongFor(M8WhyKind.clue));
        expectSameLength('clue $c', [...L.clueRight[c]!, ...L.wrongFor(M8WhyKind.clue)]);
      }
      for (final k in M8WhyKind.values) {
        for (final c in <M8Clue?>[if (k == M8WhyKind.clue) ...L.clueRight.keys else null]) {
          for (var i = 0; i < 12; i++) {
            final deal = dealChoices(L.rightFor(k, clue: c), L.wrongFor(k), math.Random(i));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
      }
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
      // The first right pull's reason is never the clue's: rights state the rule.
      for (final r in L.whyRight[M8WhyKind.backfeed]!) {
        expect(r, anyOf(contains('ব্যাক-ফিড'), contains('সজীব'), contains('কারেন্ট')));
      }
    });

    test('spoken lines: his exit is recorded; his push and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [L.coworker.line]);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, for (final k in M8WhyKind.values) L.whyQ[k]!, L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      expect(L.reused, containsAll(['ওকে কী বলবেন?', 'থামুন!', 'অল্পের জন্য!']));
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      final spoken = L.spokenLines.toSet();
      for (final l in [
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        L.callHeld,
        L.allSet,
        L.quick,
        L.fail,
        L.deadlyWord,
        L.nearMissWord,
        L.coworker.line,
        L.coworkerExit,
        ...L.coworker.asks,
        for (final k in M8WhyKind.values) L.whyQ[k]!,
        for (final m in Mk.all) m.textBn,
      ]) {
        expect(spoken, contains(l), reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m8_solar_backfeed: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: houses, doors, meters stay apart and on the world; cables run from their clip to their carrier and cross; nothing hides under the header or the guide', () {
      for (final h in [560.0, 640.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M8Geo.forScene(h, inset);
          expect(g.trainee.bottom, lessThanOrEqualTo(h));
          expect(g.ladder.bottom, lessThanOrEqualTo(h));
          expect(g.pouch.bottom, lessThanOrEqualTo(h));
          expect(g.pole.bottom, lessThan(h - 118), reason: 'the pole foot stays above the guide');
          for (var s = 0; s < 8; s++) {
            expect(g.house(s).left, greaterThanOrEqualTo(0));
            expect(g.house(s).right, lessThanOrEqualTo(M8Geo.worldW));
            expect(g.roof(s).top, greaterThan(100), reason: 'h $h site $s: under the header');
            for (final mirror in [false, true]) {
              final door = g.door(s, mirror).inflate(8), meter = g.meter(s, mirror).inflate(8);
              expect(g.house(s).contains(g.door(s, mirror).topLeft) && g.house(s).contains(g.door(s, mirror).bottomRight - const Offset(1, 1)), isTrue);
              expect(door.overlaps(meter), isFalse, reason: 'site $s mirror $mirror');
              expect(g.roof(s).overlaps(door), isFalse);
              expect(g.roof(s).overlaps(meter), isFalse);
            }
            for (var o = s + 1; o < 8; o++) {
              expect(g.house(s).inflate(2).overlaps(g.house(o)), isFalse, reason: 'houses $s / $o');
            }
          }
          // The board sits between the rows' near houses, clear of every wall.
          final rows4 = g.boardOf(4);
          for (var s = 0; s < 8; s++) {
            expect(g.house(s).overlaps(rows4), isFalse, reason: 'the board $s');
          }
          // At every camera the guide's corner is clear of the trainee, pouch and ladder.
          for (final cam in h >= 640 ? [0.0, 120.0, 240.0] : <double>[]) {
            final guide = Rect.fromLTWH(244 + cam, h - 118, 116, 118);
            expect(g.trainee.overlaps(guide), isFalse, reason: 'cam $cam');
            expect(g.pouch.overlaps(guide), isFalse);
            expect(g.ladder.overlaps(guide), isFalse);
          }
        }
      }
      final g = M8Geo.forScene(780, 0);
      for (var s = 0; s < 8; s++) {
        final dh = M8House(site: s, solar: true, slot: s, sag: 40, mirror: false, palette: 0, clutter: 0);
        final c = g.cable(dh);
        expect(c.first, g.bracket(s));
        expect((c.last - g.terminal(s)).distance, lessThan(0.01));
        expect(g.slot(s).overlaps(g.boardOf(4)), isTrue);
        expect(g.poleDrop.contains(g.pole.center), isTrue);
        // Every bracket and the whole cable stay in the world.
        for (final p in c) {
          expect(p.dx, inInclusiveRange(0, M8Geo.worldW));
        }
      }
      // Slots never overlap.
      for (var a = 0; a < 8; a++) {
        for (var b = a + 1; b < 8; b++) {
          expect(g.slot(a).overlaps(g.slot(b)), isFalse);
        }
      }
      // The lane has crossing cables in most plays; the carriers' order is the puzzle.
      var crossing = 0;
      for (var s = 0; s < 100; s++) {
        final d = m8SolarDeal(math.Random(s));
        outer:
        for (var i = 0; i < d.n; i++) {
          for (var j = i + 1; j < d.n; j++) {
            if (_cablesCross(g, d.houses[i], d.houses[j])) {
              crossing++;
              break outer;
            }
          }
        }
      }
      expect(crossing, greaterThan(90));
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

    testWidgets('the guide comes first: a tap does not skip him; then the lane, the pouch and the ladder', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M8SolarBackfeedPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.pouchLabel), findsOneWidget);
      expect(_label(L.ladderLabel), findsOneWidget);
      expect(find.textContaining('বাকি'), findsNothing, reason: 'no counter of what is left');
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives this stage\'s task in other words, never a house or a count', (t) async {
      final c = await _open(t, 5);
      expect(c.read(guideDirectorProvider).line, contains(L.look.first));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.look[1], L.look[0]]);
      for (final l in lines) {
        expect(RegExp('[0-9]').hasMatch(l), isFalse, reason: 'no number: $l');
      }
      // A mark moves the task on: the cable next.
      final h = _deal.houses.first;
      await _mark(t, h);
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await _pump(t, 400);
      expect(L.trace, contains(c.read(guideDirectorProvider).line));
      await _close(t, c);
    });

    // Few solar (2 of 6) and many solar (4 of 8); the first one a sticker house in one, a roof house in the other.
    final flowSeeds = [
      _seedWhere((d) => d.n == 6 && d.solarHouses.length == 2 && d.solarHouses.first.nonRoofOnly),
      _seedWhere((d) => d.n == 8 && d.solarHouses.length == 4 && !d.solarHouses.first.nonRoofOnly),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): marks, traces, pulls, reasons, he is refused, the ladder, the coda → pass', (t) async {
        final c = await _open(t, seed);
        for (final h in _deal.solarHouses) {
          await _rightPull(t, h);
        }
        expect(_live.allOut, isTrue);
        expect(_live.slips, 0);
        await _refuseIfHere(t);
        await _ladderDrag(t);
        if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
          await _refuse(t);
          await _ladderDrag(t);
        }
        expect(_live.climbed, isTrue);
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the climb reason');
        await waitChoiceDeck(t);
        final r = _onScreen(L.whyRight[M8WhyKind.climb]!);
        expect(r, hasLength(1));
        await t.tap(r.single, warnIfMissed: false);
        await tapReasonProceed(t);
        // The coda: the crew's tester, 0 V (ডেড), the earths; then the pass panel.
        await _pump(t, 800);
        expect(find.text(L.crewDead), findsOneWidget);
        expect(find.text(L.crewLive), findsOneWidget);
        expect(find.text(L.crewEarth), findsOneWidget);
        await _pump(t, 3600);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['8.8/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['8.8/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.textContaining('সোলারের বাড়ি:'), findsWidgets);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final badFirst = _seedWhere((d) => d.houses.any((h) => !h.solar && h.decoy != M8Decoy.none));
    M8House badOf(M8SolarDeal d) => d.houses.firstWhere((h) => !h.solar && h.decoy != M8Decoy.none);

    testWidgets('a house with no solar: the pull is a slip with its card, the carrier springs back, nothing is pouched; the lane goes on', (t) async {
      final c = await _open(t, badFirst);
      final h = badOf(_deal);
      await _mark(t, h);
      await _trace(t, h);
      await _setCam(t, _camFor(h));
      await _pullDrag(t, h);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.needless(h).textBn), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.out, isEmpty, reason: 'the carrier is back');
      expect(_live.selected, isNull);
      expect(_live.slips, 1);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.needless(h).key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      // The good house still pulls clean; he has not come yet (no right pull before).
      await _rightPull(t, _deal.solarHouses.first);
      expect(_live.out, hasLength(1));
      await _close(t, c);
    });

    testWidgets('three needless pulls strike the level out (no freeze: not deadly)', (t) async {
      final c = await _open(t, badFirst);
      final h = badOf(_deal);
      await _mark(t, h);
      for (var i = 0; i < 3; i++) {
        await _trace(t, h);
        await _setCam(t, _camFor(h));
        await _pullDrag(t, h);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_live.slips, 3);
      await _close(t, c);
    });

    final liveSeed = _seedWhere((d) => d.solarHouses.length >= 2);
    testWidgets('the first touch of the climb control brings him (nothing climbs); refused, the ladder with a solar fuse in is deadly: freeze first, then the card', (t) async {
      final c = await _open(t, liveSeed);
      await _ladderDrag(t);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the climb waits for him');
      expect(_live.ended, isFalse, reason: 'nothing climbed');
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _refuse(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _ladderDrag(t);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      expect(find.text(Mk.climbLive.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.climbLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(_live.deadly, Mk.climbLive);
      await _close(t, c);
    });

    testWidgets('one solar fuse still in after the first right pull: the ladder (after him) is deadly', (t) async {
      final c = await _open(t, liveSeed);
      await _rightPull(t, _deal.solarHouses.first);
      expect(_live.allOut, isFalse);
      await _refuseIfHere(t);
      await _ladderDrag(t);
      if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
        await _refuse(t);
        await _ladderDrag(t);
      }
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.climbLive.key);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly (he lifts the ladder): freeze, then the card; the next pull after the first right one waited for him', (t) async {
      final c = await _open(t, liveSeed);
      final solar = _deal.solarHouses.toList();
      final first = solar.first, h = solar[1];
      await _mark(t, first);
      await _trace(t, first);
      await _setCam(t, _camFor(first));
      await _pullDrag(t, first);
      // The reasons answered at once, so he has not come yet when the next pull is tried.
      while (await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 600)) {
        await waitChoiceDeck(t);
        final r = _onScreen(L.allWhyRight);
        expect(r, hasLength(1));
        await t.tap(r.single, warnIfMissed: false);
        await tapReasonProceed(t);
      }
      await _mark(t, h, guard: false);
      await _trace(t, h, guard: false);
      await _setCam(t, _camFor(h));
      await _pullDrag(t, h);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the next pull waited for him');
      expect(_live.out, isNot(contains(h.site)));
      expect(find.byType(MistakeCard), findsNothing);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.pushListen.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.pushListen.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; marks, zoom and pulls wait', (t) async {
      final c = await _open(t, liveSeed);
      final solar = _deal.solarHouses.toList();
      final first = solar.first;
      await _mark(t, first);
      await _trace(t, first);
      await _setCam(t, _camFor(first));
      await _pullDrag(t, first);
      expect(_live.out, {first.site});
      // At once: a tap on another door, a meter box and a drag do nothing (shielded, then the deck).
      final other = _deal.houses.firstWhere((h) => h.site != first.site && M8Geo.isLeft(h.site) == M8Geo.isLeft(first.site), orElse: () => _deal.houses.firstWhere((h) => h.site != first.site));
      await _setCam(t, _camFor(other));
      await t.tapAt(_scr(_geo.door(other.site, other.mirror).center));
      await t.pump(const Duration(milliseconds: 100));
      await t.tapAt(_scr(_geo.meter(other.site, other.mirror).center));
      await t.pump(const Duration(milliseconds: 100));
      expect(_live.marked, {first.site});
      expect(find.byKey(ValueKey('zoom-${other.site}')), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await t.tapAt(_scr(_geo.door(other.site, other.mirror).center));
      await t.pump(const Duration(milliseconds: 100));
      expect(_live.marked, {first.site}, reason: 'the deck is up: the scene takes nothing');
      await _answerReasons(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a tap marks a door, a second wipes it: free, no card, no guide word, no score; a drag from an unmarked clip only pans', (t) async {
      final c = await _open(t, 9);
      final h = _deal.houses.first;
      final line = c.read(guideDirectorProvider).line;
      await _setCam(t, _camFor(h));
      await _tapWorld(t, _geo.door(h.site, h.mirror).center);
      expect(_live.marked, {h.site});
      await _tapWorld(t, _geo.door(h.site, h.mirror).center);
      expect(_live.marked, isEmpty);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, line, reason: 'a mark gets no word');
      expect(_live.slips, 0);
      // A drag from the unmarked clip along its cable moves the camera, not the chalk.
      await _setCam(t, 100);
      final before = _cam;
      final b = _geo.bracket(h.site);
      final g = await t.startGesture(_scr(b));
      for (var i = 1; i <= 6; i++) {
        await g.moveTo(_scr(b) + Offset(14.0 * i, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      expect(_cam, isNot(before), reason: 'the view panned');
      expect(_live.selected, isNull);
      expect(_live.traced, isEmpty);
      expect(_cam, inInclusiveRange(0, M8Geo.camMax));
      await _close(t, c);
    });

    testWidgets('hold a roof: the view over its parapet, for any roof alike; a tap on any meter box zooms it; both cost nothing', (t) async {
      final c = await _open(t, 11);
      final net = _deal.houses.firstWhere((h) => h.netMeter, orElse: () => _deal.houses.first);
      final plain = _deal.houses.firstWhere((h) => !h.netMeter && !h.stickerBox, orElse: () => _deal.houses.last);
      for (final h in [net, plain]) {
        await _setCam(t, _camFor(h));
        final hold = await t.startGesture(_scr(_geo.roof(h.site).center));
        await _pump(t, 900);
        expect(find.byKey(ValueKey('peek-${h.site}')), findsOneWidget, reason: 'every roof answers alike');
        await hold.up();
        await _pump(t, 300);
        expect(find.byKey(ValueKey('peek-${h.site}')), findsNothing);
        await _tapWorld(t, _geo.meter(h.site, h.mirror).center);
        expect(find.byKey(ValueKey('zoom-${h.site}')), findsOneWidget, reason: 'every box answers alike');
        expect(find.text(L.importWord), h.netMeter ? findsOneWidget : findsNothing);
        expect(find.text(L.exportWord), h.netMeter ? findsOneWidget : findsNothing);
        expect(find.text(L.solarSticker), h.stickerBox ? findsOneWidget : findsNothing);
        await t.tapAt(const Offset(200, 600));
        await _pump(t, 300);
        expect(find.byKey(ValueKey('zoom-${h.site}')), findsNothing);
      }
      expect(_live.slips, 0);
      expect(_live.marked, isEmpty);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the cable lights only as far as the finger has followed it; let go short of the pole: nothing is selected, nothing costs', (t) async {
      final c = await _open(t, liveSeed);
      final h = _deal.houses.first;
      await _mark(t, h);
      await _setCam(t, _camFor(h));
      final pts = _geo.cable(h);
      await _dragAlong(t, pts.take(20).toList());
      expect(_live.selected, isNull);
      expect(_live.traced, isEmpty);
      expect(_live.slips, 0);
      // Straying off the cable stops the light: a finger far from the wire gets no further.
      final g = await t.startGesture(_scr(pts.first));
      for (final p in pts.take(8).skip(1)) {
        await g.moveTo(_scr(p));
        await t.pump(const Duration(milliseconds: 16));
      }
      for (var i = 1; i <= 6; i++) {
        await g.moveTo(_scr(pts[7] + Offset(0, -60.0 * i)));
        await t.pump(const Duration(milliseconds: 16));
      }
      for (final p in pts.skip(8)) {
        await g.moveTo(_scr(p + const Offset(0, -80)));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _pump(t, 300);
      expect(_live.selected, isNull, reason: 'not along the wire');
      await _dragAlong(t, pts);
      expect(_live.selected, h.site);
      await _close(t, c);
    });

    testWidgets('gesture hand: a swipe/sweep at rest, a nudge from a marked clip, a drag-down on the selected carrier; none presses anything', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, liveSeed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on the lane');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a swipe presses nothing');
      expect(_live.marked, isEmpty);
      final h = _deal.solarHouses.first;
      await _mark(t, h);
      expect(scene().showing, isFalse, reason: 'a touch hides the hand');
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with a mark and no trace');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a nudge presses nothing');
      expect(_live.traced, isEmpty, reason: 'the hand moves no chalk');
      await _trace(t, h);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle with a carrier selected');
      expect(_live.out, isEmpty, reason: 'the hand pulls nothing');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
