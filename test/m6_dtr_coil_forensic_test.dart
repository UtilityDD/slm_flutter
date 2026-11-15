// Lesson 6.1 (DTR), কাজ 2 "ক্ষতির খোঁজে কয়েল": the rules (a sign links
// only to what it harms; the hum is normal; a real sign is never normal; one
// right action per sign; the field tank opening is a slip after M6-4; in the
// shop the family only after the damage was found, a cause from the
// family's lesson group; listening to the recharge push = deadly, to the
// tank myth = a slip (X2/B1)), the deal, the libraries, the coworker's lines,
// and the level in the shell: the guide first, a full clean play (a reason
// pick each case, the coworker refused), a slip card that keeps the case, the
// tank trap as a slip, three slips, the deadly freeze (listening to the
// recharge push), the action rail waits for him on a fast play, the tag's
// two-step pick, and the gesture hand shows how (never what) only while the
// level waits.
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m6_dtr_coil_forensic.dart';
import 'package:slm_flutter/features/game/m6_dtr_coil_forensic_world.dart';
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
  rungId: '6.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '6.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m6CoilPacks['do_6_1_b']!;
typedef L = M6CoilLines;
typedef Mk = M6CoilMistakes;

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

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M6CoilGeo get _geo => M6CoilGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _listen(WidgetTester t) async {
  await t.longPress(_label(L.ear));
  await _pump(t, 400);
}

Future<void> _xray(WidgetTester t) async {
  final g = _geo;
  await t.dragFrom(Offset(g.tank.left + 20, g.tank.center.dy) * _k, const Offset(140, 0));
  await _pump(t, 400);
}

Future<void> _link(WidgetTester t, M6Sign s, M6Part p) async {
  final g = _geo;
  await t.dragFrom(g.pin(s) * _k, (g.zone(p).center - g.pin(s)) * _k);
  await _pump(t, 500);
}

/// A tag dragged from the tray onto the DTR (field) or the coil (shop).
Future<void> _dropTag(WidgetTester t, String text, {required bool field}) async {
  final g = _geo;
  final target = (field ? g.tank.center : g.coil.center) * _k;
  final from = t.getCenter(_label(text));
  await t.dragFrom(from, target - from);
  await _pump(t, 500);
}

/// A tag picked in two steps: tap → its preview → ✓.
Future<void> _pickTag(WidgetTester t, String text) async {
  await t.tap(_label(text));
  await t.pump(const Duration(milliseconds: 100));
  expect(await confirmChoice(t), isTrue, reason: text);
  await _pump(t, 500);
}

Future<void> _turnTo(WidgetTester t, int from, int to) async {
  final g = _geo;
  final steps = ((from - to) % m6Faces + m6Faces) % m6Faces;
  for (var i = 0; i < steps; i++) {
    // A drag right by 80 design px turns the coil one face round.
    await t.dragFrom(g.coil.center * _k, const Offset(80 * _k, 0));
    await _pump(t, 300);
  }
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M6DtrCoilForensicPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M6CoilDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m6CoilDeal(math.Random(s))));

Future<void> _refuse(WidgetTester t, M6Push p) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes ($p)');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker(p).right);
  await _pump(t, 2600);
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 3000);
}

/// One field case played right (the coworker refused if he is dealt on it).
Future<void> _playField(WidgetTester t, M6CoilDeal d, int i, {bool drag = true}) async {
  final c = d.field[i];
  if (m6Sound(c.sign)) await _listen(t);
  await _xray(t);
  await _link(t, c.sign, m6Accepted[c.sign]!.first);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${c.sign}');
  if (c.sign != M6Sign.hum) {
    if (d.coworkerCase == i) await _refuse(t, d.push);
    final a = L.act(m6ActFor(c.sign)!);
    if (drag) {
      await _dropTag(t, a, field: true);
    } else {
      await _pickTag(t, a);
    }
    expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${c.sign} action');
  }
  await _reason(t, L.whyRight(d.why[i], sign: c.sign));
}

