// Lesson 7.10 (একজন 'সার্টিফায়েড' লাইনম্যান), কাজ 1 "যোগ্য হাতে কাজ":
// the rules (a wallet of five sleeves per worker, the papers each job asks
// for, a worker dropped on a card, a card held in the tray; nothing judged
// before 'শিফট শুরু'; a man without the live-line certificate on the live-line
// card is deadly; HV joint without the jointing certification, the contractor
// job without a workman permit, a line job to the helper off the register or
// to the fresh joiner with an empty logbook, a needless hold are slips), the
// deal (three rounds of 3/4/5 people, the live-line card in round 2 or 3, a
// full correct roster always exists, a job nobody can take sometimes, looks
// apart from papers), the libraries, every spoken line listed, and the level
// in the shell: the guide first, a full clean play (wallets, drags, a hold,
// the coworker refused, a reason each round), a slip (its card, the card goes
// back), three slips, the deadly freeze, listening (deadly), and the gesture
// hand shows how (never what).
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
import 'package:slm_flutter/features/game/m7_crew_papers.dart';
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
  rungId: '7.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '7.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 0,
  doCount: 1,
);

final _pack = m7CrewPapersPacks['do_7_10_a']!;
typedef L = M7PapersLines;
typedef Mk = M7PapersMistakes;

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

M7PapersRun get _run => M7CrewPapersProbe.run!;
Finder _person(int i) => find.byKey(ValueKey('person-${_run.roundIdx}-$i'));
Finder _job(int j) => find.byKey(ValueKey('job-$j'));
Finder _held(int j) => find.byKey(ValueKey('held-$j'));
final _tray = find.byKey(const ValueKey('tray'));
final _shift = find.byKey(const ValueKey('shift-start'));
final _sleeve = find.byKey(const ValueKey('wallet-sleeve'));
final _sleeveTitle = find.byKey(const ValueKey('sleeve-title'));
String? _title(WidgetTester t) => _sleeveTitle.evaluate().isEmpty ? null : t.widget<Text>(_sleeveTitle.last).data;

Future<void> _openWallet(WidgetTester t, int i) async {
  await t.tap(_person(i), warnIfMissed: false);
  await _pump(t, 500);
}

Future<void> _swipeLeft(WidgetTester t) async {
  await t.drag(_sleeve, const Offset(-120, 0), warnIfMissed: false);
  await _pump(t, 500);
}

Future<void> _putOn(WidgetTester t, int p, int j) async {
  await t.drag(_person(p), t.getCenter(_job(j)) - t.getCenter(_person(p)), warnIfMissed: false);
  await _pump(t, 500);
}

Future<void> _toTray(WidgetTester t, int j) async {
  await t.drag(_job(j), t.getCenter(_tray) - t.getCenter(_job(j)), warnIfMissed: false);
  await _pump(t, 500);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {Size size = const Size(784, 1700)}) async {
  t.view.physicalSize = size;
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M7CrewPapersPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// A full correct roster of [r]: per card the person who takes it (distinct,
/// qualified), or null = held (nobody can take it).
List<int?> _plan(M7Round r) {
  final qual = [
    for (final j in r.jobs) [for (var i = 0; i < r.people.length; i++) if (Mk.fault(r.people[i], j) == null) i],
  ];
  final out = List<int?>.filled(r.jobs.length, null);
  bool go(int k, Set<int> used) {
    if (k == qual.length) return true;
    if (qual[k].isEmpty) return go(k + 1, used);
    for (final p in qual[k]) {
      if (used.contains(p)) continue;
      out[k] = p;
      if (go(k + 1, {...used, p})) return true;
    }
    out[k] = null;
    return false;
  }

  expect(go(0, {}), isTrue, reason: 'a roster exists');
  return out;
}

/// Handles the coworker if he has come: his deck's right card, his exit.
Future<bool> _meetHim(WidgetTester t) async {
  if (!await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 1500)) return false;
  await _pickRight(t, L.coworker.right);
  await _pump(t, 2600);
  return true;
}

/// Does [act]; if the coworker cut in, refuses him and does it again.
Future<void> _doHeld(WidgetTester t, Future<void> Function() act) async {
  await act();
  if (await _meetHim(t)) await act();
}

/// Plays the current round right: a wallet or two (the swipes checked), the
/// drags, the tray, 'শিফট শুরু' (the coworker refused when he comes), then the
/// round's reason.
Future<void> _playRound(WidgetTester t, {bool checkWallet = false, ProviderContainer? c}) async {
  final r = _run.round;
  final plan = _plan(r);
  if (checkWallet) {
    final p = [for (var i = 0; i < r.people.length; i++) i].firstWhere((i) => i != r.target);
    await _openWallet(t, p);
    final titles = <String>[];
    for (var k = 0; k < 5; k++) {
      titles.add(_title(t)!);
      expect(titles.last, L.sleeveTitle[r.people[p].sleeves[k]], reason: 'the dealt sleeve order');
      if (k < 4) await _swipeLeft(t);
    }
    expect(titles.toSet(), hasLength(5), reason: 'five different sleeves');
    expect(find.byKey(const ValueKey('sleeve-dogear')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('wallet-close')), warnIfMissed: false);
    await _pump(t, 400);
    expect(find.byKey(const ValueKey('wallet')), findsNothing);
    expect(find.byKey(const ValueKey('dogear')), findsOneWidget, reason: 'his tile shows he was opened');
  }
  for (var j = 0; j < r.jobs.length; j++) {
    final p = plan[j];
    if (p == null) {
      await _doHeld(t, () => _toTray(t, j));
      expect(_run.isHeld(j), isTrue, reason: 'card $j in the tray');
    } else {
      await _doHeld(t, () => _putOn(t, p, j));
      expect(_run.personOn(j), p, reason: 'card $j');
    }
  }
  expect(_shift, findsOneWidget, reason: 'every card filled or held');
  await _doHeld(t, () async {
    await t.tap(_shift, warnIfMissed: false);
    await _pump(t, 600);
  });
  await _pump(t, 4200);
  expect(_run.roundDone, isTrue);
  expect(find.byType(MistakeCard), findsNothing);
  final why = _run.whyKind();
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the round\'s reason');
  await _pump(t, 700);
  if (c != null) {
    for (var ms = 0; ms < 3000 && c.read(guideDirectorProvider).line != L.whyQ[why]; ms += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(c.read(guideDirectorProvider).line, L.whyQ[why], reason: 'the guide asks the key decision of the round');
  }
  await _pickRight(t, L.whyRight[why]!);
  await _pump(t, 2000);
}

