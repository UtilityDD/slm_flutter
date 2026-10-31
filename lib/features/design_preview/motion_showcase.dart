import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/lineman_profile.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../home/lineman_progress.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';

/// Reading points a finished lesson adds (the "+20" on the lesson breaker).
const _lessonReward = 20;

/// Developer-only showcase of the motion engine, driven by the signed-in
/// lineman's real progress. Reward buttons preview what the app would show
/// after a lesson; nothing is written to Supabase or local storage.
class MotionShowcase extends ConsumerStatefulWidget {
  const MotionShowcase({super.key});

  @override
  ConsumerState<MotionShowcase> createState() => _MotionShowcaseState();
}

class _MotionShowcaseState extends ConsumerState<MotionShowcase> {
  final _motion = SlmMotionSettings();
  final _shield = AnimatedSafetyShieldController();
  final _xpKey = GlobalKey();
  final _timers = <Timer>[];

  double _shieldSize = 220;
  bool _fastRing = false;
  int _bonus = 0;
  int _sweepPass = 0;
  bool _loading = false;
  int _step = 0;

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _motion.dispose();
    _shield.dispose();
    super.dispose();
  }

  LinemanProfile? get _base => ref.read(authProvider).profile;

  /// The real profile with previewed lesson rewards added on top.
  static LinemanProfile _withBonus(LinemanProfile? p, int bonus) {
    final base = p ?? const LinemanProfile(id: '');
    return LinemanProfile(
      id: base.id,
      trainingLevel: base.trainingLevel,
      points: base.points + bonus,
      readingPoints: base.readingPoints + bonus,
      quizPoints: base.quizPoints,
      totalPenalties: base.totalPenalties,
      completedLessons: base.completedLessons,
      isGuest: base.isGuest,
    );
  }

  void _later(Duration d, VoidCallback f) {
    _timers.add(Timer(d, () {
      if (mounted) f();
    }));
  }

  void _xpReward() {
    final bn = ref.read(languageProvider);
    final before = _withBonus(_base, _bonus);
    final after = _withBonus(_base, _bonus + _lessonReward);
    setState(() => _bonus += _lessonReward);
    showSlmXpToast(context, amount: _lessonReward, unit: tr(bn, 'পয়েন্ট', 'pts'), anchor: _xpKey.currentContext);

    final was = linemanPath(before).achieved;
    final now = linemanPath(after).achieved;
    final levelWas = webBadgeLevel(before);
    final levelNow = webBadgeLevel(after);
    if (levelNow > levelWas) {
      _later(const Duration(milliseconds: 1500), () => _levelUp(from: levelWas, to: levelNow));
    } else if (now > was) {
      _later(const Duration(milliseconds: 1500), () => _badge(chapter: now - 1));
    }
  }

  void _badge({int? chapter}) {
    final bn = ref.read(languageProvider);
    final path = linemanPath(_withBonus(_base, _bonus));
    final i = (chapter ?? path.achieved).clamp(0, linemanChapters.length - 1);
    final c = linemanChapters[i];
    showSlmBadgeUnlock(
      context,
      icon: c.$3,
      title: bn ? c.$1 : c.$2,
      caption: tr(bn, 'নতুন ব্যাজ আনলক', 'Badge unlocked'),
    );
  }

  void _levelUp({int? from, int? to}) {
    final bn = ref.read(languageProvider);
    final level = webBadgeLevel(_withBonus(_base, _bonus));
    final a = from ?? level;
    final b = to ?? (level >= 10 ? 10 : level + 1);
    showSlmLevelUp(
      context,
      fromLevel: a,
      toLevel: b,
      heading: tr(bn, 'লেভেল আপ', 'Level up'),
      title: linemanBadgeName(b, bn),
      reward: tr(bn, '+$_lessonReward পয়েন্ট', '+$_lessonReward points'),
    );
  }

  void _playAll() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _motion
      ..play()
      ..setLoops(true)
      ..replayEntrances();
    _shield.replayEntrance();
    setState(() => _sweepPass++);
    _later(const Duration(milliseconds: 1200), _xpReward);
    _later(const Duration(milliseconds: 3600), () => _badge());
    _later(const Duration(milliseconds: 7800), () => _levelUp());
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final profile = ref.watch(authProvider).profile;
    final ladder = ref.watch(trainingLadderProvider).value;
    final me = _withBonus(profile, _bonus);
    final path = linemanPath(me);
    final level = webBadgeLevel(me);
    final spare = (me.readingPoints - path.achieved * 40).clamp(0, 40);

    TrainingModuleItem? module;
    if (ladder != null && ladder.isNotEmpty) {
      module = ladder.firstWhere((m) => m.isActive && !m.isCompleted, orElse: () => ladder.last);
    }

    return SlmMotionScope(
      settings: _motion,
      child: Theme(
        data: SlmTheme.night(),
        child: Builder(
          builder: (context) {
            final s = context.slm;
            final g = s.layout.gutter;
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SlmBackground(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SlmTopBar(
                        title: tr(bn, 'মোশন শোকেস', 'Motion showcase'),
                        subtitle: tr(bn, 'আসল প্রোগ্রেস দিয়ে · সেভ হয় না', 'Live progress · nothing is saved'),
                        onBack: () => Navigator.of(context).maybePop(),
                        backLabel: tr(bn, 'ফিরে যান', 'Back'),
                        actions: [
                          SlmChip(
                            label: bn ? 'EN' : 'বাং',
                            icon: Icons.translate_rounded,
                            onTap: () => ref.read(languageProvider.notifier).setBengali(!bn),
                          ),
                        ],
                      ),
                      _Controls(
                        bn: bn,
                        motion: _motion,
                        onPlayAll: _playAll,
                        onReplay: () {
                          _motion.replayEntrances();
                          _shield.replayEntrance();
                        },
                        onXp: _xpReward,
                        onBadge: () => _badge(),
                        onLevel: () => _levelUp(),
                      ),
                      Expanded(
                        child: ListView(
                          padding: shellScrollPadding(context, left: g, top: SlmSpace.sm, right: g, extraBottom: SlmSpace.xxl),
                          children: [
                            _Section(
                              n: 1,
                              title: tr(bn, 'অ্যানিমেটেড সেফটি শিল্ড', 'Animated safety shield'),
                              note: tr(bn, 'ট্যাপ করলে হিরো ট্রানজিশনে বড় হবে।', 'Tap for a Hero transition.'),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      SlmPageRoute(builder: (_) => _ShieldStage(bn: bn), style: SlmTransition.fadeRise),
                                    ),
                                    child: AnimatedSafetyShield(
                                      size: _shieldSize,
                                      controller: _shield,
                                      heroTag: 'slm-shield',
                                      revolution: Duration(seconds: _fastRing ? 2 : 6),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SlmText(tr(bn, 'মাপ', 'Size'), role: SlmTextRole.caption),
                                      Expanded(
                                        child: Slider(
                                          value: _shieldSize,
                                          min: 120,
                                          max: 300,
                                          divisions: 18,
                                          label: '${_shieldSize.round()}',
                                          activeColor: s.palette.accent,
                                          inactiveColor: s.palette.line,
                                          onChanged: (v) => setState(() => _shieldSize = v),
                                        ),
                                      ),
                                      Text('${_shieldSize.round()}', style: s.type.number.copyWith(fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _Section(
                              n: 2,
                              title: tr(bn, 'অরবিটাল রিং', 'Orbital ring'),
                              note: tr(
                                bn,
                                'পেছনের অর্ধেক শিল্ডের নিচে, সামনের অর্ধেক উপরে আঁকা। সোনালি দাগ আর পুঁতি ঘোরা দেখায়।',
                                'Rear half paints under the shield, front half over it. Gold bands and beads show the spin.',
                              ),
                              child: Wrap(
                                spacing: SlmSpace.xs,
                                children: [
                                  SlmChip(
                                    label: tr(bn, '6 সেকেন্ডে এক পাক', '6 s per turn'),
                                    selected: !_fastRing,
                                    onTap: () => setState(() => _fastRing = false),
                                  ),
                                  SlmChip(
                                    label: tr(bn, 'দ্রুত (2 সেকেন্ড)', 'Fast (2 s)'),
                                    selected: _fastRing,
                                    onTap: () => setState(() => _fastRing = true),
                                  ),
                                ],
                              ),
                            ),
                            _Section(
                              n: 3,
                              title: tr(bn, 'সোনালি আলোর সুইপ', 'Gold light sweep'),
                              child: Row(
                                children: [
                                  SlmShimmer(
                                    child: Container(
                                      width: 120,
                                      height: 56,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(gradient: SlmGradients.gold, borderRadius: SlmRadius.mdAll),
                                      child: const Icon(Icons.workspace_premium_rounded, color: SlmColors.navy950, size: 30),
                                    ),
                                  ),
                                  const SizedBox(width: SlmSpace.md),
                                  Expanded(
                                    child: SlmText(
                                      tr(bn, 'লুপে চলে; বন্ধ করলে থেমে যায়।', 'Loops; stops when loops are off.'),
                                      role: SlmTextRole.bodySm,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _Section(
                              n: 4,
                              title: tr(bn, 'এমারেল্ড গ্লো', 'Emerald glow'),
                              child: Row(
                                children: [
                                  const SlmPulse(
                                    color: SlmColors.emerald400,
                                    child: SlmIconBadge(
                                      icon: Icons.health_and_safety_rounded,
                                      tone: SlmTone.emerald,
                                      style: SlmIconStyle.solid,
                                      size: 56,
                                    ),
                                  ),
                                  const SizedBox(width: SlmSpace.lg),
                                  Expanded(
                                    child: SlmText(
                                      tr(bn, 'ধীরে শ্বাস নেওয়ার মতো আলো, ঝলকানি নয়।', 'A slow breathing light, never a flash.'),
                                      role: SlmTextRole.bodySm,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _Section(
                              n: 5,
                              title: tr(bn, 'প্রিমিয়াম বাটন', 'Premium buttons'),
                              note: tr(bn, 'চাপলে নামে, ছাড়লে স্প্রিং, প্রতি ট্যাপে একবার আলো।', 'Sinks on press, springs on release, one light pass per tap.'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SlmButton(label: tr(bn, 'পাঠ শুরু করুন', 'Start lesson'), icon: Icons.play_arrow_rounded, expand: true, onPressed: () {}),
                                  const SizedBox(height: SlmSpace.sm),
                                  SlmButton.gold(label: tr(bn, 'কুইজ খেলুন', 'Play quiz'), icon: Icons.bolt_rounded, shine: false, expand: true, onPressed: () {}),
                                  const SizedBox(height: SlmSpace.sm),
                                  Row(
                                    children: [
                                      Expanded(child: SlmButton.secondary(label: tr(bn, 'পরে', 'Later'), onPressed: () {})),
                                      const SizedBox(width: SlmSpace.sm),
                                      Expanded(
                                        child: SlmButton(
                                          label: tr(bn, 'লোডিং', 'Loading'),
                                          loading: _loading,
                                          onPressed: () {
                                            setState(() => _loading = true);
                                            _later(const Duration(milliseconds: 1600), () => setState(() => _loading = false));
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: SlmSpace.sm),
                                  SlmButton(label: tr(bn, 'বন্ধ (ডিসেবলড)', 'Disabled'), expand: true, onPressed: null),
                                ],
                              ),
                            ),
                            _Section(
                              n: 6,
                              title: tr(bn, 'পয়েন্ট কাউন্টার', 'XP counter'),
                              note: tr(bn, 'আপনার মোট পয়েন্ট (প্রোফাইল থেকে)।', 'Your lifetime points, from your profile.'),
                              child: Row(
                                children: [
                                  KeyedSubtree(
                                    key: _xpKey,
                                    child: SlmCountUp(
                                      value: me.points,
                                      style: s.type.number.copyWith(fontSize: 40, color: s.palette.accent),
                                    ),
                                  ),
                                  const SizedBox(width: SlmSpace.xs),
                                  SlmText(tr(bn, 'পয়েন্ট', 'points'), role: SlmTextRole.label),
                                  const Spacer(),
                                  SlmButton.gold(
                                    label: '+$_lessonReward',
                                    icon: Icons.add_rounded,
                                    size: SlmButtonSize.small,
                                    shine: false,
                                    onPressed: _xpReward,
                                  ),
                                ],
                              ),
                            ),
                            _Section(
                              n: 7,
                              title: tr(bn, 'প্রোগ্রেস', 'Progress'),
                              note: tr(bn, 'পরের ব্যাজ পর্যন্ত রিডিং পয়েন্ট, পাঠ আর ব্যাজ।', 'Reading points to the next badge, lessons and badges.'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SlmLevelMeter(
                                    level: level,
                                    levelLabel: tr(bn, 'লেভেল', 'Level'),
                                    title: linemanBadgeName(level, bn),
                                    value: path.towardNext,
                                    caption: path.achieved >= 10
                                        ? tr(bn, 'সব ব্যাজ পাওয়া হয়েছে', 'All badges earned')
                                        : tr(bn, 'পরের ব্যাজ: $spare / 40 রিডিং পয়েন্ট', 'Next badge: $spare / 40 reading points'),
                                  ),
                                  const SizedBox(height: SlmSpace.lg),
                                  Row(
                                    children: [
                                      SlmProgressRing(
                                        value: path.towardNext,
                                        size: 76,
                                        child: Text('${(path.towardNext * 100).round()}%', style: s.type.number.copyWith(fontSize: 15)),
                                      ),
                                      const SizedBox(width: SlmSpace.md),
                                      Expanded(
                                        child: SlmAchievementCounter(
                                          value: path.achieved,
                                          total: linemanChapters.length,
                                          label: tr(bn, 'ব্যাজ পাওয়া', 'Badges earned'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: SlmSpace.lg),
                                  SlmText(
                                    module == null
                                        ? tr(bn, 'পাঠের তালিকা লোড হচ্ছে…', 'Loading lessons…')
                                        : tr(
                                            bn,
                                            'মডিউল ${module.moduleNumber}: ${module.completedLessons} / ${module.totalLessons} পাঠ',
                                            'Module ${module.moduleNumber}: ${module.completedLessons} / ${module.totalLessons} lessons',
                                          ),
                                    role: SlmTextRole.caption,
                                  ),
                                  const SizedBox(height: 6),
                                  SlmStepProgress(
                                    total: module?.totalLessons ?? 1,
                                    done: module?.completedLessons ?? 0,
                                  ),
                                ],
                              ),
                            ),
                            _Section(
                              n: 8,
                              title: tr(bn, 'ব্যাজ আনলক', 'Badge unlock'),
                              note: tr(bn, 'আপনার পরের চ্যাপ্টারের ব্যাজ।', 'Your next chapter badge.'),
                              child: SlmButton.secondary(
                                label: tr(bn, 'ব্যাজ আনলক দেখুন', 'Show badge unlock'),
                                icon: Icons.military_tech_rounded,
                                expand: true,
                                onPressed: () => _badge(),
                              ),
                            ),
                            _Section(
                              n: 9,
                              title: tr(bn, 'লেভেল আপ', 'Level up'),
                              note: tr(bn, 'লেভেল $level → ${level >= 10 ? 10 : level + 1}', 'Level $level → ${level >= 10 ? 10 : level + 1}'),
                              child: SlmButton.secondary(
                                label: tr(bn, 'লেভেল আপ দেখুন', 'Show level up'),
                                icon: Icons.keyboard_double_arrow_up_rounded,
                                expand: true,
                                onPressed: () => _levelUp(),
                              ),
                            ),
                            _Section(
                              n: 10,
                              title: tr(bn, 'অ্যানিমেটেড কার্ড', 'Animated cards'),
                              note: tr(bn, 'পরপর আসে; চাপলে ওঠে আর কিনারা জ্বলে। শুধু প্রথমটা ভাসে।', 'Staggered entrance; lift and edge light on press. Only the first floats.'),
                              child: Column(
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: SlmSpace.sm),
                                      child: SlmMotionCard(
                                        index: i,
                                        float: i == 0,
                                        variant: i == 0 ? SlmCardVariant.gold : SlmCardVariant.surface,
                                        onTap: () {},
                                        child: Row(
                                          children: [
                                            SlmIconBadge(icon: linemanChapters[i].$3, tone: i == 0 ? SlmTone.gold : SlmTone.emerald),
                                            const SizedBox(width: SlmSpace.sm),
                                            Expanded(
                                              child: SlmText(
                                                bn ? linemanChapters[i].$1 : linemanChapters[i].$2,
                                                role: SlmTextRole.titleSm,
                                              ),
                                            ),
                                            Icon(Icons.chevron_right_rounded, color: s.palette.inkMuted),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _Section(
                              n: 11,
                              title: tr(bn, 'পেজ ট্রানজিশন', 'Page transitions'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Wrap(
                                    spacing: SlmSpace.xs,
                                    runSpacing: SlmSpace.xs,
                                    children: [
                                      for (final t in SlmTransition.values)
                                        SlmChip(
                                          label: _transitionName(t, bn),
                                          icon: Icons.open_in_new_rounded,
                                          onTap: () => Navigator.of(context).push(
                                            SlmPageRoute(builder: (_) => _TransitionDemo(bn: bn, style: t), style: t),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: SlmSpace.lg),
                                  SlmText(tr(bn, 'অনবোর্ডিং ধাপ', 'Onboarding steps'), role: SlmTextRole.overline),
                                  const SizedBox(height: SlmSpace.xs),
                                  SlmCard(
                                    variant: SlmCardVariant.sunken,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          height: 64,
                                          child: SlmStepSwitcher(
                                            index: _step,
                                            builder: (context, i) => Align(
                                              alignment: Alignment.centerLeft,
                                              child: SlmText(_onboarding(bn)[i], role: SlmTextRole.title),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            SlmIconButton(
                                              icon: Icons.arrow_back_rounded,
                                              tooltip: tr(bn, 'আগের', 'Previous'),
                                              size: 44,
                                              onPressed: _step == 0 ? null : () => setState(() => _step--),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: SlmSpace.md),
                                                child: SlmStepProgress(total: 3, done: _step + 1, tone: SlmTone.gold),
                                              ),
                                            ),
                                            SlmIconButton(
                                              icon: Icons.arrow_forward_rounded,
                                              tooltip: tr(bn, 'পরের', 'Next'),
                                              size: 44,
                                              variant: SlmIconButtonVariant.gold,
                                              onPressed: _step == 2 ? null : () => setState(() => _step++),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static List<String> _onboarding(bool bn) => bn
      ? const ['ডকেট ছাড়া কাজ নয়', 'শাটডাউন নিশ্চিত করুন', 'গ্লাভস পরে তবে হাত দিন']
      : const ['No work without a docket', 'Confirm the shutdown', 'Gloves on before you touch'];

  static String _transitionName(SlmTransition t, bool bn) => switch (t) {
        SlmTransition.sharedAxisX => tr(bn, 'পাশাপাশি', 'Shared axis'),
        SlmTransition.fadeRise => tr(bn, 'ফেড + উঠে আসা', 'Fade rise'),
        SlmTransition.fadeThrough => tr(bn, 'পাঠ → কুইজ', 'Lesson → quiz'),
        SlmTransition.scaleFade => tr(bn, 'স্কেল', 'Scale'),
      };
}

class _Controls extends StatelessWidget {
  final bool bn;
  final SlmMotionSettings motion;
  final VoidCallback onPlayAll;
  final VoidCallback onReplay;
  final VoidCallback onXp;
  final VoidCallback onBadge;
  final VoidCallback onLevel;

  const _Controls({
    required this.bn,
    required this.motion,
    required this.onPlayAll,
    required this.onReplay,
    required this.onXp,
    required this.onBadge,
    required this.onLevel,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.slm.layout.gutter;
    return ListenableBuilder(
      listenable: motion,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(g, 0, g, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SlmChip(label: tr(bn, 'সব চালান', 'Play all'), icon: Icons.play_circle_rounded, selected: true, onTap: onPlayAll),
              const SizedBox(width: SlmSpace.xs),
              SlmChip(
                label: motion.paused ? tr(bn, 'চালু', 'Resume') : tr(bn, 'থামান', 'Pause'),
                icon: motion.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                onTap: motion.paused ? motion.play : motion.pause,
              ),
              const SizedBox(width: SlmSpace.xs),
              SlmChip(label: tr(bn, 'এন্ট্রান্স আবার', 'Replay entrance'), icon: Icons.replay_rounded, onTap: onReplay),
              const SizedBox(width: SlmSpace.xs),
              SlmChip(
                label: tr(bn, 'লুপ', 'Loops'),
                icon: motion.loops ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                tone: SlmTone.emerald,
                selected: motion.loops,
                onTap: () => motion.setLoops(!motion.loops),
              ),
              const SizedBox(width: SlmSpace.xs),
              SlmChip(label: tr(bn, '+পয়েন্ট', '+XP'), icon: Icons.bolt_rounded, onTap: onXp),
              const SizedBox(width: SlmSpace.xs),
              SlmChip(label: tr(bn, 'ব্যাজ', 'Badge'), icon: Icons.military_tech_rounded, onTap: onBadge),
              const SizedBox(width: SlmSpace.xs),
              SlmChip(label: tr(bn, 'লেভেল আপ', 'Level up'), icon: Icons.keyboard_double_arrow_up_rounded, onTap: onLevel),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final int n;
  final String title;
  final String? note;
  final Widget child;

  const _Section({required this.n, required this.title, this.note, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SlmSpace.lg),
      child: SlmReveal(
        index: n,
        child: SlmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SlmRankDisc(rank: n, size: 26),
                  const SizedBox(width: SlmSpace.sm),
                  Expanded(child: SlmText(title, role: SlmTextRole.title)),
                ],
              ),
              if (note != null) ...[
                const SizedBox(height: SlmSpace.xxs),
                SlmText(note!, role: SlmTextRole.caption),
              ],
              const SizedBox(height: SlmSpace.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Destination of the shield Hero.
class _ShieldStage extends StatelessWidget {
  final bool bn;
  const _ShieldStage({required this.bn});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SlmTheme.night(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: SlmBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(SlmSpace.md),
                      child: SlmIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: tr(bn, 'ফিরে যান', 'Back'),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSafetyShield(
                    size: MediaQuery.sizeOf(context).shortestSide * 0.8,
                    entrance: false,
                    heroTag: 'slm-shield',
                  ),
                  const SizedBox(height: SlmSpace.lg),
                  SlmStaggeredText(
                    tr(bn, 'মৃত্যুহীন পথ', 'The deathless path'),
                    role: SlmTextRole.display,
                    align: TextAlign.center,
                    delay: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: SlmSpace.xs),
                  SlmReveal(
                    delay: const Duration(milliseconds: 520),
                    child: SlmText(
                      tr(bn, 'নিরাপদে কাজ, নিরাপদে বাড়ি।', 'Work safe, get home safe.'),
                      role: SlmTextRole.body,
                      align: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Destination for the transition demos: staggered heading and cards.
class _TransitionDemo extends StatelessWidget {
  final bool bn;
  final SlmTransition style;

  const _TransitionDemo({required this.bn, required this.style});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: SlmTheme.night(),
      child: Builder(
        builder: (context) {
          final g = context.slm.layout.gutter;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SlmBackground(
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(g, SlmSpace.md, g, SlmSpace.xxl),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SlmIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: tr(bn, 'ফিরে যান', 'Back'),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const SizedBox(height: SlmSpace.xl),
                    SlmStaggeredText(
                      tr(bn, 'শাটডাউন ছাড়া লাইনে হাত নয়', 'Never touch a line without a shutdown'),
                      delay: const Duration(milliseconds: 220),
                    ),
                    const SizedBox(height: SlmSpace.lg),
                    SlmStagger(
                      delay: const Duration(milliseconds: 380),
                      gap: SlmSpace.sm,
                      children: [
                        for (final (bnText, enText, icon) in const [
                          ('ডকেট নিন', 'Take the docket', Icons.description_rounded),
                          ('শাটডাউন নিশ্চিত করুন', 'Confirm the shutdown', Icons.power_off_rounded),
                          ('গ্লাভস পরুন', 'Wear gloves', Icons.back_hand_rounded),
                        ])
                          SlmCard(
                            child: Row(
                              children: [
                                SlmIconBadge(icon: icon, tone: SlmTone.emerald),
                                const SizedBox(width: SlmSpace.sm),
                                Expanded(child: SlmText(bn ? bnText : enText, role: SlmTextRole.titleSm)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
