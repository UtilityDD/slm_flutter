import 'dart:math';

import 'safe_home_quiz_models.dart';

enum ShPhase { intro, quiz, disturbance, done }

class ShAnswerResult {
  final bool ok;
  final int delta;
  final String noteBn;

  const ShAnswerResult({required this.ok, required this.delta, required this.noteBn});
}

/// Lightweight SAFE HOME quiz runner — no free-play site sim.
class SafeHomeQuizEngine {
  final SafeHomePack pack;
  final Random _rng;

  late ShSite site;
  var phase = ShPhase.intro;
  var stepIndex = 0;
  var score = 0;
  late int secondsLeft;
  final wrongSteps = <String>[];
  final rightSteps = <String>[];
  ShDisturbance? activeDisturbance;
  var _sinceDisturb = 0;

  SafeHomeQuizEngine(this.pack, {int? seed}) : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    site = pack.sites[_rng.nextInt(pack.sites.length)];
    secondsLeft = pack.timeSeconds;
  }

  ShStep? get step => stepIndex < pack.steps.length ? pack.steps[stepIndex] : null;
  bool get finished => phase == ShPhase.done;
  int get totalSteps => pack.steps.length;

  void beginQuiz() {
    if (phase != ShPhase.intro) return;
    phase = ShPhase.quiz;
  }

  /// Tick once per second. Returns true if time ran out.
  bool tick() {
    if (phase == ShPhase.done || phase == ShPhase.intro) return false;
    if (secondsLeft <= 0) {
      phase = ShPhase.done;
      return true;
    }
    secondsLeft--;
    _sinceDisturb++;
    if (phase == ShPhase.quiz &&
        activeDisturbance == null &&
        pack.disturbances.isNotEmpty &&
        _sinceDisturb >= 18 + _rng.nextInt(12) &&
        _rng.nextDouble() < 0.45) {
      activeDisturbance = pack.disturbances[_rng.nextInt(pack.disturbances.length)];
      phase = ShPhase.disturbance;
      _sinceDisturb = 0;
    }
    if (secondsLeft <= 0) {
      phase = ShPhase.done;
      return true;
    }
    return false;
  }

  void dismissDisturbance() {
    final d = activeDisturbance;
    if (d == null) return;
    score = max(0, score - d.penalty);
    activeDisturbance = null;
    phase = stepIndex >= pack.steps.length ? ShPhase.done : ShPhase.quiz;
  }

  List<ShOption> shuffledOptions(ShStep s) {
    final list = [...s.options]..shuffle(_rng);
    return list;
  }

  ShAnswerResult answerSingle(String optionId) {
    final s = step;
    if (s == null || s.kind != ShKind.single) {
      return const ShAnswerResult(ok: false, delta: 0, noteBn: '');
    }
    final ok = s.options.any((o) => o.id == optionId && o.correct);
    return _apply(s, ok);
  }

  ShAnswerResult answerMulti(Set<String> picked) {
    final s = step;
    if (s == null || s.kind != ShKind.multi) {
      return const ShAnswerResult(ok: false, delta: 0, noteBn: '');
    }
    final hitEssential = s.essential.every(picked.contains);
    final hitForbidden = s.forbidden.any(picked.contains);
    final ok = hitEssential && !hitForbidden && picked.isNotEmpty;
    return _apply(s, ok);
  }

  ShAnswerResult _apply(ShStep s, bool ok) {
    if (ok) {
      score += s.reward;
      rightSteps.add(s.id);
      _advance();
      return ShAnswerResult(ok: true, delta: s.reward, noteBn: 'ঠিক · +${s.reward}');
    }
    score = max(0, score - s.penalty);
    if (!wrongSteps.contains(s.id)) wrongSteps.add(s.id);
    return ShAnswerResult(ok: false, delta: -s.penalty, noteBn: 'ভুল · −${s.penalty}');
  }

  void _advance() {
    stepIndex++;
    _sinceDisturb = 0;
    if (stepIndex >= pack.steps.length) {
      phase = ShPhase.done;
    }
  }

  String gradeBn() {
    final ratio = rightSteps.length / max(1, totalSteps);
    if (ratio >= 0.85) return 'সেফ হোম · ভালো';
    if (ratio >= 0.6) return 'আরও মনোযোগ';
    return 'আবার অনুশীলন করুন';
  }
}