/// One shop coil played right ([tap]: the damage tapped first; without it
/// the family names the damage once it was turned into view).
Future<void> _playShop(WidgetTester t, M6CoilDeal d, int j, {bool drag = false, bool tap = true}) async {
  final s = d.shop[j];
  final g = _geo;
  await _turnTo(t, s.startFace, s.damageFace);
  if (tap) {
    await t.tapAt(g.coil.center * _k);
    await _pump(t, 400);
  }
  final fam = L.family(s.family);
  final cause = L.cause(M6Cause.values.firstWhere((c) => m6CauseFits(s.family, c)));
  if (drag) {
    await _dropTag(t, fam, field: false);
    await _dropTag(t, cause, field: false);
  } else {
    await _pickTag(t, fam);
    await _pickTag(t, cause);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '${s.family}');
  await _reason(t, L.whyRight(d.why[2 + j], family: s.family));
}

M6FieldCase _f(M6Sign s, {M6Gel gel = M6Gel.blue}) => M6FieldCase(sign: s, acts: M6Act.values, gel: gel);
M6ShopCase _s(M6Family f, {int dmg = 2, int start = 0}) =>
    M6ShopCase(family: f, damageFace: dmg, startFace: start, families: M6Family.values, causes: M6Cause.values);

M6CoilRun _runOf(M6Sign first, {M6Sign second = M6Sign.gel, M6Push push = M6Push.tank, List<M6Family> shop = const [M6Family.thermal, M6Family.arc]}) =>
    M6CoilRun(M6CoilDeal(
      field: [_f(first), _f(second)],
      shop: [_s(shop[0]), _s(shop[1])],
      coworkerCase: first == M6Sign.hum ? 1 : 0,
      push: push,
      why: const [M6WhyTopic.link, M6WhyTopic.action, M6WhyTopic.family, M6WhyTopic.cause],
    ));

/// A run moved on to its first shop coil.
M6CoilRun _shopRun(M6Family f) {
  final r = _runOf(M6Sign.leak, shop: [f, f == M6Family.arc ? M6Family.mech : M6Family.arc])
    ..next()
    ..next();
  return r;
}

