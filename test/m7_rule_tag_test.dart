// Lesson 7.1 (ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন), কাজ "নিয়মের পাতা লাগান":
// the rules (a breach + its regulation pins; another regulation, a compliant
// part = slips; the register signed with a breach unpinned = one slip each;
// no deadly anywhere, ruling M7-6), the deal (3 of 4 sites, 1–3 breaches,
// never all, sides, people, light, the coworker on site 2 or 3), the live CEA
// 2023 numbers and lesson lines (X3), the libraries, every spoken line
// listed, the drawn places, and the level in the shell: the guide first, a
// full clean patrol (tabs dragged, a reason pick, the coworker refused), a
// slip card that keeps the site, missed breaches at the register, three slips,
// listening = a slip (no freeze), the drop and the register wait for him, the
// praise window takes no touch, a held tab shows its rule for free, and the
// gesture hand shows how (never what) only while the level waits.
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
import 'package:slm_flutter/features/game/m7_rule_tag.dart';
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
  rungId: '7.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.1',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7RuleTagPacks['do_7_1_a']!;
typedef L = M7RuleTagLines;
typedef Mk = M7RuleTagMistakes;

/// য় ড় ঢ় as base + nukta (the lesson file may hold single code points).
String _nk(String s) => s.replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়').replaceAll('য়', 'য়');

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
M7TagGeo get _geo => M7TagGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
M7TagRun get _live => M7RuleTagProbe.run!;

/// Drag [reg]'s tab so its pin lands at [pin] (design px).
Future<void> _dragTab(WidgetTester t, M7TagReg reg, Offset pin, {bool settle = true}) async {
  final from = _geo.tab(reg).center;
  final to = pin.translate(0, M7TagGeo.lift);
  final g = await t.startGesture(from * _k);
  for (var i = 1; i <= 8; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 8)! * _k);
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await _pump(t, settle ? 400 : 60);
}

Offset _partAt(M7TagPart p) {
  final s = _live.site;
  return _geo.partRect(s.kind, p, mirror: s.mirror).center;
}

Future<void> _sign(WidgetTester t) async {
  final r = _geo.register;
  await t.dragFrom(Offset(r.left + 12, r.center.dy) * _k, const Offset(64, 4) * _k);
  await _pump(t, 300);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7RuleTagPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

int _seedWhere(bool Function(M7TagDeal d) ok) => [for (var s = 0; s < 4000; s++) s].firstWhere((s) => ok(m7TagDeal(math.Random(s))));

/// The coworker came: refuse him.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
}

/// Pin [p] with its own regulation (the coworker refused if he cuts in; the
/// reason picked if due).
Future<void> _pin(WidgetTester t, M7TagPart p, Set<M7TagReg> asked) async {
  final reg = m7TagRegOf(p);
  await _dragTab(t, reg, _partAt(p));
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    expect(_live.pinned, isNot(contains(p)), reason: 'the drop waited for him');
    await _refuse(t);
    await _dragTab(t, reg, _partAt(p));
  }
  expect(_live.pinned, contains(p), reason: '$p pinned');
  expect(find.byType(MistakeCard), findsNothing);
  if (asked.add(reg)) {
    expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck ($reg)');
    await _pump(t, 500);
    await _pickRight(t, L.whyRight[reg]!);
    await _pump(t, 1500);
  } else {
    await _pump(t, 600);
  }
}

/// One site played clean: every breach pinned, then the register signed.
Future<void> _playSite(WidgetTester t, Set<M7TagReg> asked) async {
  final i = _live.index;
  for (final p in _live.site.breaches) {
    await _pin(t, p, asked);
  }
  await _sign(t);
  if (find.byType(CoworkerPeek).evaluate().isNotEmpty) {
    await _refuse(t);
    await _sign(t);
  }
  await _pump(t, 2400);
  expect(_live.index, i + 1);
}

M7TagSite _siteOf(M7TagSiteKind k, Map<M7TagPart, M7TagLook> looks) => M7TagSite(kind: k, looks: looks);

