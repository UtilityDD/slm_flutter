import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/services/neural_tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/ai_lineman_guide.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../home/bangla_read_aloud.dart';
import '../home/lesson_progress_store.dart';
import '../shell/shell_providers.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'beat_fx.dart';
import 'game_exit_sheet.dart';
import 'game_save.dart';
import 'learn_board_models.dart';

/// Learn choice-board: mission-first → PickGear → pending ◆ → Why → MythRival.
/// Never a fall. Premium chrome + staged scenes + score motion.
class LearnBoardRunnerPage extends ConsumerStatefulWidget {
  final String rungId;
  final String lessonId;
  final int ladderIndex;
  final LearnBoardPack pack;
  final bool muted;

  const LearnBoardRunnerPage({
    super.key,
    required this.rungId,
    required this.lessonId,
    required this.ladderIndex,
    required this.pack,
    this.muted = false,
  });

  @override
  ConsumerState<LearnBoardRunnerPage> createState() => _LearnBoardRunnerPageState();
}

enum _Beat { intro, pick, why, mythSay, mythBelieve, mythWhy, award, done }

class _LearnBoardRunnerPageState extends ConsumerState<LearnBoardRunnerPage>
    with TickerProviderStateMixin {
  final _scoreKey = GlobalKey();
  final _pendingDockKey = GlobalKey();

  late final BanglaReadAloud _voice;
  late final NeuralTtsService _neural;
  late final AnimationController _pendingPulse;
  late final AnimationController _celebrate;
  late final AnimationController _burn;
  late final AnimationController _scenePulse;
  late final AnimationController _rivalEnter;
  late final AnimationController _rivalBob;
  late final AnimationController _rivalDefeat;

  _Beat _beat = _Beat.intro;
  int _slot = 0;
  int _pending = 0;
  int _pendingFxToken = 0;
  final List<String> _worn = [];
  String? _rejectFlash;
  String? _pickedWhy;
  bool _muted = false;
  bool _busy = false;
  int _listenRun = 0;
  bool _neuralRun = false;
  var _whyRetry = false;
  var _burning = false;
  int _rivalLayers = 0;
  var _showMythBubble = false;
  var _rivalDefeated = false;
  int _rivalEntranceToken = 0;

  LearnBoardPack get _pack => widget.pack;
  LearnBoardSlot get _cur => _pack.slots[_slot];

  bool get _missionHero => _beat == _Beat.intro || _beat == _Beat.award || _beat == _Beat.done;

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    _voice = BanglaReadAloud();
    _neural = NeuralTtsService();
    _pendingPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _celebrate = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));
    _burn = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _scenePulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
      ..repeat(reverse: true);
    _rivalEnter = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));
    _rivalBob = AnimationController(vsync: this, duration: const Duration(milliseconds: 920))
      ..repeat(reverse: true);
    _rivalDefeat = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _burn.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _burning = false);
      }
    });
    _voice.onSpeakingChanged = (v) {
      if (!mounted || _neuralRun) return;
      if (v) {
        MascotTalk.begin();
      } else {
        MascotTalk.end();
      }
    };
    _neural.onSpeakingChanged = (v) {
      if (!mounted) return;
      if (v) {
        MascotTalk.begin();
      } else {
        MascotTalk.end();
      }
      if (v) setState(() => _busy = false);
    };
    _voice.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startIntro());
    });
  }

  @override
  void dispose() {
    unawaited(_stopVoice());
    MascotTalk.reset();
    _pendingPulse.dispose();
    _celebrate.dispose();
    _burn.dispose();
    _scenePulse.dispose();
    _rivalEnter.dispose();
    _rivalBob.dispose();
    _rivalDefeat.dispose();
    _neural.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _stopVoice() async {
    _listenRun++;
    _neuralRun = false;
    await _neural.stop();
    await _voice.stop();
    MascotTalk.reset();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _say(String line, {GuideMood mood = GuideMood.talk}) async {
    if (_muted || line.trim().isEmpty) return;
    final clean = MascotSpeechLibrary.toNaturalFieldBangla(line);
    ref.read(guideDirectorProvider.notifier).say(mood: mood, line: clean);
    final run = ++_listenRun;
    setState(() => _busy = true);
    _neuralRun = true;
    try {
      await _neural.play(
        [NeuralClip(clean, pauseMs: 220)],
        fallback: (text) => _voice.speak(text),
      );
    } catch (_) {
      if (run != _listenRun) return;
      await _voice.speak(clean);
    } finally {
      if (run == _listenRun) {
        _neuralRun = false;
        MascotTalk.reset();
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Offset _pendingOrigin() {
    final box = _pendingDockKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    }
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width * 0.82, size.height * 0.18);
  }

  Future<void> _startIntro() async {
    setState(() => _beat = _Beat.intro);
    await _say(_pack.introBn, mood: GuideMood.inspire);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await _enterSlot(0);
  }

  Future<void> _enterSlot(int i) async {
    await _stopVoice();
    if (!mounted) return;
    setState(() {
      _slot = i;
      _beat = _Beat.pick;
      _pending = 0;
      _rejectFlash = null;
      _pickedWhy = null;
      _whyRetry = false;
      _burning = false;
    });
    await _say(_cur.promptBn, mood: GuideMood.talk);
  }

  Future<void> _onPick(LearnBoardOption opt, Offset global) async {
    if (_beat != _Beat.pick || _busy) return;
    await _stopVoice();
    if (!opt.correct) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/dress_wrong.wav', volume: 0.7, muted: false));
      setState(() => _rejectFlash = opt.rejectBn.isNotEmpty ? opt.rejectBn : 'এটা নয়।');
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
      await _say(_rejectFlash!, mood: GuideMood.warn);
      if (mounted) setState(() => _rejectFlash = null);
      return;
    }

    HapticFeedback.lightImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/dress_right.wav', volume: 0.72, muted: false));
    setState(() {
      _pending = _cur.pendingPoints;
      _pendingFxToken++;
      if (_cur.wearAsset.isNotEmpty && !_worn.contains(_cur.wearAsset)) {
        _worn.add(_cur.wearAsset);
      }
      _beat = _Beat.why;
      _pickedWhy = null;
    });
    _celebrate.forward(from: 0);
    await _say('কেন এটা ঠিক?', mood: GuideMood.inspire);
  }

  Future<void> _bankPending(int bank, Offset global) async {
    if (bank <= 0) return;
    final origin = _pending > 0 ? _pendingOrigin() : global;
    setState(() => _pending = 0);
    _celebrate.forward(from: 0);
    await BeatFx.scoreDelta(
      ref,
      bank,
      rungId: widget.rungId,
      mood: GuideMood.celebrate,
      originGlobal: origin,
      muted: _muted,
    );
  }

  Future<void> _burnPending() async {
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/dress_wrong.wav', volume: 0.7, muted: false));
    setState(() {
      _burning = true;
      _pending = 0;
      _whyRetry = true;
      _pickedWhy = null;
    });
    _burn.forward(from: 0);
  }

  Future<void> _onWhy(LearnWhyChip chip, Offset global) async {
    if (_beat != _Beat.why || _busy) return;
    await _stopVoice();
    setState(() => _pickedWhy = chip.id);

    if (chip.correct) {
      final bank = _pending > 0 ? _pending : (_whyRetry ? 5 : 0);
      await _bankPending(bank, global);
      await _say('ঠিক।', mood: GuideMood.glad);
      if (!mounted) return;
      if (_slot < _pack.slots.length - 1) {
        await _enterSlot(_slot + 1);
      } else {
        await _enterMyth();
      }
      return;
    }

    await _burnPending();
    ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
    await _say('এই কারণ নয়। আবার বেছে নিন।', mood: GuideMood.warn);
  }

  Future<void> _enterMyth() async {
    await _stopVoice();
    if (!mounted) return;
    final layers = _pack.myth.wornAssets;
    setState(() {
      _beat = _Beat.mythSay;
      _pending = 0;
      _pickedWhy = null;
      _whyRetry = false;
      _burning = false;
      _rivalLayers = 0;
      _showMythBubble = false;
      _rivalDefeated = false;
      _rivalEntranceToken++;
    });
    _rivalDefeat.value = 0;
    _rivalEnter.forward(from: 0);
    if (!_muted) unawaited(ZlFx.cue('sounds/dress_wrong.wav', volume: 0.45, muted: false));
    HapticFeedback.heavyImpact();
    await _say('একজন অসাবধান লাইনম্যান এসে পড়ছে—', mood: GuideMood.warn);
    if (!mounted) return;

    for (var i = 0; i < layers.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/dress_wrong.wav', volume: 0.38, muted: false));
      setState(() => _rivalLayers = i + 1);
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showMythBubble = true);
    // Bubble carries the myth; coach keeps the voice so rival stays “cheap”.
    await _say(_pack.myth.rivalLineBn, mood: GuideMood.warn);
    if (!mounted) return;
    setState(() => _beat = _Beat.mythBelieve);
    await _say(_pack.myth.stingBn, mood: GuideMood.inspire);
  }

  Future<void> _onBelieve(bool yes, Offset global) async {
    if (_beat != _Beat.mythBelieve || _busy) return;
    await _stopVoice();
    final correct = _pack.myth.believeNoIsCorrect ? !yes : yes;
    if (correct) {
      setState(() {
        _rivalDefeated = true;
        _pending = _pack.myth.pendingPoints;
        _pendingFxToken++;
      });
      _rivalDefeat.forward(from: 0);
      _celebrate.forward(from: 0);
      if (!_muted) unawaited(ZlFx.cue('sounds/dress_right.wav', volume: 0.72, muted: false));
      HapticFeedback.lightImpact();
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      setState(() => _beat = _Beat.mythWhy);
      await _say('কেন বিশ্বাস করবেন না?', mood: GuideMood.inspire);
      return;
    }

    // Wrong belief — rival leans in harder, then Why with burned pending.
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/dress_wrong.wav', volume: 0.75, muted: false));
    setState(() => _whyRetry = true);
    await _burnPending();
    if (!mounted) return;
    setState(() => _beat = _Beat.mythWhy);
    await _say('ভুল বিশ্বাস। কেন নয়, বলুন।', mood: GuideMood.warn);
  }

  Future<void> _onMythWhy(LearnWhyChip chip, Offset global) async {
    if (_beat != _Beat.mythWhy || _busy) return;
    await _stopVoice();
    setState(() => _pickedWhy = chip.id);
    if (chip.correct) {
      final bank = _pending > 0 ? _pending : (_whyRetry ? 5 : 0);
      await _bankPending(bank, global);
      await _say('এই তো আসল কথা।', mood: GuideMood.celebrate);
      if (!mounted) return;
      await _award();
      return;
    }
    await _burnPending();
    await _say('আবার ভাবুন।', mood: GuideMood.warn);
  }

  Future<void> _award() async {
    await _stopVoice();
    if (!mounted) return;
    setState(() => _beat = _Beat.award);
    final save = ref.read(gameSaveProvider.notifier);
    final already = ref.read(gameSaveProvider).rungProgress[widget.rungId] == 'cleared';
    await save.markRungCleared(widget.rungId);
    final bonus = already ? 5 : _pack.clearBonus;
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    await BeatFx.scoreDelta(
      ref,
      bonus,
      rungId: widget.rungId,
      mood: GuideMood.celebrate,
      originGlobal: Offset(size.width * 0.5, size.height * 0.42),
      muted: _muted,
    );
    if (!already) {
      await markLessonCompletedLocally(ref, '1_1');
      await markLessonCompletedLocally(ref, '1.1');
    }
    await _say('${_pack.badgeBn} পেয়েছেন। এবার আসল পোশাক পরান।', mood: GuideMood.celebrate);
    if (!mounted) return;
    setState(() => _beat = _Beat.done);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<bool> _confirmExit() async {
    final leave = await showGameExitSheet(
      context,
      scope: GameExitScope.level,
      bn: ref.read(languageProvider),
    );
    return leave == true;
  }

  Color _washFor(_Beat beat, SlmPalette p) {
    return switch (beat) {
      _Beat.intro => const Color(0xFF0B1A14),
      _Beat.pick => const Color(0xFF0A1224),
      _Beat.why => const Color(0xFF12180A),
      _Beat.mythSay || _Beat.mythBelieve || _Beat.mythWhy => const Color(0xFF1A0A10),
      _Beat.award || _Beat.done => const Color(0xFF1A1408),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!await _confirmExit()) return;
        if (!mounted) return;
        Navigator.of(this.context).pop(false);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Theme(
          data: SlmTheme.night(),
          child: Builder(
            builder: (context) {
              final palette = context.slm.palette;
              return Scaffold(
                backgroundColor: palette.canvas,
                body: ScoreFlyHost(
                  scoreKey: _scoreKey,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: quiet ? Duration.zero : SlmMotion.page,
                          curve: Curves.easeInOutCubic,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _washFor(_beat, palette),
                                palette.canvas,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: SlmBackground(constrain: false, child: const SizedBox.expand()),
                      ),
                      if (!quiet)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _scenePulse,
                              builder: (_, _) {
                                final a = 0.04 + 0.03 * _scenePulse.value;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: _beat == _Beat.intro
                                          ? const Alignment(0, -0.15)
                                          : const Alignment(-0.55, 0.75),
                                      radius: 1.1,
                                      colors: [
                                        palette.accent.withValues(alpha: a),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      SafeArea(
                        child: Column(
                          children: [
                            _LearnBoardChrome(
                              scoreKey: _scoreKey,
                              muted: _muted,
                              dimmed: _beat == _Beat.intro,
                              onClose: () async {
                                if (!await _confirmExit()) return;
                                if (!mounted) return;
                                Navigator.of(this.context).pop(false);
                              },
                              onToggleMute: () async {
                                await _stopVoice();
                                setState(() => _muted = !_muted);
                              },
                            ),
                            Expanded(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(child: _stage(quiet, palette)),
                                  if (_pending > 0 || _burning) _pendingDock(quiet, palette),
                                  if (!_missionHero)
                                    Positioned(
                                      left: 4,
                                      bottom: 4,
                                      child: AiLinemanGuide(
                                        sprite: 148,
                                        bubbleWidth: 210,
                                        showBubble: true,
                                        large: true,
                                        centered: false,
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stage(bool quiet, SlmPalette palette) {
    return AnimatedSwitcher(
      duration: quiet ? Duration.zero : SlmMotion.page,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(begin: const Offset(0.04, 0.06), end: Offset.zero).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(
          (_beat == _Beat.mythSay || _beat == _Beat.mythBelieve)
              ? 'myth-encounter'
              : '$_beat-$_slot',
        ),
        child: switch (_beat) {
          _Beat.intro => _missionStage(palette, quiet),
          _Beat.pick => _pickBoard(palette, quiet),
          _Beat.why => _whyBoard(_cur.whyChips, _onWhy, palette, quiet),
          _Beat.mythSay || _Beat.mythBelieve => _rivalEncounter(palette, quiet),
          _Beat.mythWhy => _whyBoard(_pack.myth.whyChips, _onMythWhy, palette, quiet),
          _Beat.award || _Beat.done => _awardStage(palette, quiet),
        },
      ),
    );
  }

  Widget _missionStage(SlmPalette palette, bool quiet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          SlmReveal(
            index: 0,
            child: Text(
              enDigits(_pack.badgeBn),
              textAlign: TextAlign.center,
              style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: palette.accent),
            ),
          ),
          const SizedBox(height: 6),
          SlmReveal(
            index: 1,
            child: Text(
              'মিশন',
              style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: palette.inkSoft),
            ),
          ),
          const Spacer(flex: 1),
          SlmReveal(
            index: 2,
            rise: 22,
            child: const AiLinemanGuide(
              sprite: 196,
              bubbleWidth: 260,
              showBubble: true,
              large: true,
              centered: true,
            ),
          ),
          const SizedBox(height: 18),
          SlmReveal(
            index: 3,
            child: Text(
              enDigits(_pack.introBn),
              textAlign: TextAlign.center,
              style: bangla(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SlmReveal(
            index: 4,
            child: _emptyKitStrip(palette),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _emptyKitStrip(SlmPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_rounded, color: palette.inkMuted, size: 22),
          const SizedBox(width: 8),
          Text(
            'কিট এখনও খালি',
            style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: palette.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _pickBoard(SlmPalette palette, bool quiet) {
    final opts = [..._cur.options]..shuffle(math.Random(_slot + 11));
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 168),
      child: Column(
        children: [
          Text(
            enDigits(_cur.promptBn),
            textAlign: TextAlign.center,
            style: bangla(fontSize: 21, fontWeight: FontWeight.w900, color: palette.accent),
          ),
          const SizedBox(height: 8),
          _kitPreview(palette),
          if (_rejectFlash != null) ...[
            const SizedBox(height: 8),
            Text(
              enDigits(_rejectFlash!),
              textAlign: TextAlign.center,
              style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: palette.danger),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              itemCount: opts.length,
              itemBuilder: (_, i) {
                final o = opts[i];
                return SlmReveal(
                  index: i,
                  child: _optionTile(
                    asset: o.asset,
                    label: o.labelBn,
                    palette: palette,
                    onTapDown: (d) => _onPick(o, d.globalPosition),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kitPreview(SlmPalette palette) {
    return AnimatedSize(
      duration: SlmMotion.base,
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final a in _worn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Image.asset(a, width: 48, height: 48, fit: BoxFit.contain),
              ),
            if (_worn.isEmpty)
              Text(
                'কিট খালি — ধাপে ধাপে সাজান',
                style: bangla(fontSize: 13, fontWeight: FontWeight.w600, color: palette.inkSoft),
              ),
          ],
        ),
      ),
    );
  }

  Widget _whyBoard(
    List<LearnWhyChip> chips,
    Future<void> Function(LearnWhyChip, Offset) onPick,
    SlmPalette palette,
    bool quiet,
  ) {
    final list = [...chips]..shuffle(math.Random(_slot + (_beat == _Beat.mythWhy ? 99 : 3)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 168),
      child: Column(
        children: [
          Text(
            'কেন?',
            style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: palette.accent),
          ),
          const SizedBox(height: 4),
          Text(
            'সঠিক কারণটা ছুঁয়ে দিন',
            style: bangla(fontSize: 13, fontWeight: FontWeight.w600, color: palette.inkSoft),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = list[i];
                final hot = _pickedWhy == c.id;
                return SlmReveal(
                  index: i,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTapDown: (d) => onPick(c, d.globalPosition),
                      child: AnimatedContainer(
                        duration: quiet ? Duration.zero : SlmMotion.fast,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: hot
                                ? (c.correct
                                    ? [
                                        palette.primary.withValues(alpha: 0.28),
                                        palette.surface,
                                      ]
                                    : [
                                        palette.danger.withValues(alpha: 0.28),
                                        palette.surface,
                                      ])
                                : [
                                    palette.surfaceRaised,
                                    palette.surface,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: hot
                                ? (c.correct ? palette.primary : palette.danger)
                                : palette.accent.withValues(alpha: 0.28),
                            width: hot ? 1.6 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.accent.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          enDigits(c.textBn),
                          textAlign: TextAlign.center,
                          style: bangla(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rivalEncounter(SlmPalette palette, bool quiet) {
    final believe = _beat == _Beat.mythBelieve;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 168),
      child: Column(
        children: [
          Text(
            'অসাবধান লাইনম্যান',
            style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: palette.danger),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([_rivalEnter, _rivalBob, _rivalDefeat]),
              builder: (_, _) {
                final enter = quiet
                    ? 1.0
                    : Curves.easeOutBack.transform(_rivalEnter.value.clamp(0.0, 1.0));
                final bob = quiet ? 0.0 : math.sin(_rivalBob.value * math.pi * 2) * 5.0;
                final lean = quiet ? 0.0 : math.sin(_rivalBob.value * math.pi) * 0.035;
                final defeat = quiet ? (_rivalDefeated ? 1.0 : 0.0) : _rivalDefeat.value;
                final slideX = (1 - enter) * 220;
                final scale = (1.08 - 0.18 * defeat) * (0.92 + 0.08 * enter);
                final gray = ColorFilter.matrix(<double>[
                  0.35 + 0.65 * (1 - defeat), 0.4 * defeat, 0.4 * defeat, 0, 0,
                  0.4 * defeat, 0.35 + 0.65 * (1 - defeat), 0.4 * defeat, 0, 0,
                  0.4 * defeat, 0.4 * defeat, 0.35 + 0.65 * (1 - defeat), 0, 0,
                  0, 0, 0, 1 - 0.25 * defeat, 0,
                ]);

                return Transform.translate(
                  offset: Offset(slideX, bob - 8 * defeat),
                  child: Transform.rotate(
                    angle: lean * (1 - defeat) + 0.08 * defeat,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: ColorFiltered(
                        colorFilter: gray,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (!quiet)
                              Positioned.fill(
                                child: SlmSparkBurst(
                                  trigger: _rivalEntranceToken,
                                  radius: 120,
                                  count: 18,
                                  colors: const [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFBBF24),
                                    Color(0xFFFB7185),
                                    Color(0xFF94A3B8),
                                  ],
                                ),
                              ),
                            _rivalSilhouette(palette),
                            if (_showMythBubble)
                              Positioned(
                                left: 8,
                                right: 8,
                                top: 0,
                                child: _rivalMythBubble(palette, quiet),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (believe && !_rivalDefeated) ...[
            const SizedBox(height: 8),
            Text(
              'বিশ্বাস করেন?',
              style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: palette.accent),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SlmReveal(
                    index: 0,
                    child: _bigChoice(
                      label: 'হ্যাঁ',
                      color: palette.danger,
                      onTapDown: (d) => _onBelieve(true, d.globalPosition),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SlmReveal(
                    index: 1,
                    child: _bigChoice(
                      label: 'না',
                      color: palette.primary,
                      onTapDown: (d) => _onBelieve(false, d.globalPosition),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _rivalSilhouette(SlmPalette palette) {
    final myth = _pack.myth;
    final shown = myth.wornAssets.take(_rivalLayers).toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 250,
          width: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Dirty rim / desperate glow behind body
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      palette.danger.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Image.asset(myth.bodyAsset, fit: BoxFit.contain),
              for (var i = 0; i < shown.length; i++)
                AnimatedOpacity(
                  opacity: 1,
                  duration: SlmMotion.fast,
                  child: Image.asset(shown[i], fit: BoxFit.contain),
                ),
              // Danger ticks on wrong pieces
              if (_rivalLayers > 0)
                Positioned(
                  right: 0,
                  top: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < _rivalLayers && i < myth.dangerHints.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _dangerTick(myth.dangerHints[i], palette),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dangerTick(String text, SlmPalette palette) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE31A0A10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.danger.withValues(alpha: 0.65)),
      ),
      child: Text(
        enDigits(text),
        textAlign: TextAlign.right,
        style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: SoftDanger.ink, height: 1.15),
      ),
    );
  }

  Widget _rivalMythBubble(SlmPalette palette, bool quiet) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: quiet ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) => Transform.scale(scale: scale, alignment: Alignment.bottomCenter, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xF2240A0E),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          ),
          border: Border.all(color: palette.danger.withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(color: palette.danger.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Text(
          enDigits(_pack.myth.rivalLineBn),
          textAlign: TextAlign.center,
          style: bangla(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: palette.ink,
          ),
        ),
      ),
    );
  }

  Widget _bigChoice({
    required String label,
    required Color color,
    required GestureTapDownCallback onTapDown,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTapDown: onTapDown,
        child: Container(
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: color, width: 1.8),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Text(label, style: bangla(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ),
      ),
    );
  }

  Widget _awardStage(SlmPalette palette, bool quiet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Column(
        children: [
          const Spacer(),
          SlmSparkBurst(trigger: _beat, playOnMount: true, radius: 110, count: 22),
          Icon(Icons.workspace_premium_rounded, size: 84, color: palette.accent),
          const SizedBox(height: 12),
          Text(
            enDigits(_pack.badgeBn),
            textAlign: TextAlign.center,
            style: bangla(fontSize: 30, fontWeight: FontWeight.w900, color: palette.accent),
          ),
          const SizedBox(height: 8),
          Text(
            'এবার আসল পোশাক পরান',
            style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: palette.inkSoft),
          ),
          const SizedBox(height: 20),
          const AiLinemanGuide(
            sprite: 168,
            bubbleWidth: 220,
            showBubble: true,
            large: true,
            centered: true,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _optionTile({
    required String asset,
    required String label,
    required SlmPalette palette,
    required GestureTapDownCallback onTapDown,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTapDown: onTapDown,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.surfaceRaised, palette.surface],
            ),
            border: Border.all(color: palette.accent.withValues(alpha: 0.32), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Column(
              children: [
                Expanded(child: Image.asset(asset, fit: BoxFit.contain)),
                const SizedBox(height: 8),
                Text(
                  enDigits(label),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bangla(fontSize: 13.5, fontWeight: FontWeight.w800, color: palette.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pendingDock(bool quiet, SlmPalette palette) {
    return Positioned(
      top: 10,
      right: 12,
      child: IgnorePointer(
        child: SizedBox(
          key: _pendingDockKey,
          width: 132,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (_pending > 0)
                SlmSparkBurst(trigger: _pendingFxToken, radius: 64, count: 14),
              AnimatedBuilder(
                animation: Listenable.merge([_pendingPulse, _celebrate, _burn]),
                builder: (_, _) {
                  final pulse = quiet ? 1.0 : 0.94 + 0.08 * _pendingPulse.value;
                  final pop = quiet
                      ? 1.0
                      : Curves.easeOutBack.transform(_celebrate.value.clamp(0.0, 1.0));
                  final burnT = _burning ? _burn.value : 0.0;
                  final shatter = 1.0 - burnT;
                  final driftY = 28.0 * burnT;
                  final rot = (burnT * 0.35) * (_burning ? 1 : 0);
                  return Opacity(
                    opacity: shatter.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, driftY),
                      child: Transform.rotate(
                        angle: rot,
                        child: Transform.scale(
                          scale: pulse * (0.82 + 0.22 * pop) * (1 - 0.25 * burnT),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _burning
                                    ? const [Color(0xFFF87171), Color(0xFFB91C1C)]
                                    : const [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _burning ? const Color(0xFFFFB4B4) : const Color(0xFFFFF7D6),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_burning ? const Color(0x99EF4444) : const Color(0x99F59E0B)),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _burning ? 'নষ্ট' : '+${enDigits('$_pending')} ◆',
                                  style: bangla(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1A1408),
                                    height: 1.05,
                                  ),
                                ),
                                if (!_burning)
                                  Text(
                                    'অপেক্ষায়',
                                    style: bangla(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4A3A12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim Learn chrome: close · live ◆ · mute. No title / badge / death clutter.
class _LearnBoardChrome extends ConsumerStatefulWidget {
  final GlobalKey scoreKey;
  final bool muted;
  final bool dimmed;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;

  const _LearnBoardChrome({
    required this.scoreKey,
    required this.muted,
    required this.dimmed,
    required this.onClose,
    required this.onToggleMute,
  });

  @override
  ConsumerState<_LearnBoardChrome> createState() => _LearnBoardChromeState();
}

class _LearnBoardChromeState extends ConsumerState<_LearnBoardChrome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump;
  int? _lastPoints;

  @override
  void initState() {
    super.initState();
    _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(gameSaveProvider);
    if (_lastPoints != null && _lastPoints != save.points) {
      _bump.forward(from: 0);
    }
    _lastPoints = save.points;

    return AnimatedOpacity(
      duration: SlmMotion.base,
      opacity: widget.dimmed ? 0.45 : 1,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded, color: SlmColors.ivory, size: 22),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _bump,
                builder: (_, child) {
                  final s = 1.0 + 0.22 * math.sin(_bump.value * math.pi);
                  return Transform.scale(scale: s, child: child);
                },
                child: Container(
                  key: widget.scoreKey,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E2B45), Color(0xFF111A2E)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.7), width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: SlmColors.gold400.withValues(alpha: 0.28),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('◆', style: TextStyle(color: SlmColors.gold300, fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        enDigits('${save.points}'),
                        style: bangla(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: SlmColors.ivory,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onToggleMute,
                icon: Icon(
                  widget.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: widget.muted ? SlmColors.mist : SlmColors.gold300,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