void main() {
  group('rules', () {
    test('deals: two field signs (never the same), two shop families (never the same), his case and push fit, reasons fit, plays differ', () {
      final seen = <String>{};
      final pushes = <M6Push>{};
      final whys = <M6WhyTopic>{};
      final signs = <M6Sign>{};
      final fams = <M6Family>{};
      var hum = 0;
      for (var s = 0; s < 200; s++) {
        final d = m6CoilDeal(math.Random(s));
        expect(d.field, hasLength(2));
        expect(d.shop, hasLength(2));
        expect(d.field[0].sign, isNot(d.field[1].sign));
        expect(d.field.where((c) => c.sign == M6Sign.hum).length, lessThanOrEqualTo(1));
        expect(d.shop[0].family, isNot(d.shop[1].family));
        for (final c in d.field) {
          expect(c.acts.toSet(), M6Act.values.toSet(), reason: 'the trap and every action on every rail');
          final spent = c.gel == M6Gel.pink || c.gel == M6Gel.white;
          expect(spent, c.sign == M6Sign.gel, reason: 'spent gel only in the gel case');
        }
        for (final c in d.shop) {
          expect(c.startFace, isNot(c.damageFace), reason: 'turning is required');
          expect(c.causes.toSet(), M6Cause.values.toSet(), reason: 'all seven causes shown');
          expect(c.families.toSet(), M6Family.values.toSet());
        }
        expect(d.field[d.coworkerCase].sign, isNot(M6Sign.hum), reason: 'never on the hum');
        if (d.push == M6Push.recharge) expect(d.field[d.coworkerCase].sign, M6Sign.burnt, reason: 'the recharge push only after the dark oil');
        for (var i = 0; i < 2; i++) {
          final w = d.why[i];
          expect(d.field[i].sign == M6Sign.hum ? {M6WhyTopic.hum} : {M6WhyTopic.link, M6WhyTopic.action}, contains(w));
        }
        for (var j = 0; j < 2; j++) {
          expect({M6WhyTopic.family, M6WhyTopic.cause}, contains(d.why[2 + j]));
        }
        pushes.add(d.push);
        whys.addAll(d.why);
        signs.addAll(d.field.map((c) => c.sign));
        fams.addAll(d.shop.map((c) => c.family));
        if (d.field.any((c) => c.sign == M6Sign.hum)) hum++;
        seen.add('${d.field.map((c) => '${c.sign.index}${c.source.index}${c.gel.index}${c.pop}${c.acts.first.index}').join()}|'
            '${d.shop.map((c) => '${c.family.index}${c.damageFace}${c.startFace}${c.causes.first.index}').join()}|${d.coworkerCase}${d.push.name}');
      }
      expect(seen.length, greaterThan(180));
      expect(pushes, M6Push.values.toSet());
      expect(whys, M6WhyTopic.values.toSet());
      expect(signs, M6Sign.values.toSet());
      expect(fams, M6Family.values.toSet());
      expect(hum, inInclusiveRange(40, 130));
    });

    test('field: the X-ray and (for a sound) the ear first; each sign links only to what it harms', () {
      final r = _runOf(M6Sign.crackle);
      expect(r.link(M6Part.conn), isNull);
      expect(r.linked, isNull, reason: 'no X-ray, not heard');
      r.openXray();
      expect(r.link(M6Part.conn), isNull);
      expect(r.linked, isNull, reason: 'a sound sign is heard first');
      r.listen();
      expect(r.link(M6Part.coil), Mk.linkCrackle);
      expect(r.link(M6Part.normal), Mk.calledNormal);
      expect(r.slips, 2);
      expect(r.link(M6Part.conn), isNull);
      expect(r.linked, M6Part.conn);
      expect(r.actionUp, isTrue);
      for (final s in M6Sign.values) {
        for (final p in M6Part.values) {
          final x = _runOf(s, second: s == M6Sign.gel ? M6Sign.leak : M6Sign.gel)
            ..listen()
            ..openXray();
          final m = x.link(p);
          if (m6Accepted[s]!.contains(p)) {
            expect(m, isNull, reason: '$s → $p');
          } else {
            expect(m, s == M6Sign.hum ? Mk.humFault : (p == M6Part.normal ? Mk.calledNormal : Mk.link(s)), reason: '$s → $p');
            expect(m!.deadly, isFalse);
          }
        }
      }
      // Two links accepted for the leak (heat via low oil; moisture via the gap).
      expect(m6Accepted[M6Sign.leak], {M6Part.coil, M6Part.paper});
    });

    test('the hum on "normal" ends the case; no action rail for it', () {
      final r = _runOf(M6Sign.hum)
        ..listen()
        ..openXray();
      expect(r.link(M6Part.normal), isNull);
      expect(r.roundDone, isTrue);
      expect(r.actionUp, isFalse);
      expect(r.caught, contains(L.caughtSign(M6Sign.hum)));
    });

    test('field action: one right per sign; the tank trap is a SLIP (M6-4), never deadly', () {
      for (final s in [M6Sign.leak, M6Sign.gel, M6Sign.burnt, M6Sign.crackle]) {
        final r = _runOf(s, second: s == M6Sign.gel ? M6Sign.leak : M6Sign.gel)
          ..listen()
          ..openXray()
          ..link(m6Accepted[s]!.first);
        expect(r.act(M6Act.tank), Mk.tankOpen);
        expect(Mk.tankOpen.deadly, isFalse);
        expect(r.ended, isFalse);
        for (final a in M6Act.values) {
          if (a == M6Act.tank || a == m6ActFor(s)) continue;
          expect(r.act(a), Mk.act(s), reason: '$s $a');
        }
        expect(r.act(m6ActFor(s)!), isNull);
        expect(r.roundDone, isTrue);
        expect(r.caught, contains(L.caughtSign(s)));
        expect(r.slips, 4);
      }
      // No action before the link.
      final n = _runOf(M6Sign.gel)..openXray();
      expect(n.act(M6Act.gel), isNull);
      expect(n.roundDone, isFalse);
    });

    test('shop: a family before the damage was ever turned into view is a guess; a clean-face tap is a slip; a cause from the family\'s group', () {
      final r = _shopRun(M6Family.thermal);
      expect(r.inField, isFalse);
      expect(r.facing, r.shop.startFace);
      expect(r.family(M6Family.thermal), Mk.guess, reason: 'the damage never turned into view');
      expect(r.tapCoil(), Mk.cleanFace, reason: 'the clean face toward the player: a wrong flag');
      expect(r.found, isFalse);
      expect(r.slips, 2);
      r.turnTo(r.shop.damageFace);
      expect(r.cause(M6Cause.overload), isNull);
      expect(r.roundDone, isFalse, reason: 'no cause before the family');
      expect(r.tapCoil(), isNull);
      expect(r.found, isTrue);
      expect(r.tapCoil(), isNull, reason: 'found: a second tap does nothing');
      expect(r.slips, 2);
      expect(r.family(M6Family.arc), Mk.famThermal);
      expect(r.family(M6Family.thermal), isNull);
      expect(r.cause(M6Cause.lightning), Mk.causeThermal);
      expect(r.cause(M6Cause.water), isNull);
      expect(r.roundDone, isTrue);
      expect(r.caught, contains(L.caughtFamily(M6Family.thermal)));
      expect(r.slips, 4);
      // Seen without a tap: the family names it (no guess), even turned away again.
      final v = _shopRun(M6Family.arc)
        ..turnTo(2)
        ..turnTo(3);
      expect(v.found, isFalse);
      expect(v.family(M6Family.arc), isNull, reason: 'the damage was turned into view');
      expect(v.found, isTrue);
      expect(v.slips, 0);
      // Seen, but the wrong family: the family's own slip, never the guess.
      final w = _shopRun(M6Family.turn)..turnTo(2);
      expect(w.family(M6Family.mech), Mk.famTurn);
      expect(w.slips, 1);
      for (final f in [M6Family.arc, M6Family.turn, M6Family.mech]) {
        final x = _shopRun(f)..turnTo(2);
        expect(x.tapCoil(), isNull);
        expect(x.found, isTrue);
        expect(x.family(M6Family.thermal), Mk.family(f));
        x.family(f);
        expect(x.cause(M6Cause.overload), Mk.causeHeavy);
        expect(x.cause(M6Cause.weakEarth), isNull);
      }
      for (final c in M6Cause.values) {
        expect(m6CauseFits(M6Family.thermal, c), c.index < 4, reason: '$c');
        expect(m6CauseFits(M6Family.mech, c), c.index >= 4, reason: '$c');
      }
    });

    test('the coworker: after the link on his case, before the action; listening to the tank myth = slip, the recharge push = deadly (X2/B1)', () {
      final r = _runOf(M6Sign.burnt, push: M6Push.recharge);
      expect(r.coworkerGate, isFalse);
      r
        ..openXray()
        ..link(M6Part.paper);
      expect(r.coworkerGate, isTrue);
      r.act(M6Act.isolate);
      expect(r.coworkerGate, isFalse);
      expect(Mk.push(M6Push.tank), Mk.tankOpen);
      expect(Mk.push(M6Push.tank).deadly, isFalse);
      expect(Mk.push(M6Push.recharge), Mk.recharge);
      expect(Mk.push(M6Push.recharge).deadly, isTrue);
      final s = _runOf(M6Sign.leak);
      s.pushSlip(Mk.tankOpen);
      expect(s.slips, 1);
      expect(s.ended, isFalse);
      final d = _runOf(M6Sign.burnt, push: M6Push.recharge)..failDeadly(Mk.recharge);
      expect(d.ended, isTrue);
      expect(d.passed, isFalse);
    });

    test('three slips: the mark falls 15 each; a clean play passes', () {
      final r = _runOf(M6Sign.leak)..openXray();
      for (var i = 0; i < 3; i++) {
        r.link(M6Part.conn);
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      final p = _runOf(M6Sign.leak, second: M6Sign.hum)
        ..openXray()
        ..link(M6Part.coil)
        ..act(M6Act.leakFix)
        ..next()
        ..listen()
        ..openXray()
        ..link(M6Part.normal)
        ..next();
      for (var j = 0; j < 2; j++) {
        p
          ..turnTo(p.shop.damageFace)
          ..tapCoil()
          ..family(p.shop.family)
          ..cause(M6Cause.values.firstWhere((c) => m6CauseFits(p.shop.family, c)))
          ..next();
      }
      expect(p.done, isTrue);
      expect(p.passed, isTrue);
      expect(p.percent, 100);
    });

    test('English digits only; jol not pani; every mistake has its picture; the deadly set; keys unique; lesson points', () {
      final all = <String>[
        ...L.newGuideLines,
        ...L.tasks,
        ...L.tapWhy,
        L.ear,
        L.sceneField,
        L.sceneShop,
        for (final p in M6Part.values) L.part(p),
        for (final a in M6Act.values) L.act(a),
        for (final f in M6Family.values) ...[L.family(f), L.caughtFamily(f)],
        for (final c in M6Cause.values) L.cause(c),
        for (final s in M6Sign.values) L.caughtSign(s),
        ...L.allWhyRight,
        ...L.myths,
        for (final cw in L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        L.caughtCall,
        L.quick,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(Mk.all.where((m) => m.deadly).toSet(), {Mk.recharge}, reason: 'R21 only; R20 lowered to a slip (M6-4)');
      expect(Mk.deadlyKeys, ['6.1/m6_dtr_coil_forensic/recharge']);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('6.1/m6_dtr_coil_forensic/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, isNotNull, reason: m.key);
        expect(m.lessonPoint, inInclusiveRange(0, 7));
      }
      for (final f in M6Family.values) {
        expect(Mk.family(f).lessonPoint, m6FamilyPoint(f));
        expect(Mk.cause(f).lessonPoint, m6FamilyPoint(f));
      }
      // The listening clips exist (the steady hum is module 5's clip).
      for (final f in [m6HumSteady, m6Pop, m6Crackle]) {
        expect(File('assets/$f').existsSync(), isTrue, reason: f);
      }
      expect(m6EarClip(_f(M6Sign.burnt)), isNull, reason: 'the tripped DTR is silent');
      // Every file in the art folder is used, and nothing else is in it.
      const dir = 'assets/game/art/m6_dtr_coil_forensic/';
      final used = {
        for (final m in Mk.all)
          if (m.art.startsWith(dir)) m.art.split('/').last,
        m6Pop.split('/').last,
        m6Crackle.split('/').last,
      };
      final files = Directory('assets/game/art/m6_dtr_coil_forensic').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m6CoilPacks.keys, ['do_6_1_b']);
      // No DO in module 6 (M6-2); the live 6.1 words for burnt oil and the
      // popping sound (X6).
      for (final l in all) {
        expect(l.contains('ডিও') || l.contains(' DO '), isFalse, reason: l);
      }
      expect(L.act(M6Act.isolate), contains('বিচ্ছিন্ন'));
      expect(L.act(M6Act.report), contains('দ্রুত রিপোর্ট'));
      expect(all.where((l) => l.contains('তড়িৎ রিপোর্ট') || l.contains('OFF-লোড')), isEmpty);
    });

    test('libraries: same length, big enough, never a rule marked wrong', () {
      expectSameLength('parts', [for (final p in M6Part.values) L.part(p)]);
      expectSameLength('actions', [for (final a in M6Act.values) L.act(a)]);
      expectSameLength('families', [for (final f in M6Family.values) L.family(f)]);
      expectSameLength('causes', [for (final c in M6Cause.values) L.cause(c)]);
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      final topics = <(M6WhyTopic, M6Sign?, M6Family?)>[
        for (final s in [M6Sign.leak, M6Sign.gel, M6Sign.burnt, M6Sign.crackle]) ...[(M6WhyTopic.link, s, null), (M6WhyTopic.action, s, null)],
        (M6WhyTopic.hum, null, null),
        for (final f in M6Family.values) ...[(M6WhyTopic.family, null, f), (M6WhyTopic.cause, null, f)],
      ];
      for (final (w, s, f) in topics) {
        final right = L.whyRight(w, sign: s, family: f);
        expectLibrary('why $w $s $f', right, L.myths);
        expect(L.whyQ[w], isNotEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in L.allCoworkers) {
        expectSameLength('choice ${cw.line}', [...cw.right, ...cw.wrong]);
        expectLibrary('choice ${cw.line}', cw.right, cw.wrong, minRight: 3);
        expect(cw.asks, contains('কী করবেন?'));
      }
    });

    test('rival lines: his exit is recorded; his two new lines are listed for recording; myth 3 word for word', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, [
        'মাঠে পোলের ওপরে ঝুলন্ত অবস্থাতেই ট্রান্সফরমারের ট্যাঙ্ক খুলে কয়েল ঠিক করে ফেলা যায়। চলো, ঢাকনাটা খুলি!',
        'তেল একটু কালো তো কী! HG ফিউজের তার বেঁধে আবার চার্জ করে দেখি, চলবে।',
      ]);
      // Lesson 6.1 myth 3 as in tool/all_training_chapters_bn.json.
      // (The lesson file uses the precomposed ya-nukta U+09DF; the app writes U+09AF U+09BC.)
      final lesson = File('tool/all_training_chapters_bn.json').readAsStringSync().replaceAll('\u09DF', '\u09AF\u09BC');
      expect(lesson.contains(L.myth3), isTrue);
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m6_dtr_coil_forensic: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no duplicates');
      expect(L.newGuideLines, contains(L.intro));
    });

    test('tap areas: the X-ray zones apart, the signs and the ear clear of them, on the scene, clear of the header and the guide', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M6CoilGeo.forScene(h, 0);
        final zones = [for (final p in M6Part.values) g.zone(p)];
        final pins = [for (final s in M6Sign.values) g.pinHit(s)];
        final rects = [...zones, ...pins, g.ear, g.coil];
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0), reason: 'h $h: $r');
          expect(r.right, lessThanOrEqualTo(360), reason: 'h $h: $r');
          expect(r.top, greaterThan(125), reason: 'h $h: below the header $r');
          expect(r.bottom, lessThan(h - 60), reason: 'h $h: $r');
        }
        for (final z in zones) {
          expect(z.width, greaterThanOrEqualTo(44), reason: 'h $h: $z');
          expect(z.height, greaterThanOrEqualTo(34), reason: 'h $h: $z');
          for (final p in pins) {
            expect(z.overlaps(p), isFalse, reason: 'h $h: zone $z / pin $p');
          }
          expect(z.overlaps(g.ear), isFalse);
        }
        for (var i = 0; i < zones.length; i++) {
          for (var j = i + 1; j < zones.length; j++) {
            expect(zones[i].overlaps(zones[j]), isFalse, reason: 'h $h: $i/$j');
          }
        }
        // The signs that can share a case never overlap (one sign a case, but
        // keep them apart anyway).
        for (var i = 0; i < pins.length; i++) {
          for (var j = i + 1; j < pins.length; j++) {
            if ({M6Sign.values[i], M6Sign.values[j]}.containsAll({M6Sign.hum, M6Sign.crackle})) continue;
            expect(pins[i].overlaps(pins[j]), isFalse, reason: 'h $h: pins $i/$j');
          }
        }
        // The guide stands bottom right (≈116 square) when no tray is up.
        final guide = Rect.fromLTRB(244, h - 12 - 116, 360, h);
        for (final r in [...zones, ...pins, g.ear]) {
          expect(r.overlaps(guide), isFalse, reason: 'h $h: $r under the guide');
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

    testWidgets('the guide comes first: a tap does not skip him; then the field DTR and the ear', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M6DtrCoilForensicPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(L.sceneField), findsOneWidget);
      expect(_label(L.ear), findsOneWidget);
      expect(_label(L.act(M6Act.tank)), findsNothing, reason: 'no rail before the link');
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
      expect(lines.every((l) => l.contains(L.askField)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    // One play with the tank myth (refused), one with the recharge push.
    final flowSeeds = [
      _seedWhere((d) => d.push == M6Push.tank && d.field.any((c) => c.sign == M6Sign.hum)),
      _seedWhere((d) => d.push == M6Push.recharge),
    ];
    for (final (n, seed) in flowSeeds.indexed) {
      testWidgets('flow (seed $seed): two field signs, two shop coils, reasons; he is refused → pass', (t) async {
        final d = m6CoilDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 2; i++) {
          await _playField(t, d, i, drag: n == 0);
        }
        for (var j = 0; j < 2; j++) {
          await _playShop(t, d, j, drag: n == 1);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['6.1/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['6.1/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtFamily(d.shop[0].family)), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final visualFirst = _seedWhere((d) => !m6Sound(d.field[0].sign) && d.coworkerCase != 0);
    testWidgets('a wrong link shows its card; the same case goes on after it', (t) async {
      final d = m6CoilDeal(math.Random(visualFirst));
      final c = await _open(t, visualFirst);
      final sign = d.field[0].sign;
      await _xray(t);
      await _link(t, sign, M6Part.conn);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.link(sign).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _link(t, sign, m6Accepted[sign]!.first);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(L.act(M6Act.tank)), findsOneWidget, reason: 'the same case: its rail is up');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.link(sign).key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the tank trap is a slip (M6-4): its card, no freeze; the rail stays', (t) async {
      final d = m6CoilDeal(math.Random(visualFirst));
      final c = await _open(t, visualFirst);
      final sign = d.field[0].sign;
      await _xray(t);
      await _link(t, sign, m6Accepted[sign]!.first);
      await _dropTag(t, L.act(M6Act.tank), field: true);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(Mk.tankOpen.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_label(L.act(m6ActFor(sign)!)), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.tankOpen.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('a tag: a tap opens its preview and answers nothing; ✕ sets it aside; ✓ then commits', (t) async {
      final d = m6CoilDeal(math.Random(visualFirst));
      final c = await _open(t, visualFirst);
      final sign = d.field[0].sign;
      await _xray(t);
      await _link(t, sign, m6Accepted[sign]!.first);
      final right = L.act(m6ActFor(sign)!);
      await t.tap(_label(right));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await t.tap(find.byKey(const ValueKey('choice-reject')));
      await _pump(t, 400);
      expect(find.byType(CardPreviewOverlay), findsNothing);
      expect(t.widget<CardAside>(find.ancestor(of: find.text(right), matching: find.byType(CardAside))).aside, isTrue);
      await _pickTag(t, right);
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a guess in the shop (a family before the damage is found) is a slip', (t) async {
      final seed = _seedWhere((d) => d.field.every((c) => c.sign != M6Sign.hum) && d.push == M6Push.tank);
      final d = m6CoilDeal(math.Random(seed));
      final c = await _open(t, seed);
      // Play the field cases through, then guess on the first coil.
      for (var i = 0; i < 2; i++) {
        await _playField(t, d, i);
      }
      await _pump(t, 800);
      expect(_label(L.sceneShop), findsOneWidget);
      await _pickTag(t, L.family(d.shop[0].family));
      expect(find.text(Mk.guess.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.guess.key);
      await _close(t, c);
    });

    testWidgets('the shop: the damage turned into view, the family named without a tap is no slip; a tap on a clean face is a slip', (t) async {
      final seed = _seedWhere((d) => d.field.every((c) => c.sign != M6Sign.hum) && d.push == M6Push.tank);
      final d = m6CoilDeal(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 2; i++) {
        await _playField(t, d, i);
      }
      await _pump(t, 800);
      expect(_label(L.sceneShop), findsOneWidget);
      await _playShop(t, d, 0, tap: false);
      expect(c.read(gameSaveProvider).mistakes, isEmpty, reason: 'looked, then named: no guess');
      await _pump(t, 800);
      // The second coil: its start face is never the damage, so a tap there is a wrong flag.
      expect(d.shop[1].startFace, isNot(d.shop[1].damageFace));
      await t.tapAt(_geo.coil.center * _k);
      await _pump(t, 600);
      expect(find.text(Mk.cleanFace.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.cleanFace.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final d = m6CoilDeal(math.Random(visualFirst));
      final c = await _open(t, visualFirst);
      await _xray(t);
      for (var i = 0; i < 3; i++) {
        await _link(t, d.field[0].sign, M6Part.conn);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    final rechargeFirst = _seedWhere((d) => d.push == M6Push.recharge && d.coworkerCase == 0);
    testWidgets('listening to "charge it again" on the dark oil = deadly: freeze first, then the card', (t) async {
      final c = await _open(t, rechargeFirst);
      await _xray(t);
      await _link(t, M6Sign.burnt, M6Part.paper);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerRecharge.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, Mk.recharge.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    final tankFirst = _seedWhere((d) => d.push == M6Push.tank && d.coworkerCase == 0 && !m6Sound(d.field[0].sign));
    testWidgets('a fast play: the action waits for the coworker; he cuts in at once; the action did nothing', (t) async {
      final d = m6CoilDeal(math.Random(tankFirst));
      final c = await _open(t, tankFirst);
      final sign = d.field[0].sign;
      await _xray(t);
      await _link(t, sign, m6Accepted[sign]!.first);
      // At once, well inside his 1.2–2.4 s timer.
      final right = L.act(m6ActFor(sign)!);
      final g = _geo;
      final from = t.getCenter(_label(right));
      await t.dragFrom(from, g.tank.center * _k - from);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pickRight(t, L.coworkerTank.right);
      await _pump(t, 2600);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_label(right), findsOneWidget, reason: 'the held drop did nothing: the rail is still up');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to the tank myth = a slip card (no freeze); the case goes on', (t) async {
      final d = m6CoilDeal(math.Random(tankFirst));
      final c = await _open(t, tankFirst);
      final sign = d.field[0].sign;
      await _xray(t);
      await _link(t, sign, m6Accepted[sign]!.first);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworkerTank.wrong);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.tankOpen.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(_label(L.act(m6ActFor(sign)!)), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.tankOpen.key);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch', (t) async {
      final seed = _seedWhere((d) => d.field[0].sign == M6Sign.hum);
      final c = await _open(t, seed);
      await _listen(t);
      await _xray(t);
      await _link(t, M6Sign.hum, M6Part.normal);
      // The ◆ on the table, the cards up at once: the scene takes nothing (a
      // drag from the sign to a wrong part would be a slip if it did).
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _link(t, M6Sign.hum, M6Part.coil);
      await _xray(t);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, L.whyHum);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: the hold ring on a sound sign, a swipe for the X-ray, a sweep over every tag alike; none while a deck is up', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => d.field[0].sign == M6Sign.crackle && d.coworkerCase == 1);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: not heard yet');
      expect(scene().debugOptions, isEmpty, reason: 'a hold, not a pick');
      await _listen(t);
      expect(scene().showing, isFalse);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle: the X-ray');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a swipe presses nothing');
      await _xray(t);
      await _link(t, M6Sign.crackle, M6Part.conn);
      expect(_label(L.ear), findsNothing, reason: 'the ear goes once the sign is linked (the tray rises there)');
      await _pump(t, 9000);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, hasLength(M6Act.values.length), reason: 'every tag alike');
      expect(find.byType(MistakeCard), findsNothing);
      await _pickTag(t, L.act(M6Act.report));
      await waitChoiceDeck(t);
      await _pump(t, 9000);
      expect(scene().showing, isFalse, reason: 'the deck has its own hand');
      await _close(t, c);
    });
  });
}