int _seedWhere(bool Function(M7PapersDeal d) ok) => [for (var s = 0; s < 800; s++) s].firstWhere((s) => ok(m7PapersDeal(math.Random(s))));

void main() {
  group('rules', () {
    test('deal: rounds of 3/4/5 people (the player\'s own wallet only in round 3) and 2/3/3 cards; the live-line card in round 2 or 3; a full correct roster; plays differ', () {
      final seen = <String>{};
      var liveRound1 = 0;
      var avail = 0;
      var nobodyLate = 0;
      var nobodyLive = 0;
      final targets = <int>{};
      final jobMix = <String>{};
      final profs = <M7Prof>{};
      final looks = <int>{};
      final liveAt = <int>{};
      const n = 400;
      for (var s = 0; s < n; s++) {
        final d = m7PapersDeal(math.Random(s));
        expect(d.rounds.map((r) => r.people.length), [3, 4, 5]);
        expect(d.rounds.map((r) => r.jobs.length), [2, 3, 3]);
        expect(d.liveRound, inInclusiveRange(1, 2));
        expect([for (final (i, r) in d.rounds.indexed) if (r.hasLive) i], [d.liveRound], reason: 'the live-line card in exactly one of rounds 2, 3');
        expect(d.rounds.first.hasLive, isFalse);
        final names = <String>{};
        for (final (i, r) in d.rounds.indexed) {
          expect(r.jobs.toSet(), hasLength(r.jobs.length), reason: 'no card twice');
          expect(r.people.where((p) => p.isPlayer), hasLength(i == 2 ? 1 : 0));
          expect(r.people.map((p) => p.look).toSet(), hasLength(r.people.length), reason: 'looks differ in a round');
          for (final p in r.people) {
            expect(p.sleeves.toSet(), M7Sleeve.values.toSet(), reason: 'five sleeves each');
            expect(p.sleeves, hasLength(5));
            if (!p.isPlayer) expect(names.add(p.name), isTrue, reason: 'names differ');
            profs.add(p.prof);
            looks.add(p.look);
            expect(p.look, lessThan(m7Looks.length));
          }
          // A full correct roster: every card someone can take, taken by a distinct qualified person.
          final plan = _plan(r);
          for (final (j, p) in plan.indexed) {
            if (p != null) expect(Mk.fault(r.people[p], r.jobs[j]), isNull);
          }
          expect(plan.where((p) => p != null).toSet(), hasLength(plan.where((p) => p != null).length), reason: 'distinct');
          final nobody = [for (var j = 0; j < r.jobs.length; j++) if (plan[j] == null) r.jobs[j]];
          expect(nobody.length, lessThanOrEqualTo(1));
          if (i == 2 && nobody.isNotEmpty) nobodyLate++;
          if (nobody.contains(M7Job.live)) nobodyLive++;
          if (i < 2) expect(nobody.where((j) => j != M7Job.live), isEmpty, reason: 'rounds 1–2: only a live-line card can be left to no one');
          jobMix.add(r.jobs.map((j) => j.name).join(','));
        }
        final r = d.rounds[d.liveRound];
        liveAt.add(d.liveRound);
        final certHolder = r.people.any((p) => p.certs.contains(M7Cert.live));
        expect(certHolder, d.liveAvailable);
        if (certHolder) avail++;
        if (d.liveRound == 1) liveRound1++;
        // The coworker's target: dealt, without the live-line certificate (maybe the player).
        expect(r.target, isNotNull);
        expect(r.people[r.target!].certs.contains(M7Cert.live), isFalse);
        targets.add(r.people[r.target!].isPlayer ? -1 : r.target!);
        for (final (i, rr) in d.rounds.indexed) {
          if (i != d.liveRound) expect(rr.target, isNull);
        }
        seen.add([
          for (final rr in d.rounds) '${rr.jobs.map((j) => j.name).join(',')}:${rr.people.map((p) => '${p.name}${p.prof.name}${p.look}${p.sleeves.map((x) => x.index).join()}').join(',')}',
        ].join('|'));
      }
      expect(seen.length, greaterThan(n - 5), reason: 'plays differ');
      expect(liveRound1 / n, inInclusiveRange(0.35, 0.65));
      expect(avail / n, inInclusiveRange(0.35, 0.65), reason: 'someone holds the live-line certificate in about half the plays');
      expect(nobodyLate / n, inInclusiveRange(0.25, 0.8), reason: 'round 3 sometimes has a job nobody can take');
      expect(nobodyLive, greaterThan(40));
      expect(targets, containsAll(<int>{0, 1, 2}), reason: 'the target varies');
      expect(targets, contains(-1), reason: 'sometimes the player himself');
      expect(jobMix.length, greaterThan(8), reason: 'the cards and their board order vary');
      expect(profs, M7Prof.values.toSet(), reason: 'every profile is dealt');
      expect(looks.length, m7Looks.length, reason: 'every look is dealt');
      expect(liveAt, {1, 2});
    });

    test('a look never tells the papers: every look is dealt with every profile', () {
      final pairs = <String>{};
      for (var s = 0; s < 600; s++) {
        for (final r in m7PapersDeal(math.Random(s)).rounds) {
          for (final p in r.people) {
            pairs.add('${p.look}:${p.prof.name}');
          }
        }
      }
      expect(pairs.length, greaterThan(m7Looks.length * M7Prof.values.length * 0.9));
    });

    test('the papers of each profile: certificates, permit, register and logbook', () {
      final seenProf = <M7Prof, M7Person>{};
      for (var s = 0; s < 300; s++) {
        for (final r in m7PapersDeal(math.Random(s)).rounds) {
          for (final p in r.people) {
            seenProf[p.prof] = p;
          }
        }
      }
      final live = seenProf[M7Prof.live]!;
      expect(live.certs, contains(M7Cert.live));
      expect([live.hasPermit, live.hasIti, live.onRegister], [true, true, true]);
      expect(seenProf[M7Prof.jointer]!.certs, contains(M7Cert.joint));
      expect(seenProf[M7Prof.jointer]!.certs, isNot(contains(M7Cert.live)));
      final vet = seenProf[M7Prof.veteran]!;
      expect(vet.certs, isEmpty);
      expect([vet.hasPermit, vet.hasIti], [false, false]);
      expect(vet.logMonths ~/ 12, inInclusiveRange(18, 25), reason: '20 years of hands');
      final fresh = seenProf[M7Prof.fresh]!;
      expect([fresh.hasIti, fresh.hasPermit, fresh.logMonths, fresh.onRegister], [true, false, 0, true]);
      final helper = seenProf[M7Prof.helper]!;
      expect([helper.onRegister, helper.trainingOngoing, helper.hasPermit], [false, true, false]);
      expect(helper.logMonths, greaterThan(0));
      final fa = seenProf[M7Prof.firstAid]!;
      expect(fa.certs, {M7Cert.firstAid});
      expect(fa.hasPermit, isFalse);
      for (final p in seenProf.values) {
        expect(p.certs.contains(M7Cert.live), p.prof == M7Prof.live);
      }
    });

    test('what each job asks: live-line needs the live-line certificate (else deadly); the others slip with the card of what THIS man lacks', () {
      M7Person who(M7Prof prof) {
        for (var s = 0; s < 400; s++) {
          for (final r in m7PapersDeal(math.Random(s)).rounds) {
            for (final p in r.people) {
              if (p.prof == prof && !p.isPlayer) return p;
            }
          }
        }
        throw StateError('$prof');
      }

      final live = who(M7Prof.live), jointer = who(M7Prof.jointer), permit = who(M7Prof.permit), vet = who(M7Prof.veteran);
      final fresh = who(M7Prof.fresh), helper = who(M7Prof.helper), fa = who(M7Prof.firstAid);
      // Live-line: only the certificate; experience, ITI, first aid, a fresh man or a helper = deadly.
      expect(Mk.fault(live, M7Job.live), isNull);
      for (final p in [jointer, permit, vet, fresh, helper, fa]) {
        expect(Mk.fault(p, M7Job.live), Mk.liveUntrained, reason: '${p.prof}');
      }
      expect(Mk.liveUntrained.deadly, isTrue);
      // HV joint.
      expect(Mk.fault(jointer, M7Job.joint), isNull);
      for (final p in [live, permit, vet, fa]) {
        expect(Mk.fault(p, M7Job.joint), Mk.joint, reason: '${p.prof}');
      }
      // The contractor card: the workman permit (ITI, company ID, first aid do not do).
      for (final p in [live, jointer, permit]) {
        expect(Mk.fault(p, M7Job.contractor), isNull, reason: '${p.prof}');
      }
      for (final p in [vet, fa]) {
        expect(Mk.fault(p, M7Job.contractor), Mk.contractor, reason: '${p.prof}');
      }
      // The helper (off the register) and the fresh joiner (empty logbook): any line job a slip.
      for (final j in [M7Job.shutdown, M7Job.contractor, M7Job.joint]) {
        expect(Mk.fault(helper, j), Mk.helper);
        expect(Mk.fault(fresh, j), Mk.fresh);
      }
      // The shutdown job: anyone on the register with a logbook.
      for (final p in [live, jointer, permit, vet, fa]) {
        expect(Mk.fault(p, M7Job.shutdown), isNull, reason: '${p.prof}');
      }
      // Slips are slips.
      for (final m in [Mk.joint, Mk.contractor, Mk.helper, Mk.fresh, Mk.hold]) {
        expect(m.deadly, isFalse);
      }
    });

    test('place, hold, release: one person per card, one card per person; a swap sends the old man back; a held card comes off the tray', () {
      final d = m7PapersDeal(math.Random(4));
      final r = M7PapersRun(d);
      expect(r.ready, isFalse);
      expect(r.place(0, 0), isTrue);
      expect(r.place(1, 0), isTrue, reason: 'replaces him');
      expect(r.personOn(0), 1);
      expect(r.jobOf(0), isNull, reason: 'he is back in the yard');
      expect(r.place(1, 1), isTrue, reason: 'he leaves his first card');
      expect(r.personOn(0), isNull);
      expect(r.personOn(1), 1);
      expect(r.hold(0), isTrue);
      expect(r.isHeld(0), isTrue);
      expect(r.ready, isTrue, reason: 'one card with a man, one in the tray');
      expect(r.place(2, 0), isTrue);
      expect(r.isHeld(0), isFalse, reason: 'a man on it takes it off the tray');
      expect(r.release(0), isTrue);
      expect(r.release(0), isFalse);
      expect(r.hold(0), isTrue);
      expect(r.hold(1), isTrue);
      expect(r.personOn(1), isNull, reason: 'holding a card frees its man');
      expect(r.free, [0, 1, 2]);
      expect(r.placedCount, 2);
    });

    test('judging: a clean roster passes card by card in board order; nothing before; a right hold is stamped; ◆ tags say which paper fitted which job', () {
      final d = m7PapersDeal(math.Random(4));
      final plan = _plan(d.rounds.first);
      final run = M7PapersRun(d);
      expect(run.ready, isFalse, reason: 'nothing placed: no shift');
      for (final (j, p) in plan.indexed) {
        run.place(p!, j);
      }
      expect(run.ready, isTrue);
      final order = <int>[];
      for (var k = 0; k < plan.length; k++) {
        final v = run.judgeNext()!;
        expect(v.result, M7Result.ok);
        order.add(v.job);
      }
      expect(order, [0, 1], reason: 'board order');
      expect(run.judgeNext(), isNull);
      expect(run.roundDone, isTrue);
      expect(run.slips, 0);
      expect(run.caught, hasLength(2));
      expect(run.caught.toSet(), hasLength(2));
      expect(run.finished, isFalse);
      run.nextRound();
      expect(run.roundIdx, 1);
      expect(run.placedCount, 0);
      expect(run.locked, isEmpty);
    });

    test('a slip: the card of what this man lacks, the card goes back empty and the round stays open; a retry right locks it', () {
      final d = m7PapersDeal(math.Random(7));
      final r = M7PapersRun(d);
      // Find a faulty person for card 0 of round 1.
      final round = r.round;
      final bad = [for (var i = 0; i < round.people.length; i++) if (Mk.fault(round.people[i], round.jobs[0]) != null) i];
      final plan = _plan(round);
      if (bad.isNotEmpty) {
        expect(r.place(bad.first, 0), isTrue);
        for (var j = 1; j < round.jobs.length; j++) {
          if (plan[j] != null && plan[j] != bad.first) r.place(plan[j]!, j);
        }
        final v = r.judgeNext()!;
        expect(v.result, M7Result.slip);
        expect(v.mistake, Mk.fault(round.people[bad.first], round.jobs[0]));
        expect(r.slips, 1);
        expect(r.personOn(0), isNull, reason: 'back in the yard');
        expect(r.ready, isFalse, reason: 'card 0 is empty again');
        expect(r.roundDone, isFalse);
      }
      expect(r.percent, bad.isNotEmpty ? 85 : 100);
    });

    test('holds: a hold with a free qualified man is a needless-hold slip; a hold nobody can fill is stamped; "free" means not on any card', () {
      // A round whose card 0 someone can take.
      final d = m7PapersDeal(math.Random(3));
      final r = M7PapersRun(d);
      final plan = _plan(r.round);
      expect(plan[0], isNotNull);
      r.hold(0);
      r.place(plan[1]!, 1);
      var v = r.judgeNext()!;
      expect(v.result, M7Result.slip);
      expect(v.mistake, Mk.hold);
      expect(r.isHeld(0), isFalse, reason: 'back on the board');
      expect(r.slips, 1);
      // The only qualified man is used on the other card: nobody free, the hold is right.
      final d2 = m7PapersDeal(math.Random(0));
      final seed = _seedWhere((d) {
        final rr = d.rounds[d.liveRound];
        return !d.liveAvailable && _plan(rr).contains(null);
      });
      final dl = m7PapersDeal(math.Random(seed));
      final run = M7PapersRun(dl);
      for (var k = 0; k < dl.liveRound; k++) {
        final pl = _plan(run.round);
        for (final (j, p) in pl.indexed) {
          run.place(p!, j);
        }
        while (run.judgeNext() != null) {}
        run.nextRound();
      }
      final round = run.round;
      final pl = _plan(round);
      for (final (j, p) in pl.indexed) {
        if (p == null) {
          run.hold(j);
        } else {
          run.place(p, j);
        }
      }
      expect(run.ready, isTrue);
      final results = <M7Result>[];
      M7Verdict? x;
      while ((x = run.judgeNext()) != null) {
        results.add(x!.result);
      }
      expect(results, contains(M7Result.okHold));
      expect(results.where((e) => e == M7Result.ok), hasLength(2));
      expect(run.roundDone, isTrue);
      expect(run.slips, 0);
      expect(run.caught, contains(L.caughtHold));
      expect(d2.rounds, hasLength(3));
    });

    test('deadly: an uncertified man on the live-line card ends the run; listening puts his target there; no clean pass after', () {
      final seed = _seedWhere((d) => d.liveRound == 1);
      final d = m7PapersDeal(math.Random(seed));
      final r = M7PapersRun(d);
      for (final (j, p) in _plan(r.round).indexed) {
        r.place(p!, j);
      }
      while (r.judgeNext() != null) {}
      r.nextRound();
      final round = r.round;
      final live = round.liveJob;
      final bad = round.people.indexed.firstWhere((e) => !e.$2.certs.contains(M7Cert.live)).$1;
      r.place(bad, live);
      for (var j = 0; j < round.jobs.length; j++) {
        if (j == live) continue;
        final free = r.free.where((i) => Mk.fault(round.people[i], round.jobs[j]) == null);
        if (free.isNotEmpty) {
          r.place(free.first, j);
        } else {
          r.hold(j);
        }
      }
      expect(r.ready, isTrue);
      final results = <M7Verdict>[];
      M7Verdict? v;
      while ((v = r.judgeNext()) != null) {
        results.add(v!);
        if (r.ended) break;
      }
      expect(results.last.result, M7Result.deadly);
      expect(results.last.mistake, Mk.liveUntrained);
      expect(r.deadly, Mk.liveUntrained);
      expect(r.ended, isTrue);
      expect(r.passed, isFalse);
      // Listening: the target onto the card, deadly.
      final r2 = M7PapersRun(d);
      for (final (j, p) in _plan(r2.round).indexed) {
        r2.place(p!, j);
      }
      while (r2.judgeNext() != null) {}
      r2.nextRound();
      final t = r2.round.target!;
      expect(r2.listened(), Mk.listenedLive);
      expect(r2.personOn(r2.round.liveJob), t);
      expect(r2.deadly, Mk.listenedLive);
      expect(r2.ended, isTrue);
    });

    test('slips cost 15 % each; three slips still count 55 % and pass only the mark rule; the reason picks the live-line decision when there is one, else a job or the man left at home', () {
      final d = m7PapersDeal(math.Random(11));
      final r = M7PapersRun(d);
      r.slips = 3;
      expect(r.percent, 55);
      r.slips = 4;
      expect(r.percent, 40);
      // The reason's key decision.
      final seed = _seedWhere((d) => d.liveRound == 2 && _plan(d.rounds[2]).every((p) => p != null));
      final dl = m7PapersDeal(math.Random(seed));
      final run = M7PapersRun(dl);
      for (var k = 0; k < 2; k++) {
        for (final (j, p) in _plan(run.round).indexed) {
          run.place(p!, j);
        }
        while (run.judgeNext() != null) {}
        final why = run.whyKind();
        expect(why, isNot(anyOf(M7Why.liveGiven, M7Why.liveHeld)));
        if (k == 0) run.nextRound();
      }
      run.nextRound();
      for (final (j, p) in _plan(run.round).indexed) {
        run.place(p!, j);
      }
      while (run.judgeNext() != null) {}
      expect(run.whyKind(), M7Why.liveGiven);
      expect(run.finished, isTrue);
      expect(run.passed, isTrue);
      expect(run.percent, 100);
    });

    test('mistakes: the live-line card and listening are deadly, the five others slips; keys unique; pictures exist; no unused art; lesson points 0–2', () {
      expect(Mk.all.where((m) => m.deadly).map((m) => m.key), Mk.deadlyKeys);
      expect(Mk.deadlyKeys, [Mk.liveUntrained.key, Mk.listenedLive.key]);
      expect(Mk.all.where((m) => !m.deadly), hasLength(5));
      expect(Mk.all.map((m) => m.key).toSet(), hasLength(Mk.all.length));
      for (final m in Mk.all) {
        expect(m.key, startsWith('7.10/m7_crew_papers/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 2));
        expect(m.textBn.contains('অন্যায়'), isFalse);
      }
      // The slip cards say it is against the law, never that it is allowed (M7-5).
      for (final m in [Mk.joint, Mk.helper, Mk.fresh]) {
        expect(m.textBn, contains('আইনের লঙ্ঘন'));
      }
      final art = Directory('assets/game/art/m7_crew_papers').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(art, Mk.all.map((m) => m.art.split('/').last).toSet(), reason: 'no unused art');
      expect(m7CrewPapersPacks.keys, ['do_7_10_a']);
      expect(_pack.quickMs, m7PapersQuickMs);
    });

    test('English digits only; জল not পানি; ডেড not মৃত; the job cards and the tray are the spec\'s words', () {
      for (final l in L.allText) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(RegExp(r'(^|\s)পানি').hasMatch(l), isFalse, reason: l);
        expect(l.contains('মৃত '), isFalse, reason: l);
        expect(l.contains('১৮') || l.contains('under'), isFalse, reason: 'no age rule (X3): $l');
      }
      expect(L.progress(1), 'দফা 2');
      expect(L.jobText[M7Job.live], '11 kV লাইভ লাইন কাজ');
      expect(L.jobText[M7Job.joint], 'HV কেবিল জয়েন্ট');
      expect(L.jobText[M7Job.shutdown], 'শাটডাউনে লাইন মেরামত');
      expect(L.jobText[M7Job.contractor], 'ঠিকাদারের লাইন রক্ষণাবেক্ষণ — শর্ত: ওয়ার্কম্যান পারমিট');
      expect(L.tray, 'আজ নয় — প্রশিক্ষিত লোক চাই');
      // The only card that names a paper is the contractor's printed condition.
      for (final j in [M7Job.shutdown, M7Job.joint, M7Job.live]) {
        expect(L.jobText[j]!.contains('সার্টিফিকেট'), isFalse);
        expect(L.jobText[j]!.contains('পারমিট'), isFalse);
      }
      expect(L.logbookText(0), L.empty);
      expect(L.logbookText(5), 'কাজের অভিজ্ঞতা: 5 মাস');
      expect(L.logbookText(240), 'কাজের অভিজ্ঞতা: 20 বছর');
      expect(L.permitNo(4821), 'নম্বর WP-4821');
      expect(L.coworkerLine, 'লাইসেন্স বা সার্টিফিকেট তো শুধু কাগজে দেখানোর জন্য, আসল তো হলো কাজের অভিজ্ঞতা।', reason: 'myth 2 word for word');
    });

    test('libraries: every reason deck and his deck the same length, big enough; never a right line among the wrongs; deals 1 right of 3', () {
      for (final e in L.whyRight.entries) {
        expectSameLength('why ${e.key.name}', [...e.value, ...L.myths]);
        expectLibrary('why ${e.key.name}', e.value, L.myths);
      }
      expectSameLength('why all', [...L.allWhyRight, ...L.myths], ratio: 1.3);
      expect(L.myths.toSet().intersection(L.allWhyRight.toSet()), isEmpty);
      expect(M7Why.values.toSet(), L.whyRight.keys.toSet());
      expect(M7Why.values.toSet(), L.whyQ.keys.toSet());
      for (var s = 0; s < 10; s++) {
        for (final right in L.whyRight.values) {
          final deal = dealChoices(right, L.myths, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = L.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(cw.asks, contains('কী করবেন?'));
    });

    test('spoken lines: his exit is recorded; his new push (myth 2) and every guide line are listed for recording', () {
      expect(LearnVoice.resolve(L.coworkerExit, rival: true), isNotNull);
      expect(L.coworker.recordedLines, [L.coworkerLine, L.coworkerExit]);
      expect(L.newRivalLines, ['লাইসেন্স বা সার্টিফিকেট তো শুধু কাগজে দেখানোর জন্য, আসল তো হলো কাজের অভিজ্ঞতা।']);
      expect(L.newGuideLines.toSet(), hasLength(L.newGuideLines.length), reason: 'no line twice');
      expect(
          L.newGuideLines,
          containsAll(<String>{
            L.intro,
            ...L.tasks,
            ...L.tapWhy,
            ...L.whyQ.values,
            ...L.coworker.asks,
            L.callHeld,
            L.allSet,
            L.quick,
            L.fail,
            L.deadlyWord,
            L.nearMissWord,
            for (final m in Mk.all) m.textBn,
          }));
      for (final l in L.newRivalLines) {
        debugPrint('RIVAL m7_crew_papers: $l ${LearnVoice.resolve(l, rival: true) == null ? '(no clip yet)' : '(recorded)'}');
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

    testWidgets('the guide comes first: a tap does not skip him; then the yard: the gang, the cards, the tray, no shift button', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M7CrewPapersPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('শুরু'), findsNothing);
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      final d = m7PapersDeal(math.Random(3));
      for (final (i, p) in d.rounds.first.people.indexed) {
        expect(_person(i), findsOneWidget);
        expect(find.text(p.name), findsOneWidget, reason: 'name strip');
      }
      for (var j = 0; j < 2; j++) {
        expect(_job(j), findsOneWidget);
        expect(find.text(L.jobText[d.rounds.first.jobs[j]]!), findsOneWidget);
      }
      expect(find.text(L.tray), findsOneWidget);
      expect(_shift, findsNothing, reason: 'not before every card is filled or held');
      expect(find.byKey(const ValueKey('wallet')), findsNothing);
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
      expect(lines.every((l) => l.contains(L.askOpen)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('a wallet: five sleeves, swiped right to left; a dog-ear on the worker; his papers match what the deal says', (t) async {
      final c = await _open(t, 8);
      final r = _run.round;
      await _openWallet(t, 1);
      expect(find.byKey(const ValueKey('wallet')), findsOneWidget);
      expect(find.text(L.walletOf(r.people[1].name)), findsOneWidget);
      final p = r.people[1];
      for (var k = 0; k < 5; k++) {
        expect(_title(t), L.sleeveTitle[p.sleeves[k]]);
        switch (p.sleeves[k]) {
          case M7Sleeve.id:
            expect(find.text(p.onRegister ? L.registerYes : L.registerNo), findsOneWidget);
          case M7Sleeve.logbook:
            expect(find.text(L.logbookText(p.logMonths)), findsOneWidget);
          case M7Sleeve.permit:
            expect(find.text(L.permitBoard).evaluate().isNotEmpty, p.hasPermit);
          case M7Sleeve.iti:
            expect(find.text(L.itiTrade).evaluate().isNotEmpty, p.hasIti);
          case M7Sleeve.training:
            for (final c in M7Cert.values) {
              expect(find.text(L.certName[c]!).evaluate().isNotEmpty, p.certs.contains(c), reason: '$c');
            }
        }
        if (k < 4) await _swipeLeft(t);
      }
      // Swipe back (left to right) and tap a dot.
      await t.drag(_sleeve, const Offset(120, 0), warnIfMissed: false);
      await _pump(t, 500);
      expect(_title(t), L.sleeveTitle[p.sleeves[3]]);
      await t.tap(find.byKey(const ValueKey('sleeve-dot-0')), warnIfMissed: false);
      await _pump(t, 500);
      expect(_title(t), L.sleeveTitle[p.sleeves[0]]);
      expect(find.byKey(const ValueKey('sleeve-dogear')), findsOneWidget);
      // Nothing is judged and nothing marked by looking at papers.
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_run.slips, 0);
      // Tapping his tile again closes the wallet.
      await t.tap(_person(1), warnIfMissed: false);
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('wallet')), findsNothing);
      await _close(t, c);
    });

    testWidgets('a small phone (360 × 640): the board, a wallet, the gang and the shift button fit with no overflow, the wallet clear of the guide', (t) async {
      final c = await _open(t, 14, size: const Size(720, 1280));
      await _openWallet(t, 2);
      expect(find.byKey(const ValueKey('wallet')), findsOneWidget);
      final wallet = t.getRect(find.byKey(const ValueKey('wallet')));
      final board = t.getRect(find.byKey(const ValueKey('board')));
      final gang = t.getRect(find.byKey(const ValueKey('gang')));
      expect(wallet.top, greaterThanOrEqualTo(board.bottom));
      expect(wallet.bottom, lessThanOrEqualTo(gang.top));
      expect(wallet.width, lessThanOrEqualTo(360));
      await t.tap(find.byKey(const ValueKey('wallet-close')), warnIfMissed: false);
      await _pump(t, 400);
      final plan = _plan(_run.round);
      for (var j = 0; j < 2; j++) {
        await _putOn(t, plan[j]!, j);
      }
      expect(_shift, findsOneWidget);
      final shift = t.getRect(_shift);
      expect(shift.left, greaterThanOrEqualTo(0));
      expect(shift.bottom, lessThanOrEqualTo(gang.top));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a worker on a card, undone by a tap; a card in the tray, undone by a tap; the shift button comes only when every card is filled or held', (t) async {
      final c = await _open(t, 6);
      final r = _run.round;
      await _putOn(t, 0, 0);
      expect(_run.personOn(0), 0);
      expect(_shift, findsNothing);
      await t.tap(_job(0), warnIfMissed: false);
      await _pump(t, 400);
      expect(_run.personOn(0), isNull, reason: 'taken back');
      expect(_person(0), findsOneWidget);
      await _toTray(t, 1);
      expect(_run.isHeld(1), isTrue);
      expect(_held(1), findsOneWidget);
      expect(_shift, findsNothing);
      await t.tap(_held(1), warnIfMissed: false);
      await _pump(t, 400);
      expect(_run.isHeld(1), isFalse);
      await _putOn(t, 1, 0);
      await _putOn(t, 2, 1);
      expect(_shift, findsOneWidget);
      expect(_run.slips, 0);
      expect(find.byType(MistakeCard), findsNothing, reason: 'nothing is judged before the shift');
      expect(r.jobs.length, 2);
      await _close(t, c);
    });

    for (final live in [1, 2]) {
      testWidgets('flow (live-line card in round ${live + 1}): wallets, drags, the tray, the coworker refused, a reason each round → pass', (t) async {
        final seed = _seedWhere((d) => d.liveRound == live && (live == 1 ? d.liveAvailable : !d.liveAvailable));
        final c = await _open(t, seed);
        for (var round = 0; round < 3; round++) {
          expect(_run.roundIdx, round);
          await _playRound(t, checkWallet: round == 0, c: c);
          if (round < 2) {
            await _pump(t, 1500);
            expect(_run.roundIdx, round + 1);
          }
        }
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['7.10/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['7.10/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(L.caughtCall), findsOneWidget);
        expect(find.byType(FreezeFrame), findsNothing);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a wrong man: judged only at the shift; his card; the worker goes back and the card is empty; then a right one locks', (t) async {
      final seed = _seedWhere((d) {
        final r = d.rounds.first;
        final plan = _plan(r);
        final bad = [for (var i = 0; i < 3; i++) if (Mk.fault(r.people[i], r.jobs[0]) != null && !plan.contains(i)) i];
        return bad.isNotEmpty && plan[1] != null;
      });
      final d = m7PapersDeal(math.Random(seed));
      final r = d.rounds.first;
      final plan = _plan(r);
      final bad = [for (var i = 0; i < 3; i++) if (Mk.fault(r.people[i], r.jobs[0]) != null && !plan.contains(i)) i].first;
      final c = await _open(t, seed);
      await _putOn(t, bad, 0);
      await _putOn(t, plan[1]!, 1);
      expect(find.byType(MistakeCard), findsNothing);
      await t.tap(_shift, warnIfMissed: false);
      await _pump(t, 700);
      final m = Mk.fault(r.people[bad], r.jobs[0])!;
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(m.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_run.personOn(0), isNull);
      expect(_shift, findsNothing, reason: 'the card is empty again');
      expect(_person(bad), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, m.key);
      await _putOn(t, plan[0]!, 0);
      await t.tap(_shift, warnIfMissed: false);
      await _pump(t, 4000);
      expect(_run.roundDone, isTrue);
      expect(_run.slips, 1);
      await _close(t, c);
    });

    testWidgets('three needless holds strike the level out (never a freeze)', (t) async {
      final c = await _open(t, 12);
      await _toTray(t, 0);
      await _toTray(t, 1);
      for (var k = 0; k < 2; k++) {
        await t.tap(_shift, warnIfMissed: false);
        await _pump(t, 700);
        expect(find.byType(MistakeCard), findsOneWidget);
        expect(find.text(Mk.hold.textBn), findsOneWidget);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 600);
        // The held card is back on the board; hold it again.
        await _toTray(t, 0);
        expect(_run.isHeld(0), isTrue);
      }
      await t.tap(_shift, warnIfMissed: false);
      await _pump(t, 1800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(_run.slips, 3);
      await _close(t, c);
    });

    testWidgets('deadly: the live-line card to a man without the certificate freezes the yard first, then the card; the run is over', (t) async {
      final seed = _seedWhere((d) => d.liveRound == 1);
      final c = await _open(t, seed);
      await _playRound(t);
      await _pump(t, 800);
      final r = _run.round;
      final live = r.liveJob;
      final plan = _plan(r);
      final bad = r.people.indexed.firstWhere((e) => !e.$2.certs.contains(M7Cert.live) && !plan.contains(e.$1)).$1;
      await _doHeld(t, () => _putOn(t, bad, live));
      expect(_run.personOn(live), bad);
      for (var j = 0; j < r.jobs.length; j++) {
        if (j == live) continue;
        final p = plan[j];
        if (p == null) {
          await _toTray(t, j);
        } else if (p != bad) {
          await _putOn(t, p, j);
        }
      }
      // The other cards may need a man the bad one stands for: top up.
      for (var j = 0; j < r.jobs.length; j++) {
        if (j != live && !_run.isHeld(j) && _run.personOn(j) == null) {
          final free = _run.free.where((i) => Mk.fault(r.people[i], r.jobs[j]) == null);
          if (free.isNotEmpty) {
            await _putOn(t, free.first, j);
          } else {
            await _toTray(t, j);
          }
        }
      }
      expect(_shift, findsOneWidget);
      await t.tap(_shift, warnIfMissed: false);
      // The cards before it are judged first; then the freeze.
      expect(await _pumpUntil(t, find.byType(FreezeFrame), maxMs: 6000), isTrue);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the freeze comes first');
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(Mk.liveUntrained.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.where((x) => x.key == Mk.liveUntrained.key), isNotEmpty);
      expect(s.rungProgress['7.10/do/0'], isNot('cleared'));
      expect(_run.deadly, Mk.liveUntrained);
      await _close(t, c);
    });

    testWidgets('the coworker: his target\'s wallet waits for him; he comes once; listening drops the target on the live-line card — deadly (freeze first)', (t) async {
      final seed = _seedWhere((d) => d.liveRound == 1);
      final c = await _open(t, seed);
      await _playRound(t);
      await _pump(t, 800);
      final r = _run.round;
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not in the first round');
      await _openWallet(t, r.target!);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek)), isTrue, reason: 'he comes at his target\'s wallet');
      expect(find.byKey(const ValueKey('wallet')), findsNothing, reason: 'the wallet waits for him');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 400);
      await _pickWrong(t, L.coworker.wrong);
      expect(await _pumpUntil(t, find.byType(FreezeFrame), maxMs: 4000), isTrue);
      expect(_run.personOn(r.liveJob), r.target, reason: 'his man is on the live-line card');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.text(Mk.listenedLive.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, Mk.listenedLive.key);
      await _close(t, c);
    });

    testWidgets('the coworker: the live-line card and the shift button wait for him too; refused, his target\'s wallet then opens; he does not come again', (t) async {
      final seed = _seedWhere((d) => d.liveRound == 1);
      final c = await _open(t, seed);
      await _playRound(t);
      await _pump(t, 800);
      final r = _run.round;
      final plan = _plan(r);
      final live = r.liveJob;
      // Touching the live-line card (a tap on it) calls him.
      await t.tap(_job(live), warnIfMissed: false);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek)), isTrue, reason: 'he comes at the live-line card');
      await _pickRight(t, L.coworker.right);
      await _pump(t, 2600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_run.caught, contains(L.caughtCall));
      expect(_run.slips, 0);
      // His target's wallet opens now.
      await _openWallet(t, r.target!);
      expect(find.byKey(const ValueKey('wallet')), findsOneWidget);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he comes once a play');
      await t.tap(find.byKey(const ValueKey('wallet-close')), warnIfMissed: false);
      await _pump(t, 400);
      // The rest right; the shift does not wait for him again.
      for (var j = 0; j < r.jobs.length; j++) {
        final p = plan[j];
        if (p == null) {
          await _toTray(t, j);
        } else {
          await _putOn(t, p, j);
        }
      }
      await t.tap(_shift, warnIfMissed: false);
      await _pump(t, 4200);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(_run.roundDone, isTrue);
      expect(_run.slips, 0);
      await _close(t, c);
    });

    testWidgets('the coworker: going on working while he talks refuses him (the shift button)', (t) async {
      CoworkerTiming.debugReadHoldInTests = true; // beat 1 holds his caption, as on a phone
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final seed = _seedWhere((d) => d.liveRound == 1);
      final c = await _open(t, seed);
      await _playRound(t);
      await _pump(t, 800);
      final r = _run.round;
      final plan = _plan(r);
      for (var j = 0; j < r.jobs.length; j++) {
        final p = plan[j];
        if (j == r.liveJob) continue;
        if (p == null) {
          await _toTray(t, j);
        } else {
          await _putOn(t, p, j);
        }
      }
      // Fill the live-line card last: its drop calls him.
      final p = plan[r.liveJob];
      if (p == null) {
        await _toTray(t, r.liveJob);
      } else {
        await _putOn(t, p, r.liveJob);
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'beat 1: he is still talking');
      expect(_shift, findsNothing, reason: 'not ready: the live-line card still waits');
      if (p == null) {
        await _toTray(t, r.liveJob);
      } else {
        await _putOn(t, p, r.liveJob);
      }
      await _pump(t, 2500);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'he is gone, no deck');
      expect(find.byType(MistakeCard), findsNothing);
      expect(_run.caught, contains(L.caughtCall));
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the praise window and the open deck take no touch: no second shift, no new drag', (t) async {
      final c = await _open(t, 21);
      final r = _run.round;
      final plan = _plan(r);
      for (var j = 0; j < r.jobs.length; j++) {
        final p = plan[j];
        if (p == null) {
          await _toTray(t, j);
        } else {
          await _putOn(t, p, j);
        }
      }
      await t.tap(_shift, warnIfMissed: false);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 6000), isTrue);
      final slips = _run.slips;
      final locked = _run.locked.length;
      expect(_shift, findsNothing, reason: 'the button is gone while the reason waits');
      await t.tap(_job(0), warnIfMissed: false);
      await _pump(t, 300);
      expect(_run.slips, slips);
      expect(_run.locked.length, locked);
      expect(_run.personOn(0), isNotNull, reason: 'a tap on a judged card takes nobody back');
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('gesture hints: a sweep over the gang; a swipe right to left on the wallet; a nudge up from the last worker opened; a sweep over the cards and the tray; a tap on the shift button', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 31);
      IdleHintState scene() => t.state<IdleHintState>(find.byType(IdleHint).first);
      final r = _run.round;
      final plan = _plan(r);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'the hand after idle');
      expect(scene().debugOptions, hasLength(3), reason: 'every gang figure');
      expect(scene().debugFrame?.ripple, isNull, reason: 'a sweep presses nothing');
      // A wallet open: the swipe.
      await _openWallet(t, 0);
      expect(scene().showing, isFalse);
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'the swipe on the wallet');
      expect(scene().debugOptions, isEmpty);
      final f = scene().debugFrame!;
      expect(t.getRect(_sleeve).contains(f.trailFrom ?? f.tip), isTrue, reason: 'on the sleeve');
      await t.tap(find.byKey(const ValueKey('wallet-close')), warnIfMissed: false);
      await _pump(t, 600);
      expect(scene().showing, isFalse);
      // A wallet seen, nothing placed: a short nudge straight up from him.
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'the drag nudge');
      expect(scene().debugOptions, isEmpty);
      final n = scene().debugFrame!;
      final tile = t.getRect(_person(0));
      expect(tile.inflate(4).contains(n.trailFrom ?? n.tip), isTrue, reason: 'it starts on the worker he opened');
      final board = t.getRect(find.byKey(const ValueKey('board')));
      if (n.trailFrom != null) expect((n.trailFrom! - n.tip).distance, lessThanOrEqualTo(100), reason: 'at most a short nudge');
      expect(n.tip.dy <= (n.trailFrom ?? n.tip).dy + 1, isTrue, reason: 'straight up, not at a card');
      expect(board.bottom, lessThan(tile.top));
      // Placed some, not all: a sweep over the unfilled cards and the tray together.
      final first = plan.indexWhere((p) => p != null);
      await _putOn(t, plan[first]!, first);
      await _pump(t, 9500);
      expect(scene().showing, isTrue);
      expect(scene().debugOptions, hasLength(r.jobs.length + 1), reason: 'every job card and the tray alike');
      // Every card filled or held: a tap on the shift button.
      for (var j = 0; j < r.jobs.length; j++) {
        if (j == first) continue;
        final p = plan[j];
        if (p == null) {
          await _toTray(t, j);
        } else {
          await _putOn(t, p, j);
        }
      }
      await _pump(t, 9500);
      expect(scene().showing, isTrue, reason: 'tap hint on the shift button');
      expect(scene().debugOptions, isEmpty);
      expect(t.getRect(_shift).inflate(6).contains(scene().debugFrame!.tip), isTrue);
      await _close(t, c);
    });
  });
}
