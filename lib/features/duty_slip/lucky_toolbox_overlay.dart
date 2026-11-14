import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../game/game_save.dart';
import '../game/lucky_toolbox.dart';
import '../game/mistakes_book.dart' show knownMistakes;
import '../game/ten_sec_scan.dart' show TenSecChecks;
import '../game/toolbox_quiz_sources.dart';
import '../guide/guide_director.dart';
import '../life_skills/life_skills_data.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart' show zlText;

// "ভাগ্যের টুলবক্স" overlay on the ladder (rules: lib/features/game/lucky_toolbox.dart).
// quick task (~10 s, skippable) → pick 1 of 3 → the picked box opens, ◆ fly to
// the counter (ScoreFlyHost), then the other two open. A gate chest adds a
// not-yet-won life skill beside whichever box is picked. Nothing is saved
// until the pick; leaving before that keeps the chest waiting on the ladder
// (and the key, if keys are on). Every step settles to a still frame (idle = zero frames).

const _chestArt = 'assets/duty_slip/world3d/prop_chest.webp';
const _coinArt = 'assets/duty_slip/world3d/coin_current_3d.webp';
const _coinBigArt = 'assets/duty_slip/world3d/coin_cleared_3d.webp';
const _shieldArt = 'assets/duty_slip/world3d/prop_shield.webp';
const _medalArt = 'assets/duty_slip/world3d/medallion_bronze_3d.webp';

/// Code-drawn rarity colours: grey / blue / purple / gold.
Color toolboxRarityColor(ToolboxRarity r) => switch (r) {
      ToolboxRarity.common => const Color(0xFF9AA6B6),
      ToolboxRarity.rare => const Color(0xFF4EA8FF),
      ToolboxRarity.epic => const Color(0xFFB36BFF),
      ToolboxRarity.legendary => const Color(0xFFFFC94A),
    };

Color _tierColor(ChestTier t) => switch (t) {
      ChestTier.wood => const Color(0xFFC08A52),
      ChestTier.silver => const Color(0xFFD5DEE8),
      ChestTier.gold => const Color(0xFFFFC94A),
    };

String _prizeArt(ToolboxReward r, Map<String, LifeSkillModule> skills) => switch (r.prize) {
      ToolboxPrize.coins => r.rareOrBetter ? _coinBigArt : _coinArt,
      ToolboxPrize.shield => _shieldArt,
      ToolboxPrize.doubleNext || ToolboxPrize.badge => _medalArt,
      ToolboxPrize.lifeSkill => switch (skills[r.lifeSkillId]?.cardAsset) {
          final String card when card.isNotEmpty => card,
          _ => _medalArt,
        },
    };

enum _Phase { loading, task, checking, answer, pick, opening, done }

class LuckyToolboxOverlay extends ConsumerStatefulWidget {
  const LuckyToolboxOverlay({
    super.key,
    required this.claimId,
    this.gateChest = false,
    this.startTier,
    required this.muted,
    required this.onClose,
    this.rng,
    this.quizSource,
    this.lifeSkillIds,
  });

  /// The chest's one-time id (`chest@<rungId>`, game_save.dart).
  final String claimId;

  /// A module gate's chest: starts at silver and always adds a life skill.
  final bool gateChest;

  /// The waiting chest's saved tier (null = silver for a gate, else wood).
  final ChestTier? startTier;
  final bool muted;
  final VoidCallback onClose;

  /// Injectable for tests.
  final math.Random? rng;

  /// The quiz task's question (null = [standardToolboxQuiz]: Supabase →
  /// cached passed lessons → none).
  final ToolboxQuizSource? quizSource;

  /// Life-skill ids a prize may be (tests); null = all 13.
  final List<String>? lifeSkillIds;

  @override
  ConsumerState<LuckyToolboxOverlay> createState() => _LuckyToolboxOverlayState();
}