M7TagRun _runOf(M7TagSite first) => M7TagRun(M7TagDeal(
      sites: [
        first,
        for (final k in M7TagSiteKind.values.where((k) => k != first.kind).take(2)) m7TagDealSite(k, math.Random(k.index)),
      ],
      coworkerSite: 1,
      light: 0,
    ));

Map<String, dynamic> _lesson() {
  final all = jsonDecode(File('tool/all_training_chapters_bn.json').readAsStringSync()) as List<dynamic>;
  return all.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == '7.1');
}

void main() {
  group('rules', () {
    test('deals: 3 of 4 sites; 3–4 parts; 1–3 breaches, never all; sides, people, light and his site vary; plays differ', () {
      final seen = <String>{};
      final kinds = <M7TagSiteKind>{};
      final looks = <M7TagLook>{};
      final parts = <int>{};
      final breaches = <int>{};
      final him = <int>{};
      final lights = <int>{};
      var mirrored = 0, doorOpen = 0, doorClosed = 0, pillarNobody = 0;
      var laneSpansClear = 0, lanePersonOnly = 0, laneBothSpans = 0;
      for (var s = 0; s < 300; s++) {
        final d = m7TagDeal(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.map((x) => x.kind).toSet(), hasLength(3));
        expect(d.coworkerSite, inInclusiveRange(1, 2));
        him.add(d.coworkerSite);
        lights.add(d.light);
        for (final site in d.sites) {
          kinds.add(site.kind);
          expect(site.parts.length, inInclusiveRange(3, 4), reason: '${site.kind}');
          expect(site.breaches.length, inInclusiveRange(1, 3));
          expect(site.breaches.length, lessThan(site.parts.length), reason: 'never all broken');
          for (final p in m7TagFixedParts(site.kind)) {
            expect(site.looks, contains(p));
          }
          for (final e in site.looks.entries) {
            expect(m7TagLooks(e.key, breach: m7TagBreach(e.value)), contains(e.value));
          }
          if (site.kind == M7TagSiteKind.lane) {
            expect(site.looks, contains(M7TagPart.person), reason: 'someone is always on the lane\'s ladder');
            final spans = site.breaches.where((p) => p != M7TagPart.person).length;
            if (spans == 0) laneSpansClear++;
            if (site.breaches.length == 1 && site.breaches.single == M7TagPart.person) lanePersonOnly++;
            if (spans == 2) laneBothSpans++;
          }
          if (site.kind == M7TagSiteKind.pillar) {
            if (!site.looks.containsKey(M7TagPart.person)) pillarNobody++;
            if (site.looks[M7TagPart.person] == M7TagLook.local) expect(site.doorOpen, isTrue);
            if (!site.looks.containsKey(M7TagPart.person)) expect(site.doorOpen, isFalse);
            site.doorOpen ? doorOpen++ : doorClosed++;
          } else {
            expect(site.doorOpen, isFalse);
          }
          if (site.mirror) mirrored++;
          looks.addAll(site.looks.values);
          parts.add(site.parts.length);
          breaches.add(site.breaches.length);
        }
        seen.add('${d.coworkerSite}${d.light}|${d.sites.map((x) => '${x.kind.index}${x.mirror}${x.doorOpen}${x.looks.entries.map((e) => '${e.key.index}${e.value.index}').join()}').join('|')}');
      }
      expect(seen.length, greaterThan(280));
      expect(kinds, M7TagSiteKind.values.toSet());
      expect(looks, M7TagLook.values.toSet());
      expect(parts, {3, 4});
      expect(breaches, {1, 2, 3});
      expect(him, {1, 2});
      expect(lights, hasLength(kM7TagSkies.length));
      expect(mirrored, inInclusiveRange(300, 600), reason: 'plates and leads on either side');
      expect(doorOpen, greaterThan(20));
      expect(doorClosed, greaterThan(20));
      expect(pillarNobody, greaterThan(20));
      // The lane does not always have a resting span (his look is dealt first).
      expect(laneSpansClear, greaterThan(10), reason: 'both spans clear happens');
      expect(lanePersonOnly, greaterThan(10), reason: 'the ladder man as the only breach happens');
      expect(laneBothSpans, greaterThan(10), reason: 'both spans resting happens');
    });

    test('a drop: breach + its regulation pins; another regulation and a compliant part are slips; a pinned part costs nothing again', () {
      final r = _runOf(_siteOf(M7TagSiteKind.dtrPole, {
        M7TagPart.plate: M7TagLook.onGround,
        M7TagPart.neutralEarth: M7TagLook.connected,
        M7TagPart.bodyEarth: M7TagLook.cut,
        M7TagPart.person: M7TagLook.local,
      }));
      expect(r.drop(M7TagPart.plate, M7TagReg.r43), (M7TagDrop.wrongReg, Mk.wrongReg20));
      expect(r.drop(M7TagPart.neutralEarth, M7TagReg.r43), (M7TagDrop.needless, Mk.needlessNeutralEarth));
      expect(r.slips, 2);
      expect(r.drop(M7TagPart.plate, M7TagReg.r20), (M7TagDrop.pinned, null));
      expect(r.drop(M7TagPart.plate, M7TagReg.r20), (M7TagDrop.already, null));
      expect(r.drop(M7TagPart.plate, M7TagReg.r3), (M7TagDrop.already, null), reason: 'a pinned part is done');
      expect(r.drop(M7TagPart.person, M7TagReg.r20), (M7TagDrop.wrongReg, Mk.wrongReg3));
      expect(r.drop(M7TagPart.person, M7TagReg.r3), (M7TagDrop.pinned, null));
      expect(r.drop(M7TagPart.balconySpan, M7TagReg.r60), (M7TagDrop.already, null), reason: 'not on this site');
      expect(r.slips, 3);
      expect(r.unpinned, [M7TagPart.bodyEarth]);
      // The reason is asked once per regulation a play.
      expect(r.reasonDue(M7TagReg.r20), isTrue);
      expect(r.reasonDue(M7TagReg.r20), isFalse);
      // Signing with the cut body lead unpinned: one slip, its card.
      expect(r.sign(), [Mk.missedBodyEarth]);
      expect(r.slips, 4);
      expect(r.percent, 40);
      expect(r.caught.single, L.caughtSite(M7TagSiteKind.dtrPole, {M7TagReg.r20, M7TagReg.r3}));
      expect(r.caught.single, contains('3 · 20'), reason: 'booklet order');
      r.next();
      expect(r.pinned, isEmpty);
      expect(r.siteSlips, 0);
      expect(r.reasonDue(M7TagReg.r20), isFalse, reason: 'asked already this play');
    });

    test('the register: one slip per breach left (owner rule as specced); a clean site none; the lane\'s spans and person', () {
      final r = _runOf(_siteOf(M7TagSiteKind.lane, {
        M7TagPart.person: M7TagLook.local,
        M7TagPart.balconySpan: M7TagLook.resting,
        M7TagPart.roofSpan: M7TagLook.clear,
      }));
      expect(r.drop(M7TagPart.roofSpan, M7TagReg.r60), (M7TagDrop.needless, Mk.needlessRoof));
      expect(r.drop(M7TagPart.balconySpan, M7TagReg.r3), (M7TagDrop.wrongReg, Mk.wrongReg60));
      expect(r.sign(), [Mk.missedPerson, Mk.missedBalcony]);
      expect(r.slips, 4);
      expect(r.caught, isEmpty, reason: 'nothing pinned: nothing caught');
      // Both spans left: two cards that each name their own span (X6).
      final both = _runOf(_siteOf(M7TagSiteKind.lane, {
        M7TagPart.person: M7TagLook.crew,
        M7TagPart.balconySpan: M7TagLook.resting,
        M7TagPart.roofSpan: M7TagLook.resting,
      }));
      final cards = both.sign();
      expect(cards, [Mk.missedBalcony, Mk.missedRoof]);
      expect(cards.map((m) => m.key).toSet(), hasLength(2));
      expect(cards.map((m) => m.textBn).toSet(), hasLength(2));
      expect(Mk.needless(M7TagPart.balconySpan), isNot(Mk.needless(M7TagPart.roofSpan)));
      // A clear span never teaches "not touching = rule kept".
      for (final m in [Mk.needlessBalcony, Mk.needlessRoof]) {
        expect(m.textBn, isNot(contains('ঠেকেনি')));
        expect(m.textBn, isNot(contains('ফাঁক')));
        expect(m.textBn, contains('ক্লিয়ারেন্স আছে'));
      }
      final c = _runOf(_siteOf(M7TagSiteKind.pillar, {
        M7TagPart.neutralEarth: M7TagLook.gone,
        M7TagPart.plate: M7TagLook.fixed,
        M7TagPart.bodyEarth: M7TagLook.connected,
      }));
      expect(c.drop(M7TagPart.neutralEarth, M7TagReg.r43).$1, M7TagDrop.pinned);
      expect(c.sign(), isEmpty);
      expect(c.slips, 0);
      c.next();
      expect(c.index, 1);
    });

    test('no deadly in 7.1 (M7-6): every mistake a slip; keys, pictures, lesson point 3; listening = a slip', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      final r = _runOf(m7TagDealSite(M7TagSiteKind.plinth, math.Random(1)));
      expect(r.pushSlip(), Mk.pushListen);
      expect(r.slips, 1);
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.1/m7_rule_tag/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m != Mk.pushListen) expect(m.lessonPoint, 2, reason: 'lesson 7.1 point 3 holds the regulations');
      }
      expect(Mk.pushListen.lessonPoint, isNull, reason: 'a myth, not a numbered point');
      for (final p in M7TagPart.values) {
        expect(Mk.needless(p).deadly, isFalse);
        expect(Mk.missed(p).deadly, isFalse);
      }
      // Every file in the art folder is used.
      const dir = 'assets/game/art/m7_rule_tag/';
      final used = {for (final m in Mk.all) m.art.replaceFirst(dir, '')};
      final files = Directory(dir).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
      expect(m7RuleTagPacks.keys, ['do_7_1_a']);
    });

    test('the live lesson (X3): CEA 2023 numbers on the tabs, the rules and the myth word for word', () {
      final lesson = _lesson();
      final text = _nk(jsonEncode(lesson));
      // The tabs carry the live numbers (never the old 15 / 18 / 32).
      expect([for (final r in M7TagReg.values) L.regNo(r)], ['3', '20', '43 ও 50', '60–63 ও 71']);
      for (final bn in ['রেগুলেশন ৩ (উপযুক্ত ব্যক্তি)', 'রেগুলেশন ২০ (বিপজ্জনক নোটিশ)', 'রেগুলেশন ৪৩ ও ৫০ (আর্থিং)', 'রেগুলেশন ৬০ থেকে ৬৩ ও ৭১ (ক্লিয়ারেন্স)']) {
        expect(text, contains(_nk(bn)));
      }
      for (final r in M7TagReg.values) {
        expect(text, contains(_nk(L.regName(r))));
      }
      // The held rules quote the live lines.
      expect(text, contains(_nk('প্রশিক্ষিত এবং অনুমোদিত ব্যক্তিই বিদ্যুৎ লাইনে কাজ করতে পারবেন')));
      expect(text, contains(_nk('গায়ে একটি বিপদ চিহ্ন বা \'ডেঞ্জার প্লেট\' লাগানো বাধ্যতামূলক')));
      expect(text, contains(_nk('ধাতব বডি এবং সিস্টেমের নিউট্রালকে সঠিকভাবে আর্থিং করা বাধ্যতামূলক')));
      expect(text, contains(_nk('মাটি, বাড়ি এবং অন্যান্য লাইনের থেকে ন্যূনতম ক্লিয়ারেন্সের')));
      // The coworker's push is lesson myth 2 word for word (M7-10).
      final myths = ((lesson['content'] as Map)['myth_buster'] as Map)['myths'] as List;
      expect(_nk(L.coworker.line), _nk((myths[1] as Map)['myth'] as String));
      expect(_nk(Mk.pushListen.textBn), contains(_nk('যে সরাসরি বিপদের মুখে কাজ করছেন')));
      expect(text, contains(_nk('আইন জানা আপনাকে আত্মবিশ্বাসী')));
    });

    test('Bangla: English digits, জল not পানি, ডেড not মৃত, base + nukta, no "AB বন্ধ"; option groups within 1.3×', () {
      final all = <String>[
        L.intro,
        ...L.tasks,
        ...L.tapWhy,
        for (final r in M7TagReg.values) ...[L.tag(r), L.tabLabel(r), L.rule(r), L.whyQ(r), ...L.whyWrong(r)],
        ...L.allWhyRight,
        for (final k in M7TagSiteKind.values) L.siteName(k),
        ...L.coworker.recordedLines,
        ...L.coworker.right,
        ...L.coworker.wrong,
        ...L.coworker.asks,
        L.callHeld,
        L.allSet,
        L.fail,
        L.registerWord,
        for (final m in Mk.all) m.textBn,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|[\s,।—“])পানি').hasMatch(l), isFalse, reason: l); // the word, not কোম্পানি
        expect(l.contains('মৃত'), isFalse, reason: l);
        expect(l.contains('AB বন্ধ'), isFalse, reason: l);
        expect(RegExp('[ড়ঢ়য়]').hasMatch(l), isFalse, reason: 'base + nukta: $l');
      }
      expectSameLength('why', [...L.allWhyRight, ...L.allWhyWrong]);
      expect(L.allWhyWrong.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final r in M7TagReg.values) {
        expectLibrary('why $r', L.whyRight[r]!, L.whyWrong(r));
        expect(L.whyQ(r), contains(L.regNo(r)));
        for (var k = 0; k < 12; k++) {
          final deal = dealChoices(L.whyRight[r]!, L.whyWrong(r), math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworker;
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 3);
      expect(cw.asks, contains('কী করবেন?'));
    });

    test('spoken lines: his exit is recorded; his push and every new guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.newRivalLines, ['আইন তো শুধু বড় বড় ইঞ্জিনিয়ারদের জন্য, আমাদের এসব জেনে কী হবে?']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(L.newGuideLines, containsAll([L.intro, ...L.tasks, for (final r in M7TagReg.values) L.whyQ(r), L.callHeld, L.allSet, L.fail, for (final m in Mk.all) m.textBn]));
      expect(L.reused, contains('ওকে কী বলবেন?'), reason: 'it already has a clip');
      expect(L.newGuideLines, isNot(contains('ওকে কী বলবেন?')));
      for (final l in L.newGuideLines) {
        expect(L.reused, isNot(contains(l)));
      }
      // Every line the page speaks is in one of the lists.
      final spoken = L.spokenLines.toSet();
      for (final l in [L.intro, ...L.tasks, ...L.tapWhy, L.callHeld, L.allSet, L.quick, L.fail, L.coworker.line, L.coworkerExit, ...L.coworker.asks, for (final r in M7TagReg.values) L.whyQ(r), for (final m in Mk.all) m.textBn]) {
        expect(spoken, contains(l), reason: l);
      }
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_rule_tag: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
      }
    });

    test('places: parts never overlap, stay on the scene under the header, clear of the guide, his bubble, the register and the book', () {
      for (final h in [560.0, 640.0, 700.0, 780.0, 900.0]) {
        for (final inset in [0.0, 30.0]) {
          final g = M7TagGeo.forScene(h, inset);
          expect(g.book.bottom, lessThanOrEqualTo(h));
          for (final r in M7TagReg.values) {
            expect(g.book.contains(g.tab(r).topLeft) && g.book.contains(g.tab(r).bottomRight - const Offset(1, 1)), isTrue);
            expect(g.tab(r).overlaps(g.spine), isFalse);
            expect(g.tab(r).contains(g.bookCentre), isFalse, reason: 'the drag hint never starts on one tab');
          }
          expect(g.register.overlaps(g.book), isFalse);
          final guide = Rect.fromLTRB(244, g.bookTop - 118, 360, g.bookTop);
          for (final k in M7TagSiteKind.values) {
            for (final mirror in [false, true]) {
              final rects = [for (final p in [...m7TagFixedParts(k), if (k != M7TagSiteKind.lane) M7TagPart.person]) g.partRect(k, p, mirror: mirror)];
              for (final (i, a) in rects.indexed) {
                expect(a.isEmpty, isFalse);
                expect(a.left, greaterThanOrEqualTo(0), reason: '$k h $h: $a');
                expect(a.right, lessThanOrEqualTo(360), reason: '$k h $h: $a');
                expect(a.top, greaterThan(140), reason: '$k h $h: $a below the header');
                expect(a.overlaps(g.bubble), isFalse, reason: '$k h $h: $a under the bubble');
                expect(a.overlaps(guide), isFalse, reason: '$k h $h: $a under the guide');
                expect(a.overlaps(g.register), isFalse);
                expect(a.overlaps(g.book), isFalse);
                for (final b in rects.skip(i + 1)) {
                  expect(a.inflate(4).overlaps(b.inflate(4)), isFalse, reason: '$k h $h: $a / $b');
                }
              }
            }
          }
        }
      }
      // A pin finds its part; empty ground finds nothing.
      final g = M7TagGeo.forScene(780, 0);
      final s = m7TagDealSite(M7TagSiteKind.pillar, math.Random(3));
      for (final p in s.parts) {
        expect(g.partAt(s, g.partRect(s.kind, p, mirror: s.mirror).center), p);
      }
      expect(g.partAt(s, const Offset(180, 150)), isNull);
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

    testWidgets('the guide comes first: a tap does not skip him; then the four tabs and the register', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: DefaultAssetBundle(bundle: _DiskBundle(), child: M7RuleTagPage(ctx: _ctx, pack: _pack, muted: true, seed: 3)))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      for (final r in M7TagReg.values) {
        expect(_label(L.tabLabel(r)), findsOneWidget);
      }
      expect(_label(L.registerWord), findsOneWidget);
      expect(find.textContaining('বাকি'), findsNothing, reason: 'no "breaches left" counter');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide gives the task pool in turn, never a part or a regulation', (t) async {
      final c = await _open(t, 5);
      expect(c.read(guideDirectorProvider).line, contains(L.askSite));
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 3; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines, [L.tapRead, L.tapShow, L.tapSign]);
      for (final l in lines) {
        expect(RegExp('[0-9]').hasMatch(l), isFalse, reason: 'no regulation named: $l');
      }
      await _close(t, c);
    });

    // His site 2 and his site 3; one play with the lane, one with the pillar.
    final flowSeeds = [
      _seedWhere((d) => d.coworkerSite == 1 && d.sites.any((s) => s.kind == M7TagSiteKind.lane) && d.sites.expand((s) => s.breaches).toSet().length >= 3),
      _seedWhere((d) => d.coworkerSite == 2 && d.sites.any((s) => s.kind == M7TagSiteKind.pillar && s.looks.containsKey(M7TagPart.person))),
    ];
    for (final seed in flowSeeds) {
      testWidgets('flow (seed $seed): three sites, tabs dragged, reasons, he is refused, the register signed → pass', (t) async {
        final c = await _open(t, seed);
        final asked = <M7TagReg>{};
        for (var i = 0; i < 3; i++) {
          await _playSite(t, asked);
        }
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.1/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.1/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    final compliantFirst = _seedWhere((d) => d.sites.first.parts.length - d.sites.first.breaches.length >= 1 && d.sites.first.breaches.length >= 2);
    testWidgets('a needless flag and a wrong page are slips with their cards; the site goes on; empty ground costs nothing', (t) async {
      final c = await _open(t, compliantFirst);
      final s = _live.site;
      final ok = s.parts.firstWhere((p) => !s.breaches.contains(p));
      // Empty ground (the sky over the site): the tab springs back.
      await _dragTab(t, M7TagReg.r20, const Offset(300, 150));
      expect(find.byType(MistakeCard), findsNothing);
      expect(_live.slips, 0);
      await _dragTab(t, m7TagRegOf(ok), _partAt(ok));
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.needless(ok).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      final bad = s.breaches.first;
      final wrong = M7TagReg.values.firstWhere((r) => r != m7TagRegOf(bad));
      await _dragTab(t, wrong, _partAt(bad));
      expect(find.text(Mk.wrongReg(m7TagRegOf(bad)).textBn), findsOneWidget);
      expect(_live.pinned, isEmpty, reason: 'the tab sprang back');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_live.index, 0, reason: 'the same site');
      await _pin(t, bad, <M7TagReg>{});
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), [Mk.needless(ok).key, Mk.wrongReg(m7TagRegOf(bad)).key]);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    final twoBroken = _seedWhere((d) => d.sites.first.breaches.length == 2);
    testWidgets('the register signed with breaches left: one card each, then the camera pans on', (t) async {
      final c = await _open(t, twoBroken);
      final left = _live.site.breaches;
      await _sign(t);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.missed(left[0]).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(Mk.missed(left[1]).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 2600);
      expect(_live.index, 1);
      expect(_live.slips, 2, reason: 'one slip per breach left');
      // One book entry per missed breach (every part has its own key).
      expect(c.read(gameSaveProvider).mistakes, hasLength(left.length));
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key).toList(), [for (final p in left) Mk.missed(p).key]);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (needless flags)', (t) async {
      final c = await _open(t, compliantFirst);
      final s = _live.site;
      final ok = s.parts.firstWhere((p) => !s.breaches.contains(p));
      for (var i = 0; i < 3; i++) {
        await _dragTab(t, m7TagRegOf(ok), _partAt(ok));
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly in 7.1');
      await _close(t, c);
    });

    final hisSecond = _seedWhere((d) => d.coworkerSite == 1);
    testWidgets('listening to him = a slip (no freeze); the drop waited for him', (t) async {
      final c = await _open(t, hisSecond);
      await _playSite(t, <M7TagReg>{});
      final p = _live.site.breaches.first;
      await _dragTab(t, m7TagRegOf(p), _partAt(p));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the drop waits for him');
      expect(_live.pinned, isEmpty);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.pushListen.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.last.key, Mk.pushListen.key);
      expect(c.read(gameSaveProvider).mistakes.last.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      // He came once: the next drop pins.
      await _pin(t, p, <M7TagReg>{..._live.asked});
      expect(find.byType(CoworkerPeek), findsNothing);
      await _close(t, c);
    });

    testWidgets('the register waits for him too: signing his site first calls him in', (t) async {
      final c = await _open(t, hisSecond);
      await _playSite(t, <M7TagReg>{});
      await _sign(t);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(_live.index, 1, reason: 'not signed');
      expect(find.byType(MistakeCard), findsNothing);
      await _refuse(t);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the reason deck take no touch; the reason pays and the site goes on', (t) async {
      final seed = _seedWhere((d) => d.sites.first.breaches.length >= 2);
      final c = await _open(t, seed);
      final first = _live.site.breaches.first;
      final second = _live.site.breaches[1];
      await _dragTab(t, m7TagRegOf(first), _partAt(first));
      expect(_live.pinned, {first});
      // At once: drags on the scene do nothing (shielded, then the deck).
      await _dragTab(t, m7TagRegOf(second), _partAt(second), settle: false);
      expect(_live.pinned, {first});
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 500);
      await _pickRight(t, L.whyRight[m7TagRegOf(first)]!);
      await _pump(t, 1500);
      expect(_live.index, 0, reason: 'the same site');
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('hold a tab: its rule shows, for free; hold the spine: all four; nothing is pinned', (t) async {
      final c = await _open(t, 7);
      final g = await t.startGesture(_geo.tab(M7TagReg.r20).center * _k);
      await _pump(t, 900);
      expect(find.textContaining(L.rule(M7TagReg.r20)), findsOneWidget);
      expect(find.textContaining(L.rule(M7TagReg.r43)), findsNothing);
      await g.up();
      await _pump(t, 300);
      expect(find.textContaining(L.rule(M7TagReg.r20)), findsNothing);
      final s = await t.startGesture(_geo.spine.center * _k);
      await _pump(t, 900);
      for (final r in M7TagReg.values) {
        expect(find.textContaining(L.rule(r)), findsOneWidget);
      }
      await s.up();
      await _pump(t, 300);
      expect(_live.slips, 0);
      expect(_live.pinned, isEmpty);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hand: idle → a sweep over the parts (presses none); it hides while a tab is held', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 11);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9000);
      expect(scene().showing, isTrue, reason: 'idle on a site');
      expect(scene().debugOptions, hasLength(_live.site.parts.length), reason: 'every checkable part alike');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      final g = await t.startGesture(_geo.tab(M7TagReg.r3).center * _k);
      await _pump(t, 900);
      expect(scene().showing, isFalse);
      await g.up();
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });
  });
}
