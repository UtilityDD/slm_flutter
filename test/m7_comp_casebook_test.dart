// Lesson 7.2 (ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট), কাজ 1 "কোন খাতে ক্ষতিপূরণ?":
// the rules (open a file, tear calendar pages to see the story move on, file
// it in one of four drawers or the বাতিল bin; a wrong drawer or the bin is a
// slip and the file stays; listening to "his own fault — bin it" is a slip;
// no deadly act in lesson 7.2, ruling M7-6), the deal (four of eleven stories,
// a death case at most once and about half the plays, drawers shuffled, the
// own-fault case made in play order — the 2nd, 3rd or 4th case played, never
// a death case — and its lapse never a skipped safety device, the early
// pictures of a case alike whatever its head), the libraries, every spoken
// line listed,
// and the level in the shell: the guide first, tapping him, a full clean play
// (story pages, the coworker refused, a reason after each case and the
// closing reason), a wrong drawer (card, no freeze, the file stays), three
// slips, listening (a slip, the bin, never a freeze), the praise window takes
// no touch, and the gesture hand shows how (never what).
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
import 'package:slm_flutter/features/game/m7_comp_casebook.dart';
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
  rungId: '7.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m7CompCasebookPacks['do_7_2_a']!;
typedef L = M7CasebookLines;
typedef Mk = M7CasebookMistakes;

/// The new art is not in the bundle until the director wires it: tests read
/// it from disk when the bundle does not have it.
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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  await waitChoiceDeck(t);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
  await confirmChoice(t);
}

Finder _file(int i) => find.byKey(ValueKey('file-$i'));
Finder _drawer(M7Head h) => find.byKey(ValueKey('drawer-${h.name}'));
final _bin = find.byKey(const ValueKey('bin'));
final _calendar = find.byKey(const ValueKey('calendar'));
String? _note(WidgetTester t) {
  final f = find.byKey(const ValueKey('story-note'));
  return f.evaluate().isEmpty ? null : t.widget<Text>(f.last).data;
}

Future<void> _openFile(WidgetTester t, int i) async {
  await t.tap(_file(i), warnIfMissed: false);
  await _pump(t, 500);
}

Future<void> _tear(WidgetTester t) async {
  await t.drag(_calendar, const Offset(0, 90), warnIfMissed: false);
  await _pump(t, 600);
}

/// Drags file [i] onto the drawer of [h] (null = the bin).
Future<void> _fileIn(WidgetTester t, int i, M7Head? h) async {
  final to = h == null ? _bin : _drawer(h);
  await t.drag(_file(i), t.getCenter(to) - t.getCenter(_file(i)), warnIfMissed: false);
  await _pump(t, 500);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7CompCasebookPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// The case's reason deck: the right card, ✓, এগিয়ে যান.
Future<void> _reason(WidgetTester t, M7Case c) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, c.ownFault ? L.noFaultRight : L.whyRight[c.head]!);
  await _pump(t, 2000);
}

/// Plays desk file [i] right: open, tear every page (checking the story
/// moves on), the coworker refused on his file, the right drawer, the reason.
Future<void> _playCase(WidgetTester t, int i) async {
  await _openFile(t, i);
  final run = M7CompCasebookProbe.run!;
  final c = run.caseAt(i);
  expect(_note(t), c.noteAt(0), reason: 'file $i opens on its first picture');
  for (var k = 1; k <= c.pages; k++) {
    await _tear(t);
    expect(_note(t), c.noteAt(k), reason: 'file $i page $k');
    expect(find.text(L.pages[k]), findsOneWidget);
  }
  if (i == run.ownFaultCase) {
    await _fileIn(t, i, c.head);
    expect(await _pumpUntil(t, find.byType(CoworkerPeek)), isTrue, reason: 'he comes on the first drag of his file');
    expect(M7CompCasebookProbe.run!.filed, isNot(contains(i)), reason: 'the drag waits for him');
    await _pickRight(t, L.coworker.right);
    await _pump(t, 2600);
  }
  await _fileIn(t, i, c.head);
  expect(M7CompCasebookProbe.run!.filed, contains(i), reason: 'file $i filed');
  await _reason(t, c);
}