class _LuckyToolboxOverlayState extends ConsumerState<LuckyToolboxOverlay> with TickerProviderStateMixin {
  late final math.Random _rng = widget.rng ?? math.Random();
  late ChestTier _tier = widget.startTier ?? (widget.gateChest ? ChestTier.silver : ChestTier.wood);
  late final ToolboxQuizSource _quiz = widget.quizSource ?? standardToolboxQuiz();
  List<String> get _skillIds => widget.lifeSkillIds ?? kLifeSkillIds;
  var _phase = _Phase.loading;
  ToolboxTask? _task;
  int? _answer;

  /// The right option once known (a server-checked question learns it late; -1 = unknown).
  int _rightIndex = -1;
  List<ToolboxReward>? _deal;
  int? _chosen;

  /// A gate chest's extra (a life skill, or ◆ once all are won), set at the pick.
  ToolboxReward? _extra;
  var _skills = const <String, LifeSkillModule>{};
  Timer? _hold;

  /// The task's ~10 s clock (the bar shrinks; at the end = a wrong answer).
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 10));

  /// The boxes drop in and shake once, then hold still.
  late final AnimationController _dealIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  /// The picked box bursts open, its prize rises, coins fountain out.
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  /// The two missed boxes open.
  late final AnimationController _others = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _clock.addStatusListener((s) {
      if (s == AnimationStatus.completed && _phase == _Phase.task) unawaited(_onAnswer(null));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_prepare()));
    // Life-skill names and cards for the boxes (never holds up the task).
    unawaited(LifeSkillsRepo.instance.modules().then((all) {
      if (mounted && all.isNotEmpty) setState(() => _skills = {for (final m in all) m.id: m});
    }, onError: (_) {}));
  }

  @override
  void dispose() {
    _hold?.cancel();
    _clock.dispose();
    _dealIn.dispose();
    _open.dispose();
    _others.dispose();
    super.dispose();
  }

  void _cue(String path, {double volume = 0.7}) {
    if (widget.muted) return;
    unawaited(ZlFx.cue(path, volume: volume, muted: false));
  }

  void _say(String line, GuideMood mood) {
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: line, speakVoice: true, muted: widget.muted);
  }

  Future<void> _prepare() async {
    if (!mounted) return;
    final save = ref.read(gameSaveProvider);
    ToolboxQuizQuestion? quiz;
    try {
      quiz = await _quiz.next(save, _rng).timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (!mounted) return;
    final task = pickToolboxTask(
      save: save,
      known: knownMistakes,
      eyeChecks: TenSecChecks.all,
      quiz: quiz,
      rng: _rng,
    );
    if (task == null) {
      _toPick();
      return;
    }
    setState(() {
      _task = task;
      _rightIndex = task.correctIndex;
      _phase = _Phase.task;
    });
    _say(ToolboxLines.intro, GuideMood.inspire);
    _cue('sounds/quiz_flip.ogg', volume: 0.5);
    if (_still) {
      // Reduce motion: no shrinking bar; the task waits for an answer or a skip.
      _clock.value = 0;
    } else {
      unawaited(_clock.forward(from: 0));
    }
  }

  Future<void> _onAnswer(int? i) async {
    final task = _task;
    if (_phase != _Phase.task || task == null) return;
    _clock.stop();
    bool? right;
    if (task.serverChecked) {
      // The server knows the answer: a short wait, options locked.
      setState(() {
        _answer = i;
        _phase = _Phase.checking;
      });
      ToolboxQuizVerdict? verdict;
      try {
        verdict = await _quiz.check(task.quiz!, i).timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (!mounted || _phase != _Phase.checking) return;
      _rightIndex = verdict?.correctIndex ?? -1;
      right = verdict == null ? null : (i != null && verdict.correct);
    } else {
      right = i != null && i == task.correctIndex;
    }
    setState(() {
      _answer = i;
      _tier = tierAfterTask(_tier, right: right);
      _phase = _Phase.answer;
    });
    if (right == null) {
      HapticFeedback.selectionClick();
      _say(ToolboxLines.unchecked, GuideMood.think);
      _hold = Timer(const Duration(milliseconds: 1600), _toPick);
      return;
    }
    if (right) {
      HapticFeedback.lightImpact();
      _cue('sounds/quiz_right.ogg');
      _say(ToolboxLines.right, GuideMood.glad);
    } else {
      HapticFeedback.selectionClick();
      _cue('sounds/quiz_wrong.ogg', volume: 0.5);
      _say(ToolboxLines.wrong, GuideMood.think);
    }
    _hold = Timer(Duration(milliseconds: right ? 1000 : 2000), _toPick);
  }

  /// Skip (or the end of the answer beat): straight to the pick, no tier boost.
  void _toPick() {
    if (!mounted || _phase.index >= _Phase.pick.index) return;
    _hold?.cancel();
    _clock.stop();
    final save = ref.read(gameSaveProvider);
    setState(() {
      _deal = dealToolbox(_tier, _rng, save.toolbox, allLifeSkills: _skillIds);
      _phase = _Phase.pick;
    });
    _say(ToolboxLines.pick, GuideMood.talk);
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    if (_still) {
      _dealIn.value = 1;
    } else {
      unawaited(_dealIn.forward(from: 0));
    }
  }

  Future<void> _pickBox(int i, Offset global) async {
    final deal = _deal;
    if (_phase != _Phase.pick || deal == null) return;
    final r = deal[i];
    final extra = widget.gateChest
        ? gateLifeSkillExtra(ref.read(gameSaveProvider).toolbox, _rng, alsoWon: r.lifeSkillId, all: _skillIds)
        : null;
    setState(() {
      _chosen = i;
      _extra = extra;
      _phase = _Phase.opening;
    });
    _dealIn.value = 1;
    if (r.rarity.index >= ToolboxRarity.epic.index) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    _cue('sounds/intro/impact_metal.ogg', volume: 0.6);
    final ok = await ref.read(gameSaveProvider.notifier).openToolbox(
          widget.claimId,
          rareOrBetter: r.rareOrBetter,
          coins: r.coins + (extra?.coins ?? 0),
          shield: r.prize == ToolboxPrize.shield,
          doubleNext: r.prize == ToolboxPrize.doubleNext,
          badge: r.prize == ToolboxPrize.badge,
          lifeSkills: [?r.lifeSkillId, ?extra?.lifeSkillId],
          originGlobal: global,
        );
    if (!mounted) return;
    if (!ok) {
      // No key any more, or opened elsewhere: nothing was paid.
      widget.onClose();
      return;
    }
    _cue(r.rareOrBetter || extra != null ? 'sounds/quiz_complete.ogg' : 'sounds/quiz_right.ogg', volume: 0.75);
    _say(ToolboxLines.won(extra?.prize == ToolboxPrize.lifeSkill ? extra! : r), GuideMood.celebrate);
    if (_still) {
      _open.value = 1;
    } else {
      await _open.forward(from: 0);
      if (!mounted) return;
    }
    _revealOthers();
  }

  void _revealOthers() {
    if (!mounted || _phase != _Phase.opening) return;
    setState(() => _phase = _Phase.done);
    _cue('sounds/learn/card_deal_b.ogg', volume: 0.5);
    if (_still) {
      _others.value = 1;
    } else {
      unawaited(_others.forward(from: 0));
    }
  }

  /// A tap on the backdrop moves any beat on (never past the pick).
  void _onBackdropTap() {
    switch (_phase) {
      case _Phase.answer:
        _toPick();
      case _Phase.opening:
        if (_open.isAnimating) {
          _open.stop();
          _open.value = 1;
          _revealOthers();
        }
      case _Phase.done:
        if (_others.isAnimating) {
          _others.stop();
          _others.value = 1;
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(gameSaveProvider.select((s) => s.toolbox.keys));
    final canLeave = _phase != _Phase.opening;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onBackdropTap,
      child: ColoredBox(
        color: const Color(0xD9040914),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: _Chip(
                          color: _tierColor(_tier),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ToolboxFlags.keysEnabled) ...[
                                Icon(Icons.vpn_key_rounded, size: 15, color: _tierColor(_tier)),
                                const SizedBox(width: 4),
                                Text(
                                  enDigits('$keys'),
                                  key: const ValueKey('toolbox-keys'),
                                  style: zlText(13, weight: FontWeight.w900, color: SlmColors.ivory),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  ToolboxLines.tierName(_tier),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: zlText(13, weight: FontWeight.w800, color: _tierColor(_tier)),
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                        const Spacer(),
                        // Skip stays in reach at every beat before the pick.
                        if (_phase == _Phase.task || _phase == _Phase.checking || _phase == _Phase.answer)
                          TextButton(
                            key: const ValueKey('toolbox-skip'),
                            onPressed: _toPick,
                            child: Text(
                              ToolboxLines.skip,
                              style: zlText(14, weight: FontWeight.w800, color: const Color(0xFFB8C6DC)),
                            ),
                          ),
                        if (canLeave)
                          IconButton(
                            key: const ValueKey('toolbox-close'),
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close_rounded, color: SlmColors.ivory, size: 24),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ToolboxLines.name,
                      textAlign: TextAlign.center,
                      style: zlText(24, weight: FontWeight.w900, color: SlmColors.gold100, height: 1.15),
                    ),
                    const SizedBox(height: 14),
                    switch (_phase) {
                      _Phase.loading => const SizedBox(
                          height: 160,
                          child: Center(
                            child: Image(image: AssetImage(_chestArt), width: 110, height: 96, fit: BoxFit.contain),
                          ),
                        ),
                      _Phase.task || _Phase.checking || _Phase.answer => _taskCard(_task!),
                      _ => _pickStage(),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _taskCard(ToolboxTask task) {
    final answered = _phase == _Phase.answer;
    final locked = _phase != _Phase.task;
    final art = task.art;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15243E), Color(0xFF0A1324)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SlmColors.gold400, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _Chip(
                color: SlmColors.gold300,
                child: Text(
                  enDigits(task.titleBn),
                  style: zlText(13, weight: FontWeight.w900, color: SlmColors.gold200),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // The ~10 s bar: only this strip rebuilds while the clock runs.
            SizedBox(
              height: 5,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (1 - _clock.value).clamp(0.0, 1.0),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: SlmColors.gold300,
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (art != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: art.endsWith('.svg')
                    ? SvgPicture.asset(art, fit: BoxFit.contain)
                    : Image.asset(art, fit: BoxFit.contain, cacheWidth: 420),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              enDigits(task.promptBn),
              textAlign: TextAlign.center,
              style: zlText(17, weight: FontWeight.w800, color: SlmColors.ivory, height: 1.3),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < task.options.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _OptionButton(
                key: ValueKey('toolbox-opt-$i'),
                text: enDigits(task.options[i]),
                state: !answered
                    ? (_phase == _Phase.checking && i == _answer ? _OptState.picked : _OptState.open)
                    : i == _rightIndex
                        ? _OptState.right
                        : i == _answer
                            ? (_rightIndex < 0 ? _OptState.picked : _OptState.wrong)
                            : _OptState.dim,
                onTap: locked ? null : () => unawaited(_onAnswer(i)),
              ),
            ],
            if (_phase == _Phase.checking) ...[
              const SizedBox(height: 10),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: SlmColors.gold300),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pickStage() {
    final deal = _deal!;
    final done = _phase == _Phase.done;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          done ? ToolboxLines.missed : ToolboxLines.pick,
          textAlign: TextAlign.center,
          style: zlText(17, weight: FontWeight.w800, color: SlmColors.ivory),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: _BoxSlot(
                    key: ValueKey('toolbox-box-$i'),
                    index: i,
                    reward: deal[i],
                    tierColor: _tierColor(_tier),
                    skills: _skills,
                    chosen: _chosen == i,
                    anyChosen: _chosen != null,
                    dealIn: _dealIn,
                    open: _open,
                    others: _others,
                    still: _still,
                    onTap: _phase == _Phase.pick ? (global) => unawaited(_pickBox(i, global)) : null,
                  ),
                ),
            ],
          ),
        ),
        if (done && _extra != null) ...[
          const SizedBox(height: 12),
          _ExtraPrize(key: const ValueKey('toolbox-gate-extra'), reward: _extra!, skill: _skills[_extra!.lifeSkillId]),
        ],
        if (done) ...[
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('toolbox-back'),
            style: FilledButton.styleFrom(
              backgroundColor: SlmColors.gold400,
              foregroundColor: SlmColors.navy950,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: widget.onClose,
            child: Text(ToolboxLines.back, style: zlText(15, weight: FontWeight.w900, color: SlmColors.navy950)),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: child,
      );
}

enum _OptState { open, picked, right, wrong, dim }

class _OptionButton extends StatelessWidget {
  const _OptionButton({super.key, required this.text, required this.state, required this.onTap});

  final String text;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (fill, edge, icon) = switch (state) {
      _OptState.right => (const Color(0xFF0F3D2C), SlmColors.emerald300, Icons.check_circle_rounded),
      _OptState.wrong => (const Color(0xFF3E161B), const Color(0xFFFF6B6B), Icons.cancel_rounded),
      _OptState.dim => (const Color(0xFF16233A), const Color(0x553B4A66), Icons.circle_outlined),
      _OptState.picked => (const Color(0xFF243A5E), SlmColors.gold300, Icons.radio_button_checked_rounded),
      _OptState.open => (const Color(0xFF1D2E4D), const Color(0x99D4A037), Icons.circle_outlined),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: edge, width: 1.4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: edge),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: zlText(14.5, weight: FontWeight.w700, color: SlmColors.ivory, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the three boxes: drops in with a shake, glows in the chest's tier
/// colour while closed (blind pick), bursts in its rarity colour when open.
class _BoxSlot extends StatelessWidget {
  const _BoxSlot({
    super.key,
    required this.index,
    required this.reward,
    required this.tierColor,
    this.skills = const {},
    required this.chosen,
    required this.anyChosen,
    required this.dealIn,
    required this.open,
    required this.others,
    required this.still,
    required this.onTap,
  });

  final int index;
  final ToolboxReward reward;
  final Color tierColor;
  final Map<String, LifeSkillModule> skills;
  final bool chosen;
  final bool anyChosen;
  final Animation<double> dealIn;
  final Animation<double> open;
  final Animation<double> others;
  final bool still;
  final void Function(Offset global)? onTap;

  @override
  Widget build(BuildContext context) {
    final reveal = chosen ? open : others;
    final chest = Image.asset(_chestArt, width: 96, height: 84, cacheWidth: 300, fit: BoxFit.contain);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTap == null ? null : (d) => onTap!(d.globalPosition),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([dealIn, reveal]),
          child: chest,
          builder: (context, chest) {
            // Staggered drop, then one short shake.
            final begin = index * 0.14;
            final inT = still ? 1.0 : Interval(begin, (begin + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutBack).transform(dealIn.value);
            final shakeT = still ? 0.0 : const Interval(0.7, 1.0).transform(dealIn.value);
            final shake = math.sin(shakeT * math.pi * 6) * 4 * (1 - shakeT);
            final r = anyChosen && (chosen || others.value > 0) ? reveal.value : 0.0;
            final rarity = toolboxRarityColor(reward.rarity);
            final glowColor = r > 0 ? Color.lerp(tierColor, rarity, (r * 2).clamp(0.0, 1.0))! : tierColor;
            final dim = anyChosen && !chosen ? 0.72 : 1.0;
            return Opacity(
              opacity: (inT.clamp(0.0, 1.0) * dim).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(shake, (1 - inT) * -60),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: _GlowPainter(color: glowColor, burst: r, big: chosen),
                    ),
                    Transform.scale(scale: 1 + 0.12 * math.sin(r * math.pi), child: Opacity(opacity: 1 - 0.55 * r, child: chest)),
                    if (r > 0) ...[
                      if (chosen && reward.prize == ToolboxPrize.coins) ..._coinFountain(r),
                      Transform.translate(
                        offset: Offset(0, -34 * Curves.easeOut.transform(r)),
                        child: Opacity(
                          opacity: r.clamp(0.0, 1.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(_prizeArt(reward, skills), width: 56, height: 56, cacheWidth: 180, fit: BoxFit.contain),
                              const SizedBox(height: 2),
                              Text(
                                enDigits(ToolboxLines.prizeLabel(reward)),
                                style: zlText(15, weight: FontWeight.w900, color: SlmColors.ivory),
                              ),
                              Text(
                                ToolboxLines.rarityName(reward.rarity),
                                style: zlText(12, weight: FontWeight.w800, color: rarity),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Coins spring out of the opened box and fade (the ◆ fly-in carries the amount).
  List<Widget> _coinFountain(double t) {
    if (t >= 1) return const [];
    final art = reward.rareOrBetter ? _coinBigArt : _coinArt;
    return [
      for (var k = 0; k < 6; k++)
        Builder(builder: (_) {
          final angle = -math.pi / 2 + (k - 2.5) * 0.38;
          final d = 70 * Curves.easeOut.transform(t);
          final fall = 40 * t * t;
          return Transform.translate(
            offset: Offset(math.cos(angle) * d, math.sin(angle) * d + fall),
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Image.asset(art, width: 22, height: 22, cacheWidth: 66),
            ),
          );
        }),
    ];
  }
}

/// A gate chest's guaranteed extra, shown under the boxes once they are open:
/// the life skill's card and name (or the ◆ a duplicate turned into).
class _ExtraPrize extends StatelessWidget {
  const _ExtraPrize({super.key, required this.reward, required this.skill});

  final ToolboxReward reward;
  final LifeSkillModule? skill;

  @override
  Widget build(BuildContext context) {
    final card = skill?.cardAsset ?? '';
    final title = reward.prize == ToolboxPrize.lifeSkill
        ? '${LifeSkillLines.prize}: ${skill?.titleBn ?? ''}'
        : ToolboxLines.prizeLabel(reward);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF15243E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toolboxRarityColor(reward.rarity), width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                card.isNotEmpty ? card : _prizeArt(reward, const {}),
                width: 56,
                height: 56,
                cacheWidth: 168,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ToolboxLines.gateExtra, style: zlText(12.5, weight: FontWeight.w800, color: SlmColors.gold200)),
                  const SizedBox(height: 2),
                  Text(
                    enDigits(title),
                    style: zlText(15, weight: FontWeight.w900, color: SlmColors.ivory, height: 1.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.color, required this.burst, required this.big});

  final Color color;
  final double burst;
  final bool big;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.width * (0.42 + (big ? 0.12 : 0.05) * burst);
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.55 + 0.3 * burst), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: radius)),
    );
    if (burst > 0) {
      // Rays in the rarity colour.
      final ray = Paint()
        ..color = color.withValues(alpha: (0.7 * (1 - burst * 0.4)).clamp(0.0, 1.0))
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 10; k++) {
        final a = k * math.pi / 5 + burst * 0.6;
        final r0 = radius * 0.45;
        final r1 = radius * (0.65 + 0.35 * burst);
        canvas.drawLine(c + Offset(math.cos(a) * r0, math.sin(a) * r0), c + Offset(math.cos(a) * r1, math.sin(a) * r1), ray);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.color != color || old.burst != burst || old.big != big;
}
