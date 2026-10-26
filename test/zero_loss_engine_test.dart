import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_engine.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_models.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_places.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_tbt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late SmartLinemanDispatchNotifier game;
  ZeroLossState s() => container.read(zeroLossProvider)!;

  setUp(() async {
    container = ProviderContainer();
    game = container.read(zeroLossProvider.notifier);
    game.begin(await createZeroLossSetup(seed: 42));
    game.startShift();
  });

  tearDown(() => container.dispose());

  void team(String faultId, List<String> crew) {
    game.selectFault(faultId);
    for (final id in crew) {
      game.assignLineman(id);
    }
  }

  void dressAll(String faultId) {
    game.openArmour(faultId);
    for (final id in s().mission(faultId).assignedCrew) {
      for (final g in s().bodyKit(faultId)) {
        game.wearGear(id, g);
      }
    }
  }

  void packAll(String faultId, {Set<String> skip = const {}}) {
    final f = s().fault(faultId);
    for (final id in [...f.requiredGear, ...f.jobGear]) {
      if (!skip.contains(id)) game.toggleGear(id);
    }
  }

  test('setup picks a real district and fills place names', () {
    final st = s();
    expect(st.setting.districtBn, isNotEmpty);
    expect(st.setting.placeA, isNot(equals(st.setting.placeB)));
    expect(st.scenario.faults, hasLength(2));
    expect(st.crew.every((c) => c.art.isNotEmpty), isTrue);
  });

  test('crew assignment respects required count and one fault per lineman', () {
    team('wire_on_ground', ['anil', 'rafiq', 'bapi']);
    expect(s().mission('wire_on_ground').assignedCrew, ['anil', 'rafiq']);
    team('pole_insulator', ['anil']);
    expect(s().mission('pole_insulator').assignedCrew, isEmpty);
  });

  test('lead is the most careful, junior the least careful', () {
    team('pole_insulator', ['kartik', 'rafiq', 'anil']);
    expect(s().leadOf('pole_insulator')!.id, 'rafiq');
    expect(s().juniorOf('pole_insulator')!.id, 'kartik');
    expect(s().fillFor('pole_insulator', '{junior} এখনো পোলে'), 'কার্তিক এখনো পোলে');
  });

  test('personal PPE: everyone must be dressed before the truck; decoys are refused', () {
    team('pole_insulator', ['anil', 'rafiq', 'bapi']);
    game.openArmour('pole_insulator');
    expect(s().phase, ZeroLossPhase.armour);
    expect(s().bodyKit('pole_insulator'), containsAll(['helmet', 'gloves', 'boots', 'harness']));

    expect(game.wearGear('anil', 'waist_belt'), WearResult.wrong);
    expect(s().mission('pole_insulator').wrongWorn, ['waist_belt']);
    expect(game.canLoad('pole_insulator'), isFalse);

    for (final id in ['anil', 'rafiq', 'bapi']) {
      for (final g in ['helmet', 'gloves', 'boots', 'harness']) {
        expect(game.wearGear(id, g), WearResult.worn);
      }
    }
    expect(game.canLoad('pole_insulator'), isTrue);
    expect(s().mantraReport('pole_insulator')['mend'], isFalse);
  });

  test('harness is not needed for a ground job', () {
    team('wire_on_ground', ['anil', 'rafiq']);
    game.openArmour('wire_on_ground');
    expect(game.wearGear('anil', 'harness'), WearResult.notNeeded);
  });

  test('truck refuses body gear and enforces capacity', () {
    team('pole_insulator', ['anil', 'rafiq', 'bapi']);
    dressAll('pole_insulator');
    game.openLoading('pole_insulator');
    game.toggleGear('helmet');
    expect(s().mission('pole_insulator').packedGear, isEmpty);
    for (final g in s().scenario.truckGear) {
      game.toggleGear(g.id);
    }
    expect(s().mission('pole_insulator').packedGear.length, s().scenario.truckCapacity);
  });

  test('missing truck gear blocks dispatch; reload costs time', () {
    team('wire_on_ground', ['subrata', 'kartik']);
    dressAll('wire_on_ground');
    game.openLoading('wire_on_ground');
    final check = game.dispatchTruck();
    expect(check.ok, isFalse);
    expect(check.missingSafety.map((g) => g.id), contains('earth_rods'));

    final before = s().mission('wire_on_ground').minutesUsed;
    game.reloadTruck();
    expect(s().pendingCheck, isNull);
    expect(s().mission('wire_on_ground').minutesUsed, greaterThan(before));
  });

  test('full safe path: chant, best choices, safe outcome at base risk', () {
    team('wire_on_ground', ['anil', 'rafiq']);
    dressAll('wire_on_ground');
    game.openLoading('wire_on_ground');
    packAll('wire_on_ground');
    expect(game.dispatchTruck().ok, isTrue);
    expect(s().phase, ZeroLossPhase.chant);

    final before = s().points;
    game.finishChant(0);
    expect(s().phase, ZeroLossPhase.site);
    expect(s().points, before + s().scenario.chantBonusPoints);
    expect(game.riskFor('wire_on_ground'), closeTo(s().scenario.baseAccidentRisk, 1e-9));

    for (final e in s().fault('wire_on_ground').events) {
      game.chooseOption(e.options.firstWhere((o) => o.best).id);
      game.continueAfterFeedback();
    }
    expect(s().mission('wire_on_ground').outcome, MissionOutcome.safe);
    final report = s().mantraReport();
    expect(report.values.every((ok) => ok), isTrue);
    expect(report.keys, containsAll(['armour', 'fence', 'earth', 'count', 'permit']));
  });

  test('shortcut adds risk per missing safety item', () {
    team('pole_insulator', ['anil', 'rafiq', 'bapi']);
    dressAll('pole_insulator');
    game.openLoading('pole_insulator');
    packAll('pole_insulator', skip: {'earth_rods', 'lock_board'});
    game.dispatchTruck();
    game.takeShortcut();
    final sc = s().scenario;
    expect(s().mission('pole_insulator').missingSafety, hasLength(2));
    expect(game.riskFor('pole_insulator'), closeTo(sc.baseAccidentRisk + 2 * sc.missingGearRisk, 1e-9));
    expect(s().mantraReport('pole_insulator')['earth'], isFalse);
  });

  test('tired crew on a climbing job adds risk', () {
    team('pole_insulator', ['subrata', 'kartik', 'anil']);
    final sc = s().scenario;
    expect(game.riskFor('pole_insulator'), closeTo(sc.baseAccidentRisk + 2 * sc.tiredRiskClimb + 0.03, 1e-9));
  });

  test('body and truck gear are split', () {
    final sc = s().scenario;
    expect(sc.bodyGear.map((g) => g.id), containsAll(['helmet', 'gloves', 'boots', 'harness', 'waist_belt']));
    expect(sc.truckGear.any((g) => g.area == GearArea.body), isFalse);
  });

  test('every mantra has both Tool Box Talk lines; tracks alternate per mission', () {
    final sc = s().scenario;
    for (final t in TbtTrack.values) {
      expect(sc.tbt[t], isNotNull);
      expect(sc.mantras.map((m) => m.lines[t]?.letter).join(), t == TbtTrack.safe ? 'SAFEHOME' : 'সবআইফইরও');
      for (final m in sc.mantras) {
        final l = m.lines[t]!;
        expect(l.file, endsWith('.mp3'));
        expect(l.bodyAt, greaterThan(l.wordAt));
      }
    }
    expect(tbtTrackFor(s()), TbtTrack.safe);
  });

  test('every site event has a scene built from existing kit assets', () {
    final validWhen = RegExp(r'^(before|after|best|wrong|pick:\w+)$');
    for (final f in s().scenario.faults) {
      for (final e in f.events) {
        final sc = e.scene;
        expect(sc, isNotNull, reason: e.id);
        expect(File(sc!.background).existsSync(), isTrue, reason: sc.background);
        expect(sc.spots, isNotEmpty, reason: e.id);
        for (final l in sc.layers) {
          expect(File(l.image).existsSync(), isTrue, reason: '${e.id}: ${l.image}');
          for (final w in l.when) {
            expect(validWhen.hasMatch(w), isTrue, reason: '${e.id}: $w');
            if (w.startsWith('pick:')) expect(e.options.map((o) => o.id), contains(w.substring(5)));
          }
        }
        for (final p in sc.spots) {
          expect(p.x, inInclusiveRange(0, 1));
          expect(p.y, inInclusiveRange(0, 1));
        }
      }
    }
  });

  test('scene layers follow the chosen option', () {
    HazardOption option(String id, bool best) =>
        HazardOption(id: id, textBn: '', feedbackBn: '', best: best, safety: 0, satisfaction: 0, minutes: 0, risk: 0);
    final best = option('a', true);
    final bad = option('b', false);
    SceneLayer layer(List<String> when) => SceneLayer(image: '', x: 0, y: 0, h: 0, when: when);
    expect(layer(['before']).visibleFor(null), isTrue);
    expect(layer(['before']).visibleFor(best), isFalse);
    expect(layer(['best']).visibleFor(best), isTrue);
    expect(layer(['wrong']).visibleFor(bad), isTrue);
    expect(layer(['wrong']).visibleFor(best), isFalse);
    expect(layer(['pick:b']).visibleFor(bad), isTrue);
    expect(layer(['after']).visibleFor(best), isTrue);
    expect(layer([]).visibleFor(bad), isTrue);
  });

  test('setting uses Bangla towns, office and hospital for every district', () {
    final bangla = RegExp(r'^[\u0980-\u09FF\s\-]+$');
    for (var seed = 0; seed < 60; seed++) {
      final st = pickZeroLossSetting(s().scenario, Random(seed));
      for (final name in [st.office, st.placeA, st.placeB, st.hospital]) {
        expect(bangla.hasMatch(name), isTrue, reason: '${st.district}: $name');
      }
      expect(st.office, endsWith('সাপ্লাই অফিস'));
      expect({st.placeA, st.placeB, st.office.replaceAll(' সাপ্লাই অফিস', '')}, hasLength(3));
    }
    expect(zeroLossTownsBn.keys.toSet(), s().scenario.districtNamesBn.keys.toSet());
  });

  test('ledger: additions, deductions and penalties sum to the points', () {
    team('pole_insulator', ['anil', 'rafiq', 'bapi']);
    game.openArmour('pole_insulator');
    game.wearGear('anil', 'waist_belt');
    game.wearGear('anil', 'waist_belt');
    game.wearGear('anil', 'waist_belt');
    expect(s().ledger.where((e) => e.cause == ScoreCause.decoy), hasLength(1));
    dressAll('pole_insulator');
    game.openLoading('pole_insulator');
    packAll('pole_insulator', skip: {'earth_rods'});
    game.dispatchTruck();
    game.reloadTruck();
    game.dispatchTruck();
    game.takeShortcut();
    game.finishChant(5);
    final e = s().fault('pole_insulator').events.first;
    game.chooseOption(e.options.firstWhere((o) => !o.best).id);

    int sum(ScoreCause c) => s().ledger.where((x) => x.cause == c).fold(0, (a, x) => a + x.points);
    expect(sum(ScoreCause.decoy), -ZeroLossPoints.decoy);
    expect(sum(ScoreCause.reload), -ZeroLossPoints.reload);
    expect(sum(ScoreCause.shortcut), -ZeroLossPoints.shortcut);
    expect(sum(ScoreCause.chantMistake), -ZeroLossPoints.chantMistake * ZeroLossPoints.chantMistakeCap);
    expect(sum(ScoreCause.wrongDecision), -ZeroLossPoints.wrongDecision);
    expect(s().ledger.every((x) => x.kind == ScoreKind.add ? x.points > 0 : x.points < 0), isTrue);
    expect(s().points, s().pointsOf(ScoreKind.add) + s().pointsOf(ScoreKind.deduct) + s().pointsOf(ScoreKind.penalty));
    expect(s().points, lessThan(0));
  });

  test('customer complaints cost points, capped per mission', () {
    for (var i = 0; i < 6; i++) {
      game.customerComplaint('wire_on_ground');
    }
    expect(s().mission('wire_on_ground').complaints, ZeroLossPoints.complaintCap);
    expect(s().points, -ZeroLossPoints.complaint * ZeroLossPoints.complaintCap);
  });

  test('every accident cause is defined with a picture', () {
    final sc = s().scenario;
    final used = {
      for (final g in sc.gear)
        if (g.kind == GearKind.safety || g.kind == GearKind.decoy) g.cause,
      for (final f in sc.faults)
        for (final e in f.events)
          for (final o in e.options)
            if (!o.best) o.cause,
    };
    expect(used.contains(''), isFalse, reason: 'every safety item and wrong option needs a cause');
    for (final id in used) {
      expect(sc.accidentCauses.containsKey(id), isTrue, reason: id);
      expect(File(sc.accidentCause(id).image).existsSync(), isTrue, reason: id);
    }
  });

  test('practice keeps everyone safe when all mantras are kept', () {
    team('wire_on_ground', ['anil', 'rafiq']);
    dressAll('wire_on_ground');
    game.openLoading('wire_on_ground');
    packAll('wire_on_ground');
    game.dispatchTruck();
    game.finishChant(0);
    expect(game.riskFactors('wire_on_ground'), isEmpty);
  });

  test('duty: decoys go on, crew can leave half-dressed, truck leaves without warning', () async {
    game.begin(await createZeroLossSetup(seed: 7));
    game.startShift(mode: ZeroLossMode.duty);
    expect(s().duty, isTrue);
    team('wire_on_ground', ['anil', 'rafiq']);
    game.openArmour('wire_on_ground');
    expect(game.wearGear('anil', 'boots'), WearResult.worn);
    expect(game.wearGear('anil', 'slippers'), WearResult.worn);
    expect(s().mission('wire_on_ground').wornBy('anil'), ['slippers']);
    expect(s().looksReady('wire_on_ground', 'anil'), isFalse);
    expect(game.canLoad('wire_on_ground'), isTrue);
    game.openLoading('wire_on_ground');
    packAll('wire_on_ground', skip: {'tape_cones'});
    final check = game.dispatchTruck();
    expect(check.ok, isFalse);
    expect(s().pendingCheck, isNull);
    expect(s().phase, ZeroLossPhase.chant);

    final factors = game.riskFactors('wire_on_ground');
    final boots = factors.firstWhere((r) => r.gearId == 'boots' && r.linemanId == 'anil');
    expect(boots.cause, 'snake');
    expect(boots.decoyId, 'slippers');
    expect(factors.any((r) => r.gearId == 'gloves' && r.linemanId == 'rafiq' && r.cause == 'shock'), isTrue);
    expect(factors.any((r) => r.gearId == 'tape_cones' && r.cause == 'vehicle'), isTrue);
  });

  test('accident names a specific cause from what went wrong, and its victim', () async {
    for (var seed = 0; seed < 40; seed++) {
      final c = ProviderContainer();
      final g = c.read(zeroLossProvider.notifier);
      g.begin(await createZeroLossSetup(seed: seed));
      g.startShift(mode: ZeroLossMode.duty);
      g.selectFault('pole_insulator');
      for (final id in ['anil', 'rafiq', 'bapi']) {
        g.assignLineman(id);
      }
      g.openArmour('pole_insulator');
      g.openLoading('pole_insulator');
      g.dispatchTruck();
      g.finishChant(0);
      final st = c.read(zeroLossProvider)!;
      for (final e in st.fault('pole_insulator').events) {
        g.chooseOption(e.options.firstWhere((o) => !o.best).id);
        g.continueAfterFeedback();
      }
      final m = c.read(zeroLossProvider)!.mission('pole_insulator');
      if (m.outcome == MissionOutcome.accident) {
        expect(m.accident, isNotNull);
        expect(c.read(zeroLossProvider)!.scenario.accidentCauses.containsKey(m.accident!.cause), isTrue);
        if (m.accident!.linemanId != null) expect(m.injuredCrewId, m.accident!.linemanId);
        c.dispose();
        return;
      }
      c.dispose();
    }
    fail('no accident in 40 reckless shifts');
  });

  test('gear and customer art exist in the kit', () {
    final sc = s().scenario;
    for (final g in sc.gear) {
      expect(g.image, startsWith('assets/zero_loss/scene/gear_'), reason: g.id);
      expect(File(g.image).existsSync(), isTrue, reason: g.image);
    }
    expect(sc.customers, hasLength(greaterThanOrEqualTo(6)));
    for (final c in sc.customers) {
      expect(File(c.image).existsSync(), isTrue, reason: c.image);
      expect(c.linesBn, isNotEmpty);
      expect(c.lateLinesBn, isNotEmpty);
    }
  });
}