int _seedWhere(bool Function(M7CasebookDeal d) ok) => [for (var s = 0; s < 600; s++) s].firstWhere((s) => ok(m7CasebookDeal(math.Random(s))));

void main() {
  group('rules', () {
    test('deal: four different stories, a death case at most once (about half the plays), drawers shuffled, the own-fault case due 2nd–4th in play; plays differ', () {
      final seen = <String>{};
      var deaths = 0;
      final ownAt = <int>{};
      final drawerAt = <M7Head, Set<int>>{for (final h in M7Head.values) h: {}};
      final stories = <String>{};
      final mixes = <String>{};
      const n = 400;
      for (var s = 0; s < n; s++) {
        final d = m7CasebookDeal(math.Random(s));
        expect(d.cases, hasLength(4));
        expect(d.cases.map((c) => c.story.id).toSet(), hasLength(4));
        expect(d.cases.map((c) => c.name).toSet(), hasLength(4));
        final dc = d.cases.where((c) => c.isDeath).length;
        expect(dc, lessThanOrEqualTo(1));
        if (dc == 1) deaths++;
        expect(d.ownFaultAfter, inInclusiveRange(1, 3));
        expect(d.cases.where((c) => c.ownFault), isEmpty, reason: 'made in play, not on the desk');
        expect(d.drawers.toSet(), M7Head.values.toSet());
        for (final (i, h) in d.drawers.indexed) {
          drawerAt[h]!.add(i);
        }
        ownAt.add(d.ownFaultAfter);
        for (final c in d.cases) {
          stories.add(c.story.id);
        }
        mixes.add((d.cases.map((c) => c.head.index).toList()..sort()).join());
        seen.add('${d.cases.map((c) => '${c.story.id}:${c.name}:${c.tag.name}').join(',')}|${d.drawers}|${d.ownFaultAfter}');
      }
      expect(seen.length, greaterThan(n - 5));
      expect(deaths / n, inInclusiveRange(0.35, 0.65), reason: 'a death case in about half the plays');
      expect(ownAt, {1, 2, 3});
      for (final h in M7Head.values) {
        expect(drawerAt[h], {0, 1, 2, 3}, reason: '$h stands in every place');
      }
      expect(stories, L.vignettes.map((v) => v.id).toSet(), reason: 'every story is dealt');
      expect(mixes.length, greaterThan(5), reason: 'the head mix varies (never one per drawer)');
      expect(mixes.where((m) => m == '0123'), isNotEmpty, reason: 'one-per-head happens, but not always');
    });

    test('the stories: eleven (TD 4, PPD 3, PTD 2, death 2); every accident leads to more than one head; the early notes never tell the head', () {
      int count(M7Head h) => L.vignettes.where((v) => v.head == h).length;
      expect(L.vignettes, hasLength(11));
      expect([count(M7Head.td), count(M7Head.ppd), count(M7Head.ptd), count(M7Head.death)], [4, 3, 2, 2]);
      for (final a in M7Accident.values) {
        final heads = {for (final v in L.vignettes) if (v.accident == a) v.head};
        expect(heads.length, greaterThanOrEqualTo(2), reason: '$a');
      }
      for (final v in L.vignettes) {
        expect(v.isDeath, v.accident == null, reason: v.id);
      }
      // The first three pictures (and notes) depend on the accident only.
      for (final own in [false, true]) {
        for (final a in M7Accident.values) {
          final notes = <String>{};
          for (final v in L.vignettes.where((v) => v.accident == a)) {
            final c = M7Case(story: v, name: 'x', tag: M7Tag.permanent, ownFault: own, photo: 0);
            notes.add([for (var k = 0; k < 3; k++) c.noteAt(k)].join('|'));
            expect(c.pages, 3);
            expect(c.stageAt(3), M7Stage.later);
          }
          expect(notes, hasLength(1), reason: '$a own=$own: alike until the last page');
        }
      }
      // No note, page or tag names a head.
      final heads = [for (final h in M7Head.values) L.head(h)];
      final texts = [
        for (final a in M7Accident.values) ...[L.accidentNote(a, ownFault: false), L.accidentNote(a, ownFault: true)],
        L.hospitalNote,
        L.recoveringNote,
        for (final o in M7Outcome.values) L.outcomeNote(o),
        ...L.pages,
      ];
      for (final x in texts) {
        for (final h in heads) {
          expect(x.contains(h), isFalse, reason: '$x names $h');
        }
        expect(x.contains('অক্ষমতা'), isFalse, reason: x);
      }
      // The own-fault lapse is plain hurry or carelessness, never a skipped
      // safety device or rule (the Act's exception would bar the claim).
      for (final a in M7Accident.values) {
        final lapse = L.accidentNote(a, ownFault: true);
        for (final w in ['না পরে', 'না আটকে', 'না দিয়ে', 'ছাড়া', 'ঠেকা', 'গ্লাভস', 'হারনেস', 'হেলমেট', 'নেশা']) {
          expect(lapse.contains(w), isFalse, reason: '$lapse: $w');
        }
      }
      // A death case: one picture, no pages.
      final death = M7Case(story: L.vignettes.firstWhere((v) => v.isDeath), name: 'x', tag: M7Tag.contract, ownFault: false, photo: 0);
      expect(death.pages, 0);
      expect(death.stageAt(0), M7Stage.later);
    });

    test('the own-fault case is made in play order: exactly one, never the first case played, never a death case, the 2nd–4th case; a seen plain file stays plain while a fresh one is left', () {
      final positions = <int>{};
      for (var s = 0; s < 600; s++) {
        final rng = math.Random(1000 + s);
        final d = m7CasebookDeal(math.Random(s));
        final r = M7CasebookRun(d);
        final shown = <int, String>{};
        var position = 0;
        // A random way of playing: sometimes peek at other files first.
        while (!r.done) {
          final left = [for (var i = 0; i < 4; i++) if (!r.filed.contains(i)) i];
          if (rng.nextInt(3) == 0 && left.length > 1) {
            final peek = left[rng.nextInt(left.length)];
            if (r.openFile(peek)) {
              final note = r.caseAt(peek).noteAt(0);
              shown.putIfAbsent(peek, () => note);
              r.closeFile();
            }
          }
          final i = left[rng.nextInt(left.length)];
          final freshLeft = [
            for (final j in left)
              if (j != i && !d.cases[j].isDeath && !r.seen.contains(j)) j,
          ];
          final ownBefore = r.ownFaultCase;
          r.openFile(i);
          final c = r.caseAt(i);
          final before = shown[i];
          if (before != null && c.noteAt(0) != before) {
            // Only the fallback re-pictures a seen file: no fresh one was left.
            expect(ownBefore, isNull);
            expect(r.ownFaultCase, i);
            expect(freshLeft, isEmpty, reason: 'seed $s: a fresh file could have taken it');
          }
          shown[i] = c.noteAt(0);
          if (r.filed.isEmpty) expect(r.ownFaultCase, isNull, reason: 'seed $s: never the first case played');
          position++;
          if (r.ownFaultCase == i) positions.add(position);
          expect(r.file(i, c.head), isNull);
        }
        final own = r.ownFaultCase;
        expect(own, isNotNull, reason: 'seed $s: one own-fault case every play');
        expect(d.cases[own!].isDeath, isFalse);
        expect([for (var i = 0; i < 4; i++) if (r.caseAt(i).ownFault) i], [own]);
      }
      expect(positions, {2, 3, 4}, reason: 'he comes on the 2nd, 3rd or 4th case');
      // Filing in desk order, the 2nd file is his when the deal says so.
      final d = m7CasebookDeal(math.Random(_seedWhere((d) => d.ownFaultAfter == 1 && !d.cases[1].isDeath)));
      final r = M7CasebookRun(d)..openFile(0);
      r.file(0, r.caseAt(0).head);
      r.openFile(1);
      expect(r.ownFaultCase, 1);
    });

    test('open, tear, file: tearing moves one page; a wrong drawer and the bin are slips with their cards; the right drawer files it; pages come back on another file', () {
      final d = m7CasebookDeal(math.Random(5));
      final r = M7CasebookRun(d);
      expect(r.tear(), isFalse, reason: 'no file open');
      expect(r.canFile(0), isFalse);
      expect(r.file(0, d.cases[0].head), isNull);
      expect(r.filed, isEmpty, reason: 'a closed file is not filed');
      expect(r.openFile(0), isTrue);
      final c = d.cases[0];
      for (var k = 0; k < c.pages; k++) {
        expect(r.tear(), isTrue);
      }
      expect(r.tear(), isFalse, reason: 'no page left');
      expect(r.atLastPage, isTrue);
      final wrong = M7Head.values.firstWhere((h) => h != c.head);
      expect(r.file(0, wrong), Mk.wrongHead(c.head), reason: 'the card of what this case had');
      expect(r.file(0, null), Mk.binned);
      expect(r.slips, 2);
      expect(r.caseSlips(0), 2);
      expect(r.filed, isEmpty);
      expect(r.open, 0, reason: 'the file stays open');
      // Another file: its own pages, from the start.
      expect(r.openFile(1), isTrue);
      expect(r.torn, 0);
      expect(r.openFile(1), isFalse, reason: 'already open');
      expect(r.canFile(0), isFalse, reason: 'only the open file');
      expect(r.file(1, d.cases[1].head), isNull);
      expect(r.filed, {1});
      expect(r.open, isNull);
      expect(r.openFile(1), isFalse, reason: 'filed');
      expect(r.caught, hasLength(1));
      r.openFile(0);
      expect(r.file(0, c.head), isNull);
      expect(r.caught, hasLength(1), reason: 'not a clean case');
    });

    test('every head: its drawer and its card; listening is a slip; two slips still pass; the own-fault file tags the no-fault rule', () {
      for (final h in M7Head.values) {
        expect(Mk.wrongHead(h).lessonPoint, 1);
        expect(Mk.wrongHead(h).textBn, contains(h == M7Head.death ? 'মৃত্যু' : L.head(h)));
      }
      final d = m7CasebookDeal(math.Random(9));
      final r = M7CasebookRun(d);
      r.refused();
      expect(r.caught, [L.caughtCall]);
      var listened = false;
      for (var i = 0; i < 4; i++) {
        r.openFile(i);
        if (i == 0) r.file(i, null);
        if (r.ownFaultCase == i) {
          expect(r.listened(), Mk.listened);
          listened = true;
        }
        r.file(i, r.caseAt(i).head);
      }
      expect(listened, isTrue, reason: 'the own-fault case came up');
      expect(r.done, isTrue);
      expect(r.slips, 2);
      expect(r.percent, 70);
      expect(r.passed, isTrue);
      expect(r.caught, contains(L.caughtCall));
      expect(r.caught, isNot(contains(L.caughtNoFault)), reason: 'his file had a slip (listened)');
      r.amountKnown();
      expect(r.caught.last, L.caughtAmount);
      r.slips = 4;
      expect(r.passed, isFalse, reason: '40 %');
      final r2 = M7CasebookRun(d);
      for (var i = 0; i < 4; i++) {
        r2.openFile(i);
        r2.file(i, r2.caseAt(i).head);
      }
      expect(r2.caught, contains(L.caughtNoFault));
      expect(r2.caught.toSet(), hasLength(r2.caught.length));
    });

    test('no deadly act in lesson 7.2 (M7-6): every mistake a slip; keys unique; pictures exist; no unused art; lesson points 0–1', () {
      expect(Mk.all.where((m) => m.deadly), isEmpty);
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.2/m7_comp_casebook/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 1));
      }
      final art = Directory('assets/game/art/m7_comp_casebook').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(art, Mk.all.map((m) => m.art.split('/').last).toSet(), reason: 'no unused art');
      expect(m7CompCasebookPacks.keys, ['do_7_2_a']);
      expect(_pack.quickMs, m7CasebookQuickMs);
    });

    test('English digits only; জল not পানি; ডেড not মৃত; the drawer labels are the Act\'s words', () {
      for (final l in L.allText) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|\s)পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত '), isFalse, reason: l);
      }
      expect(L.progress(1), 'ফাইল 2');
      expect([for (final h in M7Head.values) L.head(h)], ['মৃত্যু', 'স্থায়ী সম্পূর্ণ অক্ষমতা', 'স্থায়ী আংশিক অক্ষমতা', 'অস্থায়ী অক্ষমতা']);
      expect([for (final t in M7Tag.values) L.tag(t)], ['স্থায়ী', 'অস্থায়ী', 'চুক্তিভিত্তিক']);
      expect(L.pages.skip(1), ['কয়েক সপ্তাহ পরে', 'কয়েক মাস পরে', 'অনেক পরে']);
    });

    test('libraries: every reason deck and his deck the same length, big enough; never a right line among the wrongs; deals 1 right of 3', () {
      expectSameLength('why', [...L.allWhyRight, ...L.myths]);
      expectSameLength('amount', [...L.amountRight, ...L.amountWrong]);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      for (final h in M7Head.values) {
        expectLibrary('$h', L.whyRight[h]!, L.myths);
      }
      expectLibrary('no-fault', L.noFaultRight, L.myths);
      expectLibrary('amount', L.amountRight, L.amountWrong);
      for (var s = 0; s < 10; s++) {
        for (final right in [...L.whyRight.values, L.noFaultRight]) {
          final deal = dealChoices(right, L.myths, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      // 'Why this drawer': its own definition, another head's, one myth.
      for (var s = 0; s < 40; s++) {
        for (final h in M7Head.values) {
          final deal = m7WhyFiledDeal(h, math.Random(s));
          expect(deal, hasLength(3));
          expect(deal.where((o) => o.correct).map((o) => o.textBn).single, isIn(L.whyRight[h]!));
          final wrong = [for (final o in deal) if (!o.correct) o.textBn];
          expect(wrong.where((w) => L.myths.contains(w)), hasLength(1), reason: '$h');
          final otherDef = wrong.where((w) => !L.myths.contains(w)).single;
          expect(otherDef, isNot(isIn(L.whyRight[h]!)));
          expect(L.allWhyRight, contains(otherDef));
        }
      }
      final cw = L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.asks, contains('কী করবেন?'));
      expect(L.amountRight.every((x) => x.contains('বয়স') && x.contains('মাসিক বেতন')), isTrue, reason: 'lesson point 2');
    });

    test('spoken lines: his exit is recorded; his new push and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.coworker.recordedLines, [L.coworkerLine, L.coworkerExit]);
      expect(L.newRivalLines, ['ওর নিজের ভুলেই তো হয়েছে! ও কিছুই পাবে না — ফাইলটা বাতিলে ফেলো।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            L.openFirst,
            L.noMorePages,
            ...L.tapWhy,
            L.whyFiled,
            L.whyOwnFault,
            L.whyAmount,
            ...L.coworker.asks,
            L.callHeld,
            L.allSet,
            L.quick,
            L.fail,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_comp_casebook: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the desk, the shuffled drawers and the bin', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7CompCasebookPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m7CasebookDeal(math.Random(3));
      for (var i = 0; i < 4; i++) {
        expect(_file(i), findsOneWidget);
        expect(find.text(d.cases[i].name), findsOneWidget);
      }
      expect(_bin, findsOneWidget);
      // The drawers in the dealt order (top row left → right, then the bottom row).
      final c = [for (final h in d.drawers) t.getCenter(_drawer(h))];
      expect(c[0].dx, lessThan(c[1].dx));
      expect(c[2].dx, lessThan(c[3].dx));
      expect(c[0].dy, lessThan(c[2].dy));
      expect(_note(t), isNull, reason: 'no story before a file is opened');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time; a swipe with no file asks for a file', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(L.askOpen)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _tear(t);
      expect(c.read(guideDirectorProvider).line, L.openFirst);
      await _close(t, c);
    });

    for (final want in ['death', 'no death']) {
      testWidgets('flow ($want): story pages, the coworker refused, the right drawers and reasons, the closing reason → pass', (t) async {
        final seed = _seedWhere((d) => d.cases.any((c) => c.isDeath) == (want == 'death'));
        final d = m7CasebookDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 4; i++) {
          await _playCase(t, i);
        }
        expect(d.cases[M7CompCasebookProbe.run!.ownFaultCase!].isDeath, isFalse);
        // The closing reason (once a play).
        expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the closing reason');
        await _pump(t, 700);
        await _pickRight(t, L.amountRight);
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.2/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.2/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.text(L.caughtAmount), findsOneWidget);
        expect(find.text(L.caughtNoFault), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a wrong drawer: its card (no freeze), the file stays open; then the right drawer; the praise window takes no touch', (t) async {
      final seed = _seedWhere((d) => !d.cases[0].isDeath);
      final d = m7CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      final first = d.cases[0];
      await _openFile(t, 0);
      for (var k = 0; k < first.pages; k++) {
        await _tear(t);
      }
      final wrong = M7Head.values.firstWhere((h) => h != first.head);
      await _fileIn(t, 0, wrong);
      await _pump(t, 400);
      expect(find.byType(FreezeFrame), findsNothing, reason: 'no deadly act here');
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.wrongHead(first.head).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(M7CompCasebookProbe.run!.open, 0, reason: 'the file stays open');
      expect(_note(t), first.noteAt(first.pages), reason: 'at the same page');
      await _fileIn(t, 0, first.head);
      // The praise window and the open deck: the calendar takes no swipe
      // (no "open a file first", nothing torn), no card.
      for (var k = 0; k < 3; k++) {
        await t.drag(_calendar, const Offset(0, 90), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(M7CompCasebookProbe.run!.open, isNull);
      expect(c.read(guideDirectorProvider).line, isNot(L.openFirst));
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, first);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.wrongHead(first.head).key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out (a wrong drawer, the bin, a wrong drawer); never a freeze', (t) async {
      final seed = _seedWhere((d) => true);
      final d = m7CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      final first = d.cases[0];
      final wrongs = M7Head.values.where((h) => h != first.head).toList();
      await _openFile(t, 0);
      for (final h in [wrongs[0], null]) {
        await _fileIn(t, 0, h);
        await _pump(t, 400);
        expect(find.byType(MistakeCard), findsOneWidget);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 600);
      }
      expect(find.text(Mk.binned.textBn), findsNothing);
      await _fileIn(t, 0, wrongs[1]);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await _close(t, c);
    });

    testWidgets('his file: the drag waits for him; listening is a slip (the bin, no freeze); he comes once; then it is filed right', (t) async {
      final seed = _seedWhere((d) => d.ownFaultAfter == 1 && !d.cases[0].isDeath && !d.cases[1].isDeath);
      final d = m7CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _openFile(t, 0);
      await _fileIn(t, 0, d.cases[0].head);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not on another file');
      await _reason(t, d.cases[0]);
      await _openFile(t, 1);
      expect(M7CompCasebookProbe.run!.ownFaultCase, 1, reason: 'the 2nd case played');
      final own = M7CompCasebookProbe.run!.caseAt(1);
      expect(own.ownFault, isTrue);
      expect(_note(t), L.accidentNote(own.story.accident!, ownFault: true), reason: 'his own lapse shows');
      await _fileIn(t, 1, own.head);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek)), isTrue);
      expect(M7CompCasebookProbe.run!.filed, {0});
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 400);
      await _pickWrong(t, L.coworker.wrong);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(Mk.listened.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(M7CompCasebookProbe.run!.open, 1, reason: 'the file comes back');
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listened.key);
      await _fileIn(t, 1, own.head);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he comes once a play');
      expect(M7CompCasebookProbe.run!.filed, {0, 1});
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      expect(find.text(L.whyOwnFault), findsWidgets);
      await _pickRight(t, L.noFaultRight);
      await _close(t, c);
    });

    testWidgets('the first file played is never his, whatever its desk slot; going on dragging while he talks refuses him', (t) async {
      CoworkerTiming.debugReadHoldInTests = true; // beat 1 holds his caption, as on a phone
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final seed = _seedWhere((d) => d.ownFaultAfter == 1 && !d.cases[1].isDeath && !d.cases[2].isDeath);
      final d = m7CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      // Desk slot 1 opened first: a plain story, no coworker on it.
      await _openFile(t, 1);
      expect(M7CompCasebookProbe.run!.ownFaultCase, isNull);
      expect(_note(t), L.accidentNote(d.cases[1].story.accident!, ownFault: false));
      await _fileIn(t, 1, d.cases[1].head);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'never on the first case played');
      expect(M7CompCasebookProbe.run!.filed, {1});
      await _reason(t, d.cases[1]);
      // The next file played is his.
      await _openFile(t, 2);
      expect(M7CompCasebookProbe.run!.ownFaultCase, 2);
      final own = M7CompCasebookProbe.run!.caseAt(2);
      await _fileIn(t, 2, own.head);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'beat 1: he is still talking');
      await _fileIn(t, 2, own.head);
      await _pump(t, 2500);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'he is gone, no deck');
      expect(find.byType(MistakeCard), findsNothing);
      expect(M7CompCasebookProbe.run!.caught, contains(L.caughtCall));
      await _fileIn(t, 2, own.head);
      expect(M7CompCasebookProbe.run!.filed, {1, 2});
      await _reason(t, own);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a death file has no pages: a swipe says so; tearing past the last page says so too', (t) async {
      final seed = _seedWhere((d) => d.cases[0].isDeath);
      final d = m7CasebookDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _openFile(t, 0);
      expect(_note(t), L.outcomeNote(d.cases[0].story.outcome));
      expect(find.byKey(const ValueKey('calendar-face')), findsNothing);
      await _tear(t);
      expect(c.read(guideDirectorProvider).line, L.noMorePages);
      expect(M7CompCasebookProbe.run!.torn, 0);
      // Pages come back when another file is opened.
      await _openFile(t, 1);
      await _tear(t);
      expect(M7CompCasebookProbe.run!.torn, 1);
      await _openFile(t, 2);
      expect(M7CompCasebookProbe.run!.torn, 0);
      expect(find.text(L.pages[0]), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('gesture hints: a sweep over the files; a swipe on the calendar; then a sweep over every drawer and the bin, then a short nudge up — never at a drawer', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _seedWhere((d) => !d.cases[0].isDeath);
      final c = await _open(t, seed);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'the hand after idle');
      expect(scene().debugOptions, hasLength(4), reason: 'every file on the desk');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      await _openFile(t, 0);
      expect(scene().showing, isFalse);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'the calendar swipe');
      expect(scene().debugOptions, isEmpty);
      final cal = t.getRect(_calendar);
      expect(cal.contains(scene().debugFrame!.trailFrom ?? scene().debugFrame!.tip), isTrue, reason: 'on the calendar pad');
      await _tear(t);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'the drawers and the bin');
      expect(scene().debugOptions, hasLength(5), reason: 'all four drawers and the bin alike');
      // Wait for the hand to come back: a nudge of the file straight up.
      var nudged = false;
      for (var k = 0; k < 40 && !nudged; k++) {
        await _pump(t, 1000);
        if (scene().showing && scene().debugOptions.isEmpty) nudged = true;
      }
      expect(nudged, isTrue, reason: 'the drag nudge comes next');
      final f = scene().debugFrame!;
      final file = t.getRect(_file(0));
      expect(file.contains(f.trailFrom!), isTrue, reason: 'it starts on the file');
      final cabBottom = t.getRect(find.byKey(const ValueKey('cabinet'))).bottom;
      expect(f.tip.dy, greaterThan(cabBottom), reason: 'never up into a drawer');
      await _close(t, c);
    });
  });
}
